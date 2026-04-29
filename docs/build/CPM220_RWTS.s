; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- RWTS (Apple $0A00-$0FFF)
; Annotated 6502 assembly source for the disk-routine block loaded by
; the boot stub from track 0 sectors 2, 4, 6, 8, A, C (in CP/M skew
; order) into Apple $0A00-$0FFF.
;
; SCOPE
;   Compared to 2.23, 2.20's RWTS region is structured slightly
;   differently. The clean 6502 RWTS code occupies more of the area
;   because 2.20's BIOS first 1 KB sits at Z-80 $DACC (not $FAB8),
;   so the BIOS-content overlap into Apple $0Cxx is less significant
;   than in 2.23. This file covers the 6502 portion through $0E10
;   (where 2.20's LOAD_CPM sits).
;
; KEY DIFFERENCES FROM 2.23
;   - LOAD_CPM at $0E10 (vs 2.23 at $0BEB / $BBEB)
;   - Main load reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D)
;   - JSR $0E10 callers are at stage-2 $1608 and $17D0 (vs 2.23's
;     $1416 and $191E)
;   - 2.20 has no embedded Z-80 fragment in the 6502 loader area
;     (2.23 had ~270 bytes at loader $143A-$1547)
;
; ENCODING (same as 2.23)
;   Standard Apple Disk II 6-and-2 GCR. Address-field prolog: D5 AA 96.
;   Data-field prolog: D5 AA AD. Both epilogs: DE AA EB.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols (same as 2.23)
; ----------------------------------------------------------------------------
DSK_PHASE_OFF   = $C080
DSK_PHASE_ON    = $C081
DSK_MOTOR_OFF   = $C088
DSK_MOTOR_ON    = $C089
DSK_DRIVE_1     = $C08A
DSK_DRIVE_2     = $C08B
DSK_Q6L         = $C08C
DSK_Q6H         = $C08D
DSK_Q7L         = $C08E
DSK_Q7H         = $C08F

PRINT_ERR       = $FF2D

zp_buf_lo       = $26
zp_buf_hi       = $27
zp_track        = $2A
zp_sector       = $2B

SLOT_HEAD_TRK   = $0478

WRITE_BYTE_4US  = $BA8F
WRITE_BYTE_DLY  = $BA90
SEEK_PHASE_ON   = $BBAD
SEEK_PHASE_OFF  = $BBB0
SEEK_PHASE_DLY  = $BBBC

            .ORG $0A00


; ============================================================================
; WRITE_SECTOR ($0A00) -- write 256 bytes at $0C00 to current track/sector
; ============================================================================

WRITE_SECTOR:
            LDX #$55                        ; $0A00 A2 55
            LDA #$00                        ; $0A02 A9 00
            STA $0D00,X                     ; $0A04 9D 00 0D
            DEX                             ; $0A07 CA
            BPL $0A04                       ; $0A08 10 FA
            TAY                             ; $0A0A A8
            LDX #$AC                        ; $0A0B A2 AC
            BIT $AAA2                       ; $0A0D 2C A2 AA
            DEY                             ; $0A10 88
            LDA ($3E),Y                     ; $0A11 B1 3E
            LSR                             ; $0A13 4A
            ROL $0C56,X                     ; $0A14 3E 56 0C
            LSR                             ; $0A17 4A
            ROL $0C56,X                     ; $0A18 3E 56 0C
            STA $0900,Y                     ; $0A1B 99 00 09
            INX                             ; $0A1E E8
            BNE $0A10                       ; $0A1F D0 EF
            TYA                             ; $0A21 98
            BNE $0A0E                       ; $0A22 D0 EA
            RTS                             ; $0A24 60
            SEC                             ; $0A25 38
            STX $27                         ; $0A26 86 27
            STX $0678                       ; $0A28 8E 78 06
            LDA $C08D,X                     ; $0A2B BD 8D C0
            LDA $C08E,X                     ; $0A2E BD 8E C0
            BMI $0AAF                       ; $0A31 30 7C
            LDA $0D00                       ; $0A33 AD 00 0D
            STA $26                         ; $0A36 85 26
            LDA #$FF                        ; $0A38 A9 FF
            STA $C08F,X                     ; $0A3A 9D 8F C0
            ORA $C08C,X                     ; $0A3D 1D 8C C0
            PHA                             ; $0A40 48
            PLA                             ; $0A41 68
            NOP                             ; $0A42 EA
            LDY #$04                        ; $0A43 A0 04
            PHA                             ; $0A45 48
            PLA                             ; $0A46 68
            JSR $0AB5                       ; $0A47 20 B5 0A
            DEY                             ; $0A4A 88
            BNE $0A45                       ; $0A4B D0 F8
            LDA #$D5                        ; $0A4D A9 D5
            JSR $0AB4                       ; $0A4F 20 B4 0A
            LDA #$AA                        ; $0A52 A9 AA
            JSR $0AB4                       ; $0A54 20 B4 0A
            LDA #$AD                        ; $0A57 A9 AD
            JSR $0AB4                       ; $0A59 20 B4 0A
            TYA                             ; $0A5C 98
            LDY #$56                        ; $0A5D A0 56
            BNE $0A64                       ; $0A5F D0 03
            LDA $0D00,Y                     ; $0A61 B9 00 0D
            EOR $0CFF,Y                     ; $0A64 59 FF 0C
            TAX                             ; $0A67 AA
            LDA $0D56,X                     ; $0A68 BD 56 0D
            LDX $27                         ; $0A6B A6 27
            STA $C08D,X                     ; $0A6D 9D 8D C0
            LDA $C08C,X                     ; $0A70 BD 8C C0
            DEY                             ; $0A73 88
            BNE $0A61                       ; $0A74 D0 EB
            LDA $26                         ; $0A76 A5 26
            NOP                             ; $0A78 EA
            EOR $0900,Y                     ; $0A79 59 00 09
            TAX                             ; $0A7C AA
            LDA $0D56,X                     ; $0A7D BD 56 0D
            LDX $0678                       ; $0A80 AE 78 06
            STA $C08D,X                     ; $0A83 9D 8D C0
            LDA $C08C,X                     ; $0A86 BD 8C C0
            LDA $0900,Y                     ; $0A89 B9 00 09
            INY                             ; $0A8C C8
            BNE $0A79                       ; $0A8D D0 EA
            TAX                             ; $0A8F AA
            LDA $0D56,X                     ; $0A90 BD 56 0D
            LDX $27                         ; $0A93 A6 27
            JSR $0AB7                       ; $0A95 20 B7 0A
            LDA #$DE                        ; $0A98 A9 DE
            JSR $0AB4                       ; $0A9A 20 B4 0A
            LDA #$AA                        ; $0A9D A9 AA
            JSR $0AB4                       ; $0A9F 20 B4 0A
            LDA #$EB                        ; $0AA2 A9 EB
            JSR $0AB4                       ; $0AA4 20 B4 0A
            LDA #$FF                        ; $0AA7 A9 FF
            JSR $0AB4                       ; $0AA9 20 B4 0A
            LDA $C08E,X                     ; $0AAC BD 8E C0
            LDA $C08C,X                     ; $0AAF BD 8C C0
            RTS                             ; $0AB2 60
            NOP                             ; $0AB3 EA
            CLC                             ; $0AB4 18
            PHA                             ; $0AB5 48
            PLA                             ; $0AB6 68
            STA $C08D,X                     ; $0AB7 9D 8D C0
            ORA $C08C,X                     ; $0ABA 1D 8C C0
            RTS                             ; $0ABD 60
            ISC $FFFF,X                     ; $0ABE FF FF FF
            ISC $FFFF,X                     ; $0AC1 FF FF FF
            ISC $FFFF,X                     ; $0AC4 FF FF FF
            ISC $FFFF,X                     ; $0AC7 FF FF FF
            ISC $FFFF,X                     ; $0ACA FF FF FF
            ISC $FFFF,X                     ; $0ACD FF FF FF
            ISC $FFFF,X                     ; $0AD0 FF FF FF
            ISC $FFFF,X                     ; $0AD3 FF FF FF
            ISC $FFFF,X                     ; $0AD6 FF FF FF
            ISC $FFFF,X                     ; $0AD9 FF FF FF
            ISC $FFFF,X                     ; $0ADC FF FF FF
            ISC $FFFF,X                     ; $0ADF FF FF FF
            ISC $FFFF,X                     ; $0AE2 FF FF FF
            ISC $FFFF,X                     ; $0AE5 FF FF FF
            ISC $FFFF,X                     ; $0AE8 FF FF FF
            ISC $FFFF,X                     ; $0AEB FF FF FF
            ISC $FFFF,X                     ; $0AEE FF FF FF
            ISC $FFFF,X                     ; $0AF1 FF FF FF
            ISC $FFFF,X                     ; $0AF4 FF FF FF
            ISC $FFFF,X                     ; $0AF7 FF FF FF
            ISC $FFFF,X                     ; $0AFA FF FF FF
            ISC $FFFF,X                     ; $0AFD FF FF FF
            LDY #$20                        ; $0B00 A0 20
            DEY                             ; $0B02 88
            BEQ $0B68                       ; $0B03 F0 63
            LDA $C08C,X                     ; $0B05 BD 8C C0
            BPL $0B05                       ; $0B08 10 FB
            EOR #$D5                        ; $0B0A 49 D5
            BNE $0B02                       ; $0B0C D0 F4
            NOP                             ; $0B0E EA
            LDA $C08C,X                     ; $0B0F BD 8C C0
            BPL $0B0F                       ; $0B12 10 FB
            CMP #$AA                        ; $0B14 C9 AA
            BNE $0B0A                       ; $0B16 D0 F2
            LDY #$56                        ; $0B18 A0 56
            LDA $C08C,X                     ; $0B1A BD 8C C0
            BPL $0B1A                       ; $0B1D 10 FB
            CMP #$AD                        ; $0B1F C9 AD
            BNE $0B0A                       ; $0B21 D0 E7
            NOP                             ; $0B23 EA
            NOP                             ; $0B24 EA
            LDA #$00                        ; $0B25 A9 00
            DEY                             ; $0B27 88
            STY $26                         ; $0B28 84 26
            LDY $C08C,X                     ; $0B2A BC 8C C0
            BPL $0B2A                       ; $0B2D 10 FB
            EOR $0D00,Y                     ; $0B2F 59 00 0D
            LDY $26                         ; $0B32 A4 26
            STA $0D00,Y                     ; $0B34 99 00 0D
            BNE $0B27                       ; $0B37 D0 EE
            STY $26                         ; $0B39 84 26
            LDY $C08C,X                     ; $0B3B BC 8C C0
            BPL $0B3B                       ; $0B3E 10 FB
            EOR $0D00,Y                     ; $0B40 59 00 0D
            LDY $26                         ; $0B43 A4 26
            STA $0900,Y                     ; $0B45 99 00 09
            INY                             ; $0B48 C8
            BNE $0B39                       ; $0B49 D0 EE
            LDY $C08C,X                     ; $0B4B BC 8C C0
            BPL $0B4B                       ; $0B4E 10 FB
            CMP $0D00,Y                     ; $0B50 D9 00 0D
            BNE $0B68                       ; $0B53 D0 13
            LDA $C08C,X                     ; $0B55 BD 8C C0
            BPL $0B55                       ; $0B58 10 FB
            CMP #$DE                        ; $0B5A C9 DE
            BNE $0B68                       ; $0B5C D0 0A
            NOP                             ; $0B5E EA

; ============================================================================
; SEEK_TRACK ($0B5F) -- move drive head
; ============================================================================


            LDA $C08C,X                     ; $0B5F BD 8C C0
            BPL $0B5F                       ; $0B62 10 FB
            CMP #$AA                        ; $0B64 C9 AA
            BEQ $0BC4                       ; $0B66 F0 5C
            SEC                             ; $0B68 38
            RTS                             ; $0B69 60
            LDY #$FC                        ; $0B6A A0 FC
            STY $26                         ; $0B6C 84 26
            INY                             ; $0B6E C8
            BNE $0B75                       ; $0B6F D0 04
            INC $26                         ; $0B71 E6 26
            BEQ $0B68                       ; $0B73 F0 F3
            LDA $C08C,X                     ; $0B75 BD 8C C0
            BPL $0B75                       ; $0B78 10 FB
            CMP #$D5                        ; $0B7A C9 D5
            BNE $0B6E                       ; $0B7C D0 F0
            NOP                             ; $0B7E EA
            LDA $C08C,X                     ; $0B7F BD 8C C0
            BPL $0B7F                       ; $0B82 10 FB
            CMP #$AA                        ; $0B84 C9 AA
            BNE $0B7A                       ; $0B86 D0 F2
            LDY #$03                        ; $0B88 A0 03
            LDA $C08C,X                     ; $0B8A BD 8C C0
            BPL $0B8A                       ; $0B8D 10 FB
            CMP #$96                        ; $0B8F C9 96
            BNE $0B7A                       ; $0B91 D0 E7
            LDA #$00                        ; $0B93 A9 00
            STA $27                         ; $0B95 85 27
            LDA $C08C,X                     ; $0B97 BD 8C C0
            BPL $0B97                       ; $0B9A 10 FB
            ROL                             ; $0B9C 2A
            STA $26                         ; $0B9D 85 26
            LDA $C08C,X                     ; $0B9F BD 8C C0
            BPL $0B9F                       ; $0BA2 10 FB
            AND $26                         ; $0BA4 25 26
            STA $002C,Y                     ; $0BA6 99 2C 00
            EOR $27                         ; $0BA9 45 27
            DEY                             ; $0BAB 88
            BPL $0B95                       ; $0BAC 10 E7
            TAY                             ; $0BAE A8
            BNE $0B68                       ; $0BAF D0 B7
            LDA $C08C,X                     ; $0BB1 BD 8C C0
            BPL $0BB1                       ; $0BB4 10 FB
            CMP #$DE                        ; $0BB6 C9 DE
            BNE $0B68                       ; $0BB8 D0 AE
            NOP                             ; $0BBA EA
            LDA $C08C,X                     ; $0BBB BD 8C C0
            BPL $0BBB                       ; $0BBE 10 FB
            CMP #$AA                        ; $0BC0 C9 AA
            BNE $0B68                       ; $0BC2 D0 A4
            CLC                             ; $0BC4 18
            RTS                             ; $0BC5 60
            LDY #$00                        ; $0BC6 A0 00
            LDX #$56                        ; $0BC8 A2 56
            DEX                             ; $0BCA CA
            BMI $0BC8                       ; $0BCB 30 FB
            LDA $0900,Y                     ; $0BCD B9 00 09
            LSR $0D00,X                     ; $0BD0 5E 00 0D
            ROL                             ; $0BD3 2A
            LSR $0D00,X                     ; $0BD4 5E 00 0D
            ROL                             ; $0BD7 2A
            STA ($3E),Y                     ; $0BD8 91 3E
            INY                             ; $0BDA C8
            BNE $0BCA                       ; $0BDB D0 ED
            RTS                             ; $0BDD 60
            STX $2B                         ; $0BDE 86 2B
            STA $2A                         ; $0BE0 85 2A
            CMP $0478                       ; $0BE2 CD 78 04
            BEQ $0C3A                       ; $0BE5 F0 53
            LDA #$00                        ; $0BE7 A9 00
            STA $26                         ; $0BE9 85 26
            LDA $0478                       ; $0BEB AD 78 04

; ============================================================================
; LOAD_CPM_LOOP ($0BEE) -- 28-sector load loop
;
; 2.20 reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D). Otherwise
; structurally identical to 2.23's LOAD_CPM_LOOP.
; ============================================================================


            STA $27                         ; $0BEE 85 27
            SEC                             ; $0BF0 38
            SBC $2A                         ; $0BF1 E5 2A
            BEQ $0C28                       ; $0BF3 F0 33
            BCS $0BFE                       ; $0BF5 B0 07
            EOR #$FF                        ; $0BF7 49 FF
            INC $0478                       ; $0BF9 EE 78 04
            BCC $0C03                       ; $0BFC 90 05
            ADC #$FE                        ; $0BFE 69 FE
            DEC $0478                       ; $0C00 CE 78 04
            CMP $26                         ; $0C03 C5 26
            BCC $0C09                       ; $0C05 90 02
            LDA $26                         ; $0C07 A5 26
            CMP #$0C                        ; $0C09 C9 0C
            BCS $0C0E                       ; $0C0B B0 01
            TAY                             ; $0C0D A8
            SEC                             ; $0C0E 38
            JSR $0C2C                       ; $0C0F 20 2C 0C
            LDA $0C50,Y                     ; $0C12 B9 50 0C
            JSR $0C3B                       ; $0C15 20 3B 0C
            LDA $27                         ; $0C18 A5 27
            CLC                             ; $0C1A 18
            JSR $0C2F                       ; $0C1B 20 2F 0C
            LDA $0C5C,Y                     ; $0C1E B9 5C 0C
            JSR $0C3B                       ; $0C21 20 3B 0C
            INC $26                         ; $0C24 E6 26
            BNE $0BEB                       ; $0C26 D0 C3
            JSR $0C3B                       ; $0C28 20 3B 0C
            CLC                             ; $0C2B 18
            LDA $0478                       ; $0C2C AD 78 04
            AND #$03                        ; $0C2F 29 03
            ROL                             ; $0C31 2A
            ORA $2B                         ; $0C32 05 2B
            TAX                             ; $0C34 AA
            LDA $C080,X                     ; $0C35 BD 80 C0
            LDX $2B                         ; $0C38 A6 2B
            RTS                             ; $0C3A 60
            LDX #$11                        ; $0C3B A2 11
            DEX                             ; $0C3D CA
            BNE $0C3D                       ; $0C3E D0 FD
            INC $46                         ; $0C40 E6 46
            BNE $0C4A                       ; $0C42 D0 06
            INC $47                         ; $0C44 E6 47
            BNE $0C4A                       ; $0C46 D0 02
            DEC $47                         ; $0C48 C6 47
            SEC                             ; $0C4A 38
            SBC #$01                        ; $0C4B E9 01
            BNE $0C3B                       ; $0C4D D0 EC
            RTS                             ; $0C4F 60
            ORA ($30,X)                     ; $0C50 01 30
            PLP                             ; $0C52 28
            BIT $20                         ; $0C53 24 20
            ASL $1C1D,X                     ; $0C55 1E 1D 1C
            NOP $1C1C,X                     ; $0C58 1C 1C 1C
            NOP $2C70,X                     ; $0C5B 1C 70 2C
            ROL $22                         ; $0C5E 26 22
            SLO $1D1E,X                     ; $0C60 1F 1E 1D
            NOP $1C1C,X                     ; $0C63 1C 1C 1C
            NOP $FF1C,X                     ; $0C66 1C 1C FF
            ISC $FFFF,X                     ; $0C69 FF FF FF
            ISC $FFFF,X                     ; $0C6C FF FF FF
            ISC $FFFF,X                     ; $0C6F FF FF FF
            ISC $FFFF,X                     ; $0C72 FF FF FF
            ISC $FFFF,X                     ; $0C75 FF FF FF
            ISC $FFFF,X                     ; $0C78 FF FF FF
            ISC $FFFF,X                     ; $0C7B FF FF FF
            ISC $FFFF,X                     ; $0C7E FF FF FF
            ISC $FFFF,X                     ; $0C81 FF FF FF
            ISC $FFFF,X                     ; $0C84 FF FF FF
            ISC $FFFF,X                     ; $0C87 FF FF FF
            ISC $FFFF,X                     ; $0C8A FF FF FF
            ISC $FFFF,X                     ; $0C8D FF FF FF
            ISC $FFFF,X                     ; $0C90 FF FF FF
            ISC $FFFF,X                     ; $0C93 FF FF FF
            ISC $FFFF,X                     ; $0C96 FF FF FF
            ISC $FFFF,X                     ; $0C99 FF FF FF
            ISC $FFFF,X                     ; $0C9C FF FF FF
            ISC $FFFF,X                     ; $0C9F FF FF FF
            ISC $FFFF,X                     ; $0CA2 FF FF FF
            ISC $FFFF,X                     ; $0CA5 FF FF FF
            ISC $FFFF,X                     ; $0CA8 FF FF FF
            ISC $FFFF,X                     ; $0CAB FF FF FF
            ISC $FFFF,X                     ; $0CAE FF FF FF
            ISC $FFFF,X                     ; $0CB1 FF FF FF
            ISC $FFFF,X                     ; $0CB4 FF FF FF
            ISC $FFFF,X                     ; $0CB7 FF FF FF
            ISC $FFFF,X                     ; $0CBA FF FF FF
            ISC $FFFF,X                     ; $0CBD FF FF FF
            ISC $FFFF,X                     ; $0CC0 FF FF FF
            ISC $FFFF,X                     ; $0CC3 FF FF FF
            ISC $FFFF,X                     ; $0CC6 FF FF FF
            ISC $FFFF,X                     ; $0CC9 FF FF FF
            ISC $FFFF,X                     ; $0CCC FF FF FF
            ISC $FFFF,X                     ; $0CCF FF FF FF
            ISC $FFFF,X                     ; $0CD2 FF FF FF
            ISC $FFFF,X                     ; $0CD5 FF FF FF
            ISC $FFFF,X                     ; $0CD8 FF FF FF
            ISC $FFFF,X                     ; $0CDB FF FF FF
            ISC $FFFF,X                     ; $0CDE FF FF FF
            ISC $FFFF,X                     ; $0CE1 FF FF FF
            ISC $FFFF,X                     ; $0CE4 FF FF FF
            ISC $FFFF,X                     ; $0CE7 FF FF FF
            ISC $FFFF,X                     ; $0CEA FF FF FF
            ISC $FFFF,X                     ; $0CED FF FF FF
            ISC $FFFF,X                     ; $0CF0 FF FF FF
            ISC $FFFF,X                     ; $0CF3 FF FF FF
            ISC $FFFF,X                     ; $0CF6 FF FF FF
            ISC $FFFF,X                     ; $0CF9 FF FF FF
            ISC $FFFF,X                     ; $0CFC FF FF FF
            ISC $FFFF,X                     ; $0CFF FF FF FF
            ISC $FFFF,X                     ; $0D02 FF FF FF
            ISC $FFFF,X                     ; $0D05 FF FF FF
            ISC $FFFF,X                     ; $0D08 FF FF FF
            ISC $FFFF,X                     ; $0D0B FF FF FF
            ISC $FFFF,X                     ; $0D0E FF FF FF
            ISC $FFFF,X                     ; $0D11 FF FF FF
            ISC $FFFF,X                     ; $0D14 FF FF FF
            ISC $FFFF,X                     ; $0D17 FF FF FF
            ISC $FFFF,X                     ; $0D1A FF FF FF
            ISC $FFFF,X                     ; $0D1D FF FF FF
            ISC $FFFF,X                     ; $0D20 FF FF FF
            ISC $FFFF,X                     ; $0D23 FF FF FF
            ISC $FFFF,X                     ; $0D26 FF FF FF
            ISC $FFFF,X                     ; $0D29 FF FF FF
            ISC $FFFF,X                     ; $0D2C FF FF FF
            ISC $FFFF,X                     ; $0D2F FF FF FF
            ISC $FFFF,X                     ; $0D32 FF FF FF
            ISC $FFFF,X                     ; $0D35 FF FF FF
            ISC $FFFF,X                     ; $0D38 FF FF FF
            ISC $FFFF,X                     ; $0D3B FF FF FF
            ISC $FFFF,X                     ; $0D3E FF FF FF
            ISC $FFFF,X                     ; $0D41 FF FF FF
            ISC $FFFF,X                     ; $0D44 FF FF FF
            ISC $FFFF,X                     ; $0D47 FF FF FF
            ISC $FFFF,X                     ; $0D4A FF FF FF
            ISC $FFFF,X                     ; $0D4D FF FF FF
            ISC $FFFF,X                     ; $0D50 FF FF FF
            ISC $FFFF,X                     ; $0D53 FF FF FF
            STX $97,Y                       ; $0D56 96 97
            TXS                             ; $0D58 9A
            TAS $9E9D,Y                     ; $0D59 9B 9D 9E
            SHA $A7A6,Y                     ; $0D5C 9F A6 A7
            LAX #$AC                        ; $0D5F AB AC
            LDA $AFAE                       ; $0D61 AD AE AF
            KIL                             ; $0D64 B2
            LAX ($B4),Y                     ; $0D65 B3 B4
            LDA $B6,X                       ; $0D67 B5 B6
            LAX $B9,Y                       ; $0D69 B7 B9
            TSX                             ; $0D6B BA
            LAS $BDBC,Y                     ; $0D6C BB BC BD
            LDX $CBBF,Y                     ; $0D6F BE BF CB
            CMP $CFCE                       ; $0D72 CD CE CF
            DCP ($D6),Y                     ; $0D75 D3 D6
            DCP $D9,X                       ; $0D77 D7 D9
            NOP                             ; $0D79 DA
            DCP $DDDC,Y                     ; $0D7A DB DC DD
            DEC $E5DF,X                     ; $0D7D DE DF E5
            INC $E7                         ; $0D80 E6 E7
            SBC #$EA                        ; $0D82 E9 EA
            SBC #$EC                        ; $0D84 EB EC
            SBC $EFEE                       ; $0D86 ED EE EF
            KIL                             ; $0D89 F2
            ISC ($F4),Y                     ; $0D8A F3 F4
            SBC $F6,X                       ; $0D8C F5 F6
            ISC $F9,X                       ; $0D8E F7 F9
            NOP                             ; $0D90 FA
            ISC $FDFC,Y                     ; $0D91 FB FC FD
            INC $00FF,X                     ; $0D94 FE FF 00
            ORA ($98,X)                     ; $0D97 01 98
            STA $0302,Y                     ; $0D99 99 02 03
            SHY $0504,X                     ; $0D9C 9C 04 05
            ASL $A0                         ; $0D9F 06 A0
            LDA ($A2,X)                     ; $0DA1 A1 A2
            LAX ($A4,X)                     ; $0DA3 A3 A4
            LDA $07                         ; $0DA5 A5 07
            PHP                             ; $0DA7 08
            TAY                             ; $0DA8 A8
            LDA #$AA                        ; $0DA9 A9 AA
            ORA #$0A                        ; $0DAB 09 0A
            ANC #$0C                        ; $0DAD 0B 0C
            ORA $B1B0                       ; $0DAF 0D B0 B1
            ASL $100F                       ; $0DB2 0E 0F 10
            ORA ($12),Y                     ; $0DB5 11 12
            SLO ($B8),Y                     ; $0DB7 13 B8
            NOP $15,X                       ; $0DB9 14 15
            ASL $17,X                       ; $0DBB 16 17
            CLC                             ; $0DBD 18
            ORA $C01A,Y                     ; $0DBE 19 1A C0
            CMP ($C2,X)                     ; $0DC1 C1 C2
            DCP ($C4,X)                     ; $0DC3 C3 C4
            CMP $C6                         ; $0DC5 C5 C6
            DCP $C8                         ; $0DC7 C7 C8
            CMP #$CA                        ; $0DC9 C9 CA
            SLO $1CCC,Y                     ; $0DCB 1B CC 1C
            ORA $D01E,X                     ; $0DCE 1D 1E D0
            CMP ($D2),Y                     ; $0DD1 D1 D2
            SLO $D5D4,X                     ; $0DD3 1F D4 D5
            JSR $D821                       ; $0DD6 20 21 D8
            KIL                             ; $0DD9 22
            RLA ($24,X)                     ; $0DDA 23 24
            AND $26                         ; $0DDC 25 26
            RLA $28                         ; $0DDE 27 28
            CPX #$E1                        ; $0DE0 E0 E1
            NOP #$E3                        ; $0DE2 E2 E3
            CPX $29                         ; $0DE4 E4 29
            ROL                             ; $0DE6 2A
            ANC #$E8                        ; $0DE7 2B E8
            BIT $2E2D                       ; $0DE9 2C 2D 2E
            RLA $3130                       ; $0DEC 2F 30 31
            KIL                             ; $0DEF 32
            BEQ $0DE3                       ; $0DF0 F0 F1
            RLA ($34),Y                     ; $0DF2 33 34
            AND $36,X                       ; $0DF4 35 36
            RLA $38,X                       ; $0DF6 37 38
            SED                             ; $0DF8 F8
            AND $3B3A,Y                     ; $0DF9 39 3A 3B
            NOP $3E3D,X                     ; $0DFC 3C 3D 3E
            RLA $AD4C,X                     ; $0DFF 3F 4C AD
            SLO $83AD                       ; $0E02 0F AD 83
            CPY #$08                        ; $0E05 C0 08
            SEI                             ; $0E07 78
            JSR $0E10                       ; $0E08 20 10 0E
            LDA $C081                       ; $0E0B AD 81 C0
            PLP                             ; $0E0E 28
            RTS                             ; $0E0F 60

; ============================================================================
; Beyond $0E10
;
; Apple $0E10 onwards in the 2.20 loader image continues with more 6502
; code (LOAD_CPM body and helpers). Since 2.20's BIOS at Z-80 $DACC
; doesn't overlap into Apple $0Cxx the way 2.23's BIOS at Z-80 $FAB8
; does, more of this region is 6502.
;
; The remainder up to $0FFF is partially 6502 and partially data tables
; for the GCR encode/decode plus state slots that the cooperative-CPU
; loop will use after the SoftCard switch.
; ============================================================================
