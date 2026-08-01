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
OS223_60K = REPO_ROOT / "CPMV223-60K" / "os"   # 2.23-60K OS source tree (separate build, bank-woven BDOS)
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
             OS223_44K / "CPM_BootLoader_DiskXlate.asm", (SOFTCARD_INC,)),
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
    # The 2.20B-56K OS core is FOLDED from the canonical 2.20-44K sources: the SAME
    # CPMV220-44K/os/CPM_{CCP,BDOS,BIOS}.asm, conditionally compiled with -DCFG_56K -DV220B,
    # produce the runtime CCP ($C400) / BDOS ($CC00) / BIOS ($DA00) images that the cold
    # loader de-interleaves onto the system tracks (sectors 11-18 / 19-32 / 33-38). This
    # retires the legacy combined CPMV220/os/CPM_SystemImage.asm + CPMV220/os/CPM_BIOS.asm.
    # See docs/CPM_56K_60K_Fold_Plan.md.
    "CPM220_56K_CCP": ChunkSource(
        asm_path=OS220_44K / "CPM_CCP.asm", cpu="z80", org=0xC400, size=0x0800,
        defines=("CFG_56K", "V220B"),
        include_files=(CPM22_INC, CPM_SYSTEM_220_INC),
    ),
    "CPM220_56K_BDOS": ChunkSource(
        asm_path=OS220_44K / "CPM_BDOS.asm", cpu="z80", org=0xCC00, size=0x0E00,
        defines=("CFG_56K", "V220B"),
        include_files=(CPM22_INC, CPM_SYSTEM_220_INC),
    ),
    "CPM220_56K_BIOS": ChunkSource(
        asm_path=OS220_44K / "CPM_BIOS.asm", cpu="z80", org=0xDA00, size=0x0600,
        defines=("CFG_56K", "V220B"),
        include_files=(SOFTCARD_INC, CPM22_INC, CPM_SYSTEM_220_INC),
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

    # The folded 56K OS core is de-skewed RUNTIME order; SCATTER each runtime page back to the
    # .po sector the cold loader de-interleaved it from (deskew.py 220b maps), exactly as the
    # 44K build does for its .dsk. The .po linear sector S -> (track S//16, physical sector whose
    # ProDOS on-disk position is S%16). CCP=$C400 (8pp, sec 11-18), BDOS=$CC00 (14pp, 19-32),
    # BIOS=$DA00 (6pp, 33-38).
    from cpm_pipeline.deskew import (
        CCP_PAGE_TO_SECTOR_220B_56K, BDOS_PAGE_TO_SECTOR_220B_56K, BIOS_PAGE_TO_SECTOR_220B_56K,
    )
    from cpm_pipeline.disk_format import PRODOS_INTERLEAVE
    prodos_inv = {od: phys for phys, od in enumerate(PRODOS_INTERLEAVE)}
    for src, org, page_map in (
        ("CPM220_56K_CCP", 0xC400, CCP_PAGE_TO_SECTOR_220B_56K),
        ("CPM220_56K_BDOS", 0xCC00, BDOS_PAGE_TO_SECTOR_220B_56K),
        ("CPM220_56K_BIOS", 0xDA00, BIOS_PAGE_TO_SECTOR_220B_56K),
    ):
        for page, sector in page_map.items():
            CHUNKS_220.append(ChunkSpec(
                source_name=src, src_offset=page - org, length=0x100,
                track=sector // 16, phys_sector=prodos_inv[sector % 16],
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
        include_files=(SOFTCARD_INC, CPM22_INC, CPM_SYSTEM_220_INC),
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


# ── Derived cells (no reference disk) + the 60K carry ───────────────────
# The 2.20 fold has four (version x memory) cells but only two reference disks
# (the 2.20-44K / 2.20B-56K diagonal). The two off-diagonal cells never shipped;
# each is the SAME chunk placement as its same-MEMORY sibling with the OS modules'
# -D defines swapped to describe the derived version/memory. Only the Z-80 OS
# modules (CPM_{CCP,BDOS,BIOS}.asm) carry the axis defines; the 6502 boot loader is
# version-agnostic and untouched. Validated TRANSITIVELY (docs/CPM_Unified_Build_Plan.md
# Step 0 + targets.verify_derived), never against a (non-existent) reference.
_OS_MODULE_NAMES = ("CPM_CCP.asm", "CPM_BDOS.asm", "CPM_BIOS.asm")


def _override_os_defines(sources: dict, defines: tuple) -> dict:
    """Copy a SOURCES dict, replacing every Z-80 OS module's `.defines` with `defines`
    (the boot loader and any non-OS entries pass through unchanged)."""
    from dataclasses import replace
    out: dict = {}
    for name, entry in sources.items():
        if (isinstance(entry, ChunkSource) and entry.cpu == "z80"
                and entry.asm_path.name in _OS_MODULE_NAMES):
            entry = replace(entry, defines=defines)
        out[name] = entry
    return out


# 2.20B-44K: the 2.20-44K placement (44K bases, DOS-3.3 .dsk) with the 2.20->2.20B
# island (-DV220B, no CFG_56K). Carrier = the 2.20-44K disk (same memory geometry).
SOURCES_220B_44K: dict = _override_os_defines(SOURCES_220_44K, ("V220B",))
CHUNKS_220B_44K: list[ChunkSpec] = CHUNKS_220_44K

# 2.20-56K: the 2.20B-56K placement (56K bases, ProDOS .po) WITHOUT the version island
# (-DCFG_56K only). Carrier = the 2.20B-56K disk (same memory geometry).
SOURCES_220_56K: dict = _override_os_defines(SOURCES_220, ("CFG_56K",))
CHUNKS_220_56K: list[ChunkSpec] = CHUNKS_220

# 2.23-60K: INSTALLER-DERIVED. The 60K system has NO OS chunk-map/reconstruct path
# (its BDOS is bank-woven across two language-card banks and still a partial blob); only
# CPM60.COM is byte-built from source (build_cpm60.build_cpm60_com). The disk is therefore
# CARRIED verbatim from its committed reference and its provenance is anchored to the
# byte-identical CPM60.COM. Empty OS chunk map = "carry the reference, overlay nothing".
# See docs/CPM_Unified_Build_Plan.md section 3 (honesty constraint) + DO-NOT-FOLD list.
SOURCES_223_60K: dict = {}
CHUNKS_223_60K: list[ChunkSpec] = []


# ── Convenience ────────────────────────────────────────────────────────
_VARIANTS: dict[str, tuple] = {
    "223":      ("CHUNKS_223", "SOURCES_223"),
    "220":      ("CHUNKS_220", "SOURCES_220"),
    "220-44k":  ("CHUNKS_220_44K", "SOURCES_220_44K"),
    "220b-44k": ("CHUNKS_220B_44K", "SOURCES_220B_44K"),   # derived (2.20B-44K)
    "220-56k":  ("CHUNKS_220_56K", "SOURCES_220_56K"),     # derived (2.20-56K)
    "223-60k":  ("CHUNKS_223_60K", "SOURCES_223_60K"),     # installer-derived (carry)
}


def get_variant(variant: str) -> tuple[list[ChunkSpec], dict]:
    """Return (chunks, sources) for a chunk-map variant.

    Variants: the three reference cells ('220', '223', '220-44k'), the two derived
    2.20 cells ('220b-44k', '220-56k'), and the installer-derived 60K carry ('223-60k').
    """
    if variant not in _VARIANTS:
        raise ValueError(
            f"unknown variant {variant!r}; expected one of {sorted(_VARIANTS)}")
    chunks_name, sources_name = _VARIANTS[variant]
    return globals()[chunks_name], globals()[sources_name]


def os_module_sources(variant: str) -> dict:
    """The Z-80 OS module ChunkSources for a variant, keyed by asm filename
    ('CPM_CCP.asm' / 'CPM_BDOS.asm' / 'CPM_BIOS.asm'). Empty for '223-60k' (no OS
    chunk map). Used by targets.verify_derived to assemble a cell's OS modules."""
    _, sources = get_variant(variant)
    return {e.asm_path.name: e for e in sources.values()
            if isinstance(e, ChunkSource) and e.asm_path.name in _OS_MODULE_NAMES}


# ── 2.23-60K listing sources ─────────────────────────────────────────────
# The 60K OS is built by build_cpm60 / regenerate_60k_*, not from a disk chunk
# map, so its two Z-80 modules have no entry above. They still need ChunkSources
# for one purpose: emitting the tracked .lst. Those sources carry no inline
# "; $XXXX" address comments -- the addresses live in the listing, exactly as in
# the 44K trees -- so the listing is the only place to read an address off the
# 60K OS, and it has to stay fresh.
# The 60K OS modules now share the same EQU/STRUCT headers the two 44K trees use, so the
# standalone listing build has to stage them exactly as the CPM60.asm master does.
SOURCES_223_60K_LISTING: dict[str, ChunkSource] = {
    "CPM223_60K_BIOS": ChunkSource(
        asm_path=OS223_60K / "CPM_BIOS.asm", cpu="z80", org=0xFA00, size=0x0600,
        include_files=(CPM22_INC,),
    ),
    "CPM223_60K_BDOS": ChunkSource(
        asm_path=OS223_60K / "CPM_BDOS.asm", cpu="z80", org=0xDC00, size=0x0E00,
        include_files=(CPM22_INC,),
    ),
}
