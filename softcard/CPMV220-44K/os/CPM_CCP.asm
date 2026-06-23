; ============================================================================
; Microsoft SoftCard CP/M 2.20 (44K) -- staged System Image (CCP + BDOS)
; ----------------------------------------------------------------------------
; Reverse-engineered from the raw on-disk bytes (sysimg_220_44k.bin), exactly
; the 5888 bytes that load at $9300. Reassembles BYTE-IDENTICAL.
;
; Runtime layout (BIOS jump table at staging offset $1700 == $AA00):
;   $9300-$93FF  Pre-CCP / serial page (parser delimiter helpers + 6502 block)
;   $9400-$94FC  Embedded 6502 RPC payload -- LDA/STA against the I/O Config
;                Block cells ($03E0-$03EB) + JSR $0Exx + RTS. This is 6502
;                machine code carried inside the Z-80 image; the SoftCard runs
;                it on the 6502 side via the CPU-switch RPC, so from the Z-80's
;                view it is DATA (decoding it as Z-80 is garbage). See the
;                CALL $94xx fan-in from the CCP -- those reference 6502 entries.
;   $9400-$9CFF  CCP -- command line parse, built-in table (DIR ERA TYPE SAVE
;                REN USER), 8-word dispatch table at $95C2, transient .COM
;                loader, $$$.SUB chaining ($$$ is a standard CP/M file type
;                [DOC CPMREF 3-45 ; facts sec.7.7]), and the CP/M error texts.
;   $9D00-$A8FF  BDOS (Microsoft SoftCard BDOS) -- function entry $9E16 (the
;                referenced re-entry: save caller SP, switch to local stack,
;                dispatch on C via the runtime pointer cell $9F43); $9E09-$9E15
;                is data. FCB/directory/disk-record logic follows.
;   $A900-$A9FF  BDOS variable + buffer page; $E5 (uninitialized) on disk.
;
; Message mechanism (prior finding, confirmed): the error texts are reached two
; ways. Pointer form -- LD BC,<msg>; (CALL/JP print) -- for NO SPACE / FILE
; EXISTS / BAD LOAD (the LD BC targets the string head). Computed/position form
; for READ ERROR / NO FILE / ALL (Y/N)? -- the locator references an INTERIOR
; offset of the text (e.g. CALL $9854 lands inside "ALL (Y/N)?"), which is why
; those targets read as mid-string addresses, not labels.
;
; Address facts cross-checked against the 2.20 manual reconcile sheet:
; CCP=$9400, BDOS=$9C00-region, I/O Config Block at 6502 $0200-$03FF (Z-80
; $F200-$F3FF), 6502 RPC cells $45-$49, A$VEC=$F3D0, Z$CPU=$F3DE.
;
; Clean-room: decompiled solely from these bytes + public CP/M 2.2 architecture
; and softcard/docs/CPM_Manual_Reconcile_Facts.md -- no 56K/2.23 source. The
; code/data split was adversarially verified and reassembles BYTE-IDENTICAL;
; comment PROSE is [AI] machine-inferred (a hint, not a manual citation) unless
; marked [DOC <manual> <page>]; [?] = open question.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ENDIF

; -- External symbols --
BDOS_DISPATCH_PTR    EQU $9F43               ; runtime pointer cell used by the BDOS function dispatch

; -- Mid-instruction references (shown inline as cover+offset) --
;   $9504 -> FCB_WILDCARD_TEST+1         shared instruction tail: $9504 is reachable code inside the instruction at $9503
;   $9539 -> SEARCH_BUILTIN_1+2         z80 skip idiom: enters the operand of $11 at $9537
;   $95DD -> RPC_CALL_HL_2+1         shared instruction tail: $95DD is reachable code inside the instruction at $95DC
;   $95FD -> CHECK_DRIVE_ERR_2+2         shared instruction tail: $95FD is reachable code inside the instruction at $95FB
;   $961E -> RST_TABLE_9609_3+1         shared instruction tail: $961E is reachable code inside the instruction at $961D
;   $9660 -> RPC_DISPATCH_1+1         shared instruction tail: $9660 is reachable code inside the instruction at $965F
;   $9690 -> RPC_DISPATCH_8+1         shared instruction tail: $9690 is reachable code inside the instruction at $968F
;   $96A1 -> RPC_DISPATCH_11+2        z80 skip idiom: enters the operand of $11 at $969F
;   $96A9 -> RPC_DISPATCH_13+1        z80 skip idiom: enters the operand of $11 at $96A8
;   $96C8 -> RPC_DISPATCH_18+1        z80 skip idiom: enters the operand of $01 at $96C7
;   $96DF -> RPC_DISPATCH_22+1        shared instruction tail: $96DF is reachable code inside the instruction at $96DE
;   $96E9 -> RPC_DISPATCH_23+1        shared instruction tail: $96E9 is reachable code inside the instruction at $96E8
;   $973C -> FCB_FIELD_BLANKS_LOOP+1         shared instruction tail: $973C is reachable code inside the instruction at $973B
;   $9782 -> DIR_CMD_1+1        shared instruction tail: $9782 is reachable code inside the instruction at $9781
;   $97EA -> DIR_EMIT_NAME_CHAR_1+2         shared instruction tail: $97EA is reachable code inside the instruction at $97E8
;   $97F8 -> DIR_EMIT_NAME_CHAR_2+1         z80 skip idiom: enters the operand of $3E at $97F7
;   $9840 -> DIR_EMIT_NAME_CHAR_8+1         shared instruction tail: $9840 is reachable code inside the instruction at $983F
;   $9898 -> CMD_EXEC_2+1         shared instruction tail: $9898 is reachable code inside the instruction at $9897
;   $98F9 -> CMD_EXEC_10+1        shared instruction tail: $98F9 is reachable code inside the instruction at $98F8
;   $990E -> CMD_EXEC_13+2        shared instruction tail: $990E is reachable code inside the instruction at $990C
;   $9974 -> FCB_CLEAR_BYTE_PAD+2        shared instruction tail: $9974 is reachable code inside the instruction at $9972
;   $99A0 -> RECORD_SCAN_BODY+2        shared instruction tail: $99A0 is reachable code inside the instruction at $999E
;   $99A7 -> RECORD_SCAN_STEP+2        shared instruction tail: $99A7 is reachable code inside the instruction at $99A5
;   $99F1 -> DISK_BUF_MOVE_GO+1        shared instruction tail: $99F1 is reachable code inside the instruction at $99F0
;   $9B30 -> CMD_EXEC_55+2        shared instruction tail: $9B30 is reachable code inside the instruction at $9B2E
;   $9B4F -> CMD_EXEC_59+1        shared instruction tail: $9B4F is reachable code inside the instruction at $9B4E
;   $9B86 -> CMD_EXEC_63+1        shared instruction tail: $9B86 is reachable code inside the instruction at $9B85
;   $9BD6 -> CMD_EXEC_67+2        shared instruction tail: $9BD6 is reachable code inside the instruction at $9BD4
;   $9BDD -> CMD_EXEC_68+2        shared instruction tail: $9BDD is reachable code inside the instruction at $9BDB
;   $9BF1 -> CMD_EXEC_69+2        shared instruction tail: $9BF1 is reachable code inside the instruction at $9BEF
;   $9C0B -> CCP_TAIL_LOADRET_p8_STG+2        shared instruction tail: $9C0B is reachable code inside the instruction at $9C09
;   $9C47 -> CCP_TAIL_CMDTAIL_p8_STG+1        shared instruction tail: $9C47 is reachable code inside the instruction at $9C46
;   $9D23 -> CCP_TAIL_CMDTAIL_p227_STG+2         shared instruction tail: $9D23 is reachable code inside the instruction at $9D21
;   $9D45 -> CCP_TAIL_4_STG+2         shared instruction tail: $9D45 is reachable code inside the instruction at $9D43
;   $9D48 -> CCP_TAIL_4_p4_STG+1         shared instruction tail: $9D48 is reachable code inside the instruction at $9D47
;   $9D62 -> CCP_TAIL_5_p20_STG+1         shared instruction tail: $9D62 is reachable code inside the instruction at $9D61
;   $9D96 -> CCP_TAIL_9_STG+2         shared instruction tail: $9D96 is reachable code inside the instruction at $9D94
;   $9DAC -> CCP_TAIL_12_STG+1         shared instruction tail: $9DAC is reachable code inside the instruction at $9DAB
;   $9DB1 -> CCP_TAIL_12_p5_STG+1         shared instruction tail: $9DB1 is reachable code inside the instruction at $9DB0
;   $9DB9 -> CCP_TAIL_12_p13_STG+1         shared instruction tail: $9DB9 is reachable code inside the instruction at $9DB8
;   $9DC9 -> CCP_TAIL_13_p10_STG+1         shared instruction tail: $9DC9 is reachable code inside the instruction at $9DC8
;   $9DD3 -> CCP_TAIL_14_p5_STG+2         shared instruction tail: $9DD3 is reachable code inside the instruction at $9DD1
;   $9DE1 -> CCP_TAIL_10_p3_STG+1         shared instruction tail: $9DE1 is reachable code inside the instruction at $9DE0
;   $9DEF -> CCP_TAIL_16_STG+1         shared instruction tail: $9DEF is reachable code inside the instruction at $9DEE
;   $9E1C -> BDOS_ENTRY_p9_STG+2        z80 skip idiom: enters the operand of $21 at $9E1A
;   $9E26 -> BDOS_ENTRY_p19_STG+2        shared instruction tail: $9E26 is reachable code inside the instruction at $9E24
;   $9E4E -> BDOS_ENTRY_p60_STG+1        shared instruction tail: $9E4E is reachable code inside the instruction at $9E4D
;   $9E78 -> BDOS_ENTRY_p102_STG+1        shared instruction tail: $9E78 is reachable code inside the instruction at $9E77
;   $9EA6 -> BDOS_ERROR_SELECT_STG+1        z80 skip idiom: enters the operand of $21 at $9EA5
;   $9EA9 -> BDOS_ERROR_SELECT_p3_STG+1        shared instruction tail: $9EA9 is reachable code inside the instruction at $9EA8
;   $9F05 -> FCB_SEQ_IO_STEP_1_STG+1        shared instruction tail: $9F05 is reachable code inside the instruction at $9F04
;   $9F45 -> FCB_SEQ_IO_STEP_8_STG+1        shared instruction tail: $9F45 is reachable code inside the instruction at $9F44
;   $9F47 -> FCB_SEQ_IO_STEP_8_p2_STG+1        shared instruction tail: $9F47 is reachable code inside the instruction at $9F46
;   $9F4A -> CONOUT_PUTC_STG+2        shared instruction tail: $9F4A is reachable code inside the instruction at $9F48
;   $9F4F -> CONOUT_PUTC_p6_STG+1        shared instruction tail: $9F4F is reachable code inside the instruction at $9F4E
;   $9F50 -> CONOUT_PUTC_p6_STG+2        shared instruction tail: $9F50 is reachable code inside the instruction at $9F4E
;   $9FB2 -> BDOS_CON_7_STG+2         shared instruction tail: $9FB2 is reachable code inside the instruction at $9FB0
;   $9FC3 -> BDOS_CON_8_p10_STG+1         shared instruction tail: $9FC3 is reachable code inside the instruction at $9FC2
;   $9FE4 -> BDOS_READ_CON_BUF_p1_STG+2         shared instruction tail: $9FE4 is reachable code inside the instruction at $9FE2
;   $9FFA -> BDOS_CON_14_p8_STG+1         shared instruction tail: $9FFA is reachable code inside the instruction at $9FF9
;   $A03E -> BDOS_CON_20_p8_STG+1         shared instruction tail: $A03E is reachable code inside the instruction at $A03D
;   $A05C -> CON_PUT_COL_1_p14_STG+2        shared instruction tail: $A05C is reachable code inside the instruction at $A05A
;   $A084 -> BDOS_CON_29_p4_STG+1         shared instruction tail: $A084 is reachable code inside the instruction at $A083
;   $A08A -> BDOS_CON_30_STG+1         shared instruction tail: $A08A is reachable code inside the instruction at $A089
;   $A0A6 -> BDOS_CON_32_STG+2         shared instruction tail: $A0A6 is reachable code inside the instruction at $A0A4
;   $A0BB -> BDOS_CON_34_p8_STG+2         shared instruction tail: $A0BB is reachable code inside the instruction at $A0B9
;   $A0D2 -> BDOS_READER_INPUT_p2_STG+2         shared instruction tail: $A0D2 is reachable code inside the instruction at $A0D0
;   $A104 -> BDOS_RET_RESULT_1_STG+1         z80 skip idiom: enters the operand of $01 at $A103
;   $A105 -> BDOS_RET_RESULT_1_STG+2         z80 skip idiom: enters the operand of $01 at $A103
;   $A11E -> BDOS_SAVED_SP_p13_STG+2         shared instruction tail: $A11E is reachable code inside the instruction at $A11C
;   $A12C -> BDOS_CON_49_p7_STG+1         z80 skip idiom: enters the operand of $21 at $A12B
;   $A144 -> BDOS_DE_PARAM_STG+1         shared instruction tail: $A144 is reachable code inside the instruction at $A143
;   $A169 -> FCB_SET_REC_FLAG_3_p14_STG+1         z80 skip idiom: enters the operand of $01 at $A168
;   $A172 -> FCB_SET_REC_FLAG_3_p23_STG+1         shared instruction tail: $A172 is reachable code inside the instruction at $A171
;   $A17F -> FCB_SET_REC_FLAG_3_p35_STG+2         shared instruction tail: $A17F is reachable code inside the instruction at $A17D
;   $A18C -> FCB_SET_REC_FLAG_4_p8_STG+1         shared instruction tail: $A18C is reachable code inside the instruction at $A18B
;   $A195 -> FCB_SET_REC_FLAG_5_STG+2         shared instruction tail: $A195 is reachable code inside the instruction at $A193
;   $A19E -> FCB_SET_REC_FLAG_6_STG+1         shared instruction tail: $A19E is reachable code inside the instruction at $A19D
;   $A1C4 -> DISK_READ_RECORD_STG+1         shared instruction tail: $A1C4 is reachable code inside the instruction at $A1C3
;   $A1D4 -> DISK_READ_RECORD_1_p3_STG+1         shared instruction tail: $A1D4 is reachable code inside the instruction at $A1D3
;   $A1DA -> DISK_READ_RECORD_1_p8_STG+2         shared instruction tail: $A1DA is reachable code inside the instruction at $A1D8
;   $A1E0 -> DISK_READ_RECORD_1_p15_STG+1         shared instruction tail: $A1E0 is reachable code inside the instruction at $A1DF
;   $A205 -> READ_CON_BUF_EDIT_p6_STG+1         shared instruction tail: $A205 is reachable code inside the instruction at $A204
;   $A219 -> READ_CON_BUF_EDIT_2_p2_STG+1         shared instruction tail: $A219 is reachable code inside the instruction at $A218
;   $A235 -> READ_CON_BUF_EDIT_4_STG+1         shared instruction tail: $A235 is reachable code inside the instruction at $A234
;   $A256 -> READ_CON_BUF_EDIT_9_p4_STG+1         shared instruction tail: $A256 is reachable code inside the instruction at $A255
;   $A288 -> FCB_NAME_MATCH_REC_1_p5_STG+1         shared instruction tail: $A288 is reachable code inside the instruction at $A287
;   $A29D -> DIR_NEXT_ENTRY_1_p13_STG+1         z80 skip idiom: enters the operand of $21 at $A29C
;   $A2D2 -> FCB_CMP_DIR_ENTRY_5_STG+1        shared instruction tail: $A2D2 is reachable code inside the instruction at $A2D1
;   $A307 -> BDOS_DCIO_3_STG+2        shared instruction tail: $A307 is reachable code inside the instruction at $A305
;   $A318 -> DIR_SEARCH_STEP_p12_STG+1        shared instruction tail: $A318 is reachable code inside the instruction at $A317
;   $A34A -> DIR_SEARCH_STEP_4_STG+2         shared instruction tail: $A34A is reachable code inside the instruction at $A348
;   $A394 -> DISK_DEBLOCK_p6_STG+2         shared instruction tail: $A394 is reachable code inside the instruction at $A392
;   $A39C -> DISK_DEBLOCK_p14_STG+2         shared instruction tail: $A39C is reachable code inside the instruction at $A39A
;   $A3A4 -> DISK_DEBLOCK_p22_STG+2         shared instruction tail: $A3A4 is reachable code inside the instruction at $A3A2
;   $A3D1 -> DISK_DEBLOCK_1_p12_STG+1         shared instruction tail: $A3D1 is reachable code inside the instruction at $A3D0
;   $A3F4 -> DISK_DEBLOCK_4_p9_STG+2         z80 skip idiom: enters the operand of $21 at $A3F2
;   $A3FD -> BDOS_CHECK_ERROR_p6_STG+2         shared instruction tail: $A3FD is reachable code inside the instruction at $A3FB
;   $A45A -> BDOS_RANDREC_3_STG+1         shared instruction tail: $A45A is reachable code inside the instruction at $A459
;   $A494 -> BDOS_RANDREC_5_p39_STG+2         z80 skip idiom: enters the operand of $21 at $A492
;   $A4A2 -> BDOS_RANDREC_6_STG+1         shared instruction tail: $A4A2 is reachable code inside the instruction at $A4A1
;   $A4FD -> BDOS_RANDREC_14_p1_STG+2        shared instruction tail: $A4FD is reachable code inside the instruction at $A4FB
;   $A546 -> FCB_EXTENT_TO_TRKSEC_1_p25_STG+2         shared instruction tail: $A546 is reachable code inside the instruction at $A544
;   $A583 -> FCB_EXTENT_TO_TRKSEC_6_STG+2         shared instruction tail: $A583 is reachable code inside the instruction at $A581
;   $A58E -> FCB_EXTENT_TO_TRKSEC_7_p9_STG+1         shared instruction tail: $A58E is reachable code inside the instruction at $A58D
;   $A5AC -> FCB_ALLOC_PREP_p5_STG+2         z80 skip idiom: enters the operand of $21 at $A5AA
;   $A5E6 -> FCB_ALLOC_BLOCK_NUM_2_p18_STG+2         shared instruction tail: $A5E6 is reachable code inside the instruction at $A5E4
;   $A66C -> DISK_STORE_SEC_TRK_11_p4_STG+2         shared instruction tail: $A66C is reachable code inside the instruction at $A66A
;   $A68C -> DISK_STORE_SEC_TRK_17_STG+2        shared instruction tail: $A68C is reachable code inside the instruction at $A68A
;   $A69A -> DISK_STORE_SEC_TRK_19_p6_STG+2        shared instruction tail: $A69A is reachable code inside the instruction at $A698
;   $A707 -> DRV_INSTALL_RWTS_12_p9_STG+1         shared instruction tail: $A707 is reachable code inside the instruction at $A706
;   $A747 -> DISK_SEEK_TRACK_1_STG+2         shared instruction tail: $A747 is reachable code inside the instruction at $A745
;   $A77F -> DIR_NAME_MASK_1_STG+1         z80 skip idiom: enters the operand of $3E at $A77E
;   $A784 -> DIR_NAME_MASK_2_STG+1         z80 skip idiom: enters the operand of $21 at $A783
;   $A78B -> DIR_NAME_MASK_2_p6_STG+2        shared instruction tail: $A78B is reachable code inside the instruction at $A789
;   $A7D2 -> DIR_NAME_MASK_11_p9_STG+1         shared instruction tail: $A7D2 is reachable code inside the instruction at $A7D1
;   $A7E4 -> DIR_NAME_MASK_13_p3_STG+1         shared instruction tail: $A7E4 is reachable code inside the instruction at $A7E3
;   $A80C -> DIR_NAME_MASK_21_p1_STG+1        shared instruction tail: $A80C is reachable code inside the instruction at $A80B
;   $A821 -> DIR_NAME_MASK_25_p3_STG+1        shared instruction tail: $A821 is reachable code inside the instruction at $A820
;   $A845 -> DIR_NAME_MASK_31_p3_STG+1        shared instruction tail: $A845 is reachable code inside the instruction at $A844
;   $A851 -> DIR_NAME_MASK_33_p3_STG+1        shared instruction tail: $A851 is reachable code inside the instruction at $A850
;   $A875 -> DIR_NAME_MASK_38_STG+1        shared instruction tail: $A875 is reachable code inside the instruction at $A874

    IFNDEF CPM_LINK
        INCLUDE "cpm22.inc"
    ORG $9300
    ENDIF


; ----------------------------------------------------------------------
; PRE_CCP_FRAGMENT_9300 -- image-base bytes; NOT confirmed executable code [UNKNOWN]. $9300, 0
; static referrers, file's only RST $08; JP target $95FD lands mid-instruction (inside LD A,($9BF0)
; at $95FB). Likely not Z-80 code.
; ----------------------------------------------------------------------
PRE_CCP_FRAGMENT_9300:
        RST $08
        SUB A
        INC DE
        INC HL
        DEC B
        ; [FLAG] $95FD lands mid-instruction (inside LD A,($9BF0) at $95FB) -- data-as-code
        JP NZ,CHECK_DRIVE_ERR_2+2
        RET
; ----------------------------------------------------------------------
; ECHO_TO_BLANK -- echo the PARSE_PTR2 token to the console (CONOUT E08C) up to a blank/NUL, then
; tail-jump to the shared RET ($9622); else INC HL, re-enter scan continuation $960F. E098 fires
; once at entry. $960F/$9622 in the RST-dispatch cluster (mis-decode owned there).
; ----------------------------------------------------------------------
ECHO_TO_BLANK:
        CALL RPC6502_E098
        LD HL,(PARSE_PTR2)
        LD A,(HL)
        CP ' '
        JP Z,RST_TABLE_9609_4
        OR A
        JP Z,RST_TABLE_9609_4
        PUSH HL
        CALL RPC6502_E08C
        POP HL
        INC HL
        ; re-enter scan continuation ($960F) for the next char
        JP RST_TABLE_9609_1
; ----------------------------------------------------------------------
; PARSE_BADCHAR -- report a bad command by emitting '?' (CONOUT E08C), run E098, then CALL/JP into
; the shared error path ($95DD / $9782). '?' emission OBSERVED.
; ----------------------------------------------------------------------
PARSE_BADCHAR:
        LD A,'?'
        CALL RPC6502_E08C
        CALL RPC6502_E098
        ; [FLAG] shared error/print path; $95DD lands mid-instruction (inside JP RPC6502_E0A7 at
        ; $95DC)
        CALL RPC_CALL_HL_2+1
        ; [FLAG] $9782 is the operand of the FE-20 (CP $20) cover at DIR_CMD_1 ($9781), a
        ; cover-idiom entry into DIR_CMD code (NOT a message pointer)
        JP DIR_CMD_1+1
; ----------------------------------------------------------------------
; SCAN_DELIM -- classify the byte at (DE) against the CP/M command-line delimiter set. Out: Z if
; (DE) is NUL or a delimiter, else NZ. A control char (below space) aborts to $9609. The eight
; tested chars are exactly the CP/M 2.2 delimiters (space = _ . : ; < >).
; ----------------------------------------------------------------------
SCAN_DELIM:
        LD A,(DE)
        OR A
        RET Z
        CP ' '
        ; [FLAG] control chars (below space) illegal -> abort to the error handler ($9609)
        JP C,RST_TABLE_9609
        RET Z
        CP '='
        RET Z
        CP '_'
        RET Z
        CP '.'
        RET Z
        CP ':'
        RET Z
        CP ';'                           ; $9345  FE 3B
        RET Z
        CP '<'
        RET Z
        CP '>'
        RET Z
        RET
; ----------------------------------------------------------------------
; SKIP_ONE_BLANK -- skip a single leading blank then chain to the scanner at $964F. NUL->RET Z;
; non-blank->RET NZ; blank->INC DE + JP $964F. $964F in the RST-dispatch cluster (mis-decode; also
; CALLed from BUILD_FCB $9370). The 7 bytes at $9359 are a separate recovered helper (see SPLITs).
; ----------------------------------------------------------------------
SKIP_ONE_BLANK:
        LD A,(DE)
        OR A
        RET Z
        CP ' '
        RET NZ
        INC DE
        ; continue scanning to the next non-blank token ($964F)
        JP RST_TABLE_964F
        DEFB    $85
        DEFB    $6F,$D0,$24,$C9,$3E,$00  ; "oP$I>"
; ----------------------------------------------------------------------
; BUILD_FCB -- [RE] parse the optional leading drive specifier ("X:") of one command-line filename
; token into the CCP-local File Control Block. SEE CAVEAT: as decoded this routine cannot be the
; LIVE parser (every exit targets the 6502 region); the FCB-parser reading is a strong [RE]
; inference from the byte patterns, the precise control flow is NOT established.
;   In:        PARSE_PTR ($9488, a cell inside the 6502 RPC block) holds the live command-line scan
;              cursor; CMD_EXEC_69 ($9BEF, a CCP workspace byte that elsewhere also coincides with a
;              JP opcode in the loaded image -- reused RAM) holds the current default-drive code. HL
;              is set internally to the FCB build buffer at $9BCD.
;   Out:       [RE] FCB.DR (byte 0 of the $9BCD buffer) set to a drive code; the $9BF0 flag cell
;              cleared on entry; PARSE_PTR2 ($948A) set to the blank-skipped token start. On the
;              no-explicit-drive path the default drive (CMD_EXEC_69) is stored to FCB.DR.
;   Clobbers:  A, B, DE, HL, flag cell $9BF0; pushes HL (the FCB base) twice on entry (matching the
;              POP HL in the parse routines).
;   Algorithm: [RE] Set HL = FCB buffer $9BCD and PUSH it twice. Clear the $9BF0 flag. Skip leading
;              blanks via the $964F RPC service and record the token start in PARSE_PTR2. Read the
;              first token byte: if NUL, the line is empty. Otherwise tentatively treat it as a
;              drive letter (B = char - '@' gives 1..26 for A..Z, with carry clear from the
;              preceding OR A) and peek the following byte: if ':' an explicit drive prefix was
;              present; if not, back up (DEC DE) and store the default drive (CMD_EXEC_69) into
;              FCB.DR.
;   CAVEAT (verified against sysimg_220_44k.bin, base $9300): EVERY conditional/unconditional exit
;   of this routine (JP Z RPC_DISPATCH_7=$9689, JP Z RPC_DISPATCH_8+1=$9690, JP
;   RPC_DISPATCH_9=$9696) targets the $9685-$96FF range, which disassembles as COHERENT 6502 code
;   (config-block stores STA $03C7/STA $03DE, JSR $FDED=COUT, JMP $FF65=MONZ, and a JMP-$AA00
;   trampoline builder LDA #$C3/STA $1000 ...), NOT Z-80. Likewise CALL RPC_DISPATCH_SETUP=$9659,
;   CALL RST_TABLE_964F=$964F, CALL RST_TABLE_9630=$9630 all enter that 6502 region. So those
;   targets are an UN-extracted embedded-6502 RPC service (the same kind already INCBIN'd at
;   $9400-$94FF), mis-rendered as Z-80; their Z-80 meaning is UNKNOWN and they are NOT relocated
;   here. Do NOT read the named '_8+1'/'_9' targets as the BUILD_FCB_NAME/BUILD_FCB_* routines that
;   follow at $9390+ -- they are different addresses in the 6502 page. See summary.
; ----------------------------------------------------------------------
BUILD_FCB:
        ; [RE] point HL at the CCP-local File Control Block build buffer ($9BCD); byte 0 = FCB.DR,
        ; bytes 1-8 the name (CPMFCB.F), bytes 9-11 the type/extension (CPMFCB.T)
        LD HL,$9BCD
        ; [RE] hand off to the 6502 via the SoftCard CPU switch (target $9659 is in the un-extracted
        ; 6502 RPC region); exact service UNKNOWN as Z-80
        CALL RPC_DISPATCH_SETUP
        ; save the FCB buffer base twice so the parse code can restore it with POP HL
        PUSH HL
        PUSH HL
        ; A=0, about to clear the $9BF0 drive-seen flag (no explicit drive yet)
        XOR A
        LD ($9BF0),A
        ; [RE] load the live command-line scan cursor (PARSE_PTR, a cell inside the 6502 RPC block)
        ; for the byte fetches below
        LD HL,(PARSE_PTR)
        EX DE,HL
        ; [RE] skip leading blanks via the $964F 6502 RPC service (target is in the un-extracted
        ; 6502 region); returns the cursor past the whitespace
        CALL RST_TABLE_964F
        EX DE,HL
        ; record the blank-skipped token start in PARSE_PTR2 ($948A, a cell in the 6502 block)
        LD (PARSE_PTR2),HL
        EX DE,HL
        POP HL
        ; read the first token character; if zero the command line is empty
        LD A,(DE)
        OR A
        JP Z,RPC_DISPATCH_7
        ; [RE] tentatively convert a drive letter to a 1-based index: with carry clear (from OR A),
        ; 'A'($41)-'@'($40)=1 ... 'P'=16 ... 'Z'=26; only meaningful if the next char is ':'
        SBC A,'@'
        LD B,A
        INC DE
        LD A,(DE)
        ; [RE] is the second character ':'? if so the token began with an explicit drive specifier
        ; "X:"
        CP ':'
        JP Z,RPC_DISPATCH_8+1
        ; no ':' -- ordinary filename; back the cursor up over the char read as the would-be ':'
        DEC DE
        ; [RE] no explicit drive: take the CCP current default drive from workspace cell $9BEF (this
        ; byte coincides with a JP opcode in the loaded image elsewhere -- reused RAM, read here as
        ; a data byte)
        LD A,(CMD_EXEC_69)
        ; [RE] store the default drive code into FCB.DR (byte 0 of the $9BCD buffer)
        LD (HL),A
        JP RPC_DISPATCH_9
; ----------------------------------------------------------------------
; BUILD_FCB_NAME -- [RE] begin filling the 8-character name field (CPMFCB.F) of the FCB from the
; command line. SEE the BUILD_FCB CAVEAT: this fragment cannot run as live Z-80 as decoded (all its
; branches/CALLs target the 6502 region); the name-field reading is a [RE] inference from the byte
; patterns.
;   In:        B = drive code (on the explicit "X:" path); HL = FCB.DR slot; DE = command-line
;              cursor at the first name character. The $9630 reference is a 6502 RPC service
;              (returns the next significant token character; Z at a terminator) -- not a Z-80
;              subroutine.
;   Out:       [RE] drive recorded in $9BF0 and stored to FCB.DR; B reloaded to 8 (name-field
;              width); first name character classified ('*' wildcard vs literal).
;   Clobbers:  A, B, HL, flag cell $9BF0.
;   Algorithm: [RE] Record the drive in $9BF0 and store it to FCB.DR. Set the field counter B = 8.
;              Obtain the next character via the $9630 6502 RPC; classify '*' (expand to '?' fill)
;              vs a literal name character.
;   CAVEAT: the branch targets (RPC_DISPATCH_16=$96B9, RPC_DISPATCH_13+1=$96A9,
;           RPC_DISPATCH_14=$96AB) and CALL $9630 all land in the $96xx 6502 region (mis-rendered as
;           Z-80); their Z-80 meaning is UNKNOWN and they are NOT relocated. Do NOT equate these
;           named targets with BUILD_FCB_NAME_CH/_PAD -- those are at different $93xx addresses. See
;           summary.
; ----------------------------------------------------------------------
BUILD_FCB_NAME:
        ; [RE] copy the drive code to record it in the flag cell and store it into the FCB
        LD A,B
        ; [RE] remember the parsed drive in the $9BF0 flag cell (non-zero => an explicit drive was
        ; given)
        LD ($9BF0),A
        ; [RE] store the drive code into FCB.DR (byte 0 of the $9BCD buffer)
        LD (HL),B
        INC DE
        ; set the field counter to 8 -- the width of the CP/M FCB name field (CPMFCB.F, F1-F8)
        LD B,$08
        ; [RE] fetch the next token character via the $9630 6502 RPC service (Z at a name-field
        ; terminator); target is in the un-extracted 6502 region
        CALL RST_TABLE_9630
        JP Z,RPC_DISPATCH_16
        INC HL
        ; [RE] is this character '*'? a '*' wildcard expands to '?' fill for the rest of the field
        CP '*'
        JP NZ,RPC_DISPATCH_13+1
        ; [RE] '*' seen: write a '?' wildcard into this name byte
        LD (HL),'?'
        JP RPC_DISPATCH_14
; ----------------------------------------------------------------------
; BUILD_FCB_NAME_CH -- [RE] store-and-advance loop body for one name character of the 8-char FCB
; name field. SEE the BUILD_FCB CAVEAT: cannot run as live Z-80 as decoded (its branches/CALL target
; the 6502 region).
;   In:        A = the character to store; HL = current FCB name byte; DE = command-line cursor; B =
;              remaining name-field count.
;   Out:       [RE] character written to (HL); DE advanced; B decremented; on field full, the next
;              character requested via the $9630 6502 RPC.
;   Clobbers:  A, B, DE, HL.
;   Algorithm: [RE] Write the character into the FCB name field, advance the cursor, decrement the
;              counter; loop while not full. When the 8 bytes are consumed, request the next token
;              character via the $9630 RPC to decide name-vs-extension.
;   CAVEAT: the branch/loop targets (RPC_DISPATCH_10=$9698, _17=$96C0, _15=$96AF) and CALL $9630 are
;           in the $96xx 6502 region (mis-rendered as Z-80); UNKNOWN as Z-80, NOT relocated. See
;           summary.
; ----------------------------------------------------------------------
BUILD_FCB_NAME_CH:
        ; [RE] store this character into the current FCB name byte (CPMFCB.F)
        LD (HL),A
        INC DE
        ; one fewer name-field byte remaining; loop while the 8-char name field is not yet full
        DEC B
        JP NZ,RPC_DISPATCH_10
        ; [RE] name field full: request the next token character via the $9630 6502 RPC (Z => token
        ; ended, no extension); target is in the un-extracted 6502 region
        CALL RST_TABLE_9630
        JP Z,RPC_DISPATCH_17
        INC DE
        JP RPC_DISPATCH_15
; ----------------------------------------------------------------------
; BUILD_FCB_PAD -- [RE] space-pad the unused tail of the 8-char name field, then begin the 3-char
; type/extension field (CPMFCB.T). SEE the BUILD_FCB CAVEAT: cannot run as live Z-80 as decoded.
;   In:        HL = current FCB name byte; B = remaining name-field bytes to pad; A = the name-scan
;              terminator character (tested for '.').
;   Out:       [RE] remaining name bytes filled with ' '; B reset to 3 for the extension; if a '.'
;              separator is present the extension scan begins, classifying '*' as '?' fill.
;   Clobbers:  A, B, HL, DE.
;   Algorithm: [RE] Fill leftover name bytes with ' ' until B=0. Set B=3 (type-field width). If the
;              terminator was not '.', no extension. Otherwise consume the '.', request the first
;              extension character via $9630, and classify '*' (expand to '?').
;   CAVEAT: the branch targets (RPC_DISPATCH_16=$96B9, _23+1=$96E9, _20=$96D9, _21=$96DB) and CALL
;           $9630 are in the $96xx 6502 region (mis-rendered as Z-80); UNKNOWN as Z-80, NOT
;           relocated. See summary.
; ----------------------------------------------------------------------
BUILD_FCB_PAD:
        INC HL
        ; [RE] pad an unused name-field byte with a space (CP/M FCB name fields are blank-filled)
        LD (HL),' '
        DEC B
        JP NZ,RPC_DISPATCH_16
        ; set the field counter to 3 -- the width of the CP/M FCB type/extension field (CPMFCB.T,
        ; T1-T3)
        LD B,$03
        ; [RE] was the name-field terminator a '.'? only then does a file-type extension follow
        CP '.'
        JP NZ,RPC_DISPATCH_23+1
        INC DE
        ; [RE] request the first extension character via the $9630 6502 RPC (Z => empty extension);
        ; target is in the un-extracted 6502 region
        CALL RST_TABLE_9630
        JP Z,RPC_DISPATCH_23+1
        INC HL
        ; [RE] is the first extension character '*'? a '*' expands to '?' fill across the type field
        CP '*'
        JP NZ,RPC_DISPATCH_20
        ; [RE] '*' seen in the extension: write a '?' wildcard into this type byte
        LD (HL),'?'
        JP RPC_DISPATCH_21
; ----------------------------------------------------------------------
; BUILD_FCB_EXT_CH -- [RE] store-and-advance loop body for one character of the 3-char FCB
; type/extension field (CPMFCB.T). SEE the BUILD_FCB CAVEAT: cannot run as live Z-80 as decoded.
;   In:        A = the extension character to store; HL = current FCB type byte; DE = command-line
;              cursor; B = remaining type-field count.
;   Out:       [RE] character written to (HL); DE advanced; B decremented; on field full, the next
;              character requested via the $9630 RPC.
;   Clobbers:  A, B, DE, HL.
;   Algorithm: [RE] Write the extension character into the FCB type field, advance the cursor,
;              decrement the counter; loop while not full. When full, request the next token
;              character via $9630 to detect the token end.
;   CAVEAT: the branch targets (RPC_DISPATCH_18+1=$96C8, _24=$96F0, _22+1=$96DF) and CALL $9630 are
;           in the $96xx 6502 region (mis-rendered as Z-80); UNKNOWN as Z-80, NOT relocated. See
;           summary.
; ----------------------------------------------------------------------
BUILD_FCB_EXT_CH:
        ; [RE] store this character into the current FCB type/extension byte (CPMFCB.T)
        LD (HL),A
        INC DE
        ; one fewer type-field byte remaining; loop while the 3-char extension field is not yet full
        DEC B
        JP NZ,RPC_DISPATCH_18+1
        ; [RE] extension field full: request the next token character via the $9630 6502 RPC (Z =>
        ; token complete); target is in the un-extracted 6502 region
        CALL RST_TABLE_9630
        JP Z,RPC_DISPATCH_24
        INC DE
        JP RPC_DISPATCH_22+1
; ----------------------------------------------------------------------
; BUILD_FCB_EXT_PAD -- [RE] space-pad the unused tail of the 3-char type field, clear the following
; FCB control byte, and write the advanced scan cursor back. SEE the BUILD_FCB CAVEAT plus the
; no-terminator note below.
;   In:        HL = current FCB type byte; B = remaining type-field bytes to pad; DE = command-line
;              cursor past the token.
;   Out:       [RE] remaining type bytes filled with ' '; the byte after the type field (FCB
;              current-extent region, CPMFCB.EX) set to $00; PARSE_PTR ($9488) updated to the
;              post-token cursor; HL (FCB base) restored via POP.
;   Clobbers:  A, B, DE, HL; PARSE_PTR cell.
;   Algorithm: [RE] Fill leftover type bytes with ' ' until B=0. Reload B=3, advance HL once and
;              write $00 into the byte after the type field (clears the FCB current-extent byte so
;              the FCB opens cleanly), looping once. Swap the cursor into HL, store it to PARSE_PTR,
;              and POP the saved FCB base.
;   CAVEAT: this fragment has NO Z-80 RET; after POP HL the bytes are DEFB $01,$0B (a boundary
;           cover) and then the embedded 6502 RPC block at $9400 (RPC6502_BLOCK, INCBIN'd). Its
;           in-loop branch targets (RPC_DISPATCH_23+1=$96E9, _25=$96F2) are in the $96xx 6502 region
;           (mis-rendered as Z-80). The true terminal/return path is UNKNOWN as Z-80. The
;           missing-RET plus fall-into-cover reinforces that the $9300 page does not terminate
;           cleanly as live Z-80 -- see summary open question 1.
; ----------------------------------------------------------------------
BUILD_FCB_EXT_PAD:
        INC HL
        ; [RE] pad an unused type-field byte with a space (CP/M FCB type fields are blank-filled)
        LD (HL),' '
        DEC B
        JP NZ,RPC_DISPATCH_23+1
        ; reload the loop guard to 3 for the single trailing-byte clear that follows
        LD B,$03
        INC HL
        ; [RE] clear the byte after the 3-char type field -- the FCB current-extent byte (CPMFCB.EX)
        ; -- so the FCB is ready for a BDOS open
        LD (HL),$00
        DEC B
        JP NZ,RPC_DISPATCH_25
        ; move the post-token command-line cursor (DE) into HL to store it
        EX DE,HL
        ; [RE] write the advanced scan cursor back to PARSE_PTR ($9488, a cell in the 6502 block)
        ; for the next token parse
        LD (PARSE_PTR),HL
        ; restore the FCB buffer base saved by the two PUSH HL in BUILD_FCB
        POP HL
        DEFB    $01,$0B
RPC6502_BLOCK:                           ; -$9500  embedded 6502 RPC block -- 6502 code (NOT Z-80), run on the
;          ; 6502 via the SoftCard CPU switch. Assembled from CPM_RPC6502.s (ca65,
;          ; authoritative) and INCBIN'd here byte-identical. Its exact source listing
;          ; follows so this file is self-documenting.
;   >>> CPM_RPC6502.s -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>
;
; PRERR           = $FF2D         ; Apple II Monitor: print "ERR" + bell
;
; .org $9400
;
; SECTOR_RW:
;         DEC $04F8                    ; $9400  CE F8 04
;         BNE $93EA                    ; $9403  D0 E5
;         BEQ $93D1                    ; $9405  F0 CA
;         PLA                          ; $9407  68
;         LDA #$40                     ; $9408  A9 40
; SECTOR_RW_1:
;         PLP                          ; $940A  28
;         JMP $0F3E                    ; $940B  4C 3E 0F
; SECTOR_MATCH:
;         BEQ DRIVE_MOTOR_ON           ; $940E  F0 2A
;         LDA $2F                      ; $9410  A5 2F
;         STA $03E3                    ; $9412  8D E3 03
;         LDA $03E2                    ; $9415  AD E2 03
;         BEQ SECTOR_MATCH_1           ; $9418  F0 08
;         CMP $2F                      ; $941A  C5 2F
;         BEQ SECTOR_MATCH_1           ; $941C  F0 04
;         LDA #$20                     ; $941E  A9 20
;         BNE SECTOR_RW_1              ; $9420  D0 E8
; SECTOR_MATCH_1:
;         LDA $03E1                    ; $9422  AD E1 03
;         TAY                          ; $9425  A8
;         LDA $0F9D,Y                  ; $9426  B9 9D 0F
;         CMP $2D                      ; $9429  C5 2D
;         BNE $93CC                    ; $942B  D0 9F
;         PLP                          ; $942D  28
;         BCC DRIVE_MOTOR_ON_2         ; $942E  90 19
;         JSR $0B00                    ; $9430  20 00 0B
;         PHP                          ; $9433  08
;         BCS $93CC                    ; $9434  B0 96
;         PLP                          ; $9436  28
;         JSR $0BC6                    ; $9437  20 C6 0B
; DRIVE_MOTOR_ON:
;         CLC                          ; $943A  18
;         LDA #$00                     ; $943B  A9 00
; DRIVE_MOTOR_ON_1:
;         BIT $38                      ; $943D  24 38
;         STA $03EA                    ; $943F  8D EA 03
;         LDX $05F8                    ; $9442  AE F8 05
;         LDA $C088,X                  ; $9445  BD 88 C0
;         RTS                          ; $9448  60
; DRIVE_MOTOR_ON_2:
;         JSR $0A25                    ; $9449  20 25 0A
;         BCC DRIVE_MOTOR_ON           ; $944C  90 EC
;         LDA #$10                     ; $944E  A9 10
;         BNE DRIVE_MOTOR_ON_1+1       ; $9450  D0 EC
;         ASL                          ; $9452  0A
;         JSR $0F5A                    ; $9453  20 5A 0F
;         LSR $0478                    ; $9456  4E 78 04
;         RTS                          ; $9459  60
; SECTOR_XFER_BYTE:
;         STA $2E                      ; $945A  85 2E
;         JSR $0F7D                    ; $945C  20 7D 0F
;         LDA $0478,Y                  ; $945F  B9 78 04
;         BIT $35                      ; $9462  24 35
;         BMI SECTOR_XFER_BYTE_1       ; $9464  30 03
;         LDA $04F8,Y                  ; $9466  B9 F8 04
; SECTOR_XFER_BYTE_1:
;         STA $0478                    ; $9469  8D 78 04
;         LDA $2E                      ; $946C  A5 2E
;         BIT $35                      ; $946E  24 35
;         BMI SECTOR_XFER_BYTE_2       ; $9470  30 05
;         STA $04F8,Y                  ; $9472  99 F8 04
;         BPL SECTOR_XFER_BYTE_3       ; $9475  10 03
; SECTOR_XFER_BYTE_2:
;         STA $0478,Y                  ; $9477  99 78 04
; SECTOR_XFER_BYTE_3:
;         JMP $0BDE                    ; $947A  4C DE 0B
; SLOT_TO_INDEX:
;         TXA                          ; $947D  8A
;         LSR                          ; $947E  4A
;         LSR                          ; $947F  4A
;         LSR                          ; $9480  4A
;         LSR                          ; $9481  4A
;         TAY                          ; $9482  A8
;         RTS                          ; $9483  60
; SECTOR_MOVE:
;         PHA                          ; $9484  48
;         LDA $03E4                    ; $9485  AD E4 03
;         .byte   $6A, $66, $35, $20                               ; $9488
; SECTOR_MOVE_1:
;         ADC $680F,X                  ; $948C  7D 0F 68
;         ASL                          ; $948F  0A
;         BIT $35                      ; $9490  24 35
; SECTOR_MOVE_2:
;         BMI SECTOR_MOVE_4            ; $9492  30 05
;         STA $04F8,Y                  ; $9494  99 F8 04
; SECTOR_MOVE_3:
;         BPL SECTOR_MOVE_5            ; $9497  10 03
; SECTOR_MOVE_4:
;         STA $0478,Y                  ; $9499  99 78 04
; SECTOR_MOVE_5:
;         RTS                          ; $949C  60
; SECTOR_XLATE_TABLE:
;         .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $949D
; ; Warm-boot reload: re-reads CP/M (CCP+BDOS) from the boot disk into the system
; ; image, which is why only ~5K of CP/M's 7K stays resident during a transient.
; ; [DOC Vol1 1-19 ; facts sec.8.7]
; WBOOT_LOAD:
;         .ifdef CFG_56K
;             lda     #>$E400          ; $94AD  warm-boot load buffer hi (56K)
;         .else
;             lda     #>$A400          ; $94AD  warm-boot load buffer hi (44K)
;         .endif
;         STA $03E9                    ; $94AF  8D E9 03
;         LDY #$00                     ; $94B2  A0 00
;         STY $03E8                    ; $94B4  8C E8 03
; WBOOT_LOAD_1:
;         STY $03E0                    ; $94B7  8C E0 03
;         INY                          ; $94BA  C8
; WBOOT_LOAD_2:
;         STY $03E4                    ; $94BB  8C E4 03
;         STY $03EB                    ; $94BE  8C EB 03
;         LDA #$60                     ; $94C1  A9 60   slot 6 (6<<4): the boot disk
;         STA $03E6                    ; $94C3  8D E6 03  controller, drives A:/B:, MUST be present [DOC Vol1 1-3/1-4 ; facts sec.8.9]
;         LDA #$0B                     ; $94C6  A9 0B
;         STA $03E1                    ; $94C8  8D E1 03
;         LDA #$1C                     ; $94CB  A9 1C
; WBOOT_READ_SECTOR:
;         PHA                          ; $94CD  48
;         PHP                          ; $94CE  08
;         SEI                          ; $94CF  78
; WBOOT_READ_SECTOR_1:
;         JSR $0E10                    ; $94D0  20 10 0E
;         BCC WBOOT_NEXT_SECTOR        ; $94D3  90 08
;         JSR PRERR                    ; $94D5  20 2D FF
;         PLP                          ; $94D8  28
;         PLA                          ; $94D9  68
; WBOOT_ERR_MONITOR:
;         JMP $0FAD                    ; $94DA  4C AD 0F
; WBOOT_NEXT_SECTOR:
;         PLP                          ; $94DD  28
;         INC $03E9                    ; $94DE  EE E9 03
;         LDX $03E1                    ; $94E1  AE E1 03
; WBOOT_NEXT_SECTOR_1:
;         INX                          ; $94E4  E8
;         CPX #$10                     ; $94E5  E0 10
;         BNE WBOOT_NEXT_SECTOR_3      ; $94E7  D0 05
; WBOOT_NEXT_SECTOR_2:
;         LDX #$00                     ; $94E9  A2 00
;         INC $03E0                    ; $94EB  EE E0 03
; WBOOT_NEXT_SECTOR_3:
;         STX $03E1                    ; $94EE  8E E1 03
;         PLA                          ; $94F1  68
;         SEC                          ; $94F2  38
;         SBC #$01                     ; $94F3  E9 01
;         BNE WBOOT_READ_SECTOR        ; $94F5  D0 D6
;         LDA #$08                     ; $94F7  A9 08
;         STA $03E9                    ; $94F9  8D E9 03
;         RTS                          ; $94FC  60
;         .byte   $FF, $FF, $FF, $00                               ; $94FD
;   <<< end listing <<<
        INCBIN  "CPM_RPC6502.bin"
; -- Addresses the Z-80 references inside the 6502 block, as offsets from RPC6502_BLOCK
;    (so they relocate with ORG). OPEN: how a Z-80 CALL into $94xx actually
;    reaches/selects the 6502 service is NOT understood -- several of these land
;    mid-6502-instruction or inside the skew table, so they are NOT semantic 6502
;    entry points. Kept verbatim, auto-named, pending that investigation. The
;    6502 CODE itself is named in CPM_RPC6502.s. --
SUBMIT_FLAG           EQU RPC6502_BLOCK + $007
CMDTAIL_SCRATCH           EQU RPC6502_BLOCK + $008
PARSE_PTR           EQU RPC6502_BLOCK + $088
PARSE_PTR2           EQU RPC6502_BLOCK + $08A
RPC6502_E08C         EQU RPC6502_BLOCK + $08C
RPC6502_E092         EQU RPC6502_BLOCK + $092
RPC6502_E098         EQU RPC6502_BLOCK + $098
RPC6502_E0A2         EQU RPC6502_BLOCK + $0A2
RPC6502_E0A7         EQU RPC6502_BLOCK + $0A7
RPC6502_E0B8         EQU RPC6502_BLOCK + $0B8
RPC6502_E0BD         EQU RPC6502_BLOCK + $0BD
RPC6502_E0D0         EQU RPC6502_BLOCK + $0D0
RPC6502_E0DA         EQU RPC6502_BLOCK + $0DA
RPC6502_E0E4         EQU RPC6502_BLOCK + $0E4
RPC6502_E0E9         EQU RPC6502_BLOCK + $0E9
RPC6502_E0EF         EQU RPC6502_BLOCK + $0EF
RPC6502_E0F9         EQU RPC6502_BLOCK + $0F9
RPC6502_E0FE         EQU RPC6502_BLOCK + $0FE
RPC6502_END           EQU RPC6502_BLOCK + $0FF
; ----------------------------------------------------------------------
; FCB_WILDCARD_NEXT -- advance to the next name/type-field byte and fall into the per-byte
; classifier [RE]
;   In:        HL -> current byte of the field being scanned; B = running count of '?' bytes seen; C
;              = bytes remaining in the field
;   Out:       falls through into FCB_WILDCARD_TEST with A = the freshly fetched byte (HL advanced
;              by one)
;   Clobbers:  A, HL
;   Algorithm: bump HL to the next field byte, load it into A, then fall into FCB_WILDCARD_TEST
;              which classifies it as '?' vs. other. [RE] this is the per-byte step of a field scan;
;              the non-'?' exit hands off to the decimal-digit field parser at FCB_DIGIT_ACCUM_STEP
;              ($9709), so whether the field is an FCB name or a command-line numeric argument is
;              not certain from these bytes alone.
; ----------------------------------------------------------------------
FCB_WILDCARD_NEXT:
        ; ; step HL to the next byte of the field being scanned
        INC HL
        ; ; fetch the field byte; fall through to classify it
        LD A,(HL)
; ----------------------------------------------------------------------
; FCB_WILDCARD_TEST -- classify the current field byte: '?' bumps the count, anything else leaves
; the loop via the field parser [RE]
;   In:        A = candidate field byte (from FCB_WILDCARD_NEXT); B = running '?' count; C = field
;              bytes remaining
;   Out:       if A != '?', branches to FCB_DIGIT_ACCUM_STEP ($9709, the digit/field parser); if A
;              == '?', B is incremented then control falls into FCB_WILDCARD_CMP_C
;   Clobbers:  B (on '?'), flags
;   Algorithm: compare the byte against '?' ($3F). [RE] '?' looks like the CP/M ambiguous-filename
;              wildcard, so a '?' increments the counter B and the scan continues into the
;              field-length decrement; a non-'?' byte exits to the numeric/field parser at $9709.
;              The exact field semantics are [RE], not confirmed.
;   Note: $9503 is the FALL-THROUGH (CP $3F) tenant; the alternate mid-byte entry
;         FCB_WILD_TEST_ENTRY ($9504 = CCF) is reached by `CALL $9504` at $98E6 and chains into the
;         same $9709 parser. CCF touches only the carry flag, so the Z flag the caller set is
;         preserved for the following `JP NZ`. See the split below.
; ----------------------------------------------------------------------
FCB_WILDCARD_TEST:
        CP $3F
        ; ; not '?' -> leave this loop, jump to the digit/field parser at FCB_DIGIT_ACCUM_STEP
        ; ($9709)
        JP NZ,FCB_DIGIT_ACCUM_STEP
        ; ; '?' seen: bump the count [RE: CP/M ambiguous-filename wildcard]
        INC B
; ----------------------------------------------------------------------
; FCB_WILDCARD_CMP_C -- decrement the field-byte counter; loop for the next byte unless the field is
; exhausted [RE]
;   In:        C = bytes remaining in the field; B = running '?' count; HL -> current field byte
;   Out:       if C != 0, branches to FCB_DIGIT_ACCUM ($9701, the loop body) for the next byte; if C
;              == 0, control falls into TEST_B_NZ with A = B
;   Clobbers:  A, C, flags
;   Algorithm: count down the per-field byte budget. While bytes remain, re-enter the scan loop body
;              at $9701; once the field is exhausted, copy the accumulated count B into A and fall
;              into TEST_B_NZ to set the predicate.
;   Note: this label is also a clean CALL entry (`CALL $9509` at $98C2) used to decrement/test C
;         directly. The loop body it targets ($9701) sits in the $9700 cluster, so the precise loop
;         wiring across the $9500/$9700 boundary is only PARTIALLY understood.
; ----------------------------------------------------------------------
FCB_WILDCARD_CMP_C:
        ; ; one fewer byte left in this field
        DEC C
        ; ; bytes remain -> back into the loop body at FCB_DIGIT_ACCUM ($9701)
        JP NZ,FCB_DIGIT_ACCUM
        ; ; field exhausted: move the accumulated count into A for the NZ predicate below
        LD A,B
; ----------------------------------------------------------------------
; TEST_B_NZ -- set Z/NZ from the byte in A (the accumulated count) and return [RE]
;   In:        A = the count to test (from FCB_WILDCARD_CMP_C, or preloaded by the direct caller
;              `CALL $950E` at $9A67)
;   Out:       flags reflect A (Z if zero, NZ if non-zero); A unchanged
;   Clobbers:  flags
;   Algorithm: OR A then RET -- a one-instruction 'is A zero?' predicate. [RE] used as the 'was any
;              '?' seen / is this field ambiguous?' test, but it is a generic zero-test and is also
;              called directly with a caller-supplied A.
; ----------------------------------------------------------------------
TEST_B_NZ:
        ; ; set Z if A is 0, NZ otherwise (generic zero-test predicate)
        OR A
        RET
; ----------------------------------------------------------------------
; CCP_CMD_NAMES -- the 24-byte CCP built-in command name table: six 4-byte space-padded keywords
; [DOC CPMREF 3-6 ; facts sec.7.8]
;   Layout:    6 entries x 4 bytes = 'DIR ' 'ERA ' 'TYPE' 'SAVE' 'REN ' 'USER' (bytes 44 49 52 20 45
;              52 41 20 54 59 50 45 53 41 56 45 52 45 4E 20 55 53 45 52, $9510-$9527).
;   Note:      kept as a single DEFB string literal (byte-identical; do not touch per the
;              keep-string-literal map). FLAG (UNRESOLVED): `CALL $9515` at $9568 and $9A9F lands
;              MID-STRING here (the 'R' of 'ERA', $9510+5), a data-as-code / mis-decode tell to
;              root-cause. Whether SEARCH_BUILTIN (which loads HL=$9710, NOT $9510) actually walks
;              this table is UNKNOWN.
; ----------------------------------------------------------------------
CCP_CMD_NAMES:
        ; ; CCP built-in command keywords, 4 space-padded bytes each: 'DIR ' 'ERA ' 'TYPE' 'SAVE'
        ; 'REN ' 'USER' [DOC CPMREF 3-6]. FLAG: `CALL $9515` (x2) targets the 'R' of 'ERA' inside
        ; this string -- data-as-code anomaly, unresolved
        DEFB    "DIR ERA TYPESAVEREN USER" ; CCP built-in command name table: DIR ERA TYPE SAVE REN USER (4 bytes each) [DOC CPMREF 3-6 ; facts sec.7.8] the six CCP built-in commands (ERA DIR REN SAVE TYPE USER)
CCP_CMD_NAMES_END:
        CP L
; ----------------------------------------------------------------------
; SEARCH_BUILTIN -- UNKNOWN purpose: a routine called from CMD_EXEC ($9ABB) after a parsed numeric
; value is stored; sets up a pointer (HL=$9710) and counter (C=0) and runs a compare loop
;   In:        on the $9ABB path, ($9BCE)/CMD_EXEC_69 hold a parsed value (the caller did `DEC A; LD
;              (CMD_EXEC_69),A` before calling); the compare loop reads bytes via DE/HL
;   Out:       on the early `CP $06 / RET NC` path, returns when C reaches 6 (C is 0 on first entry,
;              so this never fires immediately); otherwise drops into the SEARCH_BUILTIN_1 compare
;              loop and returns A from there
;   Clobbers:  A, B, C, D, DE, HL, flags
;   Algorithm: UNKNOWN. OBSERVED: `LD D,$00 / NOP / LD D,$DF` (D ends $DF; the first load is
;              redundant -- a dead/patched-over artifact, UNKNOWN), then `LD HL,$9710 / LD C,$00`,
;              then `LD A,C / CP $06 / RET NC` (a 0..5 index/limit guard), then fall into the
;              compare loop. The earlier enrichment's claim that this walks CCP_CMD_NAMES and
;              returns a built-in dispatch index is UNSUPPORTED: HL is loaded with $9710 (a pointer
;              INTO the $9700 numeric-parser code), NOT CCP_CMD_NAMES ($9510), and (HL) is compared
;              from there. Treat the 'name matcher' reading as REJECTED until the $9700 region is
;              decoded.
;   Dispatch:  UNKNOWN (not demonstrably a name-table walk).
;   FLAG: `LD HL,$9710` is an in-image pointer that must relocate but lands MID-INSTRUCTION at $970F
;         (operand of `SUB $30`) -- needs a cover-split at $970F in the $9700 cluster; left literal
;         here.
; ----------------------------------------------------------------------
SEARCH_BUILTIN:
        LD D,$00
        NOP
        LD D,$DF
        ; ; FLAG: in-image pointer set to $9710 (into the $9700 parser code, NOT CCP_CMD_NAMES);
        ; lands mid-instruction, relocation pending a split at $970F
        LD HL,$9710
        ; ; index/counter C = 0
        LD C,$00
        LD A,C
        ; ; C-index limit guard (0..5); purpose of the limit UNKNOWN
        CP $06                           ; index past last built-in? there are exactly 6 [DOC CPMREF 3-6 ; facts sec.7.8] ERA DIR REN SAVE TYPE USER
        ; ; return once the index reaches the limit (never fires on first entry, C just set to 0)
        RET NC
; ----------------------------------------------------------------------
; SEARCH_BUILTIN_1 -- compare a 4-byte run at (HL) against bytes at (DE), require a trailing space,
; return C in A on full match [RE]
;   In:        HL -> bytes to compare (set by SEARCH_BUILTIN to the $9710 region); (fall-through
;              path) DE = $9BCE (a CCP workspace cell); C = current index
;   Out:       on 4 matched bytes + a trailing space at (DE), A = C and RET; on any mismatch, branch
;              to TBUFF_INDEX_FETCH_2 ($974F) or RESOLVE_DRIVE_PREFIX ($9754) in the $9700 cluster
;   Clobbers:  A, B, DE, HL, flags
;   Algorithm: B=4; compare (DE) vs (HL); on equality advance both pointers and loop; after 4 equal
;              bytes require (DE)==' ' then return the index C in A. [RE] the structure is a
;              fixed-width-field compare; what it compares against is governed by SEARCH_BUILTIN's
;              HL setup, which is UNKNOWN, so the 'built-in keyword match' reading is NOT confirmed.
;   Note: $9537 (LD DE,$9BCE) is the FALL-THROUGH tenant; the alternate mid-byte entry
;         SEARCH_BUILTIN_ALT ($9539 = SBC A,E) is reached by `CALL $9539` at $9595 and $982D and
;         re-uses this compare loop with caller-supplied DE/HL (purpose of the SBC entry: UNKNOWN --
;         see split). $9BCE is a CCP workspace cell kept literal (file-wide relocation decision
;         needed -- FLAG).
; ----------------------------------------------------------------------
SEARCH_BUILTIN_1:
        LD DE,$9BCE
        ; ; compare a 4-byte field
        LD B,$04
        LD A,(DE)
        ; ; byte at (DE) vs byte at (HL) for this position
        CP (HL)
        JP NZ,TBUFF_INDEX_FETCH_2
        INC DE
        INC HL
        DEC B
        JP NZ,FCB_FIELD_BLANKS_LOOP+1
        ; ; after 4 equal bytes, the byte at (DE) must be a space delimiter for a full match
        LD A,(DE)
        CP ' '
        JP NZ,RESOLVE_DRIVE_PREFIX
        ; ; full match: return the index C in A
        LD A,C
        RET
; ----------------------------------------------------------------------
; SEARCH_BUILTIN_2 -- skip the rest of the mismatched field, bump the index, retry the next field
; [RE]
;   In:        HL -> within the current field; B = bytes left to skip; C = current index
;   Out:       loops to FCB_FIELD_BLANKS ($9733) with C incremented and HL advanced past the field;
;              on a skip miscount branches to TBUFF_INDEX_FETCH_2 ($974F)
;   Clobbers:  B, C, HL, flags
;   Algorithm: DEC B / INC HL to step HL over the remaining field bytes, then INC C and JP
;              FCB_FIELD_BLANKS to retry the next field. [RE] this is the 'try the next entry' tail
;              of the matcher; the targets are in the $9700 cluster so the wiring is only PARTIALLY
;              understood (see SEARCH_BUILTIN FLAG).
; ----------------------------------------------------------------------
SEARCH_BUILTIN_2:
        ; ; skip a remaining byte of the mismatched field
        INC HL
        DEC B
        JP NZ,TBUFF_INDEX_FETCH_2
        ; ; advance to the next index
        INC C
        ; ; retry the compare against the next field at FCB_FIELD_BLANKS ($9733)
        JP FCB_FIELD_BLANKS
; ----------------------------------------------------------------------
; CCP_MAIN_LOOP -- CCP top-of-loop: re-login, print drive prompt, read+parse a command line,
; dispatch a built-in or load a transient .COM. In: BC=login byte, C=(user<<4)|drive. Out: drive
; cell $9BEF set, FCB+TBUFF tail parsed. CAVEAT: several CALLs target mid-instruction/string data
; (unresolved RPC/position idiom).
; ----------------------------------------------------------------------
CCP_MAIN_LOOP:
        XOR A
        LD (SUBMIT_FLAG),A
        LD SP,$9BAB
        PUSH BC
        LD A,C
        RRA
        RRA
        RRA
        RRA
        AND $0F
        LD E,A
        ; [UNKNOWN] $9515 lands inside the CCP_CMD_NAMES string ($9510-$9527) -- a CALL-into-data
        ; idiom unresolved by static decode
        CALL $9515
        ; [RE] per-user login/select inferred from call-site; 6502 service at offset $0B8
        ; UNIDENTIFIED -- the block is disk-only, selection mechanism is the file's open question
        CALL RPC6502_E0B8
        LD ($9BAB),A
        POP BC
        LD A,C
        AND $0F
        ; record the current drive in the CCP drive cell ($9BEF; runtime scratch RAM, not the BDOS
        ; code it disassembles as)
        LD (CMD_EXEC_69),A
        ; [RE] per-drive select inferred from call-site; 6502 service at offset $0BD UNIDENTIFIED
        CALL RPC6502_E0BD
        LD A,(SUBMIT_FLAG)
        OR A
        JP NZ,DIR_CMD_2
        LD SP,$9BAB
        ; [RE] CRLF inferred from call-site; 6502 service at offset $098 UNIDENTIFIED
        CALL RPC6502_E098
        CALL GET_CUR_DRIVE
        ADD A,'A'
        ; [RE] drive letter inferred (A from ADD A,'A'); 6502 service at offset $08C UNIDENTIFIED --
        ; the 6502 block has no console routine
        CALL RPC6502_E08C
        LD A,'>'
        ; [RE] '>' inferred (A set to '>'); same UNIDENTIFIED-6502-service caveat
        CALL RPC6502_E08C
        ; [UNKNOWN] $9539 is MID-INSTRUCTION (operand of LD DE,$9BCE at $9537; header line 52) --
        ; unresolved skip/cover idiom like CALL $9515; read/parse role inferred only from loop
        ; position
        CALL SEARCH_BUILTIN_1+2
        LD DE,TBUFF                      ; default DMA buffer / command-tail buffer at 0080H [DOC CPMREF 3-47 ; facts sec.7.4/7.5] (byte 0080H = char count, then upper-cased tail; doubles as the initial DMA buffer)
        CALL RPC_CALL_HL
        CALL GET_CUR_DRIVE
        LD (CMD_EXEC_69),A
        CALL RPC_DISPATCH
        CALL NZ,RST_TABLE_9609
        LD A,($9BF0)
CCP_MAIN_LOOP_1:
        OR A
        JP NZ,CMD_EXEC_49
        CALL FCB_FIELD_LEN_LOOP
        LD HL,$97C1
        LD E,A
        LD D,$00
        ADD HL,DE
        ADD HL,DE
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        JP (HL)
        DEFB    $77
CMD_DISPATCH_TBL:
        DEFB    $98,$1F,$99,$5D,$99      ; [AI/RE] CCP-internal address table, reached via CALL CMD_DISPATCH_TBL (CD C2 95) from $980F and $9897 -- NOT the JP (HL) built-in dispatcher at $95C0 (that one indexes base $97C1). A per-implementation table, not a manual structure.
CMD_DISPATCH_TBL_2:
        DEFW    $99AD
        DEFW    CMD_EXEC_42
        DEFW    CMD_EXEC_48
        DEFW    CMD_EXEC_49
        DEFB    $21
GET_CUR_DRIVE:
        DEFB    $F3,$76,$22,$00,$94
RPC_ENTER_6502:
        LD HL,RPC6502_BLOCK
RPC_CALL_HL:
        JP (HL)
; ----------------------------------------------------------------------
; RPC_CALL_HL_1 -- LD BC,$97DF then JP RPC6502_E0A7. UNKNOWN: [RE] call-site suggests a print RPC
; but the 6502 service at $0A7 is UNIDENTIFIED. $97DF is IN-IMAGE (interior of DIR_EMIT_NAME_CHAR,
; not MSG_READ_ERROR head $95DF), mid-instruction -- left literal, FLAGGED for a cover-split there.
; ----------------------------------------------------------------------
RPC_CALL_HL_1:
        LD BC,$97DF
RPC_CALL_HL_2:
        JP RPC6502_E0A7
; ----------------------------------------------------------------------
; MSG_READ_ERROR -- CP/M "READ ERROR" message text (NUL-terminated literal).
;   In:        Not entered as code. A $00-terminated ASCII string literal addressed
;              as DATA. It is reached for printing via the stub RPC_CALL_HL_1 at
;              $95D9: LD BC,$97DF / JP RPC6502_E0A7 (the 6502 string-print RPC).
;   Out:       n/a (data).
;   Clobbers:  n/a (data).
;   Algorithm: OBSERVED bytes "READ ERROR",$00. Printed when a CCP-driven disk read
;              of a transient (.COM) hard-fails -- the standard CP/M 2.2 console
;              read-error text. [RE] LOCATOR RESOLVED (peer had marked UNKNOWN): the
;              print pointer $97DF is EXACTLY this label's address $95DF plus $0200,
;              i.e. the 6502-VIEW address of the string (the Z-80<->6502 image-view
;              +$0200 offset). The 6502 print RPC reads the same physical bytes from
;              the 6502 address space. $97DF is therefore a cross-CPU literal, NOT a
;              relocatable Z-80 label (it must stay literal). The exact Z-80 path that
;              sets HL/falls into RPC_CALL_HL_1 is reached via the JP (HL) computed
;              dispatch at RPC_CALL_HL ($95D8) and is only partially traced (UNKNOWN).
; ----------------------------------------------------------------------
MSG_READ_ERROR:
        DEFB    "READ ERROR"             ; CP/M error text
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; RPC_CALL_HL_3 -- LD BC,$97F0 then JP RPC6502_E0A7. UNKNOWN: [RE] call-site suggests a print RPC
; but the 6502 service at $0A7 is UNIDENTIFIED. $97F0 is IN-IMAGE (interior of DIR_EMIT_NAME_CHAR_2,
; not MSG_NO_FILE head $95F0), mid-instruction -- left literal, FLAGGED for a cover-split.
; ----------------------------------------------------------------------
RPC_CALL_HL_3:
        LD BC,$97F0
        JP RPC6502_E0A7
; ----------------------------------------------------------------------
; MSG_NO_FILE -- CP/M "NO FILE" message text (NUL-terminated literal).
;   In:        Not entered as code. A $00-terminated ASCII string literal emitted via
;              the stub RPC_CALL_HL_3 at $95EA: LD BC,$97F0 / JP RPC6502_E0A7 (the
;              6502 string-print RPC).
;   Out:       n/a (data).
;   Clobbers:  n/a (data).
;   Algorithm: OBSERVED bytes "NO FILE",$00. Printed when a command names a file the
;              directory search does not find -- standard CP/M 2.2 "NO FILE" text.
;              [RE] LOCATOR RESOLVED (peer had marked UNKNOWN): the print pointer
;              $97F0 is EXACTLY this label's address $95F0 plus $0200 -- the 6502-VIEW
;              address of the string (same +$0200 Z-80<->6502 image-view offset as
;              MSG_READ_ERROR). $97F0 is a cross-CPU literal, correctly kept literal,
;              NOT a relocatable Z-80 label. The reaching Z-80 path is only partially
;              traced (UNKNOWN precise trigger).
; ----------------------------------------------------------------------
MSG_NO_FILE:
        DEFB    "NO FILE"                ; CP/M error text
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CHECK_DRIVE_ERR_1 -- hand off to the 6502 RPC, then fall into the error-flag check.
;   In:        Caller has set up the pending 6502 service; $9BF0 = CCP BDOS-result/
;              error flag (0 = ok, nonzero = error code). $9BF0 is CCP RAM workspace
;              (above the CP/M base page; not in cpm22.inc) -> kept literal.
;   Out:       Falls into CHECK_DRIVE_ERR_2 with A = the $9BF0 flag and Z reflecting it.
;   Clobbers:  A, plus whatever the 6502 service touches.
;   Algorithm: Transfer to the embedded 6502 block via the Z-80 reference RPC_DISPATCH
;              ($965E) -- a target INSIDE the 6502 program (see the cluster FLAG): how
;              the Z-80 transfer selects the 6502 service is the unsolved CPU-switch
;              question shared with the $9400 block. On return, read and test the CCP
;              error flag at $9BF0.
; ----------------------------------------------------------------------
CHECK_DRIVE_ERR_1:
        ; ; hand off to the embedded 6502 block (target $965E lies INSIDE the 6502 program; the
        ; CPU-switch selector is the documented OPEN QUESTION, file lines 489-494)
        CALL RPC_DISPATCH
; ----------------------------------------------------------------------
; CHECK_DRIVE_ERR_2 -- test the CCP BDOS-result/error flag after an RPC service.
;   In:        $9BF0 = CCP error flag set by the preceding operation (0 = success,
;              nonzero = a BDOS/disk error code); CCP RAM workspace, kept literal.
;   Out:       Genuine Z-80 body is ONLY LD A,($9BF0) ($95FB) / OR A ($95FE):
;              A = flag, Z set iff no error.
;   Clobbers:  A, flags.
;   Algorithm: Load the error flag and OR A to set Z. WARNING (peer FLAG confirmed):
;              everything from $95FF onward as shown (the bogus 'JP NZ,$81AD' and the
;              lines below) is NOT Z-80 -- the disassembler mis-split the START of the
;              embedded 6502 restart block into Z-80. The off-image target $81AD
;              (outside the $9300-$9CFF CCP image) is the tell. Decoded as 6502 from
;              $9600 the bytes 'AD 81 C0' = LDA $C081 (Language-Card enable), the real
;              first instruction of the 6502 program (see the cluster FLAG). The true
;              error branch lives in that 6502 payload. Also entered at
;              CHECK_DRIVE_ERR_2+2 ($95FD, the documented shared instruction tail).
; ----------------------------------------------------------------------
CHECK_DRIVE_ERR_2:
        ; ; read the CCP BDOS-result/error flag ($9BF0: 0 = ok, nonzero = error code; CCP RAM
        ; workspace)
        LD A,($9BF0)
        ; ; set Z iff no error; FLAG: from the next line on the bytes are the embedded 6502 restart
        ; block ($9600 AD 81 C0 = LDA $C081) mis-decoded as Z-80 -- do not trust as Z-80 code
        OR A
        JP NZ,$81AD
        RET NZ
        XOR L
        ADD A,C
        RET NZ
        JR NZ,RPC_DISPATCH_4
        RRCA
; ----------------------------------------------------------------------
; RST_TABLE_9609 -- inside an EMBEDDED 6502 CODE BLOCK (NOT Z-80, NOT a data table).
;   In:        Reached from the Z-80 CCP on a command error / cold restart (many
;              JP/CALL RST_TABLE_9609 sites). The Z-80 parks (DI;HALT at $95D0/$95D1)
;              and the SoftCard runs these bytes on the 6502 via the CPU switch.
;   Out:       Re-enters the Z-80 BIOS by building a JP-to-$AA00 handoff at $1000 (see
;              Algorithm caveat).
;   Clobbers:  (6502 side) A,X,Y, zero-page $3C/$3D/$3E/$40/$41, slot-config cells
;              $03B8/$03C7/$03C8/$03DE/$03DF/$03EF.., $1000.., the 6502 stack.
;   Algorithm: OBSERVED 6502 payload ($9600 onward; INDEPENDENTLY re-disassembled here
;              as fully coherent 6502 with ZERO illegal opcodes): LC RAM write-enable
;              (LDA $C081 x2); drive motor off (STA $C088,X); clear sector cells
;              $0478/$04F8; Apple monitor init JSR $FB2F(SETTXT)/$FE93(SETVID)/
;              $FE89(SETKBD); reset 6502 stack (LDX #$FF/TXS); on CMP #$06 either print
;              a $00-string via JSR $FDED(COUT) then JMP $FF65(MONZ), or take the full
;              restart: copy loader blocks ($1168->$0FFF, $1200->$0200, $12FF->$02FF,
;              $13EF->$03EF), run the SLOT/CARD-TYPE SCANNER (JSR $1180/$1117, CMP
;              $40/$41) that PATCHES the SoftCard slot-config cells STA $03C7 / STY
;              $03C8 / STA $03DE / STA $03DF (the slot bytes in
;              CPM_SoftCard_RealMap_Findings.md), records card types at $02F8,Y, sets
;              the Card-Type-Table base $03B8, then assembles the Z-80 BIOS handoff at
;              $1000. [RE] CAVEAT: the peer's exact 'JP $AA00 (C3 00 AA) at $1000-$1002'
;              is over-specific -- the captured stores are LDA #$C3/STA $1000, LDA
;              #$00/STA $1001, LDA #$AA/STA ... but byte $9700 = $09 (not $10), so the
;              literal third store decodes STA $0902 and the precise 6502/Z-80 boundary
;              at $9700 is UNCERTAIN (genuine Z-80 resumes by $9709 'CP $20').
;   FLAG:      This 6502 block is STILL sitting as raw Z-80 disassembly (these labels +
;              garbage opcodes). PROPER FIX: extract to its own 6502 .s and INCBIN it
;              back with a verbatim listing, exactly like CPM_RPC6502.s ($9400 block).
;              The Z-80 CALL targets $9609/$9630/$964F/$9659/$965E land MID-6502-
;              INSTRUCTION -- the same unsolved CPU-switch-selector question as the
;              $9400 block. Not renamed/rewritten here to avoid inventing Z-80 semantics.
; ----------------------------------------------------------------------
RST_TABLE_9609:
        LD C,B
        SBC A,L
        ADC A,B
        RET NZ
        XOR C
        NOP
; ----------------------------------------------------------------------
; RST_TABLE_9609_1 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80. This label lands inside the 6502 code
;              described at RST_TABLE_9609; it is not a Z-80 routine. Resolved only
;              when the block is extracted to a 6502 .s (see the cluster FLAG).
; ----------------------------------------------------------------------
RST_TABLE_9609_1:
        SBC A,C
        LD A,B
        INC B
        SBC A,C
        RET M
        INC B
        JR NZ,RST_TABLE_9630_1
        EI
        JR NZ,CCP_MAIN_LOOP_1
        CP $20
; ----------------------------------------------------------------------
; RST_TABLE_9609_2 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Not a Z-80 routine. See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_9609_2:
        ADC A,C
; ----------------------------------------------------------------------
; RST_TABLE_9609_3 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609 (RST_TABLE_9609_3+1 = $961E is referenced as a shared
;              tail -- another 6502-mid-instruction artifact). Not a Z-80 routine.
;              See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_9609_3:
        CP $68
        AND D
        RST $38
        SBC A,D
; ----------------------------------------------------------------------
; RST_TABLE_9609_4 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Reached as a Z-80 JP target ($9312/$9316) into the
;              6502 block -- a CPU-switch transfer, not a Z-80 entry.
;              See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_9609_4:
        RET
; ----------------------------------------------------------------------
; RST_TABLE_9609_5 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Not a Z-80 routine. See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_9609_5:
        LD B,$F0
        DJNZ CMD_DISPATCH_TBL_2
        NOP
        CP C
        LD C,D
        LD DE,$06F0
        JR NZ,RST_TABLE_9609_2
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $962F  FD C8
; ----------------------------------------------------------------------
; RST_TABLE_9630 -- interior address inside the embedded 6502 restart block.
;   In:        Reached from the Z-80 FCB parser via CALL RST_TABLE_9630 ($9398/$93AF/
;              $93C8/$93DF) -- a SoftCard CPU-switch transfer into the 6502 code, NOT a
;              Z-80 call. The Z-80 target $9630 lands mid-6502-instruction (decoded as
;              Z-80 it is incoherent: RST $38, LD C,H/LD H,L).
;   Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Not a Z-80 routine. See the cluster FLAG (extract to .s);
;              same unsolved selector question as the $9400 block.
; ----------------------------------------------------------------------
RST_TABLE_9630:
        RET Z
        RET NC
        PUSH AF
        LD C,H
        LD H,L
        RST $38
        AND B
        LD C,$B9
        LD L,B
        LD DE,$FF99
        RRCA
        ADC A,B
        RET NC
        RST $30
        CP C
        NOP
        LD (DE),A
        SBC A,C
        NOP
; ----------------------------------------------------------------------
; RST_TABLE_9630_1 -- interior address inside the embedded 6502 restart block.
;   In/Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Not a Z-80 routine. See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_9630_1:
        LD (BC),A
        ADC A,B
        RET NC
        RST $30
        AND B
        POP AF
        CP C
        RST $38
        LD (DE),A
; ----------------------------------------------------------------------
; RST_TABLE_964F -- interior address inside the embedded 6502 restart block.
;   In:        Reached from the Z-80 via CALL/JP RST_TABLE_964F ($9356/$9370/$9A32) --
;              a SoftCard CPU-switch transfer into the 6502 code, NOT a Z-80 call;
;              the Z-80 target $964F lands mid-6502-instruction.
;   Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609. Not a Z-80 routine. See the cluster FLAG (extract to .s).
; ----------------------------------------------------------------------
RST_TABLE_964F:
        SBC A,C
        RST $38
        LD (BC),A
        ADC A,B
        RET NC
        RST $30
        ADC A,H
        CP B
        INC BC
        ADD A,H
; ----------------------------------------------------------------------
; RPC_DISPATCH_SETUP -- interior address inside the embedded 6502 restart block.
;   In:        Reached from the Z-80 via CALL RPC_DISPATCH_SETUP ($9363/$974F/$988B)
;              and adjacent to RPC_DISPATCH ($965E) -- both are SoftCard CPU-switch
;              transfers into the 6502 code. The Z-80 targets $9659 and $965E land
;              MID-6502-INSTRUCTION (inside the 6502 'STY $3E' / 'LDY #$C7' / 'RST'
;              stream), so they are NOT 6502 routine starts either.
;   Out/Clobbers/Algorithm: UNKNOWN as Z-80; part of the 6502 payload at
;              RST_TABLE_9609 (the slot-scan / cold-restart 6502 program). Not a Z-80
;              routine; how a Z-80 transfer here selects the 6502 service is the
;              documented OPEN QUESTION (shared with the $9400 block). See the cluster
;              FLAG (extract to .s).
; ----------------------------------------------------------------------
RPC_DISPATCH_SETUP:
        INC A
        ADC A,B
        ADD A,H
        LD A,$A0
; ----------------------------------------------------------------------
; RPC_DISPATCH (965E) -- MIS-DECODED embedded-6502, not Z-80. Interior of a 6502 cold-boot routine
; 9609-9700 (verified vs raw bytes: console init TEXT FB2F/SETVID FE93/SETKBD FE89, COUT loop to JMP
; FF65, page copies 1200->0200 and 13EF->03EF, slot/card-type scan via JSR 1117/1180 vs
; 1176,X/117A,X, writes 03B8 DSKCNT [DOC S&HD 2-27]/03C7/03C8/03DE/03DF + 02F8,Y, builds JMP AA00 at
; 1000). 965E=C7 operand of LDY #C7 at 965D; loop-top 965F JSR 1180. PROOF labels are artifacts: six
; BUILD_FCB targets land mid Z-80 instruction (9660/9690/96A9/96C8/96DF/96E9). Z-80 callers reach it
; via CPU switch (UNKNOWN). FLAG INCBIN extraction; no byte changes, no rewrites.
; ----------------------------------------------------------------------
RPC_DISPATCH:
        ; FLAG: NOT a Z-80 RST. 965E=C7 operand of 6502 LDY #C7 at 965D. Region 9609-9700 is
        ;       embedded 6502 mis-decoded as Z-80; extract to .s + INCBIN.
        RST $00
RPC_DISPATCH_1:
        JR NZ,$95E1
        LD DE,$A5EA
        LD A,$F0
        JR RPC_DISPATCH_6
; ----------------------------------------------------------------------
; RPC_DISPATCH_2 (9668) -- MIS-DECODED 6502. 9667 JSR 1117/966A STA 40/966C STX 41/966E JSR
; 1117/CPX#00/BEQ/CMP 40/BNE -- stable two-byte signature read. 9668=11 hi-byte of JSR 1117.
; ----------------------------------------------------------------------
RPC_DISPATCH_2:
        RLA
        ; FLAG: 6502. CORRECTION to peer: 9668 is the 11 hi-byte of JSR 1117 at 9667; STA 40 is at
        ;       966A (85 40), NOT 9669. 4085 is not a Z-80 address.
        LD DE,$4085
        ADD A,(HL)
        LD B,C
        JR NZ,RPC_DISPATCH_5
        LD DE,$00E0
        RET P
        LD E,$C5
        LD B,B
        RET NC
RPC_DISPATCH_3:
        LD A,(DE)
        CALL PO,$F041
        LD A,(DE)
        RET NC
        INC D
        AND $3E
        ADC A,H
        RET Z
        INC BC
        XOR C
RPC_DISPATCH_4:
        NOP
        ADC A,L
RPC_DISPATCH_5:
        RST $00
RPC_DISPATCH_6:
        INC BC
RPC_DISPATCH_7:
        ADC A,L
        SBC A,$03
        SBC A,B
        JR RPC_DISPATCH_27
RPC_DISPATCH_8:
        JR NZ,RST_TABLE_9609_3+1
        RST $18
        INC BC
        AND D
        NOP
        RET P
RPC_DISPATCH_9:
        RRA
        AND D
RPC_DISPATCH_10:
        INC B
        AND B
        DEC B
        OR C
        INC A
        DEFB $DD  ; ignored IX prefix; inner: HALT ; $969D  DD 76
        HALT
RPC_DISPATCH_11:
        LD DE,$09D0
        AND B
RPC_DISPATCH_12:
        RLCA
        OR C
        INC A
        DEFB $DD  ; ignored IX prefix; inner: LD A,D ; $96A6  DD 7A
        LD A,D
RPC_DISPATCH_13:
        LD DE,$03F0
RPC_DISPATCH_14:
        JP Z,$EBD0
        RET PE
; ----------------------------------------------------------------------
; RPC_DISPATCH_15 (96AF) -- MIS-DECODED 6502. 96AF CPX#02/96B1 BNE 96B6/96B3 INC 03B8 (bump
; DSKCNT/Card Type Table base [DOC S&HD 2-27]); 96B6 LDY 3D/TXA/STA 02F8,Y (per-slot
; type)/DEY/CPY#C0/BNE 965F. Z-80 93B6 JP 96AF via CPU switch (UNKNOWN).
; ----------------------------------------------------------------------
RPC_DISPATCH_15:
        ; FLAG: 6502. 96AF=CPX #02; match -> 96B3 INC 03B8 bumps DSKCNT [DOC S&HD 2-27]; STA 02F8,Y
        ;       records per-slot type; loop CPY #C0/BNE 965F. Extract to .s + INCBIN like
        ;       CPM_RPC6502.
        RET PO
        LD (BC),A
        RET NC
        INC BC
        XOR $B8
        INC BC
        AND H
        DEC A
        ADC A,D
; ----------------------------------------------------------------------
; RPC_DISPATCH_16 -- [MIS-DECODED: EMBEDDED 6502] bogus Z-80 framing of 6502 bytes in the 6502
; boot/console/probe overlay $9600-$96FF; UNKNOWN; fix=extract-to-.s+INCBIN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_16:
        SBC A,C
        RET M
        LD (BC),A
        ADC A,B
        RET NZ
        RET NZ
        RET NC
; ----------------------------------------------------------------------
; RPC_DISPATCH_17 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay $9600-$96FF; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_17:
        SBC A,(HL)
        LD C,$B8
        INC BC
        AND L
        LD A,$C9
; ----------------------------------------------------------------------
; RPC_DISPATCH_18 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; +1 cover $96C8 is a 6502
; mid-instruction artifact; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_18:
        LD BC,$1DF0
        ADD A,H
        DEC A
        XOR C
; ----------------------------------------------------------------------
; RPC_DISPATCH_19 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay $9600-$96FF; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_19:
        ADD A,L
        ADD A,L
        INC A
        ADC A,L
        ADD A,L
        RET NZ
        AND L
        LD A,$F0
        DJNZ RPC_DISPATCH_3
        NOP
; ----------------------------------------------------------------------
; RPC_DISPATCH_20 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_20:
        CP C
        DEC HL
; ----------------------------------------------------------------------
; RPC_DISPATCH_21 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay (11 F0 06 = 6502 STA $03xx,Y
; operands); UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_21:
        LD DE,$06F0
; ----------------------------------------------------------------------
; RPC_DISPATCH_22 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; +1 cover $96DF is a 6502
; mid-instruction artifact; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_22:
        JR NZ,RPC_DISPATCH_19
        DEFB $FD  ; ignored IY prefix; inner: RET Z ; $96E0  FD C8
        RET Z
        RET NC
        PUSH AF
        LD C,H
        LD H,L
        RST $38
        AND B
; ----------------------------------------------------------------------
; RPC_DISPATCH_23 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; +1 cover $96E9 is a 6502
; mid-instruction artifact; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_23:
        DJNZ RPC_DISPATCH_12
        RST $28
        INC DE
        SBC A,C
        RST $28
        INC BC
        ADC A,B
; ----------------------------------------------------------------------
; RPC_DISPATCH_24 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_24:
        RET NC
        RST $30
; ----------------------------------------------------------------------
; RPC_DISPATCH_25 -- [MIS-DECODED: EMBEDDED 6502] 6502 overlay; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_25:
        XOR C
        JP $008D
; ----------------------------------------------------------------------
; RPC_DISPATCH_26 -- [MIS-DECODED: EMBEDDED 6502] tail of the 6502 overlay; UNKNOWN; see summary.
; ----------------------------------------------------------------------
RPC_DISPATCH_26:
        DJNZ RPC_DISPATCH_11+2
; ----------------------------------------------------------------------
; RPC_DISPATCH_27 -- [MIS-DECODED: EMBEDDED 6502] tail; LD BC,BDOS_VAR_PAGE_p9_STG at $96FA is a
; 6502 artifact (the Z-80-launch builder); real Z-80 resumes at $9701; UNKNOWN.
; ----------------------------------------------------------------------
RPC_DISPATCH_27:
        NOP
        ADC A,L
        LD BC,BDOS_VAR_PAGE_p9_STG
        XOR D
        ADC A,L
        LD (BC),A
        ADD HL,BC
; ----------------------------------------------------------------------
; FCB_DIGIT_ACCUM -- [RE] FCB-name-field decimal digit accumulator (role uncertain). In: from
; FCB_WILDCARD_CMP_C $950A; $9701 lone SUB (HL) then LD HL,$9BCE, BC:=$000B. Out: B=value; error ->
; $9609 in the 6502 region (UNKNOWN). Algorithm: coherent Z-80 (CP space, SUB '0', CP 10, B=B*10
; carry-guarded). CAVEAT: reached from the FCB wildcard scanner (CP '?'); error target in the 6502
; block.
; ----------------------------------------------------------------------
FCB_DIGIT_ACCUM:
        SUB (HL)
        LD HL,$9BCE
        LD BC,$000B
        LD A,(HL)
; ----------------------------------------------------------------------
; FCB_DIGIT_ACCUM_STEP -- [RE] per-character step ($9709). B:=B*10+digit; space->$9833;
; non-digit/overflow/carry->$9609 (6502 region: UNKNOWN).
; ----------------------------------------------------------------------
FCB_DIGIT_ACCUM_STEP:
        CP ' '
        JP Z,DIR_EMIT_NAME_CHAR_7
        INC HL
        SUB '0'
        CP $0A
        JP NC,RST_TABLE_9609
        LD D,A
        LD A,B
        AND $E0
        JP NZ,RST_TABLE_9609
        LD A,B
        RLCA
        RLCA
        RLCA
        ADD A,B
        JP C,RST_TABLE_9609
        ADD A,B
        JP C,RST_TABLE_9609
        ADD A,D
        JP C,RST_TABLE_9609
        LD B,A
; ----------------------------------------------------------------------
; FCB_FIELD_LEN_LOOP -- [RE] field-length loop tail. DEC C; JP $9808 while C!=0 else RET.
; Loop-closure UNKNOWN under cover/shared-tail framing.
; ----------------------------------------------------------------------
FCB_FIELD_LEN_LOOP:
        DEC C
        JP NZ,DIR_EMIT_NAME_CHAR_3
        RET
; ----------------------------------------------------------------------
; FCB_FIELD_BLANKS -- [RE] verify the rest of the field is blanks. CP space; non-blank -> $9609
; abort (6502 region: UNKNOWN).
; ----------------------------------------------------------------------
FCB_FIELD_BLANKS:
        LD A,(HL)
        CP ' '
        JP NZ,RST_TABLE_9609
        INC HL
        DEC C
; ----------------------------------------------------------------------
; FCB_FIELD_BLANKS_LOOP -- [RE] loop/return tail of the blank check. The +1 entry $973C is a
; shared-tail target of SEARCH_BUILTIN_1 ($9544); clean framing UNKNOWN; not split.
; ----------------------------------------------------------------------
FCB_FIELD_BLANKS_LOOP:
        JP NZ,DIR_EMIT_NAME_CHAR_7
        LD A,B
        RET
; ----------------------------------------------------------------------
; COPY_FCB_EXT -- [RE] copy the 3-byte FCB type/extension field HL->DE. CAVEAT: the tail back-edge
; ($9747 -> $9842) does NOT close this 3-byte copy at $9742; back-edge UNKNOWN.
; ----------------------------------------------------------------------
COPY_FCB_EXT:
        LD B,$03
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
; ----------------------------------------------------------------------
; COPY_FCB_EXT_LOOP -- [RE] byte-count tail of the extension copy. DEC B; branch (to $9842, which
; does NOT match this copy body -- UNKNOWN) else RET.
; ----------------------------------------------------------------------
COPY_FCB_EXT_LOOP:
        DEC B
        JP NZ,CCP_NEWLINE_AND_FILEOP
        RET
; ----------------------------------------------------------------------
; TBUFF_INDEX_FETCH -- [RE] index into the command-tail buffer (TBUFF). LD HL,TBUFF, ADD A,C, fall
; into TBUFF_INDEX_FETCH_2 (which CALLs $9659 in the 6502 region; final address partly UNKNOWN).
; ----------------------------------------------------------------------
TBUFF_INDEX_FETCH:
        LD HL,TBUFF                      ; base of command-tail buffer at 0080H [DOC CPMREF 3-47 ; facts sec.7.5] (0080H = tail length, 0081H+ = upper-cased command-line tail)
        ADD A,C
; ----------------------------------------------------------------------
; TBUFF_INDEX_FETCH_2 -- [RE] finalise the indexed address and read the byte. CALL $9659, LD A,(HL),
; RET. WARNING: $9659 is in the embedded 6502 overlay; its RPC_DISPATCH_SETUP label is a bogus Z-80
; framing, so this CALL's effect is UNKNOWN.
; ----------------------------------------------------------------------
TBUFF_INDEX_FETCH_2:
        CALL RPC_DISPATCH_SETUP
        LD A,(HL)
        RET
; ----------------------------------------------------------------------
; RESOLVE_DRIVE_PREFIX -- [RE] clear the FCB drive byte, then select the parsed drive if it differs.
; XOR A/LD ($9BCD),A; LD A,($9BF0); OR A/RET Z; DEC A; CP (CMD_EXEC_69)/RET Z; else JP RPC6502_E0BD
; (select-disk RPC).
; ----------------------------------------------------------------------
RESOLVE_DRIVE_PREFIX:
        XOR A
        LD ($9BCD),A
        LD A,($9BF0)
        OR A
        RET Z
        DEC A
        LD HL,CMD_EXEC_69
        CP (HL)
        RET Z
        JP RPC6502_E0BD
; ----------------------------------------------------------------------
; RESOLVE_DRIVE_PREFIX_2 -- [RE] select the parsed drive (variant, no FCB-drive zeroing). LD
; A,($9BF0)/OR A/RET Z; DEC A; CP (CMD_EXEC_69)/RET Z; else LD A,(CMD_EXEC_69)/JP RPC6502_E0BD.
; ----------------------------------------------------------------------
RESOLVE_DRIVE_PREFIX_2:
        LD A,($9BF0)
        OR A
        RET Z
        DEC A
        LD HL,CMD_EXEC_69
        CP (HL)
        RET Z
        LD A,(CMD_EXEC_69)
        JP RPC6502_E0BD
; ----------------------------------------------------------------------
; DIR_CMD CCP DIR built-in
; ----------------------------------------------------------------------
DIR_CMD:
        CALL RPC_DISPATCH
        ; [RE] CCP print-newline ($9854==2.23 CCP_PRINT_NEWLINE, 6x; garbage Z-80 only b/c
        ; embedded-6502 region; +2 into MSG_ALL_YN mis-split; frozen pending audit). NOT UNKNOWN
        CALL $9854
        LD HL,$9BCE
        LD A,(HL)
; ----------------------------------------------------------------------
; blank test; $9782 also a live JR NZ entry, GENUINE overlap NOT split
; ----------------------------------------------------------------------
DIR_CMD_1:
        CP $20
        JP NZ,$988F
        LD B,$0B
        LD (HL),$3F
        INC HL
        DEC B
        JP NZ,CMD_EXEC_1
        LD E,$00
        PUSH DE
        CALL RPC6502_E0E9
        CALL Z,DIR_EMIT_NAME_CHAR_1+2
DIR_CMD_2:
        JP Z,CMD_EXEC_15
        LD A,($9BEE)
        RRCA
        RRCA
        RRCA
        AND $60
        LD C,A
        LD A,$0A
        CALL CCP_CONOUT_A
        RLA
        JP C,CMD_EXEC_14
        POP DE
        LD A,E
        INC E
        PUSH DE
        AND $01
        PUSH AF
        JP NZ,CMD_EXEC_5
        CALL RPC6502_E098
        PUSH BC
        CALL GET_CUR_DRIVE
        POP BC
        ADD A,$41
        CALL RPC6502_E092
        LD A,$3A
        CALL RPC6502_E092
        JP CMD_EXEC_6
; ----------------------------------------------------------------------
; ->DIR_FMT_ENTRY_COLS dir name/type field (non-prefix), ==CPMV223 DIR_CMD_4/_5
; ----------------------------------------------------------------------
DIR_FMT_ENTRY_COLS:
        CALL RPC6502_E0A2
        LD A,':'
        CALL RPC6502_E092
        CALL RPC6502_E0A2
        LD B,$01
; ----------------------------------------------------------------------
; ->DIR_EMIT_NAME_CHAR per-char emit loop pause/abort ==CPMV223 DIR_CMD_6..9. NOTE 2.20 DIR uses AND
; $01 not 2.23 AND $03
; ----------------------------------------------------------------------
DIR_EMIT_NAME_CHAR:
        LD A,B
        CALL CCP_CONOUT_A
        AND $7F
        CP ' '
        JP NZ,CMD_EXEC_10+1
        POP AF
        PUSH AF
        CP $03
DIR_EMIT_NAME_CHAR_1:
        JP NZ,CMD_EXEC_9
        LD A,$09
        CALL CCP_CONOUT_A
        AND $7F
        CP $20
        JP Z,CMD_EXEC_13+2
DIR_EMIT_NAME_CHAR_2:
        LD A,$20
        CALL RPC6502_E092
        INC B
        LD A,B
        CP $0C
        JP NC,CMD_EXEC_13+2
        CP $09
        JP NZ,CMD_EXEC_7
DIR_EMIT_NAME_CHAR_3:
        CALL RPC6502_E0A2
        JP CMD_EXEC_7
; ----------------------------------------------------------------------
; ->DIR_SEARCH_NEXT next match; CMD_DISPATCH_TBL $95C2 via CALL NOT the JP(HL) dispatcher $95C0
; ----------------------------------------------------------------------
DIR_SEARCH_NEXT:
        POP AF
        CALL CMD_DISPATCH_TBL
        JP NZ,CMD_EXEC_15
        CALL RPC6502_E0E4
        JP CMD_EXEC_2+1
; ----------------------------------------------------------------------
; ->DIR_EXIT leave DIR, jump CCP re-entry $9B86
; ----------------------------------------------------------------------
DIR_EXIT:
        POP DE
        JP CMD_EXEC_63+1
; ----------------------------------------------------------------------
; ->ERA_CMD CCP ERA built-in; all-wildcard CP $0B ->'ALL (Y/N)?'->'Y'; 1:1 CPMV223 ERA_CMD
; ----------------------------------------------------------------------
ERA_CMD:
        CALL RPC_DISPATCH
        CP $0B
        JP NZ,CMD_EXEC_18
        ; [RE] 'ALL (Y/N)?' prompt interior-offset form ($9952=$9852+$100; like READ ERROR/NO FILE
        ; +$200), not breakage; RPC decode UNKNOWN, left literal
        LD BC,$9952
        CALL RPC6502_E0A7
        CALL SEARCH_BUILTIN_1+2
        LD HL,SUBMIT_FLAG
DIR_EMIT_NAME_CHAR_7:
        DEC (HL)
        JP NZ,DIR_CMD_1+1
        INC HL
        LD A,(HL)
        CP $59
        JP NZ,DIR_CMD_1+1
        INC HL
DIR_EMIT_NAME_CHAR_8:
        LD (PARSE_PTR),HL
; ----------------------------------------------------------------------
; ->CCP_NEWLINE_AND_FILEOP newline+FCB fileop tail (==CPMV223 ERA_CMD_1). FLAG: caller $9A2B sets up
; a 16-byte copy then CALLs $9842(=newline) clobbering it -- separate load/exec mis-decode
; ----------------------------------------------------------------------
CCP_NEWLINE_AND_FILEOP:
        CALL $9854
        LD DE,$9BCD
        CALL RPC6502_E0EF
; ----------------------------------------------------------------------
; ->CCP_CONOUT_A console-output/flush tail (==CPMV223 CONOUT_A $96EC, 3x); console OUTPUT not input
; ----------------------------------------------------------------------
CCP_CONOUT_A:
        INC A
        CALL Z,DIR_EMIT_NAME_CHAR_1+2
        JP CMD_EXEC_63+1
; ----------------------------------------------------------------------
; [FLAG code/data MIS-SPLIT] only copy of text; $9852 referenced by NOTHING, $9854(+2) is the live
; 6x CALL = print-newline routine; MUST audit, CALL $9854 frozen
; ----------------------------------------------------------------------
MSG_ALL_YN:
        ; [FLAG] $9852 referenced by nothing; $9854(+2) is the live CALL/print-newline entry --
        ; code/data split UNVERIFIED, audit required
        DEFB    "ALL (Y/N)?"             ; ERA confirm prompt
        DEFB    $00                      ; terminator
PRINT_STR_AT:
        CALL RPC_DISPATCH
        JP NZ,RST_TABLE_9609
        CALL $9854
CMD_EXEC:
        CALL RPC6502_E0D0
        JP Z,RECORD_SCAN_STEP+2
        CALL RPC6502_E098
        LD HL,CMD_EXEC_69+2
        LD (HL),$FF
        LD HL,CMD_EXEC_69+2
        LD A,(HL)
        CP $80
        JP C,RECPTR_CMP16_TAIL
        PUSH HL
        CALL RPC6502_E0FE
        POP HL
        JP NZ,RECORD_SCAN_BODY+2
        XOR A
        LD (HL),A
        INC (HL)
CMD_EXEC_1:
        LD HL,$0080
        CALL RPC_DISPATCH_SETUP
        LD A,(HL)
        CP $1A
        JP Z,CMD_EXEC_63+1
        CALL RPC6502_E08C
CMD_EXEC_2:
        CALL CMD_DISPATCH_TBL
        JP NZ,CMD_EXEC_63+1
        JP FCB_CLEAR_BYTE_PAD+2
CMD_EXEC_3:
        DEC A
        JP Z,CMD_EXEC_63+1
        CALL DIR_EMIT_NAME_CHAR
        CALL CMD_EXEC
        JP RST_TABLE_9609
CMD_EXEC_4:
        CALL DIR_EMIT_NAME_CHAR_2+1
        PUSH AF
        CALL RPC_DISPATCH
        JP NZ,RST_TABLE_9609
        CALL $9854
        LD DE,$9BCD
        PUSH DE
        CALL RPC6502_E0EF
        POP DE
        CALL FCB_WILDCARD_CMP_C
        JP Z,EXTENT_INDEX_TEST_TAIL
        XOR A
        LD ($9BED),A
CMD_EXEC_5:
        POP AF
        LD L,A
        LD H,$00
        ADD HL,HL
        LD DE,$0100
CMD_EXEC_6:
        LD A,H
        OR L
        JP Z,DISK_BUF_MOVE_GO+1
CMD_EXEC_7:
        DEC HL
        PUSH HL
        LD HL,$0080
        ADD HL,DE
        PUSH HL
        CALL RPC_CALL_HL
        LD DE,$9BCD
        CALL FCB_WILDCARD_TEST+1
        POP DE
        POP HL
        JP NZ,EXTENT_INDEX_TEST_TAIL
        JP DIR_RECORD_READ
CMD_EXEC_8:
        LD DE,$9BCD
        CALL RPC6502_E0DA
CMD_EXEC_9:
        INC A
CMD_EXEC_10:
        JP NZ,CCP_RPC_THEN_LOOP
        LD BC,MSG_NO_SPACE
        CALL $C2A7
        DEFB $FD  ; ignored IY prefix; inner: AND B ; $9901  FD A0
        AND B
        RET
CMD_EXEC_11:
        INC C
        DEC C
        RET Z
        ADD HL,HL
        JP BDOS_RET_RESULT_1_STG+2
CMD_EXEC_12:
        PUSH BC
CMD_EXEC_13:
        LD A,($9F42)
CMD_EXEC_14:
        LD C,A
        LD HL,$0001
        CALL BDOS_RET_RESULT_1_STG+1
        POP BC
        LD A,C
        OR L
        LD L,A
        LD A,B
CMD_EXEC_15:
        OR H
        LD H,A
        RET
; ----------------------------------------------------------------------
; DRIVE_BIT_TEST -- per-drive bit test in a BDOS alloc/RO word (orphan; load $A9AD, C=drive $9F42,
; CALL $A0EA, AND $01). [RE] vector UNKNOWN.
; ----------------------------------------------------------------------
DRIVE_BIT_TEST:
        LD HL,(BDOS_VAR_PAGE_7_p8_STG)
        LD A,($9F42)
        LD C,A
        CALL BDOS_CON_41_p12_STG
        LD A,L
        AND $01
        RET
CMD_EXEC_17:
        LD HL,BDOS_VAR_PAGE_7_p8_STG
        LD C,(HL)
        INC HL
        LD B,(HL)
        CALL CON_START_COLUMN_STG
        LD (BDOS_VAR_PAGE_7_p8_STG),HL
        LD HL,(BDOS_VAR_PAGE_7_p35_STG)
        INC HL
        EX DE,HL
        LD HL,(BDOS_VAR_PAGE_7_p14_STG)
        LD (HL),E
        INC HL
CMD_EXEC_18:
        LD (HL),D
        RET
; ----------------------------------------------------------------------
; FCB_RO_FLAG_TEST ($9944) -- FCB R/O bit test (orphan). FIX2: ADD $0009 reaches FCB byte 9 = first
; file-TYPE char T1 (bit7=R/O), NOT first filename char; RLA, RET NC; else HL=$9C0F JP $9F4A (mid
; CCP_TAIL, left literal -- deferred).
; ----------------------------------------------------------------------
FCB_RO_FLAG_TEST:
        CALL FCB_SET_REC_FLAG_3_p4_STG
        LD DE,$0009
        ADD HL,DE
        LD A,(HL)
        ; bit 7 of FCB byte 9 (T1, first file-TYPE char) = the CP/M R/O attribute -> shift into
        ; carry
        RLA
        RET NC
        LD HL,$9C0F
        JP CONOUT_PUTC_STG+2
CMD_EXEC_20:
        CALL BDOS_SAVED_SP_p13_STG+2
        RET Z
        LD HL,$9C0D
        JP CONOUT_PUTC_STG+2
; ----------------------------------------------------------------------
; FCB_BUF_PTR_ADD_OFFSET -- form a byte pointer into the BDOS disk buffer: HL = bufptr + offset.
;   In:        BDOS_VAR_PAGE_7_p20 ($A9B9) = 16-bit disk/deblock-buffer base pointer;
;              BDOS_VAR_PAGE_9_p5 ($A9E9) = 8-bit byte offset within that buffer.
;   Out:       HL = ($A9B9) + ($A9E9) (16-bit add of an 8-bit offset, carry rippled into H).
;   Clobbers:  A, HL, flags.
;   Algorithm: load the buffer base into HL, add the unsigned byte offset to L, propagate the carry
;              into H (RET NC skips the INC H). Indexes a record byte in the BDOS disk buffer.
;              Reached indirectly via the CCP CMD_DISPATCH_TBL ($95C2, cluster-9). [RE] cell roles
;              inferred from BDOS usage.
; ----------------------------------------------------------------------
FCB_BUF_PTR_ADD_OFFSET:
        ; load the BDOS disk/deblock-buffer base pointer ($A9B9)
        LD HL,(BDOS_VAR_PAGE_7_p20_STG)
        LD A,(BDOS_VAR_PAGE_9_p5_STG)
        ; add the 8-bit byte offset to the low byte of the buffer pointer
        ADD A,L
        LD L,A
        RET NC
        ; carry out of the low byte rippled into the high byte
        INC H
        RET
; ----------------------------------------------------------------------
; FCB_GET_S2 -- fetch the current FCB's S2 byte (FCB offset 14) via the BDOS info-address cell.
;   In:        BDOS_DE_PARAM ($9F43) = caller's DE info-address = current CP/M FCB pointer (the
;              CCP-local name BDOS_DISPATCH_PTR was a MISLABEL for this same cell -- see summary).
;   Out:       A = FCB[FCB_S2] = FCB+14 (reserved / extent-high 'module' byte).
;   Clobbers:  A, DE, HL, flags.
;   Algorithm: HL := current FCB pointer; add FCB_S2 (offset 14); read the byte. [RE] reads the
;              extent-high field used by multi-extent file-position arithmetic.
; ----------------------------------------------------------------------
FCB_GET_S2:
        ; HL := current FCB pointer (BDOS_DE_PARAM, the BDOS caller-DE / info-address cell $9F43)
        LD HL,(BDOS_DISPATCH_PTR)
        ; FCB_S2 offset (14 = reserved / extent-high byte)
        LD DE,$000E
        ADD HL,DE
        ; read FCB.S2 into A
        LD A,(HL)
        RET
; ----------------------------------------------------------------------
; FCB_CLEAR_BYTE_PAD -- 2 dead cover bytes ahead of the real FCB_CLEAR_BYTE entry.
;   In:        the leading $CD $69 at $9972 are NEVER reached as code (FCB_GET_S2 RETs at $9971; no
;              ref targets $9972). The real entry is FCB_CLEAR_BYTE at +2 ($9974), reached only via
;              JP FCB_CLEAR_BYTE_PAD+2 from $989D.
;   Out:       n/a (cover bytes); see FCB_CLEAR_BYTE.
;   Clobbers:  n/a.
;   Algorithm: see the split: cover DEFB $CD,$69 then FCB_CLEAR_BYTE (AND C / LD (HL),$00 / RET) -
;              zeroes a single record/FCB byte the caller has pointed HL at.
; ----------------------------------------------------------------------
FCB_CLEAR_BYTE_PAD:
        CALL FCB_SET_REC_FLAG_3_p14_STG+1
        LD (HL),$00
        RET
        DEFB    $CD,$69,$A1,$F6,$80      ; "Mi!v"
; ----------------------------------------------------------------------
; FCB_STORE_A_DEAD -- 'LD (HL),A; RET' fragment reachable ONLY via the $9978 orphan.
;   In:        A = byte; HL -> cell -- BUT no live path reaches here: the only fall-in is from the
;              unreferenced $9978 orphan (FCB_SET_BYTE_HIBIT), and $997D has ZERO direct references.
;   Out:       (HL) := A; RET.
;   Clobbers:  none.
;   Algorithm: single store-and-return. [RE] effectively dead/orphan (the tail the $9978 orphan
;              falls into). UNKNOWN whether it was once a live branch target.
; ----------------------------------------------------------------------
FCB_STORE_A_DEAD:
        ; store the byte at (HL) -- only reached via the dead $9978 orphan fall-through
        LD (HL),A
        RET
; ----------------------------------------------------------------------
; RECPTR_CMP16 -- 16-bit compare: set up DE := ($A9EA) vs the word *(($A9B3)).
;   In:        BDOS_VAR_PAGE_9_p6 ($A9EA) = 16-bit record/match-result value; BDOS_VAR_PAGE_7_p14
;              ($A9B3) = pointer to a 2-byte (little-endian) working value.
;   Out:       falls into RECPTR_CMP16_TAIL (RECPTR_CMP16_TAIL) computing ($A9EA) - *(($A9B3)) into
;              flags.
;   Clobbers:  A, DE, HL, flags.
;   Algorithm: DE := ($A9EA); HL := *(($A9B3)) pointer; A := E; continue into the subtract tail.
;              [RE] sets up a 16-bit magnitude compare of two record counters.
; ----------------------------------------------------------------------
RECPTR_CMP16:
        ; load the record/match-result word ($A9EA) to compare
        LD HL,(BDOS_VAR_PAGE_9_p6_STG)
        EX DE,HL
        ; HL := pointer to the 2-byte working value ($A9B3)
        LD HL,(BDOS_VAR_PAGE_7_p14_STG)
        LD A,E
; ----------------------------------------------------------------------
; RECPTR_CMP16_TAIL -- 16-bit subtract tail: (DE) - *(HL) leaving the result in flags/A.
;   In:        DE = the value being compared; HL -> low byte of the 2-byte operand.
;   Out:       A = high-byte result; carry/zero reflect the 16-bit compare; HL advanced past the low
;              byte.
;   Clobbers:  A, HL, flags.
;   Algorithm: A := E - (HL) (low byte); INC HL; A := D - (HL) - borrow (high byte). [RE] standard
;              little-endian 16-bit compare; only flags matter to the caller.
; ----------------------------------------------------------------------
RECPTR_CMP16_TAIL:
        ; subtract the low byte of the operand
        SUB (HL)
        INC HL
        LD A,D
        ; subtract the high byte with borrow -> 16-bit compare result in flags
        SBC A,(HL)
        RET
; ----------------------------------------------------------------------
; RECPTR_INC_STORE -- after the BDOS extent step, bump DE and write it back as a 2-byte cell.
;   In:        DE = a record/extent value; HL set by the BDOS helper (FCB_SET_REC_FLAG_3_p35+2) to
;              point at the HIGH byte of a 2-byte little-endian destination.
;   Out:       on carry from the helper, RET (no update); else DE incremented and stored
;              (HL)=hi,(HL-1)=lo.
;   Clobbers:  A (in helper), DE, HL, flags.
;   Algorithm: CALL the BDOS extent/record helper; if carry, bail; otherwise INC DE and write the
;              word back high-then-low (HL points at the high byte). [RE] record-count write-back.
; ----------------------------------------------------------------------
RECPTR_INC_STORE:
        ; BDOS extent/record helper -- positions HL and returns carry on failure (cross-module BDOS,
        ; kept)
        CALL FCB_SET_REC_FLAG_3_p35_STG+2
        RET C
        ; advance the record/extent value by one
        INC DE
        ; write back the updated word (high byte here, low byte below)
        LD (HL),D
        DEC HL
        LD (HL),E
        RET
; ----------------------------------------------------------------------
; SUB16_DE_HL -- 16-bit subtract: HL := DE - HL.
;   In:        DE, HL = 16-bit operands.
;   Out:       HL = DE - HL; carry/zero reflect the subtraction.
;   Clobbers:  A, HL, flags.
;   Algorithm: A := E - L (low byte) -> L; A := D - H - borrow (high byte) -> H. [RE] a record/
;              extent delta used to size a remaining transfer.
; ----------------------------------------------------------------------
SUB16_DE_HL:
        LD A,E
        ; low byte: E - L
        SUB L
        LD L,A
        LD A,D
        ; high byte: D - H - borrow -> HL = DE - HL
        SBC A,H
        LD H,A
        RET
; ----------------------------------------------------------------------
; RECORD_SCAN_INIT -- seed the record scan with C = $FF then fall into the scan body.
;   In:        none (sets C := $FF as the scan sentinel/limit).
;   Out:       falls through into RECORD_SCAN_BODY (RECORD_SCAN_BODY) with C = $FF.
;   Clobbers:  C.
;   Algorithm: C := $FF (initial sentinel) and continue. [RE] sentinel value inferred from the
;              INC C / JP Z test inside the scan body.
; ----------------------------------------------------------------------
RECORD_SCAN_INIT:
        ; seed the scan with C = $FF (the INC C below tests for the $FF->$00 wrap)
        LD C,$FF
; ----------------------------------------------------------------------
; RECORD_SCAN_BODY -- load two record-pointer words, then enter the BDOS extent helper + scan loop.
;   In:        fall-through: C = $FF from RECORD_SCAN_INIT. Alt entry +2 ($99A0,
;              RECORD_SCAN_BODY_ALT)
;              reached by JP NZ from $9882. BDOS_VAR_PAGE_9_p8 ($A9EC) = cached record/result word;
;              BDOS_VAR_PAGE_7_p39 ($A9CC) = a record-pointer working value.
;   Out:       DE := ($A9EC); HL := ($A9CC); falls into RECORD_SCAN_STEP (RECORD_SCAN_STEP).
;   Clobbers:  A (alt entry only), DE, HL, flags.
;   Algorithm: DUAL ENTRY (shared-tail): tenant-1 fall-through runs LD HL,($A9EC) (2A EC A9, the $A9
;              high byte doubling as the next opcode); tenant-2 alt entry $99A0 runs that $A9 as XOR
;              C before EX DE,HL / LD HL,($A9CC). [RE]
; ----------------------------------------------------------------------
RECORD_SCAN_BODY:
        LD HL,(BDOS_VAR_PAGE_9_p8_STG)
        EX DE,HL
        ; HL := the record-pointer working value ($A9CC) for the scan step below
        LD HL,(BDOS_VAR_PAGE_7_p39_STG)
; ----------------------------------------------------------------------
; RECORD_SCAN_STEP -- run the BDOS extent/record helper, then test a record against a buffer cell.
;   In:        fall-through: HL/DE from RECORD_SCAN_BODY, C = sentinel. Alt entry +2 ($99A7,
;              RECORD_SCAN_STEP_ALT) reached by JP Z from $9869. BDOS_VAR_PAGE_7_p24 ($A9BD) and
;              _9_p8 ($A9EC) hold record pointers/counters.
;   Out:       returns (RET NC / RET Z) at decision points; on the wrap path JP into
;              DISK_READ_RECORD+1; otherwise CALL the BDOS extent helper + BDOS_CON_49 tail.
;   Clobbers:  A, BC, DE, HL, flags.
;   Algorithm: tenant-1 fall-through: CALL FCB_SET_REC_FLAG_5+2 (CD 95 A1, $A1 doubling as next
;              opcode); RET NC; save C; CALL a BDOS record-state helper; HL := ($A9EC)+($A9BD);
;              restore C, INC C and if it wrapped from $FF to 0 JP DISK_READ_RECORD+1; else CP (HL)
;              and RET Z or run the FCB extent + record helpers. tenant-2 alt entry $99A7 = AND C
;              then RET NC. [RE] $A9xx are BDOS variable-page scratch; CALL targets are BDOS
;              internals (kept).
; ----------------------------------------------------------------------
RECORD_SCAN_STEP:
        CALL FCB_SET_REC_FLAG_5_STG+2
        RET NC
        PUSH BC
        ; BDOS record-state helper (cross-module BDOS, kept) -- the target name may itself be
        ; mislabeled; role here is record bookkeeping [RE]
        CALL BDOS_GET_IOBYTE_FN_p10_STG
        LD HL,(BDOS_VAR_PAGE_7_p24_STG)
        EX DE,HL
        LD HL,(BDOS_VAR_PAGE_9_p8_STG)
        ; HL := record cache ($A9EC) + offset ($A9BD) -> address of the record byte to test
        ADD HL,DE
        POP BC
        ; if C was the $FF sentinel it wraps to 0 (Z) -> take the read-record path
        INC C
        ; sentinel exhausted -> enter the BDOS read-record path (cross-module BDOS, kept)
        JP Z,DISK_READ_RECORD_STG+1
        ; compare the candidate against the record byte at the computed address
        CP (HL)
        RET Z
        CALL FCB_SET_REC_FLAG_3_p35_STG+2
        RET NC
        CALL BDOS_CON_49_p7_STG+1
        RET
; ----------------------------------------------------------------------
; FCB_STORE_A_ORPHAN -- unreferenced 'LD (HL),A; RET' fragment.
;   In:        A = byte; HL -> cell -- BUT $99C4 has ZERO references in CCP or BDOS and is NOT
;              reached
;              by fall-through (RECORD_SCAN_STEP RETs at $99C3). The peer's claim it is 'a branch
;              target
;              used by the scan code above' is FALSE.
;   Out:       (HL) := A; RET.
;   Clobbers:  none.
;   Algorithm: single store-and-return. UNKNOWN reachability -- effectively dead/orphan. Decodes as
;              clean code (77 C9), so left as real instructions.
; ----------------------------------------------------------------------
FCB_STORE_A_ORPHAN:
        ; store the byte at (HL) -- orphan: no caller references $99C4 (UNKNOWN reachability)
        LD (HL),A
        RET
; ----------------------------------------------------------------------
; DIR_RECORD_WRITE -- run two BDOS helpers, set count=1, then tail into the BDOS record code.
;   In:        BDOS extent state set up by the callers; the BDOS variable page addresses the record
;              buffer.
;   Out:       calls FCB_SET_REC_FLAG_5_p9 + DISK_READ_RECORD_1_p15+1, sets C := $01, calls
;              BDOS_CON_8, then tail-jumps into DISK_READ_RECORD_1_p8+2.
;   Clobbers:  A, C, HL, flags (per the BDOS helpers).
;   Algorithm: CALL the BDOS extent helper; CALL the BDOS record helper; C := $01; CALL BDOS_CON_8;
;              JP into the read-record continuation. [RE] all targets are BDOS internals (kept).
;              The C := $01 reading as a record count and BDOS_CON_8's role are UNKNOWN (the
;              BDOS_CON_* names may share the CONOUT mislabel).
; ----------------------------------------------------------------------
DIR_RECORD_WRITE:
        CALL FCB_SET_REC_FLAG_5_p9_STG
        CALL DISK_READ_RECORD_1_p15_STG+1
        ; C := $01 ([RE] one record / op count) for the BDOS call
        LD C,$01
        CALL BDOS_CON_8_STG
        ; tail into the BDOS read-record continuation (cross-module BDOS, kept)
        JP DISK_READ_RECORD_1_p8_STG+2
; ----------------------------------------------------------------------
; DIR_RECORD_READ -- run the BDOS record helper, point HL at the DMA cell, tail into the read step.
;   In:        BDOS extent state; BDOS_VAR_PAGE_7_p12 ($A9B1) = the DMA-address cell.
;   Out:       JP DISK_READ_RECORD_2 with HL -> the DMA cell ($A9B1).
;   Clobbers:  A, C, HL, flags (per the BDOS helpers).
;   Algorithm: CALL DISK_READ_RECORD_1_p15+1; CALL BDOS_CON_7+2; HL := &($A9B1) DMA cell; JP
;              DISK_READ_RECORD_2. [RE] BDOS internals kept; $A9B1 is the DMA pointer cell.
; ----------------------------------------------------------------------
DIR_RECORD_READ:
        CALL DISK_READ_RECORD_1_p15_STG+1
        CALL BDOS_CON_7_STG+2
        ; HL := address of the BDOS DMA-pointer cell ($A9B1)
        LD HL,BDOS_VAR_PAGE_7_p12_STG
        JP DISK_READ_RECORD_2_STG
; ----------------------------------------------------------------------
; SET_DMA_TO_DISK_BUF -- point the BIOS DMA at the BDOS disk buffer, then jump to BIOS SETDMA.
;   In:        BDOS_VAR_PAGE_7_p20 ($A9B9) = 16-bit disk/deblock-buffer pointer (lo ($A9B9), hi
;              ($A9BA)).
;   Out:       BC = the buffer pointer; control transfers to BIOS SETDMA ($AA24) which records the
;              DMA address for the next physical read/write. Tail JP, does not return here.
;   Clobbers:  BC, HL.
;   Algorithm: HL := &($A9B9); BC := the 16-bit pointer there; JP $AA24. $AA24 = BIOS jump-table
;              entry 12 (SETDMA = BIOS_BASE $AA00 + 12*3), in the BIOS (a SEPARATE output binary,
;              off this CCP+BDOS image) -- kept literal as a documented cross-module BIOS call.
; ----------------------------------------------------------------------
SET_DMA_TO_DISK_BUF:
        ; HL := address of the disk-buffer pointer cell ($A9B9)
        LD HL,BDOS_VAR_PAGE_7_p20_STG
        LD C,(HL)
        INC HL
        LD B,(HL)
        ; BIOS SETDMA (jump-table entry 12 = $AA00+12*3; BIOS is a separate output image off this
        ; CCP+BDOS image -- cross-module, kept literal) with BC = buffer pointer
        JP $AA24
; ----------------------------------------------------------------------
; DISK_BUF_MOVE -- set up a record move between the disk buffer and the current DMA target.
;   In:        BDOS_VAR_PAGE_7_p20 ($A9B9) = disk-buffer pointer; BDOS_VAR_PAGE_7_p12 ($A9B1) =
;              current
;              DMA-address cell.
;   Out:       DE := ($A9B9) one endpoint, HL := ($A9B1) the other; falls into DISK_BUF_MOVE_GO
;              (DISK_BUF_MOVE_GO) which sets the $80 count and tail-jumps into the BDOS record code.
;   Clobbers:  DE, HL.
;   Algorithm: DE := disk buffer ptr; HL := DMA pointer; continue. [RE] sets up moving one CP/M
;              record ($80=128 bytes) between the deblock buffer and the caller's DMA area.
; ----------------------------------------------------------------------
DISK_BUF_MOVE:
        ; load the disk-buffer pointer ($A9B9)
        LD HL,(BDOS_VAR_PAGE_7_p20_STG)
        EX DE,HL
        ; HL := the current DMA address ($A9B1)
        LD HL,(BDOS_VAR_PAGE_7_p12_STG)
; ----------------------------------------------------------------------
; DISK_BUF_MOVE_GO -- set the $80 count and tail into the BDOS record (disk-store) code.
;   In:        fall-through from DISK_BUF_MOVE with DE/HL = the two endpoints; sets C := $80 (128 =
;              one CP/M record). Alt entry +1 ($99F1, DISK_BUF_MOVE_GO_ALT) reached by JP Z from
;              $98D6, where the $80 operand byte runs as ADD A,B.
;   Out:       JP CONOUT_PUTC_p6+1 ($9F4F) -- a BDOS DISK/SECTOR-STORE routine (NOTE: CONOUT_PUTC is
;              a KNOWN BDOS mislabel: disk/sector code, not console output -- see summary + BDOS
;              line 841-848).
;   Clobbers:  C (fall-through) or A (alt entry).
;   Algorithm: DUAL ENTRY (shared-tail): tenant-1 fall-through C := $80 (0E 80) then JP into the
;              BDOS
;              record code; tenant-2 alt entry $99F1 runs the $80 byte as ADD A,B then the same JP.
;              The $80 is the CP/M record-size constant (kept literal). [RE]
; ----------------------------------------------------------------------
DISK_BUF_MOVE_GO:
        LD C,$80
        ; tail into the BDOS record (disk-sector) store routine (cross-module, kept; CONOUT_PUTC is
        ; a known BDOS mislabel -- disk/sector code, not console)
        JP CONOUT_PUTC_p6_STG+1
; ----------------------------------------------------------------------
; EXTENT_INDEX_TEST -- compare two adjacent record/extent index bytes; signal a match via A+1.
;   In:        BDOS_VAR_PAGE_9_p6 ($A9EA) = first index byte; ($A9EB) = the next byte.
;   Out:       falls into EXTENT_INDEX_TEST_TAIL (EXTENT_INDEX_TEST_TAIL): bytes differ -> RET (NZ)
;              A unchanged;
;              equal -> A := A+1 then RET.
;   Clobbers:  A, HL, flags.
;   Algorithm: HL := &($A9EA); A := (HL); INC HL; CP (HL) -> compares ($A9EA) vs ($A9EB). [RE] tests
;              whether two record/extent indices match (detect end-of-extent).
; ----------------------------------------------------------------------
EXTENT_INDEX_TEST:
        ; HL := address of the first index byte ($A9EA)
        LD HL,BDOS_VAR_PAGE_9_p6_STG
        LD A,(HL)
        INC HL
        ; compare ($A9EA) against the following byte ($A9EB)
        CP (HL)
; ----------------------------------------------------------------------
; EXTENT_INDEX_TEST_TAIL -- mismatch test tail: bump A on a match, else return unchanged.
;   In:        Z/NZ from EXTENT_INDEX_TEST's CP; A holds the value to bump. Also a direct JP target
;              from $98C5 / $98EB.
;   Out:       NZ (mismatch) -> RET A unchanged; Z (match) -> A := A+1 then RET.
;   Clobbers:  A, flags.
;   Algorithm: RET NZ on mismatch; otherwise INC A; RET. [RE] returns A+1 to signal 'indices equal'.
; ----------------------------------------------------------------------
EXTENT_INDEX_TEST_TAIL:
        ; indices differ -> return immediately with A unchanged
        RET NZ
        ; indices equal -> return A+1 as the match signal
        INC A
        RET
; ----------------------------------------------------------------------
; RPC_TAIL_ORPHAN -- UNREFERENCED 3-byte fragment 'LD HL,RPC6502_END'.
;   In:        none. $99FE has ZERO references (EXTENT_INDEX_TEST_TAIL RETs at $99FD; no
;              JP/CALL/table word
;              targets $99FE).
;   Out:       n/a -- its 'LD HL,$94FF' has NO observable effect: it falls into CCP_RPC_THEN_LOOP
;              whose
;              first act (CALL RPC_ENTER_6502 -> LD HL,RPC6502_BLOCK $9400; JP (HL)) IMMEDIATELY
;              overwrites HL. The peer's 'point at the 6502 entry' narrative is FUNCTIONALLY WRONG.
;   Clobbers:  HL.
;   Algorithm: UNKNOWN/orphan. Decodes as clean code (21 FF 94); the $94FF is an in-image pointer
;              into the 6502 RPC block so the operand is relocated to RPC6502_END (byte-identical),
;              but the fragment is dead. Possibly a vestigial alternate entry.
; ----------------------------------------------------------------------
RPC_TAIL_ORPHAN:
        ; orphan: HL := end of the 6502 RPC block ($94FF), but it has no effect -- RPC_ENTER_6502
        ;         below reloads HL with $9400 (UNKNOWN why this fragment exists)
        LD HL,RPC6502_END
; ----------------------------------------------------------------------
; CCP_RPC_THEN_LOOP -- invoke the 6502-side RPC, then resume the CCP command loop.
;   In:        none required (RPC_ENTER_6502 itself loads HL := RPC6502_BLOCK $9400 and JP (HL)).
;              Reached by JP NZ from $98F8 and via the CCP dispatch table.
;   Out:       after the RPC returns, JP CMD_EXEC_63+1 -- back into the CCP command/prompt loop.
;   Clobbers:  whatever RPC_ENTER_6502 clobbers (incl. HL).
;   Algorithm: CALL RPC_ENTER_6502 (switch to the 6502, run the RPC-block payload at $9400, switch
;              back); then JP into the CCP loop. [RE] CMD_EXEC_63+1 ($9B86) is a cross-cluster CCP
;              shared-tail (kept +offset). NOTE: this is the REAL entry; the preceding
;              RPC_TAIL_ORPHAN at $99FE is dead.
; ----------------------------------------------------------------------
CCP_RPC_THEN_LOOP:
        ; switch to the 6502 and run the RPC-block payload ($9400), then return to the Z-80 (this
        ; sets HL := $9400 itself)
        CALL RPC_ENTER_6502
        ; resume the CCP command loop
        JP CMD_EXEC_63+1
MSG_NO_SPACE:
        DEFB    "NO SPACE"               ; CP/M error text
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CMD_EXEC_42 -- the CCP "REN" built-in: rename a disk file (REN newname=oldname).
;   In:        reached via the DEFW entry at CMD_DISPATCH_TBL_2 ($95C9); PARSE_PTR -> the rest of
;              the command line after "REN"; the parsed command FCB (CCP_FCB1, $9BCD) about to be
;              filled.
;   Out:       on success the file is renamed and control returns to the prompt via JP
;              CMD_EXEC_63+1;
;              FILE EXISTS / NO FILE / syntax errors divert to CMD_EXEC_47 / CMD_EXEC_46 /
;              RST_TABLE_9609.
;   Clobbers:  A,BC,DE,HL,flags; writes CCP_FCB1, the rename-target FCB (CCP_FCB1+16), the
;              command-drive
;              cell ($9BF0); pushes/pops the parsed drive.
;   Algorithm: [RE] parse the NEW name into CCP_FCB1, then search the directory for it via the 6502
;              RPC
;              (RPC6502_E0E9) -- if it already exists go to the FILE EXISTS path. Otherwise copy the
;              16-byte name+type into the rename-target FCB at CCP_FCB1+16 (the CP/M TFCB2
;              convention),
;              then scan forward for the '=' (or '_') separator that introduces the OLD name;
;              missing
;              separator -> CMD_EXEC_46. The exact function behind RPC6502_E0E9 is the file's
;              documented
;              OPEN item, not asserted here.
; ----------------------------------------------------------------------
CMD_EXEC_42:
        ; parse the next command-line token into the command FCB (CCP_FCB1)
        CALL RPC_DISPATCH
        ; malformed/empty name -> the CCP error/redo path
        JP NZ,RST_TABLE_9609
        LD A,($9BF0)
        ; save the parsed drive prefix across the directory search
        PUSH AF
        ; [FLAG] documented computed/position-form entry overlapping the MSG_ALL_YN string interior
        ; ($9854); assigned to cluster-8, left a literal CALL here
        CALL $9854
        ; [RE] 6502-RPC directory search for the NEW name; NZ => already present (per CALL context;
        ; exact RPC function UNKNOWN)
        CALL RPC6502_E0E9
        ; new name already on disk -> FILE EXISTS error
        JP NZ,CMD_EXEC_47
        LD HL,$9BCD
        LD DE,CMD_EXEC_68+2
        LD B,$10
        ; copy the 16-byte name+type into the rename-target FCB (CCP_FCB1+16, the TFCB2 slot)
        CALL CCP_NEWLINE_AND_FILEOP
        LD HL,(PARSE_PTR)
        EX DE,HL
        ; advance past blanks and fetch the next non-blank separator character
        CALL RST_TABLE_964F
        CP '='
        JP Z,CMD_EXEC_43
        CP '_'
        ; no '=' / '_' separator -> not a valid REN line
        JP NZ,CMD_EXEC_46
; ----------------------------------------------------------------------
; CMD_EXEC_43 -- REN, parse the OLD name after the '=' separator.
;   In:        DE/HL straddle the separator; B receives the parsed new-name drive (CMD_EXEC_42's
;              PUSH).
;   Out:       OLD name parsed into CCP_FCB1; command-drive cell ($9BF0) reconciled with the new
;              name's
;              drive; falls into CMD_EXEC_44 on success, else CMD_EXEC_46 on error.
;   Clobbers:  A,B,DE,HL,flags; updates PARSE_PTR and the command-drive cell.
;   Algorithm: [RE] step over the separator (INC HL, store PARSE_PTR), parse the OLD filename via
;              the
;              RPC parser, then check that the two filenames' drive prefixes agree (a cross-drive
;              rename
;              is rejected): if the command-drive cell is 0 take the new-name drive, else it must
;              equal B.
; ----------------------------------------------------------------------
CMD_EXEC_43:
        EX DE,HL
        ; consume the '=' / '_' separator
        INC HL
        ; advance the command-line parse cursor past the separator
        LD (PARSE_PTR),HL
        ; parse the OLD filename into the command FCB
        CALL RPC_DISPATCH
        JP NZ,CMD_EXEC_46
        ; recover the new name's drive prefix into B
        POP AF
        LD B,A
        LD HL,$9BF0
        ; command-drive cell ($9BF0): 0 = take the new name's drive
        LD A,(HL)
        OR A
        JP Z,CMD_EXEC_44
        ; both names must name the same drive; mismatch -> error
        CP B
        LD (HL),B
        JP NZ,CMD_EXEC_46
; ----------------------------------------------------------------------
; CMD_EXEC_44 -- REN, locate the OLD file and perform the rename.
;   In:        command FCB (CCP_FCB1) holds the OLD name; rename-target FCB (CCP_FCB1+16) holds NEW.
;   Out:       on a found OLD file the rename runs and control returns to the prompt (JP
;              CMD_EXEC_63+1);
;              if the OLD file is absent -> CMD_EXEC_45 (NO FILE).
;   Clobbers:  A,B,DE,HL,flags; zeroes CCP_FCB1's drive byte; commits B to the drive cell.
;   Algorithm: [RE] commit the agreed drive, zero CCP_FCB1.DR so the search uses the default drive,
;              then
;              search the directory for the OLD name via the RPC (RPC6502_E0E9). Not found ->
;              CMD_EXEC_45.
;              Found -> issue the rename with DE -> CCP_FCB1 (the combined old+new FCB) and return.
;              The
;              exact RPC rename path is UNKNOWN.
; ----------------------------------------------------------------------
CMD_EXEC_44:
        ; store the resolved drive into the command-drive cell ($9BF0)
        LD (HL),B
        XOR A
        ; clear CCP_FCB1.DR so the search runs on the default drive
        LD ($9BCD),A
        ; [RE] 6502-RPC directory search for the OLD name; Z => not present (per CALL context)
        CALL RPC6502_E0E9
        ; OLD file missing -> NO FILE
        JP Z,CMD_EXEC_45
        LD DE,$9BCD
        ; [RE] perform/confirm the rename with DE -> CCP_FCB1 (old+new FCB); exact RPC path UNKNOWN
        CALL TEST_B_NZ
        JP CMD_EXEC_63+1
; ----------------------------------------------------------------------
; CMD_EXEC_45 -- REN, the "old file not found" report.
;   In:        reached when the OLD-name directory search failed.
;   Out:       prints the NO FILE message (via DIR_EMIT_NAME_CHAR_1+2) and returns to the prompt.
;   Clobbers:  per the message-print helper.
;   Algorithm: emit the standard CP/M "NO FILE" diagnostic, then JP CMD_EXEC_63+1 (back to the
;              command loop).
; ----------------------------------------------------------------------
CMD_EXEC_45:
        ; print the NO FILE diagnostic for the missing rename source
        CALL DIR_EMIT_NAME_CHAR_1+2
        JP CMD_EXEC_63+1
; ----------------------------------------------------------------------
; CMD_EXEC_46 -- REN syntax-error fallthrough: treat the line as a (failed) command.
;   In:        reached on a malformed REN line (bad separator / drive mismatch).
;   Out:       runs the generic command executor (CMD_EXEC) then diverts to the error/redo path.
;   Clobbers:  per CMD_EXEC.
;   Algorithm: [RE] hand the line to the generic CMD_EXEC dispatcher and then jump to the CCP error
;              path
;              (RST_TABLE_9609) -- effectively rejecting the malformed REN.
; ----------------------------------------------------------------------
CMD_EXEC_46:
        ; fall back to the generic command executor for the malformed line
        CALL CMD_EXEC
        JP RST_TABLE_9609
; ----------------------------------------------------------------------
; CMD_EXEC_47 -- REN, the "target name already exists" report (FILE EXISTS).
;   In:        reached when the NEW name was found in the directory.
;   Out:       prints MSG_FILE_EXISTS via the 6502-RPC string printer, then returns to the prompt.
;   Clobbers:  BC and per the RPC printer.
;   Algorithm: load BC -> MSG_FILE_EXISTS and call the pointer-form string printer (RPC6502_E0A7),
;              then JP CMD_EXEC_63+1.
; ----------------------------------------------------------------------
CMD_EXEC_47:
        ; point BC at the FILE EXISTS message (pointer-form print)
        LD BC,MSG_FILE_EXISTS
        ; [RE] 6502-RPC print of the NUL-terminated string at BC
        CALL RPC6502_E0A7
        JP CMD_EXEC_63+1
; ----------------------------------------------------------------------
; MSG_FILE_EXISTS -- CP/M error string printed when REN's target name already exists on disk.
;   Reached: pointer-form, via LD BC,MSG_FILE_EXISTS then CALL RPC6502_E0A7 in CMD_EXEC_47.
;   Layout:  NUL-terminated ASCII; "FILE EXISTS" then DEFB $00.
; ----------------------------------------------------------------------
MSG_FILE_EXISTS:
        ; string literal; printed by CMD_EXEC_47 when the rename target already exists
        DEFB    "FILE EXISTS"            ; CP/M error text
        DEFB    $00                      ; terminator
; ----------------------------------------------------------------------
; CMD_EXEC_48 -- directory-list field continuation: print/measure one FCB name field.
;   In:        reached via the DEFW entry at CMD_DISPATCH_TBL_2 ($95CB); CCP_FCB1 holds the current
;              entry;
;              the field-print helper returns a field index/length in A.
;   Out:       A = field length/index; advances to CMD_EXEC_64; out-of-range (>=16) or an empty
;              leading
;              name char (' ') -> RST_TABLE_9609.
;   Clobbers:  A,E,flags.
;   Algorithm: [RE] call the per-field print/measure helper (DIR_EMIT_NAME_CHAR_2+1), reject index
;              >= 16 and
;              the empty-name case (first name char is a blank), then continue the listing at
;              CMD_EXEC_64.
;              NOTE: the CALL $9515 below enters the CCP_CMD_NAMES string interior (file's
;                    computed/position
;              form) -- left a flagged literal.
; ----------------------------------------------------------------------
CMD_EXEC_48:
        ; print/measure one directory field; A = field length/index
        CALL DIR_EMIT_NAME_CHAR_2+1
        CP $10
        ; index past the 16-byte name+type span -> done/abort
        JP NC,RST_TABLE_9609
        LD E,A
        ; fetch the entry's first filename character
        LD A,($9BCE)
        CP ' '
        ; blank leading char => empty entry, skip the listing
        JP Z,RST_TABLE_9609
        ; [FLAG] enters the CCP_CMD_NAMES string interior ($9515) -- file's documented
        ; computed/position form; needs a coordinated cover-split to mint a clean entry label, left
        ; a flagged literal (UNKNOWN, not invented)
        CALL $9515
        JP CMD_EXEC_64
; ----------------------------------------------------------------------
; CMD_EXEC_49 -- the explicit drive-change / USER-number path of the command loop.
;   In:        reached via the DEFW entry at CMD_DISPATCH_TBL_2 ($95CD) and from CCP_MAIN_LOOP_1;
;              CCP_FCB1 =
;              the parsed command FCB; the command-drive cell ($9BF0) = drive prefix.
;   Out:       if a bare drive ("B:") was typed, selects it (current drive := drive-1) and reselects
;              via
;              the RPC; otherwise hands off to CMD_EXEC_50 (transient loader).
;   Clobbers:  A,flags; writes the current-drive cell (CMD_EXEC_69 / $9BEF).
;   Algorithm: [RE] if the command FCB has no filename (first char blank) it is a pure drive change:
;              when
;              a command drive prefix is present, convert 1-based -> 0-based (DEC A), store it as
;              the
;              current drive, and re-select the disk via the 6502 RPC. NOTE: the leading CALL $95F5
;              enters
;              the MSG_NO_FILE string tail (computed/position form) -- the 3 bytes there decode as
;              LD C,H/LD B,L/NOP falling into CHECK_DRIVE_ERR_1; left a flagged literal.
; ----------------------------------------------------------------------
CMD_EXEC_49:
        ; [FLAG] enters the MSG_NO_FILE string tail ($95F5 = NO FILE+5); file's documented
        ; computed/position-form entry -- the bytes there decode as LD C,H/LD B,L/NOP then fall into
        ; CHECK_DRIVE_ERR_1 ($95F8). Left a flagged literal pending a coordinated MSG_NO_FILE
        ; cover-split
        CALL $95F5
        ; is the parsed FCB filename empty? (a bare "X:" drive change)
        LD A,($9BCE)
        CP $20
        ; a real filename was typed -> the transient .COM loader
        JP NZ,CMD_EXEC_50
        ; command-line drive prefix ($9BF0): 0 = no drive given, nothing to change
        LD A,($9BF0)
        OR A
        JP Z,CMD_EXEC_64
        ; convert the 1-based command drive to a 0-based drive number
        DEC A
        ; set the current default drive ($9BEF)
        LD (CMD_EXEC_69),A
        CALL SEARCH_BUILTIN
        ; [RE] 6502-RPC: re-select the now-current disk drive
        CALL RPC6502_E0BD
        JP CMD_EXEC_64
; ----------------------------------------------------------------------
; CMD_EXEC_50 -- transient command: verify the name carries no explicit type, then prepare to load.
;   In:        CCP_FCB1 holds the parsed command name; CCP_FCB1+FCB_T ($9BD6) = its type field.
;   Out:       if a type was already given (non-blank) -> error (RST_TABLE_9609); otherwise falls
;              into
;              CMD_EXEC_51 to open and load.
;   Clobbers:  A,DE,flags; preserves DE (the type-field pointer) across the helper call.
;   Algorithm: [RE] read the FCB type field; a CP/M command name must carry no explicit type so the
;              implied ".COM" can be applied -- a non-blank type is rejected. Then call the setup
;              helper at
;              $9854 (computed/position-form entry, flagged) before loading.
; ----------------------------------------------------------------------
CMD_EXEC_50:
        ; DE -> CCP_FCB1's type field ($9BD6 = CCP_FCB1+FCB_T); kept as the pre-existing
        ; CMD_EXEC_67+2 form (FLAG: cluster-12 to re-split the $9BCD-$9C00 FCB workspace and mint a
        ; clean type-field label)
        LD DE,CMD_EXEC_67+2
        ; read the first file-type character
        LD A,(DE)
        CP ' '
        ; an explicit extension was typed -> reject (only the implied .COM is loadable)
        JP NZ,RST_TABLE_9609
        PUSH DE
        ; [FLAG] documented computed/position-form entry overlapping the MSG_ALL_YN string interior
        ; ($9854); assigned to cluster-8, left a literal CALL here
        CALL $9854
        POP DE
; ----------------------------------------------------------------------
; CMD_EXEC_51 -- open the .COM file and load it into the TPA, with an overflow guard.
;   In:        CCP_FCB1 = the (typeless) command FCB; CCP_LOAD_FCB_SRC ($9B83) seeds the load setup.
;   Out:       on a successful in-range load the result is captured by CMD_EXEC_52; a missing file
;              ->
;              CMD_EXEC_61; an image judged too large -> JP $FFE1 (off-image error vector).
;   Clobbers:  A,DE,HL,flags; pushes the TPA base.
;   Algorithm: [RE/OBSERVED] build/open the load setup (DIR_EMIT_NAME_CHAR_8+1 entry at $9840 via
;              the $9B83
;              pointer), probe for the file (RPC6502_E0D0); Z -> not found -> CMD_EXEC_61. Else set
;              the
;              load/exec address to TPA ($0100) and call the 6502-RPC load path (RPC_CALL_HL then
;              RPC6502_E0F9). On the NZ result it stores the captured address (CMD_EXEC_52) and
;              returns. On
;              the Z path it runs a size check against the $9400 (RPC6502_BLOCK) ceiling; no-borrow
;              ->
;              proceed (CMD_EXEC_62), borrow -> JP $FFE1 (too big / BAD LOAD). UNKNOWN: the real
;              load-end
;              arrives through the 6502 RPC -- statically the visible HL=$0100+$0080=$0180 is a
;              constant,
;              so the branch outcome is RPC-side and not determinable from the Z-80 bytes; do NOT
;              read this
;              as a Z-80 record-streaming loop.
;   Re-entry:  CMD_EXEC_69 ($9BFE) JPs back here to load the next $$$.SUB-chained command.
; ----------------------------------------------------------------------
CMD_EXEC_51:
        LD HL,$9B83
        ; build/open the load setup from CCP_LOAD_FCB_SRC (enters the CCP_NEWLINE_AND_FILEOP path
        ; via the +1 cover at $9840)
        CALL DIR_EMIT_NAME_CHAR_8+1
        ; [RE] 6502-RPC: probe the directory for the .COM file; Z => not found (per CALL context)
        CALL RPC6502_E0D0
        ; file not found -> the not-found / chaining path
        JP Z,CMD_EXEC_61
        ; set the load/execute address to the TPA base
        LD HL,TPA                        ; TPA base = TBASE 0100H, the .COM transient load/exec address [DOC CPMREF 3-45 ; facts sec.7.4/7.7]
        PUSH HL
        EX DE,HL
        ; [RE] hand off to the 6502 side (set DMA / drive the load); side effects UNKNOWN from Z-80
        CALL RPC_CALL_HL
        LD DE,$9BCD
        ; [RE] 6502-RPC load/read step; on NZ the load completed -> store the result
        CALL RPC6502_E0F9
        ; load done (NZ) -> CMD_EXEC_52 stores the captured address and returns
        JP NZ,CMD_EXEC_52
        POP HL
        LD DE,TBUFF
        ADD HL,DE
        ; the ceiling: the loaded image must stay below the 6502 RPC block at $9400
        LD DE,RPC6502_BLOCK
        LD A,L
        SUB E
        LD A,H
        SBC A,D
        ; size check passed (no borrow) -> proceed
        JP NC,CMD_EXEC_62
        ; [FLAG] program too big (BAD LOAD): JP to the off-image $FFE1 vector. Kept literal
        ; (off-image; not the $0000 warm-boot, not in the BIOS table) -- target UNKNOWN
        JP $FFE1
; ----------------------------------------------------------------------
; CMD_EXEC_52 -- record the address captured after a .COM load, then return.
;   In:        HL = the address produced by the load path.
;   Out:       stores HL into the BDOS workspace cell ($A9EA = BDOS_VAR_PAGE_9_p6_STG) and RETs.
;   Clobbers:  none beyond the store.
;   Algorithm: write HL to the BDOS variable at $A9EA, then RET to CMD_EXEC_51's caller.
; ----------------------------------------------------------------------
CMD_EXEC_52:
        ; save the captured load address into the BDOS workspace cell ($A9EA)
        LD (BDOS_VAR_PAGE_9_p6_STG),HL
        RET
; ----------------------------------------------------------------------
; CMD_EXEC_53 -- SUBMIT ($$$.SUB) record-write step (BDOS page): advance and dispatch a record
; write.
;   In:        BDOS workspace ($A9C8 = DMA/buffer pointer, $A9EA = running record number) set up by
;              the
;              $$$.SUB writer.
;   Out:       advances the record number and dispatches into the BDOS write path (at $A1FE /
;              $A219).
;   Clobbers:  DE,HL,flags.
;   Algorithm: [RE] fetch the DMA/buffer source ($A9C8) into DE, bump the running record number
;              ($A9EA),
;              set the record position (CALL $A195), then dispatch to the BDOS write. UNKNOWN:
;              precise
;              BDOS-side semantics; this block ($9B05+) is reached only via fall-through (it lives
;              in the
;              BDOS-owned page).
; ----------------------------------------------------------------------
CMD_EXEC_53:
        ; load the current DMA/buffer source pointer ($A9C8)
        LD HL,(BDOS_VAR_PAGE_7_p35_STG)
        EX DE,HL
        LD HL,(BDOS_VAR_PAGE_9_p6_STG)
        ; advance to the next $$$.SUB record number
        INC HL
        LD (BDOS_VAR_PAGE_9_p6_STG),HL
        ; set the BDOS record position for the write
        CALL FCB_SET_REC_FLAG_5_STG+2
        JP NC,READ_CON_BUF_EDIT_2_p2_STG+1
        JP READ_CON_BUF_EDIT_STG
; ----------------------------------------------------------------------
; CMD_EXEC_54 -- SUBMIT record-write: position within a 4-record group.
;   In:        the running record number ($A9EA).
;   Out:       on a group boundary stores the masked position ($A9E9) and RETs (Z); else diverts
;              into the
;              BDOS path ($A220).
;   Clobbers:  A,B,flags.
;   Algorithm: [RE] compute record_number & 3 (position within a 4-record group) and double it; a
;              non-zero
;              result jumps into the BDOS engine ($A220), otherwise the masked value is stored and
;              the
;              routine returns. UNKNOWN: precise BDOS-side semantics.
; ----------------------------------------------------------------------
CMD_EXEC_54:
        ; current $$$.SUB record number ($A9EA)
        LD A,(BDOS_VAR_PAGE_9_p6_STG)
        ; position within a 4-record group
        AND $03
        LD B,$05
        ADD A,A
        DEC B
        JP NZ,READ_CON_BUF_EDIT_2_p10_STG
        LD (BDOS_VAR_PAGE_9_p5_STG),A
        OR A
        RET NZ
        PUSH BC
        CALL BDOS_CON_8_p10_STG+1
; ----------------------------------------------------------------------
; CMD_EXEC_55 -- SUBMIT record-write tail (BDOS page): flush one record then chain to the BDOS
; engine.
;   In:        BC saved by the caller; BDOS console/record state set up.
;   Out:       flushes/reads one record via the BDOS, restores BC, JPs into the BDOS record routine
;              ($A19E).
;   Clobbers:  per the BDOS calls; restores BC.
;   Algorithm: [RE] on the fall-through path: CALL BDOS_CON_8_p10_STG+1, then CALL $A1D4 (flush/read
;              one
;              record), POP BC, JP $A19E.
;   Note:      the address $9B30 (the $A1 operand byte of the CALL at $9B2E) is a genuine OVERLAP
;              ENTRY
;              reached by a JP from the CCP command scan. Per the BDOS owner's note (CPM_BDOS.asm
;              CCP_TAIL_2, lines 283-296): a clean cover-split needs blob3 ($9B00) decoded to code
;              FIRST
;              and is FLAGGED, NOT split here. No split is emitted (verified: NO referrer to $9B30
;              exists
;              in CPM_CCP.asm or CPM_BDOS.asm).
; ----------------------------------------------------------------------
CMD_EXEC_55:
        CALL DISK_READ_RECORD_1_p3_STG+1
        POP BC
        JP FCB_SET_REC_FLAG_6_STG+1
; ----------------------------------------------------------------------
; CMD_EXEC_56 -- allocation-vector bit fetch, part 1: split a disk block number into a bitmap byte
; offset + in-byte bit position.
;   In:        BC = a disk allocation block number (B = high byte, C = low byte).
;              BDOS_VAR_PAGE_7_p26_STG ($A9BF) = base pointer of the current drive's
;              allocation/directory bit map (set up from the DPB by the BDOS select-disk path).
;   Out:       D = E = (block & 7) + 1 (the 1-based bit-walk count, used by CMD_EXEC_59/60); C being
;              rebuilt as the low part of the byte offset; falls through into CMD_EXEC_57.
;   Clobbers:  A, C, D, E.
;   Algorithm: OBSERVED A=C; A&=7; A++; D=E=A (bit-in-byte index +1). Then A=C; rotate right twice
;              (continued in CMD_EXEC_57) to begin forming block>>3. [RE] classic CP/M alloc-bitmap
;              address split: byte = block/8, bit = block%8.
; ----------------------------------------------------------------------
CMD_EXEC_56:
        ; ; take the block number's low byte to extract the in-byte bit position
        LD A,C
        ; ; bit-within-byte index = block & 7
        AND $07
        INC A
        ; ; D and E both hold (block&7)+1: E counts the bit-walk in CMD_EXEC_59, D in the bit-set
        ; tail CMD_EXEC_60
        LD E,A
        LD D,A
        ; ; reload the block low byte and begin shifting it right by 3 to form the byte offset
        ; (block/8)
        LD A,C
        RRCA
        RRCA
; ----------------------------------------------------------------------
; CMD_EXEC_57 -- allocation-vector bit fetch, part 2: finish the low 5 bits of the bitmap byte
; offset.
;   In:        A = block low byte already rotated right twice by CMD_EXEC_56; B = block high byte.
;   Out:       C = (block_low >> 3) & $1F; A = B (loaded for the next stage); falls through into
;              CMD_EXEC_58.
;   Clobbers:  A, C.
;   Algorithm: OBSERVED one more RRCA (total >>3), AND $1F, store to C; then A=B to fold the block
;              high byte in. [RE] continues building the 16-bit bitmap byte offset from the block
;              number.
; ----------------------------------------------------------------------
CMD_EXEC_57:
        RRCA
        ; ; keep the low 5 bits of (block_low >> 3): the partial bitmap byte offset
        AND $1F
        LD C,A
        ; ; bring in the block number's high byte to fold into the byte offset (CMD_EXEC_58)
        LD A,B
; ----------------------------------------------------------------------
; CMD_EXEC_58 -- allocation-vector bit fetch, part 3: fold the block high byte into the 16-bit
; bitmap byte offset.
;   In:        A = block high byte; C = partial offset from CMD_EXEC_57.
;   Out:       C = ((block_high << 5) | (block_low>>3)) low byte of the offset; B begins the high
;              byte (block_high>>3) -- completed in CMD_EXEC_59.
;   Clobbers:  A, B, C.
;   Algorithm: OBSERVED A<<=5 (five ADD A,A); OR C; C=A (offset low). Then A=B; RRCA x3
;              (block_high>>3, masked in CMD_EXEC_59) for the offset high byte. [RE] BC becomes the
;              byte index into the allocation bit map.
; ----------------------------------------------------------------------
CMD_EXEC_58:
        ; ; shift the block high byte left 5 (x32) so it lines up above the (block>>3) low bits
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ; ; combine with the low part: C = low byte of the bitmap byte offset
        OR C
        LD C,A
        ; ; recompute from the block high byte: A=(block_high>>3) becomes the offset high byte
        LD A,B
        RRCA
        RRCA
        RRCA
; ----------------------------------------------------------------------
; CMD_EXEC_59 -- allocation-vector bit fetch, part 4: address the bitmap byte and rotate the wanted
; bit into carry.
;   In:        A = block_high>>3 (just computed); C = offset low byte; D=E = (block&7)+1 from
;              CMD_EXEC_56; BDOS_VAR_PAGE_7_p26_STG ($A9BF) = allocation/dir bit-map base pointer.
;   Out:       HL -> the bitmap byte holding the block's bit; the wanted bit rotated into carry/high
;              after E iterations; RET (carry/A reflect the bit). Loops via the BDOS continuation at
;              READ_CON_BUF_EDIT_9_p4_STG+1 ($A256).
;   Clobbers:  A, B, HL, flags.
;   Algorithm: OBSERVED B = (block_high>>3)&$1F (offset high); HL = (*$A9BF) + BC; A=(HL); RLCA; DEC
;              E; loop until E hits 0 (positions the block%8 bit), else RET. [RE] reads/tests one
;              allocation-vector bit for the given block; +1 of the (block&7) count makes the final
;              rotate land the wanted bit in the carry.
; ----------------------------------------------------------------------
CMD_EXEC_59:
        ; ; finish the offset high byte = (block>>3) high 5 bits; BC is now the byte index into the
        ; bit map
        AND $1F
        LD B,A
        ; ; load the current drive's allocation/directory bit-map base pointer ($A9BF, from the DPB)
        LD HL,(BDOS_VAR_PAGE_7_p26_STG)
        ; ; HL -> the bitmap byte that contains this block's allocation bit
        ADD HL,BC
        LD A,(HL)
        ; ; rotate the byte left; repeated DEC E times to walk to the (block & 7) bit position
        RLCA
        DEC E
        ; ; not yet at the target bit: continue the rotate loop in the BDOS bit helper ($A256)
        JP NZ,READ_CON_BUF_EDIT_9_p4_STG+1
        RET
; ----------------------------------------------------------------------
; CMD_EXEC_60 -- allocation-vector bit SET: write the marked bit back into the bitmap byte.
;   In:        DE/HL set up by the fetch path; C = the bit value to OR in; D = the bit-walk count;
;              HL -> bitmap byte.
;   Out:       (HL) updated with the block's allocation bit set; RET. Loops via the BDOS
;              continuation READ_CON_BUF_EDIT_11_p5_STG ($A264).
;   Clobbers:  A, B, C, flags.
;   Algorithm: OBSERVED PUSH DE; CALL the BDOS bit-read worker ($A235); AND $FE (clear bit 0); POP
;              BC; OR C (set the wanted bit); RRCA; DEC D; loop until positioned, then LD (HL),A;
;              RET. [RE] the write-back counterpart of CMD_EXEC_56-59 -- marks a block as allocated
;              in the directory/allocation bit map.
; ----------------------------------------------------------------------
CMD_EXEC_60:
        PUSH DE
        ; ; fetch the current bitmap byte via the BDOS bit-access worker ($A235)
        CALL READ_CON_BUF_EDIT_4_STG+1
        ; ; clear the low bit so the wanted bit can be OR'd in cleanly
        AND $FE
        POP BC
        ; ; set this block's allocation bit
        OR C
        RRCA
        DEC D
        ; ; not yet rotated back to the byte's natural alignment: continue in the BDOS bit helper
        ; ($A264)
        JP NZ,READ_CON_BUF_EDIT_11_p5_STG
        ; ; store the updated allocation-bitmap byte back
        LD (HL),A
        RET
; ----------------------------------------------------------------------
; CMD_EXEC_61 -- directory allocation-map scan: read a directory record, then point at its
; allocation-map field.
;   In:        current FCB / drive context (consumed by the BDOS dir-read helper).
;   Out:       HL advanced to the directory entry's allocation-map (FCB.D0 = entry+$10) via
;              DE=$0010; falls through into CMD_EXEC_62.
;   Clobbers:  A, BC, DE, HL (per the callee).
;   Algorithm: OBSERVED CALL FCB_SET_REC_FLAG_3_p4_STG (BDOS: select drive + read the next directory
;              record, HL -> entry); LD DE,$0010 = the FCB allocation-map offset. [RE] sets up to
;              walk the 16-byte block list of one directory entry while computing file size /
;              building the allocation vector.
; ----------------------------------------------------------------------
CMD_EXEC_61:
        ; ; BDOS: select the drive and read the next directory record; HL -> the directory entry
        CALL FCB_SET_REC_FLAG_3_p4_STG
        ; ; $0010 = offset of the allocation-map field (FCB.D0) within a directory entry
        LD DE,$0010
; ----------------------------------------------------------------------
; CMD_EXEC_62 -- directory allocation-map scan loop body: advance to the map, then read one block
; number (8- or 16-bit).
;   In:        HL -> directory entry; DE = $0010 (map offset); BC scratch; BDOS_VAR_PAGE_8_p11_STG
;              ($A9DD) = block-number width flag (0 = 8-bit blocks, else 16-bit).
;   Out:       HL -> the allocation-map field; for 8-bit blocks, C = (HL) and B = 0; for 16-bit
;              blocks, the value is fetched in CMD_EXEC_64. RET Z early if the per-entry count
;              exhausts.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: OBSERVED HL += DE (-> map); register-shuffle (PUSH BC/LD C,$11/POP DE) parks the old
;              BC in DE and sets C=$11; DEC C / RET Z (slot-count guard); save DE; A=($A9DD) OR A ->
;              if zero (8-bit blocks) JP into the BDOS dir helper ($A288); else (16-bit) save BC/HL,
;              C=(HL), B=0 and fall through into the split cover. [RE] the block-list walk,
;              parameterised on 8- vs 16-bit allocation block numbers.
; ----------------------------------------------------------------------
CMD_EXEC_62:
        ; ; advance HL to the directory entry's allocation-map field
        ADD HL,DE
        PUSH BC
        LD C,$11
        POP DE
        ; ; per-entry block-slot guard (C was set to $11); exhausted -> return
        DEC C
        RET Z
        PUSH DE
        ; ; read the block-number-width flag ($A9DD): 0 = 8-bit block numbers, nonzero = 16-bit
        LD A,(BDOS_VAR_PAGE_8_p11_STG)
        OR A
        ; ; 8-bit block numbers: hand the single-byte block to the BDOS dir helper ($A288)
        JP Z,FCB_NAME_MATCH_REC_1_p5_STG+1
        PUSH BC
        PUSH HL
        ; ; 16-bit blocks: read the low byte of the next allocation block number
        LD C,(HL)
        ; ; B := 0 to clear the block-number high byte before the split cover at $9B85. NOTE: this
        ; byte ($9B83) is ALSO the in-image pointer target CMD_EXEC_62_RECLEN of the foreign LD
        ; HL,$9B83 at $9AD2 (dual code/data; a scratch buffer).
        LD B,$00
; ----------------------------------------------------------------------
; CMD_EXEC_63 -- shared dir-helper re-entry (cover-split): the real entry reached by 9 `JP
; CMD_EXEC_63` sites (post-split; foreign clusters).
;   In:        BC = block number (B=0 for 8-bit), HL/BC saved on stack by CMD_EXEC_62; or
;              caller-supplied state at the +1 entry.
;   Out:       continues into the block-number test at CMD_EXEC_64 (DEC C then PUSH BC...).
;   Clobbers:  A (ADC A,(HL)), flags.
;   Algorithm: OBSERVED the byte at $9B85 is a cover ($C3): on FALL-THROUGH from CMD_EXEC_62's `LD
;              B,$00` it is JP DIR_NEXT_ENTRY_p4_STG ($A28E, the BDOS directory-next worker). When
;              ENTERED at +1 ($9B86, this label after the split) the operand bytes run as `ADC
;              A,(HL); AND D` then DEC C ($9B88) and fall into the block-number test CMD_EXEC_64.
;              [RE] a dual-use cover that both tail-jumps to the BDOS dir-next routine and serves as
;              the 9-caller re-entry into the block-number reconcile; the +1 entry's leading ADC/AND
;              are the disassembler-merged operand tail (effect on A is consumed/overwritten before
;              it matters), the meaningful work resumes at CMD_EXEC_64. CAUTION (applier): minting
;              this label at $9B86 REQUIRES rewriting the 9 foreign `JP CMD_EXEC_63+1` sites to `JP
;              CMD_EXEC_63` in the SAME byte-identical pass.
; ----------------------------------------------------------------------
CMD_EXEC_63:
        JP DIR_NEXT_ENTRY_p4_STG
        DEC C
; ----------------------------------------------------------------------
; CMD_EXEC_64 -- per-block reconcile: read one 16-bit allocation block number and range-check it
; against the drive ceiling.
;   In:        HL -> allocation-map slot; BDOS_VAR_PAGE_7_p33_STG ($A9C6) = the drive's maximum
;              block number (allocation ceiling).
;   Out:       BC = the block number; if zero (unused slot) skip via the BDOS dir helper ($A29D); if
;              in range, mark it (CALL NC into $A25C). Advances HL; continues via
;              READ_CON_BUF_EDIT_13_p4_STG ($A275).
;   Clobbers:  A, BC, HL, flags.
;   Algorithm: OBSERVED PUSH BC; C=(HL); INC HL; B=(HL) (16-bit block number); PUSH HL; A=C OR B ->
;              JP Z dir-helper (slot empty); HL=($A9C6) (max block); compute (max - block) via SUB C
;              / SBC A,B; CALL NC the BDOS bit-mark helper when block <= max; restore HL, INC HL,
;              restore BC; JP the BDOS continuation. [RE] for each non-empty block in the directory
;              entry, if the block number is within the drive's allocation ceiling, mark it
;              allocated.
; ----------------------------------------------------------------------
CMD_EXEC_64:
        PUSH BC
        ; ; read the low byte of a 16-bit allocation block number
        LD C,(HL)
        INC HL
        ; ; read its high byte -> BC = the block number
        LD B,(HL)
        PUSH HL
        LD A,C
        OR B
        ; ; block number 0 = unused map slot: skip it (BDOS dir helper $A29D)
        JP Z,DIR_NEXT_ENTRY_1_p13_STG+1
        ; ; load the drive's maximum block number ($A9C6, the allocation ceiling)
        LD HL,(BDOS_VAR_PAGE_7_p33_STG)
        LD A,L
        ; ; compute (max_block - block) across SUB C / SBC A,B to range-check the block number
        SUB C
        LD A,H
        SBC A,B
        ; ; block <= ceiling (no borrow): mark it allocated via the BDOS bit-mark helper ($A25C)
        CALL NC,READ_CON_BUF_EDIT_10_STG
        POP HL
        INC HL
        POP BC
        JP READ_CON_BUF_EDIT_13_p4_STG
; ----------------------------------------------------------------------
; CMD_EXEC_65 -- post-scan: scale the high block count and zero-fill the allocation/working buffer.
;   In:        BDOS_VAR_PAGE_7_p33_STG ($A9C6) = max block number / working count;
;              BDOS_VAR_PAGE_7_p26_STG ($A9BF) = allocation/dir buffer base pointer.
;   Out:       BC = a derived length; the buffer at (*$A9BF) zero-filled (loop continues in
;              CMD_EXEC_66).
;   Clobbers:  A, BC, HL.
;   Algorithm: OBSERVED HL=($A9C6); C=$03; CALL BDOS_CON_41_p12_STG ($A0EA: shift/scale by 3); INC
;              HL; BC=HL (length+1); HL=(*$A9BF); (HL)=0; fall through to the zero-fill loop. [RE]
;              computes how many allocation-vector bytes to clear and begins clearing them; reached
;              as a CCP-resident continuation of the BDOS select/compute path (no direct CCP caller
;              -- entered via the BDOS return path).
; ----------------------------------------------------------------------
CMD_EXEC_65:
        ; ; load the max block number / working count ($A9C6)
        LD HL,(BDOS_VAR_PAGE_7_p33_STG)
        LD C,$03
        ; ; scale by 3 (C=$03) via the BDOS shift helper ($A0EA) to size the allocation-vector
        ; buffer
        CALL BDOS_CON_41_p12_STG
        INC HL
        LD B,H
        LD C,L
        ; ; point at the allocation/directory buffer base ($A9BF)
        LD HL,(BDOS_VAR_PAGE_7_p26_STG)
        ; ; begin zero-filling the allocation-vector buffer
        LD (HL),$00
; ----------------------------------------------------------------------
; CMD_EXEC_66 -- finish zero-filling the buffer, store the end pointer, and seed a 3-byte record
; header.
;   In:        BC = remaining byte count; HL = buffer write pointer; BDOS_VAR_PAGE_7_p37_STG ($A9CA)
;              = an end/limit pointer; BDOS_VAR_PAGE_7_p26_STG ($A9BF) / BDOS_VAR_PAGE_7_p14_STG
;              ($A9B3) = working pointers.
;   Out:       buffer cleared; (*$A9BF) word := ($A9CA); a 2-byte field at (*$A9B3) seeded $03,$00;
;              then CALL READ_CON_BUF_EDIT_STG and C=$FF before falling into the $$$.SUB detect
;              (CMD_EXEC_67).
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: OBSERVED zero-fill loop INC HL/DEC BC/until BC==0 (JP NZ $A2B1); store the saved end
;              pointer ($A9CA) into the cell at (*$A9BF); write $03,$00 through (*$A9B3); CALL the
;              BDOS record-read entry ($A1FE); LD C,$FF. [RE] finalizes the cleared
;              allocation/working buffer and primes the directory scan that detects the SUBMIT chain
;              file. NOTE: the LD (HL),$03 / LD (HL),$00 write THROUGH HL pointers; they do not
;              define the bytes at $9BCD as data -- but the instruction `LD (HL),$00` physically
;              sits AT $9BCD, which is ALSO the command-FCB base (FCB.DR) read/written as DATA by
;              ~20 foreign CCP sites (dual code/data; see summary).
; ----------------------------------------------------------------------
CMD_EXEC_66:
        INC HL
        DEC BC
        LD A,B
        OR C
        ; ; loop until the whole allocation/working buffer is cleared (BDOS dir helper $A2B1)
        JP NZ,FCB_CMP_DIR_ENTRY_1_p5_STG
        ; ; fetch the saved end/limit pointer ($A9CA)
        LD HL,(BDOS_VAR_PAGE_7_p37_STG)
        EX DE,HL
        LD HL,(BDOS_VAR_PAGE_7_p26_STG)
        ; ; store the end pointer (E,D) into the word at (*$A9BF)
        LD (HL),E
        INC HL
        LD (HL),D
        CALL BDOS_CON_3_p11_STG
        LD HL,(BDOS_VAR_PAGE_7_p14_STG)
        ; ; seed a 3-byte record header (write $03 then $00 through the (*$A9B3) pointer)
        LD (HL),$03
        INC HL
        LD (HL),$00
        ; ; BDOS: read the directory record that begins the SUBMIT-chain scan ($A1FE)
        CALL READ_CON_BUF_EDIT_STG
        ; ; C := $FF, the scan/record sentinel for the $$$.SUB detect that follows
        LD C,$FF
; ----------------------------------------------------------------------
; CMD_EXEC_67 -- $$$.SUB scan step: read one directory record and re-enter the entry test.
;   In:        C = scan sentinel; current FCB/drive context.
;   Out:       on read success continues into CMD_EXEC_68; RET Z when the directory is exhausted.
;   Clobbers:  per the BDOS callees.
;   Algorithm: OBSERVED CALL READ_CON_BUF_EDIT_p6_STG+1 ($A205) then CALL DISK_READ_RECORD_2_p18_STG
;              ($A1F5); RET Z (no more records). [RE] the loop step of the SUBMIT-chain directory
;              scan. NOTE: the +2 address ($9BD6) is NOT a code entry -- it is read as DATA (the
;              command FCB name byte, the foreign LD DE,CMD_EXEC_67+2 at $9AC4 is a data-pointer
;              load, verified); see the summary's dual code/data note.
; ----------------------------------------------------------------------
CMD_EXEC_67:
        ; ; BDOS step into the directory record scan ($A205)
        CALL READ_CON_BUF_EDIT_p6_STG+1
        ; ; read the next directory record ($A1F5); RET Z when the directory is exhausted
        CALL DISK_READ_RECORD_2_p18_STG
        RET Z
; ----------------------------------------------------------------------
; CMD_EXEC_68 -- $$$.SUB entry test: skip deleted entries, match the wanted user/drive byte, and
; check for a '$' first char.
;   In:        HL -> a directory entry's status byte; BDOS_DEFAULT_FCB+2 ($9F41) = the current
;              user/drive byte (OBSERVED in the BDOS as the user-number/select cell and
;              private-stack base; the 2.23 twin labels the same physical $9F41 as
;              CCP_DELIM_BYTE+2).
;   Out:       on a deleted entry ($E5) re-scan via FCB_CMP_DIR_ENTRY_5_STG+1 ($A2D2); on a user
;              mismatch exit via BDOS_DCIO_SETIOBYTE_p3_STG ($A2F6); else A = (firstchar - '$') for
;              CMD_EXEC_69.
;   Clobbers:  A, HL, flags.
;   Algorithm: OBSERVED CALL FCB_SET_REC_FLAG_3_p4_STG (read the directory entry); A=$E5; CP (HL) ->
;              JP Z (deleted entry, keep scanning); A=(BDOS_DEFAULT_FCB+2); CP (HL) -> JP NZ
;              (different user, stop); INC HL; A=(HL); SUB '$'. [RE] standard CP/M directory match:
;              deleted-marker skip + user/drive-code match + filename-first-char test for the
;              conventional '$$$.SUB' temporary file.
; ----------------------------------------------------------------------
CMD_EXEC_68:
        ; ; BDOS: fetch the directory entry; HL -> its first (status/user) byte
        CALL FCB_SET_REC_FLAG_3_p4_STG
        ; ; $E5 = the CP/M deleted-directory-entry marker
        LD A,$E5
        CP (HL)
        ; ; entry is deleted: skip it and continue scanning ($A2D2)
        JP Z,FCB_CMP_DIR_ENTRY_5_STG+1
        ; ; load the current user/drive byte (BDOS_DEFAULT_FCB+2 = $9F41; OBSERVED in the BDOS as
        ; the user-number/select cell)
        LD A,($9F41)
        CP (HL)
        ; ; entry belongs to a different user: stop the scan ($A2F6)
        JP NZ,BDOS_DCIO_SETIOBYTE_p3_STG
        INC HL
        LD A,(HL)
        ; ; test the filename's first char against '$' (the $$$.SUB temp-file marker)
        SUB '$'
; ----------------------------------------------------------------------
; CMD_EXEC_69 -- $$$.SUB confirmed: write $FF to a BDOS workspace cell and chain back to the
; transient loader.
;   In:        A = (firstchar - '$') from CMD_EXEC_68 (0 if the file is a $$$ temp file).
;   Out:       if not a '$' file, exit via BDOS_DCIO_SETIOBYTE_p3_STG ($A2F6); else stores $FF into
;              the BDOS workspace cell BDOS_RETURN_VAL ($9F45), sets record count C=$01, runs the
;              BDOS record step, then JP CMD_EXEC_51 (the transient open/stage path at $9AD2).
;   Clobbers:  A, C, flags; writes the BDOS cell $9F45.
;   Algorithm: OBSERVED JP NZ ($A2F6) when firstchar!='$'; DEC A (A was 0 -> $FF); LD
;              (BDOS_RETURN_VAL),A; LD C,$01; CALL READ_CON_BUF_EDIT_12_STG ($A26B); CALL
;              FCB_SET_REC_FLAG_4_p8_STG+1 ($A18C); JP CMD_EXEC_51. [RE] a SUBMIT/$$$ chain file was
;              found and the CCP re-enters the command-tail loader. The store at $9BF3 writes $FF
;              into the BDOS workspace cell $9F45 (CPM_BDOS.asm: BDOS_RETURN_VAL, the standard CP/M
;              result cell; the 2.23 twin labels the same physical $9F45 CCP_DE_PARAM+2). UNKNOWN:
;              whether the loader consumes this $FF as a 'submit active' flag -- no reader is traced
;              from this cluster; do NOT assert the submit-flag role as fact. DUAL CODE/DATA: this
;              routine's address ($9BEF) is ALSO read/written as the command-FCB cell (FCB.R1) by
;              many foreign CCP sites (e.g. LD A,(CMD_EXEC_69) at $9389); the +2 ($9BF1) is read as
;              a DATA pointer by the foreign LD HL,CMD_EXEC_69+2 at $986F/$9874.
; ----------------------------------------------------------------------
CMD_EXEC_69:
        ; ; first filename char is not '$': not a $$$.SUB file, stop ($A2F6)
        JP NZ,BDOS_DCIO_SETIOBYTE_p3_STG
        ; ; A was 0 ('$' matched) -> $FF
        DEC A
        ; ; store $FF into the BDOS workspace cell BDOS_RETURN_VAL ($9F45). [RE] flags the found
        ; $$$.SUB record; UNKNOWN whether the loader reads it as a submit-active flag (see header)
        LD (FCB_SEQ_IO_STEP_8_STG+1),A
        ; ; record count = 1 for the following BDOS record step
        LD C,$01
        CALL READ_CON_BUF_EDIT_12_STG
        CALL FCB_SET_REC_FLAG_4_p8_STG+1
        ; ; chain back to the transient open/stage loader ($9AD2) to load/run the SUBMIT file
        JP CMD_EXEC_51

    INCLUDE "CPM_BDOS.asm"   ; BDOS compiles together with the CCP
    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $9300, $1700
    ENDIF
