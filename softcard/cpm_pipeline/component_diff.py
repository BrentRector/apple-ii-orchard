"""Classify *where* two SoftCard CP/M disks differ (by OS component), read the
CP/M serial number, and group disks by serial (originating license).

The chunk map (:mod:`cpm_pipeline.chunk_map`) places every system sector of a
44K 2.20/2.23 disk into a named component -- boot sector, RWTS, stage-2 loader,
install fragments, the CCP+BDOS system image, disk callbacks, BIOS. Comparing
two same-variant disks sector by sector and bucketing the byte differences by
component answers "is it the boot sector? the BIOS? the system image?" instead
of just "they differ".

The **CP/M 2.2 serial number** is the 6 bytes at the BDOS base (so the BDOS
entry vector is base+6: ``JP $9C06`` / ``JP $CC06``), mirrored in the CCP. On
these Microsoft SoftCard disks it is ``BD 16 00`` (a constant product marker)
followed by a 3-byte per-copy unit serial -- e.g. ``BD 16 00 01 4D 40``. It is
NOT a release marker (copies of one release differ) nor a per-format/per-disk
marker (``FORMAT`` writes no system, hence no serial); it is assigned once when a
copy of CP/M is serialized, and rides along through whole-disk ``COPY`` and
through ``CPM56``/``CPM60`` memory-resizes unchanged. So it fingerprints the
**licensed copy a disk's system descends from** -- a lineage signal.

Filesystem-level differences (which ``.COM`` files differ) are reported
separately by :mod:`cpm_pipeline.dedup`; component classification covers the
reserved system tracks (0-2) of the 44K layouts (60K relocates the system into
the Language Card and is not classified here). Serial reading and lineage
grouping work on any layout.
"""

from __future__ import annotations

from collections import Counter, OrderedDict
from pathlib import Path

from .format_detect import detect
from .disk_format import sector_offset, SECTOR_SIZE
from . import chunk_map

_VARIANT = {"softcard_cpm_2_23": "223", "softcard_cpm_2_20": "220"}

# Stable display order, system-track layout front to back.
_ORDER = ["boot sector", "RWTS", "stage-2 loader", "install fragments",
          "CCP+BDOS", "disk callbacks", "BIOS"]

# Microsoft SoftCard CP/M 2.2 serial product marker; the 6-byte serial begins here.
SERIAL_PREFIX = b"\xbd\x16\x00"
SERIAL_LEN = 6
# Reserved system area = tracks 0-2, which sit in the first 0x3000 bytes of a
# track-sequential image (.dsk/.po/.cpm all store sectors track by track). The
# serial lives here (CCP + BDOS); scanning it avoids filesystem false positives.
_SYSTEM_AREA = 3 * 16 * SECTOR_SIZE


def _component_of(spec) -> str:
    name = spec.source_name
    if name.endswith("BootLoader"):
        addr = spec.src_offset + 0x0800       # boot-loader image origin
        if addr == 0x0800:
            return "boot sector"
        if 0x0A00 <= addr < 0x1000:
            return "RWTS"
        if 0x1000 <= addr < 0x1200:
            return "stage-2 loader"
        return "install fragments"
    if name.endswith("SystemImage"):
        return "CCP+BDOS"
    if name.endswith("DiskCallbacks"):
        return "disk callbacks"
    if name.endswith("BIOS_Disk"):
        return "BIOS"
    return name                                # pragma: no cover - future regions


def cpm_serial(path) -> bytes | None:
    """Return the 6-byte CP/M serial number, or None if not present.

    Located by the ``BD 16 00`` product marker in the reserved system tracks
    (0-2). Works across the 44K and 60K layouts and ``.dsk``/``.po``/``.cpm``
    order, because the serial's bytes are contiguous within one sector and the
    system tracks occupy the first 0x3000 bytes of a track-sequential image. The
    serial is mirrored (CCP + BDOS), so the most frequent match is returned.
    """
    data = Path(path).read_bytes()[:_SYSTEM_AREA]
    hits: Counter[bytes] = Counter()
    i = data.find(SERIAL_PREFIX)
    while i != -1 and i + SERIAL_LEN <= len(data):
        hits[bytes(data[i:i + SERIAL_LEN])] += 1
        i = data.find(SERIAL_PREFIX, i + 1)
    return hits.most_common(1)[0][0] if hits else None


def serial_str(serial: bytes | None) -> str:
    """Human display: the 6 hex bytes (or 'unknown')."""
    return serial.hex(" ").upper() if serial else "unknown"


def lineage_groups(paths) -> "OrderedDict[str, list[Path]]":
    """Group disks by CP/M serial (originating license).

    Returns an ``OrderedDict`` keyed by serial string (``'unknown'`` for disks
    with no readable serial), each mapping to the list of paths that share it.
    Disks sharing a serial descend from the same licensed CP/M copy -- even if
    they differ at the byte level (different memory size, boot loader, files).
    """
    groups: "OrderedDict[str, list[Path]]" = OrderedDict()
    for p in paths:
        p = Path(p)
        groups.setdefault(serial_str(cpm_serial(p)), []).append(p)
    return groups


def system_component_diff(path_a, path_b):
    """Bucket system-track (tracks 0-2) byte differences by OS component.

    Returns an ordered ``{component: (diff_bytes, total_bytes)}``, or ``None`` if
    the two disks aren't the same classifiable variant (different/unknown
    variant, a 60K layout, or a ``.cpm`` CP/M-order image).
    """
    path_a, path_b = Path(path_a), Path(path_b)
    ia, ib = detect(path_a), detect(path_b)
    if ia.variant != ib.variant or ia.variant not in _VARIANT:
        return None
    if "cpm" in (ia.format, ib.format):
        return None
    chunks, _ = chunk_map.get_variant(_VARIANT[ia.variant])
    raw_a = path_a.read_bytes()
    raw_b = path_b.read_bytes()
    diff: dict[str, int] = {}
    total: dict[str, int] = {}
    for spec in chunks:
        comp = _component_of(spec)
        oa = sector_offset(spec.track, spec.phys_sector, ia.format)
        ob = sector_offset(spec.track, spec.phys_sector, ib.format)
        sa = raw_a[oa:oa + SECTOR_SIZE]
        sb = raw_b[ob:ob + SECTOR_SIZE]
        d = sum(1 for x, y in zip(sa, sb) if x != y)
        diff[comp] = diff.get(comp, 0) + d
        total[comp] = total.get(comp, 0) + SECTOR_SIZE
    return OrderedDict((c, (diff[c], total[c])) for c in _ORDER if c in total)
