"""
Side-by-side hex dump of corresponding BIOS routines from CP/M 2.20 and 2.23.

Both BIOSes are loaded into different Z-80 addresses, so to compare the
SAME routine, we resolve each routine's Z-80 address to a file offset:

  file_offset = jt_file_offset + (routine_z80_addr - jt_z80_addr)

This script dumps a byte-aligned side-by-side view of the four
console-related routines (CONST, CONIN, CONOUT, LIST) plus BOOT and WBOOT.
"""

# Each version: (file_path, jump_table_file_offset, jump_table_z80_addr)
V23 = ('e:/Orchard/softcard/cpm-investigation/bios_223.bin', 0x000, 0xFAB8)
V20 = ('e:/Orchard/softcard/cpm-investigation/bios_220.bin', 0x000, 0xDACC)

# (name, z80_addr_v23, z80_addr_v20, size_bytes)
ROUTINES = [
    # WBOOT covers from $FAB8/$DACC up to CONST
    ('WBOOT',  0xFAB8, 0xDACC, 0x58),  # 2.23: 88 bytes; 2.20: 60 bytes -- different!
    ('CONST',  0xFB10, 0xDB08, 0x0A),  # both 10 bytes
    ('CONIN',  0xFB1A, 0xDB12, 0x33),  # 2.23: 51, 2.20: 49
    ('CONOUT', 0xFB4D, 0xDB43, 0x23),  # both 35 bytes
    ('LIST',   0xFB70, 0xDB66, 0x0F),  # both 15 bytes
]


def load(path):
    with open(path, 'rb') as f:
        return f.read()


def slice_routine(buf, jt_off, jt_addr, target_addr, size):
    file_off = jt_off + (target_addr - jt_addr)
    return buf[file_off:file_off + size]


def hexdump(b):
    return ' '.join(f'{x:02X}' for x in b)


def main():
    b23 = load(V23[0])
    b20 = load(V20[0])

    for name, addr23, addr20, size in ROUTINES:
        # Use the SIZE field; for routines of different size, dump the larger
        # length from each version separately
        size23 = size  # for v23 we use the listed (which is v23-correct)
        # For exact sizes per version, compute from address pairs in jump table.
        # For now, just use a fixed window that covers either size.
        dump23 = slice_routine(b23, V23[1], V23[2], addr23, size23)
        dump20 = slice_routine(b20, V20[1], V20[2], addr20, size23)

        print(f"=== {name} ===")
        print(f"  2.23 @ ${addr23:04X} ({size23} bytes):")
        # 16 bytes per row
        for off in range(0, len(dump23), 16):
            row = dump23[off:off + 16]
            print(f"    {addr23 + off:04X}: {hexdump(row)}")
        print(f"  2.20 @ ${addr20:04X} ({size23} bytes):")
        for off in range(0, len(dump20), 16):
            row = dump20[off:off + 16]
            print(f"    {addr20 + off:04X}: {hexdump(row)}")

        # Quick diff: count bytes that match
        matches = sum(1 for a, b in zip(dump23, dump20) if a == b)
        print(f"  Identical bytes (same offset): {matches}/{size23}")
        print()


if __name__ == '__main__':
    main()
