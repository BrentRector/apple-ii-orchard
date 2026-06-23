"""Regression tests for the extracted embedded-6502 RPC block (CPM_RPC6502.s).

The 2.20 CCP's $9400-$9500 block is decompiled to its own ca65 source and
INCBIN'd by the Z-80 SystemImage. These tests enforce:
  1. the committed CPM_RPC6502.s reassembles BYTE-IDENTICAL to the on-disk block
     in both memory configs (44K $A400 buffer / 56K $E400 via CFG_56K), and
  2. the gen_rpc6502 recipe still ASSEMBLES to those same bytes (regenerate-
     fidelity at the byte level).

The committed .s is now the hand-enriched MASTER (C-level routine headers + body
comments, the `+1` cover entry converted to a clean .byte-cover label, inline
addresses moved to CPM_RPC6502.lst), so the generator is PROVENANCE-ONLY. We pin
BYTES, not source text (the BASIC.asm precedent).
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]
OS = REPO / "softcard" / "CPMV220-44K" / "os"
RPC_S = OS / "CPM_RPC6502.s"
RPC_CFG = OS / "CPM_RPC6502.cfg"

HAS_CA65 = shutil.which("ca65") is not None and shutil.which("ld65") is not None

BLOCK_START = 0x9400
BLOCK_LEN = 0x101   # $9400-$9500 inclusive


def _block_bytes():
    from cpm_pipeline.reference_data import INVEST
    sysimg = (INVEST / "sysimg_220_44k.bin")
    if not sysimg.exists():
        return None
    data = sysimg.read_bytes()
    return data[BLOCK_START - 0x9300:BLOCK_START - 0x9300 + BLOCK_LEN]


def _assemble(defines=(), text=None):
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        src = text if text is not None else RPC_S.read_text(encoding="utf-8")
        (td / "r.s").write_text(src, encoding="utf-8")
        (td / "r.cfg").write_text(RPC_CFG.read_text(encoding="utf-8"), encoding="utf-8")
        cmd = ["ca65", str(td / "r.s"), "-o", str(td / "r.o")]
        for d in defines:
            cmd += ["-D", d]
        if subprocess.run(cmd, capture_output=True, text=True).returncode:
            return b""
        subprocess.run(["ld65", "-C", str(td / "r.cfg"), "-o", str(td / "r.bin"),
                        str(td / "r.o")], capture_output=True, text=True)
        return (td / "r.bin").read_bytes() if (td / "r.bin").exists() else b""


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_rpc6502_byte_identical_44k():
    block = _block_bytes()
    if block is None:
        pytest.skip("sysimg_220_44k.bin missing")
    assert _assemble() == block


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_rpc6502_byte_identical_56k():
    block = _block_bytes()
    if block is None:
        pytest.skip("sysimg_220_44k.bin missing")
    want = bytearray(block)
    want[0x94AE - BLOCK_START] = 0xE4   # 56K warm-boot buffer high byte ($E400)
    assert _assemble(("CFG_56K",)) == bytes(want)


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_gen_rpc6502_reproduces_block_bytes():
    """The recipe (provenance) still assembles to the on-disk block, and to the
    same bytes as the committed hand-enriched master."""
    from cpm_pipeline.gen_rpc6502 import generate
    if not (REPO / "softcard" / "cpm-investigation" / "sysimg_220_44k.bin").exists():
        pytest.skip("sysimg_220_44k.bin missing")
    block = _block_bytes()
    if block is None:
        pytest.skip("sysimg_220_44k.bin missing")
    gen_bytes = _assemble(text=generate())
    assert gen_bytes == block
    assert gen_bytes == _assemble()   # generator output == committed master, byte-for-byte
