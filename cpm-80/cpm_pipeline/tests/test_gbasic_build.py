# -*- coding: utf-8 -*-
"""GBASIC.asm is the sole source for GBASIC.COM and must rebuild byte-identical.

The interpreter self-relocates ($100E -> run $3000); the source folds that into
one file via DISP/ENT (the former GBASIC_RUN.asm split was removed). This pins
that consolidation: the committed source, assembled standalone, must equal the
genuine GBASIC.COM extracted from CPMV233.DSK.
"""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80
from cpm_pipeline.filesystem import read_disk, extract_file

REPO = Path(__file__).resolve().parents[2]               # cpm-80/
GBASIC = REPO / "decompiled" / "CPMV233" / "utilities" / "GBASIC.asm"
DISK = REPO / "disks" / "CPMV233.DSK"
HAS = bool(shutil.which("sjasmplus") and DISK.exists())
skip = pytest.mark.skipif(not HAS, reason="sjasmplus or CPMV233.DSK missing")


@skip
def test_gbasic_disp_source_is_byte_identical():
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                 GBASIC.read_text(encoding="latin-1"))
    built = assemble_z80(src)
    genuine = bytes(extract_file(read_disk(DISK), "GBASIC.COM"))
    assert len(built) == 25600
    assert built == genuine
