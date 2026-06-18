"""Disk-format primitive tests."""

from cpm_pipeline.disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE,
    sector_offset, detect_format,
    SECTOR_SIZE,
)


def test_dos33_interleave_self_inverse_at_anchors():
    """DOS 3.3 interleave: phys 0 → on-disk 0; phys $F → on-disk $F."""
    assert DOS33_INTERLEAVE[0] == 0x0
    assert DOS33_INTERLEAVE[0xF] == 0xF


def test_prodos_interleave_self_inverse_at_anchors():
    assert PRODOS_INTERLEAVE[0] == 0x0
    assert PRODOS_INTERLEAVE[0xF] == 0xF


def test_dos33_offset_track_0():
    """trk0:phys0 → byte 0; trk0:phys2 → byte $0E00 (logical 0x0E)."""
    assert sector_offset(0, 0, "dsk") == 0
    assert sector_offset(0, 2, "dsk") == 0xE * SECTOR_SIZE  # phys 2 = logical $E
    assert sector_offset(0, 5, "dsk") == 0x5 * SECTOR_SIZE  # phys 5 = logical 5


def test_prodos_offset_track_0():
    """ProDOS interleave: phys 1 → on-disk 8."""
    assert sector_offset(0, 0, "po") == 0
    assert sector_offset(0, 1, "po") == 0x8 * SECTOR_SIZE


def test_cpm_offset_identity():
    """CP/M logical order: physical sector P → on-disk position P (identity)."""
    assert sector_offset(0, 0, "cpm") == 0
    assert sector_offset(0, 5, "cpm") == 5 * SECTOR_SIZE
    assert sector_offset(3, 7, "cpm") == (3 * 16 + 7) * SECTOR_SIZE


def test_format_detection():
    assert detect_format("foo.dsk") == "dsk"
    assert detect_format("foo.po") == "po"
    assert detect_format("foo.cpm") == "cpm"
    assert detect_format("FOO.CPM") == "cpm"
    import pytest
    with pytest.raises(ValueError):
        detect_format("foo.bin")
