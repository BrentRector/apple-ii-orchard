"""
Extract BIOS bytes from each CP/M image starting at the jump table,
print the jump table with standard CP/M 2.2 entry-point names, and
save the BIOS region to a binary for disassembly.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

# Standard CP/M 2.2 BIOS jump table entries
BIOS_ENTRIES = [
    'BOOT',    'WBOOT',  'CONST',  'CONIN',
    'CONOUT',  'LIST',   'PUNCH',  'READER',
    'HOME',    'SELDSK', 'SETTRK', 'SETSEC',
    'SETDMA',  'READ',   'WRITE',  'LISTST',
    'SECTRAN',
]


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


def show_jump_table(buf, offset, expected_count):
    print(f"  Jump table at file offset {offset:#06X}:")
    for i in range(expected_count):
        base = offset + i * 3
        if base + 2 >= len(buf):
            break
        op = buf[base]
        target = (buf[base + 2] << 8) | buf[base + 1]
        name = BIOS_ENTRIES[i] if i < len(BIOS_ENTRIES) else f'?{i}'
        marker = ' ' if op == 0xC3 else '!'  # ! = not a JMP
        print(f"    [{i:2d}] {name:8s}  {marker} C3 {buf[base+1]:02X} {buf[base+2]:02X}  -> ${target:04X}")


def main():
    cases = [
        ('2.23', 'e:/Orchard/cpm-80/disks/CPMV233.DSK',    0x02400),  # physical-order offset
        ('2.20', 'e:/Orchard/cpm-80/disks/CPM220Disk1.po', 0x02200),
    ]

    extracted = {}
    for label, path, offset in cases:
        print(f"\n=== {label}: {path} ===")
        buf = reconstruct_physical(path)
        # Show jump table; print 17 to see if anything beyond 15 looks like a JMP
        show_jump_table(buf, offset, 17)

        # Extract a generous chunk for disassembly: from jump table for 2 KB
        # (BIOS is typically ~1-2 KB)
        chunk = buf[offset:offset + 0x800]
        out_path = f'e:/Orchard/cpm-80/cpm-investigation/bios_{label.replace(".","")}.bin'
        with open(out_path, 'wb') as f:
            f.write(chunk)
        print(f"  Wrote {out_path} ({len(chunk)} bytes)")
        extracted[label] = (chunk, offset)

    # Quick byte-level diff of the two BIOS chunks (aligned by jump table start)
    a = extracted['2.23'][0]
    b = extracted['2.20'][0]
    n = min(len(a), len(b))
    diffs = [i for i in range(n) if a[i] != b[i]]
    print(f"\n2 KB starting at jump table — byte differences: {len(diffs)}/{n}")
    print(f"First 20 diff offsets: {[hex(d) for d in diffs[:20]]}")


if __name__ == '__main__':
    main()
