; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- CCP (Console Command Processor)
; ----------------------------------------------------------------------------
; Runtime-addressed (de-skewed): ORG $9400 (CBASE), runs $9400-$9BFF. An independent
; compilation; calls the BDOS only through the $0005 ABI and references the BDOS base
; once (BDOS_FBASE). The 44K system tracks store this sector-interleaved; the disk
; producer re-applies the skew (cpm_pipeline/deskew.py). See ../../docs/CPM_Skew_Findings.md.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    INCLUDE "cpm22.inc"
    INCLUDE "cpm_system_220.inc"
    ORG $9400
    ENDIF

; ----------------------------------------------------------------------
; CCP_ENTRY -- CCP cold/warm entry; jump to the main login-and-prompt setup.
;   In: C = (drive<<4 | user) packed login byte passed by the BIOS warm boot.
;   Out: never returns (sets up the CCP then enters the command loop).
;   Clobbers: all.
;   Algorithm: JP to the CCP login setup at CCP_COLD_ENTRY ($975C). The 3 bytes after
;     the JP are a second entry vector 'JP $9758' (C3 58 97); $9758 is CCP_WARM_ENTRY
;     (clears CCP_INLEN, then re-runs the login setup) -- the warm-start re-entry.
;   [RE] Standard CP/M 2.2 CCP base (CBASE).
; ----------------------------------------------------------------------
; (CCP_ENTRY == module base; defined in cpm_system_220.inc)
        ; enter CCP login setup: reset SP, log in drive/user
        JP CCP_COLD_ENTRY
        DEFB    $C3,$58,$97
; ----------------------------------------------------------------------
; CCP_INBUF -- console line-input buffer descriptor for C_READSTR.
;   Layout: byte0 ($9406)=max length ($7F=127), byte1 ($9407)=returned count,
;     bytes2.. ($9408)=the typed command line (also the CCP work text area).
;   [RE] Standard CP/M 2.2 CCP command buffer.
; ----------------------------------------------------------------------
CCP_INBUF:
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
        DEFB    "COPYRIGHT (C) 1979, DIGITAL RESEARCH  " ; string
        DEFB    $00                      ; terminator
        DEFS    73, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_PARSEPTR -- 16-bit scan pointer into CCP_CMDTEXT used during command parse.
;   Initialized to CCP_CMDTEXT ($9408); advanced as tokens are consumed.
;   [RE]
; ----------------------------------------------------------------------
CCP_PARSEPTR:
        DEFB    $08,$94
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
        ; E = char to print
        LD E,A
        ; C_WRITE = 2
        LD C,$02
        ; tail-call BDOS to emit the char
        JP $0005
; ----------------------------------------------------------------------
; CCP_CONOUT_KEEPBC -- print one char (CCP_CONOUT) preserving BC.
;   In: A = character.
;   Out: BC unchanged.
;   Clobbers: A/flags via BDOS; BC saved/restored.
;   Algorithm: PUSH BC; call CCP_CONOUT; POP BC; RET.
;   [RE]
; ----------------------------------------------------------------------
CCP_CONOUT_KEEPBC:
        PUSH BC
        ; emit char, with BC protected
        CALL CCP_CONOUT
        POP BC
        RET
; ----------------------------------------------------------------------
; CCP_CRLF -- emit a carriage-return + line-feed to the console.
;   In: none.
;   Out: cursor at start of next line; BC preserved.
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
        JP CCP_CONOUT_KEEPBC
; ----------------------------------------------------------------------
; CCP_SPACE -- emit a single blank to the console.
;   In: none.  Out: BC preserved.  Clobbers: A/flags.
;   Algorithm: A:=' ' ($20); JP CCP_CONOUT_KEEPBC.
;   [RE]
; ----------------------------------------------------------------------
CCP_SPACE:
        ; space character
        LD A,$20
        JP CCP_CONOUT_KEEPBC
; ----------------------------------------------------------------------
; CCP_CRLF_MSG -- emit CR/LF then print a NUL-terminated message.
;   In: BC -> NUL-terminated message string.
;   Out: message printed after a new line.
;   Clobbers: A, HL, BC.
;   Algorithm: CCP_CRLF; HL:=BC (via PUSH BC/POP HL); fall into CCP_PUTS.
;   [RE] Used by the 'READ ERROR' / 'NO FILE' message printers.
; ----------------------------------------------------------------------
CCP_CRLF_MSG:
        PUSH BC
        ; new line before the message
        CALL CCP_CRLF
        ; HL = message pointer (was BC)
        POP HL
; ----------------------------------------------------------------------
; CCP_PUTS -- print a NUL-terminated string to the console.
;   In: HL -> string.
;   Out: HL past the terminator on exit (loop stops at the NUL).
;   Clobbers: A, HL.
;   Algorithm: loop: A:=(HL); if A==0 RET; INC HL; emit A via CCP_CONOUT;
;     repeat.
;   [RE]
; ----------------------------------------------------------------------
CCP_PUTS:
        ; fetch next char
        LD A,(HL)
        OR A
        ; NUL terminates the string
        RET Z
        INC HL
        PUSH HL
        ; emit this char
        CALL CCP_CONOUT
        POP HL
        JP CCP_PUTS
; ----------------------------------------------------------------------
; BDOS_DRV_ALLRESET -- reset the disk system (BDOS function 13).
;   In: none.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=DRV_ALLRESET($0D); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_ALLRESET:
        ; DRV_ALLRESET = 13
        LD C,$0D
        JP $0005
; ----------------------------------------------------------------------
; BDOS_DRV_SET -- select the default drive (BDOS function 14).
;   In: A = drive number (0=A..15=P).
;   Out: per BDOS.  Clobbers: C, E; BDOS ABI.
;   Algorithm: E:=A; C:=DRV_SET($0E); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_SET:
        LD E,A
        ; DRV_SET = 14
        LD C,$0E
        JP $0005
; ----------------------------------------------------------------------
; BDOS_FCB_OP -- call BDOS then record the result in CCP_OPENDIRCODE.
;   In: C = BDOS function number, DE -> FCB (set by the caller).
;   Out: A = BDOS return+1; Z set if the raw code was $FF (error/not-found);
;     CCP_OPENDIRCODE ($9BEE) := the raw BDOS result code.
;   Clobbers: A/flags.
;   Algorithm: CALL BDOS; store A to CCP_OPENDIRCODE; INC A (so $FF->0 sets Z
;     meaning 'failed'); RET.  Shared tail for the open/close/search/make-style
;     wrappers (those whose error sentinel is $FF).
;   [RE]
; ----------------------------------------------------------------------
BDOS_FCB_OP:
        ; invoke BDOS with C=function, DE=FCB
        CALL $0005
        ; save raw BDOS directory code
        LD (CCP_BDOS_RESULT),A
        ; $FF->0 so Z flags 'error/not found'
        INC A
        RET
; ----------------------------------------------------------------------
; BDOS_F_OPEN -- open the file named by DE (BDOS function 15).
;   In: DE -> FCB.
;   Out: A/Z per BDOS_FCB_OP (Z = open failed).
;   Clobbers: A/flags.
;   Algorithm: C:=F_OPEN($0F); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_OPEN:
        ; F_OPEN = 15
        LD C,$0F
        JP BDOS_FCB_OP
; ----------------------------------------------------------------------
; CCP_OPEN_SUBMIT -- open the staged command FCB at record 0.
;   In: CCP command FCB at CCP_FCB ($9BCD) holds the file name.
;   Out: A/Z per BDOS_F_OPEN.
;   Clobbers: A/flags, DE.
;   Algorithm: clear CCP_CURREC ($9BED, current-record byte); DE:=CCP_FCB; JP
;     BDOS_F_OPEN.
;   [RE] Opens the parsed command file (e.g. before a chained read).
; ----------------------------------------------------------------------
CCP_OPEN_SUBMIT:
        XOR A
        ; current record := 0
        LD (CCP_FCB_CR),A
        ; DE -> CCP command FCB
        LD DE,CCP_FCB
        JP BDOS_F_OPEN
; ----------------------------------------------------------------------
; BDOS_F_CLOSE -- close the file named by DE (BDOS function 16).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP.  Clobbers: A/flags.
;   Algorithm: C:=F_CLOSE_HND($10); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_CLOSE:
        ; F_CLOSE_HND = 16
        LD C,$10
        JP BDOS_FCB_OP
; ----------------------------------------------------------------------
; BDOS_F_SFIRST -- search-for-first matching directory entry (BDOS function 17).
;   In: DE -> FCB (may contain '?' wildcards).
;   Out: A = directory index 0..3 or $FF if none; Z per BDOS_FCB_OP.
;   Clobbers: A/flags.
;   Algorithm: C:=F_SFIRST($11); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_SFIRST:
        ; F_SFIRST = 17
        LD C,$11
        JP BDOS_FCB_OP
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
        JP BDOS_FCB_OP
; ----------------------------------------------------------------------
; CCP_SEARCH_FIRST_SUBMIT -- search-for-first on the CCP command FCB.
;   In: CCP command FCB at CCP_FCB ($9BCD).
;   Out: A/Z per BDOS_F_SFIRST.
;   Clobbers: A/flags, DE.
;   Algorithm: DE:=CCP_FCB; JP BDOS_F_SFIRST.
;   [RE]
; ----------------------------------------------------------------------
CCP_SEARCH_FIRST_SUBMIT:
        ; DE -> CCP command FCB
        LD DE,CCP_FCB
        JP BDOS_F_SFIRST
; ----------------------------------------------------------------------
; BDOS_F_DELETE -- delete the file named by DE (BDOS function 19).
;   In: DE -> FCB.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_DELETE_HND($13); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DELETE:
        ; F_DELETE_HND = 19
        LD C,$13
        JP $0005
; ----------------------------------------------------------------------
; BDOS_CALL_TESTERR -- call BDOS then set Z=1 only when A==0 (success).
;   In: C = BDOS function, DE -> FCB.
;   Out: A = BDOS code; flags from OR A (Z if A==0, i.e. read/write OK).
;   Clobbers: flags.
;   Algorithm: CALL BDOS; OR A; RET.  Shared tail for the read/write wrappers
;     where 0 = success and nonzero = error/EOF.
;   [RE]
; ----------------------------------------------------------------------
BDOS_CALL_TESTERR:
        ; invoke BDOS
        CALL $0005
        ; Z=1 means success (A==0)
        OR A
        RET
; ----------------------------------------------------------------------
; BDOS_F_READ -- read the next sequential record (BDOS function 20).
;   In: DE -> FCB; DMA set elsewhere.
;   Out: A = 0 on success / nonzero on error or EOF; Z per BDOS_CALL_TESTERR.
;   Clobbers: flags.
;   Algorithm: C:=F_READ($14); JP BDOS_CALL_TESTERR.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_READ:
        ; F_READ = 20
        LD C,$14
        JP BDOS_CALL_TESTERR
; ----------------------------------------------------------------------
; CCP_READ_SUBMIT -- read the next record of the CCP command FCB.
;   In: CCP command FCB at CCP_FCB ($9BCD); DMA preset by the caller.
;   Out: A/Z per BDOS_F_READ.
;   Clobbers: flags, DE.
;   Algorithm: DE:=CCP_FCB; JP BDOS_F_READ.
;   [RE]
; ----------------------------------------------------------------------
CCP_READ_SUBMIT:
        ; DE -> CCP command FCB
        LD DE,CCP_FCB
        JP BDOS_F_READ
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
        JP BDOS_CALL_TESTERR
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
        JP BDOS_FCB_OP
; ----------------------------------------------------------------------
; BDOS_F_RENAME -- rename a file (BDOS function 23).
;   In: DE -> FCB whose first 16 bytes name the old file and second 16 the new.
;   Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_RENAME_HND($17); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_RENAME:
        ; F_RENAME_HND = 23
        LD C,$17
        JP $0005
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
;   Algorithm: C:=F_USERNUM($20); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_USERNUM:
        ; F_USERNUM = 32
        LD C,$20
        JP $0005
; ----------------------------------------------------------------------
; CCP_SET_USERDRIVE -- write the packed user/drive byte into base page $0004.
;   In: current user (from BDOS_USER_GET) and CCP_CDISK ($9BEF, default drive).
;   Out: base-page $0004 := (user<<4 | drive); the CP/M default-drive/user cell.
;   Clobbers: A, HL.
;   Algorithm: A:=BDOS_USER_GET; A<<=4 (ADD A,A x4); OR in CCP_CDISK; store $0004.
;   [RE] $0004 is the CP/M default-drive/user cell read by the warm boot.
; ----------------------------------------------------------------------
CCP_SET_USERDRIVE:
        ; A = current user number
        CALL BDOS_USER_GET
        ; user << 4 ...
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ; HL -> CCP default-drive cell
        LD HL,CCP_CUR_DRIVE
        ; pack (user<<4 | drive)
        OR (HL)
        ; store login byte to base page $0004
        LD ($0004),A
        RET
; ----------------------------------------------------------------------
; CCP_SET_DRIVE_ONLY -- write just the default drive into base-page $0004.
;   In: CCP_CDISK ($9BEF).
;   Out: $0004 := default drive (user nibble cleared).
;   Clobbers: A.
;   Algorithm: A:=CCP_CDISK; store to $0004.
;   [RE]
; ----------------------------------------------------------------------
CCP_SET_DRIVE_ONLY:
        ; A = default drive
        LD A,(CCP_CUR_DRIVE)
        ; store to base page $0004
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
;   In: CCP_SUBMITON ($9BAB) flag; CCP_SUBMITFCB ($9BAC); CCP_INBUF buffer.
;   Out: CCP_CMDTEXT holds the upper-cased command line ready to parse;
;     CCP_PARSEPTR set to its start.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: if a $$$.SUB submit is active (CCP_SUBMITON != 0): select its drive,
;     open + read the next record of CCP_SUBMITFCB into TBUFF, set its current-record
;     cell to 0 and decrement its record count, copy the 128-byte record into
;     CCP_INBUF, close the submit FCB, then poll the console for a ^C abort; if no
;     submit (or it ends/errs/aborts) discard submit (CCP_DISCARD_SUBMIT) and do a
;     console C_READSTR into CCP_INBUF.  Either path falls into CCP_UPCASE_LINE to
;     fold the line to upper case and reset the parse pointer.
;   [RE] Standard CP/M 2.2 CCP command-acquire with SUBMIT support.
; ----------------------------------------------------------------------
CCP_GETCMD:
        ; submit-active flag
        LD A,(CCP_SUBMIT_FLAG)
        OR A
        ; no submit -> read from console
        JP Z,CCP_READ_CONSOLE
        LD A,(CCP_CUR_DRIVE)
        OR A
        LD A,$00
        CALL NZ,BDOS_DRV_SET
        LD DE,CCP_SUB_FCB
        ; open the $$$.SUB submit file
        CALL BDOS_F_OPEN
        JP Z,CCP_READ_CONSOLE
        ; submit FCB record-count byte (FCB+15)
        LD A,(CCP_SUB_FCB_CR)
        DEC A
        LD (CCP_SUB_PREV_REC),A
        LD DE,CCP_SUB_FCB
        ; read the next submit record into TBUFF
        CALL BDOS_F_READ
        JP NZ,CCP_READ_CONSOLE
        ; DE -> CCP_INBUF count byte
        LD DE,CCP_INLEN
        LD HL,$0080
        LD B,$80
        ; copy 128 bytes TBUFF -> CCP_INBUF
        CALL COPY_N_BYTES
        LD HL,CCP_SUB_FCB_S2
        LD (HL),$00
        INC HL
        DEC (HL)
        LD DE,CCP_SUB_FCB
        ; close submit FCB to commit the shortened file
        CALL BDOS_F_CLOSE
        JP Z,CCP_READ_CONSOLE
        LD A,(CCP_CUR_DRIVE)
        OR A
        CALL NZ,BDOS_DRV_SET
        LD HL,CCP_CMDTEXT
        CALL CCP_PUTS
        ; poll console for a ^C abort of submit
        CALL CCP_CHECK_ABORT
        JP Z,CCP_UPCASE_LINE
        ; abort: discard the submit file
        CALL CCP_DISCARD_SUBMIT
        JP CCP_PROMPT_AND_READ
; ----------------------------------------------------------------------
; CCP_READ_CONSOLE -- discard any pending submit, then read a console line.
;   In: none.
;   Out: CCP_INBUF filled by C_READSTR; falls into CCP_UPCASE_LINE.
;   Clobbers: A, BC, DE.
;   Algorithm: CCP_DISCARD_SUBMIT; CCP_SET_USERDRIVE; C:=C_READSTR(10),
;     DE:=CCP_INBUF, CALL BDOS; then CCP_SET_DRIVE_ONLY.
;   [RE]
; ----------------------------------------------------------------------
CCP_READ_CONSOLE:
        ; discard any abandoned submit
        CALL CCP_DISCARD_SUBMIT
        ; publish user/drive to base page
        CALL CCP_SET_USERDRIVE
        ; C_READSTR = 10 (buffered line input)
        LD C,$0A
        ; DE -> CCP_INBUF descriptor
        LD DE,CCP_INBUF
        ; read a console line into CCP_INBUF
        CALL $0005
        CALL CCP_SET_DRIVE_ONLY
; ----------------------------------------------------------------------
; CCP_UPCASE_LINE -- upper-case the command line in place and reset the parser.
;   In: CCP_INLEN = char count, CCP_CMDTEXT = the typed line.
;   Out: CCP_CMDTEXT folded to upper case + NUL-terminated; CCP_PARSEPTR:=
;     CCP_CMDTEXT.
;   Clobbers: A, B, HL.
;   Algorithm: B:=count from CCP_INLEN; for each char apply CCP_UPCASE in place;
;     append a terminating NUL; CCP_PARSEPTR:=CCP_CMDTEXT.
;   [RE]
; ----------------------------------------------------------------------
CCP_UPCASE_LINE:
        ; HL -> CCP_INLEN (count) byte
        LD HL,CCP_INLEN
        ; B = number of typed chars
        LD B,(HL)
; ----------------------------------------------------------------------
; CCP_UPCASE_LOOP -- per-character upper-case loop body for CCP_UPCASE_LINE.
;   In: HL -> char before the current one, B = remaining count.
;   Out: char folded in place; loops until B==0 then joins CCP_UPCASE_DONE.
;   Clobbers: A, B, HL.
;   Algorithm: INC HL; if B==0 done; A:=(HL); A:=CCP_UPCASE(A); store; DEC B; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_UPCASE_LOOP:
        INC HL
        LD A,B
        OR A
        JP Z,CCP_UPCASE_DONE
        LD A,(HL)
        ; fold this char to upper case
        CALL CCP_UPCASE
        ; write the folded char back
        LD (HL),A
        DEC B
        JP CCP_UPCASE_LOOP
; ----------------------------------------------------------------------
; CCP_UPCASE_DONE -- terminate the upper-cased line and reset the parser.
;   In: HL -> byte just past the last char, A = 0.
;   Out: NUL written at HL; CCP_PARSEPTR := CCP_CMDTEXT.
;   Clobbers: HL.
;   Algorithm: (HL):=0 (NUL); CCP_PARSEPTR:=CCP_CMDTEXT; RET.
;   [RE]
; ----------------------------------------------------------------------
CCP_UPCASE_DONE:
        ; append NUL terminator
        LD (HL),A
        ; HL -> CCP_CMDTEXT
        LD HL,CCP_CMDTEXT
        ; parse pointer := start of line
        LD (CCP_PARSEPTR),HL
        RET
; ----------------------------------------------------------------------
; CCP_CHECK_ABORT -- poll the console; if a key is waiting, consume it.
;   In: none.
;   Out: Z set if no key was pending (continue); NZ if a key was read (abort the
;     running submit); A = the key on the NZ path.
;   Clobbers: A/flags.
;   Algorithm: C:=C_STAT($0B), CALL BDOS; if A==0 RET (Z, nothing pending); else
;     C:=C_READ($01), CALL BDOS to swallow the key; OR A; RET.
;   [RE] Lets a typed key abort an active SUBMIT batch.
; ----------------------------------------------------------------------
CCP_CHECK_ABORT:
        ; C_STAT = 11 (console status)
        LD C,$0B
        CALL $0005
        OR A
        ; no key pending -> keep running submit
        RET Z
        ; C_READ = 1: consume the typed key
        LD C,$01
        CALL $0005
        OR A
        RET
; ----------------------------------------------------------------------
; BDOS_DRV_GET -- return the current default drive (BDOS function 25).
;   In: none.  Out: A = current drive (0..15).  Clobbers: A, C.
;   Algorithm: C:=DRV_GET($19); JP BDOS.
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
;   Algorithm: C:=F_DMAOFF($1A); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DMAOFF:
        ; F_DMAOFF = 26 (set DMA)
        LD C,$1A
        JP $0005
; ----------------------------------------------------------------------
; CCP_DISCARD_SUBMIT -- end an active SUBMIT: clear the flag and delete $$$.SUB.
;   In: CCP_SUBMITON ($9BAB) flag; CCP_SUBMITFCB ($9BAC); CCP_CDISK ($9BEF).
;   Out: if submit was active it is cleared, drive A selected, the submit file
;     deleted, and the default drive restored; otherwise a no-op.
;   Clobbers: A, DE.
;   Algorithm: if CCP_SUBMITON==0 RET; clear it; select drive 0 (BDOS_DRV_SET 0);
;     delete CCP_SUBMITFCB (BDOS_F_DELETE); reselect CCP_CDISK (BDOS_DRV_SET).
;   [RE]
; ----------------------------------------------------------------------
CCP_DISCARD_SUBMIT:
        ; HL -> submit-active flag
        LD HL,CCP_SUBMIT_FLAG
        LD A,(HL)
        OR A
        ; no submit active -> nothing to discard
        RET Z
        ; clear submit-active flag
        LD (HL),$00
        XOR A
        ; select drive A (where $$$.SUB lives)
        CALL BDOS_DRV_SET
        LD DE,CCP_SUB_FCB
        ; delete the $$$.SUB submit file
        CALL BDOS_F_DELETE
        LD A,(CCP_CUR_DRIVE)
        ; restore the user's default drive
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; CCP_CHECK_SERIAL -- verify the resident BDOS serial number is still intact.
;   In: CCP_SERIAL ($9728) holds the saved 6-byte CP/M serial number; the live BDOS
;     image base is at BDOS_FBASE ($9C00), whose first 6 bytes are that serial.
;   Out: returns if the 6 bytes match; otherwise jumps to the warm-boot reload path
;     CCP_SERIAL_MISMATCH_HALT ($97CF) to refetch the system from disk.
;   Clobbers: A, B, DE, HL.
;   Algorithm: compare 6 bytes at $9728 against the BDOS image header; on first
;     mismatch JP CCP_SERIAL_MISMATCH_HALT; on full match RET.
;   [RE] Standard CP/M 2.2 CCP serial-number self-check: detects a transient that
;     overwrote the resident BDOS and forces a fresh system load if so.  NOTE: the
;     6 bytes at $9728 are the saved serial, NOT a continuation of the command-name
;     string, which ends at $9727.
; ----------------------------------------------------------------------
CCP_CHECK_SERIAL:
        ; DE -> saved 6-byte CP/M serial number
        LD DE,CCP_SERIAL_STAMP
        ; HL -> live BDOS image header (serial at +0)
        LD HL,BDOS_FBASE
        ; compare 6 serial bytes
        LD B,$06
; ----------------------------------------------------------------------
; CCP_CHECK_SERIAL_LOOP -- compare loop for CCP_CHECK_SERIAL.
;   In: DE -> saved serial, HL -> live BDOS header, B = bytes remaining.
;   Out: on mismatch JP CCP_SERIAL_MISMATCH_HALT (warm-boot reload); on B==0 RET (match).
;   Clobbers: A, B, DE, HL.
;   Algorithm: A:=(DE); if A != (HL) reload; INC DE/HL; DEC B; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_CHECK_SERIAL_LOOP:
        LD A,(DE)
        CP (HL)
        ; BDOS serial clobbered -> reload system image
        JP NZ,CCP_SERIAL_MISMATCH_HALT
        INC DE
        INC HL
        DEC B
        JP NZ,CCP_CHECK_SERIAL_LOOP
        RET
; ----------------------------------------------------------------------
; CCP_ECHO_TOKEN -- echo the current command token to the console up to a blank.
;   In: CCP_TOKENPTR ($948A) -> start of the offending token.
;   Out: token characters printed; falls into CCP_REPORT_BADCMD.
;   Clobbers: A, HL.
;   Algorithm: CCP_CRLF; HL:=CCP_TOKENPTR; print each char until a space or NUL,
;     then report the bad command.
;   [RE] Used to echo the bad name before the '?' error.
; ----------------------------------------------------------------------
CCP_ECHO_TOKEN:
        ; new line before echoing the token
        CALL CCP_CRLF
        ; HL -> start of the failing token
        LD HL,(CCP_TOKENPTR)
; ----------------------------------------------------------------------
; CCP_ECHO_TOKEN_LOOP -- character loop for CCP_ECHO_TOKEN.
;   In: HL -> current char of the token.
;   Out: prints chars until ' ' or NUL, then joins CCP_REPORT_BADCMD.
;   Clobbers: A, HL.
;   Algorithm: A:=(HL); if ' ' or NUL stop; emit A via CCP_CONOUT; INC HL; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_ECHO_TOKEN_LOOP:
        LD A,(HL)
        ; stop at a blank (token boundary)
        CP $20
        ; blank -> done echoing
        JP Z,CCP_REPORT_BADCMD
        OR A
        ; NUL -> done echoing
        JP Z,CCP_REPORT_BADCMD
        PUSH HL
        ; echo this character
        CALL CCP_CONOUT
        POP HL
        INC HL
        JP CCP_ECHO_TOKEN_LOOP
; ----------------------------------------------------------------------
; CCP_REPORT_BADCMD -- print '?' for an unrecognized command and return to prompt.
;   In: none (called after the bad token has been echoed).
;   Out: prints '?' + CR/LF, discards any submit, and jumps to the prompt loop.
;   Clobbers: A.
;   Algorithm: emit '?' ($3F); CCP_CRLF; CCP_DISCARD_SUBMIT; JP CCP_PROMPT_AND_READ ($9782,
;     the CCP prompt).
;   [RE] This is the CCP's classic 'BADNAME?' error responder.
; ----------------------------------------------------------------------
CCP_REPORT_BADCMD:
        ; '?' marks an unknown command
        LD A,$3F
        ; print the '?'
        CALL CCP_CONOUT
        CALL CCP_CRLF
        CALL CCP_DISCARD_SUBMIT
        ; back to the CCP prompt
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
        ; control char in name -> bad-token error
        JP C,CCP_ECHO_TOKEN
        RET Z
        ; '=' delimiter
        CP $3D
        RET Z
        ; '_' delimiter
        CP $5F
        RET Z
        ; '.' (name/type separator)
        CP $2E
        RET Z
        ; ':' (drive separator)
        CP $3A
        RET Z
        ; ';' delimiter
        CP $3B
        RET Z
        ; '<' delimiter
        CP $3C
        RET Z
        ; '>' delimiter
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
        ; blank?
        CP $20
        ; non-blank -> stop here
        RET NZ
        ; skip this space
        INC DE
        JP CCP_SKIP_BLANKS
; ----------------------------------------------------------------------
; CCP_HL_ADD_A -- add the unsigned A to HL (16-bit add of an 8-bit offset).
;   In: HL = base, A = offset.
;   Out: HL = HL + A.  Clobbers: A, HL, flags.
;   Algorithm: A:=A+L; L:=A; if no carry RET; else INC H; RET.
;   [RE] Used to index CCP_FCB by 0 or 16 (parse FCB1 vs FCB2).
; ----------------------------------------------------------------------
CCP_HL_ADD_A:
        ; low byte of HL + offset
        ADD A,L
        LD L,A
        RET NC
        ; propagate carry into high byte
        INC H
        RET
; ----------------------------------------------------------------------
; CCP_PARSE_FCB1 -- parse the first command-tail filename into FCB at offset 0.
;   In: CCP_PARSEPTR ($9488) -> current parse position in CCP_CMDTEXT.
;   Out: CCP_FCB ($9BCD) filled with drive+name+type; CCP_PARSEPTR advanced;
;     CCP_DRIVEGIVEN ($9BF0) set if an explicit drive prefix was present.
;   Clobbers: A, BC, DE, HL.
;   Algorithm: A:=0 (FCB offset 0); fall into CCP_BUILD_FCB.
;   [RE]
; ----------------------------------------------------------------------
CCP_PARSE_FCB1:
        ; offset 0 -> first FCB (CCP_FCB+0)
        LD A,$00
; ----------------------------------------------------------------------
; CCP_BUILD_FCB -- parse one filename token from the command tail into an FCB.
;   In: A = FCB byte offset (0 for FCB1, 16 for FCB2); CCP_PARSEPTR -> scan point.
;   Out: the FCB at CCP_FCB+offset holds {drive, 8-char NAME, 3-char TYPE} with '*'
;     expanded to '?' and unused positions blank-padded; the 3 trailing extent/record
;     bytes are zeroed; CCP_PARSEPTR / CCP_TOKENPTR advanced past the token;
;     CCP_DRIVEGIVEN set to the parsed drive if a 'd:' prefix was present; A = the
;     count of '?' wildcards in the 11 name+type bytes (nonzero => ambiguous FCB).
;   Clobbers: A, BC, DE, HL.
;   Algorithm: point HL at CCP_FCB+offset (CCP_HL_ADD_A); clear CCP_DRIVEGIVEN; load
;     DE from CCP_PARSEPTR and skip leading blanks (CCP_SKIP_BLANKS); save token start
;     to CCP_TOKENPTR; detect an optional 'd:' drive prefix (letter, via SBC A,$40 to
;     a 1-based drive number, followed by ':') and store the drive into FCB[0];
;     copy up to 8 name chars, skip an over-long name, blank-pad a short name; if a
;     '.' follows copy up to 3 type chars else blank-pad the type; zero the 3 trailing
;     FCB bytes; save the parse pointer; finally count the '?' wildcards.
;   [RE] Classic CP/M 2.2 CCP command-tail FCB parser.
; ----------------------------------------------------------------------
CCP_BUILD_FCB:
        ; HL -> CCP_FCB (drive byte) base
        LD HL,CCP_FCB
        ; HL += offset (select FCB1 or FCB2)
        CALL CCP_HL_ADD_A
        PUSH HL
        PUSH HL
        XOR A
        ; clear explicit-drive flag
        LD (CCP_FCB_DRIVE_PREFIX),A
        ; HL = current parse pointer
        LD HL,(CCP_PARSEPTR)
        EX DE,HL
        ; skip leading blanks before the token
        CALL CCP_SKIP_BLANKS
        EX DE,HL
        ; remember token start for echo
        LD (CCP_TOKENPTR),HL
        EX DE,HL
        POP HL
        LD A,(DE)
        OR A
        JP Z,CCP_FCB_DRIVE_DEFAULT
        ; letter -> 1-based drive number (carry clear)
        SBC A,$40
        LD B,A
        INC DE
        LD A,(DE)
        ; is the next char ':' (drive prefix)?
        CP $3A
        ; yes -> store drive, parse name
        JP Z,CCP_FCB_DRIVE_EXPLICIT
        ; no ':' -> back up, treat as name char
        DEC DE
; ----------------------------------------------------------------------
; CCP_FCB_DRIVE_DEFAULT -- use the current default drive in the FCB drive byte.
;   In: HL -> FCB drive byte; CCP_CDISK ($9BEF).
;   Out: FCB[0] := default drive; continues into the name-copy setup.
;   Clobbers: A.
;   Algorithm: A:=CCP_CDISK; (HL):=A; JP CCP_BUILD_FCB_NAME_SETUP.
;   [RE] Path taken when the token had no explicit 'd:' prefix.
; ----------------------------------------------------------------------
CCP_FCB_DRIVE_DEFAULT:
        ; default drive
        LD A,(CCP_CUR_DRIVE)
        ; FCB drive := default
        LD (HL),A
        JP CCP_BUILD_FCB_NAME_SETUP
; ----------------------------------------------------------------------
; CCP_FCB_DRIVE_EXPLICIT -- store the parsed explicit drive into the FCB.
;   In: B = 1-based drive number from the 'd:' prefix; HL -> FCB drive byte; DE -> ':'.
;   Out: FCB[0] := drive; CCP_DRIVEGIVEN := drive; DE advanced past ':'; continues
;     into the name copy.
;   Clobbers: A, DE.
;   Algorithm: A:=B; CCP_DRIVEGIVEN:=A; (HL):=B; INC DE (consume the ':').
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_DRIVE_EXPLICIT:
        LD A,B
        ; record that a drive was given
        LD (CCP_FCB_DRIVE_PREFIX),A
        ; FCB drive := explicit drive number
        LD (HL),B
        ; consume the ':' separator
        INC DE
; ----------------------------------------------------------------------
; CCP_BUILD_FCB_NAME_SETUP -- begin copying the 8-char file name into the FCB.
;   In: HL -> FCB drive byte (name field follows), DE -> name chars.
;   Out: B := 8 (name width); falls into CCP_FCB_NAME_LOOP.
;   Clobbers: B.
;   Algorithm: B:=8; fall through to the name copy loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_BUILD_FCB_NAME_SETUP:
        ; 8 name characters maximum
        LD B,$08
; ----------------------------------------------------------------------
; CCP_FCB_NAME_LOOP -- copy one file-name character (handling '*' and delimiters).
;   In: DE -> source char, HL -> FCB position, B = name chars remaining.
;   Out: on a delimiter, jumps to CCP_FCB_NAME_PAD to blank-fill; '*' stores a '?' in
;     this position and branches to fill the rest of the field with '?'; otherwise
;     the char is stored and the loop continues.
;   Clobbers: A, HL.
;   Algorithm: if CCP_AT_DELIM -> pad; INC HL; if char=='*' store '?' and branch to
;     the per-position fill; else store char + INC DE; DEC B; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_NAME_LOOP:
        ; stop at a field delimiter
        CALL CCP_AT_DELIM
        ; delimiter -> blank-pad remaining name
        JP Z,CCP_FCB_NAME_PAD
        INC HL
        ; '*' wildcard?
        CP $2A
        JP NZ,CCP_FCB_NAME_STORE
        ; '*' -> store '?' in this position
        LD (HL),$3F
        ; '*' fills the rest of the field with '?'
        JP CCP_FCB_NAME_NEXT
; ----------------------------------------------------------------------
; CCP_FCB_NAME_STORE -- store a literal name character into the FCB.
;   In: A = char, HL -> FCB position, DE -> source.
;   Out: (HL):=char; DE advanced; continues into the loop tail.
;   Clobbers: DE.
;   Algorithm: (HL):=A; INC DE; fall into CCP_FCB_NAME_NEXT.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_NAME_STORE:
        ; store the name character
        LD (HL),A
        ; advance past the consumed char
        INC DE
; ----------------------------------------------------------------------
; CCP_FCB_NAME_NEXT -- loop tail for the 8-char name copy.
;   In: B = name chars remaining.
;   Out: loops back to CCP_FCB_NAME_LOOP until B==0, then falls into the
;     over-long-name skip.
;   Clobbers: B.
;   Algorithm: DEC B; if B != 0 JP CCP_FCB_NAME_LOOP; else fall through.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_NAME_NEXT:
        ; one fewer name char to copy
        DEC B
        JP NZ,CCP_FCB_NAME_LOOP
; ----------------------------------------------------------------------
; CCP_FCB_NAME_SKIP -- discard any name characters beyond the 8-byte field.
;   In: DE -> next source char (name field already full).
;   Out: DE advanced to the first delimiter; then falls into the type parser.
;   Clobbers: A, DE.
;   Algorithm: loop: if CCP_AT_DELIM stop; INC DE; repeat.
;   [RE] Lets an over-length name (e.g. LONGFILENAME.TXT) truncate cleanly.
; ----------------------------------------------------------------------
CCP_FCB_NAME_SKIP:
        ; stop skipping at a delimiter
        CALL CCP_AT_DELIM
        ; delimiter -> go parse the type field
        JP Z,CCP_FCB_TYPE_BEGIN
        ; discard excess name char
        INC DE
        JP CCP_FCB_NAME_SKIP
; ----------------------------------------------------------------------
; CCP_FCB_NAME_PAD -- blank-fill the remaining name positions of the FCB.
;   In: HL -> last filled name position, B = positions remaining.
;   Out: remaining name bytes set to ' '; then falls into the type parser.
;   Clobbers: HL, B.
;   Algorithm: loop: INC HL; (HL):=' '; DEC B; while B != 0; then type parse.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_NAME_PAD:
        INC HL
        ; pad name with a blank
        LD (HL),$20
        DEC B
        JP NZ,CCP_FCB_NAME_PAD
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_BEGIN -- start parsing the 3-char file type, if a '.' is present.
;   In: A = current delimiter char, DE -> it, HL -> end of name field.
;   Out: B := 3 (type width); if the delimiter is '.', consume it and copy the
;     type; otherwise jump straight to blank-padding the type field.
;   Clobbers: A, B, DE.
;   Algorithm: B:=3; if A != '.' JP CCP_FCB_TYPE_PAD; INC DE (eat the dot).
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_BEGIN:
        ; 3 type characters
        LD B,$03
        ; is the delimiter a '.'?
        CP $2E
        ; no type given -> blank-pad type
        JP NZ,CCP_FCB_TYPE_PAD
        ; consume the '.'
        INC DE
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_LOOP -- copy one file-type character (handling '*').
;   In: DE -> source, HL -> FCB type position, B = type chars remaining.
;   Out: on a delimiter, pad the type; '*' -> '?' (fills the rest of the type);
;     otherwise store the char.
;   Clobbers: A, HL.
;   Algorithm: mirror of CCP_FCB_NAME_LOOP for the 3-char type field.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_LOOP:
        ; stop at a delimiter
        CALL CCP_AT_DELIM
        ; delimiter -> blank-pad type
        JP Z,CCP_FCB_TYPE_PAD
        INC HL
        ; '*' wildcard in type?
        CP $2A
        JP NZ,CCP_FCB_TYPE_STORE
        ; '*' -> store '?'
        LD (HL),$3F
        ; '*' fills the rest of the type
        JP CCP_FCB_TYPE_NEXT
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_STORE -- store a literal type character into the FCB.
;   In: A = char, HL -> FCB type position, DE -> source.
;   Out: (HL):=char; DE advanced; continues into the type loop tail.
;   Clobbers: DE.
;   Algorithm: (HL):=A; INC DE; fall into CCP_FCB_TYPE_NEXT.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_STORE:
        ; store the type character
        LD (HL),A
        ; advance past the consumed char
        INC DE
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_NEXT -- loop tail for the 3-char type copy.
;   In: B = type chars remaining.
;   Out: loops to CCP_FCB_TYPE_LOOP until B==0, then falls into the over-long-type
;     skip.
;   Clobbers: B.
;   Algorithm: DEC B; if B != 0 JP CCP_FCB_TYPE_LOOP; else fall through.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_NEXT:
        ; one fewer type char to copy
        DEC B
        JP NZ,CCP_FCB_TYPE_LOOP
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_SKIP -- discard any type characters beyond the 3-byte field.
;   In: DE -> next source char (type field already full).
;   Out: DE advanced to the next delimiter; then falls into the trailer zero-fill.
;   Clobbers: A, DE.
;   Algorithm: loop: if CCP_AT_DELIM stop; INC DE; repeat.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_SKIP:
        ; stop skipping at a delimiter
        CALL CCP_AT_DELIM
        ; delimiter -> zero the FCB trailer
        JP Z,CCP_FCB_ZERO_TRAILER
        ; discard excess type char
        INC DE
        JP CCP_FCB_TYPE_SKIP
; ----------------------------------------------------------------------
; CCP_FCB_TYPE_PAD -- blank-fill the remaining type positions of the FCB.
;   In: HL -> last filled type position, B = positions remaining.
;   Out: remaining type bytes set to ' '; then zero the FCB trailer.
;   Clobbers: HL, B.
;   Algorithm: loop: INC HL; (HL):=' '; DEC B; while B != 0.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_TYPE_PAD:
        INC HL
        ; pad type with a blank
        LD (HL),$20
        DEC B
        JP NZ,CCP_FCB_TYPE_PAD
; ----------------------------------------------------------------------
; CCP_FCB_ZERO_TRAILER -- zero the 3 reserved FCB bytes after name+type, finish.
;   In: HL -> end of the type field.
;   Out: the 3 bytes (extent/S1/S2 area) zeroed; CCP_PARSEPTR saved; HL restored
;     to the start of the FCB; then falls into the wildcard scan.
;   Clobbers: B, HL, DE.
;   Algorithm: B:=3; loop INC HL,(HL):=0,DEC B; save DE->CCP_PARSEPTR; restore
;     HL from the stack (start of FCB pushed by CCP_BUILD_FCB).
;   [RE] The reserved trailer bytes are the FCB extent/record-count cells.
; ----------------------------------------------------------------------
CCP_FCB_ZERO_TRAILER:
        ; 3 trailer bytes (extent/S1/S2)
        LD B,$03
; ----------------------------------------------------------------------
; CCP_FCB_ZERO_LOOP -- zero-fill loop for CCP_FCB_ZERO_TRAILER; then scan wildcards.
;   In: HL -> position before the first trailer byte, B = 3.
;   Out: 3 zero bytes written; CCP_PARSEPTR := DE; HL := start-of-FCB; then count
;     the '?' wildcards in the 11 name+type bytes and return that count in A
;     (A != 0 means the FCB is ambiguous).
;   Clobbers: A, B, C, HL, DE.
;   Algorithm: INC HL,(HL):=0,DEC B loop; EX DE,HL; CCP_PARSEPTR:=HL; POP HL
;     (FCB start); BC:=$000B; fall into the wildcard counter FCB_WILDCARD_SCAN.
;   [RE]
; ----------------------------------------------------------------------
CCP_FCB_ZERO_LOOP:
        INC HL
        ; zero a reserved FCB byte
        LD (HL),$00
        DEC B
        JP NZ,CCP_FCB_ZERO_LOOP
        EX DE,HL
        ; save the advanced parse pointer
        LD (CCP_PARSEPTR),HL
        ; HL = start of the parsed FCB
        POP HL
        ; scan 11 name+type bytes for '?'
        LD BC,$000B
; ----------------------------------------------------------------------
; FCB_WILDCARD_SCAN -- count '?' wildcard chars in a parsed 11-byte FCB filename.
;   In: HL -> the FCB drive byte ($9BCD); the first INC HL steps onto the 8+3
;       name field. BC = $000B on entry (B = 0 wildcard counter, C = 11 byte count;
;       set by 'LD BC,$000B' just before falling in here).
;   Out: A = number of '?' chars found; Z set if none (plain filename),
;        NZ if at least one wildcard (ambiguous reference).
;   Clobbers: A, B, C, HL
;   Algorithm: walk the 11 name+type bytes (loop C from 11 down to 0); for each
;     byte that equals '?' increment the wildcard counter B; on exit move B to A
;     and test it so the caller can branch on ambiguous-vs-plain. [RE]
; ----------------------------------------------------------------------
FCB_WILDCARD_SCAN:
        ; advance to next FCB name/type byte
        INC HL
        ; fetch this name byte
        LD A,(HL)
        ; is it the '?' wildcard char?
        CP $3F
        ; no: skip the wildcard count
        JP NZ,FCB_WILDCARD_SCAN_1
        ; yes: bump '?' counter
        INC B
FCB_WILDCARD_SCAN_1:
        ; one of the 11 name+type bytes done
        DEC C
        ; loop until all 11 scanned
        JP NZ,FCB_WILDCARD_SCAN
        ; return wildcard count...
        LD A,B
        ; ...and set Z (plain) / NZ (ambiguous)
        OR A
        RET
; ----------------------------------------------------------------------
; CCP_BUILTIN_NAMES -- table of the six built-in command names, 4 bytes each.
;   Layout: 'DIR ','ERA ','TYPE','SAVE','REN ','USER' (24 bytes, blank-padded).
;   Indexed 0..5 by SEARCH_BUILTIN; the matched index then selects a handler in
;   CCP_BUILTIN_DISPATCH. [RE]
; ----------------------------------------------------------------------
CCP_BUILTIN_NAMES:
        ; 0=DIR 1=ERA 2=TYPE 3=SAVE 4=REN 5=USER (4 chars each, space-padded)
        DEFB    "DIR ERA TYPESAVEREN USER" ; string
; ----------------------------------------------------------------------
; CCP_SERIAL_STAMP -- 6-byte CP/M serial-number stamp embedded in the CCP.
;   These six bytes are compared against the first six bytes of the BDOS image
;   header (BDOS_FBASE, $9C00) by the serial-check routine CCP_CHECK_SERIAL (it
;   loads DE=$9728, HL=$9C00, B=6 and compares byte-for-byte); a mismatch means
;   the CCP and BDOS are from different copies and CCP_CHECK_SERIAL jumps to
;   CCP_SERIAL_MISMATCH_HALT.
;   Treated here as opaque serial data, not code. [RE]
; ----------------------------------------------------------------------
CCP_SERIAL_STAMP:
        ; CP/M serial-number bytes; must match BDOS header at $9C00 (checked by CCP_CHECK_SERIAL)
        DEFB    $BD,$16,$00,$00,$16,$DF
; ----------------------------------------------------------------------
; SEARCH_BUILTIN -- match the parsed command word against the six built-in names.
;   In: parsed command FCB name field at CCP_FCB_NAME (the command word lives in the
;       first 4+ chars of the FCB name).
;   Out: A = command index 0..5 when a built-in matches with a trailing space; on
;        no match the loop runs C up to 6 and returns with A = 6 (>=6). The caller
;        discriminates by the index value (>=6 means 'not a built-in', falls through
;        to the external-command dispatch slot) -- carry is NOT a result flag here:
;        both the match path and the exhausted path return via NC.
;   Clobbers: A, B, C, DE, HL
;   Algorithm: for command index C = 0..5, point HL at the 4-byte name entry in
;     CCP_BUILTIN_NAMES and DE at the parsed command bytes; compare 4 bytes; on a
;     full match require the next parsed byte to be a space (no trailing junk) and
;     return C as the matched index; otherwise advance HL past this entry and try
;     the next index. [RE]
; ----------------------------------------------------------------------
SEARCH_BUILTIN:
        ; HL -> first built-in name entry (CCP_BUILTIN_NAMES)
        LD HL,CCP_BUILTIN_NAMES
        ; start at command index 0
        LD C,$00
SEARCH_BUILTIN_NEXT:
        ; current command index -> A for the range test
        LD A,C
        ; tried all 6 built-ins?
        CP $06
        ; yes: A>=6, none matched -> not a built-in
        RET NC
        ; DE -> parsed command name in the command FCB
        LD DE,CCP_FCB_NAME
        ; compare 4 name chars
        LD B,$04
SEARCH_BUILTIN_CMP:
        ; next parsed command char
        LD A,(DE)
        ; vs the table name char
        CP (HL)
        ; mismatch: skip rest of this entry
        JP NZ,SEARCH_BUILTIN_SKIP
        INC DE
        ; advance table ptr to next name char
        INC HL
        DEC B
        ; loop the 4-char compare
        JP NZ,SEARCH_BUILTIN_CMP
        ; char after the 4-char name
        LD A,(DE)
        ; must be a space (exact command, no junk)
        CP $20
        ; trailing junk: not this command, try next
        JP NZ,SEARCH_BUILTIN_ADVANCE
        ; matched: return command index in A
        LD A,C
        RET
SEARCH_BUILTIN_SKIP:
        ; skip remaining bytes of the mismatched entry
        INC HL
        DEC B
        ; until 4 bytes of this entry consumed
        JP NZ,SEARCH_BUILTIN_SKIP
SEARCH_BUILTIN_ADVANCE:
        ; advance to next command index
        INC C
        ; retry with the next built-in
        JP SEARCH_BUILTIN_NEXT
; ----------------------------------------------------------------------
; CCP_WARM_ENTRY -- warm-boot entry to the Console Command Processor.
;   In: (cold-boot path enters one line below at CCP_COLD_ENTRY=$975C with C = login
;       byte from the BIOS: high nibble = user number, low nibble = default drive.)
;   Out: does not return normally; reads, parses, and dispatches one command,
;        then loops back through the command processor.
;   Clobbers: all
;   Algorithm: the warm entry first clears the submit/auto-command flag
;     (CCP_SUBMIT_FLAG at CCP_INLEN) then falls into the common entry, which: sets the
;     user number (F_USERNUM=32) from the high nibble of the login byte, resets the
;     disk system (DRV_ALLRESET=13), selects the default drive (DRV_SET=14) from the
;     low nibble, and if no pending submit command prints the 'd>' prompt, reads a
;     console line into the line buffer, sets DMA back to TBUFF, parses it into the
;     command FCB, looks it up with SEARCH_BUILTIN, and JP (HL)'s through
;     CCP_BUILTIN_DISPATCH to the matching built-in (or runs an external .COM). [RE]
; ----------------------------------------------------------------------
CCP_WARM_ENTRY:
        ; warm entry: clear A
        XOR A
        ; clear the submit/auto-command flag
        LD (CCP_INLEN),A
CCP_COLD_ENTRY:
        ; reset CCP stack to its private area
        LD SP,CCP_SUBMIT_FLAG
        ; save the BIOS login byte (user<<4 | drive)
        PUSH BC
        ; login byte -> A
        LD A,C
        ; shift high nibble (user number) down...
        RRA
        RRA
        RRA
        RRA
        ; isolate the 4-bit user number
        AND $0F
        ; E = user number for the set-user call
        LD E,A
        ; BDOS F_USERNUM(32): set current user code
        CALL BDOS_USERNUM
        ; BDOS DRV_ALLRESET(13): reset disk system, returns login vector
        CALL BDOS_DRV_ALLRESET
        ; stash returned login byte in CCP workspace
        LD (CCP_SUBMIT_FLAG),A
        ; restore login byte
        POP BC
        ; login byte -> A again
        LD A,C
        ; isolate the 4-bit default drive number
        AND $0F
        ; remember current/default drive
        LD (CCP_CUR_DRIVE),A
        ; BDOS DRV_SET(14): select the default drive
        CALL BDOS_DRV_SET
        ; pending submit/auto command?
        LD A,(CCP_INLEN)
        ; test the submit flag
        OR A
        ; yes: skip the prompt, take the queued line
        JP NZ,CCP_PARSE_AND_DISPATCH
CCP_PROMPT_AND_READ:
        ; reset CCP stack before prompting
        LD SP,CCP_SUBMIT_FLAG
        ; print CR/LF
        CALL CCP_CRLF
        ; BDOS DRV_GET(25): get current drive number
        CALL BDOS_DRV_GET
        ; convert drive 0..15 to ASCII 'A'..'P'
        ADD A,$41
        ; C_WRITE(2): echo the drive letter
        CALL CCP_CONOUT
        ; '>' prompt character
        LD A,$3E
        ; C_WRITE(2): print the '>' prompt
        CALL CCP_CONOUT
        ; read a console command line into the buffer
        CALL CCP_GETCMD
CCP_PARSE_AND_DISPATCH:
        ; DE -> TBUFF ($0080), the default DMA / line area
        LD DE,$0080
        ; BDOS F_DMAOFF(26): set DMA back to TBUFF ($0080)
        CALL BDOS_F_DMAOFF
        ; BDOS DRV_GET(25): re-read current drive
        CALL BDOS_DRV_GET
        ; update current/default drive
        LD (CCP_CUR_DRIVE),A
        ; parse the typed line into the command FCB
        CALL CCP_PARSE_FCB1
        ; on parse note, echo command tail to first blank
        CALL NZ,CCP_ECHO_TOKEN
        ; explicit drive prefix given on the command?
        LD A,(CCP_FCB_DRIVE_PREFIX)
        ; test the drive-prefix flag
        OR A
        ; yes: go run it as an external command
        JP NZ,CCP_DRIVE_SELECT
        ; SEARCH_BUILTIN: find a built-in command index
        CALL SEARCH_BUILTIN
        ; HL -> built-in dispatch table
        LD HL,CCP_BUILTIN_DISPATCH_TBL
        ; E = command index from SEARCH_BUILTIN
        LD E,A
        ; DE = zero-extended index
        LD D,$00
        ; scale index by 2 (table of words)...
        ADD HL,DE
        ; ...HL -> the matching DEFW entry
        ADD HL,DE
        ; load handler address low byte
        LD A,(HL)
        INC HL
        ; load handler address high byte
        LD H,(HL)
        LD L,A
        ; jump to the built-in command handler
        JP (HL)
; ----------------------------------------------------------------------
; CCP_BUILTIN_DISPATCH_TBL -- jump table of the 7 built-in CCP command handlers.
;   In: indexed by the command number in A (0..6) returned by the built-in matcher
;       SEARCH_BUILTIN (compares the command name against the keyword table at CCP_BUILTIN_NAMES).
;   Out: n/a (table of DEFW handler addresses).
;   Clobbers: n/a (data).
;   Algorithm: the dispatcher at $97B4 loads HL=this table + 2*index, fetches the
;              16-bit handler address, and JP (HL)s to it. Order matches the keyword
;              table "DIR ERA TYPESAVEREN USER": 0=DIR 1=ERA 2=TYPE 3=SAVE 4=REN
;              5=USER, 6=not-a-builtin (load+run as a transient program).
;   [RE] Standard CP/M 2.2 CCP built-in dispatch table.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CCP_BUILTIN_DISPATCH -- word table of the six built-in command handler addresses.
;   Indexed (x2) by the command number SEARCH_BUILTIN returns; entries 0..5 are
;   DIR, ERA, TYPE, SAVE, REN, USER. A seventh DEFW (external/run path) follows
;   so an out-of-range index (6) falls through to the external-command handler. [RE]
; ----------------------------------------------------------------------
CCP_BUILTIN_DISPATCH_TBL:
        ; index 0: DIR builtin
        ; 0: DIR built-in
        DEFW    DIR_CMD
        ; index 1: ERA builtin
        ; 1: ERA built-in
        DEFW    ERA_CMD
        ; index 2: TYPE builtin
        ; 2: TYPE built-in
        DEFW    TYPE_CMD
        ; index 3: SAVE builtin
        ; 3: SAVE built-in
        DEFW    SAVE_CMD
        ; index 4: REN builtin
        ; 4: REN built-in
        DEFW    REN_CMD
        ; index 5: USER builtin
        ; 5: USER built-in
        DEFW    CCP_CMD_USER
        ; index 6: not a builtin -> load and run transient .COM
        ; 6: external / run .COM (out-of-range fallthrough)
        DEFW    CCP_DRIVE_SELECT
; ----------------------------------------------------------------------
; CCP_SERIAL_MISMATCH_HALT -- lock the system when the BDOS serial does not match.
;   In: reached via JP NZ from the CCP serial check (CCP_CHECK_SERIAL) on a byte mismatch.
;   Out: never returns; the CPU is halted.
;   Clobbers: HL; overwrites the first 2 bytes of the CCP entry vector at $9400.
;   Algorithm: store the bytes $F3,$76 (DI ; HALT) over the CCP cold-entry vector,
;              then JP (HL) into $9400 to execute DI then HALT, hanging the machine.
;   [RE] Standard DRI CP/M anti-piracy serial trap: a corrupted/foreign BDOS makes
;        the CCP destroy its own entry point and stop. $76F3 stored little-endian
;        places opcodes F3,76 = DI ; HALT at $9400.
; ----------------------------------------------------------------------
CCP_SERIAL_MISMATCH_HALT:
        ; $76F3 stored little-endian = bytes F3,76 = DI ; HALT
        LD HL,$76F3
        ; overwrite the CCP cold-entry vector with DI ; HALT
        LD (CCP_ENTRY),HL
        ; point HL at the just-patched entry
        LD HL,CCP_ENTRY
        ; jump into it: DI then HALT -> system hangs (serial lock)
        JP (HL)
; ----------------------------------------------------------------------
; PRINT_READ_ERROR -- emit the "READ ERROR" message on a fresh line.
;   In: none.
;   Out: message printed via CCP_CRLF_MSG (CRLF then print-string-until-NUL).
;   Clobbers: A, BC, HL (per the print helper).
;   Algorithm: point BC at the "READ ERROR" string and tail-jump CCP_CRLF_MSG, which
;              prints a CRLF then outputs the string until the $00 terminator.
;   [RE] CCP disk read-error report.
; ----------------------------------------------------------------------
PRINT_READ_ERROR:
        ; BC -> "READ ERROR" string
        LD BC,MSG_READ_ERROR
        ; tail-call CRLF + print-string-until-NUL
        JP CCP_CRLF_MSG
; ----------------------------------------------------------------------
; MSG_READ_ERROR -- NUL-terminated console message "READ ERROR".
;   In: pointed to by PRINT_READ_ERROR.
;   Out: n/a (data).
;   Clobbers: n/a.
;   Algorithm: ASCII text + $00 terminator.
;   [RE] CCP message string.
; ----------------------------------------------------------------------
MSG_READ_ERROR:
        DEFB    "READ ERROR"             ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; PRINT_NO_FILE -- emit the "NO FILE" message on a fresh line.
;   In: none.
;   Out: message printed via CCP_CRLF_MSG (CRLF then print-string-until-NUL).
;   Clobbers: A, BC, HL (per the print helper).
;   Algorithm: point BC at the "NO FILE" string and tail-jump CCP_CRLF_MSG.
;   [RE] CCP "file not found" report (DIR/ERA/REN with no matching file).
; ----------------------------------------------------------------------
PRINT_NO_FILE:
        ; BC -> "NO FILE" string
        LD BC,MSG_NO_FILE
        ; tail-call CRLF + print-string-until-NUL
        JP CCP_CRLF_MSG
; ----------------------------------------------------------------------
; MSG_NO_FILE -- NUL-terminated console message "NO FILE".
;   In: pointed to by PRINT_NO_FILE.
;   Out: n/a (data).
;   Clobbers: n/a.
;   Algorithm: ASCII text + $00 terminator.
;   [RE] CCP message string.
; ----------------------------------------------------------------------
MSG_NO_FILE:
        DEFB    "NO FILE"                ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; PARSE_FCB_DECIMAL -- parse the file-name field of the parsed FCB as a decimal number.
;   In: command tail in the CCP command buffer; reparsed here into the CCP FCB.
;   Out: A = the 8-bit decimal value (also in B); falls through to error (CCP_ECHO_TOKEN)
;        on a bad digit or overflow > 255.
;   Clobbers: A, B, C, D, HL.
;   Algorithm: rebuild the FCB from the tail (CCP_PARSE_FCB1/CCP_BUILD_FCB); if a second
;              drive-prefixed token was parsed (CCP_FCB_DRIVE_PREFIX != 0), error. Walk the 11-char
;              name field (HL=CCP_FCB_NAME): a space ends the number (then verify the
;              remaining chars are all blank); else subtract '0' and require 0..9,
;              accumulate value = value*10 + digit, trapping any carry as overflow.
;              Used by SAVE (page count) and USER (user number).
;   [RE] CCP numeric-argument parser for SAVE n and USER n.
; ----------------------------------------------------------------------
PARSE_FCB_DECIMAL:
        ; (re)parse the command tail into the CCP FCB
        CALL CCP_PARSE_FCB1
        ; A = second-token drive-prefix flag from the parse (0 = none)
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        ; unexpected extra argument -> report bad command line
        JP NZ,CCP_ECHO_TOKEN
        ; HL -> first char of the FCB name field
        LD HL,CCP_FCB_NAME
        ; B=0 (accumulator), C=11 (name field length)
        LD BC,$000B
; ----------------------------------------------------------------------
; PARSE_FCB_DECIMAL_LOOP -- digit accumulation loop for PARSE_FCB_DECIMAL.
;   In: HL -> current name char, B = running value, C = chars remaining.
;   Out: loops until a blank or all 11 chars consumed; B holds the accumulated value.
;   Clobbers: A, B, C, D, HL.
;   Algorithm: load char; if ' ' jump to the trailing-blank check; else digit=char-'0',
;              reject if >= 10; pre-reject if value >= 32 (would overflow *8); then
;              new = value*8 (3x RLCA) + value + value (= *10) + digit, rejecting on
;              carry at each add (overflow); store back, decrement count, repeat.
;   [RE] Inner loop of the CCP decimal parser.
; ----------------------------------------------------------------------
PARSE_FCB_DECIMAL_LOOP:
        LD A,(HL)
        ; space ends the digit run
        CP $20
        ; verify the rest of the field is blank
        JP Z,REQUIRE_TRAILING_BLANKS
        INC HL
        ; char - '0' -> digit value
        SUB $30
        ; reject non-decimal (>= 10)
        CP $0A
        JP NC,CCP_ECHO_TOKEN
        LD D,A
        LD A,B
        ; value already >= 32? top 3 bits set means *8 (RLCA x3) overflows a byte
        AND $E0
        JP NZ,CCP_ECHO_TOKEN
        LD A,B
        ; value << 1 (first of three RLCA -> value*8)
        RLCA
        RLCA
        RLCA
        ; value*8 + value -> *9 (trap carry = overflow)
        ADD A,B
        JP C,CCP_ECHO_TOKEN
        ; +value -> *10 (trap carry = overflow)
        ADD A,B
        JP C,CCP_ECHO_TOKEN
        ; + new digit (trap carry = overflow)
        ADD A,D
        JP C,CCP_ECHO_TOKEN
        ; store back the running value
        LD B,A
        DEC C
        JP NZ,PARSE_FCB_DECIMAL_LOOP
        RET
; ----------------------------------------------------------------------
; REQUIRE_TRAILING_BLANKS -- assert the remaining FCB name chars are all spaces.
;   In: HL -> next name char, C = count of chars remaining, B = parsed value.
;   Out: A = accumulated decimal value (from B) on success; falls to CCP_ECHO_TOKEN
;        (bad command line) if any non-space is found.
;   Clobbers: A, C, HL.
;   Algorithm: scan C chars; any char != ' ' is an error; on reaching the end return
;              the parsed value held in B.
;   [RE] Tail of the SAVE/USER decimal parser.
; ----------------------------------------------------------------------
REQUIRE_TRAILING_BLANKS:
        LD A,(HL)
        ; must be a space
        CP $20
        ; trailing junk -> bad command line
        JP NZ,CCP_ECHO_TOKEN
        INC HL
        DEC C
        ; continue while chars remain
        JP NZ,REQUIRE_TRAILING_BLANKS
        ; return the accumulated decimal value
        LD A,B
        RET
; ----------------------------------------------------------------------
; COPY_3_BYTES -- copy a 3-byte field (an FCB type/extension) (HL)->(DE).
;   In: HL = source, DE = destination.
;   Out: HL, DE advanced past 3 bytes; B = 0.
;   Clobbers: A, B, DE, HL.
;   Algorithm: set B=3 and fall into the generic byte-copy loop COPY_N_BYTES.
;   [RE] Called only by the transient-program loader (CCP_CMD_TRANSIENT) to save the
;        command's 3-byte FCB type field (CCP_FCB_EXT) into a holding area (CCP_COM_EXT)
;        before the FCB is rebuilt.
; ----------------------------------------------------------------------
COPY_3_BYTES:
        ; 3 bytes = FCB type/extension field
        LD B,$03
; ----------------------------------------------------------------------
; COPY_N_BYTES -- copy B bytes from (HL) to (DE).
;   In: HL = source, DE = destination, B = byte count (> 0).
;   Out: HL, DE advanced past the copied bytes; B = 0.
;   Clobbers: A, B, DE, HL.
;   Algorithm: loop: load (HL), store (DE), bump both pointers, dec B until zero.
;   [RE] Generic CCP memcpy. Entered with B=16 to copy a whole FCB (REN, REN_CMD),
;        B=33 to copy the transient FCB to $005C, B=$80 to copy a sector, and B=3 via
;        COPY_3_BYTES.
; ----------------------------------------------------------------------
COPY_N_BYTES:
        ; load source byte
        LD A,(HL)
        ; store to destination
        LD (DE),A
        INC HL
        INC DE
        DEC B
        ; repeat for B bytes
        JP NZ,COPY_N_BYTES
        RET
; ----------------------------------------------------------------------
; TBUFF_INDEX_FETCH -- read a byte from the default DMA buffer (TBUFF=$0080) at index C+A.
;   In: A = an extra offset, C = base index into the buffer.
;   Out: A = byte read from TBUFF + (C + A); HL = its address.
;   Clobbers: A, HL.
;   Algorithm: HL = TBUFF; A = A + C; add A to HL (via CCP_HL_ADD_A); load (HL) into A.
;   [RE] CCP reads a directory-entry byte out of the BDOS DMA buffer at TBUFF=$0080
;        (used by DIR to walk the returned directory records).
; ----------------------------------------------------------------------
TBUFF_INDEX_FETCH:
        ; HL = TBUFF (default DMA buffer at $0080)
        LD HL,$0080
        ; combine the two index parts (C + A)
        ADD A,C
        ; HL += A (16-bit add)
        CALL CCP_HL_ADD_A
        ; fetch the indexed byte
        LD A,(HL)
        RET
; ----------------------------------------------------------------------
; RESOLVE_DRIVE_PREFIX -- clear the FCB drive byte, then select the command's drive.
;   In: parsed FCB at CCP_FCB (drive byte CCP_FCB); explicit drive code in CCP_FCB_DRIVE_PREFIX
;       (1=A..), 0=default; current logged drive in CCP_CUR_DRIVE.
;   Out: the requested drive is selected (BDOS Select Disk, fn 14) when it differs from
;        the current drive; returns with the FCB drive byte forced to 0 (default).
;   Clobbers: A, HL.
;   Algorithm: store 0 into the FCB drive byte (auto-select); read the explicit drive
;              code, if 0 (none) return; decrement to a 0-based number; if it equals the
;              current drive return; otherwise tail-call BDOS_DRV_SET (BDOS Select Disk).
;   [RE] CCP drive-prefix handler. Companion CCP_RESTORE_DEFAULT_DRIVE ($9866) keeps the
;        FCB drive byte (skips the initial clear).
; ----------------------------------------------------------------------
RESOLVE_DRIVE_PREFIX:
        XOR A
        ; force FCB drive byte = 0 (use selected default drive)
        LD (CCP_FCB),A
        ; A = explicit drive code from the command (0 = none)
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        ; no explicit drive -> nothing to select
        RET Z
        ; convert 1-based code to 0-based drive number
        DEC A
        ; HL -> current logged drive
        LD HL,CCP_CUR_DRIVE
        ; already the current drive?
        CP (HL)
        ; yes -> no select needed
        RET Z
        ; tail-call BDOS Select Disk (fn 14) with A=drive
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; CCP_RESTORE_DEFAULT_DRIVE -- If the parsed FCB carried an explicit drive prefix, re-select the
; default drive (no FCB-drive-byte clear).
;   In: CCP_FCB_DRIVE_PREFIX = explicit drive prefix parsed from the command's FCB (0 = none),
;       CCP_CUR_DRIVE = current default drive code.
;   Out: When the FCB had a prefix that differs from the default, the BDOS current disk is set back
;        to the default drive (CCP_CUR_DRIVE); A clobbered.
;   Clobbers: A, E, HL.
;   Algorithm: If the FCB drive byte is 0 (no prefix) return. Otherwise convert the 1-based prefix
;              to 0-based; if it already equals the default drive (CCP_CUR_DRIVE) return; else load
;              the DEFAULT drive code (CCP_CUR_DRIVE) and call BDOS F_DRV_SET (fn 14) to re-select
;              it. Variant of RESOLVE_DRIVE_PREFIX: it does NOT zero the FCB drive byte at CCP_FCB,
;              and it selects the DEFAULT drive (restoring it on the post-operation/error paths)
;              rather than the FCB's drive.
;   [RE]
; ----------------------------------------------------------------------
CCP_RESTORE_DEFAULT_DRIVE:
        ; Load explicit drive prefix parsed into this FCB (0 => no prefix)
        LD A,(CCP_FCB_DRIVE_PREFIX)
        OR A
        ; No explicit drive prefix: leave current disk unchanged
        RET Z
        ; Convert 1-based prefix (A=1..16) to 0-based drive code
        DEC A
        LD HL,CCP_CUR_DRIVE
        ; Compare against the current default drive (CCP_CUR_DRIVE)
        CP (HL)
        ; Prefix already equals the default drive: nothing to do
        RET Z
        ; Load the DEFAULT drive code as the BDOS F_DRV_SET argument (restore it)
        LD A,(CCP_CUR_DRIVE)
        ; Tail-call BDOS F_DRV_SET (fn 14) to re-select the default drive
        JP BDOS_DRV_SET
; ----------------------------------------------------------------------
; DIR_CMD -- CCP built-in DIR: list directory entries matching the command-tail filespec.
;   In: Command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: Matching filenames printed (2 per line as 'd:NAME EXT'); 'NO FILE' if none. Returns via the
;        CCP command-complete path.
;   Clobbers: A, B, C, D, E, H, L.
;   Algorithm: Build the search FCB from the tail (CCP_PARSE_FCB1); select the requested drive
;              (RESOLVE_DRIVE_PREFIX). If the first FCB name byte is blank (no name given), fall
;              into DIR_WILDCARD_FILL to set all 11 name/type bytes to '?' (match every file). Falls
;              through to DIR_START_SEARCH which issues SEARCH_FIRST and enters the format loop.
;   [RE]
; ----------------------------------------------------------------------
DIR_CMD:
        ; Parse the command tail into the search FCB at CCP_FCB
        CALL CCP_PARSE_FCB1
        ; Select the drive named by the filespec prefix
        CALL RESOLVE_DRIVE_PREFIX
        ; Point at the FCB name field (first name byte)
        LD HL,CCP_FCB_NAME
        LD A,(HL)
        ; First name byte blank? => no filespec name was given
        CP $20
        JP NZ,DIR_START_SEARCH
        ; 11 = length of the FCB name+type field to wildcard-fill
        LD B,$0B
; ----------------------------------------------------------------------
; DIR_WILDCARD_FILL -- Overwrite the 11 FCB name+type bytes with '?' so DIR matches every file.
;   In: HL = first name byte of the search FCB; B = 11.
;   Out: 11 bytes set to '?' ($3F); HL advanced past them; B = 0. Falls into DIR_START_SEARCH.
;   Clobbers: B, HL (A preserved).
;   Algorithm: Store '?' through HL, advance, decrement count, repeat 11 times.
;   [RE]
; ----------------------------------------------------------------------
DIR_WILDCARD_FILL:
        ; Write '?' wildcard into this FCB name byte
        LD (HL),$3F
        INC HL
        DEC B
        ; Loop until all 11 name+type bytes are wildcarded
        JP NZ,DIR_WILDCARD_FILL
; ----------------------------------------------------------------------
; DIR_START_SEARCH -- Begin the DIR directory scan and test the first SEARCH result.
;   In: Search FCB at CCP_FCB populated.
;   Out: E (per-line entry counter) initialised to 0 and pushed; BDOS SEARCH_FIRST issued; if no
;        match 'NO FILE' is printed. Falls through to DIR_CMD_2.
;   Clobbers: A, E, flags; pushes DE (the entry counter).
;   Algorithm: Set the per-line entry counter E=0 and save it on the stack; call BDOS SEARCH_FIRST
;              (fn 17); on a no-match (Z) print 'NO FILE'. Falls through to DIR_CMD_2 which loops
;              over results.
;   [RE]
; ----------------------------------------------------------------------
DIR_START_SEARCH:
        ; E = directory-entry counter (drives the per-line column layout)
        LD E,$00
        ; Save the entry counter across the BDOS calls
        PUSH DE
        ; BDOS SEARCH_FIRST (fn 17) on the FCB at CCP_FCB
        CALL CCP_SEARCH_FIRST_SUBMIT
        ; No directory match (Z): print 'NO FILE'
        CALL Z,PRINT_NO_FILE
; ----------------------------------------------------------------------
; DIR_CMD_2 -- DIR main loop body: format one matched directory entry from the DMA buffer.
;   In: Z flag from the preceding SEARCH set when the directory is exhausted; BDOS stored the
;       matched entry's directory code (0..3) in CCP_BDOS_RESULT; the matched 32-byte entry sits in
;       the 128-byte DMA buffer (TBUFF $0080).
;   Out: One entry printed as 'd:NAME EXT'; loops via SEARCH_NEXT; exits to DIR_EXIT when no more
;        entries.
;   Clobbers: A, B, C, D, E, H, L.
;   Algorithm: If SEARCH reported no (further) match, go DIR_EXIT. Convert the directory code (0..3)
;              in CCP_BDOS_RESULT to the matched entry's byte offset in the DMA buffer = code*32
;              (RRCA x3 then AND $60), into C. Read the entry's flag byte at offset 10; if its bit7
;              (RLA into carry) is set, skip this entry. Otherwise pop+increment+re-push the entry
;              counter, AND $01 to test column parity: odd index continues the current line
;              (DIR_FMT_ENTRY_COLS), even index starts a fresh CRLF line then prints the drive
;              letter ('A'+drive) and ':'. Then print the 11-char name. (Layout is 2 entries per
;              line, per the AND $01 mask.)
;   [RE]
; ----------------------------------------------------------------------
DIR_CMD_2:
        ; SEARCH returned no (further) match: finish DIR
        JP Z,DIR_EXIT
        ; BDOS directory code (0..3) of the matched entry, stored by the SEARCH wrapper
        LD A,(CCP_BDOS_RESULT)
        RRCA
        RRCA
        RRCA
        ; code*32: byte offset of the matched 32-byte entry within the DMA buffer (RRCA x3 then
        ; mask)
        AND $60
        ; C = base offset of this entry within the DMA buffer
        LD C,A
        ; Offset 10 within the entry: the file flag/attribute byte
        LD A,$0A
        ; Fetch DMA[C + 10] (the entry's flag byte)
        CALL TBUFF_INDEX_FETCH
        ; Move bit7 of the flag byte into carry
        RLA
        ; Flag bit7 set: skip this entry, advance to SEARCH_NEXT
        JP C,DIR_NEXT_OR_EXIT
        ; Recover the running entry counter (E)
        POP DE
        LD A,E
        ; Count this displayed entry
        INC E
        PUSH DE
        ; Parity of the entry index => 2-per-line column layout
        AND $01
        PUSH AF
        ; Odd index: continue on the same line with a column separator
        JP NZ,DIR_FMT_ENTRY_COLS
        ; Even index: start a fresh output line (CRLF)
        CALL CCP_CRLF
        PUSH BC
        ; BDOS GET_CUR_DRIVE (fn 25) for the drive number
        CALL BDOS_DRV_GET
        POP BC
        ; Convert drive 0..15 to letter 'A'..'P'
        ADD A,$41
        CALL CCP_CONOUT_KEEPBC
        ; ':' separator after the drive letter
        LD A,$3A
        CALL CCP_CONOUT_KEEPBC
        JP DIR_PRINT_NAME
; ----------------------------------------------------------------------
; DIR_FMT_ENTRY_COLS -- Emit the column separator before the 2nd entry on a line.
;   In: Reached for an odd entry index (continuing the current output line).
;   Out: A space separator and a ':' printed; falls through to DIR_PRINT_NAME.
;   Clobbers: A.
;   Algorithm: Print the inter-column space (CCP_SPACE), then a ':' separator, then continue into
;              the name-print code.
;   [RE]
; ----------------------------------------------------------------------
DIR_FMT_ENTRY_COLS:
        ; Print the inter-column space
        CALL CCP_SPACE
        ; ':' column separator
        LD A,$3A
        CALL CCP_CONOUT_KEEPBC
; ----------------------------------------------------------------------
; DIR_PRINT_NAME -- Print one directory entry's 11-character NAME EXT field.
;   In: C = base offset of the entry within the DMA buffer (TBUFF $0080).
;   Out: Bytes 1..11 of the name/type printed with high bits stripped.
;   Clobbers: A, B.
;   Algorithm: Print a leading space (CCP_SPACE), set B=1 (first name byte index, skipping the drive
;              byte at 0), and fall into DIR_EMIT_NAME_CHAR.
;   [RE]
; ----------------------------------------------------------------------
DIR_PRINT_NAME:
        ; Leading space before the filename
        CALL CCP_SPACE
        ; B = name-byte index, starting at offset 1 (skip the FCB drive byte at 0)
        LD B,$01
; ----------------------------------------------------------------------
; DIR_EMIT_NAME_CHAR -- Loop emitting the characters of a directory name/type field.
;   In: B = current name byte index (1..11); C = entry base offset in the DMA buffer; the
;       entry-parity value pushed by DIR_CMD_2 is on the stack.
;   Out: Each character printed (blank positions emitted as a single space); a separator space
;        inserted between name (1..8) and type (9..11).
;   Clobbers: A, B.
;   Algorithm: Fetch DMA[C + B] and strip the high bit (AND $7F). If it is non-blank, print it
;              (DIR_PUT_NAME_CHAR). If it is a blank, recover the saved parity value (POP/PUSH AF)
;              and CP $03; NOTE in THIS 2.20 build the saved value is the AND $01 parity (only ever
;              0 or 1), so CP $03 never matches and the type-peek block at LD A,$09 is effectively
;              dead -- the code always substitutes a single space (DIR_EMIT_NAME_CHAR_2). (In the
;              4-column 2.23 twin the saved value is AND $03, making that block live.)
;   [RE]
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR:
        ; A = current name byte index
        LD A,B
        ; Fetch DMA[C + index] = this name/type character
        CALL TBUFF_INDEX_FETCH
        ; Strip the directory attribute high bit
        AND $7F
        ; Is this character a blank?
        CP $20
        ; Non-blank: print it directly
        JP NZ,DIR_PUT_NAME_CHAR
        ; Recover the saved entry-parity value pushed by DIR_CMD_2
        POP AF
        ; Keep it saved for the next iteration
        PUSH AF
        ; Compare saved value to 3 (never matches here: AND $01 yields only 0/1)
        CP $03
        ; Always taken in this build: emit a single space for the blank
        JP NZ,DIR_EMIT_NAME_CHAR_2
        ; (Dead in 2.20) offset 9 = first type-field byte, peeked to detect an all-blank extension
        LD A,$09
        CALL TBUFF_INDEX_FETCH
        AND $7F
        CP $20
        ; (Dead in 2.20) all-blank extension: stop and go fetch the next entry
        JP Z,DIR_SEARCH_NEXT
; ----------------------------------------------------------------------
; DIR_EMIT_NAME_CHAR_2 -- Substitute a single space for a blank name character, then fall into the
; emit step.
;   In: Reached when the current name character is a blank to be rendered as one space.
;   Out: A = ' ' ($20); falls into DIR_PUT_NAME_CHAR (CONOUT + advance).
;   Clobbers: A.
;   Algorithm: Load a space and continue to the character-output/advance step.
;   [RE]
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR_2:
        ; Emit a single space for the blank position
        LD A,$20
; ----------------------------------------------------------------------
; DIR_PUT_NAME_CHAR -- Output one name character and advance to the next name-field position.
;   In: A = character to print; B = current name byte index; C = entry base offset.
;   Out: Character printed; B incremented; loops back for the next character, or inserts the
;        name/type gap, or finishes the field.
;   Clobbers: A, B.
;   Algorithm: CONOUT the character (CCP_CONOUT_KEEPBC). Increment B; if B reaches 12 the 11-char
;              field is done (go DIR_SEARCH_NEXT). When B reaches 9 (start of the type field) print
;              an extra separator space then continue the loop; otherwise just continue.
;   [RE]
; ----------------------------------------------------------------------
DIR_PUT_NAME_CHAR:
        ; CONOUT this name/type character (BDOS fn 2)
        CALL CCP_CONOUT_KEEPBC
        ; Advance to the next name byte index
        INC B
        LD A,B
        ; Reached index 12 (all 11 chars done)?
        CP $0C
        ; Field complete: fetch the next directory entry
        JP NC,DIR_SEARCH_NEXT
        ; Reached the first type-field byte (index 9)?
        CP $09
        JP NZ,DIR_EMIT_NAME_CHAR
        ; Print the name/extension separator space
        CALL CCP_SPACE
        ; Continue emitting type-field characters
        JP DIR_EMIT_NAME_CHAR
; ----------------------------------------------------------------------
; DIR_SEARCH_NEXT -- Drop the saved parity value, then fall into the break-check + SEARCH_NEXT path.
;   In: The entry-parity value pushed by DIR_CMD_2 is on the stack.
;   Out: That value discarded; falls into DIR_NEXT_OR_EXIT which polls for a break and issues
;        SEARCH_NEXT.
;   Clobbers: AF.
;   Algorithm: POP the saved parity value off the stack (the per-line entry counter pushed in
;              DIR_START_SEARCH remains beneath it), then continue into the break-check +
;              SEARCH_NEXT path.
;   [RE]
; ----------------------------------------------------------------------
DIR_SEARCH_NEXT:
        ; Discard the saved entry-parity value pushed by DIR_CMD_2
        POP AF
; ----------------------------------------------------------------------
; DIR_NEXT_OR_EXIT -- Poll for a console abort, then issue BDOS SEARCH_NEXT to continue DIR.
;   In: Search FCB still set from the original SEARCH_FIRST.
;   Out: If a key is waiting (break) DIR aborts to DIR_EXIT; otherwise SEARCH_NEXT (fn 18) runs and
;        the loop resumes at DIR_CMD_2.
;   Clobbers: A.
;   Algorithm: Call the console-status/break check (CCP_CHECK_ABORT); if a key is waiting (NZ), exit
;              DIR. Else call BDOS SEARCH_NEXT (fn 18) and loop back to DIR_CMD_2 to format the next
;              entry.
;   [RE]
; ----------------------------------------------------------------------
DIR_NEXT_OR_EXIT:
        ; Poll console for a break/abort keypress (BDOS fn 11 then fn 1)
        CALL CCP_CHECK_ABORT
        ; Key pressed: abort the directory listing
        JP NZ,DIR_EXIT
        ; BDOS SEARCH_NEXT (fn 18) for the following entry
        CALL BDOS_F_SNEXT
        ; Format the next matched entry
        JP DIR_CMD_2
; ----------------------------------------------------------------------
; DIR_EXIT -- DIR completion: drop the saved entry counter and return to the CCP command-complete
; path.
;   In: The per-line entry counter (pushed in DIR_START_SEARCH) is on the stack.
;   Out: Stack balanced; jumps to the shared CCP end-of-command handler.
;   Clobbers: DE.
;   Algorithm: POP the saved DE counter and jump to CCP_RETURN_OK (the CCP post-command /
;              return-to-prompt handler).
;   [RE]
; ----------------------------------------------------------------------
DIR_EXIT:
        ; Balance the entry counter pushed at the start of DIR
        POP DE
        ; Return to the CCP command-complete handler
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; ERA_CMD -- CCP built-in ERA (ERASE): delete the files matching the command-tail filespec.
;   In: Command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: Matching files deleted via BDOS; if the spec was all-wildcard (all 11 FCB bytes '?') the
;        user is prompted 'ALL (Y/N)?' first. Returns via the CCP command-complete path.
;   Clobbers: A, B, C, D, E, H, L.
;   Algorithm: Build the FCB (CCP_PARSE_FCB1 returns A = count of '?' wildcard bytes in the 11-char
;              name/type). If A=11 (every position is a wildcard, i.e. '*.*') print 'ALL (Y/N)?',
;              read a console line, and abort unless it is a single 'Y'. Then fall into
;              ERA_DO_DELETE.
;   [RE]
; ----------------------------------------------------------------------
ERA_CMD:
        ; Parse the command tail into the FCB; A = count of '?' wildcard bytes
        CALL CCP_PARSE_FCB1
        ; All 11 name/type bytes wildcard => the spec was '*.*' (erase everything)
        CP $0B
        ; Not '*.*': skip the confirmation prompt
        JP NZ,ERA_DO_DELETE
        ; Point at the 'ALL (Y/N)?' prompt string
        LD BC,MSG_ERA_CONFIRM
        ; Print CRLF then the prompt
        CALL CCP_CRLF_MSG
        ; Read a console input line (the Y/N reply)
        CALL CCP_GETCMD
        ; Point at the read-line character-count byte
        LD HL,CCP_INLEN
        ; Require exactly one reply character (count must be 1)
        DEC (HL)
        ; Not a single char: abort back to the prompt
        JP NZ,CCP_PROMPT_AND_READ
        INC HL
        LD A,(HL)
        ; Reply must be 'Y'
        CP $59
        ; Not 'Y': cancel the ERA and return to the prompt
        JP NZ,CCP_PROMPT_AND_READ
        INC HL
        ; Advance the command-tail parse pointer past the consumed reply
        LD (CCP_PARSEPTR),HL
; ----------------------------------------------------------------------
; ERA_DO_DELETE -- Perform the actual ERA file deletion after any confirmation.
;   In: FCB at CCP_FCB holds the (possibly wildcard) filespec.
;   Out: BDOS DELETE_FILE executed; 'NO FILE' printed when nothing matched; returns via the CCP
;        command-complete path.
;   Clobbers: A, D, E.
;   Algorithm: Select the FCB's drive (RESOLVE_DRIVE_PREFIX); DE = FCB; call BDOS DELETE_FILE (fn
;              19). INC A so a $FF (no-file) return becomes 0/Z; on Z print 'NO FILE'. Jump to the
;              CCP post-command handler.
;   [RE]
; ----------------------------------------------------------------------
ERA_DO_DELETE:
        ; Select the drive named by the filespec
        CALL RESOLVE_DRIVE_PREFIX
        ; DE -> FCB for the delete call
        LD DE,CCP_FCB
        ; BDOS DELETE_FILE (fn 19) on the FCB
        CALL BDOS_F_DELETE
        ; Map $FF (no file deleted) to 0 so Z signals 'nothing matched'
        INC A
        ; Nothing deleted => print 'NO FILE'
        CALL Z,PRINT_NO_FILE
        ; Return to the CCP command-complete handler
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; MSG_ERA_CONFIRM -- ASCII prompt 'ALL (Y/N)?' shown before erasing every file (ERA *.*).
;   In: n/a (data).
;   Out: n/a (null-terminated string constant).
;   Clobbers: none.
;   Algorithm: Null-terminated string printed (CRLF-prefixed) by CCP_CRLF_MSG when an ERA names
;              all-wildcard files.
;   [RE]
; ----------------------------------------------------------------------
MSG_ERA_CONFIRM:
        DEFB    "ALL (Y/N)?"             ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; TYPE_CMD -- CCP built-in TYPE: open the named text file and echo its contents to the console.
;   In: Command tail already parsed; default drive in CCP_CUR_DRIVE.
;   Out: File contents printed record by record until the $1A EOF marker or a console break; on open
;        failure the offending name is echoed. Returns via the CCP command-complete path.
;   Clobbers: A, B, C, D, E, H, L.
;   Algorithm: Re-parse the FCB (CCP_PARSE_FCB1); if the parse flagged the spec (NZ, e.g. ambiguous)
;              reject it via CCP_ECHO_TOKEN. Select the drive and BDOS OPEN the file
;              (CCP_OPEN_SUBMIT = fn 15); if the open fails (Z) go report it. Emit a leading CRLF,
;              prime the per-record byte counter CCP_FCB_TAIL to $FF, and enter the read/print loop
;              (TYPE_PRINT_LOOP).
;   [RE]
; ----------------------------------------------------------------------
TYPE_CMD:
        ; Parse the command tail into the FCB at CCP_FCB
        CALL CCP_PARSE_FCB1
        ; Bad/ambiguous filespec: echo the offending token and abort
        JP NZ,CCP_ECHO_TOKEN
        ; Select the file's drive
        CALL RESOLVE_DRIVE_PREFIX
        ; BDOS OPEN_FILE (fn 15) on the FCB at CCP_FCB
        CALL CCP_OPEN_SUBMIT
        ; Open failed (file not found): go report it
        JP Z,TYPE_NO_FILE
        ; Emit a leading CRLF before the file text
        CALL CCP_CRLF
        ; Point at the TYPE per-record byte counter
        LD HL,CCP_FCB_TAIL
        ; Prime the counter so the first loop pass forces a record read
        LD (HL),$FF
; ----------------------------------------------------------------------
; TYPE_PRINT_LOOP -- TYPE inner loop: read each record and print its bytes until EOF.
;   In: File opened; CCP_FCB_TAIL = per-record byte counter (primed to $FF).
;   Out: Each 128-byte record's characters echoed; stops at the $1A (CTRL-Z) EOF marker, a non-zero
;        read status, or a console break. Returns via the CCP command-complete path.
;   Clobbers: A, B, C, D, E, H, L.
;   Algorithm: When the byte counter has reached $80 (record consumed) read the next record (BDOS
;              READ_SEQ, fn 20); a non-zero read status ends the file/handles the error at
;              TYPE_READ_DONE, and the counter is reset to 0. INC the counter, index TBUFF+counter
;              (LD HL,$0080 + CCP_HL_ADD_A); if the byte is $1A finish. Otherwise CONOUT it and poll
;              the console for a break; on break finish, else loop.
;   [RE]
; ----------------------------------------------------------------------
TYPE_PRINT_LOOP:
        ; Point at the per-record byte counter
        LD HL,CCP_FCB_TAIL
        ; Fetch the current record byte (TBUFF + counter)
        LD A,(HL)
        ; Consumed a whole 128-byte record? then read the next one
        CP $80
        ; Still within the current record: print the next byte
        JP C,TYPE_EMIT_CHAR
        PUSH HL
        ; BDOS READ_SEQ (fn 20) next record into the DMA buffer
        CALL CCP_READ_SUBMIT
        POP HL
        ; Non-zero status: end of file (or error) -> finish at TYPE_READ_DONE
        JP NZ,TYPE_READ_DONE
        XOR A
        ; Reset the byte counter to 0 for the new record
        LD (HL),A
; ----------------------------------------------------------------------
; TYPE_EMIT_CHAR -- Emit one buffered character of the TYPE'd file, advancing the record index.
;   In: HL -> the TYPE record-byte-index cell (CCP_FCB_TAIL); A = the current within-record offset;
;       the current 128-byte record has already been read into TBUFF ($0080).
;   Out: character written to the console via C_WRITE; loops back for the next character, or returns
;        to the CCP command-complete exit on Ctrl-Z (EOF marker) or a console-abort keypress.
;   Clobbers: A, HL, flags.
;   Algorithm: INC the index cell; form TBUFF+offset ($0080 + A via CCP_HL_ADD_A) and fetch the
;              byte. If it is $1A (Ctrl-Z = soft end-of-file) finish the command. Otherwise write
;              the byte with BDOS C_WRITE (fn 2), poll the console for an abort keystroke
;              (CCP_CHECK_ABORT), and on abort finish; else continue the TYPE output loop.
; [RE] TYPE built-in inner emit step; $1A = CP/M text EOF sentinel. [DOC CPMREF: CCP TYPE]
; ----------------------------------------------------------------------
TYPE_EMIT_CHAR:
        ; advance the TYPE record-byte-index cell (next byte within the current 128-byte record)
        ; advance the within-record byte index (next byte of the current 128-byte record)
        INC (HL)
        ; TBUFF base ($0080); CCP_HL_ADD_A adds the current offset in A to form TBUFF+offset
        ; TBUFF base ($0080); the following CCP_HL_ADD_A adds the byte index in A to address
        ; TBUFF+index
        LD HL,$0080
        CALL CCP_HL_ADD_A
        LD A,(HL)
        ; $1A = Ctrl-Z, CP/M soft end-of-file marker -> stop TYPE
        ; $1A = Ctrl-Z, the CP/M soft end-of-file marker that terminates a text file
        CP $1A
        ; EOF reached: branch to the CCP command-complete exit
        ; EOF reached: stop TYPE and return through the CCP command-complete path
        JP Z,CCP_RETURN_OK
        ; BDOS C_WRITE (fn 2): print this character to the console
        ; emit this record byte to the console via BDOS C_WRITE (fn 2)
        CALL CCP_CONOUT
        ; poll console status (fn 11) then read (fn 1) if a key is down; nonzero = user pressed a
        ; key to abort TYPE
        ; poll the console for a key (fn 11/fn 1); nonzero = user pressed a key to abort TYPE
        CALL CCP_CHECK_ABORT
        ; user aborted: branch to the command-complete exit
        ; user aborted: stop TYPE and return through the CCP command-complete path
        JP NZ,CCP_RETURN_OK
        ; no EOF/abort: continue the TYPE character loop
        ; no EOF and no abort: loop back for the next character/record
        JP TYPE_PRINT_LOOP
; ----------------------------------------------------------------------
; TYPE_READ_DONE -- Handle the result of a failed/short F_READ during TYPE (EOF vs read error).
;   In: A = BDOS F_READ (fn 20) return code from the just-attempted sequential read (1 = normal
;       end-of-file, other nonzero = read error).
;   Out: on normal EOF returns quietly to the CCP exit; on a read error prints "READ ERROR" and
;        falls through to the no-file/error tail.
;   Clobbers: A, BC, flags.
;   Algorithm: DEC A; if the code was 1 (normal EOF) jump to the command-complete exit. Otherwise
;              (read error) call the "READ ERROR" message printer, then fall into the drive-restore
;              + bad-command echo tail.
; [RE] TYPE built-in read-failure dispatch. [DOC CPMREF: CCP TYPE]
; ----------------------------------------------------------------------
TYPE_READ_DONE:
        ; F_READ code 1 (normal EOF) -> 0 here; any other code stays nonzero = real error
        DEC A
        ; normal end-of-file: finish the TYPE command cleanly
        JP Z,CCP_RETURN_OK
        ; print the "READ ERROR" message (disk read failure)
        CALL PRINT_READ_ERROR
; ----------------------------------------------------------------------
; TYPE_NO_FILE -- TYPE error/not-found tail: restore the caller's drive and echo the bad command.
;   In: none (entered when the TYPE target file could not be opened, or after a read error).
;   Out: re-selects the user's original drive and jumps to the bad-command echo path; does not
;        return.
;   Clobbers: A, HL, flags.
;   Algorithm: call CCP_RESTORE_DEFAULT_DRIVE to restore the default drive selection, then jump to
;              the CCP_ECHO_TOKEN routine that re-emits the offending command word followed by '?'.
; [RE] Shared TYPE failure exit. [DOC CPMREF: CCP TYPE]
; ----------------------------------------------------------------------
TYPE_NO_FILE:
        ; restore the user's original/default drive after the temporary drive switch
        CALL CCP_RESTORE_DEFAULT_DRIVE
        ; echo the unrecognized/failed command token with a '?' and re-prompt
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; SAVE_CMD -- CCP built-in SAVE: write N pages of memory from the TPA to a new disk file.
;   In: command line "SAVE n filespec"; n = decimal page count (256-byte pages) parsed from the
;       line, filespec built into the CCP command FCB (CCP_FCB).
;   Out: creates the named file and writes n*2 128-byte records starting at $0100; on success
;        returns via the SAVE finish path, on dir-full/disk-full prints "NO SPACE".
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: parse the numeric page count (PARSE_FCB_DECIMAL) and stash it; build the filename FCB
;              (CCP_PARSE_FCB1) and reject a malformed filespec; resolve the drive prefix; delete
;              any pre-existing file of that name (F_DELETE_HND fn 19); create the file (F_MAKE fn 22)
;              and on failure branch to the NO-SPACE handler; clear the FCB current-record byte;
;              convert the page count to a 128-byte record count (count*2) and set the source
;              pointer to $0100; then enter the write loop.
; [RE] SAVE built-in; source data begins at the TPA base $0100. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
SAVE_CMD:
        ; parse the leading decimal page-count argument; A = number of 256-byte pages
        CALL PARSE_FCB_DECIMAL
        ; stash the page count across the FCB parse
        PUSH AF
        ; build the destination filename into the CCP command FCB (CCP_FCB) from the command tail
        CALL CCP_PARSE_FCB1
        ; malformed filespec: echo the bad command and abort
        JP NZ,CCP_ECHO_TOKEN
        CALL RESOLVE_DRIVE_PREFIX
        LD DE,CCP_FCB
        PUSH DE
        ; BDOS F_DELETE_HND (fn 19): remove any existing file with this name first
        CALL BDOS_F_DELETE
        POP DE
        ; BDOS F_MAKE (fn 22): create the new (empty) file
        CALL BDOS_F_MAKE
        ; no free directory entry: jump to the NO-SPACE error
        JP Z,SAVE_DISK_FULL
        XOR A
        ; clear the FCB current-record byte so writing starts at record 0
        LD (CCP_FCB_CR),A
        ; recover the saved page count
        POP AF
        LD L,A
        LD H,$00
        ; pages*2 = number of 128-byte records to write
        ADD HL,HL
        ; DE = source pointer, starting at the TPA base $0100
        LD DE,$0100
; ----------------------------------------------------------------------
; SAVE_WRITE_LOOP -- Write the remaining 128-byte records of a SAVE from successive memory slices.
;   In: HL = remaining record count; DE = current source/DMA address (starts $0100, advances by $80
;       per record); the CCP command FCB (CCP_FCB) is the open output file.
;   Out: writes each record sequentially; on a write failure (disk full) branches to NO-SPACE; falls
;        through to the close step when the count reaches zero.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: while HL != 0: decrement it; precompute the NEXT source pointer ($0080 + DE) and park
;              it on the stack; set the DMA to the CURRENT source DE via F_DMAOFF (fn 26); write the
;              record with F_WRITE (fn 21) from the FCB; POP the advanced pointer back into DE and
;              restore HL; on a nonzero write status jump to NO-SPACE; otherwise loop.
;   [RE] DE is the live DMA/source; the $0080 add forms the next record's source, recovered from the
;   stack after the write. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
SAVE_WRITE_LOOP:
        LD A,H
        ; test the 16-bit remaining-record count for zero
        OR L
        ; all records written: go close the file
        JP Z,SAVE_CLOSE
        ; consume one record from the remaining count
        DEC HL
        PUSH HL
        ; compute $0080 + DE = the NEXT record's source (parked on the stack); the DMA below uses
        ; the CURRENT DE
        LD HL,$0080
        ADD HL,DE
        PUSH HL
        ; BDOS F_DMAOFF (fn 26): point the DMA at the CURRENT 128-byte source slice (DE)
        CALL BDOS_F_DMAOFF
        LD DE,CCP_FCB
        ; BDOS F_WRITE (fn 21): append the record to the file
        CALL BDOS_F_WRITE
        POP DE
        POP HL
        ; write failed (disk full): jump to the NO-SPACE error
        JP NZ,SAVE_DISK_FULL
        ; continue writing the next record
        JP SAVE_WRITE_LOOP
; ----------------------------------------------------------------------
; SAVE_CLOSE -- Close the SAVE output file after all records are written.
;   In: the CCP command FCB (CCP_FCB) = the open output file (all records already written).
;   Out: closes the file; on success continues to the SAVE finish/cleanup path, on close failure
;        falls into the NO-SPACE error.
;   Clobbers: A, C, DE, flags.
;   Algorithm: point DE at the FCB, call F_CLOSE_HND (fn 16); the wrapper returns $FF+1=0 on failure, so
;              INC A here is already folded into the wrapper -- a nonzero result means success and
;              branches to the finish path; a zero (failure) result falls into the NO-SPACE handler.
; [RE] SAVE close step. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
SAVE_CLOSE:
        LD DE,CCP_FCB
        ; BDOS F_CLOSE_HND (fn 16): flush the directory entry for the saved file
        CALL BDOS_F_CLOSE
        ; map the $FF close-error code to 0 (failure); a valid directory code becomes nonzero =
        ; success
        INC A
        ; close succeeded: go to the SAVE finish/cleanup path
        JP NZ,SAVE_FINISH
; ----------------------------------------------------------------------
; SAVE_DISK_FULL -- SAVE error tail: report "NO SPACE" and clean up.
;   In: none (entered on F_MAKE failure, a failed F_WRITE, or a failed F_CLOSE_HND).
;   Out: prints the "NO SPACE" message, then falls into the SAVE finish/cleanup path.
;   Clobbers: A, BC, DE, HL, flags.
;   Algorithm: load BC with the address of MSG_NO_SPACE, print it (CR/LF + string via CCP_CRLF_MSG),
;              then fall through to SAVE_FINISH which restores the default DMA.
; [RE] Shared SAVE failure message. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
SAVE_DISK_FULL:
        ; address of the "NO SPACE" message string
        LD BC,MSG_NO_SPACE
        ; print CR/LF then the NUL-terminated message via C_WRITE
        CALL CCP_CRLF_MSG
; ----------------------------------------------------------------------
; SAVE_FINISH -- Restore the default DMA address and return to the CCP after a SAVE.
;   In: none.
;   Out: resets the BDOS DMA address to the default $0080 and jumps to the CCP command-complete
;        exit; does not return.
;   Clobbers: A, C, DE, flags.
;   Algorithm: call CCP_SET_DMA_TBUFF which loads DE=$0080 and invokes F_DMAOFF (fn 26) to restore
;              the default DMA (SAVE had walked the DMA across the TPA), then jump to the
;              command-complete exit.
; [RE] SAVE cleanup. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
SAVE_FINISH:
        ; restore the DMA to the default $0080 (SAVE had walked it across memory)
        CALL CCP_SET_DMA_TBUFF
        ; return to the CCP command-complete exit
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; MSG_NO_SPACE -- NUL-terminated console message "NO SPACE" shown when SAVE runs out of room.
;   In: referenced by BC in SAVE_DISK_FULL.
;   Out: data only (the ASCII string followed by a $00 terminator).
;   Clobbers: none.
;   Algorithm: data.
; [RE] CCP message string. [DOC CPMREF: CCP SAVE]
; ----------------------------------------------------------------------
MSG_NO_SPACE:
        DEFB    "NO SPACE"               ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; REN_CMD -- CCP built-in REN(AME): rename an existing file given "REN newname=oldname".
;   In: command line "REN newfile=oldfile"; the new name is parsed first into the CCP command FCB
;       (CCP_FCB).
;   Out: renames oldfile to newfile via F_RENAME_HND; errors are reported as "FILE EXISTS", "NO FILE",
;        or a bad-command echo.
;   Clobbers: A, B, DE, HL, flags.
;   Algorithm: parse the new-name FCB; reject a malformed spec; save the new name's drive prefix
;              (CCP_FCB_DRIVE_PREFIX); resolve the drive; search the directory for the new name and
;              if it already EXISTS branch to the FILE-EXISTS error; copy the 16-byte new-name FCB
;              to the second FCB slot at +16 (CCP_FCB_SECOND) so F_RENAME_HND later sees old@+0/new@+16;
;              advance the command-line pointer over blanks and require an '=' ($3D) or '_' ($5F)
;              separator (else bad-command error); then parse the old name.
; [RE] REN built-in; F_RENAME_HND FCB carries old name at +0, new name at +16. [DOC CPMREF: CCP REN]
; ----------------------------------------------------------------------
REN_CMD:
        ; build the NEW filename into the CCP command FCB (CCP_FCB) from the command line
        CALL CCP_PARSE_FCB1
        ; malformed new-name spec: echo bad command
        JP NZ,CCP_ECHO_TOKEN
        ; fetch the explicit drive prefix supplied with the new name
        LD A,(CCP_FCB_DRIVE_PREFIX)
        ; save the new name's drive prefix for the later drive-match check
        PUSH AF
        CALL RESOLVE_DRIVE_PREFIX
        ; BDOS F_SFIRST (fn 17): search the directory for the NEW name
        CALL CCP_SEARCH_FIRST_SUBMIT
        ; new name already exists: report FILE EXISTS
        JP NZ,REN_FILE_EXISTS
        LD HL,CCP_FCB
        LD DE,CCP_FCB_SECOND
        ; count = 16: copy the new-name FCB into the second FCB slot at +16 (CCP_FCB_SECOND), the
        ; rename source/target pair
        LD B,$10
        CALL COPY_N_BYTES
        LD HL,(CCP_PARSEPTR)
        EX DE,HL
        ; skip blanks to reach the '=' / '_' separator
        CALL CCP_SKIP_BLANKS
        ; '=' separator between new and old names
        CP $3D
        ; '=' seen: go parse the old name
        JP Z,REN_PARSE_OLD
        ; '_' is also accepted as the new=old separator
        CP $5F
        ; no valid separator: bad-command error
        JP NZ,REN_ERROR
; ----------------------------------------------------------------------
; REN_PARSE_OLD -- Parse the old-name FCB after the '=' separator and validate the drive match.
;   In: scan pointer is at the separator; the new-name drive prefix is on the stack (pushed by
;       REN_CMD).
;   Out: builds the old-name FCB and confirms both names target the same drive; on mismatch or parse
;        error branches to the bad-command error.
;   Clobbers: A, B, DE, HL, flags.
;   Algorithm: advance past the separator and update the scan pointer (CCP_PARSEPTR); parse the
;              old-name FCB; on parse error -> error tail. Recover the new name's drive prefix into
;              B; read the old name's prefix (CCP_FCB_DRIVE_PREFIX); if it is 0 (no explicit drive)
;              accept it; otherwise the two prefixes must be equal (store B into
;              CCP_FCB_DRIVE_PREFIX and compare) else error.
; [RE] REN old-name parse + same-drive enforcement. [DOC CPMREF: CCP REN]
; ----------------------------------------------------------------------
REN_PARSE_OLD:
        EX DE,HL
        ; step past the '=' / '_' separator
        INC HL
        LD (CCP_PARSEPTR),HL
        ; build the OLD filename FCB from the rest of the line
        CALL CCP_PARSE_FCB1
        ; drives differ: reject as a bad command
        ; malformed old-name spec: bad-command error
        JP NZ,REN_ERROR
        ; recover the new name's drive prefix saved by REN_CMD (into A, then B)
        POP AF
        LD B,A
        ; CCP_FCB_DRIVE_PREFIX = the old name's explicit drive prefix
        LD HL,CCP_FCB_DRIVE_PREFIX
        LD A,(HL)
        OR A
        ; old name has no explicit drive: accept and proceed
        JP Z,REN_DO_RENAME
        ; the two filenames must reference the same drive
        CP B
        LD (HL),B
        JP NZ,REN_ERROR
; ----------------------------------------------------------------------
; REN_DO_RENAME -- Locate the old file and perform the directory rename.
;   In: the CCP command FCB holds old name at +0 (CCP_FCB) and new name at +16 (CCP_FCB_SECOND); HL
;       -> the drive-prefix cell CCP_FCB_DRIVE_PREFIX; B = the agreed drive prefix.
;   Out: searches for the old name; if not found branches to NO-FILE; otherwise renames it and
;        returns to the CCP exit.
;   Clobbers: A, B, DE, HL, flags.
;   Algorithm: store the agreed prefix B into CCP_FCB_DRIVE_PREFIX; zero the FCB drive byte (CCP_FCB
;              = default drive); search-first for the old name (F_SFIRST fn 17) -- if absent jump to
;              REN_OLD_NOT_FOUND; else call F_RENAME_HND (fn 23) on the old/new FCB pair and finish.
; [RE] REN rename step. [DOC CPMREF: CCP REN]
; ----------------------------------------------------------------------
REN_DO_RENAME:
        ; store the agreed drive prefix B into the drive-prefix cell CCP_FCB_DRIVE_PREFIX (HL still
        ; points there)
        LD (HL),B
        XOR A
        ; zero the FCB drive byte (0 = default drive) before the search
        LD (CCP_FCB),A
        ; BDOS F_SFIRST (fn 17): search the directory for the OLD name
        CALL CCP_SEARCH_FIRST_SUBMIT
        ; old file not found: report NO FILE
        JP Z,REN_OLD_NOT_FOUND
        LD DE,CCP_FCB
        ; BDOS F_RENAME_HND (fn 23): rename old -> new using the paired FCB
        CALL BDOS_F_RENAME
        ; rename done: return to the CCP command-complete exit
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; REN_OLD_NOT_FOUND -- REN error: the source file to rename does not exist.
;   In: none.
;   Out: prints "NO FILE" and returns to the CCP command-complete exit.
;   Clobbers: A, BC, flags.
;   Algorithm: call the "NO FILE" message printer (PRINT_NO_FILE), then jump to the command-complete
;              exit.
; [RE] REN missing-source error. [DOC CPMREF: CCP REN]
; ----------------------------------------------------------------------
REN_OLD_NOT_FOUND:
        ; print the "NO FILE" message (rename source not found)
        CALL PRINT_NO_FILE
        ; return to the CCP command-complete exit
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; REN_ERROR -- REN bad-command tail: restore the drive and echo the offending command.
;   In: none (entered on a missing/invalid separator, an old-name parse error, or a drive mismatch).
;   Out: restores the default drive and jumps to the bad-command echo path; does not return.
;   Clobbers: A, HL, flags.
;   Algorithm: call CCP_RESTORE_DEFAULT_DRIVE to restore the user's drive, then jump to
;              CCP_ECHO_TOKEN which re-emits the command word with a '?'.
; [RE] Shared REN syntax-error exit. [DOC CPMREF: CCP REN]
; ----------------------------------------------------------------------
REN_ERROR:
        ; restore the user's original/default drive selection
        CALL CCP_RESTORE_DEFAULT_DRIVE
        ; echo the malformed command token with a '?' and re-prompt
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; REN_FILE_EXISTS -- REN error: the requested new name already exists on disk.
;   In: none.
;   Out: prints "FILE EXISTS" and returns to the CCP command-complete exit.
;   Clobbers: A, BC, flags.
;   Algorithm: load BC with the "FILE EXISTS" message address, print it (CR/LF + string via
;              CCP_CRLF_MSG), then jump to the command-complete exit.
; [RE] REN destination-collision error; new name found by the earlier F_SFIRST. [DOC CPMREF: CCP
; REN]
; ----------------------------------------------------------------------
REN_FILE_EXISTS:
        ; address of the "FILE EXISTS" message string
        LD BC,CCP_MSG_FILE_EXISTS
        ; print CR/LF then the NUL-terminated message
        CALL CCP_CRLF_MSG
        ; return to the CCP command-complete exit
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; CCP_MSG_FILE_EXISTS -- ASCIIZ console message "FILE EXISTS".
;   In: -- (data, addressed by REN_FILE_EXISTS in BC as the error text)
;   Out: -- (zero-terminated string)
;   Clobbers: --
;   Algorithm: 11 bytes "FILE EXISTS" followed by a $00 terminator; loaded into BC
;     by REN_FILE_EXISTS and printed by CCP_CRLF_MSG when the REN built-in finds the new
;     name already on disk.
;   [RE] string literal observed in the CCP image (OBSERVED bytes).
; ----------------------------------------------------------------------
CCP_MSG_FILE_EXISTS:
        DEFB    "FILE EXISTS"            ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CCP_CMD_USER -- built-in USER command: select the user-number area (0..15).
;   In: command FCB at CCP_FCB; the numeric argument sits in the FCB name field.
;   Out: BDOS user number set to the parsed value; joins CCP_RETURN_OK_NOCRLF.
;   Clobbers: A, E, and the BDOS-call registers.
;   Algorithm: dispatch table entry 5 (keyword "USER"). PARSE_FCB_DECIMAL parses a decimal
;     number from the command FCB into A; if it is $10 (16) or more it is out of the
;     0..15 user range, so abort to CCP_ECHO_TOKEN. Move the value to E, then call
;     BDOS_USERNUM (BDOS function 32, Set/Get User Number, C=$20) to set the user area.
;     The CP $20 test on the FCB name byte rejects a missing argument. Join the
;     no-CR/LF return tail CCP_RETURN_OK_NOCRLF.
;   [RE] standard CP/M 2.2 CCP USER built-in; identity from keyword table
;     "DIR ERA TYPESAVEREN USER" index 5 -> dispatch entry CCP_CMD_USER.
; ----------------------------------------------------------------------
CCP_CMD_USER:
        ; parse the decimal user number from the command FCB name field into A
        CALL PARSE_FCB_DECIMAL
        ; user numbers are 0..15; reject $10 (16) or more as out of range
        CP $10
        ; number too large: echo the bad token and abort
        JP NC,CCP_ECHO_TOKEN
        ; E = user number, the argument for the Set-User BDOS call
        LD E,A
        ; fetch first byte of the FCB name field
        LD A,(CCP_FCB_NAME)
        ; a blank here means no argument was supplied, reject
        CP $20
        ; no argument: abort to the bad-command echo
        JP Z,CCP_ECHO_TOKEN
        ; BDOS function 32 (C=$20): set the user number to E
        CALL BDOS_USERNUM
        ; join the return tail that does not emit a leading CR/LF
        JP CCP_RETURN_OK_NOCRLF
; ----------------------------------------------------------------------
; CCP_DRIVE_SELECT -- handle a drive-prefixed command word: bare "d:" (change
;   default drive) or "d:NAME" (drive-prefixed transient).
;   In: command FCB; CCP_FCB_DRIVE_PREFIX (CCP_FCB_DRIVE_PREFIX) non-zero (a "d:" was typed).
;   Out: if no command word followed the prefix, the default drive is changed and
;     control joins CCP_RETURN_OK_NOCRLF; if a name followed, control falls to the
;     transient loader CCP_CMD_TRANSIENT.
;   Clobbers: A, and the BDOS-call registers.
;   Algorithm: reached from CCP_PARSE_AND_DISPATCH when CCP_FCB_DRIVE_PREFIX != 0 (it is NOT in
;     the keyword dispatch table). First CCP_CHECK_SERIAL verifies the CCP and BDOS serial
;     numbers still match (integrity check). If the FCB name field is non-blank a
;     command word follows the drive letter -> jump to CCP_CMD_TRANSIENT (transient load).
;     Otherwise (bare "d:") if the drive-prefix flag is zero there is nothing to do
;     (return OK); else DEC it to a 0-based drive number, store it as the current
;     drive (CCP_CUR_DRIVE), write it to page zero (CCP_SET_DRIVE_ONLY) and issue BDOS
;     Select-Disk (BDOS_DRV_SET), then return OK.
;   [RE] CP/M 2.2 CCP default-drive change / drive-prefix entry. NOT the keyword
;     USER built-in (that is CCP_CMD_USER); this is dispatch slot 6, reachable only
;     via the drive-prefix branch.
; ----------------------------------------------------------------------
CCP_DRIVE_SELECT:
        ; verify the CCP and BDOS serial numbers still match (integrity check)
        CALL CCP_CHECK_SERIAL
        ; first byte of the FCB name field
        LD A,(CCP_FCB_NAME)
        ; blank name = bare "d:" with no command word after the drive letter
        CP $20
        ; a name follows the drive prefix: treat as a transient program load
        JP NZ,CCP_CMD_TRANSIENT
        ; load the explicit drive-prefix flag (0 = none, else drive#+1)
        LD A,(CCP_FCB_DRIVE_PREFIX)
        ; was a drive actually supplied?
        OR A
        ; no drive value: nothing to change, finish via the OK tail
        JP Z,CCP_RETURN_OK_NOCRLF
        ; convert the 1-based prefix to a 0-based drive number
        DEC A
        ; commit it as the CCP current default drive
        LD (CCP_CUR_DRIVE),A
        ; write the current drive to page-zero default-drive byte $0004
        CALL CCP_SET_DRIVE_ONLY
        ; issue BDOS Select-Disk (function 14) for the new drive
        CALL BDOS_DRV_SET
        ; finish via the OK return tail (no leading CR/LF)
        JP CCP_RETURN_OK_NOCRLF
; ----------------------------------------------------------------------
; CCP_CMD_TRANSIENT -- load and run a transient (.COM) program from disk.
;   In: parsed command FCB (CCP_FCB) holding the command name; command tail.
;   Out: on success transfers control to the loaded program at the TPA ($0100); on
;     error joins CCP_BAD_LOAD / CCP_NO_FILE; never returns normally.
;   Clobbers: all registers; rebuilds the TPA and page-zero command tail.
;   Algorithm: verify the FCB extension is blank (no explicit type) -- if not, the
;     command is rejected (CCP_ECHO_TOKEN). Select the command's drive prefix, force
;     the extension to "COM" (CCP_COM_EXT), open the file; if not found jump to the
;     no-file handler. Then loop reading $80-byte records sequentially into the TPA
;     starting at $0100, advancing $80 bytes each record, until either the load
;     address would reach the CCP base ($9400 = CCP_ENTRY, abort = BAD LOAD) or EOF.
;     On clean EOF, build the page-zero command tail and JP $0100 (done in the
;     routines that follow).
;   [RE] CP/M 2.2 CCP transient program loader.
; ----------------------------------------------------------------------
CCP_CMD_TRANSIENT:
        ; point at the FCB extension (type) field
        LD DE,CCP_FCB_EXT
        ; fetch first byte of the file extension
        LD A,(DE)
        ; extension must be blank: a typed extension is not a bare command
        CP $20
        ; explicit extension given: not a transient command, echo+abort
        JP NZ,CCP_ECHO_TOKEN
        PUSH DE
        ; select the drive named by the command's drive prefix
        CALL RESOLVE_DRIVE_PREFIX
        POP DE
        ; source = the constant "COM" extension text
        LD HL,CCP_COM_EXT
        ; force the FCB type field to COM
        CALL COPY_3_BYTES
        ; open the .COM file via BDOS
        CALL CCP_OPEN_SUBMIT
        ; open failed (file not found): go to the no-file handler
        JP Z,CCP_NO_FILE
        ; load address starts at the base of the TPA
        LD HL,$0100
; ----------------------------------------------------------------------
; CCP_LOAD_LOOP -- read the .COM file record-by-record into the TPA.
;   In: HL = next TPA load address; FCB already open at CCP_FCB.
;   Out: loops until EOF (-> CCP_LOAD_DONE) or until the load pointer reaches the
;     CCP base (-> CCP_BAD_LOAD).
;   Clobbers: A, DE, HL.
;   Algorithm: push the load address, set the BDOS DMA to it (BDOS_F_DMAOFF), do a
;     sequential read (BDOS_F_READ) of one $80-byte record; on a non-zero (EOF/error)
;     read result branch to CCP_LOAD_DONE. Otherwise advance HL by $80 and compare
;     it against CCP_ENTRY ($9400 = CCP base) via a 16-bit subtract: if HL >= base the
;     program is too big -> CCP_BAD_LOAD; else loop for the next record.
;   [RE] transient-load inner loop.
; ----------------------------------------------------------------------
CCP_LOAD_LOOP:
        ; save the current TPA load pointer across the read
        PUSH HL
        EX DE,HL
        ; set the BDOS DMA address (function 26) to the load pointer
        CALL BDOS_F_DMAOFF
        ; DE = the open command FCB
        LD DE,CCP_FCB
        ; BDOS sequential read (function 20) of one 128-byte record
        CALL BDOS_F_READ
        ; non-zero = EOF or read error: finish the load
        JP NZ,CCP_LOAD_DONE
        POP HL
        ; record size = 128 bytes
        LD DE,$0080
        ; advance the load pointer to the next record slot
        ADD HL,DE
        ; compare against the CCP base -- the ceiling the program must not reach
        LD DE,CCP_ENTRY
        LD A,L
        SUB E
        LD A,H
        SBC A,D
        ; load reached the CCP: program too large -> BAD LOAD
        JP NC,CCP_BAD_LOAD
        JP CCP_LOAD_LOOP
; ----------------------------------------------------------------------
; CCP_LOAD_DONE -- finish a transient load and launch the program.
;   In: the BDOS read returned non-zero (A); stacked TPA load pointer on entry.
;   Out: if the read result was true EOF (A becomes 0 after DEC) builds page zero
;     and proceeds to the launch; otherwise -> CCP_BAD_LOAD.
;   Clobbers: all registers.
;   Algorithm: pop the saved load pointer; DEC A -- a sequential-read return of 1
;     means clean EOF (now 0); anything else is an error (-> CCP_BAD_LOAD). Reselect
;     the command's drive (CCP_RESTORE_DEFAULT_DRIVE), rebuild the command FCB (CCP_PARSE_FCB1),
;     then build a second FCB from the command tail at offset $10 into CCP_FCB
;     (CCP_BUILD_FCB with A=$10) so the program gets two default FCBs. Zero the FCB CR
;     field, copy a $21-byte FCB image down to TFCB ($005C), then fall through to the
;     tail-copy routines that build the command tail at TBUFF and launch.
;   [RE] transient launch / page-zero setup, standard CP/M 2.2 CCP.
; ----------------------------------------------------------------------
CCP_LOAD_DONE:
        ; discard the saved load pointer
        POP HL
        ; sequential-read return 1 = clean EOF -> 0; any other value is a load error
        DEC A
        ; non-EOF read result: report BAD LOAD
        JP NZ,CCP_BAD_LOAD
        ; reselect the drive named by the command prefix
        CALL CCP_RESTORE_DEFAULT_DRIVE
        CALL CCP_PARSE_FCB1
        ; point at the drive-prefix flag (saved across the FCB rebuild)
        LD HL,CCP_FCB_DRIVE_PREFIX
        PUSH HL
        LD A,(HL)
        ; seed the command FCB drive byte before the second-FCB parse
        LD (CCP_FCB),A
        ; offset $10 = build the second filename into FCB+16
        LD A,$10
        ; parse a second command-tail filename into the alternate FCB
        CALL CCP_BUILD_FCB
        POP HL
        LD A,(HL)
        ; store the second-FCB drive prefix byte
        LD (CCP_FCB_SECOND),A
        ; zero the FCB current-record field before launch
        XOR A
        ; clear the command FCB CR byte
        LD (CCP_FCB_CR),A
        ; destination = the default FCB at page zero TFCB ($005C)
        LD DE,$005C
        ; source = the CCP-built command FCB
        LD HL,CCP_FCB
        ; copy $21 (33) bytes = one full FCB image
        LD B,$21
        ; copy the FCB image down to TFCB
        CALL COPY_N_BYTES
        ; source for the tail = the CCP command-line buffer
        LD HL,CCP_CMDTEXT
; ----------------------------------------------------------------------
; CCP_TAIL_SKIP_NAME -- scan past the program name to the start of the tail.
;   In: HL = pointer into the CCP command-line buffer (CCP_CMDTEXT).
;   Out: HL points at the first blank or the NUL terminator following the command
;     word; falls through to CCP_TAIL_COPY.
;   Clobbers: A, HL.
;   Algorithm: walk forward over name characters until a $00 (end of line) or a $20
;     (blank, start of the argument tail) is found.
;   [RE] command-tail scanner.
; ----------------------------------------------------------------------
CCP_TAIL_SKIP_NAME:
        ; fetch the next command-line character
        LD A,(HL)
        ; end of line?
        OR A
        ; no tail: jump to copy an empty tail
        JP Z,CCP_TAIL_COPY
        ; blank separates the command word from its tail
        CP $20
        ; found the blank: HL now at the tail, go copy it
        JP Z,CCP_TAIL_COPY
        ; advance past this name character
        INC HL
        JP CCP_TAIL_SKIP_NAME
; ----------------------------------------------------------------------
; CCP_TAIL_COPY -- begin copying the command tail to TBUFF and counting its length.
;   In: HL = first character of the command tail (blank or NUL).
;   Out: sets DE = $0081 (TBUFF+1) and B = 0 (length), then falls into the copy
;     loop CCP_TAIL_COPY_LOOP.
;   Clobbers: B, DE.
;   Algorithm: initialize the length accumulator B to 0 and the destination pointer
;     DE to TBUFF+1 ($0081); $0080 (TBUFF) will hold the final length byte.
;   [RE] page-zero command-tail builder setup, standard CP/M 2.2 CCP.
; ----------------------------------------------------------------------
CCP_TAIL_COPY:
        ; tail length accumulator starts at 0
        LD B,$00
        ; destination = TBUFF+1 ($0080 holds the length byte)
        LD DE,$0081
; ----------------------------------------------------------------------
; CCP_TAIL_COPY_LOOP -- per-character copy loop of the command tail.
;   In: HL = source char, DE = TBUFF dest, B = running length.
;   Out: on the NUL terminator branches to CCP_TAIL_SETLEN with B = length.
;   Clobbers: A, B, DE, HL.
;   Algorithm: load (HL), store to (DE); if it was $00 the tail is done; else bump
;     the length B and advance both pointers and loop.
;   [RE] inner copy loop of CCP_TAIL_COPY.
; ----------------------------------------------------------------------
CCP_TAIL_COPY_LOOP:
        ; next tail character
        LD A,(HL)
        ; store into the TBUFF command-tail buffer
        LD (DE),A
        ; NUL terminator ends the tail
        OR A
        ; tail done: go store the final length
        JP Z,CCP_TAIL_SETLEN
        ; count this character
        INC B
        INC HL
        INC DE
        JP CCP_TAIL_COPY_LOOP
; ----------------------------------------------------------------------
; CCP_TAIL_SETLEN -- finalize page zero and launch the transient at $0100.
;   In: B = command-tail length; FCBs and TBUFF text already built.
;   Out: stores the tail length at TBUFF ($0080), sets the default DMA, and CALLs
;     the program at $0100; on its return rejoins the CCP loop.
;   Clobbers: all registers.
;   Algorithm: store B at $0080 (TBUFF length byte); emit the pending CR/LF
;     (CCP_CRLF); reset the default DMA to $0080 (CCP_SET_DMA_TBUFF); rebuild the page-zero
;     default drive/user byte at $0004 (CCP_SET_USERDRIVE); CALL $0100 to run the program.
;     After it returns, restore the CCP private stack (SP = CCP_SUBMIT_FLAG), restore the
;     current drive (CCP_SET_DRIVE_ONLY) and reselect it (BDOS_DRV_SET), then JP to the CCP
;     warm-restart point CCP_PROMPT_AND_READ.
;   [RE] transient launch finalizer, standard CP/M 2.2 CCP.
; ----------------------------------------------------------------------
CCP_TAIL_SETLEN:
        ; tail character count
        LD A,B
        ; store as the TBUFF length byte ($0080 = TBUFF)
        LD ($0080),A
        ; emit the pending CR/LF before running the program
        CALL CCP_CRLF
        ; reset the BDOS DMA address to the default ($0080)
        CALL CCP_SET_DMA_TBUFF
        ; rebuild the page-zero default drive/user byte at $0004
        CALL CCP_SET_USERDRIVE
        ; run the loaded transient program in the TPA
        CALL $0100
        ; restore the CCP private stack after the program returns
        LD SP,CCP_SUBMIT_FLAG
        ; restore the current drive in page zero
        CALL CCP_SET_DRIVE_ONLY
        ; reselect the current drive via BDOS
        CALL BDOS_DRV_SET
        ; rejoin the CCP command loop (warm restart)
        JP CCP_PROMPT_AND_READ
; ----------------------------------------------------------------------
; CCP_NO_FILE -- handle a transient whose .COM file was not found.
;   In: -- (entered when BDOS open returned not-found in CCP_CMD_TRANSIENT).
;   Out: reselects the drive then echoes the offending token and aborts; does not
;     return.
;   Clobbers: A, and the echo/BDOS registers.
;   Algorithm: reselect the command's drive prefix (CCP_RESTORE_DEFAULT_DRIVE), then jump
;     to CCP_ECHO_TOKEN which prints the command word with a trailing '?' and warm-
;     restarts the CCP.
;   [RE] file-not-found path of the transient loader.
; ----------------------------------------------------------------------
CCP_NO_FILE:
        ; reselect the drive the command named
        CALL CCP_RESTORE_DEFAULT_DRIVE
        ; echo the bad command name with '?' and restart
        JP CCP_ECHO_TOKEN
; ----------------------------------------------------------------------
; CCP_BAD_LOAD -- report a transient that would not fit / had a read error.
;   In: -- (entered on TPA overflow or a non-EOF read error).
;   Out: prints "BAD LOAD" then joins the return tail CCP_RETURN_OK; does not return.
;   Clobbers: BC and the print/BDOS registers.
;   Algorithm: load BC with the CCP_MSG_BAD_LOAD ("BAD LOAD") text and call CCP_CRLF_MSG (CR/LF +
;     message printer), then JP to the drive-restore return tail CCP_RETURN_OK.
;   [RE] over-size / read-error path of the transient loader.
; ----------------------------------------------------------------------
CCP_BAD_LOAD:
        ; point at the "BAD LOAD" message text
        LD BC,CCP_MSG_BAD_LOAD
        ; print CR/LF + the message
        CALL CCP_CRLF_MSG
        ; join the drive-restore return tail
        JP CCP_RETURN_OK
; ----------------------------------------------------------------------
; CCP_MSG_BAD_LOAD -- ASCIIZ console message "BAD LOAD".
;   In: -- (data, addressed by CCP_BAD_LOAD as the message in BC)
;   Out: -- (zero-terminated string)
;   Clobbers: --
;   Algorithm: 8 bytes "BAD LOAD" followed by a $00 terminator.
;   [RE] string literal observed in the CCP image (OBSERVED bytes).
; ----------------------------------------------------------------------
CCP_MSG_BAD_LOAD:
        DEFB    "BAD LOAD"               ; string
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CCP_COM_EXT -- the constant file-extension text "COM" for transient loads.
;   In: -- (data, source for COPY_3_BYTES in CCP_CMD_TRANSIENT)
;   Out: -- (3 bytes, no terminator)
;   Clobbers: --
;   Algorithm: the three ASCII bytes "COM" copied into the FCB type field so the
;     CCP opens the command word as NAME.COM.
;   [RE] CP/M 2.2 CCP default transient extension.
; ----------------------------------------------------------------------
CCP_COM_EXT:
        DEFB    "COM"
; ----------------------------------------------------------------------
; CCP_RETURN_OK -- normal CCP return tail: restore the drive then check for leftover.
;   In: -- (joined after a built-in or error completes).
;   Out: reselects the command's drive prefix, then falls into CCP_RETURN_OK_NOCRLF.
;   Clobbers: A, HL, and BDOS registers.
;   Algorithm: call CCP_RESTORE_DEFAULT_DRIVE to reselect the drive named by the
;     command, then fall through to CCP_RETURN_OK_NOCRLF (CCP_RETURN_OK_NOCRLF).
;   [RE] CCP command epilogue.
; ----------------------------------------------------------------------
CCP_RETURN_OK:
        ; reselect the drive named in the command prefix
        CALL CCP_RESTORE_DEFAULT_DRIVE
; ----------------------------------------------------------------------
; CCP_RETURN_OK_NOCRLF -- verify the whole command was consumed, then restart CCP.
;   In: command FCB name first byte (CCP_FCB_NAME); drive-prefix flag (CCP_FCB_DRIVE_PREFIX).
;   Out: if there is unparsed trailing text it is echoed as a bad command; otherwise
;     the CCP warm-restarts. Does not return to the caller.
;   Clobbers: A, HL, and the print/BDOS registers.
;   Algorithm: rebuild the command FCB once more (CCP_PARSE_FCB1), then test whether the
;     FCB name field was blank ($20) AND no drive prefix remained: SUB the blank from
;     the name byte, OR with the drive-prefix flag -- if the result is non-zero there
;     is leftover input, so echo the bad token (CCP_ECHO_TOKEN); else JP to the CCP
;     warm restart (CCP_PROMPT_AND_READ).
;   [RE] CCP command epilogue (no leading CR/LF).
; ----------------------------------------------------------------------
CCP_RETURN_OK_NOCRLF:
        ; re-parse the command FCB to test for leftover text
        CALL CCP_PARSE_FCB1
        ; first FCB name byte
        LD A,(CCP_FCB_NAME)
        ; subtract a blank: zero means the name field was empty
        SUB $20
        ; point at the drive-prefix flag
        LD HL,CCP_FCB_DRIVE_PREFIX
        ; combine: nonzero if either a name or a drive prefix is left over
        OR (HL)
        ; leftover token: echo it as a bad command
        JP NZ,CCP_ECHO_TOKEN
        ; command fully consumed: warm-restart the CCP
        JP CCP_PROMPT_AND_READ
        DEFS    16, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_SUBMIT_FLAG -- SUBMIT/batch-active flag; also the base of the CCP stack.
;   In/Out: a single byte. Non-zero while the CCP is feeding commands from a
;     $$$.SUB batch file; the CCP private stack is loaded with SP = this address
;     (LD SP,CCP_SUBMIT_FLAG) at every warm start and after a transient returns.
;   Clobbers: --
;   Algorithm: set non-zero when a $$$.SUB batch line is delivered (CCP_GETCMD
;     region), cleared by CCP_DISCARD_SUBMIT when batch input ends; doubles as the CCP stack
;     top.
;   [RE] CP/M 2.2 CCP batch flag / stack base.
; ----------------------------------------------------------------------
CCP_SUBMIT_FLAG:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB -- the FCB for the $$$.SUB batch (SUBMIT) file.
;   In/Out: 33-byte FCB; drive byte at this address, name/ext set to "$$$    SUB".
;   Clobbers: --
;   Algorithm: opened/read/deleted by the CCP batch logic (CCP_GETCMD / CCP_DISCARD_SUBMIT) to
;     source successive command lines from the $$$.SUB file; its name/extension
;     constant follows here.
;   [RE] CP/M 2.2 CCP SUBMIT FCB.
; ----------------------------------------------------------------------
CCP_SUB_FCB:
        DEFB    "\0"
        DEFB    "$$$     SUB"            ; string
        DEFB    $00                      ; terminator
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB_S2 -- the S2 (extent-high) field of the $$$.SUB FCB.
;   In/Out: 1 byte at CCP_SUB_FCB+$0E; cleared to 0 before reading the next batch
;     record (CCP_GETCMD writes CCP_SUB_FCB_S2 = 0 then DECs the CR field below it).
;   Clobbers: --
;   Algorithm: part of CCP_SUB_FCB; written 0 so the extent is reset before the
;     reverse read positions the CR field.
;   [RE] FCB S2 byte of the SUBMIT FCB.
; ----------------------------------------------------------------------
CCP_SUB_FCB_S2:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_SUB_FCB_CR -- the current-record (CR) field of the $$$.SUB FCB.
;   In/Out: 1 byte at CCP_SUB_FCB+$0F; holds the next batch record to read.
;   Clobbers: --
;   Algorithm: read by CCP_GETCMD, decremented, and stored as the new record index in
;     CCP_SUB_PREV_REC (the SUBMIT file is consumed in reverse).
;   [RE] FCB CR byte of the SUBMIT FCB.
; ----------------------------------------------------------------------
CCP_SUB_FCB_CR:
        DEFS    17, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_SUB_PREV_REC -- previous batch record index (cell just below the command FCB).
;   In/Out: 1 byte immediately below CCP_FCB; receives CCP_SUB_FCB_CR-1, the record
;     to read next from the $$$.SUB file (CCP_GETCMD: DEC A / LD (CCP_SUB_PREV_REC),A).
;   Clobbers: --
;   Algorithm: SUBMIT reads records back-to-front; this cell carries the decremented
;     record number used to position the next read.
;   [RE] SUBMIT reverse-read record holder.
; ----------------------------------------------------------------------
CCP_SUB_PREV_REC:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB -- the command-line FCB the CCP builds from the typed command.
;   In/Out: 33-byte FCB; this byte is the drive field, the 8-char name follows at
;     CCP_FCB_NAME, the 3-char type at CCP_FCB_EXT. Copied to TFCB ($005C) before a
;     transient runs.
;   Clobbers: --
;   Algorithm: filled by CCP_BUILD_FCB from the command tail; the built-in search
;     (SEARCH_BUILTIN) compares its name field against the keyword table and the transient
;     loader opens it as NAME.COM.
;   [RE] CP/M 2.2 CCP command FCB.
; ----------------------------------------------------------------------
CCP_FCB:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB_NAME -- the 8-character filename field of the command FCB.
;   In/Out: 8 bytes at CCP_FCB+1; the parsed command word (blank-padded).
;   Clobbers: --
;   Algorithm: matched 4 chars at a time against the keyword table
;     "DIR ERA TYPESAVEREN USER" (SEARCH_BUILTIN) and used as the .COM filename for
;     transient loads; a leading blank means no command word was given.
;   [RE] FCB name field.
; ----------------------------------------------------------------------
CCP_FCB_NAME:
        DEFS    8, $00                   ; fill
; ----------------------------------------------------------------------
; CCP_FCB_EXT -- the 3-character extension (type) field of the command FCB.
;   In/Out: 3 bytes at CCP_FCB+9.
;   Clobbers: --
;   Algorithm: must be blank for a bare command word; the transient loader overwrites
;     it with "COM" before opening the file.
;   [RE] FCB type field.
; ----------------------------------------------------------------------
CCP_FCB_EXT:
        DEFB    "\0\0\0\0\0\0\0"
; ----------------------------------------------------------------------
; CCP_FCB_SECOND -- the second filename built into the command FCB at offset $10.
;   In/Out: starts at CCP_FCB+$10; a second command-tail filename is parsed here so
;     the transient receives two default FCBs (at $005C and $006C after the copy).
;   Clobbers: --
;   Algorithm: CCP_BUILD_FCB called with A=$10 fills this; its drive prefix byte is
;     stored here, and the $21-byte copy to TFCB carries both FCB images to page zero.
;   [RE] CP/M 2.2 CCP second default FCB.
; ----------------------------------------------------------------------
CCP_FCB_SECOND:
        DEFS    16, $00                  ; fill
; ----------------------------------------------------------------------
; CCP_FCB_CR -- the current-record (CR) field of the command FCB.
;   In/Out: 1 byte at CCP_FCB+$20; zeroed before each open/read so loads start at
;     record 0.
;   Clobbers: --
;   Algorithm: cleared by the open helper (CCP_OPEN_SUBMIT) and before launching a transient.
;   [RE] FCB CR byte of the command FCB.
; ----------------------------------------------------------------------
CCP_FCB_CR:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_BDOS_RESULT -- saved A return code from the most recent BDOS file call.
;   In/Out: 1 byte; written with the BDOS return value by the file-call wrapper
;     BDOS_FCB_OP (open/close/search/delete) right after CALL $0005.
;   Clobbers: --
;   Algorithm: the wrapper saves A here, then INC A so the caller can test for the
;     $FF (not-found) directory code as zero.
;   [RE] CCP scratch for the last BDOS directory-code.
; ----------------------------------------------------------------------
CCP_BDOS_RESULT:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_CUR_DRIVE -- the CCP's current default drive number (0=A, 1=B, ...).
;   In/Out: 1 byte; the active drive the CCP selects and writes to the low nibble of
;     page-zero $0004.
;   Clobbers: --
;   Algorithm: set from the BDOS current-disk value at warm start (low nibble of the
;     boot C register) and updated by the drive-select path (CCP_DRIVE_SELECT). CCP_SET_DRIVE_ONLY
;     writes it straight to $0004; CCP_SET_USERDRIVE merges it with the user number (in the
;     high nibble) and stores the combined byte at $0004. Reselected after every
;     transient runs. NOTE: this is the DRIVE, not the user number (the user number
;     lives in the BDOS, set via function 32).
;   [RE] CP/M 2.2 CCP current default-drive byte.
; ----------------------------------------------------------------------
CCP_CUR_DRIVE:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB_DRIVE_PREFIX -- explicit drive-prefix flag for the parsed command.
;   In/Out: 1 byte; 0 means no "d:" prefix was typed, otherwise drive#+1 (A=1,B=2,..).
;   Clobbers: --
;   Algorithm: set by CCP_BUILD_FCB when it sees a "d:" before the name; used to select
;     the right drive for the command and to decide leftover-token handling. A
;     non-zero value also routes the dispatcher to CCP_DRIVE_SELECT (drive-select path).
;   [RE] CP/M 2.2 CCP command drive-prefix flag.
; ----------------------------------------------------------------------
CCP_FCB_DRIVE_PREFIX:
        DEFB    "\0"
; ----------------------------------------------------------------------
; CCP_FCB_TAIL -- trailing bytes of the command FCB record / data page.
;   In/Out: 15 bytes following the drive-prefix flag, completing the FCB-sized
;     record region the CCP keeps in its data page.
;   Clobbers: --
;   Algorithm: reserved scratch / FCB-tail bytes; no code in this cluster reads them
;     meaningfully. Exact use beyond padding the FCB record is UNKNOWN.
;   [?] purpose beyond reserved FCB-tail padding is UNKNOWN.
; ----------------------------------------------------------------------
CCP_FCB_TAIL:
        DEFS    15, $00                  ; fill
; ----------------------------------------------------------------------
; BDOS_FBASE -- BDOS image header at FBASE ($9C00): 6 serial/header bytes, then the FDOS
; entry jump.
;   In: none (static image bytes at the BDOS run base).
;   Out: bytes +0..+5 are the per-copy serial/header cells (not code); the JP at +6 (BDOS_ENTRY) is
;        the actual entry.
;   Clobbers: n/a (data + one jump).
;   Algorithm: OBSERVED -- the six bytes here are DEFB $BD,$16,$00,$00,$16,$DF, the standard CP/M
;              FBASE serial-number / header cells. The disassembler renders them as spurious
;              SBC/AND/XOR/OR instructions further on, but these +0..+5 bytes are DATA. The byte at
;              +6 is the JP BDOS_ENTRY/dispatcher that the page-zero BDOS=$0005 jump-vector lands
;              on. [RE] standard CP/M 2.2 FBASE header layout.
; ----------------------------------------------------------------------
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9400, $0800
    ENDIF
