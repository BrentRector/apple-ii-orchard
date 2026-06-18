"""Phase 5 (Stage 4) — handoff identification tests."""

import pytest

from cpm_pipeline.handoff import find_handoff
from cpm_pipeline.reference_data import (
    DISK_2_20B_56K_SYSTEM,
    DISK_2_23_44K_SYSTEM,
    present,
)


@pytest.mark.skipif(not present(DISK_2_23_44K_SYSTEM), reason="2.23 44K system disk missing")
def test_handoff_2_23():
    h = find_handoff(DISK_2_23_44K_SYSTEM)
    # Z-80 reset vector: 6502 plants JP $FA00 at Apple $1000-$1002
    assert h.z80_reset_plant is not None
    assert h.z80_reset_plant.plant_addr == 0x1000
    assert h.z80_reset_plant.target_addr == 0xFA00
    # CPU switch: JSR $0E36 in the warm-boot routine
    assert h.cpu_switch_trigger is not None
    assert h.cpu_switch_trigger.target_addr == 0x0E36
    assert 0x13C0 <= h.cpu_switch_trigger.pc_in_loader <= 0x13E0
    # BDOS vector (auto-loaded from cpm-investigation/bios_223.bin):
    # the Z-80 BIOS plants JP $9C06 at Z-80 $0005
    assert h.bdos_entry_plant is not None
    assert h.bdos_entry_plant.target_addr == 0x9C06


@pytest.mark.skipif(not present(DISK_2_20B_56K_SYSTEM), reason="2.20B 56K system disk 1 missing")
def test_handoff_2_20():
    h = find_handoff(DISK_2_20B_56K_SYSTEM)
    # Z-80 reset: JP $DA00 (2.20's BIOS at $DACC, cold-boot landing $DA00)
    assert h.z80_reset_plant is not None
    assert h.z80_reset_plant.target_addr == 0xDA00
    # CPU switch: 2.20 uses JSR $C400 (slot-4 device select), not $0E36
    assert h.cpu_switch_trigger is not None
    assert h.cpu_switch_trigger.target_addr == 0xC400
    # BDOS vector: 2.20's BDOS is at $CC06 (vs 2.23's $9C06)
    assert h.bdos_entry_plant is not None
    assert h.bdos_entry_plant.target_addr == 0xCC06


@pytest.mark.skipif(not present(DISK_2_23_44K_SYSTEM), reason="2.23 44K system disk missing")
def test_handoff_summary_string():
    h = find_handoff(DISK_2_23_44K_SYSTEM)
    s = h.summary()
    assert "HandoffInfo" in s
    assert "JP $FA00" in s
    assert "JSR $0E36" in s
