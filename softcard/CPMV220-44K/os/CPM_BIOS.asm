; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- BIOS, RUNTIME-ADDRESSED (de-skewed)
; ----------------------------------------------------------------------------
; The 44K BIOS runs at z80 $AA00-$AFFF (6 pages). The prior CPM_BIOS.asm decoded
; it in on-disk (sector-interleaved) order and was both mis-addressed (28.9%
; source-vs-runtime match) AND missing the 6th page; this source is decoded
; against the DE-SKEWED runtime image -- every label a true runtime address. The
; disk producer re-applies the sector skew (cpm_pipeline/deskew.py ::
; BIOS_PAGE_TO_SECTOR). $AA00 = the 15-entry BIOS jump vector (BOOT, WBOOT,
; CONST, CONIN, CONOUT, LIST, PUNCH, READER, HOME, SELDSK, SETTRK, SETSEC,
; SETDMA, READ, WRITE). See ../../docs/CPM_Skew_Findings.md.
;
; DECODE IN PROGRESS: --auto-coverage --relocatable disassembly (byte-identical),
; being enriched to the C-level bar.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ORG $AA00
    ENDIF

; -- Mid-instruction references (shown inline as cover+offset) --
;   $AAFD -> CCP_MODE_FLAG+1         z80 skip idiom: enters the operand of $3E at $AAFC
;   $AB0E -> KBD_STATUS_40COL+2         shared instruction tail: $AB0E is reachable code inside the instruction at $AB0C
;   $AB3F -> RPC_TRIGGER_STORE+1         shared instruction tail: $AB3F is reachable code inside the instruction at $AB3E
;   $AC42 -> PUT_CHAR_VECTOR+1         shared instruction tail: $AC42 is reachable code inside the instruction at $AC41
;   $AE7A -> CONIO_SET_A1         z80 skip idiom: enters the operand of $21 at $AE79
;   $AEA2 -> COL_FLAG         shared instruction tail: $AEA2 is reachable code inside the instruction at $AEA1
;   $AEA9 -> BOOT+1         shared instruction tail: $AEA9 is reachable code inside the instruction at $AEA8
;   $AEAA -> BOOT+2         shared instruction tail: $AEAA is reachable code inside the instruction at $AEA8
;   $AEAC -> DISK_SELDSK_SAVE+1         z80 skip idiom: enters the operand of $3E at $AEAB
;   $AEAE -> DISK_SEKDSK+1        shared instruction tail: $AEAE is reachable code inside the instruction at $AEAD
;   $AEAF -> DISK_SEKDSK+2        shared instruction tail: $AEAF is reachable code inside the instruction at $AEAD
;   $AEB1 -> DISK_HSTWRT+1        z80 skip idiom: enters the operand of $3E at $AEB0
;   $AEB3 -> DISK_WRTYPE+1        shared instruction tail: $AEB3 is reachable code inside the instruction at $AEB2
;   $AEB4 -> DISK_WRTYPE+2        shared instruction tail: $AEB4 is reachable code inside the instruction at $AEB2
;   $AEB6 -> DISK_UNADSK+1        shared instruction tail: $AEB6 is reachable code inside the instruction at $AEB5
;   $AF50 -> DEV_HANDLER_PTRS_B        shared instruction tail: $AF50 is reachable code inside the instruction at $AF4E

; ----------------------------------------------------------------------
; BIOS_VECTOR -- the CP/M 2.2 BIOS entry jump vector.
;   15 three-byte JP entries the BDOS/CCP and the cold loader call by fixed
;   offset from the BIOS base: BOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH,
;   READER, HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE.
;   In:  entered by JP/CALL to base+3*n. Out: per the dispatched entry.
;   Note: the CONOUT and SETTRK targets ($AB43, $AD56) are the second-instruction
;         entry points of CONOUT_DISPATCH and HOME's tail, decoded as raw addresses
;         here; see flags.
; ----------------------------------------------------------------------
BIOS_VECTOR:
        ; entry 0 = cold boot (first run after the loader)
        JP BOOT
BIOS_VECTOR_WBOOT:
        ; jump table
        ; entry 1 = warm boot: reload CCP, rebuild page zero
        JP      WBOOT
        JP      CONST
        JP      CONIN
        ; entry 4 = CONOUT; target CONOUT_DISPATCH+1 (skips its leading LD C,A)
        JP      CONOUT_DISPATCH+1
        JP      LIST
        JP      PUNCH
        JP      READER
        JP      HOME
        JP      SELDSK
        ; entry 10 = SETTRK; the LD A,C tail shared with HOME
        JP      SETTRK
        JP      SETSEC
        JP      SETDMA
        JP      READ
        JP      WRITE
        DEFB    $AF,$C9,$00,$60,$69,$C9
; ----------------------------------------------------------------------
; DISK_PARAM_TABLE -- per-drive disk parameter / config rows (DATA, not code).
;   Built from a repeating 16-byte row stride: a leading pointer cluster
;   ($BA,$AE,$93,$AA = pointers into BIOS routines/data), then a 13-byte tail of
;   $00 fill plus the row's own pointer pair (e.g. $AA,$A6,$AF / $4A,$AF), one row
;   per logical drive. SELDSK indexes a parallel pointer at DISK_PARAM_TABLE (LD
;   HL,DISK_PARAM_TABLE).
;   The trailing 14 bytes at $AA94 ($00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,
;   $00,$03,$00) are the device/config parameter words the probe loop PROBE_DEVICES
;   reads. DATA: described, not renamed internally. [RE]
; ----------------------------------------------------------------------
DISK_PARAM_TABLE:
        DEFS    8, $00                   ; fill
        DEFB    $BA,$AE,$93,$AA,$9A,$AF,$3A,$AF
        DEFS    8, $00                   ; fill
        DEFB    $BA,$AE,$93
        DEFB    $AA,$A6,$AF,$4A,$AF,$00  ; "*&/J/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93
        DEFB    $AA,$B2,$AF,$5A,$AF,$00  ; "*2/Z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93
        DEFB    $AA,$BE,$AF,$6A,$AF,$00  ; "*>/j/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93
        DEFB    $AA,$CA,$AF,$7A,$AF,$00  ; "*J/z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93,$AA,$D6,$AF,$8A,$AF,$20
        DEFB    $00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,$00,$03,$00
; ----------------------------------------------------------------------
; PROBE_DEVICES -- scan the 7-entry SoftCard device/config area and mark presence.
;   In:  none (walks Apple $03B8.. via z80 $F3B8 = the SoftCard config block).
;   Out: config bytes updated in place; calls per-device init when a device is found.
;   Clobbers: A,DE,HL.
;   Algorithm: for E = 7 down to 1, read config[$F3B8 + E]; if it equals 3 the slot
;              holds a recognized device, so call SLOT_IO_ADDR (build the slot I/O base)
;              and store $03 then $15 into the config cell to flag it configured. A
;              secondary DEC A test (value was 4) runs SET_SCREEN_BASE (console probe) and
;              claims the $C800 shared expansion-ROM window via RPC_TRIGGER. [RE]
; ----------------------------------------------------------------------
PROBE_DEVICES:
        ; DE = 7 entries to scan (index walks down to 1)
        LD DE,$0007
PROBE_DEVICES_LOOP:
        ; z80 $F3B8 = Apple $03B8 = base of the SoftCard device config block
        LD HL,$F3B8
        ADD HL,DE
        LD A,(HL)
        ; config value 3 = a recognized/present device in this slot
        SUB $03
        JR NZ,PROBE_DEVICES_CHK4
        CALL SLOT_IO_ADDR
        ; rewrite the cell: $03 then $15 = mark this device configured
        LD (HL),$03
        LD (HL),$15
PROBE_DEVICES_CHK4:
        ; after the SUB, A==1 here means the original value was 4 (e.g. Videx-class console)
        DEC A
        JR NZ,PROBE_DEVICES_NEXT
        CALL SET_SCREEN_BASE
        ; z80 $C800 = Apple $C800 shared expansion-ROM window for the configured card
        LD HL,$C800
        CALL RPC_TRIGGER
PROBE_DEVICES_NEXT:
        ; next config entry; loop until all 7 scanned
        DEC E
        JR NZ,PROBE_DEVICES_LOOP
        RET
; ----------------------------------------------------------------------
; SLOT_IO_ADDR -- form a SoftCard I/O / soft-switch address from a slot/offset index.
;   In:  E = low offset within the I/O page.
;   Out: HL = $E0(E | $E0), i.e. an address in z80 $E000-$EFFF = Apple I/O
;        $C000-$CFFF; A clobbered.
;   Algorithm: H = $E0 base; A = E OR H so the high nibble forces the $C0xx I/O
;        page, then H = A. Used to reach keyboard / soft switches / slot I/O. [RE]
; ----------------------------------------------------------------------
DEVICE_IO_BASE:
        ; z80 $E000 = Apple $C000 = base of the soft-switch / slot I/O page
        LD HL,$E000
        LD A,E
        ; force the high byte into the $C0xx I/O range
        OR H
        LD H,A
        RET
; ----------------------------------------------------------------------
; WBOOT -- CP/M warm boot: re-initialize the console, rebuild page zero, re-enter CCP.
;   In:  none. Out: jumps to the CCP at $9400; does not return.
;   Clobbers: all.
;   Algorithm: set SP to the default DMA top ($0080); touch the 80-col soft switch
;        (z80 $E051 = Apple $C051 TXTSET); re-init the console via RPC_TRIGGER; re-run
;        the device probe; then PAGEZERO_REBUILD writes the standard CP/M page-zero
;        jumps and DMA and enters the CCP. [RE]
; ----------------------------------------------------------------------
WBOOT:
        ; stack at the default DMA buffer top (page-zero $0080)
        LD SP,$0080
        ; z80 $E051 = Apple $C051 TXTSET soft switch (console video reset)
        LD A,($E051)
        LD HL,$0E00
        ; re-init the console I/O vectors for warm restart
        CALL RPC_TRIGGER
        ; re-scan devices so warm boot rebuilds the I/O table
        CALL PROBE_DEVICES
; ----------------------------------------------------------------------
; PAGEZERO_REBUILD -- write the standard CP/M page-zero vectors and enter the CCP.
;   In:  none. Out: tail-calls into CCP_MODE_FLAG / JP $9400 (the CCP); no return.
;   Clobbers: A,HL,BC.
;   Algorithm: clear two self-modified BIOS state cells; write JP ($C3) at $0000
;        pointing at the BIOS vector+3 (warm-boot entry, BIOS_VECTOR_WBOOT) and JP at
;        $0005 pointing at the BDOS entry $9C06; set the default DMA to $0080 via
;        SETDMA; then fall into the CCP-launch tail. [RE]
; ----------------------------------------------------------------------
PAGEZERO_REBUILD:
        XOR A
        ; clear a self-modified BIOS console-state cell
        LD (DISK_WRTYPE+2),A
        LD (DISK_SEKDSK+2),A
        ; $C3 = Z-80 JP opcode to plant at the page-zero hooks
        LD A,$C3
        ; page-zero $0000 = JP to WBOOT (CP/M warm-boot hook)
        LD ($0000),A
        ; operand of the $0000 JP = BIOS vector+3 (WBOOT entry)
        LD HL,BIOS_VECTOR_WBOOT
        LD ($0001),HL
        ; page-zero $0005 = JP to BDOS (the CP/M BDOS call hook)
        LD ($0005),A
        ; BDOS entry point ($9C06) for the $0005 hook
        LD HL,$9C06
        LD ($0006),HL
        ; default DMA address = $0080 (page-zero buffer)
        LD BC,$0080
        ; install the default DMA pointer
        CALL SETDMA
; ----------------------------------------------------------------------
; CCP_LAUNCH -- final warm/cold-boot tail: set the CCP entry flag and jump to the CCP.
;   In:  none. Out: JP $9400 (CCP cold/warm entry); no return.
;   Clobbers: A,C.
;   Algorithm: store a CCP-mode flag ($01) into $98B2, then pass the current default
;        drive (page-zero $0004) in C and jump to the CCP at $9400.
;   Self-modify: CCP_MODE_FLAG's immediate ($01) is patched elsewhere to alter the
;        launch path; references therefore read CCP_MODE_FLAG+1. [RE]
; ----------------------------------------------------------------------
CCP_MODE_FLAG:
        ; CCP-mode flag value (this immediate is self-modified elsewhere)
        LD A,$01
        ; store the CCP entry/mode flag into CCP workspace at $98B2
        LD ($98B2),A
        ; page-zero $0004 = current default drive byte
        LD A,($0004)
        LD C,A
        ; enter the CCP at $9400, C = default drive
        JP $9400
; ----------------------------------------------------------------------
; CONST -- CP/M console status: return $FF if a console char is ready, else $00.
;   In:  none. Out: A = $FF (ready) / $00 (not). Clobbers: A,HL.
;   Algorithm: load the console-status handler address from the SoftCard I/O vector
;        cell (z80 $F380 = Apple $0380) and JP (HL) to the 6502-serviced handler,
;        which returns the status in A. [RE]
; ----------------------------------------------------------------------
CONST:
        ; z80 $F380 = Apple $0380 = console-status handler vector cell
        LD HL,($F380)
        ; dispatch to the selected console-status handler (returns A)
        JP (HL)
; ----------------------------------------------------------------------
; KBD_STATUS_40COL -- 40-column console status via the Apple keyboard strobe.
;   In:  none. Out: A = $FF if a key is waiting (bit 7 set at $C000), else $00.
;   Clobbers: A.
;   Algorithm: read z80 $E000 = Apple $C000 keyboard data/strobe; RLA shifts bit 7
;        (key-ready) into carry; SBC A,A expands carry to $FF/$00. This is the
;        built-in 40-col path used when no Videx/80-col card supplies CONST. [RE]
; ----------------------------------------------------------------------
KBD_STATUS_40COL:
        ; z80 $E000 = Apple $C000 keyboard register (bit 7 = key ready)
        LD A,($E000)
        ; rotate key-ready bit 7 into carry
        RLA
        ; carry -> A = $FF (ready) or $00 (none)
        SBC A,A
        RET
; ----------------------------------------------------------------------
; CONSOLE_IN_40COL -- CONIN for the built-in Apple keyboard (default console-input
; handler, installed into the I/O vector table). Waits for a key, then maps it through
; a small remap table (function/arrow keys) at Apple $03AB.
;   Out: A = (translated) key. Clobbers A,B,C,DE,HL.
; ----------------------------------------------------------------------
CONSOLE_IN_40COL:
        CALL CONIN_KEYWAIT               ; wait for a raw key in A
        LD HL,$F3AB                      ; HL = key-remap table (Apple $03AB)
        LD B,$06                         ; up to 6 table entries
        LD C,A                           ; C = raw key
CONIN_XLATE_LOOP:
        INC HL
        LD A,(HL)                        ; entry's match byte
        INC HL
        OR A
        JP M,CONIN_XLATE_DONE            ; high-bit sentinel ends the table
        CP C                             ; raw key == this entry?
        LD A,(HL)                        ; paired replacement byte
        RET Z                            ; match -> return the translated key
        DJNZ CONIN_XLATE_LOOP
CONIN_XLATE_DONE:
        LD A,C                           ; no match -> return the raw key
        RET
CONIN_KEYWAIT:
        LD DE,$0003
CONIN_DISPATCH:
        JP KBD_WAIT_KEY                  ; target (CONIN_DISPATCH+1) patched at boot
KBD_WAIT_KEY:
        LD A,($E000)                     ; poll Apple $C000 keyboard register
        RLA                              ; key-ready (bit 7) -> carry
        JR NC,KBD_WAIT_KEY               ; spin until a key is down
        LD ($E010),A                     ; clear the keyboard strobe (Apple $C010)
        CCF
        RRA                              ; A = 7-bit key
        RET
; ----------------------------------------------------------------------
; RPC_TRIGGER -- fire a SoftCard 6502<->Z80 RPC: stash HL to the command mailbox at
; Apple $03D0, then poke the trigger cell (its address is patched per config at boot).
;   In: HL = command/params; A = trigger value. Out: per the 6502 service routine.
; ----------------------------------------------------------------------
RPC_TRIGGER:
        LD ($F3D0),HL
RPC_TRIGGER_STORE:
        LD ($0000),A
        RET
; ----------------------------------------------------------------------
; CONOUT body -- emit a console character, routed by the CP/M IOBYTE.
;   In:  A = character (caller's CONOUT arg, moved to C here).
;   Out: none. Clobbers: A,C,HL.
;   Algorithm: read IOBYTE ($0003), mask the 2-bit CONSOLE field (AND $03). If the
;              field selects device value 2 (CRT/console), dispatch through the SoftCard
;              I/O vector cell at $F392 (Apple $0392) with JP (HL). Otherwise fall into
;              the column-tracking / tab-expansion path (CONOUT_FILTER) which formats the
;              character before it reaches the physical screen handler. This is the body
;              reached from the BIOS jump-vector CONOUT entry. [RE]
; ----------------------------------------------------------------------
CONOUT_DISPATCH:
        ; save the character to emit in C for the filter path
        LD C,A
        ; read the CP/M IOBYTE (page-zero $0003)
        LD A,($0003)
        ; isolate the 2-bit CONSOLE device field of the IOBYTE
        AND $03
        ; device value 2 = direct console; anything else takes the filter path
        CP $02
        JR NZ,CONOUT_FILTER_NOEXPAND
LIST_VIA_VEC_F392:
        ; load console-output handler addr from SoftCard I/O vector ($F392 = Apple $0392)
        LD HL,($F392)
        JP (HL)
; ----------------------------------------------------------------------
; CONIN -- read a console character, routed by the IOBYTE CONSOLE field.
;   In:  none. Out: A = character. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask CONSOLE field (AND $03), and select one of three
;              input-handler vector cells by the field value: value 2 uses $F38A, value 3
;              ($02<x) uses the already-loaded $F384, the low values use $F382; then
;              JP (HL) into the chosen handler. ($F38x = Apple $038x I/O vector.) [RE]
; ----------------------------------------------------------------------
CONIN:
        LD A,($0003)
        AND $03
        CP $02
        ; preload input-handler vector for the high CONSOLE field value ($F384 = Apple $0384)
        LD HL,($F384)
        JR Z,CONIN_VIA_VEC_F38A
        JR NC,DISPATCH_VIA_HL
CONIN_VIA_VEC_F382:
        ; input-handler vector for the low CONSOLE field values ($F382 = Apple $0382)
        LD HL,($F382)
        JP (HL)
CONIN_VIA_VEC_F38A:
        ; input-handler vector for CONSOLE field value 2 ($F38A = Apple $038A)
        LD HL,($F38A)
DISPATCH_VIA_HL:
        JP (HL)
; ----------------------------------------------------------------------
; LIST -- emit a character to the list device, routed by the IOBYTE LIST field.
;   In:  C = character. Out: none. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the top 2-bit LIST field (AND $C0). Field value below
;              $80 routes to the column/tab filter (CONOUT_FILTER); value == $80 reuses
;              the console vector path (LIST_VIA_VEC_F392); higher values dispatch through
;              the list-handler vector cell $F394 (Apple $0394). [RE]
; ----------------------------------------------------------------------
LIST:
        LD A,($0003)
        ; isolate the 2-bit LIST device field (top bits of the IOBYTE)
        AND $C0
        CP $80
        JR C,CONOUT_FILTER
        JR Z,LIST_VIA_VEC_F392
        ; load list-handler vector ($F394 = Apple $0394)
        LD HL,($F394)
        JP (HL)
; ----------------------------------------------------------------------
; PUNCH -- emit a character to the punch device, routed by the IOBYTE PUNCH field.
;   In:  C = character. Out: none. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the PUNCH field (AND $30). Field value below $10 takes
;              the column/tab filter; value $10 dispatches through vector $F390; higher
;              values dispatch through vector $F38E. ($F38E/$F390 = Apple $038E/$0390.) [RE]
; ----------------------------------------------------------------------
PUNCH:
        LD A,($0003)
        ; isolate the 2-bit PUNCH device field of the IOBYTE
        AND $30
        CP $10
        JR C,CONOUT_FILTER
        ; punch-handler vector for the higher PUNCH field values ($F38E = Apple $038E)
        LD HL,($F38E)
        JR NZ,DISPATCH_VIA_HL
        ; punch-handler vector for PUNCH field value $10 ($F390 = Apple $0390)
        LD HL,($F390)
        JP (HL)
; ----------------------------------------------------------------------
; READER -- read a character from the reader device, routed by the IOBYTE READER field.
;   In:  none. Out: A = character. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the READER field (AND $0C). Field value below $04
;              reuses the CONIN low-value vector path; value $04 reuses the CONIN $F38A
;              path; higher values dispatch through reader vector $F38C (Apple $038C). [RE]
; ----------------------------------------------------------------------
READER:
        LD A,($0003)
        ; isolate the 2-bit READER device field of the IOBYTE
        AND $0C
        CP $04
        JR C,CONIN_VIA_VEC_F382
        JR Z,CONIN_VIA_VEC_F38A
        ; load reader-handler vector ($F38C = Apple $038C)
        LD HL,($F38C)
        JP (HL)
; ----------------------------------------------------------------------
; CONOUT_FILTER -- column-tracking and tab/control formatting for console output.
;   In:  C = character; entered from CONOUT/LIST/PUNCH when the IOBYTE field selects the
;        filtered (non-raw) path. A carry/expand flag is set by the entry stub.
;   Out: none; emits 0..N physical characters via the screen handler (SCREEN_EMIT).
;   Clobbers: A,B,C,D,E,HL.
;   Algorithm: SCF then SBC A,A turns the carry into a 0/$FF flag stored in COL_FLAG.
;        Clear bit 7 of the character. If a pending-column-skip counter (COL_PENDING) is
;        nonzero, decrement it and reposition using config byte $F396 (Apple $0396) plus
;        the BOOT-overlaid base word, otherwise fall through to TAB_EXPAND. This is the
;        console output formatter; the two CONOUT_FILTER/_10 labels are the carry-set and
;        carry-clear entry points to the same body. [RE]
; ----------------------------------------------------------------------
CONOUT_FILTER:
        ; carry-set entry: mark the expand flag before SBC A,A turns it into $FF
        SCF
CONOUT_FILTER_NOEXPAND:
        ; convert carry into a 0/$FF flag byte for COL_FLAG
        SBC A,A
        LD HL,COL_FLAG
        ; store the entry flag into COL_FLAG
        LD (HL),A
        ; strip the high bit of the character (7-bit ASCII)
        RES 7,C
        INC HL
        ; load COL_PENDING (pending column-skip / fill count)
        LD A,(HL)
        OR A
        ; no pending column work -> go run tab/control expansion
        JR Z,TAB_EXPAND
        ; consume one pending column step
        DEC (HL)
        ; read screen-width / left-margin config byte ($F396 = Apple $0396)
        LD A,($F396)
        LD HL,DISK_SELDSK_SAVE
        JR Z,COL_OFFSET_FROM_WIDTH
        OR A
        JP P,COL_APPLY_OFFSET_RAW
        DEC HL
; ----------------------------------------------------------------------
; COL_APPLY_OFFSET -- apply a signed config offset to the running column position.
;   In:  A = config byte (sign bit = direction); C = current column; HL -> column cell.
;   Out: (HL) = C - offset. Clobbers: A,E.
;   Algorithm: mask off the sign bit (AND $7F) to get the magnitude, subtract it from the
;        current column in C, and store the new column. Reached when the config byte's
;        sign indicates a simple subtractive column adjust. [RE]
; ----------------------------------------------------------------------
COL_APPLY_OFFSET:
        ; drop the sign bit to get the offset magnitude
        AND $7F
COL_APPLY_OFFSET_RAW:
        LD E,A
        LD A,C
        ; new column = current column (C) minus the offset
        SUB E
        ; store the updated column position
        LD (HL),A
        RET
COL_OFFSET_FROM_WIDTH:
        OR A
        JP M,COL_OFFSET_FROM_WIDTH_1
        DEC HL
COL_OFFSET_FROM_WIDTH_1:
        CALL COL_APPLY_OFFSET
        LD HL,(BOOT+2)
        LD A,($F3A1)
        OR A
        JP P,COL_COMBINE_BASE
        AND $7F
        LD E,L
        LD L,H
        LD H,E
COL_COMBINE_BASE:
        LD E,A
        ADD A,H
        LD C,A
        LD A,E
        ADD A,L
        PUSH AF
        LD B,$07
        CALL SCREEN_EMIT
        POP AF
        LD B,$0A
; ----------------------------------------------------------------------
; CONOUT_EMIT_B -- emit character C, then route to TAB_EXPAND/SCREEN_EMIT with B as mode.
;   In:  A = character to emit; B = mode/count code.
;   Out: none. Clobbers: A,C.
;   Algorithm: move A into C and fall through to SCREEN_EMIT (SCREEN_EMIT) carrying the B
;        mode code. Tail-shared helper used by the column/tab logic to push a character
;        to the physical screen handler. [RE]
; ----------------------------------------------------------------------
CONOUT_EMIT_B:
        ; move the character into C for the screen emit path
        LD C,A
        JR SCREEN_EMIT
; ----------------------------------------------------------------------
; TAB_EXPAND -- expand tabs / handle special columns against the tab-stop config table.
;   In:  C = character (already 7-bit); B = passed from caller.
;   Out: none; may emit fill characters and update the column state. Clobbers: A,B,C,D,E,HL.
;   Algorithm: COL_STATE (COL_STATE) holds a sticky control state. If zero, compare the
;        character against config byte $F397 (Apple $0397, a special trigger char); a match
;        arms the sticky state ($80). Printable characters above $1F scan the 9-entry tab
;        config table at $F3A0 (Apple $03A0, walked downward) for a matching stop; on a hit
;        it indexes +$0B into a parallel table for the action byte, optionally recursing
;        with config $F3A2 to emit a secondary character. A B==7 result sets COL_MODE
;        (COL_PENDING) = 2. Falls through to SCREEN_EMIT for the actual output. [RE]
; ----------------------------------------------------------------------
TAB_EXPAND:
        LD B,A
        ; HL -> COL_STATE sticky control-state cell
        LD HL,COL_STATE
        LD A,(HL)
        LD E,A
        OR A
        JR NZ,TAB_TABLE_SCAN
        ; read the special trigger character from config ($F397 = Apple $0397)
        LD A,($F397)
        OR A
        JR Z,TAB_EXPAND_CHECK_CTRL
        ; does the current character match the trigger?
        CP C
        JR NZ,TAB_EXPAND_CHECK_CTRL
        ; arm the sticky control state for the next character
        LD (HL),$80
        RET
TAB_EXPAND_CHECK_CTRL:
        ; control-char threshold: chars <= $1F are not table-scanned
        LD A,$1F
        CP C
        JR C,SCREEN_EMIT
TAB_TABLE_SCAN:
        ; HL -> top of the 9-entry tab-stop config table ($F3A0 = Apple $03A0)
        LD HL,$F3A0
        ; 9 tab-stop table entries to scan
        LD B,$09
TAB_TABLE_SCAN_LOOP:
        LD A,(HL)
        OR A
        JR Z,TAB_TABLE_SCAN_NEXT
        ; fold in COL_STATE before comparing the table entry to the char
        XOR E
        CP C
        JR Z,TAB_TABLE_HIT
TAB_TABLE_SCAN_NEXT:
        DEC HL
        DJNZ TAB_TABLE_SCAN_LOOP
        JR SCREEN_EMIT
TAB_TABLE_HIT:
        ; step +$0B from the matched stop to its parallel action byte
        LD DE,$000B
        ADD HL,DE
        LD A,(HL)
        OR A
        LD C,A
        JP P,TAB_EXPAND_DONE
        AND $7F
        LD C,A
        PUSH BC
        ; secondary action character from config ($F3A2 = Apple $03A2)
        LD A,($F3A2)
        LD B,$07
        CALL CONOUT_EMIT_B
        POP BC
TAB_EXPAND_DONE:
        LD A,B
        ; action code 7 -> set COL_MODE = 2
        CP $07
        JR NZ,SCREEN_EMIT
        LD A,$02
        ; record COL_MODE = 2 for the next emit
        LD (COL_PENDING),A
; ----------------------------------------------------------------------
; CONOUT_VIA_SCREEN -- emit one character to the Apple text screen, then advance
; the cursor and redraw it.
;   In:  the pending character is taken from the screen-driver state cells, not from
;        a register here (SCREEN_CHAR holds the char-under-cursor; the caller has
;        already staged the glyph). B = control-code selector for CTRL_CHAR_DISPATCH.
;   Out: none. Clobbers: A,DE,HL.
;   Algorithm: clear the wrap/scroll flag (COL_STATE), then vector through one of
;              two screen-driver entry points selected by COL_FLAG (modeled in
;              $F386/$F388 = Apple $0386/$0388 of the SoftCard I/O vector table).
;              [RE] COL_FLAG selects 40-col vs 80-col / normal vs alternate path.
; ----------------------------------------------------------------------
SCREEN_EMIT:
        XOR A
        ; clear the pending wrap/scroll flag before emitting
        ; clear COL_STATE before handing off to the screen handler
        LD (COL_STATE),A
        ; screen-mode selector: chooses which driver entry to vector to [RE]
        ; test COL_FLAG to choose which screen-output vector to use
        LD A,(COL_FLAG)
        OR A
        ; default screen-driver entry (SoftCard vector table, Apple $0388)
        ; default screen-output vector ($F388 = Apple $0388)
        LD HL,($F388)
        JR Z,SCREEN_EMIT_VECTOR
        ; alternate screen-driver entry (Apple $0386) when selector nonzero
        ; alternate screen-output vector ($F386 = Apple $0386)
        LD HL,($F386)
; ----------------------------------------------------------------------
; Merge point: HL = the selected screen-driver entry; fall through to the JP (HL).
; ----------------------------------------------------------------------
SCREEN_EMIT_VECTOR:
        ; tail-jump into the selected screen-driver entry point
        JP (HL)
; ----------------------------------------------------------------------
; PUT_CHAR_DE3 -- screen-driver entry that preloads DE=3 (advance amount / column
; step) and falls into the glyph-store path. [RE]
;   In:  driver state cells as set up by CONOUT_VIA_SCREEN.
;   Out: none. Clobbers: A,DE,HL.
; ----------------------------------------------------------------------
PUT_CHAR_DE3:
        ; preset DE = column/advance step for this driver variant [RE]
        LD DE,$0003
; ----------------------------------------------------------------------
; PUT_CHAR_VECTOR -- indirect entry into the glyph-store body. This JP's target
; operand is SELF-MODIFIED elsewhere (patch site = PUT_CHAR_VECTOR+1); it normally
; points at PUT_CHAR_STORE. Treat the +1/+2 bytes as the live dispatch target. [RE]
; ----------------------------------------------------------------------
PUT_CHAR_VECTOR:
        ; dispatch into the glyph-store body; target operand (PUT_CHAR_VECTOR+1) is patched at
        ; runtime [RE]
        JP PUT_CHAR_STORE
; ----------------------------------------------------------------------
; PUT_CHAR_STORE -- store the current glyph at the cursor cell, recompute the cursor
; screen address from CH/BASL, read back the char now under the cursor, and write it
; as the inverse/cursor glyph.
;   In:  SCREEN_CURSOR_PTR = current cursor screen pointer; SCREEN_CHAR = glyph to store.
;   Out: SCREEN_CURSOR_PTR/SCREEN_CHAR updated to the new cursor cell + char under it.
;        Clobbers: A,DE,HL.
;   Algorithm: write staged glyph to old cursor cell; run the control-char handler
;              (CTRL_CHAR_DISPATCH) which may move CH; recompute the cell address as
;              BASL + CH ($F028/$F024 = Apple $0028/$0024); save char under cursor;
;              convert it to the inverse-video cursor glyph and store it. [RE]
; ----------------------------------------------------------------------
PUT_CHAR_STORE:
        ; HL = saved cursor screen pointer (cell holding the cursor)
        LD HL,(SCREEN_CURSOR_PTR)
        ; A = staged glyph (the real char that belongs in that cell)
        LD A,(SCREEN_CHAR)
        ; draw the inverse-video cursor glyph in the new cell
        ; restore the real char into the old cursor cell
        LD (HL),A
        ; run control-char handling / cursor advance (may update CH=$F024)
        CALL CTRL_CHAR_DISPATCH
        ; HL = current text line base BASL/BASH (Apple ZP $0028/$0029)
        LD HL,($F028)
        ; A = cursor column CH (Apple ZP $0024)
        LD A,($F024)
        LD E,A
        ; high byte $F0 maps column offset into the Apple low-RAM screen region
        LD D,$F0
        ; HL = BASL + CH = address of the new cursor cell
        ADD HL,DE
        ; save the new cursor cell pointer
        LD (SCREEN_CURSOR_PTR),HL
        LD A,(HL)
        ; save the char currently under the cursor (to restore later)
        LD (SCREEN_CHAR),A
        ; is the char in the lowercase/high range? choose inverse-video mapping
        CP $E0
        JR C,PUT_CHAR_CURSOR_GLYPH
        ; fold lowercase to its display form for the cursor glyph
        XOR $20
; ----------------------------------------------------------------------
; Merge point in the cursor-glyph conversion (chars below $E0 skip the XOR $20 fold).
; ----------------------------------------------------------------------
PUT_CHAR_CURSOR_GLYPH:
        ; mask to 6-bit glyph code
        AND $3F
        ; set inverse/flash field for the on-screen cursor glyph
        OR $40
        LD (HL),A
        RET
; ----------------------------------------------------------------------
; CTRL_CHAR_DISPATCH -- handle a control character / cursor-motion code by indexing a
; per-code offset table and jumping to the matching handler body.
;   In:  B = control-code index (0 = none/plain char). A is loaded from B.
;   Out: per-handler (typically updates CH=$F024 and/or the line base). Clobbers A,HL.
;   Algorithm: if B==0 fall through to the plain-character handler at CTRL_PLAIN_CHAR. Else
;              push the RET address RPC_TRIGGER (each handler RETs back through it), load
;              HL = CTRL_HANDLER_OFFSET_TBL, add the code to L, read the handler's low byte
;              from the table (high byte stays $AC), and JP (HL) into the handler body. The
;              handlers set HL to an Apple monitor routine address and RET (the caller fires
;              the 6502 RPC), or update the cursor cells (CH/CV at Apple ZP $0024/$0025)
;              directly. See CTRL_HANDLER_OFFSET_TBL for the code -> handler mapping.
; ----------------------------------------------------------------------
CTRL_CHAR_DISPATCH:
        ; A = control-code index passed in B
        LD A,B
        ; index 0 means plain character: fall through to CTRL_PLAIN_CHAR
        OR A
        ; no control code: take the plain-char store path
        JR Z,CTRL_PLAIN_CHAR
        ; push the common return address so each handler RETs back here [RE]
        LD HL,RPC_TRIGGER
        PUSH HL
        ; HL = base of the per-code handler offset table
        LD HL,CTRL_HANDLER_OFFSET_TBL
        ; index the table: L = table_base_low + control-code; (HL) then holds the handler low byte
        ; [RE]
        ADD A,L
        ; dispatch tail: L = table base low + control code; fetch the handler low byte
        ; (high byte stays $AC) and jump to it.
        LD L,A
        LD L,(HL)                        ; 6E  L = CTRL_HANDLER_OFFSET_TBL[code]
        JP (HL)                          ; E9  enter the handler in page $AC
; CTRL_PLAIN_CHAR -- store a printable character (or handle CR) on the text screen.
CTRL_PLAIN_CHAR:
        LD A,C
        CP $0D                           ; carriage return?
        JR NZ,CTRL_PLAIN_PUT
        XOR A
        LD ($F024),A                     ; CR: reset cursor column CH (Apple ZP $0024)
        RET
CTRL_PLAIN_PUT:
        OR $80                           ; set high bit (Apple screen glyph)
        CP $E0                           ; in the lowercase range?
        JR C,CTRL_PLAIN_STORE
        LD HL,$F3DD                      ; case-fold config byte (Apple $03DD)
        XOR (HL)
CTRL_PLAIN_STORE:
        LD ($F045),A                     ; stash the glyph (Apple ZP $0045)
        LD HL,$FDF0                      ; HL = Apple monitor COUT1 ($FDF0) for the 6502 RPC
        JR PLOT_RPC_TAIL                 ; emit via the shared RPC tail
; --- control-code handlers (entered via the offset table; each RETs through RPC_TRIGGER) ---
CTRL_MODE_FF:                            ; code 4
        LD A,$FF
        DEFB    $01                      ; cover (LD BC,nn): skips the LD A,$3F below
CTRL_MODE_3F:                            ; code 5
        LD A,$3F
        LD ($F032),A                     ; set the screen mode/mask byte (Apple ZP $0032)
CTRL_POP_RET:                            ; code 7: discard the pushed return and exit
        POP HL
        RET
CTRL_RPC_FBF4:                           ; code 9
        LD HL,$FBF4                      ; HL = Apple monitor routine ($FBF4) for the RPC
        RET
CTRL_HOME_CURSOR:                        ; code 6: home the cursor (CH/CV = 0)
        XOR A
        LD L,A
        LD H,A
        LD ($F024),HL                    ; Apple ZP $0024/$0025 = (0,0)
CTRL_RPC_BASCALC:
        LD ($F045),A
        LD HL,$FBC1                      ; HL = Apple monitor BASCALC ($FBC1) for the RPC
        RET
CTRL_COL_42:                             ; code 2
        LD L,$42
        DEFB    $01                      ; cover: skips the LD L,$9C below
CTRL_COL_9C:                             ; code 3
        LD L,$9C
        DEFB    $01                      ; cover: skips the LD L,$1A below
CTRL_COL_1A:                             ; code 8
        LD L,$1A
        DEFB    $01                      ; cover: skips the LD L,$58 below
CTRL_COL_58:                             ; code 1
        LD L,$58
        LD H,$FC                         ; HL = Apple monitor routine ($FC..) for the RPC
        RET
CTRL_CLAMP_CURSOR:                       ; code 10: clamp the saved cursor to 40x24 and store it
        LD HL,(BOOT+2)                   ; load saved cursor col/row (BOOT+2 cell)
        LD A,L
        CP $28                           ; column >= 40?
        JR C,CTRL_CLAMP_ROW
        LD L,$00                         ; clamp column to 0
CTRL_CLAMP_ROW:
        LD A,H
        CP $18                           ; row >= 24?
        JR C,CTRL_CLAMP_STORE
        LD H,$00                         ; clamp row to 0
CTRL_CLAMP_STORE:
        LD ($F024),HL                    ; store cursor (Apple ZP $0024/$0025)
        DEFB    $18                      ; JR opcode; its offset is the table[0] byte below
                                         ;        ($D5 = -43 -> CTRL_RPC_BASCALC)
CTRL_HANDLER_OFFSET_TBL:
        ; low byte of each control-code handler (high byte $AC); indexed by control code
        ; 1..10. Entry [0]=$D5 doubles as the JR offset above (code 0 never dispatches here;
        ; it falls through to CTRL_PLAIN_CHAR earlier).
        ; -> [0]=JR-offset, COL_58, COL_42, COL_9C, MODE_FF, MODE_3F, HOME, POP_RET, COL_1A,
        ;    RPC_FBF4, CLAMP
        DEFB    $D5,$BA,$B1,$B4,$96,$99,$A4,$9E,$B7,$A0,$BF
; DEV_STROBE_RD -- device handler: poll a status bit at the slot I/O base, then strobe.
DEV_STROBE_RD:
        CALL SLOT_IO_ADDR                ; HL = slot I/O base for the device
DEV_STROBE_WAIT:
        LD A,(HL)
        AND $02                          ; wait for the ready bit
        JR Z,DEV_STROBE_WAIT
        INC L
        LD (HL),C                        ; hand the byte to the device
        RET
; ----------------------------------------------------------------------
; SET_CURSOR_COL_AND_BASE -- set the cursor column from C, then compute the screen
; line base address for the current row.
;   In:  C = cursor column. Row state read inside SLOT_IO_ADDR_W.
;   Out: CH=$F045 set; falls through to SET_SCREEN_BASE. Clobbers A,HL (per AD5B).
;   Algorithm: store C to the column cell (Apple $0045), then fall into the base
;              computation. [RE]
; ----------------------------------------------------------------------
SET_CURSOR_COL_AND_BASE:
        ; A = requested cursor column from C
        LD A,C
        ; store cursor column (Apple ZP $0045) [RE]
        LD ($F045),A
; ----------------------------------------------------------------------
; SET_SCREEN_BASE -- compute the text-line base address for the current cursor row
; and stash its parts in the Apple ZP screen-base cells.
;   In:  row state (consumed by SLOT_IO_ADDR_W).
;   Out: A = char under cursor (from (HL)); $F6F8/$F045/$F046/$F047 updated.
;        Clobbers A,HL.
;   Algorithm: call SLOT_IO_ADDR_W to derive the row base, store it to the scratch cell
;              $F6F8 (Apple $06F8) and to $F047 (Apple $0047); read a column from the
;              SoftCard I/O region $EFFF (Apple $CFFF), normalize via DEVICE_IO_BASE,
;              subtract a space ($20) bias, store to $F046, and return char-under-
;              cursor in A. [RE] exact roles of $F045/$F046/$F047 = BASL/BASH/col.
; ----------------------------------------------------------------------
SET_SCREEN_BASE:
        ; derive the text-line base address for the current row
        CALL SLOT_IO_ADDR_W
        ; save base into scratch cell (Apple $06F8)
        LD ($F6F8),A
        ; store base into a screen-base cell (Apple ZP $0047)
        LD ($F047),A
        ; read a column/value from SoftCard I/O ($EFFF = Apple $CFFF) [RE]
        LD A,($EFFF)
        CALL DEVICE_IO_BASE
        ; remove the space ($20) bias to get a screen offset [RE]
        SUB $20
        ; store the computed offset into a screen-base cell (Apple ZP $0046)
        LD ($F046),A
        ; return the character currently at the computed cell
        LD A,(HL)
        RET
; ----------------------------------------------------------------------
; PLOT_CHAR_AT_COL -- position to a column then write C into the row buffer at that
; offset, and tail-jump to the common screen-driver return.
;   In:  C = character; DE = column offset; cursor row state.
;   Out: char stored into the row buffer at $F678+DE (Apple $0678+DE). [RE]
;   Algorithm: recompute the base via SET_CURSOR_COL_AND_BASE, form $F678+DE,
;              store C, then JP RPC_TRIGGER (shared driver epilogue). [RE]
; ----------------------------------------------------------------------
PLOT_CHAR_AT_COL:
        ; set cursor column and recompute the row base
        CALL SET_CURSOR_COL_AND_BASE
        ; HL = row buffer base (Apple $0678) [RE]
        LD HL,$F678
        ; HL = buffer base + column offset DE
        ADD HL,DE
        ; store the character at the target column
        LD (HL),C
        LD HL,$C9AA
        ; tail into the shared screen-driver return path
PLOT_RPC_TAIL:
        JP RPC_TRIGGER                   ; (emit via the SoftCard RPC trigger)
; DEV_READ_BIT -- device handler: poll a status bit until set, then read the data byte.
DEV_READ_BIT:                            ; (DEV_HANDLER_PTRS_B[0])
        CALL SLOT_IO_ADDR
DEV_READ_WAIT:
        LD A,(HL)
        RRA                              ; ready bit -> carry
        JR NC,DEV_READ_WAIT
        INC L
        LD A,(HL)                        ; read the data byte
        RET
; DEV_OUT_RPC -- device handler: position via the screen base, RPC a fixed command, read back.
DEV_OUT_RPC:                             ; (DEV_HANDLER_PTRS_B[1])
        CALL SET_SCREEN_BASE
        LD HL,$C84D
        CALL RPC_TRIGGER                 ; trigger the SoftCard RPC
        LD HL,$F678                      ; row buffer base (Apple $0678)
        ADD HL,DE
        LD A,(HL)
        RET
DEV_OUT_1:                               ; (default I/O vector handler)
        LD DE,$0001
DEV_OUT_1_JP:
        JP DEV_RET                       ; target (DEV_OUT_1_JP+1) patched at boot
; DEV_WR_BIT -- device handler: wait for ready, then write C to the slot I/O port.
DEV_WR_BIT:                              ; (DEV_HANDLER_PTRS[2])
        CALL DEVICE_IO_BASE
        LD L,$C1
DEV_WR_WAIT:
        LD A,(HL)
        RLA                              ; ready bit -> carry
        JR C,DEV_WR_WAIT
        CALL SLOT_IO_ADDR_W
        LD (HL),C
DEV_RET:
        RET                              ; shared return (DEV_OUT_1/_2 JP here)
DEV_OUT_2:                               ; (default I/O vector handler)
        LD DE,$0002
DEV_OUT_2_JP:
        JP DEV_RET                       ; target (DEV_OUT_2_JP+1) patched at boot
DEV_OUT_3:                               ; (default I/O vector handler)
        LD DE,$0002
DEV_OUT_3_JP:
        JP $0000                         ; whole instruction built at boot (DEV_OUT_3_JP+0/+1/+2)
; ----------------------------------------------------------------------
; HOME -- BIOS jump-vector entry: seek the selected drive to track 0.
;   In:  none (operates on the selected disk).
;   Out: none. Clobbers: A,C.
;   Algorithm: if the host buffer still holds dirty (hstwrt) data, leave hstact
;              set so the pending write is not lost; otherwise mark the host
;              buffer inactive (hstact=0). Then fall into SETTRK with track 0,
;              recording sektrk=0. The actual head step happens later inside the
;              deblock read/write path, not here. [RE]
; ----------------------------------------------------------------------
HOME:
        ; read hstwrt (host-write-pending flag)
        LD A,(DISK_HSTWRT)
        OR A
        JR NZ,SETTRK_STORE
        ; no pending write: clear hstact so the host buffer is reloaded on next access
        LD (DISK_SEKDSK+2),A
; ----------------------------------------------------------------------
; SETTRK -- BIOS jump-vector entry (vector $AA1E -> here): set the requested track.
;   In:  C = track number (BC = track; only C used).
;   Out: none. Clobbers: A.
;   Algorithm: store C into sektrk (the BDOS-requested track). HOME falls in here
;              with C=0. The track is consumed later by the deblock host-match
;              test and the RWTS setup, not acted on immediately.
; ----------------------------------------------------------------------
SETTRK_STORE:
        ; HOME enters here with track 0; SETTRK enters at the LD A,C below
        LD C,$00
        ; track number from BDOS
SETTRK:                                  ; BIOS jump-vector entry 10 (HOME falls in above)
        LD A,C
        ; store into sektrk (overlaid on the BOOT entry's LD SP operand)
        LD (BOOT),A
        RET
; ----------------------------------------------------------------------
; SLOT_IO_ADDR_W -- map a slot/drive index to an Apple write-side I/O soft-switch base.
;   In:  E = slot/drive index (0..15).
;   Out: HL = $E080 + (E << 4) = Apple $C080+slot*16 soft-switch register.
;        A preserved low nibble math. Clobbers: A,L.
;   Algorithm: load the $C08x base for the write/control bank, then fall into the
;              common index scaler (SLOT_IO_SCALE) that shifts E left by 4 and adds it
;              to L. z80 $E080 = Apple $C080 (slot I/O space). [RE]
; ----------------------------------------------------------------------
SLOT_IO_ADDR_W:
        ; z80 $E080 = Apple $C080 slot-I/O base (write/control bank)
        LD HL,$E080
        JR SLOT_IO_SCALE_E
; ----------------------------------------------------------------------
; SLOT_IO_ADDR -- map a slot/drive index to an Apple I/O soft-switch address ($C08E bank).
;   In:  E = slot/drive index (0..15).
;   Out: HL = $E08E + (E << 4) = Apple $C08E+slot*16. Clobbers: A,L.
;   Algorithm: load the $C08E base, then SLOT_IO_SCALE shifts E left by 4 (ADD A,A x4)
;              and adds it to L to index the per-slot $C0n0..$C0nF register block.
;              z80 $E08E = Apple $C08E (slot I/O). [RE]
; ----------------------------------------------------------------------
SLOT_IO_ADDR:
        ; z80 $E08E = Apple $C08E slot-I/O base
        LD HL,$E08E
SLOT_IO_SCALE_E:
        ; slot/drive index
        LD A,E
SLOT_IO_SCALE:
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        PUSH AF
        ADD A,L
        LD L,A
        POP AF
        RET
; ----------------------------------------------------------------------
; SELDSK -- BIOS jump-vector entry: select the disk drive for subsequent I/O.
;   In:  C = disk number (0-based).
;   Out: HL = DPH (disk parameter header) address for drive C, or HL=0 if C is out
;             of range. Clobbers: A,DE,HL.
;   Algorithm: read the configured drive count from the SoftCard config block
;              (z80 $F3B8 = Apple $03B8). If C >= count, return 0. Otherwise record
;              the selected disk into the sekdsk build site (DISK_SELDSK_SAVE+1 = $04 marker
;              then C) and return the constant DPH at DISK_PARAM_TABLE scaled by the index.
;              z80 $F3B8 = Apple ZP/config $03B8. [RE]
; ----------------------------------------------------------------------
SELDSK:
        ; DE -> sekdsk build site (the SMC cells overlaid on the BOOT-area instructions)
        LD DE,DISK_SELDSK_SAVE+1
        LD HL,$0004
        ; configured drive count from Apple config $03B8
        LD A,($F3B8)
        DEC A
        ; requested drive vs (count-1); C-flag set if out of range
        CP C
        ; out of range -> return HL=0
        JR C,SELDSK_BAD_DRIVE
        LD A,(HL)
        ; store the marker, then the selected disk number into sekdsk
        LD (DE),A
        INC DE
        LD A,C
        LD (DE),A
        ; base DPH; SLOT_IO_SCALE indexes it by the drive number
        LD HL,DISK_PARAM_TABLE
        JR SLOT_IO_SCALE
SELDSK_BAD_DRIVE:
        LD A,(DE)
        LD (HL),A
        LD L,$00
        RET
; ----------------------------------------------------------------------
; SETSEC -- BIOS jump-vector entry: set the requested sector.
;   In:  C = sector number.
;   Out: none. Clobbers: A.
;   Algorithm: store C into seksec (the BDOS-requested sector, overlaid on BOOT+1).
;              Consumed later by the deblock host-match test.
; ----------------------------------------------------------------------
SETSEC:
        LD A,C
        ; store into seksec
        LD (BOOT+1),A
        RET
; ----------------------------------------------------------------------
; SETDMA -- BIOS jump-vector entry: set the DMA (record transfer) address.
;   In:  BC = DMA buffer address (where the 128-byte CP/M record is read to/written from).
;   Out: none. Clobbers: none.
;   Algorithm: store BC into dmaadr; the deblock copy (LDIR) uses it as the host<->record
;              transfer endpoint.
; ----------------------------------------------------------------------
SETDMA:
        ; store the DMA address into dmaadr
        LD (DISK_DMAADR),BC
        RET
; ----------------------------------------------------------------------
; READ -- BIOS jump-vector entry: read one 128-byte CP/M record via deblocking.
;   In:  sekdsk/sektrk/seksec/dmaadr previously set by SELDSK/SETTRK/SETSEC/SETDMA.
;   Out: A = 0 on success, 1 on error (set by the shared deblock tail). Clobbers: A,HL,...
;   Algorithm: clear unacnt (no unallocated-write run is in progress on a read), then
;              mark this as a read: readop=2 and seed the wrtype/flag bytes to 2, and
;              jump into the shared deblock core which pre-reads the host sector if the
;              requested record is not already buffered, then copies host -> DMA. [RE]
; ----------------------------------------------------------------------
READ:
        XOR A
        ; unacnt = 0: a read never continues an unallocated-write run
        LD (DISK_WRTYPE+2),A
        LD A,$02
        ; HL -> readop; seed readop and the following flag bytes = 2 (read operation)
        LD HL,DISK_HSTWRT+1
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
        ; enter the shared deblock core (skip the write-only pre-roll)
        JR DEBLOCK_CORE
; ----------------------------------------------------------------------
; WRITE -- BIOS jump-vector entry: write one 128-byte CP/M record via deblocking.
;   In:  C = write type (0=allocated, 1=directory, 2=to a freshly-allocated/unalloc block);
;        sekdsk/sektrk/seksec/dmaadr previously set.
;   Out: A = 0 on success, 1 on error. Clobbers: A,HL,...
;   Algorithm: record readop/wrtype from C. For an unallocated-block write (C=2) seed an
;              8-record run (unacnt=8) anchored at the current sekdsk/sektrk/seksec so the
;              next 7 sequential records skip the redundant pre-read. Then the shared
;              deblock core: if the requested record extends the active unalloc run just
;              buffer it (rsflag=0); otherwise force a host pre-read (rsflag=1), copy
;              DMA -> host, mark hstwrt. [RE]
; ----------------------------------------------------------------------
WRITE:
        LD H,C
        LD L,$00
        ; readop = wrtype (from C), clear the adjacent flag byte
        LD (DISK_HSTWRT+1),HL
        LD A,C
        ; wrtype 2 = write to an unallocated block (start a sequential run)
        CP $02
        ; ordinary write: skip the unalloc-run seeding
        JR NZ,DEBLOCK_CHECK_UNALLOC
        ; unacnt = 8 records in the new unallocated run (host blocking factor)
        LD L,$08
        ; compare sekdsk against the run's disk
        LD A,(DISK_SEKDSK)
        LD H,A
        ; seed unacnt (and the next byte) for the run
        LD (DISK_WRTYPE+2),HL
        ; anchor the run's next-track/sector (unatrk/unasec) at the requested sektrk/seksec
        LD HL,(BOOT)
        ; advance unatrk/unasec to the next record in the run
        LD (DISK_UNADSK+1),HL
; ----------------------------------------------------------------------
; DEBLOCK_CHECK_UNALLOC -- decide whether the requested record continues the active
;   unallocated-write run; if so just buffer it, else force a pre-read.
;   In:  unacnt/unatrk/unasec, sekdsk/sektrk/seksec set by READ/WRITE.
;   Out: rsflag set (0 = reuse buffer, 1 = must pre-read host sector). Clobbers: A,HL.
;   Algorithm: if unacnt==0 the run is over -> rsflag=1. Otherwise verify the request
;              matches sekdsk and the run's next unatrk/unasec; on a match advance the
;              run and set rsflag=0, on any mismatch set rsflag=1. [RE]
; ----------------------------------------------------------------------
DEBLOCK_CHECK_UNALLOC:
        ; point HL at unacnt (unallocated record count)
        LD HL,DISK_WRTYPE+2
        ; unacnt: zero means no active unalloc run
        LD A,(HL)
        OR A
        JR Z,DEBLOCK_FORCE_PREREAD
        ; consume one record of the unallocated run
        DEC (HL)
        LD A,(DISK_SEKDSK)
        INC HL
        CP (HL)
        JR NZ,DEBLOCK_FORCE_PREREAD
        LD A,(BOOT)
        ; load unatrk/unasec (the run's current track/sector)
        LD HL,(DISK_UNADSK+1)
        CP L
        JR NZ,DEBLOCK_FORCE_PREREAD
        ; requested seksec vs the run's sector
        LD A,(BOOT+1)
        CP H
        JR NZ,DEBLOCK_FORCE_PREREAD
        ; advance the unalloc sector; wrap to next track when it passes the sectors-per-track limit
        ; ($20)
        INC H
        LD A,H
        SUB $20
        JR C,DEBLOCK_RUN_CONTINUES
        LD H,A
        INC L
DEBLOCK_RUN_CONTINUES:
        LD (DISK_UNADSK+1),HL
        XOR A
        ; rsflag = 0: record continues the run, no host pre-read needed
        LD (DISK_WRTYPE+1),A
        JR DEBLOCK_CORE
DEBLOCK_FORCE_PREREAD:
        ; rsflag = 1: record breaks the run, force a host-sector pre-read
        LD HL,$0001
        LD (DISK_WRTYPE+1),HL
; ----------------------------------------------------------------------
; DEBLOCK_CORE -- shared host-buffer management for READ and WRITE (the deblock heart).
;   In:  sekdsk/sektrk/seksec, readop, wrtype, rsflag, hstact, hstwrt, dmaadr.
;   Out: A = status (0 ok). Performs the host sector flush/read and the 128-byte
;        record copy host<->DMA. Clobbers: A,BC,DE,HL.
;   Algorithm: translate seksec through SECTOR_XLATE to the physical sector. If the
;              host buffer is active (hstact) but holds a different disk/track/sector,
;              flush it when dirty (hstwrt). Set up the RWTS request (track/sector/
;              unit into the Apple $03Ex IOB). If rsflag demands it, physically read
;              the host sector. Finally LDIR-copy the selected 128-byte half of the
;              host sector to/from dmaadr (direction chosen by readop), and on a write
;              mark hstwrt and flush if required. [RE]
; ----------------------------------------------------------------------
DEBLOCK_CORE:
        ; read seksec back (returns the requested sector for translation)
        CALL READ_SEKSEC
        LD E,A
        RRA
        ; translate logical sector -> physical via the skew table
        LD HL,SECTOR_XLATE
        ADD A,L
        LD L,A
        LD C,(HL)
        ; HL -> hstact; remember prior state, then mark the host buffer active
        LD HL,DISK_SEKDSK+2
        LD A,(HL)
        ; hstact = 1 (host buffer now in use)
        LD (HL),$01
        OR A
        ; host buffer was inactive: no flush/match test needed, go set up RWTS
        JR Z,DEBLOCK_SETUP_RWTS
        ; compare sekdsk vs hstdsk (host buffer's disk)
        LD HL,(DISK_SEKDSK)
        LD A,L
        CP H
        JR NZ,DEBLOCK_NEED_RELOAD
        ; Apple $03E0 = current RWTS track/sector in the host buffer
        LD HL,($F3E0)
        ; requested sektrk vs host buffer track
        LD A,(BOOT)
        CP L
        JR NZ,DEBLOCK_NEED_RELOAD
        LD A,C
        CP H
        ; requested record already in the host buffer -> skip flush and re-read, go straight to the
        ; copy
        JR Z,DEBLOCK_COPY_RECORD
DEBLOCK_NEED_RELOAD:
        ; hstwrt: if the outgoing host buffer is dirty, flush it first
        LD A,(DISK_HSTWRT)
        OR A
        ; flush the dirty host buffer before reloading
        CALL NZ,CONFIG_PROBE
DEBLOCK_SETUP_RWTS:
        LD A,(DISK_SEKDSK)
        LD (DISK_SEKDSK+1),A
        LD B,A
        AND $01
        INC A
        ; Apple $03E4 = RWTS unit/volume cell
        LD ($F3E4),A
        LD A,B
        AND $0E
        ADD A,A
        ADD A,A
        ADD A,A
        CPL
        ADD A,$61
        ; Apple $03E6 = RWTS track cell
        LD ($F3E6),A
        LD A,(BOOT)
        LD L,A
        LD H,C
        ; Apple $03E0 = record the host buffer's new track/sector
        LD ($F3E0),HL
        ; rsflag: nonzero -> physically pre-read the host sector
        LD A,(DISK_WRTYPE+1)
        OR A
        ; perform the host sector read (RWTS read entry)
        CALL NZ,CONIO_SET_A1
        XOR A
        ; hstwrt = 0 after a fresh read
        LD (DISK_HSTWRT),A
DEBLOCK_COPY_RECORD:
        LD A,E
        ; z80 $F800 = Apple $0800 host sector buffer base
        LD HL,$F800
        RRA
        ; select the upper/lower 128-byte half of the host sector from the record's parity
        RR L
        ; dmaadr = the CP/M record buffer
        LD DE,(DISK_DMAADR)
        ; 128-byte CP/M record length
        LD BC,$0080
        ; readop: nonzero = read (host->DMA), zero = write (DMA->host)
        LD A,(DISK_HSTWRT+1)
        OR A
        JR NZ,DEBLOCK_COPY
        INC A
        LD (DISK_HSTWRT),A
        ; write direction: swap so LDIR copies DMA -> host buffer
        EX DE,HL
DEBLOCK_COPY:
        ; copy the 128-byte record host<->DMA
        LDIR
        ; wrtype: bit 0 decides whether a write must flush immediately (directory write)
        LD A,(DISK_WRTYPE)
        RRA
        LD A,$00
        RET NC
        ; immediate flush of the dirty host buffer
        CALL CONFIG_PROBE
        RET
; ----------------------------------------------------------------------
; CONFIG_PROBE -- re-detect the console device and reset the deblock state.
;   In:  none (reads the SoftCard config/IOBYTE cells in Apple page $03).
;   Out: none. Clobbers: A,HL,DE.
;   Algorithm: clear the host-sector-active flag (PATCH_LDA_HSTACT operand cell),
;              default A=2, then via the CONIO_SET_A1 cover entry set the console
;              selector at $F3EB=Apple $03EB and probe the device through RPC_TRIGGER.
;              If the probe returns a non-zero device class (==$10) it pops the
;              return address and tail-jumps through the vector at $9C0D. Called
;              at cold boot (from BOOT path) and on a disk-select change. [RE]
; ----------------------------------------------------------------------
CONFIG_PROBE:
        XOR A
        ; clear the host-active deblock flag (this LD A operand cell doubles as the disk hstact var)
        LD (DISK_HSTWRT),A
        LD A,$02
        DEFB    $21                      ; cover (LD HL,nn opcode): on fall-through absorbs the
                                         ;        LD A,$01 below, leaving A=$02 from $AE77
CONIO_SET_A1:
        LD A,$01                         ; CALL'd directly -> A=$01 (cover-skipped on fall-through)
        ; store the console-selector index into the SoftCard config block (Apple $03EB)
        LD ($F3EB),A
        LD HL,$0E03
        ; probe/init the selected console device handler
        CALL RPC_TRIGGER
        ; read the detected device-class byte from the config block (Apple $03EA)
        LD A,($F3EA)
        OR A
        ; no special device class -> done
        RET Z
        POP DE
        ; device class $10 -> dispatch through the installed handler vector
        CP $10
        RET NZ
        ; fetch the handler entry from the CCP/loader vector cell and tail-jump to it [RE]
        LD HL,($9C0D)
        JP (HL)
; ----------------------------------------------------------------------
; SECTOR_XLATE -- 16-entry logical->physical sector skew table (a 0..15 permutation).
;   Indexed by the deblock code (LD A,L add-offset lookup) to translate a CP/M logical
;   sector to the physical RWTS sector. DATA, not code.
; ----------------------------------------------------------------------
SECTOR_XLATE:
        ; 16-entry logical->physical sector skew table (a 0..15 permutation),
        ; indexed during disk deblock (DEV_HANDLER_LOOKUP-style *1 byte lookups).
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A
        DEFB    $04,$0D,$07,$08,$02,$0B,$05,$0E
; ----------------------------------------------------------------------
; COL_FLAG -- console-output entry/expand flag (0 or $FF), set by CONOUT_FILTER and
;   tested by SCREEN_EMIT to pick the physical output vector. Immediately followed by
;   COL_PENDING at A3-adjacent cells. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_FLAG:
        DEFB    $00                      ; disk scratch byte
; ----------------------------------------------------------------------
; COL_PENDING -- pending column-skip / fill counter for console output, also reused as a
;   mode byte (set to 2 by TAB_EXPAND_DONE). Decremented as columns are consumed.
;   Accessed as COL_FLAG+1 in CONOUT_FILTER. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_PENDING:
        DEFB    $00                      ; disk scratch byte
; ----------------------------------------------------------------------
; COL_STATE -- sticky control/escape state for tab expansion; armed to $80 on a trigger-
;   char match and cleared by SCREEN_EMIT. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_STATE:
        DEFB    $00                      ; disk scratch byte
; ----------------------------------------------------------------------
; SCREEN_CURSOR_PTR -- 2-byte pointer cell used by the screen routines (initialized to
;   point at SCREEN_CHAR / SCREEN_CHAR). Loaded and re-stored by PUT_CHAR_STORE while reading
;   the Apple cursor base ($F028) and column ($F024) to compute the on-screen cell. [RE]
; ----------------------------------------------------------------------
SCREEN_CURSOR_PTR:
        DEFW    SCREEN_CHAR              ; pointer cell (init -> SCREEN_CHAR)
; ----------------------------------------------------------------------
; SCREEN_CHAR -- saved on-screen character byte (the cell SCREEN_CURSOR_PTR points at by
;   default); written back to the screen with format bits applied. Scratch byte, init $00.
;   [RE]
; ----------------------------------------------------------------------
SCREEN_CHAR:
        DEFB    $00                      ; disk scratch byte
; ----------------------------------------------------------------------
; BOOT -- CP/M cold-boot BIOS entry (jump-vector $AA00 lands here via $AA00->$AEA8).
;   In:  none. Out: does not return through here (falls into the install engine).
;   Clobbers: all.
;   DUAL USE of the first 3 bytes: the opcode bytes of this 'LD SP,$0100' instruction
;   are TEMPORALLY REUSED after boot as disk-deblock cells. BOOT+1/BOOT+2 (the $00,$01
;   immediate-operand bytes) hold the current track / current sector during operation:
;   SETSEC writes BOOT+1 (seksec), HOME/HOME-path writes BOOT (sektrk low), and the
;   WRITE/READ deblock logic and READ_SEKSEC read BOOT/BOOT+1. They are valid SP-init
;   bytes only during the single cold-boot pass; thereafter they are scratch, never
;   re-executed. [RE]
;   Algorithm: set the Z-80 stack, then fall through into the self-modifying install
;   engine (PATCH_* cells) that writes the per-config operands into the running BIOS.
; ----------------------------------------------------------------------
BOOT:
        ; init Z-80 stack; these 3 bytes are reused post-boot as the disk sektrk/seksec deblock
        ; cells (BOOT=track, BOOT+1=sector)
        LD SP,$0100
; ----------------------------------------------------------------------
; DISK_SELDSK_SAVE -- (boot install template 'LD A,$C9'); +1 byte reused as SELDSK scratch.
;   At cold boot this is the install engine's 'LD A,$C9' template. After boot SELDSK
;   stores the previously-selected drive (page-zero $0004) into DISK_SELDSK_SAVE+1,
;   then the disk number into DISK_SEKDSK (the next cell). [RE]
; ----------------------------------------------------------------------
DISK_SELDSK_SAVE:
        LD A,$C9
; ----------------------------------------------------------------------
; DISK_SEKDSK -- CP/M-requested disk number (DRI deblock 'sekdsk'); +1/+2 = hstdsk/hstact.
;   Boot tenant: install template 'LD (nn),A' (operand runtime-patched). Operational
;   tenant: SELDSK stores the selected disk number here; DISK_SEKDSK+1 = host disk
;   (hstdsk [RE]); DISK_SEKDSK+2 = host-buffer-active flag (hstact), cleared by WBOOT/
;   HOME and the deblock, set when a host sector is staged. [RE]
; ----------------------------------------------------------------------
DISK_SEKDSK:
        LD (BIOS_VECTOR),A
; ----------------------------------------------------------------------
; DISK_HSTWRT -- host-buffer-dirty flag (DRI deblock 'hstwrt' [RE]); +1 = readop [RE].
;   Boot tenant: install template 'LD A,$95' (the default IOBYTE immediate). Operational
;   tenant: a deblock flag the WRITE path sets and the host-flush test reads;
;   DISK_HSTWRT+1 is the read/seek scratch the READ/WRITE deblock loads. [RE]
; ----------------------------------------------------------------------
DISK_HSTWRT:
        LD A,$95
; ----------------------------------------------------------------------
; DISK_WRTYPE -- deblock write type (DRI 'wrtype' [RE]); +1 = rsflag, +2 = unacnt.
;   Boot tenant: install template 'LD ($0003),A' (stores the default IOBYTE). Operational
;   tenant: DISK_WRTYPE+1 = read-sector-needed flag (rsflag); DISK_WRTYPE+2 = unallocated
;   record count (unacnt), seeded to 8 on a directory-extending write and decremented
;   by the WRITE deblock loop. [RE]
; ----------------------------------------------------------------------
DISK_WRTYPE:
        LD ($0003),A
; ----------------------------------------------------------------------
; DISK_UNADSK -- unallocated-run disk (DRI 'unadsk' [RE]); +1/+2 = unatrk/unasec.
;   Boot tenant: install template 'LD HL,(nn)'. Operational tenant: the unallocated
;   write run's position. DISK_UNADSK+1 (unatrk) and +2 (unasec) are seeded from the
;   CP/M-requested track/sector (BOOT/BOOT+1) and advanced as the run is written. [RE]
; ----------------------------------------------------------------------
DISK_UNADSK:
        LD HL,($F3DE)
; ----------------------------------------------------------------------
; DISK_DMAADR -- current DMA buffer address (DRI deblock 'dmaadr').
;   Boot tenant: install template 'LD (nn),HL' (patches a console/IO operand at boot).
;   Operational tenant: SETDMA stores BC here; the deblock record copy uses it as the
;   CP/M 128-byte record source/destination.
; ----------------------------------------------------------------------
DISK_DMAADR:
        LD (RPC_TRIGGER_STORE+1),HL
        XOR A
        LD ($0004),A
        LD A,($F3BB)
        CP $05
        JR NC,CONFIG_PROBE_16
        SUB $03
        JR C,CONFIG_PROBE_16
        JR NZ,CONFIG_PROBE_15
        LD HL,$1FB0
        LD (KBD_STATUS_40COL+2),HL
CONFIG_PROBE_15:
        PUSH AF
        CALL DEV_HANDLER_LOOKUP
        POP AF
        LD (PUT_CHAR_VECTOR+1),HL
        CALL DEV_HANDLER_LOOKUP_B
        LD (CONIN_DISPATCH+1),HL         ; patch the CONIN keyboard-wait vector
        LD A,$03
        LD (CCP_MODE_FLAG+1),A
CONFIG_PROBE_16:
        LD A,($F3B9)
        SUB $03
        JR C,CONFIG_PROBE_17
        CALL DEV_HANDLER_LOOKUP
        LD (DEV_OUT_1_JP+1),HL           ; patch the DEV_OUT_1 vector
        LD E,$80
CONFIG_PROBE_17:
        LD A,($F3BA)
        SUB $03
        JR C,CONFIG_PROBE_18
        PUSH AF
        CALL DEV_HANDLER_LOOKUP
        LD (DEV_OUT_2_JP+1),HL           ; patch the DEV_OUT_2 vector
        POP AF
        CP $02
        JR NC,CONFIG_PROBE_18
        CALL DEV_HANDLER_LOOKUP_B
        LD (DEV_OUT_3_JP+1),HL           ; patch the DEV_OUT_3 jump target
        JR CONFIG_PROBE_19
CONFIG_PROBE_18:
        LD HL,$1A3E
        LD (DEV_OUT_3_JP),HL             ; build DEV_OUT_3's instruction (opcode+lo)
        LD A,$C9
        LD (DEV_OUT_3_JP+2),A            ; build DEV_OUT_3's instruction (hi byte)
CONFIG_PROBE_19:
        LD A,($F381)
        OR A
        JR NZ,CONFIG_PROBE_20
        LD HL,IO_VECTOR_DEFAULTS
        LD DE,$F380
        LD BC,$0016
        LDIR
CONFIG_PROBE_20:
        CALL PROBE_DEVICES
        LD A,($F398)
        CALL SIGNON_EMIT
        LD A,($F39B)
        CALL SIGNON_EMIT
        LD HL,SIGNON_BANNER
CONFIG_PROBE_21:
        LD A,(HL)
        OR A
        JP Z,PAGEZERO_REBUILD
        PUSH HL
        CALL CONOUT_DISPATCH
        POP HL
        INC HL
        JR CONFIG_PROBE_21
; ----------------------------------------------------------------------
; DEV_HANDLER_PTRS -- DEFW table of disk read/write handler addresses (primary group),
;   indexed by DEV_HANDLER_LOOKUP. Continues as DEV_HANDLER_PTRS_B (+6). DATA.
;   Each entry should relocate from a literal address to the named target:
;     [0] $ACDF -> DISK_RD_HANDLER_A  (CALL SLOT_IO_ADDR sector-bit read handler in the
;         CTRL_HANDLER_OFFSET_TBL data/code region)
;     [1] $AD04 -> PLOT_CHAR_AT_COL        (named handler just below)
;     [2] $AD31 -> DISK_WR_HANDLER_B (handler tail in the $AD22 data/code region)
;   and DEV_HANDLER_PTRS_B holds:
;     [0] $AD12 -> DISK_RD_HANDLER_B (RRA bit-test read handler at the $AD12 block)
;     [1] $AD1C -> DISK_WR_HANDLER_A (CALL SET_SCREEN_BASE write handler in the $AD22 block)
;   See flags: these targets currently sit inside DEFB blocks (CTRL_HANDLER_OFFSET_TBL / $AD12 /
;   $AD22)
;   that are really handler CODE, so the relocations need those blocks named first.
; ----------------------------------------------------------------------
DEV_HANDLER_PTRS:
        ; table of device-handler addresses (DEFW). DEV_HANDLER_LOOKUP indexes from
        ; here; DEV_HANDLER_LOOKUP_B indexes from DEV_HANDLER_PTRS_B (+6). Selected per config
        ; by CONFIG_PROBE to install the right console/disk handler into the vector slots.
        DEFW    DEV_STROBE_RD            ; [0]
        DEFW    PLOT_CHAR_AT_COL         ; [1]
        DEFW    DEV_WR_BIT               ; [2]
DEV_HANDLER_PTRS_B:
        DEFW    DEV_READ_BIT             ; DEV_HANDLER_LOOKUP_B base
        DEFW    DEV_OUT_RPC
; ----------------------------------------------------------------------
; DEV_HANDLER_LOOKUP_B -- fetch a disk-handler address from DEV_HANDLER_PTRS_B[A].
;   In:  A = entry index (0-based). Out: HL = handler address. Clobbers: A,HL.
;   Algorithm: point HL at DEV_HANDLER_PTRS_B then fall into the shared index loader
;   (HL += A*2; HL = word at that slot). Used by CONFIG_PROBE to install the per-config
;   read/write handler addresses. [RE]
; ----------------------------------------------------------------------
DEV_HANDLER_LOOKUP_B:
        ; select the secondary handler-pointer table
        LD HL,DEV_HANDLER_PTRS_B
        JR DISK_RTN_LOOKUP_IDX
; ----------------------------------------------------------------------
; DEV_HANDLER_LOOKUP -- fetch a disk-handler address from DEV_HANDLER_PTRS[A].
;   In:  A = entry index (0-based). Out: HL = handler address. Clobbers: A,HL.
;   Algorithm: HL = base; HL += A*2 (ADD A,A; ADD A,L; LD L,A); HL = the 16-bit word
;   at that slot (low then high). Shared tail of DEV_HANDLER_LOOKUP_B. [RE]
; ----------------------------------------------------------------------
DEV_HANDLER_LOOKUP:
        ; select the primary handler-pointer table
        LD HL,DEV_HANDLER_PTRS
DISK_RTN_LOOKUP_IDX:
        ; index*2 for 16-bit (word) table entries
        ADD A,A
        ADD A,L
        LD L,A
        ; load handler address low byte
        LD A,(HL)
        INC L
        ; load handler address high byte -> HL = handler entry
        LD H,(HL)
        LD L,A
        RET
; ----------------------------------------------------------------------
; SIGNON_EMIT -- emit one sign-on byte, optionally preceded by a fixed prefix char.
;   In:  A = byte/flag. Out: none (prints via CONOUT_DISPATCH=CONOUT-class writer).
;   Algorithm: if A is positive (bit7 clear) just print it; if negative, first print
;   the prefix char from the config block (Apple $0397) then print A. Called twice from
;   the boot path to emit two config-derived sign-on chars before the banner. [RE]
; ----------------------------------------------------------------------
SIGNON_EMIT:
        OR A
        ; bit7 clear -> emit the char directly
        JP P,SIGNON_EMIT_CHAR
        PUSH AF
        ; negative flag: fetch the prefix char from the config block (Apple $0397)
        LD A,($F397)
        ; emit the prefix char
        CALL CONOUT_DISPATCH
        POP AF
SIGNON_EMIT_CHAR:
        ; tail-call to emit the original char
        JP CONOUT_DISPATCH
; ----------------------------------------------------------------------
; SIGNON_BANNER -- the cold-boot sign-on string, printed char-by-char by the boot path
;   (loop at CONFIG_PROBE_21) until the $00 terminator. Reads:
;   'Apple ][ CP/M' / '44K Ver. 2.20' / '(C) 1980 Microsoft', CR/LF separated. DATA.
; ----------------------------------------------------------------------
SIGNON_BANNER:
        DEFB    "\r\n\r\n\r\n"
        DEFB    "Apple ][ CP/M"          ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n"
        DEFB    "44K Ver. 2.20"          ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n"
        DEFB    "(C) 1980 Microsoft"     ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n\r\n\0"
; ----------------------------------------------------------------------
; IO_VECTOR_DEFAULTS -- 22-byte (BC=$0016) DATA table of default I/O handler pointers,
;   copied by the boot path (LDIR) into the SoftCard config/vector page at $F380=Apple
;   $0380 when that page is uninitialized ($F381==0). The first 22 bytes are eleven
;   little-endian addresses ($AB0C,$AB12,$AB12,$AC3E,$AC3E,$AD45,$AD45,$AD3F,$AD3F,
;   $AD2B,$AD2B) mirroring console/list/punch/reader/disk handler entry points; only
;   those 22 bytes are copied. This is a DATA pointer table, not relocated code. The
;   bytes past offset 22 ($AFC4 onward) coincidentally re-mirror nearby handler code
;   but are NOT executed from here. [RE] -- see flags.
; ----------------------------------------------------------------------
IO_VECTOR_DEFAULTS:
        DEFW    KBD_STATUS_40COL         ; CONST (40-col keyboard status)
        DEFW    CONSOLE_IN_40COL         ; CONIN
        DEFW    CONSOLE_IN_40COL
        DEFW    PUT_CHAR_DE3             ; CONOUT
        DEFW    PUT_CHAR_DE3
        DEFW    DEV_OUT_3                ; LIST/PUNCH/READER stubs
        DEFW    DEV_OUT_3
        DEFW    DEV_OUT_2
        DEFW    DEV_OUT_2
        DEFW    DEV_OUT_1
        DEFW    DEV_OUT_1
        ; $AFC4-$AFEF: an in-image second copy of the DEV_HANDLER_PTRS table + the
        ; DEV_HANDLER_LOOKUP / SIGNON_EMIT routines (byte-identical to $AF4A-$AF6F);
        ; not referenced or executed from here. [RE]
        DEFB    $42,$AB,$E1,$23,$18,$F3,$DF,$AC,$04,$AD,$31,$AD,$12,$AD,$1C,$AD
        DEFB    $21,$50,$AF,$18,$03,$21,$4A,$AF,$87,$85,$6F,$7E,$2C,$66,$6F,$C9
        DEFB    $B7,$F2,$70,$AF,$F5,$3A,$97,$F3,$CD,$42,$AB,$F1
; ----------------------------------------------------------------------
; READ_SEKSEC -- load the current deblock sector and set flags.
;   In:  none. Out: A = current sector (from BOOT+1=seksec); Z set if sector==0.
;   Clobbers: A. Called by the READ/WRITE deblock path to test/translate the sector.
;   Note BOOT+1 is the post-boot reuse of the BOOT 'LD SP,$0100' operand byte. [RE]
; ----------------------------------------------------------------------
READ_SEKSEC:
        ; read the current deblock sector (BOOT+1 reused as seksec)
        LD A,(BOOT+1)
        ; set Z/sign flags on the sector value for the caller
        OR A
        RET
        DEFB    "\r\n\r\nApple ]"

    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $AA00, $0600
    ENDIF
