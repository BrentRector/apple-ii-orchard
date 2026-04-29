"""Generate CPM220_SystemImage.asm — Z-80 source for 2.20's CCP + BDOS."""
import subprocess
import os

# 2.20's sysimg is at offset $A300 in staging, ends 5888 bytes later.
# Runtime address: same staging convention. The cold-boot plants $CC06 as
# BDOS entry (vs 2.23's $9C06) -- 12 KB shift. So the BDOS in 2.20 is
# at a higher absolute address than in 2.23.
#
# Note: 2.20's underlying CP/M is 2.0, NOT 2.2. The CCP+BDOS bytes differ
# from 2.23's substantially (98% byte-different per the version-bump devlog).

# Disassemble at $8000 base for parallel comparison with 2.23.
result = subprocess.run(
    ['python', '-m', 'nibbler', 'z80disasm', 'cpm-investigation/sysimg_220.bin',
     '--base', '0x8000', '--start', '0x8000', '--end', '0x96FF'],
    capture_output=True,
)
disasm = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm.split('\n')]

HEADER = """; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- System Image (CCP + BDOS, 5888 bytes)
; Annotated Z-80 assembly source for 2.20's CP/M 2.0 system image.
;
; STRUCTURE
;   Same overall shape as 2.23's sysimg but Digital Research CP/M 2.0
;   underneath instead of 2.2. The two differ in 5807 of 5888 bytes
;   (98.6%) -- mostly because 2.0 -> 2.2 is a substantial BDOS rewrite,
;   plus absolute-address relocation differences.
;
;   $8000-$80C7  CCP entry + initial dispatch
;   $80C7-$80DC  CCP built-in command table ("DIR ERA TYPE SAVE REN USER")
;   $80DD-$..    CCP body
;   $..-$96FF    BDOS body + various scratch (no boot banner; 2.20's
;                sysimg ends in $E5 filler instead)
;
; KEY DIFFERENCES FROM 2.23
;   - Underlying CP/M 2.0 instead of 2.2 -- 98.6% byte-different
;   - No boot banner string (last 64 bytes are $E5 filler)
;   - BDOS final position $CC06 in 2.20 vs $9C06 in 2.23 -- a 12 KB
;     relocation shift between the two builds
;
; PRACTICAL NOTE
;   Per-instruction annotation is left to standard CP/M 2.0 reference
;   disassemblies. The Videx-fix-relevant code is in BIOS (cpm220_BIOS.asm),
;   not here.
; ============================================================================

            .ORG $8000


; ============================================================================
; CCP ENTRY ($8000)
; ============================================================================

CCP_ENTRY:
"""

body = '\n'.join(lines)

FOOTER = """

; ============================================================================
; END OF SYSIMG -- 2.20 has no boot banner; sysimg tail is $E5 filler.
; ============================================================================
"""

with open('docs/CPM220_SystemImage.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)
print(f'Written: docs/CPM220_SystemImage.asm ({os.path.getsize("docs/CPM220_SystemImage.asm")} bytes)')
