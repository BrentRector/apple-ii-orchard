"""Regression tests for the SECOND extracted embedded-6502 block
(CPM_RPC6502_Restart.s -- the $9600-$9700 cold-restart/RPC service).

The 2.20 CCP's $9600-$9700 block is decompiled to its own ca65 source and
INCBIN'd by the Z-80 CCP image. These tests enforce:
  1. the committed CPM_RPC6502_Restart.s reassembles BYTE-IDENTICAL to the
     on-disk block, and
  2. the gen_rpc6502_restart recipe still ASSEMBLES to those same bytes
     (regenerate-fidelity at the byte level).

The committed .s is now the hand-enriched MASTER (C-level phase headers + body
comments, inline addresses moved to CPM_RPC6502_Restart.lst), so the generator
is PROVENANCE-ONLY -- it captured the initial mechanical decode. We therefore
pin BYTES, not source text (the BASIC.asm precedent: byte-identical is the gate,
the editable source carries the understanding).
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]
OS = REPO / "softcard" / "CPMV220-44K" / "os"
RPC_S = OS / "CPM_RPC6502_Restart.s"
RPC_CFG = OS / "CPM_RPC6502_Restart.cfg"

HAS_CA65 = shutil.which("ca65") is not None and shutil.which("ld65") is not None

BLOCK_START = 0x9600
BLOCK_LEN = 0x101   # $9600-$9700 inclusive


def _block_bytes():
    from cpm_pipeline.reference_data import INVEST
    sysimg = (INVEST / "sysimg_220_44k.bin")
    if not sysimg.exists():
        return None
    data = sysimg.read_bytes()
    return data[BLOCK_START - 0x9300:BLOCK_START - 0x9300 + BLOCK_LEN]


def _assemble(text=None):
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        src = text if text is not None else RPC_S.read_text(encoding="utf-8")
        (td / "r.s").write_text(src, encoding="utf-8")
        (td / "r.cfg").write_text(RPC_CFG.read_text(encoding="utf-8"), encoding="utf-8")
        cmd = ["ca65", str(td / "r.s"), "-o", str(td / "r.o")]
        if subprocess.run(cmd, capture_output=True, text=True).returncode:
            return b""
        subprocess.run(["ld65", "-C", str(td / "r.cfg"), "-o", str(td / "r.bin"),
                        str(td / "r.o")], capture_output=True, text=True)
        return (td / "r.bin").read_bytes() if (td / "r.bin").exists() else b""


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_rpc6502_restart_byte_identical():
    block = _block_bytes()
    if block is None:
        pytest.skip("sysimg_220_44k.bin missing")
    assert _assemble() == block


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_gen_rpc6502_restart_reproduces_block_bytes():
    """The recipe (provenance) still assembles to the on-disk block, and to the
    same bytes as the committed hand-enriched master."""
    from cpm_pipeline.gen_rpc6502_restart import generate
    if not (REPO / "softcard" / "cpm-investigation" / "sysimg_220_44k.bin").exists():
        pytest.skip("sysimg_220_44k.bin missing")
    block = _block_bytes()
    if block is None:
        pytest.skip("sysimg_220_44k.bin missing")
    gen_bytes = _assemble(generate())
    assert gen_bytes == block
    assert gen_bytes == _assemble()   # generator output == committed master, byte-for-byte
