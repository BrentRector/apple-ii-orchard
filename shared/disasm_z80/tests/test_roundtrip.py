"""Round-trip tests: disasm output must reassemble byte-identical to input.

Requires sjasmplus on PATH. Skips silently if not present.
"""

import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

from disasm_z80.cli import main as disasm_main


REPO_ROOT = Path(__file__).resolve().parents[2]
HAS_SJASMPLUS = shutil.which("sjasmplus") is not None


def _roundtrip(input_path, org, *, length=None, entries=(), data_regions=(), symbols=()):
    """Run disasm -> sjasmplus and return the assembled bytes."""
    input_path = Path(input_path)
    with tempfile.TemporaryDirectory() as tmp:
        out_base = Path(tmp) / "rt"
        argv = [str(input_path), "--org", org, "--output", str(out_base)]
        if length is not None:
            argv += ["--length", length]
        for s in symbols:
            argv += ["--symbols", str(s)]
        for e in entries:
            argv += ["--entry", e]
        for d in data_regions:
            argv += ["--data-region", d]
        rc = disasm_main(argv)
        assert rc == 0, "disasm CLI failed"
        asm_path = out_base.with_suffix(".asm")
        bin_path = out_base.with_suffix(".bin")
        result = subprocess.run(
            ["sjasmplus", str(asm_path)],
            capture_output=True, text=True,
        )
        assert result.returncode == 0, (
            f"sjasmplus failed:\n{result.stdout}\n{result.stderr}"
        )
        return bin_path.read_bytes()


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_smoke_roundtrip():
    """Hand-written 6-byte program round-trips identically."""
    src = REPO_ROOT / "toolchain" / "smoke_z80.bin"
    if not src.exists():
        pytest.skip("toolchain/smoke_z80.bin missing")
    original = src.read_bytes()
    rebuilt = _roundtrip(src, "$0100")
    assert rebuilt == original


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_cpm_223_bios_roundtrip():
    """1352-byte CP/M 2.23 Z-80 BIOS round-trips byte-identical.

    Exercises base + ED block-op + CB bit-op opcodes plus a real Z-80 code-
    overlap idiom (CALL into the middle of a JR instruction at $FB45)."""
    src = REPO_ROOT.parent / "cpm-80" / "cpm-investigation" / "bios_223.bin"
    cpm_syms = REPO_ROOT / "symbols" / "cpm_2_2.json"
    if not src.exists():
        pytest.skip("cpm-80/cpm-investigation/bios_223.bin missing")
    # The on-disk file is 2048 bytes (sector-aligned extraction with trailing
    # padding); the live BIOS is the first 1352 bytes. Truncate.
    original = src.read_bytes()[:0x548]
    # Trace from all 17 BIOS jump-table entries for high code coverage.
    entries = [f"${0xFAB8 + i*3:04X}" for i in range(17)]
    rebuilt = _roundtrip(
        src, "$FAB8", length="$0548",
        entries=entries,
        symbols=[cpm_syms] if cpm_syms.exists() else (),
    )
    assert rebuilt == original
