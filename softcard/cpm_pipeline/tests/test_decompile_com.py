"""Emulation-assisted .COM decompiler tests."""

import shutil
import subprocess
from pathlib import Path

import pytest

from cpm_pipeline.decompile_com import decompile_com, trace_com
from cpm_pipeline.filesystem import extract

REPO_ROOT = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO_ROOT / "CPMV223-44K" / "CPMV223-44K.DSK"
HAS_SJASMPLUS = shutil.which("sjasmplus") is not None


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV223-44K.DSK missing")
def test_trace_com_discovers_code_and_bdos():
    com = extract(DSK_223, "STAT.COM")
    tr = trace_com(com, max_instructions=500_000)
    assert tr.executed, "emulation executed no addresses"
    assert tr.instructions > 0
    # STAT prints to the console -> uses BDOS console/print functions.
    assert tr.bdos_calls


@pytest.mark.skipif(not DSK_223.exists(), reason="CPMV223-44K.DSK missing")
def test_decompile_file_produces_asm(tmp_path):
    r = decompile_com(DSK_223, "DUMP.COM", tmp_path)
    assert r.asm_path.exists()
    assert r.size == 512
    assert r.seed_entries >= 1
    text = r.asm_path.read_text(encoding="utf-8")
    assert "ORG" in text.upper() or "$0100" in text


@pytest.mark.skipif(not (DSK_223.exists() and HAS_SJASMPLUS),
                    reason="CPMV223-44K.DSK or sjasmplus missing")
@pytest.mark.parametrize("name", ["DUMP.COM", "STAT.COM", "PIP.COM", "CPM60.COM"])
def test_decompiled_com_roundtrips(tmp_path, name):
    r = decompile_com(DSK_223, name, tmp_path / name.split(".")[0])
    res = subprocess.run(["sjasmplus", str(r.asm_path)],
                         capture_output=True, text=True, cwd=str(r.asm_path.parent))
    assert res.returncode == 0, f"sjasmplus failed:\n{res.stdout}\n{res.stderr}"
    rebuilt = r.asm_path.with_suffix(".bin")
    assert rebuilt.exists(), "no .bin emitted"
    assert rebuilt.read_bytes() == r.com_path.read_bytes(), (
        f"{name} did not round-trip byte-identical"
    )
