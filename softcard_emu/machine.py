"""
SoftCardMachine: a Microsoft SoftCard CP/M system in one object.

Consolidates the cpm-investigation emulators (emu_softcard_full v1
boot harness + emu_softcard_v2 bidirectional machine) into a reusable
component, and adds an Apple language card so memory sizing matches
real hardware.

Both CPUs share one 64 KB Apple memory image. The Z-80 sees it through
the SoftCard's documented translation; the CPU switch is any access to
the SoftCard's slot page, from either side, with each core resuming
past its triggering instruction.
"""

import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from nibbler.cpu import CPU6502
from nibbler.z80_cpu import Z80CPU
from nibbler.dsk_disk import DSKDisk
from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

from .langcard import LanguageCard
from .videx import VidexVideoterm, find_videx_rom


def realmap(z80_addr):
    """Documented SoftCard Z-80 -> Apple address translation."""
    if z80_addr < 0xB000:
        return z80_addr + 0x1000
    if z80_addr < 0xE000:
        return z80_addr + 0x2000
    if z80_addr < 0xF000:
        return z80_addr - 0x2000
    return z80_addr - 0xF000


class Yield(Exception):
    """Raised inside a CPU hook to hand the bus to the other CPU."""


# Apple text page 1: row -> base address (the classic interleave)
def _text40_row_base(row):
    return 0x400 + (row % 8) * 0x80 + (row // 8) * 0x28


class SoftCardMachine:
    """Boot a SoftCard CP/M disk image and interact with it.

    Args:
        dsk_path: .dsk (DOS 3.3 order) or .po (ProDOS order) image.
        videx: install a Videx Videoterm in slot 3 (default True).
        language_card: model LC banking at $D000-$FFFF (default True);
            with it, CP/M sizes memory as on real hardware.
        sector_hook: service runtime disk reads straight from the image
            at the RWTS sector-read primitive (default True); False
            runs the preserved RWTS against synthetic nibble streams.
        c8_arbitrate: faithful $C800-$CFFF window arbitration with
            fault logging (default True); False = always-mapped window.
        videx_rom: explicit path to the 1 KB Videoterm firmware image.
        slot: Disk II controller slot (default 6).
    """

    def __init__(self, dsk_path, *, videx=True, language_card=True,
                 sector_hook=True, c8_arbitrate=True, videx_rom=None,
                 slot=6):
        dsk_path = str(dsk_path)
        interleave = 'prodos' if dsk_path.lower().endswith('.po') else 'dos33'
        self.interleave = (PRODOS_INTERLEAVE if interleave == 'prodos'
                           else DOS33_INTERLEAVE)
        with open(dsk_path, 'rb') as f:
            self.dsk_bytes = f.read()
        self.disk_image = bytearray(self.dsk_bytes)   # runtime-writable copy
        self.slot = slot

        self.mem = bytearray(65536)
        self.m6502 = CPU6502(slot=slot)
        self.m6502.mem = self.mem
        self.m6502.disk = DSKDisk(self.dsk_bytes, interleave=interleave)

        self.z = Z80CPU()
        self.z80_started = False
        self.switches = 0
        self.resume_6502 = None

        self.kbd_queue = []
        self.kbd_current = 0x00
        self.kbd_polls = 0            # Z-80-side $C000 reads
        self.kbd_polls_6502 = 0       # 6502-side $C000 reads

        self.disk_reads = []          # (track, sector_logical, phys, dest)
        self.disk_writes = []

        self.lc = LanguageCard(self.mem) if language_card else None

        self.videx = None
        if videx:
            rom_path = find_videx_rom(videx_rom)
            if rom_path is None:
                raise FileNotFoundError(
                    "Videx Videoterm firmware ROM not found; pass "
                    "videx_rom= or place it at softcard_emu/roms/"
                    "videx_videoterm_2.4.bin")
            self.videx = VidexVideoterm(rom_path.read_bytes(),
                                        arbitrate=c8_arbitrate)

        self._setup_boot()
        self._install_6502_hooks()
        self._install_z80_hooks()
        self._install_monitor_hooks()
        self._install_c8_pc_hooks()
        if sector_hook:
            self._install_sector_hook()

    # ------------------------------------------------------------------
    # boot-state setup (P6 PROM post-state + hooks)
    # ------------------------------------------------------------------
    def _setup_boot(self):
        mem = self.mem
        mem[0x0800:0x0900] = self.dsk_bytes[:256]

        if self.lc is None:
            # flat mode: RTS stubs at the monitor entries (PC hooks make
            # these mostly decorative, but data reads should not see 0)
            for addr in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                         0xFD8E, 0xFDED, 0xFD0C, 0xFF65, 0xFF4A, 0xFF3F):
                mem[addr] = 0x60
            mem[0xFFFC:0x10000] = bytes([0x01, 0x08, 0x02, 0x00])
        # KIL trap for stray BRK
        mem[0x0002] = 0x02
        mem[0xFFFE] = 0x02
        mem[0xFFFF] = 0x00

        # Disk II P6 PROM bytes (optional; the $C65C hook does the work)
        for rom_dir in (Path(__file__).resolve().parent / "roms",
                        _REPO_ROOT / "cpm-investigation" / "roms"):
            p = rom_dir / "disk2_p6.bin"
            if p.exists():
                base = 0xC000 | (self.slot << 8)
                rom = p.read_bytes()
                mem[base:base + len(rom)] = rom
                break

        # Videx ROM bytes live in flat memory too: 6502 instruction
        # FETCHES bypass the read hook (the core fetches via mem[pc]),
        # and both console paths execute firmware at $C3xx/$C8xx. Data
        # reads are still gated by the ownership model; fetch-side
        # faults are caught by PC hooks.
        if self.videx:
            mem[0xC300:0xC400] = self.videx.rom[768:1024]
            mem[0xC800:0xCC00] = self.videx.rom[0:1024]

        c = self.m6502
        c.pc = 0x0801
        c.x = self.slot * 16
        c.sp = 0xFD
        c.a = 0
        c.y = 0
        mem[0x2B] = self.slot * 16
        mem[0x26] = 0x00
        mem[0x27] = 0x09
        mem[0x3D] = 0x01
        c.disk.motor_on = True
        c.disk.current_qtrack = 0

        # P6 PROM boot-read hook: service "read sector N to (dest)"
        def p6_hook(cpu):
            target_sector = cpu.mem[0x3D]
            dest = cpu.mem[0x26] | (cpu.mem[0x27] << 8)
            track = cpu.disk.current_qtrack // 4
            logical = self.interleave[target_sector]
            off = (track * 16 + logical) * 256
            for i, b in enumerate(self.dsk_bytes[off:off + 256]):
                cpu.mem[(dest + i) & 0xFFFF] = b
            cpu.mem[0x27] = (cpu.mem[0x27] + 1) & 0xFF
            cpu.pc = 0x0801
            return False
        c.add_breakpoint(0xC000 | (self.slot << 8) | 0x5C, p6_hook)

        # slot-scanner $3E first-iteration patch (see cpm-investigation
        # emu_softcard.py for the derivation); installed at both
        # versions' addresses
        fired = [False]
        def patch_3e(cpu):
            if not fired[0]:
                cpu.mem[0x3E] = 0
                fired[0] = True
            return False
        c.add_breakpoint(0x106A, patch_3e)
        c.add_breakpoint(0x1063, patch_3e)

    # ------------------------------------------------------------------
    # 6502 bus hooks
    # ------------------------------------------------------------------
    def _install_6502_hooks(self):
        c = self.m6502
        orig_write = c.write
        orig_read = c.read

        def write_6502(addr, val):
            # SoftCard CPU switch: warm-loop store to the card's slot
            # page ($C400 ships in 2.20's image; the scanner patches
            # the installed copy). Only from the warm loop at $03C0+ --
            # the slot scanner's $Cn00 probe writes must not flip.
            if ((addr & 0xFF00) == 0xC700 or (addr & 0xFF00) == 0xC400) \
                    and c.pc < 0x0400:
                pc = c.pc
                self.resume_6502 = (pc + 3) & 0xFFFF \
                    if self.mem[pc] == 0x8D else pc
                if self.videx:
                    self.videx.track(addr, '6502-wr', pc)
                raise Yield()
            if 0xC080 <= addr <= 0xC08F and self.lc:
                self.lc.access(addr & 0xF, is_read=False)
                return
            if 0xC0B0 <= addr <= 0xC0BF and self.videx:
                self.videx.io(addr, val)
                return
            if 0xC100 <= addr <= 0xCFFF and self.videx:
                self.videx.track(addr, '6502-wr', c.pc)
                if 0xC800 <= addr <= 0xCFFE:
                    self.videx.window_write(addr, val, '6502', c.pc)
                    return
                if addr == 0xCFFF:
                    return
            if addr >= 0xD000 and self.lc:
                self.lc.write(addr, val)
                return
            orig_write(addr, val)
        c.write = write_6502

        def read_6502(addr):
            if addr == 0xC000:
                self.kbd_polls_6502 += 1
                if self.kbd_queue and not (self.kbd_current & 0x80):
                    self.kbd_current = self.kbd_queue.pop(0) | 0x80
                return self.kbd_current
            if addr == 0xC010:
                self.kbd_current &= 0x7F
                return 0x00
            if 0xC080 <= addr <= 0xC08F and self.lc:
                return self.lc.access(addr & 0xF, is_read=True)
            if 0xC0B0 <= addr <= 0xC0BF and self.videx:
                return self.videx.io(addr)
            if 0xC100 <= addr <= 0xCFFF and self.videx:
                self.videx.track(addr, '6502-rd', c.pc)
                if addr == 0xCFFF:
                    return 0xFF
                if addr >= 0xC800:
                    return self.videx.window_read(addr, '6502', c.pc)
                if (addr >> 8) & 7 == VidexVideoterm.SLOT:
                    return self.videx.slot_rom_read(addr)
            if addr >= 0xD000 and self.lc:
                return self.lc.read(addr)
            return orig_read(addr)
        c.read = read_6502

    # ------------------------------------------------------------------
    # Z-80 bus hooks (through the SoftCard translation)
    # ------------------------------------------------------------------
    def _install_z80_hooks(self):
        z = self.z

        def z_rd(addr, _v):
            ap = realmap(addr)
            if ap == 0xC000:
                self.kbd_polls += 1
                if self.kbd_queue and not (self.kbd_current & 0x80):
                    self.kbd_current = self.kbd_queue.pop(0) | 0x80
                return self.kbd_current
            if ap == 0xC010:
                self.kbd_current &= 0x7F
                return 0x00
            if 0xC080 <= ap <= 0xC08F and self.lc:
                return self.lc.access(ap & 0xF, is_read=True)
            if 0xC0B0 <= ap <= 0xC0BF and self.videx:
                return self.videx.io(ap)
            if (ap & 0xFF00) == 0xC700:               # SoftCard switch
                if self.videx:
                    self.videx.track(ap, 'z80-rd', z.pc)
                raise Yield()
            if 0xC100 <= ap <= 0xCFFF and self.videx:
                self.videx.track(ap, 'z80-rd', z.pc)
                if ap == 0xCFFF:
                    return 0xFF
                if ap >= 0xC800:
                    return self.videx.window_read(ap, 'z80', z.pc)
                if (ap >> 8) & 7 == VidexVideoterm.SLOT:
                    return self.videx.slot_rom_read(ap)
            if ap >= 0xD000 and self.lc:
                return self.lc.read(ap)
            return self.mem[ap]

        def z_wr(addr, val):
            ap = realmap(addr)
            if (ap & 0xFF00) == 0xC700:               # SoftCard switch
                if self.videx:
                    self.videx.track(ap, 'z80-wr', z.pc)
                raise Yield()
            if 0xC080 <= ap <= 0xC08F and self.lc:
                self.lc.access(ap & 0xF, is_read=False)
                return True
            if 0xC0B0 <= ap <= 0xC0BF and self.videx:
                self.videx.io(ap, val)
                return True
            if 0xC100 <= ap <= 0xCFFF and self.videx:
                self.videx.track(ap, 'z80-wr', z.pc)
                if 0xC800 <= ap <= 0xCFFE:
                    self.videx.window_write(ap, val, 'z80', z.pc)
                return True
            if 0xC000 <= ap <= 0xCFFF:
                return True                           # other I/O: discard
            if ap >= 0xD000 and self.lc:
                self.lc.write(ap, val)
                return True
            self.mem[ap] = val
            return True

        z.read_hook = z_rd
        z.write_hook = z_wr

    # ------------------------------------------------------------------
    # monitor entries as PC hooks ("run from ROM" regardless of RAM)
    # ------------------------------------------------------------------
    def _install_monitor_hooks(self):
        def mon_rts(cpu):
            lo = cpu.mem[0x0100 + ((cpu.sp + 1) & 0xFF)]
            hi = cpu.mem[0x0100 + ((cpu.sp + 2) & 0xFF)]
            cpu.sp = (cpu.sp + 2) & 0xFF
            cpu.pc = (((hi << 8) | lo) + 1) & 0xFFFF
            return False

        def mon_save(cpu):                 # $FF4A: A,X,Y,P,SP -> $45-$49
            cpu.mem[0x45] = cpu.a
            cpu.mem[0x46] = cpu.x
            cpu.mem[0x47] = cpu.y
            cpu.mem[0x48] = cpu._get_p()
            cpu.mem[0x49] = cpu.sp
            cpu.D = 0
            return mon_rts(cpu)

        def mon_restore(cpu):              # $FF3F: $45-$48 -> A,X,Y,P
            cpu._set_p(cpu.mem[0x48])
            cpu.a = cpu.mem[0x45]
            cpu.x = cpu.mem[0x46]
            cpu.y = cpu.mem[0x47]
            return mon_rts(cpu)

        self.m6502.add_breakpoint(0xFF4A, mon_save)
        self.m6502.add_breakpoint(0xFF3F, mon_restore)
        for entry in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                      0xFD8E, 0xFDED, 0xFD0C, 0xFF65,
                      0xFC58, 0xFC22, 0xFC42, 0xFC9C, 0xFC70, 0xFB39,
                      0xFDF0):
            self.m6502.add_breakpoint(entry, mon_rts)

    # ------------------------------------------------------------------
    # instruction-fetch coverage for $C100-$CFFF (fetches bypass read())
    # ------------------------------------------------------------------
    def _install_c8_pc_hooks(self):
        if not self.videx or not self.videx.arbitrate:
            return

        def c8_pc_hook(cpu):
            self.videx.track(cpu.pc, '6502-fetch', cpu.pc)
            if cpu.pc >= 0xC800 and not self.videx.c8_owner:
                self.videx.fault('6502-fetch', cpu.pc, cpu.pc)
            return False

        for a in range(0xC100, 0xD000):
            existing = self.m6502.on_pc.get(a)
            if existing is None:
                self.m6502.add_breakpoint(a, c8_pc_hook)
            else:
                def chained(cpu, _orig=existing):
                    c8_pc_hook(cpu)
                    return _orig(cpu)
                self.m6502.add_breakpoint(a, chained)

    # ------------------------------------------------------------------
    # sector-level disk service at the RWTS read primitive ($BE11)
    # ------------------------------------------------------------------
    def _install_sector_hook(self):
        # Contract (docs/CPM223_RWTS.asm): $03E0 track; $03E1 sector
        # (CP/M-logical; physical via the skew table at $BF9E);
        # $03E8/$03E9 destination pointer; $03E4 drive (bit0 = drive 1);
        # $03EB bit0 = read; returns carry + $03EA; $0478 tracks head.
        # 2.20's RWTS lives at different addresses and never reaches
        # this hook; its reads run the synthetic-nibble path.
        def rwts_sector_hook(c):
            track = c.mem[0x03E0]
            sec_log = c.mem[0x03E1] & 0x0F
            phys = c.mem[0xBF9E + sec_log]
            file_idx = self.interleave[phys]
            off = (track * 16 + file_idx) * 256
            dest = c.mem[0x03E8] | (c.mem[0x03E9] << 8)

            def ret(carry, err):
                c.mem[0x03EA] = err
                c.C = carry
                lo = c.mem[0x0100 + ((c.sp + 1) & 0xFF)]
                hi = c.mem[0x0100 + ((c.sp + 2) & 0xFF)]
                c.sp = (c.sp + 2) & 0xFF
                c.pc = (((hi << 8) | lo) + 1) & 0xFFFF
                return False

            if not (c.mem[0x03E4] & 1):
                return ret(carry=1, err=0x40)         # drive 2 absent
            if track >= 35 or off + 256 > len(self.disk_image):
                return ret(carry=1, err=0x40)

            c.mem[0x0478] = track
            c.mem[0x03E7] = c.mem[0x03E6]
            c.mem[0x03E5] = c.mem[0x03E4]

            if c.mem[0x03EB] & 1:                     # read
                if dest + 256 <= 0x10000:
                    c.mem[dest:dest + 256] = self.disk_image[off:off + 256]
                else:
                    for i in range(256):
                        c.mem[(dest + i) & 0xFFFF] = self.disk_image[off + i]
                self.disk_reads.append((track, sec_log, phys, dest))
            else:                                     # write
                for i in range(256):
                    self.disk_image[off + i] = c.mem[(dest + i) & 0xFFFF]
                self.disk_writes.append((track, sec_log, phys, dest))
            return ret(carry=0, err=0x00)

        self.m6502.add_breakpoint(0xBE11, rwts_sector_hook)

    # ------------------------------------------------------------------
    # public interface
    # ------------------------------------------------------------------
    def type_keys(self, text):
        """Queue keystrokes (use \\r for Return)."""
        for ch in text:
            self.kbd_queue.append(ord(ch))

    inject_keys = type_keys              # emu_softcard_v2 compatibility

    def run(self, total_steps=80_000_000, z80_slice=2_000_000,
            m6502_slice=2_000_000):
        """Alternate CPUs on the switch until idle or budget spent.

        Returns a short status string: 'z80-idle (keyboard poll)' /
        '6502-idle (keyboard poll)' mean the system is sitting at the
        console waiting for input -- i.e., a healthy interactive state.
        """
        active = '6502'
        spent = 0
        while spent < total_steps:
            if active == '6502':
                if self.resume_6502 is not None:
                    self.m6502.pc = self.resume_6502
                    self.resume_6502 = None
                before = self.m6502.exec_count
                polls_before = self.kbd_polls_6502
                try:
                    r = self.m6502.run(max_instructions=m6502_slice,
                                       progress_interval=0)
                except Yield:
                    r = 'switch'
                spent += self.m6502.exec_count - before
                if r == 'switch':
                    self.switches += 1
                    if not self.z80_started:
                        self.z.pc = 0x0000
                        self.z.sp = 0x0000
                        self.z80_started = True
                    active = 'z80'
                    continue
                if r == 'limit':
                    if (not self.kbd_queue
                            and self.kbd_polls_6502 - polls_before > 1000):
                        return '6502-idle (keyboard poll)'
                    continue
                return f"6502 stopped: {r} at PC=${self.m6502.pc:04X}"
            else:
                before = self.z.exec_count
                try:
                    r = self.z.run(max_instructions=z80_slice,
                                   progress_interval=0)
                except Yield:
                    r = 'switch'
                except Exception as e:
                    return f"Z-80 error at PC=${self.z.pc:04X}: {e}"
                spent += self.z.exec_count - before
                if r == 'switch':
                    self.switches += 1
                    active = '6502'
                    continue
                if r == 'limit':
                    if self.kbd_polls > 0 and not self.kbd_queue:
                        return 'z80-idle (keyboard poll)'
                    continue
                return f"Z-80 stopped: {r} at PC=${self.z.pc:04X}"
        return 'step budget spent'

    def screen_text(self):
        """The visible display: Videx 80-column if present, else 40-col."""
        if self.videx:
            return self.videx.screen_text()
        return self.text40()

    def text40(self, rows=24, cols=40):
        """Decode the Apple 40-column text page."""
        out = []
        for r in range(rows):
            base = _text40_row_base(r)
            line = ''.join(
                chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else '.'
                for b in self.mem[base:base + cols])
            out.append(line.rstrip('.'))
        while out and not out[-1]:
            out.pop()
        return out

    @property
    def c8_fault_count(self):
        return self.videx.fault_count if self.videx else 0
