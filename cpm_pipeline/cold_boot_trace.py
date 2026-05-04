"""Stage 5 — Z-80 cold-boot tracing.

Take a Z-80 BIOS binary (the bytes that live at the BIOS load address
after the SoftCard handoff -- $FAB8 for CP/M 2.23, $DACC for 2.20)
and structurally identify:

  * **BIOS jump table**: the 17 standard CP/M 2.x BIOS entries
    (BOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH, READER, HOME,
    SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST, SECTRAN).
    Entries 0-14 are 3-byte JP instructions; entry 15 (LISTST) is
    "XOR A; RET"; entry 16 (SECTRAN) is "LD H,B; LD L,C; RET".

  * **Trap-marker pages**: regions filled with $FF $FF $00 $00 or
    $F7 $F7 $00 $00 patterns that get runtime-populated by the
    cold-boot generator with real handler bodies. The static bytes
    decode as RST $38 / RST $30 + NOPs but are never executed in
    that form.

  * **Cold-boot generator**: the routine that walks the slot-info
    table at $F3B8+E (for E=7..1) and dispatches per device code.
    Identified by its signature `21 B8 F3 19 7E D6 03` (LD HL,$F3B8;
    ADD HL,DE; LD A,(HL); SUB $03).

  * **Per-device dispatch cases**: the CALL targets in the cold-boot
    generator, each tagged with the device code that triggers them
    (3 = keyboard, 4 = Pascal 1.0, 6 = Pascal 1.1).

For the cpm-videx investigation specifically, dispatch case 6 is
the discriminator between 2.20 (case absent) and 2.23 (case present
with target $FDB0). This module surfaces that distinction
mechanically.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


# ── Result dataclasses ────────────────────────────────────────────────
@dataclass
class BiosJumpEntry:
    index: int            # 0..16
    name: str             # 'BOOT', 'WBOOT', etc.
    address: int          # in the BIOS address space ($FAB8 + index*3)
    target: int | None    # destination of the JP, or None for non-JP entries
    raw: bytes = b""      # the actual 3 bytes (or fewer for inline routines)


@dataclass
class TrapMarkerPage:
    """A region of the BIOS that's filled with a runtime-populated
    pattern at boot. The static bytes are placeholders."""
    start: int
    end: int              # inclusive last byte
    pattern_label: str    # 'FF_FF_00_00' or 'F7_F7_00_00' or 'mixed'


@dataclass
class DispatchCase:
    """One per-device case in the cold-boot generator's dispatch."""
    device_code: int      # 3, 4, 6 (or whatever was matched)
    handler_addr: int     # CALL target (the per-device init routine)


@dataclass
class ColdBootSchedule:
    bios_path: Path
    bios_org: int                                      # load address ($FAB8 / $DACC)
    bios_size: int                                     # bytes covered
    jump_table: list[BiosJumpEntry] = field(default_factory=list)
    trap_marker_pages: list[TrapMarkerPage] = field(default_factory=list)
    cold_boot_generator_addr: int | None = None
    dispatch_cases: list[DispatchCase] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [f"ColdBootSchedule for {self.bios_path.name}"]
        lines.append(f"  BIOS org: ${self.bios_org:04X}, size: {self.bios_size} bytes")
        lines.append(f"  jump table: {len(self.jump_table)} entries")
        for entry in self.jump_table:
            tgt = f"${entry.target:04X}" if entry.target is not None else "(inline)"
            lines.append(f"    {entry.index:2d}  ${entry.address:04X}  "
                         f"{entry.name:<8s} -> {tgt}")
        lines.append(f"  trap-marker pages: {len(self.trap_marker_pages)}")
        for tp in self.trap_marker_pages:
            lines.append(f"    ${tp.start:04X}-${tp.end:04X}  pattern={tp.pattern_label}")
        if self.cold_boot_generator_addr is not None:
            lines.append(f"  cold-boot generator at ${self.cold_boot_generator_addr:04X}")
        else:
            lines.append("  cold-boot generator: NOT FOUND")
        lines.append(f"  dispatch cases: {len(self.dispatch_cases)}")
        for dc in self.dispatch_cases:
            lines.append(f"    device {dc.device_code} -> CALL ${dc.handler_addr:04X}")
        if self.notes:
            lines.append("  notes:")
            for n in self.notes:
                lines.append(f"    - {n}")
        return "\n".join(lines)


# ── Constants ─────────────────────────────────────────────────────────
BIOS_ENTRY_NAMES = [
    "BOOT", "WBOOT", "CONST", "CONIN", "CONOUT", "LIST",
    "PUNCH", "READER", "HOME", "SELDSK", "SETTRK", "SETSEC",
    "SETDMA", "READ", "WRITE", "LISTST", "SECTRAN",
]

# Cold-boot generator signature: LD HL,$F3B8 / ADD HL,DE / LD A,(HL) / SUB $03
COLD_BOOT_GENERATOR_SIGNATURE = bytes.fromhex(
    "21B8F3"   # LD HL,$F3B8
    "19"       # ADD HL,DE
    "7E"       # LD A,(HL)
    "D603"     # SUB $03
)


# ── Implementation ────────────────────────────────────────────────────
def _parse_jump_table(raw: bytes, bios_org: int) -> list[BiosJumpEntry]:
    """Parse the 17-entry CP/M jump table at the start of the BIOS image."""
    entries = []
    for i in range(15):  # entries 0-14 are 3-byte JP nnnn
        offset = i * 3
        if offset + 3 > len(raw):
            break
        opcode = raw[offset]
        if opcode == 0xC3:  # JP nnnn
            target = raw[offset + 1] | (raw[offset + 2] << 8)
        else:
            target = None
        entries.append(BiosJumpEntry(
            index=i,
            name=BIOS_ENTRY_NAMES[i],
            address=bios_org + offset,
            target=target,
            raw=bytes(raw[offset:offset + 3]),
        ))
    # Entries 15 + 16 are inline routines; just record their start
    # addresses without disassembling.
    if 15 * 3 < len(raw):
        entries.append(BiosJumpEntry(
            index=15, name="LISTST",
            address=bios_org + 15 * 3, target=None,
            raw=bytes(raw[15 * 3:15 * 3 + 3]),
        ))
    if 16 * 3 < len(raw):
        entries.append(BiosJumpEntry(
            index=16, name="SECTRAN",
            address=bios_org + 16 * 3, target=None,
            raw=bytes(raw[16 * 3:16 * 3 + 3]),
        ))
    return entries


def _find_trap_marker_pages(raw: bytes, bios_org: int,
                            *, min_pattern_runs: int = 4) -> list[TrapMarkerPage]:
    """Scan for regions filled with the trap-marker patterns.

    Patterns: 4-byte units `FF FF 00 00` and `F7 F7 00 00`. A region
    qualifies when at least `min_pattern_runs` consecutive 4-byte units
    follow the pattern.
    """
    pages = []
    patterns = {
        bytes([0xFF, 0xFF, 0x00, 0x00]): "FF_FF_00_00",
        bytes([0xF7, 0xF7, 0x00, 0x00]): "F7_F7_00_00",
    }
    i = 0
    while i + 4 <= len(raw):
        chunk = raw[i:i + 4]
        if chunk in patterns:
            # Try to extend the run
            label = patterns[chunk]
            run_start = i
            mixed = False
            j = i + 4
            while j + 4 <= len(raw):
                next_chunk = raw[j:j + 4]
                if next_chunk == chunk:
                    j += 4
                    continue
                if next_chunk in patterns:
                    mixed = True
                    j += 4
                    continue
                break
            run_units = (j - run_start) // 4
            if run_units >= min_pattern_runs:
                pages.append(TrapMarkerPage(
                    start=bios_org + run_start,
                    end=bios_org + j - 1,
                    pattern_label="mixed" if mixed else label,
                ))
            i = j
        else:
            i += 1
    return pages


def _find_cold_boot_generator(raw: bytes, bios_org: int) -> int | None:
    """Locate the cold-boot generator by signature; return its address."""
    pos = raw.find(COLD_BOOT_GENERATOR_SIGNATURE)
    if pos < 0:
        return None
    return bios_org + pos


def _find_dispatch_cases(raw: bytes, bios_org: int,
                         generator_addr: int | None) -> list[DispatchCase]:
    """Find the per-device dispatch cases inside the cold-boot generator.

    The cold-boot generator's body has a sequence of comparison-and-call
    blocks. Each block matches a specific device code:

      SUB $03      ; set A = device_code - 3 (so device 3 -> A == 0)
      JR NZ,next   ; if not 0, skip this case
      CALL handler ; device 3's handler

      DEC A        ; A -= 1 (so device 4 -> A == 0 now)
      JR NZ,next   ; if not 0, skip
      CALL handler ; device 4's handler
      [maybe more code -- e.g., loading HL, calling helpers]

      CP $02       ; A == $02 (so device 6 -> A == $02; original was 6, after
                    ; SUB $03 = 3, after DEC A = 2; matches)
      JR NZ,next
      [maybe more setup]
      CALL handler ; device 6's handler

    The simple heuristic: the FIRST CALL after each comparison
    (SUB/DEC A/CP) is the dispatch handler for that case. Subsequent
    CALLs in the same case are helper calls (e.g., CALL PRINT_STR to
    print a sign-on message) and are NOT dispatch handlers.

    We track `device_code` as: starts at 3 after SUB $03; increments
    by 1 after DEC A; jumps to whatever value CP $XX implies (CP $02
    means we're now matching the device code that becomes 0 after
    SUB $03 + DEC A + CP $02 = 3 + 1 + 2 = 6).
    """
    if generator_addr is None:
        return []
    cases = []
    sig_offset = generator_addr - bios_org
    body_start = sig_offset
    body_end = min(sig_offset + 80, len(raw))

    pc = body_start
    expected_device = 0  # gets set when we see the first SUB / CP
    seen_first_call_for_case = False

    while pc + 1 <= body_end:
        op = raw[pc]
        if op == 0xD6 and pc + 1 < body_end:  # SUB $XX
            sub_imm = raw[pc + 1]
            # SUB $03 means: device_code = 3 marks the "this case fires" point
            expected_device = sub_imm
            seen_first_call_for_case = False
            pc += 2
        elif op == 0x3D:  # DEC A
            expected_device += 1
            seen_first_call_for_case = False
            pc += 1
        elif op == 0xFE and pc + 1 < body_end:  # CP $XX
            # After SUB $03 then DEC A, A holds device-4-relative value.
            # CP $02 means we're checking device 4 + 2 = 6 (or generally,
            # the case fires when device_code - prior_offset == cp_imm).
            cp_imm = raw[pc + 1]
            expected_device += cp_imm
            seen_first_call_for_case = False
            pc += 2
        elif op == 0xCD and pc + 3 <= body_end:  # CALL nnnn
            target = raw[pc + 1] | (raw[pc + 2] << 8)
            if not seen_first_call_for_case and expected_device > 0:
                cases.append(DispatchCase(
                    device_code=expected_device,
                    handler_addr=target,
                ))
                seen_first_call_for_case = True
            pc += 3
        else:
            pc += 1
    return cases


def trace_cold_boot(bios_path: Path | str,
                    *, bios_org: int | None = None) -> ColdBootSchedule:
    """Analyze a Z-80 BIOS binary and return a structured ColdBootSchedule.

    `bios_org` defaults to $FAB8 (CP/M 2.23). For 2.20, pass $DACC.
    """
    bios_path = Path(bios_path)
    raw_full = bios_path.read_bytes()

    # Effective BIOS size (for SoftCard 2.23: 1352 bytes from $FAB8 to $FFFF;
    # the on-disk file may be longer with sector-aligned padding).
    if bios_org is None:
        # Heuristic: if the file starts with a 17-entry jump table that
        # makes sense for $FAB8 OR $DACC, pick whichever's targets land
        # inside the BIOS region.
        bios_org = 0xFAB8
        # If targets don't make sense, try $DACC.
        # First entry must be JP nnnn.
        if len(raw_full) >= 3 and raw_full[0] == 0xC3:
            target = raw_full[1] | (raw_full[2] << 8)
            if not (0xFAB8 <= target <= 0xFFFF):
                if 0xDACC <= target <= 0xE2CB:
                    bios_org = 0xDACC

    # Truncate to live BIOS size.
    if bios_org == 0xFAB8:
        bios_size = 0x10000 - 0xFAB8  # = $0548 = 1352
    elif bios_org == 0xDACC:
        bios_size = 0x0800  # 2 KB for 2.20
    else:
        bios_size = len(raw_full)
    raw = raw_full[:bios_size]

    sched = ColdBootSchedule(
        bios_path=bios_path,
        bios_org=bios_org,
        bios_size=len(raw),
    )

    sched.jump_table = _parse_jump_table(raw, bios_org)
    sched.trap_marker_pages = _find_trap_marker_pages(raw, bios_org)
    sched.cold_boot_generator_addr = _find_cold_boot_generator(raw, bios_org)
    sched.dispatch_cases = _find_dispatch_cases(
        raw, bios_org, sched.cold_boot_generator_addr,
    )

    if sched.cold_boot_generator_addr is None:
        sched.notes.append(
            "cold-boot generator signature not found; either this isn't a "
            "SoftCard CP/M BIOS or the variant differs from 2.20/2.23"
        )

    return sched
