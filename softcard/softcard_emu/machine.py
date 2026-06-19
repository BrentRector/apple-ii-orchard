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


# Genuine Apple II+ motherboard ROM ($D000-$FFFF: Applesoft + Autostart
# monitor). The 6502 executes the real monitor routines (COUT1/HOME/CROUT/
# SAVE/RESTORE/...) the SoftCard's console handler calls, so no PC-hook
# stand-ins are needed. CRC32 F66F9C26 (reset vector $FFFC -> $FA62 = Autostart).
APPLE2_ROM_CANDIDATES = [
    Path(__file__).resolve().parent / "roms" / "apple2plus_rom_d000_ffff.bin",
]


def find_apple2_rom(explicit=None):
    """Locate the 12 KB Apple II+ $D000-$FFFF ROM image, or None."""
    if explicit:
        p = Path(explicit)
        return p if p.exists() else None
    for p in APPLE2_ROM_CANDIDATES:
        if p.exists():
            return p
    return None


class SoftCardMachine:
    """Boot a SoftCard CP/M disk image and interact with it.

    A SoftCard Apple is two processors taking turns on one bus: the 6502
    does all I/O, the Z-80 runs CP/M. This object composes the subsystems
    that model that machine -- the two CPU cores, the central memory
    ``Bus``, the ``LanguageCard``, the ``VidexVideoterm``, the
    ``Keyboard``, and the ``SoftCardSwitch`` -- and drives them with a
    cooperative scheduler (see ``run``): one CPU executes until it touches
    the SoftCard's slot page, which raises ``Yield`` and hands control to
    the other. The Apple monitor is the real $D000-$FFFF ROM, executed in
    place (no stand-in hooks); the two firmware pieces the emulator still
    services with PC breakpoints are the Disk II P6 PROM's sector read and
    the BIOS sector primitive (see the ``_install_*`` methods).

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
                 apple2_rom=None, slot=6):
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
        # Which SoftCard CP/M build? 2.20's RWTS read primitive is at a different
        # address than 2.23's, so the sector hook must be installed accordingly.
        self.variant = self._detect_variant(dsk_path)
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

        # Genuine Apple II+ motherboard ROM ($D000-$FFFF). Always mapped (a
        # real SoftCard Apple has it regardless of memory size); the 6502
        # executes the actual monitor routines the SoftCard console handler
        # calls, so no monitor PC-hook stand-ins are needed.
        rom_path = find_apple2_rom(apple2_rom)
        if rom_path is None:
            raise FileNotFoundError(
                "Apple II+ ROM ($D000-$FFFF) not found; pass apple2_rom= or "
                "place it at softcard_emu/roms/apple2plus_rom_d000_ffff.bin")
        self.apple2_rom = rom_path.read_bytes()        # 12 KB, $D000-$FFFF

        # Language card: present by default so CP/M sizes memory as on real
        # hardware (omitting it gives a flat 48K-style map). Either way the
        # motherboard ROM backs $D000-$FFFF (the LC overlays bankable RAM).
        self.lc = (LanguageCard(self.mem, rom=self.apple2_rom)
                   if language_card else None)

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
        #   3. the remaining PC hooks ($C800-fetch/sector) layer on. The Apple
        #      monitor is real ROM ($D000-$FFFF), executed in place -- no hooks.
        self._setup_boot()
        self.bus.attach_6502(self.m6502)
        self.bus.attach_z80(self.z)
        self._install_c8_pc_hooks()
        if sector_hook:
            self._install_sector_hook()

    # ------------------------------------------------------------------
    # boot-state setup (P6 PROM post-state + hooks)
    # ------------------------------------------------------------------
    def _setup_boot(self):
        """Cold-boot the machine exactly as a real Apple II+ does: enter the
        autostart ROM at its RESET vector and let it run.

        The autostart monitor brings the machine up itself -- SETNORM
        (INVFLG=$FF, normal video), INIT (text mode + 40-column window),
        SETVID/SETKBD (the COUT1/KEYIN I/O vectors), HOME -- prints "Apple ][",
        scans the slots, finds the Disk II, and JMPs its $Cn00 PROM, which
        reads track 0 sector 0 and runs the disk's bootstrap. Every ROM byte
        is real ($D000-$FFFF motherboard ROM, executed in place); the only
        firmware we still service with a hook is the Disk II P6 PROM's nibble
        read (p6_hook at $Cn5C), plus a one-shot $3E patch that keeps the
        disk's own slot scan deterministic. NOTHING about the post-RESET CPU
        or zero-page state is hand-seeded -- the ROM establishes all of it
        (which is why the screen, keyboard, and 6502<->Z-80 register-passing
        all work without the stand-in monitor hooks earlier versions needed).
        """
        mem = self.mem
        if self.lc is None:
            # Flat mode (no language card): no bankable RAM at $D000-$FFFF, so
            # the motherboard ROM sits in the plane directly (reads and fetches
            # both see it). With a language card the LanguageCard serves the
            # same ROM and overlays RAM banking on top.
            mem[0xD000:0x10000] = self.apple2_rom
        # KIL pad under a stray BRK (the real BRK/IRQ vectors live in ROM at
        # $FFFA-$FFFF; this is just defensive padding at $0002).
        mem[0x0002] = 0x02

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

        # Power-on reset: enter the ROM RESET routine. The autostart cold-start
        # path is selected when the power-up byte $03F4 != ($03F3 EOR $A5);
        # freshly-cleared RAM satisfies that, but force it so a re-run is cold.
        # The ROM RESET sets the stack, registers, and all of zero page itself
        # (SETNORM/INIT/SETVID/SETKBD/HOME), then scans slots and boots the
        # Disk II -- no post-PROM hand-seeding needed. (The reset vector reads
        # through the language card in ROM mode -- its power-on default -- or
        # straight from the plane in flat mode.)
        c = self.m6502
        rv = (self.lc.read(0xFFFC) | (self.lc.read(0xFFFD) << 8)) if self.lc \
            else (mem[0xFFFC] | (mem[0xFFFD] << 8))
        c.pc = rv
        c.sp = 0xFF
        c.a = c.x = c.y = 0
        mem[0x03F4] = 0x00                            # force autostart cold start
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

        # NB: the disk's boot-time slot scanner needs no help. It probes each
        # slot with a STA $Cn00; on the SoftCard's slot ($C700) that write
        # toggles the CPU (SoftCardSwitch.trigger_6502_write -- a true per-write
        # toggle, not gated to the warm loop), the Z-80 runs the boot's planted
        # handshake (SOFTCARD_PROBE_OVL at $1000: clears the $3E "found" flag and
        # bounces back via $En00), and the scanner reads $3E=0 -> SoftCard found.
        # A former patch_3e hook forced $3E=0 here to fake that detection back
        # when the switch was warm-loop-only; the faithful toggle retired it.

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
    # variant detection (which RWTS read primitive to hook)
    # ------------------------------------------------------------------
    @staticmethod
    def _detect_variant(dsk_path):
        """'220-44k' | '220' | '223' | None. 2.20-44K's runtime RWTS read
        primitive ($0E10) differs from 2.23's ($BE11), so the sector hook must
        match. Pattern-based (no assembler); falls back to None (-> 2.23 hook)."""
        try:
            from cpm_pipeline.reconstruct import _detect_variant
            return _detect_variant(dsk_path)
        except Exception:
            return None

    # sector-level disk service at the RWTS read primitive ($BE11 / $0E10)
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

        # 2.20-44K runs a different RWTS: its read primitive is RWTS_RW ($0E10),
        # which select/seek/reads the sector named by a DIFFERENT cell contract
        # than 2.23 -- but, like 2.23, the TRACK is in $03E0 (the IOB sector cell
        # at $03E1 is the CP/M-logical sector; $03E4 is the drive/command flag,
        # held constant at 1 by RWTS_TOP, NOT the track). The CP/M-logical sector
        # maps to physical via skew table $0F9D; dest is $03E8/$03E9. Verified
        # against the real RWTS_RW (CPM_BootLoader.s): the 28-sector system load
        # walks $03E0 = track 0 (sec $0B-$0F), track 1 (all), track 2 (sec
        # $00-$06). Reading the track from $03E4 (the old bug) pinned every read
        # to track 1, scrambling the load so the Z-80 ran garbage and halted.
        def rwts220_sector_hook(c):
            track = c.mem[0x03E0]
            sec_log = c.mem[0x03E1] & 0x0F
            phys = c.mem[0x0F9D + sec_log]            # CP/M-logical -> physical
            file_idx = self.interleave[phys]          # physical -> byte offset
            off = (track * 16 + file_idx) * 256
            dest = c.mem[0x03E8] | (c.mem[0x03E9] << 8)

            def ret(carry):                            # success = carry clear
                c.C = carry
                lo = c.mem[0x0100 + ((c.sp + 1) & 0xFF)]
                hi = c.mem[0x0100 + ((c.sp + 2) & 0xFF)]
                c.sp = (c.sp + 2) & 0xFF
                c.pc = (((hi << 8) | lo) + 1) & 0xFFFF
                return False

            if track >= 35 or off + 256 > len(self.disk_image):
                return ret(carry=1)
            c.mem[0x05F8] = c.mem[0x03E6]              # current slot*16 (bookkeeping)
            c.mem[0x03E5] = track                      # current track = target
            if dest + 256 <= 0x10000:
                c.mem[dest:dest + 256] = self.disk_image[off:off + 256]
            else:
                for i in range(256):
                    c.mem[(dest + i) & 0xFFFF] = self.disk_image[off + i]
            self.disk_reads.append((track, sec_log, phys, dest))
            return ret(carry=0)

        if self.variant == "220-44k":
            self.m6502.add_breakpoint(0x0E10, rwts220_sector_hook)
        else:
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
