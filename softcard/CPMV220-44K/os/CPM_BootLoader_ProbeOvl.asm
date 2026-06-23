; ============================================================================
;  CPM_BootLoader_ProbeOvl.asm -- the SoftCard slot-probe handshake, the Z-80
;  block the boot loader installs over $1000..$100C during the slot scan. Z-80
;  code embedded in the 6502 boot image, so it is assembled here by the Z-80
;  assembler and INCBIN'd back into CPM_BootLoader.s (the CPM_RPC6502 pattern,
;  reversed CPU). Stored in the boot image at $1169, copied to $1000..$100C, and
;  executed by the Z-80 there (the SoftCard maps the Z-80 reset address $0000 to
;  Apple $1000), so a slot-probe write (SCAN_PROBE) lands the Z-80 here: it clears
;  the $3E "SoftCard found" flag and bounces straight back to the 6502.
;
;  Note the JR: it is a real instruction, but only its opcode ($18) lives in this
;  block -- SAVEBIN stops at 13 bytes, so the JR's offset byte is supplied by the
;  FOLLOWING host byte, SIG_BYTE5[0] = $F2 (a signature-table byte the handshake
;  deliberately reuses; $F2 = -14, i.e. JR back to $1000). Reassembles
;  BYTE-IDENTICAL to the original $1169-$1175 bytes.
; ============================================================================
    DEVICE NOSLOT64K

FOUND   EQU $F03E        ; the 6502's $3E "SoftCard found" flag (Z-80 view of $003E)
PROBED  EQU $F03D        ; the probed slot's $Cn high byte, set by the 6502 ($003D)

    ORG $1000

; ----------------------------------------------------------------------------
; PROBE_OVL -- slot-probe handshake. Installed over $1000..$100C; during the slot
;   scan a probe write lands the Z-80 here. Clear the $3E "SoftCard found" flag,
;   then touch the probed slot's Z-80 I/O page ($En00 = $Cn + $20) to switch back
;   to the 6502, and loop (the JR offset byte is the host's SIG_BYTE5[0]).
;   In: $3D = probed slot $Cn (set by the 6502).  Clobbers: A, HL.
; ----------------------------------------------------------------------------
PROBE_OVL:
    XOR A                ; A = 0
    LD (FOUND),A         ; $3E = 0 -> "SoftCard found in the probed slot"
    LD L,A               ; HL low = 0
    LD A,(PROBED)        ; A = probed slot $Cn
    ADD A,$20            ; $Cn -> $En (the slot's Z-80 I/O page)
    LD H,A               ; HL = $En00
    LD (HL),A            ; touch $En00 -> Apple $Cn00 -> switch back to the 6502
    JR PROBE_OVL         ; loop ($18; offset byte $F2 supplied by host SIG_BYTE5[0])

    SAVEBIN "{out_bin}", $1000, 13       ; 13 bytes (JR opcode included, its operand byte is not)
