; ============================================================================
; CP/M 2.20 (Microsoft SoftCard) -- 44K configuration -- BIOS
; ----------------------------------------------------------------------------
; Region:   Z-80 $AA00..$AEFF  (1280 / $500 bytes), the on-disk image of the
;           44K-config BIOS (CCP $9400 / BDOS $9C00 / BIOS $AA00, top of RAM
;           $AFFF -- matches the SoftCard CP/M 2.20 manual's 44K column).
; Source:   softcard/cpm-investigation/bios_220_44k_disk.bin (exact disk bytes).
; Rebuild:  reassembles BYTE-IDENTICAL to the disk image.
;
; Clean-room note: decompiled solely from these bytes plus the public CP/M 2.2
; BIOS architecture and the SoftCard CP/M 2.20 manual fact sheet
; (softcard/docs/CPM_Manual_Reconcile_Facts.md). [AI] = machine-inferred;
; [DOC] = backed by a manual page; [?] = unresolved.
;
; STRUCTURE OF THIS IMAGE
;   $AA00-$AA2C  BIOS jump table (15 x JP), the BIOS entry vectors.
;   $AA2D-$AAA1  Data: device-driver descriptor table (6 records) + a screen
;                parameter/mask block.  Pure data, never executed here.
;   $AAA2-$AB00  Code: card-type (slot) scan + WBOOT page-zero initialisation.
;   $AB01-$ABFF  $E5 trap-fill.  On disk these 255 bytes are all $E5 (the Z-80
;                "PUSH HL" / RST trap pattern).  The console/disk primitives the
;                jump table points at here ($AB08/$AB43/$AB50/...) are written
;                into this window at boot (runtime-generated handlers); they are
;                NOT present on disk.  Emitted as fill.
;   $AC00-$ACFF  Code: CONOUT/CONIN/LIST/PUNCH/READER IOBYTE demuxers, the
;                device-dispatch flag tails, and the disk sector parameter
;                builder (merged with a software screen-function lead-in branch).
;   $AD00-$ADFF  $E5 trap-fill (256 bytes) -- more runtime-generated handlers.
;   $AE00-$AEA7  Code: screen-function lookup/emit, cursor address handling,
;                plus a small block of BIOS RAM variables ($AEA2..$AEA7).
;   $AEA8-$AEFE  Code: cold-BOOT 6502 RPC stub, an HL-pointer selector, cursor
;                clamp, and a 6502-subroutine-call helper.  $AED5-$AEDE is a
;                10-byte data table embedded between two routines.
;   $AEFF        One opcode byte ($32, LD (nn),A) whose 2-byte operand lies in
;                the next BIOS chunk beyond this $500-byte image (truncation).
;
; CONFIG-BLOCK SYMBOLS (SoftCard I/O Configuration Block, $F200-$F3FF; the
; Z-80 view of 6502 $0200-$03FF).  All [DOC], per the 2.20 manual.
; ============================================================================

    DEVICE NOSLOT64K

; Apple / SoftCard external addresses -- the I/O Vector Table ($F380-$F394), the
; screen-function cells (SXYOFF/SFLDIN/HXYOFF/HFLDIN), the Card Type Table
; (DSKCNT/SLTTYP), the 6502 RPC cells (A_VEC, RPC_ACC, RPC_YREG) and the keyboard
; (KEYBD/KEYSTB) -- all come from the shared single-source-of-truth include
; (manual-cited / apple2.json). See softcard/include/apple_softcard.inc.
    INCLUDE "apple_softcard.inc"
; ---- CP/M low memory -----------------------------------------------------
BDOS_ENTRY  EQU $9C06        ; BDOS entry (44K: FBASE $9C00 + 6) -- [DOC CPMREF 3-41/3-42 ; facts sec.2.3]
CCP_ENTRY   EQU $9400        ; CCP entry (44K: CBASE) -- [DOC CPMREF 3-41/3-42 ; facts sec.2.3]

        INCLUDE "cpm22.inc"
    ORG $AA00

; ============================================================================
; BIOS JUMP TABLE  ($AA00) -- standard CP/M BIOS entry vectors.
; 15 entries (BOOT..WRITE).  Most console/disk targets land in the $E5 trap-fill
; ($AB../$AD..) because those primitives are generated into RAM at boot.
; Only BOOT ($AEA8) and WBOOT ($AACC) are real code on disk.
; ============================================================================
; ----------------------------------------------------------------------
; BIOS_BASE / JMPTAB -- standard CP/M BIOS jump table (15 entry vectors).
;   In:        Entered by the CP/M loader/CCP/BDOS through one of the 15 JP
;              slots; CP/M calls BIOS function N at BIOS_BASE + 3*N.
;   Out:       Transfers control to the selected primitive's body.
;   Clobbers:  None here (pure dispatch); each target defines its own effects.
;   Algorithm: A fixed table of 15 absolute JPs: BOOT, WBOOT, CONST, CONIN,
;              CONOUT, LIST, PUNCH, READER, HOME, SELDSK, SETTRK, SETSEC,
;              SETDMA, READ, WRITE. (This image stops at WRITE -- the CP/M 2.2
;              LISTST and SECTRAN entries are absent.) Only BOOT (COLD_BOOT) and
;              WBOOT are real code on disk; the console/disk targets land in the
;              $E5 trap-fill because those primitives are generated into RAM at
;              boot. [DOC CPMREF 3-44]
; ----------------------------------------------------------------------
BIOS_BASE:
        ; BIOS entry 0 BOOT -- cold start (real on-disk code at COLD_BOOT)
        JP      COLD_BOOT                ; $AA00  0  BOOT   (cold start)
; ----------------------------------------------------------------------
; JMPTAB -- BIOS warm-entry sub-base (jump-table entries 1..14).
;   In:        Page-zero $0000 holds 'JP JMPTAB', so any JP/CALL $0000
;              (CP/M warm-boot) re-enters CP/M through this WBOOT vector.
;   Out:       Dispatches to WBOOT (entry 1) and the remaining 13 primitives.
;   Clobbers:  None (dispatch only).
;   Algorithm: Continuation of the jump table from entry 1; WBOOT lays the
;              page-zero warm-boot JP pointing here (see WBOOT). [DOC CPMREF 3-44]
; ----------------------------------------------------------------------
JMPTAB:
        ; BIOS entry 1 WBOOT -- warm start; page-zero $0000 vectors here
        JP      WBOOT                    ; $AA03  1  WBOOT  (warm start)
        JP      CONST_IMPL               ; $AA06  2  CONST  (runtime handler)
        JP      CONIN_IMPL               ; $AA09  3  CONIN
        JP      CONOUT_IMPL              ; $AA0C  4  CONOUT
        JP      LIST_IMPL                ; $AA0F  5  LIST
        JP      PUNCH_IMPL               ; $AA12  6  PUNCH
        JP      READER_IMPL              ; $AA15  7  READER
        JP      HOME_IMPL                ; $AA18  8  HOME
        JP      SELDSK_IMPL              ; $AA1B  9  SELDSK
        JP      SETTRK_IMPL              ; $AA1E 10  SETTRK
        JP      SETSEC_IMPL              ; $AA21 11  SETSEC
        JP      SETDMA                   ; $AA24 12  SETDMA
        JP      READ_IMPL                ; $AA27 13  READ
        JP      WRITE_IMPL               ; $AA2A 14  WRITE

; ============================================================================
; DEVICE-DRIVER DESCRIPTOR TABLE + SCREEN PARAMETER BLOCK  ($AA2D-$AAA1)
; Pure data.  [AI]
;   $AA2D: small header -- XOR A;RET and LD H,B;LD L,C;RET fragments used as
;          generic null/identity helpers, plus zero padding.
;   $AA3B: six 16-byte device records, one per recognised console card type.
;          Each record = { handler=$AEBA, common=$AA93, p3, p4, 8x $00 }.
;          p3 steps +$0C (=$AF9A,$AFA6,...), p4 steps +$10 (=$AF3A,$AF4A,...);
;          both point into the $AF00+ runtime table area (off this image).
;   $AA94: screen parameter/mask block (byte pairs).
; ============================================================================
; ----------------------------------------------------------------------
; DEVTAB_HDR -- header/prologue of the device-driver descriptor table. PURE DATA.
;   In:        Indexed as data by the runtime console-driver setup (off-image).
;   Out:       Supplies a few lead bytes plus zero padding.
;   Clobbers:  n/a (data).
;   Algorithm: Six lead bytes whose values ALSO form valid Z-80 fragments --
;              $AF,$C9 = 'XOR A / RET' (return 0) and $60,$69,$C9 = 'LD H,B /
;              LD L,C / RET' (HL := BC, identity) -- followed by 8 zero-fill
;              bytes padding the header out to the first 16-byte device record.
;              OBSERVED: the bytes decode as those fragments; whether they are
;              actually entered as code (vs read only as table data) is UNKNOWN. [AI]
; ----------------------------------------------------------------------
DEVTAB_HDR:
        ; OBSERVED opcodes: $AF,$C9 = XOR A;RET (return 0); $60,$69,$C9 = LD H,B;LD L,C;RET
        ; (HL:=BC); whether reached as code is UNKNOWN [AI]
        DEFB    $AF,$C9,$00,$60,$69,$C9                          ; $AA2D
        DEFS    8, $00    ; $AA33  fill
; ----------------------------------------------------------------------
; DEVTAB -- device-driver descriptor table: 16-byte-stride records. PURE DATA.
;   In:        Read as data by the runtime console-driver selection code
;              (off this $500-byte image) once the card-type scan picks a card.
;   Out:       Per recognised console card type, supplies four pointer words.
;   Clobbers:  n/a (data).
;   Algorithm: One record per console card type, 16 bytes apart (signatures at
;              $AA3B,$AA4B,$AA5B,$AA6B,$AA7B,$AA8B). Records 0..4 = { handler=
;              $AEBA, common=$AA93, p3, p4, 8x $00 }; record 5 is short (ends at
;              SCRN_PARM-1) with a trailing $20 flag in place of the zero fill.
;              p3 steps +$0C ($AF9A,$AFA6,...) and p4 steps +$10 ($AF3A,$AF4A,...),
;              both into the $AF00+ runtime table area OFF this image.
;              KEEP_LITERAL: the records are deliberately left as raw DEFB, not
;              DEFW labels -- handler $AEBA is a genuine MID-INSTRUCTION entry
;              into the PTRSEL skip-idiom (inside LD BC,$582E at $AEB9, no clean
;              label boundary), common $AA93 is mid-data, and p3/p4 are off-image,
;              so none of the four words has a labelable boundary. [AI]
; ----------------------------------------------------------------------
DEVTAB:
        ; record 0: handler=$AEBA (mid-instruction PTRSEL entry), common=$AA93 (mid-data), p3=$AF9A,
        ; p4=$AF3A (p3/p4 off-image $AF00 runtime tables)
        DEFB    $BA,$AE,$93,$AA,$9A,$AF,$3A,$AF                  ; $AA3B record 0
        DEFS    8, $00    ; $AA43  fill
        DEFB    $BA,$AE,$93                                      ; $AA4B record 1
        DEFB    $AA,$A6,$AF,$4A,$AF,$00                          ; $AA4E
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA54 record 2
        DEFB    $AA,$B2,$AF,$5A,$AF,$00                          ; $AA5E
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA64 record 3
        DEFB    $AA,$BE,$AF,$6A,$AF,$00                          ; $AA6E
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA74 record 4
        DEFB    $AA,$CA,$AF,$7A,$AF,$00                          ; $AA7E
        ; record 5 (last, short): handler=$AEBA, common=$AA93, p3=$AFD6, p4=$AF8A, trailing flag $20
        ; (no zero fill)
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93,$AA,$D6,$AF,$8A,$AF,$20 ; $AA84 record 5
; ----------------------------------------------------------------------
; SCRN_PARM -- screen parameter / field-mask block. PURE DATA.
;   In:        Read by the screen-function emit/cursor code as byte pairs.
;   Out:       Supplies screen mask/limit constants used by the console output
;              screen-function machinery.
;   Clobbers:  n/a (data).
;   Algorithm: A block of little-endian byte pairs ($0300,$0007,$007F,$002F,
;              $00C0,$000C,$0003) used as masks/limits; $7F and $C0 look like a
;              character-field and a high-video mask respectively, but the exact
;              role of each pair is UNKNOWN. Never executed. [AI]
; ----------------------------------------------------------------------
SCRN_PARM:
        ; screen mask/limit byte pairs (incl. $7F and $C0 -- likely char-field / high-video masks;
        ; exact roles UNKNOWN) [AI]
        DEFB    $00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,$00,$03,$00 ; $AA94

; ============================================================================
; CARD-TYPE (SLOT) SCAN  ($AAA2)  -- [DOC S&HD 2-26/2-27 ; facts sec.3.6]
; Walk the Card Type Table for slots 7..1 (DSKCNT+S).  When an entry == 3
; (Apple Comms / CCS serial), initialise that slot's serial driver and rewrite
; the table entry to 3 then $15.  When the (post-SUB) value hits the device-4
; case (Videx / high-speed serial / Sup-R-Term), claim the $C800 expansion-ROM
; window via RPC_DISPATCH.  DE = slot index counter (7 down to 1).
; [DOC S&HD 2-26/2-27] the Card Type Table is at $F3B9 (= SLTTYP), one byte per
; slot, entry for slot S at $F3B8+S; value 3 = Apple Comms / CCS 7710A serial,
; value 4 = Apple Hi-Speed Serial / Videx Videoterm / M&R Sup-R-Term / Silentype
; (an 80-column external terminal when in slot 3).  The device-6 (Pascal-1.1)
; probe that 2.23 adds is absent here -- that delta is [RE], not manual-backed.
; ============================================================================
; ----------------------------------------------------------------------
; CARDTYPE_SCAN -- probe the Card Type Table and bring up serial / 80-col cards.
;   In:        Card Type Table at DSKCNT ($F3B8), one byte per slot S at
;              $F3B8+S, already populated (value 3 = Apple Comms / CCS serial,
;              value 4 = Apple Hi-Speed Serial / Videx / Sup-R-Term / Silentype).
;              [DOC S&HD 2-26/2-27]
;   Out:       Each serial (3) slot's driver is initialised and its table entry
;              rewritten (net $15); for an 80-col (4) card the $C800 expansion-ROM
;              window is claimed via the 6502 RPC. Table bytes may be overwritten.
;   Clobbers:  A, DE, HL (plus whatever SERIAL_INIT and RPC_DISPATCH touch).
;   Algorithm: Walk slots 7 down to 1 (E = slot, D = 0). For each, A := table[slot];
;              SUB 3 tests for the serial card (==3): if so, init the serial driver
;              and rewrite the entry. Then DEC A on the (post-SUB) value tests the
;              device-4 case (Videx/hi-speed/Sup-R-Term): if so, run the screen-fn
;              lead-in init and hand the 6502 the $C800 window-claim address. Loop
;              on E. The device-6 (Pascal-1.1) probe that 2.23 adds is absent here. [RE]
; ----------------------------------------------------------------------
CARDTYPE_SCAN:
        ; scan slots 7 down to 1 (E = slot index, D = 0 so ADD HL,DE adds only the slot offset)
        LD DE,$0007                      ; $AAA2  scan slots 7..1
SCAN_LOOP:
        LD HL,DSKCNT                     ; $AAA5  HL = Card Type Table base ($F3B8) [DOC S&HD 2-27]
        ADD HL,DE                        ; $AAA8  -> entry for slot E ($F3B8+S) [DOC S&HD 2-26]
        ; fetch this slot's detected card type [DOC S&HD 2-26]
        LD A,(HL)                        ; $AAA9  A = card type for this slot
        SUB $03                          ; $AAAA  ==3 ? (Apple Comms / CCS serial) [DOC S&HD 2-26]
        JR NZ,SCAN_TEST_DEV4                  ; $AAAC
        ; card type 3 (Apple Comms / CCS serial): bring up the serial driver
        CALL SERIAL_INIT                      ; $AAAE  (runtime) init serial driver
        ; OBSERVED: store $03 then immediately overstore $15 into table[slot] (net = $15, a
        ;           non-card-type marker); the $03 store is dead and its purpose is UNKNOWN
        LD (HL),$03                      ; $AAB1
        LD (HL),$15                      ; $AAB3
SCAN_TEST_DEV4:
        ; post-SUB value 4 ? -> the 80-col card case (Videx / hi-speed / Sup-R-Term / Silentype)
        ; [DOC S&HD 2-26/2-27]
        DEC A                            ; $AAB5  was value 4 ? (Videx / hi-speed) [DOC S&HD 2-26/2-27]
        JR NZ,SCAN_NEXT                  ; $AAB6
        ; 80-col card: run the screen-function lead-in init (mid-instruction cover entry at $ACEE,
        ; inside the JR at $ACED) [RE]
        CALL SF_INIT_TAIL+1              ; $AAB8  ($ACEE) screen-fn lead-in init
        ; pass the 6502 the $C800 shared expansion-ROM window address (claimed for the 80-col card)
        LD HL,$C800                      ; $AABB  expansion-ROM window
        ; issue the 6502 RPC to claim the $C800 window
        CALL RPC_DISPATCH                    ; $AABE  (runtime) claim $C800 window
SCAN_NEXT:
        ; advance to the next lower slot; loop until E reaches 0
        DEC E                            ; $AAC1  next slot
        JR NZ,SCAN_LOOP                  ; $AAC2
        RET                              ; $AAC4

; ----------------------------------------------------------------------
; SLOT_TO_EN -- form the Z-80 slot I/O-page base address $EN00 in HL.
;   In:        E = slot number (1..7).
;   Out:       HL = $EN00 where N = slot (high byte = $E0 | slot, low byte $00).
;   Clobbers:  A, HL.
;   Algorithm: Start from the $E000 I/O-page base, OR the slot number into the
;              high byte to get $EN00 = the Z-80 view of Apple $CN00 (slot N's
;              peripheral-card I/O / ROM-select page). For the SoftCard's OWN
;              slot, an access to that $CN00 page is what flips the CPU bus back
;              to the 6502 (the documented CPU-switch trigger; e.g. LD ($E700),A
;              for a slot-7 card -- see CPM_SoftCard_RealMap_Findings). This is
;              NOT the config-block cell Z_CPU ($F3DE); it is the slot I/O page
;              itself. [RE]
;              (Caller RPC_SETUP at $AEFA; the source of E there is not traced
;              in this cluster -- [RE].)
; ----------------------------------------------------------------------
SLOT_TO_EN:
        ; $E000 I/O-page base (low byte $00, high byte $E0)
        LD HL,KEYBD                      ; $AAC5  $E000 base
        LD A,E                           ; $AAC8
        ; merge slot number into the high byte -> $EN; HL becomes $EN00 (Apple $CN00 slot I/O page)
        OR H                             ; $AAC9
        LD H,A                           ; $AACA
        RET                              ; $AACB

; ============================================================================
; WBOOT  ($AACC)  -- warm boot / system (re)initialisation.
; Sets the Z-80 stack, re-claims the $0E00 area, runs the card-type scan,
; clears two BIOS flags, and lays down the page-zero jump vectors:
;   $0000 = JMP WBOOT-table ($AA03),  $0005 = JMP BDOS_ENTRY ($9C06).
; Then resets the default DMA (BC=$0080) and warm-starts the console.
; [DOC CPMREF 3-44] page-zero restart layout: $0000 holds a JMP to the BIOS
; warm-boot entry; $0005 holds a JMP to FBASE (the BDOS primary entry point at
; BOOT+0005H), and the address word at $0006/$0007 = FBASE = top of usable RAM.
; [DOC CPMREF 3-46 ; facts sec.7.4] the default DMA buffer is $0080, reset to
; $0080 on cold start, warm start, and disk reset.
; [DOC CPMREF 3-47/3-48 ; facts sec.7.5] $0080 is also the base of the default
; 128-byte command-tail buffer (byte $0080 = char count, then the tail); the
; page-zero region below it ($005C default FCB, $006C second FCB) is reserved, so
; SP=$0080 sets the Z-80 stack at the top of that reserved page-zero/buffer area,
; just below the TPA at $0100.
; ============================================================================
; ----------------------------------------------------------------------
; WBOOT -- warm boot: rebuild the page-zero vectors and restart the console/CCP.
;   In:        Entered via BIOS jump-table entry 1 (and page-zero JP $0000).
;   Out:       Z-80 SP = $0080; page zero relaid -- $0000 = JP JMPTAB (BIOS
;              warm entry), $0005 = JP BDOS_ENTRY, $0006/7 = BDOS-entry pointer
;              (top-of-TPA marker); default DMA reset to $0080; card-type scan
;              re-run; two BIOS flags cleared; $01 written to off-image $E5B2;
;              falls through into the runtime-handler $E5 fill.
;   Clobbers:  A, BC, HL, SP, and page-zero $0000-$0007, plus CURMODE/FLAG_AEAF
;              and whatever RPC_DISPATCH/CARDTYPE_SCAN/SETDMA touch.
;   Algorithm: Set the Z-80 stack at the default-DMA/command-tail base ($0080,
;              just below the TPA). Read the Apple text-mode soft switch (force
;              text mode) and run a 6502 RPC setup for the $0E00 area, then
;              rescan slot card types. Clear the screen-fn selector flags, write
;              the page-zero warm-boot JP ($0000->JMPTAB) and BDOS JP ($0005->
;              BDOS_ENTRY) plus the BDOS-entry pointer word, reset the default
;              DMA to $0080, then write $01 to $E5B2 (off-image, purpose UNKNOWN)
;              and fall through into the runtime-handler fill.
;              [DOC CPMREF 3-44/3-46/3-47]
; ----------------------------------------------------------------------
WBOOT:
        ; set the Z-80 stack at the default-DMA / command-tail base ($0080), just below the TPA [DOC
        ; CPMREF 3-47/3-48]
        LD SP,$0080                      ; $AACC  Z-80 stack at default-DMA/command-tail base ($0080), below TPA [DOC CPMREF 3-47/3-48 ; facts sec.7.5]
        ; force the Apple into text mode (read the TXTSET soft switch)
        LD A,(TXTSET)                 ; $AACF  $E051 (Apple text/lo-res switch)
        LD HL,$0E00                      ; $AAD2
        ; 6502 RPC: set up the $0E00 area
        CALL RPC_DISPATCH                    ; $AAD5  (runtime) setup
        ; re-run the slot card-type probe on warm boot
        CALL CARDTYPE_SCAN               ; $AAD8  rescan slot card types
        ; clear the screen-function selector flags (CURMODE=$AEB4, FLAG_AEAF=$AEAF)
        XOR A                            ; $AADB
        LD (CURMODE),A                   ; $AADC  $AEB4 = 0 (skip-idiom selector)
        LD (FLAG_AEAF),A                 ; $AADF  $AEAF = 0
        ; lay down the page-zero warm-boot/BDOS JP vectors (opcode $C3 = JP)
        LD A,$C3                         ; $AAE2  opcode JP
        ; $0000 = JP JMPTAB ($AA03) -- the CP/M warm-boot vector [DOC CPMREF 3-44]
        LD ($0000),A                     ; $AAE4  $0000 = JP ... [DOC CPMREF 3-44] warm-boot vector
        LD HL,JMPTAB                     ; $AAE7    ... ($AA03) BIOS warm-entry
        LD ($0001),HL                    ; $AAEA
        ; $0005 = JP BDOS_ENTRY ($9C06); $0006/7 = BDOS-entry pointer (programs read it as
        ; top-of-TPA) [DOC CPMREF 3-44]
        LD ($0005),A                     ; $AAED  $0005 = JP ... [DOC CPMREF 3-44] BDOS entry (BOOT+5)
        LD HL,BDOS_ENTRY                 ; $AAF0    ... BDOS ($9C06)
        LD ($0006),HL                    ; $AAF3  $0006/7 = FBASE ptr (top of usable RAM) [DOC CPMREF 3-44]
        ; reset the default DMA buffer to $0080 [DOC CPMREF 3-46]
        LD BC,$0080                      ; $AAF6  default DMA = $0080 [DOC CPMREF 3-46 ; facts sec.7.4]
        CALL SETDMA                      ; $AAF9  ($AD8E) set DMA address
        ; OBSERVED: write $01 to $E5B2 (Apple $C5B2, an off-image I/O-page address, NOT in-image
        ;           RAM); purpose UNKNOWN -- then fall through into the $E5 trap-fill
        LD A,$01                         ; $AAFC
        LD ($E5B2),A                     ; $AAFE  init runtime-handler RAM cell
; --- $AB01..$ABFF : $E5 trap-fill (runtime-generated console/disk handlers) ---
        DEFB    $E5,$E5,$E5,$E5,$E5,$E5,$E5                      ; $AB01
CONST_IMPL:
        DEFS    31, $E5    ; $AB08  fill  (CONST handler, generated at boot)
CONIN_IMPL_1:
        DEFB    $E5,$E5                                          ; $AB27
CONIN_RAW:
        DEFB    $E5,$E5,$E5,$E5,$E5,$E5                          ; $AB29
LIST_EMIT:
        DEFS    12, $E5    ; $AB2F  fill
RPC_DISPATCH:
        DEFS    8, $E5    ; $AB3B  fill
CONOUT_IMPL:
        DEFS    13, $E5    ; $AB43  fill  (CONOUT handler)
CONIN_IMPL:
        DEFS    22, $E5    ; $AB50  fill  (CONIN handler)
LIST_IMPL:
        DEFS    15, $E5    ; $AB66  fill  (LIST handler)
PUNCH_IMPL:
        DEFS    18, $E5    ; $AB75  fill  (PUNCH handler)
READER_IMPL:
        DEFS    42, $E5    ; $AB87  fill  (READER handler)
DISK_RPC_PUSH_ADDR:
        DEFB    $E5,$E5                                          ; $ABB1  (runtime) push sector-addr param
DISK_XLAT_POS_SECTOR:
        DEFS    10, $E5    ; $ABB3  fill  (runtime) positive-skew continuation
DISK_XLAT_NEG_SECTOR:
        DEFS    18, $E5    ; $ABBD  fill  (runtime) negative-skew (extended) case
DISK_XLAT_SECTOR_HI:
        DEFS    14, $E5    ; $ABCF  fill  (runtime) hi-component build
SF_EMIT_LEADIN:
        DEFS    35, $E5    ; $ABDD  fill

; ============================================================================
; CONSOLE STATUS / WARM-START TAIL  ($AC00)
; The warm-start tail loads C with the current disk/user byte ($0004) and jumps
; into the CCP transient at its entry ($9400).  [DOC CPMREF 3-44 ; facts sec.7.3]
; the CCP is the transient command processor launched after (re)load; on entry it
; sets its own 8-level stack with the warm-boot return pushed.  C carries the
; current drive/user so the CCP restores the A> prompt drive on warm start.
; ============================================================================
; ----------------------------------------------------------------------
; WBOOT_TAIL -- warm-start tail: hand the CCP the current drive/user and re-enter it.
;   In:        Reached by the runtime warm-boot reload sequence (generated into the $AB01-$ABFF $E5
;              trap-fill) after WBOOT has relaid page zero, set the stack, rescanned card types and
;              reset the default DMA. CP/M base page $0004 (CDISK_ADDR) holds the current drive (low
;              nibble) / user (high nibble).
;   Out:       C = current drive/user byte; control transferred to the CCP transient at CCP_ENTRY
;              ($9400), which restores the A> prompt drive on warm start. Does not return.
;   Clobbers:  A, C (then the CCP owns the machine).
;   Algorithm: Load the persisted current-drive/user byte into C and JP into the CCP entry point, so
;              the freshly (re)loaded command processor comes up on the same drive the user last
;              selected. [DOC CPMREF 3-44 ; facts sec.7.3]
;   OBSERVED/[RE]: the static byte at $AC00 disassembles as SBC A,B ($98) but is NOT an executed
;   instruction. It is the residual HIGH operand byte of the warm-boot store that the runtime
;   warm-boot handler BUILDS INTO the $E5 trap-fill region; on disk the bytes at $ABFE/$ABFF are $E5
;   fill (not a store) and $AC00 is $98, so statically $AC00 is a mid-instruction artifact and the
;   real tail entry is LD A,($0004) at $AC01. The byte-identical CPMV223-44K twin shows the
;   corresponding store as LD ($974E),A at $FC06 (so the 2.20 target is a $98xx/$97xx BIOS-RAM
;   cell); the exact target and the $98 value are UNKNOWN from this image. (Note: this is distinct
;   from the build's actual on-disk WBOOT store LD ($E5B2),A at $AAFE, which precedes the
;   trap-fill.)
; ----------------------------------------------------------------------
WBOOT_TAIL:
        SBC A,B                          ; $AC00  98
        ; load the persisted current drive (low nibble) / user (high nibble) byte so the CCP can
        ; restore the prompt drive on warm start [DOC CPMREF 3-44]
        LD A,(CDISK_ADDR)                     ; $AC01  current disk/user byte
        LD C,A                           ; $AC04
        ; re-enter the (re)loaded CCP transient with C = current drive/user [DOC CPMREF 3-44 ; facts
        ; sec.7.3]
        JP CCP_ENTRY                     ; $AC05  enter the CCP transient ($9400) [DOC CPMREF 3-44 ; facts sec.7.3]

; ----------------------------------------------------------------------
; CONST_DISP -- CONST body: dispatch console-status through the Console Status vector.
;   In:        I/O Vector Table cell CONST_VEC ($F380) holds the active Console Status #1 handler
;              address (low-high). [DOC S&HD 2-16..2-18]
;   Out:       Tail-jumps (JP (HL)) into that handler, which returns A=$FF if a console character is
;              ready else A=$00. Does not return here.
;   Clobbers:  HL (then the dispatched handler defines A and flags).
;   Algorithm: Indirectly load the Console Status #1 handler from the I/O Vector Table and jump to
;              it. Console STATUS is never IOBYTE-demuxed (verified: this body reads no IOBYTE) --
;              it always routes through Console Status #1. The default target is CONST_KBD (the
;              Apple key-ready test); CONFIGIO can repatch CONST_VEC to another card's status
;              routine. [DOC S&HD 2-16..2-18]
; ----------------------------------------------------------------------
CONST_DISP:
        ; fetch the active Console Status #1 handler from the I/O Vector Table (default = CONST_KBD)
        ; [DOC S&HD 2-16]
        LD HL,(CONST_VEC)                ; $AC08  $F380 Console Status vector
        ; tail-jump into the console-status handler; it returns A=$FF (ready) / $00 (none)
        JP (HL)                          ; $AC0B

; ----------------------------------------------------------------------
; CONST_KBD -- default Console Status #1 handler: Apple keyboard ready test.
;   In:        KEYBD ($E000), the Apple keyboard data/strobe soft switch; bit 7 set = a key is
;              waiting. [DOC S&HD 2-23]
;   Out:       A = $FF if a key is ready, $00 if not (the CP/M Console Status contract value). Does
;              NOT clear the strobe (a non-destructive peek).
;   Clobbers:  A, flags.
;   Algorithm: Read the keyboard latch, rotate bit 7 (key-ready strobe) into carry (RLA), then SBC
;              A,A to smear carry across the whole byte: carry=1 -> A=$FF, carry=0 -> A=$00. This is
;              the routine CONST_VEC points at by default. [DOC S&HD 2-23]
; ----------------------------------------------------------------------
CONST_KBD:
        ; read the Apple keyboard latch (bit 7 = a key is waiting); a non-destructive peek that
        ; leaves the strobe intact [DOC S&HD 2-23]
        LD A,(KEYBD)                     ; $AC0C  read keyboard ($E000)
        ; shift the key-ready bit (b7) into carry
        RLA                              ; $AC0F  key-ready bit (b7) -> carry
        ; expand carry across the byte: A=$FF if a key is ready, $00 otherwise (the Console Status
        ; contract value)
        SBC A,A                          ; $AC10  A = $FF if ready else $00
        RET                              ; $AC11

; ----------------------------------------------------------------------
; KBD_REDEF -- read a console key and apply the Keyboard Character Redefinition Table.
;   In:        Calls the runtime CONIN_RAW primitive for the raw keystroke. Keyboard Character
;              Redefinition Table at $F3AC (config block): up to six 2-byte entries {original ASCII,
;              replacement ASCII}, terminated early by a byte with the high bit set. [DOC S&HD 2-17]
;   Out:       A = the redefined ASCII if the key matched a table entry, else the original key.
;              Applies to the console-input path. [DOC S&HD 2-17]
;   Clobbers:  A, B, C, HL, flags.
;   Algorithm: Fetch the raw key, set HL to the table base minus one ($F3AB) so the loop's leading
;              INC HL lands on the first entry, set B=6 (max entries) and stash the key in C; then
;              scan {orig,new} pairs in KBD_REDEF_LP. NOTE: unlike CPMV223-44K (which does AND $7F
;              here), this 2.20 build does NOT mask the raw key before scanning -- verified against
;              the sibling.
; ----------------------------------------------------------------------
KBD_REDEF:
        ; get one raw keystroke from the runtime console-input primitive
        CALL CONIN_RAW                    ; $AC12  (runtime) get raw key in A
        ; point at the Keyboard Character Redefinition Table base minus 1 ($F3AC-1); the loop's
        ; leading INC HL advances to the first {orig,new} entry [DOC S&HD 2-17]
        LD HL,$F3AB                      ; $AC15  redefinition table - 1 ($F3AC base) [DOC S&HD 2-17]
        ; scan at most six redefinition entries [DOC S&HD 2-17]
        LD B,$06                         ; $AC18  up to 6 entries [DOC S&HD 2-17]
        ; hold the key under test in C for the per-entry compare
        LD C,A                           ; $AC1A  C = key to match
; ----------------------------------------------------------------------
; KBD_REDEF_LP -- per-entry scan of the Keyboard Character Redefinition Table.
;   In:        HL -> one byte before the current entry (from the previous iteration); B = entries
;              remaining; C = key under test. [DOC S&HD 2-17]
;   Out:       On a high-bit terminator: jumps to the runtime CONIN handler (CONIN_IMPL_1) with no
;              substitution. On a match: falls into KBD_REDEF_HIT which returns the replacement
;              byte. On a miss: continues via the DJNZ in KBD_REDEF_HIT.
;   Clobbers:  A, HL, flags (B walked by the trailing DJNZ).
;   Algorithm: Advance HL to the entry's original-ASCII byte, load it, advance HL to the replacement
;              byte, and test the original: high bit set marks the early end of the table -> hand
;              off to the CONIN handler; otherwise compare the original against the key in C and
;              fall into the shared match tail (KBD_REDEF_HIT). [DOC S&HD 2-17]
; ----------------------------------------------------------------------
KBD_REDEF_LP:
        INC HL                           ; $AC1B
        ; read this entry's original-ASCII byte (the key it would redefine) [DOC S&HD 2-17]
        LD A,(HL)                        ; $AC1C  ASCII to redefine [DOC S&HD 2-17]
        INC HL                           ; $AC1D
        ; test the high bit: set => early end-of-table terminator [DOC S&HD 2-17]
        OR A                             ; $AC1E
        ; end of table reached with no match -> deliver the key unchanged via the runtime CONIN
        ; handler [DOC S&HD 2-17]
        JP M,CONIN_IMPL_1                      ; $AC1F  high bit set = end of table [DOC S&HD 2-17]
        ; compare this entry's original against the key under test; equal sets Z for the
        ; KBD_REDEF_HIT match tail
        CP C                             ; $AC22
; ----------------------------------------------------------------------
; KBD_REDEF_HIT -- shared 'load (HL), return-if-zero' tail used by two callers.
;   In:        HL -> a byte to load (the keyboard-redef replacement byte in the KBD_REDEF loop; or,
;              from SF_LK_HIT's no-lead-in path, the matched screen-fn descriptor byte); B,C as set
;              by the caller.
;   Out:       A = (HL); RET if the Z flag (from the caller's preceding compare/OR) is set. In the
;              KBD_REDEF path a non-zero result continues the redefinition scan via DJNZ.
;   Clobbers:  A; (KBD_REDEF path also walks B/HL).
;   Algorithm: this is the match tail of KBD_REDEF (its primary owner): LD A,(HL) yields the
;              redefined keystroke and RET Z handles a matched/empty slot, then DJNZ continues
;              scanning. SF_LK_HIT reuses just the LD A,(HL)/RET-Z head for its no-lead-in case
;              (with the Z flag coming from the descriptor OR A at $AE11). [RE] the downstream DJNZ
;              path is only meaningful for the keyboard caller; the SF caller's exact continuation
;              here is inferred.
; ----------------------------------------------------------------------
KBD_REDEF_HIT:
        ; ; load the result byte (redefined key, or the no-lead-in screen-fn emit char)
        LD A,(HL)                        ; $AC23  matched -> replacement ASCII
        RET Z                            ; $AC24
        DJNZ KBD_REDEF_LP                ; $AC25
        LD A,C                           ; $AC27  no match -> original key
        RET                              ; $AC28

; ----------------------------------------------------------------------
; LIST_ENTRY -- preload DE then enter the runtime list/console tail.
;   In:        none required by this stub (the source of control is a runtime-generated handler in
;              the $AB.. fill and is not traced in this static image).
;   Out:       DE = $0003; falls into LIST_ENTRY_JP which JP's to the runtime LIST_EMIT handler.
;   Clobbers:  DE.
;   Algorithm: Load the constant $0003 into DE and tail into LIST_ENTRY_JP. UNKNOWN: the meaning of
;              $0003 is not resolvable from this image -- it could be the CP/M IOBYTE base-page
;              address ($0003) or a literal small-integer parameter (3). The CPMV223-44K twin loads
;              the same $0003 (there before JP CONIN_IMPL_2), and passing the IOBYTE *address* in DE
;              to an emit handler does not fit the usual CP/M pattern, so a count is at least as
;              plausible; not rewritten to a symbol to avoid asserting an unconfirmed meaning. [RE]
; ----------------------------------------------------------------------
LIST_ENTRY:
        ; load the constant 3 for the runtime list/console tail; whether this is the IOBYTE address
        ; $0003 or a small-integer parameter is UNKNOWN [RE]
        LD DE,$0003                      ; $AC29
; ----------------------------------------------------------------------
; LIST_ENTRY_JP -- tail-jump into the runtime-generated list-emit handler.
;   In:        DE as set by the caller (LIST_ENTRY loads $0003).
;   Out:       JP to LIST_EMIT, the console/list emit primitive generated into the $AB.. RAM fill at
;              boot (not present on disk). Does not return.
;   Clobbers:  whatever LIST_EMIT touches.
;   Algorithm: A single JP into the runtime list handler. NOTE: LIST_ENTRY_JP+1 ($AC2D) is a
;              deliberate mid-instruction re-entry, reached by CALL LIST_ENTRY_JP+1 at $ACD7 in the
;              screen-fn emit path (verified); the precise effect of entering the JP one byte in is
;              UNKNOWN, and the label is kept so the +1 reference stays anchored and relocatable.
;              [RE]
; ----------------------------------------------------------------------
LIST_ENTRY_JP:
        ; tail-jump into the runtime-generated list/console emit handler (LIST_ENTRY_JP+1 is a
        ; separate mid-instruction re-entry from the screen-fn emit at $ACD7) [RE]
        JP LIST_EMIT                        ; $AC2C  (runtime) list handler
                                         ; (LIST_ENTRY_JP+1 = $AC2D is a re-entry
                                         ;  used by the screen-fn emit at $ACD7)

; ----------------------------------------------------------------------
; KBD_WAIT_STROBE -- block until an Apple key is pressed, then clear the strobe.
;   In:        KEYBD ($E000) keyboard data/strobe (bit 7 set = key waiting); KEYSTB ($E010)
;              clear-strobe soft switch. [DOC S&HD 2-23]
;   Out:       Returns once a key has arrived, with the keyboard strobe acknowledged so the next
;              KEYBD read is fresh. A holds the post-rotate keyboard byte (high bit refolded by
;              CCF/RRA).
;   Clobbers:  A, flags.
;   Algorithm: Spin reading KEYBD and rotating bit 7 into carry until carry is set (a key is ready);
;              then write KEYSTB to clear the strobe (acknowledge the keypress), and CCF/RRA to
;              refold A's high bit after the wait loop's rotates. This is the Apple-keyboard
;              blocking wait, not the serial-input path. [DOC S&HD 2-23]
; ----------------------------------------------------------------------
KBD_WAIT_STROBE:
        ; poll the Apple keyboard latch (bit 7 = key ready) [DOC S&HD 2-23]
        LD A,(KEYBD)                     ; $AC2F  $E000 status
        RLA                              ; $AC32
        ; spin until a key is ready (bit 7 -> carry set)
        JR NC,KBD_WAIT_STROBE                  ; $AC33  spin until ready
        ; acknowledge the keypress by clearing the keyboard strobe so the next read is fresh [DOC
        ; S&HD 2-23]
        LD (KEYSTB),A                    ; $AC35  $E010 strobe / data
        ; refold A's high bit (undo the wait-loop rotates) via CCF/RRA
        CCF                              ; $AC38
        RRA                              ; $AC39
        RET                              ; $AC3A

; ----------------------------------------------------------------------
; SET_AVEC -- arm the SoftCard 6502 RPC call-address cell.
;   In:        HL = address of the 6502 subroutine to call (low-high), per the documented
;              arm-then-trigger protocol [DOC S&HD 2-24/2-25; apple_softcard.inc A_VEC]. (No
;              in-module caller; the HL contract is the documented A_VEC convention, not OBSERVED
;              here.) A = the byte stored to $0000 (source not traced in this cluster).
;   Out:       A_VEC ($F3D0) = HL (the 6502 target for the next RPC); CP/M base page $0000 also
;              written with A (purpose UNKNOWN). Does NOT trigger the call -- a later write to Z_CPU
;              ($F3DE) actually runs the 6502.
;   Clobbers:  A_VEC, page-zero $0000.
;   Algorithm: Store HL into A_VEC so the next SoftCard RPC trap dispatches to that 6502 routine
;              (set A_VEC, then trigger via Z_CPU). [DOC S&HD 2-24/2-25] OBSERVED: it also writes A
;              into base-page $0000; the source of A and the reason for touching $0000 here are
;              UNKNOWN (the byte-identical CPMV223-44K twin makes the same store and is equally
;              silent). [RE]
; ----------------------------------------------------------------------
SET_AVEC:
        ; store the 6502 subroutine address (low-high) into A_VEC so the next RPC trap (write to
        ; Z_CPU) calls it; this arms only, it does not trigger [DOC S&HD 2-25]
        LD (A_VEC),HL                    ; $AC3B  $F3D0 = 6502 sub address (low-high) [DOC S&HD 2-25]
        ; OBSERVED: also write A into CP/M base-page $0000; the source of A and the purpose of this
        ;           store are UNKNOWN [RE]
        LD ($0000),A                     ; $AC3E
        RET                              ; $AC41

; ============================================================================
; CONSOLE OUTPUT IOBYTE demux (CONOUT body)  ($AC42/$AC44)  -- [DOC sec 7.6]
; This is the CONOUT body (byte-identical to CPMV223-44K CONOUT_VECTOR $FC4C),
; NOT a LIST dispatch.  Saves the output char (LD C,A), reads IOBYTE ($0003),
; masks the CONSOLE field (AND $03), and on CONSOLE=2 (BAT:) routes console
; output to the List device by falling into List Output #1 ($AC4C) -- the
; standard CP/M behaviour of redirecting console output to LST: under BAT:.
; Otherwise it branches to the device-dispatch flag tail at $AC97.  $AC44 is the
; documented entry (from $AE41); $AC42 sets C first.  [DOC S&HD 7.6/2-18]
; ============================================================================
; ----------------------------------------------------------------------
; CONOUT_VECTOR -- BIOS CONOUT entry: emit a console char with IOBYTE redirection
;   In:        A = character to write to the console
;   Out:       BAT: path tail-jumps (JP (HL)) into List Output #1; the non-BAT path branches to the
;              shared IO_FLAG_FALSE flag/screen-fn tail (which ultimately dispatches via a
;              console-out vector or RETs after building disk-sector params -- this tail is a 2.20
;              merge of unrelated paths, see $AC96 block)
;   Clobbers:  A, C, HL (plus whatever the dispatched handler touches)
;   Algorithm: Saves the char in C (CONOUT_VECTOR), then falls into CONOUT_DISP which
;              reads the IOBYTE CONSOLE field. CONSOLE==2 (BAT:) redirects console output
;              to the LIST device by falling into LIST_VEC1 (standard CP/M BAT: behaviour);
;              otherwise it branches to the IO_FLAG_FALSE device-dispatch tail.
;   Note (OBSERVED): CONOUT_DISP (=CONOUT_VECTOR+1, $AC43) is a documented entry that
;              skips the LD C,A, using C as already set. SEPARATELY, LIST_REENTRY ($AE41)
;              jumps to CONOUT_DISP+1 ($AC44), which lands MID-INSTRUCTION inside
;              LD A,($0003): bytes $AC44/$AC45 ($03 $00) execute as INC BC / NOP, so that
;              re-entry skips the IOBYTE reload entirely and masks the caller's existing A
;              with AND $03 at $AC46. [RE] This is an intentional skip-into-the-middle
;              idiom, not a clean label entry -- do not describe LIST_REENTRY as entering
;              at CONOUT_DISP.
; ----------------------------------------------------------------------
CONOUT_VECTOR:
        ; ; save the output character in C; CONOUT_DISP ($AC43) is the re-entry that skips this when
        ; C already holds the char
        LD C,A                           ; $AC42  save output char
; ----------------------------------------------------------------------
; CONOUT_DISP -- IOBYTE CONSOLE-field demux for console output (BAT: -> LST:)
;   In:        C = character to output; A = IOBYTE-equivalent value (loaded here from $0003 on the
;              normal path); IOBYTE at $0003
;   Out:       JP (HL) into List Output #1 (when CONSOLE==2/BAT:) or branch to IO_FLAG_FALSE tail
;   Clobbers:  A, HL
;   Algorithm: Read the IOBYTE, isolate the CONSOLE field (AND 3). CONSOLE==2 (BAT:)
;              redirects console output to the LIST device: fall into LIST_VEC1 and jump
;              through List Output #1. Any other value (TTY:/CRT:/UC1:) branches to the
;              IO_FLAG_FALSE device-dispatch tail.
;   Note (OBSERVED): the LD A,($0003) here is also the byte that LIST_REENTRY re-enters
;              one past ($AC44, mid-instruction) to REUSE the caller's A instead of reloading
;              the IOBYTE -- so this LD A is bypassed on that re-entry path.
; ----------------------------------------------------------------------
CONOUT_DISP:
        ; ; load the CP/M IOBYTE (logical-to-physical device map) from $0003
        LD A,($0003)                     ; $AC43  IOBYTE
        ; ; keep only the CONSOLE field (bits 0-1): 0=TTY: 1=CRT: 2=BAT: 3=UC1:
        AND $03                          ; $AC46  CONSOLE field (bits 0-1)
        ; ; CONSOLE==2 means BAT:, which sends console output to the LIST device
        CP $02                           ; $AC48  ==2 => BAT: (output to LST:)
        ; ; not BAT: -> hand off to the console-output device-dispatch flag tail
        JR NZ,IO_FLAG_FALSE              ; $AC4A
; ----------------------------------------------------------------------
; LIST_VEC1 -- shared tail: jump through the List Output #1 vector
;   In:        List Output #1 vector cell (LIST1_VEC, $F392) holds the LPT: handler address; C =
;              char
;   Out:       JP (HL) into that handler (tail call); does not return here
;   Clobbers:  HL
;   Algorithm: Indirectly load the List Output #1 handler address from the I/O Vector
;              Table cell and jump to it. Reached from the CONSOLE==BAT: path (CONOUT_DISP)
;              and from the LIST==LPT: path (LIST_DEMUX_1, JR Z,LIST_VEC1).
; ----------------------------------------------------------------------
LIST_VEC1:
        ; ; fetch the List Output #1 (LPT:) handler address from the I/O Vector Table
        LD HL,(LIST1_VEC)                ; $AC4C  $F392  List Output #1
        ; ; tail-jump into the selected LIST handler
        JP (HL)                          ; $AC4F

; ============================================================================
; CONSOLE INPUT IOBYTE demux  ($AC50)  -- [DOC S&HD 7.6/2-18]
; Reads IOBYTE ($0003) and masks the CONSOLE field (bits 0-1): TTY:/CRT: (0/1)
; route via Console Input #1 ($F382); UC1: (3) via Console Input #2 ($F384);
; BAT: (2) takes input from the reader, via Reader Input #1 ($F38A).
; ============================================================================
; ----------------------------------------------------------------------
; CONIN_DISP -- IOBYTE CONSOLE-field demux for console input
;   In:        IOBYTE ($0003) CONSOLE field (bits 0-1)
;   Out:       JP (HL) into the selected console-input handler via CONIN_V1/V2/V2B; no return
;   Clobbers:  A, HL
;   Algorithm: Read the IOBYTE, isolate the CONSOLE field (AND 3). Speculatively preload
;              Console Input #2 (CONIN2_VEC, $F384) into HL, then dispatch by CP $02:
;              ==2 (BAT:) takes input from the reader via Reader Input #1 (CONIN_V2);
;              >2 i.e. 3 (UC1:) uses the preloaded Console Input #2 (CONIN_V2B);
;              <2 i.e. 0/1 (TTY:/CRT:) uses Console Input #1 (CONIN_V1).
; ----------------------------------------------------------------------
CONIN_DISP:
        ; ; load the CP/M IOBYTE from $0003
        LD A,($0003)                     ; $AC50  IOBYTE [DOC S&HD 2-18]
        ; ; isolate the CONSOLE field (bits 0-1): 0=TTY: 1=CRT: 2=BAT: 3=UC1:
        AND $03                          ; $AC53  CONSOLE field (bits 0-1) [DOC S&HD 2-18]
        ; ; classify the field: <2 = direct console, ==2 = BAT:(reader), >2 (==3) = UC1:
        CP $02                           ; $AC55  ==2 => BAT: (reader) [DOC S&HD 2-18]
        ; ; speculatively preload Console Input #2 ($F384) for the UC1: (field==3) case
        LD HL,(CONIN2_VEC)               ; $AC57  $F384 (UC1:)
        ; ; CONSOLE==2 (BAT:) -> take input from the reader (Reader Input #1)
        JR Z,CONIN_V2                    ; $AC5A
        ; ; CONSOLE==3 (UC1:) -> jump through the preloaded Console Input #2
        JR NC,CONIN_V2B                  ; $AC5C
; ----------------------------------------------------------------------
; CONIN_V1 -- shared tail: jump through Console Input #1 (TTY:/CRT:)
;   In:        Console Input #1 vector cell (CONIN1_VEC, $F382) holds the handler address
;   Out:       JP (HL) into that handler (tail call)
;   Clobbers:  HL
;   Algorithm: Load the Console Input #1 handler from the I/O Vector Table and jump to
;              it. Reached for CONSOLE 0/1 (CONIN_DISP fall-through) and for READER field 0/TTY:
;              (READER_DEMUX, JR C,CONIN_V1).
; ----------------------------------------------------------------------
CONIN_V1:
        ; ; fetch the Console Input #1 (TTY:/CRT:) handler address
        LD HL,(CONIN1_VEC)               ; $AC5E  $F382 (TTY:/CRT:)
        ; ; tail-jump into the console-input handler
        JP (HL)                          ; $AC61
; ----------------------------------------------------------------------
; CONIN_V2 -- shared tail: load Reader Input #1 then fall into CONIN_V2B to jump
;   In:        Reader Input #1 vector cell (RDR1_VEC, $F38A) holds the handler address
;   Out:       falls into CONIN_V2B which JP (HL)s into the handler
;   Clobbers:  HL
;   Algorithm: Load the Reader Input #1 handler into HL and fall through to CONIN_V2B's
;              JP (HL). Reached for CONSOLE==BAT: (CONIN_DISP, console input mapped to
;              the reader) and for READER field 1/PTR: (READER_DEMUX, JR Z,CONIN_V2).
; ----------------------------------------------------------------------
CONIN_V2:
        ; ; fetch the Reader Input #1 ($F38A) handler address (BAT: maps console input to the
        ; reader)
        LD HL,(RDR1_VEC)                 ; $AC62  $F38A (BAT: -> reader)
; ----------------------------------------------------------------------
; CONIN_V2B -- shared tail: jump through whatever input handler is in HL
;   In:        HL = selected input handler address (Console Input #2, Reader Input #1, or a Punch
;              vector)
;   Out:       JP (HL) into that handler (tail call)
;   Clobbers:  none beyond the dispatched handler
;   Algorithm: Single JP (HL). A common indirect-jump tail reused by CONIN_DISP (UC1:,
;              via JR NC), CONIN_V2 (reader, by fall-through), and PUN_DISP (punch vector
;              dispatch, via JR NZ,CONIN_V2B).
; ----------------------------------------------------------------------
CONIN_V2B:
        ; ; tail-jump into the preselected input/punch handler
        JP (HL)                          ; $AC65

; ============================================================================
; LIST OUTPUT IOBYTE demux  ($AC66)  -- [DOC sec 7.6]
; Masks the IOBYTE LIST field (bits 6-7): 0/1 (TTY:/CRT:) falls to the device-
; dispatch flag tail; ==2 (LPT:) routes to List Output #1 ($AC4C); ==3 (UL1:)
; uses List Output #2 ($F394).  Matches CPMV223-44K LIST_DEMUX ($FC70).
; $AC6B (the CP $80 alternate entry, reached by CURSOR_PUT at $AE4B) is
; LIST_DEMUX_1.  [DOC S&HD 7.6/2-18]
; ============================================================================
; ----------------------------------------------------------------------
; LIST_DEMUX -- BIOS LIST entry: IOBYTE LIST-field demux for list output
;   In:        C = character to list; IOBYTE ($0003) LIST field (bits 6-7)
;   Out:       JP (HL) into the selected list handler, or branch to IO_FLAG_TRUE tail; no return
;   Clobbers:  A, HL
;   Algorithm: Read the IOBYTE and isolate the LIST field (AND $C0), then fall into
;              LIST_DEMUX_1 to classify it. 0/1 (TTY:/CRT:) goes to the IO_FLAG_TRUE
;              device-dispatch tail; ==2 (LPT:) uses List Output #1 (LIST_VEC1); ==3 (UL1:)
;              uses List Output #2 (LIST2_VEC, $F394).
; ----------------------------------------------------------------------
LIST_DEMUX:
        ; ; load the CP/M IOBYTE from $0003
        LD A,($0003)                     ; $AC66  IOBYTE
        ; ; keep only the LIST field (bits 6-7): 0=TTY: 1=CRT: 2=LPT: 3=UL1:
        AND $C0                          ; $AC69  LIST field (bits 6-7)
; ----------------------------------------------------------------------
; LIST_DEMUX_1 -- LIST-field classifier / alternate entry (LIST field already in A bits 6-7)
;   In:        A = IOBYTE LIST field still in bits 6-7 ($00/$40/$80/$C0); C = char
;   Out:       JP (HL) into List Output #2, fall into LIST_VEC1 (List Output #1), or branch to
;              IO_FLAG_TRUE
;   Clobbers:  A, HL
;   Algorithm: Compare the masked LIST field against $80. <$80 (TTY:/CRT:) -> IO_FLAG_TRUE
;              device-dispatch tail; ==$80 (LPT:) -> LIST_VEC1 (List Output #1); >$80
;              (UL1:) -> List Output #2 (LIST2_VEC, $F394).
;   Note (OBSERVED/[RE]): CURSOR_PUT ($AE4B) reaches this label via CALL; because the
;              classifier ends in JP (HL)/JR tails rather than RET, [RE] this is the same
;              merged-tail reuse to route a character to the LIST device, not a normal call/return.
; ----------------------------------------------------------------------
LIST_DEMUX_1:
        ; ; split the LIST field: <$80 = direct (TTY:/CRT:), ==$80 = LPT:, >$80 = UL1:
        CP $80                           ; $AC6B
        ; ; LIST 0/1 (TTY:/CRT:) -> device-dispatch flag tail
        JR C,IO_FLAG_TRUE                ; $AC6D  <2 TTY:/CRT: tail
        ; ; LIST==2 (LPT:) -> jump through List Output #1
        JR Z,LIST_VEC1                   ; $AC6F  ==2 LPT: -> List Output #1 ($AC4C)
        ; ; LIST==3 (UL1:) -> fetch List Output #2 ($F394) handler
        LD HL,(LIST2_VEC)                ; $AC71  $F394  ==3 UL1: -> List Output #2
        ; ; tail-jump into List Output #2
        JP (HL)                          ; $AC74

; ============================================================================
; PUNCH OUTPUT IOBYTE demux  ($AC75)  -- [DOC S&HD 7.6/2-18]
; Masks the IOBYTE PUNCH field (bits 4-5): 0 (TTY:) falls to the device-dispatch
; flag tail; ==1 (PTP:) -> Punch Output #1 ($F38E); >=2 (UP1:/UP2:) -> Punch
; Output #2 ($F390).  Matches CPMV223-44K PUNCH_DEMUX ($FC7F).
; ============================================================================
; ----------------------------------------------------------------------
; PUN_DISP -- BIOS PUNCH entry: IOBYTE PUNCH-field demux for punch output
;   In:        C = character to punch; IOBYTE ($0003) PUNCH field (bits 4-5)
;   Out:       JP (HL) into the selected punch handler, or branch to IO_FLAG_TRUE tail; no return
;   Clobbers:  A, HL
;   Algorithm: Read the IOBYTE and isolate the PUNCH field (AND $30), then CP $10.
;              Field 0 (TTY:, $00) -> IO_FLAG_TRUE device-dispatch tail. Field 1/PTP: ($10)
;              -> Punch Output #2 (PUN2_VEC, $F390). Fields 2-3/UP1:,UP2: ($20/$30) ->
;              Punch Output #1 (PUN1_VEC, $F38E).
;   OBSERVED (verified against the assembled bytes): the equal case ($10) falls past the
;              JR NZ and lands on LD HL,(PUN2_VEC) -> JP (HL); the not-equal (>1) case takes
;              JR NZ,CONIN_V2B with PUN1_VEC still in HL. So value 1 selects PUN2 and values
;              >=2 select PUN1.
;   CORRECTION: the existing file HEADER COMMENT (lines ~369-371: "==1 (PTP:) -> Punch
;              Output #1 ($F38E); >=2 -> Punch Output #2 ($F390)") has these two mappings
;              REVERSED and must be fixed by the applier to match the bytes documented here.
; ----------------------------------------------------------------------
PUN_DISP:
        ; ; load the CP/M IOBYTE from $0003
        LD A,($0003)                     ; $AC75  IOBYTE [DOC S&HD 2-18]
        ; ; keep only the PUNCH field (bits 4-5): 0=TTY: 1=PTP: 2=UP1: 3=UP2:
        AND $30                          ; $AC78  PUNCH field (bits 4-5) [DOC S&HD 2-18]
        ; ; classify: ==0 (TTY:) below, ==$10 (PTP:) equal, >$10 (UP1:/UP2:) above
        CP $10                           ; $AC7A
        ; ; PUNCH==0 (TTY:) -> device-dispatch flag tail
        JR C,IO_FLAG_TRUE                ; $AC7C  ==0 TTY: tail
        ; ; preload Punch Output #1 ($F38E) for the >1 (UP1:/UP2:) case
        LD HL,(PUN1_VEC)                 ; $AC7E  $F38E
        ; ; PUNCH>1 (UP1:/UP2:) -> jump through Punch Output #1 via the shared JP (HL) tail
        JR NZ,CONIN_V2B                  ; $AC81
        ; ; PUNCH==1 (PTP:) falls through here -> Punch Output #2 ($F390)
        LD HL,(PUN2_VEC)                 ; $AC83  $F390
        ; ; tail-jump into Punch Output #2
        JP (HL)                          ; $AC86

; ============================================================================
; READER INPUT IOBYTE demux  ($AC87)  -- [DOC sec 7.6]
; Masks the IOBYTE READER field (bits 2-3): <2 (TTY:/CRT:) routes to Console
; Input #1 ($AC5E); ==2 (PTR:) routes to Reader Input #1 ($AC62); ==3 (UR2:)
; uses Reader Input #2 ($F38C).  Matches CPMV223-44K READER_DEMUX ($FC91).
; ============================================================================
; ----------------------------------------------------------------------
; READER_DEMUX -- BIOS READER entry: IOBYTE READER-field demux for reader input
;   In:        IOBYTE ($0003) READER field (bits 2-3)
;   Out:       JP (HL) into the selected input handler via the shared CONIN tails or Reader Input
;              #2; no return
;   Clobbers:  A, HL
;   Algorithm: Read the IOBYTE and isolate the READER field (AND $0C, leaving field value
;              x4 in A). CP $04. Field 0 (TTY:, $00) routes to Console Input #1 (CONIN_V1);
;              field 1 (PTR:, $04) routes to Reader Input #1 (CONIN_V2); fields 2-3
;              (UR1:/UR2:, $08/$0C) use Reader Input #2 (RDR2_VEC, $F38C). Reuses the
;              console-input shared tails for the first two cases.
; ----------------------------------------------------------------------
READER_DEMUX:
        ; ; load the CP/M IOBYTE from $0003
        LD A,($0003)                     ; $AC87  IOBYTE
        ; ; keep only the READER field (bits 2-3): 0=TTY: 1=PTR: 2=UR1: 3=UR2: (value x4)
        AND $0C                          ; $AC8A  READER field (bits 2-3)
        ; ; split on field value 1 ($04): below=TTY:, equal=PTR:, above=UR1:/UR2:
        CP $04                           ; $AC8C
        ; ; READER==0 (TTY:) -> route to Console Input #1
        JR C,CONIN_V1                    ; $AC8E  <2 TTY:/CRT: -> Console Input #1 ($AC5E)
        ; ; READER==1 (PTR:) -> route to Reader Input #1
        JR Z,CONIN_V2                    ; $AC90  ==2 PTR: -> Reader Input #1
        ; ; READER 2/3 (UR1:/UR2:) -> fetch Reader Input #2 ($F38C) handler
        LD HL,(RDR2_VEC)                 ; $AC92  $F38C  ==3 UR2: -> Reader Input #2
        ; ; tail-jump into Reader Input #2
        JP (HL)                          ; $AC95

; ============================================================================
; DEVICE-DISPATCH FLAG TAILS + DISK SECTOR PARAMETER BUILDER  ($AC96)
; ----------------------------------------------------------------------------
; $AC96/$AC97 are the device-dispatch flag tails (byte-identical to the
; CPMV223-44K IO_FLAG_TRUE/IO_FLAG_FALSE at $FCA0/$FCA1): the LIST/PUNCH demuxes
; above branch here for the TTY:/CRT: case.  IO_FLAG_TRUE sets carry; entering at
; IO_FLAG_FALSE (carry already clear from a preceding CP) leaves it clear; SBC A,A
; then expands carry to A=$FF or $00.
;
; Execution then falls into the disk sector wait+transfer parameter builder.
; This spine matches CPMV223-44K DISK_SECTOR_XFER/SECTOR_ADDR_XFER ($FCA4..) with
; the resident RWTS IOB target relocated from $FExx down to the BIOS-RAM cells at
; $AExx ($AEA2/$AEA3/$AEAA/$AEAB): it reads the signed skew sign from $F396, builds
; the two-byte 6502-side sector address, and pushes both halves to the disk engine
; with the RPC command codes LD B,$07 (address lo) and LD B,$0A (address hi).
; [DOC S&HD 3.2]  ($F396 is the skew-sign cell on this disk path, NOT a cursor XY
; offset.)  Unlike the 2.23 spine, the 2.20 image MERGES a software screen-function
; lead-in/table branch in at $ACE0 (SF_NORMAL, reached by the JR Z below); that tail
; falls through into the SF table search at $AE00.
; ============================================================================
; ----------------------------------------------------------------------
; IO_FLAG_TRUE -- enter the screen-function output engine asserting the B-register signal = TRUE.
;   In:        C = character being output; entered by the LIST/PUNCH IOBYTE demuxes on the
;              TTY:/CRT: case (JR C,IO_FLAG_TRUE from LIST_DEMUX_1 $AC6D / PUN_DISP $AC7C, both
;              reached with carry already set by the preceding CP).
;   Out:       carry set, then falls straight into IO_FLAG_FALSE so SBC A,A yields A=$FF.
;   Clobbers:  carry flag (then whatever IO_FLAG_FALSE touches).
;   Algorithm: SCF forces carry, then drops into the shared SBC A,A so the screen-fn signal
;              byte SF_SIGNAL becomes $FF (non-zero) for this character. [DOC S&HD page 2-19:
;              the B-register screen-fn signal is non-zero while emitting a screen function or
;              the Address-Cursor X/Y coordinates, zero during ordinary character output.]
; ----------------------------------------------------------------------
IO_FLAG_TRUE:
        ; ; set carry so the shared SBC A,A below builds the TRUE ($FF) screen-fn signal byte
        SCF                              ; $AC96
; ----------------------------------------------------------------------
; IO_FLAG_FALSE -- screen-function output dispatcher: latch the B-signal, then either recognise a
;                  new screen function or accumulate the next Address-Cursor coordinate byte.
;   In:        C = character to output; carry = the screen-fn B-signal; SF_STATE2 ($AEA3) =
;              coordinate-byte countdown (2 after Address-Cursor fired, else 0); SXYOFF ($F396) =
;              software cursor-address XY coordinate offset.
;   Out:       SF_SIGNAL ($AEA2) = $FF/$00 (from SBC A,A on the carry); char high bit cleared
;              (RES 7,C). When no coordinate transfer is in progress, branches to SF_NORMAL
;              (ordinary char / screen-fn lead-in recognition). While capturing coordinates it
;              decrements SF_STATE2 and, after the SECOND byte, tail-jumps to CURSOR_XMIT_PAIR to
;              transmit the finished X/Y pair; on the FIRST byte it applies the software offset and
;              stores one coordinate (at CURSOR_XY $AEAA), then RETs.
;   Clobbers:  A, E, HL, flags; memory SF_SIGNAL, SF_STATE2, CURSOR_XY.
;   Algorithm: expand the carry signal to A ($FF/$00) and store it as SF_SIGNAL; strip the char's
;              high bit. If SF_STATE2==0 there is no Address-Cursor sequence underway -> SF_NORMAL.
;              Otherwise decrement the countdown and read the SOFTWARE coordinate offset SXYOFF;
;              if the countdown reached 0 (this was the last/second byte) hand off to
;              CURSOR_XMIT_PAIR.
;              For the first byte, test the SXYOFF sign (high bit = transmit order, low 7 bits =
;              offset): positive -> DISK_XLAT_POS_SECTOR (runtime continuation); negative -> mask
;              to 0-127 and store C minus the offset as this coordinate byte. This is the resident
;              form of the manual's GOTOXY/cursor-address sequence. [DOC S&HD pages 2-14/2-16]
;   [RE]:      carry on entry is NOT always set/clear in a fixed way -- IO_FLAG_TRUE arrives with
;              carry SET; entry from CONOUT_DISP's JR NZ ($AC4A) inherits the CP $02 result, so
;              carry is SET for CONSOLE=TTY:/CRT: (IOBYTE 0/1) and CLEAR for UC1: (3). SF_SIGNAL
;              ($FF vs $00) follows that. The 0-vs-nonzero meaning is the screen-fn signal per
;              [DOC S&HD page 2-19].
; ----------------------------------------------------------------------
IO_FLAG_FALSE:
        ; ; expand the carry signal into A: $FF (screen-fn / coord output) or $00 (normal char) ->
        ; stored as SF_SIGNAL
        SBC A,A                          ; $AC97
        LD HL,SF_SIGNAL                  ; $AC98  $AEA2  (disk-path: relocated RWTS IOB cell)
        ; ; latch the screen-fn B-register signal byte (SF_SIGNAL) for SF_LK_DONE's console-out
        ; vector pick
        LD (HL),A                        ; $AC9B
        ; ; clear the char's Apple high bit so comparisons/coords use the 7-bit value
        RES 7,C                          ; $AC9C
        INC HL                           ; $AC9E  -> $AEA3
        ; ; read SF_STATE2, the Address-Cursor coordinate-byte countdown (2 after fn7 fired, else 0)
        LD A,(HL)                        ; $AC9F
        OR A                             ; $ACA0
        ; ; no coordinate transfer in progress -> ordinary char / screen-fn recognition (SF_NORMAL)
        JR Z,SF_NORMAL                   ; $ACA1  (2.20 merge: screen-fn lead-in branch)
        ; ; consume one coordinate byte; Z now set when this was the SECOND (final) coordinate
        DEC (HL)                         ; $ACA3
        ; ; [RE] read SXYOFF cursor-XY offset; sets no flags, so the next JR Z tests DEC
        ; (HL)/SF_STATE2
        ; ; read the SOFTWARE cursor-address XY coordinate offset (0-127; high bit = X-first vs
        ; Y-first order) [DOC S&HD page 2-14]
        LD A,(SXYOFF)                    ; $ACA4  $F396 signed skew sign cell
        LD HL,CURSOR_XY+1                      ; $ACA7  relocated RWTS IOB sector cell
        ; ; both coordinate bytes now captured -> transmit the finished X/Y pair (CURSOR_XMIT_PAIR)
        JR Z,CURSOR_XMIT_PAIR            ; $ACAA
        ; ; first coordinate byte: test the SXYOFF sign (high bit selects transmit order / negative
        ; branch)
        OR A                             ; $ACAC
        ; ; positive software offset -> runtime continuation that stores this coordinate with the
        ; positive-offset path
        JP P,DISK_XLAT_POS_SECTOR        ; $ACAD  ($ABB3, runtime) positive skew
        DEC HL                           ; $ACB0
        ; ; mask off the order bit to recover the 0-127 coordinate offset
        AND $7F                          ; $ACB1
        LD E,A                           ; $ACB3
        LD A,C                           ; $ACB4
        ; ; this coordinate = char value C minus the offset; store it as one byte of the X/Y pair
        ; (CURSOR_XY $AEAA)
        SUB E                            ; $ACB5
        LD (HL),A                        ; $ACB6
        RET                              ; $ACB7
; ----------------------------------------------------------------------
; CURSOR_XMIT_PAIR -- finish an Address-Cursor (GOTOXY) sequence: apply the software then hardware
;                     coordinate offset, build the X/Y pair, and transmit both bytes.
;   In:        A = the SOFTWARE offset SXYOFF (carried in from IO_FLAG_FALSE's LD A,(SXYOFF));
;              HL -> CURSOR_XY+1 ($AEAB); the two captured coordinate bytes live at CURSOR_XY
;              ($AEAA, X low) and CURSOR_XY+1 ($AEAB, Y high) from the IO_FLAG_FALSE accumulation
;              path; HXYOFF ($F3A1) = hardware cursor-address XY coordinate offset (0-127; high
;              bit = X/Y transmit order).
;   Out:       the two coordinate bytes are transmitted, the first with B=$07 and the second with
;              B=$0A (the screen-fn signal/command markers), through the runtime emit engine
;              (LIST_ENTRY_JP+1 / DISK_SECTOR_XFER).
;   Clobbers:  A, C, E, HL, flags.
;   Algorithm: resident form of the manual's GOTOXY tail [DOC S&HD page 2-16]. FIRST test the
;              SOFTWARE offset sign (the SXYOFF value still in A): negative -> DISK_XLAT_NEG_SECTOR
;              (runtime, extended/reverse case). Positive -> DEC HL to point at CURSOR_XY, CALL the
;              runtime sector/coord prep (DISK_RPC_PUSH_ADDR), then LD HL,(CURSOR_XY) to load both
;              coordinate bytes (L=X, H=Y). NOW read the HARDWARE offset HXYOFF and test ITS sign:
;              positive -> DISK_XLAT_SECTOR_HI (runtime) builds the hi component directly; negative
;              -> mask to 0-127, SWAP H and L (reverse the X/Y transmit order, mirroring the manual
;              NORVS step), then add the offset to each coordinate (LD E,A/ADD A,H -> C, LD A,E/
;              ADD A,L -> A). Fall into the emit tail to transmit low then high.
;   [RE]:      B=$07 / B=$0A are OBSERVED as the first/second coordinate emit markers; their exact
;              numeric meaning to the runtime emit handler (off this $500-byte image) is inferred
;              from the manual's 'B non-zero during Address-Cursor X/Y output' note [DOC S&HD page
;              2-19], not statically proven here. The routine reads BOTH offsets (software sign at
;              the top, hardware sign before the swap/add), so it is the hardware-translation form,
;              not a pure single-offset GOTOXY copy.
; ----------------------------------------------------------------------
CURSOR_XMIT_PAIR:
        ; ; test the SOFTWARE offset sign (SXYOFF still in A; negative -> the runtime
        ; reverse/extended case)
        OR A                             ; $ACB8
        JP M,DISK_XLAT_NEG_SECTOR        ; $ACB9  ($ABBD, runtime) negative case
        DEC HL                           ; $ACBC
        CALL DISK_RPC_PUSH_ADDR          ; $ACBD  ($ABB1, runtime)
        LD HL,(CURSOR_XY)                ; $ACC0  $AEAA  (disk-path: relocated sector-address word)
        ; ; [RE] read the hardware cursor-XY coordinate offset HXYOFF ($F3A1)
        ; ; read the HARDWARE cursor-address XY coordinate offset (0-127; high bit selects transmit
        ; order) [DOC S&HD page 2-14]
        LD A,(HXYOFF)                    ; $ACC3  $F3A1 hardware skew/offset cell
        OR A                             ; $ACC6
        ; ; hardware offset positive -> runtime continuation that builds the high coordinate
        ; component
        JP P,DISK_XLAT_SECTOR_HI         ; $ACC7  ($ABCF, runtime) build hi component
        AND $7F                          ; $ACCA
        ; ; hardware offset negative: swap H<->L to reverse the X-first / Y-first coordinate
        ; transmit order (manual NORVS)
        LD E,L                           ; $ACCC  swap lo/hi order
        LD L,H                           ; $ACCD
        LD H,E                           ; $ACCE
        LD E,A                           ; $ACCF
        ; ; add the hardware offset to the first coordinate (mirrors the manual GOTOXY 'ADD H' step)
        ADD A,H                          ; $ACD0
        LD C,A                           ; $ACD1
        LD A,E                           ; $ACD2
        ; ; add the hardware offset to the second coordinate (mirrors the manual GOTOXY 'ADD L'
        ; step)
        ADD A,L                          ; $ACD3
; ----------------------------------------------------------------------
; SF_SELECTOR_TBL -- DUAL USE. (a) As executed in line, the cursor-coordinate emit tail: transmit
;                    the assembled X/Y pair, low byte then high byte. (b) As referenced by
;                    SF_DISPATCH ($AE73), a putative low-byte selector-table base -- but those
;                    indexed reads land MID-INSTRUCTION inside this emit code, so the on-disk bytes
;                    do NOT form a clean handler table; the live dispatch form is generated into RAM
;                    [RE]/UNKNOWN per the $AE73 header. The label is kept (SF_DISPATCH references
;                    it).
;   In (emit path): A = low (first) coordinate byte (from CURSOR_XMIT_PAIR's ADD A,L); the high
;                    coordinate is recovered after the low byte is sent.
;   Out:       both coordinate bytes are emitted through the runtime console-out engine: the first
;              with B=$07, the second with B=$0A (the screen-fn signal/command markers). Does not
;              return here (JR DISK_SECTOR_XFER tail-emits the second byte).
;   Clobbers:  A, B, C, flags; stack (PUSH/POP AF).
;   Algorithm: save the low coordinate (PUSH AF), set B=$07 and CALL the runtime emit handler
;              (LIST_ENTRY_JP+1 = $AC2D) to send it; restore it (POP AF), set B=$0A, move it into
;              C, and JR into the runtime emit handler (DISK_SECTOR_XFER) to send the second byte.
;   [RE]:      B=$07/$0A are OBSERVED coordinate-emit markers (first/second); the runtime handler
;              that consumes them is off this image. The label name SF_SELECTOR_TBL is retained
;              unchanged because SF_DISPATCH ($AE73) reads SF_SELECTOR_TBL+B; renaming would require
;              rewriting that reference too, and the table interpretation is itself UNKNOWN.
; ----------------------------------------------------------------------
SF_SELECTOR_TBL:
        ; ; save the low coordinate byte while we transmit it
        PUSH AF                          ; $ACD4
        ; ; B = screen-fn signal/marker for the FIRST (low) coordinate byte
        LD B,$07                         ; $ACD5  RPC command: address lo
        ; ; emit the first (low) coordinate byte through the runtime console-out engine ($AC2D)
        CALL LIST_ENTRY_JP+1             ; $ACD7  ($AC2D) dispatch lo half to disk engine
        POP AF                           ; $ACDA
        ; ; B = screen-fn signal/marker for the SECOND (high) coordinate byte
        LD B,$0A                         ; $ACDB  RPC command: address hi
        LD C,A                           ; $ACDD
        ; ; tail-emit the second (high) coordinate byte via the runtime console-out engine
        JR DISK_SECTOR_XFER              ; $ACDE  ($AD2D, runtime) dispatch hi half
; ----------------------------------------------------------------------
; SF_NORMAL -- ordinary character output / screen-function recognition entry (no coordinate xfer).
;   In:        C = character being output (high bit already cleared); A = the SF_SIGNAL value just
;              stored; SF_STATE ($AEA4) = lead-in/multi-byte latch ($80 once a lead-in char has
;              been seen, else 0); SFLDIN ($F397) = software function lead-in character (0 = none).
;   Out:       if a screen-function sequence is already in progress (SF_STATE != 0) jumps to
;              SF_TABLE to look the char up; otherwise loads the software lead-in char and falls
;              into SF_INIT_TAIL to test whether this char arms a lead-in.
;   Clobbers:  A, B, E, HL, flags.
;   Algorithm: save A into B (the screen-fn signal travels in B per [DOC S&HD page 2-19]); read
;              SF_STATE into E (it becomes the XOR discriminator used later by SF_LOOKUP). If
;              SF_STATE is non-zero a screen-fn sequence is underway -> SF_TABLE. If zero, read the
;              software lead-in char SFLDIN and OR it to set flags, then fall into SF_INIT_TAIL.
;   [DOC S&HD page 2-14]: SFLDIN is the software function lead-in character; zero means no lead-in.
; ----------------------------------------------------------------------
SF_NORMAL:
        ; ; carry the screen-fn signal in B (B non-zero => screen function / coord output) [DOC S&HD
        ; page 2-19]
        LD B,A                           ; $ACE0
        LD HL,SF_STATE                   ; $ACE1  $AEA4
        ; ; read SF_STATE: the lead-in / multi-byte recognition latch ($80 = lead-in armed, 0 =
        ; idle)
        LD A,(HL)                        ; $ACE4
        ; ; keep SF_STATE in E as the XOR discriminator SF_LOOKUP folds into each table compare
        LD E,A                           ; $ACE5
        OR A                             ; $ACE6
        ; ; a screen-function sequence is already in progress -> search the function table
        ; (SF_TABLE)
        JR NZ,SF_TABLE                   ; $ACE7
        ; ; read the SOFTWARE function lead-in character (0 = no lead-in configured) [DOC S&HD page
        ; 2-14]
        LD A,(SFLDIN)                    ; $ACE9  $F397 software lead-in char [DOC S&HD 2-14]
        OR A                             ; $ACEC  zero => no lead-in [DOC S&HD 2-14]
; ----------------------------------------------------------------------
; SF_INIT_TAIL -- test the incoming char against the software lead-in and arm the lead-in latch.
;   In:        A = software lead-in char SFLDIN (flags set by the preceding OR A in SF_NORMAL);
;              C = incoming char; HL -> SF_STATE ($AEA4).
;   Out:       if this char IS the configured lead-in, sets SF_STATE = $80 (lead-in armed) and
;              RETs (the next char will be interpreted via the function table); otherwise falls
;              into SF_NOLEAD to handle it as an ordinary / single-control char.
;   Clobbers:  flags; memory SF_STATE on a match.
;   Algorithm: if SFLDIN is zero (no lead-in) -> SF_NOLEAD. Otherwise compare it to the incoming
;              char C; mismatch -> SF_NOLEAD; match -> store $80 into SF_STATE so the NEXT output
;              char is recognised as the lead-in's second byte, and RET (the lead-in itself is
;              swallowed, not emitted).
;   Note:      the entry point SF_INIT_TAIL+1 ($ACEE) is also CALLed at $AAB8 (a mid-instruction
;              cover entry, a separate use of these bytes). [RE]
;   [DOC S&HD page 2-14]: a single-char-plus-lead-in is one of the two supported screen-fn forms.
; ----------------------------------------------------------------------
SF_INIT_TAIL:
        ; ; SFLDIN == 0 means no lead-in configured -> treat the char as ordinary/control
        ; (SF_NOLEAD)
        JR Z,SF_NOLEAD                   ; $ACED
        ; ; does the incoming char match the configured lead-in character?
        CP C                             ; $ACEF
        ; ; not the lead-in -> handle as an ordinary/control char
        JR NZ,SF_NOLEAD                  ; $ACF0
        ; ; lead-in matched: arm SF_STATE=$80 so the NEXT char is looked up in the screen-fn table;
        ; swallow this one
        LD (HL),$80                      ; $ACF2
        RET                              ; $ACF4
; ----------------------------------------------------------------------
; SF_NOLEAD -- no lead-in pending: route printable chars to the emit engine, control chars to the
;              screen-function table search.
;   In:        C = incoming char (high bit cleared).
;   Out:       printable chars (> $1F) tail-jump to the runtime console-out emit engine
;              (DISK_SECTOR_XFER, $AD2D); control chars ($00-$1F) fall into SF_TABLE to be matched
;              as single-control-character screen functions.
;   Clobbers:  A, flags.
;   Algorithm: load $1F and CP C; if $1F < C (carry set, i.e. C is a printable char $20+) emit it
;              directly; otherwise (a control character $00-$1F) fall through into SF_TABLE to test
;              it against the screen-function table.
;   [DOC S&HD page 2-14]: the single-control-character form is the other supported screen-fn form.
; ----------------------------------------------------------------------
SF_NOLEAD:
        ; ; threshold: chars above $1F are printable, $00-$1F are control chars eligible as screen
        ; functions
        LD A,$1F                         ; $ACF5
        CP C                             ; $ACF7
        ; ; printable char ($20+) -> emit it directly through the runtime console-out engine
        JR C,DISK_SECTOR_XFER               ; $ACF8  ($AD2D) printable -> transfer/emit engine
; ----------------------------------------------------------------------
; SF_TABLE -- begin the screen-function table search for a control/lead-in char.
;   In:        C = char to match; E = SF_STATE discriminator (from SF_NORMAL).
;   Out:       HL = $F3A0 (one past the top of the SOFTWARE function table); B = 9 (function
;              count); A = the first table byte; falls into the runtime search loop (SF_LOOKUP
;              body re-entered via the generated SF_LK_STEP, which steps DOWNWARD with DEC HL).
;   Clobbers:  A, B, HL.
;   Algorithm: point HL at $F3A0 and load the function count (9) into B, then read the first entry
;              into A to prime the SF_LOOKUP compare. The recognition table is the SOFTWARE Screen
;              Function Table ($F398=fn1 .. $F39F=fn8/9): the SF_LK_SKIP loop walks DOWNWARD (DEC
;              HL, on-disk at $AE07), scanning the 9 software entries; on a hit SF_LK_HIT adds $0B
;              (11) to reach the parallel HARDWARE descriptor (the documented 11-byte gap between
;              the software and hardware tables). The XOR-E / CP-C match logic lives in SF_LOOKUP
;              ($AE00) and the runtime SF_LK_STEP loop head.
;   [DOC S&HD pages 2-14/2-15]: nine screen functions; recognition uses the SOFTWARE table (so the
;              routines work on the plain Apple 40-col screen). $F3A0 is a $F3xx hardware-config-
;              block address, left literal.
;   [RE]:      the exact walk start/length is inferred from the on-disk LD HL,$F3A0 / LD B,$09 /
;              DEC HL; the loop head SF_LK_STEP is generated into the $AD/$E5-fill window.
; ----------------------------------------------------------------------
SF_TABLE:
        ; ; HL = top of the SOFTWARE screen-fn table ($F398-$F39F); the loop DECs HL through the 9
        ; software entries [DOC S&HD pages 2-14/2-15]
        LD HL,$F3A0                      ; $ACFA  hardware screen-fn table base-1 ($F3A1 hdr/$F3A3 fn1) [DOC S&HD 2-14/2-15]
        ; ; nine supported screen functions to scan [DOC S&HD page 2-15]
        LD B,$09                         ; $ACFD  9 screen functions [DOC S&HD 2-15]
        ; ; prime the search with the first table entry; the SF_LOOKUP loop does XOR E / CP C per
        ; entry
        LD A,(HL)                        ; $ACFF
; --- $AD00..$ADFF : $E5 trap-fill (runtime-generated disk/console handlers) ---
        DEFS    45, $E5    ; $AD00  fill
DISK_SECTOR_XFER:
        DEFS    30, $E5    ; $AD2D  fill  (runtime) disk sector wait+transfer/emit engine
HOME_IMPL:
        DEFS    11, $E5    ; $AD4B  fill  (HOME handler)
SETTRK_IMPL:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD56  (SETTRK)
RPC_CALL_6502:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD5B
SERIAL_INIT:
        DEFS    13, $E5    ; $AD60  fill
SELDSK_IMPL:
        DEFS    28, $E5    ; $AD6D  fill  (SELDSK handler)
SETSEC_IMPL:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD89  (SETSEC)
SETDMA:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD8E  fill (SETDMA)
READ_IMPL:
        DEFS    16, $E5    ; $AD93  fill  (READ handler)
WRITE_IMPL:
        DEFS    92, $E5    ; $ADA3  fill  (WRITE handler + more)
SF_LK_STEP:
        DEFB    $E5                                              ; $ADFF

; ============================================================================
; SCREEN-FUNCTION TABLE LOOKUP  ($AE00) -- continuation of the SF processor.
; Searches the 9-entry hardware screen-function table for a match; on the
; "Address Cursor" function (#7) sets the multi-byte coordinate state.
; [DOC S&HD 2-14/2-15 ; facts sec.3.3/3.4] the nine screen functions are
; Clear Screen / Clear-to-EOP / Clear-to-EOL / Set Normal / Set Inverse / Home
; Cursor / Address Cursor (#7) / Cursor Up / Cursor Forward; function #7 is the
; one that then transmits the X/Y coordinates (offset cell $F3A1, lead-in $F3A2).
; ============================================================================
; ----------------------------------------------------------------------
; SF_LOOKUP -- screen-function table search: match the incoming console char against the
; screen-function table.
;   In:        A = current table byte under test; E = lead-in/state discriminator (from SF_STATE,
;              loaded by SF_NORMAL); C = incoming console char being output; HL -> current table
;              entry; B = remaining entries.
;   Out:       on a match, falls into SF_LK_HIT with HL at the matched entry; on a 0 entry or table
;              exhaustion, continues via SF_LK_SKIP -> SF_LK_DONE; A/flags consumed.
;   Clobbers:  A, flags (HL/B/C/E are walked by the loop and SF_LK_SKIP).
;   Algorithm: a table byte of 0 means 'function not implemented' (skip). Otherwise fold the state
;              discriminator in (table_byte XOR E) and compare to the incoming char C; equal => this
;              screen function fired (SF_LK_HIT). [RE] the XOR E lets the discriminator distinguish
;              the printable vs lead-in-armed cases. [DOC S&HD 2-14/2-15] entry==0 disables that
;              function.
; ----------------------------------------------------------------------
SF_LOOKUP:
        ; ; table entry == 0 means this screen function is not implemented -- skip it
        OR A                             ; $AE00
        JR Z,SF_LK_SKIP                  ; $AE01
        ; ; fold the lead-in/state discriminator into the entry, then test against the incoming char
        XOR E                            ; $AE03
        CP C                             ; $AE04
        ; ; match -> this screen function fired; go fetch its emit descriptor
        JR Z,SF_LK_HIT                   ; $AE05
; ----------------------------------------------------------------------
; SF_LK_SKIP -- advance the screen-function search to the next table entry (or finish).
;   In:        HL -> current table entry; B = entries remaining.
;   Out:       loops back via SF_LK_STEP ($ADFF, generated into RAM at boot) while B>0; when B
;              reaches 0 jumps to SF_LK_DONE (no match).
;   Clobbers:  HL (decremented), B (decremented).
;   Algorithm: step HL back one byte to the next candidate entry and DJNZ to the runtime loop head
;              SF_LK_STEP (which reloads the byte and re-enters SF_LOOKUP); on exhaustion fall
;              through to the no-match tail.
;   [RE] the exact table-walk direction depends on the runtime-generated SF_LK_STEP code in the
;   $AD/$E5-fill window, not present on disk.
; ----------------------------------------------------------------------
SF_LK_SKIP:
        ; ; step to the next table entry
        DEC HL                           ; $AE07
        ; ; more entries: re-enter the runtime loop head ($ADFF) which reloads the byte and re-tests
        ; in SF_LOOKUP
        DJNZ SF_LK_STEP                      ; $AE08
        ; ; table exhausted, no screen function matched -> emit the char normally
        JR SF_LK_DONE                    ; $AE0A
; ----------------------------------------------------------------------
; SF_LK_HIT -- a screen function matched: fetch its paired emit descriptor, optionally send a
; lead-in, and for Address-Cursor arm the coordinate-capture state.
;   In:        HL -> the matched table entry; B = the screen-function number; C = incoming char.
;   Out:       no-lead-in case (descriptor high bit clear) branches to the shared KBD_REDEF_HIT
;              tail; otherwise emits the hardware lead-in char, then for function 7 (Address Cursor)
;              sets SF_STATE2 = 2 so the next two chars are captured as X/Y coords; falls into
;              SF_LK_DONE.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: index +$0B (11) from the matched entry to the paired (hardware) descriptor byte [DOC
;              S&HD 2-14: the two parallel tables are 11 bytes apart]. High bit clear => no lead-in
;              -> shared tail. High bit set => mask it off to recover the emit char, push BC (B=fn#,
;              C=emit char), load the hardware lead-in char (HFLDIN/$F3A2) and B=$07 as the runtime
;              emitter's params and CALL it; then if B (the fn number) == 7 (Address Cursor) store 2
;              into SF_STATE2 so the following two bytes are taken as coordinates. [DOC S&HD
;              2-15/2-19]
; ----------------------------------------------------------------------
SF_LK_HIT:
        ; ; step from the matched entry to its paired emit descriptor (the two screen-function
        ; tables are 11 bytes apart) [DOC S&HD 2-14]
        LD DE,$000B                      ; $AE0C  index into table row
        ADD HL,DE                        ; $AE0F
        LD A,(HL)                        ; $AE10
        OR A                             ; $AE11
        LD C,A                           ; $AE12
        ; ; descriptor high bit clear => no lead-in needed; join the shared load-(HL)/return-if-zero
        ; tail
        JP P,KBD_REDEF_HIT               ; $AE13  high bit clear => no lead-in [DOC S&HD 2-14]
        ; ; high bit set => strip the lead-in flag to recover the emit char (the lead-in goes out
        ; first)
        AND $7F                          ; $AE16  high bit set => emit lead-in first [DOC S&HD 2-14]
        LD C,A                           ; $AE18
        PUSH BC                          ; $AE19
        ; ; emit the hardware function lead-in character ($F3A2) first
        LD A,(HFLDIN)                    ; $AE1A  $F3A2 hardware lead-in char [DOC S&HD 2-14]
        LD B,$07                         ; $AE1D
        CALL SF_EMIT_LEADIN                    ; $AE1F  (runtime) emit lead-in
        POP BC                           ; $AE22
        LD A,B                           ; $AE23
        ; ; was this screen function #7 (Address Cursor)? [DOC S&HD 2-15/2-19]
        CP $07                           ; $AE24  function 7 = Address Cursor ? [DOC S&HD 2-15/2-19]
        JR NZ,SF_LK_DONE                 ; $AE26
        ; ; fn7: arm coord-count state SF_STATE2 = 2 so the next two output chars are taken as X/Y
        ; coordinates [DOC S&HD 2-19]
        LD A,$02                         ; $AE28  fn7 -> transmit 2 coords (X/Y) next [DOC S&HD 2-19]
        LD (SF_STATE2),A                 ; $AE2A  $AEA3
; ----------------------------------------------------------------------
; SF_LK_DONE -- finish screen-function processing: clear the lead-in/multi-byte state, then emit the
; char through the Console Output vector selected by SF_SIGNAL.
;   In:        SF_SIGNAL ($AEA2) = the screen-fn signal byte (0 during normal char output, non-zero
;              during a screen function / coord output); C = char; HL/A as left by the caller path.
;   Out:       jumps (SF_EMIT) through Console Output #2 ($F388) when SF_SIGNAL==0, else Console
;              Output #1 ($F386).
;   Clobbers:  A, HL.
;   Algorithm: zero SF_STATE ($AEA4, the lead-in/multi-byte latch), read SF_SIGNAL to choose between
;              the two documented Console Output vectors, and tail-jump through it. [DOC S&HD
;              2-18/2-19] [RE] SF_SIGNAL is dual-purpose: this cell is also written by the disk-path
;              device-flag tail (IO_FLAG_FALSE), so the 0-vs-nonzero convention here is inferred.
; ----------------------------------------------------------------------
SF_LK_DONE:
        ; ; clear the lead-in / multi-byte state latch (SF_STATE)
        XOR A                            ; $AE2D
        LD (SF_STATE),A                  ; $AE2E  $AEA4 = 0
        ; ; read the screen-fn signal: 0 = normal char, non-zero = screen-fn / coord output [DOC
        ; S&HD 2-19] [RE]
        LD A,(SF_SIGNAL)                 ; $AE31  $AEA2  (B-reg screen-fn signal) [DOC S&HD 2-19]
        OR A                             ; $AE34
        ; ; signal 0 -> emit via Console Output #2 ($F388) [DOC S&HD 2-18]
        LD HL,(CONOUT2_VEC)              ; $AE35  $F388  Console Output #2 [DOC S&HD 2-18]
        JR Z,SF_EMIT                     ; $AE38
        ; ; signal non-zero -> emit via Console Output #1 ($F386) [DOC S&HD 2-18]
        LD HL,(CONOUT1_VEC)              ; $AE3A  $F386  Console Output #1 [DOC S&HD 2-18]
; ----------------------------------------------------------------------
; SF_EMIT -- tail-emit: jump through the Console Output vector chosen by SF_LK_DONE.
;   In:        HL = the selected Console Output vector contents (#1 $F386 or #2 $F388); C = char to
;              emit.
;   Out:       control transfers to the console-output driver; does not return here.
;   Clobbers:  none here (the target driver consumes C).
;   Algorithm: indirect JP (HL) into the configured console-output driver. [DOC S&HD 2-18]
; ----------------------------------------------------------------------
SF_EMIT:
        ; ; tail-call the configured console-output driver to emit the character
        JP (HL)                          ; $AE3D  emit char via console-out vector

; ----------------------------------------------------------------------
; LIST_REENTRY -- re-enter the CONOUT IOBYTE demux with DE preset to 3.
;   In:        the char already saved in C at the demux entry; the path needs DE=3 before
;              re-dispatching.
;   Out:       jumps to CONOUT_DISP+1 ($AC44, the CONOUT body entry that reads IOBYTE and routes).
;   Clobbers:  DE.
;   Algorithm: set DE=3 then re-enter the CONOUT demux body so the char is re-routed through the
;              IOBYTE CONSOLE-field dispatch. [DOC S&HD 7.6/2-18]
; ----------------------------------------------------------------------
LIST_REENTRY:
        LD DE,$0003                      ; $AE3E
        ; ; re-enter the CONOUT IOBYTE demux body ($AC44) to re-route the char [DOC S&HD 2-18]
        JP CONOUT_DISP+1                 ; $AE41  ($AC44)

; ============================================================================
; CURSOR-ADDRESS / WRAP HANDLER  ($AE44)
; Reads the saved cursor word ($AEA5) and column ($AEA7), computes the screen
; memory cell, wraps the high-video range, and writes the character.  [AI]
; ============================================================================
; ----------------------------------------------------------------------
; CURSOR_PUT -- restore the previously-saved screen cell, then read/highlight/cache the cell at the
; current cursor position.
;   In:        CUR_PTR ($AEA5) = pointer to the last screen cell touched; CUR_COL ($AEA7) = that
;              cell's saved original contents; Apple screen-base word at $F028, current column at
;              $F024.
;   Out:       the old cell is restored to its saved value; CUR_PTR/CUR_COL updated to the new cell
;              and its saved contents; the new cell rewritten with the cursor (normal-video) glyph.
;   Clobbers:  A, DE, HL (plus whatever the CALL LIST_DEMUX_1 at $AE4B touches -- UNKNOWN).
;   Algorithm: OBSERVED: write the saved char back to the old cursor cell (un-highlight); CALL
;              LIST_DEMUX_1 ($AC6B) -- purpose here UNKNOWN (a reused code fragment, not an obvious
;              cursor step); then compute the new cell = ($F028 screen-base word) + (DE = $F000 +
;              ($F024 column)), so the result lands in the $F0xx screen window; cache its current
;              contents in CUR_COL; if it is in the high-video range (>=$E0) XOR $20 to fold it,
;              then AND $3F / OR $40 to force a visible normal-video glyph (the cursor) and store.
;              [AI][RE] $F028/$F024 are the Apple screen-base/column cells; the CALL at $AE4B is
;              UNKNOWN.
; ----------------------------------------------------------------------
CURSOR_PUT:
        LD HL,(CUR_PTR)                  ; $AE44  $AEA5 screen cell pointer
        LD A,(CUR_COL)                   ; $AE47  $AEA7
        ; ; restore the saved character to the previous cursor cell (remove the old highlight)
        LD (HL),A                        ; $AE4A
        ; ; UNKNOWN: reuses the LIST_DEMUX_1 fragment ($AC6B); its effect within the cursor path is
        ; not understood [RE]
        CALL LIST_DEMUX_1                ; $AE4B  ($AC6B)
        ; ; new cell = Apple screen-base word + (DE below = $F000 + current column)
        LD HL,($F028)                    ; $AE4E  screen base
        LD A,($F024)                     ; $AE51  column
        LD E,A                           ; $AE54
        LD D,$F0                         ; $AE55
        ADD HL,DE                        ; $AE57
        ; ; remember the new cell pointer and cache its current contents in CUR_COL
        LD (CUR_PTR),HL                  ; $AE58  $AEA5
        LD A,(HL)                        ; $AE5B
        LD (CUR_COL),A                   ; $AE5C  $AEA7
        ; ; cell in the high-video range (>=$E0)? fold it (XOR $20) before applying the cursor
        CP $E0                           ; $AE5F
        JR C,CUR_NOFLIP                  ; $AE61
        XOR $20                          ; $AE63  fold high-video
; ----------------------------------------------------------------------
; CUR_NOFLIP -- apply the cursor highlight to the new cell and store.
;   In:        A = the new cell's contents (already high-video-folded if needed); HL -> the new
;              cell.
;   Out:       (HL) rewritten with the cursor glyph (normal-video bits set); RET.
;   Clobbers:  A.
;   Algorithm: mask to the low 6 bits (AND $3F) and OR $40 to force the normal-video character set,
;              then write it back so the cell shows the cursor. [AI]
; ----------------------------------------------------------------------
CUR_NOFLIP:
        AND $3F                          ; $AE65
        ; ; force normal-video bits so the cell renders as the visible cursor
        OR $40                           ; $AE67  set normal-video bits
        ; ; write the highlighted character back to the cursor cell
        LD (HL),A                        ; $AE69
        RET                              ; $AE6A

; ============================================================================
; SCREEN-FUNCTION EMIT / CR HANDLER  ($AE6B)
; B != 0 -> dispatch a screen function via the $ACD4 selector table.
; B == 0 -> ordinary char: handle CR ($0D) by zeroing the column ($F024),
;           else OR $80 (set high bit) and pass to the 6502 character poke.
; ============================================================================
; ----------------------------------------------------------------------
; SF_DISPATCH -- dispatch a screen function (B!=0) via an in-image selector table, or fall to
; ordinary char output (B==0).
;   In:        B = screen-function number (0 = ordinary char, else a screen function); C = char.
;   Out:       for a screen function, pushes RPC_DISPATCH as the return address, reads a low byte
;              from SF_SELECTOR_TBL+B (high byte stays $AC) and JP (HL) into the resulting $ACxx
;              address; for B==0 falls into CHAR_OUT.
;   Clobbers:  A, HL (and pushes the return vector).
;   Algorithm: if B==0 -> CHAR_OUT. Otherwise push the runtime return address, then
;              HL=SF_SELECTOR_TBL ($ACD4); ADD A,L / LD L,A indexes by B; LD L,(HL) fetches a low
;              byte; JP (HL) jumps to $AC<byte>. [RE]/UNKNOWN: the indexed reads for B=1..9 land
;              MID-INSTRUCTION ($AC06/$AC07/$ACCD/$ACAC/$ACF1/$AC06/$AC0A/$AC4F), so the on-disk
;              bytes at SF_SELECTOR_TBL do NOT form a clean table of handler entry points -- they
;              overlap the disk-sector-builder code at $ACD4 (the two paths are never simultaneously
;              live, and the live runtime form of this region is generated into RAM). The exact
;              dispatch targets are UNKNOWN from the on-disk image.
; ----------------------------------------------------------------------
SF_DISPATCH:
        LD A,B                           ; $AE6B
        OR A                             ; $AE6C
        ; ; B==0: this is an ordinary character, not a screen function
        JR Z,CHAR_OUT                    ; $AE6D
        ; ; push the runtime return address the dispatched handler returns to
        LD HL,RPC_DISPATCH                   ; $AE6F  (runtime) return address
        PUSH HL                          ; $AE72
        LD HL,SF_SELECTOR_TBL                      ; $AE73  selector base
        ADD A,L                          ; $AE76
        LD L,A                           ; $AE77
        ; ; index SF_SELECTOR_TBL by the screen-fn number to fetch a low byte (high byte stays $AC)
        ; [RE]: see header, on-disk bytes here overlap code
        LD L,(HL)                        ; $AE78
        JP (HL)                          ; $AE79
; ----------------------------------------------------------------------
; CHAR_OUT -- ordinary (non-screen-function) character output: special-case carriage return.
;   In:        C = char to output; B == 0.
;   Out:       on CR ($0D) zeroes the screen column ($F024) and returns; otherwise falls into
;              CHAR_OUT_HI.
;   Clobbers:  A.
;   Algorithm: load the char; if it is a carriage return, reset the current column to 0 ($F024) and
;              return; any other char continues to the high-bit / poke path. [AI]
; ----------------------------------------------------------------------
CHAR_OUT:
        LD A,C                           ; $AE7A
        ; ; carriage return? reset the cursor to column 0 and return
        CP $0D                           ; $AE7B  carriage return ?
        JR NZ,CHAR_OUT_HI                ; $AE7D
        XOR A                            ; $AE7F
        ; ; CR: set the current screen column ($F024) back to 0
        LD ($F024),A                     ; $AE80  column = 0
        RET                              ; $AE83
; ----------------------------------------------------------------------
; CHAR_OUT_HI -- set the Apple high bit on a printable char and fold the high-video range before
; poking.
;   In:        A = char to display.
;   Out:       falls into CHAR_POKE with A = the screen byte to write (Apple high-bit-set form,
;              optionally XOR'd with the config flag at $F3DD).
;   Clobbers:  A, HL.
;   Algorithm: set bit 7 (Apple text uses high-bit-set glyphs); if the result lands in the
;              high-video range (>=$E0), XOR it with the config/video-mode flag at $F3DD to apply
;              the current mode. [AI][RE] $F3DD is a config/video-mode flag cell.
; ----------------------------------------------------------------------
CHAR_OUT_HI:
        ; ; set the Apple text high bit (high-bit-set glyph)
        OR $80                           ; $AE84  set high bit (Apple text)
        CP $E0                           ; $AE86
        JR C,CHAR_POKE                   ; $AE88
        LD HL,$F3DD                      ; $AE8A  config flag
        ; ; high-video range: apply the current video-mode/config flag at $F3DD
        XOR (HL)                         ; $AE8D
; ----------------------------------------------------------------------
; CHAR_POKE -- hand the prepared screen byte to the 6502 and emit it via Apple Monitor COUT1 over
; the RPC trampoline.
;   In:        A = the screen byte to display.
;   Out:       stores A into the 6502 A-register pass cell ($F045/RPC_ACC) and jumps to the
;              off-image 6502 RPC trampoline ($AF0F, the next BIOS chunk) with the Apple Monitor
;              COUT1 entry ($FDF0) in HL.
;   Clobbers:  A, HL.
;   Algorithm: write the char into the RPC A pass cell, load the Apple Monitor COUT1 entry ($FDF0)
;              as the 6502 call target, and JR to the trampoline. [DOC S&HD 2-24/2-25] RPC_ACC is
;              the 6502 A pass cell. [RE] $FDF0 is the Apple Monitor character-out routine
;              (off-image ROM, not S&HD-documented); $AF0F is past this $500-byte image, in the
;              following chunk.
; ----------------------------------------------------------------------
CHAR_POKE:
        ; ; pass the display byte to the 6502 in the A-register RPC cell ($F045) [DOC S&HD 2-24]
        LD (RPC_ACC),A                     ; $AE8E  $F045 = char for 6502
        LD HL,$FDF0                      ; $AE91  Apple Monitor COUT1
        ; ; tail to the 6502 RPC trampoline (off-image, next BIOS chunk) to run Apple Monitor COUT1
        ; ($FDF0)
        JR $AF0F                         ; $AE94  -> 6502 RPC trampoline (off-image)

; ----------------------------------------------------------------------
; FORCE_FLAG -- set the Apple inverse/flash mask ($F032/INVFLG) and pop the caller's extra frame.
;   In:        none (FORCE_FLAG entry); an alternate entry at $AE99 is reachable via the skip idiom.
;   Out:       $F032 (INVFLG) = $FF (FORCE_FLAG entry) or $3F (alt entry $AE99); one word popped off
;              the stack into HL; RET.
;   Clobbers:  A, BC, HL.
;   Algorithm: load $FF and store it to the Apple inverse/flash mask cell. LD BC,$3F3E is the Z-80
;              skip idiom: its operand bytes $3E $3F are the alternate two-byte instruction LD A,$3F
;              at $AE99, swallowed when entered at FORCE_FLAG so both entries converge on the store.
;              POP HL discards the extra return address before RET. [RE] $F032 is the Apple COUT
;              inverse/flash mask (INVFLG).
; ----------------------------------------------------------------------
FORCE_FLAG:
        LD A,$FF                         ; $AE96
        ; ; skip idiom: the operand bytes $3E $3F are the alt-entry LD A,$3F at $AE99, swallowed
        ; when entered here
        LD BC,$3F3E                      ; $AE98  (skip idiom: swallows $3E $3F)
        ; ; store the inverse/flash mask (INVFLG): $FF via the FORCE_FLAG entry, $3F via the
        ; swallowed alt-entry
        LD ($F032),A                     ; $AE9B
        ; ; discard the extra return frame before returning to the real caller
        POP HL                           ; $AE9E
        RET                              ; $AE9F

; ----------------------------------------------------------------------------
; OVERLAP: the bytes $AEA0-$AEA3 form "LD HL,$FBF4 / RET" but $AEA2/$AEA3 are
; ALSO BIOS RAM variables (read/written by code above).  The two leading bytes
; $21 $F4 are shown as data so the variable labels land on the right addresses.
; ----------------------------------------------------------------------------
        DEFB    $21,$F4                                          ; $AEA0  (LD HL,$FBF4 fragment)
; ---- BIOS RAM variables -- initial on-disk values --------------------------
SF_SIGNAL:                               ; $AEA2  B-reg screen-fn signal (init $FB)
        DEFB    $FB
SF_STATE2:                               ; $AEA3  coord-count state (init $C9)
        DEFB    $C9
SF_STATE:                                ; $AEA4  lead-in / multi-byte state (init $AF)
        DEFB    $AF
CUR_PTR:                                 ; $AEA5  screen cell pointer (init $676F)
        DEFB    $6F,$67
CUR_COL:                                 ; $AEA7  saved cell contents (init $22)
        DEFB    $22

; ============================================================================
; COLD BOOT  ($AEA8)  -- jump-table entry 0.
; Stores into the 6502 A-register pass cell ($F045) and loads an Apple Monitor
; routine pointer ($FBC1), priming a 6502 RPC.  ($AEAA is also the CURSOR_XY
; word read at $ACC0.)  [AI]
; ============================================================================
; ----------------------------------------------------------------------
; COLD_BOOT -- BIOS jump-table entry 0 (cold start) lands here; the two bytes also overlap the
; CURSOR_XY data word.
;   In:        A = byte staged into the 6502 A-register pass cell by the RPC primer below.
;   Out:       RPC_ACC ($F045) = A; HL = $FBC1 (BASCAL2, Apple Monitor BASCALC inner entry).
;   Clobbers:  A, HL, flags.
;   Algorithm: The BIOS BOOT vector (JP COLD_BOOT) points at $AEA8 = 'INC H; RET P'.
;              Execution then reaches the RPC primer at $AEAA which stages A into the 6502
;              A pass cell and loads HL with the BASCAL2 pointer for the caller to fire a
;              SoftCard RPC.  The two-byte cell at $AEAA ($4532) is ALSO the cursor X/Y word
;              (CURSOR_XY) read by CURSOR_CLAMP and the disk sector-parameter path, so these
;              bytes deliberately serve as both code and a BIOS variable.
;   UNKNOWN:   the semantic role of 'INC H; RET P' as cold-start logic is not determinable
;              statically (H on entry is unknown, and the real cold-boot work appears to live
;              off this $500-byte image).  OBSERVED: the BOOT vector targets these bytes and
;              they double as the CURSOR_XY word; the rest is [RE].
; ----------------------------------------------------------------------
COLD_BOOT:
        ; ; [?] BOOT-vector lands here; these two bytes also begin the CURSOR_XY cell / RPC primer
        ; below
        INC H                            ; $AEA8
        RET P                            ; $AEA9
; ----------------------------------------------------------------------
; CURSOR_XY -- 6502 A-cell RPC primer whose address word doubles as the cursor X/Y cell.
;   In:        A = value for the 6502 A-register pass cell.
;   Out:       RPC_ACC ($F045) = A; HL = $FBC1 (BASCAL2, Apple Monitor BASCALC inner entry).
;   Clobbers:  HL, flags.
;   Algorithm: Stage A into the 6502 A pass cell, load HL with the BASCAL2 ROM entry, and
;              RET so the caller can fire the SoftCard RPC.  The label CURSOR_XY names the
;              word at $AEAA/$AEAB ($4532; X=low $32, Y=high $45) read as the cursor X/Y
;              coordinate by CURSOR_CLAMP and by the disk sector-address builder; here those
;              same bytes encode 'LD ($F045),A'.  OBSERVED dual code/data use, not a bug.
;   [RE] the BASCAL2 target as a screen-line-base RPC; OBSERVED the staged A + $FBC1 pointer.
; ----------------------------------------------------------------------
CURSOR_XY:                               ; $AEAA  cursor X/Y word (overlaps code)
        ; ; stage A into the 6502 A-register pass cell for the RPC
        LD (RPC_ACC),A                     ; $AEAA  $F045
        ; ; HL = $FBC1 = BASCAL2 (Apple Monitor BASCALC inner entry); caller arms this as the 6502
        ; RPC target
        LD HL,$FBC1                      ; $AEAD  Apple Monitor routine
        RET                              ; $AEB0

; ============================================================================
; HL-POINTER SELECTOR  ($AEB1)  -- Z-80 "LD BC,nn skip" idiom.
; Four entry points ($AEB1/$AEB4/$AEB7/$AEBA) each load L with a distinct low
; byte and fall through (skipping the next LD-L via the $01 LD BC,nn opcode) to
; LD H,$FC; RET, returning HL = $FCxx.  $AEBA is also the device-table handler
; (referenced by every DEVTAB record).  $AEB4 is the CURMODE selector byte
; cleared by WBOOT.
; ============================================================================
; ----------------------------------------------------------------------
; PTRSEL_42 -- HL-pointer selector, entry #1 of 4 (Z-80 'LD BC,nn skip' idiom).
;   In:        none -- entered by a direct CALL/JP to one of the four fall-through points.
;   Out:       HL = $FC42; H always becomes $FC, L = the called entry's low byte.
;   Clobbers:  HL, BC (clobbered by the swallowed 'LD L' immediates), flags.
;   Algorithm: Four entry points ($AEB1/$AEB4/$AEB7/$AEBA) each begin with 'LD L,low'; the
;              following $01 (LD BC,nn) opcode SWALLOWS the next entry's 'LD L,low' as its
;              16-bit immediate, so control falls straight through to 'LD H,$FC; RET'.
;              Whichever entry is called sets L; the result is HL = $FCxx into the runtime
;              $FCxx handler table.  This entry yields $FC42.  (BC is not a meaningful output.)
; ----------------------------------------------------------------------
PTRSEL_42:
        ; ; entry #1: L=$42 -> HL=$FC42; falls through (next LD L is swallowed by the $01 LD BC
        ; opcode)
        LD L,$42                         ; $AEB1  -> $FC42
; ----------------------------------------------------------------------
; CURMODE_INSTR -- HL-pointer selector entry #2; its 'LD L' operand byte at $AEB4 is the CURMODE
; var.
;   In:        none -- a direct entry into the selector chain at $AEB4.
;   Out:       HL = $FC followed by the CURMODE byte at $AEB4 ($9C on disk -> $FC9C; after
;              WBOOT zeroes CURMODE it is $00 -> $FC00).
;   Clobbers:  HL, BC, flags.
;   Algorithm: As an instruction this is 'LD BC,$9C2E', the skip-idiom no-op that swallows
;              the prior entry's 'LD L,$42' bytes.  As the entry at $AEB4 it runs 'LD L,CURMODE'.
;              WBOOT writes 0 to CURMODE ($AEB4, OBSERVED at line 178), switching the
;              entry-$AEB4 result from $FC9C to $FC00.  So this address is simultaneously a
;              fall-through selector entry and the storage of the CURMODE config byte.
; ----------------------------------------------------------------------
CURMODE_INSTR:
        ; ; skip-idiom no-op as code; the entry at $AEB4 instead runs 'LD L,CURMODE' ($9C on disk, 0
        ; after WBOOT) -> HL=$FC9C/$FC00
        LD BC,$9C2E                      ; $AEB3  CURMODE = $AEB4 (entry: LD L,$9C -> $FC9C)
        ; ; skip-idiom; the entry at $AEB7 instead runs 'LD L,$1A' -> HL=$FC1A
        LD BC,$1A2E                      ; $AEB6  (entry $AEB7: LD L,$1A -> $FC1A)
; ----------------------------------------------------------------------
; PTRSEL_58 -- HL-pointer selector entry #4; also the per-card console handler in every DEVTAB
; record.
;   In:        none -- direct entry at $AEBA; referenced by every DEVTAB record's handler field
;              ($BA,$AE).
;   Out:       HL = $FC58 into the runtime $FCxx handler table.
;   Clobbers:  HL, BC, flags.
;   Algorithm: Last entry of the selector chain: 'LD L,$58', fall through to 'LD H,$FC; RET'
;              yielding HL = $FC58.  Each device-driver descriptor record (DEVTAB, $AA3B+)
;              carries $AEBA in its handler field, so selecting a console card lands here.
;   OBSERVED: DEVTAB records at $AA4B/$AA55/... lead with $BA,$AE,$93 (handler = $AEBA).
; ----------------------------------------------------------------------
PTRSEL_58:
        ; ; skip-idiom; the entry at $AEBA instead runs 'LD L,$58' -> HL=$FC58 (the DEVTAB console
        ; handler)
        LD BC,$582E                      ; $AEB9  (entry $AEBA: LD L,$58 -> $FC58)
        ; ; common tail for all four entries: H=$FC, so HL = $FC<selected low byte>
        LD H,$FC                         ; $AEBC
        RET                              ; $AEBE

; ============================================================================
; CURSOR CLAMP  ($AEBF)  -- clamp cursor X/Y to the 40x24 Apple screen.
; If X (L) >= 40 ($28) set X=0; if Y (H) >= 24 ($18) set Y=0; store to $F024.
; ============================================================================
; ----------------------------------------------------------------------
; CURSOR_CLAMP -- clamp the cursor X/Y coordinate to the 40x24 Apple text screen.
;   In:        CURSOR_XY ($AEAA) = packed coordinate word, L = column (X), H = row (Y).
;   Out:       $F024 (Apple zero-page cursor column/row pair) = clamped {X,Y}; falls through
;              to CURSOR_XY ($AEAA) to re-prime the 6502 A-cell / BASCAL2 RPC.
;   Clobbers:  A, HL, flags.
;   Algorithm: Load the saved coordinate word; if X (L) >= 40 ($28) force X=0; if Y (H) >= 24
;              ($18) force Y=0; store the clamped pair to $F024, then tail-jump into CURSOR_XY
;              to issue the BASCAL2 RPC for the new position.
; ----------------------------------------------------------------------
CURSOR_CLAMP:
        ; ; load the saved cursor coordinate word (L = column/X, H = row/Y)
        LD HL,(CURSOR_XY)                ; $AEBF  $AEAA
        LD A,L                           ; $AEC2  X
        ; ; X past the 40-column right edge? clamp to column 0 if so
        CP $28                           ; $AEC3  >= 40 ?
        JR C,CLAMP_Y                     ; $AEC5
        LD L,$00                         ; $AEC7
; ----------------------------------------------------------------------
; CLAMP_Y -- second half of the cursor clamp: bound the row (Y).
;   In:        H = row (Y); L already X-clamped by CURSOR_CLAMP.
;   Out:       H = 0 if it was >= 24, else unchanged; falls into CLAMP_STORE.
;   Clobbers:  A, H, flags.
;   Algorithm: Compare row against 24 ($18, the Apple text-screen height); if at or past the
;              bottom edge force Y=0, then fall through to store the clamped pair.
; ----------------------------------------------------------------------
CLAMP_Y:
        LD A,H                           ; $AEC9  Y
        ; ; Y past the 24-row bottom edge? clamp to row 0 if so
        CP $18                           ; $AECA  >= 24 ?
        JR C,CLAMP_STORE                 ; $AECC
        LD H,$00                         ; $AECE
; ----------------------------------------------------------------------
; CLAMP_STORE -- write the clamped X/Y pair and re-prime the cursor RPC.
;   In:        HL = clamped {X (L), Y (H)} coordinate pair.
;   Out:       $F024 (Apple cursor column/row cell) = HL; tail-jumps to CURSOR_XY.
;   Clobbers:  memory $F024, plus whatever CURSOR_XY clobbers (HL, flags).
;   Algorithm: Store the clamped coordinate word into the Apple zero-page cursor cell, then
;              jump to CURSOR_XY to stage the 6502 A pass cell and the BASCAL2 pointer for the
;              screen-line recompute RPC.
; ----------------------------------------------------------------------
CLAMP_STORE:
        ; ; commit the clamped {X,Y} to the Apple cursor column/row cell ($F024 = Apple $24)
        LD ($F024),HL                    ; $AED0
        ; ; re-prime the BASCAL2 RPC for the new cursor position
        JR CURSOR_XY                     ; $AED3  ($AEAA)

; ----------------------------------------------------------------------
; SF_XLAT -- 10-byte data table of single low bytes pointing at page-$AE handlers ($AED5).
;   Layout:    Ten bytes, each (OBSERVED) the LOW byte of a routine/cell in page $AE:
;                $BA=PTRSEL_58($AEBA)  $B1=PTRSEL_42($AEB1)  $B4=CURMODE($AEB4)
;                $96=FORCE_FLAG($AE96) $99=$AE99            $A4=SF_STATE($AEA4)
;                $9E=$AE9E             $B7=$AEB7(PTRSEL '$1A' entry)  $A0=$AEA0 
;                $BF=CURSOR_CLAMP($AEBF)
;   Note:      Pure data (never executed inline).  Each byte's TARGET points into this module's
;              own image (page $AE), so the table is conceptually relocatable; it is left as raw
;              DEFB because the entries are single LOW bytes (no DEFW slot to hold a full label).
;              The per-entry target labels are documented so the relocation stays traceable.
;   [RE]/UNKNOWN: the assumption that a caller indexes this with H=$AE and JP (HL) is INFERRED
;              from the analogous low-byte table at $ACD4 used by the $AE73 selector; no consumer
;              of $AED5 exists in this image, so the dispatch and its index arithmetic are UNKNOWN.
; ----------------------------------------------------------------------
SF_XLAT:
        ; ; [RE] low bytes of page-$AE handlers/cells:
        ; PTRSEL_58,PTRSEL_42,CURMODE,FORCE_FLAG,$AE99,SF_STATE,$AE9E,$AEB7,$AEA0,CURSOR_CLAMP
        ; (consumer off-image)
        DEFB    $BA,$B1,$B4,$96,$99,$A4,$9E,$B7,$A0,$BF          ; $AED5

; ============================================================================
; WAIT-AND-POKE HELPER  ($AEDF)
; CALL the (runtime) routine at $AD60, then spin until status bit 1 is set,
; advance L, and store C.  [AI]
; ============================================================================
; ----------------------------------------------------------------------
; WAIT_POKE -- (re)init a card/port, then wait for its ready bit and write one byte.
;   In:        HL -> a card status/data cell pair (status at (HL), data at (HL)+1);
;              C = byte to deposit once the device signals ready.
;   Out:       C written to (HL)+1 after the status ready bit (b1) is set.
;   Clobbers:  A, L (incremented by 1 to reach the data register), flags.
;   Algorithm: Call the (runtime-generated) card-init helper SERIAL_INIT ($AD60), then poll
;              the status byte at (HL) until bit 1 (device ready / buffer-empty) is set, do
;              'INC L' to point at the data register in the same page, and store C.
;   ASSUMPTION: SERIAL_INIT is $E5 trap-fill (generated at boot), so its preservation of HL/C
;              is assumed, not statically proven.
; ----------------------------------------------------------------------
WAIT_POKE:
        ; ; (runtime-generated) (re)initialise the target card/port before the handshaked write
        CALL SERIAL_INIT                      ; $AEDF
; ----------------------------------------------------------------------
; WAIT_POKE_LP -- the busy-wait loop body of WAIT_POKE.
;   In:        HL -> status cell; C = byte to write.
;   Out:       C written to (HL)+1; returns when complete.
;   Clobbers:  A, L, flags.
;   Algorithm: Read status, mask the ready bit (b1); loop while clear; once set, 'INC L' to
;              reach the data register (same page) and deposit C.
; ----------------------------------------------------------------------
WAIT_POKE_LP:
        LD A,(HL)                        ; $AEE2
        ; ; isolate the device ready / buffer-empty bit (b1)
        AND $02                          ; $AEE3
        ; ; spin until the device signals ready
        JR Z,WAIT_POKE_LP                ; $AEE5
        INC L                            ; $AEE7
        ; ; deposit the data byte into the device's data register ((HL) after INC L = status cell +
        ; 1)
        LD (HL),C                        ; $AEE8
        RET                              ; $AEE9

; ============================================================================
; 6502 SUBROUTINE-CALL SETUP  ($AEEA)  -- [DOC S&HD 2-24/2-25 ; facts sec.4.1]
; Loads the 6502 A ($F045) and X ($F047) RPC register-pass cells, runs the
; (runtime) call helper, reads an input column ($EFFF / 6502 $C7FF view), and
; converts.  Per the RPC parameter-cell map, $F045/6502-$45 is the A pass area
; and $F047/6502-$47 is the X pass area ($F046 is Y -- Y before X).
; The final $32 opcode (LD (nn),A) continues in the next BIOS chunk.
; ============================================================================
; ----------------------------------------------------------------------
; RPC_SETUP -- stage the 6502 register-pass cells, fire a SoftCard RPC, then build slot I/O params.
;   In:        C = the 6502 A-register argument; E = slot number (consumed below via SLOT_TO_EN).
;   Out:       RPC_ACC ($F045) = C; the SoftCard RPC (RPC_CALL_6502) is executed; the returned A
;              is saved to $F6F8 and to RPC_YREG ($F047 = 6502 Y pass cell); A is then reloaded
;              from $EFFF (deselect side-effect, value discarded), the slot I/O high byte $EN is
;              formed via SLOT_TO_EN, $20 is subtracted, and the result is stored to RPC_XREG
;              ($F046) by the LD (nn),A whose $32 opcode is the last byte of this image.
;   Clobbers:  A, HL, flags, and 6502 RPC pass cells $F045/$F047/$F046, plus $F6F8.
;   Algorithm: Stage C into the 6502 A pass cell, fire the SoftCard RPC, save its A result to
;              $F6F8 and the Y pass cell, read $EFFF (Apple $CFFF = deselect all slot expansion
;              ROMs; value discarded), form the slot I/O base high byte $EN from E (SLOT_TO_EN
;              returns A=$EN, HL=$EN00), subtract $20, and store $EN-$20 into the X pass cell.
;              The byte-identical CPMV223-60K BIOS carries this SAME tail body as INIT_PASCAL_1_0
;              ($FD83+), which ends 'LD ($F046),A / LD A,(HL) / RET' -- so this routine genuinely
;              continues past $AEFF into the next BIOS chunk.
;   Note:      $F047 = RPC_YREG (6502 Y) and $F046 = RPC_XREG (6502 X) per apple_softcard.inc
;              (the S&HD table mislabels $46/$47; the include corrects it via the GBASIC HLINE
;              Y-via-$F047 evidence).
;   [DOC S&HD 2-24/2-25] RPC register-pass cells.  [RE]/UNKNOWN the device-class purpose (the 60K
;   analogue sits in the Pascal/device init dispatch) -- OBSERVED the code, INFERRED the role.
; ----------------------------------------------------------------------
RPC_SETUP:
        ; ; the 6502 A-register argument for this RPC
        LD A,C                           ; $AEEA
        LD (RPC_ACC),A                     ; $AEEB  $F045 = 6502 A pass cell [DOC S&HD 2-24/2-25]
        ; ; (runtime-generated) fire the SoftCard 6502 RPC with A staged
        CALL RPC_CALL_6502                    ; $AEEE  (runtime) 6502 call
        LD ($F6F8),A                     ; $AEF1
        LD (RPC_YREG),A                  ; $AEF4  $F047 = 6502 Y pass cell (S&HD table mislabels Y/X) [DOC S&HD 2-24/2-25]
        ; ; read Apple $CFFF: deselect ALL slot expansion ROMs (value discarded; SLOT_TO_EN reloads
        ; A from E)
        LD A,($EFFF)                     ; $AEF7
        ; ; form the slot I/O base $EN00 from the slot in E; returns A = high byte $EN
        CALL SLOT_TO_EN                  ; $AEFA  ($AAC5)
        SUB $20                          ; $AEFD
        ; ; first byte of LD ($F046),A: store ($EN-$20) into RPC_XREG (6502 X pass cell); operand +
        ; tail continue in the next BIOS chunk
        DEFB    $32                                              ; $AEFF  LD (nn),A -> continues past $AF00

CURMODE      EQU $AEB4        ; mode selector byte (operand of LD BC at $AEB3)
FLAG_AEAF    EQU $AEAF        ; BIOS flag byte cleared by WBOOT

    SAVEBIN "softcard/CPMV220-44K/os/CPM_BIOS.bin", $AA00, $0500
