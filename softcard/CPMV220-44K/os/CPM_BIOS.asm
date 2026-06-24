; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- BIOS, RUNTIME-ADDRESSED (de-skewed)
; ----------------------------------------------------------------------------
; The 44K BIOS runs at z80 $AA00-$AFFF (6 pages). The prior CPM_BIOS.asm decoded
; it in on-disk (sector-interleaved) order and was both mis-addressed (28.9%
; source-vs-runtime match) AND missing the 6th page; this source is decoded
; against the DE-SKEWED runtime image -- every label a true runtime address. The
; disk producer re-applies the sector skew (cpm_pipeline/deskew.py ::
; BIOS_PAGE_TO_SECTOR). $AA00 = the 15-entry BIOS jump vector (BOOT, WBOOT,
; CONST, CONIN, CONOUT, LIST, PUNCH, READER, HOME, SELDSK, SETTRK, SETSEC,
; SETDMA, READ, WRITE). See ../../docs/CPM_Skew_Findings.md.
;
; DECODE IN PROGRESS: --auto-coverage --relocatable disassembly (byte-identical),
; being enriched to the C-level bar.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ORG $AA00
    ENDIF

; -- Mid-instruction references (shown inline as cover+offset) --
;   $AAFD -> SUB_AAC5_3+1         z80 skip idiom: enters the operand of $3E at $AAFC
;   $AB0E -> SUB_AAC5_5+2         shared instruction tail: $AB0E is reachable code inside the instruction at $AB0C
;   $AB3F -> SUB_AB3B_1+1         shared instruction tail: $AB3F is reachable code inside the instruction at $AB3E
;   $AC42 -> SUB_AC2D_3+1         shared instruction tail: $AC42 is reachable code inside the instruction at $AC41
;   $AE7A -> CONIO_SET_A1         z80 skip idiom: enters the operand of $21 at $AE79
;   $AEA2 -> BIOS_VAR_A2         shared instruction tail: $AEA2 is reachable code inside the instruction at $AEA1
;   $AEA9 -> BOOT+1         shared instruction tail: $AEA9 is reachable code inside the instruction at $AEA8
;   $AEAA -> BOOT+2         shared instruction tail: $AEAA is reachable code inside the instruction at $AEA8
;   $AEAC -> SUB_AE73_9+1         z80 skip idiom: enters the operand of $3E at $AEAB
;   $AEAE -> SUB_AE73_10+1        shared instruction tail: $AEAE is reachable code inside the instruction at $AEAD
;   $AEAF -> SUB_AE73_10+2        shared instruction tail: $AEAF is reachable code inside the instruction at $AEAD
;   $AEB1 -> SUB_AE73_11+1        z80 skip idiom: enters the operand of $3E at $AEB0
;   $AEB3 -> SUB_AE73_12+1        shared instruction tail: $AEB3 is reachable code inside the instruction at $AEB2
;   $AEB4 -> SUB_AE73_12+2        shared instruction tail: $AEB4 is reachable code inside the instruction at $AEB2
;   $AEB6 -> SUB_AE73_13+1        shared instruction tail: $AEB6 is reachable code inside the instruction at $AEB5
;   $AF50 -> DISK_RTN_PTRS_B        shared instruction tail: $AF50 is reachable code inside the instruction at $AF4E

L_AA00:
        JP BOOT                    ; $AA00  C3 A8 AE
L_AA03:
        ; jump table
        JP      WBOOT               ; $AA03
        JP      CONST               ; $AA06
        JP      CONIN               ; $AA09
        JP      $AB43                    ; $AA0C
        JP      LIST               ; $AA0F
        JP      PUNCH               ; $AA12
        JP      READER               ; $AA15
        JP      HOME               ; $AA18
        JP      SELDSK               ; $AA1B
        JP      $AD56                    ; $AA1E
        JP      SETSEC               ; $AA21
        JP      SETDMA                 ; $AA24
        JP      READ               ; $AA27
        JP      WRITE               ; $AA2A
        DEFB    $AF,$C9,$00,$60,$69,$C9                          ; $AA2D
L_AA33:
        DEFS    8, $00    ; $AA33  fill
        DEFB    $BA,$AE,$93,$AA,$9A,$AF,$3A,$AF                  ; $AA3B
        DEFS    8, $00    ; $AA43  fill
        DEFB    $BA,$AE,$93                                      ; $AA4B
        DEFB    $AA,$A6,$AF,$4A,$AF,$00                          ; $AA4E  "*&/J/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA54
        DEFB    $AA,$B2,$AF,$5A,$AF,$00                          ; $AA5E  "*2/Z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA64
        DEFB    $AA,$BE,$AF,$6A,$AF,$00                          ; $AA6E  "*>/j/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA74
        DEFB    $AA,$CA,$AF,$7A,$AF,$00                          ; $AA7E  "*J/z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93,$AA,$D6,$AF,$8A,$AF,$20 ; $AA84
        DEFB    $00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,$00,$03,$00 ; $AA94
SUB_AAA2:
        LD DE,$0007                      ; $AAA2  11 07 00
SUB_AAA2_1:
        LD HL,$F3B8                      ; $AAA5  21 B8 F3
        ADD HL,DE                        ; $AAA8  19
        LD A,(HL)                        ; $AAA9  7E
        SUB $03                          ; $AAAA  D6 03
        JR NZ,SUB_AAA2_2                 ; $AAAC  20 07
        CALL SUB_AD60                    ; $AAAE  CD 60 AD
        LD (HL),$03                      ; $AAB1  36 03
        LD (HL),$15                      ; $AAB3  36 15
SUB_AAA2_2:
        DEC A                            ; $AAB5  3D
        JR NZ,SUB_AAA2_3                 ; $AAB6  20 09
        CALL SUB_ACEE                    ; $AAB8  CD EE AC
        LD HL,$C800                      ; $AABB  21 00 C8
        CALL SUB_AB3B                    ; $AABE  CD 3B AB
SUB_AAA2_3:
        DEC E                            ; $AAC1  1D
        JR NZ,SUB_AAA2_1                 ; $AAC2  20 E1
        RET                              ; $AAC4  C9
SUB_AAC5:
        LD HL,$E000                      ; $AAC5  21 00 E0
        LD A,E                           ; $AAC8  7B
        OR H                             ; $AAC9  B4
        LD H,A                           ; $AACA  67
        RET                              ; $AACB  C9
WBOOT:
        LD SP,$0080                      ; $AACC  31 80 00
        LD A,($E051)                     ; $AACF  3A 51 E0
        LD HL,$0E00                      ; $AAD2  21 00 0E
        CALL SUB_AB3B                    ; $AAD5  CD 3B AB
        CALL SUB_AAA2                    ; $AAD8  CD A2 AA
SUB_AAC5_2:
        XOR A                            ; $AADB  AF
        LD (SUB_AE73_12+2),A             ; $AADC  32 B4 AE
        LD (SUB_AE73_10+2),A             ; $AADF  32 AF AE
        LD A,$C3                         ; $AAE2  3E C3
        LD ($0000),A                     ; $AAE4  32 00 00
        LD HL,L_AA03                     ; $AAE7  21 03 AA
        LD ($0001),HL                    ; $AAEA  22 01 00
        LD ($0005),A                     ; $AAED  32 05 00
        LD HL,$9C06                      ; $AAF0  21 06 9C
        LD ($0006),HL                    ; $AAF3  22 06 00
        LD BC,$0080                      ; $AAF6  01 80 00
        CALL SETDMA                    ; $AAF9  CD 8E AD
SUB_AAC5_3:
        LD A,$01                         ; $AAFC  3E 01
        LD ($98B2),A                     ; $AAFE  32 B2 98
        LD A,($0004)                     ; $AB01  3A 04 00
        LD C,A                           ; $AB04  4F
        JP $9400                         ; $AB05  C3 00 94
CONST:
        LD HL,($F380)                    ; $AB08  2A 80 F3
        JP (HL)                          ; $AB0B  E9
SUB_AAC5_5:
        LD A,($E000)                     ; $AB0C  3A 00 E0
        RLA                              ; $AB0F  17
        SBC A,A                          ; $AB10  9F
        RET                              ; $AB11  C9
        DEFB    $CD,$29,$AB,$21,$AB,$F3,$06,$06,$4F,$23,$7E,$23,$B7,$FA,$27,$AB ; $AB12
        DEFB    $B9,$7E,$C8,$10,$F4,$79,$C9,$11,$03,$00,$C3      ; $AB22
L_AB2D:
        DEFB    $2F,$AB,$3A,$00,$E0,$17,$30,$FA,$32,$10,$E0,$3F,$1F,$C9 ; $AB2D
SUB_AB3B:
        LD ($F3D0),HL                    ; $AB3B  22 D0 F3
SUB_AB3B_1:
        LD ($0000),A                     ; $AB3E  32 00 00
        RET                              ; $AB41  C9
SUB_AB42:
        LD C,A                           ; $AB42  4F
        LD A,($0003)                     ; $AB43  3A 03 00
        AND $03                          ; $AB46  E6 03
        CP $02                           ; $AB48  FE 02
        JR NZ,SUB_AB42_10                ; $AB4A  20 4B
SUB_AB42_1:
        LD HL,($F392)                    ; $AB4C  2A 92 F3
        JP (HL)                          ; $AB4F  E9
CONIN:
        LD A,($0003)                     ; $AB50  3A 03 00
        AND $03                          ; $AB53  E6 03
        CP $02                           ; $AB55  FE 02
        LD HL,($F384)                    ; $AB57  2A 84 F3
        JR Z,SUB_AB42_4                  ; $AB5A  28 06
        JR NC,SUB_AB42_5                 ; $AB5C  30 07
SUB_AB42_3:
        LD HL,($F382)                    ; $AB5E  2A 82 F3
        JP (HL)                          ; $AB61  E9
SUB_AB42_4:
        LD HL,($F38A)                    ; $AB62  2A 8A F3
SUB_AB42_5:
        JP (HL)                          ; $AB65  E9
LIST:
        LD A,($0003)                     ; $AB66  3A 03 00
        AND $C0                          ; $AB69  E6 C0
        CP $80                           ; $AB6B  FE 80
        JR C,SUB_AB42_9                  ; $AB6D  38 27
        JR Z,SUB_AB42_1                  ; $AB6F  28 DB
        LD HL,($F394)                    ; $AB71  2A 94 F3
        JP (HL)                          ; $AB74  E9
PUNCH:
        LD A,($0003)                     ; $AB75  3A 03 00
        AND $30                          ; $AB78  E6 30
        CP $10                           ; $AB7A  FE 10
        JR C,SUB_AB42_9                  ; $AB7C  38 18
        LD HL,($F38E)                    ; $AB7E  2A 8E F3
        JR NZ,SUB_AB42_5                 ; $AB81  20 E2
        LD HL,($F390)                    ; $AB83  2A 90 F3
        JP (HL)                          ; $AB86  E9
READER:
        LD A,($0003)                     ; $AB87  3A 03 00
        AND $0C                          ; $AB8A  E6 0C
        CP $04                           ; $AB8C  FE 04
        JR C,SUB_AB42_3                  ; $AB8E  38 CE
        JR Z,SUB_AB42_4                  ; $AB90  28 D0
        LD HL,($F38C)                    ; $AB92  2A 8C F3
        JP (HL)                          ; $AB95  E9
SUB_AB42_9:
        SCF                              ; $AB96  37
SUB_AB42_10:
        SBC A,A                          ; $AB97  9F
        LD HL,BIOS_VAR_A2               ; $AB98  21 A2 AE
        LD (HL),A                        ; $AB9B  77
        RES 7,C                          ; $AB9C  CB B9
        INC HL                           ; $AB9E  23
        LD A,(HL)                        ; $AB9F  7E
        OR A                             ; $ABA0  B7
        JR Z,SUB_ABDD_1                  ; $ABA1  28 3D
        DEC (HL)                         ; $ABA3  35
        LD A,($F396)                     ; $ABA4  3A 96 F3
        LD HL,SUB_AE73_9                 ; $ABA7  21 AB AE
        JR Z,SUB_ABB1_2                  ; $ABAA  28 0C
        OR A                             ; $ABAC  B7
        JP P,SUB_ABB1_1                  ; $ABAD  F2 B3 AB
        DEC HL                           ; $ABB0  2B
SUB_ABB1:
        AND $7F                          ; $ABB1  E6 7F
SUB_ABB1_1:
        LD E,A                           ; $ABB3  5F
        LD A,C                           ; $ABB4  79
        SUB E                            ; $ABB5  93
        LD (HL),A                        ; $ABB6  77
        RET                              ; $ABB7  C9
SUB_ABB1_2:
        OR A                             ; $ABB8  B7
        JP M,SUB_ABB1_3                  ; $ABB9  FA BD AB
        DEC HL                           ; $ABBC  2B
SUB_ABB1_3:
        CALL SUB_ABB1                    ; $ABBD  CD B1 AB
        LD HL,(BOOT+2)             ; $ABC0  2A AA AE
        LD A,($F3A1)                     ; $ABC3  3A A1 F3
        OR A                             ; $ABC6  B7
        JP P,SUB_ABB1_4                  ; $ABC7  F2 CF AB
        AND $7F                          ; $ABCA  E6 7F
        LD E,L                           ; $ABCC  5D
        LD L,H                           ; $ABCD  6C
        LD H,E                           ; $ABCE  63
SUB_ABB1_4:
        LD E,A                           ; $ABCF  5F
        ADD A,H                          ; $ABD0  84
        LD C,A                           ; $ABD1  4F
        LD A,E                           ; $ABD2  7B
        ADD A,L                          ; $ABD3  85
        PUSH AF                          ; $ABD4  F5
        LD B,$07                         ; $ABD5  06 07
        CALL SUB_AC2D                    ; $ABD7  CD 2D AC
        POP AF                           ; $ABDA  F1
        LD B,$0A                         ; $ABDB  06 0A
SUB_ABDD:
        LD C,A                           ; $ABDD  4F
        JR SUB_AC2D                      ; $ABDE  18 4D
SUB_ABDD_1:
        LD B,A                           ; $ABE0  47
        LD HL,BIOS_VAR_A4                 ; $ABE1  21 A4 AE
        LD A,(HL)                        ; $ABE4  7E
        LD E,A                           ; $ABE5  5F
        OR A                             ; $ABE6  B7
        JR NZ,SUB_ABDD_3                 ; $ABE7  20 11
        LD A,($F397)                     ; $ABE9  3A 97 F3
        OR A                             ; $ABEC  B7
        JR Z,SUB_ABDD_2                  ; $ABED  28 06
        CP C                             ; $ABEF  B9
        JR NZ,SUB_ABDD_2                 ; $ABF0  20 03
        LD (HL),$80                      ; $ABF2  36 80
        RET                              ; $ABF4  C9
SUB_ABDD_2:
        LD A,$1F                         ; $ABF5  3E 1F
        CP C                             ; $ABF7  B9
        JR C,SUB_AC2D                    ; $ABF8  38 33
SUB_ABDD_3:
        LD HL,$F3A0                      ; $ABFA  21 A0 F3
        LD B,$09                         ; $ABFD  06 09
SUB_ABDD_4:
        LD A,(HL)                        ; $ABFF  7E
        OR A                             ; $AC00  B7
        JR Z,SUB_ABDD_5                  ; $AC01  28 04
        XOR E                            ; $AC03  AB
        CP C                             ; $AC04  B9
        JR Z,SUB_ABDD_6                  ; $AC05  28 05
SUB_ABDD_5:
        DEC HL                           ; $AC07  2B
        DJNZ SUB_ABDD_4                  ; $AC08  10 F5
        JR SUB_AC2D                      ; $AC0A  18 21
SUB_ABDD_6:
        LD DE,$000B                      ; $AC0C  11 0B 00
        ADD HL,DE                        ; $AC0F  19
        LD A,(HL)                        ; $AC10  7E
        OR A                             ; $AC11  B7
        LD C,A                           ; $AC12  4F
        JP P,SUB_ABDD_7                  ; $AC13  F2 23 AC
        AND $7F                          ; $AC16  E6 7F
        LD C,A                           ; $AC18  4F
        PUSH BC                          ; $AC19  C5
        LD A,($F3A2)                     ; $AC1A  3A A2 F3
        LD B,$07                         ; $AC1D  06 07
        CALL SUB_ABDD                    ; $AC1F  CD DD AB
        POP BC                           ; $AC22  C1
SUB_ABDD_7:
        LD A,B                           ; $AC23  78
        CP $07                           ; $AC24  FE 07
        JR NZ,SUB_AC2D                   ; $AC26  20 05
        LD A,$02                         ; $AC28  3E 02
        LD (BIOS_VAR_A3),A                ; $AC2A  32 A3 AE
SUB_AC2D:
        XOR A                            ; $AC2D  AF
        LD (BIOS_VAR_A4),A                ; $AC2E  32 A4 AE
        LD A,(BIOS_VAR_A2)              ; $AC31  3A A2 AE
        OR A                             ; $AC34  B7
        LD HL,($F388)                    ; $AC35  2A 88 F3
        JR Z,SUB_AC2D_1                  ; $AC38  28 03
        LD HL,($F386)                    ; $AC3A  2A 86 F3
SUB_AC2D_1:
        JP (HL)                          ; $AC3D  E9
SUB_AC2D_2:
        LD DE,$0003                      ; $AC3E  11 03 00
SUB_AC2D_3:
        JP SUB_AC2D_4                    ; $AC41  C3 44 AC
SUB_AC2D_4:
        LD HL,(BIOS_PTR_A5)               ; $AC44  2A A5 AE
        LD A,(BIOS_VAR_A7)                ; $AC47  3A A7 AE
        LD (HL),A                        ; $AC4A  77
        CALL SUB_AC6B                    ; $AC4B  CD 6B AC
        LD HL,($F028)                    ; $AC4E  2A 28 F0
        LD A,($F024)                     ; $AC51  3A 24 F0
        LD E,A                           ; $AC54  5F
        LD D,$F0                         ; $AC55  16 F0
        ADD HL,DE                        ; $AC57  19
        LD (BIOS_PTR_A5),HL               ; $AC58  22 A5 AE
        LD A,(HL)                        ; $AC5B  7E
        LD (BIOS_VAR_A7),A                ; $AC5C  32 A7 AE
        CP $E0                           ; $AC5F  FE E0
        JR C,SUB_AC2D_5                  ; $AC61  38 02
        XOR $20                          ; $AC63  EE 20
SUB_AC2D_5:
        AND $3F                          ; $AC65  E6 3F
        OR $40                           ; $AC67  F6 40
        LD (HL),A                        ; $AC69  77
        RET                              ; $AC6A  C9
SUB_AC6B:
        LD A,B                           ; $AC6B  78
        OR A                             ; $AC6C  B7
        JR Z,L_AC7A                      ; $AC6D  28 0B
        LD HL,SUB_AB3B                   ; $AC6F  21 3B AB
        PUSH HL                          ; $AC72  E5
        LD HL,L_ACD4                     ; $AC73  21 D4 AC
        ADD A,L                          ; $AC76  85
        DEFB    $6F,$6E,$E9                                      ; $AC77
L_AC7A:
        DEFB    $79,$FE,$0D,$20,$05                              ; $AC7A
        DEFB    $AF,$32,$24,$F0,$C9,$F6,$80                      ; $AC7F  "/2$pIv"
        DEFB    $FE,$E0,$38,$04,$21,$DD,$F3,$AE,$32,$45,$F0,$21,$F0,$FD,$18,$79 ; $AC86
        DEFB    $3E,$FF,$01,$3E,$3F,$32,$32,$F0,$E1,$C9,$21,$F4,$FB,$C9,$AF,$6F ; $AC96
        DEFB    $67,$22,$24,$F0,$32,$45,$F0,$21,$C1,$FB,$C9,$2E,$42,$01,$2E,$9C ; $ACA6
        DEFB    $01,$2E,$1A,$01,$2E,$58,$26,$FC,$C9,$2A,$AA,$AE,$7D,$FE,$28,$38 ; $ACB6
        DEFB    $02,$2E,$00,$7C,$FE,$18,$38,$02,$26,$00,$22,$24,$F0,$18 ; $ACC6
L_ACD4:
        DEFB    $D5,$BA,$B1,$B4,$96,$99,$A4,$9E,$B7,$A0,$BF,$CD,$60,$AD,$7E,$E6 ; $ACD4
        DEFB    $02,$28,$FB,$2C,$71,$C9                          ; $ACE4
SUB_ACEA:
        LD A,C                           ; $ACEA  79
        LD ($F045),A                     ; $ACEB  32 45 F0
SUB_ACEE:
        CALL SUB_AD5B                    ; $ACEE  CD 5B AD
        LD ($F6F8),A                     ; $ACF1  32 F8 F6
        LD ($F047),A                     ; $ACF4  32 47 F0
        LD A,($EFFF)                     ; $ACF7  3A FF EF
        CALL SUB_AAC5                    ; $ACFA  CD C5 AA
        SUB $20                          ; $ACFD  D6 20
        LD ($F046),A                     ; $ACFF  32 46 F0
        LD A,(HL)                        ; $AD02  7E
        RET                              ; $AD03  C9
SUB_ACEE_1:
        CALL SUB_ACEA                    ; $AD04  CD EA AC
        LD HL,$F678                      ; $AD07  21 78 F6
        ADD HL,DE                        ; $AD0A  19
        LD (HL),C                        ; $AD0B  71
        LD HL,$C9AA                      ; $AD0C  21 AA C9
        JP SUB_AB3B                      ; $AD0F  C3 3B AB
        DEFB    $CD,$60,$AD,$7E,$1F,$30,$FC,$2C,$7E,$C9,$CD,$EE,$AC,$21,$4D,$C8 ; $AD12
        DEFB    $CD,$3B,$AB,$21,$78,$F6,$19,$7E,$C9,$11,$01,$00,$C3 ; $AD22
L_AD2F:
        DEFB    $3E,$AD,$CD,$C5,$AA,$2E,$C1,$7E,$17,$38,$FC,$CD,$5B,$AD,$71,$C9 ; $AD2F
        DEFB    $11,$02,$00,$C3                                  ; $AD3F
L_AD43:
        DEFB    $3E,$AD,$11,$02,$00                              ; $AD43
L_AD48:
        DEFB    $C3                                              ; $AD48
L_AD49:
        DEFB    "\0"    ; $AD49
L_AD4A:
        DEFB    "\0"    ; $AD4A
HOME:
        LD A,(SUB_AE73_11)               ; $AD4B  3A B0 AE
        OR A                             ; $AD4E  B7
        JR NZ,SUB_ACEE_3                 ; $AD4F  20 03
        LD (SUB_AE73_10+2),A             ; $AD51  32 AF AE
SUB_ACEE_3:
        LD C,$00                         ; $AD54  0E 00
        LD A,C                           ; $AD56  79
        LD (BOOT),A                ; $AD57  32 A8 AE
        RET                              ; $AD5A  C9
SUB_AD5B:
        LD HL,$E080                      ; $AD5B  21 80 E0
        JR SUB_AD60_1                    ; $AD5E  18 03
SUB_AD60:
        LD HL,$E08E                      ; $AD60  21 8E E0
SUB_AD60_1:
        LD A,E                           ; $AD63  7B
SUB_AD60_2:
        ADD A,A                          ; $AD64  87
        ADD A,A                          ; $AD65  87
        ADD A,A                          ; $AD66  87
        ADD A,A                          ; $AD67  87
        PUSH AF                          ; $AD68  F5
        ADD A,L                          ; $AD69  85
        LD L,A                           ; $AD6A  6F
        POP AF                           ; $AD6B  F1
        RET                              ; $AD6C  C9
SELDSK:
        LD DE,SUB_AE73_9+1               ; $AD6D  11 AC AE
        LD HL,$0004                      ; $AD70  21 04 00
        LD A,($F3B8)                     ; $AD73  3A B8 F3
        DEC A                            ; $AD76  3D
        CP C                             ; $AD77  B9
        JR C,SUB_AD60_4                  ; $AD78  38 0A
        LD A,(HL)                        ; $AD7A  7E
        LD (DE),A                        ; $AD7B  12
        INC DE                           ; $AD7C  13
        LD A,C                           ; $AD7D  79
        LD (DE),A                        ; $AD7E  12
        LD HL,L_AA33                     ; $AD7F  21 33 AA
        JR SUB_AD60_2                    ; $AD82  18 E0
SUB_AD60_4:
        LD A,(DE)                        ; $AD84  1A
        LD (HL),A                        ; $AD85  77
        LD L,$00                         ; $AD86  2E 00
        RET                              ; $AD88  C9
SETSEC:
        LD A,C                           ; $AD89  79
        LD (BOOT+1),A              ; $AD8A  32 A9 AE
        RET                              ; $AD8D  C9
SETDMA:
        LD (SUB_AE73_14),BC              ; $AD8E  ED 43 B8 AE
        RET                              ; $AD92  C9
READ:
        XOR A                            ; $AD93  AF
        LD (SUB_AE73_12+2),A             ; $AD94  32 B4 AE
        LD A,$02                         ; $AD97  3E 02
        LD HL,SUB_AE73_11+1              ; $AD99  21 B1 AE
        LD (HL),A                        ; $AD9C  77
        INC HL                           ; $AD9D  23
        LD (HL),A                        ; $AD9E  77
        INC HL                           ; $AD9F  23
        LD (HL),A                        ; $ADA0  77
        JR SUB_AD8E_6                    ; $ADA1  18 4F
WRITE:
        LD H,C                           ; $ADA3  61
        LD L,$00                         ; $ADA4  2E 00
        LD (SUB_AE73_11+1),HL            ; $ADA6  22 B1 AE
        LD A,C                           ; $ADA9  79
        CP $02                           ; $ADAA  FE 02
        JR NZ,SUB_AD8E_3                 ; $ADAC  20 0F
        LD L,$08                         ; $ADAE  2E 08
        LD A,(SUB_AE73_10)               ; $ADB0  3A AD AE
        LD H,A                           ; $ADB3  67
        LD (SUB_AE73_12+2),HL            ; $ADB4  22 B4 AE
        LD HL,(BOOT)               ; $ADB7  2A A8 AE
        LD (SUB_AE73_13+1),HL            ; $ADBA  22 B6 AE
SUB_AD8E_3:
        LD HL,SUB_AE73_12+2              ; $ADBD  21 B4 AE
        LD A,(HL)                        ; $ADC0  7E
        OR A                             ; $ADC1  B7
        JR Z,SUB_AD8E_5                  ; $ADC2  28 28
        DEC (HL)                         ; $ADC4  35
        LD A,(SUB_AE73_10)               ; $ADC5  3A AD AE
        INC HL                           ; $ADC8  23
        CP (HL)                          ; $ADC9  BE
        JR NZ,SUB_AD8E_5                 ; $ADCA  20 20
        LD A,(BOOT)                ; $ADCC  3A A8 AE
        LD HL,(SUB_AE73_13+1)            ; $ADCF  2A B6 AE
        CP L                             ; $ADD2  BD
        JR NZ,SUB_AD8E_5                 ; $ADD3  20 17
        LD A,(BOOT+1)              ; $ADD5  3A A9 AE
        CP H                             ; $ADD8  BC
        JR NZ,SUB_AD8E_5                 ; $ADD9  20 11
        INC H                            ; $ADDB  24
        LD A,H                           ; $ADDC  7C
        SUB $20                          ; $ADDD  D6 20
        JR C,SUB_AD8E_4                  ; $ADDF  38 02
        LD H,A                           ; $ADE1  67
        INC L                            ; $ADE2  2C
SUB_AD8E_4:
        LD (SUB_AE73_13+1),HL            ; $ADE3  22 B6 AE
        XOR A                            ; $ADE6  AF
        LD (SUB_AE73_12+1),A             ; $ADE7  32 B3 AE
        JR SUB_AD8E_6                    ; $ADEA  18 06
SUB_AD8E_5:
        LD HL,$0001                      ; $ADEC  21 01 00
        LD (SUB_AE73_12+1),HL            ; $ADEF  22 B3 AE
SUB_AD8E_6:
        CALL SUB_AFF0                    ; $ADF2  CD F0 AF
        LD E,A                           ; $ADF5  5F
        RRA                              ; $ADF6  1F
        LD HL,SECTOR_XLATE                 ; $ADF7  21 92 AE
        ADD A,L                          ; $ADFA  85
        LD L,A                           ; $ADFB  6F
        LD C,(HL)                        ; $ADFC  4E
        LD HL,SUB_AE73_10+2              ; $ADFD  21 AF AE
        LD A,(HL)                        ; $AE00  7E
        LD (HL),$01                      ; $AE01  36 01
        OR A                             ; $AE03  B7
        JR Z,SUB_AD8E_8                  ; $AE04  28 1B
        LD HL,(SUB_AE73_10)              ; $AE06  2A AD AE
        LD A,L                           ; $AE09  7D
        CP H                             ; $AE0A  BC
        JR NZ,SUB_AD8E_7                 ; $AE0B  20 0D
        LD HL,($F3E0)                    ; $AE0D  2A E0 F3
        LD A,(BOOT)                ; $AE10  3A A8 AE
        CP L                             ; $AE13  BD
        JR NZ,SUB_AD8E_7                 ; $AE14  20 04
        LD A,C                           ; $AE16  79
        CP H                             ; $AE17  BC
        JR Z,SUB_AD8E_9                  ; $AE18  28 33
SUB_AD8E_7:
        LD A,(SUB_AE73_11)               ; $AE1A  3A B0 AE
        OR A                             ; $AE1D  B7
        CALL NZ,SUB_AE73                 ; $AE1E  C4 73 AE
SUB_AD8E_8:
        LD A,(SUB_AE73_10)               ; $AE21  3A AD AE
        LD (SUB_AE73_10+1),A             ; $AE24  32 AE AE
        LD B,A                           ; $AE27  47
        AND $01                          ; $AE28  E6 01
        INC A                            ; $AE2A  3C
        LD ($F3E4),A                     ; $AE2B  32 E4 F3
        LD A,B                           ; $AE2E  78
        AND $0E                          ; $AE2F  E6 0E
        ADD A,A                          ; $AE31  87
        ADD A,A                          ; $AE32  87
        ADD A,A                          ; $AE33  87
        CPL                              ; $AE34  2F
        ADD A,$61                        ; $AE35  C6 61
        LD ($F3E6),A                     ; $AE37  32 E6 F3
        LD A,(BOOT)                ; $AE3A  3A A8 AE
        LD L,A                           ; $AE3D  6F
        LD H,C                           ; $AE3E  61
        LD ($F3E0),HL                    ; $AE3F  22 E0 F3
        LD A,(SUB_AE73_12+1)             ; $AE42  3A B3 AE
        OR A                             ; $AE45  B7
        CALL NZ,CONIO_SET_A1             ; $AE46  C4 7A AE
        XOR A                            ; $AE49  AF
        LD (SUB_AE73_11),A               ; $AE4A  32 B0 AE
SUB_AD8E_9:
        LD A,E                           ; $AE4D  7B
        LD HL,$F800                      ; $AE4E  21 00 F8
        RRA                              ; $AE51  1F
        RR L                             ; $AE52  CB 1D
        LD DE,(SUB_AE73_14)              ; $AE54  ED 5B B8 AE
        LD BC,$0080                      ; $AE58  01 80 00
        LD A,(SUB_AE73_11+1)             ; $AE5B  3A B1 AE
        OR A                             ; $AE5E  B7
        JR NZ,SUB_AD8E_10                ; $AE5F  20 05
        INC A                            ; $AE61  3C
        LD (SUB_AE73_11),A               ; $AE62  32 B0 AE
        EX DE,HL                         ; $AE65  EB
SUB_AD8E_10:
        LDIR                             ; $AE66  ED B0
        LD A,(SUB_AE73_12)               ; $AE68  3A B2 AE
        RRA                              ; $AE6B  1F
        LD A,$00                         ; $AE6C  3E 00
        RET NC                           ; $AE6E  D0
        CALL SUB_AE73                    ; $AE6F  CD 73 AE
        RET                              ; $AE72  C9
SUB_AE73:
        XOR A                            ; $AE73  AF
        LD (SUB_AE73_11),A               ; $AE74  32 B0 AE
        LD A,$02                         ; $AE77  3E 02
        DEFB    $21                      ; $AE79  cover (LD HL,nn opcode): on fall-through absorbs the
                                         ;        LD A,$01 below, leaving A=$02 from $AE77
CONIO_SET_A1:
        LD A,$01                         ; $AE7A  CALL'd directly -> A=$01 (cover-skipped on fall-through)
        LD ($F3EB),A                     ; $AE7C  32 EB F3
        LD HL,$0E03                      ; $AE7F  21 03 0E
        CALL SUB_AB3B                    ; $AE82  CD 3B AB
        LD A,($F3EA)                     ; $AE85  3A EA F3
        OR A                             ; $AE88  B7
        RET Z                            ; $AE89  C8
        POP DE                           ; $AE8A  D1
        CP $10                           ; $AE8B  FE 10
        RET NZ                           ; $AE8D  C0
        LD HL,($9C0D)                    ; $AE8E  2A 0D 9C
        JP (HL)                          ; $AE91  E9
SECTOR_XLATE:
        ; $AE92  16-entry logical->physical sector skew table (a 0..15 permutation),
        ; indexed during disk deblock (SUB_AF59-style *1 byte lookups).
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A      ; $AE92
        DEFB    $04,$0D,$07,$08,$02,$0B,$05,$0E      ; $AE9A
BIOS_VAR_A2:
        DEFB    $00                      ; $AEA2  disk scratch byte
BIOS_VAR_A3:
        DEFB    $00                      ; $AEA3  disk scratch byte
BIOS_VAR_A4:
        DEFB    $00                      ; $AEA4  disk scratch byte
BIOS_PTR_A5:
        DEFW    BIOS_VAR_A7              ; $AEA5  pointer cell (init -> BIOS_VAR_A7)
BIOS_VAR_A7:
        DEFB    $00                      ; $AEA7  disk scratch byte
BOOT:
        LD SP,$0100                      ; $AEA8  31 00 01
SUB_AE73_9:
        LD A,$C9                         ; $AEAB  3E C9
SUB_AE73_10:
        LD (L_AA00),A                    ; $AEAD  32 00 AA
SUB_AE73_11:
        LD A,$95                         ; $AEB0  3E 95
SUB_AE73_12:
        LD ($0003),A                     ; $AEB2  32 03 00
SUB_AE73_13:
        LD HL,($F3DE)                    ; $AEB5  2A DE F3
SUB_AE73_14:
        LD (SUB_AB3B_1+1),HL             ; $AEB8  22 3F AB
        XOR A                            ; $AEBB  AF
        LD ($0004),A                     ; $AEBC  32 04 00
        LD A,($F3BB)                     ; $AEBF  3A BB F3
        CP $05                           ; $AEC2  FE 05
        JR NC,SUB_AE73_16                ; $AEC4  30 1F
        SUB $03                          ; $AEC6  D6 03
        JR C,SUB_AE73_16                 ; $AEC8  38 1B
        JR NZ,SUB_AE73_15                ; $AECA  20 06
        LD HL,$1FB0                      ; $AECC  21 B0 1F
        LD (SUB_AAC5_5+2),HL             ; $AECF  22 0E AB
SUB_AE73_15:
        PUSH AF                          ; $AED2  F5
        CALL SUB_AF59                    ; $AED3  CD 59 AF
        POP AF                           ; $AED6  F1
        LD (SUB_AC2D_3+1),HL             ; $AED7  22 42 AC
        CALL SUB_AF54                    ; $AEDA  CD 54 AF
        LD (L_AB2D),HL                   ; $AEDD  22 2D AB
        LD A,$03                         ; $AEE0  3E 03
        LD (SUB_AAC5_3+1),A              ; $AEE2  32 FD AA
SUB_AE73_16:
        LD A,($F3B9)                     ; $AEE5  3A B9 F3
        SUB $03                          ; $AEE8  D6 03
        JR C,SUB_AE73_17                 ; $AEEA  38 08
        CALL SUB_AF59                    ; $AEEC  CD 59 AF
        LD (L_AD2F),HL                   ; $AEEF  22 2F AD
        LD E,$80                         ; $AEF2  1E 80
SUB_AE73_17:
        LD A,($F3BA)                     ; $AEF4  3A BA F3
        SUB $03                          ; $AEF7  D6 03
        JR C,SUB_AE73_18                 ; $AEF9  38 14
        PUSH AF                          ; $AEFB  F5
        CALL SUB_AF59                    ; $AEFC  CD 59 AF
        LD (L_AD43),HL                   ; $AEFF  22 43 AD
        POP AF                           ; $AF02  F1
        CP $02                           ; $AF03  FE 02
        JR NC,SUB_AE73_18                ; $AF05  30 08
        CALL SUB_AF54                    ; $AF07  CD 54 AF
        LD (L_AD49),HL                   ; $AF0A  22 49 AD
        JR SUB_AE73_19                   ; $AF0D  18 0B
SUB_AE73_18:
        LD HL,$1A3E                      ; $AF0F  21 3E 1A
        LD (L_AD48),HL                   ; $AF12  22 48 AD
        LD A,$C9                         ; $AF15  3E C9
        LD (L_AD4A),A                    ; $AF17  32 4A AD
SUB_AE73_19:
        LD A,($F381)                     ; $AF1A  3A 81 F3
        OR A                             ; $AF1D  B7
        JR NZ,SUB_AE73_20                ; $AF1E  20 0B
        LD HL,L_AFAE                     ; $AF20  21 AE AF
        LD DE,$F380                      ; $AF23  11 80 F3
        LD BC,$0016                      ; $AF26  01 16 00
        LDIR                             ; $AF29  ED B0
SUB_AE73_20:
        CALL SUB_AAA2                    ; $AF2B  CD A2 AA
        LD A,($F398)                     ; $AF2E  3A 98 F3
        CALL SUB_AF64                    ; $AF31  CD 64 AF
        LD A,($F39B)                     ; $AF34  3A 9B F3
        CALL SUB_AF64                    ; $AF37  CD 64 AF
        LD HL,L_AF73                     ; $AF3A  21 73 AF
SUB_AE73_21:
        LD A,(HL)                        ; $AF3D  7E
        OR A                             ; $AF3E  B7
        JP Z,SUB_AAC5_2                  ; $AF3F  CA DB AA
        PUSH HL                          ; $AF42  E5
        CALL SUB_AB42                    ; $AF43  CD 42 AB
        POP HL                           ; $AF46  E1
        INC HL                           ; $AF47  23
        JR SUB_AE73_21                   ; $AF48  18 F3
DISK_RTN_PTRS:
        ; $AF4A  table of BIOS handler addresses (DEFW); SUB_AF59 indexes from here,
        ; SUB_AF54 indexes from DISK_RTN_PTRS_B (+6). Addresses relocated in the
        ; semantic pass once the targets are named.
        DEFW    $ACDF                    ; $AF4A  [0]
        DEFW    $AD04                    ; $AF4C  [1]
        DEFW    $AD31                    ; $AF4E  [2]
DISK_RTN_PTRS_B:
        DEFW    $AD12                    ; $AF50  SUB_AF54 base
        DEFW    $AD1C                    ; $AF52
SUB_AF54:
        LD HL,DISK_RTN_PTRS_B              ; $AF54  21 50 AF
        JR SUB_AF59_1                    ; $AF57  18 03
SUB_AF59:
        LD HL,DISK_RTN_PTRS                ; $AF59  21 4A AF
SUB_AF59_1:
        ADD A,A                          ; $AF5C  87
        ADD A,L                          ; $AF5D  85
        LD L,A                           ; $AF5E  6F
        LD A,(HL)                        ; $AF5F  7E
        INC L                            ; $AF60  2C
        LD H,(HL)                        ; $AF61  66
        LD L,A                           ; $AF62  6F
        RET                              ; $AF63  C9
SUB_AF64:
        OR A                             ; $AF64  B7
        JP P,SUB_AF64_1                  ; $AF65  F2 70 AF
        PUSH AF                          ; $AF68  F5
        LD A,($F397)                     ; $AF69  3A 97 F3
        CALL SUB_AB42                    ; $AF6C  CD 42 AB
        POP AF                           ; $AF6F  F1
SUB_AF64_1:
        JP SUB_AB42                      ; $AF70  C3 42 AB
L_AF73:
        DEFB    "\r\n\r\n\r\n"    ; $AF73
        DEFB    "Apple ][ CP/M"    ; $AF79  string
        DEFB    $0D    ; $AF86  terminator
        DEFB    "\n"    ; $AF87
        DEFB    "44K Ver. 2.20"    ; $AF88  string
        DEFB    $0D    ; $AF95  terminator
        DEFB    "\n"    ; $AF96
        DEFB    "(C) 1980 Microsoft"    ; $AF97  string
        DEFB    $0D    ; $AFA9  terminator
        DEFB    "\n\r\n\0"    ; $AFAA
L_AFAE:
        DEFB    $0C,$AB,$12,$AB,$12,$AB,$3E,$AC,$3E,$AC,$45,$AD,$45,$AD,$3F,$AD ; $AFAE
        DEFB    $3F,$AD,$2B,$AD,$2B,$AD,$42,$AB,$E1,$23,$18,$F3,$DF,$AC,$04,$AD ; $AFBE
        DEFB    $31,$AD,$12,$AD,$1C,$AD,$21,$50,$AF,$18,$03,$21,$4A,$AF,$87,$85 ; $AFCE
        DEFB    $6F,$7E,$2C,$66,$6F,$C9,$B7,$F2,$70,$AF,$F5,$3A,$97,$F3,$CD,$42 ; $AFDE
        DEFB    $AB,$F1                                          ; $AFEE
SUB_AFF0:
        LD A,(BOOT+1)              ; $AFF0  3A A9 AE
        OR A                             ; $AFF3  B7
        RET                              ; $AFF4  C9
        DEFB    "\r\n\r\nApple ]"    ; $AFF5

    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $AA00, $0600
    ENDIF
