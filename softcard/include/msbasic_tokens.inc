; msbasic_tokens.inc -- Microsoft BASIC-80 Rev 5.2 (SoftCard CP/M 2.20)
; single-byte keyword/operator TOKENS. GENERATED from the GBASIC.COM
; reserved-word table (cpm_pipeline.basic.reswords) -- the ground truth:
; per-letter index $021E, name table $0252 (last char high-bit set, token
; byte follows), operator sub-table $04D8. Validated against the $0108
; statement dispatch. EQUs are zero-width, so INCLUDEing this is
; byte-identical. CRUNCH folds source keywords to these tokens;
; DETOKENIZE_LINE reverses it; SYNCHR / FRMEVL match them inline.

TOK_LEFTS        EQU $01   ; LEFT$
TOK_RIGHTS       EQU $02   ; RIGHT$
TOK_MIDS         EQU $03   ; MID$
TOK_SGN          EQU $04   ; SGN
TOK_INT          EQU $05   ; INT
TOK_ABS          EQU $06   ; ABS
TOK_SQR          EQU $07   ; SQR
TOK_RND          EQU $08   ; RND
TOK_SIN          EQU $09   ; SIN
TOK_LOG          EQU $0A   ; LOG
TOK_EXP          EQU $0B   ; EXP
TOK_COS          EQU $0C   ; COS
TOK_TAN          EQU $0D   ; TAN
TOK_ATN          EQU $0E   ; ATN
TOK_FRE          EQU $0F   ; FRE
TOK_POS          EQU $10   ; POS
TOK_LEN          EQU $11   ; LEN
TOK_STRS         EQU $12   ; STR$
TOK_VAL          EQU $13   ; VAL
TOK_ASC          EQU $14   ; ASC
TOK_CHRS         EQU $15   ; CHR$
TOK_PEEK         EQU $16   ; PEEK
TOK_SPACES       EQU $17   ; SPACE$
TOK_OCTS         EQU $18   ; OCT$
TOK_HEXS         EQU $19   ; HEX$
TOK_LPOS         EQU $1A   ; LPOS
TOK_CINT         EQU $1B   ; CINT
TOK_CSNG         EQU $1C   ; CSNG
TOK_CDBL         EQU $1D   ; CDBL
TOK_FIX          EQU $1E   ; FIX
TOK_CVI          EQU $2A   ; CVI
TOK_CVS          EQU $2B   ; CVS
TOK_CVD          EQU $2C   ; CVD
TOK_EOF          EQU $2E   ; EOF
TOK_LOC          EQU $2F   ; LOC
TOK_LOF          EQU $30   ; LOF
TOK_MKIS         EQU $31   ; MKI$
TOK_MKSS         EQU $32   ; MKS$
TOK_MKDS         EQU $33   ; MKD$
TOK_VPOS         EQU $34   ; VPOS
TOK_PDL          EQU $35   ; PDL
TOK_BUTTON       EQU $36   ; BUTTON
TOK_END          EQU $81   ; END
TOK_FOR          EQU $82   ; FOR
TOK_NEXT         EQU $83   ; NEXT
TOK_DATA         EQU $84   ; DATA
TOK_INPUT        EQU $85   ; INPUT
TOK_DIM          EQU $86   ; DIM
TOK_READ         EQU $87   ; READ
TOK_LET          EQU $88   ; LET
TOK_GOTO         EQU $89   ; GOTO / GO TO
TOK_RUN          EQU $8A   ; RUN
TOK_IF           EQU $8B   ; IF
TOK_RESTORE      EQU $8C   ; RESTORE
TOK_GOSUB        EQU $8D   ; GOSUB
TOK_RETURN       EQU $8E   ; RETURN
TOK_REM          EQU $8F   ; REM
TOK_STOP         EQU $90   ; STOP
TOK_PRINT        EQU $91   ; PRINT
TOK_CLEAR        EQU $92   ; CLEAR
TOK_LIST         EQU $93   ; LIST
TOK_NEW          EQU $94   ; NEW
TOK_ON           EQU $95   ; ON
TOK_DEF          EQU $96   ; DEF
TOK_POKE         EQU $97   ; POKE
TOK_CONT         EQU $98   ; CONT
TOK_LPRINT       EQU $9B   ; LPRINT
TOK_LLIST        EQU $9C   ; LLIST
TOK_WIDTH        EQU $9D   ; WIDTH
TOK_ELSE         EQU $9E   ; ELSE
TOK_TRACE        EQU $9F   ; TRACE
TOK_NOTRACE      EQU $A0   ; NOTRACE
TOK_SWAP         EQU $A1   ; SWAP
TOK_ERASE        EQU $A2   ; ERASE
TOK_EDIT         EQU $A3   ; EDIT
TOK_ERROR        EQU $A4   ; ERROR
TOK_RESUME       EQU $A5   ; RESUME
TOK_DELETE       EQU $A6   ; DELETE
TOK_DEL          EQU $A6   ; DEL
TOK_AUTO         EQU $A7   ; AUTO
TOK_RENUM        EQU $A8   ; RENUM
TOK_DEFSTR       EQU $A9   ; DEFSTR
TOK_DEFINT       EQU $AA   ; DEFINT
TOK_DEFSNG       EQU $AB   ; DEFSNG
TOK_DEFDBL       EQU $AC   ; DEFDBL
TOK_LINE         EQU $AD   ; LINE
TOK_POP          EQU $AE   ; POP
TOK_WHILE        EQU $AF   ; WHILE
TOK_WEND         EQU $B0   ; WEND
TOK_CALL         EQU $B1   ; CALL
TOK_WRITE        EQU $B2   ; WRITE
TOK_COMMON       EQU $B3   ; COMMON
TOK_CHAIN        EQU $B4   ; CHAIN
TOK_OPTION       EQU $B5   ; OPTION
TOK_RANDOMIZE    EQU $B6   ; RANDOMIZE
TOK_SYSTEM       EQU $B7   ; SYSTEM
TOK_OPEN         EQU $B8   ; OPEN
TOK_FIELD        EQU $B9   ; FIELD
TOK_GET          EQU $BA   ; GET
TOK_PUT          EQU $BB   ; PUT
TOK_CLOSE        EQU $BC   ; CLOSE
TOK_LOAD         EQU $BD   ; LOAD
TOK_MERGE        EQU $BE   ; MERGE
TOK_FILES        EQU $BF   ; FILES
TOK_NAME         EQU $C0   ; NAME
TOK_KILL         EQU $C1   ; KILL
TOK_LSET         EQU $C2   ; LSET
TOK_RSET         EQU $C3   ; RSET
TOK_SAVE         EQU $C4   ; SAVE
TOK_RESET        EQU $C5   ; RESET
TOK_TEXT         EQU $C6   ; TEXT
TOK_HOME         EQU $C7   ; HOME
TOK_VTAB         EQU $C8   ; VTAB
TOK_HTAB         EQU $C9   ; HTAB
TOK_INVERSE      EQU $CA   ; INVERSE
TOK_NORMAL       EQU $CB   ; NORMAL
TOK_GR           EQU $CC   ; GR
TOK_COLOR        EQU $CD   ; COLOR
TOK_HLIN         EQU $CE   ; HLIN
TOK_VLIN         EQU $CF   ; VLIN
TOK_PLOT         EQU $D0   ; PLOT
TOK_HGR          EQU $D1   ; HGR
TOK_HPLOT        EQU $D2   ; HPLOT
TOK_HCOLOR       EQU $D3   ; HCOLOR
TOK_BEEP         EQU $D4   ; BEEP
TOK_WAIT         EQU $D5   ; WAIT
TOK_TO           EQU $DD   ; TO
TOK_THEN         EQU $DE   ; THEN
TOK_TAB_LP       EQU $DF   ; TAB(
TOK_STEP         EQU $E0   ; STEP
TOK_USR          EQU $E1   ; USR
TOK_FN           EQU $E2   ; FN
TOK_SPC_LP       EQU $E3   ; SPC(
TOK_NOT          EQU $E4   ; NOT
TOK_ERL          EQU $E5   ; ERL
TOK_ERR          EQU $E6   ; ERR
TOK_STRINGS      EQU $E7   ; STRING$
TOK_USING        EQU $E8   ; USING
TOK_INSTR        EQU $E9   ; INSTR
TOK_REM_QUOTE    EQU $EA   ; ''' operator
TOK_VARPTR       EQU $EB   ; VARPTR
TOK_SCRN         EQU $EC   ; SCRN
TOK_HSCRN        EQU $ED   ; HSCRN
TOK_INKEYS       EQU $EE   ; INKEY$
TOK_GT           EQU $EF   ; '>' operator
TOK_EQ           EQU $F0   ; '=' operator
TOK_LT           EQU $F1   ; '<' operator
TOK_PLUS         EQU $F2   ; '+' operator
TOK_MINUS        EQU $F3   ; '-' operator
TOK_MUL          EQU $F4   ; '*' operator
TOK_DIV          EQU $F5   ; '/' operator
TOK_POW          EQU $F6   ; '^' operator
TOK_AND          EQU $F7   ; AND
TOK_OR           EQU $F8   ; OR
TOK_XOR          EQU $F9   ; XOR
TOK_EQV          EQU $FA   ; EQV
TOK_IMP          EQU $FB   ; IMP
TOK_MOD          EQU $FC   ; MOD
TOK_IDIV         EQU $FD   ; '\' operator

