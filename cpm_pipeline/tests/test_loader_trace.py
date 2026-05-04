"""Phase 3 (Stage 2) — boot-loader tracing tests.

Verify that pattern-matching the install-copy loops and disk-helper
calls produces sensible structured output for both 2.20 and 2.23.
The expected install-copy destinations are anchored against the
manually-documented architecture in docs/CPM_BootLoader.md.
"""

from pathlib import Path

import pytest

from cpm_pipeline.loader_trace import trace_loader, LoadSchedule


REPO_ROOT = Path(__file__).resolve().parents[2]


def _has(p):
    return (REPO_ROOT / p).exists()


@pytest.mark.skipif(not _has("CPMV233.DSK"), reason="CPMV233.DSK not in repo")
def test_trace_2_23_basics():
    sched = trace_loader(REPO_ROOT / "CPMV233.DSK")
    # Boot-stub destinations come straight from Phase 2 -- 10 sectors.
    assert len(sched.boot_stub_destinations) == 10
    # Install-copy detection finds the four well-known stage-2 copies.
    assert len(sched.install_copies) == 4
    # The big install copy ($1200-$13FF source -> $0200-$03FF runtime
    # range) has length 241 (the LDY #$F1 = 241-byte counter).
    big = next((c for c in sched.install_copies
                if c.length == 241), None)
    assert big is not None, "missing the 241-byte install copy"
    assert big.src_addr == 0x12FF
    assert big.dst_addr == 0x02FF
    # The reset-vector patch loop ($116C source -> $FFF9 dest, 6 bytes).
    rv = next((c for c in sched.install_copies
               if c.dst_addr == 0xFFF9), None)
    assert rv is not None, "missing the reset-vector patch loop"
    assert rv.length == 6


@pytest.mark.skipif(not _has("CPMV233.DSK"), reason="CPMV233.DSK not in repo")
def test_trace_2_23_disk_helper_call():
    """2.23 stage-2 calls JSR $BBEB (the LC-RAM disk helper)."""
    sched = trace_loader(REPO_ROOT / "CPMV233.DSK")
    bbeb = next((c for c in sched.load_cpm_calls
                 if c.target_addr == 0xBBEB), None)
    assert bbeb is not None, (
        "expected JSR $BBEB in 2.23 stage-2; got "
        f"{[hex(c.target_addr) for c in sched.load_cpm_calls]}"
    )
    # The preceding LDA # value is $80 in 2.23
    assert bbeb.param == 0x80


@pytest.mark.skipif(not _has("CPM220Disk1.po"), reason="CPM220Disk1.po not in repo")
def test_trace_2_20_basics():
    sched = trace_loader(REPO_ROOT / "CPM220Disk1.po")
    assert len(sched.boot_stub_destinations) == 10
    # 2.20 has 4 install copies just like 2.23, with similar shape but
    # different exact addresses.
    assert len(sched.install_copies) == 4
    big = next((c for c in sched.install_copies
                if c.length == 241), None)
    assert big is not None
    assert big.dst_addr == 0x02FF


@pytest.mark.skipif(not _has("CPM220Disk1.po"), reason="CPM220Disk1.po not in repo")
def test_trace_2_20_disk_helper_call():
    """2.20 stage-2 calls JSR into the loader-resident $0F__ disk routines."""
    sched = trace_loader(REPO_ROOT / "CPM220Disk1.po")
    # 2.20 uses JSR $0F7D and JSR $0FAD (loader-resident, not LC RAM).
    targets = {c.target_addr for c in sched.load_cpm_calls}
    assert 0x0F7D in targets, f"expected JSR $0F7D; got {[hex(t) for t in targets]}"


def test_summary_is_string():
    if not _has("CPMV233.DSK"):
        pytest.skip("CPMV233.DSK not in repo")
    sched = trace_loader(REPO_ROOT / "CPMV233.DSK")
    s = sched.summary()
    assert isinstance(s, str) and "LoadSchedule" in s
