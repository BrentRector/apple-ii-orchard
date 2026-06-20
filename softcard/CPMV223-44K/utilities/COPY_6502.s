; ============================================================================
; COPY_6502.s -- embedded 6502 disk driver of the COPY.COM utility (2.23 44K)
; ----------------------------------------------------------------------------
; 1408 bytes ($0900-$0E7F in the .COM image) that COPY.COM carries as 6502
; machine code. COPY runs on the Z-80; this block runs on the 6502 (SoftCard
; CPU switch), so from the Z-80 it is opaque data. Rather than bury it as a
; DEFB blob, it is disassembled as real 6502 and assembled separately with
; ca65; COPY.asm INCBINs the byte-identical binary.
;
; RELOCATED +$1000 AT RUNTIME. The block is loaded at $0900 in the .COM but the
; SoftCard stages it into Apple RAM and runs it at $1900-$1E7F, so every
; internal absolute self-reference here is written as $19xx-$1Exx (e.g.
; JMP $1C00, JSR $1991/$1992, LDA $1B00,X). Those $1xxx literals are the RUN
; addresses and are intentionally NOT rewritten to file ($09xx) form -- they
; must stay $1xxx for the relocated copy to work. External fixed Apple
; addresses (zero page, the $20xx/$1Fxx track buffers, $C08x slot-6 disk
; switches) appear as themselves.
;
; ENTRY POINTS (the Z-80 hands the 6502 a run-address via the SoftCard handoff
; block at $F3D0):
;   $1900  format-track driver (Z-80 FORMAT_DEST_DISK: LD HL,$1900)
;   $1E03  read/write-track driver (Z-80 passes CHECK_SOURCE_SYSTEM_44, the
;          load address $0E03; COPY.asm equates that label to COPY_6502+$0503)
;   $1E67  a third write-prep entry reached by a separate handoff
; This is a 6-and-2 GCR Disk II engine: write-nibble / read-address / read-data
; / seek / format-track, with the standard nibble-translate tables inline.
;
; GENUINE DATA SUB-REGIONS (never code):
;   $0AD1-$0AE8  two 12-byte phase step / head-settle delay tables
;   $0AE9-$0AFF  $00 fill
;   $0B00-$0B3F  write-translate table (6-bit -> disk nibble, $96..$FF)
;   $0B40-$0B95  $00 fill
;   $0B96-$0BFF  read-translate table (disk nibble -> 6-bit, sparse inverse)
;   $0E57-$0E66  16-byte format scratch buffer (the $1E57 work area)
;
; The byte at file $0E80 (run $1E80) begins UNRELATED Z-80 bytes that stay in
; COPY.asm; the 6502 region ends at $0E7F. Clean recursive-descent decode from
; the three entries above plus an after-terminal sweep covers every byte; what
; is not reachable 6502 code is one of the data sub-regions above.
;
; Comments are [AI] inference unless tagged. Reassembles BYTE-IDENTICAL to the
; on-disk block (see cpm_pipeline test_utilities_roundtrip).
; ============================================================================
.setcpu "6502"
.segment "CODE"

; -- Mid-instruction references (shown inline as cover+offset) --
;   $0D45 -> SUB_0D3E_1+1         6502 skip idiom: enters the operand of $2C at $0D44
;   $0E03 -> SUB_0DD4_2+1         shared instruction tail: $0E03 is reachable code inside the instruction at $0E02


.org $0900

L_0900:
        JMP $1C00                    ; $0900  4C 00 1C
SUB_0903:
        SEC                          ; $0903  38
        STX $27                      ; $0904  86 27
        STX $0678                    ; $0906  8E 78 06
        LDA $C08D,X                  ; $0909  BD 8D C0
        LDA $C08E,X                  ; $090C  BD 8E C0
        BMI SUB_0903_5               ; $090F  30 7C
        LDA $2000                    ; $0911  AD 00 20
        STA $26                      ; $0914  85 26
        LDA #$FF                     ; $0916  A9 FF
        STA $C08F,X                  ; $0918  9D 8F C0
        ORA $C08C,X                  ; $091B  1D 8C C0
        PHA                          ; $091E  48
        PLA                          ; $091F  68
        NOP                          ; $0920  EA
        LDY #$04                     ; $0921  A0 04
SUB_0903_1:
        PHA                          ; $0923  48
        PLA                          ; $0924  68
        JSR $1992                    ; $0925  20 92 19
        DEY                          ; $0928  88
        BNE SUB_0903_1               ; $0929  D0 F8
        LDA #$D5                     ; $092B  A9 D5
        JSR $1991                    ; $092D  20 91 19
        LDA #$AA                     ; $0930  A9 AA
        JSR $1991                    ; $0932  20 91 19
        LDA #$AD                     ; $0935  A9 AD
        JSR $1991                    ; $0937  20 91 19
        TYA                          ; $093A  98
        LDY #$56                     ; $093B  A0 56
        BNE SUB_0903_3               ; $093D  D0 03
SUB_0903_2:
        LDA $2000,Y                  ; $093F  B9 00 20
SUB_0903_3:
        EOR $1FFF,Y                  ; $0942  59 FF 1F
        TAX                          ; $0945  AA
        LDA $1B00,X                  ; $0946  BD 00 1B
        LDX $27                      ; $0949  A6 27
        STA $C08D,X                  ; $094B  9D 8D C0
        LDA $C08C,X                  ; $094E  BD 8C C0
        DEY                          ; $0951  88
        BNE SUB_0903_2               ; $0952  D0 EB
        LDA $26                      ; $0954  A5 26
        NOP                          ; $0956  EA
SUB_0903_4:
        EOR $1F00,Y                  ; $0957  59 00 1F
        TAX                          ; $095A  AA
        LDA $1B00,X                  ; $095B  BD 00 1B
        LDX $0678                    ; $095E  AE 78 06
        STA $C08D,X                  ; $0961  9D 8D C0
        LDA $C08C,X                  ; $0964  BD 8C C0
        LDA $1F00,Y                  ; $0967  B9 00 1F
        INY                          ; $096A  C8
        BNE SUB_0903_4               ; $096B  D0 EA
        TAX                          ; $096D  AA
        LDA $1B00,X                  ; $096E  BD 00 1B
        LDX $27                      ; $0971  A6 27
        JSR $1994                    ; $0973  20 94 19
        LDA #$DE                     ; $0976  A9 DE
        JSR $1991                    ; $0978  20 91 19
        LDA #$AA                     ; $097B  A9 AA
        JSR $1991                    ; $097D  20 91 19
        LDA #$EB                     ; $0980  A9 EB
        JSR $1991                    ; $0982  20 91 19
        LDA #$FF                     ; $0985  A9 FF
        JSR $1991                    ; $0987  20 91 19
        LDA $C08E,X                  ; $098A  BD 8E C0
SUB_0903_5:
        LDA $C08C,X                  ; $098D  BD 8C C0
        RTS                          ; $0990  60
SUB_0991:
        CLC                          ; $0991  18
SUB_0992:
        PHA                          ; $0992  48
        PLA                          ; $0993  68
SUB_0994:
        STA $C08D,X                  ; $0994  9D 8D C0
        ORA $C08C,X                  ; $0997  1D 8C C0
        RTS                          ; $099A  60
SUB_099B:
        LDY #$20                     ; $099B  A0 20
SUB_099B_1:
        DEY                          ; $099D  88
        BEQ SUB_099B_13              ; $099E  F0 61
SUB_099B_2:
        LDA $C08C,X                  ; $09A0  BD 8C C0
        BPL SUB_099B_2               ; $09A3  10 FB
SUB_099B_3:
        EOR #$D5                     ; $09A5  49 D5
        BNE SUB_099B_1               ; $09A7  D0 F4
        NOP                          ; $09A9  EA
SUB_099B_4:
        LDA $C08C,X                  ; $09AA  BD 8C C0
        BPL SUB_099B_4               ; $09AD  10 FB
        CMP #$AA                     ; $09AF  C9 AA
        BNE SUB_099B_3               ; $09B1  D0 F2
        LDY #$56                     ; $09B3  A0 56
SUB_099B_5:
        LDA $C08C,X                  ; $09B5  BD 8C C0
        BPL SUB_099B_5               ; $09B8  10 FB
        CMP #$AD                     ; $09BA  C9 AD
        BNE SUB_099B_3               ; $09BC  D0 E7
        LDA #$00                     ; $09BE  A9 00
SUB_099B_6:
        DEY                          ; $09C0  88
        STY $26                      ; $09C1  84 26
SUB_099B_7:
        LDY $C08C,X                  ; $09C3  BC 8C C0
        BPL SUB_099B_7               ; $09C6  10 FB
        EOR $1B00,Y                  ; $09C8  59 00 1B
        LDY $26                      ; $09CB  A4 26
        STA $2200,Y                  ; $09CD  99 00 22
        BNE SUB_099B_6               ; $09D0  D0 EE
SUB_099B_8:
        STY $26                      ; $09D2  84 26
SUB_099B_9:
        LDY $C08C,X                  ; $09D4  BC 8C C0
        BPL SUB_099B_9               ; $09D7  10 FB
        EOR $1B00,Y                  ; $09D9  59 00 1B
        LDY $26                      ; $09DC  A4 26
        STA $2100,Y                  ; $09DE  99 00 21
        INY                          ; $09E1  C8
        BNE SUB_099B_8               ; $09E2  D0 EE
SUB_099B_10:
        LDY $C08C,X                  ; $09E4  BC 8C C0
        BPL SUB_099B_10              ; $09E7  10 FB
        CMP $1B00,Y                  ; $09E9  D9 00 1B
        BNE SUB_099B_13              ; $09EC  D0 13
SUB_099B_11:
        LDA $C08C,X                  ; $09EE  BD 8C C0
        BPL SUB_099B_11              ; $09F1  10 FB
        CMP #$DE                     ; $09F3  C9 DE
        BNE SUB_099B_13              ; $09F5  D0 0A
        NOP                          ; $09F7  EA
SUB_099B_12:
        LDA $C08C,X                  ; $09F8  BD 8C C0
        BPL SUB_099B_12              ; $09FB  10 FB
        CMP #$AA                     ; $09FD  C9 AA
        BEQ SUB_0A03_11              ; $09FF  F0 5C
SUB_099B_13:
        SEC                          ; $0A01  38
        RTS                          ; $0A02  60
SUB_0A03:
        LDY #$FC                     ; $0A03  A0 FC
        STY $26                      ; $0A05  84 26
SUB_0A03_1:
        INY                          ; $0A07  C8
        BNE SUB_0A03_2               ; $0A08  D0 04
        INC $26                      ; $0A0A  E6 26
        BEQ SUB_099B_13              ; $0A0C  F0 F3
SUB_0A03_2:
        LDA $C08C,X                  ; $0A0E  BD 8C C0
        BPL SUB_0A03_2               ; $0A11  10 FB
SUB_0A03_3:
        CMP #$D5                     ; $0A13  C9 D5
        BNE SUB_0A03_1               ; $0A15  D0 F0
        NOP                          ; $0A17  EA
SUB_0A03_4:
        LDA $C08C,X                  ; $0A18  BD 8C C0
        BPL SUB_0A03_4               ; $0A1B  10 FB
        CMP #$AA                     ; $0A1D  C9 AA
        BNE SUB_0A03_3               ; $0A1F  D0 F2
        LDY #$03                     ; $0A21  A0 03
SUB_0A03_5:
        LDA $C08C,X                  ; $0A23  BD 8C C0
        BPL SUB_0A03_5               ; $0A26  10 FB
        CMP #$96                     ; $0A28  C9 96
        BNE SUB_0A03_3               ; $0A2A  D0 E7
        LDA #$00                     ; $0A2C  A9 00
SUB_0A03_6:
        STA $27                      ; $0A2E  85 27
SUB_0A03_7:
        LDA $C08C,X                  ; $0A30  BD 8C C0
        BPL SUB_0A03_7               ; $0A33  10 FB
        ROL                          ; $0A35  2A
        STA $26                      ; $0A36  85 26
SUB_0A03_8:
        LDA $C08C,X                  ; $0A38  BD 8C C0
        BPL SUB_0A03_8               ; $0A3B  10 FB
        AND $26                      ; $0A3D  25 26
        STA a:$002C,Y                ; $0A3F  99 2C 00
        EOR $27                      ; $0A42  45 27
        DEY                          ; $0A44  88
        BPL SUB_0A03_6               ; $0A45  10 E7
        TAY                          ; $0A47  A8
        BNE SUB_099B_13              ; $0A48  D0 B7
SUB_0A03_9:
        LDA $C08C,X                  ; $0A4A  BD 8C C0
        BPL SUB_0A03_9               ; $0A4D  10 FB
        CMP #$DE                     ; $0A4F  C9 DE
        BNE SUB_099B_13              ; $0A51  D0 AE
        NOP                          ; $0A53  EA
SUB_0A03_10:
        LDA $C08C,X                  ; $0A54  BD 8C C0
        BPL SUB_0A03_10              ; $0A57  10 FB
        CMP #$AA                     ; $0A59  C9 AA
        BNE SUB_099B_13              ; $0A5B  D0 A4
SUB_0A03_11:
        CLC                          ; $0A5D  18
        RTS                          ; $0A5E  60
SUB_0A03_12:
        STX $2B                      ; $0A5F  86 2B
        STA $2A                      ; $0A61  85 2A
        CMP $0478                    ; $0A63  CD 78 04
        BEQ SUB_0AB0_1               ; $0A66  F0 53
        LDA #$00                     ; $0A68  A9 00
        STA $26                      ; $0A6A  85 26
SUB_0A03_13:
        LDA $0478                    ; $0A6C  AD 78 04
        STA $27                      ; $0A6F  85 27
        SEC                          ; $0A71  38
        SBC $2A                      ; $0A72  E5 2A
        BEQ SUB_0A03_18              ; $0A74  F0 33
        BCS SUB_0A03_14              ; $0A76  B0 07
        EOR #$FF                     ; $0A78  49 FF
        INC $0478                    ; $0A7A  EE 78 04
        BCC SUB_0A03_15              ; $0A7D  90 05
SUB_0A03_14:
        ADC #$FE                     ; $0A7F  69 FE
        DEC $0478                    ; $0A81  CE 78 04
SUB_0A03_15:
        CMP $26                      ; $0A84  C5 26
        BCC SUB_0A03_16              ; $0A86  90 02
        LDA $26                      ; $0A88  A5 26
SUB_0A03_16:
        CMP #$0C                     ; $0A8A  C9 0C
        BCS SUB_0A03_17              ; $0A8C  B0 01
        TAY                          ; $0A8E  A8
SUB_0A03_17:
        SEC                          ; $0A8F  38
        JSR $1AAD                    ; $0A90  20 AD 1A
        LDA $1AD1,Y                  ; $0A93  B9 D1 1A
        JSR $1ABC                    ; $0A96  20 BC 1A
        LDA $27                      ; $0A99  A5 27
        CLC                          ; $0A9B  18
        JSR $1AB0                    ; $0A9C  20 B0 1A
        LDA $1ADD,Y                  ; $0A9F  B9 DD 1A
        JSR $1ABC                    ; $0AA2  20 BC 1A
        INC $26                      ; $0AA5  E6 26
        BNE SUB_0A03_13              ; $0AA7  D0 C3
SUB_0A03_18:
        JSR $1ABC                    ; $0AA9  20 BC 1A
        CLC                          ; $0AAC  18
SUB_0AAD:
        LDA $0478                    ; $0AAD  AD 78 04
SUB_0AB0:
        AND #$03                     ; $0AB0  29 03
        ROL                          ; $0AB2  2A
        ORA $2B                      ; $0AB3  05 2B
        TAX                          ; $0AB5  AA
        LDA $C080,X                  ; $0AB6  BD 80 C0
        LDX $2B                      ; $0AB9  A6 2B
SUB_0AB0_1:
        RTS                          ; $0ABB  60
SUB_0ABC:
        LDX #$11                     ; $0ABC  A2 11
SUB_0ABC_1:
        DEX                          ; $0ABE  CA
        BNE SUB_0ABC_1               ; $0ABF  D0 FD
        INC $46                      ; $0AC1  E6 46
        BNE SUB_0ABC_2               ; $0AC3  D0 06
        INC $47                      ; $0AC5  E6 47
        BNE SUB_0ABC_2               ; $0AC7  D0 02
        DEC $47                      ; $0AC9  C6 47
SUB_0ABC_2:
        SEC                          ; $0ACB  38
        SBC #$01                     ; $0ACC  E9 01
        BNE SUB_0ABC                 ; $0ACE  D0 EC
        RTS                          ; $0AD0  60
        .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C, $70, $2C, $26, $22 ; $0AD1
        .byte   $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C           ; $0AE1
        .res    23, $00    ; $0AE9  fill
        .byte   $96, $97, $9A, $9B, $9D, $9E, $9F, $A6, $A7, $AB, $AC, $AD, $AE, $AF, $B2, $B3 ; $0B00
        .byte   $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC, $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3 ; $0B10
        .byte   $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE, $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC ; $0B20
        .byte   $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6, $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF ; $0B30
        .res    87, $00    ; $0B40  fill
        .byte   $01, $98, $99, $02, $03, $9C, $04, $05, $06, $A0, $A1, $A2, $A3, $A4, $A5, $07 ; $0B97
        .byte   $08, $A8, $A9, $AA, $09, $0A, $0B, $0C, $0D, $B0, $B1, $0E, $0F, $10, $11, $12 ; $0BA7
        .byte   $13, $B8, $14, $15, $16, $17, $18, $19, $1A, $C0, $C1, $C2, $C3, $C4, $C5, $C6 ; $0BB7
        .byte   $C7, $C8, $C9, $CA, $1B, $CC, $1C, $1D, $1E, $D0, $D1, $D2, $1F, $D4, $D5, $20 ; $0BC7
        .byte   $21, $D8, $22, $23, $24, $25, $26, $27, $28, $E0, $E1, $E2, $E3, $E4, $29, $2A ; $0BD7
        .byte   $2B, $E8, $2C, $2D, $2E, $2F, $30, $31, $32, $F0, $F1, $33, $34, $35, $36, $37 ; $0BE7
        .byte   $38, $F8, $39, $3A, $3B, $3C, $3D, $3E, $3F      ; $0BF7
SUB_0ABC_3:
        PHP                          ; $0C00  08
        SEI                          ; $0C01  78
        JSR $1C07                    ; $0C02  20 07 1C
        PLP                          ; $0C05  28
        RTS                          ; $0C06  60
SUB_0C07:
        LDY #$02                     ; $0C07  A0 02
        STY $06F8                    ; $0C09  8C F8 06
        LDY #$04                     ; $0C0C  A0 04
        STY $04F8                    ; $0C0E  8C F8 04
        LDA $03E6                    ; $0C11  AD E6 03
        TAX                          ; $0C14  AA
        CMP $03E7                    ; $0C15  CD E7 03
        BEQ SUB_0C07_3               ; $0C18  F0 1D
        TXA                          ; $0C1A  8A
        PHA                          ; $0C1B  48
        LDA $03E7                    ; $0C1C  AD E7 03
        TAX                          ; $0C1F  AA
        PLA                          ; $0C20  68
        PHA                          ; $0C21  48
        STA $03E7                    ; $0C22  8D E7 03
        LDA $C08E,X                  ; $0C25  BD 8E C0
SUB_0C07_1:
        LDY #$08                     ; $0C28  A0 08
        LDA $C08C,X                  ; $0C2A  BD 8C C0
SUB_0C07_2:
        CMP $C08C,X                  ; $0C2D  DD 8C C0
        BNE SUB_0C07_1               ; $0C30  D0 F6
        DEY                          ; $0C32  88
        BNE SUB_0C07_2               ; $0C33  D0 F8
        PLA                          ; $0C35  68
        TAX                          ; $0C36  AA
SUB_0C07_3:
        LDA $C08E,X                  ; $0C37  BD 8E C0
        LDA $C08C,X                  ; $0C3A  BD 8C C0
        LDY #$08                     ; $0C3D  A0 08
SUB_0C07_4:
        LDA $C08C,X                  ; $0C3F  BD 8C C0
        PHA                          ; $0C42  48
        PLA                          ; $0C43  68
        STX $05F8                    ; $0C44  8E F8 05
        CMP $C08C,X                  ; $0C47  DD 8C C0
        BNE SUB_0C07_5               ; $0C4A  D0 03
        DEY                          ; $0C4C  88
        BNE SUB_0C07_4               ; $0C4D  D0 F0
SUB_0C07_5:
        PHP                          ; $0C4F  08
        LDA $C089,X                  ; $0C50  BD 89 C0
        LDA #$EF                     ; $0C53  A9 EF
        STA $46                      ; $0C55  85 46
        LDA #$D8                     ; $0C57  A9 D8
        STA $47                      ; $0C59  85 47
        LDA $03E4                    ; $0C5B  AD E4 03
        CMP $03E5                    ; $0C5E  CD E5 03
        BEQ SUB_0C07_6               ; $0C61  F0 07
        STA $03E5                    ; $0C63  8D E5 03
        PLP                          ; $0C66  28
        LDY #$00                     ; $0C67  A0 00
        PHP                          ; $0C69  08
SUB_0C07_6:
        ROR                          ; $0C6A  6A
        BCC SUB_0C07_7               ; $0C6B  90 05
        LDA $C08A,X                  ; $0C6D  BD 8A C0
        BCS SUB_0C07_8               ; $0C70  B0 03
SUB_0C07_7:
        LDA $C08B,X                  ; $0C72  BD 8B C0
SUB_0C07_8:
        ROR $35                      ; $0C75  66 35
        PLP                          ; $0C77  28
        PHP                          ; $0C78  08
        BNE SUB_0C07_10              ; $0C79  D0 08
        LDY #$07                     ; $0C7B  A0 07
SUB_0C07_9:
        JSR $1ABC                    ; $0C7D  20 BC 1A
        DEY                          ; $0C80  88
        BNE SUB_0C07_9               ; $0C81  D0 FA
SUB_0C07_10:
        LDX $05F8                    ; $0C83  AE F8 05
        PLP                          ; $0C86  28
        BNE SUB_0C07_13              ; $0C87  D0 0D
SUB_0C07_11:
        LDY #$12                     ; $0C89  A0 12
SUB_0C07_12:
        DEY                          ; $0C8B  88
        BNE SUB_0C07_12              ; $0C8C  D0 FD
        INC $46                      ; $0C8E  E6 46
        BNE SUB_0C07_11              ; $0C90  D0 F7
        INC $47                      ; $0C92  E6 47
        BNE SUB_0C07_11              ; $0C94  D0 F3
SUB_0C07_13:
        JMP $1CDA                    ; $0C96  4C DA 1C
SUB_0C99:
        PHA                          ; $0C99  48
        JSR $1CBA                    ; $0C9A  20 BA 1C
        LDA $0478,Y                  ; $0C9D  B9 78 04
        BIT $35                      ; $0CA0  24 35
        BMI SUB_0C99_1               ; $0CA2  30 03
        LDA $04F8,Y                  ; $0CA4  B9 F8 04
SUB_0C99_1:
        STA $0478                    ; $0CA7  8D 78 04
        PLA                          ; $0CAA  68
        BIT $35                      ; $0CAB  24 35
        BMI SUB_0C99_2               ; $0CAD  30 05
        STA $04F8,Y                  ; $0CAF  99 F8 04
        BPL SUB_0C99_3               ; $0CB2  10 03
SUB_0C99_2:
        STA $0478,Y                  ; $0CB4  99 78 04
SUB_0C99_3:
        JMP $1A5F                    ; $0CB7  4C 5F 1A
SUB_0CBA:
        TXA                          ; $0CBA  8A
        LSR                          ; $0CBB  4A
        LSR                          ; $0CBC  4A
        LSR                          ; $0CBD  4A
        LSR                          ; $0CBE  4A
        TAY                          ; $0CBF  A8
        RTS                          ; $0CC0  60
SUB_0CC1:
        PHA                          ; $0CC1  48
        LDA $03E4                    ; $0CC2  AD E4 03
        ROR                          ; $0CC5  6A
        ROR $35                      ; $0CC6  66 35
        JSR $1CBA                    ; $0CC8  20 BA 1C
        PLA                          ; $0CCB  68
        ASL                          ; $0CCC  0A
        BIT $35                      ; $0CCD  24 35
        BMI SUB_0CC1_1               ; $0CCF  30 05
        STA $04F8,Y                  ; $0CD1  99 F8 04
        BPL SUB_0CC1_2               ; $0CD4  10 03
SUB_0CC1_1:
        STA $0478,Y                  ; $0CD6  99 78 04
SUB_0CC1_2:
        RTS                          ; $0CD9  60
SUB_0CC1_3:
        LDA #$CD                     ; $0CDA  A9 CD
        STA $2F                      ; $0CDC  85 2F
        LDA #$AA                     ; $0CDE  A9 AA
        STA $50                      ; $0CE0  85 50
        LDY #$00                     ; $0CE2  A0 00
        LDA #$39                     ; $0CE4  A9 39
SUB_0CC1_4:
        STA $1F00,Y                  ; $0CE6  99 00 1F
        DEY                          ; $0CE9  88
        BNE SUB_0CC1_4               ; $0CEA  D0 FA
        LDY #$56                     ; $0CEC  A0 56
        LDA #$2A                     ; $0CEE  A9 2A
SUB_0CC1_5:
        STA $1FFF,Y                  ; $0CF0  99 FF 1F
        DEY                          ; $0CF3  88
        BNE SUB_0CC1_5               ; $0CF4  D0 FA
        STY $41                      ; $0CF6  84 41
        LDA #$50                     ; $0CF8  A9 50
        JSR $1CC1                    ; $0CFA  20 C1 1C
        LDA #$26                     ; $0CFD  A9 26
        STA $51                      ; $0CFF  85 51
SUB_0CC1_6:
        LDA $41                      ; $0D01  A5 41
        ASL                          ; $0D03  0A
        JSR $1C99                    ; $0D04  20 99 1C
        JSR $1D3E                    ; $0D07  20 3E 1D
SUB_0CC1_7:
        LDA #$40                     ; $0D0A  A9 40
        BCS SUB_0CC1_9               ; $0D0C  B0 23
        LDA #$30                     ; $0D0E  A9 30
        STA $0578                    ; $0D10  8D 78 05
SUB_0CC1_8:
        SEC                          ; $0D13  38
        DEC $0578                    ; $0D14  CE 78 05
        BEQ SUB_0CC1_7               ; $0D17  F0 F1
        JSR $1A03                    ; $0D19  20 03 1A
        BCS SUB_0CC1_8               ; $0D1C  B0 F5
        LDA $2D                      ; $0D1E  A5 2D
        BNE SUB_0CC1_8               ; $0D20  D0 F1
        JSR $199B                    ; $0D22  20 9B 19
        BCS SUB_0CC1_8               ; $0D25  B0 EC
        INC $41                      ; $0D27  E6 41
        LDA $41                      ; $0D29  A5 41
        CMP #$23                     ; $0D2B  C9 23
        BCC SUB_0CC1_6               ; $0D2D  90 D2
        LDA #$00                     ; $0D2F  A9 00
SUB_0CC1_9:
        STA $03EA                    ; $0D31  8D EA 03
        LDA $C088,X                  ; $0D34  BD 88 C0
        RTS                          ; $0D37  60
SUB_0CC1_10:
        PLA                          ; $0D38  68
        PLA                          ; $0D39  68
        LDA #$10                     ; $0D3A  A9 10
        BNE SUB_0CC1_9               ; $0D3C  D0 F3
SUB_0D3E:
        LDA #$00                     ; $0D3E  A9 00
        STA $52                      ; $0D40  85 52
        LDY #$80                     ; $0D42  A0 80
SUB_0D3E_1:
        BIT $51A4                    ; $0D44  2C A4 51
        JSR $1DD4                    ; $0D47  20 D4 1D
        BCS SUB_0CC1_10              ; $0D4A  B0 EC
        JSR $1903                    ; $0D4C  20 03 19
        BCS SUB_0D3E_9               ; $0D4F  B0 62
        INC $52                      ; $0D51  E6 52
        LDA $52                      ; $0D53  A5 52
        CMP #$10                     ; $0D55  C9 10
        BCC SUB_0D3E_1+1             ; $0D57  90 EC
        LDY #$0F                     ; $0D59  A0 0F
        STY $52                      ; $0D5B  84 52
        LDA #$30                     ; $0D5D  A9 30
        STA $0578                    ; $0D5F  8D 78 05
SUB_0D3E_2:
        STA $1E57,Y                  ; $0D62  99 57 1E
        DEY                          ; $0D65  88
        BPL SUB_0D3E_2               ; $0D66  10 FA
        LDY $51                      ; $0D68  A4 51
SUB_0D3E_3:
        JSR $1DD2                    ; $0D6A  20 D2 1D
        JSR $1DD2                    ; $0D6D  20 D2 1D
        PHA                          ; $0D70  48
        PLA                          ; $0D71  68
        DEY                          ; $0D72  88
        BNE SUB_0D3E_3               ; $0D73  D0 F5
        JSR $1A03                    ; $0D75  20 03 1A
        BCS SUB_0D3E_7               ; $0D78  B0 23
        LDA $2D                      ; $0D7A  A5 2D
        BEQ SUB_0D3E_5               ; $0D7C  F0 15
        LDA #$10                     ; $0D7E  A9 10
        CMP $51                      ; $0D80  C5 51
        LDA $51                      ; $0D82  A5 51
        SBC #$01                     ; $0D84  E9 01
        STA $51                      ; $0D86  85 51
        CMP #$05                     ; $0D88  C9 05
        BCS SUB_0D3E_7               ; $0D8A  B0 11
        SEC                          ; $0D8C  38
        RTS                          ; $0D8D  60
SUB_0D3E_4:
        JSR $1A03                    ; $0D8E  20 03 1A
        BCS SUB_0D3E_6               ; $0D91  B0 05
SUB_0D3E_5:
        JSR $199B                    ; $0D93  20 9B 19
        BCC SUB_0D3E_10              ; $0D96  90 1C
SUB_0D3E_6:
        DEC $0578                    ; $0D98  CE 78 05
        BNE SUB_0D3E_4               ; $0D9B  D0 F1
SUB_0D3E_7:
        JSR $1A03                    ; $0D9D  20 03 1A
        BCS SUB_0D3E_8               ; $0DA0  B0 0B
        LDA $2D                      ; $0DA2  A5 2D
        CMP #$0F                     ; $0DA4  C9 0F
        BNE SUB_0D3E_8               ; $0DA6  D0 05
        JSR $199B                    ; $0DA8  20 9B 19
        BCC SUB_0D3E                 ; $0DAB  90 91
SUB_0D3E_8:
        DEC $0578                    ; $0DAD  CE 78 05
        BNE SUB_0D3E_7               ; $0DB0  D0 EB
        SEC                          ; $0DB2  38
SUB_0D3E_9:
        RTS                          ; $0DB3  60
SUB_0D3E_10:
        LDY $2D                      ; $0DB4  A4 2D
        LDA $1E57,Y                  ; $0DB6  B9 57 1E
        BMI SUB_0D3E_6               ; $0DB9  30 DD
        LDA #$FF                     ; $0DBB  A9 FF
        STA $1E57,Y                  ; $0DBD  99 57 1E
        DEC $52                      ; $0DC0  C6 52
        BPL SUB_0D3E_4               ; $0DC2  10 CA
        LDA $41                      ; $0DC4  A5 41
        BNE SUB_0DD2                 ; $0DC6  D0 0A
        LDA $51                      ; $0DC8  A5 51
        CMP #$10                     ; $0DCA  C9 10
        BCC SUB_0D3E_9               ; $0DCC  90 E5
        DEC $51                      ; $0DCE  C6 51
        DEC $51                      ; $0DD0  C6 51
SUB_0DD2:
        CLC                          ; $0DD2  18
        RTS                          ; $0DD3  60
SUB_0DD4:
        SEC                          ; $0DD4  38
        LDA $C08D,X                  ; $0DD5  BD 8D C0
        LDA $C08E,X                  ; $0DD8  BD 8E C0
        BMI SUB_0DD4_3               ; $0DDB  30 58
        LDA #$FF                     ; $0DDD  A9 FF
        STA $C08F,X                  ; $0DDF  9D 8F C0
        CMP $C08C,X                  ; $0DE2  DD 8C C0
        PHA                          ; $0DE5  48
        PLA                          ; $0DE6  68
        NOP                          ; $0DE7  EA
        NOP                          ; $0DE8  EA
SUB_0DD4_1:
        PHA                          ; $0DE9  48
        PLA                          ; $0DEA  68
        JSR $1992                    ; $0DEB  20 92 19
        DEY                          ; $0DEE  88
        BNE SUB_0DD4_1               ; $0DEF  D0 F8
        LDA #$D5                     ; $0DF1  A9 D5
        JSR $1991                    ; $0DF3  20 91 19
        LDA #$AA                     ; $0DF6  A9 AA
        JSR $1991                    ; $0DF8  20 91 19
        LDA #$96                     ; $0DFB  A9 96
        JSR $1991                    ; $0DFD  20 91 19
        LDA $2F                      ; $0E00  A5 2F
SUB_0DD4_2:
        JSR $1E3C                    ; $0E02  20 3C 1E
        LDA $41                      ; $0E05  A5 41
        JSR $1E3C                    ; $0E07  20 3C 1E
        LDA $52                      ; $0E0A  A5 52
        JSR $1E3C                    ; $0E0C  20 3C 1E
        LDA $2F                      ; $0E0F  A5 2F
        EOR $41                      ; $0E11  45 41
        EOR $52                      ; $0E13  45 52
        PHA                          ; $0E15  48
        LSR                          ; $0E16  4A
        ORA $50                      ; $0E17  05 50
        STA $C08D,X                  ; $0E19  9D 8D C0
        LDA $C08C,X                  ; $0E1C  BD 8C C0
        PLA                          ; $0E1F  68
        ORA #$AA                     ; $0E20  09 AA
        JSR $1E4C                    ; $0E22  20 4C 1E
        LDA #$DE                     ; $0E25  A9 DE
        JSR $1991                    ; $0E27  20 91 19
        LDA #$AA                     ; $0E2A  A9 AA
        JSR $1991                    ; $0E2C  20 91 19
        LDA #$EB                     ; $0E2F  A9 EB
        JSR $1991                    ; $0E31  20 91 19
        CLC                          ; $0E34  18
SUB_0DD4_3:
        LDA $C08E,X                  ; $0E35  BD 8E C0
        LDA $C08C,X                  ; $0E38  BD 8C C0
        RTS                          ; $0E3B  60
SUB_0E3C:
        PHA                          ; $0E3C  48
        LSR                          ; $0E3D  4A
        ORA $50                      ; $0E3E  05 50
        STA $C08D,X                  ; $0E40  9D 8D C0
        CMP $C08C,X                  ; $0E43  DD 8C C0
        PLA                          ; $0E46  68
        NOP                          ; $0E47  EA
        NOP                          ; $0E48  EA
        NOP                          ; $0E49  EA
        ORA #$AA                     ; $0E4A  09 AA
SUB_0E4C:
        NOP                          ; $0E4C  EA
        CLC                          ; $0E4D  18
        PHA                          ; $0E4E  48
        PLA                          ; $0E4F  68
        STA $C08D,X                  ; $0E50  9D 8D C0
        ORA $C08C,X                  ; $0E53  1D 8C C0
        RTS                          ; $0E56  60
        .res    16, $00    ; $0E57  fill
SUB_0E4C_1:
        NOP                          ; $0E67  EA
        NOP                          ; $0E68  EA
SUB_0E4C_2:
        PHA                          ; $0E69  48
        PLA                          ; $0E6A  68
        JSR $1992                    ; $0E6B  20 92 19
        DEY                          ; $0E6E  88
        BNE SUB_0E4C_2               ; $0E6F  D0 F8
        LDA #$D5                     ; $0E71  A9 D5
        JSR $1991                    ; $0E73  20 91 19
        LDA #$AA                     ; $0E76  A9 AA
        JSR $1991                    ; $0E78  20 91 19
        LDA #$96                     ; $0E7B  A9 96
        JSR $1991                    ; $0E7D  20 91 19
