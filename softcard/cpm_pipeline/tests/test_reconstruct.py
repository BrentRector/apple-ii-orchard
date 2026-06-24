"""End-to-end reconstruction tests.

For each known SoftCard CP/M disk image, assemble the OS sources (the 2.23
disk now from CPMV223-44K/os/; 2.20 still from docs/CPM220_*.asm), place them
on disk per the chunk map, and verify byte-identical. The whole-disk variant
also rebuilds every .COM from committed source. This is the master integration
test for the reconstruction pipeline.

Requires ca65 + ld65 + sjasmplus on PATH. Skips silently if any are
missing.
"""

import shutil
import tempfile
from pathlib import Path

import pytest

from cpm_pipeline.reconstruct import reconstruct_disk, reconstruct_full_disk
from cpm_pipeline.reference_data import (
    DISK_2_20_44K_SYSTEM,
    DISK_2_20B_56K_SYSTEM,
    DISK_2_23_44K_SYSTEM,
    present,
)


HAS_ASSEMBLERS = (
    shutil.which("ca65") is not None
    and shutil.which("ld65") is not None
    and shutil.which("sjasmplus") is not None
)


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm223_reconstruct_byte_identical():
    """2.23 44K system disk rebuilt from CPMV223-44K/os/ + remaining staging."""
    reference = DISK_2_23_44K_SYSTEM
    if not present(reference):
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm223.dsk"
        result = reconstruct_disk(
            "223", reference_path=reference, output_path=out, verify=True,
        )
        assert result.diff_count == 0, (
            f"2.23 44K reconstruction differs at {result.diff_count} byte(s); "
            f"first offsets: {[hex(o) for o in result.diff_offsets]}"
        )
        # Confirm at least one byte came from a freshly assembled source
        # (otherwise the pipeline isn't doing what we think it is).
        assert result.bytes_from_assembled > 0


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm223_full_disk_reconstruct_byte_identical():
    """Whole 2.23 44K system disk rebuilt from committed source: the OS region
    from CPMV223-44K/os/, every .COM from utilities/bin/ (+ CPM60.COM from the
    60K CPM60.asm master), and only the filesystem data carried. Byte-identical,
    and a real majority of bytes provably come from re-assembled source."""
    reference = DISK_2_23_44K_SYSTEM
    if not present(reference):
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm223_full.dsk"
        res = reconstruct_full_disk(reference, out, verify=True)
        assert res.byte_identical, (
            f"whole-disk rebuild differs; first offsets: "
            f"{[hex(o) for o in res.diff_offsets]}")
        # The OS region + every .COM come from source -> well over half the disk.
        assert res.from_source_bytes > res.total_bytes // 2


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm220_reconstruct_byte_identical():
    """2.20B 56K system disk 1 rebuilt from docs/CPM220_*.asm + remaining staging."""
    reference = DISK_2_20B_56K_SYSTEM
    if not present(reference):
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm220.po"
        result = reconstruct_disk(
            "220", reference_path=reference, output_path=out, verify=True,
        )
        assert result.diff_count == 0
        assert result.bytes_from_assembled > 0


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm220_44k_reconstruct_byte_identical():
    """2.20-44K (original 1980) system disk rebuilt from the clean-room
    CPMV220-44K/os/ tree + remaining staging. The OS sources are the
    independently decompiled, adversarially-verified 44K assembly (BIOS $AA00,
    SystemImage $9300, 6502 BootLoader)."""
    reference = DISK_2_20_44K_SYSTEM
    if not present(reference):
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm220_44k.dsk"
        result = reconstruct_disk(
            "220-44k", reference_path=reference, output_path=out, verify=True,
        )
        assert result.diff_count == 0, (
            f"2.20-44K reconstruction differs at {result.diff_count} byte(s); "
            f"first offsets: {[hex(o) for o in result.diff_offsets]}"
        )
        assert result.bytes_from_assembled > 0


def test_cpm220_44k_deskew_roundtrip_and_coherent():
    """The 44K system image runs sector-DE-INTERLEAVED (see CPM_Skew_Findings.md).
    Pin the de-skew map: gather the de-skewed runtime image from the reference .dsk,
    scatter it back == byte-identical, and the de-skewed image decodes coherently at
    its runtime addresses (CCP entry $9400, BDOS dispatch $9C47 with its fn handlers
    in-image -- impossible on the sector-scrambled order)."""
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM, present
    from cpm_pipeline.deskew import (
        build_runtime_image, scatter_to_disk, reference_runtime_image,
        RUNTIME_ORG, RUNTIME_LEN, PAGE_TO_SECTOR, PAGE,
    )
    if not present(DISK_2_20_44K_SYSTEM):
        pytest.skip("reference disk missing")
    dsk = bytearray(DISK_2_20_44K_SYSTEM.read_bytes())
    runtime = build_runtime_image(dsk)
    assert len(runtime) == RUNTIME_LEN
    back = scatter_to_disk(runtime, bytearray(dsk))
    for s in PAGE_TO_SECTOR.values():
        assert back[s*PAGE:s*PAGE+PAGE] == dsk[s*PAGE:s*PAGE+PAGE], "scatter not byte-identical"

    def at(a): return runtime[a - RUNTIME_ORG]
    def word(a): return at(a) | (at(a + 1) << 8)
    lo, hi = RUNTIME_ORG, RUNTIME_ORG + len(runtime)
    disp = 0x9C47
    in_image = sum(1 for fn in range(41) if lo <= word(disp + fn * 2) < hi)
    assert in_image >= 35, f"only {in_image}/41 dispatch handlers land in the de-skewed image"
    assert at(word(disp + 7 * 2)) == 0x3A and word(word(disp + 7 * 2) + 1) == 0x0003  # fn7 LD A,($0003)
    assert at(0x9400) == 0xC3  # CCP entry JP


def test_cpm223_44k_deskew_roundtrip_and_coherent():
    """The 2.23-44K system also runs sector-de-interleaved. Pin the emulator-derived
    de-skew maps: gather the runtime image (CCP+BDOS at $9300, BIOS at $FA00) from the
    reference .dsk, scatter it back byte-identical, and confirm it decodes coherently at
    its runtime addresses (CCP entry $9300 = JP; BDOS dispatch handlers in-image)."""
    from cpm_pipeline.reference_data import DISK_2_23_44K_SYSTEM, present
    from cpm_pipeline.deskew import (
        build_runtime_image_223, build_bios_image_223, _scatter,
        PAGE_TO_SECTOR_223, BIOS_PAGE_TO_SECTOR_223, RUNTIME_ORG_223, RUNTIME_LEN_223, PAGE,
    )
    if not present(DISK_2_23_44K_SYSTEM):
        pytest.skip("reference disk missing")
    dsk = bytearray(DISK_2_23_44K_SYSTEM.read_bytes())
    rt = build_runtime_image_223(dsk)
    assert len(rt) == RUNTIME_LEN_223
    back = _scatter(rt, PAGE_TO_SECTOR_223, RUNTIME_ORG_223, bytearray(dsk))
    for s in list(PAGE_TO_SECTOR_223.values()) + list(BIOS_PAGE_TO_SECTOR_223.values()):
        assert back[s*PAGE:s*PAGE+PAGE] == dsk[s*PAGE:s*PAGE+PAGE]
    allsec = list(PAGE_TO_SECTOR_223.values()) + list(BIOS_PAGE_TO_SECTOR_223.values())
    assert len(set(allsec)) == len(allsec) == 29, "2.23 de-skew sectors not distinct"

    def at(a): return rt[a - RUNTIME_ORG_223]
    def word(a): return at(a) | (at(a + 1) << 8)
    lo, hi = RUNTIME_ORG_223, RUNTIME_ORG_223 + len(rt)
    assert at(0x9300) == 0xC3                                   # CCP cold entry JP
    disp = 0x9C47
    in_image = sum(1 for fn in range(41) if lo <= word(disp + fn * 2) < hi)
    assert in_image >= 35, f"only {in_image}/41 BDOS dispatch handlers land in the de-skewed image"


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_os_listings_are_fresh():
    """The four per-component .lst listings (BootLoader/CCP/BDOS/BIOS) for each 44K tree are
    TRACKED side-by-side with their .asm and linked from the wiseowl articles, so they must
    not drift from the source. Regenerate each and compare to the committed file."""
    import tempfile
    from pathlib import Path
    from cpm_pipeline.chunk_map import SOURCES_220_44K, SOURCES_223
    from cpm_pipeline.os_listing import emit_listing
    chunks = [SOURCES_220_44K[k] for k in
              ("CPM220_44K_BootLoader", "CPM220_44K_CCP", "CPM220_44K_BDOS", "CPM220_44K_BIOS_Disk")]
    chunks += [SOURCES_223[k] for k in
               ("CPM223_BootLoader", "CPM223_44K_CCP", "CPM223_44K_BDOS", "CPM223_BIOS_Disk")]
    stale = []
    for cs in chunks:
        committed = cs.asm_path.with_suffix(".lst")
        if not committed.exists():
            stale.append(f"{committed} missing")
            continue
        tmp = Path(tempfile.mktemp(suffix=".lst"))
        emit_listing(cs, tmp)
        if tmp.read_text(encoding="latin-1") != committed.read_text(encoding="latin-1"):
            stale.append(f"{committed.relative_to(committed.parents[3])} differs from source "
                         f"(regenerate: cpm_pipeline.os_listing.emit_listing)")
    assert not stale, "stale committed .lst:\n  " + "\n  ".join(stale)


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm220_44k_ccp_bdos_concatenate_to_deskewed_image():
    """The de-skew RE-BASE: the two independent runtime-addressed compilations -- CPM_CCP.asm
    (ORG $9400, $0800) and CPM_BDOS.asm (ORG $9C00, $0E00) -- assembled and concatenated
    equal the de-skewed runtime image gathered from the reference disk. Enrichment must keep
    this green (the disk reconstruct then scatters these pages back to byte-identical)."""
    from cpm_pipeline.chunk_map import SOURCES_220_44K
    from cpm_pipeline.assemble import assemble_chunk
    from cpm_pipeline.deskew import reference_runtime_image, RUNTIME_ORG
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM, present
    if not present(DISK_2_20_44K_SYSTEM):
        pytest.skip("reference disk not present")
    ccp = assemble_chunk(SOURCES_220_44K["CPM220_44K_CCP"])
    bdos = assemble_chunk(SOURCES_220_44K["CPM220_44K_BDOS"])
    cat = ccp + bdos
    ref = reference_runtime_image()
    diffs = [i for i in range(min(len(cat), len(ref))) if cat[i] != ref[i]]
    assert len(cat) == len(ref) and not diffs, (
        f"CCP+BDOS ({len(cat)}) != de-skewed image ({len(ref)}); "
        f"{len(diffs)} diffs, first {[hex(RUNTIME_ORG+o) for o in diffs[:8]]}")


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_cpm220_44k_full_disk_reconstruct_byte_identical():
    """Whole 2.20-44K system disk rebuilt from source: the OS region from the
    clean-room CPMV220-44K/os/ tree, every .COM from its decompilation, only
    filesystem data carried. Byte-identical, majority of bytes from source."""
    reference = DISK_2_20_44K_SYSTEM
    if not present(reference):
        pytest.skip(f"reference disk missing: {reference}")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "cpm220_44k_full.dsk"
        res = reconstruct_full_disk(reference, out, verify=True)
        assert res.byte_identical, (
            f"whole-disk rebuild differs; first offsets: "
            f"{[hex(o) for o in res.diff_offsets]}")
        assert res.from_source_bytes > res.total_bytes // 2


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_format_transcode_dsk_to_po():
    """Building a .po output from a .dsk reference (or vice versa) round-trips
    through the physical-sector view. The output bytes differ from the
    reference because of the format change, but the *physical* sector
    contents must match."""
    reference = DISK_2_23_44K_SYSTEM
    if not present(reference):
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
