; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- BIOS, RUNTIME-ADDRESSED (de-skewed)
; ----------------------------------------------------------------------------
; The 2.23-44K BIOS runs at z80 $FA00-$FFFF (6 pages) = Apple $0A00-$0FFF LOW RAM
; (NOT $AA00 like 2.20 -- a different mechanism). Decoded against the de-skewed
; runtime image; the disk producer re-applies the sector skew (deskew.py ::
; BIOS_PAGE_TO_SECTOR_223). $FA00 = the 15-entry BIOS jump vector.
; DECODE IN PROGRESS: --auto-coverage --relocatable disassembly (byte-identical),
; being enriched to the C-level bar.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ORG $FA00
    ENDIF

L_FA00:
        JP SUB_FE85_5                    ; $FA00  C3 D1 FE
L_FA03:
        ; jump table
        JP      SUB_FAB1_1               ; $FA03
        JP      SUB_FAB1_5               ; $FA06
        JP      SUB_FAB1_7               ; $FA09
        JP      $FB4D                    ; $FA0C
        JP      SUB_FB5A_4               ; $FA0F
        JP      SUB_FB5A_5               ; $FA12
        JP      SUB_FB5A_6               ; $FA15
        JP      SUB_FDB0_2               ; $FA18
        JP      SUB_FE85_1               ; $FA1B
        JP      $FE77                    ; $FA1E
        JP      SUB_FBF0_1               ; $FA21
        JP      SUB_FBF9                 ; $FA24
        JP      SUB_FE85_3               ; $FA27
        JP      SUB_FE85_4               ; $FA2A
        DEFB    $AF,$C9,$00,$60,$69,$C9                          ; $FA2D
L_FA33:
        DEFS    8, $00    ; $FA33  fill
        DEFB    $E4,$FE,$73,$FA,$AC,$FF,$64,$FF                  ; $FA3B
        DEFS    8, $00    ; $FA43  fill
        DEFB    $E4,$FE,$73,$FA,$B8,$FF,$76,$FF                  ; $FA4B
        DEFS    8, $00    ; $FA53  fill
        DEFB    $E4,$FE,$73,$FA,$C4,$FF,$88,$FF                  ; $FA5B
        DEFS    8, $00    ; $FA63  fill
        DEFB    $E4,$FE,$73,$FA,$D0,$FF,$9A,$FF,$20,$00,$03,$07,$00,$8B,$00,$2F ; $FA6B
        DEFB    $00,$C0,$00,$0C,$00,$03,$00                      ; $FA7B
SUB_FA82:
        LD DE,$0007                      ; $FA82  11 07 00
SUB_FA82_1:
        LD HL,$F3B8                      ; $FA85  21 B8 F3
        ADD HL,DE                        ; $FA88  19
        LD A,(HL)                        ; $FA89  7E
        SUB $03                          ; $FA8A  D6 03
        JR NZ,SUB_FA82_2                 ; $FA8C  20 07
        CALL SUB_FE81                    ; $FA8E  CD 81 FE
        LD (HL),$03                      ; $FA91  36 03
        LD (HL),$15                      ; $FA93  36 15
SUB_FA82_2:
        DEC A                            ; $FA95  3D
        JR NZ,SUB_FA82_3                 ; $FA96  20 0B
        CALL SUB_FD83                    ; $FA98  CD 83 FD
        LD HL,$C800                      ; $FA9B  21 00 C8
        CALL SUB_FB45                    ; $FA9E  CD 45 FB
        JR SUB_FA82_4                    ; $FAA1  18 0A
SUB_FA82_3:
        CP $02                           ; $FAA3  FE 02
        JR NZ,SUB_FA82_4                 ; $FAA5  20 06
        LD HL,$0DD0                      ; $FAA7  21 D0 0D
        CALL SUB_FDB0                    ; $FAAA  CD B0 FD
SUB_FA82_4:
        DEC E                            ; $FAAD  1D
        JR NZ,SUB_FA82_1                 ; $FAAE  20 D5
        RET                              ; $FAB0  C9
SUB_FAB1:
        LD HL,$E000                      ; $FAB1  21 00 E0
        LD A,E                           ; $FAB4  7B
        OR H                             ; $FAB5  B4
        LD H,A                           ; $FAB6  67
        RET                              ; $FAB7  C9
SUB_FAB1_1:
        LD SP,$0080                      ; $FAB8  31 80 00
        LD A,($E051)                     ; $FABB  3A 51 E0
        LD HL,$0E00                      ; $FABE  21 00 0E
        CALL SUB_FB45                    ; $FAC1  CD 45 FB
        CALL SUB_FA82                    ; $FAC4  CD 82 FA
        LD A,($9C08)                     ; $FAC7  3A 08 9C
        CP $9C                           ; $FACA  FE 9C
        JR Z,SUB_FAB1_2                  ; $FACC  28 11
        LD HL,SUB_FE85_19                ; $FACE  21 59 FF
        LD ($F3D0),HL                    ; $FAD1  22 D0 F3
        LD HL,($F3DE)                    ; $FAD4  2A DE F3
        LD A,$77                         ; $FAD7  3E 77
        LD ($000B),A                     ; $FAD9  32 0B 00
        JP $000B                         ; $FADC  C3 0B 00
SUB_FAB1_2:
        XOR A                            ; $FADF  AF
        LD ($9307),A                     ; $FAE0  32 07 93
SUB_FAB1_3:
        XOR A                            ; $FAE3  AF
        LD (SUB_FE85_10),A               ; $FAE4  32 DD FE
        LD (SUB_FE85_8),A                ; $FAE7  32 D8 FE
        LD A,$C3                         ; $FAEA  3E C3
        LD ($0000),A                     ; $FAEC  32 00 00
        LD HL,L_FA03                     ; $FAEF  21 03 FA
        LD ($0001),HL                    ; $FAF2  22 01 00
        LD ($0005),A                     ; $FAF5  32 05 00
        LD HL,$9C06                      ; $FAF8  21 06 9C
        LD ($0006),HL                    ; $FAFB  22 06 00
        LD BC,$0080                      ; $FAFE  01 80 00
        CALL SUB_FBF9                    ; $FB01  CD F9 FB
SUB_FAB1_4:
        LD A,$01                         ; $FB04  3E 01
        LD ($974E),A                     ; $FB06  32 4E 97
        LD A,($0004)                     ; $FB09  3A 04 00
        LD C,A                           ; $FB0C  4F
        JP $9300                         ; $FB0D  C3 00 93
SUB_FAB1_5:
        LD HL,($F380)                    ; $FB10  2A 80 F3
        JP (HL)                          ; $FB13  E9
SUB_FAB1_6:
        LD A,($E000)                     ; $FB14  3A 00 E0
        RLA                              ; $FB17  17
        SBC A,A                          ; $FB18  9F
        RET                              ; $FB19  C9
SUB_FAB1_7:
        CALL SUB_FB5A                    ; $FB1A  CD 5A FB
        AND $7F                          ; $FB1D  E6 7F
        LD HL,$F3AB                      ; $FB1F  21 AB F3
        LD B,$06                         ; $FB22  06 06
        LD C,A                           ; $FB24  4F
SUB_FAB1_8:
        INC HL                           ; $FB25  23
        LD A,(HL)                        ; $FB26  7E
        INC HL                           ; $FB27  23
        OR A                             ; $FB28  B7
        JP M,SUB_FAB1_9                  ; $FB29  FA 31 FB
        CP C                             ; $FB2C  B9
        LD A,(HL)                        ; $FB2D  7E
        RET Z                            ; $FB2E  C8
        DJNZ SUB_FAB1_8                  ; $FB2F  10 F4
SUB_FAB1_9:
        LD A,C                           ; $FB31  79
        RET                              ; $FB32  C9
SUB_FAB1_10:
        LD DE,$0003                      ; $FB33  11 03 00
SUB_FAB1_11:
        JP SUB_FAB1_12                   ; $FB36  C3 39 FB
SUB_FAB1_12:
        LD A,($E000)                     ; $FB39  3A 00 E0
        RLA                              ; $FB3C  17
        JR NC,SUB_FAB1_12                ; $FB3D  30 FA
        LD ($E010),A                     ; $FB3F  32 10 E0
        CCF                              ; $FB42  3F
        RRA                              ; $FB43  1F
        RET                              ; $FB44  C9
SUB_FB45:
        LD ($F3D0),HL                    ; $FB45  22 D0 F3
SUB_FB45_1:
        LD ($0000),A                     ; $FB48  32 00 00
        RET                              ; $FB4B  C9
SUB_FB4C:
        LD C,A                           ; $FB4C  4F
        LD A,($0003)                     ; $FB4D  3A 03 00
        AND $03                          ; $FB50  E6 03
        CP $02                           ; $FB52  FE 02
        JR NZ,SUB_FB5A_8                 ; $FB54  20 4B
SUB_FB4C_1:
        LD HL,($F392)                    ; $FB56  2A 92 F3
        JP (HL)                          ; $FB59  E9
SUB_FB5A:
        LD A,($0003)                     ; $FB5A  3A 03 00
        AND $03                          ; $FB5D  E6 03
        CP $02                           ; $FB5F  FE 02
        LD HL,($F384)                    ; $FB61  2A 84 F3
        JR Z,SUB_FB5A_2                  ; $FB64  28 06
        JR NC,SUB_FB5A_3                 ; $FB66  30 07
SUB_FB5A_1:
        LD HL,($F382)                    ; $FB68  2A 82 F3
        JP (HL)                          ; $FB6B  E9
SUB_FB5A_2:
        LD HL,($F38A)                    ; $FB6C  2A 8A F3
SUB_FB5A_3:
        JP (HL)                          ; $FB6F  E9
SUB_FB5A_4:
        LD A,($0003)                     ; $FB70  3A 03 00
        AND $C0                          ; $FB73  E6 C0
        CP $80                           ; $FB75  FE 80
        JR C,SUB_FB5A_7                  ; $FB77  38 27
        JR Z,SUB_FB4C_1                  ; $FB79  28 DB
        LD HL,($F394)                    ; $FB7B  2A 94 F3
        JP (HL)                          ; $FB7E  E9
SUB_FB5A_5:
        LD A,($0003)                     ; $FB7F  3A 03 00
        AND $30                          ; $FB82  E6 30
        CP $10                           ; $FB84  FE 10
        JR C,SUB_FB5A_7                  ; $FB86  38 18
        LD HL,($F38E)                    ; $FB88  2A 8E F3
        JR Z,SUB_FB5A_3                  ; $FB8B  28 E2
        LD HL,($F390)                    ; $FB8D  2A 90 F3
        JP (HL)                          ; $FB90  E9
SUB_FB5A_6:
        LD A,($0003)                     ; $FB91  3A 03 00
        AND $0C                          ; $FB94  E6 0C
        CP $08                           ; $FB96  FE 08
        JR C,SUB_FB5A_1                  ; $FB98  38 CE
        JR Z,SUB_FB5A_2                  ; $FB9A  28 D0
        LD HL,($F38C)                    ; $FB9C  2A 8C F3
        JP (HL)                          ; $FB9F  E9
SUB_FB5A_7:
        SCF                              ; $FBA0  37
SUB_FB5A_8:
        SBC A,A                          ; $FBA1  9F
        LD HL,$F3A2                      ; $FBA2  21 A2 F3
        LD L,(HL)                        ; $FBA5  6E
        INC L                            ; $FBA6  2C
        JP Z,SUB_FCA4                    ; $FBA7  CA A4 FC
        LD HL,L_FECB                     ; $FBAA  21 CB FE
        LD (HL),A                        ; $FBAD  77
        RES 7,C                          ; $FBAE  CB B9
        INC HL                           ; $FBB0  23
        LD A,(HL)                        ; $FBB1  7E
        OR A                             ; $FBB2  B7
        JP Z,SUB_FBF9_1                  ; $FBB3  CA 56 FC
        DEC (HL)                         ; $FBB6  35
        LD A,($F396)                     ; $FBB7  3A 96 F3
        LD HL,SUB_FE85_6                 ; $FBBA  21 D4 FE
        JR Z,SUB_FBC4_2                  ; $FBBD  28 0C
        OR A                             ; $FBBF  B7
        JP P,SUB_FBC4_1                  ; $FBC0  F2 C6 FB
        DEC HL                           ; $FBC3  2B
SUB_FBC4:
        AND $7F                          ; $FBC4  E6 7F
SUB_FBC4_1:
        LD E,A                           ; $FBC6  5F
        LD A,C                           ; $FBC7  79
        SUB E                            ; $FBC8  93
        LD (HL),A                        ; $FBC9  77
        RET                              ; $FBCA  C9
SUB_FBC4_2:
        OR A                             ; $FBCB  B7
        JP M,SUB_FBC4_3                  ; $FBCC  FA D0 FB
        DEC HL                           ; $FBCF  2B
SUB_FBC4_3:
        CALL SUB_FBC4                    ; $FBD0  CD C4 FB
        LD HL,(SUB_FE85_5+2)             ; $FBD3  2A D3 FE
        LD A,($F3A1)                     ; $FBD6  3A A1 F3
        OR A                             ; $FBD9  B7
        JP P,SUB_FBC4_4                  ; $FBDA  F2 E2 FB
        AND $7F                          ; $FBDD  E6 7F
        LD E,L                           ; $FBDF  5D
        LD L,H                           ; $FBE0  6C
        LD H,E                           ; $FBE1  63
SUB_FBC4_4:
        LD E,A                           ; $FBE2  5F
        ADD A,H                          ; $FBE3  84
        LD C,A                           ; $FBE4  4F
        LD A,E                           ; $FBE5  7B
        ADD A,L                          ; $FBE6  85
        PUSH AF                          ; $FBE7  F5
        LD B,$07                         ; $FBE8  06 07
        CALL SUB_FCA4                    ; $FBEA  CD A4 FC
        POP AF                           ; $FBED  F1
        LD B,$0A                         ; $FBEE  06 0A
SUB_FBF0:
        LD C,A                           ; $FBF0  4F
        JP SUB_FCA4                      ; $FBF1  C3 A4 FC
SUB_FBF0_1:
        LD A,C                           ; $FBF4  79
        LD (SUB_FE85_5+1),A              ; $FBF5  32 D2 FE
        RET                              ; $FBF8  C9
SUB_FBF9:
        LD (SUB_FE85_11+2),BC            ; $FBF9  ED 43 E1 FE
        RET                              ; $FBFD  C9
        DEFS    88, $00    ; $FBFE  fill
SUB_FBF9_1:
        LD B,A                           ; $FC56  47
        LD HL,L_FECD                     ; $FC57  21 CD FE
        LD A,(HL)                        ; $FC5A  7E
        LD E,A                           ; $FC5B  5F
        OR A                             ; $FC5C  B7
        JR NZ,SUB_FBF9_3                 ; $FC5D  20 12
        LD A,($F397)                     ; $FC5F  3A 97 F3
        OR A                             ; $FC62  B7
        JR Z,SUB_FBF9_2                  ; $FC63  28 06
        CP C                             ; $FC65  B9
        JR NZ,SUB_FBF9_2                 ; $FC66  20 03
        LD (HL),$80                      ; $FC68  36 80
        RET                              ; $FC6A  C9
SUB_FBF9_2:
        LD A,$1F                         ; $FC6B  3E 1F
        CP C                             ; $FC6D  B9
        JP C,SUB_FCA4                    ; $FC6E  DA A4 FC
SUB_FBF9_3:
        LD HL,$F3A0                      ; $FC71  21 A0 F3
        LD B,$09                         ; $FC74  06 09
SUB_FBF9_4:
        LD A,(HL)                        ; $FC76  7E
        OR A                             ; $FC77  B7
        JR Z,SUB_FBF9_5                  ; $FC78  28 04
        XOR E                            ; $FC7A  AB
        CP C                             ; $FC7B  B9
        JR Z,SUB_FBF9_6                  ; $FC7C  28 05
SUB_FBF9_5:
        DEC HL                           ; $FC7E  2B
        DJNZ SUB_FBF9_4                  ; $FC7F  10 F5
        JR SUB_FCA4                      ; $FC81  18 21
SUB_FBF9_6:
        LD DE,$000B                      ; $FC83  11 0B 00
        ADD HL,DE                        ; $FC86  19
        LD A,(HL)                        ; $FC87  7E
        OR A                             ; $FC88  B7
        LD C,A                           ; $FC89  4F
        JP P,SUB_FBF9_7                  ; $FC8A  F2 9A FC
        AND $7F                          ; $FC8D  E6 7F
        LD C,A                           ; $FC8F  4F
        PUSH BC                          ; $FC90  C5
        LD A,($F3A2)                     ; $FC91  3A A2 F3
        LD B,$07                         ; $FC94  06 07
        CALL SUB_FBF0                    ; $FC96  CD F0 FB
        POP BC                           ; $FC99  C1
SUB_FBF9_7:
        LD A,B                           ; $FC9A  78
        CP $07                           ; $FC9B  FE 07
        JR NZ,SUB_FCA4                   ; $FC9D  20 05
        LD A,$02                         ; $FC9F  3E 02
        LD (L_FECC),A                    ; $FCA1  32 CC FE
SUB_FCA4:
        XOR A                            ; $FCA4  AF
        LD (L_FECD),A                    ; $FCA5  32 CD FE
        LD A,(L_FECB)                    ; $FCA8  3A CB FE
        OR A                             ; $FCAB  B7
        LD HL,($F388)                    ; $FCAC  2A 88 F3
        JR Z,SUB_FCA4_1                  ; $FCAF  28 03
        LD HL,($F386)                    ; $FCB1  2A 86 F3
SUB_FCA4_1:
        JP (HL)                          ; $FCB4  E9
SUB_FCA4_2:
        LD DE,$0003                      ; $FCB5  11 03 00
SUB_FCA4_3:
        JP SUB_FCA4_4                    ; $FCB8  C3 BB FC
SUB_FCA4_4:
        LD HL,(L_FECE)                   ; $FCBB  2A CE FE
        LD A,(L_FED0)                    ; $FCBE  3A D0 FE
        LD (HL),A                        ; $FCC1  77
        CALL SUB_FCE2                    ; $FCC2  CD E2 FC
        LD HL,($F028)                    ; $FCC5  2A 28 F0
        LD A,($F024)                     ; $FCC8  3A 24 F0
        LD E,A                           ; $FCCB  5F
        LD D,$F0                         ; $FCCC  16 F0
        ADD HL,DE                        ; $FCCE  19
        LD (L_FECE),HL                   ; $FCCF  22 CE FE
        LD A,(HL)                        ; $FCD2  7E
        LD (L_FED0),A                    ; $FCD3  32 D0 FE
        CP $E0                           ; $FCD6  FE E0
        JR C,SUB_FCA4_5                  ; $FCD8  38 02
        XOR $20                          ; $FCDA  EE 20
SUB_FCA4_5:
        AND $3F                          ; $FCDC  E6 3F
        OR $40                           ; $FCDE  F6 40
        LD (HL),A                        ; $FCE0  77
        RET                              ; $FCE1  C9
SUB_FCE2:
        LD A,B                           ; $FCE2  78
        OR A                             ; $FCE3  B7
        JR Z,L_FCF1                      ; $FCE4  28 0B
        LD HL,SUB_FB45                   ; $FCE6  21 45 FB
        PUSH HL                          ; $FCE9  E5
        LD HL,L_FD66                     ; $FCEA  21 66 FD
        ADD A,L                          ; $FCED  85
        DEFB    $6F,$6E,$E9                                      ; $FCEE
L_FCF1:
        DEFB    $79,$FE,$0D,$20,$05                              ; $FCF1
        DEFB    $AF,$32,$24,$F0,$C9,$F6,$80                      ; $FCF6  "/2$pIv"
        DEFB    $FE,$E0,$38,$04                                  ; $FCFD
        DEFB    $21,$DD,$F3,$AE,$32,$45,$F0,$21,$F0,$FD,$C3,$80  ; $FD01  "!]s.2Ep!p}C"
        DEFB    $FD,$CD,$81,$FE,$C6,$8F                          ; $FD0D
        DEFB    $CB,$4E,$28,$FC,$21,$2F,$F0,$36,$60,$2B,$36,$C0,$2B,$77,$2B,$36 ; $FD13  "KN(|!/p6`+6@+w+6"
        DEFB    $8D                                              ; $FD23
        DEFB    $62,$C3,$7C,$FD,$3E,$FF,$01,$3E,$3F,$32,$32,$F0,$E1,$C9,$21,$F4 ; $FD24
        DEFB    $FB,$C9,$AF,$6F,$67,$22,$24,$F0,$32,$45,$F0,$21,$C1,$FB,$C9,$2E ; $FD34
        DEFB    $42,$01,$2E,$9C,$01,$2E,$1A,$01,$2E,$58,$26,$FC,$C9,$2A,$D3,$FE ; $FD44
        DEFB    $7D,$FE,$28,$38,$02,$2E,$00,$7C,$FE,$18,$38,$02,$26,$00,$22,$24 ; $FD54
        DEFB    $F0,$18                                          ; $FD64
L_FD66:
        DEFB    $D5,$4C,$43,$46,$28,$2B,$36,$30,$49,$32,$51,$CD  ; $FD66  "ULCF(+60I2QM"
        DEFB    $83,$FD,$21,$78,$F6,$19,$71,$21,$AA,$C9,$79,$32,$45,$F0,$C3,$45 ; $FD72
        DEFB    $FB                                              ; $FD82
SUB_FD83:
        CALL SUB_FE7C                    ; $FD83  CD 7C FE
        LD ($F6F8),A                     ; $FD86  32 F8 F6
        LD ($F047),A                     ; $FD89  32 47 F0
        LD A,($EFFF)                     ; $FD8C  3A FF EF
        CALL SUB_FAB1                    ; $FD8F  CD B1 FA
        SUB $20                          ; $FD92  D6 20
        LD ($F046),A                     ; $FD94  32 46 F0
        LD A,(HL)                        ; $FD97  7E
        RET                              ; $FD98  C9
SUB_FD83_1:
        LD HL,$0E14                      ; $FD99  21 14 0E
        LD E,$03                         ; $FD9C  1E 03
        LD A,$01                         ; $FD9E  3E 01
        CALL SUB_FDAD                    ; $FDA0  CD AD FD
        LD A,($F048)                     ; $FDA3  3A 48 F0
        RRA                              ; $FDA6  1F
        SBC A,A                          ; $FDA7  9F
        RET                              ; $FDA8  C9
        DEFB    $21,$E1,$0D,$79                                  ; $FDA9
SUB_FDAD:
        LD ($F045),A                     ; $FDAD  32 45 F0
SUB_FDB0:
        LD A,E                           ; $FDB0  7B
        LD ($F047),A                     ; $FDB1  32 47 F0
        JP SUB_FB45                      ; $FDB4  C3 45 FB
SUB_FDB0_1:
        LD HL,$0E06                      ; $FDB7  21 06 0E
        CALL SUB_FDB0                    ; $FDBA  CD B0 FD
        LD A,($F045)                     ; $FDBD  3A 45 F0
        RET                              ; $FDC0  C9
        DEFB    $CD,$83,$FD,$21,$4D,$C8,$CD,$45,$FB,$21,$78,$F6,$19,$7E,$C9,$48 ; $FDC1
        DEFB    $20,$1D,$0E,$A0,$0D,$B1,$F6,$85,$F6,$AC,$F8,$06,$68,$6C,$F6,$00 ; $FDD1
        DEFB    $48,$A9,$00,$20,$EF,$0D,$20,$1D,$0E,$A0,$0F,$4C,$D6,$0D,$84,$F5 ; $FDE1
        DEFB    $48,$20,$14,$0E,$68,$A4,$F5,$90,$F5,$60,$00,$00,$00,$00,$00,$4C ; $FDF1
        DEFB    $E9,$BB,$4C,$04,$BE,$A9,$01,$20,$EF,$0D,$20,$1D,$0E,$48,$A0,$0E ; $FE01
        DEFB    $4C,$D6,$0D,$48,$20,$1D,$0E,$A0,$10,$4C,$D6,$0D,$98,$09,$C0,$AA ; $FE11
        DEFB    $98,$0A,$0A,$0A,$0A,$A8,$8C,$F8,$06,$A9,$00,$85,$F6,$86,$F7,$AD ; $FE21
        DEFB    $FF,$CF,$B1,$F6,$60,$A5,$48,$48,$A5,$45,$A6,$46,$A4,$47,$28,$58 ; $FE31
        DEFB    $60,$CD,$81,$FE,$7E,$1F,$30,$FC,$2C,$7E,$C9,$11,$01,$00,$C3 ; $FE41
L_FE50:
        DEFB    $5F,$FE,$CD,$B1,$FA,$2E,$C1,$7E,$17,$38,$FC,$CD,$7C,$FE,$71,$C9 ; $FE50
        DEFB    $11,$02,$00,$C3                                  ; $FE60
L_FE64:
        DEFB    $5F,$FE,$11,$02,$00                              ; $FE64
L_FE69:
        DEFB    $C3                                              ; $FE69
L_FE6A:
        DEFB    "\0"    ; $FE6A
L_FE6B:
        DEFB    "\0"    ; $FE6B
SUB_FDB0_2:
        LD A,(SUB_FE85_9)                ; $FE6C  3A D9 FE
        OR A                             ; $FE6F  B7
        JR NZ,SUB_FDB0_3                 ; $FE70  20 03
        LD (SUB_FE85_8),A                ; $FE72  32 D8 FE
SUB_FDB0_3:
        LD C,$00                         ; $FE75  0E 00
        LD A,C                           ; $FE77  79
        LD (SUB_FE85_5),A                ; $FE78  32 D1 FE
        RET                              ; $FE7B  C9
SUB_FE7C:
        LD HL,$E080                      ; $FE7C  21 80 E0
        JR SUB_FE81_1                    ; $FE7F  18 03
SUB_FE81:
        LD HL,$E08E                      ; $FE81  21 8E E0
SUB_FE81_1:
        LD A,E                           ; $FE84  7B
SUB_FE85:
        ADD A,A                          ; $FE85  87
        ADD A,A                          ; $FE86  87
        ADD A,A                          ; $FE87  87
        ADD A,A                          ; $FE88  87
        PUSH AF                          ; $FE89  F5
        ADD A,L                          ; $FE8A  85
        LD L,A                           ; $FE8B  6F
        POP AF                           ; $FE8C  F1
        RET                              ; $FE8D  C9
SUB_FE85_1:
        LD DE,SUB_FE85_7                 ; $FE8E  11 D5 FE
        LD HL,$0004                      ; $FE91  21 04 00
        LD A,($F3B8)                     ; $FE94  3A B8 F3
        DEC A                            ; $FE97  3D
        CP C                             ; $FE98  B9
        JR C,SUB_FE85_2                  ; $FE99  38 1D
        LD A,(HL)                        ; $FE9B  7E
        LD (DE),A                        ; $FE9C  12
        INC DE                           ; $FE9D  13
        LD A,C                           ; $FE9E  79
        LD (DE),A                        ; $FE9F  12
        LD HL,L_FA33                     ; $FEA0  21 33 FA
        CALL SUB_FE85                    ; $FEA3  CD 85 FE
        PUSH HL                          ; $FEA6  E5
        LD DE,$000A                      ; $FEA7  11 0A 00
        ADD HL,DE                        ; $FEAA  19
        LD E,(HL)                        ; $FEAB  5E
        INC HL                           ; $FEAC  23
        LD D,(HL)                        ; $FEAD  56
        LD HL,$0005                      ; $FEAE  21 05 00
        ADD HL,DE                        ; $FEB1  19
        LD A,(HL)                        ; $FEB2  7E
        LD (SUB_FE85_12+1),A             ; $FEB3  32 E3 FE
        POP HL                           ; $FEB6  E1
        RET                              ; $FEB7  C9
SUB_FE85_2:
        LD A,(DE)                        ; $FEB8  1A
        LD (HL),A                        ; $FEB9  77
        LD L,$00                         ; $FEBA  2E 00
        RET                              ; $FEBC  C9
SUB_FE85_3:
        JP $AC39                         ; $FEBD  C3 39 AC
SUB_FE85_4:
        JP $AC49                         ; $FEC0  C3 49 AC
        DEFB    $C3,$45,$FB,$2A,$0D                              ; $FEC3  "CE{*"
        DEFB    $9C,$E9,$C9                                      ; $FEC8
L_FECB:
        DEFB    "\0"    ; $FECB
L_FECC:
        DEFB    "\0"    ; $FECC
L_FECD:
        DEFB    "\0"    ; $FECD
L_FECE:
        DEFB    $D0,$FE                                          ; $FECE
L_FED0:
        DEFB    "\0"    ; $FED0
SUB_FE85_5:
        LD SP,$0100                      ; $FED1  31 00 01
SUB_FE85_6:
        XOR A                            ; $FED4  AF
SUB_FE85_7:
        LD HL,L_FA00                     ; $FED5  21 00 FA
SUB_FE85_8:
        LD (HL),A                        ; $FED8  77
SUB_FE85_9:
        INC HL                           ; $FED9  23
        LD (HL),A                        ; $FEDA  77
        INC HL                           ; $FEDB  23
        LD (HL),A                        ; $FEDC  77
SUB_FE85_10:
        LD A,$95                         ; $FEDD  3E 95
SUB_FE85_11:
        LD ($0003),A                     ; $FEDF  32 03 00
SUB_FE85_12:
        LD HL,($F3DE)                    ; $FEE2  2A DE F3
        LD (SUB_FB45_1+1),HL             ; $FEE5  22 49 FB
        XOR A                            ; $FEE8  AF
        LD ($0004),A                     ; $FEE9  32 04 00
        LD A,($F3BB)                     ; $FEEC  3A BB F3
        CP $06                           ; $FEEF  FE 06
        JR NZ,SUB_FE85_13                ; $FEF1  20 0A
        LD HL,SUB_FD83_1                 ; $FEF3  21 99 FD
        LD ($F380),HL                    ; $FEF6  22 80 F3
        SUB $03                          ; $FEF9  D6 03
        JR SUB_FE85_14                   ; $FEFB  18 13
SUB_FE85_13:
        CP $05                           ; $FEFD  FE 05
        JR Z,SUB_FE85_15                 ; $FEFF  28 22
        SUB $03                          ; $FF01  D6 03
        JR C,SUB_FE85_15                 ; $FF03  38 1E
        JR NZ,SUB_FE85_14                ; $FF05  20 09
        LD HL,SUB_FAB1_6+1               ; $FF07  21 15 FB
        LD (HL),$BE                      ; $FF0A  36 BE
        INC HL                           ; $FF0C  23
        INC HL                           ; $FF0D  23
        LD (HL),$1F                      ; $FF0E  36 1F
SUB_FE85_14:
        PUSH AF                          ; $FF10  F5
        CALL SUB_FF84                    ; $FF11  CD 84 FF
        POP AF                           ; $FF14  F1
        LD (SUB_FCA4_3+1),HL             ; $FF15  22 B9 FC
        CALL SUB_FE85_23+1               ; $FF18  CD 7F FF
        LD (SUB_FAB1_11+1),HL            ; $FF1B  22 37 FB
        LD A,$03                         ; $FF1E  3E 03
        LD (SUB_FAB1_4+1),A              ; $FF20  32 05 FB
SUB_FE85_15:
        LD A,($F3B9)                     ; $FF23  3A B9 F3
        SUB $03                          ; $FF26  D6 03
        JR C,SUB_FE85_16                 ; $FF28  38 06
        CALL SUB_FF84                    ; $FF2A  CD 84 FF
        LD (L_FE50),HL                   ; $FF2D  22 50 FE
SUB_FE85_16:
        LD A,($F3BA)                     ; $FF30  3A BA F3
        SUB $03                          ; $FF33  D6 03
        JR C,SUB_FE85_17                 ; $FF35  38 14
        PUSH AF                          ; $FF37  F5
        CALL SUB_FF84                    ; $FF38  CD 84 FF
        LD (L_FE64),HL                   ; $FF3B  22 64 FE
        POP AF                           ; $FF3E  F1
        CP $02                           ; $FF3F  FE 02
        JR Z,SUB_FE85_17                 ; $FF41  28 08
        CALL SUB_FE85_23+1               ; $FF43  CD 7F FF
        LD (L_FE6A),HL                   ; $FF46  22 6A FE
        JR SUB_FE85_18                   ; $FF49  18 0B
SUB_FE85_17:
        LD HL,$1A3E                      ; $FF4B  21 3E 1A
        LD (L_FE69),HL                   ; $FF4E  22 69 FE
        LD A,$C9                         ; $FF51  3E C9
        LD (L_FE6B),A                    ; $FF53  32 6B FE
SUB_FE85_18:
        CALL SUB_FA82                    ; $FF56  CD 82 FA
SUB_FE85_19:
        LD A,($F398)                     ; $FF59  3A 98 F3
        CALL SUB_FF8F                    ; $FF5C  CD 8F FF
        LD HL,L_FF9E                     ; $FF5F  21 9E FF
SUB_FE85_20:
        LD A,(HL)                        ; $FF62  7E
        OR A                             ; $FF63  B7
        JP Z,SUB_FAB1_3                  ; $FF64  CA E3 FA
        PUSH HL                          ; $FF67  E5
        CALL SUB_FB4C                    ; $FF68  CD 4C FB
        POP HL                           ; $FF6B  E1
        INC HL                           ; $FF6C  23
        JR SUB_FE85_20                   ; $FF6D  18 F3
SUB_FE85_21:
        LD C,$FD                         ; $FF6F  0E FD
        LD (HL),C                        ; $FF71  71
        DEFB $FD  ; ignored IY prefix; inner: LD D,D ; $FF72  FD 52
        LD D,D                           ; $FF73  52
        CP $A9                           ; $FF74  FE A9
        DEFB $FD  ; ignored IY prefix; inner: LD B,D ; $FF76  FD 42
SUB_FE85_22:
        LD B,D                           ; $FF77  42
        CP $C1                           ; $FF78  FE C1
        DEFB $FD  ; ignored IY prefix; inner: OR A ; $FF7A  FD B7
        OR A                             ; $FF7B  B7
        DEFB $FD  ; ignored IY prefix; inner: OR A ; $FF7C  FD B7
        OR A                             ; $FF7D  B7
SUB_FE85_23:
        LD IY,SUB_FE85_22                ; $FF7E  FD 21 77 FF
        JR SUB_FF84_1                    ; $FF82  18 03
SUB_FF84:
        LD HL,SUB_FE85_21                ; $FF84  21 6F FF
SUB_FF84_1:
        ADD A,A                          ; $FF87  87
        ADD A,L                          ; $FF88  85
        LD L,A                           ; $FF89  6F
        LD A,(HL)                        ; $FF8A  7E
        INC L                            ; $FF8B  2C
        LD H,(HL)                        ; $FF8C  66
        LD L,A                           ; $FF8D  6F
        RET                              ; $FF8E  C9
SUB_FF8F:
        OR A                             ; $FF8F  B7
        JP P,SUB_FF8F_1                  ; $FF90  F2 9B FF
        PUSH AF                          ; $FF93  F5
        LD A,($F397)                     ; $FF94  3A 97 F3
        CALL SUB_FB4C                    ; $FF97  CD 4C FB
        POP AF                           ; $FF9A  F1
SUB_FF8F_1:
        JP SUB_FB4C                      ; $FF9B  C3 4C FB
L_FF9E:
        DEFB    "\r\n\n\n"    ; $FF9E
        DEFB    "     Softcard CP/M"    ; $FFA2  string
        DEFB    $0D    ; $FFB4  terminator
        DEFB    "\n"    ; $FFB5
        DEFB    "     44K Ver. 2.23"    ; $FFB6  string
        DEFB    $0D    ; $FFC8  terminator
        DEFB    "\n"    ; $FFC9
        DEFB    "(c) 1980,1982 Microsoft"    ; $FFCA  string
        DEFB    $0D    ; $FFE1  terminator
        DEFB    $0A,$0D,$0A,$00,$FA,$E5,$CD,$4C,$FB,$E1,$23,$18,$F3,$0E,$FD,$71 ; $FFE2
        DEFB    $FD,$52,$FE,$A9,$FD,$42,$FE,$C1,$FD,$B7,$FD,$B7,$FD,$21 ; $FFF2

    SAVEBIN "E:/tmp/cpm223_bios_rt.bin", $FA00, $0600
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $FA00, $0600
    ENDIF
