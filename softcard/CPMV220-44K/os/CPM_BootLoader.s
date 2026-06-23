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
        .byte   $01                      ; boot sector-count

; ----------------------------------------------------------------------
; BOOT0 -- second-stage sector-load loop entered by the Disk II $Cn00 boot PROM
;   In:        X = slot*16 (left by the controller PROM at $0801 entry). $27
;              (named SECTCNT here) = the PROM's DESTINATION PAGE byte: the PROM
;              loaded boot sector 0 to $0800 then INC'd it to $09, so $27=$09 on
;              first entry [RE, from the standard Disk II P6 PROM convention:
;              $26/$27 = dest_lo/dest_hi, $3D = the sector the $Cn5C search looks
;              for]. ZP $00 is BOOT0's own logical index into SECTAB. The PROM has
;              already read sector 0 ($0800-$08FF) into memory.
;   Out:       10 further sectors of track 0 (physical 2,4,6,8,A,C,E,1,3,5 per
;              SECTAB[1..10]) read into $0A00..$13FF via the PROM's $Cn5C entry,
;              then JMP STAGE2 ($1000) to hand off to the stage-2 loader.
;   Clobbers:  A, Y; ZP $00 (SECTAB index), $3D (the physical sector the PROM
;              searches for), PTRL/PTRH ($3E/$3F = the $Cn5C indirect-call vector),
;              $27 (bumped once on the first pass).
;   Algorithm: On the FIRST pass only (detected by $27 = $09, i.e. the PROM's
;              destination page sits at $0900 right after it loaded $0800), derive
;              the slot number from X (slot*16 >> 4), OR in $C0 to form the PROM
;              page $Cn, and build the indirect-call vector PTRL/PTRH = $Cn5C (the
;              controller PROM's read-sector / search-for-prolog entry), then zero
;              the SECTAB index. Each pass advances the index in $00; once 10
;              sectors have been requested (index reaches $0B) it jumps to STAGE2.
;              Otherwise it fetches the next PHYSICAL sector number from the SECTAB
;              interleave table, stores it in $3D (where the PROM's search expects
;              it), and re-enters the PROM read routine via JMP (PTRL); the PROM
;              reads one sector, bumps its dest page, and JMPs back to $0801.
; ----------------------------------------------------------------------
BOOT0:
        LDA SECTCNT                      ; sector # just read by PROM
        ; first pass? the PROM's destination page is $09 right after it loaded $0800; if so, build
        ; the $Cn5C read vector below [RE]
        CMP #$09                         ; reached sector 9 yet?
        BNE @notdone
        ; derive the slot number from X (= slot*16) to form the controller PROM page $Cn
        TXA                              ; X = slot*16
        LSR                              ; -> slot # in low nibble
        LSR
        LSR
        LSR
        ; form the PROM page byte: slot N -> $Cn, the high byte of the $Cn5C read-sector entry
        ORA #$C0                         ; form $Cn (PROM page)
        STA PTRH                         ; high byte of read vector
        ; low byte $5C: PTRL/PTRH now address the Disk II PROM read-sector / search-prolog entry
        ; $Cn5C
        LDA #$5C                         ; $Cn5C = PROM read-sector entry
        STA PTRL
        LDA #$00
        ; reset BOOT0's SECTAB index to 0
        STA $00                          ; reset index
        INC SECTCNT                      ; bump physical sector
@notdone:
        ; advance to the next SECTAB index (sectors requested so far)
        INC $00                          ; advance load index
        LDY $00
        ; all 10 further sectors requested (index reached $0B = 11)? if so the image is loaded
        CPY #$0B                         ; loaded 11 sectors ($00..$0A)?
        BNE @next
        ; image fully loaded -- hand off to the stage-2 loader at $1000
        JMP STAGE2                       ; -> stage-2 loader at $1000
@next:
        ; map the logical index to the next PHYSICAL sector via the interleave table
        LDA SECTAB,Y                     ; next physical sector to read
        ; tell the PROM which physical sector to find (its $Cn5C search compares against $3D) [RE]
        STA $3D
        ; re-enter the controller PROM at $Cn5C through PTRL/PTRH to read that sector (it returns
        ; via JMP $0801)
        JMP ($003E)                      ; call $Cn5C PROM read-sector

; ----------------------------------------------------------------------
; SECTAB -- 16-byte physical-sector interleave table read by BOOT0
;   In:        indexed by BOOT0's logical sector counter Y (indices 1..10 used).
;   Out:       the physical sector number to feed the PROM's $Cn5C search via $3D.
;   Algorithm: pure DATA. Maps each logical load index to a physical track-0
;              sector in even-then-odd order ($00,$02,..,$0E, $01,$03,..,$0F).
;              BOOT0 uses indices 1..10 (physical 2,4,6,8,A,C,E,1,3,5); index 0
;              (sector 0) is skipped because the PROM already loaded it, and
;              indices 11..15 are unused. Genuine table data, not relocatable.
; ----------------------------------------------------------------------
SECTAB:
        ; even physical sectors $00..$0E (logical indices 0..7; BOOT0 uses 1..7)
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E
        ; odd physical sectors $01..$0F (logical indices 8..15; BOOT0 uses only 8..10)
        .byte   $01, $03, $05, $07, $09, $0B, $0D, $0F

; ----------------------------------------------------------------------
; BANNER -- cold-boot sign-on string (high-bit Apple screen ASCII)
;   In:        none (DATA).
;   Out:       the literal text " COPYRIGHT (C) 1980 MICROSOFT - NK ".
;   Algorithm: pure string DATA, each byte OR $80 (Apple screen ASCII), bounded by
;              the $FF fill that follows. The "(C) 1980 MICROSOFT" copyright
;              matches the manual cold-boot sign-on line [DOC Vol1 1-8 ; facts
;              sec.8.6]; the full three-line APPLE II CP/M banner is emitted later
;              by the BIOS, not from this boot sector. Whether/where the boot
;              loader itself prints this string is UNKNOWN from these bytes. Kept
;              as an ASCHI literal -- not relocatable.
; ----------------------------------------------------------------------
BANNER:
        ASCHI   " COPYRIGHT (C) 1980 MICROSOFT - NK " ; -$085F

        .res    160, $FF                 ; rest of boot sector ($FF)
; ----------------------------------------------------------------------
; SECBUF2 -- $0900-$09FF nibble buffer (boot-time $00 fill; RWTS scratch at run time)
;   In:        on disk this page is all $00 (it occupies the unused P6 PROM gap).
;              At RWTS run time it is one of the two 6-and-2 nibble buffers: it
;              holds the 256 high-6-bit values of the sector (PRENIBBLE shifts each
;              user byte's top bits here via STA SECBUF2,Y; WRITESECT/READSECT
;              stream it to/from disk). The companion 86-entry low-2-bits buffer is
;              at $0D00 (NIBBUF). [RE -- the file's layout map calls $0D00 the
;              "secondary" buffer, so the SECBUF2 vs NIBBUF naming is loose.]
;   Out:       n/a (scratch).
;   Clobbers:  rewritten wholesale by every RWTS sector operation.
;   Algorithm: DATA region, not code. Stored as 256 bytes of $00 in the image; the
;              RWTS primitives ($0A00+) reuse the page as nibble storage at run
;              time. TEMPORAL tenants: $00 fill on disk (boot) -> RWTS 6-and-2
;              nibble buffer once the loader runs the 6502 RWTS. Kept as a $00
;              fill -- not relocatable.
; ----------------------------------------------------------------------
SECBUF2:
        .res    256, $00                 ; $00 fill / secondary buffer

; ============================================================================
;  RWTS read primitives  ($0A00..$0BDD)
; ============================================================================

; ----------------------------------------------------------------------
; PRENIBBLE -- pre-shift the user data buffer into the 6-and-2 primary + secondary buffers
;   In:        (PTRL/PTRH $3E/$3F) -> 256-byte user sector buffer to encode
;   Out:       SECBUF2 ($0900..$09FF) holds the 256 PRIMARY bytes (the upper 6
;              bits of every user data byte); NIBBUF ($0D00..$0D55, reached as
;              NIBBUF-$AA,X with X=$AA..$FF) holds the 86 SECONDARY bytes (the
;              low 2 bits of three user bytes packed per cell)
;   Clobbers:  A, X, Y; SECBUF2[0..$FF]; NIBBUF[0..$55] (zeroed then filled)
;   Algorithm: zero the 86-byte secondary buffer (NIBBUF[$55..0]), then walk the
;              256 user bytes backwards (Y wraps $00 -> $FF down to 0). For each
;              byte, shift its two low bits out (LSR/ROL pairs) into the secondary
;              cell selected by X (three source bytes feed one secondary cell) and
;              store the remaining upper 6 bits into SECBUF2,Y. This is the standard
;              Apple 6-and-2 pre-nibble; WRITESECT then maps each value through
;              WRTRANS and clocks it onto the disk. [RE]
; ----------------------------------------------------------------------
PRENIBBLE:
        ; clear the 86-byte secondary buffer NIBBUF[$55..$00]
        LDX #$55
        LDA #$00
@clr:
        STA NIBBUF,X                     ; zero $0D00..$0D55
        DEX
        BPL @clr
        ; Y = $00: walk all 256 user bytes (the first DEY wraps Y to $FF)
        TAY
        ; X = secondary-buffer column base ($0C56+$AC = NIBBUF+2)
        LDX #$AC
@skip:
        .byte   $2C                      ; cover (BIT-abs opcode): the FIRST pass falls
                                         ; through from LDX #$AC and the BIT swallows the
                                         ; next 2 bytes, skipping the LDX #$AA so X stays $AC
PRENIB_RELOAD:
        LDX #$AA                         ; real mid-byte entry (reached by BNE PRENIB_RELOAD):
                                         ; reset the secondary-column base for each later group
@loop:
        ; pre-shift one user byte into the primary + secondary buffers
        DEY
        ; fetch the user data byte
        LDA (PTRL),Y                     ; user buffer byte
        LSR
        ROL NIBBUF-$AA,X                 ; -> 6+2 secondary buffer
        LSR
        ROL NIBBUF-$AA,X                 ; (base $0C56, X>=$AC: $0D02+)
        ; store the upper 6 bits to the primary buffer (SECBUF2)
        STA SECBUF2,Y
        INX
        ; advance the secondary column; X wrapping to $00 ends this group
        BNE @loop
        TYA
        ; more user bytes? re-enter at PRENIB_RELOAD to reset the column base
        BNE PRENIB_RELOAD
        RTS

; ----------------------------------------------------------------------
; WRITESECT -- 6-and-2 encode the pre-nibbled sector and clock it onto the diskette
;   In:        X = slot*16 (the drive's Disk II $C0n0 base index); NIBBUF (86 secondary
;              bytes) and SECBUF2 (256 primary bytes) already filled by PRENIBBLE
;   Out:       data field written as D5 AA AD <secondary stream + primary stream +
;              checksum> DE AA EB FF, controller left in read mode; on write-protect,
;              aborts to WR_DONE2 with no write
;   Clobbers:  A, X, Y; SECTCNT ($27) and $0678 (two copies of slot*16), $26 (running
;              EOR-chain checksum seed); leaves the controller in read mode on exit
;   Algorithm: sense write-protect (Q6H then Q7L; bit7 set = protected) and abort if
;              set. Else switch to write mode (Q7H), emit the self-sync gap and the
;              D5 AA AD data prologue, then write the 86-byte secondary stream and the
;              256-byte primary stream, each byte EOR-chained with the previous (the
;              running checksum) and mapped through WRTRANS to a legal disk nibble.
;              Write the final checksum nibble, the DE AA EB epilogue + an FF sync,
;              then drop the latch back to read mode. WR_NIB/WR_NIB1/WR_NIB2 hold the
;              inter-nibble spacing. [RE]
; ----------------------------------------------------------------------
WRITESECT:
        SEC
        STX SECTCNT
        ; keep a second copy of slot*16 (X is reloaded with translated nibbles in the inner loops)
        STX $0678                        ; save slot index *16
        LDA $C08D,X                      ; Q6L (sense write-protect)
        ; sense write-protect via Q7L (after the Q6H above); bit7 set = protected
        LDA $C08E,X                      ; Q7L
        ; write-protected -> abort without writing
        BMI WR_DONE2                     ; write protected -> abort
        LDA NIBBUF
        STA $26
        LDA #$FF
        ; Q7H: switch the controller into write mode
        STA $C08F,X                      ; Q7H (write mode)
        ORA $C08C,X                      ; Q6L
        PHA
        PLA
        NOP
        ; emit 4 self-sync $FF gap nibbles ahead of the data field
        LDY #$04
@gap:
        PHA
        PLA
        JSR WR_NIB1
        DEY
        BNE @gap
        ; write the D5 AA AD data-field prologue
        LDA #$D5                         ; data prologue D5 AA AD
        JSR WR_NIB
        LDA #$AA
        JSR WR_NIB
        LDA #$AD
        JSR WR_NIB
        TYA
        ; phase 1: write the 86-byte secondary stream (NIBBUF), EOR-chained
        LDY #$56
        BNE @sec2
@sec2lp:
        ; EOR-chain successive secondary bytes (NIBBUF), then translate via WRTRANS
        LDA NIBBUF,Y
@sec2:
        EOR NIBBUF-1,Y
        TAX
        LDA WRTRANS,X                    ; 6+2 write translate
        LDX SECTCNT
        STA $C08D,X
        LDA $C08C,X
        DEY
        BNE @sec2lp
        ; phase 2: re-seed the running checksum, then write the 256 primary bytes
        LDA $26
        NOP
@mainlp:
        ; EOR-chain each primary byte (SECBUF2), translate, and clock it out
        EOR SECBUF2,Y
        TAX
        LDA WRTRANS,X
        LDX $0678
        STA $C08D,X
        LDA $C08C,X
        LDA SECBUF2,Y
        INY
        BNE @mainlp
        TAX
        ; translate and write the final running-checksum nibble
        LDA WRTRANS,X
        LDX SECTCNT
        JSR WR_NIB2
        ; write the DE AA EB data-field epilogue + a trailing FF sync
        LDA #$DE                         ; data epilogue DE AA EB
        JSR WR_NIB
        LDA #$AA
        JSR WR_NIB
        LDA #$EB
        JSR WR_NIB
        LDA #$FF
        JSR WR_NIB
        ; Q7L: drop the controller back to read mode
        LDA $C08E,X                      ; Q7L (read mode)
; ----------------------------------------------------------------------
; WR_DONE2 -- common write exit: settle the controller into read mode and return
;   In:        X = slot*16 (Disk II base index); reached by fall-through after a
;              completed write, or by branch from the write-protect check
;   Out:       controller left in read mode; A = the Q6L read
;   Clobbers:  A
;   Algorithm: read Q6L ($C08C,X) to settle the data register into read mode, then
;              return to the RWTS dispatcher (which records completion status). [RE]
; ----------------------------------------------------------------------
WR_DONE2:
        ; Q6L: leave the controller in read mode, then return
        LDA $C08C,X                      ; Q6L
        RTS
        NOP
; ----------------------------------------------------------------------
; WR_NIB -- write one disk nibble with the longest inter-nibble spacing (slowest entry)
;   In:        A = nibble to write; X = slot*16 (Disk II base index)
;   Out:       A = the Q6L read; the nibble has been clocked onto the diskette
;   Clobbers:  A, carry (CLC); stack used transiently by PHA/PLA in WR_NIB1
;   Algorithm: clear carry (a 2-cycle pad), then fall into WR_NIB1. Used between bytes
;              that need the widest gap (the prologue/epilogue marks) so successive
;              latch writes stay spaced to the disk bit-cell cadence. [RE]
; ----------------------------------------------------------------------
WR_NIB:
        ; longest-spacing entry: a 2-cycle pad, then fall into WR_NIB1
        CLC
; ----------------------------------------------------------------------
; WR_NIB1 -- write one disk nibble with medium inter-nibble spacing
;   In:        A = nibble to write; X = slot*16
;   Out:       A = the Q6L read; the nibble has been clocked onto the diskette
;   Clobbers:  A; stack used transiently by PHA/PLA
;   Algorithm: a PHA/PLA pair adds a fixed delay, then fall into WR_NIB2. Used for the
;              self-sync gap nibbles -- one step faster than WR_NIB (no CLC pad). [RE]
; ----------------------------------------------------------------------
WR_NIB1:
        ; medium-spacing entry: PHA/PLA pad delay, then fall into WR_NIB2
        PHA
        PLA
; ----------------------------------------------------------------------
; WR_NIB2 -- bare latch write, no pre-delay (fastest entry; the shared write tail)
;   In:        A = nibble to write; X = slot*16; controller already in write mode (Q7H)
;   Out:       A = the Q6L read; the nibble has been clocked onto the diskette
;   Clobbers:  A
;   Algorithm: STA Q6H ($C08D,X) loads the byte into the write latch; the following
;              access of Q6L ($C08C,X) strobes it out (the standard Apple write-nibble
;              idiom). All three WR_NIB* entries converge here; callers pick WR_NIB /
;              WR_NIB1 / WR_NIB2 to hold the per-nibble cadence when surrounding code
;              has already consumed part of the gap. [RE]
; ----------------------------------------------------------------------
WR_NIB2:
        ; Q6H: load the nibble into the write latch
        STA $C08D,X                      ; Q6H (load latch)
        ; Q6L: strobe the latched byte out onto the diskette
        ORA $C08C,X                      ; Q6L (shift out)
        RTS

        .res    66, $FF                  ; fill

; ----------------------------------------------------------------------
; READSECT -- find the 6-and-2 data field and denibblize one sector into the buffers
;   In:        X = slot*16 (Disk II soft-switch base $C08x,X; the controller is already in
;              read mode and the head settled on the target track by the RWTS caller). NIBBUF
;              ($0D00) and SECBUF2 ($0900) are the destination half-buffers. The combined
;              read/write nibble table at WRTRANS ($0D56) doubles as the disk-nibble->6-bit
;              read-translate in its tail: indexing NIBBUF ($0D00),Y with a raw disk nibble
;              Y in $96..$FF lands at $0D96..$0DFF, the read-translate entries.
;   Out:       Carry CLEAR on success (branches to RDADDR_OK at $0BC4) with 86 secondary
;              nibbles in NIBBUF[$00..$55] and 256 primary bytes in SECBUF2[$00..$FF], data
;              checksum and DE AA epilogue verified. Carry SET on any failure (falls through
;              to RD_FAIL).
;   Clobbers:  A, Y, ZP $26 (running buffer-index save), NIBBUF, SECBUF2. X is preserved as
;              the slot index throughout (only read via $C08x,X, never written).
;   Algorithm: Spin the data latch hunting the D5 AA AD data prologue, decrementing a $20-entry
;              retry budget and re-syncing on each mismatch. Then read 86 secondary (2-bit)
;              nibbles into NIBBUF top-down and 256 primary (6-bit) nibbles into SECBUF2,
;              maintaining a running checksum in A: each raw disk byte is fetched into Y and
;              EOR'd through the read-translate tail of WRTRANS (EOR NIBBUF,Y) into the prior
;              value, then stored decoded. After the data bytes, verify the trailing on-disk
;              checksum nibble equals the accumulated value, then verify the DE AA data
;              epilogue. POSTNIBBLE later recombines the two half-buffers into the user buffer. [AI]
; ----------------------------------------------------------------------
READSECT:
        ; retry budget: up to $20 attempts to catch the D5 AA AD data prologue before giving up
        LDY #$20                         ; retry budget
RD_RETRY:
        DEY
        BEQ RD_FAIL
RD_D5:
        ; spin on the data latch (Q6L) until a full nibble has shifted in (high bit set)
        LDA $C08C,X
        BPL RD_D5
RD_CHK1:
        ; match the first data-prologue mark D5; any miss re-arms the retry loop
        EOR #$D5
        BNE RD_RETRY
        NOP
RD_AA:
        LDA $C08C,X
        BPL RD_AA
        ; match the second data-prologue mark AA (re-sync to the D5 hunt on a miss)
        CMP #$AA
        BNE RD_CHK1
        LDY #$56
RD_AD:
        LDA $C08C,X
        BPL RD_AD
        ; match the third data-prologue mark AD: D5 AA AD complete, the data field follows
        CMP #$AD
        BNE RD_CHK1
        NOP
        NOP
        LDA #$00
RD_SEC2:
        ; read the 86 secondary (low 2-bit) nibbles into NIBBUF[$55..$00], counting down
        DEY
        STY $26
RD_SEC2B:
        ; fetch the next raw disk nibble into Y as the index into the read-translate tail of WRTRANS
        LDY $C08C,X
        BPL RD_SEC2B
        ; translate-and-accumulate: XOR running value with read-translate[nibble] (NIBBUF base, Y in
        ; $96..$FF)
        EOR NIBBUF,Y                     ; via read-translate table
        LDY $26
        ; store the decoded secondary nibble into NIBBUF[buffer index in $26]
        STA NIBBUF,Y
        BNE RD_SEC2
RD_MAIN:
        STY $26
RD_MAINB:
        ; main loop: read the 256 primary (6-bit) nibbles, decoding into SECBUF2[$00..$FF]
        LDY $C08C,X
        BPL RD_MAINB
        EOR NIBBUF,Y
        LDY $26
        ; store the decoded primary byte into SECBUF2[buffer index in $26]
        STA SECBUF2,Y
        INY
        BNE RD_MAIN
RD_CKSUM:
        LDY $C08C,X
        BPL RD_CKSUM
        ; checksum: the final accumulated value must equal the translated disk checksum nibble, else
        ;           fail
        CMP NIBBUF,Y                     ; checksum check
        BNE RD_FAIL
RD_DE:
        LDA $C08C,X                      ; data epilogue DE AA
        BPL RD_DE
        ; verify the first data-epilogue mark DE
        CMP #$DE
        BNE RD_FAIL
        NOP
RD_DE2:
        LDA $C08C,X
        BPL RD_DE2
        ; verify the second data-epilogue mark AA; on match branch to RDADDR_OK (carry clear =
        ; success)
        CMP #$AA
        BEQ RDADDR_OK
RD_FAIL:
        ; shared read-error exit (also reached from READADDR): carry set signals a read failure to
        ; RWTS
        SEC                              ; carry set = error
        RTS

; ----------------------------------------------------------------------
; READADDR -- find and verify the next address field on the current track
;   In:        X = slot*16 (indexes the Disk II data latch $C08C,X); the head
;              is positioned over the target track and the disk is spinning in
;              read mode (set up by the RWTS_RW caller).
;   Out:       carry CLEAR (falls into RDADDR_OK) on a good address field, with
;              the four decoded fields stored at $2C..$2F = cksum/sector/track/
;              volume; carry SET (via the shared RD_FAIL exit, $0B68) on search
;              timeout or any prologue / checksum / epilogue mismatch.
;   Clobbers:  A, Y; scratch ZP cells $26 (search-timeout high byte, then the
;              rotated odd-nibble holder) and $27 (running odd/even checksum);
;              result cells $2C..$2F.
;   Algorithm: Spin reading raw nibbles, hunting the D5 AA 96 address prologue
;              under a 16-bit search budget (Y counts up from $FC, $26 its high
;              byte; budget exhausted -> RD_FAIL). Then read four 4-and-4
;              ('odd/even') encoded fields -- volume, track, sector, checksum --
;              each as two nibbles: the odd nibble is shifted left (ROL) to
;              supply the high bits and ANDed with the even nibble to rebuild
;              the byte, stored descending into $2F,$2E,$2D,$2C. A running XOR
;              checksum in $27 must come out zero. Finally verify the DE AA
;              address-field epilogue.
; ----------------------------------------------------------------------
READADDR:
        ; seed the prologue-search budget: Y counts up from $FC via INY and $26 holds its high byte,
        ; giving a bounded 16-bit scan for the D5 AA 96 mark
        LDY #$FC
        STY $26
RA_NEXT:
        INY
        BNE RA_D5
        INC $26
        BEQ RD_FAIL                      ; timeout -> error
RA_D5:
        ; spin reading raw nibbles from the data latch until one arrives (high bit set)
        LDA $C08C,X                      ; address prologue D5 AA 96
        BPL RA_D5
RA_CHK:
        ; match the first address-prologue nibble D5; on mismatch loop back via RA_NEXT and keep
        ; hunting
        CMP #$D5
        BNE RA_NEXT
        NOP
RA_AA:
        LDA $C08C,X
        BPL RA_AA
        ; match the second prologue nibble AA
        CMP #$AA
        BNE RA_CHK
        ; four address fields to decode (volume, track, sector, checksum): index Y runs 3 down to 0
        LDY #$03                         ; 4 odd/even fields to read
RA_96:
        LDA $C08C,X
        BPL RA_96
        ; match the address-prologue's third nibble 96 (data fields use AD instead)
        CMP #$96
        BNE RA_CHK
        LDA #$00
RA_FIELD:
        ; reset / re-store the running odd/even checksum accumulator before each field
        STA $27
RA_ODD:
        LDA $C08C,X
        BPL RA_ODD
        ; decode one 4-and-4 field: shift the odd nibble left so its bits land in the high (even)
        ; positions
        ROL
        STA $26
RA_EVEN:
        LDA $C08C,X
        BPL RA_EVEN
        ; AND the shifted odd nibble with the even nibble to reconstruct the original data byte
        AND $26                          ; odd/even -> byte
        ; store the rebuilt field descending into the IOB quartet: Y=3->$2F volume, 2->$2E track,
        ; 1->$2D sector, 0->$2C checksum
        STA $002C,Y                      ; store vol/trk/sec/cksum
        ; fold the byte into the running XOR checksum (held back into $27 by the next RA_FIELD pass)
        EOR $27
        DEY
        BPL RA_FIELD
        ; after the last field the folded checksum in A must be zero; nonzero -> RD_FAIL
        TAY
        BNE RD_FAIL                      ; checksum nonzero -> error
RA_DE:
        LDA $C08C,X                      ; address epilogue DE AA
        BPL RA_DE
        ; verify the address-field epilogue first nibble DE
        CMP #$DE
        BNE RD_FAIL
        NOP
RA_DE2:
        LDA $C08C,X
        BPL RA_DE2
        ; verify the address-field epilogue second nibble AA, then fall into the shared RDADDR_OK
        ; success exit
        CMP #$AA
        BNE RD_FAIL
; ----------------------------------------------------------------------
; RDADDR_OK -- shared success exit for the address- and data-field readers
;   In:        reached only after a field passed every prologue / checksum /
;              epilogue check.
;   Out:       carry CLEAR signalling success; returns to the RWTS search loop.
;   Clobbers:  carry only.
;   Algorithm: Clear carry and return. Tail-shared by READADDR (good address
;              field, fall-through) and by READSECT's data-epilogue check
;              (C3 RD_DE2 BEQ RDADDR_OK), so a single CLC+RTS serves both.
; ----------------------------------------------------------------------
RDADDR_OK:
        CLC                              ; carry clear = success
        RTS

; ----------------------------------------------------------------------
; POSTNIBBLE -- recombine the 6-and-2 buffers into the 256-byte user buffer
;   In:        SECBUF2 holds the 256 high-6-bit values just read; NIBBUF holds
;              the 86 packed low-2-bit groups; (PTRL) points at the caller's
;              user buffer; X/Y free.
;   Out:       256 fully reconstructed data bytes written through (PTRL),Y.
;   Clobbers:  A, X, Y; NIBBUF is consumed (shifted out by the LSR pair).
;   Algorithm: For each of the 256 output bytes, take the high-6-bit value from
;              SECBUF2,Y and graft on two low bits drawn from the matching
;              NIBBUF entry: inner index X cycles $55..$00 (each of the 86
;              NIBBUF bytes serves three output bytes), and each visit LSRs two
;              low bits out of NIBBUF,X and rolls them into the bottom of the
;              value before storing it via (PTRL),Y.
; ----------------------------------------------------------------------
POSTNIBBLE:
        ; Y walks all 256 output positions
        LDY #$00
@col:
        ; (re)load the inner NIBBUF index to 86; each NIBBUF byte feeds three output bytes
        LDX #$56
@row:
        DEX
        ; X underflowed past 0 -> reload the 86-entry NIBBUF index and continue with the NEXT output
        ; byte (Y has already advanced)
        BMI @col
        ; fetch the high 6 bits for this output byte
        LDA SECBUF2,Y
        ; shift the low-bit pair out of the packed nibble buffer, low bit first...
        LSR NIBBUF,X
        ; ...rolling each bit into the bottom of the value
        ROL
        LSR NIBBUF,X
        ROL
        ; store the reconstructed byte into the user buffer
        STA (PTRL),Y
        INY
        ; loop until Y wraps through all 256 bytes
        BNE @row
        RTS

; ----------------------------------------------------------------------
; SEEK -- step the Disk II arm from the current track to a target track
;   In:        A  = target track in half-track units (one phase step = one
;                    half-track; see SEEK_TRACK's ASL/LSR track<->half-track [RE])
;              X  = slot index (slot*16); forms the $C080,X phase base
;              $0478 = current track for this drive (half-track units)
;   Out:       arm positioned at the target track; $0478 updated to A
;   Clobbers:  A, X (restored to slot via LDX $2B in the phase core), Y,
;              $2A (target), $2B (slot), $26 (step counter), $27 (prior track),
;              $46/$47 (SEEK_DELAY settle counter)
;   Algorithm: Classic DOS-3.3 stepper seek. Each iteration moves the arm one
;              half-track toward the target by energizing the next stepper phase
;              ON (carry set), waiting PHTAB_ON[Y] settle ticks, then turning the
;              previous phase OFF (carry clear) and waiting PHTAB_OFF[Y]. The
;              settle index Y = min(steps-taken, steps-remaining) clamped 0..11,
;              so total settle is long at the seek ends (accelerate away, decelerate
;              in) and short while cruising -- this prevents overshoot. Returns when
;              current == target (BEQ SEEK_RET early-out / BEQ SEEK_DONE).
; ----------------------------------------------------------------------
SEEK:
        STX $2B                          ; slot index
        STA $2A                          ; target track (half-track*2)
        ; already on the target track? then nothing to do (BEQ SEEK_RET)
        CMP $0478                        ; current track
        BEQ SEEK_RET                     ; already there
        LDA #$00
        ; $26 = steps taken so far (the acceleration ramp counter), start at 0
        STA $26                          ; step count
SEEK_LOOP:
        LDA $0478
        ; remember the track we are stepping AWAY from (the phase to release later)
        STA $27                          ; prior track
        SEC
        ; distance = current - target; carry/sign picks step direction
        SBC $2A
        BEQ SEEK_DONE
        BCS @out
        EOR #$FF                         ; outward...
        ; target is inward (higher track #): step the arm one half-track up
        INC $0478
        BCC @cmp
@out:
        ADC #$FE                         ; ...vs inward
        ; target is outward (lower track #): step the arm one half-track down
        DEC $0478
@cmp:
        ; settle index Y = min(steps-remaining, steps-taken): accelerate early, decelerate near the
        ; target
        CMP $26
        BCC @lim
        LDA $26
@lim:
        ; clamp the settle-table index to 0..11 (12-entry tables); >=12 keeps the prior Y
        CMP #$0C
        BCS @clamp
        TAY
@clamp:
        ; carry SET selects the phase-ON sub-switch (energize the new phase)
        SEC
        ; energize the phase for the half-track we just stepped to (attract the arm)
        JSR PHASE_FROM_CURTRK
        LDA PHTAB_ON,Y                   ; phase-on settle delay
        JSR SEEK_DELAY
        LDA $27
        ; carry CLEAR selects the phase-OFF sub-switch (release the old phase)
        CLC
        ; de-energize the phase for the prior track ($27); the arm now coasts on
        JSR PHASE_SWITCH
        LDA PHTAB_OFF,Y                  ; phase-off settle delay
        JSR SEEK_DELAY
        ; one more step taken; loop until current reaches target
        INC $26
        BNE SEEK_LOOP
; ----------------------------------------------------------------------
; SEEK_DONE -- arm has reached the target track; final settle, then release the phase
;   In:        $0478 == $2A (target reached); $2B = slot index
;   Out:       falls through to PHASE_FROM_CURTRK with carry CLEAR to de-energize
;              the phase holding the current (final) track
;   Clobbers:  A, X, $46/$47
;   Algorithm: One last SEEK_DELAY so the head fully stops, then CLC and fall into
;              PHASE_FROM_CURTRK (carry clear = phase-OFF sub-switch) to drop the
;              holding phase. Reached by BEQ SEEK_DONE from the loop top.
; ----------------------------------------------------------------------
SEEK_DONE:
        ; final settle so the arm fully stops before the holding phase is released
        JSR SEEK_DELAY
        ; carry CLEAR -> the fall-through to PHASE_FROM_CURTRK hits the OFF sub-switch
        CLC
; ----------------------------------------------------------------------
; PHASE_FROM_CURTRK -- derive the stepper phase from the CURRENT track, then switch it
;   In:        $0478 = current track (half-track units); $2B = slot index;
;              CARRY selects the sub-switch: set = phase ON, clear = phase OFF
;   Out:       the selected $C080,X stepper soft switch has been touched;
;              X restored to the slot index
;   Clobbers:  A, X
;   Algorithm: Upper entry of the shared phase-switch core: load $0478 as the phase
;              source and fall into PHASE_SWITCH. NOTE the historical name PHASE_FROM_CURTRK
;              is misleading -- this entry does NOT always turn a phase off; the
;              CALLER's carry flag decides (SEEK enters with carry SET at $0C0F to
;              energize ON; SEEK_DONE falls in with carry CLEAR to release OFF).
; ----------------------------------------------------------------------
PHASE_FROM_CURTRK:
        ; phase source = current track; PHASE_SWITCH masks it to a phase 0..3
        LDA $0478                        ; derive phase from track
; ----------------------------------------------------------------------
; PHASE_SWITCH -- compute and touch a Disk II stepper-phase soft switch
;   In:        A = track whose low 2 bits select the phase (0..3); $2B = slot
;              index (slot*16); CARRY = the on/off sub-switch select
;   Out:       $C080 + slot + phase*2 + carry has been read (toggles the stepper
;              phase on or off); X = slot index on return
;   Clobbers:  A, X
;   Algorithm: phase = A AND 3; ROL folds CARRY into bit0 so A = phase*2 + (carry);
;              OR in the slot index to form the X offset, then touch $C080,X. For
;              slot 6 this lands in $C0E0..$C0E7 = PHASE0_OFF..PHASE3_ON [DOC apple2.json].
;              Shared by the phase-ON (carry set) and phase-OFF (carry clear) callers;
;              SEEK enters here directly (A = prior track $27, carry clear) to release
;              the old phase, bypassing the current-track load.
; ----------------------------------------------------------------------
PHASE_SWITCH:
        ; phase number 0..3 = track mod 4
        AND #$03
        ; phase*2 with CARRY shifted into bit0 = the on(1)/off(0) sub-switch select
        ROL
        ; OR in the slot index so $C080,X lands on this drive's controller
        ORA $2B                          ; | slot index
        TAX
        ; touch PHASEn off/on (slot 6 -> $C0E0..$C0E7); $C080 base kept literal = Disk II HW, NOT
        ; the language card at the same addr
        LDA $C080,X                      ; PHASEn off/on soft switch
        ; restore X = slot index for the caller
        LDX $2B
; ----------------------------------------------------------------------
; SEEK_RET -- shared RTS for SEEK's early-out and the phase-switch core
;   In:        none
;   Out:       returns to caller
;   Algorithm: Single RTS reached by SEEK's BEQ SEEK_RET (already on track) and by
;              the fall-through tail of PHASE_SWITCH.
; ----------------------------------------------------------------------
SEEK_RET:
        RTS

; ----------------------------------------------------------------------
; SEEK_DELAY -- busy-wait settle delay between stepper-phase transitions (DOS-3.3 MSWAIT)
;   In:        A = outer settle-tick count (from PHTAB_ON / PHTAB_OFF)
;   Out:       A = 0 on return; $46/$47 advanced as a 16-bit elapsed counter
;              that SATURATES (high byte pinned at $FF instead of wrapping)
;   Clobbers:  A, X, $46/$47, flags
;   Algorithm: Nested countdown: a 17-iteration inner X loop is one settle unit, then
;              a 16-bit INC of $46/$47 ticks an elapsed accumulator (a DEC $47 guard
;              undoes a high-byte wrap so it saturates at $FF), then A is decremented;
;              repeat until A reaches 0. Calibrated so each unit ~= the phase settle time.
; ----------------------------------------------------------------------
SEEK_DELAY:
        ; 17-iteration inner busy loop = one settle time unit
        LDX #$11
@inner:
        DEX
        BNE @inner
        ; advance the 16-bit elapsed accumulator ($46 low, $47 high)
        INC $46
        BNE @next
        INC $47
        BNE @next
        ; guard: undo the high-byte bump so $47 saturates at $FF instead of wrapping to 0
        DEC $47
@next:
        SEC
        ; one settle unit done; repeat A times then return
        SBC #$01
        BNE SEEK_DELAY
        RTS

; ----------------------------------------------------------------------
; PHTAB_ON -- stepper phase-ON settle-delay table (DATA), 12 entries, index 0..11
;   Layout:    one SEEK_DELAY tick count per ramp index Y = min(steps-taken,
;              steps-remaining), clamped 0..11. SEEK loads PHTAB_ON[Y] AFTER
;              energizing the new phase.
;   Values:    $01,$30,$28,$24,$20,$1E,$1D,$1C,$1C,$1C,$1C,$1C [OBSERVED]. Index 0
;              ($01) is the FIRST step; the larger early values then decay to a
;              steady $1C for the cruising mid-seek steps -- the phase-ON half of
;              the accel/decel profile, paired with PHTAB_OFF [RE].
;   Note:      pure data; referenced only as PHTAB_ON,Y (relocatable). PHTAB_ON2
;              labels this table's 7th byte (PHTAB_ON+6).
; ----------------------------------------------------------------------
PHTAB_ON:
        .byte   $01, $30, $28, $24, $20, $1E
; ----------------------------------------------------------------------
; PHTAB_ON2 -- mid-table marker: the steady-state tail of the phase-ON table
;   Layout:    $1D,$1C,$1C,$1C,$1C,$1C [OBSERVED] -- NOT a separate table; this is
;              PHTAB_ON+6, ramp indices 6..11 of the phase-ON settle table.
;   TEMPORAL OVERLAP [RE, verified]: this label's address $0C56 is ALSO used, as a
;              raw literal base, by PRENIBBLE's 'ROL $0C56,X' ($0A14 and $0A18).
;              There X >= $AC so $0C56,X reaches $0D02..$0D55 = the NIBBUF 6+2
;              secondary nibble buffer -- a base-minus-offset addressing trick into
;              NIBBUF, NOT a reference to this settle table. The two uses never
;              collide in time: the settle bytes are read during a SEEK; the ROL
;              writes happen during PRENIBBLE sector encoding. That PRENIBBLE literal
;              is intentionally left as $0C56 (it lives outside C5); do NOT relabel it.
; ----------------------------------------------------------------------
PHTAB_ON2:
        .byte   $1D, $1C, $1C, $1C, $1C, $1C
; ----------------------------------------------------------------------
; PHTAB_OFF -- stepper phase-OFF settle-delay table (DATA), 12 entries, index 0..11
;   Layout:    one SEEK_DELAY tick count per ramp index Y (same Y as PHTAB_ON).
;              SEEK loads PHTAB_OFF[Y] AFTER releasing the old phase.
;   Values:    $70,$2C,$26,$22,$1F,$1E,$1D,$1C,$1C,$1C,$1C,$1C [OBSERVED]. Index 0
;              ($70) is the long settle on the FIRST step; values decay to a steady
;              $1C while cruising -- the phase-OFF half of the accel/decel profile,
;              paired with PHTAB_ON [RE].
;   Note:      pure data; referenced only as PHTAB_OFF,Y (relocatable).
; ----------------------------------------------------------------------
PHTAB_OFF:
        .byte   $70, $2C, $26, $22, $1F, $1E
        .byte   $1D, $1C, $1C, $1C, $1C, $1C

        .res    151, $FF                 ; fill ($CFF read-translate -1)
        .byte   $FF
; ----------------------------------------------------------------------
; NIBBUF -- primary 86-byte 6-and-2 nibble scratch buffer; ALSO the index base for the reverse
; (read) translate window (two non-overlapping temporal tenants)
;   In:        Data label at $0D00 ($56 bytes). On disk it is $FF fill; it carries meaning only once
;              the running 6502 RWTS uses it.
;              As BUFFER:  indices X/Y = $00..$55 (the 86 two-bit groups of a 256-byte sector).
;              As READ-XLATE BASE: index Y = a raw disk nibble $96..$FF read from the Disk II data
;              latch ($C08C,X).
;   Out:       As BUFFER:  the packed low-2-bit halves of the sector (PRENIBBLE fills/clears it;
;              POSTNIBBLE consumes it).
;              As READ-XLATE BASE: NIBBUF,Y for Y in $96..$FF resolves to $0D96..$0DFF (the tail of
;              WRTRANS), giving disk nibble -> 6-bit value.
;   Clobbers:  n/a (data region).
;   Algorithm: [RE] Two NON-overlapping temporal tenants share this $0D00 base. (1) RUNTIME BUFFER:
;              PRENIBBLE clears
;              NIBBUF[$00..$55] ($0A04); WRITESECT reads it via LDA NIBBUF,Y / EOR NIBBUF-1,Y;
;              READSECT stores into it
;              ($0B34) and checks the checksum cell ($0B50); POSTNIBBLE shifts it out ($0BD0/$0BD4).
;              Only offsets $00..$55
;              are valid buffer cells. (2) READ-TRANSLATE INDEX BASE: a freshly read disk nibble
;              (always >= $96, high bit
;              set) goes into Y and is used as EOR/STA/CMP NIBBUF,Y; because Y >= $96, NIBBUF,Y
;              addresses $0D96.. = the
;              upper third of WRTRANS, whose bytes there are the INVERSE map (disk nibble -> 6-bit
;              value). The two uses
;              never collide: buffer cells are $0D00..$0D55, valid disk nibbles index $0D96..$0DFF.
;              OBSERVED: the whole
;              region is $FF on disk; it gains meaning only after the running RWTS writes the buffer
;              cells and the WRTRANS
;              data backs the reverse-translate window.
; ----------------------------------------------------------------------
NIBBUF:
        ; The 86 ($56) primary-buffer cells $0D00..$0D55 (one per 2-bit group of a 256-byte sector).
        ; $FF on disk; cleared/filled by the running RWTS (PRENIBBLE/READSECT) and never read as the
        ; on-disk $FF.
        .res    86, $FF                  ; primary 6+2 nibble buffer

; ----------------------------------------------------------------------
; WRTRANS -- 6-and-2 GCR nibble translate table; used in BOTH directions (disk write and disk read)
;   In:        WRITE direction: LDA WRTRANS,X with X = a 6-bit code 0..63 (a packed 6+2 group).
;              READ direction:  reached as NIBBUF($0D00)+Y for Y = a disk nibble $96..$FF (i.e.
;              WRTRANS+$40..).
;   Out:       WRITE: A = the legal disk nibble ($96..$FF) for that 6-bit code.
;              READ:  A (after EOR) = the recovered 6-bit code 0..63 for that disk nibble.
;   Clobbers:  n/a (data region).
;   Algorithm: [RE] A single 170-byte data table ($0D56..$0DFF) encoding the standard Apple 6-and-2
;              GCR mapping in both
;              directions over the same bytes. FORWARD (write): WRTRANS[code] = disk nibble; entries
;              $0D56.. are
;              $96,$97,$9A,$9B,... so code 0->$96, 1->$97, ...; WRITESECT does LDA WRTRANS,X then
;              ships A out the latch
;              ($0A68/$0A7D/$0A90). The 64 forward entries ($0D56..$0D95) are all >= $96 (the legal
;              GCR nibble set).
;              REVERSE (read): the tail of the SAME table, entered as NIBBUF,Y for a disk-nibble Y
;              in $96..$FF (landing at
;              $0D96..$0DFF = WRTRANS+$40..), holds the inverse map: disk nibble -> 6-bit value
;              (e.g. the byte at $0D96 is
;              $00, so nibble $96 decodes to value 0). READSECT uses EOR NIBBUF,Y for this. VERIFIED
;              self-consistent:
;              WRTRANS[0]=$96 and NIBBUF[$96]=$00. OBSERVED genuine data (the canonical 6&2 table)
;              -- NOT code, keep as
;              .byte. No in-image address operands here, so nothing to relocate; the routines that
;              index it (WRITESECT,
;              READSECT) already use the WRTRANS / NIBBUF labels.
; ----------------------------------------------------------------------
WRTRANS:
        ; Forward map start ($0D56): WRTRANS[6-bit code] -> legal disk nibble. Code 0 -> $96, 1 ->
        ; $97, 2 -> $9A, ... The 64 forward entries ($0D56..$0D95) are all >= $96 (the standard 6&2
        ; GCR nibble set).
        .byte   $96, $97, $9A, $9B, $9D, $9E, $9F, $A6
        .byte   $A7, $AB, $AC, $AD, $AE, $AF, $B2, $B3
        .byte   $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC
        .byte   $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3
        .byte   $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE
        .byte   $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC
        .byte   $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6
        .byte   $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF
        ; $0D96 = WRTRANS+$40, reached as NIBBUF($0D00),Y for disk nibble Y in $96..$FF: the INVERSE
        ; (read) map, disk nibble -> 6-bit value. The leading $00 means nibble $96 decodes to value
        ; 0; entries for non-legal nibbles are don't-cares the read path never indexes.
        .byte   $00, $01, $98, $99, $02, $03, $9C, $04
        .byte   $05, $06, $A0, $A1, $A2, $A3, $A4, $A5
        .byte   $07, $08, $A8, $A9, $AA, $09, $0A, $0B
        .byte   $0C, $0D, $B0, $B1, $0E, $0F, $10, $11
        .byte   $12, $13, $B8, $14, $15, $16, $17, $18
        .byte   $19, $1A, $C0, $C1, $C2, $C3, $C4, $C5
        .byte   $C6, $C7, $C8, $C9, $CA, $1B, $CC, $1C
        .byte   $1D, $1E, $D0, $D1, $D2, $1F, $D4, $D5
        .byte   $20, $21, $D8, $22, $23, $24, $25, $26
        .byte   $27, $28, $E0, $E1, $E2, $E3, $E4, $29
        .byte   $2A, $2B, $E8, $2C, $2D, $2E, $2F, $30
        .byte   $31, $32, $F0, $F1, $33, $34, $35, $36
        .byte   $37, $38, $F8, $39, $3A, $3B, $3C, $3D
        .byte   $3E, $3F

; ============================================================================
;  RWTS dispatch / controller front end  ($0E00..$0FFC)
; ============================================================================

; ----------------------------------------------------------------------
; RWTS_ENTRY -- published RWTS read entry vector ($0E00)
;   In:        (none -- a fixed jump vector)
;   Out:       transfers control to RWTS_TOP, which reads the CP/M
;              system image off track 0 into memory
;   Clobbers:  (none here; RWTS_TOP / RWTS_RW do the work)
;   Algorithm: A fixed 3-byte JMP at the very top of the RWTS dispatch
;              page so callers (and BOOT0's stage-2) have a stable entry
;              address regardless of how the routines below are laid out.
; ----------------------------------------------------------------------
RWTS_ENTRY:
        JMP RWTS_TOP                     ; top-level read entry

; ----------------------------------------------------------------------
; RWTS_DOIO -- IRQ-safe Language-Card-bank wrapper around one RWTS op ($0E03)
;   In:        the RWTS-IOB caller cells ($03E0-$03EB) already filled in by
;              the caller (track/sector/drive/slot/buffer/command)
;              [DOC CPM_SoftCard_RWTS_IOB ; facts sec.RWTS-IOB]
;   Out:       RWTS_RW's result; carry + the IOB status cell $03EA
;              (DSK_STATUS: 0=OK / error code) reflect the outcome
;   Clobbers:  A, X, Y, processor status; Disk II latch + LC bank state
;   Algorithm: Selects read/write Language-Card RAM bank 2 (the bank the
;              RWTS code and its sector buffers live in), saves the
;              caller's IRQ-enable state and masks interrupts so the
;              cycle-counted GCR read/write is not preempted, runs one
;              operation via RWTS_RW, then re-selects read-ROM and
;              restores the prior interrupt state. (Motor-off is NOT done
;              here -- it happens in RWTS_RW's exit path at $0F45.)
; ----------------------------------------------------------------------
RWTS_DOIO:
        ; enter the RWTS execution context: select read/write Language-Card RAM bank 2 (where the
        ; RWTS code + nibble buffers reside)
        LDA $C083                        ; read/write LC bank (RWTS ctx)
        ; save the caller's interrupt-enable state across the operation
        PHP
        ; mask interrupts: the GCR read/write loops are cycle-counted bit-banging and must not be
        ; preempted
        SEI
        JSR RWTS_RW
        ; leave the RWTS context: re-select read-ROM with bank-2 write still enabled ($C081 =
        ; LC_ROM_BANK2_WR) before returning
        LDA $C081                        ; restore ROM bank
        PLP
        RTS

; ----------------------------------------------------------------------
; RWTS_RW -- select drive, coast/spin-up, seek to track, then read/write one sector ($0E10)
;   In:        RWTS-IOB cells [DOC CPM_SoftCard_RWTS_IOB]:
;                $03E6 DSK_SLOT  = requested controller slot << 4,
;                $03E4 DSK_DRIVE = requested drive (1 or 2),
;                $03E0 DSK_TRACK = requested track,
;                $03E1 DSK_SECTOR= requested logical sector,
;                $03E8/$03E9 DSK_BUFFER = DMA buffer pointer,
;                $03EB DSK_COMMAND = 1 read / else write.
;              $03E5 / $03E7 = the driver's current-DRIVE / current-SLOT
;              latches (last drive/controller it selected).
;   Out:       sector transferred to/from the buffer; carry + $03EA
;              DSK_STATUS hold the result. $03E5/$03E7 updated to the now-
;              current drive/slot.
;   Clobbers:  A, X (slot*16), Y; ZP $35/$46/$47; tables $04F8/$05F8/$06F8;
;              Disk II motor/drive/phase soft switches.
;   Algorithm: (1) Arm the whole-op ($06F8=2) and per-sector ($04F8=4)
;              retry budgets. (2) If the requested controller slot differs
;              from the last one, let the previously-spinning spindle coast
;              to a stop (so two controllers are never driven at once)
;              before switching. (3) Select the requested slot, turn its
;              motor on, and wait for the spindle to reach speed. (4)
;              Latch the DMA buffer pointer and preset the 16-bit settle
;              counter; if the requested DRIVE differs from the current
;              one, flag (via the pushed Z) that an initial head-settle is
;              needed after the switch. (5) Select drive 1 vs 2 from
;              $03E4's low bit, fold the half-track parity into $35, run
;              the initial settle delay only on a drive change, then map
;              the requested TRACK ($03E0) through SEEK_TRACK (which seeks
;              the arm) and fall into the sector search/transfer of
;              cluster C8. RW_* labels below are this routine's internal
;              control-flow anchors.
; ----------------------------------------------------------------------
RWTS_RW:
        LDY #$02
        ; arm the whole-operation retry budget (2 recalibrate-and-retry passes)
        STY $06F8                        ; retry count (whole-op)
        LDY #$04
        ; arm the per-sector retry budget (4 tries); this drive-0 slot of the $04F8,Y track table is
        ; reused as the retry counter [RE]
        STY $04F8                        ; retry count (per-sector)
        ; fetch the requested controller slot (DSK_SLOT = slot<<4) into X as the soft-switch base
        ; index
        LDA $03E6                        ; requested slot*16
        TAX
        ; same controller slot as the last operation? if so skip the coast-down and go straight to
        ; spin-up
        CMP $03E7                        ; same drive as last?
        BEQ RW_SAMEDRV
        TXA
        TAY
        ; a different controller: load the previously-selected slot<<4 so its spindle can be coasted
        ; down first
        LDA $03E7                        ; prior slot*16
        TAX
        TYA
        PHA
        ; record the requested slot as the new current-slot latch
        STA $03E7
        ; put the prior controller into read mode (Q7L) so its read latch can be sampled to detect
        ; spindle motion
        LDA $C08E,X                      ; Q7L on prior drive
RW_WAIT1:
        ; coast-down: require 8 consecutive identical latch reads before declaring the old spindle
        ; stopped
        LDY #$08
        LDA $C08C,X
RW_WAIT2:
        ; re-sample the read data latch (Q6L); if it still changes the spindle is turning, so
        ; restart the 8-count
        CMP $C08C,X                      ; wait for spindle to coast
        BNE RW_WAIT1
        DEY
        BNE RW_WAIT2
        ; old spindle has coasted to a stop: restore the requested slot<<4 into X
        PLA
        TAX
RW_SAMEDRV:
        ; select read mode (Q7L) on the requested controller, then read Q6L to begin sampling for
        ; spin-up
        LDA $C08E,X                      ; Q7L (read mode)
        LDA $C08C,X                      ; Q6L
        LDY #$08
RW_SPIN:
        LDA $C08C,X
        PHA
        PLA
        PHA
        PLA
        ; latch the active slot<<4 ($05F8) -- the current-drive index used throughout the rest of
        ; the operation
        STX $05F8                        ; current slot*16
        ; the read latch changed -> the spindle is already up to speed, so stop waiting
        CMP $C08C,X                      ; spinning yet?
        BNE RW_GO
        DEY
        BNE RW_SPIN
RW_GO:
        PHP
        ; turn the selected controller's drive motor on (indexed Disk II MOTOR-ON soft switch; slot
        ; 6 -> $C0E9)
        LDA $C089,X                      ; motor on
        ; latch the caller's DMA buffer pointer (DSK_BUFFER low then high) into the RWTS buffer
        ; pointer PTRL/PTRH
        LDA $03E8                        ; buffer pointer low
        STA PTRL
        LDA $03E9                        ; buffer pointer high
        STA PTRH
        ; preset the 16-bit seek-settle countdown ($46/$47 = $D8EF), counted up to $0000 by the
        ; RW_SETTLE loop
        LDA #$EF                         ; seek settle counter
        STA $46
        LDA #$D8
        STA $47
        ; compare the requested DRIVE (DSK_DRIVE) against the driver's current-drive latch to detect
        ; a drive change
        LDA $03E4                        ; target track
        CMP $03E5                        ; current track
        BEQ RW_NOSEEK
        ; drive changed: record it as the new current-drive latch and flag (Y=0 / PHP) that an
        ; initial head-settle is needed
        STA $03E5
        PLP
        LDY #$00
        PHP
RW_NOSEEK:
        ROR
        BCC @rd1
        ; select drive 1 vs drive 2 ($C08A/$C08B,X) from the low bit of DSK_DRIVE rotated out into
        ; carry
        LDA $C08A,X                      ; select drive 1/2
        BCS @rd2
@rd1:
        LDA $C08B,X
@rd2:
        ; fold the drive-select / half-track-parity bit into $35 (the parity flag SEEK_TRACK/RECAL
        ; test)
        ROR $35
        PLP
        PHP
        BNE RW_AFTERSEEK
        ; drive changed: run an initial 7-pass settle delay to let the newly-selected head land
        ; before searching
        LDY #$07                         ; initial settle delay
@dly:
        JSR SEEK_DELAY
        DEY
        BNE @dly
        LDX $05F8
RW_AFTERSEEK:
        ; take the requested TRACK (DSK_TRACK) and feed it to SEEK_TRACK, which half-tracks it and
        ; seeks the arm there
        LDA $03E0                        ; requested sector
        JSR SEEK_TRACK                   ; physical interleave
        ; load the command (DSK_COMMAND); a read (1) of an already-settled track skips the extra
        ; settle, else fall into RW_SETTLE
        LDA $03EB
        PLP
        BNE RW_FINDSEC
        CMP #$01
        BEQ RW_FINDSEC
RW_SETTLE:
        ; extra post-seek settle: spin a short inner delay, then count the $46/$47 16-bit counter up
        ; to zero before the sector search
        LDY #$12                         ; extra seek settle
RW_SETTLE2:
        DEY
        BNE RW_SETTLE2
        INC $46
        BNE RW_SETTLE
        INC $47
        BNE RW_SETTLE
; ----------------------------------------------------------------------
; RW_FINDSEC -- arrived on the located track; for a WRITE pre-encode the user buffer, then start the
; sector search
;   In:        A = command byte (bit0: 1=read, 0=write) loaded from $03EB by the front end; arm
;              settled on the target track; $05F8 = current slot*16
;   Out:       falls into RW_REARM with the read/write decision pushed (PHP) for RW_SECOK to consume
;   Clobbers:  A, processor status (saved/restored via the stack); on the write path the secondary
;              nibble buffer (via PRENIBBLE)
;   Algorithm: ROR shifts the command's bit0 into carry and PHP saves it as the read/write flag.
;              Carry set (read) skips
;              straight to the search; carry clear (write) first calls PRENIBBLE to 6-and-2
;              pre-encode the caller's buffer
;              so WRITESECT can stream it out. [RE] command-byte bit0 semantics inferred from the
;              $03EB front-end writes.
; ----------------------------------------------------------------------
RW_FINDSEC:
        ; shift the command's bit0 into carry (1 = read, 0 = write); PHP saves it for the
        ; post-search read/write dispatch
        ROR
        PHP
        ; read request: nothing to encode, go straight to the sector search
        BCS RW_REARM
        ; write request: 6-and-2 pre-encode the caller's buffer into the secondary nibble buffer for
        ; WRITESECT
        JSR PRENIBBLE
; ----------------------------------------------------------------------
; RW_REARM -- (re)arm the per-track sector-search budget
;   In:        none
;   Out:       $0578 = $30 (48) address-field reads allowed before recalibrating this pass
;   Clobbers:  Y, $0578
;   Algorithm: Reset the sector-search countdown. Entered from RW_FINDSEC and re-entered (JMP
;              RW_REARM) from RW_RESEEK
;              after a recalibrate, so each fresh seek gets a full search budget.
; ----------------------------------------------------------------------
RW_REARM:
        ; allow up to $30 address-field reads to find the wanted sector before recalibrating
        LDY #$30                         ; sector-search budget
        STY $0578
; ----------------------------------------------------------------------
; RW_SEARCH -- read the next address field off the spinning track
;   In:        $05F8 = current slot*16; $0578 = remaining search budget
;   Out:       on success (carry clear from READADDR) the decoded volume/track/sector/checksum are
;              in $2F/$2E/$2D/$2C and
;              control falls to RW_GOTADDR; on failure (carry set) falls to RW_RETRY
;   Clobbers:  X, A, Y, $2C-$2F, $26/$27 (READADDR scratch)
;   Algorithm: Reload the slot index and call READADDR to scan for and decode one D5 AA 96 address
;              field; the carry flag
;              reports success/failure for the caller to branch on.
; ----------------------------------------------------------------------
RW_SEARCH:
        LDX $05F8
        ; scan the track for the next address field (D5 AA 96 ...) and decode
        ; volume/track/sector/checksum into $2F/$2E/$2D/$2C
        JSR READADDR                     ; read address field
        ; got a valid address field -> check whether it is the track/sector we want
        BCC RW_GOTADDR
; ----------------------------------------------------------------------
; RW_RETRY -- charge one search attempt; loop until the per-track budget is spent
;   In:        $0578 = remaining search budget
;   Out:       branches back to RW_SEARCH while budget remains; falls into RW_RECAL when exhausted
;   Clobbers:  $0578
;   Algorithm: Decrement the search countdown; while it stays non-negative keep scanning the same
;              track. This is the common
;              landing spot for every miss (bad address field, wrong volume, wrong sector, or a read
;              CRC error).
; ----------------------------------------------------------------------
RW_RETRY:
        ; one search attempt consumed
        DEC $0578
        ; budget left: keep scanning this track for the wanted sector
        BPL RW_SEARCH
; ----------------------------------------------------------------------
; RW_RECAL -- the track is unreadable; recalibrate the arm and re-seek (bounded by the whole-op
; budget)
;   In:        $0478,(drive) = believed current track; $06F8 = whole-op recal budget; $35 =
;              half-track parity
;   Out:       on budget exhaustion -> RW_HARDFAIL (error $40); otherwise reseeds the per-sector
;              retry count and falls into
;              RW_RESEEK to re-arm and search again
;   Clobbers:  A, X, Y, the stack (one saved track byte), $04F8, the per-drive track cells
;              $0478/$04F8 (via RECAL/SEEK_TRACK)
;   Algorithm: Save the current track, then RECAL with A=$60 -- this seeds a high phantom
;              current-track value so the next seek
;              steps the head all the way back toward track 0 (a recalibrate). Decrement the
;              whole-op budget and bail to
;              RW_HARDFAIL at zero; else reset the per-sector retry count to 4, re-run the sector
;              translation, and re-seek. [RE]
; ----------------------------------------------------------------------
RW_RECAL:
        ; remember the track we believe we are on so we can return to it after recalibrating
        LDA $0478                        ; recalibrate on repeated miss
        PHA
        LDA #$60
        ; A=$60 seeds a high phantom current-track so the next seek steps the head hard toward track
        ; 0 (recalibrate)
        JSR RECAL
        ; spend one whole-operation recalibrate attempt
        DEC $06F8
        ; out of recal attempts: give up with a hard error
        BEQ RW_HARDFAIL
        LDA #$04
        ; reset the per-sector retry count to 4 for the upcoming re-seek
        STA $04F8
        LDA #$00
        ; re-run the logical->physical sector translation (its tail re-seeks)
        JSR SEEK_TRACK
        PLA
; ----------------------------------------------------------------------
; RW_RESEEK -- re-seek to the saved track, then re-arm the search
;   In:        A = saved track (PLA'd by the caller); $35 = half-track parity
;   Out:       JMP RW_REARM to restart the sector search on this track
;   Clobbers:  A, X, Y, the per-drive track cells $0478/$04F8, $2E (via SEEK_TRACK)
;   Algorithm: Translate the saved track through the current parity (SEEK_TRACK, whose tail issues
;              the physical seek), then
;              jump back to re-arm the per-track search budget. Entered from RW_RECAL and from
;              RW_GOTADDR's wrong-track path.
; ----------------------------------------------------------------------
RW_RESEEK:
        ; translate + physically seek to the saved track
        JSR SEEK_TRACK
        ; restart the sector search with a fresh budget
        JMP RW_REARM                     ; re-arm (LDY #$30 at @noseek2)
; ----------------------------------------------------------------------
; RW_GOTADDR -- an address field decoded cleanly; confirm it is on the track we want
;   In:        $2E = address-field track; $0478,(drive) = current/target track
;   Out:       on a track match -> RW_ONTRACK; on a mismatch, step toward the correct track and
;              re-seek (RW_RESEEK) or, when
;              the per-sector retries are spent, recalibrate (RW_RECAL)
;   Clobbers:  A, Y, X, the stack (one saved track byte), $04F8
;   Algorithm: Compare the track read from the disk header ($2E) against the wanted track. If equal,
;              proceed to the volume/
;              sector check. If not, the head drifted: RECAL from the actual track toward the wanted
;              one and, while per-sector
;              retries remain, re-seek; otherwise fall back to a full recalibrate.
; ----------------------------------------------------------------------
RW_GOTADDR:
        ; track number read from the address field (READADDR put volume/track/sector/cksum in
        ; $2F/$2E/$2D/$2C)
        LDY $2E
        ; are we positioned on the track we asked for?
        CPY $0478                        ; on the right track?
        BEQ RW_ONTRACK
        LDA $0478
        PHA
        TYA
        ; wrong track: step the head from where we actually are toward the wanted track
        JSR RECAL                        ; step to correct track
        PLA
        ; charge a per-sector retry; re-seek if any remain, else escalate to a full recalibrate
        DEC $04F8
        BNE RW_RESEEK
        BEQ RW_RECAL
; ----------------------------------------------------------------------
; RW_HARDFAIL -- unrecoverable: too many recalibrates without reaching the track
;   In:        stack holds one track byte pushed by the recal path
;   Out:       A = $40 (hard/seek error code); falls into RW_RETURN to store status and exit
;   Clobbers:  A, stack (one PLA balances the pushed track)
;   Algorithm: Discard the saved track from the stack and load error code $40, then join the common
;              error return path.
; ----------------------------------------------------------------------
RW_HARDFAIL:
        PLA
        ; error $40 = sector never found / arm could not reach the track
        LDA #$40                         ; error code
; ----------------------------------------------------------------------
; RW_RETURN -- common error return: discard the saved read/write flag and store the error status
;   In:        A = error code ($40 hard, $20 wrong volume) set by the caller; stack top = the
;              read/write flag from RW_FINDSEC
;   Out:       jumps into the status-store sequence at RW_STORESTATUS (A -> $03EA), motor off, RTS
;   Clobbers:  processor status (PLP balances the pushed read/write flag)
;   Algorithm: Pull the read/write flag RW_FINDSEC pushed (not needed on the error path) and JMP to
;              RW_STORESTATUS -- the
;              mid-byte entry past the BIT-zp cover -- so the error code in A is written to $03EA.
; ----------------------------------------------------------------------
RW_RETURN:
        ; drop the read/write flag RW_FINDSEC pushed; not needed on the error exit
        PLP
        JMP RW_STORESTATUS               ; -> $0F3E (skip into STA $03EA)
; ----------------------------------------------------------------------
; RW_UNUSED -- UNREACHABLE dead code (verified)
;   In:        n/a
;   Out:       n/a
;   Clobbers:  n/a
;   Algorithm: A lone `BEQ RW_OKEXIT` ($0F0E) whose only textual predecessor is the unconditional
;              JMP RW_STORESTATUS at $0F0B
;              (which never falls through) and to which no branch targets; the bytes are retained
;              for byte-identical
;              reassembly but are never executed. UNKNOWN whether this is a stale fragment or
;              deliberate padding.
; ----------------------------------------------------------------------
RW_UNUSED:
        BEQ RW_OKEXIT
; ----------------------------------------------------------------------
; RW_ONTRACK -- on the correct track; verify the disk VOLUME matches the request
;   In:        $2F = address-field VOLUME; $03E2 = wanted volume (0 = accept any)
;   Out:       stores the found volume at $03E3; on match (or wanted=0) -> RW_SECOK; on mismatch ->
;              RW_RETURN with error $20
;   Clobbers:  A
;   Algorithm: Record the volume read from the address header, then if a specific volume was
;              requested compare it; a mismatch
;              raises error $20 (wrong VOLUME). NOTE: $2F is the VOLUME field -- READADDR stores
;              volume/track/sector/checksum
;              into $2F/$2E/$2D/$2C (LDY #$03 down to 0) -- so the sector match happens later in
;              RW_SECOK against $2D.
; ----------------------------------------------------------------------
RW_ONTRACK:
        ; volume number from the address field (READADDR put volume in $2F, track $2E, sector $2D,
        ; cksum $2C)
        LDA $2F                          ; found sector #
        ; report the volume we actually found
        STA $03E3
        ; wanted volume; 0 means accept any volume
        LDA $03E2
        ; no specific volume requested -> skip the volume check
        BEQ RW_SECOK
        ; does the disk's volume match the requested one?
        CMP $2F                          ; is it the one we want?
        BEQ RW_SECOK
        ; error $20 = wrong VOLUME (NOT wrong sector)
        LDA #$20                         ; wrong sector
        BNE RW_RETURN
; ----------------------------------------------------------------------
; RW_SECOK -- right track and volume; confirm this is the wanted sector, then transfer the data
; field
;   In:        $03E1 = wanted logical sector; $2D = address-field physical sector; stack top =
;              read/write flag from
;              RW_FINDSEC (carry set = read)
;   Out:       on sector mismatch -> RW_RETRY (keep searching); on a write -> RW_WRITE; on a read,
;              READSECT then POSTNIBBLE
;              decode into the user buffer, then fall into RW_OKEXIT
;   Clobbers:  A, Y, processor status; the nibble buffers and user buffer on transfer
;   Algorithm: Map the wanted logical sector through SKEWTAB (interleave) to its physical sector and
;              compare with the
;              address-field sector $2D; on a match, restore the read/write flag and dispatch: carry
;              clear -> WRITESECT, else
;              READSECT the data field (retry on CRC error) and POSTNIBBLE-decode it into the
;              caller's buffer.
; ----------------------------------------------------------------------
RW_SECOK:
        ; logical sector the caller asked for
        LDA $03E1                        ; logical sector wanted
        TAY
        ; map logical -> physical sector via the interleave/skew table
        LDA SKEWTAB,Y                    ; interleave skew
        ; does the physical sector under the head ($2D) match the one we want?
        CMP $2D                          ; matches found sector?
        ; wrong sector: keep searching this track
        BNE RW_RETRY
        PLP
        ; restored read/write flag: carry clear -> write the data field
        BCC RW_WRITE                     ; carry clear -> write op
        ; read + checksum-verify the data field into the nibble buffers
        JSR READSECT                     ; read the data field
        PHP
        ; data-field read error: retry the search
        BCS RW_RETRY
        PLP
        ; 6-and-2 decode the nibble buffers into the caller's user buffer
        JSR POSTNIBBLE                   ; decode into user buffer
; ----------------------------------------------------------------------
; RW_OKEXIT -- success: set status = 0 and fall through the cover into the store/exit sequence
;   In:        none
;   Out:       A = $00 (OK), carry clear; falls through the BIT-zp cover into the status store and
;              motor-off exit
;   Clobbers:  A, carry
;   Algorithm: CLC + load status 0; the following unlabeled .byte $24 (BIT-zp cover) harmlessly
;              reads ZP $38 on this
;              fall-through path, so control reaches STA $03EA and stores OK.
; ----------------------------------------------------------------------
RW_OKEXIT:
        CLC
        ; completion status = 0 (success)
        LDA #$00                         ; status = ok
; ----------------------------------------------------------------------
; RW_STORESTATUS -- store the completion code and turn the drive motor off (shared store/exit tail)
;   In:        A = completion status (0 = OK, $10 write error, $20 wrong volume, $40 hard/seek
;              error); $05F8 = slot*16
;   Out:       $03EA = status; drive motor off; RTS to the RWTS caller
;   Clobbers:  X, A
;   Algorithm: Two entries share this tail. The OK path (RW_OKEXIT) falls through the unlabeled
;              .byte $24 BIT-zp cover (a no-op read of ZP $38). The error paths JMP/BNE to
;              RW_STORESTATUS, the cover's operand byte $38 decoding as SEC (carry is unused by
;              STA, so it is inert). Both then STA the status to $03EA, strobe $C088,X to drop the
;              motor, and RTS. The dead RW_EXIT label is removed by this cover split.
; ----------------------------------------------------------------------
        .byte $24                        ; cover (BIT-zp opcode $24): on the OK fall-through this harmlessly BITs ZP $38, skipping the SEC below
RW_STORESTATUS:
        SEC                              ; mid-byte entry ($38 = SEC) reached from the error paths (JMP/BNE RW_STORESTATUS); carry is inert here, falls into the status store
        STA $03EA                        ; store the completion status for the RWTS caller
        LDX $05F8                        ; reload slot*16 to address this drive's soft switches
        LDA $C088,X                      ; strobe the slot-6 drive MOTOR-OFF soft switch ($C088,X = DISKII_MOTOR_OFF) to spin the drive down
        RTS                              ; return to the RWTS caller (RWTS_RW)
; ----------------------------------------------------------------------
; RW_WRITE -- write the pre-encoded data field to the located sector
;   In:        the nibble buffers hold the 6-and-2 pre-encoded sector (from PRENIBBLE); positioned
;              at the wanted track/
;              sector; X/$05F8 = slot*16
;   Out:       on success (carry clear from WRITESECT) -> RW_OKEXIT (status 0); on
;              write-protect/failure -> store error $10
;              via RW_STORESTATUS
;   Clobbers:  A, X, Y, controller state
;   Algorithm: Call WRITESECT to stream the prologue, encoded data, checksum and epilogue onto the
;              track. Clear carry means
;              the write completed; set carry (e.g. write-protected) raises error $10.
; ----------------------------------------------------------------------
RW_WRITE:
        ; stream the pre-encoded data field (prologue, data, checksum, epilogue) onto the sector
        JSR WRITESECT
        ; write succeeded -> exit with status OK
        BCC RW_OKEXIT
        ; error $10 = write failed / disk write-protected
        LDA #$10                         ; write error code
        BNE RW_STORESTATUS               ; -> $0F3E (skip into STA $03EA)

; ----------------------------------------------------------------------
; SEEK_TRACK -- seek to the requested TRACK, in half-track stepper units.
;   In:        A = desired logical track (whole track #, from $03E0 = DSK_TRACK);
;              X = slot*16 (for DRIVE_IDX); $35 bit7 = drive parity (set by the
;              caller's RW_NOSEEK/RECAL path) selects which per-drive table is live.
;   Out:       arm positioned over the target track; the live current-track cell
;              $0478 left as a WHOLE-track value (halved back after the seek).
;   Clobbers:  A, Y, $2E, $0478, $0478,Y/$04F8,Y, plus SEEK's ($26/$27/$2A/$2B).
;   Algorithm: double the whole track to half-track stepper units (ASL) -- the
;              phase stepper in SEEK works in half-track increments -- run
;              SEEK_TRACK_BODY (swap in the live drive's saved track and seek),
;              then LSR the $0478 bookkeeping cell to restore the whole-track
;              value. NOTE: this is a TRACK seek, not a sector map -- the prior
;              name SEEK_TRACK was a mis-NAMING (the caller passes $03E0 = track;
;              $03E1 is the sector and never reaches here -- the logical->physical
;              sector skew is applied separately at SKEWTAB, see RW_SECOK).
; ----------------------------------------------------------------------
SEEK_TRACK:
        ; double the whole-track number into half-track stepper units (SEEK steps in half-track
        ; increments)
        ASL
        JSR SEEK_TRACK_BODY
        ; halve the live current-track cell back to a whole-track value after the seek
        LSR $0478
        RTS
; ----------------------------------------------------------------------
; SEEK_TRACK_BODY -- swap in the active drive's saved track, then seek to A.
;   In:        A = target track (already doubled to half-track units); X = slot*16
;              (consumed by DRIVE_IDX); $35 bit7 = drive parity (set by the caller).
;   Out:       tail-calls SEEK with $0478 = the chosen drive's prior track so SEEK
;              can step from there to A; the new target track is written back into
;              that drive's saved-track table for next time.
;   Clobbers:  A, Y, $2E, $0478, $0478,Y or $04F8,Y.
;   Algorithm: Y = slot index (DRIVE_IDX). $0478,Y and $04F8,Y are the two
;              per-slot saved-track tables (one per drive of the slot's pair).
;              Using the $35 parity bit, copy the live drive's saved track into
;              the single working cell $0478, then stash the new target track
;              (held in $2E) back into that same drive's table, and JMP SEEK.
; ----------------------------------------------------------------------
SEEK_TRACK_BODY:
        ; save the target track across the table juggling (A is reused below)
        STA $2E
        ; Y = slot index, used to address the two per-drive saved-track tables
        JSR DRIVE_IDX
        ; pick the saved track of the live drive: $0478,Y on one parity, $04F8,Y on the other ($35
        ; bit7)
        LDA $0478,Y
        BIT $35
        BMI @b1
        LDA $04F8,Y
@b1:
        ; make it the single working current-track cell that SEEK steps from
        STA $0478
        LDA $2E
        BIT $35
        BMI @b2
        ; write the new target back into this drive's saved-track table ($35 parity picks $0478,Y vs
        ; $04F8,Y)
        STA $04F8,Y
        BPL @b3
@b2:
        STA $0478,Y
@b3:
        ; step the arm from $0478 to the target track
        JMP SEEK

; ----------------------------------------------------------------------
; DRIVE_IDX -- convert a slot*16 controller index into a 0..15 table index.
;   In:        X = slot number << 4 (the $C08x form, e.g. $60 for slot 6).
;   Out:       Y = slot number (0..15), the index into the per-drive saved-track
;              tables $0478,Y / $04F8,Y.
;   Clobbers:  A, Y.
;   Algorithm: A = X >> 4 (four LSRs), then TAY. Pure index arithmetic.
; ----------------------------------------------------------------------
DRIVE_IDX:
        TXA
        ; shift slot*16 down by 4 bits -> bare slot number (0..15)
        LSR
        LSR
        LSR
        LSR
        ; Y = slot index for the per-drive saved-track tables
        TAY
        RTS

; ----------------------------------------------------------------------
; RECAL -- record a track as the live drive's current track in the saved-track table.
;   In:        A = track to record (whole-track units; doubled below). RW_GOTADDR
;              passes the actually-found track to correct the recorded position;
;              RW_RECAL passes a large value ($60) to force a deliberate recalibrate.
;              $03E4 = DSK_DRIVE (its low bit selects parity), X = slot*16.
;   Out:       the live drive's saved-track table entry ($0478,Y or $04F8,Y) set to
;              A*2; $35 bit7 = drive parity. Does NOT itself seek -- a later
;              SEEK_TRACK steps from the now-(re)recorded position; an over-large
;              recorded value makes that seek slam the head into the track-0 stop
;              = recalibrate.
;   Clobbers:  A, Y, $35, $0478,Y or $04F8,Y.
;   Algorithm: derive the drive parity from DSK_DRIVE's low bit (LDA $03E4 then
;              ROR A -> carry, then ROR $35 puts it in $35 bit7), get the slot
;              index (DRIVE_IDX), double the passed track (ASL), and store it into
;              the matching per-drive saved-track table.
; ----------------------------------------------------------------------
RECAL:
        PHA
        ; DSK_DRIVE: its low bit is the drive parity (which of the slot's two drives)
        LDA $03E4
        ROR
        ; rotate that drive-parity bit into $35 bit7 = the saved-track table selector
        ROR $35
        JSR DRIVE_IDX
        PLA
        ; double the passed track into half-track units to match the saved-track tables
        ASL
        BIT $35
        BMI @b1
        ; record this track as the live drive's current track (RW_RECAL's over-large value makes the
        ; next seek slam to the track-0 stop = recalibrate)
        STA $04F8,Y
        BPL @b2
@b1:
        STA $0478,Y
@b2:
        RTS

; ----------------------------------------------------------------------
; SKEWTAB -- logical-to-physical sector interleave (skew) table, 16 entries.
;   Layout:    indexed by logical sector 0..15 (from $03E1 = DSK_SECTOR, at RW_SECOK),
;              yields the physical sector to match against the disk's address header.
;   Values:    00 02 04 06 08 0A 0C 0E 01 03 05 07 09 0B 0D 0F -- the 2:1
;              (Apple Pascal / ProDOS) interleave SoftCard CP/M uses; NOT DOS 3.3's
;              descending skew [DOC CPM_SoftCard_RWTS_IOB.md sec 'Sector interleave'].
;   Genuine DATA: kept as .byte; not code, not an in-image address table.
; ----------------------------------------------------------------------
SKEWTAB:
        ; even physical sectors for logical 0-7 (2:1 Pascal/ProDOS interleave)
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E
        ; odd physical sectors for logical 8-15
        .byte   $01, $03, $05, $07, $09, $0B, $0D, $0F

; ----------------------------------------------------------------------
; RWTS_TOP -- read the CP/M system image off the boot disk into high RAM.
;   In:        none (constants set up here). STAGE2 self-patches the sector-count
;              operand at $0FCC (the LDA #imm at $0FCB) from $1C to $16 after the
;              first call (STA $0FCC at $1106).
;   Out:       the requested run of sectors copied into $A400.. (one 256-byte page
;              per sector); $03E9 restored to $08 on exit. Loops forever (re-
;              printing 'ERR' via PRERR) until every sector reads back clean.
;   Clobbers:  A, X, Y, the IOB cells $03E0/$03E1/$03E6/$03E8/$03E9/$03EB/$03E4,
;              and everything RWTS_RW/SEEK touch.
;   Algorithm: fill the RWTS parameter block -- track=0, drive=1, command=1(read),
;              slot 6, buffer=$A400, starting logical sector=11 -- with a sector
;              counter in A. For each sector: read it (RWTS_RW); on a miss print
;              ERR and restart the whole run; on success advance the buffer one
;              page and step the logical sector, wrapping at 16 to sector 0 +
;              next track, until the counter hits zero.
;   IOB note:  cells follow the boot loader's RWTS block ($03E0-$03EB): $03E0=track,
;              $03E1=sector, $03E4=drive, $03E6=slot*16, $03E8/9=buffer ptr,
;              $03EB=command (1=read) [DOC CPM_SoftCard_RWTS_IOB.md]. (The existing
;              inline 'sector'/'track' trailing notes on $03E0/$03E4 are swapped
;              -- see summary.) $A400 is an off-image low-RAM destination, literal.
; ----------------------------------------------------------------------
RWTS_TOP:
        ; set up the RWTS parameter block: DMA buffer = $A400 (high byte $A4)
        LDA #$A4                         ; buffer high = $A4
        STA $03E9
        LDY #$00
        STY $03E8                        ; buffer low = $00
        ; track = 0 (DSK_TRACK; the inline 'sector' note is wrong -- this is the track)
        STY $03E0                        ; sector = 0
        INY
        ; drive = 1 (DSK_DRIVE; the inline 'track' note is wrong -- this is the drive)
        STY $03E4                        ; track = 1
        ; command = 1 (read)
        STY $03EB
        LDA #$60
        STA $03E6                        ; slot 6 (=$60): the disk
                                         ;        controller for drives A:/B:
                                         ;        must be in slot 6 [DOC S&HD
                                         ;        1-3/1-4 ; facts sec.8.9]
        ; start at logical sector 11
        LDA #$0B
        STA $03E1                        ; starting logical sector
        ; sector count = 28 for the first call; STAGE2 self-patches this $0FCC operand to 22 ($16)
        ; for later calls
        LDA #$1C                         ; sectors-to-read count
; ----------------------------------------------------------------------
; RWTS_TOP_LP -- per-sector read loop inside RWTS_TOP.
;   In:        A = sectors remaining; IOB cells point at the next sector/buffer.
;   Out:       on success falls through to RWTS_TOP_OK; on error never returns here
;              (restarts the whole run).
;   Clobbers:  A (saved/restored across the read), P; plus RWTS_RW's.
;   Algorithm: save A and the processor status, mask interrupts (SEI), read one
;              sector (RWTS_RW); on success fall to RWTS_TOP_OK; on a read error
;              print ERR (PRERR), restore A/P, and JMP RWTS_TOP to restart the
;              entire load from the first sector.
; ----------------------------------------------------------------------
RWTS_TOP_LP:
        PHA
        PHP
        ; mask interrupts so the bit-banged nibble read is not disturbed
        SEI
        JSR RWTS_RW                      ; read one sector
        BCC RWTS_TOP_OK
        JSR PRERR                        ; read error -> "ERR" + bell, retry
        PLP
        PLA
        ; read failed -- restart the whole load from the first sector
        JMP RWTS_TOP
; ----------------------------------------------------------------------
; RWTS_TOP_OK -- post-read advance: bump buffer + sector, decrement the counter.
;   In:        A (pushed on the stack) = sectors remaining; the just-read sector
;              landed at the current buffer page.
;   Out:       buffer advanced one page; logical sector incremented (wrapping at 16
;              to sector 0 and track+1); loops back to RWTS_TOP_LP until the count
;              reaches zero, then resets the buffer high byte to $08 and returns.
;   Clobbers:  A, X, P, $03E9, $03E1, $03E0.
;   Algorithm: INC $03E9 (next page); INX the logical sector, on reaching 16 wrap
;              to 0 and INC the track; pull and decrement the counter, loop or end.
; ----------------------------------------------------------------------
RWTS_TOP_OK:
        PLP
        ; advance the DMA buffer pointer one 256-byte page
        INC $03E9                        ; next buffer page
        LDX $03E1                        ; next logical sector
        INX
        ; at logical sector 16? wrap to sector 0 on the next track
        CPX #$10
        BNE @same
        LDX #$00                         ; wrap to track+1, sector 0
        ; sector wrapped -> step the track number (DSK_TRACK)
        INC $03E0
@same:
        STX $03E1
        PLA
        SEC
        ; one fewer sector to read; loop until the counter hits zero
        SBC #$01
        BNE RWTS_TOP_LP
        ; restore the buffer high byte to $08 (default low-RAM DMA page) before returning
        LDA #$08
        STA $03E9
        RTS

        .byte   $FF, $FF                 ; fill
        .byte   $FF                      ; (overwritten at runtime)

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

; ----------------------------------------------------------------------
; STAGE2 -- CP/M cold-boot brain: reset console, verify boot slot, classify
;          the peripheral slots, locate the SoftCard, load CP/M, hand to Z-80.
;   In:    Entered by BOOT0 (JMP STAGE2 at $0822) once 11 sectors are loaded.
;          X = slot*16 of the boot controller; the RWTS primitives below it.
;   Out:   Does not return -- ends with JMP $03D2 (the $03C0 6502->Z-80 mode
;          switch), leaving the Z-80 running CP/M from the loaded system image.
;          On error prints a message and JMP MONZ (drops to the monitor).
;   Clobbers: A,X,Y,S; ZP $3C/$3D/$3E/$40/$41; the $02xx/$03xx config block;
;          the $FFFA-$FFFF CPU vectors; the STAGE2 RAM at $1000.
;   Algorithm:
;     1. Stop the boot drive, reset the Apple text screen + COUT/KEYIN hooks,
;        reset the stack, and confirm we booted from slot 6 (else error).
;     2. Copy the Z-80 slot-probe overlay over $1000 and copy the install image
;        ($1200-$13FF) down into the $0200-$03FF I/O config block.
;     3. Scan slots $C7..$C1: write each slot page (SCAN_PROBE) to find the
;        SoftCard (its probe clears $3E), and checksum/signature-classify every
;        other card into the Card Type Table at $02F8+slot.
;     4. Having found the SoftCard, copy the RWTS parameter cells, plant
;        JMP $AA00 at $1000 (the Z-80 BIOS entry), read the CP/M system into
;        memory (RWTS_TOP), patch the RWTS sector count, install the
;        $FFFA-$FFFF reset/NMI/IRQ vectors (all -> $03C0), then JMP $03D2 to
;        switch the machine to the Z-80.
; ----------------------------------------------------------------------
STAGE2:
        ; read ROM / language-card config back into the ROM bank for the monitor calls below
        LDA $C081                        ; read ROM / LC config
        LDA $C081
        JSR DRIVE_IDX
        PHA
        ; spin the boot drive's motor off -- the slot scan and CP/M load happen with the drive idle
        ; until RWTS_TOP
        STA $C088,X                      ; motor off
        LDA #$00
        ; zero this drive's current-track shadow cells so the next seek recalibrates from track 0
        STA $0478,Y                      ; zero current-track tables
        STA $04F8,Y
        ; put the Apple screen back to text mode + full-screen window and restore the standard
        ; COUT/KEYIN I/O hooks
        JSR TEXT                         ; text mode + full-screen window
        JSR SETVID                       ; CSW -> COUT1 (screen output)
        JSR SETKBD                       ; KSW -> KEYIN (keyboard input)
        PLA
        LDX #$FF
        ; reset the 6502 stack to $01FF before the long boot sequence
        TXS                              ; reset stack
        ; the loader requires the slot-6 disk controller as the A:/B: boot device; refuse any other
        ; slot
        CMP #$06                         ; booted from slot 6? -- the
                                         ;        slot-6 disk controller is the
                                         ;        required A:/B: boot device
                                         ;        [DOC Vol1 1-3/1-4 ; facts sec.8.9]
        BEQ S2_OK
        LDY #$00
; ----------------------------------------------------------------------
; S2_ERR1 -- wrong-slot error: print "MUST BOOT FROM SLOT SIX", then halt.
;   In:    Reached when the boot slot != 6.  Y = 0 on entry.
;   Out:   Falls into S2_ERR1_END (JMP MONZ); never returns to STAGE2.
;   Clobbers: A, Y.
;   Algorithm: COUT each high-bit char of MSG_SLOT6 until the $00 terminator,
;     then drop to the monitor.
; ----------------------------------------------------------------------
S2_ERR1:
        ; walk the CR-padded slot-6 error string a char at a time (in-image source -> label
        ; MSG_SLOT6)
        LDA MSG_SLOT6,Y                  ; "MUST BOOT FROM SLOT SIX"
        BEQ S2_ERR1_END
        ; emit the char to the screen via the standard output hook
        JSR COUT                         ; print error message char
        INY
        BNE S2_ERR1
; ----------------------------------------------------------------------
; S2_ERR1_END -- give up to the Apple monitor after the slot-6 error.
;   Algorithm: JMP MONZ (monitor cold entry: reset stack, print '*', GETLN).
; ----------------------------------------------------------------------
S2_ERR1_END:
        ; boot cannot continue -- hand control to the monitor cold-start prompt
        JMP MONZ                         ; drop to the monitor
; ----------------------------------------------------------------------
; S2_OK -- boot slot verified: install the Z-80 slot-probe overlay over $1000.
;   In:    Y is the byte counter (loaded #$0E here).
;   Out:   $1000..$100D hold the slot-probe handshake (13 Z-80 instruction bytes
;          plus the JR offset byte at $100D, which is SIG_BYTE5[0]=$F2).
;   Clobbers: A, Y.
;   Algorithm: copy SOFTCARD_PROBE_OVL[1..14] down to $0FFF+1..$0FFF+14, i.e.
;     $1000..$100D, overwriting STAGE2's own (now-finished) startup bytes with
;     the overlay the Z-80 will run during the slot scan.
; ----------------------------------------------------------------------
S2_OK:
        ; copy the 14 bytes at SOFTCARD_PROBE_OVL+1..+14 ($1169..$1176); offset 0 of the source is
        ; the MSG_SLOT6 $00 terminator (data)
        LDY #$0E                         ; install Z-80 SoftCard-probe overlay
; ----------------------------------------------------------------------
; S2_INSTOVL -- copy loop for the Z-80 slot-probe overlay.
;   In:    Y = source/dest offset (counts 14 down to 1).
;   Out:   $1000..$100D = the probe overlay; falls into S2_COPYCFG with Y=0.
;   Clobbers: A, Y.
;   Algorithm: LDA SOFTCARD_PROBE_OVL,Y / STA $0FFF,Y down to Y=1.
; ----------------------------------------------------------------------
S2_INSTOVL:
        ; SOURCE is in-image (label SOFTCARD_PROBE_OVL); DEST $0FFF,Y resolves to $1000.. -- the
        ; future Z-80 reset page (DEST kept literal)
        LDA SOFTCARD_PROBE_OVL,Y         ; copy +1..+14 -> $1000..$100D
        STA $0FFF,Y
        DEY
        BNE S2_INSTOVL
; ----------------------------------------------------------------------
; S2_COPYCFG -- copy the low page of the install image into the config block.
;   In:    Y = 0 on entry (the first iteration copies offset $00, then DEY wraps
;          it to $FF for the rest of the loop).
;   Out:   $0200..$02FF = INSTALL_IMG[$00..$FF] (the $1200 page, all 256 bytes).
;   Clobbers: A, Y.
;   Algorithm: standard byte-page copy $1200->$0200 (Y=$00 first, then $FF..$01
;     via DEY/BNE = all 256 bytes), staging the low half of the I/O
;     Configuration Block the Z-80 reads as 0F200H-0F2FFH after the CPU switch.
; ----------------------------------------------------------------------
S2_COPYCFG:
        ; SOURCE in-image (INSTALL_IMG = $1200); DEST $0200,Y is low RAM -- the config block, NOT
        ; part of this stored image (DEST kept literal)
        LDA INSTALL_IMG,Y                ; copy config image lo half
        STA $0200,Y                      ; $1200..$12FF -> $0200..$02FF
        DEY
        BNE S2_COPYCFG
        LDY #$F1
; ----------------------------------------------------------------------
; S2_COPYCFG2 -- copy the high page of the install image into the config block.
;   In:    Y = $F1 on entry.
;   Out:   $0300..$03F0 (via $02FF,Y) = INSTALL_IMG[$100..$1F0] (the $1300.. page).
;   Clobbers: A, Y.
;   Algorithm: LDA INSTALL_IMG+$FF,Y / STA $02FF,Y down to Y=1, copying
;     $1300..$13F0 to $0300..$03F0; the rest of the I/O Configuration Block
;     ($03xx tail + $03EF.. RWTS cells) is built/copied separately below.
; ----------------------------------------------------------------------
S2_COPYCFG2:
        ; SOURCE in-image (base INSTALL_IMG+$FF=$12FF, indexed by Y); DEST $02FF,Y is low RAM -- the
        ; config block's high page (DEST kept literal)
        LDA INSTALL_IMG+$FF,Y            ; copy config image hi half
        STA $02FF,Y                      ; $12FF..$13F0 -> $02FF..$03F0
        DEY
        BNE S2_COPYCFG2
        STY $03B8                        ; disk-count byte = 0 (Z-80
                                         ;        0F3B8H; = #controllers x2)
                                         ;        [DOC S&HD 2-27 ; facts sec.3.7]
        STY $3C                          ; scan pointer low = 0
        DEY
        STY $3E                          ; $3E = $FF: the SoftCard-found
                                         ;        flag (cleared to 0 by a slot's
                                         ;        probe handshake, INC'd to 1 once
                                         ;        found -- see $107F / $10C4)
        LDY #$C7                         ; scan slots $C7..$C1
; ----------------------------------------------------------------------
; S2_SLOTSCAN -- per-slot scan: probe for the SoftCard, else classify the card.
;   In:    Y = current slot's $Cn high byte (starts $C7, walks down to $C1);
;          $3E = $FF (SoftCard-not-yet-found flag); $03B8 = 0 (disk count).
;   Out:   For each slot, either marks the SoftCard (S2_SOFTCARD) or records a
;          card type at $02F8+slot; loops to S2_STORETYPE then back here.
;   Clobbers: A, X, Y, $3C/$3D/$3E/$40/$41.
;   Algorithm: SCAN_PROBE writes the slot page (the SoftCard probe). If $3E was
;     cleared, the SoftCard lives here -> S2_SOFTCARD. Otherwise twice-checksum
;     the slot ROM (SUM_ROM); a stable, ROM-present card goes to signature
;     classification (S2_DISKCTRL), an unstable/absent one is type 0 (S2_HASROM).
; ----------------------------------------------------------------------
S2_SLOTSCAN:
        ; write this slot's $Cn00 page -- on the SoftCard's slot the write toggles the CPU and the
        ; Z-80 probe overlay clears $3E
        JSR SCAN_PROBE                   ; WRITE $Cn00 to probe for SoftCard
        NOP
        ; $3E was cleared by the probe handshake iff this slot is the SoftCard
        LDA $3E                          ; the probe's handshake clears $3E
        BEQ S2_SOFTCARD                  ; $3E=0 -> SoftCard found in this slot
        ; checksum the slot's $Cn00 ROM page once
        JSR SUM_ROM                      ; checksum the card ROM
        STA $40
        STX $41
        ; checksum again -- a card whose ROM reads identically twice (X=0, sums match) is a real,
        ; stable ROM card
        JSR SUM_ROM                      ; checksum again, compare
        CPX #$00
        BEQ S2_HASROM
        CMP $40
        BNE S2_HASROM
        CPX $41
        ; stable ROM present -> go signature-match it against the known card-type table
        BEQ S2_DISKCTRL                  ; stable -> classify
        BNE S2_HASROM
; ----------------------------------------------------------------------
; S2_SOFTCARD -- record the SoftCard's slot in the Z$CPU location cell.
;   In:    Y = the SoftCard slot's $Cn high byte; reached when the probe cleared $3E.
;   Out:   $3E -> 1 (found); $03C7/$03C8 set; Z$CPU $03DE/$03DF = $En00 form
;          (low 0, high $En where N = SoftCard slot).  Card type stays 0 below.
;   Clobbers: A, $3E, $03C7, $03C8, $03DE, $03DF.
;   Algorithm: flag found, then store the SoftCard's Z-80 I/O page ($Cn + $20 =
;     $En) into Z$CPU (Apple $03DE/$03DF -> Z-80 0F3DEH) so later code can flip
;     the CPU by touching that page.  Falls into S2_HASROM (type 0).
; ----------------------------------------------------------------------
S2_SOFTCARD:
        ; $3E: $FF -> $00 was the probe's clear; INC makes it 1 = "SoftCard found, slot recorded"
        INC $3E                          ; mark SoftCard found at $Cn00
        STY $03C8
        LDA #$00
        STA $03C7
        ; Z$CPU low byte = 0 (DEST low RAM; becomes Z-80 0F3DEH after the config copy)
        STA $03DE                        ; Z$CPU low byte = 0 -- the
                                         ;        SoftCard-location cell at Z-80
                                         ;        0F3DEH: low byte 0, high byte
                                         ;        of form 0ENH (N = SoftCard slot)
                                         ;        [DOC S&HD 2-24/2-25 ; facts sec.4.3]
        TYA
        CLC
        ; convert the slot $Cn high byte to the Z-80 I/O page $En (a store to $En00 switches CPUs)
        ADC #$20                         ; form $En high byte ($Cn + $20)
        ; Z$CPU high byte = $En -- the SoftCard's CPU-switch page (DEST low RAM)
        STA $03DF                        ; Z$CPU high byte = $En
; ----------------------------------------------------------------------
; S2_HASROM -- classify this slot as type 0 (no recognized ROM / not a match).
;   In:    Reached for the SoftCard slot and for unstable/empty slots.
;   Out:   X = 0 (card type 0); branches to S2_STORETYPE to record it.
;   Clobbers: X.
;   Algorithm: set the card type to 0 and store it.
; ----------------------------------------------------------------------
S2_HASROM:
        ; card type 0 = none/unknown (the SoftCard itself records as 0 here; its slot is tracked via
        ; $3E/Z$CPU)
        LDX #$00                         ; card type = unknown/none
        BEQ S2_STORETYPE
; ----------------------------------------------------------------------
; S2_DISKCTRL -- begin signature classification of a ROM-bearing card.
;   In:    ($3C)/$3D point at the slot's $Cn00 ROM page.
;   Out:   X = 4, the starting index into the SIG_BYTE5/SIG_BYTE7 signature
;          tables; falls into the S2_SIGCMP compare loop.
;   Clobbers: X.
;   Algorithm: seed the signature-table walk; the loop tests ROM bytes $Cn05
;     and $Cn07 against the known card signatures to identify the card type.
; ----------------------------------------------------------------------
S2_DISKCTRL:
        ; start at signature-table index 4 and walk down, matching $Cn05/$Cn07 against known card
        ; types
        LDX #$04                         ; signature compare index
; ----------------------------------------------------------------------
; S2_SIGCMP -- compare a slot ROM's id bytes against one signature entry.
;   In:    X = signature index; ($3C),Y addresses the slot ROM page.
;   Out:   On full match falls to S2_SIGMATCH; else S2_SIGNEXT (try next index).
;   Clobbers: A, Y.
;   Algorithm: read ROM byte $Cn05 and compare SIG_BYTE5[X]; if equal, read
;     $Cn07 and compare SIG_BYTE7[X]; both equal => a recognized card.
; ----------------------------------------------------------------------
S2_SIGCMP:
        LDY #$05
        ; fetch ROM identification byte $Cn05 from the slot page
        LDA ($3C),Y                      ; ROM byte $Cn05
        ; compare against the SIG_BYTE5 signature (in-image table -> label)
        CMP SIG_BYTE5,X
        BNE S2_SIGNEXT
        LDY #$07
        ; byte $Cn05 matched -- now fetch ROM byte $Cn07
        LDA ($3C),Y                      ; ROM byte $Cn07
        ; and compare against SIG_BYTE7; a match here identifies the card type (index)
        CMP SIG_BYTE7,X
        BEQ S2_SIGMATCH
; ----------------------------------------------------------------------
; S2_SIGNEXT -- step to the next signature-table entry.
;   In:    X = current signature index.
;   Out:   If more entries remain, loops back to S2_SIGCMP; else (X=0) falls into
;          S2_SIGMATCH, where INX makes the unmatched-ROM type = 1.
;   Clobbers: X.
;   Algorithm: DEX; while nonzero retry the compare.
; ----------------------------------------------------------------------
S2_SIGNEXT:
        ; advance to the next-lower signature index and retry until the table is exhausted
        DEX
        BNE S2_SIGCMP
; ----------------------------------------------------------------------
; S2_SIGMATCH -- resolve the matched index to a card type; count disk controllers.
;   In:    X = matched signature index (1..4), or 0 if none of the 4 matched.
;   Out:   X = card-type value (X+1; an unmatched stable ROM becomes type 1); if
;          type 2 (Disk II controller) the disk-count byte $03B8 is bumped.
;          Falls into S2_STORETYPE.
;   Clobbers: X, $03B8.
;   Algorithm: INX turns the signature index into the Card Type Table value; if
;     it is 2 (Apple Disk II Controller) increment the controller count.
; ----------------------------------------------------------------------
S2_SIGMATCH:
        ; convert the signature index into the Card Type Table value (index + 1; unmatched X=0 ->
        ; type 1)
        INX
        ; type 2 = Apple Disk II controller card
        CPX #$02                         ; type 2 = Disk II controller?
                                         ;        (Card Type Table value 2 =
                                         ;        Apple Disk II Controller)
                                         ;        [DOC S&HD 2-26/2-27 ; facts sec.3.6]
        BNE S2_STORETYPE
        ; count this disk controller (DEST $03B8 = Z-80 disk-count cell 0F3B8H)
        INC $03B8                        ; bump disk-count byte (one per
; ----------------------------------------------------------------------
; S2_STORETYPE -- record this slot's card type and advance the slot scan.
;   In:    X = card-type value; $3D = the slot's $Cn high byte.
;   Out:   $02F8+slot = card type; loops back to S2_SLOTSCAN until slot $C0.
;   Clobbers: A, Y, $02F8,Y.
;   Algorithm: store the type at the Card Type Table offset $02F8+slot, then
;     walk the slot $Cn high byte down by one and rescan until past $C1 (=$C0).
; ----------------------------------------------------------------------
S2_STORETYPE:
        ; Y = the current slot's $Cn high byte (the table is indexed by slot)
        LDY $3D                          ; slot # ($Cn high byte)
        TXA
        ; Card Type Table entry (DEST $02F8+slot in low RAM -> runtime SLTTYP 0F3B9H, slot S at
        ; 0F3B8H+S)
        STA $02F8,Y                      ; Card Type Table entry, install
                                         ;        offset $02F8+slot -> runtime
                                         ;        SLTTYP 0F3B9H, slot S at
                                         ;        0F3B8H+S [DOC S&HD 2-26/2-27 ;
                                         ;        facts sec.3.6]
        DEY
        ; stop once we have scanned past slot 1 (Y reaches $C0)
        CPY #$C0                         ; done all 7 slots?
        BNE S2_SLOTSCAN
        ASL $03B8                        ; disk count *2: the Disk Count
                                         ;        Byte = #controllers x2 [DOC
                                         ;        S&HD 2-27 ; facts sec.3.7]
        LDA $3E
        CMP #$01                         ; SoftCard found?
        BEQ S2_GOTSOFTCARD
        STY $3D
        LDA #$85
        STA $3C
        STA $C085
        LDA $3E
        BEQ S2_GOTSOFTCARD
        LDY #$00
; ----------------------------------------------------------------------
; S2_ERR2 -- no-SoftCard error: print "CAN'T FIND Z80 SOFTCARD", then halt.
;   In:    Reached when the scan completes and $3E shows no SoftCard. Y=0.
;   Out:   Falls into S2_ERR2_END (JMP MONZ); never returns.
;   Clobbers: A, Y.
;   Algorithm: COUT MSG_NOCARD chars to the $00 terminator, then to the monitor.
; ----------------------------------------------------------------------
S2_ERR2:
        ; walk the CR-padded no-card error string (in-image source -> label MSG_NOCARD)
        LDA MSG_NOCARD,Y                 ; "CAN'T FIND Z80 SOFTCARD"
        BEQ S2_ERR2_END
        ; emit the char via the standard output hook
        JSR COUT                         ; print message char
        INY
        BNE S2_ERR2
; ----------------------------------------------------------------------
; S2_ERR2_END -- give up to the Apple monitor after the no-SoftCard error.
;   Algorithm: JMP MONZ (monitor cold entry).
; ----------------------------------------------------------------------
S2_ERR2_END:
        ; no SoftCard present -- boot cannot continue; hand control to the monitor
        JMP MONZ                         ; drop to the monitor
; ----------------------------------------------------------------------
; S2_GOTSOFTCARD -- SoftCard located: copy RWTS params, plant the Z-80 entry JMP.
;   In:    Reached once $3E == 1; the config block ($0200-$03FF) is built.
;   Out:   $03EF..$03FF = the RWTS parameter cells; $1000 = C3 00 AA (JMP $AA00).
;   Clobbers: A, Y, $03EF,Y, the STAGE2 RAM at $1000-$1002.
;   Algorithm: copy the RWTS_PARM block into the live RWTS cells, then plant the
;     bytes C3 00 AA at STAGE2..STAGE2+2 ($1000..$1002) so that, after the CPU
;     switch, the Z-80 jumps to $AA00 (the BIOS cold entry). Then falls into the
;     system load below.
;   Tenant note: $1000 is reused over the boot -- it held STAGE2's startup code
;     (run by the 6502), then the probe overlay (run by the Z-80), and now this
;     JMP $AA00 (run by the Z-80). The 6502 only WRITES the JMP here; it never
;     executes it.
; ----------------------------------------------------------------------
S2_GOTSOFTCARD:
        ; copy the 16-byte RWTS parameter block down into the live RWTS cells
        LDY #$10                         ; copy RWTS param block
; ----------------------------------------------------------------------
; S2_COPYPARM -- copy loop for the RWTS parameter block, then load CP/M + arm vectors.
;   In:    Y = 16 counting down to 1; reached from S2_GOTSOFTCARD.
;   Out:   $03EF..$03FF populated; CP/M system read into RAM; RWTS sector-count
;          patched; $FFFA-$FFFF CPU vectors installed (all -> $03C0).
;   Clobbers: A, Y, $03EF,Y, $0FCC, $FFF9,Y.
;   Algorithm: copy RWTS_PARM into $03EF.. ; RWTS_TOP reads the CP/M system
;     image off disk; patch the RWTS sector-count cell $0FCC to $16 for the
;     runtime read pattern; then fall into S2_VECCOPY to install the reset
;     vectors before the CPU switch.
; ----------------------------------------------------------------------
S2_COPYPARM:
        ; SOURCE in-image (label RWTS_PARM, $13EF..); DEST $03EF,Y is low RAM (the live RWTS
        ; parameter cells)
        LDA RWTS_PARM,Y                  ; $13EF..$13FF -> $03EF..$03FF
        STA $03EF,Y
        DEY
        BNE S2_COPYPARM
        ; $C3 is the Z-80 JMP opcode -- the 6502 plants the 3-byte Z-80 jump the SoftCard will run
        ; after the CPU switch
        LDA #$C3                         ; plant JMP at $1000 ...
        ; STAGE2 ($1000) = the Z-80 JMP opcode; in-image self-plant into the STAGE-2 RAM, executed
        ; later by the Z-80 (not the 6502)
        STA STAGE2
        LDA #$00
        ; STAGE2+1 = JMP target low byte $00 (in-image plant; the Z-80 runs the resulting JMP after
        ; the switch)
        STA $1001
        LDA #$AA                         ; ... = JMP $AA00 (BIOS, later)
        ; STAGE2+2 = JMP target high byte $AA -> the planted instruction is JMP $AA00 (Z-80 BIOS
        ; entry)
        STA $1002
        ; read the CP/M system image off track 0 into memory (the BIOS/BDOS/CCP the Z-80 will run)
        JSR RWTS_TOP                     ; read the CP/M system image
        LDA #$16                         ; patch sector count in RWTS
        ; self-patch the RWTS sector-count cell $0FCC (the LDA #$1C immediate operand at $0FCB) to
        ; $16 for subsequent reads
        STA $0FCC
        LDY #$06                         ; install 6502 reset vectors --
; ----------------------------------------------------------------------
; S2_VECCOPY -- install the 6502 RESET/NMI/IRQ vectors, then switch to the Z-80.
;   In:    Y = 6 counting down to 1; VEC_IMG holds 6 bytes ($C0 $03 x3).
;   Out:   $FFFA-$FFFF = $03C0 x3 (NMI, RESET, IRQ/BRK all -> the mode switch);
;          control transfers to JMP $03D2 (the 6502->Z-80 switch) -- no return.
;   Clobbers: A, Y, $FFF9,Y.
;   Algorithm: copy the 6-byte VEC_IMG into $FFFA..$FFFF so every 6502 hardware
;     vector points at the $03C0 mode-switch routine, then JMP $03D2 (mid-
;     routine, at the STA $C081) to hand the machine to the Z-80 running CP/M.
; ----------------------------------------------------------------------
S2_VECCOPY:
        ; Y-indexed read of VEC_IMG (base VEC_IMG-1, Y=1..6 -> $1125..$112A): in-image table source,
        ; NOT a frozen literal (VEC_IMG is a label)
        LDA VEC_IMG-1,Y                  ; reads $1125..$112A -> $FFFA..
        ; DEST $FFF9+Y = $FFFA..$FFFF, the 6502 NMI/RESET/IRQ-BRK vectors (all set to $03C0;
        ; off-image HW, kept literal)
        STA $FFF9,Y
        DEY
        BNE S2_VECCOPY
        ; enter the copied $03C0 mode-switch routine at $03D2 (the STA $C081 step; $03D2 is the run
        ; address of the $13C0 image, off-image) -> the SoftCard switches CPUs and the Z-80 takes
        ; over CP/M
        JMP $03D2                        ; enter mode-switch ($03C0 rtn
                                         ;        at STA $C081) -> hand to Z-80.
                                         ;        $03C0 = the 6502->Z-80 mode-
                                         ;        switch routine [DOC S&HD 2-25 ;
                                         ;        facts sec.2.4/4.4]

; ----------------------------------------------------------------------
; SUM_ROM -- 8-bit-wrapping additive checksum of a peripheral-card ROM page
;   In:        ($3C/$3D) -> the card's $Cn00 ROM page (the slot scan points it
;              at the slot being probed). A/X/Y entry values are not used.
;   Out:       A = low byte = sum (mod 256) of all 256 ROM bytes;
;              X = high byte = count of byte-adds that overflowed; Y = 0.
;              A present, stable ROM gives a repeatable A and non-zero X; a
;              floating-bus empty slot gives an unstable, often-zero result.
;   Clobbers:  A, X, Y, carry
;   Algorithm: zero A/X/Y, then for Y = 0..255 add ROM[($3C)+Y] into A,
;              bumping X once for each add that carried out. The caller runs it
;              twice and compares A (vs $40) and X (vs $41): equal + non-zero X
;              means a real, stable card ROM is present in the slot.
; ----------------------------------------------------------------------
SUM_ROM:
        ; clear the running sum (A = low byte, X = carry count) and the index Y
        LDA #$00
        TAX
        TAY
@lp:
        CLC
        ; add the next ROM byte at ($3C)+Y into the low sum
        ADC ($3C),Y
        BCC @nc
        ; the byte add carried out -> bump the high-byte carry count
        INX
@nc:
        INY
        ; continue until Y wraps past $FF (all 256 ROM bytes summed)
        BNE @lp
        RTS

; 6502 reset/NMI/IRQ vector image installed at $FFF9..$FFFF (point at $03C0):
; the three 6502 hardware vectors (NMI/RESET/IRQ-BRK) all target the $03C0
; 6502->Z-80 mode-switch routine [DOC S&HD 2-6, 2-25 ; facts sec.2.4/4.4].
VEC_IMG:
        .byte   $C0, $03, $C0, $03, $C0, $03

; MSG_NOCARD: "CAN'T FIND Z80 SOFTCARD" (CR-padded), $00-terminated.
MSG_NOCARD:
        .byte   $8D, $8D, $8D, $8D
        ASCHI   "CAN'T FIND Z80 SOFTCARD"
        .byte   $8D
        .byte   $8D, $8D, $00

; MSG_SLOT6: "MUST BOOT FROM SLOT SIX" (CR-padded), $00-terminated (at $1168).
MSG_SLOT6:
        .byte   $8D, $8D, $8D, $8D
        ASCHI   "MUST BOOT FROM SLOT SIX"
        .byte   $8D
        .byte   $8D, $8D

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
        .byte   $00                      ; MSG_SLOT6 terminator (data)
;   >>> CPM_BootLoader_ProbeOvl.asm -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>
;
; FOUND   EQU $F03E        ; the 6502's $3E "SoftCard found" flag (Z-80 view of $003E)
; PROBED  EQU $F03D        ; the probed slot's $Cn high byte, set by the 6502 ($003D)
;
;     ORG $1000
;
; ; ----------------------------------------------------------------------------
; ; PROBE_OVL -- slot-probe handshake. Installed over $1000..$100C; during the slot
; ;   scan a probe write lands the Z-80 here. Clear the $3E "SoftCard found" flag,
; ;   then touch the probed slot's Z-80 I/O page ($En00 = $Cn + $20) to switch back
; ;   to the 6502, and loop (the JR offset byte is the host's SIG_BYTE5[0]).
; ;   In: $3D = probed slot $Cn (set by the 6502).  Clobbers: A, HL.
; ; ----------------------------------------------------------------------------
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
        .incbin "CPM_BootLoader_ProbeOvl.bin" ; -$1175  (Z-80; JR offset = SIG_BYTE5[0])

; Card-signature compare tables (bytes $Cn05 / $Cn07 for known card types).
SIG_BYTE5:
        .byte   $F2, $03, $18, $38
SIG_BYTE7:
        .byte   $48, $3C, $38, $18, $48, $FF

; ----------------------------------------------------------------------
; SCAN_PROBE -- probe one slot for the Z-80 SoftCard by WRITING its $Cn00 page
;   In:        Y = the slot's $Cn page high byte (scanned $C7..$C1); A = scratch
;              written to $Cn00 (the value is irrelevant -- the access is the probe)
;   Out:       none directly; if the SoftCard lives in this slot the write hands
;              the bus to the Z-80, which runs SOFTCARD_PROBE_OVL at $1000 and
;              clears the 6502 $3E found-flag before bouncing back (the caller
;              then reads $3E == 0). Ordinary ROM cards / empty slots ignore it.
;   Clobbers:  $3D (= $Cn), the self-modified high operand byte SCAN_PROBE_HI,
;              and (on a SoftCard slot) whatever the Z-80 handshake touches
;   Algorithm: stash the probed slot high byte in $3D, self-patch this routine's
;              own STA operand high byte (SCAN_PROBE_HI) to $Cn, then store to
;              $Cn00. The SoftCard has NO on-board ROM, so any write to its slot
;              control page toggles the bus to the Z-80; on every other slot the
;              write is harmless. The side effect (the found-flag clear) is what
;              distinguishes the SoftCard from inert cards.
; ----------------------------------------------------------------------
SCAN_PROBE:
        ; record the probed slot's $Cn high byte (also read by the Z-80 handshake via $003D)
        STY $3D                          ; high byte = $Cn
        ; self-modify this routine's own STA operand high byte (SCAN_PROBE_HI) to $Cn so the next
        ; store targets $Cn00
        STY SCAN_PROBE_HI                ; patch high byte of STA operand
        .byte   $8D, $00         ; STA opcode + operand LOW byte ($00) -- the probe write to $Cn00; HIGH byte self-patched below
SCAN_PROBE_HI:
        .byte   $C0              ; STA operand HIGH byte: STY SCAN_PROBE_HI above patches it to $Cn (target $Cn00). Shipped $C0 -> $C000 = KBD before the patch, never actually stored
                                         ;        A WRITE (not a read) to the
                                         ;        slot-dependent control area
                                         ;        $CN00 switches CPUs [DOC S&HD
                                         ;        2-24/2-31 ; facts sec.2.5]
        RTS

        .res    119, $FF                 ; fill

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

; ----------------------------------------------------------------------
; INSTALL_IMG -- the install image ($1200-$13FF), copied to $0200-$03FF (Z-80 0F200H-0F3FFH, the I/O
; Configuration Block) by S2_COPYCFG/S2_COPYCFG2 at boot.
;   In:        none (pure data in this 6502 boot image; nothing here executes at $1200).
;   Out:       after the copy, $0200-$03FF holds the config block: $034A Z-80 console/SoftCard init
;              code (INCBIN'd ConInit), $037C the RPC_SERIAL_OUT stub, $0380 the I/O Vector Table +
;              screen/keyboard config, $03C0 the 6502->Z-80 RPC service loop / mode-switch, $03D0
;              A$VEC, $03DE Z$CPU, $03EF.. the RWTS parameter tail.
;   Clobbers:  none (data).
;   Algorithm: OBSERVED: this label marks 330 bytes of $00 fill ($1200-$1349 -> $0200-$0349). [DOC
;              S&HD 2-6/2-12 ; facts sec.2.2/3] The low config-block page ($0200-$02FF) and
;              $0300-$0349 ship as zero here and are BUILT at runtime (S2_SLOTSCAN writes the Card
;              Type Table + disk-count byte; the Z-80 console-init code populates the rest). The
;              non-fill tenants of the image follow at $134A onward.
; ----------------------------------------------------------------------
INSTALL_IMG:
        .res    255, $00                 ; $00 fill ($0200 page)
        .res    75, $00                  ; $00 fill ($0300..$0349)

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
;     INCLUDE "apple_softcard.inc"   ; Apple/SoftCard external names (single source of truth)
;
; SLOT3IO EQU $E0BE        ; slot-3 device status register (Apple $C0BE)
;
;     ORG $F34A
;
; ; ----------------------------------------------------------------------------
; ; CON_STATUS -- console input status. A type-3 (serial) slot-3 card: return $FF
; ;   if a character is ready, else $00. Any other card type defers to the BIOS
; ;   console-status entry.
; ;   Out: A = $FF (char ready) / $00 (not).  Clobbers: A, flags.
; ; ----------------------------------------------------------------------------
; CON_STATUS:                     ; console status
;     LD A,(SLTTYP3)              ; slot-3 card type
;     CP $03                      ; a type-3 (serial) card?
;     JP NZ,$AB0C                 ; no -> BIOS console status
;     LD A,(SLOT3IO)              ; serial status register
;     RRA                         ; bit0 (char ready) -> carry
;     SBC A,A                     ; A = $FF if ready else $00
;     RET
;
; ; ----------------------------------------------------------------------------
; ; CON_INPUT -- console input. Fetch a raw key via the BIOS and strip the high bit.
; ;   Out: A = 7-bit ASCII char.  Clobbers: A, flags.
; ; ----------------------------------------------------------------------------
; CON_INPUT:                      ; console input
;     CALL $AB12                  ; fetch raw key via BIOS
;     AND $7F                     ; strip high bit
;     RET
;
; ; ----------------------------------------------------------------------------
; ; CON_OUTPUT -- console output (char in C). A type-3 serial card: spin until the
; ;   Tx register is ready (OUT_WAIT), then RPC the char to the 6502 -- A$VEC points
; ;   at the "STA $C0BF ; RTS" stub ($037C), fired by touching Z$CPU. Any other card
; ;   type defers to the BIOS console-output entry.
; ;   In: C = char.  Clobbers: A, HL, flags.
; ; ----------------------------------------------------------------------------
; CON_OUTPUT:                     ; console output (char in C)
;     LD A,(SLTTYP3)              ; slot-3 card type
;     CP $03                      ; a type-3 (serial) card?
;     JP NZ,$AC3E                 ; no -> BIOS console output
; OUT_WAIT:                       ; spin until the serial Tx register is ready
;     LD A,(SLOT3IO)              ; serial status register
;     AND $02                     ; Tx-ready bit set?
;     JR Z,OUT_WAIT               ; spin until ready
;     LD A,C                      ; char to send
;     LD (RPC_ACC),A                ; hand it to the 6502 (A-reg cell)
;     LD HL,$037C                 ; 6502 sub: STA $C0BF ; RTS
;     LD (A_VEC),HL               ; A$VEC := $037C
;     LD HL,(Z_CPU)               ; HL := $En00
;     LD (HL),A                   ; touch $En00 -> RPC runs the 6502
;     RET
;   <<< end listing <<<
        .incbin "CPM_BootLoader_ConInit.bin" ; ..$137B  (Z-80; byte-identical)

; ----------------------------------------------------------------------
; RPC_SERIAL_OUT -- 6502 RPC stub: push one queued character to the slot-3 serial data register.
;   In:        A = character to transmit (placed in the 6502 A-reg by RESTORE from the $45-$48 save
;              area in the RPC loop before this runs). Stored at image $137C, RUN address $037C.
;   Out:       character written to the slot-3 serial card data register ($C0BF); RTS returns to the
;              RPC service loop, which then SAVEs results and hands the bus back to the Z-80.
;   Clobbers:  nothing (A preserved; no flags of interest).
;   Algorithm: [RE] The Z-80 CON_OUTPUT path (INCBIN'd ConInit) loads the char into the A-reg pass
;              cell, arms A$VEC=$037C (this stub's run address), then touches Z$CPU to switch to the
;              6502; the $03C0 loop RESTOREs A then JSRs the armed A$VEC, landing here. STA $C0BF
;              emits the byte; RTS resumes the loop. $C0BF is fixed slot-3 serial hardware (not
;              in-image, not relocatable) -> literal.
; ----------------------------------------------------------------------
RPC_SERIAL_OUT:
        ; transmit the queued character: store A to the slot-3 serial card's data register ($C0BF,
        ; fixed hardware)
        STA $C0BF                        ; (run $037C) char -> slot-3 serial data reg
        ; return to the RPC service loop (which SAVEs results and switches the bus back to the Z-80)
        RTS
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
        .byte   $4A, $F3, $58, $F3, $12, $AB, $5E, $F3
        .byte   $3E, $AC, $45, $AD, $45, $AD, $3F, $AD
        .byte   $3F, $AD, $2B, $AD, $2B, $AD, $20, $1B
        .byte   $AA, $D9, $D4, $A9, $A8, $1E, $BD, $0B
        .byte   $0C, $A0, $00, $0C, $0B, $1D, $0E, $0F
        .byte   $19, $1E, $1F, $1C, $0B, $5B, $00, $7F
        .byte   $02, $5C, $15, $09, $FF, $FF, $FF, $FF
        .byte   $02, $03, $00, $04, $01, $00, $02, $00

; ----------------------------------------------------------------------
; RPC_SERVICE_LOOP -- the 6502 side of the cooperative two-CPU (RPC) protocol; the 6502
; idle/dispatch loop. Stored at image $13C0, RUN address $03C0 (after S2_COPYCFG copies it there).
; The 6502 RESET/NMI/IRQ-BRK hardware vectors all point here [DOC S&HD 2-25 ; facts sec.2.4/4.4].
;   In:        entered at $03C0 on a CPU-switch INTO the 6502 (the Z-80 touched Z$CPU). The Monitor
;              save area $45-$48 holds the Z-80's call parameters; A$VEC ($03D0) was armed by the
;              Z-80; the requested routine is reached via the runtime dispatch at $1010.
;   Out:       runs ONE requested 6502 routine, writes its results back to $45-$49 ($49 = 6502 SP),
;              then switches the bus back to the Z-80 and loops forever awaiting the next request.
;   Clobbers:  A, X, Y, P (loaded from / stored to the $45-$49 save area); the Language Card
;              read/write banking is toggled around the call.
;   Algorithm: [DOC S&HD 2-24/2-25 ; facts sec.4.1] Arm the Language Card for RAM bank-2 read+write
;              (two reads of $C083), then WRITE $C700 -- the slot-7 access that toggles the CPU back
;              to the Z-80 (the corrected 2.20 $C800-window hang point, see
;              CPM_SoftCard_RealMap_Findings.md). Execution PARKS at STA $C700 until the Z-80
;              switches back IN, resuming at $03C9: restore the LC to read-ROM, RESTORE A/X/Y/P from
;              $45-$48 (NOTE: $45 A / $46 Y / $47 X / $48 P per this file's EQU block; apple2.json
;              orders $46=XREG/$47=YREG -- see FLAG 2), JSR the dispatch at runtime $1010 to run the
;              requested routine, STA $C081 (LC read-ROM), JSR SAVE A/X/Y/P/S to $45-$49 (results),
;              then JMP $03C0 to hand the bus back. Every operand here is hardware
;              ($C083/$C081/$C700), Monitor (RESTORE/SAVE), or a fixed RUNTIME address ($1010
;              dispatch, $03C0 self) -- all stay literal; this loop is staged as data here and only
;              ever EXECUTES at $03C0.
; ----------------------------------------------------------------------
RPC_SERVICE_LOOP:
        LDA $C083                        ; LC: read RAM bank2, write-enable
        LDA $C083                        ; (two reads arm the LC write latch)
        STA $C700                        ; WRITE to the slot-7 page ($CN00)
                                        ;        switches CPUs -> to the Z-80
                                        ;        [DOC S&HD 2-24/2-31 ; facts sec.2.5]
        LDA $C081                        ; (resume here) LC: read ROM
        JSR RESTORE                      ; A,X,Y,P <- $45-$48 (Z-80's call params)
        JSR $1010                        ; dispatch the requested 6502 RPC routine
        STA $C081                        ; LC: read ROM
        JSR SAVE                         ; A,X,Y,P,S -> $45-$49 (results for Z-80)
        JMP $03C0                        ; loop -> hand the bus back to the Z-80

; --- $13DB..$13EE : RPC / config cells (-> $03DB..$03EE) ----------------------
;  $03D0 A$VEC (6502 sub-call address, low-high) [DOC S&HD 2-25 ; facts sec.4.2]
;  and $03DE Z$CPU (SoftCard location) [DOC S&HD 2-24/2-25 ; facts sec.4.3] live
;  in this window; here as initialized data.
        .byte   $00, $00
        .byte   $20, $00, $E7, $00, $0A, $00, $CD, $01
        .byte   $01, $60, $60, $00, $03, $00, $02, $00
        .byte   $00, $00

; ----------------------------------------------------------------------
; RWTS_PARM -- install-image source for the config-block tail; copied to $03F0-$03FF (Z-80
; 0F3F0H-0F3FFH) by S2_COPYPARM at boot.
;   In:        none (data). NOTE: S2_COPYPARM loads Y=$10 then DEY/BNE-loops, so it writes Y=$10..$1
;              -> $03FF..$03F0 and SKIPS Y=0 -- the byte at $13EF/$03EF is not copied; the file's
;              '$13EF..$13FF -> $03EF..$03FF' comment slightly overstates the low end.
;   Out:       the high tail of the I/O Configuration Block ($03F0-$03FF) is seeded with these
;              bytes.
;   Clobbers:  none (data).
;   Algorithm: OBSERVED bytes: $00, $C0,$03, $C0,$03, $A6, then three '4C C0 03' groups (= JMP
;              $03C0), then $C0,$03. The recurring $03C0/$C003 are the RPC-loop run address and an
;              address word; the 'JMP $03C0' groups plant jumps into RPC_SERVICE_LOOP's run address.
;              UNKNOWN: the precise per-cell role of this $03F0-$03FF tail -- the DOCUMENTED RWTS
;              caller IOB is the LOWER block $03E0-$03EB [DOC CPM_SoftCard_RWTS_IOB.md], so these
;              are NOT the standard caller params. All operands point at fixed runtime addresses
;              ($03C0/$C003) -> kept as .byte literals; marked [RE]/UNKNOWN rather than guessed.
; ----------------------------------------------------------------------
RWTS_PARM:
        ; [RE] config-block tail seed: address words $C003 plus the first of three planted 'JMP
        ; $03C0' ($4C $C0 $03) groups into the RPC-loop run address; precise per-cell semantics
        ; UNKNOWN (the documented RWTS caller IOB is the lower $03E0-$03EB block)
        .byte   $00, $C0, $03, $C0, $03, $A6, $4C, $C0
        .byte   $03, $4C, $C0, $03, $4C, $C0, $03, $C0
        .byte   $03
