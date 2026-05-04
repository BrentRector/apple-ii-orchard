"""Tests for Stage 1 disk-format detection."""

from pathlib import Path

import pytest

from cpm_pipeline.format_detect import (
    detect, DiskFormat,
    SOFTCARD_BOOT_FINGERPRINT, SOFTCARD_223_PASCAL11_SIGNATURE,
)


REPO_ROOT = Path(__file__).resolve().parents[2]


def _has(path):
    return (REPO_ROOT / path).exists()


# ── Sanity checks on the signature constants ─────────────────────────
def test_boot_fingerprint_is_16_bytes():
    """The fingerprint covers $0800-$080F of the boot sector."""
    assert len(SOFTCARD_BOOT_FINGERPRINT) == 16
    assert SOFTCARD_BOOT_FINGERPRINT[0] == 0x01  # count byte
    assert SOFTCARD_BOOT_FINGERPRINT[1] == 0xA5  # LDA opcode
    assert SOFTCARD_BOOT_FINGERPRINT[2] == 0x27  # zp address (page count)


def test_pascal11_signature_is_12_bytes():
    """The 2.23-only Pascal-1.1 detection branch is 12 bytes."""
    assert len(SOFTCARD_223_PASCAL11_SIGNATURE) == 12
    # Spot-check the first instruction (CPX #$04)
    assert SOFTCARD_223_PASCAL11_SIGNATURE[0:2] == b"\xE0\x04"


# ── Real-disk detection tests ────────────────────────────────────────
@pytest.mark.skipif(not _has("CPMV233.DSK"), reason="CPMV233.DSK not in repo")
def test_detect_2_23():
    info = detect(REPO_ROOT / "CPMV233.DSK")
    assert info.format == "dsk"
    assert info.size_bytes == 143360
    assert info.has_boot_stub
    assert info.boot_stub_fingerprint_match
    assert info.boot_stub_count_byte == 0x01
    assert info.boot_stub_load_count == 10
    assert info.sector_skew_table == [
        0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE,
        0x1, 0x3, 0x5, 0x7, 0x9, 0xB, 0xD, 0xF,
    ]
    assert info.variant == "softcard_cpm_2_23"
    assert info.variant_confidence == "high"


@pytest.mark.skipif(not _has("CPM220Disk1.po"), reason="CPM220Disk1.po not in repo")
def test_detect_2_20_disk1():
    info = detect(REPO_ROOT / "CPM220Disk1.po")
    assert info.format == "po"
    assert info.size_bytes == 143360
    assert info.has_boot_stub
    assert info.boot_stub_fingerprint_match
    assert info.boot_stub_load_count == 10
    assert info.variant == "softcard_cpm_2_20"


@pytest.mark.skipif(not _has("CPM220Disk2.po"), reason="CPM220Disk2.po not in repo")
def test_detect_2_20_disk2():
    """Disk 2 of the 2.20 set -- should also detect as 2.20 (same boot stub)."""
    info = detect(REPO_ROOT / "CPM220Disk2.po")
    assert info.has_boot_stub
    assert info.variant == "softcard_cpm_2_20"


@pytest.mark.skipif(not _has("CPMV233.DSK"), reason="CPMV233.DSK not in repo")
def test_destinations_match_chunk_map_2_23():
    """The detected boot-stub destinations should match the manually-
    maintained chunk_map.py for the 2.23 variant."""
    from cpm_pipeline.chunk_map import CHUNKS_223
    info = detect(REPO_ROOT / "CPMV233.DSK")
    # Build the (apple_addr, phys_sector) set the chunk map declares
    # for BootLoader bytes (sectors loaded by the boot stub).
    chunk_map_destinations = set()
    for chunk in CHUNKS_223:
        if chunk.source_name == "CPM223_BootLoader":
            apple_addr = 0x0800 + chunk.src_offset
            chunk_map_destinations.add((apple_addr, chunk.phys_sector))
    detected_destinations = set(info.boot_stub_destinations)
    # The detected set is the 10 stub-loaded sectors (excluding the boot
    # sector); the chunk map includes the boot sector too. So detected
    # should be a subset of chunk_map.
    assert detected_destinations.issubset(chunk_map_destinations), (
        f"detected: {sorted(detected_destinations)} not subset of "
        f"chunk_map: {sorted(chunk_map_destinations)}"
    )


def test_summary_is_string():
    """Smoke: `info.summary()` returns a non-empty string."""
    if not _has("CPMV233.DSK"):
        pytest.skip("CPMV233.DSK not in repo")
    info = detect(REPO_ROOT / "CPMV233.DSK")
    s = info.summary()
    assert isinstance(s, str) and len(s) > 0
