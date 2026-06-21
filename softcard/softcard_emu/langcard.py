"""
Apple language card: 16 KB of bankable RAM behind $D000-$FFFF.

Models the standard Apple II language-card banking:

  * $D000-$DFFF: two 4 KB RAM banks (bank 1 / bank 2)
  * $E000-$FFFF: 8 KB RAM, common to both banks
  * 12 KB ROM occupying the same addresses, selectable for reads
  * soft switches at $C080-$C08F (any access; A0-A3 decode):

      offset & 8 -> bank select (0 = bank 2, 8 = bank 1)
      offset & 3 == 0  read RAM,  write protect
      offset & 3 == 1  read ROM,  write enable (needs 2 odd READS)
      offset & 3 == 2  read ROM,  write protect
      offset & 3 == 3  read RAM,  write enable (needs 2 odd READS)

  Write-enable requires two consecutive READ accesses to an odd
  switch; any even access clears the pre-write counter and write
  protects; a WRITE to an odd switch clears the counter without
  changing protection (Sather, *Understanding the Apple II*).

The ROM plane is the genuine Apple II+ motherboard ROM ($D000-$FFFF:
Applesoft + the Autostart monitor), passed in by the machine. With it
mapped, the 6502 fetches and executes the real monitor routines
(COUT1/HOME/CROUT/SAVE/RESTORE/...) the SoftCard's console handler
calls -- no PC-hook stand-ins needed (see machine.py). If no ROM image
is supplied (``rom=None``) the plane falls back to an $60 (RTS) fill
plus the SAVE/RESTORE sequences and reset/IRQ vectors, enough for
LC-detection probes to see honest ROM-vs-RAM semantics.

6502 *instruction fetches* honor banking too: the CPU core fetches
opcodes and pc-relative operand bytes through ``CPU6502.fetch_hook``,
which ``Bus.fetch6502`` routes to ``LanguageCard.read`` for $D000-$FFFF.
This is how the 6502 executes the real monitor in place: in ROM-read
mode (the power-on default) fetches of $D000-$FFFF return the ROM, so
the SoftCard's console routines run the genuine COUT1/HOME/SAVE/RESTORE.
It also matters for the 60K system: its loader copies the relocated OS
into LC RAM (bank 1 of $D000-$DFFF) and JSRs into it, so without banked
fetches the CPU would read the flat plane (zeros) and execute BRKs. Z-80
accesses (data and fetch) all route through the read/write hooks and
are likewise fully banked.
"""


class LanguageCard:
    def __init__(self, apple_mem, rom=None):
        # $E000-$FFFF common RAM and bank-2 $D000-$DFFF live in the
        # shared apple_mem array (so direct pokes by setup code remain
        # visible when RAM is banked in); bank 1 is a separate 4 KB.
        self.mem = apple_mem
        self.bank1 = bytearray(0x1000)

        if rom is not None:
            if len(rom) != 0x3000:
                raise ValueError(
                    f"motherboard ROM must be $3000 (12288) bytes for "
                    f"$D000-$FFFF, got {len(rom)}")
            self.rom = bytearray(rom)                   # genuine Apple II+ ROM
        else:
            # Fallback stub (no ROM image): $60 (RTS) fill + the real monitor
            # SAVE/RESTORE byte sequences + reset/IRQ vectors, enough for
            # LC-detection probes. The machine normally passes the real ROM.
            self.rom = bytearray([0x60]) * 0x3000
            self.rom[0xFF3F - 0xD000:0xFF4A - 0xD000] = bytes.fromhex(
                "A54848A545A646A4472860")
            self.rom[0xFF4A - 0xD000:0xFF58 - 0xD000] = bytes.fromhex(
                "85458646844708688548BA8649D8")
            self.rom[0xFFFC - 0xD000] = 0x01           # reset -> $0801 boot
            self.rom[0xFFFD - 0xD000] = 0x08
            self.rom[0xFFFE - 0xD000] = 0x02           # IRQ/BRK -> $0002 trap
            self.rom[0xFFFF - 0xD000] = 0x00

        # power-on state: ROM read, bank 2, write enabled
        self.read_ram = False
        self.bank2 = True
        self.write_en = True
        self._prewrite = 0

    # -- soft switches ----------------------------------------------------
    def access(self, offset, is_read):
        """Any access to $C080+offset (offset 0-15). Returns the read value."""
        self.bank2 = (offset & 8) == 0
        self.read_ram = (offset & 3) in (0, 3)
        if offset & 1:
            if is_read:
                self._prewrite += 1
                if self._prewrite >= 2:
                    self.write_en = True
            else:
                self._prewrite = 0
        else:
            self._prewrite = 0
            self.write_en = False
        return 0x00

    # -- memory plane -----------------------------------------------------
    def read(self, addr):
        """Read $D000-$FFFF honoring the current bank state."""
        if self.read_ram:
            if addr < 0xE000 and not self.bank2:
                return self.bank1[addr - 0xD000]
            return self.mem[addr]
        return self.rom[addr - 0xD000]

    def write(self, addr, val):
        """Write $D000-$FFFF honoring write protection and bank select."""
        if not self.write_en:
            return
        if addr < 0xE000 and not self.bank2:
            self.bank1[addr - 0xD000] = val
        else:
            self.mem[addr] = val
