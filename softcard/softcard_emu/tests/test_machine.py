"""Smoke tests: boot real disk images to interactive states.

These run whole-system boots (a few million emulated instructions);
each ends early via the idle heuristics, so the suite stays fast.
"""

from pathlib import Path

import pytest

from softcard_emu import SoftCardMachine

REPO = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO / "CPMV223-44K" / "CPMV223-44K.DSK"
PO_220 = REPO / "CPMV220" / "CPMV220-Disk1.po"


def _has(p):
    return p.exists()


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_boots_to_prompt_with_videx():
    m = SoftCardMachine(DSK_223)
    res = m.run(total_steps=40_000_000)
    screen = "\n".join(m.screen_text())
    assert "Softcard CP/M" in screen
    assert "44K Ver. 2.23" in screen          # the disk's boot tracks
    assert "A>" in screen
    assert m.videx.fault_count == 0           # 2.23 owns the window correctly
    assert "idle" in res


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_223_dir_lists_directory():
    m = SoftCardMachine(DSK_223)
    m.type_keys("DIR\r")
    m.run(total_steps=80_000_000)
    screen = "\n".join(m.screen_text())
    assert "A>DIR" in screen
    assert "PIP" in screen and "COM" in screen
    assert m.videx.fault_count == 0
    assert len(m.disk_reads) > 0              # directory came off the image


@pytest.mark.skipif(not _has(PO_220), reason="CPMV220-Disk1.po missing")
def test_220_with_videx_faults_and_stays_dark():
    m = SoftCardMachine(PO_220)
    m.run(total_steps=40_000_000)
    # the softcard-videx Part 5 mechanism: window faults, blank screen
    assert m.videx.fault_count > 0
    assert m.videx.vram_writes == 0


@pytest.mark.skipif(not _has(PO_220), reason="CPMV220-Disk1.po missing")
def test_220_without_videx_boots_clean():
    m = SoftCardMachine(PO_220, videx=False)
    res = m.run(total_steps=40_000_000)
    assert "idle" in res                      # waiting at the console


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_language_card_banking():
    m = SoftCardMachine(DSK_223)
    lc = m.lc
    # power-on: ROM readable, distinct from RAM plane
    assert lc.read(0xFF58) == 0x60
    # write-enable via double read of $C083 (RAM read, bank 2)
    lc.access(3, is_read=True)
    lc.access(3, is_read=True)
    assert lc.read_ram and lc.write_en and lc.bank2
    lc.write(0xD000, 0xAB)
    assert lc.read(0xD000) == 0xAB
    # bank 1 is distinct storage
    lc.access(0xB, is_read=True)              # $C08B: RAM read, bank 1
    lc.access(0xB, is_read=True)
    assert lc.read(0xD000) == 0x00            # fresh bank 1
    lc.write(0xD000, 0xCD)
    assert lc.read(0xD000) == 0xCD
    lc.access(3, is_read=True)                # back to bank 2
    assert lc.read(0xD000) == 0xAB
    # ROM read with write enabled: writes land in RAM, reads see ROM
    lc.access(1, is_read=True)
    lc.access(1, is_read=True)                # $C081 x2: ROM read, write en
    assert lc.read(0xFF58) == 0x60
    # even access write-protects
    lc.access(0, is_read=True)
    assert not lc.write_en
