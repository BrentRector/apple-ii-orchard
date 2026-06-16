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

_REPO_ROOT = Path(__file__).resolve().parent.parent  # softcard/
# nibbler lives in the shared/ tree; softcard/ stays on path for sibling packages.
for _p in (_REPO_ROOT, _REPO_ROOT.parent / "shared"):
    if str(_p) not in sys.path:
        sys.path.insert(0, str(_p))

from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

from .langcard import LanguageCard
from .videx import VidexVideoterm, find_videx_rom
from .switch import SoftCardSwitch, Yield, realmap   # realmap re-exported
from .keyboard import Keyboard
from .cpus import Cpu6502, Z80
from .bus import Bus


# Apple text page 1: row -> base address (the classic interleave)
def _text40_row_base(row):
    return 0x400 + (row % 8) * 0x80 + (row // 8) * 0x28


class SoftCardMachine:
    """Boot a SoftCard CP/M disk image and interact with it.

    A SoftCard Apple is two processors taking turns on one bus: the 6502
    does all I/O, the Z-80 runs CP/M. This object composes the subsystems
    that model that machine -- the two CPU cores, the central memory
    ``Bus``, the ``LanguageCard``, the ``VidexVideoterm``, the
    ``Keyboard``, and the ``SoftCardSwitch`` -- and drives them with a
    cooperative scheduler (see ``run``): one CPU executes until it touches
    the SoftCard's slot page, which raises ``Yield`` and hands control to
    the other. Firmware the emulator does not load as ROM (the Apple
    monitor, the Disk II PROM, the BIOS sector primitive) is serviced by
    PC breakpoints installed at boot; see the ``_install_*`` methods.

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
        # Storage order is inferred from the extension: .po images are in
        # ProDOS sector order, everything else (.dsk) in DOS 3.3 order.
        # The interleave table maps a logical sector to its byte offset
        # within a track in the file (the on-disk skew is applied on top).
        interleave = 'prodos' if dsk_path.lower().endswith('.po') else 'dos33'
        self.interleave = (PRODOS_INTERLEAVE if interleave == 'prodos'
                           else DOS33_INTERLEAVE)
        with open(dsk_path, 'rb') as f:
            self.dsk_bytes = f.read()
        # dsk_bytes is the pristine image (read-only reference); disk_image
        # is the runtime-writable copy the sector hook reads from and writes
        # back to, so a guest can modify its own disk (e.g. CPM60.COM).
        self.disk_image = bytearray(self.dsk_bytes)
        self.slot = slot

        # The one 64 KB Apple memory plane. Both CPUs and the language card
        # share THIS exact bytearray, so a write through any of them is
        # visible to all (the bus is the single arbiter of who answers).
        self.mem = bytearray(65536)

        # CPU subsystems (the instruction-set cores live in nibbler; these
        # adapters own them and fix their machine-specific construction).
        self.cpu6502 = Cpu6502(self.mem, self.dsk_bytes,
                               slot=slot, interleave=interleave)
        self.m6502 = self.cpu6502.cpu          # public-API handle (the core)
        self.z80 = Z80()
        self.z = self.z80.cpu                  # public-API handle (the core)

        self.switch = SoftCardSwitch()         # CPU-switch policy + counters
        self.kbd = Keyboard()                  # keyboard latch + poll counters

        self.disk_reads = []          # (track, sector_logical, phys, dest)
        self.disk_writes = []         # same, for sector-hook writes

        # Language card: present by default so CP/M sizes memory as on real
        # hardware (omitting it gives a flat 48K-style map).
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

        # Central memory/bus: every CPU read/write/fetch flows through it,
        # and it alone resolves the address map by consulting the devices
        # composed above (lc/videx/kbd/switch).
        self.bus = Bus(self.mem, lc=self.lc, videx=self.videx,
                       kbd=self.kbd, switch=self.switch)

        # Wiring order is load-bearing:
        #   1. _setup_boot seeds memory + the boot PC hooks (it must run
        #      while m6502.read/write are still the cores' native methods,
        #      so attach_6502 below can capture them as the flat fallthrough).
        #   2. attach_* points the cores' memory hooks at the bus.
        #   3. the remaining PC hooks (monitor/$C800-fetch/sector) layer on.
        self._setup_boot()
        self.bus.attach_6502(self.m6502)
        self.bus.attach_z80(self.z)
        self._install_monitor_hooks()
        self._install_c8_pc_hooks()
        if sector_hook:
            self._install_sector_hook()

    # ------------------------------------------------------------------
    # boot-state setup (P6 PROM post-state + hooks)
    # ------------------------------------------------------------------
    def _setup_boot(self):
        """Seed memory and the 6502 to the state just after the Disk II
        PROM has read track 0, sector 0, and is about to run it.

        Rather than emulate the PROM's nibble decode, we drop the first
        sector at $0800 (where the PROM loads it) and reproduce the
        documented post-PROM register/zero-page state, then let the disk's
        own bootstrap take over. A handful of PC hooks stand in for ROM the
        emulator does not carry: the P6 PROM's sector read, the Apple
        monitor (see ``_install_monitor_hooks``), and a one-shot patch to
        the slot scanner.
        """
        mem = self.mem
        mem[0x0800:0x0900] = self.dsk_bytes[:256]   # track 0 sector 0 -> $0800

        if self.lc is None:
            # Flat mode (no language card): the monitor entries are RAM, so
            # seed them with RTS ($60). The PC hooks below make execution
            # there a no-op anyway, but a *data* read of these addresses
            # (e.g. a checksum) should see ROM-like bytes, not $00.
            for addr in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                         0xFD8E, 0xFDED, 0xFD0C, 0xFF65, 0xFF4A, 0xFF3F):
                mem[addr] = 0x60
            # Reset/IRQ vectors: reset -> $0801 boot entry, IRQ/BRK -> $0002.
            mem[0xFFFC:0x10000] = bytes([0x01, 0x08, 0x02, 0x00])
        # Trap stray BRK/IRQ: the vector points at $0002, where $02 is a KIL
        # opcode that halts the 6502 -- so a wild jump surfaces as a clean
        # stop instead of running off into noise.
        mem[0x0002] = 0x02
        mem[0xFFFE] = 0x02
        mem[0xFFFF] = 0x00

        # Disk II P6 state-machine PROM, loaded at the slot's $Cn00 page so
        # any code that reads it sees real bytes. The actual sector read is
        # serviced by the p6_hook below (at $Cn5C), so the PROM image is
        # optional -- load it if we have it, otherwise the hook still works.
        for rom_dir in (Path(__file__).resolve().parent / "roms",
                        _REPO_ROOT / "cpm-investigation" / "roms"):
            p = rom_dir / "disk2_p6.bin"
            if p.exists():
                base = 0xC000 | (self.slot << 8)
                rom = p.read_bytes()
                mem[base:base + len(rom)] = rom
                break

        # Mirror the Videx firmware into the flat plane at its slot ROM
        # ($C300) and expansion ROM ($C800) windows. This is needed because
        # 6502 instruction FETCHES read the flat plane directly (the core
        # fetches via mem[pc]/the fetch hook, which is flat below $D000),
        # and both console paths execute Videx firmware at $C3xx/$C8xx.
        # DATA reads of these addresses still go through the bus and are
        # gated by $C800 ownership; fetch-side ownership faults are detected
        # by the PC hooks in _install_c8_pc_hooks. (rom[768:1024] is the
        # last 256 bytes, which also appear as the $C3xx slot ROM.)
        if self.videx:
            mem[0xC300:0xC400] = self.videx.rom[768:1024]
            mem[0xC800:0xCC00] = self.videx.rom[0:1024]

        # Post-PROM 6502 state (Apple Disk II boot convention):
        #   PC=$0801  entry just past the sector-0 length byte at $0800
        #   X = slot*16 ($n0) so $Cn page code can index its soft switches
        #   SP=$FD    the PROM has pushed a couple of bytes
        c = self.m6502
        c.pc = 0x0801
        c.x = self.slot * 16
        c.sp = 0xFD
        c.a = 0
        c.y = 0
        # Zero-page the boot reads:
        #   $2B  the slot the boot came from, as $n0 (Disk II convention)
        #   $26/$27  RWTS-style destination pointer (lo/hi); next read lands
        #            at $0900 and walks upward sector by sector
        #   $3D  current sector number for the p6_hook to fetch
        mem[0x2B] = self.slot * 16
        mem[0x26] = 0x00
        mem[0x27] = 0x09
        mem[0x3D] = 0x01
        c.disk.motor_on = True
        c.disk.current_qtrack = 0

        # P6 PROM read hook at $Cn5C: stands in for the PROM's read-sector
        # routine. Reads "sector $3D of the current track" from the image
        # into the $26/$27 destination, bumps the destination high byte to
        # the next page, and resumes the bootstrap at $0801.
        def p6_hook(cpu):
            target_sector = cpu.mem[0x3D]
            dest = cpu.mem[0x26] | (cpu.mem[0x27] << 8)
            track = cpu.disk.current_qtrack // 4     # 4 quarter-tracks/track
            logical = self.interleave[target_sector]
            off = (track * 16 + logical) * 256
            for i, b in enumerate(self.dsk_bytes[off:off + 256]):
                cpu.mem[(dest + i) & 0xFFFF] = b
            cpu.mem[0x27] = (cpu.mem[0x27] + 1) & 0xFF   # advance to next page
            cpu.pc = 0x0801
            return False
        c.add_breakpoint(0xC000 | (self.slot << 8) | 0x5C, p6_hook)

        # The boot's slot scanner walks $3E as a loop counter; on real
        # hardware its first iteration starts from an indeterminate value
        # that the PROM left set. Force $3E=0 on the first pass through the
        # scanner so the count is deterministic (derivation in
        # cpm-investigation/emu_softcard.py). 2.20 and 2.23 put the scanner
        # at slightly different addresses, so patch both.
        fired = [False]
        def patch_3e(cpu):
            if not fired[0]:
                cpu.mem[0x3E] = 0
                fired[0] = True
            return False
        c.add_breakpoint(0x106A, patch_3e)
        c.add_breakpoint(0x1063, patch_3e)

    # ------------------------------------------------------------------
    # monitor entries as PC hooks ("run from ROM" regardless of RAM)
    # ------------------------------------------------------------------
    def _install_monitor_hooks(self):
        """Stand in for the Apple II monitor ROM, which we do not load.

        The SoftCard BIOS runs console I/O on the 6502 side and calls
        monitor ROM routines to do it. We don't carry that ROM, so we
        intercept its entry points as PC breakpoints. Two of them are
        load-bearing and implemented faithfully -- SAVE/RESTORE, because
        the BIOS's two-processor register-passing protocol round-trips the
        registers through the $45-$48 save area (see the softcard-videx
        series, Part 4). The rest are stubbed to a clean RTS: their screen
        side effects either don't matter to the boot path or are produced
        elsewhere (the Videx firmware, or the 40-column text page).
        """
        # A faithful RTS that does not need a real ROM byte to execute:
        # pull the return address off the stack and resume past it.
        def mon_rts(cpu):
            lo = cpu.mem[0x0100 + ((cpu.sp + 1) & 0xFF)]
            hi = cpu.mem[0x0100 + ((cpu.sp + 2) & 0xFF)]
            cpu.sp = (cpu.sp + 2) & 0xFF
            cpu.pc = (((hi << 8) | lo) + 1) & 0xFFFF
            return False

        def mon_save(cpu):                 # $FF4A SAVE: A,X,Y,P,SP -> $45-$49
            cpu.mem[0x45] = cpu.a
            cpu.mem[0x46] = cpu.x
            cpu.mem[0x47] = cpu.y
            cpu.mem[0x48] = cpu._get_p()
            cpu.mem[0x49] = cpu.sp
            cpu.D = 0                       # SAVE also clears decimal mode
            return mon_rts(cpu)

        def mon_restore(cpu):              # $FF3F RESTORE: $45-$48 -> A,X,Y,P
            cpu._set_p(cpu.mem[0x48])
            cpu.a = cpu.mem[0x45]
            cpu.x = cpu.mem[0x46]
            cpu.y = cpu.mem[0x47]
            return mon_rts(cpu)

        self.m6502.add_breakpoint(0xFF4A, mon_save)
        self.m6502.add_breakpoint(0xFF3F, mon_restore)
        # Stubbed monitor routines (canonical Apple II monitor names):
        #   FF58 a guaranteed RTS    FCA8 WAIT (delay)      FF2D PRERR
        #   FB2F INIT/SETTXT setup   FE89 SETKBD            FE93 SETVID
        #   FD8E CROUT (CR out)      FDED COUT (char out)   FD0C RDKEY
        #   FF65 MON (monitor warm)  FC58 HOME (clear)      FC22 VTAB
        #   FC42 (cursor/clear)      FC9C CLREOL            FC70 SCROLL
        #   FB39 (text mode setup)   FDF0 COUT1 (screen char out)
        for entry in (0xFF58, 0xFCA8, 0xFF2D, 0xFB2F, 0xFE89, 0xFE93,
                      0xFD8E, 0xFDED, 0xFD0C, 0xFF65,
                      0xFC58, 0xFC22, 0xFC42, 0xFC9C, 0xFC70, 0xFB39,
                      0xFDF0):
            self.m6502.add_breakpoint(entry, mon_rts)

    # ------------------------------------------------------------------
    # instruction-fetch coverage for $C100-$CFFF (fetches bypass read())
    # ------------------------------------------------------------------
    def _install_c8_pc_hooks(self):
        """Extend $C800-window ownership tracking to instruction fetches.

        The bus tracks window ownership on every DATA access to $C100-$CFFF,
        but a 6502 *instruction fetch* reads the flat plane and never calls
        the bus -- so executing firmware in the expansion-ROM window would
        otherwise escape ownership accounting. We cover that by breaking on
        every PC in $C100-$CFFF: each fetch updates ownership (a $C3xx fetch
        claims, etc.) and, if PC is in the shared $C800 window while the
        Videx does not own it, records a fault -- the exact event that kills
        2.20 (see Part 5). Only meaningful under faithful arbitration; a
        permissive (always-mapped) window has no ownership to track.
        """
        if not self.videx or not self.videx.arbitrate:
            return

        def c8_pc_hook(cpu):
            self.videx.track(cpu.pc, '6502-fetch', cpu.pc)
            if cpu.pc >= 0xC800 and not self.videx.c8_owner:
                self.videx.fault('6502-fetch', cpu.pc, cpu.pc)
            return False

        # Only one callback per address, so if a boot/monitor hook already
        # lives in this range, chain ours in front of it rather than clobber
        # it. (Today none overlap, but the chaining keeps it correct if one
        # ever does -- e.g. a monitor entry that falls inside $C100-$CFFF.)
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
        """Service runtime disk I/O directly from the image at the BIOS's
        sector primitive ($BE11 in 2.23's RWTS).

        Once CP/M is running, every disk read or write funnels through this
        one routine. Hooking it lets us move 256 bytes straight between the
        image and RAM -- skipping the nibble encode/decode -- which is fast
        and, critically, lets a guest WRITE its own disk: CPM60.COM's 60K
        conversion persists here, into ``disk_image``. Pass
        ``sector_hook=False`` to instead run the preserved RWTS against
        synthetic nibble streams (slower, used for fidelity runs).

        2.20's RWTS lives at different addresses and never reaches $BE11, so
        on a 2.20 disk this hook simply never fires.
        """
        # Live RWTS state block (contract from docs/CPM223_RWTS.asm):
        #   $03E0       track
        #   $03E1       sector, CP/M-logical (physical via skew table $BF9E)
        #   $03E4       drive select (bit 0 = drive 1 present)
        #   $03E8/$03E9 destination pointer (lo/hi)
        #   $03EB       command (bit 0 = read, else write)
        #   $03EA       result code (out); carry (out) = error
        #   $0478       per-drive current track (head position)
        def rwts_sector_hook(c):
            track = c.mem[0x03E0]
            sec_log = c.mem[0x03E1] & 0x0F
            phys = c.mem[0xBF9E + sec_log]            # CP/M-logical -> physical
            file_idx = self.interleave[phys]          # physical -> byte offset
            off = (track * 16 + file_idx) * 256
            dest = c.mem[0x03E8] | (c.mem[0x03E9] << 8)

            # Return to the caller as the real primitive would: set the
            # result code and carry, then pop the return address and resume
            # past it (carry clear = success, set = error code in $03EA).
            def ret(carry, err):
                c.mem[0x03EA] = err
                c.C = carry
                lo = c.mem[0x0100 + ((c.sp + 1) & 0xFF)]
                hi = c.mem[0x0100 + ((c.sp + 2) & 0xFF)]
                c.sp = (c.sp + 2) & 0xFF
                c.pc = (((hi << 8) | lo) + 1) & 0xFFFF
                return False

            if not (c.mem[0x03E4] & 1):
                return ret(carry=1, err=0x40)         # drive 2: not present
            if track >= 35 or off + 256 > len(self.disk_image):
                return ret(carry=1, err=0x40)         # off the end of the disk

            # Mirror the bookkeeping the real RWTS updates on a good seek.
            c.mem[0x0478] = track
            c.mem[0x03E7] = c.mem[0x03E6]
            c.mem[0x03E5] = c.mem[0x03E4]

            if c.mem[0x03EB] & 1:                     # read: image -> RAM
                if dest + 256 <= 0x10000:
                    c.mem[dest:dest + 256] = self.disk_image[off:off + 256]
                else:                                 # wrap at the top of RAM
                    for i in range(256):
                        c.mem[(dest + i) & 0xFFFF] = self.disk_image[off + i]
                self.disk_reads.append((track, sec_log, phys, dest))
            else:                                     # write: RAM -> image
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
        self.kbd.type_keys(text)

    inject_keys = type_keys              # emu_softcard_v2 compatibility

    def run(self, total_steps=80_000_000, z80_slice=2_000_000,
            m6502_slice=2_000_000):
        """Run the two-CPU machine until it goes idle or the budget runs out.

        The scheduler is cooperative: the active CPU executes a slice at a
        time, and a slice ends one of three ways. A ``Yield`` (raised by the
        bus on a SoftCard slot-page access) means "switch processors" -- we
        hand control to the other CPU and resume there. Hitting the slice's
        instruction ``limit`` without yielding means the CPU is spinning;
        if it has been hammering the keyboard ($C000) with nothing queued,
        that's the console input loop and we report the machine idle. Any
        other stop (``halt``) is an error we surface with the PC.

        Args:
            total_steps: combined instruction budget across both CPUs; the
                ceiling on a run that never goes idle.
            z80_slice / m6502_slice: instructions per slice before yielding
                back to the scheduler to re-check stop conditions.

        Returns:
            A short status string. 'z80-idle (keyboard poll)' / '6502-idle
            (keyboard poll)' mean the system is waiting at the console --
            the healthy interactive state. '... stopped: halt ...' and
            'Z-80 error ...' are failures. 'step budget spent' means it ran
            the full budget without going idle.
        """
        active = '6502'                 # the 6502 owns the bus at cold start
        spent = 0
        while spent < total_steps:
            if active == '6502':
                # Resume past the store that triggered the last switch back.
                if self.switch.resume_6502 is not None:
                    self.m6502.pc = self.switch.resume_6502
                    self.switch.resume_6502 = None
                before = self.m6502.exec_count
                polls_before = self.kbd.polls_6502
                try:
                    r = self.m6502.run(max_instructions=m6502_slice,
                                       progress_interval=0)
                except Yield:
                    r = 'switch'
                spent += self.m6502.exec_count - before
                if r == 'switch':
                    self.switch.note_switch()
                    self.switch.on_first_z80_start(self.z)  # cold-start once
                    active = 'z80'
                    continue
                if r == 'limit':
                    # Spinning on the keyboard with nothing to give = idle.
                    if (not self.kbd.queue
                            and self.kbd.polls_6502 - polls_before > 1000):
                        return '6502-idle (keyboard poll)'
                    continue                                # still busy
                return f"6502 stopped: {r} at PC=${self.m6502.pc:04X}"
            else:
                before = self.z.exec_count
                try:
                    r = self.z.run(max_instructions=z80_slice,
                                   progress_interval=0)
                except Yield:
                    r = 'switch'
                except Exception as e:
                    # The Z-80 core raises on a genuinely unknown opcode;
                    # report it with the PC rather than crash the harness.
                    return f"Z-80 error at PC=${self.z.pc:04X}: {e}"
                spent += self.z.exec_count - before
                if r == 'switch':
                    self.switch.note_switch()
                    active = '6502'
                    continue
                if r == 'limit':
                    # The Z-80 reaches the console wait via the 6502 (it has
                    # no keyboard of its own), so any prior poll + an empty
                    # queue is enough to call it idle here.
                    if self.kbd.polls_z80 > 0 and not self.kbd.queue:
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
    def switches(self):
        return self.switch.switches

    @property
    def c8_fault_count(self):
        return self.videx.fault_count if self.videx else 0
