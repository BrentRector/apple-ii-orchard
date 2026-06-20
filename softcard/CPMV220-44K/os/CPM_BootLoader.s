; ============================================================================
;  CPM_BootLoader.s  -  Microsoft SoftCard CP/M 2.20 (44K), 6502 boot image
; ============================================================================
;  On-disk image $0800-$13FF (3072 bytes) read from track 0 by the Apple
;  Disk II controller PROM.  Reverse-engineered from the raw on-disk bytes;
;  reassembles BYTE-IDENTICAL.
;
;  Clean-room: decompiled solely from these bytes + public Apple II / Disk II /
;  SoftCard knowledge and softcard/docs/CPM_Manual_Reconcile_Facts.md -- no
;  56K/2.23 source. The code/data split was adversarially verified; comment
;  PROSE is [AI] machine-inferred (a hint, not a manual citation) unless marked
;  [DOC <manual> <page>]; [?] = open question.
;
;  Layout (6502 addresses; this image lives on disk and at $0800 at boot):
;    $0800        sector-count byte read by the $Cn00 boot PROM (data, =$01)
;    $0801-$082C  BOOT0  - sector-load loop, then JMP $1000 (stage-2)
;    $082D-$083C  16-byte sector interleave table read by BOOT0
;    $083D-$085F  sign-on banner, high-bit ASCII, $FF-terminated
;    $0860-$08FF  $FF fill (rest of boot sector)
;    $0900-$09FF  $00 fill - the unused P6 PROM gap / secondary nibble buffer
;    $0A00-$0BDD  RWTS read primitives: pre-nibble, write, read, denibblize
;    $0ABE-$0AFF  $FF fill
;    $0BDE-$0C4F  RWTS seek (arm-step) routine
;    $0C50-$0C67  seek phase on/off countdown tables
;    $0C68-$0D55  $FF fill (CFF/$0D00 secondary nibble buffer overlay)
;    $0D56-$0DFF  6-and-2 read/write nibble translate table
;    $0E00-$0FFC  RWTS dispatch (READ/SEEK), front end, controller I/O
;    $0F9D-$0FAC  sector physical-to-logical interleave/skew table
;    $0FAD-$0FFC  RWTS top-level: read CP/M system into memory
;    $1000-$1188  STAGE-2 loader: find SoftCard, build config block, go Z-80
;    $1189-$11FF  $FF fill
;    $1200-$13FF  install image copied to $0200-$03FF at install time:
;                 Z-80 console/SoftCard init code, the 6502 $03C0 CPU-mode
;                 switch routine, and config-block parameter cells (all DATA
;                 here - never executed from $1200, only after the copy).
;
;  Manual anchors (SoftCard CP/M 2.20, (C)1980 Microsoft): config block at
;  $0200-$03FF (Z-80 0F200H-0F3FFH) [DOC S&HD 2-6/2-12 ; facts sec.2.2/3];
;  disk drivers+buffers $800-$FFF, screen $400-$7FF [DOC S&HD 2-6 ; facts sec.2.2];
;  Card Type Table SLTTYP=0F3B9H, slot S at 0F3B8H+S [DOC S&HD 2-26/2-27 ; facts
;  sec.3.6]; disk-count byte 0F3B8H [DOC S&HD 2-27 ; facts sec.3.7]; A$VEC=0F3D0H
;  [DOC S&HD 2-25 ; facts sec.4.2]; Z$CPU=0F3DEH [DOC S&HD 2-24/2-25 ; facts
;  sec.4.3]; 6502 mode-switch routine at $03C0, RESET/NMI/BRK vectors point here
;  [DOC S&HD 2-25 ; facts sec.2.4/4.4].
; ============================================================================

.setcpu "6502"
.segment "CODE"

; --- emit a high-bit (Apple "screen") ASCII string literal, byte-for-byte ---
.macro  ASCHI str
        .repeat .strlen(str), i
                .byte   .strat(str, i) | $80
        .endrep
.endmacro

; --- zero-page / soft-switch / Monitor symbols used below --------------------
SECTCNT         = $27           ; BOOT0 sector counter (also $27 RWTS scratch)
PTRL            = $3E           ; BOOT0 indirect-JMP / RWTS buffer pointer low
                                ; (STAGE-2's slot scan reuses $3E as the
                                ;  SoftCard-found flag -- see $105B/$1063)
PTRH            = $3F           ; BOOT0 indirect-JMP / RWTS buffer pointer high

; --- Apple II Autostart Monitor ROM entry points ($F800-$FFFF) ---------------
;  Canonical names per the Apple II Reference Manual / Monitor ROM disassembly;
;  single source of truth is shared/symbols/apple2.json. Now that the SoftCard
;  runs the genuine ROM these are the real routines, so the code below calls
;  them by name. "[used]" marks the entries this file references; the rest are
;  the standard callable entry points, kept here as the canonical table.
;  (Earlier this block carried ad-hoc, partly WRONG names -- e.g. $FB2F was
;  labelled MON_SETKBD, but $FB2F is TEXT and SETKBD is $FE89.)
; -- character / line output --
COUT            = $FDED         ; output A via (CSW); default -> COUT1            [used]
COUT1           = $FDF0         ; screen-only character output (default CSW target)
CROUT           = $FD8E         ; output a carriage return via COUT
PRBYTE          = $FDDA         ; print A as two hex digits
PRHEX           = $FDE3         ; print A's low nibble as one hex digit
; -- keyboard / line input --
RDKEY           = $FD0C         ; read a key via (KSW); default -> KEYIN
KEYIN           = $FD1B         ; default keyboard input (spin on KBD, clear strobe)
GETLN           = $FD6A         ; read a line into IN ($0200); returns X = length
; -- screen control --
TEXT            = $FB2F         ; set text mode + reset window to full screen     [used]
TEXT2           = $FB39         ; reset text window only
TABV            = $FB40         ; set cursor row (A), recompute BASL/BASH
BASCALC         = $FB5B         ; compute text base (BASL/BASH) from A = row
VIDOUT          = $FB78         ; plot A at cursor (no scroll / control handling)
VTAB            = $FC22         ; set BASL/BASH from CV
CLREOP          = $FC42         ; clear from cursor to end of page
HOME            = $FC58         ; clear text window, home cursor
SCROLL          = $FC70         ; scroll text window up one line
CLREOL          = $FC9C         ; clear from cursor to end of line
WAIT            = $FCA8         ; delay loop, duration from A
BELL            = $FBE4         ; sound the bell
; -- video/keyboard hooks + inverse flag --
SETINV          = $FE80         ; INVFLG = $3F  (COUT prints inverse)
SETNORM         = $FE84         ; INVFLG = $FF  (COUT prints normal)
SETKBD          = $FE89         ; reset KSW to KEYIN (keyboard input)             [used]
SETVID          = $FE93         ; reset CSW to COUT1 (screen output)              [used]
; -- register save/restore (the 6502<->Z-80 RPC handoff rides through these) --
;  The $45-$49 save area = the RPC register-pass cells: $45 A, $46 Y, $47 X,
;  $48 P, $49 = 6502 SP on exit [DOC S&HD 2-24/2-25 ; facts sec.4.1].
RESTORE         = $FF3F         ; A,X,Y,P <- save area $45-$48                    [used: $03C0]
SAVE            = $FF4A         ; A,X,Y,P,S -> save area $45-$49                   [used: $03C0]
; -- monitor / misc --
PRERR           = $FF2D         ; print "ERR" + bell                             [used]
IORTS           = $FF58         ; a bare RTS in the Apple Monitor ROM; the RPC
                                ; interrupt handler uses it as a no-op 6502 call
                                ; target [DOC S&HD 2-25 ; facts sec.4.5]
MONZ            = $FF65         ; monitor cold entry (reset stack, '*', GETLN)    [used]
MONITOR         = $FF69         ; monitor warm entry

.org $0800

; ----------------------------------------------------------------------------
;  $0800  sector-count byte.  The Disk II boot PROM reads this byte as the
;  count of additional sectors to load; it is DATA, not code.
; ----------------------------------------------------------------------------
        .byte   $01                     ; $0800  boot sector-count

; ----------------------------------------------------------------------------
;  BOOT0  ($0801)  -  entered by the $Cn00 controller PROM with X = slot*16.
;  Loads sectors into $0900.., then JMP STAGE2.
; ----------------------------------------------------------------------------
BOOT0:
        LDA SECTCNT                      ; $0801  sector # just read by PROM
        CMP #$09                         ; $0803  reached sector 9 yet?
        BNE @notdone                     ; $0805
        TXA                              ; $0807  X = slot*16
        LSR                              ; $0808  -> slot # in low nibble
        LSR                              ; $0809
        LSR                              ; $080A
        LSR                              ; $080B
        ORA #$C0                         ; $080C  form $Cn (PROM page)
        STA PTRH                         ; $080E  high byte of read vector
        LDA #$5C                         ; $0810  $Cn5C = PROM read-sector entry
        STA PTRL                         ; $0812
        LDA #$00                         ; $0814
        STA $00                          ; $0816  reset index
        INC SECTCNT                      ; $0818  bump physical sector
@notdone:
        INC $00                          ; $081A  advance load index
        LDY $00                          ; $081C
        CPY #$0B                         ; $081E  loaded 11 sectors ($00..$0A)?
        BNE @next                        ; $0820
        JMP STAGE2                       ; $0822  -> stage-2 loader at $1000
@next:
        LDA SECTAB,Y                     ; $0825  next physical sector to read
        STA $3D                          ; $0828
        JMP ($003E)                      ; $082A  call $Cn5C PROM read-sector

; 16-byte physical sector interleave table read by BOOT0.
SECTAB:
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E  ; $082D
        .byte   $01, $03, $05, $07, $09, $0B, $0D, $0F  ; $0835

; ----------------------------------------------------------------------------
;  Sign-on banner, high-bit Apple ASCII, terminated by the $FF fill below.
;  The "(C) 1980 MICROSOFT" copyright matches the manual's cold-boot sign-on
;  line; the full three-line "APPLE II CP/M / 44K vers. 2.2X / (C) 1980
;  MICROSOFT" banner is emitted later by the BIOS, not from this boot sector.
;  [DOC Vol1 1-8 ; facts sec.8.6]
; ----------------------------------------------------------------------------
BANNER:
        ASCHI   " COPYRIGHT (C) 1980 MICROSOFT - NK "   ; $083D-$085F

        .res    160, $FF                 ; $0860  rest of boot sector ($FF)
SECBUF2:
        .res    256, $00                 ; $0900  $00 fill / secondary buffer

; ============================================================================
;  RWTS read primitives  ($0A00..$0BDD)
; ============================================================================

; PRENIBBLE: pre-shift the user buffer into the 6+2 secondary buffer at $0D00.
PRENIBBLE:
        LDX #$55                         ; $0A00
        LDA #$00                         ; $0A02
@clr:
        STA NIBBUF,X                     ; $0A04  zero $0D00..$0D55
        DEX                              ; $0A07
        BPL @clr                         ; $0A08
        TAY                              ; $0A0A
        LDX #$AC                         ; $0A0B
@skip:
        BIT $AAA2                        ; $0A0D  3-byte skip idiom (enters +1)
@loop:
        DEY                              ; $0A10
        LDA (PTRL),Y                     ; $0A11  user buffer byte
        LSR                              ; $0A13
        ROL $0C56,X                      ; $0A14  -> 6+2 secondary buffer
        LSR                              ; $0A17
        ROL $0C56,X                      ; $0A18  (base $0C56, X>=$AC: $0D02+)
        STA SECBUF2,Y                    ; $0A1B
        INX                              ; $0A1E
        BNE @loop                        ; $0A1F
        TYA                              ; $0A21
        BNE @skip+1                      ; $0A22
        RTS                              ; $0A24

; WRITESECT: encode + write the prepared sector to the diskette.
WRITESECT:
        SEC                              ; $0A25
        STX SECTCNT                      ; $0A26
        STX $0678                        ; $0A28  save slot index *16
        LDA $C08D,X                      ; $0A2B  Q6L (sense write-protect)
        LDA $C08E,X                      ; $0A2E  Q7L
        BMI WR_DONE2                     ; $0A31  write protected -> abort
        LDA NIBBUF                       ; $0A33
        STA $26                          ; $0A36
        LDA #$FF                         ; $0A38
        STA $C08F,X                      ; $0A3A  Q7H (write mode)
        ORA $C08C,X                      ; $0A3D  Q6L
        PHA                              ; $0A40
        PLA                              ; $0A41
        NOP                              ; $0A42
        LDY #$04                         ; $0A43
@gap:
        PHA                              ; $0A45
        PLA                              ; $0A46
        JSR WR_NIB1                      ; $0A47
        DEY                              ; $0A4A
        BNE @gap                         ; $0A4B
        LDA #$D5                         ; $0A4D  data prologue D5 AA AD
        JSR WR_NIB                       ; $0A4F
        LDA #$AA                         ; $0A52
        JSR WR_NIB                       ; $0A54
        LDA #$AD                         ; $0A57
        JSR WR_NIB                       ; $0A59
        TYA                              ; $0A5C
        LDY #$56                         ; $0A5D
        BNE @sec2                        ; $0A5F
@sec2lp:
        LDA NIBBUF,Y                     ; $0A61
@sec2:
        EOR NIBBUF-1,Y                   ; $0A64
        TAX                              ; $0A67
        LDA WRTRANS,X                    ; $0A68  6+2 write translate
        LDX SECTCNT                      ; $0A6B
        STA $C08D,X                      ; $0A6D
        LDA $C08C,X                      ; $0A70
        DEY                              ; $0A73
        BNE @sec2lp                      ; $0A74
        LDA $26                          ; $0A76
        NOP                              ; $0A78
@mainlp:
        EOR SECBUF2,Y                    ; $0A79
        TAX                              ; $0A7C
        LDA WRTRANS,X                    ; $0A7D
        LDX $0678                        ; $0A80
        STA $C08D,X                      ; $0A83
        LDA $C08C,X                      ; $0A86
        LDA SECBUF2,Y                    ; $0A89
        INY                              ; $0A8C
        BNE @mainlp                      ; $0A8D
        TAX                              ; $0A8F
        LDA WRTRANS,X                    ; $0A90
        LDX SECTCNT                      ; $0A93
        JSR WR_NIB2                      ; $0A95
        LDA #$DE                         ; $0A98  data epilogue DE AA EB
        JSR WR_NIB                       ; $0A9A
        LDA #$AA                         ; $0A9D
        JSR WR_NIB                       ; $0A9F
        LDA #$EB                         ; $0AA2
        JSR WR_NIB                       ; $0AA4
        LDA #$FF                         ; $0AA7
        JSR WR_NIB                       ; $0AA9
        LDA $C08E,X                      ; $0AAC  Q7L (read mode)
WR_DONE2:
        LDA $C08C,X                      ; $0AAF  Q6L
        RTS                              ; $0AB2
        NOP                              ; $0AB3
WR_NIB:
        CLC                              ; $0AB4
WR_NIB1:
        PHA                              ; $0AB5
        PLA                              ; $0AB6
WR_NIB2:
        STA $C08D,X                      ; $0AB7  Q6H (load latch)
        ORA $C08C,X                      ; $0ABA  Q6L (shift out)
        RTS                              ; $0ABD

        .res    66, $FF                  ; $0ABE  fill

; READSECT: find the data field prologue (D5 AA AD), read+decode the sector.
READSECT:
        LDY #$20                         ; $0B00  retry budget
RD_RETRY:
        DEY                              ; $0B02
        BEQ RD_FAIL                      ; $0B03
RD_D5:
        LDA $C08C,X                      ; $0B05
        BPL RD_D5                        ; $0B08
RD_CHK1:
        EOR #$D5                         ; $0B0A
        BNE RD_RETRY                     ; $0B0C
        NOP                              ; $0B0E
RD_AA:
        LDA $C08C,X                      ; $0B0F
        BPL RD_AA                        ; $0B12
        CMP #$AA                         ; $0B14
        BNE RD_CHK1                      ; $0B16
        LDY #$56                         ; $0B18
RD_AD:
        LDA $C08C,X                      ; $0B1A
        BPL RD_AD                        ; $0B1D
        CMP #$AD                         ; $0B1F
        BNE RD_CHK1                      ; $0B21
        NOP                              ; $0B23
        NOP                              ; $0B24
        LDA #$00                         ; $0B25
RD_SEC2:
        DEY                              ; $0B27
        STY $26                          ; $0B28
RD_SEC2B:
        LDY $C08C,X                      ; $0B2A
        BPL RD_SEC2B                     ; $0B2D
        EOR NIBBUF,Y                     ; $0B2F  via read-translate table
        LDY $26                          ; $0B32
        STA NIBBUF,Y                     ; $0B34
        BNE RD_SEC2                      ; $0B37
RD_MAIN:
        STY $26                          ; $0B39
RD_MAINB:
        LDY $C08C,X                      ; $0B3B
        BPL RD_MAINB                     ; $0B3E
        EOR NIBBUF,Y                     ; $0B40
        LDY $26                          ; $0B43
        STA SECBUF2,Y                    ; $0B45
        INY                              ; $0B48
        BNE RD_MAIN                      ; $0B49
RD_CKSUM:
        LDY $C08C,X                      ; $0B4B
        BPL RD_CKSUM                     ; $0B4E
        CMP NIBBUF,Y                     ; $0B50  checksum check
        BNE RD_FAIL                      ; $0B53
RD_DE:
        LDA $C08C,X                      ; $0B55  data epilogue DE AA
        BPL RD_DE                        ; $0B58
        CMP #$DE                         ; $0B5A
        BNE RD_FAIL                      ; $0B5C
        NOP                              ; $0B5E
RD_DE2:
        LDA $C08C,X                      ; $0B5F
        BPL RD_DE2                       ; $0B62
        CMP #$AA                         ; $0B64
        BEQ RDADDR_OK                    ; $0B66
RD_FAIL:
        SEC                              ; $0B68  carry set = error
        RTS                              ; $0B69

; READADDR: read + verify the address field (volume/track/sector/checksum).
READADDR:
        LDY #$FC                         ; $0B6A
        STY $26                          ; $0B6C
RA_NEXT:
        INY                              ; $0B6E
        BNE RA_D5                        ; $0B6F
        INC $26                          ; $0B71
        BEQ RD_FAIL                      ; $0B73  timeout -> error
RA_D5:
        LDA $C08C,X                      ; $0B75  address prologue D5 AA 96
        BPL RA_D5                        ; $0B78
RA_CHK:
        CMP #$D5                         ; $0B7A
        BNE RA_NEXT                      ; $0B7C
        NOP                              ; $0B7E
RA_AA:
        LDA $C08C,X                      ; $0B7F
        BPL RA_AA                        ; $0B82
        CMP #$AA                         ; $0B84
        BNE RA_CHK                       ; $0B86
        LDY #$03                         ; $0B88  4 odd/even fields to read
RA_96:
        LDA $C08C,X                      ; $0B8A
        BPL RA_96                        ; $0B8D
        CMP #$96                         ; $0B8F
        BNE RA_CHK                       ; $0B91
        LDA #$00                         ; $0B93
RA_FIELD:
        STA $27                          ; $0B95
RA_ODD:
        LDA $C08C,X                      ; $0B97
        BPL RA_ODD                       ; $0B9A
        ROL                              ; $0B9C
        STA $26                          ; $0B9D
RA_EVEN:
        LDA $C08C,X                      ; $0B9F
        BPL RA_EVEN                      ; $0BA2
        AND $26                          ; $0BA4  odd/even -> byte
        STA $002C,Y                      ; $0BA6  store vol/trk/sec/cksum
        EOR $27                          ; $0BA9
        DEY                              ; $0BAB
        BPL RA_FIELD                     ; $0BAC
        TAY                              ; $0BAE
        BNE RD_FAIL                      ; $0BAF  checksum nonzero -> error
RA_DE:
        LDA $C08C,X                      ; $0BB1  address epilogue DE AA
        BPL RA_DE                        ; $0BB4
        CMP #$DE                         ; $0BB6
        BNE RD_FAIL                      ; $0BB8
        NOP                              ; $0BBA
RA_DE2:
        LDA $C08C,X                      ; $0BBB
        BPL RA_DE2                       ; $0BBE
        CMP #$AA                         ; $0BC0
        BNE RD_FAIL                      ; $0BC2
RDADDR_OK:
        CLC                              ; $0BC4  carry clear = success
        RTS                              ; $0BC5

; POSTNIBBLE: combine secondary + primary buffers back into the user buffer.
POSTNIBBLE:
        LDY #$00                         ; $0BC6
@col:
        LDX #$56                         ; $0BC8
@row:
        DEX                              ; $0BCA
        BMI @col                         ; $0BCB
        LDA SECBUF2,Y                    ; $0BCD
        LSR NIBBUF,X                     ; $0BD0
        ROL                              ; $0BD3
        LSR NIBBUF,X                     ; $0BD4
        ROL                              ; $0BD7
        STA (PTRL),Y                     ; $0BD8
        INY                              ; $0BDA
        BNE @row                         ; $0BDB
        RTS                              ; $0BDD

; SEEK: step the drive arm from current track ($0478) toward target track (A).
SEEK:
        STX $2B                          ; $0BDE  slot index
        STA $2A                          ; $0BE0  target track (half-track*2)
        CMP $0478                        ; $0BE2  current track
        BEQ SEEK_RET                     ; $0BE5  already there
        LDA #$00                         ; $0BE7
        STA $26                          ; $0BE9  step count
SEEK_LOOP:
        LDA $0478                        ; $0BEB
        STA $27                          ; $0BEE  prior track
        SEC                              ; $0BF0
        SBC $2A                          ; $0BF1
        BEQ SEEK_DONE                    ; $0BF3
        BCS @out                         ; $0BF5
        EOR #$FF                         ; $0BF7  outward...
        INC $0478                        ; $0BF9
        BCC @cmp                         ; $0BFC
@out:
        ADC #$FE                         ; $0BFE  ...vs inward
        DEC $0478                        ; $0C00
@cmp:
        CMP $26                          ; $0C03
        BCC @lim                         ; $0C05
        LDA $26                          ; $0C07
@lim:
        CMP #$0C                         ; $0C09
        BCS @clamp                       ; $0C0B
        TAY                              ; $0C0D
@clamp:
        SEC                              ; $0C0E
        JSR PHASE_OFF                    ; $0C0F
        LDA PHTAB_ON,Y                   ; $0C12  phase-on settle delay
        JSR SEEK_DELAY                   ; $0C15
        LDA $27                          ; $0C18
        CLC                              ; $0C1A
        JSR PHASE                        ; $0C1B
        LDA PHTAB_OFF,Y                  ; $0C1E  phase-off settle delay
        JSR SEEK_DELAY                   ; $0C21
        INC $26                          ; $0C24
        BNE SEEK_LOOP                    ; $0C26
SEEK_DONE:
        JSR SEEK_DELAY                   ; $0C28
        CLC                              ; $0C2B
PHASE_OFF:
        LDA $0478                        ; $0C2C  derive phase from track
PHASE:
        AND #$03                         ; $0C2F
        ROL                              ; $0C31
        ORA $2B                          ; $0C32  | slot index
        TAX                              ; $0C34
        LDA $C080,X                      ; $0C35  PHASEn off/on soft switch
        LDX $2B                          ; $0C38
SEEK_RET:
        RTS                              ; $0C3A

; SEEK_DELAY: count-down delay (A = loop count) used to settle the arm.
SEEK_DELAY:
        LDX #$11                         ; $0C3B
@inner:
        DEX                              ; $0C3D
        BNE @inner                       ; $0C3E
        INC $46                          ; $0C40
        BNE @next                        ; $0C42
        INC $47                          ; $0C44
        BNE @next                        ; $0C46
        DEC $47                          ; $0C48
@next:
        SEC                              ; $0C4A
        SBC #$01                         ; $0C4B
        BNE SEEK_DELAY                   ; $0C4D
        RTS                              ; $0C4F

; Seek phase settle-time tables (indexed by steps-remaining, 0..11).
PHTAB_ON:
        .byte   $01, $30, $28, $24, $20, $1E            ; $0C50
PHTAB_ON2:
        .byte   $1D, $1C, $1C, $1C, $1C, $1C            ; $0C56
PHTAB_OFF:
        .byte   $70, $2C, $26, $22, $1F, $1E            ; $0C5C
        .byte   $1D, $1C, $1C, $1C, $1C, $1C            ; $0C62

        .res    151, $FF                 ; $0C68  fill ($CFF read-translate -1)
        .byte   $FF                      ; $0CFF
NIBBUF:
        .res    86, $FF                  ; $0D00  primary 6+2 nibble buffer

; 6-and-2 read/write disk nibble translate table ($96..$FF -> 6-bit values).
WRTRANS:
        .byte   $96, $97, $9A, $9B, $9D, $9E, $9F, $A6  ; $0D56
        .byte   $A7, $AB, $AC, $AD, $AE, $AF, $B2, $B3  ; $0D5E
        .byte   $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC  ; $0D66
        .byte   $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3  ; $0D6E
        .byte   $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE  ; $0D76
        .byte   $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC  ; $0D7E
        .byte   $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6  ; $0D86
        .byte   $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF  ; $0D8E
        .byte   $00, $01, $98, $99, $02, $03, $9C, $04  ; $0D96
        .byte   $05, $06, $A0, $A1, $A2, $A3, $A4, $A5  ; $0D9E
        .byte   $07, $08, $A8, $A9, $AA, $09, $0A, $0B  ; $0DA6
        .byte   $0C, $0D, $B0, $B1, $0E, $0F, $10, $11  ; $0DAE
        .byte   $12, $13, $B8, $14, $15, $16, $17, $18  ; $0DB6
        .byte   $19, $1A, $C0, $C1, $C2, $C3, $C4, $C5  ; $0DBE
        .byte   $C6, $C7, $C8, $C9, $CA, $1B, $CC, $1C  ; $0DC6
        .byte   $1D, $1E, $D0, $D1, $D2, $1F, $D4, $D5  ; $0DCE
        .byte   $20, $21, $D8, $22, $23, $24, $25, $26  ; $0DD6
        .byte   $27, $28, $E0, $E1, $E2, $E3, $E4, $29  ; $0DDE
        .byte   $2A, $2B, $E8, $2C, $2D, $2E, $2F, $30  ; $0DE6
        .byte   $31, $32, $F0, $F1, $33, $34, $35, $36  ; $0DEE
        .byte   $37, $38, $F8, $39, $3A, $3B, $3C, $3D  ; $0DF6
        .byte   $3E, $3F                                ; $0DFE

; ============================================================================
;  RWTS dispatch / controller front end  ($0E00..$0FFC)
; ============================================================================

RWTS_ENTRY:
        JMP RWTS_TOP                     ; $0E00  top-level read entry

; RWTS_DOIO: motor-on, run one read/seek operation, motor-off (IRQ-safe).
RWTS_DOIO:
        LDA $C083                        ; $0E03  read/write LC bank (RWTS ctx)
        PHP                              ; $0E06
        SEI                              ; $0E07
        JSR RWTS_RW                      ; $0E08
        LDA $C081                        ; $0E0B  restore ROM bank
        PLP                              ; $0E0E
        RTS                              ; $0E0F

; RWTS_RW: select drive, spin up, seek, then read the requested sector.
RWTS_RW:
        LDY #$02                         ; $0E10
        STY $06F8                        ; $0E12  retry count (whole-op)
        LDY #$04                         ; $0E15
        STY $04F8                        ; $0E17  retry count (per-sector)
        LDA $03E6                        ; $0E1A  requested slot*16
        TAX                              ; $0E1D
        CMP $03E7                        ; $0E1E  same drive as last?
        BEQ RW_SAMEDRV                   ; $0E21
        TXA                              ; $0E23
        TAY                              ; $0E24
        LDA $03E7                        ; $0E25  prior slot*16
        TAX                              ; $0E28
        TYA                              ; $0E29
        PHA                              ; $0E2A
        STA $03E7                        ; $0E2B
        LDA $C08E,X                      ; $0E2E  Q7L on prior drive
RW_WAIT1:
        LDY #$08                         ; $0E31
        LDA $C08C,X                      ; $0E33
RW_WAIT2:
        CMP $C08C,X                      ; $0E36  wait for spindle to coast
        BNE RW_WAIT1                     ; $0E39
        DEY                              ; $0E3B
        BNE RW_WAIT2                     ; $0E3C
        PLA                              ; $0E3E
        TAX                              ; $0E3F
RW_SAMEDRV:
        LDA $C08E,X                      ; $0E40  Q7L (read mode)
        LDA $C08C,X                      ; $0E43  Q6L
        LDY #$08                         ; $0E46
RW_SPIN:
        LDA $C08C,X                      ; $0E48
        PHA                              ; $0E4B
        PLA                              ; $0E4C
        PHA                              ; $0E4D
        PLA                              ; $0E4E
        STX $05F8                        ; $0E4F  current slot*16
        CMP $C08C,X                      ; $0E52  spinning yet?
        BNE RW_GO                        ; $0E55
        DEY                              ; $0E57
        BNE RW_SPIN                      ; $0E58
RW_GO:
        PHP                              ; $0E5A
        LDA $C089,X                      ; $0E5B  motor on
        LDA $03E8                        ; $0E5E  buffer pointer low
        STA PTRL                         ; $0E61
        LDA $03E9                        ; $0E63  buffer pointer high
        STA PTRH                         ; $0E66
        LDA #$EF                         ; $0E68  seek settle counter
        STA $46                          ; $0E6A
        LDA #$D8                         ; $0E6C
        STA $47                          ; $0E6E
        LDA $03E4                        ; $0E70  target track
        CMP $03E5                        ; $0E73  current track
        BEQ RW_NOSEEK                    ; $0E76
        STA $03E5                        ; $0E78
        PLP                              ; $0E7B
        LDY #$00                         ; $0E7C
        PHP                              ; $0E7E
RW_NOSEEK:
        ROR                              ; $0E7F
        BCC @rd1                         ; $0E80
        LDA $C08A,X                      ; $0E82  select drive 1/2
        BCS @rd2                         ; $0E85
@rd1:
        LDA $C08B,X                      ; $0E87
@rd2:
        ROR $35                          ; $0E8A
        PLP                              ; $0E8C
        PHP                              ; $0E8D
        BNE RW_AFTERSEEK                 ; $0E8E
        LDY #$07                         ; $0E90  initial settle delay
@dly:
        JSR SEEK_DELAY                   ; $0E92
        DEY                              ; $0E95
        BNE @dly                         ; $0E96
        LDX $05F8                        ; $0E98
RW_AFTERSEEK:
        LDA $03E0                        ; $0E9B  requested sector
        JSR XLATE_SECT                   ; $0E9E  physical interleave
        LDA $03EB                        ; $0EA1
        PLP                              ; $0EA4
        BNE RW_FINDSEC                   ; $0EA5
        CMP #$01                         ; $0EA7
        BEQ RW_FINDSEC                   ; $0EA9
RW_SETTLE:
        LDY #$12                         ; $0EAB  extra seek settle
RW_SETTLE2:
        DEY                              ; $0EAD
        BNE RW_SETTLE2                   ; $0EAE
        INC $46                          ; $0EB0
        BNE RW_SETTLE                    ; $0EB2
        INC $47                          ; $0EB4
        BNE RW_SETTLE                    ; $0EB6
RW_FINDSEC:
        ROR                              ; $0EB8
        PHP                              ; $0EB9
        BCS RW_REARM                     ; $0EBA
        JSR PRENIBBLE                    ; $0EBC
RW_REARM:
        LDY #$30                         ; $0EBF  sector-search budget
        STY $0578                        ; $0EC1
RW_SEARCH:
        LDX $05F8                        ; $0EC4
        JSR READADDR                     ; $0EC7  read address field
        BCC RW_GOTADDR                   ; $0ECA
RW_RETRY:
        DEC $0578                        ; $0ECC
        BPL RW_SEARCH                    ; $0ECF
RW_RECAL:
        LDA $0478                        ; $0ED1  recalibrate on repeated miss
        PHA                              ; $0ED4
        LDA #$60                         ; $0ED5
        JSR RECAL                        ; $0ED7
        DEC $06F8                        ; $0EDA
        BEQ RW_HARDFAIL                  ; $0EDD
        LDA #$04                         ; $0EDF
        STA $04F8                        ; $0EE1
        LDA #$00                         ; $0EE4
        JSR XLATE_SECT                   ; $0EE6
        PLA                              ; $0EE9
RW_RESEEK:
        JSR XLATE_SECT                   ; $0EEA
        JMP RW_REARM                     ; $0EED  re-arm (LDY #$30 at @noseek2)
RW_GOTADDR:
        LDY $2E                          ; $0EF0
        CPY $0478                        ; $0EF2  on the right track?
        BEQ RW_ONTRACK                   ; $0EF5
        LDA $0478                        ; $0EF7
        PHA                              ; $0EFA
        TYA                              ; $0EFB
        JSR RECAL                        ; $0EFC  step to correct track
        PLA                              ; $0EFF
        DEC $04F8                        ; $0F00
        BNE RW_RESEEK                    ; $0F03
        BEQ RW_RECAL                     ; $0F05
RW_HARDFAIL:
        PLA                              ; $0F07
        LDA #$40                         ; $0F08  error code
RW_RETURN:
        PLP                              ; $0F0A
        JMP RW_EXIT+1                    ; $0F0B  -> $0F3E (skip into STA $03EA)
RW_UNUSED:
        BEQ RW_OKEXIT                    ; $0F0E
RW_ONTRACK:
        LDA $2F                          ; $0F10  found sector #
        STA $03E3                        ; $0F12
        LDA $03E2                        ; $0F15
        BEQ RW_SECOK                     ; $0F18
        CMP $2F                          ; $0F1A  is it the one we want?
        BEQ RW_SECOK                     ; $0F1C
        LDA #$20                         ; $0F1E  wrong sector
        BNE RW_RETURN                    ; $0F20
RW_SECOK:
        LDA $03E1                        ; $0F22  logical sector wanted
        TAY                              ; $0F25
        LDA SKEWTAB,Y                    ; $0F26  interleave skew
        CMP $2D                          ; $0F29  matches found sector?
        BNE RW_RETRY                     ; $0F2B
        PLP                              ; $0F2D
        BCC RW_WRITE                     ; $0F2E  carry clear -> write op
        JSR READSECT                     ; $0F30  read the data field
        PHP                              ; $0F33
        BCS RW_RETRY                     ; $0F34
        PLP                              ; $0F36
        JSR POSTNIBBLE                   ; $0F37  decode into user buffer
RW_OKEXIT:
        CLC                              ; $0F3A
        LDA #$00                         ; $0F3B  status = ok
RW_EXIT:
        BIT $38                          ; $0F3D  skip idiom; RW_EXIT+1 = STA
        STA $03EA                        ; $0F3F  store completion status
        LDX $05F8                        ; $0F42
        LDA $C088,X                      ; $0F45  motor off
        RTS                              ; $0F48
RW_WRITE:
        JSR WRITESECT                    ; $0F49
        BCC RW_OKEXIT                    ; $0F4C
        LDA #$10                         ; $0F4E  write error code
        BNE RW_EXIT+1                    ; $0F50  -> $0F3E (skip into STA $03EA)

; XLATE_SECT: map requested sector through current half-track parity.
XLATE_SECT:
        ASL                              ; $0F52
        JSR XS_BODY                      ; $0F53
        LSR $0478                        ; $0F56
        RTS                              ; $0F59
XS_BODY:
        STA $2E                          ; $0F5A
        JSR DRIVE_IDX                    ; $0F5C
        LDA $0478,Y                      ; $0F5F
        BIT $35                          ; $0F62
        BMI @b1                          ; $0F64
        LDA $04F8,Y                      ; $0F66
@b1:
        STA $0478                        ; $0F69
        LDA $2E                          ; $0F6C
        BIT $35                          ; $0F6E
        BMI @b2                          ; $0F70
        STA $04F8,Y                      ; $0F72
        BPL @b3                          ; $0F75
@b2:
        STA $0478,Y                      ; $0F77
@b3:
        JMP SEEK                         ; $0F7A

; DRIVE_IDX: X (slot*16) -> Y (drive table index 0..15).
DRIVE_IDX:
        TXA                              ; $0F7D
        LSR                              ; $0F7E
        LSR                              ; $0F7F
        LSR                              ; $0F80
        LSR                              ; $0F81
        TAY                              ; $0F82
        RTS                              ; $0F83

; RECAL: step the arm to (A) track, tracking per-drive current track.
RECAL:
        PHA                              ; $0F84
        LDA $03E4                        ; $0F85
        ROR                              ; $0F88
        ROR $35                          ; $0F89
        JSR DRIVE_IDX                    ; $0F8B
        PLA                              ; $0F8E
        ASL                              ; $0F8F
        BIT $35                          ; $0F90
        BMI @b1                          ; $0F92
        STA $04F8,Y                      ; $0F94
        BPL @b2                          ; $0F97
@b1:
        STA $0478,Y                      ; $0F99
@b2:
        RTS                              ; $0F9C

; Logical->physical sector interleave (skew) table.
SKEWTAB:
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E  ; $0F9D
        .byte   $01, $03, $05, $07, $09, $0B, $0D, $0F  ; $0FA5

; RWTS_TOP: read the 16-sector CP/M system off track 0 into memory.
;  The shipped CP/M disk is 16-sector (DOS 3.3 / Pascal / Language Card format);
;  it will not boot a drive set up for 13-sector and vice versa
;  [DOC Vol1 1-8 ; facts sec.8.8].
RWTS_TOP:
        LDA #$A4                         ; $0FAD  buffer high = $A4
        STA $03E9                        ; $0FAF
        LDY #$00                         ; $0FB2
        STY $03E8                        ; $0FB4  buffer low = $00
        STY $03E0                        ; $0FB7  sector = 0
        INY                              ; $0FBA
        STY $03E4                        ; $0FBB  track = 1
        STY $03EB                        ; $0FBE
        LDA #$60                         ; $0FC1
        STA $03E6                        ; $0FC3  slot 6 (=$60): the disk
                                         ;        controller for drives A:/B:
                                         ;        must be in slot 6 [DOC S&HD
                                         ;        1-3/1-4 ; facts sec.8.9]
        LDA #$0B                         ; $0FC6
        STA $03E1                        ; $0FC8  starting logical sector
        LDA #$1C                         ; $0FCB  sectors-to-read count
RWTS_TOP_LP:
        PHA                              ; $0FCD
        PHP                              ; $0FCE
        SEI                              ; $0FCF
        JSR RWTS_RW                      ; $0FD0  read one sector
        BCC RWTS_TOP_OK                  ; $0FD3
        JSR PRERR                        ; $0FD5  read error -> "ERR" + bell, retry
        PLP                              ; $0FD8
        PLA                              ; $0FD9
        JMP RWTS_TOP                     ; $0FDA
RWTS_TOP_OK:
        PLP                              ; $0FDD
        INC $03E9                        ; $0FDE  next buffer page
        LDX $03E1                        ; $0FE1  next logical sector
        INX                              ; $0FE4
        CPX #$10                         ; $0FE5
        BNE @same                        ; $0FE7
        LDX #$00                         ; $0FE9  wrap to track+1, sector 0
        INC $03E0                        ; $0FEB
@same:
        STX $03E1                        ; $0FEE
        PLA                              ; $0FF1
        SEC                              ; $0FF2
        SBC #$01                         ; $0FF3
        BNE RWTS_TOP_LP                  ; $0FF5
        LDA #$08                         ; $0FF7
        STA $03E9                        ; $0FF9
        RTS                              ; $0FFC

        .byte   $FF, $FF                 ; $0FFD  fill
        .byte   $FF                      ; $0FFF  (overwritten at runtime)

; ============================================================================
;  STAGE-2 loader  ($1000..$1188)
;  These are STAGE-2's own instructions; the 6502 runs them once, here, at boot
;  start. Be aware that the RAM at $1000..$100D is then REWRITTEN twice, so over
;  the boot it holds three unrelated pieces of code in turn -- one tenant at a
;  time, never together:
;    1. these STAGE-2 startup instructions       -- run by the 6502 (now)
;    2. SOFTCARD_PROBE_OVL (copied in just below) -- run by the Z-80 during the
;       slot scan (the SoftCard maps the Z-80 reset address $0000 to Apple $1000)
;    3. JMP $AA00 (planted after the system loads) -- run by the Z-80 to enter BIOS
;  The 6502 only ever runs tenant 1; the Z-80 only ever runs tenants 2 and 3.
;  No bytes here are ever executed by both CPUs, or as both 6502 and Z-80.
; ============================================================================

STAGE2:
        LDA $C081                        ; $1000  read ROM / LC config
        LDA $C081                        ; $1003
        JSR DRIVE_IDX                    ; $1006
        PHA                              ; $1009
        STA $C088,X                      ; $100A  motor off
        LDA #$00                         ; $100D
        STA $0478,Y                      ; $100F  zero current-track tables
        STA $04F8,Y                      ; $1012
        JSR TEXT                         ; $1015  text mode + full-screen window
        JSR SETVID                       ; $1018  CSW -> COUT1 (screen output)
        JSR SETKBD                       ; $101B  KSW -> KEYIN (keyboard input)
        PLA                              ; $101E
        LDX #$FF                         ; $101F
        TXS                              ; $1021  reset stack
        CMP #$06                         ; $1022  booted from slot 6? -- the
                                         ;        slot-6 disk controller is the
                                         ;        required A:/B: boot device
                                         ;        [DOC Vol1 1-3/1-4 ; facts sec.8.9]
        BEQ S2_OK                        ; $1024
        LDY #$00                         ; $1026
S2_ERR1:
        LDA MSG_SLOT6,Y                  ; $1028  "MUST BOOT FROM SLOT SIX"
        BEQ S2_ERR1_END                  ; $102B
        JSR COUT                         ; $102D  print error message char
        INY                              ; $1030
        BNE S2_ERR1                      ; $1031
S2_ERR1_END:
        JMP MONZ                         ; $1033  drop to the monitor
S2_OK:
        LDY #$0E                         ; $1036  install Z-80 SoftCard-probe overlay
S2_INSTOVL:
        LDA SOFTCARD_PROBE_OVL,Y         ; $1038  copy +1..+14 -> $1000..$100D
        STA $0FFF,Y                      ; $103B
        DEY                              ; $103E
        BNE S2_INSTOVL                   ; $103F
S2_COPYCFG:
        LDA INSTALL_IMG,Y                ; $1041  copy config image lo half
        STA $0200,Y                      ; $1044  $1200..$12FF -> $0200..$02FF
        DEY                              ; $1047
        BNE S2_COPYCFG                   ; $1048
        LDY #$F1                         ; $104A
S2_COPYCFG2:
        LDA INSTALL_IMG+$FF,Y            ; $104C  copy config image hi half
        STA $02FF,Y                      ; $104F  $12FF..$13F0 -> $02FF..$03F0
        DEY                              ; $1052
        BNE S2_COPYCFG2                  ; $1053
        STY $03B8                        ; $1055  disk-count byte = 0 (Z-80
                                         ;        0F3B8H; = #controllers x2)
                                         ;        [DOC S&HD 2-27 ; facts sec.3.7]
        STY $3C                          ; $1058  scan pointer low = 0
        DEY                              ; $105A
        STY $3E                          ; $105B  $3E = $FF: the SoftCard-found
                                         ;        flag (cleared to 0 by a slot's
                                         ;        probe handshake, INC'd to 1 once
                                         ;        found -- see $107F / $10C4)
        LDY #$C7                         ; $105D  scan slots $C7..$C1
S2_SLOTSCAN:
        JSR SCAN_PROBE                   ; $105F  WRITE $Cn00 to probe for SoftCard
        NOP                              ; $1062
        LDA $3E                          ; $1063  the probe's handshake clears $3E
        BEQ S2_SOFTCARD                  ; $1065  $3E=0 -> SoftCard found in this slot
        JSR SUM_ROM                      ; $1067  checksum the card ROM
        STA $40                          ; $106A
        STX $41                          ; $106C
        JSR SUM_ROM                      ; $106E  checksum again, compare
        CPX #$00                         ; $1071
        BEQ S2_HASROM                    ; $1073
        CMP $40                          ; $1075
        BNE S2_HASROM                    ; $1077
        CPX $41                          ; $1079
        BEQ S2_DISKCTRL                  ; $107B  stable -> classify
        BNE S2_HASROM                    ; $107D
S2_SOFTCARD:
        INC $3E                          ; $107F  mark SoftCard found at $Cn00
        STY $03C8                        ; $1081
        LDA #$00                         ; $1084
        STA $03C7                        ; $1086
        STA $03DE                        ; $1089  Z$CPU low byte = 0 -- the
                                         ;        SoftCard-location cell at Z-80
                                         ;        0F3DEH: low byte 0, high byte
                                         ;        of form 0ENH (N = SoftCard slot)
                                         ;        [DOC S&HD 2-24/2-25 ; facts sec.4.3]
        TYA                              ; $108C
        CLC                              ; $108D
        ADC #$20                         ; $108E  form $En high byte ($Cn + $20)
        STA $03DF                        ; $1090  Z$CPU high byte = $En
S2_HASROM:
        LDX #$00                         ; $1093  card type = unknown/none
        BEQ S2_STORETYPE                 ; $1095
S2_DISKCTRL:
        LDX #$04                         ; $1097  signature compare index
S2_SIGCMP:
        LDY #$05                         ; $1099
        LDA ($3C),Y                      ; $109B  ROM byte $Cn05
        CMP SIG_BYTE5,X                  ; $109D
        BNE S2_SIGNEXT                   ; $10A0
        LDY #$07                         ; $10A2
        LDA ($3C),Y                      ; $10A4  ROM byte $Cn07
        CMP SIG_BYTE7,X                  ; $10A6
        BEQ S2_SIGMATCH                  ; $10A9
S2_SIGNEXT:
        DEX                              ; $10AB
        BNE S2_SIGCMP                    ; $10AC
S2_SIGMATCH:
        INX                              ; $10AE
        CPX #$02                         ; $10AF  type 2 = Disk II controller?
                                         ;        (Card Type Table value 2 =
                                         ;        Apple Disk II Controller)
                                         ;        [DOC S&HD 2-26/2-27 ; facts sec.3.6]
        BNE S2_STORETYPE                 ; $10B1
        INC $03B8                        ; $10B3  bump disk-count byte (one per
                                         ;        controller) [DOC S&HD 2-27 ;
                                         ;        facts sec.3.7]
S2_STORETYPE:
        LDY $3D                          ; $10B6  slot # ($Cn high byte)
        TXA                              ; $10B8
        STA $02F8,Y                      ; $10B9  Card Type Table entry, install
                                         ;        offset $02F8+slot -> runtime
                                         ;        SLTTYP 0F3B9H, slot S at
                                         ;        0F3B8H+S [DOC S&HD 2-26/2-27 ;
                                         ;        facts sec.3.6]
        DEY                              ; $10BC
        CPY #$C0                         ; $10BD  done all 7 slots?
        BNE S2_SLOTSCAN                  ; $10BF
        ASL $03B8                        ; $10C1  disk count *2: the Disk Count
                                         ;        Byte = #controllers x2 [DOC
                                         ;        S&HD 2-27 ; facts sec.3.7]
        LDA $3E                          ; $10C4
        CMP #$01                         ; $10C6  SoftCard found?
        BEQ S2_GOTSOFTCARD               ; $10C8
        STY $3D                          ; $10CA
        LDA #$85                         ; $10CC
        STA $3C                          ; $10CE
        STA $C085                        ; $10D0
        LDA $3E                          ; $10D3
        BEQ S2_GOTSOFTCARD               ; $10D5
        LDY #$00                         ; $10D7
S2_ERR2:
        LDA MSG_NOCARD,Y                 ; $10D9  "CAN'T FIND Z80 SOFTCARD"
        BEQ S2_ERR2_END                  ; $10DC
        JSR COUT                         ; $10DE  print message char
        INY                              ; $10E1
        BNE S2_ERR2                      ; $10E2
S2_ERR2_END:
        JMP MONZ                         ; $10E4  drop to the monitor
S2_GOTSOFTCARD:
        LDY #$10                         ; $10E7  copy RWTS param block
S2_COPYPARM:
        LDA RWTS_PARM,Y                  ; $10E9  $13EF..$13FF -> $03EF..$03FF
        STA $03EF,Y                      ; $10EC
        DEY                              ; $10EF
        BNE S2_COPYPARM                  ; $10F0
        LDA #$C3                         ; $10F2  plant JMP at $1000 ...
        STA STAGE2                       ; $10F4
        LDA #$00                         ; $10F7
        STA $1001                        ; $10F9
        LDA #$AA                         ; $10FC  ... = JMP $AA00 (BIOS, later)
        STA $1002                        ; $10FE
        JSR RWTS_TOP                     ; $1101  read the CP/M system image
        LDA #$16                         ; $1104  patch sector count in RWTS
        STA $0FCC                        ; $1106
        LDY #$06                         ; $1109  install 6502 reset vectors --
                                         ;        RESET/NMI/BREAK at $FFFA-$FFFF
                                         ;        all point at the mode-switch
                                         ;        routine $03C0 [DOC S&HD 2-25 ;
                                         ;        facts sec.2.4/4.4]
S2_VECCOPY:
        LDA VEC_IMG-1,Y                  ; $110B  reads $1125..$112A -> $FFFA..
        STA $FFF9,Y                      ; $110E
        DEY                              ; $1111
        BNE S2_VECCOPY                   ; $1112
        JMP $03D2                        ; $1114  enter mode-switch ($03C0 rtn
                                         ;        at STA $C081) -> hand to Z-80.
                                         ;        $03C0 = the 6502->Z-80 mode-
                                         ;        switch routine [DOC S&HD 2-25 ;
                                         ;        facts sec.2.4/4.4]

; SUM_ROM: 16-bit checksum of a peripheral-card ROM at ($3C).
SUM_ROM:
        LDA #$00                         ; $1117
        TAX                              ; $1119
        TAY                              ; $111A
@lp:
        CLC                              ; $111B
        ADC ($3C),Y                      ; $111C
        BCC @nc                          ; $111E
        INX                              ; $1120
@nc:
        INY                              ; $1121
        BNE @lp                          ; $1122
        RTS                              ; $1124

; 6502 reset/NMI/IRQ vector image installed at $FFF9..$FFFF (point at $03C0):
; the three 6502 hardware vectors (NMI/RESET/IRQ-BRK) all target the $03C0
; 6502->Z-80 mode-switch routine [DOC S&HD 2-6, 2-25 ; facts sec.2.4/4.4].
VEC_IMG:
        .byte   $C0, $03, $C0, $03, $C0, $03            ; $1125

; MSG_NOCARD: "CAN'T FIND Z80 SOFTCARD" (CR-padded), $00-terminated.
MSG_NOCARD:
        .byte   $8D, $8D, $8D, $8D                      ; $112B
        ASCHI   "CAN'T FIND Z80 SOFTCARD"               ; $112F
        .byte   $8D                                     ; $1146
        .byte   $8D, $8D, $00                           ; $1147

; MSG_SLOT6: "MUST BOOT FROM SLOT SIX" (CR-padded), $00-terminated (at $1168).
MSG_SLOT6:
        .byte   $8D, $8D, $8D, $8D                      ; $114A
        ASCHI   "MUST BOOT FROM SLOT SIX"               ; $114E
        .byte   $8D                                     ; $1165
        .byte   $8D, $8D                                ; $1166

; SOFTCARD_PROBE_OVL: the slot-probe handshake. A leading $00 (the MSG_SLOT6
; terminator, data) followed by 13 bytes of Z-80 code. During the slot scan the
; boot copies those 13 bytes to RAM at $1000..$100C, over STAGE-2's startup
; instructions (which the 6502 has already finished with -- see STAGE2). From then
; on they run on the Z-80, never the 6502: the SoftCard maps the Z-80 reset address
; ($0000) to Apple $1000, so a slot-probe write (SCAN_PROBE) switches to the Z-80
; and lands it here, where it flags "found" and bounces back to the 6502. The 13
; Z-80 bytes are assembled from CPM_BootLoader_ProbeOvl.asm and INCBIN'd; the JR's
; offset byte is the following SIG_BYTE5[0]=$F2 (so SAVEBIN stops at the opcode).
SOFTCARD_PROBE_OVL:
        .byte   $00                     ; $1168  MSG_SLOT6 terminator (data)
;   >>> CPM_BootLoader_ProbeOvl.asm -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>
;
; FOUND   EQU $F03E        ; the 6502's $3E "SoftCard found" flag (Z-80 view of $003E)
; PROBED  EQU $F03D        ; the probed slot's $Cn high byte, set by the 6502 ($003D)
;
;     ORG $1000
;
; PROBE_OVL:
;     XOR A                ; A = 0
;     LD (FOUND),A         ; $3E = 0 -> "SoftCard found in the probed slot"
;     LD L,A               ; HL low = 0
;     LD A,(PROBED)        ; A = probed slot $Cn
;     ADD A,$20            ; $Cn -> $En (the slot's Z-80 I/O page)
;     LD H,A               ; HL = $En00
;     LD (HL),A            ; touch $En00 -> Apple $Cn00 -> switch back to the 6502
;     JR PROBE_OVL         ; loop ($18; offset byte $F2 supplied by host SIG_BYTE5[0])
;   <<< end listing <<<
        .incbin "CPM_BootLoader_ProbeOvl.bin"   ; $1169-$1175  (Z-80; JR offset = SIG_BYTE5[0])

; Card-signature compare tables (bytes $Cn05 / $Cn07 for known card types).
SIG_BYTE5:
        .byte   $F2, $03, $18, $38                      ; $1176
SIG_BYTE7:
        .byte   $48, $3C, $38, $18, $48, $FF            ; $117A

; SCAN_PROBE: probe slot $Cn for the SoftCard. Points ($3C/$3D) at $Cn00 and
; self-mods the STA operand so it WRITES $Cn00. That write IS the probe: on the
; SoftCard's slot it toggles the CPU (the card has no ROM -- any access to its
; slot page switches), the Z-80 runs the SOFTCARD_PROBE_OVL handshake at $1000 and clears
; the $3E "found" flag before bouncing back, so the caller's LDA $3E reads 0.
; Ordinary ROM cards / empty slots ignore the write, leaving $3E unchanged.
SCAN_PROBE:
        STY $3D                          ; $1180  high byte = $Cn
        STY SCAN_PROBE+7                 ; $1182  patch high byte of STA operand
        STA $C000                        ; $1185  WRITE $Cn00 -- the SoftCard probe.
                                         ;        A WRITE (not a read) to the
                                         ;        slot-dependent control area
                                         ;        $CN00 switches CPUs [DOC S&HD
                                         ;        2-24/2-31 ; facts sec.2.5]
        RTS                              ; $1188

        .res    119, $FF                 ; $1189  fill

; ============================================================================
;  INSTALL IMAGE  ($1200..$13FF)  -  copied to $0200..$03FF at install time.
;  This is the I/O Configuration Block / mode-switch / Z-80 init image.  It is
;  DATA in this 6502 boot image: nothing here is executed at $1200.  After the
;  copy it becomes, at $0200..$03FF (the I/O Configuration Block, Z-80
;  0F200H-0F3FFH [DOC S&HD 2-6/2-12 ; facts sec.2.2/3]):
;    $034A..  Z-80 console / SoftCard lower-case-driver init code
;    $03C0..  the 6502 -> Z-80 CPU mode-switch routine (runs after the copy)
;             [DOC S&HD 2-25 ; facts sec.2.4/4.4]
;    $03D0..  A$VEC (6502-call vector) [DOC S&HD 2-25 ; facts sec.4.2],
;             $03DE Z$CPU (SoftCard location) [DOC S&HD 2-24/2-25 ; facts sec.4.3]
;    $03EF..  RWTS parameter cells
;  $1200..$1349 is $00 fill (the low config-block page is built at runtime).
; ============================================================================

INSTALL_IMG:
        .res    255, $00                 ; $1200  $00 fill ($0200 page)
        .res    75, $00                  ; $12FF  $00 fill ($0300..$0349)

; --- $134A..$137B : Z-80 console driver for a slot-3 serial (type-3) card -----
;  These 50 bytes are Z-80 code, not 6502 -- assembled by the Z-80 assembler from
;  CPM_BootLoader_ConInit.asm (ORG'd at its $F34A run address) and INCBIN'd here.
;  Stored at this offset in the boot image, copied to Apple $034A at install,
;  executed by the Z-80 at $F34A. The exact source listing follows so this file
;  is self-documenting; CPM_BootLoader_ConInit.asm is authoritative.
;  Structures the driver touches (manual-documented): SLTTYP3 0F3BBH = the
;  Card Type Table entry for slot 3, =3 for a serial card [DOC S&HD 2-26/2-27 ;
;  facts sec.3.6]; A_ACC 0F045H = the 6502 A-register RPC pass cell, A_VEC
;  0F3D0H = 6502 sub-call address, Z_CPU 0F3DEH = SoftCard location (a store
;  there flips CPUs) [DOC S&HD 2-24/2-25 ; facts sec.4.1/4.2/4.3].
;   >>> CPM_BootLoader_ConInit.asm -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>
;
; A_ACC   EQU $F045        ; 6502 A-register RPC pass cell ($45)
; A_VEC   EQU $F3D0        ; address of 6502 subroutine to call (low-high)
; Z_CPU   EQU $F3DE        ; SoftCard location cell ($En00); a store there flips CPUs
; SLTTYP3 EQU $F3BB        ; Card Type Table entry for slot 3
; SLOT3IO EQU $E0BE        ; slot-3 device status register (Apple $C0BE)
;
;     ORG $F34A
;
; CON_STATUS:                     ; $F34A  console status
;     LD A,(SLTTYP3)              ; slot-3 card type
;     CP $03                      ; a type-3 (serial) card?
;     JP NZ,$AB0C                 ; no -> BIOS console status
;     LD A,(SLOT3IO)              ; serial status register
;     RRA                         ; bit0 (char ready) -> carry
;     SBC A,A                     ; A = $FF if ready else $00
;     RET
; CON_INPUT:                      ; $F358  console input
;     CALL $AB12                  ; fetch raw key via BIOS
;     AND $7F                     ; strip high bit
;     RET
; CON_OUTPUT:                     ; $F35E  console output (char in C)
;     LD A,(SLTTYP3)              ; slot-3 card type
;     CP $03                      ; a type-3 (serial) card?
;     JP NZ,$AC3E                 ; no -> BIOS console output
; OUT_WAIT:                       ; $F366
;     LD A,(SLOT3IO)              ; serial status register
;     AND $02                     ; Tx-ready bit set?
;     JR Z,OUT_WAIT               ; spin until ready
;     LD A,C                      ; char to send
;     LD (A_ACC),A                ; hand it to the 6502 (A-reg cell)
;     LD HL,$037C                 ; 6502 sub: STA $C0BF ; RTS
;     LD (A_VEC),HL               ; A$VEC := $037C
;     LD HL,(Z_CPU)               ; HL := $En00
;     LD (HL),A                   ; touch $En00 -> RPC runs the 6502
;     RET
;   <<< end listing <<<
        .incbin "CPM_BootLoader_ConInit.bin"   ; $134A..$137B  (Z-80; byte-identical)

; --- $137C..$137F : RPC_SERIAL_OUT -- 6502 routine called by the Z-80 console driver ---
; [AI] The Z-80 ConInit output path sets A$VEC=$037C then switches to the 6502, which runs
;      this (image copy at $137C, run address $037C): push the queued character to the slot-3
;      serial data register and return to the RPC loop. Real 6502 code, not config data.
RPC_SERIAL_OUT:
        STA $C0BF                       ; $137C  (run $037C) char -> slot-3 serial data reg
        RTS                             ; $137F
; --- $1380..$13BF : I/O Vector Table + screen-function / keyboard config -----------
;  This window is part of the I/O Configuration Block; at install offset $1380 it
;  copies to runtime $0380 = Z-80 0F380H.
;
;  $1380..$1395 (runtime $0380..$0394 = 0F380H..0F394H): the I/O Vector Table --
;  eleven two-byte little-endian primitive character-I/O vectors, each the address
;  the BIOS CONST/CONIN/CONOUT/READER/PUNCH/LIST routine JMPs through. In order:
;  #1 Console Status, #2/#3 Console Input, #4/#5 Console Output, #6/#7 Reader Input,
;  #8/#9 Punch Output, #10/#11 List Output. Here they point at this disk's console
;  handlers ($F34A CON_STATUS, $F358 CON_INPUT, $AB12, $F35E CON_OUTPUT, $AC3E) and
;  at the BIOS reader/punch/list stubs ($AD45, $AD3F, $AD2B, $AD20)
;  [DOC S&HD 2-18/2-19 ; facts sec.3.2].
;
;  $1396/$1397 (runtime $0396/$0397 = 0F396H/0F397H): the software screen-function
;  header -- SXYOFF (cursor XY coordinate offset; high bit selects X/Y transmit
;  order) then SFLDIN (lead-in character, 0 = none) [DOC S&HD 2-14 ; facts sec.3.3].
;  $1398.. (runtime $0398.. = SSFTAB 0F398H): the Software Screen Function table,
;  nine one-byte entries (Clear Screen, Clear-to-EOP, Clear-to-EOL, Set Normal,
;  Set Inverse, Home, Address Cursor, Cursor Up, Cursor Forward; 0 = unimplemented)
;  followed by the parallel Hardware Screen Function table (offset/lead-in at
;  0F3A1H/0F3A2H, fns at 0F3A3H..0F3AAH) [DOC S&HD 2-14/2-15 ; facts sec.3.4].
;  $13AC.. (runtime $03AC = 0F3ACH): Keyboard Character Redefinition Table -- up to
;  six {from,to} ASCII pairs (both high bits clear), end marked by a high-bit-set
;  byte [DOC S&HD 2-17 ; facts sec.3.5].
;  $13B8/$13B9.. (runtime $03B8/$03B9): install-time placeholder for the Disk Count
;  Byte (0F3B8H, #controllers x2) [DOC S&HD 2-27 ; facts sec.3.7] and the Card Type
;  Table (SLTTYP 0F3B9H, slot S at 0F3B8H+S) [DOC S&HD 2-26/2-27 ; facts sec.3.6];
;  CAVEAT: these two are rebuilt by the runtime slot scan (S2_SLOTSCAN above writes
;  the disk-count to $03B8 and per-slot types to $03B9+), so the bytes shipped here
;  are overwritten before use.
        .byte   $4A, $F3, $58, $F3, $12, $AB, $5E, $F3  ; $1380
        .byte   $3E, $AC, $45, $AD, $45, $AD, $3F, $AD  ; $1388
        .byte   $3F, $AD, $2B, $AD, $2B, $AD, $20, $1B  ; $1390
        .byte   $AA, $D9, $D4, $A9, $A8, $1E, $BD, $0B  ; $1398
        .byte   $0C, $A0, $00, $0C, $0B, $1D, $0E, $0F  ; $13A0
        .byte   $19, $1E, $1F, $1C, $0B, $5B, $00, $7F  ; $13A8
        .byte   $02, $5C, $15, $09, $FF, $FF, $FF, $FF  ; $13B0
        .byte   $02, $03, $00, $04, $01, $00, $02, $00  ; $13B8

; --- $13C0..$13DA : the 6502-side RPC service loop, copied to $03C0 -----------
;  The heart of the cooperative two-CPU protocol. The Z-80 is master; when it
;  needs the 6502 it switches here (the 6502 resumes at $03C9), runs one
;  requested routine, and hands the bus back. The register handoff rides through
;  the monitor's RESTORE/SAVE save area ($45-$49) -- the RPC register-pass cells:
;  $45 A, $46 Y, $47 X, $48 P, $49 = 6502 SP on exit [DOC S&HD 2-24/2-25 ;
;  facts sec.4.1]. Written as real 6502 below:
;  it runs at $03C0 but is assembled here in the install image and copied there;
;  every operand is absolute, so the bytes are identical at either address (and
;  the JMP target is the literal runtime $03C0, not this image copy). The
;  STA $C700 is the slot-7 access implicated in the corrected 2.20 $C800-window
;  hang mechanism (see CPM_SoftCard_RealMap_Findings.md).
        LDA $C083                       ; $03C0  LC: read RAM bank2, write-enable
        LDA $C083                       ; $03C3   (two reads arm the LC write latch)
        STA $C700                       ; $03C6  WRITE to the slot-7 page ($CN00)
                                        ;        switches CPUs -> to the Z-80
                                        ;        [DOC S&HD 2-24/2-31 ; facts sec.2.5]
        LDA $C081                       ; $03C9  (resume here) LC: read ROM
        JSR RESTORE                     ; $03CC  A,X,Y,P <- $45-$48 (Z-80's call params)
        JSR $1010                       ; $03CF  dispatch the requested 6502 RPC routine
        STA $C081                       ; $03D2  LC: read ROM
        JSR SAVE                        ; $03D5  A,X,Y,P,S -> $45-$49 (results for Z-80)
        JMP $03C0                       ; $03D8  loop -> hand the bus back to the Z-80

; --- $13DB..$13EE : RPC / config cells (-> $03DB..$03EE) ----------------------
;  $03D0 A$VEC (6502 sub-call address, low-high) [DOC S&HD 2-25 ; facts sec.4.2]
;  and $03DE Z$CPU (SoftCard location) [DOC S&HD 2-24/2-25 ; facts sec.4.3] live
;  in this window; here as initialized data.
        .byte   $00, $00                                ; $13DB
        .byte   $20, $00, $E7, $00, $0A, $00, $CD, $01  ; $13DD
        .byte   $01, $60, $60, $00, $03, $00, $02, $00  ; $13E5
        .byte   $00, $00                                ; $13ED

; RWTS_PARM: 17-byte RWTS parameter block copied to $03EF..$03FF at install.
RWTS_PARM:
        .byte   $00, $C0, $03, $C0, $03, $A6, $4C, $C0  ; $13EF
        .byte   $03, $4C, $C0, $03, $4C, $C0, $03, $C0  ; $13F7
        .byte   $03                                     ; $13FF
