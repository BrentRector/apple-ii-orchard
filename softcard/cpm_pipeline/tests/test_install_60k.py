# -*- coding: utf-8 -*-
"""The 2.23-60K disk is REPRODUCIBLE by running the byte-built CPM60.COM installer.

softcard_emu drives the real CPM60.COM install on the archived 2.23-44K disk; the
result must be byte-identical to the committed CPMV223-60K-EMU.DSK. This is the
"produced by running CPM60.COM on a 2.23-44K disk" provenance for the 60K resource.

Slow (it boots + runs the installer in-emulator); kept because it is the only gate
that proves the byte-built installer actually produces the shipped 60K disk.
"""
import shutil

import pytest

HAS = shutil.which("sjasmplus") is not None


@pytest.mark.skipif(not HAS, reason="sjasmplus not on PATH")
def test_installer_run_reproduces_emu_disk():
    from cpm_pipeline.install_60k import build_60k_disk_via_installer
    from cpm_pipeline.disk_format import read_disk
    from cpm_pipeline.reference_data import (
        DISK_2_23_44K_SYSTEM, DISK_2_23_60K_EMU, present)
    if not present(DISK_2_23_44K_SYSTEM, DISK_2_23_60K_EMU):
        pytest.skip("reference disk(s) missing")
    produced = build_60k_disk_via_installer()
    emu = bytes(read_disk(str(DISK_2_23_60K_EMU)))
    assert len(produced) == len(emu) == 143360
    # filesystem (tracks 3+) is byte-identical to the 44K carrier; only system tracks change
    d44 = bytes(read_disk(str(DISK_2_23_44K_SYSTEM)))
    SYS = 3 * 16 * 256
    assert produced[SYS:] == d44[SYS:], "installer must not touch the filesystem"
    assert produced != d44[:len(produced)], "installer must rewrite the system tracks"
    assert produced == emu, "installer output is not the committed 60K EMU disk"
