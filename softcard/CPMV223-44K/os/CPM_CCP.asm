; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- CCP (Console Command Processor)
; ----------------------------------------------------------------------------
; Runtime-addressed (de-skewed): ORG $9300 (CBASE), runs $9300-$9BFF. An independent
; compilation; calls the BDOS only through the $0005 ABI and references the BDOS base
; once (BDOS_FBASE). The 44K system tracks store this sector-interleaved; the disk
; producer re-applies the skew (cpm_pipeline/deskew.py :: PAGE_TO_SECTOR_223). See
; ../../docs/CPM_Skew_Findings.md.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    INCLUDE "cpm22.inc"
    INCLUDE "cpm_system_223.inc"
    ORG $9300
    ENDIF

        ; CCP_BASE ($9300): cold/warm-boot entry vector (named by cpm_system_223.inc)
        JP CCP_COLD_ENTRY
        DEFB    $C3,$08,$96
; ----------------------------------------------------------------------
; CCP_INBUF -- console line-input buffer descriptor for C_READSTR.
;   Layout: byte0 ($9306)=max length ($7F=127), byte1 ($9307)=returned count,
;     bytes2.. ($9308)=the typed command line (also the CCP work text area).
;   [RE] Standard CP/M 2.2 CCP command buffer.
; ----------------------------------------------------------------------
CCP_INBUF:
        ; max input length = 127 ($7F)
        DEFB    $7F
; ----------------------------------------------------------------------
; CCP_INLEN -- count of characters returned by the last C_READSTR (buffer fill).
;   Also doubles as the auto-command flag: nonzero on entry means a command string
;   is already staged in CCP_CMDTEXT and is re-parsed instead of re-prompting.
;   [RE]
; ----------------------------------------------------------------------
CCP_INLEN:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_CMDTEXT -- the command-line text area (CCP_INBUF+2).
;   Holds the upper-cased command line being parsed. On cold start it carries
;   16 spaces, the DRI string 'COPYRIGHT (C) 1979, DIGITAL RESEARCH  ', a NUL, then
;   73 zero pad bytes -- this fixed init doubles as the CCP scratch/line area.
;   [RE]
; ----------------------------------------------------------------------
CCP_CMDTEXT:
        DEFS    16, $20                  ; fill
        ; DRI copyright banner; also the cold-start command-line scratch fill
        DEFB    "COPYRIGHT (C) 1979, DIGITAL RESEARCH  " ; string
        DEFB    $00                      ; terminator
        DEFS    73, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_PARSEPTR -- 16-bit scan pointer into CCP_CMDTEXT used during command parse.
;   Initialized to CCP_CMDTEXT ($9308); advanced as tokens are consumed.
;   [RE]
; ----------------------------------------------------------------------
CCP_PARSEPTR:
        ; init = CCP_CMDTEXT ($9308) little-endian
        DEFB    $08,$93
; ----------------------------------------------------------------------
; CCP_TOKENPTR -- 16-bit pointer to the start of the current token.
;   Saved by the FCB builder and reused by the bad-character echo routine.
;   [RE]
; ----------------------------------------------------------------------
CCP_TOKENPTR:
        DEFB    "\0\0"
; ----------------------------------------------------------------------
; CCP_CONOUT -- write one character to the console via BDOS C_WRITE.
;   In: A = character to emit.
;   Out: none (BDOS return ignored).
;   Clobbers: C, E; BDOS clobbers per ABI.
;   Algorithm: E:=A; C:=C_WRITE(2); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
CCP_CONOUT:
        LD E,A
        ; C_WRITE = 2
        LD C,$02
        JR BDOS_JP_TAIL
; ----------------------------------------------------------------------
; CCP_SPACE -- emit a single blank to the console.
;   In: none.  Out: BC preserved.  Clobbers: A/flags.
;   Algorithm: A:=' ' ($20); fall into CCP_CONOUT_KEEPBC.
;   [RE]
; ----------------------------------------------------------------------
CCP_SPACE:
        ; space character
        LD A,$20
; ----------------------------------------------------------------------
; CCP_CONOUT_KEEPBC -- print one char (CCP_CONOUT) preserving BC.
;   In: A = character.  Out: BC unchanged.
;   Clobbers: A/flags via BDOS; BC saved/restored.
;   Algorithm: PUSH BC; call CCP_CONOUT; POP BC; RET.
;   [RE]
; ----------------------------------------------------------------------
CCP_CONOUT_KEEPBC:
        PUSH BC
        CALL CCP_CONOUT
        POP BC
        RET
; ----------------------------------------------------------------------
; CCP_CRLF -- emit a carriage-return + line-feed to the console.
;   In: none.  Out: cursor at start of next line; BC preserved.
;   Clobbers: A/flags.
;   Algorithm: print CR ($0D) then LF ($0A), each via CCP_CONOUT_KEEPBC.
;   [RE]
; ----------------------------------------------------------------------
CCP_CRLF:
        ; CR
        LD A,$0D
        CALL CCP_CONOUT_KEEPBC
        ; LF
        LD A,$0A
        JR CCP_CONOUT_KEEPBC
; ----------------------------------------------------------------------
; CCP_CRLF_MSG -- emit CR/LF then print a NUL-terminated message.
;   In: BC -> NUL-terminated message string.
;   Out: message printed after a new line.
;   Clobbers: A, HL, BC.
;   Algorithm: CCP_CRLF; HL:=BC (via PUSH BC/POP HL); fall into CCP_PUTS.
;   [RE] Used by the 'Read error' / 'No file' message printers.
; ----------------------------------------------------------------------
CCP_CRLF_MSG:
        PUSH BC
        CALL CCP_CRLF
        POP HL
; ----------------------------------------------------------------------
; CCP_PUTS -- print a NUL-terminated string to the console.
;   In: HL -> string.
;   Out: HL past the terminator on exit (loop stops at the NUL).
;   Clobbers: A, HL.
;   Algorithm: loop: A:=(HL); if A==0 RET; INC HL; emit A via CCP_CONOUT; repeat.
;   [RE]
; ----------------------------------------------------------------------
CCP_PUTS:
        LD A,(HL)
        OR A
        RET Z
        INC HL
        PUSH HL
        CALL CCP_CONOUT
        POP HL
        JR CCP_PUTS
; ----------------------------------------------------------------------
; BDOS_DRV_ALLRESET -- reset the disk system (BDOS function 13).
;   In: none.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=DRV_ALLRESET($0D); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_ALLRESET:
        ; DRV_ALLRESET = 13
        LD C,$0D
        JR BDOS_JP_TAIL
; ----------------------------------------------------------------------
; BDOS_DRV_SET -- select the default drive (BDOS function 14).
;   In: A = drive number (0=A..15=P).
;   Out: per BDOS.  Clobbers: C, E; BDOS ABI.
;   Algorithm: E:=A; C:=DRV_SET($0E); JP BDOS (shared $0005 tail).
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_SET:
        LD E,A
        ; DRV_SET = 14
        LD C,$0E
BDOS_JP_TAIL:
        JP $0005
; ----------------------------------------------------------------------
; BDOS_F_CLOSE -- close the file named by DE (BDOS function 16).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP.  Clobbers: A/flags.
;   Algorithm: C:=F_CLOSE($10); fall into BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_CLOSE:
        ; F_CLOSE = 16
        LD C,$10
BDOS_FCB_OP:
        CALL $0005
        LD (CCP_BDOS_RESULT),A
        INC A
        RET
; ----------------------------------------------------------------------
; CCP_OPEN_SUBMIT -- open the staged submit ($$$.SUB) FCB at record 0.
;   In: submit FCB at CCP_FCB (CCP_SUB_FCB).
;   Out: A/Z per BDOS_F_OPEN.  Clobbers: A/flags, DE.
;   Algorithm: clear current-record cell (CCP_FCB_CR); DE:=CCP_SUB_FCB; fall into
;     BDOS_F_OPEN.
;   [RE]
; ----------------------------------------------------------------------
CCP_OPEN_SUBMIT:
        XOR A
        LD (CCP_FCB_CR),A
        LD DE,CCP_FCB
; ----------------------------------------------------------------------
; BDOS_F_OPEN -- open the file named by DE (BDOS function 15).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP (Z = open failed).
;   Clobbers: A/flags.
;   Algorithm: C:=F_OPEN($0F); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_OPEN:
        ; F_OPEN = 15
        LD C,$0F
        JR BDOS_FCB_OP
; ----------------------------------------------------------------------
; CCP_SEARCH_FIRST_SUBMIT -- search-for-first on the submit FCB (BDOS function 17).
;   In: submit FCB at CCP_SUB_FCB.
;   Out: A/Z per BDOS_FCB_OP.  Clobbers: A/flags, DE.
;   Algorithm: DE:=CCP_SUB_FCB; C:=F_SFIRST($11); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
CCP_SEARCH_FIRST_SUBMIT:
        LD DE,CCP_FCB
        ; F_SFIRST = 17
        LD C,$11
        JR BDOS_FCB_OP
; ----------------------------------------------------------------------
; BDOS_F_SNEXT -- search-for-next matching directory entry (BDOS function 18).
;   In: prior F_SFIRST/F_SNEXT context.
;   Out: A = next directory index or $FF; Z per BDOS_FCB_OP.
;   Clobbers: A/flags.
;   Algorithm: C:=F_SNEXT($12); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_SNEXT:
        ; F_SNEXT = 18
        LD C,$12
        JR BDOS_FCB_OP
; ----------------------------------------------------------------------
; BDOS_F_DELETE -- delete the file named by DE (BDOS function 19).
;   In: DE -> FCB.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_DELETE($13); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DELETE:
        ; F_DELETE = 19
        LD C,$13
        JR BDOS_JP_TAIL
; ----------------------------------------------------------------------
; CCP_READ_SUBMIT -- read the next record of the submit FCB (BDOS function 20).
;   In: submit FCB at CCP_SUB_FCB; DMA preset by the caller.
;   Out: A/Z per BDOS_CALL_TESTERR.  Clobbers: flags, DE.
;   Algorithm: DE:=CCP_SUB_FCB; C:=F_READ($14); fall into BDOS_F_READ.
;   [RE]
; ----------------------------------------------------------------------
CCP_READ_SUBMIT:
        LD DE,CCP_FCB
; ----------------------------------------------------------------------
; BDOS_F_READ -- read the next sequential record (BDOS function 20).
;   In: DE -> FCB; DMA set elsewhere.
;   Out: A = 0 on success / nonzero on error or EOF; Z per BDOS_CALL_TESTERR.
;   Clobbers: flags.
;   Algorithm: C:=F_READ($14); fall into BDOS_CALL_TESTERR.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_READ:
        ; F_READ = 20
        LD C,$14
BDOS_CALL_TESTERR:
        CALL $0005
        OR A
        RET
; ----------------------------------------------------------------------
; BDOS_F_WRITE -- write the next sequential record (BDOS function 21).
;   In: DE -> FCB; DMA holds the record.
;   Out: A = 0 on success / nonzero on error; Z per BDOS_CALL_TESTERR.
;   Clobbers: flags.
;   Algorithm: C:=F_WRITE($15); JP BDOS_CALL_TESTERR.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_WRITE:
        ; F_WRITE = 21
        LD C,$15
        JR BDOS_CALL_TESTERR
; ----------------------------------------------------------------------
; BDOS_F_MAKE -- create the file named by DE (BDOS function 22).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP (Z = create failed/dir full).
;   Clobbers: A/flags.
;   Algorithm: C:=F_MAKE($16); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_MAKE:
        ; F_MAKE = 22
        LD C,$16
        JR BDOS_FCB_OP
; ----------------------------------------------------------------------
; BDOS_F_RENAME -- rename a file (BDOS function 23).
;   In: DE -> FCB whose first 16 bytes name the old file and second 16 the new.
;   Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_RENAME($17); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_RENAME:
        ; F_RENAME = 23
        LD C,$17
        JR BDOS_JP_TAIL
; ----------------------------------------------------------------------
; BDOS_USER_GET -- get the current user number (BDOS function 32, E=$FF).
;   In: none.  Out: A = current user number (0..15).  Clobbers: A, C, E.
;   Algorithm: E:=$FF (interrogate); fall into BDOS_USERNUM.
;   [RE]
; ----------------------------------------------------------------------
BDOS_USER_GET:
        ; $FF = interrogate (get) user number
        LD E,$FF
; ----------------------------------------------------------------------
; BDOS_USERNUM -- set/get the user number (BDOS function 32).
;   In: E = user number to set, or $FF to interrogate.
;   Out: A = user number when interrogating.  Clobbers: A, C; BDOS ABI.
;   Algorithm: C:=F_USERNUM($20); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_USERNUM:
        ; F_USERNUM = 32
        LD C,$20
        JR BDOS_JP_TAIL
; ----------------------------------------------------------------------
; CCP_SET_USERDRIVE -- write the packed user/drive byte into base page $0004.
;   In: current user (from BDOS_USER_GET) and CCP_CDISK (CCP_CUR_DRIVE, default drive).
;   Out: base-page $0004 := (user<<4 | drive); the CP/M default-drive/user cell.
;   Clobbers: A, HL.
;   Algorithm: A:=BDOS_USER_GET; A<<=4 (ADD A,A x4); OR in CCP_CDISK; store $0004.
;   [RE] $0004 (CDISK_ADDR) is the CP/M default-drive/user cell read by the warm boot.
; ----------------------------------------------------------------------
CCP_SET_USERDRIVE:
        CALL BDOS_USER_GET
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        LD HL,CCP_CUR_DRIVE
        OR (HL)
        ; store login byte (user<<4|drive) to base page $0004 (CDISK)
        LD ($0004),A
        RET
; ----------------------------------------------------------------------
; CCP_SET_DRIVE_ONLY -- write just the default drive into base-page $0004.
;   In: CCP_CDISK (CCP_CUR_DRIVE).
;   Out: $0004 := default drive (user nibble cleared).  Clobbers: A.
;   Algorithm: A:=CCP_CDISK; store to $0004.
;   [RE]
; ----------------------------------------------------------------------
CCP_SET_DRIVE_ONLY:
        LD A,(CCP_CUR_DRIVE)
        ; store default drive to base page $0004 (CDISK)
        LD ($0004),A
        RET
; ----------------------------------------------------------------------
; CCP_UPCASE -- fold one ASCII lower-case letter to upper case.
;   In: A = character.
;   Out: A = upper-cased character ('a'..'z' -> 'A'..'Z'); others unchanged.
;   Clobbers: A/flags.
;   Algorithm: if A < 'a'($61) RET; if A >= '{'($7B) RET; AND $5F to clear bit5.
;   [RE]
; ----------------------------------------------------------------------
CCP_UPCASE:
        ; below 'a' -> leave unchanged
        CP $61
        RET C
        ; above 'z' -> leave unchanged
        CP $7B
        RET NC
        ; clear bit 5: lower -> upper
        AND $5F
        RET
; ----------------------------------------------------------------------
; CCP_GETCMD -- obtain the next command line (from submit file or console).
;   In: CCP_SUBMIT_FLAG (CCP_STACK_BASE); submit FCB (CCP_SUB_FCB); CCP_INBUF buffer.
;   Out: CCP_CMDTEXT holds the upper-cased command line ready to parse;
;     CCP_PARSEPTR set to its start.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: if a $$$.SUB submit is active (CCP_SUBMIT_FLAG != 0): select its drive,
;     open + read the next record of the submit FCB into TBUFF, set its current-record
;     cell to 0 and decrement its record count, copy the 128-byte record into CCP_INBUF,
;     close the submit FCB, then poll the console for a ^C abort; if no submit (or it
;     ends/errs/aborts) discard submit (CCP_DISCARD_SUBMIT) and do a console C_READSTR
;     into CCP_INBUF. Either path falls into CCP_UPCASE_LINE.
;   [RE] Standard CP/M 2.2 CCP command-acquire with SUBMIT support.
; ----------------------------------------------------------------------
CCP_GETCMD:
        LD A,(CCP_STACK_BASE)
        OR A
        JR Z,CCP_READ_CONSOLE
        LD A,(CCP_CUR_DRIVE)
        OR A
        LD A,$00
        CALL NZ,BDOS_DRV_SET
        LD DE,CCP_SUB_FCB
        CALL BDOS_F_OPEN
        JR Z,CCP_READ_CONSOLE
        LD A,(CCP_SUB_FCB_CR)
        DEC A
        LD (CCP_SUB_PREV_REC),A
        LD DE,CCP_SUB_FCB
        CALL BDOS_F_READ
        JR NZ,CCP_READ_CONSOLE
        LD DE,CCP_INLEN
        LD HL,$0080
        LD BC,$0080
        ; copy 128 bytes TBUFF -> CCP_INBUF (the submit record)
        LDIR
        LD HL,CCP_SUB_FCB_S2
        LD (HL),$00
        INC HL
        DEC (HL)
        LD DE,CCP_SUB_FCB
        CALL BDOS_F_CLOSE
        JR Z,CCP_READ_CONSOLE
        LD A,(CCP_CUR_DRIVE)
        OR A
        CALL NZ,BDOS_DRV_SET
        LD HL,CCP_CMDTEXT
        CALL CCP_PUTS
        CALL CCP_CHECK_ABORT
        JR Z,CCP_UPCASE_LINE
        CALL CCP_DISCARD_SUBMIT
        JP CCP_PROMPT_AND_READ
CCP_READ_CONSOLE:
        CALL CCP_DISCARD_SUBMIT
        CALL CCP_SET_USERDRIVE
        ; C_READSTR = 10 (buffered console line input)
        LD C,$0A
        LD DE,CCP_INBUF
        CALL $0005
CCP_UPCASE_LINE:
        LD HL,CCP_INLEN
        LD B,(HL)
CCP_UPCASE_LOOP:
        INC HL
        LD A,B
        OR A
        JR Z,CCP_UPCASE_DONE
        LD A,(HL)
        CALL CCP_UPCASE
        LD (HL),A
        DEC B
        JR CCP_UPCASE_LOOP
CCP_UPCASE_DONE:
        LD (HL),A
        LD HL,CCP_CMDTEXT
        LD (CCP_PARSEPTR),HL
        RET
; ----------------------------------------------------------------------
; CCP_CHECK_ABORT -- poll the console; if a key is waiting, consume it.
;   In: none.
;   Out: Z set if no key was pending (continue submit); NZ if a key was read
;     (abort the running submit); A = the key on the NZ path.
;   Clobbers: A/flags.
;   Algorithm: C:=C_STAT($0B), CALL BDOS; if A==0 RET (Z); else C:=C_READ($01),
;     CALL BDOS to swallow the key; OR A; RET.
;   [RE] Lets a typed key abort an active SUBMIT batch.
; ----------------------------------------------------------------------
CCP_CHECK_ABORT:
        ; C_STAT = 11 (console status)
        LD C,$0B
        CALL $0005
        OR A
        RET Z
        ; C_READ = 1: consume the typed key
        LD C,$01
        CALL $0005
        OR A
        RET
; ----------------------------------------------------------------------
; BDOS_DRV_GET -- return the current default drive (BDOS function 25).
;   In: none.  Out: A = current drive (0..15).  Clobbers: A, C.
;   Algorithm: C:=DRV_GET($19); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_GET:
        ; DRV_GET = 25
        LD C,$19
        JP $0005
; ----------------------------------------------------------------------
; CCP_SET_DMA_TBUFF -- set the DMA address back to the default buffer TBUFF.
;   In: none.  Out: BDOS DMA := TBUFF ($0080).  Clobbers: C, DE.
;   Algorithm: DE:=TBUFF($0080); fall into BDOS_F_DMAOFF.
;   [RE]
; ----------------------------------------------------------------------
CCP_SET_DMA_TBUFF:
        ; DE = TBUFF (default DMA buffer)
        LD DE,$0080
; ----------------------------------------------------------------------
; BDOS_F_DMAOFF -- set the disk DMA (transfer) address (BDOS function 26).
;   In: DE = DMA address.  Out: per BDOS.  Clobbers: C; BDOS ABI.
;   Algorithm: C:=F_DMAOFF($1A); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DMAOFF:
        ; F_DMAOFF = 26 (set DMA)
        LD C,$1A
        JP $0005
; ----------------------------------------------------------------------
; CCP_DISCARD_SUBMIT -- end an active SUBMIT: clear the flag and delete $$$.SUB.
;   In: CCP_SUBMIT_FLAG (CCP_STACK_BASE); submit FCB (CCP_SUB_FCB); CCP_CDISK (CCP_CUR_DRIVE).
;   Out: if submit was active it is cleared, drive A selected, the submit file
;     deleted, and the default drive restored; otherwise a no-op.
;   Clobbers: A, DE.
;   Algorithm: if CCP_SUBMIT_FLAG==0 RET; clear it; select drive 0; delete submit FCB
;     (BDOS_F_DELETE); reselect CCP_CDISK (BDOS_DRV_SET).
;   [RE]
; ----------------------------------------------------------------------
CCP_DISCARD_SUBMIT:
        LD HL,CCP_STACK_BASE
        LD A,(HL)
        OR A
        RET Z
        LD (HL),$00
        XOR A
        CALL BDOS_DRV_SET
        LD DE,CCP_SUB_FCB
        CALL BDOS_F_DELETE
        LD A,(CCP_CUR_DRIVE)
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; CCP_CHECK_SERIAL -- verify the resident BDOS serial number is still intact.
;   In: CCP_SERIAL_STAMP (CCP_SERIAL_STAMP) holds the saved 6-byte CP/M serial number; the live
;     BDOS image base is at BDOS_FBASE ($9C00), whose first 6 bytes are that serial.
;   Out: returns if the 6 bytes match; otherwise jumps to the warm-boot reload/halt
;     path CCP_SERIAL_MISMATCH_HALT ($967E).
;   Clobbers: A, B, DE, HL.
;   Algorithm: compare 6 bytes at CCP_SERIAL_STAMP against the BDOS image header; on first
;     mismatch JP CCP_SERIAL_MISMATCH_HALT; on full match RET.
;   [RE] Standard CP/M 2.2 CCP serial-number self-check: a transient that overwrote
;     the resident BDOS forces a fresh system load / lock.
; ----------------------------------------------------------------------
CCP_CHECK_SERIAL:
        LD DE,CCP_SERIAL_STAMP
        LD HL,BDOS_FBASE
        ; compare 6 serial bytes
        LD B,$06
CCP_CHECK_SERIAL_LOOP:
        LD A,(DE)
        CP (HL)
        JP NZ,CCP_SERIAL_MISMATCH_HALT
        INC DE
        INC HL
        DJNZ CCP_CHECK_SERIAL_LOOP
        RET
; ----------------------------------------------------------------------
; CCP_ECHO_TOKEN -- echo the current command token to the console up to a blank.
;   In: CCP_TOKENPTR (CCP_TOKENPTR) -> start of the offending token.
;   Out: token characters printed; falls into the bad-command report.
;   Clobbers: A, HL.
;   Algorithm: CCP_CRLF; HL:=CCP_TOKENPTR; print each char until a space or NUL,
;     print '?' + CR/LF, discard submit, then JP to the warm-restart prompt.
;   [RE] The CCP's classic 'BADNAME?' error responder.
; ----------------------------------------------------------------------
CCP_ECHO_TOKEN:
        CALL CCP_CRLF
        LD HL,(CCP_TOKENPTR)
CCP_ECHO_TOKEN_LOOP:
        LD A,(HL)
        CP $20
        JR Z,CCP_REPORT_BADCMD
        OR A
        JR Z,CCP_REPORT_BADCMD
        PUSH HL
        CALL CCP_CONOUT
        POP HL
        INC HL
        JR CCP_ECHO_TOKEN_LOOP
CCP_REPORT_BADCMD:
        ; '?' marks an unknown command
        LD A,$3F
        CALL CCP_CONOUT
        CALL CCP_CRLF
        CALL CCP_DISCARD_SUBMIT
        JP CCP_PROMPT_AND_READ
; ----------------------------------------------------------------------
; CCP_AT_DELIM -- test whether the char at (DE) ends an FCB field.
;   In: DE -> current command-line char.
;   Out: Z set if the char is a terminator (NUL, ' ', '=', '_', '.', ':', ';', '<',
;     '>'); for a control char (<' ', excluding NUL) it diverts to the bad-token echo;
;     NZ for a normal filename character.
;   Clobbers: A/flags.
;   Algorithm: A:=(DE); RET Z on NUL; if A<' ' JP CCP_ECHO_TOKEN (illegal ctrl);
;     RET Z when A==' ' or A equals any field-delimiter punctuation; else NZ.
;   [RE] Field/separator classifier used while building the FCB name and type.
; ----------------------------------------------------------------------
CCP_AT_DELIM:
        LD A,(DE)
        OR A
        RET Z
        CP $20
        ; control char in name -> bad-token echo (CCP_ECHO_TOKEN)
        JR C,CCP_ECHO_TOKEN
        RET Z
        ; '=' delimiter
        CP $3D
        RET Z
        CP $5F
        RET Z
        ; '.' (name/type separator)
        CP $2E
        RET Z
        ; ':' (drive separator)
        CP $3A
        RET Z
        CP $3B
        RET Z
        CP $3C
        RET Z
        CP $3E
        RET Z
        RET
; ----------------------------------------------------------------------
; CCP_SKIP_BLANKS -- advance (DE) past any run of spaces.
;   In: DE -> command-line char.
;   Out: DE -> first non-blank (or the NUL); Z set if at end of line.
;   Clobbers: A/flags, DE.
;   Algorithm: loop: A:=(DE); RET Z on NUL; if A != ' ' RET NZ; INC DE; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_SKIP_BLANKS:
        LD A,(DE)
        OR A
        RET Z
        CP $20
        RET NZ
        INC DE
        JR CCP_SKIP_BLANKS
; ----------------------------------------------------------------------
; CCP_HL_ADD_A -- add the unsigned A to HL (16-bit add of an 8-bit offset).
;   In: HL = base, A = offset.
;   Out: HL = HL + A.  Clobbers: A, HL, flags.
;   Algorithm: A:=A+L; L:=A; if no carry RET; else INC H; RET.
;   [RE] Used to index the FCB by 0 or 16 (parse FCB1 vs FCB2).
; ----------------------------------------------------------------------
CCP_HL_ADD_A:
        ADD A,L
        LD L,A
        RET NC
        INC H
        RET
; ----------------------------------------------------------------------
; CCP_PARSE_FCB1 -- parse the first command-tail filename into FCB at offset 0.
;   In: CCP_PARSEPTR (CCP_PARSEPTR) -> current parse position in CCP_CMDTEXT.
;   Out: command FCB (CCP_FCB) filled with drive+name+type; CCP_PARSEPTR advanced;
;     CCP_DRIVEGIVEN (CCP_FCB_DRIVE_PREFIX) set if an explicit drive prefix was present.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: A:=0 (FCB offset 0); fall into CCP_BUILD_FCB.
;   [RE]
; ----------------------------------------------------------------------
CCP_PARSE_FCB1:
        ; offset 0 -> first FCB (command FCB +0)
        LD A,$00
; ----------------------------------------------------------------------
; CCP_BUILD_FCB -- parse one filename token from the command tail into an FCB.
;   In: A = FCB byte offset (0 for FCB1, 16 for FCB2); CCP_PARSEPTR -> scan point.
;   Out: the FCB at CCP_FCB+offset holds {drive, 8-char NAME, 3-char TYPE} with '*'
;     expanded to '?' and unused positions blank-padded; the 3 trailing extent/record
;     bytes are zeroed; CCP_PARSEPTR / CCP_TOKENPTR advanced past the token;
;     CCP_DRIVEGIVEN (CCP_FCB_DRIVE_PREFIX) set to the parsed drive if a 'd:' prefix was present;
;     A = count of '?' wildcards in the 11 name+type bytes (nonzero => ambiguous FCB).
;   Clobbers: A, BC, DE, HL.
;   Algorithm: point HL at FCB+offset (CCP_HL_ADD_A); clear CCP_DRIVEGIVEN; load DE
;     from CCP_PARSEPTR and skip leading blanks; save token start to CCP_TOKENPTR;
;     detect an optional 'd:' drive prefix and store the drive into FCB[0]; copy up to
;     8 name chars, skip an over-long name, blank-pad a short name; if a '.' follows copy
;     up to 3 type chars else blank-pad the type; zero the 3 trailing FCB bytes; save the
;     parse pointer; finally count the '?' wildcards (falls into FCB_WILDCARD_SCAN).
;   [RE] Classic CP/M 2.2 CCP command-tail FCB parser.
; ----------------------------------------------------------------------
CCP_BUILD_FCB:
        LD HL,CCP_FCB
        CALL CCP_HL_ADD_A
        PUSH HL
        PUSH HL
        XOR A
        LD (CCP_FCB_DRIVE_PREFIX),A
        LD HL,(CCP_PARSEPTR)
        EX DE,HL
        CALL CCP_SKIP_BLANKS
        EX DE,HL
        LD (CCP_TOKENPTR),HL
        EX DE,HL
        POP HL
        LD A,(DE)
        OR A
        JR Z,CCP_FCB_DRIVE_DEFAULT
        ; letter -> 1-based drive number (carry clear after CCP_AT_DELIM path)
        SBC A,$40
        LD B,A
        INC DE
        LD A,(DE)
        ; is the next char ':' (drive prefix)?
        CP $3A
        JR Z,CCP_FCB_DRIVE_EXPLICIT
        DEC DE
CCP_FCB_DRIVE_DEFAULT:
        LD A,(CCP_CUR_DRIVE)
        LD (HL),A
        JR CCP_BUILD_FCB_NAME_SETUP
CCP_FCB_DRIVE_EXPLICIT:
        LD A,B
        LD (CCP_FCB_DRIVE_PREFIX),A
        LD (HL),B
        INC DE
CCP_BUILD_FCB_NAME_SETUP:
        LD B,$08
CCP_FCB_NAME_LOOP:
        CALL CCP_AT_DELIM
        JR Z,CCP_FCB_NAME_PAD
        INC HL
        CP $2A
        JR NZ,CCP_FCB_NAME_STORE
        ; '*' wildcard -> store '?' in the name field
        LD (HL),$3F
        JR CCP_FCB_NAME_NEXT
CCP_FCB_NAME_STORE:
        LD (HL),A
        INC DE
CCP_FCB_NAME_NEXT:
        DJNZ CCP_FCB_NAME_LOOP
CCP_FCB_NAME_SKIP:
        CALL CCP_AT_DELIM
        JR Z,CCP_FCB_TYPE_BEGIN
        INC DE
        JR CCP_FCB_NAME_SKIP
CCP_FCB_NAME_PAD:
        INC HL
        LD (HL),$20
        DJNZ CCP_FCB_NAME_PAD
CCP_FCB_TYPE_BEGIN:
        LD B,$03
        CP $2E
        JR NZ,CCP_FCB_TYPE_PAD
        INC DE
CCP_FCB_TYPE_LOOP:
        CALL CCP_AT_DELIM
        JR Z,CCP_FCB_TYPE_PAD
        INC HL
        CP $2A
        JR NZ,CCP_FCB_TYPE_STORE
        ; '*' wildcard -> store '?' in the type field
        LD (HL),$3F
        JR CCP_FCB_TYPE_NEXT
CCP_FCB_TYPE_STORE:
        LD (HL),A
        INC DE
CCP_FCB_TYPE_NEXT:
        DJNZ CCP_FCB_TYPE_LOOP
CCP_FCB_TYPE_SKIP:
        CALL CCP_AT_DELIM
        JR Z,CCP_FCB_ZERO_TRAILER
        INC DE
        JR CCP_FCB_TYPE_SKIP
CCP_FCB_TYPE_PAD:
        INC HL
        LD (HL),$20
        DJNZ CCP_FCB_TYPE_PAD
CCP_FCB_ZERO_TRAILER:
        LD B,$03
CCP_FCB_ZERO_LOOP:
        INC HL
        LD (HL),$00
        DJNZ CCP_FCB_ZERO_LOOP
        EX DE,HL
        LD (CCP_PARSEPTR),HL
        POP HL
        LD BC,$000B
FCB_WILDCARD_SCAN:
        INC HL
        LD A,(HL)
        ; is this name/type byte the '?' wildcard?
        CP $3F
        JR NZ,FCB_WILDCARD_SCAN_1
        INC B
FCB_WILDCARD_SCAN_1:
        DEC C
        JR NZ,FCB_WILDCARD_SCAN
        LD A,B
        OR A
        RET
; ----------------------------------------------------------------------
; CCP_BUILTIN_NAMES -- table of the six built-in command names, 4 bytes each.
;   Layout: 'DIR ','ERA ','TYPE','SAVE','REN ','USER' (24 bytes, blank-padded).
;   Indexed 0..5 by SEARCH_BUILTIN; the matched index then selects a handler.
;   [RE]
; ----------------------------------------------------------------------
CCP_BUILTIN_NAMES:
        DEFB    "DIR ERA TYPESAVEREN USER" ; string
; ----------------------------------------------------------------------
; CCP_SERIAL_STAMP -- 6-byte CP/M serial-number stamp embedded in the CCP.
;   Compared against the first 6 bytes of the BDOS image header (BDOS_FBASE, $9C00)
;   by CCP_CHECK_SERIAL; a mismatch means the CCP and BDOS are from different copies
;   and the check jumps to CCP_SERIAL_MISMATCH_HALT. Opaque serial data, not code.
;   [RE] DELTA vs 2.20: 2.23 serial = BD 16 00 01 4D 40; 2.20 = BD 16 00 00 16 DF
;   (different licensed-copy serial; this is the documented per-copy fingerprint).
; ----------------------------------------------------------------------
CCP_SERIAL_STAMP:
        DEFB    $BD,$16,$00,$01,$4D,$40
; ----------------------------------------------------------------------
; SEARCH_BUILTIN -- match the parsed command word against the six built-in names.
;   In: parsed command FCB name field at CCP_FCB_NAME (the command word is the first 4+ chars).
;   Out: A = command index 0..5 when a built-in matches with a trailing space; on no
;     match the loop runs C up to 6 and returns A = 6 (>=6 means not a built-in, falls
;     through to the external-command dispatch slot). Carry is NOT a result flag.
;   Clobbers: A, B, C, DE, HL.
;   Algorithm: for command index C=0..5, point HL at the 4-byte name entry in
;     CCP_BUILTIN_NAMES and DE at the parsed command bytes; compare 4 bytes; on a full
;     match require the next parsed byte to be a space and return C; else advance HL past
;     this entry and try the next index.
;   [RE]
; ----------------------------------------------------------------------
SEARCH_BUILTIN:
        LD HL,CCP_BUILTIN_NAMES
        LD C,$00
SEARCH_BUILTIN_NEXT:
        LD A,C
        ; tried all 6 built-ins? (>=6 -> not a built-in)
        CP $06
        RET NC
        LD DE,CCP_FCB_NAME
        ; compare 4 name chars
        LD B,$04
SEARCH_BUILTIN_CMP:
        LD A,(DE)
        CP (HL)
        JR NZ,SEARCH_BUILTIN_SKIP
        INC DE
        INC HL
        DJNZ SEARCH_BUILTIN_CMP
        LD A,(DE)
        CP $20
        JR NZ,SEARCH_BUILTIN_ADVANCE
        LD A,C
        RET
SEARCH_BUILTIN_SKIP:
        INC HL
        DJNZ SEARCH_BUILTIN_SKIP
SEARCH_BUILTIN_ADVANCE:
        INC C
        JR SEARCH_BUILTIN_NEXT
; ----------------------------------------------------------------------
; CCP_WARM_ENTRY -- warm-boot entry to the Console Command Processor.
;   In: (cold path enters one line below at CCP_COLD_ENTRY=$960C with C = login byte:
;     high nibble = user number, low nibble = default drive.)
;   Out: does not return normally; reads, parses, and dispatches one command.
;   Clobbers: all.
;   Algorithm: warm entry clears the submit/auto-command flag (CCP_INLEN) then falls into
;     CCP_COLD_ENTRY, which sets the user (F_USERNUM=32), resets disk (DRV_ALLRESET=13),
;     selects the default drive (DRV_SET=14), and if no pending submit prints the 'd>'
;     prompt, reads a line, sets DMA to TBUFF, parses into the command FCB, looks it up
;     (SEARCH_BUILTIN) and JP (HL)'s through the dispatch table.
;   [RE]
; ----------------------------------------------------------------------
CCP_WARM_ENTRY:
        XOR A
        ; clear the submit/auto-command flag (CCP_INLEN)
        LD (CCP_INLEN),A
CCP_COLD_ENTRY:
        LD SP,CCP_STACK_BASE
        PUSH BC
        LD A,C
        RRA
        RRA
        RRA
        RRA
        AND $0F
        LD E,A
        CALL BDOS_USERNUM
        CALL BDOS_DRV_ALLRESET
        LD (CCP_STACK_BASE),A
        POP BC
        LD A,C
        AND $0F
        LD (CCP_CUR_DRIVE),A
        CALL BDOS_DRV_SET
        LD A,(CCP_INLEN)
        OR A
        JR NZ,CCP_PARSE_AND_DISPATCH
CCP_PROMPT_AND_READ:
        LD SP,CCP_STACK_BASE
        CALL CCP_CRLF
        CALL BDOS_DRV_GET
        ADD A,$41
        CALL CCP_CONOUT
        LD A,$3E
        CALL CCP_CONOUT
        CALL CCP_GETCMD
CCP_PARSE_AND_DISPATCH:
        LD DE,$0080
        CALL BDOS_F_DMAOFF
        CALL BDOS_DRV_GET
        LD (CCP_CUR_DRIVE),A
        CALL CCP_PARSE_FCB1
        CALL NZ,CCP_ECHO_TOKEN
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        JP NZ,CCP_DRIVE_SELECT
        CALL SEARCH_BUILTIN
        LD HL,CCP_CMD_DISPATCH_TBL
        LD E,A
        LD D,$00
        ADD HL,DE
        ADD HL,DE
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        JP (HL)
CCP_CMD_DISPATCH_TBL:
        DEFW    DIR_CMD
        DEFW    ERA_CMD
        DEFW    TYPE_CMD
        DEFW    SAVE_CMD
        DEFW    REN_CMD
        DEFW    CCP_CMD_USER
        DEFW    CCP_DRIVE_SELECT
CCP_SERIAL_MISMATCH_HALT:
        LD HL,$76F3
        LD (CCP_BASE),HL
        LD HL,CCP_BASE
        JP (HL)
; ----------------------------------------------------------------------
; PRINT_READ_ERROR -- emit the 'Read error' message on a fresh line.
;   In: none.  Out: message printed via CCP_CRLF_MSG.  Clobbers: A, BC, HL.
;   Algorithm: BC:=MSG_READ_ERROR; JP CCP_CRLF_MSG (CRLF then print-until-NUL).
;   [RE] CCP disk read-error report.
; ----------------------------------------------------------------------
PRINT_READ_ERROR:
        LD BC,MSG_READ_ERROR
        JP CCP_CRLF_MSG
; ----------------------------------------------------------------------
; MSG_READ_ERROR -- NUL-terminated console message 'Read error'.
;   [RE]
; ----------------------------------------------------------------------
MSG_READ_ERROR:
        DEFB    "Read error"             ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; PRINT_NO_FILE -- emit the 'No file' message on a fresh line.
;   In: none.  Out: message printed via CCP_CRLF_MSG.  Clobbers: A, BC, HL.
;   Algorithm: BC:=MSG_NO_FILE; JP CCP_CRLF_MSG.
;   [RE] CCP 'file not found' report.
; ----------------------------------------------------------------------
PRINT_NO_FILE:
        LD BC,MSG_NO_FILE
        JP CCP_CRLF_MSG
; ----------------------------------------------------------------------
; MSG_NO_FILE -- NUL-terminated console message 'No file'.
;   [RE]
; ----------------------------------------------------------------------
MSG_NO_FILE:
        DEFB    "No file"                ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CCP_PARSE_USERNUM -- parse a decimal user number from the command FCB name.
;   In: command FCB name field at CCP_FCB_NAME.
;   Out: A = parsed user number (0..15); on a non-digit or out-of-range value jumps
;     to CCP_ECHO_TOKEN (bad-command echo). CCP_DRIVEGIVEN must be 0 (no drive prefix).
;   Clobbers: A, B, C, D, HL.
;   Algorithm: re-parse the FCB (CCP_PARSE_FCB1); reject if a drive prefix was given;
;     accumulate decimal digits in B (B = B*10 + digit) with overflow/range checks;
;     trailing blanks must pad the field; return B in A.
;   [RE] Backs the USER built-in command.
; ----------------------------------------------------------------------
CCP_PARSE_USERNUM:
        CALL CCP_PARSE_FCB1
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        JP NZ,CCP_ECHO_TOKEN
        LD HL,CCP_FCB_NAME
        LD BC,$000B
CCP_PARSE_USERNUM_LOOP:
        LD A,(HL)
        CP $20
        JR Z,CCP_PARSE_USERNUM_TAIL
        INC HL
        ; ASCII digit -> binary ('0'=$30)
        SUB $30
        ; reject non-digit (>= 10)
        CP $0A
        JP NC,CCP_ECHO_TOKEN
        LD D,A
        LD A,B
        AND $E0
        JP NZ,CCP_ECHO_TOKEN
        LD A,B
        RLCA
        RLCA
        RLCA
        ADD A,B
        JP C,CCP_ECHO_TOKEN
        ADD A,B
        JP C,CCP_ECHO_TOKEN
        ADD A,D
        JP C,CCP_ECHO_TOKEN
        LD B,A
        DEC C
        JR NZ,CCP_PARSE_USERNUM_LOOP
        RET
CCP_PARSE_USERNUM_TAIL:
        LD A,(HL)
        CP $20
        JP NZ,CCP_ECHO_TOKEN
        INC HL
        DEC C
        JR NZ,CCP_PARSE_USERNUM_TAIL
        LD A,B
        RET
; ----------------------------------------------------------------------
; CCP_FCB_BYTE_AT -- fetch one byte of the command FCB at TBUFF+(A+C).
;   In: A = offset, C = base offset; the FCB region begins at TBUFF ($0080).
;   Out: A = the FCB byte at $0080+C+A.  Clobbers: A, HL.
;   Algorithm: HL:=TBUFF($0080); A:=A+C; HL+=A (CCP_HL_ADD_A); A:=(HL).
;   [RE] Used by the directory lister to read FCB/dir-entry bytes.
; ----------------------------------------------------------------------
CCP_FCB_BYTE_AT:
        LD HL,$0080
        ADD A,C
        CALL CCP_HL_ADD_A
        LD A,(HL)
        RET
; ----------------------------------------------------------------------
; CCP_RESET_USER_IF_NEEDED -- clear the FCB drive byte and restore the user/drive.
;   In: CCP_DRIVEGIVEN (CCP_FCB_DRIVE_PREFIX); CCP_CDISK (CCP_CUR_DRIVE).
;   Out: FCB drive byte (CCP_FCB) := 0; if a different drive was named, reselect it.
;   Clobbers: A, HL.
;   Algorithm: clear CCP_FCB; if CCP_DRIVEGIVEN==0 RET; (drive-1) compared to CDISK;
;     if equal RET; else BDOS_DRV_SET to the named drive.
;   [RE]
; ----------------------------------------------------------------------
CCP_RESET_USER_IF_NEEDED:
        XOR A
        LD (CCP_FCB),A
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        RET Z
        DEC A
        LD HL,CCP_CUR_DRIVE
        CP (HL)
        RET Z
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; CCP_RESTORE_DEFAULT_DRIVE -- if the FCB carried an explicit 'd:' prefix, re-select the default
; drive.
;   In: CCP_FCB_DRIVE_PREFIX (=CCP_FCB_DRIVE_PREFIX) = explicit drive prefix parsed from the command
;       FCB (0 = none);
;       CCP_CUR_DRIVE (=CCP_CUR_DRIVE) = current default drive.
;   Out: when the FCB had a prefix that differs from the default, the BDOS current disk is set back
;        to CCP_CUR_DRIVE via DRV_SET (fn 14); else a no-op.
;   Clobbers: A, E, HL.
;   Algorithm: if prefix is 0 return; convert 1-based prefix to 0-based; if it already equals the
;     default drive return; else A:=CCP_CUR_DRIVE and tail-call BDOS_DRV_SET. Variant of
;     RESOLVE_DRIVE_PREFIX that does NOT zero the FCB drive byte and restores the DEFAULT drive.
;   [RE] Transferred from the fully-RE'd 2.20-44K twin; byte-identical structure (offset -$100).
; ----------------------------------------------------------------------
CCP_RESTORE_DEFAULT_DRIVE:
        ; A = explicit drive prefix from the parsed FCB (0 = none)
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        RET Z
        ; convert 1-based prefix (1..16) to 0-based drive number
        DEC A
        LD HL,CCP_CUR_DRIVE
        CP (HL)
        RET Z
        ; load the DEFAULT drive code as the DRV_SET argument (restore it)
        LD A,(CCP_CUR_DRIVE)
        ; tail-call BDOS DRV_SET (fn 14) to re-select the default drive
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; DIR_CMD -- CCP built-in DIR: list directory entries matching the command-tail filespec.
;   In: command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: matching names printed (here 4 per line as 'd:NAME EXT'); 'No file' if none. Returns via
;        the CCP command-complete path.
;   Clobbers: A,B,C,D,E,H,L.
;   Algorithm: build the search FCB from the tail (CCP_PARSE_LINE_FCB); select the requested drive
;     (RESOLVE_DRIVE_PREFIX). If the first name byte is blank (no name), fall into DIR_WILDCARD_FILL
;     to set all 11 name/type bytes to '?' (match every file). Falls into DIR_START_SEARCH.
;   [RE] Transferred from the 2.20-44K twin DIR_CMD. NOTE: this 2.23 build lists 4 entries per line
;     (AND $03) where the 2.20 twin used 2 per line (AND $01) -- a real version difference.
; ----------------------------------------------------------------------
DIR_CMD:
        ; parse the command tail into the search FCB
        CALL CCP_PARSE_FCB1
        ; select the drive named by the filespec prefix (RESOLVE_DRIVE_PREFIX)
        CALL CCP_RESET_USER_IF_NEEDED
        LD HL,CCP_FCB_NAME
        LD A,(HL)
        ; first FCB name byte blank? => no filespec name given, wildcard everything
        CP $20
        JR NZ,DIR_START_SEARCH
        ; 11 = length of the FCB name+type field to wildcard-fill
        LD B,$0B
; ----------------------------------------------------------------------
; DIR_WILDCARD_FILL -- overwrite the 11 FCB name+type bytes with '?' so DIR matches every file.
;   In: HL = first name byte of the search FCB; B = 11.
;   Out: 11 bytes set to '?' ($3F); HL advanced; B = 0. Falls into DIR_START_SEARCH.
;   Clobbers: B, HL (A preserved).
;   Algorithm: store '?' through HL, advance, decrement count, repeat 11 times.
;   [RE] 2.20-44K twin DIR_WILDCARD_FILL.
; ----------------------------------------------------------------------
DIR_WILDCARD_FILL:
        LD (HL),$3F
        INC HL
        DJNZ DIR_WILDCARD_FILL
; ----------------------------------------------------------------------
; DIR_START_SEARCH -- begin the DIR directory scan and test the first SEARCH result.
;   In: search FCB populated.
;   Out: per-line entry counter E:=0 and pushed; BDOS SEARCH_FIRST (fn 17) issued; on no match
;        'No file' printed. Falls into DIR_CMD_2.
;   Clobbers: A, E, flags; pushes DE (the entry counter).
;   Algorithm: E:=0, PUSH DE; call SEARCH_FIRST (CCP_SEARCH_FIRST_SUBMIT = CCP_SEARCH_FIRST_SUBMIT);
;              on no-match (Z)
;     print 'No file' (PRINT_NO_FILE = PRINT_NO_FILE). Falls into DIR_CMD_2.
;   [RE] 2.20-44K twin DIR_START_SEARCH.
; ----------------------------------------------------------------------
DIR_START_SEARCH:
        ; E = directory-entry counter (drives the per-line column layout)
        LD E,$00
        PUSH DE
        ; BDOS SEARCH_FIRST (fn 17) on the search FCB
        CALL CCP_SEARCH_FIRST_SUBMIT
        ; no directory match: print 'No file'
        CALL Z,PRINT_NO_FILE
; ----------------------------------------------------------------------
; DIR_CMD_2 -- DIR main loop: format one matched directory entry from the DMA buffer (TBUFF).
;   In: Z from the preceding SEARCH set when the directory is exhausted; BDOS stored the matched
;       entry's directory code (0..3) in CCP_BDOS_RESULT (=CCP_BDOS_RESULT); the 32-byte entry sits
;       in TBUFF.
;   Out: one entry printed as 'd:NAME EXT'; loops via SEARCH_NEXT; exits to DIR_EXIT when done.
;   Clobbers: A,B,C,D,E,H,L.
;   Algorithm: if no further match go DIR_EXIT. code*32 (RRCA x3, AND $60) = byte offset of the
;              entry
;     in TBUFF, into C. Read the entry flag byte at +10; if bit7 set skip it. Else pop/inc/re-push
;     the
;     counter and AND $03 to test the 4-column parity: nonzero continues the current line
;     (DIR_FMT_ENTRY_COLS), zero starts a fresh CRLF line then prints the drive letter
;     ('A'+drive)+':'.
;   [RE] 2.20-44K twin DIR_CMD_2. DIFFERENCE: 2.23 masks AND $03 (4 entries/line) vs 2.20 AND $01.
; ----------------------------------------------------------------------
DIR_CMD_2:
        ; SEARCH returned no (further) match: finish DIR
        JR Z,DIR_EXIT
        ; BDOS directory code (0..3) of the matched entry
        LD A,(CCP_BDOS_RESULT)
        RRCA
        RRCA
        RRCA
        ; code*32: byte offset of the matched 32-byte entry within TBUFF
        AND $60
        LD C,A
        ; offset 10 within the entry = the file flag/attribute byte
        LD A,$0A
        CALL CCP_FCB_BYTE_AT
        ; move flag bit7 into carry
        RLA
        ; flag bit7 set: skip this entry, go SEARCH_NEXT
        JR C,DIR_NEXT_OR_EXIT
        POP DE
        LD A,E
        INC E
        PUSH DE
        ; parity of the entry index => 4-per-line column layout (2.20 twin used AND $01 = 2/line)
        AND $03
        PUSH AF
        ; nonzero column: continue on the same line with a separator
        JR NZ,DIR_FMT_ENTRY_COLS
        CALL CCP_CRLF
        PUSH BC
        CALL BDOS_DRV_GET
        POP BC
        ; convert drive 0..15 to letter 'A'..'P'
        ADD A,$41
        CALL CCP_CONOUT_KEEPBC
        LD A,$3A
        CALL CCP_CONOUT_KEEPBC
        JR DIR_PRINT_NAME
; ----------------------------------------------------------------------
; DIR_FMT_ENTRY_COLS -- emit the column separator before a continued entry on the current line.
;   In: reached for a nonzero column index (continuing the current output line).
;   Out: a space separator and a ':' printed; falls into DIR_PRINT_NAME.
;   Clobbers: A.
;   Algorithm: print the inter-column space (CCP_SPACE), then ':' , then continue into the name
;              print.
;   [RE] 2.20-44K twin DIR_FMT_ENTRY_COLS.
; ----------------------------------------------------------------------
DIR_FMT_ENTRY_COLS:
        CALL CCP_SPACE
        LD A,$3A
        CALL CCP_CONOUT_KEEPBC
; ----------------------------------------------------------------------
; DIR_PRINT_NAME -- print one directory entry's 11-character NAME EXT field.
;   In: C = base offset of the entry within TBUFF.
;   Out: bytes 1..11 of the name/type printed with high bits stripped.
;   Clobbers: A, B.
;   Algorithm: print a leading space, B:=1 (first name byte, skipping the drive byte at 0); fall
;              into
;     DIR_EMIT_NAME_CHAR.
;   [RE] 2.20-44K twin DIR_PRINT_NAME.
; ----------------------------------------------------------------------
DIR_PRINT_NAME:
        CALL CCP_SPACE
        LD B,$01
; ----------------------------------------------------------------------
; DIR_EMIT_NAME_CHAR -- loop emitting the characters of a directory name/type field.
;   In: B = current name byte index (1..11); C = entry base offset in TBUFF; the column-parity value
;       pushed by DIR_CMD_2 is on the stack.
;   Out: each char printed (blanks emitted as one space); a separator space between name (1..8) and
;        type (9..11).
;   Clobbers: A, B.
;   Algorithm: fetch TBUFF[C+B], strip the high bit (AND $7F). If non-blank, print it. If blank,
;     recover the saved parity (POP/PUSH AF) and CP $03: in THIS 2.23 build the saved value is AND
;     $03
;     (0..3), so the CP $03 type-peek block at LD A,$09 is LIVE -- when the column is the last (3)
;     it
;     peeks the first type byte and, if the extension is all blank, stops the entry early. (In the
;     2.20 twin the saved value was AND $01, so that block was dead.)
;   [RE] 2.20-44K twin DIR_EMIT_NAME_CHAR, with the type-peek block now live (4-column build).
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR:
        LD A,B
        CALL CCP_FCB_BYTE_AT
        ; strip the directory attribute high bit
        AND $7F
        CP $20
        JR NZ,DIR_PUT_NAME_CHAR
        POP AF
        PUSH AF
        ; saved column-parity == 3 (last of 4)? LIVE here (AND $03); dead in the 2.20 AND $01 twin
        CP $03
        JR NZ,DIR_EMIT_NAME_CHAR_2
        ; offset 9 = first type byte, peeked to detect an all-blank extension
        LD A,$09
        CALL CCP_FCB_BYTE_AT
        AND $7F
        CP $20
        ; all-blank extension at the last column: stop and fetch the next entry
        JR Z,DIR_SEARCH_NEXT
; ----------------------------------------------------------------------
; DIR_EMIT_NAME_CHAR_2 -- substitute a single space for a blank name char, then emit it.
;   In: reached when the current name character is a blank to be rendered as one space.
;   Out: A:=' '; falls into DIR_PUT_NAME_CHAR.
;   Clobbers: A.
;   [RE] 2.20-44K twin DIR_EMIT_NAME_CHAR_2.
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR_2:
        LD A,$20
; ----------------------------------------------------------------------
; DIR_PUT_NAME_CHAR -- output one name character and advance to the next name-field position.
;   In: A = char; B = current name byte index; C = entry base offset.
;   Out: char printed; B incremented; loops, inserts the name/type gap, or finishes the field.
;   Clobbers: A, B.
;   Algorithm: CONOUT the char (CCP_CONOUT_KEEPBC). INC B; if B==12 the 11-char field is done (go
;     DIR_SEARCH_NEXT). When B==9 (start of type) print an extra space then continue; else continue.
;   [RE] 2.20-44K twin DIR_PUT_NAME_CHAR.
; ----------------------------------------------------------------------
DIR_PUT_NAME_CHAR:
        CALL CCP_CONOUT_KEEPBC
        INC B
        LD A,B
        ; reached index 12 (all 11 name+type chars done)?
        CP $0C
        JR NC,DIR_SEARCH_NEXT
        ; reached the first type-field byte (index 9)? print the name/ext separator
        CP $09
        JR NZ,DIR_EMIT_NAME_CHAR
        CALL CCP_SPACE
        JR DIR_EMIT_NAME_CHAR
; ----------------------------------------------------------------------
; DIR_SEARCH_NEXT -- drop the saved column-parity value, then fall into the break-check +
; SEARCH_NEXT.
;   In: the column-parity value pushed by DIR_CMD_2 is on the stack.
;   Out: that value discarded; falls into DIR_NEXT_OR_EXIT (the per-line entry counter remains
;        beneath).
;   Clobbers: AF.
;   [RE] 2.20-44K twin DIR_SEARCH_NEXT.
; ----------------------------------------------------------------------
DIR_SEARCH_NEXT:
        POP AF
; ----------------------------------------------------------------------
; DIR_NEXT_OR_EXIT -- poll for a console abort, then issue BDOS SEARCH_NEXT to continue DIR.
;   In: search FCB still set from SEARCH_FIRST.
;   Out: if a key is waiting DIR aborts to DIR_EXIT; else SEARCH_NEXT (fn 18) runs and the loop
;        resumes at DIR_CMD_2.
;   Clobbers: A.
;   Algorithm: CCP_CHECK_ABORT (CCP_CHECK_ABORT); if NZ (key) exit DIR; else SEARCH_NEXT
;              (BDOS_F_SNEXT) and loop.
;   [RE] 2.20-44K twin DIR_NEXT_OR_EXIT.
; ----------------------------------------------------------------------
DIR_NEXT_OR_EXIT:
        ; poll console for a break/abort keypress (BDOS fn 11 then fn 1)
        CALL CCP_CHECK_ABORT
        JR NZ,DIR_EXIT
        ; BDOS SEARCH_NEXT (fn 18) for the following entry
        CALL BDOS_F_SNEXT
        JR DIR_CMD_2
; ----------------------------------------------------------------------
; DIR_EXIT -- DIR completion: drop the saved entry counter and return to the CCP command-complete
; path.
;   In: the per-line entry counter (pushed in DIR_START_SEARCH) is on the stack.
;   Out: stack balanced; jumps to the shared CCP end-of-command handler (CCP_RETURN_OK =
;        CCP_RETURN_OK).
;   Clobbers: DE.
;   [RE] 2.20-44K twin DIR_EXIT.
; ----------------------------------------------------------------------
DIR_EXIT:
        POP DE
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; ERA_CMD -- CCP built-in ERA (ERASE): delete files matching the command-tail filespec.
;   In: command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: matching files deleted; if the spec is all-wildcard ('*.*', 11 '?' bytes) the user is
;        prompted 'All (y/n)?' first. Returns via the CCP command-complete path.
;   Clobbers: A,B,C,D,E,H,L.
;   Algorithm: CCP_PARSE_LINE_FCB returns A = count of '?' wildcards. If A==11 print 'All (y/n)?',
;     read a line, abort unless it is a single 'Y'. Then fall into ERA_DO_DELETE.
;   [RE] 2.20-44K twin ERA_CMD. NOTE: 2.23 prompt text is lowercase 'All (y/n)?' (2.20: 'ALL
;   (Y/N)?').
; ----------------------------------------------------------------------
ERA_CMD:
        CALL CCP_PARSE_FCB1
        ; all 11 name/type bytes wildcard => spec was '*.*' (erase everything)
        CP $0B
        JR NZ,ERA_DO_DELETE
        ; point at the 'All (y/n)?' confirmation prompt
        LD BC,MSG_ERA_CONFIRM
        CALL CCP_CRLF_MSG
        CALL CCP_GETCMD
        LD HL,CCP_INLEN
        DEC (HL)
        JP NZ,CCP_PROMPT_AND_READ
        INC HL
        LD A,(HL)
        ; reply must be 'Y'
        CP $59
        JP NZ,CCP_PROMPT_AND_READ
        INC HL
        LD (CCP_PARSEPTR),HL
; ----------------------------------------------------------------------
; ERA_DO_DELETE -- perform the ERA file deletion after any confirmation.
;   In: FCB holds the (possibly wildcard) filespec.
;   Out: BDOS F_DELETE executed; 'No file' printed when nothing matched; returns via the command
;        path.
;   Clobbers: A, D, E.
;   Algorithm: select the drive (RESOLVE_DRIVE_PREFIX = CCP_RESET_USER_IF_NEEDED); DE:=FCB; F_DELETE
;              (BDOS_F_DELETE, fn 19).
;     INC A so a $FF (no-file) return becomes 0/Z; on Z print 'No file'. Jump to CCP_RETURN_OK.
;   [RE] 2.20-44K twin ERA_DO_DELETE.
; ----------------------------------------------------------------------
ERA_DO_DELETE:
        CALL CCP_RESET_USER_IF_NEEDED
        LD DE,CCP_FCB
        ; BDOS F_DELETE (fn 19) on the FCB
        CALL BDOS_F_DELETE
        ; map $FF (no file deleted) to 0 so Z signals 'nothing matched'
        INC A
        ; nothing deleted: print 'No file'
        CALL Z,PRINT_NO_FILE
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; MSG_ERA_CONFIRM -- ASCIIZ prompt 'All (y/n)?' shown before erasing every file (ERA *.*).
;   [RE] 2.20-44K twin MSG_ERA_CONFIRM. The 2.23 text is lowercase 'All (y/n)?' (2.20 was 'ALL
;   (Y/N)?').
; ----------------------------------------------------------------------
MSG_ERA_CONFIRM:
        DEFB    "All (y/n)?"             ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; TYPE_CMD -- CCP built-in TYPE: open the named text file and echo its contents to the console.
;   In: command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: file contents printed record by record until the $1A EOF marker or a console break; on open
;        failure the offending name is echoed. Returns via the CCP command-complete path.
;   Clobbers: A,B,C,D,E,H,L.
;   Algorithm: re-parse the FCB; if flagged (NZ, ambiguous) reject via CCP_ECHO_TOKEN
;              (CCP_ECHO_TOKEN).
;     Select the drive, OPEN the file (CCP_OPEN_SUBMIT = CCP_OPEN_SUBMIT); on failure (Z) report it.
;     Emit a
;     leading CRLF, prime the per-record byte counter to $FF, enter TYPE_PRINT_LOOP.
;   [RE] 2.20-44K twin TYPE_CMD.
; ----------------------------------------------------------------------
TYPE_CMD:
        CALL CCP_PARSE_FCB1
        ; bad/ambiguous filespec: echo the offending token and abort
        JP NZ,CCP_ECHO_TOKEN
        CALL CCP_RESET_USER_IF_NEEDED
        ; BDOS OPEN (fn 15) on the FCB (CCP_OPEN_SUBMIT)
        CALL CCP_OPEN_SUBMIT
        ; open failed (file not found): go report it (TYPE_NO_FILE)
        JR Z,TYPE_NO_FILE
        CALL CCP_CRLF
        LD HL,CCP_TYPE_REC_INDEX
        ; prime the per-record byte counter so the first pass forces a record read
        LD (HL),$FF
; ----------------------------------------------------------------------
; TYPE_PRINT_LOOP -- TYPE inner loop: read each record and print its bytes until EOF.
;   In: file opened; per-record byte counter (CCP_TYPE_REC_INDEX) primed to $FF.
;   Out: each 128-byte record's chars echoed; stops at $1A (Ctrl-Z) EOF, a nonzero read, or a break.
;   Clobbers: A,B,C,D,E,H,L.
;   Algorithm: when the byte counter >= $80 (record consumed) read the next record (F_READ fn 20);
;     nonzero status -> TYPE_READ_DONE; reset the counter to 0. Then fall into TYPE_EMIT_CHAR.
;   [RE] 2.20-44K twin TYPE_PRINT_LOOP.
; ----------------------------------------------------------------------
TYPE_PRINT_LOOP:
        LD HL,CCP_TYPE_REC_INDEX
        LD A,(HL)
        ; consumed a whole 128-byte record? then read the next one
        CP $80
        JR C,TYPE_EMIT_CHAR
        PUSH HL
        ; BDOS F_READ (fn 20) next record into the DMA buffer
        CALL CCP_READ_SUBMIT
        POP HL
        ; nonzero status: EOF or error -> TYPE_READ_DONE
        JR NZ,TYPE_READ_DONE
        XOR A
        LD (HL),A
; ----------------------------------------------------------------------
; TYPE_EMIT_CHAR -- emit one buffered char of the TYPE'd file, advancing the record index.
;   In: HL -> the record-byte-index cell (CCP_TYPE_REC_INDEX); the current 128-byte record is in
;       TBUFF ($0080).
;   Out: char written via C_WRITE; loops for the next char; returns to the command-complete exit on
;        $1A (EOF) or a console-abort keypress.
;   Clobbers: A, HL, flags.
;   Algorithm: INC the index; form TBUFF+offset and fetch the byte. If $1A (Ctrl-Z soft EOF) finish.
;     Else C_WRITE it (CCP_CONOUT), poll for an abort (CCP_CHECK_ABORT = CCP_CHECK_ABORT); on abort
;     finish; else
;     loop back to TYPE_PRINT_LOOP.
;   [RE] 2.20-44K twin TYPE_EMIT_CHAR; $1A = CP/M text EOF sentinel.
; ----------------------------------------------------------------------
TYPE_EMIT_CHAR:
        INC (HL)
        LD HL,$0080
        CALL CCP_HL_ADD_A
        LD A,(HL)
        ; $1A = Ctrl-Z, the CP/M soft end-of-file marker -> stop TYPE
        CP $1A
        JP Z,CCP_RETURN_OK
        CALL CCP_CONOUT
        ; poll the console for a key (fn 11/fn 1); nonzero = user aborted TYPE
        CALL CCP_CHECK_ABORT
        JP NZ,CCP_RETURN_OK
        JR TYPE_PRINT_LOOP
; ----------------------------------------------------------------------
; TYPE_READ_DONE -- handle a failed/short F_READ during TYPE (EOF vs read error).
;   In: A = F_READ return (1 = normal EOF, other nonzero = read error).
;   Out: on normal EOF returns quietly to the CCP exit; on a read error prints 'Read error' then
;        falls into TYPE_NO_FILE.
;   Clobbers: A, BC, flags.
;   Algorithm: DEC A; if 0 (was 1 = EOF) go CCP_RETURN_OK; else call the 'Read error' printer
;              (PRINT_READ_ERROR).
;   [RE] 2.20-44K twin TYPE_READ_DONE. NOTE: 2.23 message is lowercase 'Read error' (2.20 'READ
;   ERROR').
; ----------------------------------------------------------------------
TYPE_READ_DONE:
        ; F_READ code 1 (normal EOF) -> 0 here; any other code stays nonzero = real error
        DEC A
        JP Z,CCP_RETURN_OK
        ; print the 'Read error' message (disk read failure)
        CALL PRINT_READ_ERROR
; ----------------------------------------------------------------------
; TYPE_NO_FILE -- TYPE error/not-found tail: restore the caller's drive and echo the bad command.
;   In: entered when the TYPE target could not be opened, or after a read error.
;   Out: re-selects the user's original drive (CCP_RESTORE_DEFAULT_DRIVE =
;        CCP_RESTORE_DEFAULT_DRIVE) and jumps to the
;        bad-command echo (CCP_ECHO_TOKEN = CCP_ECHO_TOKEN); does not return.
;   Clobbers: A, HL, flags.
;   [RE] 2.20-44K twin TYPE_NO_FILE.
; ----------------------------------------------------------------------
TYPE_NO_FILE:
        CALL CCP_RESTORE_DEFAULT_DRIVE
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; SAVE_CMD -- CCP built-in SAVE: write N pages of memory from the TPA to a new disk file.
;   In: command line 'SAVE n filespec'; n = decimal 256-byte page count; filespec built into the
;       FCB.
;   Out: creates the file and writes n*2 128-byte records from $0100; on dir/disk-full prints 'No
;        space'.
;   Clobbers: A,BC,DE,HL,flags.
;   Algorithm: parse the page count (PARSE_FCB_DECIMAL = CCP_PARSE_USERNUM) and stash it; build the
;              filename FCB
;     and reject a malformed spec; resolve the drive; F_DELETE any existing file (fn 19); F_MAKE (fn
;     22)
;     and on failure branch to SAVE_DISK_FULL; clear the FCB CR byte; count := pages*2, source :=
;     $0100;
;     enter SAVE_WRITE_LOOP.
;   [RE] 2.20-44K twin SAVE_CMD; source data begins at the TPA base $0100.
; ----------------------------------------------------------------------
SAVE_CMD:
        ; parse the leading decimal page-count argument (PARSE_FCB_DECIMAL)
        CALL CCP_PARSE_USERNUM
        PUSH AF
        CALL CCP_PARSE_FCB1
        JP NZ,CCP_ECHO_TOKEN
        CALL CCP_RESET_USER_IF_NEEDED
        LD DE,CCP_FCB
        PUSH DE
        CALL BDOS_F_DELETE
        POP DE
        ; BDOS F_MAKE (fn 22): create the new (empty) file
        CALL BDOS_F_MAKE
        ; no free directory entry: jump to the 'No space' error
        JR Z,SAVE_DISK_FULL
        XOR A
        LD (CCP_FCB_CR),A
        POP AF
        LD L,A
        LD H,$00
        ; pages*2 = number of 128-byte records to write
        ADD HL,HL
        ; DE = source pointer, starting at the TPA base $0100
        LD DE,$0100
; ----------------------------------------------------------------------
; SAVE_WRITE_LOOP -- write the remaining 128-byte records of a SAVE from successive memory slices.
;   In: HL = remaining record count; DE = current source/DMA address (starts $0100, +$80 per
;       record);
;       the FCB is the open output file.
;   Out: writes each record; on a write failure (disk full) branches to SAVE_DISK_FULL; falls into
;        SAVE_CLOSE when the count reaches zero.
;   Clobbers: A,BC,DE,HL,flags.
;   Algorithm: while HL!=0: DEC it; precompute NEXT source ($0080+DE) onto the stack; set DMA to the
;     CURRENT DE (F_DMAOFF fn 26); F_WRITE (fn 21) from the FCB; POP the advanced pointer; on
;     nonzero
;     status -> SAVE_DISK_FULL; else loop.
;   [RE] 2.20-44K twin SAVE_WRITE_LOOP.
; ----------------------------------------------------------------------
SAVE_WRITE_LOOP:
        LD A,H
        OR L
        JR Z,SAVE_CLOSE
        DEC HL
        PUSH HL
        LD HL,$0080
        ADD HL,DE
        PUSH HL
        ; BDOS F_DMAOFF (fn 26): point the DMA at the CURRENT source slice (DE)
        CALL BDOS_F_DMAOFF
        LD DE,CCP_FCB
        ; BDOS F_WRITE (fn 21): append the record to the file
        CALL BDOS_F_WRITE
        POP DE
        POP HL
        ; write failed (disk full): jump to the 'No space' error
        JR NZ,SAVE_DISK_FULL
        JR SAVE_WRITE_LOOP
; ----------------------------------------------------------------------
; SAVE_CLOSE -- close the SAVE output file after all records are written.
;   In: the FCB = the open output file.
;   Out: closes the file; on success continues to SAVE_FINISH, on close failure falls into
;        SAVE_DISK_FULL.
;   Clobbers: A, C, DE, flags.
;   Algorithm: DE:=FCB, F_CLOSE (BDOS_F_CLOSE, fn 16); the wrapper INC's A so a $FF failure becomes
;              0; a
;     nonzero result means success -> SAVE_FINISH; a zero (failure) falls into SAVE_DISK_FULL.
;   [RE] 2.20-44K twin SAVE_CLOSE.
; ----------------------------------------------------------------------
SAVE_CLOSE:
        LD DE,CCP_FCB
        ; BDOS F_CLOSE (fn 16): flush the directory entry for the saved file
        CALL BDOS_F_CLOSE
        ; map the $FF close-error code to 0; a valid directory code becomes nonzero = success
        INC A
        JR NZ,SAVE_FINISH
; ----------------------------------------------------------------------
; SAVE_DISK_FULL -- SAVE error tail: report 'No space' and clean up.
;   In: entered on F_MAKE failure, a failed F_WRITE, or a failed F_CLOSE.
;   Out: prints 'No space', then falls into SAVE_FINISH.
;   Clobbers: A,BC,DE,HL,flags.
;   Algorithm: BC:=MSG_NO_SPACE, print it (CRLF + string via CCP_CRLF_MSG = CCP_CRLF_MSG), fall
;              through.
;   [RE] 2.20-44K twin SAVE_DISK_FULL. NOTE: 2.23 text is lowercase 'No space' (2.20 'NO SPACE').
; ----------------------------------------------------------------------
SAVE_DISK_FULL:
        LD BC,MSG_NO_SPACE
        CALL CCP_CRLF_MSG
; ----------------------------------------------------------------------
; SAVE_FINISH -- restore the default DMA address and return to the CCP after a SAVE.
;   In: none.
;   Out: resets the BDOS DMA to the default $0080 (CCP_SET_DMA_TBUFF = CCP_SET_DMA_TBUFF) and jumps
;        to
;        CCP_RETURN_OK; does not return.
;   Clobbers: A, C, DE, flags.
;   [RE] 2.20-44K twin SAVE_FINISH.
; ----------------------------------------------------------------------
SAVE_FINISH:
        CALL CCP_SET_DMA_TBUFF
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; MSG_NO_SPACE -- ASCIIZ console message 'No space' shown when SAVE runs out of room.
;   [RE] 2.20-44K twin MSG_NO_SPACE (2.23 text lowercase 'No space').
; ----------------------------------------------------------------------
MSG_NO_SPACE:
        DEFB    "No space"               ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; REN_CMD -- CCP built-in REN(AME): rename an existing file given 'REN newname=oldname'.
;   In: command line 'REN newfile=oldfile'; the new name is parsed first into the FCB.
;   Out: renames oldfile to newfile via F_RENAME; errors are 'File exists', 'No file', or a bad
;        echo.
;   Clobbers: A,B,DE,HL,flags.
;   Algorithm: parse the new-name FCB; reject a malformed spec; save the new name's drive prefix;
;     resolve the drive; SEARCH_FIRST for the new name and if it EXISTS branch to REN_FILE_EXISTS;
;     copy the 16-byte new-name FCB to the second slot at +16 (CCP_FCB_SECOND) so F_RENAME sees
;     old@+0/new@+16;
;     skip blanks and require '=' ($3D) or '_' ($5F) (else REN_ERROR); then parse the old name.
;   [RE] 2.20-44K twin REN_CMD; F_RENAME FCB carries old name at +0, new name at +16.
; ----------------------------------------------------------------------
REN_CMD:
        CALL CCP_PARSE_FCB1
        JP NZ,CCP_ECHO_TOKEN
        LD A,(CCP_FCB_DRIVE_PREFIX)
        PUSH AF
        CALL CCP_RESET_USER_IF_NEEDED
        ; BDOS SEARCH_FIRST (fn 17): does the NEW name already exist?
        CALL CCP_SEARCH_FIRST_SUBMIT
        ; new name already exists: report 'File exists'
        JR NZ,REN_FILE_EXISTS
        LD HL,CCP_FCB
        LD DE,CCP_FCB_SECOND
        LD BC,$0010
        ; copy the 16-byte new-name FCB into the second FCB slot at +16 (the rename pair)
        LDIR
        LD HL,(CCP_PARSEPTR)
        EX DE,HL
        CALL CCP_SKIP_BLANKS
        ; '=' separator between new and old names
        CP $3D
        JR Z,REN_PARSE_OLD
        ; '_' is also accepted as the new=old separator
        CP $5F
        JR NZ,REN_ERROR
; ----------------------------------------------------------------------
; REN_PARSE_OLD -- parse the old-name FCB after the separator and validate the drive match.
;   In: scan pointer is at the '=' / '_' separator; the new-name drive prefix is on the stack.
;   Out: builds the old-name FCB and confirms both names target the same drive; on mismatch/parse
;        error branches to REN_ERROR; falls into REN_DO_RENAME.
;   Clobbers: A,B,DE,HL,flags.
;   Algorithm: step past the separator and update CCP_PARSEPTR; parse the old-name FCB; on error
;     -> REN_ERROR. Recover the new name's prefix into B; read the old name's prefix; if 0 accept;
;     else the two prefixes must be equal (store B and compare) else REN_ERROR.
;   [RE] 2.20-44K twin REN_PARSE_OLD.
; ----------------------------------------------------------------------
REN_PARSE_OLD:
        EX DE,HL
        INC HL
        LD (CCP_PARSEPTR),HL
        CALL CCP_PARSE_FCB1
        JR NZ,REN_ERROR
        POP AF
        LD B,A
        LD HL,CCP_FCB_DRIVE_PREFIX
        LD A,(HL)
        OR A
        JR Z,REN_DO_RENAME
        CP B
        LD (HL),B
        JR NZ,REN_ERROR
; ----------------------------------------------------------------------
; REN_DO_RENAME -- locate the old file and perform the directory rename.
;   In: FCB holds old name at +0 and new name at +16; B = the agreed drive prefix.
;   Out: searches for the old name; if not found -> REN_OLD_NOT_FOUND; else F_RENAME and return.
;   Clobbers: A,B,DE,HL,flags.
;   Algorithm: store B into the drive-prefix cell; zero the FCB drive byte (default drive);
;              SEARCH_FIRST
;     for the old name (fn 17) -- if absent -> REN_OLD_NOT_FOUND; else F_RENAME (BDOS_F_RENAME, fn
;     23) and
;     finish at CCP_RETURN_OK.
;   [RE] 2.20-44K twin REN_DO_RENAME.
; ----------------------------------------------------------------------
REN_DO_RENAME:
        LD (HL),B
        XOR A
        LD (CCP_FCB),A
        CALL CCP_SEARCH_FIRST_SUBMIT
        JR Z,REN_OLD_NOT_FOUND
        LD DE,CCP_FCB
        ; BDOS F_RENAME (fn 23): rename old -> new using the paired FCB
        CALL BDOS_F_RENAME
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; REN_OLD_NOT_FOUND -- REN error: the source file to rename does not exist.
;   In: none.
;   Out: prints 'No file' (PRINT_NO_FILE) and returns to CCP_RETURN_OK.
;   Clobbers: A, BC, flags.
;   [RE] 2.20-44K twin REN_OLD_NOT_FOUND.
; ----------------------------------------------------------------------
REN_OLD_NOT_FOUND:
        CALL PRINT_NO_FILE
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; REN_ERROR -- REN bad-command tail: restore the drive and echo the offending command.
;   In: entered on a missing/invalid separator, an old-name parse error, or a drive mismatch.
;   Out: restores the default drive (CCP_RESTORE_DEFAULT_DRIVE = CCP_RESTORE_DEFAULT_DRIVE) and
;        jumps to the
;        bad-command echo (CCP_ECHO_TOKEN = CCP_ECHO_TOKEN); does not return.
;   Clobbers: A, HL, flags.
;   [RE] 2.20-44K twin REN_ERROR.
; ----------------------------------------------------------------------
REN_ERROR:
        CALL CCP_RESTORE_DEFAULT_DRIVE
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; REN_FILE_EXISTS -- REN error: the requested new name already exists on disk.
;   In: none.
;   Out: prints 'File exists' and returns to CCP_RETURN_OK.
;   Clobbers: A, BC, flags.
;   [RE] 2.20-44K twin REN_FILE_EXISTS; the new name was found by the earlier SEARCH_FIRST.
; ----------------------------------------------------------------------
REN_FILE_EXISTS:
        LD BC,CCP_MSG_FILE_EXISTS
        CALL CCP_CRLF_MSG
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; CCP_MSG_FILE_EXISTS -- ASCIIZ console message 'File exists'.
;   [RE] 2.20-44K twin CCP_MSG_FILE_EXISTS (2.23 text lowercase 'File exists').
; ----------------------------------------------------------------------
CCP_MSG_FILE_EXISTS:
        DEFB    "File exists"            ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CCP_CMD_USER -- built-in USER command: select the user-number area (0..15).
;   In: command FCB; the numeric argument sits in the FCB name field (CCP_FCB_NAME).
;   Out: BDOS user number set to the parsed value; joins CCP_RETURN_OK_NOCRLF.
;   Clobbers: A, E, and the BDOS-call registers.
;   Algorithm: PARSE_FCB_DECIMAL (CCP_PARSE_USERNUM) parses a decimal number into A; if >= $10 (16)
;              it is out
;     of the 0..15 range, so abort to CCP_ECHO_TOKEN. E:=value; reject a blank name byte (no
;     argument);
;     BDOS F_USERNUM (fn 32, C=$20) to set the user area; join CCP_RETURN_OK_NOCRLF.
;   [RE] 2.20-44K twin CCP_CMD_USER (keyword table index 5).
; ----------------------------------------------------------------------
CCP_CMD_USER:
        CALL CCP_PARSE_USERNUM
        ; user numbers are 0..15; reject $10 (16) or more as out of range
        CP $10
        JP NC,CCP_ECHO_TOKEN
        LD E,A
        LD A,(CCP_FCB_NAME)
        CP $20
        JP Z,CCP_ECHO_TOKEN
        ; BDOS F_USERNUM (fn 32, C=$20): set the user number to E
        CALL BDOS_USERNUM
        JP CCP_RETURN_OK_NOCRLF
; ----------------------------------------------------------------------
; CCP_DRIVE_SELECT -- handle a drive-prefixed command word: bare 'd:' (change default drive) or
;   'd:NAME' (drive-prefixed transient).
;   In: command FCB; CCP_FCB_DRIVE_PREFIX (CCP_FCB_DRIVE_PREFIX) non-zero (a 'd:' was typed).
;   Out: if no command word followed, the default drive is changed and control joins
;        CCP_RETURN_OK_NOCRLF; if a name followed, control falls to CCP_CMD_TRANSIENT.
;   Clobbers: A, and the BDOS-call registers.
;   Algorithm: reached from the dispatcher when CCP_FCB_DRIVE_PREFIX != 0 (dispatch slot 6). First
;              CCP_CHECK_SERIAL
;     (CCP_CHECK_SERIAL) verifies the CCP/BDOS serial still matches. If the FCB name is non-blank a
;     command
;     word follows -> CCP_CMD_TRANSIENT. Else (bare 'd:') if the prefix is 0 return OK; else DEC it
;     to
;     0-based, store as current drive (CCP_CUR_DRIVE), write it to $0004 (CCP_SET_DRIVE_ONLY =
;     CCP_SET_DRIVE_ONLY), and
;     DRV_SET (BDOS_DRV_SET), then return OK.
;   [RE] 2.20-44K twin CCP_DRIVE_SELECT; NOT the keyword USER built-in -- this is dispatch slot 6.
; ----------------------------------------------------------------------
CCP_DRIVE_SELECT:
        ; verify the CCP and BDOS serial numbers still match (integrity check, CCP_CHECK_SERIAL)
        CALL CCP_CHECK_SERIAL
        LD A,(CCP_FCB_NAME)
        CP $20
        ; a name follows the drive prefix: treat as a transient program load
        JR NZ,CCP_CMD_TRANSIENT
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        JP Z,CCP_RETURN_OK_NOCRLF
        DEC A
        PUSH AF
        CALL BDOS_DRV_SET
        POP AF
        LD (CCP_CUR_DRIVE),A
        CALL CCP_SET_DRIVE_ONLY
        JP CCP_RETURN_OK_NOCRLF
; ----------------------------------------------------------------------
; CCP_CMD_TRANSIENT -- load and run a transient (.COM) program from disk.
;   In: parsed command FCB holding the command name; command tail.
;   Out: on success transfers control to the loaded program at the TPA ($0100); on error joins
;        CCP_BAD_LOAD / CCP_NO_FILE; never returns normally.
;   Clobbers: all registers; rebuilds the TPA and page-zero command tail.
;   Algorithm: require a blank FCB extension (else CCP_ECHO_TOKEN); select the command's drive;
;              force
;     the extension to 'COM' (copy the 3-byte CCP_COM_EXT = CCP_COM_EXT); open the file; if not
;     found go
;     CCP_NO_FILE. Then loop reading $80-byte records into the TPA from $0100, until the load
;     address
;     would reach the CCP base ($9300, abort = BAD LOAD) or EOF. On clean EOF, launch.
;   [RE] 2.20-44K twin CCP_CMD_TRANSIENT. NOTE the entry self-checks the FCB type, then forces COM.
; ----------------------------------------------------------------------
CCP_CMD_TRANSIENT:
        CALL BDOS_USER_GET
        LD (FASTLOAD_DRIVE_SAVE),A
        LD DE,CCP_FCB_EXT
        LD A,(DE)
        CP $20
        ; explicit extension given: not a bare transient command, echo+abort
        JP NZ,CCP_ECHO_TOKEN
        PUSH DE
        CALL CCP_RESET_USER_IF_NEEDED
        POP DE
        ; source = the constant 'COM' extension text (CCP_COM_EXT)
        LD HL,CCP_COM_EXT
        LD BC,$0003
        ; force the FCB type field to COM (3-byte copy)
        LDIR
; ----------------------------------------------------------------------
; CCP_TRANSIENT_OPEN -- open the forced NAME.COM and start the load (or report not found).
;   In: FCB type field forced to 'COM'.
;   Out: on open failure (no file) -> CCP_NO_FILE; else proceeds and falls into the DPB fast-path
;        check (CCP_LOAD_CHECK_FASTPATH).
;   Clobbers: A, DE, HL.
;   Algorithm: OPEN the file (CCP_OPEN_SUBMIT = CCP_OPEN_SUBMIT); on Z (not found) jump to
;              CCP_NO_FILE; else
;     proceed via the drive/record reset helper (FASTLOAD_SET_DRIVE) into the loader.
;   [RE] 2.20 twin equivalent is the CCP_CMD_TRANSIENT open path; the fast-path branch below is
;   2.23-only.
; ----------------------------------------------------------------------
CCP_TRANSIENT_OPEN:
        ; BDOS OPEN (fn 15) the forced NAME.COM (CCP_OPEN_SUBMIT)
        CALL CCP_OPEN_SUBMIT
        JR NZ,CCP_LOAD_PREP
        CALL BDOS_USER_GET
        OR A
        ; open failed (file not found): go CCP_NO_FILE
        JP Z,CCP_NO_FILE
        XOR A
        CALL FASTLOAD_SET_DRIVE
        JR CCP_TRANSIENT_OPEN
; ----------------------------------------------------------------------
; CCP_LOAD_PREP -- prepare the transient load: optional drive re-select, then test the disk for the
;   SoftCard RPC fast-load path.
;   In: the .COM file is open.
;   Out: falls into CCP_LOAD_CHECK_FASTPATH which queries the BDOS DPB.
;   Clobbers: A, HL.
;   Algorithm: if the FCB carried a drive prefix re-select it (BDOS_DRV_SET); fall through.
;   [RE] 2.20 twin: part of the CCP_CMD_TRANSIENT load setup; the DPB/fast-load test below is
;     SoftCard-specific to 2.23 (no 2.20 equivalent).
; ----------------------------------------------------------------------
CCP_LOAD_PREP:
        LD A,(CCP_FCB)
        OR A
        JR Z,CCP_LOAD_CHECK_FASTPATH
        DEC A
        CALL BDOS_DRV_SET
; ----------------------------------------------------------------------
; CCP_LOAD_CHECK_FASTPATH -- 2.23-ONLY: query the disk parameter block and choose the SoftCard RPC
;   fast-loader when the open file lives on a compatible disk.
;   In: the .COM file is open; HL set by the preceding code.
;   Out: if the DPB signature matches, JP to FASTLOAD_RPC_BEGIN (FASTLOAD_RPC_BEGIN) to load via the
;        6502 RWTS;
;        otherwise falls into the standard byte-by-byte CCP_LOAD_LOOP at $0100.
;   Clobbers: A, HL.
;   Algorithm: C:=$1F (BDOS F_DPB = fn 31, get Disk Parameter Block address), CALL BDOS; advance HL
;              by
;     2 and read the DPB byte at +2, comparing CP $03; if it differs take the standard loader. Else
;     advance to +5 and CP $8B; on a match JP FASTLOAD_RPC_BEGIN (FASTLOAD_RPC_BEGIN). The exact DPB
;     fields are
;     [RE] the block-shift / a SoftCard format marker that gates the accelerated path.
;   [RE] NO 2.20 EQUIVALENT -- this is a SoftCard 2.23 addition; FLAGGED. Fields verified as DPB by
;     the F_DPB call; their precise meaning is partly UNKNOWN.
; ----------------------------------------------------------------------
CCP_LOAD_CHECK_FASTPATH:
        ; BDOS F_DPB (fn 31): get the Disk Parameter Block address for the open drive
        LD C,$1F
        CALL $0005
        INC HL
        INC HL
        LD A,(HL)
        ; DPB field at +2 vs $03: gate for the SoftCard RPC fast-load path [RE]
        CP $03
        JR NZ,CCP_LOAD_LOOP
        INC HL
        INC HL
        INC HL
        LD A,(HL)
        ; DPB field at +5 vs $8B: second fast-load gate marker [RE]
        CP $8B
        ; DPB matches: use the SoftCard 6502-RWTS accelerated loader (FASTLOAD_RPC_BEGIN)
        JP Z,FASTLOAD_RPC_BEGIN
; ----------------------------------------------------------------------
; CCP_LOAD_LOOP -- standard read of the .COM file record-by-record into the TPA (no fast path).
;   In: HL = next TPA load address ($0100 on entry); FCB open.
;   Out: loops until EOF (-> CCP_LOAD_DONE) or until the load pointer reaches the CCP base
;        ($9300, -> CCP_BAD_LOAD).
;   Clobbers: A, DE, HL.
;   Algorithm: HL:=$0100 then fall into the body: PUSH the load address, set DMA (F_DMAOFF), F_READ
;              one
;     $80-byte record; nonzero -> CCP_LOAD_DONE; else advance HL by $80 and compare against CCP_BASE
;     ($9300) via a 16-bit subtract: if HL >= base the program is too big -> CCP_BAD_LOAD; else
;     loop.
;   [RE] 2.20-44K twin CCP_LOAD_LOOP (the slow loader); the 2.20 ceiling was $9400 vs $9300 here.
; ----------------------------------------------------------------------
CCP_LOAD_LOOP:
        LD HL,$0100
; ----------------------------------------------------------------------
; CCP_LOAD_LOOP_BODY -- one iteration of the standard transient read loop.
;   In: HL = current TPA load pointer.
;   Out: reads one record to (HL); on EOF/error -> CCP_LOAD_DONE; advances HL; on TPA overflow ->
;        CCP_BAD_LOAD; else loops.
;   Clobbers: A, DE, HL.
;   Algorithm: set DMA to HL (F_DMAOFF = BDOS_F_DMAOFF); F_READ (BDOS_F_READ, fn 20); nonzero ->
;              CCP_LOAD_DONE;
;     HL += $80; LD DE,CCP_BASE (CCP base = $9300); 16-bit HL-DE; NC (HL>=base) -> CCP_BAD_LOAD;
;     loop.
;   [RE] 2.20-44K twin CCP_LOAD_LOOP body; image ceiling is the CCP base CCP_BASE ($9300).
; ----------------------------------------------------------------------
CCP_LOAD_LOOP_BODY:
        PUSH HL
        EX DE,HL
        CALL BDOS_F_DMAOFF
        LD DE,CCP_FCB
        ; BDOS F_READ (fn 20): read one 128-byte record into the TPA
        CALL BDOS_F_READ
        ; nonzero = EOF or read error: finish the load (CCP_LOAD_DONE)
        JR NZ,CCP_LOAD_DONE
        POP HL
        LD DE,$0080
        ADD HL,DE
        ; CCP base ($9300): the ceiling the loaded program must not reach
        LD DE,CCP_BASE
        OR A
        PUSH HL
        SBC HL,DE
        POP HL
        ; load reached the CCP: program too large -> CCP_BAD_LOAD
        JR NC,CCP_BAD_LOAD
        JR CCP_LOAD_LOOP_BODY
; ----------------------------------------------------------------------
; CCP_LOAD_DONE -- finish a transient load and decide EOF vs error.
;   In: the BDOS read returned nonzero (A); a stacked TPA load pointer on entry.
;   Out: if the read was true EOF (A becomes 0 after DEC) proceeds to launch (CCP_LAUNCH_TRANSIENT);
;        otherwise -> CCP_BAD_LOAD.
;   Clobbers: all registers.
;   Algorithm: POP the saved pointer; DEC A -- a sequential-read return of 1 means clean EOF (now
;              0);
;     anything else is an error (-> CCP_BAD_LOAD).
;   [RE] 2.20-44K twin CCP_LOAD_DONE (head).
; ----------------------------------------------------------------------
CCP_LOAD_DONE:
        POP HL
        ; sequential-read return 1 = clean EOF -> 0; any other value is a load error
        DEC A
        ; non-EOF read result: report BAD LOAD
        JR NZ,CCP_BAD_LOAD
; ----------------------------------------------------------------------
; CCP_LAUNCH_TRANSIENT -- build page zero (two default FCBs + command tail) and run the program.
;   In: the .COM image is loaded at $0100.
;   Out: copies a $21-byte FCB image to TFCB ($005C), builds the second FCB and the command tail at
;        TBUFF, then (via CCP_TAIL_SETLEN) CALLs $0100; on return rejoins the CCP loop.
;   Clobbers: all registers.
;   Algorithm: re-select the drive (CCP_RESTORE_DEFAULT_DRIVE via
;              FASTLOAD_RESELECT_DRIVE/CCP_RESTORE_DEFAULT_DRIVE), rebuild the FCB
;     (CCP_PARSE_LINE_FCB = CCP_PARSE_FCB1), build a second FCB at +16, zero the CR, copy $21 bytes
;     to $005C
;     (LDIR), and walk the command line to the tail.
;   [RE] 2.20-44K twin CCP_LOAD_DONE tail / launch setup. Reached from the fast-loader too
;   (FASTLOAD_RPC_EXEC).
; ----------------------------------------------------------------------
CCP_LAUNCH_TRANSIENT:
        CALL FASTLOAD_RESELECT_DRIVE
        CALL CCP_RESTORE_DEFAULT_DRIVE
        CALL CCP_PARSE_FCB1
        LD HL,CCP_FCB_DRIVE_PREFIX
        PUSH HL
        LD A,(HL)
        LD (CCP_FCB),A
        LD A,$10
        CALL CCP_BUILD_FCB
        POP HL
        LD A,(HL)
        LD (CCP_FCB_SECOND),A
        XOR A
        LD (CCP_FCB_CR),A
        ; destination = the default FCB at page-zero TFCB ($005C)
        LD DE,$005C
        LD HL,CCP_FCB
        LD BC,$0021
        ; copy $21 (33) bytes = one full FCB image down to TFCB
        LDIR
        LD HL,CCP_CMDTEXT
; ----------------------------------------------------------------------
; CCP_TAIL_SKIP_NAME -- scan past the program name to the start of the command tail.
;   In: HL = pointer into the CCP command-line buffer (CCP_CMDTEXT).
;   Out: HL at the first blank or NUL after the command word; falls into CCP_TAIL_COPY.
;   Clobbers: A, HL.
;   [RE] 2.20-44K twin CCP_TAIL_SKIP_NAME.
; ----------------------------------------------------------------------
CCP_TAIL_SKIP_NAME:
        LD A,(HL)
        OR A
        JR Z,CCP_TAIL_COPY
        CP $20
        JR Z,CCP_TAIL_COPY
        INC HL
        JR CCP_TAIL_SKIP_NAME
; ----------------------------------------------------------------------
; CCP_TAIL_COPY -- begin copying the command tail to TBUFF and counting its length.
;   In: HL = first char of the command tail (blank or NUL).
;   Out: DE:=$0081 (TBUFF+1), B:=0 (length); falls into CCP_TAIL_COPY_LOOP.
;   Clobbers: B, DE.
;   [RE] 2.20-44K twin CCP_TAIL_COPY; $0080 (TBUFF) holds the final length byte.
; ----------------------------------------------------------------------
CCP_TAIL_COPY:
        LD B,$00
        LD DE,$0081
; ----------------------------------------------------------------------
; CCP_TAIL_COPY_LOOP -- per-character copy loop of the command tail.
;   In: HL = source char, DE = TBUFF dest, B = running length.
;   Out: on the NUL terminator branches to CCP_TAIL_SETLEN with B = length.
;   Clobbers: A, B, DE, HL.
;   [RE] 2.20-44K twin CCP_TAIL_COPY_LOOP.
; ----------------------------------------------------------------------
CCP_TAIL_COPY_LOOP:
        LD A,(HL)
        LD (DE),A
        OR A
        JR Z,CCP_TAIL_SETLEN
        INC B
        INC HL
        INC DE
        JR CCP_TAIL_COPY_LOOP
; ----------------------------------------------------------------------
; CCP_TAIL_SETLEN -- finalize page zero and launch the transient at $0100.
;   In: B = command-tail length; FCBs and TBUFF text already built.
;   Out: stores the tail length at TBUFF ($0080), sets the default DMA, rebuilds the $0004
;        drive/user
;        byte, and CALLs the program at $0100; on its return restores the CCP stack/drive and warm-
;        restarts the CCP.
;   Clobbers: all registers.
;   Algorithm: ($0080):=B; CCP_CRLF; CCP_SET_DMA_TBUFF; CCP_SET_USERDRIVE (CCP_CRLF); CALL $0100; on
;     return SP:=CCP_STACK_BASE (CCP stack), CCP_SET_DRIVE_ONLY (CCP_SET_DRIVE_ONLY), DRV_SET
;     (BDOS_DRV_SET), JP warm restart.
;   [RE] 2.20-44K twin CCP_TAIL_SETLEN.
; ----------------------------------------------------------------------
CCP_TAIL_SETLEN:
        LD A,B
        LD ($0080),A
        CALL CCP_CRLF
        CALL CCP_SET_DMA_TBUFF
        CALL CCP_SET_USERDRIVE
        ; run the loaded transient program in the TPA
        CALL $0100
        ; restore the CCP private stack after the program returns
        LD SP,CCP_STACK_BASE
        CALL CCP_SET_DRIVE_ONLY
        CALL BDOS_DRV_SET
        JP CCP_PROMPT_AND_READ
; ----------------------------------------------------------------------
; CCP_NO_FILE -- handle a transient whose .COM file was not found.
;   In: entered when BDOS OPEN returned not-found in CCP_CMD_TRANSIENT.
;   Out: reselects the drive (via FASTLOAD_RESELECT_DRIVE/CCP_RESTORE_DEFAULT_DRIVE) then echoes the
;        offending token
;        with '?' (CCP_ECHO_TOKEN = CCP_ECHO_TOKEN) and warm-restarts; does not return.
;   Clobbers: A, and the echo/BDOS registers.
;   [RE] 2.20-44K twin CCP_NO_FILE.
; ----------------------------------------------------------------------
CCP_NO_FILE:
        CALL FASTLOAD_RESELECT_DRIVE
        CALL CCP_RESTORE_DEFAULT_DRIVE
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; CCP_BAD_LOAD -- report a transient that would not fit / had a read error.
;   In: entered on TPA overflow or a non-EOF read error.
;   Out: prints 'Bad load' (CRLF + message via CCP_CRLF_MSG = CCP_CRLF_MSG) then joins
;        CCP_RETURN_OK.
;   Clobbers: BC and the print/BDOS registers.
;   [RE] 2.20-44K twin CCP_BAD_LOAD. NOTE: 2.23 text lowercase 'Bad load' (2.20 'BAD LOAD').
; ----------------------------------------------------------------------
CCP_BAD_LOAD:
        LD BC,CCP_MSG_BAD_LOAD
        CALL CCP_CRLF_MSG
        JR CCP_RETURN_OK
; ----------------------------------------------------------------------
; CCP_MSG_BAD_LOAD -- ASCIIZ console message 'Bad load'.
;   [RE] 2.20-44K twin CCP_MSG_BAD_LOAD (2.23 text lowercase 'Bad load').
; ----------------------------------------------------------------------
CCP_MSG_BAD_LOAD:
        DEFB    "Bad load"               ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CCP_COM_EXT -- the constant file-extension text 'COM' for transient loads (3 bytes, no
; terminator).
;   Copied into the FCB type field by CCP_CMD_TRANSIENT so the CCP opens NAME.COM.
;   [RE] 2.20-44K twin CCP_COM_EXT.
; ----------------------------------------------------------------------
CCP_COM_EXT:
        DEFB    "COM"
; ----------------------------------------------------------------------
; CCP_RETURN_OK -- normal CCP return tail: restore the drive then check for leftover input.
;   In: joined after a built-in or error completes.
;   Out: reselects the command's drive prefix (CCP_RESTORE_DEFAULT_DRIVE =
;        CCP_RESTORE_DEFAULT_DRIVE), then falls into
;        CCP_RETURN_OK_NOCRLF.
;   Clobbers: A, HL, and BDOS registers.
;   [RE] 2.20-44K twin CCP_RETURN_OK.
; ----------------------------------------------------------------------
CCP_RETURN_OK:
        CALL CCP_RESTORE_DEFAULT_DRIVE
; ----------------------------------------------------------------------
; CCP_RETURN_OK_NOCRLF -- verify the whole command was consumed, then warm-restart the CCP.
;   In: command FCB name first byte (CCP_FCB_NAME); drive-prefix flag (CCP_FCB_DRIVE_PREFIX).
;   Out: if there is unparsed trailing text it is echoed as a bad command (CCP_ECHO_TOKEN =
;        CCP_ECHO_TOKEN);
;        otherwise the CCP warm-restarts (CCP_PROMPT_AND_READ). Does not return.
;   Clobbers: A, HL, and the print/BDOS registers.
;   Algorithm: rebuild the FCB (CCP_PARSE_LINE_FCB = CCP_PARSE_FCB1); SUB $20 from the name byte and
;              OR the
;     drive-prefix flag -- if nonzero there is leftover input (echo bad token); else warm-restart.
;   [RE] 2.20-44K twin CCP_RETURN_OK_NOCRLF.
; ----------------------------------------------------------------------
CCP_RETURN_OK_NOCRLF:
        CALL CCP_PARSE_FCB1
        LD A,(CCP_FCB_NAME)
        SUB $20
        LD HL,CCP_FCB_DRIVE_PREFIX
        OR (HL)
        JP NZ,CCP_ECHO_TOKEN
        JP CCP_PROMPT_AND_READ
; ----------------------------------------------------------------------
; FASTLOAD_RESELECT_DRIVE -- helper: load the saved SoftCard load-drive byte then re-select that
; drive.
;   In: FASTLOAD_DRIVE_SAVE = a saved drive/parameter byte used by the fast-loader and the launch
;       path.
;   Out: A:=that byte; falls into FASTLOAD_SET_DRIVE (FASTLOAD_SET_DRIVE).
;   Clobbers: A, E.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23 fast-load support). Also used on the standard launch path
;     (CCP_LAUNCH_TRANSIENT / CCP_NO_FILE call it) to re-select the command's drive. [RE] partial.
; ----------------------------------------------------------------------
FASTLOAD_RESELECT_DRIVE:
        LD A,(FASTLOAD_DRIVE_SAVE)
; ----------------------------------------------------------------------
; FASTLOAD_SET_DRIVE -- select the drive in A via BDOS, used by the SoftCard fast-loader.
;   In: A = drive/parameter value.
;   Out: E:=A; tail-jump to the DRV_SET wrapper (BDOS_USERNUM = F_USERNUM/DRV path).
;   Clobbers: A, E.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). Thin wrapper; exact BDOS function via BDOS_USERNUM.
; ----------------------------------------------------------------------
FASTLOAD_SET_DRIVE:
        LD E,A
        JP BDOS_USERNUM
; ----------------------------------------------------------------------
; FASTLOAD_RPC_BEGIN -- 2.23-ONLY: initialise the SoftCard 6502-RWTS accelerated .COM loader.
;   In: the .COM file is open; the DPB fast-path was selected (CCP_LOAD_CHECK_FASTPATH).
;   Out: seeds the RPC mailbox/IOB cells in Apple page 3 (Z-80 $F3xx = Apple $03xx), primes the
;        per-pass state, and falls into FASTLOAD_BUILD_PASS to read directory blocks in sector
;        order.
;   Clobbers: A, DE, HL.
;   Algorithm: HL:=($F3DE) (Z$CPU / SoftCard control cell, Apple $03DE) and self-modify it into the
;     RPC dispatch (LD (FASTLOAD_RPC_TRIGGER+1),HL); clear FASTLOAD_PASS_COUNT (pass counter);
;     FASTLOAD_LOAD_PAGE:=$11 (a starting IOB
;     value); DE:=$92FF (top of the request-list scratch area just below the CCP). Fall into the
;     build
;     loop. The $F3xx cells are the SoftCard I/O-config / IOB cells the 6502 RWTS reads (see
;     CPM_BIOS
;     and CPM_BootLoader: $03D0 RPC mailbox, $03DE Z$CPU, $03E0-$03EB IOB).
;   [RE] NO 2.20 EQUIVALENT -- SoftCard 2.23 accelerated loader; FLAGGED. Cell roles cited from the
;     BIOS/BootLoader; precise per-byte field semantics partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_RPC_BEGIN:
        ; Z-80 $F3DE = Apple $03DE = Z$CPU / SoftCard control cell ($Cn00 slot base) [DOC S&HD
        ; 2-24/2-25]
        LD HL,($F3DE)
        ; self-modify the RPC dispatch's operand (LABEL+1) with the SoftCard control address
        LD (FASTLOAD_RPC_TRIGGER+1),HL
        XOR A
        LD (FASTLOAD_PASS_COUNT),A
        LD A,$11
        LD (FASTLOAD_LOAD_PAGE),A
        ; DE = top of the request-list scratch area (just below the CCP at $9300)
        LD DE,$92FF
; ----------------------------------------------------------------------
; FASTLOAD_BUILD_PASS -- 2.23-ONLY: build one pass of block-read requests from the directory map.
;   In: DE = current request-list write pointer; CCP_FCB_SECOND = the open file's 16-byte
;       allocation/dir map.
;   Out: appends IOB request records for this pass; loops while more allocation entries remain.
;   Clobbers: A, HL.
;   Algorithm: clear CCP_FCB_CR (current-record/scratch); HL:=CCP_FCB_SECOND (allocation map) and
;              scan it
;     (FASTLOAD_SCAN_DIRMAP), emitting an IOB record per nonzero block via FASTLOAD_EMIT_IOB.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). Field roles partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_BUILD_PASS:
        XOR A
        LD (CCP_FCB_CR),A
        LD HL,CCP_FCB_SECOND
; ----------------------------------------------------------------------
; FASTLOAD_SCAN_DIRMAP -- 2.23-ONLY: walk the file's allocation map, emitting a read request per
; block.
;   In: HL -> allocation-map byte (within CCP_FCB_SECOND).
;   Out: for each nonzero block number, FASTLOAD_EMIT_IOB appends a request; stops at a 0 entry or
;        end.
;   Clobbers: A, HL.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23).
; ----------------------------------------------------------------------
FASTLOAD_SCAN_DIRMAP:
        LD A,(HL)
        OR A
        JR Z,FASTLOAD_PASS_CHECK
        CALL FASTLOAD_EMIT_IOB
        INC HL
        JR FASTLOAD_SCAN_DIRMAP
; ----------------------------------------------------------------------
; FASTLOAD_PASS_CHECK -- 2.23-ONLY: at the end of the map, decide whether another directory pass is
;   needed (more extents) and loop, else proceed to execute the queued requests.
;   In: HL at the end of the 16-byte map (L is compared against $A6 = low byte of CCP_FCB_CR).
;   Out: if more dir entries remain (FASTLOAD_NEXT_DIR_ENTRY returns NZ) loop to
;        FASTLOAD_BUILD_PASS;
;        else fall into FASTLOAD_RPC_EXEC.
;   Clobbers: A.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23).
; ----------------------------------------------------------------------
FASTLOAD_PASS_CHECK:
        ; $A6 = low byte of CCP_FCB_CR: detect HL reaching the end of the 16-byte allocation map
        LD A,$A6
        CP L
        JP NZ,FASTLOAD_RPC_EXEC
        CALL FASTLOAD_NEXT_DIR_ENTRY
        JR NZ,FASTLOAD_BUILD_PASS
; ----------------------------------------------------------------------
; FASTLOAD_RPC_EXEC -- 2.23-ONLY: terminate the request list, sort + dispatch it to the 6502 RWTS,
;   then warm-boot the CCP state and join the standard launch.
;   In: the request list is built down from $92FF.
;   Out: writes a 0 terminator, sorts the requests (FASTLOAD_SORT_REQUESTS), dispatches them through
;        the RPC (CCP_WBOOT = $9B06 entry), then JP CCP_LAUNCH_TRANSIENT (CCP_LAUNCH_TRANSIENT) to
;        build page
;        zero and run the program.
;   Clobbers: all.
;   Algorithm: (DE):=0 (list terminator); CALL FASTLOAD_SORT_REQUESTS (FASTLOAD_SORT_REQUESTS); CALL
;              CCP_WBOOT (the
;     $9B06 RPC dispatcher entry, which feeds the sorted IOB list to the 6502); JP
;     CCP_LAUNCH_TRANSIENT.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). The reuse of the CCP_WBOOT entry as the RPC dispatcher
;   is
;     OBSERVED; the dispatch internals are FASTLOAD_DISPATCH_RPC below.
; ----------------------------------------------------------------------
FASTLOAD_RPC_EXEC:
        XOR A
        LD (DE),A
        ; sort the queued block-read requests into ascending sector order (FASTLOAD_SORT_REQUESTS)
        CALL FASTLOAD_SORT_REQUESTS
        ; dispatch the sorted IOB request list to the 6502 RWTS via the $9B06 RPC entry
        CALL CCP_WBOOT
        ; join the standard launch path (CCP_LAUNCH_TRANSIENT) to build page zero and run
        JP CCP_LAUNCH_TRANSIENT
; ----------------------------------------------------------------------
; FASTLOAD_EMIT_IOB -- 2.23-ONLY: encode one block number into a 4-byte IOB request, applying the
;   physical sector-skew map.
;   In: A = logical block number; HL -> map; DE = request-list write pointer (descending).
;   Out: appends a 4-byte request (track/sector + load-address fields) to the list; updates
;        FASTLOAD_LOAD_PAGE/FASTLOAD_TRACK_TMP.
;   Clobbers: A, B, DE, HL.
;   Algorithm: derive a track-ish value (SRL A x2, +3 -> FASTLOAD_TRACK_TMP); index the 16-entry
;              skew table
;     SECTOR_SKEW_MAP (SECTOR_SKEW_MAP) by (block & 3)*4; write 4 IOB bytes per request, advancing
;     FASTLOAD_LOAD_PAGE the
;     sequential load page and special-casing $C0->$D0 (the language-card / I/O page boundary).
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). The skew table is the DOS 3.3 physical interleave; the
;     page wrap at $C0 keeps loads out of the $C000 I/O window. Field details partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_EMIT_IOB:
        PUSH HL
        PUSH AF
        SRL A
        SRL A
        ADD A,$03
        LD (FASTLOAD_TRACK_TMP),A
        POP AF
        AND $03
        ADD A,A
        ADD A,A
        ; SECTOR_SKEW_MAP: 16-entry logical->physical sector interleave table
        LD HL,SECTOR_SKEW_MAP
        ADD A,L
        LD L,A
        JR NC,FASTLOAD_EMIT_IOB_1
        INC H
FASTLOAD_EMIT_IOB_1:
        LD B,$04
FASTLOAD_EMIT_IOB_2:
        LD A,(FASTLOAD_TRACK_TMP)
        LD (DE),A
        DEC DE
        LD A,(HL)
        INC HL
        LD (DE),A
        DEC DE
        LD A,(FASTLOAD_LOAD_PAGE)
        CP $A1
        JP Z,CCP_BAD_LOAD
        ; load page reached $C0 (the $C000 I/O window): skip it
        CP $C0
        JR NZ,FASTLOAD_EMIT_IOB_3
        ; bump the load page from $C0 to $D0 to step over the I/O window
        LD A,$D0
FASTLOAD_EMIT_IOB_3:
        LD (DE),A
        INC A
        DEC DE
        LD (FASTLOAD_LOAD_PAGE),A
        DJNZ FASTLOAD_EMIT_IOB_2
        POP HL
        RET
; ----------------------------------------------------------------------
; FASTLOAD_NEXT_DIR_ENTRY -- 2.23-ONLY: read the file's next directory extent into the allocation
; map.
;   In: directory search context for the open file.
;   Out: bumps the pass counter (FASTLOAD_PASS_COUNT) and SEARCH_NEXT-style fetches the next 16-byte
;        map; Z/NZ
;        reports whether another extent was found.
;   Clobbers: A (HL/DE preserved).
;   Algorithm: INC FASTLOAD_PASS_COUNT (pass counter); CALL CCP_OPEN_SUBMIT (the
;              directory-read/SEARCH helper) to refill
;     the map; preserve HL/DE around it.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23).
; ----------------------------------------------------------------------
FASTLOAD_NEXT_DIR_ENTRY:
        PUSH HL
        PUSH DE
        LD HL,FASTLOAD_PASS_COUNT
        INC (HL)
        CALL CCP_OPEN_SUBMIT
        POP DE
        POP HL
        RET
; ----------------------------------------------------------------------
; FASTLOAD_SORT_REQUESTS -- 2.23-ONLY: sort the built IOB request list into ascending order so the
;   6502 RWTS reads sectors in one efficient sweep.
;   In: the request list occupies memory from $92FF downward, each record 3 bytes (key + payload),
;       0-terminated.
;   Out: the list is sorted in place by its sort key (an exchange/bubble sort).
;   Clobbers: A, B, DE, HL.
;   Algorithm: classic in-place exchange sort: outer pointer HL from $92FF, inner pointer DE walking
;     down 3 bytes at a time; compare keys (CP (HL) and the secondary byte), swap the 3-byte records
;     when out of order; repeat until a clean pass.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). Record stride 3 and the 0 terminator are OBSERVED; the
;     exact key semantics are partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_SORT_REQUESTS:
        LD HL,$92FF
FASTLOAD_SORT_REQUESTS_1:
        LD D,H
        LD E,L
FASTLOAD_SORT_REQUESTS_2:
        DEC DE
        DEC DE
        DEC DE
        LD A,(DE)
        OR A
        JR Z,FASTLOAD_SORT_REQUESTS_5
        CP (HL)
        JR C,FASTLOAD_SORT_REQUESTS_3
        JR NZ,FASTLOAD_SORT_REQUESTS_2
        DEC DE
        LD A,(DE)
        INC DE
        DEC HL
        CP (HL)
        INC HL
        JR NC,FASTLOAD_SORT_REQUESTS_2
FASTLOAD_SORT_REQUESTS_3:
        PUSH HL
        PUSH DE
        LD B,$03
FASTLOAD_SORT_REQUESTS_4:
        LD A,(DE)
        LD C,(HL)
        LD (HL),A
        LD A,C
        LD (DE),A
        DEC HL
        DEC DE
        DJNZ FASTLOAD_SORT_REQUESTS_4
        POP DE
        POP HL
        JR FASTLOAD_SORT_REQUESTS_2
FASTLOAD_SORT_REQUESTS_5:
        DEC HL
        DEC HL
        DEC HL
        LD A,(HL)
        OR A
        JR NZ,FASTLOAD_SORT_REQUESTS_1
        RET
        LD DE,$92FF
; ----------------------------------------------------------------------
; FASTLOAD_DISPATCH_RPC -- 2.23-ONLY: walk the sorted IOB list and fire each block read through the
;   6502 RWTS via the SoftCard RPC cells.
;   In: DE -> the request list (from $92FF down); the RPC dispatch operand was self-modified by
;       FASTLOAD_RPC_BEGIN. NOTE: the routine entry at $9B06 (one line above) is the cross-module
;       CCP_WBOOT warm-boot re-entry (defined in cpm_system_223.inc); the BDOS returns through it
;       AND
;       the fast-loader calls it to start the dispatch.
;   Out: for each request pokes the IOB cells ($F3E0/$F3E1/$F3E9 = Apple $03E0/$03E1/$03E9), sets
;        the
;        command at $F3EB and the deblock/length at $F3D0, fires the RPC (the self-modified store),
;        and
;        polls the return code at $F3EA until done; loops to the next request; RET at the list end.
;   Clobbers: A, DE, HL.
;   Algorithm: A:=(DE); if 0 the list is exhausted -> RET; store IOB bytes to $F3E0/$F3E1/$F3E9;
;     set $F3EB:=1 (read command), $F3D0:=$0E03 (deblock params); the self-modified LD ($xxxx),A at
;     FASTLOAD_RPC_TRIGGER writes the SoftCard control cell to hand off to the 6502; re-read $F3EA
;     (return code);
;     on completion loop, else jump back into the standard loader at CCP_LOAD_LOOP (CCP_LOAD_LOOP).
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). Cell roles cited from CPM_BIOS / CPM_BootLoader;
;   precise
;     handshake timing UNKNOWN. The $9B06 entry is shared with CCP_WBOOT (cpm_system_223.inc).
; ----------------------------------------------------------------------
FASTLOAD_DISPATCH_RPC:
        LD A,(DE)
        OR A
        RET Z
        ; Z-80 $F3E0 = Apple $03E0 = IOB sector/load-address cell read by the 6502 RWTS
        LD ($F3E0),A
        DEC DE
        LD A,(DE)
        LD ($F3E1),A
        DEC DE
        LD A,(DE)
        LD ($F3E9),A
        DEC DE
        LD A,$01
        ; Z-80 $F3EB = Apple $03EB = IOB command cell (1 = read)
        LD ($F3EB),A
        LD HL,$0E03
        ; Z-80 $F3D0 = Apple $03D0 = RPC command/params (deblock) mailbox
        LD ($F3D0),HL
; ----------------------------------------------------------------------
; FASTLOAD_RPC_TRIGGER -- 2.23-ONLY: the self-modified store that writes the SoftCard control cell
; to
;   hand the bus to the 6502 (the actual RPC trigger).
;   In: A = the value to write; the operand address was patched by FASTLOAD_RPC_BEGIN (LABEL+1).
;   Out: writes A to the SoftCard control/Z$CPU cell, switching execution to the 6502; then checks
;        $F3EA and continues the dispatch loop.
;   Clobbers: A, flags.
;   Algorithm: LD ($0000),A where the $0000 operand is self-modified at FASTLOAD_RPC_TRIGGER+1 to
;              the
;     SoftCard control address loaded from $F3DE; the write triggers the CPU switch / RPC.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). The operand is a self-modify target
;   (FASTLOAD_RPC_TRIGGER+1).
; ----------------------------------------------------------------------
FASTLOAD_RPC_TRIGGER:
        ; self-modified operand (FASTLOAD_RPC_TRIGGER+1, patched to the $F3DE SoftCard control
        ; address): the write switches the bus to the 6502 = the RPC trigger
        LD ($0000),A
        LD A,($F3EA)
        OR A
        JR Z,FASTLOAD_DISPATCH_RPC
        JP CCP_LOAD_LOOP
; ----------------------------------------------------------------------
; SECTOR_SKEW_MAP -- 2.23-ONLY: 16-byte logical->physical sector interleave table for the
; fast-loader.
;   Bytes: 00 09 03 0C 06 0F 01 0A 04 0D 07 08 02 0B 05 0E -- the Apple DOS 3.3 sector skew, indexed
;          by
;   FASTLOAD_EMIT_IOB to issue block reads in physical order.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23 accelerated loader).
; ----------------------------------------------------------------------
SECTOR_SKEW_MAP:
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A,$04,$0D,$07,$08,$02,$0B,$05,$0E
; ----------------------------------------------------------------------
; FASTLOAD_LOAD_PAGE -- 2.23-ONLY: running load-page byte the fast-loader writes into successive IOB
;   records (advanced per block; steps $C0->$D0 over the I/O window).
;   [RE] NO 2.20 EQUIVALENT.
; ----------------------------------------------------------------------
FASTLOAD_LOAD_PAGE:
        DEFB    "\0"
; ----------------------------------------------------------------------
; FASTLOAD_TRACK_TMP -- 2.23-ONLY: scratch track-ish value derived from the block number in
;   FASTLOAD_EMIT_IOB (SRL x2, +3) before it is written into the IOB record.
;   [RE] NO 2.20 EQUIVALENT.
; ----------------------------------------------------------------------
FASTLOAD_TRACK_TMP:
        DEFB    "\0"
; ----------------------------------------------------------------------
; FASTLOAD_DRIVE_SAVE -- 2.23-ONLY: saved drive/parameter byte for the fast-loader / launch path,
;   reloaded by FASTLOAD_RESELECT_DRIVE. (33 reserved bytes here; the first is the live cell.)
;   [RE] partial -- the live use is the saved drive byte; the remaining reserved bytes are UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_DRIVE_SAVE:
        DEFS    33, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_STACK_BASE -- top of the CCP private stack (SP is loaded here at warm start and after a
;   transient returns).
;   [RE] 2.20-44K twin equivalent (here it is the stack-base cell at $9B64).
; ----------------------------------------------------------------------
CCP_STACK_BASE:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB -- the FCB for the $$$.SUB batch (SUBMIT) file; name/ext constant '$$$     SUB'
; follows.
;   Opened/read/deleted by the CCP batch logic to source successive command lines.
;   [RE] 2.20-44K twin CCP_SUB_FCB.
; ----------------------------------------------------------------------
CCP_SUB_FCB:
        DEFB    "\0"
        DEFB    "$$$     SUB"            ; string
        DEFB    $00                      ; terminator
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB_S2 -- the S2 (extent-high) field of the $$$.SUB FCB; cleared before reading the next
;   batch record.
;   [RE] 2.20-44K twin CCP_SUB_FCB_S2.
; ----------------------------------------------------------------------
CCP_SUB_FCB_S2:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB_CR -- the current-record (CR) field of the $$$.SUB FCB; the SUBMIT file is consumed in
;   reverse, so this is decremented to position the next read.
;   [RE] 2.20-44K twin CCP_SUB_FCB_CR (followed by reserved FCB bytes).
; ----------------------------------------------------------------------
CCP_SUB_FCB_CR:
        DEFS    17, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_SUB_PREV_REC -- previous batch record index (cell just below the command FCB); receives
;   CCP_SUB_FCB_CR-1, the record to read next from $$$.SUB.
;   [RE] 2.20-44K twin CCP_SUB_PREV_REC.
; ----------------------------------------------------------------------
CCP_SUB_PREV_REC:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB -- the command-line FCB the CCP builds from the typed command (drive byte; name at
;   CCP_FCB_NAME, type at CCP_FCB_EXT). Copied to TFCB ($005C) before a transient runs.
;   [RE] 2.20-44K twin CCP_FCB.
; ----------------------------------------------------------------------
CCP_FCB:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB_NAME -- the 8-character filename field of the command FCB (parsed command word,
; blank-padded);
;   matched 4 chars at a time against the keyword table and used as the .COM filename.
;   [RE] 2.20-44K twin CCP_FCB_NAME.
; ----------------------------------------------------------------------
CCP_FCB_NAME:
        DEFS    8, $00                   ; fill
; ----------------------------------------------------------------------
; CCP_FCB_EXT -- the 3-character extension (type) field of the command FCB; must be blank for a bare
;   command word; the transient loader overwrites it with 'COM'.
;   [RE] 2.20-44K twin CCP_FCB_EXT.
; ----------------------------------------------------------------------
CCP_FCB_EXT:
        DEFB    "\0\0\0"
; ----------------------------------------------------------------------
; FASTLOAD_PASS_COUNT -- 2.23-ONLY: directory-pass counter for the fast-loader (incremented by
;   FASTLOAD_NEXT_DIR_ENTRY as it walks the file's extents). (4 reserved bytes here.)
;   [RE] NO 2.20 EQUIVALENT; exact width/use of the trailing bytes partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_PASS_COUNT:
        DEFB    "\0\0\0\0"
; ----------------------------------------------------------------------
; CCP_FCB_SECOND -- the second filename built into the command FCB at offset $10 (so the transient
;   receives two default FCBs at $005C/$006C). Also reused by the fast-loader as the 16-byte
;   allocation/directory map scratch.
;   [RE] 2.20-44K twin CCP_FCB_SECOND.
; ----------------------------------------------------------------------
CCP_FCB_SECOND:
        DEFS    16, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_FCB_CR -- the current-record (CR) field of the command FCB; zeroed before each open/read so
;   loads start at record 0.
;   [RE] 2.20-44K twin CCP_FCB_CR.
; ----------------------------------------------------------------------
CCP_FCB_CR:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_BDOS_RESULT -- saved A return code from the most recent BDOS file call
; (open/close/search/make);
;   the wrapper saves A here then INC A so the caller can test the $FF not-found code as zero.
;   [RE] 2.20-44K twin CCP_BDOS_RESULT.
; ----------------------------------------------------------------------
CCP_BDOS_RESULT:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_CUR_DRIVE -- the CCP's current default drive number (0=A,1=B,...); written to the low nibble
; of
;   page-zero $0004 and reselected after every transient runs.
;   [RE] 2.20-44K twin CCP_CUR_DRIVE (NOT the user number, which lives in the BDOS).
; ----------------------------------------------------------------------
CCP_CUR_DRIVE:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB_DRIVE_PREFIX -- explicit drive-prefix flag for the parsed command (0 = no 'd:' prefix,
; else
;   drive#+1). A non-zero value routes the dispatcher to CCP_DRIVE_SELECT (slot 6).
;   [RE] 2.20-44K twin CCP_FCB_DRIVE_PREFIX.
; ----------------------------------------------------------------------
CCP_FCB_DRIVE_PREFIX:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_TYPE_REC_INDEX -- TYPE's per-record byte index (advanced 0..$80 by TYPE_EMIT_CHAR; primed to
;   $FF to force the first record read). Followed by 86 reserved/scratch bytes up to the CCP top.
;   [RE] 2.20-44K twin (the CCP_FCB_TAIL / TYPE counter region).
; ----------------------------------------------------------------------
CCP_TYPE_REC_INDEX:
        DEFS    86, $00                  ; fill
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9300, $0900
    ENDIF
