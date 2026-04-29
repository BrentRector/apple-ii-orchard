"""Generate CPM223_RWTS.asm — the annotated 6502 source for Apple $0A00-$0C38."""
import subprocess
import sys

result = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/rwts_223.bin',
     '--base', '0x0A00', '--start', '0x0A00', '--end', '0x0C39'],
    capture_output=True,
)
disasm_text = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm_text.split('\n')]

# Section breakpoints
SECTIONS = {
    0x0A99: """
; ============================================================================
; READ_SECTOR ($0A99) -- read current track/sector to $0900-$0AFF + $0C00-$0CFF
;
; Loops looking for the address-field prolog D5 AA 96, decodes the
; 4-and-4 encoded volume/track/sector/checksum, then reads the data
; field at D5 AA AD prolog. Decodes 342 GCR nibbles into 256 data bytes
; plus an 86-byte secondary buffer at $0900,Y. Validates DE AA epilog.
; Returns carry clear on success / set on failure.
; ============================================================================

""",
    0x0B5F: """
; ============================================================================
; SEEK_TRACK ($0B5F) -- move drive head to requested track
;
; Standard four-phase stepper sequence. Reads current head position from
; $0478,Y (Apple monitor screen-hole convention), compares with desired
; track in A, computes step direction and count, energizes phase coils
; via SEEK_PHASE_ON / SEEK_PHASE_OFF in LC RAM, with per-step delays.
; ============================================================================

""",
    0x0BEE: """
; ============================================================================
; LOAD_CPM_LOOP ($0BEE) -- read N sectors from disk into staging
;
; Called by stage-2 loader (at Apple $1407 with A=$1D for 29 sectors).
; Initializes destination state at $03E0-$03EB, then loops:
;   - call LOAD_CPM_PRIM ($BE11 in LC RAM) to read one sector
;   - on error: call PRINT_ERR + jump to retry
;   - on success: advance sector counter, wrap at 16, advance track
;   - decrement remaining count, loop until done
;
; State conventions:
;   $03E0  current track number
;   $03E1  current sector (0..15)
;   $03E6  destination high byte ($60 = page $60xx)
;   $03E8  scratch
;   $03E9  sectors-loaded counter
;   $03EB  scratch
;
; The actual sector-read happens in LC RAM at $BE11; this routine is
; the orchestration layer. The second LOAD_CPM call from boot-finalization
; ($111E) re-enters here with different starting state to load additional
; sectors past the main 29.
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
; Microsoft SoftCard CP/M 2.23 -- RWTS (Apple $0A00-$0C38)
; Annotated 6502 assembly source for the disk-routine block loaded by
; the boot stub from track 0 sectors 2, 4, 6, 8, A, C (in CP/M skew
; order) into Apple $0A00-$0FFF.
;
; SCOPE
;   This file covers the clean 6502 RWTS code at $0A00-$0C38:
;     $0A00-$0A98  WRITE_SECTOR    write 256 bytes at $0C00 to disk
;     $0A99-$0B5E  READ_SECTOR     read 256 bytes from disk into $0900,$0C00
;     $0B5F-$0BED  SEEK_TRACK      step drive head to requested track
;     $0BEE-$0C38  LOAD_CPM_LOOP   29-sector load loop (calls $BE11 in LC RAM)
;
;   The bytes at $0C39-$0FFF in the loader image are NOT 6502 code. They
;   are part of the BIOS first 1 KB content the boot stub loaded; the
;   Z-80 sees them at $1C39-$1FFF after the SoftCard's bit-12 XOR mapping.
;   They will be covered in CPM223_BIOS.asm.
;
;   PREP_HANDOFF (in CPM223_BootLoader.asm at Apple $1109-$113F) copies
;   $0A00-$0FFF to $BA00-$BFFF before the SoftCard switch, preserving
;   the RWTS in LC RAM where the cooperative-CPU loop reaches it. So the
;   absolute addresses in this code (e.g., JSR $BA90, JSR $BA8F) refer
;   to where each routine WILL BE after PREP_HANDOFF copies them.
;
; CALLING CONVENTION (Apple Disk II standard)
;   X register = slot number * 16 (e.g., $60 for slot 6)
;   $26/$27    = pointer to current sector buffer / track number
;   $0478,Y    = current head track for slot Y (Apple monitor screen-hole
;                convention; $0478+$Cn for slot $Cn)
;   $03B8-$03EB = scratch state for sector counter, track number, etc.
;
; ENCODING
;   Standard Apple Disk II 6-and-2 GCR. Address-field prolog: D5 AA 96.
;   Data-field prolog: D5 AA AD. Both epilogs: DE AA EB.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols
; ----------------------------------------------------------------------------
; Apple Disk II soft switches (X-indexed by slot*16)
DSK_PHASE_OFF   = $C080       ; Disk II phase off (bit 0)
DSK_PHASE_ON    = $C081       ; Disk II phase on (bit 0)
                              ; Phases 0..3 at $C080, $C082, $C084, $C086
                              ; (off) and $C081, $C083, $C085, $C087 (on)
DSK_MOTOR_OFF   = $C088       ; Disk II motor off
DSK_MOTOR_ON    = $C089       ; Disk II motor on
DSK_DRIVE_1     = $C08A       ; select drive 1
DSK_DRIVE_2     = $C08B       ; select drive 2
DSK_Q6L         = $C08C       ; sequencer Q6 low (read latch)
DSK_Q6H         = $C08D       ; sequencer Q6 high (write enable)
DSK_Q7L         = $C08E       ; sequencer Q7 low (read mode)
DSK_Q7H         = $C08F       ; sequencer Q7 high (write mode)

; Apple monitor entry points
PRINT_ERR       = $FF2D       ; print "ERR" + bell

; Zero-page conventions
zp_buf_lo       = $26         ; sector buffer low / scratch
zp_buf_hi       = $27         ; sector buffer high / scratch
zp_track        = $2A         ; current track
zp_sector       = $2B         ; current sector

; Apple monitor screen-hole conventions
SLOT_HEAD_TRK   = $0478       ; per-slot current head track ($0478+$Cn)

; LC-RAM-resident routines (called by RWTS for sub-helpers)
WRITE_BYTE_4US  = $BA8F       ; write 1 nibble (4 us cycle)
WRITE_BYTE_DLY  = $BA90       ; write 1 nibble with extra delay
SEEK_PHASE_ON   = $BBAD       ; phase-on helper (X = phase * 2)
SEEK_PHASE_OFF  = $BBB0
SEEK_PHASE_DLY  = $BBBC       ; per-phase delay
SEEK_DELAY_TBL  = $BBD1       ; phase-on delay table indexed by half-track delta
SEEK_DELAY_TBL2 = $BBDD       ; phase-off delay table
LOAD_CPM_PRIM   = $BE11       ; sector-read primitive in LC RAM
LOAD_CPM_RETRY  = $BBE9       ; retry/error landing pad in LC RAM

            .ORG $0A00


; ============================================================================
; WRITE_SECTOR ($0A00) -- write 256 bytes at $0C00 to current track/sector
;
; Writes the standard Apple Disk II 6-and-2 GCR sequence:
;   address prolog D5 AA AD,
;   342 GCR-encoded data nibbles + checksum nibble,
;   epilog DE AA EB.
;
; Helper at $0A8E-$0A98 (WRITE_BYTE) sends one nibble out via Q6H/Q6L.
; Bails to $0A8A on write-protect detection.
; ============================================================================

WRITE_SECTOR:
"""

FOOTER = """
; ============================================================================
; END OF CLEAN 6502 SECTION
;
; Bytes at $0C39-$0FFF are part of the BIOS first 1 KB; they're Z-80
; code, not 6502. See CPM223_BIOS.asm for the Z-80-side annotations
; (this region maps to Z-80 $1C39-$1FFF under the SoftCard's bit-12
; XOR for low addresses).
; ============================================================================
"""

with open('docs/CPM223_RWTS.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM223_RWTS.asm')
print(f'Written: docs/CPM223_RWTS.asm ({size} bytes)')
