"""Stage 7: reconstruct a CP/M `.dsk` (or `.po`) image from assembled
annotated source.

Pipeline:

  1. Load all source binaries listed in the variant's SOURCES dict.
     For ChunkSource entries (annotated `.asm`), assemble fresh.
     For Path entries (pre-extracted from prior investigation), read
     directly.
  2. Start with the reference disk image (preserves the CP/M filesystem
     content + any sectors not yet covered by an annotated source).
  3. For each chunk in the variant's CHUNKS list, slice the appropriate
     source bytes and write them at the chunk's physical sector position
     on the output disk.
  4. Write the output, optionally byte-compare against reference.

The result is a `.dsk` / `.po` that's byte-identical to the original
for all sectors covered by annotated sources, and identical via
fallback for the rest. As more `.asm` sources cover more of the disk,
the fallback shrinks toward nothing.
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace
from pathlib import Path

from .assemble import ChunkSource, assemble_chunk
from .chunk_map import ChunkSpec, get_variant
from .disk_format import (
    DISK_SIZE, sector_offset, detect_format, read_disk, write_disk,
)


@dataclass
class ReconstructResult:
    output_path: Path
    chunks_written: int
    bytes_from_assembled: int     # bytes that came from a freshly assembled .asm
    bytes_from_extracted: int     # bytes from a pre-extracted .bin
    diff_count: int | None = None # bytes that differ vs reference (if --verify)
    diff_offsets: list[int] = field(default_factory=list)  # first-N diff offsets

    @property
    def matches_reference(self) -> bool:
        return self.diff_count == 0


def _resolve_source(source_entry, *, repo_root: Path) -> bytes:
    """Turn a SOURCES entry (ChunkSource or Path) into its byte content."""
    if isinstance(source_entry, ChunkSource):
        return assemble_chunk(source_entry, cwd=repo_root)
    if isinstance(source_entry, Path):
        if not source_entry.exists():
            raise FileNotFoundError(
                f"pre-extracted source missing: {source_entry}"
            )
        return source_entry.read_bytes()
    raise TypeError(f"unknown source entry type: {type(source_entry)}")


def reconstruct_disk(
    variant: str,
    *,
    reference_path: Path | str,
    output_path: Path | str,
    verify: bool = True,
    max_diff_offsets: int = 10,
    repo_root: Path | None = None,
    source_dir: Path | str | None = None,
) -> ReconstructResult:
    """Build a `.dsk`/`.po` for the given variant.

    `variant` is '220' or '223'. `reference_path` provides bytes for any
    sector not covered by the chunk map (typically the CP/M filesystem on
    tracks 3+). `output_path`'s extension determines the format (.dsk vs
    .po). When `verify=True`, the output is byte-compared against the
    reference (with the chunk map applied to both sides for normalization)
    and the diff count is recorded.
    """
    reference_path = Path(reference_path)
    output_path = Path(output_path)
    if repo_root is None:
        repo_root = Path(__file__).resolve().parent.parent

    chunks, sources = get_variant(variant)
    output_format = detect_format(output_path)
    reference_format = detect_format(reference_path)

    # Optionally assemble the annotated `.asm` sources from an alternate
    # directory (e.g. a decompiled distribution's os/ folder) instead of
    # docs/. .incbin paths inside the sources are cwd-relative (repo_root),
    # so the .asm files can live anywhere.
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

    # Resolve all source binaries (assemble or read).
    binaries: dict[str, bytes] = {}
    for name, entry in sources.items():
        binaries[name] = _resolve_source(entry, repo_root=repo_root)

    # Start with the reference image converted to the output format.
    # If formats match, just copy bytes; if they differ, we need to
    # transcode via the physical-sector view.
    if reference_format == output_format:
        disk = read_disk(reference_path)
    else:
        disk = _transcode(read_disk(reference_path),
                          src_format=reference_format,
                          dst_format=output_format)

    # Apply chunks.
    bytes_assembled = 0
    bytes_extracted = 0
    for chunk in chunks:
        if chunk.source_name not in binaries:
            raise KeyError(f"chunk references unknown source {chunk.source_name!r}")
        src = binaries[chunk.source_name]
        if chunk.src_offset + chunk.length > len(src):
            raise ValueError(
                f"chunk {chunk.source_name}+{chunk.src_offset:#x}/{chunk.length:#x}"
                f" exceeds source size {len(src)}"
            )
        sliced = src[chunk.src_offset:chunk.src_offset + chunk.length]
        target = sector_offset(chunk.track, chunk.phys_sector, output_format)
        disk[target:target + chunk.length] = sliced

        # Track which kind of source contributed
        entry = sources[chunk.source_name]
        if isinstance(entry, ChunkSource):
            bytes_assembled += chunk.length
        else:
            bytes_extracted += chunk.length

    write_disk(output_path, disk)

    result = ReconstructResult(
        output_path=output_path,
        chunks_written=len(chunks),
        bytes_from_assembled=bytes_assembled,
        bytes_from_extracted=bytes_extracted,
    )

    if verify:
        ref_disk = read_disk(reference_path)
        if reference_format != output_format:
            ref_disk = _transcode(ref_disk,
                                  src_format=reference_format,
                                  dst_format=output_format)
        diffs = [i for i in range(DISK_SIZE) if ref_disk[i] != disk[i]]
        result.diff_count = len(diffs)
        result.diff_offsets = diffs[:max_diff_offsets]

    return result


def _transcode(src_disk: bytes | bytearray,
               *, src_format: str, dst_format: str) -> bytearray:
    """Convert a 143360-byte disk image between .dsk and .po orderings.
    Round-trips through the physical-sector view.
    """
    from .disk_format import (
        DOS33_INTERLEAVE, PRODOS_INTERLEAVE, TRACKS, SECTORS_PER_TRACK,
        SECTOR_SIZE,
    )
    src_interleave = (DOS33_INTERLEAVE if src_format == "dsk"
                      else PRODOS_INTERLEAVE)
    dst_interleave = (DOS33_INTERLEAVE if dst_format == "dsk"
                      else PRODOS_INTERLEAVE)
    out = bytearray(len(src_disk))
    for track in range(TRACKS):
        for phys in range(SECTORS_PER_TRACK):
            src_pos = src_interleave[phys]
            dst_pos = dst_interleave[phys]
            src_off = (track * SECTORS_PER_TRACK + src_pos) * SECTOR_SIZE
            dst_off = (track * SECTORS_PER_TRACK + dst_pos) * SECTOR_SIZE
            out[dst_off:dst_off + SECTOR_SIZE] = src_disk[src_off:src_off + SECTOR_SIZE]
    return out
