"""Generate CPM223_DiskCallbacks.asm — Z-80 source for $1A00-$1BFF callbacks."""
import subprocess

result = subprocess.run(
    ['python', '-m', 'nibbler', 'z80disasm', 'cpm-investigation/diskcallbacks_223.bin',
     '--base', '0x1A00', '--start', '0x1A00', '--end', '0x1BFF', '--format', 'asm'],
    capture_output=True,
)
disasm = result.stdout.decode('utf-8', errors='replace')
lines = [l[2:] if l.startswith('  ') else l for l in disasm.split('\n')]

HEADER = """; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- Z-80 Disk Callbacks ($1A00-$1BFF)
; Annotated Z-80 assembly source for the disk-callback area Z-80 sees
; in TPA-area memory (under SoftCard's bit-12 XOR mapping).
;
; LOCATION
;   Apple-side: $0A00-$0BFF (after PREP_HANDOFF). Sourced from the last
;   6 pages of LOAD_CPM staging at Apple $9700-$98FF.
;   Z-80-side: $1A00-$1BFF (via bit-12 XOR for low addresses).
;
;   NOTE: The bytes here are SEPARATE from the BIOS at $FAB8 -- two
;   different physical memory regions. The BIOS is in LC RAM (or
;   SoftCard high-RAM); these callbacks are in Apple main RAM.
;
; PURPOSE
;   These are the BDOS-side and disk-I/O thunks the Z-80 calls when
;   CP/M needs to dispatch through the cooperative-CPU model. The
;   callbacks set up parameters in BIOS state slots and then trigger
;   the CPU switch via the inter-CPU sync polling at $1E39.
;
;   The polling loop at $1E39-$1E44 itself is NOT in this file -- it
;   lives in the BIOS first 1 KB content at $1C00-$1FFF (which is the
;   same bytes as BIOS $FAB8-$FEB7 dual-mapped). See CPM223_BIOS.asm
;   for the polling loop annotation.
;
; STRUCTURE
;   $1A00-$1A2F  Small BDOS-style thunks (mostly 3-byte JP entries
;                into $9F/$A1/$A9 BDOS area)
;   $1A30-$1A52  More thunks
;   $1A53-$1AAF  State-manipulation routines + disk-callback bodies
;   $1AB0-$1BFF  Mostly zero-filled / runtime-mutable state
; ============================================================================

; ----------------------------------------------------------------------------
; BDOS-area addresses (after CCP+BDOS relocation to $9C06+)
; ----------------------------------------------------------------------------
BDOS_9F01       = $9F01       ; BDOS internal entry
BDOS_9F41       = $9F41       ; BDOS state byte
BDOS_9F42       = $9F42       ; BDOS state byte
BDOS_9F43       = $9F43       ; BDOS state byte
BDOS_9F45       = $9F45       ; BDOS state pointer

BDOS_A301       = $A301       ; BDOS function dispatch
BDOS_A43B       = $A43B
BDOS_A793       = $A793
BDOS_A79C       = $A79C
BDOS_A7D2       = $A7D2
BDOS_A851       = $A851
BDOS_A929       = $A929       ; common BDOS entry
BDOS_A9AD       = $A9AD       ; (state byte address)
BDOS_A9AF       = $A9AF
BDOS_A9B1       = $A9B1
BDOS_A9BB       = $A9BB
BDOS_A9BF       = $A9BF
BDOS_A9D6       = $A9D6
BDOS_A93B       = $A93B

BDOS_A1DA       = $A1DA

; ----------------------------------------------------------------------------
; BIOS state (in trap-marker pages within $FAB8-$FFFF, dual-mapped at
; $1Cxx-$1FFF here)
; ----------------------------------------------------------------------------
state_FECB      = $FECB
state_FED2      = $FED2
state_FED4      = $FED4

            .ORG $1A00


; ============================================================================
; SECTION 1 -- BDOS dispatch thunks ($1A00-$1A40)
;
; Small entry points that do parameter setup and JP into the BDOS
; proper. Some are 4-byte (single-byte op + 3-byte JP); others have
; a small prologue. Indexed/used by CCP and other BDOS-callers.
; ============================================================================

CALLBACKS_START:
"""

FOOTER = """

; ============================================================================
; The bytes from approximately $1AAB-$1BFF in newdisk_223 are mostly
; zero-filled and trap-marker patterns, similar to the BIOS layout.
; They serve as state-storage and runtime-installed-handler slots.
; ============================================================================
"""

body = '\n'.join(lines)
with open('docs/CPM223_DiskCallbacks.asm', 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + body + FOOTER)

import os
size = os.path.getsize('docs/CPM223_DiskCallbacks.asm')
print(f'Written: docs/CPM223_DiskCallbacks.asm ({size} bytes)')
