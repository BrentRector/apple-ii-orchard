; ============================================================================
; STAT_6502.s -- stale 6502 work-buffer tail of STAT.COM (SoftCard CP/M 2.20, 44K)
; ----------------------------------------------------------------------------
; The tail of STAT.COM ($15BD-$18FF in the loaded image) is NOT Z-80 code or live
; data -- nothing in STAT references it (its last live scratch variable is
; FILE_SORTKEY_TBL at $15BC; nothing touches $15BD or beyond). It is leftover
; content of the cross-assembler's work buffer -- the uninitialised top of STAT's
; BSS, captured when the .COM was SAVEd. Two recognisable parts:
;
;   $15BD-$15FF  a fragment of assembled 6502 OBJECT CODE (a Disk II denibble /
;                16-bit-add helper -- LDA #$03 / STA $8F / ... / JMP $1D59, plus an
;                ($5E),Y read+add loop). Being a fragment, its last bytes are
;                partial instructions; ca65 cannot encode the one undocumented
;                opcode that falls here ($15F7 NOP #imm), so that and the single
;                $15FF byte that straddles the text boundary are emitted as `.byte`.
;
;   $1600-$18FF  the 6502 ASSEMBLY-SOURCE LISTING of a Disk II seek/read driver,
;                stored as high-bit ($80-set) Apple text, one source line per $8D
;                (carriage-return). Lines: "SAMEDRV LDA A.TRK" / "JSR MYSEEK" /
;                "TRYTRK ... RDADR ... SETTRK ... RETRYCNT" / "GOCAL" / "DRVERR" /
;                "RTTRK LDA A.VOL", etc. -- the symbolic source of a driver like
;                the object fragment above.
;
; Both run on the 6502 conceptually (the SoftCard CPU switch), so from the Z-80
; they are opaque data; STAT.asm INCBINs the assembled binary of this file.
; Nothing references the block, so NO cross-CPU EQUs are needed (the live Z-80
; scratch variables all sit below $15BD and stay as Z-80 DEFB in STAT.asm). The
; block is a captured buffer (NOT relocated by STAT), so it is disassembled in
; place at its load address $15BD and the absolute operands are the literal bytes.
;
; The source-listing text is emitted as readable strings via a `.charmap` that
; maps each printable ASCII code to its high-bit Apple form (e.g. 'A' -> $C1,
; ' ' -> $A0), with the $8D line terminator emitted literally -- so the listing is
; legible yet the bytes are unchanged. Reassembles BYTE-IDENTICAL to the on-disk
; tail (see cpm_pipeline test_utilities_roundtrip, STAT case).
; ============================================================================

.setcpu "6502"
.segment "CODE"

.org $15BD

; -- $15BD-$15FF: assembled 6502 object-code fragment --
        LDA #$03                     ; $15BD  A9 03
        STA $8F                      ; $15BF  85 8F
        LDA $94                      ; $15C1  A5 94
        LDX $95                      ; $15C3  A6 95
        CPX $6E                      ; $15C5  E4 6E
        BNE $15D0                    ; $15C7  D0 07
        CMP $6D                      ; $15C9  C5 6D
        BNE $15D0                    ; $15CB  D0 03
        JMP $1D59                    ; $15CD  4C 59 1D
        STA $5E                      ; $15D0  85 5E
        STX $00                      ; $15D2  86 00
        LDY #$00                     ; $15D4  A0 00
        LDA ($5E),Y                  ; $15D6  B1 5E
        TAX                          ; $15D8  AA
        INY                          ; $15D9  C8
        LDA ($5E),Y                  ; $15DA  B1 5E
        PHP                          ; $15DC  08
        INY                          ; $15DD  C8
        LDA ($5E),Y                  ; $15DE  B1 5E
        ADC $94                      ; $15E0  65 94
        STA $94                      ; $15E2  85 94
        INY                          ; $15E4  C8
        LDA ($5E),Y                  ; $15E5  B1 5E
        ADC $95                      ; $15E7  65 95
        STA $95                      ; $15E9  85 95
        PLP                          ; $15EB  28
        BPL $15C1                    ; $15EC  10 D3
        TXA                          ; $15EE  8A
        BMI $15C1                    ; $15EF  30 D0
        LDX $1C                      ; $15F1  A6 1C
        LDX $1B                      ; $15F3  A6 1B
        LDX $1A                      ; $15F5  A6 1A
        .byte   $80, $1A                            ; $15F7  (undocumented opcode -- ca65 cannot encode)
        ADC $5E                      ; $15F9  65 5E
        STA $5E                      ; $15FB  85 5E
        BCC $1601                    ; $15FD  90 02
        .byte   $E6                                 ; $15FF  (partial instruction at the text boundary)

; -- $1600-$18FF: 6502 assembly-source LISTING (high-bit Apple text) --
; -- charmap: printable ASCII -> high-bit Apple text (so the listing
;    below reads as plain strings yet assembles with bit 7 set) --
.charmap $20, $A0
.charmap $21, $A1
.charmap $22, $A2
.charmap $23, $A3
.charmap $24, $A4
.charmap $25, $A5
.charmap $26, $A6
.charmap $27, $A7
.charmap $28, $A8
.charmap $29, $A9
.charmap $2A, $AA
.charmap $2B, $AB
.charmap $2C, $AC
.charmap $2D, $AD
.charmap $2E, $AE
.charmap $2F, $AF
.charmap $30, $B0
.charmap $31, $B1
.charmap $32, $B2
.charmap $33, $B3
.charmap $34, $B4
.charmap $35, $B5
.charmap $36, $B6
.charmap $37, $B7
.charmap $38, $B8
.charmap $39, $B9
.charmap $3A, $BA
.charmap $3B, $BB
.charmap $3C, $BC
.charmap $3D, $BD
.charmap $3E, $BE
.charmap $3F, $BF
.charmap $40, $C0
.charmap $41, $C1
.charmap $42, $C2
.charmap $43, $C3
.charmap $44, $C4
.charmap $45, $C5
.charmap $46, $C6
.charmap $47, $C7
.charmap $48, $C8
.charmap $49, $C9
.charmap $4A, $CA
.charmap $4B, $CB
.charmap $4C, $CC
.charmap $4D, $CD
.charmap $4E, $CE
.charmap $4F, $CF
.charmap $50, $D0
.charmap $51, $D1
.charmap $52, $D2
.charmap $53, $D3
.charmap $54, $D4
.charmap $55, $D5
.charmap $56, $D6
.charmap $57, $D7
.charmap $58, $D8
.charmap $59, $D9
.charmap $5A, $DA
.charmap $5B, $DB
.charmap $5C, $DC
.charmap $5D, $DD
.charmap $5E, $DE
.charmap $5F, $DF
.charmap $60, $E0
.charmap $61, $E1
.charmap $62, $E2
.charmap $63, $E3
.charmap $64, $E4
.charmap $65, $E5
.charmap $66, $E6
.charmap $67, $E7
.charmap $68, $E8
.charmap $69, $E9
.charmap $6A, $EA
.charmap $6B, $EB
.charmap $6C, $EC
.charmap $6D, $ED
.charmap $6E, $EE
.charmap $6F, $EF
.charmap $70, $F0
.charmap $71, $F1
.charmap $72, $F2
.charmap $73, $F3
.charmap $74, $F4
.charmap $75, $F5
.charmap $76, $F6
.charmap $77, $F7
.charmap $78, $F8
.charmap $79, $F9
.charmap $7A, $FA
.charmap $7B, $FB
.charmap $7C, $FC
.charmap $7D, $FD
.charmap $7E, $FE

        .byte   "IT ", $8D                           ; $1600
        .byte   " DEY ", $8D                         ; $1604
        .byte   " BNE DLYLP", $8D                    ; $160A
        .byte   " LDX SLOT", $8D                     ; $1615
        .byte   "SAMEDRV LDA A.TRK", $8D             ; $161F
        .byte   " JSR MYSEEK", $8D                   ; $1631
        .byte   " PLP ", $8D                         ; $163D
        .byte   " BNE TRYTRK ", $8D                  ; $1643
        .byte   "MOTOF LDY #$12", $8D                ; $1650
        .byte   " DEY ", $8D                         ; $165F
        .byte   " BNE *-1", $8D                      ; $1665
        .byte   " INC MONTIME", $8D                  ; $166E
        .byte   " BNE MOTOF", $8D                    ; $167B
        .byte   " INC MONTIME+1", $8D                ; $1686
        .byte   " BNE MOTOF", $8D                    ; $1695
        .byte   "TRYTRK EQU *", $8D                  ; $16A0
        .byte   " LDA A.CMD", $8D                    ; $16AD
        .byte   " BEQ GALLDONE", $8D                 ; $16B8
        .byte   " ROR ", $8D                         ; $16C6
        .byte   " PHP ", $8D                         ; $16CC
        .byte   " BCS TRYTRK2 ", $8D                 ; $16D2
        .byte   " JSR PRENIBL", $8D                  ; $16E0
        .byte   "TRYTRK2 LDY #$30", $8D              ; $16ED
        .byte   " STY RETRYCNT", $8D                 ; $16FE
        .byte   "TRYADR LDX SLOT", $8D               ; $170C
        .byte   " JSR RDADR", $8D                    ; $171C
        .byte   " BCC RDRIGHT", $8D                  ; $1727
        .byte   "TRYADR2 DEC RETRYCNT ", $8D         ; $1734
        .byte   " BPL TRYADR ", $8D                  ; $174A
        .byte   "GOCAL LDA CURTRK", $8D              ; $1757
        .byte   " PHA ", $8D                         ; $1768
        .byte   " LDA #$60", $8D                     ; $176E
        .byte   " JSR SETTRK", $8D                   ; $1778
        .byte   " DEC RECALCNT", $8D                 ; $1784
        .byte   " BEQ DRVERR", $8D                   ; $1792
        .byte   " LDA #4", $8D                       ; $179E
        .byte   " STA DRV1TRK", $8D                  ; $17A6
        .byte   " LDA #0", $8D                       ; $17B3
        .byte   " JSR MYSEEK", $8D                   ; $17BB
        .byte   " PLA ", $8D                         ; $17C7
        .byte   "TRYADR3 JSR MYSEEK", $8D            ; $17CD
        .byte   " JMP TRYTRK2", $8D                  ; $17E0
        .byte   "RDRIGHT LDY TRACK", $8D             ; $17ED
        .byte   " CPY CURTRK", $8D                   ; $17FF
        .byte   " BEQ RTTRK ", $8D                   ; $180B
        .byte   " LDA CURTRK", $8D                   ; $1817
        .byte   " PHA ", $8D                         ; $1823
        .byte   " TYA ", $8D                         ; $1829
        .byte   " JSR SETTRK", $8D                   ; $182F
        .byte   " PLA ", $8D                         ; $183B
        .byte   " DEC SEEKCNT", $8D                  ; $1841
        .byte   " BNE TRYADR3", $8D                  ; $184E
        .byte   " BEQ GOCAL", $8D                    ; $185B
        .byte   "DRVERR PLA ", $8D                   ; $1866
        .byte   " LDA #$40", $8D                     ; $1872
        .byte   "JMPTO1 PLP ", $8D                   ; $187C
        .byte   " JMP HNDLERR", $8D                  ; $1888
        .byte   "GALLDONE BEQ ALLDONE", $8D          ; $1895
        .byte   "RTTRK LDA A.VOL", $8D               ; $18AA
        .byte   " PHA ", $8D                         ; $18BA
        .byte   " LDA VOLUME", $8D                   ; $18C0
        .byte   " STA A.OVOL", $8D                   ; $18CC
        .byte   " PLA ", $8D                         ; $18D8
        .byte   " BEQ CRECTVOL", $8D                 ; $18DE
        .byte   " CMP VOLUME", $8D                   ; $18EC
        .byte   " BEQ CRE"                        ; $18F8
