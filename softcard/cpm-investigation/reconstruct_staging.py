"""
Reconstruct the CP/M system image staging area at $8000-$9CFF
by simulating LOAD_CPM's disk reads.

LOAD_CPM (Apple $0BEB after PREP_HANDOFF copy) reads 29 physical sectors
sequentially starting at track 0 sector $0B:
  trk0: sectors $0B, $0C, $0D, $0E, $0F  (5 sectors)
  trk1: sectors $00 through $0F          (16 sectors)
  trk2: sectors $00 through $07          (8 sectors)
each going to memory pages $80, $81, ..., $9C (in order).

Then PREP_HANDOFF splits the staged area:
  $9700-$9CFF (last 6 pages) -> Apple $0A00-$0FFF (new disk routines)
  $8000-$96FF (first 23 pages) -> Apple $A300-$B9FF (CCP + BDOS + BIOS)

This script extracts the sectors from the .DSK file, builds the staging
area, applies the PREP_HANDOFF copies, and writes the resulting binaries
for further analysis.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE


def read_phys_sector(disk_data, track, phys_sector, interleave):
    """Read one physical sector from a flat 140K disk image."""
    logical = interleave[phys_sector]
    offset = (track * 16 + logical) * 256
    return disk_data[offset:offset + 256]


def reconstruct(disk_path, interleave):
    with open(disk_path, 'rb') as f:
        disk = f.read()

    # Build the staging area: 29 sectors at $8000-$9CFF
    staging = bytearray()
    sector_log = []

    # Start at track 0 sector $0B
    track, phys = 0, 0x0B
    for i in range(29):
        sector_log.append((track, phys))
        sector = read_phys_sector(disk, track, phys, interleave)
        staging.extend(sector)
        phys += 1
        if phys >= 16:
            phys = 0
            track += 1

    # Apply the PREP_HANDOFF copies:
    # First 23 pages ($8000-$96FF) -> $A300-$B9FF (the system image)
    sysimg = bytes(staging[0:0x1700])  # 23 pages = $1700 bytes

    # Last 6 pages ($9700-$9CFF) -> $0A00-$0FFF (new disk routines)
    new_disk = bytes(staging[0x1700:0x1D00])  # 6 pages = $600 bytes

    return staging, sysimg, new_disk, sector_log


def main():
    from nibbler.gcr import PRODOS_INTERLEAVE
    cases = [
        ('223', 'e:/Orchard/softcard/CPMV223-44K/CPMV223-44K.DSK',    DOS33_INTERLEAVE),
        ('220', 'e:/Orchard/softcard/CPMV220/CPMV220-Disk1.po', PRODOS_INTERLEAVE),
    ]
    for label, path, interleave in cases:
        staging, sysimg, new_disk, sector_log = reconstruct(path, interleave)

        print(f"=== {label}: extracted from {path} ===")
        print(f"Total staging: {len(staging)} bytes ($8000-${0x8000+len(staging)-1:04X})")
        print(f"  Sectors read (track, physical_sector):")
        for i, (t, s) in enumerate(sector_log):
            apple_dest = 0x8000 + i * 256
            print(f"    [{i:2d}] trk{t:2d}:sec${s:X} -> Apple ${apple_dest:04X}")

        # Save staging area for browsing
        out_path = f'e:/Orchard/softcard/cpm-investigation/staging_{label}.bin'
        with open(out_path, 'wb') as f:
            f.write(staging)
        print(f"\n  Wrote {out_path} ({len(staging)} bytes)")

        # Save the system image (CCP+BDOS+BIOS area, lands at Apple $A300-$B9FF)
        out_path = f'e:/Orchard/softcard/cpm-investigation/sysimg_{label}.bin'
        with open(out_path, 'wb') as f:
            f.write(sysimg)
        print(f"  Wrote {out_path} ({len(sysimg)} bytes) — base address Apple \\$A300")

        # Save the new disk routines (lands at Apple $0A00-$0FFF, replacing originals)
        out_path = f'e:/Orchard/softcard/cpm-investigation/newdisk_{label}.bin'
        with open(out_path, 'wb') as f:
            f.write(new_disk)
        print(f"  Wrote {out_path} ({len(new_disk)} bytes) — base address Apple \\$0A00")
        print()


if __name__ == '__main__':
    main()
