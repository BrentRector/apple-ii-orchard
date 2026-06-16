"""Stage 2 — boot-loader tracing.

Take the structured DiskFormat from Stage 1 (boot stub already identified,
skew table extracted, per-sector → Apple-address map for the boot-stub-
loaded sectors) and trace the rest of the loader's behavior:

  * **Stage-2 entry**: the boot stub ends with `JMP $1000`. Disassemble
    from $1000 and follow control flow.
  * **Install-copy loops**: stage-2 has small copy loops that move bytes
    from the loader's $1200-$13FF region into the runtime $0200-$03FF
    region. Pattern-match each one and record source/dest/length.
  * **LOAD_CPM call**: stage-2 calls a sector-load routine that reads
    N more sectors from disk into a staging area at $A300-$BFFF (or
    similar). Pattern-match the call and recover N + the destination.
  * **Slot scanner**: stage-2 walks slots 4..1, reading $Cn05/$Cn07/
    (2.23 also $Cn0B). Identify the scan range.
  * **Boot finalization**: planted vectors at $0000-$0007, the JSR
    $0E36 CPU-switch trigger, the install-copy that brings the
    warm-boot routine to $03C0.

Output: a `LoadSchedule` describing the full sequence of memory writes
during boot, ordered chronologically. Phase 7 (annotated source
generation) consumes this to drive the per-chunk asm emission; Phase
4/5/6 use the location/identity of routines like LOAD_CPM, the slot
scanner, and the warm-boot routine.

This module pattern-matches against well-known SoftCard boot-loader
shapes. A more general solution would use symbolic execution to follow
indirect control flow without needing pre-known patterns; for now,
patterns get us most of the way for the SoftCard case.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from .disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE, SECTOR_SIZE, SECTORS_PER_TRACK,
)
from .format_detect import DiskFormat, detect


# ── Result dataclasses ────────────────────────────────────────────────
@dataclass
class InstallCopy:
    """One stage-2 page-copy-loop event:
    `LDA src,Y / STA dst,Y / DEY / BNE`-style loops that move N bytes."""
    src_addr: int       # source 16-bit address (the LDA's operand)
    dst_addr: int       # destination 16-bit address (the STA's operand)
    length: int         # bytes copied (deduced from LDY initializer)
    pc_at_loop: int     # Apple address where the loop body sits


@dataclass
class LoadCpmCall:
    """A JSR into the loader's disk-I/O region (LC RAM $BB__ for 2.23
    or loader-resident $0E__/$0F__ for 2.20). The param field holds
    the value of the LDA #$NN immediately preceding the JSR, if any --
    its semantic meaning (sector count, source page, request code) is
    routine-specific and not derivable from this trace alone."""
    param: int          # immediately-preceding LDA #$NN value, or 0 if none
    target_addr: int    # JSR target address (the disk-helper routine)
    call_addr: int      # Apple address of the JSR


@dataclass
class LoadSchedule:
    """Structured trace of stage-2 boot-loader behavior."""
    disk_format: DiskFormat
    stage2_entry: int = 0x1000

    # The boot-stub-loaded sectors (taken directly from disk_format)
    boot_stub_destinations: list[tuple[int, int]] = field(default_factory=list)

    # Stage-2-discovered events
    install_copies: list[InstallCopy] = field(default_factory=list)
    load_cpm_calls: list[LoadCpmCall] = field(default_factory=list)

    # Notes / unanalyzed regions
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [f"LoadSchedule for {self.disk_format.path.name}"]
        lines.append(f"  variant: {self.disk_format.variant}")
        lines.append(f"  stage-2 entry: ${self.stage2_entry:04X}")
        lines.append(f"  boot-stub-loaded sectors: "
                     f"{len(self.boot_stub_destinations)}")
        for apple_addr, phys in self.boot_stub_destinations:
            lines.append(f"    ${apple_addr:04X} <- trk0:phys{phys:X}")
        lines.append(f"  install-copy loops: {len(self.install_copies)}")
        for ic in self.install_copies:
            lines.append(f"    ${ic.src_addr:04X}-${ic.src_addr + ic.length - 1:04X}"
                         f" -> ${ic.dst_addr:04X}-${ic.dst_addr + ic.length - 1:04X}"
                         f"  ({ic.length} bytes; loop at ${ic.pc_at_loop:04X})")
        lines.append(f"  disk-helper calls (LOAD_CPM-class): {len(self.load_cpm_calls)}")
        for lc in self.load_cpm_calls:
            param_text = f"A=${lc.param:02X}" if lc.param else "no preceding LDA #"
            lines.append(f"    ${lc.call_addr:04X}: JSR ${lc.target_addr:04X}"
                         f"  ({param_text})")
        if self.notes:
            lines.append("  notes:")
            for n in self.notes:
                lines.append(f"    - {n}")
        return "\n".join(lines)


# ── Implementation ────────────────────────────────────────────────────
def _build_loader_image(raw: bytes, fmt: str,
                        destinations: list[tuple[int, int]]) -> bytearray:
    """Reconstruct the in-memory loader image at $0800-$13FF from disk
    bytes. The boot stub at $0800 is sector 0 (always at file offset 0).
    The other 10 boot-stub-loaded sectors land at the destinations Phase 1
    identified (apple_addr -> phys_sector pairs).
    """
    interleave = DOS33_INTERLEAVE if fmt == "dsk" else PRODOS_INTERLEAVE
    image = bytearray(0x1400)  # covers $0000-$13FF (we only fill $0800+)
    # Boot sector at $0800
    image[0x800:0x900] = raw[:SECTOR_SIZE]
    # Boot-stub-loaded sectors
    for apple_addr, phys in destinations:
        on_disk = interleave[phys]
        offset = on_disk * SECTOR_SIZE
        image[apple_addr:apple_addr + SECTOR_SIZE] = raw[offset:offset + SECTOR_SIZE]
    return image


def _find_install_copies(image: bytearray, *,
                         scan_start: int = 0x1000,
                         scan_end: int = 0x1200) -> list[InstallCopy]:
    """Scan stage-2 for LDA abs,Y / STA abs,Y / DEY / BNE-style copy loops.

    Pattern (10 bytes): the 9-byte loop body plus optional preceding
    LDY #$NN to get the length:

       A0 NN              LDY #$NN          ; loop counter (NN bytes)
       B9 LO HI           LDA $HILO,Y       ; source
       99 LO HI           STA $HILO,Y       ; destination
       88                 DEY
       D0 F8 (or similar) BNE -7

    The exact branch offset depends on what's in between. The simplest
    high-confidence detector requires the LDA/STA pair followed within
    a few bytes by DEY/BNE.
    """
    copies = []
    pc = scan_start
    while pc < scan_end - 10:
        # LDY # ?
        if image[pc] == 0xA0:
            count = image[pc + 1]
            if count == 0:  # LDY #$00 means 256-byte loop
                count_actual = 256
            else:
                count_actual = count
            # Check next instruction is LDA abs,Y
            if image[pc + 2] == 0xB9 and image[pc + 5] == 0x99:
                src = image[pc + 3] | (image[pc + 4] << 8)
                dst = image[pc + 6] | (image[pc + 7] << 8)
                # Verify there's a DEY + BNE within a few bytes
                # (allow up to 4 bytes of intervening setup)
                for tail in range(8, 12):
                    if (image[pc + tail] == 0x88
                            and image[pc + tail + 1] == 0xD0):
                        copies.append(InstallCopy(
                            src_addr=src, dst_addr=dst,
                            length=count_actual,
                            pc_at_loop=pc,
                        ))
                        pc += tail + 2  # skip past this loop
                        break
                else:
                    pc += 1
                    continue
                continue
        pc += 1
    return copies


def _find_load_cpm_calls(image: bytearray, *,
                         scan_start: int = 0x1000,
                         scan_end: int = 0x1200) -> list[LoadCpmCall]:
    """Scan stage-2 for sector-load calls. The SoftCard pattern is a
    JSR into LC RAM ($BB__) which calls the disk-I/O primitive. The
    primitive's caller convention (LDA #$NN preloaded with a sector
    count or related parameter) varies enough that we report the JSR
    site without trying to interpret the parameter as a sector count
    alone -- Phase 4 (handoff identification) and a future symbolic-
    execution pass will narrow it.

    Heuristic: report every `JSR $BB__` in stage-2 as a "load_cpm-
    style" call, with the immediately-preceding LDA #$NN (if any) as
    the parameter.
    """
    calls = []
    pc = scan_start
    while pc < scan_end - 3:
        if image[pc] == 0x20:  # JSR
            target = image[pc + 1] | (image[pc + 2] << 8)
            # Candidate disk-helper call: JSR into LC RAM (2.23 pattern,
            # JSR $BB__) or into the loader-resident RWTS area (2.20
            # pattern, JSR $0E__-$0F__).
            if (0xBB00 <= target <= 0xBFFF
                    or 0x0E00 <= target <= 0x0FFF):
                # Look back for an LDA #$NN that might be the parameter
                param = None
                if pc >= 2 and image[pc - 2] == 0xA9:
                    param = image[pc - 1]
                calls.append(LoadCpmCall(
                    param=param if param is not None else 0,
                    target_addr=target,
                    call_addr=pc,
                ))
                pc += 3
                continue
        pc += 1
    return calls


def trace_loader(disk_path: Path | str) -> LoadSchedule:
    """Take a CP/M disk image and produce a structured LoadSchedule."""
    disk_path = Path(disk_path)
    info = detect(disk_path)
    sched = LoadSchedule(
        disk_format=info,
        boot_stub_destinations=info.boot_stub_destinations or [],
    )

    if not info.has_boot_stub:
        sched.notes.append("no SoftCard boot stub; can't trace stage 2")
        return sched

    raw = disk_path.read_bytes()
    image = _build_loader_image(
        raw, info.format, info.boot_stub_destinations or [],
    )

    sched.install_copies = _find_install_copies(image)
    sched.load_cpm_calls = _find_load_cpm_calls(image)

    if not sched.install_copies:
        sched.notes.append(
            "no install-copy loops found in stage-2 (pattern may have evolved)"
        )
    if not sched.load_cpm_calls:
        sched.notes.append(
            "no LOAD_CPM-shaped call found (pattern may differ in this variant)"
        )

    return sched
