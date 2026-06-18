"""Stage 3 — version delta detection.

Compare two CP/M disk images at the routine level. The deltas the
detector surfaces:

  * Variant agreement (both 2.23, both 2.20, or one of each).
  * Z-80 reset vector target -- where each disk's Z-80 starts after
    the SoftCard handoff.
  * BDOS entry vector target -- where each disk's user-program-visible
    BDOS lives.
  * CPU-switch mechanism -- 2.23 uses JSR $0E36; 2.20 uses JSR $C400.
  * Cold-boot dispatch cases -- which device codes each variant
    handles. The Videx-fix delta surfaces here as "case 6 present in
    disk B, absent in disk A."
  * Boot-stub byte-identity (the 60-byte boot code is identical between
    2.20 and 2.23 -- but that may not hold for other variant pairs).

The output is a structured `DiskDelta` that captures every difference
the prior phases can surface. `CPM_Videx_Difference.md` is the
manually-produced equivalent for 2.20 vs 2.23; this module produces
the same content for any disk pair.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from .format_detect import detect, DiskFormat
from .handoff import find_handoff, HandoffInfo
from .cold_boot_trace import trace_cold_boot, ColdBootSchedule
from .reference_data import bios_bin
from .disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE, SECTOR_SIZE,
)


# ── Result dataclass ──────────────────────────────────────────────────
@dataclass
class DiskDelta:
    """Structured comparison of two CP/M disk images."""
    path_a: Path
    path_b: Path
    info_a: DiskFormat
    info_b: DiskFormat
    handoff_a: HandoffInfo
    handoff_b: HandoffInfo
    cold_boot_a: ColdBootSchedule | None = None
    cold_boot_b: ColdBootSchedule | None = None

    # Variant agreement
    same_variant: bool = False

    # Boot-stub byte diff (sector 0). Code is the first ~64 bytes
    # (the executable boot stub at $0801-$0840); the rest is data
    # (skew table, copyright strings, zero pad).
    boot_stub_diff_bytes: int = 0
    boot_stub_code_diff_bytes: int = 0   # offset 0 - 0x40
    boot_stub_data_diff_bytes: int = 0   # offset 0x40 - 0xFF

    # Cold-boot dispatch deltas
    dispatch_cases_a: dict[int, int] = field(default_factory=dict)
    dispatch_cases_b: dict[int, int] = field(default_factory=dict)
    cases_only_in_a: list[int] = field(default_factory=list)
    cases_only_in_b: list[int] = field(default_factory=list)
    cases_with_different_handler: list[int] = field(default_factory=list)

    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [
            f"DiskDelta: {self.path_a.name} (A)  vs  {self.path_b.name} (B)",
        ]
        lines.append(f"  variant: A={self.info_a.variant}, "
                     f"B={self.info_b.variant} "
                     f"({'same' if self.same_variant else 'DIFFERENT'})")

        # Boot stub
        lines.append(f"  boot stub (sector 0):")
        lines.append(f"    code region (first 64 bytes): "
                     f"{self.boot_stub_code_diff_bytes} byte diff")
        lines.append(f"    data region (rest of sector): "
                     f"{self.boot_stub_data_diff_bytes} byte diff")

        # Z-80 reset vector
        ar = self.handoff_a.z80_reset_plant
        br = self.handoff_b.z80_reset_plant
        lines.append(f"  Z-80 reset: A=JP ${ar.target_addr:04X}  B=JP ${br.target_addr:04X}"
                     f" {'(same)' if ar.target_addr == br.target_addr else '(DIFFER)'}"
                     if (ar and br) else
                     "  Z-80 reset: incomplete detection (skipped)")

        # BDOS entry
        ab = self.handoff_a.bdos_entry_plant
        bb = self.handoff_b.bdos_entry_plant
        lines.append(f"  BDOS entry: A=JP ${ab.target_addr:04X}  B=JP ${bb.target_addr:04X}"
                     f" {'(same)' if ab.target_addr == bb.target_addr else '(DIFFER)'}"
                     if (ab and bb) else
                     "  BDOS entry: incomplete detection (skipped)")

        # CPU switch
        ac = self.handoff_a.cpu_switch_trigger
        bc = self.handoff_b.cpu_switch_trigger
        lines.append(f"  CPU-switch: A=JSR ${ac.target_addr:04X}  B=JSR ${bc.target_addr:04X}"
                     f" {'(same mechanism)' if ac.target_addr == bc.target_addr else '(DIFFERENT mechanism)'}"
                     if (ac and bc) else
                     "  CPU-switch: incomplete detection (skipped)")

        # Dispatch cases
        lines.append(f"  cold-boot dispatch cases:")
        lines.append(f"    A: {sorted(self.dispatch_cases_a.keys())}")
        lines.append(f"    B: {sorted(self.dispatch_cases_b.keys())}")
        if self.cases_only_in_a:
            lines.append(f"    only in A: {self.cases_only_in_a}")
        if self.cases_only_in_b:
            lines.append(f"    only in B: {self.cases_only_in_b}")
        if self.cases_with_different_handler:
            for case in self.cases_with_different_handler:
                a_h = self.dispatch_cases_a.get(case, "?")
                b_h = self.dispatch_cases_b.get(case, "?")
                a_h_str = f"${a_h:04X}" if isinstance(a_h, int) else str(a_h)
                b_h_str = f"${b_h:04X}" if isinstance(b_h, int) else str(b_h)
                lines.append(f"    case {case}: handler differs "
                             f"(A={a_h_str}  B={b_h_str})")

        if self.notes:
            lines.append("  notes:")
            for n in self.notes:
                lines.append(f"    - {n}")
        return "\n".join(lines)


# ── Implementation ────────────────────────────────────────────────────
def _read_boot_sector(path: Path, fmt: str) -> bytes:
    """Read the boot sector (sector 0 of track 0) from a disk image."""
    raw = path.read_bytes()
    # Sector 0 of track 0 is at file offset 0 in both .dsk and .po
    # because both interleaves map physical 0 → on-disk 0.
    return raw[:SECTOR_SIZE]


def compare_disks(path_a: Path | str, path_b: Path | str) -> DiskDelta:
    """Run all prior phases on both disks and produce a structured diff."""
    path_a = Path(path_a)
    path_b = Path(path_b)

    info_a = detect(path_a)
    info_b = detect(path_b)
    handoff_a = find_handoff(path_a)
    handoff_b = find_handoff(path_b)

    # Cold-boot schedules require BIOS binaries; locate them by the detected
    # BIOS base (the Z-80 reset-plant target), which distinguishes the 2.20 44K
    # ($AA00) vs 56K ($DA00) BIOSes that share one variant id. Pass that base as
    # bios_org so the trace reports addresses against the correct origin.
    cold_a = None
    cold_b = None
    base_a = handoff_a.z80_reset_plant.target_addr if handoff_a.z80_reset_plant else None
    base_b = handoff_b.z80_reset_plant.target_addr if handoff_b.z80_reset_plant else None
    bios_a = bios_bin(info_a.variant, base=base_a)
    bios_b = bios_bin(info_b.variant, base=base_b)
    if bios_a:
        cold_a = trace_cold_boot(bios_a, bios_org=base_a)
    if bios_b:
        cold_b = trace_cold_boot(bios_b, bios_org=base_b)

    delta = DiskDelta(
        path_a=path_a, path_b=path_b,
        info_a=info_a, info_b=info_b,
        handoff_a=handoff_a, handoff_b=handoff_b,
        cold_boot_a=cold_a, cold_boot_b=cold_b,
    )

    delta.same_variant = (info_a.variant == info_b.variant)

    # Boot-stub byte diff -- separately count code-region (first 64 bytes,
    # the executable boot stub at $0801-$0840) and data-region (the rest:
    # skew table, copyright strings, zero pad).
    sec0_a = _read_boot_sector(path_a, info_a.format)
    sec0_b = _read_boot_sector(path_b, info_b.format)
    code_diff = sum(1 for x, y in zip(sec0_a[:0x40], sec0_b[:0x40]) if x != y)
    data_diff = sum(1 for x, y in zip(sec0_a[0x40:], sec0_b[0x40:]) if x != y)
    delta.boot_stub_code_diff_bytes = code_diff
    delta.boot_stub_data_diff_bytes = data_diff
    delta.boot_stub_diff_bytes = code_diff + data_diff

    # Cold-boot dispatch deltas
    if cold_a:
        delta.dispatch_cases_a = {
            dc.device_code: dc.handler_addr for dc in cold_a.dispatch_cases
        }
    if cold_b:
        delta.dispatch_cases_b = {
            dc.device_code: dc.handler_addr for dc in cold_b.dispatch_cases
        }
    cases_a = set(delta.dispatch_cases_a.keys())
    cases_b = set(delta.dispatch_cases_b.keys())
    delta.cases_only_in_a = sorted(cases_a - cases_b)
    delta.cases_only_in_b = sorted(cases_b - cases_a)
    delta.cases_with_different_handler = sorted(
        c for c in cases_a & cases_b
        if delta.dispatch_cases_a[c] != delta.dispatch_cases_b[c]
    )

    if not (cold_a and cold_b):
        delta.notes.append(
            "BIOS auto-discovery failed for one or both disks; "
            "cold-boot dispatch comparison skipped"
        )

    return delta
