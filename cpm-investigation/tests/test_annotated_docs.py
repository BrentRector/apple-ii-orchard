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


HAS_CA65 = shutil.which("ca65") is not None and shutil.which("ld65") is not None


def _assemble_z80(asm_src, out_bin):
    """sjasmplus assemble. Returns (returncode, stdout+stderr)."""
    r = subprocess.run(
        ["sjasmplus", str(asm_src)],
        capture_output=True, text=True,
    )
    return r.returncode, (r.stdout + r.stderr)


def _assemble_6502(asm_src, cfg_src, out_bin, *, cwd=None):
    """ca65 + ld65 assemble. cwd controls .incbin's relative-path resolution.
    Returns (returncode, stdout+stderr)."""
    obj = asm_src.with_suffix(".o")
    r1 = subprocess.run(
        ["ca65", str(asm_src), "-o", str(obj)],
        capture_output=True, text=True, cwd=cwd,
    )
    if r1.returncode != 0:
        return r1.returncode, (r1.stdout + r1.stderr)
    r2 = subprocess.run(
        ["ld65", "-C", str(cfg_src), "-o", str(out_bin), str(obj)],
        capture_output=True, text=True,
    )
    return r2.returncode, (r2.stdout + r2.stderr)


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


def _ca65_chunk_roundtrip(asm_name, bin_name, *, org, size):
    """Generic ca65 + ld65 round-trip for hand-annotated 6502 docs that use
    .incbin from the original binary (paths resolved relative to REPO_ROOT)."""
    asm_src = REPO_ROOT / "docs" / asm_name
    bin_orig = REPO_ROOT / "cpm-investigation" / bin_name
    if not asm_src.exists() or not bin_orig.exists():
        pytest.skip("source or original missing")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        copied_asm = tmp / asm_name.replace(".asm", ".s")
        copied_asm.write_text(asm_src.read_text(encoding="utf-8"), encoding="utf-8")
        cfg = tmp / asm_name.replace(".asm", ".cfg")
        cfg.write_text(
            f"MEMORY {{\n"
            f"    RAM: start = ${org:04X}, size = ${size:04X}, file = %O;\n"
            f"}}\n"
            f"SEGMENTS {{\n"
            f"    CODE: load = RAM, type = ro;\n"
            f"}}\n",
            encoding="utf-8",
        )
        out_bin = tmp / "out.bin"
        rc, log = _assemble_6502(copied_asm, cfg, out_bin, cwd=str(REPO_ROOT))
        assert rc == 0, f"ca65/ld65 failed:\n{log}"
        rebuilt = out_bin.read_bytes()
        original = bin_orig.read_bytes()
        assert rebuilt == original, (
            f"docs/{asm_name} no longer round-trips byte-identically. "
            f"first diff at offset "
            f"{next((i for i in range(min(len(rebuilt), len(original))) if rebuilt[i] != original[i]), min(len(rebuilt), len(original)))}"
        )


@pytest.mark.skipif(not HAS_CA65, reason="ca65 + ld65 not on PATH")
def test_cpm223_rwts_annotated_roundtrip():
    """docs/CPM223_RWTS.asm must reassemble to rwts_223.bin via ca65 + ld65.
    Uses .incbin to pull the 459-byte gap (Z-80 BIOS code + GCR tables) and
    .res to fill the trailing 21 zero-bytes."""
    _ca65_chunk_roundtrip("CPM223_RWTS.asm", "rwts_223.bin",
                          org=0x0A00, size=0x0600)


@pytest.mark.skipif(not HAS_CA65, reason="ca65 + ld65 not on PATH")
def test_cpm223_installfragments_annotated_roundtrip():
    """docs/CPM223_InstallFragments.asm must reassemble to installfragments_223.bin."""
    _ca65_chunk_roundtrip("CPM223_InstallFragments.asm",
                          "installfragments_223.bin",
                          org=0x0200, size=0x0200)


@pytest.mark.skipif(not HAS_CA65, reason="ca65 + ld65 not on PATH")
def test_cpm223_bootloader_annotated_roundtrip():
    """docs/CPM223_BootLoader.asm must reassemble to loader_223.bin via ca65 + ld65.
    Uses .incbin to pull regions that live in companion files (RWTS, install
    fragments) plus several inline corrections to off-by-one prose annotations."""
    _ca65_chunk_roundtrip("CPM223_BootLoader.asm", "loader_223.bin",
                          org=0x0800, size=0x0C00)
