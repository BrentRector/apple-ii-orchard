"""CP/M filesystem reader tests, validated against the documented directory of
CPMV223-44K.DSK (docs/CPM_Filesystem.md)."""

from pathlib import Path

import pytest

from cpm_pipeline import filesystem as fs
from cpm_pipeline.filesystem import (
    softcard_params, read_directory, NotCpmFilesystem, SOFTCARD_SKEW,
)
from cpm_pipeline.disk_format import (
    read_disk, write_disk, sector_offset, SECTORS_PER_TRACK, TRACKS,
)

REPO_ROOT = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO_ROOT / "CPMV223-44K" / "CPMV223-44K.DSK"
PO_220 = REPO_ROOT / "CPMV220" / "CPMV220-Disk1.po"


def _has(p):
    return p.exists()


# Documented directory of CPMV223-44K.DSK: filename -> total 128-byte records.
GROUND_TRUTH_223 = {
    "APDOS.COM": 13, "ASM.COM": 64, "AUTORUN.COM": 1, "BOOT.COM": 4,
    "CAT.COM": 6, "CONFIGIO.BAS": 58, "COPY.COM": 28, "CPM60.COM": 88,
    "DDT.COM": 40, "DOWNLOAD.COM": 4, "DUMP.ASM": 33, "DUMP.COM": 4,
    "ED.COM": 52, "GBASIC.COM": 200, "LOAD.COM": 14, "MBASIC.COM": 192,
    "MFT.COM": 12, "PATCH.COM": 8, "PIP.COM": 58, "STAT.COM": 48,
    "SUBMIT.COM": 10, "XSUB.COM": 6,
}


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_directory_matches_documented_inventory():
    files = {f.name: f for f in fs.list_files(DSK_223)}
    assert set(files) == set(GROUND_TRUTH_223), (
        f"file set differs: extra={set(files) - set(GROUND_TRUTH_223)}, "
        f"missing={set(GROUND_TRUTH_223) - set(files)}"
    )
    for name, recs in GROUND_TRUTH_223.items():
        assert files[name].records == recs, (
            f"{name}: expected {recs} records, got {files[name].records}"
        )
        assert files[name].size == recs * 128


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_extract_cpm60_exact_size():
    data = fs.extract(DSK_223, "CPM60.COM")
    assert len(data) == 11264  # 88 records x 128


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_standard_utilities_have_com_entry():
    # Standard Digital Research / Microsoft .COM files start with a JP ($C3).
    for name in ("PIP.COM", "MBASIC.COM", "STAT.COM", "ED.COM"):
        data = fs.extract(DSK_223, name)
        assert data[:1] == b"\xC3", f"{name} does not start with JP"


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_multi_extent_file_merges():
    # MBASIC spans two extents (128 + 64 records).
    files = {f.name: f for f in fs.list_files(DSK_223)}
    assert files["MBASIC.COM"].extents == 2
    assert files["MBASIC.COM"].records == 192


@pytest.mark.skipif(not _has(PO_220), reason="CPMV220-Disk1.po missing")
def test_220_po_parses_and_extracts():
    # Same SoftCard skew/params must also work on the 2.20 ProDOS-order disk.
    files = fs.list_files(PO_220)
    assert len(files) >= 5
    names = {f.name for f in files}
    assert "PIP.COM" in names
    # PIP is a standard utility -> JP entry, and extracts to its record length.
    pip = fs.extract(PO_220, "PIP.COM")
    assert pip[:1] == b"\xC3"
    assert len(pip) % 128 == 0


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_cpm_order_roundtrip_matches_dsk(tmp_path):
    """A `.cpm` (CP/M logical sector order) image of the same disk must parse
    identically to the `.dsk`. Build one by re-laying the 223 fixture into
    logical order (logical sector L -> on-disk position L), then compare."""
    dsk = read_disk(DSK_223)
    cpm = bytearray(len(dsk))
    for t in range(TRACKS):
        for L in range(SECTORS_PER_TRACK):
            src = sector_offset(t, SOFTCARD_SKEW[L], "dsk")   # where .dsk holds logical L
            dst = sector_offset(t, L, "cpm")                  # where .cpm holds logical L
            cpm[dst:dst + 256] = dsk[src:src + 256]
    cpm_path = tmp_path / "roundtrip.cpm"
    write_disk(cpm_path, cpm)

    dsk_files = {f.name: f.records for f in fs.list_files(DSK_223)}
    cpm_files = {f.name: f.records for f in fs.list_files(cpm_path)}
    assert cpm_files == dsk_files
    # a real multi-block extraction is byte-identical across the two orderings
    assert fs.extract(cpm_path, "CPM60.COM") == fs.extract(DSK_223, "CPM60.COM")


def test_rejects_non_cpm_image():
    # A disk of zeros has no valid directory entries.
    blank = bytes(143360)
    with pytest.raises(NotCpmFilesystem):
        read_directory(blank, softcard_params("dsk"))
