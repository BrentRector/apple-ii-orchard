"""
Build the Apple II memory image of the 6502 boot loader as it exists
after the boot stub finishes loading track 0.

The boot stub loads:
  physical sector  0 -> $0800 (boot stub itself, loaded by P6 ROM)
  physical sector  2 -> $0A00
  physical sector  4 -> $0B00
  physical sector  6 -> $0C00
  physical sector  8 -> $0D00
  physical sector  A -> $0E00
  physical sector  C -> $0F00
  physical sector  E -> $1000   <-- JMP $1000 transfers control here
  physical sector  1 -> $1100
  physical sector  3 -> $1200
  physical sector  5 -> $1300

Sectors 7, 9, B, D, F of track 0 are NOT loaded by the boot stub. They may
be loaded later by the stage-2 loader or be unused.

Output: a 2 KB binary covering Apple II RAM $0800-$13FF.
File "image" is sparse — sectors not loaded are filled with $00.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

# (apple2_addr, physical_sector) for each sector loaded by the boot stub.
# Boot stub itself loads sector 0 to $0800, then proceeds with the rest.
LOAD_MAP = [
    (0x0800, 0x0),
    (0x0A00, 0x2),
    (0x0B00, 0x4),
    (0x0C00, 0x6),
    (0x0D00, 0x8),
    (0x0E00, 0xA),
    (0x0F00, 0xC),
    (0x1000, 0xE),
    (0x1100, 0x1),
    (0x1200, 0x3),
    (0x1300, 0x5),
]


def build_image(path):
    p = Path(path)
    with open(p, 'rb') as f:
        data = f.read()
    interleave = PRODOS_INTERLEAVE if p.suffix.lower() == '.po' else DOS33_INTERLEAVE
    # Apple II memory $0800..$13FF
    img = bytearray(0x1400 - 0x0800)  # 0xC00 = 3072 bytes
    for addr, phys in LOAD_MAP:
        logical = interleave[phys]
        offset = (0 * 16 + logical) * 256  # track 0
        sector = data[offset:offset + 256]
        img_off = addr - 0x0800
        img[img_off:img_off + 256] = sector
    return bytes(img)


def main():
    cases = [
        ('223', 'e:/Orchard/softcard/reference/softcard-cpm-archive/os/softcard-cpm2.23-44k-system.dsk'),
        ('220', 'e:/Orchard/softcard/reference/softcard-cpm-archive/os/softcard-cpm2.20b-56k-system-disk1.po'),
    ]
    for label, path in cases:
        img = build_image(path)
        out_path = f'e:/Orchard/softcard/cpm-investigation/loader_{label}.bin'
        with open(out_path, 'wb') as f:
            f.write(img)
        print(f"Wrote {out_path} ({len(img)} bytes)")
        # Quick first-bytes confirmation: should start with the boot stub
        print(f"  First 16 bytes (boot sector @ $0800): " +
              ' '.join(f'{b:02X}' for b in img[:16]))
        # Bytes at $1000 (entry point after boot stub):
        v1000 = img[0x1000 - 0x0800: 0x1000 - 0x0800 + 16]
        print(f"  Bytes at $1000 (entry):              " +
              ' '.join(f'{b:02X}' for b in v1000))


if __name__ == '__main__':
    main()
