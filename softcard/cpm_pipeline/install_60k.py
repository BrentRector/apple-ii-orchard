"""Produce the 2.23-60K disk by RUNNING the byte-built CPM60.COM installer.

The 60K disk is not a static chunk-map reconstruction: it is exactly what Microsoft's
CPM60.COM in-place updater writes to a 2.23-44K disk's system tracks. softcard_emu
drives the real 6502 + Z-80 install (CPM60.COM validates the disk through the BDOS,
raw-writes its embedded 60K image via the RWTS bridge, then hands off to the cold-boot
relocator), and the guest disk-writes persist into the emulator's disk image.

Every byte of the result therefore traces to source: CPM60.COM is built byte-identically
from CPMV223-60K/CPM60.asm (see build_cpm60), and the carrier is the archived 2.23-44K
release disk. The filesystem (tracks 3+) is untouched; only the system tracks change.
The output is byte-identical to the committed CPMV223-60K-EMU.DSK.
"""

from __future__ import annotations

from pathlib import Path

from .reference_data import DISK_2_23_44K_SYSTEM


def build_60k_disk_via_installer(src_44k: Path | str | None = None, *,
                                 launch_steps: int = 15_000_000,
                                 write_steps: int = 20_000_000) -> bytes:
    """Run CPM60.COM on a 2.23-44K disk in softcard_emu; return the written 60K image.

    Boots ``src_44k`` (default: the archived 2.23-44K system), runs ``CPM60``, answers
    its "Press RETURN to begin" prompt, and lets the installer raw-write the embedded 60K
    system onto the disk's system tracks. Returns the 143360-byte disk image the installer
    produced (the guest writes persist into ``machine.disk_image``).
    """
    from softcard_emu import SoftCardMachine
    src = str(src_44k) if src_44k is not None else str(DISK_2_23_44K_SYSTEM)
    m = SoftCardMachine(src)
    m.run()                                    # boot to A>
    m.type_keys("CPM60\r")                     # launch the installer
    m.run(total_steps=launch_steps)            # -> "Insert 16 sector disk ... Press RETURN to begin"
    m.type_keys("\r")                          # begin: raw-write the 60K system tracks
    m.run(total_steps=write_steps)             # (the console key-wait spins, so budget-bounded)
    return bytes(m.disk_image)
