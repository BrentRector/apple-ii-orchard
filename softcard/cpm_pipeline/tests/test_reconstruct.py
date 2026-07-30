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


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_reconstruct_emits_either_dsk_or_po_for_any_build():
    """Any build can be written as EITHER a .dsk (DOS 3.3 order) or a .po (ProDOS order)
    on request -- the format is taken from the output extension. Chunks are placed at
    physical (track, sector), so the assembled OS region is byte-identical in either
    format; the reference supplies the filesystem sectors (transcoded to the output
    format). Verify: the output, transcoded back to the reference's own format, equals
    the real reference disk byte-for-byte -- including the CROSS format (56K native .po
    written as .dsk, 44K native .dsk written as .po)."""
    from cpm_pipeline.reconstruct import _transcode, detect_format
    for variant, reference in (("220", DISK_2_20B_56K_SYSTEM),
                               ("220-44k", DISK_2_20_44K_SYSTEM)):
        if not present(reference):
            pytest.skip(f"reference disk missing: {reference}")
        ref_fmt = detect_format(Path(reference))
        ref_bytes = Path(reference).read_bytes()
        for ext in (".dsk", ".po"):
            with tempfile.TemporaryDirectory() as tmp:
                out = Path(tmp) / f"cpm{ext}"
                result = reconstruct_disk(variant, reference_path=reference,
                                          output_path=out, verify=True)
                assert result.diff_count == 0, f"{variant} -> {ext}: diff {result.diff_count}"
                back = bytes(_transcode(out.read_bytes(),
                                        src_format=ext[1:], dst_format=ref_fmt))
                assert back == ref_bytes, \
                    f"{variant} written as {ext} does not round-trip to the real disk"


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


def test_cpm220b_56k_bios_deskew_roundtrip_and_is_44k_plus_3000():
    """The 2.20B-56K BIOS lives at z80 $DA00-$DFFF (Apple language card), stored in the
    .po as 6 contiguous sectors 33-38. Pin the map: gather it, scatter it back
    byte-identical, and confirm it is the 2.20-44K BIOS ($AA00) relocated +$3000 -- every
    byte is either identical, a +$30 relocation high-byte, or one of the small set of
    genuine 2.20->2.20B deltas (3 console re-wires + the page-$DF warm-boot/sign-on block;
    see CPM_56K_60K_Fold_Plan.md). Boot entry at $DA00 is a JP (the static on-disk byte,
    not the post-boot self-modified $C9)."""
    from cpm_pipeline.reference_data import (
        DISK_2_20_44K_SYSTEM, DISK_2_20B_56K_SYSTEM, present)
    from cpm_pipeline.deskew import (
        build_bios_image_220b_56k, reference_bios_image, _scatter,
        BIOS_PAGE_TO_SECTOR_220B_56K, BIOS_ORG_220B_56K, BIOS_LEN_220B_56K, PAGE)
    if not (present(DISK_2_20B_56K_SYSTEM) and present(DISK_2_20_44K_SYSTEM)):
        pytest.skip("reference disk(s) missing")
    dsk = bytearray(DISK_2_20B_56K_SYSTEM.read_bytes())
    bios56 = build_bios_image_220b_56k(dsk)
    assert len(bios56) == BIOS_LEN_220B_56K == 6 * PAGE
    back = _scatter(bios56, BIOS_PAGE_TO_SECTOR_220B_56K, BIOS_ORG_220B_56K, bytearray(dsk))
    for s in BIOS_PAGE_TO_SECTOR_220B_56K.values():
        assert back[s*PAGE:s*PAGE+PAGE] == dsk[s*PAGE:s*PAGE+PAGE], "scatter not byte-identical"
    assert len(set(BIOS_PAGE_TO_SECTOR_220B_56K.values())) == 6, "sectors not distinct"
    assert bios56[0] == 0xC3, "BOOT entry $DA00 should be JP on the static on-disk image"

    bios44 = reference_bios_image()  # 2.20-44K BIOS at $AA00
    same = reloc = genuine = 0
    for a, b in zip(bios44, bios56):
        if a == b: same += 1
        elif (a + 0x30) & 0xFF == b: reloc += 1
        else: genuine += 1
    # 56K = 44K relocated +$3000: only the bounded 2.20->2.20B island is "genuine".
    assert genuine <= 60, f"too many non-relocation deltas ({genuine}); 56K should be 44K+$3000"
    assert reloc >= 150, f"expected the +$3000 high-byte shifts ({reloc} found)"


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="sjasmplus not on PATH")
def test_cpm220_bios_folds_44k_and_2_20b_56k_from_one_source():
    """The single CPMV220-44K/os/CPM_BIOS.asm conditionally compiles to BOTH the 2.20-44K
    BIOS (no defines) and the 2.20B-56K BIOS (-DCFG_56K -DV220B), byte-identical to each
    reference. CFG_56K re-homes the image +$3000 (cpm_system_220.inc's OS_RELOC); V220B adds
    the 2.20->2.20B island: CONIN pre-scan routing, the CCP_INLEN warm-boot stub (x3, one the
    live WBOOT target), and the '56K Ver. 2.20B' banner. See docs/CPM_56K_60K_Fold_Plan.md."""
    import subprocess
    import re as _re
    from cpm_pipeline import deskew
    if not (present(DISK_2_20_44K_SYSTEM) and present(DISK_2_20B_56K_SYSTEM)):
        pytest.skip("reference disk(s) missing")
    root = Path(__file__).resolve().parents[2]          # softcard/
    bios = root / "CPMV220-44K" / "os" / "CPM_BIOS.asm"
    incs = root / "include"

    def assemble(defines):
        tmp = Path(tempfile.mkdtemp())
        for inc in ("apple_softcard.inc", "cpm22.inc", "cpm_system_220.inc"):
            shutil.copy(incs / inc, tmp / inc)
        src = bios.read_text(encoding="latin-1")
        outbin = (tmp / "bios.bin").as_posix()
        src = _re.sub(r'(\bSAVEBIN\s+")([^"]+)(",.*)',
                      lambda m: m.group(1) + outbin + m.group(3), src)
        (tmp / "CPM_BIOS.asm").write_text(src, encoding="latin-1")
        r = subprocess.run(["sjasmplus"] + [f"-D{d}" for d in defines] + ["CPM_BIOS.asm"],
                           cwd=tmp, capture_output=True, text=True)
        assert r.returncode == 0, f"sjasmplus -D{defines} failed:\n{r.stdout}{r.stderr}"
        return Path(outbin).read_bytes()

    assert assemble(()) == deskew.reference_bios_image(), \
        "2.20-44K BIOS (no defines) not byte-identical"
    assert assemble(("CFG_56K", "V220B")) == deskew.reference_bios_image_220b_56k(), \
        "2.20B-56K BIOS fold (-DCFG_56K -DV220B) not byte-identical"


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="sjasmplus not on PATH")
def test_cpm220_ccp_bdos_fold_44k_and_2_20b_56k_from_one_source():
    """CPM_CCP.asm and CPM_BDOS.asm each conditionally compile byte-identical to BOTH the 2.20-44K
    image (no defines) and the 2.20B-56K image (-DCFG_56K -DV220B). CFG_56K re-homes them +$3000 via
    cpm_system_220.inc's OS_RELOC; V220B carries the small 2.20->2.20B deltas (the 6-byte serial in
    both, the DIR column-parity mask AND $01->$03, and the inert BDOS LD HL). This is the memory-axis
    counterpart to the BIOS fold; see docs/CPM_56K_60K_Fold_Plan.md."""
    import subprocess
    import re as _re
    from cpm_pipeline import deskew
    if not (present(DISK_2_20_44K_SYSTEM) and present(DISK_2_20B_56K_SYSTEM)):
        pytest.skip("reference disk(s) missing")
    root = Path(__file__).resolve().parents[2]
    incs = root / "include"

    def assemble(fname, defines):
        tmp = Path(tempfile.mkdtemp())
        for inc in ("apple_softcard.inc", "cpm22.inc", "cpm_system_220.inc"):
            shutil.copy(incs / inc, tmp / inc)
        src = (root / "CPMV220-44K" / "os" / fname).read_text(encoding="latin-1")
        outbin = (tmp / "out.bin").as_posix()
        src = src.replace("{out_bin}", outbin)                       # the real image SAVEBIN
        src = _re.sub(r'SAVEBIN\s+"E:/tmp/[^"]+"',                   # BDOS debug SAVEBIN -> throwaway
                      'SAVEBIN "' + (tmp / "debug.bin").as_posix() + '"', src)
        (tmp / fname).write_text(src, encoding="latin-1")
        r = subprocess.run(["sjasmplus"] + [f"-D{d}" for d in defines] + [fname],
                           cwd=tmp, capture_output=True, text=True)
        assert r.returncode == 0, f"sjasmplus {fname} -D{defines}:\n{r.stdout}{r.stderr}"
        return Path(outbin).read_bytes()

    rt44 = deskew.reference_runtime_image()          # 44K CCP($9400)+BDOS($9C00), 5632 B
    assert assemble("CPM_CCP.asm", ()) == rt44[0x0000:0x0800], "2.20-44K CCP not byte-identical"
    assert assemble("CPM_BDOS.asm", ()) == rt44[0x0800:0x1600], "2.20-44K BDOS not byte-identical"
    assert assemble("CPM_CCP.asm", ("CFG_56K", "V220B")) == deskew.reference_ccp_image_220b_56k(), \
        "2.20B-56K CCP fold not byte-identical"
    assert assemble("CPM_BDOS.asm", ("CFG_56K", "V220B")) == deskew.reference_bdos_image_220b_56k(), \
        "2.20B-56K BDOS fold not byte-identical"


# ── Step 0: transitive gates for the two DERIVED cells (no reference disk) ─────
# The 2.20 fold has FOUR version x memory cells but only TWO reference disks (2.20-44K
# and 2.20B-56K, the diagonal). The two off-diagonal cells -- 2.20B-44K and 2.20-56K --
# never shipped, so nothing byte-pins them directly. These gates pin them TRANSITIVELY:
# a derived cell, relocated by the memory axis, must equal a byte-gated diagonal cell of
# the SAME version. That also proves the MEMORY (CFG_56K) and VERSION (V220B) -D axes are
# ORTHOGONAL -- neither define smuggles in the other's deltas -- which is the one property
# the diagonal references alone cannot show. See docs/CPM_Unified_Build_Plan.md Step 0.

def _assemble_cpm220_os_module(fname, defines):
    """Assemble one folded 2.20 OS module (CPM_{CCP,BDOS,BIOS}.asm from CPMV220-44K/os/)
    with the given sjasmplus -D defines, returning the raw image bytes. Mirrors the fold
    tests' staging (shared includes copied in, SAVEBIN redirected to a temp file)."""
    import subprocess
    import re as _re
    root = Path(__file__).resolve().parents[2]
    incs = root / "include"
    tmp = Path(tempfile.mkdtemp())
    for inc in ("apple_softcard.inc", "cpm22.inc", "cpm_system_220.inc"):
        shutil.copy(incs / inc, tmp / inc)
    src = (root / "CPMV220-44K" / "os" / fname).read_text(encoding="latin-1")
    outbin = (tmp / "out.bin").as_posix()
    src = src.replace("{out_bin}", outbin)
    src = _re.sub(r'SAVEBIN\s+"E:/tmp/[^"]+"',
                  'SAVEBIN "' + (tmp / "debug.bin").as_posix() + '"', src)
    (tmp / fname).write_text(src, encoding="latin-1")
    r = subprocess.run(["sjasmplus"] + [f"-D{d}" for d in defines] + [fname],
                       cwd=tmp, capture_output=True, text=True)
    assert r.returncode == 0, f"sjasmplus {fname} -D{defines}:\n{r.stdout}{r.stderr}"
    return Path(outbin).read_bytes()


def _classify_memory_axis(base44, reloc56):
    """Classify the per-byte deltas between a 44K-base OS image and its +$3000 sibling of
    the SAME version. Returns (same, reloc, genuine): a byte is `same`, a +$30 relocation
    high-byte (`reloc`), or a `genuine` version/memory delta (offset, base, reloc)."""
    assert len(base44) == len(reloc56), "images differ in length -- not a pure relocation"
    same = reloc = 0
    genuine = []
    for i, (a, b) in enumerate(zip(base44, reloc56)):
        if a == b:
            same += 1
        elif (a + 0x30) & 0xFF == b:
            reloc += 1
        else:
            genuine.append((i, a, b))
    return same, reloc, genuine


# module -> count of genuine (non-relocation) memory-axis deltas expected. CCP/BDOS are a
# pure +$3000 with ZERO genuine bytes; the BIOS's only genuine memory-axis delta is the
# 2-byte "44K"->"56K" banner token (see the sign-on string). Empirically verified.
_MEM_AXIS_MODULES = {"CPM_CCP.asm": 0, "CPM_BDOS.asm": 0, "CPM_BIOS.asm": 2}
_BANNER_TOKEN = {(0x34, 0x35), (0x34, 0x36)}   # ASCII '4'->'5', '4'->'6'  ("44K" -> "56K")


def _assert_pure_memory_axis(fname, base44, reloc56):
    budget = _MEM_AXIS_MODULES[fname]
    same, reloc, genuine = _classify_memory_axis(base44, reloc56)
    assert reloc >= 100, f"{fname}: only {reloc} +$3000 relocations -- memory axis not applied?"
    assert len(genuine) == budget, (
        f"{fname}: {len(genuine)} genuine (non-relocation) deltas, expected {budget}: "
        f"{[(hex(o), hex(a), hex(b)) for o, a, b in genuine]}")
    assert all((a, b) in _BANNER_TOKEN for _, a, b in genuine), (
        f"{fname}: genuine deltas are not the '44K'->'56K' banner token: "
        f"{[(hex(o), hex(a), hex(b)) for o, a, b in genuine]}")


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="sjasmplus not on PATH")
def test_cpm220_derived_2_20b_44k_is_2_20b_56k_relocated():
    """DERIVED CELL 2.20B-44K (no reference disk): CPM_{CCP,BDOS,BIOS}.asm built -DV220B
    (44K bases) equals the SAME source built -DCFG_56K -DV220B (the real 2.20B-56K, already
    byte-gated) MODULO the memory axis -- each byte identical, a +$30 relocation high-byte,
    or the '44K'->'56K' banner token. Transitively pins the reference-less 2.20B-44K cell
    and proves CFG_56K carries no V220B delta (axis orthogonality)."""
    for fname in _MEM_AXIS_MODULES:
        _assert_pure_memory_axis(
            fname,
            _assemble_cpm220_os_module(fname, ("V220B",)),
            _assemble_cpm220_os_module(fname, ("CFG_56K", "V220B")))


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="sjasmplus not on PATH")
def test_cpm220_derived_2_20_56k_is_2_20_44k_relocated():
    """DERIVED CELL 2.20-56K (no reference disk): CPM_{CCP,BDOS,BIOS}.asm built with no
    defines (the real 2.20-44K, already byte-gated) equals the SAME source built -DCFG_56K
    MODULO the memory axis -- identical, a +$30 relocation high-byte, or the '44K'->'56K'
    banner token. Transitively pins the reference-less 2.20-56K cell and proves CFG_56K is a
    pure memory relocation that never pulls in a version delta."""
    for fname in _MEM_AXIS_MODULES:
        _assert_pure_memory_axis(
            fname,
            _assemble_cpm220_os_module(fname, ()),
            _assemble_cpm220_os_module(fname, ("CFG_56K",)))


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="ca65/ld65/sjasmplus not on PATH")
def test_os_listings_are_fresh():
    """The four per-component .lst listings (BootLoader/CCP/BDOS/BIOS) for each 44K tree are
    TRACKED side-by-side with their .asm and linked from the wiseowl articles, so they must
    not drift from the source. Regenerate each and compare to the committed file."""
    import tempfile
    from pathlib import Path
    from cpm_pipeline.chunk_map import (SOURCES_220_44K, SOURCES_223,
                                        SOURCES_223_60K_LISTING)
    from cpm_pipeline.os_listing import emit_listing
    chunks = [SOURCES_220_44K[k] for k in
              ("CPM220_44K_BootLoader", "CPM220_44K_CCP", "CPM220_44K_BDOS", "CPM220_44K_BIOS_Disk")]
    chunks += [SOURCES_223[k] for k in
               ("CPM223_BootLoader", "CPM223_44K_CCP", "CPM223_44K_BDOS", "CPM223_BIOS_Disk")]
    # The 60K OS modules now keep their addresses here too, having dropped their
    # inline "; $XXXX" comments; the .lst is the only place to read a 60K address.
    chunks += [SOURCES_223_60K_LISTING[k] for k in
               ("CPM223_60K_BIOS", "CPM223_60K_BDOS")]
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
