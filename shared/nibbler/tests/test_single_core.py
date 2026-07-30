"""There must be exactly one 6502 core in the repo.

apple-ii/scripts/emu6502.py used to define its own near-copy of CPU6502,
so the Apple Panic boot scripts ran a different 6502 from the SoftCard
emulator: two implementations, 91% identical, drifting apart in both
directions (the fork had decimal mode the shared core lacked; the shared
core had run(), breakpoints and fetch_hook the fork lacked).

emu6502.py now re-exports nibbler.cpu.CPU6502. This test fails if a
second core is ever reintroduced there.
"""

import importlib.util
import sys
from pathlib import Path

import pytest

from nibbler.cpu import CPU6502

_EMU6502 = Path(__file__).resolve().parents[3] / "apple-ii" / "scripts" / "emu6502.py"


def _load_emu6502():
    if not _EMU6502.is_file():
        pytest.skip(f"{_EMU6502} not present")
    spec = importlib.util.spec_from_file_location("_emu6502_under_test", _EMU6502)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_emu6502_reexports_the_shared_core():
    assert _load_emu6502().CPU6502 is CPU6502, (
        "apple-ii/scripts/emu6502.py must re-export nibbler.cpu.CPU6502, "
        "not define a second 6502"
    )


def test_emu6502_defines_no_class_named_cpu6502():
    """Belt and braces: catch a fork that shadows the import."""
    source = _EMU6502.read_text(encoding="utf-8")
    assert "class CPU6502" not in source, \
        "emu6502.py defines its own CPU6502 again"


def test_emu6502_still_exports_its_apple_ii_extras():
    """The split kept the Apple Panic material here; the boot scripts import it."""
    module = _load_emu6502()
    for name in ("WOZDisk", "decode_boot_sector_from_woz", "decode_track_53",
                 "decode_53_sector", "decode_44", "build_gcr_table"):
        assert hasattr(module, name), f"emu6502.{name} went missing"


def test_the_boot_scripts_only_use_api_the_shared_core_provides():
    """Guards the interface the Apple Panic scripts actually depend on."""
    cpu = CPU6502()
    for name in ("a", "x", "y", "sp", "pc", "mem", "disk", "halted",
                 "exec_count", "step", "format_state", "cycles"):
        assert hasattr(cpu, name), f"CPU6502.{name} is required by the boot scripts"
