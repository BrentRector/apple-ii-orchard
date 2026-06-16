"""Phase 7 (Stage 6) — annotated source-tree generation tests."""

import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

from cpm_pipeline.generate import generate, GenerateResult


REPO_ROOT = Path(__file__).resolve().parents[2]
HAS_ASSEMBLERS = (
    shutil.which("ca65") is not None
    and shutil.which("ld65") is not None
    and shutil.which("sjasmplus") is not None
)


def _has(p):
    return (REPO_ROOT / p).exists()


@pytest.mark.skipif(not _has("disks/CPMV233.DSK"), reason="CPMV233.DSK missing")
def test_generate_2_23_tree_structure():
    """Generated tree has analysis + source + symbols + build.sh + README."""
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "tree"
        result = generate(REPO_ROOT / "disks" / "CPMV233.DSK", out)
        # Directory layout
        assert (out / "README.md").exists()
        assert (out / "build.sh").exists()
        assert (out / "analysis").is_dir()
        assert (out / "source").is_dir()
        assert (out / "symbols").is_dir()
        # 4 analysis reports (format / loader / cold-boot / handoff)
        assert len(result.analysis_files) == 4
        assert (out / "analysis" / "01_format.txt").exists()
        assert (out / "analysis" / "02_loader.txt").exists()
        assert (out / "analysis" / "03_cold_boot.txt").exists()
        assert (out / "analysis" / "04_handoff.txt").exists()
        # 6 sources for 2.23
        assert len(result.sources_copied) == 6
        # 3 symbol tables for 2.23
        assert len(result.symbols_copied) == 3
        # Variant detected
        assert result.variant == "softcard_cpm_2_23"


@pytest.mark.skipif(not _has("disks/CPM220Disk1.po"), reason="CPM220Disk1.po missing")
def test_generate_2_20_tree_structure():
    """2.20 has 5 sources, 2 symbols (no cpm_2_23_bios.json)."""
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "tree"
        result = generate(REPO_ROOT / "disks" / "CPM220Disk1.po", out)
        assert result.variant == "softcard_cpm_2_20"
        assert len(result.sources_copied) == 5
        assert len(result.symbols_copied) == 2


@pytest.mark.skipif(not _has("disks/CPMV233.DSK") or not HAS_ASSEMBLERS,
                    reason="CPMV233.DSK or assemblers missing")
def test_generate_2_23_build_script_round_trips():
    """The auto-generated build.sh's equivalent reconstruction must
    round-trip byte-identical. (We test the equivalent Python invocation
    rather than shelling out to bash, which has cross-platform quirks.)"""
    from cpm_pipeline.reconstruct import reconstruct_disk

    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "tree"
        result = generate(REPO_ROOT / "disks" / "CPMV233.DSK", out)
        # Verify the build script content describes the right command
        script = result.build_script.read_text(encoding="utf-8")
        assert "python -m cpm_pipeline build 223" in script
        assert "--verify" in script
        assert "CPMV233.DSK" in script

        # Run the equivalent reconstruction directly
        rebuilt = out / "rebuilt" / "rebuilt.dsk"
        rebuilt.parent.mkdir(parents=True, exist_ok=True)
        r = reconstruct_disk(
            "223",
            reference_path=REPO_ROOT / "disks" / "CPMV233.DSK",
            output_path=rebuilt,
            verify=True,
        )
        assert r.diff_count == 0, (
            f"rebuilt disk differs at {r.diff_count} bytes"
        )


def test_overwrite_protection():
    """Without overwrite=True, generating into an existing dir errors."""
    if not _has("disks/CPMV233.DSK"):
        pytest.skip("CPMV233.DSK missing")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "tree"
        out.mkdir()
        (out / "stub").write_text("don't delete me")
        with pytest.raises(FileExistsError):
            generate(REPO_ROOT / "disks" / "CPMV233.DSK", out, overwrite=False)
        # Now with overwrite=True it works (and the stub gets deleted)
        result = generate(REPO_ROOT / "disks" / "CPMV233.DSK", out, overwrite=True)
        assert not (out / "stub").exists()
        assert result.variant == "softcard_cpm_2_23"
