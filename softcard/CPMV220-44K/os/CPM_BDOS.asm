; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- BDOS component ($9C00-$A9FF)
; ----------------------------------------------------------------------------
; Split from the former CPM_SystemImage.asm at the BDOS base ($9C00). BDOS
; function entry $9C06; dispatch via the runtime pointer cell $9F43. EQUs below
; resolve symbols defined in CPM_CCP.asm.
; ============================================================================

    DEVICE NOSLOT64K

; -- symbols referenced here but defined in CPM_CCP / externally --
BDOS_DISPATCH_PTR  EQU $9F43
L_9400             EQU $9400
L_9408             EQU $9408
SUB_9498           EQU $9498
SUB_94A7           EQU $94A7
SUB_94BD           EQU $94BD
SUB_9529           EQU $9529
SUB_95D5           EQU $95D5
SUB_9609           EQU $9609
SUB_965E           EQU $965E
SUB_965E_1         EQU $965F
SUB_972E_10        EQU $9781
SUB_9842           EQU $9842
SUB_9866           EQU $9866
SUB_9866_55        EQU $9B2E
SUB_9866_57        EQU $9B3E
SUB_9866_58        EQU $9B43
SUB_9866_59        EQU $9B4E
SUB_9866_62        EQU $9B71
SUB_9866_63        EQU $9B85
SUB_9866_68        EQU $9BDB

    ORG $9C00

        DEFB    $9A    ; $9C00  spillover: tail of the CCP JP at $9BFE
SUB_9866_70:
        POP HL                           ; $9C01  E1
        DEC A                            ; $9C02  3D
        JP NZ,SUB_9866_62                ; $9C03  C2 71 9B
        CALL SUB_9866                    ; $9C06  CD 66 98
SUB_9866_71:
        CALL SUB_965E                    ; $9C09  CD 5E 96
        LD HL,$9BF0                      ; $9C0C  21 F0 9B
        PUSH HL                          ; $9C0F  E5
        LD A,(HL)                        ; $9C10  7E
SUB_9866_72:
        LD ($9BCD),A                     ; $9C11  32 CD 9B
        LD A,$10                         ; $9C14  3E 10
        CALL SUB_965E_1+1                ; $9C16  CD 60 96
        POP HL                           ; $9C19  E1
        LD A,(HL)                        ; $9C1A  7E
        LD (SUB_9866_68+2),A             ; $9C1B  32 DD 9B
        XOR A                            ; $9C1E  AF
        LD ($9BED),A                     ; $9C1F  32 ED 9B
        LD DE,$005C                      ; $9C22  11 5C 00
        LD HL,$9BCD                      ; $9C25  21 CD 9B
        LD B,$21                         ; $9C28  06 21
        CALL SUB_9842                    ; $9C2A  CD 42 98
        LD HL,L_9408                     ; $9C2D  21 08 94
        LD A,(HL)                        ; $9C30  7E
        OR A                             ; $9C31  B7
        JP Z,SUB_9866_57                 ; $9C32  CA 3E 9B
        CP $20                           ; $9C35  FE 20
        JP Z,SUB_9866_57                 ; $9C37  CA 3E 9B
        INC HL                           ; $9C3A  23
        JP SUB_9866_55+2                 ; $9C3B  C3 30 9B
SUB_9866_73:
        LD B,$00                         ; $9C3E  06 00
        LD DE,$0081                      ; $9C40  11 81 00
        LD A,(HL)                        ; $9C43  7E
        LD (DE),A                        ; $9C44  12
        OR A                             ; $9C45  B7
SUB_9866_74:
        JP Z,SUB_9866_59+1               ; $9C46  CA 4F 9B
        INC B                            ; $9C49  04
        INC HL                           ; $9C4A  23
        INC DE                           ; $9C4B  13
        JP SUB_9866_58                   ; $9C4C  C3 43 9B
SUB_9866_75:
        LD A,B                           ; $9C4F  78
        LD ($0080),A                     ; $9C50  32 80 00
        CALL SUB_9498                    ; $9C53  CD 98 94
        CALL SUB_95D5                    ; $9C56  CD D5 95
        CALL $951A                    ; $9C59  CD 1A 95
        CALL $0100                       ; $9C5C  CD 00 01
        LD SP,$9BAB                      ; $9C5F  31 AB 9B
        CALL SUB_9529                    ; $9C62  CD 29 95
        CALL SUB_94BD                    ; $9C65  CD BD 94
        JP SUB_972E_10+1                 ; $9C68  C3 82 97
SUB_9866_76:
        CALL SUB_9866                    ; $9C6B  CD 66 98
        JP SUB_9609                      ; $9C6E  C3 09 96
SUB_9866_77:
        LD BC,$9B7A                      ; $9C71  01 7A 9B
        CALL SUB_94A7                    ; $9C74  CD A7 94
        JP SUB_9866_63+1                 ; $9C77  C3 86 9B
MSG_BAD_LOAD:
        DEFB    "BAD LOAD"  ; $9C7A  CP/M error text
        DEFB    $00    ; $9C82  terminator
STR_COM:
        DEFB    "COM"  ; $9C83  default transient file type
SUB_9866_78:
        CALL SUB_9866                    ; $9C86  CD 66 98
        CALL SUB_965E                    ; $9C89  CD 5E 96
        LD A,($9BCE)                     ; $9C8C  3A CE 9B
        SUB $20                          ; $9C8F  D6 20
        LD HL,$9BF0                      ; $9C91  21 F0 9B
        OR (HL)                          ; $9C94  B6
        JP NZ,SUB_9609                   ; $9C95  C2 09 96
        JP SUB_972E_10+1                 ; $9C98  C3 82 97
        DEFS    18, $00    ; $9C9B  fill
        DEFB    $24,$24,$24,$20,$20,$20,$20                      ; $9CAD
L_9CB4:
        DEFB    " SUB"    ; $9CB4  string
        DEFB    $00    ; $9CB8  terminator
        DEFB    $00                                              ; $9CB9
L_9CBA:
        DEFS    12, $00    ; $9CBA  fill
L_9CC6:
        DEFB    $00,$00,$00,$00                                  ; $9CC6
L_9CCA:
        DEFS    11, $00    ; $9CCA  fill
L_9CD5:
        DEFB    $00,$00,$00,$00,$00,$00,$00                      ; $9CD5
L_9CDC:
        DEFB    $00,$00,$00,$00,$00                              ; $9CDC
L_9CE1:
        DEFB    $00,$00,$00,$00                                  ; $9CE1
SUB_9CE5:
        DEFS    22, $00    ; $9CE5  fill
SUB_9CFB:
        DEFB    $00,$00,$00,$00,$00,$A2,$3A,$D4,$A9,$C3,$01      ; $9CFB
SUB_9D06:
        SBC A,A                          ; $9D06  9F
        PUSH BC                          ; $9D07  C5
        PUSH AF                          ; $9D08  F5
        LD A,(L_A9C5)                    ; $9D09  3A C5 A9
        CPL                              ; $9D0C  2F
        LD B,A                           ; $9D0D  47
        LD A,C                           ; $9D0E  79
        AND B                            ; $9D0F  A0
        LD C,A                           ; $9D10  4F
        POP AF                           ; $9D11  F1
        AND B                            ; $9D12  A0
        SUB C                            ; $9D13  91
SUB_9D14:
        AND $1F                          ; $9D14  E6 1F
        POP BC                           ; $9D16  C1
        RET                              ; $9D17  C9
SUB_9D14_1:
        LD A,$FF                         ; $9D18  3E FF
        LD (L_A9D4),A                    ; $9D1A  32 D4 A9
        LD HL,L_A9D8                     ; $9D1D  21 D8 A9
        LD (HL),C                        ; $9D20  71
SUB_9D14_2:
        LD HL,(BDOS_DISPATCH_PTR)        ; $9D21  2A 43 9F
        LD (L_A9D9),HL                   ; $9D24  22 D9 A9
        CALL SUB_A1FE                    ; $9D27  CD FE A1
        CALL SUB_9FA1                    ; $9D2A  CD A1 9F
        LD C,$00                         ; $9D2D  0E 00
        CALL SUB_A1FE_1+1                ; $9D2F  CD 05 A2
        CALL SUB_A1F5                    ; $9D32  CD F5 A1
        JP Z,SUB_A32D_7+2                ; $9D35  CA 94 A3
        LD HL,(L_A9D9)                   ; $9D38  2A D9 A9
        EX DE,HL                         ; $9D3B  EB
        LD A,(DE)                        ; $9D3C  1A
        CP $E5                           ; $9D3D  FE E5
        JP Z,SUB_A32D_1+2                ; $9D3F  CA 4A A3
SUB_9D14_3:
        PUSH DE                          ; $9D42  D5
SUB_9D14_4:
        CALL SUB_A178_1+2                ; $9D43  CD 7F A1
        POP DE                           ; $9D46  D1
SUB_9D14_5:
        JP NC,SUB_A32D_7+2               ; $9D47  D2 94 A3
        CALL SUB_A15E                    ; $9D4A  CD 5E A1
        LD A,(L_A9D8)                    ; $9D4D  3A D8 A9
        LD C,A                           ; $9D50  4F
        LD B,$00                         ; $9D51  06 00
        LD A,C                           ; $9D53  79
        OR A                             ; $9D54  B7
        JP Z,SUB_A32D_6                  ; $9D55  CA 83 A3
        LD A,(DE)                        ; $9D58  1A
        CP $3F                           ; $9D59  FE 3F
        JP Z,SUB_A32D_5                  ; $9D5B  CA 7C A3
        LD A,B                           ; $9D5E  78
        CP $0D                           ; $9D5F  FE 0D
SUB_9D14_6:
        JP Z,SUB_A32D_5                  ; $9D61  CA 7C A3
        CP $0C                           ; $9D64  FE 0C
        LD A,(DE)                        ; $9D66  1A
        JP Z,SUB_A32D_4                  ; $9D67  CA 73 A3
        SUB (HL)                         ; $9D6A  96
        AND $7F                          ; $9D6B  E6 7F
        JP NZ,SUB_A32D                   ; $9D6D  C2 2D A3
        JP SUB_A32D_5                    ; $9D70  C3 7C A3
SUB_9D14_7:
        PUSH BC                          ; $9D73  C5
        LD C,(HL)                        ; $9D74  4E
        CALL SUB_A26B_19+2               ; $9D75  CD 07 A3
        POP BC                           ; $9D78  C1
SUB_9D14_8:
        JP NZ,SUB_A32D                   ; $9D79  C2 2D A3
        INC DE                           ; $9D7C  13
        INC HL                           ; $9D7D  23
        INC B                            ; $9D7E  04
SUB_9D7F:
        DEC C                            ; $9D7F  0D
        JP SUB_A32D_2                    ; $9D80  C3 53 A3
SUB_9D7F_1:
        LD A,(L_A9EA)                    ; $9D83  3A EA A9
        AND $03                          ; $9D86  E6 03
        LD (SUB_9DA4_35+1),A             ; $9D88  32 45 9F
        LD HL,L_A9D4                     ; $9D8B  21 D4 A9
        LD A,(HL)                        ; $9D8E  7E
        RLA                              ; $9D8F  17
SUB_9D90:
        RET NC                           ; $9D90  D0
        XOR A                            ; $9D91  AF
        LD (HL),A                        ; $9D92  77
        RET                              ; $9D93  C9
SUB_9D90_1:
        CALL SUB_A1FE                    ; $9D94  CD FE A1
        LD A,$FF                         ; $9D97  3E FF
        JP SUB_9DA4_31                   ; $9D99  C3 01 9F
SUB_9D90_2:
        CALL SUB_A154                    ; $9D9C  CD 54 A1
        LD C,$0C                         ; $9D9F  0E 0C
        CALL SUB_A26B_20+1               ; $9DA1  CD 18 A3
SUB_9DA4:
        CALL SUB_A1F5                    ; $9DA4  CD F5 A1
        RET Z                            ; $9DA7  C8
        CALL SUB_A10B_5+1                ; $9DA8  CD 44 A1
SUB_9DA4_1:
        CALL SUB_A15E                    ; $9DAB  CD 5E A1
        LD (HL),$E5                      ; $9DAE  36 E5
SUB_9DA4_2:
        LD C,$00                         ; $9DB0  0E 00
        CALL SUB_A26B                    ; $9DB2  CD 6B A2
        CALL SUB_A1C6                    ; $9DB5  CD C6 A1
SUB_9DA4_3:
        CALL SUB_A32D                    ; $9DB8  CD 2D A3
        JP SUB_A32D_9+2                  ; $9DBB  C3 A4 A3
SUB_9DA4_4:
        LD D,B                           ; $9DBE  50
        LD E,C                           ; $9DBF  59
        LD A,C                           ; $9DC0  79
        OR B                             ; $9DC1  B0
        JP Z,SUB_A3BE_2+1                ; $9DC2  CA D1 A3
        DEC BC                           ; $9DC5  0B
        PUSH DE                          ; $9DC6  D5
        PUSH BC                          ; $9DC7  C5
SUB_9DA4_5:
        CALL SUB_A1FE_6+1                ; $9DC8  CD 35 A2
        RRA                              ; $9DCB  1F
        JP NC,SUB_A3BE_3                 ; $9DCC  D2 EC A3
        POP BC                           ; $9DCF  C1
        POP DE                           ; $9DD0  D1
SUB_9DA4_6:
        LD HL,(L_A9C6)                   ; $9DD1  2A C6 A9
        LD A,E                           ; $9DD4  7B
        SUB L                            ; $9DD5  95
        LD A,D                           ; $9DD6  7A
        SBC A,H                          ; $9DD7  9C
        JP NC,SUB_A3BE_4+2               ; $9DD8  D2 F4 A3
        INC DE                           ; $9DDB  13
        PUSH BC                          ; $9DDC  C5
        PUSH DE                          ; $9DDD  D5
        LD B,D                           ; $9DDE  42
        LD C,E                           ; $9DDF  4B
SUB_9DA4_7:
        CALL SUB_A1FE_6+1                ; $9DE0  CD 35 A2
        RRA                              ; $9DE3  1F
        JP NC,SUB_A3BE_3                 ; $9DE4  D2 EC A3
        POP DE                           ; $9DE7  D1
        POP BC                           ; $9DE8  C1
        JP SUB_A3BE_1                    ; $9DE9  C3 C0 A3
SUB_9DA4_8:
        RLA                              ; $9DEC  17
        INC A                            ; $9DED  3C
SUB_9DA4_9:
        CALL SUB_A264                    ; $9DEE  CD 64 A2
SUB_9DA4_10:
        POP HL                           ; $9DF1  E1
        POP DE                           ; $9DF2  D1
        RET                              ; $9DF3  C9
        DEFB    $79,$B0,$C2,$C0,$A3,$21,$00                      ; $9DF4  "y0B@#!"
SUB_9DA4_11:
        NOP                              ; $9DFB  00
        RET                              ; $9DFC  C9
SUB_9DA4_12:
        LD C,$00                         ; $9DFD  0E 00
        LD E,$BD                         ; $9DFF  1E BD
        LD D,$00                         ; $9E01  16 00
        NOP                              ; $9E03  00
        LD D,$DF                         ; $9E04  16 DF
        JP SUB_9866_72                   ; $9E06  C3 11 9C
        DEFB    $99,$9C,$A5,$9C,$AB,$9C,$B1,$9C,$EB,$22,$43,$9F,$EB ; $9E09
SUB_9DA4_13:
        LD A,E                           ; $9E16  7B
        LD (L_A9D6),A                    ; $9E17  32 D6 A9
SUB_9DA4_14:
        LD HL,$0000                      ; $9E1A  21 00 00
        LD (SUB_9DA4_35+1),HL            ; $9E1D  22 45 9F
        ADD HL,SP                        ; $9E20  39
        LD ($9F0F),HL                    ; $9E21  22 0F 9F
SUB_9DA4_15:
        LD SP,$9F41                      ; $9E24  31 41 9F
        XOR A                            ; $9E27  AF
        LD (L_A9E0),A                    ; $9E28  32 E0 A9
        LD (L_A9DE),A                    ; $9E2B  32 DE A9
        LD HL,L_A974                     ; $9E2E  21 74 A9
        PUSH HL                          ; $9E31  E5
        LD A,C                           ; $9E32  79
        CP $29                           ; $9E33  FE 29
        RET NC                           ; $9E35  D0
        LD C,E                           ; $9E36  4B
SUB_9DA4_16:
        LD HL,SUB_9866_74+1              ; $9E37  21 47 9C
        LD E,A                           ; $9E3A  5F
        LD D,$00                         ; $9E3B  16 00
        ADD HL,DE                        ; $9E3D  19
        ADD HL,DE                        ; $9E3E  19
        LD E,(HL)                        ; $9E3F  5E
        INC HL                           ; $9E40  23
        LD D,(HL)                        ; $9E41  56
        LD HL,(BDOS_DISPATCH_PTR)        ; $9E42  2A 43 9F
        EX DE,HL                         ; $9E45  EB
        JP (HL)                          ; $9E46  E9
SUB_9DA4_17:
        INC BC                           ; $9E47  03
SUB_9DA4_18:
        XOR D                            ; $9E48  AA
        RET Z                            ; $9E49  C8
        SBC A,(HL)                       ; $9E4A  9E
        SUB B                            ; $9E4B  90
        SBC A,L                          ; $9E4C  9D
SUB_9DA4_19:
        ADC A,$9E                        ; $9E4D  CE 9E
        LD (DE),A                        ; $9E4F  12
        XOR D                            ; $9E50  AA
        RRCA                             ; $9E51  0F
        XOR D                            ; $9E52  AA
        CALL NC,$ED9E                    ; $9E53  D4 9E ED
        SBC A,(HL)                       ; $9E56  9E
        DI                               ; $9E57  F3
        SBC A,(HL)                       ; $9E58  9E
        RET M                            ; $9E59  F8
        SBC A,(HL)                       ; $9E5A  9E
        POP HL                           ; $9E5B  E1
        SBC A,L                          ; $9E5C  9D
        CP $9E                           ; $9E5D  FE 9E
SUB_9DA4_20:
        LD A,(HL)                        ; $9E5F  7E
        XOR B                            ; $9E60  A8
        ADD A,E                          ; $9E61  83
        XOR B                            ; $9E62  A8
        LD B,L                           ; $9E63  45
        XOR B                            ; $9E64  A8
        SBC A,H                          ; $9E65  9C
        XOR B                            ; $9E66  A8
        AND L                            ; $9E67  A5
        XOR B                            ; $9E68  A8
        XOR E                            ; $9E69  AB
        XOR B                            ; $9E6A  A8
SUB_9DA4_21:
        RET Z                            ; $9E6B  C8
        XOR B                            ; $9E6C  A8
        RST $10                          ; $9E6D  D7
        XOR B                            ; $9E6E  A8
        RET PO                           ; $9E6F  E0
SUB_9DA4_22:
        XOR B                            ; $9E70  A8
        AND $A8                          ; $9E71  E6 A8
        CALL PE,$F5A8                    ; $9E73  EC A8 F5
        XOR B                            ; $9E76  A8
SUB_9DA4_23:
        CP $A8                           ; $9E77  FE A8
        INC B                            ; $9E79  04
        XOR C                            ; $9E7A  A9
        LD A,(BC)                        ; $9E7B  0A
        XOR C                            ; $9E7C  A9
        LD DE,$2CA9                      ; $9E7D  11 A9 2C
        AND C                            ; $9E80  A1
        RLA                              ; $9E81  17
        XOR C                            ; $9E82  A9
        DEC E                            ; $9E83  1D
        XOR C                            ; $9E84  A9
        LD H,$A9                         ; $9E85  26 A9
        DEC L                            ; $9E87  2D
        XOR C                            ; $9E88  A9
        LD B,C                           ; $9E89  41
SUB_9DA4_24:
        XOR C                            ; $9E8A  A9
        LD B,A                           ; $9E8B  47
        XOR C                            ; $9E8C  A9
        LD C,L                           ; $9E8D  4D
        XOR C                            ; $9E8E  A9
        LD C,$A8                         ; $9E8F  0E A8
        LD D,E                           ; $9E91  53
        XOR C                            ; $9E92  A9
        INC B                            ; $9E93  04
        SBC A,A                          ; $9E94  9F
        INC B                            ; $9E95  04
        SBC A,A                          ; $9E96  9F
        SBC A,E                          ; $9E97  9B
        XOR C                            ; $9E98  A9
SUB_9DA4_25:
        LD HL,L_9CCA                     ; $9E99  21 CA 9C
        CALL SUB_9CE5                    ; $9E9C  CD E5 9C
        CP $03                           ; $9E9F  FE 03
        JP Z,$0000                       ; $9EA1  CA 00 00
        RET                              ; $9EA4  C9
SUB_9DA4_26:
        LD HL,L_9CD5                     ; $9EA5  21 D5 9C
SUB_9DA4_27:
        JP L_9CB4                        ; $9EA8  C3 B4 9C
SUB_9DA4_28:
        LD HL,L_9CE1                     ; $9EAB  21 E1 9C
        JP L_9CB4                        ; $9EAE  C3 B4 9C
SUB_9DA4_29:
        LD HL,L_9CDC                     ; $9EB1  21 DC 9C
        CALL SUB_9CE5                    ; $9EB4  CD E5 9C
        JP $0000                         ; $9EB7  C3 00 00
MSG_BDOS_ERR:
        DEFB    "Bdos Err On  : $Bad Sector$Select$File R/O$"  ; $9EBA  BDOS run-time error texts ($-terminated substrings)
SUB_9DA4_30:
        PUSH HL                          ; $9EE5  E5
        CALL SUB_9DA4_5+1                ; $9EE6  CD C9 9D
        LD A,($9F42)                     ; $9EE9  3A 42 9F
        ADD A,$41                        ; $9EEC  C6 41
        LD (L_9CC6),A                    ; $9EEE  32 C6 9C
        LD BC,L_9CBA                     ; $9EF1  01 BA 9C
        CALL SUB_9DA4_6+2                ; $9EF4  CD D3 9D
        POP BC                           ; $9EF7  C1
        CALL SUB_9DA4_6+2                ; $9EF8  CD D3 9D
        LD HL,$9F0E                      ; $9EFB  21 0E 9F
        LD A,(HL)                        ; $9EFE  7E
        LD (HL),$20                      ; $9EFF  36 20
SUB_9DA4_31:
        PUSH DE                          ; $9F01  D5
        LD B,$00                         ; $9F02  06 00
SUB_9DA4_32:
        LD HL,(BDOS_DISPATCH_PTR)        ; $9F04  2A 43 9F
        ADD HL,BC                        ; $9F07  09
        EX DE,HL                         ; $9F08  EB
        CALL SUB_A15E                    ; $9F09  CD 5E A1
        POP BC                           ; $9F0C  C1
        CALL SUB_9DA4_38+1               ; $9F0D  CD 4F 9F
        CALL SUB_9FB8_2+1                ; $9F10  CD C3 9F
        JP SUB_A1C6                      ; $9F13  C3 C6 A1
SUB_9DA4_33:
        CALL SUB_A154                    ; $9F16  CD 54 A1
        LD C,$0C                         ; $9F19  0E 0C
        CALL SUB_A26B_20+1               ; $9F1B  CD 18 A3
        LD HL,(BDOS_DISPATCH_PTR)        ; $9F1E  2A 43 9F
        LD A,(HL)                        ; $9F21  7E
        LD DE,$0010                      ; $9F22  11 10 00
        ADD HL,DE                        ; $9F25  19
        LD (HL),A                        ; $9F26  77
        CALL SUB_A1F5                    ; $9F27  CD F5 A1
        RET Z                            ; $9F2A  C8
        CALL SUB_A10B_5+1                ; $9F2B  CD 44 A1
        LD C,$10                         ; $9F2E  0E 10
        LD E,$0C                         ; $9F30  1E 0C
        CALL SUB_A401                    ; $9F32  CD 01 A4
        CALL SUB_A32D                    ; $9F35  CD 2D A3
        JP L_A427                        ; $9F38  C3 27 A4
SUB_9DA4_34:
        LD C,$0C                         ; $9F3B  0E 0C
        CALL SUB_A26B_20+1               ; $9F3D  CD 18 A3
        CALL SUB_A1F5                    ; $9F40  CD F5 A1
        RET Z                            ; $9F43  C8
SUB_9DA4_35:
        LD C,$00                         ; $9F44  0E 00
SUB_9DA4_36:
        LD E,$0C                         ; $9F46  1E 0C
SUB_9DA4_37:
        CALL SUB_A401                    ; $9F48  CD 01 A4
        CALL SUB_A32D                    ; $9F4B  CD 2D A3
SUB_9DA4_38:
        JP L_A440                        ; $9F4E  C3 40 A4
        LD C,$0F                         ; $9F51  0E 0F
        CALL SUB_A26B_20+1               ; $9F53  CD 18 A3
        CALL SUB_A1F5                    ; $9F56  CD F5 A1
SUB_9F59:
        RET Z                            ; $9F59  C8
        CALL SUB_A077_6+2                ; $9F5A  CD A6 A0
        LD A,(HL)                        ; $9F5D  7E
        PUSH AF                          ; $9F5E  F5
        PUSH HL                          ; $9F5F  E5
        CALL SUB_A15E                    ; $9F60  CD 5E A1
        EX DE,HL                         ; $9F63  EB
        LD HL,(BDOS_DISPATCH_PTR)        ; $9F64  2A 43 9F
        LD C,$20                         ; $9F67  0E 20
        PUSH DE                          ; $9F69  D5
        CALL SUB_9DA4_38+1               ; $9F6A  CD 4F 9F
        CALL SUB_A178                    ; $9F6D  CD 78 A1
        POP DE                           ; $9F70  D1
        LD HL,$000C                      ; $9F71  21 0C 00
        ADD HL,DE                        ; $9F74  19
        LD C,(HL)                        ; $9F75  4E
        LD HL,$000F                      ; $9F76  21 0F 00
        ADD HL,DE                        ; $9F79  19
        LD B,(HL)                        ; $9F7A  46
        POP HL                           ; $9F7B  E1
        POP AF                           ; $9F7C  F1
        LD (HL),A                        ; $9F7D  77
        LD A,C                           ; $9F7E  79
        CP (HL)                          ; $9F7F  BE
        LD A,B                           ; $9F80  78
        JP Z,SUB_A451_2                  ; $9F81  CA 8B A4
        LD A,$00                         ; $9F84  3E 00
        JP C,SUB_A451_2                  ; $9F86  DA 8B A4
        LD A,$80                         ; $9F89  3E 80
        LD HL,(BDOS_DISPATCH_PTR)        ; $9F8B  2A 43 9F
        LD DE,$000F                      ; $9F8E  11 0F 00
        ADD HL,DE                        ; $9F91  19
        LD (HL),A                        ; $9F92  77
        RET                              ; $9F93  C9
SUB_9F59_1:
        LD A,(HL)                        ; $9F94  7E
        INC HL                           ; $9F95  23
        OR (HL)                          ; $9F96  B6
        DEC HL                           ; $9F97  2B
        RET NZ                           ; $9F98  C0
        LD A,(DE)                        ; $9F99  1A
        LD (HL),A                        ; $9F9A  77
        INC DE                           ; $9F9B  13
        INC HL                           ; $9F9C  23
SUB_9F59_2:
        LD A,(DE)                        ; $9F9D  1A
        LD (HL),A                        ; $9F9E  77
        DEC DE                           ; $9F9F  1B
        DEC HL                           ; $9FA0  2B
SUB_9FA1:
        RET                              ; $9FA1  C9
SUB_9FA1_1:
        XOR A                            ; $9FA2  AF
        LD (SUB_9DA4_35+1),A             ; $9FA3  32 45 9F
        LD (L_A9EA),A                    ; $9FA6  32 EA A9
        LD (L_A9EB),A                    ; $9FA9  32 EB A9
        CALL SUB_A10B_1+2                ; $9FAC  CD 1E A1
        RET NZ                           ; $9FAF  C0
SUB_9FA1_2:
        CALL SUB_A164_1+1                ; $9FB0  CD 69 A1
        AND $80                          ; $9FB3  E6 80
        RET NZ                           ; $9FB5  C0
        LD C,$0F                         ; $9FB6  0E 0F
SUB_9FB8:
        CALL SUB_A26B_20+1               ; $9FB8  CD 18 A3
SUB_9FB8_1:
        CALL SUB_A1F5                    ; $9FBB  CD F5 A1
        RET Z                            ; $9FBE  C8
        LD BC,$0010                      ; $9FBF  01 10 00
SUB_9FB8_2:
        CALL SUB_A15E                    ; $9FC2  CD 5E A1
        ADD HL,BC                        ; $9FC5  09
        EX DE,HL                         ; $9FC6  EB
        LD HL,(BDOS_DISPATCH_PTR)        ; $9FC7  2A 43 9F
        ADD HL,BC                        ; $9FCA  09
        LD C,$10                         ; $9FCB  0E 10
        LD A,(L_A9DD)                    ; $9FCD  3A DD A9
        OR A                             ; $9FD0  B7
SUB_9FD1:
        JP Z,SUB_A451_10                 ; $9FD1  CA E8 A4
        LD A,(HL)                        ; $9FD4  7E
        OR A                             ; $9FD5  B7
        LD A,(DE)                        ; $9FD6  1A
        JP NZ,SUB_A451_8                 ; $9FD7  C2 DB A4
        LD (HL),A                        ; $9FDA  77
        OR A                             ; $9FDB  B7
        JP NZ,SUB_A451_9                 ; $9FDC  C2 E1 A4
        LD A,(HL)                        ; $9FDF  7E
        LD (DE),A                        ; $9FE0  12
        CP (HL)                          ; $9FE1  BE
SUB_9FD1_1:
        JP NZ,SUB_A451_14                ; $9FE2  C2 1F A5
        JP SUB_A451_12+2                 ; $9FE5  C3 FD A4
SUB_9FD1_2:
        CALL SUB_A451_3+2                ; $9FE8  CD 94 A4
        EX DE,HL                         ; $9FEB  EB
        CALL SUB_A451_3+2                ; $9FEC  CD 94 A4
        EX DE,HL                         ; $9FEF  EB
        LD A,(DE)                        ; $9FF0  1A
        CP (HL)                          ; $9FF1  BE
        JP NZ,SUB_A451_14                ; $9FF2  C2 1F A5
        INC DE                           ; $9FF5  13
        INC HL                           ; $9FF6  23
        LD A,(DE)                        ; $9FF7  1A
        CP (HL)                          ; $9FF8  BE
SUB_9FD1_3:
        JP NZ,SUB_A451_14                ; $9FF9  C2 1F A5
        DEC C                            ; $9FFC  0D
        INC DE                           ; $9FFD  13
        INC HL                           ; $9FFE  23
        DEC C                            ; $9FFF  0D
        NOP                              ; $A000  00
        OR A                             ; $A001  B7
        RET NZ                           ; $A002  C0
        JP $AA09                         ; $A003  C3 09 AA
SUB_9FD1_4:
        CALL SUB_9CFB                    ; $A006  CD FB 9C
        CALL SUB_9D14                    ; $A009  CD 14 9D
        RET C                            ; $A00C  D8
        PUSH AF                          ; $A00D  F5
        LD C,A                           ; $A00E  4F
SUB_9FD1_5:
        CALL SUB_9D90                    ; $A00F  CD 90 9D
        POP AF                           ; $A012  F1
        RET                              ; $A013  C9
SUB_9FD1_6:
        CP $0D                           ; $A014  FE 0D
        RET Z                            ; $A016  C8
        CP $0A                           ; $A017  FE 0A
        RET Z                            ; $A019  C8
        CP $09                           ; $A01A  FE 09
        RET Z                            ; $A01C  C8
        CP $08                           ; $A01D  FE 08
        RET Z                            ; $A01F  C8
        CP $20                           ; $A020  FE 20
        RET                              ; $A022  C9
SUB_9FD1_7:
        LD A,($9F0E)                     ; $A023  3A 0E 9F
        OR A                             ; $A026  B7
        JP NZ,SUB_9D14_4+2               ; $A027  C2 45 9D
        CALL $AA06                       ; $A02A  CD 06 AA
        AND $01                          ; $A02D  E6 01
        RET Z                            ; $A02F  C8
        CALL $AA09                       ; $A030  CD 09 AA
        CP $13                           ; $A033  FE 13
        JP NZ,SUB_9D14_3                 ; $A035  C2 42 9D
        CALL $AA09                       ; $A038  CD 09 AA
        CP $03                           ; $A03B  FE 03
SUB_9FD1_8:
        JP Z,$0000                       ; $A03D  CA 00 00
        XOR A                            ; $A040  AF
        RET                              ; $A041  C9
SUB_9FD1_9:
        LD ($9F0E),A                     ; $A042  32 0E 9F
SUB_9FD1_10:
        LD A,$01                         ; $A045  3E 01
        RET                              ; $A047  C9
SUB_9FD1_11:
        LD A,($9F0A)                     ; $A048  3A 0A 9F
        OR A                             ; $A04B  B7
        JP NZ,SUB_9D14_6+1               ; $A04C  C2 62 9D
        PUSH BC                          ; $A04F  C5
        CALL SUB_9D14_2+2                ; $A050  CD 23 9D
SUB_9FD1_12:
        POP BC                           ; $A053  C1
        PUSH BC                          ; $A054  C5
        CALL $AA0C                       ; $A055  CD 0C AA
        POP BC                           ; $A058  C1
        PUSH BC                          ; $A059  C5
SUB_9FD1_13:
        LD A,($9F0D)                     ; $A05A  3A 0D 9F
        OR A                             ; $A05D  B7
SUB_A05E:
        CALL NZ,$AA0F                    ; $A05E  C4 0F AA
        POP BC                           ; $A061  C1
        LD A,C                           ; $A062  79
        LD HL,$9F0C                      ; $A063  21 0C 9F
        CP $7F                           ; $A066  FE 7F
        RET Z                            ; $A068  C8
        INC (HL)                         ; $A069  34
        CP $20                           ; $A06A  FE 20
        RET NC                           ; $A06C  D0
        DEC (HL)                         ; $A06D  35
        LD A,(HL)                        ; $A06E  7E
        OR A                             ; $A06F  B7
        RET Z                            ; $A070  C8
SUB_A05E_1:
        LD A,C                           ; $A071  79
        CP $08                           ; $A072  FE 08
        JP NZ,SUB_9D14_8                 ; $A074  C2 79 9D
SUB_A077:
        DEC (HL)                         ; $A077  35
        RET                              ; $A078  C9
SUB_A077_1:
        CP $0A                           ; $A079  FE 0A
        RET NZ                           ; $A07B  C0
        LD (HL),$00                      ; $A07C  36 00
        RET                              ; $A07E  C9
SUB_A077_2:
        LD A,C                           ; $A07F  79
        CALL SUB_9D14                    ; $A080  CD 14 9D
SUB_A077_3:
        JP NC,SUB_9D90                   ; $A083  D2 90 9D
        PUSH AF                          ; $A086  F5
        LD C,$5E                         ; $A087  0E 5E
SUB_A077_4:
        CALL SUB_9D14_5+1                ; $A089  CD 48 9D
        POP AF                           ; $A08C  F1
        OR $40                           ; $A08D  F6 40
        LD C,A                           ; $A08F  4F
SUB_A077_5:
        LD A,C                           ; $A090  79
        CP $09                           ; $A091  FE 09
        JP NZ,SUB_9D14_5+1               ; $A093  C2 48 9D
        LD C,$20                         ; $A096  0E 20
        CALL SUB_9D14_5+1                ; $A098  CD 48 9D
        LD A,($9F0C)                     ; $A09B  3A 0C 9F
        AND $07                          ; $A09E  E6 07
        JP NZ,SUB_9D90_1+2               ; $A0A0  C2 96 9D
        RET                              ; $A0A3  C9
SUB_A077_6:
        CALL SUB_9DA4_1+1                ; $A0A4  CD AC 9D
        LD C,$20                         ; $A0A7  0E 20
        CALL $AA0C                       ; $A0A9  CD 0C AA
        LD C,$08                         ; $A0AC  0E 08
SUB_A0AE:
        JP $AA0C                         ; $A0AE  C3 0C AA
SUB_A0AE_1:
        LD C,$23                         ; $A0B1  0E 23
        CALL SUB_9D14_5+1                ; $A0B3  CD 48 9D
        CALL SUB_9DA4_5+1                ; $A0B6  CD C9 9D
SUB_A0AE_2:
        LD A,($9F0C)                     ; $A0B9  3A 0C 9F
        LD HL,$9F0B                      ; $A0BC  21 0B 9F
        CP (HL)                          ; $A0BF  BE
        RET NC                           ; $A0C0  D0
        LD C,$20                         ; $A0C1  0E 20
        CALL SUB_9D14_5+1                ; $A0C3  CD 48 9D
        JP SUB_9DA4_3+1                  ; $A0C6  C3 B9 9D
SUB_A0AE_3:
        LD C,$0D                         ; $A0C9  0E 0D
        CALL SUB_9D14_5+1                ; $A0CB  CD 48 9D
        LD C,$0A                         ; $A0CE  0E 0A
SUB_A0AE_4:
        JP SUB_9D14_5+1                  ; $A0D0  C3 48 9D
        LD A,(BC)                        ; $A0D3  0A
        CP $24                           ; $A0D4  FE 24
        RET Z                            ; $A0D6  C8
        INC BC                           ; $A0D7  03
        PUSH BC                          ; $A0D8  C5
        LD C,A                           ; $A0D9  4F
        CALL SUB_9D90                    ; $A0DA  CD 90 9D
        POP BC                           ; $A0DD  C1
SUB_A0AE_5:
        JP SUB_9DA4_6+2                  ; $A0DE  C3 D3 9D
SUB_A0AE_6:
        LD A,($9F0C)                     ; $A0E1  3A 0C 9F
        LD ($9F0B),A                     ; $A0E4  32 0B 9F
        LD HL,(BDOS_DISPATCH_PTR)        ; $A0E7  2A 43 9F
SUB_A0EA:
        LD C,(HL)                        ; $A0EA  4E
SUB_A0EA_1:
        INC HL                           ; $A0EB  23
        PUSH HL                          ; $A0EC  E5
        LD B,$00                         ; $A0ED  06 00
        PUSH BC                          ; $A0EF  C5
        PUSH HL                          ; $A0F0  E5
        CALL SUB_9CFB                    ; $A0F1  CD FB 9C
        AND $7F                          ; $A0F4  E6 7F
        POP HL                           ; $A0F6  E1
SUB_A0F7:
        POP BC                           ; $A0F7  C1
        CP $0D                           ; $A0F8  FE 0D
        JP Z,$9EC1                      ; $A0FA  CA C1 9E
        CP $0A                           ; $A0FD  FE 0A
        JP Z,$CDC2                       ; $A0FF  CA C2 CD
        AND H                            ; $A102  A4
SUB_A0F7_1:
        LD BC,$FFEC                      ; $A103  01 EC FF
        ADD HL,BC                        ; $A106  09
        EX DE,HL                         ; $A107  EB
        ADD HL,BC                        ; $A108  09
        LD A,(DE)                        ; $A109  1A
        CP (HL)                          ; $A10A  BE
SUB_A10B:
        JP C,SUB_A451_13                 ; $A10B  DA 17 A5
        LD (HL),A                        ; $A10E  77
        LD BC,$0003                      ; $A10F  01 03 00
        ADD HL,BC                        ; $A112  09
        EX DE,HL                         ; $A113  EB
        ADD HL,BC                        ; $A114  09
        LD A,(HL)                        ; $A115  7E
        LD (DE),A                        ; $A116  12
        LD A,$FF                         ; $A117  3E FF
        LD (L_A9D2),A                    ; $A119  32 D2 A9
SUB_A10B_1:
        JP L_A410                        ; $A11C  C3 10 A4
SUB_A10B_2:
        LD HL,SUB_9DA4_35+1              ; $A11F  21 45 9F
        DEC (HL)                         ; $A122  35
        RET                              ; $A123  C9
SUB_A10B_3:
        CALL SUB_A154                    ; $A124  CD 54 A1
        LD HL,(BDOS_DISPATCH_PTR)        ; $A127  2A 43 9F
        PUSH HL                          ; $A12A  E5
SUB_A10B_4:
        LD HL,L_A9AC                     ; $A12B  21 AC A9
        LD (BDOS_DISPATCH_PTR),HL        ; $A12E  22 43 9F
        LD C,$01                         ; $A131  0E 01
        CALL SUB_A26B_20+1               ; $A133  CD 18 A3
        CALL SUB_A1F5                    ; $A136  CD F5 A1
        POP HL                           ; $A139  E1
        LD (BDOS_DISPATCH_PTR),HL        ; $A13A  22 43 9F
        RET Z                            ; $A13D  C8
        EX DE,HL                         ; $A13E  EB
        LD HL,$000F                      ; $A13F  21 0F 00
        ADD HL,DE                        ; $A142  19
SUB_A10B_5:
        LD C,$11                         ; $A143  0E 11
        XOR A                            ; $A145  AF
        LD (HL),A                        ; $A146  77
SUB_A147:
        INC HL                           ; $A147  23
        DEC C                            ; $A148  0D
        JP NZ,SUB_A524_1+2               ; $A149  C2 46 A5
        LD HL,$000D                      ; $A14C  21 0D 00
        ADD HL,DE                        ; $A14F  19
        LD (HL),A                        ; $A150  77
        CALL SUB_A178_3+1                ; $A151  CD 8C A1
SUB_A154:
        CALL SUB_A3BE_5+2                ; $A154  CD FD A3
        JP SUB_A178                      ; $A157  C3 78 A1
SUB_A154_1:
        XOR A                            ; $A15A  AF
        LD (L_A9D2),A                    ; $A15B  32 D2 A9
SUB_A15E:
        CALL SUB_A451_4+1                ; $A15E  CD A2 A4
        CALL SUB_A1F5                    ; $A161  CD F5 A1
SUB_A164:
        RET Z                            ; $A164  C8
        LD HL,(BDOS_DISPATCH_PTR)        ; $A165  2A 43 9F
SUB_A164_1:
        LD BC,$000C                      ; $A168  01 0C 00
        ADD HL,BC                        ; $A16B  09
        LD A,(HL)                        ; $A16C  7E
        INC A                            ; $A16D  3C
        AND $1F                          ; $A16E  E6 1F
        LD (HL),A                        ; $A170  77
SUB_A164_2:
        JP Z,SUB_A55A_1+2                ; $A171  CA 83 A5
        LD B,A                           ; $A174  47
        LD A,(L_A9C5)                    ; $A175  3A C5 A9
SUB_A178:
        AND B                            ; $A178  A0
        LD HL,L_A9D2                     ; $A179  21 D2 A9
        AND (HL)                         ; $A17C  A6
SUB_A178_1:
        JP Z,SUB_A55A_2+1                ; $A17D  CA 8E A5
        JP SUB_A55A_6+2                  ; $A180  C3 AC A5
SUB_A178_2:
        LD BC,$0002                      ; $A183  01 02 00
        ADD HL,BC                        ; $A186  09
        INC (HL)                         ; $A187  34
        LD A,(HL)                        ; $A188  7E
        AND $0F                          ; $A189  E6 0F
SUB_A178_3:
        JP Z,SUB_A55A_8                  ; $A18B  CA B6 A5
        LD C,$0F                         ; $A18E  0E 0F
        CALL SUB_A26B_20+1               ; $A190  CD 18 A3
SUB_A178_4:
        CALL SUB_A1F5                    ; $A193  CD F5 A1
        JP NZ,SUB_A55A_6+2               ; $A196  C2 AC A5
        LD A,(L_A9D3)                    ; $A199  3A D3 A9
SUB_A19C:
        INC A                            ; $A19C  3C
SUB_A19C_1:
        JP Z,SUB_A55A_8                  ; $A19D  CA B6 A5
        CALL SUB_A524                    ; $A1A0  CD 24 A5
        CALL SUB_A1F5                    ; $A1A3  CD F5 A1
        JP Z,SUB_A55A_8                  ; $A1A6  CA B6 A5
        JP SUB_A55A_7                    ; $A1A9  C3 AF A5
SUB_A19C_2:
        CALL SUB_A451_1+1                ; $A1AC  CD 5A A4
        CALL SUB_A0AE_2+2                ; $A1AF  CD BB A0
        XOR A                            ; $A1B2  AF
        JP SUB_9DA4_31                   ; $A1B3  C3 01 9F
SUB_A19C_3:
        CALL SUB_9DA4_32+1               ; $A1B6  CD 05 9F
        JP SUB_A178                      ; $A1B9  C3 78 A1
SUB_A19C_4:
        LD A,$01                         ; $A1BC  3E 01
        LD (L_A9D5),A                    ; $A1BE  32 D5 A9
        LD A,$FF                         ; $A1C1  3E FF
SUB_A19C_5:
        LD (L_A9D3),A                    ; $A1C3  32 D3 A9
SUB_A1C6:
        CALL SUB_A0AE_2+2                ; $A1C6  CD BB A0
        LD A,(L_A9E3)                    ; $A1C9  3A E3 A9
        LD HL,L_A9E1                     ; $A1CC  21 E1 A9
        CP (HL)                          ; $A1CF  BE
        JP C,SUB_A5C1_2+2                ; $A1D0  DA E6 A5
SUB_A1C6_1:
        CP $80                           ; $A1D3  FE 80
        JP NZ,SUB_A5C1_3                 ; $A1D5  C2 FB A5
SUB_A1C6_2:
        CALL SUB_A55A                    ; $A1D8  CD 5A A5
        XOR A                            ; $A1DB  AF
        LD (L_A9E3),A                    ; $A1DC  32 E3 A9
SUB_A1C6_3:
        LD A,(SUB_9DA4_35+1)             ; $A1DF  3A 45 9F
        OR A                             ; $A1E2  B7
SUB_A1C6_4:
        JP NZ,SUB_A5C1_3                 ; $A1E3  C2 FB A5
        CALL SUB_A077                    ; $A1E6  CD 77 A0
SUB_A1C6_5:
        CALL SUB_A077_3+1                ; $A1E9  CD 84 A0
        JP Z,SUB_A5C1_3                  ; $A1EC  CA FB A5
        CALL SUB_A077_4+1                ; $A1EF  CD 8A A0
        CALL SUB_9FD1                    ; $A1F2  CD D1 9F
SUB_A1F5:
        CALL SUB_9FA1_2+2                ; $A1F5  CD B2 9F
        JP SUB_A0AE_4+2                  ; $A1F8  C3 D2 A0
SUB_A1F5_1:
        JP SUB_9DA4_32+1                 ; $A1FB  C3 05 9F
SUB_A1FE:
        LD A,$01                         ; $A1FE  3E 01
        POP BC                           ; $A200  C1
        SBC A,(HL)                       ; $A201  9E
        CP $08                           ; $A202  FE 08
SUB_A1FE_1:
        JP NZ,SUB_9DA4_13                ; $A204  C2 16 9E
        LD A,B                           ; $A207  78
        OR A                             ; $A208  B7
        JP Z,SUB_9DA4_9+1                ; $A209  CA EF 9D
        DEC B                            ; $A20C  05
        LD A,($9F0C)                     ; $A20D  3A 0C 9F
        LD ($9F0A),A                     ; $A210  32 0A 9F
        JP SUB_9DA4_22                   ; $A213  C3 70 9E
SUB_A1FE_2:
        CP $7F                           ; $A216  FE 7F
SUB_A1FE_3:
        JP NZ,SUB_9DA4_15+2              ; $A218  C2 26 9E
        LD A,B                           ; $A21B  78
        OR A                             ; $A21C  B7
        JP Z,SUB_9DA4_9+1                ; $A21D  CA EF 9D
SUB_A1FE_4:
        LD A,(HL)                        ; $A220  7E
        DEC B                            ; $A221  05
        DEC HL                           ; $A222  2B
        JP SUB_9DA4_27+1                 ; $A223  C3 A9 9E
SUB_A1FE_5:
        CP $05                           ; $A226  FE 05
        JP NZ,SUB_9DA4_16                ; $A228  C2 37 9E
        PUSH BC                          ; $A22B  C5
        PUSH HL                          ; $A22C  E5
        CALL SUB_9DA4_5+1                ; $A22D  CD C9 9D
        XOR A                            ; $A230  AF
        LD ($9F0B),A                     ; $A231  32 0B 9F
SUB_A1FE_6:
        JP SUB_9DA4_10                   ; $A234  C3 F1 9D
        CP $10                           ; $A237  FE 10
        JP NZ,SUB_9DA4_18                ; $A239  C2 48 9E
        PUSH HL                          ; $A23C  E5
        LD HL,$9F0D                      ; $A23D  21 0D 9F
        LD A,$01                         ; $A240  3E 01
        SUB (HL)                         ; $A242  96
        LD (HL),A                        ; $A243  77
        POP HL                           ; $A244  E1
        JP SUB_9DA4_9+1                  ; $A245  C3 EF 9D
SUB_A1FE_7:
        CP $18                           ; $A248  FE 18
        JP NZ,SUB_9DA4_20                ; $A24A  C2 5F 9E
        POP HL                           ; $A24D  E1
        LD A,($9F0B)                     ; $A24E  3A 0B 9F
        LD HL,$9F0C                      ; $A251  21 0C 9F
        CP (HL)                          ; $A254  BE
SUB_A1FE_8:
        JP NC,SUB_9DA4_7+1               ; $A255  D2 E1 9D
        DEC (HL)                         ; $A258  35
        CALL SUB_9DA4                    ; $A259  CD A4 9D
SUB_A25C:
        JP SUB_9DA4_19+1                 ; $A25C  C3 4E 9E
SUB_A25C_1:
        CP $15                           ; $A25F  FE 15
        JP NZ,SUB_9DA4_21                ; $A261  C2 6B 9E
SUB_A264:
        CALL SUB_9DA4_2+1                ; $A264  CD B1 9D
        POP HL                           ; $A267  E1
        JP SUB_9DA4_7+1                  ; $A268  C3 E1 9D
SUB_A26B:
        CP $12                           ; $A26B  FE 12
        JP NZ,SUB_9DA4_26+1              ; $A26D  C2 A6 9E
        PUSH BC                          ; $A270  C5
        CALL SUB_9DA4_2+1                ; $A271  CD B1 9D
        POP BC                           ; $A274  C1
SUB_A26B_1:
        POP HL                           ; $A275  E1
        PUSH HL                          ; $A276  E5
        PUSH BC                          ; $A277  C5
        LD A,B                           ; $A278  78
        OR A                             ; $A279  B7
        JP Z,SUB_9DA4_24                 ; $A27A  CA 8A 9E
        INC HL                           ; $A27D  23
        LD C,(HL)                        ; $A27E  4E
        DEC B                            ; $A27F  05
        PUSH BC                          ; $A280  C5
        PUSH HL                          ; $A281  E5
        CALL SUB_9D7F                    ; $A282  CD 7F 9D
        POP HL                           ; $A285  E1
        POP BC                           ; $A286  C1
SUB_A26B_2:
        JP SUB_9DA4_23+1                 ; $A287  C3 78 9E
SUB_A26B_3:
        PUSH HL                          ; $A28A  E5
        LD A,($9F0A)                     ; $A28B  3A 0A 9F
SUB_A26B_4:
        OR A                             ; $A28E  B7
        JP Z,SUB_9DA4_10                 ; $A28F  CA F1 9D
        LD HL,$9F0C                      ; $A292  21 0C 9F
        SUB (HL)                         ; $A295  96
        LD ($9F0A),A                     ; $A296  32 0A 9F
        CALL SUB_9DA4                    ; $A299  CD A4 9D
SUB_A26B_5:
        LD HL,$9F0A                      ; $A29C  21 0A 9F
        DEC (HL)                         ; $A29F  35
        JP NZ,SUB_9DA4_25                ; $A2A0  C2 99 9E
SUB_A26B_6:
        JP SUB_9DA4_10                   ; $A2A3  C3 F1 9D
SUB_A26B_7:
        INC HL                           ; $A2A6  23
        LD (HL),A                        ; $A2A7  77
        INC B                            ; $A2A8  04
        PUSH BC                          ; $A2A9  C5
        PUSH HL                          ; $A2AA  E5
        LD C,A                           ; $A2AB  4F
        CALL SUB_9D7F                    ; $A2AC  CD 7F 9D
        POP HL                           ; $A2AF  E1
        POP BC                           ; $A2B0  C1
SUB_A26B_8:
        LD A,(HL)                        ; $A2B1  7E
        CP $03                           ; $A2B2  FE 03
        LD A,B                           ; $A2B4  78
        JP NZ,$9EBD                     ; $A2B5  C2 BD 9E
        CP $01                           ; $A2B8  FE 01
        JP Z,$0000                       ; $A2BA  CA 00 00
        CP C                             ; $A2BD  B9
        JP C,SUB_9DA4_9+1                ; $A2BE  DA EF 9D
        POP HL                           ; $A2C1  E1
        LD (HL),B                        ; $A2C2  70
        LD C,$0D                         ; $A2C3  0E 0D
        JP SUB_9D14_5+1                  ; $A2C5  C3 48 9D
SUB_A26B_9:
        CALL SUB_9D06                    ; $A2C8  CD 06 9D
        JP SUB_9DA4_31                   ; $A2CB  C3 01 9F
SUB_A26B_10:
        CALL $AA15                       ; $A2CE  CD 15 AA
SUB_A26B_11:
        JP SUB_9DA4_31                   ; $A2D1  C3 01 9F
        LD A,C                           ; $A2D4  79
        INC A                            ; $A2D5  3C
        JP Z,$9EE0                      ; $A2D6  CA E0 9E
        INC A                            ; $A2D9  3C
        JP Z,$AA06                       ; $A2DA  CA 06 AA
        JP $AA0C                         ; $A2DD  C3 0C AA
SUB_A26B_12:
        CALL $AA06                       ; $A2E0  CD 06 AA
        OR A                             ; $A2E3  B7
        JP Z,L_A991                      ; $A2E4  CA 91 A9
        CALL $AA09                       ; $A2E7  CD 09 AA
        JP SUB_9DA4_31                   ; $A2EA  C3 01 9F
SUB_A26B_13:
        LD A,($0003)                     ; $A2ED  3A 03 00
        JP SUB_9DA4_31                   ; $A2F0  C3 01 9F
SUB_A26B_14:
        LD HL,$0003                      ; $A2F3  21 03 00
SUB_A26B_15:
        LD (HL),C                        ; $A2F6  71
        RET                              ; $A2F7  C9
SUB_A26B_16:
        EX DE,HL                         ; $A2F8  EB
        LD C,L                           ; $A2F9  4D
        LD B,H                           ; $A2FA  44
        JP SUB_9DA4_6+2                  ; $A2FB  C3 D3 9D
SUB_A26B_17:
        CALL $3223                       ; $A2FE  CD 23 32
SUB_A26B_18:
        PUSH DE                          ; $A301  D5
        XOR C                            ; $A302  A9
        LD A,$00                         ; $A303  3E 00
SUB_A26B_19:
        LD (L_A9D3),A                    ; $A305  32 D3 A9
        CALL SUB_A154                    ; $A308  CD 54 A1
        LD HL,(BDOS_DISPATCH_PTR)        ; $A30B  2A 43 9F
        CALL SUB_A147                    ; $A30E  CD 47 A1
        CALL SUB_A0AE_2+2                ; $A311  CD BB A0
        LD A,(L_A9E3)                    ; $A314  3A E3 A9
SUB_A26B_20:
        CP $80                           ; $A317  FE 80
        JP NC,SUB_9DA4_32+1              ; $A319  D2 05 9F
        CALL SUB_A077                    ; $A31C  CD 77 A0
        CALL SUB_A077_3+1                ; $A31F  CD 84 A0
        LD C,$00                         ; $A322  0E 00
        JP NZ,SUB_A603_9                 ; $A324  C2 6E A6
        CALL SUB_9FD1_8+1                ; $A327  CD 3E A0
        LD (L_A9D7),A                    ; $A32A  32 D7 A9
SUB_A32D:
        LD BC,$0000                      ; $A32D  01 00 00
        OR A                             ; $A330  B7
        JP Z,SUB_A603_2                  ; $A331  CA 3B A6
        LD C,A                           ; $A334  4F
        DEC BC                           ; $A335  0B
        CALL SUB_A05E                    ; $A336  CD 5E A0
        LD B,H                           ; $A339  44
        LD C,L                           ; $A33A  4D
        CALL SUB_A3BE                    ; $A33B  CD BE A3
        LD A,L                           ; $A33E  7D
        OR H                             ; $A33F  B4
        JP NZ,SUB_A603_4                 ; $A340  C2 48 A6
        LD A,$02                         ; $A343  3E 02
        JP SUB_9DA4_31                   ; $A345  C3 01 9F
SUB_A32D_1:
        LD (L_A9E5),HL                   ; $A348  22 E5 A9
        EX DE,HL                         ; $A34B  EB
        LD HL,(BDOS_DISPATCH_PTR)        ; $A34C  2A 43 9F
        LD BC,$0010                      ; $A34F  01 10 00
        ADD HL,BC                        ; $A352  09
SUB_A32D_2:
        LD A,(L_A9DD)                    ; $A353  3A DD A9
        OR A                             ; $A356  B7
        LD A,(L_A9D7)                    ; $A357  3A D7 A9
        JP Z,SUB_A603_7                  ; $A35A  CA 64 A6
        CALL SUB_A164                    ; $A35D  CD 64 A1
        LD (HL),E                        ; $A360  73
        JP SUB_A603_8+2                  ; $A361  C3 6C A6
SUB_A32D_3:
        LD C,A                           ; $A364  4F
        LD B,$00                         ; $A365  06 00
        ADD HL,BC                        ; $A367  09
        ADD HL,BC                        ; $A368  09
        LD (HL),E                        ; $A369  73
        INC HL                           ; $A36A  23
        LD (HL),D                        ; $A36B  72
        LD C,$02                         ; $A36C  0E 02
        LD A,(SUB_9DA4_35+1)             ; $A36E  3A 45 9F
        OR A                             ; $A371  B7
        RET NZ                           ; $A372  C0
SUB_A32D_4:
        PUSH BC                          ; $A373  C5
        CALL SUB_A077_4+1                ; $A374  CD 8A A0
        LD A,(L_A9D5)                    ; $A377  3A D5 A9
        DEC A                            ; $A37A  3D
        DEC A                            ; $A37B  3D
SUB_A32D_5:
        JP NZ,SUB_A603_17                ; $A37C  C2 BB A6
        POP BC                           ; $A37F  C1
        PUSH BC                          ; $A380  C5
        LD A,C                           ; $A381  79
        DEC A                            ; $A382  3D
SUB_A32D_6:
        DEC A                            ; $A383  3D
        JP NZ,SUB_A603_17                ; $A384  C2 BB A6
        PUSH HL                          ; $A387  E5
        LD HL,(L_A9B9)                   ; $A388  2A B9 A9
        LD D,A                           ; $A38B  57
        LD (HL),A                        ; $A38C  77
        INC HL                           ; $A38D  23
        INC D                            ; $A38E  14
        JP P,SUB_A603_13+2               ; $A38F  F2 8C A6
SUB_A32D_7:
        CALL SUB_A1C6_3+1                ; $A392  CD E0 A1
        LD HL,(L_A9E7)                   ; $A395  2A E7 A9
        LD C,$02                         ; $A398  0E 02
SUB_A32D_8:
        LD (L_A9E5),HL                   ; $A39A  22 E5 A9
        PUSH BC                          ; $A39D  C5
        CALL SUB_9FD1                    ; $A39E  CD D1 9F
        POP BC                           ; $A3A1  C1
SUB_A32D_9:
        CALL SUB_9FB8                    ; $A3A2  CD B8 9F
        LD HL,(L_A9E5)                   ; $A3A5  2A E5 A9
        LD C,$00                         ; $A3A8  0E 00
        LD A,(L_A9C4)                    ; $A3AA  3A C4 A9
        LD B,A                           ; $A3AD  47
        AND L                            ; $A3AE  A5
        CP B                             ; $A3AF  B8
        INC HL                           ; $A3B0  23
        JP NZ,SUB_A603_14+2              ; $A3B1  C2 9A A6
        POP HL                           ; $A3B4  E1
        LD (L_A9E5),HL                   ; $A3B5  22 E5 A9
        CALL SUB_A1C6_2+2                ; $A3B8  CD DA A1
        CALL SUB_9FD1                    ; $A3BB  CD D1 9F
SUB_A3BE:
        POP BC                           ; $A3BE  C1
        PUSH BC                          ; $A3BF  C5
SUB_A3BE_1:
        CALL SUB_9FB8                    ; $A3C0  CD B8 9F
        POP BC                           ; $A3C3  C1
        LD A,(L_A9E3)                    ; $A3C4  3A E3 A9
        LD HL,L_A9E1                     ; $A3C7  21 E1 A9
        CP (HL)                          ; $A3CA  BE
        JP C,SUB_A603_18                 ; $A3CB  DA D2 A6
        LD (HL),A                        ; $A3CE  77
        INC (HL)                         ; $A3CF  34
SUB_A3BE_2:
        LD C,$02                         ; $A3D0  0E 02
        NOP                              ; $A3D2  00
        NOP                              ; $A3D3  00
        LD HL,L_9400                     ; $A3D4  21 00 94
        PUSH AF                          ; $A3D7  F5
        CALL SUB_A164_1+1                ; $A3D8  CD 69 A1
        AND $7F                          ; $A3DB  E6 7F
        LD (HL),A                        ; $A3DD  77
        POP AF                           ; $A3DE  F1
        CP $7F                           ; $A3DF  FE 7F
        JP NZ,SUB_A603_22                ; $A3E1  C2 00 A7
        LD A,(L_A9D5)                    ; $A3E4  3A D5 A9
        CP $01                           ; $A3E7  FE 01
        JP NZ,SUB_A603_22                ; $A3E9  C2 00 A7
SUB_A3BE_3:
        CALL SUB_A0AE_4+2                ; $A3EC  CD D2 A0
        CALL SUB_A55A                    ; $A3EF  CD 5A A5
SUB_A3BE_4:
        LD HL,SUB_9DA4_35+1              ; $A3F2  21 45 9F
        LD A,(HL)                        ; $A3F5  7E
        OR A                             ; $A3F6  B7
        JP NZ,SUB_A603_21                ; $A3F7  C2 FE A6
        DEC A                            ; $A3FA  3D
SUB_A3BE_5:
        LD (L_A9E3),A                    ; $A3FB  32 E3 A9
        LD (HL),$00                      ; $A3FE  36 00
        SBC A,L                          ; $A400  9D
SUB_A401:
        LD (SUB_9DA4_35+1),A             ; $A401  32 45 9F
        RET                              ; $A404  C9
SUB_A401_1:
        LD A,$01                         ; $A405  3E 01
        JP SUB_9DA4_31                   ; $A407  C3 01 9F
        DEFB    $00,$00,$00,$00,$00,$00                          ; $A40A
L_A410:
        DEFB    $00,$00,$00,$00,$00,$00                          ; $A410
SUB_A416:
        DEFS    17, $00    ; $A416  fill
L_A427:
        DEFS    20, $00    ; $A427  fill
SUB_A43B:
        DEFB    $00,$00,$00,$00,$00                              ; $A43B
L_A440:
        DEFB    $00,$00,$00,$00,$00,$00,$00                      ; $A440
SUB_A43B_1:
        LD HL,SUB_9866_71+2              ; $A447  21 0B 9C
        LD E,(HL)                        ; $A44A  5E
        INC HL                           ; $A44B  23
        LD D,(HL)                        ; $A44C  56
        EX DE,HL                         ; $A44D  EB
SUB_A43B_2:
        JP (HL)                          ; $A44E  E9
SUB_A43B_3:
        INC C                            ; $A44F  0C
        DEC C                            ; $A450  0D
SUB_A451:
        RET Z                            ; $A451  C8
        LD A,(DE)                        ; $A452  1A
        LD (HL),A                        ; $A453  77
        INC DE                           ; $A454  13
        INC HL                           ; $A455  23
        JP SUB_9DA4_38+2                 ; $A456  C3 50 9F
SUB_A451_1:
        LD A,($9F42)                     ; $A459  3A 42 9F
        LD C,A                           ; $A45C  4F
        CALL $AA1B                       ; $A45D  CD 1B AA
        LD A,H                           ; $A460  7C
        OR L                             ; $A461  B5
        RET Z                            ; $A462  C8
        LD E,(HL)                        ; $A463  5E
        INC HL                           ; $A464  23
        LD D,(HL)                        ; $A465  56
        INC HL                           ; $A466  23
        LD (L_A9B3),HL                   ; $A467  22 B3 A9
        INC HL                           ; $A46A  23
        INC HL                           ; $A46B  23
        LD (L_A9B5),HL                   ; $A46C  22 B5 A9
        INC HL                           ; $A46F  23
        INC HL                           ; $A470  23
        LD (L_A9B7),HL                   ; $A471  22 B7 A9
        INC HL                           ; $A474  23
        INC HL                           ; $A475  23
        EX DE,HL                         ; $A476  EB
        LD (L_A9D0),HL                   ; $A477  22 D0 A9
        LD HL,L_A9B9                     ; $A47A  21 B9 A9
        LD C,$08                         ; $A47D  0E 08
        CALL SUB_9DA4_38+1               ; $A47F  CD 4F 9F
        LD HL,(L_A9BB)                   ; $A482  2A BB A9
        EX DE,HL                         ; $A485  EB
        LD HL,L_A9C1                     ; $A486  21 C1 A9
        LD C,$0F                         ; $A489  0E 0F
SUB_A451_2:
        CALL SUB_9DA4_38+1               ; $A48B  CD 4F 9F
        LD HL,(L_A9C6)                   ; $A48E  2A C6 A9
        LD A,H                           ; $A491  7C
SUB_A451_3:
        LD HL,L_A9DD                     ; $A492  21 DD A9
        LD (HL),$FF                      ; $A495  36 FF
        OR A                             ; $A497  B7
        JP Z,SUB_9F59_2                  ; $A498  CA 9D 9F
        LD (HL),$00                      ; $A49B  36 00
        LD A,$FF                         ; $A49D  3E FF
        OR A                             ; $A49F  B7
        RET                              ; $A4A0  C9
SUB_A451_4:
        CALL $AA18                       ; $A4A1  CD 18 AA
        XOR A                            ; $A4A4  AF
        LD HL,(L_A9B5)                   ; $A4A5  2A B5 A9
        LD (HL),A                        ; $A4A8  77
        INC HL                           ; $A4A9  23
        LD (HL),A                        ; $A4AA  77
        LD HL,(L_A9B7)                   ; $A4AB  2A B7 A9
        LD (HL),A                        ; $A4AE  77
        INC HL                           ; $A4AF  23
        LD (HL),A                        ; $A4B0  77
        RET                              ; $A4B1  C9
SUB_A451_5:
        CALL $AA27                       ; $A4B2  CD 27 AA
        JP SUB_9FB8_1                    ; $A4B5  C3 BB 9F
SUB_A451_6:
        CALL $AA2A                       ; $A4B8  CD 2A AA
        OR A                             ; $A4BB  B7
        RET Z                            ; $A4BC  C8
        LD HL,SUB_9866_71                ; $A4BD  21 09 9C
        JP SUB_9DA4_37+2                 ; $A4C0  C3 4A 9F
SUB_A451_7:
        LD HL,(L_A9EA)                   ; $A4C3  2A EA A9
        LD C,$02                         ; $A4C6  0E 02
        CALL SUB_A0EA                    ; $A4C8  CD EA A0
        LD (L_A9E5),HL                   ; $A4CB  22 E5 A9
        LD (L_A9EC),HL                   ; $A4CE  22 EC A9
        LD HL,L_A9E5                     ; $A4D1  21 E5 A9
        LD C,(HL)                        ; $A4D4  4E
        INC HL                           ; $A4D5  23
        LD B,(HL)                        ; $A4D6  46
        LD HL,(L_A9B7)                   ; $A4D7  2A B7 A9
        LD E,(HL)                        ; $A4DA  5E
SUB_A451_8:
        INC HL                           ; $A4DB  23
        LD D,(HL)                        ; $A4DC  56
        LD HL,(L_A9B5)                   ; $A4DD  2A B5 A9
        LD A,(HL)                        ; $A4E0  7E
SUB_A451_9:
        INC HL                           ; $A4E1  23
        LD H,(HL)                        ; $A4E2  66
        LD L,A                           ; $A4E3  6F
        LD A,C                           ; $A4E4  79
        SUB E                            ; $A4E5  93
        LD A,B                           ; $A4E6  78
        SBC A,D                          ; $A4E7  9A
SUB_A451_10:
        JP NC,SUB_9FD1_3+1               ; $A4E8  D2 FA 9F
        PUSH HL                          ; $A4EB  E5
        LD HL,(L_A9C1)                   ; $A4EC  2A C1 A9
        LD A,E                           ; $A4EF  7B
        SUB L                            ; $A4F0  95
        LD E,A                           ; $A4F1  5F
        LD A,D                           ; $A4F2  7A
        SBC A,H                          ; $A4F3  9C
        LD D,A                           ; $A4F4  57
        POP HL                           ; $A4F5  E1
        DEC HL                           ; $A4F6  2B
        JP SUB_9FD1_1+2                  ; $A4F7  C3 E4 9F
SUB_A451_11:
        PUSH HL                          ; $A4FA  E5
SUB_A451_12:
        LD HL,(L_A9C1)                   ; $A4FB  2A C1 A9
        ADD HL,DE                        ; $A4FE  19
        JP C,$D2C3                       ; $A4FF  DA C3 D2
        AND B                            ; $A502  A0
        XOR A                            ; $A503  AF
        LD (L_A9D5),A                    ; $A504  32 D5 A9
        PUSH BC                          ; $A507  C5
        LD HL,(BDOS_DISPATCH_PTR)        ; $A508  2A 43 9F
        EX DE,HL                         ; $A50B  EB
        LD HL,$0021                      ; $A50C  21 21 00
        ADD HL,DE                        ; $A50F  19
        LD A,(HL)                        ; $A510  7E
        AND $7F                          ; $A511  E6 7F
        PUSH AF                          ; $A513  F5
        LD A,(HL)                        ; $A514  7E
        RLA                              ; $A515  17
        INC HL                           ; $A516  23
SUB_A451_13:
        LD A,(HL)                        ; $A517  7E
        RLA                              ; $A518  17
        AND $1F                          ; $A519  E6 1F
        LD C,A                           ; $A51B  4F
        LD A,(HL)                        ; $A51C  7E
        RRA                              ; $A51D  1F
        RRA                              ; $A51E  1F
SUB_A451_14:
        RRA                              ; $A51F  1F
        RRA                              ; $A520  1F
        AND $0F                          ; $A521  E6 0F
        LD B,A                           ; $A523  47
SUB_A524:
        POP AF                           ; $A524  F1
        INC HL                           ; $A525  23
        LD L,(HL)                        ; $A526  6E
        INC L                            ; $A527  2C
        DEC L                            ; $A528  2D
        LD L,$06                         ; $A529  2E 06
        JP NZ,SUB_A703_10+2              ; $A52B  C2 8B A7
        LD HL,$0020                      ; $A52E  21 20 00
        ADD HL,DE                        ; $A531  19
        LD (HL),A                        ; $A532  77
        LD HL,$000C                      ; $A533  21 0C 00
        ADD HL,DE                        ; $A536  19
        LD A,C                           ; $A537  79
        SUB (HL)                         ; $A538  96
        JP NZ,SUB_A703_6+2               ; $A539  C2 47 A7
        LD HL,$000E                      ; $A53C  21 0E 00
        ADD HL,DE                        ; $A53F  19
        LD A,B                           ; $A540  78
        SUB (HL)                         ; $A541  96
        AND $7F                          ; $A542  E6 7F
SUB_A524_1:
        JP Z,SUB_A703_8+1                ; $A544  CA 7F A7
        PUSH BC                          ; $A547  C5
        PUSH DE                          ; $A548  D5
        CALL SUB_A451_4+1                ; $A549  CD A2 A4
        POP DE                           ; $A54C  D1
        POP BC                           ; $A54D  C1
        LD L,$03                         ; $A54E  2E 03
        LD A,(SUB_9DA4_35+1)             ; $A550  3A 45 9F
        INC A                            ; $A553  3C
        JP Z,SUB_A703_9+1                ; $A554  CA 84 A7
        LD HL,$000C                      ; $A557  21 0C 00
SUB_A55A:
        ADD HL,DE                        ; $A55A  19
        LD (HL),C                        ; $A55B  71
        LD HL,$000E                      ; $A55C  21 0E 00
        ADD HL,DE                        ; $A55F  19
        LD (HL),B                        ; $A560  70
        CALL SUB_A451                    ; $A561  CD 51 A4
        LD A,(SUB_9DA4_35+1)             ; $A564  3A 45 9F
        INC A                            ; $A567  3C
        JP NZ,SUB_A703_8+1               ; $A568  C2 7F A7
        POP BC                           ; $A56B  C1
        PUSH BC                          ; $A56C  C5
        LD L,$04                         ; $A56D  2E 04
        INC C                            ; $A56F  0C
        JP Z,SUB_A703_9+1                ; $A570  CA 84 A7
        CALL SUB_A524                    ; $A573  CD 24 A5
        LD L,$05                         ; $A576  2E 05
        LD A,(SUB_9DA4_35+1)             ; $A578  3A 45 9F
        INC A                            ; $A57B  3C
        JP Z,SUB_A703_9+1                ; $A57C  CA 84 A7
        POP BC                           ; $A57F  C1
        XOR A                            ; $A580  AF
SUB_A55A_1:
        JP SUB_9DA4_31                   ; $A581  C3 01 9F
        PUSH HL                          ; $A584  E5
        CALL SUB_A164_1+1                ; $A585  CD 69 A1
        LD (HL),$C0                      ; $A588  36 C0
        POP HL                           ; $A58A  E1
        POP BC                           ; $A58B  C1
        LD A,L                           ; $A58C  7D
SUB_A55A_2:
        LD (SUB_9DA4_35+1),A             ; $A58D  32 45 9F
        JP SUB_A178                      ; $A590  C3 78 A1
SUB_A55A_3:
        LD C,$FF                         ; $A593  0E FF
        CALL SUB_A703                    ; $A595  CD 03 A7
        CALL Z,SUB_A5C1                  ; $A598  CC C1 A5
        RET                              ; $A59B  C9
SUB_A55A_4:
        LD C,$00                         ; $A59C  0E 00
        CALL SUB_A703                    ; $A59E  CD 03 A7
        CALL Z,SUB_A603                  ; $A5A1  CC 03 A6
        RET                              ; $A5A4  C9
SUB_A55A_5:
        EX DE,HL                         ; $A5A5  EB
        ADD HL,DE                        ; $A5A6  19
        LD C,(HL)                        ; $A5A7  4E
        LD B,$00                         ; $A5A8  06 00
SUB_A55A_6:
        LD HL,$000C                      ; $A5AA  21 0C 00
        ADD HL,DE                        ; $A5AD  19
        LD A,(HL)                        ; $A5AE  7E
SUB_A55A_7:
        RRCA                             ; $A5AF  0F
        AND $80                          ; $A5B0  E6 80
        ADD A,C                          ; $A5B2  81
        LD C,A                           ; $A5B3  4F
        LD A,$00                         ; $A5B4  3E 00
SUB_A55A_8:
        ADC A,B                          ; $A5B6  88
        LD B,A                           ; $A5B7  47
        LD A,(HL)                        ; $A5B8  7E
        RRCA                             ; $A5B9  0F
        AND $0F                          ; $A5BA  E6 0F
SUB_A55A_9:
        ADD A,B                          ; $A5BC  80
        LD B,A                           ; $A5BD  47
        LD HL,$000E                      ; $A5BE  21 0E 00
SUB_A5C1:
        ADD HL,DE                        ; $A5C1  19
        LD A,(HL)                        ; $A5C2  7E
        ADD A,A                          ; $A5C3  87
        ADD A,A                          ; $A5C4  87
        ADD A,A                          ; $A5C5  87
        ADD A,A                          ; $A5C6  87
        PUSH AF                          ; $A5C7  F5
        ADD A,B                          ; $A5C8  80
        LD B,A                           ; $A5C9  47
        PUSH AF                          ; $A5CA  F5
        POP HL                           ; $A5CB  E1
        LD A,L                           ; $A5CC  7D
        POP HL                           ; $A5CD  E1
        OR L                             ; $A5CE  B5
        AND $01                          ; $A5CF  E6 01
        RET                              ; $A5D1  C9
SUB_A5C1_1:
        LD C,$0C                         ; $A5D2  0E 0C
        CALL SUB_A26B_20+1               ; $A5D4  CD 18 A3
        LD HL,(BDOS_DISPATCH_PTR)        ; $A5D7  2A 43 9F
        LD DE,$0021                      ; $A5DA  11 21 00
        ADD HL,DE                        ; $A5DD  19
        PUSH HL                          ; $A5DE  E5
        LD (HL),D                        ; $A5DF  72
        INC HL                           ; $A5E0  23
        LD (HL),D                        ; $A5E1  72
        INC HL                           ; $A5E2  23
        LD (HL),D                        ; $A5E3  72
SUB_A5C1_2:
        CALL SUB_A1F5                    ; $A5E4  CD F5 A1
        JP Z,SUB_A7A5_12+1               ; $A5E7  CA 0C A8
        CALL SUB_A15E                    ; $A5EA  CD 5E A1
        LD DE,$000F                      ; $A5ED  11 0F 00
        CALL SUB_A7A5                    ; $A5F0  CD A5 A7
        POP HL                           ; $A5F3  E1
        PUSH HL                          ; $A5F4  E5
        LD E,A                           ; $A5F5  5F
        LD A,C                           ; $A5F6  79
        SUB (HL)                         ; $A5F7  96
        INC HL                           ; $A5F8  23
        LD A,B                           ; $A5F9  78
        SBC A,(HL)                       ; $A5FA  9E
SUB_A5C1_3:
        INC HL                           ; $A5FB  23
        LD A,E                           ; $A5FC  7B
        SBC A,(HL)                       ; $A5FD  9E
SUB_A5C1_4:
        JP C,$0F06                       ; $A5FE  DA 06 0F
        AND B                            ; $A601  A0
        LD A,C                           ; $A602  79
SUB_A603:
        SUB L                            ; $A603  95
        LD A,B                           ; $A604  78
        SBC A,H                          ; $A605  9C
        JP C,SUB_9FD1_5                  ; $A606  DA 0F A0
        EX DE,HL                         ; $A609  EB
        POP HL                           ; $A60A  E1
        INC HL                           ; $A60B  23
        JP SUB_9FD1_3+1                  ; $A60C  C3 FA 9F
SUB_A603_1:
        POP HL                           ; $A60F  E1
        PUSH BC                          ; $A610  C5
        PUSH DE                          ; $A611  D5
        PUSH HL                          ; $A612  E5
        EX DE,HL                         ; $A613  EB
        LD HL,(L_A9CE)                   ; $A614  2A CE A9
        ADD HL,DE                        ; $A617  19
        LD B,H                           ; $A618  44
        LD C,L                           ; $A619  4D
        CALL $AA1E                       ; $A61A  CD 1E AA
        POP DE                           ; $A61D  D1
        LD HL,(L_A9B5)                   ; $A61E  2A B5 A9
        LD (HL),E                        ; $A621  73
        INC HL                           ; $A622  23
        LD (HL),D                        ; $A623  72
        POP DE                           ; $A624  D1
        LD HL,(L_A9B7)                   ; $A625  2A B7 A9
        LD (HL),E                        ; $A628  73
        INC HL                           ; $A629  23
        LD (HL),D                        ; $A62A  72
        POP BC                           ; $A62B  C1
        LD A,C                           ; $A62C  79
        SUB E                            ; $A62D  93
        LD C,A                           ; $A62E  4F
        LD A,B                           ; $A62F  78
        SBC A,D                          ; $A630  9A
        LD B,A                           ; $A631  47
        LD HL,(L_A9D0)                   ; $A632  2A D0 A9
        EX DE,HL                         ; $A635  EB
        CALL $AA30                       ; $A636  CD 30 AA
        LD C,L                           ; $A639  4D
        LD B,H                           ; $A63A  44
SUB_A603_2:
        JP $AA21                         ; $A63B  C3 21 AA
SUB_A603_3:
        LD HL,L_A9C3                     ; $A63E  21 C3 A9
        LD C,(HL)                        ; $A641  4E
        LD A,(L_A9E3)                    ; $A642  3A E3 A9
        OR A                             ; $A645  B7
        RRA                              ; $A646  1F
        DEC C                            ; $A647  0D
SUB_A603_4:
        JP NZ,SUB_9FD1_10                ; $A648  C2 45 A0
        LD B,A                           ; $A64B  47
        LD A,$08                         ; $A64C  3E 08
        SUB (HL)                         ; $A64E  96
        LD C,A                           ; $A64F  4F
        LD A,(L_A9E2)                    ; $A650  3A E2 A9
        DEC C                            ; $A653  0D
        JP Z,SUB_9FD1_13+2               ; $A654  CA 5C A0
        OR A                             ; $A657  B7
        RLA                              ; $A658  17
        JP SUB_9FD1_12                   ; $A659  C3 53 A0
SUB_A603_5:
        ADD A,B                          ; $A65C  80
        RET                              ; $A65D  C9
SUB_A603_6:
        LD HL,(BDOS_DISPATCH_PTR)        ; $A65E  2A 43 9F
        LD DE,$0010                      ; $A661  11 10 00
SUB_A603_7:
        ADD HL,DE                        ; $A664  19
        ADD HL,BC                        ; $A665  09
        LD A,(L_A9DD)                    ; $A666  3A DD A9
        OR A                             ; $A669  B7
SUB_A603_8:
        JP Z,SUB_A05E_1                  ; $A66A  CA 71 A0
        LD L,(HL)                        ; $A66D  6E
SUB_A603_9:
        LD H,$00                         ; $A66E  26 00
        RET                              ; $A670  C9
SUB_A603_10:
        ADD HL,BC                        ; $A671  09
        LD E,(HL)                        ; $A672  5E
        INC HL                           ; $A673  23
        LD D,(HL)                        ; $A674  56
        EX DE,HL                         ; $A675  EB
        RET                              ; $A676  C9
SUB_A603_11:
        CALL SUB_9FD1_8+1                ; $A677  CD 3E A0
        LD C,A                           ; $A67A  4F
        LD B,$00                         ; $A67B  06 00
        CALL SUB_A05E                    ; $A67D  CD 5E A0
        LD (L_A9E5),HL                   ; $A680  22 E5 A9
        RET                              ; $A683  C9
SUB_A603_12:
        LD HL,(L_A9E5)                   ; $A684  2A E5 A9
        LD A,L                           ; $A687  7D
        OR H                             ; $A688  B4
        RET                              ; $A689  C9
SUB_A603_13:
        LD A,(L_A9C3)                    ; $A68A  3A C3 A9
        LD HL,(L_A9E5)                   ; $A68D  2A E5 A9
        ADD HL,HL                        ; $A690  29
        DEC A                            ; $A691  3D
        JP NZ,SUB_A077_5                 ; $A692  C2 90 A0
        LD (L_A9E7),HL                   ; $A695  22 E7 A9
SUB_A603_14:
        LD A,(L_A9C4)                    ; $A698  3A C4 A9
        LD C,A                           ; $A69B  4F
        LD A,(L_A9E3)                    ; $A69C  3A E3 A9
        AND C                            ; $A69F  A1
        OR L                             ; $A6A0  B5
        LD L,A                           ; $A6A1  6F
        LD (L_A9E5),HL                   ; $A6A2  22 E5 A9
        RET                              ; $A6A5  C9
SUB_A603_15:
        LD HL,(BDOS_DISPATCH_PTR)        ; $A6A6  2A 43 9F
        LD DE,$000C                      ; $A6A9  11 0C 00
        ADD HL,DE                        ; $A6AC  19
        RET                              ; $A6AD  C9
SUB_A603_16:
        LD HL,(BDOS_DISPATCH_PTR)        ; $A6AE  2A 43 9F
        LD DE,$000F                      ; $A6B1  11 0F 00
        ADD HL,DE                        ; $A6B4  19
        EX DE,HL                         ; $A6B5  EB
        LD HL,$0011                      ; $A6B6  21 11 00
        ADD HL,DE                        ; $A6B9  19
        RET                              ; $A6BA  C9
SUB_A603_17:
        CALL SUB_A0AE                    ; $A6BB  CD AE A0
        LD A,(HL)                        ; $A6BE  7E
        LD (L_A9E3),A                    ; $A6BF  32 E3 A9
        EX DE,HL                         ; $A6C2  EB
        LD A,(HL)                        ; $A6C3  7E
        LD (L_A9E1),A                    ; $A6C4  32 E1 A9
        CALL SUB_A077_6+2                ; $A6C7  CD A6 A0
        LD A,(L_A9C5)                    ; $A6CA  3A C5 A9
        AND (HL)                         ; $A6CD  A6
        LD (L_A9E2),A                    ; $A6CE  32 E2 A9
        RET                              ; $A6D1  C9
SUB_A603_18:
        CALL SUB_A0AE                    ; $A6D2  CD AE A0
        LD A,(L_A9D5)                    ; $A6D5  3A D5 A9
        CP $02                           ; $A6D8  FE 02
        JP NZ,SUB_A0AE_5                 ; $A6DA  C2 DE A0
        XOR A                            ; $A6DD  AF
        LD C,A                           ; $A6DE  4F
        LD A,(L_A9E3)                    ; $A6DF  3A E3 A9
        ADD A,C                          ; $A6E2  81
        LD (HL),A                        ; $A6E3  77
        EX DE,HL                         ; $A6E4  EB
        LD A,(L_A9E1)                    ; $A6E5  3A E1 A9
        LD (HL),A                        ; $A6E8  77
        RET                              ; $A6E9  C9
SUB_A603_19:
        INC C                            ; $A6EA  0C
        DEC C                            ; $A6EB  0D
        RET Z                            ; $A6EC  C8
        LD A,H                           ; $A6ED  7C
        OR A                             ; $A6EE  B7
        RRA                              ; $A6EF  1F
        LD H,A                           ; $A6F0  67
        LD A,L                           ; $A6F1  7D
        RRA                              ; $A6F2  1F
        LD L,A                           ; $A6F3  6F
        JP SUB_A0EA_1                    ; $A6F4  C3 EB A0
SUB_A603_20:
        LD C,$80                         ; $A6F7  0E 80
        LD HL,(L_A9B9)                   ; $A6F9  2A B9 A9
        XOR A                            ; $A6FC  AF
        ADD A,(HL)                       ; $A6FD  86
SUB_A603_21:
        INC HL                           ; $A6FE  23
        DEC C                            ; $A6FF  0D
SUB_A603_22:
        XOR B                            ; $A700  A8
        LD (HL),E                        ; $A701  73
        DEC HL                           ; $A702  2B
SUB_A703:
        LD (HL),B                        ; $A703  70
        DEC HL                           ; $A704  2B
        LD (HL),C                        ; $A705  71
SUB_A703_1:
        CALL SUB_A32D                    ; $A706  CD 2D A3
        JP SUB_A7A5_6+1                  ; $A709  C3 E4 A7
SUB_A703_2:
        POP HL                           ; $A70C  E1
        RET                              ; $A70D  C9
SUB_A703_3:
        LD HL,(BDOS_DISPATCH_PTR)        ; $A70E  2A 43 9F
        LD DE,$0020                      ; $A711  11 20 00
        CALL SUB_A7A5                    ; $A714  CD A5 A7
        LD HL,$0021                      ; $A717  21 21 00
SUB_A703_4:
        ADD HL,DE                        ; $A71A  19
        LD (HL),C                        ; $A71B  71
        INC HL                           ; $A71C  23
        LD (HL),B                        ; $A71D  70
        INC HL                           ; $A71E  23
        LD (HL),A                        ; $A71F  77
        RET                              ; $A720  C9
SUB_A703_5:
        LD HL,(L_A9AF)                   ; $A721  2A AF A9
        LD A,($9F42)                     ; $A724  3A 42 9F
        LD C,A                           ; $A727  4F
        CALL SUB_A0EA                    ; $A728  CD EA A0
        PUSH HL                          ; $A72B  E5
        EX DE,HL                         ; $A72C  EB
        CALL SUB_9F59                    ; $A72D  CD 59 9F
        POP HL                           ; $A730  E1
        CALL Z,SUB_9DA4_36+1             ; $A731  CC 47 9F
        LD A,L                           ; $A734  7D
        RRA                              ; $A735  1F
        RET C                            ; $A736  D8
        LD HL,(L_A9AF)                   ; $A737  2A AF A9
        LD C,L                           ; $A73A  4D
        LD B,H                           ; $A73B  44
        CALL SUB_A10B                    ; $A73C  CD 0B A1
        LD (L_A9AF),HL                   ; $A73F  22 AF A9
        JP SUB_A26B_6                    ; $A742  C3 A3 A2
SUB_A703_6:
        LD A,(L_A9D6)                    ; $A745  3A D6 A9
        LD HL,$9F42                      ; $A748  21 42 9F
        CP (HL)                          ; $A74B  BE
        RET Z                            ; $A74C  C8
        LD (HL),A                        ; $A74D  77
        JP SUB_A7A5_16+1                 ; $A74E  C3 21 A8
SUB_A703_7:
        LD A,$FF                         ; $A751  3E FF
        LD (L_A9DE),A                    ; $A753  32 DE A9
        LD HL,(BDOS_DISPATCH_PTR)        ; $A756  2A 43 9F
        LD A,(HL)                        ; $A759  7E
        AND $1F                          ; $A75A  E6 1F
        DEC A                            ; $A75C  3D
        LD (L_A9D6),A                    ; $A75D  32 D6 A9
        CP $1E                           ; $A760  FE 1E
        JP NC,SUB_A7A5_25+1              ; $A762  D2 75 A8
        LD A,($9F42)                     ; $A765  3A 42 9F
        LD (L_A9DF),A                    ; $A768  32 DF A9
        LD A,(HL)                        ; $A76B  7E
        LD (L_A9E0),A                    ; $A76C  32 E0 A9
        AND $E0                          ; $A76F  E6 E0
        LD (HL),A                        ; $A771  77
        CALL SUB_A7A5_21+1               ; $A772  CD 45 A8
        LD A,($9F41)                     ; $A775  3A 41 9F
        LD HL,(BDOS_DISPATCH_PTR)        ; $A778  2A 43 9F
        OR (HL)                          ; $A77B  B6
        LD (HL),A                        ; $A77C  77
        RET                              ; $A77D  C9
SUB_A703_8:
        LD A,$22                         ; $A77E  3E 22
        JP SUB_9DA4_31                   ; $A780  C3 01 9F
SUB_A703_9:
        LD HL,$0000                      ; $A783  21 00 00
        LD (L_A9AD),HL                   ; $A786  22 AD A9
SUB_A703_10:
        LD (L_A9AF),HL                   ; $A789  22 AF A9
        XOR A                            ; $A78C  AF
        LD ($9F42),A                     ; $A78D  32 42 9F
        LD HL,$0080                      ; $A790  21 80 00
SUB_A703_11:
        LD (L_A9B1),HL                   ; $A793  22 B1 A9
        CALL SUB_A1C6_2+2                ; $A796  CD DA A1
        JP SUB_A7A5_16+1                 ; $A799  C3 21 A8
SUB_A703_12:
        CALL SUB_A164_2+1                ; $A79C  CD 72 A1
        CALL SUB_A7A5_24+1               ; $A79F  CD 51 A8
        JP SUB_A451                      ; $A7A2  C3 51 A4
SUB_A7A5:
        CALL SUB_A7A5_24+1               ; $A7A5  CD 51 A8
        JP SUB_A451_4+1                  ; $A7A8  C3 A2 A4
SUB_A7A5_1:
        LD C,$00                         ; $A7AB  0E 00
        EX DE,HL                         ; $A7AD  EB
        LD A,(HL)                        ; $A7AE  7E
        CP $3F                           ; $A7AF  FE 3F
        JP Z,L_A8C2                      ; $A7B1  CA C2 A8
        CALL SUB_A077_6+2                ; $A7B4  CD A6 A0
        LD A,(HL)                        ; $A7B7  7E
        CP $3F                           ; $A7B8  FE 3F
        CALL NZ,SUB_A164_2+1             ; $A7BA  C4 72 A1
        CALL SUB_A7A5_24+1               ; $A7BD  CD 51 A8
        LD C,$0F                         ; $A7C0  0E 0F
        CALL SUB_A26B_20+1               ; $A7C2  CD 18 A3
        JP SUB_A1C6_5                    ; $A7C5  C3 E9 A1
SUB_A7A5_2:
        LD HL,(L_A9D9)                   ; $A7C8  2A D9 A9
        LD (BDOS_DISPATCH_PTR),HL        ; $A7CB  22 43 9F
        CALL SUB_A7A5_24+1               ; $A7CE  CD 51 A8
SUB_A7A5_3:
        CALL SUB_A32D                    ; $A7D1  CD 2D A3
        JP SUB_A1C6_5                    ; $A7D4  C3 E9 A1
SUB_A7A5_4:
        CALL SUB_A7A5_24+1               ; $A7D7  CD 51 A8
        CALL SUB_A32D_8+2                ; $A7DA  CD 9C A3
        JP SUB_A26B_18                   ; $A7DD  C3 01 A3
SUB_A7A5_5:
        CALL SUB_A7A5_24+1               ; $A7E0  CD 51 A8
SUB_A7A5_6:
        JP SUB_A55A_9                    ; $A7E3  C3 BC A5
        CALL SUB_A7A5_24+1               ; $A7E6  CD 51 A8
        JP SUB_A5C1_4                    ; $A7E9  C3 FE A5
SUB_A7A5_7:
        CALL SUB_A164_2+1                ; $A7EC  CD 72 A1
        CALL SUB_A7A5_24+1               ; $A7EF  CD 51 A8
        JP SUB_A524                      ; $A7F2  C3 24 A5
SUB_A7A5_8:
        CALL SUB_A7A5_24+1               ; $A7F5  CD 51 A8
        CALL SUB_A416                    ; $A7F8  CD 16 A4
        JP SUB_A26B_18                   ; $A7FB  C3 01 A3
SUB_A7A5_9:
        LD HL,(L_A9AF)                   ; $A7FE  2A AF A9
        JP L_A929                        ; $A801  C3 29 A9
SUB_A7A5_10:
        LD A,($9F42)                     ; $A804  3A 42 9F
        JP SUB_9DA4_31                   ; $A807  C3 01 9F
SUB_A7A5_11:
        EX DE,HL                         ; $A80A  EB
SUB_A7A5_12:
        LD (L_A9B1),HL                   ; $A80B  22 B1 A9
        JP SUB_A1C6_2+2                  ; $A80E  C3 DA A1
SUB_A7A5_13:
        LD HL,(L_A9BF)                   ; $A811  2A BF A9
        JP L_A929                        ; $A814  C3 29 A9
SUB_A7A5_14:
        LD HL,(L_A9AD)                   ; $A817  2A AD A9
        JP L_A929                        ; $A81A  C3 29 A9
SUB_A7A5_15:
        CALL SUB_A7A5_24+1               ; $A81D  CD 51 A8
SUB_A7A5_16:
        CALL SUB_A43B                    ; $A820  CD 3B A4
        JP SUB_A26B_18                   ; $A823  C3 01 A3
SUB_A7A5_17:
        LD HL,(L_A9BB)                   ; $A826  2A BB A9
        LD (SUB_9DA4_35+1),HL            ; $A829  22 45 9F
        RET                              ; $A82C  C9
SUB_A7A5_18:
        LD A,(L_A9D6)                    ; $A82D  3A D6 A9
        CP $FF                           ; $A830  FE FF
        JP NZ,L_A93B                     ; $A832  C2 3B A9
        LD A,($9F41)                     ; $A835  3A 41 9F
        JP SUB_9DA4_31                   ; $A838  C3 01 9F
SUB_A7A5_19:
        AND $1F                          ; $A83B  E6 1F
        LD ($9F41),A                     ; $A83D  32 41 9F
        RET                              ; $A840  C9
SUB_A7A5_20:
        CALL SUB_A7A5_24+1               ; $A841  CD 51 A8
SUB_A7A5_21:
        JP SUB_A703_11                   ; $A844  C3 93 A7
SUB_A7A5_22:
        CALL SUB_A7A5_24+1               ; $A847  CD 51 A8
        JP SUB_A703_12                   ; $A84A  C3 9C A7
SUB_A7A5_23:
        CALL SUB_A7A5_24+1               ; $A84D  CD 51 A8
SUB_A7A5_24:
        JP SUB_A7A5_3+1                  ; $A850  C3 D2 A7
        LD HL,(BDOS_DISPATCH_PTR)        ; $A853  2A 43 9F
        LD A,L                           ; $A856  7D
        CPL                              ; $A857  2F
        LD E,A                           ; $A858  5F
        LD A,H                           ; $A859  7C
        CPL                              ; $A85A  2F
        LD HL,(L_A9AF)                   ; $A85B  2A AF A9
        AND H                            ; $A85E  A4
        LD D,A                           ; $A85F  57
        LD A,L                           ; $A860  7D
        AND E                            ; $A861  A3
        LD E,A                           ; $A862  5F
        LD HL,(L_A9AD)                   ; $A863  2A AD A9
        EX DE,HL                         ; $A866  EB
        LD (L_A9AF),HL                   ; $A867  22 AF A9
        LD A,L                           ; $A86A  7D
        AND E                            ; $A86B  A3
        LD L,A                           ; $A86C  6F
        LD A,H                           ; $A86D  7C
        AND D                            ; $A86E  A2
        LD H,A                           ; $A86F  67
        LD (L_A9AD),HL                   ; $A870  22 AD A9
        RET                              ; $A873  C9
SUB_A7A5_25:
        LD A,(L_A9DE)                    ; $A874  3A DE A9
        OR A                             ; $A877  B7
        JP Z,L_A991                      ; $A878  CA 91 A9
        LD HL,(BDOS_DISPATCH_PTR)        ; $A87B  2A 43 9F
        LD (HL),$00                      ; $A87E  36 00
        LD A,(L_A9E0)                    ; $A880  3A E0 A9
        OR A                             ; $A883  B7
        JP Z,L_A991                      ; $A884  CA 91 A9
        LD (HL),A                        ; $A887  77
        LD A,(L_A9DF)                    ; $A888  3A DF A9
        LD (L_A9D6),A                    ; $A88B  32 D6 A9
        CALL SUB_A7A5_21+1               ; $A88E  CD 45 A8
        LD HL,($9F0F)                    ; $A891  2A 0F 9F
        LD SP,HL                         ; $A894  F9
        LD HL,(SUB_9DA4_35+1)            ; $A895  2A 45 9F
        LD A,L                           ; $A898  7D
        LD B,H                           ; $A899  44
        RET                              ; $A89A  C9
SUB_A7A5_26:
        CALL SUB_A7A5_24+1               ; $A89B  CD 51 A8
        LD A,$02                         ; $A89E  3E 02
        LD (L_A9D5),A                    ; $A8A0  32 D5 A9
        LD C,$00                         ; $A8A3  0E 00
        CALL SUB_A703_1+1                ; $A8A5  CD 07 A7
        CALL Z,SUB_A603                  ; $A8A8  CC 03 A6
        RET                              ; $A8AB  C9
        DEFB    $E5,$00,$00,$00,$00,$80                          ; $A8AC
        DEFS    16, $00    ; $A8B2  fill
L_A8C2:
        DEFS    62, $00    ; $A8C2  fill
        DEFS    16, $E5    ; $A900  fill
L_A910:
        DEFS    25, $E5    ; $A910  fill
L_A929:
        DEFS    18, $E5    ; $A929  fill
L_A93B:
        DEFS    57, $E5    ; $A93B  fill
L_A974:
        DEFS    29, $E5    ; $A974  fill
L_A991:
        DEFS    27, $E5    ; $A991  fill
L_A9AC:
        DEFB    $E5                                              ; $A9AC
L_A9AD:
        DEFB    $E5,$E5                                          ; $A9AD
L_A9AF:
        DEFB    $E5,$E5                                          ; $A9AF
L_A9B1:
        DEFB    $E5,$E5                                          ; $A9B1
L_A9B3:
        DEFB    $E5,$E5                                          ; $A9B3
L_A9B5:
        DEFB    $E5,$E5                                          ; $A9B5
L_A9B7:
        DEFB    $E5,$E5                                          ; $A9B7
L_A9B9:
        DEFB    $E5,$E5                                          ; $A9B9
L_A9BB:
        DEFB    $E5,$E5                                          ; $A9BB
L_A9BD:
        DEFB    $E5,$E5                                          ; $A9BD
L_A9BF:
        DEFB    $E5,$E5                                          ; $A9BF
L_A9C1:
        DEFB    $E5,$E5                                          ; $A9C1
L_A9C3:
        DEFB    $E5                                              ; $A9C3
L_A9C4:
        DEFB    $E5                                              ; $A9C4
L_A9C5:
        DEFB    $E5                                              ; $A9C5
L_A9C6:
        DEFB    $E5,$E5                                          ; $A9C6
L_A9C8:
        DEFB    $E5,$E5                                          ; $A9C8
L_A9CA:
        DEFB    $E5,$E5                                          ; $A9CA
L_A9CC:
        DEFB    $E5,$E5                                          ; $A9CC
L_A9CE:
        DEFB    $E5,$E5                                          ; $A9CE
L_A9D0:
        DEFB    $E5,$E5                                          ; $A9D0
L_A9D2:
        DEFB    $E5                                              ; $A9D2
L_A9D3:
        DEFB    $E5                                              ; $A9D3
L_A9D4:
        DEFB    $E5                                              ; $A9D4
L_A9D5:
        DEFB    $E5                                              ; $A9D5
L_A9D6:
        DEFB    $E5                                              ; $A9D6
L_A9D7:
        DEFB    $E5                                              ; $A9D7
L_A9D8:
        DEFB    $E5                                              ; $A9D8
L_A9D9:
        DEFB    $E5,$E5,$E5,$E5                                  ; $A9D9
L_A9DD:
        DEFB    $E5                                              ; $A9DD
L_A9DE:
        DEFB    $E5                                              ; $A9DE
L_A9DF:
        DEFB    $E5                                              ; $A9DF
L_A9E0:
        DEFB    $E5                                              ; $A9E0
L_A9E1:
        DEFB    $E5                                              ; $A9E1
L_A9E2:
        DEFB    $E5                                              ; $A9E2
L_A9E3:
        DEFB    $E5,$E5                                          ; $A9E3
L_A9E5:
        DEFB    $E5,$E5                                          ; $A9E5
L_A9E7:
        DEFB    $E5,$E5                                          ; $A9E7
L_A9E9:
        DEFB    $E5                                              ; $A9E9
L_A9EA:
        DEFB    $E5                                              ; $A9EA
L_A9EB:
        DEFB    $E5                                              ; $A9EB
L_A9EC:
        DEFS    20, $E5    ; $A9EC  fill


    SAVEBIN "{out_bin}", $9C00, $0E00
