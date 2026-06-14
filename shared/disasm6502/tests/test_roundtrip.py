"""Round-trip tests: disasm output must reassemble byte-identical to input.

Requires ca65 + ld65 on PATH. Skips silently if not present.
"""

import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

from disasm6502.cli import main as disasm_main


REPO_ROOT = Path(__file__).resolve().parents[2]
HAS_CA65 = shutil.which("ca65") is not None and shutil.which("ld65") is not None


def _roundtrip(input_path, org, *, entries=(), data_regions=(), symbols=()):
    """Run disasm -> ca65 -> ld65 and return the assembled bytes."""
    input_path = Path(input_path)
    with tempfile.TemporaryDirectory() as tmp:
        out_base = Path(tmp) / "rt"
        argv = [str(input_path), "--org", org, "--output", str(out_base)]
        for s in symbols:
            argv += ["--symbols", str(s)]
        for e in entries:
            argv += ["--entry", e]
        for d in data_regions:
            argv += ["--data-region", d]
        rc = disasm_main(argv)
        assert rc == 0, "disasm CLI failed"
        s_path = out_base.with_suffix(".s")
        cfg_path = out_base.with_suffix(".cfg")
        o_path = out_base.with_suffix(".o")
        bin_path = out_base.with_suffix(".bin")
        subprocess.run(["ca65", str(s_path), "-o", str(o_path)],
                       check=True, capture_output=True)
        subprocess.run(["ld65", "-C", str(cfg_path), "-o", str(bin_path),
                        str(o_path)],
                       check=True, capture_output=True)
        return bin_path.read_bytes()


@pytest.mark.skipif(not HAS_CA65, reason="ca65 + ld65 not on PATH")
def test_smoke_roundtrip():
    """Hand-written 6-byte program round-trips identically."""
    src = REPO_ROOT / "toolchain" / "smoke_6502.bin"
    if not src.exists():
        pytest.skip("toolchain/smoke_6502.bin missing")
    original = src.read_bytes()
    rebuilt = _roundtrip(src, "$0100")
    assert rebuilt == original


@pytest.mark.skipif(not HAS_CA65, reason="ca65 + ld65 not on PATH")
def test_loader_223_roundtrip():
    """3 KB CP/M 2.23 boot loader (mostly data) round-trips identically.

    First byte is the DOS sector-count byte, so entry is $0801 (not $0800).
    Everything past $083C is data (text strings + zero pad + RWTS chunks).
    """
    src = REPO_ROOT.parent / "cpm-80" / "cpm-investigation" / "loader_223.bin"
    if not src.exists():
        pytest.skip("cpm-80/cpm-investigation/loader_223.bin missing")
    apple_syms = REPO_ROOT / "symbols" / "apple2.json"
    original = src.read_bytes()
    rebuilt = _roundtrip(
        src, "$0800",
        entries=["$0801"],
        data_regions=["$083C-$13FF"],
        symbols=[apple_syms] if apple_syms.exists() else (),
    )
    assert rebuilt == original
