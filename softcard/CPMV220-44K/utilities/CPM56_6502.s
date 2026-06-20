; ============================================================================
; CPM56_6502.s -- embedded 6502 disk-update engine of the CPM56.COM utility
; ----------------------------------------------------------------------------
; 2181 bytes ($0304-$0B88) that CPM56.COM carries as 6502 machine code. CPM56
; runs on the Z-80; this block runs on the 6502 (SoftCard CPU switch), so from
; the Z-80 it is opaque data. Rather than bury it as a DEFB blob, it is
; disassembled as real 6502 and assembled separately with ca65; CPM56.asm
; INCBINs the byte-identical binary. Nothing OUTSIDE the block references an
; address INSIDE it (the Z-80 hands off via the SoftCard RPC slot $F3D0/$F3DE,
; not by a direct address ref), so no cross-CPU entry EQUs are needed.
;
; What it is, by routine (CPM56 rewrites the 44K boot tracks into the 56K
; layout; the actual track read/write/seek runs here on the 6502):
;   $0304  3-byte RPC entry prefix ($09 D0 13) -- genuine data, not code.
;   $0307  slot-setup + dispatch -- form the Disk II soft-switch base from the
;          slot# in ZP $27, prime the indirect-jump pointer at $3E/$3F, run the
;          pass counter at ZP $00 (0..$0A) and JMP ($003E) to the selected
;          per-track routine, or JMP $1000 when the pass count reaches $0B.
;   $0400  WRITE -- pre-nibble the $0D00/$0900 buffer into 6-and-2 GCR and write
;          the address+data fields to the Disk II ($C08D/$C08F write switches).
;   $0500  READ  -- spin on the read latch ($C08C), sync the D5 AA AD prologue,
;          denibble the 6-and-2 stream back into $0D00/$0900, check the DE
;          epilogue + checksum.  ($056A is an alternate denibble entry.)
;   $05C8  denibble tail; $05DE seek/arm -- step the head from $0478 to the
;          target track ($2A) via the $C080,X phase magnets, using the settle-
;          delay table at $0650 and the monitor stepper helpers at $0C2C/$0C3B.
;   $0800  disk-engine driver + cold-boot/slot-six check (SUB_0A00 prints the
;          "CAN'T FIND Z80 SOFTCARD" / "MUST BOOT FROM SLOT SIX" banners via
;          COUT and reloads via the page-3 RWTS cells $03E0-$03EB).
;   $09AD  warm-boot reload -- point the load buffer ($03E9 page), slot, loop
;          reading sectors via $0E10 (JSR PRERR on a read error).
;
; Data sub-regions kept as `.byte` (verified NOT code):
;   $0304-$0306  3-byte RPC entry prefix
;   $032D-$033C  write-nibble translate table (16 bytes, 6-and-2 low half)
;   $033D-$035F  high-bit COPYRIGHT banner ("(C) 1980 MICROSOFT - NK")
;   $0360-$03FF, $04BE-$04FF, $0668-$0755  $FF fill
;   $0650-$0667  head-stepper on/off settle-delay table (two 12-byte tables)
;   $0756-$07FF  read-translate (inverse 6-and-2 GCR) table -- 170 ($AA) bytes
;   $099D-$09AC  write-nibble table (16 bytes) embedded in the driver
;   $09FD-$09FF  $FF pad after the warm-boot RTS
;   $0B25-$0B2E  small data table ($C0 03 .. / $8D 8D 8D 8D)
;   $0B2F-$0B68  high-bit error banners (printed by the slot-six check)
;   $0B69-$0B88  data tail -- $08C7 "JSR $0B6A" is an un-understood Z-80->6502
;                RPC selector (the bytes here are NOT coherent 6502 code; the
;                SoftCard CPU-switch dispatch into $0Bxx is unresolved, the same
;                open question documented for CPM_RPC6502).
;
; Position-independent: every internal branch is relative and every absolute
; reference is to a fixed Apple address (zero page, the $0D00/$0900 buffers,
; page-3 RWTS cells $03Exx, $C08x slot switches, the monitor ROM), so the SAME
; bytes serve wherever the Z-80 stages them. Comments are [AI] inference unless
; tagged. Reassembles BYTE-IDENTICAL to the on-disk block (test_utilities_roundtrip).
; ============================================================================
.setcpu "6502"
.segment "CODE"

; -- Apple II Monitor ROM entry points used by the slot-six check / warm boot --
TEXT            = $FB2F         ; set text mode + full-screen window
COUT            = $FDED         ; output A via (CSW); default = screen
SETKBD          = $FE89         ; reset KSW to the default keyboard input
SETVID          = $FE93         ; reset CSW to the default screen output
PRERR           = $FF2D         ; print "ERR" + bell (read-error path)
MONZ            = $FF65         ; monitor entry (clear stack, "*", GETLN)

; -- Mid-instruction references (shown inline as cover+offset) --
;   $040E -> L_040D+1             6502 skip idiom: enters the operand of $2C at $040D
;   $093E -> L_093D+1             6502 skip idiom: enters the operand of $24 at $093D
;   $09C7 -> L_09C6+1             shared instruction tail: $09C7 is reachable code inside the instruction at $09C6
;   $0A25 -> SUB_0A00_1+1         shared instruction tail: $0A25 is reachable code inside the instruction at $0A24
;   $0AB4 -> SUB_0A00_15+1        shared instruction tail: $0AB4 is reachable code inside the instruction at $0AB3
;   $0AB5 -> SUB_0A00_15+2        shared instruction tail: $0AB5 is reachable code inside the instruction at $0AB3
;   $0AB7 -> SUB_0A00_16+1        shared instruction tail: $0AB7 is reachable code inside the instruction at $0AB6
;   $0B00 -> SUB_0A00_21+2        shared instruction tail: $0B00 is reachable code inside the instruction at $0AFE

.org $0304

        .byte   $09, $D0, $13                                    ; $0304  RPC entry prefix (data)
L_0307:
        TXA                          ; $0307  8A
        LSR                          ; $0308  4A
        LSR                          ; $0309  4A
        LSR                          ; $030A  4A
        LSR                          ; $030B  4A
        ORA #$C0                     ; $030C  09 C0
        STA $3F                      ; $030E  85 3F
        LDA #$5C                     ; $0310  A9 5C
        STA $3E                      ; $0312  85 3E
        LDA #$00                     ; $0314  A9 00
        STA $00                      ; $0316  85 00
        INC $27                      ; $0318  E6 27
        INC $00                      ; $031A  E6 00
        LDY $00                      ; $031C  A4 00
        CPY #$0B                     ; $031E  C0 0B
        BNE L_0325                   ; $0320  D0 03
        JMP $1000                    ; $0322  4C 00 10
L_0325:
        LDA $082D,Y                  ; $0325  B9 2D 08
        STA $3D                      ; $0328  85 3D
        JMP ($003E)                  ; $032A  6C 3E 00
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $032D
        .byte   $A0, $C3, $CF, $D0, $D9, $D2, $C9, $C7, $C8, $D4, $A0, $A8, $C3, $A9, $A0, $B1 ; $033D  " COPYRIGHT (C) 1"
        .byte   $B9, $B8, $B0, $A0, $CD, $C9, $C3, $D2, $CF, $D3, $CF, $C6, $D4, $A0, $AD, $A0 ; $034D  "980 MICROSOFT - "
        .byte   $CE, $CB, $A0                                    ; $035D  "NK "
        .res    114, $FF    ; $0360  fill
L_03D2:
        .res    46, $FF    ; $03D2  fill
L_0400:
        LDX #$55                     ; $0400  A2 55
        LDA #$00                     ; $0402  A9 00
L_0404:
        STA $0D00,X                  ; $0404  9D 00 0D
        DEX                          ; $0407  CA
        BPL L_0404                   ; $0408  10 FA
        TAY                          ; $040A  A8
        LDX #$AC                     ; $040B  A2 AC
L_040D:
        BIT $AAA2                    ; $040D  2C A2 AA
L_0410:
        DEY                          ; $0410  88
        LDA ($3E),Y                  ; $0411  B1 3E
        LSR                          ; $0413  4A
        ROL $0C56,X                  ; $0414  3E 56 0C
        LSR                          ; $0417  4A
        ROL $0C56,X                  ; $0418  3E 56 0C
        STA $0900,Y                  ; $041B  99 00 09
        INX                          ; $041E  E8
        BNE L_0410                   ; $041F  D0 EF
        TYA                          ; $0421  98
        BNE L_040D+1                 ; $0422  D0 EA
        RTS                          ; $0424  60
L_0425:
        SEC                          ; $0425  38
        STX $27                      ; $0426  86 27
        STX $0678                    ; $0428  8E 78 06
        LDA $C08D,X                  ; $042B  BD 8D C0
        LDA $C08E,X                  ; $042E  BD 8E C0
        BMI L_04AF                   ; $0431  30 7C
        LDA $0D00                    ; $0433  AD 00 0D
        STA $26                      ; $0436  85 26
        LDA #$FF                     ; $0438  A9 FF
        STA $C08F,X                  ; $043A  9D 8F C0
        ORA $C08C,X                  ; $043D  1D 8C C0
        PHA                          ; $0440  48
        PLA                          ; $0441  68
        NOP                          ; $0442  EA
        LDY #$04                     ; $0443  A0 04
L_0445:
        PHA                          ; $0445  48
        PLA                          ; $0446  68
        JSR SUB_0A00_15+2            ; $0447  20 B5 0A
        DEY                          ; $044A  88
        BNE L_0445                   ; $044B  D0 F8
        LDA #$D5                     ; $044D  A9 D5
        JSR SUB_0A00_15+1            ; $044F  20 B4 0A
        LDA #$AA                     ; $0452  A9 AA
        JSR SUB_0A00_15+1            ; $0454  20 B4 0A
        LDA #$AD                     ; $0457  A9 AD
        JSR SUB_0A00_15+1            ; $0459  20 B4 0A
        TYA                          ; $045C  98
        LDY #$56                     ; $045D  A0 56
        BNE L_0464                   ; $045F  D0 03
L_0461:
        LDA $0D00,Y                  ; $0461  B9 00 0D
L_0464:
        EOR $0CFF,Y                  ; $0464  59 FF 0C
        TAX                          ; $0467  AA
        LDA $0D56,X                  ; $0468  BD 56 0D
        LDX $27                      ; $046B  A6 27
        STA $C08D,X                  ; $046D  9D 8D C0
        LDA $C08C,X                  ; $0470  BD 8C C0
        DEY                          ; $0473  88
        BNE L_0461                   ; $0474  D0 EB
        LDA $26                      ; $0476  A5 26
        NOP                          ; $0478  EA
L_0479:
        EOR $0900,Y                  ; $0479  59 00 09
        TAX                          ; $047C  AA
        LDA $0D56,X                  ; $047D  BD 56 0D
        LDX $0678                    ; $0480  AE 78 06
        STA $C08D,X                  ; $0483  9D 8D C0
        LDA $C08C,X                  ; $0486  BD 8C C0
        LDA $0900,Y                  ; $0489  B9 00 09
        INY                          ; $048C  C8
        BNE L_0479                   ; $048D  D0 EA
        TAX                          ; $048F  AA
        LDA $0D56,X                  ; $0490  BD 56 0D
        LDX $27                      ; $0493  A6 27
        JSR SUB_0A00_16+1            ; $0495  20 B7 0A
        LDA #$DE                     ; $0498  A9 DE
        JSR SUB_0A00_15+1            ; $049A  20 B4 0A
        LDA #$AA                     ; $049D  A9 AA
        JSR SUB_0A00_15+1            ; $049F  20 B4 0A
        LDA #$EB                     ; $04A2  A9 EB
        JSR SUB_0A00_15+1            ; $04A4  20 B4 0A
        LDA #$FF                     ; $04A7  A9 FF
        JSR SUB_0A00_15+1            ; $04A9  20 B4 0A
        LDA $C08E,X                  ; $04AC  BD 8E C0
L_04AF:
        LDA $C08C,X                  ; $04AF  BD 8C C0
        RTS                          ; $04B2  60
L_04B3:
        NOP                          ; $04B3  EA
        CLC                          ; $04B4  18
        PHA                          ; $04B5  48
        PLA                          ; $04B6  68
        STA $C08D,X                  ; $04B7  9D 8D C0
        ORA $C08C,X                  ; $04BA  1D 8C C0
        RTS                          ; $04BD  60
        .res    66, $FF    ; $04BE  fill
L_0500:
        LDY #$20                     ; $0500  A0 20
L_0502:
        DEY                          ; $0502  88
        BEQ L_0568                   ; $0503  F0 63
L_0505:
        LDA $C08C,X                  ; $0505  BD 8C C0
        BPL L_0505                   ; $0508  10 FB
L_050A:
        EOR #$D5                     ; $050A  49 D5
        BNE L_0502                   ; $050C  D0 F4
        NOP                          ; $050E  EA
L_050F:
        LDA $C08C,X                  ; $050F  BD 8C C0
        BPL L_050F                   ; $0512  10 FB
        CMP #$AA                     ; $0514  C9 AA
        BNE L_050A                   ; $0516  D0 F2
        LDY #$56                     ; $0518  A0 56
L_051A:
        LDA $C08C,X                  ; $051A  BD 8C C0
        BPL L_051A                   ; $051D  10 FB
        CMP #$AD                     ; $051F  C9 AD
        BNE L_050A                   ; $0521  D0 E7
        NOP                          ; $0523  EA
        NOP                          ; $0524  EA
        LDA #$00                     ; $0525  A9 00
L_0527:
        DEY                          ; $0527  88
        STY $26                      ; $0528  84 26
L_052A:
        LDY $C08C,X                  ; $052A  BC 8C C0
        BPL L_052A                   ; $052D  10 FB
        EOR $0D00,Y                  ; $052F  59 00 0D
        LDY $26                      ; $0532  A4 26
        STA $0D00,Y                  ; $0534  99 00 0D
        BNE L_0527                   ; $0537  D0 EE
L_0539:
        STY $26                      ; $0539  84 26
L_053B:
        LDY $C08C,X                  ; $053B  BC 8C C0
        BPL L_053B                   ; $053E  10 FB
        EOR $0D00,Y                  ; $0540  59 00 0D
        LDY $26                      ; $0543  A4 26
        STA $0900,Y                  ; $0545  99 00 09
        INY                          ; $0548  C8
        BNE L_0539                   ; $0549  D0 EE
L_054B:
        LDY $C08C,X                  ; $054B  BC 8C C0
        BPL L_054B                   ; $054E  10 FB
        CMP $0D00,Y                  ; $0550  D9 00 0D
        BNE L_0568                   ; $0553  D0 13
L_0555:
        LDA $C08C,X                  ; $0555  BD 8C C0
        BPL L_0555                   ; $0558  10 FB
        CMP #$DE                     ; $055A  C9 DE
        BNE L_0568                   ; $055C  D0 0A
        NOP                          ; $055E  EA
L_055F:
        LDA $C08C,X                  ; $055F  BD 8C C0
        BPL L_055F                   ; $0562  10 FB
        CMP #$AA                     ; $0564  C9 AA
        BEQ L_05C4                   ; $0566  F0 5C
L_0568:
        SEC                          ; $0568  38
        RTS                          ; $0569  60
L_056A:
        LDY #$FC                     ; $056A  A0 FC
        STY $26                      ; $056C  84 26
L_056E:
        INY                          ; $056E  C8
        BNE L_0575                   ; $056F  D0 04
        INC $26                      ; $0571  E6 26
        BEQ L_0568                   ; $0573  F0 F3
L_0575:
        LDA $C08C,X                  ; $0575  BD 8C C0
        BPL L_0575                   ; $0578  10 FB
L_057A:
        CMP #$D5                     ; $057A  C9 D5
        BNE L_056E                   ; $057C  D0 F0
        NOP                          ; $057E  EA
L_057F:
        LDA $C08C,X                  ; $057F  BD 8C C0
        BPL L_057F                   ; $0582  10 FB
        CMP #$AA                     ; $0584  C9 AA
        BNE L_057A                   ; $0586  D0 F2
        LDY #$03                     ; $0588  A0 03
L_058A:
        LDA $C08C,X                  ; $058A  BD 8C C0
        BPL L_058A                   ; $058D  10 FB
        CMP #$96                     ; $058F  C9 96
        BNE L_057A                   ; $0591  D0 E7
        LDA #$00                     ; $0593  A9 00
L_0595:
        STA $27                      ; $0595  85 27
L_0597:
        LDA $C08C,X                  ; $0597  BD 8C C0
        BPL L_0597                   ; $059A  10 FB
        ROL                          ; $059C  2A
        STA $26                      ; $059D  85 26
L_059F:
        LDA $C08C,X                  ; $059F  BD 8C C0
        BPL L_059F                   ; $05A2  10 FB
        AND $26                      ; $05A4  25 26
        STA a:$002C,Y                ; $05A6  99 2C 00
        EOR $27                      ; $05A9  45 27
        DEY                          ; $05AB  88
        BPL L_0595                   ; $05AC  10 E7
        TAY                          ; $05AE  A8
        BNE L_0568                   ; $05AF  D0 B7
L_05B1:
        LDA $C08C,X                  ; $05B1  BD 8C C0
        BPL L_05B1                   ; $05B4  10 FB
        CMP #$DE                     ; $05B6  C9 DE
        BNE L_0568                   ; $05B8  D0 AE
        NOP                          ; $05BA  EA
L_05BB:
        LDA $C08C,X                  ; $05BB  BD 8C C0
        BPL L_05BB                   ; $05BE  10 FB
        CMP #$AA                     ; $05C0  C9 AA
        BNE L_0568                   ; $05C2  D0 A4
L_05C4:
        CLC                          ; $05C4  18
        RTS                          ; $05C5  60
L_05C6:
        LDY #$00                     ; $05C6  A0 00
L_05C8:
        LDX #$56                     ; $05C8  A2 56
L_05CA:
        DEX                          ; $05CA  CA
        BMI L_05C8                   ; $05CB  30 FB
        LDA $0900,Y                  ; $05CD  B9 00 09
        LSR $0D00,X                  ; $05D0  5E 00 0D
        ROL                          ; $05D3  2A
        LSR $0D00,X                  ; $05D4  5E 00 0D
        ROL                          ; $05D7  2A
        STA ($3E),Y                  ; $05D8  91 3E
        INY                          ; $05DA  C8
        BNE L_05CA                   ; $05DB  D0 ED
        RTS                          ; $05DD  60
L_05DE:
        STX $2B                      ; $05DE  86 2B
        STA $2A                      ; $05E0  85 2A
        CMP $0478                    ; $05E2  CD 78 04
        BEQ L_063A                   ; $05E5  F0 53
        LDA #$00                     ; $05E7  A9 00
        STA $26                      ; $05E9  85 26
L_05EB:
        LDA $0478                    ; $05EB  AD 78 04
        STA $27                      ; $05EE  85 27
        SEC                          ; $05F0  38
        SBC $2A                      ; $05F1  E5 2A
        BEQ L_0628                   ; $05F3  F0 33
        BCS L_05FE                   ; $05F5  B0 07
        EOR #$FF                     ; $05F7  49 FF
        INC $0478                    ; $05F9  EE 78 04
        BCC L_0603                   ; $05FC  90 05
L_05FE:
        ADC #$FE                     ; $05FE  69 FE
        DEC $0478                    ; $0600  CE 78 04
L_0603:
        CMP $26                      ; $0603  C5 26
        BCC L_0609                   ; $0605  90 02
        LDA $26                      ; $0607  A5 26
L_0609:
        CMP #$0C                     ; $0609  C9 0C
        BCS L_060E                   ; $060B  B0 01
        TAY                          ; $060D  A8
L_060E:
        SEC                          ; $060E  38
        JSR $0C2C                    ; $060F  20 2C 0C
        LDA $0C50,Y                  ; $0612  B9 50 0C
        JSR $0C3B                    ; $0615  20 3B 0C
        LDA $27                      ; $0618  A5 27
        CLC                          ; $061A  18
        JSR $0C2F                    ; $061B  20 2F 0C
        LDA $0C5C,Y                  ; $061E  B9 5C 0C
        JSR $0C3B                    ; $0621  20 3B 0C
        INC $26                      ; $0624  E6 26
        BNE L_05EB                   ; $0626  D0 C3
L_0628:
        JSR $0C3B                    ; $0628  20 3B 0C
        CLC                          ; $062B  18
        LDA $0478                    ; $062C  AD 78 04
        AND #$03                     ; $062F  29 03
        ROL                          ; $0631  2A
        ORA $2B                      ; $0632  05 2B
        TAX                          ; $0634  AA
        LDA $C080,X                  ; $0635  BD 80 C0
        LDX $2B                      ; $0638  A6 2B
L_063A:
        RTS                          ; $063A  60
L_063B:
        LDX #$11                     ; $063B  A2 11
L_063D:
        DEX                          ; $063D  CA
        BNE L_063D                   ; $063E  D0 FD
        INC $46                      ; $0640  E6 46
        BNE L_064A                   ; $0642  D0 06
        INC $47                      ; $0644  E6 47
        BNE L_064A                   ; $0646  D0 02
        DEC $47                      ; $0648  C6 47
L_064A:
        SEC                          ; $064A  38
        SBC #$01                     ; $064B  E9 01
        BNE L_063B                   ; $064D  D0 EC
        RTS                          ; $064F  60
        .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C, $70, $2C, $26, $22 ; $0650  stepper on/off delay table
        .byte   $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C           ; $0660
        .res    238, $FF    ; $0668  fill
        .byte   $96, $97, $9A, $9B, $9D, $9E, $9F, $A6, $A7, $AB, $AC, $AD, $AE, $AF, $B2, $B3 ; $0756  read-translate (inverse GCR) table
        .byte   $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC, $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3 ; $0766
        .byte   $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE, $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC ; $0776
        .byte   $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6, $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF ; $0786
        .byte   $00, $01, $98, $99, $02, $03, $9C, $04, $05, $06, $A0, $A1, $A2, $A3, $A4, $A5 ; $0796
        .byte   $07, $08, $A8, $A9, $AA, $09, $0A, $0B, $0C, $0D, $B0, $B1, $0E, $0F, $10, $11 ; $07A6
        .byte   $12, $13, $B8, $14, $15, $16, $17, $18, $19, $1A, $C0, $C1, $C2, $C3, $C4, $C5 ; $07B6
        .byte   $C6, $C7, $C8, $C9, $CA, $1B, $CC, $1C, $1D, $1E, $D0, $D1, $D2, $1F, $D4, $D5 ; $07C6
        .byte   $20, $21, $D8, $22, $23, $24, $25, $26, $27, $28, $E0, $E1, $E2, $E3, $E4, $29 ; $07D6
        .byte   $2A, $2B, $E8, $2C, $2D, $2E, $2F, $30, $31, $32, $F0, $F1, $33, $34, $35, $36 ; $07E6
        .byte   $37, $38, $F8, $39, $3A, $3B, $3C, $3D, $3E, $3F ; $07F6
L_0800:
        JMP $0FAD                    ; $0800  4C AD 0F
L_0803:
        LDA $C083                    ; $0803  AD 83 C0
        PHP                          ; $0806  08
        SEI                          ; $0807  78
        JSR $0E10                    ; $0808  20 10 0E
        LDA $C081                    ; $080B  AD 81 C0
        PLP                          ; $080E  28
        RTS                          ; $080F  60
L_0810:
        LDY #$02                     ; $0810  A0 02
        STY $06F8                    ; $0812  8C F8 06
        LDY #$04                     ; $0815  A0 04
        STY $04F8                    ; $0817  8C F8 04
        LDA $03E6                    ; $081A  AD E6 03
        TAX                          ; $081D  AA
        CMP $03E7                    ; $081E  CD E7 03
        BEQ L_0840                   ; $0821  F0 1D
        TXA                          ; $0823  8A
        TAY                          ; $0824  A8
        LDA $03E7                    ; $0825  AD E7 03
        TAX                          ; $0828  AA
        TYA                          ; $0829  98
        PHA                          ; $082A  48
        STA $03E7                    ; $082B  8D E7 03
        LDA $C08E,X                  ; $082E  BD 8E C0
L_0831:
        LDY #$08                     ; $0831  A0 08
        LDA $C08C,X                  ; $0833  BD 8C C0
L_0836:
        CMP $C08C,X                  ; $0836  DD 8C C0
        BNE L_0831                   ; $0839  D0 F6
        DEY                          ; $083B  88
        BNE L_0836                   ; $083C  D0 F8
        PLA                          ; $083E  68
        TAX                          ; $083F  AA
L_0840:
        LDA $C08E,X                  ; $0840  BD 8E C0
        LDA $C08C,X                  ; $0843  BD 8C C0
        LDY #$08                     ; $0846  A0 08
L_0848:
        LDA $C08C,X                  ; $0848  BD 8C C0
        PHA                          ; $084B  48
        PLA                          ; $084C  68
        PHA                          ; $084D  48
        PLA                          ; $084E  68
        STX $05F8                    ; $084F  8E F8 05
        CMP $C08C,X                  ; $0852  DD 8C C0
        BNE L_085A                   ; $0855  D0 03
        DEY                          ; $0857  88
        BNE L_0848                   ; $0858  D0 EE
L_085A:
        PHP                          ; $085A  08
        LDA $C089,X                  ; $085B  BD 89 C0
        LDA $03E8                    ; $085E  AD E8 03
        STA $3E                      ; $0861  85 3E
        LDA $03E9                    ; $0863  AD E9 03
        STA $3F                      ; $0866  85 3F
        LDA #$EF                     ; $0868  A9 EF
        STA $46                      ; $086A  85 46
        LDA #$D8                     ; $086C  A9 D8
        STA $47                      ; $086E  85 47
        LDA $03E4                    ; $0870  AD E4 03
        CMP $03E5                    ; $0873  CD E5 03
        BEQ L_087F                   ; $0876  F0 07
        STA $03E5                    ; $0878  8D E5 03
        PLP                          ; $087B  28
        LDY #$00                     ; $087C  A0 00
        PHP                          ; $087E  08
L_087F:
        ROR                          ; $087F  6A
        BCC L_0887                   ; $0880  90 05
        LDA $C08A,X                  ; $0882  BD 8A C0
        BCS L_088A                   ; $0885  B0 03
L_0887:
        LDA $C08B,X                  ; $0887  BD 8B C0
L_088A:
        ROR $35                      ; $088A  66 35
        PLP                          ; $088C  28
        PHP                          ; $088D  08
        BNE L_089B                   ; $088E  D0 0B
        LDY #$07                     ; $0890  A0 07
L_0892:
        JSR $0C3B                    ; $0892  20 3B 0C
        DEY                          ; $0895  88
        BNE L_0892                   ; $0896  D0 FA
        LDX $05F8                    ; $0898  AE F8 05
L_089B:
        LDA $03E0                    ; $089B  AD E0 03
        JSR $0F52                    ; $089E  20 52 0F
        LDA $03EB                    ; $08A1  AD EB 03
        PLP                          ; $08A4  28
        BNE L_08B8                   ; $08A5  D0 11
        CMP #$01                     ; $08A7  C9 01
        BEQ L_08B8                   ; $08A9  F0 0D
L_08AB:
        LDY #$12                     ; $08AB  A0 12
L_08AD:
        DEY                          ; $08AD  88
        BNE L_08AD                   ; $08AE  D0 FD
        INC $46                      ; $08B0  E6 46
        BNE L_08AB                   ; $08B2  D0 F7
        INC $47                      ; $08B4  E6 47
        BNE L_08AB                   ; $08B6  D0 F3
L_08B8:
        ROR                          ; $08B8  6A
        PHP                          ; $08B9  08
        BCS L_08BF                   ; $08BA  B0 03
        JSR SUB_0A00                 ; $08BC  20 00 0A
L_08BF:
        LDY #$30                     ; $08BF  A0 30
        STY $0578                    ; $08C1  8C 78 05
L_08C4:
        LDX $05F8                    ; $08C4  AE F8 05
        JSR SUB_0B6A                 ; $08C7  20 6A 0B
        BCC L_08F0                   ; $08CA  90 24
L_08CC:
        DEC $0578                    ; $08CC  CE 78 05
        BPL L_08C4                   ; $08CF  10 F3
L_08D1:
        LDA $0478                    ; $08D1  AD 78 04
        PHA                          ; $08D4  48
        LDA #$60                     ; $08D5  A9 60
        JSR $0F84                    ; $08D7  20 84 0F
        DEC $06F8                    ; $08DA  CE F8 06
        BEQ L_0907                   ; $08DD  F0 28
        LDA #$04                     ; $08DF  A9 04
        STA $04F8                    ; $08E1  8D F8 04
        LDA #$00                     ; $08E4  A9 00
        JSR $0F52                    ; $08E6  20 52 0F
        PLA                          ; $08E9  68
L_08EA:
        JSR $0F52                    ; $08EA  20 52 0F
        JMP $0EBF                    ; $08ED  4C BF 0E
L_08F0:
        LDY $2E                      ; $08F0  A4 2E
        CPY $0478                    ; $08F2  CC 78 04
        BEQ L_0910                   ; $08F5  F0 19
        LDA $0478                    ; $08F7  AD 78 04
        PHA                          ; $08FA  48
        TYA                          ; $08FB  98
        JSR $0F84                    ; $08FC  20 84 0F
        PLA                          ; $08FF  68
        DEC $04F8                    ; $0900  CE F8 04
        BNE L_08EA                   ; $0903  D0 E5
        BEQ L_08D1                   ; $0905  F0 CA
L_0907:
        PLA                          ; $0907  68
        LDA #$40                     ; $0908  A9 40
L_090A:
        PLP                          ; $090A  28
        JMP $0F3E                    ; $090B  4C 3E 0F
L_090E:
        BEQ L_093A                   ; $090E  F0 2A
L_0910:
        LDA $2F                      ; $0910  A5 2F
        STA $03E3                    ; $0912  8D E3 03
        LDA $03E2                    ; $0915  AD E2 03
        BEQ L_0922                   ; $0918  F0 08
        CMP $2F                      ; $091A  C5 2F
        BEQ L_0922                   ; $091C  F0 04
        LDA #$20                     ; $091E  A9 20
        BNE L_090A                   ; $0920  D0 E8
L_0922:
        LDA $03E1                    ; $0922  AD E1 03
        TAY                          ; $0925  A8
        LDA $0F9D,Y                  ; $0926  B9 9D 0F
        CMP $2D                      ; $0929  C5 2D
        BNE L_08CC                   ; $092B  D0 9F
        PLP                          ; $092D  28
        BCC L_0949                   ; $092E  90 19
        JSR SUB_0A00_21+2            ; $0930  20 00 0B
        PHP                          ; $0933  08
        BCS L_08CC                   ; $0934  B0 96
        PLP                          ; $0936  28
        JSR $0BC6                    ; $0937  20 C6 0B
L_093A:
        CLC                          ; $093A  18
        LDA #$00                     ; $093B  A9 00
L_093D:
        BIT $38                      ; $093D  24 38
        STA $03EA                    ; $093F  8D EA 03
        LDX $05F8                    ; $0942  AE F8 05
        LDA $C088,X                  ; $0945  BD 88 C0
        RTS                          ; $0948  60
L_0949:
        JSR SUB_0A00_1+1             ; $0949  20 25 0A
        BCC L_093A                   ; $094C  90 EC
        LDA #$10                     ; $094E  A9 10
        BNE L_093D+1                 ; $0950  D0 EC
        ASL                          ; $0952  0A
        JSR $0F5A                    ; $0953  20 5A 0F
        LSR $0478                    ; $0956  4E 78 04
        RTS                          ; $0959  60
L_095A:
        STA $2E                      ; $095A  85 2E
        JSR $0F7D                    ; $095C  20 7D 0F
        LDA $0478,Y                  ; $095F  B9 78 04
        BIT $35                      ; $0962  24 35
        BMI L_0969                   ; $0964  30 03
        LDA $04F8,Y                  ; $0966  B9 F8 04
L_0969:
        STA $0478                    ; $0969  8D 78 04
        LDA $2E                      ; $096C  A5 2E
        BIT $35                      ; $096E  24 35
        BMI L_0977                   ; $0970  30 05
        STA $04F8,Y                  ; $0972  99 F8 04
        BPL L_097A                   ; $0975  10 03
L_0977:
        STA $0478,Y                  ; $0977  99 78 04
L_097A:
        JMP $0BDE                    ; $097A  4C DE 0B
L_097D:
        TXA                          ; $097D  8A
        LSR                          ; $097E  4A
        LSR                          ; $097F  4A
        LSR                          ; $0980  4A
        LSR                          ; $0981  4A
        TAY                          ; $0982  A8
        RTS                          ; $0983  60
L_0984:
        PHA                          ; $0984  48
        LDA $03E4                    ; $0985  AD E4 03
        ROR                          ; $0988  6A
        ROR $35                      ; $0989  66 35
        JSR $0F7D                    ; $098B  20 7D 0F
        PLA                          ; $098E  68
        ASL                          ; $098F  0A
        BIT $35                      ; $0990  24 35
        BMI L_0999                   ; $0992  30 05
        STA $04F8,Y                  ; $0994  99 F8 04
        BPL L_099C                   ; $0997  10 03
L_0999:
        STA $0478,Y                  ; $0999  99 78 04
L_099C:
        RTS                          ; $099C  60
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $099D  write-nibble table
L_09AD:
        LDA #$E4                     ; $09AD  A9 E4
        STA $03E9                    ; $09AF  8D E9 03
        LDY #$00                     ; $09B2  A0 00
        STY $03E8                    ; $09B4  8C E8 03
        STY $03E0                    ; $09B7  8C E0 03
        INY                          ; $09BA  C8
        STY $03E4                    ; $09BB  8C E4 03
        STY $03EB                    ; $09BE  8C EB 03
        LDA #$60                     ; $09C1  A9 60
        STA $03E6                    ; $09C3  8D E6 03
L_09C6:
        LDA #$0B                     ; $09C6  A9 0B
        STA $03E1                    ; $09C8  8D E1 03
        LDA #$1C                     ; $09CB  A9 1C
L_09CD:
        PHA                          ; $09CD  48
        PHP                          ; $09CE  08
        SEI                          ; $09CF  78
        JSR $0E10                    ; $09D0  20 10 0E
        BCC L_09DD                   ; $09D3  90 08
        JSR PRERR                    ; $09D5  20 2D FF
        PLP                          ; $09D8  28
        PLA                          ; $09D9  68
        JMP $0FAD                    ; $09DA  4C AD 0F
L_09DD:
        PLP                          ; $09DD  28
        INC $03E9                    ; $09DE  EE E9 03
        LDX $03E1                    ; $09E1  AE E1 03
        INX                          ; $09E4  E8
        CPX #$10                     ; $09E5  E0 10
        BNE L_09EE                   ; $09E7  D0 05
        LDX #$00                     ; $09E9  A2 00
        INC $03E0                    ; $09EB  EE E0 03
L_09EE:
        STX $03E1                    ; $09EE  8E E1 03
        PLA                          ; $09F1  68
        SEC                          ; $09F2  38
        SBC #$01                     ; $09F3  E9 01
        BNE L_09CD                   ; $09F5  D0 D6
        LDA #$08                     ; $09F7  A9 08
        STA $03E9                    ; $09F9  8D E9 03
        RTS                          ; $09FC  60
        .byte   $FF, $FF, $FF                                    ; $09FD  pad
SUB_0A00:
        LDA $C081                    ; $0A00  AD 81 C0
        LDA $C081                    ; $0A03  AD 81 C0
        JSR $0F7D                    ; $0A06  20 7D 0F
        PHA                          ; $0A09  48
        STA $C088,X                  ; $0A0A  9D 88 C0
        LDA #$00                     ; $0A0D  A9 00
        STA $0478,Y                  ; $0A0F  99 78 04
        STA $04F8,Y                  ; $0A12  99 F8 04
        JSR TEXT                     ; $0A15  20 2F FB
        JSR SETVID                   ; $0A18  20 93 FE
        JSR SETKBD                   ; $0A1B  20 89 FE
        PLA                          ; $0A1E  68
        LDX #$FF                     ; $0A1F  A2 FF
        TXS                          ; $0A21  9A
        CMP #$06                     ; $0A22  C9 06
SUB_0A00_1:
        BEQ SUB_0A00_4               ; $0A24  F0 10
        LDY #$00                     ; $0A26  A0 00
SUB_0A00_2:
        LDA $114A,Y                  ; $0A28  B9 4A 11
        BEQ SUB_0A00_3               ; $0A2B  F0 06
        JSR COUT                     ; $0A2D  20 ED FD
        INY                          ; $0A30  C8
        BNE SUB_0A00_2               ; $0A31  D0 F5
SUB_0A00_3:
        JMP MONZ                     ; $0A33  4C 65 FF
SUB_0A00_4:
        LDY #$0E                     ; $0A36  A0 0E
SUB_0A00_5:
        LDA $1168,Y                  ; $0A38  B9 68 11
        STA $0FFF,Y                  ; $0A3B  99 FF 0F
        DEY                          ; $0A3E  88
        BNE SUB_0A00_5               ; $0A3F  D0 F7
SUB_0A00_6:
        LDA $1200,Y                  ; $0A41  B9 00 12
        STA $0200,Y                  ; $0A44  99 00 02
        DEY                          ; $0A47  88
        BNE SUB_0A00_6               ; $0A48  D0 F7
        LDY #$F1                     ; $0A4A  A0 F1
SUB_0A00_7:
        LDA $12FF,Y                  ; $0A4C  B9 FF 12
        STA $02FF,Y                  ; $0A4F  99 FF 02
        DEY                          ; $0A52  88
        BNE SUB_0A00_7               ; $0A53  D0 F7
        STY $03B8                    ; $0A55  8C B8 03
        STY $3C                      ; $0A58  84 3C
        DEY                          ; $0A5A  88
        STY $3E                      ; $0A5B  84 3E
        LDY #$C7                     ; $0A5D  A0 C7
SUB_0A00_8:
        JSR $1180                    ; $0A5F  20 80 11
        NOP                          ; $0A62  EA
        LDA $3E                      ; $0A63  A5 3E
        BEQ SUB_0A00_9               ; $0A65  F0 18
        JSR $1117                    ; $0A67  20 17 11
        STA $40                      ; $0A6A  85 40
        STX $41                      ; $0A6C  86 41
        JSR $1117                    ; $0A6E  20 17 11
        CPX #$00                     ; $0A71  E0 00
        BEQ SUB_0A00_10              ; $0A73  F0 1E
        CMP $40                      ; $0A75  C5 40
        BNE SUB_0A00_10              ; $0A77  D0 1A
        CPX $41                      ; $0A79  E4 41
        BEQ SUB_0A00_11              ; $0A7B  F0 1A
        BNE SUB_0A00_10              ; $0A7D  D0 14
SUB_0A00_9:
        INC $3E                      ; $0A7F  E6 3E
        STY $03C8                    ; $0A81  8C C8 03
        LDA #$00                     ; $0A84  A9 00
        STA $03C7                    ; $0A86  8D C7 03
        STA $03DE                    ; $0A89  8D DE 03
        TYA                          ; $0A8C  98
        CLC                          ; $0A8D  18
        ADC #$20                     ; $0A8E  69 20
        STA $03DF                    ; $0A90  8D DF 03
SUB_0A00_10:
        LDX #$00                     ; $0A93  A2 00
        BEQ SUB_0A00_16              ; $0A95  F0 1F
SUB_0A00_11:
        LDX #$04                     ; $0A97  A2 04
SUB_0A00_12:
        LDY #$05                     ; $0A99  A0 05
        LDA ($3C),Y                  ; $0A9B  B1 3C
        CMP $1176,X                  ; $0A9D  DD 76 11
        BNE SUB_0A00_13              ; $0AA0  D0 09
        LDY #$07                     ; $0AA2  A0 07
        LDA ($3C),Y                  ; $0AA4  B1 3C
        CMP $117A,X                  ; $0AA6  DD 7A 11
        BEQ SUB_0A00_14              ; $0AA9  F0 03
SUB_0A00_13:
        DEX                          ; $0AAB  CA
        BNE SUB_0A00_12              ; $0AAC  D0 EB
SUB_0A00_14:
        INX                          ; $0AAE  E8
        CPX #$02                     ; $0AAF  E0 02
        BNE SUB_0A00_16              ; $0AB1  D0 03
SUB_0A00_15:
        INC $03B8                    ; $0AB3  EE B8 03
SUB_0A00_16:
        LDY $3D                      ; $0AB6  A4 3D
        TXA                          ; $0AB8  8A
        STA $02F8,Y                  ; $0AB9  99 F8 02
        DEY                          ; $0ABC  88
        CPY #$C0                     ; $0ABD  C0 C0
        BNE SUB_0A00_8               ; $0ABF  D0 9E
        ASL $03B8                    ; $0AC1  0E B8 03
        LDA $3E                      ; $0AC4  A5 3E
        CMP #$01                     ; $0AC6  C9 01
        BEQ SUB_0A00_19              ; $0AC8  F0 1D
        STY $3D                      ; $0ACA  84 3D
        LDA #$85                     ; $0ACC  A9 85
        STA $3C                      ; $0ACE  85 3C
        STA $C085                    ; $0AD0  8D 85 C0
        LDA $3E                      ; $0AD3  A5 3E
        BEQ SUB_0A00_19              ; $0AD5  F0 10
        LDY #$00                     ; $0AD7  A0 00
SUB_0A00_17:
        LDA $112B,Y                  ; $0AD9  B9 2B 11
        BEQ SUB_0A00_18              ; $0ADC  F0 06
        JSR COUT                     ; $0ADE  20 ED FD
        INY                          ; $0AE1  C8
        BNE SUB_0A00_17              ; $0AE2  D0 F5
SUB_0A00_18:
        JMP MONZ                     ; $0AE4  4C 65 FF
SUB_0A00_19:
        LDY #$10                     ; $0AE7  A0 10
SUB_0A00_20:
        LDA $13EF,Y                  ; $0AE9  B9 EF 13
        STA $03EF,Y                  ; $0AEC  99 EF 03
        DEY                          ; $0AEF  88
        BNE SUB_0A00_20              ; $0AF0  D0 F7
        LDA #$C3                     ; $0AF2  A9 C3
        STA $1000                    ; $0AF4  8D 00 10
        LDA #$00                     ; $0AF7  A9 00
        STA $1001                    ; $0AF9  8D 01 10
        LDA #$DA                     ; $0AFC  A9 DA
SUB_0A00_21:
        STA $1002                    ; $0AFE  8D 02 10
        JSR $0FAD                    ; $0B01  20 AD 0F
        LDA #$16                     ; $0B04  A9 16
        STA $0FCC                    ; $0B06  8D CC 0F
        LDY #$06                     ; $0B09  A0 06
SUB_0A00_22:
        LDA $1124,Y                  ; $0B0B  B9 24 11
        STA $FFF9,Y                  ; $0B0E  99 F9 FF
        DEY                          ; $0B11  88
        BNE SUB_0A00_22              ; $0B12  D0 F7
        JMP L_03D2                   ; $0B14  4C D2 03
SUB_0A00_23:
        LDA #$00                     ; $0B17  A9 00
        TAX                          ; $0B19  AA
        TAY                          ; $0B1A  A8
SUB_0A00_24:
        CLC                          ; $0B1B  18
        ADC ($3C),Y                  ; $0B1C  71 3C
        BCC SUB_0A00_25              ; $0B1E  90 01
        INX                          ; $0B20  E8
SUB_0A00_25:
        INY                          ; $0B21  C8
SUB_0A00_26:
        BNE SUB_0A00_24              ; $0B22  D0 F7
        RTS                          ; $0B24  60
        .byte   $C0, $03, $C0, $03, $C0, $03, $8D, $8D, $8D, $8D ; $0B25
        .byte   $C3, $C1, $CE, $A7, $D4, $A0, $C6, $C9, $CE, $C4, $A0, $DA, $B8, $B0, $A0, $D3, $CF, $C6, $D4, $C3, $C1, $D2, $C4, $8D ; $0B2F  "CAN'T FIND Z80 SOFTCARD"
        .byte   $8D, $8D, $00, $8D, $8D, $8D, $8D                ; $0B47
        .byte   $CD, $D5, $D3, $D4, $A0, $C2, $CF, $CF, $D4, $A0, $C6, $D2, $CF, $CD, $A0, $D3, $CC, $CF, $D4, $A0, $D3, $C9, $D8, $8D ; $0B4E  "MUST BOOT FROM SLOT SIX"
        .byte   $8D, $8D, $00, $AF                               ; $0B66
SUB_0B6A:
        ; $08C7 "JSR $0B6A" -- un-understood Z-80->6502 RPC selector; these bytes
        ; are NOT coherent 6502 code, so they are kept as `.byte` data.
        .byte   $32, $3E, $F0, $6F, $3A, $3D, $F0, $C6, $20, $67, $77 ; $0B6A
        .byte   $18, $F2, $03, $18, $38, $48, $3C, $38, $18, $48, $FF, $84, $3D, $8C, $87, $11 ; $0B75
        .byte   $8D, $00, $00, $60                               ; $0B85
