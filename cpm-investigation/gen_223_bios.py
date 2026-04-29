"""Generate CPM223_BIOS.asm — annotated Z-80 source for the BIOS at $FAB8-$FFFF."""
import subprocess

# Disassemble the BIOS region. Note bios_223.bin is 2048 bytes covering
# $FAB8-$FFFF (1352 bytes) plus extra bytes that wrap or overshoot;
# we only want $FAB8-$FFFF here.
result = subprocess.run(
    ['python', '-m', 'nibbler', 'z80disasm', 'cpm-investigation/bios_223.bin',
     '--base', '0xFAB8', '--start', '0xFAB8', '--end', '0xFFFF', '--format', 'asm'],
    capture_output=True,
)
disasm = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm.split('\n')]

SECTIONS = {
    0xFAEB: """
; ============================================================================
; SECTION 3 -- Per-device dispatch table ($FAEB-$FB29)
;
; 4 entries x 16 bytes each = 64 bytes. Each entry holds 8 zero/state
; bytes followed by 4 pointers:
;   bytes 0-7: per-entry runtime-mutable state (set at boot, modified
;              during cooperative-CPU operations)
;   bytes 8-9: $FEE4 (state-byte address common to all entries)
;   bytes 10-11: $FE73 or similar (entry-point trampoline)
;   bytes 12-13: per-entry handler 1 address (for one of CONOUT/CONIN/etc)
;   bytes 14-15: per-entry handler 2 address
;
; All 4 dispatch targets land in TRAP-MARKER PAGES on disk -- they're
; populated at runtime by the cold-boot generator. See Part 6 of the
; article series ("The BIOS Factory").
; ============================================================================

""",
    0xFB2B: """
; ============================================================================
; SECTION 4 -- Control-character data table ($FB2B-$FB39)
; ============================================================================

""",
    0xFB3A: """
; ============================================================================
; SECTION 5 -- COLD-BOOT GENERATOR ($FB3A-$FB68) - "THE BIOS FACTORY"
;
; Walks slots 7..1 looking up device codes from the slot-info table
; built by the 6502 slot scanner. Dispatches per-device init based on
; what was detected.
;
; Device codes handled:
;   3 -> CALL $FE81
;   4 -> CALL $FD83 (Pascal 1.0; +HL=$C800 setup)
;   6 -> CALL $FDB0 (Pascal 1.1 / Videx) <- NEW IN 2.23, ABSENT FROM 2.20
;
; This is the Z-80 side of the Videx fix. See Part 6 of the article
; series for full context.
; ============================================================================

""",
    0xFB69: """
; ============================================================================
; SECTION 6 -- Small helper ($FB69-$FB6F)
; ============================================================================

""",
    0xFB70: """
; ============================================================================
; SECTION 7 -- Cold-boot continuation / WBOOT ($FB70-$FBB6)
;
; The bytes at $FB70 are reached as the LIST jump-table entry but the
; code is cold-boot-style: stack init, BDOS-vector planting, Z-80 reset
; vector rewrite. The actual BOOT vector ($FED1) presumably reaches
; this code via runtime-installed bytes in its NOP-slide region.
;
; Key actions:
;   - Init Z-80 stack to $0080
;   - First-boot vs warm-boot detect via $9C08 sentinel
;   - Plant $C3 at Z-80 $0000-$0002: rewrites reset vector from
;     "JP $FA00" (planted by 6502) to "JP $FA03" (skip first-instruction
;     init on subsequent warm-boots)
;   - Plant $C3 + $9C06 at $0005-$0007: standard CP/M BDOS call vector
;     pointing at the relocated BDOS at $9C06
; ============================================================================

""",
    0xFBB8: """
; ============================================================================
; SECTION 8 -- TRAP-MARKER PAGE 1 ($FBB8-$FCB7)
;
; 256 bytes of "FF FF 00 00 / F7 F7 00 00" pattern -- decodes as
; RST $38 / RST $30 traps. Premature execution lands in a defined
; CP/M low-memory vector rather than wandering.
;
; AT RUNTIME, this region is populated with per-device handler code
; by the cold-boot generator at $FB3A. The static code at $FF42 and
; elsewhere does JP P,$FC9A which lands in this page after population.
; The exact mechanism by which population happens is open work (likely
; involves the second JSR $BBEB load and/or copies from Apple $1Cxx).
; ============================================================================

""",
    0xFCB8: """
; ============================================================================
; SECTION 9 -- Code page 2 ($FCB8-$FDB7)
;
; Per-device init helpers and dispatch helpers. Includes:
;   $FD83  device-4 (Pascal 1.0) init -- called by generator
;   $FDB0  device-6 (Pascal 1.1) init -- called by generator
;          NOTE: as it appears on disk, $FDB0 is ONE BYTE: a "RET"
;          stub. The actual driver-install path lives elsewhere.
;          See $FDB0-stub devlog for the dead-end finding.
; ============================================================================

""",
    0xFDB8: """
; ============================================================================
; SECTION 10 -- TRAP-MARKER PAGE 3 ($FDB8-$FEB7)
;
; Another 256-byte runtime-population zone. The cold-boot generator's
; CALL $FE81 (device-3 init) lands HERE when this page is populated;
; on disk, $FE81 is a trap marker.
; ============================================================================

""",
    0xFEB8: """
; ============================================================================
; SECTION 11 -- Code page 4 ($FEB8-$FFB7)
;
; Contains the BOOT vector landing zone (NOP slide $FED1-$FF0D) and
; the static device-scan loop at $FF0E.
;
; The BIOS jump table sends BOOT to $FED1, which is in the NOP slide.
; Execution flows through ~60 NOPs and reaches the device-scan code at
; $FF0E. The scan walks 9 entries from $F3A0 (slot info) looking for a
; match against the current device code.
;
; HOME ($FE6C), SETTRK ($FE77), SELDSK ($FE8E), READ ($FEBD), WRITE
; ($FEC0) all jump-table targets land in this page or the NOP slide.
; READ and WRITE specifically land at $FEBD/$FEC0 in the NOP region;
; their actual handler bytes get installed there at boot.
; ============================================================================

""",
    0xFFB8: """
; ============================================================================
; SECTION 12 -- TRAP-MARKER PAGE 5 partial ($FFB8-$FFFF)
;
; 72 bytes of trap markers. End of BIOS.
;
; Per-device handler dispatch entries from the dispatch table at
; $FAEB target $FFAC, $FFB8, $FFC4, $FFD0 -- in this region. Populated
; at runtime by the cold-boot generator.
; ============================================================================

""",
}

body_parts = []
for line in lines:
    if line and line.startswith('$'):
        addr_str = line[1:5]
        try:
            addr = int(addr_str, 16)
            if addr in SECTIONS:
                body_parts.append(SECTIONS[addr])
        except ValueError:
            pass
    body_parts.append(line)
body = '\n'.join(body_parts)

HEADER = """; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- Z-80 BIOS ($FAB8-$FFFF, 1352 bytes)
; Annotated Z-80 assembly source for the BIOS region as Z-80 sees it
; in LC RAM after the SoftCard CPU switch.
;
; STRUCTURE
;   The BIOS uses a 256-byte interleaved layout: code pages alternating
;   with runtime-generated pages.
;
;     Page 0  $FAB8-$FBB7  Jump table, dispatch table, generator (CODE)
;     Page 1  $FBB8-$FCB7  Trap markers (RUNTIME-POPULATED)
;     Page 2  $FCB8-$FDB7  Per-device init helpers (CODE)
;     Page 3  $FDB8-$FEB7  Trap markers (RUNTIME-POPULATED)
;     Page 4  $FEB8-$FFB7  Device-scan + BOOT vector landing (CODE)
;     Page 5  $FFB8-$FFFF  Trap markers partial (RUNTIME-POPULATED, 72 bytes)
;
;   Trap markers are "FF FF 00 00 / F7 F7 00 00" patterns that decode
;   as RST $38 / RST $30. Static BIOS code calls/jumps into these
;   pages; the bytes get populated at runtime by the cold-boot
;   generator before any such call/jump fires.
;
; THE COLD-BOOT GENERATOR (Z-80 side of the Videx fix)
;   At $FB3A. Walks the slot-info table at $F3B8+E for E=7..1, dispatches
;   per device code:
;     3 -> $FE81
;     4 -> $FD83 (Pascal 1.0)
;     6 -> $FDB0 (Pascal 1.1) <- NEW IN 2.23
;   The 11-byte 6502 slot-scanner branch (in CPM223_BootLoader.asm) is
;   what writes "6" into the slot-info table for Pascal 1.1 cards. The
;   generator's branch here turns that into a runtime dispatch.
;
; DUAL ADDRESSING
;   The BIOS first 1 KB ($FAB8-$FEB7) ALSO appears at Z-80 $1C38-$1FB7
;   under SoftCard's bit-12 XOR for low addresses. Same physical bytes,
;   accessed via two different Z-80 views of memory. This is how the
;   inter-CPU sync polling loop at $1E39 (the Z-80 disk-callback area)
;   reaches the same code that the BIOS jump table dispatches.
;
; SOURCE
;   Loaded by the 6502 from disk via two LOAD_CPM passes (the second
;   one bank-switches LC RAM via STA $C083 to write into the SoftCard's
;   high-RAM area). The bytes here at $FAB8 ultimately come from
;   physical disk sectors trk2:phys4-9 of CPMV233.DSK.
; ============================================================================

; ----------------------------------------------------------------------------
; Z-80 BIOS state slots (in trap-marker pages, populated at runtime)
; ----------------------------------------------------------------------------
state_FECB      = $FECB       ; current track
state_FED2      = $FED2       ; current sector
state_FED4      = $FED4       ; current DMA address (16-bit)
state_FECD      = $FECD       ; cold-boot state byte (preflight check)
state_FED8      = $FED8       ; (zeroed by cold-boot setup at $FB9F)
state_FEDD      = $FEDD       ; (zeroed by cold-boot setup at $FB9C)

; ----------------------------------------------------------------------------
; TPA-area state (above BDOS, below BIOS)
; ----------------------------------------------------------------------------
slot_info_F3A0  = $F3A0       ; device-code table base (scanned by device-scan)
slot_info_F3B8  = $F3B8       ; slot-info table for cold-boot generator
                              ;   F3B8+E = slot E's device code (E=1..7)
state_F397      = $F397       ; (read by preflight code at $FF17)

; ----------------------------------------------------------------------------
; CCP+BDOS final positions (after relocation by loader's third page copy)
; ----------------------------------------------------------------------------
BDOS_ENTRY      = $9C06       ; planted at $0005-$0007 as "JP $9C06"
BDOS_SENTINEL   = $9C08       ; first-boot vs warm-boot detect

; ----------------------------------------------------------------------------
; Apple I/O (used by BIOS for Apple ][ video state)
; ----------------------------------------------------------------------------
APPLE_TEXT_FLAG = $E051       ; Apple ][ video text/graphics state

            .ORG $FAB8


; ============================================================================
; SECTION 1 -- BIOS Jump Table ($FAB8-$FAE4)
;
; Standard CP/M 2.x 15-entry jump table. Each entry is "JP target".
; Many targets land in trap-marker pages, where bytes get populated
; at runtime by the cold-boot generator before any of these jumps fire.
;
;   Offset  Address  Routine     Target
;   0       $FAB8    BOOT        $FED1  (NOP slide -> device-scan)
;   3       $FABB    WBOOT       $FAB8  (jumps to BOOT)
;   6       $FABE    CONST       $FB10  (in code page 0)
;   9       $FAC1    CONIN       $FB1A
;   12      $FAC4    CONOUT      $FB4D
;   15      $FAC7    LIST        $FB70  (cold-boot continuation routine
;                                        also reachable here)
;   18      $FACA    PUNCH       $FB7F
;   21      $FACD    READER      $FB91
;   24      $FAD0    HOME        $FE6C
;   27      $FAD3    SELDSK      $FE8E
;   30      $FAD6    SETTRK      $FE77
;   33      $FAD9    SETSEC      $FBF4
;   36      $FADC    SETDMA      $FBF9
;   39      $FADF    READ        $FEBD
;   42      $FAE2    WRITE       $FEC0
;
; Many READ/WRITE/HOME/etc. targets land in the NOP slide of code page 4.
; Their actual handler bytes get planted there at boot time.
; ============================================================================

JUMP_TABLE:
"""

FOOTER = """

; ============================================================================
; END OF BIOS ($FFFF)
;
; Z-80 reset vector at $0000 was planted by the 6502 as "JP $FA00".
; $FA00 is below this BIOS (in another runtime-generated region 184
; bytes long). Cold-boot setup at $FB70 rewrites $0001-$0002 to
; "JP $FA03" so subsequent warm-boots skip the cold-only first
; instruction.
;
; The cold-boot setup also plants the standard CP/M BDOS call vector:
;   $0005: $C3 (JP opcode)
;   $0006-$0007: $9C06 (BDOS entry after relocation)
; This is what user programs call via "CALL $0005" to reach BDOS.
; ============================================================================
"""

with open('docs/CPM223_BIOS.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM223_BIOS.asm')
print(f'Written: docs/CPM223_BIOS.asm ({size} bytes)')
