; ============================================================================
; BOOT_6502.s -- embedded 6502 disk-bootstrap payload of the BOOT.COM utility
; ----------------------------------------------------------------------------
; 269 bytes ($0153-$025F) that BOOT.COM carries as 6502 machine code. BOOT runs
; on the Z-80; this block runs on the 6502 (SoftCard CPU switch), so from the
; Z-80 it is opaque data. Rather than bury it as a DEFB blob, it is disassembled
; as real 6502 and assembled separately with ca65; BOOT.asm INCBINs the
; byte-identical binary and references its two cross-CPU entry points
; (TPA_START_19 = the LDIR payload start $0160, TPA_START_20 = the density
; self-mod target $0186) as offsets from the INCBIN base, so they relocate.
;
; What it is, by routine:
;   $0153  6502 launch stub -- plant "RTS" tail ($A9/$60 into $031F/$0320) and
;          JMP $0301 into the install image the Z-80 staged (run on the 6502).
;   $0160  read engine -- the Z-80 LDIRs this to Apple RAM $5000 and hands off
;          to the 6502: clear the $0800 nibble buffer, select Disk II slot-6
;          soft switches ($C08x,X), and spin on the read latch ($C08C) decoding
;          the 6-and-2 address + data fields into the buffer / via ($26).
;   $0231  GCR 6-and-2 denibble post-processor -- combine the secondary-bit
;          nibbles back into 256 data bytes, then JMP $1153 (next stage) or the
;          monitor $FF2D (PRERR) on a mismatch. Called by the $03xx orchestrator
;          the stub installs (an external entry, not reached by the in-block
;          trace), so it is seeded explicitly.
;   $025F  trailing $00 pad after the final JMP (genuine data).
;
; Position-independent: every internal branch is relative and every absolute
; reference is to a fixed Apple address (zero page, the $0800 buffer, page-3
; install image, $C08x slot-6 switches, monitor $FF2D), so the SAME bytes serve
; wherever the Z-80 stages them. Comments are [AI] inference unless tagged.
; Reassembles BYTE-IDENTICAL to the on-disk block (test_utilities_roundtrip).
; ============================================================================
.setcpu "6502"
.segment "CODE"

PRERR           = $FF2D         ; Apple II Monitor: print "ERR" + bell

.org $0153

L_0153:
        LDA #$A9                     ; $0153  A9 A9
        STA $031F                    ; $0155  8D 1F 03
        LDA #$60                     ; $0158  A9 60
        STA $0320                    ; $015A  8D 20 03
        JMP $0301                    ; $015D  4C 01 03
L_0160:
        LDX #$20                     ; $0160  A2 20
        LDY #$00                     ; $0162  A0 00
L_0164:
        LDA #$03                     ; $0164  A9 03
        STA $3C                      ; $0166  85 3C
        CLC                          ; $0168  18
        DEY                          ; $0169  88
        TYA                          ; $016A  98
L_016B:
        BIT $3C                      ; $016B  24 3C
        BEQ L_0164                   ; $016D  F0 F5
        ROL $3C                      ; $016F  26 3C
        BCC L_016B                   ; $0171  90 F8
        CPY #$D5                     ; $0173  C0 D5
        BEQ L_0164                   ; $0175  F0 ED
        DEX                          ; $0177  CA
        TXA                          ; $0178  8A
        STA $0800,Y                  ; $0179  99 00 08
        BNE L_0164                   ; $017C  D0 E6
        JSR $FF58                    ; $017E  20 58 FF
        TSX                          ; $0181  BA
        LDA #$60                     ; $0182  A9 60
        PHA                          ; $0184  48
        LDA #$0C                     ; $0185  A9 0C
        ASL                          ; $0187  0A
        ASL                          ; $0188  0A
        ASL                          ; $0189  0A
        STA $2B                      ; $018A  85 2B
        TAX                          ; $018C  AA
        LDA #$D0                     ; $018D  A9 D0
        PHA                          ; $018F  48
        LDA $C08E,X                  ; $0190  BD 8E C0
        LDA $C08C,X                  ; $0193  BD 8C C0
        LDA $C08A,X                  ; $0196  BD 8A C0
        LDA $C089,X                  ; $0199  BD 89 C0
        LDY #$50                     ; $019C  A0 50
L_019E:
        LDA $C080,X                  ; $019E  BD 80 C0
        TYA                          ; $01A1  98
        AND #$03                     ; $01A2  29 03
        ASL                          ; $01A4  0A
        ORA $2B                      ; $01A5  05 2B
        TAX                          ; $01A7  AA
        LDA $C081,X                  ; $01A8  BD 81 C0
        LDA #$56                     ; $01AB  A9 56
        JSR $FCA8                    ; $01AD  20 A8 FC
        DEY                          ; $01B0  88
        BPL L_019E                   ; $01B1  10 EB
        LDA #$03                     ; $01B3  A9 03
        STA $27                      ; $01B5  85 27
        LDA #$00                     ; $01B7  A9 00
        STA $26                      ; $01B9  85 26
        STA $3D                      ; $01BB  85 3D
L_01BD:
        CLC                          ; $01BD  18
L_01BE:
        PHP                          ; $01BE  08
L_01BF:
        LDA $C08C,X                  ; $01BF  BD 8C C0
        BPL L_01BF                   ; $01C2  10 FB
L_01C4:
        EOR #$D5                     ; $01C4  49 D5
        BNE L_01BF                   ; $01C6  D0 F7
L_01C8:
        LDA $C08C,X                  ; $01C8  BD 8C C0
        BPL L_01C8                   ; $01CB  10 FB
        CMP #$AA                     ; $01CD  C9 AA
        BNE L_01C4                   ; $01CF  D0 F3
        NOP                          ; $01D1  EA
L_01D2:
        LDA $C08C,X                  ; $01D2  BD 8C C0
        BPL L_01D2                   ; $01D5  10 FB
        CMP #$B5                     ; $01D7  C9 B5
        BEQ L_01E4                   ; $01D9  F0 09
        PLP                          ; $01DB  28
        BCC L_01BD                   ; $01DC  90 DF
        EOR #$AD                     ; $01DE  49 AD
        BEQ L_0201                   ; $01E0  F0 1F
        BNE L_01BD                   ; $01E2  D0 D9
L_01E4:
        LDY #$03                     ; $01E4  A0 03
        STY $2A                      ; $01E6  84 2A
L_01E8:
        LDA $C08C,X                  ; $01E8  BD 8C C0
        BPL L_01E8                   ; $01EB  10 FB
        ROL                          ; $01ED  2A
        STA $3C                      ; $01EE  85 3C
L_01F0:
        LDA $C08C,X                  ; $01F0  BD 8C C0
        BPL L_01F0                   ; $01F3  10 FB
        AND $3C                      ; $01F5  25 3C
        DEY                          ; $01F7  88
        BNE L_01E8                   ; $01F8  D0 EE
        PLP                          ; $01FA  28
        CMP $3D                      ; $01FB  C5 3D
        BNE L_01BD                   ; $01FD  D0 BE
        BCS L_01BE                   ; $01FF  B0 BD
L_0201:
        LDY #$9A                     ; $0201  A0 9A
L_0203:
        STY $3C                      ; $0203  84 3C
L_0205:
        LDY $C08C,X                  ; $0205  BC 8C C0
        BPL L_0205                   ; $0208  10 FB
        EOR $0800,Y                  ; $020A  59 00 08
        LDY $3C                      ; $020D  A4 3C
        DEY                          ; $020F  88
        STA $0800,Y                  ; $0210  99 00 08
        BNE L_0203                   ; $0213  D0 EE
L_0215:
        STY $3C                      ; $0215  84 3C
L_0217:
        LDY $C08C,X                  ; $0217  BC 8C C0
        BPL L_0217                   ; $021A  10 FB
        EOR $0800,Y                  ; $021C  59 00 08
        LDY $3C                      ; $021F  A4 3C
        STA ($26),Y                  ; $0221  91 26
        INY                          ; $0223  C8
        BNE L_0215                   ; $0224  D0 EF
L_0226:
        LDY $C08C,X                  ; $0226  BC 8C C0
        BPL L_0226                   ; $0229  10 FB
        EOR $0800,Y                  ; $022B  59 00 08
        BNE L_01BD                   ; $022E  D0 8D
        RTS                          ; $0230  60
L_0231:
        TAY                          ; $0231  A8
L_0232:
        LDX #$00                     ; $0232  A2 00
L_0234:
        LDA $0800,Y                  ; $0234  B9 00 08
        LSR                          ; $0237  4A
        ROL $03CC,X                  ; $0238  3E CC 03
        LSR                          ; $023B  4A
        ROL $0399,X                  ; $023C  3E 99 03
        STA $3C                      ; $023F  85 3C
        LDA ($26),Y                  ; $0241  B1 26
        ASL                          ; $0243  0A
        ASL                          ; $0244  0A
        ASL                          ; $0245  0A
        ORA $3C                      ; $0246  05 3C
        STA ($26),Y                  ; $0248  91 26
        INY                          ; $024A  C8
        INX                          ; $024B  E8
        CPX #$33                     ; $024C  E0 33
        BNE L_0234                   ; $024E  D0 E4
        DEC $2A                      ; $0250  C6 2A
        BNE L_0232                   ; $0252  D0 DE
        CPY $0300                    ; $0254  CC 00 03
        BNE L_025C                   ; $0257  D0 03
        JMP $1153                    ; $0259  4C 53 11
L_025C:
        JMP PRERR                    ; $025C  4C 2D FF  monitor "ERR"+bell on mismatch
        .byte   $00                                              ; $025F
