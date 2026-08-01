# -*- coding: utf-8 -*-
"""The CPMV220/utilities sources must keep assembling to a stable image.

WHY THIS EXISTS. Nothing in the pipeline builds `CPMV220/utilities/*.asm`, so the
byte-identical gate never assembled them. A search-and-replace that converted bare
BDOS function numbers to symbols therefore rewrote `LD C,A` -- a REGISTER move, one
byte -- into `LD C,C_READSTR`, two bytes, because "A" is a valid hex digit and the
pattern accepted it. Every address after it shifted by one and the gate stayed green,
because it never looked. This test makes the tree self-pinning.

WHAT THESE FILES ARE. Not 56K sources, despite living in the 2.20B-56K tree: they
assemble to the 2.20-*44K* disk's programs (PIP is byte-identical to
softcard-cpm2.20-44k-system.dsk's PIP.COM; STAT differs by 20 of 6144 bytes). They
are an older, less-annotated decompilation of the same utilities that
CPMV220-44K/utilities/ now owns canonically. Retiring them is a judgement call for
a human, so this pins them where they are rather than deleting them.

The pin is a SHA256 per file, not a disk comparison, because only some of them
reproduce a disk .COM exactly. Any change to the emitted bytes fails here and has
to be justified by updating the expected digest deliberately.
"""
import hashlib
import importlib.util
import shutil
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
UTIL = REPO / "CPMV220" / "utilities"
_rt_path = Path(__file__).with_name("test_utilities_roundtrip.py")
_spec = importlib.util.spec_from_file_location("_rt", _rt_path)
_rt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rt)

HAS_SJASM = shutil.which("sjasmplus") is not None

# sha256 of the assembled image of each source, captured 2026-08-01 after the
# LD C,A regression above was reverted and all ten were confirmed to assemble
# identically to their pre-conversion bytes.
EXPECTED = {
    "APDOS": "bc540d968bc42122e4d893f6eb1cd59bb2cb3e1e4e7a440f64eb323faeaf4a62",
    "BOOT": "9347da201ccf5eb45803077fd1bae049083a2e6f41c4fa40314b23cf4b52b89c",
    "COPY": "c6201f23e91e985c3c90b6b68165019df78069c65ff9fe0e563135d9e7364c02",
    "CPM56": "6531e47e84539d8a1985031a8e88e8c123e1001b33599a5f57bfcca955903380",
    "DOWNLOAD": "cec6a47748df2a83dc925307b72abedda667e506097759fa40bd062c40f36efc",
    "FORMAT": "d39763385189d975079c80ea5347c07bbeb7d99834dc73ed050519786703a269",
    "GBASIC": "43129366c295ab1af9b4b8806737996e41ba445d45b023729831589261377e49",
    "MBASIC": "a7bec23b31fcec81a43eb535acdd5daaa31a4ca134b034528da4327f3c725694",
    "PIP": "7f9e12a92e2bcfd814b5b680a2f7d5c2a2c50c9a5ef94a6891dcaa3527f08ec2",
    "RW13": "1e93fc99f4dba3de6dcf49b3525248280a9cd5894a689c7bbdd8134324fe58db",
    "STAT": "c60b320dcf538e6ccabb8287c8b6ac415c2158493eb938ffcbb07d72c39d456e",
}


def _digest(name):
    return hashlib.sha256(_rt._assemble(UTIL / f"{name}.asm")).hexdigest()


NAMES = sorted(p.stem for p in UTIL.glob("*.asm")) if UTIL.exists() else []


@pytest.mark.skipif(not HAS_SJASM, reason="sjasmplus not on PATH")
@pytest.mark.parametrize("name", NAMES)
def test_source_assembles(name):
    """Each source must still assemble to a non-empty image."""
    out = _rt._assemble(UTIL / f"{name}.asm")
    assert out, f"CPMV220/utilities/{name}.asm failed to assemble"


@pytest.mark.skipif(not HAS_SJASM, reason="sjasmplus not on PATH")
@pytest.mark.parametrize("name", NAMES)
def test_emitted_bytes_are_pinned(name):
    """A comment-only edit must not move a byte. See the module docstring."""
    if name not in EXPECTED:
        pytest.skip(f"no pinned digest for {name} yet")
    assert _digest(name) == EXPECTED[name], (
        f"CPMV220/utilities/{name}.asm no longer assembles to its pinned image. "
        "If the change was intentional, update EXPECTED deliberately.")
