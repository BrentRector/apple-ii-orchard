"""Chunk-to-physical-sector mappings for the SoftCard CP/M 2.20 + 2.23 disks.

Each `ChunkSpec` says "this slice of the named binary belongs at this
physical (track, sector) position on the disk." The binary is one of:

  * a stem matching a `docs/CPM*.asm` source (assembled by
    `cpm_pipeline.assemble`); these are the bytes the round-trip annotated
    sources emit.
Both variants are now fully sourced: every boot/OS sector maps to an
assembled `docs/CPM*.asm` source (no pre-extracted `.bin` remains in the
map). The CCP+BDOS+BIOS LOAD_CPM staging area is split across the system image
(`CPM223_44K_System` = CPM_CCP.asm INCLUDEing CPM_BDOS.asm, the two
independent modules; the 2.20-56K tree still uses the legacy combined
`CPM220_SystemImage`), `CPM*_DiskCallbacks` (2.23), and `CPM*_BIOS_Disk`
(the pristine on-disk BIOS image). A future phase (Stage 2 of the
roadmap) will derive these maps automatically from boot-loader tracing
instead of hand-listing them.

Sector positions are *physical*; the disk-format module translates
to on-disk file offsets per .dsk/.po convention.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .assemble import ChunkSource


REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS = REPO_ROOT / "docs"
INVEST = REPO_ROOT / "cpm-investigation"
OS223_44K = REPO_ROOT / "CPMV223-44K" / "os"   # canonical 2.23 OS source tree (disk build reads here)
OS220 = REPO_ROOT / "CPMV220" / "os"           # canonical 2.20B-56K OS source tree
OS220_44K = REPO_ROOT / "CPMV220-44K" / "os"   # canonical 2.20-44K OS source tree (clean-room decompile)
INCLUDE_DIR = REPO_ROOT / "include"            # shared single-source-of-truth EQU includes
SOFTCARD_INC = INCLUDE_DIR / "apple_softcard.inc"   # Apple/SoftCard external-address names
CPM22_INC = INCLUDE_DIR / "cpm22.inc"               # CP/M 2.2 ABI EQUs (BDOS, F_*/DRV_*, base page, FCB)
CPM_SYSTEM_220_INC = INCLUDE_DIR / "cpm_system_220.inc"  # CCP<->BDOS cross-module bases (de-skew split)
CPM_SYSTEM_223_INC = INCLUDE_DIR / "cpm_system_223.inc"  # 2.23 CCP<->BDOS cross-module bases (de-skew split)


@dataclass(frozen=True)
class ChunkSpec:
    """One chunk's placement on disk.

    `source_name` is either a `docs/CPM*.asm` source stem (e.g.
    'CPM223_BootLoader') or a pre-extracted binary stem (e.g.
    'staging_223'). The reconstructor resolves it via the variant's
    SOURCES dict.
    """
    source_name: str    # 'CPM223_BootLoader' or 'staging_223' etc.
    src_offset: int     # byte offset into the source binary
    length: int         # bytes to copy (typically 256 = one sector)
    track: int
    phys_sector: int

    def disk_position(self) -> tuple[int, int]:
        return (self.track, self.phys_sector)


# ── 2.23 sources ───────────────────────────────────────────────────────
SOURCES_223: dict[str, ChunkSource | Path] = {
    # The canonical 2.23 OS sources now live in CPMV223-44K/os/; the disk build
    # assembles them directly (verified byte-identical to the former docs/CPM223_*
    # round-trip sources, which are retired). 6502 = ca65 .s; Z-80 = sjasmplus .asm.
    "CPM223_BootLoader": ChunkSource(
        asm_path=OS223_44K / "CPM_BootLoader.s",
        cpu="6502", org=0x0800, size=0x0C00,
        # Two embedded Z-80 blocks -- the slot-probe handshake ($11B1, run at
        # $1000) and the disk-translate routine ($0C39, run at $BC39) -- each real
        # Z-80 source, sub-assembled by sjasmplus and INCBIN'd (CPM_RPC6502
        # pattern, CPUs swapped).
        incbin_deps=(
            ("CPM_BootLoader_ProbeOvl.bin",
             OS223_44K / "CPM_BootLoader_ProbeOvl.asm", ()),
            ("CPM_BootLoader_DiskXlate.bin",
             OS223_44K / "CPM_BootLoader_DiskXlate.asm", ()),
        ),
    ),
    # NOTE: there is no separate CPM223_RWTS / CPM223_InstallFragments source.
    # CPM_BootLoader.s ($0800-$13FF) is the single canonical decode and already
    # contains the RWTS ($0A00-$0FFF) and the install image ($1200-$13FF, run at
    # $0200-$03FF); the former standalone files were byte-identical duplicates the
    # The 2.23-44K system image is the DE-SKEWED CCP + BDOS as TWO independent
    # compilations, each decoded at its true RUNTIME address (see docs/CPM_Skew_Findings.md):
    # CCP at ORG $9300 ($0900) and BDOS at ORG $9C00 ($0E00). They share only the $0005 ABI
    # (cpm22.inc) and the cross-module symbols in cpm_system_223.inc. The cold loader stages
    # the system tracks at Apple $8000 then relocates; the disk producer SCATTERS each runtime
    # page back to the .dsk sector the loader read it from (deskew.py :: PAGE_TO_SECTOR_223).
    "CPM223_44K_CCP": ChunkSource(
        asm_path=OS223_44K / "CPM_CCP.asm",
        cpu="z80", org=0x9300, size=0x0900,
        expected_bin_name="build/CPM223_44K_CCP.bin",
        include_files=(CPM22_INC, CPM_SYSTEM_223_INC),
    ),
    "CPM223_44K_BDOS": ChunkSource(
        asm_path=OS223_44K / "CPM_BDOS.asm",
        cpu="z80", org=0x9C00, size=0x0E00,
        expected_bin_name="build/CPM223_44K_BDOS.bin",
        include_files=(CPM22_INC, CPM_SYSTEM_223_INC),
    ),
    # The de-skewed runtime BIOS ($FA00-$FFFF, 6 pages) = Apple $0A00-$0FFF LOW RAM
    # (deskew.py :: BIOS_PAGE_TO_SECTOR_223). The prior 4-page "$FA00-$FDFF + runtime tail"
    # model was the on-disk-order skew; all 6 pages come from disk sectors 40-45.
    "CPM223_BIOS_Disk": ChunkSource(
        asm_path=OS223_44K / "CPM_BIOS.asm",
        cpu="z80", org=0xFA00, size=0x0600,
        expected_bin_name="build/CPM223_BIOS_Disk.bin",
        # The BIOS embeds a 6502 RPC service ($FDD0-$FE41); its ca65 source is
        # sub-assembled and INCBIN'd (the CPM_RPC6502 pattern).
        incbin_deps=(("CPM_RPC6502_223.bin", OS223_44K / "CPM_RPC6502_223.s", ()),),
        include_files=(SOFTCARD_INC, CPM22_INC),
    ),
}


# 2.23 chunk map. The 6502-side bytes ($0800-$13FF in Apple memory) come
# from CPM223_BootLoader.asm; the boot stub loaded them in CP/M skew order.
# The CCP+BDOS staging is loaded via LOAD_CPM (29 sectors).
CHUNKS_223: list[ChunkSpec] = []


def _build_chunks_223():
    # Boot stub + 6502 RWTS + stage-2 (11 sectors of track 0).
    # Apple memory $0800-$13FF, BUT $0900-$09FF is a P6 PROM workspace
    # gap that the boot stub never loads -- so the loaded sectors land
    # at $0800 (boot sector via P6 PROM) and then $0A00, $0B00, ...,
    # $1000, $1100, $1200, $1300.
    #
    # The CPM223_BootLoader.asm file emits all 3072 bytes ($0C00 size)
    # including the $0900-$09FF gap; we slice from `apple_addr - $0800`
    # to map each loaded sector to its position in the assembled binary.
    boot_stub_loads = [
        (0x0, 0x0800),  # boot sector (P6 PROM loads; counted here for completeness)
        (0x2, 0x0A00),  # RWTS start
        (0x4, 0x0B00),
        (0x6, 0x0C00),
        (0x8, 0x0D00),
        (0xA, 0x0E00),
        (0xC, 0x0F00),
        (0xE, 0x1000),  # stage-2 entry
        (0x1, 0x1100),  # stage-2 continuation
        (0x3, 0x1200),  # install src page 1 (copied to $0200 at install)
        (0x5, 0x1300),  # install src page 2 (incl. warm-boot routine)
    ]
    for phys, apple_addr in boot_stub_loads:
        CHUNKS_223.append(ChunkSpec(
            source_name="CPM223_BootLoader",
            src_offset=apple_addr - 0x0800, length=0x100,
            track=0, phys_sector=phys,
        ))

    # CCP + BDOS + BIOS: SCATTER each de-skewed runtime page back to the .dsk sector the
    # cold loader read it from (emulator-derived; deskew.py). The loader stages the system
    # at Apple $8000 (already de-interleaved) then relocates; we reproduce the on-disk sectors
    # by writing each runtime page to .dsk linear sector S -> (track S//16, physical sector
    # whose DOS-3.3 on-disk position is S%16), exactly as for 2.20-44K.
    from cpm_pipeline.deskew import PAGE_TO_SECTOR_223, BIOS_PAGE_TO_SECTOR_223
    from cpm_pipeline.disk_format import DOS33_INTERLEAVE
    dos33_inv = {od: phys for phys, od in enumerate(DOS33_INTERLEAVE)}
    for page, sector in PAGE_TO_SECTOR_223.items():
        src, base = (("CPM223_44K_CCP", 0x9300) if page < 0x9C00
                     else ("CPM223_44K_BDOS", 0x9C00))
        CHUNKS_223.append(ChunkSpec(
            source_name=src, src_offset=page - base, length=0x100,
            track=sector // 16, phys_sector=dos33_inv[sector % 16],
        ))
    for page, sector in BIOS_PAGE_TO_SECTOR_223.items():
        CHUNKS_223.append(ChunkSpec(
            source_name="CPM223_BIOS_Disk", src_offset=page - 0xFA00, length=0x100,
            track=sector // 16, phys_sector=dos33_inv[sector % 16],
        ))


_build_chunks_223()


# ── 2.20 sources ───────────────────────────────────────────────────────
SOURCES_220: dict[str, ChunkSource | Path] = {
    # Canonical 2.20 OS sources from CPMV220/os/ (verified byte-identical to the
    # former docs/CPM220_* round-trip sources, which are retired). 6502 = ca65 .s;
    # Z-80 = sjasmplus .asm.
    "CPM220_BootLoader": ChunkSource(
        asm_path=OS220 / "CPM_BootLoader.s",
        cpu="6502", org=0x0800, size=0x0C00,
        # Two embedded Z-80 blocks -- slot-probe handshake ($1169) and slot-3
        # console driver ($134A) -- each real Z-80 source, sub-assembled by
        # sjasmplus and INCBIN'd (CPM_RPC6502 pattern, CPUs swapped).
        incbin_deps=(
            ("CPM_BootLoader_ProbeOvl.bin",
             OS220 / "CPM_BootLoader_ProbeOvl.asm", ()),
            ("CPM_BootLoader_ConInit.bin",
             OS220 / "CPM_BootLoader_ConInit.asm", ()),
        ),
    ),
    # (No separate CPM220_RWTS / CPM220_InstallFragments: CPM_BootLoader.s is the
    # single canonical decode of $0800-$13FF, which already includes both regions;
    # the standalone files were byte-identical duplicates the build never placed.)
    "CPM220_SystemImage": ChunkSource(
        asm_path=OS220 / "CPM_SystemImage.asm",
        cpu="z80", org=0x8000, size=0x1700,
        expected_bin_name="build/CPM220_SystemImage.bin",
    ),
    # The as-shipped pristine on-disk BIOS ($DA00-$DEFF) -- what LOAD_CPM reads.
    # The runtime device/console tail it builds in RAM is documented in
    # CPMV220/BOOT_AND_PATCHING.md, not baked into this source.
    "CPM220_BIOS_Disk": ChunkSource(
        asm_path=OS220 / "CPM_BIOS.asm",
        cpu="z80", org=0xDA00, size=0x0500,
        expected_bin_name="build/CPM220_BIOS_Disk.bin",
        include_files=(SOFTCARD_INC,),
    ),
}


CHUNKS_220: list[ChunkSpec] = []


def _build_chunks_220():
    # 2.20's boot stub has the same sector sequence as 2.23 (the 6502 boot
    # logic is byte-identical except for the slot-scanner delta in stage 2).
    boot_stub_loads = [
        (0x0, 0x0800),
        (0x2, 0x0A00),
        (0x4, 0x0B00),
        (0x6, 0x0C00),
        (0x8, 0x0D00),
        (0xA, 0x0E00),
        (0xC, 0x0F00),
        (0xE, 0x1000),
        (0x1, 0x1100),
        (0x3, 0x1200),
        (0x5, 0x1300),
    ]
    for phys, apple_addr in boot_stub_loads:
        CHUNKS_220.append(ChunkSpec(
            source_name="CPM220_BootLoader",
            src_offset=apple_addr - 0x0800, length=0x100,
            track=0, phys_sector=phys,
        ))

    # 2.20 LOAD_CPM reads 28 sectors (vs 2.23's 29). Same sequence,
    # one short:
    #   trk0:phys $B,$C,$D,$E,$F  (5 sectors)
    #   trk1:phys $0..$F          (16 sectors)
    #   trk2:phys $0..$6          (7 sectors)
    staging_sectors = [(0, p) for p in range(0xB, 0x10)]
    staging_sectors += [(1, p) for p in range(0x10)]
    staging_sectors += [(2, p) for p in range(0x7)]

    # offset $0000-$16FF (sectors 0-22)  -> CPM220_SystemImage (CCP + BDOS)
    # offset $1700-$1BFF (sectors 23-27) -> CPM220_BIOS_Disk   (pristine BIOS @ $DA00)
    for i, (track, phys) in enumerate(staging_sectors):
        off = i * 0x100
        if off < 0x1700:
            src, base = "CPM220_SystemImage", 0x0000
        else:
            src, base = "CPM220_BIOS_Disk", 0x1700
        CHUNKS_220.append(ChunkSpec(
            source_name=src, src_offset=off - base, length=0x100,
            track=track, phys_sector=phys,
        ))


_build_chunks_220()


# ── 2.20-44K sources (clean-room decompile, CPMV220-44K/os/) ────────────
# The original 1980 44K build: same boot/staging sector layout as the 2.20B-56K
# disk, but the Z-80 OS is assembled at the 44K (original) runtime bases --
# SystemImage (serial page + CCP + BDOS) at $9300, BIOS at $AA00 (vs the 56K
# $C300/$DA00). 6502 BootLoader is its own 44K image. Round-trips byte-identical.
SOURCES_220_44K: dict[str, ChunkSource | Path] = {
    "CPM220_44K_BootLoader": ChunkSource(
        asm_path=OS220_44K / "CPM_BootLoader.s",
        cpu="6502", org=0x0800, size=0x0C00,
        # The boot image embeds two Z-80 blocks -- the slot-probe handshake
        # ($1169) and the console driver ($134A); each is real Z-80 source,
        # sub-assembled by sjasmplus and INCBIN'd at its offset (the CPM_RPC6502
        # pattern with the CPUs swapped).
        incbin_deps=(
            ("CPM_BootLoader_ProbeOvl.bin",
             OS220_44K / "CPM_BootLoader_ProbeOvl.asm", ()),
            ("CPM_BootLoader_ConInit.bin",
             OS220_44K / "CPM_BootLoader_ConInit.asm", ()),
        ),
    ),
    # The system image is the DE-SKEWED CCP + BDOS as TWO independent compilations,
    # each decoded at its true RUNTIME address (see docs/CPM_Skew_Findings.md): the CCP
    # at ORG $9400 ($0800) and the BDOS at ORG $9C00 ($0E00). They share only the $0005
    # ABI (cpm22.inc) and the two module bases in cpm_system_220.inc. The cold loader
    # de-interleaves the system tracks into this contiguous image, so the disk producer
    # SCATTERS each runtime page back to the .dsk sector the loader read it from
    # (cpm_pipeline/deskew.py :: PAGE_TO_SECTOR) -- see _build_chunks_220_44k.
    "CPM220_44K_CCP": ChunkSource(
        asm_path=OS220_44K / "CPM_CCP.asm",
        cpu="z80", org=0x9400, size=0x0800,
        expected_bin_name="build/CPM220_44K_CCP.bin",
        include_files=(CPM22_INC, CPM_SYSTEM_220_INC),
    ),
    "CPM220_44K_BDOS": ChunkSource(
        asm_path=OS220_44K / "CPM_BDOS.asm",
        cpu="z80", org=0x9C00, size=0x0E00,
        expected_bin_name="build/CPM220_44K_BDOS.bin",
        include_files=(CPM22_INC, CPM_SYSTEM_220_INC),
    ),
    # The de-skewed runtime BIOS ($AA00-$AFFF, 6 pages) -- decoded at its true RUNTIME
    # addresses (the cold loader de-interleaves it; cpm_pipeline/deskew.py ::
    # BIOS_PAGE_TO_SECTOR). The disk producer re-applies the sector skew on the way out.
    "CPM220_44K_BIOS_Disk": ChunkSource(
        asm_path=OS220_44K / "CPM_BIOS.asm",
        cpu="z80", org=0xAA00, size=0x0600,
        expected_bin_name="build/CPM220_44K_BIOS_Disk.bin",
        include_files=(SOFTCARD_INC, CPM22_INC),
    ),
}


CHUNKS_220_44K: list[ChunkSpec] = []


def _build_chunks_220_44k():
    # Same boot stub + 28-sector LOAD_CPM staging layout as the 2.20 (56K) disk;
    # only the Z-80 source ORGs differ (44K bases).
    boot_stub_loads = [
        (0x0, 0x0800), (0x2, 0x0A00), (0x4, 0x0B00), (0x6, 0x0C00),
        (0x8, 0x0D00), (0xA, 0x0E00), (0xC, 0x0F00), (0xE, 0x1000),
        (0x1, 0x1100), (0x3, 0x1200), (0x5, 0x1300),
    ]
    for phys, apple_addr in boot_stub_loads:
        CHUNKS_220_44K.append(ChunkSpec(
            source_name="CPM220_44K_BootLoader",
            src_offset=apple_addr - 0x0800, length=0x100,
            track=0, phys_sector=phys,
        ))
    # CCP+BDOS: SCATTER each de-skewed runtime page to the .dsk sector the cold loader
    # de-interleaved it from (emulator-derived; cpm_pipeline/deskew.py). The .dsk linear
    # sector S -> (track S//16, physical sector whose DOS-3.3 on-disk position is S%16).
    from cpm_pipeline.deskew import PAGE_TO_SECTOR
    from cpm_pipeline.disk_format import DOS33_INTERLEAVE
    dos33_inv = {od: phys for phys, od in enumerate(DOS33_INTERLEAVE)}
    for page, sector in PAGE_TO_SECTOR.items():
        src, base = (("CPM220_44K_CCP", 0x9400) if page < 0x9C00
                     else ("CPM220_44K_BDOS", 0x9C00))
        CHUNKS_220_44K.append(ChunkSpec(
            source_name=src, src_offset=page - base, length=0x100,
            track=sector // 16, phys_sector=dos33_inv[sector % 16],
        ))
    # BIOS ($AA00-$AFFF, 6 pages): SCATTER each de-skewed runtime page to the .dsk sector
    # the cold loader de-interleaved it from (emulator-derived; deskew.py::BIOS_PAGE_TO_SECTOR),
    # exactly as for CCP+BDOS above. The prior 5-page placement decoded the BIOS in on-disk
    # (sector-interleaved) order and was both mis-addressed and missing the 6th page.
    from cpm_pipeline.deskew import BIOS_PAGE_TO_SECTOR
    for page, sector in BIOS_PAGE_TO_SECTOR.items():
        CHUNKS_220_44K.append(ChunkSpec(
            source_name="CPM220_44K_BIOS_Disk", src_offset=page - 0xAA00, length=0x100,
            track=sector // 16, phys_sector=dos33_inv[sector % 16],
        ))


_build_chunks_220_44k()


# ── Convenience ────────────────────────────────────────────────────────
def get_variant(variant: str) -> tuple[list[ChunkSpec], dict]:
    """Return (chunks, sources) for variant '220', '223', or '220-44k'."""
    if variant == "223":
        return CHUNKS_223, SOURCES_223
    if variant == "220":
        return CHUNKS_220, SOURCES_220
    if variant == "220-44k":
        return CHUNKS_220_44K, SOURCES_220_44K
    raise ValueError(f"unknown variant {variant!r}; expected '220', '223', or '220-44k'")
