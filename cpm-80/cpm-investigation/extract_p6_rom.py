"""Extract the Disk II P6 PROM bytes from docs/DiskII_BootROM.asm into a 256-byte ROM image."""
import re
import os

data = bytearray(256)
pat = re.compile(r'C6([0-9A-Fa-f]{2}):\s*((?:[0-9A-Fa-f]{2}\s+){1,4})')

with open('apple-ii/docs/DiskII_BootROM.asm') as f:
    for line in f:
        m = pat.search(line)
        if not m:
            continue
        off = int(m.group(1), 16)
        for i, bs in enumerate(m.group(2).split()):
            if off + i < 256:
                data[off + i] = int(bs, 16)

nz = sum(1 for b in data if b != 0)
print(f'Extracted {nz}/256 non-zero bytes')

A, X = 0, 0
for b in data:
    s = A + b
    if s > 0xFF:
        X += 1
    A = s & 0xFF
print(f'Checksum: A=${A:02X}, X=${X:02X}')

os.makedirs('cpm-80/cpm-investigation/roms', exist_ok=True)
with open('cpm-80/cpm-investigation/roms/disk2_p6.bin', 'wb') as f:
    f.write(bytes(data))
print('Saved to cpm-investigation/roms/disk2_p6.bin')
