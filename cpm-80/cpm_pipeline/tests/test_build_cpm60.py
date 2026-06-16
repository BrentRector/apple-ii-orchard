# -*- coding: utf-8 -*-
"""CPM60.COM builds byte-identical from its component sources.

The 60K installer image is reassembled purely from the checked-in component
sources (installer + boot loader + RWTS + CCP + BDOS + the as-shipped BIOS),
each in its as-shipped form, and must equal the original COM with no transform.
"""
import shutil

import pytest

from cpm_pipeline.build_cpm60 import (
    build_cpm60_com, reference_com, LAYOUT, COM_SIZE,
)

HAS = bool(shutil.which("sjasmplus") and shutil.which("ca65") and shutil.which("ld65"))
skip = pytest.mark.skipif(not HAS, reason="sjasmplus/ca65/ld65 toolchain missing")


@skip
def test_build_is_byte_identical():
    # pure component-source build, no transform: every byte comes from a source
    assert build_cpm60_com() == reference_com()


@skip
def test_built_image_is_full_size():
    assert len(build_cpm60_com()) == COM_SIZE == 0x2C00
