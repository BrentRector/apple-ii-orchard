"""Chunk-to-physical-sector mappings for the SoftCard CP/M 2.20 + 2.23 disks.

Each `ChunkSpec` says "this slice of the named binary belongs at this
physical (track, sector) position on the disk." The binary is one of:

  * a stem matching a `docs/CPM*.asm` source (assembled by
    `cpm_pipeline.assemble`); these are the bytes the round-trip annotated
    sources emit.
  * a stem matching a pre-extracted file in `cpm-investigation/` (e.g.
    `staging_223`, `newdisk_223`); these are bytes we don't yet have an
    annotated source for, so we read them from the prior investigation's
    extraction artifacts.

Phase 1 ships with the maps that were proven correct by
`cpm-investigation/pack_dsk.py` (the 2.23 case is fully covered there).
A future phase (Stage 2 of the roadmap) will derive these maps
automatically from boot-loader tracing instead of hand-listing them.

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
    # Annotated sources we assemble fresh:
    "CPM223_BootLoader": ChunkSource(
        asm_path=DOCS / "CPM223_BootLoader.asm",
        cpu="6502", org=0x0800, size=0x0C00,
    ),
    "CPM223_RWTS": ChunkSource(
        asm_path=DOCS / "CPM223_RWTS.asm",
        cpu="6502", org=0x0A00, size=0x0600,
    ),
    "CPM223_InstallFragments": ChunkSource(
        asm_path=DOCS / "CPM223_InstallFragments.asm",
        cpu="6502", org=0x0200, size=0x0200,
    ),
    "CPM223_DiskCallbacks": ChunkSource(
        asm_path=DOCS / "CPM223_DiskCallbacks.asm",
        cpu="z80", org=0x1A00, size=0x0200,
        expected_bin_name="build/CPM223_DiskCallbacks.bin",
    ),
    "CPM223_SystemImage": ChunkSource(
        asm_path=DOCS / "CPM223_SystemImage.asm",
        cpu="z80", org=0x8000, size=0x1700,
        expected_bin_name="build/CPM223_SystemImage.bin",
    ),
    "CPM223_BIOS": ChunkSource(
        asm_path=DOCS / "CPM223_BIOS.asm",
        # True base $FA00 (jump table first; = Apple $0A00 through the
        # real SoftCard map). Was 0xFAB8 -- the wrong-address-model org;
        # see docs/CPM_SoftCard_RealMap_Findings.md.
        cpu="z80", org=0xFA00, size=0x0548,
        expected_bin_name="build/CPM223_BIOS.bin",
    ),
    # Pre-extracted binaries we don't yet have an annotated source for:
    "staging_223": INVEST / "staging_223.bin",
    "newdisk_223": INVEST / "newdisk_223.bin",
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

    # CCP + BDOS + banner (29-sector LOAD_CPM read).
    # LOAD_CPM advances *physical* sectors sequentially starting at
    # trk0:phys$B, wrapping at sector $10:
    #   trk0:phys $B,$C,$D,$E,$F  (5 sectors)
    #   trk1:phys $0..$F          (16 sectors)
    #   trk2:phys $0..$7          (8 sectors)
    staging_sectors = [(0, p) for p in range(0xB, 0x10)]
    staging_sectors += [(1, p) for p in range(0x10)]
    staging_sectors += [(2, p) for p in range(0x8)]

    for i, (track, phys) in enumerate(staging_sectors):
        # Until Stage 2 of the roadmap can split staging into per-asm
        # pieces, we use the pre-extracted staging_223.bin as the source.
        # 5888 of these 7424 bytes correspond to CPM223_SystemImage.asm's
        # output; the remaining 1536 bytes are BIOS-area content not yet
        # in an annotated source.
        CHUNKS_223.append(ChunkSpec(
            source_name="staging_223",
            src_offset=i * 0x100, length=0x100,
            track=track, phys_sector=phys,
        ))


_build_chunks_223()


# ── 2.20 sources ───────────────────────────────────────────────────────
SOURCES_220: dict[str, ChunkSource | Path] = {
    "CPM220_BootLoader": ChunkSource(
        asm_path=DOCS / "CPM220_BootLoader.asm",
        cpu="6502", org=0x0800, size=0x0C00,
    ),
    "CPM220_RWTS": ChunkSource(
        asm_path=DOCS / "CPM220_RWTS.asm",
        cpu="6502", org=0x0A00, size=0x0600,
    ),
    "CPM220_InstallFragments": ChunkSource(
        asm_path=DOCS / "CPM220_InstallFragments.asm",
        cpu="6502", org=0x0200, size=0x0200,
    ),
    "CPM220_SystemImage": ChunkSource(
        asm_path=DOCS / "CPM220_SystemImage.asm",
        cpu="z80", org=0x8000, size=0x1700,
        expected_bin_name="build/CPM220_SystemImage.bin",
    ),
    "CPM220_BIOS": ChunkSource(
        asm_path=DOCS / "CPM220_BIOS.asm",
        # True base $DA00 (jump table first; = Apple $FA00 in LC RAM
        # through the real SoftCard map). Was 0xDACC -- the WBOOT handler
        # address mistaken for the base under the wrong address model.
        cpu="z80", org=0xDA00, size=0x0800,
        expected_bin_name="build/CPM220_BIOS.bin",
    ),
    # Pre-extracted binaries we don't yet have a clean per-asm split for:
    "staging_220": INVEST / "staging_220.bin",
    "newdisk_220": INVEST / "newdisk_220.bin",
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

    for i, (track, phys) in enumerate(staging_sectors):
        CHUNKS_220.append(ChunkSpec(
            source_name="staging_220",
            src_offset=i * 0x100, length=0x100,
            track=track, phys_sector=phys,
        ))


_build_chunks_220()


# ── Convenience ────────────────────────────────────────────────────────
def get_variant(variant: str) -> tuple[list[ChunkSpec], dict]:
    """Return (chunks, sources) for variant '220' or '223'."""
    if variant == "223":
        return CHUNKS_223, SOURCES_223
    if variant == "220":
        return CHUNKS_220, SOURCES_220
    raise ValueError(f"unknown variant {variant!r}; expected '220' or '223'")
