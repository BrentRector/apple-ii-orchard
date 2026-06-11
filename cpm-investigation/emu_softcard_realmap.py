"""
Real-map SoftCard boot experiment: run the Z-80 from reset ($0000) under
the *documented* Microsoft SoftCard address translation instead of the
bit-12-XOR model used by emu_softcard_full.py.

The documented SoftCard map (SoftCard manual, "Memory Map" section):

    Z-80 address     Apple address    Note
    $0000-$AFFF  ->  $1000-$BFFF      +$1000 (TPA gets contiguous RAM)
    $B000-$DFFF  ->  $D000-$FFFF      +$2000 (language-card region)
    $E000-$EFFF  ->  $C000-$CFFF      I/O page + slot ROM space
    $F000-$FFFF  ->  $0000-$0FFF      -$F000 (Apple zero page, stack,
                                      text screen, and pages 8-15)

Consequences this experiment tests:
  * Z-80 $F3B8-$F3BF == Apple $03B8-$03BF -- the slot scanner's device
    code table needs NO copy to be visible to the BIOS device scan.
  * Z-80 $FA00-$FFFF == Apple $0A00-$0FFF -- the BIOS lives where
    PREP_HANDOFF staged it; no LC-RAM load needed.
  * The Z-80 reset vector JP $FA00 lands on the BIOS jump table's BOOT
    entry (JP $FED1) directly.

Instrumentation: full write attribution (which Z-80 PC wrote which Apple
address) for the staged BIOS region, the text page, the reset-vector
page, and all I/O-page accesses.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from emu_softcard_full import SoftCardSystem
from nibbler.z80_cpu import Z80CPU, Z80Halt


def realmap(z80_addr):
    """Documented SoftCard Z-80 -> Apple address translation."""
    if z80_addr < 0xB000:
        return z80_addr + 0x1000
    if z80_addr < 0xE000:
        return z80_addr + 0x2000
    if z80_addr < 0xF000:
        return z80_addr - 0x2000       # $E000-$EFFF -> $C000-$CFFF (I/O)
    return z80_addr - 0xF000           # $F000-$FFFF -> $0000-$0FFF


class RealMapRun:
    def __init__(self, dsk_path):
        # Reuse the existing, verified 6502 boot phase as-is.
        self.sys = SoftCardSystem(dsk_path)
        self.sys.setup_boot()
        r = self.sys.run(max_6502=20_000_000, max_z80=0, log_writes=False)
        self.boot_msg = r
        self.mem = self.sys.apple_mem

        self.z = Z80CPU()
        self.write_log = []       # (exec_count, z80_pc, apple_addr, val)
        self.io_log = []          # (exec_count, z80_pc, 'R'/'W', apple_addr, val)
        self.text_writes = []     # (exec_count, z80_pc, apple_addr, val)

        def rd(addr, _v):
            ap = realmap(addr)
            if 0xC000 <= ap <= 0xC0FF and len(self.io_log) < 4000:
                self.io_log.append((self.z.exec_count, self.z.pc, 'R', ap,
                                    self.mem[ap]))
            return self.mem[ap]

        def wr(addr, val):
            ap = realmap(addr)
            if 0xC000 <= ap <= 0xCFFF:
                # I/O space: log, don't store (slot ROM / softswitches).
                if len(self.io_log) < 4000:
                    self.io_log.append((self.z.exec_count, self.z.pc, 'W',
                                        ap, val))
                return True
            if 0x0400 <= ap <= 0x07FF:
                self.text_writes.append((self.z.exec_count, self.z.pc, ap, val))
            elif (0x0000 <= ap <= 0x0FFF or 0x1000 <= ap <= 0x1002) \
                    and len(self.write_log) < 20000:
                self.write_log.append((self.z.exec_count, self.z.pc, ap, val))
            self.mem[ap] = val
            return True

        self.z.read_hook = rd
        self.z.write_hook = wr
        self.z.pc = 0x0000     # true Z-80 reset
        self.z.sp = 0x0000

    def run(self, max_z80=5_000_000):
        try:
            res = self.z.run(max_instructions=max_z80, progress_interval=0)
        except Z80Halt as e:
            res = f"Z80Halt: {e}"
        except Exception as e:
            res = f"Z80 error: {e}"
        return res


def screen_text(mem):
    """Decode Apple 40-col text page 1 rows."""
    rows = []
    for row in range(24):
        base = 0x400 + (row % 8) * 0x80 + (row // 8) * 0x28
        chars = []
        for col in range(40):
            b = mem[base + col]
            c = b & 0x7F
            chars.append(chr(c) if 32 <= c < 127 else '.')
        line = ''.join(chars).rstrip('.')
        rows.append(line)
    return rows


def main():
    dsk = sys.argv[1] if len(sys.argv) > 1 else 'CPMV233.DSK'
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 5_000_000
    r = RealMapRun(dsk)
    print(r.boot_msg)
    res = r.run(max_z80=n)
    z = r.z
    print(f"Z-80: {res}")
    print(f"Z-80 end: PC=${z.pc:04X} SP=${z.sp:04X} "
          f"A=${z.a:02X} HL=${z.h:02X}{z.l:02X} exec={z.exec_count:,}")
    print()
    print(f"-- writes to Apple $0000-$0FFF / $1000-$1002: {len(r.write_log)}")
    for ec, pc, ap, val in r.write_log[:40]:
        print(f"   exec={ec:>9,}  Z80 PC=${pc:04X}  Apple ${ap:04X} = ${val:02X}")
    if len(r.write_log) > 40:
        print(f"   ... and {len(r.write_log)-40} more")
    print()
    print(f"-- I/O page accesses: {len(r.io_log)}")
    seen = set()
    for ec, pc, kind, ap, val in r.io_log:
        key = (pc, kind, ap)
        if key in seen:
            continue
        seen.add(key)
        print(f"   exec={ec:>9,}  Z80 PC=${pc:04X}  {kind} Apple ${ap:04X}"
              f"  val=${val:02X}")
        if len(seen) >= 30:
            break
    print()
    print(f"-- text page writes: {len(r.text_writes)}")
    for ec, pc, ap, val in r.text_writes[:20]:
        c = val & 0x7F
        ch = chr(c) if 32 <= c < 127 else '?'
        print(f"   exec={ec:>9,}  Z80 PC=${pc:04X}  Apple ${ap:04X} = ${val:02X} '{ch}'")
    print()
    print("-- screen:")
    for line in screen_text(r.mem):
        print(f"   |{line}")
    print()
    print("-- Z-80 $0000-$0002 (Apple $1000-$1002):",
          ' '.join(f"{r.mem[a]:02X}" for a in range(0x1000, 0x1003)))


if __name__ == '__main__':
    main()
