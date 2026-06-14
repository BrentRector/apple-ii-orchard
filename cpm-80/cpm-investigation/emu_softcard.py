"""
SoftCard CP/M boot emulator (Stage 1 -- 6502-only).

Boots a SoftCard CP/M disk image (.dsk or .po) using the existing
nibbler 6502 emulator with a synthetic GCR nibble stream backed by the
sector-order image. Stops at the moment the 6502 would hand off to the
Z-80 -- typically when JSR $0E36 is about to execute Z-80 instructions
that the 6502 disassembles as nonsense.

This stage answers: how does the BIOS cold-boot prelude at Apple
$FA00-$FAB7 get populated before the Z-80 first executes there?
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from nibbler.cpu import CPU6502
from nibbler.dsk_disk import DSKDisk


def _read_sector_from_dsk(disk_bytes, track, phys_sector, interleave_table):
    """Return the 256 bytes of physical (track, phys_sector) from a sector-order
    .dsk/.po image."""
    logical = interleave_table[phys_sector]
    off = (track * 16 + logical) * 256
    return disk_bytes[off:off + 256]


def install_scan_init_patch(cpu):
    """
    Force `$3E = 0` immediately after stage-2 sets it to `$FF` at `$105E`.

    The slot scanner at `$1060-$10D5` has an apparent dead-code path:
    `SCAN_INIT_SLOT` at `$1086` (the only place that increments `$3E`) is
    only reached via `BEQ $1086` when `$3E = 0`, but `$3E` is initialized
    to `$FF` at `$105E` and no other code clears it. Without that init
    happening, the `LDA $3E; CMP #$01` post-scan check fails and stage-2
    drops to MONITOR.

    This patch fires at `$1060` (immediately after the STY) and forces
    `$3E = 0` so the first scan iteration takes the SCAN_INIT_SLOT path.
    On real hardware some other mechanism must set `$3E = 0` -- possibly a
    Pascal-firmware-card slot-ROM byte that the CKSUM happens to write to
    `$3E` when summed, or the SoftCard's CPU-switch flip-flop side effect.
    Without that mechanism we patch externally.
    """
    def hook(c):
        c.mem[0x3E] = 0
        return False
    cpu.add_breakpoint(0x1060, hook)


def install_p6_prom_hook(cpu, dsk_bytes, interleave_table, slot=6):
    """
    Install a breakpoint at $Cn5C (mid-routine entry of the Disk II P6 PROM)
    that synthesizes a sector read directly from the .dsk image.

    The boot stub does JMP ($003E) where ($003E) = $C65C; the real PROM at
    $C65C searches the disk for a sector matching $3D, reads its data field
    into memory at ($26), increments $27, then JMPs to $0801. Our hook
    matches that behavior without needing to emulate ROM execution.
    """
    base = 0xC000 | (slot << 8)
    entry = base | 0x5C  # e.g. $C65C for slot 6

    def hook(c):
        target_sector = c.mem[0x3D]
        dest_lo = c.mem[0x26]
        dest_hi = c.mem[0x27]
        dest = (dest_hi << 8) | dest_lo
        track = c.disk.current_qtrack // 4
        sector_bytes = _read_sector_from_dsk(
            dsk_bytes, track, target_sector, interleave_table)
        for i, b in enumerate(sector_bytes):
            c.mem[(dest + i) & 0xFFFF] = b
        # The P6 PROM's "JMP $0801" tail: increment $27, then PC = $0801.
        c.mem[0x27] = (c.mem[0x27] + 1) & 0xFF
        c.pc = 0x0801
        return False  # don't stop execution

    cpu.add_breakpoint(entry, hook)
    return entry


P6_BOOT_BYTES = bytes([])


def setup_softcard_boot(dsk_path, *, slot=6, interleave='dos33', volume=254):
    """Set up a 6502 + DSKDisk pair ready to run the SoftCard CP/M boot."""
    from nibbler.gcr import DOS33_INTERLEAVE, PRODOS_INTERLEAVE

    if dsk_path.lower().endswith('.po'):
        interleave = 'prodos'
    il = PRODOS_INTERLEAVE if interleave == 'prodos' else DOS33_INTERLEAVE

    with open(dsk_path, 'rb') as f:
        dsk_bytes = f.read()

    disk = DSKDisk(dsk_bytes, interleave=interleave, volume=volume)
    cpu = CPU6502(slot=slot)
    cpu.disk = disk

    # Sector 0 of track 0 -> $0800 (P6 PROM does this for real; we shortcut).
    cpu.mem[0x0800:0x0900] = dsk_bytes[:256]
    install_p6_prom_hook(cpu, dsk_bytes, il, slot=slot)
    install_scan_init_patch(cpu)

    # Apple monitor stubs -- standard P6 boot environment + stage-2 needs.
    for addr in (
        0xFF58,  # IORTS
        0xFCA8,  # WAIT
        0xFF2D,  # PRERR ("ERR" + bell)
        0xFB2F,  # TEXT (set text mode)
        0xFE89,  # SETKBD
        0xFE93,  # SETVID
        0xFD8E,  # CROUT (carriage return)
        0xFDED,  # COUT (output char)
        0xFD0C,  # RDKEY (read key)
        0xFF65,  # MONITOR (drop-to-monitor)
        0xFF4A,  # SAVE (save 6502 state)
        0xFF3F,  # RESTORE
    ):
        cpu.mem[addr] = 0x60     # RTS stubs
    # BRK vector -> $0002 = KIL so we halt cleanly on stray BRK.
    cpu.mem[0xFFFE] = 0x02
    cpu.mem[0xFFFF] = 0x00
    cpu.mem[0x0002] = 0x02

    # Reset/NMI vectors -> harmless.
    cpu.mem[0xFFFC] = 0x00
    cpu.mem[0xFFFD] = 0x08

    cpu.pc = 0x0801
    cpu.x = slot * 16
    cpu.sp = 0xFD
    cpu.a = 0
    cpu.y = 0
    cpu.mem[0x2B] = slot * 16
    # P6 PROM post-state: it loaded sector 0 -> $0800, so $27 (next page) = $09.
    # The boot stub at $0801 reads $27 to decide init vs. skip-init path.
    cpu.mem[0x26] = 0x00
    cpu.mem[0x27] = 0x09
    cpu.mem[0x3D] = 0x01  # P6 had just loaded sector 1's slot value
    disk.motor_on = True
    disk.current_qtrack = 0

    # Install the real Disk II P6 PROM bytes at $Cn00-$CnFF for the current
    # slot. Stage-2's slot scanner checksums each slot's ROM page; an
    # all-zero page makes the post-scan dispatch take the multi-card error
    # branch instead of DISPATCH_OK.
    rom_path = Path(__file__).resolve().parent / 'roms' / 'disk2_p6.bin'
    if rom_path.exists():
        rom_bytes = rom_path.read_bytes()
        slot_base = 0xC000 | (slot << 8)
        for i, b in enumerate(rom_bytes):
            cpu.mem[slot_base + i] = b
    return cpu, disk


def install_write_logger(cpu, regions):
    """
    Install hooks logging every write to specified address regions.

    Args:
        cpu: CPU6502 instance.
        regions: list of (lo, hi, label) tuples (hi inclusive).

    Returns: list that gets populated with (exec_count, pc, addr, value, label).
    """
    log = []
    # Wrap the CPU's memory store. CPU6502 writes via ``self.mem[addr] = v``
    # in the dispatch table, so the cleanest hook is to subclass via
    # monkey-patching the underlying write ops. We instead track writes by
    # post-decoding -- after each step, scan the regions for changes.
    # For our purposes this is approximate but adequate: we snapshot
    # before each instruction and diff after.
    snapshots = {(lo, hi, lbl): bytes(cpu.mem[lo:hi + 1]) for (lo, hi, lbl) in regions}

    def step_hook(prev_pc):
        for (lo, hi, lbl), prev in snapshots.items():
            cur = bytes(cpu.mem[lo:hi + 1])
            if cur != prev:
                # Find which addresses changed.
                for i, (p, c) in enumerate(zip(prev, cur)):
                    if p != c:
                        log.append((cpu.exec_count, prev_pc, lo + i, c, lbl))
                snapshots[(lo, hi, lbl)] = cur

    # Replace cpu.step with a wrapper.
    original_step = cpu.step
    def wrapped_step():
        prev_pc = cpu.pc
        ok = original_step()
        step_hook(prev_pc)
        return ok
    cpu.step = wrapped_step
    return log


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('disk', help='Path to .dsk or .po image')
    ap.add_argument('--slot', type=int, default=6)
    ap.add_argument('--max', type=int, default=20_000_000,
                    help='Max instructions (default 20M)')
    ap.add_argument('--stop', type=lambda s: int(s, 16), default=None,
                    help='Stop at PC (hex)')
    ap.add_argument('--watch', action='append', default=[],
                    help='lo-hi[:label] regions to log writes for (hex)')
    ap.add_argument('--dump', action='append', default=[],
                    help='lo-hi:path memory ranges to dump on stop (hex)')
    ap.add_argument('--no-progress', action='store_true')
    args = ap.parse_args()

    cpu, disk = setup_softcard_boot(args.disk, slot=args.slot)

    regions = []
    for spec in args.watch:
        parts = spec.split(':')
        rng = parts[0]
        label = parts[1] if len(parts) > 1 else rng
        lo_s, hi_s = rng.split('-')
        regions.append((int(lo_s, 16), int(hi_s, 16), label))
    write_log = install_write_logger(cpu, regions) if regions else []

    progress = 0 if args.no_progress else 2_000_000
    reason = cpu.run(max_instructions=args.max, stop_at=args.stop,
                     progress_interval=progress)

    print(f"\nStopped: {reason}")
    print(f"Executed: {cpu.exec_count:,} instructions")
    print(f"Final PC: ${cpu.pc:04X}")
    print(f"Disk track at stop: {disk.current_qtrack // 4}")
    if write_log:
        print(f"\nFirst 30 of {len(write_log)} writes to watched regions:")
        for tup in write_log[:30]:
            ec, pc, addr, val, lbl = tup
            print(f"  exec={ec:>10,}  PC=${pc:04X}  ${addr:04X}=${val:02X}  ({lbl})")
        if len(write_log) > 30:
            print(f"  ... and {len(write_log) - 30} more")

    for spec in args.dump:
        rng, path = spec.split(':')
        lo_s, hi_s = rng.split('-')
        lo, hi = int(lo_s, 16), int(hi_s, 16)
        with open(path, 'wb') as f:
            f.write(cpu.mem[lo:hi + 1])
        print(f"Dumped ${lo:04X}-${hi:04X} ({hi - lo + 1} bytes) to {path}")


if __name__ == '__main__':
    main()
