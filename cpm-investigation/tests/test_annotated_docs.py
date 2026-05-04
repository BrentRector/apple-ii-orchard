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


def _z80_chunk_roundtrip(asm_name, bin_name, expected_savebin, length=None):
    """Generic Z-80 chunk round-trip checker. `expected_savebin` is the
    'build/...' path embedded in the .asm's SAVEBIN directive that we
    rewrite to a per-test temp path. `length` truncates the original
    binary if it's longer than the live image (e.g., BIOS is 2048 bytes
    on disk but only 1352 bytes are loaded)."""
    src = REPO_ROOT / "docs" / asm_name
    bin_orig = REPO_ROOT / "cpm-investigation" / bin_name
    if not src.exists() or not bin_orig.exists():
        pytest.skip("source or original missing")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        rewritten = tmp / asm_name
        out_bin = tmp / "out.bin"
        rewritten.write_text(
            src.read_text(encoding="utf-8").replace(
                expected_savebin, out_bin.as_posix()
            ),
            encoding="utf-8",
        )
        rc, log = _assemble_z80(rewritten, out_bin)
        assert rc == 0, f"sjasmplus failed:\n{log}"
        rebuilt = out_bin.read_bytes()
        original = bin_orig.read_bytes()
        if length is not None:
            original = original[:length]
        assert rebuilt == original, (
            f"docs/{asm_name} no longer round-trips byte-identically. "
            f"first diff at offset "
            f"{next((i for i in range(min(len(rebuilt), len(original))) if rebuilt[i] != original[i]), min(len(rebuilt), len(original)))}"
        )


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_cpm223_bios_annotated_roundtrip():
    """docs/CPM223_BIOS.asm must reassemble to bios_223.bin[:1352]."""
    _z80_chunk_roundtrip(
        "CPM223_BIOS.asm", "bios_223.bin",
        expected_savebin="build/CPM223_BIOS.bin",
        length=0x548,
    )


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_cpm223_diskcallbacks_annotated_roundtrip():
    """docs/CPM223_DiskCallbacks.asm must reassemble to diskcallbacks_223.bin."""
    _z80_chunk_roundtrip(
        "CPM223_DiskCallbacks.asm", "diskcallbacks_223.bin",
        expected_savebin="build/CPM223_DiskCallbacks.bin",
    )


@pytest.mark.skipif(not HAS_SJASMPLUS, reason="sjasmplus not on PATH")
def test_cpm223_systemimage_annotated_roundtrip():
    """docs/CPM223_SystemImage.asm must reassemble to sysimg_223.bin."""
    _z80_chunk_roundtrip(
        "CPM223_SystemImage.asm", "sysimg_223.bin",
        expected_savebin="build/CPM223_SystemImage.bin",
    )
