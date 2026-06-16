"""CPU subsystems for the SoftCard machine.

The 6502 and Z-80 instruction-set cores live in the shared ``nibbler``
package. These thin adapters make each CPU a first-class subsystem on
the softcard_emu side: they own the core instance, fix its machine-
specific construction (the 6502's memory plane and Disk II controller),
and expose it as ``.cpu`` for the bus to attach memory hooks to and for
the machine to drive in its CPU-alternation loop.

Keeping these as explicit subsystems (rather than constructing bare
cores in the machine) gives the bus and machine one obvious seam per
processor and leaves the reusable cores in nibbler untouched.
"""

from nibbler.cpu import CPU6502
from nibbler.z80_cpu import Z80CPU
from nibbler.dsk_disk import DSKDisk


class Cpu6502:
    """The Apple's native 6502: runs all I/O, including the Disk II.

    Owns the core, points it at the shared 64 KB plane, and attaches a
    Disk II controller over the boot disk image.
    """

    def __init__(self, mem, dsk_bytes, *, slot=6, interleave='dos33'):
        self.cpu = CPU6502(slot=slot)
        self.cpu.mem = mem
        self.cpu.disk = DSKDisk(dsk_bytes, interleave=interleave)


class Z80:
    """The SoftCard's Z-80: runs CP/M, sharing the Apple's memory.

    Owns the core; the bus installs its read/write hooks (which apply
    the SoftCard address translation) via Bus.attach_z80.
    """

    def __init__(self):
        self.cpu = Z80CPU()
