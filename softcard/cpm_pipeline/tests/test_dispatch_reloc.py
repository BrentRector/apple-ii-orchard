# -*- coding: utf-8 -*-
"""Computed-dispatch resolution makes the CCP relocatable by ORG change alone."""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80, disasm_z80_region, load_symbols

REPO_ROOT = Path(__file__).resolve().parents[2]          # softcard/
CCP = REPO_ROOT / "decompiled" / "CPMV233-60K" / "os" / "CPM_CCP.asm"
SYMS = REPO_ROOT.parent / "shared" / "symbols" / "cpm_2_2.json"
HAS_SJASMPLUS = shutil.which("sjasmplus") is not None

skip = pytest.mark.skipif(not HAS_SJASMPLUS or not CCP.exists(),
                          reason="sjasmplus or CPM_CCP.asm missing")


def _ccp_image():
    src0 = CCP.read_text(encoding="latin-1")
    return assemble_z80(re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"', src0))


def _disasm(ccp, org):
    mem = bytearray(0x10000)
    mem[org:org + len(ccp)] = ccp
    return disasm_z80_region(mem, org, len(ccp), symbols=load_symbols(str(SYMS)),
                             seeds=[org], resolve_dispatch=True, source_name="CPM_CCP")


@skip
def test_dispatch_table_renders_defw_and_roundtrips():
    ccp = _ccp_image()
    src = _disasm(ccp, 0xD300)
    # the $D670 computed-dispatch table (7 entries) now renders relocatable DEFW,
    # not raw DEFB
    assert src.count("DEFW") >= 7
    assert "DEFB    $18,$D7" not in src        # the old non-relocatable form is gone
    # native-ORG round-trip is byte-identical
    assert assemble_z80(src) == ccp


@skip
def test_relocates_by_org_change_alone():
    ccp = _ccp_image()
    src = _disasm(ccp, 0xD300)
    # change ONLY the ORG (and the SAVEBIN base) and reassemble
    src9 = src.replace("ORG $D300", "ORG $9300")
    src9 = re.sub(r'(SAVEBIN\s+"[^"]+",\s*)\$D300', r'\1$9300', src9)
    b9 = assemble_z80(src9)
    assert len(b9) == len(ccp)
    # the $D670 dispatch table's first entry ($D718) relocated to $9718: its high
    # byte moved $D7 -> $97 by ORG change alone (DEFW <label>, not a frozen DEFB).
    off = 0xD670 - 0xD300 + 1                   # high byte of entry 0
    assert ccp[off] == 0xD7 and b9[off] == 0x97
    # a data-variable operand high byte likewise relocated: LD ($DBA7),A at $D3C1
    # (32 A7 DB, little-endian) -> $9BA7; the high byte at $D3C3 went $DB -> $9B.
    off2 = 0xD3C3 - 0xD300
    assert ccp[off2] == 0xDB and b9[off2] == 0x9B
