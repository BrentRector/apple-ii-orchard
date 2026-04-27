"""
Test whether the BIOS bytes are contiguously laid out in our reconstructed
file image (in which case file_offset = jt_offset + (z80_addr - jt_addr)),
or whether the loader scatters sectors differently.

Test: find both jump tables (the duplicates) for 2.20, compute distances
between corresponding entries' file offsets, and see if the layout is
consistent.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE


def reconstruct_physical(path):
    p = Path(path)
    with open(p, 'rb') as f:
        data = f.read()
    interleave = PRODOS_INTERLEAVE if p.suffix.lower() == '.po' else DOS33_INTERLEAVE
    out = bytearray()
    for track in range(35):
        for phys in range(16):
            logical = interleave[phys]
            offset = (track * 16 + logical) * 256
            out.extend(data[offset:offset + 256])
    return bytes(out)


def find_pattern(buf, pattern):
    """Find all positions of an exact pattern."""
    hits = []
    i = 0
    while True:
        i = buf.find(pattern, i)
        if i < 0:
            break
        hits.append(i)
        i += 1
    return hits


def main():
    # 2.20 BIOS jump table starts with: C3 A8 DE C3 CC DA C3 08 DB
    # (BOOT->$DEA8, WBOOT->$DACC, CONST->$DB08)
    pattern = bytes.fromhex('C3A8DE C3CCDA C3 08 DB'.replace(' ', ''))
    print(f"Pattern (10 bytes): {pattern.hex()}")

    # Check raw and physical-reconstructed
    with open('e:/Orchard/CPM220Disk1.po', 'rb') as f:
        raw = f.read()
    phys = reconstruct_physical('e:/Orchard/CPM220Disk1.po')

    print("\n2.20 jump-table pattern in RAW file:")
    for h in find_pattern(raw, pattern):
        print(f"  offset {h:#06X}")

    print("\n2.20 jump-table pattern in PHYSICAL-order:")
    for h in find_pattern(phys, pattern):
        print(f"  offset {h:#06X}")

    # Now look at the bytes at +$3DC from each (where BOOT@$DEA8 should be)
    print("\nBytes at offset+$3DC (where BOOT @ $DEA8 should land if contiguous):")
    for label, buf in [('raw', raw), ('phys', phys)]:
        for h in find_pattern(buf, pattern):
            target_off = h + 0x3DC
            sample = buf[target_off:target_off + 16]
            print(f"  {label} offset {h:#06X} + $3DC = {target_off:#06X}: " +
                  ' '.join(f'{b:02X}' for b in sample))

    # Same for 2.23
    print("\n--- 2.23 ---")
    # 2.23 jump table starts: C3 D1 FE C3 B8 FA C3 10 FB
    pattern23 = bytes.fromhex('C3D1FE C3B8FA C3 10 FB'.replace(' ', ''))
    with open('e:/Orchard/CPMV233.DSK', 'rb') as f:
        raw23 = f.read()
    phys23 = reconstruct_physical('e:/Orchard/CPMV233.DSK')

    print("\n2.23 jump-table pattern in RAW file:")
    for h in find_pattern(raw23, pattern23):
        print(f"  offset {h:#06X}")
    print("\n2.23 jump-table pattern in PHYSICAL-order:")
    for h in find_pattern(phys23, pattern23):
        print(f"  offset {h:#06X}")

    print("\nBytes at offset+$419 (where BOOT @ $FED1 should land if contiguous):")
    for label, buf in [('raw', raw23), ('phys', phys23)]:
        for h in find_pattern(buf, pattern23):
            target_off = h + 0x419
            sample = buf[target_off:target_off + 16]
            print(f"  {label} offset {h:#06X} + $419 = {target_off:#06X}: " +
                  ' '.join(f'{b:02X}' for b in sample))


if __name__ == '__main__':
    main()
