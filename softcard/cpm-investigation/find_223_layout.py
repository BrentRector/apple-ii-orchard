"""
2.23 .DSK file's sector ordering is unknown. Find the BIOS by:
1. Extracting each sector by every interleave
2. For each, look for the jump table pattern
3. Check whether the bytes after the jump table form valid contiguous BIOS

Key signature: code that references the BIOS load range $FA00-$FFFF should
contain bytes like '?? FA' or '?? FB' or '?? FC' or '?? FE' or '?? FF' as
the high byte of CALL/JP/LD addresses.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

CPM_SKEW = [0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE,
            0x1, 0x3, 0x5, 0x7, 0x9, 0xB, 0xD, 0xF]
NONE = list(range(16))

# Possible interpretations: file is stored in <name> order; to get
# physical sector P, look at offset (T*16 + interleave[P]) * 256.
# For RAW (file is already in CP/M-loader-order), use NONE.
ORDERINGS = {
    'raw-as-physical':         NONE,   # file order = physical sector order
    'as-DOS33':                DOS33_INTERLEAVE,
    'as-ProDOS':               PRODOS_INTERLEAVE,
    'as-CPM':                  CPM_SKEW,
}

# Also reverse interleaves: file sector N is a specific PHYSICAL sector
# (whose physical number is N in some skew). Interleave maps phys->logical;
# for file=logical-order, given physical we look at logical = interleave[physical].
# But maybe the file is stored in PHYSICAL order. Or in CP/M's read order.

JUMP_TABLE_223 = bytes.fromhex('C3D1FE C3B8FA C310FB'.replace(' ', ''))


def reconstruct(path, interleave):
    """Read file and rebuild as a flat physical-order byte stream."""
    with open(path, 'rb') as f:
        data = f.read()
    out = bytearray()
    for track in range(35):
        for phys in range(16):
            logical = interleave[phys]
            offset = (track * 16 + logical) * 256
            out.extend(data[offset:offset + 256])
    return bytes(out)


def reconstruct_cpm_load_order(path, interleave):
    """Rebuild file in the order the SoftCard loader reads it:
       physical sectors visited in CPM_SKEW order (0,2,4,...,1,3,5,...).
       Uses 'interleave' to convert physical->file-offset."""
    with open(path, 'rb') as f:
        data = f.read()
    out = bytearray()
    for track in range(35):
        for phys in CPM_SKEW:
            logical = interleave[phys]
            offset = (track * 16 + logical) * 256
            out.extend(data[offset:offset + 256])
    return bytes(out)


def looks_like_bios_at(buf, jt_offset, jt_addr):
    """Score the likelihood that valid BIOS code starts at jt_offset
    by counting bytes in the next 1KB that look like BIOS-range refs."""
    after = buf[jt_offset + 45 : jt_offset + 45 + 1024]
    bios_high = {0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF}
    score = sum(1 for b in after if b in bios_high)
    return score


def main():
    path = 'e:/Orchard/softcard/disks/CPMV233.DSK'
    print(f"Searching {path} for valid BIOS layout...\n")

    print(f"{'Interpretation':>30}  {'jt offset':>10}  {'BIOS-high bytes/1KB':>20}")
    print('-' * 65)

    candidates = []

    # First: raw file (no reconstruction)
    with open(path, 'rb') as f:
        raw = f.read()
    for jt in [i for i in range(len(raw) - 9) if raw[i:i+9] == JUMP_TABLE_223]:
        score = looks_like_bios_at(raw, jt, 0xFAB8)
        candidates.append(('raw', jt, score))
        print(f"  {'raw file':>30}  {jt:>#10x}  {score:>20}")

    # Reconstructions
    for name, interleave in ORDERINGS.items():
        buf = reconstruct(path, interleave)
        for jt in [i for i in range(len(buf) - 9) if buf[i:i+9] == JUMP_TABLE_223]:
            score = looks_like_bios_at(buf, jt, 0xFAB8)
            candidates.append((name, jt, score))
            print(f"  {name:>30}  {jt:>#10x}  {score:>20}")

    # CP/M load-order reconstructions
    for name, interleave in ORDERINGS.items():
        buf = reconstruct_cpm_load_order(path, interleave)
        cpmname = f'CPM-load via {name}'
        for jt in [i for i in range(len(buf) - 9) if buf[i:i+9] == JUMP_TABLE_223]:
            score = looks_like_bios_at(buf, jt, 0xFAB8)
            candidates.append((cpmname, jt, score))
            print(f"  {cpmname:>30}  {jt:>#10x}  {score:>20}")

    # Best candidate
    if candidates:
        best = max(candidates, key=lambda x: x[2])
        print(f"\nBest candidate: {best[0]} at offset {best[1]:#x} (score {best[2]})")

        # Dump first 32 bytes after the table
        if best[0] == 'raw':
            buf = raw
        elif best[0].startswith('CPM-load via '):
            ord_name = best[0].replace('CPM-load via ', '')
            buf = reconstruct_cpm_load_order(path, ORDERINGS[ord_name])
        else:
            buf = reconstruct(path, ORDERINGS[best[0]])

        sample = buf[best[1] + 45 : best[1] + 45 + 64]
        print(f"\nBytes after jump table (offset {best[1]+45:#x}):")
        for off in range(0, len(sample), 16):
            row = sample[off:off+16]
            print(f"  {best[1]+45+off:#06x}: " + ' '.join(f'{b:02X}' for b in row))


if __name__ == '__main__':
    main()
