; ============================================================================
;  CPM_BootLoader_ConInit.asm -- Z-80 console driver embedded in the 2.20-44K
;  6502 boot loader, extracted to its own sjasmplus source and INCBIN'd back
;  into CPM_BootLoader.s (the CPM_RPC6502 pattern, reversed CPU): the boot
;  image is 6502/ca65, but these 50 bytes are Z-80 code, so they are assembled
;  by the Z-80 assembler and the resulting binary is embedded at the right
;  offset. Stored in the boot image at $134A, copied to Apple $034A at install,
;  and executed by the Z-80 at $F34A (its view of Apple $034A) -- which is the
;  ORG below, so the relative branch resolves.
;
;  Slot-3 serial (type-3) card console primitives; each reads the card's status
;  register ($C0BE, seen as $E0BE by the Z-80) or RPCs the char to the 6502
;  (set A$VEC=A_VEC, trigger via Z$CPU=Z_CPU). Non-type-3 -> BIOS ($AB0C/$AC3E).
;  Reassembles BYTE-IDENTICAL to the original $134A-$137B bytes.
; ============================================================================
    DEVICE NOSLOT64K
    INCLUDE "apple_softcard.inc"   ; Apple/SoftCard external names (single source of truth)

SLOT3IO EQU $E0BE        ; slot-3 device status register (Apple $C0BE)

    ORG $F34A

CON_STATUS:                     ; $F34A  console status
    LD A,(SLTTYP3)              ; slot-3 card type
    CP $03                      ; a type-3 (serial) card?
    JP NZ,$AB0C                 ; no -> BIOS console status
    LD A,(SLOT3IO)              ; serial status register
    RRA                         ; bit0 (char ready) -> carry
    SBC A,A                     ; A = $FF if ready else $00
    RET
CON_INPUT:                      ; $F358  console input
    CALL $AB12                  ; fetch raw key via BIOS
    AND $7F                     ; strip high bit
    RET
CON_OUTPUT:                     ; $F35E  console output (char in C)
    LD A,(SLTTYP3)              ; slot-3 card type
    CP $03                      ; a type-3 (serial) card?
    JP NZ,$AC3E                 ; no -> BIOS console output
OUT_WAIT:                       ; $F366
    LD A,(SLOT3IO)              ; serial status register
    AND $02                     ; Tx-ready bit set?
    JR Z,OUT_WAIT               ; spin until ready
    LD A,C                      ; char to send
    LD (RPC_ACC),A                ; hand it to the 6502 (A-reg cell)
    LD HL,$037C                 ; 6502 sub: STA $C0BF ; RTS
    LD (A_VEC),HL               ; A$VEC := $037C
    LD HL,(Z_CPU)               ; HL := $En00
    LD (HL),A                   ; touch $En00 -> RPC runs the 6502
    RET

    SAVEBIN "{out_bin}", $F34A, $32     ; 50 bytes, $F34A..$F37B
