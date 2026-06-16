"""End-to-end CLI tests for the decompilation toolchain."""

from pathlib import Path

import pytest

from cpm_pipeline.cli import main

REPO_ROOT = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO_ROOT / "CPMV223-44K" / "CPMV223-44K.DSK"


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV223-44K.DSK missing")
def test_list_files_cli(capsys):
    rc = main(["list-files", str(DSK_223)])
    assert rc == 0
    out = capsys.readouterr().out
    assert "CPM60.COM" in out
    assert "22 file(s)" in out


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV223-44K.DSK missing")
def test_decompile_file_cli(tmp_path, capsys):
    rc = main(["decompile-file", str(DSK_223), "DUMP.COM", "--out", str(tmp_path / "d")])
    assert rc == 0
    assert (tmp_path / "d" / "DUMP.asm").exists()


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV223-44K.DSK missing")
def test_decompile_disk_end_to_end(tmp_path, capsys):
    # Non-interactive selection drives the full verify -> OS -> list -> file flow.
    rc = main(["decompile-disk", str(DSK_223), str(tmp_path / "out"),
               "--select", "DUMP.COM"])
    assert rc == 0
    out_dir = tmp_path / "out"
    # OS auto-disassembly (both CPUs) + gold tree
    assert (out_dir / "os" / "auto" / "CPM_BIOS.asm").exists()          # Z-80
    assert (out_dir / "os" / "auto" / "CPM_BootLoader.s").exists()      # 6502
    assert (out_dir / "os" / "gold" / "source" / "CPM_BIOS.asm").exists()
    # selected program decompiled to Z-80 source
    assert (out_dir / "files" / "DUMP" / "DUMP.asm").exists()
    text = capsys.readouterr().out
    assert "softcard_cpm_2_23" in text
    assert "DUMP.COM" in text
