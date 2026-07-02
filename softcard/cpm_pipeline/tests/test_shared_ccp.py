# -*- coding: utf-8 -*-
"""The ONE canonical, C-level 2.23 CCP folds to BOTH origins from a single source.

CPMV223-44K/os/CPM_CCP.asm builds the 2.23-44K disk CCP (ORG $9300, no defines) AND --
relocated +$4000 into the language card via -DCFG_60K (ORG $D300) -- the CCP that
CPM60.COM carries. There is no separate 60K CCP source (the duplicate was retired when
this fold landed). The two builds differ ONLY by the memory axis: every in-image operand
relocates by +$4000 via DISP/labels, and the single fast-loader top-page config constant
changes $A1 -> $F0. See docs/CPM_Unified_Build_Plan.md (Step 4) and CPMV223-60K/CPM60_COM.md.
"""
import shutil

import pytest

HAS = shutil.which("sjasmplus") is not None
skip = pytest.mark.skipif(not HAS, reason="sjasmplus not on PATH")


@skip
def test_canonical_ccp_folds_to_both_44k_and_60k_origins():
    from cpm_pipeline.assemble import assemble_chunk
    from cpm_pipeline.chunk_map import os_module_sources
    from cpm_pipeline.build_cpm60 import _folded_ccp

    ccp44 = assemble_chunk(os_module_sources("223")["CPM_CCP.asm"])   # $9300, no defines
    ccp60 = _folded_ccp()                                              # $D300, -DCFG_60K
    assert len(ccp44) == len(ccp60) == 0x900, "CCP image is not exactly $0900 bytes"

    same = reloc = 0
    genuine = []
    for i, (a, b) in enumerate(zip(ccp44, ccp60)):
        if a == b:
            same += 1
        elif (a + 0x40) & 0xFF == b:          # +$4000 relocation -> high byte +$40
            reloc += 1
        else:
            genuine.append((i, a, b))
    assert reloc >= 100, f"only {reloc} +$4000 relocations -- memory axis not applied?"
    # the ONLY non-relocation delta is the fast-loader top page ($A1 -> $F0)
    assert genuine == [(0x7B4, 0xA1, 0xF0)], (
        f"unexpected non-relocation deltas: "
        f"{[(hex(i), hex(a), hex(b)) for i, a, b in genuine]}")


@skip
def test_60k_ccp_matches_cpm60_com_image():
    """The folded 60K CCP is exactly the CCP region CPM60.COM carries (file $0E00, $0900)."""
    from cpm_pipeline.build_cpm60 import build_cpm60_com, _folded_ccp
    com = build_cpm60_com()
    assert com[0x0E00:0x0E00 + 0x900] == _folded_ccp()
