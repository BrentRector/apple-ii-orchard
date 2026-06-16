"""SoftCard CPU-switch subsystem.

A SoftCard-equipped Apple is two CPUs taking turns on one bus. Any
access to the card's slot page hands the machine to the other CPU.
This module owns that policy in one place:

  * ``realmap`` -- the documented SoftCard Z-80 -> Apple address
    translation (lives here because the switch is the SoftCard's
    defining behavior; the bus and machine import it).
  * ``Yield`` -- raised inside a bus access to unwind out to the
    CPU-alternation loop in machine.run().
  * ``SoftCardSwitch`` -- decides whether an access triggers a switch,
    computes the 6502 resume address, and tracks switch bookkeeping.

The trigger conditions are exactly those discovered for real hardware:
the 6502 switches on a *warm-loop* store to the card's slot page
($C7xx, or $C4xx in 2.20's image before the scanner patches it) while
PC is still in the warm loop (< $0400); the Z-80 switches on any access
whose translated address lands in the $C700 page.
"""


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
    """Raised inside a bus access to hand the bus to the other CPU."""


class SoftCardSwitch:
    """CPU-switch policy and bookkeeping for the SoftCard."""

    def __init__(self):
        self.resume_6502 = None      # 6502 PC to resume at after a switch back
        self.z80_started = False     # has the Z-80 been cold-started yet?
        self.switches = 0            # total CPU switches (both directions)

    def trigger_6502_write(self, addr, pc, mem_peek):
        """True if a 6502 write to ``addr`` at ``pc`` triggers a switch.

        On a trigger, records ``resume_6502``: the warm loop's store to
        the slot page is a 3-byte ``STA abs`` ($8D) when it switches, so
        the 6502 must resume *past* that instruction (pc+3); any other
        opcode resumes at pc. ``mem_peek(pc)`` reads the opcode (low
        memory, always the flat plane).
        """
        if ((addr & 0xFF00) == 0xC700 or (addr & 0xFF00) == 0xC400) \
                and pc < 0x0400:
            self.resume_6502 = (pc + 3) & 0xFFFF if mem_peek(pc) == 0x8D else pc
            return True
        return False

    def is_z80_switch(self, ap):
        """True if a Z-80 access to translated address ``ap`` switches CPUs."""
        return (ap & 0xFF00) == 0xC700

    def note_switch(self):
        """Count one CPU switch."""
        self.switches += 1

    def on_first_z80_start(self, z):
        """Cold-start the Z-80 at $0000 the first time control reaches it."""
        if not self.z80_started:
            z.pc = 0x0000
            z.sp = 0x0000
            self.z80_started = True
