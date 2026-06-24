; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- CCP (Console Command Processor)
; ----------------------------------------------------------------------------
; Runtime-addressed (de-skewed): ORG $9300 (CBASE), runs $9300-$9BFF. An independent
; compilation; calls the BDOS only through the $0005 ABI and references the BDOS base
; once (BDOS_FBASE). The 44K system tracks store this sector-interleaved; the disk
; producer re-applies the skew (cpm_pipeline/deskew.py :: PAGE_TO_SECTOR_223). See
; ../../docs/CPM_Skew_Findings.md.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    INCLUDE "cpm22.inc"
    INCLUDE "cpm_system_223.inc"
    ORG $9300
    ENDIF

L_9300:
        JP SUB_95E5_6                    ; $9300  C3 0C 96
        DEFB    $C3,$08,$96                                      ; $9303
L_9306:
        DEFB    $7F                                              ; $9306
L_9307:
        DEFB    "\0"    ; $9307
L_9308:
        DEFS    16, $20    ; $9308  fill
        DEFB    "COPYRIGHT (C) 1979, DIGITAL RESEARCH  "    ; $9318  string
        DEFB    $00    ; $933E  terminator
        DEFS    73, $00    ; $933F  fill
L_9388:
        DEFB    $08,$93                                          ; $9388
L_938A:
        DEFB    "\0\0"    ; $938A
SUB_938C:
        LD E,A                           ; $938C  5F
        LD C,$02                         ; $938D  0E 02
        JR SUB_93B6_1                    ; $938F  18 28
SUB_9391:
        LD A,$20                         ; $9391  3E 20
SUB_9393:
        PUSH BC                          ; $9393  C5
        CALL SUB_938C                    ; $9394  CD 8C 93
        POP BC                           ; $9397  C1
        RET                              ; $9398  C9
SUB_9399:
        LD A,$0D                         ; $9399  3E 0D
        CALL SUB_9393                    ; $939B  CD 93 93
        LD A,$0A                         ; $939E  3E 0A
        JR SUB_9393                      ; $93A0  18 F1
SUB_93A2:
        PUSH BC                          ; $93A2  C5
        CALL SUB_9399                    ; $93A3  CD 99 93
        POP HL                           ; $93A6  E1
SUB_93A7:
        LD A,(HL)                        ; $93A7  7E
        OR A                             ; $93A8  B7
        RET Z                            ; $93A9  C8
        INC HL                           ; $93AA  23
        PUSH HL                          ; $93AB  E5
        CALL SUB_938C                    ; $93AC  CD 8C 93
        POP HL                           ; $93AF  E1
        JR SUB_93A7                      ; $93B0  18 F5
SUB_93B2:
        LD C,$0D                         ; $93B2  0E 0D
        JR SUB_93B6_1                    ; $93B4  18 03
SUB_93B6:
        LD E,A                           ; $93B6  5F
        LD C,$0E                         ; $93B7  0E 0E
SUB_93B6_1:
        JP $0005                         ; $93B9  C3 05 00
SUB_93BC:
        LD C,$10                         ; $93BC  0E 10
SUB_93BC_1:
        CALL $0005                       ; $93BE  CD 05 00
        LD (L_9BA7),A                    ; $93C1  32 A7 9B
        INC A                            ; $93C4  3C
        RET                              ; $93C5  C9
SUB_93C6:
        XOR A                            ; $93C6  AF
        LD (L_9BA6),A                    ; $93C7  32 A6 9B
        LD DE,L_9B86                     ; $93CA  11 86 9B
SUB_93CD:
        LD C,$0F                         ; $93CD  0E 0F
        JR SUB_93BC_1                    ; $93CF  18 ED
SUB_93D1:
        LD DE,L_9B86                     ; $93D1  11 86 9B
        LD C,$11                         ; $93D4  0E 11
        JR SUB_93BC_1                    ; $93D6  18 E6
SUB_93D8:
        LD C,$12                         ; $93D8  0E 12
        JR SUB_93BC_1                    ; $93DA  18 E2
SUB_93DC:
        LD C,$13                         ; $93DC  0E 13
        JR SUB_93B6_1                    ; $93DE  18 D9
SUB_93E0:
        LD DE,L_9B86                     ; $93E0  11 86 9B
SUB_93E3:
        LD C,$14                         ; $93E3  0E 14
SUB_93E3_1:
        CALL $0005                       ; $93E5  CD 05 00
        OR A                             ; $93E8  B7
        RET                              ; $93E9  C9
SUB_93EA:
        LD C,$15                         ; $93EA  0E 15
        JR SUB_93E3_1                    ; $93EC  18 F7
SUB_93EE:
        LD C,$16                         ; $93EE  0E 16
        JR SUB_93BC_1                    ; $93F0  18 CC
SUB_93F2:
        LD C,$17                         ; $93F2  0E 17
        JR SUB_93B6_1                    ; $93F4  18 C3
SUB_93F6:
        LD E,$FF                         ; $93F6  1E FF
SUB_93F8:
        LD C,$20                         ; $93F8  0E 20
        JR SUB_93B6_1                    ; $93FA  18 BD
SUB_93FC:
        CALL SUB_93F6                    ; $93FC  CD F6 93
        ADD A,A                          ; $93FF  87
        ADD A,A                          ; $9400  87
        ADD A,A                          ; $9401  87
        ADD A,A                          ; $9402  87
        LD HL,L_9BA8                     ; $9403  21 A8 9B
        OR (HL)                          ; $9406  B6
        LD ($0004),A                     ; $9407  32 04 00
        RET                              ; $940A  C9
SUB_940B:
        LD A,(L_9BA8)                    ; $940B  3A A8 9B
        LD ($0004),A                     ; $940E  32 04 00
        RET                              ; $9411  C9
SUB_9412:
        CP $61                           ; $9412  FE 61
        RET C                            ; $9414  D8
        CP $7B                           ; $9415  FE 7B
        RET NC                           ; $9417  D0
        AND $5F                          ; $9418  E6 5F
        RET                              ; $941A  C9
SUB_941B:
        LD A,(L_9B64)                    ; $941B  3A 64 9B
        OR A                             ; $941E  B7
        JR Z,SUB_941B_1                  ; $941F  28 52
        LD A,(L_9BA8)                    ; $9421  3A A8 9B
        OR A                             ; $9424  B7
        LD A,$00                         ; $9425  3E 00
        CALL NZ,SUB_93B6                 ; $9427  C4 B6 93
        LD DE,L_9B65                     ; $942A  11 65 9B
        CALL SUB_93CD                    ; $942D  CD CD 93
        JR Z,SUB_941B_1                  ; $9430  28 41
        LD A,(L_9B74)                    ; $9432  3A 74 9B
        DEC A                            ; $9435  3D
        LD (L_9B85),A                    ; $9436  32 85 9B
        LD DE,L_9B65                     ; $9439  11 65 9B
        CALL SUB_93E3                    ; $943C  CD E3 93
        JR NZ,SUB_941B_1                 ; $943F  20 32
        LD DE,L_9307                     ; $9441  11 07 93
        LD HL,$0080                      ; $9444  21 80 00
        LD BC,$0080                      ; $9447  01 80 00
        LDIR                             ; $944A  ED B0
        LD HL,L_9B73                     ; $944C  21 73 9B
        LD (HL),$00                      ; $944F  36 00
        INC HL                           ; $9451  23
        DEC (HL)                         ; $9452  35
        LD DE,L_9B65                     ; $9453  11 65 9B
        CALL SUB_93BC                    ; $9456  CD BC 93
        JR Z,SUB_941B_1                  ; $9459  28 18
        LD A,(L_9BA8)                    ; $945B  3A A8 9B
        OR A                             ; $945E  B7
        CALL NZ,SUB_93B6                 ; $945F  C4 B6 93
        LD HL,L_9308                     ; $9462  21 08 93
        CALL SUB_93A7                    ; $9465  CD A7 93
        CALL SUB_949A                    ; $9468  CD 9A 94
        JR Z,SUB_941B_2                  ; $946B  28 14
        CALL SUB_94B5                    ; $946D  CD B5 94
        JP SUB_95E5_7                    ; $9470  C3 31 96
SUB_941B_1:
        CALL SUB_94B5                    ; $9473  CD B5 94
        CALL SUB_93FC                    ; $9476  CD FC 93
        LD C,$0A                         ; $9479  0E 0A
        LD DE,L_9306                     ; $947B  11 06 93
        CALL $0005                       ; $947E  CD 05 00
SUB_941B_2:
        LD HL,L_9307                     ; $9481  21 07 93
        LD B,(HL)                        ; $9484  46
SUB_941B_3:
        INC HL                           ; $9485  23
        LD A,B                           ; $9486  78
        OR A                             ; $9487  B7
        JR Z,SUB_941B_4                  ; $9488  28 08
        LD A,(HL)                        ; $948A  7E
        CALL SUB_9412                    ; $948B  CD 12 94
        LD (HL),A                        ; $948E  77
        DEC B                            ; $948F  05
        JR SUB_941B_3                    ; $9490  18 F3
SUB_941B_4:
        LD (HL),A                        ; $9492  77
        LD HL,L_9308                     ; $9493  21 08 93
        LD (L_9388),HL                   ; $9496  22 88 93
        RET                              ; $9499  C9
SUB_949A:
        LD C,$0B                         ; $949A  0E 0B
        CALL $0005                       ; $949C  CD 05 00
        OR A                             ; $949F  B7
        RET Z                            ; $94A0  C8
        LD C,$01                         ; $94A1  0E 01
        CALL $0005                       ; $94A3  CD 05 00
        OR A                             ; $94A6  B7
        RET                              ; $94A7  C9
SUB_94A8:
        LD C,$19                         ; $94A8  0E 19
        JP $0005                         ; $94AA  C3 05 00
SUB_94AD:
        LD DE,$0080                      ; $94AD  11 80 00
SUB_94B0:
        LD C,$1A                         ; $94B0  0E 1A
        JP $0005                         ; $94B2  C3 05 00
SUB_94B5:
        LD HL,L_9B64                     ; $94B5  21 64 9B
        LD A,(HL)                        ; $94B8  7E
        OR A                             ; $94B9  B7
        RET Z                            ; $94BA  C8
        LD (HL),$00                      ; $94BB  36 00
        XOR A                            ; $94BD  AF
        CALL SUB_93B6                    ; $94BE  CD B6 93
        LD DE,L_9B65                     ; $94C1  11 65 9B
        CALL SUB_93DC                    ; $94C4  CD DC 93
        LD A,(L_9BA8)                    ; $94C7  3A A8 9B
        JP SUB_93B6                      ; $94CA  C3 B6 93
SUB_94CD:
        LD DE,L_95DF                     ; $94CD  11 DF 95
        LD HL,BDOS_FBASE                     ; $94D0  21 00 9C
        LD B,$06                         ; $94D3  06 06
SUB_94CD_1:
        LD A,(DE)                        ; $94D5  1A
        CP (HL)                          ; $94D6  BE
        JP NZ,SUB_95E5_9                 ; $94D7  C2 7E 96
        INC DE                           ; $94DA  13
        INC HL                           ; $94DB  23
        DJNZ SUB_94CD_1                  ; $94DC  10 F7
        RET                              ; $94DE  C9
SUB_94DF:
        CALL SUB_9399                    ; $94DF  CD 99 93
        LD HL,(L_938A)                   ; $94E2  2A 8A 93
SUB_94DF_1:
        LD A,(HL)                        ; $94E5  7E
        CP $20                           ; $94E6  FE 20
        JR Z,SUB_94DF_2                  ; $94E8  28 0B
        OR A                             ; $94EA  B7
        JR Z,SUB_94DF_2                  ; $94EB  28 08
        PUSH HL                          ; $94ED  E5
        CALL SUB_938C                    ; $94EE  CD 8C 93
        POP HL                           ; $94F1  E1
        INC HL                           ; $94F2  23
        JR SUB_94DF_1                    ; $94F3  18 F0
SUB_94DF_2:
        LD A,$3F                         ; $94F5  3E 3F
        CALL SUB_938C                    ; $94F7  CD 8C 93
        CALL SUB_9399                    ; $94FA  CD 99 93
        CALL SUB_94B5                    ; $94FD  CD B5 94
        JP SUB_95E5_7                    ; $9500  C3 31 96
SUB_9503:
        LD A,(DE)                        ; $9503  1A
        OR A                             ; $9504  B7
        RET Z                            ; $9505  C8
        CP $20                           ; $9506  FE 20
        JR C,SUB_94DF                    ; $9508  38 D5
        RET Z                            ; $950A  C8
        CP $3D                           ; $950B  FE 3D
        RET Z                            ; $950D  C8
        CP $5F                           ; $950E  FE 5F
        RET Z                            ; $9510  C8
        CP $2E                           ; $9511  FE 2E
        RET Z                            ; $9513  C8
        CP $3A                           ; $9514  FE 3A
        RET Z                            ; $9516  C8
        CP $3B                           ; $9517  FE 3B
        RET Z                            ; $9519  C8
        CP $3C                           ; $951A  FE 3C
        RET Z                            ; $951C  C8
        CP $3E                           ; $951D  FE 3E
        RET Z                            ; $951F  C8
        RET                              ; $9520  C9
SUB_9521:
        LD A,(DE)                        ; $9521  1A
        OR A                             ; $9522  B7
        RET Z                            ; $9523  C8
        CP $20                           ; $9524  FE 20
        RET NZ                           ; $9526  C0
        INC DE                           ; $9527  13
        JR SUB_9521                      ; $9528  18 F7
SUB_952A:
        ADD A,L                          ; $952A  85
        LD L,A                           ; $952B  6F
        RET NC                           ; $952C  D0
        INC H                            ; $952D  24
        RET                              ; $952E  C9
SUB_952F:
        LD A,$00                         ; $952F  3E 00
SUB_9531:
        LD HL,L_9B86                     ; $9531  21 86 9B
        CALL SUB_952A                    ; $9534  CD 2A 95
        PUSH HL                          ; $9537  E5
        PUSH HL                          ; $9538  E5
        XOR A                            ; $9539  AF
        LD (L_9BA9),A                    ; $953A  32 A9 9B
        LD HL,(L_9388)                   ; $953D  2A 88 93
        EX DE,HL                         ; $9540  EB
        CALL SUB_9521                    ; $9541  CD 21 95
        EX DE,HL                         ; $9544  EB
        LD (L_938A),HL                   ; $9545  22 8A 93
        EX DE,HL                         ; $9548  EB
        POP HL                           ; $9549  E1
        LD A,(DE)                        ; $954A  1A
        OR A                             ; $954B  B7
        JR Z,SUB_9531_1                  ; $954C  28 0A
        SBC A,$40                        ; $954E  DE 40
        LD B,A                           ; $9550  47
        INC DE                           ; $9551  13
        LD A,(DE)                        ; $9552  1A
        CP $3A                           ; $9553  FE 3A
        JR Z,SUB_9531_2                  ; $9555  28 07
        DEC DE                           ; $9557  1B
SUB_9531_1:
        LD A,(L_9BA8)                    ; $9558  3A A8 9B
        LD (HL),A                        ; $955B  77
        JR SUB_9531_3                    ; $955C  18 06
SUB_9531_2:
        LD A,B                           ; $955E  78
        LD (L_9BA9),A                    ; $955F  32 A9 9B
        LD (HL),B                        ; $9562  70
        INC DE                           ; $9563  13
SUB_9531_3:
        LD B,$08                         ; $9564  06 08
SUB_9531_4:
        CALL SUB_9503                    ; $9566  CD 03 95
        JR Z,SUB_9531_8                  ; $9569  28 15
        INC HL                           ; $956B  23
        CP $2A                           ; $956C  FE 2A
        JR NZ,SUB_9531_5                 ; $956E  20 04
        LD (HL),$3F                      ; $9570  36 3F
        JR SUB_9531_6                    ; $9572  18 02
SUB_9531_5:
        LD (HL),A                        ; $9574  77
        INC DE                           ; $9575  13
SUB_9531_6:
        DJNZ SUB_9531_4                  ; $9576  10 EE
SUB_9531_7:
        CALL SUB_9503                    ; $9578  CD 03 95
        JR Z,SUB_9531_9                  ; $957B  28 08
        INC DE                           ; $957D  13
        JR SUB_9531_7                    ; $957E  18 F8
SUB_9531_8:
        INC HL                           ; $9580  23
        LD (HL),$20                      ; $9581  36 20
        DJNZ SUB_9531_8                  ; $9583  10 FB
SUB_9531_9:
        LD B,$03                         ; $9585  06 03
        CP $2E                           ; $9587  FE 2E
        JR NZ,SUB_9531_14                ; $9589  20 1B
        INC DE                           ; $958B  13
SUB_9531_10:
        CALL SUB_9503                    ; $958C  CD 03 95
        JR Z,SUB_9531_14                 ; $958F  28 15
        INC HL                           ; $9591  23
        CP $2A                           ; $9592  FE 2A
        JR NZ,SUB_9531_11                ; $9594  20 04
        LD (HL),$3F                      ; $9596  36 3F
        JR SUB_9531_12                   ; $9598  18 02
SUB_9531_11:
        LD (HL),A                        ; $959A  77
        INC DE                           ; $959B  13
SUB_9531_12:
        DJNZ SUB_9531_10                 ; $959C  10 EE
SUB_9531_13:
        CALL SUB_9503                    ; $959E  CD 03 95
        JR Z,SUB_9531_15                 ; $95A1  28 08
        INC DE                           ; $95A3  13
        JR SUB_9531_13                   ; $95A4  18 F8
SUB_9531_14:
        INC HL                           ; $95A6  23
        LD (HL),$20                      ; $95A7  36 20
        DJNZ SUB_9531_14                 ; $95A9  10 FB
SUB_9531_15:
        LD B,$03                         ; $95AB  06 03
SUB_9531_16:
        INC HL                           ; $95AD  23
        LD (HL),$00                      ; $95AE  36 00
        DJNZ SUB_9531_16                 ; $95B0  10 FB
        EX DE,HL                         ; $95B2  EB
        LD (L_9388),HL                   ; $95B3  22 88 93
        POP HL                           ; $95B6  E1
        LD BC,$000B                      ; $95B7  01 0B 00
SUB_9531_17:
        INC HL                           ; $95BA  23
        LD A,(HL)                        ; $95BB  7E
        CP $3F                           ; $95BC  FE 3F
        JR NZ,SUB_9531_18                ; $95BE  20 01
        INC B                            ; $95C0  04
SUB_9531_18:
        DEC C                            ; $95C1  0D
        JR NZ,SUB_9531_17                ; $95C2  20 F6
        LD A,B                           ; $95C4  78
        OR A                             ; $95C5  B7
        RET                              ; $95C6  C9
L_95C7:
        DEFB    "DIR ERA TYPESAVEREN USER"    ; $95C7  string
L_95DF:
        DEFB    $BD,$16,$00,$01,$4D,$40                          ; $95DF
SUB_95E5:
        LD HL,L_95C7                     ; $95E5  21 C7 95
        LD C,$00                         ; $95E8  0E 00
SUB_95E5_1:
        LD A,C                           ; $95EA  79
        CP $06                           ; $95EB  FE 06
        RET NC                           ; $95ED  D0
        LD DE,L_9B87                     ; $95EE  11 87 9B
        LD B,$04                         ; $95F1  06 04
SUB_95E5_2:
        LD A,(DE)                        ; $95F3  1A
        CP (HL)                          ; $95F4  BE
        JR NZ,SUB_95E5_3                 ; $95F5  20 0B
        INC DE                           ; $95F7  13
        INC HL                           ; $95F8  23
        DJNZ SUB_95E5_2                  ; $95F9  10 F8
        LD A,(DE)                        ; $95FB  1A
        CP $20                           ; $95FC  FE 20
        JR NZ,SUB_95E5_4                 ; $95FE  20 05
        LD A,C                           ; $9600  79
        RET                              ; $9601  C9
SUB_95E5_3:
        INC HL                           ; $9602  23
        DJNZ SUB_95E5_3                  ; $9603  10 FD
SUB_95E5_4:
        INC C                            ; $9605  0C
        JR SUB_95E5_1                    ; $9606  18 E2
SUB_95E5_5:
        XOR A                            ; $9608  AF
        LD (L_9307),A                    ; $9609  32 07 93
SUB_95E5_6:
        LD SP,L_9B64                     ; $960C  31 64 9B
        PUSH BC                          ; $960F  C5
        LD A,C                           ; $9610  79
        RRA                              ; $9611  1F
        RRA                              ; $9612  1F
        RRA                              ; $9613  1F
        RRA                              ; $9614  1F
        AND $0F                          ; $9615  E6 0F
        LD E,A                           ; $9617  5F
        CALL SUB_93F8                    ; $9618  CD F8 93
        CALL SUB_93B2                    ; $961B  CD B2 93
        LD (L_9B64),A                    ; $961E  32 64 9B
        POP BC                           ; $9621  C1
        LD A,C                           ; $9622  79
        AND $0F                          ; $9623  E6 0F
        LD (L_9BA8),A                    ; $9625  32 A8 9B
        CALL SUB_93B6                    ; $9628  CD B6 93
        LD A,(L_9307)                    ; $962B  3A 07 93
        OR A                             ; $962E  B7
        JR NZ,SUB_95E5_8                 ; $962F  20 16
SUB_95E5_7:
        LD SP,L_9B64                     ; $9631  31 64 9B
        CALL SUB_9399                    ; $9634  CD 99 93
        CALL SUB_94A8                    ; $9637  CD A8 94
        ADD A,$41                        ; $963A  C6 41
        CALL SUB_938C                    ; $963C  CD 8C 93
        LD A,$3E                         ; $963F  3E 3E
        CALL SUB_938C                    ; $9641  CD 8C 93
        CALL SUB_941B                    ; $9644  CD 1B 94
SUB_95E5_8:
        LD DE,$0080                      ; $9647  11 80 00
        CALL SUB_94B0                    ; $964A  CD B0 94
        CALL SUB_94A8                    ; $964D  CD A8 94
        LD (L_9BA8),A                    ; $9650  32 A8 9B
        CALL SUB_952F                    ; $9653  CD 2F 95
        CALL NZ,SUB_94DF                 ; $9656  C4 DF 94
        LD A,(L_9BA9)                    ; $9659  3A A9 9B
        OR A                             ; $965C  B7
        JP NZ,SUB_9707_32                ; $965D  C2 26 99
        CALL SUB_95E5                    ; $9660  CD E5 95
        LD HL,L_9670                     ; $9663  21 70 96
        LD E,A                           ; $9666  5F
        LD D,$00                         ; $9667  16 00
        ADD HL,DE                        ; $9669  19
        ADD HL,DE                        ; $966A  19
        LD A,(HL)                        ; $966B  7E
        INC HL                           ; $966C  23
        LD H,(HL)                        ; $966D  66
        LD L,A                           ; $966E  6F
        JP (HL)                          ; $966F  E9
L_9670:
        DEFW    SUB_9707_1               ; $9670
        DEFW    SUB_9707_13              ; $9672
        DEFW    SUB_9707_15              ; $9674
        DEFW    SUB_9707_20              ; $9676
        DEFW    SUB_9707_25              ; $9678
        DEFW    SUB_9707_31              ; $967A
        DEFW    SUB_9707_32              ; $967C
SUB_95E5_9:
        LD HL,$76F3                      ; $967E  21 F3 76
        LD (L_9300),HL                   ; $9681  22 00 93
        LD HL,L_9300                     ; $9684  21 00 93
        JP (HL)                          ; $9687  E9
SUB_9688:
        LD BC,L_968E                     ; $9688  01 8E 96
        JP SUB_93A2                      ; $968B  C3 A2 93
L_968E:
        DEFB    "Read error"    ; $968E  string
        DEFB    $00    ; $9698  terminator
SUB_9699:
        LD BC,L_969F                     ; $9699  01 9F 96
        JP SUB_93A2                      ; $969C  C3 A2 93
L_969F:
        DEFB    "No file"    ; $969F  string
        DEFB    $00    ; $96A6  terminator
SUB_96A7:
        CALL SUB_952F                    ; $96A7  CD 2F 95
        LD A,(L_9BA9)                    ; $96AA  3A A9 9B
        OR A                             ; $96AD  B7
        JP NZ,SUB_94DF                   ; $96AE  C2 DF 94
        LD HL,L_9B87                     ; $96B1  21 87 9B
        LD BC,$000B                      ; $96B4  01 0B 00
SUB_96A7_1:
        LD A,(HL)                        ; $96B7  7E
        CP $20                           ; $96B8  FE 20
        JR Z,SUB_96A7_2                  ; $96BA  28 24
        INC HL                           ; $96BC  23
        SUB $30                          ; $96BD  D6 30
        CP $0A                           ; $96BF  FE 0A
        JP NC,SUB_94DF                   ; $96C1  D2 DF 94
        LD D,A                           ; $96C4  57
        LD A,B                           ; $96C5  78
        AND $E0                          ; $96C6  E6 E0
        JP NZ,SUB_94DF                   ; $96C8  C2 DF 94
        LD A,B                           ; $96CB  78
        RLCA                             ; $96CC  07
        RLCA                             ; $96CD  07
        RLCA                             ; $96CE  07
        ADD A,B                          ; $96CF  80
        JP C,SUB_94DF                    ; $96D0  DA DF 94
        ADD A,B                          ; $96D3  80
        JP C,SUB_94DF                    ; $96D4  DA DF 94
        ADD A,D                          ; $96D7  82
        JP C,SUB_94DF                    ; $96D8  DA DF 94
        LD B,A                           ; $96DB  47
        DEC C                            ; $96DC  0D
        JR NZ,SUB_96A7_1                 ; $96DD  20 D8
        RET                              ; $96DF  C9
SUB_96A7_2:
        LD A,(HL)                        ; $96E0  7E
        CP $20                           ; $96E1  FE 20
        JP NZ,SUB_94DF                   ; $96E3  C2 DF 94
        INC HL                           ; $96E6  23
        DEC C                            ; $96E7  0D
        JR NZ,SUB_96A7_2                 ; $96E8  20 F6
        LD A,B                           ; $96EA  78
        RET                              ; $96EB  C9
SUB_96EC:
        LD HL,$0080                      ; $96EC  21 80 00
        ADD A,C                          ; $96EF  81
        CALL SUB_952A                    ; $96F0  CD 2A 95
        LD A,(HL)                        ; $96F3  7E
        RET                              ; $96F4  C9
SUB_96F5:
        XOR A                            ; $96F5  AF
        LD (L_9B86),A                    ; $96F6  32 86 9B
        LD A,(L_9BA9)                    ; $96F9  3A A9 9B
        OR A                             ; $96FC  B7
        RET Z                            ; $96FD  C8
        DEC A                            ; $96FE  3D
        LD HL,L_9BA8                     ; $96FF  21 A8 9B
        CP (HL)                          ; $9702  BE
        RET Z                            ; $9703  C8
        JP SUB_93B6                      ; $9704  C3 B6 93
SUB_9707:
        LD A,(L_9BA9)                    ; $9707  3A A9 9B
        OR A                             ; $970A  B7
        RET Z                            ; $970B  C8
        DEC A                            ; $970C  3D
        LD HL,L_9BA8                     ; $970D  21 A8 9B
        CP (HL)                          ; $9710  BE
        RET Z                            ; $9711  C8
        LD A,(L_9BA8)                    ; $9712  3A A8 9B
        JP SUB_93B6                      ; $9715  C3 B6 93
SUB_9707_1:
        CALL SUB_952F                    ; $9718  CD 2F 95
        CALL SUB_96F5                    ; $971B  CD F5 96
        LD HL,L_9B87                     ; $971E  21 87 9B
        LD A,(HL)                        ; $9721  7E
        CP $20                           ; $9722  FE 20
        JR NZ,SUB_9707_3                 ; $9724  20 07
        LD B,$0B                         ; $9726  06 0B
SUB_9707_2:
        LD (HL),$3F                      ; $9728  36 3F
        INC HL                           ; $972A  23
        DJNZ SUB_9707_2                  ; $972B  10 FB
SUB_9707_3:
        LD E,$00                         ; $972D  1E 00
        PUSH DE                          ; $972F  D5
        CALL SUB_93D1                    ; $9730  CD D1 93
        CALL Z,SUB_9699                  ; $9733  CC 99 96
SUB_9707_4:
        JR Z,SUB_9707_12                 ; $9736  28 75
        LD A,(L_9BA7)                    ; $9738  3A A7 9B
        RRCA                             ; $973B  0F
        RRCA                             ; $973C  0F
        RRCA                             ; $973D  0F
        AND $60                          ; $973E  E6 60
        LD C,A                           ; $9740  4F
        LD A,$0A                         ; $9741  3E 0A
        CALL SUB_96EC                    ; $9743  CD EC 96
        RLA                              ; $9746  17
        JR C,SUB_9707_11                 ; $9747  38 5A
        POP DE                           ; $9749  D1
        LD A,E                           ; $974A  7B
        INC E                            ; $974B  1C
        PUSH DE                          ; $974C  D5
        AND $03                          ; $974D  E6 03
        PUSH AF                          ; $974F  F5
        JR NZ,SUB_9707_5                 ; $9750  20 14
        CALL SUB_9399                    ; $9752  CD 99 93
        PUSH BC                          ; $9755  C5
        CALL SUB_94A8                    ; $9756  CD A8 94
        POP BC                           ; $9759  C1
        ADD A,$41                        ; $975A  C6 41
        CALL SUB_9393                    ; $975C  CD 93 93
        LD A,$3A                         ; $975F  3E 3A
        CALL SUB_9393                    ; $9761  CD 93 93
        JR SUB_9707_6                    ; $9764  18 08
SUB_9707_5:
        CALL SUB_9391                    ; $9766  CD 91 93
        LD A,$3A                         ; $9769  3E 3A
        CALL SUB_9393                    ; $976B  CD 93 93
SUB_9707_6:
        CALL SUB_9391                    ; $976E  CD 91 93
        LD B,$01                         ; $9771  06 01
SUB_9707_7:
        LD A,B                           ; $9773  78
        CALL SUB_96EC                    ; $9774  CD EC 96
        AND $7F                          ; $9777  E6 7F
        CP $20                           ; $9779  FE 20
        JR NZ,SUB_9707_9                 ; $977B  20 13
        POP AF                           ; $977D  F1
        PUSH AF                          ; $977E  F5
        CP $03                           ; $977F  FE 03
        JR NZ,SUB_9707_8                 ; $9781  20 0B
        LD A,$09                         ; $9783  3E 09
        CALL SUB_96EC                    ; $9785  CD EC 96
        AND $7F                          ; $9788  E6 7F
        CP $20                           ; $978A  FE 20
        JR Z,SUB_9707_10                 ; $978C  28 14
SUB_9707_8:
        LD A,$20                         ; $978E  3E 20
SUB_9707_9:
        CALL SUB_9393                    ; $9790  CD 93 93
        INC B                            ; $9793  04
        LD A,B                           ; $9794  78
        CP $0C                           ; $9795  FE 0C
        JR NC,SUB_9707_10                ; $9797  30 09
        CP $09                           ; $9799  FE 09
        JR NZ,SUB_9707_7                 ; $979B  20 D6
        CALL SUB_9391                    ; $979D  CD 91 93
        JR SUB_9707_7                    ; $97A0  18 D1
SUB_9707_10:
        POP AF                           ; $97A2  F1
SUB_9707_11:
        CALL SUB_949A                    ; $97A3  CD 9A 94
        JR NZ,SUB_9707_12                ; $97A6  20 05
        CALL SUB_93D8                    ; $97A8  CD D8 93
        JR SUB_9707_4                    ; $97AB  18 89
SUB_9707_12:
        POP DE                           ; $97AD  D1
        JP SUB_9707_47                   ; $97AE  C3 38 9A
SUB_9707_13:
        CALL SUB_952F                    ; $97B1  CD 2F 95
        CP $0B                           ; $97B4  FE 0B
        JR NZ,SUB_9707_14                ; $97B6  20 1B
        LD BC,L_97E3                     ; $97B8  01 E3 97
        CALL SUB_93A2                    ; $97BB  CD A2 93
        CALL SUB_941B                    ; $97BE  CD 1B 94
        LD HL,L_9307                     ; $97C1  21 07 93
        DEC (HL)                         ; $97C4  35
        JP NZ,SUB_95E5_7                 ; $97C5  C2 31 96
        INC HL                           ; $97C8  23
        LD A,(HL)                        ; $97C9  7E
        CP $59                           ; $97CA  FE 59
        JP NZ,SUB_95E5_7                 ; $97CC  C2 31 96
        INC HL                           ; $97CF  23
        LD (L_9388),HL                   ; $97D0  22 88 93
SUB_9707_14:
        CALL SUB_96F5                    ; $97D3  CD F5 96
        LD DE,L_9B86                     ; $97D6  11 86 9B
        CALL SUB_93DC                    ; $97D9  CD DC 93
        INC A                            ; $97DC  3C
        CALL Z,SUB_9699                  ; $97DD  CC 99 96
        JP SUB_9707_47                   ; $97E0  C3 38 9A
L_97E3:
        DEFB    "All (y/n)?"    ; $97E3  string
        DEFB    $00    ; $97ED  terminator
SUB_9707_15:
        CALL SUB_952F                    ; $97EE  CD 2F 95
        JP NZ,SUB_94DF                   ; $97F1  C2 DF 94
        CALL SUB_96F5                    ; $97F4  CD F5 96
        CALL SUB_93C6                    ; $97F7  CD C6 93
        JR Z,SUB_9707_19                 ; $97FA  28 38
        CALL SUB_9399                    ; $97FC  CD 99 93
        LD HL,L_9BAA                     ; $97FF  21 AA 9B
        LD (HL),$FF                      ; $9802  36 FF
SUB_9707_16:
        LD HL,L_9BAA                     ; $9804  21 AA 9B
        LD A,(HL)                        ; $9807  7E
        CP $80                           ; $9808  FE 80
        JR C,SUB_9707_17                 ; $980A  38 09
        PUSH HL                          ; $980C  E5
        CALL SUB_93E0                    ; $980D  CD E0 93
        POP HL                           ; $9810  E1
        JR NZ,SUB_9707_18                ; $9811  20 1A
        XOR A                            ; $9813  AF
        LD (HL),A                        ; $9814  77
SUB_9707_17:
        INC (HL)                         ; $9815  34
        LD HL,$0080                      ; $9816  21 80 00
        CALL SUB_952A                    ; $9819  CD 2A 95
        LD A,(HL)                        ; $981C  7E
        CP $1A                           ; $981D  FE 1A
        JP Z,SUB_9707_47                 ; $981F  CA 38 9A
        CALL SUB_938C                    ; $9822  CD 8C 93
        CALL SUB_949A                    ; $9825  CD 9A 94
        JP NZ,SUB_9707_47                ; $9828  C2 38 9A
        JR SUB_9707_16                   ; $982B  18 D7
SUB_9707_18:
        DEC A                            ; $982D  3D
        JP Z,SUB_9707_47                 ; $982E  CA 38 9A
        CALL SUB_9688                    ; $9831  CD 88 96
SUB_9707_19:
        CALL SUB_9707                    ; $9834  CD 07 97
        JP SUB_94DF                      ; $9837  C3 DF 94
SUB_9707_20:
        CALL SUB_96A7                    ; $983A  CD A7 96
        PUSH AF                          ; $983D  F5
        CALL SUB_952F                    ; $983E  CD 2F 95
        JP NZ,SUB_94DF                   ; $9841  C2 DF 94
        CALL SUB_96F5                    ; $9844  CD F5 96
        LD DE,L_9B86                     ; $9847  11 86 9B
        PUSH DE                          ; $984A  D5
        CALL SUB_93DC                    ; $984B  CD DC 93
        POP DE                           ; $984E  D1
        CALL SUB_93EE                    ; $984F  CD EE 93
        JR Z,SUB_9707_23                 ; $9852  28 2F
        XOR A                            ; $9854  AF
        LD (L_9BA6),A                    ; $9855  32 A6 9B
        POP AF                           ; $9858  F1
        LD L,A                           ; $9859  6F
        LD H,$00                         ; $985A  26 00
        ADD HL,HL                        ; $985C  29
        LD DE,$0100                      ; $985D  11 00 01
SUB_9707_21:
        LD A,H                           ; $9860  7C
        OR L                             ; $9861  B5
        JR Z,SUB_9707_22                 ; $9862  28 16
        DEC HL                           ; $9864  2B
        PUSH HL                          ; $9865  E5
        LD HL,$0080                      ; $9866  21 80 00
        ADD HL,DE                        ; $9869  19
        PUSH HL                          ; $986A  E5
        CALL SUB_94B0                    ; $986B  CD B0 94
        LD DE,L_9B86                     ; $986E  11 86 9B
        CALL SUB_93EA                    ; $9871  CD EA 93
        POP DE                           ; $9874  D1
        POP HL                           ; $9875  E1
        JR NZ,SUB_9707_23                ; $9876  20 0B
        JR SUB_9707_21                   ; $9878  18 E6
SUB_9707_22:
        LD DE,L_9B86                     ; $987A  11 86 9B
        CALL SUB_93BC                    ; $987D  CD BC 93
        INC A                            ; $9880  3C
        JR NZ,SUB_9707_24                ; $9881  20 06
SUB_9707_23:
        LD BC,L_988F                     ; $9883  01 8F 98
        CALL SUB_93A2                    ; $9886  CD A2 93
SUB_9707_24:
        CALL SUB_94AD                    ; $9889  CD AD 94
        JP SUB_9707_47                   ; $988C  C3 38 9A
L_988F:
        DEFB    "No space"    ; $988F  string
        DEFB    $00    ; $9897  terminator
SUB_9707_25:
        CALL SUB_952F                    ; $9898  CD 2F 95
        JP NZ,SUB_94DF                   ; $989B  C2 DF 94
        LD A,(L_9BA9)                    ; $989E  3A A9 9B
        PUSH AF                          ; $98A1  F5
        CALL SUB_96F5                    ; $98A2  CD F5 96
        CALL SUB_93D1                    ; $98A5  CD D1 93
        JR NZ,SUB_9707_30                ; $98A8  20 50
        LD HL,L_9B86                     ; $98AA  21 86 9B
        LD DE,L_9B96                     ; $98AD  11 96 9B
        LD BC,$0010                      ; $98B0  01 10 00
        LDIR                             ; $98B3  ED B0
        LD HL,(L_9388)                   ; $98B5  2A 88 93
        EX DE,HL                         ; $98B8  EB
        CALL SUB_9521                    ; $98B9  CD 21 95
        CP $3D                           ; $98BC  FE 3D
        JR Z,SUB_9707_26                 ; $98BE  28 04
        CP $5F                           ; $98C0  FE 5F
        JR NZ,SUB_9707_29                ; $98C2  20 30
SUB_9707_26:
        EX DE,HL                         ; $98C4  EB
        INC HL                           ; $98C5  23
        LD (L_9388),HL                   ; $98C6  22 88 93
        CALL SUB_952F                    ; $98C9  CD 2F 95
        JR NZ,SUB_9707_29                ; $98CC  20 26
        POP AF                           ; $98CE  F1
        LD B,A                           ; $98CF  47
        LD HL,L_9BA9                     ; $98D0  21 A9 9B
        LD A,(HL)                        ; $98D3  7E
        OR A                             ; $98D4  B7
        JR Z,SUB_9707_27                 ; $98D5  28 04
        CP B                             ; $98D7  B8
        LD (HL),B                        ; $98D8  70
        JR NZ,SUB_9707_29                ; $98D9  20 19
SUB_9707_27:
        LD (HL),B                        ; $98DB  70
        XOR A                            ; $98DC  AF
        LD (L_9B86),A                    ; $98DD  32 86 9B
        CALL SUB_93D1                    ; $98E0  CD D1 93
        JR Z,SUB_9707_28                 ; $98E3  28 09
        LD DE,L_9B86                     ; $98E5  11 86 9B
        CALL SUB_93F2                    ; $98E8  CD F2 93
        JP SUB_9707_47                   ; $98EB  C3 38 9A
SUB_9707_28:
        CALL SUB_9699                    ; $98EE  CD 99 96
        JP SUB_9707_47                   ; $98F1  C3 38 9A
SUB_9707_29:
        CALL SUB_9707                    ; $98F4  CD 07 97
        JP SUB_94DF                      ; $98F7  C3 DF 94
SUB_9707_30:
        LD BC,L_9903                     ; $98FA  01 03 99
        CALL SUB_93A2                    ; $98FD  CD A2 93
        JP SUB_9707_47                   ; $9900  C3 38 9A
L_9903:
        DEFB    "File exists"    ; $9903  string
        DEFB    $00    ; $990E  terminator
SUB_9707_31:
        CALL SUB_96A7                    ; $990F  CD A7 96
        CP $10                           ; $9912  FE 10
        JP NC,SUB_94DF                   ; $9914  D2 DF 94
        LD E,A                           ; $9917  5F
        LD A,(L_9B87)                    ; $9918  3A 87 9B
        CP $20                           ; $991B  FE 20
        JP Z,SUB_94DF                    ; $991D  CA DF 94
        CALL SUB_93F8                    ; $9920  CD F8 93
        JP SUB_9707_48                   ; $9923  C3 3B 9A
SUB_9707_32:
        CALL SUB_94CD                    ; $9926  CD CD 94
        LD A,(L_9B87)                    ; $9929  3A 87 9B
        CP $20                           ; $992C  FE 20
        JR NZ,SUB_9707_33                ; $992E  20 16
        LD A,(L_9BA9)                    ; $9930  3A A9 9B
        OR A                             ; $9933  B7
        JP Z,SUB_9707_48                 ; $9934  CA 3B 9A
        DEC A                            ; $9937  3D
        PUSH AF                          ; $9938  F5
        CALL SUB_93B6                    ; $9939  CD B6 93
        POP AF                           ; $993C  F1
        LD (L_9BA8),A                    ; $993D  32 A8 9B
        CALL SUB_940B                    ; $9940  CD 0B 94
        JP SUB_9707_48                   ; $9943  C3 3B 9A
SUB_9707_33:
        CALL SUB_93F6                    ; $9946  CD F6 93
        LD (L_9B43),A                    ; $9949  32 43 9B
        LD DE,L_9B8F                     ; $994C  11 8F 9B
        LD A,(DE)                        ; $994F  1A
        CP $20                           ; $9950  FE 20
        JP NZ,SUB_94DF                   ; $9952  C2 DF 94
        PUSH DE                          ; $9955  D5
        CALL SUB_96F5                    ; $9956  CD F5 96
        POP DE                           ; $9959  D1
        LD HL,L_9A35                     ; $995A  21 35 9A
        LD BC,$0003                      ; $995D  01 03 00
        LDIR                             ; $9960  ED B0
SUB_9707_34:
        CALL SUB_93C6                    ; $9962  CD C6 93
        JR NZ,SUB_9707_35                ; $9965  20 0D
        CALL SUB_93F6                    ; $9967  CD F6 93
        OR A                             ; $996A  B7
        JP Z,SUB_9707_45                 ; $996B  CA 1B 9A
        XOR A                            ; $996E  AF
        CALL SUB_9A50                    ; $996F  CD 50 9A
        JR SUB_9707_34                   ; $9972  18 EE
SUB_9707_35:
        LD A,(L_9B86)                    ; $9974  3A 86 9B
        OR A                             ; $9977  B7
        JR Z,SUB_9707_36                 ; $9978  28 04
        DEC A                            ; $997A  3D
        CALL SUB_93B6                    ; $997B  CD B6 93
SUB_9707_36:
        LD C,$1F                         ; $997E  0E 1F
        CALL $0005                       ; $9980  CD 05 00
        INC HL                           ; $9983  23
        INC HL                           ; $9984  23
        LD A,(HL)                        ; $9985  7E
        CP $03                           ; $9986  FE 03
        JR NZ,SUB_9707_37                ; $9988  20 09
        INC HL                           ; $998A  23
        INC HL                           ; $998B  23
        INC HL                           ; $998C  23
        LD A,(HL)                        ; $998D  7E
        CP $8B                           ; $998E  FE 8B
        JP Z,SUB_9A50_1                  ; $9990  CA 54 9A
SUB_9707_37:
        LD HL,$0100                      ; $9993  21 00 01
SUB_9707_38:
        PUSH HL                          ; $9996  E5
        EX DE,HL                         ; $9997  EB
        CALL SUB_94B0                    ; $9998  CD B0 94
        LD DE,L_9B86                     ; $999B  11 86 9B
        CALL SUB_93E3                    ; $999E  CD E3 93
        JR NZ,SUB_9707_39                ; $99A1  20 11
        POP HL                           ; $99A3  E1
        LD DE,$0080                      ; $99A4  11 80 00
        ADD HL,DE                        ; $99A7  19
        LD DE,L_9300                     ; $99A8  11 00 93
        OR A                             ; $99AB  B7
        PUSH HL                          ; $99AC  E5
        SBC HL,DE                        ; $99AD  ED 52
        POP HL                           ; $99AF  E1
        JR NC,SUB_9707_46                ; $99B0  30 72
        JR SUB_9707_38                   ; $99B2  18 E2
SUB_9707_39:
        POP HL                           ; $99B4  E1
        DEC A                            ; $99B5  3D
        JR NZ,SUB_9707_46                ; $99B6  20 6C
SUB_9707_40:
        CALL SUB_9A4D                    ; $99B8  CD 4D 9A
        CALL SUB_9707                    ; $99BB  CD 07 97
        CALL SUB_952F                    ; $99BE  CD 2F 95
        LD HL,L_9BA9                     ; $99C1  21 A9 9B
        PUSH HL                          ; $99C4  E5
        LD A,(HL)                        ; $99C5  7E
        LD (L_9B86),A                    ; $99C6  32 86 9B
        LD A,$10                         ; $99C9  3E 10
        CALL SUB_9531                    ; $99CB  CD 31 95
        POP HL                           ; $99CE  E1
        LD A,(HL)                        ; $99CF  7E
        LD (L_9B96),A                    ; $99D0  32 96 9B
        XOR A                            ; $99D3  AF
        LD (L_9BA6),A                    ; $99D4  32 A6 9B
        LD DE,$005C                      ; $99D7  11 5C 00
        LD HL,L_9B86                     ; $99DA  21 86 9B
        LD BC,$0021                      ; $99DD  01 21 00
        LDIR                             ; $99E0  ED B0
        LD HL,L_9308                     ; $99E2  21 08 93
SUB_9707_41:
        LD A,(HL)                        ; $99E5  7E
        OR A                             ; $99E6  B7
        JR Z,SUB_9707_42                 ; $99E7  28 07
        CP $20                           ; $99E9  FE 20
        JR Z,SUB_9707_42                 ; $99EB  28 03
        INC HL                           ; $99ED  23
        JR SUB_9707_41                   ; $99EE  18 F5
SUB_9707_42:
        LD B,$00                         ; $99F0  06 00
        LD DE,$0081                      ; $99F2  11 81 00
SUB_9707_43:
        LD A,(HL)                        ; $99F5  7E
        LD (DE),A                        ; $99F6  12
        OR A                             ; $99F7  B7
        JR Z,SUB_9707_44                 ; $99F8  28 05
        INC B                            ; $99FA  04
        INC HL                           ; $99FB  23
        INC DE                           ; $99FC  13
        JR SUB_9707_43                   ; $99FD  18 F6
SUB_9707_44:
        LD A,B                           ; $99FF  78
        LD ($0080),A                     ; $9A00  32 80 00
        CALL SUB_9399                    ; $9A03  CD 99 93
        CALL SUB_94AD                    ; $9A06  CD AD 94
        CALL SUB_93FC                    ; $9A09  CD FC 93
        CALL $0100                       ; $9A0C  CD 00 01
        LD SP,L_9B64                     ; $9A0F  31 64 9B
        CALL SUB_940B                    ; $9A12  CD 0B 94
        CALL SUB_93B6                    ; $9A15  CD B6 93
        JP SUB_95E5_7                    ; $9A18  C3 31 96
SUB_9707_45:
        CALL SUB_9A4D                    ; $9A1B  CD 4D 9A
        CALL SUB_9707                    ; $9A1E  CD 07 97
        JP SUB_94DF                      ; $9A21  C3 DF 94
SUB_9707_46:
        LD BC,L_9A2C                     ; $9A24  01 2C 9A
        CALL SUB_93A2                    ; $9A27  CD A2 93
        JR SUB_9707_47                   ; $9A2A  18 0C
L_9A2C:
        DEFB    "Bad load"    ; $9A2C  string
        DEFB    $00    ; $9A34  terminator
L_9A35:
        DEFB    "COM"    ; $9A35
SUB_9707_47:
        CALL SUB_9707                    ; $9A38  CD 07 97
SUB_9707_48:
        CALL SUB_952F                    ; $9A3B  CD 2F 95
        LD A,(L_9B87)                    ; $9A3E  3A 87 9B
        SUB $20                          ; $9A41  D6 20
        LD HL,L_9BA9                     ; $9A43  21 A9 9B
        OR (HL)                          ; $9A46  B6
        JP NZ,SUB_94DF                   ; $9A47  C2 DF 94
        JP SUB_95E5_7                    ; $9A4A  C3 31 96
SUB_9A4D:
        LD A,(L_9B43)                    ; $9A4D  3A 43 9B
SUB_9A50:
        LD E,A                           ; $9A50  5F
        JP SUB_93F8                      ; $9A51  C3 F8 93
SUB_9A50_1:
        LD HL,($F3DE)                    ; $9A54  2A DE F3
        LD (SUB_9B06_2+1),HL             ; $9A57  22 26 9B
        XOR A                            ; $9A5A  AF
        LD (L_9B92),A                    ; $9A5B  32 92 9B
        LD A,$11                         ; $9A5E  3E 11
        LD (L_9B41),A                    ; $9A60  32 41 9B
        LD DE,$92FF                      ; $9A63  11 FF 92
SUB_9A50_2:
        XOR A                            ; $9A66  AF
        LD (L_9BA6),A                    ; $9A67  32 A6 9B
        LD HL,L_9B96                     ; $9A6A  21 96 9B
SUB_9A50_3:
        LD A,(HL)                        ; $9A6D  7E
        OR A                             ; $9A6E  B7
        JR Z,SUB_9A50_4                  ; $9A6F  28 06
        CALL SUB_9A8D                    ; $9A71  CD 8D 9A
        INC HL                           ; $9A74  23
        JR SUB_9A50_3                    ; $9A75  18 F6
SUB_9A50_4:
        LD A,$A6                         ; $9A77  3E A6
        CP L                             ; $9A79  BD
        JP NZ,SUB_9A50_5                 ; $9A7A  C2 82 9A
        CALL SUB_9AC8                    ; $9A7D  CD C8 9A
        JR NZ,SUB_9A50_2                 ; $9A80  20 E4
SUB_9A50_5:
        XOR A                            ; $9A82  AF
        LD (DE),A                        ; $9A83  12
        CALL SUB_9AD4                    ; $9A84  CD D4 9A
        CALL CCP_WBOOT                    ; $9A87  CD 06 9B
        JP SUB_9707_40                   ; $9A8A  C3 B8 99
SUB_9A8D:
        PUSH HL                          ; $9A8D  E5
        PUSH AF                          ; $9A8E  F5
        SRL A                            ; $9A8F  CB 3F
        SRL A                            ; $9A91  CB 3F
        ADD A,$03                        ; $9A93  C6 03
        LD (L_9B42),A                    ; $9A95  32 42 9B
        POP AF                           ; $9A98  F1
        AND $03                          ; $9A99  E6 03
        ADD A,A                          ; $9A9B  87
        ADD A,A                          ; $9A9C  87
        LD HL,L_9B31                     ; $9A9D  21 31 9B
        ADD A,L                          ; $9AA0  85
        LD L,A                           ; $9AA1  6F
        JR NC,SUB_9A8D_1                 ; $9AA2  30 01
        INC H                            ; $9AA4  24
SUB_9A8D_1:
        LD B,$04                         ; $9AA5  06 04
SUB_9A8D_2:
        LD A,(L_9B42)                    ; $9AA7  3A 42 9B
        LD (DE),A                        ; $9AAA  12
        DEC DE                           ; $9AAB  1B
        LD A,(HL)                        ; $9AAC  7E
        INC HL                           ; $9AAD  23
        LD (DE),A                        ; $9AAE  12
        DEC DE                           ; $9AAF  1B
        LD A,(L_9B41)                    ; $9AB0  3A 41 9B
        CP $A1                           ; $9AB3  FE A1
        JP Z,SUB_9707_46                 ; $9AB5  CA 24 9A
        CP $C0                           ; $9AB8  FE C0
        JR NZ,SUB_9A8D_3                 ; $9ABA  20 02
        LD A,$D0                         ; $9ABC  3E D0
SUB_9A8D_3:
        LD (DE),A                        ; $9ABE  12
        INC A                            ; $9ABF  3C
        DEC DE                           ; $9AC0  1B
        LD (L_9B41),A                    ; $9AC1  32 41 9B
        DJNZ SUB_9A8D_2                  ; $9AC4  10 E1
        POP HL                           ; $9AC6  E1
        RET                              ; $9AC7  C9
SUB_9AC8:
        PUSH HL                          ; $9AC8  E5
        PUSH DE                          ; $9AC9  D5
        LD HL,L_9B92                     ; $9ACA  21 92 9B
        INC (HL)                         ; $9ACD  34
        CALL SUB_93C6                    ; $9ACE  CD C6 93
        POP DE                           ; $9AD1  D1
        POP HL                           ; $9AD2  E1
        RET                              ; $9AD3  C9
SUB_9AD4:
        LD HL,$92FF                      ; $9AD4  21 FF 92
SUB_9AD4_1:
        LD D,H                           ; $9AD7  54
        LD E,L                           ; $9AD8  5D
SUB_9AD4_2:
        DEC DE                           ; $9AD9  1B
        DEC DE                           ; $9ADA  1B
        DEC DE                           ; $9ADB  1B
        LD A,(DE)                        ; $9ADC  1A
        OR A                             ; $9ADD  B7
        JR Z,SUB_9AD4_5                  ; $9ADE  28 1E
        CP (HL)                          ; $9AE0  BE
        JR C,SUB_9AD4_3                  ; $9AE1  38 0A
        JR NZ,SUB_9AD4_2                 ; $9AE3  20 F4
        DEC DE                           ; $9AE5  1B
        LD A,(DE)                        ; $9AE6  1A
        INC DE                           ; $9AE7  13
        DEC HL                           ; $9AE8  2B
        CP (HL)                          ; $9AE9  BE
        INC HL                           ; $9AEA  23
        JR NC,SUB_9AD4_2                 ; $9AEB  30 EC
SUB_9AD4_3:
        PUSH HL                          ; $9AED  E5
        PUSH DE                          ; $9AEE  D5
        LD B,$03                         ; $9AEF  06 03
SUB_9AD4_4:
        LD A,(DE)                        ; $9AF1  1A
        LD C,(HL)                        ; $9AF2  4E
        LD (HL),A                        ; $9AF3  77
        LD A,C                           ; $9AF4  79
        LD (DE),A                        ; $9AF5  12
        DEC HL                           ; $9AF6  2B
        DEC DE                           ; $9AF7  1B
        DJNZ SUB_9AD4_4                  ; $9AF8  10 F7
        POP DE                           ; $9AFA  D1
        POP HL                           ; $9AFB  E1
        JR SUB_9AD4_2                    ; $9AFC  18 DB
SUB_9AD4_5:
        DEC HL                           ; $9AFE  2B
        DEC HL                           ; $9AFF  2B
        DEC HL                           ; $9B00  2B
        LD A,(HL)                        ; $9B01  7E
        OR A                             ; $9B02  B7
        JR NZ,SUB_9AD4_1                 ; $9B03  20 D2
        RET                              ; $9B05  C9
        LD DE,$92FF                      ; $9B06  11 FF 92
SUB_9B06_1:
        LD A,(DE)                        ; $9B09  1A
        OR A                             ; $9B0A  B7
        RET Z                            ; $9B0B  C8
        LD ($F3E0),A                     ; $9B0C  32 E0 F3
        DEC DE                           ; $9B0F  1B
        LD A,(DE)                        ; $9B10  1A
        LD ($F3E1),A                     ; $9B11  32 E1 F3
        DEC DE                           ; $9B14  1B
        LD A,(DE)                        ; $9B15  1A
        LD ($F3E9),A                     ; $9B16  32 E9 F3
        DEC DE                           ; $9B19  1B
        LD A,$01                         ; $9B1A  3E 01
        LD ($F3EB),A                     ; $9B1C  32 EB F3
        LD HL,$0E03                      ; $9B1F  21 03 0E
        LD ($F3D0),HL                    ; $9B22  22 D0 F3
SUB_9B06_2:
        LD ($0000),A                     ; $9B25  32 00 00
        LD A,($F3EA)                     ; $9B28  3A EA F3
        OR A                             ; $9B2B  B7
        JR Z,SUB_9B06_1                  ; $9B2C  28 DB
        JP SUB_9707_37                   ; $9B2E  C3 93 99
L_9B31:
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A,$04,$0D,$07,$08,$02,$0B,$05,$0E ; $9B31
L_9B41:
        DEFB    "\0"    ; $9B41
L_9B42:
        DEFB    "\0"    ; $9B42
L_9B43:
        DEFS    33, $00    ; $9B43  fill
L_9B64:
        DEFB    "\0"    ; $9B64
L_9B65:
        DEFB    "\0"    ; $9B65
        DEFB    "$$$     SUB"    ; $9B66  string
        DEFB    $00    ; $9B71  terminator
        DEFB    "\0"    ; $9B72
L_9B73:
        DEFB    "\0"    ; $9B73
L_9B74:
        DEFS    17, $00    ; $9B74  fill
L_9B85:
        DEFB    "\0"    ; $9B85
L_9B86:
        DEFB    "\0"    ; $9B86
L_9B87:
        DEFS    8, $00    ; $9B87  fill
L_9B8F:
        DEFB    "\0\0\0"    ; $9B8F
L_9B92:
        DEFB    "\0\0\0\0"    ; $9B92
L_9B96:
        DEFS    16, $00    ; $9B96  fill
L_9BA6:
        DEFB    "\0"    ; $9BA6
L_9BA7:
        DEFB    "\0"    ; $9BA7
L_9BA8:
        DEFB    "\0"    ; $9BA8
L_9BA9:
        DEFB    "\0"    ; $9BA9
L_9BAA:
        DEFS    86, $00    ; $9BAA  fill
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9300, $0900
    ENDIF
