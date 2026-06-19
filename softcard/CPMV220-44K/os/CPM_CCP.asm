; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- staged System Image (CCP + BDOS)
; ----------------------------------------------------------------------------
; Reverse-engineered from the raw on-disk bytes (sysimg_220_44k.bin), exactly
; the 5888 bytes that load at $9300. Reassembles BYTE-IDENTICAL.
;
; Runtime layout (BIOS jump table at staging offset $1700 == $AA00):
;   $9300-$93FF  Pre-CCP / serial page (parser delimiter helpers + 6502 block)
;   $9400-$94FC  Embedded 6502 RPC payload -- LDA/STA against the I/O Config
;                Block cells ($03E0-$03EB) + JSR $0Exx + RTS. This is 6502
;                machine code carried inside the Z-80 image; the SoftCard runs
;                it on the 6502 side via the CPU-switch RPC, so from the Z-80's
;                view it is DATA (decoding it as Z-80 is garbage). See the
;                CALL $94xx fan-in from the CCP -- those reference 6502 entries.
;   $9400-$9CFF  CCP -- command line parse, built-in table (DIR ERA TYPE SAVE
;                REN USER), 8-word dispatch table at $95C2, transient .COM
;                loader, $$$.SUB chaining, and the CP/M error texts.
;   $9D00-$A8FF  BDOS (Microsoft SoftCard BDOS) -- function entry $9E16 (the
;                referenced re-entry: save caller SP, switch to local stack,
;                dispatch on C via the runtime pointer cell $9F43); $9E09-$9E15
;                is data. FCB/directory/disk-record logic follows.
;   $A900-$A9FF  BDOS variable + buffer page; $E5 (uninitialized) on disk.
;
; Message mechanism (prior finding, confirmed): the error texts are reached two
; ways. Pointer form -- LD BC,<msg>; (CALL/JP print) -- for NO SPACE / FILE
; EXISTS / BAD LOAD (the LD BC targets the string head). Computed/position form
; for READ ERROR / NO FILE / ALL (Y/N)? -- the locator references an INTERIOR
; offset of the text (e.g. CALL $9854 lands inside "ALL (Y/N)?"), which is why
; those targets read as mid-string addresses, not labels.
;
; Address facts cross-checked against the 2.20 manual reconcile sheet:
; CCP=$9400, BDOS=$9C00-region, I/O Config Block at 6502 $0200-$03FF (Z-80
; $F200-$F3FF), 6502 RPC cells $45-$49, A$VEC=$F3D0, Z$CPU=$F3DE.
;
; Clean-room: decompiled solely from these bytes + public CP/M 2.2 architecture
; and softcard/docs/CPM_Manual_Reconcile_Facts.md -- no 56K/2.23 source. The
; code/data split was adversarially verified and reassembles BYTE-IDENTICAL;
; comment PROSE is [AI] machine-inferred (a hint, not a manual citation) unless
; marked [DOC <manual> <page>]; [?] = open question.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ENDIF

; -- External symbols --
BDOS_DISPATCH_PTR    EQU $9F43               ; runtime pointer cell used by the BDOS function dispatch

; -- Mid-instruction references (shown inline as cover+offset) --
;   $9504 -> SUB_94FE_2+1         shared instruction tail: $9504 is reachable code inside the instruction at $9503
;   $9539 -> SUB_9529_1+2         z80 skip idiom: enters the operand of $11 at $9537
;   $95DD -> SUB_95D8_2+1         shared instruction tail: $95DD is reachable code inside the instruction at $95DC
;   $95FD -> SUB_95F5_2+2         shared instruction tail: $95FD is reachable code inside the instruction at $95FB
;   $961E -> SUB_9609_3+1         shared instruction tail: $961E is reachable code inside the instruction at $961D
;   $9660 -> SUB_965E_1+1         shared instruction tail: $9660 is reachable code inside the instruction at $965F
;   $9690 -> SUB_965E_8+1         shared instruction tail: $9690 is reachable code inside the instruction at $968F
;   $96A1 -> SUB_965E_11+2        z80 skip idiom: enters the operand of $11 at $969F
;   $96A9 -> SUB_965E_13+1        z80 skip idiom: enters the operand of $11 at $96A8
;   $96C8 -> SUB_965E_18+1        z80 skip idiom: enters the operand of $01 at $96C7
;   $96DF -> SUB_965E_22+1        shared instruction tail: $96DF is reachable code inside the instruction at $96DE
;   $96E9 -> SUB_965E_23+1        shared instruction tail: $96E9 is reachable code inside the instruction at $96E8
;   $973C -> SUB_972E_2+1         shared instruction tail: $973C is reachable code inside the instruction at $973B
;   $9782 -> SUB_972E_10+1        shared instruction tail: $9782 is reachable code inside the instruction at $9781
;   $97EA -> SUB_97D9_1+2         shared instruction tail: $97EA is reachable code inside the instruction at $97E8
;   $97F8 -> SUB_97D9_2+1         z80 skip idiom: enters the operand of $3E at $97F7
;   $9840 -> SUB_97D9_8+1         shared instruction tail: $9840 is reachable code inside the instruction at $983F
;   $9898 -> SUB_9866_2+1         shared instruction tail: $9898 is reachable code inside the instruction at $9897
;   $98F9 -> SUB_9866_10+1        shared instruction tail: $98F9 is reachable code inside the instruction at $98F8
;   $990E -> SUB_9866_13+2        shared instruction tail: $990E is reachable code inside the instruction at $990C
;   $9974 -> SUB_9866_23+2        shared instruction tail: $9974 is reachable code inside the instruction at $9972
;   $99A0 -> SUB_9866_30+2        shared instruction tail: $99A0 is reachable code inside the instruction at $999E
;   $99A7 -> SUB_9866_31+2        shared instruction tail: $99A7 is reachable code inside the instruction at $99A5
;   $99F1 -> SUB_9866_37+1        shared instruction tail: $99F1 is reachable code inside the instruction at $99F0
;   $9B30 -> SUB_9866_55+2        shared instruction tail: $9B30 is reachable code inside the instruction at $9B2E
;   $9B4F -> SUB_9866_59+1        shared instruction tail: $9B4F is reachable code inside the instruction at $9B4E
;   $9B86 -> SUB_9866_63+1        shared instruction tail: $9B86 is reachable code inside the instruction at $9B85
;   $9BD6 -> SUB_9866_67+2        shared instruction tail: $9BD6 is reachable code inside the instruction at $9BD4
;   $9BDD -> SUB_9866_68+2        shared instruction tail: $9BDD is reachable code inside the instruction at $9BDB
;   $9BF1 -> SUB_9866_69+2        shared instruction tail: $9BF1 is reachable code inside the instruction at $9BEF
;   $9C0B -> SUB_9866_71+2        shared instruction tail: $9C0B is reachable code inside the instruction at $9C09
;   $9C47 -> SUB_9866_74+1        shared instruction tail: $9C47 is reachable code inside the instruction at $9C46
;   $9D23 -> SUB_9D14_2+2         shared instruction tail: $9D23 is reachable code inside the instruction at $9D21
;   $9D45 -> SUB_9D14_4+2         shared instruction tail: $9D45 is reachable code inside the instruction at $9D43
;   $9D48 -> SUB_9D14_5+1         shared instruction tail: $9D48 is reachable code inside the instruction at $9D47
;   $9D62 -> SUB_9D14_6+1         shared instruction tail: $9D62 is reachable code inside the instruction at $9D61
;   $9D96 -> SUB_9D90_1+2         shared instruction tail: $9D96 is reachable code inside the instruction at $9D94
;   $9DAC -> SUB_9DA4_1+1         shared instruction tail: $9DAC is reachable code inside the instruction at $9DAB
;   $9DB1 -> SUB_9DA4_2+1         shared instruction tail: $9DB1 is reachable code inside the instruction at $9DB0
;   $9DB9 -> SUB_9DA4_3+1         shared instruction tail: $9DB9 is reachable code inside the instruction at $9DB8
;   $9DC9 -> SUB_9DA4_5+1         shared instruction tail: $9DC9 is reachable code inside the instruction at $9DC8
;   $9DD3 -> SUB_9DA4_6+2         shared instruction tail: $9DD3 is reachable code inside the instruction at $9DD1
;   $9DE1 -> SUB_9DA4_7+1         shared instruction tail: $9DE1 is reachable code inside the instruction at $9DE0
;   $9DEF -> SUB_9DA4_9+1         shared instruction tail: $9DEF is reachable code inside the instruction at $9DEE
;   $9E1C -> SUB_9DA4_14+2        z80 skip idiom: enters the operand of $21 at $9E1A
;   $9E26 -> SUB_9DA4_15+2        shared instruction tail: $9E26 is reachable code inside the instruction at $9E24
;   $9E4E -> SUB_9DA4_19+1        shared instruction tail: $9E4E is reachable code inside the instruction at $9E4D
;   $9E78 -> SUB_9DA4_23+1        shared instruction tail: $9E78 is reachable code inside the instruction at $9E77
;   $9EA6 -> SUB_9DA4_26+1        z80 skip idiom: enters the operand of $21 at $9EA5
;   $9EA9 -> SUB_9DA4_27+1        shared instruction tail: $9EA9 is reachable code inside the instruction at $9EA8
;   $9F05 -> SUB_9DA4_32+1        shared instruction tail: $9F05 is reachable code inside the instruction at $9F04
;   $9F45 -> SUB_9DA4_35+1        shared instruction tail: $9F45 is reachable code inside the instruction at $9F44
;   $9F47 -> SUB_9DA4_36+1        shared instruction tail: $9F47 is reachable code inside the instruction at $9F46
;   $9F4A -> SUB_9DA4_37+2        shared instruction tail: $9F4A is reachable code inside the instruction at $9F48
;   $9F4F -> SUB_9DA4_38+1        shared instruction tail: $9F4F is reachable code inside the instruction at $9F4E
;   $9F50 -> SUB_9DA4_38+2        shared instruction tail: $9F50 is reachable code inside the instruction at $9F4E
;   $9FB2 -> SUB_9FA1_2+2         shared instruction tail: $9FB2 is reachable code inside the instruction at $9FB0
;   $9FC3 -> SUB_9FB8_2+1         shared instruction tail: $9FC3 is reachable code inside the instruction at $9FC2
;   $9FE4 -> SUB_9FD1_1+2         shared instruction tail: $9FE4 is reachable code inside the instruction at $9FE2
;   $9FFA -> SUB_9FD1_3+1         shared instruction tail: $9FFA is reachable code inside the instruction at $9FF9
;   $A03E -> SUB_9FD1_8+1         shared instruction tail: $A03E is reachable code inside the instruction at $A03D
;   $A05C -> SUB_9FD1_13+2        shared instruction tail: $A05C is reachable code inside the instruction at $A05A
;   $A084 -> SUB_A077_3+1         shared instruction tail: $A084 is reachable code inside the instruction at $A083
;   $A08A -> SUB_A077_4+1         shared instruction tail: $A08A is reachable code inside the instruction at $A089
;   $A0A6 -> SUB_A077_6+2         shared instruction tail: $A0A6 is reachable code inside the instruction at $A0A4
;   $A0BB -> SUB_A0AE_2+2         shared instruction tail: $A0BB is reachable code inside the instruction at $A0B9
;   $A0D2 -> SUB_A0AE_4+2         shared instruction tail: $A0D2 is reachable code inside the instruction at $A0D0
;   $A104 -> SUB_A0F7_1+1         z80 skip idiom: enters the operand of $01 at $A103
;   $A105 -> SUB_A0F7_1+2         z80 skip idiom: enters the operand of $01 at $A103
;   $A11E -> SUB_A10B_1+2         shared instruction tail: $A11E is reachable code inside the instruction at $A11C
;   $A12C -> SUB_A10B_4+1         z80 skip idiom: enters the operand of $21 at $A12B
;   $A144 -> SUB_A10B_5+1         shared instruction tail: $A144 is reachable code inside the instruction at $A143
;   $A169 -> SUB_A164_1+1         z80 skip idiom: enters the operand of $01 at $A168
;   $A172 -> SUB_A164_2+1         shared instruction tail: $A172 is reachable code inside the instruction at $A171
;   $A17F -> SUB_A178_1+2         shared instruction tail: $A17F is reachable code inside the instruction at $A17D
;   $A18C -> SUB_A178_3+1         shared instruction tail: $A18C is reachable code inside the instruction at $A18B
;   $A195 -> SUB_A178_4+2         shared instruction tail: $A195 is reachable code inside the instruction at $A193
;   $A19E -> SUB_A19C_1+1         shared instruction tail: $A19E is reachable code inside the instruction at $A19D
;   $A1C4 -> SUB_A19C_5+1         shared instruction tail: $A1C4 is reachable code inside the instruction at $A1C3
;   $A1D4 -> SUB_A1C6_1+1         shared instruction tail: $A1D4 is reachable code inside the instruction at $A1D3
;   $A1DA -> SUB_A1C6_2+2         shared instruction tail: $A1DA is reachable code inside the instruction at $A1D8
;   $A1E0 -> SUB_A1C6_3+1         shared instruction tail: $A1E0 is reachable code inside the instruction at $A1DF
;   $A205 -> SUB_A1FE_1+1         shared instruction tail: $A205 is reachable code inside the instruction at $A204
;   $A219 -> SUB_A1FE_3+1         shared instruction tail: $A219 is reachable code inside the instruction at $A218
;   $A235 -> SUB_A1FE_6+1         shared instruction tail: $A235 is reachable code inside the instruction at $A234
;   $A256 -> SUB_A1FE_8+1         shared instruction tail: $A256 is reachable code inside the instruction at $A255
;   $A288 -> SUB_A26B_2+1         shared instruction tail: $A288 is reachable code inside the instruction at $A287
;   $A29D -> SUB_A26B_5+1         z80 skip idiom: enters the operand of $21 at $A29C
;   $A2D2 -> SUB_A26B_11+1        shared instruction tail: $A2D2 is reachable code inside the instruction at $A2D1
;   $A307 -> SUB_A26B_19+2        shared instruction tail: $A307 is reachable code inside the instruction at $A305
;   $A318 -> SUB_A26B_20+1        shared instruction tail: $A318 is reachable code inside the instruction at $A317
;   $A34A -> SUB_A32D_1+2         shared instruction tail: $A34A is reachable code inside the instruction at $A348
;   $A394 -> SUB_A32D_7+2         shared instruction tail: $A394 is reachable code inside the instruction at $A392
;   $A39C -> SUB_A32D_8+2         shared instruction tail: $A39C is reachable code inside the instruction at $A39A
;   $A3A4 -> SUB_A32D_9+2         shared instruction tail: $A3A4 is reachable code inside the instruction at $A3A2
;   $A3D1 -> SUB_A3BE_2+1         shared instruction tail: $A3D1 is reachable code inside the instruction at $A3D0
;   $A3F4 -> SUB_A3BE_4+2         z80 skip idiom: enters the operand of $21 at $A3F2
;   $A3FD -> SUB_A3BE_5+2         shared instruction tail: $A3FD is reachable code inside the instruction at $A3FB
;   $A45A -> SUB_A451_1+1         shared instruction tail: $A45A is reachable code inside the instruction at $A459
;   $A494 -> SUB_A451_3+2         z80 skip idiom: enters the operand of $21 at $A492
;   $A4A2 -> SUB_A451_4+1         shared instruction tail: $A4A2 is reachable code inside the instruction at $A4A1
;   $A4FD -> SUB_A451_12+2        shared instruction tail: $A4FD is reachable code inside the instruction at $A4FB
;   $A546 -> SUB_A524_1+2         shared instruction tail: $A546 is reachable code inside the instruction at $A544
;   $A583 -> SUB_A55A_1+2         shared instruction tail: $A583 is reachable code inside the instruction at $A581
;   $A58E -> SUB_A55A_2+1         shared instruction tail: $A58E is reachable code inside the instruction at $A58D
;   $A5AC -> SUB_A55A_6+2         z80 skip idiom: enters the operand of $21 at $A5AA
;   $A5E6 -> SUB_A5C1_2+2         shared instruction tail: $A5E6 is reachable code inside the instruction at $A5E4
;   $A66C -> SUB_A603_8+2         shared instruction tail: $A66C is reachable code inside the instruction at $A66A
;   $A68C -> SUB_A603_13+2        shared instruction tail: $A68C is reachable code inside the instruction at $A68A
;   $A69A -> SUB_A603_14+2        shared instruction tail: $A69A is reachable code inside the instruction at $A698
;   $A707 -> SUB_A703_1+1         shared instruction tail: $A707 is reachable code inside the instruction at $A706
;   $A747 -> SUB_A703_6+2         shared instruction tail: $A747 is reachable code inside the instruction at $A745
;   $A77F -> SUB_A703_8+1         z80 skip idiom: enters the operand of $3E at $A77E
;   $A784 -> SUB_A703_9+1         z80 skip idiom: enters the operand of $21 at $A783
;   $A78B -> SUB_A703_10+2        shared instruction tail: $A78B is reachable code inside the instruction at $A789
;   $A7D2 -> SUB_A7A5_3+1         shared instruction tail: $A7D2 is reachable code inside the instruction at $A7D1
;   $A7E4 -> SUB_A7A5_6+1         shared instruction tail: $A7E4 is reachable code inside the instruction at $A7E3
;   $A80C -> SUB_A7A5_12+1        shared instruction tail: $A80C is reachable code inside the instruction at $A80B
;   $A821 -> SUB_A7A5_16+1        shared instruction tail: $A821 is reachable code inside the instruction at $A820
;   $A845 -> SUB_A7A5_21+1        shared instruction tail: $A845 is reachable code inside the instruction at $A844
;   $A851 -> SUB_A7A5_24+1        shared instruction tail: $A851 is reachable code inside the instruction at $A850
;   $A875 -> SUB_A7A5_25+1        shared instruction tail: $A875 is reachable code inside the instruction at $A874

    IFNDEF CPM_LINK
    ORG $9300
    ENDIF


L_9300:
        RST $08                          ; $9300  CF
        SUB A                            ; $9301  97
        INC DE                           ; $9302  13
        INC HL                           ; $9303  23
        DEC B                            ; $9304  05
        JP NZ,SUB_95F5_2+2               ; $9305  C2 FD 95
        RET                              ; $9308  C9
L_9309:
        CALL SUB_9498                    ; $9309  CD 98 94
        LD HL,(L_948A)                   ; $930C  2A 8A 94
        LD A,(HL)                        ; $930F  7E
        CP $20                           ; $9310  FE 20
        JP Z,SUB_9609_4                  ; $9312  CA 22 96
        OR A                             ; $9315  B7
        JP Z,SUB_9609_4                  ; $9316  CA 22 96
        PUSH HL                          ; $9319  E5
        CALL SUB_948C                    ; $931A  CD 8C 94
        POP HL                           ; $931D  E1
        INC HL                           ; $931E  23
        JP SUB_9609_1                    ; $931F  C3 0F 96
L_9322:
        LD A,$3F                         ; $9322  3E 3F
        CALL SUB_948C                    ; $9324  CD 8C 94
        CALL SUB_9498                    ; $9327  CD 98 94
        CALL SUB_95D8_2+1                ; $932A  CD DD 95
        JP SUB_972E_10+1                 ; $932D  C3 82 97
L_9330:
        LD A,(DE)                        ; $9330  1A
        OR A                             ; $9331  B7
        RET Z                            ; $9332  C8
        CP $20                           ; $9333  FE 20
        JP C,SUB_9609                    ; $9335  DA 09 96
        RET Z                            ; $9338  C8
        CP $3D                           ; $9339  FE 3D
        RET Z                            ; $933B  C8
        CP $5F                           ; $933C  FE 5F
        RET Z                            ; $933E  C8
        CP $2E                           ; $933F  FE 2E
        RET Z                            ; $9341  C8
        CP $3A                           ; $9342  FE 3A
        RET Z                            ; $9344  C8
        CP $3B                           ; $9345  FE 3B
        RET Z                            ; $9347  C8
        CP $3C                           ; $9348  FE 3C
        RET Z                            ; $934A  C8
        CP $3E                           ; $934B  FE 3E
        RET Z                            ; $934D  C8
        RET                              ; $934E  C9
L_934F:
        LD A,(DE)                        ; $934F  1A
        OR A                             ; $9350  B7
        RET Z                            ; $9351  C8
        CP $20                           ; $9352  FE 20
        RET NZ                           ; $9354  C0
        INC DE                           ; $9355  13
        JP SUB_964F                      ; $9356  C3 4F 96
        DEFB    $85                                              ; $9359
        DEFB    $6F,$D0,$24,$C9,$3E,$00                          ; $935A  "oP$I>"
L_9360:
        LD HL,$9BCD                      ; $9360  21 CD 9B
        CALL SUB_9659                    ; $9363  CD 59 96
        PUSH HL                          ; $9366  E5
        PUSH HL                          ; $9367  E5
        XOR A                            ; $9368  AF
        LD ($9BF0),A                     ; $9369  32 F0 9B
        LD HL,(L_9488)                   ; $936C  2A 88 94
        EX DE,HL                         ; $936F  EB
        CALL SUB_964F                    ; $9370  CD 4F 96
        EX DE,HL                         ; $9373  EB
        LD (L_948A),HL                   ; $9374  22 8A 94
        EX DE,HL                         ; $9377  EB
        POP HL                           ; $9378  E1
        LD A,(DE)                        ; $9379  1A
        OR A                             ; $937A  B7
        JP Z,SUB_965E_7                  ; $937B  CA 89 96
        SBC A,$40                        ; $937E  DE 40
        LD B,A                           ; $9380  47
        INC DE                           ; $9381  13
        LD A,(DE)                        ; $9382  1A
        CP $3A                           ; $9383  FE 3A
        JP Z,SUB_965E_8+1                ; $9385  CA 90 96
        DEC DE                           ; $9388  1B
        LD A,(SUB_9866_69)               ; $9389  3A EF 9B
        LD (HL),A                        ; $938C  77
        JP SUB_965E_9                    ; $938D  C3 96 96
L_9390:
        LD A,B                           ; $9390  78
        LD ($9BF0),A                     ; $9391  32 F0 9B
        LD (HL),B                        ; $9394  70
        INC DE                           ; $9395  13
        LD B,$08                         ; $9396  06 08
        CALL SUB_9630                    ; $9398  CD 30 96
        JP Z,SUB_965E_16                 ; $939B  CA B9 96
        INC HL                           ; $939E  23
        CP $2A                           ; $939F  FE 2A
        JP NZ,SUB_965E_13+1              ; $93A1  C2 A9 96
        LD (HL),$3F                      ; $93A4  36 3F
        JP SUB_965E_14                   ; $93A6  C3 AB 96
L_93A9:
        LD (HL),A                        ; $93A9  77
        INC DE                           ; $93AA  13
        DEC B                            ; $93AB  05
        JP NZ,SUB_965E_10                ; $93AC  C2 98 96
        CALL SUB_9630                    ; $93AF  CD 30 96
        JP Z,SUB_965E_17                 ; $93B2  CA C0 96
        INC DE                           ; $93B5  13
        JP SUB_965E_15                   ; $93B6  C3 AF 96
L_93B9:
        INC HL                           ; $93B9  23
        LD (HL),$20                      ; $93BA  36 20
        DEC B                            ; $93BC  05
        JP NZ,SUB_965E_16                ; $93BD  C2 B9 96
        LD B,$03                         ; $93C0  06 03
        CP $2E                           ; $93C2  FE 2E
        JP NZ,SUB_965E_23+1              ; $93C4  C2 E9 96
        INC DE                           ; $93C7  13
        CALL SUB_9630                    ; $93C8  CD 30 96
        JP Z,SUB_965E_23+1               ; $93CB  CA E9 96
        INC HL                           ; $93CE  23
        CP $2A                           ; $93CF  FE 2A
        JP NZ,SUB_965E_20                ; $93D1  C2 D9 96
        LD (HL),$3F                      ; $93D4  36 3F
        JP SUB_965E_21                   ; $93D6  C3 DB 96
L_93D9:
        LD (HL),A                        ; $93D9  77
        INC DE                           ; $93DA  13
        DEC B                            ; $93DB  05
        JP NZ,SUB_965E_18+1              ; $93DC  C2 C8 96
        CALL SUB_9630                    ; $93DF  CD 30 96
        JP Z,SUB_965E_24                 ; $93E2  CA F0 96
        INC DE                           ; $93E5  13
        JP SUB_965E_22+1                 ; $93E6  C3 DF 96
L_93E9:
        INC HL                           ; $93E9  23
        LD (HL),$20                      ; $93EA  36 20
        DEC B                            ; $93EC  05
        JP NZ,SUB_965E_23+1              ; $93ED  C2 E9 96
        LD B,$03                         ; $93F0  06 03
        INC HL                           ; $93F2  23
        LD (HL),$00                      ; $93F3  36 00
        DEC B                            ; $93F5  05
        JP NZ,SUB_965E_25                ; $93F6  C2 F2 96
        EX DE,HL                         ; $93F9  EB
        LD (L_9488),HL                   ; $93FA  22 88 94
        POP HL                           ; $93FD  E1
        DEFB    $01,$0B                                          ; $93FE
L_9400:    ; $9400-$9500  embedded 6502 RPC block -- 6502 code (NOT Z-80), run on the
;          ; 6502 via the SoftCard CPU switch. Assembled from CPM_RPC6502.s (ca65,
;          ; authoritative) and INCBIN'd here byte-identical. Its exact source listing
;          ; follows so this file is self-documenting.
;   >>> CPM_RPC6502.s -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>
;
; PRERR           = $FF2D         ; Apple II Monitor: print "ERR" + bell
;
; .org $9400
;
; SECTOR_RW:
;         DEC $04F8                    ; $9400  CE F8 04
;         BNE $93EA                    ; $9403  D0 E5
;         BEQ $93D1                    ; $9405  F0 CA
;         PLA                          ; $9407  68
;         LDA #$40                     ; $9408  A9 40
; SECTOR_RW_1:
;         PLP                          ; $940A  28
;         JMP $0F3E                    ; $940B  4C 3E 0F
; SECTOR_MATCH:
;         BEQ DRIVE_MOTOR_ON           ; $940E  F0 2A
;         LDA $2F                      ; $9410  A5 2F
;         STA $03E3                    ; $9412  8D E3 03
;         LDA $03E2                    ; $9415  AD E2 03
;         BEQ SECTOR_MATCH_1           ; $9418  F0 08
;         CMP $2F                      ; $941A  C5 2F
;         BEQ SECTOR_MATCH_1           ; $941C  F0 04
;         LDA #$20                     ; $941E  A9 20
;         BNE SECTOR_RW_1              ; $9420  D0 E8
; SECTOR_MATCH_1:
;         LDA $03E1                    ; $9422  AD E1 03
;         TAY                          ; $9425  A8
;         LDA $0F9D,Y                  ; $9426  B9 9D 0F
;         CMP $2D                      ; $9429  C5 2D
;         BNE $93CC                    ; $942B  D0 9F
;         PLP                          ; $942D  28
;         BCC DRIVE_MOTOR_ON_2         ; $942E  90 19
;         JSR $0B00                    ; $9430  20 00 0B
;         PHP                          ; $9433  08
;         BCS $93CC                    ; $9434  B0 96
;         PLP                          ; $9436  28
;         JSR $0BC6                    ; $9437  20 C6 0B
; DRIVE_MOTOR_ON:
;         CLC                          ; $943A  18
;         LDA #$00                     ; $943B  A9 00
; DRIVE_MOTOR_ON_1:
;         BIT $38                      ; $943D  24 38
;         STA $03EA                    ; $943F  8D EA 03
;         LDX $05F8                    ; $9442  AE F8 05
;         LDA $C088,X                  ; $9445  BD 88 C0
;         RTS                          ; $9448  60
; DRIVE_MOTOR_ON_2:
;         JSR $0A25                    ; $9449  20 25 0A
;         BCC DRIVE_MOTOR_ON           ; $944C  90 EC
;         LDA #$10                     ; $944E  A9 10
;         BNE DRIVE_MOTOR_ON_1+1       ; $9450  D0 EC
;         ASL                          ; $9452  0A
;         JSR $0F5A                    ; $9453  20 5A 0F
;         LSR $0478                    ; $9456  4E 78 04
;         RTS                          ; $9459  60
; SECTOR_XFER_BYTE:
;         STA $2E                      ; $945A  85 2E
;         JSR $0F7D                    ; $945C  20 7D 0F
;         LDA $0478,Y                  ; $945F  B9 78 04
;         BIT $35                      ; $9462  24 35
;         BMI SECTOR_XFER_BYTE_1       ; $9464  30 03
;         LDA $04F8,Y                  ; $9466  B9 F8 04
; SECTOR_XFER_BYTE_1:
;         STA $0478                    ; $9469  8D 78 04
;         LDA $2E                      ; $946C  A5 2E
;         BIT $35                      ; $946E  24 35
;         BMI SECTOR_XFER_BYTE_2       ; $9470  30 05
;         STA $04F8,Y                  ; $9472  99 F8 04
;         BPL SECTOR_XFER_BYTE_3       ; $9475  10 03
; SECTOR_XFER_BYTE_2:
;         STA $0478,Y                  ; $9477  99 78 04
; SECTOR_XFER_BYTE_3:
;         JMP $0BDE                    ; $947A  4C DE 0B
; SLOT_TO_INDEX:
;         TXA                          ; $947D  8A
;         LSR                          ; $947E  4A
;         LSR                          ; $947F  4A
;         LSR                          ; $9480  4A
;         LSR                          ; $9481  4A
;         TAY                          ; $9482  A8
;         RTS                          ; $9483  60
; SECTOR_MOVE:
;         PHA                          ; $9484  48
;         LDA $03E4                    ; $9485  AD E4 03
;         .byte   $6A, $66, $35, $20                               ; $9488
; SECTOR_MOVE_1:
;         ADC $680F,X                  ; $948C  7D 0F 68
;         ASL                          ; $948F  0A
;         BIT $35                      ; $9490  24 35
; SECTOR_MOVE_2:
;         BMI SECTOR_MOVE_4            ; $9492  30 05
;         STA $04F8,Y                  ; $9494  99 F8 04
; SECTOR_MOVE_3:
;         BPL SECTOR_MOVE_5            ; $9497  10 03
; SECTOR_MOVE_4:
;         STA $0478,Y                  ; $9499  99 78 04
; SECTOR_MOVE_5:
;         RTS                          ; $949C  60
; SECTOR_XLATE_TABLE:
;         .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $949D
; WBOOT_LOAD:
;         .ifdef CFG_56K
;             lda     #>$E400          ; $94AD  warm-boot load buffer hi (56K)
;         .else
;             lda     #>$A400          ; $94AD  warm-boot load buffer hi (44K)
;         .endif
;         STA $03E9                    ; $94AF  8D E9 03
;         LDY #$00                     ; $94B2  A0 00
;         STY $03E8                    ; $94B4  8C E8 03
; WBOOT_LOAD_1:
;         STY $03E0                    ; $94B7  8C E0 03
;         INY                          ; $94BA  C8
; WBOOT_LOAD_2:
;         STY $03E4                    ; $94BB  8C E4 03
;         STY $03EB                    ; $94BE  8C EB 03
;         LDA #$60                     ; $94C1  A9 60
;         STA $03E6                    ; $94C3  8D E6 03
;         LDA #$0B                     ; $94C6  A9 0B
;         STA $03E1                    ; $94C8  8D E1 03
;         LDA #$1C                     ; $94CB  A9 1C
; WBOOT_READ_SECTOR:
;         PHA                          ; $94CD  48
;         PHP                          ; $94CE  08
;         SEI                          ; $94CF  78
; WBOOT_READ_SECTOR_1:
;         JSR $0E10                    ; $94D0  20 10 0E
;         BCC WBOOT_NEXT_SECTOR        ; $94D3  90 08
;         JSR PRERR                    ; $94D5  20 2D FF
;         PLP                          ; $94D8  28
;         PLA                          ; $94D9  68
; WBOOT_ERR_MONITOR:
;         JMP $0FAD                    ; $94DA  4C AD 0F
; WBOOT_NEXT_SECTOR:
;         PLP                          ; $94DD  28
;         INC $03E9                    ; $94DE  EE E9 03
;         LDX $03E1                    ; $94E1  AE E1 03
; WBOOT_NEXT_SECTOR_1:
;         INX                          ; $94E4  E8
;         CPX #$10                     ; $94E5  E0 10
;         BNE WBOOT_NEXT_SECTOR_3      ; $94E7  D0 05
; WBOOT_NEXT_SECTOR_2:
;         LDX #$00                     ; $94E9  A2 00
;         INC $03E0                    ; $94EB  EE E0 03
; WBOOT_NEXT_SECTOR_3:
;         STX $03E1                    ; $94EE  8E E1 03
;         PLA                          ; $94F1  68
;         SEC                          ; $94F2  38
;         SBC #$01                     ; $94F3  E9 01
;         BNE WBOOT_READ_SECTOR        ; $94F5  D0 D6
;         LDA #$08                     ; $94F7  A9 08
;         STA $03E9                    ; $94F9  8D E9 03
;         RTS                          ; $94FC  60
;         .byte   $FF, $FF, $FF, $00                               ; $94FD
;   <<< end listing <<<
        INCBIN  "CPM_RPC6502.bin"
; -- Addresses the Z-80 references inside the 6502 block, as offsets from L_9400
;    (so they relocate with ORG). OPEN: how a Z-80 CALL into $94xx actually
;    reaches/selects the 6502 service is NOT understood -- several of these land
;    mid-6502-instruction or inside the skew table, so they are NOT semantic 6502
;    entry points. Kept verbatim, auto-named, pending that investigation. The
;    6502 CODE itself is named in CPM_RPC6502.s. --
L_9407           EQU L_9400 + $007
L_9408           EQU L_9400 + $008
L_9488           EQU L_9400 + $088
L_948A           EQU L_9400 + $08A
SUB_948C         EQU L_9400 + $08C
SUB_9492         EQU L_9400 + $092
SUB_9498         EQU L_9400 + $098
SUB_94A2         EQU L_9400 + $0A2
SUB_94A7         EQU L_9400 + $0A7
SUB_94B8         EQU L_9400 + $0B8
SUB_94BD         EQU L_9400 + $0BD
SUB_94D0         EQU L_9400 + $0D0
SUB_94DA         EQU L_9400 + $0DA
SUB_94E4         EQU L_9400 + $0E4
SUB_94E9         EQU L_9400 + $0E9
SUB_94EF         EQU L_9400 + $0EF
SUB_94F9         EQU L_9400 + $0F9
SUB_94FE         EQU L_9400 + $0FE
L_94FF           EQU L_9400 + $0FF
SUB_94FE_1:
        INC HL                           ; $9501  23
        LD A,(HL)                        ; $9502  7E
SUB_94FE_2:
        CP $3F                           ; $9503  FE 3F
        JP NZ,SUB_965E_29                ; $9505  C2 09 97
        INC B                            ; $9508  04
SUB_9509:
        DEC C                            ; $9509  0D
        JP NZ,SUB_965E_28                ; $950A  C2 01 97
        LD A,B                           ; $950D  78
SUB_950E:
        OR A                             ; $950E  B7
        RET                              ; $950F  C9
CCP_CMD_NAMES:
        DEFB    "DIR ERA TYPESAVEREN USER"  ; $9510  CCP built-in command name table: DIR ERA TYPE SAVE REN USER (4 bytes each)
SUB_951A_1:
        CP L                             ; $9528  BD
SUB_9529:
        LD D,$00                         ; $9529  16 00
        NOP                              ; $952B  00
        LD D,$DF                         ; $952C  16 DF
        LD HL,$9710                      ; $952E  21 10 97
        LD C,$00                         ; $9531  0E 00
        LD A,C                           ; $9533  79
        CP $06                           ; $9534  FE 06
        RET NC                           ; $9536  D0
SUB_9529_1:
        LD DE,$9BCE                      ; $9537  11 CE 9B
        LD B,$04                         ; $953A  06 04
        LD A,(DE)                        ; $953C  1A
        CP (HL)                          ; $953D  BE
        JP NZ,SUB_972E_6                 ; $953E  C2 4F 97
        INC DE                           ; $9541  13
        INC HL                           ; $9542  23
        DEC B                            ; $9543  05
        JP NZ,SUB_972E_2+1               ; $9544  C2 3C 97
        LD A,(DE)                        ; $9547  1A
        CP $20                           ; $9548  FE 20
        JP NZ,SUB_972E_7                 ; $954A  C2 54 97
        LD A,C                           ; $954D  79
        RET                              ; $954E  C9
SUB_9529_2:
        INC HL                           ; $954F  23
        DEC B                            ; $9550  05
        JP NZ,SUB_972E_6                 ; $9551  C2 4F 97
        INC C                            ; $9554  0C
        JP SUB_972E_1                    ; $9555  C3 33 97
SUB_9529_3:
        XOR A                            ; $9558  AF
        LD (L_9407),A                    ; $9559  32 07 94
        LD SP,$9BAB                      ; $955C  31 AB 9B
        PUSH BC                          ; $955F  C5
        LD A,C                           ; $9560  79
        RRA                              ; $9561  1F
        RRA                              ; $9562  1F
        RRA                              ; $9563  1F
        RRA                              ; $9564  1F
        AND $0F                          ; $9565  E6 0F
        LD E,A                           ; $9567  5F
        CALL $9515                    ; $9568  CD 15 95
        CALL SUB_94B8                    ; $956B  CD B8 94
        LD ($9BAB),A                     ; $956E  32 AB 9B
        POP BC                           ; $9571  C1
        LD A,C                           ; $9572  79
        AND $0F                          ; $9573  E6 0F
        LD (SUB_9866_69),A               ; $9575  32 EF 9B
        CALL SUB_94BD                    ; $9578  CD BD 94
        LD A,(L_9407)                    ; $957B  3A 07 94
        OR A                             ; $957E  B7
        JP NZ,SUB_972E_11                ; $957F  C2 98 97
        LD SP,$9BAB                      ; $9582  31 AB 9B
        CALL SUB_9498                    ; $9585  CD 98 94
        CALL SUB_95D0                    ; $9588  CD D0 95
        ADD A,$41                        ; $958B  C6 41
        CALL SUB_948C                    ; $958D  CD 8C 94
        LD A,$3E                         ; $9590  3E 3E
        CALL SUB_948C                    ; $9592  CD 8C 94
        CALL SUB_9529_1+2                ; $9595  CD 39 95
        LD DE,$0080                      ; $9598  11 80 00
        CALL SUB_95D8                    ; $959B  CD D8 95
        CALL SUB_95D0                    ; $959E  CD D0 95
        LD (SUB_9866_69),A               ; $95A1  32 EF 9B
        CALL SUB_965E                    ; $95A4  CD 5E 96
        CALL NZ,SUB_9609                 ; $95A7  C4 09 96
        LD A,($9BF0)                     ; $95AA  3A F0 9B
SUB_9529_4:
        OR A                             ; $95AD  B7
        JP NZ,SUB_9866_49                ; $95AE  C2 A5 9A
        CALL SUB_972E                    ; $95B1  CD 2E 97
        LD HL,$97C1                      ; $95B4  21 C1 97
        LD E,A                           ; $95B7  5F
        LD D,$00                         ; $95B8  16 00
        ADD HL,DE                        ; $95BA  19
        ADD HL,DE                        ; $95BB  19
        LD A,(HL)                        ; $95BC  7E
        INC HL                           ; $95BD  23
        LD H,(HL)                        ; $95BE  66
        LD L,A                           ; $95BF  6F
        JP (HL)                          ; $95C0  E9
        DEFB    $77                                              ; $95C1
SUB_95C2:
        DEFB    $98,$1F,$99,$5D,$99                              ; $95C2
L_95C7:
        DEFW    $99AD                    ; $95C7
        DEFW    SUB_9866_42              ; $95C9
        DEFW    SUB_9866_48              ; $95CB
        DEFW    SUB_9866_49              ; $95CD
        DEFB    $21                                              ; $95CF
SUB_95D0:
        DEFB    $F3,$76,$22,$00,$94                              ; $95D0
SUB_95D5:
        LD HL,L_9400                     ; $95D5  21 00 94
SUB_95D8:
        JP (HL)                          ; $95D8  E9
SUB_95D8_1:
        LD BC,$97DF                      ; $95D9  01 DF 97
SUB_95D8_2:
        JP SUB_94A7                      ; $95DC  C3 A7 94
MSG_READ_ERROR:
        DEFB    "READ ERROR"  ; $95DF  CP/M error text
        DEFB    $00    ; $95E9  terminator
SUB_95D8_3:
        LD BC,$97F0                      ; $95EA  01 F0 97
        JP SUB_94A7                      ; $95ED  C3 A7 94
MSG_NO_FILE:
        DEFB    "NO FILE"  ; $95F0  CP/M error text
        DEFB    $00    ; $95F7  terminator
SUB_95F5_1:
        CALL SUB_965E                    ; $95F8  CD 5E 96
SUB_95F5_2:
        LD A,($9BF0)                     ; $95FB  3A F0 9B
        OR A                             ; $95FE  B7
        JP NZ,$81AD                      ; $95FF  C2 AD 81
        RET NZ                           ; $9602  C0
        XOR L                            ; $9603  AD
        ADD A,C                          ; $9604  81
        RET NZ                           ; $9605  C0
        JR NZ,SUB_965E_4                 ; $9606  20 7D
        RRCA                             ; $9608  0F
SUB_9609:
        LD C,B                           ; $9609  48
        SBC A,L                          ; $960A  9D
        ADC A,B                          ; $960B  88
        RET NZ                           ; $960C  C0
        XOR C                            ; $960D  A9
        NOP                              ; $960E  00
SUB_9609_1:
        SBC A,C                          ; $960F  99
        LD A,B                           ; $9610  78
        INC B                            ; $9611  04
        SBC A,C                          ; $9612  99
        RET M                            ; $9613  F8
        INC B                            ; $9614  04
        JR NZ,SUB_9630_1                 ; $9615  20 2F
        EI                               ; $9617  FB
        JR NZ,SUB_9529_4                 ; $9618  20 93
        CP $20                           ; $961A  FE 20
SUB_9609_2:
        ADC A,C                          ; $961C  89
SUB_9609_3:
        CP $68                           ; $961D  FE 68
        AND D                            ; $961F  A2
        RST $38                          ; $9620  FF
        SBC A,D                          ; $9621  9A
SUB_9609_4:
        RET                              ; $9622  C9
SUB_9609_5:
        LD B,$F0                         ; $9623  06 F0
        DJNZ L_95C7                      ; $9625  10 A0
        NOP                              ; $9627  00
        CP C                             ; $9628  B9
        LD C,D                           ; $9629  4A
        LD DE,$06F0                      ; $962A  11 F0 06
        JR NZ,SUB_9609_2                 ; $962D  20 ED
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $962F  FD C8
SUB_9630:
        RET Z                            ; $9630  C8
        RET NC                           ; $9631  D0
        PUSH AF                          ; $9632  F5
        LD C,H                           ; $9633  4C
        LD H,L                           ; $9634  65
        RST $38                          ; $9635  FF
        AND B                            ; $9636  A0
        LD C,$B9                         ; $9637  0E B9
        LD L,B                           ; $9639  68
        LD DE,$FF99                      ; $963A  11 99 FF
        RRCA                             ; $963D  0F
        ADC A,B                          ; $963E  88
        RET NC                           ; $963F  D0
        RST $30                          ; $9640  F7
        CP C                             ; $9641  B9
        NOP                              ; $9642  00
        LD (DE),A                        ; $9643  12
        SBC A,C                          ; $9644  99
        NOP                              ; $9645  00
SUB_9630_1:
        LD (BC),A                        ; $9646  02
        ADC A,B                          ; $9647  88
        RET NC                           ; $9648  D0
        RST $30                          ; $9649  F7
        AND B                            ; $964A  A0
        POP AF                           ; $964B  F1
        CP C                             ; $964C  B9
        RST $38                          ; $964D  FF
        LD (DE),A                        ; $964E  12
SUB_964F:
        SBC A,C                          ; $964F  99
        RST $38                          ; $9650  FF
        LD (BC),A                        ; $9651  02
        ADC A,B                          ; $9652  88
        RET NC                           ; $9653  D0
        RST $30                          ; $9654  F7
        ADC A,H                          ; $9655  8C
        CP B                             ; $9656  B8
        INC BC                           ; $9657  03
        ADD A,H                          ; $9658  84
SUB_9659:
        INC A                            ; $9659  3C
        ADC A,B                          ; $965A  88
        ADD A,H                          ; $965B  84
        LD A,$A0                         ; $965C  3E A0
SUB_965E:
        RST $00                          ; $965E  C7
SUB_965E_1:
        JR NZ,$95E1                     ; $965F  20 80
        LD DE,$A5EA                      ; $9661  11 EA A5
        LD A,$F0                         ; $9664  3E F0
        JR SUB_965E_6                    ; $9666  18 20
SUB_965E_2:
        RLA                              ; $9668  17
        LD DE,$4085                      ; $9669  11 85 40
        ADD A,(HL)                       ; $966C  86
        LD B,C                           ; $966D  41
        JR NZ,SUB_965E_5                 ; $966E  20 17
        LD DE,$00E0                      ; $9670  11 E0 00
        RET P                            ; $9673  F0
        LD E,$C5                         ; $9674  1E C5
        LD B,B                           ; $9676  40
        RET NC                           ; $9677  D0
SUB_965E_3:
        LD A,(DE)                        ; $9678  1A
        CALL PO,$F041                    ; $9679  E4 41 F0
        LD A,(DE)                        ; $967C  1A
        RET NC                           ; $967D  D0
        INC D                            ; $967E  14
        AND $3E                          ; $967F  E6 3E
        ADC A,H                          ; $9681  8C
        RET Z                            ; $9682  C8
        INC BC                           ; $9683  03
        XOR C                            ; $9684  A9
SUB_965E_4:
        NOP                              ; $9685  00
        ADC A,L                          ; $9686  8D
SUB_965E_5:
        RST $00                          ; $9687  C7
SUB_965E_6:
        INC BC                           ; $9688  03
SUB_965E_7:
        ADC A,L                          ; $9689  8D
        SBC A,$03                        ; $968A  DE 03
        SBC A,B                          ; $968C  98
        JR SUB_965E_27                   ; $968D  18 69
SUB_965E_8:
        JR NZ,SUB_9609_3+1               ; $968F  20 8D
        RST $18                          ; $9691  DF
        INC BC                           ; $9692  03
        AND D                            ; $9693  A2
        NOP                              ; $9694  00
        RET P                            ; $9695  F0
SUB_965E_9:
        RRA                              ; $9696  1F
        AND D                            ; $9697  A2
SUB_965E_10:
        INC B                            ; $9698  04
        AND B                            ; $9699  A0
        DEC B                            ; $969A  05
        OR C                             ; $969B  B1
        INC A                            ; $969C  3C
        DEFB $DD  ; ignored IX prefix; inner: HALT ; $969D  DD 76
        HALT                             ; $969E  76
SUB_965E_11:
        LD DE,$09D0                      ; $969F  11 D0 09
        AND B                            ; $96A2  A0
SUB_965E_12:
        RLCA                             ; $96A3  07
        OR C                             ; $96A4  B1
        INC A                            ; $96A5  3C
        DEFB $DD  ; ignored IX prefix; inner: LD A,D ; $96A6  DD 7A
        LD A,D                           ; $96A7  7A
SUB_965E_13:
        LD DE,$03F0                      ; $96A8  11 F0 03
SUB_965E_14:
        JP Z,$EBD0                       ; $96AB  CA D0 EB
        RET PE                           ; $96AE  E8
SUB_965E_15:
        RET PO                           ; $96AF  E0
        LD (BC),A                        ; $96B0  02
        RET NC                           ; $96B1  D0
        INC BC                           ; $96B2  03
        XOR $B8                          ; $96B3  EE B8
        INC BC                           ; $96B5  03
        AND H                            ; $96B6  A4
        DEC A                            ; $96B7  3D
        ADC A,D                          ; $96B8  8A
SUB_965E_16:
        SBC A,C                          ; $96B9  99
        RET M                            ; $96BA  F8
        LD (BC),A                        ; $96BB  02
        ADC A,B                          ; $96BC  88
        RET NZ                           ; $96BD  C0
        RET NZ                           ; $96BE  C0
        RET NC                           ; $96BF  D0
SUB_965E_17:
        SBC A,(HL)                       ; $96C0  9E
        LD C,$B8                         ; $96C1  0E B8
        INC BC                           ; $96C3  03
        AND L                            ; $96C4  A5
        LD A,$C9                         ; $96C5  3E C9
SUB_965E_18:
        LD BC,$1DF0                      ; $96C7  01 F0 1D
        ADD A,H                          ; $96CA  84
        DEC A                            ; $96CB  3D
        XOR C                            ; $96CC  A9
SUB_965E_19:
        ADD A,L                          ; $96CD  85
        ADD A,L                          ; $96CE  85
        INC A                            ; $96CF  3C
        ADC A,L                          ; $96D0  8D
        ADD A,L                          ; $96D1  85
        RET NZ                           ; $96D2  C0
        AND L                            ; $96D3  A5
        LD A,$F0                         ; $96D4  3E F0
        DJNZ SUB_965E_3                  ; $96D6  10 A0
        NOP                              ; $96D8  00
SUB_965E_20:
        CP C                             ; $96D9  B9
        DEC HL                           ; $96DA  2B
SUB_965E_21:
        LD DE,$06F0                      ; $96DB  11 F0 06
SUB_965E_22:
        JR NZ,SUB_965E_19                ; $96DE  20 ED
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $96E0  FD C8
        RET Z                            ; $96E1  C8
        RET NC                           ; $96E2  D0
        PUSH AF                          ; $96E3  F5
        LD C,H                           ; $96E4  4C
        LD H,L                           ; $96E5  65
        RST $38                          ; $96E6  FF
        AND B                            ; $96E7  A0
SUB_965E_23:
        DJNZ SUB_965E_12                 ; $96E8  10 B9
        RST $28                          ; $96EA  EF
        INC DE                           ; $96EB  13
        SBC A,C                          ; $96EC  99
        RST $28                          ; $96ED  EF
        INC BC                           ; $96EE  03
        ADC A,B                          ; $96EF  88
SUB_965E_24:
        RET NC                           ; $96F0  D0
        RST $30                          ; $96F1  F7
SUB_965E_25:
        XOR C                            ; $96F2  A9
        JP $008D                         ; $96F3  C3 8D 00
SUB_965E_26:
        DJNZ SUB_965E_11+2               ; $96F6  10 A9
SUB_965E_27:
        NOP                              ; $96F8  00
        ADC A,L                          ; $96F9  8D
        LD BC,L_A910                     ; $96FA  01 10 A9
        XOR D                            ; $96FD  AA
        ADC A,L                          ; $96FE  8D
        LD (BC),A                        ; $96FF  02
        ADD HL,BC                        ; $9700  09
SUB_965E_28:
        SUB (HL)                         ; $9701  96
        LD HL,$9BCE                      ; $9702  21 CE 9B
        LD BC,$000B                      ; $9705  01 0B 00
        LD A,(HL)                        ; $9708  7E
SUB_965E_29:
        CP $20                           ; $9709  FE 20
        JP Z,SUB_97D9_7                  ; $970B  CA 33 98
        INC HL                           ; $970E  23
        SUB $30                          ; $970F  D6 30
        CP $0A                           ; $9711  FE 0A
        JP NC,SUB_9609                   ; $9713  D2 09 96
        LD D,A                           ; $9716  57
        LD A,B                           ; $9717  78
        AND $E0                          ; $9718  E6 E0
        JP NZ,SUB_9609                   ; $971A  C2 09 96
        LD A,B                           ; $971D  78
        RLCA                             ; $971E  07
        RLCA                             ; $971F  07
        RLCA                             ; $9720  07
        ADD A,B                          ; $9721  80
        JP C,SUB_9609                    ; $9722  DA 09 96
        ADD A,B                          ; $9725  80
        JP C,SUB_9609                    ; $9726  DA 09 96
        ADD A,D                          ; $9729  82
        JP C,SUB_9609                    ; $972A  DA 09 96
        LD B,A                           ; $972D  47
SUB_972E:
        DEC C                            ; $972E  0D
        JP NZ,SUB_97D9_3                 ; $972F  C2 08 98
        RET                              ; $9732  C9
SUB_972E_1:
        LD A,(HL)                        ; $9733  7E
        CP $20                           ; $9734  FE 20
        JP NZ,SUB_9609                   ; $9736  C2 09 96
        INC HL                           ; $9739  23
        DEC C                            ; $973A  0D
SUB_972E_2:
        JP NZ,SUB_97D9_7                 ; $973B  C2 33 98
        LD A,B                           ; $973E  78
        RET                              ; $973F  C9
SUB_972E_3:
        LD B,$03                         ; $9740  06 03
        LD A,(HL)                        ; $9742  7E
        LD (DE),A                        ; $9743  12
        INC HL                           ; $9744  23
        INC DE                           ; $9745  13
SUB_972E_4:
        DEC B                            ; $9746  05
        JP NZ,SUB_9842                   ; $9747  C2 42 98
        RET                              ; $974A  C9
SUB_972E_5:
        LD HL,$0080                      ; $974B  21 80 00
        ADD A,C                          ; $974E  81
SUB_972E_6:
        CALL SUB_9659                    ; $974F  CD 59 96
        LD A,(HL)                        ; $9752  7E
        RET                              ; $9753  C9
SUB_972E_7:
        XOR A                            ; $9754  AF
        LD ($9BCD),A                     ; $9755  32 CD 9B
        LD A,($9BF0)                     ; $9758  3A F0 9B
        OR A                             ; $975B  B7
        RET Z                            ; $975C  C8
        DEC A                            ; $975D  3D
        LD HL,SUB_9866_69                ; $975E  21 EF 9B
        CP (HL)                          ; $9761  BE
        RET Z                            ; $9762  C8
        JP SUB_94BD                      ; $9763  C3 BD 94
SUB_972E_8:
        LD A,($9BF0)                     ; $9766  3A F0 9B
        OR A                             ; $9769  B7
        RET Z                            ; $976A  C8
        DEC A                            ; $976B  3D
        LD HL,SUB_9866_69                ; $976C  21 EF 9B
        CP (HL)                          ; $976F  BE
        RET Z                            ; $9770  C8
        LD A,(SUB_9866_69)               ; $9771  3A EF 9B
        JP SUB_94BD                      ; $9774  C3 BD 94
SUB_972E_9:
        CALL SUB_965E                    ; $9777  CD 5E 96
        CALL $9854                    ; $977A  CD 54 98
        LD HL,$9BCE                      ; $977D  21 CE 9B
        LD A,(HL)                        ; $9780  7E
SUB_972E_10:
        CP $20                           ; $9781  FE 20
        JP NZ,$988F                      ; $9783  C2 8F 98
        LD B,$0B                         ; $9786  06 0B
        LD (HL),$3F                      ; $9788  36 3F
        INC HL                           ; $978A  23
        DEC B                            ; $978B  05
        JP NZ,SUB_9866_1                 ; $978C  C2 88 98
        LD E,$00                         ; $978F  1E 00
        PUSH DE                          ; $9791  D5
        CALL SUB_94E9                    ; $9792  CD E9 94
        CALL Z,SUB_97D9_1+2              ; $9795  CC EA 97
SUB_972E_11:
        JP Z,SUB_9866_15                 ; $9798  CA 1B 99
        LD A,($9BEE)                     ; $979B  3A EE 9B
        RRCA                             ; $979E  0F
        RRCA                             ; $979F  0F
        RRCA                             ; $97A0  0F
        AND $60                          ; $97A1  E6 60
        LD C,A                           ; $97A3  4F
        LD A,$0A                         ; $97A4  3E 0A
        CALL SUB_984B                    ; $97A6  CD 4B 98
        RLA                              ; $97A9  17
        JP C,SUB_9866_14                 ; $97AA  DA 0F 99
        POP DE                           ; $97AD  D1
        LD A,E                           ; $97AE  7B
        INC E                            ; $97AF  1C
        PUSH DE                          ; $97B0  D5
        AND $01                          ; $97B1  E6 01
        PUSH AF                          ; $97B3  F5
        JP NZ,SUB_9866_5                 ; $97B4  C2 CC 98
        CALL SUB_9498                    ; $97B7  CD 98 94
        PUSH BC                          ; $97BA  C5
        CALL SUB_95D0                    ; $97BB  CD D0 95
        POP BC                           ; $97BE  C1
        ADD A,$41                        ; $97BF  C6 41
        CALL SUB_9492                    ; $97C1  CD 92 94
        LD A,$3A                         ; $97C4  3E 3A
        CALL SUB_9492                    ; $97C6  CD 92 94
        JP SUB_9866_6                    ; $97C9  C3 D4 98
SUB_972E_12:
        CALL SUB_94A2                    ; $97CC  CD A2 94
        LD A,$3A                         ; $97CF  3E 3A
        CALL SUB_9492                    ; $97D1  CD 92 94
        CALL SUB_94A2                    ; $97D4  CD A2 94
        LD B,$01                         ; $97D7  06 01
SUB_97D9:
        LD A,B                           ; $97D9  78
        CALL SUB_984B                    ; $97DA  CD 4B 98
        AND $7F                          ; $97DD  E6 7F
        CP $20                           ; $97DF  FE 20
        JP NZ,SUB_9866_10+1              ; $97E1  C2 F9 98
        POP AF                           ; $97E4  F1
        PUSH AF                          ; $97E5  F5
        CP $03                           ; $97E6  FE 03
SUB_97D9_1:
        JP NZ,SUB_9866_9                 ; $97E8  C2 F7 98
        LD A,$09                         ; $97EB  3E 09
        CALL SUB_984B                    ; $97ED  CD 4B 98
        AND $7F                          ; $97F0  E6 7F
        CP $20                           ; $97F2  FE 20
        JP Z,SUB_9866_13+2               ; $97F4  CA 0E 99
SUB_97D9_2:
        LD A,$20                         ; $97F7  3E 20
        CALL SUB_9492                    ; $97F9  CD 92 94
        INC B                            ; $97FC  04
        LD A,B                           ; $97FD  78
        CP $0C                           ; $97FE  FE 0C
        JP NC,SUB_9866_13+2              ; $9800  D2 0E 99
        CP $09                           ; $9803  FE 09
        JP NZ,SUB_9866_7                 ; $9805  C2 D9 98
SUB_97D9_3:
        CALL SUB_94A2                    ; $9808  CD A2 94
        JP SUB_9866_7                    ; $980B  C3 D9 98
SUB_97D9_4:
        POP AF                           ; $980E  F1
        CALL SUB_95C2                    ; $980F  CD C2 95
        JP NZ,SUB_9866_15                ; $9812  C2 1B 99
        CALL SUB_94E4                    ; $9815  CD E4 94
        JP SUB_9866_2+1                  ; $9818  C3 98 98
SUB_97D9_5:
        POP DE                           ; $981B  D1
        JP SUB_9866_63+1                 ; $981C  C3 86 9B
SUB_97D9_6:
        CALL SUB_965E                    ; $981F  CD 5E 96
        CP $0B                           ; $9822  FE 0B
        JP NZ,SUB_9866_18                ; $9824  C2 42 99
        LD BC,$9952                      ; $9827  01 52 99
        CALL SUB_94A7                    ; $982A  CD A7 94
        CALL SUB_9529_1+2                ; $982D  CD 39 95
        LD HL,L_9407                     ; $9830  21 07 94
SUB_97D9_7:
        DEC (HL)                         ; $9833  35
        JP NZ,SUB_972E_10+1              ; $9834  C2 82 97
        INC HL                           ; $9837  23
        LD A,(HL)                        ; $9838  7E
        CP $59                           ; $9839  FE 59
        JP NZ,SUB_972E_10+1              ; $983B  C2 82 97
        INC HL                           ; $983E  23
SUB_97D9_8:
        LD (L_9488),HL                   ; $983F  22 88 94
SUB_9842:
        CALL $9854                    ; $9842  CD 54 98
        LD DE,$9BCD                      ; $9845  11 CD 9B
        CALL SUB_94EF                    ; $9848  CD EF 94
SUB_984B:
        INC A                            ; $984B  3C
        CALL Z,SUB_97D9_1+2              ; $984C  CC EA 97
        JP SUB_9866_63+1                 ; $984F  C3 86 9B
MSG_ALL_YN:
        DEFB    "ALL (Y/N)?"  ; $9852  ERA confirm prompt
        DEFB    $00    ; $985C  terminator
SUB_9854_1:
        CALL SUB_965E                    ; $985D  CD 5E 96
        JP NZ,SUB_9609                   ; $9860  C2 09 96
        CALL $9854                    ; $9863  CD 54 98
SUB_9866:
        CALL SUB_94D0                    ; $9866  CD D0 94
        JP Z,SUB_9866_31+2               ; $9869  CA A7 99
        CALL SUB_9498                    ; $986C  CD 98 94
        LD HL,SUB_9866_69+2              ; $986F  21 F1 9B
        LD (HL),$FF                      ; $9872  36 FF
        LD HL,SUB_9866_69+2              ; $9874  21 F1 9B
        LD A,(HL)                        ; $9877  7E
        CP $80                           ; $9878  FE 80
        JP C,SUB_9866_26                 ; $987A  DA 87 99
        PUSH HL                          ; $987D  E5
        CALL SUB_94FE                    ; $987E  CD FE 94
        POP HL                           ; $9881  E1
        JP NZ,SUB_9866_30+2              ; $9882  C2 A0 99
        XOR A                            ; $9885  AF
        LD (HL),A                        ; $9886  77
        INC (HL)                         ; $9887  34
SUB_9866_1:
        LD HL,$0080                      ; $9888  21 80 00
        CALL SUB_9659                    ; $988B  CD 59 96
        LD A,(HL)                        ; $988E  7E
        CP $1A                           ; $988F  FE 1A
        JP Z,SUB_9866_63+1               ; $9891  CA 86 9B
        CALL SUB_948C                    ; $9894  CD 8C 94
SUB_9866_2:
        CALL SUB_95C2                    ; $9897  CD C2 95
        JP NZ,SUB_9866_63+1              ; $989A  C2 86 9B
        JP SUB_9866_23+2                 ; $989D  C3 74 99
SUB_9866_3:
        DEC A                            ; $98A0  3D
        JP Z,SUB_9866_63+1               ; $98A1  CA 86 9B
        CALL SUB_97D9                    ; $98A4  CD D9 97
        CALL SUB_9866                    ; $98A7  CD 66 98
        JP SUB_9609                      ; $98AA  C3 09 96
SUB_9866_4:
        CALL SUB_97D9_2+1                ; $98AD  CD F8 97
        PUSH AF                          ; $98B0  F5
        CALL SUB_965E                    ; $98B1  CD 5E 96
        JP NZ,SUB_9609                   ; $98B4  C2 09 96
        CALL $9854                    ; $98B7  CD 54 98
        LD DE,$9BCD                      ; $98BA  11 CD 9B
        PUSH DE                          ; $98BD  D5
        CALL SUB_94EF                    ; $98BE  CD EF 94
        POP DE                           ; $98C1  D1
        CALL SUB_9509                    ; $98C2  CD 09 95
        JP Z,SUB_9866_39                 ; $98C5  CA FB 99
        XOR A                            ; $98C8  AF
        LD ($9BED),A                     ; $98C9  32 ED 9B
SUB_9866_5:
        POP AF                           ; $98CC  F1
        LD L,A                           ; $98CD  6F
        LD H,$00                         ; $98CE  26 00
        ADD HL,HL                        ; $98D0  29
        LD DE,$0100                      ; $98D1  11 00 01
SUB_9866_6:
        LD A,H                           ; $98D4  7C
        OR L                             ; $98D5  B5
        JP Z,SUB_9866_37+1               ; $98D6  CA F1 99
SUB_9866_7:
        DEC HL                           ; $98D9  2B
        PUSH HL                          ; $98DA  E5
        LD HL,$0080                      ; $98DB  21 80 00
        ADD HL,DE                        ; $98DE  19
        PUSH HL                          ; $98DF  E5
        CALL SUB_95D8                    ; $98E0  CD D8 95
        LD DE,$9BCD                      ; $98E3  11 CD 9B
        CALL SUB_94FE_2+1                ; $98E6  CD 04 95
        POP DE                           ; $98E9  D1
        POP HL                           ; $98EA  E1
        JP NZ,SUB_9866_39                ; $98EB  C2 FB 99
        JP SUB_9866_34                   ; $98EE  C3 D4 99
SUB_9866_8:
        LD DE,$9BCD                      ; $98F1  11 CD 9B
        CALL SUB_94DA                    ; $98F4  CD DA 94
SUB_9866_9:
        INC A                            ; $98F7  3C
SUB_9866_10:
        JP NZ,SUB_9866_41                ; $98F8  C2 01 9A
        LD BC,MSG_NO_SPACE                     ; $98FB  01 07 9A
        CALL $C2A7                       ; $98FE  CD A7 C2
        DEFB $FD  ; ignored IY prefix; inner: AND B ; $9901  FD A0
        AND B                            ; $9902  A0
        RET                              ; $9903  C9
SUB_9866_11:
        INC C                            ; $9904  0C
        DEC C                            ; $9905  0D
        RET Z                            ; $9906  C8
        ADD HL,HL                        ; $9907  29
        JP SUB_A0F7_1+2                  ; $9908  C3 05 A1
SUB_9866_12:
        PUSH BC                          ; $990B  C5
SUB_9866_13:
        LD A,($9F42)                     ; $990C  3A 42 9F
SUB_9866_14:
        LD C,A                           ; $990F  4F
        LD HL,$0001                      ; $9910  21 01 00
        CALL SUB_A0F7_1+1                ; $9913  CD 04 A1
        POP BC                           ; $9916  C1
        LD A,C                           ; $9917  79
        OR L                             ; $9918  B5
        LD L,A                           ; $9919  6F
        LD A,B                           ; $991A  78
SUB_9866_15:
        OR H                             ; $991B  B4
        LD H,A                           ; $991C  67
        RET                              ; $991D  C9
SUB_9866_16:
        LD HL,(L_A9AD)                   ; $991E  2A AD A9
        LD A,($9F42)                     ; $9921  3A 42 9F
        LD C,A                           ; $9924  4F
        CALL SUB_A0EA                    ; $9925  CD EA A0
        LD A,L                           ; $9928  7D
        AND $01                          ; $9929  E6 01
        RET                              ; $992B  C9
SUB_9866_17:
        LD HL,L_A9AD                     ; $992C  21 AD A9
        LD C,(HL)                        ; $992F  4E
        INC HL                           ; $9930  23
        LD B,(HL)                        ; $9931  46
        CALL SUB_A10B                    ; $9932  CD 0B A1
        LD (L_A9AD),HL                   ; $9935  22 AD A9
        LD HL,(L_A9C8)                   ; $9938  2A C8 A9
        INC HL                           ; $993B  23
        EX DE,HL                         ; $993C  EB
        LD HL,(L_A9B3)                   ; $993D  2A B3 A9
        LD (HL),E                        ; $9940  73
        INC HL                           ; $9941  23
SUB_9866_18:
        LD (HL),D                        ; $9942  72
        RET                              ; $9943  C9
SUB_9866_19:
        CALL SUB_A15E                    ; $9944  CD 5E A1
        LD DE,$0009                      ; $9947  11 09 00
        ADD HL,DE                        ; $994A  19
        LD A,(HL)                        ; $994B  7E
        RLA                              ; $994C  17
        RET NC                           ; $994D  D0
        LD HL,$9C0F                      ; $994E  21 0F 9C
        JP SUB_9DA4_37+2                 ; $9951  C3 4A 9F
SUB_9866_20:
        CALL SUB_A10B_1+2                ; $9954  CD 1E A1
        RET Z                            ; $9957  C8
        LD HL,$9C0D                      ; $9958  21 0D 9C
        JP SUB_9DA4_37+2                 ; $995B  C3 4A 9F
SUB_9866_21:
        LD HL,(L_A9B9)                   ; $995E  2A B9 A9
        LD A,(L_A9E9)                    ; $9961  3A E9 A9
        ADD A,L                          ; $9964  85
        LD L,A                           ; $9965  6F
        RET NC                           ; $9966  D0
        INC H                            ; $9967  24
        RET                              ; $9968  C9
SUB_9866_22:
        LD HL,(BDOS_DISPATCH_PTR)        ; $9969  2A 43 9F
        LD DE,$000E                      ; $996C  11 0E 00
        ADD HL,DE                        ; $996F  19
        LD A,(HL)                        ; $9970  7E
        RET                              ; $9971  C9
SUB_9866_23:
        CALL SUB_A164_1+1                ; $9972  CD 69 A1
        LD (HL),$00                      ; $9975  36 00
        RET                              ; $9977  C9
        DEFB    $CD,$69,$A1,$F6,$80                              ; $9978  "Mi!v"
SUB_9866_24:
        LD (HL),A                        ; $997D  77
        RET                              ; $997E  C9
SUB_9866_25:
        LD HL,(L_A9EA)                   ; $997F  2A EA A9
        EX DE,HL                         ; $9982  EB
        LD HL,(L_A9B3)                   ; $9983  2A B3 A9
        LD A,E                           ; $9986  7B
SUB_9866_26:
        SUB (HL)                         ; $9987  96
        INC HL                           ; $9988  23
        LD A,D                           ; $9989  7A
        SBC A,(HL)                       ; $998A  9E
        RET                              ; $998B  C9
SUB_9866_27:
        CALL SUB_A178_1+2                ; $998C  CD 7F A1
        RET C                            ; $998F  D8
        INC DE                           ; $9990  13
        LD (HL),D                        ; $9991  72
        DEC HL                           ; $9992  2B
        LD (HL),E                        ; $9993  73
        RET                              ; $9994  C9
SUB_9866_28:
        LD A,E                           ; $9995  7B
        SUB L                            ; $9996  95
        LD L,A                           ; $9997  6F
        LD A,D                           ; $9998  7A
        SBC A,H                          ; $9999  9C
        LD H,A                           ; $999A  67
        RET                              ; $999B  C9
SUB_9866_29:
        LD C,$FF                         ; $999C  0E FF
SUB_9866_30:
        LD HL,(L_A9EC)                   ; $999E  2A EC A9
        EX DE,HL                         ; $99A1  EB
        LD HL,(L_A9CC)                   ; $99A2  2A CC A9
SUB_9866_31:
        CALL SUB_A178_4+2                ; $99A5  CD 95 A1
        RET NC                           ; $99A8  D0
        PUSH BC                          ; $99A9  C5
        CALL SUB_A0F7                    ; $99AA  CD F7 A0
        LD HL,(L_A9BD)                   ; $99AD  2A BD A9
        EX DE,HL                         ; $99B0  EB
        LD HL,(L_A9EC)                   ; $99B1  2A EC A9
        ADD HL,DE                        ; $99B4  19
        POP BC                           ; $99B5  C1
        INC C                            ; $99B6  0C
        JP Z,SUB_A19C_5+1                ; $99B7  CA C4 A1
        CP (HL)                          ; $99BA  BE
        RET Z                            ; $99BB  C8
        CALL SUB_A178_1+2                ; $99BC  CD 7F A1
        RET NC                           ; $99BF  D0
        CALL SUB_A10B_4+1                ; $99C0  CD 2C A1
        RET                              ; $99C3  C9
SUB_9866_32:
        LD (HL),A                        ; $99C4  77
        RET                              ; $99C5  C9
SUB_9866_33:
        CALL SUB_A19C                    ; $99C6  CD 9C A1
        CALL SUB_A1C6_3+1                ; $99C9  CD E0 A1
        LD C,$01                         ; $99CC  0E 01
        CALL SUB_9FB8                    ; $99CE  CD B8 9F
        JP SUB_A1C6_2+2                  ; $99D1  C3 DA A1
SUB_9866_34:
        CALL SUB_A1C6_3+1                ; $99D4  CD E0 A1
        CALL SUB_9FA1_2+2                ; $99D7  CD B2 9F
        LD HL,L_A9B1                     ; $99DA  21 B1 A9
        JP SUB_A1C6_4                    ; $99DD  C3 E3 A1
SUB_9866_35:
        LD HL,L_A9B9                     ; $99E0  21 B9 A9
        LD C,(HL)                        ; $99E3  4E
        INC HL                           ; $99E4  23
        LD B,(HL)                        ; $99E5  46
        JP $AA24                         ; $99E6  C3 24 AA
SUB_9866_36:
        LD HL,(L_A9B9)                   ; $99E9  2A B9 A9
        EX DE,HL                         ; $99EC  EB
        LD HL,(L_A9B1)                   ; $99ED  2A B1 A9
SUB_9866_37:
        LD C,$80                         ; $99F0  0E 80
        JP SUB_9DA4_38+1                 ; $99F2  C3 4F 9F
SUB_9866_38:
        LD HL,L_A9EA                     ; $99F5  21 EA A9
        LD A,(HL)                        ; $99F8  7E
        INC HL                           ; $99F9  23
        CP (HL)                          ; $99FA  BE
SUB_9866_39:
        RET NZ                           ; $99FB  C0
        INC A                            ; $99FC  3C
        RET                              ; $99FD  C9
SUB_9866_40:
        LD HL,L_94FF                     ; $99FE  21 FF 94
SUB_9866_41:
        CALL SUB_95D5                    ; $9A01  CD D5 95
        JP SUB_9866_63+1                 ; $9A04  C3 86 9B
MSG_NO_SPACE:
        DEFB    "NO SPACE"  ; $9A07  CP/M error text
        DEFB    $00    ; $9A0F  terminator
SUB_9866_42:
        CALL SUB_965E                    ; $9A10  CD 5E 96
        JP NZ,SUB_9609                   ; $9A13  C2 09 96
        LD A,($9BF0)                     ; $9A16  3A F0 9B
        PUSH AF                          ; $9A19  F5
        CALL $9854                    ; $9A1A  CD 54 98
        CALL SUB_94E9                    ; $9A1D  CD E9 94
        JP NZ,SUB_9866_47                ; $9A20  C2 79 9A
        LD HL,$9BCD                      ; $9A23  21 CD 9B
        LD DE,SUB_9866_68+2              ; $9A26  11 DD 9B
        LD B,$10                         ; $9A29  06 10
        CALL SUB_9842                    ; $9A2B  CD 42 98
        LD HL,(L_9488)                   ; $9A2E  2A 88 94
        EX DE,HL                         ; $9A31  EB
        CALL SUB_964F                    ; $9A32  CD 4F 96
        CP $3D                           ; $9A35  FE 3D
        JP Z,SUB_9866_43                 ; $9A37  CA 3F 9A
        CP $5F                           ; $9A3A  FE 5F
        JP NZ,SUB_9866_46                ; $9A3C  C2 73 9A
SUB_9866_43:
        EX DE,HL                         ; $9A3F  EB
        INC HL                           ; $9A40  23
        LD (L_9488),HL                   ; $9A41  22 88 94
        CALL SUB_965E                    ; $9A44  CD 5E 96
        JP NZ,SUB_9866_46                ; $9A47  C2 73 9A
        POP AF                           ; $9A4A  F1
        LD B,A                           ; $9A4B  47
        LD HL,$9BF0                      ; $9A4C  21 F0 9B
        LD A,(HL)                        ; $9A4F  7E
        OR A                             ; $9A50  B7
        JP Z,SUB_9866_44                 ; $9A51  CA 59 9A
        CP B                             ; $9A54  B8
        LD (HL),B                        ; $9A55  70
        JP NZ,SUB_9866_46                ; $9A56  C2 73 9A
SUB_9866_44:
        LD (HL),B                        ; $9A59  70
        XOR A                            ; $9A5A  AF
        LD ($9BCD),A                     ; $9A5B  32 CD 9B
        CALL SUB_94E9                    ; $9A5E  CD E9 94
        JP Z,SUB_9866_45                 ; $9A61  CA 6D 9A
        LD DE,$9BCD                      ; $9A64  11 CD 9B
        CALL SUB_950E                    ; $9A67  CD 0E 95
        JP SUB_9866_63+1                 ; $9A6A  C3 86 9B
SUB_9866_45:
        CALL SUB_97D9_1+2                ; $9A6D  CD EA 97
        JP SUB_9866_63+1                 ; $9A70  C3 86 9B
SUB_9866_46:
        CALL SUB_9866                    ; $9A73  CD 66 98
        JP SUB_9609                      ; $9A76  C3 09 96
SUB_9866_47:
        LD BC,MSG_FILE_EXISTS                     ; $9A79  01 82 9A
        CALL SUB_94A7                    ; $9A7C  CD A7 94
        JP SUB_9866_63+1                 ; $9A7F  C3 86 9B
MSG_FILE_EXISTS:
        DEFB    "FILE EXISTS"  ; $9A82  CP/M error text
        DEFB    $00    ; $9A8D  terminator
SUB_9866_48:
        CALL SUB_97D9_2+1                ; $9A8E  CD F8 97
        CP $10                           ; $9A91  FE 10
        JP NC,SUB_9609                   ; $9A93  D2 09 96
        LD E,A                           ; $9A96  5F
        LD A,($9BCE)                     ; $9A97  3A CE 9B
        CP $20                           ; $9A9A  FE 20
        JP Z,SUB_9609                    ; $9A9C  CA 09 96
        CALL $9515                    ; $9A9F  CD 15 95
        JP SUB_9866_64                   ; $9AA2  C3 89 9B
SUB_9866_49:
        CALL $95F5                    ; $9AA5  CD F5 95
        LD A,($9BCE)                     ; $9AA8  3A CE 9B
        CP $20                           ; $9AAB  FE 20
        JP NZ,SUB_9866_50                ; $9AAD  C2 C4 9A
        LD A,($9BF0)                     ; $9AB0  3A F0 9B
        OR A                             ; $9AB3  B7
        JP Z,SUB_9866_64                 ; $9AB4  CA 89 9B
        DEC A                            ; $9AB7  3D
        LD (SUB_9866_69),A               ; $9AB8  32 EF 9B
        CALL SUB_9529                    ; $9ABB  CD 29 95
        CALL SUB_94BD                    ; $9ABE  CD BD 94
        JP SUB_9866_64                   ; $9AC1  C3 89 9B
SUB_9866_50:
        LD DE,SUB_9866_67+2              ; $9AC4  11 D6 9B
        LD A,(DE)                        ; $9AC7  1A
        CP $20                           ; $9AC8  FE 20
        JP NZ,SUB_9609                   ; $9ACA  C2 09 96
        PUSH DE                          ; $9ACD  D5
        CALL $9854                    ; $9ACE  CD 54 98
        POP DE                           ; $9AD1  D1
SUB_9866_51:
        LD HL,$9B83                      ; $9AD2  21 83 9B
        CALL SUB_97D9_8+1                ; $9AD5  CD 40 98
        CALL SUB_94D0                    ; $9AD8  CD D0 94
        JP Z,SUB_9866_61                 ; $9ADB  CA 6B 9B
        LD HL,$0100                      ; $9ADE  21 00 01
        PUSH HL                          ; $9AE1  E5
        EX DE,HL                         ; $9AE2  EB
        CALL SUB_95D8                    ; $9AE3  CD D8 95
        LD DE,$9BCD                      ; $9AE6  11 CD 9B
        CALL SUB_94F9                    ; $9AE9  CD F9 94
        JP NZ,SUB_9866_52                ; $9AEC  C2 01 9B
        POP HL                           ; $9AEF  E1
        LD DE,$0080                      ; $9AF0  11 80 00
        ADD HL,DE                        ; $9AF3  19
        LD DE,L_9400                     ; $9AF4  11 00 94
        LD A,L                           ; $9AF7  7D
        SUB E                            ; $9AF8  93
        LD A,H                           ; $9AF9  7C
        SBC A,D                          ; $9AFA  9A
        JP NC,SUB_9866_62                ; $9AFB  D2 71 9B
        JP $FFE1                         ; $9AFE  C3 E1 FF
SUB_9866_52:
        LD (L_A9EA),HL                   ; $9B01  22 EA A9
        RET                              ; $9B04  C9
SUB_9866_53:
        LD HL,(L_A9C8)                   ; $9B05  2A C8 A9
        EX DE,HL                         ; $9B08  EB
        LD HL,(L_A9EA)                   ; $9B09  2A EA A9
        INC HL                           ; $9B0C  23
        LD (L_A9EA),HL                   ; $9B0D  22 EA A9
        CALL SUB_A178_4+2                ; $9B10  CD 95 A1
        JP NC,SUB_A1FE_3+1               ; $9B13  D2 19 A2
        JP SUB_A1FE                      ; $9B16  C3 FE A1
SUB_9866_54:
        LD A,(L_A9EA)                    ; $9B19  3A EA A9
        AND $03                          ; $9B1C  E6 03
        LD B,$05                         ; $9B1E  06 05
        ADD A,A                          ; $9B20  87
        DEC B                            ; $9B21  05
        JP NZ,SUB_A1FE_4                 ; $9B22  C2 20 A2
        LD (L_A9E9),A                    ; $9B25  32 E9 A9
        OR A                             ; $9B28  B7
        RET NZ                           ; $9B29  C0
        PUSH BC                          ; $9B2A  C5
        CALL SUB_9FB8_2+1                ; $9B2B  CD C3 9F
SUB_9866_55:
        CALL SUB_A1C6_1+1                ; $9B2E  CD D4 A1
        POP BC                           ; $9B31  C1
        JP SUB_A19C_1+1                  ; $9B32  C3 9E A1
SUB_9866_56:
        LD A,C                           ; $9B35  79
        AND $07                          ; $9B36  E6 07
        INC A                            ; $9B38  3C
        LD E,A                           ; $9B39  5F
        LD D,A                           ; $9B3A  57
        LD A,C                           ; $9B3B  79
        RRCA                             ; $9B3C  0F
        RRCA                             ; $9B3D  0F
SUB_9866_57:
        RRCA                             ; $9B3E  0F
        AND $1F                          ; $9B3F  E6 1F
        LD C,A                           ; $9B41  4F
        LD A,B                           ; $9B42  78
SUB_9866_58:
        ADD A,A                          ; $9B43  87
        ADD A,A                          ; $9B44  87
        ADD A,A                          ; $9B45  87
        ADD A,A                          ; $9B46  87
        ADD A,A                          ; $9B47  87
        OR C                             ; $9B48  B1
        LD C,A                           ; $9B49  4F
        LD A,B                           ; $9B4A  78
        RRCA                             ; $9B4B  0F
        RRCA                             ; $9B4C  0F
        RRCA                             ; $9B4D  0F
SUB_9866_59:
        AND $1F                          ; $9B4E  E6 1F
        LD B,A                           ; $9B50  47
        LD HL,(L_A9BF)                   ; $9B51  2A BF A9
        ADD HL,BC                        ; $9B54  09
        LD A,(HL)                        ; $9B55  7E
        RLCA                             ; $9B56  07
        DEC E                            ; $9B57  1D
        JP NZ,SUB_A1FE_8+1               ; $9B58  C2 56 A2
        RET                              ; $9B5B  C9
SUB_9866_60:
        PUSH DE                          ; $9B5C  D5
        CALL SUB_A1FE_6+1                ; $9B5D  CD 35 A2
        AND $FE                          ; $9B60  E6 FE
        POP BC                           ; $9B62  C1
        OR C                             ; $9B63  B1
        RRCA                             ; $9B64  0F
        DEC D                            ; $9B65  15
        JP NZ,SUB_A264                   ; $9B66  C2 64 A2
        LD (HL),A                        ; $9B69  77
        RET                              ; $9B6A  C9
SUB_9866_61:
        CALL SUB_A15E                    ; $9B6B  CD 5E A1
        LD DE,$0010                      ; $9B6E  11 10 00
SUB_9866_62:
        ADD HL,DE                        ; $9B71  19
        PUSH BC                          ; $9B72  C5
        LD C,$11                         ; $9B73  0E 11
        POP DE                           ; $9B75  D1
        DEC C                            ; $9B76  0D
        RET Z                            ; $9B77  C8
        PUSH DE                          ; $9B78  D5
        LD A,(L_A9DD)                    ; $9B79  3A DD A9
        OR A                             ; $9B7C  B7
        JP Z,SUB_A26B_2+1                ; $9B7D  CA 88 A2
        PUSH BC                          ; $9B80  C5
        PUSH HL                          ; $9B81  E5
        LD C,(HL)                        ; $9B82  4E
        LD B,$00                         ; $9B83  06 00
SUB_9866_63:
        JP SUB_A26B_4                    ; $9B85  C3 8E A2
        DEC C                            ; $9B88  0D
SUB_9866_64:
        PUSH BC                          ; $9B89  C5
        LD C,(HL)                        ; $9B8A  4E
        INC HL                           ; $9B8B  23
        LD B,(HL)                        ; $9B8C  46
        PUSH HL                          ; $9B8D  E5
        LD A,C                           ; $9B8E  79
        OR B                             ; $9B8F  B0
        JP Z,SUB_A26B_5+1                ; $9B90  CA 9D A2
        LD HL,(L_A9C6)                   ; $9B93  2A C6 A9
        LD A,L                           ; $9B96  7D
        SUB C                            ; $9B97  91
        LD A,H                           ; $9B98  7C
        SBC A,B                          ; $9B99  98
        CALL NC,SUB_A25C                 ; $9B9A  D4 5C A2
        POP HL                           ; $9B9D  E1
        INC HL                           ; $9B9E  23
        POP BC                           ; $9B9F  C1
        JP SUB_A26B_1                    ; $9BA0  C3 75 A2
SUB_9866_65:
        LD HL,(L_A9C6)                   ; $9BA3  2A C6 A9
        LD C,$03                         ; $9BA6  0E 03
        CALL SUB_A0EA                    ; $9BA8  CD EA A0
        INC HL                           ; $9BAB  23
        LD B,H                           ; $9BAC  44
        LD C,L                           ; $9BAD  4D
        LD HL,(L_A9BF)                   ; $9BAE  2A BF A9
        LD (HL),$00                      ; $9BB1  36 00
SUB_9866_66:
        INC HL                           ; $9BB3  23
        DEC BC                           ; $9BB4  0B
        LD A,B                           ; $9BB5  78
        OR C                             ; $9BB6  B1
        JP NZ,SUB_A26B_8                 ; $9BB7  C2 B1 A2
        LD HL,(L_A9CA)                   ; $9BBA  2A CA A9
        EX DE,HL                         ; $9BBD  EB
        LD HL,(L_A9BF)                   ; $9BBE  2A BF A9
        LD (HL),E                        ; $9BC1  73
        INC HL                           ; $9BC2  23
        LD (HL),D                        ; $9BC3  72
        CALL SUB_9FA1                    ; $9BC4  CD A1 9F
        LD HL,(L_A9B3)                   ; $9BC7  2A B3 A9
        LD (HL),$03                      ; $9BCA  36 03
        INC HL                           ; $9BCC  23
        LD (HL),$00                      ; $9BCD  36 00
        CALL SUB_A1FE                    ; $9BCF  CD FE A1
        LD C,$FF                         ; $9BD2  0E FF
SUB_9866_67:
        CALL SUB_A1FE_1+1                ; $9BD4  CD 05 A2
        CALL SUB_A1F5                    ; $9BD7  CD F5 A1
        RET Z                            ; $9BDA  C8
SUB_9866_68:
        CALL SUB_A15E                    ; $9BDB  CD 5E A1
        LD A,$E5                         ; $9BDE  3E E5
        CP (HL)                          ; $9BE0  BE
        JP Z,SUB_A26B_11+1               ; $9BE1  CA D2 A2
        LD A,($9F41)                     ; $9BE4  3A 41 9F
        CP (HL)                          ; $9BE7  BE
        JP NZ,SUB_A26B_15                ; $9BE8  C2 F6 A2
        INC HL                           ; $9BEB  23
        LD A,(HL)                        ; $9BEC  7E
        SUB $24                          ; $9BED  D6 24
SUB_9866_69:
        JP NZ,SUB_A26B_15                ; $9BEF  C2 F6 A2
        DEC A                            ; $9BF2  3D
        LD (SUB_9DA4_35+1),A             ; $9BF3  32 45 9F
        LD C,$01                         ; $9BF6  0E 01
        CALL SUB_A26B                    ; $9BF8  CD 6B A2
        CALL SUB_A178_3+1                ; $9BFB  CD 8C A1
        JP SUB_9866_51                   ; $9BFE  C3 D2 9A

    INCLUDE "CPM_BDOS.asm"   ; BDOS compiles together with the CCP
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9300, $1700
    ENDIF
