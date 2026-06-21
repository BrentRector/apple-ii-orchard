; ============================================================================
; RW13_6502.s -- embedded 6502 13-sector disk engine of the RW13.COM utility
; ----------------------------------------------------------------------------
; 1792 bytes that RW13.COM carries as 6502 machine code. RW13 ("13 Sector Disk
; Conversion", Microsoft 1980) runs on the Z-80; this engine runs on the 6502
; (SoftCard CPU switch), so from the Z-80 it is opaque data. Rather than bury it
; as a DEFB blob, it is disassembled as real 6502 and assembled separately with
; ca65; RW13.asm INCBINs the byte-identical binary.
;
; Staging vs run address: the block sits at Z-80 $0300 inside the .COM. The Z-80
; install path points the 6502 vector A$VEC ($F3D0) at $1300 (LD HL,$1300 /
; LD ($F3D0),HL at RW13.asm $0198), so this code RUNS at Apple 6502 $1300-$19FF.
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-subroutine-call (RPC)
; mechanism: the Z-80 stores the 6502 target at A$VEC (0F3D0H) and writes Z$CPU
; (0F3DEH) to run it; results come back through the page-3 cells. The new BIOS
; 13-sector sector handler the Z-80 installs (RW13.asm $018F-$01A1) re-enters
; this engine through that vector for every read/write.
;
; What it is, by routine:
;   $1300  RELOCATE_PATCH -- relocate the saved 16-sector handler ($0E09/$0E0A)
;          into the 13-sector driver's call sites, scan/patch the handler's own
;          jump-table operands (PATCH_SCAN), then JMP the Apple Monitor MOVE
;          ($FE2C) to copy the engine into its resident BIOS slot.
;   $1383  PATCH_SCAN -- walk a code range; add the relocation delta ($40) to any
;          jump operand whose high byte is in [$14,$1A) (i.e. an in-engine ref).
;   $1403  PRENIBBLE_WRITE -- pre-nibble a 256-byte sector into the 6-and-2 GCR
;          write buffers ($0900.. and the $1700-block scratch).
;   $146D  WRITE_SECTOR -- write the address+data fields to the Disk II
;          ($C08D/$C08F write switches), emitting nibbles via WRITE_NIBBLE.
;   $1500  READ_SECTOR -- spin on the read latch ($C08C), sync the D5 AA AD data
;          prologue, denibble the 6-and-2 stream into the buffers, check epilogue.
;   $1568  READ_ADDR_FIELD -- sync + read the D5 AA B5 address field (volume,
;          track, sector, checksum) into $002C..; used to find the wanted sector.
;   $15C4  DENIBBLE_SECTOR -- denibble the 6-and-2 buffers back to a 256-byte
;          sector image at ($3E).
;   $1621  SEEK_TRACK -- step the head from the current track ($0478) to the
;          target ($2A) via the $C080,X phase magnets, using the two settle-delay
;          tables STEP_ON_DELAY/STEP_OFF_DELAY and STEP_DELAY.
;   $1800  DISK_DRIVER -- the resident 13-sector RWTS: probe the drive, seek, then
;          dispatch read/write per sector against the 13-sector skew table at
;          $19E0; falls back to the genuine 16-sector handler ($0E06) when not in
;          13-sector mode.
;
; Data sub-regions kept as `.byte` (verified NOT code):
;   $13B4-$13FF  FE/FF scratch band (denibble work area template)
;   $1400-$1402  3-byte self-mod prefix (the Z-80 install plants the two bytes at
;                SELFMOD_TARGET_LO/_HI from $1006/$1007 at RELOCATE_PATCH $1315/$131B)
;   $1693-$16E7  16-sector logical->physical sector-translate table (+ FE/FF tail)
;   $16E8-$1799  FE/FF nibble-assembly scratch (GCR_BUF0/1/2/3 are the three 51-byte
;                GCR work buffers + the odd-bits byte; GCR_BUF0_M1 is the EOR base)
;   $179A-$17B9  6-and-2 valid-nibble write table (AB AD AE ... FF), 32 bytes
;                (WRITE_NIB_TABLE)
;   $17BA-$17D1  two head-stepper on/off settle-delay tables, 12 bytes each
;                (STEP_ON_DELAY / STEP_OFF_DELAY)
;   $17D2-$17FF  FE/FF scratch band before DISK_DRIVER
;   $19AF-$19DF  FE/FF scratch band after the engine
;   $19E0-$19FF  13-sector logical->physical skew table (SKEW_13SEC) + the page-3 RPC
;                param tail ($1A 00 03 07 ... the doorbell/config bytes the Z-80 reads)
;
; NOTE on the 56K reference (CPMV220/utilities/RW13.asm, the 2.20B-56K build of
; the same program): its Z-80 disassembler left three "DEFW" cells inside this
; block ($0689 -> $02D0, $0693 -> $0100, $0944 -> $0815). As REAL 6502 those are
; NOT standalone data words: $0689/$1689 is the BNE in STEP_DELAY's $47-carry
; loop, $0944/$1944 is the operand of "JSR READ_SECTOR" + a PHP, and $0693/$1693
; is the head of the sector-translate table. They are decoded correctly here.
;
; Position-independent w.r.t. its own internals only by way of RELOCATE_PATCH,
; which fixes up the in-engine jump operands at install time; every other
; absolute reference is to a fixed Apple address (zero page, the $0900/$1700
; buffers, the $03Exx page-3 RWTS cells, $C08x slot switches, the Monitor ROM).
; Comments are [AI] inference unless tagged. Reassembles BYTE-IDENTICAL to the
; on-disk block (test_utilities_roundtrip; CPMV220-44K:RW13).
; ============================================================================
.setcpu "6502"
.segment "CODE"

MOVE            = $FE2C         ; Apple II Monitor: move memory (A1..A2)->(A4)

.org $1300

RELOCATE_PATCH:
        LDA $0E09                    ; $1300  AD 09 0E
        STA $1819                    ; $1303  8D 19 18
        STA $03EE                    ; $1306  8D EE 03
        LDA $0E0A                    ; $1309  AD 0A 0E
        STA $181A                    ; $130C  8D 1A 18
        STA $03EF                    ; $130F  8D EF 03
        LDA $1006                    ; $1312  AD 06 10
        STA SELFMOD_TARGET_LO        ; $1315  8D 01 14
        LDA $1007                    ; $1318  AD 07 10
        STA SELFMOD_TARGET_HI        ; $131B  8D 02 14
        TAY                          ; $131E  A8
        SEC                          ; $131F  38
        SBC #$0E                     ; $1320  E9 0E
        STA $1806                    ; $1322  8D 06 18
        TYA                          ; $1325  98
        CMP #$BE                     ; $1326  C9 BE
        BCC RELOCATE_PATCH_1         ; $1328  90 03
        CLC                          ; $132A  18
        ADC #$10                     ; $132B  69 10
RELOCATE_PATCH_1:
        TAY                          ; $132D  A8
        SEC                          ; $132E  38
        SBC #$12                     ; $132F  E9 12
        STA $40                      ; $1331  85 40
        TYA                          ; $1333  98
        CLC                          ; $1334  18
        ADC #$06                     ; $1335  69 06
        STA $0E0A                    ; $1337  8D 0A 0E
        LDY #$00                     ; $133A  A0 00
        STY $0E09                    ; $133C  8C 09 0E
        LDA #$03                     ; $133F  A9 03
        LDY #$14                     ; $1341  A0 14
        STA $3C                      ; $1343  85 3C
        STY $3D                      ; $1345  84 3D
        LDA #$93                     ; $1347  A9 93
        LDY #$16                     ; $1349  A0 16
        STA $3E                      ; $134B  85 3E
        STY $3F                      ; $134D  84 3F
        JSR PATCH_SCAN               ; $134F  20 83 13
        LDA #$00                     ; $1352  A9 00
        LDY #$18                     ; $1354  A0 18
        STA $3C                      ; $1356  85 3C
        STY $3D                      ; $1358  84 3D
        LDA #$AF                     ; $135A  A9 AF
        LDY #$19                     ; $135C  A0 19
        STA $3E                      ; $135E  85 3E
        STY $3F                      ; $1360  84 3F
        JSR PATCH_SCAN               ; $1362  20 83 13
        LDA #$00                     ; $1365  A9 00
        LDY #$14                     ; $1367  A0 14
        STA $3C                      ; $1369  85 3C
        STY $3D                      ; $136B  84 3D
        LDA #$FE                     ; $136D  A9 FE
        LDY #$19                     ; $136F  A0 19
        STA $3E                      ; $1371  85 3E
        STY $3F                      ; $1373  84 3F
        LDA #$14                     ; $1375  A9 14
        CLC                          ; $1377  18
        ADC $40                      ; $1378  65 40
        STA $43                      ; $137A  85 43
        LDY #$00                     ; $137C  A0 00
        STY $42                      ; $137E  84 42
        JMP MOVE                     ; $1380  4C 2C FE
PATCH_SCAN:
        LDY #$00                     ; $1383  A0 00
        LDA ($3C),Y                  ; $1385  B1 3C
        JSR $F88E                    ; $1387  20 8E F8
        LDA $2F                      ; $138A  A5 2F
        CMP #$02                     ; $138C  C9 02
        BCC PATCH_SCAN_1             ; $138E  90 10
        LDY #$02                     ; $1390  A0 02
        LDA ($3C),Y                  ; $1392  B1 3C
        CMP #$14                     ; $1394  C9 14
        BCC PATCH_SCAN_1             ; $1396  90 08
        CMP #$1A                     ; $1398  C9 1A
        BCS PATCH_SCAN_1             ; $139A  B0 04
        ADC $40                      ; $139C  65 40
        STA ($3C),Y                  ; $139E  91 3C
PATCH_SCAN_1:
        LDA $2F                      ; $13A0  A5 2F
        SEC                          ; $13A2  38
        ADC $3C                      ; $13A3  65 3C
        STA $3C                      ; $13A5  85 3C
        BCC PATCH_SCAN_2             ; $13A7  90 02
        INC $3D                      ; $13A9  E6 3D
PATCH_SCAN_2:
        CMP $3E                      ; $13AB  C5 3E
        LDA $3D                      ; $13AD  A5 3D
        SBC $3F                      ; $13AF  E5 3F
        BCC PATCH_SCAN               ; $13B1  90 D0
        RTS                          ; $13B3  60
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $13B4
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $13C4
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $13D4
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $13E4
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $C3 ; $13F4
SELFMOD_TARGET_LO:
        .byte   $06                                              ; $1401
SELFMOD_TARGET_HI:
        .byte   $9C                                              ; $1402
PRENIBBLE_WRITE:
        LDX #$32                     ; $1403  A2 32
        LDY #$00                     ; $1405  A0 00
PRENIBBLE_WRITE_1:
        LDA ($3E),Y                  ; $1407  B1 3E
        STA $26                      ; $1409  85 26
        LSR                          ; $140B  4A
        LSR                          ; $140C  4A
        LSR                          ; $140D  4A
        STA $0900,X                  ; $140E  9D 00 09
        INY                          ; $1411  C8
        LDA ($3E),Y                  ; $1412  B1 3E
        STA $27                      ; $1414  85 27
        LSR                          ; $1416  4A
        LSR                          ; $1417  4A
        LSR                          ; $1418  4A
        STA $0933,X                  ; $1419  9D 33 09
        INY                          ; $141C  C8
        LDA ($3E),Y                  ; $141D  B1 3E
        STA $2A                      ; $141F  85 2A
        LSR                          ; $1421  4A
        LSR                          ; $1422  4A
        LSR                          ; $1423  4A
        STA $0966,X                  ; $1424  9D 66 09
        INY                          ; $1427  C8
        LDA ($3E),Y                  ; $1428  B1 3E
        LSR                          ; $142A  4A
        ROL $2A                      ; $142B  26 2A
        LSR                          ; $142D  4A
        ROL $27                      ; $142E  26 27
        LSR                          ; $1430  4A
        ROL $26                      ; $1431  26 26
        STA $0999,X                  ; $1433  9D 99 09
        INY                          ; $1436  C8
        LDA ($3E),Y                  ; $1437  B1 3E
        LSR                          ; $1439  4A
        ROL $2A                      ; $143A  26 2A
        LSR                          ; $143C  4A
        ROL $27                      ; $143D  26 27
        LSR                          ; $143F  4A
        STA $09CC,X                  ; $1440  9D CC 09
        LDA $26                      ; $1443  A5 26
        ROL                          ; $1445  2A
        AND #$1F                     ; $1446  29 1F
        STA GCR_BUF0,X                 ; $1448  9D 00 17
        LDA $27                      ; $144B  A5 27
        AND #$1F                     ; $144D  29 1F
        STA GCR_BUF1,X                 ; $144F  9D 33 17
        LDA $2A                      ; $1452  A5 2A
        AND #$1F                     ; $1454  29 1F
        STA GCR_BUF2,X                 ; $1456  9D 66 17
        INY                          ; $1459  C8
        DEX                          ; $145A  CA
        BPL PRENIBBLE_WRITE_1        ; $145B  10 AA
        LDA ($3E),Y                  ; $145D  B1 3E
        TAX                          ; $145F  AA
        AND #$07                     ; $1460  29 07
        STA GCR_BUF3                   ; $1462  8D 99 17
        TXA                          ; $1465  8A
        LSR                          ; $1466  4A
        LSR                          ; $1467  4A
        LSR                          ; $1468  4A
        STA $09FF                    ; $1469  8D FF 09
        RTS                          ; $146C  60
WRITE_SECTOR:
        SEC                          ; $146D  38
        LDA $C08D,X                  ; $146E  BD 8D C0
        LDA $C08E,X                  ; $1471  BD 8E C0
        BMI WRITE_SECTOR_5           ; $1474  30 7C
        STX $27                      ; $1476  86 27
        STX $0678                    ; $1478  8E 78 06
        LDA GCR_BUF0                   ; $147B  AD 00 17
        STA $26                      ; $147E  85 26
        LDA #$FF                     ; $1480  A9 FF
        STA $C08F,X                  ; $1482  9D 8F C0
        ORA $C08C,X                  ; $1485  1D 8C C0
        PHA                          ; $1488  48
        PLA                          ; $1489  68
        NOP                          ; $148A  EA
        LDY #$04                     ; $148B  A0 04
WRITE_SECTOR_1:
        PHA                          ; $148D  48
        PLA                          ; $148E  68
        JSR WRITE_NIBBLE_2                 ; $148F  20 F7 14
        DEY                          ; $1492  88
        BNE WRITE_SECTOR_1           ; $1493  D0 F8
        LDA #$D5                     ; $1495  A9 D5
        JSR WRITE_NIBBLE             ; $1497  20 F6 14
        LDA #$AA                     ; $149A  A9 AA
        JSR WRITE_NIBBLE             ; $149C  20 F6 14
        LDA #$AD                     ; $149F  A9 AD
        JSR WRITE_NIBBLE             ; $14A1  20 F6 14
        TYA                          ; $14A4  98
        LDY #$9A                     ; $14A5  A0 9A
        BNE WRITE_SECTOR_3           ; $14A7  D0 03
WRITE_SECTOR_2:
        LDA GCR_BUF0,Y                 ; $14A9  B9 00 17
WRITE_SECTOR_3:
        EOR GCR_BUF0_M1,Y                 ; $14AC  59 FF 16
        TAX                          ; $14AF  AA
        LDA WRITE_NIB_TABLE,X                 ; $14B0  BD 9A 17
        LDX $27                      ; $14B3  A6 27
        STA $C08D,X                  ; $14B5  9D 8D C0
        LDA $C08C,X                  ; $14B8  BD 8C C0
        DEY                          ; $14BB  88
        BNE WRITE_SECTOR_2           ; $14BC  D0 EB
        LDA $26                      ; $14BE  A5 26
        NOP                          ; $14C0  EA
WRITE_SECTOR_4:
        EOR $0900,Y                  ; $14C1  59 00 09
        TAX                          ; $14C4  AA
        LDA WRITE_NIB_TABLE,X                 ; $14C5  BD 9A 17
        LDX $0678                    ; $14C8  AE 78 06
        STA $C08D,X                  ; $14CB  9D 8D C0
        LDA $C08C,X                  ; $14CE  BD 8C C0
        LDA $0900,Y                  ; $14D1  B9 00 09
        INY                          ; $14D4  C8
        BNE WRITE_SECTOR_4           ; $14D5  D0 EA
        TAX                          ; $14D7  AA
        LDA WRITE_NIB_TABLE,X                 ; $14D8  BD 9A 17
        LDX $27                      ; $14DB  A6 27
        JSR WRITE_NIBBLE_3                 ; $14DD  20 F9 14
        LDA #$DE                     ; $14E0  A9 DE
        JSR WRITE_NIBBLE             ; $14E2  20 F6 14
        LDA #$AA                     ; $14E5  A9 AA
        JSR WRITE_NIBBLE             ; $14E7  20 F6 14
        LDA #$EB                     ; $14EA  A9 EB
        JSR WRITE_NIBBLE             ; $14EC  20 F6 14
        LDA $C08E,X                  ; $14EF  BD 8E C0
WRITE_SECTOR_5:
        LDA $C08C,X                  ; $14F2  BD 8C C0
        RTS                          ; $14F5  60
WRITE_NIBBLE:
        CLC                          ; $14F6  18
WRITE_NIBBLE_2:
        PHA                          ; $14F7  48
        PLA                          ; $14F8  68
WRITE_NIBBLE_3:
        STA $C08D,X                  ; $14F9  9D 8D C0
        ORA $C08C,X                  ; $14FC  1D 8C C0
        RTS                          ; $14FF  60
READ_SECTOR:
        LDY #$20                     ; $1500  A0 20
READ_SECTOR_1:
        DEY                          ; $1502  88
        BEQ READ_SECTOR_13           ; $1503  F0 61
READ_SECTOR_2:
        LDA $C08C,X                  ; $1505  BD 8C C0
        BPL READ_SECTOR_2            ; $1508  10 FB
READ_SECTOR_3:
        EOR #$D5                     ; $150A  49 D5
        BNE READ_SECTOR_1            ; $150C  D0 F4
        NOP                          ; $150E  EA
READ_SECTOR_4:
        LDA $C08C,X                  ; $150F  BD 8C C0
        BPL READ_SECTOR_4            ; $1512  10 FB
        CMP #$AA                     ; $1514  C9 AA
        BNE READ_SECTOR_3            ; $1516  D0 F2
        LDY #$9A                     ; $1518  A0 9A
READ_SECTOR_5:
        LDA $C08C,X                  ; $151A  BD 8C C0
        BPL READ_SECTOR_5            ; $151D  10 FB
        CMP #$AD                     ; $151F  C9 AD
        BNE READ_SECTOR_3            ; $1521  D0 E7
        LDA #$00                     ; $1523  A9 00
READ_SECTOR_6:
        DEY                          ; $1525  88
        STY $26                      ; $1526  84 26
READ_SECTOR_7:
        LDY $C08C,X                  ; $1528  BC 8C C0
        BPL READ_SECTOR_7            ; $152B  10 FB
        EOR $15E8,Y                  ; $152D  59 E8 15
        LDY $26                      ; $1530  A4 26
        STA GCR_BUF0,Y                 ; $1532  99 00 17
        BNE READ_SECTOR_6            ; $1535  D0 EE
READ_SECTOR_8:
        STY $26                      ; $1537  84 26
READ_SECTOR_9:
        LDY $C08C,X                  ; $1539  BC 8C C0
        BPL READ_SECTOR_9            ; $153C  10 FB
        EOR $15E8,Y                  ; $153E  59 E8 15
        LDY $26                      ; $1541  A4 26
        STA $0900,Y                  ; $1543  99 00 09
        INY                          ; $1546  C8
        BNE READ_SECTOR_8            ; $1547  D0 EE
READ_SECTOR_10:
        LDY $C08C,X                  ; $1549  BC 8C C0
        BPL READ_SECTOR_10           ; $154C  10 FB
        CMP $15E8,Y                  ; $154E  D9 E8 15
        BNE READ_SECTOR_13           ; $1551  D0 13
READ_SECTOR_11:
        LDA $C08C,X                  ; $1553  BD 8C C0
        BPL READ_SECTOR_11           ; $1556  10 FB
        CMP #$DE                     ; $1558  C9 DE
        BNE READ_SECTOR_13           ; $155A  D0 0A
        NOP                          ; $155C  EA
READ_SECTOR_12:
        LDA $C08C,X                  ; $155D  BD 8C C0
        BPL READ_SECTOR_12           ; $1560  10 FB
        CMP #$AA                     ; $1562  C9 AA
        BEQ READ_ADDR_FIELD_11       ; $1564  F0 5C
READ_SECTOR_13:
        SEC                          ; $1566  38
        RTS                          ; $1567  60
READ_ADDR_FIELD:
        LDY #$F8                     ; $1568  A0 F8
        STY $26                      ; $156A  84 26
READ_ADDR_FIELD_1:
        INY                          ; $156C  C8
        BNE READ_ADDR_FIELD_2        ; $156D  D0 04
        INC $26                      ; $156F  E6 26
        BEQ READ_SECTOR_13           ; $1571  F0 F3
READ_ADDR_FIELD_2:
        LDA $C08C,X                  ; $1573  BD 8C C0
        BPL READ_ADDR_FIELD_2        ; $1576  10 FB
READ_ADDR_FIELD_3:
        CMP #$D5                     ; $1578  C9 D5
        BNE READ_ADDR_FIELD_1        ; $157A  D0 F0
        NOP                          ; $157C  EA
READ_ADDR_FIELD_4:
        LDA $C08C,X                  ; $157D  BD 8C C0
        BPL READ_ADDR_FIELD_4        ; $1580  10 FB
        CMP #$AA                     ; $1582  C9 AA
        BNE READ_ADDR_FIELD_3        ; $1584  D0 F2
        LDY #$03                     ; $1586  A0 03
READ_ADDR_FIELD_5:
        LDA $C08C,X                  ; $1588  BD 8C C0
        BPL READ_ADDR_FIELD_5        ; $158B  10 FB
        CMP #$B5                     ; $158D  C9 B5
        BNE READ_ADDR_FIELD_3        ; $158F  D0 E7
        LDA #$00                     ; $1591  A9 00
READ_ADDR_FIELD_6:
        STA $27                      ; $1593  85 27
READ_ADDR_FIELD_7:
        LDA $C08C,X                  ; $1595  BD 8C C0
        BPL READ_ADDR_FIELD_7        ; $1598  10 FB
        ROL                          ; $159A  2A
        STA $26                      ; $159B  85 26
READ_ADDR_FIELD_8:
        LDA $C08C,X                  ; $159D  BD 8C C0
        BPL READ_ADDR_FIELD_8        ; $15A0  10 FB
        AND $26                      ; $15A2  25 26
        STA a:$002C,Y                ; $15A4  99 2C 00
        EOR $27                      ; $15A7  45 27
        DEY                          ; $15A9  88
        BPL READ_ADDR_FIELD_6        ; $15AA  10 E7
        TAY                          ; $15AC  A8
        BNE READ_SECTOR_13           ; $15AD  D0 B7
READ_ADDR_FIELD_9:
        LDA $C08C,X                  ; $15AF  BD 8C C0
        BPL READ_ADDR_FIELD_9        ; $15B2  10 FB
        CMP #$DE                     ; $15B4  C9 DE
        BNE READ_SECTOR_13           ; $15B6  D0 AE
        NOP                          ; $15B8  EA
READ_ADDR_FIELD_10:
        LDA $C08C,X                  ; $15B9  BD 8C C0
        BPL READ_ADDR_FIELD_10       ; $15BC  10 FB
        CMP #$AA                     ; $15BE  C9 AA
        BNE READ_SECTOR_13           ; $15C0  D0 A4
READ_ADDR_FIELD_11:
        CLC                          ; $15C2  18
        RTS                          ; $15C3  60
DENIBBLE_SECTOR:
        LDX #$32                     ; $15C4  A2 32
        LDY #$00                     ; $15C6  A0 00
DENIBBLE_SECTOR_1:
        LDA GCR_BUF0,X                 ; $15C8  BD 00 17
        LSR                          ; $15CB  4A
        LSR                          ; $15CC  4A
        LSR                          ; $15CD  4A
        STA $27                      ; $15CE  85 27
        LSR                          ; $15D0  4A
        STA $26                      ; $15D1  85 26
        LSR                          ; $15D3  4A
        ORA $0900,X                  ; $15D4  1D 00 09
        STA ($3E),Y                  ; $15D7  91 3E
        INY                          ; $15D9  C8
        LDA GCR_BUF1,X                 ; $15DA  BD 33 17
        LSR                          ; $15DD  4A
        LSR                          ; $15DE  4A
        LSR                          ; $15DF  4A
        LSR                          ; $15E0  4A
        ROL $27                      ; $15E1  26 27
        LSR                          ; $15E3  4A
        ROL $26                      ; $15E4  26 26
        ORA $0933,X                  ; $15E6  1D 33 09
        STA ($3E),Y                  ; $15E9  91 3E
        INY                          ; $15EB  C8
        LDA GCR_BUF2,X                 ; $15EC  BD 66 17
        LSR                          ; $15EF  4A
        LSR                          ; $15F0  4A
        LSR                          ; $15F1  4A
        LSR                          ; $15F2  4A
        ROL $27                      ; $15F3  26 27
        LSR                          ; $15F5  4A
        ROL $26                      ; $15F6  26 26
        ORA $0966,X                  ; $15F8  1D 66 09
        STA ($3E),Y                  ; $15FB  91 3E
        INY                          ; $15FD  C8
        LDA $26                      ; $15FE  A5 26
        AND #$07                     ; $1600  29 07
        ORA $0999,X                  ; $1602  1D 99 09
        STA ($3E),Y                  ; $1605  91 3E
        INY                          ; $1607  C8
        LDA $27                      ; $1608  A5 27
        AND #$07                     ; $160A  29 07
        ORA $09CC,X                  ; $160C  1D CC 09
        STA ($3E),Y                  ; $160F  91 3E
        INY                          ; $1611  C8
        DEX                          ; $1612  CA
        BPL DENIBBLE_SECTOR_1        ; $1613  10 B3
        LDA GCR_BUF3                   ; $1615  AD 99 17
        LSR                          ; $1618  4A
        LSR                          ; $1619  4A
        LSR                          ; $161A  4A
        ORA $09FF                    ; $161B  0D FF 09
        STA ($3E),Y                  ; $161E  91 3E
        RTS                          ; $1620  60
SEEK_TRACK:
        STX $2B                      ; $1621  86 2B
        STA $2A                      ; $1623  85 2A
        CMP $0478                    ; $1625  CD 78 04
        BEQ PHASE_SET_1               ; $1628  F0 53
        LDA #$00                     ; $162A  A9 00
        STA $26                      ; $162C  85 26
SEEK_TRACK_1:
        LDA $0478                    ; $162E  AD 78 04
        STA $27                      ; $1631  85 27
        SEC                          ; $1633  38
        SBC $2A                      ; $1634  E5 2A
        BEQ SEEK_TRACK_6             ; $1636  F0 33
        BCS SEEK_TRACK_2             ; $1638  B0 07
        EOR #$FF                     ; $163A  49 FF
        INC $0478                    ; $163C  EE 78 04
        BCC SEEK_TRACK_3             ; $163F  90 05
SEEK_TRACK_2:
        ADC #$FE                     ; $1641  69 FE
        DEC $0478                    ; $1643  CE 78 04
SEEK_TRACK_3:
        CMP $26                      ; $1646  C5 26
        BCC SEEK_TRACK_4             ; $1648  90 02
        LDA $26                      ; $164A  A5 26
SEEK_TRACK_4:
        CMP #$0C                     ; $164C  C9 0C
        BCS SEEK_TRACK_5             ; $164E  B0 01
        TAY                          ; $1650  A8
SEEK_TRACK_5:
        SEC                          ; $1651  38
        JSR PHASE_OFF                ; $1652  20 6F 16
        LDA STEP_ON_DELAY,Y                 ; $1655  B9 BA 17
        JSR STEP_DELAY               ; $1658  20 7E 16
        LDA $27                      ; $165B  A5 27
        CLC                          ; $165D  18
        JSR PHASE_SET                 ; $165E  20 72 16
        LDA STEP_OFF_DELAY,Y                 ; $1661  B9 C6 17
        JSR STEP_DELAY               ; $1664  20 7E 16
        INC $26                      ; $1667  E6 26
        BNE SEEK_TRACK_1             ; $1669  D0 C3
SEEK_TRACK_6:
        JSR STEP_DELAY               ; $166B  20 7E 16
        CLC                          ; $166E  18
PHASE_OFF:
        LDA $0478                    ; $166F  AD 78 04
PHASE_SET:
        AND #$03                     ; $1672  29 03
        ROL                          ; $1674  2A
        ORA $2B                      ; $1675  05 2B
        TAX                          ; $1677  AA
        LDA $C080,X                  ; $1678  BD 80 C0
        LDX $2B                      ; $167B  A6 2B
PHASE_SET_1:
        RTS                          ; $167D  60
STEP_DELAY:
        LDX #$11                     ; $167E  A2 11
STEP_DELAY_1:
        DEX                          ; $1680  CA
        BNE STEP_DELAY_1             ; $1681  D0 FD
        INC $46                      ; $1683  E6 46
        BNE STEP_DELAY_2             ; $1685  D0 06
        INC $47                      ; $1687  E6 47
        BNE STEP_DELAY_2             ; $1689  D0 02
        DEC $47                      ; $168B  C6 47
STEP_DELAY_2:
        SEC                          ; $168D  38
        SBC #$01                     ; $168E  E9 01
        BNE STEP_DELAY               ; $1690  D0 EC
        RTS                          ; $1692  60
        .byte   $00, $01, $08, $10, $18, $02, $03, $04, $05, $06, $20, $28, $30, $07, $09, $38 ; $1693
        .byte   $40, $0A, $48, $50, $58, $0B, $0C, $0D, $0E, $0F, $11, $12, $13, $14, $15, $16 ; $16A3
        .byte   $17, $19, $1A, $1B, $1C, $1D, $1E                ; $16B3
        .byte   $21, $22, $23, $24, $60, $68, $25, $26, $70, $78, $27, $80 ; $16BA  "!"#$`h%&px'"
        .byte   $88, $90, $29, $2A, $2B, $2C, $2D, $2E, $2F, $31, $32, $33, $98, $A0, $34, $A8 ; $16C6
        .byte   $B0, $B8, $35, $36, $37, $39, $3A, $C0, $C8, $D0, $3B, $3C, $D8, $E0, $3E, $E8 ; $16D6
        .byte   $F0, $F8, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $16E6
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE      ; $16F6
GCR_BUF0_M1:                                                     ; [AI] GCR_BUF0-1: EOR running-checksum base for WRITE_SECTOR's `EOR GCR_BUF0_M1,Y`
        .byte   $FE                                              ; $16FF
GCR_BUF0:
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $1700
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $1710
        .byte   $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $1720
        .byte   $FF, $FF, $FE                                    ; $1730
GCR_BUF1:
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $1733
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $1743
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $1753
        .byte   $FE, $FF, $FF                                    ; $1763
GCR_BUF2:
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $1766
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $1776
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $1786
        .byte   $FE, $FE, $FF                                    ; $1796
GCR_BUF3:
        .byte   $FF                                              ; $1799
WRITE_NIB_TABLE:
        .byte   $AB, $AD, $AE, $AF, $B5, $B6, $B7, $BA, $BB, $BD, $BE, $BF, $D6, $D7, $DA, $DB ; $179A
        .byte   $DD, $DE, $DF, $EA, $EB, $ED, $EE, $EF, $F5, $F6, $F7, $FA, $FB, $FD, $FE, $FF ; $17AA
STEP_ON_DELAY:
        .byte   $01, $30, $28, $24, $20, $1E, $1D, $1C, $1C, $1C, $1C, $1C ; $17BA
STEP_OFF_DELAY:
        .byte   $70, $2C, $26, $22, $1F, $1E, $1D, $1C, $1C, $1C, $1C, $1C, $FE, $FE, $FF, $FF ; $17C6
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $17D6
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF ; $17E6
        .byte   $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE ; $17F6
DISK_DRIVER:
        LDA #$00                     ; $1800  A9 00
        STA $1006                    ; $1802  8D 06 10
        LDA #$8C                     ; $1805  A9 8C
        STA $1007                    ; $1807  8D 07 10
        LDA $03E6                    ; $180A  AD E6 03
        CMP #$60                     ; $180D  C9 60
        BNE DISK_DRIVER_1            ; $180F  D0 07
        LDA $03E4                    ; $1811  AD E4 03
        CMP #$02                     ; $1814  C9 02
        BEQ DISK_DRIVER_2            ; $1816  F0 03
DISK_DRIVER_1:
        JMP $0E06                    ; $1818  4C 06 0E
DISK_DRIVER_2:
        LDY #$02                     ; $181B  A0 02
        STY $06F8                    ; $181D  8C F8 06
        LDY #$04                     ; $1820  A0 04
        STY $04F8                    ; $1822  8C F8 04
        LDA $03E6                    ; $1825  AD E6 03
        TAX                          ; $1828  AA
        CMP $03E7                    ; $1829  CD E7 03
        BEQ DISK_DRIVER_5            ; $182C  F0 1D
        TXA                          ; $182E  8A
        TAY                          ; $182F  A8
        LDA $03E7                    ; $1830  AD E7 03
        TAX                          ; $1833  AA
        TYA                          ; $1834  98
        PHA                          ; $1835  48
        STA $03E7                    ; $1836  8D E7 03
        LDA $C08E,X                  ; $1839  BD 8E C0
DISK_DRIVER_3:
        LDY #$08                     ; $183C  A0 08
        LDA $C08C,X                  ; $183E  BD 8C C0
DISK_DRIVER_4:
        CMP $C08C,X                  ; $1841  DD 8C C0
        BNE DISK_DRIVER_3            ; $1844  D0 F6
        DEY                          ; $1846  88
        BNE DISK_DRIVER_4            ; $1847  D0 F8
        PLA                          ; $1849  68
        TAX                          ; $184A  AA
DISK_DRIVER_5:
        LDA $C08E,X                  ; $184B  BD 8E C0
        LDA $C08C,X                  ; $184E  BD 8C C0
        LDY #$08                     ; $1851  A0 08
DISK_DRIVER_6:
        LDA $C08C,X                  ; $1853  BD 8C C0
        PHA                          ; $1856  48
        PLA                          ; $1857  68
        PHA                          ; $1858  48
        PLA                          ; $1859  68
        STX $05F8                    ; $185A  8E F8 05
        CMP $C08C,X                  ; $185D  DD 8C C0
        BNE DISK_DRIVER_7            ; $1860  D0 03
        DEY                          ; $1862  88
        BNE DISK_DRIVER_6            ; $1863  D0 EE
DISK_DRIVER_7:
        PHP                          ; $1865  08
        LDA $C089,X                  ; $1866  BD 89 C0
        LDA $03E8                    ; $1869  AD E8 03
        STA $3E                      ; $186C  85 3E
        LDA $03E9                    ; $186E  AD E9 03
        STA $3F                      ; $1871  85 3F
        LDA #$EF                     ; $1873  A9 EF
        STA $46                      ; $1875  85 46
        LDA #$D8                     ; $1877  A9 D8
        STA $47                      ; $1879  85 47
        LDA $03E4                    ; $187B  AD E4 03
        CMP $03E5                    ; $187E  CD E5 03
        BEQ DISK_DRIVER_8            ; $1881  F0 07
        STA $03E5                    ; $1883  8D E5 03
        PLP                          ; $1886  28
        LDY #$00                     ; $1887  A0 00
        PHP                          ; $1889  08
DISK_DRIVER_8:
        ROR                          ; $188A  6A
        BCC DISK_DRIVER_9            ; $188B  90 05
        LDA $C08A,X                  ; $188D  BD 8A C0
        BCS DISK_DRIVER_10           ; $1890  B0 03
DISK_DRIVER_9:
        LDA $C08B,X                  ; $1892  BD 8B C0
DISK_DRIVER_10:
        ROR $35                      ; $1895  66 35
        PLP                          ; $1897  28
        PHP                          ; $1898  08
        BNE DISK_DRIVER_12           ; $1899  D0 0B
        LDY #$07                     ; $189B  A0 07
DISK_DRIVER_11:
        JSR STEP_DELAY               ; $189D  20 7E 16
        DEY                          ; $18A0  88
        BNE DISK_DRIVER_11           ; $18A1  D0 FA
        LDX $05F8                    ; $18A3  AE F8 05
DISK_DRIVER_12:
        LDA $03E0                    ; $18A6  AD E0 03
        JSR BUFFER_SWAP_HI           ; $18A9  20 64 19
        PLP                          ; $18AC  28
        BNE DISK_DRIVER_15           ; $18AD  D0 0D
DISK_DRIVER_13:
        LDY #$12                     ; $18AF  A0 12
DISK_DRIVER_14:
        DEY                          ; $18B1  88
        BNE DISK_DRIVER_14           ; $18B2  D0 FD
        INC $46                      ; $18B4  E6 46
        BNE DISK_DRIVER_13           ; $18B6  D0 F7
        INC $47                      ; $18B8  E6 47
        BNE DISK_DRIVER_13           ; $18BA  D0 F3
DISK_DRIVER_15:
        LDA $03EB                    ; $18BC  AD EB 03
        BEQ DISK_DRIVER_24           ; $18BF  F0 56
        ROR                          ; $18C1  6A
        PHP                          ; $18C2  08
        BCS DISK_DRIVER_16           ; $18C3  B0 03
        JSR PRENIBBLE_WRITE          ; $18C5  20 03 14
DISK_DRIVER_16:
        LDY #$30                     ; $18C8  A0 30
        STY $0578                    ; $18CA  8C 78 05
DISK_DRIVER_17:
        LDX $05F8                    ; $18CD  AE F8 05
        JSR READ_ADDR_FIELD          ; $18D0  20 68 15
        BCC DISK_DRIVER_21           ; $18D3  90 24
DISK_DRIVER_18:
        DEC $0578                    ; $18D5  CE 78 05
        BPL DISK_DRIVER_17           ; $18D8  10 F3
DISK_DRIVER_19:
        LDA $0478                    ; $18DA  AD 78 04
        PHA                          ; $18DD  48
        LDA #$60                     ; $18DE  A9 60
        JSR BUFFER_STORE             ; $18E0  20 96 19
        DEC $06F8                    ; $18E3  CE F8 06
        BEQ DISK_DRIVER_22           ; $18E6  F0 28
        LDA #$04                     ; $18E8  A9 04
        STA $04F8                    ; $18EA  8D F8 04
        LDA #$00                     ; $18ED  A9 00
        JSR BUFFER_SWAP_HI           ; $18EF  20 64 19
        PLA                          ; $18F2  68
DISK_DRIVER_20:
        JSR BUFFER_SWAP_HI           ; $18F3  20 64 19
        JMP DISK_DRIVER_16           ; $18F6  4C C8 18
DISK_DRIVER_21:
        LDY $2E                      ; $18F9  A4 2E
        CPY $0478                    ; $18FB  CC 78 04
        BEQ DISK_DRIVER_25           ; $18FE  F0 19
        LDA $0478                    ; $1900  AD 78 04
        PHA                          ; $1903  48
        TYA                          ; $1904  98
        JSR BUFFER_STORE             ; $1905  20 96 19
        PLA                          ; $1908  68
        DEC $04F8                    ; $1909  CE F8 04
        BNE DISK_DRIVER_20           ; $190C  D0 E5
        BEQ DISK_DRIVER_19           ; $190E  F0 CA
DISK_DRIVER_22:
        PLA                          ; $1910  68
        LDA #$40                     ; $1911  A9 40
DISK_DRIVER_23:
        PLP                          ; $1913  28
        JMP DISK_DRIVER_30+1         ; $1914  4C 53 19
DISK_DRIVER_24:
        BEQ DISK_DRIVER_29           ; $1917  F0 36
DISK_DRIVER_25:
        LDA $2F                      ; $1919  A5 2F
        STA $03E3                    ; $191B  8D E3 03
        LDA $03E2                    ; $191E  AD E2 03
        BEQ DISK_DRIVER_26           ; $1921  F0 08
        CMP $2F                      ; $1923  C5 2F
        BEQ DISK_DRIVER_26           ; $1925  F0 04
        LDA #$20                     ; $1927  A9 20
        BNE DISK_DRIVER_23           ; $1929  D0 E8
DISK_DRIVER_26:
        LDY $03E1                    ; $192B  AC E1 03
        LDA $03E0                    ; $192E  AD E0 03
        CMP #$03                     ; $1931  C9 03
        BCS DISK_DRIVER_27           ; $1933  B0 03
        TYA                          ; $1935  98
        BCC DISK_DRIVER_28           ; $1936  90 03
DISK_DRIVER_27:
        LDA SKEW_13SEC,Y                 ; $1938  B9 E0 19
DISK_DRIVER_28:
        CMP $2D                      ; $193B  C5 2D
        BNE DISK_DRIVER_18           ; $193D  D0 96
        PLP                          ; $193F  28
        BCC DISK_DRIVER_31           ; $1940  90 19
        JSR READ_SECTOR              ; $1942  20 00 15
        PHP                          ; $1945  08
        BCS DISK_DRIVER_18           ; $1946  B0 8D
        PLP                          ; $1948  28
        JSR DENIBBLE_SECTOR          ; $1949  20 C4 15
        LDX $05F8                    ; $194C  AE F8 05
DISK_DRIVER_29:
        CLC                          ; $194F  18
        LDA #$00                     ; $1950  A9 00
DISK_DRIVER_30:
        BIT $38                      ; $1952  24 38
        STA $03EA                    ; $1954  8D EA 03
        LDA $C088,X                  ; $1957  BD 88 C0
        RTS                          ; $195A  60
DISK_DRIVER_31:
        JSR WRITE_SECTOR             ; $195B  20 6D 14
        BCC DISK_DRIVER_29           ; $195E  90 EF
        LDA #$10                     ; $1960  A9 10
        BCS DISK_DRIVER_30+1         ; $1962  B0 EF
BUFFER_SWAP_HI:
        ASL                          ; $1964  0A
        JSR BUFFER_SELECT            ; $1965  20 6C 19
        LSR $0478                    ; $1968  4E 78 04
        RTS                          ; $196B  60
BUFFER_SELECT:
        STA $2E                      ; $196C  85 2E
        JSR SLOT_TO_INDEX            ; $196E  20 8F 19
        LDA $0478,Y                  ; $1971  B9 78 04
        BIT $35                      ; $1974  24 35
        BMI BUFFER_SELECT_1          ; $1976  30 03
        LDA $04F8,Y                  ; $1978  B9 F8 04
BUFFER_SELECT_1:
        STA $0478                    ; $197B  8D 78 04
        LDA $2E                      ; $197E  A5 2E
        BIT $35                      ; $1980  24 35
        BMI BUFFER_SELECT_2          ; $1982  30 05
        STA $04F8,Y                  ; $1984  99 F8 04
        BPL BUFFER_SELECT_3          ; $1987  10 03
BUFFER_SELECT_2:
        STA $0478,Y                  ; $1989  99 78 04
BUFFER_SELECT_3:
        JMP SEEK_TRACK               ; $198C  4C 21 16
SLOT_TO_INDEX:
        TXA                          ; $198F  8A
        LSR                          ; $1990  4A
        LSR                          ; $1991  4A
        LSR                          ; $1992  4A
        LSR                          ; $1993  4A
        TAY                          ; $1994  A8
        RTS                          ; $1995  60
BUFFER_STORE:
        PHA                          ; $1996  48
        LDA $03E4                    ; $1997  AD E4 03
        ROR                          ; $199A  6A
        ROR $35                      ; $199B  66 35
        JSR SLOT_TO_INDEX            ; $199D  20 8F 19
        PLA                          ; $19A0  68
        ASL                          ; $19A1  0A
        BIT $35                      ; $19A2  24 35
        BMI BUFFER_STORE_1           ; $19A4  30 05
        STA $04F8,Y                  ; $19A6  99 F8 04
        BPL BUFFER_STORE_2           ; $19A9  10 03
BUFFER_STORE_1:
        STA $0478,Y                  ; $19AB  99 78 04
BUFFER_STORE_2:
        RTS                          ; $19AE  60
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $19AF
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $19BF
        .byte   $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE, $FE, $FF, $FF, $FE ; $19CF
        .byte   $FE                                              ; $19DF
SKEW_13SEC:
        .byte   $00, $09, $05, $03, $0C, $FF, $06, $02, $0A, $08, $04, $FF, $0B, $07, $FF, $01 ; $19E0
        .byte   $1A, $00, $03, $07, $00, $67, $00, $2F, $00, $C0, $00, $0C, $00, $03, $00, $00 ; $19F0
