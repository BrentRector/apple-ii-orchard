"""Generate CPM220_RWTS.asm — annotated 6502 source for Apple $0A00-$0FFF (2.20)."""
import subprocess

# Disassemble entire 2.20 RWTS region (1.5 KB)
result = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/rwts_220.bin',
     '--base', '0x0A00', '--start', '0x0A00', '--end', '0x0E10'],
    capture_output=True,
)
disasm_text = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm_text.split('\n')]

# Section breakpoints — 2.20 layout differs from 2.23
SECTIONS = {
    0x0A99: """
; ============================================================================
; READ_SECTOR ($0A99) -- read current track/sector
;
; Standard Apple Disk II 6-and-2 GCR pattern. Likely byte-identical
; to 2.23's READ_SECTOR (RWTS routines are stable across versions).
; ============================================================================

""",
    0x0B5F: """
; ============================================================================
; SEEK_TRACK ($0B5F) -- move drive head
; ============================================================================

""",
    0x0BEE: """
; ============================================================================
; LOAD_CPM_LOOP ($0BEE) -- 28-sector load loop
;
; 2.20 reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D). Otherwise
; structurally identical to 2.23's LOAD_CPM_LOOP.
; ============================================================================

""",
    0x0E10: """
; ============================================================================
; LOAD_CPM ($0E10) -- 2.20's LOAD_CPM entry (was at $0BEB-style in 2.23)
;
; 2.20 has its LOAD_CPM-equivalent at a DIFFERENT ADDRESS than 2.23.
; 2.23 puts LOAD_CPM at $0BEB (which becomes $BBEB after PREP_HANDOFF
; copies it to LC RAM). 2.20 has LOAD_CPM at $0E10 (which would become
; $BE10 after PREP_HANDOFF -- but 2.20 also calls $0E10 directly via
; JSR $0E10 from stage-2 at $1608 and $17D0).
;
; The structural shift between 2.20's $0E10 and 2.23's $0BEB is one of
; the boundaries that explains why so many bytes differ between the two
; loaders -- the relocation cascades through the whole file.
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
; Microsoft SoftCard CP/M 2.20 -- RWTS (Apple $0A00-$0FFF)
; Annotated 6502 assembly source for the disk-routine block loaded by
; the boot stub from track 0 sectors 2, 4, 6, 8, A, C (in CP/M skew
; order) into Apple $0A00-$0FFF.
;
; SCOPE
;   Compared to 2.23, 2.20's RWTS region is structured slightly
;   differently. The clean 6502 RWTS code occupies more of the area
;   because 2.20's BIOS first 1 KB sits at Z-80 $DACC (not $FAB8),
;   so the BIOS-content overlap into Apple $0Cxx is less significant
;   than in 2.23. This file covers the 6502 portion through $0E10
;   (where 2.20's LOAD_CPM sits).
;
; KEY DIFFERENCES FROM 2.23
;   - LOAD_CPM at $0E10 (vs 2.23 at $0BEB / $BBEB)
;   - Main load reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D)
;   - JSR $0E10 callers are at stage-2 $1608 and $17D0 (vs 2.23's
;     $1416 and $191E)
;   - 2.20 has no embedded Z-80 fragment in the 6502 loader area
;     (2.23 had ~270 bytes at loader $143A-$1547)
;
; ENCODING (same as 2.23)
;   Standard Apple Disk II 6-and-2 GCR. Address-field prolog: D5 AA 96.
;   Data-field prolog: D5 AA AD. Both epilogs: DE AA EB.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols (same as 2.23)
; ----------------------------------------------------------------------------
DSK_PHASE_OFF   = $C080
DSK_PHASE_ON    = $C081
DSK_MOTOR_OFF   = $C088
DSK_MOTOR_ON    = $C089
DSK_DRIVE_1     = $C08A
DSK_DRIVE_2     = $C08B
DSK_Q6L         = $C08C
DSK_Q6H         = $C08D
DSK_Q7L         = $C08E
DSK_Q7H         = $C08F

PRINT_ERR       = $FF2D

zp_buf_lo       = $26
zp_buf_hi       = $27
zp_track        = $2A
zp_sector       = $2B

SLOT_HEAD_TRK   = $0478

WRITE_BYTE_4US  = $BA8F
WRITE_BYTE_DLY  = $BA90
SEEK_PHASE_ON   = $BBAD
SEEK_PHASE_OFF  = $BBB0
SEEK_PHASE_DLY  = $BBBC

            .ORG $0A00


; ============================================================================
; WRITE_SECTOR ($0A00) -- write 256 bytes at $0C00 to current track/sector
; ============================================================================

WRITE_SECTOR:
"""

FOOTER = """
; ============================================================================
; Beyond $0E10
;
; Apple $0E10 onwards in the 2.20 loader image continues with more 6502
; code (LOAD_CPM body and helpers). Since 2.20's BIOS at Z-80 $DACC
; doesn't overlap into Apple $0Cxx the way 2.23's BIOS at Z-80 $FAB8
; does, more of this region is 6502.
;
; The remainder up to $0FFF is partially 6502 and partially data tables
; for the GCR encode/decode plus state slots that the cooperative-CPU
; loop will use after the SoftCard switch.
; ============================================================================
"""

with open('docs/CPM220_RWTS.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM220_RWTS.asm')
print(f'Written: docs/CPM220_RWTS.asm ({size} bytes)')
