"""Assembler wrappers: take an OS source file (a per-disk os/ tree), produce its bytes.

Wraps the same ca65/ld65 (6502) and sjasmplus (Z-80) toolchains that the
docs round-trip regression tests use. The tests are in
`cpm-investigation/tests/test_annotated_docs.py`; this module factors
their assembly logic into a reusable function.

Each annotated source file in `docs/` declares its target binary inline:

  * Z-80 sources (`.asm` for sjasmplus): contain a `SAVEBIN "build/...bin", $org, $size`
    directive that names the output filename. The assembler writes the
    binary as a side effect.
  * 6502 sources (also `.asm` extension here, ca65 syntax): need an
    external linker config (`.cfg`) describing a single MEMORY region
    + CODE segment. We synthesize the config based on the source's
    `.org` and the binary size (specified by the caller).

For both, this module returns the byte content of the assembled
binary as a `bytes` object.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


class AssemblyError(RuntimeError):
    """Raised when ca65/ld65/sjasmplus fails or produces an unexpected output."""


@dataclass
class ChunkSource:
    """How to assemble one chunk's source file."""
    asm_path: Path        # path to the .asm source in docs/
    cpu: str              # '6502' or 'z80'
    org: int              # load address (also the .org in the file)
    size: int             # bytes to expect in the output
    # For 6502: the build/...bin name baked into the SAVEBIN directive
    # (Z-80 uses SAVEBIN; 6502 we synthesize a linker config and ignore this.)
    expected_bin_name: str | None = None
    # Z-80 sources may INCBIN a separately-assembled foreign-CPU binary (e.g. the
    # embedded 6502 RPC block). Each entry is a 6502 ca65 source (with a sibling
    # .cfg) to assemble into a `bin_name` placed beside the Z-80 source so its
    # INCBIN resolves. `defines` are -D flags for the config (e.g. CFG_56K).
    incbin_deps: tuple = ()   # tuple of (bin_name, ca65_src_path, defines_tuple)
    # Z-80 sources may INCLUDE sibling component sources (e.g. CPM_CCP.asm INCLUDEs
    # CPM_BDOS.asm so the two compile as one unit, cross-refs resolving without
    # equates). Each path is copied verbatim beside the main source so the INCLUDE
    # resolves at assembly time.
    include_files: tuple = ()   # tuple of Paths copied into the build dir


def assemble_chunk(source: ChunkSource, *, cwd: Path | None = None,
                   lst_path: Path | None = None) -> bytes:
    """Assemble `source` and return the resulting binary bytes.

    `cwd` controls the working directory the assembler runs from (matters
    for `.incbin` path resolution -- those paths are relative to either
    the source file or the cwd, depending on the assembler).

    For 6502 sources (ca65), runs `ca65 + ld65` with a synthesized linker
    config that places one CODE segment at the source's load address with
    the expected size.

    For Z-80 sources (sjasmplus), runs `sjasmplus`. The source file's
    SAVEBIN directive points at a `build/...bin` path that we rewrite to
    a temp path so the user's working tree isn't polluted.
    """
    if not source.asm_path.exists():
        raise AssemblyError(f"source not found: {source.asm_path}")

    if source.cpu == "6502":
        return _assemble_6502(source, cwd=cwd, lst_path=lst_path)
    if source.cpu == "z80":
        return _assemble_z80(source, cwd=cwd, lst_path=lst_path)
    raise AssemblyError(f"unknown CPU {source.cpu!r} for {source.asm_path.name}")


def _build_z80_incbin_dep(src_path: Path, out_bin: Path, defines: tuple) -> None:
    """sjasmplus a Z-80 INCBIN dependency to `out_bin` (a Z-80 routine embedded in
    a 6502 image and INCBIN'd by it -- the reverse of `_build_incbin_dep`). The
    Z-80 source must SAVEBIN to the literal ``{out_bin}`` placeholder, which we
    rewrite to `out_bin`. `defines` become -D flags. Raises on failure."""
    if not shutil.which("sjasmplus"):
        raise AssemblyError("sjasmplus not on PATH (source shared/toolchain/env.sh)")
    if not src_path.exists():
        raise AssemblyError(f"Z-80 INCBIN dep source missing: {src_path}")
    tmp_src = out_bin.parent / src_path.name
    text = src_path.read_text(encoding="utf-8")
    # Stage any shared includes the fragment pulls in (e.g. apple_softcard.inc) beside it
    # so the bare-name INCLUDE resolves in the build dir.
    _inc_dir = Path(__file__).resolve().parent.parent / "include"
    for inc in re.findall(r'(?im)^\s*INCLUDE\s+"([^"]+)"', text):
        cand = _inc_dir / inc
        if cand.exists():
            (out_bin.parent / inc).write_text(cand.read_text(encoding="latin-1"),
                                              encoding="latin-1")
    tmp_src.write_text(_SAVEBIN_RE.sub(rf'\1{out_bin.as_posix()}\3', text),
                       encoding="utf-8")
    cmd = ["sjasmplus"] + [f"-D{d}" for d in defines] + [tmp_src.name]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(out_bin.parent))
    if r.returncode != 0 or not out_bin.exists():
        raise AssemblyError(f"sjasmplus failed for {src_path.name}:\n{r.stdout}{r.stderr}")


def _assemble_6502(source: ChunkSource, *, cwd: Path | None,
                   lst_path: Path | None = None) -> bytes:
    """Run ca65 + ld65 against a 6502 source, return the binary bytes. If `lst_path`
    is given, also emit the ca65 listing (address + machine bytes + source per line)
    there -- the .s source carries the absolute addresses via its `.org`, so the
    listing matches the disk image."""
    if not shutil.which("ca65") or not shutil.which("ld65"):
        raise AssemblyError("ca65 and/or ld65 not on PATH (source shared/toolchain/env.sh)")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        # Copy the source to the temp dir so the assembler's working
        # directory doesn't matter. (.incbin paths in the source resolve
        # relative to cwd, which we set to the repo root -- or to tmp when the
        # source INCBINs a sub-assembled Z-80 block staged there.)
        copied_asm = tmp / source.asm_path.name.replace(".asm", ".s")
        copied_asm.write_text(
            source.asm_path.read_text(encoding="utf-8"),
            encoding="utf-8",
        )

        # Sub-assemble any INCBIN'd Z-80 blocks (embedded Z-80 routines extracted
        # to their own sjasmplus source and INCBIN'd back into this 6502 image,
        # so each CPU's code is real source in its own assembler) into tmp, where
        # the source's `.incbin "name.bin"` resolves (ca65 runs with cwd=tmp).
        for bin_name, src_path, defines in source.incbin_deps:
            _build_z80_incbin_dep(Path(src_path), tmp / bin_name, defines)

        # Synthesize linker config
        cfg = tmp / (source.asm_path.stem + ".cfg")
        cfg.write_text(
            f"MEMORY {{\n"
            f"    RAM: start = ${source.org:04X}, "
            f"size = ${source.size:04X}, file = %O;\n"
            f"}}\n"
            f"SEGMENTS {{\n"
            f"    CODE: load = RAM, type = ro;\n"
            f"}}\n",
            encoding="utf-8",
        )
        obj = copied_asm.with_suffix(".o")
        out_bin = tmp / "out.bin"

        # When the source INCBINs a sub-assembled block, run ca65 from tmp so the
        # relative `.incbin` path resolves there; otherwise from the repo root.
        ca_cwd = str(tmp) if source.incbin_deps else cwd
        lst_tmp = obj.with_suffix(".lst")
        ca_cmd = ["ca65", str(copied_asm), "-o", str(obj)]
        if lst_path is not None:
            ca_cmd += ["-l", str(lst_tmp)]
        ca65 = subprocess.run(
            ca_cmd, capture_output=True, text=True, cwd=ca_cwd,
        )
        if ca65.returncode != 0:
            raise AssemblyError(
                f"ca65 failed for {source.asm_path.name}:\n{ca65.stdout}{ca65.stderr}"
            )
        if lst_path is not None and lst_tmp.exists():
            Path(lst_path).write_text(lst_tmp.read_text(encoding="latin-1"),
                                      encoding="latin-1")
        ld65 = subprocess.run(
            ["ld65", "-C", str(cfg), "-o", str(out_bin), str(obj)],
            capture_output=True, text=True,
        )
        if ld65.returncode != 0:
            raise AssemblyError(
                f"ld65 failed for {source.asm_path.name}:\n{ld65.stdout}{ld65.stderr}"
            )

        result = out_bin.read_bytes()
        if len(result) != source.size:
            raise AssemblyError(
                f"{source.asm_path.name}: expected {source.size} bytes, got {len(result)}"
            )
        return result


# Pattern to find SAVEBIN in Z-80 sources so we can rewrite the path.
_SAVEBIN_RE = re.compile(
    r'(\bSAVEBIN\s+")([^"]+)(",.*)',
    re.IGNORECASE,
)


def _build_incbin_dep(src_path: Path, out_bin: Path, defines: tuple) -> None:
    """ca65 + ld65 a 6502 INCBIN dependency (with its sibling .cfg) to `out_bin`.
    `defines` become -D flags (e.g. ('CFG_56K',)). Raises on failure."""
    if not shutil.which("ca65") or not shutil.which("ld65"):
        raise AssemblyError("ca65/ld65 not on PATH (source shared/toolchain/env.sh)")
    cfg = src_path.with_suffix(".cfg")
    if not src_path.exists() or not cfg.exists():
        raise AssemblyError(f"INCBIN dep source/cfg missing: {src_path}")
    obj = out_bin.with_suffix(".o")
    cmd = ["ca65", str(src_path), "-o", str(obj)]
    for d in defines:
        cmd += ["-D", d]
    ca = subprocess.run(cmd, capture_output=True, text=True)
    if ca.returncode != 0:
        raise AssemblyError(f"ca65 failed for {src_path.name}:\n{ca.stdout}{ca.stderr}")
    ld = subprocess.run(["ld65", "-C", str(cfg), "-o", str(out_bin), str(obj)],
                        capture_output=True, text=True)
    if ld.returncode != 0 or not out_bin.exists():
        raise AssemblyError(f"ld65 failed for {src_path.name}:\n{ld.stdout}{ld.stderr}")


def _assemble_z80(source: ChunkSource, *, cwd: Path | None, lst_path: Path | None = None) -> bytes:
    """Run sjasmplus against a Z-80 source, return the binary bytes. If `lst_path` is given,
    also emit the sjasmplus listing (address + machine bytes + source per line) there -- the
    OS analogue of fold_build's GBASIC.lst (the .asm carries no inline `$addr` comments)."""
    if not shutil.which("sjasmplus"):
        raise AssemblyError("sjasmplus not on PATH (source shared/toolchain/env.sh)")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        copied_asm = tmp / source.asm_path.name
        out_bin = tmp / "out.bin"
        text = source.asm_path.read_text(encoding="utf-8")
        # Rewrite the SAVEBIN target so the binary lands in our temp dir.
        # If no SAVEBIN is in the source, skip rewriting (assembler will
        # produce no output and we'll error below).
        new_text = _SAVEBIN_RE.sub(rf'\1{out_bin.as_posix()}\3', text)
        copied_asm.write_text(new_text, encoding="utf-8")

        # Assemble any INCBIN'd foreign-CPU dependencies into the temp dir, so
        # the Z-80 source's `INCBIN "name"` resolves there (sjasmplus runs with
        # cwd=tmp below). Each dep is a ca65 6502 source + sibling .cfg.
        for bin_name, src_path, defines in source.incbin_deps:
            _build_incbin_dep(Path(src_path), tmp / bin_name, defines)
        # Copy INCLUDE'd component sources verbatim into the temp dir.
        for inc in source.include_files:
            shutil.copy(Path(inc), tmp / Path(inc).name)

        # When there are INCBIN/INCLUDE deps, run from the temp dir so relative
        # INCBIN/INCLUDE paths resolve there (mirrors the CPM60.COM build).
        run_cwd = str(tmp) if (source.incbin_deps or source.include_files) else cwd
        lst_tmp = tmp / "out.lst"
        cmd = ["sjasmplus"]
        if lst_path is not None:
            cmd.append(f"--lst={lst_tmp.resolve().as_posix()}")
        cmd.append(copied_asm.name if source.incbin_deps else str(copied_asm))
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=run_cwd)
        if result.returncode != 0:
            raise AssemblyError(
                f"sjasmplus failed for {source.asm_path.name}:\n{result.stdout}{result.stderr}"
            )
        if not out_bin.exists():
            raise AssemblyError(
                f"{source.asm_path.name}: sjasmplus produced no binary "
                f"(SAVEBIN directive missing or rewrite pattern failed?)"
            )
        bytes_ = out_bin.read_bytes()
        if len(bytes_) != source.size:
            raise AssemblyError(
                f"{source.asm_path.name}: expected {source.size} bytes, got {len(bytes_)}"
            )
        if lst_path is not None and lst_tmp.exists():
            Path(lst_path).write_text(lst_tmp.read_text(encoding="latin-1"), encoding="latin-1")
        return bytes_
