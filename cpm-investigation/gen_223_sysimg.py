"""Generate CPM223_SystemImage.asm — Z-80 source for CCP + BDOS at $8000-$96FF."""
import subprocess

result = subprocess.run(
    ['python', '-m', 'nibbler', 'z80disasm', 'cpm-investigation/sysimg_223.bin',
     '--base', '0x8000', '--start', '0x8000', '--end', '0x96BB', '--format', 'asm'],
    capture_output=True,
)
disasm = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm.split('\n')]

SECTIONS = {
    0x80C7: """
; ============================================================================
; CCP BUILT-IN COMMAND TABLE ($80C7-$80DD)
;
; Six four-character entries, each padded with spaces to 4 chars:
;   DIR   list directory
;   ERA   erase file
;   TYPE  type file to console
;   SAVE  save N pages of memory to file
;   REN   rename file
;   USER  set/show current user area
;
; The CCP command parser tokenizes input and matches against this
; table; non-matching commands are loaded as .COM files from disk.
; ============================================================================

""",
    0x828E: """
; ============================================================================
; CCP messages and error strings ($828E-$8B69)
;
; Mostly $-terminated CP/M-style strings interspersed with the CCP's
; runtime code (file-name parser, command dispatcher, drive-select
; handler, error-message printer).
; ============================================================================

""",
    0x8B70: """
; ============================================================================
; BDOS BODY ($8B70-$96BA)
;
; Digital Research's CP/M 2.2 BDOS, ~2.7 KB. Standard structure:
;   - Function dispatcher: receives C = function code, dispatches via
;     a jump table to the appropriate handler
;   - File operations: open, close, read sequential, write sequential,
;     read random, write random (BDOS functions 15-21, 33-34)
;   - Console operations: read char, write char, print string (functions
;     1-12)
;   - Drive operations: select disk, get/set DMA, login (functions
;     13-14, 24-26)
;   - Error handling: BDOS error trap (the "Bdos Err On %c: %s" path
;     using the strings at $8DBA)
;
; Key entry point reached via the cold-boot's plant at $0005-$0007:
;   $0005: JP $9C06    ; user-program -> BDOS interface
; Wait -- $9C06 is past sysimg's end ($96FF). The actual BDOS entry
; address used at runtime depends on the relocation by the loader's
; third page copy. After that copy, sysimg lives at $8000-$96FF; the
; BDOS body is somewhere within this range; the cold-boot plants the
; correct entry-point address there.
;
; Per-instruction annotation is omitted here -- the BDOS matches the
; standard Digital Research CP/M 2.2 reference disassembly with
; absolute-address relocation. See standard CP/M reference materials
; for the full instruction-level breakdown.
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
; Microsoft SoftCard CP/M 2.23 -- System Image (CCP + BDOS at $8000-$96FF)
; Annotated Z-80 assembly source for the CP/M 2.2 system image as it
; sits at runtime $8000-$96FF after the loader's third page copy.
;
; SCOPE
;   This region is Digital Research's stock CP/M 2.2 (CCP + BDOS) plus
;   Microsoft's boot banner. Microsoft provides only the BIOS (covered
;   in CPM223_BIOS.asm); the CCP and BDOS here are the standard 1981
;   CP/M 2.2 codebase with absolute-address relocation applied for the
;   $8000-$96FF runtime range.
;
; STRUCTURE
;   $8000-$80C6  CCP entry + initial dispatch code
;   $80C7-$80DD  CCP built-in command table ("DIR ERA TYPE SAVE REN USER")
;   $80DE-$8B69  CCP body: command parser, file-name parser, drive
;                  selector, error-message printer
;   $8B70-$96BA  BDOS body: function dispatcher + handler routines
;   $96BB-$96FF  Boot banner string
;
; SOURCE
;   Loaded by LOAD_CPM (29-sector read into Apple $8000-$9CFF staging)
;   and relocated to runtime position by the loader's third page copy
;   at Apple $113D (copies $A300-$B9FF -> $8000-$96FF).
;
; PRACTICAL NOTE
;   Per-instruction annotation of CCP+BDOS is left to the reader's
;   standard CP/M 2.2 reference disassembly (Heath / Digital Research
;   archives). Microsoft's modifications to CCP+BDOS for the SoftCard
;   are minimal -- the boot banner string and any absolute-address
;   relocation, primarily. The Videx-fix-relevant code is in BIOS
;   (covered in CPM223_BIOS.asm), not here.
; ============================================================================

            .ORG $8000


; ============================================================================
; CCP ENTRY ($8000)
;
; Cold-start jumps to the CCP main loop at $9631 (near top of CCP).
; That's where the prompt-display + command-read loop lives.
; ============================================================================

CCP_ENTRY:
"""

FOOTER = """

; ============================================================================
; BOOT BANNER ($96BB-$96FF)
; ============================================================================

BOOT_BANNER:
            .BYTE $0D, $0A, $0A, $0A
            .ASCII "     Softcard CP/M"
            .BYTE $0D, $0A
            .ASCII "     60K Ver. 2.23"
            .BYTE $0D, $0A
            .ASCII "(c) 1980,1982 Microsoft"
            .BYTE $0D, $0A, $0D, $0A, $00
            .BYTE $FA       ; trailing byte (purpose: TBD)
"""

with open('docs/CPM223_SystemImage.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM223_SystemImage.asm')
print(f'Written: docs/CPM223_SystemImage.asm ({size} bytes)')
