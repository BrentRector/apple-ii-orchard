; ============================================================================
; FORMAT_6502.s -- embedded 6502 disk-format engine of the FORMAT.COM utility
; ----------------------------------------------------------------------------
; 1536 bytes ($0400-$09FF in the .COM image) that FORMAT.COM carries as 6502
; machine code. FORMAT.COM ("16 Sector Disk Formatter", (C) 1980 Microsoft)
; runs on the Z-80; this block runs on the 6502 (SoftCard CPU switch), so from
; the Z-80 it is opaque data. Rather than bury it as a DEFB blob it is
; disassembled as real 6502 and assembled separately with ca65; FORMAT.asm
; INCBINs the byte-identical binary. Nothing OUTSIDE the block references an
; address INSIDE it (the Z-80 hands off via the SoftCard RPC slot $F3D0/$F3DE,
; not by a direct address ref), so no cross-CPU entry EQUs are needed.
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-subroutine-call (RPC):
; the Z-80 stages the 6502 entry at A$VEC ($F3D0), pokes Z$CPU ($F3DE), the
; 6502 runs the code, results come back through the same cells.
;
; RELOCATED +$1000 AT RUNTIME. The block lives at $0400 in the .COM but the
; Z-80 front end stages LD HL,$1400 as the 6502 entry, so the SoftCard runs it
; at $1400-$19FF and every internal absolute self-reference here is written as
; $14xx-$19xx (e.g. JMP $1700, JSR $1491/$1492, LDA $1600,X). Those $1xxx
; literals are the RUN addresses and are intentionally NOT rewritten to file
; ($04xx) form -- they must stay $1xxx for the relocated copy to work. External
; fixed Apple addresses appear as themselves: the $C08x slot-6 Disk II
; soft-switches (phase magnets / read-write latch / motor), the engine's own
; 6-and-2 nibble buffers (run $1B00/$1C00/$1D00/$1E00 = file $0B00..+ relocated
; +$1000, filled at runtime), the page-3/screen-adjacent work cells
; ($0478/$04F8/$0578/$05F8/$06F8), the RWTS config cells $03E0-$03EB
; [DOC S&HD 2-6 ; facts sec.2.2], the command-line buffer ($0200..$0256), the
; Apple Monitor ROM ($F941 PLOT-ish helper, $FDDA PRBYTE), and the FORMAT
; helpers below the block ($12F7, $1A35, $1A6F).
;
; ENTRY (the Z-80 hands the 6502 a run-address via $F3D0): $1400 -> JMP $1700,
; the format driver. This is a 6-and-2 GCR Disk II engine: seek, write/read the
; D5 AA 96 address field and D5 AA AD data field, nibblize/denibblize, and
; format+verify each of the 16 sectors on every track.
;
; GENUINE DATA SUB-REGIONS (never code):
;   $15D1-$15E8  two 12-byte phase-step / head-settle delay tables
;   $1600-$163F  6-and-2 write-nibble translate table (6-bit -> disk byte,
;                $96..$FF)
;   $1640-$1646  7-byte cold-start pointer preamble (data fragment ahead of the
;                COLD_START init at $1647; not reachable 6502 control flow)
;   $1697-$16FF  6-and-2 de-nibble (read) translate table (disk byte -> 6-bit)
;   $18D1-$18E0  16-byte per-track format scratch buffer (STA/LDA $18D1,Y)
;   $19FF        trailing pad byte ($BD)
;
; OPEN QUESTION -- the Z-80->6502 dispatch is NOT fully understood. A few static
; jumps inside this block land in a data table or mid-instruction (JMP $1618 at
; $19E9 and JMP $16EC at $198D both target the nibble tables; JSR $165A at $1661
; lands inside the COLD_START STA $EF). These are the same SoftCard CPU-switch
; dispatch puzzle documented for CPM_RPC6502/CPM56_6502; the targets are left as
; data / cover+offset and not asserted to be clean code entries.
;
; Clean-room decompile; comments are [AI] inference unless tagged otherwise.
; Reassembles BYTE-IDENTICAL to the on-disk block (test_utilities_roundtrip).
; ============================================================================
.setcpu "6502"
.segment "CODE"

; -- Mid-instruction references (shown inline as cover+offset) --
;   $1434 -> WRITE_DATA_FIELD_2+2 shared instruction tail: $1434 is reachable code inside the instruction at $1432
;   $165A -> COLD_START_1+1       shared instruction tail: $165A is reachable code inside the instruction at $1659

.org $1400

ENTRY:
        JMP FORMAT_DRIVER            ; $1400  4C 00 17
WRITE_DATA_FIELD:
        SEC                          ; $1403  38
        STX $27                      ; $1404  86 27
        STX $0678                    ; $1406  8E 78 06
        LDA $C08D,X                  ; $1409  BD 8D C0
        LDA $C08E,X                  ; $140C  BD 8E C0
        BMI WRITE_DATA_EPILOGUE_1    ; $140F  30 7C
        LDA $1C00                    ; $1411  AD 00 1C
        STA $26                      ; $1414  85 26
        LDA #$FF                     ; $1416  A9 FF
        STA $C08F,X                  ; $1418  9D 8F C0
        ORA $C08C,X                  ; $141B  1D 8C C0
        PHA                          ; $141E  48
        PLA                          ; $141F  68
        NOP                          ; $1420  EA
        LDY #$04                     ; $1421  A0 04
WRITE_DATA_FIELD_1:
        PHA                          ; $1423  48
        PLA                          ; $1424  68
        JSR WR_NIB_PHA               ; $1425  20 92 14
        DEY                          ; $1428  88
        BNE WRITE_DATA_FIELD_1       ; $1429  D0 F8
        LDA #$D5                     ; $142B  A9 D5
        JSR WR_NIB_CLC               ; $142D  20 91 14
        LDA #$AA                     ; $1430  A9 AA
WRITE_DATA_FIELD_2:
        JSR WR_NIB_CLC               ; $1432  20 91 14
        LDA #$AD                     ; $1435  A9 AD
        JSR WR_NIB_CLC               ; $1437  20 91 14
        TYA                          ; $143A  98
        LDY #$56                     ; $143B  A0 56
        BNE WRITE_DATA_FIELD_4       ; $143D  D0 03
WRITE_DATA_FIELD_3:
        LDA $1C00,Y                  ; $143F  B9 00 1C
WRITE_DATA_FIELD_4:
        EOR $1BFF,Y                  ; $1442  59 FF 1B
        TAX                          ; $1445  AA
        LDA CMD_CHECK_1,X                 ; $1446  BD 00 16
        LDX $27                      ; $1449  A6 27
        STA $C08D,X                  ; $144B  9D 8D C0
        LDA $C08C,X                  ; $144E  BD 8C C0
        DEY                          ; $1451  88
        BNE WRITE_DATA_FIELD_3       ; $1452  D0 EB
        LDA $26                      ; $1454  A5 26
        NOP                          ; $1456  EA
WRITE_DATA_FIELD_5:
        EOR $1B00,Y                  ; $1457  59 00 1B
        TAX                          ; $145A  AA
        LDA CMD_CHECK_1,X                 ; $145B  BD 00 16
        LDX $0678                    ; $145E  AE 78 06
PUT_NIBBLE_2:                                                 ; second-buffer write-latch tail of WRITE_DATA_FIELD: store nibble to data latch, read latch
        STA $C08D,X                  ; $1461  9D 8D C0
        LDA $C08C,X                  ; $1464  BD 8C C0
        LDA $1B00,Y                  ; $1467  B9 00 1B
        INY                          ; $146A  C8
        BNE WRITE_DATA_FIELD_5       ; $146B  D0 EA
        TAX                          ; $146D  AA
        LDA CMD_CHECK_1,X                 ; $146E  BD 00 16
        LDX $27                      ; $1471  A6 27
        JSR WR_NIB                   ; $1473  20 94 14
        LDA #$DE                     ; $1476  A9 DE
WRITE_DATA_EPILOGUE:                                          ; write the DE AA EB FF data-field epilogue, then read the latch
        JSR WR_NIB_CLC               ; $1478  20 91 14
        LDA #$AA                     ; $147B  A9 AA
        JSR WR_NIB_CLC               ; $147D  20 91 14
        LDA #$EB                     ; $1480  A9 EB
        JSR WR_NIB_CLC               ; $1482  20 91 14
        LDA #$FF                     ; $1485  A9 FF
        JSR WR_NIB_CLC               ; $1487  20 91 14
        LDA $C08E,X                  ; $148A  BD 8E C0
WRITE_DATA_EPILOGUE_1:
        LDA $C08C,X                  ; $148D  BD 8C C0
        RTS                          ; $1490  60
WR_NIB_CLC:
        CLC                          ; $1491  18
WR_NIB_PHA:
        PHA                          ; $1492  48
        PLA                          ; $1493  68
WR_NIB:
        STA $C08D,X                  ; $1494  9D 8D C0
        ORA $C08C,X                  ; $1497  1D 8C C0
        RTS                          ; $149A  60
READ_DATA_FIELD:
        LDY #$20                     ; $149B  A0 20
READ_DATA_FIELD_1:
        DEY                          ; $149D  88
        BEQ READ_DATA_FIELD_13       ; $149E  F0 61
READ_DATA_FIELD_2:
        LDA $C08C,X                  ; $14A0  BD 8C C0
        BPL READ_DATA_FIELD_2        ; $14A3  10 FB
READ_DATA_FIELD_3:
        EOR #$D5                     ; $14A5  49 D5
        BNE READ_DATA_FIELD_1        ; $14A7  D0 F4
        NOP                          ; $14A9  EA
READ_DATA_FIELD_4:
        LDA $C08C,X                  ; $14AA  BD 8C C0
        BPL READ_DATA_FIELD_4        ; $14AD  10 FB
        CMP #$AA                     ; $14AF  C9 AA
        BNE READ_DATA_FIELD_3        ; $14B1  D0 F2
        LDY #$56                     ; $14B3  A0 56
READ_DATA_FIELD_5:
        LDA $C08C,X                  ; $14B5  BD 8C C0
        BPL READ_DATA_FIELD_5        ; $14B8  10 FB
        CMP #$AD                     ; $14BA  C9 AD
        BNE READ_DATA_FIELD_3        ; $14BC  D0 E7
        LDA #$00                     ; $14BE  A9 00
READ_DATA_FIELD_6:
        DEY                          ; $14C0  88
        STY $26                      ; $14C1  84 26
READ_DATA_FIELD_7:
        LDY $C08C,X                  ; $14C3  BC 8C C0
        BPL READ_DATA_FIELD_7        ; $14C6  10 FB
        EOR CMD_CHECK_1,Y                 ; $14C8  59 00 16
        LDY $26                      ; $14CB  A4 26
        STA $1E00,Y                  ; $14CD  99 00 1E
        BNE READ_DATA_FIELD_6        ; $14D0  D0 EE
READ_DATA_FIELD_8:
        STY $26                      ; $14D2  84 26
READ_DATA_FIELD_9:
        LDY $C08C,X                  ; $14D4  BC 8C C0
        BPL READ_DATA_FIELD_9        ; $14D7  10 FB
        EOR CMD_CHECK_1,Y                 ; $14D9  59 00 16
        LDY $26                      ; $14DC  A4 26
        STA $1D00,Y                  ; $14DE  99 00 1D
        INY                          ; $14E1  C8
        BNE READ_DATA_FIELD_8        ; $14E2  D0 EE
READ_DATA_FIELD_10:
        LDY $C08C,X                  ; $14E4  BC 8C C0
        BPL READ_DATA_FIELD_10       ; $14E7  10 FB
        CMP CMD_CHECK_1,Y                 ; $14E9  D9 00 16
        BNE READ_DATA_FIELD_13       ; $14EC  D0 13
READ_DATA_FIELD_11:
        LDA $C08C,X                  ; $14EE  BD 8C C0
        BPL READ_DATA_FIELD_11       ; $14F1  10 FB
        CMP #$DE                     ; $14F3  C9 DE
        BNE READ_DATA_FIELD_13       ; $14F5  D0 0A
        NOP                          ; $14F7  EA
READ_DATA_FIELD_12:
        LDA $C08C,X                  ; $14F8  BD 8C C0
        BPL READ_DATA_FIELD_12       ; $14FB  10 FB
        CMP #$AA                     ; $14FD  C9 AA
        BEQ READ_ADDR_FIELD_7        ; $14FF  F0 5C
READ_DATA_FIELD_13:
        SEC                          ; $1501  38
        RTS                          ; $1502  60
SYNC_D5AA:
        LDY #$FC                     ; $1503  A0 FC
        STY $26                      ; $1505  84 26
SYNC_D5AA_1:
        INY                          ; $1507  C8
        BNE SYNC_D5AA_2              ; $1508  D0 04
        INC $26                      ; $150A  E6 26
        BEQ READ_DATA_FIELD_13       ; $150C  F0 F3
SYNC_D5AA_2:
        LDA $C08C,X                  ; $150E  BD 8C C0
        BPL SYNC_D5AA_2              ; $1511  10 FB
SYNC_D5AA_3:
        CMP #$D5                     ; $1513  C9 D5
        BNE SYNC_D5AA_1              ; $1515  D0 F0
        NOP                          ; $1517  EA
SYNC_D5AA_4:
        LDA $C08C,X                  ; $1518  BD 8C C0
        BPL SYNC_D5AA_4              ; $151B  10 FB
        CMP #$AA                     ; $151D  C9 AA
        BNE SYNC_D5AA_3              ; $151F  D0 F2
READ_ADDR_FIELD:
        LDY #$03                     ; $1521  A0 03
READ_ADDR_FIELD_1:
        LDA $C08C,X                  ; $1523  BD 8C C0
        BPL READ_ADDR_FIELD_1        ; $1526  10 FB
        CMP #$96                     ; $1528  C9 96
        BNE SYNC_D5AA_3              ; $152A  D0 E7
        LDA #$00                     ; $152C  A9 00
READ_ADDR_FIELD_2:
        STA $27                      ; $152E  85 27
READ_ADDR_FIELD_3:
        LDA $C08C,X                  ; $1530  BD 8C C0
        BPL READ_ADDR_FIELD_3        ; $1533  10 FB
        ROL                          ; $1535  2A
        STA $26                      ; $1536  85 26
READ_ADDR_FIELD_4:
        LDA $C08C,X                  ; $1538  BD 8C C0
        BPL READ_ADDR_FIELD_4        ; $153B  10 FB
        AND $26                      ; $153D  25 26
        STA a:$002C,Y                ; $153F  99 2C 00
        EOR $27                      ; $1542  45 27
        DEY                          ; $1544  88
        BPL READ_ADDR_FIELD_2        ; $1545  10 E7
        TAY                          ; $1547  A8
        BNE READ_DATA_FIELD_13       ; $1548  D0 B7
READ_ADDR_FIELD_5:
        LDA $C08C,X                  ; $154A  BD 8C C0
        BPL READ_ADDR_FIELD_5        ; $154D  10 FB
        CMP #$DE                     ; $154F  C9 DE
        BNE READ_DATA_FIELD_13       ; $1551  D0 AE
        NOP                          ; $1553  EA
READ_ADDR_FIELD_6:
        LDA $C08C,X                  ; $1554  BD 8C C0
        BPL READ_ADDR_FIELD_6        ; $1557  10 FB
        CMP #$AA                     ; $1559  C9 AA
        BNE READ_DATA_FIELD_13       ; $155B  D0 A4
READ_ADDR_FIELD_7:
        CLC                          ; $155D  18
        RTS                          ; $155E  60
SEEK_TRACK:
        STX $2B                      ; $155F  86 2B
        STA $2A                      ; $1561  85 2A
        CMP $0478                    ; $1563  CD 78 04
        BEQ PHASE_ON_1               ; $1566  F0 53
        LDA #$00                     ; $1568  A9 00
        STA $26                      ; $156A  85 26
SEEK_TRACK_1:
        LDA $0478                    ; $156C  AD 78 04
        STA $27                      ; $156F  85 27
        SEC                          ; $1571  38
        SBC $2A                      ; $1572  E5 2A
        BEQ SEEK_TRACK_6             ; $1574  F0 33
        BCS SEEK_TRACK_2             ; $1576  B0 07
        EOR #$FF                     ; $1578  49 FF
        INC $0478                    ; $157A  EE 78 04
        BCC SEEK_TRACK_3             ; $157D  90 05
SEEK_TRACK_2:
        ADC #$FE                     ; $157F  69 FE
        DEC $0478                    ; $1581  CE 78 04
SEEK_TRACK_3:
        CMP $26                      ; $1584  C5 26
        BCC SEEK_TRACK_4             ; $1586  90 02
        LDA $26                      ; $1588  A5 26
SEEK_TRACK_4:
        CMP #$0C                     ; $158A  C9 0C
        BCS SEEK_TRACK_5             ; $158C  B0 01
        TAY                          ; $158E  A8
SEEK_TRACK_5:
        SEC                          ; $158F  38
        JSR PHASE_OFF                ; $1590  20 AD 15
        LDA STEP_DELAY_3,Y                 ; $1593  B9 D1 15
        JSR STEP_DELAY               ; $1596  20 BC 15
        LDA $27                      ; $1599  A5 27
        CLC                          ; $159B  18
        JSR PHASE_ON                 ; $159C  20 B0 15
        LDA STEP_DELAY_5,Y                 ; $159F  B9 DD 15
        JSR STEP_DELAY               ; $15A2  20 BC 15
        INC $26                      ; $15A5  E6 26
        BNE SEEK_TRACK_1             ; $15A7  D0 C3
SEEK_TRACK_6:
        JSR STEP_DELAY               ; $15A9  20 BC 15
        CLC                          ; $15AC  18
PHASE_OFF:
        LDA $0478                    ; $15AD  AD 78 04
PHASE_ON:
        AND #$03                     ; $15B0  29 03
        ROL                          ; $15B2  2A
        ORA $2B                      ; $15B3  05 2B
        TAX                          ; $15B5  AA
        LDA $C080,X                  ; $15B6  BD 80 C0
        LDX $2B                      ; $15B9  A6 2B
PHASE_ON_1:
        RTS                          ; $15BB  60
STEP_DELAY:
        LDX #$11                     ; $15BC  A2 11
STEP_DELAY_1:
        DEX                          ; $15BE  CA
        BNE STEP_DELAY_1             ; $15BF  D0 FD
        INC $46                      ; $15C1  E6 46
        BNE STEP_DELAY_2             ; $15C3  D0 06
        INC $47                      ; $15C5  E6 47
        BNE STEP_DELAY_2             ; $15C7  D0 02
        DEC $47                      ; $15C9  C6 47
STEP_DELAY_2:
        SEC                          ; $15CB  38
        SBC #$01                     ; $15CC  E9 01
        BNE STEP_DELAY               ; $15CE  D0 EC
        RTS                          ; $15D0  60
STEP_DELAY_3:
        .byte   $01, $30, $28, $24, $20, $1E, $1D                ; $15D1
STEP_DELAY_4:
        .byte   $1C, $1C, $1C, $1C, $1C                          ; $15D8
STEP_DELAY_5:
        .byte   $70, $2C, $26, $22, $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C ; $15DD
STEP_DELAY_TAIL:
        SBC $0F                      ; $15E9  E5 0F
        BCC STEP_DELAY_4                   ; $15EB  90 EB
        PLA                          ; $15ED  68
        TAX                          ; $15EE  AA
        RTS                          ; $15EF  60
CMD_CHECK:
        LDX #$00                     ; $15F0  A2 00
        STX $D1                      ; $15F2  86 D1
        STX $86                      ; $15F4  86 86
        LDA $0203                    ; $15F6  AD 03 02
        CMP #$AF                     ; $15F9  C9 AF
        BNE CMD_CHECK_2                   ; $15FB  D0 12
        LDA $0204                    ; $15FD  AD 04 02
CMD_CHECK_1:
        .byte   $96, $97, $9A, $9B, $9D, $9E, $9F, $A6, $A7, $AB, $AC, $AD, $AE, $AF, $B2 ; $1600
CMD_CHECK_2:
        .byte   $B3, $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC      ; $160F
CMD_CHECK_3:
        .byte   $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3, $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE ; $1618
        .byte   $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC, $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6 ; $1628
        .byte   $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF, $70, $85, $D4, $A5, $71, $85, $D5 ; $1638
COLD_START:
        LDX #$00                     ; $1647  A2 00
        STX $D9                      ; $1649  86 D9
        STX $E5                      ; $164B  86 E5
        STX $E4                      ; $164D  86 E4
        STX $EC                      ; $164F  86 EC
        STX $EE                      ; $1651  86 EE
        STX $D7                      ; $1653  86 D7
        STX $D8                      ; $1655  86 D8
        LDA #$70                     ; $1657  A9 70
COLD_START_1:
        STA $EF                      ; $1659  85 EF
        STA $ED                      ; $165B  85 ED
        LDX #$FF                     ; $165D  A2 FF
        TXS                          ; $165F  9A
        INX                          ; $1660  E8
        JSR COLD_START_1+1           ; $1661  20 5A 16
        LDA $D1                      ; $1664  A5 D1
        BEQ COLD_START_2             ; $1666  F0 10
        LDA $D0                      ; $1668  A5 D0
        BEQ COLD_START_2             ; $166A  F0 0C
        LDA $E5                      ; $166C  A5 E5
        LDX $E4                      ; $166E  A6 E4
        JSR $F941                    ; $1670  20 41 F9
        LDA #$3A                     ; $1673  A9 3A
        JSR $1A35                    ; $1675  20 35 1A
COLD_START_2:
        LDA $0200                    ; $1678  AD 00 02
        CMP #$2A                     ; $167B  C9 2A
        BEQ COLD_START_3             ; $167D  F0 04
        CMP #$3B                     ; $167F  C9 3B
        BNE COLD_START_4             ; $1681  D0 03
COLD_START_3:
        JMP $12F7                    ; $1683  4C F7 12
COLD_START_4:
        CMP #$20                     ; $1686  C9 20
        BEQ COLD_START_6                   ; $1688  F0 10
        LDY #$00                     ; $168A  A0 00
        LDA $0200,Y                  ; $168C  B9 00 02
        STA $0256,Y                  ; $168F  99 56 02
        INY                          ; $1692  C8
        CMP #$20                     ; $1693  C9 20
        BNE COLD_START_5                   ; $1695  D0 00
COLD_START_5:
        .byte   $01, $98, $99                                    ; $1697
COLD_START_6:
        .byte   $02, $03, $9C, $04, $05, $06, $A0, $A1, $A2, $A3, $A4, $A5, $07, $08, $A8, $A9 ; $169A
        .byte   $AA, $09, $0A, $0B, $0C, $0D, $B0, $B1, $0E, $0F, $10, $11, $12, $13, $B8, $14 ; $16AA
        .byte   $15, $16, $17, $18, $19, $1A, $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9 ; $16BA
        .byte   $CA, $1B, $CC, $1C, $1D, $1E, $D0, $D1, $D2, $1F, $D4, $D5, $20, $21, $D8, $22 ; $16CA
        .byte   $23, $24, $25, $26, $27, $28, $E0, $E1, $E2, $E3, $E4, $29, $2A, $2B, $E8, $2C ; $16DA
        .byte   $2D, $2E                                         ; $16EA
COLD_START_7:
        .byte   $2F, $30, $31, $32, $F0, $F1, $33, $34, $35, $36, $37, $38, $F8, $39, $3A, $3B ; $16EC
        .byte   $3C, $3D, $3E, $3F                               ; $16FC
FORMAT_DRIVER:
        PHP                          ; $1700  08
        SEI                          ; $1701  78
        JSR DRIVE_SETUP              ; $1702  20 07 17
        PLP                          ; $1705  28
        RTS                          ; $1706  60
DRIVE_SETUP:
        LDY #$02                     ; $1707  A0 02
        STY $06F8                    ; $1709  8C F8 06
        LDY #$04                     ; $170C  A0 04
        STY $04F8                    ; $170E  8C F8 04
        LDA $03E6                    ; $1711  AD E6 03
        TAX                          ; $1714  AA
        CMP $03E7                    ; $1715  CD E7 03
        BEQ DRIVE_SETUP_3            ; $1718  F0 1D
        TXA                          ; $171A  8A
        PHA                          ; $171B  48
        LDA $03E7                    ; $171C  AD E7 03
        TAX                          ; $171F  AA
        PLA                          ; $1720  68
        PHA                          ; $1721  48
        STA $03E7                    ; $1722  8D E7 03
        LDA $C08E,X                  ; $1725  BD 8E C0
DRIVE_SETUP_1:
        LDY #$08                     ; $1728  A0 08
        LDA $C08C,X                  ; $172A  BD 8C C0
DRIVE_SETUP_2:
        CMP $C08C,X                  ; $172D  DD 8C C0
        BNE DRIVE_SETUP_1            ; $1730  D0 F6
        DEY                          ; $1732  88
        BNE DRIVE_SETUP_2            ; $1733  D0 F8
        PLA                          ; $1735  68
        TAX                          ; $1736  AA
DRIVE_SETUP_3:
        LDA $C08E,X                  ; $1737  BD 8E C0
        LDA $C08C,X                  ; $173A  BD 8C C0
        LDY #$08                     ; $173D  A0 08
DRIVE_SETUP_4:
        LDA $C08C,X                  ; $173F  BD 8C C0
        PHA                          ; $1742  48
        PLA                          ; $1743  68
        STX $05F8                    ; $1744  8E F8 05
        CMP $C08C,X                  ; $1747  DD 8C C0
        BNE DRIVE_SETUP_5            ; $174A  D0 03
        DEY                          ; $174C  88
        BNE DRIVE_SETUP_4            ; $174D  D0 F0
DRIVE_SETUP_5:
        PHP                          ; $174F  08
        LDA $C089,X                  ; $1750  BD 89 C0
        LDA #$EF                     ; $1753  A9 EF
        STA $46                      ; $1755  85 46
        LDA #$D8                     ; $1757  A9 D8
        STA $47                      ; $1759  85 47
        LDA $03E4                    ; $175B  AD E4 03
        CMP $03E5                    ; $175E  CD E5 03
        BEQ DRIVE_SETUP_6            ; $1761  F0 07
        STA $03E5                    ; $1763  8D E5 03
        PLP                          ; $1766  28
        LDY #$00                     ; $1767  A0 00
        PHP                          ; $1769  08
DRIVE_SETUP_6:
        ROR                          ; $176A  6A
        BCC DRIVE_SETUP_7            ; $176B  90 05
        LDA $C08A,X                  ; $176D  BD 8A C0
        BCS DRIVE_SETUP_8            ; $1770  B0 03
DRIVE_SETUP_7:
        LDA $C08B,X                  ; $1772  BD 8B C0
DRIVE_SETUP_8:
        ROR $35                      ; $1775  66 35
        PLP                          ; $1777  28
        PHP                          ; $1778  08
        BNE DRIVE_SETUP_10           ; $1779  D0 08
        LDY #$07                     ; $177B  A0 07
DRIVE_SETUP_9:
        JSR STEP_DELAY               ; $177D  20 BC 15
        DEY                          ; $1780  88
        BNE DRIVE_SETUP_9            ; $1781  D0 FA
DRIVE_SETUP_10:
        LDX $05F8                    ; $1783  AE F8 05
        PLP                          ; $1786  28
        BNE DRIVE_SETUP_13           ; $1787  D0 0D
DRIVE_SETUP_11:
        LDY #$12                     ; $1789  A0 12
DRIVE_SETUP_12:
        DEY                          ; $178B  88
        BNE DRIVE_SETUP_12           ; $178C  D0 FD
        INC $46                      ; $178E  E6 46
        BNE DRIVE_SETUP_11           ; $1790  D0 F7
        INC $47                      ; $1792  E6 47
        BNE DRIVE_SETUP_11           ; $1794  D0 F3
DRIVE_SETUP_13:
        JMP FORMAT_TRACK             ; $1796  4C DA 17
BUF_SWAP_1:
        PHA                          ; $1799  48
        JSR SLOT_TO_INDEX            ; $179A  20 BA 17
        LDA $0478,Y                  ; $179D  B9 78 04
        BIT $35                      ; $17A0  24 35
        BMI BUF_SWAP_1_1             ; $17A2  30 03
        LDA $04F8,Y                  ; $17A4  B9 F8 04
BUF_SWAP_1_1:
        STA $0478                    ; $17A7  8D 78 04
        PLA                          ; $17AA  68
        BIT $35                      ; $17AB  24 35
        BMI BUF_SWAP_1_2             ; $17AD  30 05
        STA $04F8,Y                  ; $17AF  99 F8 04
        BPL BUF_SWAP_1_3             ; $17B2  10 03
BUF_SWAP_1_2:
        STA $0478,Y                  ; $17B4  99 78 04
BUF_SWAP_1_3:
        JMP SEEK_TRACK               ; $17B7  4C 5F 15
SLOT_TO_INDEX:
        TXA                          ; $17BA  8A
        LSR                          ; $17BB  4A
        LSR                          ; $17BC  4A
        LSR                          ; $17BD  4A
        LSR                          ; $17BE  4A
        TAY                          ; $17BF  A8
        RTS                          ; $17C0  60
BUF_SELECT:
        PHA                          ; $17C1  48
        LDA $03E4                    ; $17C2  AD E4 03
        ROR                          ; $17C5  6A
        ROR $35                      ; $17C6  66 35
        JSR SLOT_TO_INDEX            ; $17C8  20 BA 17
        PLA                          ; $17CB  68
        ASL                          ; $17CC  0A
        BIT $35                      ; $17CD  24 35
        BMI BUF_SELECT_1             ; $17CF  30 05
        STA $04F8,Y                  ; $17D1  99 F8 04
        BPL BUF_SELECT_2             ; $17D4  10 03
BUF_SELECT_1:
        STA $0478,Y                  ; $17D6  99 78 04
BUF_SELECT_2:
        RTS                          ; $17D9  60
FORMAT_TRACK:
        LDA #$CD                     ; $17DA  A9 CD
        STA $2F                      ; $17DC  85 2F
        LDA #$AA                     ; $17DE  A9 AA
        STA $50                      ; $17E0  85 50
        LDY #$00                     ; $17E2  A0 00
        LDA #$39                     ; $17E4  A9 39
FORMAT_TRACK_1:
        STA $1B00,Y                  ; $17E6  99 00 1B
        DEY                          ; $17E9  88
        BNE FORMAT_TRACK_1           ; $17EA  D0 FA
        LDY #$56                     ; $17EC  A0 56
        LDA #$2A                     ; $17EE  A9 2A
FORMAT_TRACK_2:
        STA $1BFF,Y                  ; $17F0  99 FF 1B
        DEY                          ; $17F3  88
        BNE FORMAT_TRACK_2           ; $17F4  D0 FA
        STY $41                      ; $17F6  84 41
        LDA #$50                     ; $17F8  A9 50
        JSR BUF_SELECT               ; $17FA  20 C1 17
        LDA #$26                     ; $17FD  A9 26
        STA $51                      ; $17FF  85 51
FORMAT_TRACK_3:
        LDA $41                      ; $1801  A5 41
        ASL                          ; $1803  0A
        JSR BUF_SWAP_1               ; $1804  20 99 17
        JSR FORMAT_PASS              ; $1807  20 3E 18
FORMAT_TRACK_4:
        LDA #$40                     ; $180A  A9 40
        BCS FORMAT_TRACK_6           ; $180C  B0 23
        LDA #$30                     ; $180E  A9 30
        STA $0578                    ; $1810  8D 78 05
FORMAT_TRACK_5:
        SEC                          ; $1813  38
        DEC $0578                    ; $1814  CE 78 05
        BEQ FORMAT_TRACK_4           ; $1817  F0 F1
        JSR SYNC_D5AA                ; $1819  20 03 15
        BCS FORMAT_TRACK_5           ; $181C  B0 F5
        LDA $2D                      ; $181E  A5 2D
        BNE FORMAT_TRACK_5           ; $1820  D0 F1
        JSR READ_DATA_FIELD          ; $1822  20 9B 14
        BCS FORMAT_TRACK_5           ; $1825  B0 EC
        INC $41                      ; $1827  E6 41
        LDA $41                      ; $1829  A5 41
        CMP #$23                     ; $182B  C9 23
        BCC FORMAT_TRACK_3           ; $182D  90 D2
        LDA #$00                     ; $182F  A9 00
FORMAT_TRACK_6:
        STA $03EA                    ; $1831  8D EA 03
        LDA $C088,X                  ; $1834  BD 88 C0
        RTS                          ; $1837  60
FORMAT_TRACK_7:
        PLA                          ; $1838  68
        PLA                          ; $1839  68
        LDA #$10                     ; $183A  A9 10
        BNE FORMAT_TRACK_6           ; $183C  D0 F3
FORMAT_PASS:
        JMP FORMAT_PASS_INIT         ; $183E  4C 64 19
FORMAT_PASS_1:
        NOP                          ; $1841  EA
FORMAT_PASS_2:
        LDY $51                      ; $1842  A4 51
FORMAT_PASS_3:
        JSR WRITE_ADDR_FIELD         ; $1844  20 E1 18
        BCS FORMAT_TRACK_7           ; $1847  B0 EF
        JSR WRITE_DATA_FIELD         ; $1849  20 03 14
        BCS FORMAT_PASS_11           ; $184C  B0 62
        INC $52                      ; $184E  E6 52
        LDA $52                      ; $1850  A5 52
        CMP #$10                     ; $1852  C9 10
        BCC FORMAT_PASS_2            ; $1854  90 EC
        LDY #$0F                     ; $1856  A0 0F
        STY $52                      ; $1858  84 52
        LDA #$30                     ; $185A  A9 30
        STA $0578                    ; $185C  8D 78 05
FORMAT_PASS_4:
        STA CLEAR_CARRY_RET_1,Y                 ; $185F  99 D1 18
        DEY                          ; $1862  88
        BPL FORMAT_PASS_4            ; $1863  10 FA
        LDY $51                      ; $1865  A4 51
FORMAT_PASS_5:
        JSR CLEAR_CARRY_RET          ; $1867  20 CF 18
        JSR CLEAR_CARRY_RET          ; $186A  20 CF 18
        PHA                          ; $186D  48
        PLA                          ; $186E  68
        DEY                          ; $186F  88
        BNE FORMAT_PASS_5            ; $1870  D0 F5
        JSR SYNC_D5AA                ; $1872  20 03 15
        BCS FORMAT_PASS_9            ; $1875  B0 23
        LDA $2D                      ; $1877  A5 2D
        BEQ FORMAT_PASS_7            ; $1879  F0 15
        LDA #$10                     ; $187B  A9 10
        CMP $51                      ; $187D  C5 51
        LDA $51                      ; $187F  A5 51
        SBC #$01                     ; $1881  E9 01
        STA $51                      ; $1883  85 51
        CMP #$05                     ; $1885  C9 05
        BCS FORMAT_PASS_9            ; $1887  B0 11
        SEC                          ; $1889  38
        RTS                          ; $188A  60
FORMAT_PASS_6:
        JSR SYNC_D5AA                ; $188B  20 03 15
        BCS FORMAT_PASS_8            ; $188E  B0 05
FORMAT_PASS_7:
        JSR READ_DATA_FIELD          ; $1890  20 9B 14
        BCC FORMAT_PASS_12           ; $1893  90 1C
FORMAT_PASS_8:
        DEC $0578                    ; $1895  CE 78 05
        BNE FORMAT_PASS_6            ; $1898  D0 F1
FORMAT_PASS_9:
        JSR SYNC_D5AA                ; $189A  20 03 15
        BCS FORMAT_PASS_10           ; $189D  B0 0B
        LDA $2D                      ; $189F  A5 2D
        CMP #$0F                     ; $18A1  C9 0F
        BNE FORMAT_PASS_10           ; $18A3  D0 05
        JSR READ_DATA_FIELD          ; $18A5  20 9B 14
        BCC FORMAT_PASS              ; $18A8  90 94
FORMAT_PASS_10:
        DEC $0578                    ; $18AA  CE 78 05
        BNE FORMAT_PASS_9            ; $18AD  D0 EB
        SEC                          ; $18AF  38
FORMAT_PASS_11:
        RTS                          ; $18B0  60
FORMAT_PASS_12:
        LDY $2D                      ; $18B1  A4 2D
        LDA CLEAR_CARRY_RET_1,Y                 ; $18B3  B9 D1 18
        BMI FORMAT_PASS_8            ; $18B6  30 DD
        LDA #$FF                     ; $18B8  A9 FF
        STA CLEAR_CARRY_RET_1,Y                 ; $18BA  99 D1 18
        DEC $52                      ; $18BD  C6 52
        BPL FORMAT_PASS_6            ; $18BF  10 CA
        LDA $41                      ; $18C1  A5 41
        BNE CLEAR_CARRY_RET          ; $18C3  D0 0A
        LDA $51                      ; $18C5  A5 51
        CMP #$10                     ; $18C7  C9 10
        BCC FORMAT_PASS_11           ; $18C9  90 E5
        DEC $51                      ; $18CB  C6 51
        DEC $51                      ; $18CD  C6 51
CLEAR_CARRY_RET:                                              ; CLC/RTS success stub: clear carry (= OK) and return
        CLC                          ; $18CF  18
        RTS                          ; $18D0  60
CLEAR_CARRY_RET_1:
        .byte   $3B, $F0, $52, $C8, $C0, $10, $B0, $0D, $B9, $00, $02, $20, $35, $1A, $C9, $20 ; $18D1
WRITE_ADDR_FIELD:
        SEC                          ; $18E1  38
        LDA $C08D,X                  ; $18E2  BD 8D C0
        LDA $C08E,X                  ; $18E5  BD 8E C0
        BMI WRITE_ADDR_FIELD_2       ; $18E8  30 58
        LDA #$FF                     ; $18EA  A9 FF
        STA $C08F,X                  ; $18EC  9D 8F C0
        CMP $C08C,X                  ; $18EF  DD 8C C0
        PHA                          ; $18F2  48
        PLA                          ; $18F3  68
        NOP                          ; $18F4  EA
        NOP                          ; $18F5  EA
WRITE_ADDR_FIELD_1:
        PHA                          ; $18F6  48
        PLA                          ; $18F7  68
        JSR WR_NIB_PHA               ; $18F8  20 92 14
        DEY                          ; $18FB  88
        BNE WRITE_ADDR_FIELD_1       ; $18FC  D0 F8
        LDA #$D5                     ; $18FE  A9 D5
        JSR WR_NIB_CLC               ; $1900  20 91 14
        LDA #$AA                     ; $1903  A9 AA
        JSR WR_NIB_CLC               ; $1905  20 91 14
        LDA #$96                     ; $1908  A9 96
        JSR WR_NIB_CLC               ; $190A  20 91 14
        LDA $2F                      ; $190D  A5 2F
        JSR WR_NIB_44                ; $190F  20 49 19
        LDA $41                      ; $1912  A5 41
        JSR WR_NIB_44                ; $1914  20 49 19
        LDA $52                      ; $1917  A5 52
        JSR WR_NIB_44                ; $1919  20 49 19
        LDA $2F                      ; $191C  A5 2F
        EOR $41                      ; $191E  45 41
        EOR $52                      ; $1920  45 52
        PHA                          ; $1922  48
        LSR                          ; $1923  4A
        ORA $50                      ; $1924  05 50
        STA $C08D,X                  ; $1926  9D 8D C0
        LDA $C08C,X                  ; $1929  BD 8C C0
        PLA                          ; $192C  68
        ORA #$AA                     ; $192D  09 AA
        JSR WR_NIB_44_EVEN           ; $192F  20 59 19
        LDA #$DE                     ; $1932  A9 DE
        JSR WR_NIB_CLC               ; $1934  20 91 14
        LDA #$AA                     ; $1937  A9 AA
        JSR WR_NIB_CLC               ; $1939  20 91 14
        LDA #$EB                     ; $193C  A9 EB
        JSR WR_NIB_CLC               ; $193E  20 91 14
        CLC                          ; $1941  18
WRITE_ADDR_FIELD_2:
        LDA $C08E,X                  ; $1942  BD 8E C0
        LDA $C08C,X                  ; $1945  BD 8C C0
        RTS                          ; $1948  60
WR_NIB_44:
        PHA                          ; $1949  48
        LSR                          ; $194A  4A
        ORA $50                      ; $194B  05 50
        STA $C08D,X                  ; $194D  9D 8D C0
        CMP $C08C,X                  ; $1950  DD 8C C0
        PLA                          ; $1953  68
        NOP                          ; $1954  EA
        NOP                          ; $1955  EA
        NOP                          ; $1956  EA
        ORA #$AA                     ; $1957  09 AA
WR_NIB_44_EVEN:
        NOP                          ; $1959  EA
        CLC                          ; $195A  18
        PHA                          ; $195B  48
        PLA                          ; $195C  68
        STA $C08D,X                  ; $195D  9D 8D C0
        ORA $C08C,X                  ; $1960  1D 8C C0
        RTS                          ; $1963  60
FORMAT_PASS_INIT:
        LDY #$80                     ; $1964  A0 80
        LDA #$00                     ; $1966  A9 00
        STA $52                      ; $1968  85 52
        JMP FORMAT_PASS_3            ; $196A  4C 44 18
FORMAT_PASS_INIT_1:
        BRK                          ; $196D  00
FORMAT_PASS_INIT_2:
        BRK                          ; $196E  00
FORMAT_PASS_INIT_3:
        JSR $1A35                    ; $196F  20 35 1A
        LDA #$00                     ; $1972  A9 00
        STA $D6                      ; $1974  85 D6
        PLA                          ; $1976  68
        LDX #$00                     ; $1977  A2 00
        STA ($EC,X)                  ; $1979  81 EC
        STA $80                      ; $197B  85 80
        LDA $D1                      ; $197D  A5 D1
        BEQ FORMAT_PASS_INIT_4       ; $197F  F0 0C
        INC $D6                      ; $1981  E6 D6
        LDA #$20                     ; $1983  A9 20
        JSR $1A35                    ; $1985  20 35 1A
        LDA $80                      ; $1988  A5 80
        JSR $FDDA                    ; $198A  20 DA FD
FORMAT_PASS_INIT_4:
        JMP COLD_START_7                   ; $198D  4C EC 16
STRCMP:
        STX $DA                      ; $1990  86 DA
        STY $88                      ; $1992  84 88
        TSX                          ; $1994  BA
        JSR $1A6F                    ; $1995  20 6F 1A
        STA $E2                      ; $1998  85 E2
        JSR $1A6F                    ; $199A  20 6F 1A
        STA $E3                      ; $199D  85 E3
STRCMP_1:
        LDY #$00                     ; $199F  A0 00
        LDX #$00                     ; $19A1  A2 00
STRCMP_2:
        LDA ($E2),Y                  ; $19A3  B1 E2
        BNE STRCMP_3                 ; $19A5  D0 03
        LDY #$01                     ; $19A7  A0 01
        RTS                          ; $19A9  60
STRCMP_3:
        CMP $0210,X                  ; $19AA  DD 10 02
        BNE STRCMP_4                 ; $19AD  D0 07
        INX                          ; $19AF  E8
        INY                          ; $19B0  C8
        CPY $88                      ; $19B1  C4 88
        BNE STRCMP_2                 ; $19B3  D0 EE
        RTS                          ; $19B5  60
STRCMP_4:
        LDA $DA                      ; $19B6  A5 DA
        CLC                          ; $19B8  18
        ADC $E2                      ; $19B9  65 E2
        STA $E2                      ; $19BB  85 E2
        BCC STRCMP_1                 ; $19BD  90 E0
        INC $E3                      ; $19BF  E6 E3
        BNE STRCMP_1                 ; $19C1  D0 DC
        LDA $D0                      ; $19C3  A5 D0
        BEQ STRCMP_5                 ; $19C5  F0 01
        RTS                          ; $19C7  60
STRCMP_5:
        LDX #$00                     ; $19C8  A2 00
        JSR READ_ADDR_FIELD          ; $19CA  20 21 15
        CPY #$FF                     ; $19CD  C0 FF
        BEQ STRCMP_6                 ; $19CF  F0 04
        LDX #$05                     ; $19D1  A2 05
        BNE STRCMP_9                 ; $19D3  D0 14
STRCMP_6:
        LDA $E9                      ; $19D5  A5 E9
        CMP $73                      ; $19D7  C5 73
        BCC STRCMP_7                 ; $19D9  90 06
        LDA $E8                      ; $19DB  A5 E8
        CMP $72                      ; $19DD  C5 72
        BCS STRCMP_8                 ; $19DF  B0 06
STRCMP_7:
        JSR WRITE_DATA_EPILOGUE      ; $19E1  20 78 14
        JMP WRITE_DATA_FIELD_2+2     ; $19E4  4C 34 14
STRCMP_8:
        LDX #$06                     ; $19E7  A2 06
STRCMP_9:
        JMP CMD_CHECK_3                   ; $19E9  4C 18 16
STRCMP_10:
        LDY #$00                     ; $19EC  A0 00
        LDA ($E8),Y                  ; $19EE  B1 E8
        BEQ STRCMP_11                ; $19F0  F0 06
        JSR PUT_NIBBLE_2             ; $19F2  20 61 14
        JMP WRITE_DATA_FIELD_2+2     ; $19F5  4C 34 14
STRCMP_11:
        LDX #$00                     ; $19F8  A2 00
        LDA $87                      ; $19FA  A5 87
        STA ($E8),Y                  ; $19FC  91 E8
        INY                          ; $19FE  C8
        .byte   $BD                                              ; $19FF
