; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- RWTS (Apple $0A00-$0C38)
; Annotated 6502 assembly source for the disk-routine block loaded by
; the boot stub from track 0 sectors 2, 4, 6, 8, A, C (in CP/M skew
; order) into Apple $0A00-$0FFF.
;
; SCOPE
;   This file covers the clean 6502 RWTS code at $0A00-$0C38:
;     $0A00-$0A98  WRITE_SECTOR    write 256 bytes at $0C00 to disk
;     $0A99-$0B5E  READ_SECTOR     read 256 bytes from disk into $0900,$0C00
;     $0B5F-$0BED  SEEK_TRACK      step drive head to requested track
;     $0BEE-$0C38  LOAD_CPM_LOOP   29-sector load loop (calls $BE11 in LC RAM)
;
;   The bytes at $0C39-$0FFF in the loader image are NOT 6502 code. They
;   are part of the BIOS first 1 KB content the boot stub loaded; the
;   Z-80 sees them at $1C39-$1FFF after the SoftCard's bit-12 XOR mapping.
;   They will be covered in CPM223_BIOS.asm.
;
;   PREP_HANDOFF (in CPM223_BootLoader.asm at Apple $1109-$113F) copies
;   $0A00-$0FFF to $BA00-$BFFF before the SoftCard switch, preserving
;   the RWTS in LC RAM where the cooperative-CPU loop reaches it. So the
;   absolute addresses in this code (e.g., JSR $BA90, JSR $BA8F) refer
;   to where each routine WILL BE after PREP_HANDOFF copies them.
;
; CALLING CONVENTION (Apple Disk II standard)
;   X register = slot number * 16 (e.g., $60 for slot 6)
;   $26/$27    = pointer to current sector buffer / track number
;   $0478,Y    = current head track for slot Y (Apple monitor screen-hole
;                convention; $0478+$Cn for slot $Cn)
;   $03B8-$03EB = scratch state for sector counter, track number, etc.
;
; ENCODING
;   Standard Apple Disk II 6-and-2 GCR. Address-field prolog: D5 AA 96.
;   Data-field prolog: D5 AA AD. Both epilogs: DE AA EB.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols
; ----------------------------------------------------------------------------
; Apple Disk II soft switches (X-indexed by slot*16)
DSK_PHASE_OFF   = $C080       ; Disk II phase off (bit 0)
DSK_PHASE_ON    = $C081       ; Disk II phase on (bit 0)
                              ; Phases 0..3 at $C080, $C082, $C084, $C086
                              ; (off) and $C081, $C083, $C085, $C087 (on)
DSK_MOTOR_OFF   = $C088       ; Disk II motor off
DSK_MOTOR_ON    = $C089       ; Disk II motor on
DSK_DRIVE_1     = $C08A       ; select drive 1
DSK_DRIVE_2     = $C08B       ; select drive 2
DSK_Q6L         = $C08C       ; sequencer Q6 low (read latch)
DSK_Q6H         = $C08D       ; sequencer Q6 high (write enable)
DSK_Q7L         = $C08E       ; sequencer Q7 low (read mode)
DSK_Q7H         = $C08F       ; sequencer Q7 high (write mode)

; Apple monitor entry points
PRINT_ERR       = $FF2D       ; print "ERR" + bell

; Zero-page conventions
zp_buf_lo       = $26         ; sector buffer low / scratch
zp_buf_hi       = $27         ; sector buffer high / scratch
zp_track        = $2A         ; current track
zp_sector       = $2B         ; current sector

; Apple monitor screen-hole conventions
SLOT_HEAD_TRK   = $0478       ; per-slot current head track ($0478+$Cn)

; LC-RAM-resident routines (called by RWTS for sub-helpers)
WRITE_BYTE_4US  = $BA8F       ; write 1 nibble (4 us cycle)
WRITE_BYTE_DLY  = $BA90       ; write 1 nibble with extra delay
SEEK_PHASE_ON   = $BBAD       ; phase-on helper (X = phase * 2)
SEEK_PHASE_OFF  = $BBB0
SEEK_PHASE_DLY  = $BBBC       ; per-phase delay
SEEK_DELAY_TBL  = $BBD1       ; phase-on delay table indexed by half-track delta
SEEK_DELAY_TBL2 = $BBDD       ; phase-off delay table
LOAD_CPM_PRIM   = $BE11       ; sector-read primitive in LC RAM
LOAD_CPM_RETRY  = $BBE9       ; retry/error landing pad in LC RAM

            .ORG $0A00


; ============================================================================
; WRITE_SECTOR ($0A00) -- write 256 bytes at $0C00 to current track/sector
;
; Writes the standard Apple Disk II 6-and-2 GCR sequence:
;   address prolog D5 AA AD,
;   342 GCR-encoded data nibbles + checksum nibble,
;   epilog DE AA EB.
;
; Helper at $0A8E-$0A98 (WRITE_BYTE) sends one nibble out via Q6H/Q6L.
; Bails to $0A8A on write-protect detection.
; ============================================================================

WRITE_SECTOR:
            SEC                             ; $0A00 38
            STX $27                         ; $0A01 86 27
            STX $0678                       ; $0A03 8E 78 06
            LDA $C08D,X                     ; $0A06 BD 8D C0
            LDA $C08E,X                     ; $0A09 BD 8E C0
            BMI $0A8A                       ; $0A0C 30 7C
            LDA $0C00                       ; $0A0E AD 00 0C
            STA $26                         ; $0A11 85 26
            LDA #$FF                        ; $0A13 A9 FF
            STA $C08F,X                     ; $0A15 9D 8F C0
            ORA $C08C,X                     ; $0A18 1D 8C C0
            PHA                             ; $0A1B 48
            PLA                             ; $0A1C 68
            NOP                             ; $0A1D EA
            LDY #$04                        ; $0A1E A0 04
            PHA                             ; $0A20 48
            PLA                             ; $0A21 68
            JSR $BA90                       ; $0A22 20 90 BA
            DEY                             ; $0A25 88
            BNE $0A20                       ; $0A26 D0 F8
            LDA #$D5                        ; $0A28 A9 D5
            JSR $BA8F                       ; $0A2A 20 8F BA
            LDA #$AA                        ; $0A2D A9 AA
            JSR $BA8F                       ; $0A2F 20 8F BA
            LDA #$AD                        ; $0A32 A9 AD
            JSR $BA8F                       ; $0A34 20 8F BA
            TYA                             ; $0A37 98
            LDY #$56                        ; $0A38 A0 56
            BNE $0A3F                       ; $0A3A D0 03
            LDA $0C00,Y                     ; $0A3C B9 00 0C
            EOR $0BFF,Y                     ; $0A3F 59 FF 0B
            TAX                             ; $0A42 AA
            LDA $BD5A,X                     ; $0A43 BD 5A BD
            LDX $27                         ; $0A46 A6 27
            STA $C08D,X                     ; $0A48 9D 8D C0
            LDA $C08C,X                     ; $0A4B BD 8C C0
            DEY                             ; $0A4E 88
            BNE $0A3C                       ; $0A4F D0 EB
            LDA $26                         ; $0A51 A5 26
            NOP                             ; $0A53 EA
            EOR $0900,Y                     ; $0A54 59 00 09
            TAX                             ; $0A57 AA
            LDA $BD5A,X                     ; $0A58 BD 5A BD
            LDX $0678                       ; $0A5B AE 78 06
            STA $C08D,X                     ; $0A5E 9D 8D C0
            LDA $C08C,X                     ; $0A61 BD 8C C0
            LDA $0900,Y                     ; $0A64 B9 00 09
            INY                             ; $0A67 C8
            BNE $0A54                       ; $0A68 D0 EA
            TAX                             ; $0A6A AA
            LDA $BD5A,X                     ; $0A6B BD 5A BD
            LDX $27                         ; $0A6E A6 27
            JSR $BA92                       ; $0A70 20 92 BA
            LDA #$DE                        ; $0A73 A9 DE
            JSR $BA8F                       ; $0A75 20 8F BA
            LDA #$AA                        ; $0A78 A9 AA
            JSR $BA8F                       ; $0A7A 20 8F BA
            LDA #$EB                        ; $0A7D A9 EB
            JSR $BA8F                       ; $0A7F 20 8F BA
            LDA #$FF                        ; $0A82 A9 FF
            JSR $BA8F                       ; $0A84 20 8F BA
            LDA $C08E,X                     ; $0A87 BD 8E C0
            LDA $C08C,X                     ; $0A8A BD 8C C0
            RTS                             ; $0A8D 60
            NOP                             ; $0A8E EA
            CLC                             ; $0A8F 18
            PHA                             ; $0A90 48
            PLA                             ; $0A91 68
            STA $C08D,X                     ; $0A92 9D 8D C0
            ORA $C08C,X                     ; $0A95 1D 8C C0
            RTS                             ; $0A98 60

; ============================================================================
; READ_SECTOR ($0A99) -- read current track/sector to $0900-$0AFF + $0C00-$0CFF
;
; Loops looking for the address-field prolog D5 AA 96, decodes the
; 4-and-4 encoded volume/track/sector/checksum, then reads the data
; field at D5 AA AD prolog. Decodes 342 GCR nibbles into 256 data bytes
; plus an 86-byte secondary buffer at $0900,Y. Validates DE AA epilog.
; Returns carry clear on success / set on failure.
; ============================================================================


            LDY #$20                        ; $0A99 A0 20
            DEY                             ; $0A9B 88
            BEQ $0B01                       ; $0A9C F0 63
            LDA $C08C,X                     ; $0A9E BD 8C C0
            BPL $0A9E                       ; $0AA1 10 FB
            EOR #$D5                        ; $0AA3 49 D5
            BNE $0A9B                       ; $0AA5 D0 F4
            NOP                             ; $0AA7 EA
            LDA $C08C,X                     ; $0AA8 BD 8C C0
            BPL $0AA8                       ; $0AAB 10 FB
            CMP #$AA                        ; $0AAD C9 AA
            BNE $0AA3                       ; $0AAF D0 F2
            LDY #$56                        ; $0AB1 A0 56
            LDA $C08C,X                     ; $0AB3 BD 8C C0
            BPL $0AB3                       ; $0AB6 10 FB
            CMP #$AD                        ; $0AB8 C9 AD
            BNE $0AA3                       ; $0ABA D0 E7
            NOP                             ; $0ABC EA
            NOP                             ; $0ABD EA
            LDA #$00                        ; $0ABE A9 00
            DEY                             ; $0AC0 88
            STY $26                         ; $0AC1 84 26
            LDY $C08C,X                     ; $0AC3 BC 8C C0
            BPL $0AC3                       ; $0AC6 10 FB
            EOR $BD04,Y                     ; $0AC8 59 04 BD
            LDY $26                         ; $0ACB A4 26
            STA $0C00,Y                     ; $0ACD 99 00 0C
            BNE $0AC0                       ; $0AD0 D0 EE
            STY $26                         ; $0AD2 84 26
            LDY $C08C,X                     ; $0AD4 BC 8C C0
            BPL $0AD4                       ; $0AD7 10 FB
            EOR $BD04,Y                     ; $0AD9 59 04 BD
            LDY $26                         ; $0ADC A4 26
            STA $0900,Y                     ; $0ADE 99 00 09
            INY                             ; $0AE1 C8
            BNE $0AD2                       ; $0AE2 D0 EE
            LDY $C08C,X                     ; $0AE4 BC 8C C0
            BPL $0AE4                       ; $0AE7 10 FB
            CMP $BD04,Y                     ; $0AE9 D9 04 BD
            BNE $0B01                       ; $0AEC D0 13
            LDA $C08C,X                     ; $0AEE BD 8C C0
            BPL $0AEE                       ; $0AF1 10 FB
            CMP #$DE                        ; $0AF3 C9 DE
            BNE $0B01                       ; $0AF5 D0 0A
            NOP                             ; $0AF7 EA
            LDA $C08C,X                     ; $0AF8 BD 8C C0
            BPL $0AF8                       ; $0AFB 10 FB
            CMP #$AA                        ; $0AFD C9 AA
            BEQ $0B5D                       ; $0AFF F0 5C
            SEC                             ; $0B01 38
            RTS                             ; $0B02 60
            LDY #$FC                        ; $0B03 A0 FC
            STY $26                         ; $0B05 84 26
            INY                             ; $0B07 C8
            BNE $0B0E                       ; $0B08 D0 04
            INC $26                         ; $0B0A E6 26
            BEQ $0B01                       ; $0B0C F0 F3
            LDA $C08C,X                     ; $0B0E BD 8C C0
            BPL $0B0E                       ; $0B11 10 FB
            CMP #$D5                        ; $0B13 C9 D5
            BNE $0B07                       ; $0B15 D0 F0
            NOP                             ; $0B17 EA
            LDA $C08C,X                     ; $0B18 BD 8C C0
            BPL $0B18                       ; $0B1B 10 FB
            CMP #$AA                        ; $0B1D C9 AA
            BNE $0B13                       ; $0B1F D0 F2
            LDY #$03                        ; $0B21 A0 03
            LDA $C08C,X                     ; $0B23 BD 8C C0
            BPL $0B23                       ; $0B26 10 FB
            CMP #$96                        ; $0B28 C9 96
            BNE $0B13                       ; $0B2A D0 E7
            LDA #$00                        ; $0B2C A9 00
            STA $27                         ; $0B2E 85 27
            LDA $C08C,X                     ; $0B30 BD 8C C0
            BPL $0B30                       ; $0B33 10 FB
            ROL                             ; $0B35 2A
            STA $26                         ; $0B36 85 26
            LDA $C08C,X                     ; $0B38 BD 8C C0
            BPL $0B38                       ; $0B3B 10 FB
            AND $26                         ; $0B3D 25 26
            STA $002C,Y                     ; $0B3F 99 2C 00
            EOR $27                         ; $0B42 45 27
            DEY                             ; $0B44 88
            BPL $0B2E                       ; $0B45 10 E7
            TAY                             ; $0B47 A8
            BNE $0B01                       ; $0B48 D0 B7
            LDA $C08C,X                     ; $0B4A BD 8C C0
            BPL $0B4A                       ; $0B4D 10 FB
            CMP #$DE                        ; $0B4F C9 DE
            BNE $0B01                       ; $0B51 D0 AE
            NOP                             ; $0B53 EA
            LDA $C08C,X                     ; $0B54 BD 8C C0
            BPL $0B54                       ; $0B57 10 FB
            CMP #$AA                        ; $0B59 C9 AA
            BNE $0B01                       ; $0B5B D0 A4
            CLC                             ; $0B5D 18
            RTS                             ; $0B5E 60

; ============================================================================
; SEEK_TRACK ($0B5F) -- move drive head to requested track
;
; Standard four-phase stepper sequence. Reads current head position from
; $0478,Y (Apple monitor screen-hole convention), compares with desired
; track in A, computes step direction and count, energizes phase coils
; via SEEK_PHASE_ON / SEEK_PHASE_OFF in LC RAM, with per-step delays.
; ============================================================================


            STX $2B                         ; $0B5F 86 2B
            STA $2A                         ; $0B61 85 2A
            CMP $0478                       ; $0B63 CD 78 04
            BEQ $0BBB                       ; $0B66 F0 53
            LDA #$00                        ; $0B68 A9 00
            STA $26                         ; $0B6A 85 26
            LDA $0478                       ; $0B6C AD 78 04
            STA $27                         ; $0B6F 85 27
            SEC                             ; $0B71 38
            SBC $2A                         ; $0B72 E5 2A
            BEQ $0BA9                       ; $0B74 F0 33
            BCS $0B7F                       ; $0B76 B0 07
            EOR #$FF                        ; $0B78 49 FF
            INC $0478                       ; $0B7A EE 78 04
            BCC $0B84                       ; $0B7D 90 05
            ADC #$FE                        ; $0B7F 69 FE
            DEC $0478                       ; $0B81 CE 78 04
            CMP $26                         ; $0B84 C5 26
            BCC $0B8A                       ; $0B86 90 02
            LDA $26                         ; $0B88 A5 26
            CMP #$0C                        ; $0B8A C9 0C
            BCS $0B8F                       ; $0B8C B0 01
            TAY                             ; $0B8E A8
            SEC                             ; $0B8F 38
            JSR $BBAD                       ; $0B90 20 AD BB
            LDA $BBD1,Y                     ; $0B93 B9 D1 BB
            JSR $BBBC                       ; $0B96 20 BC BB
            LDA $27                         ; $0B99 A5 27
            CLC                             ; $0B9B 18
            JSR $BBB0                       ; $0B9C 20 B0 BB
            LDA $BBDD,Y                     ; $0B9F B9 DD BB
            JSR $BBBC                       ; $0BA2 20 BC BB
            INC $26                         ; $0BA5 E6 26
            BNE $0B6C                       ; $0BA7 D0 C3
            JSR $BBBC                       ; $0BA9 20 BC BB
            CLC                             ; $0BAC 18
            LDA $0478                       ; $0BAD AD 78 04
            AND #$03                        ; $0BB0 29 03
            ROL                             ; $0BB2 2A
            ORA $2B                         ; $0BB3 05 2B
            TAX                             ; $0BB5 AA
            LDA $C080,X                     ; $0BB6 BD 80 C0
            LDX $2B                         ; $0BB9 A6 2B
            RTS                             ; $0BBB 60
            LDX #$11                        ; $0BBC A2 11
            DEX                             ; $0BBE CA
            BNE $0BBE                       ; $0BBF D0 FD
            INC $46                         ; $0BC1 E6 46
            BNE $0BCB                       ; $0BC3 D0 06
            INC $47                         ; $0BC5 E6 47
            BNE $0BCB                       ; $0BC7 D0 02
            DEC $47                         ; $0BC9 C6 47
            SEC                             ; $0BCB 38
            SBC #$01                        ; $0BCC E9 01
            BNE $0BBC                       ; $0BCE D0 EC
            RTS                             ; $0BD0 60
            ORA ($30,X)                     ; $0BD1 01 30
            PLP                             ; $0BD3 28
            BIT $20                         ; $0BD4 24 20
            ASL $1C1D,X                     ; $0BD6 1E 1D 1C
            NOP $1C1C,X                     ; $0BD9 1C 1C 1C
            NOP $2C70,X                     ; $0BDC 1C 70 2C
            ROL $22                         ; $0BDF 26 22
            SLO $1D1E,X                     ; $0BE1 1F 1E 1D
            NOP $1C1C,X                     ; $0BE4 1C 1C 1C
            NOP $A91C,X                     ; $0BE7 1C 1C A9
            LAX ($8D,X)                     ; $0BEA A3 8D
            SBC #$03                        ; $0BEC E9 03

; ============================================================================
; LOAD_CPM_LOOP ($0BEE) -- read N sectors from disk into staging
;
; Called by stage-2 loader (at Apple $1407 with A=$1D for 29 sectors).
; Initializes destination state at $03E0-$03EB, then loops:
;   - call LOAD_CPM_PRIM ($BE11 in LC RAM) to read one sector
;   - on error: call PRINT_ERR + jump to retry
;   - on success: advance sector counter, wrap at 16, advance track
;   - decrement remaining count, loop until done
;
; State conventions:
;   $03E0  current track number
;   $03E1  current sector (0..15)
;   $03E6  destination high byte ($60 = page $60xx)
;   $03E8  scratch
;   $03E9  sectors-loaded counter
;   $03EB  scratch
;
; The actual sector-read happens in LC RAM at $BE11; this routine is
; the orchestration layer. The second LOAD_CPM call from boot-finalization
; ($111E) re-enters here with different starting state to load additional
; sectors past the main 29.
; ============================================================================


            LDY #$00                        ; $0BEE A0 00
            STY $03E8                       ; $0BF0 8C E8 03
            STY $03E0                       ; $0BF3 8C E0 03
            INY                             ; $0BF6 C8
            STY $03E4                       ; $0BF7 8C E4 03
            STY $03EB                       ; $0BFA 8C EB 03
            LDA #$60                        ; $0BFD A9 60
            STA $03E6                       ; $0BFF 8D E6 03
            LDA #$0B                        ; $0C02 A9 0B
            STA $03E1                       ; $0C04 8D E1 03
            LDA #$1D                        ; $0C07 A9 1D
            PHA                             ; $0C09 48
            PHP                             ; $0C0A 08
            SEI                             ; $0C0B 78
            JSR $BE11                       ; $0C0C 20 11 BE
            BCC $0C19                       ; $0C0F 90 08
            JSR $FF2D                       ; $0C11 20 2D FF
            PLP                             ; $0C14 28
            PLA                             ; $0C15 68
            JMP $BBE9                       ; $0C16 4C E9 BB
            PLP                             ; $0C19 28
            INC $03E9                       ; $0C1A EE E9 03
            LDX $03E1                       ; $0C1D AE E1 03
            INX                             ; $0C20 E8
            CPX #$10                        ; $0C21 E0 10
            BNE $0C2A                       ; $0C23 D0 05
            LDX #$00                        ; $0C25 A2 00
            INC $03E0                       ; $0C27 EE E0 03
            STX $03E1                       ; $0C2A 8E E1 03
            PLA                             ; $0C2D 68
            SEC                             ; $0C2E 38
            SBC #$01                        ; $0C2F E9 01
            BNE $0C09                       ; $0C31 D0 D6
            LDA #$08                        ; $0C33 A9 08
            STA $03E9                       ; $0C35 8D E9 03
            RTS                             ; $0C38 60

; ============================================================================
; END OF CLEAN 6502 SECTION
;
; Bytes at $0C39-$0FFF are part of the BIOS first 1 KB; they're Z-80
; code, not 6502. See CPM223_BIOS.asm for the Z-80-side annotations
; (this region maps to Z-80 $1C39-$1FFF under the SoftCard's bit-12
; XOR for low addresses).
; ============================================================================
