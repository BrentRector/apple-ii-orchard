"""CP/M 2.2 filesystem reader for Microsoft SoftCard Apple II disks.

Tracks 0-2 of a SoftCard CP/M disk hold the boot pipeline; tracks 3-34 hold a
standard CP/M 2.2 filesystem (directory + file allocation). This module parses
that directory and extracts file contents, so the toolchain can list the
user-visible programs (``CPM60.COM``, ``MBASIC.COM``, ...) and pull a selected
``.COM`` out for decompilation.

The address chain from a CP/M allocation block to a byte offset in the ``.dsk``
/ ``.po`` image is:

    block B (1 KB)          -> 4 consecutive CP/M *logical* 256-byte sectors
    logical sector (in trk) -> physical sector via the CP/M SECTRAN skew
    physical sector         -> on-disk offset via the DOS 3.3 / ProDOS interleave
                               (cpm_pipeline.disk_format.sector_offset)

The SoftCard CP/M SECTRAN skew was derived empirically and verified against the
documented directory of ``CPMV223-44K.DSK`` (see docs/CPM_Filesystem.md): logical
sector ``L`` within a track maps to physical sector ``(L * 3) % 16``. With it,
the 22 documented files parse with exact record counts and ``CPM60.COM`` extracts
to its expected 11,264 bytes; the standard utilities (``PIP``/``MBASIC``/``STAT``)
begin with the canonical ``JP`` ($C3) .COM entry.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from .disk_format import read_disk, sector_offset, SECTOR_SIZE, SECTORS_PER_TRACK, detect_format


# CP/M SECTRAN skew for SoftCard Apple CP/M: logical sector -> physical sector.
SOFTCARD_SKEW = tuple((i * 3) % SECTORS_PER_TRACK for i in range(SECTORS_PER_TRACK))

# Standard SoftCard CP/M 2.2 disk parameters (5.25" Apple Disk II).
RESERVED_TRACKS = 3        # tracks 0-2 are the boot pipeline
BLOCK_SIZE = 1024          # BLS: 1 KB allocation block
DIR_ENTRIES = 64           # 64 directory entries (2 directory blocks)
RECORD_SIZE = 128          # CP/M logical record


class NotCpmFilesystem(ValueError):
    """Raised when a disk image does not look like a SoftCard CP/M filesystem."""


@dataclass
class CpmParams:
    """Disk parameters needed to locate the directory and file data."""
    fmt: str                                    # 'dsk' (DOS 3.3 order) or 'po' (ProDOS)
    reserved_tracks: int = RESERVED_TRACKS
    sectors_per_track: int = SECTORS_PER_TRACK
    sector_size: int = SECTOR_SIZE
    block_size: int = BLOCK_SIZE
    dir_entries: int = DIR_ENTRIES
    skew: tuple[int, ...] = SOFTCARD_SKEW

    @property
    def sectors_per_block(self) -> int:
        return self.block_size // self.sector_size

    @property
    def dir_blocks(self) -> int:
        return -(-self.dir_entries * 32 // self.block_size)  # ceil


@dataclass
class CpmFile:
    """A logical file assembled from one or more directory entries (extents)."""
    name: str                                   # "CPM60.COM"
    user: int                                   # CP/M user number (0-15)
    records: int                                # total 128-byte records
    blocks: list[int] = field(default_factory=list)   # allocation blocks, in order
    extents: int = 0
    read_only: bool = False
    system: bool = False

    @property
    def size(self) -> int:
        """File size in bytes (records x 128)."""
        return self.records * RECORD_SIZE


def softcard_params(fmt: str) -> CpmParams:
    """Return the standard SoftCard CP/M parameters for the given image format."""
    return CpmParams(fmt=fmt)


def _block_locations(p: CpmParams, block: int):
    """Yield (track, physical_sector) for each sector of an allocation block."""
    first_logical = block * p.sectors_per_block
    for i in range(p.sectors_per_block):
        gl = first_logical + i
        track = p.reserved_tracks + gl // p.sectors_per_track
        local = gl % p.sectors_per_track
        yield track, p.skew[local]


def _read_block(disk: bytes, p: CpmParams, block: int) -> bytes:
    out = bytearray()
    for track, phys in _block_locations(p, block):
        off = sector_offset(track, phys, p.fmt)
        out += disk[off:off + p.sector_size]
    return bytes(out)


def _filename(entry: bytes) -> str | None:
    """Return 'NAME.EXT' for a directory entry, or None if the name bytes are
    not a plausible CP/M filename (rejects zero-fill / corrupt slots)."""
    raw = bytes(c & 0x7F for c in entry[1:12])      # 8 name + 3 ext, attr bits masked
    if any(c < 0x20 or c > 0x7E for c in raw):
        return None
    name = raw[:8].decode("latin1").rstrip()
    ext = raw[8:11].decode("latin1").rstrip()
    if not name or name[0] == " ":
        return None
    return f"{name}.{ext}" if ext else name


def read_directory(disk: bytes, p: CpmParams | None = None) -> list[CpmFile]:
    """Parse the CP/M directory and return one CpmFile per logical file.

    Multiple directory entries for the same (user, filename) -- CP/M extents --
    are merged into a single CpmFile with concatenated blocks and summed records.
    """
    if p is None:
        p = softcard_params("dsk")

    raw = bytearray()
    for b in range(p.dir_blocks):
        raw += _read_block(disk, p, b)

    # (user, name) -> {ex: (records, blocks, ro, sys)}
    merged: dict[tuple[int, str], dict] = {}
    valid = 0
    for i in range(p.dir_entries):
        entry = raw[i * 32:i * 32 + 32]
        if len(entry) < 32:
            break
        user = entry[0]
        if user > 0x0F:        # 0xE5 = empty/deleted slot
            continue
        name = _filename(entry)
        if name is None:
            continue
        valid += 1
        ex = entry[12] + entry[14] * 32        # extent number (EX + S2*32)
        rc = entry[15]
        blocks = [b for b in entry[16:32] if b != 0]
        rec = merged.setdefault((user, name), {})
        rec[ex] = (rc, blocks, bool(entry[9] & 0x80), bool(entry[10] & 0x80))

    if valid == 0:
        raise NotCpmFilesystem(
            "no valid CP/M directory entries found; not a SoftCard CP/M filesystem "
            "(or unsupported disk parameters)"
        )

    files: list[CpmFile] = []
    for (user, name), exts in merged.items():
        records = 0
        blocks: list[int] = []
        ro = sys_ = False
        for ex in sorted(exts):
            rc, blks, e_ro, e_sys = exts[ex]
            records += rc
            blocks += blks
            ro = ro or e_ro
            sys_ = sys_ or e_sys
        files.append(CpmFile(name=name, user=user, records=records,
                             blocks=blocks, extents=len(exts),
                             read_only=ro, system=sys_))
    files.sort(key=lambda f: (f.user, f.name))
    return files


def extract_file(disk: bytes, name: str, p: CpmParams | None = None,
                 user: int = 0) -> bytes:
    """Return the raw bytes of a file, truncated to its exact record length."""
    if p is None:
        p = softcard_params("dsk")
    name = name.upper()
    for f in read_directory(disk, p):
        if f.name == name and f.user == user:
            data = bytearray()
            for b in f.blocks:
                data += _read_block(disk, p, b)
            return bytes(data[:f.size])
    raise FileNotFoundError(f"{name!r} (user {user}) not found in CP/M directory")


# ── convenience wrappers that take a path and auto-detect the image format ──

def list_files(path: Path | str) -> list[CpmFile]:
    """Read a SoftCard CP/M disk image and return its file list."""
    disk = read_disk(path)
    return read_directory(disk, softcard_params(detect_format(path)))


def extract(path: Path | str, name: str, user: int = 0) -> bytes:
    """Read a disk image and extract a single file's bytes by name."""
    disk = read_disk(path)
    return extract_file(disk, name, softcard_params(detect_format(path)), user=user)
