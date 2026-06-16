"""
Search a flat 140K Apple II image for the CP/M BIOS jump table.

The CP/M 2.x BIOS begins with 17 consecutive Z-80 JMP instructions:
  C3 lo hi  (BOOT)
  C3 lo hi  (WBOOT)
  C3 lo hi  (CONST)
  ... 14 more
That's 51 bytes of pattern: C3 ?? ?? C3 ?? ?? × 17.

The targets should mostly be in ascending order within a small range
(the BIOS lives in a contiguous block, typically < 4 KB).

Note: we search the raw file bytes — the on-disk byte sequence for any
contiguous Z-80 code is preserved regardless of which sector it lands
in (interleave shuffles WHICH sector contains a given byte but doesn't
change the bytes themselves WITHIN a sector).

Caveat: if the BIOS straddles a sector boundary, the jump table could
be split across two non-adjacent file offsets (because of interleave).
We handle this by also searching a "physical-order" reconstruction.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE


def reconstruct_physical(path):
    """Read the file and reconstruct the physical-sector byte stream:
    track 0 phys-sector 0, phys-sector 1, ..., phys-sector F, then track 1 ..."""
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


def find_jump_table(buf, min_jumps=8):
    """Find positions where N or more consecutive C3 jumps occur."""
    hits = []
    i = 0
    n = len(buf)
    while i < n - 3:
        if buf[i] == 0xC3:
            # Count consecutive jumps from here
            j = i
            count = 0
            targets = []
            while j < n - 2 and buf[j] == 0xC3:
                lo = buf[j + 1]
                hi = buf[j + 2]
                targets.append((hi << 8) | lo)
                count += 1
                j += 3
            if count >= min_jumps:
                hits.append((i, count, targets))
                i = j
            else:
                i += 1
        else:
            i += 1
    return hits


def describe_hit(name, offset, count, targets):
    # Heuristics: BIOS jump table targets should mostly be in a tight range
    if not targets:
        return f"  offset {offset:#06X}: {count} jumps"
    lo, hi = min(targets), max(targets)
    spread = hi - lo
    asc = sum(1 for k in range(1, len(targets)) if targets[k] >= targets[k-1])
    print(f"  offset {offset:>6} ({offset:#07X}): {count} jumps, "
          f"targets ${lo:04X}..${hi:04X} (spread ${spread:04X}), "
          f"{asc}/{len(targets)-1} ascending")
    if count >= 16:
        print(f"    targets: " + ' '.join(f'${t:04X}' for t in targets[:17]))


def main():
    for path in ['e:/Orchard/softcard/disks/CPMV223-44K.DSK',
                 'e:/Orchard/softcard/disks/CPMV220-Disk1.po']:
        print(f"\n=== {path} ===")
        # Search both raw file order and physical-reconstructed order
        with open(path, 'rb') as f:
            raw = f.read()
        phys = reconstruct_physical(path)

        print("[raw file order]")
        hits = find_jump_table(raw, min_jumps=8)
        for offset, count, targets in hits:
            describe_hit(path, offset, count, targets)

        print("[physical-sector order]")
        hits = find_jump_table(phys, min_jumps=8)
        for offset, count, targets in hits:
            describe_hit(path, offset, count, targets)


if __name__ == '__main__':
    main()
