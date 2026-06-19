; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- CCP module (+ system-image assembler)
; ----------------------------------------------------------------------------
; The CP/M "system" the boot loader reads off the system tracks is TWO independent
; modules -- the CCP and the BDOS -- each its own source file. This is the CCP
; module. It also assembles the full $8000 LOAD_CPM staging image by INCLUDEing the
; BDOS module (CPM_BDOS.asm) at its staged position, so the two compile as ONE unit
; and reassemble BYTE-IDENTICAL to the on-disk system tracks. (Mirrors the
; CPMV220-44K CPM_CCP.asm + CPM_BDOS.asm split.)
;
; Staging layout (ORG $8000, 5888 bytes; SYS_INIT relocates it at boot):
;   $8000-$8CFF  CCP, staged here but DECODED at its $9300 RUN address via DISP
;                $9300 -- the staged bytes already ARE the $9300 run form (they
;                decode to coherent Z-80 at $9300, garbage at $8000), so SYS_INIT
;                copies them up unchanged; there is no per-byte address fixup and
;                NO relocation bitmap (the whole region is CCP code + data). The
;                lone island of DEFB is the embedded 6502 RPC block at $9401-$94FF
;                (6502 machine code carried inside the Z-80 image; the SoftCard runs
;                it on the 6502 via the CPU switch, so to the Z-80 it is opaque
;                data -- decoding it as Z-80 is garbage). The CCP's command parse,
;                the DIR/ERA/TYPE/SAVE/REN/USER built-in name table ($93C7) and
;                dispatch pointer table ($9570), the transient .COM loader, the
;                $$$.SUB chaining area ($9E31+) and the CP/M error texts all decode
;                as real code/data here. Note the run-address window $9300-$9FFF
;                logically OVERLAPS the BDOS's $9C00 base; that overlap is only
;                label values (the physical bytes differ and the names do not
;                collide), and the CCP's $9C00-$9FFF cold-boot/loader routines run
;                before the BDOS copy-up, so both can name the same addresses.
;   $8D00-$96FF  BDOS, INCLUDEd from CPM_BDOS.asm under DISP $9C00 (its labels are
;                $9C00-based, its bytes land at staging offset $0D00). SYS_INIT, the
;                in-place relocator, lives in the BDOS tail and runs at staging
;                ($9631) before the copy-up to $9C00.
;
; This file DEFINEs CPM_LINK around the INCLUDE so CPM_BDOS.asm emits body-only
; (its own DEVICE/ORG/SAVEBIN are IFNDEF CPM_LINK and run only when it builds
; standalone). The [AI]/[DOC] comment conventions are as in the sibling sources.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ENDIF

; -- Staging-image routines the CCP calls. SYS_INIT is the in-place relocator: its
;    bytes sit in the BDOS-staging tail (INCLUDEd below, decoded there at the BDOS
;    run address), but it EXECUTES here at its staging address before the copy-up, so
;    the CCP references it by staging address. --
SYS_INIT             EQU $9631               ; system init / relocator entry (runs in-place at staging)
SYS_INIT_4           EQU $967B               ; SYS_INIT inner loop ($967B)

; -- Page-zero symbols the CCP references. WBOOT_VEC ($0000), IOBYTE ($0003),
;    RST2_VEC ($0010) and DEFAULT_DMA ($0080) are ALSO defined by CPM_BDOS.asm
;    (INCLUDEd below); since the two compile as one unit those definitions resolve
;    the CCP's references, so they are NOT redefined here (a duplicate EQU is an
;    error). The four below are CCP-only and are defined here. --
BDOS_VEC             EQU $0005               ; BDOS call vector -- JP BDOS_ENTRY. Programs CALL $0005; the word at $0006 doubles as the top-of-TPA marker.
DEFAULT_FCB          EQU $005C               ; Default File Control Block -- the CCP populates it from command-line argument 1 (standard 36-byte FCB).
CMDLINE              EQU $0081               ; Command-line tail characters (uppercase, leading space). Same buffer as DEFAULT_DMA ($0080).
TPA_START            EQU $0100               ; Start of the Transient Program Area; .COM files load and start executing here.

; -- Mid-instruction references (shown inline as cover+offset) --
;   $9307 -> L_9306+1             shared instruction tail: $9307 is reachable code inside the instruction at $9306
;   $9388 -> L_9387+1             shared instruction tail: $9388 is reachable code inside the instruction at $9387
;   $938A -> L_9389+1             shared instruction tail: $938A is reachable code inside the instruction at $9389
;   $9393 -> SUB_9391_1+1         shared instruction tail: $9393 is reachable code inside the instruction at $9392
;   $9399 -> SUB_9391_2+1         shared instruction tail: $9399 is reachable code inside the instruction at $9398
;   $93A2 -> SUB_9391_6+1         shared instruction tail: $93A2 is reachable code inside the instruction at $93A1
;   $93E3 -> SUB_93E0_1+1         z80 skip idiom: enters the operand of $01 at $93E2
;   $93F2 -> SUB_93EE_1+1         shared instruction tail: $93F2 is reachable code inside the instruction at $93F1
;   $93F6 -> SUB_93EE_3+1         shared instruction tail: $93F6 is reachable code inside the instruction at $93F5
;   $952A -> SUB_9521_1+2         shared instruction tail: $952A is reachable code inside the instruction at $9528
;   $95B0 -> SUB_9531_6+2         shared instruction tail: $95B0 is reachable code inside the instruction at $95AE
;   $95C7 -> SUB_9531_8+1         shared instruction tail: $95C7 is reachable code inside the instruction at $95C6
;   $95CA -> SUB_9531_9+2         shared instruction tail: $95CA is reachable code inside the instruction at $95C8
;   $95E5 -> SUB_9531_11+2        shared instruction tail: $95E5 is reachable code inside the instruction at $95E3
;   $9631 -> SUB_9531_17+1        shared instruction tail: $9631 is reachable code inside the instruction at $9630
;   $96FF -> SUB_96F5_1+1         shared instruction tail: $96FF is reachable code inside the instruction at $96FE
;   $9926 -> SUB_9707_33+1        shared instruction tail: $9926 is reachable code inside the instruction at $9925
;   $9993 -> SUB_9707_41+1        shared instruction tail: $9993 is reachable code inside the instruction at $9992
;   $99B8 -> SUB_9707_44+2        z80 skip idiom: enters the operand of $21 at $99B6
;   $9A24 -> SUB_9707_51+1        shared instruction tail: $9A24 is reachable code inside the instruction at $9A23
;   $9A35 -> SUB_9707_54+1        shared instruction tail: $9A35 is reachable code inside the instruction at $9A34
;   $9A3B -> SUB_9707_56+2        shared instruction tail: $9A3B is reachable code inside the instruction at $9A39
;   $9A4D -> SUB_9707_58+1        z80 skip idiom: enters the operand of $11 at $9A4C
;   $9A54 -> SUB_9A50_1+2         shared instruction tail: $9A54 is reachable code inside the instruction at $9A52
;   $9A82 -> SUB_9A50_5+2         shared instruction tail: $9A82 is reachable code inside the instruction at $9A80
;   $9AC8 -> SUB_9A8D_4+2         shared instruction tail: $9AC8 is reachable code inside the instruction at $9AC6
;   $9B26 -> SUB_9B06_4+1         shared instruction tail: $9B26 is reachable code inside the instruction at $9B25
;   $9BA6 -> SUB_9B06_26+1        shared instruction tail: $9BA6 is reachable code inside the instruction at $9BA5
;   $9BA7 -> SUB_9B06_26+2        shared instruction tail: $9BA7 is reachable code inside the instruction at $9BA5
;   $9C0D -> SUB_9B06_37+1        shared instruction tail: $9C0D is reachable code inside the instruction at $9C0C
;   $9F41 -> SUB_9B06_72+2        shared instruction tail: $9F41 is reachable code inside the instruction at $9F3F
;   $9F45 -> SUB_9B06_74+2        shared instruction tail: $9F45 is reachable code inside the instruction at $9F43
;   $9F4F -> SUB_9B06_76+2        shared instruction tail: $9F4F is reachable code inside the instruction at $9F4D
;   $9FC3 -> SUB_9FB8_2+1         shared instruction tail: $9FC3 is reachable code inside the instruction at $9FC2
;   $9FFA -> SUB_9FB8_5+1         z80 skip idiom: enters the operand of $21 at $9FF9

    ORG $8000
    DISP $9300

; [AI] ORG $8000 entry point of the loaded system image; decoded at its $9300 RUN
;       address via DISP. The first instruction is JP SYS_INIT ($9631); the bytes that
;       follow are the CCP's $9300 run-form code and data. The image carries the CCP +
;       BDOS plus the page-zero template the system installs (warm-boot JMP at $0000,
;       BDOS entry vector at $0005, default FCB at $005C, default DMA / command-tail
;       buffer at $0080). [DOC CPMREF 3-44] $0005 holds a JMP to FBASE (the BDOS) and the
;       word at $0006 doubles as the top-of-TPA / start-of-FDOS pointer; OS calls pass the
;       function number in C and the info address in DE through $0005.

L_9300:
        JP SYS_INIT                      ; $9300  C3 31 96  at load (image@$8000) -> the SYS_INIT
                                         ;   relocator at $9631; post-relocation $9631 is a CCP
                                         ;   routine (SUB_9531_17+1), the target of the CCP's own
                                         ;   JP $9631 sites -- both resolve to $9631, byte-identical
L_9303:
        LD A,(DE)                        ; $9303  1A
        OR A                             ; $9304  B7
        RET Z                            ; $9305  C8
L_9306:
        CP $20                           ; $9306  FE 20
L_9308:
        JR C,$92DF                       ; $9308  38 D5
        RET Z                            ; $930A  C8
        CP $3D                           ; $930B  FE 3D
        RET Z                            ; $930D  C8
        CP $5F                           ; $930E  FE 5F
        RET Z                            ; $9310  C8
        CP $2E                           ; $9311  FE 2E
        RET Z                            ; $9313  C8
        CP $3A                           ; $9314  FE 3A
        RET Z                            ; $9316  C8
        CP $3B                           ; $9317  FE 3B
        RET Z                            ; $9319  C8
        CP $3C                           ; $931A  FE 3C
        RET Z                            ; $931C  C8
        CP $3E                           ; $931D  FE 3E
        RET Z                            ; $931F  C8
        RET                              ; $9320  C9
L_9321:
        LD A,(DE)                        ; $9321  1A
        OR A                             ; $9322  B7
        RET Z                            ; $9323  C8
        CP $20                           ; $9324  FE 20
        RET NZ                           ; $9326  C0
        INC DE                           ; $9327  13
        JR L_9321                        ; $9328  18 F7
L_932A:
        ADD A,L                          ; $932A  85
        LD L,A                           ; $932B  6F
        RET NC                           ; $932C  D0
        INC H                            ; $932D  24
        RET                              ; $932E  C9
L_932F:
        LD A,$00                         ; $932F  3E 00
        LD HL,SUB_9B06_18                ; $9331  21 86 9B
        CALL SUB_9521_1+2                ; $9334  CD 2A 95
        PUSH HL                          ; $9337  E5
        PUSH HL                          ; $9338  E5
        XOR A                            ; $9339  AF
        LD (SUB_9B06_28),A               ; $933A  32 A9 9B
        LD HL,(L_9387+1)                 ; $933D  2A 88 93
        EX DE,HL                         ; $9340  EB
        CALL SUB_9521                    ; $9341  CD 21 95
        EX DE,HL                         ; $9344  EB
        LD (L_9389+1),HL                 ; $9345  22 8A 93
        EX DE,HL                         ; $9348  EB
        POP HL                           ; $9349  E1
        LD A,(DE)                        ; $934A  1A
        OR A                             ; $934B  B7
        JR Z,L_9358                      ; $934C  28 0A
        SBC A,$40                        ; $934E  DE 40
        LD B,A                           ; $9350  47
        INC DE                           ; $9351  13
        LD A,(DE)                        ; $9352  1A
        CP $3A                           ; $9353  FE 3A
        JR Z,L_935E                      ; $9355  28 07
        DEC DE                           ; $9357  1B
L_9358:
        LD A,(SUB_9B06_27)               ; $9358  3A A8 9B
        LD (HL),A                        ; $935B  77
        JR L_9364                        ; $935C  18 06
L_935E:
        LD A,B                           ; $935E  78
        LD (SUB_9B06_28),A               ; $935F  32 A9 9B
        LD (HL),B                        ; $9362  70
        INC DE                           ; $9363  13
L_9364:
        LD B,$08                         ; $9364  06 08
L_9366:
        CALL SUB_9503                    ; $9366  CD 03 95
        JR Z,L_9380                      ; $9369  28 15
        INC HL                           ; $936B  23
        CP $2A                           ; $936C  FE 2A
        JR NZ,L_9374                     ; $936E  20 04
        LD (HL),$3F                      ; $9370  36 3F
        JR L_9376                        ; $9372  18 02
L_9374:
        LD (HL),A                        ; $9374  77
        INC DE                           ; $9375  13
L_9376:
        DJNZ L_9366                      ; $9376  10 EE
L_9378:
        CALL SUB_9503                    ; $9378  CD 03 95
        JR Z,L_9385                      ; $937B  28 08
        INC DE                           ; $937D  13
        JR L_9378                        ; $937E  18 F8
L_9380:
        INC HL                           ; $9380  23
        LD (HL),$20                      ; $9381  36 20
        DJNZ L_9380                      ; $9383  10 FB
L_9385:
        LD B,$03                         ; $9385  06 03
L_9387:
        CP $2E                           ; $9387  FE 2E
L_9389:
        JR NZ,SUB_9391_7                 ; $9389  20 1B
        INC DE                           ; $938B  13
SUB_938C:
        CALL SUB_9503                    ; $938C  CD 03 95
        JR Z,SUB_9391_7                  ; $938F  28 15
SUB_9391:
        INC HL                           ; $9391  23
SUB_9391_1:
        CP $2A                           ; $9392  FE 2A
        JR NZ,SUB_9391_3                 ; $9394  20 04
        LD (HL),$3F                      ; $9396  36 3F
SUB_9391_2:
        JR SUB_9391_4                    ; $9398  18 02
SUB_9391_3:
        LD (HL),A                        ; $939A  77
        INC DE                           ; $939B  13
SUB_9391_4:
        DJNZ SUB_938C                    ; $939C  10 EE
SUB_9391_5:
        CALL SUB_9503                    ; $939E  CD 03 95
SUB_9391_6:
        JR Z,SUB_9391_8                  ; $93A1  28 08
        INC DE                           ; $93A3  13
        JR SUB_9391_5                    ; $93A4  18 F8
SUB_9391_7:
        INC HL                           ; $93A6  23
        LD (HL),$20                      ; $93A7  36 20
        DJNZ SUB_9391_7                  ; $93A9  10 FB
SUB_9391_8:
        LD B,$03                         ; $93AB  06 03
SUB_9391_9:
        INC HL                           ; $93AD  23
        LD (HL),$00                      ; $93AE  36 00
        DJNZ SUB_9391_9                  ; $93B0  10 FB
SUB_93B2:
        EX DE,HL                         ; $93B2  EB
        LD (L_9387+1),HL                 ; $93B3  22 88 93
SUB_93B6:
        POP HL                           ; $93B6  E1
        LD BC,$000B                      ; $93B7  01 0B 00
SUB_93B6_1:
        INC HL                           ; $93BA  23
        LD A,(HL)                        ; $93BB  7E
SUB_93BC:
        CP $3F                           ; $93BC  FE 3F
        JR NZ,SUB_93BC_1                 ; $93BE  20 01
        INC B                            ; $93C0  04
SUB_93BC_1:
        DEC C                            ; $93C1  0D
        JR NZ,SUB_93B6_1                 ; $93C2  20 F6
        LD A,B                           ; $93C4  78
        OR A                             ; $93C5  B7
SUB_93C6:
        RET                              ; $93C6  C9
        DEFB    $44,$49,$52,$20,$45,$52,$41,$20,$54,$59          ; $93C7
SUB_93D1:
        DEFB    "PESAVER"    ; $93D1  string
SUB_93D8:
        DEFB    $45,$4E,$20,$55                                  ; $93D8
SUB_93DC:
        DEFB    $53,$45,$52                                      ; $93DC
SUB_93DC_1:
        CP L                             ; $93DF  BD
SUB_93E0:
        LD D,$00                         ; $93E0  16 00
SUB_93E0_1:
        LD BC,$404D                      ; $93E2  01 4D 40
        LD HL,SUB_9531_8+1               ; $93E5  21 C7 95
        LD C,$00                         ; $93E8  0E 00
SUB_93EA:
        LD A,C                           ; $93EA  79
        CP $06                           ; $93EB  FE 06
        RET NC                           ; $93ED  D0
SUB_93EE:
        LD DE,SUB_9B06_19                ; $93EE  11 87 9B
SUB_93EE_1:
        LD B,$04                         ; $93F1  06 04
SUB_93EE_2:
        LD A,(DE)                        ; $93F3  1A
        CP (HL)                          ; $93F4  BE
SUB_93EE_3:
        JR NZ,L_9402                     ; $93F5  20 0B
        INC DE                           ; $93F7  13
SUB_93F8:
        INC HL                           ; $93F8  23
        DJNZ SUB_93EE_2                  ; $93F9  10 F8
        LD A,(DE)                        ; $93FB  1A
SUB_93FC:
        CP $20                           ; $93FC  FE 20
        JR NZ,L_9405                     ; $93FE  20 05
        LD L,B                           ; $9400  68
; [AI] -- Embedded 6502 RPC block ($9401-$94FF). 6502 machine code (NOT Z-80) carried
;        inside the Z-80 system image; the SoftCard runs it on the 6502 side via the
;        CPU-switch RPC, so from the Z-80's view it is opaque DATA (decoding it as Z-80
;        is garbage) and it is kept as DEFB. It is the warm-boot / RWTS disk service:
;        retry/sector-match/motor-on/sector-mover against the I/O-config cells
;        ($03E0-$03EB), the slot-ROM page ($C088,X) and the RWTS helpers; it also holds
;        a sector-skew table. The Z-80 CCP/BDOS CALL several interior addresses here
;        (SUB_940B/SUB_941B/SUB_949A/... -- the labels below) as RPC selectors. Mirrors
;        the CPMV220-44K $9400 block (there factored out to CPM_RPC6502.s). --
        DEFB    $CE                                              ; $9401
L_9402:
        DEFB    $F8,$04,$D0                                      ; $9402
L_9405:
        DEFB    $E5,$F0,$CA,$68,$A9,$40                          ; $9405
SUB_940B:
        DEFB    $28,$4C,$3F,$BF,$F0,$2A,$A5,$2F,$8D              ; $940B  "(L??p*%/"
        DEFB    $E3,$03,$AD,$E2,$03,$F0,$08                      ; $9414
SUB_941B:
        DEFB    $C5,$2F,$F0,$04,$A9,$20,$D0,$E8,$AD,$E1,$03,$A8,$B9,$9E,$BF,$C5 ; $941B
        DEFB    $2D,$D0,$9F,$28,$90,$19,$20,$99,$BA,$08,$B0,$96,$28,$20,$D3,$BF ; $942B
        DEFB    $18,$A9,$00,$24,$38,$8D,$EA,$03,$AE,$F8,$05,$BD,$88,$C0,$60,$20 ; $943B
        DEFB    $00,$BA,$90,$EC,$A9,$10,$D0,$EC,$0A,$20,$5B,$BF,$4E,$78,$04,$60 ; $944B
        DEFB    $85,$2E,$20,$7E,$BF,$B9,$78,$04,$24,$35,$30,$03,$B9,$F8,$04,$8D ; $945B
        DEFB    $78,$04,$A5,$2E,$24,$35,$30,$05,$99,$F8,$04,$10,$03,$99,$78,$04 ; $946B
        DEFB    $4C,$5F,$BB,$8A,$4A,$4A,$4A,$4A,$A8,$60,$48,$AD,$E4,$03,$6A,$66 ; $947B
        DEFB    $35,$20,$7E,$BF,$68,$0A,$24,$35,$30,$05,$99,$F8,$04,$10,$03 ; $948B
SUB_949A:
        DEFB    $99,$78,$04,$60,$00,$02,$04,$06,$08,$0A,$0C,$0E,$01,$03 ; $949A
SUB_94A8:
        DEFB    $05,$07,$09,$0B,$0D                              ; $94A8
SUB_94AD:
        DEFB    $0F,$A2,$55                                      ; $94AD
SUB_94B0:
        DEFB    $A9,$00,$9D,$00,$0C,$CA,$10,$FA,$A8,$A2,$AC,$2C,$A2,$AA,$88,$B1 ; $94B0
        DEFB    $3E,$4A,$3E,$56,$0B,$4A,$3E,$56,$0B,$99,$00,$09,$E8 ; $94C0
SUB_94CD:
        DEFB    $D0,$EF,$98                                      ; $94CD
        DEFB    $D0,$EA,$60,$A0,$00                              ; $94D0  "Pj` "
        DEFB    $A2,$56,$CA,$30,$FB,$B9,$00                      ; $94D5  ""VJ0{9"
        DEFB    $09,$5E,$00                                      ; $94DC
SUB_94DF:
        DEFB    $0C,$2A,$5E,$00,$0C,$2A,$91,$3E,$C8,$D0,$ED      ; $94DF
L_94EA:
        DEFB    $60                                              ; $94EA
        DEFS    21, $00    ; $94EB  fill ($94EB-$94FF: tail padding of the 6502 RPC block)
; [AI] -- end of embedded 6502 block; Z-80 code resumes at $9500 --
SUB_94DF_1:
        LD A,C                           ; $9500  79
        RET                              ; $9501  C9
SUB_94DF_2:
        INC HL                           ; $9502  23
SUB_9503:
        DJNZ SUB_94DF_2                  ; $9503  10 FD
        INC C                            ; $9505  0C
        JR L_94EA                        ; $9506  18 E2
SUB_9503_1:
        XOR A                            ; $9508  AF
        LD (L_9306+1),A                  ; $9509  32 07 93
        LD SP,SUB_9B06_13                ; $950C  31 64 9B
        PUSH BC                          ; $950F  C5
        LD A,C                           ; $9510  79
        RRA                              ; $9511  1F
        RRA                              ; $9512  1F
        RRA                              ; $9513  1F
        RRA                              ; $9514  1F
        AND $0F                          ; $9515  E6 0F
        LD E,A                           ; $9517  5F
        CALL SUB_93F8                    ; $9518  CD F8 93
        CALL SUB_93B2                    ; $951B  CD B2 93
        LD (SUB_9B06_13),A               ; $951E  32 64 9B
SUB_9521:
        POP BC                           ; $9521  C1
        LD A,C                           ; $9522  79
        AND $0F                          ; $9523  E6 0F
        LD (SUB_9B06_27),A               ; $9525  32 A8 9B
SUB_9521_1:
        CALL SUB_93B6                    ; $9528  CD B6 93
        LD A,(L_9306+1)                  ; $952B  3A 07 93
        OR A                             ; $952E  B7
SUB_952F:
        JR NZ,SUB_9531_1                 ; $952F  20 16
SUB_9531:
        LD SP,SUB_9B06_13                ; $9531  31 64 9B
        CALL SUB_9391_2+1                ; $9534  CD 99 93
        CALL SUB_94A8                    ; $9537  CD A8 94
        ADD A,$41                        ; $953A  C6 41
        CALL SUB_938C                    ; $953C  CD 8C 93
        LD A,$3E                         ; $953F  3E 3E
        CALL SUB_938C                    ; $9541  CD 8C 93
        CALL SUB_941B                    ; $9544  CD 1B 94
SUB_9531_1:
        LD DE,DEFAULT_DMA                ; $9547  11 80 00
        CALL SUB_94B0                    ; $954A  CD B0 94
        CALL SUB_94A8                    ; $954D  CD A8 94
        LD (SUB_9B06_27),A               ; $9550  32 A8 9B
        CALL SUB_952F                    ; $9553  CD 2F 95
        CALL NZ,SUB_94DF                 ; $9556  C4 DF 94
        LD A,(SUB_9B06_28)               ; $9559  3A A9 9B
        OR A                             ; $955C  B7
        JP NZ,SUB_9707_33+1              ; $955D  C2 26 99
        CALL SUB_9531_11+2               ; $9560  CD E5 95
        LD HL,SUB_9531_20                ; $9563  21 70 96
        LD E,A                           ; $9566  5F
        LD D,$00                         ; $9567  16 00
        ADD HL,DE                        ; $9569  19
        ADD HL,DE                        ; $956A  19
        LD A,(HL)                        ; $956B  7E
        INC HL                           ; $956C  23
        LD H,(HL)                        ; $956D  66
        LD L,A                           ; $956E  6F
        JP (HL)                          ; $956F  E9
        DEFW    SUB_9707_1               ; $9570
        DEFW    SUB_9707_13              ; $9572
        DEFW    SUB_9707_15              ; $9574
        DEFW    SUB_9707_20              ; $9576
        DEFW    SUB_9707_25              ; $9578
        DEFW    SUB_9707_32              ; $957A
        DEFW    SUB_9707_33+1            ; $957C
SUB_9531_2:
        LD HL,$76F3                      ; $957E  21 F3 76
        LD (L_9300),HL                   ; $9581  22 00 93
        LD HL,L_9300                     ; $9584  21 00 93
        JP (HL)                          ; $9587  E9
SUB_9531_3:
        LD BC,SUB_9688_1                 ; $9588  01 8E 96
        JP SUB_9391_6+1                  ; $958B  C3 A2 93
        DEFB    "Read error"    ; $958E  string
        DEFB    $00    ; $9598  terminator
SUB_9531_4:
        LD BC,SUB_9699_1                 ; $9599  01 9F 96
        JP SUB_9391_6+1                  ; $959C  C3 A2 93
        DEFB    "No file"    ; $959F  string
        DEFB    $00    ; $95A6  terminator
SUB_9531_5:
        CALL SUB_952F                    ; $95A7  CD 2F 95
        LD A,(SUB_9B06_28)               ; $95AA  3A A9 9B
        OR A                             ; $95AD  B7
SUB_9531_6:
        JP NZ,SUB_94DF                   ; $95AE  C2 DF 94
        LD HL,SUB_9B06_19                ; $95B1  21 87 9B
        LD BC,$000B                      ; $95B4  01 0B 00
SUB_9531_7:
        LD A,(HL)                        ; $95B7  7E
        CP $20                           ; $95B8  FE 20
        JR Z,SUB_9531_10                 ; $95BA  28 24
        INC HL                           ; $95BC  23
        SUB $30                          ; $95BD  D6 30
        CP $0A                           ; $95BF  FE 0A
        JP NC,SUB_94DF                   ; $95C1  D2 DF 94
        LD D,A                           ; $95C4  57
        LD A,B                           ; $95C5  78
SUB_9531_8:
        AND $E0                          ; $95C6  E6 E0
SUB_9531_9:
        JP NZ,SUB_94DF                   ; $95C8  C2 DF 94
        LD A,B                           ; $95CB  78
        RLCA                             ; $95CC  07
        RLCA                             ; $95CD  07
        RLCA                             ; $95CE  07
        ADD A,B                          ; $95CF  80
        JP C,SUB_94DF                    ; $95D0  DA DF 94
        ADD A,B                          ; $95D3  80
        JP C,SUB_94DF                    ; $95D4  DA DF 94
        ADD A,D                          ; $95D7  82
        JP C,SUB_94DF                    ; $95D8  DA DF 94
        LD B,A                           ; $95DB  47
        DEC C                            ; $95DC  0D
        JR NZ,SUB_9531_7                 ; $95DD  20 D8
        RET                              ; $95DF  C9
SUB_9531_10:
        LD A,(HL)                        ; $95E0  7E
        CP $20                           ; $95E1  FE 20
SUB_9531_11:
        JP NZ,SUB_94DF                   ; $95E3  C2 DF 94
        INC HL                           ; $95E6  23
        DEC C                            ; $95E7  0D
        JR NZ,SUB_9531_10                ; $95E8  20 F6
        LD A,B                           ; $95EA  78
        RET                              ; $95EB  C9
SUB_9531_12:
        LD HL,DEFAULT_DMA                ; $95EC  21 80 00
        ADD A,C                          ; $95EF  81
        CALL SUB_9521_1+2                ; $95F0  CD 2A 95
        LD A,(HL)                        ; $95F3  7E
        RET                              ; $95F4  C9
SUB_9531_13:
        XOR A                            ; $95F5  AF
        LD (SUB_9B06_18),A               ; $95F6  32 86 9B
        LD A,(SUB_9B06_28)               ; $95F9  3A A9 9B
        OR A                             ; $95FC  B7
        RET Z                            ; $95FD  C8
        DEC A                            ; $95FE  3D
        LD HL,$81AD                      ; $95FF  21 AD 81
        RET NZ                           ; $9602  C0
        XOR L                            ; $9603  AD
        ADD A,C                          ; $9604  81
        RET NZ                           ; $9605  C0
        ADC A,D                          ; $9606  8A
        LD C,D                           ; $9607  4A
        LD C,D                           ; $9608  4A
        LD C,D                           ; $9609  4A
        LD C,D                           ; $960A  4A
        XOR B                            ; $960B  A8
        LD C,B                           ; $960C  48
        SBC A,L                          ; $960D  9D
        ADC A,B                          ; $960E  88
        RET NZ                           ; $960F  C0
        XOR C                            ; $9610  A9
        NOP                              ; $9611  00
        SBC A,C                          ; $9612  99
        LD A,B                           ; $9613  78
        INC B                            ; $9614  04
        SBC A,C                          ; $9615  99
        RET M                            ; $9616  F8
        INC B                            ; $9617  04
        JR NZ,SUB_9531_18                ; $9618  20 2F
        EI                               ; $961A  FB
        JR NZ,SUB_9531_6+2               ; $961B  20 93
        CP $20                           ; $961D  FE 20
SUB_9531_14:
        ADC A,C                          ; $961F  89
        CP $68                           ; $9620  FE 68
        AND D                            ; $9622  A2
        RST $38                          ; $9623  FF
        SBC A,D                          ; $9624  9A
SUB_9531_15:
        RET                              ; $9625  C9
SUB_9531_16:
        LD B,$F0                         ; $9626  06 F0
        DJNZ SUB_9531_9+2                ; $9628  10 A0
        NOP                              ; $962A  00
        CP C                             ; $962B  B9
        SUB D                            ; $962C  92
        LD DE,$06F0                      ; $962D  11 F0 06
SUB_9531_17:
        JR NZ,SUB_9531_14                ; $9630  20 ED
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $9632  FD C8
        RET Z                            ; $9633  C8
        RET NC                           ; $9634  D0
        PUSH AF                          ; $9635  F5
        LD C,H                           ; $9636  4C
        LD H,L                           ; $9637  65
        RST $38                          ; $9638  FF
        AND B                            ; $9639  A0
        LD C,$B9                         ; $963A  0E B9
        OR B                             ; $963C  B0
        LD DE,$FF99                      ; $963D  11 99 FF
        RRCA                             ; $9640  0F
        ADC A,B                          ; $9641  88
        RET NC                           ; $9642  D0
        RST $30                          ; $9643  F7
        CP C                             ; $9644  B9
        NOP                              ; $9645  00
        LD (DE),A                        ; $9646  12
        SBC A,C                          ; $9647  99
        NOP                              ; $9648  00
SUB_9531_18:
        LD (BC),A                        ; $9649  02
        ADC A,B                          ; $964A  88
        RET NC                           ; $964B  D0
        RST $30                          ; $964C  F7
        AND B                            ; $964D  A0
        POP AF                           ; $964E  F1
        CP C                             ; $964F  B9
        RST $38                          ; $9650  FF
        LD (DE),A                        ; $9651  12
        SBC A,C                          ; $9652  99
        RST $38                          ; $9653  FF
        LD (BC),A                        ; $9654  02
        ADC A,B                          ; $9655  88
        RET NC                           ; $9656  D0
        RST $30                          ; $9657  F7
        ADC A,H                          ; $9658  8C
        CP B                             ; $9659  B8
        INC BC                           ; $965A  03
        ADD A,H                          ; $965B  84
        INC A                            ; $965C  3C
        ADC A,B                          ; $965D  88
        ADD A,H                          ; $965E  84
        LD A,$A0                         ; $965F  3E A0
        RST $00                          ; $9661  C7
        ADD A,H                          ; $9662  84
        DEC A                            ; $9663  3D
        ADC A,H                          ; $9664  8C
        LD L,C                           ; $9665  69
        DJNZ SUB_9531_13                 ; $9666  10 8D
        NOP                              ; $9668  00
        RET NZ                           ; $9669  C0
        AND L                            ; $966A  A5
        LD A,$F0                         ; $966B  3E F0
        JR SUB_9688_2                    ; $966D  18 20
SUB_9531_19:
        LD C,(HL)                        ; $966F  4E
SUB_9531_20:
        LD DE,$4085                      ; $9670  11 85 40
        ADD A,(HL)                       ; $9673  86
        LD B,C                           ; $9674  41
        JR NZ,SUB_96A7_3                 ; $9675  20 4E
        LD DE,$00E0                      ; $9677  11 E0 00
        RET P                            ; $967A  F0
        LD E,$C5                         ; $967B  1E C5
        LD B,B                           ; $967D  40
        RET NC                           ; $967E  D0
        LD A,(DE)                        ; $967F  1A
        CALL PO,$F041                    ; $9680  E4 41 F0
        LD A,(DE)                        ; $9683  1A
        RET NC                           ; $9684  D0
        INC D                            ; $9685  14
        AND $3E                          ; $9686  E6 3E
SUB_9688:
        ADC A,H                          ; $9688  8C
        RET Z                            ; $9689  C8
        INC BC                           ; $968A  03
        XOR C                            ; $968B  A9
        NOP                              ; $968C  00
        ADC A,L                          ; $968D  8D
SUB_9688_1:
        RST $00                          ; $968E  C7
SUB_9688_2:
        INC BC                           ; $968F  03
        ADC A,L                          ; $9690  8D
        SBC A,$03                        ; $9691  DE 03
        SBC A,B                          ; $9693  98
        JR SUB_96F5_1+1                  ; $9694  18 69
SUB_9688_3:
        JR NZ,SUB_9531_15                ; $9696  20 8D
        RST $18                          ; $9698  DF
SUB_9699:
        INC BC                           ; $9699  03
        AND D                            ; $969A  A2
        NOP                              ; $969B  00
        RET P                            ; $969C  F0
        DEC L                            ; $969D  2D
        AND D                            ; $969E  A2
SUB_9699_1:
        INC B                            ; $969F  04
        AND B                            ; $96A0  A0
        DEC B                            ; $96A1  05
        OR C                             ; $96A2  B1
        INC A                            ; $96A3  3C
        CP (IX+17)                       ; $96A4  DD BE 11
SUB_96A7:
        RET NC                           ; $96A7  D0
        ADD HL,BC                        ; $96A8  09
SUB_96A7_1:
        AND B                            ; $96A9  A0
        RLCA                             ; $96AA  07
SUB_96A7_2:
        OR C                             ; $96AB  B1
        INC A                            ; $96AC  3C
        DEFB $DD  ; ignored IX prefix; inner: JP NZ,$F011 ; $96AD  DD C2 11 F0
        JP NZ,$F011                      ; $96AE  C2 11 F0
        INC BC                           ; $96B1  03
        JP Z,$EBD0                       ; $96B2  CA D0 EB
        RET PE                           ; $96B5  E8
        RET PO                           ; $96B6  E0
        LD (BC),A                        ; $96B7  02
        RET NC                           ; $96B8  D0
        INC BC                           ; $96B9  03
        XOR $B8                          ; $96BA  EE B8
        INC BC                           ; $96BC  03
        RET PO                           ; $96BD  E0
        INC B                            ; $96BE  04
        RET NC                           ; $96BF  D0
        LD A,(BC)                        ; $96C0  0A
        AND B                            ; $96C1  A0
        DEC BC                           ; $96C2  0B
        OR C                             ; $96C3  B1
        INC A                            ; $96C4  3C
SUB_96A7_3:
        RET                              ; $96C5  C9
SUB_96A7_4:
        LD BC,$02D0                      ; $96C6  01 D0 02
        AND D                            ; $96C9  A2
        LD B,$A4                         ; $96CA  06 A4
        DEC A                            ; $96CC  3D
        ADC A,D                          ; $96CD  8A
        SBC A,C                          ; $96CE  99
        RET M                            ; $96CF  F8
        LD (BC),A                        ; $96D0  02
        ADC A,B                          ; $96D1  88
        RET NZ                           ; $96D2  C0
        RET NZ                           ; $96D3  C0
        RET NC                           ; $96D4  D0
SUB_96A7_5:
        ADC A,H                          ; $96D5  8C
        LD C,$B8                         ; $96D6  0E B8
        INC BC                           ; $96D8  03
        AND L                            ; $96D9  A5
        LD A,$C9                         ; $96DA  3E C9
        LD BC,$10F0                      ; $96DC  01 F0 10
        AND B                            ; $96DF  A0
        NOP                              ; $96E0  00
        CP C                             ; $96E1  B9
        LD (HL),E                        ; $96E2  73
        LD DE,$06F0                      ; $96E3  11 F0 06
        JR NZ,SUB_96A7_5                 ; $96E6  20 ED
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $96E8  FD C8
        RET Z                            ; $96E9  C8
        RET NC                           ; $96EA  D0
        PUSH AF                          ; $96EB  F5
SUB_96EC:
        LD C,H                           ; $96EC  4C
        LD H,L                           ; $96ED  65
        RST $38                          ; $96EE  FF
        AND B                            ; $96EF  A0
        DJNZ SUB_96A7_2                  ; $96F0  10 B9
        RST $28                          ; $96F2  EF
        INC DE                           ; $96F3  13
        SBC A,C                          ; $96F4  99
SUB_96F5:
        RST $28                          ; $96F5  EF
        INC BC                           ; $96F6  03
        ADC A,B                          ; $96F7  88
        RET NC                           ; $96F8  D0
        RST $30                          ; $96F9  F7
        XOR C                            ; $96FA  A9
        JP $008D                         ; $96FB  C3 8D 00
SUB_96F5_1:
        DJNZ SUB_96A7_1                  ; $96FE  10 A9
        XOR B                            ; $9700  A8
        SBC A,E                          ; $9701  9B
        CP (HL)                          ; $9702  BE
        RET Z                            ; $9703  C8
        JP SUB_93B6                      ; $9704  C3 B6 93
SUB_9707:
        LD A,(SUB_9B06_28)               ; $9707  3A A9 9B
        OR A                             ; $970A  B7
        RET Z                            ; $970B  C8
        DEC A                            ; $970C  3D
        LD HL,SUB_9B06_27                ; $970D  21 A8 9B
        CP (HL)                          ; $9710  BE
        RET Z                            ; $9711  C8
        LD A,(SUB_9B06_27)               ; $9712  3A A8 9B
        JP SUB_93B6                      ; $9715  C3 B6 93
SUB_9707_1:
        CALL SUB_952F                    ; $9718  CD 2F 95
        CALL SUB_96F5                    ; $971B  CD F5 96
        LD HL,SUB_9B06_19                ; $971E  21 87 9B
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
        LD A,(SUB_9B06_26+2)             ; $9738  3A A7 9B
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
        CALL SUB_9391_2+1                ; $9752  CD 99 93
        PUSH BC                          ; $9755  C5
        CALL SUB_94A8                    ; $9756  CD A8 94
        POP BC                           ; $9759  C1
        ADD A,$41                        ; $975A  C6 41
        CALL SUB_9391_1+1                ; $975C  CD 93 93
        LD A,$3A                         ; $975F  3E 3A
        CALL SUB_9391_1+1                ; $9761  CD 93 93
        JR SUB_9707_6                    ; $9764  18 08
SUB_9707_5:
        CALL SUB_9391                    ; $9766  CD 91 93
        LD A,$3A                         ; $9769  3E 3A
        CALL SUB_9391_1+1                ; $976B  CD 93 93
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
        CALL SUB_9391_1+1                ; $9790  CD 93 93
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
        JP SUB_9707_55                   ; $97AE  C3 38 9A
SUB_9707_13:
        CALL SUB_952F                    ; $97B1  CD 2F 95
        CP $0B                           ; $97B4  FE 0B
        JR NZ,SUB_9707_14                ; $97B6  20 1B
        LD BC,L_97E3                     ; $97B8  01 E3 97
        CALL SUB_9391_6+1                ; $97BB  CD A2 93
        CALL SUB_941B                    ; $97BE  CD 1B 94
        LD HL,L_9306+1                   ; $97C1  21 07 93
        DEC (HL)                         ; $97C4  35
        JP NZ,SUB_9531_17+1              ; $97C5  C2 31 96
        INC HL                           ; $97C8  23
        LD A,(HL)                        ; $97C9  7E
        CP $59                           ; $97CA  FE 59
        JP NZ,SUB_9531_17+1              ; $97CC  C2 31 96
        INC HL                           ; $97CF  23
        LD (L_9387+1),HL                 ; $97D0  22 88 93
SUB_9707_14:
        CALL SUB_96F5                    ; $97D3  CD F5 96
        LD DE,SUB_9B06_18                ; $97D6  11 86 9B
        CALL SUB_93DC                    ; $97D9  CD DC 93
        INC A                            ; $97DC  3C
        CALL Z,SUB_9699                  ; $97DD  CC 99 96
        JP SUB_9707_55                   ; $97E0  C3 38 9A
L_97E3:
        DEFB    "All (y/n)?"    ; $97E3  string
        DEFB    $00    ; $97ED  terminator
SUB_9707_15:
        CALL SUB_952F                    ; $97EE  CD 2F 95
        JP NZ,SUB_94DF                   ; $97F1  C2 DF 94
        CALL SUB_96F5                    ; $97F4  CD F5 96
        CALL SUB_93C6                    ; $97F7  CD C6 93
        JR Z,SUB_9707_19                 ; $97FA  28 38
        CALL SUB_9391_2+1                ; $97FC  CD 99 93
        LD HL,SUB_9B06_29                ; $97FF  21 AA 9B
        LD (HL),$FF                      ; $9802  36 FF
SUB_9707_16:
        LD HL,SUB_9B06_29                ; $9804  21 AA 9B
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
        LD HL,DEFAULT_DMA                ; $9816  21 80 00
        CALL SUB_9521_1+2                ; $9819  CD 2A 95
        LD A,(HL)                        ; $981C  7E
        CP $1A                           ; $981D  FE 1A
        JP Z,SUB_9707_55                 ; $981F  CA 38 9A
        CALL SUB_938C                    ; $9822  CD 8C 93
        CALL SUB_949A                    ; $9825  CD 9A 94
        JP NZ,SUB_9707_55                ; $9828  C2 38 9A
        JR SUB_9707_16                   ; $982B  18 D7
SUB_9707_18:
        DEC A                            ; $982D  3D
        JP Z,SUB_9707_55                 ; $982E  CA 38 9A
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
        LD DE,SUB_9B06_18                ; $9847  11 86 9B
        PUSH DE                          ; $984A  D5
        CALL SUB_93DC                    ; $984B  CD DC 93
        POP DE                           ; $984E  D1
        CALL SUB_93EE                    ; $984F  CD EE 93
        JR Z,SUB_9707_23                 ; $9852  28 2F
        XOR A                            ; $9854  AF
        LD (SUB_9B06_26+1),A             ; $9855  32 A6 9B
        POP AF                           ; $9858  F1
        LD L,A                           ; $9859  6F
        LD H,$00                         ; $985A  26 00
        ADD HL,HL                        ; $985C  29
        LD DE,TPA_START                  ; $985D  11 00 01
SUB_9707_21:
        LD A,H                           ; $9860  7C
        OR L                             ; $9861  B5
        JR Z,SUB_9707_22                 ; $9862  28 16
        DEC HL                           ; $9864  2B
        PUSH HL                          ; $9865  E5
        LD HL,DEFAULT_DMA                ; $9866  21 80 00
        ADD HL,DE                        ; $9869  19
        PUSH HL                          ; $986A  E5
        CALL SUB_94B0                    ; $986B  CD B0 94
        LD DE,SUB_9B06_18                ; $986E  11 86 9B
        CALL SUB_93EA                    ; $9871  CD EA 93
        POP DE                           ; $9874  D1
        POP HL                           ; $9875  E1
        JR NZ,SUB_9707_23                ; $9876  20 0B
        JR SUB_9707_21                   ; $9878  18 E6
SUB_9707_22:
        LD DE,SUB_9B06_18                ; $987A  11 86 9B
        CALL SUB_93BC                    ; $987D  CD BC 93
        INC A                            ; $9880  3C
        JR NZ,SUB_9707_24                ; $9881  20 06
SUB_9707_23:
        LD BC,L_988F                     ; $9883  01 8F 98
        CALL SUB_9391_6+1                ; $9886  CD A2 93
SUB_9707_24:
        CALL SUB_94AD                    ; $9889  CD AD 94
        JP SUB_9707_55                   ; $988C  C3 38 9A
L_988F:
        DEFB    "No space"    ; $988F  string
        DEFB    $00    ; $9897  terminator
SUB_9707_25:
        CALL SUB_952F                    ; $9898  CD 2F 95
        JP NZ,SUB_94DF                   ; $989B  C2 DF 94
        LD A,(SUB_9B06_28)               ; $989E  3A A9 9B
        PUSH AF                          ; $98A1  F5
        CALL SUB_96F5                    ; $98A2  CD F5 96
        CALL SUB_93D1                    ; $98A5  CD D1 93
        JR NZ,SUB_9707_30                ; $98A8  20 50
        LD HL,SUB_9B06_18                ; $98AA  21 86 9B
        LD DE,SUB_9B06_24                ; $98AD  11 96 9B
        LD BC,RST2_VEC                   ; $98B0  01 10 00
        LDIR                             ; $98B3  ED B0
        LD HL,(L_9387+1)                 ; $98B5  2A 88 93
        EX DE,HL                         ; $98B8  EB
        CALL SUB_9521                    ; $98B9  CD 21 95
        CP $3D                           ; $98BC  FE 3D
        JR Z,SUB_9707_26                 ; $98BE  28 04
        CP $5F                           ; $98C0  FE 5F
        JR NZ,SUB_9707_29                ; $98C2  20 30
SUB_9707_26:
        EX DE,HL                         ; $98C4  EB
        INC HL                           ; $98C5  23
        LD (L_9387+1),HL                 ; $98C6  22 88 93
        CALL SUB_952F                    ; $98C9  CD 2F 95
        JR NZ,SUB_9707_29                ; $98CC  20 26
        POP AF                           ; $98CE  F1
        LD B,A                           ; $98CF  47
        LD HL,SUB_9B06_28                ; $98D0  21 A9 9B
        LD A,(HL)                        ; $98D3  7E
        OR A                             ; $98D4  B7
        JR Z,SUB_9707_27                 ; $98D5  28 04
        CP B                             ; $98D7  B8
        LD (HL),B                        ; $98D8  70
        JR NZ,SUB_9707_29                ; $98D9  20 19
SUB_9707_27:
        LD (HL),B                        ; $98DB  70
        XOR A                            ; $98DC  AF
        LD (SUB_9B06_18),A               ; $98DD  32 86 9B
        CALL SUB_93D1                    ; $98E0  CD D1 93
        JR Z,SUB_9707_28                 ; $98E3  28 09
        LD DE,SUB_9B06_18                ; $98E5  11 86 9B
        CALL SUB_93EE_1+1                ; $98E8  CD F2 93
        JP SUB_9707_55                   ; $98EB  C3 38 9A
SUB_9707_28:
        CALL SUB_9699                    ; $98EE  CD 99 96
        JP SUB_9707_55                   ; $98F1  C3 38 9A
SUB_9707_29:
        CALL SUB_9707                    ; $98F4  CD 07 97
        JP SUB_94DF                      ; $98F7  C3 DF 94
SUB_9707_30:
        LD BC,SUB_9707_31                ; $98FA  01 03 99
        CALL SUB_9391_6+1                ; $98FD  CD A2 93
        RRCA                             ; $9900  0F
        AND B                            ; $9901  A0
        LD A,C                           ; $9902  79
SUB_9707_31:
        SUB L                            ; $9903  95
        LD A,B                           ; $9904  78
        SBC A,H                          ; $9905  9C
        JP C,$A00F                       ; $9906  DA 0F A0
        EX DE,HL                         ; $9909  EB
        POP HL                           ; $990A  E1
        INC HL                           ; $990B  23
        JP SUB_9FB8_5+1                  ; $990C  C3 FA 9F
SUB_9707_32:
        POP HL                           ; $990F  E1
        PUSH BC                          ; $9910  C5
        PUSH DE                          ; $9911  D5
        PUSH HL                          ; $9912  E5
        EX DE,HL                         ; $9913  EB
        LD HL,($A9CE)                    ; $9914  2A CE A9
        ADD HL,DE                        ; $9917  19
        LD B,H                           ; $9918  44
        LD C,L                           ; $9919  4D
        CALL $FA1E                       ; $991A  CD 1E FA
        POP DE                           ; $991D  D1
        LD HL,($A9B5)                    ; $991E  2A B5 A9
        LD (HL),E                        ; $9921  73
        INC HL                           ; $9922  23
        LD (HL),D                        ; $9923  72
        POP DE                           ; $9924  D1
SUB_9707_33:
        LD HL,($A9B7)                    ; $9925  2A B7 A9
        LD (HL),E                        ; $9928  73
        INC HL                           ; $9929  23
        LD (HL),D                        ; $992A  72
        POP BC                           ; $992B  C1
        LD A,C                           ; $992C  79
        SUB E                            ; $992D  93
        LD C,A                           ; $992E  4F
        LD A,B                           ; $992F  78
        SBC A,D                          ; $9930  9A
        LD B,A                           ; $9931  47
        LD HL,($A9D0)                    ; $9932  2A D0 A9
        EX DE,HL                         ; $9935  EB
        CALL $FA30                       ; $9936  CD 30 FA
        LD C,L                           ; $9939  4D
        LD B,H                           ; $993A  44
        JP $FA21                         ; $993B  C3 21 FA
SUB_9707_34:
        LD HL,$A9C3                      ; $993E  21 C3 A9
        LD C,(HL)                        ; $9941  4E
        LD A,($A9E3)                     ; $9942  3A E3 A9
        OR A                             ; $9945  B7
        RRA                              ; $9946  1F
        DEC C                            ; $9947  0D
        JP NZ,$A045                      ; $9948  C2 45 A0
        LD B,A                           ; $994B  47
        LD A,$08                         ; $994C  3E 08
        SUB (HL)                         ; $994E  96
        LD C,A                           ; $994F  4F
        LD A,($A9E2)                     ; $9950  3A E2 A9
        DEC C                            ; $9953  0D
        JP Z,$A05C                       ; $9954  CA 5C A0
        OR A                             ; $9957  B7
        RLA                              ; $9958  17
        JP $A053                         ; $9959  C3 53 A0
SUB_9707_35:
        ADD A,B                          ; $995C  80
        RET                              ; $995D  C9
SUB_9707_36:
        LD HL,(SUB_9B06_74)              ; $995E  2A 43 9F
        LD DE,RST2_VEC                   ; $9961  11 10 00
        ADD HL,DE                        ; $9964  19
        ADD HL,BC                        ; $9965  09
        LD A,($A9DD)                     ; $9966  3A DD A9
        OR A                             ; $9969  B7
        JP Z,$A071                       ; $996A  CA 71 A0
        LD L,(HL)                        ; $996D  6E
        LD H,$00                         ; $996E  26 00
        RET                              ; $9970  C9
SUB_9707_37:
        ADD HL,BC                        ; $9971  09
        LD E,(HL)                        ; $9972  5E
        INC HL                           ; $9973  23
        LD D,(HL)                        ; $9974  56
        EX DE,HL                         ; $9975  EB
        RET                              ; $9976  C9
SUB_9707_38:
        CALL $A03E                       ; $9977  CD 3E A0
        LD C,A                           ; $997A  4F
        LD B,$00                         ; $997B  06 00
        CALL $A05E                       ; $997D  CD 5E A0
        LD ($A9E5),HL                    ; $9980  22 E5 A9
        RET                              ; $9983  C9
SUB_9707_39:
        LD HL,($A9E5)                    ; $9984  2A E5 A9
        LD A,L                           ; $9987  7D
        OR H                             ; $9988  B4
        RET                              ; $9989  C9
SUB_9707_40:
        LD A,($A9C3)                     ; $998A  3A C3 A9
        LD HL,($A9E5)                    ; $998D  2A E5 A9
        ADD HL,HL                        ; $9990  29
        DEC A                            ; $9991  3D
SUB_9707_41:
        JP NZ,$A090                      ; $9992  C2 90 A0
        LD ($A9E7),HL                    ; $9995  22 E7 A9
        LD A,($A9C4)                     ; $9998  3A C4 A9
        LD C,A                           ; $999B  4F
        LD A,($A9E3)                     ; $999C  3A E3 A9
        AND C                            ; $999F  A1
        OR L                             ; $99A0  B5
        LD L,A                           ; $99A1  6F
        LD ($A9E5),HL                    ; $99A2  22 E5 A9
        RET                              ; $99A5  C9
SUB_9707_42:
        LD HL,(SUB_9B06_74)              ; $99A6  2A 43 9F
        LD DE,$000C                      ; $99A9  11 0C 00
        ADD HL,DE                        ; $99AC  19
        RET                              ; $99AD  C9
SUB_9707_43:
        LD HL,(SUB_9B06_74)              ; $99AE  2A 43 9F
        LD DE,$000F                      ; $99B1  11 0F 00
        ADD HL,DE                        ; $99B4  19
        EX DE,HL                         ; $99B5  EB
SUB_9707_44:
        LD HL,$0011                      ; $99B6  21 11 00
        ADD HL,DE                        ; $99B9  19
        RET                              ; $99BA  C9
SUB_9707_45:
        CALL $A0AE                       ; $99BB  CD AE A0
        LD A,(HL)                        ; $99BE  7E
        LD ($A9E3),A                     ; $99BF  32 E3 A9
        EX DE,HL                         ; $99C2  EB
        LD A,(HL)                        ; $99C3  7E
        LD ($A9E1),A                     ; $99C4  32 E1 A9
        CALL $A0A6                       ; $99C7  CD A6 A0
        LD A,($A9C5)                     ; $99CA  3A C5 A9
        AND (HL)                         ; $99CD  A6
        LD ($A9E2),A                     ; $99CE  32 E2 A9
        RET                              ; $99D1  C9
SUB_9707_46:
        CALL $A0AE                       ; $99D2  CD AE A0
        LD A,($A9D5)                     ; $99D5  3A D5 A9
        CP $02                           ; $99D8  FE 02
        JP NZ,$A0DE                      ; $99DA  C2 DE A0
        XOR A                            ; $99DD  AF
        LD C,A                           ; $99DE  4F
        LD A,($A9E3)                     ; $99DF  3A E3 A9
        ADD A,C                          ; $99E2  81
        LD (HL),A                        ; $99E3  77
        EX DE,HL                         ; $99E4  EB
        LD A,($A9E1)                     ; $99E5  3A E1 A9
        LD (HL),A                        ; $99E8  77
        RET                              ; $99E9  C9
SUB_9707_47:
        INC C                            ; $99EA  0C
        DEC C                            ; $99EB  0D
        RET Z                            ; $99EC  C8
        LD A,H                           ; $99ED  7C
        OR A                             ; $99EE  B7
        RRA                              ; $99EF  1F
        LD H,A                           ; $99F0  67
        LD A,L                           ; $99F1  7D
        RRA                              ; $99F2  1F
        LD L,A                           ; $99F3  6F
        JP $A0EB                         ; $99F4  C3 EB A0
SUB_9707_48:
        LD C,$80                         ; $99F7  0E 80
        LD HL,($A9B9)                    ; $99F9  2A B9 A9
        XOR A                            ; $99FC  AF
        ADD A,(HL)                       ; $99FD  86
        INC HL                           ; $99FE  23
        DEC C                            ; $99FF  0D
        JP SUB_9707_55                   ; $9A00  C3 38 9A
        DEFB    "File exists"    ; $9A03  string
        DEFB    $00    ; $9A0E  terminator
SUB_9707_49:
        CALL SUB_96A7                    ; $9A0F  CD A7 96
        CP $10                           ; $9A12  FE 10
        JP NC,SUB_94DF                   ; $9A14  D2 DF 94
        LD E,A                           ; $9A17  5F
        LD A,(SUB_9B06_19)               ; $9A18  3A 87 9B
SUB_9707_50:
        CP $20                           ; $9A1B  FE 20
        JP Z,SUB_94DF                    ; $9A1D  CA DF 94
        CALL SUB_93F8                    ; $9A20  CD F8 93
SUB_9707_51:
        JP SUB_9707_56+2                 ; $9A23  C3 3B 9A
SUB_9707_52:
        CALL SUB_94CD                    ; $9A26  CD CD 94
        LD A,(SUB_9B06_19)               ; $9A29  3A 87 9B
SUB_9707_53:
        CP $20                           ; $9A2C  FE 20
        JR NZ,SUB_9707_57                ; $9A2E  20 16
        LD A,(SUB_9B06_28)               ; $9A30  3A A9 9B
        OR A                             ; $9A33  B7
SUB_9707_54:
        JP Z,SUB_9707_56+2               ; $9A34  CA 3B 9A
        DEC A                            ; $9A37  3D
SUB_9707_55:
        PUSH AF                          ; $9A38  F5
SUB_9707_56:
        CALL SUB_93B6                    ; $9A39  CD B6 93
        POP AF                           ; $9A3C  F1
        LD (SUB_9B06_27),A               ; $9A3D  32 A8 9B
        CALL SUB_940B                    ; $9A40  CD 0B 94
        JP SUB_9707_56+2                 ; $9A43  C3 3B 9A
SUB_9707_57:
        CALL SUB_93EE_3+1                ; $9A46  CD F6 93
        LD (SUB_9B06_9),A                ; $9A49  32 43 9B
SUB_9707_58:
        LD DE,SUB_9B06_21                ; $9A4C  11 8F 9B
        LD A,(DE)                        ; $9A4F  1A
SUB_9A50:
        CP $20                           ; $9A50  FE 20
SUB_9A50_1:
        JP NZ,SUB_94DF                   ; $9A52  C2 DF 94
        PUSH DE                          ; $9A55  D5
        CALL SUB_96F5                    ; $9A56  CD F5 96
        POP DE                           ; $9A59  D1
        LD HL,SUB_9707_54+1              ; $9A5A  21 35 9A
        LD BC,IOBYTE                     ; $9A5D  01 03 00
        LDIR                             ; $9A60  ED B0
SUB_9A50_2:
        CALL SUB_93C6                    ; $9A62  CD C6 93
        JR NZ,SUB_9A50_3                 ; $9A65  20 0D
        CALL SUB_93EE_3+1                ; $9A67  CD F6 93
        OR A                             ; $9A6A  B7
        JP Z,SUB_9707_50                 ; $9A6B  CA 1B 9A
        XOR A                            ; $9A6E  AF
        CALL SUB_9A50                    ; $9A6F  CD 50 9A
        JR SUB_9A50_2                    ; $9A72  18 EE
SUB_9A50_3:
        LD A,(SUB_9B06_18)               ; $9A74  3A 86 9B
        OR A                             ; $9A77  B7
        JR Z,SUB_9A50_4                  ; $9A78  28 04
        DEC A                            ; $9A7A  3D
        CALL SUB_93B6                    ; $9A7B  CD B6 93
SUB_9A50_4:
        LD C,$1F                         ; $9A7E  0E 1F
SUB_9A50_5:
        CALL BDOS_VEC                    ; $9A80  CD 05 00
        INC HL                           ; $9A83  23
        INC HL                           ; $9A84  23
        LD A,(HL)                        ; $9A85  7E
        CP $03                           ; $9A86  FE 03
        JR NZ,SUB_9A8D_1                 ; $9A88  20 09
        INC HL                           ; $9A8A  23
        INC HL                           ; $9A8B  23
        INC HL                           ; $9A8C  23
SUB_9A8D:
        LD A,(HL)                        ; $9A8D  7E
        CP $8B                           ; $9A8E  FE 8B
        JP Z,SUB_9A50_1+2                ; $9A90  CA 54 9A
SUB_9A8D_1:
        LD HL,TPA_START                  ; $9A93  21 00 01
SUB_9A8D_2:
        PUSH HL                          ; $9A96  E5
        EX DE,HL                         ; $9A97  EB
        CALL SUB_94B0                    ; $9A98  CD B0 94
        LD DE,SUB_9B06_18                ; $9A9B  11 86 9B
        CALL SUB_93E0_1+1                ; $9A9E  CD E3 93
        JR NZ,SUB_9A8D_3                 ; $9AA1  20 11
        POP HL                           ; $9AA3  E1
        LD DE,DEFAULT_DMA                ; $9AA4  11 80 00
        ADD HL,DE                        ; $9AA7  19
        LD DE,L_9300                     ; $9AA8  11 00 93
        OR A                             ; $9AAB  B7
        PUSH HL                          ; $9AAC  E5
        SBC HL,DE                        ; $9AAD  ED 52
        POP HL                           ; $9AAF  E1
        JR NC,SUB_9B06_3                 ; $9AB0  30 72
        JR SUB_9A8D_2                    ; $9AB2  18 E2
SUB_9A8D_3:
        POP HL                           ; $9AB4  E1
        DEC A                            ; $9AB5  3D
        JR NZ,SUB_9B06_3                 ; $9AB6  20 6C
        CALL SUB_9707_58+1               ; $9AB8  CD 4D 9A
        CALL SUB_9707                    ; $9ABB  CD 07 97
        CALL SUB_952F                    ; $9ABE  CD 2F 95
        LD HL,SUB_9B06_28                ; $9AC1  21 A9 9B
        PUSH HL                          ; $9AC4  E5
        LD A,(HL)                        ; $9AC5  7E
SUB_9A8D_4:
        LD (SUB_9B06_18),A               ; $9AC6  32 86 9B
        LD A,$10                         ; $9AC9  3E 10
        CALL SUB_9531                    ; $9ACB  CD 31 95
        POP HL                           ; $9ACE  E1
        LD A,(HL)                        ; $9ACF  7E
        LD (SUB_9B06_24),A               ; $9AD0  32 96 9B
        XOR A                            ; $9AD3  AF
SUB_9AD4:
        LD (SUB_9B06_26+1),A             ; $9AD4  32 A6 9B
        LD DE,DEFAULT_FCB                ; $9AD7  11 5C 00
        LD HL,SUB_9B06_18                ; $9ADA  21 86 9B
        LD BC,$0021                      ; $9ADD  01 21 00
        LDIR                             ; $9AE0  ED B0
        LD HL,L_9308                     ; $9AE2  21 08 93
SUB_9AD4_1:
        LD A,(HL)                        ; $9AE5  7E
        OR A                             ; $9AE6  B7
        JR Z,SUB_9AD4_2                  ; $9AE7  28 07
        CP $20                           ; $9AE9  FE 20
        JR Z,SUB_9AD4_2                  ; $9AEB  28 03
        INC HL                           ; $9AED  23
        JR SUB_9AD4_1                    ; $9AEE  18 F5
SUB_9AD4_2:
        LD B,$00                         ; $9AF0  06 00
        LD DE,CMDLINE                    ; $9AF2  11 81 00
SUB_9AD4_3:
        LD A,(HL)                        ; $9AF5  7E
        LD (DE),A                        ; $9AF6  12
        OR A                             ; $9AF7  B7
        JR Z,SUB_9AD4_4                  ; $9AF8  28 05
        INC B                            ; $9AFA  04
        INC HL                           ; $9AFB  23
        INC DE                           ; $9AFC  13
        JR SUB_9AD4_3                    ; $9AFD  18 F6
SUB_9AD4_4:
        LD A,B                           ; $9AFF  78
        JP NZ,$A0FD                      ; $9B00  C2 FD A0
        RET                              ; $9B03  C9
SUB_9AD4_5:
        INC C                            ; $9B04  0C
        DEC C                            ; $9B05  0D
SUB_9B06:
        RET Z                            ; $9B06  C8
        ADD HL,HL                        ; $9B07  29
        JP $A105                         ; $9B08  C3 05 A1
SUB_9B06_1:
        PUSH BC                          ; $9B0B  C5
        LD A,(SUB_9B06_73)               ; $9B0C  3A 42 9F
        LD C,A                           ; $9B0F  4F
        LD HL,$0001                      ; $9B10  21 01 00
        CALL $A104                       ; $9B13  CD 04 A1
        POP BC                           ; $9B16  C1
        LD A,C                           ; $9B17  79
        OR L                             ; $9B18  B5
        LD L,A                           ; $9B19  6F
        LD A,B                           ; $9B1A  78
        OR H                             ; $9B1B  B4
        LD H,A                           ; $9B1C  67
        RET                              ; $9B1D  C9
SUB_9B06_2:
        LD HL,($A9AD)                    ; $9B1E  2A AD A9
        LD A,(SUB_9B06_73)               ; $9B21  3A 42 9F
SUB_9B06_3:
        LD C,A                           ; $9B24  4F
SUB_9B06_4:
        CALL $A0EA                       ; $9B25  CD EA A0
        LD A,L                           ; $9B28  7D
        AND $01                          ; $9B29  E6 01
        RET                              ; $9B2B  C9
SUB_9B06_5:
        LD HL,$A9AD                      ; $9B2C  21 AD A9
        LD C,(HL)                        ; $9B2F  4E
        INC HL                           ; $9B30  23
SUB_9B06_6:
        LD B,(HL)                        ; $9B31  46
        CALL $A10B                       ; $9B32  CD 0B A1
        LD ($A9AD),HL                    ; $9B35  22 AD A9
        LD HL,($A9C8)                    ; $9B38  2A C8 A9
        INC HL                           ; $9B3B  23
        EX DE,HL                         ; $9B3C  EB
        LD HL,($A9B3)                    ; $9B3D  2A B3 A9
        LD (HL),E                        ; $9B40  73
SUB_9B06_7:
        INC HL                           ; $9B41  23
SUB_9B06_8:
        LD (HL),D                        ; $9B42  72
SUB_9B06_9:
        RET                              ; $9B43  C9
SUB_9B06_10:
        CALL $A15E                       ; $9B44  CD 5E A1
        LD DE,$0009                      ; $9B47  11 09 00
        ADD HL,DE                        ; $9B4A  19
        LD A,(HL)                        ; $9B4B  7E
        RLA                              ; $9B4C  17
        RET NC                           ; $9B4D  D0
        LD HL,SUB_9B06_38                ; $9B4E  21 0F 9C
        JP SUB_9B06_75                   ; $9B51  C3 4A 9F
SUB_9B06_11:
        CALL $A11E                       ; $9B54  CD 1E A1
        RET Z                            ; $9B57  C8
        LD HL,SUB_9B06_37+1              ; $9B58  21 0D 9C
        JP SUB_9B06_75                   ; $9B5B  C3 4A 9F
SUB_9B06_12:
        LD HL,($A9B9)                    ; $9B5E  2A B9 A9
        LD A,($A9E9)                     ; $9B61  3A E9 A9
SUB_9B06_13:
        ADD A,L                          ; $9B64  85
        LD L,A                           ; $9B65  6F
        RET NC                           ; $9B66  D0
        INC H                            ; $9B67  24
        RET                              ; $9B68  C9
SUB_9B06_14:
        LD HL,(SUB_9B06_74)              ; $9B69  2A 43 9F
        LD DE,$000E                      ; $9B6C  11 0E 00
        ADD HL,DE                        ; $9B6F  19
        LD A,(HL)                        ; $9B70  7E
        RET                              ; $9B71  C9
SUB_9B06_15:
        CALL $A169                       ; $9B72  CD 69 A1
        LD (HL),$00                      ; $9B75  36 00
        RET                              ; $9B77  C9
SUB_9B06_16:
        CALL $A169                       ; $9B78  CD 69 A1
        OR $80                           ; $9B7B  F6 80
        LD (HL),A                        ; $9B7D  77
        RET                              ; $9B7E  C9
SUB_9B06_17:
        LD HL,($A9EA)                    ; $9B7F  2A EA A9
        EX DE,HL                         ; $9B82  EB
        LD HL,($A9B3)                    ; $9B83  2A B3 A9
SUB_9B06_18:
        LD A,E                           ; $9B86  7B
SUB_9B06_19:
        SUB (HL)                         ; $9B87  96
        INC HL                           ; $9B88  23
        LD A,D                           ; $9B89  7A
        SBC A,(HL)                       ; $9B8A  9E
        RET                              ; $9B8B  C9
SUB_9B06_20:
        CALL $A17F                       ; $9B8C  CD 7F A1
SUB_9B06_21:
        RET C                            ; $9B8F  D8
        INC DE                           ; $9B90  13
        LD (HL),D                        ; $9B91  72
SUB_9B06_22:
        DEC HL                           ; $9B92  2B
        LD (HL),E                        ; $9B93  73
        RET                              ; $9B94  C9
SUB_9B06_23:
        LD A,E                           ; $9B95  7B
SUB_9B06_24:
        SUB L                            ; $9B96  95
        LD L,A                           ; $9B97  6F
        LD A,D                           ; $9B98  7A
        SBC A,H                          ; $9B99  9C
        LD H,A                           ; $9B9A  67
        RET                              ; $9B9B  C9
SUB_9B06_25:
        LD C,$FF                         ; $9B9C  0E FF
        LD HL,($A9EC)                    ; $9B9E  2A EC A9
        EX DE,HL                         ; $9BA1  EB
        LD HL,($A9CC)                    ; $9BA2  2A CC A9
SUB_9B06_26:
        CALL $A195                       ; $9BA5  CD 95 A1
SUB_9B06_27:
        RET NC                           ; $9BA8  D0
SUB_9B06_28:
        PUSH BC                          ; $9BA9  C5
SUB_9B06_29:
        CALL $A0F7                       ; $9BAA  CD F7 A0
        LD HL,($A9BD)                    ; $9BAD  2A BD A9
        EX DE,HL                         ; $9BB0  EB
        LD HL,($A9EC)                    ; $9BB1  2A EC A9
        ADD HL,DE                        ; $9BB4  19
        POP BC                           ; $9BB5  C1
        INC C                            ; $9BB6  0C
        JP Z,$A1C4                       ; $9BB7  CA C4 A1
        CP (HL)                          ; $9BBA  BE
        RET Z                            ; $9BBB  C8
        CALL $A17F                       ; $9BBC  CD 7F A1
        RET NC                           ; $9BBF  D0
        CALL $A12C                       ; $9BC0  CD 2C A1
        RET                              ; $9BC3  C9
SUB_9B06_30:
        LD (HL),A                        ; $9BC4  77
        RET                              ; $9BC5  C9
SUB_9B06_31:
        CALL $A19C                       ; $9BC6  CD 9C A1
        CALL $A1E0                       ; $9BC9  CD E0 A1
        LD C,$01                         ; $9BCC  0E 01
        CALL SUB_9FB8                    ; $9BCE  CD B8 9F
        JP $A1DA                         ; $9BD1  C3 DA A1
SUB_9B06_32:
        CALL $A1E0                       ; $9BD4  CD E0 A1
        CALL SUB_9FB2                    ; $9BD7  CD B2 9F
        LD HL,$A9B1                      ; $9BDA  21 B1 A9
        JP $A1E3                         ; $9BDD  C3 E3 A1
SUB_9B06_33:
        LD HL,$A9B9                      ; $9BE0  21 B9 A9
        LD C,(HL)                        ; $9BE3  4E
        INC HL                           ; $9BE4  23
        LD B,(HL)                        ; $9BE5  46
        JP $FA24                         ; $9BE6  C3 24 FA
SUB_9B06_34:
        LD HL,($A9B9)                    ; $9BE9  2A B9 A9
        EX DE,HL                         ; $9BEC  EB
        LD HL,($A9B1)                    ; $9BED  2A B1 A9
        LD C,$80                         ; $9BF0  0E 80
        JP SUB_9B06_76+2                 ; $9BF2  C3 4F 9F
SUB_9B06_35:
        LD HL,$A9EA                      ; $9BF5  21 EA A9
        LD A,(HL)                        ; $9BF8  7E
        INC HL                           ; $9BF9  23
        CP (HL)                          ; $9BFA  BE
        RET NZ                           ; $9BFB  C0
        INC A                            ; $9BFC  3C
        RET                              ; $9BFD  C9
SUB_9B06_36:
        LD HL,$32FF                      ; $9BFE  21 FF 32
        ADD A,B                          ; $9C01  80
        NOP                              ; $9C02  00
        CALL SUB_9391_2+1                ; $9C03  CD 99 93
        CALL SUB_94AD                    ; $9C06  CD AD 94
        CALL SUB_93FC                    ; $9C09  CD FC 93
SUB_9B06_37:
        CALL TPA_START                   ; $9C0C  CD 00 01
SUB_9B06_38:
        LD SP,SUB_9B06_13                ; $9C0F  31 64 9B
        CALL SUB_940B                    ; $9C12  CD 0B 94
        CALL SUB_93B6                    ; $9C15  CD B6 93
        JP SUB_9531_17+1                 ; $9C18  C3 31 96
SUB_9B06_39:
        CALL SUB_9707_58+1               ; $9C1B  CD 4D 9A
        CALL SUB_9707                    ; $9C1E  CD 07 97
        JP SUB_94DF                      ; $9C21  C3 DF 94
SUB_9B06_40:
        LD BC,SUB_9707_53                ; $9C24  01 2C 9A
        CALL SUB_9391_6+1                ; $9C27  CD A2 93
        JR SUB_9B06_41                   ; $9C2A  18 0C
        DEFB    "Bad load"    ; $9C2C  string
        DEFB    $00    ; $9C34  terminator
        DEFB    $43,$4F,$4D                                      ; $9C35
SUB_9B06_41:
        CALL SUB_9707                    ; $9C38  CD 07 97
        CALL SUB_952F                    ; $9C3B  CD 2F 95
        LD A,(SUB_9B06_19)               ; $9C3E  3A 87 9B
        SUB $20                          ; $9C41  D6 20
        LD HL,SUB_9B06_28                ; $9C43  21 A9 9B
        OR (HL)                          ; $9C46  B6
        JP NZ,SUB_94DF                   ; $9C47  C2 DF 94
        JP SUB_9531_17+1                 ; $9C4A  C3 31 96
SUB_9B06_42:
        LD A,(SUB_9B06_9)                ; $9C4D  3A 43 9B
        LD E,A                           ; $9C50  5F
        JP SUB_93F8                      ; $9C51  C3 F8 93
SUB_9B06_43:
        LD HL,($F3DE)                    ; $9C54  2A DE F3
        LD (SUB_9B06_4+1),HL             ; $9C57  22 26 9B
        XOR A                            ; $9C5A  AF
        LD (SUB_9B06_22),A               ; $9C5B  32 92 9B
        LD A,$11                         ; $9C5E  3E 11
        LD (SUB_9B06_7),A                ; $9C60  32 41 9B
        LD DE,$92FF                      ; $9C63  11 FF 92
SUB_9B06_44:
        XOR A                            ; $9C66  AF
        LD (SUB_9B06_26+1),A             ; $9C67  32 A6 9B
        LD HL,SUB_9B06_24                ; $9C6A  21 96 9B
SUB_9B06_45:
        LD A,(HL)                        ; $9C6D  7E
        OR A                             ; $9C6E  B7
        JR Z,SUB_9B06_46                 ; $9C6F  28 06
        CALL SUB_9A8D                    ; $9C71  CD 8D 9A
        INC HL                           ; $9C74  23
        JR SUB_9B06_45                   ; $9C75  18 F6
SUB_9B06_46:
        LD A,$A6                         ; $9C77  3E A6
        CP L                             ; $9C79  BD
        JP NZ,SUB_9A50_5+2               ; $9C7A  C2 82 9A
        CALL SUB_9A8D_4+2                ; $9C7D  CD C8 9A
        JR NZ,SUB_9B06_44                ; $9C80  20 E4
        XOR A                            ; $9C82  AF
        LD (DE),A                        ; $9C83  12
        CALL SUB_9AD4                    ; $9C84  CD D4 9A
        CALL SUB_9B06                    ; $9C87  CD 06 9B
        JP SUB_9707_44+2                 ; $9C8A  C3 B8 99
SUB_9B06_47:
        PUSH HL                          ; $9C8D  E5
        PUSH AF                          ; $9C8E  F5
        SRL A                            ; $9C8F  CB 3F
        SRL A                            ; $9C91  CB 3F
        ADD A,$03                        ; $9C93  C6 03
        LD (SUB_9B06_8),A                ; $9C95  32 42 9B
        POP AF                           ; $9C98  F1
        AND $03                          ; $9C99  E6 03
        ADD A,A                          ; $9C9B  87
        ADD A,A                          ; $9C9C  87
        LD HL,SUB_9B06_6                 ; $9C9D  21 31 9B
        ADD A,L                          ; $9CA0  85
        LD L,A                           ; $9CA1  6F
        JR NC,SUB_9B06_48                ; $9CA2  30 01
        INC H                            ; $9CA4  24
SUB_9B06_48:
        LD B,$04                         ; $9CA5  06 04
SUB_9B06_49:
        LD A,(SUB_9B06_8)                ; $9CA7  3A 42 9B
        LD (DE),A                        ; $9CAA  12
        DEC DE                           ; $9CAB  1B
        LD A,(HL)                        ; $9CAC  7E
        INC HL                           ; $9CAD  23
        LD (DE),A                        ; $9CAE  12
        DEC DE                           ; $9CAF  1B
        LD A,(SUB_9B06_7)                ; $9CB0  3A 41 9B
        CP $A1                           ; $9CB3  FE A1
        JP Z,SUB_9707_51+1               ; $9CB5  CA 24 9A
        CP $C0                           ; $9CB8  FE C0
        JR NZ,SUB_9B06_50                ; $9CBA  20 02
        LD A,$D0                         ; $9CBC  3E D0
SUB_9B06_50:
        LD (DE),A                        ; $9CBE  12
        INC A                            ; $9CBF  3C
        DEC DE                           ; $9CC0  1B
        LD (SUB_9B06_7),A                ; $9CC1  32 41 9B
        DJNZ SUB_9B06_49                 ; $9CC4  10 E1
        POP HL                           ; $9CC6  E1
        RET                              ; $9CC7  C9
SUB_9B06_51:
        PUSH HL                          ; $9CC8  E5
        PUSH DE                          ; $9CC9  D5
        LD HL,SUB_9B06_22                ; $9CCA  21 92 9B
        INC (HL)                         ; $9CCD  34
        CALL SUB_93C6                    ; $9CCE  CD C6 93
        POP DE                           ; $9CD1  D1
        POP HL                           ; $9CD2  E1
        RET                              ; $9CD3  C9
SUB_9B06_52:
        LD HL,$92FF                      ; $9CD4  21 FF 92
        LD D,H                           ; $9CD7  54
        LD E,L                           ; $9CD8  5D
SUB_9B06_53:
        DEC DE                           ; $9CD9  1B
        DEC DE                           ; $9CDA  1B
        DEC DE                           ; $9CDB  1B
        LD A,(DE)                        ; $9CDC  1A
        OR A                             ; $9CDD  B7
        JR Z,SUB_9B06_56                 ; $9CDE  28 1E
        CP (HL)                          ; $9CE0  BE
        JR C,SUB_9B06_54                 ; $9CE1  38 0A
        JR NZ,SUB_9B06_53                ; $9CE3  20 F4
        DEC DE                           ; $9CE5  1B
        LD A,(DE)                        ; $9CE6  1A
        INC DE                           ; $9CE7  13
        DEC HL                           ; $9CE8  2B
        CP (HL)                          ; $9CE9  BE
        INC HL                           ; $9CEA  23
        JR NC,SUB_9B06_53                ; $9CEB  30 EC
SUB_9B06_54:
        PUSH HL                          ; $9CED  E5
        PUSH DE                          ; $9CEE  D5
        LD B,$03                         ; $9CEF  06 03
SUB_9B06_55:
        LD A,(DE)                        ; $9CF1  1A
        LD C,(HL)                        ; $9CF2  4E
        LD (HL),A                        ; $9CF3  77
        LD A,C                           ; $9CF4  79
        LD (DE),A                        ; $9CF5  12
        DEC HL                           ; $9CF6  2B
        DEC DE                           ; $9CF7  1B
        DJNZ SUB_9B06_55                 ; $9CF8  10 F7
        POP DE                           ; $9CFA  D1
        POP HL                           ; $9CFB  E1
        JR SUB_9B06_53                   ; $9CFC  18 DB
SUB_9B06_56:
        DEC HL                           ; $9CFE  2B
        DEC HL                           ; $9CFF  2B
        RST $38                          ; $9D00  FF
        LD ($A9EA),HL                    ; $9D01  22 EA A9
        RET                              ; $9D04  C9
SUB_9B06_57:
        LD HL,($A9C8)                    ; $9D05  2A C8 A9
        EX DE,HL                         ; $9D08  EB
        LD HL,($A9EA)                    ; $9D09  2A EA A9
        INC HL                           ; $9D0C  23
        LD ($A9EA),HL                    ; $9D0D  22 EA A9
        CALL $A195                       ; $9D10  CD 95 A1
        JP NC,$A219                      ; $9D13  D2 19 A2
        JP $A1FE                         ; $9D16  C3 FE A1
SUB_9B06_58:
        LD A,($A9EA)                     ; $9D19  3A EA A9
        AND $03                          ; $9D1C  E6 03
        LD B,$05                         ; $9D1E  06 05
        ADD A,A                          ; $9D20  87
        DEC B                            ; $9D21  05
        JP NZ,$A220                      ; $9D22  C2 20 A2
        LD ($A9E9),A                     ; $9D25  32 E9 A9
        OR A                             ; $9D28  B7
        RET NZ                           ; $9D29  C0
        PUSH BC                          ; $9D2A  C5
        CALL SUB_9FB8_2+1                ; $9D2B  CD C3 9F
        CALL $A1D4                       ; $9D2E  CD D4 A1
        POP BC                           ; $9D31  C1
        JP $A19E                         ; $9D32  C3 9E A1
SUB_9B06_59:
        LD A,C                           ; $9D35  79
        AND $07                          ; $9D36  E6 07
        INC A                            ; $9D38  3C
        LD E,A                           ; $9D39  5F
        LD D,A                           ; $9D3A  57
        LD A,C                           ; $9D3B  79
        RRCA                             ; $9D3C  0F
        RRCA                             ; $9D3D  0F
        RRCA                             ; $9D3E  0F
        AND $1F                          ; $9D3F  E6 1F
        LD C,A                           ; $9D41  4F
        LD A,B                           ; $9D42  78
        ADD A,A                          ; $9D43  87
        ADD A,A                          ; $9D44  87
        ADD A,A                          ; $9D45  87
        ADD A,A                          ; $9D46  87
        ADD A,A                          ; $9D47  87
        OR C                             ; $9D48  B1
        LD C,A                           ; $9D49  4F
        LD A,B                           ; $9D4A  78
        RRCA                             ; $9D4B  0F
        RRCA                             ; $9D4C  0F
        RRCA                             ; $9D4D  0F
        AND $1F                          ; $9D4E  E6 1F
        LD B,A                           ; $9D50  47
        LD HL,($A9BF)                    ; $9D51  2A BF A9
        ADD HL,BC                        ; $9D54  09
        LD A,(HL)                        ; $9D55  7E
        RLCA                             ; $9D56  07
        DEC E                            ; $9D57  1D
        JP NZ,$A256                      ; $9D58  C2 56 A2
        RET                              ; $9D5B  C9
SUB_9B06_60:
        PUSH DE                          ; $9D5C  D5
        CALL $A235                       ; $9D5D  CD 35 A2
        AND $FE                          ; $9D60  E6 FE
        POP BC                           ; $9D62  C1
        OR C                             ; $9D63  B1
        RRCA                             ; $9D64  0F
        DEC D                            ; $9D65  15
        JP NZ,$A264                      ; $9D66  C2 64 A2
        LD (HL),A                        ; $9D69  77
        RET                              ; $9D6A  C9
SUB_9B06_61:
        CALL $A15E                       ; $9D6B  CD 5E A1
        LD DE,RST2_VEC                   ; $9D6E  11 10 00
        ADD HL,DE                        ; $9D71  19
        PUSH BC                          ; $9D72  C5
        LD C,$11                         ; $9D73  0E 11
        POP DE                           ; $9D75  D1
        DEC C                            ; $9D76  0D
        RET Z                            ; $9D77  C8
        PUSH DE                          ; $9D78  D5
        LD A,($A9DD)                     ; $9D79  3A DD A9
        OR A                             ; $9D7C  B7
        JP Z,$A288                       ; $9D7D  CA 88 A2
        PUSH BC                          ; $9D80  C5
        PUSH HL                          ; $9D81  E5
        LD C,(HL)                        ; $9D82  4E
        LD B,$00                         ; $9D83  06 00
        JP $A28E                         ; $9D85  C3 8E A2
SUB_9B06_62:
        DEC C                            ; $9D88  0D
        PUSH BC                          ; $9D89  C5
        LD C,(HL)                        ; $9D8A  4E
        INC HL                           ; $9D8B  23
        LD B,(HL)                        ; $9D8C  46
        PUSH HL                          ; $9D8D  E5
        LD A,C                           ; $9D8E  79
        OR B                             ; $9D8F  B0
        JP Z,$A29D                       ; $9D90  CA 9D A2
        LD HL,($A9C6)                    ; $9D93  2A C6 A9
        LD A,L                           ; $9D96  7D
        SUB C                            ; $9D97  91
        LD A,H                           ; $9D98  7C
        SBC A,B                          ; $9D99  98
        CALL NC,$A25C                    ; $9D9A  D4 5C A2
        POP HL                           ; $9D9D  E1
        INC HL                           ; $9D9E  23
        POP BC                           ; $9D9F  C1
        JP $A275                         ; $9DA0  C3 75 A2
SUB_9B06_63:
        LD HL,($A9C6)                    ; $9DA3  2A C6 A9
        LD C,$03                         ; $9DA6  0E 03
        CALL $A0EA                       ; $9DA8  CD EA A0
        INC HL                           ; $9DAB  23
        LD B,H                           ; $9DAC  44
        LD C,L                           ; $9DAD  4D
        LD HL,($A9BF)                    ; $9DAE  2A BF A9
        LD (HL),$00                      ; $9DB1  36 00
        INC HL                           ; $9DB3  23
        DEC BC                           ; $9DB4  0B
        LD A,B                           ; $9DB5  78
        OR C                             ; $9DB6  B1
        JP NZ,$A2B1                      ; $9DB7  C2 B1 A2
        LD HL,($A9CA)                    ; $9DBA  2A CA A9
        EX DE,HL                         ; $9DBD  EB
        LD HL,($A9BF)                    ; $9DBE  2A BF A9
        LD (HL),E                        ; $9DC1  73
        INC HL                           ; $9DC2  23
        LD (HL),D                        ; $9DC3  72
        CALL SUB_9FA1                    ; $9DC4  CD A1 9F
        LD HL,($A9B3)                    ; $9DC7  2A B3 A9
        LD (HL),$03                      ; $9DCA  36 03
        INC HL                           ; $9DCC  23
        LD (HL),$00                      ; $9DCD  36 00
        CALL $A1FE                       ; $9DCF  CD FE A1
        LD C,$FF                         ; $9DD2  0E FF
        CALL $A205                       ; $9DD4  CD 05 A2
SUB_9B06_64:
        CALL $A1F5                       ; $9DD7  CD F5 A1
        RET Z                            ; $9DDA  C8
        CALL $A15E                       ; $9DDB  CD 5E A1
        LD A,$E5                         ; $9DDE  3E E5
        CP (HL)                          ; $9DE0  BE
        JP Z,$A2D2                       ; $9DE1  CA D2 A2
        LD A,(SUB_9B06_72+2)             ; $9DE4  3A 41 9F
        CP (HL)                          ; $9DE7  BE
        JP NZ,$A2F6                      ; $9DE8  C2 F6 A2
        INC HL                           ; $9DEB  23
        LD A,(HL)                        ; $9DEC  7E
        SUB $24                          ; $9DED  D6 24
        JP NZ,$A2F6                      ; $9DEF  C2 F6 A2
        DEC A                            ; $9DF2  3D
        LD (SUB_9B06_74+2),A             ; $9DF3  32 45 9F
        LD C,$01                         ; $9DF6  0E 01
        CALL $A26B                       ; $9DF8  CD 6B A2
        CALL $A18C                       ; $9DFB  CD 8C A1
        JP $2BD2                         ; $9DFE  C3 D2 2B
SUB_9B06_65:
        LD A,(HL)                        ; $9E01  7E
        OR A                             ; $9E02  B7
        JR NZ,SUB_9B06_64                ; $9E03  20 D2
        RET                              ; $9E05  C9
SUB_9B06_66:
        LD DE,$92FF                      ; $9E06  11 FF 92
SUB_9B06_67:
        LD A,(DE)                        ; $9E09  1A
        OR A                             ; $9E0A  B7
        RET Z                            ; $9E0B  C8
        LD ($F3E0),A                     ; $9E0C  32 E0 F3
        DEC DE                           ; $9E0F  1B
        LD A,(DE)                        ; $9E10  1A
        LD ($F3E1),A                     ; $9E11  32 E1 F3
        DEC DE                           ; $9E14  1B
        LD A,(DE)                        ; $9E15  1A
        LD ($F3E9),A                     ; $9E16  32 E9 F3
        DEC DE                           ; $9E19  1B
        LD A,$01                         ; $9E1A  3E 01
        LD ($F3EB),A                     ; $9E1C  32 EB F3
        LD HL,$0E03                      ; $9E1F  21 03 0E
        LD ($F3D0),HL                    ; $9E22  22 D0 F3
        LD (WBOOT_VEC),A                 ; $9E25  32 00 00
        LD A,($F3EA)                     ; $9E28  3A EA F3
        OR A                             ; $9E2B  B7
        JR Z,SUB_9B06_67                 ; $9E2C  28 DB
        JP SUB_9707_41+1                 ; $9E2E  C3 93 99
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A,$04,$0D,$07,$08,$02,$0B,$05,$0E ; $9E31
        DEFS    37, $00    ; $9E41  fill
        DEFB    "$$$     SUB"    ; $9E66  string
        DEFB    $00    ; $9E71  terminator
        DEFS    142, $00    ; $9E72  fill
SUB_9B06_68:
        AND D                            ; $9F00  A2
SUB_9B06_69:
        LD A,($A9D4)                     ; $9F01  3A D4 A9
        JP SUB_9B06_69                   ; $9F04  C3 01 9F
SUB_9B06_70:
        PUSH BC                          ; $9F07  C5
        PUSH AF                          ; $9F08  F5
        LD A,($A9C5)                     ; $9F09  3A C5 A9
        CPL                              ; $9F0C  2F
        LD B,A                           ; $9F0D  47
        LD A,C                           ; $9F0E  79
        AND B                            ; $9F0F  A0
        LD C,A                           ; $9F10  4F
        POP AF                           ; $9F11  F1
        AND B                            ; $9F12  A0
        SUB C                            ; $9F13  91
        AND $1F                          ; $9F14  E6 1F
        POP BC                           ; $9F16  C1
        RET                              ; $9F17  C9
SUB_9B06_71:
        LD A,$FF                         ; $9F18  3E FF
        LD ($A9D4),A                     ; $9F1A  32 D4 A9
        LD HL,$A9D8                      ; $9F1D  21 D8 A9
        LD (HL),C                        ; $9F20  71
        LD HL,(SUB_9B06_74)              ; $9F21  2A 43 9F
        LD ($A9D9),HL                    ; $9F24  22 D9 A9
        CALL $A1FE                       ; $9F27  CD FE A1
        CALL SUB_9FA1                    ; $9F2A  CD A1 9F
        LD C,$00                         ; $9F2D  0E 00
        CALL $A205                       ; $9F2F  CD 05 A2
        CALL $A1F5                       ; $9F32  CD F5 A1
        JP Z,$A394                       ; $9F35  CA 94 A3
        LD HL,($A9D9)                    ; $9F38  2A D9 A9
        EX DE,HL                         ; $9F3B  EB
        LD A,(DE)                        ; $9F3C  1A
        CP $E5                           ; $9F3D  FE E5
SUB_9B06_72:
        JP Z,$A34A                       ; $9F3F  CA 4A A3
SUB_9B06_73:
        PUSH DE                          ; $9F42  D5
SUB_9B06_74:
        CALL $A17F                       ; $9F43  CD 7F A1
        POP DE                           ; $9F46  D1
        JP NC,$A394                      ; $9F47  D2 94 A3
SUB_9B06_75:
        CALL $A15E                       ; $9F4A  CD 5E A1
SUB_9B06_76:
        LD A,($A9D8)                     ; $9F4D  3A D8 A9
        LD C,A                           ; $9F50  4F
        LD B,$00                         ; $9F51  06 00
        LD A,C                           ; $9F53  79
        OR A                             ; $9F54  B7
        JP Z,$A383                       ; $9F55  CA 83 A3
        LD A,(DE)                        ; $9F58  1A
        CP $3F                           ; $9F59  FE 3F
        JP Z,$A37C                       ; $9F5B  CA 7C A3
        LD A,B                           ; $9F5E  78
        CP $0D                           ; $9F5F  FE 0D
        JP Z,$A37C                       ; $9F61  CA 7C A3
        CP $0C                           ; $9F64  FE 0C
        LD A,(DE)                        ; $9F66  1A
        JP Z,$A373                       ; $9F67  CA 73 A3
        SUB (HL)                         ; $9F6A  96
        AND $7F                          ; $9F6B  E6 7F
        JP NZ,$A32D                      ; $9F6D  C2 2D A3
        JP $A37C                         ; $9F70  C3 7C A3
SUB_9B06_77:
        PUSH BC                          ; $9F73  C5
        LD C,(HL)                        ; $9F74  4E
        CALL $A307                       ; $9F75  CD 07 A3
        POP BC                           ; $9F78  C1
        JP NZ,$A32D                      ; $9F79  C2 2D A3
        INC DE                           ; $9F7C  13
        INC HL                           ; $9F7D  23
        INC B                            ; $9F7E  04
        DEC C                            ; $9F7F  0D
        JP $A353                         ; $9F80  C3 53 A3
SUB_9B06_78:
        LD A,($A9EA)                     ; $9F83  3A EA A9
        AND $03                          ; $9F86  E6 03
        LD (SUB_9B06_74+2),A             ; $9F88  32 45 9F
        LD HL,$A9D4                      ; $9F8B  21 D4 A9
        LD A,(HL)                        ; $9F8E  7E
        RLA                              ; $9F8F  17
        RET NC                           ; $9F90  D0
        XOR A                            ; $9F91  AF
        LD (HL),A                        ; $9F92  77
        RET                              ; $9F93  C9
SUB_9B06_79:
        CALL $A1FE                       ; $9F94  CD FE A1
        LD A,$FF                         ; $9F97  3E FF
        JP SUB_9B06_69                   ; $9F99  C3 01 9F
SUB_9B06_80:
        CALL $A154                       ; $9F9C  CD 54 A1
        LD C,$0C                         ; $9F9F  0E 0C
SUB_9FA1:
        CALL $A318                       ; $9FA1  CD 18 A3
        CALL $A1F5                       ; $9FA4  CD F5 A1
        RET Z                            ; $9FA7  C8
        CALL $A144                       ; $9FA8  CD 44 A1
        CALL $A15E                       ; $9FAB  CD 5E A1
        LD (HL),$E5                      ; $9FAE  36 E5
        LD C,$00                         ; $9FB0  0E 00
SUB_9FB2:
        CALL $A26B                       ; $9FB2  CD 6B A2
        CALL $A1C6                       ; $9FB5  CD C6 A1
SUB_9FB8:
        CALL $A32D                       ; $9FB8  CD 2D A3
        JP $A3A4                         ; $9FBB  C3 A4 A3
SUB_9FB8_1:
        LD D,B                           ; $9FBE  50
        LD E,C                           ; $9FBF  59
        LD A,C                           ; $9FC0  79
        OR B                             ; $9FC1  B0
SUB_9FB8_2:
        JP Z,$A3D1                       ; $9FC2  CA D1 A3
        DEC BC                           ; $9FC5  0B
        PUSH DE                          ; $9FC6  D5
        PUSH BC                          ; $9FC7  C5
        CALL $A235                       ; $9FC8  CD 35 A2
        RRA                              ; $9FCB  1F
        JP NC,$A3EC                      ; $9FCC  D2 EC A3
        POP BC                           ; $9FCF  C1
        POP DE                           ; $9FD0  D1
        LD HL,($A9C6)                    ; $9FD1  2A C6 A9
        LD A,E                           ; $9FD4  7B
        SUB L                            ; $9FD5  95
        LD A,D                           ; $9FD6  7A
        SBC A,H                          ; $9FD7  9C
        JP NC,$A3F4                      ; $9FD8  D2 F4 A3
        INC DE                           ; $9FDB  13
        PUSH BC                          ; $9FDC  C5
        PUSH DE                          ; $9FDD  D5
        LD B,D                           ; $9FDE  42
        LD C,E                           ; $9FDF  4B
        CALL $A235                       ; $9FE0  CD 35 A2
        RRA                              ; $9FE3  1F
        JP NC,$A3EC                      ; $9FE4  D2 EC A3
        POP DE                           ; $9FE7  D1
        POP BC                           ; $9FE8  C1
        JP $A3C0                         ; $9FE9  C3 C0 A3
SUB_9FB8_3:
        RLA                              ; $9FEC  17
        INC A                            ; $9FED  3C
        CALL $A264                       ; $9FEE  CD 64 A2
        POP HL                           ; $9FF1  E1
        POP DE                           ; $9FF2  D1
        RET                              ; $9FF3  C9
SUB_9FB8_4:
        LD A,C                           ; $9FF4  79
        OR B                             ; $9FF5  B0
        JP NZ,$A3C0                      ; $9FF6  C2 C0 A3
SUB_9FB8_5:
        LD HL,WBOOT_VEC                  ; $9FF9  21 00 00
        RET                              ; $9FFC  C9
SUB_9FB8_6:
        LD C,$00                         ; $9FFD  0E 00
        DEFB    $1E                                              ; $9FFF
    ENT

; ---------------------------------------------------------------------------
; BDOS module ($8D00 staged -> $9C00 run). DISP makes its labels $9C00-based while
; its bytes are placed here at staging offset $0D00; DEFINE CPM_LINK keeps its
; standalone DEVICE/ORG/SAVEBIN out of this combined build.
; ---------------------------------------------------------------------------
    DISP $9C00
    DEFINE CPM_LINK
    INCLUDE "CPM_BDOS.asm"
    UNDEFINE CPM_LINK
    ENT

    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $8000, $1700
    ENDIF
