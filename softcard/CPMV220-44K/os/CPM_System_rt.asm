; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- system image, RUNTIME-ADDRESSED (de-skewed)
; ----------------------------------------------------------------------------
; The 44K system tracks store the CCP/BDOS sector-INTERLEAVED; the cold loader
; de-interleaves them into contiguous RAM, so the image EXECUTES in a different
; order than it sits on disk (see ../../docs/CPM_Skew_Findings.md). This source
; is decoded against the DE-SKEWED RUNTIME image -- exactly what the CPU runs --
; ORG $9400, every label a true runtime address. The de-skew map (runtime page ->
; .dsk sector) is cpm_pipeline/deskew.py, read straight from the emulator's loader.
;
; Runtime map:  CCP $9400-$9BFF (CBASE $9400, entry JP $975C; DRI copyright at
; $9408), BDOS $9C00-$A9FF (FBASE $9C00; entry $9C06; dispatch table $9C47; fn
; 12-40 handlers $A8xx; variable page $A9xx). The two embedded 6502 RPC payloads
; and the boot stub live on other sectors and are not part of this Z-80 image.
;
; DECODE IN PROGRESS: began as an --auto-coverage --relocatable disassembly of the
; de-skewed image (byte-identical), being enriched to the C-level bar. The prior
; on-disk-order CPM_CCP.asm / CPM_BDOS.asm are a naming LEAD only (skewed addresses,
; and their headers carry obsolete skew-seam caveats the de-skew resolved).
; ============================================================================

    DEVICE NOSLOT64K

    ORG $9400

L_9400:
        JP SUB_972E_6                    ; $9400  C3 5C 97
        DEFB    $C3,$58,$97                                      ; $9403
L_9406:
        DEFB    $7F                                              ; $9406
L_9407:
        DEFB    "\0"    ; $9407
L_9408:
        DEFS    16, $20    ; $9408  fill
        DEFB    "COPYRIGHT (C) 1979, DIGITAL RESEARCH  "    ; $9418  string
        DEFB    $00    ; $943E  terminator
        DEFS    73, $00    ; $943F  fill
L_9488:
        DEFB    $08,$94                                          ; $9488
L_948A:
        DEFB    "\0\0"    ; $948A
SUB_948C:
        LD E,A                           ; $948C  5F
        LD C,$02                         ; $948D  0E 02
        JP $0005                         ; $948F  C3 05 00
SUB_9492:
        PUSH BC                          ; $9492  C5
        CALL SUB_948C                    ; $9493  CD 8C 94
        POP BC                           ; $9496  C1
        RET                              ; $9497  C9
SUB_9498:
        LD A,$0D                         ; $9498  3E 0D
        CALL SUB_9492                    ; $949A  CD 92 94
        LD A,$0A                         ; $949D  3E 0A
        JP SUB_9492                      ; $949F  C3 92 94
SUB_94A2:
        LD A,$20                         ; $94A2  3E 20
        JP SUB_9492                      ; $94A4  C3 92 94
SUB_94A7:
        PUSH BC                          ; $94A7  C5
        CALL SUB_9498                    ; $94A8  CD 98 94
        POP HL                           ; $94AB  E1
SUB_94AC:
        LD A,(HL)                        ; $94AC  7E
        OR A                             ; $94AD  B7
        RET Z                            ; $94AE  C8
        INC HL                           ; $94AF  23
        PUSH HL                          ; $94B0  E5
        CALL SUB_948C                    ; $94B1  CD 8C 94
        POP HL                           ; $94B4  E1
        JP SUB_94AC                      ; $94B5  C3 AC 94
SUB_94B8:
        LD C,$0D                         ; $94B8  0E 0D
        JP $0005                         ; $94BA  C3 05 00
SUB_94BD:
        LD E,A                           ; $94BD  5F
        LD C,$0E                         ; $94BE  0E 0E
        JP $0005                         ; $94C0  C3 05 00
SUB_94BD_1:
        CALL $0005                       ; $94C3  CD 05 00
        LD (L_9BEE),A                    ; $94C6  32 EE 9B
        INC A                            ; $94C9  3C
        RET                              ; $94CA  C9
SUB_94CB:
        LD C,$0F                         ; $94CB  0E 0F
        JP SUB_94BD_1                    ; $94CD  C3 C3 94
SUB_94D0:
        XOR A                            ; $94D0  AF
        LD (L_9BED),A                    ; $94D1  32 ED 9B
        LD DE,L_9BCD                     ; $94D4  11 CD 9B
        JP SUB_94CB                      ; $94D7  C3 CB 94
SUB_94DA:
        LD C,$10                         ; $94DA  0E 10
        JP SUB_94BD_1                    ; $94DC  C3 C3 94
SUB_94DA_1:
        LD C,$11                         ; $94DF  0E 11
        JP SUB_94BD_1                    ; $94E1  C3 C3 94
SUB_94E4:
        LD C,$12                         ; $94E4  0E 12
        JP SUB_94BD_1                    ; $94E6  C3 C3 94
SUB_94E9:
        LD DE,L_9BCD                     ; $94E9  11 CD 9B
        JP SUB_94DA_1                    ; $94EC  C3 DF 94
SUB_94EF:
        LD C,$13                         ; $94EF  0E 13
        JP $0005                         ; $94F1  C3 05 00
SUB_94EF_1:
        CALL $0005                       ; $94F4  CD 05 00
        OR A                             ; $94F7  B7
        RET                              ; $94F8  C9
SUB_94F9:
        LD C,$14                         ; $94F9  0E 14
        JP SUB_94EF_1                    ; $94FB  C3 F4 94
SUB_94FE:
        LD DE,L_9BCD                     ; $94FE  11 CD 9B
        JP SUB_94F9                      ; $9501  C3 F9 94
SUB_9504:
        LD C,$15                         ; $9504  0E 15
        JP SUB_94EF_1                    ; $9506  C3 F4 94
SUB_9509:
        LD C,$16                         ; $9509  0E 16
        JP SUB_94BD_1                    ; $950B  C3 C3 94
SUB_950E:
        LD C,$17                         ; $950E  0E 17
        JP $0005                         ; $9510  C3 05 00
SUB_9513:
        LD E,$FF                         ; $9513  1E FF
SUB_9515:
        LD C,$20                         ; $9515  0E 20
        JP $0005                         ; $9517  C3 05 00
SUB_951A:
        CALL SUB_9513                    ; $951A  CD 13 95
        ADD A,A                          ; $951D  87
        ADD A,A                          ; $951E  87
        ADD A,A                          ; $951F  87
        ADD A,A                          ; $9520  87
        LD HL,L_9BEF                     ; $9521  21 EF 9B
        OR (HL)                          ; $9524  B6
        LD ($0004),A                     ; $9525  32 04 00
        RET                              ; $9528  C9
SUB_9529:
        LD A,(L_9BEF)                    ; $9529  3A EF 9B
        LD ($0004),A                     ; $952C  32 04 00
        RET                              ; $952F  C9
SUB_9530:
        CP $61                           ; $9530  FE 61
        RET C                            ; $9532  D8
        CP $7B                           ; $9533  FE 7B
        RET NC                           ; $9535  D0
        AND $5F                          ; $9536  E6 5F
        RET                              ; $9538  C9
SUB_9539:
        LD A,(L_9BAB)                    ; $9539  3A AB 9B
        OR A                             ; $953C  B7
        JP Z,SUB_9539_1                  ; $953D  CA 96 95
        LD A,(L_9BEF)                    ; $9540  3A EF 9B
        OR A                             ; $9543  B7
        LD A,$00                         ; $9544  3E 00
        CALL NZ,SUB_94BD                 ; $9546  C4 BD 94
        LD DE,L_9BAC                     ; $9549  11 AC 9B
        CALL SUB_94CB                    ; $954C  CD CB 94
        JP Z,SUB_9539_1                  ; $954F  CA 96 95
        LD A,(L_9BBB)                    ; $9552  3A BB 9B
        DEC A                            ; $9555  3D
        LD (L_9BCC),A                    ; $9556  32 CC 9B
        LD DE,L_9BAC                     ; $9559  11 AC 9B
        CALL SUB_94F9                    ; $955C  CD F9 94
        JP NZ,SUB_9539_1                 ; $955F  C2 96 95
        LD DE,L_9407                     ; $9562  11 07 94
        LD HL,$0080                      ; $9565  21 80 00
        LD B,$80                         ; $9568  06 80
        CALL SUB_9842                    ; $956A  CD 42 98
        LD HL,L_9BBA                     ; $956D  21 BA 9B
        LD (HL),$00                      ; $9570  36 00
        INC HL                           ; $9572  23
        DEC (HL)                         ; $9573  35
        LD DE,L_9BAC                     ; $9574  11 AC 9B
        CALL SUB_94DA                    ; $9577  CD DA 94
        JP Z,SUB_9539_1                  ; $957A  CA 96 95
        LD A,(L_9BEF)                    ; $957D  3A EF 9B
        OR A                             ; $9580  B7
        CALL NZ,SUB_94BD                 ; $9581  C4 BD 94
        LD HL,L_9408                     ; $9584  21 08 94
        CALL SUB_94AC                    ; $9587  CD AC 94
        CALL SUB_95C2                    ; $958A  CD C2 95
        JP Z,SUB_9539_2                  ; $958D  CA A7 95
        CALL SUB_95DD                    ; $9590  CD DD 95
        JP SUB_972E_7                    ; $9593  C3 82 97
SUB_9539_1:
        CALL SUB_95DD                    ; $9596  CD DD 95
        CALL SUB_951A                    ; $9599  CD 1A 95
        LD C,$0A                         ; $959C  0E 0A
        LD DE,L_9406                     ; $959E  11 06 94
        CALL $0005                       ; $95A1  CD 05 00
        CALL SUB_9529                    ; $95A4  CD 29 95
SUB_9539_2:
        LD HL,L_9407                     ; $95A7  21 07 94
        LD B,(HL)                        ; $95AA  46
SUB_9539_3:
        INC HL                           ; $95AB  23
        LD A,B                           ; $95AC  78
        OR A                             ; $95AD  B7
        JP Z,SUB_9539_4                  ; $95AE  CA BA 95
        LD A,(HL)                        ; $95B1  7E
        CALL SUB_9530                    ; $95B2  CD 30 95
        LD (HL),A                        ; $95B5  77
        DEC B                            ; $95B6  05
        JP SUB_9539_3                    ; $95B7  C3 AB 95
SUB_9539_4:
        LD (HL),A                        ; $95BA  77
        LD HL,L_9408                     ; $95BB  21 08 94
        LD (L_9488),HL                   ; $95BE  22 88 94
        RET                              ; $95C1  C9
SUB_95C2:
        LD C,$0B                         ; $95C2  0E 0B
        CALL $0005                       ; $95C4  CD 05 00
        OR A                             ; $95C7  B7
        RET Z                            ; $95C8  C8
        LD C,$01                         ; $95C9  0E 01
        CALL $0005                       ; $95CB  CD 05 00
        OR A                             ; $95CE  B7
        RET                              ; $95CF  C9
SUB_95D0:
        LD C,$19                         ; $95D0  0E 19
        JP $0005                         ; $95D2  C3 05 00
SUB_95D5:
        LD DE,$0080                      ; $95D5  11 80 00
SUB_95D8:
        LD C,$1A                         ; $95D8  0E 1A
        JP $0005                         ; $95DA  C3 05 00
SUB_95DD:
        LD HL,L_9BAB                     ; $95DD  21 AB 9B
        LD A,(HL)                        ; $95E0  7E
        OR A                             ; $95E1  B7
        RET Z                            ; $95E2  C8
        LD (HL),$00                      ; $95E3  36 00
        XOR A                            ; $95E5  AF
        CALL SUB_94BD                    ; $95E6  CD BD 94
        LD DE,L_9BAC                     ; $95E9  11 AC 9B
        CALL SUB_94EF                    ; $95EC  CD EF 94
        LD A,(L_9BEF)                    ; $95EF  3A EF 9B
        JP SUB_94BD                      ; $95F2  C3 BD 94
SUB_95F5:
        LD DE,CCP_CMD_NAMES_END                     ; $95F5  11 28 97
        LD HL,BDOS_IMAGE_HEADER                     ; $95F8  21 00 9C
        LD B,$06                         ; $95FB  06 06
SUB_95F5_1:
        LD A,(DE)                        ; $95FD  1A
        CP (HL)                          ; $95FE  BE
        JP NZ,SUB_972E_9                 ; $95FF  C2 CF 97
        INC DE                           ; $9602  13
        INC HL                           ; $9603  23
        DEC B                            ; $9604  05
        JP NZ,SUB_95F5_1                 ; $9605  C2 FD 95
        RET                              ; $9608  C9
ECHO_TO_BLANK:
        CALL SUB_9498                    ; $9609  CD 98 94
        LD HL,(L_948A)                   ; $960C  2A 8A 94
SUB_9609_1:
        LD A,(HL)                        ; $960F  7E
        CP $20                           ; $9610  FE 20
        JP Z,PARSE_BADCHAR                  ; $9612  CA 22 96
        OR A                             ; $9615  B7
        JP Z,PARSE_BADCHAR                  ; $9616  CA 22 96
        PUSH HL                          ; $9619  E5
        CALL SUB_948C                    ; $961A  CD 8C 94
        POP HL                           ; $961D  E1
        INC HL                           ; $961E  23
        JP SUB_9609_1                    ; $961F  C3 0F 96
PARSE_BADCHAR:
        LD A,$3F                         ; $9622  3E 3F
        CALL SUB_948C                    ; $9624  CD 8C 94
        CALL SUB_9498                    ; $9627  CD 98 94
        CALL SUB_95DD                    ; $962A  CD DD 95
        JP SUB_972E_7                    ; $962D  C3 82 97
SCAN_DELIM:
        LD A,(DE)                        ; $9630  1A
        OR A                             ; $9631  B7
        RET Z                            ; $9632  C8
        CP $20                           ; $9633  FE 20
        JP C,ECHO_TO_BLANK                    ; $9635  DA 09 96
        RET Z                            ; $9638  C8
        CP $3D                           ; $9639  FE 3D
        RET Z                            ; $963B  C8
        CP $5F                           ; $963C  FE 5F
        RET Z                            ; $963E  C8
        CP $2E                           ; $963F  FE 2E
        RET Z                            ; $9641  C8
        CP $3A                           ; $9642  FE 3A
        RET Z                            ; $9644  C8
        CP $3B                           ; $9645  FE 3B
        RET Z                            ; $9647  C8
        CP $3C                           ; $9648  FE 3C
        RET Z                            ; $964A  C8
        CP $3E                           ; $964B  FE 3E
        RET Z                            ; $964D  C8
        RET                              ; $964E  C9
SKIP_ONE_BLANK:
        LD A,(DE)                        ; $964F  1A
        OR A                             ; $9650  B7
        RET Z                            ; $9651  C8
        CP $20                           ; $9652  FE 20
        RET NZ                           ; $9654  C0
        INC DE                           ; $9655  13
        JP SKIP_ONE_BLANK                      ; $9656  C3 4F 96
SUB_9659:
        ADD A,L                          ; $9659  85
        LD L,A                           ; $965A  6F
        RET NC                           ; $965B  D0
        INC H                            ; $965C  24
        RET                              ; $965D  C9
SUB_965E:
        LD A,$00                         ; $965E  3E 00
BUILD_FCB:
        LD HL,L_9BCD                     ; $9660  21 CD 9B
        CALL SUB_9659                    ; $9663  CD 59 96
        PUSH HL                          ; $9666  E5
        PUSH HL                          ; $9667  E5
        XOR A                            ; $9668  AF
        LD (L_9BF0),A                    ; $9669  32 F0 9B
        LD HL,(L_9488)                   ; $966C  2A 88 94
        EX DE,HL                         ; $966F  EB
        CALL SKIP_ONE_BLANK                    ; $9670  CD 4F 96
        EX DE,HL                         ; $9673  EB
        LD (L_948A),HL                   ; $9674  22 8A 94
        EX DE,HL                         ; $9677  EB
        POP HL                           ; $9678  E1
        LD A,(DE)                        ; $9679  1A
        OR A                             ; $967A  B7
        JP Z,SUB_9660_1                  ; $967B  CA 89 96
        SBC A,$40                        ; $967E  DE 40
        LD B,A                           ; $9680  47
        INC DE                           ; $9681  13
        LD A,(DE)                        ; $9682  1A
        CP $3A                           ; $9683  FE 3A
        JP Z,BUILD_FCB_NAME                  ; $9685  CA 90 96
        DEC DE                           ; $9688  1B
SUB_9660_1:
        LD A,(L_9BEF)                    ; $9689  3A EF 9B
        LD (HL),A                        ; $968C  77
        JP SUB_9660_3                    ; $968D  C3 96 96
BUILD_FCB_NAME:
        LD A,B                           ; $9690  78
        LD (L_9BF0),A                    ; $9691  32 F0 9B
        LD (HL),B                        ; $9694  70
        INC DE                           ; $9695  13
SUB_9660_3:
        LD B,$08                         ; $9696  06 08
SUB_9660_4:
        CALL SCAN_DELIM                    ; $9698  CD 30 96
        JP Z,BUILD_FCB_PAD                  ; $969B  CA B9 96
        INC HL                           ; $969E  23
        CP $2A                           ; $969F  FE 2A
        JP NZ,BUILD_FCB_NAME_CH                 ; $96A1  C2 A9 96
        LD (HL),$3F                      ; $96A4  36 3F
        JP SUB_9660_6                    ; $96A6  C3 AB 96
BUILD_FCB_NAME_CH:
        LD (HL),A                        ; $96A9  77
        INC DE                           ; $96AA  13
SUB_9660_6:
        DEC B                            ; $96AB  05
        JP NZ,SUB_9660_4                 ; $96AC  C2 98 96
SUB_9660_7:
        CALL SCAN_DELIM                    ; $96AF  CD 30 96
        JP Z,SUB_9660_9                  ; $96B2  CA C0 96
        INC DE                           ; $96B5  13
        JP SUB_9660_7                    ; $96B6  C3 AF 96
BUILD_FCB_PAD:
        INC HL                           ; $96B9  23
        LD (HL),$20                      ; $96BA  36 20
        DEC B                            ; $96BC  05
        JP NZ,BUILD_FCB_PAD                 ; $96BD  C2 B9 96
SUB_9660_9:
        LD B,$03                         ; $96C0  06 03
        CP $2E                           ; $96C2  FE 2E
        JP NZ,BUILD_FCB_EXT_PAD                ; $96C4  C2 E9 96
        INC DE                           ; $96C7  13
SUB_9660_10:
        CALL SCAN_DELIM                    ; $96C8  CD 30 96
        JP Z,BUILD_FCB_EXT_PAD                 ; $96CB  CA E9 96
        INC HL                           ; $96CE  23
        CP $2A                           ; $96CF  FE 2A
        JP NZ,BUILD_FCB_EXT_CH                ; $96D1  C2 D9 96
        LD (HL),$3F                      ; $96D4  36 3F
        JP SUB_9660_12                   ; $96D6  C3 DB 96
BUILD_FCB_EXT_CH:
        LD (HL),A                        ; $96D9  77
        INC DE                           ; $96DA  13
SUB_9660_12:
        DEC B                            ; $96DB  05
        JP NZ,SUB_9660_10                ; $96DC  C2 C8 96
SUB_9660_13:
        CALL SCAN_DELIM                    ; $96DF  CD 30 96
        JP Z,SUB_9660_15                 ; $96E2  CA F0 96
        INC DE                           ; $96E5  13
        JP SUB_9660_13                   ; $96E6  C3 DF 96
BUILD_FCB_EXT_PAD:
        INC HL                           ; $96E9  23
        LD (HL),$20                      ; $96EA  36 20
        DEC B                            ; $96EC  05
        JP NZ,BUILD_FCB_EXT_PAD                ; $96ED  C2 E9 96
SUB_9660_15:
        LD B,$03                         ; $96F0  06 03
SUB_9660_16:
        INC HL                           ; $96F2  23
        LD (HL),$00                      ; $96F3  36 00
        DEC B                            ; $96F5  05
        JP NZ,SUB_9660_16                ; $96F6  C2 F2 96
        EX DE,HL                         ; $96F9  EB
        LD (L_9488),HL                   ; $96FA  22 88 94
        POP HL                           ; $96FD  E1
        LD BC,$000B                      ; $96FE  01 0B 00
FCB_WILDCARD_NEXT:
        INC HL                           ; $9701  23
        LD A,(HL)                        ; $9702  7E
        CP $3F                           ; $9703  FE 3F
        JP NZ,FCB_WILDCARD_CMP_C                ; $9705  C2 09 97
        INC B                            ; $9708  04
FCB_WILDCARD_CMP_C:
        DEC C                            ; $9709  0D
        JP NZ,FCB_WILDCARD_NEXT                ; $970A  C2 01 97
        LD A,B                           ; $970D  78
        OR A                             ; $970E  B7
        RET                              ; $970F  C9
L_9710:
        DEFB    "DIR ERA TYPESAVEREN USER"    ; $9710  string
CCP_CMD_NAMES_END:
        DEFB    $BD,$16,$00,$00,$16,$DF                          ; $9728
SUB_972E:
        LD HL,L_9710                     ; $972E  21 10 97
        LD C,$00                         ; $9731  0E 00
SUB_972E_1:
        LD A,C                           ; $9733  79
        CP $06                           ; $9734  FE 06
        RET NC                           ; $9736  D0
        LD DE,L_9BCE                     ; $9737  11 CE 9B
        LD B,$04                         ; $973A  06 04
SUB_972E_2:
        LD A,(DE)                        ; $973C  1A
        CP (HL)                          ; $973D  BE
        JP NZ,SEARCH_BUILTIN_2                 ; $973E  C2 4F 97
        INC DE                           ; $9741  13
        INC HL                           ; $9742  23
        DEC B                            ; $9743  05
        JP NZ,SUB_972E_2                 ; $9744  C2 3C 97
        LD A,(DE)                        ; $9747  1A
        CP $20                           ; $9748  FE 20
        JP NZ,SUB_972E_4                 ; $974A  C2 54 97
        LD A,C                           ; $974D  79
        RET                              ; $974E  C9
SEARCH_BUILTIN_2:
        INC HL                           ; $974F  23
        DEC B                            ; $9750  05
        JP NZ,SEARCH_BUILTIN_2                 ; $9751  C2 4F 97
SUB_972E_4:
        INC C                            ; $9754  0C
        JP SUB_972E_1                    ; $9755  C3 33 97
CCP_MAIN_LOOP:
        XOR A                            ; $9758  AF
        LD (L_9407),A                    ; $9759  32 07 94
SUB_972E_6:
        LD SP,L_9BAB                     ; $975C  31 AB 9B
        PUSH BC                          ; $975F  C5
        LD A,C                           ; $9760  79
        RRA                              ; $9761  1F
        RRA                              ; $9762  1F
        RRA                              ; $9763  1F
        RRA                              ; $9764  1F
        AND $0F                          ; $9765  E6 0F
        LD E,A                           ; $9767  5F
        CALL SUB_9515                    ; $9768  CD 15 95
        CALL SUB_94B8                    ; $976B  CD B8 94
        LD (L_9BAB),A                    ; $976E  32 AB 9B
        POP BC                           ; $9771  C1
        LD A,C                           ; $9772  79
        AND $0F                          ; $9773  E6 0F
        LD (L_9BEF),A                    ; $9775  32 EF 9B
        CALL SUB_94BD                    ; $9778  CD BD 94
        LD A,(L_9407)                    ; $977B  3A 07 94
        OR A                             ; $977E  B7
        JP NZ,SUB_972E_8                 ; $977F  C2 98 97
SUB_972E_7:
        LD SP,L_9BAB                     ; $9782  31 AB 9B
        CALL SUB_9498                    ; $9785  CD 98 94
        CALL SUB_95D0                    ; $9788  CD D0 95
        ADD A,$41                        ; $978B  C6 41
        CALL SUB_948C                    ; $978D  CD 8C 94
        LD A,$3E                         ; $9790  3E 3E
        CALL SUB_948C                    ; $9792  CD 8C 94
        CALL SUB_9539                    ; $9795  CD 39 95
SUB_972E_8:
        LD DE,$0080                      ; $9798  11 80 00
        CALL SUB_95D8                    ; $979B  CD D8 95
        CALL SUB_95D0                    ; $979E  CD D0 95
        LD (L_9BEF),A                    ; $97A1  32 EF 9B
        CALL SUB_965E                    ; $97A4  CD 5E 96
        CALL NZ,ECHO_TO_BLANK                 ; $97A7  C4 09 96
        LD A,(L_9BF0)                    ; $97AA  3A F0 9B
        OR A                             ; $97AD  B7
        JP NZ,CMD_EXEC_49                ; $97AE  C2 A5 9A
        CALL SUB_972E                    ; $97B1  CD 2E 97
        LD HL,L_97C1                     ; $97B4  21 C1 97
        LD E,A                           ; $97B7  5F
        LD D,$00                         ; $97B8  16 00
        ADD HL,DE                        ; $97BA  19
        ADD HL,DE                        ; $97BB  19
        LD A,(HL)                        ; $97BC  7E
        INC HL                           ; $97BD  23
        LD H,(HL)                        ; $97BE  66
        LD L,A                           ; $97BF  6F
        JP (HL)                          ; $97C0  E9
L_97C1:
        DEFW    DIR_CMD               ; $97C1
        DEFW    ERA_CMD              ; $97C3
        DEFW    PRINT_STR_AT              ; $97C5
        DEFW    CMD_EXEC_4              ; $97C7
        DEFW    CMD_EXEC_42              ; $97C9
        DEFW    CMD_EXEC_48              ; $97CB
        DEFW    CMD_EXEC_49              ; $97CD
SUB_972E_9:
        LD HL,$76F3                      ; $97CF  21 F3 76
        LD (L_9400),HL                   ; $97D2  22 00 94
        LD HL,L_9400                     ; $97D5  21 00 94
        JP (HL)                          ; $97D8  E9
SUB_97D9:
        LD BC,L_97DF                     ; $97D9  01 DF 97
        JP SUB_94A7                      ; $97DC  C3 A7 94
L_97DF:
        DEFB    "READ ERROR"    ; $97DF  string
        DEFB    $00    ; $97E9  terminator
SUB_97EA:
        LD BC,L_97F0                     ; $97EA  01 F0 97
        JP SUB_94A7                      ; $97ED  C3 A7 94
L_97F0:
        DEFB    "NO FILE"    ; $97F0  string
        DEFB    $00    ; $97F7  terminator
SUB_97F8:
        CALL SUB_965E                    ; $97F8  CD 5E 96
        LD A,(L_9BF0)                    ; $97FB  3A F0 9B
        OR A                             ; $97FE  B7
        JP NZ,ECHO_TO_BLANK                   ; $97FF  C2 09 96
        LD HL,L_9BCE                     ; $9802  21 CE 9B
        LD BC,$000B                      ; $9805  01 0B 00
SUB_97F8_1:
        LD A,(HL)                        ; $9808  7E
        CP $20                           ; $9809  FE 20
        JP Z,FCB_FIELD_BLANKS                  ; $980B  CA 33 98
        INC HL                           ; $980E  23
        SUB $30                          ; $980F  D6 30
        CP $0A                           ; $9811  FE 0A
        JP NC,ECHO_TO_BLANK                   ; $9813  D2 09 96
        LD D,A                           ; $9816  57
        LD A,B                           ; $9817  78
        AND $E0                          ; $9818  E6 E0
        JP NZ,ECHO_TO_BLANK                   ; $981A  C2 09 96
        LD A,B                           ; $981D  78
        RLCA                             ; $981E  07
        RLCA                             ; $981F  07
        RLCA                             ; $9820  07
        ADD A,B                          ; $9821  80
        JP C,ECHO_TO_BLANK                    ; $9822  DA 09 96
        ADD A,B                          ; $9825  80
        JP C,ECHO_TO_BLANK                    ; $9826  DA 09 96
        ADD A,D                          ; $9829  82
        JP C,ECHO_TO_BLANK                    ; $982A  DA 09 96
        LD B,A                           ; $982D  47
        DEC C                            ; $982E  0D
        JP NZ,SUB_97F8_1                 ; $982F  C2 08 98
        RET                              ; $9832  C9
FCB_FIELD_BLANKS:
        LD A,(HL)                        ; $9833  7E
        CP $20                           ; $9834  FE 20
        JP NZ,ECHO_TO_BLANK                   ; $9836  C2 09 96
        INC HL                           ; $9839  23
        DEC C                            ; $983A  0D
        JP NZ,FCB_FIELD_BLANKS                 ; $983B  C2 33 98
        LD A,B                           ; $983E  78
        RET                              ; $983F  C9
COPY_FCB_EXT:
        LD B,$03                         ; $9840  06 03
SUB_9842:
        LD A,(HL)                        ; $9842  7E
        LD (DE),A                        ; $9843  12
        INC HL                           ; $9844  23
        INC DE                           ; $9845  13
        DEC B                            ; $9846  05
        JP NZ,SUB_9842                   ; $9847  C2 42 98
        RET                              ; $984A  C9
TBUFF_INDEX_FETCH:
        LD HL,$0080                      ; $984B  21 80 00
        ADD A,C                          ; $984E  81
        CALL SUB_9659                    ; $984F  CD 59 96
        LD A,(HL)                        ; $9852  7E
        RET                              ; $9853  C9
RESOLVE_DRIVE_PREFIX:
        XOR A                            ; $9854  AF
        LD (L_9BCD),A                    ; $9855  32 CD 9B
        LD A,(L_9BF0)                    ; $9858  3A F0 9B
        OR A                             ; $985B  B7
        RET Z                            ; $985C  C8
        DEC A                            ; $985D  3D
        LD HL,L_9BEF                     ; $985E  21 EF 9B
        CP (HL)                          ; $9861  BE
        RET Z                            ; $9862  C8
        JP SUB_94BD                      ; $9863  C3 BD 94
RESOLVE_DRIVE_PREFIX_2:
        LD A,(L_9BF0)                    ; $9866  3A F0 9B
        OR A                             ; $9869  B7
        RET Z                            ; $986A  C8
        DEC A                            ; $986B  3D
        LD HL,L_9BEF                     ; $986C  21 EF 9B
        CP (HL)                          ; $986F  BE
        RET Z                            ; $9870  C8
        LD A,(L_9BEF)                    ; $9871  3A EF 9B
        JP SUB_94BD                      ; $9874  C3 BD 94
DIR_CMD:
        CALL SUB_965E                    ; $9877  CD 5E 96
        CALL RESOLVE_DRIVE_PREFIX                    ; $987A  CD 54 98
        LD HL,L_9BCE                     ; $987D  21 CE 9B
        LD A,(HL)                        ; $9880  7E
        CP $20                           ; $9881  FE 20
        JP NZ,SUB_9866_3                 ; $9883  C2 8F 98
        LD B,$0B                         ; $9886  06 0B
SUB_9866_2:
        LD (HL),$3F                      ; $9888  36 3F
        INC HL                           ; $988A  23
        DEC B                            ; $988B  05
        JP NZ,SUB_9866_2                 ; $988C  C2 88 98
SUB_9866_3:
        LD E,$00                         ; $988F  1E 00
        PUSH DE                          ; $9891  D5
        CALL SUB_94E9                    ; $9892  CD E9 94
        CALL Z,SUB_97EA                  ; $9895  CC EA 97
DIR_CMD_2:
        JP Z,DIR_EXIT                 ; $9898  CA 1B 99
        LD A,(L_9BEE)                    ; $989B  3A EE 9B
        RRCA                             ; $989E  0F
        RRCA                             ; $989F  0F
        RRCA                             ; $98A0  0F
        AND $60                          ; $98A1  E6 60
        LD C,A                           ; $98A3  4F
        LD A,$0A                         ; $98A4  3E 0A
        CALL TBUFF_INDEX_FETCH                    ; $98A6  CD 4B 98
        RLA                              ; $98A9  17
        JP C,SUB_9866_11                 ; $98AA  DA 0F 99
        POP DE                           ; $98AD  D1
        LD A,E                           ; $98AE  7B
        INC E                            ; $98AF  1C
        PUSH DE                          ; $98B0  D5
        AND $01                          ; $98B1  E6 01
        PUSH AF                          ; $98B3  F5
        JP NZ,DIR_FMT_ENTRY_COLS                 ; $98B4  C2 CC 98
        CALL SUB_9498                    ; $98B7  CD 98 94
        PUSH BC                          ; $98BA  C5
        CALL SUB_95D0                    ; $98BB  CD D0 95
        POP BC                           ; $98BE  C1
        ADD A,$41                        ; $98BF  C6 41
        CALL SUB_9492                    ; $98C1  CD 92 94
        LD A,$3A                         ; $98C4  3E 3A
        CALL SUB_9492                    ; $98C6  CD 92 94
        JP SUB_9866_6                    ; $98C9  C3 D4 98
DIR_FMT_ENTRY_COLS:
        CALL SUB_94A2                    ; $98CC  CD A2 94
        LD A,$3A                         ; $98CF  3E 3A
        CALL SUB_9492                    ; $98D1  CD 92 94
SUB_9866_6:
        CALL SUB_94A2                    ; $98D4  CD A2 94
        LD B,$01                         ; $98D7  06 01
DIR_EMIT_NAME_CHAR:
        LD A,B                           ; $98D9  78
        CALL TBUFF_INDEX_FETCH                    ; $98DA  CD 4B 98
        AND $7F                          ; $98DD  E6 7F
        CP $20                           ; $98DF  FE 20
        JP NZ,SUB_9866_9                 ; $98E1  C2 F9 98
        POP AF                           ; $98E4  F1
        PUSH AF                          ; $98E5  F5
        CP $03                           ; $98E6  FE 03
        JP NZ,DIR_EMIT_NAME_CHAR_2                 ; $98E8  C2 F7 98
        LD A,$09                         ; $98EB  3E 09
        CALL TBUFF_INDEX_FETCH                    ; $98ED  CD 4B 98
        AND $7F                          ; $98F0  E6 7F
        CP $20                           ; $98F2  FE 20
        JP Z,DIR_SEARCH_NEXT                 ; $98F4  CA 0E 99
DIR_EMIT_NAME_CHAR_2:
        LD A,$20                         ; $98F7  3E 20
SUB_9866_9:
        CALL SUB_9492                    ; $98F9  CD 92 94
        INC B                            ; $98FC  04
        LD A,B                           ; $98FD  78
        CP $0C                           ; $98FE  FE 0C
        JP NC,DIR_SEARCH_NEXT                ; $9900  D2 0E 99
        CP $09                           ; $9903  FE 09
        JP NZ,DIR_EMIT_NAME_CHAR                 ; $9905  C2 D9 98
        CALL SUB_94A2                    ; $9908  CD A2 94
        JP DIR_EMIT_NAME_CHAR                    ; $990B  C3 D9 98
DIR_SEARCH_NEXT:
        POP AF                           ; $990E  F1
SUB_9866_11:
        CALL SUB_95C2                    ; $990F  CD C2 95
        JP NZ,DIR_EXIT                ; $9912  C2 1B 99
        CALL SUB_94E4                    ; $9915  CD E4 94
        JP DIR_CMD_2                    ; $9918  C3 98 98
DIR_EXIT:
        POP DE                           ; $991B  D1
        JP SUB_9866_42                   ; $991C  C3 86 9B
ERA_CMD:
        CALL SUB_965E                    ; $991F  CD 5E 96
        CP $0B                           ; $9922  FE 0B
        JP NZ,CCP_NEWLINE_AND_FILEOP                ; $9924  C2 42 99
        LD BC,L_9952                     ; $9927  01 52 99
        CALL SUB_94A7                    ; $992A  CD A7 94
        CALL SUB_9539                    ; $992D  CD 39 95
        LD HL,L_9407                     ; $9930  21 07 94
        DEC (HL)                         ; $9933  35
        JP NZ,SUB_972E_7                 ; $9934  C2 82 97
        INC HL                           ; $9937  23
        LD A,(HL)                        ; $9938  7E
        CP $59                           ; $9939  FE 59
        JP NZ,SUB_972E_7                 ; $993B  C2 82 97
        INC HL                           ; $993E  23
        LD (L_9488),HL                   ; $993F  22 88 94
CCP_NEWLINE_AND_FILEOP:
        CALL RESOLVE_DRIVE_PREFIX                    ; $9942  CD 54 98
        LD DE,L_9BCD                     ; $9945  11 CD 9B
        CALL SUB_94EF                    ; $9948  CD EF 94
        INC A                            ; $994B  3C
        CALL Z,SUB_97EA                  ; $994C  CC EA 97
        JP SUB_9866_42                   ; $994F  C3 86 9B
L_9952:
        DEFB    "ALL (Y/N)?"    ; $9952  string
        DEFB    $00    ; $995C  terminator
PRINT_STR_AT:
        CALL SUB_965E                    ; $995D  CD 5E 96
        JP NZ,ECHO_TO_BLANK                   ; $9960  C2 09 96
        CALL RESOLVE_DRIVE_PREFIX                    ; $9963  CD 54 98
        CALL SUB_94D0                    ; $9966  CD D0 94
        JP Z,SUB_9866_19                 ; $9969  CA A7 99
        CALL SUB_9498                    ; $996C  CD 98 94
        LD HL,L_9BF1                     ; $996F  21 F1 9B
        LD (HL),$FF                      ; $9972  36 FF
SUB_9866_16:
        LD HL,L_9BF1                     ; $9974  21 F1 9B
        LD A,(HL)                        ; $9977  7E
        CP $80                           ; $9978  FE 80
        JP C,SUB_9866_17                 ; $997A  DA 87 99
        PUSH HL                          ; $997D  E5
        CALL SUB_94FE                    ; $997E  CD FE 94
        POP HL                           ; $9981  E1
        JP NZ,CMD_EXEC_3                ; $9982  C2 A0 99
        XOR A                            ; $9985  AF
        LD (HL),A                        ; $9986  77
SUB_9866_17:
        INC (HL)                         ; $9987  34
        LD HL,$0080                      ; $9988  21 80 00
        CALL SUB_9659                    ; $998B  CD 59 96
        LD A,(HL)                        ; $998E  7E
        CP $1A                           ; $998F  FE 1A
        JP Z,SUB_9866_42                 ; $9991  CA 86 9B
        CALL SUB_948C                    ; $9994  CD 8C 94
        CALL SUB_95C2                    ; $9997  CD C2 95
        JP NZ,SUB_9866_42                ; $999A  C2 86 9B
        JP SUB_9866_16                   ; $999D  C3 74 99
CMD_EXEC_3:
        DEC A                            ; $99A0  3D
        JP Z,SUB_9866_42                 ; $99A1  CA 86 9B
        CALL SUB_97D9                    ; $99A4  CD D9 97
SUB_9866_19:
        CALL RESOLVE_DRIVE_PREFIX_2                    ; $99A7  CD 66 98
        JP ECHO_TO_BLANK                      ; $99AA  C3 09 96
CMD_EXEC_4:
        CALL SUB_97F8                    ; $99AD  CD F8 97
        PUSH AF                          ; $99B0  F5
        CALL SUB_965E                    ; $99B1  CD 5E 96
        JP NZ,ECHO_TO_BLANK                   ; $99B4  C2 09 96
        CALL RESOLVE_DRIVE_PREFIX                    ; $99B7  CD 54 98
        LD DE,L_9BCD                     ; $99BA  11 CD 9B
        PUSH DE                          ; $99BD  D5
        CALL SUB_94EF                    ; $99BE  CD EF 94
        POP DE                           ; $99C1  D1
        CALL SUB_9509                    ; $99C2  CD 09 95
        JP Z,SUB_9866_23                 ; $99C5  CA FB 99
        XOR A                            ; $99C8  AF
        LD (L_9BED),A                    ; $99C9  32 ED 9B
        POP AF                           ; $99CC  F1
        LD L,A                           ; $99CD  6F
        LD H,$00                         ; $99CE  26 00
        ADD HL,HL                        ; $99D0  29
        LD DE,$0100                      ; $99D1  11 00 01
CMD_EXEC_6:
        LD A,H                           ; $99D4  7C
        OR L                             ; $99D5  B5
        JP Z,CMD_EXEC_8                 ; $99D6  CA F1 99
        DEC HL                           ; $99D9  2B
        PUSH HL                          ; $99DA  E5
        LD HL,$0080                      ; $99DB  21 80 00
        ADD HL,DE                        ; $99DE  19
        PUSH HL                          ; $99DF  E5
        CALL SUB_95D8                    ; $99E0  CD D8 95
        LD DE,L_9BCD                     ; $99E3  11 CD 9B
        CALL SUB_9504                    ; $99E6  CD 04 95
        POP DE                           ; $99E9  D1
        POP HL                           ; $99EA  E1
        JP NZ,SUB_9866_23                ; $99EB  C2 FB 99
        JP CMD_EXEC_6                   ; $99EE  C3 D4 99
CMD_EXEC_8:
        LD DE,L_9BCD                     ; $99F1  11 CD 9B
        CALL SUB_94DA                    ; $99F4  CD DA 94
        INC A                            ; $99F7  3C
        JP NZ,SUB_9866_24                ; $99F8  C2 01 9A
SUB_9866_23:
        LD BC,L_9A07                     ; $99FB  01 07 9A
        CALL SUB_94A7                    ; $99FE  CD A7 94
SUB_9866_24:
        CALL SUB_95D5                    ; $9A01  CD D5 95
        JP SUB_9866_42                   ; $9A04  C3 86 9B
L_9A07:
        DEFB    "NO SPACE"    ; $9A07  string
        DEFB    $00    ; $9A0F  terminator
CMD_EXEC_42:
        CALL SUB_965E                    ; $9A10  CD 5E 96
        JP NZ,ECHO_TO_BLANK                   ; $9A13  C2 09 96
        LD A,(L_9BF0)                    ; $9A16  3A F0 9B
        PUSH AF                          ; $9A19  F5
        CALL RESOLVE_DRIVE_PREFIX                    ; $9A1A  CD 54 98
        CALL SUB_94E9                    ; $9A1D  CD E9 94
        JP NZ,CMD_EXEC_47                ; $9A20  C2 79 9A
        LD HL,L_9BCD                     ; $9A23  21 CD 9B
        LD DE,L_9BDD                     ; $9A26  11 DD 9B
        LD B,$10                         ; $9A29  06 10
        CALL SUB_9842                    ; $9A2B  CD 42 98
        LD HL,(L_9488)                   ; $9A2E  2A 88 94
        EX DE,HL                         ; $9A31  EB
        CALL SKIP_ONE_BLANK                    ; $9A32  CD 4F 96
        CP $3D                           ; $9A35  FE 3D
        JP Z,CMD_EXEC_43                 ; $9A37  CA 3F 9A
        CP $5F                           ; $9A3A  FE 5F
        JP NZ,CMD_EXEC_46                ; $9A3C  C2 73 9A
CMD_EXEC_43:
        EX DE,HL                         ; $9A3F  EB
        INC HL                           ; $9A40  23
        LD (L_9488),HL                   ; $9A41  22 88 94
        CALL SUB_965E                    ; $9A44  CD 5E 96
        JP NZ,CMD_EXEC_46                ; $9A47  C2 73 9A
        POP AF                           ; $9A4A  F1
        LD B,A                           ; $9A4B  47
        LD HL,L_9BF0                     ; $9A4C  21 F0 9B
        LD A,(HL)                        ; $9A4F  7E
        OR A                             ; $9A50  B7
        JP Z,CMD_EXEC_44                 ; $9A51  CA 59 9A
        CP B                             ; $9A54  B8
        LD (HL),B                        ; $9A55  70
        JP NZ,CMD_EXEC_46                ; $9A56  C2 73 9A
CMD_EXEC_44:
        LD (HL),B                        ; $9A59  70
        XOR A                            ; $9A5A  AF
        LD (L_9BCD),A                    ; $9A5B  32 CD 9B
        CALL SUB_94E9                    ; $9A5E  CD E9 94
        JP Z,CMD_EXEC_45                 ; $9A61  CA 6D 9A
        LD DE,L_9BCD                     ; $9A64  11 CD 9B
        CALL SUB_950E                    ; $9A67  CD 0E 95
        JP SUB_9866_42                   ; $9A6A  C3 86 9B
CMD_EXEC_45:
        CALL SUB_97EA                    ; $9A6D  CD EA 97
        JP SUB_9866_42                   ; $9A70  C3 86 9B
CMD_EXEC_46:
        CALL RESOLVE_DRIVE_PREFIX_2                    ; $9A73  CD 66 98
        JP ECHO_TO_BLANK                      ; $9A76  C3 09 96
CMD_EXEC_47:
        LD BC,L_9A82                     ; $9A79  01 82 9A
        CALL SUB_94A7                    ; $9A7C  CD A7 94
        JP SUB_9866_42                   ; $9A7F  C3 86 9B
L_9A82:
        DEFB    "FILE EXISTS"    ; $9A82  string
        DEFB    $00    ; $9A8D  terminator
CMD_EXEC_48:
        CALL SUB_97F8                    ; $9A8E  CD F8 97
        CP $10                           ; $9A91  FE 10
        JP NC,ECHO_TO_BLANK                   ; $9A93  D2 09 96
        LD E,A                           ; $9A96  5F
        LD A,(L_9BCE)                    ; $9A97  3A CE 9B
        CP $20                           ; $9A9A  FE 20
        JP Z,ECHO_TO_BLANK                    ; $9A9C  CA 09 96
        CALL SUB_9515                    ; $9A9F  CD 15 95
        JP SUB_9866_43                   ; $9AA2  C3 89 9B
CMD_EXEC_49:
        CALL SUB_95F5                    ; $9AA5  CD F5 95
        LD A,(L_9BCE)                    ; $9AA8  3A CE 9B
        CP $20                           ; $9AAB  FE 20
        JP NZ,CMD_EXEC_50                ; $9AAD  C2 C4 9A
        LD A,(L_9BF0)                    ; $9AB0  3A F0 9B
        OR A                             ; $9AB3  B7
        JP Z,SUB_9866_43                 ; $9AB4  CA 89 9B
        DEC A                            ; $9AB7  3D
        LD (L_9BEF),A                    ; $9AB8  32 EF 9B
        CALL SUB_9529                    ; $9ABB  CD 29 95
        CALL SUB_94BD                    ; $9ABE  CD BD 94
        JP SUB_9866_43                   ; $9AC1  C3 89 9B
CMD_EXEC_50:
        LD DE,L_9BD6                     ; $9AC4  11 D6 9B
        LD A,(DE)                        ; $9AC7  1A
        CP $20                           ; $9AC8  FE 20
        JP NZ,ECHO_TO_BLANK                   ; $9ACA  C2 09 96
        PUSH DE                          ; $9ACD  D5
        CALL RESOLVE_DRIVE_PREFIX                    ; $9ACE  CD 54 98
        POP DE                           ; $9AD1  D1
        LD HL,L_9B83                     ; $9AD2  21 83 9B
        CALL COPY_FCB_EXT                    ; $9AD5  CD 40 98
        CALL SUB_94D0                    ; $9AD8  CD D0 94
        JP Z,SUB_9866_40                 ; $9ADB  CA 6B 9B
        LD HL,$0100                      ; $9ADE  21 00 01
SUB_9866_34:
        PUSH HL                          ; $9AE1  E5
        EX DE,HL                         ; $9AE2  EB
        CALL SUB_95D8                    ; $9AE3  CD D8 95
        LD DE,L_9BCD                     ; $9AE6  11 CD 9B
        CALL SUB_94F9                    ; $9AE9  CD F9 94
        JP NZ,CCP_TAIL_LOADRET                ; $9AEC  C2 01 9B
        POP HL                           ; $9AEF  E1
        LD DE,$0080                      ; $9AF0  11 80 00
        ADD HL,DE                        ; $9AF3  19
        LD DE,L_9400                     ; $9AF4  11 00 94
        LD A,L                           ; $9AF7  7D
        SUB E                            ; $9AF8  93
        LD A,H                           ; $9AF9  7C
        SBC A,D                          ; $9AFA  9A
        JP NC,SUB_9866_41                ; $9AFB  D2 71 9B
        JP SUB_9866_34                   ; $9AFE  C3 E1 9A
CCP_TAIL_LOADRET:
        POP HL                           ; $9B01  E1
        DEC A                            ; $9B02  3D
        JP NZ,SUB_9866_41                ; $9B03  C2 71 9B
        CALL RESOLVE_DRIVE_PREFIX_2                    ; $9B06  CD 66 98
        CALL SUB_965E                    ; $9B09  CD 5E 96
        LD HL,L_9BF0                     ; $9B0C  21 F0 9B
        PUSH HL                          ; $9B0F  E5
        LD A,(HL)                        ; $9B10  7E
        LD (L_9BCD),A                    ; $9B11  32 CD 9B
        LD A,$10                         ; $9B14  3E 10
        CALL BUILD_FCB                    ; $9B16  CD 60 96
        POP HL                           ; $9B19  E1
        LD A,(HL)                        ; $9B1A  7E
        LD (L_9BDD),A                    ; $9B1B  32 DD 9B
        XOR A                            ; $9B1E  AF
        LD (L_9BED),A                    ; $9B1F  32 ED 9B
        LD DE,$005C                      ; $9B22  11 5C 00
        LD HL,L_9BCD                     ; $9B25  21 CD 9B
        LD B,$21                         ; $9B28  06 21
        CALL SUB_9842                    ; $9B2A  CD 42 98
        LD HL,L_9408                     ; $9B2D  21 08 94
SUB_9866_36:
        LD A,(HL)                        ; $9B30  7E
        OR A                             ; $9B31  B7
        JP Z,CCP_TAIL_CMDTAIL                 ; $9B32  CA 3E 9B
        CP $20                           ; $9B35  FE 20
        JP Z,CCP_TAIL_CMDTAIL                 ; $9B37  CA 3E 9B
        INC HL                           ; $9B3A  23
        JP SUB_9866_36                   ; $9B3B  C3 30 9B
CCP_TAIL_CMDTAIL:
        LD B,$00                         ; $9B3E  06 00
        LD DE,$0081                      ; $9B40  11 81 00
SUB_9866_38:
        LD A,(HL)                        ; $9B43  7E
        LD (DE),A                        ; $9B44  12
        OR A                             ; $9B45  B7
        JP Z,SUB_9866_39                 ; $9B46  CA 4F 9B
        INC B                            ; $9B49  04
        INC HL                           ; $9B4A  23
        INC DE                           ; $9B4B  13
        JP SUB_9866_38                   ; $9B4C  C3 43 9B
SUB_9866_39:
        LD A,B                           ; $9B4F  78
        LD ($0080),A                     ; $9B50  32 80 00
        CALL SUB_9498                    ; $9B53  CD 98 94
        CALL SUB_95D5                    ; $9B56  CD D5 95
        CALL SUB_951A                    ; $9B59  CD 1A 95
        CALL $0100                       ; $9B5C  CD 00 01
        LD SP,L_9BAB                     ; $9B5F  31 AB 9B
        CALL SUB_9529                    ; $9B62  CD 29 95
        CALL SUB_94BD                    ; $9B65  CD BD 94
        JP SUB_972E_7                    ; $9B68  C3 82 97
SUB_9866_40:
        CALL RESOLVE_DRIVE_PREFIX_2                    ; $9B6B  CD 66 98
        JP ECHO_TO_BLANK                      ; $9B6E  C3 09 96
SUB_9866_41:
        LD BC,L_9B7A                     ; $9B71  01 7A 9B
        CALL SUB_94A7                    ; $9B74  CD A7 94
        JP SUB_9866_42                   ; $9B77  C3 86 9B
L_9B7A:
        DEFB    "BAD LOAD"    ; $9B7A  string
        DEFB    $00    ; $9B82  terminator
L_9B83:
        DEFB    "COM"    ; $9B83
SUB_9866_42:
        CALL RESOLVE_DRIVE_PREFIX_2                    ; $9B86  CD 66 98
SUB_9866_43:
        CALL SUB_965E                    ; $9B89  CD 5E 96
        LD A,(L_9BCE)                    ; $9B8C  3A CE 9B
        SUB $20                          ; $9B8F  D6 20
        LD HL,L_9BF0                     ; $9B91  21 F0 9B
        OR (HL)                          ; $9B94  B6
        JP NZ,ECHO_TO_BLANK                   ; $9B95  C2 09 96
        JP SUB_972E_7                    ; $9B98  C3 82 97
        DEFS    16, $00    ; $9B9B  fill
L_9BAB:
        DEFB    "\0"    ; $9BAB
L_9BAC:
        DEFB    "\0"    ; $9BAC
        DEFB    "$$$     SUB"    ; $9BAD  string
        DEFB    $00    ; $9BB8  terminator
        DEFB    "\0"    ; $9BB9
L_9BBA:
        DEFB    "\0"    ; $9BBA
L_9BBB:
        DEFS    17, $00    ; $9BBB  fill
L_9BCC:
        DEFB    "\0"    ; $9BCC
L_9BCD:
        DEFB    "\0"    ; $9BCD
L_9BCE:
        DEFS    8, $00    ; $9BCE  fill
L_9BD6:
        DEFB    "\0\0\0\0\0\0\0"    ; $9BD6
L_9BDD:
        DEFS    16, $00    ; $9BDD  fill
L_9BED:
        DEFB    "\0"    ; $9BED
L_9BEE:
        DEFB    "\0"    ; $9BEE
L_9BEF:
        DEFB    "\0"    ; $9BEF
L_9BF0:
        DEFB    "\0"    ; $9BF0
L_9BF1:
        DEFS    15, $00    ; $9BF1  fill
BDOS_IMAGE_HEADER:
        DEFB    $BD,$16,$00,$00,$16,$DF                          ; $9C00
BDOS_ENTRY:
        JP BDOS_DISPATCH                   ; $9C06  C3 11 9C
BDOS_ERR_VECTORS:
        SBC A,C                          ; $9C09  99
        SBC A,H                          ; $9C0A  9C
SUB_9866_46:
        AND L                            ; $9C0B  A5
        SBC A,H                          ; $9C0C  9C
SUB_9866_47:
        XOR E                            ; $9C0D  AB
        SBC A,H                          ; $9C0E  9C
SUB_9866_48:
        OR C                             ; $9C0F  B1
        SBC A,H                          ; $9C10  9C
BDOS_DISPATCH:
        EX DE,HL                         ; $9C11  EB
        LD (L_9F43),HL                   ; $9C12  22 43 9F
        EX DE,HL                         ; $9C15  EB
        LD A,E                           ; $9C16  7B
        LD (L_A9D6),A                    ; $9C17  32 D6 A9
        LD HL,$0000                      ; $9C1A  21 00 00
        LD (L_9F45),HL                   ; $9C1D  22 45 9F
        ADD HL,SP                        ; $9C20  39
        LD (L_9F0F),HL                   ; $9C21  22 0F 9F
        LD SP,L_9F41                     ; $9C24  31 41 9F
        XOR A                            ; $9C27  AF
        LD (L_A9E0),A                    ; $9C28  32 E0 A9
        LD (L_A9DE),A                    ; $9C2B  32 DE A9
        LD HL,DIR_NAME_MASK_38                ; $9C2E  21 74 A9
        PUSH HL                          ; $9C31  E5
        LD A,C                           ; $9C32  79
        CP $29                           ; $9C33  FE 29
        RET NC                           ; $9C35  D0
        LD C,E                           ; $9C36  4B
        LD HL,BDOS_DISPATCH_TBL                     ; $9C37  21 47 9C
        LD E,A                           ; $9C3A  5F
        LD D,$00                         ; $9C3B  16 00
        ADD HL,DE                        ; $9C3D  19
        ADD HL,DE                        ; $9C3E  19
        LD E,(HL)                        ; $9C3F  5E
        INC HL                           ; $9C40  23
        LD D,(HL)                        ; $9C41  56
        LD HL,(L_9F43)                   ; $9C42  2A 43 9F
        EX DE,HL                         ; $9C45  EB
        JP (HL)                          ; $9C46  E9
BDOS_DISPATCH_TBL:
        DEFW    $AA03                    ; $9C47
        DEFW    F_CONIN_H              ; $9C49
        DEFW    F_CONOUT_H                 ; $9C4B
        DEFW    F_READERIN_H              ; $9C4D
        DEFB    $12,$AA,$0F,$AA,$D4,$9E,$ED,$9E,$F3,$9E,$F8,$9E,$E1,$9D,$FE,$9E ; $9C4F
        DEFW    S_BDOSVER_H               ; $9C5F
        DEFW    DRV_ALLRESET_H               ; $9C61
        DEFW    DRV_SET_H                 ; $9C63
        DEFW    F_OPEN_H               ; $9C65
        DEFW    F_CLOSE_H               ; $9C67
        DEFW    F_SFIRST_H               ; $9C69
        DEFW    F_SNEXT_H               ; $9C6B
        DEFW    F_DELETE_H               ; $9C6D
        DEFW    F_READ_H              ; $9C6F
        DEFW    F_WRITE_H              ; $9C71
        DEFW    F_MAKE_H              ; $9C73
        DEFW    F_RENAME_H              ; $9C75
        DEFW    DRV_LOGINVEC_H              ; $9C77
        DEFW    DRV_GET_H              ; $9C79
        DEFW    F_DMAOFF_H              ; $9C7B
        DEFW    DRV_ALLOCVEC_H              ; $9C7D
        DEFW    DRV_SETRO_H                 ; $9C7F
        DEFW    DRV_ROVEC_H              ; $9C81
        DEFW    F_ATTRIB_H              ; $9C83
        DEFW    DRV_DPB_H              ; $9C85
        DEFW    F_USERNUM_H              ; $9C87
        DEFW    F_READRAND_H              ; $9C89
        DEFW    F_WRITERAND_H              ; $9C8B
        DEFW    F_SIZE_H              ; $9C8D
        DEFW    F_RANDREC_H               ; $9C8F
        DEFW    DIR_NAME_MASK_34              ; $9C91
        DEFW    SUB_9DC9_29              ; $9C93
        DEFW    SUB_9DC9_29              ; $9C95
        DEFW    F_WRITEZF_H              ; $9C97
        DEFW    $CA21                    ; $9C99
        DEFW    $CD9C                    ; $9C9B
        DEFW    BDOS_ERR_PRINT                 ; $9C9D
        DEFW    $03FE                    ; $9C9F
        DEFW    $00CA                    ; $9CA1
        DEFW    $C900                    ; $9CA3
        DEFW    $D521                    ; $9CA5
        DEFW    $C39C                    ; $9CA7
        DEFW    SUB_9866_50              ; $9CA9
        DEFW    $E121                    ; $9CAB
        DEFW    $C39C                    ; $9CAD
        DEFW    SUB_9866_50              ; $9CAF
        DEFW    $DC21                    ; $9CB1
        DEFB    $9C                                              ; $9CB3
SUB_9866_50:
        CALL BDOS_ERR_PRINT                    ; $9CB4  CD E5 9C
        JP $0000                         ; $9CB7  C3 00 00
L_9CBA:
        DEFB    "Bdos Err On "    ; $9CBA  string
L_9CC6:
        DEFB    " : $Bad Sector$Select$File R/O$"    ; $9CC6  string
BDOS_ERR_PRINT:
        PUSH HL                          ; $9CE5  E5
        CALL BDOS_CON_37                    ; $9CE6  CD C9 9D
        LD A,(L_9F42)                    ; $9CE9  3A 42 9F
        ADD A,$41                        ; $9CEC  C6 41
        LD (L_9CC6),A                    ; $9CEE  32 C6 9C
        LD BC,L_9CBA                     ; $9CF1  01 BA 9C
        CALL BDOS_CON_39                  ; $9CF4  CD D3 9D
        POP BC                           ; $9CF7  C1
        CALL BDOS_CON_39                  ; $9CF8  CD D3 9D
SUB_9CFB:
        LD HL,L_9F0E                     ; $9CFB  21 0E 9F
        LD A,(HL)                        ; $9CFE  7E
        LD (HL),$00                      ; $9CFF  36 00
        OR A                             ; $9D01  B7
        RET NZ                           ; $9D02  C0
        JP $AA09                         ; $9D03  C3 09 AA
BDOS_CON_15:
        CALL SUB_9CFB                    ; $9D06  CD FB 9C
        CALL IS_CTRL_CHAR                    ; $9D09  CD 14 9D
        RET C                            ; $9D0C  D8
        PUSH AF                          ; $9D0D  F5
        LD C,A                           ; $9D0E  4F
        CALL F_CONOUT_H                    ; $9D0F  CD 90 9D
        POP AF                           ; $9D12  F1
        RET                              ; $9D13  C9
IS_CTRL_CHAR:
        CP $0D                           ; $9D14  FE 0D
        RET Z                            ; $9D16  C8
        CP $0A                           ; $9D17  FE 0A
        RET Z                            ; $9D19  C8
        CP $09                           ; $9D1A  FE 09
        RET Z                            ; $9D1C  C8
        CP $08                           ; $9D1D  FE 08
        RET Z                            ; $9D1F  C8
        CP $20                           ; $9D20  FE 20
        RET                              ; $9D22  C9
BDOS_CON_18:
        LD A,(L_9F0E)                    ; $9D23  3A 0E 9F
        OR A                             ; $9D26  B7
        JP NZ,SUB_9D23_2                 ; $9D27  C2 45 9D
        CALL $AA06                       ; $9D2A  CD 06 AA
        AND $01                          ; $9D2D  E6 01
        RET Z                            ; $9D2F  C8
        CALL $AA09                       ; $9D30  CD 09 AA
        CP $13                           ; $9D33  FE 13
        JP NZ,BDOS_CON_21                 ; $9D35  C2 42 9D
        CALL $AA09                       ; $9D38  CD 09 AA
        CP $03                           ; $9D3B  FE 03
        JP Z,$0000                       ; $9D3D  CA 00 00
        XOR A                            ; $9D40  AF
        RET                              ; $9D41  C9
BDOS_CON_21:
        LD (L_9F0E),A                    ; $9D42  32 0E 9F
SUB_9D23_2:
        LD A,$01                         ; $9D45  3E 01
        RET                              ; $9D47  C9
CON_PUT_COL:
        LD A,(L_9F0A)                    ; $9D48  3A 0A 9F
        OR A                             ; $9D4B  B7
        JP NZ,SUB_9D48_1                 ; $9D4C  C2 62 9D
        PUSH BC                          ; $9D4F  C5
        CALL BDOS_CON_18                    ; $9D50  CD 23 9D
        POP BC                           ; $9D53  C1
        PUSH BC                          ; $9D54  C5
        CALL $AA0C                       ; $9D55  CD 0C AA
        POP BC                           ; $9D58  C1
        PUSH BC                          ; $9D59  C5
        LD A,(L_9F0D)                    ; $9D5A  3A 0D 9F
        OR A                             ; $9D5D  B7
        CALL NZ,$AA0F                    ; $9D5E  C4 0F AA
        POP BC                           ; $9D61  C1
SUB_9D48_1:
        LD A,C                           ; $9D62  79
        LD HL,L_9F0C                     ; $9D63  21 0C 9F
        CP $7F                           ; $9D66  FE 7F
        RET Z                            ; $9D68  C8
        INC (HL)                         ; $9D69  34
        CP $20                           ; $9D6A  FE 20
        RET NC                           ; $9D6C  D0
        DEC (HL)                         ; $9D6D  35
        LD A,(HL)                        ; $9D6E  7E
        OR A                             ; $9D6F  B7
        RET Z                            ; $9D70  C8
        LD A,C                           ; $9D71  79
        CP $08                           ; $9D72  FE 08
        JP NZ,CON_PUT_COL_6                 ; $9D74  C2 79 9D
        DEC (HL)                         ; $9D77  35
        RET                              ; $9D78  C9
CON_PUT_COL_6:
        CP $0A                           ; $9D79  FE 0A
        RET NZ                           ; $9D7B  C0
        LD (HL),$00                      ; $9D7C  36 00
        RET                              ; $9D7E  C9
BDOS_CON_29:
        LD A,C                           ; $9D7F  79
        CALL IS_CTRL_CHAR                    ; $9D80  CD 14 9D
        JP NC,F_CONOUT_H                   ; $9D83  D2 90 9D
        PUSH AF                          ; $9D86  F5
        LD C,$5E                         ; $9D87  0E 5E
        CALL CON_PUT_COL                    ; $9D89  CD 48 9D
        POP AF                           ; $9D8C  F1
        OR $40                           ; $9D8D  F6 40
        LD C,A                           ; $9D8F  4F
F_CONOUT_H:
        LD A,C                           ; $9D90  79
        CP $09                           ; $9D91  FE 09
        JP NZ,CON_PUT_COL                   ; $9D93  C2 48 9D
SUB_9D90_1:
        LD C,$20                         ; $9D96  0E 20
        CALL CON_PUT_COL                    ; $9D98  CD 48 9D
        LD A,(L_9F0C)                    ; $9D9B  3A 0C 9F
        AND $07                          ; $9D9E  E6 07
        JP NZ,SUB_9D90_1                 ; $9DA0  C2 96 9D
        RET                              ; $9DA3  C9
BDOS_CON_32:
        CALL SUB_9DAC                    ; $9DA4  CD AC 9D
        LD C,$20                         ; $9DA7  0E 20
        CALL $AA0C                       ; $9DA9  CD 0C AA
SUB_9DAC:
        LD C,$08                         ; $9DAC  0E 08
        JP $AA0C                         ; $9DAE  C3 0C AA
BDOS_CON_34:
        LD C,$23                         ; $9DB1  0E 23
        CALL CON_PUT_COL                    ; $9DB3  CD 48 9D
        CALL BDOS_CON_37                    ; $9DB6  CD C9 9D
SUB_9DB1_1:
        LD A,(L_9F0C)                    ; $9DB9  3A 0C 9F
        LD HL,L_9F0B                     ; $9DBC  21 0B 9F
        CP (HL)                          ; $9DBF  BE
        RET NC                           ; $9DC0  D0
        LD C,$20                         ; $9DC1  0E 20
        CALL CON_PUT_COL                    ; $9DC3  CD 48 9D
        JP SUB_9DB1_1                    ; $9DC6  C3 B9 9D
BDOS_CON_37:
        LD C,$0D                         ; $9DC9  0E 0D
        CALL CON_PUT_COL                    ; $9DCB  CD 48 9D
        LD C,$0A                         ; $9DCE  0E 0A
        JP CON_PUT_COL                      ; $9DD0  C3 48 9D
BDOS_CON_39:
        LD A,(BC)                        ; $9DD3  0A
        CP $24                           ; $9DD4  FE 24
        RET Z                            ; $9DD6  C8
        INC BC                           ; $9DD7  03
        PUSH BC                          ; $9DD8  C5
        LD C,A                           ; $9DD9  4F
        CALL F_CONOUT_H                    ; $9DDA  CD 90 9D
        POP BC                           ; $9DDD  C1
        JP BDOS_CON_39                    ; $9DDE  C3 D3 9D
F_READCONBUF_H:
        LD A,(L_9F0C)                    ; $9DE1  3A 0C 9F
        LD (L_9F0B),A                    ; $9DE4  32 0B 9F
        LD HL,(L_9F43)                   ; $9DE7  2A 43 9F
        LD C,(HL)                        ; $9DEA  4E
        INC HL                           ; $9DEB  23
        PUSH HL                          ; $9DEC  E5
        LD B,$00                         ; $9DED  06 00
SUB_9DC9_3:
        PUSH BC                          ; $9DEF  C5
        PUSH HL                          ; $9DF0  E5
SUB_9DC9_4:
        CALL SUB_9CFB                    ; $9DF1  CD FB 9C
        AND $7F                          ; $9DF4  E6 7F
        POP HL                           ; $9DF6  E1
        POP BC                           ; $9DF7  C1
        CP $0D                           ; $9DF8  FE 0D
        JP Z,SUB_9DC9_19                 ; $9DFA  CA C1 9E
        CP $0A                           ; $9DFD  FE 0A
        JP Z,SUB_9DC9_19                 ; $9DFF  CA C1 9E
        CP $08                           ; $9E02  FE 08
        JP NZ,READ_CON_BUF_EDIT_2                 ; $9E04  C2 16 9E
        LD A,B                           ; $9E07  78
        OR A                             ; $9E08  B7
        JP Z,SUB_9DC9_3                  ; $9E09  CA EF 9D
        DEC B                            ; $9E0C  05
        LD A,(L_9F0C)                    ; $9E0D  3A 0C 9F
        LD (L_9F0A),A                    ; $9E10  32 0A 9F
        JP SUB_9DC9_12                   ; $9E13  C3 70 9E
READ_CON_BUF_EDIT_2:
        CP $7F                           ; $9E16  FE 7F
        JP NZ,READ_CON_BUF_EDIT_3                 ; $9E18  C2 26 9E
        LD A,B                           ; $9E1B  78
        OR A                             ; $9E1C  B7
        JP Z,SUB_9DC9_3                  ; $9E1D  CA EF 9D
        LD A,(HL)                        ; $9E20  7E
        DEC B                            ; $9E21  05
        DEC HL                           ; $9E22  2B
        JP SUB_9DC9_17                   ; $9E23  C3 A9 9E
READ_CON_BUF_EDIT_3:
        CP $05                           ; $9E26  FE 05
        JP NZ,READ_CON_BUF_EDIT_5                 ; $9E28  C2 37 9E
        PUSH BC                          ; $9E2B  C5
        PUSH HL                          ; $9E2C  E5
        CALL BDOS_CON_37                    ; $9E2D  CD C9 9D
        XOR A                            ; $9E30  AF
        LD (L_9F0B),A                    ; $9E31  32 0B 9F
        JP SUB_9DC9_4                    ; $9E34  C3 F1 9D
READ_CON_BUF_EDIT_5:
        CP $10                           ; $9E37  FE 10
        JP NZ,READ_CON_BUF_EDIT_8                 ; $9E39  C2 48 9E
        PUSH HL                          ; $9E3C  E5
        LD HL,L_9F0D                     ; $9E3D  21 0D 9F
        LD A,$01                         ; $9E40  3E 01
        SUB (HL)                         ; $9E42  96
        LD (HL),A                        ; $9E43  77
        POP HL                           ; $9E44  E1
        JP SUB_9DC9_3                    ; $9E45  C3 EF 9D
READ_CON_BUF_EDIT_8:
        CP $18                           ; $9E48  FE 18
        JP NZ,READ_CON_BUF_EDIT_11                ; $9E4A  C2 5F 9E
        POP HL                           ; $9E4D  E1
SUB_9DC9_9:
        LD A,(L_9F0B)                    ; $9E4E  3A 0B 9F
        LD HL,L_9F0C                     ; $9E51  21 0C 9F
        CP (HL)                          ; $9E54  BE
        JP NC,F_READCONBUF_H                 ; $9E55  D2 E1 9D
        DEC (HL)                         ; $9E58  35
        CALL BDOS_CON_32                    ; $9E59  CD A4 9D
        JP SUB_9DC9_9                    ; $9E5C  C3 4E 9E
READ_CON_BUF_EDIT_11:
        CP $15                           ; $9E5F  FE 15
        JP NZ,READ_CON_BUF_EDIT_12                ; $9E61  C2 6B 9E
        CALL BDOS_CON_34                    ; $9E64  CD B1 9D
        POP HL                           ; $9E67  E1
        JP F_READCONBUF_H                    ; $9E68  C3 E1 9D
READ_CON_BUF_EDIT_12:
        CP $12                           ; $9E6B  FE 12
        JP NZ,FCB_CMP_DIR_ENTRY                ; $9E6D  C2 A6 9E
SUB_9DC9_12:
        PUSH BC                          ; $9E70  C5
        CALL BDOS_CON_34                    ; $9E71  CD B1 9D
        POP BC                           ; $9E74  C1
        POP HL                           ; $9E75  E1
        PUSH HL                          ; $9E76  E5
        PUSH BC                          ; $9E77  C5
SUB_9DC9_13:
        LD A,B                           ; $9E78  78
        OR A                             ; $9E79  B7
        JP Z,DIR_NEXT_ENTRY                 ; $9E7A  CA 8A 9E
        INC HL                           ; $9E7D  23
        LD C,(HL)                        ; $9E7E  4E
        DEC B                            ; $9E7F  05
        PUSH BC                          ; $9E80  C5
        PUSH HL                          ; $9E81  E5
        CALL BDOS_CON_29                    ; $9E82  CD 7F 9D
        POP HL                           ; $9E85  E1
        POP BC                           ; $9E86  C1
        JP SUB_9DC9_13                   ; $9E87  C3 78 9E
DIR_NEXT_ENTRY:
        PUSH HL                          ; $9E8A  E5
        LD A,(L_9F0A)                    ; $9E8B  3A 0A 9F
        OR A                             ; $9E8E  B7
        JP Z,SUB_9DC9_4                  ; $9E8F  CA F1 9D
        LD HL,L_9F0C                     ; $9E92  21 0C 9F
        SUB (HL)                         ; $9E95  96
        LD (L_9F0A),A                    ; $9E96  32 0A 9F
SUB_9DC9_15:
        CALL BDOS_CON_32                    ; $9E99  CD A4 9D
        LD HL,L_9F0A                     ; $9E9C  21 0A 9F
        DEC (HL)                         ; $9E9F  35
        JP NZ,SUB_9DC9_15                ; $9EA0  C2 99 9E
        JP SUB_9DC9_4                    ; $9EA3  C3 F1 9D
FCB_CMP_DIR_ENTRY:
        INC HL                           ; $9EA6  23
        LD (HL),A                        ; $9EA7  77
        INC B                            ; $9EA8  04
SUB_9DC9_17:
        PUSH BC                          ; $9EA9  C5
        PUSH HL                          ; $9EAA  E5
        LD C,A                           ; $9EAB  4F
        CALL BDOS_CON_29                    ; $9EAC  CD 7F 9D
        POP HL                           ; $9EAF  E1
        POP BC                           ; $9EB0  C1
        LD A,(HL)                        ; $9EB1  7E
        CP $03                           ; $9EB2  FE 03
        LD A,B                           ; $9EB4  78
        JP NZ,SUB_9DC9_18                ; $9EB5  C2 BD 9E
        CP $01                           ; $9EB8  FE 01
        JP Z,$0000                       ; $9EBA  CA 00 00
SUB_9DC9_18:
        CP C                             ; $9EBD  B9
        JP C,SUB_9DC9_3                  ; $9EBE  DA EF 9D
SUB_9DC9_19:
        POP HL                           ; $9EC1  E1
        LD (HL),B                        ; $9EC2  70
        LD C,$0D                         ; $9EC3  0E 0D
        JP CON_PUT_COL                      ; $9EC5  C3 48 9D
F_CONIN_H:
        CALL BDOS_CON_15                    ; $9EC8  CD 06 9D
        JP BDOS_RET_RESULT                   ; $9ECB  C3 01 9F
F_READERIN_H:
        CALL $AA15                       ; $9ECE  CD 15 AA
        JP BDOS_RET_RESULT                   ; $9ED1  C3 01 9F
F_DIRECTIO_H:
        LD A,C                           ; $9ED4  79
        INC A                            ; $9ED5  3C
        JP Z,FCB_CMP_DIR_ENTRY_7                 ; $9ED6  CA E0 9E
        INC A                            ; $9ED9  3C
        JP Z,$AA06                       ; $9EDA  CA 06 AA
        JP $AA0C                         ; $9EDD  C3 0C AA
FCB_CMP_DIR_ENTRY_7:
        CALL $AA06                       ; $9EE0  CD 06 AA
        OR A                             ; $9EE3  B7
        JP Z,SUB_A851_29                 ; $9EE4  CA 91 A9
        CALL $AA09                       ; $9EE7  CD 09 AA
        JP BDOS_RET_RESULT                   ; $9EEA  C3 01 9F
F_GETIOB_H:
        LD A,($0003)                     ; $9EED  3A 03 00
        JP BDOS_RET_RESULT                   ; $9EF0  C3 01 9F
F_SETIOB_H:
        LD HL,$0003                      ; $9EF3  21 03 00
        LD (HL),C                        ; $9EF6  71
        RET                              ; $9EF7  C9
F_PRINTSTR_H:
        EX DE,HL                         ; $9EF8  EB
        LD C,L                           ; $9EF9  4D
        LD B,H                           ; $9EFA  44
        JP BDOS_CON_39                    ; $9EFB  C3 D3 9D
F_CONSTAT_H:
        CALL BDOS_CON_18                    ; $9EFE  CD 23 9D
BDOS_RET_RESULT:
        LD (L_9F45),A                    ; $9F01  32 45 9F
SUB_9DC9_29:
        RET                              ; $9F04  C9
BDOS_CHECK_ERROR_2:
        LD A,$01                         ; $9F05  3E 01
        JP BDOS_RET_RESULT                   ; $9F07  C3 01 9F
L_9F0A:
        DEFB    "\0"    ; $9F0A
L_9F0B:
        DEFB    "\0"    ; $9F0B
L_9F0C:
        DEFB    "\0"    ; $9F0C
L_9F0D:
        DEFB    "\0"    ; $9F0D
L_9F0E:
        DEFB    "\0"    ; $9F0E
L_9F0F:
        DEFS    50, $00    ; $9F0F  fill
L_9F41:
        DEFB    "\0"    ; $9F41
L_9F42:
        DEFB    "\0"    ; $9F42
L_9F43:
        DEFB    "\0\0"    ; $9F43
L_9F45:
        DEFB    "\0\0"    ; $9F45
SUB_9F47:
        LD HL,SUB_9866_46                ; $9F47  21 0B 9C
SUB_9F47_1:
        LD E,(HL)                        ; $9F4A  5E
        INC HL                           ; $9F4B  23
        LD D,(HL)                        ; $9F4C  56
        EX DE,HL                         ; $9F4D  EB
        JP (HL)                          ; $9F4E  E9
BDOS_RANDREC_2:
        INC C                            ; $9F4F  0C
SUB_9F4F_1:
        DEC C                            ; $9F50  0D
        RET Z                            ; $9F51  C8
        LD A,(DE)                        ; $9F52  1A
        LD (HL),A                        ; $9F53  77
        INC DE                           ; $9F54  13
        INC HL                           ; $9F55  23
        JP SUB_9F4F_1                    ; $9F56  C3 50 9F
BDOS_RANDREC_3:
        LD A,(L_9F42)                    ; $9F59  3A 42 9F
        LD C,A                           ; $9F5C  4F
        CALL $AA1B                       ; $9F5D  CD 1B AA
        LD A,H                           ; $9F60  7C
        OR L                             ; $9F61  B5
        RET Z                            ; $9F62  C8
        LD E,(HL)                        ; $9F63  5E
        INC HL                           ; $9F64  23
        LD D,(HL)                        ; $9F65  56
        INC HL                           ; $9F66  23
        LD (DPB_WORK_PTR0),HL                   ; $9F67  22 B3 A9
        INC HL                           ; $9F6A  23
        INC HL                           ; $9F6B  23
        LD (L_A9B5),HL                   ; $9F6C  22 B5 A9
        INC HL                           ; $9F6F  23
        INC HL                           ; $9F70  23
        LD (L_A9B7),HL                   ; $9F71  22 B7 A9
        INC HL                           ; $9F74  23
        INC HL                           ; $9F75  23
        EX DE,HL                         ; $9F76  EB
        LD (L_A9D0),HL                   ; $9F77  22 D0 A9
        LD HL,DIRBUF_PTR                     ; $9F7A  21 B9 A9
        LD C,$08                         ; $9F7D  0E 08
        CALL BDOS_RANDREC_2                    ; $9F7F  CD 4F 9F
        LD HL,(L_A9BB)                   ; $9F82  2A BB A9
        EX DE,HL                         ; $9F85  EB
        LD HL,L_A9C1                     ; $9F86  21 C1 A9
        LD C,$0F                         ; $9F89  0E 0F
        CALL BDOS_RANDREC_2                    ; $9F8B  CD 4F 9F
        LD HL,(MAX_BLOCK_DSM)                   ; $9F8E  2A C6 A9
        LD A,H                           ; $9F91  7C
        LD HL,BLOCK_WIDTH_FLAG                     ; $9F92  21 DD A9
        LD (HL),$FF                      ; $9F95  36 FF
        OR A                             ; $9F97  B7
        JP Z,SUB_9F59_1                  ; $9F98  CA 9D 9F
        LD (HL),$00                      ; $9F9B  36 00
SUB_9F59_1:
        LD A,$FF                         ; $9F9D  3E FF
        OR A                             ; $9F9F  B7
        RET                              ; $9FA0  C9
BDOS_RANDREC_6:
        CALL $AA18                       ; $9FA1  CD 18 AA
        XOR A                            ; $9FA4  AF
        LD HL,(L_A9B5)                   ; $9FA5  2A B5 A9
        LD (HL),A                        ; $9FA8  77
        INC HL                           ; $9FA9  23
        LD (HL),A                        ; $9FAA  77
        LD HL,(L_A9B7)                   ; $9FAB  2A B7 A9
        LD (HL),A                        ; $9FAE  77
        INC HL                           ; $9FAF  23
        LD (HL),A                        ; $9FB0  77
        RET                              ; $9FB1  C9
BDOS_RANDREC_7:
        CALL $AA27                       ; $9FB2  CD 27 AA
        JP SUB_9FB8_1                    ; $9FB5  C3 BB 9F
BDOS_RANDREC_8:
        CALL $AA2A                       ; $9FB8  CD 2A AA
SUB_9FB8_1:
        OR A                             ; $9FBB  B7
        RET Z                            ; $9FBC  C8
        LD HL,BDOS_ERR_VECTORS                ; $9FBD  21 09 9C
        JP SUB_9F47_1                    ; $9FC0  C3 4A 9F
BDOS_RANDREC_9:
        LD HL,(CUR_RECORD)                   ; $9FC3  2A EA A9
        LD C,$02                         ; $9FC6  0E 02
        CALL DRV_INSTALL_RWTS_10                    ; $9FC8  CD EA A0
        LD (L_A9E5),HL                   ; $9FCB  22 E5 A9
        LD (REC_CACHE),HL                   ; $9FCE  22 EC A9
SUB_9FD1:
        LD HL,L_A9E5                     ; $9FD1  21 E5 A9
        LD C,(HL)                        ; $9FD4  4E
        INC HL                           ; $9FD5  23
        LD B,(HL)                        ; $9FD6  46
        LD HL,(L_A9B7)                   ; $9FD7  2A B7 A9
        LD E,(HL)                        ; $9FDA  5E
        INC HL                           ; $9FDB  23
        LD D,(HL)                        ; $9FDC  56
        LD HL,(L_A9B5)                   ; $9FDD  2A B5 A9
        LD A,(HL)                        ; $9FE0  7E
        INC HL                           ; $9FE1  23
        LD H,(HL)                        ; $9FE2  66
        LD L,A                           ; $9FE3  6F
SUB_9FD1_1:
        LD A,C                           ; $9FE4  79
        SUB E                            ; $9FE5  93
        LD A,B                           ; $9FE6  78
        SBC A,D                          ; $9FE7  9A
        JP NC,SUB_9FD1_2                 ; $9FE8  D2 FA 9F
        PUSH HL                          ; $9FEB  E5
        LD HL,(L_A9C1)                   ; $9FEC  2A C1 A9
        LD A,E                           ; $9FEF  7B
        SUB L                            ; $9FF0  95
        LD E,A                           ; $9FF1  5F
        LD A,D                           ; $9FF2  7A
        SBC A,H                          ; $9FF3  9C
        LD D,A                           ; $9FF4  57
        POP HL                           ; $9FF5  E1
        DEC HL                           ; $9FF6  2B
        JP SUB_9FD1_1                    ; $9FF7  C3 E4 9F
SUB_9FD1_2:
        PUSH HL                          ; $9FFA  E5
        LD HL,(L_A9C1)                   ; $9FFB  2A C1 A9
        ADD HL,DE                        ; $9FFE  19
        JP C,DISK_STORE_SEC_TRK_1                  ; $9FFF  DA 0F A0
        LD A,C                           ; $A002  79
        SUB L                            ; $A003  95
        LD A,B                           ; $A004  78
        SBC A,H                          ; $A005  9C
        JP C,DISK_STORE_SEC_TRK_1                  ; $A006  DA 0F A0
        EX DE,HL                         ; $A009  EB
        POP HL                           ; $A00A  E1
        INC HL                           ; $A00B  23
        JP SUB_9FD1_2                    ; $A00C  C3 FA 9F
DISK_STORE_SEC_TRK_1:
        POP HL                           ; $A00F  E1
        PUSH BC                          ; $A010  C5
        PUSH DE                          ; $A011  D5
        PUSH HL                          ; $A012  E5
        EX DE,HL                         ; $A013  EB
        LD HL,(L_A9CE)                   ; $A014  2A CE A9
        ADD HL,DE                        ; $A017  19
        LD B,H                           ; $A018  44
        LD C,L                           ; $A019  4D
        CALL $AA1E                       ; $A01A  CD 1E AA
        POP DE                           ; $A01D  D1
        LD HL,(L_A9B5)                   ; $A01E  2A B5 A9
        LD (HL),E                        ; $A021  73
        INC HL                           ; $A022  23
        LD (HL),D                        ; $A023  72
        POP DE                           ; $A024  D1
        LD HL,(L_A9B7)                   ; $A025  2A B7 A9
        LD (HL),E                        ; $A028  73
        INC HL                           ; $A029  23
        LD (HL),D                        ; $A02A  72
        POP BC                           ; $A02B  C1
        LD A,C                           ; $A02C  79
        SUB E                            ; $A02D  93
        LD C,A                           ; $A02E  4F
        LD A,B                           ; $A02F  78
        SBC A,D                          ; $A030  9A
        LD B,A                           ; $A031  47
        LD HL,(L_A9D0)                   ; $A032  2A D0 A9
        EX DE,HL                         ; $A035  EB
        CALL $AA30                       ; $A036  CD 30 AA
        LD C,L                           ; $A039  4D
        LD B,H                           ; $A03A  44
        JP $AA21                         ; $A03B  C3 21 AA
DISK_STORE_SEC_TRK_6:
        LD HL,L_A9C3                     ; $A03E  21 C3 A9
        LD C,(HL)                        ; $A041  4E
        LD A,(L_A9E3)                    ; $A042  3A E3 A9
SUB_A03E_1:
        OR A                             ; $A045  B7
        RRA                              ; $A046  1F
        DEC C                            ; $A047  0D
        JP NZ,SUB_A03E_1                 ; $A048  C2 45 A0
        LD B,A                           ; $A04B  47
        LD A,$08                         ; $A04C  3E 08
        SUB (HL)                         ; $A04E  96
        LD C,A                           ; $A04F  4F
        LD A,(L_A9E2)                    ; $A050  3A E2 A9
SUB_A03E_2:
        DEC C                            ; $A053  0D
        JP Z,DISK_STORE_SEC_TRK_9                  ; $A054  CA 5C A0
        OR A                             ; $A057  B7
        RLA                              ; $A058  17
        JP SUB_A03E_2                    ; $A059  C3 53 A0
DISK_STORE_SEC_TRK_9:
        ADD A,B                          ; $A05C  80
        RET                              ; $A05D  C9
DISK_STORE_SEC_TRK_10:
        LD HL,(L_9F43)                   ; $A05E  2A 43 9F
        LD DE,$0010                      ; $A061  11 10 00
        ADD HL,DE                        ; $A064  19
        ADD HL,BC                        ; $A065  09
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A066  3A DD A9
        OR A                             ; $A069  B7
        JP Z,DISK_STORE_SEC_TRK_13                  ; $A06A  CA 71 A0
        LD L,(HL)                        ; $A06D  6E
        LD H,$00                         ; $A06E  26 00
        RET                              ; $A070  C9
DISK_STORE_SEC_TRK_13:
        ADD HL,BC                        ; $A071  09
        LD E,(HL)                        ; $A072  5E
        INC HL                           ; $A073  23
        LD D,(HL)                        ; $A074  56
        EX DE,HL                         ; $A075  EB
        RET                              ; $A076  C9
DISK_STORE_SEC_TRK_14:
        CALL DISK_STORE_SEC_TRK_6                    ; $A077  CD 3E A0
        LD C,A                           ; $A07A  4F
        LD B,$00                         ; $A07B  06 00
        CALL DISK_STORE_SEC_TRK_10                    ; $A07D  CD 5E A0
        LD (L_A9E5),HL                   ; $A080  22 E5 A9
        RET                              ; $A083  C9
DISK_STORE_SEC_TRK_16:
        LD HL,(L_A9E5)                   ; $A084  2A E5 A9
        LD A,L                           ; $A087  7D
        OR H                             ; $A088  B4
        RET                              ; $A089  C9
DISK_STORE_SEC_TRK_17:
        LD A,(L_A9C3)                    ; $A08A  3A C3 A9
        LD HL,(L_A9E5)                   ; $A08D  2A E5 A9
SUB_A08A_1:
        ADD HL,HL                        ; $A090  29
        DEC A                            ; $A091  3D
        JP NZ,SUB_A08A_1                 ; $A092  C2 90 A0
        LD (L_A9E7),HL                   ; $A095  22 E7 A9
        LD A,(L_A9C4)                    ; $A098  3A C4 A9
        LD C,A                           ; $A09B  4F
        LD A,(L_A9E3)                    ; $A09C  3A E3 A9
        AND C                            ; $A09F  A1
        OR L                             ; $A0A0  B5
        LD L,A                           ; $A0A1  6F
        LD (L_A9E5),HL                   ; $A0A2  22 E5 A9
        RET                              ; $A0A5  C9
DRV_INSTALL_RWTS_1:
        LD HL,(L_9F43)                   ; $A0A6  2A 43 9F
        LD DE,$000C                      ; $A0A9  11 0C 00
        ADD HL,DE                        ; $A0AC  19
        RET                              ; $A0AD  C9
DRV_INSTALL_RWTS_2:
        LD HL,(L_9F43)                   ; $A0AE  2A 43 9F
        LD DE,$000F                      ; $A0B1  11 0F 00
        ADD HL,DE                        ; $A0B4  19
        EX DE,HL                         ; $A0B5  EB
        LD HL,$0011                      ; $A0B6  21 11 00
        ADD HL,DE                        ; $A0B9  19
        RET                              ; $A0BA  C9
DRV_INSTALL_RWTS_3:
        CALL DRV_INSTALL_RWTS_2                    ; $A0BB  CD AE A0
        LD A,(HL)                        ; $A0BE  7E
        LD (L_A9E3),A                    ; $A0BF  32 E3 A9
        EX DE,HL                         ; $A0C2  EB
        LD A,(HL)                        ; $A0C3  7E
        LD (L_A9E1),A                    ; $A0C4  32 E1 A9
        CALL DRV_INSTALL_RWTS_1                    ; $A0C7  CD A6 A0
        LD A,(L_A9C5)                    ; $A0CA  3A C5 A9
        AND (HL)                         ; $A0CD  A6
        LD (L_A9E2),A                    ; $A0CE  32 E2 A9
        RET                              ; $A0D1  C9
DRV_INSTALL_RWTS_6:
        CALL DRV_INSTALL_RWTS_2                    ; $A0D2  CD AE A0
        LD A,(L_A9D5)                    ; $A0D5  3A D5 A9
        CP $02                           ; $A0D8  FE 02
        JP NZ,SUB_A0D2_1                 ; $A0DA  C2 DE A0
        XOR A                            ; $A0DD  AF
SUB_A0D2_1:
        LD C,A                           ; $A0DE  4F
        LD A,(L_A9E3)                    ; $A0DF  3A E3 A9
        ADD A,C                          ; $A0E2  81
        LD (HL),A                        ; $A0E3  77
        EX DE,HL                         ; $A0E4  EB
        LD A,(L_A9E1)                    ; $A0E5  3A E1 A9
        LD (HL),A                        ; $A0E8  77
        RET                              ; $A0E9  C9
DRV_INSTALL_RWTS_10:
        INC C                            ; $A0EA  0C
SUB_A0EA_1:
        DEC C                            ; $A0EB  0D
        RET Z                            ; $A0EC  C8
        LD A,H                           ; $A0ED  7C
        OR A                             ; $A0EE  B7
        RRA                              ; $A0EF  1F
        LD H,A                           ; $A0F0  67
        LD A,L                           ; $A0F1  7D
        RRA                              ; $A0F2  1F
        LD L,A                           ; $A0F3  6F
        JP SUB_A0EA_1                    ; $A0F4  C3 EB A0
SUB_A0F7:
        LD C,$80                         ; $A0F7  0E 80
        LD HL,(DIRBUF_PTR)                   ; $A0F9  2A B9 A9
        XOR A                            ; $A0FC  AF
SUB_A0F7_1:
        ADD A,(HL)                       ; $A0FD  86
        INC HL                           ; $A0FE  23
        DEC C                            ; $A0FF  0D
        JP NZ,SUB_A0F7_1                 ; $A100  C2 FD A0
        RET                              ; $A103  C9
CMD_EXEC_11:
        INC C                            ; $A104  0C
SUB_A104_1:
        DEC C                            ; $A105  0D
        RET Z                            ; $A106  C8
        ADD HL,HL                        ; $A107  29
        JP SUB_A104_1                    ; $A108  C3 05 A1
CMD_EXEC_12:
        PUSH BC                          ; $A10B  C5
        LD A,(L_9F42)                    ; $A10C  3A 42 9F
        LD C,A                           ; $A10F  4F
        LD HL,$0001                      ; $A110  21 01 00
        CALL CMD_EXEC_11                    ; $A113  CD 04 A1
        POP BC                           ; $A116  C1
        LD A,C                           ; $A117  79
        OR L                             ; $A118  B5
        LD L,A                           ; $A119  6F
        LD A,B                           ; $A11A  78
        OR H                             ; $A11B  B4
        LD H,A                           ; $A11C  67
        RET                              ; $A11D  C9
DRIVE_BIT_TEST:
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A11E  2A AD A9
        LD A,(L_9F42)                    ; $A121  3A 42 9F
        LD C,A                           ; $A124  4F
        CALL DRV_INSTALL_RWTS_10                    ; $A125  CD EA A0
        LD A,L                           ; $A128  7D
        AND $01                          ; $A129  E6 01
        RET                              ; $A12B  C9
DRV_SETRO_H:
        LD HL,DRV_LOGIN_VECTOR                     ; $A12C  21 AD A9
        LD C,(HL)                        ; $A12F  4E
        INC HL                           ; $A130  23
        LD B,(HL)                        ; $A131  46
        CALL CMD_EXEC_12                    ; $A132  CD 0B A1
        LD (DRV_LOGIN_VECTOR),HL                   ; $A135  22 AD A9
        LD HL,(DPB_REC_PTR)                   ; $A138  2A C8 A9
        INC HL                           ; $A13B  23
        EX DE,HL                         ; $A13C  EB
        LD HL,(DPB_WORK_PTR0)                   ; $A13D  2A B3 A9
        LD (HL),E                        ; $A140  73
        INC HL                           ; $A141  23
        LD (HL),D                        ; $A142  72
        RET                              ; $A143  C9
FCB_RO_FLAG_TEST:
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A144  CD 5E A1
SUB_A147:
        LD DE,$0009                      ; $A147  11 09 00
        ADD HL,DE                        ; $A14A  19
        LD A,(HL)                        ; $A14B  7E
        RLA                              ; $A14C  17
        RET NC                           ; $A14D  D0
        LD HL,SUB_9866_48                ; $A14E  21 0F 9C
        JP SUB_9F47_1                    ; $A151  C3 4A 9F
CMD_EXEC_20:
        CALL DRIVE_BIT_TEST                    ; $A154  CD 1E A1
        RET Z                            ; $A157  C8
        LD HL,SUB_9866_47                ; $A158  21 0D 9C
        JP SUB_9F47_1                    ; $A15B  C3 4A 9F
FCB_BUF_PTR_ADD_OFFSET:
        LD HL,(DIRBUF_PTR)                   ; $A15E  2A B9 A9
        LD A,(DEBLOCK_BYTE_OFF)                    ; $A161  3A E9 A9
SUB_A164:
        ADD A,L                          ; $A164  85
        LD L,A                           ; $A165  6F
        RET NC                           ; $A166  D0
        INC H                            ; $A167  24
        RET                              ; $A168  C9
FCB_GET_S2:
        LD HL,(L_9F43)                   ; $A169  2A 43 9F
        LD DE,$000E                      ; $A16C  11 0E 00
        ADD HL,DE                        ; $A16F  19
        LD A,(HL)                        ; $A170  7E
        RET                              ; $A171  C9
SUB_A172:
        CALL FCB_GET_S2                    ; $A172  CD 69 A1
        LD (HL),$00                      ; $A175  36 00
        RET                              ; $A177  C9
SUB_A178:
        CALL FCB_GET_S2                    ; $A178  CD 69 A1
        OR $80                           ; $A17B  F6 80
        LD (HL),A                        ; $A17D  77
        RET                              ; $A17E  C9
RECPTR_CMP16:
        LD HL,(CUR_RECORD)                   ; $A17F  2A EA A9
        EX DE,HL                         ; $A182  EB
        LD HL,(DPB_WORK_PTR0)                   ; $A183  2A B3 A9
        LD A,E                           ; $A186  7B
        SUB (HL)                         ; $A187  96
        INC HL                           ; $A188  23
        LD A,D                           ; $A189  7A
        SBC A,(HL)                       ; $A18A  9E
        RET                              ; $A18B  C9
RECPTR_INC_STORE:
        CALL RECPTR_CMP16                    ; $A18C  CD 7F A1
        RET C                            ; $A18F  D8
        INC DE                           ; $A190  13
        LD (HL),D                        ; $A191  72
        DEC HL                           ; $A192  2B
        LD (HL),E                        ; $A193  73
        RET                              ; $A194  C9
SUB16_DE_HL:
        LD A,E                           ; $A195  7B
        SUB L                            ; $A196  95
        LD L,A                           ; $A197  6F
        LD A,D                           ; $A198  7A
        SBC A,H                          ; $A199  9C
        LD H,A                           ; $A19A  67
        RET                              ; $A19B  C9
RECORD_SCAN_INIT:
        LD C,$FF                         ; $A19C  0E FF
RECORD_SCAN_BODY:
        LD HL,(REC_CACHE)                   ; $A19E  2A EC A9
        EX DE,HL                         ; $A1A1  EB
        LD HL,(REC_SCAN_PTR)                   ; $A1A2  2A CC A9
        CALL SUB16_DE_HL                    ; $A1A5  CD 95 A1
        RET NC                           ; $A1A8  D0
        PUSH BC                          ; $A1A9  C5
        CALL SUB_A0F7                    ; $A1AA  CD F7 A0
        LD HL,(REC_BYTE_OFFSET)                   ; $A1AD  2A BD A9
        EX DE,HL                         ; $A1B0  EB
        LD HL,(REC_CACHE)                   ; $A1B1  2A EC A9
        ADD HL,DE                        ; $A1B4  19
        POP BC                           ; $A1B5  C1
        INC C                            ; $A1B6  0C
        JP Z,FCB_STORE_A_ORPHAN                  ; $A1B7  CA C4 A1
        CP (HL)                          ; $A1BA  BE
        RET Z                            ; $A1BB  C8
        CALL RECPTR_CMP16                    ; $A1BC  CD 7F A1
        RET NC                           ; $A1BF  D0
        CALL DRV_SETRO_H                    ; $A1C0  CD 2C A1
        RET                              ; $A1C3  C9
FCB_STORE_A_ORPHAN:
        LD (HL),A                        ; $A1C4  77
        RET                              ; $A1C5  C9
DIR_RECORD_WRITE:
        CALL RECORD_SCAN_INIT                    ; $A1C6  CD 9C A1
        CALL SET_DMA_TO_DISK_BUF                    ; $A1C9  CD E0 A1
        LD C,$01                         ; $A1CC  0E 01
        CALL BDOS_RANDREC_8                    ; $A1CE  CD B8 9F
        JP SUB_A1DA                      ; $A1D1  C3 DA A1
DIR_RECORD_READ:
        CALL SET_DMA_TO_DISK_BUF                    ; $A1D4  CD E0 A1
        CALL BDOS_RANDREC_7                    ; $A1D7  CD B2 9F
SUB_A1DA:
        LD HL,DMA_ADDR                     ; $A1DA  21 B1 A9
        JP SUB_A1E0_1                    ; $A1DD  C3 E3 A1
SET_DMA_TO_DISK_BUF:
        LD HL,DIRBUF_PTR                     ; $A1E0  21 B9 A9
SUB_A1E0_1:
        LD C,(HL)                        ; $A1E3  4E
        INC HL                           ; $A1E4  23
        LD B,(HL)                        ; $A1E5  46
        JP $AA24                         ; $A1E6  C3 24 AA
DISK_BUF_MOVE:
        LD HL,(DIRBUF_PTR)                   ; $A1E9  2A B9 A9
        EX DE,HL                         ; $A1EC  EB
        LD HL,(DMA_ADDR)                   ; $A1ED  2A B1 A9
        LD C,$80                         ; $A1F0  0E 80
        JP BDOS_RANDREC_2                      ; $A1F2  C3 4F 9F
SUB_A1F5:
        LD HL,CUR_RECORD                     ; $A1F5  21 EA A9
        LD A,(HL)                        ; $A1F8  7E
        INC HL                           ; $A1F9  23
        CP (HL)                          ; $A1FA  BE
        RET NZ                           ; $A1FB  C0
        INC A                            ; $A1FC  3C
        RET                              ; $A1FD  C9
SUB_A1FE:
        LD HL,$FFFF                      ; $A1FE  21 FF FF
        LD (CUR_RECORD),HL                   ; $A201  22 EA A9
        RET                              ; $A204  C9
CMD_EXEC_53:
        LD HL,(DPB_REC_PTR)                   ; $A205  2A C8 A9
        EX DE,HL                         ; $A208  EB
        LD HL,(CUR_RECORD)                   ; $A209  2A EA A9
        INC HL                           ; $A20C  23
        LD (CUR_RECORD),HL                   ; $A20D  22 EA A9
        CALL SUB16_DE_HL                    ; $A210  CD 95 A1
        JP NC,CMD_EXEC_54                 ; $A213  D2 19 A2
        JP SUB_A1FE                      ; $A216  C3 FE A1
CMD_EXEC_54:
        LD A,(CUR_RECORD)                    ; $A219  3A EA A9
        AND $03                          ; $A21C  E6 03
        LD B,$05                         ; $A21E  06 05
SUB_A205_2:
        ADD A,A                          ; $A220  87
        DEC B                            ; $A221  05
        JP NZ,SUB_A205_2                 ; $A222  C2 20 A2
        LD (DEBLOCK_BYTE_OFF),A                    ; $A225  32 E9 A9
        OR A                             ; $A228  B7
        RET NZ                           ; $A229  C0
        PUSH BC                          ; $A22A  C5
        CALL BDOS_RANDREC_9                    ; $A22B  CD C3 9F
        CALL DIR_RECORD_READ                    ; $A22E  CD D4 A1
        POP BC                           ; $A231  C1
        JP RECORD_SCAN_BODY                    ; $A232  C3 9E A1
CMD_EXEC_56:
        LD A,C                           ; $A235  79
        AND $07                          ; $A236  E6 07
        INC A                            ; $A238  3C
        LD E,A                           ; $A239  5F
        LD D,A                           ; $A23A  57
        LD A,C                           ; $A23B  79
        RRCA                             ; $A23C  0F
        RRCA                             ; $A23D  0F
        RRCA                             ; $A23E  0F
        AND $1F                          ; $A23F  E6 1F
        LD C,A                           ; $A241  4F
        LD A,B                           ; $A242  78
        ADD A,A                          ; $A243  87
        ADD A,A                          ; $A244  87
        ADD A,A                          ; $A245  87
        ADD A,A                          ; $A246  87
        ADD A,A                          ; $A247  87
        OR C                             ; $A248  B1
        LD C,A                           ; $A249  4F
        LD A,B                           ; $A24A  78
        RRCA                             ; $A24B  0F
        RRCA                             ; $A24C  0F
        RRCA                             ; $A24D  0F
        AND $1F                          ; $A24E  E6 1F
        LD B,A                           ; $A250  47
        LD HL,(ALLOC_VEC_PTR)                   ; $A251  2A BF A9
        ADD HL,BC                        ; $A254  09
        LD A,(HL)                        ; $A255  7E
SUB_A235_1:
        RLCA                             ; $A256  07
        DEC E                            ; $A257  1D
        JP NZ,SUB_A235_1                 ; $A258  C2 56 A2
        RET                              ; $A25B  C9
CMD_EXEC_60:
        PUSH DE                          ; $A25C  D5
        CALL CMD_EXEC_56                    ; $A25D  CD 35 A2
        AND $FE                          ; $A260  E6 FE
        POP BC                           ; $A262  C1
        OR C                             ; $A263  B1
SUB_A264:
        RRCA                             ; $A264  0F
        DEC D                            ; $A265  15
        JP NZ,SUB_A264                   ; $A266  C2 64 A2
        LD (HL),A                        ; $A269  77
        RET                              ; $A26A  C9
CMD_EXEC_61:
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A26B  CD 5E A1
        LD DE,$0010                      ; $A26E  11 10 00
        ADD HL,DE                        ; $A271  19
        PUSH BC                          ; $A272  C5
        LD C,$11                         ; $A273  0E 11
SUB_A26B_1:
        POP DE                           ; $A275  D1
        DEC C                            ; $A276  0D
        RET Z                            ; $A277  C8
        PUSH DE                          ; $A278  D5
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A279  3A DD A9
        OR A                             ; $A27C  B7
        JP Z,SUB_A26B_2                  ; $A27D  CA 88 A2
        PUSH BC                          ; $A280  C5
        PUSH HL                          ; $A281  E5
        LD C,(HL)                        ; $A282  4E
        LD B,$00                         ; $A283  06 00
        JP SUB_A26B_3                    ; $A285  C3 8E A2
SUB_A26B_2:
        DEC C                            ; $A288  0D
        PUSH BC                          ; $A289  C5
        LD C,(HL)                        ; $A28A  4E
        INC HL                           ; $A28B  23
        LD B,(HL)                        ; $A28C  46
        PUSH HL                          ; $A28D  E5
SUB_A26B_3:
        LD A,C                           ; $A28E  79
        OR B                             ; $A28F  B0
        JP Z,SUB_A26B_4                  ; $A290  CA 9D A2
        LD HL,(MAX_BLOCK_DSM)                   ; $A293  2A C6 A9
        LD A,L                           ; $A296  7D
        SUB C                            ; $A297  91
        LD A,H                           ; $A298  7C
        SBC A,B                          ; $A299  98
        CALL NC,CMD_EXEC_60                 ; $A29A  D4 5C A2
SUB_A26B_4:
        POP HL                           ; $A29D  E1
        INC HL                           ; $A29E  23
        POP BC                           ; $A29F  C1
        JP SUB_A26B_1                    ; $A2A0  C3 75 A2
CMD_EXEC_65:
        LD HL,(MAX_BLOCK_DSM)                   ; $A2A3  2A C6 A9
        LD C,$03                         ; $A2A6  0E 03
        CALL DRV_INSTALL_RWTS_10                    ; $A2A8  CD EA A0
        INC HL                           ; $A2AB  23
        LD B,H                           ; $A2AC  44
        LD C,L                           ; $A2AD  4D
        LD HL,(ALLOC_VEC_PTR)                   ; $A2AE  2A BF A9
SUB_A26B_6:
        LD (HL),$00                      ; $A2B1  36 00
        INC HL                           ; $A2B3  23
        DEC BC                           ; $A2B4  0B
        LD A,B                           ; $A2B5  78
        OR C                             ; $A2B6  B1
        JP NZ,SUB_A26B_6                 ; $A2B7  C2 B1 A2
        LD HL,(ALLOC_END_PTR)                   ; $A2BA  2A CA A9
        EX DE,HL                         ; $A2BD  EB
        LD HL,(ALLOC_VEC_PTR)                   ; $A2BE  2A BF A9
        LD (HL),E                        ; $A2C1  73
        INC HL                           ; $A2C2  23
        LD (HL),D                        ; $A2C3  72
        CALL BDOS_RANDREC_6                    ; $A2C4  CD A1 9F
        LD HL,(DPB_WORK_PTR0)                   ; $A2C7  2A B3 A9
        LD (HL),$03                      ; $A2CA  36 03
        INC HL                           ; $A2CC  23
        LD (HL),$00                      ; $A2CD  36 00
        CALL SUB_A1FE                    ; $A2CF  CD FE A1
SUB_A26B_7:
        LD C,$FF                         ; $A2D2  0E FF
        CALL CMD_EXEC_53                    ; $A2D4  CD 05 A2
        CALL SUB_A1F5                    ; $A2D7  CD F5 A1
        RET Z                            ; $A2DA  C8
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A2DB  CD 5E A1
        LD A,$E5                         ; $A2DE  3E E5
        CP (HL)                          ; $A2E0  BE
        JP Z,SUB_A26B_7                  ; $A2E1  CA D2 A2
        LD A,(L_9F41)                    ; $A2E4  3A 41 9F
        CP (HL)                          ; $A2E7  BE
        JP NZ,SUB_A26B_8                 ; $A2E8  C2 F6 A2
        INC HL                           ; $A2EB  23
        LD A,(HL)                        ; $A2EC  7E
        SUB $24                          ; $A2ED  D6 24
        JP NZ,SUB_A26B_8                 ; $A2EF  C2 F6 A2
        DEC A                            ; $A2F2  3D
        LD (L_9F45),A                    ; $A2F3  32 45 9F
SUB_A26B_8:
        LD C,$01                         ; $A2F6  0E 01
        CALL CMD_EXEC_61                    ; $A2F8  CD 6B A2
        CALL RECPTR_INC_STORE                    ; $A2FB  CD 8C A1
        JP SUB_A26B_7                    ; $A2FE  C3 D2 A2
SUB_A26B_9:
        LD A,(L_A9D4)                    ; $A301  3A D4 A9
        JP BDOS_RET_RESULT                   ; $A304  C3 01 9F
SUB_A307:
        PUSH BC                          ; $A307  C5
        PUSH AF                          ; $A308  F5
        LD A,(L_A9C5)                    ; $A309  3A C5 A9
        CPL                              ; $A30C  2F
        LD B,A                           ; $A30D  47
        LD A,C                           ; $A30E  79
        AND B                            ; $A30F  A0
        LD C,A                           ; $A310  4F
        POP AF                           ; $A311  F1
        AND B                            ; $A312  A0
        SUB C                            ; $A313  91
        AND $1F                          ; $A314  E6 1F
        POP BC                           ; $A316  C1
        RET                              ; $A317  C9
SUB_A318:
        LD A,$FF                         ; $A318  3E FF
        LD (L_A9D4),A                    ; $A31A  32 D4 A9
        LD HL,L_A9D8                     ; $A31D  21 D8 A9
        LD (HL),C                        ; $A320  71
        LD HL,(L_9F43)                   ; $A321  2A 43 9F
        LD (L_A9D9),HL                   ; $A324  22 D9 A9
        CALL SUB_A1FE                    ; $A327  CD FE A1
        CALL BDOS_RANDREC_6                    ; $A32A  CD A1 9F
SUB_A32D:
        LD C,$00                         ; $A32D  0E 00
        CALL CMD_EXEC_53                    ; $A32F  CD 05 A2
        CALL SUB_A1F5                    ; $A332  CD F5 A1
        JP Z,CCP_TAIL_9                  ; $A335  CA 94 A3
        LD HL,(L_A9D9)                   ; $A338  2A D9 A9
        EX DE,HL                         ; $A33B  EB
        LD A,(DE)                        ; $A33C  1A
        CP $E5                           ; $A33D  FE E5
        JP Z,SUB_A32D_1                  ; $A33F  CA 4A A3
        PUSH DE                          ; $A342  D5
        CALL RECPTR_CMP16                    ; $A343  CD 7F A1
        POP DE                           ; $A346  D1
        JP NC,CCP_TAIL_9                 ; $A347  D2 94 A3
SUB_A32D_1:
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A34A  CD 5E A1
        LD A,(L_A9D8)                    ; $A34D  3A D8 A9
        LD C,A                           ; $A350  4F
        LD B,$00                         ; $A351  06 00
SUB_A32D_2:
        LD A,C                           ; $A353  79
        OR A                             ; $A354  B7
        JP Z,CCP_TAIL_7                  ; $A355  CA 83 A3
        LD A,(DE)                        ; $A358  1A
        CP $3F                           ; $A359  FE 3F
        JP Z,SUB_A32D_4                  ; $A35B  CA 7C A3
        LD A,B                           ; $A35E  78
        CP $0D                           ; $A35F  FE 0D
        JP Z,SUB_A32D_4                  ; $A361  CA 7C A3
        CP $0C                           ; $A364  FE 0C
        LD A,(DE)                        ; $A366  1A
        JP Z,SUB_A32D_3                  ; $A367  CA 73 A3
        SUB (HL)                         ; $A36A  96
        AND $7F                          ; $A36B  E6 7F
        JP NZ,SUB_A32D                   ; $A36D  C2 2D A3
        JP SUB_A32D_4                    ; $A370  C3 7C A3
SUB_A32D_3:
        PUSH BC                          ; $A373  C5
        LD C,(HL)                        ; $A374  4E
        CALL SUB_A307                    ; $A375  CD 07 A3
        POP BC                           ; $A378  C1
        JP NZ,SUB_A32D                   ; $A379  C2 2D A3
SUB_A32D_4:
        INC DE                           ; $A37C  13
        INC HL                           ; $A37D  23
        INC B                            ; $A37E  04
        DEC C                            ; $A37F  0D
        JP SUB_A32D_2                    ; $A380  C3 53 A3
CCP_TAIL_7:
        LD A,(CUR_RECORD)                    ; $A383  3A EA A9
        AND $03                          ; $A386  E6 03
        LD (L_9F45),A                    ; $A388  32 45 9F
        LD HL,L_A9D4                     ; $A38B  21 D4 A9
        LD A,(HL)                        ; $A38E  7E
        RLA                              ; $A38F  17
        RET NC                           ; $A390  D0
        XOR A                            ; $A391  AF
        LD (HL),A                        ; $A392  77
        RET                              ; $A393  C9
CCP_TAIL_9:
        CALL SUB_A1FE                    ; $A394  CD FE A1
        LD A,$FF                         ; $A397  3E FF
        JP BDOS_RET_RESULT                   ; $A399  C3 01 9F
SUB_A39C:
        CALL CMD_EXEC_20                    ; $A39C  CD 54 A1
        LD C,$0C                         ; $A39F  0E 0C
        CALL SUB_A318                    ; $A3A1  CD 18 A3
SUB_A39C_1:
        CALL SUB_A1F5                    ; $A3A4  CD F5 A1
        RET Z                            ; $A3A7  C8
        CALL FCB_RO_FLAG_TEST                    ; $A3A8  CD 44 A1
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A3AB  CD 5E A1
        LD (HL),$E5                      ; $A3AE  36 E5
        LD C,$00                         ; $A3B0  0E 00
        CALL CMD_EXEC_61                    ; $A3B2  CD 6B A2
        CALL DIR_RECORD_WRITE                    ; $A3B5  CD C6 A1
        CALL SUB_A32D                    ; $A3B8  CD 2D A3
        JP SUB_A39C_1                    ; $A3BB  C3 A4 A3
CCP_TAIL_13:
        LD D,B                           ; $A3BE  50
        LD E,C                           ; $A3BF  59
SUB_A3BE_1:
        LD A,C                           ; $A3C0  79
        OR B                             ; $A3C1  B0
        JP Z,SUB_A3BE_2                  ; $A3C2  CA D1 A3
        DEC BC                           ; $A3C5  0B
        PUSH DE                          ; $A3C6  D5
        PUSH BC                          ; $A3C7  C5
        CALL CMD_EXEC_56                    ; $A3C8  CD 35 A2
        RRA                              ; $A3CB  1F
        JP NC,CCP_TAIL_15                 ; $A3CC  D2 EC A3
        POP BC                           ; $A3CF  C1
        POP DE                           ; $A3D0  D1
SUB_A3BE_2:
        LD HL,(MAX_BLOCK_DSM)                   ; $A3D1  2A C6 A9
        LD A,E                           ; $A3D4  7B
        SUB L                            ; $A3D5  95
        LD A,D                           ; $A3D6  7A
        SBC A,H                          ; $A3D7  9C
        JP NC,SUB_A3BE_4                 ; $A3D8  D2 F4 A3
        INC DE                           ; $A3DB  13
        PUSH BC                          ; $A3DC  C5
        PUSH DE                          ; $A3DD  D5
        LD B,D                           ; $A3DE  42
        LD C,E                           ; $A3DF  4B
        CALL CMD_EXEC_56                    ; $A3E0  CD 35 A2
        RRA                              ; $A3E3  1F
        JP NC,CCP_TAIL_15                 ; $A3E4  D2 EC A3
        POP DE                           ; $A3E7  D1
        POP BC                           ; $A3E8  C1
        JP SUB_A3BE_1                    ; $A3E9  C3 C0 A3
CCP_TAIL_15:
        RLA                              ; $A3EC  17
        INC A                            ; $A3ED  3C
        CALL SUB_A264                    ; $A3EE  CD 64 A2
        POP HL                           ; $A3F1  E1
        POP DE                           ; $A3F2  D1
        RET                              ; $A3F3  C9
SUB_A3BE_4:
        LD A,C                           ; $A3F4  79
        OR B                             ; $A3F5  B0
        JP NZ,SUB_A3BE_1                 ; $A3F6  C2 C0 A3
        LD HL,$0000                      ; $A3F9  21 00 00
        RET                              ; $A3FC  C9
SUB_A3FD:
        LD C,$00                         ; $A3FD  0E 00
        LD E,$20                         ; $A3FF  1E 20
SUB_A401:
        PUSH DE                          ; $A401  D5
        LD B,$00                         ; $A402  06 00
        LD HL,(L_9F43)                   ; $A404  2A 43 9F
        ADD HL,BC                        ; $A407  09
        EX DE,HL                         ; $A408  EB
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A409  CD 5E A1
        POP BC                           ; $A40C  C1
        CALL BDOS_RANDREC_2                    ; $A40D  CD 4F 9F
SUB_A401_1:
        CALL BDOS_RANDREC_9                    ; $A410  CD C3 9F
        JP DIR_RECORD_WRITE                      ; $A413  C3 C6 A1
FCB_SEQ_IO_STEP_3:
        CALL CMD_EXEC_20                    ; $A416  CD 54 A1
        LD C,$0C                         ; $A419  0E 0C
        CALL SUB_A318                    ; $A41B  CD 18 A3
        LD HL,(L_9F43)                   ; $A41E  2A 43 9F
        LD A,(HL)                        ; $A421  7E
        LD DE,$0010                      ; $A422  11 10 00
        ADD HL,DE                        ; $A425  19
        LD (HL),A                        ; $A426  77
SUB_A416_1:
        CALL SUB_A1F5                    ; $A427  CD F5 A1
        RET Z                            ; $A42A  C8
        CALL FCB_RO_FLAG_TEST                    ; $A42B  CD 44 A1
        LD C,$10                         ; $A42E  0E 10
        LD E,$0C                         ; $A430  1E 0C
        CALL SUB_A401                    ; $A432  CD 01 A4
        CALL SUB_A32D                    ; $A435  CD 2D A3
        JP SUB_A416_1                    ; $A438  C3 27 A4
FCB_SEQ_IO_STEP_6:
        LD C,$0C                         ; $A43B  0E 0C
        CALL SUB_A318                    ; $A43D  CD 18 A3
FCB_SEQ_IO_STEP_7:
        CALL SUB_A1F5                    ; $A440  CD F5 A1
        RET Z                            ; $A443  C8
        LD C,$00                         ; $A444  0E 00
        LD E,$0C                         ; $A446  1E 0C
        CALL SUB_A401                    ; $A448  CD 01 A4
        CALL SUB_A32D                    ; $A44B  CD 2D A3
        JP FCB_SEQ_IO_STEP_7                    ; $A44E  C3 40 A4
CONOUT_PUTC_1:
        LD C,$0F                         ; $A451  0E 0F
        CALL SUB_A318                    ; $A453  CD 18 A3
        CALL SUB_A1F5                    ; $A456  CD F5 A1
        RET Z                            ; $A459  C8
SUB_A45A:
        CALL DRV_INSTALL_RWTS_1                    ; $A45A  CD A6 A0
        LD A,(HL)                        ; $A45D  7E
        PUSH AF                          ; $A45E  F5
        PUSH HL                          ; $A45F  E5
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A460  CD 5E A1
        EX DE,HL                         ; $A463  EB
        LD HL,(L_9F43)                   ; $A464  2A 43 9F
        LD C,$20                         ; $A467  0E 20
        PUSH DE                          ; $A469  D5
        CALL BDOS_RANDREC_2                    ; $A46A  CD 4F 9F
        CALL SUB_A178                    ; $A46D  CD 78 A1
        POP DE                           ; $A470  D1
        LD HL,$000C                      ; $A471  21 0C 00
        ADD HL,DE                        ; $A474  19
        LD C,(HL)                        ; $A475  4E
        LD HL,$000F                      ; $A476  21 0F 00
        ADD HL,DE                        ; $A479  19
        LD B,(HL)                        ; $A47A  46
        POP HL                           ; $A47B  E1
        POP AF                           ; $A47C  F1
        LD (HL),A                        ; $A47D  77
        LD A,C                           ; $A47E  79
        CP (HL)                          ; $A47F  BE
        LD A,B                           ; $A480  78
        JP Z,SUB_A45A_1                  ; $A481  CA 8B A4
        LD A,$00                         ; $A484  3E 00
        JP C,SUB_A45A_1                  ; $A486  DA 8B A4
        LD A,$80                         ; $A489  3E 80
SUB_A45A_1:
        LD HL,(L_9F43)                   ; $A48B  2A 43 9F
        LD DE,$000F                      ; $A48E  11 0F 00
        ADD HL,DE                        ; $A491  19
        LD (HL),A                        ; $A492  77
        RET                              ; $A493  C9
BDOS_CON_2:
        LD A,(HL)                        ; $A494  7E
        INC HL                           ; $A495  23
        OR (HL)                          ; $A496  B6
        DEC HL                           ; $A497  2B
        RET NZ                           ; $A498  C0
        LD A,(DE)                        ; $A499  1A
        LD (HL),A                        ; $A49A  77
        INC DE                           ; $A49B  13
        INC HL                           ; $A49C  23
        LD A,(DE)                        ; $A49D  1A
        LD (HL),A                        ; $A49E  77
        DEC DE                           ; $A49F  1B
        DEC HL                           ; $A4A0  2B
        RET                              ; $A4A1  C9
BDOS_SET_RESULT_ZERO:
        XOR A                            ; $A4A2  AF
        LD (L_9F45),A                    ; $A4A3  32 45 9F
        LD (CUR_RECORD),A                    ; $A4A6  32 EA A9
        LD (L_A9EB),A                    ; $A4A9  32 EB A9
        CALL DRIVE_BIT_TEST                    ; $A4AC  CD 1E A1
        RET NZ                           ; $A4AF  C0
        CALL FCB_GET_S2                    ; $A4B0  CD 69 A1
        AND $80                          ; $A4B3  E6 80
        RET NZ                           ; $A4B5  C0
        LD C,$0F                         ; $A4B6  0E 0F
        CALL SUB_A318                    ; $A4B8  CD 18 A3
        CALL SUB_A1F5                    ; $A4BB  CD F5 A1
        RET Z                            ; $A4BE  C8
        LD BC,$0010                      ; $A4BF  01 10 00
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A4C2  CD 5E A1
        ADD HL,BC                        ; $A4C5  09
        EX DE,HL                         ; $A4C6  EB
        LD HL,(L_9F43)                   ; $A4C7  2A 43 9F
        ADD HL,BC                        ; $A4CA  09
        LD C,$10                         ; $A4CB  0E 10
SUB_A4A2_1:
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A4CD  3A DD A9
        OR A                             ; $A4D0  B7
        JP Z,BDOS_CON_12                  ; $A4D1  CA E8 A4
        LD A,(HL)                        ; $A4D4  7E
        OR A                             ; $A4D5  B7
        LD A,(DE)                        ; $A4D6  1A
        JP NZ,SUB_A4A2_2                 ; $A4D7  C2 DB A4
        LD (HL),A                        ; $A4DA  77
SUB_A4A2_2:
        OR A                             ; $A4DB  B7
        JP NZ,BDOS_READ_CON_BUF                 ; $A4DC  C2 E1 A4
        LD A,(HL)                        ; $A4DF  7E
        LD (DE),A                        ; $A4E0  12
BDOS_READ_CON_BUF:
        CP (HL)                          ; $A4E1  BE
        JP NZ,BDOS_DEC_RESULT                 ; $A4E2  C2 1F A5
        JP SUB_A4A2_5                    ; $A4E5  C3 FD A4
BDOS_CON_12:
        CALL BDOS_CON_2                    ; $A4E8  CD 94 A4
        EX DE,HL                         ; $A4EB  EB
        CALL BDOS_CON_2                    ; $A4EC  CD 94 A4
        EX DE,HL                         ; $A4EF  EB
        LD A,(DE)                        ; $A4F0  1A
        CP (HL)                          ; $A4F1  BE
        JP NZ,BDOS_DEC_RESULT                 ; $A4F2  C2 1F A5
        INC DE                           ; $A4F5  13
        INC HL                           ; $A4F6  23
        LD A,(DE)                        ; $A4F7  1A
        CP (HL)                          ; $A4F8  BE
        JP NZ,BDOS_DEC_RESULT                 ; $A4F9  C2 1F A5
        DEC C                            ; $A4FC  0D
SUB_A4A2_5:
        INC DE                           ; $A4FD  13
        INC HL                           ; $A4FE  23
        DEC C                            ; $A4FF  0D
        JP NZ,SUB_A4A2_1                 ; $A500  C2 CD A4
        LD BC,$FFEC                      ; $A503  01 EC FF
        ADD HL,BC                        ; $A506  09
        EX DE,HL                         ; $A507  EB
        ADD HL,BC                        ; $A508  09
        LD A,(DE)                        ; $A509  1A
        CP (HL)                          ; $A50A  BE
        JP C,SUB_A4A2_6                  ; $A50B  DA 17 A5
        LD (HL),A                        ; $A50E  77
        LD BC,$0003                      ; $A50F  01 03 00
        ADD HL,BC                        ; $A512  09
        EX DE,HL                         ; $A513  EB
        ADD HL,BC                        ; $A514  09
        LD A,(HL)                        ; $A515  7E
        LD (DE),A                        ; $A516  12
SUB_A4A2_6:
        LD A,$FF                         ; $A517  3E FF
        LD (L_A9D2),A                    ; $A519  32 D2 A9
        JP SUB_A401_1                    ; $A51C  C3 10 A4
BDOS_DEC_RESULT:
        LD HL,L_9F45                     ; $A51F  21 45 9F
        DEC (HL)                         ; $A522  35
        RET                              ; $A523  C9
DIR_READ_REC_TO_SCRATCH:
        CALL CMD_EXEC_20                    ; $A524  CD 54 A1
        LD HL,(L_9F43)                   ; $A527  2A 43 9F
        PUSH HL                          ; $A52A  E5
        LD HL,L_A9AC                     ; $A52B  21 AC A9
        LD (L_9F43),HL                   ; $A52E  22 43 9F
        LD C,$01                         ; $A531  0E 01
        CALL SUB_A318                    ; $A533  CD 18 A3
        CALL SUB_A1F5                    ; $A536  CD F5 A1
        POP HL                           ; $A539  E1
        LD (L_9F43),HL                   ; $A53A  22 43 9F
        RET Z                            ; $A53D  C8
        EX DE,HL                         ; $A53E  EB
        LD HL,$000F                      ; $A53F  21 0F 00
        ADD HL,DE                        ; $A542  19
        LD C,$11                         ; $A543  0E 11
        XOR A                            ; $A545  AF
SUB_A524_1:
        LD (HL),A                        ; $A546  77
        INC HL                           ; $A547  23
        DEC C                            ; $A548  0D
        JP NZ,SUB_A524_1                 ; $A549  C2 46 A5
        LD HL,$000D                      ; $A54C  21 0D 00
        ADD HL,DE                        ; $A54F  19
        LD (HL),A                        ; $A550  77
        CALL RECPTR_INC_STORE                    ; $A551  CD 8C A1
        CALL SUB_A3FD                    ; $A554  CD FD A3
        JP SUB_A178                      ; $A557  C3 78 A1
FCB_SET_REC_FLAG_3:
        XOR A                            ; $A55A  AF
        LD (L_A9D2),A                    ; $A55B  32 D2 A9
        CALL BDOS_SET_RESULT_ZERO                    ; $A55E  CD A2 A4
        CALL SUB_A1F5                    ; $A561  CD F5 A1
        RET Z                            ; $A564  C8
        LD HL,(L_9F43)                   ; $A565  2A 43 9F
        LD BC,$000C                      ; $A568  01 0C 00
        ADD HL,BC                        ; $A56B  09
        LD A,(HL)                        ; $A56C  7E
        INC A                            ; $A56D  3C
        AND $1F                          ; $A56E  E6 1F
        LD (HL),A                        ; $A570  77
        JP Z,FCB_SET_REC_FLAG_4                  ; $A571  CA 83 A5
        LD B,A                           ; $A574  47
        LD A,(L_A9C5)                    ; $A575  3A C5 A9
        AND B                            ; $A578  A0
        LD HL,L_A9D2                     ; $A579  21 D2 A9
        AND (HL)                         ; $A57C  A6
        JP Z,SUB_A55A_2                  ; $A57D  CA 8E A5
        JP FCB_SET_REC_FLAG_8                    ; $A580  C3 AC A5
FCB_SET_REC_FLAG_4:
        LD BC,$0002                      ; $A583  01 02 00
        ADD HL,BC                        ; $A586  09
        INC (HL)                         ; $A587  34
        LD A,(HL)                        ; $A588  7E
        AND $0F                          ; $A589  E6 0F
        JP Z,DISK_RET_OK_1                  ; $A58B  CA B6 A5
SUB_A55A_2:
        LD C,$0F                         ; $A58E  0E 0F
        CALL SUB_A318                    ; $A590  CD 18 A3
        CALL SUB_A1F5                    ; $A593  CD F5 A1
        JP NZ,FCB_SET_REC_FLAG_8                 ; $A596  C2 AC A5
        LD A,(L_A9D3)                    ; $A599  3A D3 A9
        INC A                            ; $A59C  3C
        JP Z,DISK_RET_OK_1                  ; $A59D  CA B6 A5
        CALL DIR_READ_REC_TO_SCRATCH                    ; $A5A0  CD 24 A5
        CALL SUB_A1F5                    ; $A5A3  CD F5 A1
        JP Z,DISK_RET_OK_1                  ; $A5A6  CA B6 A5
        JP SUB_A55A_4                    ; $A5A9  C3 AF A5
FCB_SET_REC_FLAG_8:
        CALL SUB_A45A                    ; $A5AC  CD 5A A4
SUB_A55A_4:
        CALL DRV_INSTALL_RWTS_3                    ; $A5AF  CD BB A0
        XOR A                            ; $A5B2  AF
        JP BDOS_RET_RESULT                   ; $A5B3  C3 01 9F
DISK_RET_OK_1:
        CALL BDOS_CHECK_ERROR_2                    ; $A5B6  CD 05 9F
        JP SUB_A178                      ; $A5B9  C3 78 A1
DISK_RET_OK_3:
        LD A,$01                         ; $A5BC  3E 01
        LD (L_A9D5),A                    ; $A5BE  32 D5 A9
SUB_A5C1:
        LD A,$FF                         ; $A5C1  3E FF
        LD (L_A9D3),A                    ; $A5C3  32 D3 A9
        CALL DRV_INSTALL_RWTS_3                    ; $A5C6  CD BB A0
        LD A,(L_A9E3)                    ; $A5C9  3A E3 A9
        LD HL,L_A9E1                     ; $A5CC  21 E1 A9
        CP (HL)                          ; $A5CF  BE
        JP C,SUB_A5C1_1                  ; $A5D0  DA E6 A5
        CP $80                           ; $A5D3  FE 80
        JP NZ,SUB_A5C1_2                 ; $A5D5  C2 FB A5
        CALL FCB_SET_REC_FLAG_3                    ; $A5D8  CD 5A A5
        XOR A                            ; $A5DB  AF
        LD (L_A9E3),A                    ; $A5DC  32 E3 A9
        LD A,(L_9F45)                    ; $A5DF  3A 45 9F
        OR A                             ; $A5E2  B7
        JP NZ,SUB_A5C1_2                 ; $A5E3  C2 FB A5
SUB_A5C1_1:
        CALL DISK_STORE_SEC_TRK_14                    ; $A5E6  CD 77 A0
        CALL DISK_STORE_SEC_TRK_16                    ; $A5E9  CD 84 A0
        JP Z,SUB_A5C1_2                  ; $A5EC  CA FB A5
        CALL DISK_STORE_SEC_TRK_17                    ; $A5EF  CD 8A A0
        CALL SUB_9FD1                    ; $A5F2  CD D1 9F
        CALL BDOS_RANDREC_7                    ; $A5F5  CD B2 9F
        JP DRV_INSTALL_RWTS_6                      ; $A5F8  C3 D2 A0
SUB_A5C1_2:
        JP BDOS_CHECK_ERROR_2                      ; $A5FB  C3 05 9F
SUB_A5C1_3:
        LD A,$01                         ; $A5FE  3E 01
        LD (L_A9D5),A                    ; $A600  32 D5 A9
SUB_A603:
        LD A,$00                         ; $A603  3E 00
        LD (L_A9D3),A                    ; $A605  32 D3 A9
        CALL CMD_EXEC_20                    ; $A608  CD 54 A1
        LD HL,(L_9F43)                   ; $A60B  2A 43 9F
        CALL SUB_A147                    ; $A60E  CD 47 A1
        CALL DRV_INSTALL_RWTS_3                    ; $A611  CD BB A0
        LD A,(L_A9E3)                    ; $A614  3A E3 A9
        CP $80                           ; $A617  FE 80
        JP NC,BDOS_CHECK_ERROR_2                   ; $A619  D2 05 9F
        CALL DISK_STORE_SEC_TRK_14                    ; $A61C  CD 77 A0
        CALL DISK_STORE_SEC_TRK_16                    ; $A61F  CD 84 A0
        LD C,$00                         ; $A622  0E 00
        JP NZ,SUB_A603_5                 ; $A624  C2 6E A6
        CALL DISK_STORE_SEC_TRK_6                    ; $A627  CD 3E A0
        LD (L_A9D7),A                    ; $A62A  32 D7 A9
        LD BC,$0000                      ; $A62D  01 00 00
        OR A                             ; $A630  B7
        JP Z,SUB_A603_1                  ; $A631  CA 3B A6
        LD C,A                           ; $A634  4F
        DEC BC                           ; $A635  0B
        CALL DISK_STORE_SEC_TRK_10                    ; $A636  CD 5E A0
        LD B,H                           ; $A639  44
        LD C,L                           ; $A63A  4D
SUB_A603_1:
        CALL CCP_TAIL_13                    ; $A63B  CD BE A3
        LD A,L                           ; $A63E  7D
        OR H                             ; $A63F  B4
        JP NZ,DIR_SEARCH_STEP_4                 ; $A640  C2 48 A6
        LD A,$02                         ; $A643  3E 02
        JP BDOS_RET_RESULT                   ; $A645  C3 01 9F
DIR_SEARCH_STEP_4:
        LD (L_A9E5),HL                   ; $A648  22 E5 A9
        EX DE,HL                         ; $A64B  EB
        LD HL,(L_9F43)                   ; $A64C  2A 43 9F
        LD BC,$0010                      ; $A64F  01 10 00
        ADD HL,BC                        ; $A652  09
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A653  3A DD A9
        OR A                             ; $A656  B7
        LD A,(L_A9D7)                    ; $A657  3A D7 A9
        JP Z,DISK_SET_DMA_PTR                  ; $A65A  CA 64 A6
        CALL SUB_A164                    ; $A65D  CD 64 A1
        LD (HL),E                        ; $A660  73
        JP SUB_A603_4                    ; $A661  C3 6C A6
DISK_SET_DMA_PTR:
        LD C,A                           ; $A664  4F
        LD B,$00                         ; $A665  06 00
        ADD HL,BC                        ; $A667  09
        ADD HL,BC                        ; $A668  09
        LD (HL),E                        ; $A669  73
        INC HL                           ; $A66A  23
        LD (HL),D                        ; $A66B  72
SUB_A603_4:
        LD C,$02                         ; $A66C  0E 02
SUB_A603_5:
        LD A,(L_9F45)                    ; $A66E  3A 45 9F
        OR A                             ; $A671  B7
        RET NZ                           ; $A672  C0
        PUSH BC                          ; $A673  C5
        CALL DISK_STORE_SEC_TRK_17                    ; $A674  CD 8A A0
        LD A,(L_A9D5)                    ; $A677  3A D5 A9
        DEC A                            ; $A67A  3D
        DEC A                            ; $A67B  3D
        JP NZ,SUB_A603_8                 ; $A67C  C2 BB A6
        POP BC                           ; $A67F  C1
        PUSH BC                          ; $A680  C5
        LD A,C                           ; $A681  79
        DEC A                            ; $A682  3D
        DEC A                            ; $A683  3D
        JP NZ,SUB_A603_8                 ; $A684  C2 BB A6
        PUSH HL                          ; $A687  E5
        LD HL,(DIRBUF_PTR)                   ; $A688  2A B9 A9
        LD D,A                           ; $A68B  57
DISK_DEBLOCK:
        LD (HL),A                        ; $A68C  77
        INC HL                           ; $A68D  23
        INC D                            ; $A68E  14
        JP P,DISK_DEBLOCK                  ; $A68F  F2 8C A6
        CALL SET_DMA_TO_DISK_BUF                    ; $A692  CD E0 A1
        LD HL,(L_A9E7)                   ; $A695  2A E7 A9
        LD C,$02                         ; $A698  0E 02
SUB_A603_7:
        LD (L_A9E5),HL                   ; $A69A  22 E5 A9
        PUSH BC                          ; $A69D  C5
        CALL SUB_9FD1                    ; $A69E  CD D1 9F
        POP BC                           ; $A6A1  C1
        CALL BDOS_RANDREC_8                    ; $A6A2  CD B8 9F
        LD HL,(L_A9E5)                   ; $A6A5  2A E5 A9
        LD C,$00                         ; $A6A8  0E 00
        LD A,(L_A9C4)                    ; $A6AA  3A C4 A9
        LD B,A                           ; $A6AD  47
        AND L                            ; $A6AE  A5
        CP B                             ; $A6AF  B8
        INC HL                           ; $A6B0  23
        JP NZ,SUB_A603_7                 ; $A6B1  C2 9A A6
        POP HL                           ; $A6B4  E1
        LD (L_A9E5),HL                   ; $A6B5  22 E5 A9
        CALL SUB_A1DA                    ; $A6B8  CD DA A1
SUB_A603_8:
        CALL SUB_9FD1                    ; $A6BB  CD D1 9F
        POP BC                           ; $A6BE  C1
        PUSH BC                          ; $A6BF  C5
        CALL BDOS_RANDREC_8                    ; $A6C0  CD B8 9F
        POP BC                           ; $A6C3  C1
        LD A,(L_A9E3)                    ; $A6C4  3A E3 A9
        LD HL,L_A9E1                     ; $A6C7  21 E1 A9
        CP (HL)                          ; $A6CA  BE
        JP C,SUB_A603_9                  ; $A6CB  DA D2 A6
        LD (HL),A                        ; $A6CE  77
        INC (HL)                         ; $A6CF  34
        LD C,$02                         ; $A6D0  0E 02
SUB_A603_9:
        NOP                              ; $A6D2  00
        NOP                              ; $A6D3  00
        LD HL,L_9400                     ; $A6D4  21 00 94
        PUSH AF                          ; $A6D7  F5
        CALL FCB_GET_S2                    ; $A6D8  CD 69 A1
        AND $7F                          ; $A6DB  E6 7F
        LD (HL),A                        ; $A6DD  77
        POP AF                           ; $A6DE  F1
        CP $7F                           ; $A6DF  FE 7F
        JP NZ,SUB_A603_11                ; $A6E1  C2 00 A7
        LD A,(L_A9D5)                    ; $A6E4  3A D5 A9
        CP $01                           ; $A6E7  FE 01
        JP NZ,SUB_A603_11                ; $A6E9  C2 00 A7
        CALL DRV_INSTALL_RWTS_6                    ; $A6EC  CD D2 A0
        CALL FCB_SET_REC_FLAG_3                    ; $A6EF  CD 5A A5
        LD HL,L_9F45                     ; $A6F2  21 45 9F
        LD A,(HL)                        ; $A6F5  7E
        OR A                             ; $A6F6  B7
        JP NZ,SUB_A603_10                ; $A6F7  C2 FE A6
        DEC A                            ; $A6FA  3D
        LD (L_A9E3),A                    ; $A6FB  32 E3 A9
SUB_A603_10:
        LD (HL),$00                      ; $A6FE  36 00
SUB_A603_11:
        JP DRV_INSTALL_RWTS_6                      ; $A700  C3 D2 A0
SUB_A703:
        XOR A                            ; $A703  AF
        LD (L_A9D5),A                    ; $A704  32 D5 A9
FCB_EXTRACT_RANDREC:
        PUSH BC                          ; $A707  C5
        LD HL,(L_9F43)                   ; $A708  2A 43 9F
        EX DE,HL                         ; $A70B  EB
        LD HL,$0021                      ; $A70C  21 21 00
        ADD HL,DE                        ; $A70F  19
        LD A,(HL)                        ; $A710  7E
        AND $7F                          ; $A711  E6 7F
        PUSH AF                          ; $A713  F5
        LD A,(HL)                        ; $A714  7E
        RLA                              ; $A715  17
        INC HL                           ; $A716  23
        LD A,(HL)                        ; $A717  7E
        RLA                              ; $A718  17
        AND $1F                          ; $A719  E6 1F
        LD C,A                           ; $A71B  4F
        LD A,(HL)                        ; $A71C  7E
        RRA                              ; $A71D  1F
        RRA                              ; $A71E  1F
        RRA                              ; $A71F  1F
        RRA                              ; $A720  1F
        AND $0F                          ; $A721  E6 0F
        LD B,A                           ; $A723  47
        POP AF                           ; $A724  F1
        INC HL                           ; $A725  23
        LD L,(HL)                        ; $A726  6E
        INC L                            ; $A727  2C
        DEC L                            ; $A728  2D
        LD L,$06                         ; $A729  2E 06
        JP NZ,SUB_A707_4                 ; $A72B  C2 8B A7
        LD HL,$0020                      ; $A72E  21 20 00
        ADD HL,DE                        ; $A731  19
        LD (HL),A                        ; $A732  77
        LD HL,$000C                      ; $A733  21 0C 00
        ADD HL,DE                        ; $A736  19
        LD A,C                           ; $A737  79
        SUB (HL)                         ; $A738  96
        JP NZ,SUB_A707_1                 ; $A739  C2 47 A7
        LD HL,$000E                      ; $A73C  21 0E 00
        ADD HL,DE                        ; $A73F  19
        LD A,B                           ; $A740  78
        SUB (HL)                         ; $A741  96
        AND $7F                          ; $A742  E6 7F
        JP Z,SUB_A707_2                  ; $A744  CA 7F A7
SUB_A707_1:
        PUSH BC                          ; $A747  C5
        PUSH DE                          ; $A748  D5
        CALL BDOS_SET_RESULT_ZERO                    ; $A749  CD A2 A4
        POP DE                           ; $A74C  D1
        POP BC                           ; $A74D  C1
        LD L,$03                         ; $A74E  2E 03
        LD A,(L_9F45)                    ; $A750  3A 45 9F
        INC A                            ; $A753  3C
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A754  CA 84 A7
        LD HL,$000C                      ; $A757  21 0C 00
        ADD HL,DE                        ; $A75A  19
        LD (HL),C                        ; $A75B  71
        LD HL,$000E                      ; $A75C  21 0E 00
        ADD HL,DE                        ; $A75F  19
        LD (HL),B                        ; $A760  70
        CALL CONOUT_PUTC_1                    ; $A761  CD 51 A4
        LD A,(L_9F45)                    ; $A764  3A 45 9F
        INC A                            ; $A767  3C
        JP NZ,SUB_A707_2                 ; $A768  C2 7F A7
        POP BC                           ; $A76B  C1
        PUSH BC                          ; $A76C  C5
        LD L,$04                         ; $A76D  2E 04
        INC C                            ; $A76F  0C
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A770  CA 84 A7
        CALL DIR_READ_REC_TO_SCRATCH                    ; $A773  CD 24 A5
        LD L,$05                         ; $A776  2E 05
        LD A,(L_9F45)                    ; $A778  3A 45 9F
        INC A                            ; $A77B  3C
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A77C  CA 84 A7
SUB_A707_2:
        POP BC                           ; $A77F  C1
        XOR A                            ; $A780  AF
        JP BDOS_RET_RESULT                   ; $A781  C3 01 9F
FCB_EXTENT_TO_TRKSEC_7:
        PUSH HL                          ; $A784  E5
        CALL FCB_GET_S2                    ; $A785  CD 69 A1
        LD (HL),$C0                      ; $A788  36 C0
        POP HL                           ; $A78A  E1
SUB_A707_4:
        POP BC                           ; $A78B  C1
        LD A,L                           ; $A78C  7D
        LD (L_9F45),A                    ; $A78D  32 45 9F
        JP SUB_A178                      ; $A790  C3 78 A1
FCB_EXTENT_TO_TRKSEC_8:
        LD C,$FF                         ; $A793  0E FF
        CALL SUB_A703                    ; $A795  CD 03 A7
        CALL Z,SUB_A5C1                  ; $A798  CC C1 A5
        RET                              ; $A79B  C9
FCB_EXTENT_TO_TRKSEC_9:
        LD C,$00                         ; $A79C  0E 00
        CALL SUB_A703                    ; $A79E  CD 03 A7
        CALL Z,SUB_A603                  ; $A7A1  CC 03 A6
        RET                              ; $A7A4  C9
FCB_ALLOC_PREP:
        EX DE,HL                         ; $A7A5  EB
        ADD HL,DE                        ; $A7A6  19
        LD C,(HL)                        ; $A7A7  4E
        LD B,$00                         ; $A7A8  06 00
        LD HL,$000C                      ; $A7AA  21 0C 00
        ADD HL,DE                        ; $A7AD  19
        LD A,(HL)                        ; $A7AE  7E
        RRCA                             ; $A7AF  0F
        AND $80                          ; $A7B0  E6 80
        ADD A,C                          ; $A7B2  81
        LD C,A                           ; $A7B3  4F
        LD A,$00                         ; $A7B4  3E 00
        ADC A,B                          ; $A7B6  88
        LD B,A                           ; $A7B7  47
        LD A,(HL)                        ; $A7B8  7E
        RRCA                             ; $A7B9  0F
        AND $0F                          ; $A7BA  E6 0F
        ADD A,B                          ; $A7BC  80
        LD B,A                           ; $A7BD  47
        LD HL,$000E                      ; $A7BE  21 0E 00
        ADD HL,DE                        ; $A7C1  19
        LD A,(HL)                        ; $A7C2  7E
        ADD A,A                          ; $A7C3  87
        ADD A,A                          ; $A7C4  87
        ADD A,A                          ; $A7C5  87
        ADD A,A                          ; $A7C6  87
        PUSH AF                          ; $A7C7  F5
        ADD A,B                          ; $A7C8  80
        LD B,A                           ; $A7C9  47
        PUSH AF                          ; $A7CA  F5
        POP HL                           ; $A7CB  E1
        LD A,L                           ; $A7CC  7D
        POP HL                           ; $A7CD  E1
        OR L                             ; $A7CE  B5
        AND $01                          ; $A7CF  E6 01
        RET                              ; $A7D1  C9
FCB_ALLOC_BLOCK_NUM_2:
        LD C,$0C                         ; $A7D2  0E 0C
        CALL SUB_A318                    ; $A7D4  CD 18 A3
        LD HL,(L_9F43)                   ; $A7D7  2A 43 9F
        LD DE,$0021                      ; $A7DA  11 21 00
        ADD HL,DE                        ; $A7DD  19
        PUSH HL                          ; $A7DE  E5
        LD (HL),D                        ; $A7DF  72
        INC HL                           ; $A7E0  23
        LD (HL),D                        ; $A7E1  72
        INC HL                           ; $A7E2  23
        LD (HL),D                        ; $A7E3  72
SUB_A7A5_2:
        CALL SUB_A1F5                    ; $A7E4  CD F5 A1
        JP Z,DRV_INSTALL_RWTS_13                  ; $A7E7  CA 0C A8
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A7EA  CD 5E A1
        LD DE,$000F                      ; $A7ED  11 0F 00
        CALL FCB_ALLOC_PREP                    ; $A7F0  CD A5 A7
        POP HL                           ; $A7F3  E1
        PUSH HL                          ; $A7F4  E5
        LD E,A                           ; $A7F5  5F
        LD A,C                           ; $A7F6  79
        SUB (HL)                         ; $A7F7  96
        INC HL                           ; $A7F8  23
        LD A,B                           ; $A7F9  78
        SBC A,(HL)                       ; $A7FA  9E
        INC HL                           ; $A7FB  23
        LD A,E                           ; $A7FC  7B
        SBC A,(HL)                       ; $A7FD  9E
        JP C,SUB_A7A5_3                  ; $A7FE  DA 06 A8
        LD (HL),E                        ; $A801  73
        DEC HL                           ; $A802  2B
        LD (HL),B                        ; $A803  70
        DEC HL                           ; $A804  2B
        LD (HL),C                        ; $A805  71
SUB_A7A5_3:
        CALL SUB_A32D                    ; $A806  CD 2D A3
        JP SUB_A7A5_2                    ; $A809  C3 E4 A7
DRV_INSTALL_RWTS_13:
        POP HL                           ; $A80C  E1
        RET                              ; $A80D  C9
F_RANDREC_H:
        LD HL,(L_9F43)                   ; $A80E  2A 43 9F
        LD DE,$0020                      ; $A811  11 20 00
        CALL FCB_ALLOC_PREP                    ; $A814  CD A5 A7
        LD HL,$0021                      ; $A817  21 21 00
        ADD HL,DE                        ; $A81A  19
        LD (HL),C                        ; $A81B  71
        INC HL                           ; $A81C  23
        LD (HL),B                        ; $A81D  70
        INC HL                           ; $A81E  23
        LD (HL),A                        ; $A81F  77
        RET                              ; $A820  C9
DRV_INSTALL_RWTS_17:
        LD HL,(L_A9AF)                   ; $A821  2A AF A9
        LD A,(L_9F42)                    ; $A824  3A 42 9F
        LD C,A                           ; $A827  4F
        CALL DRV_INSTALL_RWTS_10                    ; $A828  CD EA A0
        PUSH HL                          ; $A82B  E5
        EX DE,HL                         ; $A82C  EB
        CALL BDOS_RANDREC_3                    ; $A82D  CD 59 9F
        POP HL                           ; $A830  E1
        CALL Z,SUB_9F47                  ; $A831  CC 47 9F
        LD A,L                           ; $A834  7D
        RRA                              ; $A835  1F
        RET C                            ; $A836  D8
        LD HL,(L_A9AF)                   ; $A837  2A AF A9
        LD C,L                           ; $A83A  4D
        LD B,H                           ; $A83B  44
        CALL CMD_EXEC_12                    ; $A83C  CD 0B A1
        LD (L_A9AF),HL                   ; $A83F  22 AF A9
        JP CMD_EXEC_65                    ; $A842  C3 A3 A2
DRV_SET_H:
        LD A,(L_A9D6)                    ; $A845  3A D6 A9
        LD HL,L_9F42                     ; $A848  21 42 9F
        CP (HL)                          ; $A84B  BE
        RET Z                            ; $A84C  C8
        LD (HL),A                        ; $A84D  77
        JP DRV_INSTALL_RWTS_17                    ; $A84E  C3 21 A8
DISK_SEEK_TRACK_2:
        LD A,$FF                         ; $A851  3E FF
        LD (L_A9DE),A                    ; $A853  32 DE A9
        LD HL,(L_9F43)                   ; $A856  2A 43 9F
        LD A,(HL)                        ; $A859  7E
        AND $1F                          ; $A85A  E6 1F
        DEC A                            ; $A85C  3D
        LD (L_A9D6),A                    ; $A85D  32 D6 A9
        CP $1E                           ; $A860  FE 1E
        JP NC,SUB_A851_1                 ; $A862  D2 75 A8
        LD A,(L_9F42)                    ; $A865  3A 42 9F
        LD (L_A9DF),A                    ; $A868  32 DF A9
        LD A,(HL)                        ; $A86B  7E
        LD (L_A9E0),A                    ; $A86C  32 E0 A9
        AND $E0                          ; $A86F  E6 E0
        LD (HL),A                        ; $A871  77
        CALL DRV_SET_H                    ; $A872  CD 45 A8
SUB_A851_1:
        LD A,(L_9F41)                    ; $A875  3A 41 9F
        LD HL,(L_9F43)                   ; $A878  2A 43 9F
        OR (HL)                          ; $A87B  B6
        LD (HL),A                        ; $A87C  77
        RET                              ; $A87D  C9
S_BDOSVER_H:
        LD A,$22                         ; $A87E  3E 22
        JP BDOS_RET_RESULT                   ; $A880  C3 01 9F
DRV_ALLRESET_H:
        LD HL,$0000                      ; $A883  21 00 00
        LD (DRV_LOGIN_VECTOR),HL                   ; $A886  22 AD A9
        LD (L_A9AF),HL                   ; $A889  22 AF A9
        XOR A                            ; $A88C  AF
        LD (L_9F42),A                    ; $A88D  32 42 9F
        LD HL,$0080                      ; $A890  21 80 00
        LD (DMA_ADDR),HL                   ; $A893  22 B1 A9
        CALL SUB_A1DA                    ; $A896  CD DA A1
        JP DRV_INSTALL_RWTS_17                    ; $A899  C3 21 A8
F_OPEN_H:
        CALL SUB_A172                    ; $A89C  CD 72 A1
        CALL DISK_SEEK_TRACK_2                    ; $A89F  CD 51 A8
        JP CONOUT_PUTC_1                      ; $A8A2  C3 51 A4
F_CLOSE_H:
        CALL DISK_SEEK_TRACK_2                    ; $A8A5  CD 51 A8
        JP BDOS_SET_RESULT_ZERO                      ; $A8A8  C3 A2 A4
F_SFIRST_H:
        LD C,$00                         ; $A8AB  0E 00
        EX DE,HL                         ; $A8AD  EB
        LD A,(HL)                        ; $A8AE  7E
        CP $3F                           ; $A8AF  FE 3F
        JP Z,SUB_A851_7                  ; $A8B1  CA C2 A8
        CALL DRV_INSTALL_RWTS_1                    ; $A8B4  CD A6 A0
        LD A,(HL)                        ; $A8B7  7E
        CP $3F                           ; $A8B8  FE 3F
        CALL NZ,SUB_A172                 ; $A8BA  C4 72 A1
        CALL DISK_SEEK_TRACK_2                    ; $A8BD  CD 51 A8
        LD C,$0F                         ; $A8C0  0E 0F
SUB_A851_7:
        CALL SUB_A318                    ; $A8C2  CD 18 A3
        JP DISK_BUF_MOVE                    ; $A8C5  C3 E9 A1
F_SNEXT_H:
        LD HL,(L_A9D9)                   ; $A8C8  2A D9 A9
        LD (L_9F43),HL                   ; $A8CB  22 43 9F
        CALL DISK_SEEK_TRACK_2                    ; $A8CE  CD 51 A8
        CALL SUB_A32D                    ; $A8D1  CD 2D A3
        JP DISK_BUF_MOVE                    ; $A8D4  C3 E9 A1
F_DELETE_H:
        CALL DISK_SEEK_TRACK_2                    ; $A8D7  CD 51 A8
        CALL SUB_A39C                    ; $A8DA  CD 9C A3
        JP SUB_A26B_9                    ; $A8DD  C3 01 A3
F_READ_H:
        CALL DISK_SEEK_TRACK_2                    ; $A8E0  CD 51 A8
        JP DISK_RET_OK_3                    ; $A8E3  C3 BC A5
F_WRITE_H:
        CALL DISK_SEEK_TRACK_2                    ; $A8E6  CD 51 A8
        JP SUB_A5C1_3                    ; $A8E9  C3 FE A5
F_MAKE_H:
        CALL SUB_A172                    ; $A8EC  CD 72 A1
        CALL DISK_SEEK_TRACK_2                    ; $A8EF  CD 51 A8
        JP DIR_READ_REC_TO_SCRATCH                      ; $A8F2  C3 24 A5
F_RENAME_H:
        CALL DISK_SEEK_TRACK_2                    ; $A8F5  CD 51 A8
        CALL FCB_SEQ_IO_STEP_3                    ; $A8F8  CD 16 A4
        JP SUB_A26B_9                    ; $A8FB  C3 01 A3
DRV_LOGINVEC_H:
        LD HL,(L_A9AF)                   ; $A8FE  2A AF A9
        JP DIR_NAME_MASK_27                   ; $A901  C3 29 A9
DRV_GET_H:
        LD A,(L_9F42)                    ; $A904  3A 42 9F
        JP BDOS_RET_RESULT                   ; $A907  C3 01 9F
F_DMAOFF_H:
        EX DE,HL                         ; $A90A  EB
        LD (DMA_ADDR),HL                   ; $A90B  22 B1 A9
        JP SUB_A1DA                      ; $A90E  C3 DA A1
DRV_ALLOCVEC_H:
        LD HL,(ALLOC_VEC_PTR)                   ; $A911  2A BF A9
        JP DIR_NAME_MASK_27                   ; $A914  C3 29 A9
DRV_ROVEC_H:
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A917  2A AD A9
        JP DIR_NAME_MASK_27                   ; $A91A  C3 29 A9
F_ATTRIB_H:
        CALL DISK_SEEK_TRACK_2                    ; $A91D  CD 51 A8
        CALL FCB_SEQ_IO_STEP_6                    ; $A920  CD 3B A4
        JP SUB_A26B_9                    ; $A923  C3 01 A3
DRV_DPB_H:
        LD HL,(L_A9BB)                   ; $A926  2A BB A9
DIR_NAME_MASK_27:
        LD (L_9F45),HL                   ; $A929  22 45 9F
        RET                              ; $A92C  C9
F_USERNUM_H:
        LD A,(L_A9D6)                    ; $A92D  3A D6 A9
        CP $FF                           ; $A930  FE FF
        JP NZ,DIR_NAME_MASK_30                ; $A932  C2 3B A9
        LD A,(L_9F41)                    ; $A935  3A 41 9F
        JP BDOS_RET_RESULT                   ; $A938  C3 01 9F
DIR_NAME_MASK_30:
        AND $1F                          ; $A93B  E6 1F
        LD (L_9F41),A                    ; $A93D  32 41 9F
        RET                              ; $A940  C9
F_READRAND_H:
        CALL DISK_SEEK_TRACK_2                    ; $A941  CD 51 A8
        JP FCB_EXTENT_TO_TRKSEC_8                    ; $A944  C3 93 A7
F_WRITERAND_H:
        CALL DISK_SEEK_TRACK_2                    ; $A947  CD 51 A8
        JP FCB_EXTENT_TO_TRKSEC_9                    ; $A94A  C3 9C A7
F_SIZE_H:
        CALL DISK_SEEK_TRACK_2                    ; $A94D  CD 51 A8
        JP FCB_ALLOC_BLOCK_NUM_2                    ; $A950  C3 D2 A7
DIR_NAME_MASK_34:
        LD HL,(L_9F43)                   ; $A953  2A 43 9F
        LD A,L                           ; $A956  7D
        CPL                              ; $A957  2F
        LD E,A                           ; $A958  5F
        LD A,H                           ; $A959  7C
        CPL                              ; $A95A  2F
        LD HL,(L_A9AF)                   ; $A95B  2A AF A9
        AND H                            ; $A95E  A4
        LD D,A                           ; $A95F  57
        LD A,L                           ; $A960  7D
        AND E                            ; $A961  A3
        LD E,A                           ; $A962  5F
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A963  2A AD A9
        EX DE,HL                         ; $A966  EB
        LD (L_A9AF),HL                   ; $A967  22 AF A9
        LD A,L                           ; $A96A  7D
        AND E                            ; $A96B  A3
        LD L,A                           ; $A96C  6F
        LD A,H                           ; $A96D  7C
        AND D                            ; $A96E  A2
        LD H,A                           ; $A96F  67
        LD (DRV_LOGIN_VECTOR),HL                   ; $A970  22 AD A9
        RET                              ; $A973  C9
DIR_NAME_MASK_38:
        LD A,(L_A9DE)                    ; $A974  3A DE A9
        OR A                             ; $A977  B7
        JP Z,SUB_A851_29                 ; $A978  CA 91 A9
        LD HL,(L_9F43)                   ; $A97B  2A 43 9F
        LD (HL),$00                      ; $A97E  36 00
        LD A,(L_A9E0)                    ; $A980  3A E0 A9
        OR A                             ; $A983  B7
        JP Z,SUB_A851_29                 ; $A984  CA 91 A9
        LD (HL),A                        ; $A987  77
        LD A,(L_A9DF)                    ; $A988  3A DF A9
        LD (L_A9D6),A                    ; $A98B  32 D6 A9
        CALL DRV_SET_H                    ; $A98E  CD 45 A8
SUB_A851_29:
        LD HL,(L_9F0F)                   ; $A991  2A 0F 9F
        LD SP,HL                         ; $A994  F9
        LD HL,(L_9F45)                   ; $A995  2A 45 9F
        LD A,L                           ; $A998  7D
        LD B,H                           ; $A999  44
        RET                              ; $A99A  C9
F_WRITEZF_H:
        CALL DISK_SEEK_TRACK_2                    ; $A99B  CD 51 A8
        LD A,$02                         ; $A99E  3E 02
        LD (L_A9D5),A                    ; $A9A0  32 D5 A9
        LD C,$00                         ; $A9A3  0E 00
        CALL FCB_EXTRACT_RANDREC                    ; $A9A5  CD 07 A7
        CALL Z,SUB_A603                  ; $A9A8  CC 03 A6
        RET                              ; $A9AB  C9
L_A9AC:
        DEFB    $E5                                              ; $A9AC
DRV_LOGIN_VECTOR:
        DEFB    "\0\0"    ; $A9AD
L_A9AF:
        DEFB    "\0\0"    ; $A9AF
DMA_ADDR:
        DEFB    $80,$00                                          ; $A9B1
DPB_WORK_PTR0:
        DEFB    "\0\0"    ; $A9B3
L_A9B5:
        DEFB    "\0\0"    ; $A9B5
L_A9B7:
        DEFB    "\0\0"    ; $A9B7
DIRBUF_PTR:
        DEFB    "\0\0"    ; $A9B9
L_A9BB:
        DEFB    "\0\0"    ; $A9BB
REC_BYTE_OFFSET:
        DEFB    "\0\0"    ; $A9BD
ALLOC_VEC_PTR:
        DEFB    "\0\0"    ; $A9BF
L_A9C1:
        DEFB    "\0\0"    ; $A9C1
L_A9C3:
        DEFB    "\0"    ; $A9C3
L_A9C4:
        DEFB    "\0"    ; $A9C4
L_A9C5:
        DEFB    "\0"    ; $A9C5
MAX_BLOCK_DSM:
        DEFB    "\0\0"    ; $A9C6
DPB_REC_PTR:
        DEFB    "\0\0"    ; $A9C8
ALLOC_END_PTR:
        DEFB    "\0\0"    ; $A9CA
REC_SCAN_PTR:
        DEFB    "\0\0"    ; $A9CC
L_A9CE:
        DEFB    "\0\0"    ; $A9CE
L_A9D0:
        DEFB    "\0\0"    ; $A9D0
L_A9D2:
        DEFB    "\0"    ; $A9D2
L_A9D3:
        DEFB    "\0"    ; $A9D3
L_A9D4:
        DEFB    "\0"    ; $A9D4
L_A9D5:
        DEFB    "\0"    ; $A9D5
L_A9D6:
        DEFB    "\0"    ; $A9D6
L_A9D7:
        DEFB    "\0"    ; $A9D7
L_A9D8:
        DEFB    "\0"    ; $A9D8
L_A9D9:
        DEFB    "\0\0\0\0"    ; $A9D9
BLOCK_WIDTH_FLAG:
        DEFB    "\0"    ; $A9DD
L_A9DE:
        DEFB    "\0"    ; $A9DE
L_A9DF:
        DEFB    "\0"    ; $A9DF
L_A9E0:
        DEFB    "\0"    ; $A9E0
L_A9E1:
        DEFB    "\0"    ; $A9E1
L_A9E2:
        DEFB    "\0"    ; $A9E2
L_A9E3:
        DEFB    "\0\0"    ; $A9E3
L_A9E5:
        DEFB    "\0\0"    ; $A9E5
L_A9E7:
        DEFB    "\0\0"    ; $A9E7
DEBLOCK_BYTE_OFF:
        DEFB    "\0"    ; $A9E9
CUR_RECORD:
        DEFB    "\0"    ; $A9EA
L_A9EB:
        DEFB    "\0"    ; $A9EB
REC_CACHE:
        DEFS    20, $00    ; $A9EC  fill

    SAVEBIN "E:/tmp/cpm_system_full.bin", $9400, $1600
