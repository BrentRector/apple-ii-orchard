# -*- coding: utf-8 -*-
"""The shared CCP source builds byte-identical at both the 44K and 60K origins
from one file via two symbols (SYS_BASE + MEMTOP_PAGE)."""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80

REPO = Path(__file__).resolve().parents[2]               # softcard/
SHARED = REPO / "src" / "os" / "CPM_CCP.asm"
CCP60 = REPO / "decompiled" / "CPMV233-60K" / "os" / "CPM_CCP.asm"
HAS = shutil.which("sjasmplus") is not None
skip = pytest.mark.skipif(not HAS or not SHARED.exists(), reason="sjasmplus or shared CCP missing")


def _build(sys_base, memtop):
    t = SHARED.read_text(encoding="latin-1")
    t = t.replace("SYS_BASE    EQU $D300", f"SYS_BASE    EQU ${sys_base:04X}")
    t = t.replace("MEMTOP_PAGE EQU $F0", f"MEMTOP_PAGE EQU ${memtop:02X}")
    t = re.sub(r'(SAVEBIN\s+"[^"]+",\s*)SYS_BASE', r'\1' + f"${sys_base:04X}", t)
    return assemble_z80(t)


@skip
def test_60k_build_is_byte_identical():
    ccp60 = assemble_z80(re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                                CCP60.read_text(encoding="latin-1")))
    assert _build(0xD300, 0xF0) == ccp60


@skip
def test_44k_build_relocates_by_symbols_alone():
    b60 = _build(0xD300, 0xF0)
    b44 = _build(0x9300, 0xA1)
    assert len(b44) == len(b60)
    # dispatch-table entry $D718 -> $9718 (DEFW relocated): high byte $D7 -> $97
    assert b60[0x371] == 0xD7 and b44[0x371] == 0x97
    # the SYS_BASE-1 top-of-TPA pointer ($D2FF -> $92FF): high byte $D2 -> $92
    assert b60[0xDA65 - 0xD300] == 0xD2 and b44[0xDA65 - 0xD300] == 0x92
    # MEMTOP_PAGE config constant: $F0 (60K) -> $A1 (44K), NOT a relocation
    assert b60[0xDAB4 - 0xD300] == 0xF0 and b44[0xDAB4 - 0xD300] == 0xA1
