"""Regenerate docs/CPM223_BIOS.asm from cpm-investigation/bios_223.bin.

Runs disasm_z80 with the standard CP/M 2.23 BIOS configuration (all 17
jump-table entries seeded, trap-marker pages marked as data, CP/M and
2.23-specific symbol tables loaded), then prepends a prose header and
inserts per-section / per-routine annotations.

The output reassembles to byte-identical bytes via:

    sjasmplus docs/CPM223_BIOS.asm

This replaces the prior gen_223_bios.py that called the now-deleted
`nibbler z80disasm` subcommand.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from disasm_z80.cli import main as disasm_main


# ── Per-label prose blocks ────────────────────────────────────────────
LABEL_PROSE = {
    "BOOT": [
        "",
        "; ============================================================================",
        "; SECTION 1 -- BIOS Jump Table  ($FAB8-$FAEA)",
        ";",
        "; Standard CP/M 2.x 17-entry jump table (15 disk/console + LISTST + SECTRAN).",
        "; Entries 0-14 are 3-byte JP instructions whose targets land in code page 0,",
        "; code page 4, or runtime-populated dispatch slots in pages 1/3/5.",
        "; Entries 15 (LISTST) and 16 (SECTRAN) are inline 1- to 3-byte routines.",
        ";",
        "; Targets:",
        ";   BOOT  -> BOOT_LANDING ($FED1) -- NOP slide leading to device-scan",
        ";   WBOOT -> BOOT itself          -- on this build, warm boot = cold boot",
        ";   CONST/CONIN/CONOUT/LIST/PUNCH/READER -> page-0 dispatch stubs",
        ";   HOME/SELDSK/SETTRK            -> page-4 (BOOT vector landing area)",
        ";   SETSEC/SETDMA                 -> page-1 (trap-marker dispatch slots)",
        ";   READ/WRITE                    -> page-4 (overwritten by cold-boot generator)",
        "; ============================================================================",
        "",
    ],
    "L_FB10": [
        "",
        "; ============================================================================",
        "; SECTION 2 -- Code-page 0 dispatch stubs  ($FAEB-$FB39)",
        ";",
        "; Each console/list/punch/reader BIOS entry above lands in this page.",
        "; The static bytes here are mostly $00 / $E4 $FE $73 $FA / $FF $FF patterns",
        "; that look like CALL PO,$73FE / JP M,nnnn instructions but are inert at boot",
        "; time -- the cold-boot generator at SECTION 3 overwrites them with the",
        "; appropriate device dispatch code before any jump-table entry can fire.",
        ";",
        "; The lookup table at $FB2B-$FB39 is the device-code -> per-character-device",
        "; init parameter table (read by SECTION 3).",
        "; ============================================================================",
        "",
    ],
    "L_FB3D": [
        "",
        "; ============================================================================",
        "; SECTION 3 -- Cold-boot generator (the Z-80 side of the Videx fix)",
        ";",
        "; Walks the slot-info table at $F3B8+E for E=7,6,...,1, dispatching by",
        "; device code:",
        ";   3 -> CALL INIT_KEYBOARD     ($FE81)",
        ";   4 -> CALL INIT_PASCAL_1_0   ($FD83)  -- old Pascal firmware",
        ";   6 -> CALL INIT_PASCAL_1_1   ($FDB0)  -- NEW IN 2.23 (the Videx delta)",
        ";",
        "; The 11-byte 6502 slot-scanner branch in the boot loader writes '6' into",
        "; this slot-info table for Pascal-1.1 cards (Videx Videoterm). Without that",
        "; branch on the 6502 side, only codes 3 and 4 are ever generated, and a",
        "; 2.20 system trying to call INIT_PASCAL_1_1 would land on whatever bytes",
        "; happen to live at $FDB0 (a JR NZ to a trap marker -> system hang).",
        ";",
        "; Loop body (per slot E):",
        ";   * read device code from $F3B8+E",
        ";   * if code==3, fill HL with $0315 and call $FE81",
        ";   * if code==4, call $FD83 and then PRINT_STR (HL := $C800)",
        ";   * if code==6, set HL := $0DD0 and call $FDB0 (Pascal 1.1 init)",
        "; ============================================================================",
        "",
    ],
    "L_FB70": [
        "",
        "; ============================================================================",
        "; SECTION 4 -- Stage 2 cold boot  ($FB70-$FB96)",
        ";",
        "; Sets the Z-80 stack to $0080 (CP/M default), reads Apple text-mode flag,",
        "; loads HL with $0E00, calls SECTION 3 ($FB45 = code-overlap entry into the",
        "; generator), then CALL $FA82 (a routine in the BDOS area that performs",
        "; remaining device init).",
        ";",
        "; The check at $FB7F-$FB85 reads BDOS_SENTINEL ($9C08): if it equals $9C",
        "; we're cold-booting (no warm-boot state yet), so jump to SECTION 5; otherwise",
        "; continue with a warm-boot path that points $0006 at $9C06 (BDOS entry) and",
        "; jumps through $000B (the warm-boot vector planted at boot).",
        "; ============================================================================",
        "",
    ],
    "L_FB97": [
        "",
        "; ============================================================================",
        "; SECTION 5 -- Stage 3 cold boot  ($FB97-$FBB7)",
        ";",
        "; Initial cold-boot setup. Zeros several state bytes, then plants the",
        "; CP/M conventional vectors at the bottom of memory:",
        ";   $0000-$0002 := JP $FA03    (warm-boot vector via BIOS)",
        ";   $0005-$0007 := JP $9C06    (BDOS entry)",
        ";",
        "; After this, falls into the trap-marker page where the cold-boot generator",
        "; has installed runtime code that completes initialization.",
        "; ============================================================================",
        "",
    ],
    "INIT_PASCAL_1_0": [
        "",
        "; ============================================================================",
        "; INIT_PASCAL_1_0 -- per-slot Pascal 1.0 firmware init  ($FD83)",
        ";",
        "; Called by SECTION 3 when slot E's device code == 4. Walks the per-slot",
        "; state from $F388 / $F3A1 etc., and calls the per-device helpers in page 1",
        "; that the trap-marker bytes have been overwritten with.",
        "; ============================================================================",
        "",
    ],
    "INIT_PASCAL_1_1": [
        "",
        "; ============================================================================",
        "; INIT_PASCAL_1_1 -- per-slot Pascal 1.1 firmware init  ($FDB0)  *** 2.23 NEW ***",
        ";",
        "; In 2.23 this is just RET. Its existence (versus 2.20's $FDB0 falling on a",
        "; trap marker that happens to decode as a JR NZ branching into more trap",
        "; markers) is what allows the cold-boot generator to dispatch device code 6",
        "; to a known landing spot. The actual Pascal-1.1 init is performed by code",
        "; that 2.23's BIOS sets up via runtime patching of higher addresses.",
        ";",
        "; This RET is the literal one-byte fix that makes Videx Videoterm work on",
        "; CP/M 2.23: 2.20 had no entry here, so a slot reporting device code 6",
        "; would crash the cold-boot generator.",
        "; ============================================================================",
        "",
    ],
    "L_FF0E": [
        "",
        "; ============================================================================",
        "; SECTION 6 -- Device-scan / slot-walk routine  ($FF0E-$FF6C)",
        ";",
        "; Reaches here from the BOOT_LANDING NOP slide. Scans the device-code table",
        "; at $F3A0 (9 entries down from $F3A0, comparing E XOR slot-code against C).",
        "; On match, picks up further config from $F3A0+11 and dispatches into the",
        "; per-device init code in page 1 (which by now has been overwritten by the",
        "; cold-boot generator above).",
        ";",
        "; This is the routine the standard BIOS jump-table entries HOME/SELDSK/",
        "; SETTRK eventually reach via the BOOT_LANDING NOP slide.",
        "; ============================================================================",
        "",
    ],
}


HEADER = """\
; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- Z-80 BIOS  ($FAB8-$FFFF, 1352 bytes)
;
; Annotated Z-80 source for the BIOS region as the Z-80 sees it in LC RAM
; after the SoftCard CPU switch. Reassembles byte-identically via:
;
;     sjasmplus docs/CPM223_BIOS.asm
;
; STRUCTURE -- 256-byte interleaved layout
; ----------------------------------------
;   Page 0  $FAB8-$FBB7  Jump table, dispatch stubs, cold-boot generator (CODE)
;   Page 1  $FBB8-$FCB7  Trap markers (RUNTIME-POPULATED)
;   Page 2  $FCB8-$FDB7  Per-device init helpers (CODE)
;   Page 3  $FDB8-$FEB7  Trap markers (RUNTIME-POPULATED)
;   Page 4  $FEB8-$FFB7  Device-scan + BOOT vector landing (CODE)
;   Page 5  $FFB8-$FFFF  Trap markers, partial 72 bytes (RUNTIME-POPULATED)
;
; Trap markers are "FF FF 00 00" / "F7 F7 00 00" patterns that decode as
; RST $38 / RST $30 -- inert at boot. Static BIOS code calls/jumps into
; these pages; the cold-boot generator overwrites them with real code
; before any such call/jump fires.
;
; THE COLD-BOOT GENERATOR (Z-80 side of the Videx fix)
; ----------------------------------------------------
; At SECTION 3 below ($FB3A). Walks slot-info table at $F3B8+E for E=7..1,
; dispatches by device code:
;   3 -> INIT_KEYBOARD    ($FE81)
;   4 -> INIT_PASCAL_1_0  ($FD83)
;   6 -> INIT_PASCAL_1_1  ($FDB0)   <-- NEW IN 2.23 (the Videx fix)
;
; The 11-byte 6502 slot-scanner branch in CPM223_BootLoader.asm is what
; writes "6" into the slot-info table for Pascal-1.1 cards. The generator's
; new branch here turns that into a runtime dispatch into INIT_PASCAL_1_1
; instead of falling on a trap marker.
;
; DUAL ADDRESSING
; ---------------
; The first 1 KB of this BIOS ($FAB8-$FEB7) ALSO appears at Z-80 $1C38-$1FB7
; under SoftCard's bit-12 XOR for low addresses. Same physical bytes, two
; Z-80 views. This is how the inter-CPU sync polling at $1E39 (the Z-80
; disk-callback area) reaches the same code that the BIOS jump table dispatches.
;
; SOURCE
; ------
; Loaded by the 6502 from disk via two LOAD_CPM passes (the second one
; bank-switches LC RAM via STA $C083 to write into SoftCard high RAM).
; Bytes at $FAB8 ultimately come from physical disk sectors trk2:phys4-9
; of CPMV233.DSK.
; ============================================================================

"""


def disassemble_to_string():
    """Run disasm_z80 and capture its .asm output as a string."""
    import tempfile
    bin_path = REPO_ROOT / "cpm-investigation" / "bios_223.bin"
    cpm = REPO_ROOT / "symbols" / "cpm_2_2.json"
    cpm223 = REPO_ROOT / "symbols" / "cpm_2_23_bios.json"
    entries = [f"${0xFAB8 + i*3:04X}" for i in range(17)]
    with tempfile.TemporaryDirectory() as tmp:
        out_base = Path(tmp) / "bios"
        argv = [
            str(bin_path),
            "--org", "$FAB8", "--length", "$0548",
            "--symbols", str(cpm),
            "--symbols", str(cpm223),
            "--output", str(out_base),
            "--data-region", "$FBB8-$FCB7",
            "--data-region", "$FDB8-$FEB7",
            "--data-region", "$FFB8-$FFFF",
        ]
        for e in entries:
            argv += ["--entry", e]
        rc = disasm_main(argv)
        if rc != 0:
            raise RuntimeError("disasm_z80 failed")
        return out_base.with_suffix(".asm").read_text(encoding="utf-8")


def inject_prose(disasm_text):
    """Walk the disasm output line by line; before any line introducing a
    label whose name is in LABEL_PROSE, insert that prose block."""
    out = []
    for line in disasm_text.splitlines():
        stripped = line.rstrip()
        if stripped.endswith(":"):
            label = stripped[:-1].strip()
            if label in LABEL_PROSE:
                out.extend(LABEL_PROSE[label])
        out.append(line)
    return "\n".join(out) + "\n"


def main():
    disasm = disassemble_to_string()
    # Strip the disasm's auto-generated comment header; keep from `DEVICE NOSLOT64K`
    # onward. Also rewrite the SAVEBIN target to a stable build path.
    lines = disasm.splitlines()
    body_start = 0
    for i, line in enumerate(lines):
        if line.lstrip().startswith("DEVICE NOSLOT64K"):
            body_start = i
            break
    body_lines = lines[body_start:]
    # Rewrite SAVEBIN line (replaces the temp path the CLI baked in).
    for i, line in enumerate(body_lines):
        if "SAVEBIN" in line:
            body_lines[i] = ('    SAVEBIN "build/CPM223_BIOS.bin", $FAB8, $0548')
    body = "\n".join(body_lines)
    body = inject_prose(body)

    out_path = REPO_ROOT / "docs" / "CPM223_BIOS.asm"
    out_path.write_text(HEADER + body, encoding="utf-8")
    print(f"wrote {out_path}  ({out_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
