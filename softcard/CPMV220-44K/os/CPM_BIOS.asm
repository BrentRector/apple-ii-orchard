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
;   $AC00-$ACFF  Code: console-/list-/punch-/reader-dispatch (IOBYTE demux) and
;                the console-output screen-function processor.
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

; ---- I/O Vector Table (config block) -- [DOC sec 3.2] --------------------
CONST_VEC   EQU $F380        ; Console status vector
CONIN1_VEC  EQU $F382        ; Console input vector #1 (TTY:/CRT:)
CONIN2_VEC  EQU $F384        ; Console input vector #2 (UC1:)
CONOUT1_VEC EQU $F386        ; Console output vector #1
CONOUT2_VEC EQU $F388        ; Console output vector #2
RDR1_VEC    EQU $F38A        ; Reader input vector #1
RDR2_VEC    EQU $F38C        ; Reader input vector #2
PUN1_VEC    EQU $F38E        ; Punch output vector #1
PUN2_VEC    EQU $F390        ; Punch output vector #2
LIST1_VEC   EQU $F392        ; List output vector #1
LIST2_VEC   EQU $F394        ; List output vector #2
; ---- Screen-function header/tables -- [DOC sec 3.3/3.4] ------------------
SXYOFF      EQU $F396        ; Software cursor XY coordinate offset
SFLDIN      EQU $F397        ; Software function lead-in char
HXYOFF      EQU $F3A1        ; Hardware cursor XY coordinate offset
HFLDIN      EQU $F3A2        ; Hardware function lead-in char
; ---- Disk count / card type table -- [DOC sec 3.6/3.7] ------------------
DSKCNT      EQU $F3B8        ; Disk count byte; Card Type Table indexes from here
SLTTYP      EQU $F3B9        ; Card Type Table base (entry for slot S at DSKCNT+S)
; ---- 6502 RPC mechanism -- [DOC sec 4] ----------------------------------
A_ACC       EQU $F045        ; 6502 A-register pass cell ($45)
A_XREG      EQU $F047        ; 6502 X-register pass cell ($47)
A_VEC       EQU $F3D0        ; address of 6502 subroutine to call (low-high)
KEYBD       EQU $E000        ; Apple keyboard (Z-80 view of 6502 $C000)
KEYSTB      EQU $E010        ; keyboard clear-strobe (KEYBD+$10)
; ---- CP/M low memory -----------------------------------------------------
BDOS_ENTRY  EQU $9C06        ; BDOS entry (44K: FBASE $9C00 + 6) -- [DOC sec 2.3]
CCP_ENTRY   EQU $9400        ; CCP entry (44K: CBASE) -- [DOC sec 2.3]

    ORG $AA00

; ============================================================================
; BIOS JUMP TABLE  ($AA00) -- standard CP/M BIOS entry vectors.
; 15 entries (BOOT..WRITE).  Most console/disk targets land in the $E5 trap-fill
; ($AB../$AD..) because those primitives are generated into RAM at boot.
; Only BOOT ($AEA8) and WBOOT ($AACC) are real code on disk.
; ============================================================================
BIOS_BASE:
        JP      COLD_BOOT                ; $AA00  0  BOOT   (cold start)
JMPTAB:
        JP      WBOOT                    ; $AA03  1  WBOOT  (warm start)
        JP      L_AB08                   ; $AA06  2  CONST  (runtime handler)
        JP      L_AB50                   ; $AA09  3  CONIN
        JP      L_AB43                   ; $AA0C  4  CONOUT
        JP      L_AB66                   ; $AA0F  5  LIST
        JP      L_AB75                   ; $AA12  6  PUNCH
        JP      L_AB87                   ; $AA15  7  READER
        JP      L_AD4B                   ; $AA18  8  HOME
        JP      L_AD6D                   ; $AA1B  9  SELDSK
        JP      L_AD56                   ; $AA1E 10  SETTRK
        JP      L_AD89                   ; $AA21 11  SETSEC
        JP      SETDMA                   ; $AA24 12  SETDMA
        JP      L_AD93                   ; $AA27 13  READ
        JP      L_ADA3                   ; $AA2A 14  WRITE

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
DEVTAB_HDR:
        DEFB    $AF,$C9,$00,$60,$69,$C9                          ; $AA2D
        DEFS    8, $00    ; $AA33  fill
DEVTAB:
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
        DEFB    $00,$00,$00,$00,$00,$00,$00,$BA,$AE,$93,$AA,$D6,$AF,$8A,$AF,$20 ; $AA84 record 5
SCRN_PARM:
        DEFB    $00,$03,$07,$00,$7F,$00,$2F,$00,$C0,$00,$0C,$00,$03,$00 ; $AA94

; ============================================================================
; CARD-TYPE (SLOT) SCAN  ($AAA2)  -- [DOC sec 3.6]
; Walk the Card Type Table for slots 7..1 (DSKCNT+S).  When an entry == 3
; (Apple Comms / CCS serial), initialise that slot's serial driver and rewrite
; the table entry to 3 then $15.  When the (post-SUB) value hits the device-4
; case (Videx / high-speed serial / Sup-R-Term), claim the $C800 expansion-ROM
; window via SUB_AB3B.  DE = slot index counter (7 down to 1).
; ============================================================================
CARDTYPE_SCAN:
        LD DE,$0007                      ; $AAA2  scan slots 7..1
SCAN_LOOP:
        LD HL,DSKCNT                     ; $AAA5  HL = Card Type Table base ($F3B8)
        ADD HL,DE                        ; $AAA8  -> entry for slot E
        LD A,(HL)                        ; $AAA9  A = card type for this slot
        SUB $03                          ; $AAAA  ==3 ? (Apple Comms / CCS serial)
        JR NZ,SCAN_NOT3                  ; $AAAC
        CALL L_AD60                      ; $AAAE  (runtime) init serial driver
        LD (HL),$03                      ; $AAB1
        LD (HL),$15                      ; $AAB3
SCAN_NOT3:
        DEC A                            ; $AAB5  was value 4 ? (Videx / hi-speed)
        JR NZ,SCAN_NEXT                  ; $AAB6
        CALL SF_INIT_TAIL+1              ; $AAB8  ($ACEE) screen-fn lead-in init
        LD HL,$C800                      ; $AABB  expansion-ROM window
        CALL SUB_AB3B                    ; $AABE  (runtime) claim $C800 window
SCAN_NEXT:
        DEC E                            ; $AAC1  next slot
        JR NZ,SCAN_LOOP                  ; $AAC2
        RET                              ; $AAC4

; ----------------------------------------------------------------------------
; SLOT_TO_EN ($AAC5) -- form the Z-80 SoftCard / slot I/O address $EN00 in HL
; from a slot number in E (KEYBD/$E000 base OR'd with E in the high byte). [AI]
; ----------------------------------------------------------------------------
SLOT_TO_EN:
        LD HL,KEYBD                      ; $AAC5  $E000 base
        LD A,E                           ; $AAC8
        OR H                             ; $AAC9
        LD H,A                           ; $AACA
        RET                              ; $AACB

; ============================================================================
; WBOOT  ($AACC)  -- warm boot / system (re)initialisation.
; Sets the Z-80 stack, re-claims the $0E00 area, runs the card-type scan,
; clears two BIOS flags, and lays down the page-zero jump vectors:
;   $0000 = JMP WBOOT-table ($AA03),  $0005 = JMP BDOS_ENTRY ($9C06).
; Then resets the default DMA (BC=$0080) and warm-starts the console.
; ============================================================================
WBOOT:
        LD SP,$0080                      ; $AACC  Z-80 stack just below TPA
        LD A,(KEYBD+$51)                 ; $AACF  $E051 (Apple text/lo-res switch)
        LD HL,$0E00                      ; $AAD2
        CALL SUB_AB3B                    ; $AAD5  (runtime) setup
        CALL CARDTYPE_SCAN               ; $AAD8  rescan slot card types
        XOR A                            ; $AADB
        LD (CURMODE),A                   ; $AADC  $AEB4 = 0 (skip-idiom selector)
        LD (FLAG_AEAF),A                 ; $AADF  $AEAF = 0
        LD A,$C3                         ; $AAE2  opcode JP
        LD ($0000),A                     ; $AAE4  $0000 = JP ...
        LD HL,JMPTAB                     ; $AAE7    ... ($AA03) BIOS warm-entry
        LD ($0001),HL                    ; $AAEA
        LD ($0005),A                     ; $AAED  $0005 = JP ...
        LD HL,BDOS_ENTRY                 ; $AAF0    ... BDOS ($9C06)
        LD ($0006),HL                    ; $AAF3
        LD BC,$0080                      ; $AAF6  default DMA = $0080
        CALL SETDMA                      ; $AAF9  ($AD8E) set DMA address
        LD A,$01                         ; $AAFC
        LD ($E5B2),A                     ; $AAFE  init runtime-handler RAM cell
; --- $AB01..$ABFF : $E5 trap-fill (runtime-generated console/disk handlers) ---
        DEFB    $E5,$E5,$E5,$E5,$E5,$E5,$E5                      ; $AB01
L_AB08:
        DEFS    31, $E5    ; $AB08  fill  (CONST handler, generated at boot)
L_AB27:
        DEFB    $E5,$E5                                          ; $AB27
SUB_AB29:
        DEFB    $E5,$E5,$E5,$E5,$E5,$E5                          ; $AB29
L_AB2F:
        DEFS    12, $E5    ; $AB2F  fill
SUB_AB3B:
        DEFS    8, $E5    ; $AB3B  fill
L_AB43:
        DEFS    13, $E5    ; $AB43  fill  (CONOUT handler)
L_AB50:
        DEFS    22, $E5    ; $AB50  fill  (CONIN handler)
L_AB66:
        DEFS    15, $E5    ; $AB66  fill  (LIST handler)
L_AB75:
        DEFS    18, $E5    ; $AB75  fill  (PUNCH handler)
L_AB87:
        DEFS    42, $E5    ; $AB87  fill  (READER handler)
SUB_ABB1:
        DEFB    $E5,$E5                                          ; $ABB1
L_ABB3:
        DEFS    10, $E5    ; $ABB3  fill
L_ABBD:
        DEFS    18, $E5    ; $ABBD  fill
L_ABCF:
        DEFS    14, $E5    ; $ABCF  fill
SUB_ABDD:
        DEFS    35, $E5    ; $ABDD  fill

; ============================================================================
; CONSOLE STATUS / WARM-START TAIL  ($AC00)
; ============================================================================
WBOOT_TAIL:
        SBC A,B                          ; $AC00  98
        LD A,($0004)                     ; $AC01  current disk/user byte
        LD C,A                           ; $AC04
        JP CCP_ENTRY                     ; $AC05  enter the CCP ($9400)

; ---- CONST inner: call the console-status vector --------------------------
CONST_DISP:
        LD HL,(CONST_VEC)                ; $AC08  $F380
        JP (HL)                          ; $AC0B

; ---- Default console status: poll Apple keyboard --------------------------
CONST_KBD:
        LD A,(KEYBD)                     ; $AC0C  read keyboard ($E000)
        RLA                              ; $AC0F  key-ready bit (b7) -> carry
        SBC A,A                          ; $AC10  A = $FF if ready else $00
        RET                              ; $AC11

; ---- Keyboard-redefinition lookup ($F3AB table, max 6 pairs) -- [DOC 3.5] --
KBD_REDEF:
        CALL SUB_AB29                    ; $AC12  (runtime) get raw key in A
        LD HL,$F3AB                      ; $AC15  redefinition table - 1
        LD B,$06                         ; $AC18  up to 6 entries
        LD C,A                           ; $AC1A  C = key to match
KBD_REDEF_LP:
        INC HL                           ; $AC1B
        LD A,(HL)                        ; $AC1C  ASCII to redefine
        INC HL                           ; $AC1D
        OR A                             ; $AC1E
        JP M,L_AB27                      ; $AC1F  high bit set = end of table
        CP C                             ; $AC22
KBD_REDEF_HIT:
        LD A,(HL)                        ; $AC23  matched -> replacement ASCII
        RET Z                            ; $AC24
        DJNZ KBD_REDEF_LP                ; $AC25
        LD A,C                           ; $AC27  no match -> original key
        RET                              ; $AC28

; ---- LIST entry helper: set DE=3 then dispatch ----------------------------
LIST_ENTRY:
        LD DE,$0003                      ; $AC29
LIST_ENTRY_JP:
        JP L_AB2F                        ; $AC2C  (runtime) list handler
                                         ; (LIST_ENTRY_JP+1 = $AC2D is a re-entry
                                         ;  used by the screen-fn emit at $ACD7)

; ---- Wait for serial Tx ready, send bit/char via $E000/$E010 -- [AI] -------
SERIAL_TX:
        LD A,(KEYBD)                     ; $AC2F  $E000 status
        RLA                              ; $AC32
        JR NC,SERIAL_TX                  ; $AC33  spin until ready
        LD (KEYSTB),A                    ; $AC35  $E010 strobe / data
        CCF                              ; $AC38
        RRA                              ; $AC39
        RET                              ; $AC3A

; ---- Store a 6502-call vector (A_VEC) and trigger -- [DOC sec 4.2] ---------
SET_AVEC:
        LD (A_VEC),HL                    ; $AC3B  $F3D0 = 6502 sub address
        LD ($0000),A                     ; $AC3E
        RET                              ; $AC41

; ============================================================================
; LIST OUTPUT DISPATCH  ($AC42/$AC44)  -- IOBYTE demux  [DOC sec 7.6]
; Reads IOBYTE ($0003), masks the LIST field, and jumps through the appropriate
; List Output vector.  $AC44 is the documented entry (from $AE41); $AC42 sets C
; first.
; ============================================================================
LIST_SETC:
        LD C,A                           ; $AC42
LIST_DISP:
        LD A,($0003)                     ; $AC43  IOBYTE
        AND $03                          ; $AC46
        CP $02                           ; $AC48
        JR NZ,SF_PROC2                   ; $AC4A
LIST_VEC1:
        LD HL,(LIST1_VEC)                ; $AC4C  $F392
        JP (HL)                          ; $AC4F

; ============================================================================
; CONSOLE INPUT DISPATCH  ($AC50)  -- IOBYTE CONSOLE field (bits 0-1)
; ============================================================================
CONIN_DISP:
        LD A,($0003)                     ; $AC50  IOBYTE
        AND $03                          ; $AC53
        CP $02                           ; $AC55
        LD HL,(CONIN2_VEC)               ; $AC57  $F384 (UC1:)
        JR Z,CONIN_V2                    ; $AC5A
        JR NC,CONIN_V2B                  ; $AC5C
CONIN_V1:
        LD HL,(CONIN1_VEC)               ; $AC5E  $F382 (TTY:/CRT:)
        JP (HL)                          ; $AC61
CONIN_V2:
        LD HL,(RDR1_VEC)                 ; $AC62  $F38A (BAT: -> reader)
CONIN_V2B:
        JP (HL)                          ; $AC65

; ============================================================================
; READER/LIST high-bits DISPATCH  ($AC66)  -- IOBYTE upper field
; ============================================================================
RDR_DISP:
        LD A,($0003)                     ; $AC66  IOBYTE
        AND $C0                          ; $AC69  LIST field (bits 6-7)
SF_PROC_ENTRY:
        CP $80                           ; $AC6B
        JR C,SF_PROC                     ; $AC6D
        JR Z,LIST_VEC1                   ; $AC6F  ($AC4C)
        LD HL,(LIST2_VEC)                ; $AC71  $F394
        JP (HL)                          ; $AC74

; ============================================================================
; PUNCH OUTPUT DISPATCH  ($AC75)  -- IOBYTE PUNCH field (bits 4-5)
; ============================================================================
PUN_DISP:
        LD A,($0003)                     ; $AC75  IOBYTE
        AND $30                          ; $AC78
        CP $10                           ; $AC7A
        JR C,SF_PROC                     ; $AC7C
        LD HL,(PUN1_VEC)                 ; $AC7E  $F38E
        JR NZ,CONIN_V2B                  ; $AC81
        LD HL,(PUN2_VEC)                 ; $AC83  $F390
        JP (HL)                          ; $AC86

; ============================================================================
; READER-field DISPATCH ($AC87)  -- IOBYTE READER field (bits 2-3) -> vectors
; ============================================================================
RDR2_DISP:
        LD A,($0003)                     ; $AC87  IOBYTE
        AND $0C                          ; $AC8A
        CP $04                           ; $AC8C
        JR C,CONIN_V1                    ; $AC8E  ($AC5E)
        JR Z,CONIN_V2                    ; $AC90
        LD HL,(RDR2_VEC)                 ; $AC92  $F38C
        JP (HL)                          ; $AC95

; ============================================================================
; CONSOLE-OUTPUT SCREEN-FUNCTION PROCESSOR  ($AC96)  -- [DOC sec 3.4]
; Matches the outgoing character against the software screen-function table and
; either emits a hardware sequence or treats it as a normal character.  Uses the
; BIOS state variables at $AEA2 (B-register screen-fn signal) and $AEA4 (pending
; lead-in / multi-byte state).
; ============================================================================
SF_PROC:
        SCF                              ; $AC96
SF_PROC2:
        SBC A,A                          ; $AC97
        LD HL,SF_SIGNAL                  ; $AC98  $AEA2
        LD (HL),A                        ; $AC9B
        RES 7,C                          ; $AC9C
        INC HL                           ; $AC9E  -> $AEA3
        LD A,(HL)                        ; $AC9F
        OR A                             ; $ACA0
        JR Z,SF_NORMAL                   ; $ACA1
        DEC (HL)                         ; $ACA3
        LD A,(SXYOFF)                    ; $ACA4  $F396 cursor XY offset
        LD HL,$AEAB                      ; $ACA7
        JR Z,SF_XY                       ; $ACAA
        OR A                             ; $ACAC
        JP P,L_ABB3                      ; $ACAD  (runtime)
        DEC HL                           ; $ACB0
        AND $7F                          ; $ACB1
        LD E,A                           ; $ACB3
        LD A,C                           ; $ACB4
        SUB E                            ; $ACB5
        LD (HL),A                        ; $ACB6
        RET                              ; $ACB7
SF_XY:
        OR A                             ; $ACB8
        JP M,L_ABBD                      ; $ACB9  (runtime)
        DEC HL                           ; $ACBC
        CALL SUB_ABB1                    ; $ACBD  (runtime)
        LD HL,(CURSOR_XY)                ; $ACC0  $AEAA cursor X/Y word
        LD A,(HXYOFF)                    ; $ACC3  $F3A1 hardware XY offset
        OR A                             ; $ACC6
        JP P,L_ABCF                      ; $ACC7  (runtime)
        AND $7F                          ; $ACCA
        LD E,L                           ; $ACCC  swap X/Y order
        LD L,H                           ; $ACCD
        LD H,E                           ; $ACCE
        LD E,A                           ; $ACCF
        ADD A,H                          ; $ACD0
        LD C,A                           ; $ACD1
        LD A,E                           ; $ACD2
        ADD A,L                          ; $ACD3
        PUSH AF                          ; $ACD4
        LD B,$07                         ; $ACD5
        CALL LIST_ENTRY_JP+1             ; $ACD7  ($AC2D) emit via output vector
        POP AF                           ; $ACDA
        LD B,$0A                         ; $ACDB
        LD C,A                           ; $ACDD
        JR L_AD2D                        ; $ACDE  (runtime) emit
SF_NORMAL:
        LD B,A                           ; $ACE0
        LD HL,SF_STATE                   ; $ACE1  $AEA4
        LD A,(HL)                        ; $ACE4
        LD E,A                           ; $ACE5
        OR A                             ; $ACE6
        JR NZ,SF_TABLE                   ; $ACE7
        LD A,(SFLDIN)                    ; $ACE9  $F397 software lead-in
        OR A                             ; $ACEC
SF_INIT_TAIL:
        JR Z,SF_NOLEAD                   ; $ACED
        CP C                             ; $ACEF
        JR NZ,SF_NOLEAD                  ; $ACF0
        LD (HL),$80                      ; $ACF2
        RET                              ; $ACF4
SF_NOLEAD:
        LD A,$1F                         ; $ACF5
        CP C                             ; $ACF7
        JR C,L_AD2D                      ; $ACF8  printable -> emit
SF_TABLE:
        LD HL,$F3A0                      ; $ACFA  hardware screen-fn table - 1
        LD B,$09                         ; $ACFD  9 functions
        LD A,(HL)                        ; $ACFF
; --- $AD00..$ADFF : $E5 trap-fill (runtime-generated disk/console handlers) ---
        DEFS    45, $E5    ; $AD00  fill
L_AD2D:
        DEFS    30, $E5    ; $AD2D  fill  (character-emit handler)
L_AD4B:
        DEFS    11, $E5    ; $AD4B  fill  (HOME handler)
L_AD56:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD56  (SETTRK)
SUB_AD5B:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD5B
L_AD60:
        DEFS    13, $E5    ; $AD60  fill
L_AD6D:
        DEFS    28, $E5    ; $AD6D  fill  (SELDSK handler)
L_AD89:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD89  (SETSEC)
SETDMA:
        DEFB    $E5,$E5,$E5,$E5,$E5                              ; $AD8E  fill (SETDMA)
L_AD93:
        DEFS    16, $E5    ; $AD93  fill  (READ handler)
L_ADA3:
        DEFS    92, $E5    ; $ADA3  fill  (WRITE handler + more)
L_ADFF:
        DEFB    $E5                                              ; $ADFF

; ============================================================================
; SCREEN-FUNCTION TABLE LOOKUP  ($AE00) -- continuation of the SF processor.
; Searches the 9-entry hardware screen-function table for a match; on the
; "Address Cursor" function (#7) sets the multi-byte coordinate state.
; ============================================================================
SF_LOOKUP:
        OR A                             ; $AE00
        JR Z,SF_LK_SKIP                  ; $AE01
        XOR E                            ; $AE03
        CP C                             ; $AE04
        JR Z,SF_LK_HIT                   ; $AE05
SF_LK_SKIP:
        DEC HL                           ; $AE07
        DJNZ L_ADFF                      ; $AE08
        JR SF_LK_DONE                    ; $AE0A
SF_LK_HIT:
        LD DE,$000B                      ; $AE0C  index into table row
        ADD HL,DE                        ; $AE0F
        LD A,(HL)                        ; $AE10
        OR A                             ; $AE11
        LD C,A                           ; $AE12
        JP P,KBD_REDEF_HIT               ; $AE13  ($AC23)
        AND $7F                          ; $AE16
        LD C,A                           ; $AE18
        PUSH BC                          ; $AE19
        LD A,(HFLDIN)                    ; $AE1A  $F3A2 hardware lead-in
        LD B,$07                         ; $AE1D
        CALL SUB_ABDD                    ; $AE1F  (runtime) emit lead-in
        POP BC                           ; $AE22
        LD A,B                           ; $AE23
        CP $07                           ; $AE24
        JR NZ,SF_LK_DONE                 ; $AE26
        LD A,$02                         ; $AE28  function 7 -> expect 2 coords
        LD (SF_STATE2),A                 ; $AE2A  $AEA3
SF_LK_DONE:
        XOR A                            ; $AE2D
        LD (SF_STATE),A                  ; $AE2E  $AEA4 = 0
        LD A,(SF_SIGNAL)                 ; $AE31  $AEA2
        OR A                             ; $AE34
        LD HL,(CONOUT2_VEC)              ; $AE35  $F388
        JR Z,SF_EMIT                     ; $AE38
        LD HL,(CONOUT1_VEC)              ; $AE3A  $F386
SF_EMIT:
        JP (HL)                          ; $AE3D  emit char via console-out vector

; ---- LIST-field re-entry: DE=3 then list dispatch ($AC44) ------------------
LIST_REENTRY:
        LD DE,$0003                      ; $AE3E
        JP LIST_DISP+1                   ; $AE41  ($AC44)

; ============================================================================
; CURSOR-ADDRESS / WRAP HANDLER  ($AE44)
; Reads the saved cursor word ($AEA5) and column ($AEA7), computes the screen
; memory cell, wraps the high-video range, and writes the character.  [AI]
; ============================================================================
CURSOR_PUT:
        LD HL,(CUR_PTR)                  ; $AE44  $AEA5 screen cell pointer
        LD A,(CUR_COL)                   ; $AE47  $AEA7
        LD (HL),A                        ; $AE4A
        CALL SF_PROC_ENTRY               ; $AE4B  ($AC6B)
        LD HL,($F028)                    ; $AE4E  screen base
        LD A,($F024)                     ; $AE51  column
        LD E,A                           ; $AE54
        LD D,$F0                         ; $AE55
        ADD HL,DE                        ; $AE57
        LD (CUR_PTR),HL                  ; $AE58  $AEA5
        LD A,(HL)                        ; $AE5B
        LD (CUR_COL),A                   ; $AE5C  $AEA7
        CP $E0                           ; $AE5F
        JR C,CUR_NOFLIP                  ; $AE61
        XOR $20                          ; $AE63  fold high-video
CUR_NOFLIP:
        AND $3F                          ; $AE65
        OR $40                           ; $AE67  set normal-video bits
        LD (HL),A                        ; $AE69
        RET                              ; $AE6A

; ============================================================================
; SCREEN-FUNCTION EMIT / CR HANDLER  ($AE6B)
; B != 0 -> dispatch a screen function via the $ACD4 selector table.
; B == 0 -> ordinary char: handle CR ($0D) by zeroing the column ($F024),
;           else OR $80 (set high bit) and pass to the 6502 character poke.
; ============================================================================
SF_DISPATCH:
        LD A,B                           ; $AE6B
        OR A                             ; $AE6C
        JR Z,CHAR_OUT                    ; $AE6D
        LD HL,SUB_AB3B                   ; $AE6F  (runtime) return address
        PUSH HL                          ; $AE72
        LD HL,$ACD4                      ; $AE73  selector base
        ADD A,L                          ; $AE76
        LD L,A                           ; $AE77
        LD L,(HL)                        ; $AE78
        JP (HL)                          ; $AE79
CHAR_OUT:
        LD A,C                           ; $AE7A
        CP $0D                           ; $AE7B  carriage return ?
        JR NZ,CHAR_OUT_HI                ; $AE7D
        XOR A                            ; $AE7F
        LD ($F024),A                     ; $AE80  column = 0
        RET                              ; $AE83
CHAR_OUT_HI:
        OR $80                           ; $AE84  set high bit (Apple text)
        CP $E0                           ; $AE86
        JR C,CHAR_POKE                   ; $AE88
        LD HL,$F3DD                      ; $AE8A  config flag
        XOR (HL)                         ; $AE8D
CHAR_POKE:
        LD (A_ACC),A                     ; $AE8E  $F045 = char for 6502
        LD HL,$FDF0                      ; $AE91  Apple Monitor COUT1
        JR $AF0F                         ; $AE94  -> 6502 RPC trampoline (off-image)

; ---- Set "force redraw" flag and return ($AE96) ---------------------------
FORCE_FLAG:
        LD A,$FF                         ; $AE96
        LD BC,$3F3E                      ; $AE98  (skip idiom: swallows $3E $3F)
        LD ($F032),A                     ; $AE9B
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
COLD_BOOT:
        INC H                            ; $AEA8
        RET P                            ; $AEA9
CURSOR_XY:                               ; $AEAA  cursor X/Y word (overlaps code)
        LD (A_ACC),A                     ; $AEAA  $F045
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
PTRSEL_42:
        LD L,$42                         ; $AEB1  -> $FC42
CURMODE_INSTR:
        LD BC,$9C2E                      ; $AEB3  CURMODE = $AEB4 (entry: LD L,$9C -> $FC9C)
        LD BC,$1A2E                      ; $AEB6  (entry $AEB7: LD L,$1A -> $FC1A)
PTRSEL_58:
        LD BC,$582E                      ; $AEB9  (entry $AEBA: LD L,$58 -> $FC58)
        LD H,$FC                         ; $AEBC
        RET                              ; $AEBE

; ============================================================================
; CURSOR CLAMP  ($AEBF)  -- clamp cursor X/Y to the 40x24 Apple screen.
; If X (L) >= 40 ($28) set X=0; if Y (H) >= 24 ($18) set Y=0; store to $F024.
; ============================================================================
CURSOR_CLAMP:
        LD HL,(CURSOR_XY)                ; $AEBF  $AEAA
        LD A,L                           ; $AEC2  X
        CP $28                           ; $AEC3  >= 40 ?
        JR C,CLAMP_Y                     ; $AEC5
        LD L,$00                         ; $AEC7
CLAMP_Y:
        LD A,H                           ; $AEC9  Y
        CP $18                           ; $AECA  >= 24 ?
        JR C,CLAMP_STORE                 ; $AECC
        LD H,$00                         ; $AECE
CLAMP_STORE:
        LD ($F024),HL                    ; $AED0
        JR CURSOR_XY                     ; $AED3  ($AEAA)

; ---- 10-byte data table (screen-function / translate constants) -- [?] ------
SF_XLAT:
        DEFB    $BA,$B1,$B4,$96,$99,$A4,$9E,$B7,$A0,$BF          ; $AED5

; ============================================================================
; WAIT-AND-POKE HELPER  ($AEDF)
; CALL the (runtime) routine at $AD60, then spin until status bit 1 is set,
; advance L, and store C.  [AI]
; ============================================================================
WAIT_POKE:
        CALL L_AD60                      ; $AEDF
WAIT_POKE_LP:
        LD A,(HL)                        ; $AEE2
        AND $02                          ; $AEE3
        JR Z,WAIT_POKE_LP                ; $AEE5
        INC L                            ; $AEE7
        LD (HL),C                        ; $AEE8
        RET                              ; $AEE9

; ============================================================================
; 6502 SUBROUTINE-CALL SETUP  ($AEEA)  -- [DOC sec 4]
; Loads the 6502 A ($F045) and X ($F047) pass cells, runs the (runtime) call
; helper, reads an input column ($EFFF / 6502 $C7FF view), and converts.
; The final $32 opcode (LD (nn),A) continues in the next BIOS chunk.
; ============================================================================
RPC_SETUP:
        LD A,C                           ; $AEEA
        LD (A_ACC),A                     ; $AEEB  $F045 = 6502 A
        CALL SUB_AD5B                    ; $AEEE  (runtime) 6502 call
        LD ($F6F8),A                     ; $AEF1
        LD (A_XREG),A                    ; $AEF4  $F047 = 6502 X
        LD A,($EFFF)                     ; $AEF7
        CALL SLOT_TO_EN                  ; $AEFA  ($AAC5)
        SUB $20                          ; $AEFD
        DEFB    $32                                              ; $AEFF  LD (nn),A -> continues past $AF00

CURMODE      EQU $AEB4        ; mode selector byte (operand of LD BC at $AEB3)
FLAG_AEAF    EQU $AEAF        ; BIOS flag byte cleared by WBOOT

    SAVEBIN "softcard/CPMV220-44K/os/CPM_BIOS.bin", $AA00, $0500
