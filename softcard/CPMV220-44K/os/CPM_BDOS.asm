; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- BDOS (Basic Disk Operating System)
; ----------------------------------------------------------------------------
; Runtime-addressed (de-skewed): ORG $9C00 (FBASE), runs $9C00-$A9FF. An independent
; compilation: $9C00 image header (serial + JP $9C06 entry), the 41-entry function
; dispatch table ($9C47), console/line-edit, FCB/directory/allocation, disk record
; deblock + RWTS, the variable page ($A9xx). References the CCP base once (CCP_ENTRY,
; warm boot). The 44K system tracks store this sector-interleaved; the disk producer
; re-applies the skew (cpm_pipeline/deskew.py). See ../../docs/CPM_Skew_Findings.md.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    INCLUDE "cpm22.inc"
    INCLUDE "cpm_system_220.inc"
    ORG $9C00
    ENDIF
; (BDOS_IMAGE_HEADER == module base; defined in cpm_system_220.inc)
        DEFB    $BD,$16,$00,$00,$16,$DF                          ; $9C00
; ----------------------------------------------------------------------
; BDOS_ENTRY -- the BDOS=$0005-vector landing point (FBASE+6); jumps to the function dispatcher.
;   In: C = BDOS function number, DE = info address (or single-byte arg in E) -- the standard $0005
;       call ABI.
;   Out: jumps to BDOS_DISPATCH; never returns here (the handler RETs through the common BDOS exit).
;   Clobbers: none of its own (single JP).
;   Algorithm: OBSERVED -- one JP BDOS_DISPATCH. The page-zero $0005 jump-vector targets this
;              address ($9C06), so every BDOS call enters here. [RE]
; ----------------------------------------------------------------------
BDOS_ENTRY:
        ; enter the function dispatcher; reached from the page-zero BDOS=$0005 jump vector
        JP BDOS_DISPATCH                   ; $9C06  C3 11 9C
; ----------------------------------------------------------------------
; BDOS_ERR_VECTORS -- DATA: first entry of a 4-word table of BDOS disk-error reporter addresses.
;   In: a caller does LD HL,<one of these 4 word slots> then falls into the reporter helper at
;       $9F4A, which does LD E,(HL)/INC HL/LD D,(HL)/EX DE,HL/JP (HL) to enter the selected
;       reporter.
;   Out: this slot's word is the run address of the Bad-Sector (permanent disk) error reporter.
;   Clobbers: n/a (data).
;   Algorithm: OBSERVED -- two DATA bytes ($99 $9C) forming the address of the Bad-Sector reporter;
;              mis-decoded as SBC A,C / SBC A,H. This slot is loaded by the random-record path (the
;              caller at $9FBD: LD HL,BDOS_ERR_VECTORS). The four reporters print 'Bdos Err On d:'
;              then a '$'-terminated cause string ('Bad Sector' / 'Select' / 'R/O' / 'File R/O').
;              [RE]
; ----------------------------------------------------------------------
BDOS_ERR_VECTORS:
        ; DATA: low byte of the Bad-Sector (permanent disk-error) reporter address -- mis-decoded as
        ;       SBC A,C
        SBC A,C                          ; $9C09  99
        ; DATA: high byte ($9C) of the Bad-Sector reporter address
        SBC A,H                          ; $9C0A  9C
; ----------------------------------------------------------------------
; BDOS_ERRVEC_SELECT -- DATA: word for the Select-error reporter in the BDOS error-vector table.
;   In: n/a (data; this label's address is loaded into HL by the helper-front-end at $9F47 (LD
;       HL,BDOS_ERRVEC_SELECT) before falling into the $9F4A reporter dispatch).
;   Out: n/a (the word here is the run address of the 'Select' error reporter, which prints the
;        message then warm-boots).
;   Clobbers: n/a (data).
;   Algorithm: OBSERVED -- two DATA bytes ($A5 $9C) forming the Select-error reporter address;
;              mis-decoded as AND L / SBC A,H. [RE]
; ----------------------------------------------------------------------
BDOS_ERRVEC_SELECT:
        ; DATA: low byte of the Select-error reporter address -- mis-decoded as AND L
        AND L                            ; $9C0B  A5
        ; DATA: high byte ($9C) of the Select-error reporter address
        SBC A,H                          ; $9C0C  9C
; ----------------------------------------------------------------------
; BDOS_ERRVEC_RODISK -- DATA: word for the R/O-disk error reporter in the BDOS error-vector table.
;   In: n/a (data; loaded into HL by the caller at $A158 (LD HL,BDOS_ERRVEC_RODISK), reached when a
;       write is attempted to a read-only-flagged drive).
;   Out: n/a (the word here is the run address of the reporter that prints 'R/O').
;   Clobbers: n/a (data).
;   Algorithm: OBSERVED -- two DATA bytes ($AB $9C) forming the R/O-disk reporter address;
;              mis-decoded as XOR E / SBC A,H. The exact CP/M error sub-class ('R/O disk' vs 'disk
;              changed to R/O') is UNKNOWN from these bytes; the reported cause string is 'R/O'.
;              [RE]
; ----------------------------------------------------------------------
BDOS_ERRVEC_RODISK:
        ; DATA: low byte of the R/O-disk reporter address -- mis-decoded as XOR E
        XOR E                            ; $9C0D  AB
        ; DATA: high byte ($9C) of the R/O-disk reporter address
        SBC A,H                          ; $9C0E  9C
; ----------------------------------------------------------------------
; BDOS_ERRVEC_FILERO -- DATA: word for the File-R/O error reporter in the BDOS error-vector table.
;   In: n/a (data; loaded into HL by the caller at $A14E (LD HL,BDOS_ERRVEC_FILERO), reached on a
;       write to a read-only file).
;   Out: n/a (the word here is the run address of the reporter that prints 'File R/O').
;   Clobbers: n/a (data).
;   Algorithm: OBSERVED -- two DATA bytes ($B1 $9C) forming the File-R/O reporter address;
;              mis-decoded as OR C / SBC A,H. This is the last of the 4 error-vector words;
;              BDOS_DISPATCH begins immediately after. [RE]
; ----------------------------------------------------------------------
BDOS_ERRVEC_FILERO:
        ; DATA: low byte of the File-R/O reporter address -- mis-decoded as OR C
        OR C                             ; $9C0F  B1
        ; DATA: high byte ($9C) of the File-R/O reporter address
        SBC A,H                          ; $9C10  9C
; ----------------------------------------------------------------------
; BDOS_DISPATCH -- the CP/M 2.2 FDOS dispatcher: set up the BDOS frame and vector to the function
; handler.
;   In: C = BDOS function number (valid 0..40); DE = info address (single-byte arg also in E);
;       caller's SP live.
;   Out: control transfers (JP (HL)) to the selected handler with HL = the caller's info-address; on
;        out-of-range C (>= 41) it RETs straight to the just-pushed common exit, returning the
;        default 0 result.
;   Clobbers: A, BC, DE, HL, SP (switches to the private BDOS stack).
;   Algorithm: OBSERVED -- save caller DE (the info-address) into BDOS_PARAM_PTR; copy low byte E
;              into the requested-drive/byte-param cell DRV_SELECT_ARG; default the word result
;              (BDOS_RETVAL) to 0; capture caller SP into BDOS_SAVED_SP and switch SP to the private
;              BDOS stack top (BDOS_STACK_TOP); clear two per-call state cells (DRV_SAVED_FCB_BYTE, DRV_RESTORE_FLAG) to
;              0; push the common BDOS exit (FCB_AUTO_DRIVE_RESTORE = $A974) so every handler RETs
;              through it; range-check the function number A (=C) against $29 (41) -- CP $29 / RET
;              NC returns to the exit when A >= 41. Then move byte-arg E into C for the handler, set
;              the index DE = function number (LD E,A / LD D,0), index BDOS_DISPATCH_TBL by 2*A (two
;              ADD HL,DE), fetch the handler word into DE, reload the saved info-address into HL, EX
;              DE,HL, and JP (HL). Dispatch is static-indexed: function N selects table entry N.
;              [RE]
; ----------------------------------------------------------------------
BDOS_DISPATCH:
        EX DE,HL                         ; $9C11  EB
        ; save the caller's DE info-address (reloaded into HL just before JP (HL) to the handler)
        LD (BDOS_PARAM_PTR),HL                   ; $9C12  22 43 9F
        EX DE,HL                         ; $9C15  EB
        LD A,E                           ; $9C16  7B
        ; stash the low arg byte E as the requested drive / byte parameter
        LD (DRV_SELECT_ARG),A                    ; $9C17  32 D6 A9
        ; default the BDOS word result to 0 before dispatch
        LD HL,$0000                      ; $9C1A  21 00 00
        ; clear the BDOS word-result cell (read back by the common exit)
        LD (BDOS_RETVAL),HL                   ; $9C1D  22 45 9F
        ; HL was 0, so HL := caller's SP
        ADD HL,SP                        ; $9C20  39
        ; save the caller's stack pointer for the common exit to restore
        LD (BDOS_SAVED_SP),HL                   ; $9C21  22 0F 9F
        ; switch to the private BDOS internal stack
        LD SP,BDOS_STACK_TOP                     ; $9C24  31 41 9F
        XOR A                            ; $9C27  AF
        ; clear a per-call disk/reselect state cell (A=0 from XOR A)
        LD (DRV_SAVED_FCB_BYTE),A                    ; $9C28  32 E0 A9
        ; clear a second per-call state cell (A=0)
        LD (DRV_RESTORE_FLAG),A                    ; $9C2B  32 DE A9
        ; load the common BDOS exit/return-result address ($A974)
        LD HL,FCB_AUTO_DRIVE_RESTORE                ; $9C2E  21 74 A9
        ; push the common exit so every handler RETs back through it
        PUSH HL                          ; $9C31  E5
        ; A := function number for the range check and the table index
        LD A,C                           ; $9C32  79
        ; range-check: function number 41 ($29) or higher is out of range
        CP $29                           ; $9C33  FE 29
        ; out-of-range -> return to the common exit with the default (0) result
        RET NC                           ; $9C35  D0
        ; move the byte argument (E) into C for the handler (C is now free since A holds the func
        ; number)
        LD C,E                           ; $9C36  4B
        ; base of the 41-entry handler table
        LD HL,BDOS_DISPATCH_TBL                     ; $9C37  21 47 9C
        ; DE := function number (E=A, D=0) as the table index
        LD E,A                           ; $9C3A  5F
        ; high byte of the index = 0
        LD D,$00                         ; $9C3B  16 00
        ; index by 2*A: two ADD HL,DE advance HL by 2*function-number
        ADD HL,DE                        ; $9C3D  19
        ADD HL,DE                        ; $9C3E  19
        ; fetch handler address low byte
        LD E,(HL)                        ; $9C3F  5E
        INC HL                           ; $9C40  23
        ; fetch handler address high byte
        LD D,(HL)                        ; $9C41  56
        ; reload the caller's info-address into HL for the handler
        LD HL,(BDOS_PARAM_PTR)                   ; $9C42  2A 43 9F
        EX DE,HL                         ; $9C45  EB
        ; enter the selected BDOS function handler
        JP (HL)                          ; $9C46  E9
; ----------------------------------------------------------------------
; BDOS_DISPATCH_TBL -- 41-entry BDOS function dispatch table (one handler address per function
; 0..40).
;   In: indexed by 2*A (the function number) in BDOS_DISPATCH.
;   Out: the selected word is fetched and entered via JP (HL).
;   Clobbers: n/a (data).
;   Algorithm: OBSERVED -- a table of 16-bit handler run addresses. In-image handlers ($9Cxx-$A8xx)
;              render as labels; handlers above this staged image render as raw $hex; functions
;              4..11 sit in the DEFB run at $9C4F that the disassembler did not split into DEFW.
;              Functions 0-36 ($00-$24) are the standard CP/M 2.2 set; slots 37-40 ($25-$28) are
;              SoftCard/2.2 extensions (37 = drive-login mask, 38/39 = RET no-op stubs, 40 = Write
;              Random Zero Fill). [RE]
; ----------------------------------------------------------------------
BDOS_DISPATCH_TBL:
        ; fn 0 ($00) System Reset (warm boot)
        DEFW    $AA03                    ; $9C47
        ; fn 1 ($01) Console Input -> A
        DEFW    F_CONIN_H              ; $9C49
        ; fn 2 ($02) Console Output (E=char)
        DEFW    F_CONOUT_H                 ; $9C4B
        ; fn 3 ($03) Reader Input -> A
        DEFW    F_READERIN_H              ; $9C4D
        ; fns 4-11 as little-endian words: 4=$AA12 Punch Out, 5=$AA0F List Out, 6=$9ED4 Direct
        ; Console I/O, 7=$9EED Get IOBYTE, 8=$9EF3 Set IOBYTE, 9=$9EF8 Print String, 10=$9DE1 Read
        ; Console Buffer, 11=$9EFE Get Console Status
        DEFB    $12,$AA,$0F,$AA,$D4,$9E,$ED,$9E,$F3,$9E,$F8,$9E,$E1,$9D,$FE,$9E ; $9C4F
        ; fn 12 ($0C) Return Version Number -> HL
        DEFW    S_BDOSVER_H               ; $9C5F
        ; fn 13 ($0D) Reset Disk System
        DEFW    DRV_ALLRESET_H               ; $9C61
        ; fn 14 ($0E) Select Disk
        DEFW    DRV_SET_H                 ; $9C63
        ; fn 15 ($0F) Open File
        DEFW    F_OPEN_H               ; $9C65
        ; fn 16 ($10) Close File
        DEFW    F_CLOSE_H               ; $9C67
        ; fn 17 ($11) Search for First
        DEFW    F_SFIRST_H               ; $9C69
        ; fn 18 ($12) Search for Next
        DEFW    F_SNEXT_H               ; $9C6B
        ; fn 19 ($13) Delete File
        DEFW    F_DELETE_H               ; $9C6D
        ; fn 20 ($14) Read Sequential
        DEFW    F_READ_H              ; $9C6F
        ; fn 21 ($15) Write Sequential
        DEFW    F_WRITE_H              ; $9C71
        ; fn 22 ($16) Make File
        DEFW    F_MAKE_H              ; $9C73
        ; fn 23 ($17) Rename File
        DEFW    F_RENAME_H              ; $9C75
        ; fn 24 ($18) Return Login Vector -> HL
        DEFW    DRV_LOGINVEC_H              ; $9C77
        ; fn 25 ($19) Return Current Disk -> A
        DEFW    DRV_GET_H              ; $9C79
        ; fn 26 ($1A) Set DMA Address (DE)
        DEFW    F_DMAOFF_H              ; $9C7B
        ; fn 27 ($1B) Get Allocation Vector -> HL
        DEFW    DRV_ALLOCVEC_H              ; $9C7D
        ; fn 28 ($1C) Write Protect Disk
        DEFW    DRV_SETRO_H                 ; $9C7F
        ; fn 29 ($1D) Get R/O Vector -> HL
        DEFW    DRV_ROVEC_H              ; $9C81
        ; fn 30 ($1E) Set File Attributes
        DEFW    F_ATTRIB_H              ; $9C83
        ; fn 31 ($1F) Get Disk Parameter Block addr -> HL
        DEFW    DRV_DPB_H              ; $9C85
        ; fn 32 ($20) Get/Set User Number
        DEFW    F_USERNUM_H              ; $9C87
        ; fn 33 ($21) Read Random
        DEFW    F_READRAND_H              ; $9C89
        ; fn 34 ($22) Write Random
        DEFW    F_WRITERAND_H              ; $9C8B
        ; fn 35 ($23) Compute File Size
        DEFW    F_SIZE_H              ; $9C8D
        ; fn 36 ($24) Set Random Record
        DEFW    F_RANDREC_H               ; $9C8F
        ; fn 37 ($25) SoftCard extension: drive-login-vector mask (handler at $A953)
        DEFW    DRV_RESET_H              ; $9C91
        ; fn 38 ($26) SoftCard extension: RET no-op stub
        DEFW    BDOS_RET_NOP              ; $9C93
        ; fn 39 ($27) SoftCard extension: RET no-op stub (same handler)
        DEFW    BDOS_RET_NOP              ; $9C95
        ; fn 40 ($28) Write Random with Zero Fill
        DEFW    F_WRITEZF_H              ; $9C97
        DEFW    $CA21                    ; $9C99
        DEFW    $CD9C                    ; $9C9B
        DEFW    BDOS_ERR_PRINT                 ; $9C9D
        DEFW    $03FE                    ; $9C9F
        DEFW    $00CA                    ; $9CA1
        DEFW    $C900                    ; $9CA3
        DEFW    $D521                    ; $9CA5
        DEFW    $C39C                    ; $9CA7
        DEFW    BDOS_ERR_TRAP              ; $9CA9
        DEFW    $E121                    ; $9CAB
        DEFW    $C39C                    ; $9CAD
        DEFW    BDOS_ERR_TRAP              ; $9CAF
        DEFW    $DC21                    ; $9CB1
        DEFB    $9C                                              ; $9CB3
; ----------------------------------------------------------------------
; BDOS_ERR_TRAP -- Print a BDOS disk error message and warm-boot.
;   In: HL = pointer to the '$'-terminated reason string (set by the calling error
;       stub, e.g. 'Bad Sector$'/'Select$'/'File R/O$'); BDOS_CUR_DRIVE = current drive index
;       (0=A), used only to form the banner's drive letter.
;   Out: does not return -- transfers to warm boot (JP 0).
;   Clobbers: AF, BC, HL (irrelevant -- system restarts).
;   Algorithm: call BDOS_ERR_PRINT to emit 'Bdos Err On d: <reason>', then JP 0000
;              (CP/M warm-boot vector) to reload the CCP.
;   [RE] Standard CP/M 2.2 BDOS fatal-disk-error trap. Reached via JP from the disk-error
;        stubs just below the dispatch table, each of which loads HL with its reason string.
; ----------------------------------------------------------------------
BDOS_ERR_TRAP:
        ; Emit 'Bdos Err On d: <reason>$' to the console
        CALL BDOS_ERR_PRINT                    ; $9CB4  CD E5 9C
        ; Warm boot (vector at 0000) -- reload CCP, never returns
        JP $0000                         ; $9CB7  C3 00 00
; ----------------------------------------------------------------------
; BDOS_ERR_MSG_HEAD -- '$'-terminated head of the BDOS error banner: 'Bdos Err On '.
;   [RE] Printed by BDOS_ERR_PRINT; the drive letter is patched into the byte that follows.
; ----------------------------------------------------------------------
BDOS_ERR_MSG_HEAD:
        DEFB    "Bdos Err On "    ; $9CBA  string
; ----------------------------------------------------------------------
; BDOS_ERR_MSG_DRIVE -- drive-letter slot plus the four '$'-delimited error reasons.
;   Layout: 1 patched drive-letter byte, then ' : $', 'Bad Sector$', 'Select$', 'File R/O$'.
;   [RE] BDOS_ERR_PRINT overwrites the first byte with 'A'+drive, then prints from here;
;        the selected reason string ('Bad Sector$' at +4, 'Select$' at +15, 'File R/O$'
;        at +22) is pointed to by HL on entry to the trap (moved into BC inside
;        BDOS_ERR_PRINT via PUSH HL / POP BC).
; ----------------------------------------------------------------------
BDOS_ERR_MSG_DRIVE:
        DEFB    " : $Bad Sector$Select$File R/O$"    ; $9CC6  string
; ----------------------------------------------------------------------
; BDOS_ERR_PRINT -- print the 'Bdos Err On d: <reason>' banner to the console.
;   In: HL = pointer to the trailing reason string ('$'-terminated); BDOS_CUR_DRIVE = drive index.
;   Out: banner echoed via the console-output path; the entry HL is consumed (PUSH/POP).
;   Clobbers: AF, BC, HL.
;   Algorithm: save the reason pointer (PUSH HL); print CR/LF (CON_CRLF); form drive
;              letter 'A'+BDOS_CUR_DRIVE and patch it into BDOS_ERR_MSG_DRIVE; print the fixed head
;              'Bdos Err On ' via BC; then POP the saved reason pointer into BC and print it,
;              each through the '$'-terminated string printer (CON_PRINT_STR).
;   [RE] Standard CP/M 2.2 BDOS error reporter.
; ----------------------------------------------------------------------
BDOS_ERR_PRINT:
        PUSH HL                          ; $9CE5  E5
        ; Emit CR/LF before the banner
        CALL CON_CRLF                    ; $9CE6  CD C9 9D
        ; Current drive index (0=A)
        LD A,(BDOS_CUR_DRIVE)                    ; $9CE9  3A 42 9F
        ; Convert to drive letter 'A'+n
        ADD A,$41                        ; $9CEC  C6 41
        ; Patch the drive-letter slot in the message
        LD (BDOS_ERR_MSG_DRIVE),A                    ; $9CEE  32 C6 9C
        ; Point at the fixed head 'Bdos Err On '
        LD BC,BDOS_ERR_MSG_HEAD                     ; $9CF1  01 BA 9C
        ; Print head + ' d: ' up to the '$'
        CALL CON_PRINT_STR                  ; $9CF4  CD D3 9D
        ; Recover the reason-string pointer (PUSHed from HL on entry)
        POP BC                           ; $9CF7  C1
        ; Print the selected reason string
        CALL CON_PRINT_STR                  ; $9CF8  CD D3 9D
; ----------------------------------------------------------------------
; CON_GETC_OR_RAW -- return the 1-char type-ahead if present, else read raw console input.
;   In: CON_PENDING_CHAR = pending look-ahead char (0 if none).
;   Out: A = next console character; CON_PENDING_CHAR cleared if it supplied the byte.
;   Clobbers: AF, HL.
;   Algorithm: if CON_PENDING_CHAR nonzero, consume and return it; otherwise call the BIOS
;              console-input vector (BDOS variable-page entry $AA09) for a fresh key.
;   [RE] Single-byte console un-get buffer used by the line editor and CONIN.
; ----------------------------------------------------------------------
CON_GETC_OR_RAW:
        ; Point at the 1-char type-ahead buffer
        LD HL,CON_PENDING_CHAR                     ; $9CFB  21 0E 9F
        LD A,(HL)                        ; $9CFE  7E
        ; Clear it -- the held char (if any) is consumed
        LD (HL),$00                      ; $9CFF  36 00
        OR A                             ; $9D01  B7
        ; A held char was present: return it
        RET NZ                           ; $9D02  C0
        ; Else fall through to the BIOS CONIN vector
        JP $AA09                         ; $9D03  C3 09 AA
; ----------------------------------------------------------------------
; F_CONIN_RAW -- read one console char, echoing it unless it is a control char.
;   In: none.
;   Out: A = character read (7-bit not masked here).
;   Clobbers: AF, BC, HL.
;   Algorithm: fetch a char (CON_GETC_OR_RAW); if it is a printable/handled control
;              (IS_CTRL_CHAR sets carry for the unechoed set) skip echo; otherwise echo
;              it via F_CONOUT_H, preserving the char across the call.
;   [RE] Backs BDOS function 1 (Console Input with echo).
; ----------------------------------------------------------------------
F_CONIN_RAW:
        ; Get next console char (type-ahead or raw)
        CALL CON_GETC_OR_RAW                    ; $9D06  CD FB 9C
        ; Carry set => do not echo (control char)
        CALL IS_CTRL_CHAR                    ; $9D09  CD 14 9D
        ; Control char: return without echo
        RET C                            ; $9D0C  D8
        PUSH AF                          ; $9D0D  F5
        LD C,A                           ; $9D0E  4F
        ; Echo the character
        CALL F_CONOUT_H                    ; $9D0F  CD 90 9D
        POP AF                           ; $9D12  F1
        RET                              ; $9D13  C9
; ----------------------------------------------------------------------
; IS_CTRL_CHAR -- classify a char as a special/control code for echo suppression.
;   In: A = character.
;   Out: Z set if A is CR/LF/TAB/BS (those return early with Z); CARRY reflects A<' '
;        from the final CP $20 (carry set => below space, i.e. an unhandled control char).
;   Clobbers: AF.
;   Algorithm: compare A against CR(0D), LF(0A), TAB(09), BS(08) returning Z on a hit;
;              else fall through to CP ' ' so carry tells printable-vs-control.
;   [RE] Helper used by the console echo/expansion paths.
; ----------------------------------------------------------------------
IS_CTRL_CHAR:
        ; Carriage return?
        CP $0D                           ; $9D14  FE 0D
        RET Z                            ; $9D16  C8
        ; Line feed?
        CP $0A                           ; $9D17  FE 0A
        RET Z                            ; $9D19  C8
        ; Tab?
        CP $09                           ; $9D1A  FE 09
        RET Z                            ; $9D1C  C8
        ; Backspace?
        CP $08                           ; $9D1D  FE 08
        RET Z                            ; $9D1F  C8
        ; Set carry if below space (control char)
        CP $20                           ; $9D20  FE 20
        RET                              ; $9D22  C9
; ----------------------------------------------------------------------
; CON_POLL_STATUS -- console-status poll that also traps Ctrl-S/Ctrl-C while idle.
;   In: CON_PENDING_CHAR = type-ahead char (nonzero => a key is already pending).
;   Out: A = 1 if a character is ready, 0 if not.
;   Clobbers: AF.
;   Algorithm: if a char is already buffered, report ready; else ask the BIOS console
;              status vector ($AA06). If a key is down, peek it ($AA09): Ctrl-S (13h)
;              stalls (then Ctrl-C warm-boots via JP 0); any other key is stashed in
;              CON_PENDING_CHAR as type-ahead and reported ready.
;   [RE] Backs the BDOS console-status / flow-control behaviour.
; ----------------------------------------------------------------------
CON_POLL_STATUS:
        ; Already have a buffered char?
        LD A,(CON_PENDING_CHAR)                    ; $9D23  3A 0E 9F
        OR A                             ; $9D26  B7
        ; Yes -> report 'ready' (A=1)
        JP NZ,CON_STATUS_READY                 ; $9D27  C2 45 9D
        ; BIOS console status vector
        CALL $AA06                       ; $9D2A  CD 06 AA
        ; Bit0 = key available?
        AND $01                          ; $9D2D  E6 01
        ; No key -> return A=0 (not ready)
        RET Z                            ; $9D2F  C8
        ; Read the pending key
        CALL $AA09                       ; $9D30  CD 09 AA
        ; Ctrl-S (stop/flow-control)?
        CP $13                           ; $9D33  FE 13
        ; No -> buffer it as type-ahead
        JP NZ,CON_POLL_STASH                 ; $9D35  C2 42 9D
        ; After Ctrl-S, wait for the resume/abort key
        CALL $AA09                       ; $9D38  CD 09 AA
        ; Ctrl-C while paused?
        CP $03                           ; $9D3B  FE 03
        ; Ctrl-C -> warm boot
        JP Z,$0000                       ; $9D3D  CA 00 00
        ; Otherwise resume: report 'no key' (A=0)
        XOR A                            ; $9D40  AF
        RET                              ; $9D41  C9
; ----------------------------------------------------------------------
; CON_POLL_STASH -- stash the just-read key as type-ahead and report 'ready'.
;   In: A = key character to hold.
;   Out: A = 1 (ready).
;   Clobbers: none beyond A.
;   Algorithm: store A into the 1-char type-ahead cell, then fall into the A:=1 tail.
; ----------------------------------------------------------------------
CON_POLL_STASH:
        ; Hold the key in the type-ahead buffer
        LD (CON_PENDING_CHAR),A                    ; $9D42  32 0E 9F
; ----------------------------------------------------------------------
; CON_STATUS_READY -- return A=1, the 'character is ready' status result.
;   In: none. Out: A=1. Clobbers: A.
;   [RE] Shared tail of CON_POLL_STATUS.
; ----------------------------------------------------------------------
CON_STATUS_READY:
        ; Status = ready
        LD A,$01                         ; $9D45  3E 01
        RET                              ; $9D47  C9
; ----------------------------------------------------------------------
; CON_PUT_COL -- output one char to the console, tracking column and honouring Ctrl-S.
;   In: C = character to print.
;   Out: char sent to console (and to the list device if echo flag set); column counter
;        CON_COL updated for printables; BS/LF adjust it.
;   Clobbers: AF, HL (BC preserved across the BIOS calls).
;   Algorithm: unless a redisplay-suppress flag (CON_SAVED_COL) is set, poll for Ctrl-S/Ctrl-C
;              then send C to the BIOS conout vector ($AA0C) and, if the printer-echo
;              flag CON_LIST_ECHO is set, to the list vector ($AA0F). Then update the column:
;              DEL(7F) leaves it; printable >=' ' increments; BS decrements; LF zeroes it.
;   [RE] Core character-output + column bookkeeping for the console writer.
; ----------------------------------------------------------------------
CON_PUT_COL:
        ; Redisplay-in-progress? skip status poll/echo if so
        LD A,(CON_SAVED_COL)                    ; $9D48  3A 0A 9F
        OR A                             ; $9D4B  B7
        ; Suppressed: go straight to column tracking
        JP NZ,CON_TRACK_COL                 ; $9D4C  C2 62 9D
        PUSH BC                          ; $9D4F  C5
        ; Poll for Ctrl-S/Ctrl-C before output
        CALL CON_POLL_STATUS                    ; $9D50  CD 23 9D
        POP BC                           ; $9D53  C1
        PUSH BC                          ; $9D54  C5
        ; BIOS console-output vector
        CALL $AA0C                       ; $9D55  CD 0C AA
        POP BC                           ; $9D58  C1
        PUSH BC                          ; $9D59  C5
        ; Printer (list) echo enabled?
        LD A,(CON_LIST_ECHO)                    ; $9D5A  3A 0D 9F
        OR A                             ; $9D5D  B7
        ; Also send to the list device
        CALL NZ,$AA0F                    ; $9D5E  C4 0F AA
        POP BC                           ; $9D61  C1
; ----------------------------------------------------------------------
; CON_TRACK_COL -- update the output column counter for the char just sent.
;   In: C = the char emitted; CON_COL = current column.
;   Out: CON_COL adjusted (DEL no-op, printable +1, BS -1 if nonzero, LF -> 0).
;   Clobbers: AF, HL.
;   Algorithm: DEL(7F) -> return; >=' ' -> increment column; control chars -> if column
;              is already 0 return; BS(08) -> decrement; LF(0A) -> zero the column.
;   [RE] Column bookkeeping shared by CON_PUT_COL.
; ----------------------------------------------------------------------
CON_TRACK_COL:
        LD A,C                           ; $9D62  79
        ; HL -> current output column
        LD HL,CON_COL                     ; $9D63  21 0C 9F
        ; DELETE: no column change
        CP $7F                           ; $9D66  FE 7F
        RET Z                            ; $9D68  C8
        ; Tentatively advance the column
        INC (HL)                         ; $9D69  34
        ; Printable (>= space)? keep the increment
        CP $20                           ; $9D6A  FE 20
        RET NC                           ; $9D6C  D0
        ; Control char: undo the increment
        DEC (HL)                         ; $9D6D  35
        LD A,(HL)                        ; $9D6E  7E
        OR A                             ; $9D6F  B7
        RET Z                            ; $9D70  C8
        LD A,C                           ; $9D71  79
        ; Backspace?
        CP $08                           ; $9D72  FE 08
        JP NZ,CON_TRACK_COL_LF                 ; $9D74  C2 79 9D
        DEC (HL)                         ; $9D77  35
        RET                              ; $9D78  C9
; ----------------------------------------------------------------------
; CON_TRACK_COL_LF -- handle the line-feed case of column tracking.
;   In: A = the control char; HL -> column cell.
;   Out: column zeroed if A was LF; unchanged otherwise.
;   Clobbers: AF.
;   [RE] LF tail of CON_TRACK_COL.
; ----------------------------------------------------------------------
CON_TRACK_COL_LF:
        ; Line feed?
        CP $0A                           ; $9D79  FE 0A
        RET NZ                           ; $9D7B  C0
        ; LF resets the column to 0
        LD (HL),$00                      ; $9D7C  36 00
        RET                              ; $9D7E  C9
; ----------------------------------------------------------------------
; CON_PUT_VISIBLE -- output a char, expanding non-tab control codes as '^X'.
;   In: C = character.
;   Out: char(s) sent via CON_PUT_COL; TAB handled by F_CONOUT_H expansion.
;   Clobbers: AF.
;   Algorithm: if the char is a handled control (IS_CTRL_CHAR, carry clear) print it
;              normally through F_CONOUT_H; otherwise emit '^' then the char OR'd with
;              40h (control-to-letter), so e.g. Ctrl-A shows as '^A'.
;   [RE] Visible-control echo used by the line editor's buffer redisplay.
; ----------------------------------------------------------------------
CON_PUT_VISIBLE:
        LD A,C                           ; $9D7F  79
        ; Classify; carry clear => print as-is
        CALL IS_CTRL_CHAR                    ; $9D80  CD 14 9D
        ; Ordinary char/tab: normal output
        JP NC,F_CONOUT_H                   ; $9D83  D2 90 9D
        PUSH AF                          ; $9D86  F5
        ; '^' caret prefix for a control char
        LD C,$5E                         ; $9D87  0E 5E
        ; Print the caret
        CALL CON_PUT_COL                    ; $9D89  CD 48 9D
        POP AF                           ; $9D8C  F1
        ; Map control code to its display letter
        OR $40                           ; $9D8D  F6 40
        LD C,A                           ; $9D8F  4F
; ----------------------------------------------------------------------
; F_CONOUT_H -- BDOS console-output handler (function 2) with tab expansion.
;   In: C = character to print.
;   Out: character emitted; TAB expands to spaces to the next 8-column stop.
;   Clobbers: AF.
;   Algorithm: if C != TAB(09) just print it via CON_PUT_COL; if TAB, emit spaces
;              through CON_PUT_COL until the column counter (CON_COL) is a multiple of 8.
;   [RE] BDOS function 2 (Console Output) backing routine.
; ----------------------------------------------------------------------
F_CONOUT_H:
        LD A,C                           ; $9D90  79
        ; Tab character?
        CP $09                           ; $9D91  FE 09
        ; Non-tab: print directly
        JP NZ,CON_PUT_COL                   ; $9D93  C2 48 9D
; ----------------------------------------------------------------------
; CONOUT_TAB_FILL -- emit spaces until the column reaches the next 8-stop (tab expand).
;   In: CON_COL = current column.
;   Out: spaces printed until (column & 7)==0.
;   Clobbers: AF, C.
;   Algorithm: output a space via CON_PUT_COL, re-read the column, loop while low 3 bits
;              are nonzero.
;   [RE] Tab-expansion loop of F_CONOUT_H.
; ----------------------------------------------------------------------
CONOUT_TAB_FILL:
        ; Space to fill the tab
        LD C,$20                         ; $9D96  0E 20
        CALL CON_PUT_COL                    ; $9D98  CD 48 9D
        LD A,(CON_COL)                    ; $9D9B  3A 0C 9F
        ; At an 8-column tab stop yet?
        AND $07                          ; $9D9E  E6 07
        ; Not yet -> emit another space
        JP NZ,CONOUT_TAB_FILL                 ; $9DA0  C2 96 9D
        RET                              ; $9DA3  C9
; ----------------------------------------------------------------------
; CON_BACKSPACE -- erase the last echoed character (BS, space, BS).
;   In: none. Out: cursor moved left one cell, char blanked on screen.
;   Clobbers: AF, C.
;   Algorithm: emit BS (via CON_BS_OUT), then space, then BS again through the BIOS
;              conout vector so the previous glyph is overwritten with a blank.
;   [RE] Destructive backspace used by the line editor on rubout.
; ----------------------------------------------------------------------
CON_BACKSPACE:
        ; Send a backspace
        CALL CON_BS_OUT                    ; $9DA4  CD AC 9D
        ; Overwrite the char with a space
        LD C,$20                         ; $9DA7  0E 20
        ; BIOS conout: print the blanking space
        CALL $AA0C                       ; $9DA9  CD 0C AA
; ----------------------------------------------------------------------
; CON_BS_OUT -- send a single backspace (08) to the console.
;   In: none. Out: BS emitted via the BIOS conout vector.
;   Clobbers: C.
;   [RE] Tail-call helper; also used as the leading BS of CON_BACKSPACE.
; ----------------------------------------------------------------------
CON_BS_OUT:
        ; Backspace character
        LD C,$08                         ; $9DAC  0E 08
        ; BIOS conout (tail call)
        JP $AA0C                         ; $9DAE  C3 0C AA
; ----------------------------------------------------------------------
; CON_RETYPE_LINE -- echo '#' + CR/LF and reprint the current edit buffer (Ctrl-R).
;   In: CON_COL = total chars in the line; the edit buffer follows BDOS_PARAM_PTR's pointer.
;   Out: a fresh copy of the typed line shown on a new line.
;   Clobbers: AF, C, HL.
;   Algorithm: print '#', CR/LF (CON_CRLF), then loop re-emitting characters with
;              CON_PUT_COL until the echoed count CON_LINE_START_COL reaches CON_COL.
;   [RE] Implements the line editor's Ctrl-R (retype) function.
; ----------------------------------------------------------------------
CON_RETYPE_LINE:
        ; '#' marker shown for a retype
        LD C,$23                         ; $9DB1  0E 23
        ; Print the '#'
        CALL CON_PUT_COL                    ; $9DB3  CD 48 9D
        ; CR/LF onto a fresh line
        CALL CON_CRLF                    ; $9DB6  CD C9 9D
; ----------------------------------------------------------------------
; CON_RETYPE_LOOP -- reprint buffered characters until the column matches the count.
;   In: CON_LINE_START_COL = chars already re-echoed; CON_COL = target count.
;   Out: remaining buffered chars emitted as spaces (placeholder re-echo).
;   Clobbers: AF, C, HL.
;   Algorithm: while column (CON_COL) >= the running CON_LINE_START_COL counter is false, emit a
;              space via CON_PUT_COL and loop.
;   [RE] Re-echo loop of CON_RETYPE_LINE.
;   [?] The compared cells are the editor's column vs echoed-count; exact pairing UNKNOWN
;       beyond 'advance until equal'.
; ----------------------------------------------------------------------
CON_RETYPE_LOOP:
        ; Current column / line length
        LD A,(CON_COL)                    ; $9DB9  3A 0C 9F
        ; HL -> echoed-count cell
        LD HL,CON_LINE_START_COL                     ; $9DBC  21 0B 9F
        ; Reached the end of the buffer?
        CP (HL)                          ; $9DBF  BE
        ; Done re-echoing
        RET NC                           ; $9DC0  D0
        ; Emit a space placeholder
        LD C,$20                         ; $9DC1  0E 20
        CALL CON_PUT_COL                    ; $9DC3  CD 48 9D
        JP CON_RETYPE_LOOP                    ; $9DC6  C3 B9 9D
; ----------------------------------------------------------------------
; CON_CRLF -- output a carriage-return / line-feed pair to the console.
;   In: none. Out: CR then LF emitted; column reset by the LF.
;   Clobbers: AF, C.
;   Algorithm: CON_PUT_COL with CR(0D), then tail-call CON_PUT_COL with LF(0A).
;   [RE] Newline helper used throughout the console/error paths.
; ----------------------------------------------------------------------
CON_CRLF:
        ; Carriage return
        LD C,$0D                         ; $9DC9  0E 0D
        ; Emit CR
        CALL CON_PUT_COL                    ; $9DCB  CD 48 9D
        ; Line feed
        LD C,$0A                         ; $9DCE  0E 0A
        ; Emit LF (tail call)
        JP CON_PUT_COL                      ; $9DD0  C3 48 9D
; ----------------------------------------------------------------------
; CON_PRINT_STR -- print a '$'-terminated string to the console.
;   In: BC = pointer to the string; terminated by '$' (24h).
;   Out: each char emitted via F_CONOUT_H until '$' is reached.
;   Clobbers: AF, BC, C.
;   Algorithm: load (BC); if '$' return; else advance BC, output the char through
;              F_CONOUT_H (preserving BC), and loop.
;   [RE] The '$'-terminated string writer; backs BDOS function 9 and the error printer.
; ----------------------------------------------------------------------
CON_PRINT_STR:
        ; Fetch next string byte
        LD A,(BC)                        ; $9DD3  0A
        ; '$' string terminator?
        CP $24                           ; $9DD4  FE 24
        ; End of string
        RET Z                            ; $9DD6  C8
        INC BC                           ; $9DD7  03
        PUSH BC                          ; $9DD8  C5
        LD C,A                           ; $9DD9  4F
        ; Print the character
        CALL F_CONOUT_H                    ; $9DDA  CD 90 9D
        POP BC                           ; $9DDD  C1
        ; Next character
        JP CON_PRINT_STR                    ; $9DDE  C3 D3 9D
; ----------------------------------------------------------------------
; F_READCONBUF_H -- BDOS buffered console line input (function 10) with editing.
;   In: BDOS_PARAM_PTR -> the read buffer (byte0 = max length, byte1 = returned count, data...).
;   Out: the buffer filled with the edited line; byte1 set to the char count.
;   Clobbers: AF, BC, DE, HL.
;   Algorithm: seed the echoed-count from the current column; read chars one at a time
;              (CON_GETC_OR_RAW, masked to 7 bits) and dispatch the editing controls:
;              CR/LF terminate; BS/DEL delete; Ctrl-E new line; Ctrl-P printer toggle;
;              Ctrl-X erase line; Ctrl-U abandon (#); Ctrl-R retype; other chars are
;              stored (full buffer rings). Terminates by writing the count and CR.
;   [RE] Classic CP/M 2.2 line editor (Read Console Buffer).
; ----------------------------------------------------------------------
F_READCONBUF_H:
        ; Start echoed-count at the current column
        LD A,(CON_COL)                    ; $9DE1  3A 0C 9F
        LD (CON_LINE_START_COL),A                    ; $9DE4  32 0B 9F
        ; HL -> caller's input buffer descriptor
        LD HL,(BDOS_PARAM_PTR)                   ; $9DE7  2A 43 9F
        ; C = buffer maximum length
        LD C,(HL)                        ; $9DEA  4E
        ; Skip to the data area (past max/count bytes)
        INC HL                           ; $9DEB  23
        PUSH HL                          ; $9DEC  E5
        ; B = current character count (starts 0)
        LD B,$00                         ; $9DED  06 00
; ----------------------------------------------------------------------
; READBUF_NEXT -- top of the line-editor read loop: save state and fetch a char.
;   In: B = count so far, HL -> buffer position.
;   Out: falls into READBUF_GETC with BC/HL preserved on the stack.
;   Clobbers: stack.
;   [RE] Per-keystroke loop head of F_READCONBUF_H.
; ----------------------------------------------------------------------
READBUF_NEXT:
        PUSH BC                          ; $9DEF  C5
        PUSH HL                          ; $9DF0  E5
; ----------------------------------------------------------------------
; READBUF_GETC -- read and classify the next edit character.
;   In: stacked BC/HL = saved count and buffer pointer.
;   Out: A = 7-bit char; control codes dispatched to the appropriate editor handler.
;   Clobbers: AF, BC, HL.
;   Algorithm: CON_GETC_OR_RAW, mask to 7 bits, restore BC/HL, then chain CP/JP tests:
;              CR/LF -> finish; BS -> delete; the remaining tests fall through to the
;              DEL / control-key handlers.
;   [RE] Keystroke dispatcher inside F_READCONBUF_H.
; ----------------------------------------------------------------------
READBUF_GETC:
        ; Read next raw/type-ahead char
        CALL CON_GETC_OR_RAW                    ; $9DF1  CD FB 9C
        ; Strip the high bit (7-bit ASCII)
        AND $7F                          ; $9DF4  E6 7F
        POP HL                           ; $9DF6  E1
        POP BC                           ; $9DF7  C1
        ; CR -> end of line
        CP $0D                           ; $9DF8  FE 0D
        JP Z,READBUF_DONE                 ; $9DFA  CA C1 9E
        ; LF -> end of line
        CP $0A                           ; $9DFD  FE 0A
        JP Z,READBUF_DONE                 ; $9DFF  CA C1 9E
        ; Backspace -> delete char
        CP $08                           ; $9E02  FE 08
        JP NZ,READBUF_DEL                 ; $9E04  C2 16 9E
        LD A,B                           ; $9E07  78
        OR A                             ; $9E08  B7
        ; Buffer empty: nothing to delete, re-loop
        JP Z,READBUF_NEXT                  ; $9E09  CA EF 9D
        DEC B                            ; $9E0C  05
        LD A,(CON_COL)                    ; $9E0D  3A 0C 9F
        LD (CON_SAVED_COL),A                    ; $9E10  32 0A 9F
        JP READBUF_REDISPLAY                   ; $9E13  C3 70 9E
; ----------------------------------------------------------------------
; READBUF_DEL -- handle DEL (7F) as a destructive rubout of the previous char.
;   In: A = char (7F), B = count, HL -> buffer position.
;   Out: if buffer nonempty, last char fetched for re-echo handling and pointer/count
;        backed up; empty buffer just re-loops.
;   Clobbers: AF, B, HL.
;   [RE] DELETE key path of the line editor.
; ----------------------------------------------------------------------
READBUF_DEL:
        ; DELETE key?
        CP $7F                           ; $9E16  FE 7F
        ; No -> try the next control
        JP NZ,READBUF_CTRL_E                 ; $9E18  C2 26 9E
        LD A,B                           ; $9E1B  78
        OR A                             ; $9E1C  B7
        ; Empty buffer: ignore, re-loop
        JP Z,READBUF_NEXT                  ; $9E1D  CA EF 9D
        LD A,(HL)                        ; $9E20  7E
        DEC B                            ; $9E21  05
        ; Back up the buffer pointer
        DEC HL                           ; $9E22  2B
        JP READBUF_STORE_ECHO                   ; $9E23  C3 A9 9E
; ----------------------------------------------------------------------
; READBUF_CTRL_E -- handle Ctrl-E (05): physical CR/LF without ending the line.
;   In: A = char, BC/HL = editor state.
;   Out: cursor moved to a new line, echoed-count reset; editing continues.
;   Clobbers: AF.
;   Algorithm: on Ctrl-E print CR/LF (CON_CRLF), zero the echoed-count CON_LINE_START_COL, and
;              resume reading; otherwise fall through to the next control test.
; ----------------------------------------------------------------------
READBUF_CTRL_E:
        ; Ctrl-E -> physical new line
        CP $05                           ; $9E26  FE 05
        ; No -> try Ctrl-P
        JP NZ,READBUF_CTRL_P                 ; $9E28  C2 37 9E
        PUSH BC                          ; $9E2B  C5
        PUSH HL                          ; $9E2C  E5
        ; Emit CR/LF
        CALL CON_CRLF                    ; $9E2D  CD C9 9D
        XOR A                            ; $9E30  AF
        ; Reset the echoed-count to 0
        LD (CON_LINE_START_COL),A                    ; $9E31  32 0B 9F
        JP READBUF_GETC                    ; $9E34  C3 F1 9D
; ----------------------------------------------------------------------
; READBUF_CTRL_P -- handle Ctrl-P (10): toggle the printer (list-device) echo flag.
;   In: A = char.
;   Out: CON_LIST_ECHO flipped between 0 and 1; editing continues.
;   Clobbers: AF, HL.
;   Algorithm: on Ctrl-P compute 1 - CON_LIST_ECHO to toggle the printer-echo flag, then loop;
;              otherwise fall through to the Ctrl-X test.
; ----------------------------------------------------------------------
READBUF_CTRL_P:
        ; Ctrl-P -> toggle printer echo
        CP $10                           ; $9E37  FE 10
        ; No -> try Ctrl-X
        JP NZ,READBUF_CTRL_X                 ; $9E39  C2 48 9E
        PUSH HL                          ; $9E3C  E5
        ; HL -> printer-echo flag
        LD HL,CON_LIST_ECHO                     ; $9E3D  21 0D 9F
        LD A,$01                         ; $9E40  3E 01
        ; 1 - flag => toggle 0<->1
        SUB (HL)                         ; $9E42  96
        LD (HL),A                        ; $9E43  77
        POP HL                           ; $9E44  E1
        JP READBUF_NEXT                    ; $9E45  C3 EF 9D
; ----------------------------------------------------------------------
; READBUF_CTRL_X -- handle Ctrl-X (18): erase the whole input line.
;   In: A = char; CON_COL = column; CON_LINE_START_COL = start column.
;   Out: all echoed chars backspaced away and the buffer emptied; editing restarts.
;   Clobbers: AF, HL.
;   Algorithm: on Ctrl-X loop CON_BACKSPACE while the column exceeds the line-start,
;              then restart the read with an empty buffer; else fall to the Ctrl-U test.
; ----------------------------------------------------------------------
READBUF_CTRL_X:
        ; Ctrl-X -> erase entire line
        CP $18                           ; $9E48  FE 18
        ; No -> try Ctrl-U
        JP NZ,READBUF_CTRL_U                ; $9E4A  C2 5F 9E
        POP HL                           ; $9E4D  E1
; ----------------------------------------------------------------------
; READBUF_ERASE_LOOP -- backspace-erase characters back to the line start.
;   In: CON_LINE_START_COL = start column, CON_COL = current column.
;   Out: console column reduced to the start; chars visually erased.
;   Clobbers: AF, HL.
;   Algorithm: while current column > start column, decrement it and CON_BACKSPACE.
;   [RE] Erase loop shared by Ctrl-X.
; ----------------------------------------------------------------------
READBUF_ERASE_LOOP:
        ; Line-start column
        LD A,(CON_LINE_START_COL)                    ; $9E4E  3A 0B 9F
        LD HL,CON_COL                     ; $9E51  21 0C 9F
        ; Reached the start?
        CP (HL)                          ; $9E54  BE
        ; Yes -> restart with an empty buffer
        JP NC,F_READCONBUF_H                 ; $9E55  D2 E1 9D
        DEC (HL)                         ; $9E58  35
        ; Backspace-erase one cell
        CALL CON_BACKSPACE                    ; $9E59  CD A4 9D
        JP READBUF_ERASE_LOOP                    ; $9E5C  C3 4E 9E
; ----------------------------------------------------------------------
; READBUF_CTRL_U -- handle Ctrl-U (15): abandon the line, show '#', restart.
;   In: A = char.
;   Out: '#' printed, fresh line started, buffer reset.
;   Clobbers: AF, HL.
;   Algorithm: on Ctrl-U mark the abandoned line (CON_RETYPE_LINE prints '#'+CRLF) and
;              restart the read; otherwise fall to the Ctrl-R test.
; ----------------------------------------------------------------------
READBUF_CTRL_U:
        ; Ctrl-U -> abandon line (#)
        CP $15                           ; $9E5F  FE 15
        ; No -> try Ctrl-R
        JP NZ,READBUF_CTRL_R                ; $9E61  C2 6B 9E
        ; Mark '#' and CR/LF
        CALL CON_RETYPE_LINE                    ; $9E64  CD B1 9D
        POP HL                           ; $9E67  E1
        ; Restart input with an empty buffer
        JP F_READCONBUF_H                    ; $9E68  C3 E1 9D
; ----------------------------------------------------------------------
; READBUF_CTRL_R -- handle Ctrl-R (12): retype the current line, else store the char.
;   In: A = char, B = count, HL -> buffer.
;   Out: Ctrl-R reprints the buffer; any other char falls into the store path.
;   Clobbers: AF.
;   Algorithm: if char != Ctrl-R, jump to the FCB/store path (the dispatcher's default);
;              on Ctrl-R fall into the retype-and-redisplay sequence.
; ----------------------------------------------------------------------
READBUF_CTRL_R:
        ; Ctrl-R -> retype line
        CP $12                           ; $9E6B  FE 12
        ; Other char -> store it in the buffer
        JP NZ,READBUF_STORE                ; $9E6D  C2 A6 9E
; ----------------------------------------------------------------------
; READBUF_REDISPLAY -- reprint the buffered line after a retype/delete.
;   In: B = char count; buffer on stack (HL).
;   Out: '#'/CRLF emitted then each buffered char re-echoed via CON_PUT_VISIBLE.
;   Clobbers: AF, BC, HL.
;   Algorithm: CON_RETYPE_LINE for the marker, then walk the buffer re-echoing each
;              stored char with CON_PUT_VISIBLE (so controls show as '^X').
;   [RE] Buffer redisplay used by Ctrl-R and after a backspace.
; ----------------------------------------------------------------------
READBUF_REDISPLAY:
        PUSH BC                          ; $9E70  C5
        ; Print '#' + CR/LF before redisplay
        CALL CON_RETYPE_LINE                    ; $9E71  CD B1 9D
        POP BC                           ; $9E74  C1
        POP HL                           ; $9E75  E1
        PUSH HL                          ; $9E76  E5
        PUSH BC                          ; $9E77  C5
; ----------------------------------------------------------------------
; READBUF_REDISPLAY_LOOP -- re-echo each buffered character.
;   In: B = remaining count, HL -> buffer position.
;   Out: every buffered char emitted via CON_PUT_VISIBLE.
;   Clobbers: AF, BC, C, HL.
;   Algorithm: while B != 0, advance HL, load the char, CON_PUT_VISIBLE it, decrement B;
;              on exhaustion fall into the post-redisplay column fixup (READBUF_REPOS).
;   [RE] Redisplay loop of READBUF_REDISPLAY.
; ----------------------------------------------------------------------
READBUF_REDISPLAY_LOOP:
        LD A,B                           ; $9E78  78
        OR A                             ; $9E79  B7
        ; All re-echoed -> fix up column
        JP Z,READBUF_REPOS                 ; $9E7A  CA 8A 9E
        INC HL                           ; $9E7D  23
        LD C,(HL)                        ; $9E7E  4E
        DEC B                            ; $9E7F  05
        PUSH BC                          ; $9E80  C5
        PUSH HL                          ; $9E81  E5
        ; Re-echo char (controls as ^X)
        CALL CON_PUT_VISIBLE                    ; $9E82  CD 7F 9D
        POP HL                           ; $9E85  E1
        POP BC                           ; $9E86  C1
        JP READBUF_REDISPLAY_LOOP                   ; $9E87  C3 78 9E
; ----------------------------------------------------------------------
; READBUF_REPOS -- after redisplay, backspace the cursor to the edit position.
;   In: CON_SAVED_COL = saved column to restore to, CON_COL = current column.
;   Out: cursor moved back so further typing continues at the right spot.
;   Clobbers: AF, HL.
;   Algorithm: if no saved position (CON_SAVED_COL==0) resume reading; else compute how far past
;              the target the cursor is (CON_SAVED_COL := saved - column) and fall into the
;              backspace loop READBUF_REPOS_LOOP.
;   [RE] Cursor-reposition step after a Ctrl-R / delete redisplay.
;   [?] Auto-name 'READBUF_REPOS' was a stale/mislabel from the skewed source -- this is
;       console line-editor code, NOT directory traversal.
; ----------------------------------------------------------------------
READBUF_REPOS:
        PUSH HL                          ; $9E8A  E5
        ; Saved cursor column (0 = none)
        LD A,(CON_SAVED_COL)                    ; $9E8B  3A 0A 9F
        OR A                             ; $9E8E  B7
        ; Nothing to restore -> read next char
        JP Z,READBUF_GETC                  ; $9E8F  CA F1 9D
        LD HL,CON_COL                     ; $9E92  21 0C 9F
        ; saved - current column = cells to back up
        SUB (HL)                         ; $9E95  96
        LD (CON_SAVED_COL),A                    ; $9E96  32 0A 9F
; ----------------------------------------------------------------------
; READBUF_REPOS_LOOP -- backspace the cursor by the computed cell count.
;   In: CON_SAVED_COL = number of cells to back up.
;   Out: cursor repositioned; loop ends and the editor reads the next char.
;   Clobbers: AF, HL.
;   Algorithm: CON_BACKSPACE, decrement CON_SAVED_COL, repeat until zero, then resume input.
;   [RE] Reposition loop of READBUF_REPOS.
; ----------------------------------------------------------------------
READBUF_REPOS_LOOP:
        ; Backspace one cell
        CALL CON_BACKSPACE                    ; $9E99  CD A4 9D
        LD HL,CON_SAVED_COL                     ; $9E9C  21 0A 9F
        DEC (HL)                         ; $9E9F  35
        ; More cells to back up
        JP NZ,READBUF_REPOS_LOOP                ; $9EA0  C2 99 9E
        ; Done -> read next char
        JP READBUF_GETC                    ; $9EA3  C3 F1 9D
; ----------------------------------------------------------------------
; READBUF_STORE -- store an ordinary character into the input buffer.
;   In: A = char to store, B = count, HL -> next buffer slot.
;   Out: char written, count incremented; falls into the echo/limit check.
;   Clobbers: AF, B, HL.
;   Algorithm: write the char at ++HL, bump B, then fall into READBUF_STORE_ECHO which
;              echoes it and checks the buffer-full limit.
;   [?] Auto-name 'READBUF_STORE' is a stale skew mislabel -- this is the line
;       editor's character-store path, NOT an FCB/directory compare.
; ----------------------------------------------------------------------
READBUF_STORE:
        INC HL                           ; $9EA6  23
        ; Store the typed char in the buffer
        LD (HL),A                        ; $9EA7  77
        ; Bump the character count
        INC B                            ; $9EA8  04
; ----------------------------------------------------------------------
; READBUF_STORE_ECHO -- echo the stored char and enforce the buffer length limit.
;   In: A = char, B = count, C = buffer max length.
;   Out: char echoed; if count reached the max (or hit a hard limit) the line is
;        terminated, otherwise reading continues.
;   Clobbers: AF, BC, HL.
;   Algorithm: echo via CON_PUT_VISIBLE; reload the buffer max; if the max byte is 1
;              (degenerate) terminate immediately; if count == max terminate, else loop.
;   [RE] Store-and-limit tail of the line editor.
;   [?] The CP $03 then CP $01 sequence tests the buffer-descriptor max byte; exact
;       degenerate-case semantics beyond 'terminate when full' are UNKNOWN.
; ----------------------------------------------------------------------
READBUF_STORE_ECHO:
        PUSH BC                          ; $9EA9  C5
        PUSH HL                          ; $9EAA  E5
        LD C,A                           ; $9EAB  4F
        ; Echo the just-stored char
        CALL CON_PUT_VISIBLE                    ; $9EAC  CD 7F 9D
        POP HL                           ; $9EAF  E1
        POP BC                           ; $9EB0  C1
        LD A,(HL)                        ; $9EB1  7E
        ; Inspect the buffer-max byte
        CP $03                           ; $9EB2  FE 03
        LD A,B                           ; $9EB4  78
        JP NZ,READBUF_LIMIT                ; $9EB5  C2 BD 9E
        ; Degenerate max of 1 -> terminate
        CP $01                           ; $9EB8  FE 01
        ; Terminate (warm-boot guard path)
        JP Z,$0000                       ; $9EBA  CA 00 00
; ----------------------------------------------------------------------
; READBUF_LIMIT -- compare the count to the buffer max and continue or finish.
;   In: A = count (B), C = buffer maximum length.
;   Out: if count < max keep reading, else fall into the line-terminate path.
;   Clobbers: AF.
;   Algorithm: CP C; if count < max (carry) loop back to READBUF_NEXT, else finish.
;   [RE] Buffer-full check of the line editor.
; ----------------------------------------------------------------------
READBUF_LIMIT:
        ; count vs buffer max
        CP C                             ; $9EBD  B9
        ; Room left -> read another char
        JP C,READBUF_NEXT                  ; $9EBE  DA EF 9D
; ----------------------------------------------------------------------
; READBUF_DONE -- finish the input line: store the count and emit a CR.
;   In: stacked HL -> buffer count byte; B = final character count.
;   Out: count written into the buffer; CR echoed; returns to the BDOS caller.
;   Clobbers: AF, C, HL.
;   Algorithm: pop the buffer pointer, store B as the returned char count, then output
;              CR via CON_PUT_COL (tail call) to close the input line.
;   [RE] Line-editor termination, reached on CR/LF/buffer-full.
; ----------------------------------------------------------------------
READBUF_DONE:
        POP HL                           ; $9EC1  E1
        ; Write the final character count into the buffer
        LD (HL),B                        ; $9EC2  70
        ; Carriage return to close the line
        LD C,$0D                         ; $9EC3  0E 0D
        ; Emit CR and return to caller
        JP CON_PUT_COL                      ; $9EC5  C3 48 9D
; ----------------------------------------------------------------------
; F_CONIN_H -- BDOS function 1 handler: console input with echo, returned in A.
;   In: none.
;   Out: BDOS result (BDOS_RETVAL) = char read.
;   Clobbers: AF, BC, HL.
;   Algorithm: read+echo via F_CONIN_RAW, then store the char as the BDOS return value.
;   [RE] Dispatch-table entry for function 1.
; ----------------------------------------------------------------------
F_CONIN_H:
        ; Read one char (with echo)
        CALL F_CONIN_RAW                    ; $9EC8  CD 06 9D
        ; Store as the BDOS return value
        JP BDOS_RET_RESULT                   ; $9ECB  C3 01 9F
; ----------------------------------------------------------------------
; F_READERIN_H -- BDOS function 3 handler: read from the reader (AUX/RDR) device.
;   In: none.
;   Out: BDOS result (BDOS_RETVAL) = byte from the BIOS reader vector.
;   Clobbers: AF.
;   Algorithm: call the BIOS reader-input vector ($AA15), store the byte as the result.
;   [RE] Dispatch entry for function 3 (Reader Input).
; ----------------------------------------------------------------------
F_READERIN_H:
        ; BIOS reader-input vector
        CALL $AA15                       ; $9ECE  CD 15 AA
        ; Store as the BDOS return value
        JP BDOS_RET_RESULT                   ; $9ED1  C3 01 9F
; ----------------------------------------------------------------------
; F_DIRECTIO_H -- BDOS function 6 handler: direct console I/O.
;   In: C = subfunction (FF = input/status, FE = status only, else = output char).
;   Out: input/status results returned via BDOS_RET_RESULT; output sent to console.
;   Clobbers: AF.
;   Algorithm: C==FF -> direct input branch; C==FE -> raw BIOS console-status ($AA06);
;              otherwise treat C as a character and send it to the BIOS conout ($AA0C),
;              bypassing the editor and flow control.
;   [RE] Dispatch entry for function 6 (Direct Console I/O).
; ----------------------------------------------------------------------
F_DIRECTIO_H:
        LD A,C                           ; $9ED4  79
        ; C==FE? (status-only subfunction)
        ; C==FF? (test for direct-input subfunction)
        INC A                            ; $9ED5  3C
        ; FF -> direct console input
        JP Z,DIRECTIO_INPUT                 ; $9ED6  CA E0 9E
        INC A                            ; $9ED9  3C
        ; FE -> raw BIOS console status
        JP Z,$AA06                       ; $9EDA  CA 06 AA
        ; Else output C directly via BIOS conout
        JP $AA0C                         ; $9EDD  C3 0C AA
; ----------------------------------------------------------------------
; DIRECTIO_INPUT -- direct console input subfunction of function 6.
;   In: none.
;   Out: BDOS result = char if one is ready, else 0; no echo, no flow control.
;   Clobbers: AF.
;   Algorithm: poll raw BIOS console status ($AA06); if no key, return 0 (A=0 result);
;              if a key is ready, read it raw ($AA09) and store as the result.
;   [?] Auto-name carries a stale 'READBUF_STORE' skew prefix -- this is direct
;       console input, NOT an FCB/directory routine.
; ----------------------------------------------------------------------
DIRECTIO_INPUT:
        ; Raw BIOS console status
        CALL $AA06                       ; $9EE0  CD 06 AA
        OR A                             ; $9EE3  B7
        ; No key -> return 0 result
        JP Z,BDOS_RETURN_RESULT                 ; $9EE4  CA 91 A9
        ; Read the key raw (no echo)
        CALL $AA09                       ; $9EE7  CD 09 AA
        ; Store as the BDOS return value
        JP BDOS_RET_RESULT                   ; $9EEA  C3 01 9F
; ----------------------------------------------------------------------
; F_GETIOB_H -- BDOS function 7 handler: get the I/O byte (IOBYTE).
;   In: none.
;   Out: BDOS result = the IOBYTE at fixed address 0003.
;   Clobbers: AF.
;   Algorithm: load (0003) and return it as the result.
;   [RE] Dispatch entry for function 7 (Get IOBYTE).
; ----------------------------------------------------------------------
F_GETIOB_H:
        ; IOBYTE lives at page-zero 0003
        LD A,($0003)                     ; $9EED  3A 03 00
        ; Return it as the BDOS result
        JP BDOS_RET_RESULT                   ; $9EF0  C3 01 9F
; ----------------------------------------------------------------------
; F_SETIOB_H -- BDOS function 8 handler: set the I/O byte (IOBYTE).
;   In: C = new IOBYTE value.
;   Out: (0003) = C.
;   Clobbers: HL.
;   Algorithm: store C into the fixed IOBYTE cell at 0003 and return.
;   [RE] Dispatch entry for function 8 (Set IOBYTE).
; ----------------------------------------------------------------------
F_SETIOB_H:
        ; Page-zero IOBYTE address
        LD HL,$0003                      ; $9EF3  21 03 00
        ; Write the new IOBYTE
        LD (HL),C                        ; $9EF6  71
        RET                              ; $9EF7  C9
; ----------------------------------------------------------------------
; F_PRINTSTR_H -- BDOS function 9 handler: print a '$'-terminated string.
;   In: DE = pointer to the string.
;   Out: string echoed to the console up to the '$'.
;   Clobbers: AF, BC.
;   Algorithm: move DE into BC and tail-call CON_PRINT_STR.
;   [RE] Dispatch entry for function 9 (Print String).
; ----------------------------------------------------------------------
F_PRINTSTR_H:
        EX DE,HL                         ; $9EF8  EB
        ; BC := string pointer (from DE via EX)
        LD C,L                           ; $9EF9  4D
        LD B,H                           ; $9EFA  44
        ; Print '$'-terminated string
        JP CON_PRINT_STR                    ; $9EFB  C3 D3 9D
; ----------------------------------------------------------------------
; F_CONSTAT_H -- BDOS function 11 handler: get console status.
;   In: none.
;   Out: BDOS result = 1 if a console char is ready, else 0.
;   Clobbers: AF.
;   Algorithm: CON_POLL_STATUS to test readiness (handling Ctrl-S/Ctrl-C), then fall
;              into BDOS_RET_RESULT to store the 0/1 status.
;   [RE] Dispatch entry for function 11 (Get Console Status).
; ----------------------------------------------------------------------
F_CONSTAT_H:
        ; Poll console readiness (0/1)
        CALL CON_POLL_STATUS                    ; $9EFE  CD 23 9D
; ----------------------------------------------------------------------
; BDOS_RET_RESULT -- store A as the BDOS function return value and return.
;   In: A = result byte.
;   Out: BDOS_RETVAL (BDOS return cell) = A.
;   Clobbers: none beyond the result cell.
;   Algorithm: write A to the return-value cell; common tail of many handlers.
;   [RE] The BDOS result sink read back by BDOS_DISPATCH on exit.
; ----------------------------------------------------------------------
BDOS_RET_RESULT:
        ; Save A as the BDOS return value
        LD (BDOS_RETVAL),A                    ; $9F01  32 45 9F
; ----------------------------------------------------------------------
; BDOS_RET_NOP -- bare RET; the no-op result tail shared by status handlers.
;   In: none. Out: none. Clobbers: none.
;   [RE] Fall-through return after BDOS_RET_RESULT; also a dispatch-table target for
;        functions that simply return.
; ----------------------------------------------------------------------
BDOS_RET_NOP:
        RET                              ; $9F04  C9
; ----------------------------------------------------------------------
; BDOS_RET_ONE -- set the BDOS return value to 1 and exit.
;   In: none.
;   Out: BDOS result (BDOS_RETVAL) = 1.
;   Clobbers: AF.
;   Algorithm: load A=1 and join BDOS_RET_RESULT.
;   [RE] Used by handlers that report a fixed 'true'/error-code-1 result.
; ----------------------------------------------------------------------
BDOS_RET_ONE:
        ; Result code 1
        LD A,$01                         ; $9F05  3E 01
        ; Store and return
        JP BDOS_RET_RESULT                   ; $9F07  C3 01 9F
; ----------------------------------------------------------------------
; CON_SAVED_COL -- saved cursor column for line-editor redisplay/reposition.
;   Also doubles as a 'suppress status-poll/echo' flag inside CON_PUT_COL.
;   [RE] BDOS console state byte; zero when not repositioning.
; ----------------------------------------------------------------------
CON_SAVED_COL:
        DEFB    "\0"    ; $9F0A
; ----------------------------------------------------------------------
; CON_LINE_START_COL -- column at the start of the current input line (echoed-count base).
;   [RE] Used by the line editor to know how far back Ctrl-X / DEL may erase.
; ----------------------------------------------------------------------
CON_LINE_START_COL:
        DEFB    "\0"    ; $9F0B
; ----------------------------------------------------------------------
; CON_COL -- current console output column counter.
;   [RE] Incremented per printable char, reset by LF; drives tab expansion and editing.
; ----------------------------------------------------------------------
CON_COL:
        DEFB    "\0"    ; $9F0C
; ----------------------------------------------------------------------
; CON_LIST_ECHO -- printer (list device) echo flag; nonzero => mirror console output.
;   [RE] Toggled by the line editor's Ctrl-P.
; ----------------------------------------------------------------------
CON_LIST_ECHO:
        DEFB    "\0"    ; $9F0D
; ----------------------------------------------------------------------
; CON_PENDING_CHAR -- 1-byte console type-ahead / un-get buffer (0 = empty).
;   [RE] Filled by CON_POLL_STATUS, consumed by CON_GETC_OR_RAW.
; ----------------------------------------------------------------------
CON_PENDING_CHAR:
        DEFB    "\0"    ; $9F0E
; ----------------------------------------------------------------------
; BDOS_SAVED_SP -- caller's stack pointer saved on BDOS entry (51-byte cell + slack).
;   [RE] BDOS_DISPATCH saves SP here and switches to the BDOS-local stack; restored on
;        exit. The trailing DEFS reserves the BDOS local stack space below BDOS_STACK_TOP.
; ----------------------------------------------------------------------
BDOS_SAVED_SP:
        DEFS    50, $00    ; $9F0F  fill
; ----------------------------------------------------------------------
; BDOS_STACK_TOP -- top of the BDOS private stack (SP loaded here on entry).
;   [RE] BDOS_DISPATCH does LD SP,BDOS_STACK_TOP before dispatching a function.
; ----------------------------------------------------------------------
BDOS_STACK_TOP:
        DEFB    "\0"    ; $9F41
; ----------------------------------------------------------------------
; BDOS_CUR_DRIVE -- current selected drive index (0=A) for error reporting and disk ops.
;   [RE] Used to form the error-banner drive letter and as the drive arg in random-record
;        / DPB setup.
; ----------------------------------------------------------------------
BDOS_CUR_DRIVE:
        DEFB    "\0"    ; $9F42
; ----------------------------------------------------------------------
; BDOS_PARAM_PTR -- saved DE parameter pointer from the BDOS call (FCB / DMA / buffer).
;   [RE] BDOS_DISPATCH stashes the incoming DE here; consumers (file ops, line input)
;        reload it as the operand pointer. 16-bit cell.
; ----------------------------------------------------------------------
BDOS_PARAM_PTR:
        DEFB    "\0\0"    ; $9F43
; ----------------------------------------------------------------------
; BDOS_RETVAL -- BDOS function return value (16-bit: low byte = A result, high = B).
;   [RE] Cleared on entry; written by BDOS_RET_RESULT; read back by the dispatcher's exit.
; ----------------------------------------------------------------------
BDOS_RETVAL:
        DEFB    "\0\0"    ; $9F45
; ----------------------------------------------------------------------
; BDOS_ERR_SELECT -- enter the BDOS disk-error handler via the error-vector table.
;   In: none (uses the fixed error-vector list at BDOS_ERR_VECTORS).
;   Out: transfers to the indexed error routine (does not return normally).
;   Clobbers: HL, DE.
;   Algorithm: point HL at the error-vector table entry (BDOS_ERRVEC_SELECT) and fall into the
;              dispatch-by-pointer tail BDOS_VECTOR_JUMP.
;   [RE] One of the BDOS_ERR_VECTORS table dispatch entry points.
;   [?] Exact reason-code mapping is encoded by which vector slot the caller chose;
;       semantics beyond 'jump through the error-vector table' are inferred.
; ----------------------------------------------------------------------
BDOS_ERR_SELECT:
        ; Point at the error-vector table slot
        LD HL,BDOS_ERRVEC_SELECT                ; $9F47  21 0B 9C
; ----------------------------------------------------------------------
; BDOS_VECTOR_JUMP -- jump through a 2-byte pointer pointed to by HL.
;   In: HL -> a little-endian routine pointer.
;   Out: control transferred to (HL); does not return here.
;   Clobbers: DE, HL.
;   Algorithm: load DE from (HL), EX DE,HL, JP (HL) -- an indirect call/jump.
;   [RE] Shared indirect-dispatch tail used by the BDOS error/random-record paths.
; ----------------------------------------------------------------------
BDOS_VECTOR_JUMP:
        ; Low byte of the target pointer
        LD E,(HL)                        ; $9F4A  5E
        INC HL                           ; $9F4B  23
        ; High byte of the target pointer
        LD D,(HL)                        ; $9F4C  56
        EX DE,HL                         ; $9F4D  EB
        ; Jump to the resolved routine
        JP (HL)                          ; $9F4E  E9
; ----------------------------------------------------------------------
; BLOCK_COPY_INCC -- copy (C+1) bytes from (DE) to (HL); pre-increment entry.
;   In: C = count-1, DE = source, HL = destination.
;   Out: bytes copied; DE/HL advanced past the block.
;   Clobbers: AF, C, DE, HL.
;   Algorithm: INC C so the following DEC-C-test loop runs C+1 times, copying one byte
;              per pass.
;   [RE] Small memory-copy helper used by the BDOS DPB / random-record setup.
; ----------------------------------------------------------------------
BLOCK_COPY_INCC:
        ; Bump count so the loop runs (C+1) times
        INC C                            ; $9F4F  0C
; ----------------------------------------------------------------------
; BLOCK_COPY_LOOP -- byte-copy loop body for BLOCK_COPY_INCC.
;   In: C = remaining count, DE = source, HL = destination.
;   Out: copies bytes until C decrements to zero.
;   Clobbers: AF, C, DE, HL.
;   Algorithm: DEC C; if zero return; copy (DE)->(HL); INC DE; INC HL; loop.
;   [RE] Loop of the BDOS block-copy helper.
; ----------------------------------------------------------------------
BLOCK_COPY_LOOP:
        ; One fewer byte to copy
        DEC C                            ; $9F50  0D
        ; Count exhausted
        RET Z                            ; $9F51  C8
        ; Read source byte
        LD A,(DE)                        ; $9F52  1A
        ; Store to destination
        LD (HL),A                        ; $9F53  77
        INC DE                           ; $9F54  13
        INC HL                           ; $9F55  23
        ; Next byte
        JP BLOCK_COPY_LOOP                    ; $9F56  C3 50 9F
; ----------------------------------------------------------------------
; DRV_SELECT_DPB -- select the current drive and copy its Disk Parameter Block into BDOS work cells.
;   In: BDOS_CUR_DRIVE = drive index.
;   Out: BDOS DPB/work pointers (DPB_WORK_PTR0, DEBLOCK_HSTREC_PTR0/B7, DPB_XLT_PTR, dir/alloc fields,
;        MAX_BLOCK_DSM, BLOCK_WIDTH_FLAG) populated for the selected drive; A=FF success.
;   Clobbers: AF, BC, DE, HL.
;   Algorithm: ask the BIOS SELDSK vector ($AA1B) for the selected drive's DPH; if null
;              return; chase the DPH to the DPB, copy the translation/allocation pointers
;              and the parameter block into the BDOS working cells (via BLOCK_COPY_INCC),
;              then set BLOCK_WIDTH_FLAG from the max-block-number high byte (single- vs
;              multi-byte block addressing).
;   [RE] Standard CP/M 2.2 drive-select / DPB extraction sequence.
;   [?] Individual A9xx work-cell roles are inferred from the canonical DPB layout.
; ----------------------------------------------------------------------
BDOS_RANDREC_3:
        ; Current drive index
        LD A,(BDOS_CUR_DRIVE)                    ; $9F59  3A 42 9F
        LD C,A                           ; $9F5C  4F
        ; BIOS SELDSK -> DPH pointer in HL
        CALL $AA1B                       ; $9F5D  CD 1B AA
        LD A,H                           ; $9F60  7C
        ; DPH pointer null? (no such drive)
        OR L                             ; $9F61  B5
        ; Null -> bail out
        RET Z                            ; $9F62  C8
        LD E,(HL)                        ; $9F63  5E
        INC HL                           ; $9F64  23
        LD D,(HL)                        ; $9F65  56
        INC HL                           ; $9F66  23
        ; Save the DPB-derived work pointer
        LD (DPB_WORK_PTR0),HL                   ; $9F67  22 B3 A9
        INC HL                           ; $9F6A  23
        INC HL                           ; $9F6B  23
        LD (DEBLOCK_HSTREC_PTR0),HL                   ; $9F6C  22 B5 A9
        INC HL                           ; $9F6F  23
        INC HL                           ; $9F70  23
        LD (DEBLOCK_HSTREC_PTR1),HL                   ; $9F71  22 B7 A9
        INC HL                           ; $9F74  23
        INC HL                           ; $9F75  23
        EX DE,HL                         ; $9F76  EB
        LD (DPB_XLT_PTR),HL                   ; $9F77  22 D0 A9
        LD HL,DIRBUF_PTR                     ; $9F7A  21 B9 A9
        LD C,$08                         ; $9F7D  0E 08
        CALL BLOCK_COPY_INCC                    ; $9F7F  CD 4F 9F
        LD HL,(DPB_PTR)                   ; $9F82  2A BB A9
        EX DE,HL                         ; $9F85  EB
        LD HL,DPB_SPT                     ; $9F86  21 C1 A9
        LD C,$0F                         ; $9F89  0E 0F
        CALL BLOCK_COPY_INCC                    ; $9F8B  CD 4F 9F
        ; Max block number (DSM) for this drive
        LD HL,(MAX_BLOCK_DSM)                   ; $9F8E  2A C6 A9
        LD A,H                           ; $9F91  7C
        ; Flag: 1- vs 2-byte block addressing
        LD HL,BLOCK_WIDTH_FLAG                     ; $9F92  21 DD A9
        LD (HL),$FF                      ; $9F95  36 FF
        OR A                             ; $9F97  B7
        ; DSM high byte 0 => single-byte block map
        JP Z,DRV_SELECT_OK                  ; $9F98  CA 9D 9F
        LD (HL),$00                      ; $9F9B  36 00
; ----------------------------------------------------------------------
; DRV_SELECT_OK -- success tail of the drive-select / DPB-setup path: pick the allocation-map width,
; then return the 'drive selected' status.
;   In: MAX_BLOCK_DSM (the DPB's DSM = highest block number) already loaded; BLOCK_WIDTH_FLAG cell
;       about to be set.
;   Out: A = $FF with flags NZ (OR A leaves A non-zero) -- the non-NULL 'drive selected' indicator
;        returned to the SELDSK caller. BLOCK_WIDTH_FLAG = $FF if DSM < 256 (1-byte allocation
;        entries) or $00 if DSM >= 256 (2-byte entries).
;   Clobbers: A, F (HL was used by the caller just above to address BLOCK_WIDTH_FLAG).
;   Algorithm: this label is the join of two paths. When DSM's high byte is zero (small disk) the
;              caller's 'JP Z' lands here directly, leaving BLOCK_WIDTH_FLAG at its preset $FF;
;              otherwise the caller falls through after first storing $00 into BLOCK_WIDTH_FLAG.
;              Both paths then load A=$FF and OR A so the routine returns a non-zero 'selected'
;              status.
; [RE] Verified from the byte sequence (3E FF / B7 / C9) and from the preceding test of
; MAX_BLOCK_DSM's high byte that selects BLOCK_WIDTH_FLAG. The $FF return is the SELDSK-path success
; value.
; ----------------------------------------------------------------------
DRV_SELECT_OK:
        ; A = $FF: non-zero 'drive selected / parameters valid' status.
        LD A,$FF                         ; $9F9D  3E FF
        ; Set flags from A (NZ) so the caller sees a non-zero result.
        OR A                             ; $9F9F  B7
        RET                              ; $9FA0  C9
; ----------------------------------------------------------------------
; DISK_HOME_CLEAR_SCAN -- seek the drive to track 0 and reset the two BDOS record-scan accumulator
; cells.
;   In: DEBLOCK_HSTREC_PTR0 and DEBLOCK_HSTREC_PTR1 each hold the ADDRESS of a 16-bit scratch word (set up by the drive-select
;       path).
;   Out: BIOS HOME has positioned the head at track 0; the 16-bit word pointed to by (DEBLOCK_HSTREC_PTR0) and
;        the 16-bit word pointed to by (DEBLOCK_HSTREC_PTR1) are both zeroed; A = 0.
;   Clobbers: A, HL, F.
;   Algorithm: CALL the BIOS HOME vector ($AA18, jump-table entry 8) to seek to track 0, then store
;              0 into the two bytes of the word at (DEBLOCK_HSTREC_PTR0) and the two bytes of the word at
;              (DEBLOCK_HSTREC_PTR1). This re-bases the record->track/sector walk at the start of the disk for a
;              fresh scan.
; [RE] $AA18 is jump-table entry 8 = HOME (verified against the BIOS jump table at $AA00). A=0 (XOR
; A) is written through the two stored pointers, two bytes each.
; ----------------------------------------------------------------------
DISK_HOME_CLEAR_SCAN:
        ; BIOS HOME (jump-table entry 8): seek the head to track 0.
        CALL $AA18                       ; $9FA1  CD 18 AA
        ; A = 0, the fill value for the scan-accumulator cells.
        XOR A                            ; $9FA4  AF
        ; HL = address of the first 16-bit scan accumulator; zero its two bytes.
        LD HL,(DEBLOCK_HSTREC_PTR0)                   ; $9FA5  2A B5 A9
        LD (HL),A                        ; $9FA8  77
        INC HL                           ; $9FA9  23
        LD (HL),A                        ; $9FAA  77
        ; HL = address of the second 16-bit scan accumulator; zero its two bytes.
        LD HL,(DEBLOCK_HSTREC_PTR1)                   ; $9FAB  2A B7 A9
        LD (HL),A                        ; $9FAE  77
        INC HL                           ; $9FAF  23
        LD (HL),A                        ; $9FB0  77
        RET                              ; $9FB1  C9
; ----------------------------------------------------------------------
; DISK_READ_CHECKED -- issue a BIOS sector READ and convert a non-zero BIOS status into a BDOS disk
; error.
;   In: BIOS disk parameters (drive/track/sector/DMA) already set by the caller.
;   Out: returns normally if the read succeeded (BIOS A = 0); otherwise does not return -- transfers
;        into the BDOS disk-error dispatcher.
;   Clobbers: A, F (and whatever the BIOS read consumes).
;   Algorithm: CALL the BIOS READ vector ($AA27, jump-table entry 13), then JP to the shared status
;              check (DISK_STATUS_CHECK), which raises a BDOS disk error when A is non-zero.
; [RE] $AA27 is jump-table entry 13 = READ (verified against the BIOS jump table at $AA00); the
; shared tail tests A and dispatches through BDOS_ERR_VECTORS.
; ----------------------------------------------------------------------
DISK_READ_CHECKED:
        ; BIOS READ (jump-table entry 13): read the selected sector into the DMA buffer; A=0 on
        ; success.
        CALL $AA27                       ; $9FB2  CD 27 AA
        JP DISK_STATUS_CHECK                    ; $9FB5  C3 BB 9F
; ----------------------------------------------------------------------
; DISK_WRITE_CHECKED -- issue a BIOS sector WRITE and convert a non-zero BIOS status into a BDOS
; disk error.
;   In: BIOS disk parameters (drive/track/sector/DMA) already set by the caller.
;   Out: returns normally if the write succeeded (BIOS A = 0); otherwise does not return --
;        transfers into the BDOS disk-error dispatcher.
;   Clobbers: A, F (and whatever the BIOS write consumes).
;   Algorithm: CALL the BIOS WRITE vector ($AA2A, jump-table entry 14), then fall through into the
;              shared status check (DISK_STATUS_CHECK), which raises a BDOS disk error when A is
;              non-zero.
; [RE] $AA2A is jump-table entry 14 = WRITE (verified against the BIOS jump table at $AA00); shares
; the error tail with DISK_READ_CHECKED.
; ----------------------------------------------------------------------
DISK_WRITE_CHECKED:
        ; BIOS WRITE (jump-table entry 14): write the DMA buffer to the selected sector; A=0 on
        ; success.
        CALL $AA2A                       ; $9FB8  CD 2A AA
; ----------------------------------------------------------------------
; DISK_STATUS_CHECK -- shared BIOS-status check used by the READ/WRITE wrappers; raise a BDOS disk
; error on failure.
;   In: A = BIOS read/write status (0 = success, non-zero = hardware/select error).
;   Out: returns to the wrapper's caller if A = 0; otherwise points HL at the BDOS error-vector
;        table and jumps into the indirect error dispatcher (does not return).
;   Clobbers: HL, F (on the error path control transfers away).
;   Algorithm: OR A; RET Z on success. On failure load HL with BDOS_ERR_VECTORS and JP to the
;              indirect dispatcher (BDOS_VECTOR_JUMP), which reads a 16-bit handler address from the
;              table and jumps to it (the first entry = disk-I/O error).
; [RE] HL is set to the BDOS_ERR_VECTORS table (its first entry, the disk-I/O error handler) before
; the indirect dispatch through BDOS_VECTOR_JUMP.
; ----------------------------------------------------------------------
DISK_STATUS_CHECK:
        ; Test BIOS status: zero = success.
        OR A                             ; $9FBB  B7
        ; Success: return to the READ/WRITE wrapper's caller.
        RET Z                            ; $9FBC  C8
        ; Failure: point at the BDOS disk-error vector table (first entry).
        LD HL,BDOS_ERR_VECTORS                ; $9FBD  21 09 9C
        ; Dispatch indirectly through the error-vector table (does not return).
        JP BDOS_VECTOR_JUMP                    ; $9FC0  C3 4A 9F
; ----------------------------------------------------------------------
; REC_DIV4_SETUP -- divide the current record number by 4 and stage it as the target for the
; record->track/sector walk.
;   In: CUR_RECORD holds the current logical record number (read here as a 16-bit value).
;   Out: HL = CUR_RECORD >> 2; that value is stored into both CUR_BLOCK_NUMBER (the walk target) and the start
;        of REC_CACHE.
;   Clobbers: A, C, HL, F.
;   Algorithm: load HL from CUR_RECORD, set C = 2, call the logical-shift-right-by-C helper
;              (DRV_INSTALL_RWTS_10) to compute HL = HL >> 2, then save the result to CUR_BLOCK_NUMBER
;              (consumed by RECORD_TO_TRACK as the search target) and cache it at REC_CACHE.
; [RE] DRV_INSTALL_RWTS_10 verified as a 'shift HL logically right C times' helper (OR A clears
; carry, then RRA on H and L, C iterations); C=2 -> divide by 4. The exact meaning of the /4 is
; UNKNOWN; it is the quantity the subsequent track/sector resolver searches for.
; ----------------------------------------------------------------------
REC_DIV4_SETUP:
        ; HL = current logical record number (16-bit load).
        LD HL,(CUR_RECORD)                   ; $9FC3  2A EA A9
        ; Shift count = 2 (logical shift right by 2 = divide by 4).
        LD C,$02                         ; $9FC6  0E 02
        ; HL >>= 2 via the shift-right-by-C helper.
        CALL DRV_INSTALL_RWTS_10                    ; $9FC8  CD EA A0
        ; Store as the search target for the record->track/sector walk.
        LD (CUR_BLOCK_NUMBER),HL                   ; $9FCB  22 E5 A9
        ; Also cache the value at the start of REC_CACHE.
        LD (REC_CACHE),HL                   ; $9FCE  22 EC A9
; ----------------------------------------------------------------------
; RECORD_TO_TRACK -- entry of the loop that maps a logical record number to its physical track by
; stepping in sectors-per-track units.
;   In: CUR_BLOCK_NUMBER = 16-bit search target (record/4, set by REC_DIV4_SETUP); (DEBLOCK_HSTREC_PTR1) -> a 16-bit
;       running record-boundary accumulator; (DEBLOCK_HSTREC_PTR0) -> the current track number; DPB_SPT = SPT
;       (sectors per track, low word of the copied DPB).
;   Out: loads BC = target, DE = current boundary accumulator, HL = current track number, then
;        enters the search loop (RECORD_TO_TRACK_BACK). On a match it branches to
;        DISK_STORE_SEC_TRK_1, which sets the BIOS track/sector.
;   Clobbers: A, BC, DE, HL, F.
;   Algorithm: load the target into BC (via CUR_BLOCK_NUMBER), the boundary accumulator into DE (dereferenced
;              through (DEBLOCK_HSTREC_PTR1)), and the current track number into HL (dereferenced through
;              (DEBLOCK_HSTREC_PTR0)), then fall into the back/forward search that walks the accumulator by SPT
;              until the target record falls inside one track.
; [RE] DPB_SPT is the first word of the 15-byte DPB copied at $9F86 = SPT (sectors per track);
; MAX_BLOCK_DSM/$A9C6 is DSM at DPB offset 5, DPB_OFF is OFF at offset 13. The exit
; DISK_STORE_SEC_TRK_1 adds DPB_OFF (OFF) and calls the BIOS SETTRK vector ($AA1E), confirming the
; walked quantity is a track, not an allocation block.
; ----------------------------------------------------------------------
RECORD_TO_TRACK:
        ; HL -> the 16-bit search-target cell (record/4).
        LD HL,CUR_BLOCK_NUMBER                     ; $9FD1  21 E5 A9
        ; BC = search target (low byte then high).
        LD C,(HL)                        ; $9FD4  4E
        INC HL                           ; $9FD5  23
        LD B,(HL)                        ; $9FD6  46
        ; Dereference the boundary-accumulator pointer; load DE = current boundary.
        LD HL,(DEBLOCK_HSTREC_PTR1)                   ; $9FD7  2A B7 A9
        LD E,(HL)                        ; $9FDA  5E
        INC HL                           ; $9FDB  23
        LD D,(HL)                        ; $9FDC  56
        ; Dereference the track-number pointer; load HL = current track number.
        LD HL,(DEBLOCK_HSTREC_PTR0)                   ; $9FDD  2A B5 A9
        LD A,(HL)                        ; $9FE0  7E
        INC HL                           ; $9FE1  23
        LD H,(HL)                        ; $9FE2  66
        LD L,A                           ; $9FE3  6F
; ----------------------------------------------------------------------
; RECORD_TO_TRACK_BACK -- 'overshoot' branch: step the track number back while the boundary
; accumulator exceeds the target.
;   In: BC = target; DE = current boundary accumulator; HL = current track number; DPB_SPT = SPT
;       (sectors per track).
;   Out: loops, or when target >= accumulator falls into RECORD_TO_TRACK_FWD (forward branch).
;   Clobbers: A, DE, HL, F.
;   Algorithm: compute target - accumulator (BC - DE) via SUB E / SBC A,D; if no borrow (target >=
;              accumulator) branch forward to RECORD_TO_TRACK_FWD. Otherwise subtract one track's
;              worth of sectors (SPT in DPB_SPT) from DE and decrement the track number HL, then
;              repeat.
; [RE] The SUB E / SBC A,D pattern is a 16-bit compare of BC against DE through A; the borrow
; (carry-out) selects the direction. The subtraction of DPB_SPT from DE backs the boundary down by
; one track.
; ----------------------------------------------------------------------
RECORD_TO_TRACK_BACK:
        LD A,C                           ; $9FE4  79
        ; 16-bit compare: low byte of (target - accumulator).
        SUB E                            ; $9FE5  93
        LD A,B                           ; $9FE6  78
        ; ...high byte; borrow (carry set) means target < accumulator (overshot).
        SBC A,D                          ; $9FE7  9A
        ; target >= accumulator: switch to the forward search.
        JP NC,RECORD_TO_TRACK_FWD                 ; $9FE8  D2 FA 9F
        PUSH HL                          ; $9FEB  E5
        ; HL = SPT (sectors per track); back the boundary accumulator down by one track.
        LD HL,(DPB_SPT)                   ; $9FEC  2A C1 A9
        LD A,E                           ; $9FEF  7B
        SUB L                            ; $9FF0  95
        LD E,A                           ; $9FF1  5F
        LD A,D                           ; $9FF2  7A
        SBC A,H                          ; $9FF3  9C
        LD D,A                           ; $9FF4  57
        POP HL                           ; $9FF5  E1
        ; Step the track number down by one.
        DEC HL                           ; $9FF6  2B
        ; Repeat the overshoot test for the previous track.
        JP RECORD_TO_TRACK_BACK                    ; $9FF7  C3 E4 9F
; ----------------------------------------------------------------------
; RECORD_TO_TRACK_FWD -- 'forward' branch: step the track number ahead one track until the target
; record falls inside it.
;   In: BC = target; DE = boundary accumulator; HL = current track number; DPB_SPT = SPT (sectors per
;       track).
;   Out: when the target lies within the current track, branches to DISK_STORE_SEC_TRK_1 to set the
;        BIOS track and compute the sector within it; otherwise loops.
;   Clobbers: A, BC, DE, HL, F.
;   Algorithm: add one SPT (DPB_SPT) to the boundary DE; if that addition carries, the target is in
;              this track -> exit. Else compare the target (BC) against the new boundary; if the
;              boundary now exceeds the target, exit; otherwise commit the new boundary into DE,
;              advance the track number HL, and repeat.
; [RE] The two SUB L / SBC A,H comparisons test BC against the advanced boundary in HL; either
; carry-out routes to DISK_STORE_SEC_TRK_1, which sets the BIOS track via SETTRK ($AA1E).
; ----------------------------------------------------------------------
RECORD_TO_TRACK_FWD:
        PUSH HL                          ; $9FFA  E5
        ; HL = SPT (sectors per track).
        LD HL,(DPB_SPT)                   ; $9FFB  2A C1 A9
        ; Advance the boundary accumulator by one track's sectors.
        ADD HL,DE                        ; $9FFE  19
        ; Carry: target is inside this track -> resolve to track/sector.
        JP C,DISK_STORE_SEC_TRK_1                  ; $9FFF  DA 0F A0
        LD A,C                           ; $A002  79
        ; Compare target (BC) low byte against the advanced boundary.
        SUB L                            ; $A003  95
        LD A,B                           ; $A004  78
        ; ...high byte; carry means the boundary now passes the target -> done.
        SBC A,H                          ; $A005  9C
        ; Boundary now exceeds target: resolve this track to track/sector.
        JP C,DISK_STORE_SEC_TRK_1                  ; $A006  DA 0F A0
        ; Commit the advanced boundary into DE.
        EX DE,HL                         ; $A009  EB
        POP HL                           ; $A00A  E1
        ; Advance the track number forward.
        INC HL                           ; $A00B  23
        ; Repeat the forward search for the next track.
        JP RECORD_TO_TRACK_FWD                    ; $A00C  C3 FA 9F
; ----------------------------------------------------------------------
; BDOS_DEBLOCK_XFER_LOOP -- transfer a record span through the BIOS-bridge helper, then advance.
;   In: BC = record count, DE = record offset within the buffer span, HL on the stack;
;       DPB_OFF = a base address/pointer set from the selected-disk header (role UNKNOWN);
;       DEBLOCK_HSTREC_PTR0/DEBLOCK_HSTREC_PTR1 = pointer cells (set from the selected-disk header).
;   Out: DEBLOCK_HSTREC_PTR0 and DEBLOCK_HSTREC_PTR1 each updated to the value DE returned by the helper; BC = BC - DE.
;   Clobbers: A,BC,DE,HL.
;   Algorithm: pop the saved pointer, add the DPB_OFF base to DE to form the helper request in BC,
;       CALL the BIOS-bridge helper $AA1E; store its returned DE into both [DEBLOCK_HSTREC_PTR0] and [DEBLOCK_HSTREC_PTR1];
;       recompute BC = BC - DE; load the advance vector (DPB_XLT_PTR) into DE, CALL the advance helper
;       $AA30, then JP back into the bridge at $AA21.
;   [RE] part of the BDOS deblocking transfer path; the $AAxx targets are BIOS-bridge helpers above
;       this cluster. [?] transfer DIRECTION (read vs write) and the exact buffer/pointer semantics
;       UNKNOWN -- not determinable from these bytes alone.
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_1:
        POP HL                           ; $A00F  E1
        PUSH BC                          ; $A010  C5
        PUSH DE                          ; $A011  D5
        PUSH HL                          ; $A012  E5
        EX DE,HL                         ; $A013  EB
        ; add the DPB_OFF base (from the selected-disk header) to the record offset
        LD HL,(DPB_OFF)                   ; $A014  2A CE A9
        ADD HL,DE                        ; $A017  19
        LD B,H                           ; $A018  44
        LD C,L                           ; $A019  4D
        ; BIOS-bridge transfer helper for the assembled span
        CALL $AA1E                       ; $A01A  CD 1E AA
        POP DE                           ; $A01D  D1
        LD HL,(DEBLOCK_HSTREC_PTR0)                   ; $A01E  2A B5 A9
        LD (HL),E                        ; $A021  73
        INC HL                           ; $A022  23
        LD (HL),D                        ; $A023  72
        POP DE                           ; $A024  D1
        LD HL,(DEBLOCK_HSTREC_PTR1)                   ; $A025  2A B7 A9
        LD (HL),E                        ; $A028  73
        INC HL                           ; $A029  23
        LD (HL),D                        ; $A02A  72
        POP BC                           ; $A02B  C1
        LD A,C                           ; $A02C  79
        ; begin BC = BC - DE: records remaining after this span
        SUB E                            ; $A02D  93
        LD C,A                           ; $A02E  4F
        LD A,B                           ; $A02F  78
        SBC A,D                          ; $A030  9A
        LD B,A                           ; $A031  47
        LD HL,(DPB_XLT_PTR)                   ; $A032  2A D0 A9
        EX DE,HL                         ; $A035  EB
        ; BIOS-bridge advance helper for the next span
        CALL $AA30                       ; $A036  CD 30 AA
        LD C,L                           ; $A039  4D
        LD B,H                           ; $A03A  44
        ; re-enter the bridge to continue the transfer loop
        JP $AA21                         ; $A03B  C3 21 AA
; ----------------------------------------------------------------------
; FCB_RECORD_TO_BLOCKMAP_INDEX -- derive the FCB disk-map index for the current record/extent.
;   In: DPB_BSH = BSH (block-shift, records-per-block log2); FCB_CURREC = CR (current record, low half);
;       FCB_EXTENT_MASKED = the masked extent value ((FCB extent) AND EXM).
;   Out: A = the index (0..15) into the FCB allocation map for the block holding the current record.
;   Clobbers: A,B,C,HL.
;   Algorithm: C = BSH; rotate FCB_CURREC right BSH times (loop FCB_BLOCKMAP_INDEX_SHR) to drop the
;              within-block
;       record bits, keep the result in B; then C = 8 - BSH and rotate FCB_EXTENT_MASKED left (8-BSH) times
;       (loop FCB_BLOCKMAP_INDEX_SHL) to bring the extent bits up; finally ADD A,B at
;       DISK_STORE_SEC_TRK_9.
;   [RE] maps (record,extent) -> which d0..d15 entry of the FCB disk-allocation map; its output A is
;       used directly as the BC index into GET_ALLOC_BLOCK_ENTRY by DISK_STORE_SEC_TRK_14. [?] exact
;       bit packing partially inferred.
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_6:
        ; DPB_BSH = DPB block-shift factor (BSH), records-per-block log2
        LD HL,DPB_BSH                     ; $A03E  21 C3 A9
        LD C,(HL)                        ; $A041  4E
        LD A,(FCB_CURREC)                    ; $A042  3A E3 A9
FCB_BLOCKMAP_INDEX_SHR:
        OR A                             ; $A045  B7
        RRA                              ; $A046  1F
        DEC C                            ; $A047  0D
        JP NZ,FCB_BLOCKMAP_INDEX_SHR                 ; $A048  C2 45 A0
        LD B,A                           ; $A04B  47
        ; complement the shift: 8 - BSH
        LD A,$08                         ; $A04C  3E 08
        ; C = 8 - BSH = left-rotate count for the extent half
        SUB (HL)                         ; $A04E  96
        LD C,A                           ; $A04F  4F
        LD A,(FCB_EXTENT_MASKED)                    ; $A050  3A E2 A9
FCB_BLOCKMAP_INDEX_SHL:
        DEC C                            ; $A053  0D
        JP Z,DISK_STORE_SEC_TRK_9                  ; $A054  CA 5C A0
        OR A                             ; $A057  B7
        RLA                              ; $A058  17
        JP FCB_BLOCKMAP_INDEX_SHL                    ; $A059  C3 53 A0
; ----------------------------------------------------------------------
; FCB_BLOCKMAP_INDEX_MERGE -- tail of DISK_STORE_SEC_TRK_6: combine the two shifted halves.
;   In: A = the left-shifted extent half; B = the right-shifted record half.
;   Out: A = combined disk-map index (A + B).
;   Clobbers: A.
;   Algorithm: ADD A,B and return.
;   [RE] continuation/exit label of the index computation.
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_9:
        ; combine the extent and record halves into the disk-map index
        ADD A,B                          ; $A05C  80
        RET                              ; $A05D  C9
; ----------------------------------------------------------------------
; GET_ALLOC_BLOCK_ENTRY -- read a block number from the current FCB's disk-allocation map, indexed
; by BC.
;   In: BC = entry index; BDOS_PARAM_PTR = the current FCB pointer (the BDOS call's DE parameter);
;       BLOCK_WIDTH_FLAG selects 8-bit (nonzero) vs 16-bit (zero) map entries.
;   Out: HL = the indexed block number (zero-extended byte if 8-bit, else the full 16-bit word).
;   Clobbers: A,DE,HL.
;   Algorithm: HL = [BDOS_PARAM_PTR] + $0010 + BC (FCB+$10 = the d0..d15 disk-allocation map); if
;       BLOCK_WIDTH_FLAG==0 fall through to the word path (DISK_STORE_SEC_TRK_13), otherwise read
;       a single byte into L with H=0.
;   [RE] the DSM>255 vs <=255 entry-width branch (standard CP/M big/small-disk map handling).
;       FCB offset $10 is the on-disk allocation map. [?]
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_10:
        ; current FCB pointer (BDOS DE parameter)
        LD HL,(BDOS_PARAM_PTR)                   ; $A05E  2A 43 9F
        ; FCB+$10 = the disk-allocation map (d0..d15)
        LD DE,$0010                      ; $A061  11 10 00
        ADD HL,DE                        ; $A064  19
        ADD HL,BC                        ; $A065  09
        ; 0 = 16-bit map entries (big disk, DSM>255); nonzero = 8-bit
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A066  3A DD A9
        OR A                             ; $A069  B7
        JP Z,DISK_STORE_SEC_TRK_13                  ; $A06A  CA 71 A0
        ; 8-bit entry path: zero-extend the byte into HL
        LD L,(HL)                        ; $A06D  6E
        LD H,$00                         ; $A06E  26 00
        RET                              ; $A070  C9
; ----------------------------------------------------------------------
; GET_ALLOC_BLOCK_ENTRY_WORD -- 16-bit-entry tail of GET_ALLOC_BLOCK_ENTRY.
;   In: HL = FCB map base + index (one stride short of the word entry); BC = entry index.
;   Out: HL = the 16-bit block number fetched from the map.
;   Clobbers: DE,HL.
;   Algorithm: ADD HL,BC a second time (word stride), load low/high bytes into DE, EX DE,HL.
;   [RE] big-disk word-entry fetch.
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_13:
        ; second add: word-sized stride into the allocation map
        ADD HL,BC                        ; $A071  09
        LD E,(HL)                        ; $A072  5E
        INC HL                           ; $A073  23
        LD D,(HL)                        ; $A074  56
        EX DE,HL                         ; $A075  EB
        RET                              ; $A076  C9
; ----------------------------------------------------------------------
; FCB_GET_CURRENT_BLOCK -- look up the FCB allocation-map block number for the current
; record/extent.
;   In: the current FCB and the FCB_CURREC/FCB_EXTENT_MASKED position cells (set by DRV_INSTALL_RWTS_3).
;   Out: HL and CUR_BLOCK_NUMBER = the resolved block number from the FCB allocation map.
;   Clobbers: A,BC,DE,HL.
;   Algorithm: CALL DISK_STORE_SEC_TRK_6 to get the map index in A, move it to BC (C=A, B=0),
;       CALL GET_ALLOC_BLOCK_ENTRY to fetch the block number, then cache it in CUR_BLOCK_NUMBER.
;   [RE] composes the index computation and the map lookup to get the current block number. [?]
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_14:
        ; derive the allocation-map index for this record/extent
        CALL DISK_STORE_SEC_TRK_6                    ; $A077  CD 3E A0
        LD C,A                           ; $A07A  4F
        LD B,$00                         ; $A07B  06 00
        ; fetch the block number from the FCB allocation map
        CALL DISK_STORE_SEC_TRK_10                    ; $A07D  CD 5E A0
        ; cache the resolved block number
        LD (CUR_BLOCK_NUMBER),HL                   ; $A080  22 E5 A9
        RET                              ; $A083  C9
; ----------------------------------------------------------------------
; BLOCK_IS_ZERO -- test whether the cached block number (CUR_BLOCK_NUMBER) is zero (unallocated).
;   In: CUR_BLOCK_NUMBER = cached block number.
;   Out: HL = the block number; Z set if it is zero (no block allocated -- a hole).
;   Clobbers: A,HL.
;   Algorithm: load CUR_BLOCK_NUMBER; LD A,L / OR H to set Z when both halves are zero.
;   [RE] standard 'block 0 means unallocated' test.
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_16:
        LD HL,(CUR_BLOCK_NUMBER)                   ; $A084  2A E5 A9
        LD A,L                           ; $A087  7D
        ; Z set when the 16-bit block number is zero (unallocated)
        OR H                             ; $A088  B4
        RET                              ; $A089  C9
; ----------------------------------------------------------------------
; BLOCK_TO_FIRST_RECORD -- expand a block number into the absolute record number it maps to.
;   In: CUR_BLOCK_NUMBER = block number; DPB_BSH = BSH (records-per-block log2); DPB_BLM = BLM (block mask);
;       FCB_CURREC = CR (current record, low half).
;   Out: BLOCK_BASE_RECORD = block<<BSH (the block's base record); CUR_BLOCK_NUMBER = (block base) OR (CR AND BLM).
;   Clobbers: A,C,HL.
;   Algorithm: shift CUR_BLOCK_NUMBER left BSH times (loop BLOCK_TO_FIRST_RECORD_SHL) to get the block base
;              record, store
;       it in BLOCK_BASE_RECORD; then OR in the within-block record bits (FCB_CURREC AND DPB_BLM) and store the
;       full record number back into CUR_BLOCK_NUMBER.
;   [RE] canonical record = (block << BSH) | (record AND BLM). [?]
; ----------------------------------------------------------------------
DISK_STORE_SEC_TRK_17:
        ; BSH = number of left shifts (records-per-block log2)
        LD A,(DPB_BSH)                    ; $A08A  3A C3 A9
        LD HL,(CUR_BLOCK_NUMBER)                   ; $A08D  2A E5 A9
BLOCK_TO_FIRST_RECORD_SHL:
        ADD HL,HL                        ; $A090  29
        DEC A                            ; $A091  3D
        JP NZ,BLOCK_TO_FIRST_RECORD_SHL                 ; $A092  C2 90 A0
        ; save the block's base record number
        LD (BLOCK_BASE_RECORD),HL                   ; $A095  22 E7 A9
        ; BLM = block mask for the within-block record bits
        LD A,(DPB_BLM)                    ; $A098  3A C4 A9
        LD C,A                           ; $A09B  4F
        LD A,(FCB_CURREC)                    ; $A09C  3A E3 A9
        ; isolate the within-block record bits (CR AND BLM)
        AND C                            ; $A09F  A1
        ; merge the block base and the within-block offset
        OR L                             ; $A0A0  B5
        LD L,A                           ; $A0A1  6F
        LD (CUR_BLOCK_NUMBER),HL                   ; $A0A2  22 E5 A9
        RET                              ; $A0A5  C9
; ----------------------------------------------------------------------
; FCB_FIELD_PTR_0C -- point HL at offset $0C (the EX / extent field) of the current FCB.
;   In: BDOS_PARAM_PTR = current FCB pointer.
;   Out: HL = [BDOS_PARAM_PTR] + $000C (FCB+12 = EX, the current-extent byte).
;   Clobbers: DE,HL.
;   Algorithm: load the FCB base, add $000C.
;   [RE] accessor for FCB byte 12 (EX). [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_1:
        LD HL,(BDOS_PARAM_PTR)                   ; $A0A6  2A 43 9F
        ; FCB+$0C = the EX (current extent) field
        LD DE,$000C                      ; $A0A9  11 0C 00
        ADD HL,DE                        ; $A0AC  19
        RET                              ; $A0AD  C9
; ----------------------------------------------------------------------
; FCB_FIELD_PTRS_0F_20 -- compute pointers to FCB offsets $0F (RC) and $20 (CR).
;   In: BDOS_PARAM_PTR = current FCB pointer.
;   Out: DE = [BDOS_PARAM_PTR] + $0F (FCB+15 = RC, record count); HL = DE + $11 = [BDOS_PARAM_PTR] +
;        $20
;        (FCB+32 = CR, current record).
;   Clobbers: DE,HL.
;   Algorithm: HL = base + $0F, move to DE, HL = DE + $11.
;   [RE] paired accessor for the RC and CR FCB fields, used by DRV_INSTALL_RWTS_3/_6. [DOC CP/M 2.2
;   FCB]
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_2:
        LD HL,(BDOS_PARAM_PTR)                   ; $A0AE  2A 43 9F
        ; FCB+$0F = the RC (record count) field
        LD DE,$000F                      ; $A0B1  11 0F 00
        ADD HL,DE                        ; $A0B4  19
        EX DE,HL                         ; $A0B5  EB
        ; CR (FCB+$20) is $11 bytes past RC
        LD HL,$0011                      ; $A0B6  21 11 00
        ADD HL,DE                        ; $A0B9  19
        RET                              ; $A0BA  C9
; ----------------------------------------------------------------------
; LOAD_FCB_POSITION -- copy the current FCB's position fields into the BDOS scratch cells.
;   In: the current FCB (via DRV_INSTALL_RWTS_2 / _1); DPB_EXM = EXM (extent mask).
;   Out: FCB_CURREC = CR (FCB+$20); FCB_RECCOUNT = RC (FCB+$0F); FCB_EXTENT_MASKED = EX (FCB+$0C) AND EXM.
;   Clobbers: A,DE,HL.
;   Algorithm: via DRV_INSTALL_RWTS_2 read CR into FCB_CURREC and RC into FCB_RECCOUNT; via
;       DRV_INSTALL_RWTS_1 read EX, mask it with EXM (DPB_EXM), store in FCB_EXTENT_MASKED.
;   [RE] loads the file's current record / record-count / masked-extent into the deblock scratch
;   cells. [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_3:
        CALL DRV_INSTALL_RWTS_2                    ; $A0BB  CD AE A0
        LD A,(HL)                        ; $A0BE  7E
        ; stash CR (current record, FCB+$20)
        LD (FCB_CURREC),A                    ; $A0BF  32 E3 A9
        EX DE,HL                         ; $A0C2  EB
        LD A,(HL)                        ; $A0C3  7E
        ; stash RC (record count, FCB+$0F)
        LD (FCB_RECCOUNT),A                    ; $A0C4  32 E1 A9
        CALL DRV_INSTALL_RWTS_1                    ; $A0C7  CD A6 A0
        ; EXM (extent mask) applied to the EX byte
        LD A,(DPB_EXM)                    ; $A0CA  3A C5 A9
        AND (HL)                         ; $A0CD  A6
        ; store EX AND EXM (the in-extent bits)
        LD (FCB_EXTENT_MASKED),A                    ; $A0CE  32 E2 A9
        RET                              ; $A0D1  C9
; ----------------------------------------------------------------------
; STORE_FCB_POSITION -- write the (possibly adjusted) position values back into the current FCB.
;   In: WRITE_TYPE_FLAG (mode/adjust selector), FCB_CURREC, FCB_RECCOUNT scratch cells; the current FCB.
;   Out: FCB+$20 (CR) = FCB_CURREC + adjust; FCB+$0F (RC) = FCB_RECCOUNT.
;   Clobbers: A,C,DE,HL.
;   Algorithm: get the RC/CR pointers; if WRITE_TYPE_FLAG != 2 then C = WRITE_TYPE_FLAG else C = 0; write
;       (FCB_CURREC + C) into CR and FCB_RECCOUNT into RC.
;   [RE] inverse of LOAD_FCB_POSITION with a special case when WRITE_TYPE_FLAG == 2 (the adjustment is
;       zeroed). [?] meaning of the WRITE_TYPE_FLAG selector values UNKNOWN.
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_6:
        CALL DRV_INSTALL_RWTS_2                    ; $A0D2  CD AE A0
        ; mode/adjust selector; value 2 zeroes the adjustment
        LD A,(WRITE_TYPE_FLAG)                    ; $A0D5  3A D5 A9
        ; special-case selector value 2
        CP $02                           ; $A0D8  FE 02
        JP NZ,STORE_FCB_POSITION_2                 ; $A0DA  C2 DE A0
        XOR A                            ; $A0DD  AF
STORE_FCB_POSITION_2:
        LD C,A                           ; $A0DE  4F
        LD A,(FCB_CURREC)                    ; $A0DF  3A E3 A9
        ; apply the selector-dependent adjustment to CR
        ADD A,C                          ; $A0E2  81
        LD (HL),A                        ; $A0E3  77
        EX DE,HL                         ; $A0E4  EB
        LD A,(FCB_RECCOUNT)                    ; $A0E5  3A E1 A9
        LD (HL),A                        ; $A0E8  77
        RET                              ; $A0E9  C9
; ----------------------------------------------------------------------
; SHR_HL_C -- logical-shift HL right by C bit positions.
;   In: HL = value; C = shift count (0 leaves HL unchanged).
;   Out: HL >>= C (logical).
;   Clobbers: A,C,HL (C decremented to 0).
;   Algorithm: INC C / loop { DEC C; ret if zero; OR A to clear carry, RRA H, then RRA L feeding
;       H's carried-out bit 0 into L's top }.
;   [RE] generic unsigned right-shift helper used to scale block/drive-bit values.
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_10:
        INC C                            ; $A0EA  0C
SHR_HL_C_LOOP:
        DEC C                            ; $A0EB  0D
        RET Z                            ; $A0EC  C8
        LD A,H                           ; $A0ED  7C
        ; clear carry before the rotate (logical, not arithmetic, shift)
        OR A                             ; $A0EE  B7
        ; shift H right; its bit 0 is carried into L below
        RRA                              ; $A0EF  1F
        LD H,A                           ; $A0F0  67
        LD A,L                           ; $A0F1  7D
        RRA                              ; $A0F2  1F
        LD L,A                           ; $A0F3  6F
        JP SHR_HL_C_LOOP                    ; $A0F4  C3 EB A0
; ----------------------------------------------------------------------
; DIR_CHECKSUM -- compute the 128-byte additive checksum of the directory buffer.
;   In: DIRBUF_PTR -> 128-byte directory sector buffer.
;   Out: A = 8-bit sum of the 128 bytes.
;   Clobbers: A,C,HL.
;   Algorithm: C=$80 count, HL=DIRBUF_PTR, A=0; loop ADD A,(HL)/INC HL/DEC C until C==0.
;   [RE] canonical CP/M directory-checksum routine (detects media swap). [DOC CP/M 2.2 ALG]
; ----------------------------------------------------------------------
DIR_CHECKSUM:
        ; 128 bytes = one directory sector
        LD C,$80                         ; $A0F7  0E 80
        ; directory sector buffer base
        LD HL,(DIRBUF_PTR)                   ; $A0F9  2A B9 A9
        XOR A                            ; $A0FC  AF
DIR_CHECKSUM_LOOP:
        ; accumulate the 8-bit additive checksum
        ADD A,(HL)                       ; $A0FD  86
        INC HL                           ; $A0FE  23
        DEC C                            ; $A0FF  0D
        JP NZ,DIR_CHECKSUM_LOOP                 ; $A100  C2 FD A0
        RET                              ; $A103  C9
; ----------------------------------------------------------------------
; SHL_HL_C -- logical-shift HL left by C bit positions.
;   In: HL = value; C = shift count (0 leaves HL unchanged).
;   Out: HL <<= C.
;   Clobbers: C,HL (C decremented to 0).
;   Algorithm: INC C / loop { DEC C; ret if zero; ADD HL,HL }.
;   [RE] generic unsigned left-shift helper (e.g. building a 1<<n drive-bit mask).
; ----------------------------------------------------------------------
CMD_EXEC_11:
        INC C                            ; $A104  0C
SHL_HL_C_LOOP:
        DEC C                            ; $A105  0D
        RET Z                            ; $A106  C8
        ; one left shift of HL
        ADD HL,HL                        ; $A107  29
        JP SHL_HL_C_LOOP                    ; $A108  C3 05 A1
; ----------------------------------------------------------------------
; DRIVE_BIT_OR_INTO_VECTOR -- OR the current drive's single-bit mask into a 16-bit vector.
;   In: BC = the existing 16-bit vector (preserved across the call); BDOS_CUR_DRIVE = current drive
;       (0-based).
;       (HL on entry is IGNORED -- it is overwritten with $0001.)
;   Out: HL = BC OR (1 << current_drive).
;   Clobbers: A,HL (BC saved/restored).
;   Algorithm: PUSH BC; C = current drive; HL = 1; CALL SHL_HL_C to form 1<<drive; POP BC;
;       L = C OR L (low byte), H = B OR H (high byte).
;   [RE] sets the current drive's bit in whatever vector the caller passes in BC (used by both the
;       R/O vector and the login vector setters). [?]
; ----------------------------------------------------------------------
CMD_EXEC_12:
        PUSH BC                          ; $A10B  C5
        ; current drive number = bit position
        LD A,(BDOS_CUR_DRIVE)                    ; $A10C  3A 42 9F
        LD C,A                           ; $A10F  4F
        LD HL,$0001                      ; $A110  21 01 00
        ; HL = 1 << current_drive
        CALL CMD_EXEC_11                    ; $A113  CD 04 A1
        POP BC                           ; $A116  C1
        LD A,C                           ; $A117  79
        ; low byte: OR the existing vector (C) with the new drive bit
        OR L                             ; $A118  B5
        LD L,A                           ; $A119  6F
        LD A,B                           ; $A11A  78
        ; high byte: OR the existing vector (B) with the new drive bit
        OR H                             ; $A11B  B4
        LD H,A                           ; $A11C  67
        RET                              ; $A11D  C9
; ----------------------------------------------------------------------
; TEST_DRIVE_RO_BIT -- test whether the current drive's bit is set in the read-only drive vector.
;   In: the 16-bit R/O vector at $A9AD (NOTE: the var-page cell is mislabeled DRV_LOGIN_VECTOR;
;       it is the read-only vector set by the Write-Protect-Disk handler DRV_SETRO_H);
;       BDOS_CUR_DRIVE = drive.
;   Out: A = 1 if the current drive's R/O bit is set, else 0; Z reflects the result.
;   Clobbers: A,C,HL.
;   Algorithm: load the vector, SHR_HL_C by the drive number to bring its bit to bit 0, AND $01.
;   [RE] CMD_EXEC_20 (CHECK_DRIVE_READONLY) uses this and raises the R/O error when the bit is set,
;       which proves this vector is the read-only vector, not the login vector. [?] cell-name fix
;       deferred.
; ----------------------------------------------------------------------
DRIVE_BIT_TEST:
        ; the read-only drive vector (cell mislabeled DRV_LOGIN_VECTOR)
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A11E  2A AD A9
        LD A,(BDOS_CUR_DRIVE)                    ; $A121  3A 42 9F
        LD C,A                           ; $A124  4F
        ; shift the wanted drive's bit down to bit 0
        CALL DRV_INSTALL_RWTS_10                    ; $A125  CD EA A0
        LD A,L                           ; $A128  7D
        ; isolate the current drive's R/O bit
        AND $01                          ; $A129  E6 01
        RET                              ; $A12B  C9
; ----------------------------------------------------------------------
; SET_DRIVE_READONLY -- BDOS function 28 (Write Protect Disk): set the current drive's R/O bit.
;   In: the R/O drive vector at $A9AD (cell mislabeled DRV_LOGIN_VECTOR); BDOS_CUR_DRIVE = current
;       drive;
;       DPB_REC_PTR (a directory record-count limit); DPB_WORK_PTR0 -> a 16-bit working cell.
;   Out: the R/O vector has the current drive's bit set; the word at [DPB_WORK_PTR0] = DPB_REC_PTR +
;        1.
;   Clobbers: A,BC,DE,HL.
;   Algorithm: load the R/O vector into BC, set the current-drive bit via DRIVE_BIT_OR_INTO_VECTOR,
;       store it back; then store (DPB_REC_PTR + 1) into the 16-bit cell pointed to by
;       DPB_WORK_PTR0.
;   [RE] this label is the fn-28 entry in the dispatch table at $9C7F, confirming
;   Write-Protect-Disk;
;       the existing label DRV_SETRO_H ('set read-only') agrees. [?] purpose of caching
;       DPB_REC_PTR+1 UNKNOWN.
; ----------------------------------------------------------------------
DRV_SETRO_H:
        LD HL,DRV_LOGIN_VECTOR                     ; $A12C  21 AD A9
        LD C,(HL)                        ; $A12F  4E
        INC HL                           ; $A130  23
        LD B,(HL)                        ; $A131  46
        ; set the current drive's bit in the R/O vector
        CALL CMD_EXEC_12                    ; $A132  CD 0B A1
        ; store the updated R/O vector (cell mislabeled DRV_LOGIN_VECTOR)
        LD (DRV_LOGIN_VECTOR),HL                   ; $A135  22 AD A9
        ; directory record-count limit for this drive
        LD HL,(DPB_REC_PTR)                   ; $A138  2A C8 A9
        INC HL                           ; $A13B  23
        EX DE,HL                         ; $A13C  EB
        LD HL,(DPB_WORK_PTR0)                   ; $A13D  2A B3 A9
        LD (HL),E                        ; $A140  73
        INC HL                           ; $A141  23
        ; save (DPB_REC_PTR + 1) into the cell at [DPB_WORK_PTR0]
        LD (HL),D                        ; $A142  72
        RET                              ; $A143  C9
; ----------------------------------------------------------------------
; CHECK_DIRENT_READONLY -- raise the file-R/O error if the matched directory entry is read-only.
;   In: DIRBUF_PTR / DEBLOCK_BYTE_OFF locate the matched directory entry (via
;       FCB_BUF_PTR_ADD_OFFSET).
;   Out: returns normally if writable; otherwise jumps to the BDOS error vector (no return).
;   Clobbers: A,DE,HL.
;   Algorithm: point at the entry, advance to byte +9 (the first type byte t1', whose bit 7 is the
;       R/O attribute), RLA to shift bit 7 into carry; RET NC if clear, else load the file-R/O
;       error vector (BDOS_ERRVEC_FILERO at $9C0F) and dispatch via BDOS_VECTOR_JUMP.
;   [RE] CP/M file R/O attribute = bit 7 of directory-entry byte 9 (t1'). [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
FCB_RO_FLAG_TEST:
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A144  CD 5E A1
CHECK_DIRENT_READONLY_INNER:
        ; offset to dir-entry byte 9 (t1'; bit 7 = R/O attribute)
        LD DE,$0009                      ; $A147  11 09 00
        ADD HL,DE                        ; $A14A  19
        LD A,(HL)                        ; $A14B  7E
        ; shift attribute bit 7 into carry
        RLA                              ; $A14C  17
        ; carry clear: entry is writable, continue
        RET NC                           ; $A14D  D0
        ; file-read-only error vector ($9C0F)
        LD HL,BDOS_ERRVEC_FILERO                ; $A14E  21 0F 9C
        JP BDOS_VECTOR_JUMP                    ; $A151  C3 4A 9F
; ----------------------------------------------------------------------
; CHECK_DRIVE_READONLY -- raise the disk-R/O error if the current drive is write-protected.
;   In: the current drive context (DRIVE_BIT_TEST reads the R/O drive vector).
;   Out: returns if writable; otherwise jumps to the BDOS error vector (no return).
;   Clobbers: A,C,HL.
;   Algorithm: CALL DRIVE_BIT_TEST (current drive's R/O bit); RET Z if clear (writable), else load
;       the disk-R/O error vector (BDOS_ERRVEC_RODISK at $9C0D) and dispatch via BDOS_VECTOR_JUMP.
;   [RE] guards writes against a write-protected disk. [?]
; ----------------------------------------------------------------------
CMD_EXEC_20:
        ; test the current drive's read-only bit
        CALL DRIVE_BIT_TEST                    ; $A154  CD 1E A1
        ; writable: nothing to raise
        RET Z                            ; $A157  C8
        ; disk-read-only error vector ($9C0D)
        LD HL,BDOS_ERRVEC_RODISK                ; $A158  21 0D 9C
        JP BDOS_VECTOR_JUMP                    ; $A15B  C3 4A 9F
; ----------------------------------------------------------------------
; DIRENT_PTR -- compute a pointer to the matched directory entry inside the directory buffer.
;   In: DIRBUF_PTR -> directory sector buffer; DEBLOCK_BYTE_OFF = byte offset of the entry.
;   Out: HL = DIRBUF_PTR + DEBLOCK_BYTE_OFF.
;   Clobbers: A,HL.
;   Algorithm: load the buffer base, load the 8-bit entry offset, add it to L with carry into H
;              (DIRENT_PTR_ADD).
;   [RE] locates the directory entry just matched by a BDOS directory search. [?]
; ----------------------------------------------------------------------
FCB_BUF_PTR_ADD_OFFSET:
        ; directory sector buffer base
        LD HL,(DIRBUF_PTR)                   ; $A15E  2A B9 A9
        ; byte offset of the matched entry within the buffer
        LD A,(DEBLOCK_BYTE_OFF)                    ; $A161  3A E9 A9
DIRENT_PTR_ADD:
        ADD A,L                          ; $A164  85
        LD L,A                           ; $A165  6F
        RET NC                           ; $A166  D0
        INC H                            ; $A167  24
        RET                              ; $A168  C9
; ----------------------------------------------------------------------
; GET_FCB_S2_PTR -- point HL at FCB byte 14 (the S2 / extent-high field) of the current FCB.
;   In: BDOS_PARAM_PTR = current FCB pointer.
;   Out: HL = [BDOS_PARAM_PTR] + $000E (FCB+14, the S2 byte); A = its current value.
;   Clobbers: A,DE,HL.
;   Algorithm: HL = base + $0E, read (HL) into A.
;   [RE] FCB byte 14 = S2 (extent-high / module count) per CP/M 2.2 FCB layout. [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
FCB_GET_S2:
        LD HL,(BDOS_PARAM_PTR)                   ; $A169  2A 43 9F
        ; offset to FCB byte 14 (the S2 field)
        LD DE,$000E                      ; $A16C  11 0E 00
        ADD HL,DE                        ; $A16F  19
        LD A,(HL)                        ; $A170  7E
        RET                              ; $A171  C9
; ----------------------------------------------------------------------
; CLEAR_FCB_S2 -- zero the S2 (byte 14) field of the current FCB.
;   In: the current FCB (via GET_FCB_S2_PTR).
;   Out: FCB byte 14 = 0.
;   Clobbers: A,DE,HL.
;   Algorithm: get the S2 pointer, store 0.
;   [RE] resets the extent-high/S2 field. [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
CLEAR_FCB_S2:
        CALL FCB_GET_S2                    ; $A172  CD 69 A1
        ; clear the FCB S2 field
        LD (HL),$00                      ; $A175  36 00
        RET                              ; $A177  C9
; ----------------------------------------------------------------------
; MARK_FCB_S2_HIGHBIT -- set bit 7 of the FCB S2 (byte 14) field.
;   In: the current FCB (via GET_FCB_S2_PTR, which also returns A = the current S2 value).
;   Out: FCB byte 14 |= $80.
;   Clobbers: A,DE,HL.
;   Algorithm: get the S2 pointer (A = current S2), OR $80, store back.
;   [RE] in CP/M 2.2 the high bit of S2 flags the FCB as written/needing a directory update at
;   close. [DOC CP/M 2.2 FCB]
; ----------------------------------------------------------------------
MARK_FCB_S2_HIGHBIT:
        CALL FCB_GET_S2                    ; $A178  CD 69 A1
        ; set S2 bit 7 (the write/close flag)
        OR $80                           ; $A17B  F6 80
        LD (HL),A                        ; $A17D  77
        RET                              ; $A17E  C9
; ----------------------------------------------------------------------
; CMP_CURREC_VS_WORKPTR -- compare the current record number against the working record cell.
;   In: CUR_RECORD = 16-bit current record; DPB_WORK_PTR0 -> a 16-bit working record value.
;   Out: HL = address of the working value's high byte; flags = (CUR_RECORD - working value);
;        CARRY SET when CUR_RECORD < the working value (i.e. no extension needed).
;   Clobbers: A,DE,HL.
;   Algorithm: DE = CUR_RECORD, HL = (DPB_WORK_PTR0); subtract low byte (SUB), then high byte (SBC),
;       leaving HL pointing at the high byte; no value is stored.
;   [RE] RECPTR_INC_STORE uses this: on NC (CUR_RECORD >= working) it bumps and stores CUR_RECORD+1,
;       extending the high-water record count. [?]
; ----------------------------------------------------------------------
CMP_CURREC_VS_WORKPTR:
        ; current logical record number
        LD HL,(CUR_RECORD)                   ; $A17F  2A EA A9
        EX DE,HL                         ; $A182  EB
        ; pointer to the working record-count value
        LD HL,(DPB_WORK_PTR0)                   ; $A183  2A B3 A9
        LD A,E                           ; $A186  7B
        SUB (HL)                         ; $A187  96
        INC HL                           ; $A188  23
        LD A,D                           ; $A189  7A
        ; 16-bit compare; carry => current record is BELOW the stored value
        SBC A,(HL)                       ; $A18A  9E
        RET                              ; $A18B  C9
; ----------------------------------------------------------------------
; RECPTR_INC_STORE -- If the current record is at or past the stored high-water count, bump the
; count to one past it.
;   In: CUR_RECORD = the record number just processed; DPB_WORK_PTR0 holds a pointer to a 16-bit
;       record-count cell.
;   Out: If CUR_RECORD >= (count cell), the cell is set to CUR_RECORD+1. Otherwise unchanged. DE =
;        CUR_RECORD (then +1 if updated); HL left pointing into the count cell.
;   Clobbers: A, DE, HL, flags.
;   Algorithm: Call CMP_CURREC_VS_WORKPTR, which computes CUR_RECORD - (count cell) and leaves DE =
;              CUR_RECORD, HL -> the cell's high byte. RET C (carry = borrow = CUR_RECORD < count,
;              so the stored count is already larger -> leave it). Otherwise DE := CUR_RECORD+1 and
;              write it back HIGH byte first (LD (HL),D), DEC HL, then LOW byte (LD (HL),E).
;   [RE] Classic CP/M 2.2 BDOS extent record-count bump; keeps the FCB's high-water record one past
;   the last accessed.
; ----------------------------------------------------------------------
RECPTR_INC_STORE:
        ; compute CUR_RECORD - (count cell); carry => CUR_RECORD below the stored count; leaves HL
        ; -> cell high byte, DE = CUR_RECORD
        CALL CMP_CURREC_VS_WORKPTR                    ; $A18C  CD 7F A1
        ; CUR_RECORD < stored count -- count is already ahead, nothing to advance
        RET C                            ; $A18F  D8
        ; DE = CUR_RECORD + 1 (one past the record just used)
        INC DE                           ; $A190  13
        ; HL points at the count cell high byte (left there by CMP_CURREC_VS_WORKPTR); write new
        ; high byte
        LD (HL),D                        ; $A191  72
        ; step back to the count cell low byte
        DEC HL                           ; $A192  2B
        ; write new count low byte
        LD (HL),E                        ; $A193  73
        RET                              ; $A194  C9
; ----------------------------------------------------------------------
; SUB16_DE_HL -- 16-bit subtract HL := DE - HL.
;   In: DE = minuend, HL = subtrahend.
;   Out: HL = DE - HL; carry set on borrow (DE < HL unsigned). A holds the high-byte result.
;   Clobbers: A, HL, flags. DE preserved.
;   Algorithm: Subtract low bytes (E - L) -> L, then high bytes with borrow (D - H) -> H.
;   [RE] General BDOS 16-bit compare/difference helper used by the record scan and seek logic.
; ----------------------------------------------------------------------
SUB16_DE_HL:
        LD A,E                           ; $A195  7B
        ; low byte: E - L
        SUB L                            ; $A196  95
        ; store low result
        LD L,A                           ; $A197  6F
        LD A,D                           ; $A198  7A
        ; high byte: D - H with borrow; carry out = unsigned borrow
        SBC A,H                          ; $A199  9C
        ; store high result; HL = DE - HL
        LD H,A                           ; $A19A  67
        RET                              ; $A19B  C9
; ----------------------------------------------------------------------
; RECORD_SCAN_INIT -- Enter the directory-record scan in store mode (write A into the located byte
; rather than compare it).
;   In: see RECORD_SCAN_BODY.
;   Out: see RECORD_SCAN_BODY.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: Set C = $FF so the INC C inside RECORD_SCAN_BODY wraps to 0 (Z) and takes the store
;              branch (FCB_STORE_A_ORPHAN), then fall through into RECORD_SCAN_BODY.
;   [RE] Thin mode-selecting entry to the shared directory-record scan.
; ----------------------------------------------------------------------
RECORD_SCAN_INIT:
        ; C=$FF -> INC C in scan body wraps to 0 (Z) -> take the store branch
        LD C,$FF                         ; $A19C  0E FF
; ----------------------------------------------------------------------
; RECORD_SCAN_BODY -- Scan to the target byte in the cached directory record, then either store A
; there or compare A against it.
;   In: C = mode (INC C wraps to 0 => store mode, else compare mode); REC_CACHE = cached record
;       cursor; REC_SCAN_PTR = scan limit; REC_BYTE_OFFSET = byte offset within the record; A = byte
;       to store/compare; DIRBUF (via DIRBUF_PTR) holds the loaded directory record.
;   Out: store mode writes A and returns via FCB_STORE_A_ORPHAN. Compare mode: returns Z on a match;
;        if no match and CUR_RECORD is past the stored count it flags the drive read-only
;        (DRV_SETRO_H). If REC_CACHE - REC_SCAN_PTR did not borrow, returns NC (nothing to do).
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: DE := REC_CACHE, HL := REC_SCAN_PTR; SUB16_DE_HL (HL = REC_CACHE - REC_SCAN_PTR); RET
;              NC if no borrow. Else checksum the directory buffer (DIR_CHECKSUM), add REC_BYTE_OFFSET
;              to REC_CACHE to address the target byte. INC C: if it wrapped to 0, store A there.
;              Otherwise CP (HL); RET Z on match. On mismatch CMP_CURREC_VS_WORKPTR; RET NC if
;              within the record count, else DRV_SETRO_H.
;   [RE] Heart of the directory record scan/checksum loop in the BDOS deblocking layer.
; ----------------------------------------------------------------------
RECORD_SCAN_BODY:
        ; DE := cached record cursor (after the following EX DE,HL)
        LD HL,(REC_CACHE)                   ; $A19E  2A EC A9
        EX DE,HL                         ; $A1A1  EB
        ; HL := scan limit pointer
        LD HL,(REC_SCAN_PTR)                   ; $A1A2  2A CC A9
        ; HL = REC_CACHE - REC_SCAN_PTR; carry (borrow) => still in range
        CALL SUB16_DE_HL                    ; $A1A5  CD 95 A1
        ; no borrow (cursor at/past limit) -> return, caller sees not-found
        RET NC                           ; $A1A8  D0
        PUSH BC                          ; $A1A9  C5
        ; sum the 128-byte directory buffer (DIRBUF) -- the change-detect checksum
        CALL DIR_CHECKSUM                    ; $A1AA  CD F7 A0
        ; DE := byte offset within the record (after the following EX DE,HL)
        LD HL,(REC_BYTE_OFFSET)                   ; $A1AD  2A BD A9
        EX DE,HL                         ; $A1B0  EB
        LD HL,(REC_CACHE)                   ; $A1B1  2A EC A9
        ; HL -> the target byte inside the cached record
        ADD HL,DE                        ; $A1B4  19
        POP BC                           ; $A1B5  C1
        ; advance mode; if it wraps to 0 this is store mode
        INC C                            ; $A1B6  0C
        ; store mode: write A into the directory byte and return
        JP Z,FCB_STORE_A_ORPHAN                  ; $A1B7  CA C4 A1
        ; compare mode: compare A with the directory byte
        CP (HL)                          ; $A1BA  BE
        ; match found -> return Z
        RET Z                            ; $A1BB  C8
        ; no match: is CUR_RECORD within the stored record count?
        CALL CMP_CURREC_VS_WORKPTR                    ; $A1BC  CD 7F A1
        ; within the record count -> just return
        RET NC                           ; $A1BF  D0
        ; past end with a mismatch -> set the drive read-only (protect)
        CALL DRV_SETRO_H                    ; $A1C0  CD 2C A1
        RET                              ; $A1C3  C9
; ----------------------------------------------------------------------
; FCB_STORE_A_ORPHAN -- Store the accumulator into the directory byte addressed by HL (scan
; store-mode tail).
;   In: HL -> target directory byte; A = value to store.
;   Out: (HL) = A.
;   Clobbers: nothing (memory only).
;   Algorithm: LD (HL),A; RET.
;   [RE] Store-mode terminator branched to from RECORD_SCAN_BODY when INC C wrapped to 0.
; ----------------------------------------------------------------------
FCB_STORE_A_ORPHAN:
        ; write the byte into the directory record
        LD (HL),A                        ; $A1C4  77
        RET                              ; $A1C5  C9
; ----------------------------------------------------------------------
; DIR_RECORD_WRITE -- Checksum-verify then write the directory buffer to disk as a record, and
; refresh the user buffer.
;   In: directory buffer (DIRBUF) and the BDOS deblock state set up by the caller.
;   Out: the record is written to disk (with the R/O-on-tamper check); user DMA restored; errors
;        raised via DISK_WRITE_CHECKED.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: RECORD_SCAN_INIT runs the scan in store mode (re-checksums the directory buffer and
;              sets the drive R/O on a tamper mismatch). SET_DMA_TO_DISK_BUF aims the BIOS DMA at
;              DIRBUF; C=1 selects the directory write type; DISK_WRITE_CHECKED issues the BIOS
;              WRITE and raises on error; JP RESTORE_USER_DMA restores the user DMA.
;   [RE] Directory-record write path; C=1 is the CP/M deblock directory-write code (BIOS WRITE
;   vector $AA2A).
; ----------------------------------------------------------------------
DIR_RECORD_WRITE:
        ; re-checksum the directory buffer / set R/O on a tamper mismatch before writing
        CALL RECORD_SCAN_INIT                    ; $A1C6  CD 9C A1
        ; point BIOS DMA at the directory buffer (DIRBUF)
        CALL SET_DMA_TO_DISK_BUF                    ; $A1C9  CD E0 A1
        ; deblock write type 1 = directory write
        LD C,$01                         ; $A1CC  0E 01
        ; BIOS sector WRITE ($AA2A) + raise on error
        CALL DISK_WRITE_CHECKED                    ; $A1CE  CD B8 9F
        ; restore the user DMA address and return
        JP RESTORE_USER_DMA                      ; $A1D1  C3 DA A1
; ----------------------------------------------------------------------
; DIR_RECORD_READ -- Read a directory record from disk into the directory buffer, then restore the
; user DMA.
;   In: BDOS deblock state set up by the caller.
;   Out: DIRBUF filled from disk; user DMA restored; errors raised via DISK_READ_CHECKED.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: SET_DMA_TO_DISK_BUF (aim BIOS DMA at DIRBUF), DISK_READ_CHECKED (BIOS READ vector
;              $AA27 + error check), then fall through into RESTORE_USER_DMA to restore the user DMA
;              address.
;   [RE] Directory-record read path; pairs with DIR_RECORD_WRITE.
; ----------------------------------------------------------------------
DIR_RECORD_READ:
        ; point BIOS DMA at the directory buffer (DIRBUF)
        CALL SET_DMA_TO_DISK_BUF                    ; $A1D4  CD E0 A1
        ; BIOS sector READ ($AA27) + raise on error
        CALL DISK_READ_CHECKED                    ; $A1D7  CD B2 9F
; ----------------------------------------------------------------------
; RESTORE_USER_DMA -- Restore the BIOS DMA address to the user's DMA buffer.
;   In: DMA_ADDR cell holds the user DMA address.
;   Out: BIOS DMA set to (DMA_ADDR) via the BIOS SETDMA vector.
;   Clobbers: BC, HL, flags.
;   Algorithm: HL := address of the DMA_ADDR cell, then JP SET_DMA_FROM_CELL which loads BC from the
;              cell and jumps to the BIOS SETDMA vector ($AA24).
;   [RE] Used after directory I/O to put DMA back to the application buffer.
; ----------------------------------------------------------------------
RESTORE_USER_DMA:
        ; HL -> the saved user DMA address cell
        LD HL,DMA_ADDR                     ; $A1DA  21 B1 A9
        ; load BC from the cell and call BIOS SETDMA
        JP SET_DMA_FROM_CELL                    ; $A1DD  C3 E3 A1
; ----------------------------------------------------------------------
; SET_DMA_TO_DISK_BUF -- Point the BIOS DMA at the directory/disk buffer (DIRBUF).
;   In: DIRBUF_PTR cell holds the directory buffer address.
;   Out: BIOS DMA set to (DIRBUF_PTR) via the BIOS SETDMA vector.
;   Clobbers: BC, HL, flags.
;   Algorithm: HL := address of the DIRBUF_PTR cell, fall into SET_DMA_FROM_CELL: load BC from (HL)
;              and jump to the BIOS SETDMA vector ($AA24).
;   [RE] Companion to RESTORE_USER_DMA; aims I/O at the OS directory buffer.
; ----------------------------------------------------------------------
SET_DMA_TO_DISK_BUF:
        ; HL -> the directory buffer pointer cell
        LD HL,DIRBUF_PTR                     ; $A1E0  21 B9 A9
; ----------------------------------------------------------------------
; SET_DMA_FROM_CELL -- Load a DMA address from a 16-bit cell and hand it to the BIOS SETDMA vector.
;   In: HL -> a 2-byte little-endian DMA address cell.
;   Out: BIOS DMA set to (HL); tail-jumps into the BIOS SETDMA jump vector at $AA24.
;   Clobbers: BC, HL.
;   Algorithm: C := (HL), INC HL, B := (HL) so BC = the 16-bit address; JP $AA24 (BIOS SETDMA entry
;              in the BDOS->BIOS jump-vector page).
;   [RE] Shared tail of SET_DMA_TO_DISK_BUF and RESTORE_USER_DMA. $AA24 is the BIOS SETDMA jump cell
;   (13th jump-table entry).
; ----------------------------------------------------------------------
SET_DMA_FROM_CELL:
        ; BC low byte := DMA address low from the cell
        LD C,(HL)                        ; $A1E3  4E
        INC HL                           ; $A1E4  23
        ; BC high byte := DMA address high (HL advanced by the preceding INC HL)
        LD B,(HL)                        ; $A1E5  46
        ; tail-jump to the BIOS SETDMA jump vector
        JP $AA24                         ; $A1E6  C3 24 AA
; ----------------------------------------------------------------------
; DISK_BUF_MOVE -- Copy the 128-byte directory buffer into the user DMA buffer.
;   In: DIRBUF_PTR -> source (directory buffer); DMA_ADDR -> destination (user DMA).
;   Out: 128 bytes copied DIRBUF -> user DMA.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: DE := (DIRBUF_PTR) source, HL := (DMA_ADDR) destination, C := $80 (128), JP
;              BLOCK_COPY_INCC (the byte-copy loop moving C bytes from DE to HL).
;   [RE] Deblock read-back: surfaces a directory-sector record to the application buffer.
; ----------------------------------------------------------------------
DISK_BUF_MOVE:
        ; DE := directory buffer source (after the following EX DE,HL)
        LD HL,(DIRBUF_PTR)                   ; $A1E9  2A B9 A9
        EX DE,HL                         ; $A1EC  EB
        ; HL := user DMA buffer (copy destination)
        LD HL,(DMA_ADDR)                   ; $A1ED  2A B1 A9
        ; 128 bytes = one CP/M record
        LD C,$80                         ; $A1F0  0E 80
        ; tail-call the C-byte memory copy loop (DE->HL)
        JP BLOCK_COPY_INCC                      ; $A1F2  C3 4F 9F
; ----------------------------------------------------------------------
; CUR_RECORD_BYTES_EQUAL -- Test whether the low and high bytes of the 16-bit CUR_RECORD cell are
; equal.
;   In: CUR_RECORD = a 16-bit cell ($A9EA low, $A9EB high).
;   Out: If the two bytes differ, returns NZ with A = the low byte unchanged. If they are equal,
;        returns A = low byte + 1 (and Z cleared by the INC).
;   Clobbers: A, HL, flags.
;   Algorithm: HL -> CUR_RECORD low byte; A := (HL); INC HL (-> high byte); CP (HL); RET NZ if they
;              differ; else INC A and RET.
;   [RE] Deblock helper that compares the two halves of CUR_RECORD; called widely across the BDOS
;   read/write deblock paths. The exact role of the equal/INC result is UNKNOWN from these bytes
;   alone (the callers consume A/the Z flag).
; ----------------------------------------------------------------------
CUR_RECORD_BYTES_EQUAL:
        ; HL -> CUR_RECORD low byte ($A9EA)
        LD HL,CUR_RECORD                     ; $A1F5  21 EA A9
        ; A := CUR_RECORD low byte
        LD A,(HL)                        ; $A1F8  7E
        INC HL                           ; $A1F9  23
        ; compare low byte against the high byte (HL advanced by the preceding INC HL)
        CP (HL)                          ; $A1FA  BE
        ; bytes differ -> return NZ, A = low byte
        RET NZ                           ; $A1FB  C0
        ; bytes equal -> A = low byte + 1 (also clears Z)
        INC A                            ; $A1FC  3C
        RET                              ; $A1FD  C9
; ----------------------------------------------------------------------
; INVALIDATE_CUR_RECORD -- Mark the cached record pointer invalid (CUR_RECORD := $FFFF).
;   In: none.
;   Out: CUR_RECORD cell = $FFFF.
;   Clobbers: HL.
;   Algorithm: HL := $FFFF; store to CUR_RECORD; RET.
;   [RE] Forces the next deblock access to reload, since $FFFF can never equal a real record number.
; ----------------------------------------------------------------------
INVALIDATE_CUR_RECORD:
        ; sentinel: no record cached
        LD HL,$FFFF                      ; $A1FE  21 FF FF
        ; invalidate the cached current-record value
        LD (CUR_RECORD),HL                   ; $A201  22 EA A9
        RET                              ; $A204  C9
; ----------------------------------------------------------------------
; DIR_READ_NEXT -- Advance the directory record pointer and read the next directory record.
;   In: CUR_RECORD = last directory record index processed; DPB_REC_PTR = total directory records on
;       this drive.
;   Out: CY/A set per DIR_RECORD_DEBLOCK if a record remains; CUR_RECORD invalidated ($FFFF) when
;        the directory is exhausted.
;   Clobbers: A, DE, HL, flags.
;   Algorithm: increment CUR_RECORD; if it has not passed the directory record count (DPB_REC_PTR)
;              fall through to DIR_RECORD_DEBLOCK to position on the next 32-byte entry, else mark
;              end-of-directory via DIR_INVALIDATE_RECORD.
; [RE] Canonical CP/M 2.2 BDOS read-next-directory-entry sequencer.
; ----------------------------------------------------------------------
CMD_EXEC_53:
        ; DE = number of directory records on the selected drive (from the DPB).
        LD HL,(DPB_REC_PTR)                   ; $A205  2A C8 A9
        EX DE,HL                         ; $A208  EB
        LD HL,(CUR_RECORD)                   ; $A209  2A EA A9
        ; Step to the next directory record index.
        INC HL                           ; $A20C  23
        LD (CUR_RECORD),HL                   ; $A20D  22 EA A9
        ; Compare CUR_RECORD against the directory record count.
        CALL SUB16_DE_HL                    ; $A210  CD 95 A1
        ; Records remain: deblock and read the next directory record.
        JP NC,CMD_EXEC_54                 ; $A213  D2 19 A2
        ; Directory exhausted: invalidate CUR_RECORD and return end-of-directory.
        JP INVALIDATE_CUR_RECORD                      ; $A216  C3 FE A1
; ----------------------------------------------------------------------
; DIR_RECORD_DEBLOCK -- Position on the current 32-byte directory entry within its 128-byte record,
; reading the record from disk on a record boundary.
;   In: CUR_RECORD = current directory record index.
;   Out: DEBLOCK_BYTE_OFF = byte offset (0/32/64/96) of this entry inside the directory buffer; on a
;        fresh record the directory record has been read into the disk buffer.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: entries-per-record offset = (CUR_RECORD & 3) << 5; store it; if the offset is
;              non-zero the entry is already in the buffer so return; on a record boundary (offset
;              0) compute the absolute disk record and read it into the directory buffer.
; [RE] CP/M packs four 32-byte directory entries per 128-byte record; this is the BDOS deblocking
; step.
; ----------------------------------------------------------------------
CMD_EXEC_54:
        LD A,(CUR_RECORD)                    ; $A219  3A EA A9
        ; Index of this entry within its 4-entry directory record.
        AND $03                          ; $A21C  E6 03
        ; Shift count: multiply by 32 to get the byte offset of the entry.
        LD B,$05                         ; $A21E  06 05
DIR_DEBLOCK_SHIFT:
        ADD A,A                          ; $A220  87
        DEC B                            ; $A221  05
        JP NZ,DIR_DEBLOCK_SHIFT                 ; $A222  C2 20 A2
        ; Byte offset (0/32/64/96) of this entry within the 128-byte directory buffer.
        LD (DEBLOCK_BYTE_OFF),A                    ; $A225  32 E9 A9
        OR A                             ; $A228  B7
        ; Entry not on a record boundary: the record is already buffered, done.
        RET NZ                           ; $A229  C0
        PUSH BC                          ; $A22A  C5
        ; Resolve the directory record's physical disk location (block/record math).
        CALL REC_DIV4_SETUP                    ; $A22B  CD C3 9F
        ; Read the directory record into the disk buffer.
        CALL DIR_RECORD_READ                    ; $A22E  CD D4 A1
        POP BC                           ; $A231  C1
        ; Re-evaluate the record-scan state after the read.
        JP RECORD_SCAN_BODY                    ; $A232  C3 9E A1
; ----------------------------------------------------------------------
; ALLOC_BIT_GET -- Fetch the allocation-vector bit for a given disk block, returning it in carry.
;   In: BC = block (group) number.
;   Out: carry/high bit of A = current allocation state of that block; A = the allocation byte
;        rotated so the wanted bit is in the MSB; HL = address of that byte in the allocation
;        vector; D = E = bit index (rotate count).
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: D=E=(block & 7)+1 = bit index (1-based) used as a rotate count; byte index = block >>
;              3; add to ALLOC_VEC_PTR; load the byte and rotate left by the bit index so the
;              selected bit ends up in carry/MSB.
; [RE] Canonical CP/M 2.2 getmod: read one allocation bit from the bit-vector.
; ----------------------------------------------------------------------
CMD_EXEC_56:
        LD A,C                           ; $A235  79
        ; Low 3 bits = bit position of the block within its allocation byte.
        AND $07                          ; $A236  E6 07
        ; 1-based rotate count to bring the wanted bit into the MSB.
        INC A                            ; $A238  3C
        ; Save the bit index in both D and E (E consumed here; D consumed by ALLOC_BIT_SET on the
        ; way back).
        LD E,A                           ; $A239  5F
        LD D,A                           ; $A23A  57
        LD A,C                           ; $A23B  79
        RRCA                             ; $A23C  0F
        RRCA                             ; $A23D  0F
        RRCA                             ; $A23E  0F
        ; Form the byte index (block >> 3), low half of the 16-bit offset.
        AND $1F                          ; $A23F  E6 1F
        LD C,A                           ; $A241  4F
        LD A,B                           ; $A242  78
        ADD A,A                          ; $A243  87
        ADD A,A                          ; $A244  87
        ADD A,A                          ; $A245  87
        ADD A,A                          ; $A246  87
        ADD A,A                          ; $A247  87
        ; Combine high/low pieces of the (block>>3) byte offset.
        OR C                             ; $A248  B1
        LD C,A                           ; $A249  4F
        LD A,B                           ; $A24A  78
        RRCA                             ; $A24B  0F
        RRCA                             ; $A24C  0F
        RRCA                             ; $A24D  0F
        AND $1F                          ; $A24E  E6 1F
        LD B,A                           ; $A250  47
        ; Base of the in-memory allocation bit-vector for this drive.
        LD HL,(ALLOC_VEC_PTR)                   ; $A251  2A BF A9
        ; HL -> the allocation byte holding this block's bit.
        ADD HL,BC                        ; $A254  09
        ; Load that allocation byte.
        LD A,(HL)                        ; $A255  7E
ALLOC_BIT_ROTATE:
        RLCA                             ; $A256  07
        DEC E                            ; $A257  1D
        JP NZ,ALLOC_BIT_ROTATE                 ; $A258  C2 56 A2
        RET                              ; $A25B  C9
; ----------------------------------------------------------------------
; ALLOC_BIT_SET -- Mark a disk block as allocated in the allocation vector.
;   In: BC = block (group) number.
;   Out: the allocation byte for that block is updated in place with its bit forced to 1.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: call ALLOC_BIT_GET to read the byte (left-rotated so the bit is in the MSB) and
;              return the bit index in D; clear the rotated LSB and OR in 1 to set the target bit;
;              rotate right D times to restore byte alignment; store it back via HL.
; [RE] Canonical CP/M 2.2 setmod: set one allocation bit in the bit-vector.
; ----------------------------------------------------------------------
CMD_EXEC_60:
        PUSH DE                          ; $A25C  D5
        ; Read the allocation byte rotated so the target bit is in the MSB (D = bit index).
        CALL CMD_EXEC_56                    ; $A25D  CD 35 A2
        ; Clear the rotated LSB; the following OR C forces this block's bit to 1.
        AND $FE                          ; $A260  E6 FE
        ; Recover the saved bit value (in C) to OR into the rotated byte.
        POP BC                           ; $A262  C1
        ; Set the target allocation bit.
        OR C                             ; $A263  B1
ALLOC_BIT_RESTORE:
        RRCA                             ; $A264  0F
        DEC D                            ; $A265  15
        JP NZ,ALLOC_BIT_RESTORE                   ; $A266  C2 64 A2
        ; Store the updated allocation byte back into the bit-vector.
        LD (HL),A                        ; $A269  77
        RET                              ; $A26A  C9
; ----------------------------------------------------------------------
; ALLOC_FROM_FCB -- Mark every disk block referenced by a directory entry's block map as allocated.
;   In: DEBLOCK_BYTE_OFF positions HL on the current 32-byte directory entry; BLOCK_WIDTH_FLAG
;       selects 8-bit (non-zero, DSM<256) vs 16-bit (zero) block numbers; entry contains a 16-byte
;       block-pointer map at offset $10.
;   Out: the allocation vector has every non-zero, in-range block of this entry marked used.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: point HL at the block map (entry+$10); iterate 16 (8-bit) or 8 (16-bit) pointers;
;              read each block number; if non-zero and <= MAX_BLOCK_DSM, mark it allocated via
;              ALLOC_BIT_SET.
; [RE] Canonical CP/M 2.2 directory-entry allocation-map application used when rebuilding the
; allocation vector.
; ----------------------------------------------------------------------
CMD_EXEC_61:
        ; HL -> start of the current 32-byte directory entry in the buffer.
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A26B  CD 5E A1
        ; Skip to the 16-byte block-pointer map at offset $10 of the entry.
        LD DE,$0010                      ; $A26E  11 10 00
        ADD HL,DE                        ; $A271  19
        PUSH BC                          ; $A272  C5
        ; Loop counter: 16 block pointers plus one (decremented before each iteration).
        LD C,$11                         ; $A273  0E 11
ALLOC_FROM_FCB_LOOP:
        POP DE                           ; $A275  D1
        DEC C                            ; $A276  0D
        RET Z                            ; $A277  C8
        PUSH DE                          ; $A278  D5
        ; Non-zero => 8-bit block numbers (DSM<256); zero => 16-bit block numbers.
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A279  3A DD A9
        OR A                             ; $A27C  B7
        JP Z,ALLOC_FROM_FCB_WIDE                  ; $A27D  CA 88 A2
        PUSH BC                          ; $A280  C5
        PUSH HL                          ; $A281  E5
        ; Read one block-pointer byte (low byte of the block number; 8-bit path).
        LD C,(HL)                        ; $A282  4E
        LD B,$00                         ; $A283  06 00
        JP ALLOC_FROM_FCB_CHECK                    ; $A285  C3 8E A2
ALLOC_FROM_FCB_WIDE:
        DEC C                            ; $A288  0D
        PUSH BC                          ; $A289  C5
        LD C,(HL)                        ; $A28A  4E
        INC HL                           ; $A28B  23
        LD B,(HL)                        ; $A28C  46
        PUSH HL                          ; $A28D  E5
ALLOC_FROM_FCB_CHECK:
        LD A,C                           ; $A28E  79
        OR B                             ; $A28F  B0
        JP Z,ALLOC_FROM_FCB_NEXT                  ; $A290  CA 9D A2
        ; DSM = highest valid block number for this drive.
        LD HL,(MAX_BLOCK_DSM)                   ; $A293  2A C6 A9
        LD A,L                           ; $A296  7D
        ; Range-check the block number against DSM (16-bit subtract: LD A,L/SUB C then LD A,H/SBC
        ; A,B).
        SUB C                            ; $A297  91
        LD A,H                           ; $A298  7C
        SBC A,B                          ; $A299  98
        ; In range and non-zero: mark this block allocated.
        CALL NC,CMD_EXEC_60                 ; $A29A  D4 5C A2
ALLOC_FROM_FCB_NEXT:
        POP HL                           ; $A29D  E1
        INC HL                           ; $A29E  23
        POP BC                           ; $A29F  C1
        JP ALLOC_FROM_FCB_LOOP                    ; $A2A0  C3 75 A2
; ----------------------------------------------------------------------
; ALLOC_VECTOR_BUILD -- Rebuild the drive's allocation bit-vector by scanning the entire directory.
;   In: selected drive's DPB fields (MAX_BLOCK_DSM, directory-reserved-blocks word at ALLOC_END_PTR,
;       ALLOC_VEC_PTR) set up.
;   Out: allocation vector fully populated: reserved directory blocks plus every block referenced by
;        a non-deleted directory entry are marked used.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: zero the allocation vector across its whole length ((DSM+1)/8 bytes); seed the
;              directory's reserved blocks; reset the scan workspace to read the directory from the
;              start; for each directory entry skip deleted ($E5) entries, run a special-entry check
;              against the BDOS default-FCB byte / '$' name byte, and call ALLOC_FROM_FCB to mark
;              its blocks; advance to the next entry until the directory is exhausted.
; [RE] Canonical CP/M 2.2 drive-init allocation-vector builder, invoked on drive selection / reset.
; [?] The compare against ($9F41) (BDOS default-FCB area) followed by the $24 ('$') name-byte test
; and the ($9F45) flag store is a special-entry path; its exact intent is UNKNOWN.
; ----------------------------------------------------------------------
CMD_EXEC_65:
        ; DSM = highest block number; +1 gives the block count to clear.
        LD HL,(MAX_BLOCK_DSM)                   ; $A2A3  2A C6 A9
        ; Shift count 3: (DSM+1)/8 = number of bytes in the allocation vector.
        LD C,$03                         ; $A2A6  0E 03
        ; HL >>= 3 to convert block count into allocation-byte count.
        CALL DRV_INSTALL_RWTS_10                    ; $A2A8  CD EA A0
        INC HL                           ; $A2AB  23
        LD B,H                           ; $A2AC  44
        LD C,L                           ; $A2AD  4D
        ; Start of the allocation vector to be cleared.
        LD HL,(ALLOC_VEC_PTR)                   ; $A2AE  2A BF A9
ALLOC_VECTOR_CLEAR_LOOP:
        ; Zero one allocation byte.
        LD (HL),$00                      ; $A2B1  36 00
        INC HL                           ; $A2B3  23
        DEC BC                           ; $A2B4  0B
        LD A,B                           ; $A2B5  78
        OR C                             ; $A2B6  B1
        JP NZ,ALLOC_VECTOR_CLEAR_LOOP                 ; $A2B7  C2 B1 A2
        ; Reserved-blocks mask word: the directory's pre-allocated blocks.
        LD HL,(ALLOC_END_PTR)                   ; $A2BA  2A CA A9
        EX DE,HL                         ; $A2BD  EB
        LD HL,(ALLOC_VEC_PTR)                   ; $A2BE  2A BF A9
        ; Seed the allocation vector with the reserved (directory) blocks.
        LD (HL),E                        ; $A2C1  73
        INC HL                           ; $A2C2  23
        LD (HL),D                        ; $A2C3  72
        ; Reset the directory scan state to the beginning.
        CALL DISK_HOME_CLEAR_SCAN                    ; $A2C4  CD A1 9F
        LD HL,(DPB_WORK_PTR0)                   ; $A2C7  2A B3 A9
        ; Initialise the scan record-count workspace.
        LD (HL),$03                      ; $A2CA  36 03
        INC HL                           ; $A2CC  23
        LD (HL),$00                      ; $A2CD  36 00
        ; Invalidate CUR_RECORD so the first read positions at directory start.
        CALL INVALIDATE_CUR_RECORD                    ; $A2CF  CD FE A1
ALLOC_VECTOR_SCAN_LOOP:
        ; Search-all sentinel: advance unconditionally through every directory record.
        LD C,$FF                         ; $A2D2  0E FF
        ; Advance to and deblock the next directory entry.
        CALL CMD_EXEC_53                    ; $A2D4  CD 05 A2
        ; Test for end-of-directory; Z => done scanning.
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A2D7  CD F5 A1
        ; Whole directory scanned: allocation vector is complete.
        RET Z                            ; $A2DA  C8
        ; HL -> the current directory entry's first byte (user/status code).
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A2DB  CD 5E A1
        ; $E5 = deleted/empty directory entry marker.
        LD A,$E5                         ; $A2DE  3E E5
        ; Skip deleted entries; they own no blocks.
        CP (HL)                          ; $A2E0  BE
        ; Deleted entry: move to the next directory entry.
        JP Z,ALLOC_VECTOR_SCAN_LOOP                  ; $A2E1  CA D2 A2
        ; Special-entry check: compare the entry's first byte against the BDOS default-FCB byte
        ; ($9F41); exact purpose UNKNOWN.
        LD A,(BDOS_STACK_TOP)                    ; $A2E4  3A 41 9F
        CP (HL)                          ; $A2E7  BE
        JP NZ,ALLOC_VECTOR_SCAN_MARK                 ; $A2E8  C2 F6 A2
        INC HL                           ; $A2EB  23
        LD A,(HL)                        ; $A2EC  7E
        ; Test the entry's name byte against '$' ($24); part of the special-entry path.
        SUB $24                          ; $A2ED  D6 24
        JP NZ,ALLOC_VECTOR_SCAN_MARK                 ; $A2EF  C2 F6 A2
        DEC A                            ; $A2F2  3D
        ; Record the special-entry result flag ($9F45); role UNKNOWN.
        LD (BDOS_RETVAL),A                    ; $A2F3  32 45 9F
ALLOC_VECTOR_SCAN_MARK:
        ; Select 8-bit-block-map width (BLOCK_WIDTH_FLAG non-zero) for the allocation pass.
        LD C,$01                         ; $A2F6  0E 01
        ; Mark every block this directory entry references as allocated.
        CALL CMD_EXEC_61                    ; $A2F8  CD 6B A2
        ; Advance the directory record/scan pointer to the next entry.
        CALL RECPTR_INC_STORE                    ; $A2FB  CD 8C A1
        ; Continue the directory scan.
        JP ALLOC_VECTOR_SCAN_LOOP                    ; $A2FE  C3 D2 A2
; ----------------------------------------------------------------------
; DIR_RETURN_MATCH_FLAG -- return the saved directory-search match status as the BDOS result.
;   In: DIR_MATCH_FLAG ($A9D4) holds the result of the last directory scan ($FF=no match, else the
;       0..3 entry index).
;   Out: A = DIR_MATCH_FLAG; stored to the BDOS result byte ($9F45) via BDOS_RET_RESULT.
;   Clobbers: A
;   Algorithm: load the cached search-match flag and tail-jump into the common result-store path.
;              Used as the common return tail of F_DELETE_HND/F_RENAME_HND/F_ATTRIB_HND.
;   [RE]
; ----------------------------------------------------------------------
DIR_RETURN_MATCH_FLAG:
        ; fetch the directory-search match flag saved by the scan
        LD A,(DIR_MATCH_FLAG)                    ; $A301  3A D4 A9
        ; store A as the BDOS function result and return
        JP BDOS_RET_RESULT                   ; $A304  C3 01 9F
; ----------------------------------------------------------------------
; FCB_EXTENT_COMPARE -- compare two FCB extent bytes under the drive's extent mask.
;   In: C = one extent byte; A = the other extent byte; EXTENT_MASK ($A9C5) = DPB EXM.
;   Out: A,flags = ((A & ~mask) - (C & ~mask)) & $1F; Z set when the high extent fields match.
;   Clobbers: A (BC/AF saved+restored across the call).
;   Algorithm: complement EXM, AND it into both extent bytes (dropping the masked low bits),
;              subtract, keep five bits, and test for equality. BC and AF are pushed/popped, so only
;              A and flags effectively change.
;   [RE]
; ----------------------------------------------------------------------
FCB_EXTENT_COMPARE:
        PUSH BC                          ; $A307  C5
        PUSH AF                          ; $A308  F5
        ; load the drive extent mask (DPB EXM)
        LD A,(DPB_EXM)                    ; $A309  3A C5 A9
        ; complement mask: keep the extent bits, drop the EXM-masked low bits
        CPL                              ; $A30C  2F
        LD B,A                           ; $A30D  47
        LD A,C                           ; $A30E  79
        ; mask one extent byte (C) with ~EXM
        AND B                            ; $A30F  A0
        LD C,A                           ; $A310  4F
        POP AF                           ; $A311  F1
        ; mask the other extent byte (A) the same way
        AND B                            ; $A312  A0
        ; compare the two masked extents
        SUB C                            ; $A313  91
        ; keep the 5-bit extent field; Z means the extents match
        AND $1F                          ; $A314  E6 1F
        POP BC                           ; $A316  C1
        RET                              ; $A317  C9
; ----------------------------------------------------------------------
; DIR_SEARCH_FIRST -- begin a directory scan for the current FCB, comparing C bytes per entry.
;   In: C = number of FCB bytes to match (e.g. $0C=name+type, $0F=incl. extent); FCB pointer in
;       CURFCB_PTR ($9F43).
;   Out: falls straight through into BDOS_DIR_SCAN_NEXT, which returns the within-record entry index
;        0..3 or $FF.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: set DIR_MATCH_FLAG=$FF, store the compare length ($A9D8) and the search-FCB pointer
;              ($A9D9), reset the record counter to -1 (INVALIDATE_CUR_RECORD), rewind/clear the
;              directory scan state (DISK_HOME_CLEAR_SCAN), then run the first search-next pass.
;   [RE]
; ----------------------------------------------------------------------
DIR_SEARCH_FIRST:
        LD A,$FF                         ; $A318  3E FF
        ; DIR_MATCH_FLAG = $FF (no match yet)
        LD (DIR_MATCH_FLAG),A                    ; $A31A  32 D4 A9
        LD HL,DIR_CMP_LEN                     ; $A31D  21 D8 A9
        ; save number of FCB bytes to compare per entry
        LD (HL),C                        ; $A320  71
        ; current FCB pointer
        LD HL,(BDOS_PARAM_PTR)                   ; $A321  2A 43 9F
        ; save the search-FCB pointer for the scan loop
        LD (DIR_FCB_PTR),HL                   ; $A324  22 D9 A9
        ; reset the directory record counter to -1
        CALL INVALIDATE_CUR_RECORD                    ; $A327  CD FE A1
        ; rewind directory scan state / clear the record pointers
        CALL DISK_HOME_CLEAR_SCAN                    ; $A32A  CD A1 9F
; ----------------------------------------------------------------------
; BDOS_DIR_SCAN_NEXT -- advance through directory entries until one matches the search FCB.
;   In: search-FCB pointer in DIR_FCB_PTR ($A9D9); compare length in DIR_CMP_LEN ($A9D8).
;   Out: A=matching entry index (0..3) on success (via DIR_MATCH_DONE); not-found via DIR_NO_MATCH
;        ($FF result).
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: step to the next directory record (CMD_EXEC_53); if the record counter passed the
;              directory limit -> not found; otherwise treat erased ($E5) entries specially and
;              bound-check the record (CMP_CURREC_VS_WORKPTR), then fall into the per-entry compare;
;              on full match -> DIR_MATCH_DONE, else loop to the next entry/record.
;   [RE] standard CP/M 2.2 directory search-next with '?' wildcards
; ----------------------------------------------------------------------
BDOS_DIR_SCAN_NEXT:
        ; scan mode: plain search-next (no special return)
        LD C,$00                         ; $A32D  0E 00
        ; advance to the next directory record
        CALL CMD_EXEC_53                    ; $A32F  CD 05 A2
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A332  CD F5 A1
        ; record counter passed the directory limit -> not found
        JP Z,DIR_NO_MATCH                  ; $A335  CA 94 A3
        ; DE := search-FCB pointer
        LD HL,(DIR_FCB_PTR)                   ; $A338  2A D9 A9
        EX DE,HL                         ; $A33B  EB
        LD A,(DE)                        ; $A33C  1A
        ; first byte $E5 = empty/erased directory slot
        CP $E5                           ; $A33D  FE E5
        JP Z,BDOS_DIR_SCAN_NEXT_CMP                  ; $A33F  CA 4A A3
        PUSH DE                          ; $A342  D5
        ; have we run past the active directory extent?
        CALL CMP_CURREC_VS_WORKPTR                    ; $A343  CD 7F A1
        POP DE                           ; $A346  D1
        ; past end-of-directory -> not found
        JP NC,DIR_NO_MATCH                 ; $A347  D2 94 A3
; ----------------------------------------------------------------------
; BDOS_DIR_SCAN_NEXT_CMP -- set up the per-entry compare loop for BDOS_DIR_SCAN_NEXT.
;   In: DE -> directory entry; FCB bytes located via FCB_BUF_PTR_ADD_OFFSET; DIR_CMP_LEN ($A9D8)
;       bytes to compare.
;   Out: B=0 (index), C=compare count; falls into DIR_CMP_BYTE_LOOP.
;   Clobbers: A,B,C,H,L,flags
;   Algorithm: point HL at the FCB bytes to compare (FCB_BUF_PTR_ADD_OFFSET), load the compare
;              length into C, zero the byte index B, then enter the byte-compare loop.
;   [RE]
; ----------------------------------------------------------------------
BDOS_DIR_SCAN_NEXT_CMP:
        ; HL -> FCB bytes to compare against the entry
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A34A  CD 5E A1
        ; load number of bytes to compare per entry
        LD A,(DIR_CMP_LEN)                    ; $A34D  3A D8 A9
        LD C,A                           ; $A350  4F
        LD B,$00                         ; $A351  06 00
; ----------------------------------------------------------------------
; DIR_CMP_BYTE_LOOP -- compare one FCB byte against the directory entry, honoring wildcards.
;   In: C = bytes remaining; B = byte index within the entry; DE -> entry byte; HL -> FCB byte.
;   Out: on count exhausted -> DIR_MATCH_FOUND; on mismatch -> restart BDOS_DIR_SCAN_NEXT; else step
;        via DIR_CMP_ADVANCE.
;   Clobbers: A,flags (DE,HL,B,C advanced by DIR_CMP_ADVANCE)
;   Algorithm: count==0 ends the entry as a match; entry byte '?' ($3F) is a wildcard; index 13
;              ($0D, S1) is skipped; index 12 ($0C) is the extent field (DIR_CMP_EXTENT); otherwise
;              the two bytes must match in the low 7 bits.
;   [RE]
; ----------------------------------------------------------------------
DIR_CMP_BYTE_LOOP:
        LD A,C                           ; $A353  79
        OR A                             ; $A354  B7
        ; all bytes compared equal -> directory entry matches
        JP Z,DIR_MATCH_FOUND                  ; $A355  CA 83 A3
        LD A,(DE)                        ; $A358  1A
        ; '?' wildcard in the entry byte matches any FCB byte
        CP $3F                           ; $A359  FE 3F
        JP Z,DIR_CMP_ADVANCE                  ; $A35B  CA 7C A3
        LD A,B                           ; $A35E  78
        ; byte index 13 (S1) is ignored in the compare
        CP $0D                           ; $A35F  FE 0D
        JP Z,DIR_CMP_ADVANCE                  ; $A361  CA 7C A3
        ; byte index 12 is the extent byte -> special compare
        CP $0C                           ; $A364  FE 0C
        LD A,(DE)                        ; $A366  1A
        JP Z,DIR_CMP_EXTENT                  ; $A367  CA 73 A3
        ; ordinary byte: entry byte minus the FCB byte
        SUB (HL)                         ; $A36A  96
        ; mask the attribute high bit; non-zero -> mismatch, rescan
        AND $7F                          ; $A36B  E6 7F
        JP NZ,BDOS_DIR_SCAN_NEXT                   ; $A36D  C2 2D A3
        JP DIR_CMP_ADVANCE                    ; $A370  C3 7C A3
; ----------------------------------------------------------------------
; DIR_CMP_EXTENT -- compare the extent byte during the directory match.
;   In: HL -> FCB extent byte; A = entry extent byte; B/C preserved across the call.
;   Out: equal -> DIR_CMP_ADVANCE; unequal -> restart BDOS_DIR_SCAN_NEXT.
;   Clobbers: A,flags (BC saved+restored)
;   Algorithm: load the FCB extent byte into C, call FCB_EXTENT_COMPARE on the entry extent (A) and
;              the FCB extent under the EXM mask; Z continues the compare, NZ rejects this entry.
;   [RE]
; ----------------------------------------------------------------------
DIR_CMP_EXTENT:
        PUSH BC                          ; $A373  C5
        LD C,(HL)                        ; $A374  4E
        ; compare entry vs FCB extents under the EXM mask
        CALL FCB_EXTENT_COMPARE                    ; $A375  CD 07 A3
        POP BC                           ; $A378  C1
        ; extent differs -> reject entry, continue search
        JP NZ,BDOS_DIR_SCAN_NEXT                   ; $A379  C2 2D A3
; ----------------------------------------------------------------------
; DIR_CMP_ADVANCE -- step to the next byte of the entry/FCB compare.
;   In: DE -> entry byte, HL -> FCB byte, B = index, C = count remaining.
;   Out: DE,HL incremented; B incremented; C decremented; loops back to DIR_CMP_BYTE_LOOP.
;   Clobbers: B,C,D,E,H,L
;   Algorithm: advance both pointers, bump the index, drop the remaining count, re-enter the byte
;              loop.
;   [RE]
; ----------------------------------------------------------------------
DIR_CMP_ADVANCE:
        INC DE                           ; $A37C  13
        INC HL                           ; $A37D  23
        INC B                            ; $A37E  04
        DEC C                            ; $A37F  0D
        ; compare the next byte of the entry
        JP DIR_CMP_BYTE_LOOP                    ; $A380  C3 53 A3
; ----------------------------------------------------------------------
; DIR_MATCH_FOUND -- record a successful directory match and return its index.
;   In: CUR_RECORD ($A9EA) = current directory record number.
;   Out: BDOS result byte ($9F45) = record & 3 (entry index 0..3); DIR_MATCH_FLAG cleared to 0 if it
;        was still negative.
;   Clobbers: A,H,L,flags
;   Algorithm: compute the within-record entry index (record mod 4) into the result byte; if
;              DIR_MATCH_FLAG still has its sign bit set (=$FF, not yet matched), zero it to mark
;              'matched'.
;   [RE]
; ----------------------------------------------------------------------
DIR_MATCH_FOUND:
        LD A,(CUR_RECORD)                    ; $A383  3A EA A9
        ; entry index within the 128-byte record (4 entries)
        AND $03                          ; $A386  E6 03
        ; store entry index as the search result
        LD (BDOS_RETVAL),A                    ; $A388  32 45 9F
        ; point at DIR_MATCH_FLAG
        LD HL,DIR_MATCH_FLAG                     ; $A38B  21 D4 A9
        LD A,(HL)                        ; $A38E  7E
        ; test the flag's high bit (still $FF == not yet matched)
        RLA                              ; $A38F  17
        ; flag already cleared -> keep it
        RET NC                           ; $A390  D0
        XOR A                            ; $A391  AF
        LD (HL),A                        ; $A392  77
        RET                              ; $A393  C9
; ----------------------------------------------------------------------
; DIR_NO_MATCH -- terminate a directory scan with 'not found'.
;   In: none.
;   Out: BDOS result byte ($9F45) = $FF; record counter reset to -1.
;   Clobbers: A,H,L,flags
;   Algorithm: reset the record counter (INVALIDATE_CUR_RECORD) and store $FF as the BDOS result.
;   [RE]
; ----------------------------------------------------------------------
DIR_NO_MATCH:
        ; reset the directory record counter to -1
        CALL INVALIDATE_CUR_RECORD                    ; $A394  CD FE A1
        ; $FF = directory entry not found
        LD A,$FF                         ; $A397  3E FF
        ; store $FF as the BDOS result
        JP BDOS_RET_RESULT                   ; $A399  C3 01 9F
; ----------------------------------------------------------------------
; F_DELETE_HND -- delete every directory entry matching the FCB (BDOS function 19).
;   In: CURFCB_PTR ($9F43) -> FCB (may contain '?' wildcards). Reached from F_DELETE_H (dispatch fn
;       19).
;   Out: matching directory entries marked erased ($E5) and written back; result via the search
;        tail.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: log in the drive (CMD_EXEC_20), search-first on 12 FCB bytes (name+type), then fall
;              into F_DELETE_LOOP to erase each match.
;   [RE] CP/M 2.2 F_DELETE_HND
; ----------------------------------------------------------------------
F_DELETE_HND:
        ; verify/log in the selected drive
        CALL CMD_EXEC_20                    ; $A39C  CD 54 A1
        ; compare 12 FCB bytes (name + type, ignore extent)
        LD C,$0C                         ; $A39F  0E 0C
        ; search-first for a matching directory entry
        CALL DIR_SEARCH_FIRST                    ; $A3A1  CD 18 A3
; ----------------------------------------------------------------------
; F_DELETE_LOOP -- erase-and-write each matching directory entry, then search the next.
;   In: a pending search result from DIR_SEARCH_FIRST/NEXT.
;   Out: returns when no further matches remain.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: stop when CUR_RECORD_BYTES_EQUAL reports no match; reject if read-only
;              (FCB_RO_FLAG_TEST); point at the matched entry, set its first byte to $E5, clear the
;              entry's allocation map (CMD_EXEC_61), write the directory record (DIR_RECORD_WRITE),
;              search-next, repeat.
;   [RE]
; ----------------------------------------------------------------------
F_DELETE_LOOP:
        ; did the previous search find an entry?
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A3A4  CD F5 A1
        ; no more matches -> done
        RET Z                            ; $A3A7  C8
        ; reject deletion if the file is read-only
        CALL FCB_RO_FLAG_TEST                    ; $A3A8  CD 44 A1
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A3AB  CD 5E A1
        ; mark the directory entry as erased
        LD (HL),$E5                      ; $A3AE  36 E5
        LD C,$00                         ; $A3B0  0E 00
        ; free this entry's allocation-map blocks
        CALL CMD_EXEC_61                    ; $A3B2  CD 6B A2
        ; write the modified directory record back to disk
        CALL DIR_RECORD_WRITE                    ; $A3B5  CD C6 A1
        ; advance to the next matching entry
        CALL BDOS_DIR_SCAN_NEXT                    ; $A3B8  CD 2D A3
        JP F_DELETE_LOOP                    ; $A3BB  C3 A4 A3
; ----------------------------------------------------------------------
; ALLOC_GET_BLOCK -- find/allocate a disk block near a starting block, marking it used.
;   In: BC = starting block number (passed by the write core when extending a file).
;   Out: HL = the block number actually claimed (0 if none free); its allocation-vector bit set.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: copy the start block to DE, scan downward then upward from it testing each block's
;              allocation bit (CMD_EXEC_56 = BLOCK_BIT_TEST), bounded by MAX_BLOCK_DSM; mark the
;              chosen block used (ALLOC_BIT_RESTORE = ALLOC_VEC_SETBIT) and return it, or 0 when no
;              block can be allocated.
;   [RE] allocation-vector block search/allocate
; ----------------------------------------------------------------------
ALLOC_GET_BLOCK:
        ; copy the starting block number into DE
        LD D,B                           ; $A3BE  50
        LD E,C                           ; $A3BF  59
; ----------------------------------------------------------------------
; ALLOC_SCAN_DOWN -- scan downward for an in-use block in the run.
;   In: BC = block counter; DE = candidate block; allocation vector via CMD_EXEC_56
;       (BLOCK_BIT_TEST).
;   Out: on an in-use block -> ALLOC_MARK_DONE; otherwise falls into ALLOC_SCAN_UP.
;   Clobbers: A,B,C,D,E,flags
;   Algorithm: while BC != 0, decrement, test the block's bit; if set (in use), finish; else keep
;              scanning down.
;   [RE]
; ----------------------------------------------------------------------
ALLOC_SCAN_DOWN:
        LD A,C                           ; $A3C0  79
        OR B                             ; $A3C1  B0
        ; counter exhausted -> switch to upward scan
        JP Z,ALLOC_SCAN_UP                  ; $A3C2  CA D1 A3
        DEC BC                           ; $A3C5  0B
        PUSH DE                          ; $A3C6  D5
        PUSH BC                          ; $A3C7  C5
        ; test this block's allocation-vector bit
        CALL CMD_EXEC_56                    ; $A3C8  CD 35 A2
        ; carry = the tested block's in-use bit
        RRA                              ; $A3CB  1F
        ; block already in use -> mark and finish
        JP NC,ALLOC_MARK_DONE                 ; $A3CC  D2 EC A3
        POP BC                           ; $A3CF  C1
        POP DE                           ; $A3D0  D1
; ----------------------------------------------------------------------
; ALLOC_SCAN_UP -- scan upward (toward MAX_BLOCK_DSM) for an in-use block.
;   In: DE = candidate block; MAX_BLOCK_DSM ($A9C6) = highest block number on the drive.
;   Out: at/past the disk limit -> ALLOC_SCAN_FINISH; on an in-use block -> ALLOC_MARK_DONE.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: compare DE against DSM; if past it, stop; else increment and test the next block's
;              allocation bit (CMD_EXEC_56), looping back to the downward scan.
;   [RE]
; ----------------------------------------------------------------------
ALLOC_SCAN_UP:
        ; highest valid block number (DSM)
        LD HL,(MAX_BLOCK_DSM)                   ; $A3D1  2A C6 A9
        LD A,E                           ; $A3D4  7B
        SUB L                            ; $A3D5  95
        LD A,D                           ; $A3D6  7A
        SBC A,H                          ; $A3D7  9C
        ; candidate beyond disk size -> stop scanning
        JP NC,ALLOC_SCAN_FINISH                 ; $A3D8  D2 F4 A3
        INC DE                           ; $A3DB  13
        PUSH BC                          ; $A3DC  C5
        PUSH DE                          ; $A3DD  D5
        LD B,D                           ; $A3DE  42
        LD C,E                           ; $A3DF  4B
        ; test the next block's allocation bit
        CALL CMD_EXEC_56                    ; $A3E0  CD 35 A2
        ; carry = in-use bit
        RRA                              ; $A3E3  1F
        ; in use -> mark and finish
        JP NC,ALLOC_MARK_DONE                 ; $A3E4  D2 EC A3
        POP DE                           ; $A3E7  D1
        POP BC                           ; $A3E8  C1
        JP ALLOC_SCAN_DOWN                    ; $A3E9  C3 C0 A3
; ----------------------------------------------------------------------
; ALLOC_MARK_DONE -- set the chosen block's allocation bit and return it.
;   In: A = the block's current allocation byte (rotated by the scan); the block number tracked by
;       ALLOC_BIT_RESTORE.
;   Out: allocation vector updated; HL/DE restored from the stack; returns to ALLOC_GET_BLOCK's
;        caller.
;   Clobbers: A,H,L,D,E,flags
;   Algorithm: rotate the in-use bit back into place, force it set (INC A), write it through
;              ALLOC_BIT_RESTORE (ALLOC_VEC_SETBIT), restore the saved registers, and return.
;   [RE]
; ----------------------------------------------------------------------
ALLOC_MARK_DONE:
        ; rotate the bit back to its position in the allocation byte
        RLA                              ; $A3EC  17
        ; force the block's bit to 'used'
        INC A                            ; $A3ED  3C
        ; write the updated bit back into the allocation vector
        CALL ALLOC_BIT_RESTORE                    ; $A3EE  CD 64 A2
        POP HL                           ; $A3F1  E1
        POP DE                           ; $A3F2  D1
        RET                              ; $A3F3  C9
; ----------------------------------------------------------------------
; ALLOC_SCAN_FINISH -- end the block scan when the disk limit is reached.
;   In: BC = remaining block counter; DE = candidate block.
;   Out: if blocks remain -> back to ALLOC_SCAN_DOWN; else HL=0 (no block) and return.
;   Clobbers: A,H,L,flags
;   Algorithm: if the counter is non-zero, resume the downward scan; otherwise return zero meaning
;              no allocatable block was found.
;   [RE]
; ----------------------------------------------------------------------
ALLOC_SCAN_FINISH:
        LD A,C                           ; $A3F4  79
        OR B                             ; $A3F5  B0
        ; blocks left to scan -> continue downward
        JP NZ,ALLOC_SCAN_DOWN                 ; $A3F6  C2 C0 A3
        ; no block found -> return 0
        LD HL,$0000                      ; $A3F9  21 00 00
        RET                              ; $A3FC  C9
; ----------------------------------------------------------------------
; FCB_WRITE_DIR_ENTRY -- copy the whole 32-byte FCB image into the matched directory entry and write
; it.
;   In: CURFCB_PTR ($9F43) -> FCB; sets C=0 (FCB offset 0), E=$20 (32 bytes).
;   Out: directory record holding this entry written back to disk.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: set up a full-32-byte copy at FCB offset 0 and fall into FCB_COPY_TO_DIR, which moves
;              the bytes and writes the directory record.
;   [RE]
; ----------------------------------------------------------------------
FCB_WRITE_DIR_ENTRY:
        ; FCB source offset 0
        LD C,$00                         ; $A3FD  0E 00
        ; copy length 32 = full directory entry
        LD E,$20                         ; $A3FF  1E 20
; ----------------------------------------------------------------------
; FCB_COPY_TO_DIR -- copy E FCB bytes (from offset C) into the matched directory entry.
;   In: C = FCB byte offset; E = byte count; CURFCB_PTR ($9F43) -> FCB; current matched dir entry.
;   Out: directory buffer updated, then the record written via FCB_FLUSH_DIR.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: form a source pointer at FCB+C, point HL at the directory entry slot
;              (FCB_BUF_PTR_ADD_OFFSET), block-copy E bytes (BLOCK_COPY_INCC memcpy), then fall into
;              FCB_FLUSH_DIR to commit the record.
;   [RE]
; ----------------------------------------------------------------------
FCB_COPY_TO_DIR:
        PUSH DE                          ; $A401  D5
        LD B,$00                         ; $A402  06 00
        ; FCB base pointer
        LD HL,(BDOS_PARAM_PTR)                   ; $A404  2A 43 9F
        ; source := FCB + offset C
        ADD HL,BC                        ; $A407  09
        EX DE,HL                         ; $A408  EB
        ; HL -> destination slot in the directory buffer
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A409  CD 5E A1
        POP BC                           ; $A40C  C1
        ; copy E FCB bytes into the directory entry
        CALL BLOCK_COPY_INCC                    ; $A40D  CD 4F 9F
; ----------------------------------------------------------------------
; FCB_FLUSH_DIR -- position to the directory record and write it back.
;   In: current directory record state from the preceding match.
;   Out: the directory record written to disk.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: run the directory record-position helper (REC_DIV4_SETUP) then tail-jump to
;              DIR_RECORD_WRITE to commit the buffer to the directory sector.
;   [RE]
; ----------------------------------------------------------------------
FCB_FLUSH_DIR:
        ; position to the directory record's disk sector
        CALL REC_DIV4_SETUP                    ; $A410  CD C3 9F
        ; write the updated directory record to disk
        JP DIR_RECORD_WRITE                      ; $A413  C3 C6 A1
; ----------------------------------------------------------------------
; F_RENAME_HND -- rename a file: replace matching directory entries with the new name (BDOS fn 23).
;   In: CURFCB_PTR ($9F43) -> FCB whose bytes 0..15 are the old name and bytes 16..31 the new name.
;       Reached from F_RENAME_H (dispatch fn 23).
;   Out: every matching directory entry rewritten with the new name; read-only entries rejected.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: log in the drive, search-first on 12 bytes of the old name, copy the FCB drive byte
;              (offset 0) into the new-name half (offset 16) so both target the same drive, then run
;              F_RENAME_LOOP over each match.
;   [RE] CP/M 2.2 F_RENAME_HND
; ----------------------------------------------------------------------
F_RENAME_HND:
        ; verify/log in the selected drive
        CALL CMD_EXEC_20                    ; $A416  CD 54 A1
        ; search on 12 FCB bytes (old name + type)
        LD C,$0C                         ; $A419  0E 0C
        CALL DIR_SEARCH_FIRST                    ; $A41B  CD 18 A3
        LD HL,(BDOS_PARAM_PTR)                   ; $A41E  2A 43 9F
        LD A,(HL)                        ; $A421  7E
        ; offset 16: start of the new-name half of the FCB
        LD DE,$0010                      ; $A422  11 10 00
        ADD HL,DE                        ; $A425  19
        ; copy the FCB drive byte (offset 0) into the new-name half
        LD (HL),A                        ; $A426  77
; ----------------------------------------------------------------------
; F_RENAME_LOOP -- rewrite each matched entry with the new name and write it back.
;   In: a pending search result.
;   Out: returns when no more matches.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: stop on no-match; reject read-only files; copy 12 bytes from FCB offset 16 (the new
;              name+type) into the entry at offset 0 (via FCB_COPY_TO_DIR); write the directory
;              record; search-next; repeat.
;   [RE]
; ----------------------------------------------------------------------
F_RENAME_LOOP:
        ; did the search find an entry?
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A427  CD F5 A1
        ; no more matches -> done
        RET Z                            ; $A42A  C8
        ; reject rename of a read-only file
        CALL FCB_RO_FLAG_TEST                    ; $A42B  CD 44 A1
        ; source offset 16 = the new-name half of the FCB
        LD C,$10                         ; $A42E  0E 10
        ; copy 12 bytes (new name + type) over the entry
        LD E,$0C                         ; $A430  1E 0C
        ; overwrite the entry with the new name and flush
        CALL FCB_COPY_TO_DIR                    ; $A432  CD 01 A4
        ; advance to the next matching entry
        CALL BDOS_DIR_SCAN_NEXT                    ; $A435  CD 2D A3
        JP F_RENAME_LOOP                    ; $A438  C3 27 A4
; ----------------------------------------------------------------------
; F_ATTRIB_HND -- set file attributes from the FCB into matching directory entries (BDOS fn 30).
;   In: CURFCB_PTR ($9F43) -> FCB carrying the attribute high bits in the name/type bytes. Reached
;       from F_ATTRIB_H (dispatch fn 30).
;   Out: every matching directory entry's first 12 bytes rewritten with the FCB's attribute bits.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: search-first on 12 bytes, then run F_ATTRIB_LOOP to copy the 12 name/type bytes (with
;              their attribute high bits) from FCB offset 0 into each matched entry and write the
;              record.
;   [RE] CP/M 2.2 F_ATTRIB_HND
; ----------------------------------------------------------------------
F_ATTRIB_HND:
        ; search on 12 FCB bytes (name + type)
        LD C,$0C                         ; $A43B  0E 0C
        ; search-first for a matching entry
        CALL DIR_SEARCH_FIRST                    ; $A43D  CD 18 A3
; ----------------------------------------------------------------------
; F_ATTRIB_LOOP -- write the FCB's attribute bytes into each matched entry.
;   In: a pending search result.
;   Out: returns when no more matches.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: stop on no-match; copy 12 bytes from FCB offset 0 (name/type with attribute bits)
;              into the entry (FCB_COPY_TO_DIR); flush the directory record; search-next; repeat.
;   [RE]
; ----------------------------------------------------------------------
F_ATTRIB_LOOP:
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A440  CD F5 A1
        ; no more matches -> done
        RET Z                            ; $A443  C8
        ; source offset 0 = the FCB name/type bytes
        LD C,$00                         ; $A444  0E 00
        ; copy 12 bytes including the attribute high bits
        LD E,$0C                         ; $A446  1E 0C
        ; write the attribute bytes into the entry and flush
        CALL FCB_COPY_TO_DIR                    ; $A448  CD 01 A4
        ; advance to the next matching entry
        CALL BDOS_DIR_SCAN_NEXT                    ; $A44B  CD 2D A3
        JP F_ATTRIB_LOOP                    ; $A44E  C3 40 A4
; ----------------------------------------------------------------------
; FCB_OPEN_SEARCH -- search-first for the FCB's extent and merge the directory entry into the FCB.
;   In: CURFCB_PTR ($9F43) -> FCB. Called as the core of F_OPEN (F_OPEN_H, dispatch fn 15) and from
;       the random-record extent-positioning path.
;   Out: on match, the matched entry is merged into the FCB (record-count fields filled,
;        FILE_SIZE_FROM_EXTENT); on no match returns Z with no merge.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: search-first on 15 bytes (name+type+extent); if not found return Z; otherwise fall
;              through into FILE_SIZE_FROM_EXTENT to copy the entry into the FCB and set the record
;              count.
;   [RE] CP/M 2.2 F_OPEN core / extent locate-and-merge
; ----------------------------------------------------------------------
FCB_OPEN_SEARCH:
        ; search on 15 bytes (name + type + extent)
        LD C,$0F                         ; $A451  0E 0F
        ; search-first for the file's directory entry
        CALL DIR_SEARCH_FIRST                    ; $A453  CD 18 A3
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A456  CD F5 A1
        ; extent not found -> caller sees the no-match result
        RET Z                            ; $A459  C8
; ----------------------------------------------------------------------
; FILE_SIZE_FROM_EXTENT -- merge a matched directory entry into the FCB and update its record count.
;   In: HL -> matched directory entry; CURFCB_PTR ($9F43) -> the user FCB.
;   Out: the 32-byte entry copied into the FCB image; the FCB's record-count byte (offset 15)
;        updated per this extent.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: save the entry's first byte, copy the 32 directory bytes into the FCB image
;              (BLOCK_COPY_INCC), set the S2 'written' flag (MARK_FCB_S2_HIGHBIT), then from the
;              entry copy read offset 12 = EX (extent number) into C and offset 15 = RC (record
;              count) into B, and choose the new offset-15 value ($00 if this extent is below the
;              current one, RC if equal, $80 if above) and store it.  Used by both F_OPEN
;              (FCB_OPEN_SEARCH) and F_SIZE.
;   [RE]
; ----------------------------------------------------------------------
FILE_SIZE_FROM_EXTENT:
        ; HL -> matched entry; read its first (extent-low) byte
        CALL DRV_INSTALL_RWTS_1                    ; $A45A  CD A6 A0
        LD A,(HL)                        ; $A45D  7E
        PUSH AF                          ; $A45E  F5
        PUSH HL                          ; $A45F  E5
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A460  CD 5E A1
        EX DE,HL                         ; $A463  EB
        LD HL,(BDOS_PARAM_PTR)                   ; $A464  2A 43 9F
        ; copy the full 32-byte entry into the FCB image
        LD C,$20                         ; $A467  0E 20
        PUSH DE                          ; $A469  D5
        CALL BLOCK_COPY_INCC                    ; $A46A  CD 4F 9F
        CALL MARK_FCB_S2_HIGHBIT                    ; $A46D  CD 78 A1
        POP DE                           ; $A470  D1
        ; offset 12 = EX (extent number) of this entry
        LD HL,$000C                      ; $A471  21 0C 00
        ADD HL,DE                        ; $A474  19
        LD C,(HL)                        ; $A475  4E
        ; offset 15 = RC (record count) of this entry
        LD HL,$000F                      ; $A476  21 0F 00
        ADD HL,DE                        ; $A479  19
        LD B,(HL)                        ; $A47A  46
        POP HL                           ; $A47B  E1
        POP AF                           ; $A47C  F1
        LD (HL),A                        ; $A47D  77
        LD A,C                           ; $A47E  79
        ; compare this extent's number against the FCB's
        CP (HL)                          ; $A47F  BE
        LD A,B                           ; $A480  78
        JP Z,FILE_SIZE_STORE                  ; $A481  CA 8B A4
        LD A,$00                         ; $A484  3E 00
        JP C,FILE_SIZE_STORE                  ; $A486  DA 8B A4
        ; extent above current -> $80 (full 128-record) marker
        LD A,$80                         ; $A489  3E 80
; ----------------------------------------------------------------------
; FILE_SIZE_STORE -- write the computed record value into the FCB record-count field.
;   In: A = computed value ($00/$80/extent RC); CURFCB_PTR ($9F43) -> FCB.
;   Out: FCB offset 15 (RC) = A.
;   Clobbers: D,E,H,L
;   Algorithm: index the FCB to offset 15 and store the record-count byte.
;   [RE]
; ----------------------------------------------------------------------
FILE_SIZE_STORE:
        LD HL,(BDOS_PARAM_PTR)                   ; $A48B  2A 43 9F
        ; FCB offset 15 = record-count (RC) byte
        LD DE,$000F                      ; $A48E  11 0F 00
        ADD HL,DE                        ; $A491  19
        ; store the computed record value
        LD (HL),A                        ; $A492  77
        RET                              ; $A493  C9
; ----------------------------------------------------------------------
; FCB_WORD_FILL_IF_ZERO -- copy a 16-bit word from (DE) to (HL) only when (HL) is currently zero.
;   In: HL -> destination word; DE -> source word.
;   Out: if the destination word was 0, it is overwritten with the source word; DE,HL preserved.
;   Clobbers: A,flags
;   Algorithm: OR the two destination bytes; if non-zero return unchanged; otherwise copy both
;              source bytes across, restoring DE/HL to their entry values.
;   [RE] allocation-word merge helper used during F_CLOSE_HND
; ----------------------------------------------------------------------
FCB_WORD_FILL_IF_ZERO:
        LD A,(HL)                        ; $A494  7E
        INC HL                           ; $A495  23
        ; test whether the destination word is already non-zero
        OR (HL)                          ; $A496  B6
        DEC HL                           ; $A497  2B
        ; destination already set -> leave it alone
        RET NZ                           ; $A498  C0
        LD A,(DE)                        ; $A499  1A
        ; copy low byte of the source word
        LD (HL),A                        ; $A49A  77
        INC DE                           ; $A49B  13
        INC HL                           ; $A49C  23
        LD A,(DE)                        ; $A49D  1A
        ; copy high byte of the source word
        LD (HL),A                        ; $A49E  77
        DEC DE                           ; $A49F  1B
        DEC HL                           ; $A4A0  2B
        RET                              ; $A4A1  C9
; ----------------------------------------------------------------------
; F_CLOSE_HND -- close a file: merge the in-memory FCB into its directory entry (BDOS fn 16).
;   In: CURFCB_PTR ($9F43) -> FCB. Reached from F_CLOSE_H (dispatch fn 16); also used internally to
;       flush an extent.
;   Out: directory entry updated with this FCB's allocation map / record count; result byte set.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: zero the result byte and record state, verify the drive is selected (DRIVE_BIT_TEST)
;              and the FCB S2 high bit is clear; search-first on the extent (15 bytes); if found,
;              merge the FCB's 16-byte allocation map into the entry (filling zero words via
;              FCB_WORD_FILL_IF_ZERO, keeping the larger record count) then flush.
;   [RE] CP/M 2.2 F_CLOSE_HND
; ----------------------------------------------------------------------
F_CLOSE_HND:
        XOR A                            ; $A4A2  AF
        LD (BDOS_RETVAL),A                    ; $A4A3  32 45 9F
        ; clear the directory record counter
        LD (CUR_RECORD),A                    ; $A4A6  32 EA A9
        LD (CUR_RECORD_HI),A                    ; $A4A9  32 EB A9
        ; is the drive logged in?
        CALL DRIVE_BIT_TEST                    ; $A4AC  CD 1E A1
        ; no valid drive -> nothing to close
        RET NZ                           ; $A4AF  C0
        ; read the FCB S2 byte (offset 14)
        CALL FCB_GET_S2                    ; $A4B0  CD 69 A1
        ; high bit = FCB flagged not-to-be-written -> skip
        AND $80                          ; $A4B3  E6 80
        RET NZ                           ; $A4B5  C0
        ; search on 15 bytes (name+type+extent)
        LD C,$0F                         ; $A4B6  0E 0F
        ; search-first for this extent's directory entry
        CALL DIR_SEARCH_FIRST                    ; $A4B8  CD 18 A3
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A4BB  CD F5 A1
        RET Z                            ; $A4BE  C8
        LD BC,$0010                      ; $A4BF  01 10 00
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A4C2  CD 5E A1
        ADD HL,BC                        ; $A4C5  09
        EX DE,HL                         ; $A4C6  EB
        LD HL,(BDOS_PARAM_PTR)                   ; $A4C7  2A 43 9F
        ADD HL,BC                        ; $A4CA  09
        LD C,$10                         ; $A4CB  0E 10
; ----------------------------------------------------------------------
; FCB_MERGE_MAP_LOOP -- merge the FCB allocation map slot-by-slot into the directory entry.
;   In: HL -> entry allocation slot; DE -> FCB allocation slot; C = slots remaining (16).
;   Out: merged allocation map; jumps to FCB_MERGE_DIFF on an 8-bit conflict, else continues.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: per slot, if BLOCK_WIDTH_FLAG selects 16-bit block numbers go word-wise
;              (FCB_MERGE_WORD); else handle an 8-bit block: when the entry slot is zero take the
;              FCB's block, then fall into the byte reconciliation.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_MAP_LOOP:
        ; 0 = 16-bit block numbers, non-zero = 8-bit
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A4CD  3A DD A9
        OR A                             ; $A4D0  B7
        ; 16-bit blocks -> word-wise merge path
        JP Z,FCB_MERGE_WORD                  ; $A4D1  CA E8 A4
        LD A,(HL)                        ; $A4D4  7E
        OR A                             ; $A4D5  B7
        LD A,(DE)                        ; $A4D6  1A
        JP NZ,FCB_MERGE_BYTE_CHECK                 ; $A4D7  C2 DB A4
        ; entry slot empty -> take the FCB's block number
        LD (HL),A                        ; $A4DA  77
; ----------------------------------------------------------------------
; FCB_MERGE_BYTE_CHECK -- reconcile one 8-bit allocation slot between FCB and entry.
;   In: A = FCB block byte; HL -> entry block byte; DE -> FCB block byte.
;   Out: FCB block non-zero -> FCB_MERGE_DIFF (compare); else copy entry block into the FCB, then
;        compare.
;   Clobbers: A,flags
;   Algorithm: if the FCB block byte is non-zero, jump to the compare; otherwise mirror the entry
;              block byte into the FCB so both agree, then fall into the compare.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_BYTE_CHECK:
        OR A                             ; $A4DB  B7
        ; FCB block set -> compare with the entry
        JP NZ,FCB_MERGE_DIFF                 ; $A4DC  C2 E1 A4
        LD A,(HL)                        ; $A4DF  7E
        ; FCB block empty -> copy the entry's block into it
        LD (DE),A                        ; $A4E0  12
; ----------------------------------------------------------------------
; FCB_MERGE_DIFF -- detect a block-map disagreement between FCB and directory entry.
;   In: A = FCB block byte; HL -> entry block byte.
;   Out: if they differ, FCB_DEC_RESULT flags the conflict; else continue (FCB_MERGE_NEXT).
;   Clobbers: A,flags
;   Algorithm: compare the FCB block byte with the entry's; unequal records an error via
;              FCB_DEC_RESULT, otherwise advance to the next slot.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_DIFF:
        ; FCB block vs entry block
        CP (HL)                          ; $A4E1  BE
        ; block maps disagree -> flag conflict
        JP NZ,FCB_DEC_RESULT                 ; $A4E2  C2 1F A5
        JP FCB_MERGE_NEXT                    ; $A4E5  C3 FD A4
; ----------------------------------------------------------------------
; FCB_MERGE_WORD -- merge/compare a 16-bit allocation word for double-byte-block drives.
;   In: HL -> entry word; DE -> FCB word.
;   Out: zero words filled across both directions; on a true word mismatch -> FCB_DEC_RESULT.
;   Clobbers: A,D,E,H,L,flags
;   Algorithm: fill the entry word from the FCB if it was zero, fill the FCB word from the entry if
;              it was zero (FCB_WORD_FILL_IF_ZERO both ways, EX DE,HL between), then compare the two
;              16-bit values byte-by-byte and flag a conflict on inequality.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_WORD:
        ; fill entry word from FCB if entry was zero
        CALL FCB_WORD_FILL_IF_ZERO                    ; $A4E8  CD 94 A4
        EX DE,HL                         ; $A4EB  EB
        ; fill FCB word from entry if FCB was zero
        CALL FCB_WORD_FILL_IF_ZERO                    ; $A4EC  CD 94 A4
        EX DE,HL                         ; $A4EF  EB
        LD A,(DE)                        ; $A4F0  1A
        ; compare low bytes of the two block words
        CP (HL)                          ; $A4F1  BE
        JP NZ,FCB_DEC_RESULT                 ; $A4F2  C2 1F A5
        INC DE                           ; $A4F5  13
        INC HL                           ; $A4F6  23
        LD A,(DE)                        ; $A4F7  1A
        ; compare high bytes of the two block words
        CP (HL)                          ; $A4F8  BE
        JP NZ,FCB_DEC_RESULT                 ; $A4F9  C2 1F A5
        DEC C                            ; $A4FC  0D
; ----------------------------------------------------------------------
; FCB_MERGE_NEXT -- step to the next allocation slot, then finalize the record count.
;   In: DE,HL -> current FCB/entry block bytes; C = slot count remaining.
;   Out: loops to FCB_MERGE_MAP_LOOP until C reaches 0, then reconciles the record-count field and
;        continues to FCB_MERGE_FINISH.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: advance both pointers, decrement the count; while slots remain re-enter the merge
;              loop; when done back up by 20 bytes ($FFEC) to the record-count field and keep the
;              larger of the FCB/entry counts (and the matching S2/extent bytes), then fall into
;              FCB_MERGE_FINISH.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_NEXT:
        INC DE                           ; $A4FD  13
        INC HL                           ; $A4FE  23
        DEC C                            ; $A4FF  0D
        ; more allocation slots -> keep merging
        JP NZ,FCB_MERGE_MAP_LOOP                 ; $A500  C2 CD A4
        ; back up 20 bytes to the record-count field
        LD BC,$FFEC                      ; $A503  01 EC FF
        ADD HL,BC                        ; $A506  09
        EX DE,HL                         ; $A507  EB
        ADD HL,BC                        ; $A508  09
        LD A,(DE)                        ; $A509  1A
        ; compare FCB record count with the entry's
        CP (HL)                          ; $A50A  BE
        ; FCB count smaller -> keep the entry's count
        JP C,FCB_MERGE_FINISH                  ; $A50B  DA 17 A5
        ; FCB count larger -> store it into the entry
        LD (HL),A                        ; $A50E  77
        LD BC,$0003                      ; $A50F  01 03 00
        ADD HL,BC                        ; $A512  09
        EX DE,HL                         ; $A513  EB
        ADD HL,BC                        ; $A514  09
        LD A,(HL)                        ; $A515  7E
        LD (DE),A                        ; $A516  12
; ----------------------------------------------------------------------
; FCB_MERGE_FINISH -- mark the merged entry dirty and flush the directory record.
;   In: merged directory entry in the buffer.
;   Out: dir-changed flag ($A9D2) = $FF; directory record written via FCB_FLUSH_DIR.
;   Clobbers: A,H,L,flags
;   Algorithm: set the 'directory changed' flag and tail-jump to FCB_FLUSH_DIR to commit the record
;              to disk.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_FINISH:
        LD A,$FF                         ; $A517  3E FF
        ; set the directory-changed flag ($FF)
        LD (DIR_DIRTY_FLAG),A                    ; $A519  32 D2 A9
        ; flush the merged entry to the directory sector
        JP FCB_FLUSH_DIR                    ; $A51C  C3 10 A4
; ----------------------------------------------------------------------
; FCB_DEC_RESULT -- record a directory-merge conflict by decrementing the result byte.
;   In: none (operates on the BDOS result byte $9F45).
;   Out: result byte decremented (toward the $FF error code).
;   Clobbers: H,L,flags
;   Algorithm: point at the result byte and decrement it in place to signal the close/merge
;              mismatch.
;   [RE]
; ----------------------------------------------------------------------
FCB_DEC_RESULT:
        ; point at the BDOS result byte
        LD HL,BDOS_RETVAL                     ; $A51F  21 45 9F
        ; decrement to flag the merge conflict
        DEC (HL)                         ; $A522  35
        RET                              ; $A523  C9
; ----------------------------------------------------------------------
; DIR_MAKE_ENTRY -- find a free directory slot and create a new (empty) entry for the FCB.
;   In: CURFCB_PTR ($9F43) -> FCB. Also the core of F_MAKE (F_MAKE_H, dispatch fn 22).
;   Out: a free directory slot located and initialized for this file; returns Z if no slot is free.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: log in the drive, temporarily redirect the FCB pointer to a scratch FCB ($A9AC) and
;              search-first in mode 1 for an empty ($E5) slot, restore the FCB pointer; on success
;              zero 17 bytes of the entry's record/allocation area (from offset 15), clear the S1
;              byte (offset 13), advance the record pointer (RECPTR_INC_STORE), write the new entry
;              (FCB_WRITE_DIR_ENTRY), and set the FCB S2 'written' flag (MARK_FCB_S2_HIGHBIT).
;   [RE] make-directory-entry helper
; ----------------------------------------------------------------------
DIR_MAKE_ENTRY:
        ; log in the drive
        CALL CMD_EXEC_20                    ; $A524  CD 54 A1
        LD HL,(BDOS_PARAM_PTR)                   ; $A527  2A 43 9F
        PUSH HL                          ; $A52A  E5
        ; point at a scratch FCB used to find a free slot
        LD HL,EMPTY_DIR_FCB                     ; $A52B  21 AC A9
        LD (BDOS_PARAM_PTR),HL                   ; $A52E  22 43 9F
        ; search mode 1: locate a free ($E5) directory entry
        LD C,$01                         ; $A531  0E 01
        CALL DIR_SEARCH_FIRST                    ; $A533  CD 18 A3
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A536  CD F5 A1
        POP HL                           ; $A539  E1
        LD (BDOS_PARAM_PTR),HL                   ; $A53A  22 43 9F
        RET Z                            ; $A53D  C8
        EX DE,HL                         ; $A53E  EB
        LD HL,$000F                      ; $A53F  21 0F 00
        ADD HL,DE                        ; $A542  19
        ; 17 bytes of record/allocation area to clear
        LD C,$11                         ; $A543  0E 11
        XOR A                            ; $A545  AF
; ----------------------------------------------------------------------
; DIR_ZERO_ALLOC -- clear the record/allocation bytes of a freshly created directory entry.
;   In: HL -> first byte to clear; C = byte count (17); A = 0.
;   Out: C bytes at HL set to zero.
;   Clobbers: C,H,L,flags
;   Algorithm: store-zero / increment HL / decrement C until the count reaches zero.
;   [RE]
; ----------------------------------------------------------------------
DIR_ZERO_ALLOC:
        LD (HL),A                        ; $A546  77
        INC HL                           ; $A547  23
        DEC C                            ; $A548  0D
        ; loop until all record/allocation bytes are zeroed
        JP NZ,DIR_ZERO_ALLOC                 ; $A549  C2 46 A5
        LD HL,$000D                      ; $A54C  21 0D 00
        ADD HL,DE                        ; $A54F  19
        LD (HL),A                        ; $A550  77
        CALL RECPTR_INC_STORE                    ; $A551  CD 8C A1
        CALL FCB_WRITE_DIR_ENTRY                    ; $A554  CD FD A3
        JP MARK_FCB_S2_HIGHBIT                      ; $A557  C3 78 A1
; ----------------------------------------------------------------------
; FCB_ADVANCE_RECORD -- advance the FCB to the next record/extent for sequential write.
;   In: CURFCB_PTR ($9F43) -> open FCB.
;   Out: FCB current-record / extent fields stepped; new extent opened or created as needed.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: clear the dir-changed flag, flush the current extent (F_CLOSE_HND via F_CLOSE_HND), bump the
;              FCB current-record byte (offset 12) and wrap it mod 32; on wrap go open the next
;              extent (FCB_NEXT_EXTENT); otherwise check the extent mask (EXM at $A9C5) and the
;              dir-changed flag to decide between re-opening the current extent or merging the
;              just-flushed one.
;   [RE] sequential-write record/extent advance
; ----------------------------------------------------------------------
FCB_ADVANCE_RECORD:
        XOR A                            ; $A55A  AF
        ; clear the directory-changed flag
        LD (DIR_DIRTY_FLAG),A                    ; $A55B  32 D2 A9
        ; close/flush the current extent first
        CALL F_CLOSE_HND                    ; $A55E  CD A2 A4
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A561  CD F5 A1
        RET Z                            ; $A564  C8
        LD HL,(BDOS_PARAM_PTR)                   ; $A565  2A 43 9F
        ; FCB offset 12 = current-record byte
        LD BC,$000C                      ; $A568  01 0C 00
        ADD HL,BC                        ; $A56B  09
        LD A,(HL)                        ; $A56C  7E
        INC A                            ; $A56D  3C
        ; wrap the current record mod 32 (128 records/extent)
        AND $1F                          ; $A56E  E6 1F
        LD (HL),A                        ; $A570  77
        ; record wrapped -> move to the next extent
        JP Z,FCB_NEXT_EXTENT                  ; $A571  CA 83 A5
        LD B,A                           ; $A574  47
        ; load the extent mask (EXM)
        LD A,(DPB_EXM)                    ; $A575  3A C5 A9
        AND B                            ; $A578  A0
        LD HL,DIR_DIRTY_FLAG                     ; $A579  21 D2 A9
        AND (HL)                         ; $A57C  A6
        JP Z,FCB_OPEN_NEXT_EXTENT                  ; $A57D  CA 8E A5
        JP FCB_MERGE_FOUND_EXTENT                    ; $A580  C3 AC A5
; ----------------------------------------------------------------------
; FCB_NEXT_EXTENT -- step the FCB to the next extent when the record count wraps.
;   In: HL -> FCB current-record byte; FCB extent fields follow.
;   Out: extent byte (offset 14) incremented; low-nibble rollover branches to finish.
;   Clobbers: A,B,C,H,L,flags
;   Algorithm: advance HL by 2 to the extent byte (offset 14), increment it; if its low nibble is
;              now zero a module of extents has rolled over and control goes to DISK_FINISH_OK;
;              otherwise fall into the open-next-extent path.
;   [RE]
; ----------------------------------------------------------------------
FCB_NEXT_EXTENT:
        ; step from record byte (12) to the extent byte (14)
        LD BC,$0002                      ; $A583  01 02 00
        ADD HL,BC                        ; $A586  09
        ; advance to the next extent
        INC (HL)                         ; $A587  34
        LD A,(HL)                        ; $A588  7E
        ; low nibble = extent within the current entry group
        AND $0F                          ; $A589  E6 0F
        ; extent group rolled over -> finish
        JP Z,DISK_FINISH_OK                  ; $A58B  CA B6 A5
; ----------------------------------------------------------------------
; FCB_OPEN_NEXT_EXTENT -- search the directory for the FCB's next extent, creating it if absent.
;   In: CURFCB_PTR ($9F43) -> FCB positioned at the next extent; the read/write direction flag in
;       $A9D3.
;   Out: the extent opened (merged into the FCB) or a new entry created; result set.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: search-first on 15 bytes for the extent; if found go merge it
;              (FCB_MERGE_FOUND_EXTENT); else, when the direction flag is not $FF (i.e. a write),
;              make a new directory entry (DIR_MAKE_ENTRY); on a read (or no free slot) take the
;              disk-finish/error path.
;   [RE]
; ----------------------------------------------------------------------
FCB_OPEN_NEXT_EXTENT:
        ; search on 15 bytes (name+type+extent)
        LD C,$0F                         ; $A58E  0E 0F
        ; search-first for the next extent
        CALL DIR_SEARCH_FIRST                    ; $A590  CD 18 A3
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A593  CD F5 A1
        ; extent exists -> merge it into the FCB
        JP NZ,FCB_MERGE_FOUND_EXTENT                 ; $A596  C2 AC A5
        LD A,(RW_DIRECTION_FLAG)                    ; $A599  3A D3 A9
        INC A                            ; $A59C  3C
        JP Z,DISK_FINISH_OK                  ; $A59D  CA B6 A5
        ; no extent -> make a new directory entry
        CALL DIR_MAKE_ENTRY                    ; $A5A0  CD 24 A5
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A5A3  CD F5 A1
        JP Z,DISK_FINISH_OK                  ; $A5A6  CA B6 A5
        JP FCB_FINISH_NEW_EXTENT                    ; $A5A9  C3 AF A5
; ----------------------------------------------------------------------
; FCB_MERGE_FOUND_EXTENT -- merge a located directory extent back into the FCB.
;   In: a successful search result for the extent; CURFCB_PTR ($9F43) -> FCB.
;   Out: FCB's record/size fields updated from the entry; then falls into FCB_FINISH_NEW_EXTENT
;        (refresh fields, return 0).
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: merge the matched extent into the FCB (FILE_SIZE_FROM_EXTENT), then fall through into
;              FCB_FINISH_NEW_EXTENT which refreshes the working fields and returns success.
;   [RE]
; ----------------------------------------------------------------------
FCB_MERGE_FOUND_EXTENT:
        ; merge the matched extent and set the FCB record count, then fall into
        ; FCB_FINISH_NEW_EXTENT
        CALL FILE_SIZE_FROM_EXTENT                    ; $A5AC  CD 5A A4
; ----------------------------------------------------------------------
; FCB_FINISH_NEW_EXTENT -- finish opening a newly created extent and return OK.
;   In: a new directory entry just made for the FCB.
;   Out: FCB working fields refreshed; BDOS result = 0.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: refresh the FCB drive/extent fields (DRV_INSTALL_RWTS_3) and return success (0).
;   [RE]
; ----------------------------------------------------------------------
FCB_FINISH_NEW_EXTENT:
        ; refresh the FCB drive/extent working fields
        CALL DRV_INSTALL_RWTS_3                    ; $A5AF  CD BB A0
        XOR A                            ; $A5B2  AF
        ; return success (0)
        JP BDOS_RET_RESULT                   ; $A5B3  C3 01 9F
; ----------------------------------------------------------------------
; DISK_FINISH_OK -- finalize the BDOS result and set the FCB written flag.
;   In: directory/record operation just completed.
;   Out: BDOS result finalized (BDOS_RET_ONE); FCB S2 'written' bit set.
;   Clobbers: A,H,L,flags
;   Algorithm: run the common result-finalizer (BDOS_RET_ONE) then tail-jump to MARK_FCB_S2_HIGHBIT
;              to set the FCB S2 high bit (mark written) and return.
;   [RE]
; ----------------------------------------------------------------------
DISK_FINISH_OK:
        ; finalize the BDOS result for the operation
        CALL BDOS_RET_ONE                    ; $A5B6  CD 05 9F
        ; set the FCB S2 'written' flag and return
        JP MARK_FCB_S2_HIGHBIT                      ; $A5B9  C3 78 A1
; ----------------------------------------------------------------------
; FILE_READ_SEQ -- sequential read of one record into the DMA buffer (BDOS fn 20).
;   In: CURFCB_PTR ($9F43) -> open FCB. Reached from F_READ_H (dispatch fn 20).
;   Out: requested record read; BDOS result reflects success/EOF.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: set the sequential/random mode flag $A9D5=1 (1 = sequential; the random-read path
;              BDOS_SEEK_NOREAD sets it 0) then fall into the shared read core (FILE_READ_RECORD).
;   [RE] CP/M 2.2 sequential read entry
; ----------------------------------------------------------------------
FILE_READ_SEQ:
        ; mode = 1 (sequential read)
        LD A,$01                         ; $A5BC  3E 01
        ; store the sequential/random mode flag (1=sequential)
        LD (WRITE_TYPE_FLAG),A                    ; $A5BE  32 D5 A9
; ----------------------------------------------------------------------
; FILE_READ_RECORD -- read the FCB's current record into the DMA buffer (shared read core).
;   In: CURFCB_PTR ($9F43) -> open FCB; record/extent fields set. Shared by sequential
;       (FILE_READ_SEQ) and random read.
;   Out: the record's sector read and de-blocked to the DMA address; result = 0/error.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: set the direction flag $A9D3=$FF (read), refresh the FCB working fields, compare the
;              current record ($A9E3) against the extent's record count ($A9E1); if at the $80
;              boundary advance to the next extent (FCB_ADVANCE_RECORD), else translate the record
;              to a physical sector and read it.
;   [RE] CP/M 2.2 read core
; ----------------------------------------------------------------------
FILE_READ_RECORD:
        ; direction = read
        LD A,$FF                         ; $A5C1  3E FF
        ; store the read/write direction flag ($FF=read)
        LD (RW_DIRECTION_FLAG),A                    ; $A5C3  32 D3 A9
        ; refresh the FCB drive/extent working fields
        CALL DRV_INSTALL_RWTS_3                    ; $A5C6  CD BB A0
        LD A,(FCB_CURREC)                    ; $A5C9  3A E3 A9
        LD HL,FCB_RECCOUNT                     ; $A5CC  21 E1 A9
        CP (HL)                          ; $A5CF  BE
        JP C,FILE_READ_DO_SECTOR                  ; $A5D0  DA E6 A5
        ; record at the $80 boundary = extent boundary / EOF
        CP $80                           ; $A5D3  FE 80
        JP NZ,FILE_READ_ERROR                 ; $A5D5  C2 FB A5
        CALL FCB_ADVANCE_RECORD                    ; $A5D8  CD 5A A5
        XOR A                            ; $A5DB  AF
        LD (FCB_CURREC),A                    ; $A5DC  32 E3 A9
        LD A,(BDOS_RETVAL)                    ; $A5DF  3A 45 9F
        OR A                             ; $A5E2  B7
        JP NZ,FILE_READ_ERROR                 ; $A5E3  C2 FB A5
; ----------------------------------------------------------------------
; FILE_READ_DO_SECTOR -- translate the record to a sector and read it into the DMA buffer.
;   In: FCB working fields set; record within the current extent.
;   Out: the physical sector read and de-blocked into the DMA address.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: compute block/sector/track from the record (DISK_STORE_SEC_TRK_14/16/17); if no block
;              is allocated take the read-error path; otherwise read the sector through the
;              deblocking buffer and return via the BIOS read tail (DRV_INSTALL_RWTS_6).
;   [RE]
; ----------------------------------------------------------------------
FILE_READ_DO_SECTOR:
        ; compute the block number for this record
        CALL DISK_STORE_SEC_TRK_14                    ; $A5E6  CD 77 A0
        CALL DISK_STORE_SEC_TRK_16                    ; $A5E9  CD 84 A0
        ; no allocated block -> read error / unwritten
        JP Z,FILE_READ_ERROR                  ; $A5EC  CA FB A5
        ; compute the physical sector/track
        CALL DISK_STORE_SEC_TRK_17                    ; $A5EF  CD 8A A0
        CALL RECORD_TO_TRACK                    ; $A5F2  CD D1 9F
        CALL DISK_READ_CHECKED                    ; $A5F5  CD B2 9F
        ; perform the BIOS sector read and return
        JP DRV_INSTALL_RWTS_6                      ; $A5F8  C3 D2 A0
; ----------------------------------------------------------------------
; FILE_READ_ERROR -- return a read error / unwritten-record result.
;   In: none.
;   Out: BDOS result set to the error code via BDOS_RET_ONE.
;   Clobbers: A,flags
;   Algorithm: tail-jump to the common error-result setter.
;   [RE]
; ----------------------------------------------------------------------
FILE_READ_ERROR:
        ; return the BDOS read error code
        JP BDOS_RET_ONE                      ; $A5FB  C3 05 9F
; ----------------------------------------------------------------------
; FILE_WRITE_SEQ -- sequential write of one record from the DMA buffer (BDOS fn 21).
;   In: CURFCB_PTR ($9F43) -> FCB; DMA buffer holds the record. Reached from F_WRITE_H (dispatch fn
;       21).
;   Out: enters the write core; record written, blocks allocated as needed; result set.
;   Clobbers: A,B,C,D,E,H,L,flags
;   Algorithm: set the sequential/random mode flag $A9D5=1 (1 = sequential) then fall into the
;              shared write core (at $A603, which clears the direction flag, logs in, allocates a
;              block when the record is new, translates to a sector, and writes).
;   [RE] CP/M 2.2 sequential write entry
; ----------------------------------------------------------------------
FILE_WRITE_SEQ:
        ; mode = 1 (sequential write)
        LD A,$01                         ; $A5FE  3E 01
        ; store the sequential/random mode flag (1=sequential)
        LD (WRITE_TYPE_FLAG),A                    ; $A600  32 D5 A9
; ----------------------------------------------------------------------
; BDOS_WRITE -- BDOS WRITE primitive (CP/M 2.2 fn 21 F_WRITE / fn 34 F_WRITERAND / fn 40 F_WRITEZF
; target). Write the current record of the open file, allocating and deblocking disk blocks as
; needed.
;   In: CURFCB (BDOS_PARAM_PTR) -> active FCB; the BDOS work cells for current-record (FCB_CURREC) /
;       record-count (FCB_RECCOUNT) have been primed from the FCB by DRV_INSTALL_RWTS_3; DMA holds the
;       caller's record; WRITE_TYPE_FLAG = write type (1 = sequential, 2 = random); BDOS_RETVAL = seek
;       create/extend mode flag.
;   Out: A = BDOS return code (0 = OK, 2 = disk full); status returned through BDOS_RET_RESULT; FCB
;        allocation map / record count updated; host sector written. (OBSERVED: only the disk-full=2
;        path is taken here; other error codes come from sub-routines.)
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: clear the directory-update flag (RW_DIRECTION_FLAG); fetch the current record index and reject
;              it if >= 128 (extent full). Compute the FCB allocation-map SLOT for this record and
;              read the block number already stored there: if it is non-zero the block is already
;              allocated, so branch straight to the write phase. If it is zero, recompute the slot
;              index, fetch the block stored in the PREVIOUS slot as an allocation hint, then call
;              the disk-map allocator (ALLOC_GET_BLOCK) to grab a fresh block. Store the (new or
;              existing) block number into the FCB allocation slot, then perform the physical write
;              and update the extent record count. Mirrors the standard CP/M 2.2 BDOS write routine.
;              [RE]
; ----------------------------------------------------------------------
BDOS_WRITE:
        ; Clear the directory-update-needed flag (RW_DIRECTION_FLAG) before starting this write.
        LD A,$00                         ; $A603  3E 00
        LD (RW_DIRECTION_FLAG),A                    ; $A605  32 D3 A9
        ; Drive read-only / select check (raises a BDOS error overlay if the drive is not writable).
        CALL CMD_EXEC_20                    ; $A608  CD 54 A1
        ; HL = pointer to the active FCB (CURFCB).
        LD HL,(BDOS_PARAM_PTR)                   ; $A60B  2A 43 9F
        CALL CHECK_DIRENT_READONLY_INNER                    ; $A60E  CD 47 A1
        CALL DRV_INSTALL_RWTS_3                    ; $A611  CD BB A0
        ; Load the current record number within the extent (primed from the FCB).
        LD A,(FCB_CURREC)                    ; $A614  3A E3 A9
        ; Record index 128 means the extent is full -> cannot write, report error.
        CP $80                           ; $A617  FE 80
        ; Extent full / index out of range: bail to the BDOS error path.
        JP NC,BDOS_RET_ONE                   ; $A619  D2 05 9F
        CALL DISK_STORE_SEC_TRK_14                    ; $A61C  CD 77 A0
        CALL DISK_STORE_SEC_TRK_16                    ; $A61F  CD 84 A0
        ; C = 0: existing-block write mode (no zero-fill); used only if the block is already
        ; allocated.
        LD C,$00                         ; $A622  0E 00
        ; Block already allocated (slot held a non-zero block) -> skip allocation, go to the write
        ; phase.
        JP NZ,BDOS_WRITE_PHASE                 ; $A624  C2 6E A6
        ; Recompute the FCB allocation-map slot index for the current record (A = slot index, NOT a
        ; disk block).
        CALL DISK_STORE_SEC_TRK_6                    ; $A627  CD 3E A0
        ; Save the allocation-slot index for use when storing the new block number.
        LD (ALLOC_SLOT_INDEX),A                    ; $A62A  32 D7 A9
        LD BC,$0000                      ; $A62D  01 00 00
        OR A                             ; $A630  B7
        ; Slot index 0 (first slot) -> skip the previous-slot fetch; go allocate a fresh block.
        JP Z,BDOS_WRITE_ALLOCBLK                  ; $A631  CA 3B A6
        LD C,A                           ; $A634  4F
        DEC BC                           ; $A635  0B
        ; Fetch the block stored in the PREVIOUS slot (BC = slot-1) as the allocation starting hint
        ; -> HL.
        CALL DISK_STORE_SEC_TRK_10                    ; $A636  CD 5E A0
        LD B,H                           ; $A639  44
        LD C,L                           ; $A63A  4D
; ----------------------------------------------------------------------
; BDOS_WRITE_ALLOCBLK -- allocate a fresh data block from the disk allocation vector, or return
; 'disk full'.
;   In: BC = allocation hint (block from the previous slot, or 0); CURFCB context valid.
;   Out: on success HL = newly allocated block number and control falls into BDOS_WRITE_STOREBLK; on
;        no free block, returns A=2 (disk full) via BDOS_RET_RESULT.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: call the disk-map allocator ALLOC_GET_BLOCK, which scans the drive allocation bitmap
;              (up to MAX_BLOCK_DSM), marks a free block in use and returns HL = its block number
;              (HL = 0 when the disk is full). If HL is zero, set A=2 and return the disk-full
;              status; otherwise fall through to record the new block in the FCB. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_ALLOCBLK:
        ; Allocate a fresh block from the drive allocation bitmap; HL = new block number (0 = disk
        ; full).
        CALL ALLOC_GET_BLOCK                    ; $A63B  CD BE A3
        LD A,L                           ; $A63E  7D
        ; Test HL for zero (no free block was found).
        OR H                             ; $A63F  B4
        ; Non-zero block: proceed to record it in the FCB.
        JP NZ,BDOS_WRITE_STOREBLK                 ; $A640  C2 48 A6
        ; A = 2: disk-full return code.
        LD A,$02                         ; $A643  3E 02
        ; Return disk-full status to the caller.
        JP BDOS_RET_RESULT                   ; $A645  C3 01 9F
; ----------------------------------------------------------------------
; BDOS_WRITE_STOREBLK -- store the (new or existing) block number into the FCB allocation slot for
; the current record.
;   In: HL = block number; CURFCB (BDOS_PARAM_PTR) = active FCB; ALLOC_SLOT_INDEX = allocation-slot index
;       within the extent; BLOCK_WIDTH_FLAG selects 1-byte vs 2-byte block entries.
;   Out: FCB allocation map updated with the block number at the computed slot.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: save the block number to CUR_BLOCK_NUMBER (for the write phase) into DE; point HL at the FCB
;              allocation map (FCB+16); read the slot index. If BLOCK_WIDTH_FLAG selects 8-bit
;              blocks, add the slot index to HL (via DIRENT_PTR_ADD) and store one byte; otherwise
;              jump to the 16-bit store path. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_STOREBLK:
        ; Save the block number for the write phase (host record/sector base).
        LD (CUR_BLOCK_NUMBER),HL                   ; $A648  22 E5 A9
        EX DE,HL                         ; $A64B  EB
        LD HL,(BDOS_PARAM_PTR)                   ; $A64C  2A 43 9F
        ; Offset 16 = start of the allocation/disk-map area inside the FCB.
        LD BC,$0010                      ; $A64F  01 10 00
        ADD HL,BC                        ; $A652  09
        ; Test whether the drive uses 8-bit (small disk) or 16-bit block numbers.
        LD A,(BLOCK_WIDTH_FLAG)                    ; $A653  3A DD A9
        OR A                             ; $A656  B7
        ; A = allocation-slot index within the FCB extent.
        LD A,(ALLOC_SLOT_INDEX)                    ; $A657  3A D7 A9
        ; 16-bit-block-number drive: store the block number as a 2-byte entry.
        JP Z,BDOS_WRITE_STOREBLK16                  ; $A65A  CA 64 A6
        ; Add the slot index to HL = address of the single-byte slot inside the FCB map.
        CALL DIRENT_PTR_ADD                    ; $A65D  CD 64 A1
        ; Store the low byte (8-bit block number) into the FCB slot.
        LD (HL),E                        ; $A660  73
        JP BDOS_WRITE_NEWBLK                    ; $A661  C3 6C A6
; ----------------------------------------------------------------------
; BDOS_WRITE_STOREBLK16 -- store a 16-bit block number into the FCB allocation map (large-disk
; format).
;   In: HL = FCB allocation-map base (FCB+16); A = slot index; DE = block number.
;   Out: the 2-byte block number written at FCB+16 + slot*2 (low byte then high byte).
;   Clobbers: A, BC, HL, flags.
;   Algorithm: extend the slot index to BC, add it to HL twice (slot*2 byte offset), then store DE
;              low/high. Falls through to the write phase. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_STOREBLK16:
        ; BC = slot index.
        LD C,A                           ; $A664  4F
        LD B,$00                         ; $A665  06 00
        ; Add slot index twice (this is the first add) => byte offset = slot*2 for 16-bit entries.
        ADD HL,BC                        ; $A667  09
        ADD HL,BC                        ; $A668  09
        ; Store block-number low byte.
        LD (HL),E                        ; $A669  73
        INC HL                           ; $A66A  23
        ; Store block-number high byte.
        LD (HL),D                        ; $A66B  72
; ----------------------------------------------------------------------
; BDOS_WRITE_NEWBLK -- mark this write as 'new block, must zero-fill' before the write phase.
;   In: control reaches here after a freshly allocated block was recorded in the FCB.
;   Out: C = 2, signalling the write phase to zero-fill the unwritten records of the new block.
;   Clobbers: C.
;   Algorithm: set C=2 (new-block write mode) and fall into the write phase. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_NEWBLK:
        ; C = 2: new-block write mode (the block was just allocated, zero-fill it).
        LD C,$02                         ; $A66C  0E 02
; ----------------------------------------------------------------------
; BDOS_WRITE_PHASE -- perform the physical write of the current record, honoring the
; deblocking/new-block mode.
;   In: C = write mode (0 = existing block, 2 = new block); CURFCB context valid; DMA holds the
;       caller's record; BDOS_RETVAL = seek create/extend mode flag (00 / FF); WRITE_TYPE_FLAG = BDOS write
;       type (1 = sequential, 2 = random).
;   Out: host sector updated on disk; control merges into the post-write record-count update;
;        returns early if the create/extend flag is set.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: load BDOS_RETVAL; if it is non-zero (a create/extend was flagged) return so the
;              caller can handle it. Otherwise save the mode, compute the host record/sector
;              (DISK_STORE_SEC_TRK_17), and branch on write type: random data writes (type 2) go
;              directly; sequential writes of a fresh block (mode 2) first zero-fill the
;              directory/work buffer and write its records up to the host-sector boundary.
;              (OBSERVED: BDOS_RETVAL is the same cell the seek code sets to its phase value;
;              calling it a 'host-buffer' flag is not supported -- it is the seek/create mode cell.)
;              [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_PHASE:
        ; Load the seek create/extend mode flag (BDOS_RETVAL; 00 = normal, FF = create/extend
        ; pending).
        LD A,(BDOS_RETVAL)                    ; $A66E  3A 45 9F
        OR A                             ; $A671  B7
        ; Create/extend flagged (BDOS_RETVAL != 0) -> return to the caller without writing here.
        RET NZ                           ; $A672  C0
        ; Preserve the write-mode byte (C) across the sector computation.
        PUSH BC                          ; $A673  C5
        ; Compute the host physical record index/sector for the current logical record.
        CALL DISK_STORE_SEC_TRK_17                    ; $A674  CD 8A A0
        ; Load the BDOS write type (1 = sequential, 2 = random).
        LD A,(WRITE_TYPE_FLAG)                    ; $A677  3A D5 A9
        DEC A                            ; $A67A  3D
        DEC A                            ; $A67B  3D
        ; Write type != 2 (sequential) -> may need the new-block zero-fill path.
        JP NZ,BDOS_WRITE_DOWRITE                 ; $A67C  C2 BB A6
        POP BC                           ; $A67F  C1
        PUSH BC                          ; $A680  C5
        ; A = write mode (was the block freshly allocated?).
        LD A,C                           ; $A681  79
        DEC A                            ; $A682  3D
        DEC A                            ; $A683  3D
        ; Existing block (mode != 2): write directly, no zero-fill.
        JP NZ,BDOS_WRITE_DOWRITE                 ; $A684  C2 BB A6
        PUSH HL                          ; $A687  E5
        ; HL = directory/work buffer to be zero-filled before the new-block write.
        LD HL,(DIRBUF_PTR)                   ; $A688  2A B9 A9
        ; D = 0: byte counter for the 128-byte fill loop.
        LD D,A                           ; $A68B  57
; ----------------------------------------------------------------------
; BDOS_WRITE_ZEROFILL -- zero-fill one 128-byte record buffer for a freshly allocated block.
;   In: HL = buffer start; A = 0 (fill value); D = 0 (loop counter).
;   Out: 128 bytes from HL cleared to 0; HL advanced past the buffer.
;   Clobbers: A(=0), D, HL, flags.
;   Algorithm: store 0, advance HL, INC D and loop while the sign flag stays clear (D < 128), i.e.
;              128 iterations (0..127). Clears the work buffer before writing fresh records into a
;              new block. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_ZEROFILL:
        ; Store 0 into the buffer byte.
        LD (HL),A                        ; $A68C  77
        INC HL                           ; $A68D  23
        ; Advance the 0..127 fill counter.
        INC D                            ; $A68E  14
        ; Loop while D < 128 (sign clear): fill all 128 record bytes.
        JP P,BDOS_WRITE_ZEROFILL                  ; $A68F  F2 8C A6
        ; Point the DMA at the deblocking/host buffer for the fill writes.
        CALL SET_DMA_TO_DISK_BUF                    ; $A692  CD E0 A1
        ; HL = base host record index for this block's fill.
        LD HL,(BLOCK_BASE_RECORD)                   ; $A695  2A E7 A9
        LD C,$02                         ; $A698  0E 02
; ----------------------------------------------------------------------
; BDOS_WRITE_FILLLOOP -- write the zero-filled records of a new block up to the host-sector
; boundary.
;   In: HL = current host record index; C = 2 (mode); deblock DMA already pointed at the fill
;       buffer.
;   Out: the records spanning the host sector written; loops until the record index crosses the
;        host-sector mask boundary.
;   Clobbers: A, BC, HL, flags.
;   Algorithm: save the record index (CUR_BLOCK_NUMBER), translate/seek the host sector (RECORD_TO_TRACK),
;              write it (DISK_WRITE_CHECKED), reload the index and mask it with the
;              records-per-host-sector mask (DPB_BLM); INC the index and loop until the masked value
;              differs (host-sector boundary reached). Then restore the saved record index and
;              finalize via RESTORE_USER_DMA. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_FILLLOOP:
        ; Save the working host-record index.
        LD (CUR_BLOCK_NUMBER),HL                   ; $A69A  22 E5 A9
        PUSH BC                          ; $A69D  C5
        ; Translate/seek the host track+sector for this record.
        CALL RECORD_TO_TRACK                    ; $A69E  CD D1 9F
        POP BC                           ; $A6A1  C1
        ; Write the (zeroed) record to the host sector via the BIOS R/W call.
        CALL DISK_WRITE_CHECKED                    ; $A6A2  CD B8 9F
        LD HL,(CUR_BLOCK_NUMBER)                   ; $A6A5  2A E5 A9
        LD C,$00                         ; $A6A8  0E 00
        ; Load the records-per-host-sector mask.
        LD A,(DPB_BLM)                    ; $A6AA  3A C4 A9
        LD B,A                           ; $A6AD  47
        ; Mask the record index to its position within the host sector.
        AND L                            ; $A6AE  A5
        ; Compare against the host-sector base value (still inside this host sector?).
        CP B                             ; $A6AF  B8
        INC HL                           ; $A6B0  23
        ; Loop while still within the same host sector (fill all its records).
        JP NZ,BDOS_WRITE_FILLLOOP                 ; $A6B1  C2 9A A6
        POP HL                           ; $A6B4  E1
        LD (CUR_BLOCK_NUMBER),HL                   ; $A6B5  22 E5 A9
        ; Restore the caller DMA and finalize the new-block fill.
        CALL RESTORE_USER_DMA                    ; $A6B8  CD DA A1
; ----------------------------------------------------------------------
; BDOS_WRITE_DOWRITE -- write the caller's current record to its host sector and bump the extent
; record count.
;   In: stack holds the mode byte; CURFCB context valid; DMA = caller record.
;   Out: record written; FCB current-record-count cell (FCB_RECCOUNT) advanced when this record extends
;        the extent; C=2 if the count grew; falls into the S2/extent-overflow update.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: translate/seek (RECORD_TO_TRACK) and write (DISK_WRITE_CHECKED) the record; compare
;              the just-written record index (FCB_CURREC) against the extent's stored record count
;              (FCB_RECCOUNT); if it is a new high-water record, store and increment the count and set C=2
;              (extent grew). [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_DOWRITE:
        ; Translate/seek the host track+sector for the current record.
        CALL RECORD_TO_TRACK                    ; $A6BB  CD D1 9F
        POP BC                           ; $A6BE  C1
        PUSH BC                          ; $A6BF  C5
        ; Write the caller's record to the host sector via the BIOS R/W call.
        CALL DISK_WRITE_CHECKED                    ; $A6C0  CD B8 9F
        POP BC                           ; $A6C3  C1
        ; A = the record index just written within the extent.
        LD A,(FCB_CURREC)                    ; $A6C4  3A E3 A9
        ; HL -> the extent's current record-count cell (FCB_RECCOUNT).
        LD HL,FCB_RECCOUNT                     ; $A6C7  21 E1 A9
        ; Is the written record beyond the current record count?
        CP (HL)                          ; $A6CA  BE
        ; Record is within the existing count -> no count update needed.
        JP C,BDOS_WRITE_S2UPDATE                  ; $A6CB  DA D2 A6
        ; Extent grew: store the new record index as the count...
        LD (HL),A                        ; $A6CE  77
        ; ...and bump it (count = index + 1).
        INC (HL)                         ; $A6CF  34
        ; C = 2: signal the extent record count was extended.
        LD C,$02                         ; $A6D0  0E 02
; ----------------------------------------------------------------------
; BDOS_WRITE_S2UPDATE -- refresh the FCB S2 byte and, at end-of-extent, advance the FCB to the next
; extent.
;   In: A = current record/extent state; CURFCB context valid; WRITE_TYPE_FLAG = write type.
;   Out: FCB S2 byte stored with its high bit cleared; on extent rollover (record index 0x7F with
;        sequential write) the record count is written back and the FCB moves to the next extent;
;        otherwise takes the common return.
;   Clobbers: A, BC, HL, flags.
;   Algorithm: (two leading NOPs are padding). Fetch the FCB S2 byte (FCB_GET_S2), clear its high
;              bit and store it back. If the just-written record was the last in the extent (0x7F)
;              AND this is a sequential write (WRITE_TYPE_FLAG == 1), copy the working record count back into
;              the FCB (DRV_INSTALL_RWTS_6) and advance to the next extent (FCB_ADVANCE_RECORD); if
;              no host buffer write is pending, reset the current-record cell; else take the common
;              return. (OBSERVED: the LD HL,$9400 at entry is immediately overwritten by FCB_GET_S2
;              -- it loads no value that is used.) [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_S2UPDATE:
        NOP                              ; $A6D2  00
        NOP                              ; $A6D3  00
        ; Vestigial load of the BDOS base ($9400) -- HL is immediately overwritten by FCB_GET_S2
        ; below; value unused.
        LD HL,CCP_ENTRY                     ; $A6D4  21 00 94
        PUSH AF                          ; $A6D7  F5
        ; HL -> the FCB S2 (extent-module) byte; A = its value.
        CALL FCB_GET_S2                    ; $A6D8  CD 69 A1
        ; Clear the high (modified/in-use) bit of the S2 byte.
        AND $7F                          ; $A6DB  E6 7F
        ; Store the updated S2 byte back into the FCB.
        LD (HL),A                        ; $A6DD  77
        POP AF                           ; $A6DE  F1
        ; Was the just-written record the last (index 0x7F) of the extent?
        CP $7F                           ; $A6DF  FE 7F
        ; Not at end of extent -> done, take the common return.
        JP NZ,BDOS_WRITE_RET                ; $A6E1  C2 00 A7
        ; Load the BDOS write type.
        LD A,(WRITE_TYPE_FLAG)                    ; $A6E4  3A D5 A9
        ; Only sequential writes (type 1) roll the extent forward here.
        CP $01                           ; $A6E7  FE 01
        ; Random write at extent end -> done, common return.
        JP NZ,BDOS_WRITE_RET                ; $A6E9  C2 00 A7
        ; Copy the working record count (FCB_CURREC/FCB_RECCOUNT) back into the FCB before rolling over.
        CALL DRV_INSTALL_RWTS_6                    ; $A6EC  CD D2 A0
        ; Advance the FCB to the next extent (increment EX, handle module overflow).
        CALL FCB_ADVANCE_RECORD                    ; $A6EF  CD 5A A5
        LD HL,BDOS_RETVAL                     ; $A6F2  21 45 9F
        LD A,(HL)                        ; $A6F5  7E
        OR A                             ; $A6F6  B7
        JP NZ,BDOS_WRITE_RESETREC                ; $A6F7  C2 FE A6
        DEC A                            ; $A6FA  3D
        LD (FCB_CURREC),A                    ; $A6FB  32 E3 A9
; ----------------------------------------------------------------------
; BDOS_WRITE_RESETREC -- clear the seek/create-mode flag cell after an extent rollover.
;   In: HL -> the BDOS_RETVAL flag cell.
;   Out: that flag cell cleared to 0.
;   Clobbers: (memory only).
;   Algorithm: store 0 through HL to reset the BDOS_RETVAL flag, then fall into the common return.
;              [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_RESETREC:
        ; Clear the BDOS_RETVAL seek/create-mode flag for the new extent.
        LD (HL),$00                      ; $A6FE  36 00
; ----------------------------------------------------------------------
; BDOS_WRITE_RET -- common exit of the WRITE primitive.
;   In: write completed (or no further action needed).
;   Out: tail-jumps to DRV_INSTALL_RWTS_6, which copies the working record/count back into the FCB
;        and returns to the BDOS dispatcher.
;   Clobbers: per the tail routine.
;   Algorithm: tail-jump to the record-count writeback routine. [RE]
; ----------------------------------------------------------------------
BDOS_WRITE_RET:
        ; Copy the working record/count back into the FCB and return via the shared tail.
        JP DRV_INSTALL_RWTS_6                      ; $A700  C3 D2 A0
; ----------------------------------------------------------------------
; BDOS_SEEK_NOREAD -- SEEK entry that clears the write-type cell, then computes/positions the target
; extent.
;   In: CURFCB (BDOS_PARAM_PTR) valid.
;   Out: as for BDOS_SEEK_COMPUTE below.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: clear the write-type cell (WRITE_TYPE_FLAG = 0), then fall straight into BDOS_SEEK_COMPUTE.
;              (OBSERVED: this entry is used by the random read/write callers
;              FCB_EXTENT_TO_TRKSEC_8/9 after they set C; BDOS_SEEK_NOREAD itself does not consume C
;              -- it is merely preserved on the stack across the seek and used by the caller
;              afterward.) [RE]
; ----------------------------------------------------------------------
BDOS_SEEK_NOREAD:
        XOR A                            ; $A703  AF
        ; Write type = 0 (cleared before the seek).
        LD (WRITE_TYPE_FLAG),A                    ; $A704  32 D5 A9
; ----------------------------------------------------------------------
; BDOS_SEEK_COMPUTE -- compute the target extent/record from the FCB random-record field (R0/R1/R2)
; and seek the directory to it.
;   In: CURFCB (BDOS_PARAM_PTR) -> FCB whose random-record bytes (FCB+33..35 = R0/R1/R2) hold the
;       desired record; BDOS_RETVAL = create/extend mode flag.
;   Out: B = target S2 (module), C = target extent-within-entry; if the FCB is already positioned
;        there, returns OK (A=0) via BDOS_RET_RESULT; else repositions the directory; on R2 != 0
;        returns record-out-of-range. (OBSERVED: BC is also just preserved on the stack for the
;        calling read/write routine.)
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: read R0 and combine with R1 into the 16-bit record number. record-within-extent = R0
;              & 0x7F; extent = ((R1 << 1) | R0.bit7) & 0x1F (C); S2/module = R1 >> 4 (B). If R2
;              (high random byte) is non-zero the record is out of range -> abort with phase code 6.
;              Otherwise compare target extent (C vs FCB+12) and S2 (B vs FCB+14): if both already
;              match, fall through with no positioning; else reposition the directory to the target
;              extent. Mirrors the standard CP/M 2.2 BDOS random seek. [RE]
; ----------------------------------------------------------------------
BDOS_SEEK_COMPUTE:
        PUSH BC                          ; $A707  C5
        ; HL = pointer to the active FCB (CURFCB).
        LD HL,(BDOS_PARAM_PTR)                   ; $A708  2A 43 9F
        EX DE,HL                         ; $A70B  EB
        ; Offset 33 (0x21) = FCB random-record field R0; HL = FCB+33 after ADD HL,DE.
        LD HL,$0021                      ; $A70C  21 21 00
        ADD HL,DE                        ; $A70F  19
        LD A,(HL)                        ; $A710  7E
        ; Record-within-extent = R0 bits 0..6 (0..127).
        AND $7F                          ; $A711  E6 7F
        PUSH AF                          ; $A713  F5
        LD A,(HL)                        ; $A714  7E
        ; Rotate R0 bit7 into carry (combined with R1 below for the extent number).
        RLA                              ; $A715  17
        INC HL                           ; $A716  23
        LD A,(HL)                        ; $A717  7E
        ; Rotate R1 left, picking up R0.bit7 from carry: forms (R1 << 1) | R0.bit7.
        RLA                              ; $A718  17
        ; Low 5 bits = extent number within the directory entry.
        AND $1F                          ; $A719  E6 1F
        ; C = target extent (low part).
        LD C,A                           ; $A71B  4F
        LD A,(HL)                        ; $A71C  7E
        RRA                              ; $A71D  1F
        RRA                              ; $A71E  1F
        RRA                              ; $A71F  1F
        RRA                              ; $A720  1F
        ; Keep R1's high nibble = S2 / extent-module count.
        AND $0F                          ; $A721  E6 0F
        ; B = target S2 (extent module) value (R1 >> 4).
        LD B,A                           ; $A723  47
        POP AF                           ; $A724  F1
        INC HL                           ; $A725  23
        LD L,(HL)                        ; $A726  6E
        INC L                            ; $A727  2C
        DEC L                            ; $A728  2D
        ; Preset L = seek phase code 6 (the random-record overflow result).
        LD L,$06                         ; $A729  2E 06
        ; R2 (high random-record byte) non-zero -> record number out of range, abort the seek.
        JP NZ,RANDREC_POS_RET                 ; $A72B  C2 8B A7
        LD HL,$0020                      ; $A72E  21 20 00
        ADD HL,DE                        ; $A731  19
        LD (HL),A                        ; $A732  77
        ; Offset 12 = FCB extent (EX) byte.
        LD HL,$000C                      ; $A733  21 0C 00
        ADD HL,DE                        ; $A736  19
        LD A,C                           ; $A737  79
        ; Compare target extent (C) against the FCB's current extent.
        SUB (HL)                         ; $A738  96
        ; Extent differs -> must reposition the directory to the new extent.
        JP NZ,BDOS_SEEK_REPOSITION                 ; $A739  C2 47 A7
        ; Offset 14 = FCB S2 (module) byte.
        LD HL,$000E                      ; $A73C  21 0E 00
        ADD HL,DE                        ; $A73F  19
        LD A,B                           ; $A740  78
        ; Compare target S2 (B) against the FCB's current S2.
        SUB (HL)                         ; $A741  96
        AND $7F                          ; $A742  E6 7F
        ; Extent and S2 both already current -> nothing to seek, return OK.
        JP Z,BDOS_SEEK_DONE                  ; $A744  CA 7F A7
; ----------------------------------------------------------------------
; BDOS_SEEK_REPOSITION -- close the current extent and open/seek the directory to the requested
; extent.
;   In: B = target S2, C = target extent; DE -> FCB; BDOS_RETVAL = create/extend mode flag (0xFF =
;       create on miss).
;   Out: FCB extent (EX, +12) and S2 (+14) set to the target; directory positioned at the matching
;        extent; a phase code is left in L (stored into BDOS_RETVAL at the seek tail); on success
;        falls into BDOS_SEEK_DONE.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: close/flush the currently open extent (F_CLOSE_HND clears the host-buffer/seek cache).
;              Set phase=3; if BDOS_RETVAL == 0xFF (create mode; INC A gives 0 / Z) take the
;              extent-allocate path. Otherwise store the new EX (+12) and S2 (+14) into the FCB and
;              open the matching directory entry (FCB_OPEN_SEARCH). Re-test BDOS_RETVAL (phase 4):
;              on create, probe the next extent; read the directory record (DIR_MAKE_ENTRY); re-test
;              (phase 5); then drop into BDOS_SEEK_DONE. [RE]
; ----------------------------------------------------------------------
BDOS_SEEK_REPOSITION:
        PUSH BC                          ; $A747  C5
        PUSH DE                          ; $A748  D5
        ; Close the currently open extent (clears the host-buffer/seek cache cells) before
        ; repositioning.
        CALL F_CLOSE_HND                    ; $A749  CD A2 A4
        POP DE                           ; $A74C  D1
        POP BC                           ; $A74D  C1
        ; Seek phase code 3 (extent-allocate path).
        LD L,$03                         ; $A74E  2E 03
        ; Load the create/extend mode flag.
        LD A,(BDOS_RETVAL)                    ; $A750  3A 45 9F
        ; Test for the 0xFF 'create/allocate on miss' value (INC -> 0 / sets Z).
        INC A                            ; $A753  3C
        ; Create/allocate mode -> take the extent-allocate path.
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A754  CA 84 A7
        ; Offset 12 = FCB extent (EX) byte.
        LD HL,$000C                      ; $A757  21 0C 00
        ADD HL,DE                        ; $A75A  19
        ; Store the new target extent into the FCB.
        LD (HL),C                        ; $A75B  71
        ; Offset 14 = FCB S2 byte.
        LD HL,$000E                      ; $A75C  21 0E 00
        ADD HL,DE                        ; $A75F  19
        ; Store the new target S2 (module) into the FCB.
        LD (HL),B                        ; $A760  70
        ; Search/open the directory entry for the new extent.
        CALL FCB_OPEN_SEARCH                    ; $A761  CD 51 A4
        LD A,(BDOS_RETVAL)                    ; $A764  3A 45 9F
        INC A                            ; $A767  3C
        JP NZ,BDOS_SEEK_DONE                 ; $A768  C2 7F A7
        POP BC                           ; $A76B  C1
        PUSH BC                          ; $A76C  C5
        ; Seek phase code 4.
        LD L,$04                         ; $A76D  2E 04
        ; Bump the extent for the next-extent create probe.
        INC C                            ; $A76F  0C
        ; Create path: allocate/init the new extent.
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A770  CA 84 A7
        ; Read the directory record for the new extent into the scratch buffer.
        CALL DIR_MAKE_ENTRY                    ; $A773  CD 24 A5
        ; Seek phase code 5.
        LD L,$05                         ; $A776  2E 05
        LD A,(BDOS_RETVAL)                    ; $A778  3A 45 9F
        INC A                            ; $A77B  3C
        ; Create path: finalize the new extent.
        JP Z,FCB_EXTENT_TO_TRKSEC_7                  ; $A77C  CA 84 A7
; ----------------------------------------------------------------------
; BDOS_SEEK_DONE -- successful SEEK exit: restore registers and return OK.
;   In: target extent/record now current in the FCB.
;   Out: A = 0 (seek OK) returned via BDOS_RET_RESULT; the BC saved at SEEK entry restored.
;   Clobbers: A, BC.
;   Algorithm: pop the saved BC, set A=0 and return the success status through the BDOS result tail.
;              [RE]
; ----------------------------------------------------------------------
BDOS_SEEK_DONE:
        ; Restore the caller's BC saved at SEEK entry.
        POP BC                           ; $A77F  C1
        ; A = 0: seek successful.
        XOR A                            ; $A780  AF
        ; Return the seek result (0 = OK) to the caller.
        JP BDOS_RET_RESULT                   ; $A781  C3 01 9F
; ----------------------------------------------------------------------
; RANDREC_POS_FAIL -- error tail of the random-record positioning code (BDOS_SEEK_COMPUTE): mark the
; extent invalid and report.
;   In: L = error/return code to publish (set by the caller, e.g. 6 = 'random record out of range',
;       3, 4, 5); one BC frame still pushed by BDOS_SEEK_COMPUTE; BDOS_PARAM_PTR = current FCB
;       pointer.
;   Out: FCB S2 byte (offset $0E) forced to $C0; BDOS_RETVAL result cell loaded with L; tail-jumps
;        via RANDREC_POS_RET to MARK_FCB_S2_HIGHBIT, which then ORs $80 into S2 and returns.
;   Clobbers: A, HL, BC (popped).
;   Algorithm: PUSH HL; fetch &FCB.S2 via FCB_GET_S2 and store $C0 into it; POP HL; fall through
;              into RANDREC_POS_RET, which POPs the BC frame, copies L into the result cell, and JPs
;              MARK_FCB_S2_HIGHBIT.
;   [RE] Reached from several points in BDOS_SEEK_COMPUTE when the random record cannot be
;   positioned (out of range, or a read-mode request that would have to extend the file). Setting S2
;   to $C0 marks the extent so the file is treated as unwritten/at-EOF; the published L code is the
;   BDOS error returned to the caller.
; ----------------------------------------------------------------------
FCB_EXTENT_TO_TRKSEC_7:
        PUSH HL                          ; $A784  E5
        ; HL := &FCB.S2 (offset $0E of the current FCB)
        CALL FCB_GET_S2                    ; $A785  CD 69 A1
        ; S2 := $C0: high bit set (extent marked invalid/unwritten) + zero the module count [RE]
        LD (HL),$C0                      ; $A788  36 C0
        POP HL                           ; $A78A  E1
; ----------------------------------------------------------------------
; RANDREC_POS_RET -- common exit for BDOS_SEEK_COMPUTE: discard the saved BC frame, publish the L
; result code, finalize via MARK_FCB_S2_HIGHBIT.
;   In: L = result/return code; one BC frame still pushed on the stack from BDOS_SEEK_COMPUTE's
;       entry PUSH BC.
;   Out: BDOS_RETVAL result cell = L; control transfers to MARK_FCB_S2_HIGHBIT (sets FCB S2 high
;        bit, returns to the BDOS dispatcher).
;   Clobbers: A, BC (popped).
;   Algorithm: POP BC to discard the saved register pair; A := L; store A into the BDOS_RETVAL
;              result cell; JP MARK_FCB_S2_HIGHBIT.
;   [RE] Entered by fall-through from RANDREC_POS_FAIL and directly (JP NZ from $A72B) when the
;   addressed extent differs from the open one. MARK_FCB_S2_HIGHBIT ORs $80 into the FCB S2 byte
;   before returning.
; ----------------------------------------------------------------------
RANDREC_POS_RET:
        ; discard the BC frame pushed on entry to BDOS_SEEK_COMPUTE
        POP BC                           ; $A78B  C1
        LD A,L                           ; $A78C  7D
        ; publish the return/error code in the BDOS result cell
        LD (BDOS_RETVAL),A                    ; $A78D  32 45 9F
        ; set FCB S2 high bit, then return to caller
        JP MARK_FCB_S2_HIGHBIT                      ; $A790  C3 78 A1
; ----------------------------------------------------------------------
; F_READRAND_BODY -- BDOS function 33 (Read Random) worker: position the FCB from its random record,
; then read that record.
;   In: BDOS_PARAM_PTR = current FCB pointer (random-record field r0/r1/r2 set by the caller);
;       reached from F_READRAND_H after FCB_AUTO_DRIVE_SELECT.
;   Out: read result stored in the BDOS result cell (BDOS_RETVAL) by the called read routine; Z from
;        positioning governs whether the read runs.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: C := $FF (read mode = do NOT extend the file); CALL BDOS_SEEK_NOREAD
;              (BDOS_SEEK_COMPUTE) to convert the random record into extent + current-record fields;
;              if positioning succeeded (Z), CALL FILE_READ_RECORD to read the addressed record;
;              RET.
;   [RE][DOC CP/M 2.2 BDOS fn 33] C=$FF is consumed inside BDOS_SEEK_COMPUTE: when positioning would
;   require extending the file, INC C on $FF sets Z and diverts to the error tail, so a read past
;   EOF fails instead of allocating. The conditional CALL Z performs the sector read only when
;   positioning succeeded (Z).
; ----------------------------------------------------------------------
FCB_EXTENT_TO_TRKSEC_8:
        ; C := $FF: read mode -- positioning must NOT extend/allocate (INC C->Z triggers the fail
        ; path)
        LD C,$FF                         ; $A793  0E FF
        ; BDOS_SEEK_COMPUTE: convert random record (r0/r1/r2) into extent + cr; Z on success
        CALL BDOS_SEEK_NOREAD                    ; $A795  CD 03 A7
        ; if positioned OK, read the addressed record
        CALL Z,FILE_READ_RECORD                  ; $A798  CC C1 A5
        RET                              ; $A79B  C9
; ----------------------------------------------------------------------
; F_WRITERAND_BODY -- BDOS function 34 (Write Random) worker: position the FCB from its random
; record, then write that record.
;   In: BDOS_PARAM_PTR = current FCB pointer (random-record field set by the caller); reached from
;       F_WRITERAND_H after FCB_AUTO_DRIVE_SELECT.
;   Out: write result stored in the BDOS result cell (BDOS_RETVAL) by the called write routine; Z
;        from positioning governs whether the write runs.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: C := $00 (write mode = allocate/extend as needed); CALL BDOS_SEEK_NOREAD
;              (BDOS_SEEK_COMPUTE) to set extent + current-record from the random record; if
;              positioning succeeded (Z), CALL BDOS_WRITE to write the record; RET.
;   [RE][DOC CP/M 2.2 BDOS fn 34] C=$00 is consumed inside BDOS_SEEK_COMPUTE: INC C on $00 yields
;   $01 (NZ), so the extend path is taken rather than the error tail, allowing a new extent/block to
;   be allocated. The conditional CALL Z writes the record only when positioning succeeded (Z).
; ----------------------------------------------------------------------
FCB_EXTENT_TO_TRKSEC_9:
        ; C := $00: write mode -- positioning may allocate/extend the file (INC C->$01 NZ, no fail)
        LD C,$00                         ; $A79C  0E 00
        ; BDOS_SEEK_COMPUTE: convert random record into extent + cr; Z on success
        CALL BDOS_SEEK_NOREAD                    ; $A79E  CD 03 A7
        ; if positioned OK, write the addressed record
        CALL Z,BDOS_WRITE                  ; $A7A1  CC 03 A6
        RET                              ; $A7A4  C9
; ----------------------------------------------------------------------
; FCB_RECNUM_FROM_FIELDS -- compute the 24-bit absolute record number from an FCB's record byte plus
; its extent (ex) and S2 fields.
;   In: HL = base pointer to the FCB (or directory entry); DE = byte offset within it of the low
;       record byte to read (e.g. $20 = cr for Set Random Record, $0F for the per-extent record
;       count in Compute File Size).
;   Out: C = low byte, B = mid byte, A = high byte of the record number; A AND $01 leaves Z/NZ on
;        the result's low bit for callers; HL, DE clobbered.
;   Clobbers: A, BC, HL, DE, flags.
;   Algorithm: EX DE,HL so HL=offset, DE=FCB base; ADD HL,DE -> &FCB+offset; C := that byte, B := 0.
;              Read the extent byte (offset $0C): RRCA then AND $80 puts its bit0 into bit7, add to
;              C (carry into B) -- the *128 contribution; RRCA/AND $0F of the same extent byte adds
;              the extent's high nibble into B. Read S2 (offset $0E): shift left 4 (ADD A,A x4), add
;              into B to form the high bits; final AND $01 sets Z/NZ on the low bit of the
;              accumulated value.
;   [RE] Builds the linear absolute record index (record + ex*128 + S2*...) that CP/M 2.2 uses to
;   map directory extents onto a flat record space; shared by Set Random Record (fn 36) and Compute
;   File Size (fn 35).
; ----------------------------------------------------------------------
FCB_ALLOC_PREP:
        ; HL := caller offset; DE := FCB base pointer
        EX DE,HL                         ; $A7A5  EB
        ; HL := &FCB + offset (the low record byte)
        ADD HL,DE                        ; $A7A6  19
        ; C := low record bits from that byte
        LD C,(HL)                        ; $A7A7  4E
        LD B,$00                         ; $A7A8  06 00
        ; offset $0C = FCB extent (ex) byte
        LD HL,$000C                      ; $A7AA  21 0C 00
        ADD HL,DE                        ; $A7AD  19
        LD A,(HL)                        ; $A7AE  7E
        RRCA                             ; $A7AF  0F
        ; extent bit0 -> record bit7 (the ex*128 contribution)
        AND $80                          ; $A7B0  E6 80
        ADD A,C                          ; $A7B2  81
        LD C,A                           ; $A7B3  4F
        LD A,$00                         ; $A7B4  3E 00
        ADC A,B                          ; $A7B6  88
        LD B,A                           ; $A7B7  47
        LD A,(HL)                        ; $A7B8  7E
        RRCA                             ; $A7B9  0F
        AND $0F                          ; $A7BA  E6 0F
        ADD A,B                          ; $A7BC  80
        LD B,A                           ; $A7BD  47
        ; offset $0E = FCB S2 byte (extent-high / module)
        LD HL,$000E                      ; $A7BE  21 0E 00
        ADD HL,DE                        ; $A7C1  19
        LD A,(HL)                        ; $A7C2  7E
        ; first of four ADD A,A: shift S2 left to form the high record bits
        ADD A,A                          ; $A7C3  87
        ADD A,A                          ; $A7C4  87
        ADD A,A                          ; $A7C5  87
        ADD A,A                          ; $A7C6  87
        PUSH AF                          ; $A7C7  F5
        ADD A,B                          ; $A7C8  80
        LD B,A                           ; $A7C9  47
        PUSH AF                          ; $A7CA  F5
        POP HL                           ; $A7CB  E1
        LD A,L                           ; $A7CC  7D
        POP HL                           ; $A7CD  E1
        OR L                             ; $A7CE  B5
        ; set Z/NZ on the low bit of the result for callers
        AND $01                          ; $A7CF  E6 01
        RET                              ; $A7D1  C9
; ----------------------------------------------------------------------
; F_COMPSIZE_BODY -- BDOS function 35 (Compute File Size) worker: scan the directory and write the
; max record number into r0/r1/r2.
;   In: BDOS_PARAM_PTR = current FCB pointer; reached from F_SIZE_H after FCB_AUTO_DRIVE_SELECT.
;   Out: FCB random-record bytes r0/r1/r2 (offsets $21-$23) set to the file's record count (one past
;        the highest record across all matching directory extents).
;   Clobbers: A, BC, DE, HL.
;   Algorithm: C := $0C and CALL DIR_SEARCH_FIRST to begin a directory search masked over the first
;              12 FCB bytes (drive+name+type; the extent byte is NOT matched). Point HL at FCB+$21
;              and zero the three random-record bytes (D is 0 from LD DE,$0021). Then loop over
;              every matching directory entry (falls into COMPSIZE_SCAN_LOOP): for each, compute its
;              record number via FCB_RECNUM_FROM_FIELDS at offset $0F and keep the running maximum
;              in r0/r1/r2; when the search exhausts, the largest record number remains stored.
;   [RE][DOC CP/M 2.2 BDOS fn 35] Result is a record count (next free record), one past the highest
;   used record; the loop mirrors the canonical 'scan directory, max(extent record number)'
;   algorithm.
; ----------------------------------------------------------------------
FCB_ALLOC_BLOCK_NUM_2:
        ; mask = first $0C (12) FCB bytes: drive+name+type (extent NOT compared) when scanning
        LD C,$0C                         ; $A7D2  0E 0C
        ; begin a masked directory search over those 12 bytes
        CALL DIR_SEARCH_FIRST                    ; $A7D4  CD 18 A3
        LD HL,(BDOS_PARAM_PTR)                   ; $A7D7  2A 43 9F
        ; offset $21 = FCB random-record field r0 (D=0 used to zero the bytes)
        LD DE,$0021                      ; $A7DA  11 21 00
        ADD HL,DE                        ; $A7DD  19
        PUSH HL                          ; $A7DE  E5
        ; r0 := 0 (zero the 3-byte running maximum)
        LD (HL),D                        ; $A7DF  72
        INC HL                           ; $A7E0  23
        ; r1 := 0
        LD (HL),D                        ; $A7E1  72
        INC HL                           ; $A7E2  23
        ; r2 := 0
        LD (HL),D                        ; $A7E3  72
; ----------------------------------------------------------------------
; COMPSIZE_SCAN_LOOP -- per-directory-entry step of Compute File Size: fold each extent's record
; number into the running max.
;   In: stack top = pointer to the FCB random-record max (r0/r1/r2); a masked directory search is in
;       progress.
;   Out: on directory exhaustion, exits via COMPSIZE_DONE (pop, return); otherwise updates the
;        3-byte max in place and continues.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: CALL CUR_RECORD_BYTES_EQUAL to test whether the search is exhausted; if so (Z) JP
;              COMPSIZE_DONE. Else CALL FCB_BUF_PTR_ADD_OFFSET to point at this entry in the
;              directory buffer, then FCB_ALLOC_PREP at offset $0F to get the candidate record
;              number in C(lo)/B(mid)/A(hi). Reload &r0 (POP/PUSH HL), 24-bit subtract candidate -
;              stored (SUB / SBC / SBC over r0,r1,r2); if candidate < stored (carry), JP
;              COMPSIZE_NEXT keeping the stored max; otherwise overwrite r2,r1,r0 with the
;              candidate; fall into COMPSIZE_NEXT.
;   [RE] Implements a running max over directory extents; the 24-bit subtract decides whether this
;   extent extends the file further than any seen so far.
; ----------------------------------------------------------------------
COMPSIZE_SCAN_LOOP:
        ; test whether the directory search is exhausted; Z = no more entries
        CALL CUR_RECORD_BYTES_EQUAL                    ; $A7E4  CD F5 A1
        ; search exhausted -> finish (pop saved ptr and return)
        JP Z,COMPSIZE_DONE                  ; $A7E7  CA 0C A8
        ; HL := directory buffer + this entry's byte offset
        CALL FCB_BUF_PTR_ADD_OFFSET                    ; $A7EA  CD 5E A1
        ; offset $0F = the entry's record-count byte for FCB_RECNUM_FROM_FIELDS
        LD DE,$000F                      ; $A7ED  11 0F 00
        ; candidate record number -> C(lo)/B(mid)/A(hi)
        CALL FCB_ALLOC_PREP                    ; $A7F0  CD A5 A7
        POP HL                           ; $A7F3  E1
        PUSH HL                          ; $A7F4  E5
        LD E,A                           ; $A7F5  5F
        ; begin 24-bit compare: candidate - stored max over r0/r1/r2
        LD A,C                           ; $A7F6  79
        SUB (HL)                         ; $A7F7  96
        INC HL                           ; $A7F8  23
        LD A,B                           ; $A7F9  78
        SBC A,(HL)                       ; $A7FA  9E
        INC HL                           ; $A7FB  23
        LD A,E                           ; $A7FC  7B
        SBC A,(HL)                       ; $A7FD  9E
        ; candidate < stored max -> keep stored max, skip the store
        JP C,COMPSIZE_NEXT                  ; $A7FE  DA 06 A8
        ; candidate >= max: store new high byte (r2)
        LD (HL),E                        ; $A801  73
        DEC HL                           ; $A802  2B
        ; store new mid byte (r1)
        LD (HL),B                        ; $A803  70
        DEC HL                           ; $A804  2B
        ; store new low byte (r0)
        LD (HL),C                        ; $A805  71
; ----------------------------------------------------------------------
; COMPSIZE_NEXT -- Compute File Size loop continuation: advance the directory search and re-enter
; the scan loop.
;   In: directory search state live; stack top = pointer to the running r0/r1/r2 maximum.
;   Out: re-enters COMPSIZE_SCAN_LOOP (COMPSIZE_SCAN_LOOP) after advancing to the next directory
;        entry.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: CALL BDOS_DIR_SCAN_NEXT to advance the masked directory search by one entry; JP
;              COMPSIZE_SCAN_LOOP.
;   [RE] Joined both from the 'candidate < max' early path and after a store; BDOS_DIR_SCAN_NEXT
;   performs the next directory read/match.
; ----------------------------------------------------------------------
COMPSIZE_NEXT:
        ; advance the masked directory search to the next matching entry
        CALL BDOS_DIR_SCAN_NEXT                    ; $A806  CD 2D A3
        ; loop back to fold the next extent into the max
        JP COMPSIZE_SCAN_LOOP                    ; $A809  C3 E4 A7
; ----------------------------------------------------------------------
; COMPSIZE_DONE -- Compute File Size exit: discard the saved max pointer and return.
;   In: stack top = pointer to the FCB r0/r1/r2 max (already written in place).
;   Out: returns to the F_SIZE_H caller; FCB random-record field holds the computed file size.
;   Clobbers: HL.
;   Algorithm: POP HL to balance the PUSH HL done in FCB_ALLOC_BLOCK_NUM_2 before the scan; RET.
;   [RE] Sole loop exit, reached when the directory search is exhausted.
; ----------------------------------------------------------------------
COMPSIZE_DONE:
        ; balance the saved r0/r1/r2 pointer pushed before the scan loop
        POP HL                           ; $A80C  E1
        RET                              ; $A80D  C9
; ----------------------------------------------------------------------
; F_RANDREC_H -- BDOS function 36 (Set Random Record): compute the random-record field of the
; current FCB from its sequential position.
;   In: current FCB pointer in BDOS cell BDOS_PARAM_PTR (the FCB whose sequential extent/cr fields
;       are to be converted).
;   Out: bytes r0/r1/r2 (FCB offsets $21..$23) written with the 24-bit record number derived from
;        the FCB's extent and current-record fields.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: call FCB_ALLOC_PREP with HL=FCB base and DE=$0020, which folds the cr (current-record
;              at FCB+$20), the extent number and the extent-high bit into a record count returned
;              in C (low) / B (high) / A (overflow), and leaves DE = the FCB base pointer; then form
;              HL = FCB+$0021 (DE + $0021) and store C,B,A into FCB[$21],[$22],[$23].
;   [RE] verified against canonical CP/M 2.2 Set Random Record (dispatch fn 36 at $9C8F);
;   FCB_ALLOC_PREP is the standard extent->record-count fold.
; ----------------------------------------------------------------------
F_RANDREC_H:
        ; HL = pointer to the current FCB (the file whose sequential position we are converting)
        LD HL,(BDOS_PARAM_PTR)                   ; $A80E  2A 43 9F
        ; DE = $20: FCB_ALLOC_PREP reads the cr/extent region at FCB+$20 and returns DE = the FCB
        ; base
        LD DE,$0020                      ; $A811  11 20 00
        ; fold cr + extent# + extent-high bit into a 24-bit record number -> C low, B high, A
        ; overflow; returns DE = FCB base
        CALL FCB_ALLOC_PREP                    ; $A814  CD A5 A7
        ; HL = $0021; the next ADD HL,DE makes HL = FCB + $21, the start of the 3-byte random-record
        ; field r0,r1,r2
        LD HL,$0021                      ; $A817  21 21 00
        ADD HL,DE                        ; $A81A  19
        ; store r0 (record number, low byte)
        LD (HL),C                        ; $A81B  71
        INC HL                           ; $A81C  23
        ; store r1 (record number, high byte)
        LD (HL),B                        ; $A81D  70
        INC HL                           ; $A81E  23
        ; store r2 (record number overflow / random-record overflow byte)
        LD (HL),A                        ; $A81F  77
        RET                              ; $A820  C9
; ----------------------------------------------------------------------
; DRV_INSTALL_RWTS_17 -- Select-disk / log-in worker: ensure the drive in BDOS_CUR_DRIVE is logged
; in, and rebuild its allocation vector if it was not.
;   In: BDOS_CUR_DRIVE = requested (current) drive number 0..15; DRV_SELECT_VECTOR = working login/select
;       vector.
;   Out: if the drive was newly logged in, its directory is scanned (BDOS_ERR_SELECT) and its
;        allocation vector rebuilt (CMD_EXEC_65); DRV_SELECT_VECTOR updated with the drive's login bit.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: load the working login vector DRV_SELECT_VECTOR; build a single-bit mask for the requested drive
;              (DRV_INSTALL_RWTS_10 shifts); test (BDOS_RANDREC_3) whether the drive's DPB is
;              already established; if not yet logged in (Z) call BDOS_ERR_SELECT to log it in /
;              scan its directory; if the login bit was already set (RRA -> carry) just return;
;              otherwise OR this drive's bit into DRV_SELECT_VECTOR (CMD_EXEC_12), store it, and fall into
;              CMD_EXEC_65 to (re)build the allocation vector.
;   [RE] the standard CP/M 2.2 select-disk login path reached from DRV_SET (fn 14) and DRV_ALLRESET
;   (fn 13). [?] the A=L / RRA already-logged-in test is inferred from the surrounding flow, not
;   proven from these bytes alone.
; ----------------------------------------------------------------------
DRV_INSTALL_RWTS_17:
        ; HL = working login/select vector
        LD HL,(DRV_SELECT_VECTOR)                   ; $A821  2A AF A9
        ; A = requested drive number
        LD A,(BDOS_CUR_DRIVE)                    ; $A824  3A 42 9F
        LD C,A                           ; $A827  4F
        ; shift to form the single-bit drive mask for this drive
        CALL DRV_INSTALL_RWTS_10                    ; $A828  CD EA A0
        PUSH HL                          ; $A82B  E5
        EX DE,HL                         ; $A82C  EB
        ; establish/test the drive's DPB; sets Z if the drive needs logging in
        CALL BDOS_RANDREC_3                    ; $A82D  CD 59 9F
        POP HL                           ; $A830  E1
        ; drive not yet logged in: run the disk log-in / directory scan
        CALL Z,BDOS_ERR_SELECT                  ; $A831  CC 47 9F
        LD A,L                           ; $A834  7D
        ; rotate bit 0 of the drive mask into carry: carry set => this drive already had its login
        ; bit set
        RRA                              ; $A835  1F
        ; already logged in: nothing more to do
        RET C                            ; $A836  D8
        LD HL,(DRV_SELECT_VECTOR)                   ; $A837  2A AF A9
        LD C,L                           ; $A83A  4D
        LD B,H                           ; $A83B  44
        ; OR this drive's bit into the working login vector
        CALL CMD_EXEC_12                    ; $A83C  CD 0B A1
        ; store the updated working login vector
        LD (DRV_SELECT_VECTOR),HL                   ; $A83F  22 AF A9
        ; tail into rebuild-allocation-vector for the freshly logged-in drive
        JP CMD_EXEC_65                    ; $A842  C3 A3 A2
; ----------------------------------------------------------------------
; DRV_SET_H -- BDOS function 14 (Select Disk): make the drive in DRV_SELECT_ARG the current drive.
;   In: DRV_SELECT_ARG = desired drive number; BDOS_CUR_DRIVE = current drive number.
;   Out: if the drive changed, BDOS_CUR_DRIVE is updated and the drive is logged in / allocation
;        vector rebuilt (via DRV_INSTALL_RWTS_17); otherwise no-op.
;   Clobbers: A, HL (and whatever DRV_INSTALL_RWTS_17 clobbers).
;   Algorithm: compare desired drive (DRV_SELECT_ARG) with current (BDOS_CUR_DRIVE); if equal return; else
;              store the new current drive and jump to the select/log-in worker.
;   [RE] dispatch fn 14 at $9C63; matches canonical CP/M 2.2 Select Disk.
; ----------------------------------------------------------------------
DRV_SET_H:
        ; A = requested drive number
        LD A,(DRV_SELECT_ARG)                    ; $A845  3A D6 A9
        ; HL -> current-drive cell
        LD HL,BDOS_CUR_DRIVE                     ; $A848  21 42 9F
        ; already the current drive?
        CP (HL)                          ; $A84B  BE
        ; yes: nothing to do
        RET Z                            ; $A84C  C8
        ; set the new current drive
        LD (HL),A                        ; $A84D  77
        ; log it in / rebuild its allocation vector
        JP DRV_INSTALL_RWTS_17                    ; $A84E  C3 21 A8
; ----------------------------------------------------------------------
; FCB_AUTO_DRIVE_SELECT -- common file-operation preamble: honor the drive prefix in the caller's
; FCB, temporarily selecting that drive.
;   In: BDOS_PARAM_PTR = pointer to the caller's FCB (byte 0 = drive prefix, 0=default else
;       drive+1); BDOS_CUR_DRIVE = current drive; BDOS_STACK_TOP = current user number.
;   Out: if the FCB names an explicit drive, that drive is selected (DRV_SELECT_ARG set, DRV_SET_H called)
;        and the prior drive is saved in the restore cells (DRV_RESTORE_FLAG flag=$FF, DRV_SAVED_DRIVE=saved drive,
;        DRV_SAVED_FCB_BYTE=saved FCB drive byte); the FCB's drive byte is rewritten to OR in the current user
;        number.
;   Clobbers: A, HL.
;   Algorithm: set restore-pending flag DRV_RESTORE_FLAG=$FF; read FCB byte0, mask $1F and DEC to get drive
;              index into DRV_SELECT_ARG; if >=$1E (no explicit drive / out of range) skip the switch; else
;              save current drive (BDOS_CUR_DRIVE->DRV_SAVED_DRIVE) and original FCB byte (->DRV_SAVED_FCB_BYTE), strip
;              the drive prefix bits ($E0 mask) from FCB byte0, and select the requested drive via
;              DRV_SET_H; finally OR the current user number (BDOS_STACK_TOP) into FCB byte0.
;   [RE] this is the auto-disk-select / FCB drive-prefix handler that nearly every file BDOS call
;   funnels through; the matching restore is FCB_AUTO_DRIVE_RESTORE. The old auto-label
;   'FCB_AUTO_DRIVE_SELECT' is a misnomer (it does not seek tracks).
; ----------------------------------------------------------------------
FCB_AUTO_DRIVE_SELECT:
        ; mark 'a temporary drive switch is pending' so the epilogue restores it
        LD A,$FF                         ; $A851  3E FF
        ; store the restore-pending flag
        LD (DRV_RESTORE_FLAG),A                    ; $A853  32 DE A9
        ; HL -> caller's FCB; (HL) = drive-prefix byte
        LD HL,(BDOS_PARAM_PTR)                   ; $A856  2A 43 9F
        LD A,(HL)                        ; $A859  7E
        ; isolate the drive-prefix field of FCB byte 0
        AND $1F                          ; $A85A  E6 1F
        ; convert prefix (1..16) to drive index (0..15); $00 (default) wraps to $FF
        DEC A                            ; $A85C  3D
        ; record the drive this FCB asks for
        LD (DRV_SELECT_ARG),A                    ; $A85D  32 D6 A9
        ; no explicit drive (default => $FF) or out of range?
        CP $1E                           ; $A860  FE 1E
        ; yes: skip the drive switch, just merge the user number
        JP NC,FCB_MERGE_USER                 ; $A862  D2 75 A8
        LD A,(BDOS_CUR_DRIVE)                    ; $A865  3A 42 9F
        ; save the current drive so the epilogue can restore it
        LD (DRV_SAVED_DRIVE),A                    ; $A868  32 DF A9
        LD A,(HL)                        ; $A86B  7E
        ; save the original FCB drive-prefix byte for restore
        LD (DRV_SAVED_FCB_BYTE),A                    ; $A86C  32 E0 A9
        ; clear the drive-prefix bits, leaving the high flag bits of FCB byte0
        AND $E0                          ; $A86F  E6 E0
        LD (HL),A                        ; $A871  77
        ; temporarily select the drive named by the FCB
        CALL DRV_SET_H                    ; $A872  CD 45 A8
; ----------------------------------------------------------------------
; FCB_MERGE_USER -- tail of FCB_AUTO_DRIVE_SELECT: OR the current user number into the FCB's drive
; byte.
;   In: BDOS_STACK_TOP = current user number; BDOS_PARAM_PTR = pointer to the FCB.
;   Out: FCB byte0 |= current user number.
;   Clobbers: A, HL.
;   Algorithm: load user number, OR with FCB byte0, store back.
;   [RE] shared exit of the auto-disk-select preamble.
; ----------------------------------------------------------------------
FCB_MERGE_USER:
        ; A = current user number
        LD A,(BDOS_STACK_TOP)                    ; $A875  3A 41 9F
        LD HL,(BDOS_PARAM_PTR)                   ; $A878  2A 43 9F
        ; merge the user number into the FCB's drive/flags byte
        OR (HL)                          ; $A87B  B6
        ; write it back
        LD (HL),A                        ; $A87C  77
        RET                              ; $A87D  C9
; ----------------------------------------------------------------------
; S_BDOSVER_H -- BDOS function 12 (Return Version Number): report CP/M 2.2.
;   In: none.
;   Out: low byte of the BDOS result set to $22 (= version 2.2) via BDOS_RET_RESULT, which writes
;        only BDOS_RETVAL (the result low byte / register A).
;   Clobbers: A.
;   Algorithm: load $22 and store it as the low byte of the BDOS return result. (The result high
;              byte is not written here; in canonical CP/M 2.2 the version word is $00$22, but this
;              routine sets only the low byte.)
;   [RE] dispatch fn 12 at $9C5F; $22 = CP/M 2.2 per the canonical version code.
; ----------------------------------------------------------------------
S_BDOSVER_H:
        ; version code $22 = CP/M 2.2
        LD A,$22                         ; $A87E  3E 22
        ; return it as the BDOS result low byte
        JP BDOS_RET_RESULT                   ; $A880  C3 01 9F
; ----------------------------------------------------------------------
; DRV_ALLRESET_H -- BDOS function 13 (Reset Disk System): return CP/M to its initial disk state.
;   In: none.
;   Out: login vector and working login/select vector cleared; current drive forced to A: (0); DMA
;        address reset to TBUFF ($0080); drive A logged in fresh.
;   Clobbers: A, HL (and DRV_INSTALL_RWTS_17 / RESTORE_USER_DMA clobbers).
;   Algorithm: zero DRV_LOGIN_VECTOR and DRV_SELECT_VECTOR; set current drive BDOS_CUR_DRIVE=0; set
;              DMA_ADDR=$0080 (TBUFF); call RESTORE_USER_DMA (set the live BIOS DMA / reset disk
;              buffering); jump to DRV_INSTALL_RWTS_17 to log in drive A.
;   [RE] dispatch fn 13 at $9C61; matches canonical CP/M 2.2 Reset Disk System.
; ----------------------------------------------------------------------
DRV_ALLRESET_H:
        LD HL,$0000                      ; $A883  21 00 00
        ; clear the master logged-in drive bitmap
        LD (DRV_LOGIN_VECTOR),HL                   ; $A886  22 AD A9
        ; clear the working login/select vector
        LD (DRV_SELECT_VECTOR),HL                   ; $A889  22 AF A9
        XOR A                            ; $A88C  AF
        ; force current drive back to A: (0)
        LD (BDOS_CUR_DRIVE),A                    ; $A88D  32 42 9F
        ; TBUFF ($0080) = default DMA address
        LD HL,$0080                      ; $A890  21 80 00
        ; reset the DMA address to TBUFF
        LD (DMA_ADDR),HL                   ; $A893  22 B1 A9
        ; push the reset DMA address through to disk buffering / BIOS
        CALL RESTORE_USER_DMA                    ; $A896  CD DA A1
        ; log in drive A from a clean state
        JP DRV_INSTALL_RWTS_17                    ; $A899  C3 21 A8
; ----------------------------------------------------------------------
; F_OPEN_H -- BDOS function 15 (Open File): open the file named by the FCB.
;   In: BDOS_PARAM_PTR = pointer to the caller's FCB.
;   Out: directory match result returned via FCB_OPEN_SEARCH (the search/open result path); FCB
;        filled in from the matching directory entry on success, $FF if not found.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: CLEAR_FCB_S2 prepares/clears the open scratch state; FCB_AUTO_DRIVE_SELECT honors the
;              FCB drive prefix; jump into the open/search-and-fill path (FCB_OPEN_SEARCH).
;   [RE] dispatch fn 15 at $9C65; canonical CP/M 2.2 Open File.
; ----------------------------------------------------------------------
F_OPEN_H:
        ; prepare directory/open scratch state for this FCB
        CALL CLEAR_FCB_S2                    ; $A89C  CD 72 A1
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A89F  CD 51 A8
        ; search the directory and fill the FCB (open path)
        JP FCB_OPEN_SEARCH                      ; $A8A2  C3 51 A4
; ----------------------------------------------------------------------
; F_CLOSE_H -- BDOS function 16 (Close File): write the FCB back to its directory entry.
;   In: BDOS_PARAM_PTR = pointer to the caller's FCB (must be open).
;   Out: directory entry updated; result returned via F_CLOSE_HND path ($FF / dir-code).
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the FCB drive prefix; jump into the close
;              (rewrite-directory) path.
;   [RE] dispatch fn 16 at $9C67; canonical CP/M 2.2 Close File.
; ----------------------------------------------------------------------
F_CLOSE_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8A5  CD 51 A8
        ; rewrite the directory entry and return the close result
        JP F_CLOSE_HND                      ; $A8A8  C3 A2 A4
; ----------------------------------------------------------------------
; F_SFIRST_H -- BDOS function 17 (Search for First): find the first directory entry matching the
; FCB.
;   In: DE = pointer to the search FCB (the BDOS dispatcher has also saved DE in BDOS_PARAM_PTR).
;       FCB byte0 = $3F ('?') means 'match every entry' (ambiguous all-entries scan).
;   Out: directory match copied to the DMA buffer; result (0..3 = dir position, or $FF none) via
;        DISK_BUF_MOVE.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: C=0 (default match length); fetch FCB byte0 (HL<-DE); if byte0==$3F do an unqualified
;              all-entries scan (C left 0); else compute HL=FCB+$0C via DRV_INSTALL_RWTS_1 and test
;              the extent byte FCB[$0C] -- if it is not '?' prepare scratch (CLEAR_FCB_S2) -- then
;              auto-select drive and set C=$0F (15-byte name+type+extent match); fall into
;              DIR_SEARCH_AND_COPY to run the directory search and copy the hit to the DMA buffer.
;   [RE] dispatch fn 17 at $9C69; canonical CP/M 2.2 Search First; $3F is the '?' all-match marker.
;   DRV_INSTALL_RWTS_1 only computes the FCB+$0C pointer (it does not save the search FCB).
; ----------------------------------------------------------------------
F_SFIRST_H:
        ; search match length 0 (default name+type compare)
        LD C,$00                         ; $A8AB  0E 00
        EX DE,HL                         ; $A8AD  EB
        ; fetch FCB byte0 (drive/wildcard marker)
        LD A,(HL)                        ; $A8AE  7E
        ; $3F ('?') in byte0 => match every directory entry
        CP $3F                           ; $A8AF  FE 3F
        ; all-entries scan: go straight to the directory search
        JP Z,DIR_SEARCH_AND_COPY                  ; $A8B1  CA C2 A8
        ; HL = FCB + $0C (pointer to the extent byte); does NOT save the search FCB
        CALL DRV_INSTALL_RWTS_1                    ; $A8B4  CD A6 A0
        LD A,(HL)                        ; $A8B7  7E
        ; is the extent byte FCB[$0C] the '?' wildcard (match all extents)?
        CP $3F                           ; $A8B8  FE 3F
        ; extent not wildcard: prepare directory scratch state
        CALL NZ,CLEAR_FCB_S2                 ; $A8BA  C4 72 A1
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8BD  CD 51 A8
        ; match 15 bytes (name+type+extent) for a qualified search
        LD C,$0F                         ; $A8C0  0E 0F
; ----------------------------------------------------------------------
; DIR_SEARCH_AND_COPY -- run the directory scan and copy the matched entry to the DMA buffer.
;   In: C = number of bytes to compare in the directory match; search FCB already established by
;       F_SFIRST_H.
;   Out: matching directory record moved to the DMA buffer; A = directory position (0..3) or $FF if
;        none.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: DIR_SEARCH_FIRST performs the directory search with the C-byte mask; tail into
;              DISK_BUF_MOVE to copy the located directory entry into the user's DMA buffer and
;              return the result code.
;   [RE] shared search tail for fn 17 (Search First) and fn 18 (Search Next).
; ----------------------------------------------------------------------
DIR_SEARCH_AND_COPY:
        ; scan the directory comparing C bytes against the search FCB
        CALL DIR_SEARCH_FIRST                    ; $A8C2  CD 18 A3
        ; copy the matched directory entry to the DMA buffer, return its position
        JP DISK_BUF_MOVE                    ; $A8C5  C3 E9 A1
; ----------------------------------------------------------------------
; F_SNEXT_H -- BDOS function 18 (Search for Next): continue a directory search begun by Search
; First.
;   In: search state saved in DIR_FCB_PTR (the search FCB pointer stored by the directory-search core
;       DIR_SEARCH_FIRST at $A324).
;   Out: next matching directory record copied to the DMA buffer; A = position (0..3) or $FF if no
;        more.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: restore the saved search FCB pointer (DIR_FCB_PTR -> BDOS_PARAM_PTR); auto-select its
;              drive; BDOS_DIR_SCAN_NEXT advances the directory scan from the saved position; tail
;              into DISK_BUF_MOVE to deliver the hit.
;   [RE] dispatch fn 18 at $9C6B; canonical CP/M 2.2 Search Next; DIR_FCB_PTR holds the in-progress
;   search FCB.
; ----------------------------------------------------------------------
F_SNEXT_H:
        ; restore the saved Search-First FCB pointer
        LD HL,(DIR_FCB_PTR)                   ; $A8C8  2A D9 A9
        ; make it the active FCB for this scan step
        LD (BDOS_PARAM_PTR),HL                   ; $A8CB  22 43 9F
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8CE  CD 51 A8
        ; advance the directory search from the last matched entry
        CALL BDOS_DIR_SCAN_NEXT                    ; $A8D1  CD 2D A3
        ; copy the next matched entry to the DMA buffer, return its position
        JP DISK_BUF_MOVE                    ; $A8D4  C3 E9 A1
; ----------------------------------------------------------------------
; F_DELETE_H -- BDOS function 19 (Delete File): erase all directory entries matching the FCB.
;   In: BDOS_PARAM_PTR = pointer to the (possibly ambiguous) FCB.
;   Out: matching directory entries marked deleted ($E5) and their allocation freed; result via
;        DIR_RETURN_MATCH_FLAG ($FF if none / dir code).
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; F_DELETE_HND scans and erases each
;              matching directory entry (releasing its blocks); tail into the
;              directory-update/result path DIR_RETURN_MATCH_FLAG.
;   [RE] dispatch fn 19 at $9C6D; canonical CP/M 2.2 Delete File.
; ----------------------------------------------------------------------
F_DELETE_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8D7  CD 51 A8
        ; erase every matching directory entry and free its blocks
        CALL F_DELETE_HND                    ; $A8DA  CD 9C A3
        ; flush the directory and return the result code
        JP DIR_RETURN_MATCH_FLAG                    ; $A8DD  C3 01 A3
; ----------------------------------------------------------------------
; F_READ_H -- BDOS function 20 (Read Sequential): read the next 128-byte record of the open file.
;   In: BDOS_PARAM_PTR = pointer to an open FCB positioned at the next sequential record.
;   Out: one record read into the DMA buffer; A = 0 on success or a nonzero read-error/EOF code; the
;        FCB's sequential position advanced.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; jump into the sequential read core
;              (FILE_READ_SEQ).
;   [RE] dispatch fn 20 at $9C6F; canonical CP/M 2.2 Read Sequential.
; ----------------------------------------------------------------------
F_READ_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8E0  CD 51 A8
        ; read the next sequential record into the DMA buffer
        JP FILE_READ_SEQ                    ; $A8E3  C3 BC A5
; ----------------------------------------------------------------------
; F_WRITE_H -- BDOS function 21 (Write Sequential): write the next 128-byte record to the open file.
;   In: BDOS_PARAM_PTR = pointer to an open FCB; DMA buffer holds the record to write.
;   Out: one record written; A = 0 on success or a nonzero error code (disk full / R/O); FCB
;        position advanced, allocation extended as needed.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; jump into the write core
;              (FILE_WRITE_SEQ sets the write-mode flag for a normal sequential write).
;   [RE] dispatch fn 21 at $9C71; canonical CP/M 2.2 Write Sequential; the write core distinguishes
;   normal vs zero-fill write modes.
; ----------------------------------------------------------------------
F_WRITE_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8E6  CD 51 A8
        ; set the (normal) write mode and write the next sequential record
        JP FILE_WRITE_SEQ                    ; $A8E9  C3 FE A5
; ----------------------------------------------------------------------
; F_MAKE_H -- BDOS function 22 (Make File): create a new directory entry for the FCB.
;   In: BDOS_PARAM_PTR = pointer to the FCB naming the file to create.
;   Out: a fresh, empty directory entry allocated and the FCB opened against it; A = dir position or
;        $FF if the directory is full.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: CLEAR_FCB_S2 prepares the create scratch state; FCB_AUTO_DRIVE_SELECT honors the
;              drive prefix; jump into the make-directory-entry core (DIR_MAKE_ENTRY).
;   [RE] dispatch fn 22 at $9C73; canonical CP/M 2.2 Make File.
; ----------------------------------------------------------------------
F_MAKE_H:
        ; prepare directory create scratch state
        CALL CLEAR_FCB_S2                    ; $A8EC  CD 72 A1
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8EF  CD 51 A8
        ; allocate and initialize a new directory entry for the file
        JP DIR_MAKE_ENTRY                      ; $A8F2  C3 24 A5
; ----------------------------------------------------------------------
; F_RENAME_H -- BDOS function 23 (Rename File): change a file's name in its directory entries.
;   In: BDOS_PARAM_PTR = pointer to an FCB whose first 12 bytes hold the old name and bytes $10..
;       hold the new name.
;   Out: every matching directory entry's name field rewritten to the new name; result via
;        DIR_RETURN_MATCH_FLAG.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; F_RENAME_HND walks the directory rewriting
;              matched entries to the new name; tail into the directory-update/result path
;              DIR_RETURN_MATCH_FLAG.
;   [RE] dispatch fn 23 at $9C75; canonical CP/M 2.2 Rename File.
; ----------------------------------------------------------------------
F_RENAME_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A8F5  CD 51 A8
        ; rewrite every matching directory entry to the new name
        CALL F_RENAME_HND                    ; $A8F8  CD 16 A4
        ; flush the directory and return the result code
        JP DIR_RETURN_MATCH_FLAG                    ; $A8FB  C3 01 A3
; ----------------------------------------------------------------------
; DRV_LOGINVEC_H -- BDOS function 24 (Return Login Vector): report which drives are logged in.
;   In: DRV_SELECT_VECTOR = working login/select vector (bit d = drive d logged in).
;   Out: BDOS result HL = the login vector (returned via the common result-store
;        BDOS_RET_RESULT_HL).
;   Clobbers: HL.
;   Algorithm: load the working login vector and store it as the 16-bit BDOS result.
;   [RE] dispatch fn 24 at $9C77; canonical CP/M 2.2 Return Login Vector.
; ----------------------------------------------------------------------
DRV_LOGINVEC_H:
        ; HL = login vector (one bit per logged-in drive)
        LD HL,(DRV_SELECT_VECTOR)                   ; $A8FE  2A AF A9
        ; store HL as the 16-bit BDOS result
        JP BDOS_RET_RESULT_HL                   ; $A901  C3 29 A9
; ----------------------------------------------------------------------
; DRV_GET_H -- BDOS function 25 (Return Current Disk): report the current default drive.
;   In: BDOS_CUR_DRIVE = current drive number.
;   Out: BDOS result A = current drive (0=A:).
;   Clobbers: A.
;   Algorithm: load the current-drive cell and return it as the BDOS result.
;   [RE] dispatch fn 25 at $9C79; canonical CP/M 2.2 Return Current Disk.
; ----------------------------------------------------------------------
DRV_GET_H:
        ; A = current drive number
        LD A,(BDOS_CUR_DRIVE)                    ; $A904  3A 42 9F
        ; return it as the BDOS result
        JP BDOS_RET_RESULT                   ; $A907  C3 01 9F
; ----------------------------------------------------------------------
; F_DMAOFF_H -- BDOS function 26 (Set DMA Address): set the disk read/write buffer address.
;   In: DE = new DMA (disk transfer) address supplied by the caller.
;   Out: DMA_ADDR set to DE and pushed through to the BIOS disk-buffering layer.
;   Clobbers: A, HL (and RESTORE_USER_DMA clobbers).
;   Algorithm: move DE into HL, store at DMA_ADDR, jump to RESTORE_USER_DMA to apply it to the live
;              disk buffering / BIOS SETDMA.
;   [RE] dispatch fn 26 at $9C7B; canonical CP/M 2.2 Set DMA Address.
; ----------------------------------------------------------------------
F_DMAOFF_H:
        ; HL = caller's requested DMA address
        EX DE,HL                         ; $A90A  EB
        ; record the new DMA address
        LD (DMA_ADDR),HL                   ; $A90B  22 B1 A9
        ; apply the DMA address to disk buffering / BIOS
        JP RESTORE_USER_DMA                      ; $A90E  C3 DA A1
; ----------------------------------------------------------------------
; DRV_ALLOCVEC_H -- BDOS function 27 (Return Allocation Vector address).
;   In: ALLOC_VEC_PTR = base address of the current drive's allocation (block-in-use) bit vector.
;   Out: BDOS result HL = the allocation vector address.
;   Clobbers: HL.
;   Algorithm: load the allocation-vector pointer and store it as the 16-bit BDOS result.
;   [RE] dispatch fn 27 at $9C7D; canonical CP/M 2.2 Get Allocation Vector.
; ----------------------------------------------------------------------
DRV_ALLOCVEC_H:
        ; HL = address of the current drive's allocation bit vector
        LD HL,(ALLOC_VEC_PTR)                   ; $A911  2A BF A9
        ; store HL as the 16-bit BDOS result
        JP BDOS_RET_RESULT_HL                   ; $A914  C3 29 A9
; ----------------------------------------------------------------------
; DRV_ROVEC_H -- BDOS function 29 (Return Read-Only Vector): report which drives are read-only.
;   In: DRV_LOGIN_VECTOR -- here read as the read-only bit vector master copy.
;   Out: BDOS result HL = the read-only drive vector (bit d set = drive d is R/O).
;   Clobbers: HL.
;   Algorithm: load the R/O vector and store it as the 16-bit BDOS result.
;   [RE] dispatch fn 29 at $9C81; canonical CP/M 2.2 Get Read-Only Vector. [?] Source operand is the
;   DRV_LOGIN_VECTOR cell; per CP/M 2.2 the R/O vector is a distinct mask -- the symbol name may be
;   a misnomer for the R/O vector cell, or this build keeps the R/O bits in the same word.
; ----------------------------------------------------------------------
DRV_ROVEC_H:
        ; HL = read-only drive vector (one bit per R/O drive)
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A917  2A AD A9
        ; store HL as the 16-bit BDOS result
        JP BDOS_RET_RESULT_HL                   ; $A91A  C3 29 A9
; ----------------------------------------------------------------------
; F_ATTRIB_H -- BDOS function 30 (Set File Attributes): write the FCB's attribute bits into its
; directory entries.
;   In: BDOS_PARAM_PTR = pointer to the FCB carrying the desired attribute (high) bits in its
;       name/type bytes.
;   Out: matching directory entries updated with the new attributes; result via
;        DIR_RETURN_MATCH_FLAG.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; F_ATTRIB_HND walks the directory copying
;              the FCB's attribute bits into each matched entry; tail into the
;              directory-update/result path.
;   [RE] dispatch fn 30 at $9C83; canonical CP/M 2.2 Set File Attributes.
; ----------------------------------------------------------------------
F_ATTRIB_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A91D  CD 51 A8
        ; copy the FCB's attribute bits into every matching directory entry
        CALL F_ATTRIB_HND                    ; $A920  CD 3B A4
        ; flush the directory and return the result code
        JP DIR_RETURN_MATCH_FLAG                    ; $A923  C3 01 A3
; ----------------------------------------------------------------------
; DRV_DPB_H -- BDOS function 31 (Return Disk Parameter Block address).
;   In: DPB_PTR = address of the current drive's DPB (set during disk select/log-in).
;   Out: BDOS result HL = the DPB address.
;   Clobbers: HL.
;   Algorithm: load the DPB pointer and store it as the 16-bit BDOS result.
;   [RE] dispatch fn 31 at $9C85; canonical CP/M 2.2 Get DPB; falls into the shared result-store
;   BDOS_RET_RESULT_HL.
; ----------------------------------------------------------------------
DRV_DPB_H:
        ; HL = address of the current drive's Disk Parameter Block
        LD HL,(DPB_PTR)                   ; $A926  2A BB A9
; ----------------------------------------------------------------------
; BDOS_RET_RESULT_HL -- common exit: store the 16-bit value in HL as the BDOS return result.
;   In: HL = value to return to the caller.
;   Out: BDOS result cell BDOS_RETVAL = HL.
;   Clobbers: none (writes memory).
;   Algorithm: store HL at the BDOS result cell and return.
;   [RE] the HL-valued counterpart of BDOS_RET_RESULT (which returns A); used by the get-vector /
;   get-pointer functions (login vector, alloc vector, R/O vector, DPB) and fallen into from
;   DRV_DPB_H.
; ----------------------------------------------------------------------
BDOS_RET_RESULT_HL:
        ; store HL as the 16-bit BDOS result
        LD (BDOS_RETVAL),HL                   ; $A929  22 45 9F
        RET                              ; $A92C  C9
; ----------------------------------------------------------------------
; F_USERNUM_H -- BDOS function 32 (Get/Set User Code).
;   In: DRV_SELECT_ARG = caller's argument byte ($FF = 'get', else the user number to set); BDOS_STACK_TOP =
;       current user number.
;   Out: if get: BDOS result A = current user number; if set: current user number BDOS_STACK_TOP
;        updated to (arg AND $1F).
;   Clobbers: A.
;   Algorithm: if the argument is $FF, return the current user number; otherwise mask the argument
;              to 0..31 and store it as the current user number.
;   [RE] dispatch fn 32 at $9C87; canonical CP/M 2.2 Get/Set User; $FF = query.
; ----------------------------------------------------------------------
F_USERNUM_H:
        ; A = caller's argument ($FF = query current user)
        LD A,(DRV_SELECT_ARG)                    ; $A92D  3A D6 A9
        ; is this a 'get current user' request?
        CP $FF                           ; $A930  FE FF
        ; no: it is a 'set user number' request
        JP NZ,SET_USER_NUMBER                ; $A932  C2 3B A9
        ; get path: load the current user number
        LD A,(BDOS_STACK_TOP)                    ; $A935  3A 41 9F
        ; return it as the BDOS result
        JP BDOS_RET_RESULT                   ; $A938  C3 01 9F
; ----------------------------------------------------------------------
; SET_USER_NUMBER -- set path of BDOS function 32: change the current user number.
;   In: A = requested user number.
;   Out: current user number BDOS_STACK_TOP = A AND $1F (0..31).
;   Clobbers: A.
;   Algorithm: mask the requested user number to 5 bits and store it.
;   [RE] continuation of F_USERNUM_H (Get/Set User).
; ----------------------------------------------------------------------
SET_USER_NUMBER:
        ; clamp the user number to the range 0..31
        AND $1F                          ; $A93B  E6 1F
        ; store the new current user number
        LD (BDOS_STACK_TOP),A                    ; $A93D  32 41 9F
        RET                              ; $A940  C9
; ----------------------------------------------------------------------
; F_READRAND_H -- BDOS function 33 (Read Random): read the record addressed by the FCB's
; random-record field.
;   In: BDOS_PARAM_PTR = pointer to an open FCB whose r0/r1/r2 ($21..$23) hold the target record
;       number.
;   Out: that record read into the DMA buffer; A = 0 on success or a random-read error code (e.g.
;        1=reading unwritten data, 6=record number out of range); FCB positioned at that record.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; jump into the random-read core
;              (FCB_EXTENT_TO_TRKSEC_8) which seeks to the random record and reads it.
;   [RE] dispatch fn 33 at $9C89; canonical CP/M 2.2 Read Random.
; ----------------------------------------------------------------------
F_READRAND_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A941  CD 51 A8
        ; position to the FCB's random record and read it
        JP FCB_EXTENT_TO_TRKSEC_8                    ; $A944  C3 93 A7
; ----------------------------------------------------------------------
; F_WRITERAND_H -- BDOS function 34 (Write Random): write the record addressed by the FCB's
; random-record field.
;   In: BDOS_PARAM_PTR = pointer to an open FCB whose r0/r1/r2 hold the target record number; DMA
;       buffer holds the record.
;   Out: that record written; A = 0 on success or a random-write error code; file extended/allocated
;        as needed.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; jump into the random-write core
;              (FCB_EXTENT_TO_TRKSEC_9).
;   [RE] dispatch fn 34 at $9C8B; canonical CP/M 2.2 Write Random.
; ----------------------------------------------------------------------
F_WRITERAND_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A947  CD 51 A8
        ; position to the FCB's random record and write it
        JP FCB_EXTENT_TO_TRKSEC_9                    ; $A94A  C3 9C A7
; ----------------------------------------------------------------------
; F_SIZE_H -- BDOS function 35 (Compute File Size): set the FCB's random-record field to the file's
; record count.
;   In: BDOS_PARAM_PTR = pointer to the FCB naming the file.
;   Out: FCB r0/r1/r2 ($21..$23) set to the number of 128-byte records in the file (its 'virtual
;        size').
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; jump into the size-compute core
;              (FCB_ALLOC_BLOCK_NUM_2) which scans the directory extents to find the highest record
;              and writes it into the FCB random-record field.
;   [RE] dispatch fn 35 at $9C8D; canonical CP/M 2.2 Compute File Size.
; ----------------------------------------------------------------------
F_SIZE_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A94D  CD 51 A8
        ; scan the file's extents and write its record count into the FCB
        JP FCB_ALLOC_BLOCK_NUM_2                    ; $A950  C3 D2 A7
; ----------------------------------------------------------------------
; DRV_RESET_H -- BDOS function 37 (Reset Drive): mark the drives named by the caller's bit mask as
; no longer logged in.
;   In: BDOS_PARAM_PTR = caller's reset bit-mask (one bit per drive to reset); DRV_SELECT_VECTOR = working
;       login vector; DRV_LOGIN_VECTOR = master logged-in / R-O master vector.
;   Out: for each drive bit set in the mask, that drive's bit is cleared in both DRV_SELECT_VECTOR and
;        DRV_LOGIN_VECTOR, forcing a fresh log-in on next access.
;   Clobbers: A, DE, HL.
;   Algorithm: form the bitwise complement of the caller's reset mask (CPL of each byte of
;              BDOS_PARAM_PTR); AND it into DRV_SELECT_VECTOR to clear those login bits and store back; then
;              AND the now-masked login word with DRV_LOGIN_VECTOR (which also has the reset bits
;              cleared) and store back, so the master vector loses the reset drives' bits too.
;   [RE] dispatch fn 37 at $9C91; canonical CP/M 2.2 Reset Drive (selective reset). The auto-label
;   'DIR_NAME_MASK' is unrelated to its real function.
; ----------------------------------------------------------------------
DRV_RESET_H:
        ; HL = caller's reset bit-mask (one bit per drive to reset)
        LD HL,(BDOS_PARAM_PTR)                   ; $A953  2A 43 9F
        LD A,L                           ; $A956  7D
        ; complement the mask low byte (a 1 marks a drive to KEEP; 0 marks a drive being reset)
        CPL                              ; $A957  2F
        LD E,A                           ; $A958  5F
        LD A,H                           ; $A959  7C
        CPL                              ; $A95A  2F
        ; HL = working login vector
        LD HL,(DRV_SELECT_VECTOR)                   ; $A95B  2A AF A9
        ; clear the reset drives' bits in the login vector (high byte path)
        AND H                            ; $A95E  A4
        LD D,A                           ; $A95F  57
        LD A,L                           ; $A960  7D
        AND E                            ; $A961  A3
        LD E,A                           ; $A962  5F
        ; HL = master logged-in / R-O vector
        LD HL,(DRV_LOGIN_VECTOR)                   ; $A963  2A AD A9
        EX DE,HL                         ; $A966  EB
        ; store the updated login vector
        LD (DRV_SELECT_VECTOR),HL                   ; $A967  22 AF A9
        LD A,L                           ; $A96A  7D
        AND E                            ; $A96B  A3
        LD L,A                           ; $A96C  6F
        LD A,H                           ; $A96D  7C
        AND D                            ; $A96E  A2
        LD H,A                           ; $A96F  67
        ; store the master vector with the reset drives cleared
        LD (DRV_LOGIN_VECTOR),HL                   ; $A970  22 AD A9
        RET                              ; $A973  C9
; ----------------------------------------------------------------------
; FCB_AUTO_DRIVE_RESTORE -- file-operation epilogue: undo a temporary drive switch made by
; FCB_AUTO_DRIVE_SELECT, then return the BDOS result.
;   In: DRV_RESTORE_FLAG = restore-pending flag (0 = no switch was made); BDOS_PARAM_PTR = FCB pointer; DRV_SAVED_FCB_BYTE
;       = saved FCB drive byte; DRV_SAVED_DRIVE = saved drive number; BDOS_SAVED_SP = saved BDOS stack
;       pointer; BDOS_RETVAL = BDOS result.
;   Out: if a switch was pending, the FCB's drive byte and the current drive are restored to their
;        pre-call values (DRV_SET_H reselects the original drive); then control falls into
;        BDOS_RETURN_RESULT to restore the BDOS stack and deliver A = result low byte (B = high
;        byte).
;   Clobbers: A, B, HL, SP.
;   Algorithm: if no temporary switch was made (DRV_RESTORE_FLAG==0) skip to the result return; else clear the
;              FCB drive byte ($00), and if the saved original byte (DRV_SAVED_FCB_BYTE) is nonzero restore it;
;              restore the saved current drive (DRV_SAVED_DRIVE -> DRV_SELECT_ARG) and reselect it via DRV_SET_H;
;              fall into BDOS_RETURN_RESULT.
;   [RE] this is the universal file-op epilogue that pairs with FCB_AUTO_DRIVE_SELECT; the
;   'DIR_NAME_MASK' auto-label is unrelated.
; ----------------------------------------------------------------------
FCB_AUTO_DRIVE_RESTORE:
        ; was a temporary drive switch made by the preamble?
        LD A,(DRV_RESTORE_FLAG)                    ; $A974  3A DE A9
        OR A                             ; $A977  B7
        ; no switch: skip restore, go straight to the result return
        JP Z,BDOS_RETURN_RESULT                 ; $A978  CA 91 A9
        ; HL -> FCB whose drive byte was modified
        LD HL,(BDOS_PARAM_PTR)                   ; $A97B  2A 43 9F
        ; clear the FCB drive byte before restoring it
        LD (HL),$00                      ; $A97E  36 00
        ; A = saved original FCB drive-prefix byte
        LD A,(DRV_SAVED_FCB_BYTE)                    ; $A980  3A E0 A9
        OR A                             ; $A983  B7
        ; saved byte was 0 (no real prefix): nothing to put back, go to result return
        JP Z,BDOS_RETURN_RESULT                 ; $A984  CA 91 A9
        ; restore the original FCB drive-prefix byte
        LD (HL),A                        ; $A987  77
        ; A = saved current drive number
        LD A,(DRV_SAVED_DRIVE)                    ; $A988  3A DF A9
        ; set it as the drive to reselect
        LD (DRV_SELECT_ARG),A                    ; $A98B  32 D6 A9
        ; reselect the drive that was current before the call
        CALL DRV_SET_H                    ; $A98E  CD 45 A8
; ----------------------------------------------------------------------
; BDOS_RETURN_RESULT -- final BDOS exit: restore the entry stack and deliver the result to the
; caller.
;   In: BDOS_SAVED_SP = saved BDOS entry stack pointer; BDOS_RETVAL = 16-bit BDOS result.
;   Out: SP restored to the BDOS entry stack; A = result low byte, B = result high byte (HL also =
;        result).
;   Clobbers: A, B, HL, SP.
;   Algorithm: load the saved stack pointer into SP; load the 16-bit result into HL; copy L->A and
;              H->B so both the 8-bit (A) and 16-bit (HL/BA) return conventions are satisfied;
;              return to the BDOS dispatcher.
;   [RE] the common tail every BDOS function returns through; pairs the saved-SP restore with the
;   result hand-off.
; ----------------------------------------------------------------------
BDOS_RETURN_RESULT:
        ; HL = saved BDOS entry stack pointer
        LD HL,(BDOS_SAVED_SP)                   ; $A991  2A 0F 9F
        ; restore the BDOS entry stack (drop any locals)
        LD SP,HL                         ; $A994  F9
        ; HL = the 16-bit BDOS result value
        LD HL,(BDOS_RETVAL)                   ; $A995  2A 45 9F
        ; A = result low byte (8-bit return convention)
        LD A,L                           ; $A998  7D
        ; B = result high byte (16-bit return convention)
        LD B,H                           ; $A999  44
        RET                              ; $A99A  C9
; ----------------------------------------------------------------------
; F_WRITEZF_H -- BDOS function 40 (Write Random with Zero Fill): like Write Random, but newly
; allocated blocks are pre-filled with zeros.
;   In: BDOS_PARAM_PTR = pointer to an open FCB whose r0/r1/r2 hold the target record number; DMA
;       buffer holds the record.
;   Out: the record written at the random position; any block newly allocated to reach it is
;        zero-filled first; A = 0 or a random-write error code.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: FCB_AUTO_DRIVE_SELECT honors the drive prefix; set write-mode WRITE_TYPE_FLAG=2 (zero-fill);
;              C=0; call the random-record extract/seek core (BDOS_SEEK_COMPUTE) and, on success
;              (Z), perform the write (BDOS_WRITE).
;   [RE] dispatch fn 40 at $9C97; canonical CP/M 2.2 Write Random with Zero Fill; WRITE_TYPE_FLAG=2
;   distinguishes it from normal Write Random.
; ----------------------------------------------------------------------
F_WRITEZF_H:
        ; auto-select the FCB's drive prefix
        CALL FCB_AUTO_DRIVE_SELECT                    ; $A99B  CD 51 A8
        ; write-mode 2 = write random with zero fill of new blocks
        LD A,$02                         ; $A99E  3E 02
        ; select zero-fill write mode
        LD (WRITE_TYPE_FLAG),A                    ; $A9A0  32 D5 A9
        ; C=0 parameter to the random-record extract core
        LD C,$00                         ; $A9A3  0E 00
        ; decode the FCB random record and seek/allocate to it
        CALL BDOS_SEEK_COMPUTE                    ; $A9A5  CD 07 A7
        ; on success, write the record (with zero-filled new blocks)
        CALL Z,BDOS_WRITE                  ; $A9A8  CC 03 A6
        RET                              ; $A9AB  C9
EMPTY_DIR_FCB:
        DEFB    $E5                                              ; $A9AC
DRV_LOGIN_VECTOR:
        DEFB    "\0\0"    ; $A9AD
DRV_SELECT_VECTOR:
        DEFB    "\0\0"    ; $A9AF
DMA_ADDR:
        DEFB    $80,$00                                          ; $A9B1
DPB_WORK_PTR0:
        DEFB    "\0\0"    ; $A9B3
DEBLOCK_HSTREC_PTR0:
        DEFB    "\0\0"    ; $A9B5
DEBLOCK_HSTREC_PTR1:
        DEFB    "\0\0"    ; $A9B7
DIRBUF_PTR:
        DEFB    "\0\0"    ; $A9B9
DPB_PTR:
        DEFB    "\0\0"    ; $A9BB
REC_BYTE_OFFSET:
        DEFB    "\0\0"    ; $A9BD
ALLOC_VEC_PTR:
        DEFB    "\0\0"    ; $A9BF
DPB_SPT:
        DEFB    "\0\0"    ; $A9C1
DPB_BSH:
        DEFB    "\0"    ; $A9C3
DPB_BLM:
        DEFB    "\0"    ; $A9C4
DPB_EXM:
        DEFB    "\0"    ; $A9C5
MAX_BLOCK_DSM:
        DEFB    "\0\0"    ; $A9C6
DPB_REC_PTR:
        DEFB    "\0\0"    ; $A9C8
ALLOC_END_PTR:
        DEFB    "\0\0"    ; $A9CA
REC_SCAN_PTR:
        DEFB    "\0\0"    ; $A9CC
DPB_OFF:
        DEFB    "\0\0"    ; $A9CE
DPB_XLT_PTR:
        DEFB    "\0\0"    ; $A9D0
DIR_DIRTY_FLAG:
        DEFB    "\0"    ; $A9D2
RW_DIRECTION_FLAG:
        DEFB    "\0"    ; $A9D3
DIR_MATCH_FLAG:
        DEFB    "\0"    ; $A9D4
WRITE_TYPE_FLAG:
        DEFB    "\0"    ; $A9D5
DRV_SELECT_ARG:
        DEFB    "\0"    ; $A9D6
ALLOC_SLOT_INDEX:
        DEFB    "\0"    ; $A9D7
DIR_CMP_LEN:
        DEFB    "\0"    ; $A9D8
DIR_FCB_PTR:
        DEFB    "\0\0\0\0"    ; $A9D9
BLOCK_WIDTH_FLAG:
        DEFB    "\0"    ; $A9DD
DRV_RESTORE_FLAG:
        DEFB    "\0"    ; $A9DE
DRV_SAVED_DRIVE:
        DEFB    "\0"    ; $A9DF
DRV_SAVED_FCB_BYTE:
        DEFB    "\0"    ; $A9E0
FCB_RECCOUNT:
        DEFB    "\0"    ; $A9E1
FCB_EXTENT_MASKED:
        DEFB    "\0"    ; $A9E2
FCB_CURREC:
        DEFB    "\0\0"    ; $A9E3
CUR_BLOCK_NUMBER:
        DEFB    "\0\0"    ; $A9E5
BLOCK_BASE_RECORD:
        DEFB    "\0\0"    ; $A9E7
DEBLOCK_BYTE_OFF:
        DEFB    "\0"    ; $A9E9
CUR_RECORD:
        DEFB    "\0"    ; $A9EA
CUR_RECORD_HI:
        DEFB    "\0"    ; $A9EB
REC_CACHE:
        DEFS    20, $00    ; $A9EC  fill

    SAVEBIN "E:/tmp/cpm_system_full.bin", $9400, $1600
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9C00, $0E00
    ENDIF
