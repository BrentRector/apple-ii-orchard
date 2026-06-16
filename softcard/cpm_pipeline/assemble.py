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


def assemble_chunk(source: ChunkSource, *, cwd: Path | None = None) -> bytes:
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
        return _assemble_6502(source, cwd=cwd)
    if source.cpu == "z80":
        return _assemble_z80(source, cwd=cwd)
    raise AssemblyError(f"unknown CPU {source.cpu!r} for {source.asm_path.name}")


def _assemble_6502(source: ChunkSource, *, cwd: Path | None) -> bytes:
    """Run ca65 + ld65 against a 6502 source, return the binary bytes."""
    if not shutil.which("ca65") or not shutil.which("ld65"):
        raise AssemblyError("ca65 and/or ld65 not on PATH (source shared/toolchain/env.sh)")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        # Copy the source to the temp dir so the assembler's working
        # directory doesn't matter. (.incbin paths in the source resolve
        # relative to cwd, which we set to the repo root.)
        copied_asm = tmp / source.asm_path.name.replace(".asm", ".s")
        copied_asm.write_text(
            source.asm_path.read_text(encoding="utf-8"),
            encoding="utf-8",
        )

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

        ca65 = subprocess.run(
            ["ca65", str(copied_asm), "-o", str(obj)],
            capture_output=True, text=True, cwd=cwd,
        )
        if ca65.returncode != 0:
            raise AssemblyError(
                f"ca65 failed for {source.asm_path.name}:\n{ca65.stdout}{ca65.stderr}"
            )
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


def _assemble_z80(source: ChunkSource, *, cwd: Path | None) -> bytes:
    """Run sjasmplus against a Z-80 source, return the binary bytes."""
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

        result = subprocess.run(
            ["sjasmplus", str(copied_asm)],
            capture_output=True, text=True, cwd=cwd,
        )
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
        return bytes_
