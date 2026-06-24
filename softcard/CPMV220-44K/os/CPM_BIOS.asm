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
;   $AB3F -> SUB_AB3B_1+1         shared instruction tail: $AB3F is reachable code inside the instruction at $AB3E
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
;   $AF50 -> DISK_RTN_PTRS_B        shared instruction tail: $AF50 is reachable code inside the instruction at $AF4E

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
        JP BOOT                    ; $AA00  C3 A8 AE
BIOS_VECTOR_WBOOT:
        ; jump table
        ; entry 1 = warm boot: reload CCP, rebuild page zero
        JP      WBOOT               ; $AA03
        JP      CONST               ; $AA06
        JP      CONIN               ; $AA09
        ; entry 4 = CONOUT; target CONOUT_DISPATCH+1 (skips its leading LD C,A)
        JP      $AB43                    ; $AA0C
        JP      LIST               ; $AA0F
        JP      PUNCH               ; $AA12
        JP      READER               ; $AA15
        JP      HOME               ; $AA18
        JP      SELDSK               ; $AA1B
        ; entry 10 = SETTRK; the LD A,C tail shared with HOME
        JP      $AD56                    ; $AA1E
        JP      SETSEC               ; $AA21
        JP      SETDMA                 ; $AA24
        JP      READ               ; $AA27
        JP      WRITE               ; $AA2A
        DEFB    $AF,$C9,$00,$60,$69,$C9                          ; $AA2D
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
        DEFS    8, $00    ; $AA33  fill
        DEFB    $BA,$AE,$93,$AA,$9A,$AF,$3A,$AF                  ; $AA3B
        DEFS    8, $00    ; $AA43  fill
        DEFB    $BA,$AE,$93                                      ; $AA4B
        DEFB    $AA,$A6,$AF,$4A,$AF,$00                          ; $AA4E  "*&/J/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA54
        DEFB    $AA,$B2,$AF,$5A,$AF,$00                          ; $AA5E  "*2/Z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA64
        DEFB    $AA,$BE,$AF,$6A,$AF,$00                          ; $AA6E  "*>/j/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93          ; $AA74
        DEFB    $AA,$CA,$AF,$7A,$AF,$00                          ; $AA7E  "*J/z/"
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93,$AA,$D6,$AF,$8A,$AF,$20 ; $AA84
        DEFB    $00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,$00,$03,$00 ; $AA94
; ----------------------------------------------------------------------
; PROBE_DEVICES -- scan the 7-entry SoftCard device/config area and mark presence.
;   In:  none (walks Apple $03B8.. via z80 $F3B8 = the SoftCard config block).
;   Out: config bytes updated in place; calls per-device init when a device is found.
;   Clobbers: A,DE,HL.
;   Algorithm: for E = 7 down to 1, read config[$F3B8 + E]; if it equals 3 the slot
;              holds a recognized device, so call SLOT_IO_ADDR (build the slot I/O base)
;              and store $03 then $15 into the config cell to flag it configured. A
;              secondary DEC A test (value was 4) runs SET_SCREEN_BASE (console probe) and
;              claims the $C800 shared expansion-ROM window via SUB_AB3B. [RE]
; ----------------------------------------------------------------------
PROBE_DEVICES:
        ; DE = 7 entries to scan (index walks down to 1)
        LD DE,$0007                      ; $AAA2  11 07 00
PROBE_DEVICES_LOOP:
        ; z80 $F3B8 = Apple $03B8 = base of the SoftCard device config block
        LD HL,$F3B8                      ; $AAA5  21 B8 F3
        ADD HL,DE                        ; $AAA8  19
        LD A,(HL)                        ; $AAA9  7E
        ; config value 3 = a recognized/present device in this slot
        SUB $03                          ; $AAAA  D6 03
        JR NZ,PROBE_DEVICES_CHK4                 ; $AAAC  20 07
        CALL SLOT_IO_ADDR                    ; $AAAE  CD 60 AD
        ; rewrite the cell: $03 then $15 = mark this device configured
        LD (HL),$03                      ; $AAB1  36 03
        LD (HL),$15                      ; $AAB3  36 15
PROBE_DEVICES_CHK4:
        ; after the SUB, A==1 here means the original value was 4 (e.g. Videx-class console)
        DEC A                            ; $AAB5  3D
        JR NZ,PROBE_DEVICES_NEXT                 ; $AAB6  20 09
        CALL SET_SCREEN_BASE                    ; $AAB8  CD EE AC
        ; z80 $C800 = Apple $C800 shared expansion-ROM window for the configured card
        LD HL,$C800                      ; $AABB  21 00 C8
        CALL SUB_AB3B                    ; $AABE  CD 3B AB
PROBE_DEVICES_NEXT:
        ; next config entry; loop until all 7 scanned
        DEC E                            ; $AAC1  1D
        JR NZ,PROBE_DEVICES_LOOP                 ; $AAC2  20 E1
        RET                              ; $AAC4  C9
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
        LD HL,$E000                      ; $AAC5  21 00 E0
        LD A,E                           ; $AAC8  7B
        ; force the high byte into the $C0xx I/O range
        OR H                             ; $AAC9  B4
        LD H,A                           ; $AACA  67
        RET                              ; $AACB  C9
; ----------------------------------------------------------------------
; WBOOT -- CP/M warm boot: re-initialize the console, rebuild page zero, re-enter CCP.
;   In:  none. Out: jumps to the CCP at $9400; does not return.
;   Clobbers: all.
;   Algorithm: set SP to the default DMA top ($0080); touch the 80-col soft switch
;        (z80 $E051 = Apple $C051 TXTSET); re-init the console via SUB_AB3B; re-run
;        the device probe; then PAGEZERO_REBUILD writes the standard CP/M page-zero
;        jumps and DMA and enters the CCP. [RE]
; ----------------------------------------------------------------------
WBOOT:
        ; stack at the default DMA buffer top (page-zero $0080)
        LD SP,$0080                      ; $AACC  31 80 00
        ; z80 $E051 = Apple $C051 TXTSET soft switch (console video reset)
        LD A,($E051)                     ; $AACF  3A 51 E0
        LD HL,$0E00                      ; $AAD2  21 00 0E
        ; re-init the console I/O vectors for warm restart
        CALL SUB_AB3B                    ; $AAD5  CD 3B AB
        ; re-scan devices so warm boot rebuilds the I/O table
        CALL PROBE_DEVICES                    ; $AAD8  CD A2 AA
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
        XOR A                            ; $AADB  AF
        ; clear a self-modified BIOS console-state cell
        LD (DISK_WRTYPE+2),A             ; $AADC  32 B4 AE
        LD (DISK_SEKDSK+2),A             ; $AADF  32 AF AE
        ; $C3 = Z-80 JP opcode to plant at the page-zero hooks
        LD A,$C3                         ; $AAE2  3E C3
        ; page-zero $0000 = JP to WBOOT (CP/M warm-boot hook)
        LD ($0000),A                     ; $AAE4  32 00 00
        ; operand of the $0000 JP = BIOS vector+3 (WBOOT entry)
        LD HL,BIOS_VECTOR_WBOOT                     ; $AAE7  21 03 AA
        LD ($0001),HL                    ; $AAEA  22 01 00
        ; page-zero $0005 = JP to BDOS (the CP/M BDOS call hook)
        LD ($0005),A                     ; $AAED  32 05 00
        ; BDOS entry point ($9C06) for the $0005 hook
        LD HL,$9C06                      ; $AAF0  21 06 9C
        LD ($0006),HL                    ; $AAF3  22 06 00
        ; default DMA address = $0080 (page-zero buffer)
        LD BC,$0080                      ; $AAF6  01 80 00
        ; install the default DMA pointer
        CALL SETDMA                    ; $AAF9  CD 8E AD
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
        LD A,$01                         ; $AAFC  3E 01
        ; store the CCP entry/mode flag into CCP workspace at $98B2
        LD ($98B2),A                     ; $AAFE  32 B2 98
        ; page-zero $0004 = current default drive byte
        LD A,($0004)                     ; $AB01  3A 04 00
        LD C,A                           ; $AB04  4F
        ; enter the CCP at $9400, C = default drive
        JP $9400                         ; $AB05  C3 00 94
; ----------------------------------------------------------------------
; CONST -- CP/M console status: return $FF if a console char is ready, else $00.
;   In:  none. Out: A = $FF (ready) / $00 (not). Clobbers: A,HL.
;   Algorithm: load the console-status handler address from the SoftCard I/O vector
;        cell (z80 $F380 = Apple $0380) and JP (HL) to the 6502-serviced handler,
;        which returns the status in A. [RE]
; ----------------------------------------------------------------------
CONST:
        ; z80 $F380 = Apple $0380 = console-status handler vector cell
        LD HL,($F380)                    ; $AB08  2A 80 F3
        ; dispatch to the selected console-status handler (returns A)
        JP (HL)                          ; $AB0B  E9
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
        LD A,($E000)                     ; $AB0C  3A 00 E0
        ; rotate key-ready bit 7 into carry
        RLA                              ; $AB0F  17
        ; carry -> A = $FF (ready) or $00 (none)
        SBC A,A                          ; $AB10  9F
        RET                              ; $AB11  C9
        DEFB    $CD,$29,$AB,$21,$AB,$F3,$06,$06,$4F,$23,$7E,$23,$B7,$FA,$27,$AB ; $AB12
        DEFB    $B9,$7E,$C8,$10,$F4,$79,$C9,$11,$03,$00,$C3      ; $AB22
L_AB2D:
        DEFB    $2F,$AB,$3A,$00,$E0,$17,$30,$FA,$32,$10,$E0,$3F,$1F,$C9 ; $AB2D
SUB_AB3B:
        LD ($F3D0),HL                    ; $AB3B  22 D0 F3
SUB_AB3B_1:
        LD ($0000),A                     ; $AB3E  32 00 00
        RET                              ; $AB41  C9
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
        LD C,A                           ; $AB42  4F
        ; read the CP/M IOBYTE (page-zero $0003)
        LD A,($0003)                     ; $AB43  3A 03 00
        ; isolate the 2-bit CONSOLE device field of the IOBYTE
        AND $03                          ; $AB46  E6 03
        ; device value 2 = direct console; anything else takes the filter path
        CP $02                           ; $AB48  FE 02
        JR NZ,CONOUT_FILTER_NOEXPAND                ; $AB4A  20 4B
LIST_VIA_VEC_F392:
        ; load console-output handler addr from SoftCard I/O vector ($F392 = Apple $0392)
        LD HL,($F392)                    ; $AB4C  2A 92 F3
        JP (HL)                          ; $AB4F  E9
; ----------------------------------------------------------------------
; CONIN -- read a console character, routed by the IOBYTE CONSOLE field.
;   In:  none. Out: A = character. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask CONSOLE field (AND $03), and select one of three
;              input-handler vector cells by the field value: value 2 uses $F38A, value 3
;              ($02<x) uses the already-loaded $F384, the low values use $F382; then
;              JP (HL) into the chosen handler. ($F38x = Apple $038x I/O vector.) [RE]
; ----------------------------------------------------------------------
CONIN:
        LD A,($0003)                     ; $AB50  3A 03 00
        AND $03                          ; $AB53  E6 03
        CP $02                           ; $AB55  FE 02
        ; preload input-handler vector for the high CONSOLE field value ($F384 = Apple $0384)
        LD HL,($F384)                    ; $AB57  2A 84 F3
        JR Z,CONIN_VIA_VEC_F38A                  ; $AB5A  28 06
        JR NC,DISPATCH_VIA_HL                 ; $AB5C  30 07
CONIN_VIA_VEC_F382:
        ; input-handler vector for the low CONSOLE field values ($F382 = Apple $0382)
        LD HL,($F382)                    ; $AB5E  2A 82 F3
        JP (HL)                          ; $AB61  E9
CONIN_VIA_VEC_F38A:
        ; input-handler vector for CONSOLE field value 2 ($F38A = Apple $038A)
        LD HL,($F38A)                    ; $AB62  2A 8A F3
DISPATCH_VIA_HL:
        JP (HL)                          ; $AB65  E9
; ----------------------------------------------------------------------
; LIST -- emit a character to the list device, routed by the IOBYTE LIST field.
;   In:  C = character. Out: none. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the top 2-bit LIST field (AND $C0). Field value below
;              $80 routes to the column/tab filter (CONOUT_FILTER); value == $80 reuses
;              the console vector path (LIST_VIA_VEC_F392); higher values dispatch through
;              the list-handler vector cell $F394 (Apple $0394). [RE]
; ----------------------------------------------------------------------
LIST:
        LD A,($0003)                     ; $AB66  3A 03 00
        ; isolate the 2-bit LIST device field (top bits of the IOBYTE)
        AND $C0                          ; $AB69  E6 C0
        CP $80                           ; $AB6B  FE 80
        JR C,CONOUT_FILTER                  ; $AB6D  38 27
        JR Z,LIST_VIA_VEC_F392                  ; $AB6F  28 DB
        ; load list-handler vector ($F394 = Apple $0394)
        LD HL,($F394)                    ; $AB71  2A 94 F3
        JP (HL)                          ; $AB74  E9
; ----------------------------------------------------------------------
; PUNCH -- emit a character to the punch device, routed by the IOBYTE PUNCH field.
;   In:  C = character. Out: none. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the PUNCH field (AND $30). Field value below $10 takes
;              the column/tab filter; value $10 dispatches through vector $F390; higher
;              values dispatch through vector $F38E. ($F38E/$F390 = Apple $038E/$0390.) [RE]
; ----------------------------------------------------------------------
PUNCH:
        LD A,($0003)                     ; $AB75  3A 03 00
        ; isolate the 2-bit PUNCH device field of the IOBYTE
        AND $30                          ; $AB78  E6 30
        CP $10                           ; $AB7A  FE 10
        JR C,CONOUT_FILTER                  ; $AB7C  38 18
        ; punch-handler vector for the higher PUNCH field values ($F38E = Apple $038E)
        LD HL,($F38E)                    ; $AB7E  2A 8E F3
        JR NZ,DISPATCH_VIA_HL                 ; $AB81  20 E2
        ; punch-handler vector for PUNCH field value $10 ($F390 = Apple $0390)
        LD HL,($F390)                    ; $AB83  2A 90 F3
        JP (HL)                          ; $AB86  E9
; ----------------------------------------------------------------------
; READER -- read a character from the reader device, routed by the IOBYTE READER field.
;   In:  none. Out: A = character. Clobbers: A,HL.
;   Algorithm: read IOBYTE, mask the READER field (AND $0C). Field value below $04
;              reuses the CONIN low-value vector path; value $04 reuses the CONIN $F38A
;              path; higher values dispatch through reader vector $F38C (Apple $038C). [RE]
; ----------------------------------------------------------------------
READER:
        LD A,($0003)                     ; $AB87  3A 03 00
        ; isolate the 2-bit READER device field of the IOBYTE
        AND $0C                          ; $AB8A  E6 0C
        CP $04                           ; $AB8C  FE 04
        JR C,CONIN_VIA_VEC_F382                  ; $AB8E  38 CE
        JR Z,CONIN_VIA_VEC_F38A                  ; $AB90  28 D0
        ; load reader-handler vector ($F38C = Apple $038C)
        LD HL,($F38C)                    ; $AB92  2A 8C F3
        JP (HL)                          ; $AB95  E9
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
        SCF                              ; $AB96  37
CONOUT_FILTER_NOEXPAND:
        ; convert carry into a 0/$FF flag byte for COL_FLAG
        SBC A,A                          ; $AB97  9F
        LD HL,COL_FLAG               ; $AB98  21 A2 AE
        ; store the entry flag into COL_FLAG
        LD (HL),A                        ; $AB9B  77
        ; strip the high bit of the character (7-bit ASCII)
        RES 7,C                          ; $AB9C  CB B9
        INC HL                           ; $AB9E  23
        ; load COL_PENDING (pending column-skip / fill count)
        LD A,(HL)                        ; $AB9F  7E
        OR A                             ; $ABA0  B7
        ; no pending column work -> go run tab/control expansion
        JR Z,TAB_EXPAND                  ; $ABA1  28 3D
        ; consume one pending column step
        DEC (HL)                         ; $ABA3  35
        ; read screen-width / left-margin config byte ($F396 = Apple $0396)
        LD A,($F396)                     ; $ABA4  3A 96 F3
        LD HL,DISK_SELDSK_SAVE                 ; $ABA7  21 AB AE
        JR Z,COL_OFFSET_FROM_WIDTH                  ; $ABAA  28 0C
        OR A                             ; $ABAC  B7
        JP P,COL_APPLY_OFFSET_RAW                  ; $ABAD  F2 B3 AB
        DEC HL                           ; $ABB0  2B
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
        AND $7F                          ; $ABB1  E6 7F
COL_APPLY_OFFSET_RAW:
        LD E,A                           ; $ABB3  5F
        LD A,C                           ; $ABB4  79
        ; new column = current column (C) minus the offset
        SUB E                            ; $ABB5  93
        ; store the updated column position
        LD (HL),A                        ; $ABB6  77
        RET                              ; $ABB7  C9
COL_OFFSET_FROM_WIDTH:
        OR A                             ; $ABB8  B7
        JP M,COL_OFFSET_FROM_WIDTH_1                  ; $ABB9  FA BD AB
        DEC HL                           ; $ABBC  2B
COL_OFFSET_FROM_WIDTH_1:
        CALL COL_APPLY_OFFSET                    ; $ABBD  CD B1 AB
        LD HL,(BOOT+2)             ; $ABC0  2A AA AE
        LD A,($F3A1)                     ; $ABC3  3A A1 F3
        OR A                             ; $ABC6  B7
        JP P,COL_COMBINE_BASE                  ; $ABC7  F2 CF AB
        AND $7F                          ; $ABCA  E6 7F
        LD E,L                           ; $ABCC  5D
        LD L,H                           ; $ABCD  6C
        LD H,E                           ; $ABCE  63
COL_COMBINE_BASE:
        LD E,A                           ; $ABCF  5F
        ADD A,H                          ; $ABD0  84
        LD C,A                           ; $ABD1  4F
        LD A,E                           ; $ABD2  7B
        ADD A,L                          ; $ABD3  85
        PUSH AF                          ; $ABD4  F5
        LD B,$07                         ; $ABD5  06 07
        CALL SCREEN_EMIT                    ; $ABD7  CD 2D AC
        POP AF                           ; $ABDA  F1
        LD B,$0A                         ; $ABDB  06 0A
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
        LD C,A                           ; $ABDD  4F
        JR SCREEN_EMIT                      ; $ABDE  18 4D
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
        LD B,A                           ; $ABE0  47
        ; HL -> COL_STATE sticky control-state cell
        LD HL,COL_STATE                 ; $ABE1  21 A4 AE
        LD A,(HL)                        ; $ABE4  7E
        LD E,A                           ; $ABE5  5F
        OR A                             ; $ABE6  B7
        JR NZ,TAB_TABLE_SCAN                 ; $ABE7  20 11
        ; read the special trigger character from config ($F397 = Apple $0397)
        LD A,($F397)                     ; $ABE9  3A 97 F3
        OR A                             ; $ABEC  B7
        JR Z,TAB_EXPAND_CHECK_CTRL                  ; $ABED  28 06
        ; does the current character match the trigger?
        CP C                             ; $ABEF  B9
        JR NZ,TAB_EXPAND_CHECK_CTRL                 ; $ABF0  20 03
        ; arm the sticky control state for the next character
        LD (HL),$80                      ; $ABF2  36 80
        RET                              ; $ABF4  C9
TAB_EXPAND_CHECK_CTRL:
        ; control-char threshold: chars <= $1F are not table-scanned
        LD A,$1F                         ; $ABF5  3E 1F
        CP C                             ; $ABF7  B9
        JR C,SCREEN_EMIT                    ; $ABF8  38 33
TAB_TABLE_SCAN:
        ; HL -> top of the 9-entry tab-stop config table ($F3A0 = Apple $03A0)
        LD HL,$F3A0                      ; $ABFA  21 A0 F3
        ; 9 tab-stop table entries to scan
        LD B,$09                         ; $ABFD  06 09
TAB_TABLE_SCAN_LOOP:
        LD A,(HL)                        ; $ABFF  7E
        OR A                             ; $AC00  B7
        JR Z,TAB_TABLE_SCAN_NEXT                  ; $AC01  28 04
        ; fold in COL_STATE before comparing the table entry to the char
        XOR E                            ; $AC03  AB
        CP C                             ; $AC04  B9
        JR Z,TAB_TABLE_HIT                  ; $AC05  28 05
TAB_TABLE_SCAN_NEXT:
        DEC HL                           ; $AC07  2B
        DJNZ TAB_TABLE_SCAN_LOOP                  ; $AC08  10 F5
        JR SCREEN_EMIT                      ; $AC0A  18 21
TAB_TABLE_HIT:
        ; step +$0B from the matched stop to its parallel action byte
        LD DE,$000B                      ; $AC0C  11 0B 00
        ADD HL,DE                        ; $AC0F  19
        LD A,(HL)                        ; $AC10  7E
        OR A                             ; $AC11  B7
        LD C,A                           ; $AC12  4F
        JP P,TAB_EXPAND_DONE                  ; $AC13  F2 23 AC
        AND $7F                          ; $AC16  E6 7F
        LD C,A                           ; $AC18  4F
        PUSH BC                          ; $AC19  C5
        ; secondary action character from config ($F3A2 = Apple $03A2)
        LD A,($F3A2)                     ; $AC1A  3A A2 F3
        LD B,$07                         ; $AC1D  06 07
        CALL CONOUT_EMIT_B                    ; $AC1F  CD DD AB
        POP BC                           ; $AC22  C1
TAB_EXPAND_DONE:
        LD A,B                           ; $AC23  78
        ; action code 7 -> set COL_MODE = 2
        CP $07                           ; $AC24  FE 07
        JR NZ,SCREEN_EMIT                   ; $AC26  20 05
        LD A,$02                         ; $AC28  3E 02
        ; record COL_MODE = 2 for the next emit
        LD (COL_PENDING),A                ; $AC2A  32 A3 AE
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
        XOR A                            ; $AC2D  AF
        ; clear the pending wrap/scroll flag before emitting
        ; clear COL_STATE before handing off to the screen handler
        LD (COL_STATE),A                ; $AC2E  32 A4 AE
        ; screen-mode selector: chooses which driver entry to vector to [RE]
        ; test COL_FLAG to choose which screen-output vector to use
        LD A,(COL_FLAG)              ; $AC31  3A A2 AE
        OR A                             ; $AC34  B7
        ; default screen-driver entry (SoftCard vector table, Apple $0388)
        ; default screen-output vector ($F388 = Apple $0388)
        LD HL,($F388)                    ; $AC35  2A 88 F3
        JR Z,SCREEN_EMIT_VECTOR                  ; $AC38  28 03
        ; alternate screen-driver entry (Apple $0386) when selector nonzero
        ; alternate screen-output vector ($F386 = Apple $0386)
        LD HL,($F386)                    ; $AC3A  2A 86 F3
; ----------------------------------------------------------------------
; Merge point: HL = the selected screen-driver entry; fall through to the JP (HL).
; ----------------------------------------------------------------------
SCREEN_EMIT_VECTOR:
        ; tail-jump into the selected screen-driver entry point
        JP (HL)                          ; $AC3D  E9
; ----------------------------------------------------------------------
; PUT_CHAR_DE3 -- screen-driver entry that preloads DE=3 (advance amount / column
; step) and falls into the glyph-store path. [RE]
;   In:  driver state cells as set up by CONOUT_VIA_SCREEN.
;   Out: none. Clobbers: A,DE,HL.
; ----------------------------------------------------------------------
PUT_CHAR_DE3:
        ; preset DE = column/advance step for this driver variant [RE]
        LD DE,$0003                      ; $AC3E  11 03 00
; ----------------------------------------------------------------------
; PUT_CHAR_VECTOR -- indirect entry into the glyph-store body. This JP's target
; operand is SELF-MODIFIED elsewhere (patch site = PUT_CHAR_VECTOR+1); it normally
; points at PUT_CHAR_STORE. Treat the +1/+2 bytes as the live dispatch target. [RE]
; ----------------------------------------------------------------------
PUT_CHAR_VECTOR:
        ; dispatch into the glyph-store body; target operand (PUT_CHAR_VECTOR+1) is patched at
        ; runtime [RE]
        JP PUT_CHAR_STORE                    ; $AC41  C3 44 AC
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
        LD HL,(SCREEN_CURSOR_PTR)               ; $AC44  2A A5 AE
        ; A = staged glyph (the real char that belongs in that cell)
        LD A,(SCREEN_CHAR)                ; $AC47  3A A7 AE
        ; draw the inverse-video cursor glyph in the new cell
        ; restore the real char into the old cursor cell
        LD (HL),A                        ; $AC4A  77
        ; run control-char handling / cursor advance (may update CH=$F024)
        CALL CTRL_CHAR_DISPATCH                    ; $AC4B  CD 6B AC
        ; HL = current text line base BASL/BASH (Apple ZP $0028/$0029)
        LD HL,($F028)                    ; $AC4E  2A 28 F0
        ; A = cursor column CH (Apple ZP $0024)
        LD A,($F024)                     ; $AC51  3A 24 F0
        LD E,A                           ; $AC54  5F
        ; high byte $F0 maps column offset into the Apple low-RAM screen region
        LD D,$F0                         ; $AC55  16 F0
        ; HL = BASL + CH = address of the new cursor cell
        ADD HL,DE                        ; $AC57  19
        ; save the new cursor cell pointer
        LD (SCREEN_CURSOR_PTR),HL               ; $AC58  22 A5 AE
        LD A,(HL)                        ; $AC5B  7E
        ; save the char currently under the cursor (to restore later)
        LD (SCREEN_CHAR),A                ; $AC5C  32 A7 AE
        ; is the char in the lowercase/high range? choose inverse-video mapping
        CP $E0                           ; $AC5F  FE E0
        JR C,PUT_CHAR_CURSOR_GLYPH                  ; $AC61  38 02
        ; fold lowercase to its display form for the cursor glyph
        XOR $20                          ; $AC63  EE 20
; ----------------------------------------------------------------------
; Merge point in the cursor-glyph conversion (chars below $E0 skip the XOR $20 fold).
; ----------------------------------------------------------------------
PUT_CHAR_CURSOR_GLYPH:
        ; mask to 6-bit glyph code
        AND $3F                          ; $AC65  E6 3F
        ; set inverse/flash field for the on-screen cursor glyph
        OR $40                           ; $AC67  F6 40
        LD (HL),A                        ; $AC69  77
        RET                              ; $AC6A  C9
; ----------------------------------------------------------------------
; CTRL_CHAR_DISPATCH -- handle a control character / cursor-motion code by indexing a
; per-code offset table and jumping to the matching handler body.
;   In:  B = control-code index (0 = none/plain char). A is loaded from B.
;   Out: per-handler (typically updates CH=$F024 and/or the line base). Clobbers A,HL.
;   Algorithm: if B==0 fall through to the plain-character handler at CTRL_PLAIN_CHAR. Else
;              push RET address SUB_AB3B (handlers RET back into the caller's flow),
;              load HL = the offset table base (CTRL_HANDLER_OFFSET_TBL), add the code to L, read
;              the
;              handler's low byte from the table, and JP (HL) into page $AC where all
;              the handler bodies live. See flags[] for the exact table/body layout.
;   NOTE: the byte stream $AC77-$ACD3 below the ADD A,L is the dispatch tail + handler
;         bodies (CODE currently left as DEFB); $ACD4-$ACE5 is the offset table + a
;         trailing helper. UNKNOWN exactly which control code maps to which handler
;         until the bodies are disassembled.
; ----------------------------------------------------------------------
CTRL_CHAR_DISPATCH:
        ; A = control-code index passed in B
        LD A,B                           ; $AC6B  78
        ; index 0 means plain character: fall through to CTRL_PLAIN_CHAR
        OR A                             ; $AC6C  B7
        ; no control code: take the plain-char store path
        JR Z,CTRL_PLAIN_CHAR                      ; $AC6D  28 0B
        ; push the common return address so each handler RETs back here [RE]
        LD HL,SUB_AB3B                   ; $AC6F  21 3B AB
        PUSH HL                          ; $AC72  E5
        ; HL = base of the per-code handler offset table
        LD HL,CTRL_HANDLER_OFFSET_TBL                     ; $AC73  21 D4 AC
        ; index the table: L = table_base_low + control-code; (HL) then holds the handler low byte
        ; [RE]
        ADD A,L                          ; $AC76  85
        DEFB    $6F,$6E,$E9                                      ; $AC77
CTRL_PLAIN_CHAR:
        DEFB    $79,$FE,$0D,$20,$05                              ; $AC7A
        DEFB    $AF,$32,$24,$F0,$C9,$F6,$80                      ; $AC7F  "/2$pIv"
        DEFB    $FE,$E0,$38,$04,$21,$DD,$F3,$AE,$32,$45,$F0,$21,$F0,$FD,$18,$79 ; $AC86
        DEFB    $3E,$FF,$01,$3E,$3F,$32,$32,$F0,$E1,$C9,$21,$F4,$FB,$C9,$AF,$6F ; $AC96
        DEFB    $67,$22,$24,$F0,$32,$45,$F0,$21,$C1,$FB,$C9,$2E,$42,$01,$2E,$9C ; $ACA6
        DEFB    $01,$2E,$1A,$01,$2E,$58,$26,$FC,$C9,$2A,$AA,$AE,$7D,$FE,$28,$38 ; $ACB6
        DEFB    $02,$2E,$00,$7C,$FE,$18,$38,$02,$26,$00,$22,$24,$F0,$18 ; $ACC6
CTRL_HANDLER_OFFSET_TBL:
        DEFB    $D5,$BA,$B1,$B4,$96,$99,$A4,$9E,$B7,$A0,$BF,$CD,$60,$AD,$7E,$E6 ; $ACD4
        DEFB    $02,$28,$FB,$2C,$71,$C9                          ; $ACE4
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
        LD A,C                           ; $ACEA  79
        ; store cursor column (Apple ZP $0045) [RE]
        LD ($F045),A                     ; $ACEB  32 45 F0
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
        CALL SLOT_IO_ADDR_W                    ; $ACEE  CD 5B AD
        ; save base into scratch cell (Apple $06F8)
        LD ($F6F8),A                     ; $ACF1  32 F8 F6
        ; store base into a screen-base cell (Apple ZP $0047)
        LD ($F047),A                     ; $ACF4  32 47 F0
        ; read a column/value from SoftCard I/O ($EFFF = Apple $CFFF) [RE]
        LD A,($EFFF)                     ; $ACF7  3A FF EF
        CALL DEVICE_IO_BASE                    ; $ACFA  CD C5 AA
        ; remove the space ($20) bias to get a screen offset [RE]
        SUB $20                          ; $ACFD  D6 20
        ; store the computed offset into a screen-base cell (Apple ZP $0046)
        LD ($F046),A                     ; $ACFF  32 46 F0
        ; return the character currently at the computed cell
        LD A,(HL)                        ; $AD02  7E
        RET                              ; $AD03  C9
; ----------------------------------------------------------------------
; PLOT_CHAR_AT_COL -- position to a column then write C into the row buffer at that
; offset, and tail-jump to the common screen-driver return.
;   In:  C = character; DE = column offset; cursor row state.
;   Out: char stored into the row buffer at $F678+DE (Apple $0678+DE). [RE]
;   Algorithm: recompute the base via SET_CURSOR_COL_AND_BASE, form $F678+DE,
;              store C, then JP SUB_AB3B (shared driver epilogue). [RE]
; ----------------------------------------------------------------------
PLOT_CHAR_AT_COL:
        ; set cursor column and recompute the row base
        CALL SET_CURSOR_COL_AND_BASE                    ; $AD04  CD EA AC
        ; HL = row buffer base (Apple $0678) [RE]
        LD HL,$F678                      ; $AD07  21 78 F6
        ; HL = buffer base + column offset DE
        ADD HL,DE                        ; $AD0A  19
        ; store the character at the target column
        LD (HL),C                        ; $AD0B  71
        LD HL,$C9AA                      ; $AD0C  21 AA C9
        ; tail into the shared screen-driver return path
        JP SUB_AB3B                      ; $AD0F  C3 3B AB
        DEFB    $CD,$60,$AD,$7E,$1F,$30,$FC,$2C,$7E,$C9,$CD,$EE,$AC,$21,$4D,$C8 ; $AD12
        DEFB    $CD,$3B,$AB,$21,$78,$F6,$19,$7E,$C9,$11,$01,$00,$C3 ; $AD22
L_AD2F:
        DEFB    $3E,$AD,$CD,$C5,$AA,$2E,$C1,$7E,$17,$38,$FC,$CD,$5B,$AD,$71,$C9 ; $AD2F
        DEFB    $11,$02,$00,$C3                                  ; $AD3F
L_AD43:
        DEFB    $3E,$AD,$11,$02,$00                              ; $AD43
L_AD48:
        DEFB    $C3                                              ; $AD48
L_AD49:
        DEFB    "\0"    ; $AD49
L_AD4A:
        DEFB    "\0"    ; $AD4A
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
        LD A,(DISK_HSTWRT)               ; $AD4B  3A B0 AE
        OR A                             ; $AD4E  B7
        JR NZ,SETTRK_STORE                 ; $AD4F  20 03
        ; no pending write: clear hstact so the host buffer is reloaded on next access
        LD (DISK_SEKDSK+2),A             ; $AD51  32 AF AE
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
        LD C,$00                         ; $AD54  0E 00
        ; track number from BDOS
        LD A,C                           ; $AD56  79
        ; store into sektrk (overlaid on the BOOT entry's LD SP operand)
        LD (BOOT),A                ; $AD57  32 A8 AE
        RET                              ; $AD5A  C9
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
        LD HL,$E080                      ; $AD5B  21 80 E0
        JR SLOT_IO_SCALE_E                    ; $AD5E  18 03
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
        LD HL,$E08E                      ; $AD60  21 8E E0
SLOT_IO_SCALE_E:
        ; slot/drive index
        LD A,E                           ; $AD63  7B
SLOT_IO_SCALE:
        ADD A,A                          ; $AD64  87
        ADD A,A                          ; $AD65  87
        ADD A,A                          ; $AD66  87
        ADD A,A                          ; $AD67  87
        PUSH AF                          ; $AD68  F5
        ADD A,L                          ; $AD69  85
        LD L,A                           ; $AD6A  6F
        POP AF                           ; $AD6B  F1
        RET                              ; $AD6C  C9
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
        LD DE,DISK_SELDSK_SAVE+1               ; $AD6D  11 AC AE
        LD HL,$0004                      ; $AD70  21 04 00
        ; configured drive count from Apple config $03B8
        LD A,($F3B8)                     ; $AD73  3A B8 F3
        DEC A                            ; $AD76  3D
        ; requested drive vs (count-1); C-flag set if out of range
        CP C                             ; $AD77  B9
        ; out of range -> return HL=0
        JR C,SELDSK_BAD_DRIVE                  ; $AD78  38 0A
        LD A,(HL)                        ; $AD7A  7E
        ; store the marker, then the selected disk number into sekdsk
        LD (DE),A                        ; $AD7B  12
        INC DE                           ; $AD7C  13
        LD A,C                           ; $AD7D  79
        LD (DE),A                        ; $AD7E  12
        ; base DPH; SLOT_IO_SCALE indexes it by the drive number
        LD HL,DISK_PARAM_TABLE                     ; $AD7F  21 33 AA
        JR SLOT_IO_SCALE                    ; $AD82  18 E0
SELDSK_BAD_DRIVE:
        LD A,(DE)                        ; $AD84  1A
        LD (HL),A                        ; $AD85  77
        LD L,$00                         ; $AD86  2E 00
        RET                              ; $AD88  C9
; ----------------------------------------------------------------------
; SETSEC -- BIOS jump-vector entry: set the requested sector.
;   In:  C = sector number.
;   Out: none. Clobbers: A.
;   Algorithm: store C into seksec (the BDOS-requested sector, overlaid on BOOT+1).
;              Consumed later by the deblock host-match test.
; ----------------------------------------------------------------------
SETSEC:
        LD A,C                           ; $AD89  79
        ; store into seksec
        LD (BOOT+1),A              ; $AD8A  32 A9 AE
        RET                              ; $AD8D  C9
; ----------------------------------------------------------------------
; SETDMA -- BIOS jump-vector entry: set the DMA (record transfer) address.
;   In:  BC = DMA buffer address (where the 128-byte CP/M record is read to/written from).
;   Out: none. Clobbers: none.
;   Algorithm: store BC into dmaadr; the deblock copy (LDIR) uses it as the host<->record
;              transfer endpoint.
; ----------------------------------------------------------------------
SETDMA:
        ; store the DMA address into dmaadr
        LD (DISK_DMAADR),BC              ; $AD8E  ED 43 B8 AE
        RET                              ; $AD92  C9
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
        XOR A                            ; $AD93  AF
        ; unacnt = 0: a read never continues an unallocated-write run
        LD (DISK_WRTYPE+2),A             ; $AD94  32 B4 AE
        LD A,$02                         ; $AD97  3E 02
        ; HL -> readop; seed readop and the following flag bytes = 2 (read operation)
        LD HL,DISK_HSTWRT+1              ; $AD99  21 B1 AE
        LD (HL),A                        ; $AD9C  77
        INC HL                           ; $AD9D  23
        LD (HL),A                        ; $AD9E  77
        INC HL                           ; $AD9F  23
        LD (HL),A                        ; $ADA0  77
        ; enter the shared deblock core (skip the write-only pre-roll)
        JR DEBLOCK_CORE                    ; $ADA1  18 4F
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
        LD H,C                           ; $ADA3  61
        LD L,$00                         ; $ADA4  2E 00
        ; readop = wrtype (from C), clear the adjacent flag byte
        LD (DISK_HSTWRT+1),HL            ; $ADA6  22 B1 AE
        LD A,C                           ; $ADA9  79
        ; wrtype 2 = write to an unallocated block (start a sequential run)
        CP $02                           ; $ADAA  FE 02
        ; ordinary write: skip the unalloc-run seeding
        JR NZ,DEBLOCK_CHECK_UNALLOC                 ; $ADAC  20 0F
        ; unacnt = 8 records in the new unallocated run (host blocking factor)
        LD L,$08                         ; $ADAE  2E 08
        ; compare sekdsk against the run's disk
        LD A,(DISK_SEKDSK)               ; $ADB0  3A AD AE
        LD H,A                           ; $ADB3  67
        ; seed unacnt (and the next byte) for the run
        LD (DISK_WRTYPE+2),HL            ; $ADB4  22 B4 AE
        ; anchor the run's next-track/sector (unatrk/unasec) at the requested sektrk/seksec
        LD HL,(BOOT)               ; $ADB7  2A A8 AE
        ; advance unatrk/unasec to the next record in the run
        LD (DISK_UNADSK+1),HL            ; $ADBA  22 B6 AE
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
        LD HL,DISK_WRTYPE+2              ; $ADBD  21 B4 AE
        ; unacnt: zero means no active unalloc run
        LD A,(HL)                        ; $ADC0  7E
        OR A                             ; $ADC1  B7
        JR Z,DEBLOCK_FORCE_PREREAD                  ; $ADC2  28 28
        ; consume one record of the unallocated run
        DEC (HL)                         ; $ADC4  35
        LD A,(DISK_SEKDSK)               ; $ADC5  3A AD AE
        INC HL                           ; $ADC8  23
        CP (HL)                          ; $ADC9  BE
        JR NZ,DEBLOCK_FORCE_PREREAD                 ; $ADCA  20 20
        LD A,(BOOT)                ; $ADCC  3A A8 AE
        ; load unatrk/unasec (the run's current track/sector)
        LD HL,(DISK_UNADSK+1)            ; $ADCF  2A B6 AE
        CP L                             ; $ADD2  BD
        JR NZ,DEBLOCK_FORCE_PREREAD                 ; $ADD3  20 17
        ; requested seksec vs the run's sector
        LD A,(BOOT+1)              ; $ADD5  3A A9 AE
        CP H                             ; $ADD8  BC
        JR NZ,DEBLOCK_FORCE_PREREAD                 ; $ADD9  20 11
        ; advance the unalloc sector; wrap to next track when it passes the sectors-per-track limit
        ; ($20)
        INC H                            ; $ADDB  24
        LD A,H                           ; $ADDC  7C
        SUB $20                          ; $ADDD  D6 20
        JR C,DEBLOCK_RUN_CONTINUES                  ; $ADDF  38 02
        LD H,A                           ; $ADE1  67
        INC L                            ; $ADE2  2C
DEBLOCK_RUN_CONTINUES:
        LD (DISK_UNADSK+1),HL            ; $ADE3  22 B6 AE
        XOR A                            ; $ADE6  AF
        ; rsflag = 0: record continues the run, no host pre-read needed
        LD (DISK_WRTYPE+1),A             ; $ADE7  32 B3 AE
        JR DEBLOCK_CORE                    ; $ADEA  18 06
DEBLOCK_FORCE_PREREAD:
        ; rsflag = 1: record breaks the run, force a host-sector pre-read
        LD HL,$0001                      ; $ADEC  21 01 00
        LD (DISK_WRTYPE+1),HL            ; $ADEF  22 B3 AE
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
        CALL READ_SEKSEC                    ; $ADF2  CD F0 AF
        LD E,A                           ; $ADF5  5F
        RRA                              ; $ADF6  1F
        ; translate logical sector -> physical via the skew table
        LD HL,SECTOR_XLATE                 ; $ADF7  21 92 AE
        ADD A,L                          ; $ADFA  85
        LD L,A                           ; $ADFB  6F
        LD C,(HL)                        ; $ADFC  4E
        ; HL -> hstact; remember prior state, then mark the host buffer active
        LD HL,DISK_SEKDSK+2              ; $ADFD  21 AF AE
        LD A,(HL)                        ; $AE00  7E
        ; hstact = 1 (host buffer now in use)
        LD (HL),$01                      ; $AE01  36 01
        OR A                             ; $AE03  B7
        ; host buffer was inactive: no flush/match test needed, go set up RWTS
        JR Z,DEBLOCK_SETUP_RWTS                  ; $AE04  28 1B
        ; compare sekdsk vs hstdsk (host buffer's disk)
        LD HL,(DISK_SEKDSK)              ; $AE06  2A AD AE
        LD A,L                           ; $AE09  7D
        CP H                             ; $AE0A  BC
        JR NZ,DEBLOCK_NEED_RELOAD                 ; $AE0B  20 0D
        ; Apple $03E0 = current RWTS track/sector in the host buffer
        LD HL,($F3E0)                    ; $AE0D  2A E0 F3
        ; requested sektrk vs host buffer track
        LD A,(BOOT)                ; $AE10  3A A8 AE
        CP L                             ; $AE13  BD
        JR NZ,DEBLOCK_NEED_RELOAD                 ; $AE14  20 04
        LD A,C                           ; $AE16  79
        CP H                             ; $AE17  BC
        ; requested record already in the host buffer -> skip flush and re-read, go straight to the
        ; copy
        JR Z,DEBLOCK_COPY_RECORD                  ; $AE18  28 33
DEBLOCK_NEED_RELOAD:
        ; hstwrt: if the outgoing host buffer is dirty, flush it first
        LD A,(DISK_HSTWRT)               ; $AE1A  3A B0 AE
        OR A                             ; $AE1D  B7
        ; flush the dirty host buffer before reloading
        CALL NZ,CONFIG_PROBE                 ; $AE1E  C4 73 AE
DEBLOCK_SETUP_RWTS:
        LD A,(DISK_SEKDSK)               ; $AE21  3A AD AE
        LD (DISK_SEKDSK+1),A             ; $AE24  32 AE AE
        LD B,A                           ; $AE27  47
        AND $01                          ; $AE28  E6 01
        INC A                            ; $AE2A  3C
        ; Apple $03E4 = RWTS unit/volume cell
        LD ($F3E4),A                     ; $AE2B  32 E4 F3
        LD A,B                           ; $AE2E  78
        AND $0E                          ; $AE2F  E6 0E
        ADD A,A                          ; $AE31  87
        ADD A,A                          ; $AE32  87
        ADD A,A                          ; $AE33  87
        CPL                              ; $AE34  2F
        ADD A,$61                        ; $AE35  C6 61
        ; Apple $03E6 = RWTS track cell
        LD ($F3E6),A                     ; $AE37  32 E6 F3
        LD A,(BOOT)                ; $AE3A  3A A8 AE
        LD L,A                           ; $AE3D  6F
        LD H,C                           ; $AE3E  61
        ; Apple $03E0 = record the host buffer's new track/sector
        LD ($F3E0),HL                    ; $AE3F  22 E0 F3
        ; rsflag: nonzero -> physically pre-read the host sector
        LD A,(DISK_WRTYPE+1)             ; $AE42  3A B3 AE
        OR A                             ; $AE45  B7
        ; perform the host sector read (RWTS read entry)
        CALL NZ,CONIO_SET_A1             ; $AE46  C4 7A AE
        XOR A                            ; $AE49  AF
        ; hstwrt = 0 after a fresh read
        LD (DISK_HSTWRT),A               ; $AE4A  32 B0 AE
DEBLOCK_COPY_RECORD:
        LD A,E                           ; $AE4D  7B
        ; z80 $F800 = Apple $0800 host sector buffer base
        LD HL,$F800                      ; $AE4E  21 00 F8
        RRA                              ; $AE51  1F
        ; select the upper/lower 128-byte half of the host sector from the record's parity
        RR L                             ; $AE52  CB 1D
        ; dmaadr = the CP/M record buffer
        LD DE,(DISK_DMAADR)              ; $AE54  ED 5B B8 AE
        ; 128-byte CP/M record length
        LD BC,$0080                      ; $AE58  01 80 00
        ; readop: nonzero = read (host->DMA), zero = write (DMA->host)
        LD A,(DISK_HSTWRT+1)             ; $AE5B  3A B1 AE
        OR A                             ; $AE5E  B7
        JR NZ,DEBLOCK_COPY                ; $AE5F  20 05
        INC A                            ; $AE61  3C
        LD (DISK_HSTWRT),A               ; $AE62  32 B0 AE
        ; write direction: swap so LDIR copies DMA -> host buffer
        EX DE,HL                         ; $AE65  EB
DEBLOCK_COPY:
        ; copy the 128-byte record host<->DMA
        LDIR                             ; $AE66  ED B0
        ; wrtype: bit 0 decides whether a write must flush immediately (directory write)
        LD A,(DISK_WRTYPE)               ; $AE68  3A B2 AE
        RRA                              ; $AE6B  1F
        LD A,$00                         ; $AE6C  3E 00
        RET NC                           ; $AE6E  D0
        ; immediate flush of the dirty host buffer
        CALL CONFIG_PROBE                    ; $AE6F  CD 73 AE
        RET                              ; $AE72  C9
; ----------------------------------------------------------------------
; CONFIG_PROBE -- re-detect the console device and reset the deblock state.
;   In:  none (reads the SoftCard config/IOBYTE cells in Apple page $03).
;   Out: none. Clobbers: A,HL,DE.
;   Algorithm: clear the host-sector-active flag (PATCH_LDA_HSTACT operand cell),
;              default A=2, then via the CONIO_SET_A1 cover entry set the console
;              selector at $F3EB=Apple $03EB and probe the device through SUB_AB3B.
;              If the probe returns a non-zero device class (==$10) it pops the
;              return address and tail-jumps through the vector at $9C0D. Called
;              at cold boot (from BOOT path) and on a disk-select change. [RE]
; ----------------------------------------------------------------------
CONFIG_PROBE:
        XOR A                            ; $AE73  AF
        ; clear the host-active deblock flag (this LD A operand cell doubles as the disk hstact var)
        LD (DISK_HSTWRT),A               ; $AE74  32 B0 AE
        LD A,$02                         ; $AE77  3E 02
        DEFB    $21                      ; $AE79  cover (LD HL,nn opcode): on fall-through absorbs the
                                         ;        LD A,$01 below, leaving A=$02 from $AE77
CONIO_SET_A1:
        LD A,$01                         ; $AE7A  CALL'd directly -> A=$01 (cover-skipped on fall-through)
        ; store the console-selector index into the SoftCard config block (Apple $03EB)
        LD ($F3EB),A                     ; $AE7C  32 EB F3
        LD HL,$0E03                      ; $AE7F  21 03 0E
        ; probe/init the selected console device handler
        CALL SUB_AB3B                    ; $AE82  CD 3B AB
        ; read the detected device-class byte from the config block (Apple $03EA)
        LD A,($F3EA)                     ; $AE85  3A EA F3
        OR A                             ; $AE88  B7
        ; no special device class -> done
        RET Z                            ; $AE89  C8
        POP DE                           ; $AE8A  D1
        ; device class $10 -> dispatch through the installed handler vector
        CP $10                           ; $AE8B  FE 10
        RET NZ                           ; $AE8D  C0
        ; fetch the handler entry from the CCP/loader vector cell and tail-jump to it [RE]
        LD HL,($9C0D)                    ; $AE8E  2A 0D 9C
        JP (HL)                          ; $AE91  E9
; ----------------------------------------------------------------------
; SECTOR_XLATE -- 16-entry logical->physical sector skew table (a 0..15 permutation).
;   Indexed by the deblock code (LD A,L add-offset lookup) to translate a CP/M logical
;   sector to the physical RWTS sector. DATA, not code.
; ----------------------------------------------------------------------
SECTOR_XLATE:
        ; $AE92  16-entry logical->physical sector skew table (a 0..15 permutation),
        ; indexed during disk deblock (DISK_RTN_LOOKUP-style *1 byte lookups).
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A      ; $AE92
        DEFB    $04,$0D,$07,$08,$02,$0B,$05,$0E      ; $AE9A
; ----------------------------------------------------------------------
; COL_FLAG -- console-output entry/expand flag (0 or $FF), set by CONOUT_FILTER and
;   tested by SCREEN_EMIT to pick the physical output vector. Immediately followed by
;   COL_PENDING at A3-adjacent cells. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_FLAG:
        DEFB    $00                      ; $AEA2  disk scratch byte
; ----------------------------------------------------------------------
; COL_PENDING -- pending column-skip / fill counter for console output, also reused as a
;   mode byte (set to 2 by TAB_EXPAND_DONE). Decremented as columns are consumed.
;   Accessed as COL_FLAG+1 in CONOUT_FILTER. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_PENDING:
        DEFB    $00                      ; $AEA3  disk scratch byte
; ----------------------------------------------------------------------
; COL_STATE -- sticky control/escape state for tab expansion; armed to $80 on a trigger-
;   char match and cleared by SCREEN_EMIT. Scratch byte, init $00. [RE]
; ----------------------------------------------------------------------
COL_STATE:
        DEFB    $00                      ; $AEA4  disk scratch byte
; ----------------------------------------------------------------------
; SCREEN_CURSOR_PTR -- 2-byte pointer cell used by the screen routines (initialized to
;   point at SCREEN_CHAR / SCREEN_CHAR). Loaded and re-stored by PUT_CHAR_STORE while reading
;   the Apple cursor base ($F028) and column ($F024) to compute the on-screen cell. [RE]
; ----------------------------------------------------------------------
SCREEN_CURSOR_PTR:
        DEFW    SCREEN_CHAR              ; $AEA5  pointer cell (init -> SCREEN_CHAR)
; ----------------------------------------------------------------------
; SCREEN_CHAR -- saved on-screen character byte (the cell SCREEN_CURSOR_PTR points at by
;   default); written back to the screen with format bits applied. Scratch byte, init $00.
;   [RE]
; ----------------------------------------------------------------------
SCREEN_CHAR:
        DEFB    $00                      ; $AEA7  disk scratch byte
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
        LD SP,$0100                      ; $AEA8  31 00 01
; ----------------------------------------------------------------------
; DISK_SELDSK_SAVE -- (boot install template 'LD A,$C9'); +1 byte reused as SELDSK scratch.
;   At cold boot this is the install engine's 'LD A,$C9' template. After boot SELDSK
;   stores the previously-selected drive (page-zero $0004) into DISK_SELDSK_SAVE+1,
;   then the disk number into DISK_SEKDSK (the next cell). [RE]
; ----------------------------------------------------------------------
DISK_SELDSK_SAVE:
        LD A,$C9                         ; $AEAB  3E C9
; ----------------------------------------------------------------------
; DISK_SEKDSK -- CP/M-requested disk number (DRI deblock 'sekdsk'); +1/+2 = hstdsk/hstact.
;   Boot tenant: install template 'LD (nn),A' (operand runtime-patched). Operational
;   tenant: SELDSK stores the selected disk number here; DISK_SEKDSK+1 = host disk
;   (hstdsk [RE]); DISK_SEKDSK+2 = host-buffer-active flag (hstact), cleared by WBOOT/
;   HOME and the deblock, set when a host sector is staged. [RE]
; ----------------------------------------------------------------------
DISK_SEKDSK:
        LD (BIOS_VECTOR),A                    ; $AEAD  32 00 AA
; ----------------------------------------------------------------------
; DISK_HSTWRT -- host-buffer-dirty flag (DRI deblock 'hstwrt' [RE]); +1 = readop [RE].
;   Boot tenant: install template 'LD A,$95' (the default IOBYTE immediate). Operational
;   tenant: a deblock flag the WRITE path sets and the host-flush test reads;
;   DISK_HSTWRT+1 is the read/seek scratch the READ/WRITE deblock loads. [RE]
; ----------------------------------------------------------------------
DISK_HSTWRT:
        LD A,$95                         ; $AEB0  3E 95
; ----------------------------------------------------------------------
; DISK_WRTYPE -- deblock write type (DRI 'wrtype' [RE]); +1 = rsflag, +2 = unacnt.
;   Boot tenant: install template 'LD ($0003),A' (stores the default IOBYTE). Operational
;   tenant: DISK_WRTYPE+1 = read-sector-needed flag (rsflag); DISK_WRTYPE+2 = unallocated
;   record count (unacnt), seeded to 8 on a directory-extending write and decremented
;   by the WRITE deblock loop. [RE]
; ----------------------------------------------------------------------
DISK_WRTYPE:
        LD ($0003),A                     ; $AEB2  32 03 00
; ----------------------------------------------------------------------
; DISK_UNADSK -- unallocated-run disk (DRI 'unadsk' [RE]); +1/+2 = unatrk/unasec.
;   Boot tenant: install template 'LD HL,(nn)'. Operational tenant: the unallocated
;   write run's position. DISK_UNADSK+1 (unatrk) and +2 (unasec) are seeded from the
;   CP/M-requested track/sector (BOOT/BOOT+1) and advanced as the run is written. [RE]
; ----------------------------------------------------------------------
DISK_UNADSK:
        LD HL,($F3DE)                    ; $AEB5  2A DE F3
; ----------------------------------------------------------------------
; DISK_DMAADR -- current DMA buffer address (DRI deblock 'dmaadr').
;   Boot tenant: install template 'LD (nn),HL' (patches a console/IO operand at boot).
;   Operational tenant: SETDMA stores BC here; the deblock record copy uses it as the
;   CP/M 128-byte record source/destination.
; ----------------------------------------------------------------------
DISK_DMAADR:
        LD (SUB_AB3B_1+1),HL             ; $AEB8  22 3F AB
        XOR A                            ; $AEBB  AF
        LD ($0004),A                     ; $AEBC  32 04 00
        LD A,($F3BB)                     ; $AEBF  3A BB F3
        CP $05                           ; $AEC2  FE 05
        JR NC,CONFIG_PROBE_16                ; $AEC4  30 1F
        SUB $03                          ; $AEC6  D6 03
        JR C,CONFIG_PROBE_16                 ; $AEC8  38 1B
        JR NZ,CONFIG_PROBE_15                ; $AECA  20 06
        LD HL,$1FB0                      ; $AECC  21 B0 1F
        LD (KBD_STATUS_40COL+2),HL             ; $AECF  22 0E AB
CONFIG_PROBE_15:
        PUSH AF                          ; $AED2  F5
        CALL DISK_RTN_LOOKUP                    ; $AED3  CD 59 AF
        POP AF                           ; $AED6  F1
        LD (PUT_CHAR_VECTOR+1),HL             ; $AED7  22 42 AC
        CALL DISK_RTN_LOOKUP_B                    ; $AEDA  CD 54 AF
        LD (L_AB2D),HL                   ; $AEDD  22 2D AB
        LD A,$03                         ; $AEE0  3E 03
        LD (CCP_MODE_FLAG+1),A              ; $AEE2  32 FD AA
CONFIG_PROBE_16:
        LD A,($F3B9)                     ; $AEE5  3A B9 F3
        SUB $03                          ; $AEE8  D6 03
        JR C,CONFIG_PROBE_17                 ; $AEEA  38 08
        CALL DISK_RTN_LOOKUP                    ; $AEEC  CD 59 AF
        LD (L_AD2F),HL                   ; $AEEF  22 2F AD
        LD E,$80                         ; $AEF2  1E 80
CONFIG_PROBE_17:
        LD A,($F3BA)                     ; $AEF4  3A BA F3
        SUB $03                          ; $AEF7  D6 03
        JR C,CONFIG_PROBE_18                 ; $AEF9  38 14
        PUSH AF                          ; $AEFB  F5
        CALL DISK_RTN_LOOKUP                    ; $AEFC  CD 59 AF
        LD (L_AD43),HL                   ; $AEFF  22 43 AD
        POP AF                           ; $AF02  F1
        CP $02                           ; $AF03  FE 02
        JR NC,CONFIG_PROBE_18                ; $AF05  30 08
        CALL DISK_RTN_LOOKUP_B                    ; $AF07  CD 54 AF
        LD (L_AD49),HL                   ; $AF0A  22 49 AD
        JR CONFIG_PROBE_19                   ; $AF0D  18 0B
CONFIG_PROBE_18:
        LD HL,$1A3E                      ; $AF0F  21 3E 1A
        LD (L_AD48),HL                   ; $AF12  22 48 AD
        LD A,$C9                         ; $AF15  3E C9
        LD (L_AD4A),A                    ; $AF17  32 4A AD
CONFIG_PROBE_19:
        LD A,($F381)                     ; $AF1A  3A 81 F3
        OR A                             ; $AF1D  B7
        JR NZ,CONFIG_PROBE_20                ; $AF1E  20 0B
        LD HL,IO_VECTOR_DEFAULTS                     ; $AF20  21 AE AF
        LD DE,$F380                      ; $AF23  11 80 F3
        LD BC,$0016                      ; $AF26  01 16 00
        LDIR                             ; $AF29  ED B0
CONFIG_PROBE_20:
        CALL PROBE_DEVICES                    ; $AF2B  CD A2 AA
        LD A,($F398)                     ; $AF2E  3A 98 F3
        CALL SIGNON_EMIT                    ; $AF31  CD 64 AF
        LD A,($F39B)                     ; $AF34  3A 9B F3
        CALL SIGNON_EMIT                    ; $AF37  CD 64 AF
        LD HL,SIGNON_BANNER                     ; $AF3A  21 73 AF
CONFIG_PROBE_21:
        LD A,(HL)                        ; $AF3D  7E
        OR A                             ; $AF3E  B7
        JP Z,PAGEZERO_REBUILD                  ; $AF3F  CA DB AA
        PUSH HL                          ; $AF42  E5
        CALL CONOUT_DISPATCH                    ; $AF43  CD 42 AB
        POP HL                           ; $AF46  E1
        INC HL                           ; $AF47  23
        JR CONFIG_PROBE_21                   ; $AF48  18 F3
; ----------------------------------------------------------------------
; DISK_RTN_PTRS -- DEFW table of disk read/write handler addresses (primary group),
;   indexed by DISK_RTN_LOOKUP. Continues as DISK_RTN_PTRS_B (+6). DATA.
;   Each entry should relocate from a literal address to the named target:
;     [0] $ACDF -> DISK_RD_HANDLER_A  (CALL SLOT_IO_ADDR sector-bit read handler in the
;         CTRL_HANDLER_OFFSET_TBL data/code region)
;     [1] $AD04 -> PLOT_CHAR_AT_COL        (named handler just below)
;     [2] $AD31 -> DISK_WR_HANDLER_B (handler tail in the $AD22 data/code region)
;   and DISK_RTN_PTRS_B holds:
;     [0] $AD12 -> DISK_RD_HANDLER_B (RRA bit-test read handler at the $AD12 block)
;     [1] $AD1C -> DISK_WR_HANDLER_A (CALL SET_SCREEN_BASE write handler in the $AD22 block)
;   See flags: these targets currently sit inside DEFB blocks (CTRL_HANDLER_OFFSET_TBL / $AD12 /
;   $AD22)
;   that are really handler CODE, so the relocations need those blocks named first.
; ----------------------------------------------------------------------
DISK_RTN_PTRS:
        ; $AF4A  table of BIOS handler addresses (DEFW); DISK_RTN_LOOKUP indexes from here,
        ; DISK_RTN_LOOKUP_B indexes from DISK_RTN_PTRS_B (+6). Addresses relocated in the
        ; semantic pass once the targets are named.
        DEFW    $ACDF                    ; $AF4A  [0]
        DEFW    $AD04                    ; $AF4C  [1]
        DEFW    $AD31                    ; $AF4E  [2]
DISK_RTN_PTRS_B:
        DEFW    $AD12                    ; $AF50  DISK_RTN_LOOKUP_B base
        DEFW    $AD1C                    ; $AF52
; ----------------------------------------------------------------------
; DISK_RTN_LOOKUP_B -- fetch a disk-handler address from DISK_RTN_PTRS_B[A].
;   In:  A = entry index (0-based). Out: HL = handler address. Clobbers: A,HL.
;   Algorithm: point HL at DISK_RTN_PTRS_B then fall into the shared index loader
;   (HL += A*2; HL = word at that slot). Used by CONFIG_PROBE to install the per-config
;   read/write handler addresses. [RE]
; ----------------------------------------------------------------------
DISK_RTN_LOOKUP_B:
        ; select the secondary handler-pointer table
        LD HL,DISK_RTN_PTRS_B              ; $AF54  21 50 AF
        JR DISK_RTN_LOOKUP_IDX                    ; $AF57  18 03
; ----------------------------------------------------------------------
; DISK_RTN_LOOKUP -- fetch a disk-handler address from DISK_RTN_PTRS[A].
;   In:  A = entry index (0-based). Out: HL = handler address. Clobbers: A,HL.
;   Algorithm: HL = base; HL += A*2 (ADD A,A; ADD A,L; LD L,A); HL = the 16-bit word
;   at that slot (low then high). Shared tail of DISK_RTN_LOOKUP_B. [RE]
; ----------------------------------------------------------------------
DISK_RTN_LOOKUP:
        ; select the primary handler-pointer table
        LD HL,DISK_RTN_PTRS                ; $AF59  21 4A AF
DISK_RTN_LOOKUP_IDX:
        ; index*2 for 16-bit (word) table entries
        ADD A,A                          ; $AF5C  87
        ADD A,L                          ; $AF5D  85
        LD L,A                           ; $AF5E  6F
        ; load handler address low byte
        LD A,(HL)                        ; $AF5F  7E
        INC L                            ; $AF60  2C
        ; load handler address high byte -> HL = handler entry
        LD H,(HL)                        ; $AF61  66
        LD L,A                           ; $AF62  6F
        RET                              ; $AF63  C9
; ----------------------------------------------------------------------
; SIGNON_EMIT -- emit one sign-on byte, optionally preceded by a fixed prefix char.
;   In:  A = byte/flag. Out: none (prints via CONOUT_DISPATCH=CONOUT-class writer).
;   Algorithm: if A is positive (bit7 clear) just print it; if negative, first print
;   the prefix char from the config block (Apple $0397) then print A. Called twice from
;   the boot path to emit two config-derived sign-on chars before the banner. [RE]
; ----------------------------------------------------------------------
SIGNON_EMIT:
        OR A                             ; $AF64  B7
        ; bit7 clear -> emit the char directly
        JP P,SIGNON_EMIT_CHAR                  ; $AF65  F2 70 AF
        PUSH AF                          ; $AF68  F5
        ; negative flag: fetch the prefix char from the config block (Apple $0397)
        LD A,($F397)                     ; $AF69  3A 97 F3
        ; emit the prefix char
        CALL CONOUT_DISPATCH                    ; $AF6C  CD 42 AB
        POP AF                           ; $AF6F  F1
SIGNON_EMIT_CHAR:
        ; tail-call to emit the original char
        JP CONOUT_DISPATCH                      ; $AF70  C3 42 AB
; ----------------------------------------------------------------------
; SIGNON_BANNER -- the cold-boot sign-on string, printed char-by-char by the boot path
;   (loop at CONFIG_PROBE_21) until the $00 terminator. Reads:
;   'Apple ][ CP/M' / '44K Ver. 2.20' / '(C) 1980 Microsoft', CR/LF separated. DATA.
; ----------------------------------------------------------------------
SIGNON_BANNER:
        DEFB    "\r\n\r\n\r\n"    ; $AF73
        DEFB    "Apple ][ CP/M"    ; $AF79  string
        DEFB    $0D    ; $AF86  terminator
        DEFB    "\n"    ; $AF87
        DEFB    "44K Ver. 2.20"    ; $AF88  string
        DEFB    $0D    ; $AF95  terminator
        DEFB    "\n"    ; $AF96
        DEFB    "(C) 1980 Microsoft"    ; $AF97  string
        DEFB    $0D    ; $AFA9  terminator
        DEFB    "\n\r\n\0"    ; $AFAA
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
        DEFB    $0C,$AB,$12,$AB,$12,$AB,$3E,$AC,$3E,$AC,$45,$AD,$45,$AD,$3F,$AD ; $AFAE
        DEFB    $3F,$AD,$2B,$AD,$2B,$AD,$42,$AB,$E1,$23,$18,$F3,$DF,$AC,$04,$AD ; $AFBE
        DEFB    $31,$AD,$12,$AD,$1C,$AD,$21,$50,$AF,$18,$03,$21,$4A,$AF,$87,$85 ; $AFCE
        DEFB    $6F,$7E,$2C,$66,$6F,$C9,$B7,$F2,$70,$AF,$F5,$3A,$97,$F3,$CD,$42 ; $AFDE
        DEFB    $AB,$F1                                          ; $AFEE
; ----------------------------------------------------------------------
; READ_SEKSEC -- load the current deblock sector and set flags.
;   In:  none. Out: A = current sector (from BOOT+1=seksec); Z set if sector==0.
;   Clobbers: A. Called by the READ/WRITE deblock path to test/translate the sector.
;   Note BOOT+1 is the post-boot reuse of the BOOT 'LD SP,$0100' operand byte. [RE]
; ----------------------------------------------------------------------
READ_SEKSEC:
        ; read the current deblock sector (BOOT+1 reused as seksec)
        LD A,(BOOT+1)              ; $AFF0  3A A9 AE
        ; set Z/sign flags on the sector value for the caller
        OR A                             ; $AFF3  B7
        RET                              ; $AFF4  C9
        DEFB    "\r\n\r\nApple ]"    ; $AFF5

    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $AA00, $0600
    ENDIF
