"""Generate CPM220_BootLoader.asm — annotated 6502 source for 2.20 boot stub + stage-2."""
import subprocess

# Disassemble boot stub area
result_stub = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/loader_220.bin',
     '--base', '0x0800', '--start', '0x0800', '--end', '0x0840', '--format', 'asm'],
    capture_output=True,
)
stub_disasm = result_stub.stdout.decode('utf-8', errors='replace')
stub_lines = [l[2:] if l.startswith('  ') else l for l in stub_disasm.split('\n')]

# Disassemble stage-2 loader area
result_s2 = subprocess.run(
    ['python', '-m', 'nibbler', 'disasm', 'cpm-investigation/loader_220.bin',
     '--base', '0x0800', '--start', '0x1000', '--end', '0x1200', '--format', 'asm'],
    capture_output=True,
)
s2_disasm = result_s2.stdout.decode('utf-8', errors='replace')
s2_lines = [l[2:] if l.startswith('  ') else l for l in s2_disasm.split('\n')]

HEADER = """; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- 6502 Boot Loader (integrated source)
; Annotated disassembly of the loader as it exists in Apple ][ RAM
; after the boot stub completes.
;
; The loader occupies $0800-$13FF in Apple ][ RAM. Loaded by the Disk II
; P6 PROM (sector 0 -> $0800) and the boot stub itself (10 more sectors
; of track 0 -> $0A00-$1300, in CP/M sector skew order).
;
; THIS FILE COVERS
;   $0800-$08FF  Boot stub (sector 0; 60 bytes of code, BYTE-IDENTICAL
;                to 2.23; rest is sector skew table and old/new copyright
;                strings)
;   $1000-$11FF  Stage-2 entry, install loops, slot scanner, dispatch,
;                boot-finalization. NOTE: 74% of stage-2 bytes differ
;                from 2.23. Same overall structure but different
;                addresses and code shape.
;
; KEY DIFFERENCES FROM 2.23
;   - Z-80 BIOS at $DACC (vs 2.23's $FAB8); reset vector planted as
;     "JP $DA00" not "JP $FA00"
;   - BDOS final position $CC06 (vs 2.23's $9C06)
;   - LOAD_CPM at Apple $0E10 (vs $0BEB / $BBEB in 2.23)
;   - Main load reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D)
;   - 11-byte Pascal 1.1 detection branch ABSENT (the Videx-fix delta;
;     see CPM_Videx_Difference.md and Part 1 of the article series)
;   - Install copy loops at $1041, $104C, $10E9 (vs $1044, $104F, $10F1)
;   - Warm-boot routine bytes at $13C0+ have STA $C400 + JSR $1010
;     instead of 2.23's STA $FFFF + JSR $0E36 -- different CPU-switch
;     mechanism (slot-4 I/O vs Z-80-byte fetch)
;   - No copyright string at $0860 (zero-filled in 2.20)
;
; COMPANION FILES
;   CPM220_InstallFragments.asm  ORG $0200, runtime view of the bytes
;                                 sourced from $1200-$13FF (different
;                                 from 2.23's install fragments).
;   CPM220_RWTS.asm              ORG $0A00, disk-routine block.
;
; The companion narrative is the cpm-videx article series and
; docs/CPM_Videx_Difference.md.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols (same set as 2.23 since the underlying Apple platform is the same)
; ----------------------------------------------------------------------------
zp_ptr_lo       = $3C        ; 16-bit pointer / slot ROM base
zp_ptr_hi       = $3D
zp_jmp_lo       = $3E        ; indirect-JMP target
zp_jmp_hi       = $3F
zp_count        = $00
zp_p6_count     = $27

dev_count_d2    = $03B8
dev_table       = $03B9
warm_boot       = $03C0

TEXT            = $FB2F
SETVID          = $FE93
SETKBD          = $FE89
COUT            = $FDED
IORTS           = $FF58
SAVE            = $FF4A
RESTORE         = $FF3F
MONITOR         = $FF65

KBD             = $C000
LC_RD_RAM       = $C081
LC_WR_RAM       = $C083
DISK_MOTOR_OFF  = $C088


; ============================================================================
; SECTION 1 -- Boot stub (sector 0, $0800-$08FF)
;
; 60 bytes of code at $0801-$083C. BYTE-IDENTICAL to 2.23's boot stub.
; Loads 10 more sectors of track 0 in CP/M skew order, then JMP $1000.
; ============================================================================

            .ORG $0800

$0800:      .BYTE $01

BOOT_STUB:
"""

FOOTER_STUB = """
; (Sector skew table at $082D-$083C, then old-style copyright string
;  through $085C, then ZERO-FILLED to $08FF. 2.20 lacks the second
;  1982 copyright that 2.23 added at $0860.)


; ============================================================================
; SECTION 2 -- Disk I/O block ($0A00-$0FFF, summary only)
;
; Standard Apple Disk II RWTS routines. Per-instruction disassembly is
; in CPM220_RWTS.asm. Major entry points (analogous to 2.23):
;   $0A00  WRITE_SECTOR
;   $0A99  READ_SECTOR
;   $0B5F  SEEK_TRACK
;   $0BEE  LOAD_CPM_LOOP (28-sector main load)
;   $0E10  LOAD_CPM (entry called from stage-2 $1608, $17D0)
;
; Bytes in $0C39-$0FFF that LOOK like illegal 6502 opcodes are likely
; data tables (GCR encode/decode lookup) plus state slots. Not Z-80
; code -- 2.20's BIOS at $DACC doesn't overlap into Apple $0Cxx the
; way 2.23's BIOS at $FAB8 does.
; ============================================================================


; ============================================================================
; SECTION 3 -- Stage-2 loader ($1000-$11FF)
;
; Entry point reached via JMP $1000 from the boot stub. Sets up Apple
; ][ environment, runs install loops, runs the slot scanner, sets up
; the device-code table, runs LOAD_CPM, then runs boot-finalization
; that sets up the Z-80 reset vector and triggers the SoftCard switch.
; ============================================================================

            .ORG $1000

STAGE2_ENTRY:
"""

FOOTER = """

; ============================================================================
; SECTION 4 -- Page-2 install image source ($1200-$12FF, source-only)
;
; This 256-byte block gets copied to Apple $0200-$02FF by the install
; loop at $1041. The runtime form is in CPM220_InstallFragments.asm.
; The bytes here are the SOURCE; they're meaningless to 6502 disasm at
; $12xx because they execute as 6502 (or are read as data) at $02xx.
; ============================================================================


; ============================================================================
; SECTION 5 -- Page-3 install image source ($1300-$13FF, source-only)
;
; Copied to $0300-$03FF by the install loops at $104C (most of it) and
; $10E9 (last 16 bytes). Includes the warm-boot routine source bytes
; at $13C0-$13DC. Runtime form is in CPM220_InstallFragments.asm.
; ============================================================================
"""


body_stub = '\n'.join(stub_lines)
body_s2 = '\n'.join(s2_lines)

with open('docs/CPM220_BootLoader.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body_stub + FOOTER_STUB + body_s2 + FOOTER)

import os
size = os.path.getsize('docs/CPM220_BootLoader.asm')
print(f'Written: docs/CPM220_BootLoader.asm ({size} bytes)')
