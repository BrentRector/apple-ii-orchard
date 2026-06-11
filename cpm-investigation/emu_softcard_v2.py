"""
SoftCard CP/M boot emulator v2: bidirectional CPU switching + the
documented SoftCard address map.

This is the "future emulator pass" deferred at investigation closure
(resume-prompt "Architectural mechanisms still unmodeled"). It models:

  * The documented SoftCard Z-80 -> Apple address translation:
        Z-80 $0000-$AFFF  ->  Apple $1000-$BFFF   (+$1000)
        Z-80 $B000-$DFFF  ->  Apple $D000-$FFFF   (+$2000, LC region)
        Z-80 $E000-$EFFF  ->  Apple $C000-$CFFF   (I/O page)
        Z-80 $F000-$FFFF  ->  Apple $0000-$0FFF   (-$F000)
    (replacing v1's bit-12-XOR-below-$2000 model, which booted the 6502
    phase correctly but left the Z-80 wandering an empty BIOS).

  * Bidirectional CPU switching on access to the SoftCard's slot I/O
    space (Apple $C700 for the slot-7 configuration both 2.20 and 2.23
    install): 6502 access freezes the 6502 and resumes the Z-80; Z-80
    access (via its $E700 window) freezes the Z-80 and resumes the 6502.
    The 6502 resumes *after* its triggering instruction; the Z-80
    likewise. First Z-80 entry is a true reset (PC=$0000).

  * Runtime cooperative disk I/O: the 6502-side service path runs the
    real preserved RWTS down to the Disk II soft switches; we service it
    with a sector-level hook (same approach as the boot-time P6 hook).

What this demonstrates end-to-end (2.23 + Videx in slot 3):
  reset vector JP $FA00 -> BIOS jump table at Z-80 $FA00 (Apple $0A00)
  -> cold boot -> device scan reads slot table at Z-80 $F3B8 (= Apple
  $03B8, no copy!) -> Videx = device 6 -> CONOUT delegation to 6502
  (reg slots $45-$48 + patched JSR operand at $03D0) -> 6502 runs Videx
  firmware -> banner in Videx VRAM -> A> prompt -> Z-80 polls keyboard
  at $E000 (= Apple $C000, no flag pair).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from emu_softcard_full import SoftCardSystem
from nibbler.z80_cpu import Z80CPU


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


class SoftCardV2:
    SWITCH_APPLE = 0xC700      # SoftCard slot-7 I/O select

    def __init__(self, dsk_path, *, videx=True, trace=False,
                 sector_hook=True, c8_arbitrate=True):
        self.c8_arbitrate = c8_arbitrate
        self.sys = SoftCardSystem(dsk_path)
        self.sys.setup_boot()
        if not videx:
            # blank out the Videx ROM the base harness installed
            self.sys.apple_mem[0xC300:0xC400] = bytes(256)
            self.sys.apple_mem[0xC800:0xCC00] = bytes(1024)
        self.mem = self.sys.apple_mem
        self.m6502 = self.sys.cpu6502
        self.trace = trace

        # v1 installed a one-way switch breakpoint at $0E36; remove it.
        self.m6502.remove_breakpoint(0x0E36)

        # --- Monitor-ROM entry emulation ----------------------------------
        # The flat 64K model has no language-card banking. On real hardware
        # Apple $D000-$FFFF is two banks: monitor ROM, and the LC RAM that
        # 2.20's Z-80 BIOS occupies at $FA00-$FFFF (Z-80 $DA00+, +$2000
        # window). The warm loop manages the banks as part of the
        # cooperative protocol -- LDA $C081 banks ROM in before
        # JSR $0E36/$FF58/$FF4A, LDA $C083 x2 banks LC RAM back in before
        # handing the bus to the Z-80. Rather than model the banking,
        # emulate the monitor entries the loader and warm loop call as PC
        # hooks: they run "from ROM" no matter what RAM holds at those
        # addresses. SAVE/RESTORE move real data ($45-$48 register slots
        # are the RPC result channel); the rest are no-ops here.
        def mon_rts(c):
            lo = c.mem[0x0100 + ((c.sp + 1) & 0xFF)]
            hi = c.mem[0x0100 + ((c.sp + 2) & 0xFF)]
            c.sp = (c.sp + 2) & 0xFF
            c.pc = (((hi << 8) | lo) + 1) & 0xFFFF
            return False

        def mon_save(c):                   # $FF4A SAVE: A,X,Y,P,SP -> $45-$49
            c.mem[0x45] = c.a
            c.mem[0x46] = c.x
            c.mem[0x47] = c.y
            c.mem[0x48] = c._get_p()
            c.mem[0x49] = c.sp
            c.D = 0
            return mon_rts(c)

        def mon_restore(c):                # $FF3F RESTORE: $45-$48 -> A,X,Y,P
            c._set_p(c.mem[0x48])
            c.a = c.mem[0x45]
            c.x = c.mem[0x46]
            c.y = c.mem[0x47]
            return mon_rts(c)

        self.m6502.add_breakpoint(0xFF4A, mon_save)
        self.m6502.add_breakpoint(0xFF3F, mon_restore)
        for entry in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                      0xFD8E, 0xFDED, 0xFD0C, 0xFF65):
            self.m6502.add_breakpoint(entry, mon_rts)

        # --- Videx Videoterm hardware model -------------------------------
        # 2 KB VRAM, visible 512 bytes at a time at $CC00-$CDFF. The page
        # is selected by A2-A3 of the $C0B0-$C0BF CRTC access; A0 selects
        # CRTC register-select vs data. (Videoterm installation manual.)
        self.videx_vram = bytearray(2048)
        self.videx_page = 0
        self.crtc_regs = bytearray(18)
        self.crtc_sel = 0

        def videx_io(addr, val=None):
            """Access to $C0B0-$C0BF: returns read value (or None)."""
            self.videx_page = (addr >> 2) & 3
            if addr & 1:                       # data port
                if val is not None:
                    if self.crtc_sel < 18:
                        self.crtc_regs[self.crtc_sel] = val
                    return None
                return self.crtc_regs[self.crtc_sel] \
                    if self.crtc_sel < 18 else 0
            if val is not None:
                self.crtc_sel = val
                return None
            return 0
        self.videx_io = videx_io

        def videx_vram_addr(apple_addr):
            return self.videx_page * 512 + (apple_addr - 0xCC00)
        self.videx_vram_addr = videx_vram_addr

        # --- $C800-$CFFF expansion-ROM window arbitration ------------------
        # Real Videoterm behavior (verified by the A2FPGA implementation
        # against real hardware -- see a2fpga-videx-02, "C8-space
        # ownership"): the card claims the window when its own $C3xx slot
        # page is addressed, and releases it on $CFFF *or on any access to
        # a different slot's $Cnxx page* (other_slot_c8). The SoftCard's
        # warm loop touches $C700 every RPC round-trip, so the window is
        # unowned at every 6502 service-call entry unless the call comes
        # in through $C3xx. 2.20's console RPC targets ($C800/$C84D/$C9AA)
        # live INSIDE the window and are entered directly; 2.23's Pascal
        # 1.1 island re-claims via the $Cn0D vector dispatch. When no card
        # owns the window, reads float (modelled as $FF) -- on real
        # hardware, fetching there executes garbage. Faults are logged;
        # flat (always-mapped) behavior via c8_arbitrate=False.
        self.videx_present = videx
        self.c8_owner = None
        self.c8_faults = []           # (kind, pc, addr) accesses while unowned
        self.c8_fault_count = 0
        self.c8_events = []           # first claim/release transitions

        def c8_track(ap, who='?', pc=0):
            """Owner bookkeeping for any $C100-$CFFF access."""
            old = self.c8_owner
            if ap == 0xCFFF:
                self.c8_owner = None
            elif 0xC100 <= ap <= 0xC7FF:
                slot = (ap >> 8) & 7
                if slot == 3 and self.videx_present:
                    self.c8_owner = 3
                else:
                    self.c8_owner = None      # other_slot_c8 release
            if self.c8_owner != old and len(self.c8_events) < 400:
                self.c8_events.append(
                    (who, pc, ap, 'claim' if self.c8_owner == 3
                     else 'release'))
        self.c8_track = c8_track

        # --- Z-80 with the real map -------------------------------------
        self.z = Z80CPU()
        self.z80_started = False
        self.switches = 0
        self.log = []                 # significant events
        self.vram_writes = []         # (who, pc, apple_addr, val)
        self.kbd_polls = 0
        self.kbd_queue = []           # injected keys (Apple format, bit7 set)
        self.kbd_current = 0x00

        def z_rd(addr, _v):
            ap = realmap(addr)
            if ap == 0xC000:                       # keyboard data
                self.kbd_polls += 1
                if self.kbd_queue and not (self.kbd_current & 0x80):
                    self.kbd_current = self.kbd_queue.pop(0) | 0x80
                return self.kbd_current
            if ap == 0xC010:                       # keyboard strobe clear
                self.kbd_current &= 0x7F
                return 0x00
            if 0xC0B0 <= ap <= 0xC0BF:
                return self.videx_io(ap)
            if (ap & 0xFF00) == 0xC700:            # SoftCard switch (read)
                if self.c8_arbitrate:              # slot-7 access on the bus
                    self.c8_track(ap, 'z80-rd', self.z.pc)
                raise Yield()
            if self.c8_arbitrate and 0xC100 <= ap <= 0xCFFF:
                self.c8_track(ap, 'z80-rd', self.z.pc)
                if ap == 0xCFFF:
                    return 0xFF
                if ap >= 0xC800:
                    if self.c8_owner != 3:
                        self._c8_fault('z80-rd', self.z.pc, ap)
                        return 0xFF
                    if 0xCC00 <= ap <= 0xCDFF:
                        return self.videx_vram[self.videx_vram_addr(ap)]
            elif 0xCC00 <= ap <= 0xCDFF:
                return self.videx_vram[self.videx_vram_addr(ap)]
            return self.mem[ap]

        def z_wr(addr, val):
            ap = realmap(addr)
            if (ap & 0xFF00) == 0xC700:            # SoftCard switch (write)
                if self.c8_arbitrate:              # slot-7 access on the bus
                    self.c8_track(ap, 'z80-wr', self.z.pc)
                raise Yield()
            if 0xC0B0 <= ap <= 0xC0BF:
                self.videx_io(ap, val)
                return True
            if self.c8_arbitrate and 0xC100 <= ap <= 0xCFFF:
                self.c8_track(ap, 'z80-wr', self.z.pc)
                if 0xC800 <= ap <= 0xCFFE:
                    if self.c8_owner == 3:
                        if 0xCC00 <= ap <= 0xCDFF:
                            self.vram_writes.append(('z80', self.z.pc,
                                                     ap, val))
                            self.videx_vram[self.videx_vram_addr(ap)] = val
                    else:
                        self._c8_fault('z80-wr', self.z.pc, ap)
                return True
            if 0xCC00 <= ap <= 0xCDFF:
                self.vram_writes.append(('z80', self.z.pc, ap, val))
                self.videx_vram[self.videx_vram_addr(ap)] = val
                return True
            if 0xC000 <= ap <= 0xCFFF:
                return True                        # other I/O: discard
            self.mem[ap] = val
            return True

        self.z.read_hook = z_rd
        self.z.write_hook = z_wr
        self.resume_6502 = None

        # --- 6502 side ----------------------------------------------------
        # Trap the warm-loop STA $C700 (at $03C6 in both versions) and any
        # JSR into $C400/$C700 space, by hooking the 6502's write/read.
        orig_write = self.m6502.write
        def write_6502(addr, val):
            if ((addr & 0xFF00) == 0xC700 or (addr & 0xFF00) == 0xC400) \
                    and self.m6502.pc < 0x0400:
                # Bus flip -- but only from the installed warm loop at
                # $03C0+. The slot scanner at $1060+ writes a $00 probe
                # into $Cn00 of candidate slots during boot (that's the
                # SoftCard *discovery* write on real hardware); the
                # switch must not fire for those.
                # The exception aborts the STA mid-instruction with PC
                # still at the opcode; record where to resume (past the
                # 3-byte STA abs) so the 6502 continues its loop.
                pc = self.m6502.pc
                if self.mem[pc] == 0x8D:           # STA abs
                    self.resume_6502 = (pc + 3) & 0xFFFF
                else:
                    self.resume_6502 = pc
                if self.c8_arbitrate:              # slot-7 access on the bus
                    self.c8_track(addr, '6502-wr', pc)
                raise Yield()
            if 0xC0B0 <= addr <= 0xC0BF:
                self.videx_io(addr, val)
                return
            if self.c8_arbitrate and 0xC100 <= addr <= 0xCFFF:
                self.c8_track(addr, '6502-wr', self.m6502.pc)
                if 0xC800 <= addr <= 0xCFFE:
                    if self.c8_owner == 3:
                        if 0xCC00 <= addr <= 0xCDFF:
                            self.vram_writes.append(('6502', self.m6502.pc,
                                                     addr, val))
                            self.videx_vram[self.videx_vram_addr(addr)] = val
                    else:
                        self._c8_fault('6502-wr', self.m6502.pc, addr)
                    return
                if addr == 0xCFFF:
                    return
            elif 0xCC00 <= addr <= 0xCDFF:         # Videx VRAM window
                self.vram_writes.append(('6502', self.m6502.pc, addr, val))
                self.videx_vram[self.videx_vram_addr(addr)] = val
                return
            orig_write(addr, val)
        self.m6502.write = write_6502

        orig_read = self.m6502.read
        def read_6502(addr):
            if addr == 0xC000:                     # keyboard (6502 side)
                if self.kbd_queue and not (self.kbd_current & 0x80):
                    self.kbd_current = self.kbd_queue.pop(0) | 0x80
                return self.kbd_current
            if addr == 0xC010:
                self.kbd_current &= 0x7F
                return 0x00
            if 0xC0B0 <= addr <= 0xC0BF:
                return self.videx_io(addr)
            if self.c8_arbitrate and 0xC100 <= addr <= 0xCFFF:
                self.c8_track(addr, '6502-rd', self.m6502.pc)
                if addr == 0xCFFF:
                    return 0xFF
                if addr >= 0xC800:
                    if self.c8_owner != 3:
                        self._c8_fault('6502-rd', self.m6502.pc, addr)
                        return 0xFF
                    if 0xCC00 <= addr <= 0xCDFF:
                        return self.videx_vram[self.videx_vram_addr(addr)]
            elif 0xCC00 <= addr <= 0xCDFF:
                return self.videx_vram[self.videx_vram_addr(addr)]
            return orig_read(addr)
        self.m6502.read = read_6502

        # Instruction fetches bypass read() (the core fetches via mem[pc]),
        # but on the real bus a fetch is an address-bus access like any
        # other: fetching in $C3xx claims the window for the Videx (this
        # is how 2.23's $Cn0D vector dispatch re-claims it), fetching in
        # another slot's page releases it, and fetching in $C800-$CFFF
        # while unowned executes floating bus. Model with PC hooks over
        # the whole $C100-$CFFF range (chaining any existing hook, e.g.
        # the P6 boot hook at $C65C). Faults are log-only: execution
        # continues with the flat bytes.
        if self.c8_arbitrate:
            def c8_pc_hook(c):
                self.c8_track(c.pc, '6502-fetch', c.pc)
                if c.pc >= 0xC800 and self.c8_owner != 3:
                    self._c8_fault('6502-fetch', c.pc, c.pc)
                return False
            for a in range(0xC100, 0xD000):
                existing = self.m6502.on_pc.get(a)
                if existing is None:
                    self.m6502.add_breakpoint(a, c8_pc_hook)
                else:
                    def chained(c, _orig=existing):
                        c8_pc_hook(c)
                        return _orig(c)
                    self.m6502.add_breakpoint(a, chained)

        # Boot-time P6 PROM hook stays (installed by setup_boot).

        # --- Sector-level RWTS service ------------------------------------
        # All disk reads (boot-time LOAD_CPM and the runtime cooperative
        # RPC path alike) funnel through the sector-read primitive
        # LOAD_CPM_PRIM at $BE11 in LC RAM. Rather than running the
        # preserved RWTS down to the Disk II soft switches (synthetic
        # nibble streams + seek/settle timing the model doesn't capture),
        # capture the request at $BE11 and copy the sector straight from
        # the .dsk image -- the same approach as the boot-time P6 hook.
        #
        # Contract (from docs/CPM223_RWTS.asm):
        #   $03E0        requested track
        #   $03E1        requested sector, CP/M-logical; physical =
        #                CPM_SKEW_TABLE[$03E1] (the table at $BF9E)
        #   $03E8/$03E9  destination pointer lo/hi (loaded into $3E/$3F;
        #                MERGE_BUFFER writes the 256 bytes through it)
        #   $03E4        drive (bit 0 set = drive 1)
        #   $03EB        bit 0 set = read, clear = write
        #   returns      carry clear + $03EA=0 on success; carry set +
        #                $03EA=error code on failure; $0478 tracks head
        self.disk_image = bytearray(self.sys.dsk_bytes)
        self.disk_reads = []          # (track, sector_logical, phys, dest)
        self.disk_writes = []

        def rwts_sector_hook(c):
            track = c.mem[0x03E0]
            sec_log = c.mem[0x03E1] & 0x0F
            phys = c.mem[0xBF9E + sec_log]
            file_idx = self.sys.interleave[phys]
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

            if not (c.mem[0x03E4] & 1):          # drive 2: not present
                return ret(carry=1, err=0x40)
            if track >= 35 or off + 256 > len(self.disk_image):
                return ret(carry=1, err=0x40)

            # head/drive shadows the real primitive would leave behind
            c.mem[0x0478] = track
            c.mem[0x03E7] = c.mem[0x03E6]
            c.mem[0x03E5] = c.mem[0x03E4]

            if c.mem[0x03EB] & 1:                # read
                if dest + 256 <= 0x10000:
                    c.mem[dest:dest + 256] = self.disk_image[off:off + 256]
                else:                            # wraps: byte-by-byte
                    for i in range(256):
                        c.mem[(dest + i) & 0xFFFF] = self.disk_image[off + i]
                self.disk_reads.append((track, sec_log, phys, dest))
            else:                                # write
                for i in range(256):
                    self.disk_image[off + i] = c.mem[(dest + i) & 0xFFFF]
                self.disk_writes.append((track, sec_log, phys, dest))
            return ret(carry=0, err=0x00)

        if sector_hook:
            self.m6502.add_breakpoint(0xBE11, rwts_sector_hook)

    # ---------------------------------------------------------------------
    def _c8_fault(self, kind, pc, addr):
        self.c8_fault_count += 1
        if len(self.c8_faults) < 200:
            self.c8_faults.append((kind, pc, addr))

    def inject_keys(self, text):
        """Queue keystrokes (CR = \\r)."""
        for ch in text:
            self.kbd_queue.append(ord(ch))

    def run(self, total_steps=40_000_000, z80_slice=2_000_000,
            m6502_slice=2_000_000):
        """Alternate CPUs on Yield until quiescent or step budget spent."""
        active = '6502'
        spent = 0
        while spent < total_steps:
            if active == '6502':
                if self.resume_6502 is not None:
                    self.m6502.pc = self.resume_6502
                    self.resume_6502 = None
                before = self.m6502.exec_count
                try:
                    r = self.m6502.run(max_instructions=m6502_slice,
                                       progress_interval=0)
                except Yield:
                    r = 'switch'
                spent += self.m6502.exec_count - before
                if r == 'switch':
                    self.switches += 1
                    if not self.z80_started:
                        self.z.pc = 0x0000        # true Z-80 reset
                        self.z.sp = 0x0000
                        self.z80_started = True
                        self.log.append(('first-switch',
                                         self.m6502.exec_count))
                    active = 'z80'
                    continue
                if r == 'limit':
                    continue                      # slice expired; keep going
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
                    continue                      # slice expired; keep going
                return f"Z-80 stopped: {r} at PC=${self.z.pc:04X}"
        return 'step budget spent'


def videx_screen(v2, cols=80, rows=24):
    """Decode the Videoterm display: 2 KB VRAM ring starting at the CRTC
    start address (R12:R13), 80x24."""
    start = ((v2.crtc_regs[12] << 8) | v2.crtc_regs[13]) & 0x7FF
    out = []
    for r in range(rows):
        line = ''.join(
            chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else '.'
            for b in (v2.videx_vram[(start + r * cols + c) & 0x7FF]
                      for c in range(cols)))
        out.append(line.rstrip('.'))
    while out and not out[-1]:
        out.pop()
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('disk')
    ap.add_argument('--no-videx', action='store_true')
    ap.add_argument('--keys', default='', help='keystrokes after boot')
    ap.add_argument('--steps', type=int, default=40_000_000)
    ap.add_argument('--real-rwts', action='store_true',
                    help='no $BE11 sector hook; run the preserved RWTS '
                         'down to the Disk II soft switches')
    ap.add_argument('--flat-c800', action='store_true',
                    help='no $C800-$CFFF window arbitration (always-mapped '
                         'Videx expansion ROM, pre-correction behavior)')
    args = ap.parse_args()

    v2 = SoftCardV2(args.disk, videx=not args.no_videx,
                    sector_hook=not args.real_rwts,
                    c8_arbitrate=not args.flat_c800)
    if args.keys:
        v2.inject_keys(args.keys.replace('\\r', '\r'))
    res = v2.run(total_steps=args.steps)
    print(f"result: {res}")
    print(f"switches: {v2.switches}, kbd polls: {v2.kbd_polls:,}")
    print(f"6502: {v2.m6502.exec_count:,} insns, last PC=${v2.m6502.pc:04X}")
    print(f"Z-80: {v2.z.exec_count:,} insns, last PC=${v2.z.pc:04X} "
          f"SP=${v2.z.sp:04X}")
    print(f"Z-80 $0000-$0002: "
          + ' '.join(f"{v2.mem[realmap(a)]:02X}" for a in range(3)))
    print(f"$C800 window faults: {v2.c8_fault_count} "
          f"(owner at end: {v2.c8_owner})")
    for kind, pc, addr in v2.c8_faults[:12]:
        print(f"  {kind} at PC=${pc:04X} addr=${addr:04X}")
    if v2.c8_fault_count and v2.c8_events:
        print("first ownership transitions:")
        for who, pc, ap, what in v2.c8_events[:14]:
            print(f"  {what:7s} {who:10s} PC=${pc:04X} addr=${ap:04X}")
    print(f"disk: {len(v2.disk_reads)} sector reads, "
          f"{len(v2.disk_writes)} writes via $BE11 hook")
    if v2.disk_reads:
        tail = v2.disk_reads[-8:]
        for trk, sec, phys, dest in tail:
            print(f"  read trk {trk:2} sec {sec:2} (phys {phys:2}) "
                  f"-> ${dest:04X}")
    print(f"Videx VRAM writes: {len(v2.vram_writes)}")
    if v2.vram_writes:
        text = ''.join(chr(v & 0x7F) if 32 <= (v & 0x7F) < 127 else '·'
                       for _, _, _, v in v2.vram_writes[:200])
        print(f"  chars written: {text}")
    for line in videx_screen(v2):
        print(f"  |{line}")


if __name__ == '__main__':
    main()
