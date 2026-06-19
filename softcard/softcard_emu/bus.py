"""Central memory/bus subsystem.

The Bus owns the flat 64 KB Apple memory plane and is the single place
that knows the current memory-map state, resolving every access by
address region instead of scattering those checks across the machine.
It composes the subsystems that own the live state it consults:

  * LanguageCard -- $D000-$FFFF bank/write-enable and the $C080-$C08F
    soft switches.
  * VidexVideoterm -- the active slot ROM ($C300), the $C800-$CFFF
    expansion-ROM window and who currently owns it, and CRTC I/O.
  * Keyboard -- $C000 data / $C010 strobe and the poll counters.
  * SoftCardSwitch -- whether an access hands the bus to the other CPU.

Both processors reach memory through this one object. The 6502 sees the
native Apple address space; the Z-80 sees it through the SoftCard
translation (``realmap``), applied here before decode. Instruction
fetches get their own entry points: the 6502's honors language-card
banking over $D000-$FFFF (the 60K system executes its relocated OS from
LC RAM); the Z-80's fetch path already routes through its read hook.

The decode ladders below are a faithful, order-preserving hoist of the
per-CPU hooks that previously lived in the machine -- the region branch
order and the two side-specific divergences (the 6502 switch trigger
vs. the Z-80's; the Z-80's "$C000-$CFFF other I/O is discarded" catch-
all) are reproduced exactly, so behavior is byte-for-byte unchanged.
"""

from .switch import realmap, Yield
from .videx import VidexVideoterm


class Bus:
    def __init__(self, mem, *, lc=None, videx=None, kbd, switch):
        self.mem = mem                # the shared 64 KB plane
        self.lc = lc                  # LanguageCard or None
        self.videx = videx            # VidexVideoterm or None
        self.kbd = kbd                # Keyboard
        self.switch = switch          # SoftCardSwitch
        self._c = None                # 6502 core (read live for pc)
        self._z = None                # Z-80 core (read live for pc)
        # The 6502's flat/Disk-II fallthrough reuses the core's native
        # read/write (they model the Disk II latches and the
        # write_ranges histogram); captured at attach time.
        self._orig_read = None
        self._orig_write = None

    # -- flat-plane seam (boot pokes, ROM mirroring, opcode peeks) --------
    def flat_read(self, addr):
        return self.mem[addr]

    def flat_write(self, addr, val):
        self.mem[addr] = val

    # -- CPU attachment ---------------------------------------------------
    def attach_6502(self, cpu):
        """Route a 6502 core's data + fetch accesses through the bus."""
        self._c = cpu
        self._orig_read = cpu.read     # capture native methods BEFORE
        self._orig_write = cpu.write   # replacing them (Disk II + write_ranges)
        cpu.read = self.read6502
        cpu.write = self.write6502
        if self.lc:
            cpu.fetch_hook = self.fetch6502

    def attach_z80(self, cpu):
        """Route a Z-80 core's memory accesses through the bus."""
        self._z = cpu
        cpu.read_hook = self.readz80
        cpu.write_hook = self.writez80

    # -- 6502 instruction fetch (language-card banked) -------------------
    def fetch6502(self, addr):
        # $D000-$FFFF fetches honor LC banking (the 60K loader copies the
        # relocated OS into LC bank 1 and JSRs into it); below $D000,
        # incl. the Videx firmware at $C3xx/$C8xx, fetch the flat plane.
        if addr >= 0xD000:
            return self.lc.read(addr)
        return self.mem[addr]

    # -- 6502 data path --------------------------------------------------
    def write6502(self, addr, val):
        c = self._c
        # SoftCard CPU switch: warm-loop store to the card's slot page
        # ($C400 ships in 2.20's image; the scanner patches the installed
        # copy). Only from the warm loop (pc < $0400).
        if self.switch.trigger_6502_write(addr, c.pc, self.flat_read):
            if self.videx:
                self.videx.track(addr, '6502-wr', c.pc)
            raise Yield()
        if addr == 0xC010:                            # any access clears the
            self.kbd.clear_strobe()                   # keyboard strobe (incl.
            return                                    # a write, per real HW)
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
        self._orig_write(addr, val)

    def read6502(self, addr):
        c = self._c
        if addr == 0xC000:
            return self.kbd.read_data('6502')
        if addr == 0xC010:
            return self.kbd.clear_strobe()
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
        return self._orig_read(addr)

    # -- Z-80 data path (through the SoftCard translation) ---------------
    def readz80(self, addr, _v=None):
        z = self._z
        ap = realmap(addr)
        if ap == 0xC000:
            return self.kbd.read_data('z80')
        if ap == 0xC010:
            return self.kbd.clear_strobe()
        if 0xC080 <= ap <= 0xC08F and self.lc:
            return self.lc.access(ap & 0xF, is_read=True)
        if 0xC0B0 <= ap <= 0xC0BF and self.videx:
            return self.videx.io(ap)
        if self.switch.is_z80_switch(ap):             # SoftCard switch
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

    def writez80(self, addr, val):
        z = self._z
        ap = realmap(addr)
        if self.switch.is_z80_switch(ap):             # SoftCard switch
            if self.videx:
                self.videx.track(ap, 'z80-wr', z.pc)
            raise Yield()
        if ap == 0xC010:                              # write clears the keyboard
            self.kbd.clear_strobe()                   # strobe (SoftCard CONIN
            return True                               # does LD ($E010),A)
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
            return True                               # other I/O: discard
        if ap >= 0xD000 and self.lc:
            self.lc.write(ap, val)
            return True
        self.mem[ap] = val
        return True
