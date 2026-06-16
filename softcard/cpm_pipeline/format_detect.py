"""Stage 1 — disk-format detection.

Given a raw `.dsk` or `.po` image, structurally determine what's there:

  * File format and size sanity check.
  * Whether sector 0 looks like a CP/M-style boot stub (P6 PROM compatible).
  * The boot-stub's count byte (sector 0 byte 0; the page count P6 PROM
    increments).
  * The CP/M sector skew table embedded in the boot stub (typically at
    file offset $2D for SoftCard CP/M; the 16-byte table the stub
    indexes by sector counter).
  * How many sectors of track 0 the boot stub loads (deduced from the
    skew table position and the stage-2 entry's `JMP $1000`).
  * Best-effort CP/M variant identification (2.20 vs 2.23 vs unknown)
    by signature-matching the stage-2 slot scanner.

This module produces a structured `DiskFormat` object that Phase 3
(boot-loader tracing) consumes. It does not require any of the
hand-maintained chunk maps — the detection works on the bytes alone.

For WOZ input (raw flux), nibbler's existing GCR layer handles the
nibble→sector decoding and the result lands here as a `.dsk`-equivalent
sector stream. WOZ-specific detections (custom prologs, etc.) are out
of scope for this module; nibbler already covers them.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from pathlib import Path

from .disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE,
    DISK_SIZE, SECTOR_SIZE, SECTORS_PER_TRACK, TRACKS,
    detect_format as detect_format_from_extension,
)


# ── Known boot-stub signatures ────────────────────────────────────────
#
# The first ~12 bytes of a SoftCard CP/M boot stub are highly recognizable
# and identical across 2.20 and 2.23. The pattern (interpreted as 6502):
#
#   $0800  $01           ; count byte (P6 PROM page count)
#   $0801  A5 27         ; LDA $27        ; load page count
#   $0803  C9 09         ; CMP #$09       ; first re-entry?
#   $0805  D0 13         ; BNE +$13       ; if not, skip init
#   $0807  8A            ; TXA            ; X = slot * 16
#   $0808  4A 4A 4A 4A   ; LSR LSR LSR LSR ; isolate slot number
#   $080C  09 C0         ; ORA #$C0       ; -> $C0 + slot
#   $080E  85 3F         ; STA $3F        ; slot ROM page hi
#
# Total fingerprint: 16 bytes. The (LSR; LSR; LSR; LSR; ORA #$C0)
# combination is essentially uniquely diagnostic.

SOFTCARD_BOOT_FINGERPRINT = bytes.fromhex(
    "01"                # count byte
    "A527"              # LDA $27
    "C909"              # CMP #$09
    "D013"              # BNE +$13
    "8A"                # TXA
    "4A4A4A4A"          # LSR LSR LSR LSR
    "09C0"              # ORA #$C0
    "853F"              # STA $3F
)


# Pascal-1.1 detection branch (2.23 stage-2 only). Per
# docs/CPM_Videx_Difference.md, the 2.23 slot scanner inserts the
# following exact byte sequence after the standard slot-signature loop:
#
#   E0 04    CPX #$04           ; matched standard Pascal (sig #3)?
#   D0 0A    BNE skip           ; no -> normal handling
#   A0 0B    LDY #$0B           ; Y = Pascal-1.1 signature byte offset
#   B1 3C    LDA ($3C),Y        ; A = byte at $Cn0B of slot ROM
#   C9 01    CMP #$01           ; Pascal 1.1 generic device marker?
#   D0 02    BNE skip           ; no -> normal handling
#  (then LDX #$06 follows -- A2 06 -- but it's reachable from the
#   normal path too, so we don't include it in the signature.)
#
# This 12-byte sequence is the unique bullet point distinguishing 2.23
# from 2.20 in the boot loader.

SOFTCARD_223_PASCAL11_SIGNATURE = bytes.fromhex(
    "E004"              # CPX #$04
    "D00A"              # BNE +$0A
    "A00B"              # LDY #$0B
    "B13C"              # LDA ($3C),Y
    "C901"              # CMP #$01
    "D002"              # BNE +$02
)


# ── Result dataclass ──────────────────────────────────────────────────
@dataclass
class DiskFormat:
    """Structured detection result for a single disk image."""
    path: Path
    format: str                                 # 'dsk' or 'po'
    size_bytes: int
    tracks: int = TRACKS
    sectors_per_track: int = SECTORS_PER_TRACK
    sector_size: int = SECTOR_SIZE

    # Boot stub
    has_boot_stub: bool = False
    boot_stub_count_byte: int | None = None     # byte at $0800
    boot_stub_fingerprint_match: bool = False   # SoftCard signature?
    sector_skew_table: list[int] | None = None  # the 16-byte table at $082D
    boot_stub_load_count: int | None = None     # how many sectors loaded
    boot_stub_destinations: list[tuple[int, int]] | None = None
        # (apple_address, physical_sector) pairs derived from the skew table

    # Variant identification
    variant: str = "unknown"                    # 'softcard_2_20' / 'softcard_2_23' / 'unknown'
    variant_confidence: str = "low"             # 'high' / 'medium' / 'low'
    variant_evidence: list[str] = field(default_factory=list)

    # Misc
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        """Human-readable single-paragraph summary."""
        parts = [f"{self.path.name}: {self.format.upper()} format, "
                 f"{self.size_bytes} bytes ({self.tracks}T x "
                 f"{self.sectors_per_track}S x {self.sector_size}B)"]
        if not self.has_boot_stub:
            parts.append("no recognizable CP/M boot stub at sector 0")
        else:
            parts.append(
                f"boot stub: count={self.boot_stub_count_byte}, "
                f"loads {self.boot_stub_load_count} sectors of track 0"
            )
            if self.sector_skew_table:
                skew_hex = " ".join(f"{b:X}" for b in self.sector_skew_table)
                parts.append(f"skew table: {skew_hex}")
        parts.append(f"variant: {self.variant} (confidence: {self.variant_confidence})")
        if self.variant_evidence:
            parts.append(f"evidence: {'; '.join(self.variant_evidence)}")
        return "\n  ".join(parts)


# ── Detection ─────────────────────────────────────────────────────────
def detect(path: Path | str) -> DiskFormat:
    """Inspect a `.dsk`/`.po` image and return a structured DiskFormat."""
    path = Path(path)
    raw = path.read_bytes()
    fmt = detect_format_from_extension(path)

    result = DiskFormat(
        path=path,
        format=fmt,
        size_bytes=len(raw),
    )

    # Sanity check size
    if len(raw) != DISK_SIZE:
        result.notes.append(f"unexpected size {len(raw)}, expected {DISK_SIZE}")
        return result

    # Read sector 0 (boot sector) — at file offset 0 in both DSK and PO,
    # since track 0 logical 0 maps to the first 256 bytes regardless
    # of interleave (DOS33_INTERLEAVE[0] == PRODOS_INTERLEAVE[0] == 0).
    sector_zero = raw[:SECTOR_SIZE]

    result.boot_stub_count_byte = sector_zero[0]

    # Check fingerprint
    if sector_zero[:len(SOFTCARD_BOOT_FINGERPRINT)] == SOFTCARD_BOOT_FINGERPRINT:
        result.has_boot_stub = True
        result.boot_stub_fingerprint_match = True

        # Extract the sector skew table. SoftCard boot stub stores it at
        # $082D, which is byte offset 0x2D in sector 0.
        skew = list(sector_zero[0x2D:0x2D + 16])
        # Sanity: skew must be a permutation of 0..15.
        if sorted(skew) == list(range(16)):
            result.sector_skew_table = skew
            # The boot stub loads sectors[1..N] of the skew table (skipping
            # sector[0] which is the boot sector itself, loaded by P6 PROM).
            # The CMP #$0B at $081E is the loop terminator; the LSB after
            # CMP # tells us how many sectors get loaded.
            cmp_count = sector_zero[0x1F]  # the $0B byte after `CPY #` at $081E
            result.boot_stub_load_count = cmp_count - 1  # loop runs counter 1..N-1
            # Build the destination map: each loaded sector lands at
            # successive Apple addresses starting from $0A00 (the first
            # destination after the gap at $0900).
            destinations = []
            apple_addr = 0x0A00
            for i in range(1, cmp_count):  # skew indices 1..cmp_count-1
                destinations.append((apple_addr, skew[i]))
                apple_addr += SECTOR_SIZE
            result.boot_stub_destinations = destinations
        else:
            result.notes.append(
                f"skew table at $082D doesn't look valid: {skew}"
            )

    # Try to identify the CP/M variant. Search the entire boot loader
    # region (track 0 — physical sectors loaded by the boot stub) for
    # the Pascal-1.1 signature.
    if result.has_boot_stub:
        # Read all 16 sectors of track 0 in physical-sector order
        # (regardless of on-disk format) so we can search the loader
        # bytes for signatures.
        interleave = DOS33_INTERLEAVE if fmt == "dsk" else PRODOS_INTERLEAVE
        track0_physical = bytearray(16 * SECTOR_SIZE)
        for phys in range(16):
            on_disk = interleave[phys]
            track0_physical[phys * SECTOR_SIZE:(phys + 1) * SECTOR_SIZE] = (
                raw[on_disk * SECTOR_SIZE:(on_disk + 1) * SECTOR_SIZE]
            )

        if SOFTCARD_223_PASCAL11_SIGNATURE in track0_physical:
            result.variant = "softcard_cpm_2_23"
            result.variant_confidence = "high"
            result.variant_evidence.append(
                "Pascal-1.1 detection branch present in stage-2 (2.23 only)"
            )
        else:
            result.variant = "softcard_cpm_2_20"
            result.variant_confidence = "medium"
            result.variant_evidence.append(
                "boot stub matches SoftCard CP/M signature; no Pascal-1.1 "
                "branch found (consistent with 2.20)"
            )

    return result
