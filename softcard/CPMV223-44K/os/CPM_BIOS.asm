; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- BIOS, RUNTIME-ADDRESSED (de-skewed)
; ----------------------------------------------------------------------------
; The 2.23-44K BIOS runs at z80 $FA00-$FFFF (6 pages) = Apple $0A00-$0FFF LOW RAM
; (NOT $AA00 like 2.20 -- a different mechanism). Decoded against the de-skewed
; runtime image; the disk producer re-applies the sector skew (deskew.py ::
; BIOS_PAGE_TO_SECTOR_223). $FA00 = the 15-entry BIOS jump vector.
; DECODE IN PROGRESS: --auto-coverage --relocatable disassembly (byte-identical),
; being enriched to the C-level bar.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ORG $FA00
    ENDIF

; ----------------------------------------------------------------------
; BIOS_VECTOR -- the CP/M 2.2 BIOS entry jump vector (2.23-44K, runtime $FA00).
;   15 three-byte JP entries the BDOS/CCP and the cold loader call by fixed
;   offset from the BIOS base: BOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH,
;   READER, HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE.
;   In:  entered by JP/CALL to base+3*n.  Out: per the dispatched entry.
;   Note: the CONOUT target ($FB4D) is the second-instruction entry of
;         CONOUT_DISPATCH (skips its leading LD C,A); see flags. [RE]
; ----------------------------------------------------------------------
BIOS_VECTOR:
        ; entry 0 = cold boot (BOOT, lives in the $FE85 band, out of this scope)
        JP BOOT
; ----------------------------------------------------------------------
; BIOS_VECTOR_WBOOT -- jump-table entries 1..14 (WBOOT .. WRITE).
;   Same 14-entry layout as the 2.20-44K twin; only the target addresses move
;   ($FA-band, not $AA). CONOUT ($FA0C) targets CONOUT_DISPATCH+1 ($FB4D). [RE]
; ----------------------------------------------------------------------
BIOS_VECTOR_WBOOT:
        ; jump table
        ; entry 1 = WBOOT: reload CCP, rebuild page zero
        JP      WBOOT
        ; entry 2 = CONST: console status via IOBYTE
        JP      CONST
        ; entry 3 = CONIN: dispatch + function/arrow remap
        JP      CONIN
        ; entry 4 = CONOUT; target CONOUT_DISPATCH+1 (skips its leading LD C,A)
        JP      $FB4D
        ; entry 5 = LIST: route by IOBYTE LIST field
        JP      LIST
        ; entry 6 = PUNCH: route by IOBYTE PUNCH field
        JP      PUNCH
        ; entry 7 = READER: route by IOBYTE READER field
        JP      READER
        ; entry 8 = HOME (out of this scope, $FDB0 band)
        JP      HOME
        ; entry 9 = SELDSK (out of this scope, $FE85 band)
        JP      SELDSK
        ; entry 10 = SETTRK (out of this scope, $FE77)
        JP      $FE77
        ; entry 11 = SETSEC: store sector into deblock scratch
        JP      SETSEC
        ; entry 12 = SETDMA: store DMA address into deblock scratch
        JP      SETDMA
        ; entry 13 = READ (out of this scope, $FE85 band)
        JP      READ
        ; entry 14 = WRITE (out of this scope, $FE85 band)
        JP      WRITE
        ; post-vector trailer = XOR A / RET / DW $6000 / RET; same 6 bytes as 2.20's $AA2D. See
        ; flags.
        DEFB    $AF,$C9,$00,$60,$69,$C9
; ----------------------------------------------------------------------
; DPH_TABLE -- the CP/M 2.2 Disk Parameter Header array (one 16-byte DPH per logical
;   drive 0..3; 2.23 supports 4 drives, vs 6 in the 2.20 twin). SELDSK returns
;   DPH_TABLE + 16*drive. Each DPH = XLT, three BDOS scratch words, DIRBUF, DPB, CSV,
;   ALV. XLT = 0 (no SECTRAN translate). All drives share one DIRBUF ($FEE4, in the
;   install/deblock band) and one DPB. The per-drive CSV (checksum) / ALV (allocation)
;   vectors live in the BIOS's $FF RAM, reused as scratch after boot; kept literal. [RE]
; ----------------------------------------------------------------------
DPH_TABLE:
        DEFW    0,0,0,0,$FEE4,DPB,$FFAC,$FF64   ; drive 0: DIRBUF, DPB, CSV=$FFAC, ALV=$FF64
        DEFW    0,0,0,0,$FEE4,DPB,$FFB8,$FF76   ; drive 1
        DEFW    0,0,0,0,$FEE4,DPB,$FFC4,$FF88   ; drive 2
        DEFW    0,0,0,0,$FEE4,DPB,$FFD0,$FF9A   ; drive 3
; DPB -- the shared Disk Parameter Block (5.25" floppy; every DPH points here).
;   DSM = 139 here vs the 2.20 twin's 127 (a slightly larger usable capacity).
DPB:
        DEFW    $0020                    ; SPT = 32 sectors (128-byte records) per track
        DEFB    $03,$07                  ; BSH=3, BLM=7 -> 1 KB allocation blocks
        DEFB    $00                      ; EXM = 0
        DEFW    $008B                    ; DSM = 139 (140 blocks => 140 KB capacity)
        DEFW    $002F                    ; DRM = 47 (48 directory entries)
        DEFB    $C0,$00                  ; AL0/AL1 -> 2 directory-reserved blocks
        DEFW    $000C                    ; CKS = 12 (directory checksum bytes)
        DEFW    $0003                    ; OFF = 3 reserved (system) tracks
; ----------------------------------------------------------------------
; PROBE_DEVICES -- scan the SoftCard device/config area and mark presence.
;   In:  none (walks Apple $03B8.. via z80 $F3B8 = the SoftCard config block).
;   Out: config bytes updated in place; per-device init called when a device is found.
;   Clobbers: A,DE,HL.
;   Algorithm: for E = 7 down to 1, read config[$F3B8 + E].  If it equals 3 the slot
;     holds a recognized device, so call SLOT_IO_INIT and store $03 then $15 into the
;     cell to flag it configured.  A secondary DEC A test (original value 4, e.g. a
;     Videx-class 80-col console) runs SET_SCREEN_BASE and claims the $C800 shared
;     expansion-ROM window via RPC_TRIGGER; a value-2 path repoints a vector via
;     SUB_FDB0 ($0DD0 param).  Same shape as the 2.20 twin's PROBE_DEVICES. [RE]
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
        ; build the slot I/O base for the found device (SLOT_IO_INIT)
        CALL SLOT_IO_ADDR
        ; rewrite the cell: $03 then $15 = mark this device configured
        LD (HL),$03
        LD (HL),$15
PROBE_DEVICES_CHK4:
        ; after the SUB, A==1 means the original value was 4 (Videx-class 80-col console)
        DEC A
        JR NZ,PROBE_DEVICES_CHK2
        ; console probe / select the 80-col screen base (SET_SCREEN_BASE)
        CALL SUB_FD83
        ; z80 $C800 = Apple $C800 shared expansion-ROM window for the configured card
        LD HL,$C800
        CALL RPC_TRIGGER
        JR PROBE_DEVICES_NEXT
PROBE_DEVICES_CHK2:
        ; value 2 = a different device class (e.g. printer/serial); takes the SUB_FDB0 path
        CP $02
        JR NZ,PROBE_DEVICES_NEXT
        ; param for the value-2 vector init ($0DD0)
        LD HL,$0DD0
        CALL SUB_FDB0
PROBE_DEVICES_NEXT:
        ; next config entry; loop until all 7 scanned
        DEC E
        JR NZ,PROBE_DEVICES_LOOP
        RET
; ----------------------------------------------------------------------
; SLOT_IO_ADDR -- form a SoftCard I/O / soft-switch address from a slot/offset index.
;   In:  E = low offset within the I/O page.
;   Out: HL = $E0(E | $E0), an address in z80 $E000-$EFFF = Apple I/O $C000-$CFFF;
;        A clobbered.
;   Algorithm: H = $E0 base; A = E OR H forces the high nibble into the $C0xx I/O
;        page, then H = A.  Used to reach keyboard / soft switches / slot I/O.
;        Same as the 2.20 twin's DEVICE_IO_BASE. [RE]
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
; WBOOT -- CP/M warm boot: re-init the console, rebuild page zero, re-enter the CCP.
;   In:  none.  Out: jumps to the CCP at $9300; does not return.  Clobbers: all.
;   Algorithm: set SP to the default DMA top ($0080); touch the 80-col soft switch
;     (z80 $E051 = Apple $C051 TXTSET); re-init the console via RPC_TRIGGER; re-run
;     PROBE_DEVICES.  If the CCP image signature at $9C08 is intact ($9C) it falls
;     into PAGEZERO_REBUILD; otherwise it reloads the CCP/system via a page-zero JP.
;   Note: 2.23 reloads through a self-built $000B jump and enters the CCP at $9300
;     (the 2.20 twin used $9400). [RE]
; ----------------------------------------------------------------------
WBOOT:
        ; stack at the default DMA buffer top (page-zero $0080)
        LD SP,$0080
        ; z80 $E051 = Apple $C051 TXTSET soft switch (console video reset)
        LD A,($E051)
        LD HL,$0E00
        ; re-init the console I/O vectors (RPC_TRIGGER) for warm restart
        CALL RPC_TRIGGER
        ; re-scan devices so warm boot rebuilds the I/O table
        CALL PROBE_DEVICES
        ; read the CCP-image signature byte at $9C08
        LD A,($9C08)
        ; signature $9C present = CCP image intact, skip the reload
        CP $9C
        JR Z,PAGEZERO_REBUILD
        LD HL,SIGNON_PRINT
        LD ($F3D0),HL
        LD HL,($F3DE)
        LD A,$77
        ; plant a $77 byte at page-zero $000B to bridge into the reload path
        LD ($000B),A
        ; jump into the self-built page-zero reload bridge
        JP $000B
; ----------------------------------------------------------------------
; PAGEZERO_REBUILD -- clear the CCP-restart flag, then write the page-zero hooks.
;   In:  none.  Out: falls into CCP_LAUNCH; no return.  Clobbers: A,HL,BC.
;   Algorithm: zero the CCP restart flag at $9307, then (PAGEZERO_REBUILD_HOOKS)
;     plant JP ($C3) at $0000 -> the BIOS WBOOT entry (BIOS_VECTOR+3, BIOS_VECTOR_WBOOT) and
;     JP at $0005 -> the BDOS entry $9C06; clear two self-modified BIOS state cells
;     ($FEDD/$FED8); set the default DMA to $0080 via SETDMA. [RE]
; ----------------------------------------------------------------------
PAGEZERO_REBUILD:
        XOR A
        ; clear the CCP restart/cold flag at $9307
        LD ($9307),A
PAGEZERO_REBUILD_HOOKS:
        XOR A
        ; clear a self-modified BIOS state cell ($FEDD)
        LD (BOOT_TMPL_IOBYTE),A
        ; clear a self-modified BIOS state cell ($FED8)
        LD (DISK_HSTACT),A
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
        ; install the default DMA pointer (SETDMA)
        CALL SETDMA
; ----------------------------------------------------------------------
; CCP_LAUNCH -- final warm/cold-boot tail: set the CCP entry flag, jump to the CCP.
;   In:  none.  Out: JP $9300 (CCP cold/warm entry); no return.  Clobbers: A,C.
;   Algorithm: store a CCP-mode flag ($01) into $974E, pass the current default
;     drive (page-zero $0004) in C, and jump to the CCP at $9300. [RE]
; ----------------------------------------------------------------------
CCP_LAUNCH:
        ; CCP-mode flag value
        LD A,$01
        ; store the CCP entry/mode flag into CCP workspace at $974E
        LD ($974E),A
        ; page-zero $0004 = current default drive byte
        LD A,($0004)
        LD C,A
        ; enter the CCP at $9300, C = default drive (2.20 used $9400)
        JP $9300
; ----------------------------------------------------------------------
; CONST -- CP/M console status: return $FF if a console char is ready, else $00.
;   In:  none.  Out: A = $FF (ready) / $00 (not).  Clobbers: A,HL.
;   Algorithm: load the console-status handler address from the SoftCard I/O vector
;     cell (z80 $F380 = Apple $0380) and JP (HL) to the 6502-serviced handler, which
;     returns the status in A.  Same as the 2.20 twin's CONST. [RE]
; ----------------------------------------------------------------------
CONST:
        ; z80 $F380 = Apple $0380 = console-status handler vector cell
        LD HL,($F380)
        ; dispatch to the selected console-status handler (returns A)
        JP (HL)
; ----------------------------------------------------------------------
; KBD_STATUS_40COL -- 40-column console status via the Apple keyboard strobe.
;   In:  none.  Out: A = $FF if a key is waiting (bit 7 set at $C000), else $00.
;   Clobbers: A.
;   Algorithm: read z80 $E000 = Apple $C000 keyboard register; RLA shifts bit 7
;     (key-ready) into carry; SBC A,A expands carry to $FF/$00.  The built-in 40-col
;     CONST path used when no Videx/80-col card supplies the status vector. [RE]
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
; CONIN -- read a console character: IOBYTE-route the input, then remap the key.
;   In:  none.  Out: A = (translated) key.  Clobbers: A,B,C,DE,HL.
;   Algorithm: CALL CONIN_DISPATCH to fetch a raw key (routed by the IOBYTE CONSOLE
;     field); clear the high bit; then scan a small remap table at Apple $03AB
;     (z80 $F3AB) of up to 6 entries (function/arrow keys), returning the paired
;     replacement byte on a match, else the raw key.
;   Note: 2.23's CONIN jump-vector entry runs this remap wrapper; the 2.20 twin's
;     equivalent is CONSOLE_IN_40COL.  Differs from a bare dispatcher. [RE]
; ----------------------------------------------------------------------
CONIN:
        ; fetch a raw key in A via the IOBYTE-routed CONIN dispatcher
        CALL CONIN_DISPATCH_IOBYTE
        ; strip the high bit (7-bit ASCII)
        AND $7F
        ; HL = key-remap table base (z80 $F3AB = Apple $03AB; first entry pair at $03AC)
        LD HL,$F3AB
        ; up to 6 remap-table entries
        LD B,$06
        ; C = raw key
        LD C,A
; ----------------------------------------------------------------------
; CONIN_XLATE_LOOP -- scan the function/arrow-key remap table.
;   In:  C = raw key; B = entry count; HL -> table base.
;   Out: A = translated key on match (returns), else loops; A = C on table end.
;   Algorithm: each entry = [match byte, replacement byte]; a high-bit sentinel
;     match byte ends the table. [RE]
; ----------------------------------------------------------------------
CONIN_XLATE_LOOP:
        INC HL
        ; entry's match byte
        LD A,(HL)
        INC HL
        OR A
        ; high-bit sentinel ends the table
        JP M,CONIN_XLATE_DONE
        ; raw key == this entry?
        CP C
        ; paired replacement byte
        LD A,(HL)
        ; match -> return the translated key
        RET Z
        DJNZ CONIN_XLATE_LOOP
; ----------------------------------------------------------------------
; CONIN_XLATE_DONE -- no remap match: return the raw key in A. [RE]
; ----------------------------------------------------------------------
CONIN_XLATE_DONE:
        ; no match -> return the raw key
        LD A,C
        RET
; ----------------------------------------------------------------------
; CONIN_KEYWAIT -- seed the keyboard-wait dispatch index, then wait for a key.
;   In:  none.  Out: A = 7-bit key (via KBD_WAIT_KEY).  Clobbers: A,DE.
;   Algorithm: load DE = 3 (the default console index), then JP through the
;     self-modified CONIN_DISPATCH cell; at boot that target is patched to the
;     selected keyboard-wait handler (default KBD_WAIT_KEY). [RE]
; ----------------------------------------------------------------------
CONIN_KEYWAIT:
        ; DE = 3 = default console-device index
        LD DE,$0003
; ----------------------------------------------------------------------
; CONIN_DISPATCH -- self-modified keyboard-wait vector.
;   The JP target ($FB39 / KBD_WAIT_KEY by default) is patched at boot per the
;   selected console card.  Referenced as CONIN_DISPATCH+1 by the patch site. [RE]
; ----------------------------------------------------------------------
CONIN_DISPATCH:
        ; target (CONIN_DISPATCH+1) patched at boot to the chosen keyboard-wait handler
        JP KBD_WAIT_KEY
; ----------------------------------------------------------------------
; KBD_WAIT_KEY -- spin on the Apple keyboard register until a key is down.
;   In:  none.  Out: A = 7-bit key (high bit cleared).  Clobbers: A.
;   Algorithm: poll z80 $E000 = Apple $C000; RLA puts key-ready (bit 7) into carry,
;     spin while clear; on a key, clear the strobe at $E010 = Apple $C010 and return
;     the 7-bit key (CCF/RRA). [RE]
; ----------------------------------------------------------------------
KBD_WAIT_KEY:
        ; poll z80 $E000 = Apple $C000 keyboard register
        LD A,($E000)
        ; key-ready (bit 7) -> carry
        RLA
        ; spin until a key is down
        JR NC,KBD_WAIT_KEY
        ; clear the keyboard strobe (z80 $E010 = Apple $C010)
        LD ($E010),A
        CCF
        ; A = 7-bit key
        RRA
        RET
; ----------------------------------------------------------------------
; RPC_TRIGGER -- fire a SoftCard 6502<->Z80 RPC.
;   In:  HL = command/params; A = trigger value.  Out: per the 6502 service routine.
;   Algorithm: stash HL to the command mailbox (z80 $F3D0 = Apple $03D0), then poke
;     the trigger cell.  The trigger store-address ($0000 here) is self-modified per
;     config at boot, so the store site is RPC_TRIGGER_STORE+1. [RE]
; ----------------------------------------------------------------------
RPC_TRIGGER:
        ; z80 $F3D0 = Apple $03D0 = RPC command/params mailbox
        LD ($F3D0),HL
RPC_TRIGGER_STORE:
        LD ($0000),A
        RET
; ----------------------------------------------------------------------
; CONOUT_DISPATCH -- emit a console character, routed by the CP/M IOBYTE.
;   In:  A = character (the BIOS CONOUT arg).  The jump-vector CONOUT entry targets
;        CONOUT_DISPATCH+1 ($FB4D), skipping the leading LD C,A; the fall-through
;        entry here (from the dispatcher) keeps it.
;   Out: none.  Clobbers: A,C,HL.
;   Algorithm: read IOBYTE ($0003), mask the 2-bit CONSOLE field (AND $03).  Field
;     value 2 dispatches through the SoftCard I/O vector at $F392 (Apple $0392) with
;     JP (HL); otherwise fall into the column/tab filter. [RE]
; ----------------------------------------------------------------------
CONOUT_DISPATCH:
        ; save the character to emit in C for the filter path (skipped by the +1 entry)
        LD C,A
        ; read the CP/M IOBYTE (page-zero $0003)
        LD A,($0003)
        ; isolate the 2-bit CONSOLE device field of the IOBYTE
        AND $03
        ; device value 2 = direct console; anything else takes the filter path
        CP $02
        JR NZ,CONOUT_FILTER_NOEXPAND
CONOUT_VIA_VEC_F392:
        ; load console-output handler addr from SoftCard I/O vector ($F392 = Apple $0392)
        LD HL,($F392)
        JP (HL)
; ----------------------------------------------------------------------
; CONIN_DISPATCH_IOBYTE -- read a console character, routed by the IOBYTE CONSOLE field.
;   In:  none.  Out: A = character.  Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the CONSOLE field (AND $03).  Value 2 uses vector
;     $F38A; the high value ($02<x) uses the preloaded $F384; low values use $F382;
;     then JP (HL) into the chosen handler.  ($F38x = Apple $038x I/O vector.)
;     Called by CONIN (the remap wrapper) and reused by READER. [RE]
; ----------------------------------------------------------------------
CONIN_DISPATCH_IOBYTE:
        ; read the CP/M IOBYTE
        LD A,($0003)
        ; isolate the 2-bit CONSOLE device field
        AND $03
        CP $02
        ; preload the input vector for the high CONSOLE value ($F384 = Apple $0384)
        LD HL,($F384)
        JR Z,CONIN_VIA_VEC_F38A
        JR NC,DISPATCH_VIA_HL
CONIN_VIA_VEC_F382:
        ; input vector for the low CONSOLE values ($F382 = Apple $0382)
        LD HL,($F382)
        JP (HL)
CONIN_VIA_VEC_F38A:
        ; input vector for CONSOLE value 2 ($F38A = Apple $038A)
        LD HL,($F38A)
DISPATCH_VIA_HL:
        JP (HL)
; ----------------------------------------------------------------------
; LIST -- emit a character to the list device, routed by the IOBYTE LIST field.
;   In:  C = character.  Out: none.  Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the top 2-bit LIST field (AND $C0).  Below $80
;     routes to the column/tab filter; == $80 reuses the console vector path
;     (CONOUT_VIA_VEC_F392); higher values dispatch through list vector $F394
;     (Apple $0394). [RE]
; ----------------------------------------------------------------------
LIST:
        LD A,($0003)
        ; isolate the 2-bit LIST device field (top bits of the IOBYTE)
        AND $C0
        CP $80
        ; field < $80 -> no-device / filter path
        JR C,DISPATCH_NODEV
        ; field == $80 -> reuse the console output vector path
        JR Z,CONOUT_VIA_VEC_F392
        ; list-handler vector ($F394 = Apple $0394)
        LD HL,($F394)
        JP (HL)
; ----------------------------------------------------------------------
; PUNCH -- emit a character to the punch device, routed by the IOBYTE PUNCH field.
;   In:  C = character.  Out: none.  Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the PUNCH field (AND $30).  Below $10 takes the
;     column/tab filter; == $10 dispatches through vector $F38E; higher values use
;     vector $F390.  ($F38E/$F390 = Apple $038E/$0390.) [RE]
; ----------------------------------------------------------------------
PUNCH:
        LD A,($0003)
        ; isolate the 2-bit PUNCH device field of the IOBYTE
        AND $30
        CP $10
        ; field < $10 -> no-device / filter path
        JR C,DISPATCH_NODEV
        ; punch vector for the higher PUNCH values ($F38E = Apple $038E)
        LD HL,($F38E)
        ; field == $10 -> use the $F390 vector below
        JR Z,DISPATCH_VIA_HL
        ; punch vector for PUNCH value $10 ($F390 = Apple $0390)
        LD HL,($F390)
        JP (HL)
; ----------------------------------------------------------------------
; READER -- read a character from the reader device, routed by the IOBYTE READER field.
;   In:  none.  Out: A = character.  Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the READER field (AND $0C).  Below $04 reuses the
;     CONIN low-value vector; == $04 reuses the CONIN $F38A path; higher values use
;     reader vector $F38C (Apple $038C). [RE]
; ----------------------------------------------------------------------
READER:
        LD A,($0003)
        ; isolate the 2-bit READER device field of the IOBYTE
        AND $0C
        CP $08
        ; field < $04 -> reuse the CONIN low-value vector path
        JR C,CONIN_VIA_VEC_F382
        ; field == $04 -> reuse the CONIN $F38A vector path
        JR Z,CONIN_VIA_VEC_F38A
        ; reader-handler vector ($F38C = Apple $038C)
        LD HL,($F38C)
        JP (HL)
; ----------------------------------------------------------------------
; DISPATCH_NODEV -- IOBYTE field selects no physical device: fall into the filter.
;   In:  carry set by the caller (no-device).  Out: enters CONOUT_FILTER_NOEXPAND
;        with the carry folded into the COL_FLAG byte.  Clobbers: A,HL.
;   Algorithm: SCF then (CONOUT_FILTER_NOEXPAND) SBC A,A turns carry into a 0/$FF
;     flag stored in COL_FLAG ($FECB); clear bit 7 of the char in C; if the pending-
;     column counter ($FECC) is nonzero, apply a config-driven column offset, else
;     fall through to the tab/control expansion (SETDMA_1). [RE]
; ----------------------------------------------------------------------
DISPATCH_NODEV:
        ; carry-set entry: mark the expand flag before SBC A,A turns it into $FF
        SCF
CONOUT_FILTER_NOEXPAND:
        ; convert carry into a 0/$FF flag byte for COL_FLAG
        SBC A,A
        LD HL,$F3A2
        LD L,(HL)
        INC L
        JP Z,SUB_FCA4
        ; HL -> COL_FLAG cell ($FECB)
        LD HL,L_FECB
        ; store the entry flag into COL_FLAG
        LD (HL),A
        ; strip the high bit of the character (7-bit ASCII)
        RES 7,C
        INC HL
        ; load COL_PENDING (pending column-skip / fill count, $FECC)
        LD A,(HL)
        OR A
        ; no pending column work -> run tab/control expansion
        JP Z,SETDMA_1
        ; consume one pending column step
        DEC (HL)
        ; read screen-width / left-margin config byte ($F396 = Apple $0396)
        LD A,($F396)
        ; HL -> the column cell in the $FE85 deblock/screen-state band ($FED4)
        LD HL,BOOT_TMPL_XORA
        ; config byte zero -> derive the offset from the running width
        JR Z,COL_OFFSET_FROM_WIDTH
        OR A
        JP P,COL_APPLY_OFFSET_RAW
        DEC HL
; ----------------------------------------------------------------------
; COL_APPLY_OFFSET -- apply a signed config offset to the running column position.
;   In:  A = config byte (sign bit = direction); C = current column; HL -> column cell.
;   Out: (HL) = C - offset.  Clobbers: A,E.
;   Algorithm: AND $7F drops the sign bit to the magnitude, subtract it from the
;     current column in C, store the new column.  Reached when the config byte's sign
;     indicates a subtractive column adjust. [RE]
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
; ----------------------------------------------------------------------
; COL_OFFSET_FROM_WIDTH -- derive the column offset from the running screen width.
;   In:  C = current column; the BOOT-overlaid base word at (BOOT+2).
;   Out: updates the column and emits via SCREEN_EMIT; combines a base address with
;        the offset.  Clobbers: A,B,C,DE,HL.
;   Algorithm: pick the column cell by the config sign, CALL COL_APPLY_OFFSET, then
;     load the base word (BOOT+2 = the cold-boot operand reused as deblock
;     scratch), fold in config $F3A1, and ADD to form the screen address before
;     emitting (SCREEN_EMIT). [RE]
; ----------------------------------------------------------------------
COL_OFFSET_FROM_WIDTH:
        OR A
        ; config sign negative -> keep the higher column cell
        JP M,COL_OFFSET_FROM_WIDTH_1
        DEC HL
COL_OFFSET_FROM_WIDTH_1:
        ; apply the signed column offset (COL_APPLY_OFFSET)
        CALL COL_APPLY_OFFSET
        ; base word = the BOOT-overlaid deblock scratch ($FED3)
        LD HL,(BOOT+2)
        ; config byte $F3A1 = Apple $03A1 (screen-base modifier)
        LD A,($F3A1)
        OR A
        ; config positive -> use HL as-is, skip the byte swap
        JP P,COL_COMBINE_BASE
        ; negative: drop the sign bit, then swap H<->L below
        AND $7F
        LD E,L
        LD L,H
        LD H,E
; ----------------------------------------------------------------------
; COL_COMBINE_BASE -- fold the config offset into the base address, emit the char.
;   In:  A = config offset; HL = base word; C will receive the high result.
;   Out: pushes the low result, emits via SCREEN_EMIT with B=7, then re-enters the
;        emit path with B=$0A.  Clobbers: A,B,C,DE,HL.
;   Algorithm: C = offset + H; A = offset + L; CALL SCREEN_EMIT (B=7), then fall into
;     CONOUT_EMIT_B with B=$0A. [RE]
; ----------------------------------------------------------------------
COL_COMBINE_BASE:
        LD E,A
        ; C = config offset + base high byte
        ADD A,H
        LD C,A
        LD A,E
        ; A = config offset + base low byte
        ADD A,L
        PUSH AF
        ; mode/count code 7 for the screen emit
        LD B,$07
        ; emit via the screen handler (SCREEN_EMIT)
        CALL SUB_FCA4
        POP AF
        ; mode/count code $0A for the follow-up emit
        LD B,$0A
SUB_FBF0:
        LD C,A
        JP SUB_FCA4
; ----------------------------------------------------------------------
; SETSEC -- BIOS jump-vector entry 11 ($FA24 -> $FBF4): set the requested sector.
;   In:  C = sector number. Out: none. Clobbers: A.
;   Algorithm: store C into seksec (DISK_SEKTRK_223+1 = $FED2, the SP-operand low
;        byte reused as the deblock sector cell). Consumed later by the OFF-IMAGE
;        deblock host-match test, not acted on here. Mirrors the 2.20 SETSEC. [RE]
; ----------------------------------------------------------------------
SETSEC:
        LD A,C
        ; store the sector into seksec ($FED2, DISK_SEKTRK_223+1)
        LD (BOOT+1),A
        RET
; ----------------------------------------------------------------------
; SETDMA -- BIOS jump-vector entry 12 ($FA27 -> $FBF9): set the DMA address.
;   In:  BC = DMA buffer address (the 128-byte CP/M record source/destination).
;   Out: none. Clobbers: none.
;   Algorithm: store BC into the dmaadr cell (SECTOR_BLOCK_PATCH+2 = $FEE1, the
;        operand region of the install-template 'LD ($0003),A'). The OFF-IMAGE
;        deblock copy uses dmaadr as the host<->record transfer endpoint. The 2.20
;        deblock did the LDIR itself; in 2.23 the value is read off-image. [RE]
; ----------------------------------------------------------------------
SETDMA:
        ; store BC into dmaadr ($FEE1, overlaid on the install-template LD ($0003),A operand)
        LD (DISK_DMAADR+2),BC
        RET
        DEFS    88, $00                  ; fill
SETDMA_1:
        LD B,A
        LD HL,L_FECD
        LD A,(HL)
        LD E,A
        OR A
        JR NZ,SETDMA_3
        LD A,($F397)
        OR A
        JR Z,SETDMA_2
        CP C
        JR NZ,SETDMA_2
        LD (HL),$80
        RET
SETDMA_2:
        LD A,$1F
        CP C
        JP C,SUB_FCA4
SETDMA_3:
        LD HL,$F3A0
        LD B,$09
SETDMA_4:
        LD A,(HL)
        OR A
        JR Z,SETDMA_5
        XOR E
        CP C
        JR Z,SETDMA_6
SETDMA_5:
        DEC HL
        DJNZ SETDMA_4
        JR SUB_FCA4
SETDMA_6:
        LD DE,$000B
        ADD HL,DE
        LD A,(HL)
        OR A
        LD C,A
        JP P,SETDMA_7
        AND $7F
        LD C,A
        PUSH BC
        LD A,($F3A2)
        LD B,$07
        CALL SUB_FBF0
        POP BC
SETDMA_7:
        LD A,B
        CP $07
        JR NZ,SUB_FCA4
        LD A,$02
        LD (L_FECC),A
SUB_FCA4:
        XOR A
        LD (L_FECD),A
        LD A,(L_FECB)
        OR A
        LD HL,($F388)
        JR Z,SUB_FCA4_1
        LD HL,($F386)
SUB_FCA4_1:
        JP (HL)
SUB_FCA4_2:
        LD DE,$0003
SUB_FCA4_3:
        JP SUB_FCA4_4
SUB_FCA4_4:
        LD HL,(L_FECE)
        LD A,(L_FED0)
        LD (HL),A
        CALL SUB_FCE2
        LD HL,($F028)
        LD A,($F024)
        LD E,A
        LD D,$F0
        ADD HL,DE
        LD (L_FECE),HL
        LD A,(HL)
        LD (L_FED0),A
        CP $E0
        JR C,SUB_FCA4_5
        XOR $20
SUB_FCA4_5:
        AND $3F
        OR $40
        LD (HL),A
        RET
SUB_FCE2:
        LD A,B
        OR A
        JR Z,L_FCF1
        LD HL,RPC_TRIGGER
        PUSH HL
        LD HL,L_FD66
        ADD A,L
        DEFB    $6F,$6E,$E9
L_FCF1:
        DEFB    $79,$FE,$0D,$20,$05
        DEFB    $AF,$32,$24,$F0,$C9,$F6,$80 ; "/2$pIv"
        DEFB    $FE,$E0,$38,$04
        DEFB    $21,$DD,$F3,$AE,$32,$45,$F0,$21,$F0,$FD,$C3,$80 ; "!]s.2Ep!p}C"
        DEFB    $FD,$CD,$81,$FE,$C6,$8F
        DEFB    $CB,$4E,$28,$FC,$21,$2F,$F0,$36,$60,$2B,$36,$C0,$2B,$77,$2B,$36 ; "KN(|!/p6`+6@+w+6"
        DEFB    $8D
        DEFB    $62,$C3,$7C,$FD,$3E,$FF,$01,$3E,$3F,$32,$32,$F0,$E1,$C9,$21,$F4
        DEFB    $FB,$C9,$AF,$6F,$67,$22,$24,$F0,$32,$45,$F0,$21,$C1,$FB,$C9,$2E
        DEFB    $42,$01,$2E,$9C,$01,$2E,$1A,$01,$2E,$58,$26,$FC,$C9,$2A,$D3,$FE
        DEFB    $7D,$FE,$28,$38,$02,$2E,$00,$7C,$FE,$18,$38,$02,$26,$00,$22,$24
        DEFB    $F0,$18
L_FD66:
        DEFB    $D5,$4C,$43,$46,$28,$2B,$36,$30,$49,$32,$51,$CD ; "ULCF(+60I2QM"
        DEFB    $83,$FD,$21,$78,$F6,$19,$71,$21,$AA,$C9,$79,$32,$45,$F0,$C3,$45
        DEFB    $FB
SUB_FD83:
        CALL SLOT_IO_ADDR_W
        LD ($F6F8),A
        LD ($F047),A
        LD A,($EFFF)
        CALL DEVICE_IO_BASE
        SUB $20
        LD ($F046),A
        LD A,(HL)
        RET
SUB_FD83_1:
        LD HL,$0E14
        LD E,$03
        LD A,$01
        CALL SUB_FDAD
        LD A,($F048)
        RRA
        SBC A,A
        RET
        DEFB    $21,$E1,$0D,$79
SUB_FDAD:
        LD ($F045),A
SUB_FDB0:
        LD A,E
        LD ($F047),A
        JP RPC_TRIGGER
SUB_FDB0_1:
        LD HL,$0E06
        CALL SUB_FDB0
        LD A,($F045)
        RET
        DEFB    $CD,$83,$FD,$21,$4D,$C8,$CD,$45,$FB,$21,$78,$F6,$19,$7E,$C9,$48
        DEFB    $20,$1D,$0E,$A0,$0D,$B1,$F6,$85,$F6,$AC,$F8,$06,$68,$6C,$F6,$00
        DEFB    $48,$A9,$00,$20,$EF,$0D,$20,$1D,$0E,$A0,$0F,$4C,$D6,$0D,$84,$F5
        DEFB    $48,$20,$14,$0E,$68,$A4,$F5,$90,$F5,$60,$00,$00,$00,$00,$00,$4C
        DEFB    $E9,$BB,$4C,$04,$BE,$A9,$01,$20,$EF,$0D,$20,$1D,$0E,$48,$A0,$0E
        DEFB    $4C,$D6,$0D,$48,$20,$1D,$0E,$A0,$10,$4C,$D6,$0D,$98,$09,$C0,$AA
        DEFB    $98,$0A,$0A,$0A,$0A,$A8,$8C,$F8,$06,$A9,$00,$85,$F6,$86,$F7,$AD
        DEFB    $FF,$CF,$B1,$F6,$60,$A5,$48,$48,$A5,$45,$A6,$46,$A4,$47,$28,$58
        DEFB    $60,$CD,$81,$FE,$7E,$1F,$30,$FC,$2C,$7E,$C9,$11,$01,$00,$C3
L_FE50:
        DEFB    $5F,$FE,$CD,$B1,$FA,$2E,$C1,$7E,$17,$38,$FC,$CD,$7C,$FE,$71,$C9
        DEFB    $11,$02,$00,$C3
L_FE64:
        DEFB    $5F,$FE,$11,$02,$00
L_FE69:
        DEFB    $C3
L_FE6A:
        DEFB    "\0"
L_FE6B:
        DEFB    "\0"
; ----------------------------------------------------------------------
; HOME -- BIOS jump-vector entry 8 ($FA18): seek the selected drive to track 0. [RE]
;   In:  none. Out: none. Clobbers: A,C.
;   Algorithm: if the host buffer still holds a pending write (hstwrt nonzero) leave
;     hstact set so the dirty buffer is not dropped; else clear hstact (host buffer
;     inactive). Then fall through into SETTRK_STORE with track 0. Mirrors the 2.20
;     twin HOME exactly; the actual head step happens later in the deblock path. [RE]
; ----------------------------------------------------------------------
HOME:
        ; read hstwrt (host-write-pending flag; lives in the BOOT install-template cells)
        LD A,(DISK_HSTWRT)
        OR A
        ; pending write -> keep hstact set, skip the clear
        JR NZ,SETTRK_STORE
        ; no pending write: clear hstact so the host buffer is reloaded on next access
        LD (DISK_HSTACT),A
; ----------------------------------------------------------------------
; SETTRK_STORE -- HOME falls in here with track 0; common tail with SETTRK. [RE]
;   In:  (HOME path) forces C=0. Out: stores sektrk. Clobbers: A,C.
;   Algorithm: load C=0, then fall into SETTRK's store (the $FE77 vector body) which
;     writes the track into the BOOT 'LD SP' operand byte reused as sektrk. [RE]
; ----------------------------------------------------------------------
SETTRK_STORE:
        ; HOME enters here with track 0; SETTRK enters at the LD A,C below
        LD C,$00
        ; SETTRK (vector entry 10, JP $FE77): track number from BDOS in C
        LD A,C
        ; store sektrk into BOOT's LD SP operand byte (BOOT cell reused post-boot as sektrk)
        LD (BOOT),A
        RET
; ----------------------------------------------------------------------
; SLOT_IO_ADDR_W -- map a slot/drive index to an Apple write-side I/O soft-switch base.
;   In:  E = slot/drive index (0..15). Out: HL = $E080 + (E<<4). Clobbers: A,L.
;   Algorithm: load the $C08x write/control-bank base (z80 $E080 = Apple $C080), then
;     fall into the shared index scaler (SLOT_IO_SCALE, the ADD A,A x4 at $FE85).
;     Twin of 2.20 SLOT_IO_ADDR_W. [RE]
; ----------------------------------------------------------------------
SLOT_IO_ADDR_W:
        ; z80 $E080 = Apple $C080 slot-I/O base (write/control bank)
        LD HL,$E080
        JR SLOT_IO_SCALE_E
; ----------------------------------------------------------------------
; SLOT_IO_ADDR -- map a slot/drive index to an Apple I/O soft-switch base ($C08E bank).
;   In:  E = slot/drive index (0..15). Out: HL = $E08E + (E<<4). Clobbers: A,L.
;   Algorithm: load the $C08E base, fall into SLOT_IO_SCALE_E. z80 $E08E = Apple $C08E.
;     Twin of 2.20 SLOT_IO_ADDR. [RE]
; ----------------------------------------------------------------------
SLOT_IO_ADDR:
        ; z80 $E08E = Apple $C08E slot-I/O base
        LD HL,$E08E
; ----------------------------------------------------------------------
; SLOT_IO_SCALE_E -- load the slot/drive index into A, then fall into SLOT_IO_SCALE.
;   In:  E = index. Out: continues into the scaler. Twin of 2.20 SLOT_IO_SCALE_E. [RE]
; ----------------------------------------------------------------------
SLOT_IO_SCALE_E:
        ; slot/drive index into A for the scaler
        LD A,E
; ----------------------------------------------------------------------
; SLOT_IO_SCALE -- shift the index in A left by 4 and add it to L (index a $C0n0..$C0nF
;     16-byte slot-I/O block, or a *16-stride table). [RE]
;   In:  A = index, L = base low byte. Out: L += A*16; A preserved. Clobbers: A,L.
;   Algorithm: ADD A,A four times (A*=16), PUSH AF, ADD A,L, LD L,A, POP AF, RET.
;     Shared by SLOT_IO_ADDR/_W and by SELDSK (DPH-table index) and the device probe.
;     Twin of 2.20 SLOT_IO_SCALE. [RE]
; ----------------------------------------------------------------------
SLOT_IO_SCALE:
        ; A *= 16 over the four ADD A,A (slot block is 16 bytes; DPH stride is 16)
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        PUSH AF
        ; L = base + index*16
        ADD A,L
        LD L,A
        POP AF
        RET
; ----------------------------------------------------------------------
; SELDSK -- BIOS jump-vector entry 9 ($FA1B): select the disk drive for subsequent I/O.
;   In:  C = disk number (0-based). Out: HL = DPH address for drive C, or HL=0 if out
;     of range. Clobbers: A,DE,HL.
;   Algorithm: DE -> the sekdsk build site (DISK_SEKDSK, an install-template cell reused
;     as disk-state scratch). Read the configured drive count from the SoftCard config
;     block (z80 $F3B8 = Apple $03B8); if C >= count return HL=0. Else record the disk
;     number, index the DPH table at DPH_TABLE by C*16 (CALL SLOT_IO_SCALE), pull a per-drive
;     disk-parameter byte and self-modify the install template SECTOR_BLOCK_PATCH+1 with it.
;     Twin of 2.20 SELDSK. [RE]
; ----------------------------------------------------------------------
SELDSK:
        ; DE -> sekdsk build site (install-template cell reused as disk-select scratch)
        LD DE,DISK_SEKDSK
        LD HL,$0004
        ; configured drive count from the SoftCard config block (Apple $03B8)
        LD A,($F3B8)
        DEC A
        ; requested drive vs (count-1); carry => out of range
        CP C
        ; out of range -> SELDSK_BAD_DRIVE (returns HL=0)
        JR C,SELDSK_BAD_DRIVE
        LD A,(HL)
        LD (DE),A
        INC DE
        LD A,C
        LD (DE),A
        ; HL = DPH table base ($FA33); CALL SLOT_IO_SCALE indexes it by C*16
        LD HL,DPH_TABLE
        CALL SLOT_IO_SCALE
        PUSH HL
        LD DE,$000A
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD HL,$0005
        ADD HL,DE
        LD A,(HL)
        ; self-modify: store the per-drive disk-parameter byte into the install template's LD
        ; HL,(nn) operand [RE]
        LD (SECTOR_BLOCK_PATCH+1),A
        POP HL
        RET
; ----------------------------------------------------------------------
; SELDSK_BAD_DRIVE -- out-of-range drive: return HL=0 (no DPH). [RE]
;   In:  DE -> sekdsk build site. Out: HL=0. Clobbers: A,L.
;   Twin of 2.20 SELDSK_BAD_DRIVE. [RE]
; ----------------------------------------------------------------------
SELDSK_BAD_DRIVE:
        LD A,(DE)
        LD (HL),A
        ; HL=0 signals an invalid drive to the BDOS
        LD L,$00
        RET
; ----------------------------------------------------------------------
; READ -- BIOS jump-vector entry 13 ($FA27): read one 128-byte CP/M record.
;   In:  sekdsk/sektrk/seksec/dmaadr previously set. Out: A=0 ok / 1 error.
;   Algorithm: OFF-IMAGE tail-jump to the deblock/RWTS read core at $AC39, which sits
;     in the system-image region BELOW the BIOS (not inside $FA00-$FFFF). FLAG: unlike
;     the 2.20 twin, the 2.23 BIOS does NOT carry the deblock or the $03E0-IOB RWTS RPC
;     in-image; READ/WRITE delegate to the $ACxx host-sector routines. [RE] -- see flags.
; ----------------------------------------------------------------------
READ:
        ; off-image jump to the deblock/RWTS read core at $AC39 (system-image region, not BIOS) [RE]
        JP $AC39
; ----------------------------------------------------------------------
; WRITE -- BIOS jump-vector entry 14 ($FA2A): write one 128-byte CP/M record.
;   In:  C = write type; sekdsk/sektrk/seksec/dmaadr previously set. Out: A=0 ok / 1 error.
;   Algorithm: OFF-IMAGE tail-jump to the deblock/RWTS write core at $AC49 (system-image
;     region below the BIOS). Same off-image RWTS delegation as READ_RECORD. [RE]
;   NOTE: the bytes at $FEC3-$FECA ($C3 $45 $FB $2A $0D $9C $E9 $C9) immediately after
;     this JP are NOT executed on the WRITE path; they are install/handler scratch -- see flags.
; ----------------------------------------------------------------------
WRITE:
        ; off-image jump to the deblock/RWTS write core at $AC49 (system-image region, not BIOS)
        ; [RE]
        JP $AC49
        DEFB    $C3,$45,$FB,$2A,$0D      ; "CE{*"
        DEFB    $9C,$E9,$C9
L_FECB:
        DEFB    "\0"
L_FECC:
        DEFB    "\0"
L_FECD:
        DEFB    "\0"
L_FECE:
        DEFB    $D0,$FE
L_FED0:
        DEFB    "\0"
; ----------------------------------------------------------------------
; BOOT -- CP/M cold-boot BIOS entry (jump-vector entry 0; $FA00 -> here at $FED1).
;   In:  none. Out: does not return through here (falls into the install engine).
;   Clobbers: all.
;   DUAL USE of the operand bytes: this 'LD SP,$0100' executes ONCE at cold boot to set
;     the Z-80 stack; afterwards BOOT (the $00 operand byte) is reused as sektrk and
;     BOOT+1 as seksec (SETTRK stores BOOT at $FE78, SETSEC stores
;     BOOT+1 at $FBF5), and BOOT+2 ($FED3) is read as a console cursor word
;     ($FBD3 LD HL,(BOOT+2)). Valid SP-init bytes only during the single cold-boot
;     pass; thereafter disk/console scratch, never re-executed. Twin of 2.20 BOOT. [RE]
;   Algorithm: set SP, then fall through into the self-modifying install engine
;     (BOOT_TMPL_XORA..SECTOR_BLOCK_PATCH are template-instruction cells whose operands double as
;     disk-deblock state).
; ----------------------------------------------------------------------
BOOT:
        ; init Z-80 stack; BOOT/+1/+2 reused post-boot as sektrk/seksec and a console cursor word
        LD SP,$0100
; ----------------------------------------------------------------------
; BOOT_TMPL_XORA -- cold-boot install template 'XOR A'; operationally a disk-state cell.
;   Boot tenant: 'XOR A' clears A as the install engine starts the page-clear. Operational
;   tenant: this cell is referenced as a console/disk scratch base (LD HL,BOOT_TMPL_XORA at
;   $FBBA in the console path). Twin region of 2.20 DISK_SELDSK_SAVE. [RE]
; ----------------------------------------------------------------------
BOOT_TMPL_XORA:
        XOR A
; ----------------------------------------------------------------------
; DISK_SEKDSK -- cold-boot install template 'LD HL,BIOS_VECTOR'; operationally the sekdsk cell.
;   Boot tenant: 'LD HL,nn' template the install engine steps over. Operational tenant:
;   SELDSK uses DE=DISK_SEKDSK as the sekdsk build site (selected disk number). Twin of
;   2.20 DISK_SEKDSK. [RE]
; ----------------------------------------------------------------------
DISK_SEKDSK:
        LD HL,BIOS_VECTOR
; ----------------------------------------------------------------------
; DISK_HSTACT -- cold-boot install template 'LD (HL),A'; operationally the hstact flag.
;   Boot tenant: part of the page-zero/template clear. Operational tenant: host-buffer-
;   active flag, cleared by HOME ($FE72) and by PAGEZERO_REBUILD ($FAE7), set when a host
;   sector is staged. Twin of 2.20 DISK_HSTWRT-area hstact. [RE]
; ----------------------------------------------------------------------
DISK_HSTACT:
        LD (HL),A
; ----------------------------------------------------------------------
; DISK_HSTWRT -- cold-boot install template 'INC HL'; operationally the hstwrt flag.
;   Boot tenant: 'INC HL' advances the install-clear pointer. Operational tenant: host-
;   buffer-dirty flag, read by HOME ($FE6C). Twin of 2.20 DISK_HSTWRT. [RE]
; ----------------------------------------------------------------------
DISK_HSTWRT:
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
; ----------------------------------------------------------------------
; BOOT_TMPL_IOBYTE -- cold-boot install template 'LD A,$95' (default IOBYTE immediate).
;   Boot tenant: loads the default IOBYTE value $95 into A. Operational tenant: this cell
;   is cleared by PAGEZERO_REBUILD ($FAE4) and used as a console-state byte. Twin of the
;   2.20 DISK_HSTWRT 'LD A,$95' default-IOBYTE template. [RE]
; ----------------------------------------------------------------------
BOOT_TMPL_IOBYTE:
        ; default CP/M IOBYTE immediate ($95) loaded at cold boot
        LD A,$95
; ----------------------------------------------------------------------
; DISK_DMAADR -- cold-boot install template 'LD ($0003),A' (store default IOBYTE);
;     +2 operand reused as dmaadr.
;   Boot tenant: stores the default IOBYTE into page-zero $0003 at cold boot. Operational
;   tenant: SETDMA writes BC into DISK_DMAADR+2 ($FEE1) as the current DMA buffer address
;   (SETDMA 'LD (DISK_DMAADR+2),BC'); the deblock record copy uses it. Twin of the 2.20
;   DISK_WRTYPE/DISK_DMAADR overlay. [RE]
; ----------------------------------------------------------------------
DISK_DMAADR:
        ; store the default IOBYTE into page-zero $0003; the operand cell (+2) doubles as dmaadr
        LD ($0003),A
; ----------------------------------------------------------------------
; DISK_PARAM_TMPL -- cold-boot install template 'LD HL,($F3DE)'; SELDSK self-modifies +1.
;   Boot tenant: 'LD HL,(nn)' loads a config word; the install engine continues at $FEE5.
;   Operational tenant: SELDSK patches DISK_PARAM_TMPL+1 ($FEE3) with a per-drive disk-
;   parameter byte. From $FEE5 the cold-boot INSTALL ENGINE proper runs (see body). Twin
;   of 2.20 DISK_UNADSK template + the DEV_INSTALL flow. [RE]
;   Algorithm (install engine from $FEE5): copy the RPC-trigger store address into
;     RPC_TRIGGER_STORE+1; clear page-zero $0004; read the console card class from config
;     $F3BB; for the device-6/Pascal-class console install the $FD99 status handler into
;     the $F380 vector, else for the Videx/40-col classes self-modify the CONST handler
;     (KBD_STATUS_40COL+1) so status reads come from the card; then install CONOUT/CONIN handler
;     vectors via the handler lookups, print the sign-on banner, and enter the CCP.
; ----------------------------------------------------------------------
SECTOR_BLOCK_PATCH:
        ; install template: load a config word (operand at +1 is self-modified by SELDSK with the
        ; disk param)
        LD HL,($F3DE)
        ; self-modify: write the SoftCard RPC-trigger store address into RPC_TRIGGER_STORE's LD
        ; (nn),A operand [RE]
        LD (RPC_TRIGGER_STORE+1),HL
        XOR A
        ; clear page-zero $0004 (current default drive)
        LD ($0004),A
        ; read the configured console card class from the config block (Apple $03BB)
        LD A,($F3BB)
        ; card class 6 = device-6 / Pascal-firmware console (post-1980 path; absent in the 1980
        ; manual) [RE]
        CP $06
        JR NZ,DEV_INSTALL_LIST
        ; device-6 console: install the $FD99 status handler
        LD HL,SUB_FD83_1
        ; store it into the SoftCard console-status I/O vector cell (Apple $0380)
        LD ($F380),HL
        SUB $03
        JR DEV_INSTALL_PUNCH
; ----------------------------------------------------------------------
; DEV_INSTALL_LIST -- install the LIST device-output handler from the config class. [RE]
;   In:  install engine running. Out: patches the LIST output stub vector. Clobbers: A,HL.
;   Algorithm: read the LIST card class (config $F3B9 = Apple $03B9), bias by 3; if a
;     real device is configured, look up its handler (CALL HANDLER_LOOKUP) and store it
;     into the LIST stub vector cell L_FE50. Twin of 2.20 DEV_INSTALL flow. [RE]
; ----------------------------------------------------------------------
DEV_INSTALL_LIST:
        CP $05
        JR Z,DEV_INSTALL_READER
        SUB $03
        JR C,DEV_INSTALL_READER
        JR NZ,DEV_INSTALL_PUNCH
        LD HL,KBD_STATUS_40COL+1
        LD (HL),$BE
        INC HL
        INC HL
        LD (HL),$1F
; ----------------------------------------------------------------------
; DEV_INSTALL_PUNCH -- install the PUNCH device-output handler from the config class. [RE]
;   Algorithm: read the PUNCH card class (config $F3BA = Apple $03BA), bias by 3; if
;     configured, look up the handler and store it into the PUNCH stub vector L_FE64; for
;     the higher class value also install a secondary handler into L_FE6A. Twin of 2.20
;     DEV_INSTALL flow. [RE]
; ----------------------------------------------------------------------
DEV_INSTALL_PUNCH:
        PUSH AF
        CALL DEV_HANDLER_LOOKUP
        POP AF
        LD (SUB_FCA4_3+1),HL
        ; secondary handler lookup via the skip-idiom entry (HANDLER_LOOKUP_B); the FD cover byte at
        ; DEV_HANDLER_LOOKUP_B is skipped [RE]
        CALL DEV_HANDLER_LOOKUP_B+1
        LD (CONIN_DISPATCH+1),HL
        LD A,$03
        LD (CCP_LAUNCH+1),A
; ----------------------------------------------------------------------
; DEV_INSTALL_READER -- build the default READER/list-output stub when none is configured.
;   Algorithm: when no real device class is configured, build the no-op stub at L_FE69:
;     store $1A3E ('LD A,$1A' opcode+immediate) then $C9 ('RET') so the device returns a
;     constant. Twin of 2.20 DEV_INSTALL_4's DEV_OUT_3 build. [RE]
; ----------------------------------------------------------------------
DEV_INSTALL_READER:
        LD A,($F3B9)
        SUB $03
        JR C,INSTALL_DONE_DEVICES
        CALL DEV_HANDLER_LOOKUP
        LD (L_FE50),HL
; ----------------------------------------------------------------------
; INSTALL_DONE_DEVICES -- run the device probe after the per-device installs. [RE]
;   Algorithm: CALL PROBE_DEVICES (PROBE_DEVICES) to scan the 7 SoftCard config slots and
;     mark/init each present card before the banner is printed. Twin of 2.20 DEV_INSTALL_6
;     PROBE_DEVICES call. [RE]
; ----------------------------------------------------------------------
INSTALL_DONE_DEVICES:
        LD A,($F3BA)
        SUB $03
        JR C,SLOT_IO_SCALE_17
        PUSH AF
        CALL DEV_HANDLER_LOOKUP
        LD (L_FE64),HL
        POP AF
        CP $02
        JR Z,SLOT_IO_SCALE_17
        CALL DEV_HANDLER_LOOKUP_B+1
        LD (L_FE6A),HL
        JR SLOT_IO_SCALE_18
SLOT_IO_SCALE_17:
        LD HL,$1A3E
        LD (L_FE69),HL
        LD A,$C9
        LD (L_FE6B),A
SLOT_IO_SCALE_18:
        ; scan + init the 7 SoftCard config slots (device probe) before the sign-on
        CALL PROBE_DEVICES
; ----------------------------------------------------------------------
; SIGNON_PRINT -- emit the two config-derived sign-on prefix chars, then the banner. [RE]
;   In:  none. Out: prints the sign-on. Clobbers: A,HL.
;   Algorithm: read config $F398 (Apple $0398), pass it to the CONOUT writer (CONOUT_DISPATCH),
;     then walk SIGNON_BANNER (SIGNON_BANNER) char-by-char through CONOUT until the $00
;     terminator, then enter PAGEZERO_REBUILD (PAGEZERO_REBUILD_HOOKS). Twin of the 2.20
;     DEV_INSTALL_6/
;     DEV_INSTALL_7 banner loop (here it routes through CONOUT directly, not SIGNON_EMIT).
;     NOTE: WBOOT (WBOOT) also stashes SIGNON_PRINT into the $F3D0 RPC mailbox at
;     $FACE for a re-init path. [RE]
; ----------------------------------------------------------------------
SIGNON_PRINT:
        ; first config-derived sign-on char (Apple $0398)
        LD A,($F398)
        ; emit it via SIGNON_EMIT (prefixes a config char if bit7 set), routed through CONOUT
        CALL SIGNON_EMIT
        ; HL -> the cold-boot sign-on banner string
        LD HL,SIGNON_BANNER
; ----------------------------------------------------------------------
; SIGNON_BANNER_LOOP -- print SIGNON_BANNER char-by-char until the $00 terminator. [RE]
;   In:  HL -> banner. Out: jumps to PAGEZERO_REBUILD at the terminator. Clobbers: A,HL.
;   Algorithm: load (HL); if $00 jump to PAGEZERO_REBUILD (PAGEZERO_REBUILD_HOOKS) to finish cold
;     boot; else push HL, CALL CONOUT (CONOUT_DISPATCH), pop, INC HL, repeat. Twin of 2.20
;     DEV_INSTALL_7. [RE]
; ----------------------------------------------------------------------
SIGNON_BANNER_LOOP:
        LD A,(HL)
        OR A
        ; banner terminator -> PAGEZERO_REBUILD (write page-zero hooks, enter the CCP)
        JP Z,PAGEZERO_REBUILD_HOOKS
        PUSH HL
        ; emit one banner char via CONOUT
        CALL CONOUT_DISPATCH
        POP HL
        INC HL
        JR SIGNON_BANNER_LOOP
SLOT_IO_SCALE_21:
        LD C,$FD
        LD (HL),C
        DEFB $FD  ; ignored IY prefix; inner: LD D,D ; $FF72  FD 52
        LD D,D
        CP $A9
        DEFB $FD  ; ignored IY prefix; inner: LD B,D ; $FF76  FD 42
SLOT_IO_SCALE_22:
        LD B,D
        CP $C1
        DEFB $FD  ; ignored IY prefix; inner: OR A ; $FF7A  FD B7
        OR A
        DEFB $FD  ; ignored IY prefix; inner: OR A ; $FF7C  FD B7
        OR A
; ----------------------------------------------------------------------
; DEV_HANDLER_LOOKUP_B -- secondary-table handler lookup, entered at +1 via a skip idiom.
;   In:  A = entry index. Out: HL = handler address from the secondary table. Clobbers: A,HL.
;   SKIP IDIOM: the byte at DEV_HANDLER_LOOKUP_B ($FF7E) is an $FD cover (reads as 'LD IY,$FF77'
;     when fallen into); every CALLER targets DEV_HANDLER_LOOKUP_B+1 ($FF7F) which executes
;     'LD HL,SLOT_IO_SCALE_22' (the secondary DEV_HANDLER_PTRS_B base) then 'JR DEV_HANDLER_
;     LOOKUP_IDX'. Twin of 2.20 DEV_HANDLER_LOOKUP_B (there a clean 'LD HL,..; JR'). [RE]
;   -- see flags for the cover byte and the surrounding DEFB-as-code handler table.
; ----------------------------------------------------------------------
DEV_HANDLER_LOOKUP_B:
        ; COVER: the FD prefix makes this 'LD IY,$FF77' on fall-in; callers enter at +1 => 'LD
        ;        HL,SLOT_IO_SCALE_22' (secondary table base) [RE]
        LD IY,SLOT_IO_SCALE_22
        ; join the shared index tail (HL += A*2; load the word)
        JR DEV_HANDLER_LOOKUP_IDX
; ----------------------------------------------------------------------
; DEV_HANDLER_LOOKUP -- fetch a device-handler address from the primary pointer table.
;   In:  A = entry index (0-based). Out: HL = handler address. Clobbers: A,HL.
;   Algorithm: HL = DEV_HANDLER_PTRS base (SLOT_IO_SCALE_21); fall into the shared scaler
;     (ADD A,A; ADD A,L; LD L,A) then load the 16-bit word at that slot (low then high).
;     The secondary-table entry is HANDLER_LOOKUP_B at DEV_HANDLER_LOOKUP_B+1 (skip idiom). Twin
;     of 2.20 DEV_HANDLER_LOOKUP. [RE]
; ----------------------------------------------------------------------
DEV_HANDLER_LOOKUP:
        ; select the primary device-handler pointer table
        LD HL,SLOT_IO_SCALE_21
; ----------------------------------------------------------------------
; DEV_HANDLER_LOOKUP_IDX -- shared table-index tail: HL += A*2; HL = word at that slot.
;   In:  A = index, HL = table base. Out: HL = the 16-bit handler address. Clobbers: A,HL.
;   Twin of 2.20 DISK_RTN_LOOKUP_IDX. [RE]
; ----------------------------------------------------------------------
DEV_HANDLER_LOOKUP_IDX:
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
;   In:  A = byte/flag. Out: prints via CONOUT (CONOUT_DISPATCH). Clobbers: A,HL.
;   Algorithm: if A is positive (bit7 clear) emit it directly via CONOUT; if negative,
;     first emit the prefix char from config $F397 (Apple $0397), then tail-jump to
;     CONOUT to emit A. Twin of 2.20 SIGNON_EMIT. [RE]
; ----------------------------------------------------------------------
SIGNON_EMIT:
        OR A
        ; bit7 clear -> emit the char directly via CONOUT
        JP P,SIGNON_EMIT_CHAR
        PUSH AF
        ; negative flag: fetch the prefix char from the config block (Apple $0397)
        LD A,($F397)
        ; emit the prefix char via CONOUT
        CALL CONOUT_DISPATCH
        POP AF
; ----------------------------------------------------------------------
; SIGNON_EMIT_CHAR -- tail of SIGNON_EMIT: emit the original char via CONOUT. [RE]
; ----------------------------------------------------------------------
SIGNON_EMIT_CHAR:
        ; tail-call CONOUT to emit the char
        JP CONOUT_DISPATCH
; ----------------------------------------------------------------------
; SIGNON_BANNER -- the cold-boot sign-on string, printed by SIGNON_BANNER_LOOP until $00.
;   Reads (40-col uppercase / Videx mixed-case): CR/LF/LF/LF, '     Softcard CP/M', CR/LF,
;   '     44K Ver. 2.23', CR/LF, '(c) 1980,1982 Microsoft', CR, LF/CR/LF, $00. DATA.
;   NOTE: the 40-col Apple screen is uppercase-only so it renders 'SOFTCARD'; the Videx
;   80-col card renders the mixed-case 'Softcard'. The trailing bytes from $FFE6 ($FA $E5
;   ...) are NOT banner text -- they are an in-image copy of handler/lookup code; see flags.
;   Twin of 2.20 SIGNON_BANNER (which reads 'Apple ][ CP/M' / '44K Ver. 2.20' /
;   '(C) 1980 Microsoft'). [RE]
; ----------------------------------------------------------------------
SIGNON_BANNER:
        DEFB    "\r\n\n\n"
        DEFB    "     Softcard CP/M"     ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n"
        DEFB    "     44K Ver. 2.23"     ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n"
        DEFB    "(c) 1980,1982 Microsoft" ; string
        DEFB    $0D                      ; terminator
        DEFB    $0A,$0D,$0A,$00,$FA,$E5,$CD,$4C,$FB,$E1,$23,$18,$F3,$0E,$FD,$71
        DEFB    $FD,$52,$FE,$A9,$FD,$42,$FE,$C1,$FD,$B7,$FD,$B7,$FD,$21

    SAVEBIN "E:/tmp/cpm223_bios_rt.bin", $FA00, $0600
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $FA00, $0600
    ENDIF
