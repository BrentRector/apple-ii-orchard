"""Stage 4 — handoff identification.

Locate the bridge between the 6502 boot loader and the Z-80 takeover.
Three concrete signals to find:

  * **Z-80 reset vector plant**: a `LDA #$C3; STA $0000; LDA #$XX;
    STA $0001; LDA #$YY; STA $0002` sequence in the loader. The XX/YY
    bytes are the low/high of the Z-80's first instruction address
    after reset (`JP $XXYY`). For 2.23 this is `$FA00`; for 2.20 it's
    `$DA00`.

  * **BDOS call vector plant**: a similar `LDA #$C3; STA $0005;
    LDA #$LO; STA $0006; LDA #$HI; STA $0007` sequence. The LO/HI
    bytes are the BDOS entry. For 2.23 this is `$9C06`; for 2.20 it's
    `$CC06`.

  * **CPU-switch trigger**: a `JSR $0E36` (or the variant equivalent --
    2.20 uses a different mechanism) instruction in the warm-boot
    routine at runtime `$03C0+`. The byte at the JSR's target is read
    by the SoftCard hardware to flip the bus from 6502 to Z-80.

These three signals together fully describe the handoff: where the
Z-80 starts executing, where user programs reach BDOS, and what
instruction physically triggers the CPU swap.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from .disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE, SECTOR_SIZE,
)
from .format_detect import detect


@dataclass
class VectorPlant:
    """One `LDA #$C3 / STA $XXXX / LDA # / STA / LDA # / STA` sequence
    that plants a JP-instruction at the named target."""
    name: str               # 'z80_reset' or 'bdos_entry'
    plant_addr: int         # address of the JP being planted ($0000 or $0005)
    target_addr: int        # the address the JP will jump to
    pc_in_loader: int       # Apple address of the planting code


@dataclass
class CpuSwitchTrigger:
    """The JSR (or analog) instruction that triggers the SoftCard's
    bus swap from 6502 to Z-80."""
    pc_in_loader: int       # Apple address of the JSR
    target_addr: int        # the JSR target (e.g., $0E36)


@dataclass
class HandoffInfo:
    disk_path: Path
    z80_reset_plant: VectorPlant | None = None
    bdos_entry_plant: VectorPlant | None = None
    cpu_switch_trigger: CpuSwitchTrigger | None = None
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [f"HandoffInfo for {self.disk_path.name}"]
        if self.z80_reset_plant:
            p = self.z80_reset_plant
            lines.append(
                f"  Z-80 reset vector: planted at ${p.plant_addr:04X} "
                f"-> JP ${p.target_addr:04X}  (planting code at ${p.pc_in_loader:04X})"
            )
        else:
            lines.append("  Z-80 reset vector: NOT FOUND")
        if self.bdos_entry_plant:
            p = self.bdos_entry_plant
            lines.append(
                f"  BDOS entry vector: planted at ${p.plant_addr:04X} "
                f"-> JP ${p.target_addr:04X}  (planting code at ${p.pc_in_loader:04X})"
            )
        else:
            lines.append("  BDOS entry vector: NOT FOUND")
        if self.cpu_switch_trigger:
            t = self.cpu_switch_trigger
            lines.append(
                f"  CPU-switch trigger: JSR ${t.target_addr:04X} "
                f"at ${t.pc_in_loader:04X}"
            )
        else:
            lines.append("  CPU-switch trigger: NOT FOUND")
        if self.notes:
            for n in self.notes:
                lines.append(f"  note: {n}")
        return "\n".join(lines)


# ── Implementation ────────────────────────────────────────────────────
def _build_loader_image(raw: bytes, fmt: str,
                        destinations: list[tuple[int, int]]) -> bytearray:
    """Same loader-image reconstruction as in loader_trace.py."""
    interleave = DOS33_INTERLEAVE if fmt == "dsk" else PRODOS_INTERLEAVE
    image = bytearray(0x1400)
    image[0x800:0x900] = raw[:SECTOR_SIZE]
    for apple_addr, phys in destinations:
        on_disk = interleave[phys]
        offset = on_disk * SECTOR_SIZE
        image[apple_addr:apple_addr + SECTOR_SIZE] = raw[offset:offset + SECTOR_SIZE]
    return image


def _find_vector_plant(image: bytearray, target_apple_addr: int,
                       *, scan_start: int = 0x1000,
                       scan_end: int = 0x13FF) -> VectorPlant | None:
    """Look for a 6-byte sequence that plants `JP $XXYY` at
    `target_apple_addr`. The expected pattern (15 bytes total):

       A9 C3       LDA #$C3
       8D LO HI    STA target_apple_addr
       A9 LO       LDA #(JP-target-low-byte)
       8D LO+1 HI  STA target_apple_addr+1
       A9 HI       LDA #(JP-target-high-byte)
       8D LO+2 HI  STA target_apple_addr+2

    This is the canonical pattern for both versions. Some loaders use
    a more compact variant (`LDA #$C3; STA target; LDA #lo; STA target+1;
    LDA #hi; STA target+2`) which we can also recognize -- the strict
    15-byte form is the most common.
    """
    target_lo = target_apple_addr & 0xFF
    target_hi = (target_apple_addr >> 8) & 0xFF
    pc = scan_start
    while pc + 15 <= scan_end:
        if (image[pc] == 0xA9 and image[pc + 1] == 0xC3      # LDA #$C3
                and image[pc + 2] == 0x8D                     # STA abs
                and image[pc + 3] == target_lo
                and image[pc + 4] == target_hi
                and image[pc + 5] == 0xA9                     # LDA #lo
                and image[pc + 7] == 0x8D                     # STA abs
                and image[pc + 8] == (target_lo + 1) & 0xFF
                and image[pc + 9] == target_hi
                and image[pc + 10] == 0xA9                    # LDA #hi
                and image[pc + 12] == 0x8D                    # STA abs
                and image[pc + 13] == (target_lo + 2) & 0xFF
                and image[pc + 14] == target_hi):
            jp_target_lo = image[pc + 6]
            jp_target_hi = image[pc + 11]
            jp_target = jp_target_lo | (jp_target_hi << 8)
            return VectorPlant(
                name="(unnamed)",
                plant_addr=target_apple_addr,
                target_addr=jp_target,
                pc_in_loader=pc,
            )
        pc += 1

    # Also try the "LDA #$C3 / STA addr / LDx / STx / LDx / STx" pattern
    # where instead of three separate LDAs, the loader may use LDX/STX
    # or LD HL,addr / LD A,#x / STA addr (Z-80-influenced patterns).
    # For now, just return None if the 15-byte LDA/STA form isn't found.
    return None


def _find_compact_vector_plant(image: bytearray, target_apple_addr: int,
                               *, scan_start: int = 0x1000,
                               scan_end: int = 0x13FF) -> VectorPlant | None:
    """Try the "LDA #$C3 / STA target / LDX / STA / LDA / STA" pattern --
    a variation that uses the same A register reuse but in a
    different order, OR a "LDA #$C3 / STA / LDA HL low / STA HL+1 /
    LDA HL high / STA HL+2" variant.

    The key indicator we look for: any STA at `target_apple_addr` with
    A=$C3 nearby, followed by stores at target+1 and target+2.
    """
    target_lo = target_apple_addr & 0xFF
    target_hi = (target_apple_addr >> 8) & 0xFF
    pc = scan_start
    while pc + 3 <= scan_end:
        # Look for STA target_apple_addr (8D LO HI) with the previous
        # instruction being LDA #$C3 (A9 C3)
        if (image[pc] == 0x8D
                and image[pc + 1] == target_lo
                and image[pc + 2] == target_hi
                and pc >= 2
                and image[pc - 2] == 0xA9
                and image[pc - 1] == 0xC3):
            # Now scan forward up to ~30 bytes for the STAs at +1 and +2
            jp_target_lo = None
            jp_target_hi = None
            scan = pc + 3
            while scan < pc + 50 and scan + 3 <= len(image):
                if (image[scan] == 0xA9 and scan + 5 <= len(image)
                        and image[scan + 2] == 0x8D
                        and image[scan + 3] == (target_lo + 1) & 0xFF
                        and image[scan + 4] == target_hi):
                    jp_target_lo = image[scan + 1]
                # Z-80 plant variant: STA $0006 with HL pair stored
                if (image[scan] == 0x21 and scan + 6 <= len(image)
                        and image[scan + 3] == 0x8D
                        and image[scan + 4] == (target_lo + 1) & 0xFF
                        and image[scan + 5] == target_hi):
                    jp_target_lo = image[scan + 1]
                    jp_target_hi = image[scan + 2]
                    break
                if (image[scan] == 0xA9 and scan + 5 <= len(image)
                        and image[scan + 2] == 0x8D
                        and image[scan + 3] == (target_lo + 2) & 0xFF
                        and image[scan + 4] == target_hi):
                    jp_target_hi = image[scan + 1]
                if jp_target_lo is not None and jp_target_hi is not None:
                    break
                scan += 1
            if jp_target_lo is not None and jp_target_hi is not None:
                return VectorPlant(
                    name="(unnamed)",
                    plant_addr=target_apple_addr,
                    target_addr=jp_target_lo | (jp_target_hi << 8),
                    pc_in_loader=pc - 2,  # back up to the LDA #$C3
                )
        pc += 1
    return None


def _find_cpu_switch_trigger(image: bytearray, *,
                             scan_start: int = 0x1000,
                             scan_end: int = 0x13FF) -> CpuSwitchTrigger | None:
    """Find the SoftCard CPU-switch trigger in the loader.

    For 2.23 the trigger is `JSR $0E36` in the warm-boot routine
    (Apple $13C0+). For 2.20 the warm-boot routine at $13C0+ uses a
    different mechanism: `STA $C400 / JSR $1010` (the STA $C400 hits
    the slot-4 device-select page, and the JSR $1010 enters the
    cooperative-CPU loop). The STA $C400 is the SoftCard signal.
    """
    # First try the JSR $0E36 pattern (2.23-style)
    pc = scan_start
    while pc + 3 <= scan_end:
        if image[pc] == 0x20:  # JSR
            target = image[pc + 1] | (image[pc + 2] << 8)
            if target == 0x0E36:
                return CpuSwitchTrigger(pc_in_loader=pc, target_addr=target)
            if 0x0E00 <= target <= 0x0EFF and pc >= 0x13C0:
                return CpuSwitchTrigger(pc_in_loader=pc, target_addr=target)
        pc += 1
    # 2.20-style: look for STA $C400 in the warm-boot region
    pc = 0x13C0
    while pc + 3 <= scan_end:
        if (image[pc] == 0x8D
                and image[pc + 1] == 0x00
                and image[pc + 2] == 0xC4):
            return CpuSwitchTrigger(pc_in_loader=pc, target_addr=0xC400)
        pc += 1
    return None


def _find_z80_bios_planting(bios_bytes: bytes, bios_org: int) -> tuple[
        VectorPlant | None, VectorPlant | None]:
    """Search a Z-80 BIOS binary for the Z-80-side vector planting code.

    The Z-80 BIOS plants both the warm-boot vector (`JP $FA03` at Z-80
    $0000-$0002) and the BDOS call vector (`JP $9C06` at Z-80 $0005-$0007)
    during cold-boot setup. The Z-80 instructions are:

       3E C3        LD A, $C3
       32 00 00     LD ($0000), A         (plant JP opcode at Z-80 $0000)
       21 LO HI     LD HL, warm-boot      (warm-boot target)
       22 01 00     LD ($0001), HL        (plant target)
       32 05 00     LD ($0005), A         (plant JP opcode at Z-80 $0005)
       21 LO HI     LD HL, BDOS_entry     (BDOS entry)
       22 06 00     LD ($0006), HL        (plant BDOS target)
    """
    pc = 0
    while pc + 19 <= len(bios_bytes):
        if (bios_bytes[pc] == 0x3E and bios_bytes[pc + 1] == 0xC3       # LD A,$C3
                and bios_bytes[pc + 2] == 0x32 and bios_bytes[pc + 3] == 0x00
                and bios_bytes[pc + 4] == 0x00                             # LD ($0000),A
                and bios_bytes[pc + 5] == 0x21                             # LD HL,nn
                and bios_bytes[pc + 8] == 0x22 and bios_bytes[pc + 9] == 0x01
                and bios_bytes[pc + 10] == 0x00                            # LD ($0001),HL
                and bios_bytes[pc + 11] == 0x32 and bios_bytes[pc + 12] == 0x05
                and bios_bytes[pc + 13] == 0x00                            # LD ($0005),A
                and bios_bytes[pc + 14] == 0x21                            # LD HL,nn
                and bios_bytes[pc + 17] == 0x22 and bios_bytes[pc + 18] == 0x06
                and bios_bytes[pc + 19] == 0x00):                          # LD ($0006),HL
            warm_target = bios_bytes[pc + 6] | (bios_bytes[pc + 7] << 8)
            bdos_target = bios_bytes[pc + 15] | (bios_bytes[pc + 16] << 8)
            warm = VectorPlant(
                name="z80_warm_boot",
                plant_addr=0x0000,
                target_addr=warm_target,
                pc_in_loader=bios_org + pc,
            )
            bdos = VectorPlant(
                name="bdos_entry_z80",
                plant_addr=0x0005,
                target_addr=bdos_target,
                pc_in_loader=bios_org + pc + 11,
            )
            return warm, bdos
        pc += 1
    return None, None


def find_handoff(disk_path: Path | str,
                 *, bios_path: Path | str | None = None,
                 bios_org: int | None = None) -> HandoffInfo:
    """Identify the handoff signals in a CP/M disk's loader.

    When `bios_path` is provided, the Z-80-side vector planting code
    (warm-boot vector + BDOS entry vector) is also detected from the
    BIOS bytes. If omitted, only the 6502-side reset vector plant and
    the CPU-switch trigger are reported.
    """
    disk_path = Path(disk_path)
    info = detect(disk_path)
    h = HandoffInfo(disk_path=disk_path)

    if not info.has_boot_stub:
        h.notes.append("no SoftCard boot stub; can't trace handoff")
        return h

    raw = disk_path.read_bytes()
    image = _build_loader_image(
        raw, info.format, info.boot_stub_destinations or [],
    )

    # 6502-side: Z-80 reset vector plant. The 6502 stores at Apple
    # $1000-$1002 because SoftCard's bit-12 XOR maps Apple $1000 to
    # Z-80 $0000.
    plant = (_find_vector_plant(image, 0x1000)
             or _find_compact_vector_plant(image, 0x1000))
    if plant:
        plant.name = "z80_reset"
        h.z80_reset_plant = plant

    # CPU-switch trigger (in the warm-boot routine at $13C0+)
    h.cpu_switch_trigger = _find_cpu_switch_trigger(image)

    # Z-80-side BIOS planting (warm-boot vector + BDOS entry).
    # Requires a BIOS binary. Auto-detect path if not supplied: look
    # for cpm-investigation/bios_NNN.bin matching the variant.
    if bios_path is None:
        guess = _guess_bios_path(disk_path, info.variant)
        if guess and guess.exists():
            bios_path = guess
            if bios_org is None:
                # Corrected 2026-06-11: true bases $FA00/$DA00 (was
                # $FAB8/$DACC under the wrong address model).
                bios_org = (0xFA00 if info.variant == "softcard_cpm_2_23"
                            else 0xDA00 if info.variant == "softcard_cpm_2_20"
                            else None)

    if bios_path is not None and bios_org is not None:
        bios_bytes = Path(bios_path).read_bytes()
        warm, bdos = _find_z80_bios_planting(bios_bytes, bios_org)
        if warm:
            h.z80_reset_plant = h.z80_reset_plant or warm
        if bdos:
            h.bdos_entry_plant = bdos
        if not warm and not bdos:
            h.notes.append(
                f"BIOS {Path(bios_path).name}: no Z-80-side vector "
                f"planting code matched (pattern may differ)"
            )

    return h


def _guess_bios_path(disk_path: Path, variant: str) -> Path | None:
    """Find the matching bios_NNN.bin for `variant`.

    Delegates to reference_data.bios_bin, which locates the binary relative to
    the package (not the disk), so the disk image may live anywhere. disk_path
    is kept in the signature for API symmetry with the other detectors.
    """
    del disk_path  # intentionally unused: aux data is package-relative, not disk-relative
    from .reference_data import bios_bin
    return bios_bin(variant)
