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
        JP CCP_COLD_ENTRY                    ; $9300  C3 0C 96
        DEFB    $C3,$08,$96                                      ; $9303
; ----------------------------------------------------------------------
; CCP_INBUF -- console line-input buffer descriptor for C_READSTR.
;   Layout: byte0 ($9306)=max length ($7F=127), byte1 ($9307)=returned count,
;     bytes2.. ($9308)=the typed command line (also the CCP work text area).
;   [RE] Standard CP/M 2.2 CCP command buffer.
; ----------------------------------------------------------------------
CCP_INBUF:
        ; max input length = 127 ($7F)
        DEFB    $7F                                              ; $9306
; ----------------------------------------------------------------------
; CCP_INLEN -- count of characters returned by the last C_READSTR (buffer fill).
;   Also doubles as the auto-command flag: nonzero on entry means a command string
;   is already staged in CCP_CMDTEXT and is re-parsed instead of re-prompting.
;   [RE]
; ----------------------------------------------------------------------
CCP_INLEN:
        DEFB    "\0"    ; $9307
; ----------------------------------------------------------------------
; CCP_CMDTEXT -- the command-line text area (CCP_INBUF+2).
;   Holds the upper-cased command line being parsed. On cold start it carries
;   16 spaces, the DRI string 'COPYRIGHT (C) 1979, DIGITAL RESEARCH  ', a NUL, then
;   73 zero pad bytes -- this fixed init doubles as the CCP scratch/line area.
;   [RE]
; ----------------------------------------------------------------------
CCP_CMDTEXT:
        DEFS    16, $20    ; $9308  fill
        ; DRI copyright banner; also the cold-start command-line scratch fill
        DEFB    "COPYRIGHT (C) 1979, DIGITAL RESEARCH  "    ; $9318  string
        DEFB    $00    ; $933E  terminator
        DEFS    73, $00    ; $933F  fill
; ----------------------------------------------------------------------
; CCP_PARSEPTR -- 16-bit scan pointer into CCP_CMDTEXT used during command parse.
;   Initialized to CCP_CMDTEXT ($9308); advanced as tokens are consumed.
;   [RE]
; ----------------------------------------------------------------------
CCP_PARSEPTR:
        ; init = CCP_CMDTEXT ($9308) little-endian
        DEFB    $08,$93                                          ; $9388
; ----------------------------------------------------------------------
; CCP_TOKENPTR -- 16-bit pointer to the start of the current token.
;   Saved by the FCB builder and reused by the bad-character echo routine.
;   [RE]
; ----------------------------------------------------------------------
CCP_TOKENPTR:
        DEFB    "\0\0"    ; $938A
; ----------------------------------------------------------------------
; CCP_CONOUT -- write one character to the console via BDOS C_WRITE.
;   In: A = character to emit.
;   Out: none (BDOS return ignored).
;   Clobbers: C, E; BDOS clobbers per ABI.
;   Algorithm: E:=A; C:=C_WRITE(2); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
CCP_CONOUT:
        LD E,A                           ; $938C  5F
        ; C_WRITE = 2
        LD C,$02                         ; $938D  0E 02
        JR BDOS_JP_TAIL                    ; $938F  18 28
; ----------------------------------------------------------------------
; CCP_SPACE -- emit a single blank to the console.
;   In: none.  Out: BC preserved.  Clobbers: A/flags.
;   Algorithm: A:=' ' ($20); fall into CCP_CONOUT_KEEPBC.
;   [RE]
; ----------------------------------------------------------------------
CCP_SPACE:
        ; space character
        LD A,$20                         ; $9391  3E 20
; ----------------------------------------------------------------------
; CCP_CONOUT_KEEPBC -- print one char (CCP_CONOUT) preserving BC.
;   In: A = character.  Out: BC unchanged.
;   Clobbers: A/flags via BDOS; BC saved/restored.
;   Algorithm: PUSH BC; call CCP_CONOUT; POP BC; RET.
;   [RE]
; ----------------------------------------------------------------------
CCP_CONOUT_KEEPBC:
        PUSH BC                          ; $9393  C5
        CALL CCP_CONOUT                    ; $9394  CD 8C 93
        POP BC                           ; $9397  C1
        RET                              ; $9398  C9
; ----------------------------------------------------------------------
; CCP_CRLF -- emit a carriage-return + line-feed to the console.
;   In: none.  Out: cursor at start of next line; BC preserved.
;   Clobbers: A/flags.
;   Algorithm: print CR ($0D) then LF ($0A), each via CCP_CONOUT_KEEPBC.
;   [RE]
; ----------------------------------------------------------------------
CCP_CRLF:
        ; CR
        LD A,$0D                         ; $9399  3E 0D
        CALL CCP_CONOUT_KEEPBC                    ; $939B  CD 93 93
        ; LF
        LD A,$0A                         ; $939E  3E 0A
        JR CCP_CONOUT_KEEPBC                      ; $93A0  18 F1
; ----------------------------------------------------------------------
; CCP_CRLF_MSG -- emit CR/LF then print a NUL-terminated message.
;   In: BC -> NUL-terminated message string.
;   Out: message printed after a new line.
;   Clobbers: A, HL, BC.
;   Algorithm: CCP_CRLF; HL:=BC (via PUSH BC/POP HL); fall into CCP_PUTS.
;   [RE] Used by the 'Read error' / 'No file' message printers.
; ----------------------------------------------------------------------
CCP_CRLF_MSG:
        PUSH BC                          ; $93A2  C5
        CALL CCP_CRLF                    ; $93A3  CD 99 93
        POP HL                           ; $93A6  E1
; ----------------------------------------------------------------------
; CCP_PUTS -- print a NUL-terminated string to the console.
;   In: HL -> string.
;   Out: HL past the terminator on exit (loop stops at the NUL).
;   Clobbers: A, HL.
;   Algorithm: loop: A:=(HL); if A==0 RET; INC HL; emit A via CCP_CONOUT; repeat.
;   [RE]
; ----------------------------------------------------------------------
CCP_PUTS:
        LD A,(HL)                        ; $93A7  7E
        OR A                             ; $93A8  B7
        RET Z                            ; $93A9  C8
        INC HL                           ; $93AA  23
        PUSH HL                          ; $93AB  E5
        CALL CCP_CONOUT                    ; $93AC  CD 8C 93
        POP HL                           ; $93AF  E1
        JR CCP_PUTS                      ; $93B0  18 F5
; ----------------------------------------------------------------------
; BDOS_DRV_ALLRESET -- reset the disk system (BDOS function 13).
;   In: none.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=DRV_ALLRESET($0D); JP BDOS.
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_ALLRESET:
        ; DRV_ALLRESET = 13
        LD C,$0D                         ; $93B2  0E 0D
        JR BDOS_JP_TAIL                    ; $93B4  18 03
; ----------------------------------------------------------------------
; BDOS_DRV_SET -- select the default drive (BDOS function 14).
;   In: A = drive number (0=A..15=P).
;   Out: per BDOS.  Clobbers: C, E; BDOS ABI.
;   Algorithm: E:=A; C:=DRV_SET($0E); JP BDOS (shared $0005 tail).
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_SET:
        LD E,A                           ; $93B6  5F
        ; DRV_SET = 14
        LD C,$0E                         ; $93B7  0E 0E
BDOS_JP_TAIL:
        JP $0005                         ; $93B9  C3 05 00
; ----------------------------------------------------------------------
; BDOS_F_CLOSE -- close the file named by DE (BDOS function 16).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP.  Clobbers: A/flags.
;   Algorithm: C:=F_CLOSE($10); fall into BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_CLOSE:
        ; F_CLOSE = 16
        LD C,$10                         ; $93BC  0E 10
BDOS_FCB_OP:
        CALL $0005                       ; $93BE  CD 05 00
        LD (CCP_BDOS_RESULT),A                    ; $93C1  32 A7 9B
        INC A                            ; $93C4  3C
        RET                              ; $93C5  C9
; ----------------------------------------------------------------------
; CCP_OPEN_SUBMIT -- open the staged submit ($$$.SUB) FCB at record 0.
;   In: submit FCB at CCP_FCB (CCP_SUB_FCB).
;   Out: A/Z per BDOS_F_OPEN.  Clobbers: A/flags, DE.
;   Algorithm: clear current-record cell (CCP_FCB_CR); DE:=CCP_SUB_FCB; fall into
;     BDOS_F_OPEN.
;   [RE]
; ----------------------------------------------------------------------
CCP_OPEN_SUBMIT:
        XOR A                            ; $93C6  AF
        LD (CCP_FCB_CR),A                    ; $93C7  32 A6 9B
        LD DE,CCP_FCB                     ; $93CA  11 86 9B
; ----------------------------------------------------------------------
; BDOS_F_OPEN -- open the file named by DE (BDOS function 15).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP (Z = open failed).
;   Clobbers: A/flags.
;   Algorithm: C:=F_OPEN($0F); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_OPEN:
        ; F_OPEN = 15
        LD C,$0F                         ; $93CD  0E 0F
        JR BDOS_FCB_OP                    ; $93CF  18 ED
; ----------------------------------------------------------------------
; CCP_SEARCH_FIRST_SUBMIT -- search-for-first on the submit FCB (BDOS function 17).
;   In: submit FCB at CCP_SUB_FCB.
;   Out: A/Z per BDOS_FCB_OP.  Clobbers: A/flags, DE.
;   Algorithm: DE:=CCP_SUB_FCB; C:=F_SFIRST($11); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
CCP_SEARCH_FIRST_SUBMIT:
        LD DE,CCP_FCB                     ; $93D1  11 86 9B
        ; F_SFIRST = 17
        LD C,$11                         ; $93D4  0E 11
        JR BDOS_FCB_OP                    ; $93D6  18 E6
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
        LD C,$12                         ; $93D8  0E 12
        JR BDOS_FCB_OP                    ; $93DA  18 E2
; ----------------------------------------------------------------------
; BDOS_F_DELETE -- delete the file named by DE (BDOS function 19).
;   In: DE -> FCB.  Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_DELETE($13); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DELETE:
        ; F_DELETE = 19
        LD C,$13                         ; $93DC  0E 13
        JR BDOS_JP_TAIL                    ; $93DE  18 D9
; ----------------------------------------------------------------------
; CCP_READ_SUBMIT -- read the next record of the submit FCB (BDOS function 20).
;   In: submit FCB at CCP_SUB_FCB; DMA preset by the caller.
;   Out: A/Z per BDOS_CALL_TESTERR.  Clobbers: flags, DE.
;   Algorithm: DE:=CCP_SUB_FCB; C:=F_READ($14); fall into BDOS_F_READ.
;   [RE]
; ----------------------------------------------------------------------
CCP_READ_SUBMIT:
        LD DE,CCP_FCB                     ; $93E0  11 86 9B
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
        LD C,$14                         ; $93E3  0E 14
BDOS_CALL_TESTERR:
        CALL $0005                       ; $93E5  CD 05 00
        OR A                             ; $93E8  B7
        RET                              ; $93E9  C9
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
        LD C,$15                         ; $93EA  0E 15
        JR BDOS_CALL_TESTERR                    ; $93EC  18 F7
; ----------------------------------------------------------------------
; BDOS_F_MAKE -- create the file named by DE (BDOS function 22).
;   In: DE -> FCB.  Out: A/Z per BDOS_FCB_OP (Z = create failed/dir full).
;   Clobbers: A/flags.
;   Algorithm: C:=F_MAKE($16); JP BDOS_FCB_OP.
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_MAKE:
        ; F_MAKE = 22
        LD C,$16                         ; $93EE  0E 16
        JR BDOS_FCB_OP                    ; $93F0  18 CC
; ----------------------------------------------------------------------
; BDOS_F_RENAME -- rename a file (BDOS function 23).
;   In: DE -> FCB whose first 16 bytes name the old file and second 16 the new.
;   Out: per BDOS.  Clobbers: per BDOS ABI.
;   Algorithm: C:=F_RENAME($17); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_RENAME:
        ; F_RENAME = 23
        LD C,$17                         ; $93F2  0E 17
        JR BDOS_JP_TAIL                    ; $93F4  18 C3
; ----------------------------------------------------------------------
; BDOS_USER_GET -- get the current user number (BDOS function 32, E=$FF).
;   In: none.  Out: A = current user number (0..15).  Clobbers: A, C, E.
;   Algorithm: E:=$FF (interrogate); fall into BDOS_USERNUM.
;   [RE]
; ----------------------------------------------------------------------
BDOS_USER_GET:
        ; $FF = interrogate (get) user number
        LD E,$FF                         ; $93F6  1E FF
; ----------------------------------------------------------------------
; BDOS_USERNUM -- set/get the user number (BDOS function 32).
;   In: E = user number to set, or $FF to interrogate.
;   Out: A = user number when interrogating.  Clobbers: A, C; BDOS ABI.
;   Algorithm: C:=F_USERNUM($20); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_USERNUM:
        ; F_USERNUM = 32
        LD C,$20                         ; $93F8  0E 20
        JR BDOS_JP_TAIL                    ; $93FA  18 BD
; ----------------------------------------------------------------------
; CCP_SET_USERDRIVE -- write the packed user/drive byte into base page $0004.
;   In: current user (from BDOS_USER_GET) and CCP_CDISK (CCP_CUR_DRIVE, default drive).
;   Out: base-page $0004 := (user<<4 | drive); the CP/M default-drive/user cell.
;   Clobbers: A, HL.
;   Algorithm: A:=BDOS_USER_GET; A<<=4 (ADD A,A x4); OR in CCP_CDISK; store $0004.
;   [RE] $0004 (CDISK_ADDR) is the CP/M default-drive/user cell read by the warm boot.
; ----------------------------------------------------------------------
CCP_SET_USERDRIVE:
        CALL BDOS_USER_GET                    ; $93FC  CD F6 93
        ADD A,A                          ; $93FF  87
        ADD A,A                          ; $9400  87
        ADD A,A                          ; $9401  87
        ADD A,A                          ; $9402  87
        LD HL,CCP_CUR_DRIVE                     ; $9403  21 A8 9B
        OR (HL)                          ; $9406  B6
        ; store login byte (user<<4|drive) to base page $0004 (CDISK)
        LD ($0004),A                     ; $9407  32 04 00
        RET                              ; $940A  C9
; ----------------------------------------------------------------------
; CCP_SET_DRIVE_ONLY -- write just the default drive into base-page $0004.
;   In: CCP_CDISK (CCP_CUR_DRIVE).
;   Out: $0004 := default drive (user nibble cleared).  Clobbers: A.
;   Algorithm: A:=CCP_CDISK; store to $0004.
;   [RE]
; ----------------------------------------------------------------------
CCP_SET_DRIVE_ONLY:
        LD A,(CCP_CUR_DRIVE)                    ; $940B  3A A8 9B
        ; store default drive to base page $0004 (CDISK)
        LD ($0004),A                     ; $940E  32 04 00
        RET                              ; $9411  C9
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
        CP $61                           ; $9412  FE 61
        RET C                            ; $9414  D8
        ; above 'z' -> leave unchanged
        CP $7B                           ; $9415  FE 7B
        RET NC                           ; $9417  D0
        ; clear bit 5: lower -> upper
        AND $5F                          ; $9418  E6 5F
        RET                              ; $941A  C9
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
        LD A,(CCP_STACK_BASE)                    ; $941B  3A 64 9B
        OR A                             ; $941E  B7
        JR Z,CCP_READ_CONSOLE                  ; $941F  28 52
        LD A,(CCP_CUR_DRIVE)                    ; $9421  3A A8 9B
        OR A                             ; $9424  B7
        LD A,$00                         ; $9425  3E 00
        CALL NZ,BDOS_DRV_SET                 ; $9427  C4 B6 93
        LD DE,CCP_SUB_FCB                     ; $942A  11 65 9B
        CALL BDOS_F_OPEN                    ; $942D  CD CD 93
        JR Z,CCP_READ_CONSOLE                  ; $9430  28 41
        LD A,(CCP_SUB_FCB_CR)                    ; $9432  3A 74 9B
        DEC A                            ; $9435  3D
        LD (CCP_SUB_PREV_REC),A                    ; $9436  32 85 9B
        LD DE,CCP_SUB_FCB                     ; $9439  11 65 9B
        CALL BDOS_F_READ                    ; $943C  CD E3 93
        JR NZ,CCP_READ_CONSOLE                 ; $943F  20 32
        LD DE,CCP_INLEN                     ; $9441  11 07 93
        LD HL,$0080                      ; $9444  21 80 00
        LD BC,$0080                      ; $9447  01 80 00
        ; copy 128 bytes TBUFF -> CCP_INBUF (the submit record)
        LDIR                             ; $944A  ED B0
        LD HL,CCP_SUB_FCB_S2                     ; $944C  21 73 9B
        LD (HL),$00                      ; $944F  36 00
        INC HL                           ; $9451  23
        DEC (HL)                         ; $9452  35
        LD DE,CCP_SUB_FCB                     ; $9453  11 65 9B
        CALL BDOS_F_CLOSE                    ; $9456  CD BC 93
        JR Z,CCP_READ_CONSOLE                  ; $9459  28 18
        LD A,(CCP_CUR_DRIVE)                    ; $945B  3A A8 9B
        OR A                             ; $945E  B7
        CALL NZ,BDOS_DRV_SET                 ; $945F  C4 B6 93
        LD HL,CCP_CMDTEXT                     ; $9462  21 08 93
        CALL CCP_PUTS                    ; $9465  CD A7 93
        CALL CCP_CHECK_ABORT                    ; $9468  CD 9A 94
        JR Z,CCP_UPCASE_LINE                  ; $946B  28 14
        CALL CCP_DISCARD_SUBMIT                    ; $946D  CD B5 94
        JP CCP_PROMPT_AND_READ                    ; $9470  C3 31 96
CCP_READ_CONSOLE:
        CALL CCP_DISCARD_SUBMIT                    ; $9473  CD B5 94
        CALL CCP_SET_USERDRIVE                    ; $9476  CD FC 93
        ; C_READSTR = 10 (buffered console line input)
        LD C,$0A                         ; $9479  0E 0A
        LD DE,CCP_INBUF                     ; $947B  11 06 93
        CALL $0005                       ; $947E  CD 05 00
CCP_UPCASE_LINE:
        LD HL,CCP_INLEN                     ; $9481  21 07 93
        LD B,(HL)                        ; $9484  46
CCP_UPCASE_LOOP:
        INC HL                           ; $9485  23
        LD A,B                           ; $9486  78
        OR A                             ; $9487  B7
        JR Z,CCP_UPCASE_DONE                  ; $9488  28 08
        LD A,(HL)                        ; $948A  7E
        CALL CCP_UPCASE                    ; $948B  CD 12 94
        LD (HL),A                        ; $948E  77
        DEC B                            ; $948F  05
        JR CCP_UPCASE_LOOP                    ; $9490  18 F3
CCP_UPCASE_DONE:
        LD (HL),A                        ; $9492  77
        LD HL,CCP_CMDTEXT                     ; $9493  21 08 93
        LD (CCP_PARSEPTR),HL                   ; $9496  22 88 93
        RET                              ; $9499  C9
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
        LD C,$0B                         ; $949A  0E 0B
        CALL $0005                       ; $949C  CD 05 00
        OR A                             ; $949F  B7
        RET Z                            ; $94A0  C8
        ; C_READ = 1: consume the typed key
        LD C,$01                         ; $94A1  0E 01
        CALL $0005                       ; $94A3  CD 05 00
        OR A                             ; $94A6  B7
        RET                              ; $94A7  C9
; ----------------------------------------------------------------------
; BDOS_DRV_GET -- return the current default drive (BDOS function 25).
;   In: none.  Out: A = current drive (0..15).  Clobbers: A, C.
;   Algorithm: C:=DRV_GET($19); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_DRV_GET:
        ; DRV_GET = 25
        LD C,$19                         ; $94A8  0E 19
        JP $0005                         ; $94AA  C3 05 00
; ----------------------------------------------------------------------
; CCP_SET_DMA_TBUFF -- set the DMA address back to the default buffer TBUFF.
;   In: none.  Out: BDOS DMA := TBUFF ($0080).  Clobbers: C, DE.
;   Algorithm: DE:=TBUFF($0080); fall into BDOS_F_DMAOFF.
;   [RE]
; ----------------------------------------------------------------------
CCP_SET_DMA_TBUFF:
        ; DE = TBUFF (default DMA buffer)
        LD DE,$0080                      ; $94AD  11 80 00
; ----------------------------------------------------------------------
; BDOS_F_DMAOFF -- set the disk DMA (transfer) address (BDOS function 26).
;   In: DE = DMA address.  Out: per BDOS.  Clobbers: C; BDOS ABI.
;   Algorithm: C:=F_DMAOFF($1A); JP BDOS ($0005).
;   [RE]
; ----------------------------------------------------------------------
BDOS_F_DMAOFF:
        ; F_DMAOFF = 26 (set DMA)
        LD C,$1A                         ; $94B0  0E 1A
        JP $0005                         ; $94B2  C3 05 00
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
        LD HL,CCP_STACK_BASE                     ; $94B5  21 64 9B
        LD A,(HL)                        ; $94B8  7E
        OR A                             ; $94B9  B7
        RET Z                            ; $94BA  C8
        LD (HL),$00                      ; $94BB  36 00
        XOR A                            ; $94BD  AF
        CALL BDOS_DRV_SET                    ; $94BE  CD B6 93
        LD DE,CCP_SUB_FCB                     ; $94C1  11 65 9B
        CALL BDOS_F_DELETE                    ; $94C4  CD DC 93
        LD A,(CCP_CUR_DRIVE)                    ; $94C7  3A A8 9B
        JP BDOS_DRV_SET                      ; $94CA  C3 B6 93
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
        LD DE,CCP_SERIAL_STAMP                     ; $94CD  11 DF 95
        LD HL,BDOS_FBASE                     ; $94D0  21 00 9C
        ; compare 6 serial bytes
        LD B,$06                         ; $94D3  06 06
CCP_CHECK_SERIAL_LOOP:
        LD A,(DE)                        ; $94D5  1A
        CP (HL)                          ; $94D6  BE
        JP NZ,CCP_SERIAL_MISMATCH_HALT                 ; $94D7  C2 7E 96
        INC DE                           ; $94DA  13
        INC HL                           ; $94DB  23
        DJNZ CCP_CHECK_SERIAL_LOOP                  ; $94DC  10 F7
        RET                              ; $94DE  C9
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
        CALL CCP_CRLF                    ; $94DF  CD 99 93
        LD HL,(CCP_TOKENPTR)                   ; $94E2  2A 8A 93
CCP_ECHO_TOKEN_LOOP:
        LD A,(HL)                        ; $94E5  7E
        CP $20                           ; $94E6  FE 20
        JR Z,CCP_REPORT_BADCMD                  ; $94E8  28 0B
        OR A                             ; $94EA  B7
        JR Z,CCP_REPORT_BADCMD                  ; $94EB  28 08
        PUSH HL                          ; $94ED  E5
        CALL CCP_CONOUT                    ; $94EE  CD 8C 93
        POP HL                           ; $94F1  E1
        INC HL                           ; $94F2  23
        JR CCP_ECHO_TOKEN_LOOP                    ; $94F3  18 F0
CCP_REPORT_BADCMD:
        ; '?' marks an unknown command
        LD A,$3F                         ; $94F5  3E 3F
        CALL CCP_CONOUT                    ; $94F7  CD 8C 93
        CALL CCP_CRLF                    ; $94FA  CD 99 93
        CALL CCP_DISCARD_SUBMIT                    ; $94FD  CD B5 94
        JP CCP_PROMPT_AND_READ                    ; $9500  C3 31 96
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
        LD A,(DE)                        ; $9503  1A
        OR A                             ; $9504  B7
        RET Z                            ; $9505  C8
        CP $20                           ; $9506  FE 20
        ; control char in name -> bad-token echo (CCP_ECHO_TOKEN)
        JR C,CCP_ECHO_TOKEN                    ; $9508  38 D5
        RET Z                            ; $950A  C8
        ; '=' delimiter
        CP $3D                           ; $950B  FE 3D
        RET Z                            ; $950D  C8
        CP $5F                           ; $950E  FE 5F
        RET Z                            ; $9510  C8
        ; '.' (name/type separator)
        CP $2E                           ; $9511  FE 2E
        RET Z                            ; $9513  C8
        ; ':' (drive separator)
        CP $3A                           ; $9514  FE 3A
        RET Z                            ; $9516  C8
        CP $3B                           ; $9517  FE 3B
        RET Z                            ; $9519  C8
        CP $3C                           ; $951A  FE 3C
        RET Z                            ; $951C  C8
        CP $3E                           ; $951D  FE 3E
        RET Z                            ; $951F  C8
        RET                              ; $9520  C9
; ----------------------------------------------------------------------
; CCP_SKIP_BLANKS -- advance (DE) past any run of spaces.
;   In: DE -> command-line char.
;   Out: DE -> first non-blank (or the NUL); Z set if at end of line.
;   Clobbers: A/flags, DE.
;   Algorithm: loop: A:=(DE); RET Z on NUL; if A != ' ' RET NZ; INC DE; loop.
;   [RE]
; ----------------------------------------------------------------------
CCP_SKIP_BLANKS:
        LD A,(DE)                        ; $9521  1A
        OR A                             ; $9522  B7
        RET Z                            ; $9523  C8
        CP $20                           ; $9524  FE 20
        RET NZ                           ; $9526  C0
        INC DE                           ; $9527  13
        JR CCP_SKIP_BLANKS                      ; $9528  18 F7
; ----------------------------------------------------------------------
; CCP_HL_ADD_A -- add the unsigned A to HL (16-bit add of an 8-bit offset).
;   In: HL = base, A = offset.
;   Out: HL = HL + A.  Clobbers: A, HL, flags.
;   Algorithm: A:=A+L; L:=A; if no carry RET; else INC H; RET.
;   [RE] Used to index the FCB by 0 or 16 (parse FCB1 vs FCB2).
; ----------------------------------------------------------------------
CCP_HL_ADD_A:
        ADD A,L                          ; $952A  85
        LD L,A                           ; $952B  6F
        RET NC                           ; $952C  D0
        INC H                            ; $952D  24
        RET                              ; $952E  C9
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
        LD A,$00                         ; $952F  3E 00
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
        LD HL,CCP_FCB                     ; $9531  21 86 9B
        CALL CCP_HL_ADD_A                    ; $9534  CD 2A 95
        PUSH HL                          ; $9537  E5
        PUSH HL                          ; $9538  E5
        XOR A                            ; $9539  AF
        LD (CCP_FCB_DRIVE_PREFIX),A                    ; $953A  32 A9 9B
        LD HL,(CCP_PARSEPTR)                   ; $953D  2A 88 93
        EX DE,HL                         ; $9540  EB
        CALL CCP_SKIP_BLANKS                    ; $9541  CD 21 95
        EX DE,HL                         ; $9544  EB
        LD (CCP_TOKENPTR),HL                   ; $9545  22 8A 93
        EX DE,HL                         ; $9548  EB
        POP HL                           ; $9549  E1
        LD A,(DE)                        ; $954A  1A
        OR A                             ; $954B  B7
        JR Z,CCP_FCB_DRIVE_DEFAULT                  ; $954C  28 0A
        ; letter -> 1-based drive number (carry clear after CCP_AT_DELIM path)
        SBC A,$40                        ; $954E  DE 40
        LD B,A                           ; $9550  47
        INC DE                           ; $9551  13
        LD A,(DE)                        ; $9552  1A
        ; is the next char ':' (drive prefix)?
        CP $3A                           ; $9553  FE 3A
        JR Z,CCP_FCB_DRIVE_EXPLICIT                  ; $9555  28 07
        DEC DE                           ; $9557  1B
CCP_FCB_DRIVE_DEFAULT:
        LD A,(CCP_CUR_DRIVE)                    ; $9558  3A A8 9B
        LD (HL),A                        ; $955B  77
        JR CCP_BUILD_FCB_NAME_SETUP                    ; $955C  18 06
CCP_FCB_DRIVE_EXPLICIT:
        LD A,B                           ; $955E  78
        LD (CCP_FCB_DRIVE_PREFIX),A                    ; $955F  32 A9 9B
        LD (HL),B                        ; $9562  70
        INC DE                           ; $9563  13
CCP_BUILD_FCB_NAME_SETUP:
        LD B,$08                         ; $9564  06 08
CCP_FCB_NAME_LOOP:
        CALL CCP_AT_DELIM                    ; $9566  CD 03 95
        JR Z,CCP_FCB_NAME_PAD                  ; $9569  28 15
        INC HL                           ; $956B  23
        CP $2A                           ; $956C  FE 2A
        JR NZ,CCP_FCB_NAME_STORE                 ; $956E  20 04
        ; '*' wildcard -> store '?' in the name field
        LD (HL),$3F                      ; $9570  36 3F
        JR CCP_FCB_NAME_NEXT                    ; $9572  18 02
CCP_FCB_NAME_STORE:
        LD (HL),A                        ; $9574  77
        INC DE                           ; $9575  13
CCP_FCB_NAME_NEXT:
        DJNZ CCP_FCB_NAME_LOOP                  ; $9576  10 EE
CCP_FCB_NAME_SKIP:
        CALL CCP_AT_DELIM                    ; $9578  CD 03 95
        JR Z,CCP_FCB_TYPE_BEGIN                  ; $957B  28 08
        INC DE                           ; $957D  13
        JR CCP_FCB_NAME_SKIP                    ; $957E  18 F8
CCP_FCB_NAME_PAD:
        INC HL                           ; $9580  23
        LD (HL),$20                      ; $9581  36 20
        DJNZ CCP_FCB_NAME_PAD                  ; $9583  10 FB
CCP_FCB_TYPE_BEGIN:
        LD B,$03                         ; $9585  06 03
        CP $2E                           ; $9587  FE 2E
        JR NZ,CCP_FCB_TYPE_PAD                ; $9589  20 1B
        INC DE                           ; $958B  13
CCP_FCB_TYPE_LOOP:
        CALL CCP_AT_DELIM                    ; $958C  CD 03 95
        JR Z,CCP_FCB_TYPE_PAD                 ; $958F  28 15
        INC HL                           ; $9591  23
        CP $2A                           ; $9592  FE 2A
        JR NZ,CCP_FCB_TYPE_STORE                ; $9594  20 04
        ; '*' wildcard -> store '?' in the type field
        LD (HL),$3F                      ; $9596  36 3F
        JR CCP_FCB_TYPE_NEXT                   ; $9598  18 02
CCP_FCB_TYPE_STORE:
        LD (HL),A                        ; $959A  77
        INC DE                           ; $959B  13
CCP_FCB_TYPE_NEXT:
        DJNZ CCP_FCB_TYPE_LOOP                 ; $959C  10 EE
CCP_FCB_TYPE_SKIP:
        CALL CCP_AT_DELIM                    ; $959E  CD 03 95
        JR Z,CCP_FCB_ZERO_TRAILER                 ; $95A1  28 08
        INC DE                           ; $95A3  13
        JR CCP_FCB_TYPE_SKIP                   ; $95A4  18 F8
CCP_FCB_TYPE_PAD:
        INC HL                           ; $95A6  23
        LD (HL),$20                      ; $95A7  36 20
        DJNZ CCP_FCB_TYPE_PAD                 ; $95A9  10 FB
CCP_FCB_ZERO_TRAILER:
        LD B,$03                         ; $95AB  06 03
CCP_FCB_ZERO_LOOP:
        INC HL                           ; $95AD  23
        LD (HL),$00                      ; $95AE  36 00
        DJNZ CCP_FCB_ZERO_LOOP                 ; $95B0  10 FB
        EX DE,HL                         ; $95B2  EB
        LD (CCP_PARSEPTR),HL                   ; $95B3  22 88 93
        POP HL                           ; $95B6  E1
        LD BC,$000B                      ; $95B7  01 0B 00
FCB_WILDCARD_SCAN:
        INC HL                           ; $95BA  23
        LD A,(HL)                        ; $95BB  7E
        ; is this name/type byte the '?' wildcard?
        CP $3F                           ; $95BC  FE 3F
        JR NZ,FCB_WILDCARD_SCAN_1                ; $95BE  20 01
        INC B                            ; $95C0  04
FCB_WILDCARD_SCAN_1:
        DEC C                            ; $95C1  0D
        JR NZ,FCB_WILDCARD_SCAN                ; $95C2  20 F6
        LD A,B                           ; $95C4  78
        OR A                             ; $95C5  B7
        RET                              ; $95C6  C9
; ----------------------------------------------------------------------
; CCP_BUILTIN_NAMES -- table of the six built-in command names, 4 bytes each.
;   Layout: 'DIR ','ERA ','TYPE','SAVE','REN ','USER' (24 bytes, blank-padded).
;   Indexed 0..5 by SEARCH_BUILTIN; the matched index then selects a handler.
;   [RE]
; ----------------------------------------------------------------------
CCP_BUILTIN_NAMES:
        DEFB    "DIR ERA TYPESAVEREN USER"    ; $95C7  string
; ----------------------------------------------------------------------
; CCP_SERIAL_STAMP -- 6-byte CP/M serial-number stamp embedded in the CCP.
;   Compared against the first 6 bytes of the BDOS image header (BDOS_FBASE, $9C00)
;   by CCP_CHECK_SERIAL; a mismatch means the CCP and BDOS are from different copies
;   and the check jumps to CCP_SERIAL_MISMATCH_HALT. Opaque serial data, not code.
;   [RE] DELTA vs 2.20: 2.23 serial = BD 16 00 01 4D 40; 2.20 = BD 16 00 00 16 DF
;   (different licensed-copy serial; this is the documented per-copy fingerprint).
; ----------------------------------------------------------------------
CCP_SERIAL_STAMP:
        DEFB    $BD,$16,$00,$01,$4D,$40                          ; $95DF
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
        LD HL,CCP_BUILTIN_NAMES                     ; $95E5  21 C7 95
        LD C,$00                         ; $95E8  0E 00
SEARCH_BUILTIN_NEXT:
        LD A,C                           ; $95EA  79
        ; tried all 6 built-ins? (>=6 -> not a built-in)
        CP $06                           ; $95EB  FE 06
        RET NC                           ; $95ED  D0
        LD DE,CCP_FCB_NAME                     ; $95EE  11 87 9B
        ; compare 4 name chars
        LD B,$04                         ; $95F1  06 04
SEARCH_BUILTIN_CMP:
        LD A,(DE)                        ; $95F3  1A
        CP (HL)                          ; $95F4  BE
        JR NZ,SEARCH_BUILTIN_SKIP                 ; $95F5  20 0B
        INC DE                           ; $95F7  13
        INC HL                           ; $95F8  23
        DJNZ SEARCH_BUILTIN_CMP                  ; $95F9  10 F8
        LD A,(DE)                        ; $95FB  1A
        CP $20                           ; $95FC  FE 20
        JR NZ,SEARCH_BUILTIN_ADVANCE                 ; $95FE  20 05
        LD A,C                           ; $9600  79
        RET                              ; $9601  C9
SEARCH_BUILTIN_SKIP:
        INC HL                           ; $9602  23
        DJNZ SEARCH_BUILTIN_SKIP                  ; $9603  10 FD
SEARCH_BUILTIN_ADVANCE:
        INC C                            ; $9605  0C
        JR SEARCH_BUILTIN_NEXT                    ; $9606  18 E2
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
        XOR A                            ; $9608  AF
        ; clear the submit/auto-command flag (CCP_INLEN)
        LD (CCP_INLEN),A                    ; $9609  32 07 93
CCP_COLD_ENTRY:
        LD SP,CCP_STACK_BASE                     ; $960C  31 64 9B
        PUSH BC                          ; $960F  C5
        LD A,C                           ; $9610  79
        RRA                              ; $9611  1F
        RRA                              ; $9612  1F
        RRA                              ; $9613  1F
        RRA                              ; $9614  1F
        AND $0F                          ; $9615  E6 0F
        LD E,A                           ; $9617  5F
        CALL BDOS_USERNUM                    ; $9618  CD F8 93
        CALL BDOS_DRV_ALLRESET                    ; $961B  CD B2 93
        LD (CCP_STACK_BASE),A                    ; $961E  32 64 9B
        POP BC                           ; $9621  C1
        LD A,C                           ; $9622  79
        AND $0F                          ; $9623  E6 0F
        LD (CCP_CUR_DRIVE),A                    ; $9625  32 A8 9B
        CALL BDOS_DRV_SET                    ; $9628  CD B6 93
        LD A,(CCP_INLEN)                    ; $962B  3A 07 93
        OR A                             ; $962E  B7
        JR NZ,CCP_PARSE_AND_DISPATCH                 ; $962F  20 16
CCP_PROMPT_AND_READ:
        LD SP,CCP_STACK_BASE                     ; $9631  31 64 9B
        CALL CCP_CRLF                    ; $9634  CD 99 93
        CALL BDOS_DRV_GET                    ; $9637  CD A8 94
        ADD A,$41                        ; $963A  C6 41
        CALL CCP_CONOUT                    ; $963C  CD 8C 93
        LD A,$3E                         ; $963F  3E 3E
        CALL CCP_CONOUT                    ; $9641  CD 8C 93
        CALL CCP_GETCMD                    ; $9644  CD 1B 94
CCP_PARSE_AND_DISPATCH:
        LD DE,$0080                      ; $9647  11 80 00
        CALL BDOS_F_DMAOFF                    ; $964A  CD B0 94
        CALL BDOS_DRV_GET                    ; $964D  CD A8 94
        LD (CCP_CUR_DRIVE),A                    ; $9650  32 A8 9B
        CALL CCP_PARSE_FCB1                    ; $9653  CD 2F 95
        CALL NZ,CCP_ECHO_TOKEN                 ; $9656  C4 DF 94
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $9659  3A A9 9B
        OR A                             ; $965C  B7
        JP NZ,CCP_DRIVE_SELECT                ; $965D  C2 26 99
        CALL SEARCH_BUILTIN                    ; $9660  CD E5 95
        LD HL,CCP_CMD_DISPATCH_TBL                     ; $9663  21 70 96
        LD E,A                           ; $9666  5F
        LD D,$00                         ; $9667  16 00
        ADD HL,DE                        ; $9669  19
        ADD HL,DE                        ; $966A  19
        LD A,(HL)                        ; $966B  7E
        INC HL                           ; $966C  23
        LD H,(HL)                        ; $966D  66
        LD L,A                           ; $966E  6F
        JP (HL)                          ; $966F  E9
CCP_CMD_DISPATCH_TBL:
        DEFW    DIR_CMD               ; $9670
        DEFW    ERA_CMD              ; $9672
        DEFW    TYPE_CMD              ; $9674
        DEFW    SAVE_CMD              ; $9676
        DEFW    REN_CMD              ; $9678
        DEFW    CCP_CMD_USER              ; $967A
        DEFW    CCP_DRIVE_SELECT              ; $967C
CCP_SERIAL_MISMATCH_HALT:
        LD HL,$76F3                      ; $967E  21 F3 76
        LD (CCP_BASE),HL                   ; $9681  22 00 93
        LD HL,CCP_BASE                     ; $9684  21 00 93
        JP (HL)                          ; $9687  E9
; ----------------------------------------------------------------------
; PRINT_READ_ERROR -- emit the 'Read error' message on a fresh line.
;   In: none.  Out: message printed via CCP_CRLF_MSG.  Clobbers: A, BC, HL.
;   Algorithm: BC:=MSG_READ_ERROR; JP CCP_CRLF_MSG (CRLF then print-until-NUL).
;   [RE] CCP disk read-error report.
; ----------------------------------------------------------------------
PRINT_READ_ERROR:
        LD BC,MSG_READ_ERROR                     ; $9688  01 8E 96
        JP CCP_CRLF_MSG                      ; $968B  C3 A2 93
; ----------------------------------------------------------------------
; MSG_READ_ERROR -- NUL-terminated console message 'Read error'.
;   [RE]
; ----------------------------------------------------------------------
MSG_READ_ERROR:
        DEFB    "Read error"    ; $968E  string
        DEFB    $00    ; $9698  terminator
; ----------------------------------------------------------------------
; PRINT_NO_FILE -- emit the 'No file' message on a fresh line.
;   In: none.  Out: message printed via CCP_CRLF_MSG.  Clobbers: A, BC, HL.
;   Algorithm: BC:=MSG_NO_FILE; JP CCP_CRLF_MSG.
;   [RE] CCP 'file not found' report.
; ----------------------------------------------------------------------
PRINT_NO_FILE:
        LD BC,MSG_NO_FILE                     ; $9699  01 9F 96
        JP CCP_CRLF_MSG                      ; $969C  C3 A2 93
; ----------------------------------------------------------------------
; MSG_NO_FILE -- NUL-terminated console message 'No file'.
;   [RE]
; ----------------------------------------------------------------------
MSG_NO_FILE:
        DEFB    "No file"    ; $969F  string
        DEFB    $00    ; $96A6  terminator
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
        CALL CCP_PARSE_FCB1                    ; $96A7  CD 2F 95
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $96AA  3A A9 9B
        OR A                             ; $96AD  B7
        JP NZ,CCP_ECHO_TOKEN                   ; $96AE  C2 DF 94
        LD HL,CCP_FCB_NAME                     ; $96B1  21 87 9B
        LD BC,$000B                      ; $96B4  01 0B 00
CCP_PARSE_USERNUM_LOOP:
        LD A,(HL)                        ; $96B7  7E
        CP $20                           ; $96B8  FE 20
        JR Z,CCP_PARSE_USERNUM_TAIL                  ; $96BA  28 24
        INC HL                           ; $96BC  23
        ; ASCII digit -> binary ('0'=$30)
        SUB $30                          ; $96BD  D6 30
        ; reject non-digit (>= 10)
        CP $0A                           ; $96BF  FE 0A
        JP NC,CCP_ECHO_TOKEN                   ; $96C1  D2 DF 94
        LD D,A                           ; $96C4  57
        LD A,B                           ; $96C5  78
        AND $E0                          ; $96C6  E6 E0
        JP NZ,CCP_ECHO_TOKEN                   ; $96C8  C2 DF 94
        LD A,B                           ; $96CB  78
        RLCA                             ; $96CC  07
        RLCA                             ; $96CD  07
        RLCA                             ; $96CE  07
        ADD A,B                          ; $96CF  80
        JP C,CCP_ECHO_TOKEN                    ; $96D0  DA DF 94
        ADD A,B                          ; $96D3  80
        JP C,CCP_ECHO_TOKEN                    ; $96D4  DA DF 94
        ADD A,D                          ; $96D7  82
        JP C,CCP_ECHO_TOKEN                    ; $96D8  DA DF 94
        LD B,A                           ; $96DB  47
        DEC C                            ; $96DC  0D
        JR NZ,CCP_PARSE_USERNUM_LOOP                 ; $96DD  20 D8
        RET                              ; $96DF  C9
CCP_PARSE_USERNUM_TAIL:
        LD A,(HL)                        ; $96E0  7E
        CP $20                           ; $96E1  FE 20
        JP NZ,CCP_ECHO_TOKEN                   ; $96E3  C2 DF 94
        INC HL                           ; $96E6  23
        DEC C                            ; $96E7  0D
        JR NZ,CCP_PARSE_USERNUM_TAIL                 ; $96E8  20 F6
        LD A,B                           ; $96EA  78
        RET                              ; $96EB  C9
; ----------------------------------------------------------------------
; CCP_FCB_BYTE_AT -- fetch one byte of the command FCB at TBUFF+(A+C).
;   In: A = offset, C = base offset; the FCB region begins at TBUFF ($0080).
;   Out: A = the FCB byte at $0080+C+A.  Clobbers: A, HL.
;   Algorithm: HL:=TBUFF($0080); A:=A+C; HL+=A (CCP_HL_ADD_A); A:=(HL).
;   [RE] Used by the directory lister to read FCB/dir-entry bytes.
; ----------------------------------------------------------------------
CCP_FCB_BYTE_AT:
        LD HL,$0080                      ; $96EC  21 80 00
        ADD A,C                          ; $96EF  81
        CALL CCP_HL_ADD_A                    ; $96F0  CD 2A 95
        LD A,(HL)                        ; $96F3  7E
        RET                              ; $96F4  C9
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
        XOR A                            ; $96F5  AF
        LD (CCP_FCB),A                    ; $96F6  32 86 9B
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $96F9  3A A9 9B
        OR A                             ; $96FC  B7
        RET Z                            ; $96FD  C8
        DEC A                            ; $96FE  3D
        LD HL,CCP_CUR_DRIVE                     ; $96FF  21 A8 9B
        CP (HL)                          ; $9702  BE
        RET Z                            ; $9703  C8
        JP BDOS_DRV_SET                      ; $9704  C3 B6 93
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
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $9707  3A A9 9B
        OR A                             ; $970A  B7
        RET Z                            ; $970B  C8
        ; convert 1-based prefix (1..16) to 0-based drive number
        DEC A                            ; $970C  3D
        LD HL,CCP_CUR_DRIVE                     ; $970D  21 A8 9B
        CP (HL)                          ; $9710  BE
        RET Z                            ; $9711  C8
        ; load the DEFAULT drive code as the DRV_SET argument (restore it)
        LD A,(CCP_CUR_DRIVE)                    ; $9712  3A A8 9B
        ; tail-call BDOS DRV_SET (fn 14) to re-select the default drive
        JP BDOS_DRV_SET                      ; $9715  C3 B6 93
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
        CALL CCP_PARSE_FCB1                    ; $9718  CD 2F 95
        ; select the drive named by the filespec prefix (RESOLVE_DRIVE_PREFIX)
        CALL CCP_RESET_USER_IF_NEEDED                    ; $971B  CD F5 96
        LD HL,CCP_FCB_NAME                     ; $971E  21 87 9B
        LD A,(HL)                        ; $9721  7E
        ; first FCB name byte blank? => no filespec name given, wildcard everything
        CP $20                           ; $9722  FE 20
        JR NZ,DIR_START_SEARCH                 ; $9724  20 07
        ; 11 = length of the FCB name+type field to wildcard-fill
        LD B,$0B                         ; $9726  06 0B
; ----------------------------------------------------------------------
; DIR_WILDCARD_FILL -- overwrite the 11 FCB name+type bytes with '?' so DIR matches every file.
;   In: HL = first name byte of the search FCB; B = 11.
;   Out: 11 bytes set to '?' ($3F); HL advanced; B = 0. Falls into DIR_START_SEARCH.
;   Clobbers: B, HL (A preserved).
;   Algorithm: store '?' through HL, advance, decrement count, repeat 11 times.
;   [RE] 2.20-44K twin DIR_WILDCARD_FILL.
; ----------------------------------------------------------------------
DIR_WILDCARD_FILL:
        LD (HL),$3F                      ; $9728  36 3F
        INC HL                           ; $972A  23
        DJNZ DIR_WILDCARD_FILL                  ; $972B  10 FB
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
        LD E,$00                         ; $972D  1E 00
        PUSH DE                          ; $972F  D5
        ; BDOS SEARCH_FIRST (fn 17) on the search FCB
        CALL CCP_SEARCH_FIRST_SUBMIT                    ; $9730  CD D1 93
        ; no directory match: print 'No file'
        CALL Z,PRINT_NO_FILE                  ; $9733  CC 99 96
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
        JR Z,DIR_EXIT                 ; $9736  28 75
        ; BDOS directory code (0..3) of the matched entry
        LD A,(CCP_BDOS_RESULT)                    ; $9738  3A A7 9B
        RRCA                             ; $973B  0F
        RRCA                             ; $973C  0F
        RRCA                             ; $973D  0F
        ; code*32: byte offset of the matched 32-byte entry within TBUFF
        AND $60                          ; $973E  E6 60
        LD C,A                           ; $9740  4F
        ; offset 10 within the entry = the file flag/attribute byte
        LD A,$0A                         ; $9741  3E 0A
        CALL CCP_FCB_BYTE_AT                    ; $9743  CD EC 96
        ; move flag bit7 into carry
        RLA                              ; $9746  17
        ; flag bit7 set: skip this entry, go SEARCH_NEXT
        JR C,DIR_NEXT_OR_EXIT                 ; $9747  38 5A
        POP DE                           ; $9749  D1
        LD A,E                           ; $974A  7B
        INC E                            ; $974B  1C
        PUSH DE                          ; $974C  D5
        ; parity of the entry index => 4-per-line column layout (2.20 twin used AND $01 = 2/line)
        AND $03                          ; $974D  E6 03
        PUSH AF                          ; $974F  F5
        ; nonzero column: continue on the same line with a separator
        JR NZ,DIR_FMT_ENTRY_COLS                 ; $9750  20 14
        CALL CCP_CRLF                    ; $9752  CD 99 93
        PUSH BC                          ; $9755  C5
        CALL BDOS_DRV_GET                    ; $9756  CD A8 94
        POP BC                           ; $9759  C1
        ; convert drive 0..15 to letter 'A'..'P'
        ADD A,$41                        ; $975A  C6 41
        CALL CCP_CONOUT_KEEPBC                    ; $975C  CD 93 93
        LD A,$3A                         ; $975F  3E 3A
        CALL CCP_CONOUT_KEEPBC                    ; $9761  CD 93 93
        JR DIR_PRINT_NAME                    ; $9764  18 08
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
        CALL CCP_SPACE                    ; $9766  CD 91 93
        LD A,$3A                         ; $9769  3E 3A
        CALL CCP_CONOUT_KEEPBC                    ; $976B  CD 93 93
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
        CALL CCP_SPACE                    ; $976E  CD 91 93
        LD B,$01                         ; $9771  06 01
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
        LD A,B                           ; $9773  78
        CALL CCP_FCB_BYTE_AT                    ; $9774  CD EC 96
        ; strip the directory attribute high bit
        AND $7F                          ; $9777  E6 7F
        CP $20                           ; $9779  FE 20
        JR NZ,DIR_PUT_NAME_CHAR                 ; $977B  20 13
        POP AF                           ; $977D  F1
        PUSH AF                          ; $977E  F5
        ; saved column-parity == 3 (last of 4)? LIVE here (AND $03); dead in the 2.20 AND $01 twin
        CP $03                           ; $977F  FE 03
        JR NZ,DIR_EMIT_NAME_CHAR_2                 ; $9781  20 0B
        ; offset 9 = first type byte, peeked to detect an all-blank extension
        LD A,$09                         ; $9783  3E 09
        CALL CCP_FCB_BYTE_AT                    ; $9785  CD EC 96
        AND $7F                          ; $9788  E6 7F
        CP $20                           ; $978A  FE 20
        ; all-blank extension at the last column: stop and fetch the next entry
        JR Z,DIR_SEARCH_NEXT                 ; $978C  28 14
; ----------------------------------------------------------------------
; DIR_EMIT_NAME_CHAR_2 -- substitute a single space for a blank name char, then emit it.
;   In: reached when the current name character is a blank to be rendered as one space.
;   Out: A:=' '; falls into DIR_PUT_NAME_CHAR.
;   Clobbers: A.
;   [RE] 2.20-44K twin DIR_EMIT_NAME_CHAR_2.
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR_2:
        LD A,$20                         ; $978E  3E 20
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
        CALL CCP_CONOUT_KEEPBC                    ; $9790  CD 93 93
        INC B                            ; $9793  04
        LD A,B                           ; $9794  78
        ; reached index 12 (all 11 name+type chars done)?
        CP $0C                           ; $9795  FE 0C
        JR NC,DIR_SEARCH_NEXT                ; $9797  30 09
        ; reached the first type-field byte (index 9)? print the name/ext separator
        CP $09                           ; $9799  FE 09
        JR NZ,DIR_EMIT_NAME_CHAR                 ; $979B  20 D6
        CALL CCP_SPACE                    ; $979D  CD 91 93
        JR DIR_EMIT_NAME_CHAR                    ; $97A0  18 D1
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
        POP AF                           ; $97A2  F1
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
        CALL CCP_CHECK_ABORT                    ; $97A3  CD 9A 94
        JR NZ,DIR_EXIT                ; $97A6  20 05
        ; BDOS SEARCH_NEXT (fn 18) for the following entry
        CALL BDOS_F_SNEXT                    ; $97A8  CD D8 93
        JR DIR_CMD_2                    ; $97AB  18 89
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
        POP DE                           ; $97AD  D1
        JP CCP_RETURN_OK                   ; $97AE  C3 38 9A
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
        CALL CCP_PARSE_FCB1                    ; $97B1  CD 2F 95
        ; all 11 name/type bytes wildcard => spec was '*.*' (erase everything)
        CP $0B                           ; $97B4  FE 0B
        JR NZ,ERA_DO_DELETE                ; $97B6  20 1B
        ; point at the 'All (y/n)?' confirmation prompt
        LD BC,MSG_ERA_CONFIRM                     ; $97B8  01 E3 97
        CALL CCP_CRLF_MSG                    ; $97BB  CD A2 93
        CALL CCP_GETCMD                    ; $97BE  CD 1B 94
        LD HL,CCP_INLEN                     ; $97C1  21 07 93
        DEC (HL)                         ; $97C4  35
        JP NZ,CCP_PROMPT_AND_READ                 ; $97C5  C2 31 96
        INC HL                           ; $97C8  23
        LD A,(HL)                        ; $97C9  7E
        ; reply must be 'Y'
        CP $59                           ; $97CA  FE 59
        JP NZ,CCP_PROMPT_AND_READ                 ; $97CC  C2 31 96
        INC HL                           ; $97CF  23
        LD (CCP_PARSEPTR),HL                   ; $97D0  22 88 93
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
        CALL CCP_RESET_USER_IF_NEEDED                    ; $97D3  CD F5 96
        LD DE,CCP_FCB                     ; $97D6  11 86 9B
        ; BDOS F_DELETE (fn 19) on the FCB
        CALL BDOS_F_DELETE                    ; $97D9  CD DC 93
        ; map $FF (no file deleted) to 0 so Z signals 'nothing matched'
        INC A                            ; $97DC  3C
        ; nothing deleted: print 'No file'
        CALL Z,PRINT_NO_FILE                  ; $97DD  CC 99 96
        JP CCP_RETURN_OK                   ; $97E0  C3 38 9A
; ----------------------------------------------------------------------
; MSG_ERA_CONFIRM -- ASCIIZ prompt 'All (y/n)?' shown before erasing every file (ERA *.*).
;   [RE] 2.20-44K twin MSG_ERA_CONFIRM. The 2.23 text is lowercase 'All (y/n)?' (2.20 was 'ALL
;   (Y/N)?').
; ----------------------------------------------------------------------
MSG_ERA_CONFIRM:
        DEFB    "All (y/n)?"    ; $97E3  string
        DEFB    $00    ; $97ED  terminator
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
        CALL CCP_PARSE_FCB1                    ; $97EE  CD 2F 95
        ; bad/ambiguous filespec: echo the offending token and abort
        JP NZ,CCP_ECHO_TOKEN                   ; $97F1  C2 DF 94
        CALL CCP_RESET_USER_IF_NEEDED                    ; $97F4  CD F5 96
        ; BDOS OPEN (fn 15) on the FCB (CCP_OPEN_SUBMIT)
        CALL CCP_OPEN_SUBMIT                    ; $97F7  CD C6 93
        ; open failed (file not found): go report it (TYPE_NO_FILE)
        JR Z,TYPE_NO_FILE                 ; $97FA  28 38
        CALL CCP_CRLF                    ; $97FC  CD 99 93
        LD HL,CCP_TYPE_REC_INDEX                     ; $97FF  21 AA 9B
        ; prime the per-record byte counter so the first pass forces a record read
        LD (HL),$FF                      ; $9802  36 FF
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
        LD HL,CCP_TYPE_REC_INDEX                     ; $9804  21 AA 9B
        LD A,(HL)                        ; $9807  7E
        ; consumed a whole 128-byte record? then read the next one
        CP $80                           ; $9808  FE 80
        JR C,TYPE_EMIT_CHAR                 ; $980A  38 09
        PUSH HL                          ; $980C  E5
        ; BDOS F_READ (fn 20) next record into the DMA buffer
        CALL CCP_READ_SUBMIT                    ; $980D  CD E0 93
        POP HL                           ; $9810  E1
        ; nonzero status: EOF or error -> TYPE_READ_DONE
        JR NZ,TYPE_READ_DONE                ; $9811  20 1A
        XOR A                            ; $9813  AF
        LD (HL),A                        ; $9814  77
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
        INC (HL)                         ; $9815  34
        LD HL,$0080                      ; $9816  21 80 00
        CALL CCP_HL_ADD_A                    ; $9819  CD 2A 95
        LD A,(HL)                        ; $981C  7E
        ; $1A = Ctrl-Z, the CP/M soft end-of-file marker -> stop TYPE
        CP $1A                           ; $981D  FE 1A
        JP Z,CCP_RETURN_OK                 ; $981F  CA 38 9A
        CALL CCP_CONOUT                    ; $9822  CD 8C 93
        ; poll the console for a key (fn 11/fn 1); nonzero = user aborted TYPE
        CALL CCP_CHECK_ABORT                    ; $9825  CD 9A 94
        JP NZ,CCP_RETURN_OK                ; $9828  C2 38 9A
        JR TYPE_PRINT_LOOP                   ; $982B  18 D7
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
        DEC A                            ; $982D  3D
        JP Z,CCP_RETURN_OK                 ; $982E  CA 38 9A
        ; print the 'Read error' message (disk read failure)
        CALL PRINT_READ_ERROR                    ; $9831  CD 88 96
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
        CALL CCP_RESTORE_DEFAULT_DRIVE                    ; $9834  CD 07 97
        JP CCP_ECHO_TOKEN                      ; $9837  C3 DF 94
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
        CALL CCP_PARSE_USERNUM                    ; $983A  CD A7 96
        PUSH AF                          ; $983D  F5
        CALL CCP_PARSE_FCB1                    ; $983E  CD 2F 95
        JP NZ,CCP_ECHO_TOKEN                   ; $9841  C2 DF 94
        CALL CCP_RESET_USER_IF_NEEDED                    ; $9844  CD F5 96
        LD DE,CCP_FCB                     ; $9847  11 86 9B
        PUSH DE                          ; $984A  D5
        CALL BDOS_F_DELETE                    ; $984B  CD DC 93
        POP DE                           ; $984E  D1
        ; BDOS F_MAKE (fn 22): create the new (empty) file
        CALL BDOS_F_MAKE                    ; $984F  CD EE 93
        ; no free directory entry: jump to the 'No space' error
        JR Z,SAVE_DISK_FULL                 ; $9852  28 2F
        XOR A                            ; $9854  AF
        LD (CCP_FCB_CR),A                    ; $9855  32 A6 9B
        POP AF                           ; $9858  F1
        LD L,A                           ; $9859  6F
        LD H,$00                         ; $985A  26 00
        ; pages*2 = number of 128-byte records to write
        ADD HL,HL                        ; $985C  29
        ; DE = source pointer, starting at the TPA base $0100
        LD DE,$0100                      ; $985D  11 00 01
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
        LD A,H                           ; $9860  7C
        OR L                             ; $9861  B5
        JR Z,SAVE_CLOSE                 ; $9862  28 16
        DEC HL                           ; $9864  2B
        PUSH HL                          ; $9865  E5
        LD HL,$0080                      ; $9866  21 80 00
        ADD HL,DE                        ; $9869  19
        PUSH HL                          ; $986A  E5
        ; BDOS F_DMAOFF (fn 26): point the DMA at the CURRENT source slice (DE)
        CALL BDOS_F_DMAOFF                    ; $986B  CD B0 94
        LD DE,CCP_FCB                     ; $986E  11 86 9B
        ; BDOS F_WRITE (fn 21): append the record to the file
        CALL BDOS_F_WRITE                    ; $9871  CD EA 93
        POP DE                           ; $9874  D1
        POP HL                           ; $9875  E1
        ; write failed (disk full): jump to the 'No space' error
        JR NZ,SAVE_DISK_FULL                ; $9876  20 0B
        JR SAVE_WRITE_LOOP                   ; $9878  18 E6
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
        LD DE,CCP_FCB                     ; $987A  11 86 9B
        ; BDOS F_CLOSE (fn 16): flush the directory entry for the saved file
        CALL BDOS_F_CLOSE                    ; $987D  CD BC 93
        ; map the $FF close-error code to 0; a valid directory code becomes nonzero = success
        INC A                            ; $9880  3C
        JR NZ,SAVE_FINISH                ; $9881  20 06
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
        LD BC,MSG_NO_SPACE                     ; $9883  01 8F 98
        CALL CCP_CRLF_MSG                    ; $9886  CD A2 93
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
        CALL CCP_SET_DMA_TBUFF                    ; $9889  CD AD 94
        JP CCP_RETURN_OK                   ; $988C  C3 38 9A
; ----------------------------------------------------------------------
; MSG_NO_SPACE -- ASCIIZ console message 'No space' shown when SAVE runs out of room.
;   [RE] 2.20-44K twin MSG_NO_SPACE (2.23 text lowercase 'No space').
; ----------------------------------------------------------------------
MSG_NO_SPACE:
        DEFB    "No space"    ; $988F  string
        DEFB    $00    ; $9897  terminator
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
        CALL CCP_PARSE_FCB1                    ; $9898  CD 2F 95
        JP NZ,CCP_ECHO_TOKEN                   ; $989B  C2 DF 94
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $989E  3A A9 9B
        PUSH AF                          ; $98A1  F5
        CALL CCP_RESET_USER_IF_NEEDED                    ; $98A2  CD F5 96
        ; BDOS SEARCH_FIRST (fn 17): does the NEW name already exist?
        CALL CCP_SEARCH_FIRST_SUBMIT                    ; $98A5  CD D1 93
        ; new name already exists: report 'File exists'
        JR NZ,REN_FILE_EXISTS                ; $98A8  20 50
        LD HL,CCP_FCB                     ; $98AA  21 86 9B
        LD DE,CCP_FCB_SECOND                     ; $98AD  11 96 9B
        LD BC,$0010                      ; $98B0  01 10 00
        ; copy the 16-byte new-name FCB into the second FCB slot at +16 (the rename pair)
        LDIR                             ; $98B3  ED B0
        LD HL,(CCP_PARSEPTR)                   ; $98B5  2A 88 93
        EX DE,HL                         ; $98B8  EB
        CALL CCP_SKIP_BLANKS                    ; $98B9  CD 21 95
        ; '=' separator between new and old names
        CP $3D                           ; $98BC  FE 3D
        JR Z,REN_PARSE_OLD                 ; $98BE  28 04
        ; '_' is also accepted as the new=old separator
        CP $5F                           ; $98C0  FE 5F
        JR NZ,REN_ERROR                ; $98C2  20 30
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
        EX DE,HL                         ; $98C4  EB
        INC HL                           ; $98C5  23
        LD (CCP_PARSEPTR),HL                   ; $98C6  22 88 93
        CALL CCP_PARSE_FCB1                    ; $98C9  CD 2F 95
        JR NZ,REN_ERROR                ; $98CC  20 26
        POP AF                           ; $98CE  F1
        LD B,A                           ; $98CF  47
        LD HL,CCP_FCB_DRIVE_PREFIX                     ; $98D0  21 A9 9B
        LD A,(HL)                        ; $98D3  7E
        OR A                             ; $98D4  B7
        JR Z,REN_DO_RENAME                 ; $98D5  28 04
        CP B                             ; $98D7  B8
        LD (HL),B                        ; $98D8  70
        JR NZ,REN_ERROR                ; $98D9  20 19
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
        LD (HL),B                        ; $98DB  70
        XOR A                            ; $98DC  AF
        LD (CCP_FCB),A                    ; $98DD  32 86 9B
        CALL CCP_SEARCH_FIRST_SUBMIT                    ; $98E0  CD D1 93
        JR Z,REN_OLD_NOT_FOUND                 ; $98E3  28 09
        LD DE,CCP_FCB                     ; $98E5  11 86 9B
        ; BDOS F_RENAME (fn 23): rename old -> new using the paired FCB
        CALL BDOS_F_RENAME                    ; $98E8  CD F2 93
        JP CCP_RETURN_OK                   ; $98EB  C3 38 9A
; ----------------------------------------------------------------------
; REN_OLD_NOT_FOUND -- REN error: the source file to rename does not exist.
;   In: none.
;   Out: prints 'No file' (PRINT_NO_FILE) and returns to CCP_RETURN_OK.
;   Clobbers: A, BC, flags.
;   [RE] 2.20-44K twin REN_OLD_NOT_FOUND.
; ----------------------------------------------------------------------
REN_OLD_NOT_FOUND:
        CALL PRINT_NO_FILE                    ; $98EE  CD 99 96
        JP CCP_RETURN_OK                   ; $98F1  C3 38 9A
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
        CALL CCP_RESTORE_DEFAULT_DRIVE                    ; $98F4  CD 07 97
        JP CCP_ECHO_TOKEN                      ; $98F7  C3 DF 94
; ----------------------------------------------------------------------
; REN_FILE_EXISTS -- REN error: the requested new name already exists on disk.
;   In: none.
;   Out: prints 'File exists' and returns to CCP_RETURN_OK.
;   Clobbers: A, BC, flags.
;   [RE] 2.20-44K twin REN_FILE_EXISTS; the new name was found by the earlier SEARCH_FIRST.
; ----------------------------------------------------------------------
REN_FILE_EXISTS:
        LD BC,CCP_MSG_FILE_EXISTS                     ; $98FA  01 03 99
        CALL CCP_CRLF_MSG                    ; $98FD  CD A2 93
        JP CCP_RETURN_OK                   ; $9900  C3 38 9A
; ----------------------------------------------------------------------
; CCP_MSG_FILE_EXISTS -- ASCIIZ console message 'File exists'.
;   [RE] 2.20-44K twin CCP_MSG_FILE_EXISTS (2.23 text lowercase 'File exists').
; ----------------------------------------------------------------------
CCP_MSG_FILE_EXISTS:
        DEFB    "File exists"    ; $9903  string
        DEFB    $00    ; $990E  terminator
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
        CALL CCP_PARSE_USERNUM                    ; $990F  CD A7 96
        ; user numbers are 0..15; reject $10 (16) or more as out of range
        CP $10                           ; $9912  FE 10
        JP NC,CCP_ECHO_TOKEN                   ; $9914  D2 DF 94
        LD E,A                           ; $9917  5F
        LD A,(CCP_FCB_NAME)                    ; $9918  3A 87 9B
        CP $20                           ; $991B  FE 20
        JP Z,CCP_ECHO_TOKEN                    ; $991D  CA DF 94
        ; BDOS F_USERNUM (fn 32, C=$20): set the user number to E
        CALL BDOS_USERNUM                    ; $9920  CD F8 93
        JP CCP_RETURN_OK_NOCRLF                   ; $9923  C3 3B 9A
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
        CALL CCP_CHECK_SERIAL                    ; $9926  CD CD 94
        LD A,(CCP_FCB_NAME)                    ; $9929  3A 87 9B
        CP $20                           ; $992C  FE 20
        ; a name follows the drive prefix: treat as a transient program load
        JR NZ,CCP_CMD_TRANSIENT                ; $992E  20 16
        LD A,(CCP_FCB_DRIVE_PREFIX)                    ; $9930  3A A9 9B
        OR A                             ; $9933  B7
        JP Z,CCP_RETURN_OK_NOCRLF                 ; $9934  CA 3B 9A
        DEC A                            ; $9937  3D
        PUSH AF                          ; $9938  F5
        CALL BDOS_DRV_SET                    ; $9939  CD B6 93
        POP AF                           ; $993C  F1
        LD (CCP_CUR_DRIVE),A                    ; $993D  32 A8 9B
        CALL CCP_SET_DRIVE_ONLY                    ; $9940  CD 0B 94
        JP CCP_RETURN_OK_NOCRLF                   ; $9943  C3 3B 9A
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
        CALL BDOS_USER_GET                    ; $9946  CD F6 93
        LD (FASTLOAD_DRIVE_SAVE),A                    ; $9949  32 43 9B
        LD DE,CCP_FCB_EXT                     ; $994C  11 8F 9B
        LD A,(DE)                        ; $994F  1A
        CP $20                           ; $9950  FE 20
        ; explicit extension given: not a bare transient command, echo+abort
        JP NZ,CCP_ECHO_TOKEN                   ; $9952  C2 DF 94
        PUSH DE                          ; $9955  D5
        CALL CCP_RESET_USER_IF_NEEDED                    ; $9956  CD F5 96
        POP DE                           ; $9959  D1
        ; source = the constant 'COM' extension text (CCP_COM_EXT)
        LD HL,CCP_COM_EXT                     ; $995A  21 35 9A
        LD BC,$0003                      ; $995D  01 03 00
        ; force the FCB type field to COM (3-byte copy)
        LDIR                             ; $9960  ED B0
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
        CALL CCP_OPEN_SUBMIT                    ; $9962  CD C6 93
        JR NZ,CCP_LOAD_PREP                ; $9965  20 0D
        CALL BDOS_USER_GET                    ; $9967  CD F6 93
        OR A                             ; $996A  B7
        ; open failed (file not found): go CCP_NO_FILE
        JP Z,CCP_NO_FILE                 ; $996B  CA 1B 9A
        XOR A                            ; $996E  AF
        CALL FASTLOAD_SET_DRIVE                    ; $996F  CD 50 9A
        JR CCP_TRANSIENT_OPEN                   ; $9972  18 EE
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
        LD A,(CCP_FCB)                    ; $9974  3A 86 9B
        OR A                             ; $9977  B7
        JR Z,CCP_LOAD_CHECK_FASTPATH                 ; $9978  28 04
        DEC A                            ; $997A  3D
        CALL BDOS_DRV_SET                    ; $997B  CD B6 93
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
        LD C,$1F                         ; $997E  0E 1F
        CALL $0005                       ; $9980  CD 05 00
        INC HL                           ; $9983  23
        INC HL                           ; $9984  23
        LD A,(HL)                        ; $9985  7E
        ; DPB field at +2 vs $03: gate for the SoftCard RPC fast-load path [RE]
        CP $03                           ; $9986  FE 03
        JR NZ,CCP_LOAD_LOOP                ; $9988  20 09
        INC HL                           ; $998A  23
        INC HL                           ; $998B  23
        INC HL                           ; $998C  23
        LD A,(HL)                        ; $998D  7E
        ; DPB field at +5 vs $8B: second fast-load gate marker [RE]
        CP $8B                           ; $998E  FE 8B
        ; DPB matches: use the SoftCard 6502-RWTS accelerated loader (FASTLOAD_RPC_BEGIN)
        JP Z,FASTLOAD_RPC_BEGIN                  ; $9990  CA 54 9A
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
        LD HL,$0100                      ; $9993  21 00 01
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
        PUSH HL                          ; $9996  E5
        EX DE,HL                         ; $9997  EB
        CALL BDOS_F_DMAOFF                    ; $9998  CD B0 94
        LD DE,CCP_FCB                     ; $999B  11 86 9B
        ; BDOS F_READ (fn 20): read one 128-byte record into the TPA
        CALL BDOS_F_READ                    ; $999E  CD E3 93
        ; nonzero = EOF or read error: finish the load (CCP_LOAD_DONE)
        JR NZ,CCP_LOAD_DONE                ; $99A1  20 11
        POP HL                           ; $99A3  E1
        LD DE,$0080                      ; $99A4  11 80 00
        ADD HL,DE                        ; $99A7  19
        ; CCP base ($9300): the ceiling the loaded program must not reach
        LD DE,CCP_BASE                     ; $99A8  11 00 93
        OR A                             ; $99AB  B7
        PUSH HL                          ; $99AC  E5
        SBC HL,DE                        ; $99AD  ED 52
        POP HL                           ; $99AF  E1
        ; load reached the CCP: program too large -> CCP_BAD_LOAD
        JR NC,CCP_BAD_LOAD                ; $99B0  30 72
        JR CCP_LOAD_LOOP_BODY                   ; $99B2  18 E2
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
        POP HL                           ; $99B4  E1
        ; sequential-read return 1 = clean EOF -> 0; any other value is a load error
        DEC A                            ; $99B5  3D
        ; non-EOF read result: report BAD LOAD
        JR NZ,CCP_BAD_LOAD                ; $99B6  20 6C
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
        CALL FASTLOAD_RESELECT_DRIVE                    ; $99B8  CD 4D 9A
        CALL CCP_RESTORE_DEFAULT_DRIVE                    ; $99BB  CD 07 97
        CALL CCP_PARSE_FCB1                    ; $99BE  CD 2F 95
        LD HL,CCP_FCB_DRIVE_PREFIX                     ; $99C1  21 A9 9B
        PUSH HL                          ; $99C4  E5
        LD A,(HL)                        ; $99C5  7E
        LD (CCP_FCB),A                    ; $99C6  32 86 9B
        LD A,$10                         ; $99C9  3E 10
        CALL CCP_BUILD_FCB                    ; $99CB  CD 31 95
        POP HL                           ; $99CE  E1
        LD A,(HL)                        ; $99CF  7E
        LD (CCP_FCB_SECOND),A                    ; $99D0  32 96 9B
        XOR A                            ; $99D3  AF
        LD (CCP_FCB_CR),A                    ; $99D4  32 A6 9B
        ; destination = the default FCB at page-zero TFCB ($005C)
        LD DE,$005C                      ; $99D7  11 5C 00
        LD HL,CCP_FCB                     ; $99DA  21 86 9B
        LD BC,$0021                      ; $99DD  01 21 00
        ; copy $21 (33) bytes = one full FCB image down to TFCB
        LDIR                             ; $99E0  ED B0
        LD HL,CCP_CMDTEXT                     ; $99E2  21 08 93
; ----------------------------------------------------------------------
; CCP_TAIL_SKIP_NAME -- scan past the program name to the start of the command tail.
;   In: HL = pointer into the CCP command-line buffer (CCP_CMDTEXT).
;   Out: HL at the first blank or NUL after the command word; falls into CCP_TAIL_COPY.
;   Clobbers: A, HL.
;   [RE] 2.20-44K twin CCP_TAIL_SKIP_NAME.
; ----------------------------------------------------------------------
CCP_TAIL_SKIP_NAME:
        LD A,(HL)                        ; $99E5  7E
        OR A                             ; $99E6  B7
        JR Z,CCP_TAIL_COPY                 ; $99E7  28 07
        CP $20                           ; $99E9  FE 20
        JR Z,CCP_TAIL_COPY                 ; $99EB  28 03
        INC HL                           ; $99ED  23
        JR CCP_TAIL_SKIP_NAME                   ; $99EE  18 F5
; ----------------------------------------------------------------------
; CCP_TAIL_COPY -- begin copying the command tail to TBUFF and counting its length.
;   In: HL = first char of the command tail (blank or NUL).
;   Out: DE:=$0081 (TBUFF+1), B:=0 (length); falls into CCP_TAIL_COPY_LOOP.
;   Clobbers: B, DE.
;   [RE] 2.20-44K twin CCP_TAIL_COPY; $0080 (TBUFF) holds the final length byte.
; ----------------------------------------------------------------------
CCP_TAIL_COPY:
        LD B,$00                         ; $99F0  06 00
        LD DE,$0081                      ; $99F2  11 81 00
; ----------------------------------------------------------------------
; CCP_TAIL_COPY_LOOP -- per-character copy loop of the command tail.
;   In: HL = source char, DE = TBUFF dest, B = running length.
;   Out: on the NUL terminator branches to CCP_TAIL_SETLEN with B = length.
;   Clobbers: A, B, DE, HL.
;   [RE] 2.20-44K twin CCP_TAIL_COPY_LOOP.
; ----------------------------------------------------------------------
CCP_TAIL_COPY_LOOP:
        LD A,(HL)                        ; $99F5  7E
        LD (DE),A                        ; $99F6  12
        OR A                             ; $99F7  B7
        JR Z,CCP_TAIL_SETLEN                 ; $99F8  28 05
        INC B                            ; $99FA  04
        INC HL                           ; $99FB  23
        INC DE                           ; $99FC  13
        JR CCP_TAIL_COPY_LOOP                   ; $99FD  18 F6
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
        LD A,B                           ; $99FF  78
        LD ($0080),A                     ; $9A00  32 80 00
        CALL CCP_CRLF                    ; $9A03  CD 99 93
        CALL CCP_SET_DMA_TBUFF                    ; $9A06  CD AD 94
        CALL CCP_SET_USERDRIVE                    ; $9A09  CD FC 93
        ; run the loaded transient program in the TPA
        CALL $0100                       ; $9A0C  CD 00 01
        ; restore the CCP private stack after the program returns
        LD SP,CCP_STACK_BASE                     ; $9A0F  31 64 9B
        CALL CCP_SET_DRIVE_ONLY                    ; $9A12  CD 0B 94
        CALL BDOS_DRV_SET                    ; $9A15  CD B6 93
        JP CCP_PROMPT_AND_READ                    ; $9A18  C3 31 96
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
        CALL FASTLOAD_RESELECT_DRIVE                    ; $9A1B  CD 4D 9A
        CALL CCP_RESTORE_DEFAULT_DRIVE                    ; $9A1E  CD 07 97
        JP CCP_ECHO_TOKEN                      ; $9A21  C3 DF 94
; ----------------------------------------------------------------------
; CCP_BAD_LOAD -- report a transient that would not fit / had a read error.
;   In: entered on TPA overflow or a non-EOF read error.
;   Out: prints 'Bad load' (CRLF + message via CCP_CRLF_MSG = CCP_CRLF_MSG) then joins
;        CCP_RETURN_OK.
;   Clobbers: BC and the print/BDOS registers.
;   [RE] 2.20-44K twin CCP_BAD_LOAD. NOTE: 2.23 text lowercase 'Bad load' (2.20 'BAD LOAD').
; ----------------------------------------------------------------------
CCP_BAD_LOAD:
        LD BC,CCP_MSG_BAD_LOAD                     ; $9A24  01 2C 9A
        CALL CCP_CRLF_MSG                    ; $9A27  CD A2 93
        JR CCP_RETURN_OK                   ; $9A2A  18 0C
; ----------------------------------------------------------------------
; CCP_MSG_BAD_LOAD -- ASCIIZ console message 'Bad load'.
;   [RE] 2.20-44K twin CCP_MSG_BAD_LOAD (2.23 text lowercase 'Bad load').
; ----------------------------------------------------------------------
CCP_MSG_BAD_LOAD:
        DEFB    "Bad load"    ; $9A2C  string
        DEFB    $00    ; $9A34  terminator
; ----------------------------------------------------------------------
; CCP_COM_EXT -- the constant file-extension text 'COM' for transient loads (3 bytes, no
; terminator).
;   Copied into the FCB type field by CCP_CMD_TRANSIENT so the CCP opens NAME.COM.
;   [RE] 2.20-44K twin CCP_COM_EXT.
; ----------------------------------------------------------------------
CCP_COM_EXT:
        DEFB    "COM"    ; $9A35
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
        CALL CCP_RESTORE_DEFAULT_DRIVE                    ; $9A38  CD 07 97
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
        CALL CCP_PARSE_FCB1                    ; $9A3B  CD 2F 95
        LD A,(CCP_FCB_NAME)                    ; $9A3E  3A 87 9B
        SUB $20                          ; $9A41  D6 20
        LD HL,CCP_FCB_DRIVE_PREFIX                     ; $9A43  21 A9 9B
        OR (HL)                          ; $9A46  B6
        JP NZ,CCP_ECHO_TOKEN                   ; $9A47  C2 DF 94
        JP CCP_PROMPT_AND_READ                    ; $9A4A  C3 31 96
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
        LD A,(FASTLOAD_DRIVE_SAVE)                    ; $9A4D  3A 43 9B
; ----------------------------------------------------------------------
; FASTLOAD_SET_DRIVE -- select the drive in A via BDOS, used by the SoftCard fast-loader.
;   In: A = drive/parameter value.
;   Out: E:=A; tail-jump to the DRV_SET wrapper (BDOS_USERNUM = F_USERNUM/DRV path).
;   Clobbers: A, E.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23). Thin wrapper; exact BDOS function via BDOS_USERNUM.
; ----------------------------------------------------------------------
FASTLOAD_SET_DRIVE:
        LD E,A                           ; $9A50  5F
        JP BDOS_USERNUM                      ; $9A51  C3 F8 93
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
        LD HL,($F3DE)                    ; $9A54  2A DE F3
        ; self-modify the RPC dispatch's operand (LABEL+1) with the SoftCard control address
        LD (FASTLOAD_RPC_TRIGGER+1),HL             ; $9A57  22 26 9B
        XOR A                            ; $9A5A  AF
        LD (FASTLOAD_PASS_COUNT),A                    ; $9A5B  32 92 9B
        LD A,$11                         ; $9A5E  3E 11
        LD (FASTLOAD_LOAD_PAGE),A                    ; $9A60  32 41 9B
        ; DE = top of the request-list scratch area (just below the CCP at $9300)
        LD DE,$92FF                      ; $9A63  11 FF 92
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
        XOR A                            ; $9A66  AF
        LD (CCP_FCB_CR),A                    ; $9A67  32 A6 9B
        LD HL,CCP_FCB_SECOND                     ; $9A6A  21 96 9B
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
        LD A,(HL)                        ; $9A6D  7E
        OR A                             ; $9A6E  B7
        JR Z,FASTLOAD_PASS_CHECK                  ; $9A6F  28 06
        CALL FASTLOAD_EMIT_IOB                    ; $9A71  CD 8D 9A
        INC HL                           ; $9A74  23
        JR FASTLOAD_SCAN_DIRMAP                    ; $9A75  18 F6
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
        LD A,$A6                         ; $9A77  3E A6
        CP L                             ; $9A79  BD
        JP NZ,FASTLOAD_RPC_EXEC                 ; $9A7A  C2 82 9A
        CALL FASTLOAD_NEXT_DIR_ENTRY                    ; $9A7D  CD C8 9A
        JR NZ,FASTLOAD_BUILD_PASS                 ; $9A80  20 E4
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
        XOR A                            ; $9A82  AF
        LD (DE),A                        ; $9A83  12
        ; sort the queued block-read requests into ascending sector order (FASTLOAD_SORT_REQUESTS)
        CALL FASTLOAD_SORT_REQUESTS                    ; $9A84  CD D4 9A
        ; dispatch the sorted IOB request list to the 6502 RWTS via the $9B06 RPC entry
        CALL CCP_WBOOT                    ; $9A87  CD 06 9B
        ; join the standard launch path (CCP_LAUNCH_TRANSIENT) to build page zero and run
        JP CCP_LAUNCH_TRANSIENT                   ; $9A8A  C3 B8 99
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
        PUSH HL                          ; $9A8D  E5
        PUSH AF                          ; $9A8E  F5
        SRL A                            ; $9A8F  CB 3F
        SRL A                            ; $9A91  CB 3F
        ADD A,$03                        ; $9A93  C6 03
        LD (FASTLOAD_TRACK_TMP),A                    ; $9A95  32 42 9B
        POP AF                           ; $9A98  F1
        AND $03                          ; $9A99  E6 03
        ADD A,A                          ; $9A9B  87
        ADD A,A                          ; $9A9C  87
        ; SECTOR_SKEW_MAP: 16-entry logical->physical sector interleave table
        LD HL,SECTOR_SKEW_MAP                     ; $9A9D  21 31 9B
        ADD A,L                          ; $9AA0  85
        LD L,A                           ; $9AA1  6F
        JR NC,FASTLOAD_EMIT_IOB_1                 ; $9AA2  30 01
        INC H                            ; $9AA4  24
FASTLOAD_EMIT_IOB_1:
        LD B,$04                         ; $9AA5  06 04
FASTLOAD_EMIT_IOB_2:
        LD A,(FASTLOAD_TRACK_TMP)                    ; $9AA7  3A 42 9B
        LD (DE),A                        ; $9AAA  12
        DEC DE                           ; $9AAB  1B
        LD A,(HL)                        ; $9AAC  7E
        INC HL                           ; $9AAD  23
        LD (DE),A                        ; $9AAE  12
        DEC DE                           ; $9AAF  1B
        LD A,(FASTLOAD_LOAD_PAGE)                    ; $9AB0  3A 41 9B
        CP $A1                           ; $9AB3  FE A1
        JP Z,CCP_BAD_LOAD                 ; $9AB5  CA 24 9A
        ; load page reached $C0 (the $C000 I/O window): skip it
        CP $C0                           ; $9AB8  FE C0
        JR NZ,FASTLOAD_EMIT_IOB_3                 ; $9ABA  20 02
        ; bump the load page from $C0 to $D0 to step over the I/O window
        LD A,$D0                         ; $9ABC  3E D0
FASTLOAD_EMIT_IOB_3:
        LD (DE),A                        ; $9ABE  12
        INC A                            ; $9ABF  3C
        DEC DE                           ; $9AC0  1B
        LD (FASTLOAD_LOAD_PAGE),A                    ; $9AC1  32 41 9B
        DJNZ FASTLOAD_EMIT_IOB_2                  ; $9AC4  10 E1
        POP HL                           ; $9AC6  E1
        RET                              ; $9AC7  C9
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
        PUSH HL                          ; $9AC8  E5
        PUSH DE                          ; $9AC9  D5
        LD HL,FASTLOAD_PASS_COUNT                     ; $9ACA  21 92 9B
        INC (HL)                         ; $9ACD  34
        CALL CCP_OPEN_SUBMIT                    ; $9ACE  CD C6 93
        POP DE                           ; $9AD1  D1
        POP HL                           ; $9AD2  E1
        RET                              ; $9AD3  C9
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
        LD HL,$92FF                      ; $9AD4  21 FF 92
FASTLOAD_SORT_REQUESTS_1:
        LD D,H                           ; $9AD7  54
        LD E,L                           ; $9AD8  5D
FASTLOAD_SORT_REQUESTS_2:
        DEC DE                           ; $9AD9  1B
        DEC DE                           ; $9ADA  1B
        DEC DE                           ; $9ADB  1B
        LD A,(DE)                        ; $9ADC  1A
        OR A                             ; $9ADD  B7
        JR Z,FASTLOAD_SORT_REQUESTS_5                  ; $9ADE  28 1E
        CP (HL)                          ; $9AE0  BE
        JR C,FASTLOAD_SORT_REQUESTS_3                  ; $9AE1  38 0A
        JR NZ,FASTLOAD_SORT_REQUESTS_2                 ; $9AE3  20 F4
        DEC DE                           ; $9AE5  1B
        LD A,(DE)                        ; $9AE6  1A
        INC DE                           ; $9AE7  13
        DEC HL                           ; $9AE8  2B
        CP (HL)                          ; $9AE9  BE
        INC HL                           ; $9AEA  23
        JR NC,FASTLOAD_SORT_REQUESTS_2                 ; $9AEB  30 EC
FASTLOAD_SORT_REQUESTS_3:
        PUSH HL                          ; $9AED  E5
        PUSH DE                          ; $9AEE  D5
        LD B,$03                         ; $9AEF  06 03
FASTLOAD_SORT_REQUESTS_4:
        LD A,(DE)                        ; $9AF1  1A
        LD C,(HL)                        ; $9AF2  4E
        LD (HL),A                        ; $9AF3  77
        LD A,C                           ; $9AF4  79
        LD (DE),A                        ; $9AF5  12
        DEC HL                           ; $9AF6  2B
        DEC DE                           ; $9AF7  1B
        DJNZ FASTLOAD_SORT_REQUESTS_4                  ; $9AF8  10 F7
        POP DE                           ; $9AFA  D1
        POP HL                           ; $9AFB  E1
        JR FASTLOAD_SORT_REQUESTS_2                    ; $9AFC  18 DB
FASTLOAD_SORT_REQUESTS_5:
        DEC HL                           ; $9AFE  2B
        DEC HL                           ; $9AFF  2B
        DEC HL                           ; $9B00  2B
        LD A,(HL)                        ; $9B01  7E
        OR A                             ; $9B02  B7
        JR NZ,FASTLOAD_SORT_REQUESTS_1                 ; $9B03  20 D2
        RET                              ; $9B05  C9
        LD DE,$92FF                      ; $9B06  11 FF 92
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
        LD A,(DE)                        ; $9B09  1A
        OR A                             ; $9B0A  B7
        RET Z                            ; $9B0B  C8
        ; Z-80 $F3E0 = Apple $03E0 = IOB sector/load-address cell read by the 6502 RWTS
        LD ($F3E0),A                     ; $9B0C  32 E0 F3
        DEC DE                           ; $9B0F  1B
        LD A,(DE)                        ; $9B10  1A
        LD ($F3E1),A                     ; $9B11  32 E1 F3
        DEC DE                           ; $9B14  1B
        LD A,(DE)                        ; $9B15  1A
        LD ($F3E9),A                     ; $9B16  32 E9 F3
        DEC DE                           ; $9B19  1B
        LD A,$01                         ; $9B1A  3E 01
        ; Z-80 $F3EB = Apple $03EB = IOB command cell (1 = read)
        LD ($F3EB),A                     ; $9B1C  32 EB F3
        LD HL,$0E03                      ; $9B1F  21 03 0E
        ; Z-80 $F3D0 = Apple $03D0 = RPC command/params (deblock) mailbox
        LD ($F3D0),HL                    ; $9B22  22 D0 F3
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
        LD ($0000),A                     ; $9B25  32 00 00
        LD A,($F3EA)                     ; $9B28  3A EA F3
        OR A                             ; $9B2B  B7
        JR Z,FASTLOAD_DISPATCH_RPC                  ; $9B2C  28 DB
        JP CCP_LOAD_LOOP                   ; $9B2E  C3 93 99
; ----------------------------------------------------------------------
; SECTOR_SKEW_MAP -- 2.23-ONLY: 16-byte logical->physical sector interleave table for the
; fast-loader.
;   Bytes: 00 09 03 0C 06 0F 01 0A 04 0D 07 08 02 0B 05 0E -- the Apple DOS 3.3 sector skew, indexed
;          by
;   FASTLOAD_EMIT_IOB to issue block reads in physical order.
;   [RE] NO 2.20 EQUIVALENT (SoftCard 2.23 accelerated loader).
; ----------------------------------------------------------------------
SECTOR_SKEW_MAP:
        DEFB    $00,$09,$03,$0C,$06,$0F,$01,$0A,$04,$0D,$07,$08,$02,$0B,$05,$0E ; $9B31
; ----------------------------------------------------------------------
; FASTLOAD_LOAD_PAGE -- 2.23-ONLY: running load-page byte the fast-loader writes into successive IOB
;   records (advanced per block; steps $C0->$D0 over the I/O window).
;   [RE] NO 2.20 EQUIVALENT.
; ----------------------------------------------------------------------
FASTLOAD_LOAD_PAGE:
        DEFB    "\0"    ; $9B41
; ----------------------------------------------------------------------
; FASTLOAD_TRACK_TMP -- 2.23-ONLY: scratch track-ish value derived from the block number in
;   FASTLOAD_EMIT_IOB (SRL x2, +3) before it is written into the IOB record.
;   [RE] NO 2.20 EQUIVALENT.
; ----------------------------------------------------------------------
FASTLOAD_TRACK_TMP:
        DEFB    "\0"    ; $9B42
; ----------------------------------------------------------------------
; FASTLOAD_DRIVE_SAVE -- 2.23-ONLY: saved drive/parameter byte for the fast-loader / launch path,
;   reloaded by FASTLOAD_RESELECT_DRIVE. (33 reserved bytes here; the first is the live cell.)
;   [RE] partial -- the live use is the saved drive byte; the remaining reserved bytes are UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_DRIVE_SAVE:
        DEFS    33, $00    ; $9B43  fill
; ----------------------------------------------------------------------
; CCP_STACK_BASE -- top of the CCP private stack (SP is loaded here at warm start and after a
;   transient returns).
;   [RE] 2.20-44K twin equivalent (here it is the stack-base cell at $9B64).
; ----------------------------------------------------------------------
CCP_STACK_BASE:
        DEFB    "\0"    ; $9B64
; ----------------------------------------------------------------------
; CCP_SUB_FCB -- the FCB for the $$$.SUB batch (SUBMIT) file; name/ext constant '$$$     SUB'
; follows.
;   Opened/read/deleted by the CCP batch logic to source successive command lines.
;   [RE] 2.20-44K twin CCP_SUB_FCB.
; ----------------------------------------------------------------------
CCP_SUB_FCB:
        DEFB    "\0"    ; $9B65
        DEFB    "$$$     SUB"    ; $9B66  string
        DEFB    $00    ; $9B71  terminator
        DEFB    "\0"    ; $9B72
; ----------------------------------------------------------------------
; CCP_SUB_FCB_S2 -- the S2 (extent-high) field of the $$$.SUB FCB; cleared before reading the next
;   batch record.
;   [RE] 2.20-44K twin CCP_SUB_FCB_S2.
; ----------------------------------------------------------------------
CCP_SUB_FCB_S2:
        DEFB    "\0"    ; $9B73
; ----------------------------------------------------------------------
; CCP_SUB_FCB_CR -- the current-record (CR) field of the $$$.SUB FCB; the SUBMIT file is consumed in
;   reverse, so this is decremented to position the next read.
;   [RE] 2.20-44K twin CCP_SUB_FCB_CR (followed by reserved FCB bytes).
; ----------------------------------------------------------------------
CCP_SUB_FCB_CR:
        DEFS    17, $00    ; $9B74  fill
; ----------------------------------------------------------------------
; CCP_SUB_PREV_REC -- previous batch record index (cell just below the command FCB); receives
;   CCP_SUB_FCB_CR-1, the record to read next from $$$.SUB.
;   [RE] 2.20-44K twin CCP_SUB_PREV_REC.
; ----------------------------------------------------------------------
CCP_SUB_PREV_REC:
        DEFB    "\0"    ; $9B85
; ----------------------------------------------------------------------
; CCP_FCB -- the command-line FCB the CCP builds from the typed command (drive byte; name at
;   CCP_FCB_NAME, type at CCP_FCB_EXT). Copied to TFCB ($005C) before a transient runs.
;   [RE] 2.20-44K twin CCP_FCB.
; ----------------------------------------------------------------------
CCP_FCB:
        DEFB    "\0"    ; $9B86
; ----------------------------------------------------------------------
; CCP_FCB_NAME -- the 8-character filename field of the command FCB (parsed command word,
; blank-padded);
;   matched 4 chars at a time against the keyword table and used as the .COM filename.
;   [RE] 2.20-44K twin CCP_FCB_NAME.
; ----------------------------------------------------------------------
CCP_FCB_NAME:
        DEFS    8, $00    ; $9B87  fill
; ----------------------------------------------------------------------
; CCP_FCB_EXT -- the 3-character extension (type) field of the command FCB; must be blank for a bare
;   command word; the transient loader overwrites it with 'COM'.
;   [RE] 2.20-44K twin CCP_FCB_EXT.
; ----------------------------------------------------------------------
CCP_FCB_EXT:
        DEFB    "\0\0\0"    ; $9B8F
; ----------------------------------------------------------------------
; FASTLOAD_PASS_COUNT -- 2.23-ONLY: directory-pass counter for the fast-loader (incremented by
;   FASTLOAD_NEXT_DIR_ENTRY as it walks the file's extents). (4 reserved bytes here.)
;   [RE] NO 2.20 EQUIVALENT; exact width/use of the trailing bytes partly UNKNOWN.
; ----------------------------------------------------------------------
FASTLOAD_PASS_COUNT:
        DEFB    "\0\0\0\0"    ; $9B92
; ----------------------------------------------------------------------
; CCP_FCB_SECOND -- the second filename built into the command FCB at offset $10 (so the transient
;   receives two default FCBs at $005C/$006C). Also reused by the fast-loader as the 16-byte
;   allocation/directory map scratch.
;   [RE] 2.20-44K twin CCP_FCB_SECOND.
; ----------------------------------------------------------------------
CCP_FCB_SECOND:
        DEFS    16, $00    ; $9B96  fill
; ----------------------------------------------------------------------
; CCP_FCB_CR -- the current-record (CR) field of the command FCB; zeroed before each open/read so
;   loads start at record 0.
;   [RE] 2.20-44K twin CCP_FCB_CR.
; ----------------------------------------------------------------------
CCP_FCB_CR:
        DEFB    "\0"    ; $9BA6
; ----------------------------------------------------------------------
; CCP_BDOS_RESULT -- saved A return code from the most recent BDOS file call
; (open/close/search/make);
;   the wrapper saves A here then INC A so the caller can test the $FF not-found code as zero.
;   [RE] 2.20-44K twin CCP_BDOS_RESULT.
; ----------------------------------------------------------------------
CCP_BDOS_RESULT:
        DEFB    "\0"    ; $9BA7
; ----------------------------------------------------------------------
; CCP_CUR_DRIVE -- the CCP's current default drive number (0=A,1=B,...); written to the low nibble
; of
;   page-zero $0004 and reselected after every transient runs.
;   [RE] 2.20-44K twin CCP_CUR_DRIVE (NOT the user number, which lives in the BDOS).
; ----------------------------------------------------------------------
CCP_CUR_DRIVE:
        DEFB    "\0"    ; $9BA8
; ----------------------------------------------------------------------
; CCP_FCB_DRIVE_PREFIX -- explicit drive-prefix flag for the parsed command (0 = no 'd:' prefix,
; else
;   drive#+1). A non-zero value routes the dispatcher to CCP_DRIVE_SELECT (slot 6).
;   [RE] 2.20-44K twin CCP_FCB_DRIVE_PREFIX.
; ----------------------------------------------------------------------
CCP_FCB_DRIVE_PREFIX:
        DEFB    "\0"    ; $9BA9
; ----------------------------------------------------------------------
; CCP_TYPE_REC_INDEX -- TYPE's per-record byte index (advanced 0..$80 by TYPE_EMIT_CHAR; primed to
;   $FF to force the first record read). Followed by 86 reserved/scratch bytes up to the CCP top.
;   [RE] 2.20-44K twin (the CCP_FCB_TAIL / TYPE counter region).
; ----------------------------------------------------------------------
CCP_TYPE_REC_INDEX:
        DEFS    86, $00    ; $9BAA  fill
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9300, $0900
    ENDIF
