"""Regression tests for the extracted STAT.COM 6502 work-buffer tail (STAT_6502.s).

STAT.COM's tail ($15BD-$18FF) is stale assembler-buffer content -- a fragment of
6502 object code followed by a 6502 source listing -- extracted to its own ca65
source and INCBIN'd by STAT.asm. Byte-identical reassembly of STAT.COM as a whole
is already enforced by test_utilities_roundtrip; these tests additionally enforce:
  1. the committed STAT_6502.s reassembles BYTE-IDENTICAL to the on-disk tail, and
  2. the gen_stat_6502 recipe reproduces the committed source + config verbatim
     (regenerate-from-source fidelity, mirroring test_rpc6502).
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]
UTIL = REPO / "softcard" / "CPMV220-44K" / "utilities"
STAT_S = UTIL / "STAT_6502.s"
STAT_CFG = UTIL / "STAT_6502.cfg"

HAS_CA65 = shutil.which("ca65") is not None and shutil.which("ld65") is not None

BLOCK_START = 0x15BD
BLOCK_END = 0x1900   # exclusive


def _tail_bytes():
    from cpm_pipeline.filesystem import read_disk, extract_file
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM, present
    if not present(DISK_2_20_44K_SYSTEM):
        return None
    com = bytes(extract_file(read_disk(Path(DISK_2_20_44K_SYSTEM)), "STAT.COM"))
    return com[BLOCK_START - 0x100:BLOCK_END - 0x100]


def _assemble():
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        (td / "s.s").write_text(STAT_S.read_text(encoding="utf-8"), encoding="utf-8")
        (td / "s.cfg").write_text(STAT_CFG.read_text(encoding="utf-8"), encoding="utf-8")
        if subprocess.run(["ca65", str(td / "s.s"), "-o", str(td / "s.o")],
                          capture_output=True, text=True).returncode:
            return b""
        subprocess.run(["ld65", "-C", str(td / "s.cfg"), "-o", str(td / "s.bin"),
                        str(td / "s.o")], capture_output=True, text=True)
        return (td / "s.bin").read_bytes() if (td / "s.bin").exists() else b""


@pytest.mark.skipif(not HAS_CA65, reason="ca65/ld65 not on PATH")
def test_stat_6502_byte_identical():
    tail = _tail_bytes()
    if tail is None:
        pytest.skip("2.20-44K system disk missing")
    assert _assemble() == tail


def test_gen_stat_6502_reproduces_committed_source():
    """The recipe regenerates the committed source + config verbatim (no drift)."""
    from cpm_pipeline.filesystem import read_disk  # noqa: F401  (import probe)
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM, present
    if not present(DISK_2_20_44K_SYSTEM):
        pytest.skip("2.20-44K system disk missing")
    from cpm_pipeline.gen_stat_6502 import generate, config
    assert generate() == STAT_S.read_text(encoding="utf-8")
    assert config() == STAT_CFG.read_text(encoding="utf-8")
