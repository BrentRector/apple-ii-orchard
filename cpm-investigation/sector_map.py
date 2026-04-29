"""
Generate the comprehensive disk-sector map for SoftCard CP/M 2.23.

For each physical sector of the 140K disk image (35 tracks * 16 sectors),
report:
  - what bytes are there (first N bytes / brief signature)
  - what the loader does with them (boot stub / LOAD_CPM / second LOAD_CPM / unused)
  - what address they end up at in Apple memory after the loader runs
  - which mechanism gets them there

The output is a structured Markdown table suitable for the docs/ directory
or the wiseowl.com reference collection.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE


# Mapping from (track, phys_sector) -> description of what's in it and where it ends up.
# Built from the cpm-videx investigation findings.

def classify_sector(track, phys, disk_data, interleave):
    """Return (bytes_first_8, role_description, final_apple_addr_range)."""
    logical = interleave[phys]
    file_offset = (track * 16 + logical) * 256
    sector_bytes = disk_data[file_offset:file_offset + 256]
    first_bytes = ' '.join(f'{b:02X}' for b in sector_bytes[:8])
    is_zero = all(b == 0 for b in sector_bytes)

    role = "(unused / file-system area)"
    final_apple = "—"

    # Track 0: boot loader and disk routines
    if track == 0:
        if phys == 0:
            role = "**Boot stub** (sector 0). Loaded by Disk II P6 PROM."
            final_apple = "Apple `$0800-$08FF`"
        elif phys in (0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E):
            # Even sectors loaded by boot stub in CP/M skew order
            order = [0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E].index(phys)
            target = 0x0A00 + order * 0x100
            role = f"Boot stub iteration {order+1} (CP/M skew). 6502 disk routines area."
            final_apple = f"Apple `${target:04X}-${target+0xFF:04X}`"
        elif phys in (0x01, 0x03, 0x05):
            # Odd sectors loaded by boot stub
            order = [0x01, 0x03, 0x05].index(phys) + 7
            target = 0x0A00 + order * 0x100
            role = f"Boot stub iteration {order+1} (CP/M skew). Stage-2 loader."
            final_apple = f"Apple `${target:04X}-${target+0xFF:04X}`"
        elif phys in (0x07, 0x09):
            role = "Not loaded by boot stub. Tail of stage-2 area."
            final_apple = "(not loaded)"
        elif phys == 0x0B:
            role = "**LOAD_CPM call 1, sector 0**. CCP/BDOS staging starts here."
            final_apple = "Apple `$8000-$80FF` (then via PREP_HANDOFF #3 -> `$A300-$A3FF`)"
        elif phys in (0x0C, 0x0D, 0x0E, 0x0F):
            order = phys - 0x0B
            staging = 0x8000 + order * 0x100
            role = f"LOAD_CPM call 1, sector {order+1}. CCP/BDOS staging."
            final_apple = f"Apple `${staging:04X}-${staging+0xFF:04X}` -> `${0xA300+order*0x100:04X}` after PREP_HANDOFF #3"

    elif track == 1:
        # All 16 sectors of track 1 are LOAD_CPM call 1, positions 5-20
        order = 5 + phys
        staging = 0x8000 + order * 0x100
        role = f"LOAD_CPM call 1, sector {order+1}. CCP/BDOS or BIOS-first-half staging."
        # Determine final destination
        if order < 23:
            # First 23 pages -> $A300-$B9FF
            final_addr = 0xA300 + order * 0x100
            role += " (CCP+BDOS area)"
            final_apple = f"Apple `${staging:04X}-${staging+0xFF:04X}` -> `${final_addr:04X}`"
        else:
            # Last 6 pages -> $0A00-$0FFF
            offset_in_last_six = order - 23
            final_addr = 0x0A00 + offset_in_last_six * 0x100
            role += " (Z-80 callbacks + BIOS first 1 KB)"
            final_apple = f"Apple `${staging:04X}-${staging+0xFF:04X}` -> `${final_addr:04X}`"

    elif track == 2:
        if phys < 8:
            # Track 2 sectors 0-7 are LOAD_CPM call 1, positions 21-28
            order = 21 + phys
            staging = 0x8000 + order * 0x100
            if order < 23:
                final_addr = 0xA300 + order * 0x100
                role = f"LOAD_CPM call 1, sector {order+1}. End of CCP/BDOS staging."
                final_apple = f"Apple `${staging:04X}-${staging+0xFF:04X}` -> `${final_addr:04X}`"
            else:
                # last 6 pages
                offset_in_last_six = order - 23
                final_addr = 0x0A00 + offset_in_last_six * 0x100
                role = f"LOAD_CPM call 1, sector {order+1}. Z-80 callbacks + BIOS first 1 KB."
                final_apple = f"Apple `${staging:04X}-${staging+0xFF:04X}` -> `${final_addr:04X}`"
        elif phys in (0x08, 0x09, 0x0A, 0x0B):
            order = phys - 0x08
            role = f"**Empty (zeros).** Originally would have been BIOS second half — but is runtime-generated, so disk has zeros."
            final_apple = f"(if loaded would be BIOS `${0xFEB8 + order * 0x100:04X}-${0xFEB8 + order * 0x100 + 0xFF:04X}` — but isn't)"
        else:  # phys $0C-$0F
            role = "Not loaded. May be loaded by second LOAD_CPM call (post-handoff)."
            final_apple = "(deferred / not loaded by stage-2)"

    else:
        # Tracks 3-34: CP/M filesystem area
        role = "CP/M filesystem area (after CP/M directory track)."
        final_apple = "(not loaded by boot — accessible via CP/M file ops once running)"

    return first_bytes, role, final_apple, is_zero


def main():
    with open('e:/Orchard/CPMV233.DSK', 'rb') as f:
        disk = f.read()

    print("# CP/M 2.23 Disk-Sector Map")
    print()
    print("This is a comprehensive map of every physical sector in the 140 KB CP/M 2.23")
    print("disk image (`CPMV233.DSK`). For each sector, the table shows the first 8")
    print("bytes (a quick signature), what role the sector plays in the boot sequence,")
    print("and where the bytes end up in Apple memory after the loader runs.")
    print()
    print("**Format**: `track:sector` is a physical (T,S) coordinate. The .DSK file")
    print("stores sectors in DOS 3.3 logical order, so the file offset for physical")
    print("sector `(T,S)` is `(T*16 + DOS33_INTERLEAVE[S]) * 256`.")
    print()
    print("| Trk:Sec | First 8 bytes | Role | Final Apple address |")
    print("|---------|---------------|------|---------------------|")

    for track in range(35):
        for phys in range(16):
            first, role, final, is_zero = classify_sector(track, phys, disk, DOS33_INTERLEAVE)
            zero_marker = " (zeros)" if is_zero else ""
            print(f"| `{track:2d}:${phys:X}` | `{first}`{zero_marker} | {role} | {final} |")
        # Visual separator between tracks
        # print()


if __name__ == '__main__':
    main()
