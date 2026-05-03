"""Regression tests: hand-annotated .asm files in docs/ must reassemble
byte-identically to the binaries they describe.

Catches accidental edits to docs/ that would silently break the round-trip
property -- since the annotated files are MEANT to be human-edited, this
test makes sure those edits don't cross into the bytes themselves.
"""

import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
HAS_SJASMPLUS = shutil.which("sjasmplus") is not None


def _assemble_z80(asm_src, out_bin):
    """sjasmplus assemble. Returns (returncode, stdout+stderr)."""
    r = subprocess.run(
        ["sjasmplus", str(asm_src)],
        capture_output=True, text=True,
    )
    return r.returncode, (r.stdout + r.stderr)


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_cpm223_bios_annotated_roundtrip():
    """docs/CPM223_BIOS.asm must reassemble to bios_223.bin[:1352]."""
    src = REPO_ROOT / "docs" / "CPM223_BIOS.asm"
    bin_orig = REPO_ROOT / "cpm-investigation" / "bios_223.bin"
    if not src.exists() or not bin_orig.exists():
        pytest.skip("source or original missing")

    # Copy the .asm to a temp dir, rewriting SAVEBIN to a temp output path
    # (sjasmplus runs in CWD-relative; we don't want to write into build/
    # from a test).
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        rewritten = tmp / "CPM223_BIOS.asm"
        out_bin = tmp / "out.bin"
        rewritten.write_text(
            src.read_text(encoding="utf-8").replace(
                'build/CPM223_BIOS.bin', out_bin.as_posix()
            ),
            encoding="utf-8",
        )
        rc, log = _assemble_z80(rewritten, out_bin)
        assert rc == 0, f"sjasmplus failed:\n{log}"
        assert out_bin.exists()
        rebuilt = out_bin.read_bytes()
        original = bin_orig.read_bytes()[:0x548]   # first 1352 bytes
        assert rebuilt == original, (
            f"docs/CPM223_BIOS.asm no longer round-trips byte-identically. "
            f"first diff at offset {next((i for i in range(len(rebuilt)) if rebuilt[i] != original[i]), len(rebuilt))}"
        )
