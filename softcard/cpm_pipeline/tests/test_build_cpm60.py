# -*- coding: utf-8 -*-
"""CPM60.COM builds byte-identical to the genuine file on CPMV233.DSK.

Two independent build paths must both reproduce the original:
  * the canonical single master source CPM60.asm (DISP places each relocating
    Z-80 module as real code at its run address);
  * a cross-check that concatenates separately assembled components per a
    Python layout table.
The reference is the real CPM60.COM extracted from the disk image -- every byte
comes from an as-shipped source, with no post-placement transform.
"""
import shutil

import pytest

from cpm_pipeline.build_cpm60 import (
    build_cpm60_com, build_cpm60_com_via_layout, reference_com, COM_SIZE,
)

HAS = bool(shutil.which("sjasmplus") and shutil.which("ca65") and shutil.which("ld65"))
skip = pytest.mark.skipif(not HAS, reason="sjasmplus/ca65/ld65 toolchain missing")


@skip
def test_master_build_is_byte_identical():
    # single master source (DISP/MODULE/INCBIN) == the genuine disk file
    assert build_cpm60_com() == reference_com()


@skip
def test_layout_crosscheck_is_byte_identical():
    # independent component-concat path agrees with the master and the disk
    assert build_cpm60_com_via_layout() == reference_com()


@skip
def test_both_paths_agree():
    assert build_cpm60_com() == build_cpm60_com_via_layout()


@skip
def test_built_image_is_full_size():
    assert len(build_cpm60_com()) == COM_SIZE == 0x2C00
