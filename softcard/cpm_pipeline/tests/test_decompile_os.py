"""Hybrid OS decompiler tests."""

import shutil
import subprocess
from pathlib import Path

import pytest

from cpm_pipeline.decompile_os import decompile_os

REPO_ROOT = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO_ROOT / "disks" / "CPMV233.DSK"
PO_220 = REPO_ROOT / "disks" / "CPM220Disk1.po"
HAS_SJASMPLUS = shutil.which("sjasmplus") is not None


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV233.DSK missing")
def test_223_all_regions_decompile(tmp_path):
    r = decompile_os(DSK_223, tmp_path / "os", force=True)
    assert r.variant == "softcard_cpm_2_23"
    assert r.regions and all(reg.ok for reg in r.regions), \
        [(reg.name, reg.note) for reg in r.regions if not reg.ok]
    # 6502 regions emit ca65 .s, Z-80 regions emit sjasmplus .asm.
    for reg in r.regions:
        assert reg.asm_path.exists()
        assert reg.asm_path.suffix == (".s" if reg.cpu == "6502" else ".asm")
    # gold tree present for a recognized variant
    assert r.gold_dir and (r.gold_dir / "source" / "CPM223_BIOS.asm").exists()
    assert (r.out_dir / "README.md").exists()


@pytest.mark.skipif(not PO_220.exists(), reason="CPM220Disk1.po missing")
def test_220_regions_decompile(tmp_path):
    r = decompile_os(PO_220, tmp_path / "os", force=True)
    assert r.variant == "softcard_cpm_2_20"
    assert r.regions and all(reg.ok for reg in r.regions)


@pytest.mark.skipif(not (DSK_223.exists() and HAS_SJASMPLUS),
                    reason="CPMV233.DSK or sjasmplus missing")
def test_223_bios_auto_disasm_roundtrips(tmp_path):
    # The machine disassembly of the BIOS must reassemble to the original bytes.
    r = decompile_os(DSK_223, tmp_path / "os", gold=False, force=True)
    bios = next(reg for reg in r.regions if reg.name == "BIOS")
    res = subprocess.run(["sjasmplus", str(bios.asm_path)],
                         capture_output=True, text=True, cwd=str(bios.asm_path.parent))
    assert res.returncode == 0, res.stdout + res.stderr
    rebuilt = bios.asm_path.with_suffix(".bin")
    original = (REPO_ROOT / "cpm-investigation" / "bios_223.bin").read_bytes()[:0x548]
    assert rebuilt.read_bytes() == original, "BIOS auto-disassembly did not round-trip"


def test_unrecognized_disk_is_graceful(tmp_path):
    # A blank image: detect() returns unknown variant; decompile_os should not
    # crash, just report no region map.
    blank = tmp_path / "blank.dsk"
    blank.write_bytes(bytes(143360))
    r = decompile_os(blank, tmp_path / "os", gold=False, force=True)
    assert r.variant == "unknown"
    assert r.regions == []
    assert any("unrecognized" in n for n in r.notes)
