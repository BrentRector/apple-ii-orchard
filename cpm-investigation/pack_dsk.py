"""
pack_dsk.py -- Build a Microsoft SoftCard CP/M .DSK image from annotated
                assembly source.

This is pseudo-code in the form of a runnable Python script. It documents
the MAPPING from assembled binary chunks (each chunk being the output of
assembling one of the CPM223_*.asm or CPM220_*.asm source files at its
.ORG address) to physical disk sectors of a 35-track DOS-3.3-ordered
.DSK image.

OVERVIEW
========

A Microsoft SoftCard CP/M .DSK image is 143360 bytes:
    35 tracks * 16 sectors * 256 bytes = 143360.

Sectors are stored in DOS 3.3 LOGICAL order. The boot stub and LOAD_CPM
both reference sectors via the CP/M skew table (0,2,4,6,8,A,C,E,1,3,5).
To compose a .DSK image from binary chunks, we need to:

    1. Assemble each .asm source file at its .ORG address, producing a
       binary chunk keyed by Apple-side memory address (or Z-80-side for
       Z-80 sources, which then need to be stored at their LC-RAM-source
       sectors).
    2. Look up where each chunk goes physically on disk via the
       per-physical-sector map (docs/CPM_DiskSectorMap.md).
    3. Convert physical sector position to DOS-3.3 logical via the
       interleave table.
    4. Write the bytes into the right offset of the .DSK output.
    5. Fill unused sectors with zeros (or with the CP/M filesystem
       content from a reference image if you want a bootable disk that
       runs more than just CP/M's CCP).

This script is the MAPPING; the assembly step is delegated to a real
6502/Z-80 assembler (e.g., ca65 + z80asm) and isn't implemented here.
For round-trip testing we use the already-extracted .bin files instead.

USAGE
=====

    python pack_dsk.py CPMV233.DSK ./build/cpm223.dsk

The reference .DSK is read to fill sectors we don't generate (mostly
the CP/M filesystem on tracks 3+); the generated .DSK is the output.
"""

import sys
import struct
from pathlib import Path

# ----------------------------------------------------------------------------
# Apple Disk II DOS 3.3 interleave: physical sector -> logical sector
# (logical sector that's stored at this physical position on disk)
# ----------------------------------------------------------------------------
DOS33_INTERLEAVE = [0x0, 0x7, 0xE, 0x6, 0xD, 0x5, 0xC, 0x4,
                    0xB, 0x3, 0xA, 0x2, 0x9, 0x1, 0x8, 0xF]


def disk_offset(track: int, phys_sector: int) -> int:
    """Return file offset in DOS-3.3-ordered .DSK for (track, physical sector)."""
    logical = DOS33_INTERLEAVE[phys_sector]
    return (track * 16 + logical) * 256


# ----------------------------------------------------------------------------
# CHUNK MAP: each entry says "this binary chunk goes at this physical sector".
#
# The chunks correspond to assembled outputs of the .asm source files.
# For now we read pre-extracted .bin files (round-trip testing). A real
# build tool would assemble the .asm files first.
# ----------------------------------------------------------------------------

# 2.23 chunk map (track, phys_sector) -> (source_file, byte_offset, length)
#
# The boot stub is at trk0:phys0 (always; loaded by P6 PROM).
# The boot-stub-loaded sectors of track 0 map per the LOAD_MAP in
# extract_loader.py. The LOAD_CPM-staged sectors map per the
# 29-sector CP/M skew read starting at trk0:logical $0B.

CHUNKS_223 = [
    # === Boot stub + RWTS + stage-2 (track 0, loaded by boot stub) ===
    # Source: loader_223.bin (3 KB covering Apple $0800-$13FF)
    # Apple address -> physical sector mapping per extract_loader.py LOAD_MAP

    # Apple $0800 (boot stub) -> trk0:phys0
    ('loader_223.bin', 0x000, 0x100, 0, 0x0),
    # Apple $0A00 (RWTS) -> trk0:phys2
    ('loader_223.bin', 0x200, 0x100, 0, 0x2),
    # Apple $0B00 -> trk0:phys4
    ('loader_223.bin', 0x300, 0x100, 0, 0x4),
    # Apple $0C00 -> trk0:phys6
    ('loader_223.bin', 0x400, 0x100, 0, 0x6),
    # Apple $0D00 -> trk0:phys8
    ('loader_223.bin', 0x500, 0x100, 0, 0x8),
    # Apple $0E00 -> trk0:physA
    ('loader_223.bin', 0x600, 0x100, 0, 0xA),
    # Apple $0F00 -> trk0:physC
    ('loader_223.bin', 0x700, 0x100, 0, 0xC),
    # Apple $1000 (stage-2 entry) -> trk0:physE
    ('loader_223.bin', 0x800, 0x100, 0, 0xE),
    # Apple $1100 (stage-2 cont.) -> trk0:phys1
    ('loader_223.bin', 0x900, 0x100, 0, 0x1),
    # Apple $1200 (install src page 1) -> trk0:phys3
    ('loader_223.bin', 0xA00, 0x100, 0, 0x3),
    # Apple $1300 (install src page 2 incl. warm-boot) -> trk0:phys5
    ('loader_223.bin', 0xB00, 0x100, 0, 0x5),

    # === CCP + BDOS + banner (29-sector LOAD_CPM read) ===
    # Source: staging_223.bin (sysimg first 23 sectors + newdisk last 6)
    # Read via CP/M skew starting at trk0:logical $0B
    # Logical-sector destination order is (in skew):
    #   trk0:$B,$C,$D,$E,$F  (5 sectors of track 0 after sector $A)
    #   trk1:$0..$F          (16 sectors of track 1)
    #   trk2:$0..$7          (8 sectors of track 2)
    # = 29 sectors total

    # We map the 29 sectors of staging by their logical-sector order;
    # the CP/M skew of the boot loader tracks this implicitly.
    # Since DOS33_INTERLEAVE is already physical->logical, we'll find
    # the physical sector for each logical position.

    # (Loop generated below in code, not enumerated here.)
]


def build_223_dsk(reference_dsk: Path, output_dsk: Path):
    """Build a 2.23 .DSK image, using pre-extracted binary chunks."""
    # Start with reference disk image (so CP/M filesystem on tracks 3+
    # is preserved). A pure ground-up build would zero-fill.
    with open(reference_dsk, 'rb') as f:
        dsk = bytearray(f.read())

    # Load source binaries
    sources = {}
    base = Path('cpm-investigation')
    for name in ['loader_223.bin', 'sysimg_223.bin', 'newdisk_223.bin', 'staging_223.bin']:
        p = base / name
        if p.exists():
            sources[name] = p.read_bytes()

    # Apply explicit chunks from CHUNKS_223
    for source, offset, length, track, phys in CHUNKS_223:
        chunk = sources[source][offset:offset + length]
        target = disk_offset(track, phys)
        dsk[target:target + length] = chunk
        print(f'  {source}+{offset:#06x} ({length:#x} bytes) -> trk{track}:phys{phys:X} '
              f'(disk offset {target:#06x})')

    # Apply CCP+BDOS staging across the 29-sector LOAD_CPM read.
    # The 29 sectors are read into Apple $8000-$9CFF using PHYSICAL
    # sector numbers (NOT logical). LOAD_CPM advances physical sectors
    # sequentially starting at trk0:phys$0B, wrapping at sector $10
    # to the next track:
    #   trk0:phys $B, $C, $D, $E, $F                 (5 sectors)
    #   trk1:phys $0..$F                             (16 sectors)
    #   trk2:phys $0..$7                             (8 sectors)
    # = 29 sectors total
    #
    # See reconstruct_staging.py for the staging-extraction reference.
    staging = sources['staging_223.bin']
    sectors = [(0, p) for p in range(0xB, 0x10)]
    sectors += [(1, p) for p in range(0x10)]
    sectors += [(2, p) for p in range(0x8)]

    for i, (track, phys) in enumerate(sectors):
        # disk_offset takes a physical sector and returns the .DSK file
        # offset where DOS-3.3 stores that physical position's content
        # (i.e., disk_offset = (track*16 + interleave[phys]) * 256).
        target = disk_offset(track, phys)
        dsk[target:target + 256] = staging[i * 256:(i + 1) * 256]
        print(f'  staging+{i*256:#06x} (sector {i}) -> '
              f'trk{track}:phys${phys:X} '
              f'(disk offset {target:#06x})')

    # The remaining boot-related sectors (BIOS bytes that don't fit in
    # newdisk) are loaded by the SECOND JSR $BBEB at loader-stage-2
    # $111E. Those sectors are at trk2:phys8-physF and possibly into
    # track 3. The destinations within the SoftCard's high-RAM aren't
    # fully traced; for round-trip testing we leave those sectors as
    # they are in the reference image.

    # Write output
    with open(output_dsk, 'wb') as f:
        f.write(dsk)
    print(f'\nWrote {output_dsk} ({len(dsk)} bytes)')


def verify_against(generated: Path, reference: Path):
    """Compare two .DSK images byte-for-byte."""
    with open(generated, 'rb') as f:
        g = f.read()
    with open(reference, 'rb') as f:
        r = f.read()
    if len(g) != len(r):
        print(f'SIZE MISMATCH: {len(g)} vs {len(r)}')
        return
    diffs = sum(1 for i in range(len(g)) if g[i] != r[i])
    print(f'Byte differences: {diffs}/{len(g)}')
    if diffs == 0:
        print('  PERFECT MATCH -- the chunk map is correct')
    elif diffs < 256:
        print(f'  Close match -- showing first 10 diff offsets:')
        d = [i for i in range(len(g)) if g[i] != r[i]][:10]
        for off in d:
            track = off // (16 * 256)
            sec = (off % (16 * 256)) // 256
            print(f'    offset {off:#06x} (trk{track}:logical{sec:X}): '
                  f'gen={g[off]:02x} ref={r[off]:02x}')


# ============================================================================
# REAL BUILD TOOL (pseudo-code outline, not implemented)
# ============================================================================
"""
PSEUDO-CODE for a full build tool that goes from .asm sources to .DSK:

def real_build(asm_files: list[Path], output_dsk: Path):
    # 1. Assemble each .asm at its declared .ORG address
    binaries = {}
    for asm in asm_files:
        org, output = run_6502_or_z80_assembler(asm)
        binaries[asm.stem] = (org, output)
        # Each binary is keyed by source-file name and has a known ORG.

    # 2. Use the per-physical-sector map (docs/CPM_DiskSectorMap.md)
    #    to determine which (track, phys_sector) gets which bytes
    #    from which binary.
    sector_map = parse_sector_map('docs/CPM_DiskSectorMap.md')
    # Each entry: (track, phys, source_binary, byte_offset, length)

    # 3. Compose the .DSK
    dsk = bytearray(35 * 16 * 256)  # zero-filled
    for (track, phys), (source, offset, length) in sector_map.items():
        org, binary = binaries[source]
        target = disk_offset(track, phys)
        dsk[target:target + length] = binary[offset:offset + length]

    # 4. Optionally fill remaining sectors with CP/M filesystem
    #    content from a reference image (or leave zero-filled to
    #    create a "bootable but no files" disk).

    write(output_dsk, dsk)


This requires:
  - A 6502 assembler (ca65 from cc65, or dasm) for the 6502 sources.
  - A Z-80 assembler (z80asm, or pasmo, or sjasmplus) for the Z-80
    sources. Each .asm file's leading symbols section needs to map to
    the assembler's syntax (e.g., ca65 uses '=' for symbol
    definitions, sjasmplus uses 'EQU').
  - A small wrapper that strips the disassembler-style "$0A00:"
    address prefixes (each line) before passing to the assembler.
  - The sector-map document parsed to obtain (track, phys) -> source
    bindings.

The current Python script implements step 3 and 4 directly using
pre-extracted .bin files (skipping assembly), which is enough to
verify the chunk map is correct via round-trip comparison against
the reference CPMV233.DSK.
"""


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: pack_dsk.py REFERENCE.DSK OUTPUT.DSK')
        sys.exit(1)

    ref = Path(sys.argv[1])
    out = Path(sys.argv[2])
    out.parent.mkdir(parents=True, exist_ok=True)

    print(f'Building {out} from binaries (reference: {ref})...')
    build_223_dsk(ref, out)

    print()
    print(f'Verifying against {ref}...')
    verify_against(out, ref)
