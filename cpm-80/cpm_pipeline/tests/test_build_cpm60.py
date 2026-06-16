# -*- coding: utf-8 -*-
"""CPM60.COM builds byte-identical from its component sources.

The 60K installer image is reassembled from the checked-in component sources
(installer + boot loader + RWTS + CCP + BDOS + the unpatched BIOS template) plus
a documented 125-byte COM-specific overlay, and must equal the original COM.
"""
import json
import shutil

import pytest

from cpm_pipeline.build_cpm60 import (
    build_cpm60_com, reference_com, LAYOUT, _OVERLAY, COM_SIZE,
)

HAS = bool(shutil.which("sjasmplus") and shutil.which("ca65") and shutil.which("ld65"))
skip = pytest.mark.skipif(not HAS, reason="sjasmplus/ca65/ld65 toolchain missing")


@skip
def test_build_is_byte_identical():
    assert build_cpm60_com() == reference_com()


@skip
def test_overlay_is_small_and_documented():
    overlay = json.loads(_OVERLAY.read_text(encoding="utf-8"))
    assert len(overlay["bytes"]) == 125            # ~1% of the 11,264-byte COM
    assert "_doc" in overlay and overlay["ranges"]


@skip
def test_bios_region_is_100pct_unpatched_template():
    # the BIOS occupies COM 0x2600-0x2BFF and must come entirely from the
    # template source -- NO overlay byte may fall in it
    overlay = json.loads(_OVERLAY.read_text(encoding="utf-8"))["bytes"]
    bios = next(r for r in LAYOUT if r.src == "bios")
    assert not any(bios.com_off <= int(o, 16) < bios.com_off + bios.length
                   for o in overlay)


@skip
def test_built_image_is_full_size():
    assert len(build_cpm60_com()) == COM_SIZE == 0x2C00
