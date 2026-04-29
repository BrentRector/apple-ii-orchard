"""Generate CPM220_BIOS.asm — annotated Z-80 source for the 2.20 BIOS at $DACC-$E2CB."""
import subprocess

result = subprocess.run(
    ['python', '-m', 'nibbler', 'z80disasm', 'cpm-investigation/bios_220.bin',
     '--base', '0xDACC', '--start', '0xDACC', '--end', '0xE2CB', '--format', 'asm'],
    capture_output=True,
)
disasm = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm.split('\n')]

SECTIONS = {
    0xDAFF: """
; ============================================================================
; SECTION 3 -- Per-device dispatch table ($DAFF-$DB5E)
;
; SIX entries x 16 bytes = 96 bytes (vs 2.23's 4 entries / 64 bytes).
; Each entry: 8 zero/state bytes + 4 pointers.
;
; Entries 0-3 dispatch to STATIC handler code in code page 6 ($E0CC area).
; Entries 4-5 dispatch to addresses in $E5-filled regions (runtime slots
; like 2.23's, but only 2 of 6 slots are runtime in 2.20).
;
; This is where 2.20 differs architecturally from 2.23: it has more
; static handlers + only 2 runtime slots, where 2.23 has 0 static + 4
; runtime. See Part 6 of the article series and the 2.20-dispatch-table
; devlog for the full comparison.
; ============================================================================

""",
    0xDB6E: """
; ============================================================================
; SECTION 4 -- COLD-BOOT GENERATOR ($DB6E-$DB90) - 2.20 version
;
; Same structural shape as 2.23's generator at $FB3A but WITHOUT the
; device-code-6 (Pascal 1.1) branch. This is the byte-level location of
; the missing-Videx-handling on the Z-80 side.
;
; Device codes handled:
;   3 -> CALL $DD60 (vs 2.23's CALL $FE81)
;   4 -> CALL $DCEE (vs 2.23's CALL $FD83 + $C800 setup)
;   (NO branch for 6) <- this is what 2.23 added
; ============================================================================

""",
    0xDBCC: """
; ============================================================================
; SECTION 5 -- $E5-filled page 1 ($DBCC-$DCCB)
;
; 256 bytes of $E5 (CP/M deleted-file marker; also Z-80 PUSH HL opcode).
; State storage and possibly runtime-installed handler slots.
; ============================================================================

""",
    0xDCCC: """
; ============================================================================
; SECTION 6 -- Code page 2 ($DCCC-$DDCB)
;
; Per-device init helpers:
;   $DCEE  device-4 (Pascal 1.0) init
;   $DD60  device-3 init
;   $DD8E  SETDMA jump-table target
;   $DD93  READ jump-table target
;   $DDA3  WRITE jump-table target
; ============================================================================

""",
    0xDDCC: """
; ============================================================================
; SECTION 7 -- $E5-filled page 3 ($DDCC-$DECB)
;
; Filler. The BOOT vector $DEA8 lands HERE in this filler region; real
; code resumes at $DECC. Like 2.23's BOOT vector landing in NOPs.
; ============================================================================

""",
    0xDECC: """
; ============================================================================
; SECTION 8 -- Code page 4 ($DECC-$DFCB)
;
; Cold-boot device-scan loop. Structurally identical to 2.23's at
; $FF0E (same instructions, same encoding) -- the BIOS-side device
; dispatch architecture didn't change between versions.
; ============================================================================

""",
    0xDFCC: """
; ============================================================================
; SECTION 9 -- $E5-filled page 5 ($DFCC-$E0CB)
;
; Filler. State storage for the static handlers in the next page.
; ============================================================================

""",
    0xE0CC: """
; ============================================================================
; SECTION 10 -- STATIC PER-DEVICE HANDLERS ($E0CC-$E1CB)
;
; *** THIS PAGE HAS NO ANALOG IN 2.23 ***
;
; 2.20 ships per-device I/O handler routines as static code here. 2.23
; removed this page entirely and made handlers runtime-installed
; instead.
;
; Routines visible here:
;   - Status-byte readers and writers
;   - Per-device output sequences (CALL $DCEA + JP $DB3B style)
;   - References to expansion-ROM addresses ($C9AA, $C84D) for Pascal
;     1.0 entry points
;   - Slot-base arithmetic (LD A,E; ADD A,A x 4 = E*16 = slot offset)
;   - State management at $DEA4-$DEC8 (the $DDCC-$DECB filler page)
;
; The Videx fix would have required adding a Pascal-1.1-aware handler
; here in 2.20. Microsoft instead removed the entire page in 2.23 and
; built the runtime-generator architecture, into which Pascal 1.1 plugs
; as device code 6 (with ~10 bytes of new generator code at $FB5B).
; ============================================================================

""",
    0xE1CC: """
; ============================================================================
; SECTION 11 -- $E5-filled page 7 ($E1CC-$E2CB)
;
; Final filler page. End of BIOS.
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
; Microsoft SoftCard CP/M 2.20 -- Z-80 BIOS ($DACC-$E2CB, 2 KB)
; Annotated Z-80 assembly source for the 2.20 BIOS region.
;
; STRUCTURE
;   2.20's BIOS uses a 256-byte interleaved layout (same as 2.23) but
;   has 4 code pages + 4 filler pages = 2 KB total.
;
;     Page 0  $DACC-$DBCB  Jump table, dispatch table, generator (CODE)
;     Page 1  $DBCC-$DCCB  $E5 filler
;     Page 2  $DCCC-$DDCB  Per-device init helpers (CODE)
;     Page 3  $DDCC-$DECB  $E5 filler (BOOT vector lands here)
;     Page 4  $DECC-$DFCB  Cold-boot device-scan + helpers (CODE)
;     Page 5  $DFCC-$E0CB  $E5 filler
;     Page 6  $E0CC-$E1CB  STATIC PER-DEVICE HANDLERS (CODE) <- 2.23 lacks this
;     Page 7  $E1CC-$E2CB  $E5 filler
;
;   Filler is $E5 (CP/M deleted-file marker / Z-80 PUSH HL). 2.23 uses
;   FF/F7/00 trap markers instead -- a safety upgrade so premature
;   execution lands in a defined trap rather than thrashing the stack.
;
; KEY DIFFERENCES FROM 2.23
;   - 2 KB total (vs 2.23's 1.35 KB) -- 2.20 is bigger because of the
;     static-handler page.
;   - Page 6 ($E0CC-$E1CB) holds STATIC device handlers. 2.23 generates
;     equivalents at runtime instead.
;   - Cold-boot generator at $DB6E lacks the device-6 (Pascal 1.1)
;     branch that 2.23 added -- the Videx-fix is precisely this absence.
;   - Dispatch table at $DAFF has 6 entries (vs 2.23's 4), with entries
;     0-3 pointing to static handlers and entries 4-5 to runtime slots.
;   - BDOS final position $CC06 (vs 2.23's $9C06 -- 12 KB shift).
; ============================================================================

; ----------------------------------------------------------------------------
; State slots (in $E5-filled pages at runtime)
; ----------------------------------------------------------------------------
state_DEA4      = $DEA4
state_DEA5      = $DEA5
state_DEA7      = $DEA7
state_DEAF      = $DEAF
state_DEB4      = $DEB4
state_DEB1      = $DEB1
state_DEB6      = $DEB6
state_E5B2      = $E5B2

; ----------------------------------------------------------------------------
; TPA-area state (above BDOS at $CC06)
; ----------------------------------------------------------------------------
slot_info_F3B8  = $F3B8       ; slot-info table base
state_F386      = $F386
state_F388      = $F388
state_F397      = $F397

; ----------------------------------------------------------------------------
; CCP+BDOS final positions
; ----------------------------------------------------------------------------
BDOS_ENTRY      = $CC06       ; 2.20: BDOS at $CC06 (vs 2.23 at $9C06)

; ----------------------------------------------------------------------------
; Apple I/O
; ----------------------------------------------------------------------------
APPLE_TEXT_FLAG = $E051

            .ORG $DACC


; ============================================================================
; SECTION 1 -- BIOS Jump Table ($DACC-$DAF8)
;
; Standard CP/M 2.x 15-entry jump table. Targets are in 2.20-specific
; addresses; structure parallels 2.23.
;
;   Offset  Address  Routine     Target
;   0       $DACC    BOOT        $DEA8  (lands in $E5 filler page 3)
;   3       $DACF    WBOOT       $DACC  (-> BOOT)
;   6       $DAD2    CONST       $DB08
;   9       $DAD5    CONIN       $DB12
;   12      $DAD8    CONOUT      $DB43
;   15      $DADB    LIST        $DB66
;   18      $DADE    PUNCH       $DB75
;   21      $DAE1    READER      $DB87
;   24      $DAE4    HOME        $DD4B
;   27      $DAE7    SELDSK      $DD6D
;   30      $DAEA    SETTRK      $DD56
;   33      $DAED    SETSEC      $DD89
;   36      $DAF0    SETDMA      $DD8E
;   39      $DAF3    READ        $DD93
;   42      $DAF6    WRITE       $DDA3
; ============================================================================

JUMP_TABLE:
"""

FOOTER = """

; ============================================================================
; END OF BIOS ($E2CB)
;
; Z-80 reset vector at $0000 was planted by the 6502 as "JP $DA00".
; $DA00 is below this BIOS (in a runtime-generated region 204 bytes
; long, $DA00-$DACB). Cold-boot setup rewrites the reset vector to
; "JP $DA03" for warm-boot use.
;
; The cold-boot setup plants the BDOS call vector at $0005-$0007:
;   $0005: $C3 (JP opcode)
;   $0006-$0007: $CC06 (BDOS entry after relocation)
; ============================================================================
"""

with open('docs/CPM220_BIOS.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM220_BIOS.asm')
print(f'Written: docs/CPM220_BIOS.asm ({size} bytes)')
