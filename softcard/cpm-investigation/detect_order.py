"""
Determine actual sector ordering by trying all combinations and counting
how many sectors are byte-identical between 2.20 and 2.23 system tracks.

Also try CP/M-order (the skew baked into the boot stub).
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

# CP/M skew from the boot stub at $082D-$083C
CPM_SKEW = [0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE,
            0x1, 0x3, 0x5, 0x7, 0x9, 0xB, 0xD, 0xF]

# "Physical" / no-interleave (file order = physical)
NONE = list(range(16))

ORDERS = {
    'DOS33':  DOS33_INTERLEAVE,
    'ProDOS': PRODOS_INTERLEAVE,
    'CPM':    CPM_SKEW,
    'phys':   NONE,
}


def load(path, interleave):
    with open(path, 'rb') as f:
        data = f.read()
    sectors = {}
    for track in range(35):
        for phys in range(16):
            logical = interleave[phys]
            offset = (track * 16 + logical) * 256
            sectors[(track, phys)] = data[offset:offset + 256]
    return sectors


def count_identical(a, b, max_track=3):
    same = 0
    total = 0
    for t in range(max_track):
        for s in range(16):
            total += 1
            if a[(t, s)] == b[(t, s)]:
                same += 1
    return same, total


def main():
    paths = {
        '223': 'e:/Orchard/softcard/disks/CPMV233.DSK',
        '220': 'e:/Orchard/softcard/disks/CPM220Disk1.po',
    }
    print(f"Identical-sector counts in tracks 0-2 (out of 48 total):")
    print(f"  {'223 order':>10}  {'220 order':>10}  {'identical':>10}")
    print('-' * 36)
    for n223, i223 in ORDERS.items():
        for n220, i220 in ORDERS.items():
            a = load(paths['223'], i223)
            b = load(paths['220'], i220)
            same, total = count_identical(a, b, max_track=3)
            mark = ' <-- HIGH MATCH' if same > 5 else ''
            print(f"  {n223:>10}  {n220:>10}  {same:>5}/{total}{mark}")


if __name__ == '__main__':
    main()
