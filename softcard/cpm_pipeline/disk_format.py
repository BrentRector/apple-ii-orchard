"""Disk format primitives: sector ordering, file-offset math.

Apple II disk images come in two physical-to-on-disk orderings:

  * **DOS 3.3 order** (`.dsk` files): sectors stored in DOS 3.3 *logical*
    order. The "logical" sector at position N on disk is the N-th sector
    in DOS-3.3-skew terms, NOT the N-th physical sector.
  * **ProDOS order** (`.po` files): sectors stored in physical-block-pair
    order. ProDOS reads two physical sectors at a time; the on-disk
    position is the ProDOS-block layout.

Both formats hold the same logical-vs-physical sector contents -- they
differ only in the order they're stored on disk. nibbler's GCR module
provides the interleave tables.

The CP/M boot stub addresses sectors by *physical* position (CP/M skew).
To compose or decompose a `.dsk`/`.po` from physical-sector data, we
need to translate physical → on-disk via the appropriate interleave
table.
"""

from __future__ import annotations

import sys
from pathlib import Path

# The GCR module lives in nibbler. Avoid importing nibbler at top level
# so this module stays usable in isolation; import lazily.

# DOS 3.3 interleave: physical sector → logical sector at that on-disk position
DOS33_INTERLEAVE = [0x0, 0x7, 0xE, 0x6, 0xD, 0x5, 0xC, 0x4,
                    0xB, 0x3, 0xA, 0x2, 0x9, 0x1, 0x8, 0xF]

# ProDOS interleave: physical → on-disk position (different from DOS 3.3)
PRODOS_INTERLEAVE = [0x0, 0x8, 0x1, 0x9, 0x2, 0xA, 0x3, 0xB,
                     0x4, 0xC, 0x5, 0xD, 0x6, 0xE, 0x7, 0xF]

# Standard 5.25" disk: 35 tracks × 16 sectors × 256 bytes = 143360 bytes
TRACKS = 35
SECTORS_PER_TRACK = 16
SECTOR_SIZE = 256
DISK_SIZE = TRACKS * SECTORS_PER_TRACK * SECTOR_SIZE


def sector_offset(track: int, phys_sector: int, format: str) -> int:
    """Return the byte offset in a `.dsk` or `.po` file where the given
    physical sector's data is stored.

    `format` is 'dsk' (DOS 3.3 order) or 'po' (ProDOS order).
    """
    if format == "dsk":
        on_disk_pos = DOS33_INTERLEAVE[phys_sector]
    elif format == "po":
        on_disk_pos = PRODOS_INTERLEAVE[phys_sector]
    else:
        raise ValueError(f"unknown disk format {format!r}")
    return (track * SECTORS_PER_TRACK + on_disk_pos) * SECTOR_SIZE


def detect_format(path: Path | str) -> str:
    """Infer disk format from file extension.

    Returns 'dsk' or 'po'. Raises ValueError if neither extension applies.
    """
    suffix = Path(path).suffix.lower()
    if suffix == ".dsk":
        return "dsk"
    if suffix == ".po":
        return "po"
    raise ValueError(
        f"can't detect disk format from extension {suffix!r}; "
        f"expected .dsk or .po"
    )


def read_disk(path: Path | str) -> bytearray:
    """Load a 5.25" disk image (143360 bytes). Raises if size is wrong."""
    raw = Path(path).read_bytes()
    if len(raw) != DISK_SIZE:
        raise ValueError(
            f"unexpected size {len(raw)} for {path}; expected {DISK_SIZE}"
        )
    return bytearray(raw)


def write_disk(path: Path | str, data: bytes | bytearray) -> None:
    """Write a disk image. Errors if size isn't 143360 bytes."""
    if len(data) != DISK_SIZE:
        raise ValueError(
            f"refusing to write {len(data)}-byte disk image; expected {DISK_SIZE}"
        )
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(bytes(data))
