"""Reconstruct a SoftCard CP/M `.dsk` / `.po` image from re-assembled source.

This module has one job in two grains:

* :func:`reconstruct_disk` rebuilds the **boot/OS region** (tracks 0-2) from the
  variant's annotated `docs/CPM*.asm` sources and takes every other sector
  (the CP/M filesystem on tracks 3+) from a reference image. It is the fast
  path behind the ``build`` CLI verb and the round-trip tests, and it supports
  assembling the OS sources from an alternate directory (``source_dir``).

* :func:`reconstruct_full_disk` rebuilds the **whole disk** component by
  component: the OS region from source (same chunk placement as above), *every*
  ``.COM`` program from its own re-assembled disassembly, and only the
  filesystem's data files / directory / free space carried from the image. It
  verifies byte-identical and reports per-byte provenance, so it can show that
  every byte of *code* on the disk is regenerated from human-readable source.

Both grains share the same primitives: resolve the variant's sources to bytes
(:func:`_resolve_source` / :func:`_assemble_sources`) and place chunk slices at
their physical sector positions (:func:`_place_chunks`). The whole-disk path is
the OS path plus a CP/M-filesystem layer on top.
"""

from __future__ import annotations

import re
import subprocess
import tempfile
from dataclasses import dataclass, field, replace
from pathlib import Path

from .assemble import ChunkSource, assemble_chunk
from .chunk_map import ChunkSpec, get_variant
from .disk_format import (
    DISK_SIZE, sector_offset, detect_format, read_disk, write_disk,
)

_REPO_ROOT = Path(__file__).resolve().parent.parent          # cpm-80/  (ca65 .incbin base)


# ── results ─────────────────────────────────────────────────────────────────

@dataclass
class ReconstructResult:
    """Outcome of an OS-region rebuild (:func:`reconstruct_disk`)."""
    output_path: Path
    chunks_written: int
    bytes_from_assembled: int      # bytes that came from a freshly assembled .asm
    bytes_from_extracted: int      # bytes from a pre-extracted .bin (0 once fully sourced)
    diff_count: int | None = None  # bytes that differ vs reference (when verify=True)
    diff_offsets: list[int] = field(default_factory=list)

    @property
    def matches_reference(self) -> bool:
        return self.diff_count == 0


# Per-byte provenance categories for the whole-disk rebuild.
OS_SOURCE, COM_SOURCE, DATA_FILE, DIRECTORY, FILE_RESIDUE, FREE = range(6)
PROV_LABEL = {
    OS_SOURCE:    "OS code (re-assembled source)",
    COM_SOURCE:   ".COM code (re-assembled source)",
    DATA_FILE:    "data file",
    DIRECTORY:    "CP/M directory",
    FILE_RESIDUE: "file padding / residue",
    FREE:         "free space / boot gaps",
}


@dataclass
class FullRebuildResult:
    """Outcome of a whole-disk rebuild (:func:`reconstruct_full_disk`)."""
    output_path: Path
    variant: str
    total_bytes: int
    byte_identical: bool
    diff_offsets: list[int] = field(default_factory=list)
    prov_bytes: dict[int, int] = field(default_factory=dict)   # category -> byte count

    @property
    def from_source_bytes(self) -> int:
        return self.prov_bytes.get(OS_SOURCE, 0) + self.prov_bytes.get(COM_SOURCE, 0)

    def summary(self) -> str:
        n = self.total_bytes or 1
        pct = lambda v: f"{100 * v / n:4.1f}%"
        lines = [
            f"Whole-disk rebuild from source: {self.output_path.name}  (variant {self.variant})",
            f"  BYTE-IDENTICAL to original: {self.byte_identical}"
            + ("" if self.byte_identical
               else f"  ({len(self.diff_offsets)} diffs, first: "
                    + ", ".join(f'${o:05X}' for o in self.diff_offsets[:8]) + ")"),
            f"  from re-assembled SOURCE: {self.from_source_bytes:6d} B ({pct(self.from_source_bytes)})"
            f"  [OS {self.prov_bytes.get(OS_SOURCE, 0)} + .COM {self.prov_bytes.get(COM_SOURCE, 0)}]",
        ]
        for cat in (DATA_FILE, DIRECTORY, FILE_RESIDUE, FREE):
            lines.append(f"  {PROV_LABEL[cat]:30s}: {self.prov_bytes.get(cat, 0):6d} B "
                         f"({pct(self.prov_bytes.get(cat, 0))})")
        return "\n".join(lines)


# ── shared primitives ────────────────────────────────────────────────────────

def _resolve_source(source_entry, *, repo_root: Path) -> bytes:
    """Turn a SOURCES entry (a ChunkSource `.asm` or a pre-extracted Path) into bytes."""
    if isinstance(source_entry, ChunkSource):
        return assemble_chunk(source_entry, cwd=repo_root)
    if isinstance(source_entry, Path):
        if not source_entry.exists():
            raise FileNotFoundError(f"pre-extracted source missing: {source_entry}")
        return source_entry.read_bytes()
    raise TypeError(f"unknown source entry type: {type(source_entry)}")


def _assemble_sources(sources: dict, *, repo_root: Path,
                      source_dir: Path | str | None = None) -> tuple[dict[str, bytes], dict]:
    """Resolve every source in a variant's SOURCES dict to its bytes.

    If ``source_dir`` is given, each annotated `.asm` is assembled from that
    directory instead of `docs/` (the `.incbin` paths inside stay cwd-relative),
    which lets a decompiled distribution's `os/` folder drive the rebuild.
    Returns ``(name -> bytes, possibly-remapped sources dict)``.
    """
    if source_dir is not None:
        source_dir = Path(source_dir)
        remapped = {}
        for name, entry in sources.items():
            if isinstance(entry, ChunkSource):
                cand = source_dir / entry.asm_path.name
                if cand.exists():
                    entry = replace(entry, asm_path=cand)
            remapped[name] = entry
        sources = remapped
    binaries = {name: _resolve_source(entry, repo_root=repo_root)
                for name, entry in sources.items()}
    return binaries, sources


def _place_chunks(disk: bytearray, chunks: list[ChunkSpec], binaries: dict[str, bytes],
                  sources: dict, fmt: str, *, prov: bytearray | None = None) -> tuple[int, int]:
    """Write each chunk's source slice to its physical sector position.

    Returns ``(bytes_from_assembled, bytes_from_extracted)``. If ``prov`` is
    given, marks every written byte ``OS_SOURCE`` (used by the whole-disk path).
    """
    bytes_assembled = bytes_extracted = 0
    for chunk in chunks:
        if chunk.source_name not in binaries:
            raise KeyError(f"chunk references unknown source {chunk.source_name!r}")
        src = binaries[chunk.source_name]
        if chunk.src_offset + chunk.length > len(src):
            raise ValueError(
                f"chunk {chunk.source_name}+{chunk.src_offset:#x}/{chunk.length:#x}"
                f" exceeds source size {len(src)}")
        target = sector_offset(chunk.track, chunk.phys_sector, fmt)
        disk[target:target + chunk.length] = src[chunk.src_offset:chunk.src_offset + chunk.length]
        if prov is not None:
            for k in range(chunk.length):
                prov[target + k] = OS_SOURCE
        if isinstance(sources[chunk.source_name], ChunkSource):
            bytes_assembled += chunk.length
        else:
            bytes_extracted += chunk.length
    return bytes_assembled, bytes_extracted


def _transcode(src_disk: bytes | bytearray, *, src_format: str, dst_format: str) -> bytearray:
    """Convert a 143360-byte image between .dsk and .po orderings (physical-sector round-trip)."""
    from .disk_format import (
        DOS33_INTERLEAVE, PRODOS_INTERLEAVE, TRACKS, SECTORS_PER_TRACK, SECTOR_SIZE,
    )
    src_il = DOS33_INTERLEAVE if src_format == "dsk" else PRODOS_INTERLEAVE
    dst_il = DOS33_INTERLEAVE if dst_format == "dsk" else PRODOS_INTERLEAVE
    out = bytearray(len(src_disk))
    for track in range(TRACKS):
        for phys in range(SECTORS_PER_TRACK):
            s = (track * SECTORS_PER_TRACK + src_il[phys]) * SECTOR_SIZE
            d = (track * SECTORS_PER_TRACK + dst_il[phys]) * SECTOR_SIZE
            out[d:d + SECTOR_SIZE] = src_disk[s:s + SECTOR_SIZE]
    return out


# ── OS-region rebuild (the `build` verb) ─────────────────────────────────────

def reconstruct_disk(variant: str, *, reference_path: Path | str, output_path: Path | str,
                     verify: bool = True, max_diff_offsets: int = 10,
                     repo_root: Path | None = None,
                     source_dir: Path | str | None = None) -> ReconstructResult:
    """Rebuild the boot/OS region from source; take the filesystem from a reference.

    `variant` is '220' or '223'. `reference_path` supplies bytes for any sector
    not covered by the chunk map (the CP/M filesystem on tracks 3+).
    `output_path`'s extension selects the format (.dsk vs .po). With
    `verify=True`, the output is byte-compared against the reference.
    """
    reference_path, output_path = Path(reference_path), Path(output_path)
    if repo_root is None:
        repo_root = _REPO_ROOT

    chunks, sources = get_variant(variant)
    out_fmt, ref_fmt = detect_format(output_path), detect_format(reference_path)
    binaries, sources = _assemble_sources(sources, repo_root=repo_root, source_dir=source_dir)

    # Start from the reference image (in the output format), then overlay chunks.
    disk = read_disk(reference_path) if ref_fmt == out_fmt else _transcode(
        read_disk(reference_path), src_format=ref_fmt, dst_format=out_fmt)
    assembled, extracted = _place_chunks(disk, chunks, binaries, sources, out_fmt)
    write_disk(output_path, disk)

    result = ReconstructResult(
        output_path=output_path, chunks_written=len(chunks),
        bytes_from_assembled=assembled, bytes_from_extracted=extracted)

    if verify:
        ref = read_disk(reference_path)
        if ref_fmt != out_fmt:
            ref = _transcode(ref, src_format=ref_fmt, dst_format=out_fmt)
        diffs = [i for i in range(DISK_SIZE) if ref[i] != disk[i]]
        result.diff_count = len(diffs)
        result.diff_offsets = diffs[:max_diff_offsets]
    return result


# ── whole-disk rebuild (OS + every .COM, all from source) ────────────────────

def _assemble_com(disk_path, name: str, td: Path) -> bytes:
    """Decompile a .COM (emulation-assisted) and re-assemble it back to bytes."""
    from .decompile_com import decompile_com           # lazy: pulls in disasm_z80
    r = decompile_com(disk_path, name, td / name.split(".")[0], max_instructions=1_000_000)
    out_bin = td / (name.split(".")[0] + "_a.bin")
    txt = re.sub(r'SAVEBIN\s+"[^"]+"', f'SAVEBIN "{out_bin.as_posix()}"', r.asm_path.read_text())
    (td / (name.split(".")[0] + "_a.asm")).write_text(txt, encoding="utf-8")
    subprocess.run(["sjasmplus", str(td / (name.split(".")[0] + "_a.asm"))],
                   capture_output=True, text=True, cwd=str(td))
    return out_bin.read_bytes()


def reconstruct_full_disk(disk_path, output_path, *, variant: str | None = None,
                          verify: bool = True) -> FullRebuildResult:
    """Rebuild the whole disk from source and (optionally) verify byte-identical.

    The image is assembled into a blank buffer, never copied wholesale from the
    reference: the OS region comes from the variant's annotated sources, every
    ``.COM`` from its own re-assembled disassembly, and the filesystem's data
    files / directory / file padding / free space are carried as data. The point
    is not that a copy equals itself, but that every *code* region is
    independently regenerated from human-readable source and still lands on the
    exact original bytes.
    """
    from .decompile_os import detect                   # variant detection
    from .filesystem import (read_directory, extract_file, softcard_params,
                             _block_locations)

    disk_path, output_path = Path(disk_path), Path(output_path)
    fmt = detect_format(disk_path)
    if variant is None:
        v = detect(disk_path).variant
        variant = "223" if v.endswith("2_23") else "220" if v.endswith("2_20") else None
        if variant is None:
            raise ValueError(f"unrecognized SoftCard CP/M variant: {v!r}")

    ref = bytearray(read_disk(disk_path))
    n = len(ref)
    out = bytearray(n)
    prov = bytearray([0xFF]) * n                        # 0xFF = unassigned

    # 1. OS / boot region from the variant's assembled sources (shared placement).
    chunks, sources = get_variant(variant)
    binaries, sources = _assemble_sources(sources, repo_root=_REPO_ROOT)
    _place_chunks(out, chunks, binaries, sources, fmt, prov=prov)

    # 2. CP/M filesystem: directory metadata, then each file's content.
    p = softcard_params(fmt)
    for blk in range(p.dir_blocks):                     # directory blocks (metadata)
        for (t, ph) in _block_locations(p, blk):
            off = sector_offset(t, ph, fmt)
            out[off:off + 256] = ref[off:off + 256]
            for k in range(256):
                prov[off + k] = DIRECTORY

    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        for f in read_directory(ref, p):
            is_com = f.name.endswith(".COM")
            data = _assemble_com(disk_path, f.name, td) if is_com else extract_file(ref, f.name, p, f.user)
            tag = COM_SOURCE if is_com else DATA_FILE
            written = 0
            for blk in f.blocks:
                for (t, ph) in _block_locations(p, blk):
                    off = sector_offset(t, ph, fmt)
                    for k in range(256):
                        if written < f.size:           # the file's own bytes
                            out[off + k] = data[written]
                            prov[off + k] = tag
                        else:                          # block tail past the file length
                            out[off + k] = ref[off + k]
                            prov[off + k] = FILE_RESIDUE
                        written += 1

    # 3. Anything still unassigned is free space / boot-region gaps: carry it.
    for i in range(n):
        if prov[i] == 0xFF:
            out[i] = ref[i]
            prov[i] = FREE

    write_disk(output_path, out)

    diffs = [i for i in range(n) if out[i] != ref[i]] if verify else []
    from collections import Counter
    counts = Counter(prov)
    return FullRebuildResult(
        output_path=output_path, variant=variant, total_bytes=n,
        byte_identical=(len(diffs) == 0), diff_offsets=diffs[:16],
        prov_bytes={cat: counts.get(cat, 0) for cat in PROV_LABEL})


def main(argv=None) -> int:
    """CLI: rebuild a whole disk from source and verify byte-identical."""
    import argparse
    ap = argparse.ArgumentParser(
        prog="cpm_pipeline.reconstruct",
        description="Rebuild a whole SoftCard CP/M disk from re-assembled source; verify byte-identical.")
    ap.add_argument("disk", help="reference .dsk/.po image")
    ap.add_argument("output", help="output disk image path")
    ap.add_argument("--variant", choices=("220", "223"), default=None)
    args = ap.parse_args(argv)
    res = reconstruct_full_disk(args.disk, args.output, variant=args.variant)
    print(res.summary())
    return 0 if res.byte_identical else 1


if __name__ == "__main__":
    raise SystemExit(main())
