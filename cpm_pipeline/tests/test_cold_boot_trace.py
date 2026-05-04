"""Phase 4 (Stage 5) — Z-80 cold-boot trace tests."""

from pathlib import Path

import pytest

from cpm_pipeline.cold_boot_trace import (
    trace_cold_boot, BIOS_ENTRY_NAMES, COLD_BOOT_GENERATOR_SIGNATURE,
)


REPO_ROOT = Path(__file__).resolve().parents[2]


def _has(p):
    return (REPO_ROOT / p).exists()


def test_signature_constants():
    assert len(COLD_BOOT_GENERATOR_SIGNATURE) == 7
    # First three bytes are LD HL,$F3B8 (the slot-info table address)
    assert COLD_BOOT_GENERATOR_SIGNATURE[:3] == b"\x21\xB8\xF3"
    # The names list has all 17 standard CP/M BIOS entries
    assert len(BIOS_ENTRY_NAMES) == 17
    assert BIOS_ENTRY_NAMES[0] == "BOOT"
    assert BIOS_ENTRY_NAMES[15] == "LISTST"
    assert BIOS_ENTRY_NAMES[16] == "SECTRAN"


@pytest.mark.skipif(not _has("cpm-investigation/bios_223.bin"),
                    reason="bios_223.bin missing")
def test_trace_2_23_jump_table():
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_223.bin")
    assert sched.bios_org == 0xFAB8
    assert sched.bios_size == 0x0548  # 1352 bytes for the live BIOS
    # All 17 entries identified
    assert len(sched.jump_table) == 17
    # Entry 0 is BOOT; should JP to $FED1 (the runtime-populated landing)
    assert sched.jump_table[0].name == "BOOT"
    assert sched.jump_table[0].target == 0xFED1
    # Entry 1 (WBOOT) jumps to BOOT itself in this build
    assert sched.jump_table[1].name == "WBOOT"
    assert sched.jump_table[1].target == 0xFAB8
    # Inline entries 15 + 16 have no JP target
    assert sched.jump_table[15].name == "LISTST"
    assert sched.jump_table[15].target is None


@pytest.mark.skipif(not _has("cpm-investigation/bios_223.bin"),
                    reason="bios_223.bin missing")
def test_trace_2_23_cold_boot_generator():
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_223.bin")
    # Cold-boot generator signature is at $FB3D in the live BIOS
    assert sched.cold_boot_generator_addr == 0xFB3D


@pytest.mark.skipif(not _has("cpm-investigation/bios_223.bin"),
                    reason="bios_223.bin missing")
def test_trace_2_23_dispatch_cases():
    """The Videx-fix discriminator: 2.23 has dispatch cases for devices 3, 4, 6."""
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_223.bin")
    cases = {dc.device_code: dc.handler_addr for dc in sched.dispatch_cases}
    assert 3 in cases, "missing device-3 dispatch case"
    assert 4 in cases, "missing device-4 dispatch case"
    assert 6 in cases, "missing device-6 dispatch case (the Videx fix)"
    # Known handler addresses
    assert cases[3] == 0xFE81  # INIT_KEYBOARD
    assert cases[4] == 0xFD83  # INIT_PASCAL_1_0
    assert cases[6] == 0xFDB0  # INIT_PASCAL_1_1 -- the 2.23-only fix


@pytest.mark.skipif(not _has("cpm-investigation/bios_220.bin"),
                    reason="bios_220.bin missing")
def test_trace_2_20_jump_table():
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_220.bin")
    assert sched.bios_org == 0xDACC
    assert len(sched.jump_table) == 17
    # 2.20 BOOT JPs to $DEA8 (the 2.20 equivalent of 2.23's $FED1 landing)
    assert sched.jump_table[0].target == 0xDEA8


@pytest.mark.skipif(not _has("cpm-investigation/bios_220.bin"),
                    reason="bios_220.bin missing")
def test_trace_2_20_dispatch_cases_lacks_device_6():
    """The Videx-fix delta: 2.20 has cases for devices 3 and 4 only."""
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_220.bin")
    cases = {dc.device_code for dc in sched.dispatch_cases}
    assert 3 in cases
    assert 4 in cases
    assert 6 not in cases, (
        "2.20 should NOT have a device-6 case (that's the 2.23-only Videx "
        f"fix); got cases for devices {sorted(cases)}"
    )


def test_summary_string():
    if not _has("cpm-investigation/bios_223.bin"):
        pytest.skip("bios_223.bin missing")
    sched = trace_cold_boot(REPO_ROOT / "cpm-investigation" / "bios_223.bin")
    s = sched.summary()
    assert "ColdBootSchedule" in s
    assert "BOOT" in s and "SECTRAN" in s  # jump-table names render
