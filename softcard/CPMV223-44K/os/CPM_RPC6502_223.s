; ============================================================================
; CPM_RPC6502_223.s -- embedded 6502 RPC service of SoftCard CP/M 2.23 (44K) BIOS
; ----------------------------------------------------------------------------
; 114 bytes that live at z80 $FDD0-$FE41 inside the de-skewed BIOS = Apple $0DD0
; (the SoftCard maps z80 $Fxxx -> Apple $0xxx low RAM). The SoftCard runs these
; bytes on the 6502 via the CPU switch (the RPC mechanism: the Z-80 stashes the
; 6502 target at A_VEC=$03D0 and writes Z_CPU=$03DE; the 6502 executes here and
; the Z-80 reads results back). From the Z-80 they are opaque data, so CPM_BIOS.asm
; INCBINs the assembled binary of THIS file at the $FDD0 position.
;   The service: SUB_0E1D forms a slot-ROM pointer (TYA/ORA #$C0 -> $Cn page in
;   $F6/$F7, STY $06F8, read $CFFF to disable expansion ROM) then LDA ($F6),Y; the
;   entries at $0DD0/$0DE1/$0E14 vary the index (Y = $0D/$0F/$10) and JMP ($00F6)
;   dispatches into the selected slot-ROM / firmware routine; the epilogue at $0E36
;   restores the Apple cursor ZP ($45/$46/$47), PLP/CLI/RTS back to the caller.
;   [RE] which Z-80 CALL site selects which entry is the OPEN question.
; ============================================================================

.setcpu "6502"
.segment "CODE"

.org $0DD0

L_0DD0:
        PHA                          ; $0DD0  48
        JSR SUB_0E1D                 ; $0DD1  20 1D 0E
        LDY #$0D                     ; $0DD4  A0 0D
L_0DD6:
        LDA ($F6),Y                  ; $0DD6  B1 F6
        STA $F6                      ; $0DD8  85 F6
        LDY $06F8                    ; $0DDA  AC F8 06
        PLA                          ; $0DDD  68
        JMP ($00F6)                ; $0DDE  6C F6 00
L_0DE1:
        PHA                          ; $0DE1  48
        LDA #$00                     ; $0DE2  A9 00
        JSR SUB_0DEF                 ; $0DE4  20 EF 0D
        JSR SUB_0E1D                 ; $0DE7  20 1D 0E
        LDY #$0F                     ; $0DEA  A0 0F
        JMP L_0DD6                   ; $0DEC  4C D6 0D
SUB_0DEF:
        STY $F5                      ; $0DEF  84 F5
        PHA                          ; $0DF1  48
        JSR SUB_0E14                 ; $0DF2  20 14 0E
        PLA                          ; $0DF5  68
        LDY $F5                      ; $0DF6  A4 F5
        BCC SUB_0DEF                 ; $0DF8  90 F5
        RTS                          ; $0DFA  60
        .byte   $00, $00, $00, $00, $00, $4C, $E9, $BB, $4C, $04, $BE, $A9, $01, $20, $EF, $0D ; $0DFB
        .byte   $20, $1D, $0E, $48, $A0, $0E, $4C, $D6, $0D      ; $0E0B
SUB_0E14:
        PHA                          ; $0E14  48
        JSR SUB_0E1D                 ; $0E15  20 1D 0E
        LDY #$10                     ; $0E18  A0 10
        JMP L_0DD6                   ; $0E1A  4C D6 0D
SUB_0E1D:
        TYA                          ; $0E1D  98
        ORA #$C0                     ; $0E1E  09 C0
        TAX                          ; $0E20  AA
        TYA                          ; $0E21  98
        ASL                          ; $0E22  0A
        ASL                          ; $0E23  0A
        ASL                          ; $0E24  0A
        ASL                          ; $0E25  0A
        TAY                          ; $0E26  A8
        STY $06F8                    ; $0E27  8C F8 06
        LDA #$00                     ; $0E2A  A9 00
        STA $F6                      ; $0E2C  85 F6
        STX $F7                      ; $0E2E  86 F7
        LDA $CFFF                    ; $0E30  AD FF CF
        LDA ($F6),Y                  ; $0E33  B1 F6
        RTS                          ; $0E35  60
SUB_0E1D_1:
        LDA $48                      ; $0E36  A5 48
        PHA                          ; $0E38  48
        LDA $45                      ; $0E39  A5 45
        LDX $46                      ; $0E3B  A6 46
        LDY $47                      ; $0E3D  A4 47
        PLP                          ; $0E3F  28
        CLI                          ; $0E40  58
        RTS                          ; $0E41  60
