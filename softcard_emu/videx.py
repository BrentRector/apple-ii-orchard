"""
Videx Videoterm in slot 3: firmware ROM, CRTC, paged VRAM, and
$C800-$CFFF expansion-ROM window arbitration.

Hardware model (Videoterm Installation & Operation Manual; A2FPGA
videx_card.sv):

  * 1 KB firmware ROM at $C800-$CBFF; its last 256 bytes also appear
    as the slot ROM at $C300-$C3FF.
  * 2 KB VRAM, visible 512 bytes at a time at $CC00-$CDFF; the page is
    selected by A2-A3 of any $C0B0-$C0BF access; A0 selects CRTC
    register-select vs data (R12/R13 drive the screen start address).
  * C8-space ownership: the card claims the shared $C800-$CFFF window
    when its own $C3xx slot page is accessed, and releases it on any
    $CFFF access -- and, under the A2FPGA arbitration rule this class
    reproduces, on any access to a DIFFERENT slot's $Cnxx page
    (`other_slot_rom`). The A2FPGA source documents that release as an
    FPGA-bus-mux addition; whether physical Videoterm boards behave
    identically is an open question (softcard-videx series, Part 5).
    Pass arbitrate=False for a permissive always-mapped window.

Reads of the unowned window float (modelled as $FF) and are recorded
as faults; on real hardware, fetching there executes garbage.
"""

from pathlib import Path

VIDEX_ROM_CANDIDATES = [
    Path(__file__).resolve().parent / "roms" / "videx_videoterm_2.4.bin",
    Path("e:/a2fpga_core/hdl/videx/Videx Videoterm ROM 2.4.bin"),
]


def find_videx_rom(explicit=None):
    if explicit:
        p = Path(explicit)
        return p if p.exists() else None
    for p in VIDEX_ROM_CANDIDATES:
        if p.exists():
            return p
    return None


class VidexVideoterm:
    SLOT = 3

    def __init__(self, rom_bytes, *, arbitrate=True):
        self.rom = bytes(rom_bytes)                    # 1024 bytes
        self.arbitrate = arbitrate
        self.vram = bytearray(2048)
        self.page = 0
        self.crtc_regs = bytearray(18)
        self.crtc_sel = 0

        self.c8_owner = False        # do we own $C800-$CFFF right now?
        self.faults = []             # (kind, pc, addr) while unowned
        self.fault_count = 0
        self.events = []             # first claim/release transitions
        self.vram_writes = 0

    # -- $C0B0-$C0BF ------------------------------------------------------
    def io(self, addr, val=None):
        self.page = (addr >> 2) & 3
        if addr & 1:                                   # data port
            if val is not None:
                if self.crtc_sel < 18:
                    self.crtc_regs[self.crtc_sel] = val
                return None
            return self.crtc_regs[self.crtc_sel] if self.crtc_sel < 18 else 0
        if val is not None:
            self.crtc_sel = val
            return None
        return 0

    # -- ownership bookkeeping ---------------------------------------------
    def track(self, ap, who='?', pc=0):
        """Owner bookkeeping for any $C100-$CFFF bus access."""
        old = self.c8_owner
        if ap == 0xCFFF:
            self.c8_owner = False
        elif 0xC100 <= ap <= 0xC7FF:
            slot = (ap >> 8) & 7
            if slot == self.SLOT:
                self.c8_owner = True
            elif self.arbitrate:
                self.c8_owner = False              # other_slot_rom release
        if self.c8_owner != old and len(self.events) < 400:
            self.events.append(
                (who, pc, ap, 'claim' if self.c8_owner else 'release'))

    def fault(self, kind, pc, addr):
        self.fault_count += 1
        if len(self.faults) < 200:
            self.faults.append((kind, pc, addr))

    # -- window data path ($C800-$CFFE; caller has done track()) -----------
    def vram_addr(self, ap):
        return self.page * 512 + (ap - 0xCC00)

    def window_read(self, ap, who='?', pc=0):
        if not self.c8_owner and self.arbitrate:
            self.fault(who + '-rd', pc, ap)
            return 0xFF
        if 0xCC00 <= ap <= 0xCDFF:
            return self.vram[self.vram_addr(ap)]
        if 0xC800 <= ap <= 0xCBFF:
            return self.rom[ap - 0xC800]
        return 0xFF                                    # $CE00-$CFFE unused

    def window_write(self, ap, val, who='?', pc=0):
        if not self.c8_owner and self.arbitrate:
            self.fault(who + '-wr', pc, ap)
            return
        if 0xCC00 <= ap <= 0xCDFF:
            self.vram_writes += 1
            self.vram[self.vram_addr(ap)] = val

    # -- slot ROM ($C300-$C3FF) --------------------------------------------
    def slot_rom_read(self, ap):
        return self.rom[768 + (ap - 0xC300)]

    # -- display -----------------------------------------------------------
    def screen_text(self, cols=80, rows=24):
        """Decode the 80x24 display from the CRTC start address."""
        start = ((self.crtc_regs[12] << 8) | self.crtc_regs[13]) & 0x7FF
        out = []
        for r in range(rows):
            line = ''.join(
                chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else '.'
                for b in (self.vram[(start + r * cols + c) & 0x7FF]
                          for c in range(cols)))
            out.append(line.rstrip('.'))
        while out and not out[-1]:
            out.pop()
        return out
