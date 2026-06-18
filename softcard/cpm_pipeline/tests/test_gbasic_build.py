# -*- coding: utf-8 -*-
"""GBASIC.asm is the sole source for GBASIC.COM and must rebuild byte-identical.

The interpreter self-relocates ($100E -> run $3000); the source folds that into
one file via DISP/ENT (the former GBASIC_RUN.asm split was removed). This pins
that consolidation: the committed source, assembled standalone, must equal the
genuine GBASIC.COM extracted from softcard-cpm2.23-44k-system.dsk.
"""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline.reference_data import DISK_2_23_44K_SYSTEM, present

REPO = Path(__file__).resolve().parents[2]               # softcard/
GBASIC = REPO / "CPMV223-44K" / "utilities" / "GBASIC.asm"
DISK = DISK_2_23_44K_SYSTEM
HAS = bool(shutil.which("sjasmplus") and present(DISK))
skip = pytest.mark.skipif(not HAS, reason="sjasmplus or softcard-cpm2.23-44k-system.dsk missing")


@skip
def test_gbasic_disp_source_is_byte_identical():
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                 GBASIC.read_text(encoding="latin-1"))
    built = assemble_z80(src)
    genuine = bytes(extract_file(read_disk(DISK), "GBASIC.COM"))
    assert len(built) == 25600
    assert built == genuine
