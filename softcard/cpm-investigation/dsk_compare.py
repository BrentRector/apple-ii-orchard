"""
Read .dsk (DOS-order) and .po (ProDOS-order) Apple II disk images and
expose them as a uniform "physical sector" view, then diff multiple images
sector-by-sector.

The boot stub in all three CP/M images reads physical sectors directly,
so to compare across formats we must normalize to physical-sector order.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE


def load_physical(path):
    """Return a dict {(track, phys_sector): bytes} for a 140K image."""
    p = Path(path)
    with open(p, 'rb') as f:
        data = f.read()
    if len(data) != 143360:
        raise ValueError(f"Unexpected size {len(data)} for {p.name}")

    interleave = PRODOS_INTERLEAVE if p.suffix.lower() == '.po' else DOS33_INTERLEAVE

    sectors = {}
    for track in range(35):
        for phys in range(16):
            logical = interleave[phys]
            offset = (track * 16 + logical) * 256
            sectors[(track, phys)] = data[offset:offset + 256]
    return sectors


def byte_diff_count(a, b):
    return sum(1 for x, y in zip(a, b) if x != y)


def diff_summary(images, max_track=5):
    a_name, b_name = list(images.keys())[:2]
    a, b = images[a_name], images[b_name]
    print(f"Comparing {a_name} vs {b_name}\n")
    print(f"  {'Track':>5}  {'PhysSec':>7}  {'Diff':>5}  {a_name+' first 8':>28}  {b_name+' first 8':>28}")
    print('-' * 88)

    for track in range(max_track):
        for phys in range(16):
            sa, sb = a[(track, phys)], b[(track, phys)]
            d = byte_diff_count(sa, sb)
            fa = ' '.join(f'{x:02X}' for x in sa[:8])
            fb = ' '.join(f'{x:02X}' for x in sb[:8])
            marker = ' ' if d == 0 else ('.' if d < 16 else ('o' if d < 64 else 'X'))
            print(f"  {track:>5}  {phys:>7X}  {d:>4d}{marker}  {fa:>28}  {fb:>28}")
        print()


def main():
    images = {
        '223':    load_physical('e:/Orchard/softcard/CPMV223-44K/CPMV223-44K.DSK'),
        '220-d1': load_physical('e:/Orchard/softcard/CPMV220/CPMV220-Disk1.po'),
    }
    diff_summary(images, max_track=3)

    # Also: confirm 220 d1 vs d2 are identical for system area
    d1 = load_physical('e:/Orchard/softcard/CPMV220/CPMV220-Disk1.po')
    d2 = load_physical('e:/Orchard/softcard/CPMV220/CPMV220-Disk2.po')
    print("\n2.20 disk 1 vs disk 2 (system area):")
    for t in range(3):
        for s in range(16):
            d = byte_diff_count(d1[(t,s)], d2[(t,s)])
            if d:
                print(f"  Track {t} sector {s:X}: {d} bytes differ")
    print("  (no output above = identical)")


if __name__ == '__main__':
    main()
