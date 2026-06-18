"""Component-level diff: byte differences localized to the OS component."""

from pathlib import Path

import pytest

from cpm_pipeline import chunk_map
from cpm_pipeline.component_diff import (
    system_component_diff, cpm_serial, lineage_groups,
)
from cpm_pipeline.disk_format import sector_offset

REPO = Path(__file__).resolve().parents[2]
DSK_223 = REPO / "CPMV223-44K" / "CPMV223-44K.DSK"
PO_220 = REPO / "CPMV220" / "CPMV220-Disk1.po"


def _has(p):
    return p.exists()


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_identical_disk_has_no_component_diff():
    comp = system_component_diff(DSK_223, DSK_223)
    assert comp is not None
    assert all(d == 0 for d, _t in comp.values())
    # the expected components are all present
    assert {"boot sector", "RWTS", "CCP+BDOS", "BIOS"} <= set(comp)


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_cpm_serial_has_prefix_and_length():
    ser = cpm_serial(DSK_223)
    assert ser is not None
    assert len(ser) == 6
    assert ser[:3] == b"\xbd\x16\x00"          # SoftCard CP/M 2.2 product marker
    assert ser == b"\xbd\x16\x00\x01\x4d\x40"  # CPMV223-44K's known serial


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_lineage_groups_shared_serial():
    # Two copies of one disk share their serial -> a single lineage of 2.
    groups = lineage_groups([DSK_223, DSK_223])
    assert len(groups) == 1
    (serial, disks), = groups.items()
    assert len(disks) == 2
    assert serial.startswith("BD 16 00")


@pytest.mark.skipif(not (_has(DSK_223) and _has(PO_220)), reason="fixtures missing")
def test_lineage_separates_distinct_licenses():
    if cpm_serial(PO_220) is None:
        pytest.skip("2.20 serial not readable")
    groups = lineage_groups([DSK_223, PO_220])
    assert len(groups) == 2                     # different licensed copies


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_flip_in_bios_localizes_to_bios(tmp_path):
    chunks, _ = chunk_map.get_variant("223")
    bios = next(s for s in chunks if s.source_name.endswith("BIOS_Disk"))
    off = sector_offset(bios.track, bios.phys_sector, "dsk")
    data = bytearray(DSK_223.read_bytes())
    data[off] ^= 0xFF                       # corrupt one byte of a BIOS sector
    mod = tmp_path / "mod.dsk"
    mod.write_bytes(data)

    comp = system_component_diff(DSK_223, mod)
    assert comp["BIOS"][0] >= 1
    assert all(d == 0 for c, (d, _t) in comp.items() if c != "BIOS")
