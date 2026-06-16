"""End-to-end reconstruction tests.

For each known SoftCard CP/M disk image, assemble all the docs/CPM*.asm
sources, place them on disk per the chunk map, and verify the result is
byte-identical to the original. This is the master integration test for
Phase 1 of the pipeline (Stage 7 of the roadmap).

Requires ca65 + ld65 + sjasmplus on PATH. Skips silently if any are
missing.
"""

import shutil
import tempfile
from pathlib import Path

import pytest

from cpm_pipeline.reconstruct import reconstruct_disk


REPO_ROOT = Path(__file__).resolve().parents[2]
HAS_ASSEMBLERS = (
    shutil.which("ca65") is not None
    and shutil.which("ld65") is not None
    and shutil.which("sjasmplus") is not None
)


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm223_reconstruct_byte_identical():
    """CPMV223-44K.DSK rebuilt from docs/CPM223_*.asm + remaining staging."""
    reference = REPO_ROOT / "disks" / "CPMV223-44K.DSK"
    if not reference.exists():
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm223.dsk"
        result = reconstruct_disk(
            "223", reference_path=reference, output_path=out, verify=True,
        )
        assert result.diff_count == 0, (
            f"CPMV223-44K.DSK reconstruction differs at {result.diff_count} byte(s); "
            f"first offsets: {[hex(o) for o in result.diff_offsets]}"
        )
        # Confirm at least one byte came from a freshly assembled source
        # (otherwise the pipeline isn't doing what we think it is).
        assert result.bytes_from_assembled > 0


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm220_reconstruct_byte_identical():
    """CPMV220-Disk1.po rebuilt from docs/CPM220_*.asm + remaining staging."""
    reference = REPO_ROOT / "disks" / "CPMV220-Disk1.po"
    if not reference.exists():
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm220.po"
        result = reconstruct_disk(
            "220", reference_path=reference, output_path=out, verify=True,
        )
        assert result.diff_count == 0
        assert result.bytes_from_assembled > 0


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_format_transcode_dsk_to_po():
    """Building a .po output from a .dsk reference (or vice versa) round-trips
    through the physical-sector view. The output bytes differ from the
    reference because of the format change, but the *physical* sector
    contents must match."""
    reference = REPO_ROOT / "disks" / "CPMV223-44K.DSK"
    if not reference.exists():
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        # Write the 2.23 disk in .po order (different on-disk byte order
        # but same physical sector contents).
        out = Path(tmp) / "cpm223.po"
        result = reconstruct_disk(
            "223", reference_path=reference, output_path=out,
            verify=False,  # different format -> verify=False makes no claim
        )
        # The output exists and is the right size; transcoding works.
        assert out.exists()
        assert out.stat().st_size == 143360
        # Re-reconstruct in .dsk order from the .po output; it should match
        # the original .dsk (byte-identical), proving the transcode is lossless.
        out_back = Path(tmp) / "cpm223_back.dsk"
        result2 = reconstruct_disk(
            "223", reference_path=out, output_path=out_back, verify=True,
        )
        # Note: the .po reference here was just transcoded from .dsk; the
        # round-trip back to .dsk via reconstruct_disk should match.
        assert result2.diff_count == 0
