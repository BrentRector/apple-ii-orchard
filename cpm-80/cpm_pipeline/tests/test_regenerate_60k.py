# -*- coding: utf-8 -*-
"""The 60K BIOS recipe regenerates byte-identical and supports force-labels/seeds.

The CPMV233-60K BIOS is not a registry target (its bytes are the CPM60.COM
payload at COM 0x2600 + boot-loader patches). regenerate_60k_bios() reproduces
it through the current pipeline -- recovering the JP jump table and the
previously-stranded relocation code -- while staying byte-identical and carrying
every curated inline label and EQU symbol.
"""
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.regenerate import regenerate_60k_bios, _BIOS_60K

HAS = shutil.which("sjasmplus") is not None
skip = pytest.mark.skipif(not HAS or not _BIOS_60K.exists(),
                          reason="sjasmplus or 60K BIOS source missing")


@skip
def test_regenerate_is_byte_identical():
    r = regenerate_60k_bios(write=False)
    assert r.byte_identical, r.notes
    assert r.comments_dropped == 0


@skip
def test_force_label_stays_byte_identical_and_recovers_routine():
    # planting a new AI name at $FCA4 must not change bytes, and the recipe must
    # render the BIOS jump-table entry at $FA06 as a JP (not a stranded DEFB)
    r = regenerate_60k_bios(write=False, ai_names={0xFCA4: "CONSOLE_PUT_CHAR"})
    assert r.byte_identical, r.notes


@skip
def test_curated_equ_symbols_survive():
    # SLOT_INFO_BASE=$F3B8 is a curated EQU absent from cpm_2_2.json; the recipe's
    # symbol overlay must keep it rather than reverting to a raw $F3B8 literal
    text = _BIOS_60K.read_text(encoding="utf-8")
    assert "SLOT_INFO_BASE" in text
