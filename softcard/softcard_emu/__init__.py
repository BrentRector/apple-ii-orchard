"""
softcard_emu -- a Microsoft SoftCard CP/M system emulator.

Boots an unmodified SoftCard CP/M disk image (.dsk DOS 3.3 order or
.po ProDOS order) from the Disk II PROM's first sector read all the
way to an interactive A> prompt, with both CPUs modeled:

  * 6502 (nibbler.cpu) and Z-80 (nibbler.z80_cpu) sharing one 64 KB
    Apple memory image
  * the SoftCard's documented Z-80->Apple address translation and its
    bidirectional CPU switch (any access to the card's slot page)
  * Disk II controller with a track/sector bypass that services reads
    straight from the disk image (the full synthetic-nibble RWTS path
    remains available)
  * Videx Videoterm: real firmware ROM execution, CRTC register file,
    paged 2 KB VRAM, and faithful $C800-$CFFF expansion-ROM window
    arbitration (the instrument behind wiseowl.com's softcard-videx
    series, Part 5)
  * Apple language card: ROM/RAM banking at $D000-$FFFF with the
    standard $C080-$C08F soft switches, so CP/M's memory sizing
    matches real hardware

Quick start:

    from softcard_emu import SoftCardMachine
    m = SoftCardMachine("CPMV223-44K.DSK")
    m.type_keys("DIR\\r")
    m.run()
    print("\\n".join(m.screen_text()))

CLI:

    python -m softcard_emu CPMV223-44K.DSK --keys "DIR\\r"

Architecture: the machine is a thin composition of independent
subsystems, each in its own module:

  * Bus (bus.py) -- the central memory/bus; every CPU read/write/fetch
    flows through it, and it alone resolves the address map (LC banking,
    slot ROM, $C800 window ownership, soft switches).
  * Cpu6502 / Z80 (cpus.py) -- the two processor subsystems wrapping the
    reusable nibbler cores.
  * LanguageCard (langcard.py), VidexVideoterm (videx.py),
    Keyboard (keyboard.py), SoftCardSwitch (switch.py) -- the devices
    whose live state the bus consults.

SoftCardMachine (machine.py) constructs these, wires the bus to the
CPUs, installs the boot/monitor/sector PC hooks, and runs the
CPU-alternation loop.
"""

from .machine import SoftCardMachine, realmap
from .bus import Bus
from .cpus import Cpu6502, Z80
from .langcard import LanguageCard
from .videx import VidexVideoterm
from .keyboard import Keyboard
from .switch import SoftCardSwitch, Yield

__version__ = "1.1.0"
__all__ = [
    "SoftCardMachine", "realmap", "Bus", "Cpu6502", "Z80",
    "LanguageCard", "VidexVideoterm", "Keyboard", "SoftCardSwitch",
    "Yield", "__version__",
]
