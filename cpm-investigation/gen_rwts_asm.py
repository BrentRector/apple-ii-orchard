"""Generate CPM223_RWTS.asm -- the annotated 6502 source for Apple $0A00-$0FFF.

The boot stub loads $0A00-$0FFF (6 sectors of track 0 in CP/M skew order).
That region contains an interleaved mix of 6502 RWTS code, Z-80 BIOS-first-1KB
code, and GCR codec data tables:

  $0A00-$0C38   6502 code  (WRITE_SECTOR / READ_SECTOR / SEEK / LOAD_CPM_LOOP)
  $0C39-$0CFF   Z-80 code  (BIOS init at Z-80 $1C39-$1CFF; not disassembled here)
  $0D00-$0DFF   data       (GCR decode table @ $0D04, encode table @ $0D5A)
  $0E00-$0FEA   6502 code  (LOAD_CPM_PRIM, retry/seek/track-state helpers,
                            CP/M-skew table, GCR split/merge buffer routines)
  $0FEB-$0FFF   zero pad

After PREP_HANDOFF #1 copies the whole region to $BA00-$BFFF, the 6502
references become $BA00-$BFEA. The Z-80 sees the same physical bytes
mirrored at $1A00-$1FFF (bit-12 XOR), but only uses the Z-80 code at
$1C39-$1CFF; the rest is 6502-only territory.
"""
import subprocess
import sys

# 6502 code section 1: $0A00-$0C38
result1 = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/rwts_223.bin',
     '--base', '0x0A00', '--start', '0x0A00', '--end', '0x0C39', '--format', 'asm'],
    capture_output=True,
)
text1 = result1.stdout.decode('utf-8', errors='replace')

# 6502 code section 2: $0E04-$0FEB
result2 = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/rwts_223.bin',
     '--base', '0x0A00', '--start', '0x0E04', '--end', '0x0FEB', '--format', 'asm'],
    capture_output=True,
)
text2 = result2.stdout.decode('utf-8', errors='replace')

disasm_text = text1
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

import re
ADDR_RE = re.compile(r';\s+\$([0-9A-Fa-f]{4})\s')


def extract_addr(line):
    m = ADDR_RE.search(line)
    if m:
        try:
            return int(m.group(1), 16)
        except ValueError:
            return None
    return None


body_parts = []
for line in lines:
    addr = extract_addr(line)
    if addr is not None and addr in SECTIONS:
        body_parts.append(SECTIONS[addr])
    body_parts.append(line)
body = '\n'.join(body_parts)

HEADER = """; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- 6502 RWTS (Apple $0A00-$0FFF)
; Annotated 6502 assembly source for the disk-routine block loaded by
; the boot stub from track 0 sectors 2, 4, 6, 8, A, C (in CP/M skew
; order) into Apple $0A00-$0FFF.
;
; SCOPE
;   This file documents the 6502 portions of the loaded region:
;     $0A00-$0A98  WRITE_SECTOR     write 256 bytes at $0C00 to disk
;     $0A99-$0B02  READ_DATA_FIELD  decode D5 AA AD ... DE AA EB sequence
;     $0B03-$0B5E  READ_ADDR_FIELD  decode D5 AA 96 4-and-4 vol/trk/sec/ck
;     $0B5F-$0BBB  SEEK_TRACK       step head to requested track
;     $0BBC-$0BD0  STEP_DELAY       16-bit timer for phase delays
;     $0BD1-$0BE8  SEEK_DELAY_TBL   12-entry phase-on/off delay tables
;     $0BEE-$0C38  LOAD_CPM_LOOP    29-sector load orchestrator
;     [GAP $0C39-$0CFF: Z-80 BIOS first-1KB code -- see CPM223_BIOS.asm]
;     [GAP $0D00-$0DFF: GCR codec data tables ($BD04 decode, $BD5A encode)]
;     $0E04-$0E10  LOAD_CPM_PRIM_OUTER  phase-1-on wrapper
;     $0E11-$0EBF  LOAD_CPM_PRIM    sector-read primitive (called as $BE11)
;     $0EC0-$0F49  SECTOR_RW_RETRY  retry/error-recovery body
;     $0F4A-$0F52  WRITE_SECTOR_CALL  write-mode wrapper
;     $0F53-$0F5A  SEEK_RECAL       recalibration helper
;     $0F5B-$0F84  TRACK_STATE_SET  swap track between drive 1 and 2 slots
;     $0F85-$0F9D  TRACK_STATE_GET  read saved track for active drive
;     $0F9E-$0FAD  CPM_SKEW_TABLE   16-byte CP/M sector-skew table
;     $0FAE-$0FD2  SPLIT_BUFFER     pre-write 256 -> 86+256 6+2 GCR split
;     $0FD3-$0FEA  MERGE_BUFFER     post-read 86+256 -> 256 6+2 GCR merge
;     $0FEB-$0FFF  zero-padded
;
;   PREP_HANDOFF (in CPM223_BootLoader.asm at Apple $1109-$113F) copies
;   $0A00-$0FFF to $BA00-$BFFF before the SoftCard switch, preserving
;   the RWTS in LC RAM where the cooperative-CPU loop reaches it. So the
;   absolute addresses in this code (e.g., JSR $BA90, JSR $BA8F, JSR
;   $BB03, JSR $BE11) refer to where each routine WILL BE after the
;   PREP_HANDOFF copy: $0A00 -> $BA00, $0B5F -> $BB5F, $0E11 -> $BE11,
;   $0FAE -> $BFAE, etc.
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

GAP_COMMENTS = """
; ============================================================================
; GAP: $0C39-$0CFF -- Z-80 BIOS init code
;
; The bytes at $0C39-$0CFF are Z-80 code, part of the BIOS first 1 KB
; that the boot stub loaded into $0A00-$0FFF as a single block. The
; Z-80 sees them at $1C39-$1CFF after the SoftCard's bit-12 XOR.
;
; They are not 6502 instructions and are intentionally skipped here.
; See CPM223_BIOS.asm for the Z-80-side annotations.
; ============================================================================

; ============================================================================
; GAP: $0D00-$0DFF -- GCR codec data tables
;
; Standard Apple Disk II 6-and-2 GCR translation tables, used by the
; 6502 RWTS in the runtime layout (after PREP_HANDOFF #1 copies them to
; $BD00-$BDFF in LC RAM). The 6502 code reaches them via the symbols:
;
;   $BD04 = 256-entry decode table (8-bit nibble -> 6-bit value;
;           invalid entries marked with $FE). Referenced by
;           READ_DATA_FIELD at $0AC8 (`EOR $BD04,Y`) and $0AD9.
;
;   $BD5A = 64-entry encode table (6-bit value -> 8-bit GCR nibble:
;           96 97 9A 9B ... FE FF). Referenced by WRITE_SECTOR at
;           $0A43 (`LDA $BD5A,X`).
;
; The exact byte layout is in the binary file; treat this as opaque
; data for the purposes of the source listing.
; ============================================================================

"""

# Append the second 6502 code block ($0E04-$0FEA) plus tail commentary.
SECTIONS_2 = {
    0x0E11: """
; ============================================================================
; LOAD_CPM_PRIM ($0E11) -- the actual sector-read primitive
;
; Called as $BE11 from LOAD_CPM_LOOP (and from LOAD_CPM_PRIM_OUTER above).
; Drives the Disk II hardware: motor on, track selection, drive 1 vs 2
; switching, retry counting, calls to READ_ADDR_FIELD ($BB03) and
; READ_DATA_FIELD ($BA99) for the actual bytes-on-the-wire work.
;
; Drive-state convention:
;   $03E4 / $03E5    desired vs current drive number
;   $05F8 / $06F8    current X (slot*16) per drive selection
;   $03E2 / $03E3    desired vs current track shadow
;
; The lower-level helpers SEEK_TRACK ($BB5F) and STEP_DELAY ($BBBC)
; live in the first 6502 block above; LOAD_CPM_PRIM uses them via the
; absolute references $BB03, $BA99, $BBBC, $BB5F, etc.
; ============================================================================

""",
    0x0EC0: """
; ----------------------------------------------------------------------------
; SECTOR_RW_RETRY ($0EC0) -- retry loop body
;
; On entry: Y = retry counter ($30 = 48 attempts). Loops calling
; READ_ADDR_FIELD; if still failing after 48 attempts, runs error
; recovery (track-state save, recalibration via JSR $BF85, attempt
; second-drive fallback, finally JMP $BEC0 to retry).
; ----------------------------------------------------------------------------

""",
    0x0F4A: """
; ----------------------------------------------------------------------------
; WRITE_SECTOR_CALL ($0F4A) -- write-mode wrapper
;
; Calls WRITE_SECTOR at $BA00 (in LC RAM after PREP_HANDOFF), branches
; to success/failure paths via the carry flag.
; ----------------------------------------------------------------------------

""",
    0x0F53: """
; ----------------------------------------------------------------------------
; SEEK_RECAL ($0F53) -- recalibration helper (BF53 in LC RAM)
;
; Doubles the track number (ASL = track*2 for half-track addressing),
; calls SEEK_TRACK ($BF5B), and updates the per-slot screen-hole
; track at $0478. Used during error recovery to reset head position.
; ----------------------------------------------------------------------------

""",
    0x0F5B: """
; ----------------------------------------------------------------------------
; TRACK_STATE_SET ($0F5B = $BF5B in LC RAM) -- save / restore track
;
; Reads bit 7 of $35 to decide whether the current track lives in
; $0478,Y (drive 1) or $04F8,Y (drive 2). Swaps them and JMPs to
; SEEK_TRACK ($BB5F). Y is computed from X via TRACK_STATE_GET below
; (X = slot*16, Y = X / 16 = slot number).
; ----------------------------------------------------------------------------

""",
    0x0F7E: """
; ----------------------------------------------------------------------------
; SLOT_TO_INDEX ($0F7E = $BF7E in LC RAM)
;
; Helper: convert X (slot*16) to Y (slot) by 4-bit right shift.
; ----------------------------------------------------------------------------

""",
    0x0F85: """
; ----------------------------------------------------------------------------
; TRACK_STATE_GET ($0F85 = $BF85 in LC RAM)
;
; Mirror of TRACK_STATE_SET: reads $03E4 (drive number) into bit 7 of
; $35, then stores A in $0478,Y or $04F8,Y depending on which drive
; is active.
; ----------------------------------------------------------------------------

""",
    0x0F9E: """
; ----------------------------------------------------------------------------
; CPM_SKEW_TABLE ($0F9E = $BF9E in LC RAM) -- 16-byte CP/M sector skew
;
; The CP/M physical-sector skew used by the boot stub and by the
; cooperative-CPU disk callback layer. Logical-sector index N maps to
; physical sector CPM_SKEW_TABLE[N]:
;
;   $00 $02 $04 $06 $08 $0A $0C $0E $01 $03 $05 $07 $09 $0B $0D $0F
;
; This is not the same as DOS 3.3 interleave -- CP/M reads even
; sectors first, then odd sectors (a 2:1 step, lock-step skew).
; Referenced by SECTOR_RW_RETRY at $0F27 (`LDA $BF9E,Y`).
; ----------------------------------------------------------------------------

""",
    0x0FAE: """
; ----------------------------------------------------------------------------
; SPLIT_BUFFER ($0FAE = $BFAE in LC RAM) -- pre-write 8-bit -> 6+2 split
;
; Takes the 256 8-bit data bytes pointed to by ($3E/$3F) and splits
; each into a 6-bit primary (stored at $0C00,X) and a 2-bit secondary
; (packed 3-per-byte at $0900,Y). Output is the GCR-pre-encode form
; that WRITE_SECTOR consumes via the encode table at $BD5A.
;
; Called once per sector before WRITE_SECTOR.
; Two entry points (the BIT-trick at $0FBB):
;   $0FB9: LDX #$AC -- one initial offset
;   $0FBC: LDX #$AA -- alternate initial offset
; Both fall through to the loop body at $0FBE.
; ----------------------------------------------------------------------------

""",
    0x0FD3: """
; ----------------------------------------------------------------------------
; MERGE_BUFFER ($0FD3 = $BFD3 in LC RAM) -- post-read 6+2 -> 8-bit merge
;
; Inverse of SPLIT_BUFFER. Takes the 6-bit primary at $0C00,X and the
; 2-bit secondary at $0900,Y (both populated by READ_DATA_FIELD via
; the decode table at $BD04) and reconstructs 256 8-bit bytes at
; ($3E/$3F).
;
; Called once per sector after a successful READ_DATA_FIELD.
; ----------------------------------------------------------------------------

""",
}

lines2 = [l[2:] if l.startswith('  ') else l for l in text2.split('\n')]
body2_parts = []
for line in lines2:
    addr = extract_addr(line)
    if addr is not None and addr in SECTIONS_2:
        body2_parts.append(SECTIONS_2[addr])
    body2_parts.append(line)
body2 = '\n'.join(body2_parts)

SECTION2_HEADER = """
; ============================================================================
; LOAD_CPM_PRIM_OUTER ($0E04) -- thin wrapper that asserts phase 1 around
; the sector-read primitive
;
; The original 6502 disk routines region resumes here. The boot stub
; loaded sectors $08, $0A, $0C of track 0 into pages $0D00, $0E00,
; $0F00, holding the GCR codec tables (page $0D00) and a second block
; of 6502 RWTS code (pages $0E00 and $0F00). Together with the first
; block at $0A00-$0C38, the LC-RAM-resident RWTS at $BA00-$BFFF that
; the cooperative-CPU disk callbacks reach into is fully populated.
; ============================================================================

"""

FOOTER = """
; ============================================================================
; END OF 6502 RWTS REGION ($0FEB-$0FFF zero-padded)
;
; The trailing bytes at $0FEB-$0FFF are zeros on disk -- pad to the
; sector boundary. After PREP_HANDOFF #1 they're at $BFEB-$BFFF, which
; is the unused tail of the LC-RAM RWTS area.
; ============================================================================
"""

with open('docs/CPM223_RWTS.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + GAP_COMMENTS + SECTION2_HEADER + body2 + FOOTER)

import os
size = os.path.getsize('docs/CPM223_RWTS.asm')
print(f'Written: docs/CPM223_RWTS.asm ({size} bytes)')
