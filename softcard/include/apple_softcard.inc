; apple_softcard.inc -- canonical names for the EXTERNAL Apple / Microsoft SoftCard
; addresses that Z-80 CP/M code references.  Defined ONCE here and INCLUDEd by every
; SoftCard source file, so these names are never re-derived per file.  EQUs are
; zero-width, so including this is byte-identical.
;
; Two authoritative sources (cite the matching tag at the use site too):
;   [DOC S&HD <page>] = Microsoft "Apple CP/M Software and Hardware Details" manual
;                       (softcard/reference/softcard-cpm-archive/manuals/transcribed/
;                        software-and-hardware-details.md)
;   [apple2.json]     = shared/symbols/apple2.json (Apple II monitor ROM / soft-switch /
;                       zero-page canonical names)
;
; SoftCard Z-80 <-> Apple 6502 address mapping used below:
;   Z-80 $E000-$EFFF  ==  Apple $C000-$CFFF   (the Apple I/O page -- soft switches)
;   Z-80 $F000-$F1FF  ==  Apple $0000-$01FF   (6502 zero page + stack)
;   Z-80 $F200-$F3FF  ==  Apple $0200-$03FF   (the I/O Configuration Block)
; Apple ROM entry points are 6502-native addresses ($Fxxx): Z-80 code passes them as
; the TARGET VALUE of a SoftCard RPC call (stored at A_VEC, then a write to Z_CPU runs
; the 6502), so they are used as constants, not as Z-80 memory addresses.

; (CP/M base-page vectors -- WBOOT $0000, BDOS $0005, IOBYTE $0003, etc. -- are NOT
; defined here: they are not SoftCard-specific and each OS module defines them as its
; own labels/equates.  This include is strictly the Apple/SoftCard hardware externals.)

; ---- SoftCard I/O Configuration Block (Z-80 $F200-$F3FF = Apple $0200-$03FF) -----
; [DOC S&HD 2-3, 2-16..2-27].  The I/O Vector Table: primitive char-I/O vectors that
; normally point into the BIOS but can be repatched (CONFIGIO) [DOC S&HD 2-18..2-19].
CONST_VEC   EQU $F380      ; Console status vector  -> A=$FF if char ready
CONIN1_VEC  EQU $F382      ; Console input vector #1 (TTY:/CRT:)
CONIN2_VEC  EQU $F384      ; Console input vector #2 (UC1:)
CONOUT1_VEC EQU $F386      ; Console output vector #1
CONOUT2_VEC EQU $F388      ; Console output vector #2
RDR1_VEC    EQU $F38A      ; Reader input vector #1 (PTR:)
RDR2_VEC    EQU $F38C      ; Reader input vector #2
PUN1_VEC    EQU $F38E      ; Punch output vector #1
PUN2_VEC    EQU $F390      ; Punch output vector #2
LIST1_VEC   EQU $F392      ; List output vector #1 (LPT:)
LIST2_VEC   EQU $F394      ; List output vector #2
; Screen Function Tables (software/hardware): the cursor-XY coordinate offset and the
; function lead-in char used to translate screen-control sequences [DOC S&HD 2-13..2-14].
SXYOFF      EQU $F396      ; Software cursor-XY coordinate offset (hi bit = X/Y order)
SFLDIN      EQU $F397      ; Software function lead-in char (0 = none)
HXYOFF      EQU $F3A1      ; Hardware cursor-XY coordinate offset
HFLDIN      EQU $F3A2      ; Hardware function lead-in char
; Card Type Table: one byte per slot, value 0..5 (2=DiskII, 3=serial, 4=80-col/Videx,
; 5=parallel) [DOC S&HD 2-26..2-27].  The slot-S entry is at DSKCNT + S.
DSKCNT      EQU $F3B8      ; Disk Count Byte; Card Type Table indexes from here [DOC S&HD 2-27]
SLTTYP      EQU $F3B9      ; Card Type Table, slot 1 entry (slot S at DSKCNT+S)
SLTTYP3     EQU $F3BB      ; slot 3 (console) card type -- 3/4 => external 80-col terminal

; ---- SoftCard 6502 RPC interface [DOC S&HD 2-24..2-25] ---------------------------
; Set A_VEC = 6502 subroutine address, optionally pass args via the register cells,
; then WRITE Z_CPU to run the 6502; the 6502 RTS resumes Z-80 execution.  The manual
; calls these A$VEC / Z$CPU (sjasmplus forbids '$' in identifiers, so A_VEC / Z_CPU).
A_VEC       EQU $F3D0      ; address of 6502 subroutine to call (low,high) [DOC S&HD 2-25]
Z_CPU       EQU $F3DE      ; SoftCard trigger: a WRITE here runs the 6502 [DOC S&HD 2-24]
; 6502 register pass cells = the Apple monitor save block at Apple $0045-$0049
; [apple2.json]; the RPC passes/returns the 6502 A,X,Y,P,SP through them [DOC S&HD 2-24].
; Named for the cell ($46=XREG, $47=YREG, the monitor SAVE order).  NOTE: the S&HD
; table mislabels $46/$47 as Y/X; GBASIC's HLINE call (Y=column via $F047) confirms the
; cell at $47 carries 6502 Y, so the monitor-cell naming used here is the correct one.
RPC_ACC     EQU $F045      ; 6502 A register (Apple $45 ACC)
RPC_XREG    EQU $F046      ; 6502 X register (Apple $46 XREG)
RPC_YREG    EQU $F047      ; 6502 Y register (Apple $47 YREG)
RPC_STATUS  EQU $F048      ; 6502 P/status (Apple $48 STATUS)
RPC_SP      EQU $F049      ; 6502 stack pointer on return (Apple $49 SPNT)
RPC_ENTER_Z80 EQU $F3C0    ; 6502->Z-80 mode-switch routine; 6502 RESET/NMI/BRK vectors [DOC S&HD 2-25]

; ---- Apple soft switches (Z-80 $E0xx = Apple $C0xx) [apple2.json] ----------------
KEYBD       EQU $E000      ; Apple $C000 -- keyboard data (bit 7 = strobe) [DOC S&HD 2-23]
KEYSTB      EQU $E010      ; Apple $C010 -- keyboard clear-strobe [DOC S&HD 2-23]
TXTCLR      EQU $E050      ; Apple $C050 -- graphics on (clear text)
TXTSET      EQU $E051      ; Apple $C051 -- text on
MIXCLR      EQU $E052      ; Apple $C052 -- full-screen graphics
MIXSET      EQU $E053      ; Apple $C053 -- split graphics + 4 text lines
TXTPAGE1    EQU $E054      ; Apple $C054 -- display page 1
TXTPAGE2    EQU $E055      ; Apple $C055 -- display page 2
LORES       EQU $E056      ; Apple $C056 -- lo-res graphics (clear hi-res)
HIRES       EQU $E057      ; Apple $C057 -- hi-res graphics
BUTN0       EQU $E061      ; Apple $C061 -- pushbutton 0 / open-apple (bit 7)

; ---- Apple zero page used by the graphics RPC (Z-80 $F0xx = Apple $00xx) [apple2.json]
WNDTOP      EQU $F022      ; Apple $22 -- text window top row
GBASL       EQU $F026      ; Apple $26 -- graphics base addr low
GBASH       EQU $F027      ; Apple $27 -- graphics base addr high
H2          EQU $F02C      ; Apple $2C -- HLINE right-edge column
V2          EQU $F02D      ; Apple $2D -- VLINE bottom row
COLOR       EQU $F030      ; Apple $30 -- lo-res colour byte (colour in both nibbles)
INVFLG      EQU $F032      ; Apple $32 -- inverse/flash mask for COUT

; ---- Apple monitor ROM entry points (RPC target values) [apple2.json / DOC S&HD] -
HLINE       EQU $F819      ; lo-res horizontal line (Y=left col, H2=right, A=row) [apple2.json]
VLINE       EQU $F828      ; lo-res vertical line (A=top row, V2=bottom, Y=col)   [apple2.json]
SCRN_ROM    EQU $F871      ; read lo-res pixel (Y,A) -> A colour 0..15            [apple2.json]
PREAD       EQU $FB1E      ; read game-paddle/timer -> Y [DOC S&HD 2-25] [apple2.json]
TEXT_ROM    EQU $FB2F      ; set text mode + full-screen window                  [apple2.json]
HOME        EQU $FC58      ; clear text window, home cursor                      [apple2.json]
