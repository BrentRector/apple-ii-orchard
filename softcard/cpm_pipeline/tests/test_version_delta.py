"""Phase 6 (Stage 3) — version delta tests."""

import pytest

from cpm_pipeline.reference_data import (
    DISK_2_20B_56K_SYSTEM,
    DISK_2_23_44K_SYSTEM,
    present,
)
from cpm_pipeline.version_delta import compare_disks


@pytest.mark.skipif(not present(DISK_2_23_44K_SYSTEM, DISK_2_20B_56K_SYSTEM),
                    reason="both disks needed")
def test_diff_2_20_vs_2_23_surfaces_videx_fix():
    """The headline test: comparing 2.20 vs 2.23 must mechanically
    surface the Videx-fix delta.

    Specifically:
      * variants differ
      * boot-stub CODE region is byte-identical (the 60-byte stub
        is the same), but DATA region differs (copyright strings)
      * Z-80 reset target differs ($DA00 vs $FA00)
      * BDOS entry target differs ($CC06 vs $9C06)
      * CPU-switch mechanism differs ($C400 vs $0E36)
      * dispatch case 6 only in 2.23 (the Videx fix)
    """
    delta = compare_disks(
        DISK_2_20B_56K_SYSTEM,
        DISK_2_23_44K_SYSTEM,
    )
    # Variant
    assert not delta.same_variant
    # Boot stub: code identical, data differs
    assert delta.boot_stub_code_diff_bytes == 0
    assert delta.boot_stub_data_diff_bytes > 0
    # Reset vector
    assert delta.handoff_a.z80_reset_plant.target_addr == 0xDA00
    assert delta.handoff_b.z80_reset_plant.target_addr == 0xFA00
    # BDOS
    assert delta.handoff_a.bdos_entry_plant.target_addr == 0xCC06
    assert delta.handoff_b.bdos_entry_plant.target_addr == 0x9C06
    # CPU switch
    assert delta.handoff_a.cpu_switch_trigger.target_addr == 0xC400
    assert delta.handoff_b.cpu_switch_trigger.target_addr == 0x0E36
    # Dispatch cases
    assert delta.cases_only_in_b == [6], (
        f"expected case 6 to be only in B (2.23, the Videx fix); "
        f"got cases_only_in_a={delta.cases_only_in_a}, "
        f"cases_only_in_b={delta.cases_only_in_b}"
    )
    # Cases 3 and 4 exist in both but with different handler addresses
    # (because BIOSes live at different base addresses)
    assert 3 in delta.cases_with_different_handler
    assert 4 in delta.cases_with_different_handler


@pytest.mark.skipif(not present(DISK_2_20B_56K_SYSTEM),
                    reason="softcard-cpm2.20b-56k-system-disk1.po missing")
def test_diff_same_disk_is_zero():
    """Diffing a disk against itself surfaces no differences."""
    delta = compare_disks(
        DISK_2_20B_56K_SYSTEM,
        DISK_2_20B_56K_SYSTEM,
    )
    assert delta.same_variant
    assert delta.boot_stub_diff_bytes == 0
    assert delta.cases_only_in_a == []
    assert delta.cases_only_in_b == []
    assert delta.cases_with_different_handler == []


@pytest.mark.skipif(not present(DISK_2_20B_56K_SYSTEM, DISK_2_23_44K_SYSTEM),
                    reason="both disks needed")
def test_diff_summary_string():
    delta = compare_disks(
        DISK_2_20B_56K_SYSTEM,
        DISK_2_23_44K_SYSTEM,
    )
    s = delta.summary()
    assert "DiskDelta" in s
    assert "Videx" in s or "only in B: [6]" in s or "case 6" in s.lower()
