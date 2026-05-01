"""
Stage-2 SoftCard CP/M boot emulator: 6502 + Z-80 + SoftCard memory mapping.

Models:
  - 64K Apple memory (shared by both CPUs)
  - 6502 (via nibbler.cpu.CPU6502) sees Apple addresses directly
  - Z-80 (via nibbler.z80_cpu.Z80CPU) sees Apple memory through the
    SoftCard's bit-12 XOR for low addresses ($0000-$0FFF and $1000-$1FFF
    swap), straight-through for $2000+
  - CPU-switch flip-flop modelled at $C0BF (a guess; documented variant)

The CPU switch fires at $13CC: JSR $0E36. The 6502 attempts to execute
Z-80 callback bytes at $0E36 -- in our model we intercept and switch to
Z-80 execution at the equivalent Z-80 address.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from nibbler.cpu import CPU6502
from nibbler.z80_cpu import Z80CPU, Z80Halt
from nibbler.dsk_disk import DSKDisk
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE


def softcard_xor(z80_addr):
    """Map Z-80 address to Apple address.

    The standard SoftCard mapping flips bit 12 for any address < $2000:
      Z-80 $0000-$0FFF  <->  Apple $1000-$1FFF
      Z-80 $1000-$1FFF  <->  Apple $0000-$0FFF
      Z-80 $2000-$FFFF  ->   Apple $2000-$FFFF (unchanged)

    Some SoftCard documentation extends this to $0000-$AFFF; the standard
    implementation is the more limited bit-12-XOR-on-low-2K-pair behavior.
    """
    if z80_addr < 0x2000:
        return z80_addr ^ 0x1000
    return z80_addr


class SoftCardSystem:
    """Container for shared Apple memory + 6502 + Z-80 + active-CPU switch."""

    def __init__(self, dsk_path, *, slot=6, interleave='dos33', volume=254):
        if dsk_path.lower().endswith('.po'):
            interleave = 'prodos'
        il = PRODOS_INTERLEAVE if interleave == 'prodos' else DOS33_INTERLEAVE

        with open(dsk_path, 'rb') as f:
            self.dsk_bytes = f.read()
        self.interleave = il

        # Single shared 64K memory array. Both CPUs read/write through hooks.
        self.apple_mem = bytearray(65536)

        self.disk = DSKDisk(self.dsk_bytes, interleave=interleave, volume=volume)
        self.cpu6502 = CPU6502(slot=slot)
        self.cpu6502.disk = self.disk
        # Replace cpu6502.mem with our shared array via a thin proxy.
        self.cpu6502.mem = self.apple_mem

        self.cpu_z80 = Z80CPU()
        # Z-80 reads/writes go through SoftCard mapping.
        def z80_read(addr, _val):
            return self.apple_mem[softcard_xor(addr)]
        def z80_write(addr, val):
            self.apple_mem[softcard_xor(addr)] = val
            return True  # claim the write
        self.cpu_z80.read_hook = z80_read
        self.cpu_z80.write_hook = z80_write
        # Z-80 also has its own .mem array; keep it but unused.

        self.active = '6502'
        self.switch_count = 0
        self.write_log_z80 = []
        self.write_log_6502 = []

    def set_apple(self, addr, val):
        self.apple_mem[addr & 0xFFFF] = val & 0xFF

    def setup_boot(self, *, slot=6):
        """Set up the 6502 boot state (same as Stage-1 emu_softcard.py)."""
        # Standard P6 PROM post-state.
        self.apple_mem[0x0800:0x0900] = self.dsk_bytes[:256]
        # Apple monitor stubs.
        for addr in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                     0xFD8E, 0xFDED, 0xFD0C, 0xFF65, 0xFF4A, 0xFF3F):
            self.apple_mem[addr] = 0x60     # RTS
        # BRK/IRQ trap at $0002 = KIL.
        self.apple_mem[0xFFFE] = 0x02
        self.apple_mem[0xFFFF] = 0x00
        self.apple_mem[0x0002] = 0x02
        # Reset/NMI vectors.
        self.apple_mem[0xFFFC] = 0x00
        self.apple_mem[0xFFFD] = 0x08
        # Disk II PROM bytes in slot 6.
        rom_path = Path(__file__).resolve().parent / 'roms' / 'disk2_p6.bin'
        if rom_path.exists():
            rom_bytes = rom_path.read_bytes()
            slot_base = 0xC000 | (slot << 8)
            self.apple_mem[slot_base:slot_base + len(rom_bytes)] = rom_bytes

        # Videx Videoterm in slot 3 (if ROM is available). The Videx ROM
        # is 1024 bytes mapped at $C800-$CBFF (expansion ROM); the last
        # 256 bytes ($CB00-$CBFF) are also visible at $C300-$C3FF when
        # slot 3 is selected. We place both copies in flat memory; the
        # CFFF expansion-ROM-deselect softswitch is a no-op for our model.
        videx_path = Path('e:/a2fpga_core/hdl/videx/Videx Videoterm ROM 2.4.bin')
        if videx_path.exists():
            videx = videx_path.read_bytes()
            # Slot ROM at $C300-$C3FF: bytes 768-1023 of the image.
            self.apple_mem[0xC300:0xC400] = videx[768:1024]
            # Expansion ROM at $C800-$CBFF.
            self.apple_mem[0xC800:0xCC00] = videx[0:1024]

        # 6502 register state.
        self.cpu6502.pc = 0x0801
        self.cpu6502.x = slot * 16
        self.cpu6502.sp = 0xFD
        self.cpu6502.a = 0
        self.cpu6502.y = 0
        self.apple_mem[0x2B] = slot * 16
        self.apple_mem[0x26] = 0x00
        self.apple_mem[0x27] = 0x09
        self.apple_mem[0x3D] = 0x01
        self.disk.motor_on = True
        self.disk.current_qtrack = 0

        # P6 PROM hook at $C65C.
        def p6_hook(c):
            target_sector = c.mem[0x3D]
            dest_lo = c.mem[0x26]
            dest_hi = c.mem[0x27]
            dest = (dest_hi << 8) | dest_lo
            track = self.disk.current_qtrack // 4
            logical = self.interleave[target_sector]
            off = (track * 16 + logical) * 256
            sector_bytes = self.dsk_bytes[off:off + 256]
            for i, b in enumerate(sector_bytes):
                c.mem[(dest + i) & 0xFFFF] = b
            c.mem[0x27] = (c.mem[0x27] + 1) & 0xFF
            c.pc = 0x0801
            return False
        self.cpu6502.add_breakpoint(0xC000 | (slot << 8) | 0x5C, p6_hook)

        # Slot-scanner $3E patch (see emu_softcard.py for reasoning).
        # One-shot: fires at the FIRST LDA $3E in the scan loop. Sets $3E=0
        # so the first iteration takes SCAN_INIT_SLOT (incrementing $3E to 1);
        # subsequent iterations take SCAN_DO_PROBE normally.
        # Address differs between 2.20 ($1063) and 2.23 ($106A); install at both.
        fired = [False]
        def patch_3e(c):
            if not fired[0]:
                c.mem[0x3E] = 0
                fired[0] = True
            return False
        self.cpu6502.add_breakpoint(0x106A, patch_3e)
        self.cpu6502.add_breakpoint(0x1063, patch_3e)

        # CPU-switch trigger: when 6502 PC reaches $0E36. The warm-boot
        # routine at $03C0 ends with `JSR $0E36`, and the bytes at $0E36
        # are Z-80 instructions installed by PREP_HANDOFF #2 (they don't
        # parse as 6502). On real hardware, the SoftCard's CPU-switch
        # flip-flop triggers when 6502 attempts to execute these bytes;
        # in our emulator we install a PC breakpoint to model that.
        def cpu_switch(c):
            self.switch_count += 1
            target_apple = 0x0E36
            self.cpu_z80.pc = softcard_xor(target_apple)
            self.cpu_z80.sp = 0x0080
            self.active = 'z80'
            return True
        self.cpu6502.add_breakpoint(0x0E36, cpu_switch)

    def run(self, *, max_6502=10_000_000, max_z80=1_000_000, log_writes=True):
        """Run the boot until Z-80 takeover, then run Z-80 for max_z80 insns."""
        # Optionally install a write logger for both CPUs (limited, just logs
        # writes to BIOS region).
        if log_writes:
            self._install_z80_write_log()

        result6 = self.cpu6502.run(max_instructions=max_6502, progress_interval=0)
        if self.active != 'z80':
            return f"6502 stopped before switch: {result6} at PC=${self.cpu6502.pc:04X}"

        try:
            result_z = self.cpu_z80.run(max_instructions=max_z80,
                                        progress_interval=0)
        except Exception as e:
            result_z = f"Z80 error: {e}"
        return f"6502 ran {self.cpu6502.exec_count:,} insns; Z-80 ran {self.cpu_z80.exec_count:,} insns ({result_z})"

    def _install_z80_write_log(self):
        log = self.write_log_z80
        old_hook = self.cpu_z80.write_hook
        def hook(addr, val):
            apple_addr = softcard_xor(addr)
            # Only log writes to BIOS region.
            if 0xFA00 <= apple_addr <= 0xFFFF:
                log.append((self.cpu_z80.exec_count, self.cpu_z80.pc,
                            apple_addr, val))
            self.apple_mem[apple_addr] = val
            return True
        self.cpu_z80.write_hook = hook


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('disk', help='Path to .dsk or .po image')
    ap.add_argument('--max-6502', type=int, default=20_000_000)
    ap.add_argument('--max-z80', type=int, default=10_000_000)
    args = ap.parse_args()

    sys_ = SoftCardSystem(args.disk)
    sys_.setup_boot()
    msg = sys_.run(max_6502=args.max_6502, max_z80=args.max_z80)
    print(msg)
    print(f"Switch count: {sys_.switch_count}")
    print(f"Active CPU at end: {sys_.active}")
    print()
    print(f"Z-80 PC at end: ${sys_.cpu_z80.pc:04X}")
    print(f"Z-80 writes to BIOS area ($FA00-$FFFF): {len(sys_.write_log_z80)}")
    if sys_.write_log_z80:
        print("First 30 writes:")
        for ec, pc, addr, val in sys_.write_log_z80[:30]:
            print(f"  Z-80 exec={ec:>10,}  PC=${pc:04X}  ${addr:04X}=${val:02X}")
        print(f"  ... and {max(0, len(sys_.write_log_z80) - 30)} more")
    nz = sum(1 for b in sys_.apple_mem[0xFA00:0x10000] if b != 0)
    print(f"$FA00-$FFFF non-zero bytes after run: {nz} / 1536")


if __name__ == '__main__':
    main()
