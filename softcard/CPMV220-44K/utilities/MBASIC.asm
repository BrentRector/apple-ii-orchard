; MBASIC.COM -- Microsoft BASIC-80 Rev 5.2 interpreter (graphics OFF), SoftCard CP/M 2.20 (44K).
; Clean-slate disassembly of the MBASIC.COM bytes on the 2.20-44K system disk; reassembles
; byte-identically.  Range: $0100-$60FF (24576 bytes).  MBASIC runs IN PLACE at $0100 (entry
; $0100 = JP $5E51 cold start); it is the graphics-OFF build of the same engine as GBASIC,
; so the graphics tokens dispatch to a 'Graphics statement not implemented' error stub.

    DEVICE NOSLOT64K
    INCLUDE "apple_softcard.inc"   ; canonical Apple/SoftCard external names
    INCLUDE "msbasic_tokens.inc"   ; MS BASIC keyword-token names
    INCLUDE "msbasic_errors.inc"   ; MS BASIC error-code names (ERR_*)

    ORG $0100

; CP/M .COM entry point at $0100: JP COLD_START ($5E51). MBASIC runs in place (no relocation), so this is the only fixed CP/M load address. Replaces SUB_0100. [RE]
COM_ENTRY:
        JP COLD_START                    ; $0100  C3 51 5E
        DEFW    FN_LPOS                  ; $0103
        DEFB    $55                      ; $0105
COM_ENTRY_1:
        INC L                            ; $0106  2C
COM_ENTRY_2:
        NOP                              ; $0107  00
STMT_DISPATCH_TBL:
        DEFW    STMT_END                 ; $0108
        DEFW    STMT_FOR                 ; $010A
        DEFW    STMT_NEXT                ; $010C
        DEFW    STMT_DATA                ; $010E
        DEFW    STMT_INPUT               ; $0110
        DEFW    PTRGET                   ; $0112
        DEFW    STMT_READ                ; $0114
        DEFW    STMT_LET                 ; $0116
        DEFW    STMT_GOTO                ; $0118
        DEFW    STMT_RUN                 ; $011A
        DEFW    STMT_IF                  ; $011C
        DEFW    STMT_RESTORE             ; $011E
        DEFW    STMT_GOSUB               ; $0120
        DEFW    STMT_RETURN              ; $0122
        DEFW    STMT_DATA+2              ; $0124
        DEFW    STMT_STOP                ; $0126
        DEFW    STMT_PRINT               ; $0128
        DEFW    STMT_CLEAR               ; $012A
        DEFW    STMT_LIST                ; $012C
        DEFW    STMT_NEW                 ; $012E
        DEFW    STMT_ON                  ; $0130
        DEFW    STMT_DEF                 ; $0132
        DEFW    STMT_POKE                ; $0134
        DEFW    STMT_CONT                ; $0136
        DEFW    RAISE_SYNTAX_ERROR       ; $0138
        DEFB    $92                      ; $013A
        DEFB    $0D                      ; $013B
        DEFW    STMT_LPRINT              ; $013C
        DEFW    STMT_LLIST               ; $013E
        DEFW    STMT_WIDTH               ; $0140
        DEFW    STMT_DATA+2              ; $0142
        DEFW    STMT_TRACE               ; $0144
        DEFW    STMT_TRACE+1             ; $0146
        DEFW    STMT_SWAP                ; $0148
        DEFW    STMT_ERASE               ; $014A
        DEFW    STMT_EDIT                ; $014C
        DEFW    STMT_ERROR               ; $014E
        DEFW    STMT_RESUME              ; $0150
        DEFW    STMT_DELETE              ; $0152
        DEFW    SCAN_LINE_RANGE_RESUME   ; $0154
        DEFW    STMT_RENUM               ; $0156
        DEFW    STMT_DEFSTR              ; $0158
        DEFW    STMT_DEFSTR_1+1          ; $015A
        DEFW    STMT_DEFSTR_2+1          ; $015C
        DEFW    STMT_DEFSTR_3+1          ; $015E
        DEFW    STMT_LINE                ; $0160
        DEFW    STMT_POP                 ; $0162
        DEFW    STMT_WHILE               ; $0164
        DEFW    STMT_WEND                ; $0166
        DEFW    STMT_CALL                ; $0168
        DEFW    STMT_WRITE               ; $016A
        DEFW    STMT_DATA                ; $016C
        DEFW    STMT_CHAIN               ; $016E
        DEFW    STMT_OPTION              ; $0170
        DEFW    STMT_RANDOMIZE           ; $0172
        DEFW    STMT_SYSTEM              ; $0174
        DEFW    STMT_OPEN                ; $0176
        DEFW    STMT_FIELD               ; $0178
        DEFW    STMT_PUT+1               ; $017A
        DEFW    STMT_PUT                 ; $017C
        DEFW    STMT_CLOSE               ; $017E
        DEFW    OPEN_NAMED_FILE_1+1      ; $0180
        DEFW    STMT_MERGE               ; $0182
        DEFW    STMT_FILES               ; $0184
        DEFW    STMT_NAME                ; $0186
        DEFW    STMT_KILL                ; $0188
        DEFW    STMT_RSET+1              ; $018A
        DEFW    STMT_RSET                ; $018C
        DEFW    STMT_SAVE                ; $018E
        DEFW    STMT_RESET               ; $0190
        DEFW    STMT_TEXT                ; $0192
        DEFW    GFX_STMT_HOME            ; $0194
        DEFW    GFX_STMT_VTAB            ; $0196
        DEFW    GFX_STMT_HTAB            ; $0198
        DEFW    GFX_STMT_HOME_1+1        ; $019A
        DEFW    GFX_STMT_HOME_2+1        ; $019C
        DEFW    GFX_STMT_GR              ; $019E
        DEFW    GFX_STMT_COLOR           ; $01A0
        DEFW    GFX_STMT_HLIN            ; $01A2
        DEFW    GFX_STMT_VLIN            ; $01A4
        DEFW    GFX_STMT_PLOT            ; $01A6
        DEFW    SUB_2803_1+1             ; $01A8
        DEFW    SUB_2803_1+1             ; $01AA
        DEFW    SUB_2803_1+1             ; $01AC
        DEFW    GFX_STMT_BEEP            ; $01AE
        DEFW    STMT_WAIT                ; $01B0
FUNC_DISPATCH_TBL:
        DEFW    STR_SUBSTR_ALLOC_COPY    ; $01B2
        DEFW    FN_LEFT_STR              ; $01B4
        DEFW    FN_RIGHT_STR             ; $01B6
        DEFW    FN_MID_STR               ; $01B8
        DEFW    FN_SGN                   ; $01BA
        DEFW    FN_INT                   ; $01BC
        DEFW    FN_ABS                   ; $01BE
        DEFW    FN_SQR                   ; $01C0
        DEFW    FN_RND                   ; $01C2
        DEFW    FN_SIN                   ; $01C4
        DEFW    FN_LOG                   ; $01C6
        DEFW    FN_EXP                   ; $01C8
        DEFW    FN_COS                   ; $01CA
        DEFW    FN_TAN                   ; $01CC
        DEFW    FN_ATN                   ; $01CE
        DEFW    FP_LOAD_COL_TO_FAC       ; $01D0
        DEFW    FN_POS                   ; $01D2
        DEFW    STR_FN_FINALIZE          ; $01D4
        DEFW    STR_VAL_NULTERM          ; $01D6
        DEFW    FN_VAL                   ; $01D8
        DEFW    FN_ASC                   ; $01DA
        DEFW    FN_CHR_STR               ; $01DC
        DEFW    FN_PEEK                  ; $01DE
        DEFW    FN_SPACE_STR             ; $01E0
        DEFW    FN_OCT_STR               ; $01E2
        DEFW    FN_HEX_STR               ; $01E4
        DEFW    FN_LPOS                  ; $01E6
        DEFW    FN_CINT                  ; $01E8
        DEFW    FN_CSNG                  ; $01EA
        DEFW    FN_CDBL                  ; $01EC
        DEFW    $0000                    ; $01EE
        DEFW    $0000                    ; $01F0
        DEFW    $0000                    ; $01F2
        DEFW    $0000                    ; $01F4
        DEFW    $0000                    ; $01F6
        DEFW    $0000                    ; $01F8
        DEFW    $0000                    ; $01FA
        DEFW    $0000                    ; $01FC
        DEFW    $0000                    ; $01FE
        DEFW    $0000                    ; $0200
        DEFW    $0000                    ; $0202
        DEFW    FN_CVI                   ; $0204
        DEFW    FN_CVI_1+1               ; $0206
        DEFW    FN_CVI_2+1               ; $0208
        DEFW    $0000                    ; $020A
        DEFW    FN_EOF                   ; $020C
        DEFW    FN_LOC_VALUE             ; $020E
        DEFW    FN_LOF_VALUE             ; $0210
        DEFW    FN_LOF                   ; $0212
        DEFW    FN_LOF_1+1               ; $0214
        DEFW    FN_LOF_2+1               ; $0216
        DEFW    GFX_FN_MKD_STR           ; $0218
        DEFW    GFX_FN_VPOS              ; $021A
        DEFW    GFX_FN_PDL               ; $021C
; -- Reserved-word / token table (CRUNCH keyword<->token map). The
;    per-letter index points at each first-letter group; a name entry
;    is the keyword TAIL (first letter implied), last char high-bit set,
;    then the token byte; $00 ends a group. Operator sub-table = (char,
;    token) pairs. Byte-identical to the original DEFB bytes.
RESWORD_INDEX:                           ; $021E  per-letter group pointers A-Z
        DEFW    KWGRP_A,KWGRP_B,KWGRP_C,KWGRP_D,KWGRP_E,KWGRP_F
        DEFW    KWGRP_G,KWGRP_H,KWGRP_I,KWGRP_J,KWGRP_K,KWGRP_L
        DEFW    KWGRP_M,KWGRP_N,KWGRP_O,KWGRP_P,KWGRP_Q,KWGRP_R
        DEFW    KWGRP_S,KWGRP_T,KWGRP_U,KWGRP_V,KWGRP_W,KWGRP_X
        DEFW    KWGRP_Y,KWGRP_Z
KWGRP_A:                                 ; $0252
        DEFB    'N','D'+$80,TOK_AND          ; AND
        DEFB    'B','S'+$80,TOK_ABS          ; ABS
        DEFB    'T','N'+$80,TOK_ATN          ; ATN
        DEFB    'S','C'+$80,TOK_ASC          ; ASC
        DEFB    'U','T','O'+$80,TOK_AUTO     ; AUTO
        DEFB    $00                          ; end A-group
KWGRP_B:                                 ; $0263
        DEFB    'U','T','T','O','N'+$80,TOK_BUTTON ; BUTTON
        DEFB    'E','E','P'+$80,TOK_BEEP     ; BEEP
        DEFB    $00                          ; end B-group
KWGRP_C:                                 ; $026E
        DEFB    'L','O','S','E'+$80,TOK_CLOSE ; CLOSE
        DEFB    'O','N','T'+$80,TOK_CONT     ; CONT
        DEFB    'L','E','A','R'+$80,TOK_CLEAR ; CLEAR
        DEFB    'I','N','T'+$80,TOK_CINT     ; CINT
        DEFB    'S','N','G'+$80,TOK_CSNG     ; CSNG
        DEFB    'D','B','L'+$80,TOK_CDBL     ; CDBL
        DEFB    'V','I'+$80,TOK_CVI          ; CVI
        DEFB    'V','S'+$80,TOK_CVS          ; CVS
        DEFB    'V','D'+$80,TOK_CVD          ; CVD
        DEFB    'O','S'+$80,TOK_COS          ; COS
        DEFB    'H','R','$'+$80,TOK_CHRS     ; CHR$
        DEFB    'A','L','L'+$80,TOK_CALL     ; CALL
        DEFB    'O','M','M','O','N'+$80,TOK_COMMON ; COMMON
        DEFB    'H','A','I','N'+$80,TOK_CHAIN ; CHAIN
        DEFB    'O','L','O','R'+$80,TOK_COLOR ; COLOR
        DEFB    $00                          ; end C-group
KWGRP_D:                                 ; $02AD
        DEFB    'A','T','A'+$80,TOK_DATA     ; DATA
        DEFB    'I','M'+$80,TOK_DIM          ; DIM
        DEFB    'E','F','S','T','R'+$80,TOK_DEFSTR ; DEFSTR
        DEFB    'E','F','I','N','T'+$80,TOK_DEFINT ; DEFINT
        DEFB    'E','F','S','N','G'+$80,TOK_DEFSNG ; DEFSNG
        DEFB    'E','F','D','B','L'+$80,TOK_DEFDBL ; DEFDBL
        DEFB    'E','F'+$80,TOK_DEF          ; DEF
        DEFB    'E','L','E','T','E'+$80,TOK_DELETE ; DELETE
        DEFB    'E','L'+$80,TOK_DEL          ; DEL
        DEFB    $00                          ; end D-group
KWGRP_E:                                 ; $02D9
        DEFB    'N','D'+$80,TOK_END          ; END
        DEFB    'L','S','E'+$80,TOK_ELSE     ; ELSE
        DEFB    'R','A','S','E'+$80,TOK_ERASE ; ERASE
        DEFB    'D','I','T'+$80,TOK_EDIT     ; EDIT
        DEFB    'R','R','O','R'+$80,TOK_ERROR ; ERROR
        DEFB    'R','L'+$80,TOK_ERL          ; ERL
        DEFB    'R','R'+$80,TOK_ERR          ; ERR
        DEFB    'X','P'+$80,TOK_EXP          ; EXP
        DEFB    'O','F'+$80,TOK_EOF          ; EOF
        DEFB    'Q','V'+$80,TOK_EQV          ; EQV
        DEFB    $00                          ; end E-group
KWGRP_F:                                 ; $02FE
        DEFB    'O','R'+$80,TOK_FOR          ; FOR
        DEFB    'I','E','L','D'+$80,TOK_FIELD ; FIELD
        DEFB    'I','L','E','S'+$80,TOK_FILES ; FILES
        DEFB    'N'+$80,TOK_FN               ; FN
        DEFB    'R','E'+$80,TOK_FRE          ; FRE
        DEFB    'I','X'+$80,TOK_FIX          ; FIX
        DEFB    $00                          ; end F-group
KWGRP_G:                                 ; $0314
        DEFB    'O','T','O'+$80,TOK_GOTO     ; GOTO
        DEFB    'O',' ','T','O'+$80,TOK_GOTO ; GO TO
        DEFB    'O','S','U','B'+$80,TOK_GOSUB ; GOSUB
        DEFB    'E','T'+$80,TOK_GET          ; GET
        DEFB    'R'+$80,TOK_GR               ; GR
        DEFB    $00                          ; end G-group
KWGRP_H:                                 ; $0328
        DEFB    'O','M','E'+$80,TOK_HOME     ; HOME
        DEFB    'L','I','N'+$80,TOK_HLIN     ; HLIN
        DEFB    'G','R'+$80,TOK_HGR          ; HGR
        DEFB    'C','O','L','O','R'+$80,TOK_HCOLOR ; HCOLOR
        DEFB    'P','L','O','T'+$80,TOK_HPLOT ; HPLOT
        DEFB    'T','A','B'+$80,TOK_HTAB     ; HTAB
        DEFB    'S','C','R','N'+$80,TOK_HSCRN ; HSCRN
        DEFB    'E','X','$'+$80,TOK_HEXS     ; HEX$
        DEFB    $00                          ; end H-group
KWGRP_I:                                 ; $034C
        DEFB    'N','P','U','T'+$80,TOK_INPUT ; INPUT
        DEFB    'F'+$80,TOK_IF               ; IF
        DEFB    'N','S','T','R'+$80,TOK_INSTR ; INSTR
        DEFB    'N','T'+$80,TOK_INT          ; INT
        DEFB    'M','P'+$80,TOK_IMP          ; IMP
        DEFB    'N','K','E','Y','$'+$80,TOK_INKEYS ; INKEY$
        DEFB    'N','V','E','R','S','E'+$80,TOK_INVERSE ; INVERSE
        DEFB    $00                          ; end I-group
KWGRP_J:                                 ; $036C
        DEFB    $00                          ; end J-group
KWGRP_K:                                 ; $036D
        DEFB    'I','L','L'+$80,TOK_KILL     ; KILL
        DEFB    $00                          ; end K-group
KWGRP_L:                                 ; $0372
        DEFB    'E','T'+$80,TOK_LET          ; LET
        DEFB    'I','N','E'+$80,TOK_LINE     ; LINE
        DEFB    'O','A','D'+$80,TOK_LOAD     ; LOAD
        DEFB    'S','E','T'+$80,TOK_LSET     ; LSET
        DEFB    'P','R','I','N','T'+$80,TOK_LPRINT ; LPRINT
        DEFB    'L','I','S','T'+$80,TOK_LLIST ; LLIST
        DEFB    'P','O','S'+$80,TOK_LPOS     ; LPOS
        DEFB    'I','S','T'+$80,TOK_LIST     ; LIST
        DEFB    'O','G'+$80,TOK_LOG          ; LOG
        DEFB    'O','C'+$80,TOK_LOC          ; LOC
        DEFB    'E','N'+$80,TOK_LEN          ; LEN
        DEFB    'E','F','T','$'+$80,TOK_LEFTS ; LEFT$
        DEFB    'O','F'+$80,TOK_LOF          ; LOF
        DEFB    $00                          ; end L-group
KWGRP_M:                                 ; $03A6
        DEFB    'E','R','G','E'+$80,TOK_MERGE ; MERGE
        DEFB    'O','D'+$80,TOK_MOD          ; MOD
        DEFB    'K','I','$'+$80,TOK_MKIS     ; MKI$
        DEFB    'K','S','$'+$80,TOK_MKSS     ; MKS$
        DEFB    'K','D','$'+$80,TOK_MKDS     ; MKD$
        DEFB    'I','D','$'+$80,TOK_MIDS     ; MID$
        DEFB    $00                          ; end M-group
KWGRP_N:                                 ; $03BF
        DEFB    'E','X','T'+$80,TOK_NEXT     ; NEXT
        DEFB    'O','R','M','A','L'+$80,TOK_NORMAL ; NORMAL
        DEFB    'O','T','R','A','C','E'+$80,TOK_NOTRACE ; NOTRACE
        DEFB    'A','M','E'+$80,TOK_NAME     ; NAME
        DEFB    'E','W'+$80,TOK_NEW          ; NEW
        DEFB    'O','T'+$80,TOK_NOT          ; NOT
        DEFB    $00                          ; end N-group
KWGRP_O:                                 ; $03DB
        DEFB    'N'+$80,TOK_ON               ; ON
        DEFB    'P','E','N'+$80,TOK_OPEN     ; OPEN
        DEFB    'R'+$80,TOK_OR               ; OR
        DEFB    'C','T','$'+$80,TOK_OCTS     ; OCT$
        DEFB    'P','T','I','O','N'+$80,TOK_OPTION ; OPTION
        DEFB    $00                          ; end O-group
KWGRP_P:                                 ; $03EE
        DEFB    'U','T'+$80,TOK_PUT          ; PUT
        DEFB    'O','K','E'+$80,TOK_POKE     ; POKE
        DEFB    'R','I','N','T'+$80,TOK_PRINT ; PRINT
        DEFB    'O','S'+$80,TOK_POS          ; POS
        DEFB    'E','E','K'+$80,TOK_PEEK     ; PEEK
        DEFB    'L','O','T'+$80,TOK_PLOT     ; PLOT
        DEFB    'D','L'+$80,TOK_PDL          ; PDL
        DEFB    'O','P'+$80,TOK_POP          ; POP
        DEFB    $00                          ; end P-group
KWGRP_Q:                                 ; $040C
        DEFB    $00                          ; end Q-group
KWGRP_R:                                 ; $040D
        DEFB    'E','A','D'+$80,TOK_READ     ; READ
        DEFB    'U','N'+$80,TOK_RUN          ; RUN
        DEFB    'E','S','T','O','R','E'+$80,TOK_RESTORE ; RESTORE
        DEFB    'E','T','U','R','N'+$80,TOK_RETURN ; RETURN
        DEFB    'E','M'+$80,TOK_REM          ; REM
        DEFB    'E','S','U','M','E'+$80,TOK_RESUME ; RESUME
        DEFB    'S','E','T'+$80,TOK_RSET     ; RSET
        DEFB    'I','G','H','T','$'+$80,TOK_RIGHTS ; RIGHT$
        DEFB    'N','D'+$80,TOK_RND          ; RND
        DEFB    'E','N','U','M'+$80,TOK_RENUM ; RENUM
        DEFB    'E','S','E','T'+$80,TOK_RESET ; RESET
        DEFB    'A','N','D','O','M','I','Z','E'+$80,TOK_RANDOMIZE ; RANDOMIZE
        DEFB    $00                          ; end R-group
KWGRP_S:                                 ; $044B
        DEFB    'T','O','P'+$80,TOK_STOP     ; STOP
        DEFB    'W','A','P'+$80,TOK_SWAP     ; SWAP
        DEFB    'A','V','E'+$80,TOK_SAVE     ; SAVE
        DEFB    'P','C','('+$80,TOK_SPC_LP   ; SPC(
        DEFB    'T','E','P'+$80,TOK_STEP     ; STEP
        DEFB    'G','N'+$80,TOK_SGN          ; SGN
        DEFB    'Q','R'+$80,TOK_SQR          ; SQR
        DEFB    'I','N'+$80,TOK_SIN          ; SIN
        DEFB    'T','R','$'+$80,TOK_STRS     ; STR$
        DEFB    'T','R','I','N','G','$'+$80,TOK_STRINGS ; STRING$
        DEFB    'P','A','C','E','$'+$80,TOK_SPACES ; SPACE$
        DEFB    'Y','S','T','E','M'+$80,TOK_SYSTEM ; SYSTEM
        DEFB    'C','R','N'+$80,TOK_SCRN     ; SCRN
        DEFB    $00                          ; end S-group
KWGRP_T:                                 ; $0484
        DEFB    'R','A','C','E'+$80,TOK_TRACE ; TRACE
        DEFB    'A','B','('+$80,TOK_TAB_LP   ; TAB(
        DEFB    'O'+$80,TOK_TO               ; TO
        DEFB    'H','E','N'+$80,TOK_THEN     ; THEN
        DEFB    'A','N'+$80,TOK_TAN          ; TAN
        DEFB    'E','X','T'+$80,TOK_TEXT     ; TEXT
        DEFB    $00                          ; end T-group
KWGRP_U:                                 ; $049B
        DEFB    'S','I','N','G'+$80,TOK_USING ; USING
        DEFB    'S','R'+$80,TOK_USR          ; USR
        DEFB    $00                          ; end U-group
KWGRP_V:                                 ; $04A4
        DEFB    'A','L'+$80,TOK_VAL          ; VAL
        DEFB    'A','R','P','T','R'+$80,TOK_VARPTR ; VARPTR
        DEFB    'L','I','N'+$80,TOK_VLIN     ; VLIN
        DEFB    'T','A','B'+$80,TOK_VTAB     ; VTAB
        DEFB    'P','O','S'+$80,TOK_VPOS     ; VPOS
        DEFB    $00                          ; end V-group
KWGRP_W:                                 ; $04BA
        DEFB    'I','D','T','H'+$80,TOK_WIDTH ; WIDTH
        DEFB    'A','I','T'+$80,TOK_WAIT     ; WAIT
        DEFB    'H','I','L','E'+$80,TOK_WHILE ; WHILE
        DEFB    'E','N','D'+$80,TOK_WEND     ; WEND
        DEFB    'R','I','T','E'+$80,TOK_WRITE ; WRITE
        DEFB    $00                          ; end W-group
KWGRP_X:                                 ; $04D2
        DEFB    'O','R'+$80,TOK_XOR          ; XOR
        DEFB    $00                          ; end X-group
KWGRP_Y:                                 ; $04D6
        DEFB    $00                          ; end Y-group
KWGRP_Z:                                 ; $04D7
        DEFB    $00                          ; end Z-group
RESWORD_OPS:                             ; $04D8  operator (char,token) pairs
        DEFB    '+'+$80,TOK_PLUS             ; '+'
        DEFB    '-'+$80,TOK_MINUS            ; '-'
        DEFB    '*'+$80,TOK_MUL              ; '*'
        DEFB    '/'+$80,TOK_DIV              ; '/'
        DEFB    '^'+$80,TOK_POW              ; '^'
        DEFB    $DC,TOK_IDIV                 ; '\'
        DEFB    $A7,TOK_REM_QUOTE            ; '''
        DEFB    '>'+$80,TOK_GT               ; '>'
        DEFB    '='+$80,TOK_EQ               ; '='
        DEFB    '<'+$80,TOK_LT               ; '<'
        DEFB    $00                          ; end operators
FRMEVL_PREC_TBL:
        DEFB    $79,$79,$7C,$7C,$7F,$50,$46,$3C,$32,$28,$7A,$7B  ; $04ED
OPERATOR_ROUTINE_TBL:
        DEFW    FN_CSNG                  ; $04F9
        DEFW    $0000                    ; $04FB
        DEFW    FN_LPOS                  ; $04FD
        DEFW    FP_INT_CHECK             ; $04FF
        DEFW    FN_CINT                  ; $0501
        DEFW    DADD                     ; $0503
        DEFW    DP_NEGATE_SIGN           ; $0505
        DEFW    DMUL                     ; $0507
        DEFW    DDIV                     ; $0509
        DEFW    DCOMP_REL                ; $050B
        DEFW    FADD_ALIGN               ; $050D
        DEFW    FSUB                     ; $050F
        DEFW    FMUL                     ; $0511
        DEFW    FDIV                     ; $0513
        DEFW    FCOMP                    ; $0515
        DEFW    IADD                     ; $0517
        DEFW    INT_SIGNEXT_SUB          ; $0519
        DEFW    IMUL                     ; $051B
        DEFB    $02                      ; $051D
        DEFB    $1C                      ; $051E
        DEFW    INT16_COMP               ; $051F
; -- Error-message table. RAISE_ERROR is entered with the error code in E.
;    The base ERROR_MESSAGE_TABLE ($0521) is a $00 = the empty message 0; the printer
;    scans E terminators forward from it, so code E selects the E-th message (err 1 =
;    'NEXT without FOR'). BASIC errors are codes 1..N; the disk errors (FIELD overflow
;    on) are remapped to codes 50..70 (the scan does CP $32 / SUB $12). Codes are the
;    ERR_* equates (msbasic_errors.inc); messages are not individually referenced, so
;    only the few a trap loads by pointer keep an ERRMSG_* label.
; [RE] Error-message table base AND the direct-mode empty message: the $00 here is error message 0 (the scan base) and is also printed by ERROR_RESUME_FROM_DIRECT as the empty '?<>' direct-mode error text.
ERROR_MESSAGE_TABLE:
        DEFB    $00                      ; $0521  err 0 (empty message, scan base)
        DEFB    "NEXT without FOR",$00   ; $0522  ERR_NEXT_WITHOUT_FOR = 1
        DEFB    "Syntax error",$00       ; $0533  ERR_SYNTAX_ERROR = 2
        DEFB    "RETURN without GOSUB",$00  ; $0540  ERR_RETURN_WITHOUT_GOSUB = 3
        DEFB    "Out of DATA",$00        ; $0555  ERR_OUT_OF_DATA = 4
        DEFB    "Illegal function call",$00  ; $0561  ERR_ILLEGAL_FUNCTION_CALL = 5
; [RE] Error message string "Overflow" (error $06): loaded by the error reporter; the overflow trap also sets the current-message pointer ($0848) to it.
ERRMSG_OVERFLOW:
        DEFB    "Overflow",$00           ; $0577  ERR_OVERFLOW = 6
        DEFB    "Out of memory",$00      ; $0580  ERR_OUT_OF_MEMORY = 7
        DEFB    "Undefined line number",$00  ; $058E  ERR_UNDEFINED_LINE_NUMBER = 8
        DEFB    "Subscript out of range",$00  ; $05A4  ERR_SUBSCRIPT_OUT_OF_RANGE = 9
        DEFB    "Duplicate Definition",$00  ; $05BB  ERR_DUPLICATE_DEFINITION = 10
; [RE] Error message string "Division by zero" (error $0B): the FP divide-by-zero path stores this pointer into the current-error-message cell ($0848).
ERRMSG_DIVISION_BY_ZERO:
        DEFB    "Division by zero",$00   ; $05D0  ERR_DIVISION_BY_ZERO = 11
        DEFB    "Illegal direct",$00     ; $05E1  ERR_ILLEGAL_DIRECT = 12
        DEFB    "Type mismatch",$00      ; $05F0  ERR_TYPE_MISMATCH = 13
        DEFB    "Out of string space",$00  ; $05FE  ERR_OUT_OF_STRING_SPACE = 14
        DEFB    "String too long",$00    ; $0612  ERR_STRING_TOO_LONG = 15
        DEFB    "String formula too complex",$00  ; $0622  ERR_STRING_FORMULA_TOO_COMPLEX = 16
        DEFB    "Can't continue",$00     ; $063D  ERR_CANT_CONTINUE = 17
        DEFB    "Undefined user function",$00  ; $064C  ERR_UNDEFINED_USER_FUNCTION = 18
        DEFB    "No RESUME",$00          ; $0664  ERR_NO_RESUME = 19
        DEFB    "RESUME without error",$00  ; $066E  ERR_RESUME_WITHOUT_ERROR = 20
        DEFB    "Unprintable error",$00  ; $0683  ERR_UNPRINTABLE_ERROR = 21
        DEFB    "Missing operand",$00    ; $0695  ERR_MISSING_OPERAND = 22
        DEFB    "Line buffer overflow",$00  ; $06A5  ERR_LINE_BUFFER_OVERFLOW = 23
        DEFB    "?",$00                  ; $06BA  ERR_UNUSED_24 = 24
        DEFB    "?",$00                  ; $06BC  ERR_UNUSED_25 = 25
        DEFB    "FOR Without NEXT",$00   ; $06BE  ERR_FOR_WITHOUT_NEXT = 26
        DEFB    "?",$00                  ; $06CF  ERR_UNUSED_27 = 27
        DEFB    "?",$00                  ; $06D1  ERR_UNUSED_28 = 28
        DEFB    "WHILE without WEND",$00 ; $06D3  ERR_WHILE_WITHOUT_WEND = 29
        DEFB    "WEND without WHILE",$00 ; $06E6  ERR_WEND_WITHOUT_WHILE = 30
        DEFB    "Reset error",$00        ; $06F9  ERR_RESET_ERROR = 31
        DEFB    "Graphics statement not implemented",$00  ; $0705  ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED = 32
        DEFB    "FIELD overflow",$00     ; $0728  ERR_FIELD_OVERFLOW = 50
        DEFB    "Internal error",$00     ; $0737  ERR_INTERNAL_ERROR = 51
        DEFB    "Bad file number",$00    ; $0746  ERR_BAD_FILE_NUMBER = 52
        DEFB    "File not found",$00     ; $0756  ERR_FILE_NOT_FOUND = 53
        DEFB    "Bad file mode",$00      ; $0765  ERR_BAD_FILE_MODE = 54
        DEFB    "File already open",$00  ; $0773  ERR_FILE_ALREADY_OPEN = 55
        DEFB    "?",$00                  ; $0785  ERR_UNUSED_56 = 56
        DEFB    "Disk I/O error",$00     ; $0787  ERR_DISK_I_O_ERROR = 57
        DEFB    "File already exists",$00  ; $0796  ERR_FILE_ALREADY_EXISTS = 58
        DEFB    "?",$00                  ; $07AA  ERR_UNUSED_59 = 59
        DEFB    "?",$00                  ; $07AC  ERR_UNUSED_60 = 60
        DEFB    "Disk full",$00          ; $07AE  ERR_DISK_FULL = 61
        DEFB    "Input past end",$00     ; $07B8  ERR_INPUT_PAST_END = 62
        DEFB    "Bad record number",$00  ; $07C7  ERR_BAD_RECORD_NUMBER = 63
        DEFB    "Bad file name",$00      ; $07D9  ERR_BAD_FILE_NAME = 64
        DEFB    "?",$00                  ; $07E7  ERR_UNUSED_65 = 65
        DEFB    "Direct statement in file",$00  ; $07E9  ERR_DIRECT_STATEMENT_IN_FILE = 66
        DEFB    "Too many files",$00     ; $0802  ERR_TOO_MANY_FILES = 67
        DEFB    "Disk Read Only",$00     ; $0811  ERR_DISK_READ_ONLY = 68
        DEFB    "Drive select error",$00 ; $0820  ERR_DRIVE_SELECT_ERROR = 69
        DEFB    "File Read Only",$00     ; $0833  ERR_FILE_READ_ONLY = 70
SUB_0752_28:
        EX DE,HL                         ; $0842  EB
        INC D                            ; $0843  14
SUB_0752_29:
        EX DE,HL                         ; $0844  EB
        INC D                            ; $0845  14
        EX DE,HL                         ; $0846  EB
        INC D                            ; $0847  14
        EX DE,HL                         ; $0848  EB
        INC D                            ; $0849  14
        EX DE,HL                         ; $084A  EB
        INC D                            ; $084B  14
        EX DE,HL                         ; $084C  EB
        INC D                            ; $084D  14
        EX DE,HL                         ; $084E  EB
        INC D                            ; $084F  14
        EX DE,HL                         ; $0850  EB
SUB_0752_30:
        INC D                            ; $0851  14
        EX DE,HL                         ; $0852  EB
        INC D                            ; $0853  14
        EX DE,HL                         ; $0854  EB
        INC D                            ; $0855  14
SUB_0752_31:
        LD BC,$0000                      ; $0856  01 00 00
        NOP                              ; $0859  00
SUB_0752_32:
        LD BC,$7000                      ; $085A  01 00 70
SUB_0752_33:
        ADD A,H                          ; $085D  84
SUB_0752_34:
        LD D,B                           ; $085E  50
SUB_0752_35:
        JR FILTAB_7                      ; $085F  18 38
SUB_0752_36:
        NOP                              ; $0861  00
; Ctrl-O output-suppress toggle: nonzero discards console output. Cleared at READY/cold-start, toggled by CONIN on Ctrl-O ($0F) and cleared on Ctrl-C. (Already commented in file.)
CTRL_O_SUPPRESS:
        NOP                              ; $0862  00
; Active-file FCB pointer (MS BASIC PTRFIL): 0 = console; set to a file's FCB during PRINT#/INPUT#/file I/O, reset to 0 at end of a console PRINT. Default $0000.
PTRFIL:
        NOP                              ; $0863  00
PTRFIL_1:
        NOP                              ; $0864  00
PTRFIL_2:
        XOR D                            ; $0865  AA
        LD H,C                           ; $0866  61
; [RE] Saved current text/statement pointer (MS BASIC SAVTXT): the running program pointer loaded into HL to execute; set to $FFFF in direct mode; CONT checks ==$FFFF for 'no continue'. Default $FFFE. Loaded/saved across CONT/RESUME and the storage-overflow guard.
SAVTXT:
        CP $FF                           ; $0867  FE FF
; Start of BASIC program text (MS BASIC TXTTAB): base of the linked line list, scanned by FNDLIN/relink/RUN/CLEAR. Default $84C9. The ,P-protected DECODE runs $0846..$0B6F.
TXTTAB:
        LD B,A                           ; $0869  47
        LD H,C                           ; $086A  61
TXTTAB_1:
        LD (HL),A                        ; $086B  77
        DEC B                            ; $086C  05
TXTTAB_2:
        NOP                              ; $086D  00
TXTTAB_3:
        NOP                              ; $086E  00
TXTTAB_4:
        NOP                              ; $086F  00
        NOP                              ; $0870  00
; [RE] Seed pointer for slot 0 of the file/FOR-slot pointer array at $0850: cold-start loads it with the warm-start re-entry MAIN_LOOP_ENTRY_1 ($81D1) and the CHAIN/OPEN reinit copies $084E into $0850/$0840 after CLEAR_VARS. Effectively the default first-slot/command pointer.
FILTAB_SLOT0_SEED:
        NOP                              ; $0871  00
FILTAB_SLOT0_SEED_1:
        NOP                              ; $0872  00
; [RE] File/FOR-slot pointer array (MS BASIC FILTAB), indexed by max-open-files ($0870); each entry points at an FCB base. Slot 0 doubles as the deferred start-up command pointer consulted at the Ok/main-loop entry ($81D1). 126-byte region.
FILTAB:
        NOP                              ; $0873  00
FILTAB_1:
        NOP                              ; $0874  00
        NOP                              ; $0875  00
        NOP                              ; $0876  00
        NOP                              ; $0877  00
        NOP                              ; $0878  00
        NOP                              ; $0879  00
        NOP                              ; $087A  00
        NOP                              ; $087B  00
        NOP                              ; $087C  00
        NOP                              ; $087D  00
        NOP                              ; $087E  00
        NOP                              ; $087F  00
        NOP                              ; $0880  00
        NOP                              ; $0881  00
        NOP                              ; $0882  00
        NOP                              ; $0883  00
        NOP                              ; $0884  00
        NOP                              ; $0885  00
        NOP                              ; $0886  00
        NOP                              ; $0887  00
        NOP                              ; $0888  00
        NOP                              ; $0889  00
        NOP                              ; $088A  00
FILTAB_2:
        NOP                              ; $088B  00
        NOP                              ; $088C  00
FILTAB_3:
        NOP                              ; $088D  00
        NOP                              ; $088E  00
        NOP                              ; $088F  00
        NOP                              ; $0890  00
        NOP                              ; $0891  00
        NOP                              ; $0892  00
FILTAB_4:
        NOP                              ; $0893  00
FILTAB_5:
        NOP                              ; $0894  00
FILTAB_6:
        NOP                              ; $0895  00
        NOP                              ; $0896  00
        NOP                              ; $0897  00
        NOP                              ; $0898  00
FILTAB_7:
        NOP                              ; $0899  00
FILTAB_8:
        NOP                              ; $089A  00
        NOP                              ; $089B  00
        NOP                              ; $089C  00
        NOP                              ; $089D  00
        NOP                              ; $089E  00
        NOP                              ; $089F  00
        NOP                              ; $08A0  00
        NOP                              ; $08A1  00
        NOP                              ; $08A2  00
        NOP                              ; $08A3  00
        NOP                              ; $08A4  00
        NOP                              ; $08A5  00
        NOP                              ; $08A6  00
        NOP                              ; $08A7  00
        NOP                              ; $08A8  00
        NOP                              ; $08A9  00
        NOP                              ; $08AA  00
        NOP                              ; $08AB  00
        NOP                              ; $08AC  00
        NOP                              ; $08AD  00
        NOP                              ; $08AE  00
        NOP                              ; $08AF  00
        NOP                              ; $08B0  00
        NOP                              ; $08B1  00
        NOP                              ; $08B2  00
        NOP                              ; $08B3  00
        NOP                              ; $08B4  00
        NOP                              ; $08B5  00
        NOP                              ; $08B6  00
        NOP                              ; $08B7  00
        NOP                              ; $08B8  00
        NOP                              ; $08B9  00
        NOP                              ; $08BA  00
FILTAB_9:
        NOP                              ; $08BB  00
        NOP                              ; $08BC  00
FILTAB_10:
        NOP                              ; $08BD  00
        NOP                              ; $08BE  00
        NOP                              ; $08BF  00
        NOP                              ; $08C0  00
        NOP                              ; $08C1  00
        NOP                              ; $08C2  00
        NOP                              ; $08C3  00
        NOP                              ; $08C4  00
        NOP                              ; $08C5  00
        NOP                              ; $08C6  00
        NOP                              ; $08C7  00
        NOP                              ; $08C8  00
        NOP                              ; $08C9  00
        NOP                              ; $08CA  00
        NOP                              ; $08CB  00
        NOP                              ; $08CC  00
FILTAB_11:
        NOP                              ; $08CD  00
FILTAB_12:
        NOP                              ; $08CE  00
        NOP                              ; $08CF  00
        NOP                              ; $08D0  00
        NOP                              ; $08D1  00
        NOP                              ; $08D2  00
        NOP                              ; $08D3  00
        NOP                              ; $08D4  00
        NOP                              ; $08D5  00
FILTAB_13:
        NOP                              ; $08D6  00
        NOP                              ; $08D7  00
        NOP                              ; $08D8  00
FILTAB_14:
        NOP                              ; $08D9  00
        NOP                              ; $08DA  00
        NOP                              ; $08DB  00
        NOP                              ; $08DC  00
        NOP                              ; $08DD  00
        NOP                              ; $08DE  00
        NOP                              ; $08DF  00
        NOP                              ; $08E0  00
        NOP                              ; $08E1  00
        NOP                              ; $08E2  00
        NOP                              ; $08E3  00
        NOP                              ; $08E4  00
        NOP                              ; $08E5  00
        NOP                              ; $08E6  00
        NOP                              ; $08E7  00
        NOP                              ; $08E8  00
        NOP                              ; $08E9  00
        NOP                              ; $08EA  00
        NOP                              ; $08EB  00
        NOP                              ; $08EC  00
        NOP                              ; $08ED  00
FILTAB_15:
        NOP                              ; $08EE  00
FILTAB_16:
        NOP                              ; $08EF  00
FILTAB_17:
        NOP                              ; $08F0  00
FILTAB_18:
        LD A,($0000)                     ; $08F1  3A 00 00
        NOP                              ; $08F4  00
        NOP                              ; $08F5  00
        NOP                              ; $08F6  00
        NOP                              ; $08F7  00
        NOP                              ; $08F8  00
        NOP                              ; $08F9  00
        NOP                              ; $08FA  00
        NOP                              ; $08FB  00
        NOP                              ; $08FC  00
        NOP                              ; $08FD  00
        NOP                              ; $08FE  00
        NOP                              ; $08FF  00
        NOP                              ; $0900  00
        NOP                              ; $0901  00
        NOP                              ; $0902  00
        NOP                              ; $0903  00
        NOP                              ; $0904  00
        NOP                              ; $0905  00
        NOP                              ; $0906  00
        NOP                              ; $0907  00
        NOP                              ; $0908  00
        NOP                              ; $0909  00
        NOP                              ; $090A  00
        NOP                              ; $090B  00
        NOP                              ; $090C  00
        NOP                              ; $090D  00
        NOP                              ; $090E  00
        NOP                              ; $090F  00
        NOP                              ; $0910  00
        NOP                              ; $0911  00
        NOP                              ; $0912  00
        NOP                              ; $0913  00
        NOP                              ; $0914  00
        NOP                              ; $0915  00
        NOP                              ; $0916  00
        NOP                              ; $0917  00
        NOP                              ; $0918  00
        NOP                              ; $0919  00
        NOP                              ; $091A  00
        NOP                              ; $091B  00
        NOP                              ; $091C  00
        NOP                              ; $091D  00
        NOP                              ; $091E  00
        NOP                              ; $091F  00
        NOP                              ; $0920  00
        NOP                              ; $0921  00
        NOP                              ; $0922  00
        NOP                              ; $0923  00
        NOP                              ; $0924  00
        NOP                              ; $0925  00
        NOP                              ; $0926  00
        NOP                              ; $0927  00
        NOP                              ; $0928  00
        NOP                              ; $0929  00
        NOP                              ; $092A  00
        NOP                              ; $092B  00
        NOP                              ; $092C  00
        NOP                              ; $092D  00
        NOP                              ; $092E  00
        NOP                              ; $092F  00
        NOP                              ; $0930  00
        NOP                              ; $0931  00
        NOP                              ; $0932  00
        NOP                              ; $0933  00
        NOP                              ; $0934  00
        NOP                              ; $0935  00
        NOP                              ; $0936  00
        NOP                              ; $0937  00
        NOP                              ; $0938  00
        NOP                              ; $0939  00
        NOP                              ; $093A  00
        NOP                              ; $093B  00
        NOP                              ; $093C  00
        NOP                              ; $093D  00
        NOP                              ; $093E  00
        NOP                              ; $093F  00
        NOP                              ; $0940  00
        NOP                              ; $0941  00
        NOP                              ; $0942  00
        NOP                              ; $0943  00
        NOP                              ; $0944  00
        NOP                              ; $0945  00
        NOP                              ; $0946  00
        NOP                              ; $0947  00
        NOP                              ; $0948  00
        NOP                              ; $0949  00
        NOP                              ; $094A  00
        NOP                              ; $094B  00
        NOP                              ; $094C  00
        NOP                              ; $094D  00
        NOP                              ; $094E  00
        NOP                              ; $094F  00
        NOP                              ; $0950  00
        NOP                              ; $0951  00
        NOP                              ; $0952  00
        NOP                              ; $0953  00
        NOP                              ; $0954  00
        NOP                              ; $0955  00
        NOP                              ; $0956  00
        NOP                              ; $0957  00
        NOP                              ; $0958  00
        NOP                              ; $0959  00
        NOP                              ; $095A  00
        NOP                              ; $095B  00
        NOP                              ; $095C  00
        NOP                              ; $095D  00
        NOP                              ; $095E  00
        NOP                              ; $095F  00
        NOP                              ; $0960  00
        NOP                              ; $0961  00
        NOP                              ; $0962  00
        NOP                              ; $0963  00
        NOP                              ; $0964  00
        NOP                              ; $0965  00
        NOP                              ; $0966  00
        NOP                              ; $0967  00
        NOP                              ; $0968  00
        NOP                              ; $0969  00
        NOP                              ; $096A  00
        NOP                              ; $096B  00
        NOP                              ; $096C  00
        NOP                              ; $096D  00
        NOP                              ; $096E  00
        NOP                              ; $096F  00
        NOP                              ; $0970  00
        NOP                              ; $0971  00
        NOP                              ; $0972  00
        NOP                              ; $0973  00
        NOP                              ; $0974  00
        NOP                              ; $0975  00
        NOP                              ; $0976  00
        NOP                              ; $0977  00
        NOP                              ; $0978  00
        NOP                              ; $0979  00
        NOP                              ; $097A  00
        NOP                              ; $097B  00
        NOP                              ; $097C  00
        NOP                              ; $097D  00
        NOP                              ; $097E  00
        NOP                              ; $097F  00
        NOP                              ; $0980  00
        NOP                              ; $0981  00
        NOP                              ; $0982  00
        NOP                              ; $0983  00
        NOP                              ; $0984  00
        NOP                              ; $0985  00
        NOP                              ; $0986  00
        NOP                              ; $0987  00
        NOP                              ; $0988  00
        NOP                              ; $0989  00
        NOP                              ; $098A  00
        NOP                              ; $098B  00
        NOP                              ; $098C  00
        NOP                              ; $098D  00
        NOP                              ; $098E  00
        NOP                              ; $098F  00
        NOP                              ; $0990  00
        NOP                              ; $0991  00
        NOP                              ; $0992  00
        NOP                              ; $0993  00
        NOP                              ; $0994  00
        NOP                              ; $0995  00
        NOP                              ; $0996  00
        NOP                              ; $0997  00
        NOP                              ; $0998  00
        NOP                              ; $0999  00
        NOP                              ; $099A  00
        NOP                              ; $099B  00
        NOP                              ; $099C  00
        NOP                              ; $099D  00
        NOP                              ; $099E  00
        NOP                              ; $099F  00
        NOP                              ; $09A0  00
        NOP                              ; $09A1  00
        NOP                              ; $09A2  00
        NOP                              ; $09A3  00
        NOP                              ; $09A4  00
        NOP                              ; $09A5  00
        NOP                              ; $09A6  00
        NOP                              ; $09A7  00
        NOP                              ; $09A8  00
        NOP                              ; $09A9  00
        NOP                              ; $09AA  00
        NOP                              ; $09AB  00
        NOP                              ; $09AC  00
        NOP                              ; $09AD  00
        NOP                              ; $09AE  00
        NOP                              ; $09AF  00
        NOP                              ; $09B0  00
        NOP                              ; $09B1  00
        NOP                              ; $09B2  00
        NOP                              ; $09B3  00
        NOP                              ; $09B4  00
        NOP                              ; $09B5  00
        NOP                              ; $09B6  00
        NOP                              ; $09B7  00
        NOP                              ; $09B8  00
        NOP                              ; $09B9  00
        NOP                              ; $09BA  00
        NOP                              ; $09BB  00
        NOP                              ; $09BC  00
        NOP                              ; $09BD  00
        NOP                              ; $09BE  00
        NOP                              ; $09BF  00
        NOP                              ; $09C0  00
        NOP                              ; $09C1  00
        NOP                              ; $09C2  00
        NOP                              ; $09C3  00
        NOP                              ; $09C4  00
        NOP                              ; $09C5  00
        NOP                              ; $09C6  00
        NOP                              ; $09C7  00
        NOP                              ; $09C8  00
        NOP                              ; $09C9  00
        NOP                              ; $09CA  00
        NOP                              ; $09CB  00
        NOP                              ; $09CC  00
        NOP                              ; $09CD  00
        NOP                              ; $09CE  00
        NOP                              ; $09CF  00
        NOP                              ; $09D0  00
        NOP                              ; $09D1  00
        NOP                              ; $09D2  00
        NOP                              ; $09D3  00
        NOP                              ; $09D4  00
        NOP                              ; $09D5  00
        NOP                              ; $09D6  00
        NOP                              ; $09D7  00
        NOP                              ; $09D8  00
        NOP                              ; $09D9  00
        NOP                              ; $09DA  00
        NOP                              ; $09DB  00
        NOP                              ; $09DC  00
        NOP                              ; $09DD  00
        NOP                              ; $09DE  00
        NOP                              ; $09DF  00
        NOP                              ; $09E0  00
        NOP                              ; $09E1  00
        NOP                              ; $09E2  00
        NOP                              ; $09E3  00
        NOP                              ; $09E4  00
        NOP                              ; $09E5  00
        NOP                              ; $09E6  00
        NOP                              ; $09E7  00
        NOP                              ; $09E8  00
        NOP                              ; $09E9  00
        NOP                              ; $09EA  00
        NOP                              ; $09EB  00
        NOP                              ; $09EC  00
        NOP                              ; $09ED  00
        NOP                              ; $09EE  00
        NOP                              ; $09EF  00
        NOP                              ; $09F0  00
        NOP                              ; $09F1  00
        NOP                              ; $09F2  00
        NOP                              ; $09F3  00
        NOP                              ; $09F4  00
        NOP                              ; $09F5  00
        NOP                              ; $09F6  00
        NOP                              ; $09F7  00
        NOP                              ; $09F8  00
        NOP                              ; $09F9  00
        NOP                              ; $09FA  00
        NOP                              ; $09FB  00
        NOP                              ; $09FC  00
        NOP                              ; $09FD  00
        NOP                              ; $09FE  00
        NOP                              ; $09FF  00
        NOP                              ; $0A00  00
        NOP                              ; $0A01  00
        NOP                              ; $0A02  00
        NOP                              ; $0A03  00
        NOP                              ; $0A04  00
        NOP                              ; $0A05  00
        NOP                              ; $0A06  00
        NOP                              ; $0A07  00
        NOP                              ; $0A08  00
        NOP                              ; $0A09  00
        NOP                              ; $0A0A  00
        NOP                              ; $0A0B  00
        NOP                              ; $0A0C  00
        NOP                              ; $0A0D  00
        NOP                              ; $0A0E  00
        NOP                              ; $0A0F  00
        NOP                              ; $0A10  00
        NOP                              ; $0A11  00
        NOP                              ; $0A12  00
        NOP                              ; $0A13  00
        NOP                              ; $0A14  00
        NOP                              ; $0A15  00
        NOP                              ; $0A16  00
        NOP                              ; $0A17  00
        NOP                              ; $0A18  00
        NOP                              ; $0A19  00
        NOP                              ; $0A1A  00
        NOP                              ; $0A1B  00
        NOP                              ; $0A1C  00
        NOP                              ; $0A1D  00
SUB_0925_1:
        NOP                              ; $0A1E  00
        NOP                              ; $0A1F  00
        NOP                              ; $0A20  00
        NOP                              ; $0A21  00
        NOP                              ; $0A22  00
        NOP                              ; $0A23  00
        NOP                              ; $0A24  00
        NOP                              ; $0A25  00
        NOP                              ; $0A26  00
        NOP                              ; $0A27  00
        NOP                              ; $0A28  00
        NOP                              ; $0A29  00
        NOP                              ; $0A2A  00
        NOP                              ; $0A2B  00
        NOP                              ; $0A2C  00
        NOP                              ; $0A2D  00
        NOP                              ; $0A2E  00
        NOP                              ; $0A2F  00
SUB_0925_2:
        INC L                            ; $0A30  2C
; Console line-input buffer (MS BASIC BUF): INLIN reads/echoes the edited input line here; Ctrl-U/Ctrl-R reset the pointer to $0A0E. Buffer body continues through $0A1E.
BUF:
        NOP                              ; $0A31  00
        NOP                              ; $0A32  00
        NOP                              ; $0A33  00
        NOP                              ; $0A34  00
        NOP                              ; $0A35  00
        NOP                              ; $0A36  00
        NOP                              ; $0A37  00
        NOP                              ; $0A38  00
        NOP                              ; $0A39  00
        NOP                              ; $0A3A  00
        NOP                              ; $0A3B  00
        NOP                              ; $0A3C  00
        NOP                              ; $0A3D  00
        NOP                              ; $0A3E  00
        NOP                              ; $0A3F  00
        NOP                              ; $0A40  00
        NOP                              ; $0A41  00
        NOP                              ; $0A42  00
        NOP                              ; $0A43  00
        NOP                              ; $0A44  00
        NOP                              ; $0A45  00
        NOP                              ; $0A46  00
        NOP                              ; $0A47  00
        NOP                              ; $0A48  00
        NOP                              ; $0A49  00
        NOP                              ; $0A4A  00
        NOP                              ; $0A4B  00
        NOP                              ; $0A4C  00
        NOP                              ; $0A4D  00
        NOP                              ; $0A4E  00
        NOP                              ; $0A4F  00
        NOP                              ; $0A50  00
        NOP                              ; $0A51  00
        NOP                              ; $0A52  00
        NOP                              ; $0A53  00
        NOP                              ; $0A54  00
        NOP                              ; $0A55  00
        NOP                              ; $0A56  00
        NOP                              ; $0A57  00
        NOP                              ; $0A58  00
        NOP                              ; $0A59  00
        NOP                              ; $0A5A  00
        NOP                              ; $0A5B  00
        NOP                              ; $0A5C  00
        NOP                              ; $0A5D  00
        NOP                              ; $0A5E  00
        NOP                              ; $0A5F  00
        NOP                              ; $0A60  00
        NOP                              ; $0A61  00
        NOP                              ; $0A62  00
        NOP                              ; $0A63  00
        NOP                              ; $0A64  00
        NOP                              ; $0A65  00
        NOP                              ; $0A66  00
        NOP                              ; $0A67  00
        NOP                              ; $0A68  00
        NOP                              ; $0A69  00
        NOP                              ; $0A6A  00
        NOP                              ; $0A6B  00
        NOP                              ; $0A6C  00
        NOP                              ; $0A6D  00
        NOP                              ; $0A6E  00
        NOP                              ; $0A6F  00
        NOP                              ; $0A70  00
        NOP                              ; $0A71  00
        NOP                              ; $0A72  00
        NOP                              ; $0A73  00
        NOP                              ; $0A74  00
        NOP                              ; $0A75  00
        NOP                              ; $0A76  00
        NOP                              ; $0A77  00
        NOP                              ; $0A78  00
        NOP                              ; $0A79  00
        NOP                              ; $0A7A  00
        NOP                              ; $0A7B  00
        NOP                              ; $0A7C  00
        NOP                              ; $0A7D  00
        NOP                              ; $0A7E  00
        NOP                              ; $0A7F  00
        NOP                              ; $0A80  00
        NOP                              ; $0A81  00
        NOP                              ; $0A82  00
        NOP                              ; $0A83  00
        NOP                              ; $0A84  00
        NOP                              ; $0A85  00
        NOP                              ; $0A86  00
        NOP                              ; $0A87  00
        NOP                              ; $0A88  00
        NOP                              ; $0A89  00
        NOP                              ; $0A8A  00
        NOP                              ; $0A8B  00
        NOP                              ; $0A8C  00
        NOP                              ; $0A8D  00
        NOP                              ; $0A8E  00
        NOP                              ; $0A8F  00
        NOP                              ; $0A90  00
        NOP                              ; $0A91  00
        NOP                              ; $0A92  00
        NOP                              ; $0A93  00
        NOP                              ; $0A94  00
        NOP                              ; $0A95  00
        NOP                              ; $0A96  00
        NOP                              ; $0A97  00
BUF_1:
        NOP                              ; $0A98  00
BUF_2:
        NOP                              ; $0A99  00
        NOP                              ; $0A9A  00
        NOP                              ; $0A9B  00
        NOP                              ; $0A9C  00
        NOP                              ; $0A9D  00
        NOP                              ; $0A9E  00
        NOP                              ; $0A9F  00
        NOP                              ; $0AA0  00
        NOP                              ; $0AA1  00
        NOP                              ; $0AA2  00
        NOP                              ; $0AA3  00
        NOP                              ; $0AA4  00
        NOP                              ; $0AA5  00
        NOP                              ; $0AA6  00
        NOP                              ; $0AA7  00
        NOP                              ; $0AA8  00
        NOP                              ; $0AA9  00
        NOP                              ; $0AAA  00
        NOP                              ; $0AAB  00
        NOP                              ; $0AAC  00
        NOP                              ; $0AAD  00
        NOP                              ; $0AAE  00
        NOP                              ; $0AAF  00
        NOP                              ; $0AB0  00
        NOP                              ; $0AB1  00
        NOP                              ; $0AB2  00
        NOP                              ; $0AB3  00
        NOP                              ; $0AB4  00
        NOP                              ; $0AB5  00
        NOP                              ; $0AB6  00
        NOP                              ; $0AB7  00
        NOP                              ; $0AB8  00
        NOP                              ; $0AB9  00
        NOP                              ; $0ABA  00
        NOP                              ; $0ABB  00
        NOP                              ; $0ABC  00
        NOP                              ; $0ABD  00
        NOP                              ; $0ABE  00
        NOP                              ; $0ABF  00
        NOP                              ; $0AC0  00
        NOP                              ; $0AC1  00
        NOP                              ; $0AC2  00
        NOP                              ; $0AC3  00
        NOP                              ; $0AC4  00
        NOP                              ; $0AC5  00
        NOP                              ; $0AC6  00
        NOP                              ; $0AC7  00
        NOP                              ; $0AC8  00
        NOP                              ; $0AC9  00
        NOP                              ; $0ACA  00
        NOP                              ; $0ACB  00
        NOP                              ; $0ACC  00
        NOP                              ; $0ACD  00
        NOP                              ; $0ACE  00
        NOP                              ; $0ACF  00
        NOP                              ; $0AD0  00
        NOP                              ; $0AD1  00
        NOP                              ; $0AD2  00
        NOP                              ; $0AD3  00
        NOP                              ; $0AD4  00
        NOP                              ; $0AD5  00
        NOP                              ; $0AD6  00
        NOP                              ; $0AD7  00
        NOP                              ; $0AD8  00
        NOP                              ; $0AD9  00
        NOP                              ; $0ADA  00
        NOP                              ; $0ADB  00
        NOP                              ; $0ADC  00
        NOP                              ; $0ADD  00
        NOP                              ; $0ADE  00
        NOP                              ; $0ADF  00
        NOP                              ; $0AE0  00
        NOP                              ; $0AE1  00
        NOP                              ; $0AE2  00
        NOP                              ; $0AE3  00
        NOP                              ; $0AE4  00
        NOP                              ; $0AE5  00
        NOP                              ; $0AE6  00
        NOP                              ; $0AE7  00
        NOP                              ; $0AE8  00
        NOP                              ; $0AE9  00
        NOP                              ; $0AEA  00
        NOP                              ; $0AEB  00
        NOP                              ; $0AEC  00
        NOP                              ; $0AED  00
        NOP                              ; $0AEE  00
        NOP                              ; $0AEF  00
        NOP                              ; $0AF0  00
        NOP                              ; $0AF1  00
        NOP                              ; $0AF2  00
        NOP                              ; $0AF3  00
        NOP                              ; $0AF4  00
        NOP                              ; $0AF5  00
        NOP                              ; $0AF6  00
        NOP                              ; $0AF7  00
        NOP                              ; $0AF8  00
        NOP                              ; $0AF9  00
        NOP                              ; $0AFA  00
        NOP                              ; $0AFB  00
        NOP                              ; $0AFC  00
        NOP                              ; $0AFD  00
        NOP                              ; $0AFE  00
        NOP                              ; $0AFF  00
        NOP                              ; $0B00  00
        NOP                              ; $0B01  00
        NOP                              ; $0B02  00
        NOP                              ; $0B03  00
        NOP                              ; $0B04  00
        NOP                              ; $0B05  00
        NOP                              ; $0B06  00
        NOP                              ; $0B07  00
        NOP                              ; $0B08  00
        NOP                              ; $0B09  00
        NOP                              ; $0B0A  00
        NOP                              ; $0B0B  00
        NOP                              ; $0B0C  00
        NOP                              ; $0B0D  00
        NOP                              ; $0B0E  00
        NOP                              ; $0B0F  00
        NOP                              ; $0B10  00
        NOP                              ; $0B11  00
        NOP                              ; $0B12  00
        NOP                              ; $0B13  00
        NOP                              ; $0B14  00
        NOP                              ; $0B15  00
        NOP                              ; $0B16  00
        NOP                              ; $0B17  00
        NOP                              ; $0B18  00
        NOP                              ; $0B19  00
        NOP                              ; $0B1A  00
        NOP                              ; $0B1B  00
        NOP                              ; $0B1C  00
        NOP                              ; $0B1D  00
BUF_3:
        NOP                              ; $0B1E  00
        NOP                              ; $0B1F  00
        NOP                              ; $0B20  00
        NOP                              ; $0B21  00
        NOP                              ; $0B22  00
        NOP                              ; $0B23  00
        NOP                              ; $0B24  00
        NOP                              ; $0B25  00
        NOP                              ; $0B26  00
        NOP                              ; $0B27  00
        NOP                              ; $0B28  00
        NOP                              ; $0B29  00
        NOP                              ; $0B2A  00
        NOP                              ; $0B2B  00
        NOP                              ; $0B2C  00
        NOP                              ; $0B2D  00
        NOP                              ; $0B2E  00
        NOP                              ; $0B2F  00
        NOP                              ; $0B30  00
        NOP                              ; $0B31  00
        NOP                              ; $0B32  00
SUB_0B2A_1:
        NOP                              ; $0B33  00
SUB_0B2A_2:
        NOP                              ; $0B34  00
SUB_0B2A_3:
        NOP                              ; $0B35  00
SUB_0B2A_4:
        NOP                              ; $0B36  00
SUB_0B2A_5:
        NOP                              ; $0B37  00
SUB_0B2A_6:
        NOP                              ; $0B38  00
SUB_0B2A_7:
        NOP                              ; $0B39  00
SUB_0B2A_8:
        NOP                              ; $0B3A  00
        NOP                              ; $0B3B  00
SUB_0B2A_9:
        NOP                              ; $0B3C  00
SUB_0B2A_10:
        NOP                              ; $0B3D  00
SUB_0B2A_11:
        NOP                              ; $0B3E  00
        NOP                              ; $0B3F  00
SUB_0B2A_12:
        NOP                              ; $0B40  00
        NOP                              ; $0B41  00
        NOP                              ; $0B42  00
        NOP                              ; $0B43  00
        NOP                              ; $0B44  00
        NOP                              ; $0B45  00
; Top-of-storage / highest usable RAM pointer (MS BASIC MEMSIZ): cold-start sets it below the stack; GETSTK checks SP vs MEMSIZ; the string heap top ($0B48) seeds from it. Read by GARBAG.
MEMSIZ:
        NOP                              ; $0B46  00
        NOP                              ; $0B47  00
MEMSIZ_1:
        NOP                              ; $0B48  00
        NOP                              ; $0B49  00
MEMSIZ_2:
        NOP                              ; $0B4A  00
        NOP                              ; $0B4B  00
        NOP                              ; $0B4C  00
        NOP                              ; $0B4D  00
        NOP                              ; $0B4E  00
        NOP                              ; $0B4F  00
        NOP                              ; $0B50  00
        NOP                              ; $0B51  00
        NOP                              ; $0B52  00
        NOP                              ; $0B53  00
        NOP                              ; $0B54  00
        NOP                              ; $0B55  00
        NOP                              ; $0B56  00
        NOP                              ; $0B57  00
        NOP                              ; $0B58  00
MEMSIZ_3:
        NOP                              ; $0B59  00
        NOP                              ; $0B5A  00
        NOP                              ; $0B5B  00
        NOP                              ; $0B5C  00
        NOP                              ; $0B5D  00
        NOP                              ; $0B5E  00
        NOP                              ; $0B5F  00
        NOP                              ; $0B60  00
        NOP                              ; $0B61  00
        NOP                              ; $0B62  00
        NOP                              ; $0B63  00
        NOP                              ; $0B64  00
        NOP                              ; $0B65  00
        NOP                              ; $0B66  00
        NOP                              ; $0B67  00
MEMSIZ_4:
        NOP                              ; $0B68  00
MEMSIZ_5:
        NOP                              ; $0B69  00
        NOP                              ; $0B6A  00
; [RE] Top-of-free-string-space pointer (MS BASIC FRETOP): the string heap allocates downward from here; GETSPA decrements it, FRESTR1 hands back the topmost string, GARBAG slides live strings up to it. Seeded from MEMSIZ at cold-start/CLEAR.
FRETOP:
        NOP                              ; $0B6B  00
        NOP                              ; $0B6C  00
FRETOP_1:
        NOP                              ; $0B6D  00
        NOP                              ; $0B6E  00
FRETOP_2:
        NOP                              ; $0B6F  00
        NOP                              ; $0B70  00
FRETOP_3:
        NOP                              ; $0B71  00
        NOP                              ; $0B72  00
; [RE] Saved text pointer of the current DATA line during a READ ($3A5C stores the located DATA line ptr). On a READ-time parse error STMT_LINE_1 restores it into SAVTXT ($0D69 -> $0844) so '? ... in <line>' reports against the DATA line, not the READ line.
DATA_LINE_TXTPTR:
        NOP                              ; $0B73  00
        NOP                              ; $0B74  00
DATA_LINE_TXTPTR_1:
        NOP                              ; $0B75  00
DATA_LINE_TXTPTR_2:
        NOP                              ; $0B76  00
DATA_LINE_TXTPTR_3:
        NOP                              ; $0B77  00
        NOP                              ; $0B78  00
DATA_LINE_TXTPTR_4:
        NOP                              ; $0B79  00
; [RE] AUTO line-numbering mode flag: AUTO sets it nonzero ($36F9) with start/increment in $0B58/$0B5A; the READY/line dispatcher checks it to auto-generate the next line-number prompt and clears it on completion/overflow; CLEAR_VARS zeroes it.
AUTFLG:
        NOP                              ; $0B7A  00
; [RE] AUTO current/next line number: set by the AUTO command ($36FD) and advanced by $0B5A each input; the line dispatcher uses it to prompt/insert the next auto-numbered line.
AUTLIN:
        NOP                              ; $0B7B  00
        NOP                              ; $0B7C  00
; [RE] AUTO line-number increment (default $000A): set by the AUTO command ($36F6) and added to AUTLIN ($0B58) by the line dispatcher to form the next auto line number.
AUTINC:
        NOP                              ; $0B7D  00
        NOP                              ; $0B7E  00
; [RE] Saved text pointer of the current statement (MS BASIC OLDTXT): NEWSTT records it each statement ($3374); STOP/END copies it to the CONT save ($0B6D at $6979); error/'Redo from start' restores from it.
OLDTXT:
        NOP                              ; $0B7F  00
        NOP                              ; $0B80  00
; [RE] Saved stack pointer (MS BASIC SAVSTK): written via LD ($0B5E),SP at NEWSTT ($3377) and cold-start; restored to SP on error-recovery / FOR-stack unwinding (e.g. STMT_CALL_6 $72AF) to discard pending expression frames.
SAVSTK:
        NOP                              ; $0B81  00
        NOP                              ; $0B82  00
; [RE] Error-handler saved text pointer: RAISE_ERROR stores SAVTXT ($0844) here ($0D8C); the message printer reads it ($0DFC/$0E00) to decide direct vs '? ... in <line>'; RESUME reloads it into SAVTXT ($36B5).
ERR_SAVTXT:
        NOP                              ; $0B83  00
        NOP                              ; $0B84  00
; [RE] Saved program line of the last error (MS BASIC ERRLIN): RAISE_ERROR records the offending line ($0D9B) for ERR/ERL reporting; LINGET '.' shortcut substitutes it as the current line number ($34D9).
ERRLIN:
        NOP                              ; $0B85  00
        NOP                              ; $0B86  00
ERRLIN_1:
        NOP                              ; $0B87  00
        NOP                              ; $0B88  00
ERRLIN_2:
        NOP                              ; $0B89  00
        NOP                              ; $0B8A  00
; [RE] ON-ERROR trap-active flag (MS BASIC ONEFLG): nonzero while inside an error handler. Gates ON-ERROR dispatch and RESUME, and is tested by PROGRAM_END so a handler that runs off the end of the program raises 'No RESUME' (ERR_NO_RESUME); cleared by CLEAR.
ONEFLG:
        NOP                              ; $0B8B  00
; [RE] FRMEVL operand text-pointer scratch (general TEMP): the precedence loop saves/reloads the current (HL) here ($3A85/$3A88) across operator recursion. The same cell is reused by FOUT to record the decimal-point buffer position during numeric formatting.
FRMEVL_TXTPTR_TEMP:
        NOP                              ; $0B8C  00
        NOP                              ; $0B8D  00
FRMEVL_TXTPTR_TEMP_1:
        NOP                              ; $0B8E  00
        NOP                              ; $0B8F  00
FRMEVL_TXTPTR_TEMP_2:
        NOP                              ; $0B90  00
        NOP                              ; $0B91  00
; [RE] Start of variable + free space (MS BASIC VARTAB/STREND-grow pointer): base of the simple-variable table walked by PTRGET/CHAIN; the string-relocation copy grows the pool here; CLEAR re-points it just above program text. ,P-protected DECODE ends at $0B6F.
VARTAB:
        NOP                              ; $0B92  00
        NOP                              ; $0B93  00
VARTAB_1:
        NOP                              ; $0B94  00
        NOP                              ; $0B95  00
VARTAB_2:
        NOP                              ; $0B96  00
        NOP                              ; $0B97  00
VARTAB_3:
        NOP                              ; $0B98  00
        NOP                              ; $0B99  00
VARTAB_4:
        NOP                              ; $0B9A  00
        NOP                              ; $0B9B  00
        NOP                              ; $0B9C  00
        NOP                              ; $0B9D  00
        NOP                              ; $0B9E  00
        NOP                              ; $0B9F  00
        NOP                              ; $0BA0  00
        NOP                              ; $0BA1  00
        NOP                              ; $0BA2  00
        NOP                              ; $0BA3  00
        NOP                              ; $0BA4  00
        NOP                              ; $0BA5  00
        NOP                              ; $0BA6  00
        NOP                              ; $0BA7  00
        NOP                              ; $0BA8  00
        NOP                              ; $0BA9  00
        NOP                              ; $0BAA  00
        NOP                              ; $0BAB  00
        NOP                              ; $0BAC  00
        NOP                              ; $0BAD  00
        NOP                              ; $0BAE  00
        NOP                              ; $0BAF  00
        NOP                              ; $0BB0  00
        NOP                              ; $0BB1  00
        NOP                              ; $0BB2  00
        NOP                              ; $0BB3  00
VARTAB_5:
        NOP                              ; $0BB4  00
        NOP                              ; $0BB5  00
VARTAB_6:
        NOP                              ; $0BB6  00
        NOP                              ; $0BB7  00
VARTAB_7:
        NOP                              ; $0BB8  00
        NOP                              ; $0BB9  00
        NOP                              ; $0BBA  00
        NOP                              ; $0BBB  00
        NOP                              ; $0BBC  00
        NOP                              ; $0BBD  00
        NOP                              ; $0BBE  00
        NOP                              ; $0BBF  00
        NOP                              ; $0BC0  00
        NOP                              ; $0BC1  00
        NOP                              ; $0BC2  00
        NOP                              ; $0BC3  00
        NOP                              ; $0BC4  00
        NOP                              ; $0BC5  00
        NOP                              ; $0BC6  00
        NOP                              ; $0BC7  00
        NOP                              ; $0BC8  00
        NOP                              ; $0BC9  00
        NOP                              ; $0BCA  00
        NOP                              ; $0BCB  00
        NOP                              ; $0BCC  00
        NOP                              ; $0BCD  00
        NOP                              ; $0BCE  00
        NOP                              ; $0BCF  00
        NOP                              ; $0BD0  00
        NOP                              ; $0BD1  00
        NOP                              ; $0BD2  00
        NOP                              ; $0BD3  00
        NOP                              ; $0BD4  00
        NOP                              ; $0BD5  00
        NOP                              ; $0BD6  00
        NOP                              ; $0BD7  00
        NOP                              ; $0BD8  00
        NOP                              ; $0BD9  00
        NOP                              ; $0BDA  00
        NOP                              ; $0BDB  00
        NOP                              ; $0BDC  00
        NOP                              ; $0BDD  00
        NOP                              ; $0BDE  00
        NOP                              ; $0BDF  00
        NOP                              ; $0BE0  00
        NOP                              ; $0BE1  00
        NOP                              ; $0BE2  00
        NOP                              ; $0BE3  00
        NOP                              ; $0BE4  00
        NOP                              ; $0BE5  00
        NOP                              ; $0BE6  00
        NOP                              ; $0BE7  00
        NOP                              ; $0BE8  00
        NOP                              ; $0BE9  00
        NOP                              ; $0BEA  00
        NOP                              ; $0BEB  00
        NOP                              ; $0BEC  00
        NOP                              ; $0BED  00
        NOP                              ; $0BEE  00
        NOP                              ; $0BEF  00
        NOP                              ; $0BF0  00
        NOP                              ; $0BF1  00
        NOP                              ; $0BF2  00
        NOP                              ; $0BF3  00
        NOP                              ; $0BF4  00
        NOP                              ; $0BF5  00
        NOP                              ; $0BF6  00
        NOP                              ; $0BF7  00
        NOP                              ; $0BF8  00
        NOP                              ; $0BF9  00
        NOP                              ; $0BFA  00
        NOP                              ; $0BFB  00
        NOP                              ; $0BFC  00
        NOP                              ; $0BFD  00
        NOP                              ; $0BFE  00
        NOP                              ; $0BFF  00
        NOP                              ; $0C00  00
        NOP                              ; $0C01  00
        NOP                              ; $0C02  00
        NOP                              ; $0C03  00
        NOP                              ; $0C04  00
        NOP                              ; $0C05  00
        NOP                              ; $0C06  00
        NOP                              ; $0C07  00
        NOP                              ; $0C08  00
        NOP                              ; $0C09  00
        NOP                              ; $0C0A  00
        NOP                              ; $0C0B  00
        NOP                              ; $0C0C  00
        NOP                              ; $0C0D  00
        NOP                              ; $0C0E  00
        NOP                              ; $0C0F  00
        NOP                              ; $0C10  00
        NOP                              ; $0C11  00
        NOP                              ; $0C12  00
        NOP                              ; $0C13  00
        NOP                              ; $0C14  00
        NOP                              ; $0C15  00
        NOP                              ; $0C16  00
        NOP                              ; $0C17  00
        NOP                              ; $0C18  00
        NOP                              ; $0C19  00
        NOP                              ; $0C1A  00
        NOP                              ; $0C1B  00
SUB_0C03_1:
        OR H                             ; $0C1C  B4
        DEC BC                           ; $0C1D  0B
SUB_0C03_2:
        NOP                              ; $0C1E  00
        NOP                              ; $0C1F  00
SUB_0C03_3:
        NOP                              ; $0C20  00
        NOP                              ; $0C21  00
        NOP                              ; $0C22  00
        NOP                              ; $0C23  00
        NOP                              ; $0C24  00
        NOP                              ; $0C25  00
        NOP                              ; $0C26  00
        NOP                              ; $0C27  00
        NOP                              ; $0C28  00
        NOP                              ; $0C29  00
        NOP                              ; $0C2A  00
        NOP                              ; $0C2B  00
        NOP                              ; $0C2C  00
        NOP                              ; $0C2D  00
        NOP                              ; $0C2E  00
        NOP                              ; $0C2F  00
        NOP                              ; $0C30  00
        NOP                              ; $0C31  00
        NOP                              ; $0C32  00
        NOP                              ; $0C33  00
        NOP                              ; $0C34  00
        NOP                              ; $0C35  00
        NOP                              ; $0C36  00
        NOP                              ; $0C37  00
        NOP                              ; $0C38  00
        NOP                              ; $0C39  00
        NOP                              ; $0C3A  00
        NOP                              ; $0C3B  00
        NOP                              ; $0C3C  00
        NOP                              ; $0C3D  00
        NOP                              ; $0C3E  00
        NOP                              ; $0C3F  00
        NOP                              ; $0C40  00
        NOP                              ; $0C41  00
        NOP                              ; $0C42  00
        NOP                              ; $0C43  00
        NOP                              ; $0C44  00
        NOP                              ; $0C45  00
        NOP                              ; $0C46  00
        NOP                              ; $0C47  00
        NOP                              ; $0C48  00
        NOP                              ; $0C49  00
        NOP                              ; $0C4A  00
        NOP                              ; $0C4B  00
        NOP                              ; $0C4C  00
        NOP                              ; $0C4D  00
        NOP                              ; $0C4E  00
        NOP                              ; $0C4F  00
        NOP                              ; $0C50  00
        NOP                              ; $0C51  00
        NOP                              ; $0C52  00
        NOP                              ; $0C53  00
        NOP                              ; $0C54  00
        NOP                              ; $0C55  00
        NOP                              ; $0C56  00
        NOP                              ; $0C57  00
        NOP                              ; $0C58  00
        NOP                              ; $0C59  00
        NOP                              ; $0C5A  00
        NOP                              ; $0C5B  00
        NOP                              ; $0C5C  00
        NOP                              ; $0C5D  00
        NOP                              ; $0C5E  00
        NOP                              ; $0C5F  00
        NOP                              ; $0C60  00
        NOP                              ; $0C61  00
        NOP                              ; $0C62  00
        NOP                              ; $0C63  00
        NOP                              ; $0C64  00
        NOP                              ; $0C65  00
        NOP                              ; $0C66  00
        NOP                              ; $0C67  00
        NOP                              ; $0C68  00
        NOP                              ; $0C69  00
        NOP                              ; $0C6A  00
        NOP                              ; $0C6B  00
        NOP                              ; $0C6C  00
        NOP                              ; $0C6D  00
        NOP                              ; $0C6E  00
        NOP                              ; $0C6F  00
        NOP                              ; $0C70  00
        NOP                              ; $0C71  00
        NOP                              ; $0C72  00
        NOP                              ; $0C73  00
        NOP                              ; $0C74  00
        NOP                              ; $0C75  00
        NOP                              ; $0C76  00
        NOP                              ; $0C77  00
        NOP                              ; $0C78  00
        NOP                              ; $0C79  00
        NOP                              ; $0C7A  00
        NOP                              ; $0C7B  00
        NOP                              ; $0C7C  00
        NOP                              ; $0C7D  00
        NOP                              ; $0C7E  00
        NOP                              ; $0C7F  00
        NOP                              ; $0C80  00
        NOP                              ; $0C81  00
        NOP                              ; $0C82  00
        NOP                              ; $0C83  00
SUB_0C4B_1:
        NOP                              ; $0C84  00
SUB_0C4B_2:
        NOP                              ; $0C85  00
SUB_0C4B_3:
        NOP                              ; $0C86  00
SUB_0C4B_4:
        NOP                              ; $0C87  00
SUB_0C4B_5:
        NOP                              ; $0C88  00
        NOP                              ; $0C89  00
SUB_0C4B_6:
        NOP                              ; $0C8A  00
        NOP                              ; $0C8B  00
SUB_0C4B_7:
        NOP                              ; $0C8C  00
SUB_0C4B_8:
        NOP                              ; $0C8D  00
        NOP                              ; $0C8E  00
SUB_0C4B_9:
        NOP                              ; $0C8F  00
SUB_0C4B_10:
        NOP                              ; $0C90  00
        NOP                              ; $0C91  00
        NOP                              ; $0C92  00
        NOP                              ; $0C93  00
SUB_0C4B_11:
        NOP                              ; $0C94  00
        NOP                              ; $0C95  00
SUB_0C4B_12:
        NOP                              ; $0C96  00
SUB_0C4B_13:
        NOP                              ; $0C97  00
; [RE] In-RAM call trampoline: POP return addr into HL, restore AF/DE off the stack, JP (HL). Re-enters caller with saved A/flags and DE.
RAM_DISPATCH_TRAMPOLINE:
        POP HL                           ; $0C98  E1
        POP DE                           ; $0C99  D1
        POP AF                           ; $0C9A  F1
        PUSH AF                          ; $0C9B  F5
        PUSH DE                          ; $0C9C  D5
        JP (HL)                          ; $0C9D  E9
        NOP                              ; $0C9E  00
        NOP                              ; $0C9F  00
        NOP                              ; $0CA0  00
        NOP                              ; $0CA1  00
        NOP                              ; $0CA2  00
        NOP                              ; $0CA3  00
        NOP                              ; $0CA4  00
        NOP                              ; $0CA5  00
        NOP                              ; $0CA6  00
        NOP                              ; $0CA7  00
        NOP                              ; $0CA8  00
        NOP                              ; $0CA9  00
        NOP                              ; $0CAA  00
        NOP                              ; $0CAB  00
        NOP                              ; $0CAC  00
        NOP                              ; $0CAD  00
        NOP                              ; $0CAE  00
        NOP                              ; $0CAF  00
        NOP                              ; $0CB0  00
        NOP                              ; $0CB1  00
        NOP                              ; $0CB2  00
        NOP                              ; $0CB3  00
        NOP                              ; $0CB4  00
        NOP                              ; $0CB5  00
; Editor/LIST working flag (MBASIC equiv of GBASIC's $0C93; the low-RAM cells shift +$23 between the two builds). INPUT_PROMPT_SEP stores 0 or ';' here; INLIN_CR_FINISH tests it to choose auto-redisplay of a prefilled buffer vs normal line terminate; DETOKENIZE_LINE clears it as the inter-token spacing state. Was L_0CB6. [RE]
DETOKENIZE_SPACE_FLAG:
        NOP                              ; $0CB6  00
; INPUT '?'-prompt suppression flag (MBASIC equiv of GBASIC's $0C94, +$23 shift). INPUT_PROMPT sets $FF (emit '? '); a trailing ',' clears it to 0 to suppress the question mark. INPUT_EMIT_PROMPT tests it. Was L_0CB7. [RE]
INPUT_PROMPT_QMARK_FLAG:
        NOP                              ; $0CB7  00
; CHAIN string-compaction temp: CHAIN_COMPACT_STRINGS saves FRETOP (top-of-string) here ($5188) and restores it ($51D5) around the string-heap move that preserves COMMON variables. MBASIC equiv of GBASIC's $0C95 (+$23 shift). Was L_0CB8. [RE]
CHAIN_FRETOP_SAVE:
        NOP                              ; $0CB8  00
        NOP                              ; $0CB9  00
; Default file record length / random-record limit cell. COLD_SET_WIDTH inits it to $0080 (128, the CP/M record size); FILE_NUM_TO_FCB range-checks the requested record number against it ($5BC4) and file setup re-stores it ($5FC7/$5FF8). MBASIC equiv of GBASIC's open-file-table-limit cell $0C97 (+$23 shift); the stale '$0CBA' in the FP comments is a transferred GBASIC note (real FP ARG temp is $0CDD). Was L_0CBA. [RE]
FILE_RECLEN_DEFAULT:
        NOP                              ; $0CBA  00
        NOP                              ; $0CBB  00
; 'Running a stored program' / protected-program flag (MBASIC equiv of GBASIC's $0C99, +$23 shift). COLD_START and CLEAR_VARS clear it; ILLEGAL_DIRECT_CHECK ($5E2B) tests it (zero => Illegal direct error). LOAD/MERGE sets it to $FE (the SAVE,P protected marker) then triggers PROG_SCRAMBLE. Was L_0CBC. [RE]
RUNNING_PROG_FLAG:
        NOP                              ; $0CBC  00
; [RE] CHAIN/ON-ERROR 'preserve variables' flag: CHAIN-with-ALL and CHAIN set it ($72BA/$72C7) so the CLEAR storage reset skips clearing variable space ($6894 test); RAISE_ERROR clears it ($0D90); cold-start zeroes it.
CHAIN_PRESERVE_FLAG:
        NOP                              ; $0CBD  00
CHAIN_PRESERVE_FLAG_1:
        NOP                              ; $0CBE  00
CHAIN_PRESERVE_FLAG_2:
        NOP                              ; $0CBF  00
        NOP                              ; $0CC0  00
CHAIN_PRESERVE_FLAG_3:
        NOP                              ; $0CC1  00
        NOP                              ; $0CC2  00
; [RE] CHAIN-in-progress / break-pause flag: set to 1 during CHAIN string-var move ($752C) so the CLEAR reset preserves the string heap ($68CC test); also the Ctrl-C/list-pause flag polled by the auto-page LIST 'more' handler ($673B). Cleared by RAISE_ERROR and cold-start.
CHAIN_BREAK_FLAG:
        NOP                              ; $0CC3  00
CHAIN_BREAK_FLAG_1:
        NOP                              ; $0CC4  00
        NOP                              ; $0CC5  00
CHAIN_BREAK_FLAG_2:
        NOP                              ; $0CC6  00
        NOP                              ; $0CC7  00
        NOP                              ; $0CC8  00
        NOP                              ; $0CC9  00
        NOP                              ; $0CCA  00
        NOP                              ; $0CCB  00
        NOP                              ; $0CCC  00
CHAIN_BREAK_FLAG_3:
        NOP                              ; $0CCD  00
CHAIN_BREAK_FLAG_4:
        NOP                              ; $0CCE  00
CHAIN_BREAK_FLAG_5:
        NOP                              ; $0CCF  00
CHAIN_BREAK_FLAG_6:
        NOP                              ; $0CD0  00
        NOP                              ; $0CD1  00
CHAIN_BREAK_FLAG_7:
        NOP                              ; $0CD2  00
CHAIN_BREAK_FLAG_8:
        NOP                              ; $0CD3  00
CHAIN_BREAK_FLAG_9:
        NOP                              ; $0CD4  00
        NOP                              ; $0CD5  00
CHAIN_BREAK_FLAG_10:
        NOP                              ; $0CD6  00
CHAIN_BREAK_FLAG_11:
        NOP                              ; $0CD7  00
CHAIN_BREAK_FLAG_12:
        NOP                              ; $0CD8  00
CHAIN_BREAK_FLAG_13:
        NOP                              ; $0CD9  00
CHAIN_BREAK_FLAG_14:
        NOP                              ; $0CDA  00
CHAIN_BREAK_FLAG_15:
        NOP                              ; $0CDB  00
CHAIN_BREAK_FLAG_16:
        NOP                              ; $0CDC  00
CHAIN_BREAK_FLAG_17:
        NOP                              ; $0CDD  00
        NOP                              ; $0CDE  00
        NOP                              ; $0CDF  00
        NOP                              ; $0CE0  00
        NOP                              ; $0CE1  00
        NOP                              ; $0CE2  00
CHAIN_BREAK_FLAG_18:
        NOP                              ; $0CE3  00
CHAIN_BREAK_FLAG_19:
        NOP                              ; $0CE4  00
CHAIN_BREAK_FLAG_20:
        NOP                              ; $0CE5  00
CHAIN_BREAK_FLAG_21:
        NOP                              ; $0CE6  00
        NOP                              ; $0CE7  00
        NOP                              ; $0CE8  00
        NOP                              ; $0CE9  00
        NOP                              ; $0CEA  00
        NOP                              ; $0CEB  00
        NOP                              ; $0CEC  00
        NOP                              ; $0CED  00
        NOP                              ; $0CEE  00
        NOP                              ; $0CEF  00
CHAIN_BREAK_FLAG_22:
        NOP                              ; $0CF0  00
        NOP                              ; $0CF1  00
        NOP                              ; $0CF2  00
        NOP                              ; $0CF3  00
        NOP                              ; $0CF4  00
        NOP                              ; $0CF5  00
        NOP                              ; $0CF6  00
        NOP                              ; $0CF7  00
        NOP                              ; $0CF8  00
        NOP                              ; $0CF9  00
        NOP                              ; $0CFA  00
        NOP                              ; $0CFB  00
        NOP                              ; $0CFC  00
        NOP                              ; $0CFD  00
        NOP                              ; $0CFE  00
        NOP                              ; $0CFF  00
CHAIN_BREAK_FLAG_23:
        NOP                              ; $0D00  00
        NOP                              ; $0D01  00
        NOP                              ; $0D02  00
        NOP                              ; $0D03  00
        NOP                              ; $0D04  00
        NOP                              ; $0D05  00
SUB_0D04_1:
        NOP                              ; $0D06  00
SUB_0D04_2:
        NOP                              ; $0D07  00
        NOP                              ; $0D08  00
        NOP                              ; $0D09  00
        NOP                              ; $0D0A  00
SUB_0D04_3:
        NOP                              ; $0D0B  00
        NOP                              ; $0D0C  00
        NOP                              ; $0D0D  00
        NOP                              ; $0D0E  00
        NOP                              ; $0D0F  00
SUB_0D04_4:
        JR NZ,$0D7B                      ; $0D10  20 69
        LD L,(HL)                        ; $0D12  6E
SUB_0D04_5:
        JR NZ,MSG_BREAK                  ; $0D13  20 00
; Data: 'Break' message + CRLF used by the STOP/Ctrl-C path ($0E0B). $0CED ' in ' suffix, $0CF7 'Break'.
MSG_BREAK:
        LD C,A                           ; $0D15  4F
        LD L,E                           ; $0D16  6B
        DEC C                            ; $0D17  0D
        LD A,(BC)                        ; $0D18  0A
        NOP                              ; $0D19  00
MSG_BREAK_1:
        LD B,D                           ; $0D1A  42
        LD (HL),D                        ; $0D1B  72
        LD H,L                           ; $0D1C  65
        LD H,C                           ; $0D1D  61
MSG_BREAK_2:
        LD L,E                           ; $0D1E  6B
        NOP                              ; $0D1F  00
; [RE] Entry to FOR/GOSUB stack-frame fixup: HL = SP+4, fall into STKFRAME_SCAN to walk the runtime stack.
STKFRAME_SCAN_INIT:
        LD HL,$0004                      ; $0D20  21 04 00
        ADD HL,SP                        ; $0D23  39
; [RE] Walk runtime stack frames: skip FOR frames (token $AF, +16/+6 bytes), find GOSUB markers ($82), compare each frame's text pointer vs HL via FNDLIN-cmp ($691F) to fix up frames after a program edit/delete.
STKFRAME_SCAN:
        LD A,(HL)                        ; $0D24  7E
        INC HL                           ; $0D25  23
        CP $AF                           ; $0D26  FE AF
        JR NZ,STKFRAME_SCAN_1            ; $0D28  20 06
        LD BC,$0006                      ; $0D2A  01 06 00
        ADD HL,BC                        ; $0D2D  09
        JR STKFRAME_SCAN                 ; $0D2E  18 F4
STKFRAME_SCAN_1:
        CP $82                           ; $0D30  FE 82
        RET NZ                           ; $0D32  C0
        LD C,(HL)                        ; $0D33  4E
        INC HL                           ; $0D34  23
        LD B,(HL)                        ; $0D35  46
        INC HL                           ; $0D36  23
        PUSH HL                          ; $0D37  E5
        LD L,C                           ; $0D38  69
        LD H,B                           ; $0D39  60
        LD A,D                           ; $0D3A  7A
        OR E                             ; $0D3B  B3
        EX DE,HL                         ; $0D3C  EB
        JR Z,STKFRAME_SCAN_2             ; $0D3D  28 04
        EX DE,HL                         ; $0D3F  EB
        CALL CMP_HL_DE                   ; $0D40  CD 9D 45
STKFRAME_SCAN_2:
        LD BC,$0010                      ; $0D43  01 10 00
        POP HL                           ; $0D46  E1
        RET Z                            ; $0D47  C8
        ADD HL,BC                        ; $0D48  09
        JR STKFRAME_SCAN                 ; $0D49  18 D9
STKFRAME_SCAN_3:
        LD BC,STOP_BREAK_2+1             ; $0D4B  01 45 0E
        JP ERROR_PRINT_SETUP_1           ; $0D4E  C3 C4 0D
; [RE] PROGRAM_END: reached from NEWSTT (JP Z) when a line link is $0000 -- execution ran off the end of the program. If SAVTXT is $FFFF (direct mode), fall through to the ready/Ok-prompt return; otherwise, if an error handler is active (ONEFLG set) it ran off the end without RESUME, so raise 'No RESUME' (ERR_NO_RESUME). The CONT command and its 'Can't continue' error live in STMT_CONT, not here.
PROGRAM_END:
        LD HL,(SAVTXT)                   ; $0D51  2A 67 08
        LD A,H                           ; $0D54  7C
        AND L                            ; $0D55  A5
        INC A                            ; $0D56  3C
        JR Z,PROGRAM_END_1               ; $0D57  28 08
        LD A,(ONEFLG)                    ; $0D59  3A 8B 0B
        OR A                             ; $0D5C  B7
        LD E,ERR_NO_RESUME               ; $0D5D  1E 13
        JR NZ,RAISE_ERROR                ; $0D5F  20 4B
PROGRAM_END_1:
        JP STMT_END_3                    ; $0D61  C3 E7 45
; Named-error entry stubs: each loads an error code into E (LD E,ERR_* via the $1E opcode of the next LD BC) then falls through to RAISE_ERROR. Overlapping table of error vectors -- code JPs to a specific entry to raise that error.
RAISE_DISK_FULL:
        LD E,ERR_DISK_FULL               ; $0D64  raise error 61
        DEFB    $01                      ; $0D66  LD BC opcode = skip the next LD E
RAISE_DISK_I_O_ERROR:
        LD E,ERR_DISK_I_O_ERROR          ; $0D67  raise error 57
        DEFB    $01                      ; $0D69  LD BC opcode = skip the next LD E
RAISE_BAD_FILE_MODE:
        LD E,ERR_BAD_FILE_MODE           ; $0D6A  raise error 54
        DEFB    $01                      ; $0D6C  LD BC opcode = skip the next LD E
RAISE_FILE_NOT_FOUND:
        LD E,ERR_FILE_NOT_FOUND          ; $0D6D  raise error 53
        DEFB    $01                      ; $0D6F  LD BC opcode = skip the next LD E
RAISE_BAD_FILE_NUMBER:
        LD E,ERR_BAD_FILE_NUMBER         ; $0D70  raise error 52
        DEFB    $01                      ; $0D72  LD BC opcode = skip the next LD E
RAISE_INTERNAL_ERROR:
        LD E,ERR_INTERNAL_ERROR          ; $0D73  raise error 51
        DEFB    $01                      ; $0D75  LD BC opcode = skip the next LD E
RAISE_INPUT_PAST_END:
        LD E,ERR_INPUT_PAST_END          ; $0D76  raise error 62
        DEFB    $01                      ; $0D78  LD BC opcode = skip the next LD E
RAISE_FILE_ALREADY_OPEN:
        LD E,ERR_FILE_ALREADY_OPEN       ; $0D79  raise error 55
        DEFB    $01                      ; $0D7B  LD BC opcode = skip the next LD E
RAISE_BAD_FILE_NAME:
        LD E,ERR_BAD_FILE_NAME           ; $0D7C  raise error 64
        DEFB    $01                      ; $0D7E  LD BC opcode = skip the next LD E
RAISE_BAD_RECORD_NUMBER:
        LD E,ERR_BAD_RECORD_NUMBER       ; $0D7F  raise error 63
        DEFB    $01                      ; $0D81  LD BC opcode = skip the next LD E
RAISE_FIELD_OVERFLOW:
        LD E,ERR_FIELD_OVERFLOW          ; $0D82  raise error 50
        DEFB    $01                      ; $0D84  LD BC opcode = skip the next LD E
RAISE_TOO_MANY_FILES:
        LD E,ERR_TOO_MANY_FILES          ; $0D85  raise error 67
        DEFB    $01                      ; $0D87  LD BC opcode = skip the next LD E
RAISE_FILE_ALREADY_EXISTS:
        LD E,ERR_FILE_ALREADY_EXISTS     ; $0D88  raise error 58
        JR RAISE_ERROR                   ; $0D8A  18 20
; [RE] Restore saved program pointer ($0B50 -> $0844) on the no-continue path before re-entering the error/ready flow.
CONT_RESUME_RESTORE:
        LD HL,(DATA_LINE_TXTPTR)         ; $0D8C  2A 73 0B
        LD (SAVTXT),HL                   ; $0D8F  22 67 08
; Syntax-error entry: LD E,ERR_SYNTAX_ERROR then fall through the coded-error table into RAISE_ERROR. Common target of statement parsers (JP RAISE_SYNTAX_ERROR).
RAISE_SYNTAX_ERROR:
        LD E,ERR_SYNTAX_ERROR            ; $0D92  raise error 2
        DEFB    $01                      ; $0D94  LD BC opcode = skip the next LD E
RAISE_DIVISION_BY_ZERO:
        LD E,ERR_DIVISION_BY_ZERO        ; $0D95  raise error 11
        DEFB    $01                      ; $0D97  LD BC opcode = skip the next LD E
RAISE_NEXT_WITHOUT_FOR:
        LD E,ERR_NEXT_WITHOUT_FOR        ; $0D98  raise error 1
        DEFB    $01                      ; $0D9A  LD BC opcode = skip the next LD E
RAISE_DUPLICATE_DEFINITION:
        LD E,ERR_DUPLICATE_DEFINITION    ; $0D9B  raise error 10
        DEFB    $01                      ; $0D9D  LD BC opcode = skip the next LD E
RAISE_UNDEFINED_USER_FUNCTION:
        LD E,ERR_UNDEFINED_USER_FUNCTION ; $0D9E  raise error 18
        DEFB    $01                      ; $0DA0  LD BC opcode = skip the next LD E
RAISE_RESUME_WITHOUT_ERROR:
        LD E,ERR_RESUME_WITHOUT_ERROR    ; $0DA1  raise error 20
        DEFB    $01                      ; $0DA3  LD BC opcode = skip the next LD E
RAISE_OVERFLOW:
        LD E,ERR_OVERFLOW                ; $0DA4  raise error 6
        DEFB    $01                      ; $0DA6  LD BC opcode = skip the next LD E
RAISE_MISSING_OPERAND:
        LD E,ERR_MISSING_OPERAND         ; $0DA7  raise error 22
        DEFB    $01                      ; $0DA9  LD BC opcode = skip the next LD E
RAISE_TYPE_MISMATCH:
        LD E,ERR_TYPE_MISMATCH           ; $0DAA  raise error 13
; [RE] Raise/report error #E (entered with the error code in E). Saves the current text pointer (SAVTXT) to ERR_SAVTXT, clears the ON-ERROR/CHAIN flags (CHAIN_PRESERVE_FLAG / CHAIN_BREAK_FLAG), records the offending line in ERRLIN, then either dispatches to the ON ERROR handler or prints '?<message> Error[ in <line>]' and returns to direct mode via RESET_RUN_STATE. The message is found by scanning E entries from ERROR_MESSAGE_TABLE; the error codes are the ERR_* equates.
RAISE_ERROR:
        LD HL,(SAVTXT)                   ; $0DAC  2A 67 08
        LD (ERR_SAVTXT),HL               ; $0DAF  22 83 0B
        XOR A                            ; $0DB2  AF
        LD (CHAIN_PRESERVE_FLAG),A       ; $0DB3  32 BD 0C
        LD (CHAIN_BREAK_FLAG),A          ; $0DB6  32 C3 0C
        LD A,H                           ; $0DB9  7C
        AND L                            ; $0DBA  A5
        INC A                            ; $0DBB  3C
        JR Z,ERROR_PRINT_SETUP           ; $0DBC  28 03
        LD (ERRLIN),HL                   ; $0DBE  22 85 0B
; [RE] Build/print the error text: emit '?', look up the 2-char error mnemonic, append ' Error', and optionally ' in <line>'; falls into the direct-mode READY path.
ERROR_PRINT_SETUP:
        LD BC,ERROR_REPORT_BODY          ; $0DC1  01 CA 0D
ERROR_PRINT_SETUP_1:
        LD HL,(SAVSTK)                   ; $0DC4  2A 81 0B
        JP SUB_453A_2                    ; $0DC7  C3 72 45
; Packed table of 2-letter error mnemonics (NF/SN/RG/OD/FC/OV/OM/UL/BS/DD/...) indexed by error code, printed by ERROR_PRINT_MSG.
ERROR_REPORT_BODY:
        POP BC                           ; $0DCA  C1
        LD A,E                           ; $0DCB  7B
        LD C,E                           ; $0DCC  4B
        LD (SUB_0752_31+2),A             ; $0DCD  32 58 08
        LD HL,(OLDTXT)                   ; $0DD0  2A 7F 0B
        LD (ERRLIN_1),HL                 ; $0DD3  22 87 0B
        EX DE,HL                         ; $0DD6  EB
        LD HL,(ERR_SAVTXT)               ; $0DD7  2A 83 0B
        LD A,H                           ; $0DDA  7C
        AND L                            ; $0DDB  A5
        INC A                            ; $0DDC  3C
        JR Z,ERROR_REPORT_BODY_1         ; $0DDD  28 07
        LD (FRMEVL_TXTPTR_TEMP_1),HL     ; $0DDF  22 8E 0B
        EX DE,HL                         ; $0DE2  EB
        LD (FRMEVL_TXTPTR_TEMP_2),HL     ; $0DE3  22 90 0B
ERROR_REPORT_BODY_1:
        LD HL,(ERRLIN_2)                 ; $0DE6  2A 89 0B
        LD A,H                           ; $0DE9  7C
        OR L                             ; $0DEA  B5
        EX DE,HL                         ; $0DEB  EB
        LD HL,ONEFLG                     ; $0DEC  21 8B 0B
        JR Z,ERROR_REPORT_BODY_2         ; $0DEF  28 08
        AND (HL)                         ; $0DF1  A6
        JR NZ,ERROR_REPORT_BODY_2        ; $0DF2  20 05
        DEC (HL)                         ; $0DF4  35
        EX DE,HL                         ; $0DF5  EB
        JP STMT_FOR_10                   ; $0DF6  C3 A0 13
ERROR_REPORT_BODY_2:
        XOR A                            ; $0DF9  AF
        LD (HL),A                        ; $0DFA  77
        LD E,C                           ; $0DFB  59
        LD (CTRL_O_SUPPRESS),A           ; $0DFC  32 62 08
        CALL PRINT_CRLF_IF_COL           ; $0DFF  CD F9 43
        LD HL,ERROR_MESSAGE_TABLE        ; $0E02  21 21 05
        LD A,E                           ; $0E05  7B
        CP $47                           ; $0E06  FE 47
        JR NC,ERROR_REPORT_BODY_3        ; $0E08  30 08
        CP $32                           ; $0E0A  FE 32
        JR NC,ERROR_REPORT_BODY_4        ; $0E0C  30 06
        CP $21                           ; $0E0E  FE 21
        JR C,ERROR_REPORT_BODY_5         ; $0E10  38 05
ERROR_REPORT_BODY_3:
        LD A,$26                         ; $0E12  3E 26
ERROR_REPORT_BODY_4:
        SUB $11                          ; $0E14  D6 11
        LD E,A                           ; $0E16  5F
ERROR_REPORT_BODY_5:
        CALL STMT_DATA+2                 ; $0E17  CD D1 15
        INC HL                           ; $0E1A  23
        DEC E                            ; $0E1B  1D
        JR NZ,ERROR_REPORT_BODY_5        ; $0E1C  20 F9
        PUSH HL                          ; $0E1E  E5
        LD HL,(ERR_SAVTXT)               ; $0E1F  2A 83 0B
        EX (SP),HL                       ; $0E22  E3
; [RE] After error message: if current line is direct (text begins '?'), point at the canned direct-mode message ($0521); else print ' in <line>' and drop to READY.
ERROR_RESUME_FROM_DIRECT:
        LD A,(HL)                        ; $0E23  7E
        CP $3F                           ; $0E24  FE 3F
        JR NZ,STOP_BREAK                 ; $0E26  20 06
        POP HL                           ; $0E28  E1
        LD HL,ERROR_MESSAGE_TABLE        ; $0E29  21 21 05
        JR ERROR_REPORT_BODY_3           ; $0E2C  18 E4
; [RE] STOP/Ctrl-C break: print 'Break' message ($6C40 STROUT), compute/print the current line number, then fall into the READY prompt and NEWSTT main loop.
STOP_BREAK:
        CALL STROUT                      ; $0E2E  CD BE 48
        POP HL                           ; $0E31  E1
        LD DE,$FFFE                      ; $0E32  11 FE FF
        CALL CMP_HL_DE                   ; $0E35  CD 9D 45
STOP_BREAK_1:
        CALL Z,CRLF                      ; $0E38  CC 06 44
        JP Z,STMT_SYSTEM_1               ; $0E3B  CA 6B 5A
        LD A,H                           ; $0E3E  7C
        AND L                            ; $0E3F  A5
        INC A                            ; $0E40  3C
        CALL NZ,FOUT_PRINT               ; $0E41  C4 89 33
STOP_BREAK_2:
        LD A,$C1                         ; $0E44  3E C1
; READY/main interpreter loop: print prompt char, clear output column $083F, read a console line ($781A), then process it (tokenize or execute).
NEWSTT_READY:
        CALL OUTDO_RESET_COL             ; $0E46  CD F7 42
        XOR A                            ; $0E49  AF
        LD (CTRL_O_SUPPRESS),A           ; $0E4A  32 62 08
        CALL LOAD_FINISH_CLOSE_CUR       ; $0E4D  CD 98 54
        CALL PRINT_CRLF_IF_COL           ; $0E50  CD F9 43
        LD HL,MSG_BREAK                  ; $0E53  21 15 0D
NEWSTT_READY_1:
        CALL $0000                       ; $0E56  CD 00 00
        LD A,(SUB_0752_31+2)             ; $0E59  3A 58 08
        SUB $02                          ; $0E5C  D6 02
        CALL Z,STMT_EDIT_LINENUM         ; $0E5E  CC DB 3E
; [RE] Process the input line: FOUT the leading line number, FNDLIN to locate it, CRUNCH-tokenize ($3000), then insert/replace/delete in the program or execute as a direct statement.
DIRECT_LINE_DISPATCH:
        LD HL,$FFFF                      ; $0E61  21 FF FF
        LD (SAVTXT),HL                   ; $0E64  22 67 08
        LD A,(AUTFLG)                    ; $0E67  3A 7A 0B
        OR A                             ; $0E6A  B7
        JR Z,SUB_0E9E_2                  ; $0E6B  28 43
        LD HL,(AUTLIN)                   ; $0E6D  2A 7B 0B
        PUSH HL                          ; $0E70  E5
        CALL FOUT                        ; $0E71  CD 91 33
        POP DE                           ; $0E74  D1
        PUSH DE                          ; $0E75  D5
        CALL FNDLIN                      ; $0E76  CD AB 0F
        LD A,$2A                         ; $0E79  3E 2A
        JR C,DIRECT_LINE_DISPATCH_1      ; $0E7B  38 02
        LD A,$20                         ; $0E7D  3E 20
DIRECT_LINE_DISPATCH_1:
        CALL OUTCHR                      ; $0E7F  CD 91 42
        CALL INLIN_RESET_EDIT_STATE      ; $0E82  CD A1 4C
        POP DE                           ; $0E85  D1
        JR NC,DIRECT_LINE_DISPATCH_3     ; $0E86  30 0C
        XOR A                            ; $0E88  AF
        LD (AUTFLG),A                    ; $0E89  32 7A 0B
        JR NEWSTT_READY                  ; $0E8C  18 B8
DIRECT_LINE_DISPATCH_2:
        XOR A                            ; $0E8E  AF
        LD (AUTFLG),A                    ; $0E8F  32 7A 0B
        JR SUB_0E9E_1                    ; $0E92  18 13
DIRECT_LINE_DISPATCH_3:
        LD HL,(AUTINC)                   ; $0E94  2A 7D 0B
        ADD HL,DE                        ; $0E97  19
        JR C,DIRECT_LINE_DISPATCH_2      ; $0E98  38 F4
        PUSH DE                          ; $0E9A  D5
        LD DE,$FFF9                      ; $0E9B  11 F9 FF
        CALL CMP_HL_DE                   ; $0E9E  CD 9D 45
        POP DE                           ; $0EA1  D1
        JR NC,DIRECT_LINE_DISPATCH_2     ; $0EA2  30 EA
        LD (AUTLIN),HL                   ; $0EA4  22 7B 0B
SUB_0E9E_1:
        LD A,(BUF)                       ; $0EA7  3A 31 0A
        OR A                             ; $0EAA  B7
        JR Z,DIRECT_LINE_DISPATCH        ; $0EAB  28 B4
        JP EDIT_BUF_SHIFT_10             ; $0EAD  C3 C1 40
SUB_0E9E_2:
        CALL INLIN_RESET_EDIT_STATE      ; $0EB0  CD A1 4C
        JR C,DIRECT_LINE_DISPATCH        ; $0EB3  38 AC
        CALL CHRGET                      ; $0EB5  CD E4 13
        INC A                            ; $0EB8  3C
        DEC A                            ; $0EB9  3D
        JR Z,DIRECT_LINE_DISPATCH        ; $0EBA  28 A5
        PUSH AF                          ; $0EBC  F5
        CALL LINGET                      ; $0EBD  CD FB 14
        CALL CRUNCH_SKIP_BLANKS_BACK     ; $0EC0  CD 9A 12
        LD A,(HL)                        ; $0EC3  7E
        CP $20                           ; $0EC4  FE 20
        CALL Z,FP_LOAD_DONE              ; $0EC6  CC 3D 2B
; [RE] Execute a tokenized direct-mode statement: CHRGET-prime and call the statement dispatcher; on a bare line number fall to edit/insert.
DIRECT_EXEC_STMT:
        PUSH DE                          ; $0EC9  D5
        CALL CRUNCH                      ; $0ECA  CD 1B 10
        POP DE                           ; $0ECD  D1
        POP AF                           ; $0ECE  F1
        LD (OLDTXT),HL                   ; $0ECF  22 7F 0B
        JP NC,STMT_MERGE_3               ; $0ED2  D2 D0 54
        PUSH DE                          ; $0ED5  D5
        PUSH BC                          ; $0ED6  C5
        CALL ILLEGAL_DIRECT_CHECK        ; $0ED7  CD 2A 5E
        CALL CHRGET                      ; $0EDA  CD E4 13
        OR A                             ; $0EDD  B7
        PUSH AF                          ; $0EDE  F5
        EX DE,HL                         ; $0EDF  EB
        LD (ERRLIN),HL                   ; $0EE0  22 85 0B
        EX DE,HL                         ; $0EE3  EB
        CALL FNDLIN                      ; $0EE4  CD AB 0F
        JR C,SUB_0EDA_1                  ; $0EE7  38 06
        POP AF                           ; $0EE9  F1
        PUSH AF                          ; $0EEA  F5
        JP Z,STMT_GOTO_2                 ; $0EEB  CA 91 15
        OR A                             ; $0EEE  B7
SUB_0EDA_1:
        PUSH BC                          ; $0EEF  C5
        PUSH AF                          ; $0EF0  F5
        PUSH HL                          ; $0EF1  E5
        CALL RENUM_FIXUP_IF_PENDING      ; $0EF2  CD 26 24
        POP HL                           ; $0EF5  E1
        POP AF                           ; $0EF6  F1
        POP BC                           ; $0EF7  C1
        PUSH BC                          ; $0EF8  C5
        CALL C,BLOCK_MOVE_TO_VARTAB      ; $0EF9  DC AF 22
        POP DE                           ; $0EFC  D1
        POP AF                           ; $0EFD  F1
        PUSH DE                          ; $0EFE  D5
        JR Z,SUB_0F28_2                  ; $0EFF  28 37
        POP DE                           ; $0F01  D1
        LD A,(CHAIN_BREAK_FLAG)          ; $0F02  3A C3 0C
        OR A                             ; $0F05  B7
        JR NZ,SUB_0EDA_2                 ; $0F06  20 06
        LD HL,(MEMSIZ)                   ; $0F08  2A 46 0B
        LD (FRETOP),HL                   ; $0F0B  22 6B 0B
SUB_0EDA_2:
        LD HL,(VARTAB)                   ; $0F0E  2A 92 0B
        EX (SP),HL                       ; $0F11  E3
        POP BC                           ; $0F12  C1
        PUSH HL                          ; $0F13  E5
        ADD HL,BC                        ; $0F14  09
        PUSH HL                          ; $0F15  E5
        CALL STR_COPY_DOWN               ; $0F16  CD 8F 44
        POP HL                           ; $0F19  E1
        LD (VARTAB),HL                   ; $0F1A  22 92 0B
        EX DE,HL                         ; $0F1D  EB
        LD (HL),H                        ; $0F1E  74
        POP BC                           ; $0F1F  C1
        POP DE                           ; $0F20  D1
        PUSH HL                          ; $0F21  E5
        INC HL                           ; $0F22  23
        INC HL                           ; $0F23  23
        LD (HL),E                        ; $0F24  73
        INC HL                           ; $0F25  23
        LD (HL),D                        ; $0F26  72
        INC HL                           ; $0F27  23
        LD DE,FILTAB_18+1                ; $0F28  11 F2 08
        DEC BC                           ; $0F2B  0B
        DEC BC                           ; $0F2C  0B
        DEC BC                           ; $0F2D  0B
        DEC BC                           ; $0F2E  0B
SUB_0F28_1:
        LD A,(DE)                        ; $0F2F  1A
        LD (HL),A                        ; $0F30  77
        INC HL                           ; $0F31  23
        INC DE                           ; $0F32  13
        DEC BC                           ; $0F33  0B
        LD A,C                           ; $0F34  79
        OR B                             ; $0F35  B0
        JR NZ,SUB_0F28_1                 ; $0F36  20 F7
SUB_0F28_2:
        POP DE                           ; $0F38  D1
        CALL CHEAD_LOOP                  ; $0F39  CD 60 0F
        LD HL,$0080                      ; $0F3C  21 80 00
        LD (HL),$00                      ; $0F3F  36 00
        LD (FILTAB),HL                   ; $0F41  22 73 08
        LD HL,(PTRFIL)                   ; $0F44  2A 63 08
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $0F47  22 8C 0B
        CALL CLEAR_RESET_DATAPTR         ; $0F4A  CD 0B 45
        LD HL,(FILTAB_SLOT0_SEED)        ; $0F4D  2A 71 08
        LD (FILTAB),HL                   ; $0F50  22 73 08
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $0F53  2A 8C 0B
        LD (PTRFIL),HL                   ; $0F56  22 63 08
        JP DIRECT_LINE_DISPATCH          ; $0F59  C3 61 0E
; [RE] Relink program lines from program start ($0846): rebuild each line's forward-link word so the chain is contiguous after an insert/delete.
CHEAD:
        LD HL,(TXTTAB)                   ; $0F5C  2A 69 08
        EX DE,HL                         ; $0F5F  EB
; [RE] CHEAD scan loop: for each line walk to its terminating $00, fold embedded tokens, and write the next-line link pointer; stop at the program's double-zero end marker.
CHEAD_LOOP:
        LD H,D                           ; $0F60  62
        LD L,E                           ; $0F61  6B
        LD A,(HL)                        ; $0F62  7E
        INC HL                           ; $0F63  23
        OR (HL)                          ; $0F64  B6
        RET Z                            ; $0F65  C8
        INC HL                           ; $0F66  23
        INC HL                           ; $0F67  23
CHEAD_LOOP_1:
        INC HL                           ; $0F68  23
        LD A,(HL)                        ; $0F69  7E
CHEAD_LOOP_2:
        OR A                             ; $0F6A  B7
        JR Z,CHEAD_LOOP_3                ; $0F6B  28 10
        CP $20                           ; $0F6D  FE 20
        JR NC,CHEAD_LOOP_1               ; $0F6F  30 F7
        CP $0B                           ; $0F71  FE 0B
        JR C,CHEAD_LOOP_1                ; $0F73  38 F3
        CALL CHRGOT                      ; $0F75  CD E5 13
        CALL CHRGET                      ; $0F78  CD E4 13
        JR CHEAD_LOOP_2                  ; $0F7B  18 ED
CHEAD_LOOP_3:
        INC HL                           ; $0F7D  23
        EX DE,HL                         ; $0F7E  EB
        LD (HL),E                        ; $0F7F  73
        INC HL                           ; $0F80  23
        LD (HL),D                        ; $0F81  72
        JR CHEAD_LOOP                    ; $0F82  18 DC
; [RE] Parse an optional 'start[-end]' line-number range (LIST/DELETE): get first line# ($34D5), accept ',' / '-' ($F3) separator, get second; syntax-error to $0D6F on malformed input.
SCAN_LINE_RANGE:
        LD DE,$0000                      ; $0F84  11 00 00
        PUSH DE                          ; $0F87  D5
        JR Z,SCAN_LINE_RANGE_2           ; $0F88  28 14
        POP DE                           ; $0F8A  D1
        CALL LINGET_DOT                  ; $0F8B  CD F0 14
        PUSH DE                          ; $0F8E  D5
        JR Z,SCAN_LINE_RANGE_3           ; $0F8F  28 16
        LD A,(HL)                        ; $0F91  7E
        CP $2C                           ; $0F92  FE 2C
        JR Z,SCAN_LINE_RANGE_1           ; $0F94  28 05
        CP TOK_MINUS                     ; $0F96  FE F3
        JP NZ,RAISE_SYNTAX_ERROR         ; $0F98  C2 92 0D
SCAN_LINE_RANGE_1:
        CALL CHRGET                      ; $0F9B  CD E4 13
SCAN_LINE_RANGE_2:
        LD DE,$FFFA                      ; $0F9E  11 FA FF
        CALL NZ,LINGET_DOT               ; $0FA1  C4 F0 14
        JP NZ,RAISE_SYNTAX_ERROR         ; $0FA4  C2 92 0D
SCAN_LINE_RANGE_3:
        EX DE,HL                         ; $0FA7  EB
        POP DE                           ; $0FA8  D1
; [RE] FNDLIN entry that takes the line number already in DE (via the stack) before searching the program.
FNDLIN_FROM_TEXT:
        EX (SP),HL                       ; $0FA9  E3
        PUSH HL                          ; $0FAA  E5
; Find a program line by number: scan the linked line list from program start ($0846), comparing each line number against the target; returns C set/clear and BC=prior link for the insert point.
FNDLIN:
        LD HL,(TXTTAB)                   ; $0FAB  2A 69 08
; FNDLIN inner loop: follow each line's forward link, load its line number, FNDLIN-compare vs target; return when found or when the number passes the target.
FNDLIN_LOOP:
        LD B,H                           ; $0FAE  44
        LD C,L                           ; $0FAF  4D
        LD A,(HL)                        ; $0FB0  7E
        INC HL                           ; $0FB1  23
        OR (HL)                          ; $0FB2  B6
        DEC HL                           ; $0FB3  2B
        RET Z                            ; $0FB4  C8
        INC HL                           ; $0FB5  23
        INC HL                           ; $0FB6  23
        LD A,(HL)                        ; $0FB7  7E
        INC HL                           ; $0FB8  23
        LD H,(HL)                        ; $0FB9  66
        LD L,A                           ; $0FBA  6F
        CALL CMP_HL_DE                   ; $0FBB  CD 9D 45
        LD H,B                           ; $0FBE  60
        LD L,C                           ; $0FBF  69
        LD A,(HL)                        ; $0FC0  7E
        INC HL                           ; $0FC1  23
        LD H,(HL)                        ; $0FC2  66
        LD L,A                           ; $0FC3  6F
        CCF                              ; $0FC4  3F
        RET Z                            ; $0FC5  C8
        CCF                              ; $0FC6  3F
        RET NC                           ; $0FC7  D0
        JR FNDLIN_LOOP                   ; $0FC8  18 E4
; [RE] Evaluate a PRINT/INPUT-style item with optional '#'(file/channel $23) prefix: CHRGOT, FRMEVL the operand ($3A75), branch on numeric vs string ($3DC8), and stage it into the string/var area ($0B6F).
EVAL_CHANNEL_OR_ITEM:
        CALL CHRGOT                      ; $0FCA  CD E5 13
        CP $23                           ; $0FCD  FE 23
        RET Z                            ; $0FCF  C8
        PUSH HL                          ; $0FD0  E5
        CALL FRMEVL_NOPAREN              ; $0FD1  CD 90 1A
        CALL FRMEVL_TEST_TYPE            ; $0FD4  CD E3 1D
        JR Z,EVAL_CHANNEL_OR_ITEM_1      ; $0FD7  28 08
        CALL FILE_NUM_TO_FCB_NZ          ; $0FD9  CD B5 52
        POP DE                           ; $0FDC  D1
        POP DE                           ; $0FDD  D1
        JP STMT_PUT_1                    ; $0FDE  C3 EA 5B
EVAL_CHANNEL_OR_ITEM_1:
        POP HL                           ; $0FE1  E1
        CALL PTRGET_1+1                  ; $0FE2  CD B3 3B
        CALL FRMEVL_TEST_TYPE            ; $0FE5  CD E3 1D
        JP NZ,GETINT_POSITIVE_1          ; $0FE8  C2 EB 14
        PUSH HL                          ; $0FEB  E5
        LD A,(DE)                        ; $0FEC  1A
        OR A                             ; $0FED  B7
        JR Z,EVAL_CHANNEL_OR_ITEM_2      ; $0FEE  28 0F
        PUSH DE                          ; $0FF0  D5
        EX DE,HL                         ; $0FF1  EB
        INC HL                           ; $0FF2  23
        LD E,(HL)                        ; $0FF3  5E
        INC HL                           ; $0FF4  23
        LD D,(HL)                        ; $0FF5  56
        LD HL,(VARTAB)                   ; $0FF6  2A 92 0B
        CALL CMP_HL_DE                   ; $0FF9  CD 9D 45
        POP DE                           ; $0FFC  D1
        JR C,EVAL_CHANNEL_OR_ITEM_3+1    ; $0FFD  38 0B
EVAL_CHANNEL_OR_ITEM_2:
        LD A,$01                         ; $0FFF  3E 01
        PUSH DE                          ; $1001  D5
        CALL GETSPA                      ; $1002  CD D6 48
        POP HL                           ; $1005  E1
        CALL STORE_STR_DESC_AT_HL        ; $1006  CD 60 48
EVAL_CHANNEL_OR_ITEM_3:
        CP $EB                           ; $1009  FE EB
        LD (HL),$01                      ; $100B  36 01
        INC HL                           ; $100D  23
        LD E,(HL)                        ; $100E  5E
        INC HL                           ; $100F  23
        LD D,(HL)                        ; $1010  56
        CALL GET_PENDING_KEY             ; $1011  CD 72 44
        CALL Z,INCHR                     ; $1014  CC A2 43
        LD (DE),A                        ; $1017  12
        POP HL                           ; $1018  E1
        POP BC                           ; $1019  C1
        RET                              ; $101A  C9
; MS BASIC-80 CRUNCH: tokenizes an input line. Scans the source text, folds reserved words to single-byte tokens via the reserved-word name table (DE=$08CF/$04D8 reserved-word pointers), passes through string literals ($22) and REM/DATA text verbatim, and emits the crunched line. Handles the GOTO/GOSUB ('GO TO'/'GO SUB') two-word forms. $0B15/$0B16 are CRUNCH mode flags.
CRUNCH:
        XOR A                            ; $101B  AF
        LD (SUB_0B2A_7),A                ; $101C  32 39 0B
        LD (SUB_0B2A_6),A                ; $101F  32 38 0B
        LD BC,$013B                      ; $1022  01 3B 01
        LD DE,FILTAB_18+1                ; $1025  11 F2 08
CRUNCH_1:
        LD A,(HL)                        ; $1028  7E
        CP $22                           ; $1029  FE 22
        JP Z,SUB_1128_20                 ; $102B  CA 32 12
        CP $20                           ; $102E  FE 20
        JP Z,SUB_1128_16                 ; $1030  CA 0C 12
        OR A                             ; $1033  B7
        JP Z,SUB_1128_22                 ; $1034  CA 3A 12
        LD A,(SUB_0B2A_6)                ; $1037  3A 38 0B
        OR A                             ; $103A  B7
        LD A,(HL)                        ; $103B  7E
        JP NZ,SUB_1128_16                ; $103C  C2 0C 12
        CP $3F                           ; $103F  FE 3F
        LD A,$91                         ; $1041  3E 91
        PUSH DE                          ; $1043  D5
        PUSH BC                          ; $1044  C5
        JP Z,CRUNCH_RESWORD_TAIL_8       ; $1045  CA 03 11
        LD DE,RESWORD_OPS                ; $1048  11 D8 04
        CALL CHRGET_UPCASE               ; $104B  CD E7 1C
        CALL IS_LETTER_A                 ; $104E  CD BF 46
        JP C,SUB_1128_3                  ; $1051  DA 57 11
        PUSH HL                          ; $1054  E5
        LD BC,CRUNCH_RESWORD_TAIL        ; $1055  01 97 10
        PUSH BC                          ; $1058  C5
        CP $47                           ; $1059  FE 47
        RET NZ                           ; $105B  C0
        INC HL                           ; $105C  23
        CALL CHRGET_UPCASE               ; $105D  CD E7 1C
        CP $4F                           ; $1060  FE 4F
        RET NZ                           ; $1062  C0
        INC HL                           ; $1063  23
        CALL CHRGET_UPCASE               ; $1064  CD E7 1C
        CP $20                           ; $1067  FE 20
        RET NZ                           ; $1069  C0
        INC HL                           ; $106A  23
CRUNCH_2:
        CALL CHRGET_UPCASE               ; $106B  CD E7 1C
        INC HL                           ; $106E  23
        CP $20                           ; $106F  FE 20
        JR Z,CRUNCH_2                    ; $1071  28 F8
        CP $53                           ; $1073  FE 53
        JR Z,CRUNCH_3                    ; $1075  28 0C
        CP $54                           ; $1077  FE 54
        RET NZ                           ; $1079  C0
        CALL CHRGET_UPCASE               ; $107A  CD E7 1C
        CP $4F                           ; $107D  FE 4F
        LD A,TOK_GOTO                    ; $107F  3E 89
        JR CRUNCH_4                      ; $1081  18 0E
CRUNCH_3:
        CALL CHRGET_UPCASE               ; $1083  CD E7 1C
        CP $55                           ; $1086  FE 55
        RET NZ                           ; $1088  C0
        INC HL                           ; $1089  23
        CALL CHRGET_UPCASE               ; $108A  CD E7 1C
        CP $42                           ; $108D  FE 42
        LD A,$8D                         ; $108F  3E 8D
CRUNCH_4:
        RET NZ                           ; $1091  C0
        POP BC                           ; $1092  C1
        POP BC                           ; $1093  C1
        JP CRUNCH_RESWORD_TAIL_8         ; $1094  C3 03 11
; [RE] CRUNCH continuation reached via LD BC,L_307C/PUSH BC/RET (executable, rendered as DEFB): finishes tokenizing the reserved word that SUB_6A41 matched, emitting its token byte via CRUNCH_EMIT and looping back to CRUNCH_1.
CRUNCH_RESWORD_TAIL:
        POP HL                           ; $1097  E1
        CALL CHRGET_UPCASE               ; $1098  CD E7 1C
        PUSH HL                          ; $109B  E5
        LD HL,RESWORD_INDEX              ; $109C  21 1E 02
        SUB $41                          ; $109F  D6 41
        ADD A,A                          ; $10A1  87
        LD C,A                           ; $10A2  4F
        LD B,$00                         ; $10A3  06 00
        ADD HL,BC                        ; $10A5  09
        LD E,(HL)                        ; $10A6  5E
        INC HL                           ; $10A7  23
        LD D,(HL)                        ; $10A8  56
        POP HL                           ; $10A9  E1
        INC HL                           ; $10AA  23
CRUNCH_RESWORD_TAIL_1:
        PUSH HL                          ; $10AB  E5
CRUNCH_RESWORD_TAIL_2:
        CALL CHRGET_UPCASE               ; $10AC  CD E7 1C
        LD C,A                           ; $10AF  4F
        LD A,(DE)                        ; $10B0  1A
        AND $7F                          ; $10B1  E6 7F
        JP Z,CRUNCH_EMIT_2               ; $10B3  CA 5A 12
        INC HL                           ; $10B6  23
        CP C                             ; $10B7  B9
        JR NZ,CRUNCH_RESWORD_TAIL_5      ; $10B8  20 3E
        LD A,(DE)                        ; $10BA  1A
        INC DE                           ; $10BB  13
        OR A                             ; $10BC  B7
        JP P,CRUNCH_RESWORD_TAIL_2       ; $10BD  F2 AC 10
        LD A,C                           ; $10C0  79
        CP $28                           ; $10C1  FE 28
        JR Z,CRUNCH_RESWORD_TAIL_4       ; $10C3  28 18
        LD A,(DE)                        ; $10C5  1A
        CP $E2                           ; $10C6  FE E2
        JR Z,CRUNCH_RESWORD_TAIL_4       ; $10C8  28 13
        CP $E1                           ; $10CA  FE E1
        JR Z,CRUNCH_RESWORD_TAIL_4       ; $10CC  28 0F
        CALL CHRGET_UPCASE               ; $10CE  CD E7 1C
        CP $2E                           ; $10D1  FE 2E
        JR Z,CRUNCH_RESWORD_TAIL_3       ; $10D3  28 03
        CALL IS_ALNUM_CHAR               ; $10D5  CD FC 21
CRUNCH_RESWORD_TAIL_3:
        LD A,$00                         ; $10D8  3E 00
        JP NC,CRUNCH_EMIT_2              ; $10DA  D2 5A 12
CRUNCH_RESWORD_TAIL_4:
        POP AF                           ; $10DD  F1
        LD A,(DE)                        ; $10DE  1A
        OR A                             ; $10DF  B7
        JP M,CRUNCH_RESWORD_TAIL_7       ; $10E0  FA 02 11
        POP BC                           ; $10E3  C1
        POP DE                           ; $10E4  D1
        OR $80                           ; $10E5  F6 80
        PUSH AF                          ; $10E7  F5
        LD A,$FF                         ; $10E8  3E FF
        CALL CRUNCH_EMIT                 ; $10EA  CD 4F 12
        XOR A                            ; $10ED  AF
        LD (SUB_0B2A_7),A                ; $10EE  32 39 0B
        POP AF                           ; $10F1  F1
        CALL CRUNCH_EMIT                 ; $10F2  CD 4F 12
        JP CRUNCH_1                      ; $10F5  C3 28 10
CRUNCH_RESWORD_TAIL_5:
        POP HL                           ; $10F8  E1
CRUNCH_RESWORD_TAIL_6:
        LD A,(DE)                        ; $10F9  1A
        INC DE                           ; $10FA  13
        OR A                             ; $10FB  B7
        JP P,CRUNCH_RESWORD_TAIL_6       ; $10FC  F2 F9 10
        INC DE                           ; $10FF  13
        JR CRUNCH_RESWORD_TAIL_1         ; $1100  18 A9
CRUNCH_RESWORD_TAIL_7:
        DEC HL                           ; $1102  2B
CRUNCH_RESWORD_TAIL_8:
        PUSH AF                          ; $1103  F5
        LD BC,SUB_1128_1+1               ; $1104  01 35 11
        PUSH BC                          ; $1107  C5
        CP $8C                           ; $1108  FE 8C
        RET Z                            ; $110A  C8
        CP $A7                           ; $110B  FE A7
        RET Z                            ; $110D  C8
        CP $A8                           ; $110E  FE A8
        RET Z                            ; $1110  C8
        CP $A6                           ; $1111  FE A6
        RET Z                            ; $1113  C8
        CP $A3                           ; $1114  FE A3
        RET Z                            ; $1116  C8
        CP $A5                           ; $1117  FE A5
        RET Z                            ; $1119  C8
        CP $E5                           ; $111A  FE E5
        RET Z                            ; $111C  C8
        CP TOK_ELSE                      ; $111D  FE 9E
        RET Z                            ; $111F  C8
        CP $8A                           ; $1120  FE 8A
        RET Z                            ; $1122  C8
        CP $93                           ; $1123  FE 93
        RET Z                            ; $1125  C8
        CP $9C                           ; $1126  FE 9C
        RET Z                            ; $1128  C8
        CP TOK_GOTO                      ; $1129  FE 89
        RET Z                            ; $112B  C8
        CP TOK_THEN                      ; $112C  FE DE
        RET Z                            ; $112E  C8
        CP $8D                           ; $112F  FE 8D
        RET Z                            ; $1131  C8
        POP AF                           ; $1132  F1
        XOR A                            ; $1133  AF
SUB_1128_1:
        JP NZ,STMT_DISPATCH_TBL+54       ; $1134  C2 3E 01
SUB_1128_2:
        LD (SUB_0B2A_7),A                ; $1137  32 39 0B
        POP AF                           ; $113A  F1
        POP BC                           ; $113B  C1
        POP DE                           ; $113C  D1
        CP TOK_ELSE                      ; $113D  FE 9E
        PUSH AF                          ; $113F  F5
        CALL Z,CRUNCH_EMIT_COLON         ; $1140  CC 4D 12
        POP AF                           ; $1143  F1
        CP $EA                           ; $1144  FE EA
        JP NZ,SUB_1128_14                ; $1146  C2 EC 11
        PUSH AF                          ; $1149  F5
        CALL CRUNCH_EMIT_COLON           ; $114A  CD 4D 12
        LD A,TOK_REM                     ; $114D  3E 8F
        CALL CRUNCH_EMIT                 ; $114F  CD 4F 12
        POP AF                           ; $1152  F1
        PUSH AF                          ; $1153  F5
        JP SUB_1128_21                   ; $1154  C3 34 12
SUB_1128_3:
        LD A,(HL)                        ; $1157  7E
        CP $2E                           ; $1158  FE 2E
        JR Z,SUB_1128_4                  ; $115A  28 0A
        CP $3A                           ; $115C  FE 3A
        JP NC,SUB_1128_12                ; $115E  D2 DA 11
        CP $30                           ; $1161  FE 30
        JP C,SUB_1128_12                 ; $1163  DA DA 11
SUB_1128_4:
        LD A,(SUB_0B2A_7)                ; $1166  3A 39 0B
        OR A                             ; $1169  B7
        LD A,(HL)                        ; $116A  7E
        POP BC                           ; $116B  C1
        POP DE                           ; $116C  D1
        JP M,SUB_1128_16                 ; $116D  FA 0C 12
        JR Z,SUB_1128_8                  ; $1170  28 1F
        CP $2E                           ; $1172  FE 2E
        JP Z,SUB_1128_16                 ; $1174  CA 0C 12
        LD A,$0E                         ; $1177  3E 0E
        CALL CRUNCH_EMIT                 ; $1179  CD 4F 12
        PUSH DE                          ; $117C  D5
        CALL LINGET                      ; $117D  CD FB 14
        CALL CRUNCH_SKIP_BLANKS_BACK     ; $1180  CD 9A 12
SUB_1128_5:
        EX (SP),HL                       ; $1183  E3
        EX DE,HL                         ; $1184  EB
SUB_1128_6:
        LD A,L                           ; $1185  7D
        CALL CRUNCH_EMIT                 ; $1186  CD 4F 12
        LD A,H                           ; $1189  7C
SUB_1128_7:
        POP HL                           ; $118A  E1
        CALL CRUNCH_EMIT                 ; $118B  CD 4F 12
        JP CRUNCH_1                      ; $118E  C3 28 10
SUB_1128_8:
        PUSH DE                          ; $1191  D5
        PUSH BC                          ; $1192  C5
        LD A,(HL)                        ; $1193  7E
        CALL FIN_1+1                     ; $1194  CD 25 31
        CALL CRUNCH_SKIP_BLANKS_BACK     ; $1197  CD 9A 12
        POP BC                           ; $119A  C1
        POP DE                           ; $119B  D1
        PUSH HL                          ; $119C  E5
        LD A,(SUB_0B2A_5)                ; $119D  3A 37 0B
        CP $02                           ; $11A0  FE 02
        JR NZ,SUB_1128_9                 ; $11A2  20 15
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $11A4  2A D4 0C
        LD A,H                           ; $11A7  7C
        OR A                             ; $11A8  B7
        LD A,$02                         ; $11A9  3E 02
        JR NZ,SUB_1128_9                 ; $11AB  20 0C
        LD A,L                           ; $11AD  7D
        LD H,L                           ; $11AE  65
        LD L,$0F                         ; $11AF  2E 0F
        CP $0A                           ; $11B1  FE 0A
        JR NC,SUB_1128_6                 ; $11B3  30 D0
        ADD A,$11                        ; $11B5  C6 11
        JR SUB_1128_7                    ; $11B7  18 D1
SUB_1128_9:
        PUSH AF                          ; $11B9  F5
        RRCA                             ; $11BA  0F
        ADD A,$1B                        ; $11BB  C6 1B
        CALL CRUNCH_EMIT                 ; $11BD  CD 4F 12
        LD HL,CHAIN_BREAK_FLAG_9         ; $11C0  21 D4 0C
        CALL FRMEVL_TEST_TYPE            ; $11C3  CD E3 1D
        JR C,SUB_1128_10                 ; $11C6  38 03
        LD HL,CHAIN_BREAK_FLAG_6         ; $11C8  21 D0 0C
SUB_1128_10:
        POP AF                           ; $11CB  F1
SUB_1128_11:
        PUSH AF                          ; $11CC  F5
        LD A,(HL)                        ; $11CD  7E
        CALL CRUNCH_EMIT                 ; $11CE  CD 4F 12
        POP AF                           ; $11D1  F1
        INC HL                           ; $11D2  23
        DEC A                            ; $11D3  3D
        JR NZ,SUB_1128_11                ; $11D4  20 F6
        POP HL                           ; $11D6  E1
        JP CRUNCH_1                      ; $11D7  C3 28 10
SUB_1128_12:
        LD DE,KWGRP_Z                    ; $11DA  11 D7 04
SUB_1128_13:
        INC DE                           ; $11DD  13
        LD A,(DE)                        ; $11DE  1A
        AND $7F                          ; $11DF  E6 7F
        JP Z,CRUNCH_EMIT_5               ; $11E1  CA 80 12
        INC DE                           ; $11E4  13
        CP (HL)                          ; $11E5  BE
        LD A,(DE)                        ; $11E6  1A
        JR NZ,SUB_1128_13                ; $11E7  20 F4
        JP CRUNCH_EMIT_6                 ; $11E9  C3 8F 12
SUB_1128_14:
        CP $26                           ; $11EC  FE 26
        JR NZ,SUB_1128_16                ; $11EE  20 1C
        PUSH HL                          ; $11F0  E5
        CALL CHRGET                      ; $11F1  CD E4 13
        POP HL                           ; $11F4  E1
        CALL TOUPPER_A                   ; $11F5  CD E8 1C
        CP $48                           ; $11F8  FE 48
        LD A,$0B                         ; $11FA  3E 0B
        JR NZ,SUB_1128_15                ; $11FC  20 02
        LD A,$0C                         ; $11FE  3E 0C
SUB_1128_15:
        CALL CRUNCH_EMIT                 ; $1200  CD 4F 12
        PUSH DE                          ; $1203  D5
        PUSH BC                          ; $1204  C5
        CALL SCAN_AMP_RADIX_CONST        ; $1205  CD F6 1C
        POP BC                           ; $1208  C1
        JP SUB_1128_5                    ; $1209  C3 83 11
SUB_1128_16:
        INC HL                           ; $120C  23
        PUSH AF                          ; $120D  F5
        CALL CRUNCH_EMIT                 ; $120E  CD 4F 12
        POP AF                           ; $1211  F1
        SUB $3A                          ; $1212  D6 3A
        JR Z,SUB_1128_17                 ; $1214  28 06
        CP $4A                           ; $1216  FE 4A
        JR NZ,SUB_1128_18                ; $1218  20 08
        LD A,$01                         ; $121A  3E 01
SUB_1128_17:
        LD (SUB_0B2A_6),A                ; $121C  32 38 0B
        LD (SUB_0B2A_7),A                ; $121F  32 39 0B
SUB_1128_18:
        SUB $55                          ; $1222  D6 55
        JP NZ,CRUNCH_1                   ; $1224  C2 28 10
        PUSH AF                          ; $1227  F5
SUB_1128_19:
        LD A,(HL)                        ; $1228  7E
        OR A                             ; $1229  B7
        EX (SP),HL                       ; $122A  E3
        LD A,H                           ; $122B  7C
        POP HL                           ; $122C  E1
        JR Z,SUB_1128_22                 ; $122D  28 0B
        CP (HL)                          ; $122F  BE
        JR Z,SUB_1128_16                 ; $1230  28 DA
SUB_1128_20:
        PUSH AF                          ; $1232  F5
        LD A,(HL)                        ; $1233  7E
SUB_1128_21:
        INC HL                           ; $1234  23
        CALL CRUNCH_EMIT                 ; $1235  CD 4F 12
        JR SUB_1128_19                   ; $1238  18 EE
SUB_1128_22:
        LD HL,STMT_DISPATCH_TBL+56       ; $123A  21 40 01
        LD A,L                           ; $123D  7D
        SUB C                            ; $123E  91
        LD C,A                           ; $123F  4F
        LD A,H                           ; $1240  7C
        SBC A,B                          ; $1241  98
        LD B,A                           ; $1242  47
        LD HL,FILTAB_18                  ; $1243  21 F1 08
        XOR A                            ; $1246  AF
        LD (DE),A                        ; $1247  12
        INC DE                           ; $1248  13
        LD (DE),A                        ; $1249  12
        INC DE                           ; $124A  13
        LD (DE),A                        ; $124B  12
        RET                              ; $124C  C9
; [RE] Load A=':' ($3A) then fall into CRUNCH_EMIT: emit a statement-separator colon into the crunch buffer (used around tokens like ELSE/REM that imply a colon).
CRUNCH_EMIT_COLON:
        LD A,$3A                         ; $124D  3E 3A
; [RE] CRUNCH output-byte helper: store A to the crunch buffer at (DE), advance DE, decrement remaining count BC; on buffer exhaustion raise error E=$17 (line/buffer overflow) via the RAISE_ERROR dispatcher.
CRUNCH_EMIT:
        LD (DE),A                        ; $124F  12
        INC DE                           ; $1250  13
        DEC BC                           ; $1251  0B
        LD A,C                           ; $1252  79
        OR B                             ; $1253  B0
        RET NZ                           ; $1254  C0
CRUNCH_EMIT_1:
        LD E,ERR_LINE_BUFFER_OVERFLOW    ; $1255  1E 17
        JP RAISE_ERROR                   ; $1257  C3 AC 0D
CRUNCH_EMIT_2:
        POP HL                           ; $125A  E1
        DEC HL                           ; $125B  2B
        DEC A                            ; $125C  3D
        LD (SUB_0B2A_7),A                ; $125D  32 39 0B
        POP BC                           ; $1260  C1
        POP DE                           ; $1261  D1
        CALL CHRGET_UPCASE               ; $1262  CD E7 1C
CRUNCH_EMIT_3:
        CALL CRUNCH_EMIT                 ; $1265  CD 4F 12
        INC HL                           ; $1268  23
        CALL CHRGET_UPCASE               ; $1269  CD E7 1C
        CALL IS_LETTER_A                 ; $126C  CD BF 46
        JR NC,CRUNCH_EMIT_3              ; $126F  30 F4
        CP $3A                           ; $1271  FE 3A
        JR NC,CRUNCH_EMIT_4              ; $1273  30 08
        CP $30                           ; $1275  FE 30
        JR NC,CRUNCH_EMIT_3              ; $1277  30 EC
        CP $2E                           ; $1279  FE 2E
        JR Z,CRUNCH_EMIT_3               ; $127B  28 E8
CRUNCH_EMIT_4:
        JP CRUNCH_1                      ; $127D  C3 28 10
CRUNCH_EMIT_5:
        LD A,(HL)                        ; $1280  7E
        CP $20                           ; $1281  FE 20
        JR NC,CRUNCH_EMIT_6              ; $1283  30 0A
        CP $09                           ; $1285  FE 09
        JR Z,CRUNCH_EMIT_6               ; $1287  28 06
        CP $0A                           ; $1289  FE 0A
        JR Z,CRUNCH_EMIT_6               ; $128B  28 02
        LD A,$20                         ; $128D  3E 20
CRUNCH_EMIT_6:
        PUSH AF                          ; $128F  F5
        LD A,(SUB_0B2A_7)                ; $1290  3A 39 0B
        INC A                            ; $1293  3C
        JR Z,CRUNCH_EMIT_7               ; $1294  28 01
        DEC A                            ; $1296  3D
CRUNCH_EMIT_7:
        JP SUB_1128_2                    ; $1297  C3 37 11
; [RE] CRUNCH helper: walk HL backward over trailing whitespace (space/$09/$0A), then INC HL to leave HL just past the last non-blank; used to trim blanks before re-scanning a number/reserved word.
CRUNCH_SKIP_BLANKS_BACK:
        DEC HL                           ; $129A  2B
        LD A,(HL)                        ; $129B  7E
        CP $20                           ; $129C  FE 20
        JR Z,CRUNCH_SKIP_BLANKS_BACK     ; $129E  28 FA
        CP $09                           ; $12A0  FE 09
        JR Z,CRUNCH_SKIP_BLANKS_BACK     ; $12A2  28 F6
        CP $0A                           ; $12A4  FE 0A
        JR Z,CRUNCH_SKIP_BLANKS_BACK     ; $12A6  28 F2
        INC HL                           ; $12A8  23
        RET                              ; $12A9  C9
; [RE] FOR statement handler (token $82): sets up the FOR/NEXT loop frame on the runtime stack.
STMT_FOR:
        LD A,$64                         ; $12AA  3E 64
        LD (DATA_LINE_TXTPTR_1),A        ; $12AC  32 75 0B
        CALL PTRGET_1+1                  ; $12AF  CD B3 3B
        CALL SYNCHR                      ; $12B2  CD A3 45
        DEFB    TOK_EQ                   ; $12B5  F0  inline keyword-token arg consumed by the preceding CALL
        PUSH DE                          ; $12B6  D5
        EX DE,HL                         ; $12B7  EB
        LD (DATA_LINE_TXTPTR_3),HL       ; $12B8  22 77 0B
        EX DE,HL                         ; $12BB  EB
        LD A,(SUB_0B2A_5)                ; $12BC  3A 37 0B
        PUSH AF                          ; $12BF  F5
        CALL FRMEVL_NOPAREN              ; $12C0  CD 90 1A
        POP AF                           ; $12C3  F1
        PUSH HL                          ; $12C4  E5
        CALL FRMEVL_APPLY_OP             ; $12C5  CD 1A 20
        LD HL,SUB_0C4B_10                ; $12C8  21 90 0C
        CALL FP_MOVE_TO_FAC              ; $12CB  CD 3F 2B
        POP HL                           ; $12CE  E1
        POP DE                           ; $12CF  D1
        POP BC                           ; $12D0  C1
        PUSH HL                          ; $12D1  E5
        CALL STMT_DATA                   ; $12D2  CD CF 15
        LD (FRETOP_3),HL                 ; $12D5  22 71 0B
        LD HL,$0002                      ; $12D8  21 02 00
        ADD HL,SP                        ; $12DB  39
STMT_FOR_1:
        CALL STKFRAME_SCAN               ; $12DC  CD 24 0D
        POP DE                           ; $12DF  D1
        JR NZ,STMT_FOR_2                 ; $12E0  20 18
        ADD HL,BC                        ; $12E2  09
        PUSH DE                          ; $12E3  D5
        DEC HL                           ; $12E4  2B
        LD D,(HL)                        ; $12E5  56
        DEC HL                           ; $12E6  2B
        LD E,(HL)                        ; $12E7  5E
        INC HL                           ; $12E8  23
        INC HL                           ; $12E9  23
        PUSH HL                          ; $12EA  E5
        LD HL,(FRETOP_3)                 ; $12EB  2A 71 0B
        CALL CMP_HL_DE                   ; $12EE  CD 9D 45
        POP HL                           ; $12F1  E1
        JP NZ,STMT_FOR_1                 ; $12F2  C2 DC 12
        POP DE                           ; $12F5  D1
        LD SP,HL                         ; $12F6  F9
        LD (SAVSTK),HL                   ; $12F7  22 81 0B
STMT_FOR_2:
        EX DE,HL                         ; $12FA  EB
        LD C,$08                         ; $12FB  0E 08
        CALL CHECK_STACK_ROOM            ; $12FD  CD 9F 44
        PUSH HL                          ; $1300  E5
        LD HL,(FRETOP_3)                 ; $1301  2A 71 0B
        EX (SP),HL                       ; $1304  E3
        PUSH HL                          ; $1305  E5
        LD HL,(SAVTXT)                   ; $1306  2A 67 08
        EX (SP),HL                       ; $1309  E3
        CALL SYNCHR                      ; $130A  CD A3 45
        DEFB    TOK_TO                   ; $130D  DD  inline keyword-token arg consumed by the preceding CALL
        CALL FRMEVL_TEST_TYPE            ; $130E  CD E3 1D
        JP Z,RAISE_TYPE_MISMATCH         ; $1311  CA AA 0D
STMT_FOR_3:
        JP NC,RAISE_TYPE_MISMATCH        ; $1314  D2 AA 0D
        PUSH AF                          ; $1317  F5
        CALL FRMEVL_NOPAREN              ; $1318  CD 90 1A
        POP AF                           ; $131B  F1
        PUSH HL                          ; $131C  E5
        JP P,STMT_FOR_4                  ; $131D  F2 35 13
        CALL FN_LPOS                     ; $1320  CD F4 2B
        EX (SP),HL                       ; $1323  E3
        LD DE,$0001                      ; $1324  11 01 00
        LD A,(HL)                        ; $1327  7E
        CP TOK_STEP                      ; $1328  FE E0
        CALL Z,GETINT_CHRGET             ; $132A  CC A0 20
        PUSH DE                          ; $132D  D5
        PUSH HL                          ; $132E  E5
        EX DE,HL                         ; $132F  EB
        CALL FP_MANT_SIGN                ; $1330  CD 12 2B
        JR STMT_FOR_5                    ; $1333  18 22
STMT_FOR_4:
        CALL FN_CINT                     ; $1335  CD 6C 2C
        CALL FP_LOAD_FAC                 ; $1338  CD 33 2B
        POP HL                           ; $133B  E1
        PUSH BC                          ; $133C  C5
        PUSH DE                          ; $133D  D5
        LD BC,$8100                      ; $133E  01 00 81
        LD D,C                           ; $1341  51
        LD E,D                           ; $1342  5A
        LD A,(HL)                        ; $1343  7E
        CP TOK_STEP                      ; $1344  FE E0
        LD A,$01                         ; $1346  3E 01
        JR NZ,STMT_FOR_6                 ; $1348  20 0E
        CALL FRMEVL_LOWPREC              ; $134A  CD 91 1A
        PUSH HL                          ; $134D  E5
        CALL FN_CINT                     ; $134E  CD 6C 2C
        CALL FP_LOAD_FAC                 ; $1351  CD 33 2B
        CALL FP_SIGN                     ; $1354  CD C5 2A
STMT_FOR_5:
        POP HL                           ; $1357  E1
STMT_FOR_6:
        PUSH BC                          ; $1358  C5
        PUSH DE                          ; $1359  D5
        LD C,A                           ; $135A  4F
        CALL FRMEVL_TEST_TYPE            ; $135B  CD E3 1D
        LD B,A                           ; $135E  47
        PUSH BC                          ; $135F  C5
        DEC HL                           ; $1360  2B
        CALL CHRGET                      ; $1361  CD E4 13
        JP NZ,RAISE_SYNTAX_ERROR         ; $1364  C2 92 0D
        CALL BLOCK_SCAN_FORNEXT          ; $1367  CD D1 24
        CALL CHRGET                      ; $136A  CD E4 13
        PUSH HL                          ; $136D  E5
        PUSH HL                          ; $136E  E5
        LD HL,(SUB_0C4B_11)              ; $136F  2A 94 0C
        LD (SAVTXT),HL                   ; $1372  22 67 08
        LD HL,(DATA_LINE_TXTPTR_3)       ; $1375  2A 77 0B
        EX (SP),HL                       ; $1378  E3
        LD B,$82                         ; $1379  06 82
        PUSH BC                          ; $137B  C5
        INC SP                           ; $137C  33
        PUSH AF                          ; $137D  F5
        PUSH AF                          ; $137E  F5
        JP STMT_NEXT_1+1                 ; $137F  C3 52 47
STMT_FOR_7:
        LD B,$82                         ; $1382  06 82
        PUSH BC                          ; $1384  C5
        INC SP                           ; $1385  33
STMT_FOR_8:
        PUSH HL                          ; $1386  E5
STMT_FOR_9:
        CALL $0000                       ; $1387  CD 00 00
        POP HL                           ; $138A  E1
        OR A                             ; $138B  B7
        CALL NZ,INKEY_SCAN               ; $138C  C4 37 44
        LD (OLDTXT),HL                   ; $138F  22 7F 0B
        LD (SAVSTK),SP                   ; $1392  ED 73 81 0B
        LD A,(HL)                        ; $1396  7E
        CP $3A                           ; $1397  FE 3A
        JR Z,STMT_FOR_12                 ; $1399  28 29
        OR A                             ; $139B  B7
        JP NZ,RAISE_SYNTAX_ERROR         ; $139C  C2 92 0D
        INC HL                           ; $139F  23
STMT_FOR_10:
        LD A,(HL)                        ; $13A0  7E
        INC HL                           ; $13A1  23
        OR (HL)                          ; $13A2  B6
        JP Z,PROGRAM_END                 ; $13A3  CA 51 0D
        INC HL                           ; $13A6  23
        LD E,(HL)                        ; $13A7  5E
        INC HL                           ; $13A8  23
        LD D,(HL)                        ; $13A9  56
        EX DE,HL                         ; $13AA  EB
        LD (SAVTXT),HL                   ; $13AB  22 67 08
        LD A,(CHAIN_BREAK_FLAG_4)        ; $13AE  3A CE 0C
        OR A                             ; $13B1  B7
        JR Z,STMT_FOR_11                 ; $13B2  28 0F
        PUSH DE                          ; $13B4  D5
        LD A,$5B                         ; $13B5  3E 5B
        CALL OUTCHR                      ; $13B7  CD 91 42
        CALL FOUT                        ; $13BA  CD 91 33
        LD A,$5D                         ; $13BD  3E 5D
        CALL OUTCHR                      ; $13BF  CD 91 42
        POP DE                           ; $13C2  D1
STMT_FOR_11:
        EX DE,HL                         ; $13C3  EB
STMT_FOR_12:
        CALL CHRGET                      ; $13C4  CD E4 13
        LD DE,STMT_FOR_8                 ; $13C7  11 86 13
        PUSH DE                          ; $13CA  D5
        RET Z                            ; $13CB  C8
; [RE] Statement executor / dispatch. Token in A; SUB $81; if <0 not a statement; CP $5B reject tokens above the table; RLCA (index*2); index the statement-handler DEFW table at $0108 (addr = $0108 + (token-$81)*2), load handler into BC, PUSH BC, fall into CHRGET ($33C9) and RET to the handler. The graphics statement handlers (HOME..PLOT, tokens $C7-$D5) live in this table at $0194-$01B0.
NEWSTT_DISPATCH:
        SUB $81                          ; $13CC  D6 81
        JP C,STMT_LET                    ; $13CE  DA F6 15
        CP $5B                           ; $13D1  FE 5B
        JP NC,GETVAR_NAME_1              ; $13D3  D2 4F 20
        RLCA                             ; $13D6  07
        LD C,A                           ; $13D7  4F
        LD B,$00                         ; $13D8  06 00
        EX DE,HL                         ; $13DA  EB
        LD HL,STMT_DISPATCH_TBL          ; $13DB  21 08 01
        ADD HL,BC                        ; $13DE  09
        LD C,(HL)                        ; $13DF  4E
        INC HL                           ; $13E0  23
        LD B,(HL)                        ; $13E1  46
        PUSH BC                          ; $13E2  C5
        EX DE,HL                         ; $13E3  EB
; MS BASIC CHRGET: INC HL then fetch the next program/text char at (HL) into A, skipping spaces, returning C set if it is a digit (0-9) and Z set at end-of-line ($00)/end-of-statement. Expands the embedded constant-token forms ($0B-$1E line-number/constant tokens, $1C/$1E etc.) into their literal values. Entry SUB_33C9_1 ($33CA) = CHRGOT (re-fetch current char without advancing).
CHRGET:
        INC HL                           ; $13E4  23
; CHRGOT: re-fetch the current text char at (HL) into A without advancing (CHRGET minus the leading INC HL); sets C if digit, Z at end-of-line/statement; expands embedded constant tokens $0B-$1E.
CHRGOT:
        LD A,(HL)                        ; $13E5  7E
        CP $3A                           ; $13E6  FE 3A
        RET NC                           ; $13E8  D0
CHRGOT_1:
        CP $20                           ; $13E9  FE 20
        JR Z,CHRGET                      ; $13EB  28 F7
        JR NC,CHRGOT_RELOAD_PTR_8        ; $13ED  30 69
        OR A                             ; $13EF  B7
        RET Z                            ; $13F0  C8
        CP $0B                           ; $13F1  FE 0B
        JR C,CHRGOT_RELOAD_PTR_7         ; $13F3  38 5E
        CP $1E                           ; $13F5  FE 1E
        JR NZ,CHRGOT_2                   ; $13F7  20 05
        LD A,(SUB_0B2A_9)                ; $13F9  3A 3C 0B
        OR A                             ; $13FC  B7
        RET                              ; $13FD  C9
CHRGOT_2:
        CP $10                           ; $13FE  FE 10
        JR NZ,CHRGOT_RELOAD_PTR_1        ; $1400  20 05
; CHRGOT embedded-token continuation: on the $10-class constant token, reload the saved text pointer (TERM_POS_WORK+$10, $0B3A) and re-enter CHRGOT. Part of the in-place CHRGET/CHRGOT char-fetch + constant-token expansion ($13E0 area). Was SUB_1402. [RE]
CHRGOT_RELOAD_PTR:
        LD HL,(SUB_0B2A_8)               ; $1402  2A 3A 0B
        JR CHRGOT                        ; $1405  18 DE
CHRGOT_RELOAD_PTR_1:
        PUSH AF                          ; $1407  F5
        INC HL                           ; $1408  23
        LD (SUB_0B2A_9),A                ; $1409  32 3C 0B
        SUB $1C                          ; $140C  D6 1C
        JR NC,CHRGOT_RELOAD_PTR_6        ; $140E  30 28
        SUB $F5                          ; $1410  D6 F5
        JR NC,CHRGOT_RELOAD_PTR_2        ; $1412  30 06
        CP $FE                           ; $1414  FE FE
        JR NZ,CHRGOT_RELOAD_PTR_5        ; $1416  20 16
        LD A,(HL)                        ; $1418  7E
        INC HL                           ; $1419  23
CHRGOT_RELOAD_PTR_2:
        LD (SUB_0B2A_8),HL               ; $141A  22 3A 0B
CHRGOT_RELOAD_PTR_3:
        LD H,$00                         ; $141D  26 00
CHRGOT_RELOAD_PTR_4:
        LD L,A                           ; $141F  6F
        LD (SUB_0B2A_11),HL              ; $1420  22 3E 0B
        LD A,$02                         ; $1423  3E 02
        LD (SUB_0B2A_10),A               ; $1425  32 3D 0B
        LD HL,CHRGOT_RELOAD_PTR_9        ; $1428  21 5E 14
        POP AF                           ; $142B  F1
        OR A                             ; $142C  B7
        RET                              ; $142D  C9
CHRGOT_RELOAD_PTR_5:
        LD A,(HL)                        ; $142E  7E
        INC HL                           ; $142F  23
        INC HL                           ; $1430  23
        LD (SUB_0B2A_8),HL               ; $1431  22 3A 0B
        DEC HL                           ; $1434  2B
        LD H,(HL)                        ; $1435  66
        JR CHRGOT_RELOAD_PTR_4           ; $1436  18 E7
CHRGOT_RELOAD_PTR_6:
        INC A                            ; $1438  3C
        RLCA                             ; $1439  07
        LD (SUB_0B2A_10),A               ; $143A  32 3D 0B
        PUSH DE                          ; $143D  D5
        PUSH BC                          ; $143E  C5
        LD DE,SUB_0B2A_11                ; $143F  11 3E 0B
        EX DE,HL                         ; $1442  EB
        LD B,A                           ; $1443  47
        CALL FP_MOVE_LOOP                ; $1444  CD 4B 2B
        EX DE,HL                         ; $1447  EB
        POP BC                           ; $1448  C1
        POP DE                           ; $1449  D1
        LD (SUB_0B2A_8),HL               ; $144A  22 3A 0B
        POP AF                           ; $144D  F1
        LD HL,CHRGOT_RELOAD_PTR_9        ; $144E  21 5E 14
        OR A                             ; $1451  B7
        RET                              ; $1452  C9
CHRGOT_RELOAD_PTR_7:
        CP $09                           ; $1453  FE 09
        JP NC,CHRGET                     ; $1455  D2 E4 13
CHRGOT_RELOAD_PTR_8:
        CP $30                           ; $1458  FE 30
        CCF                              ; $145A  3F
        INC A                            ; $145B  3C
        DEC A                            ; $145C  3D
        RET                              ; $145D  C9
CHRGOT_RELOAD_PTR_9:
        LD E,$10                         ; $145E  1E 10
; [RE] CHRGOT constant-token tail: for the embedded numeric-constant tokens ($0B-$1E) decoded by CHRGOT, materialise the literal value into FAC ($0CB1/$0CB3) and value-type ($0B14), then resume the char scan at CHRGOT_3 ($33E7).
CHRGOT_CONST_VALUE:
        LD A,(SUB_0B2A_9)                ; $1460  3A 3C 0B
        CP $0F                           ; $1463  FE 0F
        JR NC,CHRGOT_CONST_VALUE_2       ; $1465  30 16
        CP $0D                           ; $1467  FE 0D
        JR C,CHRGOT_CONST_VALUE_2        ; $1469  38 12
        LD HL,(SUB_0B2A_11)              ; $146B  2A 3E 0B
        JR NZ,CHRGOT_CONST_VALUE_1       ; $146E  20 07
        INC HL                           ; $1470  23
        INC HL                           ; $1471  23
        INC HL                           ; $1472  23
        LD E,(HL)                        ; $1473  5E
        INC HL                           ; $1474  23
        LD D,(HL)                        ; $1475  56
        EX DE,HL                         ; $1476  EB
CHRGOT_CONST_VALUE_1:
        CALL INT_TO_SNG                  ; $1477  CD 6C 2E
        JP CHRGOT_RELOAD_PTR             ; $147A  C3 02 14
CHRGOT_CONST_VALUE_2:
        LD A,(SUB_0B2A_10)               ; $147D  3A 3D 0B
        LD (SUB_0B2A_5),A                ; $1480  32 37 0B
        CP $08                           ; $1483  FE 08
        JR Z,CHRGOT_CONST_VALUE_3        ; $1485  28 0F
        LD HL,(SUB_0B2A_11)              ; $1487  2A 3E 0B
        LD (CHAIN_BREAK_FLAG_9),HL       ; $148A  22 D4 0C
        LD HL,(SUB_0B2A_12)              ; $148D  2A 40 0B
        LD (CHAIN_BREAK_FLAG_10),HL      ; $1490  22 D6 0C
        JP CHRGOT_RELOAD_PTR             ; $1493  C3 02 14
CHRGOT_CONST_VALUE_3:
        LD HL,SUB_0B2A_11                ; $1496  21 3E 0B
        CALL FP_ARG_SETUP1               ; $1499  CD 6A 2B
        JP CHRGOT_RELOAD_PTR             ; $149C  C3 02 14
; [RE] DEFSTR statement handler (token $A9): declare a default-string letter range. DEFINT/DEFSNG/DEFDBL ($AA-$AC) enter a few bytes later with a different type code.
STMT_DEFSTR:
        LD E,$03                         ; $149F  1E 03
STMT_DEFSTR_1:
        LD BC,$021E                      ; $14A1  01 1E 02
STMT_DEFSTR_2:
        LD BC,$041E                      ; $14A4  01 1E 04
STMT_DEFSTR_3:
        LD BC,$081E                      ; $14A7  01 1E 08
STMT_DEFSTR_4:
        CALL IS_LETTER                   ; $14AA  CD BE 46
        LD BC,RAISE_SYNTAX_ERROR         ; $14AD  01 92 0D
        PUSH BC                          ; $14B0  C5
        RET C                            ; $14B1  D8
        SUB $41                          ; $14B2  D6 41
        LD C,A                           ; $14B4  4F
        LD B,A                           ; $14B5  47
        CALL CHRGET                      ; $14B6  CD E4 13
        CP TOK_MINUS                     ; $14B9  FE F3
        JR NZ,STMT_DEFSTR_5              ; $14BB  20 0D
        CALL CHRGET                      ; $14BD  CD E4 13
        CALL IS_LETTER                   ; $14C0  CD BE 46
        RET C                            ; $14C3  D8
        SUB $41                          ; $14C4  D6 41
        LD B,A                           ; $14C6  47
        CALL CHRGET                      ; $14C7  CD E4 13
STMT_DEFSTR_5:
        LD A,B                           ; $14CA  78
        SUB C                            ; $14CB  91
        RET C                            ; $14CC  D8
        INC A                            ; $14CD  3C
        EX (SP),HL                       ; $14CE  E3
        LD HL,VARTAB_4                   ; $14CF  21 9A 0B
        LD B,$00                         ; $14D2  06 00
        ADD HL,BC                        ; $14D4  09
STMT_DEFSTR_6:
        LD (HL),E                        ; $14D5  73
        INC HL                           ; $14D6  23
        DEC A                            ; $14D7  3D
        JR NZ,STMT_DEFSTR_6              ; $14D8  20 FB
        POP HL                           ; $14DA  E1
        LD A,(HL)                        ; $14DB  7E
        CP $2C                           ; $14DC  FE 2C
        RET NZ                           ; $14DE  C0
        CALL CHRGET                      ; $14DF  CD E4 13
        JR STMT_DEFSTR_4                 ; $14E2  18 C6
; [RE] CHRGET then GETINT-positive: advances the text pointer, evaluates an expr to a signed 16-bit int (via SUB_34CC); used where a leading char must be skipped first (e.g. WIDTH/coord parsers at $60DD/$60F5/$7F41/$7F7F)
GETINT_CHRGET_POS:
        CALL CHRGET                      ; $14E4  CD E4 13
; [RE] GETINT requiring a non-negative result: CALL GETINT; RET P if the high byte (D) is sign-positive (0..$7FFF), else fall into SUB_34CC_1 which loads E=$05 and JP RAISE_ERROR -> 'Illegal function call' (FC). Widely used by graphics/coord and array parsers
GETINT_POSITIVE:
        CALL GETINT                      ; $14E7  CD A3 20
        RET P                            ; $14EA  F0
GETINT_POSITIVE_1:
        LD E,ERR_ILLEGAL_FUNCTION_CALL   ; $14EB  1E 05
        JP RAISE_ERROR                   ; $14ED  C3 AC 0D
; [RE] LINGET entry handling the '.' shortcut: if current char is '.' ($2E) substitute the current line number from $0B62 and CHRGET past it; otherwise fall into LINGET to parse an explicit decimal line number into DE.
LINGET_DOT:
        LD A,(HL)                        ; $14F0  7E
        CP $2E                           ; $14F1  FE 2E
        EX DE,HL                         ; $14F3  EB
        LD HL,(ERRLIN)                   ; $14F4  2A 85 0B
        EX DE,HL                         ; $14F7  EB
        JP Z,CHRGET                      ; $14F8  CA E4 13
; LINGET: DEC HL then parse a decimal line number from the text at (HL) into DE (range-checked); standard MS BASIC line-number reader used by GOTO/GOSUB/ON/RESUME/THEN.
LINGET:
        DEC HL                           ; $14FB  2B
; LINGET entry without the leading DEC HL: CHRGET the first char then parse the decimal line number into DE (LINGET re-entry used by ON-GOTO list scanning).
LINGET_NEXT:
        CALL CHRGET                      ; $14FC  CD E4 13
        CP $0E                           ; $14FF  FE 0E
        JP Z,LINGET_TOKLINE              ; $1501  CA 06 15
        CP $0D                           ; $1504  FE 0D
; [RE] LINGET digit-accumulation loop: read ASCII digits, DE = DE*10 + digit (via the *10 sequence and $1998 overflow guard at SUB_691F) until a non-digit; returns the parsed line number in DE.
LINGET_TOKLINE:
        EX DE,HL                         ; $1506  EB
        LD HL,(SUB_0B2A_11)              ; $1507  2A 3E 0B
        EX DE,HL                         ; $150A  EB
        JP Z,CHRGET                      ; $150B  CA E4 13
        DEC HL                           ; $150E  2B
        LD DE,$0000                      ; $150F  11 00 00
LINGET_TOKLINE_1:
        CALL CHRGET                      ; $1512  CD E4 13
        RET NC                           ; $1515  D0
        PUSH HL                          ; $1516  E5
        PUSH AF                          ; $1517  F5
        LD HL,INPUT_PARSE_VALUES_4+1     ; $1518  21 98 19
        CALL CMP_HL_DE                   ; $151B  CD 9D 45
        JR C,LINGET_TOKLINE_2            ; $151E  38 11
        LD H,D                           ; $1520  62
        LD L,E                           ; $1521  6B
        ADD HL,DE                        ; $1522  19
        ADD HL,HL                        ; $1523  29
        ADD HL,DE                        ; $1524  19
        ADD HL,HL                        ; $1525  29
        POP AF                           ; $1526  F1
        SUB $30                          ; $1527  D6 30
        LD E,A                           ; $1529  5F
        LD D,$00                         ; $152A  16 00
        ADD HL,DE                        ; $152C  19
        EX DE,HL                         ; $152D  EB
        POP HL                           ; $152E  E1
        JR LINGET_TOKLINE_1              ; $152F  18 E1
LINGET_TOKLINE_2:
        POP AF                           ; $1531  F1
        POP HL                           ; $1532  E1
        RET                              ; $1533  C9
; [RE] RUN statement handler (token $8A): clears variables and begins execution at the start (or a given line).
STMT_RUN:
        JP Z,CLEAR_RESET_DATAPTR         ; $1534  CA 0B 45
        CP $0E                           ; $1537  FE 0E
        JR Z,STMT_RUN_1                  ; $1539  28 05
        CP $0D                           ; $153B  FE 0D
        JP NZ,OPEN_NAMED_FILE_1          ; $153D  C2 FD 53
STMT_RUN_1:
        CALL CLEAR_RESET_STORAGE         ; $1540  CD 0F 45
        LD BC,STMT_FOR_8                 ; $1543  01 86 13
        JR STMT_GOSUB_1                  ; $1546  18 17
; [RE] GOSUB statement handler (token $8D): pushes a return frame then transfers like GOTO.
STMT_GOSUB:
        LD C,$03                         ; $1548  0E 03
        CALL CHECK_STACK_ROOM            ; $154A  CD 9F 44
        CALL LINGET                      ; $154D  CD FB 14
        POP BC                           ; $1550  C1
        PUSH HL                          ; $1551  E5
        PUSH HL                          ; $1552  E5
        LD HL,(SAVTXT)                   ; $1553  2A 67 08
        EX (SP),HL                       ; $1556  E3
        LD A,$8D                         ; $1557  3E 8D
        PUSH AF                          ; $1559  F5
        INC SP                           ; $155A  33
        PUSH BC                          ; $155B  C5
        JP STMT_GOTO_1                   ; $155C  C3 63 15
STMT_GOSUB_1:
        PUSH BC                          ; $155F  C5
; [RE] GOTO statement handler (token $89): parses a line number, FNDLIN search, sets the text pointer.
STMT_GOTO:
        CALL LINGET                      ; $1560  CD FB 14
STMT_GOTO_1:
        LD A,(SUB_0B2A_9)                ; $1563  3A 3C 0B
        CP $0D                           ; $1566  FE 0D
        EX DE,HL                         ; $1568  EB
        RET Z                            ; $1569  C8
        EX DE,HL                         ; $156A  EB
        PUSH HL                          ; $156B  E5
        LD HL,(SUB_0B2A_8)               ; $156C  2A 3A 0B
        EX (SP),HL                       ; $156F  E3
        CALL STMT_DATA+2                 ; $1570  CD D1 15
        INC HL                           ; $1573  23
        PUSH HL                          ; $1574  E5
        LD HL,(SAVTXT)                   ; $1575  2A 67 08
        CALL CMP_HL_DE                   ; $1578  CD 9D 45
        POP HL                           ; $157B  E1
        CALL C,FNDLIN_LOOP               ; $157C  DC AE 0F
        CALL NC,FNDLIN                   ; $157F  D4 AB 0F
        JR NC,STMT_GOTO_2                ; $1582  30 0D
        DEC BC                           ; $1584  0B
        LD A,$0D                         ; $1585  3E 0D
        LD (DATA_LINE_TXTPTR_4),A        ; $1587  32 79 0B
        POP HL                           ; $158A  E1
        CALL RENUM_STORE_LINEREF         ; $158B  CD 1D 24
        LD H,B                           ; $158E  60
        LD L,C                           ; $158F  69
        RET                              ; $1590  C9
STMT_GOTO_2:
        LD E,ERR_UNDEFINED_LINE_NUMBER   ; $1591  1E 08
        JP RAISE_ERROR                   ; $1593  C3 AC 0D
; [RE] POP statement handler (token $AE): discard the top GOSUB return frame.
STMT_POP:
        LD (DATA_LINE_TXTPTR_3),HL       ; $1596  22 77 0B
        LD D,$FF                         ; $1599  16 FF
        CALL STKFRAME_SCAN_INIT          ; $159B  CD 20 0D
        LD SP,HL                         ; $159E  F9
        LD (SAVSTK),HL                   ; $159F  22 81 0B
        CP $8D                           ; $15A2  FE 8D
        JR NZ,STMT_RETURN_1              ; $15A4  20 1A
        LD HL,$0004                      ; $15A6  21 04 00
        ADD HL,SP                        ; $15A9  39
        LD (SAVSTK),HL                   ; $15AA  22 81 0B
        LD SP,HL                         ; $15AD  F9
        LD HL,(DATA_LINE_TXTPTR_3)       ; $15AE  2A 77 0B
        JP STMT_FOR_8                    ; $15B1  C3 86 13
; [RE] RETURN statement handler (token $8E): pops the GOSUB return frame and resumes.
STMT_RETURN:
        RET NZ                           ; $15B4  C0
        LD D,$FF                         ; $15B5  16 FF
        CALL STKFRAME_SCAN_INIT          ; $15B7  CD 20 0D
        LD SP,HL                         ; $15BA  F9
        LD (SAVSTK),HL                   ; $15BB  22 81 0B
        CP $8D                           ; $15BE  FE 8D
STMT_RETURN_1:
        LD E,ERR_RETURN_WITHOUT_GOSUB    ; $15C0  1E 03
        JP NZ,RAISE_ERROR                ; $15C2  C2 AC 0D
        POP HL                           ; $15C5  E1
        LD (SAVTXT),HL                   ; $15C6  22 67 08
        LD HL,STMT_FOR_8                 ; $15C9  21 86 13
        EX (SP),HL                       ; $15CC  E3
        LD A,$E1                         ; $15CD  3E E1
; [RE] DATA statement handler (token $84): no-op at run time (scanned/skipped). COMMON (token $B3) also dispatches to this same entry.
STMT_DATA:
        LD BC,STOP_BREAK_1+2             ; $15CF  01 3A 0E
        NOP                              ; $15D2  00
        LD B,$00                         ; $15D3  06 00
STMT_DATA_1:
        LD A,C                           ; $15D5  79
        LD C,B                           ; $15D6  48
        LD B,A                           ; $15D7  47
STMT_DATA_2:
        DEC HL                           ; $15D8  2B
STMT_DATA_3:
        CALL CHRGET                      ; $15D9  CD E4 13
        OR A                             ; $15DC  B7
        RET Z                            ; $15DD  C8
        CP B                             ; $15DE  B8
        RET Z                            ; $15DF  C8
        INC HL                           ; $15E0  23
        CP $22                           ; $15E1  FE 22
        JR Z,STMT_DATA_1                 ; $15E3  28 F0
        INC A                            ; $15E5  3C
        JR Z,STMT_DATA_3                 ; $15E6  28 F1
        SUB $8C                          ; $15E8  D6 8C
        JR NZ,STMT_DATA_2                ; $15EA  20 EC
        CP B                             ; $15EC  B8
        ADC A,D                          ; $15ED  8A
        LD D,A                           ; $15EE  57
        JR STMT_DATA_2                   ; $15EF  18 E7
STMT_DATA_4:
        POP AF                           ; $15F1  F1
        ADD A,$03                        ; $15F2  C6 03
        JR STMT_LET_1                    ; $15F4  18 15
; [RE] LET / implicit-assignment handler (token $88): evaluates RHS (CALL $5F35) and stores into the target variable.
STMT_LET:
        CALL PTRGET_1+1                  ; $15F6  CD B3 3B
        CALL SYNCHR                      ; $15F9  CD A3 45
        DEFB    TOK_EQ                   ; $15FC  F0  inline keyword-token arg consumed by the preceding CALL
        EX DE,HL                         ; $15FD  EB
        LD (DATA_LINE_TXTPTR_3),HL       ; $15FE  22 77 0B
        EX DE,HL                         ; $1601  EB
        PUSH DE                          ; $1602  D5
        LD A,(SUB_0B2A_5)                ; $1603  3A 37 0B
        PUSH AF                          ; $1606  F5
        CALL FRMEVL_NOPAREN              ; $1607  CD 90 1A
        POP AF                           ; $160A  F1
STMT_LET_1:
        EX (SP),HL                       ; $160B  E3
STMT_LET_2:
        LD B,A                           ; $160C  47
        LD A,(SUB_0B2A_5)                ; $160D  3A 37 0B
        CP B                             ; $1610  B8
        LD A,B                           ; $1611  78
        JR Z,STMT_LET_4                  ; $1612  28 06
        CALL FRMEVL_APPLY_OP             ; $1614  CD 1A 20
STMT_LET_3:
        LD A,(SUB_0B2A_5)                ; $1617  3A 37 0B
STMT_LET_4:
        LD DE,CHAIN_BREAK_FLAG_9         ; $161A  11 D4 0C
STMT_LET_5:
        CP $05                           ; $161D  FE 05
        JR C,STMT_LET_6                  ; $161F  38 03
        LD DE,CHAIN_BREAK_FLAG_6         ; $1621  11 D0 0C
STMT_LET_6:
        PUSH HL                          ; $1624  E5
        CP $03                           ; $1625  FE 03
        JR NZ,STMT_LET_9                 ; $1627  20 2E
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $1629  2A D4 0C
        PUSH HL                          ; $162C  E5
        INC HL                           ; $162D  23
        LD E,(HL)                        ; $162E  5E
        INC HL                           ; $162F  23
        LD D,(HL)                        ; $1630  56
        LD HL,(TXTTAB)                   ; $1631  2A 69 08
        CALL CMP_HL_DE                   ; $1634  CD 9D 45
        JR NC,STMT_LET_7+1               ; $1637  30 12
        LD HL,(VARTAB_2)                 ; $1639  2A 96 0B
        CALL CMP_HL_DE                   ; $163C  CD 9D 45
        POP DE                           ; $163F  D1
        JR NC,STMT_LET_8                 ; $1640  30 11
        LD HL,MEMSIZ_4                   ; $1642  21 68 0B
        CALL CMP_HL_DE                   ; $1645  CD 9D 45
        JR NC,STMT_LET_8                 ; $1648  30 09
STMT_LET_7:
        LD A,$D1                         ; $164A  3E D1
        CALL FREE_TOP_TEMP_DESCR         ; $164C  CD 57 4A
        EX DE,HL                         ; $164F  EB
        CALL STR_BUILD_FROM_DESC         ; $1650  CD 44 48
STMT_LET_8:
        CALL FREE_TOP_TEMP_DESCR         ; $1653  CD 57 4A
        EX (SP),HL                       ; $1656  E3
STMT_LET_9:
        CALL FP_MOVE_TYPED               ; $1657  CD 47 2B
        POP DE                           ; $165A  D1
        POP HL                           ; $165B  E1
        RET                              ; $165C  C9
; [RE] ON statement handler (token $95): ON..GOTO/GOSUB/ERROR computed branch (CP $A4 tests for ERROR).
STMT_ON:
        CP $A4                           ; $165D  FE A4
        JR NZ,STMT_ON_2                  ; $165F  20 2A
        CALL CHRGET                      ; $1661  CD E4 13
        CALL SYNCHR                      ; $1664  CD A3 45
        DEFB    TOK_GOTO                 ; $1667  89  inline keyword-token arg consumed by the preceding CALL
        CALL LINGET                      ; $1668  CD FB 14
        LD A,D                           ; $166B  7A
        OR E                             ; $166C  B3
        JR Z,STMT_ON_1                   ; $166D  28 09
        CALL FNDLIN_FROM_TEXT            ; $166F  CD A9 0F
        LD D,B                           ; $1672  50
        LD E,C                           ; $1673  59
        POP HL                           ; $1674  E1
        JP NC,STMT_GOTO_2                ; $1675  D2 91 15
STMT_ON_1:
        EX DE,HL                         ; $1678  EB
        LD (ERRLIN_2),HL                 ; $1679  22 89 0B
        EX DE,HL                         ; $167C  EB
        RET C                            ; $167D  D8
        LD A,(ONEFLG)                    ; $167E  3A 8B 0B
        OR A                             ; $1681  B7
        LD A,E                           ; $1682  7B
        RET Z                            ; $1683  C8
        LD A,(SUB_0752_31+2)             ; $1684  3A 58 08
        LD E,A                           ; $1687  5F
        JP ERROR_PRINT_SETUP             ; $1688  C3 C1 0D
STMT_ON_2:
        CALL GETBYT                      ; $168B  CD B2 20
        LD A,(HL)                        ; $168E  7E
        LD B,A                           ; $168F  47
        CP $8D                           ; $1690  FE 8D
        JR Z,STMT_ON_3                   ; $1692  28 05
        CALL SYNCHR                      ; $1694  CD A3 45
        DEFB    TOK_GOTO                 ; $1697  89  inline keyword-token arg consumed by the preceding CALL
        DEC HL                           ; $1698  2B
STMT_ON_3:
        LD C,E                           ; $1699  4B
STMT_ON_4:
        DEC C                            ; $169A  0D
        LD A,B                           ; $169B  78
        JP Z,NEWSTT_DISPATCH             ; $169C  CA CC 13
        CALL LINGET_NEXT                 ; $169F  CD FC 14
        CP $2C                           ; $16A2  FE 2C
        RET NZ                           ; $16A4  C0
        JR STMT_ON_4                     ; $16A5  18 F3
; [RE] RESUME statement handler (token $A5): return from an ON ERROR handler (RESUME/RESUME NEXT/RESUME line).
STMT_RESUME:
        LD DE,ONEFLG                     ; $16A7  11 8B 0B
        LD A,(DE)                        ; $16AA  1A
        OR A                             ; $16AB  B7
        JP Z,RAISE_RESUME_WITHOUT_ERROR  ; $16AC  CA A1 0D
        INC A                            ; $16AF  3C
        LD (SUB_0752_31+2),A             ; $16B0  32 58 08
        LD (DE),A                        ; $16B3  12
        LD A,(HL)                        ; $16B4  7E
        CP $83                           ; $16B5  FE 83
        JR Z,STMT_RESUME_1               ; $16B7  28 0C
        CALL LINGET                      ; $16B9  CD FB 14
        RET NZ                           ; $16BC  C0
        LD A,D                           ; $16BD  7A
        OR E                             ; $16BE  B3
        JP NZ,STMT_GOTO_1                ; $16BF  C2 63 15
        INC A                            ; $16C2  3C
        JR STMT_RESUME_2                 ; $16C3  18 04
STMT_RESUME_1:
        CALL CHRGET                      ; $16C5  CD E4 13
        RET NZ                           ; $16C8  C0
STMT_RESUME_2:
        LD HL,(ERRLIN_1)                 ; $16C9  2A 87 0B
        EX DE,HL                         ; $16CC  EB
        LD HL,(ERR_SAVTXT)               ; $16CD  2A 83 0B
        LD (SAVTXT),HL                   ; $16D0  22 67 08
        EX DE,HL                         ; $16D3  EB
        RET NZ                           ; $16D4  C0
        LD A,(HL)                        ; $16D5  7E
        OR A                             ; $16D6  B7
        JR NZ,STMT_RESUME_3              ; $16D7  20 04
        INC HL                           ; $16D9  23
        INC HL                           ; $16DA  23
        INC HL                           ; $16DB  23
        INC HL                           ; $16DC  23
STMT_RESUME_3:
        INC HL                           ; $16DD  23
        JP STMT_DATA                     ; $16DE  C3 CF 15
; [RE] ERROR statement handler (token $A4): force the given error code through the ERROR handler.
STMT_ERROR:
        CALL GETBYT                      ; $16E1  CD B2 20
        RET NZ                           ; $16E4  C0
        OR A                             ; $16E5  B7
        JP Z,GETINT_POSITIVE_1           ; $16E6  CA EB 14
        JP RAISE_ERROR                   ; $16E9  C3 AC 0D
; [RE] Parse an optional line-number range (default span $000A) via LINGET_DOT/LINGET, store the start/end pointers into the continue/trace cells $0B5A/$0B57/$0B58, then JP $0E3E to re-enter the NEWSTT main loop at that line.
SCAN_LINE_RANGE_RESUME:
        LD DE,$000A                      ; $16EC  11 0A 00
        PUSH DE                          ; $16EF  D5
        JR Z,SCAN_LINE_RANGE_RESUME_2    ; $16F0  28 19
        CALL LINGET_DOT                  ; $16F2  CD F0 14
        EX DE,HL                         ; $16F5  EB
        EX (SP),HL                       ; $16F6  E3
        JR Z,SCAN_LINE_RANGE_RESUME_3    ; $16F7  28 13
        EX DE,HL                         ; $16F9  EB
        CALL SYNCHR                      ; $16FA  CD A3 45
        DEFB    ','                      ; $16FD  2C  inline char arg consumed by the preceding CALL
        EX DE,HL                         ; $16FE  EB
SCAN_LINE_RANGE_RESUME_1:
        LD HL,(AUTINC)                   ; $16FF  2A 7D 0B
        EX DE,HL                         ; $1702  EB
        JR Z,SCAN_LINE_RANGE_RESUME_2    ; $1703  28 06
        CALL LINGET                      ; $1705  CD FB 14
        JP NZ,RAISE_SYNTAX_ERROR         ; $1708  C2 92 0D
SCAN_LINE_RANGE_RESUME_2:
        EX DE,HL                         ; $170B  EB
SCAN_LINE_RANGE_RESUME_3:
        LD A,H                           ; $170C  7C
        OR L                             ; $170D  B5
        JP Z,GETINT_POSITIVE_1           ; $170E  CA EB 14
        LD (AUTINC),HL                   ; $1711  22 7D 0B
        LD (AUTFLG),A                    ; $1714  32 7A 0B
        POP HL                           ; $1717  E1
        LD (AUTLIN),HL                   ; $1718  22 7B 0B
        POP BC                           ; $171B  C1
        JP DIRECT_LINE_DISPATCH          ; $171C  C3 61 0E
; [RE] IF statement handler: evaluate the condition via FRMEVL, skip an optional ',' and the THEN/GOTO token; if true, a following line-number token ($0E) means GOTO (JP STMT_GOTO) else execute the THEN clause via NEWSTT_DISPATCH; if false, scan forward over the matching ELSE ($9E) depth (SUB_3704_4) to the alternate/next line.
STMT_IF:
        CALL FRMEVL_NOPAREN              ; $171F  CD 90 1A
        LD A,(HL)                        ; $1722  7E
        CP $2C                           ; $1723  FE 2C
        CALL Z,CHRGET                    ; $1725  CC E4 13
        CP TOK_GOTO                      ; $1728  FE 89
        JR Z,STMT_IF_1                   ; $172A  28 05
        CALL SYNCHR                      ; $172C  CD A3 45
        DEFB    TOK_THEN                 ; $172F  DE  inline keyword-token arg consumed by the preceding CALL
        DEC HL                           ; $1730  2B
STMT_IF_1:
        PUSH HL                          ; $1731  E5
        CALL FP_TEST_SIGN                ; $1732  CD 06 2B
        POP HL                           ; $1735  E1
        JR Z,STMT_IF_3                   ; $1736  28 12
STMT_IF_2:
        CALL CHRGET                      ; $1738  CD E4 13
        RET Z                            ; $173B  C8
        CP $0E                           ; $173C  FE 0E
        JP Z,STMT_GOTO                   ; $173E  CA 60 15
        CP $0D                           ; $1741  FE 0D
        JP NZ,NEWSTT_DISPATCH            ; $1743  C2 CC 13
        LD HL,(SUB_0B2A_11)              ; $1746  2A 3E 0B
        RET                              ; $1749  C9
STMT_IF_3:
        LD D,$01                         ; $174A  16 01
STMT_IF_4:
        CALL STMT_DATA                   ; $174C  CD CF 15
        OR A                             ; $174F  B7
        RET Z                            ; $1750  C8
        CALL CHRGET                      ; $1751  CD E4 13
        CP TOK_ELSE                      ; $1754  FE 9E
        JR NZ,STMT_IF_4                  ; $1756  20 F4
        DEC D                            ; $1758  15
        JR NZ,STMT_IF_4                  ; $1759  20 F1
        JR STMT_IF_2                     ; $175B  18 DB
; [RE] LPRINT statement handler (token $9B): PRINT directed to the line printer; falls into the shared PRINT engine.
STMT_LPRINT:
        LD A,$01                         ; $175D  3E 01
        LD (SUB_0752_32+1),A             ; $175F  32 5B 08
        JP STMT_PRINT_1                  ; $1762  C3 6A 17
; PRINT statement engine (shared by PRINT/LPRINT/PRINT#): walk the print list emitting expressions, honour ',' tab zones and ';' (no-space), TAB($E8)/SPC($DF)/USING($E3) functions, and emit CRLF unless suppressed; column tracking via $0837/$0B11.
STMT_PRINT:
        LD C,$02                         ; $1765  0E 02
        CALL PARSE_FILENUM_HASH          ; $1767  CD 8D 52
STMT_PRINT_1:
        DEC HL                           ; $176A  2B
        CALL CHRGET                      ; $176B  CD E4 13
        CALL Z,CRLF                      ; $176E  CC 06 44
STMT_PRINT_2:
        JP Z,PRINT_RESET_STATE           ; $1771  CA 9A 18
        CP TOK_USING                     ; $1774  FE E8
        JP Z,PRINT_USING                 ; $1776  CA D6 40
        CP $DF                           ; $1779  FE DF
        JP Z,STMT_PRINT_11               ; $177B  CA 20 18
        CP $E3                           ; $177E  FE E3
        JP Z,STMT_PRINT_11               ; $1780  CA 20 18
        PUSH HL                          ; $1783  E5
        CP $2C                           ; $1784  FE 2C
        JR Z,STMT_PRINT_7                ; $1786  28 5E
        CP $3B                           ; $1788  FE 3B
        JP Z,STMT_PRINT_21               ; $178A  CA 93 18
        POP BC                           ; $178D  C1
        CALL FRMEVL_NOPAREN              ; $178E  CD 90 1A
        PUSH HL                          ; $1791  E5
        CALL FRMEVL_TEST_TYPE            ; $1792  CD E3 1D
        JR Z,STMT_PRINT_3                ; $1795  28 0C
        CALL FOUT_2                      ; $1797  CD A0 33
        CALL SCAN_STR_LITERAL            ; $179A  CD 68 48
        LD (HL),$20                      ; $179D  36 20
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $179F  2A D4 0C
        INC (HL)                         ; $17A2  34
STMT_PRINT_3:
        LD HL,(PTRFIL)                   ; $17A3  2A 63 08
        LD A,H                           ; $17A6  7C
        OR L                             ; $17A7  B5
        JR NZ,STMT_PRINT_6               ; $17A8  20 35
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $17AA  2A D4 0C
        LD A,(SUB_0752_32+1)             ; $17AD  3A 5B 08
        OR A                             ; $17B0  B7
        JR Z,STMT_PRINT_4                ; $17B1  28 16
        LD A,(SUB_0752_33)               ; $17B3  3A 5D 08
        LD B,A                           ; $17B6  47
        INC A                            ; $17B7  3C
        JP Z,STMT_PRINT_6                ; $17B8  CA DF 17
        LD A,(SUB_0752_32)               ; $17BB  3A 5A 08
        OR A                             ; $17BE  B7
        JP Z,STMT_PRINT_6                ; $17BF  CA DF 17
        ADD A,(HL)                       ; $17C2  86
        CCF                              ; $17C3  3F
        JR NC,STMT_PRINT_5               ; $17C4  30 16
        CP B                             ; $17C6  B8
        JR STMT_PRINT_5                  ; $17C7  18 13
STMT_PRINT_4:
        LD A,(SUB_0752_34)               ; $17C9  3A 5E 08
        LD B,A                           ; $17CC  47
        INC A                            ; $17CD  3C
        JR Z,STMT_PRINT_6                ; $17CE  28 0F
        LD A,(SUB_0B2A_2)                ; $17D0  3A 34 0B
        OR A                             ; $17D3  B7
        JR Z,STMT_PRINT_6                ; $17D4  28 09
        ADD A,(HL)                       ; $17D6  86
        CCF                              ; $17D7  3F
        JR NC,STMT_PRINT_5               ; $17D8  30 02
        DEC A                            ; $17DA  3D
        CP B                             ; $17DB  B8
STMT_PRINT_5:
        CALL NC,CRLF                     ; $17DC  D4 06 44
STMT_PRINT_6:
        CALL STRPRT                      ; $17DF  CD C1 48
        POP HL                           ; $17E2  E1
        JP STMT_PRINT_1                  ; $17E3  C3 6A 17
STMT_PRINT_7:
        LD HL,(PTRFIL)                   ; $17E6  2A 63 08
        LD A,H                           ; $17E9  7C
        OR L                             ; $17EA  B5
        LD BC,$0028                      ; $17EB  01 28 00
        ADD HL,BC                        ; $17EE  09
        LD A,(HL)                        ; $17EF  7E
        JR NZ,STMT_PRINT_10              ; $17F0  20 26
        LD A,(SUB_0752_32+1)             ; $17F2  3A 5B 08
        OR A                             ; $17F5  B7
        JR Z,STMT_PRINT_8                ; $17F6  28 0E
        LD A,(SUB_0752_32+2)             ; $17F8  3A 5C 08
        LD B,A                           ; $17FB  47
        INC A                            ; $17FC  3C
        LD A,(SUB_0752_32)               ; $17FD  3A 5A 08
        JR Z,STMT_PRINT_10               ; $1800  28 16
        CP B                             ; $1802  B8
        JP STMT_PRINT_9                  ; $1803  C3 12 18
STMT_PRINT_8:
        LD A,(SUB_0752_35+1)             ; $1806  3A 60 08
        LD B,A                           ; $1809  47
        LD A,(SUB_0B2A_2)                ; $180A  3A 34 0B
        CP $FF                           ; $180D  FE FF
        JR Z,STMT_PRINT_10               ; $180F  28 07
        CP B                             ; $1811  B8
STMT_PRINT_9:
        CALL NC,CRLF                     ; $1812  D4 06 44
        JP NC,STMT_PRINT_21              ; $1815  D2 93 18
STMT_PRINT_10:
        SUB $0E                          ; $1818  D6 0E
        JR NC,STMT_PRINT_10              ; $181A  30 FC
        CPL                              ; $181C  2F
        JP STMT_PRINT_19                 ; $181D  C3 8A 18
STMT_PRINT_11:
        PUSH AF                          ; $1820  F5
        CALL CHRGET                      ; $1821  CD E4 13
        CALL GETINT                      ; $1824  CD A3 20
        POP AF                           ; $1827  F1
        PUSH AF                          ; $1828  F5
        CP $E3                           ; $1829  FE E3
        JR Z,STMT_PRINT_12               ; $182B  28 01
        DEC DE                           ; $182D  1B
STMT_PRINT_12:
        LD A,D                           ; $182E  7A
        OR A                             ; $182F  B7
        JP P,STMT_PRINT_13               ; $1830  F2 36 18
        LD DE,$0000                      ; $1833  11 00 00
STMT_PRINT_13:
        PUSH HL                          ; $1836  E5
STMT_PRINT_14:
        LD HL,(PTRFIL)                   ; $1837  2A 63 08
        LD A,H                           ; $183A  7C
        OR L                             ; $183B  B5
        JR NZ,STMT_PRINT_16              ; $183C  20 16
        LD A,(SUB_0752_32+1)             ; $183E  3A 5B 08
        OR A                             ; $1841  B7
        LD A,(SUB_0752_33)               ; $1842  3A 5D 08
        JR NZ,STMT_PRINT_15              ; $1845  20 03
        LD A,(SUB_0752_34)               ; $1847  3A 5E 08
STMT_PRINT_15:
        LD L,A                           ; $184A  6F
        INC A                            ; $184B  3C
        JR Z,STMT_PRINT_16               ; $184C  28 06
        LD H,$00                         ; $184E  26 00
        CALL INT_DIV_ROUND               ; $1850  CD 76 2E
        EX DE,HL                         ; $1853  EB
STMT_PRINT_16:
        POP HL                           ; $1854  E1
        CALL SYNCHR                      ; $1855  CD A3 45
        DEFB    ')'                      ; $1858  29  inline char arg consumed by the preceding CALL
        DEC HL                           ; $1859  2B
        POP AF                           ; $185A  F1
        SUB $E3                          ; $185B  D6 E3
        PUSH HL                          ; $185D  E5
        JR Z,STMT_PRINT_18               ; $185E  28 1B
        LD HL,(PTRFIL)                   ; $1860  2A 63 08
        LD A,H                           ; $1863  7C
        OR L                             ; $1864  B5
        LD BC,$0028                      ; $1865  01 28 00
        ADD HL,BC                        ; $1868  09
        LD A,(HL)                        ; $1869  7E
        JR NZ,STMT_PRINT_18              ; $186A  20 0F
        LD A,(SUB_0752_32+1)             ; $186C  3A 5B 08
        OR A                             ; $186F  B7
        JP Z,STMT_PRINT_17               ; $1870  CA 78 18
        LD A,(SUB_0752_32)               ; $1873  3A 5A 08
        JR STMT_PRINT_18                 ; $1876  18 03
STMT_PRINT_17:
        LD A,(SUB_0B2A_2)                ; $1878  3A 34 0B
STMT_PRINT_18:
        CPL                              ; $187B  2F
        ADD A,E                          ; $187C  83
        JR C,STMT_PRINT_19               ; $187D  38 0B
        INC A                            ; $187F  3C
        JR Z,STMT_PRINT_21               ; $1880  28 11
        CALL CRLF                        ; $1882  CD 06 44
        LD A,E                           ; $1885  7B
        DEC A                            ; $1886  3D
        JP M,STMT_PRINT_21               ; $1887  FA 93 18
STMT_PRINT_19:
        INC A                            ; $188A  3C
        LD B,A                           ; $188B  47
        LD A,$20                         ; $188C  3E 20
STMT_PRINT_20:
        CALL OUTCHR                      ; $188E  CD 91 42
        DJNZ STMT_PRINT_20               ; $1891  10 FB
STMT_PRINT_21:
        POP HL                           ; $1893  E1
        CALL CHRGET                      ; $1894  CD E4 13
        JP STMT_PRINT_2                  ; $1897  C3 71 17
; [RE] PRINT epilogue/reset: clear the LPRINT-direction flag $0838 and the file/device pointer $0840 back to console defaults at the end of a PRINT statement.
PRINT_RESET_STATE:
        XOR A                            ; $189A  AF
        LD (SUB_0752_32+1),A             ; $189B  32 5B 08
        PUSH HL                          ; $189E  E5
        LD H,A                           ; $189F  67
        LD L,A                           ; $18A0  6F
        LD (PTRFIL),HL                   ; $18A1  22 63 08
        POP HL                           ; $18A4  E1
        RET                              ; $18A5  C9
; [RE] LINE statement handler (token $AD): LINE INPUT (read a whole console line into a string).
STMT_LINE:
        CALL SYNCHR                      ; $18A6  CD A3 45
        DEFB    TOK_INPUT                ; $18A9  85  inline keyword-token arg consumed by the preceding CALL
        CP $23                           ; $18AA  FE 23
        JP Z,FN_CVI_5                    ; $18AC  CA 23 53
        CALL INPUT_PROMPT_SEP            ; $18AF  CD AC 4D
        CALL INPUT_PROMPT                ; $18B2  CD 1F 19
        CALL PTRGET_1+1                  ; $18B5  CD B3 3B
        CALL FP_INT_CHECK                ; $18B8  CD B3 2C
        PUSH DE                          ; $18BB  D5
        PUSH HL                          ; $18BC  E5
        CALL INLIN                       ; $18BD  CD A9 4C
        POP DE                           ; $18C0  D1
        POP BC                           ; $18C1  C1
        JP C,STMT_END_2+1                ; $18C2  DA E4 45
        PUSH BC                          ; $18C5  C5
        PUSH DE                          ; $18C6  D5
        LD B,$00                         ; $18C7  06 00
        CALL SCAN_STR_TERM               ; $18C9  CD 6B 48
        POP HL                           ; $18CC  E1
        LD A,$03                         ; $18CD  3E 03
        JP STMT_LET_1                    ; $18CF  C3 0B 16
; INPUT error literal "?Redo from start" + CR/LF; STROUT'd by the INPUT re-prompt path (STMT_LINE_2) when the user's typed reply does not parse. Bytes after the terminator are INPUT-path code rendered as DEFB.
MSG_REDO_FROM_START:
        CCF                              ; $18D2  3F
        LD D,D                           ; $18D3  52
        LD H,L                           ; $18D4  65
        LD H,H                           ; $18D5  64
        LD L,A                           ; $18D6  6F
        JR NZ,INPUT_PROMPT_1+2           ; $18D7  20 66
        LD (HL),D                        ; $18D9  72
        LD L,A                           ; $18DA  6F
        LD L,L                           ; $18DB  6D
        JR NZ,INPUT_EMIT_PROMPT_1+1      ; $18DC  20 73
        LD (HL),H                        ; $18DE  74
        LD H,C                           ; $18DF  61
        LD (HL),D                        ; $18E0  72
        LD (HL),H                        ; $18E1  74
        DEC C                            ; $18E2  0D
        LD A,(BC)                        ; $18E3  0A
        NOP                              ; $18E4  00
MSG_REDO_FROM_START_1:
        INC HL                           ; $18E5  23
        LD A,(HL)                        ; $18E6  7E
        OR A                             ; $18E7  B7
        JP Z,RAISE_SYNTAX_ERROR          ; $18E8  CA 92 0D
        CP $22                           ; $18EB  FE 22
        JR NZ,MSG_REDO_FROM_START_1      ; $18ED  20 F6
        JP INPUT_PARSE_VALUES_2          ; $18EF  C3 7D 19
MSG_REDO_FROM_START_2:
        POP HL                           ; $18F2  E1
        POP HL                           ; $18F3  E1
        JP MSG_REDO_FROM_START_4         ; $18F4  C3 FE 18
MSG_REDO_FROM_START_3:
        LD A,(DATA_LINE_TXTPTR_2)        ; $18F7  3A 76 0B
        OR A                             ; $18FA  B7
        JP NZ,CONT_RESUME_RESTORE        ; $18FB  C2 8C 0D
MSG_REDO_FROM_START_4:
        POP BC                           ; $18FE  C1
        LD HL,MSG_REDO_FROM_START        ; $18FF  21 D2 18
        CALL STROUT                      ; $1902  CD BE 48
        LD HL,(OLDTXT)                   ; $1905  2A 7F 0B
        RET                              ; $1908  C9
MSG_REDO_FROM_START_5:
        CALL GET_FILENUM_PREFIX_C1       ; $1909  CD 8B 52
        PUSH HL                          ; $190C  E5
        LD HL,SUB_0925_2                 ; $190D  21 30 0A
        JP INPUT_PARSE_VALUES_6          ; $1910  C3 CE 19
; [RE] INPUT statement handler (token $85): prompt + read console line, parse values into the variable list.
STMT_INPUT:
        CP $23                           ; $1913  FE 23
        JP Z,MSG_REDO_FROM_START_5       ; $1915  CA 09 19
        CALL INPUT_PROMPT_SEP            ; $1918  CD AC 4D
        LD BC,INPUT_EMIT_PROMPT          ; $191B  01 47 19
        PUSH BC                          ; $191E  C5
; [RE] INPUT prompt parser: if the next token is '"' read the quoted prompt string and emit it; the following ';' vs ',' sets the suppress-'?'-mark flag ($0C94) and trailing-comma flag ($083F); shared prompt setup before reading the console line.
INPUT_PROMPT:
        CP $22                           ; $191F  FE 22
        LD A,$00                         ; $1921  3E 00
        LD (CTRL_O_SUPPRESS),A           ; $1923  32 62 08
        LD A,$FF                         ; $1926  3E FF
        LD (INPUT_PROMPT_QMARK_FLAG),A   ; $1928  32 B7 0C
        RET NZ                           ; $192B  C0
        CALL SCAN_STR_QUOTE              ; $192C  CD 69 48
        LD A,(HL)                        ; $192F  7E
        CP $2C                           ; $1930  FE 2C
        JR NZ,INPUT_PROMPT_1             ; $1932  20 09
        XOR A                            ; $1934  AF
        LD (INPUT_PROMPT_QMARK_FLAG),A   ; $1935  32 B7 0C
        CALL CHRGET                      ; $1938  CD E4 13
        JR INPUT_PROMPT_2                ; $193B  18 04
INPUT_PROMPT_1:
        CALL SYNCHR                      ; $193D  CD A3 45
        DEFB    ';'                      ; $1940  3B  inline char arg consumed by the preceding CALL
INPUT_PROMPT_2:
        PUSH HL                          ; $1941  E5
        CALL STRPRT                      ; $1942  CD C1 48
        POP HL                           ; $1945  E1
        RET                              ; $1946  C9
; [RE] INPUT continuation (executable, rendered as DEFB): emits the '? ' prompt via OUTCHR, reads the console line (SUB_702B), and on empty/abort branches to STMT_END; falls through to the value-parse loop L_394D.
INPUT_EMIT_PROMPT:
        PUSH HL                          ; $1947  E5
        LD A,(INPUT_PROMPT_QMARK_FLAG)   ; $1948  3A B7 0C
        OR A                             ; $194B  B7
        JR Z,INPUT_EMIT_PROMPT_2         ; $194C  28 0A
        LD A,$3F                         ; $194E  3E 3F
INPUT_EMIT_PROMPT_1:
        CALL OUTCHR                      ; $1950  CD 91 42
        LD A,$20                         ; $1953  3E 20
        CALL OUTCHR                      ; $1955  CD 91 42
INPUT_EMIT_PROMPT_2:
        CALL INLIN                       ; $1958  CD A9 4C
        POP BC                           ; $195B  C1
        JP C,STMT_END_2+1                ; $195C  DA E4 45
        PUSH BC                          ; $195F  C5
        LD (HL),$2C                      ; $1960  36 2C
        EX DE,HL                         ; $1962  EB
        POP HL                           ; $1963  E1
        PUSH HL                          ; $1964  E5
        PUSH DE                          ; $1965  D5
        PUSH DE                          ; $1966  D5
        DEC HL                           ; $1967  2B
; [RE] INPUT value-parse loop (executable, rendered as DEFB): for each variable, read a field from the typed line (honouring quotes and ',' separators), convert and assign via STMT_LET_2; on mismatch jumps to the '?Redo from start' re-prompt (STMT_LINE_1/2).
INPUT_PARSE_VALUES:
        LD A,$80                         ; $1968  3E 80
        LD (DATA_LINE_TXTPTR_1),A        ; $196A  32 75 0B
        CALL CHRGET                      ; $196D  CD E4 13
        CALL PTRGET_1+1                  ; $1970  CD B3 3B
        LD A,(HL)                        ; $1973  7E
        DEC HL                           ; $1974  2B
        CP $28                           ; $1975  FE 28
        JR NZ,INPUT_PARSE_VALUES_3       ; $1977  20 19
        INC HL                           ; $1979  23
        LD B,$00                         ; $197A  06 00
INPUT_PARSE_VALUES_1:
        INC B                            ; $197C  04
INPUT_PARSE_VALUES_2:
        CALL CHRGET                      ; $197D  CD E4 13
        JP Z,RAISE_SYNTAX_ERROR          ; $1980  CA 92 0D
        CP $22                           ; $1983  FE 22
        JP Z,MSG_REDO_FROM_START_1       ; $1985  CA E5 18
        CP $28                           ; $1988  FE 28
        JR Z,INPUT_PARSE_VALUES_1        ; $198A  28 F0
        CP $29                           ; $198C  FE 29
        JR NZ,INPUT_PARSE_VALUES_2       ; $198E  20 ED
        DJNZ INPUT_PARSE_VALUES_2        ; $1990  10 EB
INPUT_PARSE_VALUES_3:
        CALL CHRGET                      ; $1992  CD E4 13
        JR Z,INPUT_PARSE_VALUES_5        ; $1995  28 05
INPUT_PARSE_VALUES_4:
        CP $2C                           ; $1997  FE 2C
        JP NZ,RAISE_SYNTAX_ERROR         ; $1999  C2 92 0D
INPUT_PARSE_VALUES_5:
        EX (SP),HL                       ; $199C  E3
        LD A,(HL)                        ; $199D  7E
        CP $2C                           ; $199E  FE 2C
        JP NZ,MSG_REDO_FROM_START_2      ; $19A0  C2 F2 18
        LD A,$01                         ; $19A3  3E 01
        LD (CHAIN_BREAK_FLAG_14),A       ; $19A5  32 DA 0C
        CALL STMT_READ_4+1               ; $19A8  CD F4 19
        LD A,(CHAIN_BREAK_FLAG_14)       ; $19AB  3A DA 0C
        DEC A                            ; $19AE  3D
        JP NZ,MSG_REDO_FROM_START_2      ; $19AF  C2 F2 18
        PUSH HL                          ; $19B2  E5
        CALL FRMEVL_TEST_TYPE            ; $19B3  CD E3 1D
        CALL Z,FRESTR                    ; $19B6  CC 3A 4A
        POP HL                           ; $19B9  E1
        DEC HL                           ; $19BA  2B
        CALL CHRGET                      ; $19BB  CD E4 13
        EX (SP),HL                       ; $19BE  E3
        LD A,(HL)                        ; $19BF  7E
        CP $2C                           ; $19C0  FE 2C
        JR Z,INPUT_PARSE_VALUES          ; $19C2  28 A4
        POP HL                           ; $19C4  E1
        DEC HL                           ; $19C5  2B
        CALL CHRGET                      ; $19C6  CD E4 13
        OR A                             ; $19C9  B7
        POP HL                           ; $19CA  E1
        JP NZ,MSG_REDO_FROM_START_4      ; $19CB  C2 FE 18
INPUT_PARSE_VALUES_6:
        LD (HL),$2C                      ; $19CE  36 2C
        JR STMT_READ_1+1                 ; $19D0  18 05
; [RE] READ statement handler (token $87): reads the next DATA item into a variable.
STMT_READ:
        PUSH HL                          ; $19D2  E5
        LD HL,(VARTAB_3)                 ; $19D3  2A 98 0B
STMT_READ_1:
        OR $AF                           ; $19D6  F6 AF
        LD (DATA_LINE_TXTPTR_2),A        ; $19D8  32 76 0B
        EX (SP),HL                       ; $19DB  E3
        JR STMT_READ_3                   ; $19DC  18 04
STMT_READ_2:
        CALL SYNCHR                      ; $19DE  CD A3 45
        DEFB    ','                      ; $19E1  2C  inline char arg consumed by the preceding CALL
STMT_READ_3:
        CALL PTRGET_1+1                  ; $19E2  CD B3 3B
        EX (SP),HL                       ; $19E5  E3
        PUSH DE                          ; $19E6  D5
        LD A,(HL)                        ; $19E7  7E
        CP $2C                           ; $19E8  FE 2C
        JR Z,STMT_READ_4                 ; $19EA  28 07
        LD A,(DATA_LINE_TXTPTR_2)        ; $19EC  3A 76 0B
        OR A                             ; $19EF  B7
        JP NZ,STMT_READ_11               ; $19F0  C2 63 1A
STMT_READ_4:
        OR $AF                           ; $19F3  F6 AF
        LD (SUB_0C4B_7),A                ; $19F5  32 8C 0C
        EX DE,HL                         ; $19F8  EB
        LD HL,(PTRFIL)                   ; $19F9  2A 63 08
        LD A,H                           ; $19FC  7C
        OR L                             ; $19FD  B5
        EX DE,HL                         ; $19FE  EB
        JP NZ,FN_CVI_4                   ; $19FF  C2 15 53
        CALL FRMEVL_TEST_TYPE            ; $1A02  CD E3 1D
        PUSH AF                          ; $1A05  F5
        JR NZ,STMT_READ_8                ; $1A06  20 2B
        CALL CHRGET                      ; $1A08  CD E4 13
        LD D,A                           ; $1A0B  57
        LD B,A                           ; $1A0C  47
        CP $22                           ; $1A0D  FE 22
        JR Z,STMT_READ_6                 ; $1A0F  28 0C
        LD A,(DATA_LINE_TXTPTR_2)        ; $1A11  3A 76 0B
        OR A                             ; $1A14  B7
        LD D,A                           ; $1A15  57
        JR Z,STMT_READ_5                 ; $1A16  28 02
        LD D,$3A                         ; $1A18  16 3A
STMT_READ_5:
        LD B,$2C                         ; $1A1A  06 2C
        DEC HL                           ; $1A1C  2B
STMT_READ_6:
        CALL SCAN_STR_BODY               ; $1A1D  CD 6C 48
STMT_READ_7:
        POP AF                           ; $1A20  F1
        ADD A,$03                        ; $1A21  C6 03
        LD C,A                           ; $1A23  4F
        LD A,(SUB_0C4B_7)                ; $1A24  3A 8C 0C
        OR A                             ; $1A27  B7
        RET Z                            ; $1A28  C8
        LD A,C                           ; $1A29  79
        EX DE,HL                         ; $1A2A  EB
        LD HL,STMT_READ_9                ; $1A2B  21 42 1A
        EX (SP),HL                       ; $1A2E  E3
        PUSH DE                          ; $1A2F  D5
        JP STMT_LET_2                    ; $1A30  C3 0C 16
STMT_READ_8:
        CALL CHRGET                      ; $1A33  CD E4 13
        POP AF                           ; $1A36  F1
        PUSH AF                          ; $1A37  F5
        LD BC,STMT_READ_7                ; $1A38  01 20 1A
        PUSH BC                          ; $1A3B  C5
        JP C,FIN_1+1                     ; $1A3C  DA 25 31
        JP FIN                           ; $1A3F  C3 1E 31
STMT_READ_9:
        DEC HL                           ; $1A42  2B
        CALL CHRGET                      ; $1A43  CD E4 13
        JR Z,STMT_READ_10                ; $1A46  28 05
        CP $2C                           ; $1A48  FE 2C
        JP NZ,MSG_REDO_FROM_START_3      ; $1A4A  C2 F7 18
STMT_READ_10:
        EX (SP),HL                       ; $1A4D  E3
        DEC HL                           ; $1A4E  2B
        CALL CHRGET                      ; $1A4F  CD E4 13
        JP NZ,STMT_READ_2                ; $1A52  C2 DE 19
        POP DE                           ; $1A55  D1
        LD A,(DATA_LINE_TXTPTR_2)        ; $1A56  3A 76 0B
        OR A                             ; $1A59  B7
        EX DE,HL                         ; $1A5A  EB
        JP NZ,STMT_RESTORE_3             ; $1A5B  C2 CA 45
        PUSH DE                          ; $1A5E  D5
        POP HL                           ; $1A5F  E1
        JP PRINT_RESET_STATE             ; $1A60  C3 9A 18
STMT_READ_11:
        CALL STMT_DATA                   ; $1A63  CD CF 15
        OR A                             ; $1A66  B7
        JR NZ,STMT_READ_12               ; $1A67  20 12
        INC HL                           ; $1A69  23
        LD A,(HL)                        ; $1A6A  7E
        INC HL                           ; $1A6B  23
        OR (HL)                          ; $1A6C  B6
        LD E,ERR_OUT_OF_DATA             ; $1A6D  1E 04
        JP Z,RAISE_ERROR                 ; $1A6F  CA AC 0D
        INC HL                           ; $1A72  23
        LD E,(HL)                        ; $1A73  5E
        INC HL                           ; $1A74  23
        LD D,(HL)                        ; $1A75  56
        EX DE,HL                         ; $1A76  EB
        LD (DATA_LINE_TXTPTR),HL         ; $1A77  22 73 0B
        EX DE,HL                         ; $1A7A  EB
STMT_READ_12:
        CALL CHRGET                      ; $1A7B  CD E4 13
        CP $84                           ; $1A7E  FE 84
        JR NZ,STMT_READ_11               ; $1A80  20 E1
        JP STMT_READ_4                   ; $1A82  C3 F3 19
; [RE] Evaluate-expression wrapper: SYNCHR the current char (advance past a required token), RET if at end-of-statement (P flag), else JP into FRMEVL to evaluate the following expression into FAC.
EVAL_EXPR_AFTER_SYNCHR:
        CALL SYNCHR                      ; $1A85  CD A3 45
        DEFB    TOK_EQ                   ; $1A88  F0  inline keyword-token arg consumed by the preceding CALL
        JP FRMEVL_NOPAREN                ; $1A89  C3 90 1A
; MS BASIC-80 FRMEVL: evaluate a complete expression (numeric or string) at (HL) into the FAC ($0CB1). $3A71 calls SYNCHR-context entry; $3A76/$3A78 is the precedence-driven operator loop: fetch an operand (EVAL, SUB_3BF6), then while the next token is a binary operator of high enough precedence, recurse and apply. Relational/arithmetic operator tokens >= $EF are handled here; precedence table at $04ED, operator-function dispatch table at $0517/$0503.
FRMEVL:
        CALL SYNCHR                      ; $1A8C  CD A3 45
        DEFB    '('                      ; $1A8F  28  inline char arg consumed by the preceding CALL
; [RE] Bare expression-evaluator entry (no leading '(' required): DEC HL to back up, then fall into the FRMEVL operator-precedence loop with D=0. The general 'evaluate expression at (HL) into FAC' call used throughout the parsers (60+ sites).
FRMEVL_NOPAREN:
        DEC HL                           ; $1A90  2B
; [RE] FRMEVL body entry with D=$00 (lowest operator precedence); falls into the precedence loop. Canonical MS BASIC-80 FRMEVL after the SYNCHR-context check.
FRMEVL_LOWPREC:
        LD D,$00                         ; $1A91  16 00
; [RE] FRMEVL operator-precedence loop: save pending-operator precedence (D), check stack, fetch one operand (FRMEVL_EVAL_OPERAND); then while the next token at (HL) is a binary operator (>= $EF) of precedence > pending, recurse here and apply. Relational vs arithmetic vs string-concat dispatch follows.
FRMEVL_OPLOOP:
        PUSH DE                          ; $1A93  D5
        LD C,$01                         ; $1A94  0E 01
        CALL CHECK_STACK_ROOM            ; $1A96  CD 9F 44
        CALL FRMEVL_EVAL_OPERAND         ; $1A99  CD 11 1C
        XOR A                            ; $1A9C  AF
        LD (CHAIN_BREAK_FLAG_13),A       ; $1A9D  32 D9 0C
FRMEVL_OPLOOP_1:
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $1AA0  22 8C 0B
FRMEVL_OPLOOP_2:
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $1AA3  2A 8C 0B
        POP BC                           ; $1AA6  C1
        LD A,(HL)                        ; $1AA7  7E
        LD (FRETOP_1),HL                 ; $1AA8  22 6D 0B
        CP TOK_GT                        ; $1AAB  FE EF
        RET C                            ; $1AAD  D8
        CP TOK_PLUS                      ; $1AAE  FE F2
        JP C,FRMEVL_RELOP                ; $1AB0  DA 1C 1B
        SUB TOK_PLUS                     ; $1AB3  D6 F2
        LD E,A                           ; $1AB5  5F
        JR NZ,FRMEVL_OPLOOP_3            ; $1AB6  20 09
        LD A,(SUB_0B2A_5)                ; $1AB8  3A 37 0B
        CP $03                           ; $1ABB  FE 03
        LD A,E                           ; $1ABD  7B
        JP Z,STR_CONCAT                  ; $1ABE  CA EE 49
FRMEVL_OPLOOP_3:
        CP $0C                           ; $1AC1  FE 0C
        RET NC                           ; $1AC3  D0
        LD HL,FRMEVL_PREC_TBL            ; $1AC4  21 ED 04
        LD D,$00                         ; $1AC7  16 00
        ADD HL,DE                        ; $1AC9  19
        LD A,B                           ; $1ACA  78
        LD D,(HL)                        ; $1ACB  56
        CP D                             ; $1ACC  BA
        RET NC                           ; $1ACD  D0
        PUSH BC                          ; $1ACE  C5
        LD BC,FRMEVL_OPLOOP_2            ; $1ACF  01 A3 1A
        PUSH BC                          ; $1AD2  C5
        LD A,D                           ; $1AD3  7A
        CP $7F                           ; $1AD4  FE 7F
        JP Z,FRMEVL_RELOP_2              ; $1AD6  CA 39 1B
        CP $51                           ; $1AD9  FE 51
        JP C,FRMEVL_RELOP_3              ; $1ADB  DA 46 1B
        AND $FE                          ; $1ADE  E6 FE
        CP $7A                           ; $1AE0  FE 7A
        JP Z,FRMEVL_RELOP_3              ; $1AE2  CA 46 1B
FRMEVL_OPLOOP_4:
        LD HL,CHAIN_BREAK_FLAG_9         ; $1AE5  21 D4 0C
        LD A,(SUB_0B2A_5)                ; $1AE8  3A 37 0B
        SUB $03                          ; $1AEB  D6 03
        JP Z,RAISE_TYPE_MISMATCH         ; $1AED  CA AA 0D
        OR A                             ; $1AF0  B7
        LD C,(HL)                        ; $1AF1  4E
        INC HL                           ; $1AF2  23
        LD B,(HL)                        ; $1AF3  46
        PUSH BC                          ; $1AF4  C5
        JP M,FRMEVL_OPLOOP_5             ; $1AF5  FA 0D 1B
        INC HL                           ; $1AF8  23
        LD C,(HL)                        ; $1AF9  4E
        INC HL                           ; $1AFA  23
        LD B,(HL)                        ; $1AFB  46
        PUSH BC                          ; $1AFC  C5
        JP PO,FRMEVL_OPLOOP_5            ; $1AFD  E2 0D 1B
        INC HL                           ; $1B00  23
        LD HL,CHAIN_BREAK_FLAG_6         ; $1B01  21 D0 0C
        LD C,(HL)                        ; $1B04  4E
        INC HL                           ; $1B05  23
        LD B,(HL)                        ; $1B06  46
        INC HL                           ; $1B07  23
        PUSH BC                          ; $1B08  C5
        LD C,(HL)                        ; $1B09  4E
        INC HL                           ; $1B0A  23
        LD B,(HL)                        ; $1B0B  46
        PUSH BC                          ; $1B0C  C5
FRMEVL_OPLOOP_5:
        ADD A,$03                        ; $1B0D  C6 03
        LD C,E                           ; $1B0F  4B
        LD B,A                           ; $1B10  47
        PUSH BC                          ; $1B11  C5
        LD BC,FRMEVL_OPCOMBINE           ; $1B12  01 6D 1B
FRMEVL_OPLOOP_6:
        PUSH BC                          ; $1B15  C5
        LD HL,(FRETOP_1)                 ; $1B16  2A 6D 0B
        JP FRMEVL_OPLOOP                 ; $1B19  C3 93 1A
; [RE] Relational-operator collector: tokens $EF-$F1 (=,<,>) accumulate a 3-bit relation mask in D (RLA/XOR), advancing past consecutive relation tokens via CHRGET; falls to FRMEVL_ARITHOP when a non-relation operator is seen.
FRMEVL_RELOP:
        LD D,$00                         ; $1B1C  16 00
FRMEVL_RELOP_1:
        SUB TOK_GT                       ; $1B1E  D6 EF
        JP C,FRMEVL_ARITHOP              ; $1B20  DA 51 1B
        CP $03                           ; $1B23  FE 03
        JP NC,FRMEVL_ARITHOP             ; $1B25  D2 51 1B
        CP $01                           ; $1B28  FE 01
        RLA                              ; $1B2A  17
        XOR D                            ; $1B2B  AA
        CP D                             ; $1B2C  BA
        LD D,A                           ; $1B2D  57
        JP C,RAISE_SYNTAX_ERROR          ; $1B2E  DA 92 0D
        LD (FRETOP_1),HL                 ; $1B31  22 6D 0B
        CALL CHRGET                      ; $1B34  CD E4 13
        JR FRMEVL_RELOP_1                ; $1B37  18 E5
FRMEVL_RELOP_2:
        CALL FN_CINT                     ; $1B39  CD 6C 2C
        CALL FAC_PUSH                    ; $1B3C  CD 18 2B
        LD BC,$3916                      ; $1B3F  01 16 39
        LD D,$7F                         ; $1B42  16 7F
        JR FRMEVL_OPLOOP_6               ; $1B44  18 CF
FRMEVL_RELOP_3:
        PUSH DE                          ; $1B46  D5
        CALL FN_LPOS                     ; $1B47  CD F4 2B
        POP DE                           ; $1B4A  D1
        PUSH HL                          ; $1B4B  E5
        LD BC,FRMEVL_INT_OP_HANDLER      ; $1B4C  01 F3 1D
        JR FRMEVL_OPLOOP_6               ; $1B4F  18 C4
; [RE] Arithmetic/string binary-operator apply: if pending precedence (B) < new operator precedence ($64 guard) push the FAC operand and recurse; sets up the operator-result combine via FRMEVL_OPCOMBINE.
FRMEVL_ARITHOP:
        LD A,B                           ; $1B51  78
        CP $64                           ; $1B52  FE 64
        RET NC                           ; $1B54  D0
        PUSH BC                          ; $1B55  C5
        PUSH DE                          ; $1B56  D5
        LD DE,$6404                      ; $1B57  11 04 64
        LD HL,FRMEVL_SCAN_UNARY_1        ; $1B5A  21 C2 1D
        PUSH HL                          ; $1B5D  E5
        CALL FRMEVL_TEST_TYPE            ; $1B5E  CD E3 1D
        JP NZ,FRMEVL_OPLOOP_4            ; $1B61  C2 E5 1A
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $1B64  2A D4 0C
        PUSH HL                          ; $1B67  E5
        LD BC,NEXT_LOOP_BODY_7           ; $1B68  01 01 48
        JR FRMEVL_OPLOOP_6               ; $1B6B  18 A8
; [RE] Operator-result combine: after the right operand is evaluated, recover operator code/type ($0B15/$0B14), coerce both operands to a common numeric type (CINT/CSNG paths) or take the string path ($08), then dispatch to the arithmetic operator routine via the $0517 (numeric) / $0503 (relational) vector tables.
FRMEVL_OPCOMBINE:
        POP BC                           ; $1B6D  C1
        LD A,C                           ; $1B6E  79
        LD (SUB_0B2A_6),A                ; $1B6F  32 38 0B
        LD A,(SUB_0B2A_5)                ; $1B72  3A 37 0B
        CP B                             ; $1B75  B8
        JR NZ,FRMEVL_OPCOMBINE_1         ; $1B76  20 0B
        CP $02                           ; $1B78  FE 02
        JR Z,FRMEVL_OPCOMBINE_2          ; $1B7A  28 1F
        CP $04                           ; $1B7C  FE 04
        JP Z,FRMEVL_OP_POP_FRAME         ; $1B7E  CA E7 1B
        JR NC,FRMEVL_OPCOMBINE_4         ; $1B81  30 2B
FRMEVL_OPCOMBINE_1:
        LD D,A                           ; $1B83  57
        LD A,B                           ; $1B84  78
        CP $08                           ; $1B85  FE 08
        JR Z,FRMEVL_OPCOMBINE_3          ; $1B87  28 22
        LD A,D                           ; $1B89  7A
        CP $08                           ; $1B8A  FE 08
        JR Z,FRMEVL_OPCOMBINE_9          ; $1B8C  28 44
        LD A,B                           ; $1B8E  78
        CP $04                           ; $1B8F  FE 04
        JR Z,FRMEVL_OP_COERCE_INT        ; $1B91  28 51
        LD A,D                           ; $1B93  7A
        CP $03                           ; $1B94  FE 03
        JP Z,RAISE_TYPE_MISMATCH         ; $1B96  CA AA 0D
        JR NC,FRMEVL_OP_DISPATCH_REL_1   ; $1B99  30 53
FRMEVL_OPCOMBINE_2:
        LD HL,OPERATOR_ROUTINE_TBL+30    ; $1B9B  21 17 05
        LD B,$00                         ; $1B9E  06 00
        ADD HL,BC                        ; $1BA0  09
        ADD HL,BC                        ; $1BA1  09
        LD C,(HL)                        ; $1BA2  4E
        INC HL                           ; $1BA3  23
        LD B,(HL)                        ; $1BA4  46
        POP DE                           ; $1BA5  D1
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $1BA6  2A D4 0C
        PUSH BC                          ; $1BA9  C5
        RET                              ; $1BAA  C9
FRMEVL_OPCOMBINE_3:
        CALL FN_CSNG                     ; $1BAB  CD 98 2C
FRMEVL_OPCOMBINE_4:
        CALL FP_ARG_TO_TEMP2             ; $1BAE  CD 6F 2B
        POP HL                           ; $1BB1  E1
        LD (CHAIN_BREAK_FLAG_7),HL       ; $1BB2  22 D2 0C
        POP HL                           ; $1BB5  E1
        LD (CHAIN_BREAK_FLAG_6),HL       ; $1BB6  22 D0 0C
FRMEVL_OPCOMBINE_5:
        POP BC                           ; $1BB9  C1
        POP DE                           ; $1BBA  D1
        CALL FP_STORE_FAC                ; $1BBB  CD 28 2B
FRMEVL_OPCOMBINE_6:
        CALL FN_CSNG                     ; $1BBE  CD 98 2C
        LD HL,OPERATOR_ROUTINE_TBL+10    ; $1BC1  21 03 05
FRMEVL_OPCOMBINE_7:
        LD A,(SUB_0B2A_6)                ; $1BC4  3A 38 0B
        RLCA                             ; $1BC7  07
        ADD A,L                          ; $1BC8  85
        LD L,A                           ; $1BC9  6F
FRMEVL_OPCOMBINE_8:
        ADC A,H                          ; $1BCA  8C
        SUB L                            ; $1BCB  95
        LD H,A                           ; $1BCC  67
        LD A,(HL)                        ; $1BCD  7E
        INC HL                           ; $1BCE  23
        LD H,(HL)                        ; $1BCF  66
        LD L,A                           ; $1BD0  6F
        JP (HL)                          ; $1BD1  E9
FRMEVL_OPCOMBINE_9:
        PUSH BC                          ; $1BD2  C5
        CALL FP_ARG_TO_TEMP2             ; $1BD3  CD 6F 2B
        POP AF                           ; $1BD6  F1
        LD (SUB_0B2A_5),A                ; $1BD7  32 37 0B
        CP $04                           ; $1BDA  FE 04
        JR Z,FRMEVL_OPCOMBINE_5          ; $1BDC  28 DB
        POP HL                           ; $1BDE  E1
        LD (CHAIN_BREAK_FLAG_9),HL       ; $1BDF  22 D4 0C
        JR FRMEVL_OPCOMBINE_6            ; $1BE2  18 DA
; [RE] FRMEVL operator-apply coercion (mis-split as DEFB, real code reached from FRMEVL_OPCOMBINE $3B76 when operand-type B==$04): CALL FN_CINT to force the operand to integer, then fall into FRMEVL_OP_POP_FRAME
FRMEVL_OP_COERCE_INT:
        CALL FN_CINT                     ; $1BE4  CD 6C 2C
; [RE] FRMEVL operator-apply (mis-split DEFB code, target of JP Z at $3B63 for string type): POP BC / POP DE to recover the operator/operand frame, then fall into FRMEVL_OP_DISPATCH_REL
FRMEVL_OP_POP_FRAME:
        POP BC                           ; $1BE7  C1
        POP DE                           ; $1BE8  D1
; [RE] FRMEVL operator-apply tail (mis-split DEFB code): LD HL,$050D (relational/string-op handler vector base) then JR back into the operator-result combine loop at ~$3BA9 to dispatch the pending operator
FRMEVL_OP_DISPATCH_REL:
        LD HL,OPERATOR_ROUTINE_TBL+20    ; $1BE9  21 0D 05
        JR FRMEVL_OPCOMBINE_7            ; $1BEC  18 D6
FRMEVL_OP_DISPATCH_REL_1:
        POP HL                           ; $1BEE  E1
        CALL FAC_PUSH                    ; $1BEF  CD 18 2B
        CALL INT_TO_SINGLE_HL            ; $1BF2  CD 8C 2C
        CALL FP_LOAD_FAC                 ; $1BF5  CD 33 2B
        POP HL                           ; $1BF8  E1
        LD (CHAIN_BREAK_FLAG_10),HL      ; $1BF9  22 D6 0C
        POP HL                           ; $1BFC  E1
        LD (CHAIN_BREAK_FLAG_9),HL       ; $1BFD  22 D4 0C
        JR FRMEVL_OP_DISPATCH_REL        ; $1C00  18 E7
        PUSH HL                          ; $1C02  E5
        EX DE,HL                         ; $1C03  EB
        CALL INT_TO_SINGLE_HL            ; $1C04  CD 8C 2C
        POP HL                           ; $1C07  E1
        CALL FAC_PUSH                    ; $1C08  CD 18 2B
        CALL INT_TO_SINGLE_HL            ; $1C0B  CD 8C 2C
        JP FDIV_BY_TEN_1                 ; $1C0E  C3 F1 29
; [RE] EVAL: fetch one operand/factor for FRMEVL. Parses a numeric constant (-> SUB_5F35 number scan), a parenthesized sub-expression, a string literal ($22), a variable reference, unary NOT ($E2)/minus, the FN call token ($E1), and the built-in function tokens (SCRN $CD/$EC/$ED, COLOR $D3, USR $E9, etc.) by dispatching to their FN_ handlers.
FRMEVL_EVAL_OPERAND:
        CALL CHRGET                      ; $1C11  CD E4 13
FRMEVL_EVAL_OPERAND_1:
        JP Z,RAISE_MISSING_OPERAND       ; $1C14  CA A7 0D
        JP C,FIN_1+1                     ; $1C17  DA 25 31
        CALL IS_LETTER_A                 ; $1C1A  CD BF 46
        JP NC,FRMEVL_PAREN_3             ; $1C1D  D2 D7 1C
        CP $20                           ; $1C20  FE 20
        JP C,CHRGOT_CONST_VALUE          ; $1C22  DA 60 14
        INC A                            ; $1C25  3C
        JP Z,SCAN_AMP_RADIX_CONST_7      ; $1C26  CA 56 1D
        DEC A                            ; $1C29  3D
        CP TOK_PLUS                      ; $1C2A  FE F2
        JR Z,FRMEVL_EVAL_OPERAND         ; $1C2C  28 E3
        CP TOK_MINUS                     ; $1C2E  FE F3
        JP Z,FRMEVL_PAREN_1              ; $1C30  CA C9 1C
        CP $22                           ; $1C33  FE 22
        JP Z,SCAN_STR_QUOTE              ; $1C35  CA 69 48
        CP TOK_NOT                       ; $1C38  FE E4
        JP Z,FRMEVL_SCAN_UNARY_2         ; $1C3A  CA CE 1D
        CP $26                           ; $1C3D  FE 26
        JP Z,SCAN_AMP_RADIX_CONST        ; $1C3F  CA F6 1C
        CP $E6                           ; $1C42  FE E6
        JR NZ,FRMEVL_EVAL_OPERAND_2      ; $1C44  20 0C
        CALL CHRGET                      ; $1C46  CD E4 13
        LD A,(SUB_0752_31+2)             ; $1C49  3A 58 08
        PUSH HL                          ; $1C4C  E5
        CALL FP_LOAD_INT_TO_FAC          ; $1C4D  CD 4D 1E
        POP HL                           ; $1C50  E1
        RET                              ; $1C51  C9
FRMEVL_EVAL_OPERAND_2:
        CP $E5                           ; $1C52  FE E5
        JR NZ,FRMEVL_EVAL_OPERAND_4      ; $1C54  20 0C
        CALL CHRGET                      ; $1C56  CD E4 13
        PUSH HL                          ; $1C59  E5
FRMEVL_EVAL_OPERAND_3:
        LD HL,(ERR_SAVTXT)               ; $1C5A  2A 83 0B
        CALL INT_TO_SNG                  ; $1C5D  CD 6C 2E
        POP HL                           ; $1C60  E1
        RET                              ; $1C61  C9
FRMEVL_EVAL_OPERAND_4:
        CP $EB                           ; $1C62  FE EB
        JR NZ,FRMEVL_EVAL_OPERAND_7      ; $1C64  20 29
        CALL CHRGET                      ; $1C66  CD E4 13
        CALL SYNCHR                      ; $1C69  CD A3 45
        DEFB    '('                      ; $1C6C  28  inline char arg consumed by the preceding CALL
        CP $23                           ; $1C6D  FE 23
        JR NZ,FRMEVL_EVAL_OPERAND_5      ; $1C6F  20 0B
        CALL GETBYT_CHRGET               ; $1C71  CD AF 20
        PUSH HL                          ; $1C74  E5
        CALL FCB_BUFFER_PTR              ; $1C75  CD CF 52
        POP HL                           ; $1C78  E1
        JP FRMEVL_EVAL_OPERAND_6         ; $1C79  C3 7F 1C
FRMEVL_EVAL_OPERAND_5:
        CALL PTRGET_1+1                  ; $1C7C  CD B3 3B
FRMEVL_EVAL_OPERAND_6:
        CALL SYNCHR                      ; $1C7F  CD A3 45
        DEFB    ')'                      ; $1C82  29  inline char arg consumed by the preceding CALL
        PUSH HL                          ; $1C83  E5
        EX DE,HL                         ; $1C84  EB
        LD A,H                           ; $1C85  7C
        OR L                             ; $1C86  B5
        JP Z,GETINT_POSITIVE_1           ; $1C87  CA EB 14
        CALL FP_STORE_FAC_INT            ; $1C8A  CD 55 2C
        POP HL                           ; $1C8D  E1
        RET                              ; $1C8E  C9
FRMEVL_EVAL_OPERAND_7:
        CP $E1                           ; $1C8F  FE E1
        JP Z,FP_LOAD_INT_TO_FAC_2        ; $1C91  CA 53 1E
        CP $E9                           ; $1C94  FE E9
        JP Z,FN_INSTR                    ; $1C96  CA 54 4B
        CP $CD                           ; $1C99  FE CD
        JP Z,GFX_FN_VPOS_3               ; $1C9B  CA 93 27
        CP $D3                           ; $1C9E  FE D3
        JP Z,SUB_2803_1+1                ; $1CA0  CA 0F 28
        CP $EC                           ; $1CA3  FE EC
        JP Z,GFX_FN_VPOS_2               ; $1CA5  CA 78 27
        CP $ED                           ; $1CA8  FE ED
        JP Z,SUB_2803_1+1                ; $1CAA  CA 0F 28
        CP $EE                           ; $1CAD  FE EE
        JP Z,INKEY_SCAN_2                ; $1CAF  CA 4A 44
        CP $E7                           ; $1CB2  FE E7
        JP Z,FN_STRING_STR               ; $1CB4  CA 91 4A
        CP TOK_INPUT                     ; $1CB7  FE 85
        JP Z,FIELD_PAD_SPACES_4          ; $1CB9  CA 65 56
        CP TOK_FN                        ; $1CBC  FE E2
        JP Z,STMT_DEF_2                  ; $1CBE  CA C8 1E
; [RE] Evaluate a parenthesised expression / get a 16-bit integer argument: calls FRMEVL then converts the FAC to an integer in DE (ADD HL,HL). Used by functions and subscript evaluation.
FRMEVL_PAREN:
        CALL FRMEVL                      ; $1CC1  CD 8C 1A
        CALL SYNCHR                      ; $1CC4  CD A3 45
        DEFB    ')'                      ; $1CC7  29  inline char arg consumed by the preceding CALL
        RET                              ; $1CC8  C9
FRMEVL_PAREN_1:
        LD D,$7D                         ; $1CC9  16 7D
        CALL FRMEVL_OPLOOP               ; $1CCB  CD 93 1A
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $1CCE  2A 8C 0B
        PUSH HL                          ; $1CD1  E5
        CALL FP_NEGATE_CHECKED           ; $1CD2  CD EB 2A
FRMEVL_PAREN_2:
        POP HL                           ; $1CD5  E1
        RET                              ; $1CD6  C9
FRMEVL_PAREN_3:
        CALL PTRGET_1+1                  ; $1CD7  CD B3 3B
FRMEVL_PAREN_4:
        PUSH HL                          ; $1CDA  E5
        EX DE,HL                         ; $1CDB  EB
        LD (CHAIN_BREAK_FLAG_9),HL       ; $1CDC  22 D4 0C
        CALL FRMEVL_TEST_TYPE            ; $1CDF  CD E3 1D
        CALL NZ,FP_ARG_SETUP1            ; $1CE2  C4 6A 2B
        POP HL                           ; $1CE5  E1
        RET                              ; $1CE6  C9
; [RE] Read char at (HL) and fold ASCII lowercase a-z ($61-$7A) to uppercase (AND $5F); leaves other chars unchanged. CRUNCH's case-insensitive keyword matcher uses this. SUB_3CCD ($3CCD) is the same fold applied to the char already in A.
CHRGET_UPCASE:
        LD A,(HL)                        ; $1CE7  7E
; Fold the char already in A from ASCII lowercase a-z ($61-$7A) to uppercase (AND $5F); other chars unchanged. Entry to CHRGET_UPCASE that skips the LD A,(HL); used by CRUNCH keyword matching and the &H/&O scanner
TOUPPER_A:
        CP $61                           ; $1CE8  FE 61
        RET C                            ; $1CEA  D8
        CP $7B                           ; $1CEB  FE 7B
        RET NC                           ; $1CED  D0
        AND $5F                          ; $1CEE  E6 5F
        RET                              ; $1CF0  C9
; [RE] Two-way operand guard: if the current char is '&' ($26) fall into the &H/&O radix-constant scanner, else JP LINGET to parse a decimal line number.
LINGET_OR_AMP:
        CP $26                           ; $1CF1  FE 26
        JP NZ,LINGET                     ; $1CF3  C2 FB 14
; [RE] '&' radix-literal scanner (FRMEVL reaches it at $3C24 on token $26): parses &H<hex> (ADD HL,HL x4 + nibble) and &O<octal> (ADD HL,HL x3 + digit) into HL, stores as an integer in the FAC via FP_STORE_FAC_INT; Overflow (E=$06,$0D81) on too many digits, Syntax ($0D6F) on a bad octal digit
SCAN_AMP_RADIX_CONST:
        LD DE,$0000                      ; $1CF6  11 00 00
        CALL CHRGET                      ; $1CF9  CD E4 13
        CALL TOUPPER_A                   ; $1CFC  CD E8 1C
        CP $4F                           ; $1CFF  FE 4F
        JR Z,SCAN_AMP_RADIX_CONST_5      ; $1D01  28 2F
        CP $48                           ; $1D03  FE 48
        JR NZ,SCAN_AMP_RADIX_CONST_4     ; $1D05  20 2A
        LD B,$05                         ; $1D07  06 05
SCAN_AMP_RADIX_CONST_1:
        INC HL                           ; $1D09  23
        LD A,(HL)                        ; $1D0A  7E
        CALL TOUPPER_A                   ; $1D0B  CD E8 1C
        CALL IS_LETTER_A                 ; $1D0E  CD BF 46
        EX DE,HL                         ; $1D11  EB
        JR NC,SCAN_AMP_RADIX_CONST_2     ; $1D12  30 0A
        CP $3A                           ; $1D14  FE 3A
        JR NC,SCAN_AMP_RADIX_CONST_6     ; $1D16  30 39
        SUB $30                          ; $1D18  D6 30
        JR C,SCAN_AMP_RADIX_CONST_6      ; $1D1A  38 35
        JR SCAN_AMP_RADIX_CONST_3        ; $1D1C  18 06
SCAN_AMP_RADIX_CONST_2:
        CP $47                           ; $1D1E  FE 47
        JR NC,SCAN_AMP_RADIX_CONST_6     ; $1D20  30 2F
        SUB $37                          ; $1D22  D6 37
SCAN_AMP_RADIX_CONST_3:
        ADD HL,HL                        ; $1D24  29
        ADD HL,HL                        ; $1D25  29
        ADD HL,HL                        ; $1D26  29
        ADD HL,HL                        ; $1D27  29
        OR L                             ; $1D28  B5
        LD L,A                           ; $1D29  6F
        DEC B                            ; $1D2A  05
        JP Z,RAISE_OVERFLOW              ; $1D2B  CA A4 0D
        EX DE,HL                         ; $1D2E  EB
        JR SCAN_AMP_RADIX_CONST_1        ; $1D2F  18 D8
SCAN_AMP_RADIX_CONST_4:
        DEC HL                           ; $1D31  2B
SCAN_AMP_RADIX_CONST_5:
        CALL CHRGET                      ; $1D32  CD E4 13
        EX DE,HL                         ; $1D35  EB
        JR NC,SCAN_AMP_RADIX_CONST_6     ; $1D36  30 19
        CP $38                           ; $1D38  FE 38
        JP NC,RAISE_SYNTAX_ERROR         ; $1D3A  D2 92 0D
        LD BC,RAISE_OVERFLOW             ; $1D3D  01 A4 0D
        PUSH BC                          ; $1D40  C5
        ADD HL,HL                        ; $1D41  29
        RET C                            ; $1D42  D8
        ADD HL,HL                        ; $1D43  29
        RET C                            ; $1D44  D8
        ADD HL,HL                        ; $1D45  29
        RET C                            ; $1D46  D8
        POP BC                           ; $1D47  C1
        LD B,$00                         ; $1D48  06 00
        SUB $30                          ; $1D4A  D6 30
        LD C,A                           ; $1D4C  4F
        ADD HL,BC                        ; $1D4D  09
        EX DE,HL                         ; $1D4E  EB
        JR SCAN_AMP_RADIX_CONST_5        ; $1D4F  18 E1
SCAN_AMP_RADIX_CONST_6:
        CALL FP_STORE_FAC_INT            ; $1D51  CD 55 2C
        EX DE,HL                         ; $1D54  EB
        RET                              ; $1D55  C9
SCAN_AMP_RADIX_CONST_7:
        INC HL                           ; $1D56  23
        LD A,(HL)                        ; $1D57  7E
        SUB $81                          ; $1D58  D6 81
        CP $07                           ; $1D5A  FE 07
        JR NZ,SCAN_AMP_RADIX_CONST_8     ; $1D5C  20 0C
        PUSH HL                          ; $1D5E  E5
        CALL CHRGET                      ; $1D5F  CD E4 13
        CP $28                           ; $1D62  FE 28
        POP HL                           ; $1D64  E1
        JP NZ,POLY_EVAL_3                ; $1D65  C2 07 3A
        LD A,$07                         ; $1D68  3E 07
SCAN_AMP_RADIX_CONST_8:
        LD B,$00                         ; $1D6A  06 00
        RLCA                             ; $1D6C  07
        LD C,A                           ; $1D6D  4F
        PUSH BC                          ; $1D6E  C5
        CALL CHRGET                      ; $1D6F  CD E4 13
        LD A,C                           ; $1D72  79
        CP $05                           ; $1D73  FE 05
        JP NC,SCAN_AMP_RADIX_CONST_9     ; $1D75  D2 90 1D
        CALL FRMEVL                      ; $1D78  CD 8C 1A
        CALL SYNCHR                      ; $1D7B  CD A3 45
        DEFB    ','                      ; $1D7E  2C  inline char arg consumed by the preceding CALL
        CALL FP_INT_CHECK                ; $1D7F  CD B3 2C
        EX DE,HL                         ; $1D82  EB
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $1D83  2A D4 0C
        EX (SP),HL                       ; $1D86  E3
        PUSH HL                          ; $1D87  E5
        EX DE,HL                         ; $1D88  EB
        CALL GETBYT                      ; $1D89  CD B2 20
        EX DE,HL                         ; $1D8C  EB
        EX (SP),HL                       ; $1D8D  E3
        JR SCAN_AMP_RADIX_CONST_11       ; $1D8E  18 19
SCAN_AMP_RADIX_CONST_9:
        CALL FRMEVL_PAREN                ; $1D90  CD C1 1C
        EX (SP),HL                       ; $1D93  E3
        LD A,L                           ; $1D94  7D
        CP $0C                           ; $1D95  FE 0C
        JR C,SCAN_AMP_RADIX_CONST_10     ; $1D97  38 07
        CP $1B                           ; $1D99  FE 1B
        PUSH HL                          ; $1D9B  E5
        CALL C,FN_CINT                   ; $1D9C  DC 6C 2C
        POP HL                           ; $1D9F  E1
SCAN_AMP_RADIX_CONST_10:
        LD DE,FRMEVL_PAREN_2             ; $1DA0  11 D5 1C
        PUSH DE                          ; $1DA3  D5
        LD A,$01                         ; $1DA4  3E 01
        LD (CHAIN_BREAK_FLAG_13),A       ; $1DA6  32 D9 0C
SCAN_AMP_RADIX_CONST_11:
        LD BC,FUNC_DISPATCH_TBL          ; $1DA9  01 B2 01
; [RE] Indexed vector dispatch: ADD HL,BC then load the 16-bit target from (HL) and JP (HL). Shared by the operator-function table ($04F9) and other token-dispatch sites.
DISPATCH_VECTOR_HLBC:
        ADD HL,BC                        ; $1DAC  09
        LD C,(HL)                        ; $1DAD  4E
        INC HL                           ; $1DAE  23
        LD H,(HL)                        ; $1DAF  66
        LD L,C                           ; $1DB0  69
        JP (HL)                          ; $1DB1  E9
; [RE] Pre-scan a leading unary operator token: recognises NOT ($F3), unary minus ($2D)/$F2 and unary plus ($2B), toggling D; backs up (HL) one char when none match. Used when fetching a factor/operand.
FRMEVL_SCAN_UNARY:
        DEC D                            ; $1DB2  15
        CP TOK_MINUS                     ; $1DB3  FE F3
        RET Z                            ; $1DB5  C8
        CP $2D                           ; $1DB6  FE 2D
        RET Z                            ; $1DB8  C8
        INC D                            ; $1DB9  14
        CP $2B                           ; $1DBA  FE 2B
        RET Z                            ; $1DBC  C8
        CP TOK_PLUS                      ; $1DBD  FE F2
        RET Z                            ; $1DBF  C8
        DEC HL                           ; $1DC0  2B
        RET                              ; $1DC1  C9
FRMEVL_SCAN_UNARY_1:
        INC A                            ; $1DC2  3C
        ADC A,A                          ; $1DC3  8F
        POP BC                           ; $1DC4  C1
        AND B                            ; $1DC5  A0
        ADD A,$FF                        ; $1DC6  C6 FF
        SBC A,A                          ; $1DC8  9F
        CALL INT16_TO_FP                 ; $1DC9  CD FF 2A
        JR FRMEVL_SCAN_UNARY_3           ; $1DCC  18 12
FRMEVL_SCAN_UNARY_2:
        LD D,$5A                         ; $1DCE  16 5A
        CALL FRMEVL_OPLOOP               ; $1DD0  CD 93 1A
        CALL FN_LPOS                     ; $1DD3  CD F4 2B
        LD A,L                           ; $1DD6  7D
        CPL                              ; $1DD7  2F
        LD L,A                           ; $1DD8  6F
        LD A,H                           ; $1DD9  7C
        CPL                              ; $1DDA  2F
        LD H,A                           ; $1DDB  67
        LD (CHAIN_BREAK_FLAG_9),HL       ; $1DDC  22 D4 0C
        POP BC                           ; $1DDF  C1
FRMEVL_SCAN_UNARY_3:
        JP FRMEVL_OPLOOP_2               ; $1DE0  C3 A3 1A
; [RE] Classify the FAC value type from $0B14 (2=sng,3=dbl,4=str,8=int): returns Z when string and sets carry/flags so callers can branch numeric-vs-string. Canonical MS BASIC type-test helper.
FRMEVL_TEST_TYPE:
        LD A,(SUB_0B2A_5)                ; $1DE3  3A 37 0B
        CP $08                           ; $1DE6  FE 08
        JR NC,FRMEVL_TEST_TYPE_1         ; $1DE8  30 05
        SUB $03                          ; $1DEA  D6 03
        OR A                             ; $1DEC  B7
        SCF                              ; $1DED  37
        RET                              ; $1DEE  C9
FRMEVL_TEST_TYPE_1:
        SUB $03                          ; $1DEF  D6 03
        OR A                             ; $1DF1  B7
        RET                              ; $1DF2  C9
; [RE] Integer-operands binary-operator handler (mis-split as DEFB, real code; set up by FRMEVL_OPLOOP_13 at $3B31 LD BC,$3DD8): pops operator token in A and the two integer operands (DE,HL), branches per token to integer add/sub/AND/OR/XOR/relational kernels, leaving the integer result in the FAC
FRMEVL_INT_OP_HANDLER:
        PUSH BC                          ; $1DF3  C5
        CALL FN_LPOS                     ; $1DF4  CD F4 2B
        POP AF                           ; $1DF7  F1
        POP DE                           ; $1DF8  D1
        CP $7A                           ; $1DF9  FE 7A
        JP Z,INT_DIV_ROUND               ; $1DFB  CA 76 2E
        CP $7B                           ; $1DFE  FE 7B
        JP Z,INT_DIV_KERNEL              ; $1E00  CA 14 2E
        LD BC,FP_LOAD_INT_TO_FAC_1       ; $1E03  01 4F 1E
        PUSH BC                          ; $1E06  C5
        CP $46                           ; $1E07  FE 46
        JR NZ,FRMEVL_INT_OP_HANDLER_1    ; $1E09  20 06
        LD A,E                           ; $1E0B  7B
        OR L                             ; $1E0C  B5
        LD L,A                           ; $1E0D  6F
        LD A,H                           ; $1E0E  7C
        OR D                             ; $1E0F  B2
        RET                              ; $1E10  C9
FRMEVL_INT_OP_HANDLER_1:
        CP $50                           ; $1E11  FE 50
        JR NZ,FRMEVL_INT_OP_HANDLER_2    ; $1E13  20 06
        LD A,E                           ; $1E15  7B
        AND L                            ; $1E16  A5
        LD L,A                           ; $1E17  6F
        LD A,H                           ; $1E18  7C
        AND D                            ; $1E19  A2
        RET                              ; $1E1A  C9
FRMEVL_INT_OP_HANDLER_2:
        CP $3C                           ; $1E1B  FE 3C
; Continuation of FRMEVL_INT_OP_HANDLER (integer binary-operator dispatch): tests the operator token for XOR ($3C) and computes HL := HL XOR DE, else falls through to EQV/IMP. Was SUB_1E1D. [RE]
FRMEVL_INT_OP_XOR:
        JR NZ,FRMEVL_INT_OP_XOR_1        ; $1E1D  20 06
        LD A,E                           ; $1E1F  7B
        XOR L                            ; $1E20  AD
        LD L,A                           ; $1E21  6F
        LD A,H                           ; $1E22  7C
        XOR D                            ; $1E23  AA
        RET                              ; $1E24  C9
FRMEVL_INT_OP_XOR_1:
        CP $32                           ; $1E25  FE 32
        JR NZ,FRMEVL_INT_OP_XOR_2        ; $1E27  20 08
        LD A,E                           ; $1E29  7B
        XOR L                            ; $1E2A  AD
        CPL                              ; $1E2B  2F
        LD L,A                           ; $1E2C  6F
        LD A,H                           ; $1E2D  7C
        XOR D                            ; $1E2E  AA
        CPL                              ; $1E2F  2F
        RET                              ; $1E30  C9
FRMEVL_INT_OP_XOR_2:
        LD A,L                           ; $1E31  7D
        CPL                              ; $1E32  2F
        AND E                            ; $1E33  A3
        CPL                              ; $1E34  2F
        LD L,A                           ; $1E35  6F
        LD A,H                           ; $1E36  7C
        CPL                              ; $1E37  2F
        AND D                            ; $1E38  A2
        CPL                              ; $1E39  2F
        RET                              ; $1E3A  C9
; [RE] 16-bit integer subtract (HL := HL - DE) then store the integer result into the FAC via FP_STORE (SUB_51EE).
FP_INT_SUB_TO_FAC:
        LD A,L                           ; $1E3B  7D
        SUB E                            ; $1E3C  93
        LD L,A                           ; $1E3D  6F
        LD A,H                           ; $1E3E  7C
        SBC A,D                          ; $1E3F  9A
        LD H,A                           ; $1E40  67
        JP INT_TO_SNG                    ; $1E41  C3 6C 2E
; [RE] HEX$() handler (function token $19): hexadecimal-string conversion.
FN_HEX_STR:
        LD A,(SUB_0752_32)               ; $1E44  3A 5A 08
        JR FP_LOAD_COL_TO_FAC_1          ; $1E47  18 03
; [RE] Load print-column counter ($0B11)+1 as an integer into the FAC (entry for POS-style functions); shares the tail with FP_LOAD_INT_TO_FAC.
FP_LOAD_COL_TO_FAC:
        LD A,(SUB_0B2A_2)                ; $1E49  3A 34 0B
FP_LOAD_COL_TO_FAC_1:
        INC A                            ; $1E4C  3C
; [RE] Store the 8-bit value in A (zero-extended to HL) as an integer into the FAC via FP_STORE_FAC_INT.
FP_LOAD_INT_TO_FAC:
        LD L,A                           ; $1E4D  6F
        XOR A                            ; $1E4E  AF
FP_LOAD_INT_TO_FAC_1:
        LD H,A                           ; $1E4F  67
        JP FP_STORE_FAC_INT              ; $1E50  C3 55 2C
FP_LOAD_INT_TO_FAC_2:
        CALL USRVEC_ADDR                 ; $1E53  CD 72 1E
        PUSH DE                          ; $1E56  D5
        CALL FRMEVL_PAREN                ; $1E57  CD C1 1C
        EX (SP),HL                       ; $1E5A  E3
        LD C,(HL)                        ; $1E5B  4E
        INC HL                           ; $1E5C  23
        LD B,(HL)                        ; $1E5D  46
        LD HL,FMUL_7                     ; $1E5E  21 E1 29
        PUSH HL                          ; $1E61  E5
        PUSH BC                          ; $1E62  C5
        LD A,(SUB_0B2A_5)                ; $1E63  3A 37 0B
        PUSH AF                          ; $1E66  F5
        CP $03                           ; $1E67  FE 03
        CALL Z,FRESTR                    ; $1E69  CC 3A 4A
        POP AF                           ; $1E6C  F1
        EX DE,HL                         ; $1E6D  EB
        LD HL,CHAIN_BREAK_FLAG_9         ; $1E6E  21 D4 0C
        RET                              ; $1E71  C9
; [RE] Compute the address of a USR(n) dispatch vector: base $081F + (digit index*2 from $0B1B if a numeric suffix follows the USR token), returned in DE. Used by DEF USR / USR-call setup.
USRVEC_ADDR:
        CALL CHRGET                      ; $1E72  CD E4 13
        LD BC,$0000                      ; $1E75  01 00 00
        CP $1B                           ; $1E78  FE 1B
        JR NC,USRVEC_ADDR_1              ; $1E7A  30 0D
        CP $11                           ; $1E7C  FE 11
        JR C,USRVEC_ADDR_1               ; $1E7E  38 09
        CALL CHRGET                      ; $1E80  CD E4 13
        LD A,(SUB_0B2A_11)               ; $1E83  3A 3E 0B
        OR A                             ; $1E86  B7
        RLA                              ; $1E87  17
        LD C,A                           ; $1E88  4F
USRVEC_ADDR_1:
        EX DE,HL                         ; $1E89  EB
        LD HL,SUB_0752_28                ; $1E8A  21 42 08
        ADD HL,BC                        ; $1E8D  09
        EX DE,HL                         ; $1E8E  EB
        RET                              ; $1E8F  C9
USRVEC_ADDR_2:
        CALL USRVEC_ADDR                 ; $1E90  CD 72 1E
        PUSH DE                          ; $1E93  D5
        CALL SYNCHR                      ; $1E94  CD A3 45
        DEFB    TOK_EQ                   ; $1E97  F0  inline keyword-token arg consumed by the preceding CALL
        CALL GETINT                      ; $1E98  CD A3 20
        EX (SP),HL                       ; $1E9B  E3
        LD (HL),E                        ; $1E9C  73
        INC HL                           ; $1E9D  23
        LD (HL),D                        ; $1E9E  72
        POP HL                           ; $1E9F  E1
        RET                              ; $1EA0  C9
; [RE] DEF statement handler (token $96): DEF FN user-function definition / DEF USR (CP $E1 = USR token).
STMT_DEF:
        CP $E1                           ; $1EA1  FE E1
        JR Z,USRVEC_ADDR_2               ; $1EA3  28 EB
        CALL GETVAR_NAME                 ; $1EA5  CD 41 20
        CALL CHECK_MEM_TOP               ; $1EA8  CD 33 20
        EX DE,HL                         ; $1EAB  EB
        LD (HL),E                        ; $1EAC  73
        INC HL                           ; $1EAD  23
        LD (HL),D                        ; $1EAE  72
        EX DE,HL                         ; $1EAF  EB
        LD A,(HL)                        ; $1EB0  7E
        CP $28                           ; $1EB1  FE 28
        JP NZ,STMT_DATA                  ; $1EB3  C2 CF 15
        CALL CHRGET                      ; $1EB6  CD E4 13
STMT_DEF_1:
        CALL PTRGET_1+1                  ; $1EB9  CD B3 3B
        LD A,(HL)                        ; $1EBC  7E
        CP $29                           ; $1EBD  FE 29
        JP Z,STMT_DATA                   ; $1EBF  CA CF 15
        CALL SYNCHR                      ; $1EC2  CD A3 45
        DEFB    ','                      ; $1EC5  2C  inline char arg consumed by the preceding CALL
        JR STMT_DEF_1                    ; $1EC6  18 F1
STMT_DEF_2:
        CALL GETVAR_NAME                 ; $1EC8  CD 41 20
        LD A,(SUB_0B2A_5)                ; $1ECB  3A 37 0B
        OR A                             ; $1ECE  B7
        PUSH AF                          ; $1ECF  F5
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $1ED0  22 8C 0B
        EX DE,HL                         ; $1ED3  EB
        LD A,(HL)                        ; $1ED4  7E
        INC HL                           ; $1ED5  23
        LD H,(HL)                        ; $1ED6  66
        LD L,A                           ; $1ED7  6F
        OR H                             ; $1ED8  B4
        JP Z,RAISE_UNDEFINED_USER_FUNCTION  ; $1ED9  CA 9E 0D
        LD A,(HL)                        ; $1EDC  7E
        CP $28                           ; $1EDD  FE 28
        JP NZ,STMT_DEF_9+1               ; $1EDF  C2 8E 1F
        CALL CHRGET                      ; $1EE2  CD E4 13
        LD (FRETOP_1),HL                 ; $1EE5  22 6D 0B
        EX DE,HL                         ; $1EE8  EB
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $1EE9  2A 8C 0B
        CALL SYNCHR                      ; $1EEC  CD A3 45
        DEFB    '('                      ; $1EEF  28  inline char arg consumed by the preceding CALL
        XOR A                            ; $1EF0  AF
        PUSH AF                          ; $1EF1  F5
        PUSH HL                          ; $1EF2  E5
        EX DE,HL                         ; $1EF3  EB
STMT_DEF_3:
        LD A,$80                         ; $1EF4  3E 80
        LD (DATA_LINE_TXTPTR_1),A        ; $1EF6  32 75 0B
        CALL PTRGET_1+1                  ; $1EF9  CD B3 3B
        EX DE,HL                         ; $1EFC  EB
        EX (SP),HL                       ; $1EFD  E3
        LD A,(SUB_0B2A_5)                ; $1EFE  3A 37 0B
        PUSH AF                          ; $1F01  F5
        PUSH DE                          ; $1F02  D5
        CALL FRMEVL_NOPAREN              ; $1F03  CD 90 1A
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $1F06  22 8C 0B
        POP HL                           ; $1F09  E1
        LD (FRETOP_1),HL                 ; $1F0A  22 6D 0B
        POP AF                           ; $1F0D  F1
        CALL FRMEVL_APPLY_OP             ; $1F0E  CD 1A 20
        LD C,$04                         ; $1F11  0E 04
STMT_DEF_4:
        CALL CHECK_STACK_ROOM            ; $1F13  CD 9F 44
        LD HL,$FFF8                      ; $1F16  21 F8 FF
        ADD HL,SP                        ; $1F19  39
        LD SP,HL                         ; $1F1A  F9
        CALL FP_ARG_SETUP2               ; $1F1B  CD 72 2B
        LD A,(SUB_0B2A_5)                ; $1F1E  3A 37 0B
        PUSH AF                          ; $1F21  F5
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $1F22  2A 8C 0B
        LD A,(HL)                        ; $1F25  7E
        CP $29                           ; $1F26  FE 29
        JR Z,STMT_DEF_6                  ; $1F28  28 12
        CALL SYNCHR                      ; $1F2A  CD A3 45
        DEFB    ','                      ; $1F2D  2C  inline char arg consumed by the preceding CALL
        PUSH HL                          ; $1F2E  E5
        LD HL,(FRETOP_1)                 ; $1F2F  2A 6D 0B
        CALL SYNCHR                      ; $1F32  CD A3 45
        DEFB    ','                      ; $1F35  2C  inline char arg consumed by the preceding CALL
        JR STMT_DEF_3                    ; $1F36  18 BC
STMT_DEF_5:
        POP AF                           ; $1F38  F1
        LD (SUB_0C03_2),A                ; $1F39  32 1E 0C
STMT_DEF_6:
        POP AF                           ; $1F3C  F1
        OR A                             ; $1F3D  B7
        JR Z,STMT_DEF_8                  ; $1F3E  28 3F
        LD (SUB_0B2A_5),A                ; $1F40  32 37 0B
        LD HL,$0000                      ; $1F43  21 00 00
        ADD HL,SP                        ; $1F46  39
        CALL FP_ARG_SETUP1               ; $1F47  CD 6A 2B
        LD HL,$0008                      ; $1F4A  21 08 00
        ADD HL,SP                        ; $1F4D  39
        LD SP,HL                         ; $1F4E  F9
        POP DE                           ; $1F4F  D1
        LD L,$03                         ; $1F50  2E 03
STMT_DEF_7:
        INC L                            ; $1F52  2C
        DEC DE                           ; $1F53  1B
        LD A,(DE)                        ; $1F54  1A
        OR A                             ; $1F55  B7
        JP M,STMT_DEF_7                  ; $1F56  FA 52 1F
        DEC DE                           ; $1F59  1B
        DEC DE                           ; $1F5A  1B
        DEC DE                           ; $1F5B  1B
        LD A,(SUB_0B2A_5)                ; $1F5C  3A 37 0B
        ADD A,L                          ; $1F5F  85
        LD B,A                           ; $1F60  47
        LD A,(SUB_0C03_2)                ; $1F61  3A 1E 0C
        LD C,A                           ; $1F64  4F
        ADD A,B                          ; $1F65  80
        CP $64                           ; $1F66  FE 64
        JP NC,GETINT_POSITIVE_1          ; $1F68  D2 EB 14
        PUSH AF                          ; $1F6B  F5
        LD A,L                           ; $1F6C  7D
        LD B,$00                         ; $1F6D  06 00
        LD HL,SUB_0C03_3                 ; $1F6F  21 20 0C
        ADD HL,BC                        ; $1F72  09
        LD C,A                           ; $1F73  4F
        CALL BLOCK_COPY_DE_HL            ; $1F74  CD 2E 20
        LD BC,STMT_DEF_5                 ; $1F77  01 38 1F
        PUSH BC                          ; $1F7A  C5
        PUSH BC                          ; $1F7B  C5
        JP STMT_LET_3                    ; $1F7C  C3 17 16
STMT_DEF_8:
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $1F7F  2A 8C 0B
        CALL CHRGET                      ; $1F82  CD E4 13
        PUSH HL                          ; $1F85  E5
        LD HL,(FRETOP_1)                 ; $1F86  2A 6D 0B
        CALL SYNCHR                      ; $1F89  CD A3 45
        DEFB    ')'                      ; $1F8C  29  inline char arg consumed by the preceding CALL
STMT_DEF_9:
        LD A,$D5                         ; $1F8D  3E D5
        LD (FRETOP_1),HL                 ; $1F8F  22 6D 0B
        LD A,(VARTAB_6)                  ; $1F92  3A B6 0B
        ADD A,$04                        ; $1F95  C6 04
        PUSH AF                          ; $1F97  F5
        RRCA                             ; $1F98  0F
        LD C,A                           ; $1F99  4F
        CALL CHECK_STACK_ROOM            ; $1F9A  CD 9F 44
        POP AF                           ; $1F9D  F1
        LD C,A                           ; $1F9E  4F
        CPL                              ; $1F9F  2F
        INC A                            ; $1FA0  3C
        LD L,A                           ; $1FA1  6F
        LD H,$FF                         ; $1FA2  26 FF
        ADD HL,SP                        ; $1FA4  39
        LD SP,HL                         ; $1FA5  F9
        PUSH HL                          ; $1FA6  E5
        LD DE,VARTAB_5                   ; $1FA7  11 B4 0B
        CALL BLOCK_COPY_DE_HL            ; $1FAA  CD 2E 20
        POP HL                           ; $1FAD  E1
        LD (VARTAB_5),HL                 ; $1FAE  22 B4 0B
        LD HL,(SUB_0C03_2)               ; $1FB1  2A 1E 0C
        LD (VARTAB_6),HL                 ; $1FB4  22 B6 0B
        LD B,H                           ; $1FB7  44
        LD C,L                           ; $1FB8  4D
        LD HL,VARTAB_7                   ; $1FB9  21 B8 0B
        LD DE,SUB_0C03_3                 ; $1FBC  11 20 0C
        CALL BLOCK_COPY_DE_HL            ; $1FBF  CD 2E 20
        LD H,A                           ; $1FC2  67
        LD L,A                           ; $1FC3  6F
        LD (SUB_0C03_2),HL               ; $1FC4  22 1E 0C
        LD HL,(SUB_0C4B_6)               ; $1FC7  2A 8A 0C
        INC HL                           ; $1FCA  23
        LD (SUB_0C4B_6),HL               ; $1FCB  22 8A 0C
        LD A,H                           ; $1FCE  7C
        OR L                             ; $1FCF  B5
        LD (SUB_0C4B_4),A                ; $1FD0  32 87 0C
        LD HL,(FRETOP_1)                 ; $1FD3  2A 6D 0B
        CALL EVAL_EXPR_AFTER_SYNCHR      ; $1FD6  CD 85 1A
        DEC HL                           ; $1FD9  2B
        CALL CHRGET                      ; $1FDA  CD E4 13
        JP NZ,RAISE_SYNTAX_ERROR         ; $1FDD  C2 92 0D
        CALL FRMEVL_TEST_TYPE            ; $1FE0  CD E3 1D
        JR NZ,STMT_DEF_10                ; $1FE3  20 11
        LD DE,MEMSIZ_4                   ; $1FE5  11 68 0B
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $1FE8  2A D4 0C
        CALL CMP_HL_DE                   ; $1FEB  CD 9D 45
        JR C,STMT_DEF_10                 ; $1FEE  38 06
        CALL STR_BUILD_FROM_DESC         ; $1FF0  CD 44 48
        CALL PUT_STR_TEMP_1+1            ; $1FF3  CD 9C 48
STMT_DEF_10:
        LD HL,(VARTAB_5)                 ; $1FF6  2A B4 0B
        LD D,H                           ; $1FF9  54
        LD E,L                           ; $1FFA  5D
        INC HL                           ; $1FFB  23
        INC HL                           ; $1FFC  23
        LD C,(HL)                        ; $1FFD  4E
        INC HL                           ; $1FFE  23
        LD B,(HL)                        ; $1FFF  46
        INC BC                           ; $2000  03
        INC BC                           ; $2001  03
        INC BC                           ; $2002  03
        INC BC                           ; $2003  03
        LD HL,VARTAB_5                   ; $2004  21 B4 0B
        CALL BLOCK_COPY_DE_HL            ; $2007  CD 2E 20
        EX DE,HL                         ; $200A  EB
        LD SP,HL                         ; $200B  F9
        LD HL,(SUB_0C4B_6)               ; $200C  2A 8A 0C
        DEC HL                           ; $200F  2B
        LD (SUB_0C4B_6),HL               ; $2010  22 8A 0C
        LD A,H                           ; $2013  7C
        OR L                             ; $2014  B5
        LD (SUB_0C4B_4),A                ; $2015  32 87 0C
        POP HL                           ; $2018  E1
        POP AF                           ; $2019  F1
; [RE] Apply a binary operator: mask the operator code (AND $07), index the operator-routine vector table at $04F9, and jump via DISPATCH_VECTOR_HLBC, preserving HL across the call.
FRMEVL_APPLY_OP:
        PUSH HL                          ; $201A  E5
        AND $07                          ; $201B  E6 07
FRMEVL_APPLY_OP_1:
        LD HL,OPERATOR_ROUTINE_TBL       ; $201D  21 F9 04
        LD C,A                           ; $2020  4F
        LD B,$00                         ; $2021  06 00
        ADD HL,BC                        ; $2023  09
        CALL DISPATCH_VECTOR_HLBC        ; $2024  CD AC 1D
        POP HL                           ; $2027  E1
        RET                              ; $2028  C9
FRMEVL_APPLY_OP_2:
        LD A,(DE)                        ; $2029  1A
        LD (HL),A                        ; $202A  77
        INC HL                           ; $202B  23
        INC DE                           ; $202C  13
        DEC BC                           ; $202D  0B
; [RE] Copy BC bytes from (DE) to (HL), ascending (LDI-style hand loop). General memory-move helper used by DEF FN parameter save/restore and variable-table shuffling.
BLOCK_COPY_DE_HL:
        LD A,B                           ; $202E  78
        OR C                             ; $202F  B1
        JR NZ,FRMEVL_APPLY_OP_2          ; $2030  20 F7
        RET                              ; $2032  C9
; [RE] Variable-space overflow guard: if the free-space-remaining counter ($0844) has wrapped to 0, raise 'Out of memory' (E=$0C) via RAISE_ERROR. Called before allocating variable/array storage.
CHECK_MEM_TOP:
        PUSH HL                          ; $2033  E5
        LD HL,(SAVTXT)                   ; $2034  2A 67 08
        INC HL                           ; $2037  23
        LD A,H                           ; $2038  7C
        OR L                             ; $2039  B5
        POP HL                           ; $203A  E1
        RET NZ                           ; $203B  C0
        LD E,ERR_ILLEGAL_DIRECT          ; $203C  1E 0C
        JP RAISE_ERROR                   ; $203E  C3 AC 0D
; [RE] Fetch and validate a variable-name token after SYNCHR: requires an alphabetic first char (JP PO on letter test), records the name in $0B52, then resolves it via PTRGET (SUB_5F30_2).
GETVAR_NAME:
        CALL SYNCHR                      ; $2041  CD A3 45
        DEFB    TOK_FN                   ; $2044  E2  inline keyword-token arg consumed by the preceding CALL
        LD A,$80                         ; $2045  3E 80
        LD (DATA_LINE_TXTPTR_1),A        ; $2047  32 75 0B
        OR (HL)                          ; $204A  B6
        LD C,A                           ; $204B  4F
        JP PTRGET_2                      ; $204C  C3 B8 3B
GETVAR_NAME_1:
        CP $7E                           ; $204F  FE 7E
        JP NZ,RAISE_SYNTAX_ERROR         ; $2051  C2 92 0D
        INC HL                           ; $2054  23
        LD A,(HL)                        ; $2055  7E
        CP $83                           ; $2056  FE 83
        JP NZ,RAISE_SYNTAX_ERROR         ; $2058  C2 92 0D
        INC HL                           ; $205B  23
        JP STMT_MID_ASSIGN               ; $205C  C3 E1 4B
        DEFB    $C3                      ; $205F
        DEFW    RAISE_SYNTAX_ERROR       ; $2060
; [RE] WIDTH statement handler (token $9D): set console/printer output line width (CP $9B tests for LPRINT form).
STMT_WIDTH:
        CP $9B                           ; $2062  FE 9B
        JR NZ,STMT_WIDTH_2               ; $2064  20 11
        CALL CHRGET                      ; $2066  CD E4 13
        CALL GETBYT                      ; $2069  CD B2 20
        LD (SUB_0752_33),A               ; $206C  32 5D 08
STMT_WIDTH_1:
        LD E,A                           ; $206F  5F
        CALL WIDTH_CLAMP_COLUMN          ; $2070  CD 96 20
        LD (SUB_0752_32+2),A             ; $2073  32 5C 08
        RET                              ; $2076  C9
STMT_WIDTH_2:
        CP $2C                           ; $2077  FE 2C
        JR Z,WIDTH_SET_CONSOLE_1         ; $2079  28 11
        CALL GETBYT                      ; $207B  CD B2 20
; [RE] WIDTH continuation: parse 'WIDTH #file,width' branch - stores file-width to $083B/$083D, then handles optional ',pos' second field.
WIDTH_SET_CONSOLE:
        LD (SUB_0752_34),A               ; $207E  32 5E 08
        LD E,A                           ; $2081  5F
        CALL WIDTH_CLAMP_COLUMN          ; $2082  CD 96 20
        LD (SUB_0752_35+1),A             ; $2085  32 60 08
        LD A,(HL)                        ; $2088  7E
        CP $2C                           ; $2089  FE 2C
        RET NZ                           ; $208B  C0
WIDTH_SET_CONSOLE_1:
        CALL CHRGET                      ; $208C  CD E4 13
        CALL GETBYT                      ; $208F  CD B2 20
        LD (SUB_0752_35),A               ; $2092  32 5F 08
        RET                              ; $2095  C9
; [RE] WIDTH helper: fold the requested column count into the valid 1..n range by repeated SUB $0E, then bias by E (original value); returns the clamped width byte.
WIDTH_CLAMP_COLUMN:
        SUB $0E                          ; $2096  D6 0E
        JR NC,WIDTH_CLAMP_COLUMN         ; $2098  30 FC
        ADD A,$1C                        ; $209A  C6 1C
        CPL                              ; $209C  2F
        INC A                            ; $209D  3C
        ADD A,E                          ; $209E  83
        RET                              ; $209F  C9
; [RE] MS BASIC GETINT entry: advance the text pointer (CHRGET) then evaluate a numeric expression and return it as a 16-bit integer (falls into GETINT).
GETINT_CHRGET:
        CALL CHRGET                      ; $20A0  CD E4 13
; [RE] MS BASIC GETINT: evaluate expression at the text pointer (FRMEVL), convert FAC to signed 16-bit (FN_LPOS) into DE; flags set from high byte.
GETINT:
        CALL FRMEVL_NOPAREN              ; $20A3  CD 90 1A
; [RE] Convert current numeric value (FAC) to a 16-bit integer in DE via FN_LPOS; A=high byte, OR A sets Z if value fits in one byte (used by GETBYT/POKE/PEEK).
FRC_INT_DE:
        PUSH HL                          ; $20A6  E5
        CALL FN_LPOS                     ; $20A7  CD F4 2B
        EX DE,HL                         ; $20AA  EB
        POP HL                           ; $20AB  E1
        LD A,D                           ; $20AC  7A
        OR A                             ; $20AD  B7
        RET                              ; $20AE  C9
; [RE] MS BASIC GETBYT entry: advance the text pointer (CHRGET) then fall into GETBYT (0..255 byte evaluator).
GETBYT_CHRGET:
        CALL CHRGET                      ; $20AF  CD E4 13
; [RE] MS BASIC GETBYT: evaluate expression (FRMEVL) then fall into CONINT to range-check it as a 0..255 byte in A/E.
GETBYT:
        CALL FRMEVL_NOPAREN              ; $20B2  CD 90 1A
; [RE] MS BASIC CONINT: require the integer to fit in one byte - convert via FRC_INT_DE and 'Illegal function call' (SUB_34CC_1) if the high byte is non-zero; returns the byte in A and E.
CONINT:
        CALL FRC_INT_DE                  ; $20B5  CD A6 20
        JP NZ,GETINT_POSITIVE_1          ; $20B8  C2 EB 14
        DEC HL                           ; $20BB  2B
        CALL CHRGET                      ; $20BC  CD E4 13
        LD A,E                           ; $20BF  7B
        RET                              ; $20C0  C9
; [RE] LLIST statement handler (token $9C): LIST directed to the line printer (sets printer flag then joins LIST).
STMT_LLIST:
        LD A,$01                         ; $20C1  3E 01
        LD (SUB_0752_32+1),A             ; $20C3  32 5B 08
; [RE] LIST statement handler (token $93): detokenizes program lines to the console (uses the reserved-word table walk at $4178).
STMT_LIST:
        POP BC                           ; $20C6  C1
        CALL SCAN_LINE_RANGE             ; $20C7  CD 84 0F
        PUSH BC                          ; $20CA  C5
        CALL ILLEGAL_DIRECT_CHECK        ; $20CB  CD 2A 5E
STMT_LIST_1:
        LD HL,$FFFF                      ; $20CE  21 FF FF
        LD (SAVTXT),HL                   ; $20D1  22 67 08
        POP HL                           ; $20D4  E1
        POP DE                           ; $20D5  D1
        LD C,(HL)                        ; $20D6  4E
        INC HL                           ; $20D7  23
        LD B,(HL)                        ; $20D8  46
        INC HL                           ; $20D9  23
        LD A,B                           ; $20DA  78
        OR C                             ; $20DB  B1
        JP Z,NEWSTT_READY                ; $20DC  CA 46 0E
        PUSH HL                          ; $20DF  E5
        LD HL,(PTRFIL)                   ; $20E0  2A 63 08
        LD A,H                           ; $20E3  7C
        OR L                             ; $20E4  B5
        POP HL                           ; $20E5  E1
        CALL Z,RPC_CONST_POLL            ; $20E6  CC 2C 44
        PUSH BC                          ; $20E9  C5
        LD C,(HL)                        ; $20EA  4E
        INC HL                           ; $20EB  23
        LD B,(HL)                        ; $20EC  46
        INC HL                           ; $20ED  23
        PUSH BC                          ; $20EE  C5
        EX (SP),HL                       ; $20EF  E3
        EX DE,HL                         ; $20F0  EB
        CALL CMP_HL_DE                   ; $20F1  CD 9D 45
        POP BC                           ; $20F4  C1
        JP C,STOP_BREAK_2+1              ; $20F5  DA 45 0E
        EX (SP),HL                       ; $20F8  E3
        PUSH HL                          ; $20F9  E5
        PUSH BC                          ; $20FA  C5
        EX DE,HL                         ; $20FB  EB
        LD (ERRLIN),HL                   ; $20FC  22 85 0B
        CALL FOUT                        ; $20FF  CD 91 33
        POP HL                           ; $2102  E1
        LD A,(HL)                        ; $2103  7E
        CP $09                           ; $2104  FE 09
        JR Z,STMT_LIST_2                 ; $2106  28 05
        LD A,$20                         ; $2108  3E 20
        CALL OUTCHR                      ; $210A  CD 91 42
STMT_LIST_2:
        CALL DETOKENIZE_LINE             ; $210D  CD 24 21
        LD HL,BUF                        ; $2110  21 31 0A
        CALL PRINT_ZSTRING               ; $2113  CD 1B 21
        CALL CRLF                        ; $2116  CD 06 44
        JR STMT_LIST_1                   ; $2119  18 B3
; [RE] Print a $00-terminated message byte-by-byte through SUB_6800 (console out); used by LIST to emit the post-line trailer text at $0A0E.
PRINT_ZSTRING:
        LD A,(HL)                        ; $211B  7E
        OR A                             ; $211C  B7
        RET Z                            ; $211D  C8
        CALL OUTCHR_LF_EXPAND            ; $211E  CD 7E 44
        INC HL                           ; $2121  23
        JR PRINT_ZSTRING                 ; $2122  18 F7
; [RE] LIST de-tokenizer: expand a crunched line back to ASCII into a buffer (BC=dest, D=remaining length). Copies literal bytes, and for reserved-word tokens (>= $0B) looks the keyword name up (SUB_41E1) and copies its spelling. Used by LIST and by the sign-on/error formatting. $0C93 tracks inter-token spacing.
DETOKENIZE_LINE:
        LD BC,BUF                        ; $2124  01 31 0A
DETOKENIZE_LINE_1:
        LD D,$FF                         ; $2127  16 FF
        XOR A                            ; $2129  AF
        LD (DETOKENIZE_SPACE_FLAG),A     ; $212A  32 B6 0C
        CALL ILLEGAL_DIRECT_CHECK        ; $212D  CD 2A 5E
        JR DETOKENIZE_LINE_3             ; $2130  18 04
DETOKENIZE_LINE_2:
        INC BC                           ; $2132  03
        INC HL                           ; $2133  23
        DEC D                            ; $2134  15
        RET Z                            ; $2135  C8
DETOKENIZE_LINE_3:
        LD A,(HL)                        ; $2136  7E
        OR A                             ; $2137  B7
        LD (BC),A                        ; $2138  02
        RET Z                            ; $2139  C8
        CP $0B                           ; $213A  FE 0B
        JR C,DETOKENIZE_LINE_4           ; $213C  38 05
        CP $20                           ; $213E  FE 20
        LD E,A                           ; $2140  5F
        JR C,DETOKENIZE_LINE_5           ; $2141  38 12
DETOKENIZE_LINE_4:
        OR A                             ; $2143  B7
        JP M,DETOKENIZE_LINE_9           ; $2144  FA 76 21
        LD E,A                           ; $2147  5F
        CP $2E                           ; $2148  FE 2E
        JR Z,DETOKENIZE_LINE_5           ; $214A  28 09
        CALL IS_ALNUM_CHAR               ; $214C  CD FC 21
        JP NC,DETOKENIZE_LINE_5          ; $214F  D2 55 21
        XOR A                            ; $2152  AF
        JR DETOKENIZE_LINE_7             ; $2153  18 11
DETOKENIZE_LINE_5:
        LD A,(DETOKENIZE_SPACE_FLAG)     ; $2155  3A B6 0C
        OR A                             ; $2158  B7
        JR Z,DETOKENIZE_LINE_6           ; $2159  28 09
        INC A                            ; $215B  3C
        JR NZ,DETOKENIZE_LINE_6          ; $215C  20 06
        LD A,$20                         ; $215E  3E 20
        LD (BC),A                        ; $2160  02
        INC BC                           ; $2161  03
        DEC D                            ; $2162  15
        RET Z                            ; $2163  C8
DETOKENIZE_LINE_6:
        LD A,$01                         ; $2164  3E 01
DETOKENIZE_LINE_7:
        LD (DETOKENIZE_SPACE_FLAG),A     ; $2166  32 B6 0C
        LD A,E                           ; $2169  7B
        CP $0B                           ; $216A  FE 0B
        JR C,DETOKENIZE_LINE_8           ; $216C  38 05
        CP $20                           ; $216E  FE 20
        JP C,IS_ALNUM_CHAR_1             ; $2170  DA 07 22
DETOKENIZE_LINE_8:
        LD (BC),A                        ; $2173  02
        JR DETOKENIZE_LINE_2             ; $2174  18 BC
DETOKENIZE_LINE_9:
        INC A                            ; $2176  3C
        LD A,(HL)                        ; $2177  7E
        JR NZ,DETOKENIZE_LINE_10         ; $2178  20 04
        INC HL                           ; $217A  23
        LD A,(HL)                        ; $217B  7E
        AND $7F                          ; $217C  E6 7F
DETOKENIZE_LINE_10:
        INC HL                           ; $217E  23
        CP $EA                           ; $217F  FE EA
        JR NZ,DETOKENIZE_LINE_11         ; $2181  20 08
        DEC BC                           ; $2183  0B
        DEC BC                           ; $2184  0B
        DEC BC                           ; $2185  0B
        DEC BC                           ; $2186  0B
        INC D                            ; $2187  14
        INC D                            ; $2188  14
        INC D                            ; $2189  14
        INC D                            ; $218A  14
DETOKENIZE_LINE_11:
        CP TOK_ELSE                      ; $218B  FE 9E
        CALL Z,DEC_BC                    ; $218D  CC E3 2C
        PUSH HL                          ; $2190  E5
        PUSH BC                          ; $2191  C5
        PUSH DE                          ; $2192  D5
        LD HL,RESWORD_INDEX+51           ; $2193  21 51 02
        LD B,A                           ; $2196  47
        LD C,$40                         ; $2197  0E 40
DETOKENIZE_LINE_12:
        INC C                            ; $2199  0C
DETOKENIZE_LINE_13:
        INC HL                           ; $219A  23
        LD D,H                           ; $219B  54
        LD E,L                           ; $219C  5D
DETOKENIZE_LINE_14:
        LD A,(HL)                        ; $219D  7E
        OR A                             ; $219E  B7
        JR Z,DETOKENIZE_LINE_12          ; $219F  28 F8
        INC HL                           ; $21A1  23
        JP P,DETOKENIZE_LINE_14          ; $21A2  F2 9D 21
        LD A,(HL)                        ; $21A5  7E
        CP B                             ; $21A6  B8
        JR NZ,DETOKENIZE_LINE_13         ; $21A7  20 F1
        EX DE,HL                         ; $21A9  EB
        CP $E1                           ; $21AA  FE E1
        JR Z,DETOKENIZE_LINE_15          ; $21AC  28 02
        CP TOK_FN                        ; $21AE  FE E2
DETOKENIZE_LINE_15:
        LD A,C                           ; $21B0  79
        POP DE                           ; $21B1  D1
        POP BC                           ; $21B2  C1
        LD E,A                           ; $21B3  5F
        JR NZ,DETOKENIZE_LINE_16         ; $21B4  20 0B
        LD A,(DETOKENIZE_SPACE_FLAG)     ; $21B6  3A B6 0C
        OR A                             ; $21B9  B7
        LD A,$00                         ; $21BA  3E 00
        LD (DETOKENIZE_SPACE_FLAG),A     ; $21BC  32 B6 0C
        JR DETOKENIZE_LINE_18            ; $21BF  18 13
DETOKENIZE_LINE_16:
        CP $5B                           ; $21C1  FE 5B
        JR NZ,DETOKENIZE_LINE_17         ; $21C3  20 06
        XOR A                            ; $21C5  AF
        LD (DETOKENIZE_SPACE_FLAG),A     ; $21C6  32 B6 0C
        JR DETOKENIZE_LINE_20            ; $21C9  18 16
DETOKENIZE_LINE_17:
        LD A,(DETOKENIZE_SPACE_FLAG)     ; $21CB  3A B6 0C
        OR A                             ; $21CE  B7
        LD A,$FF                         ; $21CF  3E FF
        LD (DETOKENIZE_SPACE_FLAG),A     ; $21D1  32 B6 0C
DETOKENIZE_LINE_18:
        JR Z,DETOKENIZE_LINE_19          ; $21D4  28 08
        LD A,$20                         ; $21D6  3E 20
        LD (BC),A                        ; $21D8  02
        INC BC                           ; $21D9  03
        DEC D                            ; $21DA  15
        JP Z,GETSPA_2                    ; $21DB  CA F1 48
DETOKENIZE_LINE_19:
        LD A,E                           ; $21DE  7B
        JR DETOKENIZE_LINE_21            ; $21DF  18 03
DETOKENIZE_LINE_20:
        LD A,(HL)                        ; $21E1  7E
        INC HL                           ; $21E2  23
        LD E,A                           ; $21E3  5F
DETOKENIZE_LINE_21:
        AND $7F                          ; $21E4  E6 7F
        LD (BC),A                        ; $21E6  02
        INC BC                           ; $21E7  03
        DEC D                            ; $21E8  15
        JP Z,GETSPA_2                    ; $21E9  CA F1 48
        OR E                             ; $21EC  B3
        JP P,DETOKENIZE_LINE_20          ; $21ED  F2 E1 21
        CP $A8                           ; $21F0  FE A8
        JR NZ,DETOKENIZE_LINE_22         ; $21F2  20 04
        XOR A                            ; $21F4  AF
        LD (DETOKENIZE_SPACE_FLAG),A     ; $21F5  32 B6 0C
DETOKENIZE_LINE_22:
        POP HL                           ; $21F8  E1
        JP DETOKENIZE_LINE_3             ; $21F9  C3 36 21
; [RE] LIST detokenizer helper: classify the next program byte - returns NC for an alpha/keyword char, C (with CCF) for ASCII digit 0-9, controlling whether DETOKENIZE_LINE treats it as a reserved-word token or literal.
IS_ALNUM_CHAR:
        CALL IS_LETTER_A                 ; $21FC  CD BF 46
        RET NC                           ; $21FF  D0
        CP $30                           ; $2200  FE 30
        RET C                            ; $2202  D8
        CP $3A                           ; $2203  FE 3A
        CCF                              ; $2205  3F
        RET                              ; $2206  C9
IS_ALNUM_CHAR_1:
        DEC HL                           ; $2207  2B
        CALL CHRGET                      ; $2208  CD E4 13
        PUSH DE                          ; $220B  D5
        PUSH BC                          ; $220C  C5
        PUSH AF                          ; $220D  F5
        CALL CHRGOT_CONST_VALUE          ; $220E  CD 60 14
        POP AF                           ; $2211  F1
        LD BC,IS_ALNUM_CHAR_3            ; $2212  01 26 22
        PUSH BC                          ; $2215  C5
        CP $0B                           ; $2216  FE 0B
        JP Z,POW10_INT_TABLE_1+2         ; $2218  CA BC 38
        CP $0C                           ; $221B  FE 0C
        JP Z,POW10_INT_TABLE_2+1         ; $221D  CA BF 38
IS_ALNUM_CHAR_2:
        LD HL,(SUB_0B2A_11)              ; $2220  2A 3E 0B
        JP FOUT_2                        ; $2223  C3 A0 33
IS_ALNUM_CHAR_3:
        POP BC                           ; $2226  C1
        POP DE                           ; $2227  D1
        LD A,(SUB_0B2A_9)                ; $2228  3A 3C 0B
        LD E,$4F                         ; $222B  1E 4F
        CP $0B                           ; $222D  FE 0B
        JR Z,IS_ALNUM_CHAR_4             ; $222F  28 06
        CP $0C                           ; $2231  FE 0C
        LD E,$48                         ; $2233  1E 48
        JR NZ,IS_ALNUM_CHAR_5            ; $2235  20 0B
IS_ALNUM_CHAR_4:
        LD A,$26                         ; $2237  3E 26
        LD (BC),A                        ; $2239  02
        INC BC                           ; $223A  03
        DEC D                            ; $223B  15
        RET Z                            ; $223C  C8
        LD A,E                           ; $223D  7B
        LD (BC),A                        ; $223E  02
        INC BC                           ; $223F  03
        DEC D                            ; $2240  15
        RET Z                            ; $2241  C8
IS_ALNUM_CHAR_5:
        LD A,(SUB_0B2A_10)               ; $2242  3A 3D 0B
        CP $04                           ; $2245  FE 04
        LD E,$00                         ; $2247  1E 00
        JR C,IS_ALNUM_CHAR_6             ; $2249  38 06
        LD E,$21                         ; $224B  1E 21
        JR Z,IS_ALNUM_CHAR_6             ; $224D  28 02
        LD E,$23                         ; $224F  1E 23
IS_ALNUM_CHAR_6:
        LD A,(HL)                        ; $2251  7E
        CP $20                           ; $2252  FE 20
        CALL Z,FP_LOAD_DONE              ; $2254  CC 3D 2B
IS_ALNUM_CHAR_7:
        LD A,(HL)                        ; $2257  7E
        INC HL                           ; $2258  23
        OR A                             ; $2259  B7
        JR Z,IS_ALNUM_CHAR_10            ; $225A  28 20
        LD (BC),A                        ; $225C  02
        INC BC                           ; $225D  03
        DEC D                            ; $225E  15
        RET Z                            ; $225F  C8
        LD A,(SUB_0B2A_10)               ; $2260  3A 3D 0B
        CP $04                           ; $2263  FE 04
        JR C,IS_ALNUM_CHAR_7             ; $2265  38 F0
        DEC BC                           ; $2267  0B
        LD A,(BC)                        ; $2268  0A
        INC BC                           ; $2269  03
        JR NZ,IS_ALNUM_CHAR_8            ; $226A  20 04
        CP $2E                           ; $226C  FE 2E
        JR Z,IS_ALNUM_CHAR_9             ; $226E  28 08
IS_ALNUM_CHAR_8:
        CP $44                           ; $2270  FE 44
        JR Z,IS_ALNUM_CHAR_9             ; $2272  28 04
        CP $45                           ; $2274  FE 45
        JR NZ,IS_ALNUM_CHAR_7            ; $2276  20 DF
IS_ALNUM_CHAR_9:
        LD E,$00                         ; $2278  1E 00
        JR IS_ALNUM_CHAR_7               ; $227A  18 DB
IS_ALNUM_CHAR_10:
        LD A,E                           ; $227C  7B
        OR A                             ; $227D  B7
        JR Z,IS_ALNUM_CHAR_11            ; $227E  28 04
        LD (BC),A                        ; $2280  02
        INC BC                           ; $2281  03
        DEC D                            ; $2282  15
        RET Z                            ; $2283  C8
IS_ALNUM_CHAR_11:
        LD HL,(SUB_0B2A_8)               ; $2284  2A 3A 0B
        JP DETOKENIZE_LINE_3             ; $2287  C3 36 21
; [RE] DELETE statement handler (token $A6): delete a range of program lines (CALL $0F61 parses the range).
STMT_DELETE:
        CALL SCAN_LINE_RANGE             ; $228A  CD 84 0F
        PUSH BC                          ; $228D  C5
        CALL RENUM_FIXUP_IF_PENDING      ; $228E  CD 26 24
        POP BC                           ; $2291  C1
        POP DE                           ; $2292  D1
        PUSH BC                          ; $2293  C5
        PUSH BC                          ; $2294  C5
        CALL FNDLIN                      ; $2295  CD AB 0F
STMT_DELETE_1:
        JR NC,STMT_DELETE_2              ; $2298  30 07
        LD D,H                           ; $229A  54
        LD E,L                           ; $229B  5D
        EX (SP),HL                       ; $229C  E3
        PUSH HL                          ; $229D  E5
        CALL CMP_HL_DE                   ; $229E  CD 9D 45
STMT_DELETE_2:
        JP NC,GETINT_POSITIVE_1          ; $22A1  D2 EB 14
        LD HL,MSG_BREAK                  ; $22A4  21 15 0D
        CALL STROUT                      ; $22A7  CD BE 48
        POP BC                           ; $22AA  C1
        LD HL,SUB_0F28_2                 ; $22AB  21 38 0F
        EX (SP),HL                       ; $22AE  E3
; [RE] Copy a string from (DE) into the string pool growing at $0B6F, byte-by-byte via SUB_691F until done; updates the $0B6F string-area pointer. Used by DELETE/edit to relocate text.
BLOCK_MOVE_TO_VARTAB:
        EX DE,HL                         ; $22AF  EB
        LD HL,(VARTAB)                   ; $22B0  2A 92 0B
BLOCK_MOVE_TO_VARTAB_1:
        LD A,(DE)                        ; $22B3  1A
        LD (BC),A                        ; $22B4  02
        INC BC                           ; $22B5  03
        INC DE                           ; $22B6  13
        CALL CMP_HL_DE                   ; $22B7  CD 9D 45
        JR NZ,BLOCK_MOVE_TO_VARTAB_1     ; $22BA  20 F7
        LD H,B                           ; $22BC  60
        LD L,C                           ; $22BD  69
        LD (VARTAB),HL                   ; $22BE  22 92 0B
        RET                              ; $22C1  C9
; [RE] CHR$() handler (function token $15): one-character string from a code.
FN_CHR_STR:
        CALL GETADR                      ; $22C2  CD E1 22
        CALL DIRECT_MODE_GUARD           ; $22C5  CD 21 5E
        LD A,(HL)                        ; $22C8  7E
        JP FP_LOAD_INT_TO_FAC            ; $22C9  C3 4D 1E
; [RE] POKE statement handler (token $97): evaluate address,value then store to memory.
STMT_POKE:
        CALL FRMEVL_NOPAREN              ; $22CC  CD 90 1A
        PUSH HL                          ; $22CF  E5
        CALL GETADR                      ; $22D0  CD E1 22
        EX (SP),HL                       ; $22D3  E3
        CALL DIRECT_MODE_GUARD           ; $22D4  CD 21 5E
        CALL SYNCHR                      ; $22D7  CD A3 45
        DEFB    ','                      ; $22DA  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $22DB  CD B2 20
        POP DE                           ; $22DE  D1
        LD (DE),A                        ; $22DF  12
        RET                              ; $22E0  C9
; [RE] MS BASIC GETADR: evaluate FAC and convert to an unsigned 16-bit address in BC/$9180-bias form (for POKE/PEEK); rejects out-of-range via SUB_4BA6. Pushes FN_LPOS as the integer-fetch continuation.
GETADR:
        LD BC,FN_LPOS                    ; $22E1  01 F4 2B
        PUSH BC                          ; $22E4  C5
        CALL FRMEVL_TEST_TYPE            ; $22E5  CD E3 1D
        RET M                            ; $22E8  F8
        LD A,(CHAIN_BREAK_FLAG_11)       ; $22E9  3A D7 0C
        CP $90                           ; $22EC  FE 90
        RET NZ                           ; $22EE  C0
        LD A,(CHAIN_BREAK_FLAG_10)       ; $22EF  3A D6 0C
        OR A                             ; $22F2  B7
        RET M                            ; $22F3  F8
        LD BC,$9180                      ; $22F4  01 80 91
        LD DE,$0000                      ; $22F7  11 00 00
        JP FADD_ALIGN                    ; $22FA  C3 24 28
; [RE] RENUM statement handler (token $A8): renumber program lines (defaults start/step in the LD BC,$000A).
STMT_RENUM:
        LD BC,$000A                      ; $22FD  01 0A 00
        PUSH BC                          ; $2300  C5
        LD D,B                           ; $2301  50
        LD E,B                           ; $2302  58
        JR Z,STMT_RENUM_2                ; $2303  28 2A
        CP $2C                           ; $2305  FE 2C
        JR Z,STMT_RENUM_1                ; $2307  28 09
        PUSH DE                          ; $2309  D5
        CALL LINGET_DOT                  ; $230A  CD F0 14
        LD B,D                           ; $230D  42
        LD C,E                           ; $230E  4B
        POP DE                           ; $230F  D1
        JR Z,STMT_RENUM_2                ; $2310  28 1D
STMT_RENUM_1:
        CALL SYNCHR                      ; $2312  CD A3 45
        DEFB    ','                      ; $2315  2C  inline char arg consumed by the preceding CALL
        CALL LINGET_DOT                  ; $2316  CD F0 14
        JR Z,STMT_RENUM_2                ; $2319  28 14
        POP AF                           ; $231B  F1
        CALL SYNCHR                      ; $231C  CD A3 45
        DEFB    ','                      ; $231F  2C  inline char arg consumed by the preceding CALL
        PUSH DE                          ; $2320  D5
        CALL LINGET                      ; $2321  CD FB 14
        JP NZ,RAISE_SYNTAX_ERROR         ; $2324  C2 92 0D
        LD A,D                           ; $2327  7A
        OR E                             ; $2328  B3
        JP Z,GETINT_POSITIVE_1           ; $2329  CA EB 14
        EX DE,HL                         ; $232C  EB
        EX (SP),HL                       ; $232D  E3
        EX DE,HL                         ; $232E  EB
STMT_RENUM_2:
        PUSH BC                          ; $232F  C5
        CALL FNDLIN                      ; $2330  CD AB 0F
        POP DE                           ; $2333  D1
        PUSH DE                          ; $2334  D5
        PUSH BC                          ; $2335  C5
        CALL FNDLIN                      ; $2336  CD AB 0F
        LD H,B                           ; $2339  60
        LD L,C                           ; $233A  69
        POP DE                           ; $233B  D1
        CALL CMP_HL_DE                   ; $233C  CD 9D 45
        EX DE,HL                         ; $233F  EB
        JP C,GETINT_POSITIVE_1           ; $2340  DA EB 14
        POP DE                           ; $2343  D1
        POP BC                           ; $2344  C1
        POP AF                           ; $2345  F1
        PUSH HL                          ; $2346  E5
        PUSH DE                          ; $2347  D5
        JR STMT_RENUM_4                  ; $2348  18 10
STMT_RENUM_3:
        ADD HL,BC                        ; $234A  09
        JP C,GETINT_POSITIVE_1           ; $234B  DA EB 14
        EX DE,HL                         ; $234E  EB
        PUSH HL                          ; $234F  E5
        LD HL,$FFF9                      ; $2350  21 F9 FF
        CALL CMP_HL_DE                   ; $2353  CD 9D 45
        POP HL                           ; $2356  E1
        JP C,GETINT_POSITIVE_1           ; $2357  DA EB 14
STMT_RENUM_4:
        PUSH DE                          ; $235A  D5
        LD E,(HL)                        ; $235B  5E
        LD A,E                           ; $235C  7B
        INC HL                           ; $235D  23
        LD D,(HL)                        ; $235E  56
        OR D                             ; $235F  B2
        EX DE,HL                         ; $2360  EB
        POP DE                           ; $2361  D1
        JR Z,STMT_RENUM_5                ; $2362  28 07
        LD A,(HL)                        ; $2364  7E
        INC HL                           ; $2365  23
        OR (HL)                          ; $2366  B6
        DEC HL                           ; $2367  2B
        EX DE,HL                         ; $2368  EB
        JR NZ,STMT_RENUM_3               ; $2369  20 DF
STMT_RENUM_5:
        PUSH BC                          ; $236B  C5
        CALL STMT_RENUM_8+1              ; $236C  CD 8C 23
        POP BC                           ; $236F  C1
        POP DE                           ; $2370  D1
        POP HL                           ; $2371  E1
STMT_RENUM_6:
        PUSH DE                          ; $2372  D5
        LD E,(HL)                        ; $2373  5E
        LD A,E                           ; $2374  7B
        INC HL                           ; $2375  23
        LD D,(HL)                        ; $2376  56
        OR D                             ; $2377  B2
        JR Z,STMT_RENUM_7                ; $2378  28 0D
        EX DE,HL                         ; $237A  EB
        EX (SP),HL                       ; $237B  E3
        EX DE,HL                         ; $237C  EB
        INC HL                           ; $237D  23
        LD (HL),E                        ; $237E  73
        INC HL                           ; $237F  23
        LD (HL),D                        ; $2380  72
        EX DE,HL                         ; $2381  EB
        ADD HL,BC                        ; $2382  09
        EX DE,HL                         ; $2383  EB
        POP HL                           ; $2384  E1
        JR STMT_RENUM_6                  ; $2385  18 EB
STMT_RENUM_7:
        LD BC,STOP_BREAK_2+1             ; $2387  01 45 0E
        PUSH BC                          ; $238A  C5
STMT_RENUM_8:
        CP $F6                           ; $238B  FE F6
; [RE] RENUM pass 2: walk every program line, find line-number references after GOTO/GOSUB/THEN tokens ($A4/$0E markers), translate each old line number to its new value (SUB_34EB lookup) and rewrite the 3-byte encoded line-number token in place; reports 'Undefined line' for missing targets.
RENUM_PATCH_LINEREFS:
        XOR A                            ; $238D  AF
        LD (DATA_LINE_TXTPTR_4),A        ; $238E  32 79 0B
        LD HL,(TXTTAB)                   ; $2391  2A 69 08
        DEC HL                           ; $2394  2B
RENUM_PATCH_LINEREFS_1:
        INC HL                           ; $2395  23
        LD A,(HL)                        ; $2396  7E
        INC HL                           ; $2397  23
        OR (HL)                          ; $2398  B6
        RET Z                            ; $2399  C8
        INC HL                           ; $239A  23
        LD E,(HL)                        ; $239B  5E
        INC HL                           ; $239C  23
        LD D,(HL)                        ; $239D  56
RENUM_PATCH_LINEREFS_2:
        CALL CHRGET                      ; $239E  CD E4 13
RENUM_PATCH_LINEREFS_3:
        OR A                             ; $23A1  B7
        JR Z,RENUM_PATCH_LINEREFS_1      ; $23A2  28 F1
        LD C,A                           ; $23A4  4F
        LD A,(DATA_LINE_TXTPTR_4)        ; $23A5  3A 79 0B
        OR A                             ; $23A8  B7
        LD A,C                           ; $23A9  79
        JR Z,MSG_UNDEFINED_LINE_3        ; $23AA  28 57
        CP $A4                           ; $23AC  FE A4
        JR NZ,RENUM_PATCH_LINEREFS_4     ; $23AE  20 18
        CALL CHRGET                      ; $23B0  CD E4 13
        CP TOK_GOTO                      ; $23B3  FE 89
        JR NZ,RENUM_PATCH_LINEREFS_3     ; $23B5  20 EA
        CALL CHRGET                      ; $23B7  CD E4 13
        CP $0E                           ; $23BA  FE 0E
        JR NZ,RENUM_PATCH_LINEREFS_3     ; $23BC  20 E3
        PUSH DE                          ; $23BE  D5
        CALL LINGET_TOKLINE              ; $23BF  CD 06 15
        LD A,D                           ; $23C2  7A
        OR E                             ; $23C3  B3
        JR NZ,RENUM_PATCH_LINEREFS_5     ; $23C4  20 0A
        JR RENUM_PATCH_LINEREFS_7        ; $23C6  18 27
RENUM_PATCH_LINEREFS_4:
        CP $0E                           ; $23C8  FE 0E
        JR NZ,RENUM_PATCH_LINEREFS_2     ; $23CA  20 D2
        PUSH DE                          ; $23CC  D5
        CALL LINGET_TOKLINE              ; $23CD  CD 06 15
RENUM_PATCH_LINEREFS_5:
        PUSH HL                          ; $23D0  E5
        CALL FNDLIN                      ; $23D1  CD AB 0F
        DEC BC                           ; $23D4  0B
        LD A,$0D                         ; $23D5  3E 0D
        JR C,MSG_UNDEFINED_LINE_4        ; $23D7  38 3D
        CALL PRINT_CRLF_IF_COL           ; $23D9  CD F9 43
        LD HL,MSG_UNDEFINED_LINE         ; $23DC  21 F3 23
        PUSH DE                          ; $23DF  D5
        CALL STROUT                      ; $23E0  CD BE 48
        POP HL                           ; $23E3  E1
        CALL FOUT                        ; $23E4  CD 91 33
        POP BC                           ; $23E7  C1
        POP HL                           ; $23E8  E1
        PUSH HL                          ; $23E9  E5
        PUSH BC                          ; $23EA  C5
        CALL FOUT_PRINT                  ; $23EB  CD 89 33
RENUM_PATCH_LINEREFS_6:
        POP HL                           ; $23EE  E1
RENUM_PATCH_LINEREFS_7:
        POP DE                           ; $23EF  D1
        DEC HL                           ; $23F0  2B
        JR RENUM_PATCH_LINEREFS_2        ; $23F1  18 AB
; Data string 'Undefined line ' (+NUL) printed by the RENUM/line-reference checker (loaded at $43C1, emitted via STROUT) before the offending line number
MSG_UNDEFINED_LINE:
        LD D,L                           ; $23F3  55
        LD L,(HL)                        ; $23F4  6E
        LD H,H                           ; $23F5  64
        LD H,L                           ; $23F6  65
        LD H,(HL)                        ; $23F7  66
MSG_UNDEFINED_LINE_1:
        LD L,C                           ; $23F8  69
        LD L,(HL)                        ; $23F9  6E
        LD H,L                           ; $23FA  65
        LD H,H                           ; $23FB  64
        JR NZ,STROUT_NOFLAGS             ; $23FC  20 6C
        LD L,C                           ; $23FE  69
        LD L,(HL)                        ; $23FF  6E
MSG_UNDEFINED_LINE_2:
        LD H,L                           ; $2400  65
        JR NZ,MSG_UNDEFINED_LINE_3       ; $2401  20 00
MSG_UNDEFINED_LINE_3:
        CP $0D                           ; $2403  FE 0D
        JP NZ,RENUM_PATCH_LINEREFS_2     ; $2405  C2 9E 23
        PUSH DE                          ; $2408  D5
        CALL LINGET_TOKLINE              ; $2409  CD 06 15
        PUSH HL                          ; $240C  E5
        EX DE,HL                         ; $240D  EB
        INC HL                           ; $240E  23
        INC HL                           ; $240F  23
        INC HL                           ; $2410  23
        LD C,(HL)                        ; $2411  4E
        INC HL                           ; $2412  23
        LD B,(HL)                        ; $2413  46
        LD A,$0E                         ; $2414  3E 0E
MSG_UNDEFINED_LINE_4:
        LD HL,RENUM_PATCH_LINEREFS_6     ; $2416  21 EE 23
        PUSH HL                          ; $2419  E5
        LD HL,(SUB_0B2A_8)               ; $241A  2A 3A 0B
; [RE] Write the 3-byte encoded line-number token (marker A, line# in BC) backward into the program text just before the pointer in $0B17.
RENUM_STORE_LINEREF:
        PUSH HL                          ; $241D  E5
        DEC HL                           ; $241E  2B
        LD (HL),B                        ; $241F  70
        DEC HL                           ; $2420  2B
        LD (HL),C                        ; $2421  71
        DEC HL                           ; $2422  2B
        LD (HL),A                        ; $2423  77
        POP HL                           ; $2424  E1
        RET                              ; $2425  C9
; [RE] If the renumber-pending flag $0B56 is set, run the line-reference fix-up pass (RENUM_PATCH_LINEREFS); otherwise return. Called after DELETE edits the program.
RENUM_FIXUP_IF_PENDING:
        LD A,(DATA_LINE_TXTPTR_4)        ; $2426  3A 79 0B
        OR A                             ; $2429  B7
        RET Z                            ; $242A  C8
        JP RENUM_PATCH_LINEREFS          ; $242B  C3 8D 23
; [RE] OPTION statement handler (token $B5): OPTION BASE 0/1 array lower-bound selector.
STMT_OPTION:
        CALL SYNCHR                      ; $242E  CD A3 45
        DEFB    'B'                      ; $2431  42  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $2432  CD A3 45
        DEFB    'A'                      ; $2435  41  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $2436  CD A3 45
        DEFB    'S'                      ; $2439  53  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $243A  CD A3 45
        DEFB    'E'                      ; $243D  45  inline char arg consumed by the preceding CALL
        LD A,(SUB_0C4B_13)               ; $243E  3A 97 0C
        OR A                             ; $2441  B7
        JP NZ,RAISE_DUPLICATE_DEFINITION ; $2442  C2 9B 0D
        PUSH HL                          ; $2445  E5
        LD HL,(VARTAB_1)                 ; $2446  2A 94 0B
        EX DE,HL                         ; $2449  EB
        LD HL,(VARTAB_2)                 ; $244A  2A 96 0B
        CALL CMP_HL_DE                   ; $244D  CD 9D 45
        JP NZ,RAISE_DUPLICATE_DEFINITION ; $2450  C2 9B 0D
        POP HL                           ; $2453  E1
        LD A,(HL)                        ; $2454  7E
        SUB $30                          ; $2455  D6 30
        JP C,RAISE_SYNTAX_ERROR          ; $2457  DA 92 0D
        CP $02                           ; $245A  FE 02
        JP NC,RAISE_SYNTAX_ERROR         ; $245C  D2 92 0D
        LD (SUB_0C4B_12),A               ; $245F  32 96 0C
        INC A                            ; $2462  3C
        LD (SUB_0C4B_13),A               ; $2463  32 97 0C
        CALL CHRGET                      ; $2466  CD E4 13
        RET                              ; $2469  C9
; [RE] Print a $00-terminated string at (HL) through STROUT_PUTC_SAVE, preserving registers; loops to end of string.
STROUT_NOFLAGS:
        LD A,(HL)                        ; $246A  7E
        OR A                             ; $246B  B7
        RET Z                            ; $246C  C8
        CALL STROUT_PUTC                 ; $246D  CD 74 24
        INC HL                           ; $2470  23
        JP STROUT_NOFLAGS                ; $2471  C3 6A 24
; [RE] Emit one character (A) to the console via OUTDO (OUTDO_WIDTH_1) while preserving AF across the call.
STROUT_PUTC:
        PUSH AF                          ; $2474  F5
        JP OUTDO_WIDTH_1                 ; $2475  C3 0F 43
; [RE] RANDOMIZE statement handler (token $B6): reseed the RND generator (prompts for a seed if none given).
STMT_RANDOMIZE:
        JR Z,STMT_RANDOMIZE_1            ; $2478  28 09
        CALL FRMEVL_NOPAREN              ; $247A  CD 90 1A
        PUSH HL                          ; $247D  E5
        CALL FN_LPOS                     ; $247E  CD F4 2B
        JR STMT_RANDOMIZE_3              ; $2481  18 1B
STMT_RANDOMIZE_1:
        PUSH HL                          ; $2483  E5
STMT_RANDOMIZE_2:
        LD HL,MSG_RANDOMIZE_PROMPT       ; $2484  21 A6 24
        CALL STROUT                      ; $2487  CD BE 48
        CALL QINLIN                      ; $248A  CD 87 4C
        POP DE                           ; $248D  D1
        JP C,STMT_END_2+1                ; $248E  DA E4 45
        PUSH DE                          ; $2491  D5
        INC HL                           ; $2492  23
        LD A,(HL)                        ; $2493  7E
        CALL FIN_1+1                     ; $2494  CD 25 31
        LD A,(HL)                        ; $2497  7E
        OR A                             ; $2498  B7
        JR NZ,STMT_RANDOMIZE_2           ; $2499  20 E9
        CALL FN_LPOS                     ; $249B  CD F4 2B
STMT_RANDOMIZE_3:
        LD (RNDX_SEED_WORD),HL           ; $249E  22 A3 3A
        CALL POLY_EVAL_SQR               ; $24A1  CD 0A 3A
        POP HL                           ; $24A4  E1
        RET                              ; $24A5  C9
; Data string 'Random number seed (-32768- to 32767)' (with a $08 backspace splice) -- the interactive RANDOMIZE prompt emitted by STMT_RANDOMIZE via STROUT/QINLIN
MSG_RANDOMIZE_PROMPT:
        LD D,D                           ; $24A6  52
        LD H,C                           ; $24A7  61
        LD L,(HL)                        ; $24A8  6E
        LD H,H                           ; $24A9  64
        LD L,A                           ; $24AA  6F
        LD L,L                           ; $24AB  6D
        JR NZ,BLOCK_SCAN_FORNEXT_11      ; $24AC  20 6E
        LD (HL),L                        ; $24AE  75
        LD L,L                           ; $24AF  6D
        LD H,D                           ; $24B0  62
        LD H,L                           ; $24B1  65
        LD (HL),D                        ; $24B2  72
        JR NZ,BLOCK_SCAN_FORNEXT_12      ; $24B3  20 73
        LD H,L                           ; $24B5  65
        LD H,L                           ; $24B6  65
        LD H,H                           ; $24B7  64
        JR NZ,BLOCK_SCAN_FORNEXT_5       ; $24B8  20 28
        DEC L                            ; $24BA  2D
        INC SP                           ; $24BB  33
        LD ($3637),A                     ; $24BC  32 37 36
        JR C,BLOCK_SCAN_FORNEXT_7+1      ; $24BF  38 2D
        EX AF,AF'                        ; $24C1  08
        JR NZ,BLOCK_SCAN_FORNEXT_13      ; $24C2  20 74
        LD L,A                           ; $24C4  6F
        JR NZ,BLOCK_SCAN_FORNEXT_8       ; $24C5  20 33
        LD ($3637),A                     ; $24C7  32 37 36
        SCF                              ; $24CA  37
        ADD HL,HL                        ; $24CB  29
        NOP                              ; $24CC  00
; [RE] Enter the structured-block program scanner with delimiter set for WHILE/WEND (C=$1D); used to balance nested block-statement keywords while searching forward through program text.
BLOCK_SCAN_WHILE:
        LD C,$1D                         ; $24CD  0E 1D
        JR BLOCK_SCAN_FORNEXT_1          ; $24CF  18 02
; [RE] Structured-block program scanner (FOR/NEXT default, C=$1A): walk crunched program text counting nesting of the matching open/close keyword tokens (e.g. FOR vs NEXT, $82/$83), tracking the current line pointer in $0C71; returns when the balancing close at depth 0 is found.
BLOCK_SCAN_FORNEXT:
        LD C,$1A                         ; $24D1  0E 1A
BLOCK_SCAN_FORNEXT_1:
        LD B,$00                         ; $24D3  06 00
        EX DE,HL                         ; $24D5  EB
        LD HL,(SAVTXT)                   ; $24D6  2A 67 08
        LD (SUB_0C4B_11),HL              ; $24D9  22 94 0C
        EX DE,HL                         ; $24DC  EB
BLOCK_SCAN_FORNEXT_2:
        INC B                            ; $24DD  04
BLOCK_SCAN_FORNEXT_3:
        DEC HL                           ; $24DE  2B
BLOCK_SCAN_FORNEXT_4:
        CALL CHRGET                      ; $24DF  CD E4 13
BLOCK_SCAN_FORNEXT_5:
        JR Z,BLOCK_SCAN_FORNEXT_6        ; $24E2  28 08
        CP TOK_ELSE                      ; $24E4  FE 9E
        JR Z,BLOCK_SCAN_FORNEXT_9        ; $24E6  28 18
        CP TOK_THEN                      ; $24E8  FE DE
        JR NZ,BLOCK_SCAN_FORNEXT_4       ; $24EA  20 F3
BLOCK_SCAN_FORNEXT_6:
        OR A                             ; $24EC  B7
BLOCK_SCAN_FORNEXT_7:
        JR NZ,BLOCK_SCAN_FORNEXT_9       ; $24ED  20 11
        INC HL                           ; $24EF  23
        LD A,(HL)                        ; $24F0  7E
        INC HL                           ; $24F1  23
        OR (HL)                          ; $24F2  B6
        LD E,C                           ; $24F3  59
        JP Z,RAISE_ERROR                 ; $24F4  CA AC 0D
        INC HL                           ; $24F7  23
        LD E,(HL)                        ; $24F8  5E
        INC HL                           ; $24F9  23
BLOCK_SCAN_FORNEXT_8:
        LD D,(HL)                        ; $24FA  56
        EX DE,HL                         ; $24FB  EB
        LD (SUB_0C4B_11),HL              ; $24FC  22 94 0C
        EX DE,HL                         ; $24FF  EB
BLOCK_SCAN_FORNEXT_9:
        CALL CHRGET                      ; $2500  CD E4 13
        LD A,C                           ; $2503  79
        CP $1A                           ; $2504  FE 1A
        LD A,(HL)                        ; $2506  7E
        JR Z,BLOCK_SCAN_FORNEXT_10       ; $2507  28 0B
        CP $AF                           ; $2509  FE AF
        JR Z,BLOCK_SCAN_FORNEXT_2        ; $250B  28 D0
        CP $B0                           ; $250D  FE B0
        JR NZ,BLOCK_SCAN_FORNEXT_3       ; $250F  20 CD
        DJNZ BLOCK_SCAN_FORNEXT_3        ; $2511  10 CB
        RET                              ; $2513  C9
BLOCK_SCAN_FORNEXT_10:
        CP $82                           ; $2514  FE 82
        JR Z,BLOCK_SCAN_FORNEXT_2        ; $2516  28 C5
        CP $83                           ; $2518  FE 83
        JR NZ,BLOCK_SCAN_FORNEXT_3       ; $251A  20 C2
BLOCK_SCAN_FORNEXT_11:
        DEC B                            ; $251C  05
        RET Z                            ; $251D  C8
        CALL CHRGET                      ; $251E  CD E4 13
        JR Z,BLOCK_SCAN_FORNEXT_6        ; $2521  28 C9
        EX DE,HL                         ; $2523  EB
        LD HL,(SAVTXT)                   ; $2524  2A 67 08
        PUSH HL                          ; $2527  E5
BLOCK_SCAN_FORNEXT_12:
        LD HL,(SUB_0C4B_11)              ; $2528  2A 94 0C
        LD (SAVTXT),HL                   ; $252B  22 67 08
        EX DE,HL                         ; $252E  EB
        PUSH BC                          ; $252F  C5
        CALL PTRGET_1+1                  ; $2530  CD B3 3B
        POP BC                           ; $2533  C1
        DEC HL                           ; $2534  2B
        CALL CHRGET                      ; $2535  CD E4 13
BLOCK_SCAN_FORNEXT_13:
        LD DE,BLOCK_SCAN_FORNEXT_6       ; $2538  11 EC 24
        JR Z,BLOCK_SCAN_FORNEXT_14       ; $253B  28 08
        CALL SYNCHR                      ; $253D  CD A3 45
        DEFB    ','                      ; $2540  2C  inline char arg consumed by the preceding CALL
        DEC HL                           ; $2541  2B
        LD DE,BLOCK_SCAN_FORNEXT_11      ; $2542  11 1C 25
BLOCK_SCAN_FORNEXT_14:
        EX (SP),HL                       ; $2545  E3
        LD (SAVTXT),HL                   ; $2546  22 67 08
        POP HL                           ; $2549  E1
        PUSH DE                          ; $254A  D5
        RET                              ; $254B  C9
BLOCK_SCAN_FORNEXT_15:
        PUSH AF                          ; $254C  F5
        LD A,(CHAIN_BREAK_FLAG_13)       ; $254D  3A D9 0C
        LD (CHAIN_BREAK_FLAG_14),A       ; $2550  32 DA 0C
        POP AF                           ; $2553  F1
; [RE] Clears the screen reverse/INVERSE flag cell ($0CB6=0) used by the console attribute path. Entry just below the VTAB/HTAB cursor helpers.
GFX_CLR_REVERSE_FLAG:
        PUSH AF                          ; $2554  F5
        XOR A                            ; $2555  AF
        LD (CHAIN_BREAK_FLAG_13),A       ; $2556  32 D9 0C
        POP AF                           ; $2559  F1
        RET                              ; $255A  C9
; [RE] VTAB statement handler (token $C8): Apple graphics superset -- set the text cursor row (CALL $458E reads the operand).
GFX_STMT_VTAB:
        CALL GFX_GET_BYTE_ARG            ; $255B  CD A9 25
        PUSH HL                          ; $255E  E5
        LD HL,SUB_0752_35                ; $255F  21 5F 08
GFX_STMT_VTAB_1:
        SUB (HL)                         ; $2562  96
        JP P,GFX_STMT_VTAB_1             ; $2563  F2 62 25
        ADD A,(HL)                       ; $2566  86
        LD (SUB_0B2A_3),A                ; $2567  32 35 0B
GFX_STMT_VTAB_2:
        CALL SCREEN_POS_FROM_TABLE       ; $256A  CD 6F 25
        POP HL                           ; $256D  E1
        RET                              ; $256E  C9
; [RE] Cursor/position helper used by HTAB/VTAB/HOME. Reads the per-screen cursor-config cells SLTTYP table at $F396/$F397 (40 vs 80-column geometry; bit7 selects swap of H/L) and folds the BASIC position ($0B11) into a console call via $6704. $F396/$F397 are SoftCard I/O-config screen cells in the $F3xx block.
SCREEN_POS_FROM_TABLE:
        LD E,$07                         ; $256F  1E 07
        CALL SCREEN_POS_EMIT             ; $2571  CD 90 25
        LD HL,(SUB_0B2A_2)               ; $2574  2A 34 0B
        LD A,(SXYOFF)                    ; $2577  3A 96 F3
        OR A                             ; $257A  B7
        JP P,SCREEN_POS_FROM_TABLE_1     ; $257B  F2 83 25
        AND $7F                          ; $257E  E6 7F
        LD E,L                           ; $2580  5D
        LD L,H                           ; $2581  6C
        LD H,E                           ; $2582  63
SCREEN_POS_FROM_TABLE_1:
        LD E,A                           ; $2583  5F
        ADD A,L                          ; $2584  85
        LD L,A                           ; $2585  6F
        LD A,E                           ; $2586  7B
        ADD A,H                          ; $2587  84
        PUSH HL                          ; $2588  E5
        CALL OUTDO_DEVICE2               ; $2589  CD 82 43
        POP HL                           ; $258C  E1
        LD A,L                           ; $258D  7D
        JR SCREEN_POS_EMIT_1             ; $258E  18 16
; [RE] Emits one cursor-position component. Indexes the $F397 screen-config cell by E, applies the bit7 'present' test (AND $7F), and routes the value through the console output routine $6704. Part of the HTAB/VTAB cursor positioning path.
SCREEN_POS_EMIT:
        LD D,$00                         ; $2590  16 00
        LD HL,SFLDIN                     ; $2592  21 97 F3
        ADD HL,DE                        ; $2595  19
        LD A,(HL)                        ; $2596  7E
        OR A                             ; $2597  B7
        RET Z                            ; $2598  C8
        JP P,SCREEN_POS_EMIT_1           ; $2599  F2 A6 25
        AND $7F                          ; $259C  E6 7F
        PUSH AF                          ; $259E  F5
        LD A,(SFLDIN)                    ; $259F  3A 97 F3
        CALL OUTDO_DEVICE2               ; $25A2  CD 82 43
        POP AF                           ; $25A5  F1
SCREEN_POS_EMIT_1:
        JP OUTDO_DEVICE2                 ; $25A6  C3 82 43
; [RE] Evaluate one expression and return it as an 8-bit value (CALL FRMEVL-byte $4097); A=0 -> error ($34D0), else returns A-1. Argument fetch shared by the cursor/graphics statements.
GFX_GET_BYTE_ARG:
        CALL GETBYT                      ; $25A9  CD B2 20
        OR A                             ; $25AC  B7
        JP Z,GETINT_POSITIVE_1           ; $25AD  CA EB 14
        DEC A                            ; $25B0  3D
        RET                              ; $25B1  C9
; [RE] HTAB statement handler (token $C9): Apple graphics superset -- set the text cursor column.
GFX_STMT_HTAB:
        CALL GFX_GET_BYTE_ARG            ; $25B2  CD A9 25
        PUSH HL                          ; $25B5  E5
        LD HL,SUB_0752_34                ; $25B6  21 5E 08
GFX_STMT_HTAB_1:
        SUB (HL)                         ; $25B9  96
        JP P,GFX_STMT_HTAB_1             ; $25BA  F2 B9 25
        ADD A,(HL)                       ; $25BD  86
        LD (SUB_0B2A_2),A                ; $25BE  32 34 0B
; [RE] HOME statement (token $C7, dispatch $0194 -> $45A8). $45A6 JRs into $4539_3; $45A8 zeroes the BASIC cursor-position cell $0B11, selects the screen attribute table entry (E=1, BC=$051E/$041E mode index) and calls SCREEN_POS_EMIT to clear/home the text cursor.
STMT_HOME:
        JR GFX_STMT_VTAB_2               ; $25C1  18 A7
; [RE] HOME statement handler (token $C7): Apple graphics superset -- clear the text screen / home cursor via the 6502 RPC.
GFX_STMT_HOME:
        PUSH HL                          ; $25C3  E5
        LD HL,$0000                      ; $25C4  21 00 00
        LD (SUB_0B2A_2),HL               ; $25C7  22 34 0B
        POP HL                           ; $25CA  E1
        LD E,$01                         ; $25CB  1E 01
GFX_STMT_HOME_1:
        LD BC,$051E                      ; $25CD  01 1E 05
GFX_STMT_HOME_2:
        LD BC,$041E                      ; $25D0  01 1E 04
        PUSH HL                          ; $25D3  E5
        CALL SCREEN_POS_EMIT             ; $25D4  CD 90 25
        POP HL                           ; $25D7  E1
        RET                              ; $25D8  C9
; [RE] GFX_ TEXT statement handler (token $C6): Apple graphics superset -- return the screen to text mode (RPC to the 6502 side).
STMT_TEXT:
        PUSH HL                          ; $25D9  E5
        LD HL,TEXT_ROM                   ; $25DA  21 2F FB
        CALL RPC_CALL                    ; $25DD  CD 02 26
        LD A,(SUB_0752_35)               ; $25E0  3A 5F 08
        DEC A                            ; $25E3  3D
        LD H,A                           ; $25E4  67
        LD L,$00                         ; $25E5  2E 00
        LD (SUB_0B2A_2),HL               ; $25E7  22 34 0B
        LD A,(TXTSET)                    ; $25EA  3A 51 E0
        LD A,(TXTPAGE1)                  ; $25ED  3A 54 E0
        LD A,(SUB_2803_2)                ; $25F0  3A 14 28
        OR A                             ; $25F3  B7
        JR Z,SUB_25EA_1                  ; $25F4  28 06
        LD HL,HOME_ROM                   ; $25F6  21 58 FC
        CALL RPC_CALL                    ; $25F9  CD 02 26
SUB_25EA_1:
        XOR A                            ; $25FC  AF
        LD (SUB_2803_2),A                ; $25FD  32 14 28
        JR STMT_HOME                     ; $2600  18 BF
; [RE] 6502 remote-procedure-call dispatcher. HL = Apple monitor-ROM target address; stores it at A$VEC ($F3D0) then writes the trigger cell whose operand was self-modified at cold start to Z$CPU ($F3DE) (the 'LD ($0000),A' at $45EA is patched to 'LD ($F3DE),A' by the init at $8243). Storing to Z$CPU hands control to the 6502, which runs the Apple monitor routine and returns. This is the bridge graphics uses to reach the Apple ROM (TEXT/HOME/PREAD/etc.).
RPC_CALL:
        LD (A_VEC),HL                    ; $2602  22 D0 F3
; [RE] Self-modified store. Assembled as LD ($0000),A; cold-start init ($8240-$8245) reads Z$CPU ($F3DE) and patches this operand so it becomes LD (Z$CPU),A -- the write that actually triggers the 6502 to service the call queued at A$VEC.
RPC_TRIGGER_STORE:
        LD ($0000),A                     ; $2605  32 00 00
        RET                              ; $2608  C9
; [RE] GR statement handler (token $CC): Apple graphics superset -- enter low-res graphics mode (loads mode byte then 6502 RPC).
GFX_STMT_GR:
        LD A,$00                         ; $2609  3E 00
        LD (COLOR),A                     ; $260B  32 30 F0
        CALL NZ,GETBYT                   ; $260E  C4 B2 20
        CP $02                           ; $2611  FE 02
        JR NC,GFX_PARSE_LINE_COORDS_1    ; $2613  30 63
        PUSH HL                          ; $2615  E5
        PUSH AF                          ; $2616  F5
        LD A,$14                         ; $2617  3E 14
        LD (WNDTOP),A                    ; $2619  32 22 F0
        LD HL,SCAN_LINE_RANGE_RESUME_1+1 ; $261C  21 00 17
        LD (SUB_0B2A_2),HL               ; $261F  22 34 0B
        CALL SCREEN_POS_FROM_TABLE       ; $2622  CD 6F 25
        LD A,(LORES)                     ; $2625  3A 56 E0
        POP AF                           ; $2628  F1
        POP HL                           ; $2629  E1
        LD (LORES),A                     ; $262A  32 56 E0
        CALL GFX_SET_DISPLAY_MODE        ; $262D  CD E0 27
        JR NZ,GFX_STMT_GR_1              ; $2630  20 09
        INC HL                           ; $2632  23
        PUSH DE                          ; $2633  D5
        CALL GETBYT                      ; $2634  CD B2 20
        CALL GFX_SET_LORES_COLOR         ; $2637  CD 64 26
        POP DE                           ; $263A  D1
GFX_STMT_GR_1:
        PUSH HL                          ; $263B  E5
        LD A,$27                         ; $263C  3E 27
        LD (H2),A                        ; $263E  32 2C F0
        LD B,D                           ; $2641  42
GFX_STMT_GR_2:
        XOR A                            ; $2642  AF
        LD (RPC_YREG),A                  ; $2643  32 47 F0
        LD A,B                           ; $2646  78
        DEC A                            ; $2647  3D
        LD (RPC_ACC),A                   ; $2648  32 45 F0
        CALL GFX_LORES_HLIN_RPC          ; $264B  CD 57 26
        DJNZ GFX_STMT_GR_2               ; $264E  10 F2
        LD A,$FF                         ; $2650  3E FF
        LD (SUB_2803_2),A                ; $2652  32 14 28
        POP HL                           ; $2655  E1
        RET                              ; $2656  C9
; [RE] Low-res block-draw RPC tail: LD HL,$F819 (6502 HLIN handler entry) then JP RPC_CALL. Called by GR fill, HLIN setup to execute the horizontal-segment draw on the 6502 side.
GFX_LORES_HLIN_RPC:
        LD HL,HLINE                      ; $2657  21 19 F8
        JP RPC_CALL                      ; $265A  C3 02 26
; [RE] COLOR statement handler (token $CD): Apple graphics superset -- set the low-res plotting color.
GFX_STMT_COLOR:
        CALL SYNCHR                      ; $265D  CD A3 45
        DEFB    TOK_EQ                   ; $2660  F0  inline keyword-token arg consumed by the preceding CALL
        CALL GETBYT                      ; $2661  CD B2 20
; [RE] COLOR statement body: validate color E<16, replicate it into both nibbles (4x ADD A,A; OR E) and store the packed low-res color byte to $F030.
GFX_SET_LORES_COLOR:
        LD A,E                           ; $2664  7B
        CP $10                           ; $2665  FE 10
        JR NC,GFX_PARSE_LINE_COORDS_1    ; $2667  30 0F
        ADD A,A                          ; $2669  87
        ADD A,A                          ; $266A  87
        ADD A,A                          ; $266B  87
        ADD A,A                          ; $266C  87
        OR E                             ; $266D  B3
        LD (COLOR),A                     ; $266E  32 30 F0
        RET                              ; $2671  C9
; [RE] GFX parse line coordinates: returns A = cross-axis coord, E = start, D = end.
GFX_PARSE_LINE_COORDS:
        PUSH BC                          ; $2672  C5
        CALL GFX_PARSE_TWO_BYTES         ; $2673  CD C1 26
        POP BC                           ; $2676  C1
        CP B                             ; $2677  B8
GFX_PARSE_LINE_COORDS_1:
        JP NC,GETINT_POSITIVE_1          ; $2678  D2 EB 14
        CP E                             ; $267B  BB
        JP C,GETINT_POSITIVE_1           ; $267C  DA EB 14
        LD D,A                           ; $267F  57
        PUSH DE                          ; $2680  D5
        PUSH BC                          ; $2681  C5
        CALL SYNCHR                      ; $2682  CD A3 45
        DEFB    'A'                      ; $2685  41  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $2686  CD A3 45
        DEFB    'T'                      ; $2689  54  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $268A  CD B2 20
        POP BC                           ; $268D  C1
        CP C                             ; $268E  B9
        JR NC,GFX_PARSE_LINE_COORDS_1    ; $268F  30 E7
        POP DE                           ; $2691  D1
        RET                              ; $2692  C9
; [RE] HLIN statement handler (token $CE): Apple graphics superset -- draw a horizontal low-res line.
GFX_STMT_HLIN:
        LD BC,FADD_ALIGN_1+1             ; $2693  01 30 28
        CALL GFX_PARSE_LINE_COORDS       ; $2696  CD 72 26
        LD (RPC_ACC),A                   ; $2699  32 45 F0
        LD A,E                           ; $269C  7B
        LD (RPC_YREG),A                  ; $269D  32 47 F0
        LD A,D                           ; $26A0  7A
        LD (H2),A                        ; $26A1  32 2C F0
        PUSH HL                          ; $26A4  E5
        CALL GFX_LORES_HLIN_RPC          ; $26A5  CD 57 26
        POP HL                           ; $26A8  E1
        RET                              ; $26A9  C9
; [RE] VLIN statement body (mirror of GFX_STMT_HLIN): parse coords, store Y0/Y1->$F045/$F047 and X->$F02D, then fall to the low-res draw RPC ($F828) via SUB_46C6_1.
GFX_STMT_VLIN:
        LD BC,$3028                      ; $26AA  01 28 30
        CALL GFX_PARSE_LINE_COORDS       ; $26AD  CD 72 26
        LD (RPC_YREG),A                  ; $26B0  32 47 F0
        LD A,E                           ; $26B3  7B
        LD (RPC_ACC),A                   ; $26B4  32 45 F0
        LD A,D                           ; $26B7  7A
        LD (V2),A                        ; $26B8  32 2D F0
        PUSH HL                          ; $26BB  E5
        LD HL,VLINE                      ; $26BC  21 28 F8
        JR GFX_STMT_PLOT_1               ; $26BF  18 27
; [RE] Parse two comma-separated byte expressions (X then Y): eval first into A, SYNCHR ',', eval second into A; preserves DE across. Used by PLOT/SCRN/BEEP coordinate reads.
GFX_PARSE_TWO_BYTES:
        CALL GETBYT                      ; $26C1  CD B2 20
        PUSH DE                          ; $26C4  D5
        CALL SYNCHR                      ; $26C5  CD A3 45
        DEFB    ','                      ; $26C8  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $26C9  CD B2 20
        POP DE                           ; $26CC  D1
        RET                              ; $26CD  C9
; [RE] Parse+range-check a low-res PLOT coordinate pair: X<$30 and Y<$28 (else FC error), store X->$F045 and Y->$F047.
GFX_PARSE_PLOT_COORD:
        CALL GFX_PARSE_TWO_BYTES         ; $26CE  CD C1 26
        CP $30                           ; $26D1  FE 30
        JR NC,GFX_PARSE_LINE_COORDS_1    ; $26D3  30 A3
        LD (RPC_ACC),A                   ; $26D5  32 45 F0
        LD A,E                           ; $26D8  7B
        CP $28                           ; $26D9  FE 28
        JR NC,GFX_PARSE_LINE_COORDS_1    ; $26DB  30 9B
        LD (RPC_YREG),A                  ; $26DD  32 47 F0
        RET                              ; $26E0  C9
; [RE] PLOT statement body: parse+validate coords (GFX_PARSE_PLOT_COORD), set HL=$F800 (6502 PLOT handler) and fall into the RPC tail.
GFX_STMT_PLOT:
        CALL GFX_PARSE_PLOT_COORD        ; $26E1  CD CE 26
        PUSH HL                          ; $26E4  E5
        LD HL,$F800                      ; $26E5  21 00 F8
GFX_STMT_PLOT_1:
        CALL RPC_CALL                    ; $26E8  CD 02 26
        POP HL                           ; $26EB  E1
        RET                              ; $26EC  C9
; [RE] PDL() handler (function token $35): Apple graphics superset -- read a game paddle/analog value via the 6502 RPC.
GFX_FN_PDL:
        CALL CONINT                      ; $26ED  CD B5 20
        LD A,E                           ; $26F0  7B
        CP $03                           ; $26F1  FE 03
        JR NC,GFX_FN_VPOS_1              ; $26F3  30 6F
        LD A,D                           ; $26F5  7A
        OR A                             ; $26F6  B7
        JR NZ,GFX_FN_VPOS_1              ; $26F7  20 6B
        PUSH HL                          ; $26F9  E5
        LD HL,BUTN0                      ; $26FA  21 61 E0
        ADD HL,DE                        ; $26FD  19
        LD A,(HL)                        ; $26FE  7E
        POP HL                           ; $26FF  E1
        RLA                              ; $2700  17
        SBC A,A                          ; $2701  9F
        LD L,A                           ; $2702  6F
        LD H,A                           ; $2703  67
        JP FP_STORE_FAC_INT              ; $2704  C3 55 2C
; [RE] MKD$() handler (function token $33): pack a double into an 8-byte string for random files (note: this entry sits in the Apple graphics block region).
GFX_FN_MKD_STR:
        LD A,(SUB_0B2A_3)                ; $2707  3A 35 0B
        INC A                            ; $270A  3C
GFX_FN_MKD_STR_1:
        PUSH HL                          ; $270B  E5
GFX_FN_MKD_STR_2:
        CALL FP_LOAD_INT_TO_FAC          ; $270C  CD 4D 1E
        POP HL                           ; $270F  E1
GFX_FN_MKD_STR_3:
        RET                              ; $2710  C9
; [RE] BEEP statement handler (token $D4): Apple graphics superset -- sound the console bell via the 6502 RPC.
GFX_STMT_BEEP:
        CALL GFX_PARSE_TWO_BYTES         ; $2711  CD C1 26
        INC A                            ; $2714  3C
        LD (RPC_ACC),A                   ; $2715  32 45 F0
        LD A,E                           ; $2718  7B
        INC A                            ; $2719  3C
        LD (RPC_XREG),A                  ; $271A  32 46 F0
        PUSH HL                          ; $271D  E5
        LD HL,FOUT_SCALE10_STEP_3        ; $271E  21 24 37
        JP GFX_STMT_PLOT_1               ; $2721  C3 E8 26
        DEFB    $A0,$00                  ; $2724
        DEFW    DDIV_1                   ; $2726
        DEFB    $C0,$88,$D0,$04          ; $2728
        DEFW    STMT_RESTORE_1           ; $272C
        DEFW    CHAIN_BREAK_FLAG_22      ; $272E
        DEFW    FILE_FLUSH_RECORD_CK_1   ; $2730
        DEFB    $FF,$CA,$D0,$F3          ; $2732
        DEFW    STMT_ERASE_3             ; $2736
        DEFB    $D0,$EC,$F0              ; $2738
        DEFW    SUB_60AD_5               ; $273B
; [RE] WAIT statement handler (token $D5): poll an I/O port until (in AND mask) XOR xor is non-zero.
STMT_WAIT:
        CALL GETINT                      ; $273D  CD A3 20
        PUSH DE                          ; $2740  D5
        CALL SYNCHR                      ; $2741  CD A3 45
        DEFB    ','                      ; $2744  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $2745  CD B2 20
        PUSH AF                          ; $2748  F5
        LD E,$00                         ; $2749  1E 00
        JR Z,STMT_WAIT_1                 ; $274B  28 07
        CALL SYNCHR                      ; $274D  CD A3 45
        DEFB    ','                      ; $2750  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $2751  CD B2 20
STMT_WAIT_1:
        POP AF                           ; $2754  F1
        LD D,A                           ; $2755  57
        EX (SP),HL                       ; $2756  E3
STMT_WAIT_2:
        LD A,(HL)                        ; $2757  7E
        XOR E                            ; $2758  AB
        AND D                            ; $2759  A2
        JR Z,STMT_WAIT_2                 ; $275A  28 FB
        POP HL                           ; $275C  E1
        RET                              ; $275D  C9
; [RE] VPOS() handler (function token $34): Apple graphics superset -- current text cursor row (CALL $409A).
GFX_FN_VPOS:
        CALL CONINT                      ; $275E  CD B5 20
        LD A,E                           ; $2761  7B
        CP $04                           ; $2762  FE 04
GFX_FN_VPOS_1:
        JP NC,GETINT_POSITIVE_1          ; $2764  D2 EB 14
        LD (RPC_XREG),A                  ; $2767  32 46 F0
        PUSH HL                          ; $276A  E5
        LD HL,PREAD                      ; $276B  21 1E FB
        CALL RPC_CALL                    ; $276E  CD 02 26
        POP HL                           ; $2771  E1
        LD A,(RPC_YREG)                  ; $2772  3A 47 F0
        JP FP_LOAD_INT_TO_FAC            ; $2775  C3 4D 1E
GFX_FN_VPOS_2:
        CALL CHRGET                      ; $2778  CD E4 13
        CALL SYNCHR                      ; $277B  CD A3 45
        DEFB    '('                      ; $277E  28  inline char arg consumed by the preceding CALL
        CALL GFX_PARSE_PLOT_COORD        ; $277F  CD CE 26
        CALL SYNCHR                      ; $2782  CD A3 45
        DEFB    ')'                      ; $2785  29  inline char arg consumed by the preceding CALL
        PUSH HL                          ; $2786  E5
        LD HL,SCRN_ROM                   ; $2787  21 71 F8
        CALL RPC_CALL                    ; $278A  CD 02 26
        LD A,(RPC_ACC)                   ; $278D  3A 45 F0
        JP GFX_FN_MKD_STR_2              ; $2790  C3 0C 27
GFX_FN_VPOS_3:
        CALL CHRGET                      ; $2793  CD E4 13
        LD A,(COLOR)                     ; $2796  3A 30 F0
        AND $0F                          ; $2799  E6 0F
        JP GFX_FN_MKD_STR_1              ; $279B  C3 0B 27
GFX_FN_VPOS_4:
        LD HL,RPC_ACC                    ; $279E  21 45 F0
        XOR A                            ; $27A1  AF
        LD (HL),A                        ; $27A2  77
        INC HL                           ; $27A3  23
        LD (HL),A                        ; $27A4  77
        INC HL                           ; $27A5  23
        LD (HL),A                        ; $27A6  77
        POP HL                           ; $27A7  E1
        CALL CHRGOT                      ; $27A8  CD E5 13
        JR Z,GFX_FN_VPOS_9               ; $27AB  28 2C
        CALL SYNCHR                      ; $27AD  CD A3 45
        DEFB    '('                      ; $27B0  28  inline char arg consumed by the preceding CALL
        LD DE,RPC_ACC                    ; $27B1  11 45 F0
        LD B,$03                         ; $27B4  06 03
GFX_FN_VPOS_5:
        LD A,(HL)                        ; $27B6  7E
        CP $29                           ; $27B7  FE 29
        JR Z,GFX_FN_VPOS_8               ; $27B9  28 1A
        CP $2C                           ; $27BB  FE 2C
        JR NZ,GFX_FN_VPOS_6              ; $27BD  20 05
        CALL CHRGET                      ; $27BF  CD E4 13
        JR GFX_FN_VPOS_7                 ; $27C2  18 0F
GFX_FN_VPOS_6:
        PUSH BC                          ; $27C4  C5
        PUSH DE                          ; $27C5  D5
        CALL GETBYT                      ; $27C6  CD B2 20
        POP DE                           ; $27C9  D1
        POP BC                           ; $27CA  C1
        LD (DE),A                        ; $27CB  12
        INC DE                           ; $27CC  13
        LD A,(HL)                        ; $27CD  7E
        CP $2C                           ; $27CE  FE 2C
        CALL Z,CHRGET                    ; $27D0  CC E4 13
GFX_FN_VPOS_7:
        DJNZ GFX_FN_VPOS_5               ; $27D3  10 E1
GFX_FN_VPOS_8:
        CALL SYNCHR                      ; $27D5  CD A3 45
        DEFB    ')'                      ; $27D8  29  inline char arg consumed by the preceding CALL
GFX_FN_VPOS_9:
        PUSH HL                          ; $27D9  E5
        LD HL,(DETOKENIZE_SPACE_FLAG)    ; $27DA  2A B6 0C
        JP GFX_STMT_PLOT_1               ; $27DD  C3 E8 26
; [RE] Graphics display-mode soft-switch helper. LD ($E050),A = $C050 TXTCLR (graphics on); LD HL,$E053; RRA selects mixed vs full screen: NC -> use $E053 ($C053 MIXSET, mixed text+graphics, D=$28 rows); C -> DEC L to $E052 ($C052 MIXCLR, full-screen graphics, D=$30 rows); the LD (HL),L touches the chosen switch. Sets the Apple display into the requested graphics mode.
GFX_SET_DISPLAY_MODE:
        PUSH HL                          ; $27E0  E5
        LD (TXTCLR),A                    ; $27E1  32 50 E0
        LD HL,MIXSET                     ; $27E4  21 53 E0
        RRA                              ; $27E7  1F
        LD D,$28                         ; $27E8  16 28
        JR NC,SUB_27E1_1                 ; $27EA  30 03
        DEC L                            ; $27EC  2D
        LD D,$30                         ; $27ED  16 30
SUB_27E1_1:
        LD (HL),L                        ; $27EF  75
        POP HL                           ; $27F0  E1
        LD A,(HL)                        ; $27F1  7E
        CP $2C                           ; $27F2  FE 2C
        RET                              ; $27F4  C9
SUB_27E1_2:
        LD E,$1F                         ; $27F5  1E 1F
SUB_27E1_3:
        LD BC,$391E                      ; $27F7  01 1E 39
SUB_27E1_4:
        LD BC,$441E                      ; $27FA  01 1E 44
SUB_27E1_5:
        LD BC,$451E                      ; $27FD  01 1E 45
SUB_27E1_6:
        LD BC,$461E                      ; $2800  01 1E 46
        PUSH DE                          ; $2803  D5
        LD C,$0E                         ; $2804  0E 0E
        LD A,($0004)                     ; $2806  3A 04 00
        LD E,A                           ; $2809  5F
        CALL $0005                       ; $280A  CD 05 00
        POP DE                           ; $280D  D1
SUB_2803_1:
        LD BC,$201E                      ; $280E  01 1E 20
        JP RAISE_ERROR                   ; $2811  C3 AC 0D
SUB_2803_2:
        NOP                              ; $2814  00
SUB_2803_3:
        LD D,B                           ; $2815  50
; [RE] FADDT entry: load constant pointer (L_5BDC) then fall into FADD-with-operand; adds the FP value at (HL) to FAC.
FADD_LOAD_CONST:
        LD HL,FP_CONST_HALF_SNG          ; $2816  21 5A 38
; [RE] FADD with operand at (HL): load the addend mantissa/exp into regs (SUB_4EB8) then align-and-add against FAC.
FADD_FROM_MEM:
        CALL FP_LOAD_MEM                 ; $2819  CD 36 2B
        JR FADD_ALIGN                    ; $281C  18 06
FADD_FROM_MEM_1:
        CALL FP_LOAD_MEM                 ; $281E  CD 36 2B
; [RE] FADD entry when addend already supplied; loads FAC into HL-pair (SUB_4E76 negate path) then aligns exponents.
FSUB:
        CALL FP_NEG                      ; $2821  CD F4 2A
; [RE] FADD core: compare exponents of addend (B) and FAC ($0CB4); if FAC=0 just store addend; shift the smaller mantissa right to align, then add.
FADD_ALIGN:
        LD A,B                           ; $2824  78
        OR A                             ; $2825  B7
        RET Z                            ; $2826  C8
        LD A,(CHAIN_BREAK_FLAG_11)       ; $2827  3A D7 0C
        OR A                             ; $282A  B7
        JP Z,FP_STORE_FAC                ; $282B  CA 28 2B
        SUB B                            ; $282E  90
FADD_ALIGN_1:
        JR NC,FADD_ALIGN_2               ; $282F  30 0C
        CPL                              ; $2831  2F
        INC A                            ; $2832  3C
        EX DE,HL                         ; $2833  EB
        CALL FAC_PUSH                    ; $2834  CD 18 2B
        EX DE,HL                         ; $2837  EB
        CALL FP_STORE_FAC                ; $2838  CD 28 2B
        POP BC                           ; $283B  C1
        POP DE                           ; $283C  D1
FADD_ALIGN_2:
        CP $19                           ; $283D  FE 19
        RET NC                           ; $283F  D0
        PUSH AF                          ; $2840  F5
        CALL FP_UNPACK_MSB               ; $2841  CD 52 2B
        LD H,A                           ; $2844  67
        POP AF                           ; $2845  F1
        CALL MANT_SHIFT_BYTES            ; $2846  CD F5 28
        LD A,H                           ; $2849  7C
        OR A                             ; $284A  B7
        LD HL,CHAIN_BREAK_FLAG_9         ; $284B  21 D4 0C
        JP P,FADD_ALIGN_3                ; $284E  F2 63 28
        CALL MANT_ADD                    ; $2851  CD D5 28
        JP NC,FP_SET_ZERO_7              ; $2854  D2 B6 28
        INC HL                           ; $2857  23
        INC (HL)                         ; $2858  34
        JP Z,FIN_EXP_DIGIT_10            ; $2859  CA D4 32
        LD L,$01                         ; $285C  2E 01
        CALL MANT_SHIFT_BITS             ; $285E  CD 17 29
        JR FP_SET_ZERO_7                 ; $2861  18 53
FADD_ALIGN_3:
        XOR A                            ; $2863  AF
        SUB B                            ; $2864  90
        LD B,A                           ; $2865  47
        LD A,(HL)                        ; $2866  7E
        SBC A,E                          ; $2867  9B
        LD E,A                           ; $2868  5F
        INC HL                           ; $2869  23
        LD A,(HL)                        ; $286A  7E
        SBC A,D                          ; $286B  9A
        LD D,A                           ; $286C  57
        INC HL                           ; $286D  23
        LD A,(HL)                        ; $286E  7E
        SBC A,C                          ; $286F  99
        LD C,A                           ; $2870  4F
; [RE] FADD mantissa combine: CALL C,FCOMPL (sign disagreement) then drop into FADD proper to add/subtract the aligned mantissas.
FADD_COMBINE:
        CALL C,FCOMPL                    ; $2871  DC E1 28
; [RE] FP add/normalize core (FADDT path): align exponents, add/subtract mantissas, and renormalize the result in the FAC ($0CB1/$0CB4). SUB_4C09 ($4C09) is the normalize/round tail that writes the final exponent to $0CB4.
FADD:
        LD L,B                           ; $2874  68
        LD H,E                           ; $2875  63
        XOR A                            ; $2876  AF
FADD_1:
        LD B,A                           ; $2877  47
        LD A,C                           ; $2878  79
        OR A                             ; $2879  B7
        JR NZ,FP_SET_ZERO_5              ; $287A  20 27
        LD C,D                           ; $287C  4A
        LD D,H                           ; $287D  54
        LD H,L                           ; $287E  65
        LD L,A                           ; $287F  6F
        LD A,B                           ; $2880  78
        SUB $08                          ; $2881  D6 08
        CP $E0                           ; $2883  FE E0
        JR NZ,FADD_1                     ; $2885  20 F0
; [RE] MBF normalize/round tail: left-justify the summed mantissa (B=shift count), adjust the FAC exponent at $0CB4, round, store result back (JP FADD_STORE).
FP_SET_ZERO:
        XOR A                            ; $2887  AF
FP_SET_ZERO_1:
        LD (CHAIN_BREAK_FLAG_11),A       ; $2888  32 D7 0C
        RET                              ; $288B  C9
FP_SET_ZERO_2:
        LD A,H                           ; $288C  7C
        OR L                             ; $288D  B5
        OR D                             ; $288E  B2
        JR NZ,FP_SET_ZERO_4              ; $288F  20 0A
        LD A,C                           ; $2891  79
FP_SET_ZERO_3:
        DEC B                            ; $2892  05
        RLA                              ; $2893  17
        JR NC,FP_SET_ZERO_3              ; $2894  30 FC
        INC B                            ; $2896  04
        RRA                              ; $2897  1F
        LD C,A                           ; $2898  4F
        JR FP_SET_ZERO_6                 ; $2899  18 0B
FP_SET_ZERO_4:
        DEC B                            ; $289B  05
        ADD HL,HL                        ; $289C  29
        LD A,D                           ; $289D  7A
        RLA                              ; $289E  17
        LD D,A                           ; $289F  57
        LD A,C                           ; $28A0  79
        ADC A,A                          ; $28A1  8F
        LD C,A                           ; $28A2  4F
FP_SET_ZERO_5:
        JP P,FP_SET_ZERO_2               ; $28A3  F2 8C 28
FP_SET_ZERO_6:
        LD A,B                           ; $28A6  78
        LD E,H                           ; $28A7  5C
        LD B,L                           ; $28A8  45
        OR A                             ; $28A9  B7
        JR Z,FP_SET_ZERO_7               ; $28AA  28 0A
        LD HL,CHAIN_BREAK_FLAG_11        ; $28AC  21 D7 0C
        ADD A,(HL)                       ; $28AF  86
        LD (HL),A                        ; $28B0  77
        JR NC,FP_SET_ZERO                ; $28B1  30 D4
        JP Z,FP_SET_ZERO                 ; $28B3  CA 87 28
FP_SET_ZERO_7:
        LD A,B                           ; $28B6  78
FP_SET_ZERO_8:
        LD HL,CHAIN_BREAK_FLAG_11        ; $28B7  21 D7 0C
        OR A                             ; $28BA  B7
        CALL M,FADD_ROUND_CARRY          ; $28BB  FC C8 28
        LD B,(HL)                        ; $28BE  46
        INC HL                           ; $28BF  23
        LD A,(HL)                        ; $28C0  7E
        AND $80                          ; $28C1  E6 80
        XOR C                            ; $28C3  A9
        LD C,A                           ; $28C4  4F
        JP FP_STORE_FAC                  ; $28C5  C3 28 2B
; [RE] Round/carry propagation: bump mantissa bytes E,D,C and exponent on a rounding carry; overflow to error if the exponent wraps.
FADD_ROUND_CARRY:
        INC E                            ; $28C8  1C
        RET NZ                           ; $28C9  C0
        INC D                            ; $28CA  14
        RET NZ                           ; $28CB  C0
        INC C                            ; $28CC  0C
        RET NZ                           ; $28CD  C0
        LD C,$80                         ; $28CE  0E 80
        INC (HL)                         ; $28D0  34
        RET NZ                           ; $28D1  C0
        JP FIN_EXP_DIGIT_9               ; $28D2  C3 D3 32
; [RE] 3-byte mantissa add: (HL..)+E,D,C with carry into the FAC mantissa registers.
MANT_ADD:
        LD A,(HL)                        ; $28D5  7E
        ADD A,E                          ; $28D6  83
        LD E,A                           ; $28D7  5F
        INC HL                           ; $28D8  23
        LD A,(HL)                        ; $28D9  7E
        ADC A,D                          ; $28DA  8A
        LD D,A                           ; $28DB  57
        INC HL                           ; $28DC  23
        LD A,(HL)                        ; $28DD  7E
        ADC A,C                          ; $28DE  89
        LD C,A                           ; $28DF  4F
        RET                              ; $28E0  C9
; [RE] FCOMPL: two's-complement negate the working mantissa (B,E,D,C) and flip the sign byte at $0CB5; used when adding operands of opposite sign.
FCOMPL:
        LD HL,CHAIN_BREAK_FLAG_12        ; $28E1  21 D8 0C
        LD A,(HL)                        ; $28E4  7E
        CPL                              ; $28E5  2F
        LD (HL),A                        ; $28E6  77
        XOR A                            ; $28E7  AF
        LD L,A                           ; $28E8  6F
        SUB B                            ; $28E9  90
        LD B,A                           ; $28EA  47
        LD A,L                           ; $28EB  7D
        SBC A,E                          ; $28EC  9B
        LD E,A                           ; $28ED  5F
        LD A,L                           ; $28EE  7D
        SBC A,D                          ; $28EF  9A
        LD D,A                           ; $28F0  57
        LD A,L                           ; $28F1  7D
        SBC A,C                          ; $28F2  99
        LD C,A                           ; $28F3  4F
        RET                              ; $28F4  C9
; [RE] Byte-granular mantissa right-shift: shift the 4-byte mantissa right whole bytes by (exponent diff)/8, then fall into the bit-shift remainder.
MANT_SHIFT_BYTES:
        LD B,$00                         ; $28F5  06 00
MANT_SHIFT_BYTES_1:
        SUB $08                          ; $28F7  D6 08
        JR C,MANT_SHIFT_BYTES_2          ; $28F9  38 07
        LD B,E                           ; $28FB  43
        LD E,D                           ; $28FC  5A
        LD D,C                           ; $28FD  51
        LD C,$00                         ; $28FE  0E 00
        JR MANT_SHIFT_BYTES_1            ; $2900  18 F5
MANT_SHIFT_BYTES_2:
        ADD A,$09                        ; $2902  C6 09
        LD L,A                           ; $2904  6F
        LD A,D                           ; $2905  7A
        OR E                             ; $2906  B3
        OR B                             ; $2907  B0
        JR NZ,MANT_SHIFT_BYTES_4         ; $2908  20 09
        LD A,C                           ; $290A  79
MANT_SHIFT_BYTES_3:
        DEC L                            ; $290B  2D
        RET Z                            ; $290C  C8
        RRA                              ; $290D  1F
        LD C,A                           ; $290E  4F
        JR NC,MANT_SHIFT_BYTES_3         ; $290F  30 FA
        JR MANT_SHIFT_BITS_1             ; $2911  18 06
MANT_SHIFT_BYTES_4:
        XOR A                            ; $2913  AF
        DEC L                            ; $2914  2D
        RET Z                            ; $2915  C8
        LD A,C                           ; $2916  79
; [RE] Bit-granular mantissa right-shift: rotate C,D,E,B right one bit per step to finish exponent alignment.
MANT_SHIFT_BITS:
        RRA                              ; $2917  1F
        LD C,A                           ; $2918  4F
MANT_SHIFT_BITS_1:
        LD A,D                           ; $2919  7A
        RRA                              ; $291A  1F
        LD D,A                           ; $291B  57
        LD A,E                           ; $291C  7B
        RRA                              ; $291D  1F
        LD E,A                           ; $291E  5F
        LD A,B                           ; $291F  78
        RRA                              ; $2920  1F
        LD B,A                           ; $2921  47
        JR MANT_SHIFT_BYTES_4            ; $2922  18 EF
SUB_2922_1:
        NOP                              ; $2924  00
        NOP                              ; $2925  00
        NOP                              ; $2926  00
        ADD A,C                          ; $2927  81
SUB_2922_2:
        INC B                            ; $2928  04
        SBC A,D                          ; $2929  9A
        RST $30                          ; $292A  F7
        ADD HL,DE                        ; $292B  19
        ADD A,E                          ; $292C  83
        INC H                            ; $292D  24
        LD H,E                           ; $292E  63
        LD B,E                           ; $292F  43
        ADD A,E                          ; $2930  83
        LD (HL),L                        ; $2931  75
        CALL $848D                       ; $2932  CD 8D 84
        XOR C                            ; $2935  A9
        LD A,A                           ; $2936  7F
        ADD A,E                          ; $2937  83
        ADD A,D                          ; $2938  82
SUB_2922_3:
        INC B                            ; $2939  04
        NOP                              ; $293A  00
        NOP                              ; $293B  00
        NOP                              ; $293C  00
        ADD A,C                          ; $293D  81
        JP PO,$4DB0                      ; $293E  E2 B0 4D
        ADD A,E                          ; $2941  83
        LD A,(BC)                        ; $2942  0A
        LD (HL),D                        ; $2943  72
        LD DE,$F483                      ; $2944  11 83 F4
        INC B                            ; $2947  04
        DEC (HL)                         ; $2948  35
        LD A,A                           ; $2949  7F
; [RE] SIN() handler (function token $09): sine (MBF; shares the poly evaluator $47C5).
FN_SIN:
        CALL FP_SIGN                     ; $294A  CD C5 2A
        OR A                             ; $294D  B7
        JP PE,GETINT_POSITIVE_1          ; $294E  EA EB 14
        CALL FN_SIN_REDUCE               ; $2951  CD 5D 29
        LD BC,$8031                      ; $2954  01 31 80
        LD DE,$7218                      ; $2957  11 18 72
        JP FMUL                          ; $295A  C3 90 29
; [RE] SIN range reduction / polynomial preprocessor: folds the argument into the principal interval before the Chebyshev poly (CALL $5D65 poly eval); helper for FN_SIN.
FN_SIN_REDUCE:
        CALL FP_LOAD_FAC                 ; $295D  CD 33 2B
        LD A,$80                         ; $2960  3E 80
        LD (CHAIN_BREAK_FLAG_11),A       ; $2962  32 D7 0C
        XOR B                            ; $2965  A8
        PUSH AF                          ; $2966  F5
        CALL FAC_PUSH                    ; $2967  CD 18 2B
        LD HL,SUB_2922_2                 ; $296A  21 28 29
        CALL POLY_EVAL                   ; $296D  CD E3 39
        POP BC                           ; $2970  C1
        POP HL                           ; $2971  E1
        CALL FAC_PUSH                    ; $2972  CD 18 2B
        EX DE,HL                         ; $2975  EB
        CALL FP_STORE_FAC                ; $2976  CD 28 2B
        LD HL,SUB_2922_3                 ; $2979  21 39 29
        CALL POLY_EVAL                   ; $297C  CD E3 39
        POP BC                           ; $297F  C1
        POP DE                           ; $2980  D1
        CALL FDIV                        ; $2981  CD F3 29
        POP AF                           ; $2984  F1
        CALL FAC_PUSH                    ; $2985  CD 18 2B
        CALL FLOAT_A                     ; $2988  CD D4 2A
        POP BC                           ; $298B  C1
        POP DE                           ; $298C  D1
        JP FADD_ALIGN                    ; $298D  C3 24 28
; [RE] MS BASIC-80 floating-point multiply (FMULT): multiply the argument FP value by the FAC (mantissa at $0CB1, exponent $0CB4) using the shift-and-add mantissa loop, producing the product in the FAC.
FMUL:
        CALL FP_SIGN                     ; $2990  CD C5 2A
        RET Z                            ; $2993  C8
        LD L,$00                         ; $2994  2E 00
        CALL EXP_ADD                     ; $2996  CD 84 2A
        LD A,C                           ; $2999  79
        LD (FMUL_4+1),A                  ; $299A  32 C7 29
        EX DE,HL                         ; $299D  EB
        LD (FMUL_3+1),HL                 ; $299E  22 C2 29
        LD BC,$0000                      ; $29A1  01 00 00
        LD D,B                           ; $29A4  50
        LD E,B                           ; $29A5  58
        LD HL,FADD                       ; $29A6  21 74 28
        PUSH HL                          ; $29A9  E5
        LD HL,FMUL_1                     ; $29AA  21 B2 29
        PUSH HL                          ; $29AD  E5
        PUSH HL                          ; $29AE  E5
        LD HL,CHAIN_BREAK_FLAG_9         ; $29AF  21 D4 0C
FMUL_1:
        LD A,(HL)                        ; $29B2  7E
        INC HL                           ; $29B3  23
        OR A                             ; $29B4  B7
        JR Z,FMUL_8                      ; $29B5  28 2C
        PUSH HL                          ; $29B7  E5
        EX DE,HL                         ; $29B8  EB
        LD E,$08                         ; $29B9  1E 08
FMUL_2:
        RRA                              ; $29BB  1F
        LD D,A                           ; $29BC  57
        LD A,C                           ; $29BD  79
        JR NC,FMUL_5                     ; $29BE  30 08
        PUSH DE                          ; $29C0  D5
FMUL_3:
        LD DE,$0000                      ; $29C1  11 00 00
        ADD HL,DE                        ; $29C4  19
        POP DE                           ; $29C5  D1
FMUL_4:
        ADC A,$00                        ; $29C6  CE 00
FMUL_5:
        RRA                              ; $29C8  1F
        LD C,A                           ; $29C9  4F
        LD A,H                           ; $29CA  7C
        RRA                              ; $29CB  1F
        LD H,A                           ; $29CC  67
        LD A,L                           ; $29CD  7D
        RRA                              ; $29CE  1F
        LD L,A                           ; $29CF  6F
        LD A,B                           ; $29D0  78
        RRA                              ; $29D1  1F
        LD B,A                           ; $29D2  47
        AND $10                          ; $29D3  E6 10
        JP Z,FMUL_6                      ; $29D5  CA DC 29
        LD A,B                           ; $29D8  78
        OR $20                           ; $29D9  F6 20
        LD B,A                           ; $29DB  47
FMUL_6:
        DEC E                            ; $29DC  1D
        LD A,D                           ; $29DD  7A
        JR NZ,FMUL_2                     ; $29DE  20 DB
        EX DE,HL                         ; $29E0  EB
FMUL_7:
        POP HL                           ; $29E1  E1
        RET                              ; $29E2  C9
FMUL_8:
        LD B,E                           ; $29E3  43
        LD E,D                           ; $29E4  5A
        LD D,C                           ; $29E5  51
        LD C,A                           ; $29E6  4F
        RET                              ; $29E7  C9
; [RE] FDIV reciprocal-divide setup: pushes the divisor (SUB_4E9A) and constant L_5384, then falls into FDIV restoring-division.
FDIV_BY_TEN:
        CALL FAC_PUSH                    ; $29E8  CD 18 2B
        LD HL,DP_CONST_2                 ; $29EB  21 02 30
        CALL FP_STORE_REGS_LD            ; $29EE  CD 25 2B
FDIV_BY_TEN_1:
        POP BC                           ; $29F1  C1
        POP DE                           ; $29F2  D1
; [RE] MBF floating-point divide: divisor self-modified into the subtract trio ($4D9D/$4DA1/$4DA5), restoring long division of the FAC mantissa, result normalized via FADD_NORMALIZE.
FDIV:
        CALL FP_SIGN                     ; $29F3  CD C5 2A
        JP Z,FIN_EXP_DIGIT_12            ; $29F6  CA DC 32
        LD L,$FF                         ; $29F9  2E FF
        CALL EXP_ADD                     ; $29FB  CD 84 2A
        INC (HL)                         ; $29FE  34
        INC (HL)                         ; $29FF  34
        DEC HL                           ; $2A00  2B
        LD A,(HL)                        ; $2A01  7E
        LD (FDIV_4+1),A                  ; $2A02  32 24 2A
        DEC HL                           ; $2A05  2B
        LD A,(HL)                        ; $2A06  7E
        LD (FDIV_3+1),A                  ; $2A07  32 20 2A
        DEC HL                           ; $2A0A  2B
        LD A,(HL)                        ; $2A0B  7E
        LD (FDIV_2+1),A                  ; $2A0C  32 1C 2A
        LD B,C                           ; $2A0F  41
        EX DE,HL                         ; $2A10  EB
        XOR A                            ; $2A11  AF
        LD C,A                           ; $2A12  4F
        LD D,A                           ; $2A13  57
        LD E,A                           ; $2A14  5F
        LD (FDIV_5+1),A                  ; $2A15  32 27 2A
FDIV_1:
        PUSH HL                          ; $2A18  E5
        PUSH BC                          ; $2A19  C5
        LD A,L                           ; $2A1A  7D
FDIV_2:
        SUB $00                          ; $2A1B  D6 00
        LD L,A                           ; $2A1D  6F
        LD A,H                           ; $2A1E  7C
FDIV_3:
        SBC A,$00                        ; $2A1F  DE 00
        LD H,A                           ; $2A21  67
        LD A,B                           ; $2A22  78
FDIV_4:
        SBC A,$00                        ; $2A23  DE 00
        LD B,A                           ; $2A25  47
FDIV_5:
        LD A,$00                         ; $2A26  3E 00
        SBC A,$00                        ; $2A28  DE 00
        CCF                              ; $2A2A  3F
        JR NC,FDIV_6+1                   ; $2A2B  30 07
        LD (FDIV_5+1),A                  ; $2A2D  32 27 2A
        POP AF                           ; $2A30  F1
        POP AF                           ; $2A31  F1
        SCF                              ; $2A32  37
FDIV_6:
        JP NC,$E1C1                      ; $2A33  D2 C1 E1
        LD A,C                           ; $2A36  79
        INC A                            ; $2A37  3C
        DEC A                            ; $2A38  3D
        RRA                              ; $2A39  1F
        JP P,FDIV_8                      ; $2A3A  F2 52 2A
        RLA                              ; $2A3D  17
        LD A,(FDIV_5+1)                  ; $2A3E  3A 27 2A
        RRA                              ; $2A41  1F
        AND $C0                          ; $2A42  E6 C0
        PUSH AF                          ; $2A44  F5
        LD A,B                           ; $2A45  78
        OR H                             ; $2A46  B4
        OR L                             ; $2A47  B5
        JP Z,FDIV_7                      ; $2A48  CA 4D 2A
        LD A,$20                         ; $2A4B  3E 20
FDIV_7:
        POP HL                           ; $2A4D  E1
        OR H                             ; $2A4E  B4
        JP FP_SET_ZERO_8                 ; $2A4F  C3 B7 28
FDIV_8:
        RLA                              ; $2A52  17
        LD A,E                           ; $2A53  7B
        RLA                              ; $2A54  17
        LD E,A                           ; $2A55  5F
        LD A,D                           ; $2A56  7A
        RLA                              ; $2A57  17
        LD D,A                           ; $2A58  57
        LD A,C                           ; $2A59  79
        RLA                              ; $2A5A  17
        LD C,A                           ; $2A5B  4F
        ADD HL,HL                        ; $2A5C  29
        LD A,B                           ; $2A5D  78
        RLA                              ; $2A5E  17
        LD B,A                           ; $2A5F  47
        LD A,(FDIV_5+1)                  ; $2A60  3A 27 2A
        RLA                              ; $2A63  17
        LD (FDIV_5+1),A                  ; $2A64  32 27 2A
        LD A,C                           ; $2A67  79
        OR D                             ; $2A68  B2
        OR E                             ; $2A69  B3
        JR NZ,FDIV_1                     ; $2A6A  20 AC
        PUSH HL                          ; $2A6C  E5
        LD HL,CHAIN_BREAK_FLAG_11        ; $2A6D  21 D7 0C
        DEC (HL)                         ; $2A70  35
        POP HL                           ; $2A71  E1
        JR NZ,FDIV_1                     ; $2A72  20 A4
        JP FP_SET_ZERO                   ; $2A74  C3 87 28
; [RE] MUL/DIV sign+exponent combine: XOR the two operand sign bytes ($0CC0/$0CC1) and add the biased exponents; produces the result sign/exponent for FMUL and FDIV.
MULDIV_SIGN:
        LD A,$FF                         ; $2A77  3E FF
MULDIV_SIGN_1:
        LD L,$AF                         ; $2A79  2E AF
        LD HL,CHAIN_BREAK_FLAG_18        ; $2A7B  21 E3 0C
        LD C,(HL)                        ; $2A7E  4E
        INC HL                           ; $2A7F  23
        XOR (HL)                         ; $2A80  AE
        LD B,A                           ; $2A81  47
        LD L,$00                         ; $2A82  2E 00
; [RE] Add operand exponent (B) to FAC exponent at $0CB4 with overflow/underflow detection; jumps to over/underflow handlers; shared by FMUL/FDIV.
EXP_ADD:
        LD A,B                           ; $2A84  78
        OR A                             ; $2A85  B7
        JR Z,SUB_2AA1_2                  ; $2A86  28 1F
        LD A,L                           ; $2A88  7D
        LD HL,CHAIN_BREAK_FLAG_11        ; $2A89  21 D7 0C
        XOR (HL)                         ; $2A8C  AE
        ADD A,B                          ; $2A8D  80
        LD B,A                           ; $2A8E  47
        RRA                              ; $2A8F  1F
        XOR B                            ; $2A90  A8
        LD A,B                           ; $2A91  78
        JP P,SUB_2AA1_1                  ; $2A92  F2 A6 2A
        ADD A,$80                        ; $2A95  C6 80
        LD (HL),A                        ; $2A97  77
        JP Z,FMUL_7                      ; $2A98  CA E1 29
        CALL FP_UNPACK_MSB               ; $2A9B  CD 52 2B
        LD (HL),A                        ; $2A9E  77
; [RE] Exponent-result finalize: pop saved sign, branch to zero result (FADD clear) on underflow or overflow error on overflow.
DEC_HL_RET:
        DEC HL                           ; $2A9F  2B
        RET                              ; $2AA0  C9
        CALL FP_SIGN                     ; $2AA1  CD C5 2A
        CPL                              ; $2AA4  2F
        POP HL                           ; $2AA5  E1
SUB_2AA1_1:
        OR A                             ; $2AA6  B7
SUB_2AA1_2:
        POP HL                           ; $2AA7  E1
        JP P,FP_SET_ZERO                 ; $2AA8  F2 87 28
        JP FIN_EXP_DIGIT_3               ; $2AAB  C3 AC 32
; [RE] Scale FAC by a small power of two: load FAC, add 2 to the exponent (x4), renormalize via FADD_ALIGN, bump $0CB4; used by SIN/EXP poly scaling.
FP_SCALE2:
        CALL FP_LOAD_FAC                 ; $2AAE  CD 33 2B
        LD A,B                           ; $2AB1  78
        OR A                             ; $2AB2  B7
        RET Z                            ; $2AB3  C8
        ADD A,$02                        ; $2AB4  C6 02
        JP C,FIN_EXP_DIGIT_8             ; $2AB6  DA CC 32
        LD B,A                           ; $2AB9  47
        CALL FADD_ALIGN                  ; $2ABA  CD 24 28
        LD HL,CHAIN_BREAK_FLAG_11        ; $2ABD  21 D7 0C
        INC (HL)                         ; $2AC0  34
        RET NZ                           ; $2AC1  C0
        JP FIN_EXP_DIGIT_8               ; $2AC2  C3 CC 32
; [RE] SIGN of FAC: returns A=0 if exponent($0CB4)=0, else A=$01 (positive) or $FF (negative) from the sign byte $0CB3.
FP_SIGN:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $2AC5  3A D7 0C
        OR A                             ; $2AC8  B7
        RET Z                            ; $2AC9  C8
        LD A,(CHAIN_BREAK_FLAG_10)       ; $2ACA  3A D6 0C
FP_SIGN_1:
        CP $2F                           ; $2ACD  FE 2F
FP_SIGN_2:
        RLA                              ; $2ACF  17
FP_SIGN_3:
        SBC A,A                          ; $2AD0  9F
        RET NZ                           ; $2AD1  C0
        INC A                            ; $2AD2  3C
        RET                              ; $2AD3  C9
; [RE] Float the signed byte in A into the FAC: set exponent $88, clear low mantissa, set sign, normalize via FADD_COMBINE.
FLOAT_A:
        LD B,$88                         ; $2AD4  06 88
        LD DE,$0000                      ; $2AD6  11 00 00
FLOAT_A_1:
        LD HL,CHAIN_BREAK_FLAG_11        ; $2AD9  21 D7 0C
        LD C,A                           ; $2ADC  4F
        LD (HL),B                        ; $2ADD  70
        LD B,$00                         ; $2ADE  06 00
        INC HL                           ; $2AE0  23
        LD (HL),$80                      ; $2AE1  36 80
        RLA                              ; $2AE3  17
        JP FADD_COMBINE                  ; $2AE4  C3 71 28
; [RE] INT() handler (function token $05): floor to integer.
FN_INT:
        CALL FP_TEST_SIGN                ; $2AE7  CD 06 2B
        RET P                            ; $2AEA  F0
; [RE] Negate-FAC-and-continue: toggle the FAC sign (SUB_4E76) then re-dispatch through the integer/type check ($3DC8) path.
FP_NEGATE_CHECKED:
        CALL FRMEVL_TEST_TYPE            ; $2AEB  CD E3 1D
        JP M,INT_NEGATE_FAC              ; $2AEE  FA 61 2E
        JP Z,RAISE_TYPE_MISMATCH         ; $2AF1  CA AA 0D
; [RE] Negate FAC: flip the high (sign) bit of the FAC sign byte at $0CB3.
FP_NEG:
        LD HL,CHAIN_BREAK_FLAG_10        ; $2AF4  21 D6 0C
        LD A,(HL)                        ; $2AF7  7E
        XOR $80                          ; $2AF8  EE 80
        LD (HL),A                        ; $2AFA  77
        RET                              ; $2AFB  C9
; [RE] MID$() handler (function token $03): substring extraction.
FN_MID_STR:
        CALL FP_TEST_SIGN                ; $2AFC  CD 06 2B
; [RE] Store signed 16-bit value in A (sign-extended into HL) into the FAC as an integer (JP FP_STORE_FAC_INT).
INT16_TO_FP:
        LD L,A                           ; $2AFF  6F
        RLA                              ; $2B00  17
        SBC A,A                          ; $2B01  9F
        LD H,A                           ; $2B02  67
        JP FP_STORE_FAC_INT              ; $2B03  C3 55 2C
; [RE] Type/sign test for INT-class coercion: $3DC8 type-check, error on zero/string, return sign of mantissa for integer values.
FP_TEST_SIGN:
        CALL FRMEVL_TEST_TYPE            ; $2B06  CD E3 1D
        JP Z,RAISE_TYPE_MISMATCH         ; $2B09  CA AA 0D
        JP P,FP_SIGN                     ; $2B0C  F2 C5 2A
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $2B0F  2A D4 0C
; [RE] Test FAC integer mantissa ($0CB1) for zero and return its sign via the SIGN tail.
FP_MANT_SIGN:
        LD A,H                           ; $2B12  7C
        OR L                             ; $2B13  B5
        RET Z                            ; $2B14  C8
        LD A,H                           ; $2B15  7C
        JR FP_SIGN_2                     ; $2B16  18 B7
; [RE] PUSHF: push the FAC mantissa ($0CB1) and sign/low-exp ($0CB3) onto the stack while preserving the caller return address (EX (SP),HL).
FAC_PUSH:
        EX DE,HL                         ; $2B18  EB
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $2B19  2A D4 0C
        EX (SP),HL                       ; $2B1C  E3
        PUSH HL                          ; $2B1D  E5
        LD HL,(CHAIN_BREAK_FLAG_10)      ; $2B1E  2A D6 0C
        EX (SP),HL                       ; $2B21  E3
        PUSH HL                          ; $2B22  E5
        EX DE,HL                         ; $2B23  EB
        RET                              ; $2B24  C9
; [RE] Load operand at (HL) into regs (SUB_4EB8) then store DE/BC into the FAC; combined load-then-store helper.
FP_STORE_REGS_LD:
        CALL FP_LOAD_MEM                 ; $2B25  CD 36 2B
; [RE] MOVFR: store DE (mantissa low) and B,C (sign/high) into the FAC cells $0CB1/$0CB3.
FP_STORE_FAC:
        EX DE,HL                         ; $2B28  EB
        LD (CHAIN_BREAK_FLAG_9),HL       ; $2B29  22 D4 0C
        LD H,B                           ; $2B2C  60
        LD L,C                           ; $2B2D  69
        LD (CHAIN_BREAK_FLAG_10),HL      ; $2B2E  22 D6 0C
        EX DE,HL                         ; $2B31  EB
        RET                              ; $2B32  C9
; [RE] MOVRF: load the FAC ($0CB1) 4-byte mantissa into E,D,C,B.
FP_LOAD_FAC:
        LD HL,CHAIN_BREAK_FLAG_9         ; $2B33  21 D4 0C
; [RE] Load 4 FP mantissa bytes from (HL) into E,D,C,B (advancing HL).
FP_LOAD_MEM:
        LD E,(HL)                        ; $2B36  5E
        INC HL                           ; $2B37  23
; [RE] Load 3 FP bytes from (HL) into D,C,B (entry past the first byte).
FP_LOAD_MEM3:
        LD D,(HL)                        ; $2B38  56
        INC HL                           ; $2B39  23
        LD C,(HL)                        ; $2B3A  4E
        INC HL                           ; $2B3B  23
        LD B,(HL)                        ; $2B3C  46
; [RE] Tail of the (HL)->regs loaders: final INC HL and RET.
FP_LOAD_DONE:
        INC HL                           ; $2B3D  23
        RET                              ; $2B3E  C9
; [RE] MOVE: copy 4 bytes from (DE) into the FAC at $0CB1.
FP_MOVE_TO_FAC:
        LD DE,CHAIN_BREAK_FLAG_9         ; $2B3F  11 D4 0C
; [RE] Block-copy 4 bytes (DE)->(HL); generic FP move primitive.
FP_MOVE4:
        LD B,$04                         ; $2B42  06 04
        JR FP_MOVE_LOOP                  ; $2B44  18 05
FP_MOVE4_1:
        EX DE,HL                         ; $2B46  EB
; [RE] Block-copy (DE)->(HL) of length = current value type ($0B14: 2/3/4/8 bytes); type-aware FP/string move.
FP_MOVE_TYPED:
        LD A,(SUB_0B2A_5)                ; $2B47  3A 37 0B
        LD B,A                           ; $2B4A  47
; [RE] Byte-copy loop body for the FP block moves (DJNZ over B bytes).
FP_MOVE_LOOP:
        LD A,(DE)                        ; $2B4B  1A
        LD (HL),A                        ; $2B4C  77
        INC DE                           ; $2B4D  13
        INC HL                           ; $2B4E  23
        DJNZ FP_MOVE_LOOP                ; $2B4F  10 FA
        RET                              ; $2B51  C9
; [RE] Set the hidden mantissa MSB and extract the sign: force bit7 of $0CB3 high byte, save sign, return rounding bit in A.
FP_UNPACK_MSB:
        LD HL,CHAIN_BREAK_FLAG_10        ; $2B52  21 D6 0C
        LD A,(HL)                        ; $2B55  7E
        RLCA                             ; $2B56  07
        SCF                              ; $2B57  37
        RRA                              ; $2B58  1F
        LD (HL),A                        ; $2B59  77
        CCF                              ; $2B5A  3F
        RRA                              ; $2B5B  1F
        INC HL                           ; $2B5C  23
        INC HL                           ; $2B5D  23
        LD (HL),A                        ; $2B5E  77
        LD A,C                           ; $2B5F  79
        RLCA                             ; $2B60  07
        SCF                              ; $2B61  37
        RRA                              ; $2B62  1F
        LD C,A                           ; $2B63  4F
        RRA                              ; $2B64  1F
        XOR (HL)                         ; $2B65  AE
        RET                              ; $2B66  C9
; [RE] Load second operand from temp ($0CBA) and set up the typed-move target (SUB_4EC4_1) before a compare/op.
FP_ARG_TO_TEMP1:
        LD HL,CHAIN_BREAK_FLAG_17        ; $2B67  21 DD 0C
; [RE] Operand setup: push the typed-move routine, type-check ($3DC8), and select the temp source ($0CAD or $0CB1) for the pending op.
FP_ARG_SETUP1:
        LD DE,FP_MOVE4_1                 ; $2B6A  11 46 2B
        JR FP_ARG_SETUP2_1               ; $2B6D  18 06
; [RE] Load second operand from temp ($0CBA) and set up the type-driven move (SUB_4EC9) before a compare/op.
FP_ARG_TO_TEMP2:
        LD HL,CHAIN_BREAK_FLAG_17        ; $2B6F  21 DD 0C
; [RE] Operand setup variant selecting the typed-move (SUB_4EC9); type-check and pick temp source $0CAD/$0CB1.
FP_ARG_SETUP2:
        LD DE,FP_MOVE_TYPED              ; $2B72  11 47 2B
FP_ARG_SETUP2_1:
        PUSH DE                          ; $2B75  D5
        LD DE,CHAIN_BREAK_FLAG_9         ; $2B76  11 D4 0C
        CALL FRMEVL_TEST_TYPE            ; $2B79  CD E3 1D
        RET C                            ; $2B7C  D8
        LD DE,CHAIN_BREAK_FLAG_6         ; $2B7D  11 D0 0C
        RET                              ; $2B80  C9
; [RE] Floating-point compare (FAC vs regs operand): returns A=0 equal, $01 / $FF for greater/less from sign+exponent+mantissa comparison.
FCOMP:
        LD A,B                           ; $2B81  78
        OR A                             ; $2B82  B7
        JP Z,FP_SIGN                     ; $2B83  CA C5 2A
        LD HL,FP_SIGN_1+1                ; $2B86  21 CE 2A
        PUSH HL                          ; $2B89  E5
        CALL FP_SIGN                     ; $2B8A  CD C5 2A
        LD A,C                           ; $2B8D  79
        RET Z                            ; $2B8E  C8
        LD HL,CHAIN_BREAK_FLAG_10        ; $2B8F  21 D6 0C
        XOR (HL)                         ; $2B92  AE
        LD A,C                           ; $2B93  79
        RET M                            ; $2B94  F8
        CALL FP_MANT_EQ                  ; $2B95  CD 9B 2B
FCOMP_1:
        RRA                              ; $2B98  1F
        XOR C                            ; $2B99  A9
        RET                              ; $2B9A  C9
; [RE] Mantissa-equality test: compare the 4 mantissa bytes (B,C,D,E) against (HL..); on full match pops two return levels (equal).
FP_MANT_EQ:
        INC HL                           ; $2B9B  23
        LD A,B                           ; $2B9C  78
        CP (HL)                          ; $2B9D  BE
        RET NZ                           ; $2B9E  C0
        DEC HL                           ; $2B9F  2B
        LD A,C                           ; $2BA0  79
        CP (HL)                          ; $2BA1  BE
        RET NZ                           ; $2BA2  C0
        DEC HL                           ; $2BA3  2B
        LD A,D                           ; $2BA4  7A
        CP (HL)                          ; $2BA5  BE
        RET NZ                           ; $2BA6  C0
        DEC HL                           ; $2BA7  2B
        LD A,E                           ; $2BA8  7B
        SUB (HL)                         ; $2BA9  96
        RET NZ                           ; $2BAA  C0
        POP HL                           ; $2BAB  E1
        POP HL                           ; $2BAC  E1
        RET                              ; $2BAD  C9
; [RE] 16-bit integer compare of D:E vs H:L returning the SIGN-style -1/0/+1 result via the FP_SIGN tail.
INT16_COMP:
        LD A,D                           ; $2BAE  7A
        XOR H                            ; $2BAF  AC
        LD A,H                           ; $2BB0  7C
        JP M,FP_SIGN_2                   ; $2BB1  FA CF 2A
        CP D                             ; $2BB4  BA
        JP NZ,FP_SIGN_3                  ; $2BB5  C2 D0 2A
        LD A,L                           ; $2BB8  7D
        SUB E                            ; $2BB9  93
        JP NZ,FP_SIGN_3                  ; $2BBA  C2 D0 2A
        RET                              ; $2BBD  C9
; [RE] Compare two FP operands (one in temp $0CBA): sign+exponent then 8-byte mantissa compare; the relational-operator comparator.
DCOMP:
        LD HL,CHAIN_BREAK_FLAG_17        ; $2BBE  21 DD 0C
        CALL FP_MOVE_TYPED               ; $2BC1  CD 47 2B
; [RE] Body of the FP operand compare: byte-by-byte mantissa comparison ($0CC1 down) yielding the ordering result.
DCOMP_BODY:
        LD DE,CHAIN_BREAK_FLAG_19        ; $2BC4  11 E4 0C
        LD A,(DE)                        ; $2BC7  1A
        OR A                             ; $2BC8  B7
        JP Z,FP_SIGN                     ; $2BC9  CA C5 2A
        LD HL,FP_SIGN_1+1                ; $2BCC  21 CE 2A
        PUSH HL                          ; $2BCF  E5
        CALL FP_SIGN                     ; $2BD0  CD C5 2A
        DEC DE                           ; $2BD3  1B
        LD A,(DE)                        ; $2BD4  1A
        LD C,A                           ; $2BD5  4F
        RET Z                            ; $2BD6  C8
        LD HL,CHAIN_BREAK_FLAG_10        ; $2BD7  21 D6 0C
        XOR (HL)                         ; $2BDA  AE
        LD A,C                           ; $2BDB  79
        RET M                            ; $2BDC  F8
        INC DE                           ; $2BDD  13
        INC HL                           ; $2BDE  23
        LD B,$08                         ; $2BDF  06 08
DCOMP_BODY_1:
        LD A,(DE)                        ; $2BE1  1A
        SUB (HL)                         ; $2BE2  96
        JP NZ,FCOMP_1                    ; $2BE3  C2 98 2B
        DEC DE                           ; $2BE6  1B
        DEC HL                           ; $2BE7  2B
        DEC B                            ; $2BE8  05
        JR NZ,DCOMP_BODY_1               ; $2BE9  20 F6
        POP BC                           ; $2BEB  C1
        RET                              ; $2BEC  C9
; [RE] Double-precision relational comparator (OPERATOR_ROUTINE_TBL double-compare slot $050B): CALL DCOMP_BODY then collapse the result to A=-1/0/+1 (FP_SIGN_1+1) -- the double analog of FCOMP.
DCOMP_REL:
        CALL DCOMP_BODY                  ; $2BED  CD C4 2B
        JP NZ,FP_SIGN_1+1                ; $2BF0  C2 CE 2A
        RET                              ; $2BF3  C9
; [RE] LPOS() handler (function token $1A): current line-printer column (CALL $3DC8 = type-check helper). Also used as the integer-coerce entry.
FN_LPOS:
        CALL FRMEVL_TEST_TYPE            ; $2BF4  CD E3 1D
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $2BF7  2A D4 0C
        RET M                            ; $2BFA  F8
        JP Z,RAISE_TYPE_MISMATCH         ; $2BFB  CA AA 0D
        JP PO,FN_LPOS_1                  ; $2BFE  E2 13 2C
        CALL FP_ARG_TO_TEMP2             ; $2C01  CD 6F 2B
        LD HL,FP_CONST_HALF_DBL          ; $2C04  21 56 38
        CALL FP_ARG_SETUP1               ; $2C07  CD 6A 2B
        CALL DADD                        ; $2C0A  CD 8E 2E
        CALL FIX_TO_INT                  ; $2C0D  CD 76 2C
        JP FN_LPOS_2                     ; $2C10  C3 16 2C
FN_LPOS_1:
        CALL FADD_LOAD_CONST             ; $2C13  CD 16 28
FN_LPOS_2:
        LD A,(CHAIN_BREAK_FLAG_10)       ; $2C16  3A D6 0C
        OR A                             ; $2C19  B7
        PUSH AF                          ; $2C1A  F5
        AND $7F                          ; $2C1B  E6 7F
        LD (CHAIN_BREAK_FLAG_10),A       ; $2C1D  32 D6 0C
FN_LPOS_3:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $2C20  3A D7 0C
        CP $90                           ; $2C23  FE 90
        JP NC,RAISE_OVERFLOW             ; $2C25  D2 A4 0D
        CALL FP_SHIFT_MANTISSA           ; $2C28  CD BA 2C
        LD A,(CHAIN_BREAK_FLAG_11)       ; $2C2B  3A D7 0C
        OR A                             ; $2C2E  B7
        JP NZ,FN_LPOS_4                  ; $2C2F  C2 37 2C
        POP AF                           ; $2C32  F1
        EX DE,HL                         ; $2C33  EB
        JP FN_LPOS_5                     ; $2C34  C3 3C 2C
FN_LPOS_4:
        POP AF                           ; $2C37  F1
        EX DE,HL                         ; $2C38  EB
        JP P,FN_LPOS_6                   ; $2C39  F2 42 2C
FN_LPOS_5:
        LD A,H                           ; $2C3C  7C
        CPL                              ; $2C3D  2F
        LD H,A                           ; $2C3E  67
        LD A,L                           ; $2C3F  7D
        CPL                              ; $2C40  2F
        LD L,A                           ; $2C41  6F
FN_LPOS_6:
        JP FP_STORE_FAC_INT              ; $2C42  C3 55 2C
FN_LPOS_7:
        LD HL,RAISE_OVERFLOW             ; $2C45  21 A4 0D
        PUSH HL                          ; $2C48  E5
; [RE] Convert FAC to a 16-bit integer in HL: error if exponent>=$90 (out of range), else shift the mantissa down (FP_SHIFT_MANTISSA).
FP_TO_INT:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $2C49  3A D7 0C
        CP $90                           ; $2C4C  FE 90
        JR NC,FP_TO_INT_RANGE            ; $2C4E  30 0E
        CALL FP_SHIFT_MANTISSA           ; $2C50  CD BA 2C
        EX DE,HL                         ; $2C53  EB
FP_TO_INT_1:
        POP DE                           ; $2C54  D1
; [RE] Store HL into the FAC low cells ($0CB1) and set the value-type to $02 (single) in $0B14 (SUB_4FDA). The MOVFR/integer-into-FAC primitive used throughout the evaluator.
FP_STORE_FAC_INT:
        LD (CHAIN_BREAK_FLAG_9),HL       ; $2C55  22 D4 0C
; [RE] Set the current value-type byte $0B14 to $02 (single precision).
SET_TYPE_SINGLE:
        LD A,$02                         ; $2C58  3E 02
SET_TYPE_SINGLE_1:
        LD (SUB_0B2A_5),A                ; $2C5A  32 37 0B
        RET                              ; $2C5D  C9
; [RE] Range-check helper for FP->int: compare FAC against the $8000 boundary (FCOMP) and finalize the integer result.
FP_TO_INT_RANGE:
        LD BC,$9080                      ; $2C5E  01 80 90
        LD DE,$0000                      ; $2C61  11 00 00
        CALL FCOMP                       ; $2C64  CD 81 2B
        RET NZ                           ; $2C67  C0
        LD H,C                           ; $2C68  61
        LD L,D                           ; $2C69  6A
        JR FP_TO_INT_1                   ; $2C6A  18 E8
; [RE] CINT() handler (function token $1B): coerce to integer.
FN_CINT:
        CALL FRMEVL_TEST_TYPE            ; $2C6C  CD E3 1D
        RET PO                           ; $2C6F  E0
        JP M,INT_TO_SINGLE               ; $2C70  FA 89 2C
        JP Z,RAISE_TYPE_MISMATCH         ; $2C73  CA AA 0D
; [RE] CINT body: load FAC, round/scale to an integer, set the high byte and store back via FADD_NORMALIZE.
FIX_TO_INT:
        CALL FP_LOAD_FAC                 ; $2C76  CD 33 2B
        CALL SET_TYPE_DOUBLE_1+1         ; $2C79  CD AE 2C
        LD A,B                           ; $2C7C  78
        OR A                             ; $2C7D  B7
        RET Z                            ; $2C7E  C8
        CALL FP_UNPACK_MSB               ; $2C7F  CD 52 2B
        LD HL,CHAIN_BREAK_FLAG_8         ; $2C82  21 D3 0C
        LD B,(HL)                        ; $2C85  46
        JP FP_SET_ZERO_7                 ; $2C86  C3 B6 28
; [RE] Convert the signed 16-bit FAC integer ($0CB1) to single precision: build exponent $90 and normalize via FADD_ALIGN.
INT_TO_SINGLE:
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $2C89  2A D4 0C
; [RE] INT_TO_SINGLE entry with the integer already in HL: set type, form exponent $90, normalize.
INT_TO_SINGLE_HL:
        CALL SET_TYPE_DOUBLE_1+1         ; $2C8C  CD AE 2C
        LD A,H                           ; $2C8F  7C
        LD D,L                           ; $2C90  55
        LD E,$00                         ; $2C91  1E 00
        LD B,$90                         ; $2C93  06 90
        JP FLOAT_A_1                     ; $2C95  C3 D9 2A
; [RE] CSNG() handler (function token $1C): coerce to single precision.
FN_CSNG:
        CALL FRMEVL_TEST_TYPE            ; $2C98  CD E3 1D
        RET NC                           ; $2C9B  D0
        JP Z,RAISE_TYPE_MISMATCH         ; $2C9C  CA AA 0D
        CALL M,INT_TO_SINGLE             ; $2C9F  FC 89 2C
; [RE] Clear the FAC double-precision extension cells ($0CAD/$0CAF) when widening to single.
FP_CLEAR_EXT:
        LD HL,$0000                      ; $2CA2  21 00 00
        LD (CHAIN_BREAK_FLAG_6),HL       ; $2CA5  22 D0 0C
        LD (CHAIN_BREAK_FLAG_7),HL       ; $2CA8  22 D2 0C
; [RE] Set value type for a single (BC=$043E length/exp pair) and store type byte; entry used when promoting an integer to FP.
SET_TYPE_DOUBLE:
        LD A,$08                         ; $2CAB  3E 08
SET_TYPE_DOUBLE_1:
        LD BC,$043E                      ; $2CAD  01 3E 04
        JP SET_TYPE_SINGLE_1             ; $2CB0  C3 5A 2C
; [RE] Type-check requiring a numeric value; error ($0D87) if string/zero -- gatekeeper for an INT-class operation.
FP_INT_CHECK:
        CALL FRMEVL_TEST_TYPE            ; $2CB3  CD E3 1D
        RET Z                            ; $2CB6  C8
        JP RAISE_TYPE_MISMATCH           ; $2CB7  C3 AA 0D
; [RE] FP mantissa right-shift / denormalize-align helper: shifts the FAC mantissa (B,C,D,E build the 4-byte mantissa) right by the exponent difference so two FP values can be added; common to FADD/FP_INT.
FP_SHIFT_MANTISSA:
        LD B,A                           ; $2CBA  47
        LD C,A                           ; $2CBB  4F
        LD D,A                           ; $2CBC  57
        LD E,A                           ; $2CBD  5F
        OR A                             ; $2CBE  B7
        RET Z                            ; $2CBF  C8
        PUSH HL                          ; $2CC0  E5
        CALL FP_LOAD_FAC                 ; $2CC1  CD 33 2B
        CALL FP_UNPACK_MSB               ; $2CC4  CD 52 2B
        XOR (HL)                         ; $2CC7  AE
        LD H,A                           ; $2CC8  67
        CALL M,DEC_DE_WITH_BORROW        ; $2CC9  FC DE 2C
        LD A,$98                         ; $2CCC  3E 98
        SUB B                            ; $2CCE  90
        CALL MANT_SHIFT_BYTES            ; $2CCF  CD F5 28
        LD A,H                           ; $2CD2  7C
        RLA                              ; $2CD3  17
        CALL C,FADD_ROUND_CARRY          ; $2CD4  DC C8 28
        LD B,$00                         ; $2CD7  06 00
        CALL C,FCOMPL                    ; $2CD9  DC E1 28
        POP HL                           ; $2CDC  E1
        RET                              ; $2CDD  C9
; [RE] Decrement DE and, on borrow (DE wrapped to $FFFF), fall through to also decrement BC; multi-byte counter for the shift loop.
DEC_DE_WITH_BORROW:
        DEC DE                           ; $2CDE  1B
        LD A,D                           ; $2CDF  7A
        AND E                            ; $2CE0  A3
        INC A                            ; $2CE1  3C
        RET NZ                           ; $2CE2  C0
; [RE] Decrement BC (low half of the shift/round counter) and return.
DEC_BC:
        DEC BC                           ; $2CE3  0B
        RET                              ; $2CE4  C9
; [RE] CDBL() handler (function token $1D): coerce to double precision.
FN_CDBL:
        CALL FRMEVL_TEST_TYPE            ; $2CE5  CD E3 1D
        RET M                            ; $2CE8  F8
        CALL FP_SIGN                     ; $2CE9  CD C5 2A
        JP P,FN_SGN                      ; $2CEC  F2 F8 2C
        CALL FP_NEG                      ; $2CEF  CD F4 2A
        CALL FN_SGN                      ; $2CF2  CD F8 2C
        JP FP_NEGATE_CHECKED             ; $2CF5  C3 EB 2A
; [RE] SGN() handler (function token $04): sign of a number (-1/0/+1).
FN_SGN:
        CALL FRMEVL_TEST_TYPE            ; $2CF8  CD E3 1D
        RET M                            ; $2CFB  F8
        JR NC,FIX_SCALE_1                ; $2CFC  30 1F
        JP Z,RAISE_TYPE_MISMATCH         ; $2CFE  CA AA 0D
        CALL FP_TO_INT                   ; $2D01  CD 49 2C
; [RE] FIX/round scaling: if exponent>=$98 already integral; else shift mantissa down to the integer position and re-round via FADD_COMBINE.
FIX_SCALE:
        LD HL,CHAIN_BREAK_FLAG_11        ; $2D04  21 D7 0C
        LD A,(HL)                        ; $2D07  7E
        CP $98                           ; $2D08  FE 98
        LD A,(CHAIN_BREAK_FLAG_9)        ; $2D0A  3A D4 0C
        RET NC                           ; $2D0D  D0
        LD A,(HL)                        ; $2D0E  7E
        CALL FP_SHIFT_MANTISSA           ; $2D0F  CD BA 2C
        LD (HL),$98                      ; $2D12  36 98
        LD A,E                           ; $2D14  7B
        PUSH AF                          ; $2D15  F5
        LD A,C                           ; $2D16  79
        RLA                              ; $2D17  17
        CALL FADD_COMBINE                ; $2D18  CD 71 28
        POP AF                           ; $2D1B  F1
        RET                              ; $2D1C  C9
FIX_SCALE_1:
        LD HL,CHAIN_BREAK_FLAG_11        ; $2D1D  21 D7 0C
        LD A,(HL)                        ; $2D20  7E
        CP $90                           ; $2D21  FE 90
        JR NZ,FIX_SCALE_4                ; $2D23  20 1A
        LD C,A                           ; $2D25  4F
        DEC HL                           ; $2D26  2B
        LD A,(HL)                        ; $2D27  7E
        XOR $80                          ; $2D28  EE 80
        LD B,$06                         ; $2D2A  06 06
FIX_SCALE_2:
        DEC HL                           ; $2D2C  2B
        OR (HL)                          ; $2D2D  B6
        DEC B                            ; $2D2E  05
        JR NZ,FIX_SCALE_2                ; $2D2F  20 FB
        OR A                             ; $2D31  B7
        LD HL,$8000                      ; $2D32  21 00 80
        JP NZ,FIX_SCALE_3                ; $2D35  C2 3E 2D
        CALL FP_STORE_FAC_INT            ; $2D38  CD 55 2C
        JP FN_CSNG                       ; $2D3B  C3 98 2C
FIX_SCALE_3:
        LD A,C                           ; $2D3E  79
FIX_SCALE_4:
        OR A                             ; $2D3F  B7
        RET Z                            ; $2D40  C8
        CP $B8                           ; $2D41  FE B8
        RET NC                           ; $2D43  D0
; [RE] Denormalize toward the integer point for FIX: set exponent $B8, align the mantissa (SUB_5306) and clear the guard cell $0CAC.
FIX_DENORM:
        PUSH AF                          ; $2D44  F5
        CALL FP_LOAD_FAC                 ; $2D45  CD 33 2B
        CALL FP_UNPACK_MSB               ; $2D48  CD 52 2B
        XOR (HL)                         ; $2D4B  AE
        DEC HL                           ; $2D4C  2B
        LD (HL),$B8                      ; $2D4D  36 B8
        PUSH AF                          ; $2D4F  F5
        DEC HL                           ; $2D50  2B
        LD (HL),C                        ; $2D51  71
        CALL M,DBL_EXT_DEC               ; $2D52  FC 6F 2D
        LD A,(CHAIN_BREAK_FLAG_10)       ; $2D55  3A D6 0C
        LD C,A                           ; $2D58  4F
        LD HL,CHAIN_BREAK_FLAG_10        ; $2D59  21 D6 0C
        LD A,$B8                         ; $2D5C  3E B8
        SUB B                            ; $2D5E  90
        CALL DP_SHIFT_RIGHT_N            ; $2D5F  CD 84 2F
        POP AF                           ; $2D62  F1
        CALL M,DP_ROUND_CARRY            ; $2D63  FC 3F 2F
        XOR A                            ; $2D66  AF
        LD (CHAIN_BREAK_FLAG_5),A        ; $2D67  32 CF 0C
        POP AF                           ; $2D6A  F1
        RET NC                           ; $2D6B  D0
        JP DADD_4                        ; $2D6C  C3 F7 2E
; [RE] Borrow-decrement the FAC double-precision extension bytes from $0CAD upward (propagating the borrow through the low mantissa).
DBL_EXT_DEC:
        LD HL,CHAIN_BREAK_FLAG_6         ; $2D6F  21 D0 0C
DBL_EXT_DEC_1:
        LD A,(HL)                        ; $2D72  7E
        DEC (HL)                         ; $2D73  35
        OR A                             ; $2D74  B7
        INC HL                           ; $2D75  23
        JR Z,DBL_EXT_DEC_1               ; $2D76  28 FA
        RET                              ; $2D78  C9
; [RE] 16x16 unsigned multiply for array subscript/offset computation (callers in PTRGET array code $61BB/$61FD): HL_running*BC accumulated by 16-iteration shift-add into DE; on overflow JP PTRGET_SEARCH_27 -> 'Subscript out of range' (E=$09). Result in DE
ARRAY_INDEX_MUL16:
        PUSH HL                          ; $2D79  E5
        LD HL,$0000                      ; $2D7A  21 00 00
        LD A,B                           ; $2D7D  78
        OR C                             ; $2D7E  B1
        JR Z,ARRAY_INDEX_MUL16_3         ; $2D7F  28 12
        LD A,$10                         ; $2D81  3E 10
ARRAY_INDEX_MUL16_1:
        ADD HL,HL                        ; $2D83  29
        JP C,SUB_3D4E_11                 ; $2D84  DA EA 3D
        EX DE,HL                         ; $2D87  EB
        ADD HL,HL                        ; $2D88  29
        EX DE,HL                         ; $2D89  EB
        JR NC,ARRAY_INDEX_MUL16_2        ; $2D8A  30 04
        ADD HL,BC                        ; $2D8C  09
        JP C,SUB_3D4E_11                 ; $2D8D  DA EA 3D
ARRAY_INDEX_MUL16_2:
        DEC A                            ; $2D90  3D
        JR NZ,ARRAY_INDEX_MUL16_1        ; $2D91  20 F0
ARRAY_INDEX_MUL16_3:
        EX DE,HL                         ; $2D93  EB
        POP HL                           ; $2D94  E1
        RET                              ; $2D95  C9
; [RE] Sign-extend HL into B (LD A,H/RLA/SBC A,A), negate via INT_NEG ($51D9), then SBC the high parts; entry into the signed-integer combine path feeding SUB_5123_1.
INT_SIGNEXT_SUB:
        LD A,H                           ; $2D96  7C
        RLA                              ; $2D97  17
        SBC A,A                          ; $2D98  9F
        LD B,A                           ; $2D99  47
        CALL INT_NEG_STORE               ; $2D9A  CD 57 2E
        LD A,C                           ; $2D9D  79
        SBC A,B                          ; $2D9E  98
        JR IADD_1                        ; $2D9F  18 03
; Integer ADD operator: sign-extend HL and DE, ADD HL,DE with carry into the sign byte, detect signed overflow (JP P to FP_RECOVER $4FD6); on overflow promote both operands to single via FLOAT_FROM_INT ($51F3) and re-add through FADD. MS BASIC-80 integer addition.
IADD:
        LD A,H                           ; $2DA1  7C
        RLA                              ; $2DA2  17
        SBC A,A                          ; $2DA3  9F
IADD_1:
        LD B,A                           ; $2DA4  47
        PUSH HL                          ; $2DA5  E5
        LD A,D                           ; $2DA6  7A
        RLA                              ; $2DA7  17
        SBC A,A                          ; $2DA8  9F
        ADD HL,DE                        ; $2DA9  19
        ADC A,B                          ; $2DAA  88
        RRCA                             ; $2DAB  0F
        XOR H                            ; $2DAC  AC
        JP P,FP_TO_INT_1                 ; $2DAD  F2 54 2C
        PUSH BC                          ; $2DB0  C5
        EX DE,HL                         ; $2DB1  EB
        CALL INT_TO_SINGLE_HL            ; $2DB2  CD 8C 2C
        POP AF                           ; $2DB5  F1
        POP HL                           ; $2DB6  E1
        CALL FAC_PUSH                    ; $2DB7  CD 18 2B
        EX DE,HL                         ; $2DBA  EB
        CALL FLOAT_FROM_INT              ; $2DBB  CD 71 2E
        JP FIN_DONE_1                    ; $2DBE  C3 8F 32
; [RE] 16-bit signed integer multiply (OPERATOR_ROUTINE_TBL integer-multiply slot $051B): sign-normalize then a 16-iteration shift-and-add of BC into HL; on overflow promote both operands to single and re-enter FMUL.
IMUL:
        LD A,H                           ; $2DC1  7C
        OR L                             ; $2DC2  B5
        JP Z,FP_STORE_FAC_INT            ; $2DC3  CA 55 2C
        PUSH HL                          ; $2DC6  E5
        PUSH DE                          ; $2DC7  D5
        CALL INT_SETSIGN_NEG             ; $2DC8  CD 4B 2E
        PUSH BC                          ; $2DCB  C5
        LD B,H                           ; $2DCC  44
        LD C,L                           ; $2DCD  4D
        LD HL,$0000                      ; $2DCE  21 00 00
        LD A,$10                         ; $2DD1  3E 10
IMUL_1:
        ADD HL,HL                        ; $2DD3  29
        JR C,IMULDIV_FINISH_2+1          ; $2DD4  38 1F
        EX DE,HL                         ; $2DD6  EB
        ADD HL,HL                        ; $2DD7  29
        EX DE,HL                         ; $2DD8  EB
        JR NC,IMUL_2                     ; $2DD9  30 04
        ADD HL,BC                        ; $2DDB  09
        JP C,IMULDIV_FINISH_2+1          ; $2DDC  DA F5 2D
IMUL_2:
        DEC A                            ; $2DDF  3D
        JR NZ,IMUL_1                     ; $2DE0  20 F1
        POP BC                           ; $2DE2  C1
        POP DE                           ; $2DE3  D1
; [RE] Tail of integer multiply/divide: test product sign, on overflow promote operands to float and dispatch to FMUL ($4D12) / FADD-store paths; otherwise store signed integer result via INT_NEG/FP_STORE_FAC_INT.
IMULDIV_FINISH:
        LD A,H                           ; $2DE4  7C
        OR A                             ; $2DE5  B7
        JP M,IMULDIV_FINISH_1            ; $2DE6  FA EE 2D
        POP DE                           ; $2DE9  D1
        LD A,B                           ; $2DEA  78
        JP INT_ABS_STORE_1               ; $2DEB  C3 53 2E
IMULDIV_FINISH_1:
        XOR $80                          ; $2DEE  EE 80
        OR L                             ; $2DF0  B5
        JR Z,IMULDIV_FLOAT_FALLBACK      ; $2DF1  28 13
        EX DE,HL                         ; $2DF3  EB
IMULDIV_FINISH_2:
        LD BC,$E1C1                      ; $2DF4  01 C1 E1
        CALL INT_TO_SINGLE_HL            ; $2DF7  CD 8C 2C
        POP HL                           ; $2DFA  E1
        CALL FAC_PUSH                    ; $2DFB  CD 18 2B
        CALL INT_TO_SINGLE_HL            ; $2DFE  CD 8C 2C
IMULDIV_FINISH_3:
        POP BC                           ; $2E01  C1
        POP DE                           ; $2E02  D1
        JP FMUL                          ; $2E03  C3 90 29
; [RE] Float fallback for integer mul/div overflow: if result negative store integer (FP_STORE_FAC_INT $4FD7), else convert and re-enter via SUB_500E and jump to SUB_4E76 (FAC load).
IMULDIV_FLOAT_FALLBACK:
        LD A,B                           ; $2E06  78
        OR A                             ; $2E07  B7
        POP BC                           ; $2E08  C1
        JP M,FP_STORE_FAC_INT            ; $2E09  FA 55 2C
        PUSH DE                          ; $2E0C  D5
        CALL INT_TO_SINGLE_HL            ; $2E0D  CD 8C 2C
        POP DE                           ; $2E10  D1
        JP FP_NEG                        ; $2E11  C3 F4 2A
; 16-bit integer MULTIPLY via shift-and-add: $11 iterations adding BC into the running product in HL, with carry/overflow detection (Overflow error vector $0D72 on zero-operand guard). MS BASIC-80 integer multiply.
INT_DIV_KERNEL:
        LD A,H                           ; $2E14  7C
        OR L                             ; $2E15  B5
        JP Z,RAISE_DIVISION_BY_ZERO      ; $2E16  CA 95 0D
        CALL INT_SETSIGN_NEG             ; $2E19  CD 4B 2E
        PUSH BC                          ; $2E1C  C5
        EX DE,HL                         ; $2E1D  EB
        CALL INT_NEG_STORE               ; $2E1E  CD 57 2E
        LD B,H                           ; $2E21  44
        LD C,L                           ; $2E22  4D
        LD HL,$0000                      ; $2E23  21 00 00
        LD A,$11                         ; $2E26  3E 11
        PUSH AF                          ; $2E28  F5
        OR A                             ; $2E29  B7
        JR INT_DIV_KERNEL_3              ; $2E2A  18 09
INT_DIV_KERNEL_1:
        PUSH AF                          ; $2E2C  F5
        PUSH HL                          ; $2E2D  E5
        ADD HL,BC                        ; $2E2E  09
        JR NC,INT_DIV_KERNEL_2+1         ; $2E2F  30 03
        POP AF                           ; $2E31  F1
        SCF                              ; $2E32  37
INT_DIV_KERNEL_2:
        LD A,$E1                         ; $2E33  3E E1
INT_DIV_KERNEL_3:
        LD A,E                           ; $2E35  7B
        RLA                              ; $2E36  17
        LD E,A                           ; $2E37  5F
        LD A,D                           ; $2E38  7A
        RLA                              ; $2E39  17
        LD D,A                           ; $2E3A  57
        LD A,L                           ; $2E3B  7D
        RLA                              ; $2E3C  17
        LD L,A                           ; $2E3D  6F
        LD A,H                           ; $2E3E  7C
        RLA                              ; $2E3F  17
        LD H,A                           ; $2E40  67
        POP AF                           ; $2E41  F1
        DEC A                            ; $2E42  3D
        JR NZ,INT_DIV_KERNEL_1           ; $2E43  20 E7
        EX DE,HL                         ; $2E45  EB
        POP BC                           ; $2E46  C1
        PUSH DE                          ; $2E47  D5
        JP IMULDIV_FINISH                ; $2E48  C3 E4 2D
; [RE] Combine signs of HL and DE into B, then take absolute value of HL via INT_ABS_STORE; sign-management prologue for signed integer multiply/divide.
INT_SETSIGN_NEG:
        LD A,H                           ; $2E4B  7C
        XOR D                            ; $2E4C  AA
        LD B,A                           ; $2E4D  47
INT_SETSIGN_NEG_1:
        CALL INT_ABS_STORE               ; $2E4E  CD 52 2E
        EX DE,HL                         ; $2E51  EB
; [RE] If HL is non-negative store it as a signed integer to the FAC (FP_STORE_FAC_INT $4FD7); otherwise fall through to INT_NEG to negate first.
INT_ABS_STORE:
        LD A,H                           ; $2E52  7C
INT_ABS_STORE_1:
        OR A                             ; $2E53  B7
        JP P,FP_STORE_FAC_INT            ; $2E54  F2 55 2C
; [RE] Two's-complement negate the 16-bit integer in HL (0-L, 0-H with borrow) then store to the integer FAC via FP_STORE_FAC_INT ($4FD7).
INT_NEG_STORE:
        XOR A                            ; $2E57  AF
        LD C,A                           ; $2E58  4F
        SUB L                            ; $2E59  95
        LD L,A                           ; $2E5A  6F
        LD A,C                           ; $2E5B  79
        SBC A,H                          ; $2E5C  9C
        LD H,A                           ; $2E5D  67
        JP FP_STORE_FAC_INT              ; $2E5E  C3 55 2C
; [RE] Negate the integer FAC: load HL from $0CB1, negate via INT_NEG, return NZ unless result is the $8000 sentinel (then fall into INT_TO_SNG to promote).
INT_NEGATE_FAC:
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $2E61  2A D4 0C
        CALL INT_NEG_STORE               ; $2E64  CD 57 2E
        LD A,H                           ; $2E67  7C
        XOR $80                          ; $2E68  EE 80
        OR L                             ; $2E6A  B5
        RET NZ                           ; $2E6B  C0
; [RE] Promote integer FAC to single-precision: move to DE, set up via SUB_502D, clear A, fall into FLOAT_FROM_INT.
INT_TO_SNG:
        EX DE,HL                         ; $2E6C  EB
        CALL SET_TYPE_DOUBLE_1+1         ; $2E6D  CD AE 2C
        XOR A                            ; $2E70  AF
; Build a single-precision FAC from the signed integer in HL: load binary exponent $98 (2^24 bias) and enter the FP normalize/pack path at SUB_4E5B. MS BASIC-80 float-from-integer.
FLOAT_FROM_INT:
        LD B,$98                         ; $2E71  06 98
        JP FLOAT_A_1                     ; $2E73  C3 D9 2A
; 16-bit integer DIVIDE: multiply-by-reciprocal then RRA-shift the quotient (D:E) into H:L with rounding, store via SUB_4FDA and INT_ABS_STORE. MS BASIC-80 integer divide.
INT_DIV_ROUND:
        PUSH DE                          ; $2E76  D5
        CALL INT_DIV_KERNEL              ; $2E77  CD 14 2E
        XOR A                            ; $2E7A  AF
        ADD A,D                          ; $2E7B  82
        RRA                              ; $2E7C  1F
        LD H,A                           ; $2E7D  67
        LD A,E                           ; $2E7E  7B
        RRA                              ; $2E7F  1F
        LD L,A                           ; $2E80  6F
        CALL SET_TYPE_SINGLE             ; $2E81  CD 58 2C
        POP AF                           ; $2E84  F1
        JR INT_ABS_STORE_1               ; $2E85  18 CC
; [RE] Flip the sign byte of the double-precision operand at $0CC0 (XOR $80), then fall into DADD (double-precision add) to perform a double subtract.
DP_NEGATE_SIGN:
        LD HL,CHAIN_BREAK_FLAG_18        ; $2E87  21 E3 0C
        LD A,(HL)                        ; $2E8A  7E
        XOR $80                          ; $2E8B  EE 80
        LD (HL),A                        ; $2E8D  77
; Double-precision (8-byte mantissa) ADD/SUBTRACT: align the operand exponent at $0CC1 against the accumulator exponent $0CB4, denormalize-shift, add/subtract the 8-byte mantissas at $0CAC vs $0CBA, renormalize. Core of MBF double-precision addition.
DADD:
        LD HL,CHAIN_BREAK_FLAG_19        ; $2E8E  21 E4 0C
        LD A,(HL)                        ; $2E91  7E
        OR A                             ; $2E92  B7
        RET Z                            ; $2E93  C8
        LD B,A                           ; $2E94  47
        DEC HL                           ; $2E95  2B
        LD C,(HL)                        ; $2E96  4E
        LD DE,CHAIN_BREAK_FLAG_11        ; $2E97  11 D7 0C
        LD A,(DE)                        ; $2E9A  1A
        OR A                             ; $2E9B  B7
        JP Z,FP_ARG_TO_TEMP1             ; $2E9C  CA 67 2B
        SUB B                            ; $2E9F  90
        JR NC,DADD_2                     ; $2EA0  30 16
        CPL                              ; $2EA2  2F
        INC A                            ; $2EA3  3C
        PUSH AF                          ; $2EA4  F5
        LD C,$08                         ; $2EA5  0E 08
        INC HL                           ; $2EA7  23
        PUSH HL                          ; $2EA8  E5
DADD_1:
        LD A,(DE)                        ; $2EA9  1A
        LD B,(HL)                        ; $2EAA  46
        LD (HL),A                        ; $2EAB  77
        LD A,B                           ; $2EAC  78
        LD (DE),A                        ; $2EAD  12
        DEC DE                           ; $2EAE  1B
        DEC HL                           ; $2EAF  2B
        DEC C                            ; $2EB0  0D
        JR NZ,DADD_1                     ; $2EB1  20 F6
        POP HL                           ; $2EB3  E1
        LD B,(HL)                        ; $2EB4  46
        DEC HL                           ; $2EB5  2B
        LD C,(HL)                        ; $2EB6  4E
        POP AF                           ; $2EB7  F1
DADD_2:
        CP $39                           ; $2EB8  FE 39
        RET NC                           ; $2EBA  D0
        PUSH AF                          ; $2EBB  F5
        CALL FP_UNPACK_MSB               ; $2EBC  CD 52 2B
        LD HL,CHAIN_BREAK_FLAG_16        ; $2EBF  21 DC 0C
        LD B,A                           ; $2EC2  47
        LD A,$00                         ; $2EC3  3E 00
        LD (HL),A                        ; $2EC5  77
        LD (CHAIN_BREAK_FLAG_5),A        ; $2EC6  32 CF 0C
        POP AF                           ; $2EC9  F1
        LD HL,CHAIN_BREAK_FLAG_18        ; $2ECA  21 E3 0C
        CALL DP_SHIFT_RIGHT_N            ; $2ECD  CD 84 2F
        LD A,(CHAIN_BREAK_FLAG_16)       ; $2ED0  3A DC 0C
        LD (CHAIN_BREAK_FLAG_5),A        ; $2ED3  32 CF 0C
        LD A,B                           ; $2ED6  78
        OR A                             ; $2ED7  B7
        JP P,DADD_3                      ; $2ED8  F2 EC 2E
        CALL DP_ADD_CONST_8E             ; $2EDB  CD 5B 2F
        JP NC,DADD_9                     ; $2EDE  D2 2D 2F
        EX DE,HL                         ; $2EE1  EB
        INC (HL)                         ; $2EE2  34
        JP Z,FIN_EXP_DIGIT_10            ; $2EE3  CA D4 32
        CALL DP_SHIFT_RIGHT_FROM_CB3     ; $2EE6  CD AB 2F
        JP DADD_9                        ; $2EE9  C3 2D 2F
DADD_3:
        LD A,$9E                         ; $2EEC  3E 9E
        CALL DP_ADD_BLOCK_INIT           ; $2EEE  CD 5D 2F
        LD HL,CHAIN_BREAK_FLAG_12        ; $2EF1  21 D8 0C
        CALL C,DP_NEG_MANTISSA           ; $2EF4  DC 72 2F
DADD_4:
        XOR A                            ; $2EF7  AF
DADD_5:
        LD B,A                           ; $2EF8  47
        LD A,(CHAIN_BREAK_FLAG_10)       ; $2EF9  3A D6 0C
        OR A                             ; $2EFC  B7
        JR NZ,DADD_8                     ; $2EFD  20 1E
        LD HL,CHAIN_BREAK_FLAG_5         ; $2EFF  21 CF 0C
        LD C,$08                         ; $2F02  0E 08
DADD_6:
        LD D,(HL)                        ; $2F04  56
        LD (HL),A                        ; $2F05  77
        LD A,D                           ; $2F06  7A
        INC HL                           ; $2F07  23
        DEC C                            ; $2F08  0D
        JR NZ,DADD_6                     ; $2F09  20 F9
        LD A,B                           ; $2F0B  78
        SUB $08                          ; $2F0C  D6 08
        CP $C0                           ; $2F0E  FE C0
        JR NZ,DADD_5                     ; $2F10  20 E6
        JP FP_SET_ZERO                   ; $2F12  C3 87 28
DADD_7:
        DEC B                            ; $2F15  05
        LD HL,CHAIN_BREAK_FLAG_5         ; $2F16  21 CF 0C
        CALL DP_SHIFT_LEFT_8             ; $2F19  CD B2 2F
        OR A                             ; $2F1C  B7
DADD_8:
        JP P,DADD_7                      ; $2F1D  F2 15 2F
        LD A,B                           ; $2F20  78
        OR A                             ; $2F21  B7
        JR Z,DADD_9                      ; $2F22  28 09
        LD HL,CHAIN_BREAK_FLAG_11        ; $2F24  21 D7 0C
        ADD A,(HL)                       ; $2F27  86
        LD (HL),A                        ; $2F28  77
        JP NC,FP_SET_ZERO                ; $2F29  D2 87 28
        RET Z                            ; $2F2C  C8
DADD_9:
        LD A,(CHAIN_BREAK_FLAG_5)        ; $2F2D  3A CF 0C
DADD_10:
        OR A                             ; $2F30  B7
        CALL M,DP_ROUND_CARRY            ; $2F31  FC 3F 2F
        LD HL,CHAIN_BREAK_FLAG_12        ; $2F34  21 D8 0C
        LD A,(HL)                        ; $2F37  7E
        AND $80                          ; $2F38  E6 80
        DEC HL                           ; $2F3A  2B
        DEC HL                           ; $2F3B  2B
        XOR (HL)                         ; $2F3C  AE
        LD (HL),A                        ; $2F3D  77
        RET                              ; $2F3E  C9
; [RE] Round-up / carry-propagate the 8-byte double mantissa (INC through $0CAD..; on full carry set MSB $80 and bump exponent), called when the high mantissa byte is negative after add.
DP_ROUND_CARRY:
        LD HL,CHAIN_BREAK_FLAG_6         ; $2F3F  21 D0 0C
        LD B,$07                         ; $2F42  06 07
DP_ROUND_CARRY_1:
        INC (HL)                         ; $2F44  34
        RET NZ                           ; $2F45  C0
        INC HL                           ; $2F46  23
        DEC B                            ; $2F47  05
        JR NZ,DP_ROUND_CARRY_1           ; $2F48  20 FA
        INC (HL)                         ; $2F4A  34
        JP Z,FIN_EXP_DIGIT_10            ; $2F4B  CA D4 32
        DEC HL                           ; $2F4E  2B
        LD (HL),$80                      ; $2F4F  36 80
        RET                              ; $2F51  C9
; [RE] Subtract constant $8E from accumulator and add the 7-byte block $0CBA into $0CAD; thin wrapper that presets A and falls into the multi-byte add loop DP_ADD_BLOCK.
DP_SUB_CONST_8E:
        LD DE,CHAIN_BREAK_FLAG_23        ; $2F52  11 00 0D
        LD HL,CHAIN_BREAK_FLAG_17        ; $2F55  21 DD 0C
        JP DP_ADD_BLOCK_1                ; $2F58  C3 63 2F
; [RE] Preset constant $8E (LD A,$8E) for the multi-byte mantissa add, then fall into DP_ADD_BLOCK; used by the double multiply/divide inner loop.
DP_ADD_CONST_8E:
        LD A,$8E                         ; $2F5B  3E 8E
; [RE] Set up source $0CBA and dest $0CAD for a 7-byte chained ADC, store the constant operand byte into the loop, then run DP_ADD_BLOCK.
DP_ADD_BLOCK_INIT:
        LD HL,CHAIN_BREAK_FLAG_17        ; $2F5D  21 DD 0C
; [RE] 7-byte chained add-with-carry loop: ADC each byte of [HL]=$0CBA into [DE]=$0CAD, advancing both pointers. Multi-byte mantissa addition primitive for double-precision arithmetic.
DP_ADD_BLOCK:
        LD DE,CHAIN_BREAK_FLAG_6         ; $2F60  11 D0 0C
DP_ADD_BLOCK_1:
        LD C,$07                         ; $2F63  0E 07
        LD (DP_ADD_BLOCK_3),A            ; $2F65  32 6A 2F
        XOR A                            ; $2F68  AF
DP_ADD_BLOCK_2:
        LD A,(DE)                        ; $2F69  1A
DP_ADD_BLOCK_3:
        ADC A,(HL)                       ; $2F6A  8E
        LD (DE),A                        ; $2F6B  12
        INC DE                           ; $2F6C  13
        INC HL                           ; $2F6D  23
        DEC C                            ; $2F6E  0D
        JR NZ,DP_ADD_BLOCK_2             ; $2F6F  20 F8
        RET                              ; $2F71  C9
; [RE] Two's-complement negate the 8-byte double mantissa starting at $0CAC (CPL the guard byte, then chained 0-byte SBC across 8 bytes).
DP_NEG_MANTISSA:
        LD A,(HL)                        ; $2F72  7E
        CPL                              ; $2F73  2F
        LD (HL),A                        ; $2F74  77
        LD HL,CHAIN_BREAK_FLAG_5         ; $2F75  21 CF 0C
        LD B,$08                         ; $2F78  06 08
        XOR A                            ; $2F7A  AF
        LD C,A                           ; $2F7B  4F
DP_NEG_MANTISSA_1:
        LD A,C                           ; $2F7C  79
        SBC A,(HL)                       ; $2F7D  9E
        LD (HL),A                        ; $2F7E  77
        INC HL                           ; $2F7F  23
        DEC B                            ; $2F80  05
        JR NZ,DP_NEG_MANTISSA_1          ; $2F81  20 F9
        RET                              ; $2F83  C9
; [RE] Denormalize: shift the 8-byte double mantissa right by N bit-positions (in groups of 8 via byte moves, remainder by per-bit RRA) to align exponents before DADD.
DP_SHIFT_RIGHT_N:
        LD (HL),C                        ; $2F84  71
        PUSH HL                          ; $2F85  E5
DP_SHIFT_RIGHT_N_1:
        SUB $08                          ; $2F86  D6 08
        JR C,DP_SHIFT_RIGHT_LOOP_2       ; $2F88  38 0E
DP_SHIFT_RIGHT_N_2:
        POP HL                           ; $2F8A  E1
; [RE] Inner byte/bit right-shift loop for DP_SHIFT_RIGHT_N: moves whole bytes while the shift count exceeds 8, then performs the leftover bit shifts.
DP_SHIFT_RIGHT_LOOP:
        PUSH HL                          ; $2F8B  E5
        LD DE,$0800                      ; $2F8C  11 00 08
DP_SHIFT_RIGHT_LOOP_1:
        LD C,(HL)                        ; $2F8F  4E
        LD (HL),E                        ; $2F90  73
        LD E,C                           ; $2F91  59
        DEC HL                           ; $2F92  2B
        DEC D                            ; $2F93  15
        JR NZ,DP_SHIFT_RIGHT_LOOP_1      ; $2F94  20 F9
        JR DP_SHIFT_RIGHT_N_1            ; $2F96  18 EE
DP_SHIFT_RIGHT_LOOP_2:
        ADD A,$09                        ; $2F98  C6 09
        LD D,A                           ; $2F9A  57
DP_SHIFT_RIGHT_LOOP_3:
        XOR A                            ; $2F9B  AF
        POP HL                           ; $2F9C  E1
        DEC D                            ; $2F9D  15
        RET Z                            ; $2F9E  C8
DP_SHIFT_RIGHT_LOOP_4:
        PUSH HL                          ; $2F9F  E5
        LD E,$08                         ; $2FA0  1E 08
DP_SHIFT_RIGHT_LOOP_5:
        LD A,(HL)                        ; $2FA2  7E
        RRA                              ; $2FA3  1F
        LD (HL),A                        ; $2FA4  77
        DEC HL                           ; $2FA5  2B
        DEC E                            ; $2FA6  1D
        JR NZ,DP_SHIFT_RIGHT_LOOP_5      ; $2FA7  20 F9
        JR DP_SHIFT_RIGHT_LOOP_3         ; $2FA9  18 F0
; [RE] Right-shift the double mantissa by 1 starting at $0CB3 (sets D=$01), used between partial products in the double multiply.
DP_SHIFT_RIGHT_FROM_CB3:
        LD HL,CHAIN_BREAK_FLAG_10        ; $2FAB  21 D6 0C
        LD D,$01                         ; $2FAE  16 01
        JR DP_SHIFT_RIGHT_LOOP_4         ; $2FB0  18 ED
; [RE] Shift the 8-byte double mantissa left by one bit (chained RLA across 8 bytes from [HL]); partial-product accumulation step for double multiply.
DP_SHIFT_LEFT_8:
        LD C,$08                         ; $2FB2  0E 08
; Loop body of DP_SHIFT_LEFT_8: chained RLA across the 8 mantissa bytes from (HL), one bit left, used between partial products in the double-precision multiply (also CALLed at $30DC). Was SUB_2FB4. [RE]
DP_SHIFT_LEFT_8_LOOP:
        LD A,(HL)                        ; $2FB4  7E
        RLA                              ; $2FB5  17
        LD (HL),A                        ; $2FB6  77
        INC HL                           ; $2FB7  23
        DEC C                            ; $2FB8  0D
        JR NZ,DP_SHIFT_LEFT_8_LOOP       ; $2FB9  20 F9
        RET                              ; $2FBB  C9
; Double-precision MULTIPLY: for each of 7 mantissa bytes / 8 bits, conditionally add (DP_ADD_CONST) the multiplicand and shift, accumulating the 8-byte product; guards against multiply-by-zero. MS BASIC-80 double multiply.
DMUL:
        CALL FP_SIGN                     ; $2FBC  CD C5 2A
        RET Z                            ; $2FBF  C8
        LD A,(CHAIN_BREAK_FLAG_19)       ; $2FC0  3A E4 0C
        OR A                             ; $2FC3  B7
        JP Z,FP_SET_ZERO                 ; $2FC4  CA 87 28
        CALL MULDIV_SIGN_1+1             ; $2FC7  CD 7A 2A
        CALL DP_COPY_TEMP                ; $2FCA  CD F2 30
        LD (HL),C                        ; $2FCD  71
        INC DE                           ; $2FCE  13
        LD B,$07                         ; $2FCF  06 07
DMUL_1:
        LD A,(DE)                        ; $2FD1  1A
        INC DE                           ; $2FD2  13
        OR A                             ; $2FD3  B7
        PUSH DE                          ; $2FD4  D5
        JR Z,DMUL_4                      ; $2FD5  28 17
        LD C,$08                         ; $2FD7  0E 08
DMUL_2:
        PUSH BC                          ; $2FD9  C5
        RRA                              ; $2FDA  1F
        LD B,A                           ; $2FDB  47
        CALL C,DP_ADD_CONST_8E           ; $2FDC  DC 5B 2F
        CALL DP_SHIFT_RIGHT_FROM_CB3     ; $2FDF  CD AB 2F
        LD A,B                           ; $2FE2  78
        POP BC                           ; $2FE3  C1
        DEC C                            ; $2FE4  0D
        JR NZ,DMUL_2                     ; $2FE5  20 F2
DMUL_3:
        POP DE                           ; $2FE7  D1
        DEC B                            ; $2FE8  05
        JR NZ,DMUL_1                     ; $2FE9  20 E6
        JP DADD_4                        ; $2FEB  C3 F7 2E
DMUL_4:
        LD HL,CHAIN_BREAK_FLAG_10        ; $2FEE  21 D6 0C
        CALL DP_SHIFT_RIGHT_LOOP         ; $2FF1  CD 8B 2F
        JR DMUL_3                        ; $2FF4  18 F1
; [RE] Double-precision MBF constant (8-byte mantissa $CD CC CC CC CC CC 4C exp $7D ~= 0.1) used as the divide-by-ten reciprocal seed by DDIV/the decimal scaler.
DP_CONST_TENTH:
        CALL $CCCC                       ; $2FF6  CD CC CC
        CALL Z,$CCCC                     ; $2FF9  CC CC CC
        LD C,H                           ; $2FFC  4C
        LD A,L                           ; $2FFD  7D
        NOP                              ; $2FFE  00
        NOP                              ; $2FFF  00
        NOP                              ; $3000  00
        NOP                              ; $3001  00
; [RE] Small double-precision MBF constant ($00 $00 $20 $84) following DP_CONST_TENTH, used as a rounding/scaling constant by the double-precision path.
DP_CONST_2:
        NOP                              ; $3002  00
        NOP                              ; $3003  00
        JR NZ,DP_SHIFT_RIGHT_N_2         ; $3004  20 84
; Double-precision DIVIDE: handle exponent/sign, restoring-division by 15 iterations (DP_PUSH_OPERAND / DADD / DP_POP_OPERAND), building the quotient mantissa; promotes to single (SUB_4E76) when exponent small. MS BASIC-80 double divide.
FIN_DSCALE_DIV10:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $3006  3A D7 0C
        CP $41                           ; $3009  FE 41
        JP NC,FIN_DSCALE_DIV10_1         ; $300B  D2 1A 30
        LD DE,DP_CONST_TENTH             ; $300E  11 F6 2F
        LD HL,CHAIN_BREAK_FLAG_17        ; $3011  21 DD 0C
        CALL FP_MOVE_TYPED               ; $3014  CD 47 2B
        JP DMUL                          ; $3017  C3 BC 2F
FIN_DSCALE_DIV10_1:
        LD A,(CHAIN_BREAK_FLAG_10)       ; $301A  3A D6 0C
        OR A                             ; $301D  B7
        JP P,FIN_DSCALE_DIV10_3          ; $301E  F2 2A 30
        AND $7F                          ; $3021  E6 7F
        LD (CHAIN_BREAK_FLAG_10),A       ; $3023  32 D6 0C
FIN_DSCALE_DIV10_2:
        LD HL,FP_NEG                     ; $3026  21 F4 2A
        PUSH HL                          ; $3029  E5
FIN_DSCALE_DIV10_3:
        CALL DP_DEC_EXP                  ; $302A  CD 66 30
        LD DE,CHAIN_BREAK_FLAG_6         ; $302D  11 D0 0C
        LD HL,CHAIN_BREAK_FLAG_17        ; $3030  21 DD 0C
        CALL FP_MOVE_TYPED               ; $3033  CD 47 2B
        CALL DP_DEC_EXP                  ; $3036  CD 66 30
        CALL DADD                        ; $3039  CD 8E 2E
        LD DE,CHAIN_BREAK_FLAG_6         ; $303C  11 D0 0C
        LD HL,CHAIN_BREAK_FLAG_17        ; $303F  21 DD 0C
        CALL FP_MOVE_TYPED               ; $3042  CD 47 2B
        LD A,$0F                         ; $3045  3E 0F
FIN_DSCALE_DIV10_4:
        PUSH AF                          ; $3047  F5
        CALL DP_DEC_EXP_BY4              ; $3048  CD 6E 30
        CALL DP_PUSH_OPERAND             ; $304B  CD 7A 30
        CALL DADD                        ; $304E  CD 8E 2E
        LD HL,CHAIN_BREAK_FLAG_18        ; $3051  21 E3 0C
        CALL DP_POP_OPERAND              ; $3054  CD 8B 30
        POP AF                           ; $3057  F1
        DEC A                            ; $3058  3D
        JP NZ,FIN_DSCALE_DIV10_4         ; $3059  C2 47 30
        CALL DP_DEC_EXP                  ; $305C  CD 66 30
        CALL DP_DEC_EXP                  ; $305F  CD 66 30
        CALL DP_DEC_EXP                  ; $3062  CD 66 30
        RET                              ; $3065  C9
; [RE] Decrement the double-precision exponent at $0CB4; on underflow to zero jump to FP_ZERO ($4C09). Renormalization step for DMUL/DDIV.
DP_DEC_EXP:
        LD HL,CHAIN_BREAK_FLAG_11        ; $3066  21 D7 0C
        DEC (HL)                         ; $3069  35
        RET NZ                           ; $306A  C0
        JP FP_SET_ZERO                   ; $306B  C3 87 28
; [RE] Decrement the operand exponent byte $0CC1 by up to 4, returning early when it reaches zero; quad-loop counter for the divide reciprocal expansion.
DP_DEC_EXP_BY4:
        LD HL,CHAIN_BREAK_FLAG_19        ; $306E  21 E4 0C
        LD A,$04                         ; $3071  3E 04
DP_DEC_EXP_BY4_1:
        DEC (HL)                         ; $3073  35
        RET Z                            ; $3074  C8
        DEC A                            ; $3075  3D
        JP NZ,DP_DEC_EXP_BY4_1           ; $3076  C2 73 30
        RET                              ; $3079  C9
; [RE] Push the 4 word-pairs of the 8-byte double operand at $0CBA onto the stack (saving the return address), preserving it across an inner DADD in DDIV.
DP_PUSH_OPERAND:
        POP DE                           ; $307A  D1
        LD A,$04                         ; $307B  3E 04
        LD HL,CHAIN_BREAK_FLAG_17        ; $307D  21 DD 0C
DP_PUSH_OPERAND_1:
        LD C,(HL)                        ; $3080  4E
        INC HL                           ; $3081  23
        LD B,(HL)                        ; $3082  46
        INC HL                           ; $3083  23
        PUSH BC                          ; $3084  C5
        DEC A                            ; $3085  3D
        JP NZ,DP_PUSH_OPERAND_1          ; $3086  C2 80 30
        PUSH DE                          ; $3089  D5
        RET                              ; $308A  C9
; [RE] Restore the 8-byte double operand into $0CC1..$0CBA from the stack (inverse of DP_PUSH_OPERAND).
DP_POP_OPERAND:
        POP DE                           ; $308B  D1
        LD A,$04                         ; $308C  3E 04
        LD HL,CHAIN_BREAK_FLAG_19        ; $308E  21 E4 0C
DP_POP_OPERAND_1:
        POP BC                           ; $3091  C1
        LD (HL),B                        ; $3092  70
        DEC HL                           ; $3093  2B
        LD (HL),C                        ; $3094  71
        DEC HL                           ; $3095  2B
        DEC A                            ; $3096  3D
        JP NZ,DP_POP_OPERAND_1           ; $3097  C2 91 30
        PUSH DE                          ; $309A  D5
        RET                              ; $309B  C9
; [RE] Double-precision FIX/INT and decimal-scale helper: validates exponents, copies FAC to temp via DP_COPY_TEMP ($5474), then repeatedly subtracts powers of ten ($9E/$8E constants) to extract integer digits.
DDIV:
        LD A,(CHAIN_BREAK_FLAG_19)       ; $309C  3A E4 0C
        OR A                             ; $309F  B7
        JP Z,FIN_EXP_DIGIT_13            ; $30A0  CA E0 32
        LD A,(CHAIN_BREAK_FLAG_11)       ; $30A3  3A D7 0C
        OR A                             ; $30A6  B7
        JP Z,FP_SET_ZERO                 ; $30A7  CA 87 28
        CALL MULDIV_SIGN                 ; $30AA  CD 77 2A
DDIV_1:
        INC (HL)                         ; $30AD  34
        INC (HL)                         ; $30AE  34
        JP Z,FIN_EXP_DIGIT_10            ; $30AF  CA D4 32
        CALL DP_COPY_TEMP                ; $30B2  CD F2 30
        LD HL,SUB_0D04_2                 ; $30B5  21 07 0D
        LD (HL),C                        ; $30B8  71
        LD B,C                           ; $30B9  41
DDIV_2:
        LD A,$9E                         ; $30BA  3E 9E
        CALL DP_SUB_CONST_8E             ; $30BC  CD 52 2F
        LD A,(DE)                        ; $30BF  1A
        SBC A,C                          ; $30C0  99
        CCF                              ; $30C1  3F
        JR C,DDIV_3+1                    ; $30C2  38 07
        LD A,$8E                         ; $30C4  3E 8E
        CALL DP_SUB_CONST_8E             ; $30C6  CD 52 2F
        XOR A                            ; $30C9  AF
DDIV_3:
        JP C,KWGRP_R+5                   ; $30CA  DA 12 04
        LD A,(CHAIN_BREAK_FLAG_10)       ; $30CD  3A D6 0C
        INC A                            ; $30D0  3C
        DEC A                            ; $30D1  3D
        RRA                              ; $30D2  1F
        JP M,DADD_10                     ; $30D3  FA 30 2F
        RLA                              ; $30D6  17
        LD HL,CHAIN_BREAK_FLAG_6         ; $30D7  21 D0 0C
        LD C,$07                         ; $30DA  0E 07
        CALL DP_SHIFT_LEFT_8_LOOP        ; $30DC  CD B4 2F
        LD HL,CHAIN_BREAK_FLAG_23        ; $30DF  21 00 0D
        CALL DP_SHIFT_LEFT_8             ; $30E2  CD B2 2F
        LD A,B                           ; $30E5  78
        OR A                             ; $30E6  B7
        JR NZ,DDIV_2                     ; $30E7  20 D1
        LD HL,CHAIN_BREAK_FLAG_11        ; $30E9  21 D7 0C
        DEC (HL)                         ; $30EC  35
        JR NZ,DDIV_2                     ; $30ED  20 CB
        JP FP_SET_ZERO                   ; $30EF  C3 87 28
; [RE] Copy the 7-byte double mantissa down into temp buffer $0CE3 (and clear the source), saving the leading byte to $0CC0; scratch save used by DMUL/DDIV/DP_FIX.
DP_COPY_TEMP:
        LD A,C                           ; $30F2  79
        LD (CHAIN_BREAK_FLAG_18),A       ; $30F3  32 E3 0C
        DEC HL                           ; $30F6  2B
        LD DE,SUB_0D04_1                 ; $30F7  11 06 0D
        LD BC,$0700                      ; $30FA  01 00 07
DP_COPY_TEMP_1:
        LD A,(HL)                        ; $30FD  7E
        LD (DE),A                        ; $30FE  12
        LD (HL),C                        ; $30FF  71
        DEC DE                           ; $3100  1B
        DEC HL                           ; $3101  2B
        DEC B                            ; $3102  05
        JR NZ,DP_COPY_TEMP_1             ; $3103  20 F8
        RET                              ; $3105  C9
; [RE] Multiply the double accumulator by ten: bump the mantissa length, add the value to itself shifted (DADD), used by the decimal input/output scaler. Double-precision *10 step.
DP_MUL10:
        CALL FP_ARG_TO_TEMP2             ; $3106  CD 6F 2B
        EX DE,HL                         ; $3109  EB
        DEC HL                           ; $310A  2B
        LD A,(HL)                        ; $310B  7E
        OR A                             ; $310C  B7
        RET Z                            ; $310D  C8
        ADD A,$02                        ; $310E  C6 02
        JP C,FIN_EXP_DIGIT_10            ; $3110  DA D4 32
        LD (HL),A                        ; $3113  77
        PUSH HL                          ; $3114  E5
        CALL DADD                        ; $3115  CD 8E 2E
        POP HL                           ; $3118  E1
        INC (HL)                         ; $3119  34
        RET NZ                           ; $311A  C0
        JP FIN_EXP_DIGIT_10              ; $311B  C3 D4 32
; FIN: parse an ASCII numeric literal into the FAC. Handles leading sign, decimal point, E/D exponent markers, and type suffixes (%=int, !=sng, #=dbl, $=str); accumulates digits with integer->single->double promotion. MS BASIC-80 string-to-number.
FIN:
        CALL FP_SET_ZERO                 ; $311E  CD 87 28
        CALL SET_TYPE_DOUBLE             ; $3121  CD AB 2C
FIN_1:
        OR $AF                           ; $3124  F6 AF
        LD BC,BLOCK_SCAN_FORNEXT_15      ; $3126  01 4C 25
        PUSH BC                          ; $3129  C5
        PUSH AF                          ; $312A  F5
        LD A,$01                         ; $312B  3E 01
        LD (CHAIN_BREAK_FLAG_13),A       ; $312D  32 D9 0C
        POP AF                           ; $3130  F1
        EX DE,HL                         ; $3131  EB
        LD BC,$00FF                      ; $3132  01 FF 00
        LD H,B                           ; $3135  60
        LD L,B                           ; $3136  68
        CALL Z,FP_STORE_FAC_INT          ; $3137  CC 55 2C
        EX DE,HL                         ; $313A  EB
        LD A,(HL)                        ; $313B  7E
        CP $26                           ; $313C  FE 26
        JP Z,SCAN_AMP_RADIX_CONST        ; $313E  CA F6 1C
        CP $2D                           ; $3141  FE 2D
        PUSH AF                          ; $3143  F5
        JP Z,FIN_2                       ; $3144  CA 4C 31
        CP $2B                           ; $3147  FE 2B
        JR Z,FIN_2                       ; $3149  28 01
        DEC HL                           ; $314B  2B
FIN_2:
        CALL CHRGET                      ; $314C  CD E4 13
        JP C,FIN_ACCUM_DIGIT             ; $314F  DA 25 32
        CP $2E                           ; $3152  FE 2E
        JP Z,FIN_11                      ; $3154  CA CE 31
        CP $65                           ; $3157  FE 65
        JR Z,FIN_3                       ; $3159  28 02
        CP $45                           ; $315B  FE 45
FIN_3:
        JP NZ,FIN_6                      ; $315D  C2 81 31
        PUSH HL                          ; $3160  E5
        CALL CHRGET                      ; $3161  CD E4 13
        CP $6C                           ; $3164  FE 6C
        JR Z,FIN_4                       ; $3166  28 0A
        CP $4C                           ; $3168  FE 4C
        JR Z,FIN_4                       ; $316A  28 06
        CP $71                           ; $316C  FE 71
        JR Z,FIN_4                       ; $316E  28 02
        CP $51                           ; $3170  FE 51
FIN_4:
        POP HL                           ; $3172  E1
        JR Z,FIN_5                       ; $3173  28 0B
        LD A,(SUB_0B2A_5)                ; $3175  3A 37 0B
        CP $08                           ; $3178  FE 08
        JR Z,FIN_7                       ; $317A  28 1C
        LD A,$00                         ; $317C  3E 00
        JR FIN_7                         ; $317E  18 18
FIN_5:
        LD A,(HL)                        ; $3180  7E
FIN_6:
        CP $25                           ; $3181  FE 25
        JP Z,FIN_12                      ; $3183  CA DA 31
        CP $23                           ; $3186  FE 23
        JP Z,FIN_13                      ; $3188  CA EA 31
        CP $21                           ; $318B  FE 21
        JP Z,FIN_14                      ; $318D  CA EB 31
        CP $64                           ; $3190  FE 64
        JR Z,FIN_7                       ; $3192  28 04
        CP $44                           ; $3194  FE 44
        JR NZ,FIN_9                      ; $3196  20 16
FIN_7:
        OR A                             ; $3198  B7
        CALL FIN_TYPE_FIXUP              ; $3199  CD F3 31
        CALL CHRGET                      ; $319C  CD E4 13
        CALL FRMEVL_SCAN_UNARY           ; $319F  CD B2 1D
FIN_8:
        CALL CHRGET                      ; $31A2  CD E4 13
        JP C,FIN_EXP_DIGIT               ; $31A5  DA 94 32
        INC D                            ; $31A8  14
        JR NZ,FIN_9                      ; $31A9  20 03
        XOR A                            ; $31AB  AF
        SUB E                            ; $31AC  93
        LD E,A                           ; $31AD  5F
FIN_9:
        PUSH HL                          ; $31AE  E5
        LD A,E                           ; $31AF  7B
        SUB B                            ; $31B0  90
        LD E,A                           ; $31B1  5F
FIN_10:
        CALL P,FIN_MUL10                 ; $31B2  F4 02 32
        CALL M,FIN_DIV10                 ; $31B5  FC 12 32
        JR NZ,FIN_10                     ; $31B8  20 F8
        POP HL                           ; $31BA  E1
        POP AF                           ; $31BB  F1
        PUSH HL                          ; $31BC  E5
        CALL Z,FP_NEGATE_CHECKED         ; $31BD  CC EB 2A
        POP HL                           ; $31C0  E1
        CALL FRMEVL_TEST_TYPE            ; $31C1  CD E3 1D
        RET PE                           ; $31C4  E8
        PUSH HL                          ; $31C5  E5
        LD HL,FMUL_7                     ; $31C6  21 E1 29
        PUSH HL                          ; $31C9  E5
        CALL FP_TO_INT_RANGE             ; $31CA  CD 5E 2C
        RET                              ; $31CD  C9
FIN_11:
        CALL FRMEVL_TEST_TYPE            ; $31CE  CD E3 1D
        INC C                            ; $31D1  0C
        JR NZ,FIN_9                      ; $31D2  20 DA
        CALL C,FIN_TYPE_FIXUP            ; $31D4  DC F3 31
        JP FIN_2                         ; $31D7  C3 4C 31
FIN_12:
        CALL CHRGET                      ; $31DA  CD E4 13
        POP AF                           ; $31DD  F1
        PUSH HL                          ; $31DE  E5
        LD HL,FMUL_7                     ; $31DF  21 E1 29
        PUSH HL                          ; $31E2  E5
        LD HL,FN_LPOS                    ; $31E3  21 F4 2B
        PUSH HL                          ; $31E6  E5
        PUSH AF                          ; $31E7  F5
        JR FIN_9                         ; $31E8  18 C4
FIN_13:
        OR A                             ; $31EA  B7
FIN_14:
        CALL FIN_TYPE_FIXUP              ; $31EB  CD F3 31
        CALL CHRGET                      ; $31EE  CD E4 13
        JR FIN_9                         ; $31F1  18 BB
; [RE] FIN coercion: force the parsed value to integer (FN_CINT) when Z, else to single (FN_CSNG) when NZ, preserving all registers.
FIN_TYPE_FIXUP:
        PUSH HL                          ; $31F3  E5
        PUSH DE                          ; $31F4  D5
        PUSH BC                          ; $31F5  C5
        PUSH AF                          ; $31F6  F5
        CALL Z,FN_CINT                   ; $31F7  CC 6C 2C
        POP AF                           ; $31FA  F1
        CALL NZ,FN_CSNG                  ; $31FB  C4 98 2C
        POP BC                           ; $31FE  C1
        POP DE                           ; $31FF  D1
        POP HL                           ; $3200  E1
        RET                              ; $3201  C9
; [RE] FIN accumulate digit *10: RET if count zero, else multiply the running value by ten using the single-precision (SUB_4E30) or double-precision (DP_MUL10 $5488) path per type parity; returns A decremented.
FIN_MUL10:
        RET Z                            ; $3202  C8
; [RE] Body of FIN_MUL10 (entry past the RET Z guard): performs the *10 multiply by single- or double-precision path.
FIN_MUL10_DO:
        PUSH AF                          ; $3203  F5
        CALL FRMEVL_TEST_TYPE            ; $3204  CD E3 1D
        PUSH AF                          ; $3207  F5
        CALL PO,FP_SCALE2                ; $3208  E4 AE 2A
        POP AF                           ; $320B  F1
        CALL PE,DP_MUL10                 ; $320C  EC 06 31
        POP AF                           ; $320F  F1
; [RE] Shared 'DEC A; RET' counter helper: decrements the digit/exponent count in A. Tail of FIN_MUL10 and called conditionally by the FOUT exponent formatter ($5986)
DEC_A_RET:
        DEC A                            ; $3210  3D
        RET                              ; $3211  C9
; [RE] FIN fractional scale-down: divide the running value by ten via the single-precision (SUB_4D6A) or double-precision (DDIV $5388) path per type parity; returns A incremented to track the decimal exponent.
FIN_DIV10:
        PUSH DE                          ; $3212  D5
        PUSH HL                          ; $3213  E5
        PUSH AF                          ; $3214  F5
        CALL FRMEVL_TEST_TYPE            ; $3215  CD E3 1D
        PUSH AF                          ; $3218  F5
        CALL PO,FDIV_BY_TEN              ; $3219  E4 E8 29
        POP AF                           ; $321C  F1
FIN_DIV10_1:
        CALL PE,FIN_DSCALE_DIV10         ; $321D  EC 06 30
FIN_DIV10_2:
        POP AF                           ; $3220  F1
        POP HL                           ; $3221  E1
        POP DE                           ; $3222  D1
        INC A                            ; $3223  3C
        RET                              ; $3224  C9
; [RE] FIN integer-accumulate a decimal digit into $0CB1 (HL = HL*10 + digit) while the value still fits 16 bits; on overflow it promotes to single/double (constant $9474/$2400) and continues in float.
FIN_ACCUM_DIGIT:
        PUSH DE                          ; $3225  D5
        LD A,B                           ; $3226  78
        ADC A,C                          ; $3227  89
        LD B,A                           ; $3228  47
        PUSH BC                          ; $3229  C5
        PUSH HL                          ; $322A  E5
        LD A,(HL)                        ; $322B  7E
        SUB $30                          ; $322C  D6 30
        PUSH AF                          ; $322E  F5
        CALL FRMEVL_TEST_TYPE            ; $322F  CD E3 1D
        JP P,SUB_3248_4                  ; $3232  F2 5D 32
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $3235  2A D4 0C
        LD DE,CHAIN_BREAK_FLAG_3         ; $3238  11 CD 0C
FIN_ACCUM_DIGIT_1:
        CALL CMP_HL_DE                   ; $323B  CD 9D 45
        JR NC,SUB_3248_3                 ; $323E  30 19
        LD D,H                           ; $3240  54
        LD E,L                           ; $3241  5D
        ADD HL,HL                        ; $3242  29
        ADD HL,HL                        ; $3243  29
        ADD HL,DE                        ; $3244  19
        ADD HL,HL                        ; $3245  29
        POP AF                           ; $3246  F1
        LD C,A                           ; $3247  4F
        ADD HL,BC                        ; $3248  09
        LD A,H                           ; $3249  7C
        OR A                             ; $324A  B7
        JP M,SUB_3248_2                  ; $324B  FA 57 32
        LD (CHAIN_BREAK_FLAG_9),HL       ; $324E  22 D4 0C
SUB_3248_1:
        POP HL                           ; $3251  E1
        POP BC                           ; $3252  C1
        POP DE                           ; $3253  D1
        JP FIN_2                         ; $3254  C3 4C 31
SUB_3248_2:
        LD A,C                           ; $3257  79
        PUSH AF                          ; $3258  F5
SUB_3248_3:
        CALL INT_TO_SINGLE               ; $3259  CD 89 2C
        SCF                              ; $325C  37
SUB_3248_4:
        JR NC,SUB_3248_6                 ; $325D  30 18
        LD BC,$9474                      ; $325F  01 74 94
        LD DE,MSG_UNDEFINED_LINE_2       ; $3262  11 00 24
        CALL FCOMP                       ; $3265  CD 81 2B
        JP P,SUB_3248_5                  ; $3268  F2 74 32
        CALL FP_SCALE2                   ; $326B  CD AE 2A
        POP AF                           ; $326E  F1
        CALL FIN_DONE                    ; $326F  CD 89 32
        JR SUB_3248_1                    ; $3272  18 DD
SUB_3248_5:
        CALL FP_CLEAR_EXT                ; $3274  CD A2 2C
SUB_3248_6:
        CALL DP_MUL10                    ; $3277  CD 06 31
        CALL FP_ARG_TO_TEMP2             ; $327A  CD 6F 2B
        POP AF                           ; $327D  F1
        CALL FLOAT_A                     ; $327E  CD D4 2A
        CALL FP_CLEAR_EXT                ; $3281  CD A2 2C
        CALL DADD                        ; $3284  CD 8E 2E
        JR SUB_3248_1                    ; $3287  18 C8
; [RE] FIN finalize: store the completed FAC (SUB_4E9A / SUB_4E56), unwind the saved registers and dispatch through SUB_4BA6 to return the converted number to the expression evaluator.
FIN_DONE:
        CALL FAC_PUSH                    ; $3289  CD 18 2B
        CALL FLOAT_A                     ; $328C  CD D4 2A
FIN_DONE_1:
        POP BC                           ; $328F  C1
        POP DE                           ; $3290  D1
        JP FADD_ALIGN                    ; $3291  C3 24 28
; [RE] FIN exponent-field digit accumulate: E*10+digit into E with range guard (<10), used while reading the E/D exponent of a numeric literal; errors via $0D81 path on overflow.
FIN_EXP_DIGIT:
        LD A,E                           ; $3294  7B
        CP $0A                           ; $3295  FE 0A
        JR NC,FIN_EXP_DIGIT_1+1          ; $3297  30 09
        RLCA                             ; $3299  07
        RLCA                             ; $329A  07
        ADD A,E                          ; $329B  83
        RLCA                             ; $329C  07
        ADD A,(HL)                       ; $329D  86
        SUB $30                          ; $329E  D6 30
        LD E,A                           ; $32A0  5F
FIN_EXP_DIGIT_1:
        JP M,$7F1E                       ; $32A1  FA 1E 7F
        JP FIN_8                         ; $32A4  C3 A2 31
FIN_EXP_DIGIT_2:
        OR A                             ; $32A7  B7
        JP FIN_EXP_DIGIT_17              ; $32A8  C3 09 33
        POP AF                           ; $32AB  F1
FIN_EXP_DIGIT_3:
        PUSH HL                          ; $32AC  E5
        LD HL,CHAIN_BREAK_FLAG_10        ; $32AD  21 D6 0C
        CALL FRMEVL_TEST_TYPE            ; $32B0  CD E3 1D
        JP PO,FIN_EXP_DIGIT_4            ; $32B3  E2 BC 32
        LD A,(CHAIN_BREAK_FLAG_18)       ; $32B6  3A E3 0C
        JP FIN_EXP_DIGIT_5               ; $32B9  C3 BD 32
FIN_EXP_DIGIT_4:
        LD A,C                           ; $32BC  79
FIN_EXP_DIGIT_5:
        XOR (HL)                         ; $32BD  AE
        RLA                              ; $32BE  17
        POP HL                           ; $32BF  E1
        JP FIN_EXP_DIGIT_17              ; $32C0  C3 09 33
FIN_EXP_DIGIT_6:
        LD A,(CHAIN_BREAK_FLAG_12)       ; $32C3  3A D8 0C
        JP FIN_EXP_DIGIT_11              ; $32C6  C3 D8 32
        POP AF                           ; $32C9  F1
FIN_EXP_DIGIT_7:
        POP AF                           ; $32CA  F1
        POP AF                           ; $32CB  F1
FIN_EXP_DIGIT_8:
        LD A,(CHAIN_BREAK_FLAG_10)       ; $32CC  3A D6 0C
        RLA                              ; $32CF  17
        JP FIN_EXP_DIGIT_17              ; $32D0  C3 09 33
FIN_EXP_DIGIT_9:
        POP AF                           ; $32D3  F1
FIN_EXP_DIGIT_10:
        LD A,(CHAIN_BREAK_FLAG_12)       ; $32D4  3A D8 0C
        CPL                              ; $32D7  2F
FIN_EXP_DIGIT_11:
        RLA                              ; $32D8  17
        JP FIN_EXP_DIGIT_17              ; $32D9  C3 09 33
FIN_EXP_DIGIT_12:
        LD A,C                           ; $32DC  79
        JP FIN_EXP_DIGIT_16              ; $32DD  C3 02 33
FIN_EXP_DIGIT_13:
        PUSH HL                          ; $32E0  E5
        PUSH DE                          ; $32E1  D5
        LD HL,CHAIN_BREAK_FLAG_6         ; $32E2  21 D0 0C
        LD DE,FIN_EXP_DIGIT_25           ; $32E5  11 85 33
        CALL FP_MOVE4                    ; $32E8  CD 42 2B
        LD A,(FIN_EXP_DIGIT_25)          ; $32EB  3A 85 33
        LD (CHAIN_BREAK_FLAG_7),A        ; $32EE  32 D2 0C
        CALL FRMEVL_TEST_TYPE            ; $32F1  CD E3 1D
        JP PO,FIN_EXP_DIGIT_14           ; $32F4  E2 FD 32
        LD A,(CHAIN_BREAK_FLAG_10)       ; $32F7  3A D6 0C
        JP FIN_EXP_DIGIT_15              ; $32FA  C3 00 33
FIN_EXP_DIGIT_14:
        LD A,(CHAIN_BREAK_FLAG_18)       ; $32FD  3A E3 0C
FIN_EXP_DIGIT_15:
        POP DE                           ; $3300  D1
        POP HL                           ; $3301  E1
FIN_EXP_DIGIT_16:
        RLA                              ; $3302  17
        LD HL,ERRMSG_DIVISION_BY_ZERO    ; $3303  21 D0 05
        LD (TXTTAB_1),HL                 ; $3306  22 6B 08
FIN_EXP_DIGIT_17:
        PUSH HL                          ; $3309  E5
        PUSH BC                          ; $330A  C5
        PUSH DE                          ; $330B  D5
        PUSH AF                          ; $330C  F5
        PUSH AF                          ; $330D  F5
        LD HL,(ERRLIN_2)                 ; $330E  2A 89 0B
        LD A,H                           ; $3311  7C
        OR L                             ; $3312  B5
        JP NZ,FIN_EXP_DIGIT_20           ; $3313  C2 3A 33
        LD A,(CHAIN_BREAK_FLAG_13)       ; $3316  3A D9 0C
        OR A                             ; $3319  B7
        JP Z,FIN_EXP_DIGIT_19            ; $331A  CA 27 33
FIN_EXP_DIGIT_18:
        CP $01                           ; $331D  FE 01
        JP NZ,FIN_EXP_DIGIT_20           ; $331F  C2 3A 33
        LD A,$02                         ; $3322  3E 02
        LD (CHAIN_BREAK_FLAG_13),A       ; $3324  32 D9 0C
FIN_EXP_DIGIT_19:
        LD HL,(TXTTAB_1)                 ; $3327  2A 6B 08
        CALL STROUT_NOFLAGS              ; $332A  CD 6A 24
        LD (SUB_0B2A_2),A                ; $332D  32 34 0B
        LD A,$0D                         ; $3330  3E 0D
        CALL STROUT_PUTC                 ; $3332  CD 74 24
        LD A,$0A                         ; $3335  3E 0A
        CALL STROUT_PUTC                 ; $3337  CD 74 24
FIN_EXP_DIGIT_20:
        POP AF                           ; $333A  F1
        LD HL,CHAIN_BREAK_FLAG_9         ; $333B  21 D4 0C
        LD DE,FIN_EXP_DIGIT_24           ; $333E  11 81 33
        JP NC,FIN_EXP_DIGIT_21           ; $3341  D2 47 33
        LD DE,FIN_EXP_DIGIT_25           ; $3344  11 85 33
FIN_EXP_DIGIT_21:
        CALL FP_MOVE4                    ; $3347  CD 42 2B
        CALL FRMEVL_TEST_TYPE            ; $334A  CD E3 1D
        JP PO,FIN_EXP_DIGIT_22           ; $334D  E2 59 33
        LD HL,CHAIN_BREAK_FLAG_6         ; $3350  21 D0 0C
        LD DE,FIN_EXP_DIGIT_25           ; $3353  11 85 33
        CALL FP_MOVE4                    ; $3356  CD 42 2B
FIN_EXP_DIGIT_22:
        LD HL,(ERRLIN_2)                 ; $3359  2A 89 0B
        LD A,H                           ; $335C  7C
        OR L                             ; $335D  B5
        JP Z,FIN_EXP_DIGIT_23            ; $335E  CA 76 33
        LD HL,(TXTTAB_1)                 ; $3361  2A 6B 08
        LD DE,ERRMSG_OVERFLOW            ; $3364  11 77 05
        CALL CMP_HL_DE                   ; $3367  CD 9D 45
        LD HL,ERRMSG_OVERFLOW            ; $336A  21 77 05
        LD (TXTTAB_1),HL                 ; $336D  22 6B 08
        JP Z,RAISE_OVERFLOW              ; $3370  CA A4 0D
        JP RAISE_DIVISION_BY_ZERO        ; $3373  C3 95 0D
FIN_EXP_DIGIT_23:
        POP AF                           ; $3376  F1
        LD HL,ERRMSG_OVERFLOW            ; $3377  21 77 05
        LD (TXTTAB_1),HL                 ; $337A  22 6B 08
        POP DE                           ; $337D  D1
        POP BC                           ; $337E  C1
        POP HL                           ; $337F  E1
        RET                              ; $3380  C9
FIN_EXP_DIGIT_24:
        RST $38                          ; $3381  FF
        RST $38                          ; $3382  FF
        LD A,A                           ; $3383  7F
        RST $38                          ; $3384  FF
FIN_EXP_DIGIT_25:
        RST $38                          ; $3385  FF
        RST $38                          ; $3386  FF
        RST $38                          ; $3387  FF
        RST $38                          ; $3388  FF
; [RE] Print the FOUT-formatted ASCII number string from buffer $0CED via STROUT ($6C40), preserving HL; the console-output wrapper used after FOUT builds the digit string.
FOUT_PRINT:
        PUSH HL                          ; $3389  E5
        LD HL,SUB_0D04_4                 ; $338A  21 10 0D
        CALL STROUT                      ; $338D  CD BE 48
        POP HL                           ; $3390  E1
; MS BASIC-80 FOUT: convert the FP value in the FAC ($0CB1) to a printable decimal ASCII string (sign $2B/$2D, digits, decimal point, E-exponent). Used by PRINT, STR$, and the sign-on free-bytes report. Value type read from $0B14.
FOUT:
        LD BC,PUT_STR_TEMP_2             ; $3391  01 BD 48
        PUSH BC                          ; $3394  C5
        CALL FP_STORE_FAC_INT            ; $3395  CD 55 2C
        XOR A                            ; $3398  AF
        CALL FOUT_SET_FORMAT             ; $3399  CD 1F 34
        OR (HL)                          ; $339C  B6
        JP FOUT_BODY_2                   ; $339D  C3 BC 33
; [RE] MS BASIC-80 FOUT: convert FAC (mantissa $0CB1 / exp $0CB4 / type $0B14) to a decimal/exponential ASCII string in the $0CC3 buffer, A=0 -> no format flags. Returns HL -> string. Used by STR$/PRINT/LIST.
FOUT_2:
        XOR A                            ; $33A0  AF
; [RE] FOUT with PRINT USING format flags in A (stored to $0B4A via FOUT_SET_FORMAT); handles sign placement then dispatches by value type.
FOUT_BODY:
        CALL FOUT_SET_FORMAT             ; $33A1  CD 1F 34
        AND $08                          ; $33A4  E6 08
        JR Z,FOUT_BODY_1                 ; $33A6  28 02
        LD (HL),$2B                      ; $33A8  36 2B
FOUT_BODY_1:
        EX DE,HL                         ; $33AA  EB
        CALL FP_TEST_SIGN                ; $33AB  CD 06 2B
        EX DE,HL                         ; $33AE  EB
        JP P,FOUT_BODY_2                 ; $33AF  F2 BC 33
        LD (HL),$2D                      ; $33B2  36 2D
        PUSH BC                          ; $33B4  C5
        PUSH HL                          ; $33B5  E5
        CALL FP_NEGATE_CHECKED           ; $33B6  CD EB 2A
        POP HL                           ; $33B9  E1
        POP BC                           ; $33BA  C1
        OR H                             ; $33BB  B4
FOUT_BODY_2:
        INC HL                           ; $33BC  23
        LD (HL),$30                      ; $33BD  36 30
        LD A,(FRETOP_1)                  ; $33BF  3A 6D 0B
        LD D,A                           ; $33C2  57
        RLA                              ; $33C3  17
        LD A,(SUB_0B2A_5)                ; $33C4  3A 37 0B
        JP C,FOUT_EXPONENT_6             ; $33C7  DA 40 35
        JP Z,FOUT_EXPONENT_4             ; $33CA  CA 38 35
        CP $04                           ; $33CD  FE 04
        JP NC,FOUT_DOUBLE_FMT            ; $33CF  D2 28 34
        LD BC,$0000                      ; $33D2  01 00 00
        CALL FOUT_DIGITS_INT             ; $33D5  CD 09 38
; [RE] PRINT USING numeric-field scanner: walks the format-image field at $0CC3 ('#', '.', ',', '$', '*', '+', 'E/D' exponent), records width/flags, and rewrites fill characters (space/'*'/'$').
PRUSING_FIELD:
        LD HL,CHAIN_BREAK_FLAG_21        ; $33D8  21 E6 0C
        LD B,(HL)                        ; $33DB  46
        LD C,$20                         ; $33DC  0E 20
        LD A,(FRETOP_1)                  ; $33DE  3A 6D 0B
        LD E,A                           ; $33E1  5F
        AND $20                          ; $33E2  E6 20
        JR Z,PRUSING_FIELD_1             ; $33E4  28 0D
        LD A,B                           ; $33E6  78
        CP C                             ; $33E7  B9
        LD C,$2A                         ; $33E8  0E 2A
        JR NZ,PRUSING_FIELD_1            ; $33EA  20 07
        LD A,E                           ; $33EC  7B
        AND $04                          ; $33ED  E6 04
        JP NZ,PRUSING_FIELD_1            ; $33EF  C2 F3 33
        LD B,C                           ; $33F2  41
PRUSING_FIELD_1:
        LD (HL),C                        ; $33F3  71
        CALL CHRGET                      ; $33F4  CD E4 13
        JR Z,PRUSING_FIELD_2             ; $33F7  28 14
        CP $45                           ; $33F9  FE 45
        JR Z,PRUSING_FIELD_2             ; $33FB  28 10
        CP $44                           ; $33FD  FE 44
        JR Z,PRUSING_FIELD_2             ; $33FF  28 0C
        CP $30                           ; $3401  FE 30
        JR Z,PRUSING_FIELD_1             ; $3403  28 EE
        CP $2C                           ; $3405  FE 2C
        JR Z,PRUSING_FIELD_1             ; $3407  28 EA
        CP $2E                           ; $3409  FE 2E
        JR NZ,PRUSING_FIELD_3            ; $340B  20 03
PRUSING_FIELD_2:
        DEC HL                           ; $340D  2B
        LD (HL),$30                      ; $340E  36 30
PRUSING_FIELD_3:
        LD A,E                           ; $3410  7B
        AND $10                          ; $3411  E6 10
        JR Z,SUB_3415_1                  ; $3413  28 03
        DEC HL                           ; $3415  2B
        LD (HL),$24                      ; $3416  36 24
SUB_3415_1:
        LD A,E                           ; $3418  7B
        AND $04                          ; $3419  E6 04
        RET NZ                           ; $341B  C0
        DEC HL                           ; $341C  2B
        LD (HL),B                        ; $341D  70
SUB_3415_2:
        RET                              ; $341E  C9
; [RE] Store the PRINT USING format byte (A) to $0B4A and reset the output buffer head ($0CC3) to a leading space.
FOUT_SET_FORMAT:
        LD (FRETOP_1),A                  ; $341F  32 6D 0B
        LD HL,CHAIN_BREAK_FLAG_21        ; $3422  21 E6 0C
        LD (HL),$20                      ; $3425  36 20
        RET                              ; $3427  C9
; [RE] FIN core (ASCII -> floating): scans the digit/decimal/exponent text, counts integer+fraction digits, parses the E/D exponent ($CB8 = exp-overflow flag), and converts via the decimal-accumulate path (CALLs FOUT_DIGITS_* / power-of-ten scaling). Returns the value in FAC.
FOUT_DOUBLE_FMT:
        CALL FAC_PUSH                    ; $3428  CD 18 2B
        EX DE,HL                         ; $342B  EB
        LD HL,(CHAIN_BREAK_FLAG_6)       ; $342C  2A D0 0C
        PUSH HL                          ; $342F  E5
        LD HL,(CHAIN_BREAK_FLAG_7)       ; $3430  2A D2 0C
        PUSH HL                          ; $3433  E5
        EX DE,HL                         ; $3434  EB
        PUSH AF                          ; $3435  F5
        XOR A                            ; $3436  AF
        LD (CHAIN_BREAK_FLAG_15),A       ; $3437  32 DB 0C
        POP AF                           ; $343A  F1
        PUSH AF                          ; $343B  F5
        CALL FOUT_CORE                   ; $343C  CD D3 34
        LD B,$45                         ; $343F  06 45
        LD C,$00                         ; $3441  0E 00
FOUT_DOUBLE_FMT_1:
        PUSH HL                          ; $3443  E5
        LD A,(HL)                        ; $3444  7E
FOUT_DOUBLE_FMT_2:
        CP B                             ; $3445  B8
        JP Z,FOUT_DOUBLE_FMT_5           ; $3446  CA 74 34
        CP $3A                           ; $3449  FE 3A
        JP NC,FOUT_DOUBLE_FMT_3          ; $344B  D2 54 34
        CP $30                           ; $344E  FE 30
        JP C,FOUT_DOUBLE_FMT_3           ; $3450  DA 54 34
        INC C                            ; $3453  0C
FOUT_DOUBLE_FMT_3:
        INC HL                           ; $3454  23
        LD A,(HL)                        ; $3455  7E
        OR A                             ; $3456  B7
        JP NZ,FOUT_DOUBLE_FMT_2          ; $3457  C2 45 34
        LD A,$44                         ; $345A  3E 44
        CP B                             ; $345C  B8
        LD B,A                           ; $345D  47
        POP HL                           ; $345E  E1
        LD C,$00                         ; $345F  0E 00
        JP NZ,FOUT_DOUBLE_FMT_1          ; $3461  C2 43 34
FOUT_DOUBLE_FMT_4:
        POP AF                           ; $3464  F1
        POP BC                           ; $3465  C1
        POP DE                           ; $3466  D1
        EX DE,HL                         ; $3467  EB
        LD (CHAIN_BREAK_FLAG_6),HL       ; $3468  22 D0 0C
        LD H,B                           ; $346B  60
        LD L,C                           ; $346C  69
        LD (CHAIN_BREAK_FLAG_7),HL       ; $346D  22 D2 0C
        EX DE,HL                         ; $3470  EB
        POP BC                           ; $3471  C1
        POP DE                           ; $3472  D1
        RET                              ; $3473  C9
FOUT_DOUBLE_FMT_5:
        PUSH BC                          ; $3474  C5
        LD B,$00                         ; $3475  06 00
        INC HL                           ; $3477  23
        LD A,(HL)                        ; $3478  7E
FOUT_DOUBLE_FMT_6:
        CP $2B                           ; $3479  FE 2B
        JP Z,FOUT_DOUBLE_FMT_10          ; $347B  CA BB 34
        CP $2D                           ; $347E  FE 2D
        JP Z,FOUT_DOUBLE_FMT_7           ; $3480  CA 92 34
        SUB $30                          ; $3483  D6 30
        LD C,A                           ; $3485  4F
        LD A,B                           ; $3486  78
        ADD A,A                          ; $3487  87
        ADD A,A                          ; $3488  87
        ADD A,B                          ; $3489  80
        ADD A,A                          ; $348A  87
        ADD A,C                          ; $348B  81
        LD B,A                           ; $348C  47
        CP $10                           ; $348D  FE 10
        JP NC,FOUT_DOUBLE_FMT_10         ; $348F  D2 BB 34
FOUT_DOUBLE_FMT_7:
        INC HL                           ; $3492  23
        LD A,(HL)                        ; $3493  7E
        OR A                             ; $3494  B7
        JP NZ,FOUT_DOUBLE_FMT_6          ; $3495  C2 79 34
        LD H,B                           ; $3498  60
        POP BC                           ; $3499  C1
        LD A,B                           ; $349A  78
        CP $45                           ; $349B  FE 45
        JP NZ,FOUT_DOUBLE_FMT_9          ; $349D  C2 B0 34
        LD A,C                           ; $34A0  79
        ADD A,H                          ; $34A1  84
        CP $09                           ; $34A2  FE 09
        POP HL                           ; $34A4  E1
        JP NC,FOUT_DOUBLE_FMT_4          ; $34A5  D2 64 34
FOUT_DOUBLE_FMT_8:
        LD A,$80                         ; $34A8  3E 80
        LD (CHAIN_BREAK_FLAG_15),A       ; $34AA  32 DB 0C
        JP FOUT_DOUBLE_FMT_11            ; $34AD  C3 C0 34
FOUT_DOUBLE_FMT_9:
        LD A,H                           ; $34B0  7C
        ADD A,C                          ; $34B1  81
        CP $12                           ; $34B2  FE 12
        POP HL                           ; $34B4  E1
        JP NC,FOUT_DOUBLE_FMT_4          ; $34B5  D2 64 34
        JP FOUT_DOUBLE_FMT_8             ; $34B8  C3 A8 34
FOUT_DOUBLE_FMT_10:
        POP BC                           ; $34BB  C1
        POP HL                           ; $34BC  E1
        JP FOUT_DOUBLE_FMT_4             ; $34BD  C3 64 34
FOUT_DOUBLE_FMT_11:
        POP AF                           ; $34C0  F1
        POP BC                           ; $34C1  C1
        POP DE                           ; $34C2  D1
        EX DE,HL                         ; $34C3  EB
        LD (CHAIN_BREAK_FLAG_6),HL       ; $34C4  22 D0 0C
        LD H,B                           ; $34C7  60
        LD L,C                           ; $34C8  69
        LD (CHAIN_BREAK_FLAG_7),HL       ; $34C9  22 D2 0C
        EX DE,HL                         ; $34CC  EB
        POP BC                           ; $34CD  C1
        POP DE                           ; $34CE  D1
        CALL FP_STORE_FAC                ; $34CF  CD 28 2B
        INC HL                           ; $34D2  23
; [RE] FOUT decimal core: rounds the FAC to N significant digits, computes the base-10 exponent, generates the digit string and trims trailing zeros; decides fixed vs E-notation.
FOUT_CORE:
        CP $05                           ; $34D3  FE 05
        PUSH HL                          ; $34D5  E5
        SBC A,$00                        ; $34D6  DE 00
        RLA                              ; $34D8  17
        LD D,A                           ; $34D9  57
        INC D                            ; $34DA  14
        CALL FOUT_SCALE10                ; $34DB  CD BA 36
        LD BC,KWGRP_F+2                  ; $34DE  01 00 03
        PUSH AF                          ; $34E1  F5
        LD A,(CHAIN_BREAK_FLAG_15)       ; $34E2  3A DB 0C
        OR A                             ; $34E5  B7
        JP P,FOUT_CORE_1                 ; $34E6  F2 EE 34
        POP AF                           ; $34E9  F1
        ADD A,D                          ; $34EA  82
        JP FOUT_CORE_2                   ; $34EB  C3 F7 34
FOUT_CORE_1:
        POP AF                           ; $34EE  F1
        ADD A,D                          ; $34EF  82
        JP M,FOUT_CORE_3                 ; $34F0  FA FB 34
        INC D                            ; $34F3  14
        CP D                             ; $34F4  BA
        JR NC,FOUT_CORE_3                ; $34F5  30 04
FOUT_CORE_2:
        INC A                            ; $34F7  3C
        LD B,A                           ; $34F8  47
        LD A,$02                         ; $34F9  3E 02
FOUT_CORE_3:
        SUB $02                          ; $34FB  D6 02
        POP HL                           ; $34FD  E1
        PUSH AF                          ; $34FE  F5
        CALL FOUT_LEADING_FRAC           ; $34FF  CD 51 37
        LD (HL),$30                      ; $3502  36 30
        CALL Z,FP_LOAD_DONE              ; $3504  CC 3D 2B
        CALL FOUT_DIGITS_FRAC            ; $3507  CD 77 37
FOUT_CORE_4:
        DEC HL                           ; $350A  2B
        LD A,(HL)                        ; $350B  7E
        CP $30                           ; $350C  FE 30
        JR Z,FOUT_CORE_4                 ; $350E  28 FA
        CP $2E                           ; $3510  FE 2E
        CALL NZ,FP_LOAD_DONE             ; $3512  C4 3D 2B
        POP AF                           ; $3515  F1
        JR Z,FOUT_EXPONENT_5             ; $3516  28 21
; [RE] Append the exponent suffix (E/D, sign, two decimal digits) to the formatted number and NUL-terminate; also the PRINT USING field-assembly path that interleaves the digit string with the format image (commas, '$', '*', '+'/'-').
FOUT_EXPONENT:
        PUSH AF                          ; $3518  F5
        CALL FRMEVL_TEST_TYPE            ; $3519  CD E3 1D
        LD A,$22                         ; $351C  3E 22
FOUT_EXPONENT_1:
        ADC A,A                          ; $351E  8F
        LD (HL),A                        ; $351F  77
        INC HL                           ; $3520  23
        POP AF                           ; $3521  F1
        LD (HL),$2B                      ; $3522  36 2B
        JP P,FOUT_EXPONENT_2             ; $3524  F2 2B 35
        LD (HL),$2D                      ; $3527  36 2D
        CPL                              ; $3529  2F
        INC A                            ; $352A  3C
FOUT_EXPONENT_2:
        LD B,$2F                         ; $352B  06 2F
FOUT_EXPONENT_3:
        INC B                            ; $352D  04
        SUB $0A                          ; $352E  D6 0A
        JR NC,FOUT_EXPONENT_3            ; $3530  30 FB
        ADD A,$3A                        ; $3532  C6 3A
        INC HL                           ; $3534  23
        LD (HL),B                        ; $3535  70
        INC HL                           ; $3536  23
        LD (HL),A                        ; $3537  77
FOUT_EXPONENT_4:
        INC HL                           ; $3538  23
FOUT_EXPONENT_5:
        LD (HL),$00                      ; $3539  36 00
        EX DE,HL                         ; $353B  EB
        LD HL,CHAIN_BREAK_FLAG_21        ; $353C  21 E6 0C
        RET                              ; $353F  C9
FOUT_EXPONENT_6:
        INC HL                           ; $3540  23
        PUSH BC                          ; $3541  C5
        CP $04                           ; $3542  FE 04
        LD A,D                           ; $3544  7A
        JP NC,FOUT_EXPONENT_15           ; $3545  D2 B3 35
        RRA                              ; $3548  1F
        JP C,FOUT_EXPONENT_27            ; $3549  DA 4D 36
        LD BC,$0603                      ; $354C  01 03 06
        CALL PRUSING_COMMA_FLAG          ; $354F  CD 49 37
        POP DE                           ; $3552  D1
        LD A,D                           ; $3553  7A
        SUB $05                          ; $3554  D6 05
        CALL P,FOUT_EMIT_ZEROS           ; $3556  F4 29 37
        CALL FOUT_DIGITS_INT             ; $3559  CD 09 38
FOUT_EXPONENT_7:
        LD A,E                           ; $355C  7B
        OR A                             ; $355D  B7
        CALL Z,DEC_HL_RET                ; $355E  CC 9F 2A
        DEC A                            ; $3561  3D
        CALL P,FOUT_EMIT_ZEROS           ; $3562  F4 29 37
FOUT_EXPONENT_8:
        PUSH HL                          ; $3565  E5
        CALL PRUSING_FIELD               ; $3566  CD D8 33
        POP HL                           ; $3569  E1
        JR Z,FOUT_EXPONENT_9             ; $356A  28 02
        LD (HL),B                        ; $356C  70
        INC HL                           ; $356D  23
FOUT_EXPONENT_9:
        LD (HL),$00                      ; $356E  36 00
        LD HL,CHAIN_BREAK_FLAG_20        ; $3570  21 E5 0C
FOUT_EXPONENT_10:
        INC HL                           ; $3573  23
FOUT_EXPONENT_11:
        LD A,(FRMEVL_TXTPTR_TEMP)        ; $3574  3A 8C 0B
        SUB L                            ; $3577  95
        SUB D                            ; $3578  92
        RET Z                            ; $3579  C8
        LD A,(HL)                        ; $357A  7E
        CP $20                           ; $357B  FE 20
        JR Z,FOUT_EXPONENT_10            ; $357D  28 F4
        CP $2A                           ; $357F  FE 2A
        JR Z,FOUT_EXPONENT_10            ; $3581  28 F0
        DEC HL                           ; $3583  2B
        PUSH HL                          ; $3584  E5
FOUT_EXPONENT_12:
        PUSH AF                          ; $3585  F5
        LD BC,FOUT_EXPONENT_12           ; $3586  01 85 35
        PUSH BC                          ; $3589  C5
        CALL CHRGET                      ; $358A  CD E4 13
        CP $2D                           ; $358D  FE 2D
        RET Z                            ; $358F  C8
        CP $2B                           ; $3590  FE 2B
        RET Z                            ; $3592  C8
        CP $24                           ; $3593  FE 24
        RET Z                            ; $3595  C8
        POP BC                           ; $3596  C1
        CP $30                           ; $3597  FE 30
        JR NZ,FOUT_EXPONENT_14           ; $3599  20 11
        INC HL                           ; $359B  23
        CALL CHRGET                      ; $359C  CD E4 13
        JR NC,FOUT_EXPONENT_14           ; $359F  30 0B
        DEC HL                           ; $35A1  2B
FOUT_EXPONENT_13:
        LD BC,$772B                      ; $35A2  01 2B 77
        POP AF                           ; $35A5  F1
        JR Z,FOUT_EXPONENT_13+1          ; $35A6  28 FB
        POP BC                           ; $35A8  C1
        JP FOUT_EXPONENT_11              ; $35A9  C3 74 35
FOUT_EXPONENT_14:
        POP AF                           ; $35AC  F1
        JR Z,FOUT_EXPONENT_14            ; $35AD  28 FD
        POP HL                           ; $35AF  E1
        LD (HL),$25                      ; $35B0  36 25
        RET                              ; $35B2  C9
FOUT_EXPONENT_15:
        PUSH HL                          ; $35B3  E5
        RRA                              ; $35B4  1F
        JP C,FOUT_EXPONENT_28            ; $35B5  DA 54 36
        JR Z,FOUT_EXPONENT_17            ; $35B8  28 14
        LD DE,FP_CONST_ENOTATION_THRESHOLD  ; $35BA  11 5E 38
        CALL DCOMP                       ; $35BD  CD BE 2B
        LD D,$10                         ; $35C0  16 10
        JP M,FOUT_EXPONENT_18            ; $35C2  FA DC 35
FOUT_EXPONENT_16:
        POP HL                           ; $35C5  E1
        POP BC                           ; $35C6  C1
        CALL FOUT_2                      ; $35C7  CD A0 33
        DEC HL                           ; $35CA  2B
        LD (HL),$25                      ; $35CB  36 25
        RET                              ; $35CD  C9
FOUT_EXPONENT_17:
        LD BC,$B60E                      ; $35CE  01 0E B6
        LD DE,FRMEVL_OPCOMBINE_8         ; $35D1  11 CA 1B
        CALL FCOMP                       ; $35D4  CD 81 2B
        JP P,FOUT_EXPONENT_16            ; $35D7  F2 C5 35
        LD D,$06                         ; $35DA  16 06
FOUT_EXPONENT_18:
        CALL FP_SIGN                     ; $35DC  CD C5 2A
        CALL NZ,FOUT_SCALE10             ; $35DF  C4 BA 36
        POP HL                           ; $35E2  E1
        POP BC                           ; $35E3  C1
        JP M,FOUT_EXPONENT_19            ; $35E4  FA 01 36
        PUSH BC                          ; $35E7  C5
        LD E,A                           ; $35E8  5F
        LD A,B                           ; $35E9  78
        SUB D                            ; $35EA  92
        SUB E                            ; $35EB  93
        CALL P,FOUT_EMIT_ZEROS           ; $35EC  F4 29 37
        CALL PRUSING_DIGIT_COUNT         ; $35EF  CD 3D 37
        CALL FOUT_DIGITS_FRAC            ; $35F2  CD 77 37
        OR E                             ; $35F5  B3
        CALL NZ,FOUT_EMIT_ZERO_LOOP      ; $35F6  C4 37 37
        OR E                             ; $35F9  B3
        CALL NZ,FOUT_DIGIT_SEP           ; $35FA  C4 64 37
        POP DE                           ; $35FD  D1
        JP FOUT_EXPONENT_7               ; $35FE  C3 5C 35
FOUT_EXPONENT_19:
        LD E,A                           ; $3601  5F
        LD A,C                           ; $3602  79
        OR A                             ; $3603  B7
        CALL NZ,DEC_A_RET                ; $3604  C4 10 32
        ADD A,E                          ; $3607  83
        JP M,FOUT_EXPONENT_20            ; $3608  FA 0C 36
        XOR A                            ; $360B  AF
FOUT_EXPONENT_20:
        PUSH BC                          ; $360C  C5
        PUSH AF                          ; $360D  F5
FOUT_EXPONENT_21:
        CALL M,FIN_DIV10                 ; $360E  FC 12 32
        JP M,FOUT_EXPONENT_21            ; $3611  FA 0E 36
        POP BC                           ; $3614  C1
        LD A,E                           ; $3615  7B
        SUB B                            ; $3616  90
        POP BC                           ; $3617  C1
        LD E,A                           ; $3618  5F
        ADD A,D                          ; $3619  82
        LD A,B                           ; $361A  78
        JP M,FOUT_EXPONENT_23            ; $361B  FA 29 36
FOUT_EXPONENT_22:
        SUB D                            ; $361E  92
        SUB E                            ; $361F  93
        CALL P,FOUT_EMIT_ZEROS           ; $3620  F4 29 37
        PUSH BC                          ; $3623  C5
        CALL PRUSING_DIGIT_COUNT         ; $3624  CD 3D 37
        JR FOUT_EXPONENT_25              ; $3627  18 11
FOUT_EXPONENT_23:
        CALL FOUT_EMIT_ZEROS             ; $3629  CD 29 37
        LD A,C                           ; $362C  79
        CALL FOUT_DECIMAL_POINT          ; $362D  CD 67 37
        LD C,A                           ; $3630  4F
        XOR A                            ; $3631  AF
        SUB D                            ; $3632  92
        SUB E                            ; $3633  93
        CALL FOUT_EMIT_ZEROS             ; $3634  CD 29 37
FOUT_EXPONENT_24:
        PUSH BC                          ; $3637  C5
        LD B,A                           ; $3638  47
        LD C,A                           ; $3639  4F
FOUT_EXPONENT_25:
        CALL FOUT_DIGITS_FRAC            ; $363A  CD 77 37
        POP BC                           ; $363D  C1
        OR C                             ; $363E  B1
        JR NZ,FOUT_EXPONENT_26           ; $363F  20 03
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $3641  2A 8C 0B
FOUT_EXPONENT_26:
        ADD A,E                          ; $3644  83
        DEC A                            ; $3645  3D
        CALL P,FOUT_EMIT_ZEROS           ; $3646  F4 29 37
        LD D,B                           ; $3649  50
        JP FOUT_EXPONENT_8               ; $364A  C3 65 35
FOUT_EXPONENT_27:
        PUSH HL                          ; $364D  E5
        PUSH DE                          ; $364E  D5
        CALL INT_TO_SINGLE               ; $364F  CD 89 2C
        POP DE                           ; $3652  D1
        XOR A                            ; $3653  AF
FOUT_EXPONENT_28:
        JP Z,FOUT_EXPONENT_29+1          ; $3654  CA 5A 36
        LD E,$10                         ; $3657  1E 10
FOUT_EXPONENT_29:
        LD BC,$061E                      ; $3659  01 1E 06
        CALL FP_SIGN                     ; $365C  CD C5 2A
        SCF                              ; $365F  37
        CALL NZ,FOUT_SCALE10             ; $3660  C4 BA 36
        POP HL                           ; $3663  E1
        POP BC                           ; $3664  C1
        PUSH AF                          ; $3665  F5
        LD A,C                           ; $3666  79
        OR A                             ; $3667  B7
        PUSH AF                          ; $3668  F5
        CALL NZ,DEC_A_RET                ; $3669  C4 10 32
        ADD A,B                          ; $366C  80
        LD C,A                           ; $366D  4F
        LD A,D                           ; $366E  7A
        AND $04                          ; $366F  E6 04
        CP $01                           ; $3671  FE 01
        SBC A,A                          ; $3673  9F
        LD D,A                           ; $3674  57
        ADD A,C                          ; $3675  81
        LD C,A                           ; $3676  4F
        SUB E                            ; $3677  93
        PUSH AF                          ; $3678  F5
        PUSH BC                          ; $3679  C5
FOUT_EXPONENT_30:
        CALL M,FIN_DIV10                 ; $367A  FC 12 32
        JP M,FOUT_EXPONENT_30            ; $367D  FA 7A 36
        POP BC                           ; $3680  C1
        POP AF                           ; $3681  F1
        PUSH BC                          ; $3682  C5
        PUSH AF                          ; $3683  F5
        JP M,FOUT_EXPONENT_31            ; $3684  FA 88 36
        XOR A                            ; $3687  AF
FOUT_EXPONENT_31:
        CPL                              ; $3688  2F
        INC A                            ; $3689  3C
        ADD A,B                          ; $368A  80
        INC A                            ; $368B  3C
        ADD A,D                          ; $368C  82
        LD B,A                           ; $368D  47
        LD C,$00                         ; $368E  0E 00
        CALL FOUT_DIGITS_FRAC            ; $3690  CD 77 37
        POP AF                           ; $3693  F1
        CALL P,FOUT_EMIT_ZEROS_DP        ; $3694  F4 31 37
        CALL FOUT_DIGIT_SEP              ; $3697  CD 64 37
        POP BC                           ; $369A  C1
        POP AF                           ; $369B  F1
        JP NZ,FOUT_EXPONENT_32           ; $369C  C2 AB 36
        CALL DEC_HL_RET                  ; $369F  CD 9F 2A
        LD A,(HL)                        ; $36A2  7E
        CP $2E                           ; $36A3  FE 2E
        CALL NZ,FP_LOAD_DONE             ; $36A5  C4 3D 2B
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $36A8  22 8C 0B
FOUT_EXPONENT_32:
        POP AF                           ; $36AB  F1
        JR C,FOUT_EXPONENT_33            ; $36AC  38 03
        ADD A,E                          ; $36AE  83
        SUB B                            ; $36AF  90
        SUB D                            ; $36B0  92
FOUT_EXPONENT_33:
        PUSH BC                          ; $36B1  C5
        CALL FOUT_EXPONENT               ; $36B2  CD 18 35
        EX DE,HL                         ; $36B5  EB
        POP DE                           ; $36B6  D1
        JP FOUT_EXPONENT_8               ; $36B7  C3 65 35
; [RE] Scale FAC into the [1,10) digit-generation range by repeated multiply/divide by powers of ten (tables at $5BC0/$5BC8/$5BD0), tracking the decimal exponent in the saved counter.
FOUT_SCALE10:
        PUSH DE                          ; $36BA  D5
        XOR A                            ; $36BB  AF
        PUSH AF                          ; $36BC  F5
        CALL FRMEVL_TEST_TYPE            ; $36BD  CD E3 1D
        JP PO,FOUT_SCALE10_2             ; $36C0  E2 DD 36
FOUT_SCALE10_1:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $36C3  3A D7 0C
        CP $91                           ; $36C6  FE 91
        JP NC,FOUT_SCALE10_2             ; $36C8  D2 DD 36
        LD DE,FOUT_DIGITS_INT_4          ; $36CB  11 3E 38
        LD HL,CHAIN_BREAK_FLAG_17        ; $36CE  21 DD 0C
        CALL FP_MOVE_TYPED               ; $36D1  CD 47 2B
        CALL DMUL                        ; $36D4  CD BC 2F
        POP AF                           ; $36D7  F1
        SUB $0A                          ; $36D8  D6 0A
        PUSH AF                          ; $36DA  F5
        JR FOUT_SCALE10_1                ; $36DB  18 E6
FOUT_SCALE10_2:
        CALL FOUT_SCALE10_STEP           ; $36DD  CD 0D 37
FOUT_SCALE10_3:
        CALL FRMEVL_TEST_TYPE            ; $36E0  CD E3 1D
        JP PE,FOUT_SCALE10_4             ; $36E3  EA F1 36
        LD BC,$9143                      ; $36E6  01 43 91
        LD DE,$4FF9                      ; $36E9  11 F9 4F
        CALL FCOMP                       ; $36EC  CD 81 2B
        JR FOUT_SCALE10_5                ; $36EF  18 06
FOUT_SCALE10_4:
        LD DE,FOUT_DIGITS_INT_5          ; $36F1  11 46 38
        CALL DCOMP                       ; $36F4  CD BE 2B
FOUT_SCALE10_5:
        JP P,FOUT_SCALE10_7              ; $36F7  F2 09 37
        POP AF                           ; $36FA  F1
        CALL FIN_MUL10_DO                ; $36FB  CD 03 32
        PUSH AF                          ; $36FE  F5
        JR FOUT_SCALE10_3                ; $36FF  18 DF
FOUT_SCALE10_6:
        POP AF                           ; $3701  F1
        CALL FIN_DIV10                   ; $3702  CD 12 32
        PUSH AF                          ; $3705  F5
        CALL FOUT_SCALE10_STEP           ; $3706  CD 0D 37
FOUT_SCALE10_7:
        POP AF                           ; $3709  F1
        OR A                             ; $370A  B7
        POP DE                           ; $370B  D1
        RET                              ; $370C  C9
; [RE] One power-of-ten comparison/normalize step for FOUT_SCALE10: compares FAC against 10 / 1e-? bounds and multiplies or divides as needed.
FOUT_SCALE10_STEP:
        CALL FRMEVL_TEST_TYPE            ; $370D  CD E3 1D
        JP PE,FOUT_SCALE10_STEP_2        ; $3710  EA 1E 37
FOUT_SCALE10_STEP_1:
        LD BC,$9474                      ; $3713  01 74 94
        LD DE,MSG_UNDEFINED_LINE_1       ; $3716  11 F8 23
        CALL FCOMP                       ; $3719  CD 81 2B
        JR FOUT_SCALE10_STEP_3           ; $371C  18 06
FOUT_SCALE10_STEP_2:
        LD DE,FOUT_DIGITS_INT_6          ; $371E  11 4E 38
        CALL DCOMP                       ; $3721  CD BE 2B
FOUT_SCALE10_STEP_3:
        POP HL                           ; $3724  E1
        JP P,FOUT_SCALE10_6              ; $3725  F2 01 37
        JP (HL)                          ; $3728  E9
; [RE] Emit A leading/trailing '0' digits into the output buffer (HL), decrementing A to zero.
FOUT_EMIT_ZEROS:
        OR A                             ; $3729  B7
FOUT_EMIT_ZEROS_1:
        RET Z                            ; $372A  C8
        DEC A                            ; $372B  3D
        LD (HL),$30                      ; $372C  36 30
        INC HL                           ; $372E  23
        JR FOUT_EMIT_ZEROS_1             ; $372F  18 F9
; [RE] Emit A '0' digits, inserting the decimal point / comma separators via FOUT_DIGIT_SEP as the digit position requires (PRINT USING fractional fill).
FOUT_EMIT_ZEROS_DP:
        JR NZ,FOUT_EMIT_ZERO_LOOP        ; $3731  20 04
FOUT_EMIT_ZEROS_DP_1:
        RET Z                            ; $3733  C8
        CALL FOUT_DIGIT_SEP              ; $3734  CD 64 37
; [RE] Inner loop: store a '0' digit, advance, decrement count (shared tail of FOUT_EMIT_ZEROS_DP).
FOUT_EMIT_ZERO_LOOP:
        LD (HL),$30                      ; $3737  36 30
        INC HL                           ; $3739  23
        DEC A                            ; $373A  3D
        JR FOUT_EMIT_ZEROS_DP_1          ; $373B  18 F6
; [RE] Compute the comma-group digit counter (C) and total digit width (B) for a PRINT USING numeric field from the integer/fraction digit counts in D/E.
PRUSING_DIGIT_COUNT:
        LD A,E                           ; $373D  7B
        ADD A,D                          ; $373E  82
        INC A                            ; $373F  3C
        LD B,A                           ; $3740  47
        INC A                            ; $3741  3C
PRUSING_DIGIT_COUNT_1:
        SUB $03                          ; $3742  D6 03
        JR NC,PRUSING_DIGIT_COUNT_1      ; $3744  30 FC
        ADD A,$05                        ; $3746  C6 05
        LD C,A                           ; $3748  4F
; [RE] Test the PRINT USING comma-grouping flag (bit 6 of format byte $0B4A); returns with C set/cleared to enable thousands separators.
PRUSING_COMMA_FLAG:
        LD A,(FRETOP_1)                  ; $3749  3A 6D 0B
        AND $40                          ; $374C  E6 40
        RET NZ                           ; $374E  C0
        LD C,A                           ; $374F  4F
        RET                              ; $3750  C9
; [RE] Emit the decimal point plus leading-zero run for a pure-fraction value (|x|<1): records the decimal-point position at $0B69 and fills '0' digits.
FOUT_LEADING_FRAC:
        DEC B                            ; $3751  05
        JP P,FOUT_DIGIT_SEP_1            ; $3752  F2 65 37
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $3755  22 8C 0B
        LD (HL),$2E                      ; $3758  36 2E
FOUT_LEADING_FRAC_1:
        INC HL                           ; $375A  23
        LD (HL),$30                      ; $375B  36 30
        INC B                            ; $375D  04
        JP NZ,FOUT_LEADING_FRAC_1        ; $375E  C2 5A 37
        INC HL                           ; $3761  23
        LD C,B                           ; $3762  48
        RET                              ; $3763  C9
; [RE] Per-digit separator emitter: drops the decimal point ('.', records pos at $0B69) when the integer digits are exhausted, or a comma every 3 digits when grouping is enabled.
FOUT_DIGIT_SEP:
        DEC B                            ; $3764  05
FOUT_DIGIT_SEP_1:
        JR NZ,FOUT_DECIMAL_POINT_1       ; $3765  20 08
; [RE] Emit the decimal point '.', record its buffer position at $0B69, and (when grouping) reseed the comma counter to 3.
FOUT_DECIMAL_POINT:
        LD (HL),$2E                      ; $3767  36 2E
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $3769  22 8C 0B
        INC HL                           ; $376C  23
        LD C,B                           ; $376D  48
        RET                              ; $376E  C9
FOUT_DECIMAL_POINT_1:
        DEC C                            ; $376F  0D
        RET NZ                           ; $3770  C0
        LD (HL),$2C                      ; $3771  36 2C
        INC HL                           ; $3773  23
        LD C,$03                         ; $3774  0E 03
        RET                              ; $3776  C9
; [RE] Generate fractional decimal digits: repeatedly multiply the FAC fraction by 10 (via the BCD constant tables $5BD8/$5BE8/$5C2E) and emit each integer digit through FOUT_DIGIT_SEP.
FOUT_DIGITS_FRAC:
        PUSH DE                          ; $3777  D5
        CALL FRMEVL_TEST_TYPE            ; $3778  CD E3 1D
        JP PO,FOUT_DIGITS_FRAC_3         ; $377B  E2 C3 37
        PUSH BC                          ; $377E  C5
        PUSH HL                          ; $377F  E5
        CALL FP_ARG_TO_TEMP2             ; $3780  CD 6F 2B
        LD HL,FP_CONST_HALF_DBL          ; $3783  21 56 38
        CALL FP_ARG_SETUP1               ; $3786  CD 6A 2B
        CALL DADD                        ; $3789  CD 8E 2E
        XOR A                            ; $378C  AF
        CALL FIX_DENORM                  ; $378D  CD 44 2D
        POP HL                           ; $3790  E1
        POP BC                           ; $3791  C1
        LD DE,FP_POW10_FRAC_TABLE        ; $3792  11 66 38
        LD A,$0A                         ; $3795  3E 0A
FOUT_DIGITS_FRAC_1:
        CALL FOUT_DIGIT_SEP              ; $3797  CD 64 37
        PUSH BC                          ; $379A  C5
        PUSH AF                          ; $379B  F5
        PUSH HL                          ; $379C  E5
        PUSH DE                          ; $379D  D5
        LD B,$2F                         ; $379E  06 2F
FOUT_DIGITS_FRAC_2:
        INC B                            ; $37A0  04
        POP HL                           ; $37A1  E1
        PUSH HL                          ; $37A2  E5
        LD A,$9E                         ; $37A3  3E 9E
        CALL DP_ADD_BLOCK                ; $37A5  CD 60 2F
        JR NC,FOUT_DIGITS_FRAC_2         ; $37A8  30 F6
        POP HL                           ; $37AA  E1
        LD A,$8E                         ; $37AB  3E 8E
        CALL DP_ADD_BLOCK                ; $37AD  CD 60 2F
        EX DE,HL                         ; $37B0  EB
        POP HL                           ; $37B1  E1
        LD (HL),B                        ; $37B2  70
        INC HL                           ; $37B3  23
        POP AF                           ; $37B4  F1
        POP BC                           ; $37B5  C1
        DEC A                            ; $37B6  3D
        JR NZ,FOUT_DIGITS_FRAC_1         ; $37B7  20 DE
        PUSH BC                          ; $37B9  C5
        PUSH HL                          ; $37BA  E5
        LD HL,CHAIN_BREAK_FLAG_6         ; $37BB  21 D0 0C
        CALL FP_STORE_REGS_LD            ; $37BE  CD 25 2B
        JR FOUT_DIGITS_FRAC_4            ; $37C1  18 0D
FOUT_DIGITS_FRAC_3:
        PUSH BC                          ; $37C3  C5
        PUSH HL                          ; $37C4  E5
        CALL FADD_LOAD_CONST             ; $37C5  CD 16 28
        LD A,$01                         ; $37C8  3E 01
        CALL FP_SHIFT_MANTISSA           ; $37CA  CD BA 2C
        CALL FP_STORE_FAC                ; $37CD  CD 28 2B
FOUT_DIGITS_FRAC_4:
        POP HL                           ; $37D0  E1
        POP BC                           ; $37D1  C1
        XOR A                            ; $37D2  AF
        LD DE,FP_POW10_FRAC_TABLE2       ; $37D3  11 AC 38
FOUT_DIGITS_FRAC_5:
        CCF                              ; $37D6  3F
        CALL FOUT_DIGIT_SEP              ; $37D7  CD 64 37
        PUSH BC                          ; $37DA  C5
        PUSH AF                          ; $37DB  F5
        PUSH HL                          ; $37DC  E5
        PUSH DE                          ; $37DD  D5
        CALL FP_LOAD_FAC                 ; $37DE  CD 33 2B
        POP HL                           ; $37E1  E1
        LD B,$2F                         ; $37E2  06 2F
FOUT_DIGITS_FRAC_6:
        INC B                            ; $37E4  04
        LD A,E                           ; $37E5  7B
        SUB (HL)                         ; $37E6  96
        LD E,A                           ; $37E7  5F
        INC HL                           ; $37E8  23
        LD A,D                           ; $37E9  7A
        SBC A,(HL)                       ; $37EA  9E
        LD D,A                           ; $37EB  57
        INC HL                           ; $37EC  23
        LD A,C                           ; $37ED  79
        SBC A,(HL)                       ; $37EE  9E
        LD C,A                           ; $37EF  4F
        DEC HL                           ; $37F0  2B
        DEC HL                           ; $37F1  2B
        JR NC,FOUT_DIGITS_FRAC_6         ; $37F2  30 F0
        CALL MANT_ADD                    ; $37F4  CD D5 28
        INC HL                           ; $37F7  23
        CALL FP_STORE_FAC                ; $37F8  CD 28 2B
        EX DE,HL                         ; $37FB  EB
        POP HL                           ; $37FC  E1
        LD (HL),B                        ; $37FD  70
        INC HL                           ; $37FE  23
        POP AF                           ; $37FF  F1
        POP BC                           ; $3800  C1
        JR C,FOUT_DIGITS_FRAC_5          ; $3801  38 D3
        INC DE                           ; $3803  13
        INC DE                           ; $3804  13
        LD A,$04                         ; $3805  3E 04
        JR FOUT_DIGITS_INT_1             ; $3807  18 06
; [RE] Generate integer decimal digits by repeated subtraction of the power-of-ten table at $5C34 (10000/1000/100/10/1) from the FAC mantissa $0CB1, emitting each via FOUT_DIGIT_SEP.
FOUT_DIGITS_INT:
        PUSH DE                          ; $3809  D5
        LD DE,POW10_INT_TABLE            ; $380A  11 B2 38
        LD A,$05                         ; $380D  3E 05
FOUT_DIGITS_INT_1:
        CALL FOUT_DIGIT_SEP              ; $380F  CD 64 37
        PUSH BC                          ; $3812  C5
        PUSH AF                          ; $3813  F5
        PUSH HL                          ; $3814  E5
        EX DE,HL                         ; $3815  EB
        LD C,(HL)                        ; $3816  4E
        INC HL                           ; $3817  23
        LD B,(HL)                        ; $3818  46
        PUSH BC                          ; $3819  C5
        INC HL                           ; $381A  23
        EX (SP),HL                       ; $381B  E3
        EX DE,HL                         ; $381C  EB
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $381D  2A D4 0C
        LD B,$2F                         ; $3820  06 2F
FOUT_DIGITS_INT_2:
        INC B                            ; $3822  04
FOUT_DIGITS_INT_3:
        LD A,L                           ; $3823  7D
        SUB E                            ; $3824  93
        LD L,A                           ; $3825  6F
        LD A,H                           ; $3826  7C
        SBC A,D                          ; $3827  9A
        LD H,A                           ; $3828  67
        JR NC,FOUT_DIGITS_INT_2          ; $3829  30 F7
        ADD HL,DE                        ; $382B  19
        LD (CHAIN_BREAK_FLAG_9),HL       ; $382C  22 D4 0C
        POP DE                           ; $382F  D1
        POP HL                           ; $3830  E1
        LD (HL),B                        ; $3831  70
        INC HL                           ; $3832  23
        POP AF                           ; $3833  F1
        POP BC                           ; $3834  C1
        DEC A                            ; $3835  3D
        JR NZ,FOUT_DIGITS_INT_1          ; $3836  20 D7
        CALL FOUT_DIGIT_SEP              ; $3838  CD 64 37
        LD (HL),A                        ; $383B  77
        POP DE                           ; $383C  D1
        RET                              ; $383D  C9
FOUT_DIGITS_INT_4:
        NOP                              ; $383E  00
        NOP                              ; $383F  00
        NOP                              ; $3840  00
        NOP                              ; $3841  00
        LD SP,HL                         ; $3842  F9
        LD (BC),A                        ; $3843  02
        DEC D                            ; $3844  15
        AND D                            ; $3845  A2
FOUT_DIGITS_INT_5:
        POP HL                           ; $3846  E1
        RST $38                          ; $3847  FF
        SBC A,A                          ; $3848  9F
        LD SP,$5FA9                      ; $3849  31 A9 5F
        LD H,E                           ; $384C  63
        OR D                             ; $384D  B2
FOUT_DIGITS_INT_6:
        CP $FF                           ; $384E  FE FF
        INC BC                           ; $3850  03
        CP A                             ; $3851  BF
        RET                              ; $3852  C9
        DEC DE                           ; $3853  1B
        LD C,$B6                         ; $3854  0E B6
; [RE] Double-precision 0.5 rounding-bias FP constant: DADD'd to the value before FIX in FN_LPOS ($4F86) and in the fractional-digit generator ($5B05) to round-to-nearest
FP_CONST_HALF_DBL:
        NOP                              ; $3856  00
        NOP                              ; $3857  00
        NOP                              ; $3858  00
        NOP                              ; $3859  00
; [RE] Single-precision 0.5 rounding constant loaded by FADD_LOAD_CONST/FADDT ($4B98, $5C90): added to the FAC during single-precision round-before-truncate in FOUT/FIX
FP_CONST_HALF_SNG:
        NOP                              ; $385A  00
        NOP                              ; $385B  00
        NOP                              ; $385C  00
        ADD A,B                          ; $385D  80
; [RE] FP magnitude threshold constant compared via DCOMP in the FOUT exponent path ($593C): the value above which numeric output switches to E (scientific) notation
FP_CONST_ENOTATION_THRESHOLD:
        NOP                              ; $385E  00
        NOP                              ; $385F  00
        INC B                            ; $3860  04
        CP A                             ; $3861  BF
        RET                              ; $3862  C9
FP_CONST_ENOTATION_THRESHOLD_1:
        DEC DE                           ; $3863  1B
FP_CONST_ENOTATION_THRESHOLD_2:
        LD C,$B6                         ; $3864  0E B6
; [RE] Double-precision power-of-ten (negative-exponent) table used by FOUT_DIGITS_FRAC ($5B14): each fractional decimal digit extracted by repeated subtraction of these scaled-ten constants from the FAC fraction
FP_POW10_FRAC_TABLE:
        NOP                              ; $3866  00
        ADD A,B                          ; $3867  80
        ADD A,$A4                        ; $3868  C6 A4
        LD A,(HL)                        ; $386A  7E
        ADC A,L                          ; $386B  8D
        INC BC                           ; $386C  03
        NOP                              ; $386D  00
        LD B,B                           ; $386E  40
        LD A,D                           ; $386F  7A
        DJNZ FP_CONST_ENOTATION_THRESHOLD_2+1  ; $3870  10 F3
        LD E,D                           ; $3872  5A
        NOP                              ; $3873  00
        NOP                              ; $3874  00
        AND B                            ; $3875  A0
        LD (HL),D                        ; $3876  72
        LD C,(HL)                        ; $3877  4E
        JR FP_POW10_FRAC_TABLE_2         ; $3878  18 09
FP_POW10_FRAC_TABLE_1:
        NOP                              ; $387A  00
        NOP                              ; $387B  00
        DJNZ FOUT_DIGITS_INT_3           ; $387C  10 A5
        CALL NC,$00E8                    ; $387E  D4 E8 00
        NOP                              ; $3881  00
        NOP                              ; $3882  00
FP_POW10_FRAC_TABLE_2:
        RET PE                           ; $3883  E8
        HALT                             ; $3884  76
FP_POW10_FRAC_TABLE_3:
        LD C,B                           ; $3885  48
        RLA                              ; $3886  17
        NOP                              ; $3887  00
        NOP                              ; $3888  00
        NOP                              ; $3889  00
        CALL PO,$540B                    ; $388A  E4 0B 54
        LD (BC),A                        ; $388D  02
        NOP                              ; $388E  00
        NOP                              ; $388F  00
        NOP                              ; $3890  00
        JP Z,$3B9A                       ; $3891  CA 9A 3B
        NOP                              ; $3894  00
        NOP                              ; $3895  00
        NOP                              ; $3896  00
        NOP                              ; $3897  00
        POP HL                           ; $3898  E1
        PUSH AF                          ; $3899  F5
        DEC B                            ; $389A  05
        NOP                              ; $389B  00
        NOP                              ; $389C  00
        NOP                              ; $389D  00
        ADD A,B                          ; $389E  80
        SUB (HL)                         ; $389F  96
        SBC A,B                          ; $38A0  98
        NOP                              ; $38A1  00
        NOP                              ; $38A2  00
        NOP                              ; $38A3  00
        NOP                              ; $38A4  00
        LD B,B                           ; $38A5  40
        LD B,D                           ; $38A6  42
        RRCA                             ; $38A7  0F
        NOP                              ; $38A8  00
        NOP                              ; $38A9  00
        NOP                              ; $38AA  00
        NOP                              ; $38AB  00
; [RE] Second double-precision power-of-ten constant block for fractional-digit generation (loaded as DE at $5B55 in the FOUT fraction loop), companion to the $5BE8 table
FP_POW10_FRAC_TABLE2:
        AND B                            ; $38AC  A0
        ADD A,(HL)                       ; $38AD  86
        LD BC,GFX_FN_MKD_STR_3           ; $38AE  01 10 27
        NOP                              ; $38B1  00
; [RE] Little-endian integer power-of-ten table 10000/1000/100/10/1 ($10 27 / E8 03 / 64 00 / 0A 00 / 01 00) used by FOUT_DIGITS_INT ($5B8C): each integer decimal digit produced by repeated subtraction from the FAC mantissa
POW10_INT_TABLE:
        DJNZ POW10_INT_TABLE_6           ; $38B2  10 27
        RET PE                           ; $38B4  E8
        INC BC                           ; $38B5  03
        LD H,H                           ; $38B6  64
        NOP                              ; $38B7  00
        LD A,(BC)                        ; $38B8  0A
        NOP                              ; $38B9  00
POW10_INT_TABLE_1:
        LD BC,$AF00                      ; $38BA  01 00 AF
        LD B,A                           ; $38BD  47
POW10_INT_TABLE_2:
        JP NZ,COM_ENTRY_1                ; $38BE  C2 06 01
        PUSH BC                          ; $38C1  C5
        CALL GETADR                      ; $38C2  CD E1 22
        POP BC                           ; $38C5  C1
        LD DE,CHAIN_BREAK_FLAG_20        ; $38C6  11 E5 0C
        PUSH DE                          ; $38C9  D5
        XOR A                            ; $38CA  AF
        LD (DE),A                        ; $38CB  12
        DEC B                            ; $38CC  05
        INC B                            ; $38CD  04
        LD C,$06                         ; $38CE  0E 06
        JR Z,POW10_INT_TABLE_5           ; $38D0  28 08
        LD C,$04                         ; $38D2  0E 04
POW10_INT_TABLE_3:
        ADD HL,HL                        ; $38D4  29
        ADC A,A                          ; $38D5  8F
POW10_INT_TABLE_4:
        ADD HL,HL                        ; $38D6  29
        ADC A,A                          ; $38D7  8F
        ADD HL,HL                        ; $38D8  29
        ADC A,A                          ; $38D9  8F
POW10_INT_TABLE_5:
        ADD HL,HL                        ; $38DA  29
POW10_INT_TABLE_6:
        ADC A,A                          ; $38DB  8F
        OR A                             ; $38DC  B7
        JP NZ,POW10_INT_TABLE_7          ; $38DD  C2 EB 38
        LD A,C                           ; $38E0  79
        DEC A                            ; $38E1  3D
        JP Z,POW10_INT_TABLE_7           ; $38E2  CA EB 38
        LD A,(DE)                        ; $38E5  1A
        OR A                             ; $38E6  B7
        JP Z,POW10_INT_TABLE_9           ; $38E7  CA F7 38
        XOR A                            ; $38EA  AF
POW10_INT_TABLE_7:
        ADD A,$30                        ; $38EB  C6 30
        CP $3A                           ; $38ED  FE 3A
        JP C,POW10_INT_TABLE_8           ; $38EF  DA F4 38
        ADD A,$07                        ; $38F2  C6 07
POW10_INT_TABLE_8:
        LD (DE),A                        ; $38F4  12
        INC DE                           ; $38F5  13
        LD (DE),A                        ; $38F6  12
POW10_INT_TABLE_9:
        XOR A                            ; $38F7  AF
        DEC C                            ; $38F8  0D
        JR Z,POW10_INT_TABLE_10          ; $38F9  28 08
        DEC B                            ; $38FB  05
        INC B                            ; $38FC  04
        JP Z,POW10_INT_TABLE_4           ; $38FD  CA D6 38
        JP POW10_INT_TABLE_3             ; $3900  C3 D4 38
POW10_INT_TABLE_10:
        LD (DE),A                        ; $3903  12
        POP HL                           ; $3904  E1
        RET                              ; $3905  C9
; [RE] Helper that pushes the FAC-negate routine ($4E76) as a return address then JP (HL); used to conditionally negate the FAC in the transcendental handlers.
FAC_NEGATE_VIA:
        LD HL,FP_NEG                     ; $3906  21 F4 2A
        EX (SP),HL                       ; $3909  E3
        JP (HL)                          ; $390A  E9
; [RE] ABS() handler (function token $06): absolute value (MBF).
FN_ABS:
        CALL FAC_PUSH                    ; $390B  CD 18 2B
        LD HL,FP_CONST_HALF_SNG          ; $390E  21 5A 38
        CALL FP_STORE_REGS_LD            ; $3911  CD 25 2B
        JR FN_ABS_2                      ; $3914  18 03
FN_ABS_1:
        CALL FN_CINT                     ; $3916  CD 6C 2C
FN_ABS_2:
        POP BC                           ; $3919  C1
        POP DE                           ; $391A  D1
        LD HL,GFX_CLR_REVERSE_FLAG       ; $391B  21 54 25
FN_ABS_3:
        PUSH HL                          ; $391E  E5
        LD A,$01                         ; $391F  3E 01
        LD (CHAIN_BREAK_FLAG_13),A       ; $3921  32 D9 0C
        CALL FP_SIGN                     ; $3924  CD C5 2A
        LD A,B                           ; $3927  78
        JR Z,FN_LOG                      ; $3928  28 3C
        JP P,FN_ABS_4                    ; $392A  F2 31 39
        OR A                             ; $392D  B7
        JP Z,FIN_EXP_DIGIT_16            ; $392E  CA 02 33
FN_ABS_4:
        OR A                             ; $3931  B7
        JP Z,FP_SET_ZERO_1               ; $3932  CA 88 28
        PUSH DE                          ; $3935  D5
        PUSH BC                          ; $3936  C5
        LD A,C                           ; $3937  79
        OR $7F                           ; $3938  F6 7F
        CALL FP_LOAD_FAC                 ; $393A  CD 33 2B
        JP P,FN_ABS_5                    ; $393D  F2 4E 39
        PUSH DE                          ; $3940  D5
        PUSH BC                          ; $3941  C5
        CALL FIX_SCALE                   ; $3942  CD 04 2D
        POP BC                           ; $3945  C1
        POP DE                           ; $3946  D1
        PUSH AF                          ; $3947  F5
        CALL FCOMP                       ; $3948  CD 81 2B
        POP HL                           ; $394B  E1
        LD A,H                           ; $394C  7C
        RRA                              ; $394D  1F
FN_ABS_5:
        POP HL                           ; $394E  E1
        LD (CHAIN_BREAK_FLAG_10),HL      ; $394F  22 D6 0C
        POP HL                           ; $3952  E1
        LD (CHAIN_BREAK_FLAG_9),HL       ; $3953  22 D4 0C
        CALL C,FAC_NEGATE_VIA            ; $3956  DC 06 39
        CALL Z,FP_NEG                    ; $3959  CC F4 2A
        PUSH DE                          ; $395C  D5
        PUSH BC                          ; $395D  C5
        CALL FN_SIN                      ; $395E  CD 4A 29
        POP BC                           ; $3961  C1
        POP DE                           ; $3962  D1
        CALL FMUL                        ; $3963  CD 90 29
; [RE] LOG() handler (function token $0A): natural logarithm (MBF).
FN_LOG:
        LD BC,$8138                      ; $3966  01 38 81
        LD DE,$AA3B                      ; $3969  11 3B AA
        CALL FMUL                        ; $396C  CD 90 29
        LD A,(CHAIN_BREAK_FLAG_11)       ; $396F  3A D7 0C
        CP $88                           ; $3972  FE 88
        JP NC,FN_LOG_2                   ; $3974  D2 9B 39
        CP $68                           ; $3977  FE 68
        JP C,FN_LOG_5                    ; $3979  DA AD 39
        CALL FAC_PUSH                    ; $397C  CD 18 2B
        CALL FIX_SCALE                   ; $397F  CD 04 2D
        ADD A,$81                        ; $3982  C6 81
        POP BC                           ; $3984  C1
        POP DE                           ; $3985  D1
        JP Z,FN_LOG_3                    ; $3986  CA 9E 39
        PUSH AF                          ; $3989  F5
        CALL FSUB                        ; $398A  CD 21 28
        LD HL,FN_LOG_6                   ; $398D  21 B7 39
        CALL POLY_EVAL                   ; $3990  CD E3 39
        POP BC                           ; $3993  C1
        LD DE,$0000                      ; $3994  11 00 00
        LD C,D                           ; $3997  4A
FN_LOG_1:
        JP FMUL                          ; $3998  C3 90 29
FN_LOG_2:
        CALL FAC_PUSH                    ; $399B  CD 18 2B
FN_LOG_3:
        LD A,(CHAIN_BREAK_FLAG_10)       ; $399E  3A D6 0C
        OR A                             ; $39A1  B7
        JP P,FN_LOG_4                    ; $39A2  F2 AA 39
        POP AF                           ; $39A5  F1
        POP AF                           ; $39A6  F1
        JP FP_SET_ZERO                   ; $39A7  C3 87 28
FN_LOG_4:
        JP FIN_EXP_DIGIT_7               ; $39AA  C3 CA 32
FN_LOG_5:
        LD BC,$8100                      ; $39AD  01 00 81
        LD DE,$0000                      ; $39B0  11 00 00
        CALL FP_STORE_FAC                ; $39B3  CD 28 2B
        RET                              ; $39B6  C9
FN_LOG_6:
        RLCA                             ; $39B7  07
        LD A,H                           ; $39B8  7C
        ADC A,B                          ; $39B9  88
        LD E,C                           ; $39BA  59
        LD (HL),H                        ; $39BB  74
        RET PO                           ; $39BC  E0
        SUB A                            ; $39BD  97
        LD H,$77                         ; $39BE  26 77
        CALL NZ,FRMEVL_INT_OP_XOR        ; $39C0  C4 1D 1E
        LD A,D                           ; $39C3  7A
        LD E,(HL)                        ; $39C4  5E
        LD D,B                           ; $39C5  50
        LD H,E                           ; $39C6  63
        LD A,H                           ; $39C7  7C
        LD A,(DE)                        ; $39C8  1A
        CP $75                           ; $39C9  FE 75
        LD A,(HL)                        ; $39CB  7E
        JR FN_SQR_2                      ; $39CC  18 72
        LD SP,$0080                      ; $39CE  31 80 00
        NOP                              ; $39D1  00
        NOP                              ; $39D2  00
        ADD A,C                          ; $39D3  81
; [RE] Odd-power polynomial evaluator: forms x*P(x^2) for the series approximations (SIN/ATN/TAN), squaring the argument then calling the Horner evaluator POLY_EVAL.
POLY_EVAL_ODD:
        CALL FAC_PUSH                    ; $39D4  CD 18 2B
        LD DE,IMULDIV_FINISH_3           ; $39D7  11 01 2E
        PUSH DE                          ; $39DA  D5
        PUSH HL                          ; $39DB  E5
        CALL FP_LOAD_FAC                 ; $39DC  CD 33 2B
        CALL FMUL                        ; $39DF  CD 90 29
        POP HL                           ; $39E2  E1
; [RE] MS BASIC-80 polynomial (Horner) evaluator: HL -> coefficient table (count byte then MBF coefficients); repeatedly FMUL by the argument and FADD the next coefficient. Shared by LOG/EXP/SIN/COS/TAN/ATN.
POLY_EVAL:
        CALL FAC_PUSH                    ; $39E3  CD 18 2B
        LD A,(HL)                        ; $39E6  7E
        INC HL                           ; $39E7  23
        CALL FP_STORE_REGS_LD            ; $39E8  CD 25 2B
POLY_EVAL_1:
        LD B,$F1                         ; $39EB  06 F1
        POP BC                           ; $39ED  C1
        POP DE                           ; $39EE  D1
        DEC A                            ; $39EF  3D
        RET Z                            ; $39F0  C8
        PUSH DE                          ; $39F1  D5
        PUSH BC                          ; $39F2  C5
        PUSH AF                          ; $39F3  F5
        PUSH HL                          ; $39F4  E5
        CALL FMUL                        ; $39F5  CD 90 29
        POP HL                           ; $39F8  E1
        CALL FP_LOAD_MEM                 ; $39F9  CD 36 2B
        PUSH HL                          ; $39FC  E5
        CALL FADD_ALIGN                  ; $39FD  CD 24 28
        POP HL                           ; $3A00  E1
        JR POLY_EVAL_1+1                 ; $3A01  18 E9
POLY_EVAL_2:
        LD D,D                           ; $3A03  52
        RST $00                          ; $3A04  C7
        LD C,A                           ; $3A05  4F
        ADD A,B                          ; $3A06  80
POLY_EVAL_3:
        CALL CHRGET                      ; $3A07  CD E4 13
; [RE] Evaluate a polynomial in sqrt(x): pushes the argument, runs FN_SQR, then evaluates the series via POLY_EVAL (used by the ATN/LOG support path called at $4486).
POLY_EVAL_SQR:
        PUSH HL                          ; $3A0A  E5
        LD HL,SUB_2922_1                 ; $3A0B  21 24 29
        CALL FP_STORE_REGS_LD            ; $3A0E  CD 25 2B
        CALL FN_SQR                      ; $3A11  CD 18 3A
        POP HL                           ; $3A14  E1
        JP SET_TYPE_DOUBLE_1+1           ; $3A15  C3 AE 2C
; [RE] SQR() handler (function token $07): square root (MBF math package).
FN_SQR:
        CALL FP_SIGN                     ; $3A18  CD C5 2A
        LD HL,FN_SQR_8                   ; $3A1B  21 81 3A
FN_SQR_1:
        JP M,FN_SQR_5                    ; $3A1E  FA 78 3A
        LD HL,RNDX_SEED                  ; $3A21  21 A2 3A
        CALL FP_STORE_REGS_LD            ; $3A24  CD 25 2B
        LD HL,FN_SQR_8                   ; $3A27  21 81 3A
        RET Z                            ; $3A2A  C8
        ADD A,(HL)                       ; $3A2B  86
        AND $07                          ; $3A2C  E6 07
        LD B,$00                         ; $3A2E  06 00
        LD (HL),A                        ; $3A30  77
        INC HL                           ; $3A31  23
        ADD A,A                          ; $3A32  87
        ADD A,A                          ; $3A33  87
        LD C,A                           ; $3A34  4F
        ADD HL,BC                        ; $3A35  09
        CALL FP_LOAD_MEM                 ; $3A36  CD 36 2B
        CALL FMUL                        ; $3A39  CD 90 29
        LD A,(FN_SQR_7)                  ; $3A3C  3A 80 3A
        INC A                            ; $3A3F  3C
FN_SQR_2:
        AND $03                          ; $3A40  E6 03
        LD B,$00                         ; $3A42  06 00
        CP $01                           ; $3A44  FE 01
        ADC A,B                          ; $3A46  88
        LD (FN_SQR_7),A                  ; $3A47  32 80 3A
        LD HL,RNDX_SEED                  ; $3A4A  21 A2 3A
        ADD A,A                          ; $3A4D  87
        ADD A,A                          ; $3A4E  87
        LD C,A                           ; $3A4F  4F
        ADD HL,BC                        ; $3A50  09
        CALL FADD_FROM_MEM               ; $3A51  CD 19 28
FN_SQR_3:
        CALL FP_LOAD_FAC                 ; $3A54  CD 33 2B
        LD A,E                           ; $3A57  7B
        LD E,C                           ; $3A58  59
        XOR $4F                          ; $3A59  EE 4F
        LD C,A                           ; $3A5B  4F
        LD (HL),$80                      ; $3A5C  36 80
        DEC HL                           ; $3A5E  2B
        LD B,(HL)                        ; $3A5F  46
        LD (HL),$80                      ; $3A60  36 80
        LD HL,FN_SQR_6                   ; $3A62  21 7F 3A
        INC (HL)                         ; $3A65  34
        LD A,(HL)                        ; $3A66  7E
        SUB $AB                          ; $3A67  D6 AB
        JR NZ,FN_SQR_4                   ; $3A69  20 04
        LD (HL),A                        ; $3A6B  77
        INC C                            ; $3A6C  0C
        DEC D                            ; $3A6D  15
        INC E                            ; $3A6E  1C
FN_SQR_4:
        CALL FADD                        ; $3A6F  CD 74 28
        LD HL,RNDX_SEED                  ; $3A72  21 A2 3A
        JP FP_MOVE_TO_FAC                ; $3A75  C3 3F 2B
FN_SQR_5:
        LD (HL),A                        ; $3A78  77
        DEC HL                           ; $3A79  2B
        LD (HL),A                        ; $3A7A  77
        DEC HL                           ; $3A7B  2B
        LD (HL),A                        ; $3A7C  77
        JR FN_SQR_3                      ; $3A7D  18 D5
FN_SQR_6:
        NOP                              ; $3A7F  00
FN_SQR_7:
        NOP                              ; $3A80  00
FN_SQR_8:
        NOP                              ; $3A81  00
        DEC (HL)                         ; $3A82  35
        LD C,D                           ; $3A83  4A
        JP Z,$3999                       ; $3A84  CA 99 39
        INC E                            ; $3A87  1C
        HALT                             ; $3A88  76
        DEFW    STMT_DELETE_1            ; $3A89
        DEFB    $95,$B3                  ; $3A8B
        DEFW    BUF_1                    ; $3A8D
        DEFW    NEXT_LOOP_BODY_5         ; $3A8F
        DEFW    FN_CVI_12                ; $3A91
        DEFB    $D1,$99                  ; $3A93
        DEFW    BUF_2                    ; $3A95
        DEFB    $1A,$9F,$98,$65,$BC,$CD,$98,$D6,$77,$3E,$98  ; $3A97
; [RE] RND seed (RNDX) work cell, low byte of the 4-byte running random state at $5E24-$5E27. CLEAR/RUN re-initializes it from a default constant ($68AE FP_MOVE4 from $5D85); FN_RND multiplies/updates it; also reused as FP scratch by FN_SQR ($5DA3/$5DCC/$5DF4)
RNDX_SEED:
        LD D,D                           ; $3AA2  52
; [RE] RND seed mantissa word (upper 3 bytes of the RNDX state at $5E25-$5E27): RANDOMIZE stores the new seed here via STMT_RANDOMIZE_3 ($4483 LD ($5E25),HL)
RNDX_SEED_WORD:
        RST $00                          ; $3AA3  C7
        LD C,A                           ; $3AA4  4F
        ADD A,B                          ; $3AA5  80
        LD L,B                           ; $3AA6  68
        OR C                             ; $3AA7  B1
        LD B,(HL)                        ; $3AA8  46
        LD L,B                           ; $3AA9  68
        SBC A,C                          ; $3AAA  99
        JP (HL)                          ; $3AAB  E9
RNDX_SEED_WORD_1:
        SUB D                            ; $3AAC  92
        LD L,C                           ; $3AAD  69
        DJNZ FN_SQR_8                    ; $3AAE  10 D1
        LD (HL),L                        ; $3AB0  75
        LD L,B                           ; $3AB1  68
; [RE] EXP() handler (function token $0B): exponential e^x (MBF).
FN_EXP:
        LD HL,FN_RND_4+2                 ; $3AB2  21 28 3B
        CALL FADD_FROM_MEM               ; $3AB5  CD 19 28
; [RE] RND() handler (function token $08): pseudo-random number (reads the seed at $0CB4).
FN_RND:
        LD A,(CHAIN_BREAK_FLAG_11)       ; $3AB8  3A D7 0C
        CP $77                           ; $3ABB  FE 77
        RET C                            ; $3ABD  D8
        LD BC,$7E22                      ; $3ABE  01 22 7E
        LD DE,$F983                      ; $3AC1  11 83 F9
        CALL FMUL                        ; $3AC4  CD 90 29
        CALL FAC_PUSH                    ; $3AC7  CD 18 2B
        CALL FIX_SCALE                   ; $3ACA  CD 04 2D
        POP BC                           ; $3ACD  C1
        POP DE                           ; $3ACE  D1
        CALL FSUB                        ; $3ACF  CD 21 28
        LD BC,$7F00                      ; $3AD2  01 00 7F
        LD DE,$0000                      ; $3AD5  11 00 00
        CALL FCOMP                       ; $3AD8  CD 81 2B
        JP M,FN_RND_1                    ; $3ADB  FA 02 3B
        LD BC,$7F80                      ; $3ADE  01 80 7F
        LD DE,$0000                      ; $3AE1  11 00 00
        CALL FADD_ALIGN                  ; $3AE4  CD 24 28
        LD BC,$8080                      ; $3AE7  01 80 80
        LD DE,$0000                      ; $3AEA  11 00 00
        CALL FADD_ALIGN                  ; $3AED  CD 24 28
        CALL FP_SIGN                     ; $3AF0  CD C5 2A
        CALL P,FP_NEG                    ; $3AF3  F4 F4 2A
        LD BC,$7F00                      ; $3AF6  01 00 7F
        LD DE,$0000                      ; $3AF9  11 00 00
        CALL FADD_ALIGN                  ; $3AFC  CD 24 28
        CALL FP_NEG                      ; $3AFF  CD F4 2A
FN_RND_1:
        LD A,(CHAIN_BREAK_FLAG_10)       ; $3B02  3A D6 0C
        OR A                             ; $3B05  B7
        PUSH AF                          ; $3B06  F5
        JP P,FN_RND_2                    ; $3B07  F2 0F 3B
        XOR $80                          ; $3B0A  EE 80
        LD (CHAIN_BREAK_FLAG_10),A       ; $3B0C  32 D6 0C
FN_RND_2:
        LD HL,FN_RND_5                   ; $3B0F  21 30 3B
        CALL POLY_EVAL_ODD               ; $3B12  CD D4 39
        POP AF                           ; $3B15  F1
        RET P                            ; $3B16  F0
        LD A,(CHAIN_BREAK_FLAG_10)       ; $3B17  3A D6 0C
        XOR $80                          ; $3B1A  EE 80
        LD (CHAIN_BREAK_FLAG_10),A       ; $3B1C  32 D6 0C
        RET                              ; $3B1F  C9
FN_RND_3:
        NOP                              ; $3B20  00
        NOP                              ; $3B21  00
        NOP                              ; $3B22  00
        NOP                              ; $3B23  00
        ADD A,E                          ; $3B24  83
        LD SP,HL                         ; $3B25  F9
FN_RND_4:
        LD ($DB7E),HL                    ; $3B26  22 7E DB
        RRCA                             ; $3B29  0F
        LD C,C                           ; $3B2A  49
        ADD A,C                          ; $3B2B  81
        NOP                              ; $3B2C  00
        NOP                              ; $3B2D  00
        NOP                              ; $3B2E  00
        LD A,A                           ; $3B2F  7F
FN_RND_5:
        DEC B                            ; $3B30  05
        EI                               ; $3B31  FB
        RST $10                          ; $3B32  D7
        LD E,$86                         ; $3B33  1E 86
        LD H,L                           ; $3B35  65
        LD H,$99                         ; $3B36  26 99
        ADD A,A                          ; $3B38  87
        LD E,B                           ; $3B39  58
        INC (HL)                         ; $3B3A  34
        INC HL                           ; $3B3B  23
        ADD A,A                          ; $3B3C  87
        POP HL                           ; $3B3D  E1
        LD E,L                           ; $3B3E  5D
        AND L                            ; $3B3F  A5
        ADD A,(HL)                       ; $3B40  86
        IN A,($0F)                       ; $3B41  DB 0F
        LD C,C                           ; $3B43  49
        ADD A,E                          ; $3B44  83
; [RE] COS() handler (function token $0C): cosine (MBF).
FN_COS:
        CALL FAC_PUSH                    ; $3B45  CD 18 2B
        CALL FN_RND                      ; $3B48  CD B8 3A
        POP BC                           ; $3B4B  C1
        POP HL                           ; $3B4C  E1
        CALL FAC_PUSH                    ; $3B4D  CD 18 2B
        EX DE,HL                         ; $3B50  EB
        CALL FP_STORE_FAC                ; $3B51  CD 28 2B
        CALL FN_EXP                      ; $3B54  CD B2 3A
        JP FDIV_BY_TEN_1                 ; $3B57  C3 F1 29
; [RE] TAN() handler (function token $0D): tangent (MBF; shares poly evaluator $47C5).
FN_TAN:
        CALL FP_SIGN                     ; $3B5A  CD C5 2A
        CALL M,FAC_NEGATE_VIA            ; $3B5D  FC 06 39
        CALL M,FP_NEG                    ; $3B60  FC F4 2A
        LD A,(CHAIN_BREAK_FLAG_11)       ; $3B63  3A D7 0C
        CP $81                           ; $3B66  FE 81
        JR C,FN_TAN_1                    ; $3B68  38 0C
        LD BC,$8100                      ; $3B6A  01 00 81
        LD D,C                           ; $3B6D  51
        LD E,C                           ; $3B6E  59
        CALL FDIV                        ; $3B6F  CD F3 29
        LD HL,FADD_FROM_MEM_1            ; $3B72  21 1E 28
        PUSH HL                          ; $3B75  E5
FN_TAN_1:
        LD HL,FN_TAN_2                   ; $3B76  21 80 3B
        CALL POLY_EVAL_ODD               ; $3B79  CD D4 39
        LD HL,FN_RND_4+2                 ; $3B7C  21 28 3B
        RET                              ; $3B7F  C9
FN_TAN_2:
        ADD HL,BC                        ; $3B80  09
        LD C,D                           ; $3B81  4A
        RST $10                          ; $3B82  D7
        DEC SP                           ; $3B83  3B
        LD A,B                           ; $3B84  78
        LD (BC),A                        ; $3B85  02
        LD L,(HL)                        ; $3B86  6E
        ADD A,H                          ; $3B87  84
        LD A,E                           ; $3B88  7B
        CP $C1                           ; $3B89  FE C1
        CPL                              ; $3B8B  2F
        LD A,H                           ; $3B8C  7C
        LD (HL),H                        ; $3B8D  74
        LD SP,$7D9A                      ; $3B8E  31 9A 7D
        ADD A,H                          ; $3B91  84
        DEC A                            ; $3B92  3D
        LD E,D                           ; $3B93  5A
        LD A,L                           ; $3B94  7D
        RET Z                            ; $3B95  C8
        LD A,A                           ; $3B96  7F
        SUB C                            ; $3B97  91
        LD A,(HL)                        ; $3B98  7E
FN_TAN_3:
        CALL PO,$4CBB                    ; $3B99  E4 BB 4C
        LD A,(HL)                        ; $3B9C  7E
        LD L,H                           ; $3B9D  6C
        XOR D                            ; $3B9E  AA
        XOR D                            ; $3B9F  AA
        LD A,A                           ; $3BA0  7F
        NOP                              ; $3BA1  00
        NOP                              ; $3BA2  00
        NOP                              ; $3BA3  00
        ADD A,C                          ; $3BA4  81
FN_TAN_4:
        DEC HL                           ; $3BA5  2B
        CALL CHRGET                      ; $3BA6  CD E4 13
        RET Z                            ; $3BA9  C8
        CALL SYNCHR                      ; $3BAA  CD A3 45
        INC L                            ; $3BAD  2C
; [RE] PTRGET front-end: scan a variable name at the BASIC text pointer (HL). Accumulates the leading alpha + following alphanumerics (high-bit set) into the VARNAM buffer $0871, honouring type-suffix chars %/$/!/# to set VALTYP $0B14 (and the default-type table at $0B36), then falls into the table search at PTRGET_SEARCH ($5FC9). Called by LET ($5F35) and FRMEVL operand fetch.
PTRGET:
        LD BC,FN_TAN_4                   ; $3BAE  01 A5 3B
        PUSH BC                          ; $3BB1  C5
PTRGET_1:
        OR $AF                           ; $3BB2  F6 AF
        LD (SUB_0B2A_4),A                ; $3BB4  32 36 0B
        LD C,(HL)                        ; $3BB7  4E
PTRGET_2:
        CALL IS_LETTER                   ; $3BB8  CD BE 46
        JP C,RAISE_SYNTAX_ERROR          ; $3BBB  DA 92 0D
        XOR A                            ; $3BBE  AF
        LD B,A                           ; $3BBF  47
        LD (FILTAB_5),A                  ; $3BC0  32 94 08
        INC HL                           ; $3BC3  23
        LD A,(HL)                        ; $3BC4  7E
        CP $2E                           ; $3BC5  FE 2E
        JR C,PTRGET_7                    ; $3BC7  38 39
        JR Z,PTRGET_4                    ; $3BC9  28 0D
        CP $3A                           ; $3BCB  FE 3A
        JR NC,PTRGET_3                   ; $3BCD  30 04
        CP $30                           ; $3BCF  FE 30
        JR NC,PTRGET_4                   ; $3BD1  30 05
PTRGET_3:
        CALL IS_LETTER_A                 ; $3BD3  CD BF 46
        JR C,PTRGET_7                    ; $3BD6  38 2A
PTRGET_4:
        LD B,A                           ; $3BD8  47
        PUSH BC                          ; $3BD9  C5
        LD B,$FF                         ; $3BDA  06 FF
        LD DE,FILTAB_5                   ; $3BDC  11 94 08
PTRGET_5:
        OR $80                           ; $3BDF  F6 80
        INC B                            ; $3BE1  04
        LD (DE),A                        ; $3BE2  12
        INC DE                           ; $3BE3  13
        INC HL                           ; $3BE4  23
        LD A,(HL)                        ; $3BE5  7E
        CP $3A                           ; $3BE6  FE 3A
        JR NC,PTRGET_6                   ; $3BE8  30 04
        CP $30                           ; $3BEA  FE 30
        JR NC,PTRGET_5                   ; $3BEC  30 F1
PTRGET_6:
        CALL IS_LETTER_A                 ; $3BEE  CD BF 46
        JR NC,PTRGET_5                   ; $3BF1  30 EC
        CP $2E                           ; $3BF3  FE 2E
        JR Z,PTRGET_5                    ; $3BF5  28 E8
        LD A,B                           ; $3BF7  78
        CP $27                           ; $3BF8  FE 27
        JP NC,RAISE_SYNTAX_ERROR         ; $3BFA  D2 92 0D
        POP BC                           ; $3BFD  C1
        LD (FILTAB_5),A                  ; $3BFE  32 94 08
        LD A,(HL)                        ; $3C01  7E
PTRGET_7:
        CP $26                           ; $3C02  FE 26
        JR NC,PTRGET_8                   ; $3C04  30 17
        LD DE,PTRGET_9                   ; $3C06  11 2B 3C
        PUSH DE                          ; $3C09  D5
        LD D,$02                         ; $3C0A  16 02
        CP $25                           ; $3C0C  FE 25
        RET Z                            ; $3C0E  C8
        INC D                            ; $3C0F  14
        CP $24                           ; $3C10  FE 24
        RET Z                            ; $3C12  C8
        INC D                            ; $3C13  14
        CP $21                           ; $3C14  FE 21
        RET Z                            ; $3C16  C8
        LD D,$08                         ; $3C17  16 08
        CP $23                           ; $3C19  FE 23
        RET Z                            ; $3C1B  C8
        POP AF                           ; $3C1C  F1
PTRGET_8:
        LD A,C                           ; $3C1D  79
        AND $7F                          ; $3C1E  E6 7F
        LD E,A                           ; $3C20  5F
        LD D,$00                         ; $3C21  16 00
        PUSH HL                          ; $3C23  E5
        LD HL,MEMSIZ_3                   ; $3C24  21 59 0B
        ADD HL,DE                        ; $3C27  19
        LD D,(HL)                        ; $3C28  56
        POP HL                           ; $3C29  E1
        DEC HL                           ; $3C2A  2B
PTRGET_9:
        LD A,D                           ; $3C2B  7A
        LD (SUB_0B2A_5),A                ; $3C2C  32 37 0B
        CALL CHRGET                      ; $3C2F  CD E4 13
        LD A,(DATA_LINE_TXTPTR_1)        ; $3C32  3A 75 0B
        DEC A                            ; $3C35  3D
        JP Z,SUB_3D4E_6+1                ; $3C36  CA AB 3D
        JP P,PTRGET_SEARCH               ; $3C39  F2 47 3C
        LD A,(HL)                        ; $3C3C  7E
        SUB $28                          ; $3C3D  D6 28
        JP Z,SUB_3D15_5                  ; $3C3F  CA 35 3D
        SUB $33                          ; $3C42  D6 33
        JP Z,SUB_3D15_5                  ; $3C44  CA 35 3D
; [RE] PTRGET search/allocate core: walk the simple-variable table ($0B6F..$0B71) for the packed name in C/$0B14/$0871; on a hit return its address, on a miss create a new entry (allocate via STR/var-space grow, SUB_6811/SUB_622E). Detects '(' to branch to the array path (subscript eval + array search/alloc, $612C loop) honouring DIM and OPTION BASE.
PTRGET_SEARCH:
        XOR A                            ; $3C47  AF
        LD (DATA_LINE_TXTPTR_1),A        ; $3C48  32 75 0B
        PUSH HL                          ; $3C4B  E5
        LD A,(SUB_0C4B_4)                ; $3C4C  3A 87 0C
        OR A                             ; $3C4F  B7
        LD (SUB_0C4B_1),A                ; $3C50  32 84 0C
        JR Z,PTRGET_SEARCH_6             ; $3C53  28 40
        LD HL,(VARTAB_6)                 ; $3C55  2A B6 0B
        LD DE,VARTAB_7                   ; $3C58  11 B8 0B
        ADD HL,DE                        ; $3C5B  19
        LD (SUB_0C4B_2),HL               ; $3C5C  22 85 0C
        EX DE,HL                         ; $3C5F  EB
        JR PTRGET_SEARCH_5               ; $3C60  18 1B
PTRGET_SEARCH_1:
        LD A,(DE)                        ; $3C62  1A
        LD L,A                           ; $3C63  6F
        INC DE                           ; $3C64  13
        LD A,(DE)                        ; $3C65  1A
        INC DE                           ; $3C66  13
        CP C                             ; $3C67  B9
        JR NZ,PTRGET_SEARCH_2            ; $3C68  20 0B
        LD A,(SUB_0B2A_5)                ; $3C6A  3A 37 0B
        CP L                             ; $3C6D  BD
        JR NZ,PTRGET_SEARCH_2            ; $3C6E  20 05
        LD A,(DE)                        ; $3C70  1A
        CP B                             ; $3C71  B8
        JP Z,PTRGET_SEARCH_10            ; $3C72  CA 06 3D
PTRGET_SEARCH_2:
        INC DE                           ; $3C75  13
PTRGET_SEARCH_3:
        LD A,(DE)                        ; $3C76  1A
PTRGET_SEARCH_4:
        LD H,$00                         ; $3C77  26 00
        ADD A,L                          ; $3C79  85
        INC A                            ; $3C7A  3C
        LD L,A                           ; $3C7B  6F
        ADD HL,DE                        ; $3C7C  19
PTRGET_SEARCH_5:
        EX DE,HL                         ; $3C7D  EB
        LD A,(SUB_0C4B_2)                ; $3C7E  3A 85 0C
        CP E                             ; $3C81  BB
        JP NZ,PTRGET_SEARCH_1            ; $3C82  C2 62 3C
        LD A,(SUB_0C4B_3)                ; $3C85  3A 86 0C
        CP D                             ; $3C88  BA
        JR NZ,PTRGET_SEARCH_1            ; $3C89  20 D7
        LD A,(SUB_0C4B_1)                ; $3C8B  3A 84 0C
        OR A                             ; $3C8E  B7
        JR Z,PTRGET_SEARCH_8             ; $3C8F  28 14
        XOR A                            ; $3C91  AF
        LD (SUB_0C4B_1),A                ; $3C92  32 84 0C
PTRGET_SEARCH_6:
        LD HL,(VARTAB_1)                 ; $3C95  2A 94 0B
        LD (SUB_0C4B_2),HL               ; $3C98  22 85 0C
        LD HL,(VARTAB)                   ; $3C9B  2A 92 0B
        JR PTRGET_SEARCH_5               ; $3C9E  18 DD
PTRGET_SEARCH_7:
        LD D,A                           ; $3CA0  57
        LD E,A                           ; $3CA1  5F
        POP BC                           ; $3CA2  C1
        EX (SP),HL                       ; $3CA3  E3
        RET                              ; $3CA4  C9
PTRGET_SEARCH_8:
        POP HL                           ; $3CA5  E1
        EX (SP),HL                       ; $3CA6  E3
        PUSH DE                          ; $3CA7  D5
        LD DE,FRMEVL_EVAL_OPERAND_6      ; $3CA8  11 7F 1C
        CALL CMP_HL_DE                   ; $3CAB  CD 9D 45
        JR Z,PTRGET_SEARCH_7             ; $3CAE  28 F0
        LD DE,SUB_5012_3                 ; $3CB0  11 23 50
        CALL CMP_HL_DE                   ; $3CB3  CD 9D 45
        JP Z,PTRGET_SEARCH_7             ; $3CB6  CA A0 3C
        LD DE,SUB_5012_4                 ; $3CB9  11 32 50
        CALL CMP_HL_DE                   ; $3CBC  CD 9D 45
        JR Z,PTRGET_SEARCH_7             ; $3CBF  28 DF
        LD DE,FRMEVL_PAREN_4             ; $3CC1  11 DA 1C
        CALL CMP_HL_DE                   ; $3CC4  CD 9D 45
        POP DE                           ; $3CC7  D1
        JR Z,SUB_3D15_2                  ; $3CC8  28 56
        EX (SP),HL                       ; $3CCA  E3
        PUSH HL                          ; $3CCB  E5
        PUSH BC                          ; $3CCC  C5
        LD A,(SUB_0B2A_5)                ; $3CCD  3A 37 0B
        LD B,A                           ; $3CD0  47
        LD A,(FILTAB_5)                  ; $3CD1  3A 94 08
        ADD A,B                          ; $3CD4  80
        INC A                            ; $3CD5  3C
        LD C,A                           ; $3CD6  4F
        PUSH BC                          ; $3CD7  C5
        LD B,$00                         ; $3CD8  06 00
        INC BC                           ; $3CDA  03
        INC BC                           ; $3CDB  03
        INC BC                           ; $3CDC  03
        LD HL,(VARTAB_2)                 ; $3CDD  2A 96 0B
        PUSH HL                          ; $3CE0  E5
        ADD HL,BC                        ; $3CE1  09
        POP BC                           ; $3CE2  C1
        PUSH HL                          ; $3CE3  E5
        CALL STR_COPY_DOWN               ; $3CE4  CD 8F 44
        POP HL                           ; $3CE7  E1
        LD (VARTAB_2),HL                 ; $3CE8  22 96 0B
        LD H,B                           ; $3CEB  60
        LD L,C                           ; $3CEC  69
        LD (VARTAB_1),HL                 ; $3CED  22 94 0B
PTRGET_SEARCH_9:
        DEC HL                           ; $3CF0  2B
        LD (HL),$00                      ; $3CF1  36 00
        CALL CMP_HL_DE                   ; $3CF3  CD 9D 45
        JR NZ,PTRGET_SEARCH_9            ; $3CF6  20 F8
        POP DE                           ; $3CF8  D1
        LD (HL),D                        ; $3CF9  72
        INC HL                           ; $3CFA  23
        POP DE                           ; $3CFB  D1
        LD (HL),E                        ; $3CFC  73
        INC HL                           ; $3CFD  23
        LD (HL),D                        ; $3CFE  72
        CALL VARNAM_STORE                ; $3CFF  CD AC 3E
        EX DE,HL                         ; $3D02  EB
        INC DE                           ; $3D03  13
        POP HL                           ; $3D04  E1
        RET                              ; $3D05  C9
PTRGET_SEARCH_10:
        INC DE                           ; $3D06  13
        LD A,(FILTAB_5)                  ; $3D07  3A 94 08
        LD H,A                           ; $3D0A  67
        LD A,(DE)                        ; $3D0B  1A
        CP H                             ; $3D0C  BC
        JP NZ,PTRGET_SEARCH_3            ; $3D0D  C2 76 3C
        OR A                             ; $3D10  B7
        JR NZ,SUB_3D15_1                 ; $3D11  20 03
        INC DE                           ; $3D13  13
        POP HL                           ; $3D14  E1
        RET                              ; $3D15  C9
SUB_3D15_1:
        EX DE,HL                         ; $3D16  EB
        CALL VARNAM_COMPARE              ; $3D17  CD C0 3E
        EX DE,HL                         ; $3D1A  EB
        JP NZ,PTRGET_SEARCH_4            ; $3D1B  C2 77 3C
        POP HL                           ; $3D1E  E1
        RET                              ; $3D1F  C9
SUB_3D15_2:
        LD (CHAIN_BREAK_FLAG_11),A       ; $3D20  32 D7 0C
        LD H,A                           ; $3D23  67
        LD L,A                           ; $3D24  6F
SUB_3D15_3:
        LD (CHAIN_BREAK_FLAG_9),HL       ; $3D25  22 D4 0C
        CALL FRMEVL_TEST_TYPE            ; $3D28  CD E3 1D
        JR NZ,SUB_3D15_4                 ; $3D2B  20 06
        LD HL,SUB_0D04_5+1               ; $3D2D  21 14 0D
        LD (CHAIN_BREAK_FLAG_9),HL       ; $3D30  22 D4 0C
SUB_3D15_4:
        POP HL                           ; $3D33  E1
        RET                              ; $3D34  C9
SUB_3D15_5:
        PUSH HL                          ; $3D35  E5
        LD HL,(SUB_0B2A_4)               ; $3D36  2A 36 0B
        EX (SP),HL                       ; $3D39  E3
        LD D,A                           ; $3D3A  57
SUB_3D15_6:
        PUSH DE                          ; $3D3B  D5
        PUSH BC                          ; $3D3C  C5
        LD DE,FILTAB_5                   ; $3D3D  11 94 08
        LD A,(DE)                        ; $3D40  1A
        OR A                             ; $3D41  B7
        JR Z,SUB_3D4E_2                  ; $3D42  28 2F
        EX DE,HL                         ; $3D44  EB
        ADD A,$02                        ; $3D45  C6 02
        RRA                              ; $3D47  1F
        LD C,A                           ; $3D48  4F
        CALL CHECK_STACK_ROOM            ; $3D49  CD 9F 44
        LD A,C                           ; $3D4C  79
SUB_3D15_7:
        LD C,(HL)                        ; $3D4D  4E
        INC HL                           ; $3D4E  23
        LD B,(HL)                        ; $3D4F  46
        INC HL                           ; $3D50  23
        PUSH BC                          ; $3D51  C5
        DEC A                            ; $3D52  3D
        JR NZ,SUB_3D15_7                 ; $3D53  20 F8
        PUSH HL                          ; $3D55  E5
        LD A,(FILTAB_5)                  ; $3D56  3A 94 08
        PUSH AF                          ; $3D59  F5
        EX DE,HL                         ; $3D5A  EB
        CALL GETINT_CHRGET_POS           ; $3D5B  CD E4 14
        POP AF                           ; $3D5E  F1
        LD (FILTAB_9),HL                 ; $3D5F  22 BB 08
        POP HL                           ; $3D62  E1
        ADD A,$02                        ; $3D63  C6 02
        RRA                              ; $3D65  1F
SUB_3D4E_1:
        POP BC                           ; $3D66  C1
        DEC HL                           ; $3D67  2B
        LD (HL),B                        ; $3D68  70
        DEC HL                           ; $3D69  2B
        LD (HL),C                        ; $3D6A  71
        DEC A                            ; $3D6B  3D
        JR NZ,SUB_3D4E_1                 ; $3D6C  20 F8
        LD HL,(FILTAB_9)                 ; $3D6E  2A BB 08
        JR SUB_3D4E_3                    ; $3D71  18 07
SUB_3D4E_2:
        CALL GETINT_CHRGET_POS           ; $3D73  CD E4 14
        XOR A                            ; $3D76  AF
        LD (FILTAB_5),A                  ; $3D77  32 94 08
SUB_3D4E_3:
        LD A,(SUB_0C4B_12)               ; $3D7A  3A 96 0C
        OR A                             ; $3D7D  B7
        JR Z,SUB_3D4E_4                  ; $3D7E  28 06
        LD A,D                           ; $3D80  7A
        OR E                             ; $3D81  B3
        DEC DE                           ; $3D82  1B
        JP Z,SUB_3D4E_11                 ; $3D83  CA EA 3D
SUB_3D4E_4:
        POP BC                           ; $3D86  C1
        POP AF                           ; $3D87  F1
        EX DE,HL                         ; $3D88  EB
        EX (SP),HL                       ; $3D89  E3
        PUSH HL                          ; $3D8A  E5
        EX DE,HL                         ; $3D8B  EB
        INC A                            ; $3D8C  3C
        LD D,A                           ; $3D8D  57
        LD A,(HL)                        ; $3D8E  7E
        CP $2C                           ; $3D8F  FE 2C
        JP Z,SUB_3D15_6                  ; $3D91  CA 3B 3D
        CP $29                           ; $3D94  FE 29
        JR Z,SUB_3D4E_5                  ; $3D96  28 05
        CP $5D                           ; $3D98  FE 5D
        JP NZ,RAISE_SYNTAX_ERROR         ; $3D9A  C2 92 0D
SUB_3D4E_5:
        CALL CHRGET                      ; $3D9D  CD E4 13
        LD (FRMEVL_TXTPTR_TEMP),HL       ; $3DA0  22 8C 0B
        POP HL                           ; $3DA3  E1
        LD (SUB_0B2A_4),HL               ; $3DA4  22 36 0B
        LD E,$00                         ; $3DA7  1E 00
        PUSH DE                          ; $3DA9  D5
SUB_3D4E_6:
        LD DE,$F5E5                      ; $3DAA  11 E5 F5
        LD HL,(VARTAB_1)                 ; $3DAD  2A 94 0B
SUB_3D4E_7:
        LD A,$19                         ; $3DB0  3E 19
        EX DE,HL                         ; $3DB2  EB
        LD HL,(VARTAB_2)                 ; $3DB3  2A 96 0B
        EX DE,HL                         ; $3DB6  EB
        CALL CMP_HL_DE                   ; $3DB7  CD 9D 45
        JR Z,SUB_3D4E_13                 ; $3DBA  28 45
        LD E,(HL)                        ; $3DBC  5E
        INC HL                           ; $3DBD  23
        LD A,(HL)                        ; $3DBE  7E
        INC HL                           ; $3DBF  23
        CP C                             ; $3DC0  B9
        JR NZ,SUB_3D4E_8                 ; $3DC1  20 0A
        LD A,(SUB_0B2A_5)                ; $3DC3  3A 37 0B
        CP E                             ; $3DC6  BB
        JR NZ,SUB_3D4E_8                 ; $3DC7  20 04
        LD A,(HL)                        ; $3DC9  7E
        CP B                             ; $3DCA  B8
        JR Z,SUB_3D4E_12                 ; $3DCB  28 23
SUB_3D4E_8:
        INC HL                           ; $3DCD  23
SUB_3D4E_9:
        LD E,(HL)                        ; $3DCE  5E
        INC E                            ; $3DCF  1C
        LD D,$00                         ; $3DD0  16 00
        ADD HL,DE                        ; $3DD2  19
SUB_3D4E_10:
        LD E,(HL)                        ; $3DD3  5E
        INC HL                           ; $3DD4  23
        LD D,(HL)                        ; $3DD5  56
        INC HL                           ; $3DD6  23
        JR NZ,SUB_3D4E_7+1               ; $3DD7  20 D8
        LD A,(SUB_0B2A_4)                ; $3DD9  3A 36 0B
        OR A                             ; $3DDC  B7
        JP NZ,RAISE_DUPLICATE_DEFINITION ; $3DDD  C2 9B 0D
        POP AF                           ; $3DE0  F1
        LD B,H                           ; $3DE1  44
        LD C,L                           ; $3DE2  4D
        JP Z,FMUL_7                      ; $3DE3  CA E1 29
        SUB (HL)                         ; $3DE6  96
        JP Z,SUB_3D4E_20                 ; $3DE7  CA 69 3E
SUB_3D4E_11:
        LD DE,ERR_SUBSCRIPT_OUT_OF_RANGE ; $3DEA  11 09 00
        JP RAISE_ERROR                   ; $3DED  C3 AC 0D
SUB_3D4E_12:
        INC HL                           ; $3DF0  23
        LD A,(FILTAB_5)                  ; $3DF1  3A 94 08
        CP (HL)                          ; $3DF4  BE
        JR NZ,SUB_3D4E_9                 ; $3DF5  20 D7
        INC HL                           ; $3DF7  23
        OR A                             ; $3DF8  B7
        JR Z,SUB_3D4E_10                 ; $3DF9  28 D8
        DEC HL                           ; $3DFB  2B
        CALL VARNAM_COMPARE              ; $3DFC  CD C0 3E
        JR SUB_3D4E_10                   ; $3DFF  18 D2
SUB_3D4E_13:
        LD A,(SUB_0B2A_5)                ; $3E01  3A 37 0B
        LD (HL),A                        ; $3E04  77
        INC HL                           ; $3E05  23
        LD E,A                           ; $3E06  5F
        LD D,$00                         ; $3E07  16 00
        POP AF                           ; $3E09  F1
        JP Z,SUB_3D4E_25                 ; $3E0A  CA 9F 3E
        LD (HL),C                        ; $3E0D  71
        INC HL                           ; $3E0E  23
        LD (HL),B                        ; $3E0F  70
        CALL VARNAM_STORE                ; $3E10  CD AC 3E
        INC HL                           ; $3E13  23
        LD C,A                           ; $3E14  4F
        CALL CHECK_STACK_ROOM            ; $3E15  CD 9F 44
        INC HL                           ; $3E18  23
        INC HL                           ; $3E19  23
        LD (FRETOP_1),HL                 ; $3E1A  22 6D 0B
        LD (HL),C                        ; $3E1D  71
SUB_3D4E_14:
        INC HL                           ; $3E1E  23
        LD A,(SUB_0B2A_4)                ; $3E1F  3A 36 0B
        RLA                              ; $3E22  17
        LD A,C                           ; $3E23  79
SUB_3D4E_15:
        JR C,SUB_3D4E_16                 ; $3E24  38 0C
        PUSH AF                          ; $3E26  F5
        LD A,(SUB_0C4B_12)               ; $3E27  3A 96 0C
        XOR $0B                          ; $3E2A  EE 0B
        LD C,A                           ; $3E2C  4F
        LD B,$00                         ; $3E2D  06 00
        POP AF                           ; $3E2F  F1
        JR NC,SUB_3D4E_17                ; $3E30  30 02
SUB_3D4E_16:
        POP BC                           ; $3E32  C1
        INC BC                           ; $3E33  03
SUB_3D4E_17:
        LD (HL),C                        ; $3E34  71
        PUSH AF                          ; $3E35  F5
        INC HL                           ; $3E36  23
        LD (HL),B                        ; $3E37  70
        INC HL                           ; $3E38  23
        CALL ARRAY_INDEX_MUL16           ; $3E39  CD 79 2D
        POP AF                           ; $3E3C  F1
        DEC A                            ; $3E3D  3D
        JR NZ,SUB_3D4E_15                ; $3E3E  20 E4
        PUSH AF                          ; $3E40  F5
        LD B,D                           ; $3E41  42
        LD C,E                           ; $3E42  4B
        EX DE,HL                         ; $3E43  EB
        ADD HL,DE                        ; $3E44  19
SUB_3D4E_18:
        JP C,CHECK_STACK_ROOM_1          ; $3E45  DA B4 44
        CALL GC_CHECK_AND_COLLECT        ; $3E48  CD C2 44
        LD (VARTAB_2),HL                 ; $3E4B  22 96 0B
SUB_3D4E_19:
        DEC HL                           ; $3E4E  2B
        LD (HL),$00                      ; $3E4F  36 00
        CALL CMP_HL_DE                   ; $3E51  CD 9D 45
        JR NZ,SUB_3D4E_19                ; $3E54  20 F8
        INC BC                           ; $3E56  03
        LD D,A                           ; $3E57  57
        LD HL,(FRETOP_1)                 ; $3E58  2A 6D 0B
        LD E,(HL)                        ; $3E5B  5E
        EX DE,HL                         ; $3E5C  EB
        ADD HL,HL                        ; $3E5D  29
        ADD HL,BC                        ; $3E5E  09
        EX DE,HL                         ; $3E5F  EB
        DEC HL                           ; $3E60  2B
        DEC HL                           ; $3E61  2B
        LD (HL),E                        ; $3E62  73
        INC HL                           ; $3E63  23
        LD (HL),D                        ; $3E64  72
        INC HL                           ; $3E65  23
        POP AF                           ; $3E66  F1
        JR C,SUB_3D4E_24                 ; $3E67  38 32
SUB_3D4E_20:
        LD B,A                           ; $3E69  47
        LD C,A                           ; $3E6A  4F
        LD A,(HL)                        ; $3E6B  7E
        INC HL                           ; $3E6C  23
SUB_3D4E_21:
        LD D,$E1                         ; $3E6D  16 E1
        LD E,(HL)                        ; $3E6F  5E
        INC HL                           ; $3E70  23
        LD D,(HL)                        ; $3E71  56
        INC HL                           ; $3E72  23
        EX (SP),HL                       ; $3E73  E3
        PUSH AF                          ; $3E74  F5
        CALL CMP_HL_DE                   ; $3E75  CD 9D 45
        JP NC,SUB_3D4E_11                ; $3E78  D2 EA 3D
        CALL ARRAY_INDEX_MUL16           ; $3E7B  CD 79 2D
        ADD HL,DE                        ; $3E7E  19
        POP AF                           ; $3E7F  F1
        DEC A                            ; $3E80  3D
        LD B,H                           ; $3E81  44
        LD C,L                           ; $3E82  4D
        JR NZ,SUB_3D4E_21+1              ; $3E83  20 E9
        LD A,(SUB_0B2A_5)                ; $3E85  3A 37 0B
        LD B,H                           ; $3E88  44
        LD C,L                           ; $3E89  4D
        ADD HL,HL                        ; $3E8A  29
        SUB $04                          ; $3E8B  D6 04
        JR C,SUB_3D4E_22                 ; $3E8D  38 04
        ADD HL,HL                        ; $3E8F  29
        JR Z,SUB_3D4E_23                 ; $3E90  28 06
        ADD HL,HL                        ; $3E92  29
SUB_3D4E_22:
        OR A                             ; $3E93  B7
        JP PO,SUB_3D4E_23                ; $3E94  E2 98 3E
        ADD HL,BC                        ; $3E97  09
SUB_3D4E_23:
        POP BC                           ; $3E98  C1
        ADD HL,BC                        ; $3E99  09
        EX DE,HL                         ; $3E9A  EB
SUB_3D4E_24:
        LD HL,(FRMEVL_TXTPTR_TEMP)       ; $3E9B  2A 8C 0B
        RET                              ; $3E9E  C9
SUB_3D4E_25:
        SCF                              ; $3E9F  37
        SBC A,A                          ; $3EA0  9F
        POP HL                           ; $3EA1  E1
        RET                              ; $3EA2  C9
; [RE] Advance HL past one variable/array-table entry: load length byte at (HL), then add it to HL (falls into VARTAB_ADD_LEN). Used while scanning the array table during PTRGET and by the array-walk in DIM/index code ($6CBF, $740E...).
VARTAB_SKIP_ENTRY:
        LD A,(HL)                        ; $3EA3  7E
        INC HL                           ; $3EA4  23
; [RE] HL += A (zero-extended) preserving BC: B:=0, C:=A, ADD HL,BC. Entry point used to step over a table entry whose length is already in A.
VARTAB_ADD_LEN:
        PUSH BC                          ; $3EA5  C5
        LD B,$00                         ; $3EA6  06 00
        LD C,A                           ; $3EA8  4F
        ADD HL,BC                        ; $3EA9  09
        POP BC                           ; $3EAA  C1
        RET                              ; $3EAB  C9
; [RE] Copy the scanned variable name from the VARNAM buffer $0871 (length-prefixed) into the new variable-table entry at (HL), advancing HL. Used by PTRGET_SEARCH when creating a fresh entry.
VARNAM_STORE:
        PUSH BC                          ; $3EAC  C5
        PUSH DE                          ; $3EAD  D5
        PUSH AF                          ; $3EAE  F5
        LD DE,FILTAB_5                   ; $3EAF  11 94 08
        LD A,(DE)                        ; $3EB2  1A
        LD B,A                           ; $3EB3  47
        INC B                            ; $3EB4  04
VARNAM_STORE_1:
        LD A,(DE)                        ; $3EB5  1A
        INC DE                           ; $3EB6  13
        INC HL                           ; $3EB7  23
        LD (HL),A                        ; $3EB8  77
        DEC B                            ; $3EB9  05
        JR NZ,VARNAM_STORE_1             ; $3EBA  20 F9
        POP AF                           ; $3EBC  F1
        POP DE                           ; $3EBD  D1
        POP BC                           ; $3EBE  C1
        RET                              ; $3EBF  C9
; [RE] Compare the variable name held at (HL) in a table entry against the scanned name in buffer $0872, length A. Returns Z on full match; on mismatch advances HL past the rest of the name (via VARTAB_ADD_LEN) and returns NZ. Drives the linear scan in PTRGET_SEARCH.
VARNAM_COMPARE:
        PUSH DE                          ; $3EC0  D5
        PUSH BC                          ; $3EC1  C5
        LD DE,FILTAB_6                   ; $3EC2  11 95 08
        LD B,A                           ; $3EC5  47
        INC HL                           ; $3EC6  23
        INC B                            ; $3EC7  04
VARNAM_COMPARE_1:
        DEC B                            ; $3EC8  05
        JR Z,VARNAM_COMPARE_2            ; $3EC9  28 0D
        LD A,(DE)                        ; $3ECB  1A
        CP (HL)                          ; $3ECC  BE
        INC HL                           ; $3ECD  23
        INC DE                           ; $3ECE  13
        JR Z,VARNAM_COMPARE_1            ; $3ECF  28 F7
        LD A,B                           ; $3ED1  78
        DEC A                            ; $3ED2  3D
        CALL NZ,VARTAB_ADD_LEN           ; $3ED3  C4 A5 3E
        XOR A                            ; $3ED6  AF
        DEC A                            ; $3ED7  3D
VARNAM_COMPARE_2:
        POP BC                           ; $3ED8  C1
        POP DE                           ; $3ED9  D1
        RET                              ; $3EDA  C9
; [RE] EDIT-statement line-number resolver: store the LIST/edit flag at $0835, fetch the current/target line pointer from $0B60, and fall into the EDIT statement handler (STMT_EDIT) to enter the line editor.
STMT_EDIT_LINENUM:
        LD (SUB_0752_31+2),A             ; $3EDB  32 58 08
        LD HL,(ERR_SAVTXT)               ; $3EDE  2A 83 0B
        OR H                             ; $3EE1  B4
        AND L                            ; $3EE2  A5
        INC A                            ; $3EE3  3C
        EX DE,HL                         ; $3EE4  EB
        RET Z                            ; $3EE5  C8
        JR STMT_EDIT_1                   ; $3EE6  18 04
; [RE] EDIT statement handler (token $A3): enter the line editor for a program line.
STMT_EDIT:
        CALL LINGET_DOT                  ; $3EE8  CD F0 14
        RET NZ                           ; $3EEB  C0
STMT_EDIT_1:
        POP HL                           ; $3EEC  E1
STMT_EDIT_2:
        EX DE,HL                         ; $3EED  EB
        LD (ERRLIN),HL                   ; $3EEE  22 85 0B
        EX DE,HL                         ; $3EF1  EB
        CALL FNDLIN                      ; $3EF2  CD AB 0F
        JP NC,STMT_GOTO_2                ; $3EF5  D2 91 15
        LD H,B                           ; $3EF8  60
        LD L,C                           ; $3EF9  69
        INC HL                           ; $3EFA  23
        INC HL                           ; $3EFB  23
        LD C,(HL)                        ; $3EFC  4E
        INC HL                           ; $3EFD  23
        LD B,(HL)                        ; $3EFE  46
        INC HL                           ; $3EFF  23
        PUSH BC                          ; $3F00  C5
        CALL DETOKENIZE_LINE             ; $3F01  CD 24 21
STMT_EDIT_3:
        POP HL                           ; $3F04  E1
STMT_EDIT_4:
        PUSH HL                          ; $3F05  E5
        LD A,H                           ; $3F06  7C
        AND L                            ; $3F07  A5
        INC A                            ; $3F08  3C
        LD A,$21                         ; $3F09  3E 21
        CALL Z,OUTCHR                    ; $3F0B  CC 91 42
        CALL NZ,FOUT                     ; $3F0E  C4 91 33
        LD A,$20                         ; $3F11  3E 20
        CALL OUTCHR                      ; $3F13  CD 91 42
        LD HL,BUF                        ; $3F16  21 31 0A
        PUSH HL                          ; $3F19  E5
        LD C,$FF                         ; $3F1A  0E FF
STMT_EDIT_5:
        INC C                            ; $3F1C  0C
        LD A,(HL)                        ; $3F1D  7E
STMT_EDIT_6:
        INC HL                           ; $3F1E  23
        OR A                             ; $3F1F  B7
        JR NZ,STMT_EDIT_5                ; $3F20  20 FA
        POP HL                           ; $3F22  E1
        LD B,A                           ; $3F23  47
STMT_EDIT_7:
        LD D,$00                         ; $3F24  16 00
STMT_EDIT_8:
        CALL CONIN                       ; $3F26  CD DA 43
        OR A                             ; $3F29  B7
        JR Z,STMT_EDIT_8                 ; $3F2A  28 FA
        CALL TOUPPER_A                   ; $3F2C  CD E8 1C
        SUB $30                          ; $3F2F  D6 30
        JR C,STMT_EDIT_9                 ; $3F31  38 0E
        CP $0A                           ; $3F33  FE 0A
        JR NC,STMT_EDIT_9                ; $3F35  30 0A
        LD E,A                           ; $3F37  5F
        LD A,D                           ; $3F38  7A
        RLCA                             ; $3F39  07
        RLCA                             ; $3F3A  07
        ADD A,D                          ; $3F3B  82
        RLCA                             ; $3F3C  07
        ADD A,E                          ; $3F3D  83
        LD D,A                           ; $3F3E  57
        JR STMT_EDIT_8                   ; $3F3F  18 E5
STMT_EDIT_9:
        PUSH HL                          ; $3F41  E5
        LD HL,STMT_EDIT_7                ; $3F42  21 24 3F
        EX (SP),HL                       ; $3F45  E3
        DEC D                            ; $3F46  15
        INC D                            ; $3F47  14
        JP NZ,STMT_EDIT_10               ; $3F48  C2 4C 3F
        INC D                            ; $3F4B  14
STMT_EDIT_10:
        CP $D8                           ; $3F4C  FE D8
        JP Z,EDIT_BUF_SHIFT_6            ; $3F4E  CA 9E 40
        CP $4F                           ; $3F51  FE 4F
        JP Z,EDIT_BUF_SHIFT_7            ; $3F53  CA A9 40
        CP $DD                           ; $3F56  FE DD
        JP Z,EDIT_BUF_SHIFT_8            ; $3F58  CA B6 40
        CP $F0                           ; $3F5B  FE F0
        JR Z,EDIT_ECHO_SPAN              ; $3F5D  28 45
        CP $31                           ; $3F5F  FE 31
        JR C,STMT_EDIT_11                ; $3F61  38 02
        SUB $20                          ; $3F63  D6 20
STMT_EDIT_11:
        CP $21                           ; $3F65  FE 21
        JP Z,EDIT_BUF_SHIFT_11           ; $3F67  CA CB 40
        CP $1C                           ; $3F6A  FE 1C
        JP Z,EDIT_ECHO_SPAN_6            ; $3F6C  CA DA 3F
        CP $23                           ; $3F6F  FE 23
        JR Z,EDIT_ECHO_SPAN_2            ; $3F71  28 43
        CP $19                           ; $3F73  FE 19
        JP Z,EDIT_EMIT_BACKSLASH_7       ; $3F75  CA 2E 40
        CP $14                           ; $3F78  FE 14
        JP Z,EDIT_ECHO_SPAN_7            ; $3F7A  CA E4 3F
        CP $13                           ; $3F7D  FE 13
        JP Z,EDIT_EMIT_BACKSLASH_1       ; $3F7F  CA FF 3F
        CP $15                           ; $3F82  FE 15
        JP Z,EDIT_BUF_SHIFT_9            ; $3F84  CA B9 40
        CP $28                           ; $3F87  FE 28
        JP Z,EDIT_EMIT_BACKSLASH_6       ; $3F89  CA 29 40
        CP $1B                           ; $3F8C  FE 1B
        JR Z,EDIT_ECHO_SPAN_1            ; $3F8E  28 20
        CP $18                           ; $3F90  FE 18
        JP Z,EDIT_EMIT_BACKSLASH_5       ; $3F92  CA 26 40
        CP $11                           ; $3F95  FE 11
        LD A,$07                         ; $3F97  3E 07
        JP NZ,OUTCHR                     ; $3F99  C2 91 42
        POP BC                           ; $3F9C  C1
        POP DE                           ; $3F9D  D1
        CALL CRLF                        ; $3F9E  CD 06 44
        JP STMT_EDIT_2                   ; $3FA1  C3 ED 3E
; [RE] Line-editor helper: echo D characters of the line buffer at (HL) to the console (OUTCHR via SUB_6800), advancing HL and the column count B; ESC ($1B) enters the copy/scan sub-mode (EDIT_COPY_MODE). Part of the EDIT/line-input screen editor.
EDIT_ECHO_SPAN:
        LD A,(HL)                        ; $3FA4  7E
        OR A                             ; $3FA5  B7
        RET Z                            ; $3FA6  C8
        INC B                            ; $3FA7  04
        CALL OUTCHR_LF_EXPAND            ; $3FA8  CD 7E 44
        INC HL                           ; $3FAB  23
        DEC D                            ; $3FAC  15
        JR NZ,EDIT_ECHO_SPAN             ; $3FAD  20 F5
        RET                              ; $3FAF  C9
EDIT_ECHO_SPAN_1:
        PUSH HL                          ; $3FB0  E5
        LD HL,EDIT_EMIT_BACKSLASH        ; $3FB1  21 F9 3F
        EX (SP),HL                       ; $3FB4  E3
        SCF                              ; $3FB5  37
EDIT_ECHO_SPAN_2:
        PUSH AF                          ; $3FB6  F5
        CALL CONIN                       ; $3FB7  CD DA 43
        LD E,A                           ; $3FBA  5F
        POP AF                           ; $3FBB  F1
        PUSH AF                          ; $3FBC  F5
        CALL C,EDIT_EMIT_BACKSLASH       ; $3FBD  DC F9 3F
EDIT_ECHO_SPAN_3:
        LD A,(HL)                        ; $3FC0  7E
        OR A                             ; $3FC1  B7
        JP Z,EDIT_ECHO_SPAN_5            ; $3FC2  CA D8 3F
        CALL OUTCHR_LF_EXPAND            ; $3FC5  CD 7E 44
        POP AF                           ; $3FC8  F1
        PUSH AF                          ; $3FC9  F5
        CALL C,EDIT_BUF_SHIFT            ; $3FCA  DC 68 40
        JR C,EDIT_ECHO_SPAN_4            ; $3FCD  38 02
        INC HL                           ; $3FCF  23
        INC B                            ; $3FD0  04
EDIT_ECHO_SPAN_4:
        LD A,(HL)                        ; $3FD1  7E
        CP E                             ; $3FD2  BB
        JR NZ,EDIT_ECHO_SPAN_3           ; $3FD3  20 EB
        DEC D                            ; $3FD5  15
        JR NZ,EDIT_ECHO_SPAN_3           ; $3FD6  20 E8
EDIT_ECHO_SPAN_5:
        POP AF                           ; $3FD8  F1
        RET                              ; $3FD9  C9
EDIT_ECHO_SPAN_6:
        CALL PRINT_ZSTRING               ; $3FDA  CD 1B 21
        CALL CRLF                        ; $3FDD  CD 06 44
        POP BC                           ; $3FE0  C1
        JP STMT_EDIT_3                   ; $3FE1  C3 04 3F
EDIT_ECHO_SPAN_7:
        LD A,(HL)                        ; $3FE4  7E
        OR A                             ; $3FE5  B7
        RET Z                            ; $3FE6  C8
        LD A,$5C                         ; $3FE7  3E 5C
        CALL OUTCHR_LF_EXPAND            ; $3FE9  CD 7E 44
EDIT_ECHO_SPAN_8:
        LD A,(HL)                        ; $3FEC  7E
        OR A                             ; $3FED  B7
        JR Z,EDIT_EMIT_BACKSLASH         ; $3FEE  28 09
        CALL OUTCHR_LF_EXPAND            ; $3FF0  CD 7E 44
        CALL EDIT_BUF_SHIFT              ; $3FF3  CD 68 40
        DEC D                            ; $3FF6  15
        JR NZ,EDIT_ECHO_SPAN_8           ; $3FF7  20 F3
; [RE] Line-editor helper: emit a '\' ($5C) line-terminator marker through OUTCHR; entry SUB_637B_1/_2 read replacement characters from the console (CONIN), filtering control chars, and overwrite the buffer (insert/overtype) for the EDIT screen editor.
EDIT_EMIT_BACKSLASH:
        LD A,$5C                         ; $3FF9  3E 5C
        CALL OUTCHR                      ; $3FFB  CD 91 42
        RET                              ; $3FFE  C9
EDIT_EMIT_BACKSLASH_1:
        LD A,(HL)                        ; $3FFF  7E
        OR A                             ; $4000  B7
        RET Z                            ; $4001  C8
EDIT_EMIT_BACKSLASH_2:
        CALL CONIN                       ; $4002  CD DA 43
        CP $20                           ; $4005  FE 20
        JR NC,EDIT_EMIT_BACKSLASH_3      ; $4007  30 13
        CP $0A                           ; $4009  FE 0A
        JR Z,EDIT_EMIT_BACKSLASH_3       ; $400B  28 0F
        CP $07                           ; $400D  FE 07
        JR Z,EDIT_EMIT_BACKSLASH_3       ; $400F  28 0B
        CP $09                           ; $4011  FE 09
        JR Z,EDIT_EMIT_BACKSLASH_3       ; $4013  28 07
        LD A,$07                         ; $4015  3E 07
        CALL OUTCHR                      ; $4017  CD 91 42
        JR EDIT_EMIT_BACKSLASH_2         ; $401A  18 E6
EDIT_EMIT_BACKSLASH_3:
        LD (HL),A                        ; $401C  77
EDIT_EMIT_BACKSLASH_4:
        CALL OUTCHR_LF_EXPAND            ; $401D  CD 7E 44
        INC HL                           ; $4020  23
        INC B                            ; $4021  04
        DEC D                            ; $4022  15
        JR NZ,EDIT_EMIT_BACKSLASH_1      ; $4023  20 DA
        RET                              ; $4025  C9
EDIT_EMIT_BACKSLASH_5:
        LD (HL),$00                      ; $4026  36 00
        LD C,B                           ; $4028  48
EDIT_EMIT_BACKSLASH_6:
        LD D,$FF                         ; $4029  16 FF
        CALL EDIT_ECHO_SPAN              ; $402B  CD A4 3F
EDIT_EMIT_BACKSLASH_7:
        CALL CONIN                       ; $402E  CD DA 43
        CP $7F                           ; $4031  FE 7F
        JR Z,EDIT_EMIT_BACKSLASH_8       ; $4033  28 24
        CP $08                           ; $4035  FE 08
        JR Z,EDIT_EMIT_BACKSLASH_9       ; $4037  28 22
        CP $0D                           ; $4039  FE 0D
        JP Z,EDIT_BUF_SHIFT_8            ; $403B  CA B6 40
        CP $1B                           ; $403E  FE 1B
        RET Z                            ; $4040  C8
        CP $08                           ; $4041  FE 08
        JR Z,EDIT_EMIT_BACKSLASH_9       ; $4043  28 16
        CP $0A                           ; $4045  FE 0A
        JR Z,EDIT_BUF_SHIFT_2            ; $4047  28 2E
        CP $07                           ; $4049  FE 07
        JR Z,EDIT_BUF_SHIFT_2            ; $404B  28 2A
        CP $09                           ; $404D  FE 09
        JR Z,EDIT_BUF_SHIFT_2            ; $404F  28 26
        CP $20                           ; $4051  FE 20
        JR C,EDIT_EMIT_BACKSLASH_7       ; $4053  38 D9
        CP $5F                           ; $4055  FE 5F
        JR NZ,EDIT_BUF_SHIFT_2           ; $4057  20 1E
EDIT_EMIT_BACKSLASH_8:
        LD A,$5F                         ; $4059  3E 5F
EDIT_EMIT_BACKSLASH_9:
        DEC B                            ; $405B  05
        INC B                            ; $405C  04
        JR Z,EDIT_BUF_SHIFT_3            ; $405D  28 1F
        CALL OUTCHR_LF_EXPAND            ; $405F  CD 7E 44
        DEC HL                           ; $4062  2B
        DEC B                            ; $4063  05
        LD DE,EDIT_EMIT_BACKSLASH_7      ; $4064  11 2E 40
        PUSH DE                          ; $4067  D5
; [RE] Line-editor buffer-shift helper: pull characters down within the edit buffer at (HL) until the NUL terminator (used for delete/backspace in the EDIT screen editor). The continuation labels SUB_63EA_9.. share code into the PRINT USING formatter below.
EDIT_BUF_SHIFT:
        PUSH HL                          ; $4068  E5
        DEC C                            ; $4069  0D
EDIT_BUF_SHIFT_1:
        LD A,(HL)                        ; $406A  7E
        OR A                             ; $406B  B7
        SCF                              ; $406C  37
        JP Z,FMUL_7                      ; $406D  CA E1 29
        INC HL                           ; $4070  23
        LD A,(HL)                        ; $4071  7E
        DEC HL                           ; $4072  2B
        LD (HL),A                        ; $4073  77
        INC HL                           ; $4074  23
        JR EDIT_BUF_SHIFT_1              ; $4075  18 F3
EDIT_BUF_SHIFT_2:
        PUSH AF                          ; $4077  F5
        LD A,C                           ; $4078  79
        CP $FF                           ; $4079  FE FF
        JR C,EDIT_BUF_SHIFT_5            ; $407B  38 08
        POP AF                           ; $407D  F1
EDIT_BUF_SHIFT_3:
        LD A,$07                         ; $407E  3E 07
        CALL OUTCHR                      ; $4080  CD 91 42
EDIT_BUF_SHIFT_4:
        JR EDIT_EMIT_BACKSLASH_7         ; $4083  18 A9
EDIT_BUF_SHIFT_5:
        SUB B                            ; $4085  90
        INC C                            ; $4086  0C
        INC B                            ; $4087  04
        PUSH BC                          ; $4088  C5
        EX DE,HL                         ; $4089  EB
        LD L,A                           ; $408A  6F
        LD H,$00                         ; $408B  26 00
        ADD HL,DE                        ; $408D  19
        LD B,H                           ; $408E  44
        LD C,L                           ; $408F  4D
        INC HL                           ; $4090  23
        CALL STR_COPY_DOWN_NOCHK         ; $4091  CD 92 44
        POP BC                           ; $4094  C1
        POP AF                           ; $4095  F1
        LD (HL),A                        ; $4096  77
        CALL OUTCHR_LF_EXPAND            ; $4097  CD 7E 44
        INC HL                           ; $409A  23
        JP EDIT_BUF_SHIFT_4              ; $409B  C3 83 40
EDIT_BUF_SHIFT_6:
        LD A,B                           ; $409E  78
        OR A                             ; $409F  B7
        RET Z                            ; $40A0  C8
        CALL INLIN_BACKSPACE             ; $40A1  CD C3 4D
        DEC B                            ; $40A4  05
        DEC D                            ; $40A5  15
        JR NZ,EDIT_BUF_SHIFT_7           ; $40A6  20 01
        RET                              ; $40A8  C9
EDIT_BUF_SHIFT_7:
        LD A,B                           ; $40A9  78
        OR A                             ; $40AA  B7
        RET Z                            ; $40AB  C8
        DEC B                            ; $40AC  05
        DEC HL                           ; $40AD  2B
        LD A,(HL)                        ; $40AE  7E
        CALL OUTCHR_LF_EXPAND            ; $40AF  CD 7E 44
        DEC D                            ; $40B2  15
        JR NZ,EDIT_BUF_SHIFT_7           ; $40B3  20 F4
        RET                              ; $40B5  C9
EDIT_BUF_SHIFT_8:
        CALL PRINT_ZSTRING               ; $40B6  CD 1B 21
EDIT_BUF_SHIFT_9:
        CALL CRLF                        ; $40B9  CD 06 44
        POP BC                           ; $40BC  C1
        POP DE                           ; $40BD  D1
        LD A,D                           ; $40BE  7A
        AND E                            ; $40BF  A3
        INC A                            ; $40C0  3C
EDIT_BUF_SHIFT_10:
        LD HL,SUB_0925_2                 ; $40C1  21 30 0A
        RET Z                            ; $40C4  C8
        SCF                              ; $40C5  37
        PUSH AF                          ; $40C6  F5
        INC HL                           ; $40C7  23
        JP DIRECT_EXEC_STMT              ; $40C8  C3 C9 0E
EDIT_BUF_SHIFT_11:
        POP BC                           ; $40CB  C1
        POP DE                           ; $40CC  D1
        LD A,D                           ; $40CD  7A
        AND E                            ; $40CE  A3
        INC A                            ; $40CF  3C
        JP Z,PRINT_CRLF_IF_COL_1         ; $40D0  CA 01 44
        JP NEWSTT_READY                  ; $40D3  C3 46 0E
; [RE] PRINT USING statement engine (reached from the PRINT dispatcher on token $E8 'USING'): evaluate the format string, then scan its field characters - '#' digit positions, '.' decimal point, ',' grouping, '+'/'-' sign, '$$' float-dollar, '**' asterisk-fill, '^^^^' exponential, '\ \' string field, '!' first-char, '&' variable string - formatting each argument (FOUT/SUB_5723 for numbers, STROUT for strings) and looping over the value list.
PRINT_USING:
        CALL FRMEVL_LOWPREC              ; $40D6  CD 91 1A
        CALL FP_INT_CHECK                ; $40D9  CD B3 2C
        CALL SYNCHR                      ; $40DC  CD A3 45
        DEFB    ';'                      ; $40DF  3B  inline char arg consumed by the preceding CALL
        EX DE,HL                         ; $40E0  EB
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $40E1  2A D4 0C
        JR PRINT_USING_2                 ; $40E4  18 08
PRINT_USING_1:
        LD A,(DATA_LINE_TXTPTR_2)        ; $40E6  3A 76 0B
        OR A                             ; $40E9  B7
        JR Z,PRINT_USING_3               ; $40EA  28 0C
        POP DE                           ; $40EC  D1
        EX DE,HL                         ; $40ED  EB
PRINT_USING_2:
        PUSH HL                          ; $40EE  E5
        XOR A                            ; $40EF  AF
        LD (DATA_LINE_TXTPTR_2),A        ; $40F0  32 76 0B
        CP D                             ; $40F3  BA
        PUSH AF                          ; $40F4  F5
        PUSH DE                          ; $40F5  D5
        LD B,(HL)                        ; $40F6  46
        OR B                             ; $40F7  B0
PRINT_USING_3:
        JP Z,GETINT_POSITIVE_1           ; $40F8  CA EB 14
        INC HL                           ; $40FB  23
        LD C,(HL)                        ; $40FC  4E
        INC HL                           ; $40FD  23
        LD H,(HL)                        ; $40FE  66
        LD L,C                           ; $40FF  69
        JR PRINT_USING_8                 ; $4100  18 1C
PRINT_USING_4:
        LD E,B                           ; $4102  58
        PUSH HL                          ; $4103  E5
        LD C,$02                         ; $4104  0E 02
PRINT_USING_5:
        LD A,(HL)                        ; $4106  7E
        INC HL                           ; $4107  23
        CP $5C                           ; $4108  FE 5C
        JP Z,PRINT_USING_31+1            ; $410A  CA 50 42
        CP $20                           ; $410D  FE 20
        JR NZ,PRINT_USING_6              ; $410F  20 03
        INC C                            ; $4111  0C
        DJNZ PRINT_USING_5               ; $4112  10 F2
PRINT_USING_6:
        POP HL                           ; $4114  E1
        LD B,E                           ; $4115  43
        LD A,$5C                         ; $4116  3E 5C
PRINT_USING_7:
        CALL PRINT_USING_PUT_SIGN        ; $4118  CD 87 42
        CALL OUTCHR                      ; $411B  CD 91 42
PRINT_USING_8:
        XOR A                            ; $411E  AF
        LD E,A                           ; $411F  5F
        LD D,A                           ; $4120  57
PRINT_USING_9:
        CALL PRINT_USING_PUT_SIGN        ; $4121  CD 87 42
        LD D,A                           ; $4124  57
        LD A,(HL)                        ; $4125  7E
        INC HL                           ; $4126  23
        CP $21                           ; $4127  FE 21
        JP Z,PRINT_USING_30              ; $4129  CA 4D 42
        CP $23                           ; $412C  FE 23
        JR Z,PRINT_USING_13              ; $412E  28 41
        CP $26                           ; $4130  FE 26
        JP Z,PRINT_USING_29              ; $4132  CA 49 42
        DEC B                            ; $4135  05
        JP Z,PRINT_USING_25              ; $4136  CA 28 42
        CP $2B                           ; $4139  FE 2B
        LD A,$08                         ; $413B  3E 08
        JR Z,PRINT_USING_9               ; $413D  28 E2
        DEC HL                           ; $413F  2B
        LD A,(HL)                        ; $4140  7E
        INC HL                           ; $4141  23
        CP $2E                           ; $4142  FE 2E
        JR Z,PRINT_USING_14              ; $4144  28 45
        CP $5F                           ; $4146  FE 5F
        JP Z,PRINT_USING_28              ; $4148  CA 3E 42
        CP $5C                           ; $414B  FE 5C
        JR Z,PRINT_USING_4               ; $414D  28 B3
        CP (HL)                          ; $414F  BE
        JR NZ,PRINT_USING_7              ; $4150  20 C6
        CP $24                           ; $4152  FE 24
        JR Z,PRINT_USING_11+1            ; $4154  28 14
        CP $2A                           ; $4156  FE 2A
        JR NZ,PRINT_USING_7              ; $4158  20 BE
        LD A,B                           ; $415A  78
        INC HL                           ; $415B  23
        CP $02                           ; $415C  FE 02
        JR C,PRINT_USING_10              ; $415E  38 03
        LD A,(HL)                        ; $4160  7E
        CP $24                           ; $4161  FE 24
PRINT_USING_10:
        LD A,$20                         ; $4163  3E 20
        JR NZ,PRINT_USING_12             ; $4165  20 07
        DEC B                            ; $4167  05
        INC E                            ; $4168  1C
PRINT_USING_11:
        CP $AF                           ; $4169  FE AF
        ADD A,$10                        ; $416B  C6 10
        INC HL                           ; $416D  23
PRINT_USING_12:
        INC E                            ; $416E  1C
        ADD A,D                          ; $416F  82
        LD D,A                           ; $4170  57
PRINT_USING_13:
        INC E                            ; $4171  1C
        LD C,$00                         ; $4172  0E 00
        DEC B                            ; $4174  05
        JR Z,PRINT_USING_18              ; $4175  28 48
        LD A,(HL)                        ; $4177  7E
        INC HL                           ; $4178  23
        CP $2E                           ; $4179  FE 2E
        JR Z,PRINT_USING_15              ; $417B  28 19
        CP $23                           ; $417D  FE 23
        JR Z,PRINT_USING_13              ; $417F  28 F0
        CP $2C                           ; $4181  FE 2C
        JR NZ,PRINT_USING_16             ; $4183  20 1B
        LD A,D                           ; $4185  7A
        OR $40                           ; $4186  F6 40
        LD D,A                           ; $4188  57
        JR PRINT_USING_13                ; $4189  18 E6
PRINT_USING_14:
        LD A,(HL)                        ; $418B  7E
        CP $23                           ; $418C  FE 23
        LD A,$2E                         ; $418E  3E 2E
        JP NZ,PRINT_USING_7              ; $4190  C2 18 41
        LD C,$01                         ; $4193  0E 01
        INC HL                           ; $4195  23
PRINT_USING_15:
        INC C                            ; $4196  0C
        DEC B                            ; $4197  05
        JR Z,PRINT_USING_18              ; $4198  28 25
        LD A,(HL)                        ; $419A  7E
        INC HL                           ; $419B  23
        CP $23                           ; $419C  FE 23
        JR Z,PRINT_USING_15              ; $419E  28 F6
PRINT_USING_16:
        PUSH DE                          ; $41A0  D5
        LD DE,PRINT_USING_17+1           ; $41A1  11 BD 41
        PUSH DE                          ; $41A4  D5
        LD D,H                           ; $41A5  54
        LD E,L                           ; $41A6  5D
        CP $5E                           ; $41A7  FE 5E
        RET NZ                           ; $41A9  C0
        CP (HL)                          ; $41AA  BE
        RET NZ                           ; $41AB  C0
        INC HL                           ; $41AC  23
        CP (HL)                          ; $41AD  BE
        RET NZ                           ; $41AE  C0
        INC HL                           ; $41AF  23
        CP (HL)                          ; $41B0  BE
        RET NZ                           ; $41B1  C0
        INC HL                           ; $41B2  23
        LD A,B                           ; $41B3  78
        SUB $04                          ; $41B4  D6 04
        RET C                            ; $41B6  D8
        POP DE                           ; $41B7  D1
        POP DE                           ; $41B8  D1
        LD B,A                           ; $41B9  47
        INC D                            ; $41BA  14
        INC HL                           ; $41BB  23
PRINT_USING_17:
        JP Z,$D1EB                       ; $41BC  CA EB D1
PRINT_USING_18:
        LD A,D                           ; $41BF  7A
        DEC HL                           ; $41C0  2B
        INC E                            ; $41C1  1C
        AND $08                          ; $41C2  E6 08
        JR NZ,PRINT_USING_20             ; $41C4  20 15
        DEC E                            ; $41C6  1D
        LD A,B                           ; $41C7  78
        OR A                             ; $41C8  B7
        JR Z,PRINT_USING_20              ; $41C9  28 10
        LD A,(HL)                        ; $41CB  7E
        SUB $2D                          ; $41CC  D6 2D
        JR Z,PRINT_USING_19              ; $41CE  28 06
        CP $FE                           ; $41D0  FE FE
        JR NZ,PRINT_USING_20             ; $41D2  20 07
        LD A,$08                         ; $41D4  3E 08
PRINT_USING_19:
        ADD A,$04                        ; $41D6  C6 04
        ADD A,D                          ; $41D8  82
        LD D,A                           ; $41D9  57
        DEC B                            ; $41DA  05
PRINT_USING_20:
        POP HL                           ; $41DB  E1
        POP AF                           ; $41DC  F1
        JR Z,PRINT_USING_27              ; $41DD  28 54
        PUSH BC                          ; $41DF  C5
        PUSH DE                          ; $41E0  D5
        CALL FRMEVL_NOPAREN              ; $41E1  CD 90 1A
        POP DE                           ; $41E4  D1
        POP BC                           ; $41E5  C1
        PUSH BC                          ; $41E6  C5
        PUSH HL                          ; $41E7  E5
        LD B,E                           ; $41E8  43
        LD A,B                           ; $41E9  78
        ADD A,C                          ; $41EA  81
        CP $19                           ; $41EB  FE 19
        JP NC,GETINT_POSITIVE_1          ; $41ED  D2 EB 14
        LD A,D                           ; $41F0  7A
        OR $80                           ; $41F1  F6 80
        CALL FOUT_BODY                   ; $41F3  CD A1 33
        CALL STROUT                      ; $41F6  CD BE 48
PRINT_USING_21:
        POP HL                           ; $41F9  E1
        DEC HL                           ; $41FA  2B
        CALL CHRGET                      ; $41FB  CD E4 13
        SCF                              ; $41FE  37
        JR Z,PRINT_USING_23              ; $41FF  28 0F
        LD (DATA_LINE_TXTPTR_2),A        ; $4201  32 76 0B
        CP $3B                           ; $4204  FE 3B
        JR Z,PRINT_USING_22              ; $4206  28 05
        CP $2C                           ; $4208  FE 2C
        JP NZ,RAISE_SYNTAX_ERROR         ; $420A  C2 92 0D
PRINT_USING_22:
        CALL CHRGET                      ; $420D  CD E4 13
PRINT_USING_23:
        POP BC                           ; $4210  C1
        EX DE,HL                         ; $4211  EB
        POP HL                           ; $4212  E1
        PUSH HL                          ; $4213  E5
        PUSH AF                          ; $4214  F5
        PUSH DE                          ; $4215  D5
        LD A,(HL)                        ; $4216  7E
        SUB B                            ; $4217  90
        INC HL                           ; $4218  23
        LD C,(HL)                        ; $4219  4E
        INC HL                           ; $421A  23
        LD H,(HL)                        ; $421B  66
        LD L,C                           ; $421C  69
        LD D,$00                         ; $421D  16 00
        LD E,A                           ; $421F  5F
        ADD HL,DE                        ; $4220  19
PRINT_USING_24:
        LD A,B                           ; $4221  78
        OR A                             ; $4222  B7
        JP NZ,PRINT_USING_8              ; $4223  C2 1E 41
        JR PRINT_USING_26                ; $4226  18 06
PRINT_USING_25:
        CALL PRINT_USING_PUT_SIGN        ; $4228  CD 87 42
        CALL OUTCHR                      ; $422B  CD 91 42
PRINT_USING_26:
        POP HL                           ; $422E  E1
        POP AF                           ; $422F  F1
        JP NZ,PRINT_USING_1              ; $4230  C2 E6 40
PRINT_USING_27:
        CALL C,CRLF                      ; $4233  DC 06 44
        EX (SP),HL                       ; $4236  E3
        CALL FRESTR_DE                   ; $4237  CD 3D 4A
        POP HL                           ; $423A  E1
        JP PRINT_RESET_STATE             ; $423B  C3 9A 18
PRINT_USING_28:
        CALL PRINT_USING_PUT_SIGN        ; $423E  CD 87 42
        DEC B                            ; $4241  05
        LD A,(HL)                        ; $4242  7E
        INC HL                           ; $4243  23
        CALL OUTCHR                      ; $4244  CD 91 42
        JR PRINT_USING_24                ; $4247  18 D8
PRINT_USING_29:
        LD C,$FF                         ; $4249  0E FF
        JR PRINT_USING_32                ; $424B  18 04
PRINT_USING_30:
        LD C,$01                         ; $424D  0E 01
PRINT_USING_31:
        LD A,$F1                         ; $424F  3E F1
PRINT_USING_32:
        DEC B                            ; $4251  05
        CALL PRINT_USING_PUT_SIGN        ; $4252  CD 87 42
        POP HL                           ; $4255  E1
        POP AF                           ; $4256  F1
        JR Z,PRINT_USING_27              ; $4257  28 DA
        PUSH BC                          ; $4259  C5
        CALL FRMEVL_NOPAREN              ; $425A  CD 90 1A
        CALL FP_INT_CHECK                ; $425D  CD B3 2C
        POP BC                           ; $4260  C1
        PUSH BC                          ; $4261  C5
        PUSH HL                          ; $4262  E5
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $4263  2A D4 0C
        LD B,C                           ; $4266  41
        LD C,$00                         ; $4267  0E 00
        PUSH BC                          ; $4269  C5
        CALL STR_SUBSTR_ALLOC_COPY_2+1   ; $426A  CD DA 4A
        CALL STRPRT                      ; $426D  CD C1 48
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $4270  2A D4 0C
        POP AF                           ; $4273  F1
        INC A                            ; $4274  3C
        JP Z,PRINT_USING_21              ; $4275  CA F9 41
        DEC A                            ; $4278  3D
        SUB (HL)                         ; $4279  96
        LD B,A                           ; $427A  47
        LD A,$20                         ; $427B  3E 20
        INC B                            ; $427D  04
PRINT_USING_33:
        DEC B                            ; $427E  05
        JP Z,PRINT_USING_21              ; $427F  CA F9 41
        CALL OUTCHR                      ; $4282  CD 91 42
        JR PRINT_USING_33                ; $4285  18 F7
; [RE] PRINT USING helper: if the pending-sign flag in D is set, emit a leading '+' ($2B) via OUTCHR before the formatted field; preserves AF.
PRINT_USING_PUT_SIGN:
        PUSH AF                          ; $4287  F5
        LD A,D                           ; $4288  7A
        OR A                             ; $4289  B7
        LD A,$2B                         ; $428A  3E 2B
        CALL NZ,OUTCHR                   ; $428C  C4 91 42
        POP AF                           ; $428F  F1
        RET                              ; $4290  C9
; [RE] OUTCHR: console character output with column tracking ($0837 cursor column), TAB ($09) expansion to 8-col stops, backspace ($08) and CR handling, then emits the byte through the BIOS console-out vector (SUB_666C, CALL into the runtime-patched $0000 cell).
OUTCHR:
        PUSH AF                          ; $4291  F5
        PUSH HL                          ; $4292  E5
        LD HL,(PTRFIL)                   ; $4293  2A 63 08
        LD A,H                           ; $4296  7C
        OR L                             ; $4297  B5
        JP NZ,FN_LOF_VALUE_1             ; $4298  C2 9E 57
        POP HL                           ; $429B  E1
        LD A,(SUB_0752_32+1)             ; $429C  3A 5B 08
        OR A                             ; $429F  B7
        JP Z,OUTDO_WIDTH_1               ; $42A0  CA 0F 43
        POP AF                           ; $42A3  F1
        PUSH AF                          ; $42A4  F5
        CP $08                           ; $42A5  FE 08
        JR NZ,OUTCHR_1                   ; $42A7  20 0A
        LD A,(SUB_0752_32)               ; $42A9  3A 5A 08
        DEC A                            ; $42AC  3D
        LD (SUB_0752_32),A               ; $42AD  32 5A 08
        POP AF                           ; $42B0  F1
        JR OUTDO_DEVICE                  ; $42B1  18 37
OUTCHR_1:
        CP $09                           ; $42B3  FE 09
        JR NZ,OUTCHR_3                   ; $42B5  20 0E
OUTCHR_2:
        LD A,$20                         ; $42B7  3E 20
        CALL OUTCHR                      ; $42B9  CD 91 42
        LD A,(SUB_0752_32)               ; $42BC  3A 5A 08
        AND $07                          ; $42BF  E6 07
        JR NZ,OUTCHR_2                   ; $42C1  20 F4
        POP AF                           ; $42C3  F1
        RET                              ; $42C4  C9
OUTCHR_3:
        POP AF                           ; $42C5  F1
        PUSH AF                          ; $42C6  F5
        SUB $0D                          ; $42C7  D6 0D
        JR Z,OUTCHR_5                    ; $42C9  28 1B
        JR C,OUTCHR_6                    ; $42CB  38 1C
        LD A,(SUB_0752_33)               ; $42CD  3A 5D 08
        INC A                            ; $42D0  3C
        LD A,(SUB_0752_32)               ; $42D1  3A 5A 08
        JR Z,OUTCHR_4                    ; $42D4  28 0B
        PUSH HL                          ; $42D6  E5
        LD HL,SUB_0752_33                ; $42D7  21 5D 08
        CP (HL)                          ; $42DA  BE
        POP HL                           ; $42DB  E1
        CALL Z,OUTDO_WIDTH               ; $42DC  CC 00 43
        JR Z,OUTCHR_6                    ; $42DF  28 08
OUTCHR_4:
        CP $FF                           ; $42E1  FE FF
        JR Z,OUTCHR_6                    ; $42E3  28 04
        INC A                            ; $42E5  3C
OUTCHR_5:
        LD (SUB_0752_32),A               ; $42E6  32 5A 08
OUTCHR_6:
        POP AF                           ; $42E9  F1
; [RE] Low-level BIOS console-out vector wrapper: char in A, saves BC/DE/HL, copies to C, CALLs the runtime-patched $0000 cell (CP/M BIOS CONOUT, installed by cold start at SUB_666C_1+1 / $8217). The device-output primitive that OUTCHR ($6613) and OUTDO_WIDTH ($6682) route through.
OUTDO_DEVICE:
        PUSH AF                          ; $42EA  F5
        PUSH BC                          ; $42EB  C5
        PUSH DE                          ; $42EC  D5
        PUSH HL                          ; $42ED  E5
        LD C,A                           ; $42EE  4F
OUTDO_DEVICE_1:
        CALL $0000                       ; $42EF  CD 00 00
        POP HL                           ; $42F2  E1
        POP DE                           ; $42F3  D1
        POP BC                           ; $42F4  C1
        POP AF                           ; $42F5  F1
        RET                              ; $42F6  C9
; [RE] Clears the output-suppress flag ($0838) and, if the print column ($0837) is nonzero, falls through to OUTDO_WIDTH to emit CRLF and reset the column. The 'return to start of line' helper before fresh output.
OUTDO_RESET_COL:
        XOR A                            ; $42F7  AF
        LD (SUB_0752_32+1),A             ; $42F8  32 5B 08
        LD A,(SUB_0752_32)               ; $42FB  3A 5A 08
        OR A                             ; $42FE  B7
        RET Z                            ; $42FF  C8
; [RE] High-level char-out with line-width/auto-CR logic: enforces the terminal width, expands TAB, handles backspace against the column counter ($0B11), and issues CRLF when the print column reaches the width. Wraps the OUTCHR primitive (SUB_6704).
OUTDO_WIDTH:
        LD A,$0D                         ; $4300  3E 0D
        CALL OUTDO_DEVICE                ; $4302  CD EA 42
        LD A,$0A                         ; $4305  3E 0A
        CALL OUTDO_DEVICE                ; $4307  CD EA 42
        XOR A                            ; $430A  AF
        LD (SUB_0752_32),A               ; $430B  32 5A 08
        RET                              ; $430E  C9
OUTDO_WIDTH_1:
        LD A,(CTRL_O_SUPPRESS)           ; $430F  3A 62 08
        OR A                             ; $4312  B7
        JP NZ,GETSPA_2                   ; $4313  C2 F1 48
        POP AF                           ; $4316  F1
        PUSH BC                          ; $4317  C5
        PUSH AF                          ; $4318  F5
        CP $0A                           ; $4319  FE 0A
        JR NZ,OUTDO_WIDTH_3              ; $431B  20 05
OUTDO_WIDTH_2:
        CALL LINE_COUNT_INC              ; $431D  CD 92 43
        LD A,$0A                         ; $4320  3E 0A
OUTDO_WIDTH_3:
        CP $08                           ; $4322  FE 08
        JR NZ,OUTDO_WIDTH_5              ; $4324  20 1B
        LD A,(SUB_0B2A_2)                ; $4326  3A 34 0B
        OR A                             ; $4329  B7
        JR NZ,OUTDO_WIDTH_4              ; $432A  20 0D
        LD A,(SUB_0B2A_3)                ; $432C  3A 35 0B
        OR A                             ; $432F  B7
        JR Z,OUTDO_WIDTH_7               ; $4330  28 1F
        DEC A                            ; $4332  3D
        LD (SUB_0B2A_3),A                ; $4333  32 35 0B
        LD A,(SUB_0752_34)               ; $4336  3A 5E 08
OUTDO_WIDTH_4:
        DEC A                            ; $4339  3D
        LD (SUB_0B2A_2),A                ; $433A  32 34 0B
        LD A,$08                         ; $433D  3E 08
        JR OUTDO_WIDTH_9                 ; $433F  18 17
OUTDO_WIDTH_5:
        CP $09                           ; $4341  FE 09
        JR NZ,OUTDO_WIDTH_8              ; $4343  20 0F
OUTDO_WIDTH_6:
        LD A,$20                         ; $4345  3E 20
        CALL OUTCHR                      ; $4347  CD 91 42
        LD A,(SUB_0B2A_2)                ; $434A  3A 34 0B
        AND $07                          ; $434D  E6 07
        JR NZ,OUTDO_WIDTH_6              ; $434F  20 F4
OUTDO_WIDTH_7:
        POP AF                           ; $4351  F1
        POP BC                           ; $4352  C1
        RET                              ; $4353  C9
OUTDO_WIDTH_8:
        CP $20                           ; $4354  FE 20
        JR C,OUTDO_WIDTH_9               ; $4356  38 00
OUTDO_WIDTH_9:
        POP AF                           ; $4358  F1
        PUSH AF                          ; $4359  F5
        CALL OUTDO_DEVICE2               ; $435A  CD 82 43
        CP $20                           ; $435D  FE 20
        JR C,OUTDO_WIDTH_10              ; $435F  38 1E
        LD A,(SUB_0752_34)               ; $4361  3A 5E 08
        INC A                            ; $4364  3C
        JR Z,OUTDO_WIDTH_10              ; $4365  28 18
        DEC A                            ; $4367  3D
        LD B,A                           ; $4368  47
        LD A,(SUB_0B2A_2)                ; $4369  3A 34 0B
        INC A                            ; $436C  3C
        JR Z,OUTDO_WIDTH_10              ; $436D  28 10
        LD (SUB_0B2A_2),A                ; $436F  32 34 0B
        CP B                             ; $4372  B8
        JR NZ,OUTDO_WIDTH_10             ; $4373  20 0A
        LD A,(SUB_2803_3)                ; $4375  3A 15 28
        CP B                             ; $4378  B8
        CALL Z,LIST_NEWLINE_COUNT        ; $4379  CC 8F 43
        CALL NZ,CRLF                     ; $437C  C4 06 44
OUTDO_WIDTH_10:
        POP AF                           ; $437F  F1
        POP BC                           ; $4380  C1
        RET                              ; $4381  C9
; [RE] Second BIOS console-out vector wrapper (raw byte emit): char in A->C, saves regs, CALLs the runtime-patched $0000 cell (separate CP/M BIOS output entry installed by cold start at SUB_6704_1+1 / $820D). Used by OUTDO_WIDTH for the actual character emission distinct from OUTDO_DEVICE.
OUTDO_DEVICE2:
        PUSH AF                          ; $4382  F5
        PUSH BC                          ; $4383  C5
        PUSH DE                          ; $4384  D5
        PUSH HL                          ; $4385  E5
        LD C,A                           ; $4386  4F
OUTDO_DEVICE2_1:
        CALL $0000                       ; $4387  CD 00 00
        POP HL                           ; $438A  E1
        POP DE                           ; $438B  D1
        POP BC                           ; $438C  C1
        POP AF                           ; $438D  F1
        RET                              ; $438E  C9
; [RE] Force end-of-line bookkeeping: calls SUB_6792 to clear column state, then falls into LINE_COUNT_INC to bump the printed-line counter / page check ($0B12 vs $083C).
LIST_NEWLINE_COUNT:
        CALL RESET_PRINT_STATE           ; $438F  CD 10 44
; [RE] Increments the printed-line counter ($0B12) up to the page limit ($083C); clamps at the limit and returns A=0. Drives the auto-page / line-width newline logic in OUTDO_WIDTH.
LINE_COUNT_INC:
        LD A,(SUB_0752_35)               ; $4392  3A 5F 08
        LD B,A                           ; $4395  47
        LD A,(SUB_0B2A_3)                ; $4396  3A 35 0B
        INC A                            ; $4399  3C
        CP B                             ; $439A  B8
        JR NC,LINE_COUNT_INC_1           ; $439B  30 03
        LD (SUB_0B2A_3),A                ; $439D  32 35 0B
LINE_COUNT_INC_1:
        XOR A                            ; $43A0  AF
        RET                              ; $43A1  C9
; [RE] Auto-page 'more' handler on the LIST/output path: skips when output is redirected ($0840 nonzero), tests pending key (SUB_7C0B), runs the input poll (SUB_781A) and Ctrl-C/break check ($0CA0), and on a full page pushes STMT_FOR_7 and prints the pause prompt string at $0CF2 via STROUT before resuming.
INCHR:
        PUSH HL                          ; $43A2  E5
        LD HL,(PTRFIL)                   ; $43A3  2A 63 08
        LD A,H                           ; $43A6  7C
        OR L                             ; $43A7  B5
        JR Z,INCHR_1                     ; $43A8  28 2F
        CALL GETC_FILE_EOF               ; $43AA  CD 89 58
        JP NC,FMUL_7                     ; $43AD  D2 E1 29
        PUSH BC                          ; $43B0  C5
        PUSH DE                          ; $43B1  D5
        PUSH HL                          ; $43B2  E5
        CALL LOAD_FINISH_CLOSE_CUR       ; $43B3  CD 98 54
        POP HL                           ; $43B6  E1
        POP DE                           ; $43B7  D1
        POP BC                           ; $43B8  C1
        LD A,(CHAIN_BREAK_FLAG)          ; $43B9  3A C3 0C
        OR A                             ; $43BC  B7
        JP NZ,CHAIN_COMPACT_STRINGS_2    ; $43BD  C2 BD 51
        LD A,(TXTTAB_2)                  ; $43C0  3A 6D 08
        OR A                             ; $43C3  B7
        LD HL,STMT_FOR_8                 ; $43C4  21 86 13
        EX (SP),HL                       ; $43C7  E3
        JP NZ,CLEAR_RESET_DATAPTR        ; $43C8  C2 0B 45
        EX (SP),HL                       ; $43CB  E3
        PUSH BC                          ; $43CC  C5
        PUSH DE                          ; $43CD  D5
        LD HL,MSG_BREAK                  ; $43CE  21 15 0D
        CALL STROUT                      ; $43D1  CD BE 48
        POP DE                           ; $43D4  D1
        POP BC                           ; $43D5  C1
        XOR A                            ; $43D6  AF
        POP HL                           ; $43D7  E1
        RET                              ; $43D8  C9
INCHR_1:
        POP HL                           ; $43D9  E1
; [RE] CONIN: read one console character via the BIOS console-in vector (CALL into the runtime-patched $0000 cell), mask to 7 bits, and service the Ctrl-O ($0F) output-suppress toggle ($083F). The keyboard input primitive.
CONIN:
        PUSH BC                          ; $43DA  C5
        PUSH DE                          ; $43DB  D5
        PUSH HL                          ; $43DC  E5
CONIN_1:
        CALL $0000                       ; $43DD  CD 00 00
        POP HL                           ; $43E0  E1
        POP DE                           ; $43E1  D1
        POP BC                           ; $43E2  C1
        AND $7F                          ; $43E3  E6 7F
        CP $0F                           ; $43E5  FE 0F
        RET NZ                           ; $43E7  C0
        LD A,(CTRL_O_SUPPRESS)           ; $43E8  3A 62 08
        OR A                             ; $43EB  B7
        CALL Z,ECHO_CTRL_O               ; $43EC  CC 0E 46
        CPL                              ; $43EF  2F
        LD (CTRL_O_SUPPRESS),A           ; $43F0  32 62 08
        OR A                             ; $43F3  B7
        JP Z,ECHO_CTRL_O                 ; $43F4  CA 0E 46
        XOR A                            ; $43F7  AF
        RET                              ; $43F8  C9
; [RE] If the auto-print column flag ($0B11) is nonzero, emit CR/LF (CRLF $6788); else return. Ensures output starts on a fresh line.
PRINT_CRLF_IF_COL:
        LD A,(SUB_0B2A_2)                ; $43F9  3A 34 0B
        OR A                             ; $43FC  B7
        RET Z                            ; $43FD  C8
        JP CRLF                          ; $43FE  C3 06 44
PRINT_CRLF_IF_COL_1:
        LD (HL),$00                      ; $4401  36 00
        LD HL,SUB_0925_2                 ; $4403  21 30 0A
; [RE] Output CR ($0D) + LF ($0A) to the console (via OUTCHR), then clear pending auto-line state. The print-newline routine; used by the sign-on and after each Ok prompt.
CRLF:
        LD A,$0D                         ; $4406  3E 0D
        CALL OUTCHR                      ; $4408  CD 91 42
        LD A,$0A                         ; $440B  3E 0A
        CALL OUTCHR                      ; $440D  CD 91 42
; [RE] Clear pending auto-line / print-column state ($0837 column, $0838, $0B11) after a newline; consulted via $0840 line-input-in-progress guard.
RESET_PRINT_STATE:
        PUSH HL                          ; $4410  E5
        LD HL,(PTRFIL)                   ; $4411  2A 63 08
        LD A,H                           ; $4414  7C
        OR L                             ; $4415  B5
        POP HL                           ; $4416  E1
        JR Z,RESET_PRINT_STATE_1         ; $4417  28 02
        XOR A                            ; $4419  AF
        RET                              ; $441A  C9
RESET_PRINT_STATE_1:
        LD A,(SUB_0752_32+1)             ; $441B  3A 5B 08
RESET_PRINT_STATE_2:
        OR A                             ; $441E  B7
        JR Z,RESET_PRINT_STATE_3         ; $441F  28 05
        XOR A                            ; $4421  AF
        LD (SUB_0752_32),A               ; $4422  32 5A 08
        RET                              ; $4425  C9
RESET_PRINT_STATE_3:
        XOR A                            ; $4426  AF
        LD (SUB_0B2A_2),A                ; $4427  32 34 0B
        XOR A                            ; $442A  AF
        RET                              ; $442B  C9
; [RE] RPC stub: CALL the runtime-patched 6502-bridge vector at $0000 (cell filled by cold-start from the CP/M BIOS jump table) to poll console status; returns Z per result. One of several $0000 RPC call sites the cold-start patcher fixes up.
RPC_CONST_POLL:
        PUSH BC                          ; $442C  C5
        PUSH DE                          ; $442D  D5
        PUSH HL                          ; $442E  E5
RPC_CONST_POLL_1:
        CALL $0000                       ; $442F  CD 00 00
        POP HL                           ; $4432  E1
        POP DE                           ; $4433  D1
        POP BC                           ; $4434  C1
        OR A                             ; $4435  B7
        RET Z                            ; $4436  C8
; [RE] Keyboard scan / pending-char handler (INKEY$ / Ctrl-C-Ctrl-S poll): reads a console char (SUB_675C), processes the Ctrl-S ($13) pause and Ctrl-C ($03) break ($0834 pending-key cell), and returns it. SUB_67B9_1 ($67CC) is the INKEY$ function evaluator.
INKEY_SCAN:
        CALL CONIN                       ; $4437  CD DA 43
        CP $13                           ; $443A  FE 13
        CALL Z,CONIN                     ; $443C  CC DA 43
        LD (SUB_0752_31+1),A             ; $443F  32 57 08
        CP $03                           ; $4442  FE 03
        CALL Z,ECHO_CTRL_CHAR            ; $4444  CC 10 46
INKEY_SCAN_1:
        JP STMT_STOP                     ; $4447  C3 CF 45
INKEY_SCAN_2:
        CALL CHRGET                      ; $444A  CD E4 13
        PUSH HL                          ; $444D  E5
        CALL GET_PENDING_KEY             ; $444E  CD 72 44
        JR NZ,INKEY_SCAN_4               ; $4451  20 09
INKEY_SCAN_3:
        CALL $0000                       ; $4453  CD 00 00
        OR A                             ; $4456  B7
        JR Z,INKEY_SCAN_5                ; $4457  28 0C
        CALL CONIN                       ; $4459  CD DA 43
INKEY_SCAN_4:
        PUSH AF                          ; $445C  F5
        CALL ALLOC_STR_1                 ; $445D  CD 58 48
        POP AF                           ; $4460  F1
        LD E,A                           ; $4461  5F
        CALL STR_FN_RETURN_CHAR          ; $4462  CD 89 4A
INKEY_SCAN_5:
        LD HL,SUB_0D04_5+1               ; $4465  21 14 0D
        LD (CHAIN_BREAK_FLAG_9),HL       ; $4468  22 D4 0C
        LD A,$03                         ; $446B  3E 03
        LD (SUB_0B2A_5),A                ; $446D  32 37 0B
        POP HL                           ; $4470  E1
        RET                              ; $4471  C9
; [RE] Fetch and clear the pending-key cell ($0834) set by INKEY_SCAN; returns Z if no key pending, else the key in A with the cell zeroed.
GET_PENDING_KEY:
        LD A,(SUB_0752_31+1)             ; $4472  3A 57 08
        OR A                             ; $4475  B7
        RET Z                            ; $4476  C8
        PUSH AF                          ; $4477  F5
        XOR A                            ; $4478  AF
        LD (SUB_0752_31+1),A             ; $4479  32 57 08
        POP AF                           ; $447C  F1
        RET                              ; $447D  C9
; [RE] Print a char via OUTCHR ($6613); if it was LF ($0A) also emit CR ($0D) and reset print state. Newline-expanding console write.
OUTCHR_LF_EXPAND:
        CALL OUTCHR                      ; $447E  CD 91 42
        CP $0A                           ; $4481  FE 0A
        RET NZ                           ; $4483  C0
        LD A,$0D                         ; $4484  3E 0D
        CALL OUTCHR                      ; $4486  CD 91 42
        CALL RESET_PRINT_STATE           ; $4489  CD 10 44
        LD A,$0A                         ; $448C  3E 0A
        RET                              ; $448E  C9
; [RE] After GC_CHECK_AND_COLLECT, copy a string of BC bytes downward from (HL) to (BC dest), comparing via HL/DE-compare; the string-move primitive used by string assignment.
STR_COPY_DOWN:
        CALL GC_CHECK_AND_COLLECT        ; $448F  CD C2 44
; [RE] String copy loop without the prior heap check: move bytes from (HL) to (BC) decrementing both until HL==DE (SUB_691F compare). Tail of STR_COPY_DOWN.
STR_COPY_DOWN_NOCHK:
        PUSH BC                          ; $4492  C5
        EX (SP),HL                       ; $4493  E3
        POP BC                           ; $4494  C1
STR_COPY_DOWN_NOCHK_1:
        CALL CMP_HL_DE                   ; $4495  CD 9D 45
        LD A,(HL)                        ; $4498  7E
        LD (BC),A                        ; $4499  02
        RET Z                            ; $449A  C8
        DEC BC                           ; $449B  0B
        DEC HL                           ; $449C  2B
        JR STR_COPY_DOWN_NOCHK_1         ; $449D  18 F6
; [RE] GETSTK/stack-room check: verify BC*2 bytes are available between SP and the top-of-storage pointer ($0B23); on failure fall through to SUB_6821_1 which raises 'Out of memory' (error E=$07) via the RAISE_ERROR dispatcher.
CHECK_STACK_ROOM:
        PUSH HL                          ; $449F  E5
        LD HL,(MEMSIZ)                   ; $44A0  2A 46 0B
        LD B,$00                         ; $44A3  06 00
        ADD HL,BC                        ; $44A5  09
        ADD HL,BC                        ; $44A6  09
        LD A,$C6                         ; $44A7  3E C6
        SUB L                            ; $44A9  95
        LD L,A                           ; $44AA  6F
        LD A,$FF                         ; $44AB  3E FF
        SBC A,H                          ; $44AD  9C
        JR C,CHECK_STACK_ROOM_1          ; $44AE  38 04
        LD H,A                           ; $44B0  67
        ADD HL,SP                        ; $44B1  39
        POP HL                           ; $44B2  E1
        RET C                            ; $44B3  D8
CHECK_STACK_ROOM_1:
        LD HL,(PTRFIL_2)                 ; $44B4  2A 65 08
        DEC HL                           ; $44B7  2B
        DEC HL                           ; $44B8  2B
        LD (SAVSTK),HL                   ; $44B9  22 81 0B
CHECK_STACK_ROOM_2:
        LD DE,ERR_OUT_OF_MEMORY          ; $44BC  11 07 00
        JP RAISE_ERROR                   ; $44BF  C3 AC 0D
; [RE] String free/space guard: if the requested string allocation would collide with the variable space, trigger garbage collection (SUB_6C82) and retry; if still no room raise 'Out of string space' (E=$07/$0E) via RAISE_ERROR.
GC_CHECK_AND_COLLECT:
        CALL CMP_STR_VS_VARTOP           ; $44C2  CD D5 44
        RET NC                           ; $44C5  D0
        PUSH BC                          ; $44C6  C5
        PUSH DE                          ; $44C7  D5
        PUSH HL                          ; $44C8  E5
        CALL GARBAG                      ; $44C9  CD 00 49
        POP HL                           ; $44CC  E1
        POP DE                           ; $44CD  D1
        POP BC                           ; $44CE  C1
        CALL CMP_STR_VS_VARTOP           ; $44CF  CD D5 44
        RET NC                           ; $44D2  D0
        JR CHECK_STACK_ROOM_2            ; $44D3  18 E7
; [RE] Compare a candidate string-heap address (HL) against the string/var-space top pointer ($0B48) via the 16-bit compare; returns carry if the allocation would collide. Used by GC_CHECK_AND_COLLECT.
CMP_STR_VS_VARTOP:
        PUSH DE                          ; $44D5  D5
        EX DE,HL                         ; $44D6  EB
        LD HL,(FRETOP)                   ; $44D7  2A 6B 0B
        CALL CMP_HL_DE                   ; $44DA  CD 9D 45
        EX DE,HL                         ; $44DD  EB
        POP DE                           ; $44DE  D1
        RET                              ; $44DF  C9
; [RE] RUN/CLEAR setup: zero the array of work-pointers indexed by $0870 (file/FOR slots) starting at $0850, then fall through to clear variables. Entry from the warm-start path ($81BD).
RUN_CLEAR:
        LD A,(FILTAB_4)                  ; $44E0  3A 93 08
        LD B,A                           ; $44E3  47
        LD HL,FILTAB                     ; $44E4  21 73 08
        XOR A                            ; $44E7  AF
        INC B                            ; $44E8  04
RUN_CLEAR_1:
        LD E,(HL)                        ; $44E9  5E
        INC HL                           ; $44EA  23
        LD D,(HL)                        ; $44EB  56
        INC HL                           ; $44EC  23
        LD (DE),A                        ; $44ED  12
        DJNZ RUN_CLEAR_1                 ; $44EE  10 F9
        CALL CLOSE_ALL_FILES             ; $44F0  CD 4F 55
        XOR A                            ; $44F3  AF
; [RE] NEW statement handler (token $94): erases the current program and variables.
STMT_NEW:
        RET NZ                           ; $44F4  C0
; [RE] CLEARC: reset the variable, array and string-heap pointers ($0B57/$0B56/$0B6F, top-of-string), clearing all variables. The NEW/CLEAR/RUN re-initialization of the dynamic storage map.
CLEAR_VARS:
        LD HL,(TXTTAB)                   ; $44F5  2A 69 08
        CALL STMT_TRACE+1                ; $44F8  CD 3E 46
        LD (RUNNING_PROG_FLAG),A         ; $44FB  32 BC 0C
        LD (AUTFLG),A                    ; $44FE  32 7A 0B
        LD (DATA_LINE_TXTPTR_4),A        ; $4501  32 79 0B
        LD (HL),A                        ; $4504  77
        INC HL                           ; $4505  23
        LD (HL),A                        ; $4506  77
        INC HL                           ; $4507  23
        LD (VARTAB),HL                   ; $4508  22 92 0B
; [RE] CLEAR/RUN reinit: load program start ($0846), step back, fall into the storage-map reset that re-points the variable/array/string base pointers ($0B54 etc.).
CLEAR_RESET_DATAPTR:
        LD HL,(TXTTAB)                   ; $450B  2A 69 08
        DEC HL                           ; $450E  2B
; [RE] Core CLEAR/NEW/RUN storage re-initialization: rebuilds the variable, array, FOR/file-slot, DATA and string-heap pointers, clears the math accumulator slots, resets stack and graphics state; common tail of NEW/CLEAR/RUN.
CLEAR_RESET_STORAGE:
        LD (DATA_LINE_TXTPTR_3),HL       ; $450F  22 77 0B
        LD A,(CHAIN_PRESERVE_FLAG)       ; $4512  3A BD 0C
        OR A                             ; $4515  B7
        JR NZ,CLEAR_RESET_STORAGE_3      ; $4516  20 11
        XOR A                            ; $4518  AF
        LD (SUB_0C4B_13),A               ; $4519  32 97 0C
CLEAR_RESET_STORAGE_1:
        LD (SUB_0C4B_12),A               ; $451C  32 96 0C
        LD B,$1A                         ; $451F  06 1A
        LD HL,VARTAB_4                   ; $4521  21 9A 0B
CLEAR_RESET_STORAGE_2:
        LD (HL),$04                      ; $4524  36 04
        INC HL                           ; $4526  23
        DJNZ CLEAR_RESET_STORAGE_2       ; $4527  10 FB
CLEAR_RESET_STORAGE_3:
        LD DE,POLY_EVAL_2                ; $4529  11 03 3A
        LD HL,RNDX_SEED                  ; $452C  21 A2 3A
        CALL FP_MOVE4                    ; $452F  CD 42 2B
        LD HL,FN_SQR_6                   ; $4532  21 7F 3A
        XOR A                            ; $4535  AF
        LD (HL),A                        ; $4536  77
        INC HL                           ; $4537  23
        LD (HL),A                        ; $4538  77
        INC HL                           ; $4539  23
        LD (HL),A                        ; $453A  77
        XOR A                            ; $453B  AF
        LD (ONEFLG),A                    ; $453C  32 8B 0B
        LD L,A                           ; $453F  6F
        LD H,A                           ; $4540  67
        LD (ERRLIN_2),HL                 ; $4541  22 89 0B
        LD (FRMEVL_TXTPTR_TEMP_2),HL     ; $4544  22 90 0B
        LD HL,(MEMSIZ)                   ; $4547  2A 46 0B
        LD A,(CHAIN_BREAK_FLAG)          ; $454A  3A C3 0C
        OR A                             ; $454D  B7
        JR NZ,SUB_453A_1                 ; $454E  20 03
        LD (FRETOP),HL                   ; $4550  22 6B 0B
SUB_453A_1:
        XOR A                            ; $4553  AF
        CALL STMT_RESTORE                ; $4554  CD B5 45
        LD HL,(VARTAB)                   ; $4557  2A 92 0B
        LD (VARTAB_1),HL                 ; $455A  22 94 0B
        LD (VARTAB_2),HL                 ; $455D  22 96 0B
        LD A,(CHAIN_PRESERVE_FLAG)       ; $4560  3A BD 0C
        OR A                             ; $4563  B7
        CALL Z,CLOSE_ALL_FILES           ; $4564  CC 4F 55
        POP BC                           ; $4567  C1
        LD HL,(PTRFIL_2)                 ; $4568  2A 65 08
        DEC HL                           ; $456B  2B
        DEC HL                           ; $456C  2B
        LD (SAVSTK),HL                   ; $456D  22 81 0B
        INC HL                           ; $4570  23
        INC HL                           ; $4571  23
SUB_453A_2:
        LD SP,HL                         ; $4572  F9
        LD HL,MEMSIZ_2                   ; $4573  21 4A 0B
        LD (MEMSIZ_1),HL                 ; $4576  22 48 0B
        CALL GFX_CLR_REVERSE_FLAG        ; $4579  CD 54 25
        CALL OUTDO_RESET_COL             ; $457C  CD F7 42
        CALL PRINT_RESET_STATE           ; $457F  CD 9A 18
        XOR A                            ; $4582  AF
        LD H,A                           ; $4583  67
        LD L,A                           ; $4584  6F
        LD (VARTAB_6),HL                 ; $4585  22 B6 0B
        LD (SUB_0C4B_4),A                ; $4588  32 87 0C
        LD (SUB_0C03_2),HL               ; $458B  22 1E 0C
        LD (SUB_0C4B_6),HL               ; $458E  22 8A 0C
        LD (VARTAB_5),HL                 ; $4591  22 B4 0B
        LD (DATA_LINE_TXTPTR_1),A        ; $4594  32 75 0B
        PUSH HL                          ; $4597  E5
        PUSH BC                          ; $4598  C5
SUB_453A_3:
        LD HL,(DATA_LINE_TXTPTR_3)       ; $4599  2A 77 0B
        RET                              ; $459C  C9
; MS BASIC 16-bit compare: A=H-D then (if equal) A=L-E, setting Z when HL==DE and carry per HL<DE. The pervasive pointer-compare primitive (68 call sites).
CMP_HL_DE:
        LD A,H                           ; $459D  7C
        SUB D                            ; $459E  92
        RET NZ                           ; $459F  C0
        LD A,L                           ; $45A0  7D
        SUB E                            ; $45A1  93
        RET                              ; $45A2  C9
; MS BASIC SYNCHR: verify the current char at (HL) equals the literal byte placed inline immediately after the CALL; if it matches, advance past it and CHRGET the next char; on mismatch JP to Syntax Error ($0D6F). The pervasive 'expect this token' primitive.
SYNCHR:
        LD A,(HL)                        ; $45A3  7E
        EX (SP),HL                       ; $45A4  E3
        CP (HL)                          ; $45A5  BE
        JR NZ,SYNCHR_1                   ; $45A6  20 0A
        INC HL                           ; $45A8  23
        EX (SP),HL                       ; $45A9  E3
        INC HL                           ; $45AA  23
        LD A,(HL)                        ; $45AB  7E
        CP $3A                           ; $45AC  FE 3A
        RET NC                           ; $45AE  D0
        JP CHRGOT_1                      ; $45AF  C3 E9 13
SYNCHR_1:
        JP RAISE_SYNTAX_ERROR            ; $45B2  C3 92 0D
; [RE] RESTORE statement handler (token $8C): resets the DATA read pointer (optionally to a line number).
STMT_RESTORE:
        EX DE,HL                         ; $45B5  EB
        LD HL,(TXTTAB)                   ; $45B6  2A 69 08
        JR Z,STMT_RESTORE_2              ; $45B9  28 0E
        EX DE,HL                         ; $45BB  EB
        CALL LINGET                      ; $45BC  CD FB 14
        PUSH HL                          ; $45BF  E5
        CALL FNDLIN                      ; $45C0  CD AB 0F
        LD H,B                           ; $45C3  60
        LD L,C                           ; $45C4  69
        POP DE                           ; $45C5  D1
STMT_RESTORE_1:
        JP NC,STMT_GOTO_2                ; $45C6  D2 91 15
STMT_RESTORE_2:
        DEC HL                           ; $45C9  2B
STMT_RESTORE_3:
        LD (VARTAB_3),HL                 ; $45CA  22 98 0B
        EX DE,HL                         ; $45CD  EB
        RET                              ; $45CE  C9
; [RE] STOP statement handler (token $90): break to direct mode with a Break message (shares logic with END at $6956).
STMT_STOP:
        RET NZ                           ; $45CF  C0
        INC A                            ; $45D0  3C
        JP STMT_END_1                    ; $45D1  C3 DA 45
; [RE] END statement handler (token $81). Reached via the GONE/NEWSTT statement dispatcher at $33B1 (SUB $81; RLCA; LD HL,$0108; ADD HL,BC; load handler; JP).
STMT_END:
        RET NZ                           ; $45D4  C0
        PUSH AF                          ; $45D5  F5
        CALL Z,CLOSE_ALL_FILES           ; $45D6  CC 4F 55
        POP AF                           ; $45D9  F1
STMT_END_1:
        LD (OLDTXT),HL                   ; $45DA  22 7F 0B
        LD HL,MEMSIZ_2                   ; $45DD  21 4A 0B
        LD (MEMSIZ_1),HL                 ; $45E0  22 48 0B
STMT_END_2:
        LD HL,$FFF6                      ; $45E3  21 F6 FF
        POP BC                           ; $45E6  C1
STMT_END_3:
        LD HL,(SAVTXT)                   ; $45E7  2A 67 08
        PUSH HL                          ; $45EA  E5
        PUSH AF                          ; $45EB  F5
        LD A,L                           ; $45EC  7D
        AND H                            ; $45ED  A4
        INC A                            ; $45EE  3C
        JR Z,STMT_END_4                  ; $45EF  28 09
        LD (FRMEVL_TXTPTR_TEMP_1),HL     ; $45F1  22 8E 0B
        LD HL,(OLDTXT)                   ; $45F4  2A 7F 0B
        LD (FRMEVL_TXTPTR_TEMP_2),HL     ; $45F7  22 90 0B
STMT_END_4:
        XOR A                            ; $45FA  AF
        LD (CTRL_O_SUPPRESS),A           ; $45FB  32 62 08
        CALL OUTDO_RESET_COL             ; $45FE  CD F7 42
        CALL PRINT_CRLF_IF_COL           ; $4601  CD F9 43
        POP AF                           ; $4604  F1
        LD HL,MSG_BREAK_1                ; $4605  21 1A 0D
        JP NZ,ERROR_RESUME_FROM_DIRECT   ; $4608  C2 23 0E
        JP STOP_BREAK_2+1                ; $460B  C3 45 0E
; [RE] Entry with A=$0F: echo a Ctrl-O as '^O'; falls into ECHO_CTRL_CHAR to print '^' + (ctrl+$40) then CRLF.
ECHO_CTRL_O:
        LD A,$0F                         ; $460E  3E 0F
; [RE] Echo a control character as caret notation: prints '^' ($5E) then the char+$40 via OUTCHR, then CRLF; on Ctrl-C ($03) also clears the pause/suppress flags ($0838/$083F).
ECHO_CTRL_CHAR:
        PUSH AF                          ; $4610  F5
        SUB $03                          ; $4611  D6 03
        JR NZ,ECHO_CTRL_CHAR_1           ; $4613  20 06
        LD (SUB_0752_32+1),A             ; $4615  32 5B 08
        LD (CTRL_O_SUPPRESS),A           ; $4618  32 62 08
ECHO_CTRL_CHAR_1:
        LD A,$5E                         ; $461B  3E 5E
ECHO_CTRL_CHAR_2:
        CALL OUTCHR                      ; $461D  CD 91 42
        POP AF                           ; $4620  F1
        ADD A,$40                        ; $4621  C6 40
        CALL OUTCHR                      ; $4623  CD 91 42
        JP CRLF                          ; $4626  C3 06 44
; [RE] CONT statement handler (token $98): resume a stopped program from the saved text pointer ($0B6D).
STMT_CONT:
        LD HL,(FRMEVL_TXTPTR_TEMP_2)     ; $4629  2A 90 0B
        LD A,H                           ; $462C  7C
        OR L                             ; $462D  B5
        LD DE,ERR_CANT_CONTINUE          ; $462E  11 11 00
        JP Z,RAISE_ERROR                 ; $4631  CA AC 0D
        EX DE,HL                         ; $4634  EB
        LD HL,(FRMEVL_TXTPTR_TEMP_1)     ; $4635  2A 8E 0B
        LD (SAVTXT),HL                   ; $4638  22 67 08
        EX DE,HL                         ; $463B  EB
        RET                              ; $463C  C9
; [RE] TRACE statement handler (token $9F): enable execution trace (TRON-equivalent); sets the trace flag.
STMT_TRACE:
        LD A,$AF                         ; $463D  3E AF
        LD (CHAIN_BREAK_FLAG_4),A        ; $463F  32 CE 0C
        RET                              ; $4642  C9
; [RE] SWAP statement handler (token $A1): exchange the values of two variables.
STMT_SWAP:
        CALL PTRGET_1+1                  ; $4643  CD B3 3B
        PUSH DE                          ; $4646  D5
        PUSH HL                          ; $4647  E5
        LD HL,CHAIN_BREAK_FLAG_2         ; $4648  21 C6 0C
        CALL FP_MOVE_TYPED               ; $464B  CD 47 2B
STMT_SWAP_1:
        LD HL,(VARTAB_1)                 ; $464E  2A 94 0B
        EX (SP),HL                       ; $4651  E3
        CALL FRMEVL_TEST_TYPE            ; $4652  CD E3 1D
        PUSH AF                          ; $4655  F5
        CALL SYNCHR                      ; $4656  CD A3 45
        DEFB    ','                      ; $4659  2C  inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1                  ; $465A  CD B3 3B
        POP BC                           ; $465D  C1
        CALL FRMEVL_TEST_TYPE            ; $465E  CD E3 1D
        CP B                             ; $4661  B8
        JP NZ,RAISE_TYPE_MISMATCH        ; $4662  C2 AA 0D
        EX (SP),HL                       ; $4665  E3
        EX DE,HL                         ; $4666  EB
        PUSH HL                          ; $4667  E5
        LD HL,(VARTAB_1)                 ; $4668  2A 94 0B
        CALL CMP_HL_DE                   ; $466B  CD 9D 45
        JP NZ,GETINT_POSITIVE_1          ; $466E  C2 EB 14
        POP DE                           ; $4671  D1
        POP HL                           ; $4672  E1
        EX (SP),HL                       ; $4673  E3
        PUSH DE                          ; $4674  D5
        CALL FP_MOVE_TYPED               ; $4675  CD 47 2B
        POP HL                           ; $4678  E1
        LD DE,CHAIN_BREAK_FLAG_2         ; $4679  11 C6 0C
        CALL FP_MOVE_TYPED               ; $467C  CD 47 2B
        POP HL                           ; $467F  E1
        RET                              ; $4680  C9
; [RE] ERASE statement handler (token $A2): delete a dimensioned array, freeing its storage.
STMT_ERASE:
        LD A,$01                         ; $4681  3E 01
        LD (DATA_LINE_TXTPTR_1),A        ; $4683  32 75 0B
        CALL PTRGET_1+1                  ; $4686  CD B3 3B
        JP NZ,GETINT_POSITIVE_1          ; $4689  C2 EB 14
        PUSH HL                          ; $468C  E5
        LD (DATA_LINE_TXTPTR_1),A        ; $468D  32 75 0B
        LD H,B                           ; $4690  60
        LD L,C                           ; $4691  69
        DEC BC                           ; $4692  0B
        DEC BC                           ; $4693  0B
        DEC BC                           ; $4694  0B
STMT_ERASE_1:
        LD A,(BC)                        ; $4695  0A
        DEC BC                           ; $4696  0B
        OR A                             ; $4697  B7
        JP M,STMT_ERASE_1                ; $4698  FA 95 46
        DEC BC                           ; $469B  0B
        DEC BC                           ; $469C  0B
        ADD HL,DE                        ; $469D  19
        EX DE,HL                         ; $469E  EB
        LD HL,(VARTAB_2)                 ; $469F  2A 96 0B
STMT_ERASE_2:
        CALL CMP_HL_DE                   ; $46A2  CD 9D 45
        LD A,(DE)                        ; $46A5  1A
STMT_ERASE_3:
        LD (BC),A                        ; $46A6  02
        INC DE                           ; $46A7  13
        INC BC                           ; $46A8  03
        JR NZ,STMT_ERASE_2               ; $46A9  20 F7
        DEC BC                           ; $46AB  0B
        LD H,B                           ; $46AC  60
        LD L,C                           ; $46AD  69
        LD (VARTAB_2),HL                 ; $46AE  22 96 0B
        POP HL                           ; $46B1  E1
        LD A,(HL)                        ; $46B2  7E
        CP $2C                           ; $46B3  FE 2C
        RET NZ                           ; $46B5  C0
        CALL CHRGET                      ; $46B6  CD E4 13
        JR STMT_ERASE                    ; $46B9  18 C6
STMT_ERASE_4:
        POP AF                           ; $46BB  F1
        POP HL                           ; $46BC  E1
        RET                              ; $46BD  C9
; [RE] Test (HL): set carry if the char is a letter A-Z ($41-$5A); returns carry/no-carry to classify identifier start chars.
IS_LETTER:
        LD A,(HL)                        ; $46BE  7E
; [RE] Same letter test on the char already in A: carry if A in $41-$5A, else clear (CCF after the upper-bound test).
IS_LETTER_A:
        CP $41                           ; $46BF  FE 41
        RET C                            ; $46C1  D8
        CP $5B                           ; $46C2  FE 5B
        CCF                              ; $46C4  3F
        RET                              ; $46C5  C9
; [RE] CLEAR statement handler (token $92): clears variables/strings and optionally sets memory/stack limits.
STMT_CLEAR:
        JP Z,CLEAR_RESET_STORAGE         ; $46C6  CA 0F 45
        CP $2C                           ; $46C9  FE 2C
        JR Z,STMT_CLEAR_1                ; $46CB  28 0A
        CALL GETINT_POSITIVE             ; $46CD  CD E7 14
        DEC HL                           ; $46D0  2B
        CALL CHRGET                      ; $46D1  CD E4 13
        JP Z,CLEAR_RESET_STORAGE         ; $46D4  CA 0F 45
STMT_CLEAR_1:
        CALL SYNCHR                      ; $46D7  CD A3 45
        DEFB    ','                      ; $46DA  2C  inline char arg consumed by the preceding CALL
        JP Z,CLEAR_RESET_STORAGE         ; $46DB  CA 0F 45
        EX DE,HL                         ; $46DE  EB
        LD HL,(PTRFIL_2)                 ; $46DF  2A 65 08
        EX DE,HL                         ; $46E2  EB
        CP $2C                           ; $46E3  FE 2C
        JR Z,STMT_CLEAR_2                ; $46E5  28 0E
        CALL FRMEVL_NOPAREN              ; $46E7  CD 90 1A
        PUSH HL                          ; $46EA  E5
        CALL GETADR                      ; $46EB  CD E1 22
        LD A,H                           ; $46EE  7C
        OR L                             ; $46EF  B5
        JP Z,GETINT_POSITIVE_1           ; $46F0  CA EB 14
        EX DE,HL                         ; $46F3  EB
        POP HL                           ; $46F4  E1
STMT_CLEAR_2:
        DEC HL                           ; $46F5  2B
        CALL CHRGET                      ; $46F6  CD E4 13
        PUSH DE                          ; $46F9  D5
        JR Z,STMT_CLEAR_4                ; $46FA  28 3C
        CALL SYNCHR                      ; $46FC  CD A3 45
        DEFB    ','                      ; $46FF  2C  inline char arg consumed by the preceding CALL
        JR Z,STMT_CLEAR_4                ; $4700  28 36
        CALL GETINT_POSITIVE             ; $4702  CD E7 14
        DEC HL                           ; $4705  2B
        CALL CHRGET                      ; $4706  CD E4 13
        JP NZ,RAISE_SYNTAX_ERROR         ; $4709  C2 92 0D
STMT_CLEAR_3:
        EX (SP),HL                       ; $470C  E3
        PUSH HL                          ; $470D  E5
        LD HL,$004E                      ; $470E  21 4E 00
        CALL CMP_HL_DE                   ; $4711  CD 9D 45
        JP NC,CHECK_STACK_ROOM_1         ; $4714  D2 B4 44
        POP HL                           ; $4717  E1
        CALL SUB_HL_DE                   ; $4718  CD 49 47
        JP C,CHECK_STACK_ROOM_1          ; $471B  DA B4 44
        PUSH HL                          ; $471E  E5
        LD HL,(VARTAB)                   ; $471F  2A 92 0B
        LD BC,$0014                      ; $4722  01 14 00
        ADD HL,BC                        ; $4725  09
        CALL CMP_HL_DE                   ; $4726  CD 9D 45
        JP NC,CHECK_STACK_ROOM_1         ; $4729  D2 B4 44
        EX DE,HL                         ; $472C  EB
        LD (MEMSIZ),HL                   ; $472D  22 46 0B
        POP HL                           ; $4730  E1
        LD (PTRFIL_2),HL                 ; $4731  22 65 08
        POP HL                           ; $4734  E1
        JP CLEAR_RESET_STORAGE           ; $4735  C3 0F 45
STMT_CLEAR_4:
        PUSH HL                          ; $4738  E5
        LD HL,(PTRFIL_2)                 ; $4739  2A 65 08
        EX DE,HL                         ; $473C  EB
        LD HL,(MEMSIZ)                   ; $473D  2A 46 0B
        LD A,E                           ; $4740  7B
        SUB L                            ; $4741  95
        LD E,A                           ; $4742  5F
        LD A,D                           ; $4743  7A
        SBC A,H                          ; $4744  9C
        LD D,A                           ; $4745  57
        POP HL                           ; $4746  E1
        JR STMT_CLEAR_3                  ; $4747  18 C3
; [RE] 16-bit subtract: DE = HL - DE (LD A,L/SUB E / LD A,H/SBC D), used by CLEAR to size the protected memory region.
SUB_HL_DE:
        LD A,L                           ; $4749  7D
        SUB E                            ; $474A  93
        LD E,A                           ; $474B  5F
        LD A,H                           ; $474C  7C
        SBC A,D                          ; $474D  9A
        LD D,A                           ; $474E  57
        RET                              ; $474F  C9
; [RE] NEXT statement handler (token $83): advances/closes the current FOR loop frame.
STMT_NEXT:
        PUSH AF                          ; $4750  F5
STMT_NEXT_1:
        OR $AF                           ; $4751  F6 AF
        LD (SUB_0C4B_9),A                ; $4753  32 8F 0C
        POP AF                           ; $4756  F1
        LD DE,$0000                      ; $4757  11 00 00
; [RE] Core of the NEXT statement: locate the matching FOR frame on the stack ($0CFD search), apply the STEP, compare against the limit, and either re-enter the loop (STMT_FOR_6) or fall through to loop exit; also handles 'NEXT var,var'.
NEXT_LOOP_BODY:
        LD (SUB_0C4B_8),HL               ; $475A  22 8D 0C
        CALL NZ,PTRGET_1+1               ; $475D  C4 B3 3B
        LD (DATA_LINE_TXTPTR_3),HL       ; $4760  22 77 0B
        CALL STKFRAME_SCAN_INIT          ; $4763  CD 20 0D
        JP NZ,RAISE_NEXT_WITHOUT_FOR     ; $4766  C2 98 0D
        LD SP,HL                         ; $4769  F9
        PUSH DE                          ; $476A  D5
        LD E,(HL)                        ; $476B  5E
        INC HL                           ; $476C  23
        LD D,(HL)                        ; $476D  56
        INC HL                           ; $476E  23
        PUSH HL                          ; $476F  E5
        LD HL,(SUB_0C4B_8)               ; $4770  2A 8D 0C
        CALL CMP_HL_DE                   ; $4773  CD 9D 45
        JP NZ,RAISE_NEXT_WITHOUT_FOR     ; $4776  C2 98 0D
        POP HL                           ; $4779  E1
        POP DE                           ; $477A  D1
        PUSH DE                          ; $477B  D5
        LD A,(HL)                        ; $477C  7E
        PUSH AF                          ; $477D  F5
        INC HL                           ; $477E  23
        PUSH DE                          ; $477F  D5
        LD A,(HL)                        ; $4780  7E
        INC HL                           ; $4781  23
        OR A                             ; $4782  B7
        JP M,NEXT_LOOP_BODY_2            ; $4783  FA A9 47
        CALL FP_STORE_REGS_LD            ; $4786  CD 25 2B
        EX (SP),HL                       ; $4789  E3
        PUSH HL                          ; $478A  E5
        LD A,(SUB_0C4B_9)                ; $478B  3A 8F 0C
        OR A                             ; $478E  B7
        JR NZ,NEXT_LOOP_BODY_1           ; $478F  20 07
        LD HL,SUB_0C4B_10                ; $4791  21 90 0C
        CALL FP_STORE_REGS_LD            ; $4794  CD 25 2B
        XOR A                            ; $4797  AF
NEXT_LOOP_BODY_1:
        CALL NZ,FADD_FROM_MEM            ; $4798  C4 19 28
        POP HL                           ; $479B  E1
        CALL FP_MOVE_TO_FAC              ; $479C  CD 3F 2B
        POP HL                           ; $479F  E1
        CALL FP_LOAD_MEM                 ; $47A0  CD 36 2B
        PUSH HL                          ; $47A3  E5
        CALL FCOMP                       ; $47A4  CD 81 2B
        JR NEXT_LOOP_BODY_5              ; $47A7  18 34
NEXT_LOOP_BODY_2:
        INC HL                           ; $47A9  23
        INC HL                           ; $47AA  23
        INC HL                           ; $47AB  23
        INC HL                           ; $47AC  23
        LD C,(HL)                        ; $47AD  4E
        INC HL                           ; $47AE  23
        LD B,(HL)                        ; $47AF  46
        INC HL                           ; $47B0  23
        EX (SP),HL                       ; $47B1  E3
        LD E,(HL)                        ; $47B2  5E
        INC HL                           ; $47B3  23
        LD D,(HL)                        ; $47B4  56
        PUSH HL                          ; $47B5  E5
        LD L,C                           ; $47B6  69
        LD H,B                           ; $47B7  60
        LD A,(SUB_0C4B_9)                ; $47B8  3A 8F 0C
        OR A                             ; $47BB  B7
        JR NZ,NEXT_LOOP_BODY_3           ; $47BC  20 05
        LD HL,(SUB_0C4B_10)              ; $47BE  2A 90 0C
        JR NEXT_LOOP_BODY_4              ; $47C1  18 0B
NEXT_LOOP_BODY_3:
        CALL IADD                        ; $47C3  CD A1 2D
        LD A,(SUB_0B2A_5)                ; $47C6  3A 37 0B
        CP $04                           ; $47C9  FE 04
        JP Z,RAISE_OVERFLOW              ; $47CB  CA A4 0D
NEXT_LOOP_BODY_4:
        EX DE,HL                         ; $47CE  EB
        POP HL                           ; $47CF  E1
        LD (HL),D                        ; $47D0  72
        DEC HL                           ; $47D1  2B
        LD (HL),E                        ; $47D2  73
        POP HL                           ; $47D3  E1
        PUSH DE                          ; $47D4  D5
        LD E,(HL)                        ; $47D5  5E
        INC HL                           ; $47D6  23
        LD D,(HL)                        ; $47D7  56
        INC HL                           ; $47D8  23
        EX (SP),HL                       ; $47D9  E3
        CALL INT16_COMP                  ; $47DA  CD AE 2B
NEXT_LOOP_BODY_5:
        POP HL                           ; $47DD  E1
        POP BC                           ; $47DE  C1
        SUB B                            ; $47DF  90
        CALL FP_LOAD_MEM                 ; $47E0  CD 36 2B
        JR Z,NEXT_LOOP_BODY_6            ; $47E3  28 09
        EX DE,HL                         ; $47E5  EB
        LD (SAVTXT),HL                   ; $47E6  22 67 08
        LD L,C                           ; $47E9  69
        LD H,B                           ; $47EA  60
        JP STMT_FOR_7                    ; $47EB  C3 82 13
NEXT_LOOP_BODY_6:
        LD SP,HL                         ; $47EE  F9
        LD (SAVSTK),HL                   ; $47EF  22 81 0B
        LD HL,(DATA_LINE_TXTPTR_3)       ; $47F2  2A 77 0B
        LD A,(HL)                        ; $47F5  7E
        CP $2C                           ; $47F6  FE 2C
        JP NZ,STMT_FOR_8                 ; $47F8  C2 86 13
        CALL CHRGET                      ; $47FB  CD E4 13
        CALL NEXT_LOOP_BODY              ; $47FE  CD 5A 47
NEXT_LOOP_BODY_7:
        CALL FRETMP                      ; $4801  CD 37 4A
        LD A,(HL)                        ; $4804  7E
        INC HL                           ; $4805  23
        LD C,(HL)                        ; $4806  4E
        INC HL                           ; $4807  23
        LD B,(HL)                        ; $4808  46
        POP DE                           ; $4809  D1
        PUSH BC                          ; $480A  C5
        PUSH AF                          ; $480B  F5
        CALL FRESTR1                     ; $480C  CD 3E 4A
        POP DE                           ; $480F  D1
        LD E,(HL)                        ; $4810  5E
        INC HL                           ; $4811  23
        LD C,(HL)                        ; $4812  4E
        INC HL                           ; $4813  23
        LD B,(HL)                        ; $4814  46
        POP HL                           ; $4815  E1
NEXT_LOOP_BODY_8:
        LD A,E                           ; $4816  7B
        OR D                             ; $4817  B2
        RET Z                            ; $4818  C8
        LD A,D                           ; $4819  7A
        SUB $01                          ; $481A  D6 01
        RET C                            ; $481C  D8
        XOR A                            ; $481D  AF
        CP E                             ; $481E  BB
        INC A                            ; $481F  3C
        RET NC                           ; $4820  D0
        DEC D                            ; $4821  15
        DEC E                            ; $4822  1D
        LD A,(BC)                        ; $4823  0A
        INC BC                           ; $4824  03
        CP (HL)                          ; $4825  BE
        INC HL                           ; $4826  23
        JR Z,NEXT_LOOP_BODY_8            ; $4827  28 ED
        CCF                              ; $4829  3F
        JP FP_SIGN_3                     ; $482A  C3 D0 2A
; [RE] SPACE$() handler (function token $17): string of n spaces.
FN_SPACE_STR:
        CALL POW10_INT_TABLE_1+2         ; $482D  CD BC 38
        JR STR_FN_FINALIZE_1             ; $4830  18 08
; [RE] OCT$() handler (function token $18): octal-string conversion.
FN_OCT_STR:
        CALL POW10_INT_TABLE_2+1         ; $4832  CD BF 38
        JR STR_FN_FINALIZE_1             ; $4835  18 03
; [RE] Finalize a string-returning function result: scan the formed string (SUB_6BEA), build its descriptor and stage it as the string temporary returned through SUB_6E0B.
STR_FN_FINALIZE:
        CALL FOUT_2                      ; $4837  CD A0 33
STR_FN_FINALIZE_1:
        CALL SCAN_STR_LITERAL            ; $483A  CD 68 48
        CALL FRESTR                      ; $483D  CD 3A 4A
        LD BC,STR_FN_RETURN_CHAR_1       ; $4840  01 8D 4A
        PUSH BC                          ; $4843  C5
; [RE] Build/allocate a string body from a descriptor: for the byte at (HL) call GETSPA to reserve space, copy via SUB_6DB0, returning the new descriptor; used by string concatenation/formatting.
STR_BUILD_FROM_DESC:
        LD A,(HL)                        ; $4844  7E
        INC HL                           ; $4845  23
        PUSH HL                          ; $4846  E5
        CALL GETSPA                      ; $4847  CD D6 48
        POP HL                           ; $484A  E1
        LD C,(HL)                        ; $484B  4E
        INC HL                           ; $484C  23
        LD B,(HL)                        ; $484D  46
        CALL STORE_STR_DESC              ; $484E  CD 5D 48
        PUSH HL                          ; $4851  E5
        LD L,A                           ; $4852  6F
        CALL BLOCK_COPY_BC_TO_DE         ; $4853  CD 2E 4A
        POP DE                           ; $4856  D1
        RET                              ; $4857  C9
; [RE] Allocate a 1-byte string (A=1) then build its descriptor; convenience entry into the descriptor builder for single-char string results (e.g. CHR$, INKEY$).
ALLOC_STR_1:
        LD A,$01                         ; $4858  3E 01
; [RE] Allocate an A-byte string via GETSPA, then fall into STORE_STR_DESC to record length/pointer.
ALLOC_STR_A:
        CALL GETSPA                      ; $485A  CD D6 48
; [RE] Store a string descriptor (length A, body pointer DE) into the temporary descriptor cell $0B45..$0B47 and return HL pointing at it.
STORE_STR_DESC:
        LD HL,MEMSIZ_4                   ; $485D  21 68 0B
; Store-string-descriptor core with HL pre-loaded to the target descriptor cell: writes length A and body pointer DE at (HL), returns HL. STORE_STR_DESC ($485D) enters here with HL = temp-descriptor $0B68; also CALLed directly ($1006). Was SUB_4860. [RE]
STORE_STR_DESC_AT_HL:
        PUSH HL                          ; $4860  E5
        LD (HL),A                        ; $4861  77
        INC HL                           ; $4862  23
        LD (HL),E                        ; $4863  73
        INC HL                           ; $4864  23
        LD (HL),D                        ; $4865  72
        POP HL                           ; $4866  E1
        RET                              ; $4867  C9
; [RE] Scan a quoted/argument string starting before (HL): default terminator '"' ($22); measures length to the closing quote/NUL and forms a descriptor. PRINT/string-constant scanner (call sites in CRUNCH/FRMEVL/PRINT).
SCAN_STR_LITERAL:
        DEC HL                           ; $4868  2B
; [RE] Entry with B set to the open-quote terminator $22; sets D=B and scans the string body.
SCAN_STR_QUOTE:
        LD B,$22                         ; $4869  06 22
; [RE] Entry with the terminator byte preset in B; copies to D and scans to that terminator or NUL.
SCAN_STR_TERM:
        LD D,B                           ; $486B  50
; [RE] String-scan inner loop: walk (HL) counting chars in C until a NUL, the B-terminator or D-terminator; trims trailing spaces after a comma terminator and stores the resulting descriptor (length C).
SCAN_STR_BODY:
        PUSH HL                          ; $486C  E5
        LD C,$FF                         ; $486D  0E FF
SCAN_STR_BODY_1:
        INC HL                           ; $486F  23
        LD A,(HL)                        ; $4870  7E
        INC C                            ; $4871  0C
        OR A                             ; $4872  B7
        JR Z,SCAN_STR_BODY_2             ; $4873  28 06
        CP D                             ; $4875  BA
        JR Z,SCAN_STR_BODY_2             ; $4876  28 03
        CP B                             ; $4878  B8
        JR NZ,SCAN_STR_BODY_1            ; $4879  20 F4
SCAN_STR_BODY_2:
        CP $22                           ; $487B  FE 22
        CALL Z,CHRGET                    ; $487D  CC E4 13
        PUSH HL                          ; $4880  E5
        LD A,B                           ; $4881  78
        CP $2C                           ; $4882  FE 2C
        JR NZ,SCAN_STR_BODY_4            ; $4884  20 0A
        INC C                            ; $4886  0C
SCAN_STR_BODY_3:
        DEC C                            ; $4887  0D
        JR Z,SCAN_STR_BODY_4             ; $4888  28 06
        DEC HL                           ; $488A  2B
        LD A,(HL)                        ; $488B  7E
        CP $20                           ; $488C  FE 20
        JR Z,SCAN_STR_BODY_3             ; $488E  28 F7
SCAN_STR_BODY_4:
        POP HL                           ; $4890  E1
        EX (SP),HL                       ; $4891  E3
        INC HL                           ; $4892  23
        EX DE,HL                         ; $4893  EB
        LD A,C                           ; $4894  79
        CALL STORE_STR_DESC              ; $4895  CD 5D 48
; [RE] Place a string descriptor into the rotating string-temporary table (pointer $0B25, base $0B48): records type=string ($0B14=3), stores the descriptor and advances the temp pointer; on overflow raises 'String formula too complex' (E=$10 via RAISE_ERROR). Widely used to stage string FRMEVL results.
PUT_STR_TEMP:
        LD DE,MEMSIZ_4                   ; $4898  11 68 0B
PUT_STR_TEMP_1:
        LD A,$D5                         ; $489B  3E D5
        LD HL,(MEMSIZ_1)                 ; $489D  2A 48 0B
        LD (CHAIN_BREAK_FLAG_9),HL       ; $48A0  22 D4 0C
        LD A,$03                         ; $48A3  3E 03
        LD (SUB_0B2A_5),A                ; $48A5  32 37 0B
        CALL FP_MOVE_TYPED               ; $48A8  CD 47 2B
        LD DE,FRETOP                     ; $48AB  11 6B 0B
        CALL CMP_HL_DE                   ; $48AE  CD 9D 45
        LD (MEMSIZ_1),HL                 ; $48B1  22 48 0B
        POP HL                           ; $48B4  E1
        LD A,(HL)                        ; $48B5  7E
        RET NZ                           ; $48B6  C0
        LD DE,ERR_STRING_FORMULA_TOO_COMPLEX  ; $48B7  11 10 00
        JP RAISE_ERROR                   ; $48BA  C3 AC 0D
PUT_STR_TEMP_2:
        INC HL                           ; $48BD  23
; [RE] STROUT/print-message: print the NUL-terminated string at (HL) (or counted string) to the console one char at a time via OUTCHR ($6613), translating CR. Used for the sign-on banner and error messages.
STROUT:
        CALL SCAN_STR_LITERAL            ; $48BE  CD 68 48
; [RE] Print a string VALUE: free the temp descriptor (FRESTR), load its address->BC and length->D (FP_LOAD_MEM3), then output D bytes via OUTCHR, resetting print state on CR. Entry past STROUT's literal scan; used by PRINT/LPRINT/INPUT-prompt ($37C4/$3927/$65EF/$75B4/$75D6)
STRPRT:
        CALL FRESTR                      ; $48C1  CD 3A 4A
        CALL FP_LOAD_MEM3                ; $48C4  CD 38 2B
        INC D                            ; $48C7  14
STRPRT_1:
        DEC D                            ; $48C8  15
        RET Z                            ; $48C9  C8
        LD A,(BC)                        ; $48CA  0A
        CALL OUTCHR                      ; $48CB  CD 91 42
        CP $0D                           ; $48CE  FE 0D
        CALL Z,RESET_PRINT_STATE         ; $48D0  CC 10 44
        INC BC                           ; $48D3  03
        JR STRPRT_1                      ; $48D4  18 F2
; [RE] String-space allocator (GETSPA): reserve A bytes at the top of the string heap (top-of-string pointer $0B48, string area base $0B73), invoking garbage collection on exhaustion; raises 'Out of string space' (E=$0E).
GETSPA:
        OR A                             ; $48D6  B7
GETSPA_1:
        LD C,$F1                         ; $48D7  0E F1
        PUSH AF                          ; $48D9  F5
        LD HL,(VARTAB_2)                 ; $48DA  2A 96 0B
        EX DE,HL                         ; $48DD  EB
        LD HL,(FRETOP)                   ; $48DE  2A 6B 0B
        CPL                              ; $48E1  2F
        LD C,A                           ; $48E2  4F
        LD B,$FF                         ; $48E3  06 FF
        ADD HL,BC                        ; $48E5  09
        INC HL                           ; $48E6  23
        CALL CMP_HL_DE                   ; $48E7  CD 9D 45
        JR C,GETSPA_3                    ; $48EA  38 07
        LD (FRETOP),HL                   ; $48EC  22 6B 0B
        INC HL                           ; $48EF  23
        EX DE,HL                         ; $48F0  EB
GETSPA_2:
        POP AF                           ; $48F1  F1
        RET                              ; $48F2  C9
GETSPA_3:
        POP AF                           ; $48F3  F1
        LD DE,ERR_OUT_OF_STRING_SPACE    ; $48F4  11 0E 00
        JP Z,RAISE_ERROR                 ; $48F7  CA AC 0D
        CP A                             ; $48FA  BF
        PUSH AF                          ; $48FB  F5
        LD BC,GETSPA_1+1                 ; $48FC  01 D8 48
        PUSH BC                          ; $48FF  C5
; MS BASIC-80 GARBAG: garbage-collect / compact the string heap. Scans simple string variables, string arrays and string temporaries (pointers $0B23/$0B73/$0B27/$0B25) to find the highest still-referenced string and slide live strings up, reclaiming free space. Called by GETSPA when the heap is full.
GARBAG:
        LD HL,(MEMSIZ)                   ; $4900  2A 46 0B
GARBAG_1:
        LD (FRETOP),HL                   ; $4903  22 6B 0B
        LD HL,$0000                      ; $4906  21 00 00
        PUSH HL                          ; $4909  E5
        LD HL,(VARTAB_2)                 ; $490A  2A 96 0B
        PUSH HL                          ; $490D  E5
        LD HL,MEMSIZ_2                   ; $490E  21 4A 0B
GARBAG_2:
        EX DE,HL                         ; $4911  EB
        LD HL,(MEMSIZ_1)                 ; $4912  2A 48 0B
        EX DE,HL                         ; $4915  EB
        CALL CMP_HL_DE                   ; $4916  CD 9D 45
        LD BC,GARBAG_2                   ; $4919  01 11 49
        JP NZ,SUB_494C_5                 ; $491C  C2 A5 49
        LD HL,SUB_0C03_1                 ; $491F  21 1C 0C
        LD (SUB_0C4B_5),HL               ; $4922  22 88 0C
        LD HL,(VARTAB_1)                 ; $4925  2A 94 0B
        LD (SUB_0C4B_2),HL               ; $4928  22 85 0C
        LD HL,(VARTAB)                   ; $492B  2A 92 0B
GARBAG_3:
        EX DE,HL                         ; $492E  EB
        LD HL,(SUB_0C4B_2)               ; $492F  2A 85 0C
        EX DE,HL                         ; $4932  EB
        CALL CMP_HL_DE                   ; $4933  CD 9D 45
        JR Z,SUB_494C_1                  ; $4936  28 17
        LD A,(HL)                        ; $4938  7E
        INC HL                           ; $4939  23
        INC HL                           ; $493A  23
        INC HL                           ; $493B  23
        PUSH AF                          ; $493C  F5
        CALL VARTAB_SKIP_ENTRY           ; $493D  CD A3 3E
        POP AF                           ; $4940  F1
        CP $03                           ; $4941  FE 03
        JR NZ,GARBAG_4                   ; $4943  20 04
        CALL GARBAG_FIX_STR_PTR          ; $4945  CD A6 49
        XOR A                            ; $4948  AF
GARBAG_4:
        LD E,A                           ; $4949  5F
        LD D,$00                         ; $494A  16 00
        ADD HL,DE                        ; $494C  19
        JR GARBAG_3                      ; $494D  18 DF
SUB_494C_1:
        LD HL,(SUB_0C4B_5)               ; $494F  2A 88 0C
        LD A,(HL)                        ; $4952  7E
        INC HL                           ; $4953  23
        LD H,(HL)                        ; $4954  66
        LD L,A                           ; $4955  6F
        OR H                             ; $4956  B4
        EX DE,HL                         ; $4957  EB
        LD HL,(VARTAB_1)                 ; $4958  2A 94 0B
        JR Z,SUB_494C_3                  ; $495B  28 13
        EX DE,HL                         ; $495D  EB
        LD (SUB_0C4B_5),HL               ; $495E  22 88 0C
        INC HL                           ; $4961  23
        INC HL                           ; $4962  23
        LD E,(HL)                        ; $4963  5E
        INC HL                           ; $4964  23
        LD D,(HL)                        ; $4965  56
        INC HL                           ; $4966  23
        EX DE,HL                         ; $4967  EB
        ADD HL,DE                        ; $4968  19
        LD (SUB_0C4B_2),HL               ; $4969  22 85 0C
        EX DE,HL                         ; $496C  EB
        JR GARBAG_3                      ; $496D  18 BF
SUB_494C_2:
        POP BC                           ; $496F  C1
SUB_494C_3:
        EX DE,HL                         ; $4970  EB
        LD HL,(VARTAB_2)                 ; $4971  2A 96 0B
        EX DE,HL                         ; $4974  EB
        CALL CMP_HL_DE                   ; $4975  CD 9D 45
        JP Z,GARBAG_FIX_STR_PTR_1        ; $4978  CA CA 49
        LD A,(HL)                        ; $497B  7E
        INC HL                           ; $497C  23
        PUSH AF                          ; $497D  F5
        INC HL                           ; $497E  23
        INC HL                           ; $497F  23
        CALL VARTAB_SKIP_ENTRY           ; $4980  CD A3 3E
        LD C,(HL)                        ; $4983  4E
        INC HL                           ; $4984  23
        LD B,(HL)                        ; $4985  46
        INC HL                           ; $4986  23
        POP AF                           ; $4987  F1
        PUSH HL                          ; $4988  E5
        ADD HL,BC                        ; $4989  09
        CP $03                           ; $498A  FE 03
        JR NZ,SUB_494C_2                 ; $498C  20 E1
        LD (FRETOP_2),HL                 ; $498E  22 6F 0B
        POP HL                           ; $4991  E1
        LD C,(HL)                        ; $4992  4E
        LD B,$00                         ; $4993  06 00
        ADD HL,BC                        ; $4995  09
        ADD HL,BC                        ; $4996  09
        INC HL                           ; $4997  23
SUB_494C_4:
        EX DE,HL                         ; $4998  EB
        LD HL,(FRETOP_2)                 ; $4999  2A 6F 0B
        EX DE,HL                         ; $499C  EB
        CALL CMP_HL_DE                   ; $499D  CD 9D 45
        JR Z,SUB_494C_3                  ; $49A0  28 CE
        LD BC,SUB_494C_4                 ; $49A2  01 98 49
SUB_494C_5:
        PUSH BC                          ; $49A5  C5
; [RE] GARBAG helper: scan a string descriptor (length+ptr at HL) and, if the string lives below the current collection watermark ($0B48), record it as the new candidate highest free-able block; advances HL past the descriptor.
GARBAG_FIX_STR_PTR:
        XOR A                            ; $49A6  AF
        OR (HL)                          ; $49A7  B6
        INC HL                           ; $49A8  23
        LD E,(HL)                        ; $49A9  5E
        INC HL                           ; $49AA  23
        LD D,(HL)                        ; $49AB  56
        INC HL                           ; $49AC  23
        RET Z                            ; $49AD  C8
        LD B,H                           ; $49AE  44
        LD C,L                           ; $49AF  4D
        LD HL,(FRETOP)                   ; $49B0  2A 6B 0B
        CALL CMP_HL_DE                   ; $49B3  CD 9D 45
        LD H,B                           ; $49B6  60
        LD L,C                           ; $49B7  69
        RET C                            ; $49B8  D8
        POP HL                           ; $49B9  E1
        EX (SP),HL                       ; $49BA  E3
        CALL CMP_HL_DE                   ; $49BB  CD 9D 45
        EX (SP),HL                       ; $49BE  E3
        PUSH HL                          ; $49BF  E5
        LD H,B                           ; $49C0  60
        LD L,C                           ; $49C1  69
        RET NC                           ; $49C2  D0
        POP BC                           ; $49C3  C1
        POP AF                           ; $49C4  F1
        POP AF                           ; $49C5  F1
        PUSH HL                          ; $49C6  E5
        PUSH DE                          ; $49C7  D5
        PUSH BC                          ; $49C8  C5
        RET                              ; $49C9  C9
GARBAG_FIX_STR_PTR_1:
        POP DE                           ; $49CA  D1
        POP HL                           ; $49CB  E1
        LD A,L                           ; $49CC  7D
        OR H                             ; $49CD  B4
        RET Z                            ; $49CE  C8
        DEC HL                           ; $49CF  2B
        LD B,(HL)                        ; $49D0  46
        DEC HL                           ; $49D1  2B
        LD C,(HL)                        ; $49D2  4E
        PUSH HL                          ; $49D3  E5
        DEC HL                           ; $49D4  2B
        LD L,(HL)                        ; $49D5  6E
        LD H,$00                         ; $49D6  26 00
        ADD HL,BC                        ; $49D8  09
        LD D,B                           ; $49D9  50
        LD E,C                           ; $49DA  59
        DEC HL                           ; $49DB  2B
        LD B,H                           ; $49DC  44
        LD C,L                           ; $49DD  4D
        LD HL,(FRETOP)                   ; $49DE  2A 6B 0B
        CALL STR_COPY_DOWN_NOCHK         ; $49E1  CD 92 44
        POP HL                           ; $49E4  E1
        LD (HL),C                        ; $49E5  71
        INC HL                           ; $49E6  23
        LD (HL),B                        ; $49E7  70
        LD L,C                           ; $49E8  69
        LD H,B                           ; $49E9  60
        DEC HL                           ; $49EA  2B
        JP GARBAG_1                      ; $49EB  C3 03 49
; [RE] FRESTR/movestring helper: pull a string's descriptor (via FRMEVL_EVAL_OPERAND), free its data with SUB_6DC0, then copy the bytes into freshly-allocated string space (SUB_6DA8 block copies); returns through FRMEVL fixup.
STR_CONCAT:
        PUSH BC                          ; $49EE  C5
        PUSH HL                          ; $49EF  E5
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $49F0  2A D4 0C
        EX (SP),HL                       ; $49F3  E3
        CALL FRMEVL_EVAL_OPERAND         ; $49F4  CD 11 1C
        EX (SP),HL                       ; $49F7  E3
        CALL FP_INT_CHECK                ; $49F8  CD B3 2C
        LD A,(HL)                        ; $49FB  7E
        PUSH HL                          ; $49FC  E5
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $49FD  2A D4 0C
        PUSH HL                          ; $4A00  E5
        ADD A,(HL)                       ; $4A01  86
        LD DE,ERR_STRING_TOO_LONG        ; $4A02  11 0F 00
        JP C,RAISE_ERROR                 ; $4A05  DA AC 0D
        CALL ALLOC_STR_A                 ; $4A08  CD 5A 48
        POP DE                           ; $4A0B  D1
        CALL FRESTR1                     ; $4A0C  CD 3E 4A
        EX (SP),HL                       ; $4A0F  E3
        CALL FRESTR_DE                   ; $4A10  CD 3D 4A
        PUSH HL                          ; $4A13  E5
        LD HL,(MEMSIZ_5)                 ; $4A14  2A 69 0B
        EX DE,HL                         ; $4A17  EB
        CALL STR_COPY_DESCR_DATA         ; $4A18  CD 26 4A
        CALL STR_COPY_DESCR_DATA         ; $4A1B  CD 26 4A
        LD HL,FRMEVL_OPLOOP_1            ; $4A1E  21 A0 1A
        EX (SP),HL                       ; $4A21  E3
        PUSH HL                          ; $4A22  E5
        JP PUT_STR_TEMP                  ; $4A23  C3 98 48
; [RE] copy one string-descriptor's data: pops the descriptor (len in A, addr in BC) off the caller's stack and block-copies len bytes from (BC) to (DE) via SUB_6DB0.
STR_COPY_DESCR_DATA:
        POP HL                           ; $4A26  E1
        EX (SP),HL                       ; $4A27  E3
        LD A,(HL)                        ; $4A28  7E
        INC HL                           ; $4A29  23
        LD C,(HL)                        ; $4A2A  4E
        INC HL                           ; $4A2B  23
        LD B,(HL)                        ; $4A2C  46
        LD L,A                           ; $4A2D  6F
; [RE] copy A (=L) bytes from (BC) to (DE), ascending; INC L / DEC L sets the counter, RET Z when done. Generic ascending memory move.
BLOCK_COPY_BC_TO_DE:
        INC L                            ; $4A2E  2C
BLOCK_COPY_BC_TO_DE_1:
        DEC L                            ; $4A2F  2D
        RET Z                            ; $4A30  C8
        LD A,(BC)                        ; $4A31  0A
        LD (DE),A                        ; $4A32  12
        INC BC                           ; $4A33  03
        INC DE                           ; $4A34  13
        JR BLOCK_COPY_BC_TO_DE_1         ; $4A35  18 F8
; MS BASIC-80 FRETMP: free the most-recent temporary string descriptor (CALL FREFAC at $5035), then fall into FRESTR to reclaim its heap bytes if it was the topmost allocation.
FRETMP:
        CALL FP_INT_CHECK                ; $4A37  CD B3 2C
; MS BASIC-80 FRESTR: free the string whose descriptor pointer is in FAC ($0CB1); loads the descriptor then frees its data via FRESTR1 (SUB_6DC0).
FRESTR:
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $4A3A  2A D4 0C
; MS BASIC-80 FRESTR entry with descriptor address already in HL: EX DE,HL then free.
FRESTR_DE:
        EX DE,HL                         ; $4A3D  EB
; MS BASIC-80 FRESTR1: if the descriptor points at the topmost string-heap allocation, hand its bytes back by advancing the top-of-free-string pointer ($0B48); otherwise leave the heap unchanged.
FRESTR1:
        CALL FREE_TOP_TEMP_DESCR         ; $4A3E  CD 57 4A
        EX DE,HL                         ; $4A41  EB
        RET NZ                           ; $4A42  C0
        PUSH DE                          ; $4A43  D5
        LD D,B                           ; $4A44  50
        LD E,C                           ; $4A45  59
        DEC DE                           ; $4A46  1B
        LD C,(HL)                        ; $4A47  4E
        LD HL,(FRETOP)                   ; $4A48  2A 6B 0B
        CALL CMP_HL_DE                   ; $4A4B  CD 9D 45
        JR NZ,FRESTR1_1                  ; $4A4E  20 05
        LD B,A                           ; $4A50  47
        ADD HL,BC                        ; $4A51  09
        LD (FRETOP),HL                   ; $4A52  22 6B 0B
FRESTR1_1:
        POP HL                           ; $4A55  E1
        RET                              ; $4A56  C9
; [RE] pop the most-recently-pushed temporary string descriptor off the temp-descriptor stack ($0B25): if HL matches, retract the temp pointer by one descriptor and clear Z.
FREE_TOP_TEMP_DESCR:
        LD HL,(MEMSIZ_1)                 ; $4A57  2A 48 0B
        DEC HL                           ; $4A5A  2B
        LD B,(HL)                        ; $4A5B  46
        DEC HL                           ; $4A5C  2B
        LD C,(HL)                        ; $4A5D  4E
        DEC HL                           ; $4A5E  2B
        CALL CMP_HL_DE                   ; $4A5F  CD 9D 45
        RET NZ                           ; $4A62  C0
        LD (MEMSIZ_1),HL                 ; $4A63  22 48 0B
        RET                              ; $4A66  C9
; [RE] POS() handler (function token $10): current console column (LD BC,$3E32 = return-integer helper).
FN_POS:
        LD BC,FP_LOAD_INT_TO_FAC         ; $4A67  01 4D 1E
        PUSH BC                          ; $4A6A  C5
; [RE] evaluate the pending string argument to a descriptor (via FRETMP), returning the descriptor's length in A and address in HL; Z set if the string is empty.
GET_STR_DESCR_PTR:
        CALL FRETMP                      ; $4A6B  CD 37 4A
        XOR A                            ; $4A6E  AF
        LD D,A                           ; $4A6F  57
        LD A,(HL)                        ; $4A70  7E
        OR A                             ; $4A71  B7
        RET                              ; $4A72  C9
; [RE] VAL() handler (function token $13): numeric value of a string (FIN).
FN_VAL:
        LD BC,FP_LOAD_INT_TO_FAC         ; $4A73  01 4D 1E
        PUSH BC                          ; $4A76  C5
; [RE] VAL() body: fetch the string descriptor, error if empty, then load the string's text pointer (DE) and first byte (A) for numeric parsing (FIN).
FN_VAL_BODY:
        CALL GET_STR_DESCR_PTR           ; $4A77  CD 6B 4A
        JP Z,GETINT_POSITIVE_1           ; $4A7A  CA EB 14
        INC HL                           ; $4A7D  23
        LD E,(HL)                        ; $4A7E  5E
        INC HL                           ; $4A7F  23
        LD D,(HL)                        ; $4A80  56
        LD A,(DE)                        ; $4A81  1A
        RET                              ; $4A82  C9
; [RE] ASC() handler (function token $14): character code of a string's first byte.
FN_ASC:
        CALL ALLOC_STR_1                 ; $4A83  CD 58 48
        CALL CONINT                      ; $4A86  CD B5 20
; [RE] string-function epilogue: store result char (E) into the string work buffer at ($0B46) and return through SUB_6C1A (FRMEVL string-temp fixup).
STR_FN_RETURN_CHAR:
        LD HL,(MEMSIZ_5)                 ; $4A89  2A 69 0B
        LD (HL),E                        ; $4A8C  73
STR_FN_RETURN_CHAR_1:
        POP BC                           ; $4A8D  C1
        JP PUT_STR_TEMP                  ; $4A8E  C3 98 48
; [RE] MID$() function body (token $E7): parse '(' source$ ',' start [ ',' len ] ')', then drop into the LEFT$/RIGHT$/MID$ common copy path.
FN_STRING_STR:
        CALL CHRGET                      ; $4A91  CD E4 13
        CALL SYNCHR                      ; $4A94  CD A3 45
        DEFB    '('                      ; $4A97  28  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $4A98  CD B2 20
        PUSH DE                          ; $4A9B  D5
        CALL SYNCHR                      ; $4A9C  CD A3 45
        DEFB    ','                      ; $4A9F  2C  inline char arg consumed by the preceding CALL
        CALL FRMEVL_NOPAREN              ; $4AA0  CD 90 1A
        CALL SYNCHR                      ; $4AA3  CD A3 45
        DEFB    ')'                      ; $4AA6  29  inline char arg consumed by the preceding CALL
        EX (SP),HL                       ; $4AA7  E3
        PUSH HL                          ; $4AA8  E5
        CALL FRMEVL_TEST_TYPE            ; $4AA9  CD E3 1D
        JR Z,FN_STRING_STR_1             ; $4AAC  28 05
        CALL CONINT                      ; $4AAE  CD B5 20
        JR FN_STRING_STR_2               ; $4AB1  18 03
FN_STRING_STR_1:
        CALL FN_VAL_BODY                 ; $4AB3  CD 77 4A
FN_STRING_STR_2:
        POP DE                           ; $4AB6  D1
        CALL STR_FILL_ALLOC              ; $4AB7  CD BF 4A
; [RE] PEEK() handler (function token $16): read a memory byte (CALL $409A evaluates the address).
FN_PEEK:
        CALL CONINT                      ; $4ABA  CD B5 20
        LD A,$20                         ; $4ABD  3E 20
; [RE] STRING$/SPACE$ build helper: allocate B bytes of string space, fill with the pad char in A, returning the new descriptor; entry from the function epilogue at SUB_6E0B.
STR_FILL_ALLOC:
        PUSH AF                          ; $4ABF  F5
        LD A,E                           ; $4AC0  7B
        CALL ALLOC_STR_A                 ; $4AC1  CD 5A 48
        LD B,A                           ; $4AC4  47
        POP AF                           ; $4AC5  F1
        INC B                            ; $4AC6  04
        DEC B                            ; $4AC7  05
        JR Z,STR_FN_RETURN_CHAR_1        ; $4AC8  28 C3
        LD HL,(MEMSIZ_5)                 ; $4ACA  2A 69 0B
; [RE] fill loop: write fill char A into B successive bytes of the freshly allocated string buffer at ($0B46).
STR_FILL_LOOP:
        LD (HL),A                        ; $4ACD  77
        INC HL                           ; $4ACE  23
        DJNZ STR_FILL_LOOP               ; $4ACF  10 FC
        JR STR_FN_RETURN_CHAR_1          ; $4AD1  18 BA
; [RE] LEFT$/RIGHT$/MID$ common tail: parse the length byte, clamp it to the source length, allocate a new string of that size and copy the selected substring into it; returns via FRMEVL string-temp fixup.
STR_SUBSTR_ALLOC_COPY:
        CALL PARSE_BYTE_ARG              ; $4AD3  CD 4A 4B
        XOR A                            ; $4AD6  AF
STR_SUBSTR_ALLOC_COPY_1:
        EX (SP),HL                       ; $4AD7  E3
        LD C,A                           ; $4AD8  4F
STR_SUBSTR_ALLOC_COPY_2:
        LD A,$E5                         ; $4AD9  3E E5
STR_SUBSTR_ALLOC_COPY_3:
        PUSH HL                          ; $4ADB  E5
        LD A,(HL)                        ; $4ADC  7E
        CP B                             ; $4ADD  B8
        JR C,STR_SUBSTR_ALLOC_COPY_4+1   ; $4ADE  38 02
        LD A,B                           ; $4AE0  78
STR_SUBSTR_ALLOC_COPY_4:
        LD DE,$000E                      ; $4AE1  11 0E 00
        PUSH BC                          ; $4AE4  C5
        CALL GETSPA                      ; $4AE5  CD D6 48
        POP BC                           ; $4AE8  C1
        POP HL                           ; $4AE9  E1
        PUSH HL                          ; $4AEA  E5
        INC HL                           ; $4AEB  23
        LD B,(HL)                        ; $4AEC  46
        INC HL                           ; $4AED  23
        LD H,(HL)                        ; $4AEE  66
        LD L,B                           ; $4AEF  68
        LD B,$00                         ; $4AF0  06 00
        ADD HL,BC                        ; $4AF2  09
        LD B,H                           ; $4AF3  44
        LD C,L                           ; $4AF4  4D
        CALL STORE_STR_DESC              ; $4AF5  CD 5D 48
        LD L,A                           ; $4AF8  6F
        CALL BLOCK_COPY_BC_TO_DE         ; $4AF9  CD 2E 4A
        POP DE                           ; $4AFC  D1
        CALL FRESTR1                     ; $4AFD  CD 3E 4A
        JP PUT_STR_TEMP                  ; $4B00  C3 98 48
; [RE] LEFT$() handler (function token $01): leftmost n chars of a string.
FN_LEFT_STR:
        CALL PARSE_BYTE_ARG              ; $4B03  CD 4A 4B
        POP DE                           ; $4B06  D1
        PUSH DE                          ; $4B07  D5
        LD A,(DE)                        ; $4B08  1A
        SUB B                            ; $4B09  90
        JR STR_SUBSTR_ALLOC_COPY_1       ; $4B0A  18 CB
; [RE] RIGHT$() handler (function token $02): rightmost n chars of a string.
FN_RIGHT_STR:
        EX DE,HL                         ; $4B0C  EB
        LD A,(HL)                        ; $4B0D  7E
        CALL POP_LEN_TO_B                ; $4B0E  CD 4F 4B
        INC B                            ; $4B11  04
        DEC B                            ; $4B12  05
        JP Z,GETINT_POSITIVE_1           ; $4B13  CA EB 14
        PUSH BC                          ; $4B16  C5
        CALL PARSE_OPT_LEN_ARG           ; $4B17  CD 5F 4C
        POP AF                           ; $4B1A  F1
        EX (SP),HL                       ; $4B1B  E3
        LD BC,STR_SUBSTR_ALLOC_COPY_3    ; $4B1C  01 DB 4A
        PUSH BC                          ; $4B1F  C5
        DEC A                            ; $4B20  3D
        CP (HL)                          ; $4B21  BE
        LD B,$00                         ; $4B22  06 00
        RET NC                           ; $4B24  D0
        LD C,A                           ; $4B25  4F
        LD A,(HL)                        ; $4B26  7E
        SUB C                            ; $4B27  91
        CP E                             ; $4B28  BB
        LD B,A                           ; $4B29  47
        RET C                            ; $4B2A  D8
        LD B,E                           ; $4B2B  43
        RET                              ; $4B2C  C9
; [RE] string-function helper (reached via the function dispatch table): fetch the string descriptor, index to byte E within it, read/replace that byte and re-tokenise (used by a single-char string accessor).
STR_VAL_NULTERM:
        CALL GET_STR_DESCR_PTR           ; $4B2D  CD 6B 4A
        JP Z,FP_LOAD_INT_TO_FAC          ; $4B30  CA 4D 1E
        LD E,A                           ; $4B33  5F
        INC HL                           ; $4B34  23
        LD A,(HL)                        ; $4B35  7E
        INC HL                           ; $4B36  23
        LD H,(HL)                        ; $4B37  66
        LD L,A                           ; $4B38  6F
        PUSH HL                          ; $4B39  E5
        ADD HL,DE                        ; $4B3A  19
        LD B,(HL)                        ; $4B3B  46
        LD (HL),D                        ; $4B3C  72
        EX (SP),HL                       ; $4B3D  E3
        PUSH BC                          ; $4B3E  C5
        DEC HL                           ; $4B3F  2B
        CALL CHRGET                      ; $4B40  CD E4 13
        CALL FIN                         ; $4B43  CD 1E 31
        POP BC                           ; $4B46  C1
        POP HL                           ; $4B47  E1
        LD (HL),B                        ; $4B48  70
        RET                              ; $4B49  C9
; [RE] parse a required numeric byte argument terminated by ')': SYNCHR ')' then return the prior length byte in B from the caller's pushed args.
PARSE_BYTE_ARG:
        EX DE,HL                         ; $4B4A  EB
        CALL SYNCHR                      ; $4B4B  CD A3 45
        DEFB    ')'                      ; $4B4E  29  inline char arg consumed by the preceding CALL
; [RE] recover the source-string length byte into B from the two stacked descriptor halves, preserving the return address.
POP_LEN_TO_B:
        POP BC                           ; $4B4F  C1
        POP DE                           ; $4B50  D1
        PUSH BC                          ; $4B51  C5
        LD B,E                           ; $4B52  43
        RET                              ; $4B53  C9
; [RE] INSTR() body (token $E9): parse optional start position then the two string arguments, search for the second string inside the first and return the 1-based match index (0 if not found).
FN_INSTR:
        CALL CHRGET                      ; $4B54  CD E4 13
        CALL FRMEVL                      ; $4B57  CD 8C 1A
        CALL FRMEVL_TEST_TYPE            ; $4B5A  CD E3 1D
        LD A,$01                         ; $4B5D  3E 01
        PUSH AF                          ; $4B5F  F5
        JR Z,FN_INSTR_1                  ; $4B60  28 13
        POP AF                           ; $4B62  F1
        CALL CONINT                      ; $4B63  CD B5 20
        OR A                             ; $4B66  B7
        JP Z,GETINT_POSITIVE_1           ; $4B67  CA EB 14
        PUSH AF                          ; $4B6A  F5
        CALL SYNCHR                      ; $4B6B  CD A3 45
        DEFB    ','                      ; $4B6E  2C  inline char arg consumed by the preceding CALL
        CALL FRMEVL_NOPAREN              ; $4B6F  CD 90 1A
        CALL FP_INT_CHECK                ; $4B72  CD B3 2C
FN_INSTR_1:
        CALL SYNCHR                      ; $4B75  CD A3 45
        DEFB    ','                      ; $4B78  2C  inline char arg consumed by the preceding CALL
        PUSH HL                          ; $4B79  E5
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $4B7A  2A D4 0C
        EX (SP),HL                       ; $4B7D  E3
        CALL FRMEVL_NOPAREN              ; $4B7E  CD 90 1A
        CALL SYNCHR                      ; $4B81  CD A3 45
        DEFB    ')'                      ; $4B84  29  inline char arg consumed by the preceding CALL
        PUSH HL                          ; $4B85  E5
        CALL FRETMP                      ; $4B86  CD 37 4A
        EX DE,HL                         ; $4B89  EB
        POP BC                           ; $4B8A  C1
        POP HL                           ; $4B8B  E1
        POP AF                           ; $4B8C  F1
        PUSH BC                          ; $4B8D  C5
        LD BC,FMUL_7                     ; $4B8E  01 E1 29
        PUSH BC                          ; $4B91  C5
        LD BC,FP_LOAD_INT_TO_FAC         ; $4B92  01 4D 1E
        PUSH BC                          ; $4B95  C5
        PUSH AF                          ; $4B96  F5
        PUSH DE                          ; $4B97  D5
        CALL FRESTR_DE                   ; $4B98  CD 3D 4A
        POP DE                           ; $4B9B  D1
        POP AF                           ; $4B9C  F1
        LD B,A                           ; $4B9D  47
        DEC A                            ; $4B9E  3D
        LD C,A                           ; $4B9F  4F
        CP (HL)                          ; $4BA0  BE
        LD A,$00                         ; $4BA1  3E 00
        RET NC                           ; $4BA3  D0
        LD A,(DE)                        ; $4BA4  1A
        OR A                             ; $4BA5  B7
        LD A,B                           ; $4BA6  78
        RET Z                            ; $4BA7  C8
        LD A,(HL)                        ; $4BA8  7E
        INC HL                           ; $4BA9  23
        LD B,(HL)                        ; $4BAA  46
        INC HL                           ; $4BAB  23
        LD H,(HL)                        ; $4BAC  66
        LD L,B                           ; $4BAD  68
        LD B,$00                         ; $4BAE  06 00
        ADD HL,BC                        ; $4BB0  09
        SUB C                            ; $4BB1  91
        LD B,A                           ; $4BB2  47
        PUSH BC                          ; $4BB3  C5
        PUSH DE                          ; $4BB4  D5
        EX (SP),HL                       ; $4BB5  E3
        LD C,(HL)                        ; $4BB6  4E
        INC HL                           ; $4BB7  23
        LD E,(HL)                        ; $4BB8  5E
        INC HL                           ; $4BB9  23
        LD D,(HL)                        ; $4BBA  56
        POP HL                           ; $4BBB  E1
SUB_4BAD_1:
        PUSH HL                          ; $4BBC  E5
        PUSH DE                          ; $4BBD  D5
        PUSH BC                          ; $4BBE  C5
SUB_4BAD_2:
        LD A,(DE)                        ; $4BBF  1A
        CP (HL)                          ; $4BC0  BE
        JR NZ,SUB_4BAD_5                 ; $4BC1  20 16
        INC DE                           ; $4BC3  13
        DEC C                            ; $4BC4  0D
        JR Z,SUB_4BAD_4                  ; $4BC5  28 09
        INC HL                           ; $4BC7  23
        DJNZ SUB_4BAD_2                  ; $4BC8  10 F5
        POP DE                           ; $4BCA  D1
        POP DE                           ; $4BCB  D1
        POP BC                           ; $4BCC  C1
SUB_4BAD_3:
        POP DE                           ; $4BCD  D1
        XOR A                            ; $4BCE  AF
        RET                              ; $4BCF  C9
SUB_4BAD_4:
        POP HL                           ; $4BD0  E1
        POP DE                           ; $4BD1  D1
        POP DE                           ; $4BD2  D1
        POP BC                           ; $4BD3  C1
        LD A,B                           ; $4BD4  78
        SUB H                            ; $4BD5  94
        ADD A,C                          ; $4BD6  81
        INC A                            ; $4BD7  3C
        RET                              ; $4BD8  C9
SUB_4BAD_5:
        POP BC                           ; $4BD9  C1
        POP DE                           ; $4BDA  D1
        POP HL                           ; $4BDB  E1
        INC HL                           ; $4BDC  23
        DJNZ SUB_4BAD_1                  ; $4BDD  10 DD
        JR SUB_4BAD_3                    ; $4BDF  18 EC
; [RE] LET MID$(var$,start[,len])=src$ assignment body: locate the target string in place (allocating/copying it down out of program/heap space if needed), then overwrite the selected character range with the source string's bytes (no length change).
STMT_MID_ASSIGN:
        CALL SYNCHR                      ; $4BE1  CD A3 45
        DEFB    '('                      ; $4BE4  28  inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1                  ; $4BE5  CD B3 3B
        CALL FP_INT_CHECK                ; $4BE8  CD B3 2C
        PUSH HL                          ; $4BEB  E5
        PUSH DE                          ; $4BEC  D5
        EX DE,HL                         ; $4BED  EB
        INC HL                           ; $4BEE  23
        LD E,(HL)                        ; $4BEF  5E
        INC HL                           ; $4BF0  23
        LD D,(HL)                        ; $4BF1  56
        LD HL,(VARTAB_2)                 ; $4BF2  2A 96 0B
        CALL CMP_HL_DE                   ; $4BF5  CD 9D 45
        JR C,SUB_4C03_1                  ; $4BF8  38 12
        LD HL,(TXTTAB)                   ; $4BFA  2A 69 08
        CALL CMP_HL_DE                   ; $4BFD  CD 9D 45
        JR NC,SUB_4C03_1                 ; $4C00  30 0A
        POP HL                           ; $4C02  E1
        PUSH HL                          ; $4C03  E5
        CALL STR_BUILD_FROM_DESC         ; $4C04  CD 44 48
        POP HL                           ; $4C07  E1
        PUSH HL                          ; $4C08  E5
        CALL FP_MOVE_TYPED               ; $4C09  CD 47 2B
SUB_4C03_1:
        POP HL                           ; $4C0C  E1
        EX (SP),HL                       ; $4C0D  E3
        CALL SYNCHR                      ; $4C0E  CD A3 45
        DEFB    ','                      ; $4C11  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $4C12  CD B2 20
        OR A                             ; $4C15  B7
        JP Z,GETINT_POSITIVE_1           ; $4C16  CA EB 14
        PUSH AF                          ; $4C19  F5
        LD A,(HL)                        ; $4C1A  7E
        CALL PARSE_OPT_LEN_ARG           ; $4C1B  CD 5F 4C
        PUSH DE                          ; $4C1E  D5
        CALL EVAL_EXPR_AFTER_SYNCHR      ; $4C1F  CD 85 1A
        PUSH HL                          ; $4C22  E5
        CALL FRETMP                      ; $4C23  CD 37 4A
        EX DE,HL                         ; $4C26  EB
        POP HL                           ; $4C27  E1
        POP BC                           ; $4C28  C1
        POP AF                           ; $4C29  F1
        LD B,A                           ; $4C2A  47
        EX (SP),HL                       ; $4C2B  E3
        PUSH HL                          ; $4C2C  E5
        LD HL,FMUL_7                     ; $4C2D  21 E1 29
        EX (SP),HL                       ; $4C30  E3
        LD A,C                           ; $4C31  79
        OR A                             ; $4C32  B7
        RET Z                            ; $4C33  C8
        LD A,(HL)                        ; $4C34  7E
        SUB B                            ; $4C35  90
        JP C,GETINT_POSITIVE_1           ; $4C36  DA EB 14
        INC A                            ; $4C39  3C
        CP C                             ; $4C3A  B9
        JR C,SUB_4C03_2                  ; $4C3B  38 01
        LD A,C                           ; $4C3D  79
SUB_4C03_2:
        LD C,B                           ; $4C3E  48
        DEC C                            ; $4C3F  0D
        LD B,$00                         ; $4C40  06 00
        PUSH DE                          ; $4C42  D5
        INC HL                           ; $4C43  23
        LD E,(HL)                        ; $4C44  5E
        INC HL                           ; $4C45  23
        LD H,(HL)                        ; $4C46  66
        LD L,E                           ; $4C47  6B
        ADD HL,BC                        ; $4C48  09
        LD B,A                           ; $4C49  47
        POP DE                           ; $4C4A  D1
        EX DE,HL                         ; $4C4B  EB
        LD C,(HL)                        ; $4C4C  4E
        INC HL                           ; $4C4D  23
        LD A,(HL)                        ; $4C4E  7E
        INC HL                           ; $4C4F  23
        LD H,(HL)                        ; $4C50  66
        LD L,A                           ; $4C51  6F
        EX DE,HL                         ; $4C52  EB
        LD A,C                           ; $4C53  79
        OR A                             ; $4C54  B7
        RET Z                            ; $4C55  C8
SUB_4C03_3:
        LD A,(DE)                        ; $4C56  1A
        LD (HL),A                        ; $4C57  77
        INC DE                           ; $4C58  13
        INC HL                           ; $4C59  23
        DEC C                            ; $4C5A  0D
        RET Z                            ; $4C5B  C8
        DJNZ SUB_4C03_3                  ; $4C5C  10 F8
        RET                              ; $4C5E  C9
; [RE] parse an optional second/length argument: default $FF (whole string) when next char is ')', otherwise SYNCHR ',' and read a byte expression; ends by checking for ')'.
PARSE_OPT_LEN_ARG:
        LD E,$FF                         ; $4C5F  1E FF
        CP $29                           ; $4C61  FE 29
        JR Z,PARSE_OPT_LEN_ARG_1         ; $4C63  28 07
        CALL SYNCHR                      ; $4C65  CD A3 45
        DEFB    ','                      ; $4C68  2C  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $4C69  CD B2 20
PARSE_OPT_LEN_ARG_1:
        CALL SYNCHR                      ; $4C6C  CD A3 45
        DEFB    ')'                      ; $4C6F  29  inline char arg consumed by the preceding CALL
        RET                              ; $4C70  C9
; [RE] ATN() handler (function token $0E): arctangent (MBF).
FN_ATN:
        CALL FRMEVL_TEST_TYPE            ; $4C71  CD E3 1D
        JP NZ,FN_ATN_1                   ; $4C74  C2 7D 4C
        CALL FRESTR                      ; $4C77  CD 3A 4A
        CALL GARBAG                      ; $4C7A  CD 00 49
FN_ATN_1:
        LD HL,(VARTAB_2)                 ; $4C7D  2A 96 0B
        EX DE,HL                         ; $4C80  EB
        LD HL,(FRETOP)                   ; $4C81  2A 6B 0B
        JP FP_INT_SUB_TO_FAC             ; $4C84  C3 3B 1E
; MS BASIC-80 QINLIN: print the '? ' input prompt then fall into the console line-input editor (INLIN). Called for INPUT and for the RANDOMIZE seed prompt.
QINLIN:
        LD A,$3F                         ; $4C87  3E 3F
        CALL OUTCHR                      ; $4C89  CD 91 42
        LD A,$20                         ; $4C8C  3E 20
        CALL OUTCHR                      ; $4C8E  CD 91 42
        JP INLIN_RESET_EDIT_STATE        ; $4C91  C3 A1 4C
; [RE] INLIN per-character fetch: read one console key (CONIN at $6724); Ctrl-A ($01) toggles into line-edit/redisplay, otherwise dispatch the character in the editor.
INLIN_GETCH:
        CALL INCHR                       ; $4C94  CD A2 43
        CP $01                           ; $4C97  FE 01
        JP NZ,INLIN_DISPATCH             ; $4C99  C2 F0 4C
        LD (HL),$00                      ; $4C9C  36 00
        JR INLIN_1                       ; $4C9E  18 13
; [RE] store char then reset editor state: clear the pending-control and auto-quote flags ($0834/$0C93) at the start of a fresh input line.
INLIN_PUT_AND_RESET:
        LD (HL),B                        ; $4CA0  70
; INLIN editor state reset (entered just below INLIN_PUT_AND_RESET): clear the pending-control self-mod byte ($0857) and the INLIN_REDISPLAY_FLAG ($0CB6) before reading a fresh input line. Was SUB_4CA1. [RE]
INLIN_RESET_EDIT_STATE:
        XOR A                            ; $4CA1  AF
        LD (SUB_0752_31+1),A             ; $4CA2  32 57 08
        XOR A                            ; $4CA5  AF
        LD (DETOKENIZE_SPACE_FLAG),A     ; $4CA6  32 B6 0C
; MS BASIC-80 INLIN: console line-input editor main loop. Reads keys, echoes printable characters into the line buffer at $0A0E, and handles control keys (CR, BS/Ctrl-H, Ctrl-U, Ctrl-R, Ctrl-X, Tab, LF, DEL) building an edited line; returns it with CY=Ctrl-C abort.
INLIN:
        CALL INLIN_SAVE_COLUMN           ; $4CA9  CD BC 4D
        CALL INCHR                       ; $4CAC  CD A2 43
        CP $01                           ; $4CAF  FE 01
        JR NZ,INLIN_KILL_LINE_1          ; $4CB1  20 32
INLIN_1:
        CALL CRLF                        ; $4CB3  CD 06 44
        LD HL,$FFFF                      ; $4CB6  21 FF FF
INLIN_2:
        JP STMT_EDIT_4                   ; $4CB9  C3 05 3F
; [RE] DEL/rubout handling: echo a backslash on first delete, then erase one character from the buffer, updating the echo state at $083E.
INLIN_DELETE_CHAR:
        LD A,(SUB_0752_36)               ; $4CBC  3A 61 08
        OR A                             ; $4CBF  B7
        LD A,$5C                         ; $4CC0  3E 5C
        LD (SUB_0752_36),A               ; $4CC2  32 61 08
        JR NZ,INLIN_DELETE_CHAR_1        ; $4CC5  20 07
        DEC B                            ; $4CC7  05
        JR Z,INLIN_PUT_AND_RESET         ; $4CC8  28 D6
        CALL OUTCHR                      ; $4CCA  CD 91 42
        INC B                            ; $4CCD  04
INLIN_DELETE_CHAR_1:
        DEC B                            ; $4CCE  05
        DEC HL                           ; $4CCF  2B
        JR Z,INLIN_KILL_LINE             ; $4CD0  28 0D
        LD A,(HL)                        ; $4CD2  7E
        CALL OUTCHR                      ; $4CD3  CD 91 42
        JR INLIN_GETCH                   ; $4CD6  18 BC
        DEC B                            ; $4CD8  05
        DEC HL                           ; $4CD9  2B
        CALL OUTCHR                      ; $4CDA  CD 91 42
        JR NZ,INLIN_GETCH                ; $4CDD  20 B5
; [RE] Ctrl-U / line-kill finish: echo the trailing char, CRLF, reset the prompt buffer pointer ($0A0E) and start the line over.
INLIN_KILL_LINE:
        CALL OUTCHR                      ; $4CDF  CD 91 42
        CALL CRLF                        ; $4CE2  CD 06 44
INLIN_KILL_LINE_1:
        LD HL,BUF                        ; $4CE5  21 31 0A
        LD B,$01                         ; $4CE8  06 01
        PUSH AF                          ; $4CEA  F5
        XOR A                            ; $4CEB  AF
        LD (SUB_0752_36),A               ; $4CEC  32 61 08
        POP AF                           ; $4CEF  F1
; [RE] INLIN control-character dispatch: classify the input char (Bell $07, CR $0D, Tab $09, LF $0A, Ctrl-U $15, BS $08, Ctrl-X $18, Ctrl-R $12, < $20 ignore) and branch; printable chars fall through to the store path.
INLIN_DISPATCH:
        LD C,A                           ; $4CF0  4F
        CP $7F                           ; $4CF1  FE 7F
        JR Z,INLIN_DELETE_CHAR           ; $4CF3  28 C7
        LD A,(SUB_0752_36)               ; $4CF5  3A 61 08
        OR A                             ; $4CF8  B7
        JR Z,INLIN_DISPATCH_1            ; $4CF9  28 09
        LD A,$5C                         ; $4CFB  3E 5C
        CALL OUTCHR                      ; $4CFD  CD 91 42
        XOR A                            ; $4D00  AF
        LD (SUB_0752_36),A               ; $4D01  32 61 08
INLIN_DISPATCH_1:
        LD A,C                           ; $4D04  79
        CP $07                           ; $4D05  FE 07
        JR Z,INLIN_STORE_CHAR            ; $4D07  28 58
        CP $03                           ; $4D09  FE 03
        CALL Z,ECHO_CTRL_CHAR            ; $4D0B  CC 10 46
        SCF                              ; $4D0E  37
        RET Z                            ; $4D0F  C8
        CP $0D                           ; $4D10  FE 0D
        JP Z,INLIN_CR_FINISH             ; $4D12  CA 9F 4D
        CP $09                           ; $4D15  FE 09
        JR Z,INLIN_STORE_CHAR            ; $4D17  28 48
        CP $0A                           ; $4D19  FE 0A
        JR NZ,INLIN_DISPATCH_2           ; $4D1B  20 07
        DEC B                            ; $4D1D  05
        JP Z,INLIN_RESET_EDIT_STATE      ; $4D1E  CA A1 4C
        INC B                            ; $4D21  04
        JR INLIN_STORE_CHAR              ; $4D22  18 3D
INLIN_DISPATCH_2:
        CP $15                           ; $4D24  FE 15
        CALL Z,ECHO_CTRL_CHAR            ; $4D26  CC 10 46
        JP Z,INLIN_RESET_EDIT_STATE      ; $4D29  CA A1 4C
        CP $08                           ; $4D2C  FE 08
        JR NZ,INLIN_CTRL_X               ; $4D2E  20 0A
        DEC B                            ; $4D30  05
        JP Z,INLIN                       ; $4D31  CA A9 4C
        CALL INLIN_BACKSPACE             ; $4D34  CD C3 4D
        JP INLIN_GETCH                   ; $4D37  C3 94 4C
; [RE] Ctrl-X handling: discard the current line by echoing '#' and restarting the editor (jumps to the line-kill finish).
INLIN_CTRL_X:
        CP $18                           ; $4D3A  FE 18
        JP NZ,INLIN_CTRL_R               ; $4D3C  C2 44 4D
        LD A,$23                         ; $4D3F  3E 23
        JP INLIN_KILL_LINE               ; $4D41  C3 DF 4C
; [RE] Ctrl-R / retype-line: terminate the buffer, CRLF, redisplay the line accumulated so far (SUB_4100) from $0A0E, then resume editing.
INLIN_CTRL_R:
        CP $12                           ; $4D44  FE 12
        JR NZ,INLIN_CTRL_R_1             ; $4D46  20 14
        PUSH BC                          ; $4D48  C5
        PUSH DE                          ; $4D49  D5
        PUSH HL                          ; $4D4A  E5
        LD (HL),$00                      ; $4D4B  36 00
        CALL CRLF                        ; $4D4D  CD 06 44
        LD HL,BUF                        ; $4D50  21 31 0A
        CALL PRINT_ZSTRING               ; $4D53  CD 1B 21
        POP HL                           ; $4D56  E1
        POP DE                           ; $4D57  D1
        POP BC                           ; $4D58  C1
        JP INLIN_GETCH                   ; $4D59  C3 94 4C
INLIN_CTRL_R_1:
        CP $20                           ; $4D5C  FE 20
        JP C,INLIN_GETCH                 ; $4D5E  DA 94 4C
; [RE] store a printable character: guard against buffer overflow (255 chars -> Bell and reformat via $34E0/CRUNCH_EMIT), else append to the buffer, echo it, and detect end-of-line on LF.
INLIN_STORE_CHAR:
        LD A,B                           ; $4D61  78
        INC A                            ; $4D62  3C
        JR NZ,INLIN_APPEND_ECHO          ; $4D63  20 18
        PUSH HL                          ; $4D65  E5
        LD HL,(PTRFIL)                   ; $4D66  2A 63 08
        LD A,H                           ; $4D69  7C
        OR L                             ; $4D6A  B5
        POP HL                           ; $4D6B  E1
        LD A,$07                         ; $4D6C  3E 07
        JR Z,INLIN_APPEND_ECHO_1         ; $4D6E  28 11
        LD HL,BUF                        ; $4D70  21 31 0A
        CALL LINGET                      ; $4D73  CD FB 14
        EX DE,HL                         ; $4D76  EB
        LD (SAVTXT),HL                   ; $4D77  22 67 08
        JP CRUNCH_EMIT_1                 ; $4D7A  C3 55 12
; [RE] append the accepted char C to the buffer, bump the count, echo it; on a literal newline reset the print column ($0B11) and wait for the continuation key.
INLIN_APPEND_ECHO:
        LD A,C                           ; $4D7D  79
        LD (HL),C                        ; $4D7E  71
        INC HL                           ; $4D7F  23
        INC B                            ; $4D80  04
INLIN_APPEND_ECHO_1:
        CALL OUTCHR                      ; $4D81  CD 91 42
        SUB $0A                          ; $4D84  D6 0A
        JP NZ,INLIN_GETCH                ; $4D86  C2 94 4C
        LD (SUB_0B2A_2),A                ; $4D89  32 34 0B
        LD A,$0D                         ; $4D8C  3E 0D
        CALL OUTCHR                      ; $4D8E  CD 91 42
; [RE] after echoing a hard LF, poll the console until a non-null key arrives; CR ends the line, anything else re-enters the dispatcher.
INLIN_WAIT_AFTER_LF:
        CALL INCHR                       ; $4D91  CD A2 43
        OR A                             ; $4D94  B7
        JR Z,INLIN_WAIT_AFTER_LF         ; $4D95  28 FA
        CP $0D                           ; $4D97  FE 0D
        JP Z,INLIN_GETCH                 ; $4D99  CA 94 4C
        JP INLIN_DISPATCH                ; $4D9C  C3 F0 4C
; [RE] CR / end-of-line: if in auto-quote ('?') redisplay mode return the editor's prefilled buffer ($0A0D); otherwise terminate the buffer and return the completed line.
INLIN_CR_FINISH:
        LD A,(DETOKENIZE_SPACE_FLAG)     ; $4D9F  3A B6 0C
        OR A                             ; $4DA2  B7
        JP Z,PRINT_CRLF_IF_COL_1         ; $4DA3  CA 01 44
        XOR A                            ; $4DA6  AF
        LD (HL),A                        ; $4DA7  77
        LD HL,SUB_0925_2                 ; $4DA8  21 30 0A
        RET                              ; $4DAB  C9
; [RE] INPUT/LINE-INPUT prompt-separator: clear the auto-prompt flag ($0C93); if the next char is ';' set the flag (suppress the trailing '?') and CHRGET past it.
INPUT_PROMPT_SEP:
        PUSH AF                          ; $4DAC  F5
        LD A,$00                         ; $4DAD  3E 00
INPUT_PROMPT_SEP_1:
        LD (DETOKENIZE_SPACE_FLAG),A     ; $4DAF  32 B6 0C
        POP AF                           ; $4DB2  F1
        CP $3B                           ; $4DB3  FE 3B
        RET NZ                           ; $4DB5  C0
        LD (DETOKENIZE_SPACE_FLAG),A     ; $4DB6  32 B6 0C
        JP CHRGET                        ; $4DB9  C3 E4 13
; [RE] snapshot the current print column ($0B11) into the Tab-expansion base cell (self-modified operand at $719D) so Tab stops align to where the prompt left the cursor.
INLIN_SAVE_COLUMN:
        LD A,(SUB_0B2A_2)                ; $4DBC  3A 34 0B
        LD (INLIN_ERASE_N_COLS_2),A      ; $4DBF  32 1B 4E
        RET                              ; $4DC2  C9
; [RE] backspace/Ctrl-H handling: if erasing over a LF redisplay the line; if over a Tab recompute and back up the right number of columns to the previous tab stop; else erase one echoed character.
INLIN_BACKSPACE:
        DEC HL                           ; $4DC3  2B
        LD A,(HL)                        ; $4DC4  7E
        CP $0A                           ; $4DC5  FE 0A
        JR NZ,INLIN_REDISPLAY_LINE_2     ; $4DC7  20 10
        PUSH BC                          ; $4DC9  C5
        DEC B                            ; $4DCA  05
        JR Z,INLIN_REDISPLAY_LINE_1      ; $4DCB  28 0A
        LD HL,BUF                        ; $4DCD  21 31 0A
; [RE] re-echo the buffered line characters from HL for B bytes (used when backspacing past a newline).
INLIN_REDISPLAY_LINE:
        LD A,(HL)                        ; $4DD0  7E
        CALL OUTCHR                      ; $4DD1  CD 91 42
        INC HL                           ; $4DD4  23
        DJNZ INLIN_REDISPLAY_LINE        ; $4DD5  10 F9
INLIN_REDISPLAY_LINE_1:
        POP BC                           ; $4DD7  C1
        RET                              ; $4DD8  C9
INLIN_REDISPLAY_LINE_2:
        CP $09                           ; $4DD9  FE 09
        JR NZ,INLIN_REDISPLAY_LINE_6     ; $4DDB  20 27
        PUSH HL                          ; $4DDD  E5
        PUSH BC                          ; $4DDE  C5
        PUSH DE                          ; $4DDF  D5
        LD D,$00                         ; $4DE0  16 00
INLIN_REDISPLAY_LINE_3:
        DEC HL                           ; $4DE2  2B
        LD A,(HL)                        ; $4DE3  7E
        CP $09                           ; $4DE4  FE 09
        JR Z,INLIN_REDISPLAY_LINE_5      ; $4DE6  28 0F
        CP $0A                           ; $4DE8  FE 0A
        JR Z,INLIN_REDISPLAY_LINE_5      ; $4DEA  28 0B
        DEC B                            ; $4DEC  05
        JR Z,INLIN_REDISPLAY_LINE_4      ; $4DED  28 03
        INC D                            ; $4DEF  14
        JR INLIN_REDISPLAY_LINE_3        ; $4DF0  18 F0
INLIN_REDISPLAY_LINE_4:
        LD A,(INLIN_ERASE_N_COLS_2)      ; $4DF2  3A 1B 4E
        ADD A,D                          ; $4DF5  82
        LD D,A                           ; $4DF6  57
INLIN_REDISPLAY_LINE_5:
        LD A,D                           ; $4DF7  7A
        AND $07                          ; $4DF8  E6 07
        CPL                              ; $4DFA  2F
        ADD A,$09                        ; $4DFB  C6 09
        CALL INLIN_ERASE_N_COLS          ; $4DFD  CD 06 4E
        POP DE                           ; $4E00  D1
        POP BC                           ; $4E01  C1
        POP HL                           ; $4E02  E1
        RET                              ; $4E03  C9
INLIN_REDISPLAY_LINE_6:
        LD A,$01                         ; $4E04  3E 01
; [RE] erase A character cells on the console by emitting BS/space/BS B times (visual rubout of B columns).
INLIN_ERASE_N_COLS:
        PUSH BC                          ; $4E06  C5
        LD B,A                           ; $4E07  47
INLIN_ERASE_N_COLS_1:
        LD A,$08                         ; $4E08  3E 08
        CALL OUTCHR                      ; $4E0A  CD 91 42
        LD A,$20                         ; $4E0D  3E 20
        CALL OUTCHR                      ; $4E0F  CD 91 42
        LD A,$08                         ; $4E12  3E 08
        CALL OUTCHR                      ; $4E14  CD 91 42
        DJNZ INLIN_ERASE_N_COLS_1        ; $4E17  10 EF
        POP BC                           ; $4E19  C1
        RET                              ; $4E1A  C9
INLIN_ERASE_N_COLS_2:
        NOP                              ; $4E1B  00
; [RE] WHILE statement handler (token $AF): begin a WHILE/WEND loop; records the loop text pointer ($0B4E).
STMT_WHILE:
        LD (FRETOP_3),HL                 ; $4E1C  22 71 0B
        CALL BLOCK_SCAN_WHILE            ; $4E1F  CD CD 24
        CALL CHRGET                      ; $4E22  CD E4 13
        EX DE,HL                         ; $4E25  EB
        CALL WHILE_FIND_FRAME            ; $4E26  CD 80 4E
        INC SP                           ; $4E29  33
        INC SP                           ; $4E2A  33
        JR NZ,STMT_WHILE_1               ; $4E2B  20 05
        ADD HL,BC                        ; $4E2D  09
        LD SP,HL                         ; $4E2E  F9
        LD (SAVSTK),HL                   ; $4E2F  22 81 0B
STMT_WHILE_1:
        LD HL,(SAVTXT)                   ; $4E32  2A 67 08
        PUSH HL                          ; $4E35  E5
        LD HL,(FRETOP_3)                 ; $4E36  2A 71 0B
        PUSH HL                          ; $4E39  E5
        PUSH DE                          ; $4E3A  D5
        JR STMT_WEND_1                   ; $4E3B  18 24
; [RE] WEND statement handler (token $B0): test the WHILE condition and loop or fall through.
STMT_WEND:
        JP NZ,RAISE_SYNTAX_ERROR         ; $4E3D  C2 92 0D
        EX DE,HL                         ; $4E40  EB
        CALL WHILE_FIND_FRAME            ; $4E41  CD 80 4E
        JP NZ,WEND_NO_WHILE_ERR          ; $4E44  C2 A8 4E
        LD SP,HL                         ; $4E47  F9
        LD (SAVSTK),HL                   ; $4E48  22 81 0B
        EX DE,HL                         ; $4E4B  EB
        LD HL,(SAVTXT)                   ; $4E4C  2A 67 08
        LD (SUB_0C4B_11),HL              ; $4E4F  22 94 0C
        EX DE,HL                         ; $4E52  EB
        INC HL                           ; $4E53  23
        INC HL                           ; $4E54  23
        LD E,(HL)                        ; $4E55  5E
        INC HL                           ; $4E56  23
        LD D,(HL)                        ; $4E57  56
        INC HL                           ; $4E58  23
        LD A,(HL)                        ; $4E59  7E
        INC HL                           ; $4E5A  23
        LD H,(HL)                        ; $4E5B  66
        LD L,A                           ; $4E5C  6F
        LD (SAVTXT),HL                   ; $4E5D  22 67 08
        EX DE,HL                         ; $4E60  EB
STMT_WEND_1:
        CALL FRMEVL_NOPAREN              ; $4E61  CD 90 1A
        PUSH HL                          ; $4E64  E5
        CALL FP_TEST_SIGN                ; $4E65  CD 06 2B
        POP HL                           ; $4E68  E1
        JR Z,STMT_WEND_2                 ; $4E69  28 09
        LD BC,$00AF                      ; $4E6B  01 AF 00
        LD B,C                           ; $4E6E  41
        PUSH BC                          ; $4E6F  C5
        INC SP                           ; $4E70  33
        JP STMT_FOR_8                    ; $4E71  C3 86 13
STMT_WEND_2:
        LD HL,(SUB_0C4B_11)              ; $4E74  2A 94 0C
        LD (SAVTXT),HL                   ; $4E77  22 67 08
        POP HL                           ; $4E7A  E1
        POP AF                           ; $4E7B  F1
        POP AF                           ; $4E7C  F1
        JP STMT_FOR_8                    ; $4E7D  C3 86 13
; [RE] WHILE/WEND helper: walk the runtime stack frames (skipping FOR entries, marker $82) looking for a matching WHILE frame (marker $AF) whose loop-text pointer matches; returns the frame in HL with Z set on match.
WHILE_FIND_FRAME:
        LD HL,$0004                      ; $4E80  21 04 00
        ADD HL,SP                        ; $4E83  39
WHILE_FIND_FRAME_1:
        LD A,(HL)                        ; $4E84  7E
        INC HL                           ; $4E85  23
        LD BC,$0082                      ; $4E86  01 82 00
        CP C                             ; $4E89  B9
        JR NZ,WHILE_FIND_FRAME_2         ; $4E8A  20 06
        LD BC,$0010                      ; $4E8C  01 10 00
        ADD HL,BC                        ; $4E8F  09
        JR WHILE_FIND_FRAME_1            ; $4E90  18 F2
WHILE_FIND_FRAME_2:
        LD BC,$00AF                      ; $4E92  01 AF 00
        CP C                             ; $4E95  B9
        RET NZ                           ; $4E96  C0
        PUSH HL                          ; $4E97  E5
        LD C,(HL)                        ; $4E98  4E
        INC HL                           ; $4E99  23
        LD B,(HL)                        ; $4E9A  46
        LD H,B                           ; $4E9B  60
        LD L,C                           ; $4E9C  69
        CALL CMP_HL_DE                   ; $4E9D  CD 9D 45
        POP HL                           ; $4EA0  E1
        LD BC,$0006                      ; $4EA1  01 06 00
        RET Z                            ; $4EA4  C8
        ADD HL,BC                        ; $4EA5  09
        JR WHILE_FIND_FRAME_1            ; $4EA6  18 DC
; [RE] WEND without matching WHILE: raise coded error $1E ('WEND without WHILE') via the error dispatcher at RAISE_ERROR.
WEND_NO_WHILE_ERR:
        LD DE,ERR_WEND_WITHOUT_WHILE     ; $4EA8  11 1E 00
        JP RAISE_ERROR                   ; $4EAB  C3 AC 0D
; [RE] CALL statement handler (token $B1): call an external machine-code routine.
STMT_CALL:
        LD A,$80                         ; $4EAE  3E 80
        LD (DATA_LINE_TXTPTR_1),A        ; $4EB0  32 75 0B
        LD A,(HL)                        ; $4EB3  7E
        CP $25                           ; $4EB4  FE 25
        PUSH AF                          ; $4EB6  F5
        CALL Z,CHRGET                    ; $4EB7  CC E4 13
        CALL PTRGET_1+1                  ; $4EBA  CD B3 3B
        EX (SP),HL                       ; $4EBD  E3
        PUSH HL                          ; $4EBE  E5
        EX DE,HL                         ; $4EBF  EB
        CALL FRMEVL_TEST_TYPE            ; $4EC0  CD E3 1D
        CALL FP_ARG_SETUP1               ; $4EC3  CD 6A 2B
        CALL FN_LPOS                     ; $4EC6  CD F4 2B
        LD (DETOKENIZE_SPACE_FLAG),HL    ; $4EC9  22 B6 0C
        POP AF                           ; $4ECC  F1
        JP Z,GFX_FN_VPOS_4               ; $4ECD  CA 9E 27
        LD C,$20                         ; $4ED0  0E 20
        CALL CHECK_STACK_ROOM            ; $4ED2  CD 9F 44
        POP DE                           ; $4ED5  D1
        LD HL,$FFC0                      ; $4ED6  21 C0 FF
        ADD HL,SP                        ; $4ED9  39
        LD SP,HL                         ; $4EDA  F9
        EX DE,HL                         ; $4EDB  EB
        LD C,$20                         ; $4EDC  0E 20
        DEC HL                           ; $4EDE  2B
        CALL CHRGET                      ; $4EDF  CD E4 13
        LD (DATA_LINE_TXTPTR_3),HL       ; $4EE2  22 77 0B
        JR Z,STMT_CALL_3                 ; $4EE5  28 3B
        CALL SYNCHR                      ; $4EE7  CD A3 45
        DEFB    '('                      ; $4EEA  28  inline char arg consumed by the preceding CALL
STMT_CALL_1:
        PUSH BC                          ; $4EEB  C5
        PUSH DE                          ; $4EEC  D5
        CALL PTRGET_1+1                  ; $4EED  CD B3 3B
        EX (SP),HL                       ; $4EF0  E3
        LD (HL),E                        ; $4EF1  73
        INC HL                           ; $4EF2  23
        LD (HL),D                        ; $4EF3  72
        INC HL                           ; $4EF4  23
        EX (SP),HL                       ; $4EF5  E3
        POP DE                           ; $4EF6  D1
        POP BC                           ; $4EF7  C1
        LD A,(HL)                        ; $4EF8  7E
        CP $2C                           ; $4EF9  FE 2C
        JR NZ,STMT_CALL_2                ; $4EFB  20 06
        DEC C                            ; $4EFD  0D
        CALL CHRGET                      ; $4EFE  CD E4 13
        JR STMT_CALL_1                   ; $4F01  18 E8
STMT_CALL_2:
        CALL SYNCHR                      ; $4F03  CD A3 45
        DEFB    ')'                      ; $4F06  29  inline char arg consumed by the preceding CALL
        LD (DATA_LINE_TXTPTR_3),HL       ; $4F07  22 77 0B
        LD A,$21                         ; $4F0A  3E 21
        SUB C                            ; $4F0C  91
        POP HL                           ; $4F0D  E1
        DEC A                            ; $4F0E  3D
        JR Z,STMT_CALL_3                 ; $4F0F  28 11
        POP DE                           ; $4F11  D1
        DEC A                            ; $4F12  3D
        JR Z,STMT_CALL_3                 ; $4F13  28 0D
        POP BC                           ; $4F15  C1
        DEC A                            ; $4F16  3D
        JR Z,STMT_CALL_3                 ; $4F17  28 09
        PUSH BC                          ; $4F19  C5
        PUSH HL                          ; $4F1A  E5
        LD HL,$0002                      ; $4F1B  21 02 00
        ADD HL,SP                        ; $4F1E  39
        LD B,H                           ; $4F1F  44
        LD C,L                           ; $4F20  4D
        POP HL                           ; $4F21  E1
STMT_CALL_3:
        PUSH HL                          ; $4F22  E5
        LD HL,STMT_CALL_4                ; $4F23  21 2D 4F
        EX (SP),HL                       ; $4F26  E3
        PUSH HL                          ; $4F27  E5
        LD HL,(DETOKENIZE_SPACE_FLAG)    ; $4F28  2A B6 0C
        EX (SP),HL                       ; $4F2B  E3
        RET                              ; $4F2C  C9
STMT_CALL_4:
        LD HL,(SAVSTK)                   ; $4F2D  2A 81 0B
        LD SP,HL                         ; $4F30  F9
        LD HL,(DATA_LINE_TXTPTR_3)       ; $4F31  2A 77 0B
        JP STMT_FOR_8                    ; $4F34  C3 86 13
; [RE] CHAIN statement handler (token $B4): load and run another program, optionally preserving variables.
STMT_CHAIN:
        XOR A                            ; $4F37  AF
        LD (CHAIN_PRESERVE_FLAG),A       ; $4F38  32 BD 0C
        LD (CHAIN_PRESERVE_FLAG_1),A     ; $4F3B  32 BE 0C
        LD A,(HL)                        ; $4F3E  7E
        LD DE,$00BE                      ; $4F3F  11 BE 00
        CP E                             ; $4F42  BB
        JR NZ,STMT_CHAIN_1               ; $4F43  20 04
        LD (CHAIN_PRESERVE_FLAG),A       ; $4F45  32 BD 0C
        INC HL                           ; $4F48  23
STMT_CHAIN_1:
        DEC HL                           ; $4F49  2B
        CALL CHRGET                      ; $4F4A  CD E4 13
        CALL OPEN_FILE_FOR_LOAD_D1       ; $4F4D  CD F7 53
        PUSH HL                          ; $4F50  E5
        LD HL,$0000                      ; $4F51  21 00 00
        LD (CHAIN_BREAK_FLAG_1),HL       ; $4F54  22 C4 0C
        POP HL                           ; $4F57  E1
        DEC HL                           ; $4F58  2B
        CALL CHRGET                      ; $4F59  CD E4 13
        JP Z,STMT_CHAIN_5                ; $4F5C  CA C5 4F
        CALL SYNCHR                      ; $4F5F  CD A3 45
        DEFB    ','                      ; $4F62  2C  inline char arg consumed by the preceding CALL
        CP $2C                           ; $4F63  FE 2C
        JR Z,STMT_CHAIN_2                ; $4F65  28 11
        CALL FRMEVL_NOPAREN              ; $4F67  CD 90 1A
        PUSH HL                          ; $4F6A  E5
        CALL GETADR                      ; $4F6B  CD E1 22
        LD (CHAIN_BREAK_FLAG_1),HL       ; $4F6E  22 C4 0C
        POP HL                           ; $4F71  E1
        DEC HL                           ; $4F72  2B
        CALL CHRGET                      ; $4F73  CD E4 13
        JR Z,STMT_CHAIN_5                ; $4F76  28 4D
STMT_CHAIN_2:
        CALL SYNCHR                      ; $4F78  CD A3 45
        DEFB    ','                      ; $4F7B  2C  inline char arg consumed by the preceding CALL
        LD DE,$00A6                      ; $4F7C  11 A6 00
        CP E                             ; $4F7F  BB
        JR Z,STMT_CHAIN_3                ; $4F80  28 18
        CALL SYNCHR                      ; $4F82  CD A3 45
        DEFB    'A'                      ; $4F85  41  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $4F86  CD A3 45
        DEFB    'L'                      ; $4F89  4C  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $4F8A  CD A3 45
        DEFB    'L'                      ; $4F8D  4C  inline char arg consumed by the preceding CALL
        JP Z,CHAIN_SCAN_STRINGS          ; $4F8E  CA E9 50
        CALL SYNCHR                      ; $4F91  CD A3 45
        DEFB    ','                      ; $4F94  2C  inline char arg consumed by the preceding CALL
        CP E                             ; $4F95  BB
        JP NZ,RAISE_SYNTAX_ERROR         ; $4F96  C2 92 0D
        OR A                             ; $4F99  B7
STMT_CHAIN_3:
        PUSH AF                          ; $4F9A  F5
        LD (CHAIN_PRESERVE_FLAG_1),A     ; $4F9B  32 BE 0C
        CALL CHRGET                      ; $4F9E  CD E4 13
        CALL SCAN_LINE_RANGE             ; $4FA1  CD 84 0F
        PUSH BC                          ; $4FA4  C5
        CALL RENUM_FIXUP_IF_PENDING      ; $4FA5  CD 26 24
        POP BC                           ; $4FA8  C1
        POP DE                           ; $4FA9  D1
        PUSH BC                          ; $4FAA  C5
        LD H,B                           ; $4FAB  60
        LD L,C                           ; $4FAC  69
        LD (CHAIN_PRESERVE_FLAG_3),HL    ; $4FAD  22 C1 0C
        CALL FNDLIN                      ; $4FB0  CD AB 0F
        JR NC,STMT_CHAIN_4               ; $4FB3  30 09
        LD D,H                           ; $4FB5  54
        LD E,L                           ; $4FB6  5D
        LD (CHAIN_PRESERVE_FLAG_2),HL    ; $4FB7  22 BF 0C
        POP HL                           ; $4FBA  E1
        CALL CMP_HL_DE                   ; $4FBB  CD 9D 45
STMT_CHAIN_4:
        JP NC,GETINT_POSITIVE_1          ; $4FBE  D2 EB 14
        POP AF                           ; $4FC1  F1
        JP NZ,CHAIN_SCAN_STRINGS         ; $4FC2  C2 E9 50
STMT_CHAIN_5:
        LD HL,(TXTTAB)                   ; $4FC5  2A 69 08
        DEC HL                           ; $4FC8  2B
STMT_CHAIN_6:
        INC HL                           ; $4FC9  23
        LD A,(HL)                        ; $4FCA  7E
        INC HL                           ; $4FCB  23
        OR (HL)                          ; $4FCC  B6
        JP Z,CHAIN_MARK_VAR_6            ; $4FCD  CA 75 50
        INC HL                           ; $4FD0  23
        LD E,(HL)                        ; $4FD1  5E
        INC HL                           ; $4FD2  23
        LD D,(HL)                        ; $4FD3  56
        EX DE,HL                         ; $4FD4  EB
        LD (SAVTXT),HL                   ; $4FD5  22 67 08
        EX DE,HL                         ; $4FD8  EB
STMT_CHAIN_7:
        CALL CHRGET                      ; $4FD9  CD E4 13
STMT_CHAIN_8:
        OR A                             ; $4FDC  B7
        JR Z,STMT_CHAIN_6                ; $4FDD  28 EA
        CP $3A                           ; $4FDF  FE 3A
        JR Z,STMT_CHAIN_7                ; $4FE1  28 F6
        LD DE,$00B3                      ; $4FE3  11 B3 00
        CP E                             ; $4FE6  BB
        JR Z,STMT_CHAIN_9                ; $4FE7  28 09
        CALL CHRGET                      ; $4FE9  CD E4 13
        CALL STMT_DATA                   ; $4FEC  CD CF 15
        DEC HL                           ; $4FEF  2B
        JR STMT_CHAIN_7                  ; $4FF0  18 E7
STMT_CHAIN_9:
        CALL CHRGET                      ; $4FF2  CD E4 13
        JR Z,STMT_CHAIN_8                ; $4FF5  28 E5
STMT_CHAIN_10:
        PUSH HL                          ; $4FF7  E5
STMT_CHAIN_11:
        LD A,$01                         ; $4FF8  3E 01
        LD (DATA_LINE_TXTPTR_1),A        ; $4FFA  32 75 0B
        CALL PTRGET_1+1                  ; $4FFD  CD B3 3B
        JR Z,CHAIN_MARK_VAR_2            ; $5000  28 48
        LD A,B                           ; $5002  78
        OR $80                           ; $5003  F6 80
        LD B,A                           ; $5005  47
        XOR A                            ; $5006  AF
        CALL SUB_3D4E_6+1                ; $5007  CD AB 3D
        LD A,$00                         ; $500A  3E 00
        LD (DATA_LINE_TXTPTR_1),A        ; $500C  32 75 0B
        JR NZ,SUB_5012_1                 ; $500F  20 08
        LD A,(HL)                        ; $5011  7E
        CP $28                           ; $5012  FE 28
        JR NZ,SUB_5012_2                 ; $5014  20 09
        POP AF                           ; $5016  F1
        JR CHAIN_MARK_VAR_4              ; $5017  18 4B
SUB_5012_1:
        LD A,(HL)                        ; $5019  7E
        CP $28                           ; $501A  FE 28
        JP Z,GETINT_POSITIVE_1           ; $501C  CA EB 14
SUB_5012_2:
        POP HL                           ; $501F  E1
        CALL PTRGET_1+1                  ; $5020  CD B3 3B
SUB_5012_3:
        LD A,D                           ; $5023  7A
        OR E                             ; $5024  B3
        JR NZ,SUB_5012_5                 ; $5025  20 10
        LD A,B                           ; $5027  78
        OR $80                           ; $5028  F6 80
        LD B,A                           ; $502A  47
        LD A,(SUB_0B2A_5)                ; $502B  3A 37 0B
        LD D,A                           ; $502E  57
        CALL PTRGET_SEARCH               ; $502F  CD 47 3C
SUB_5012_4:
        LD A,D                           ; $5032  7A
        OR E                             ; $5033  B3
        JP Z,GETINT_POSITIVE_1           ; $5034  CA EB 14
SUB_5012_5:
        PUSH HL                          ; $5037  E5
        LD B,D                           ; $5038  42
        LD C,E                           ; $5039  4B
        LD HL,CHAIN_MARK_VAR_3           ; $503A  21 58 50
        PUSH HL                          ; $503D  E5
; [RE] CHAIN-ALL/COMMON helper: set the high bit (preserve flag) on a named variable so the post-CHAIN cleanup keeps it across the program reload.
CHAIN_MARK_VAR:
        DEC BC                           ; $503E  0B
CHAIN_MARK_VAR_1:
        LD A,(BC)                        ; $503F  0A
        DEC BC                           ; $5040  0B
        OR A                             ; $5041  B7
        JP M,CHAIN_MARK_VAR_1            ; $5042  FA 3F 50
        LD A,(BC)                        ; $5045  0A
        OR $80                           ; $5046  F6 80
        LD (BC),A                        ; $5048  02
        RET                              ; $5049  C9
CHAIN_MARK_VAR_2:
        LD (DATA_LINE_TXTPTR_1),A        ; $504A  32 75 0B
        LD A,(HL)                        ; $504D  7E
        CP $28                           ; $504E  FE 28
        JR NZ,SUB_5012_2                 ; $5050  20 CD
        EX (SP),HL                       ; $5052  E3
        DEC BC                           ; $5053  0B
        DEC BC                           ; $5054  0B
        CALL CHAIN_MARK_VAR              ; $5055  CD 3E 50
CHAIN_MARK_VAR_3:
        POP HL                           ; $5058  E1
        DEC HL                           ; $5059  2B
        CALL CHRGET                      ; $505A  CD E4 13
        JP Z,STMT_CHAIN_8                ; $505D  CA DC 4F
        CP $28                           ; $5060  FE 28
        JR NZ,CHAIN_MARK_VAR_5           ; $5062  20 0A
CHAIN_MARK_VAR_4:
        CALL CHRGET                      ; $5064  CD E4 13
        CALL SYNCHR                      ; $5067  CD A3 45
        DEFB    ')'                      ; $506A  29  inline char arg consumed by the preceding CALL
        JP Z,STMT_CHAIN_8                ; $506B  CA DC 4F
CHAIN_MARK_VAR_5:
        CALL SYNCHR                      ; $506E  CD A3 45
        DEFB    ','                      ; $5071  2C  inline char arg consumed by the preceding CALL
        JP STMT_CHAIN_10                 ; $5072  C3 F7 4F
CHAIN_MARK_VAR_6:
        LD HL,(VARTAB_1)                 ; $5075  2A 94 0B
        EX DE,HL                         ; $5078  EB
        LD HL,(VARTAB)                   ; $5079  2A 92 0B
CHAIN_MARK_VAR_7:
        CALL CMP_HL_DE                   ; $507C  CD 9D 45
        JR Z,CHAIN_SCAN_ARRAYS           ; $507F  28 40
        PUSH HL                          ; $5081  E5
        LD C,(HL)                        ; $5082  4E
        INC HL                           ; $5083  23
        INC HL                           ; $5084  23
        LD A,(HL)                        ; $5085  7E
        OR A                             ; $5086  B7
        PUSH AF                          ; $5087  F5
        AND $7F                          ; $5088  E6 7F
        LD (HL),A                        ; $508A  77
        INC HL                           ; $508B  23
        CALL VARTAB_SKIP_ENTRY           ; $508C  CD A3 3E
        LD B,$00                         ; $508F  06 00
        ADD HL,BC                        ; $5091  09
        POP AF                           ; $5092  F1
        POP BC                           ; $5093  C1
        JP M,CHAIN_MARK_VAR_7            ; $5094  FA 7C 50
        PUSH BC                          ; $5097  C5
        CALL CHAIN_COPY_VAR_BLOCK        ; $5098  CD A6 50
        LD HL,(VARTAB_1)                 ; $509B  2A 94 0B
        ADD HL,DE                        ; $509E  19
        LD (VARTAB_1),HL                 ; $509F  22 94 0B
        EX DE,HL                         ; $50A2  EB
        POP HL                           ; $50A3  E1
        JR CHAIN_MARK_VAR_7              ; $50A4  18 D6
; [RE] CHAIN preserve pass: relocate kept simple/array variables, copying their bytes up out of the way (via SUB_691F compare and block move) and adjusting the variable/array area pointers ($0B71/$0B73) so they survive the new program load.
CHAIN_COPY_VAR_BLOCK:
        EX DE,HL                         ; $50A6  EB
        LD HL,(VARTAB_2)                 ; $50A7  2A 96 0B
CHAIN_COPY_VAR_BLOCK_1:
        CALL CMP_HL_DE                   ; $50AA  CD 9D 45
        LD A,(DE)                        ; $50AD  1A
        LD (BC),A                        ; $50AE  02
        INC DE                           ; $50AF  13
        INC BC                           ; $50B0  03
        JR NZ,CHAIN_COPY_VAR_BLOCK_1     ; $50B1  20 F7
        LD A,C                           ; $50B3  79
        SUB L                            ; $50B4  95
        LD E,A                           ; $50B5  5F
        LD A,B                           ; $50B6  78
        SBC A,H                          ; $50B7  9C
        LD D,A                           ; $50B8  57
        DEC DE                           ; $50B9  1B
        DEC BC                           ; $50BA  0B
        LD H,B                           ; $50BB  60
        LD L,C                           ; $50BC  69
        LD (VARTAB_2),HL                 ; $50BD  22 96 0B
        RET                              ; $50C0  C9
; [RE] CHAIN preserve pass over arrays: walk the array table, temporarily clearing each entry's preserve bit, summing sizes (SUB_6225) and relocating the kept ones.
CHAIN_SCAN_ARRAYS:
        LD HL,(VARTAB_2)                 ; $50C1  2A 96 0B
        EX DE,HL                         ; $50C4  EB
CHAIN_SCAN_ARRAYS_1:
        CALL CMP_HL_DE                   ; $50C5  CD 9D 45
        JR Z,CHAIN_SCAN_STRINGS          ; $50C8  28 1F
        PUSH HL                          ; $50CA  E5
        INC HL                           ; $50CB  23
        INC HL                           ; $50CC  23
        LD A,(HL)                        ; $50CD  7E
        OR A                             ; $50CE  B7
        PUSH AF                          ; $50CF  F5
        AND $7F                          ; $50D0  E6 7F
        LD (HL),A                        ; $50D2  77
        INC HL                           ; $50D3  23
        CALL VARTAB_SKIP_ENTRY           ; $50D4  CD A3 3E
        LD C,(HL)                        ; $50D7  4E
        INC HL                           ; $50D8  23
        LD B,(HL)                        ; $50D9  46
        INC HL                           ; $50DA  23
        ADD HL,BC                        ; $50DB  09
        POP AF                           ; $50DC  F1
        POP BC                           ; $50DD  C1
        JP M,CHAIN_SCAN_ARRAYS_1         ; $50DE  FA C5 50
        PUSH BC                          ; $50E1  C5
        CALL CHAIN_COPY_VAR_BLOCK        ; $50E2  CD A6 50
        EX DE,HL                         ; $50E5  EB
        POP HL                           ; $50E6  E1
        JR CHAIN_SCAN_ARRAYS_1           ; $50E7  18 DC
; [RE] CHAIN preserve pass over string variables/arrays: walk simple-variable and array storage ($0B6F/$0B71), freeing/relocating string descriptors (type 3) of kept variables via SUB_74C5.
CHAIN_SCAN_STRINGS:
        LD HL,(VARTAB)                   ; $50E9  2A 92 0B
CHAIN_SCAN_STRINGS_1:
        EX DE,HL                         ; $50EC  EB
        LD HL,(VARTAB_1)                 ; $50ED  2A 94 0B
        EX DE,HL                         ; $50F0  EB
        CALL CMP_HL_DE                   ; $50F1  CD 9D 45
        JR Z,CHAIN_SCAN_STRINGS_4        ; $50F4  28 18
        LD A,(HL)                        ; $50F6  7E
        INC HL                           ; $50F7  23
        INC HL                           ; $50F8  23
        INC HL                           ; $50F9  23
        PUSH AF                          ; $50FA  F5
        CALL VARTAB_SKIP_ENTRY           ; $50FB  CD A3 3E
        POP AF                           ; $50FE  F1
        CP $03                           ; $50FF  FE 03
        JR NZ,CHAIN_SCAN_STRINGS_2       ; $5101  20 04
        CALL CHAIN_MOVE_STRING_VAR       ; $5103  CD 43 51
        XOR A                            ; $5106  AF
CHAIN_SCAN_STRINGS_2:
        LD E,A                           ; $5107  5F
        LD D,$00                         ; $5108  16 00
        ADD HL,DE                        ; $510A  19
        JR CHAIN_SCAN_STRINGS_1          ; $510B  18 DF
CHAIN_SCAN_STRINGS_3:
        POP BC                           ; $510D  C1
CHAIN_SCAN_STRINGS_4:
        EX DE,HL                         ; $510E  EB
        LD HL,(VARTAB_2)                 ; $510F  2A 96 0B
        EX DE,HL                         ; $5112  EB
        CALL CMP_HL_DE                   ; $5113  CD 9D 45
        JR Z,CHAIN_COMPACT_STRINGS       ; $5116  28 55
        LD A,(HL)                        ; $5118  7E
        INC HL                           ; $5119  23
        INC HL                           ; $511A  23
        PUSH AF                          ; $511B  F5
        INC HL                           ; $511C  23
        CALL VARTAB_SKIP_ENTRY           ; $511D  CD A3 3E
        LD C,(HL)                        ; $5120  4E
        INC HL                           ; $5121  23
        LD B,(HL)                        ; $5122  46
        INC HL                           ; $5123  23
        POP AF                           ; $5124  F1
        PUSH HL                          ; $5125  E5
        ADD HL,BC                        ; $5126  09
        CP $03                           ; $5127  FE 03
        JR NZ,CHAIN_SCAN_STRINGS_3       ; $5129  20 E2
        LD (FRETOP_1),HL                 ; $512B  22 6D 0B
        POP HL                           ; $512E  E1
        LD C,(HL)                        ; $512F  4E
        LD B,$00                         ; $5130  06 00
        ADD HL,BC                        ; $5132  09
        ADD HL,BC                        ; $5133  09
        INC HL                           ; $5134  23
CHAIN_SCAN_STRINGS_5:
        EX DE,HL                         ; $5135  EB
        LD HL,(FRETOP_1)                 ; $5136  2A 6D 0B
        EX DE,HL                         ; $5139  EB
        CALL CMP_HL_DE                   ; $513A  CD 9D 45
        JR Z,CHAIN_SCAN_STRINGS_4        ; $513D  28 CF
        LD BC,CHAIN_SCAN_STRINGS_5       ; $513F  01 35 51
        PUSH BC                          ; $5142  C5
; [RE] move one kept string's data during CHAIN: if the string lives in program/heap space that the reload will clobber, copy it up into safe string space (SUB_6BC6/SUB_4ECD) and rewrite its descriptor pointer.
CHAIN_MOVE_STRING_VAR:
        XOR A                            ; $5143  AF
        OR (HL)                          ; $5144  B6
        INC HL                           ; $5145  23
        LD E,(HL)                        ; $5146  5E
        INC HL                           ; $5147  23
        LD D,(HL)                        ; $5148  56
        INC HL                           ; $5149  23
        RET Z                            ; $514A  C8
        PUSH HL                          ; $514B  E5
        LD HL,(VARTAB)                   ; $514C  2A 92 0B
        CALL CMP_HL_DE                   ; $514F  CD 9D 45
        POP HL                           ; $5152  E1
        RET C                            ; $5153  D8
        PUSH HL                          ; $5154  E5
        LD HL,(TXTTAB)                   ; $5155  2A 69 08
        CALL CMP_HL_DE                   ; $5158  CD 9D 45
        POP HL                           ; $515B  E1
        RET NC                           ; $515C  D0
        PUSH HL                          ; $515D  E5
        DEC HL                           ; $515E  2B
        DEC HL                           ; $515F  2B
        DEC HL                           ; $5160  2B
        PUSH HL                          ; $5161  E5
        CALL STR_BUILD_FROM_DESC         ; $5162  CD 44 48
        POP HL                           ; $5165  E1
        LD B,$03                         ; $5166  06 03
        CALL FP_MOVE_LOOP                ; $5168  CD 4B 2B
        POP HL                           ; $516B  E1
        RET                              ; $516C  C9
; [RE] CHAIN string-space compaction: garbage-collect, then slide the preserved string heap (between $0B6F/$0B71/$0B73) to its new base, recording the move delta for descriptor fixups.
CHAIN_COMPACT_STRINGS:
        CALL GARBAG                      ; $516D  CD 00 49
        LD HL,(VARTAB_2)                 ; $5170  2A 96 0B
        LD B,H                           ; $5173  44
        LD C,L                           ; $5174  4D
        LD HL,(VARTAB)                   ; $5175  2A 92 0B
        EX DE,HL                         ; $5178  EB
        LD HL,(VARTAB_1)                 ; $5179  2A 94 0B
        LD A,L                           ; $517C  7D
        SUB E                            ; $517D  93
        LD L,A                           ; $517E  6F
        LD A,H                           ; $517F  7C
        SBC A,D                          ; $5180  9A
        LD H,A                           ; $5181  67
        LD (SUB_0C4B_5),HL               ; $5182  22 88 0C
        LD HL,(FRETOP)                   ; $5185  2A 6B 0B
        LD (CHAIN_FRETOP_SAVE),HL        ; $5188  22 B8 0C
        CALL STR_COPY_DOWN_NOCHK         ; $518B  CD 92 44
        LD H,B                           ; $518E  60
        LD L,C                           ; $518F  69
        DEC HL                           ; $5190  2B
        LD (FRETOP),HL                   ; $5191  22 6B 0B
        LD A,(CHAIN_PRESERVE_FLAG_1)     ; $5194  3A BE 0C
        OR A                             ; $5197  B7
        JR Z,CHAIN_COMPACT_STRINGS_1     ; $5198  28 0E
        LD HL,(CHAIN_PRESERVE_FLAG_3)    ; $519A  2A C1 0C
        LD B,H                           ; $519D  44
        LD C,L                           ; $519E  4D
        LD HL,(CHAIN_PRESERVE_FLAG_2)    ; $519F  2A BF 0C
        CALL BLOCK_MOVE_TO_VARTAB        ; $51A2  CD AF 22
        CALL CHEAD                       ; $51A5  CD 5C 0F
CHAIN_COMPACT_STRINGS_1:
        LD A,$01                         ; $51A8  3E 01
        LD (CHAIN_BREAK_FLAG),A          ; $51AA  32 C3 0C
        LD A,(CHAIN_PRESERVE_FLAG)       ; $51AD  3A BD 0C
        OR A                             ; $51B0  B7
        JP NZ,STMT_MERGE_1               ; $51B1  C2 B7 54
        LD A,(FILTAB_4)                  ; $51B4  3A 93 08
        LD (TXTTAB_3),A                  ; $51B7  32 6E 08
        JP OPEN_NAMED_FILE_3             ; $51BA  C3 1B 54
CHAIN_COMPACT_STRINGS_2:
        XOR A                            ; $51BD  AF
        LD (CHAIN_BREAK_FLAG),A          ; $51BE  32 C3 0C
        LD (CHAIN_PRESERVE_FLAG),A       ; $51C1  32 BD 0C
        LD HL,(VARTAB)                   ; $51C4  2A 92 0B
        LD B,H                           ; $51C7  44
        LD C,L                           ; $51C8  4D
        LD HL,(SUB_0C4B_5)               ; $51C9  2A 88 0C
        ADD HL,BC                        ; $51CC  09
        LD (VARTAB_1),HL                 ; $51CD  22 94 0B
        LD HL,(FRETOP)                   ; $51D0  2A 6B 0B
        INC HL                           ; $51D3  23
        EX DE,HL                         ; $51D4  EB
        LD HL,(CHAIN_FRETOP_SAVE)        ; $51D5  2A B8 0C
        LD (FRETOP),HL                   ; $51D8  22 6B 0B
CHAIN_COMPACT_STRINGS_3:
        CALL CMP_HL_DE                   ; $51DB  CD 9D 45
        LD A,(DE)                        ; $51DE  1A
        LD (BC),A                        ; $51DF  02
        INC DE                           ; $51E0  13
        INC BC                           ; $51E1  03
        JR NZ,CHAIN_COMPACT_STRINGS_3    ; $51E2  20 F7
        DEC BC                           ; $51E4  0B
        LD H,B                           ; $51E5  60
        LD L,C                           ; $51E6  69
        LD (VARTAB_2),HL                 ; $51E7  22 96 0B
        LD HL,(CHAIN_BREAK_FLAG_1)       ; $51EA  2A C4 0C
        LD A,H                           ; $51ED  7C
        OR L                             ; $51EE  B5
        EX DE,HL                         ; $51EF  EB
        LD HL,(TXTTAB)                   ; $51F0  2A 69 08
        DEC HL                           ; $51F3  2B
        JP Z,STMT_FOR_8                  ; $51F4  CA 86 13
        CALL FNDLIN                      ; $51F7  CD AB 0F
        JP NC,STMT_GOTO_2                ; $51FA  D2 91 15
        DEC BC                           ; $51FD  0B
        LD H,B                           ; $51FE  60
        LD L,C                           ; $51FF  69
        JP STMT_FOR_8                    ; $5200  C3 86 13
        DEFB    $C3                      ; $5203
        DEFW    STMT_DATA                ; $5204
; [RE] WRITE statement handler (token $B2): PRINT a comma-separated, quoted list to console/file.
STMT_WRITE:
        LD C,$02                         ; $5206  0E 02
        CALL PARSE_FILENUM_HASH          ; $5208  CD 8D 52
        DEC HL                           ; $520B  2B
        CALL CHRGET                      ; $520C  CD E4 13
        JR Z,SUB_5226_5                  ; $520F  28 4D
STMT_WRITE_1:
        CALL FRMEVL_NOPAREN              ; $5211  CD 90 1A
        PUSH HL                          ; $5214  E5
        CALL FRMEVL_TEST_TYPE            ; $5215  CD E3 1D
        JR Z,SUB_5226_4                  ; $5218  28 35
        CALL FOUT_2                      ; $521A  CD A0 33
        CALL SCAN_STR_LITERAL            ; $521D  CD 68 48
        LD HL,(CHAIN_BREAK_FLAG_9)       ; $5220  2A D4 0C
        INC HL                           ; $5223  23
        LD E,(HL)                        ; $5224  5E
        INC HL                           ; $5225  23
        LD D,(HL)                        ; $5226  56
        LD A,(DE)                        ; $5227  1A
        CP $20                           ; $5228  FE 20
        JR NZ,SUB_5226_1                 ; $522A  20 06
        INC DE                           ; $522C  13
        LD (HL),D                        ; $522D  72
        DEC HL                           ; $522E  2B
        LD (HL),E                        ; $522F  73
        DEC HL                           ; $5230  2B
        DEC (HL)                         ; $5231  35
SUB_5226_1:
        CALL STRPRT                      ; $5232  CD C1 48
SUB_5226_2:
        POP HL                           ; $5235  E1
        DEC HL                           ; $5236  2B
        CALL CHRGET                      ; $5237  CD E4 13
        JR Z,SUB_5226_5                  ; $523A  28 22
        CP $3B                           ; $523C  FE 3B
        JR Z,SUB_5226_3                  ; $523E  28 05
        CALL SYNCHR                      ; $5240  CD A3 45
        DEFB    ','                      ; $5243  2C  inline char arg consumed by the preceding CALL
        DEC HL                           ; $5244  2B
SUB_5226_3:
        CALL CHRGET                      ; $5245  CD E4 13
        LD A,$2C                         ; $5248  3E 2C
        CALL OUTCHR                      ; $524A  CD 91 42
        JR STMT_WRITE_1                  ; $524D  18 C2
SUB_5226_4:
        LD A,$22                         ; $524F  3E 22
        CALL OUTCHR                      ; $5251  CD 91 42
        CALL STRPRT                      ; $5254  CD C1 48
        LD A,$22                         ; $5257  3E 22
        CALL OUTCHR                      ; $5259  CD 91 42
        JR SUB_5226_2                    ; $525C  18 D7
SUB_5226_5:
        PUSH HL                          ; $525E  E5
        LD HL,(PTRFIL)                   ; $525F  2A 63 08
        LD A,H                           ; $5262  7C
        OR L                             ; $5263  B5
        JR Z,SUB_5226_7                  ; $5264  28 1E
        LD A,(HL)                        ; $5266  7E
        CP $03                           ; $5267  FE 03
        JR NZ,SUB_5226_7                 ; $5269  20 19
        CALL FILE_BUF_REMAIN             ; $526B  CD 8E 5D
        LD A,L                           ; $526E  7D
        SUB E                            ; $526F  93
        LD L,A                           ; $5270  6F
        LD A,H                           ; $5271  7C
        SBC A,D                          ; $5272  9A
        LD H,A                           ; $5273  67
        LD DE,$FFFE                      ; $5274  11 FE FF
        ADD HL,DE                        ; $5277  19
        JR NC,SUB_5226_7                 ; $5278  30 0A
SUB_5226_6:
        LD A,$20                         ; $527A  3E 20
        CALL OUTCHR                      ; $527C  CD 91 42
        DEC HL                           ; $527F  2B
        LD A,H                           ; $5280  7C
        OR L                             ; $5281  B5
        JR NZ,SUB_5226_6                 ; $5282  20 F6
SUB_5226_7:
        POP HL                           ; $5284  E1
        CALL CRLF                        ; $5285  CD 06 44
        JP PRINT_RESET_STATE             ; $5288  C3 9A 18
; [RE] Entry for routines needing a default file# of 1: sets C=1 then falls into PARSE_FILENUM_HASH.
GET_FILENUM_PREFIX_C1:
        LD C,$01                         ; $528B  0E 01
; [RE] If next char is '#', skip it and parse the file-number expr via FILE_NUM_TO_FCB; else return with file# defaulted (C). Used by PRINT#/INPUT#/WRITE#/GET/PUT.
PARSE_FILENUM_HASH:
        CP $23                           ; $528D  FE 23
        RET NZ                           ; $528F  C0
        PUSH BC                          ; $5290  C5
        CALL FILE_NUM_TO_FCB             ; $5291  CD A9 52
        POP DE                           ; $5294  D1
        CP E                             ; $5295  BB
        JR Z,PARSE_FILENUM_HASH_1        ; $5296  28 05
        CP $03                           ; $5298  FE 03
        JP NZ,RAISE_BAD_FILE_MODE        ; $529A  C2 6A 0D
PARSE_FILENUM_HASH_1:
        CALL SYNCHR                      ; $529D  CD A3 45
        DEFB    ','                      ; $52A0  2C  inline char arg consumed by the preceding CALL
; [RE] Set current-file FCB pointer (PTRFIL $0840) = BC (the resolved file number); HL preserved.
STORE_CUR_FCB_PTR:
        EX DE,HL                         ; $52A1  EB
        LD H,B                           ; $52A2  60
        LD L,C                           ; $52A3  69
        LD (PTRFIL),HL                   ; $52A4  22 63 08
        EX DE,HL                         ; $52A7  EB
        RET                              ; $52A8  C9
; [RE] CHRGET past optional '#', FRMEVL the file-number expr, range-check vs max open files ($0870); index file table at $0850 to BC=FCB base, return mode byte in A ('File not OPEN' if 0).
FILE_NUM_TO_FCB:
        DEC HL                           ; $52A9  2B
        CALL CHRGET                      ; $52AA  CD E4 13
        CP $23                           ; $52AD  FE 23
        CALL Z,CHRGET                    ; $52AF  CC E4 13
        CALL FRMEVL_NOPAREN              ; $52B2  CD 90 1A
; [RE] FILE_NUM_TO_FCB wrapper that sets Z per the FCB mode byte (caller checks open/closed).
FILE_NUM_TO_FCB_NZ:
        CALL CONINT                      ; $52B5  CD B5 20
; [RE] Resolve file# then return the FCB mode byte (file-open type) in A via the table lookup at 763B.
FILE_NUM_TO_FCB_A:
        LD E,A                           ; $52B8  5F
; [RE] Given file# in E, index file-table $0850 to BC=FCB, load mode byte A=(FCB[0]); OR A sets flags.
FCB_MODE_BYTE:
        LD A,(FILTAB_4)                  ; $52B9  3A 93 08
        CP E                             ; $52BC  BB
        JP C,RAISE_BAD_FILE_NUMBER       ; $52BD  DA 70 0D
        LD D,$00                         ; $52C0  16 00
        PUSH HL                          ; $52C2  E5
        LD HL,FILTAB                     ; $52C3  21 73 08
        ADD HL,DE                        ; $52C6  19
        ADD HL,DE                        ; $52C7  19
        LD C,(HL)                        ; $52C8  4E
        INC HL                           ; $52C9  23
        LD B,(HL)                        ; $52CA  46
        LD A,(BC)                        ; $52CB  0A
        OR A                             ; $52CC  B7
        POP HL                           ; $52CD  E1
        RET                              ; $52CE  C9
; [RE] Return DE = pointer to the file's data buffer inside its FCB: offset $29 for sequential, $B2 for random (per mode byte).
FCB_BUFFER_PTR:
        CALL FCB_MODE_BYTE               ; $52CF  CD B9 52
        LD HL,$0029                      ; $52D2  21 29 00
        CP $03                           ; $52D5  FE 03
        JR NZ,FCB_BUFFER_PTR_1           ; $52D7  20 03
        LD HL,$00B2                      ; $52D9  21 B2 00
FCB_BUFFER_PTR_1:
        ADD HL,BC                        ; $52DC  09
        EX DE,HL                         ; $52DD  EB
        RET                              ; $52DE  C9
; [RE] LOF() handler (function token $30): length-of-file in records (LD A,$02 selects the file-info op).
FN_LOF:
        LD A,$02                         ; $52DF  3E 02
FN_LOF_1:
        LD BC,$043E                      ; $52E1  01 3E 04
FN_LOF_2:
        LD BC,$083E                      ; $52E4  01 3E 08
        PUSH AF                          ; $52E7  F5
        CALL FRMEVL_APPLY_OP             ; $52E8  CD 1A 20
        POP AF                           ; $52EB  F1
        CALL ALLOC_STR_A                 ; $52EC  CD 5A 48
        LD HL,(MEMSIZ_5)                 ; $52EF  2A 69 0B
        CALL FP_ARG_SETUP2               ; $52F2  CD 72 2B
        JP STR_FN_RETURN_CHAR_1          ; $52F5  C3 8D 4A
; [RE] CVI() function handler (FUNC_DISPATCH_TBL slot $0204; CVS/CVD enter at +offset with widths 2/4/8): free the argument string temp (FRETMP), check it is wide enough (else FC), reinterpret its bytes as a numeric and load the FAC.
FN_CVI:
        LD A,$01                         ; $52F8  3E 01
FN_CVI_1:
        LD BC,$033E                      ; $52FA  01 3E 03
FN_CVI_2:
        LD BC,$073E                      ; $52FD  01 3E 07
FN_CVI_3:
        PUSH AF                          ; $5300  F5
        CALL FRETMP                      ; $5301  CD 37 4A
        POP AF                           ; $5304  F1
        CP (HL)                          ; $5305  BE
        JP NC,GETINT_POSITIVE_1          ; $5306  D2 EB 14
        INC A                            ; $5309  3C
        INC HL                           ; $530A  23
        LD C,(HL)                        ; $530B  4E
        INC HL                           ; $530C  23
        LD H,(HL)                        ; $530D  66
        LD L,C                           ; $530E  69
        LD (SUB_0B2A_5),A                ; $530F  32 37 0B
        JP FP_ARG_SETUP1                 ; $5312  C3 6A 2B
FN_CVI_4:
        CALL FRMEVL_TEST_TYPE            ; $5315  CD E3 1D
        LD BC,STMT_READ_7                ; $5318  01 20 1A
        LD DE,FN_LPOS_3                  ; $531B  11 20 2C
        JR NZ,FN_CVI_6                   ; $531E  20 17
        LD E,D                           ; $5320  5A
        JR FN_CVI_6                      ; $5321  18 14
FN_CVI_5:
        CALL GET_FILENUM_PREFIX_C1       ; $5323  CD 8B 52
        CALL PTRGET_1+1                  ; $5326  CD B3 3B
        CALL FP_INT_CHECK                ; $5329  CD B3 2C
        LD BC,PRINT_RESET_STATE          ; $532C  01 9A 18
        PUSH BC                          ; $532F  C5
        PUSH DE                          ; $5330  D5
        LD BC,STMT_DATA_4                ; $5331  01 F1 15
        XOR A                            ; $5334  AF
        LD D,A                           ; $5335  57
        LD E,A                           ; $5336  5F
FN_CVI_6:
        PUSH AF                          ; $5337  F5
        PUSH BC                          ; $5338  C5
        PUSH HL                          ; $5339  E5
FN_CVI_7:
        CALL GETC_FILE_EOF               ; $533A  CD 89 58
        JP C,RAISE_INPUT_PAST_END        ; $533D  DA 76 0D
        CP $20                           ; $5340  FE 20
        JR NZ,FN_CVI_8                   ; $5342  20 04
        INC D                            ; $5344  14
        DEC D                            ; $5345  15
        JR NZ,FN_CVI_7                   ; $5346  20 F2
FN_CVI_8:
        CP $22                           ; $5348  FE 22
        JR NZ,FN_CVI_9                   ; $534A  20 0E
        LD B,A                           ; $534C  47
        LD A,E                           ; $534D  7B
        CP $2C                           ; $534E  FE 2C
        LD A,B                           ; $5350  78
        JR NZ,FN_CVI_9                   ; $5351  20 07
        LD D,B                           ; $5353  50
        LD E,B                           ; $5354  58
        CALL GETC_FILE_EOF               ; $5355  CD 89 58
        JR C,FN_CVI_13                   ; $5358  38 43
FN_CVI_9:
        LD HL,BUF                        ; $535A  21 31 0A
        LD B,$FF                         ; $535D  06 FF
FN_CVI_10:
        LD C,A                           ; $535F  4F
        LD A,D                           ; $5360  7A
        CP $22                           ; $5361  FE 22
        LD A,C                           ; $5363  79
        JR Z,FN_CVI_11                   ; $5364  28 26
        CP $0D                           ; $5366  FE 0D
        PUSH HL                          ; $5368  E5
        JR Z,FN_CVI_15                   ; $5369  28 4D
        POP HL                           ; $536B  E1
        CP $0A                           ; $536C  FE 0A
        JR NZ,FN_CVI_11                  ; $536E  20 1C
        LD C,A                           ; $5370  4F
        LD A,E                           ; $5371  7B
        CP $2C                           ; $5372  FE 2C
        LD A,C                           ; $5374  79
        CALL NZ,INPUT_BUF_STORE          ; $5375  C4 EE 53
        CALL GETC_FILE_EOF               ; $5378  CD 89 58
        JR C,FN_CVI_13                   ; $537B  38 20
        CP $0D                           ; $537D  FE 0D
        JR NZ,FN_CVI_11                  ; $537F  20 0B
        LD A,E                           ; $5381  7B
        CP $20                           ; $5382  FE 20
        JR Z,FN_CVI_12                   ; $5384  28 12
        CP $2C                           ; $5386  FE 2C
        LD A,$0D                         ; $5388  3E 0D
        JR Z,FN_CVI_12                   ; $538A  28 0C
FN_CVI_11:
        OR A                             ; $538C  B7
        JR Z,FN_CVI_12                   ; $538D  28 09
        CP D                             ; $538F  BA
        JR Z,FN_CVI_13                   ; $5390  28 0B
        CP E                             ; $5392  BB
        JR Z,FN_CVI_13                   ; $5393  28 08
        CALL INPUT_BUF_STORE             ; $5395  CD EE 53
FN_CVI_12:
        CALL GETC_FILE_EOF               ; $5398  CD 89 58
        JR NC,FN_CVI_10                  ; $539B  30 C2
FN_CVI_13:
        PUSH HL                          ; $539D  E5
        CP $22                           ; $539E  FE 22
        JR Z,FN_CVI_14                   ; $53A0  28 04
        CP $20                           ; $53A2  FE 20
        JR NZ,FN_CVI_17                  ; $53A4  20 23
FN_CVI_14:
        CALL GETC_FILE_EOF               ; $53A6  CD 89 58
        JR C,FN_CVI_17                   ; $53A9  38 1E
        CP $20                           ; $53AB  FE 20
        JR Z,FN_CVI_14                   ; $53AD  28 F7
        CP $2C                           ; $53AF  FE 2C
        JP Z,FN_CVI_17                   ; $53B1  CA C9 53
        CP $0D                           ; $53B4  FE 0D
        JR NZ,FN_CVI_16                  ; $53B6  20 09
FN_CVI_15:
        CALL GETC_FILE_EOF               ; $53B8  CD 89 58
        JR C,FN_CVI_17                   ; $53BB  38 0C
        CP $0A                           ; $53BD  FE 0A
        JR Z,FN_CVI_17                   ; $53BF  28 08
FN_CVI_16:
        LD HL,(PTRFIL)                   ; $53C1  2A 63 08
        LD BC,$0028                      ; $53C4  01 28 00
        ADD HL,BC                        ; $53C7  09
        INC (HL)                         ; $53C8  34
FN_CVI_17:
        POP HL                           ; $53C9  E1
FN_CVI_18:
        LD (HL),$00                      ; $53CA  36 00
        LD HL,SUB_0925_2                 ; $53CC  21 30 0A
        LD A,E                           ; $53CF  7B
        SUB $20                          ; $53D0  D6 20
        JR Z,FN_CVI_19                   ; $53D2  28 08
        LD B,D                           ; $53D4  42
        LD D,$00                         ; $53D5  16 00
        CALL SCAN_STR_BODY               ; $53D7  CD 6C 48
        POP HL                           ; $53DA  E1
        RET                              ; $53DB  C9
FN_CVI_19:
        CALL FRMEVL_TEST_TYPE            ; $53DC  CD E3 1D
        PUSH AF                          ; $53DF  F5
        CALL CHRGET                      ; $53E0  CD E4 13
        POP AF                           ; $53E3  F1
        PUSH AF                          ; $53E4  F5
        CALL C,FIN_1+1                   ; $53E5  DC 25 31
        POP AF                           ; $53E8  F1
        CALL NC,FIN                      ; $53E9  D4 1E 31
        POP HL                           ; $53EC  E1
        RET                              ; $53ED  C9
; [RE] INPUT#/LINE INPUT# helper: store char A into input buffer (HL++), decrement field count B; on underflow pop caller and bail.
INPUT_BUF_STORE:
        OR A                             ; $53EE  B7
        RET Z                            ; $53EF  C8
        LD (HL),A                        ; $53F0  77
        INC HL                           ; $53F1  23
        DEC B                            ; $53F2  05
        RET NZ                           ; $53F3  C0
        POP BC                           ; $53F4  C1
        JR FN_CVI_18                     ; $53F5  18 D3
; [RE] LOAD entry: D=1 (open-for-input mode) then fall into the file-open core.
OPEN_FILE_FOR_LOAD_D1:
        LD D,$01                         ; $53F7  16 01
; [RE] LOAD/SAVE file-open stub: select channel #0 (XOR A) and enter the OPEN core with the access mode in D.
OPEN_NAMED_FILE:
        XOR A                            ; $53F9  AF
        JP STMT_OPEN_2                   ; $53FA  C3 B3 59
OPEN_NAMED_FILE_1:
        OR $AF                           ; $53FD  F6 AF
        PUSH AF                          ; $53FF  F5
        CALL OPEN_FILE_FOR_LOAD_D1       ; $5400  CD F7 53
        LD A,(FILTAB_4)                  ; $5403  3A 93 08
        LD (TXTTAB_3),A                  ; $5406  32 6E 08
        DEC HL                           ; $5409  2B
OPEN_NAMED_FILE_2:
        CALL CHRGET                      ; $540A  CD E4 13
        JR Z,OPEN_NAMED_FILE_4+1         ; $540D  28 11
        CALL SYNCHR                      ; $540F  CD A3 45
        DEFB    ','                      ; $5412  2C  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $5413  CD A3 45
        DEFB    'R'                      ; $5416  52  inline char arg consumed by the preceding CALL
        JP NZ,RAISE_SYNTAX_ERROR         ; $5417  C2 92 0D
        POP AF                           ; $541A  F1
OPEN_NAMED_FILE_3:
        XOR A                            ; $541B  AF
        LD (FILTAB_4),A                  ; $541C  32 93 08
OPEN_NAMED_FILE_4:
        OR $F1                           ; $541F  F6 F1
        LD (TXTTAB_2),A                  ; $5421  32 6D 08
        LD HL,$0080                      ; $5424  21 80 00
        LD (HL),$00                      ; $5427  36 00
        LD (FILTAB),HL                   ; $5429  22 73 08
        CALL CLEAR_VARS                  ; $542C  CD F5 44
        LD A,(TXTTAB_3)                  ; $542F  3A 6E 08
        LD (FILTAB_4),A                  ; $5432  32 93 08
        LD HL,(FILTAB_SLOT0_SEED)        ; $5435  2A 71 08
        LD (FILTAB),HL                   ; $5438  22 73 08
        LD (PTRFIL),HL                   ; $543B  22 63 08
        LD HL,(SAVTXT)                   ; $543E  2A 67 08
        INC HL                           ; $5441  23
        LD A,H                           ; $5442  7C
        AND L                            ; $5443  A5
        INC A                            ; $5444  3C
        JR NZ,OPEN_NAMED_FILE_5          ; $5445  20 03
        LD (SAVTXT),HL                   ; $5447  22 67 08
OPEN_NAMED_FILE_5:
        CALL GETC_FILE_EOF               ; $544A  CD 89 58
        JP C,DIRECT_LINE_DISPATCH        ; $544D  DA 61 0E
        CP $FE                           ; $5450  FE FE
        JR NZ,OPEN_NAMED_FILE_6          ; $5452  20 05
        LD (RUNNING_PROG_FLAG),A         ; $5454  32 BC 0C
        JR OPEN_NAMED_FILE_7             ; $5457  18 04
OPEN_NAMED_FILE_6:
        INC A                            ; $5459  3C
        JP NZ,STMT_MERGE_2               ; $545A  C2 C5 54
OPEN_NAMED_FILE_7:
        LD HL,(TXTTAB)                   ; $545D  2A 69 08
        CALL FILE_READ_RECORDS           ; $5460  CD 70 5B
        LD (VARTAB),HL                   ; $5463  22 92 0B
        LD A,(RUNNING_PROG_FLAG)         ; $5466  3A BC 0C
        OR A                             ; $5469  B7
        CALL NZ,PROG_SCRAMBLE            ; $546A  C4 EB 5D
        CALL CHEAD                       ; $546D  CD 5C 0F
        INC HL                           ; $5470  23
        INC HL                           ; $5471  23
        LD (VARTAB),HL                   ; $5472  22 92 0B
        LD HL,FILTAB_4                   ; $5475  21 93 08
        LD A,(HL)                        ; $5478  7E
        LD (TXTTAB_3),A                  ; $5479  32 6E 08
        LD (HL),$00                      ; $547C  36 00
        CALL CLEAR_RESET_DATAPTR         ; $547E  CD 0B 45
        LD A,(TXTTAB_3)                  ; $5481  3A 6E 08
        LD (FILTAB_4),A                  ; $5484  32 93 08
        LD A,(CHAIN_BREAK_FLAG)          ; $5487  3A C3 0C
        OR A                             ; $548A  B7
        JP NZ,CHAIN_COMPACT_STRINGS_2    ; $548B  C2 BD 51
        LD A,(TXTTAB_2)                  ; $548E  3A 6D 08
        OR A                             ; $5491  B7
        JP Z,NEWSTT_READY                ; $5492  CA 46 0E
        JP STMT_FOR_8                    ; $5495  C3 86 13
; [RE] After LOAD/RUN: close all open files (via CLOSE-all) and re-init variable space (CLEAR_VARS).
LOAD_FINISH_CLOSE_CUR:
        CALL PRINT_RESET_STATE           ; $5498  CD 9A 18
        CALL FILE_CLOSE_ONE              ; $549B  CD 3C 57
        JP SUB_453A_3                    ; $549E  C3 99 45
; [RE] RUN with no filename: CLEAR_VARS then jump into the program-run / stack-reset path.
RUN_CLEAR_AND_GO:
        CALL CLEAR_VARS                  ; $54A1  CD F5 44
        JP CHECK_STACK_ROOM_1            ; $54A4  C3 B4 44
; [RE] MERGE statement handler (token $BE): merge an ASCII program file into the current program.
STMT_MERGE:
        POP BC                           ; $54A7  C1
        CALL OPEN_FILE_FOR_LOAD_D1       ; $54A8  CD F7 53
        DEC HL                           ; $54AB  2B
        CALL CHRGET                      ; $54AC  CD E4 13
        JR Z,STMT_MERGE_1                ; $54AF  28 06
        CALL LOAD_FINISH_CLOSE_CUR       ; $54B1  CD 98 54
        JP RAISE_SYNTAX_ERROR            ; $54B4  C3 92 0D
STMT_MERGE_1:
        XOR A                            ; $54B7  AF
        LD (TXTTAB_2),A                  ; $54B8  32 6D 08
        CALL GETC_FILE_EOF               ; $54BB  CD 89 58
        JP C,DIRECT_LINE_DISPATCH        ; $54BE  DA 61 0E
        INC A                            ; $54C1  3C
        JP Z,RAISE_BAD_FILE_MODE         ; $54C2  CA 6A 0D
STMT_MERGE_2:
        LD HL,(PTRFIL)                   ; $54C5  2A 63 08
        LD BC,$0028                      ; $54C8  01 28 00
        ADD HL,BC                        ; $54CB  09
        INC (HL)                         ; $54CC  34
        JP DIRECT_LINE_DISPATCH          ; $54CD  C3 61 0E
STMT_MERGE_3:
        PUSH HL                          ; $54D0  E5
        LD HL,(PTRFIL)                   ; $54D1  2A 63 08
        LD A,H                           ; $54D4  7C
        OR L                             ; $54D5  B5
        LD DE,ERR_DIRECT_STATEMENT_IN_FILE  ; $54D6  11 42 00
        JP NZ,RAISE_ERROR                ; $54D9  C2 AC 0D
        POP HL                           ; $54DC  E1
        JP STMT_FOR_12                   ; $54DD  C3 C4 13
; [RE] SAVE statement handler (token $C4): save the program to disk (tokenized or ASCII).
STMT_SAVE:
        LD D,$02                         ; $54E0  16 02
        CALL OPEN_NAMED_FILE             ; $54E2  CD F9 53
        DEC HL                           ; $54E5  2B
        CALL CHRGET                      ; $54E6  CD E4 13
        JR Z,STMT_SAVE_1                 ; $54E9  28 10
        CALL SYNCHR                      ; $54EB  CD A3 45
        DEFB    ','                      ; $54EE  2C  inline char arg consumed by the preceding CALL
        CP $50                           ; $54EF  FE 50
        JP Z,FILE_BUF_REMAIN_BC_1        ; $54F1  CA 9D 5D
        CALL SYNCHR                      ; $54F4  CD A3 45
        DEFB    'A'                      ; $54F7  41  inline char arg consumed by the preceding CALL
        JP STMT_LIST                     ; $54F8  C3 C6 20
STMT_SAVE_1:
        CALL RENUM_PATCH_LINEREFS        ; $54FB  CD 8D 23
        CALL ILLEGAL_DIRECT_CHECK        ; $54FE  CD 2A 5E
        LD A,$FF                         ; $5501  3E FF
; [RE] SAVE core: write the tokenized program image (line links + text) byte-by-byte to the open output file via PUTC_FILE (SUB_7B22), terminating at end-of-program.
SAVE_WRITE_PROGRAM:
        CALL PUTC_FILE                   ; $5503  CD A0 57
        LD HL,(VARTAB)                   ; $5506  2A 92 0B
        EX DE,HL                         ; $5509  EB
        LD HL,(TXTTAB)                   ; $550A  2A 69 08
SAVE_WRITE_PROGRAM_1:
        CALL CMP_HL_DE                   ; $550D  CD 9D 45
        JP Z,LOAD_FINISH_CLOSE_CUR       ; $5510  CA 98 54
        LD A,(HL)                        ; $5513  7E
        INC HL                           ; $5514  23
        PUSH DE                          ; $5515  D5
        CALL PUTC_FILE                   ; $5516  CD A0 57
        POP DE                           ; $5519  D1
        JR SAVE_WRITE_PROGRAM_1          ; $551A  18 F1
; [RE] CLOSE statement handler (token $BC): close one or all open file channels.
STMT_CLOSE:
        LD BC,FILE_CLOSE_ONE             ; $551C  01 3C 57
        LD A,(FILTAB_4)                  ; $551F  3A 93 08
        JR NZ,CLOSE_ONE_THEN_COMMA_1     ; $5522  20 1A
        PUSH HL                          ; $5524  E5
STMT_CLOSE_1:
        PUSH BC                          ; $5525  C5
        PUSH AF                          ; $5526  F5
        LD DE,CLOSE_ALL_LOOP_NEXT        ; $5527  11 2D 55
        PUSH DE                          ; $552A  D5
        PUSH BC                          ; $552B  C5
        RET                              ; $552C  C9
; [RE] CLOSE-all loop trampoline (executable bytes shown as DEFB): POP regs, decrement file index, loop to close next file, else POP HL/RET.
CLOSE_ALL_LOOP_NEXT:
        POP AF                           ; $552D  F1
        POP BC                           ; $552E  C1
        DEC A                            ; $552F  3D
        JP P,STMT_CLOSE_1                ; $5530  F2 25 55
        POP HL                           ; $5533  E1
        RET                              ; $5534  C9
; [RE] CLOSE continuation trampoline (executable DEFB): after closing one file, restore BC and check for ',' to close the next listed file number.
CLOSE_ONE_THEN_COMMA:
        POP BC                           ; $5535  C1
        POP HL                           ; $5536  E1
        LD A,(HL)                        ; $5537  7E
        CP $2C                           ; $5538  FE 2C
        RET NZ                           ; $553A  C0
        CALL CHRGET                      ; $553B  CD E4 13
CLOSE_ONE_THEN_COMMA_1:
        PUSH BC                          ; $553E  C5
        LD A,(HL)                        ; $553F  7E
        CP $23                           ; $5540  FE 23
        CALL Z,CHRGET                    ; $5542  CC E4 13
        CALL GETBYT                      ; $5545  CD B2 20
        EX (SP),HL                       ; $5548  E3
        PUSH HL                          ; $5549  E5
        LD DE,CLOSE_ONE_THEN_COMMA       ; $554A  11 35 55
        PUSH DE                          ; $554D  D5
        JP (HL)                          ; $554E  E9
; [RE] Close every open file (A=0 -> CLOSE-all path of STMT_CLOSE); preserves BC/DE. Used by RUN/NEW/SYSTEM/RESET.
CLOSE_ALL_FILES:
        PUSH DE                          ; $554F  D5
        PUSH BC                          ; $5550  C5
        XOR A                            ; $5551  AF
        CALL STMT_CLOSE                  ; $5552  CD 1C 55
        POP BC                           ; $5555  C1
        POP DE                           ; $5556  D1
        XOR A                            ; $5557  AF
        RET                              ; $5558  C9
; [RE] FIELD statement handler (token $B9): define random-file buffer field variables.
STMT_FIELD:
        CALL FILE_NUM_TO_FCB             ; $5559  CD A9 52
        JP Z,RAISE_BAD_FILE_NUMBER       ; $555C  CA 70 0D
        SUB $03                          ; $555F  D6 03
        JP NZ,RAISE_BAD_FILE_MODE        ; $5561  C2 6A 0D
        EX DE,HL                         ; $5564  EB
        LD HL,$00A9                      ; $5565  21 A9 00
        ADD HL,BC                        ; $5568  09
        LD A,(HL)                        ; $5569  7E
        INC HL                           ; $556A  23
        LD H,(HL)                        ; $556B  66
        LD L,A                           ; $556C  6F
        LD (DETOKENIZE_SPACE_FLAG),HL    ; $556D  22 B6 0C
        LD HL,$0000                      ; $5570  21 00 00
        LD (ILLEGAL_DIRECT_CHECK_1),HL   ; $5573  22 34 5E
        LD A,H                           ; $5576  7C
        EX DE,HL                         ; $5577  EB
        LD DE,$00B2                      ; $5578  11 B2 00
STMT_FIELD_1:
        EX DE,HL                         ; $557B  EB
        ADD HL,BC                        ; $557C  09
        LD B,A                           ; $557D  47
        EX DE,HL                         ; $557E  EB
        LD A,(HL)                        ; $557F  7E
        CP $2C                           ; $5580  FE 2C
        RET NZ                           ; $5582  C0
        PUSH DE                          ; $5583  D5
        PUSH BC                          ; $5584  C5
        CALL GETBYT_CHRGET               ; $5585  CD AF 20
        PUSH AF                          ; $5588  F5
        CALL SYNCHR                      ; $5589  CD A3 45
        DEFB    'A'                      ; $558C  41  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $558D  CD A3 45
        DEFB    'S'                      ; $5590  53  inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1                  ; $5591  CD B3 3B
        CALL FP_INT_CHECK                ; $5594  CD B3 2C
        POP AF                           ; $5597  F1
        POP BC                           ; $5598  C1
        EX (SP),HL                       ; $5599  E3
        LD C,A                           ; $559A  4F
        PUSH DE                          ; $559B  D5
        PUSH HL                          ; $559C  E5
        LD HL,(ILLEGAL_DIRECT_CHECK_1)   ; $559D  2A 34 5E
        LD B,$00                         ; $55A0  06 00
        ADD HL,BC                        ; $55A2  09
        LD (ILLEGAL_DIRECT_CHECK_1),HL   ; $55A3  22 34 5E
        EX DE,HL                         ; $55A6  EB
        LD HL,(DETOKENIZE_SPACE_FLAG)    ; $55A7  2A B6 0C
        CALL CMP_HL_DE                   ; $55AA  CD 9D 45
        JP C,RAISE_FIELD_OVERFLOW        ; $55AD  DA 82 0D
        POP HL                           ; $55B0  E1
        POP DE                           ; $55B1  D1
        EX DE,HL                         ; $55B2  EB
        LD (HL),C                        ; $55B3  71
        INC HL                           ; $55B4  23
        LD (HL),E                        ; $55B5  73
        INC HL                           ; $55B6  23
        LD (HL),D                        ; $55B7  72
        POP HL                           ; $55B8  E1
        JR STMT_FIELD_1                  ; $55B9  18 C0
; [RE] RSET statement handler (token $C3): right-justify a string into a FIELD buffer variable. LSET (token $C2) enters at $793E with the justify flag cleared.
STMT_RSET:
        OR $37                           ; $55BB  F6 37
        PUSH AF                          ; $55BD  F5
        CALL PTRGET_1+1                  ; $55BE  CD B3 3B
        CALL FP_INT_CHECK                ; $55C1  CD B3 2C
        PUSH DE                          ; $55C4  D5
        CALL EVAL_EXPR_AFTER_SYNCHR      ; $55C5  CD 85 1A
        POP BC                           ; $55C8  C1
        EX (SP),HL                       ; $55C9  E3
        PUSH HL                          ; $55CA  E5
        PUSH BC                          ; $55CB  C5
        CALL FRETMP                      ; $55CC  CD 37 4A
        LD B,(HL)                        ; $55CF  46
        EX (SP),HL                       ; $55D0  E3
        LD A,(HL)                        ; $55D1  7E
        LD C,A                           ; $55D2  4F
        PUSH BC                          ; $55D3  C5
        PUSH HL                          ; $55D4  E5
        PUSH AF                          ; $55D5  F5
        INC HL                           ; $55D6  23
        LD E,(HL)                        ; $55D7  5E
        INC HL                           ; $55D8  23
        LD D,(HL)                        ; $55D9  56
        OR A                             ; $55DA  B7
        JP Z,STMT_RSET_5                 ; $55DB  CA 3B 56
        LD HL,(TXTTAB)                   ; $55DE  2A 69 08
        CALL CMP_HL_DE                   ; $55E1  CD 9D 45
        JR NC,STMT_RSET_2                ; $55E4  30 30
        LD HL,(VARTAB)                   ; $55E6  2A 92 0B
        CALL CMP_HL_DE                   ; $55E9  CD 9D 45
        JR C,STMT_RSET_2                 ; $55EC  38 28
        LD E,C                           ; $55EE  59
        LD D,$00                         ; $55EF  16 00
        LD HL,(VARTAB_2)                 ; $55F1  2A 96 0B
        ADD HL,DE                        ; $55F4  19
        EX DE,HL                         ; $55F5  EB
        LD HL,(FRETOP)                   ; $55F6  2A 6B 0B
        CALL CMP_HL_DE                   ; $55F9  CD 9D 45
        JP C,FIELD_PAD_SPACES_2          ; $55FC  DA 4E 56
STMT_RSET_1:
        POP AF                           ; $55FF  F1
        LD A,C                           ; $5600  79
        CALL GETSPA                      ; $5601  CD D6 48
        POP HL                           ; $5604  E1
        POP BC                           ; $5605  C1
        EX (SP),HL                       ; $5606  E3
        PUSH DE                          ; $5607  D5
        PUSH BC                          ; $5608  C5
        CALL FRETMP                      ; $5609  CD 37 4A
        POP BC                           ; $560C  C1
        POP DE                           ; $560D  D1
        EX (SP),HL                       ; $560E  E3
        PUSH BC                          ; $560F  C5
        PUSH HL                          ; $5610  E5
        INC HL                           ; $5611  23
        LD (HL),E                        ; $5612  73
        INC HL                           ; $5613  23
        LD (HL),D                        ; $5614  72
        PUSH AF                          ; $5615  F5
STMT_RSET_2:
        POP AF                           ; $5616  F1
        POP HL                           ; $5617  E1
        INC HL                           ; $5618  23
        LD E,(HL)                        ; $5619  5E
        INC HL                           ; $561A  23
        LD D,(HL)                        ; $561B  56
        POP BC                           ; $561C  C1
        POP HL                           ; $561D  E1
        PUSH DE                          ; $561E  D5
        INC HL                           ; $561F  23
        LD E,(HL)                        ; $5620  5E
        INC HL                           ; $5621  23
        LD D,(HL)                        ; $5622  56
        EX DE,HL                         ; $5623  EB
        POP DE                           ; $5624  D1
        LD A,C                           ; $5625  79
        CP B                             ; $5626  B8
        JR NC,STMT_RSET_3                ; $5627  30 01
        LD B,A                           ; $5629  47
STMT_RSET_3:
        SUB B                            ; $562A  90
        LD C,A                           ; $562B  4F
        POP AF                           ; $562C  F1
        CALL NC,FIELD_PAD_SPACES         ; $562D  D4 45 56
        INC B                            ; $5630  04
STMT_RSET_4:
        DEC B                            ; $5631  05
        JR Z,STMT_RSET_6                 ; $5632  28 0C
        LD A,(HL)                        ; $5634  7E
        LD (DE),A                        ; $5635  12
        INC HL                           ; $5636  23
        INC DE                           ; $5637  13
        JP STMT_RSET_4                   ; $5638  C3 31 56
STMT_RSET_5:
        POP BC                           ; $563B  C1
        POP BC                           ; $563C  C1
        POP BC                           ; $563D  C1
        POP BC                           ; $563E  C1
        POP BC                           ; $563F  C1
STMT_RSET_6:
        CALL C,FIELD_PAD_SPACES          ; $5640  DC 45 56
        POP HL                           ; $5643  E1
        RET                              ; $5644  C9
; [RE] LSET/RSET helper: pad the field buffer (DE) with C spaces; used to blank/justify the fixed-width field.
FIELD_PAD_SPACES:
        LD A,$20                         ; $5645  3E 20
        INC C                            ; $5647  0C
FIELD_PAD_SPACES_1:
        DEC C                            ; $5648  0D
        RET Z                            ; $5649  C8
        LD (DE),A                        ; $564A  12
        INC DE                           ; $564B  13
        JR FIELD_PAD_SPACES_1            ; $564C  18 FA
FIELD_PAD_SPACES_2:
        POP AF                           ; $564E  F1
        POP HL                           ; $564F  E1
        POP BC                           ; $5650  C1
        EX (SP),HL                       ; $5651  E3
        EX DE,HL                         ; $5652  EB
        JR NZ,FIELD_PAD_SPACES_3         ; $5653  20 09
        PUSH BC                          ; $5655  C5
        LD A,B                           ; $5656  78
        CALL ALLOC_STR_A                 ; $5657  CD 5A 48
        CALL PUT_STR_TEMP                ; $565A  CD 98 48
        POP BC                           ; $565D  C1
FIELD_PAD_SPACES_3:
        EX (SP),HL                       ; $565E  E3
        PUSH BC                          ; $565F  C5
        PUSH HL                          ; $5660  E5
        PUSH AF                          ; $5661  F5
        JP STMT_RSET_1                   ; $5662  C3 FF 55
FIELD_PAD_SPACES_4:
        CALL CHRGET                      ; $5665  CD E4 13
        CALL SYNCHR                      ; $5668  CD A3 45
        DEFB    '$'                      ; $566B  24  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $566C  CD A3 45
        DEFB    '('                      ; $566F  28  inline char arg consumed by the preceding CALL
        CALL GETBYT                      ; $5670  CD B2 20
        PUSH DE                          ; $5673  D5
        LD A,(HL)                        ; $5674  7E
        CP $2C                           ; $5675  FE 2C
        JR NZ,FIELD_PAD_SPACES_5         ; $5677  20 0F
        CALL CHRGET                      ; $5679  CD E4 13
        CALL FILE_NUM_TO_FCB             ; $567C  CD A9 52
        CP $02                           ; $567F  FE 02
        JP Z,RAISE_BAD_FILE_MODE         ; $5681  CA 6A 0D
        CALL STORE_CUR_FCB_PTR           ; $5684  CD A1 52
        XOR A                            ; $5687  AF
FIELD_PAD_SPACES_5:
        PUSH AF                          ; $5688  F5
        CALL SYNCHR                      ; $5689  CD A3 45
        DEFB    ')'                      ; $568C  29  inline char arg consumed by the preceding CALL
        POP AF                           ; $568D  F1
        EX (SP),HL                       ; $568E  E3
        PUSH AF                          ; $568F  F5
        LD A,L                           ; $5690  7D
        OR A                             ; $5691  B7
        JP Z,GETINT_POSITIVE_1           ; $5692  CA EB 14
        PUSH HL                          ; $5695  E5
        CALL ALLOC_STR_A                 ; $5696  CD 5A 48
        EX DE,HL                         ; $5699  EB
        POP BC                           ; $569A  C1
FIELD_PAD_SPACES_6:
        POP AF                           ; $569B  F1
        PUSH AF                          ; $569C  F5
        JR Z,FIELD_PAD_SPACES_10         ; $569D  28 20
        CALL GET_PENDING_KEY             ; $569F  CD 72 44
        JR NZ,FIELD_PAD_SPACES_7         ; $56A2  20 03
        CALL CONIN                       ; $56A4  CD DA 43
FIELD_PAD_SPACES_7:
        CP $03                           ; $56A7  FE 03
        JP Z,FIELD_PAD_SPACES_9          ; $56A9  CA B8 56
FIELD_PAD_SPACES_8:
        LD (HL),A                        ; $56AC  77
        INC HL                           ; $56AD  23
        DEC C                            ; $56AE  0D
        JR NZ,FIELD_PAD_SPACES_6         ; $56AF  20 EA
        POP AF                           ; $56B1  F1
        CALL PRINT_RESET_STATE           ; $56B2  CD 9A 18
        JP PUT_STR_TEMP                  ; $56B5  C3 98 48
FIELD_PAD_SPACES_9:
        LD HL,(SAVSTK)                   ; $56B8  2A 81 0B
        LD SP,HL                         ; $56BB  F9
        JP STMT_END_3                    ; $56BC  C3 E7 45
FIELD_PAD_SPACES_10:
        CALL GETC_FILE_EOF               ; $56BF  CD 89 58
        JP C,RAISE_INPUT_PAST_END        ; $56C2  DA 76 0D
        JP FIELD_PAD_SPACES_8            ; $56C5  C3 AC 56
; [RE] EOF() function handler (FUNC_DISPATCH_TBL slot $020C): resolve the file number to its FCB and return the end-of-file boolean.
FN_EOF:
        CALL FILE_NUM_TO_FCB_NZ          ; $56C8  CD B5 52
        JP Z,RAISE_BAD_FILE_NUMBER       ; $56CB  CA 70 0D
        CP $02                           ; $56CE  FE 02
        JP Z,RAISE_BAD_FILE_MODE         ; $56D0  CA 6A 0D
FN_EOF_1:
        LD HL,$0027                      ; $56D3  21 27 00
        ADD HL,BC                        ; $56D6  09
        LD A,(HL)                        ; $56D7  7E
        OR A                             ; $56D8  B7
        JR Z,FN_EOF_3                    ; $56D9  28 1E
        LD A,(BC)                        ; $56DB  0A
        CP $03                           ; $56DC  FE 03
        JR Z,FN_EOF_3                    ; $56DE  28 19
        INC HL                           ; $56E0  23
        LD A,(HL)                        ; $56E1  7E
        OR A                             ; $56E2  B7
        JR NZ,FN_EOF_2                   ; $56E3  20 09
        PUSH BC                          ; $56E5  C5
        LD H,B                           ; $56E6  60
        LD L,C                           ; $56E7  69
        CALL FILE_READ_RECORD_FCB        ; $56E8  CD 42 58
        POP BC                           ; $56EB  C1
        JR FN_EOF_1                      ; $56EC  18 E5
FN_EOF_2:
        LD A,$80                         ; $56EE  3E 80
        SUB (HL)                         ; $56F0  96
        LD C,A                           ; $56F1  4F
        LD B,$00                         ; $56F2  06 00
        ADD HL,BC                        ; $56F4  09
        INC HL                           ; $56F5  23
        LD A,(HL)                        ; $56F6  7E
        SUB $1A                          ; $56F7  D6 1A
FN_EOF_3:
        SUB $01                          ; $56F9  D6 01
        SBC A,A                          ; $56FB  9F
        JP INT16_TO_FP                   ; $56FC  C3 FF 2A
; [RE] Flush the current record via BDOS Write-Sequential ($15) (read-seq = $14); function code from $08CD.
FILE_FLUSH_RECORD:
        LD D,B                           ; $56FF  50
        LD E,C                           ; $5700  59
        INC DE                           ; $5701  13
; [RE] Write-sequential error check: BDOS Write-Sequential = $15 (function code held at $08CD).
FILE_FLUSH_RECORD_CK:
        LD HL,$0027                      ; $5702  21 27 00
        ADD HL,BC                        ; $5705  09
        PUSH BC                          ; $5706  C5
        XOR A                            ; $5707  AF
        LD (HL),A                        ; $5708  77
        CALL BDOS_SET_DMA_FCB            ; $5709  CD 78 58
        LD A,(FILTAB_17)                 ; $570C  3A F0 08
        CALL BDOS_FILE_CALL              ; $570F  CD 44 5B
        CP $FF                           ; $5712  FE FF
        JP Z,RAISE_TOO_MANY_FILES        ; $5714  CA 85 0D
        DEC A                            ; $5717  3D
        JP Z,RAISE_DISK_I_O_ERROR        ; $5718  CA 67 0D
        DEC A                            ; $571B  3D
        JP NZ,FILE_FLUSH_RECORD_CK_2     ; $571C  C2 2B 57
        POP DE                           ; $571F  D1
FILE_FLUSH_RECORD_CK_1:
        XOR A                            ; $5720  AF
        LD (DE),A                        ; $5721  12
        LD C,$10                         ; $5722  0E 10
        INC DE                           ; $5724  13
        CALL $0005                       ; $5725  CD 05 00
        JP RAISE_DISK_FULL               ; $5728  C3 64 0D
FILE_FLUSH_RECORD_CK_2:
        INC A                            ; $572B  3C
        JP Z,RAISE_TOO_MANY_FILES        ; $572C  CA 85 0D
        POP BC                           ; $572F  C1
        LD HL,$0025                      ; $5730  21 25 00
        ADD HL,BC                        ; $5733  09
        LD E,(HL)                        ; $5734  5E
        INC HL                           ; $5735  23
        LD D,(HL)                        ; $5736  56
        INC DE                           ; $5737  13
        LD (HL),D                        ; $5738  72
        DEC HL                           ; $5739  2B
        LD (HL),E                        ; $573A  73
        RET                              ; $573B  C9
; [RE] Close a single open file: write trailing Ctrl-Z/EOF + flush partial record if dirty, BDOS Close-File ($10), then zero the FCB slot.
FILE_CLOSE_ONE:
        CALL FILE_NUM_TO_FCB_A           ; $573C  CD B8 52
        JR Z,FILE_CLOSE_ONE_4            ; $573F  28 2F
        LD L,E                           ; $5741  6B
        PUSH BC                          ; $5742  C5
        LD A,(BC)                        ; $5743  0A
        LD D,B                           ; $5744  50
        LD E,C                           ; $5745  59
        INC DE                           ; $5746  13
        PUSH DE                          ; $5747  D5
        CP $02                           ; $5748  FE 02
        JR NZ,FILE_CLOSE_ONE_3           ; $574A  20 1A
        INC L                            ; $574C  2C
        DEC L                            ; $574D  2D
        JR NZ,FILE_CLOSE_ONE_1           ; $574E  20 02
        XOR A                            ; $5750  AF
        LD (BC),A                        ; $5751  02
FILE_CLOSE_ONE_1:
        LD HL,FILE_CLOSE_ONE_2           ; $5752  21 5D 57
        PUSH HL                          ; $5755  E5
        PUSH HL                          ; $5756  E5
        LD H,B                           ; $5757  60
        LD L,C                           ; $5758  69
        LD A,$1A                         ; $5759  3E 1A
        JR PUTC_FILE_1                   ; $575B  18 54
FILE_CLOSE_ONE_2:
        LD HL,$0027                      ; $575D  21 27 00
        ADD HL,BC                        ; $5760  09
        LD A,(HL)                        ; $5761  7E
        OR A                             ; $5762  B7
        CALL NZ,FILE_FLUSH_RECORD_CK     ; $5763  C4 02 57
FILE_CLOSE_ONE_3:
        POP DE                           ; $5766  D1
        CALL BDOS_SET_DMA_FCB            ; $5767  CD 78 58
        LD C,$10                         ; $576A  0E 10
        CALL $0005                       ; $576C  CD 05 00
        POP BC                           ; $576F  C1
FILE_CLOSE_ONE_4:
        LD D,$29                         ; $5770  16 29
        XOR A                            ; $5772  AF
FILE_CLOSE_ONE_5:
        LD (BC),A                        ; $5773  02
        INC BC                           ; $5774  03
        DEC D                            ; $5775  15
        JR NZ,FILE_CLOSE_ONE_5           ; $5776  20 FB
        RET                              ; $5778  C9
; [RE] LOC() function body: return current record/position number from the FCB (random offset $AE vs sequential $26).
FN_LOC_VALUE:
        CALL FILE_NUM_TO_FCB_NZ          ; $5779  CD B5 52
        JP Z,RAISE_BAD_FILE_NUMBER       ; $577C  CA 70 0D
        CP $03                           ; $577F  FE 03
        LD HL,$0026                      ; $5781  21 26 00
        JR NZ,FN_LOC_VALUE_1             ; $5784  20 03
        LD HL,$00AE                      ; $5786  21 AE 00
FN_LOC_VALUE_1:
        ADD HL,BC                        ; $5789  09
        LD A,(HL)                        ; $578A  7E
        DEC HL                           ; $578B  2B
        LD L,(HL)                        ; $578C  6E
        JP FP_LOAD_INT_TO_FAC_1          ; $578D  C3 4F 1E
; [RE] LOF()/file-size helper: read a length byte from the FCB ($10 field) and return it as a numeric value.
FN_LOF_VALUE:
        CALL FILE_NUM_TO_FCB_NZ          ; $5790  CD B5 52
        JP Z,RAISE_BAD_FILE_NUMBER       ; $5793  CA 70 0D
        LD HL,$0010                      ; $5796  21 10 00
        ADD HL,BC                        ; $5799  09
        LD A,(HL)                        ; $579A  7E
        JP FP_LOAD_INT_TO_FAC            ; $579B  C3 4D 1E
FN_LOF_VALUE_1:
        POP HL                           ; $579E  E1
        POP AF                           ; $579F  F1
; [RE] Write one byte (A) to the open sequential file buffer; when the 128-byte record fills, flush it via FILE_FLUSH_RECORD and advance the record number.
PUTC_FILE:
        PUSH HL                          ; $57A0  E5
        PUSH AF                          ; $57A1  F5
        LD HL,(PTRFIL)                   ; $57A2  2A 63 08
        LD A,(HL)                        ; $57A5  7E
        CP $01                           ; $57A6  FE 01
        JP Z,STMT_ERASE_4                ; $57A8  CA BB 46
        CP $03                           ; $57AB  FE 03
        JP Z,BLOCK_COPY_BC_2             ; $57AD  CA 36 5D
        POP AF                           ; $57B0  F1
PUTC_FILE_1:
        PUSH DE                          ; $57B1  D5
        PUSH BC                          ; $57B2  C5
        LD B,H                           ; $57B3  44
        LD C,L                           ; $57B4  4D
        PUSH AF                          ; $57B5  F5
        LD DE,$0027                      ; $57B6  11 27 00
        ADD HL,DE                        ; $57B9  19
        LD A,(HL)                        ; $57BA  7E
        CP $80                           ; $57BB  FE 80
        PUSH HL                          ; $57BD  E5
        CALL Z,FILE_FLUSH_RECORD         ; $57BE  CC FF 56
        POP HL                           ; $57C1  E1
        INC (HL)                         ; $57C2  34
        LD C,(HL)                        ; $57C3  4E
        LD B,$00                         ; $57C4  06 00
        INC HL                           ; $57C6  23
        POP AF                           ; $57C7  F1
        PUSH AF                          ; $57C8  F5
        LD D,(HL)                        ; $57C9  56
        CP $0D                           ; $57CA  FE 0D
        LD (HL),B                        ; $57CC  70
        JR Z,PUTC_FILE_2                 ; $57CD  28 05
        ADD A,$E0                        ; $57CF  C6 E0
        LD A,D                           ; $57D1  7A
        ADC A,B                          ; $57D2  88
        LD (HL),A                        ; $57D3  77
PUTC_FILE_2:
        ADD HL,BC                        ; $57D4  09
        POP AF                           ; $57D5  F1
        POP BC                           ; $57D6  C1
        POP DE                           ; $57D7  D1
        LD (HL),A                        ; $57D8  77
        POP HL                           ; $57D9  E1
        RET                              ; $57DA  C9
PUTC_FILE_3:
        DEC DE                           ; $57DB  1B
        DEC HL                           ; $57DC  2B
        LD (HL),E                        ; $57DD  73
        INC HL                           ; $57DE  23
        LD (HL),D                        ; $57DF  72
        INC HL                           ; $57E0  23
        LD (HL),$80                      ; $57E1  36 80
        INC HL                           ; $57E3  23
        LD (HL),$80                      ; $57E4  36 80
        POP HL                           ; $57E6  E1
        EX (SP),HL                       ; $57E7  E3
        LD B,H                           ; $57E8  44
        LD C,L                           ; $57E9  4D
        PUSH HL                          ; $57EA  E5
        LD HL,$0022                      ; $57EB  21 22 00
        ADD HL,BC                        ; $57EE  09
        LD (HL),E                        ; $57EF  73
        INC HL                           ; $57F0  23
        LD (HL),D                        ; $57F1  72
        INC HL                           ; $57F2  23
        LD (HL),$00                      ; $57F3  36 00
        POP HL                           ; $57F5  E1
        LD A,(TXTTAB_4)                  ; $57F6  3A 6F 08
        OR A                             ; $57F9  B7
        JR NZ,PUTC_FILE_4                ; $57FA  20 05
        CALL FILE_READ_RECORD_FCB        ; $57FC  CD 42 58
        POP HL                           ; $57FF  E1
        RET                              ; $5800  C9
PUTC_FILE_4:
        CALL FILE_FLUSH_RECORD           ; $5801  CD FF 56
        POP HL                           ; $5804  E1
        JP PRINT_RESET_STATE             ; $5805  C3 9A 18
; [RE] LDIR copy of a 128-byte (one CP/M record) block; BC preserved.
COPY_128_BLOCK:
        PUSH BC                          ; $5808  C5
        LD BC,$0080                      ; $5809  01 80 00
        LDIR                             ; $580C  ED B0
        POP BC                           ; $580E  C1
        RET                              ; $580F  C9
; [RE] Read next byte from the open sequential input file buffer; when the buffer is exhausted, refill it with the next record (sets carry/Ctrl-Z at EOF).
GETC_FILE:
        PUSH BC                          ; $5810  C5
        PUSH HL                          ; $5811  E5
GETC_FILE_1:
        LD HL,(PTRFIL)                   ; $5812  2A 63 08
        LD A,(HL)                        ; $5815  7E
        CP $03                           ; $5816  FE 03
        JP Z,BLOCK_COPY_BC_5             ; $5818  CA 63 5D
        LD BC,$0028                      ; $581B  01 28 00
        ADD HL,BC                        ; $581E  09
        LD A,(HL)                        ; $581F  7E
        OR A                             ; $5820  B7
        JR Z,GETC_FILE_2                 ; $5821  28 0C
        DEC HL                           ; $5823  2B
        LD A,(HL)                        ; $5824  7E
        INC HL                           ; $5825  23
        DEC (HL)                         ; $5826  35
        SUB (HL)                         ; $5827  96
        LD C,A                           ; $5828  4F
        ADD HL,BC                        ; $5829  09
        LD A,(HL)                        ; $582A  7E
        OR A                             ; $582B  B7
        POP HL                           ; $582C  E1
        POP BC                           ; $582D  C1
        RET                              ; $582E  C9
GETC_FILE_2:
        DEC HL                           ; $582F  2B
        LD A,(HL)                        ; $5830  7E
        OR A                             ; $5831  B7
        JR Z,GETC_FILE_3                 ; $5832  28 05
        CALL FILE_READ_RECORD            ; $5834  CD 3F 58
        JR NZ,GETC_FILE_1                ; $5837  20 D9
GETC_FILE_3:
        SCF                              ; $5839  37
        POP HL                           ; $583A  E1
        POP BC                           ; $583B  C1
        LD A,$1A                         ; $583C  3E 1A
        RET                              ; $583E  C9
; [RE] Read the next sequential record from the current file into its FCB buffer (entry that loads $0840 first).
FILE_READ_RECORD:
        LD HL,(PTRFIL)                   ; $583F  2A 63 08
; [RE] Bump the FCB record number and BDOS Read-Sequential into the buffer; sets the buffer-status byte (0=data, $80=EOF).
FILE_READ_RECORD_FCB:
        PUSH DE                          ; $5842  D5
        LD D,H                           ; $5843  54
        LD E,L                           ; $5844  5D
        INC DE                           ; $5845  13
        LD BC,$0025                      ; $5846  01 25 00
        ADD HL,BC                        ; $5849  09
        LD C,(HL)                        ; $584A  4E
        INC HL                           ; $584B  23
        LD B,(HL)                        ; $584C  46
        INC BC                           ; $584D  03
        DEC HL                           ; $584E  2B
        LD (HL),C                        ; $584F  71
        INC HL                           ; $5850  23
        LD (HL),B                        ; $5851  70
        INC HL                           ; $5852  23
        INC HL                           ; $5853  23
        PUSH HL                          ; $5854  E5
        LD BC,$007F                      ; $5855  01 7F 00
        LD (HL),$00                      ; $5858  36 00
        PUSH DE                          ; $585A  D5
        LD D,H                           ; $585B  54
        LD E,L                           ; $585C  5D
        INC DE                           ; $585D  13
        LDIR                             ; $585E  ED B0
        POP DE                           ; $5860  D1
        CALL BDOS_SET_DMA_FCB            ; $5861  CD 78 58
        LD A,(FILTAB_16)                 ; $5864  3A EF 08
        CALL BDOS_FILE_CALL              ; $5867  CD 44 5B
        OR A                             ; $586A  B7
        LD A,$00                         ; $586B  3E 00
        JR NZ,FILE_READ_RECORD_FCB_1     ; $586D  20 02
        LD A,$80                         ; $586F  3E 80
FILE_READ_RECORD_FCB_1:
        POP HL                           ; $5871  E1
        LD (HL),A                        ; $5872  77
        DEC HL                           ; $5873  2B
        LD (HL),A                        ; $5874  77
        OR A                             ; $5875  B7
        POP DE                           ; $5876  D1
        RET                              ; $5877  C9
; [RE] Point CP/M DMA at this file's 128-byte buffer (FCB+$28) via BDOS Set-DMA ($1A) before a read/write.
BDOS_SET_DMA_FCB:
        PUSH BC                          ; $5878  C5
        PUSH DE                          ; $5879  D5
        PUSH HL                          ; $587A  E5
        LD HL,$0028                      ; $587B  21 28 00
        ADD HL,DE                        ; $587E  19
        EX DE,HL                         ; $587F  EB
        LD C,$1A                         ; $5880  0E 1A
        CALL $0005                       ; $5882  CD 05 00
        POP HL                           ; $5885  E1
        POP DE                           ; $5886  D1
        POP BC                           ; $5887  C1
        RET                              ; $5888  C9
; [RE] GETC_FILE wrapper that detects Ctrl-Z ($1A) as end-of-file: marks the FCB EOF fields and returns carry on EOF.
GETC_FILE_EOF:
        CALL GETC_FILE                   ; $5889  CD 10 58
        RET C                            ; $588C  D8
        CP $1A                           ; $588D  FE 1A
        SCF                              ; $588F  37
        CCF                              ; $5890  3F
        RET NZ                           ; $5891  C0
        PUSH BC                          ; $5892  C5
        PUSH HL                          ; $5893  E5
        LD HL,(PTRFIL)                   ; $5894  2A 63 08
        LD BC,$0027                      ; $5897  01 27 00
        ADD HL,BC                        ; $589A  09
        LD (HL),$00                      ; $589B  36 00
        INC HL                           ; $589D  23
        LD (HL),$00                      ; $589E  36 00
        SCF                              ; $58A0  37
        POP HL                           ; $58A1  E1
        POP BC                           ; $58A2  C1
        RET                              ; $58A3  C9
; [RE] FRMEVL a string filename, then parse drive/name/ext into the scratch CP/M FCB at $08AA (uppercased, space-padded fields).
PARSE_FILENAME_TO_FCB:
        CALL FRMEVL_NOPAREN              ; $58A4  CD 90 1A
        PUSH HL                          ; $58A7  E5
        CALL FRETMP                      ; $58A8  CD 37 4A
        LD A,(HL)                        ; $58AB  7E
        OR A                             ; $58AC  B7
        JP Z,RAISE_BAD_FILE_NAME         ; $58AD  CA 7C 0D
        PUSH AF                          ; $58B0  F5
        INC HL                           ; $58B1  23
        LD E,(HL)                        ; $58B2  5E
        INC HL                           ; $58B3  23
        LD H,(HL)                        ; $58B4  66
        LD L,E                           ; $58B5  6B
        LD E,A                           ; $58B6  5F
        CP $02                           ; $58B7  FE 02
        JR C,PARSE_FILENAME_TO_FCB_1     ; $58B9  38 0A
        LD C,(HL)                        ; $58BB  4E
        INC HL                           ; $58BC  23
        LD A,(HL)                        ; $58BD  7E
        DEC E                            ; $58BE  1D
        CP $3A                           ; $58BF  FE 3A
        JR Z,PARSE_FILENAME_TO_FCB_2     ; $58C1  28 06
        DEC HL                           ; $58C3  2B
        INC E                            ; $58C4  1C
PARSE_FILENAME_TO_FCB_1:
        DEC HL                           ; $58C5  2B
        INC E                            ; $58C6  1C
        LD C,$40                         ; $58C7  0E 40
PARSE_FILENAME_TO_FCB_2:
        DEC E                            ; $58C9  1D
        JP Z,RAISE_BAD_FILE_NAME         ; $58CA  CA 7C 0D
        LD A,C                           ; $58CD  79
        SUB $40                          ; $58CE  D6 40
        JP C,RAISE_BAD_FILE_NAME         ; $58D0  DA 7C 0D
        CP $1B                           ; $58D3  FE 1B
        JP NC,RAISE_BAD_FILE_NAME        ; $58D5  D2 7C 0D
        LD BC,FILTAB_11                  ; $58D8  01 CD 08
        LD (BC),A                        ; $58DB  02
        INC BC                           ; $58DC  03
        LD D,$0B                         ; $58DD  16 0B
PARSE_FILENAME_TO_FCB_3:
        INC HL                           ; $58DF  23
PARSE_FILENAME_TO_FCB_4:
        DEC E                            ; $58E0  1D
        JP M,FCB_PAD_FIELD_1             ; $58E1  FA 11 59
        LD A,(HL)                        ; $58E4  7E
        CP $2E                           ; $58E5  FE 2E
        JR NZ,PARSE_FILENAME_TO_FCB_5    ; $58E7  20 08
        CALL FCB_PAD_FIELD               ; $58E9  CD FE 58
        POP AF                           ; $58EC  F1
        SCF                              ; $58ED  37
        PUSH AF                          ; $58EE  F5
        JR PARSE_FILENAME_TO_FCB_3       ; $58EF  18 EE
PARSE_FILENAME_TO_FCB_5:
        LD (BC),A                        ; $58F1  02
        INC BC                           ; $58F2  03
        INC HL                           ; $58F3  23
        DEC D                            ; $58F4  15
        JR NZ,PARSE_FILENAME_TO_FCB_4    ; $58F5  20 E9
PARSE_FILENAME_TO_FCB_6:
        XOR A                            ; $58F7  AF
        LD (FILTAB_14),A                 ; $58F8  32 D9 08
        POP AF                           ; $58FB  F1
        POP HL                           ; $58FC  E1
        RET                              ; $58FD  C9
; [RE] Pad the remaining name/extension field bytes of the FCB with spaces ($20) to the fixed width.
FCB_PAD_FIELD:
        LD A,D                           ; $58FE  7A
        CP $0B                           ; $58FF  FE 0B
        JP Z,RAISE_BAD_FILE_NAME         ; $5901  CA 7C 0D
        CP $03                           ; $5904  FE 03
        JP C,RAISE_BAD_FILE_NAME         ; $5906  DA 7C 0D
        RET Z                            ; $5909  C8
        LD A,$20                         ; $590A  3E 20
        LD (BC),A                        ; $590C  02
        INC BC                           ; $590D  03
        DEC D                            ; $590E  15
        JR FCB_PAD_FIELD                 ; $590F  18 ED
FCB_PAD_FIELD_1:
        INC D                            ; $5911  14
        DEC D                            ; $5912  15
        JR Z,PARSE_FILENAME_TO_FCB_6     ; $5913  28 E2
FCB_PAD_FIELD_2:
        LD A,$20                         ; $5915  3E 20
        LD (BC),A                        ; $5917  02
        INC BC                           ; $5918  03
        DEC D                            ; $5919  15
        JR NZ,FCB_PAD_FIELD_2            ; $591A  20 F9
        JR PARSE_FILENAME_TO_FCB_6       ; $591C  18 D9
; [RE] NAME statement handler (token $C0): rename a disk file (NAME old AS new).
STMT_NAME:
        CALL PARSE_FILENAME_TO_FCB       ; $591E  CD A4 58
        PUSH HL                          ; $5921  E5
        LD DE,$0080                      ; $5922  11 80 00
        LD C,$1A                         ; $5925  0E 1A
        CALL $0005                       ; $5927  CD 05 00
        LD DE,FILTAB_11                  ; $592A  11 CD 08
        LD C,$0F                         ; $592D  0E 0F
        CALL $0005                       ; $592F  CD 05 00
        INC A                            ; $5932  3C
        JP Z,RAISE_FILE_NOT_FOUND        ; $5933  CA 6D 0D
        LD HL,FILTAB_10                  ; $5936  21 BD 08
        LD DE,FILTAB_11                  ; $5939  11 CD 08
        LD B,$0C                         ; $593C  06 0C
STMT_NAME_1:
        LD A,(DE)                        ; $593E  1A
        LD (HL),A                        ; $593F  77
        INC HL                           ; $5940  23
        INC DE                           ; $5941  13
        DJNZ STMT_NAME_1                 ; $5942  10 FA
        POP HL                           ; $5944  E1
        CALL SYNCHR                      ; $5945  CD A3 45
        DEFB    'A'                      ; $5948  41  inline char arg consumed by the preceding CALL
        CALL SYNCHR                      ; $5949  CD A3 45
        DEFB    'S'                      ; $594C  53  inline char arg consumed by the preceding CALL
        CALL PARSE_FILENAME_TO_FCB       ; $594D  CD A4 58
        PUSH HL                          ; $5950  E5
        LD A,(FILTAB_11)                 ; $5951  3A CD 08
        LD HL,FILTAB_10                  ; $5954  21 BD 08
        CP (HL)                          ; $5957  BE
STMT_NAME_2:
        JP NZ,GETINT_POSITIVE_1          ; $5958  C2 EB 14
        LD DE,FILTAB_11                  ; $595B  11 CD 08
        LD C,$0F                         ; $595E  0E 0F
        CALL $0005                       ; $5960  CD 05 00
        INC A                            ; $5963  3C
        JP NZ,RAISE_FILE_ALREADY_EXISTS  ; $5964  C2 88 0D
        LD C,$17                         ; $5967  0E 17
        LD DE,FILTAB_10                  ; $5969  11 BD 08
        CALL $0005                       ; $596C  CD 05 00
        POP HL                           ; $596F  E1
        RET                              ; $5970  C9
; [RE] OPEN statement handler (token $B8): open a disk file on a channel.
STMT_OPEN:
        LD BC,PRINT_RESET_STATE          ; $5971  01 9A 18
        PUSH BC                          ; $5974  C5
        CALL FRMEVL_NOPAREN              ; $5975  CD 90 1A
        PUSH HL                          ; $5978  E5
        CALL FRETMP                      ; $5979  CD 37 4A
        LD A,(HL)                        ; $597C  7E
        OR A                             ; $597D  B7
        JP Z,RAISE_BAD_FILE_MODE         ; $597E  CA 6A 0D
        INC HL                           ; $5981  23
        LD C,(HL)                        ; $5982  4E
        INC HL                           ; $5983  23
        LD B,(HL)                        ; $5984  46
        LD A,(BC)                        ; $5985  0A
        AND $DF                          ; $5986  E6 DF
        LD D,$02                         ; $5988  16 02
        CP $4F                           ; $598A  FE 4F
        JR Z,STMT_OPEN_1                 ; $598C  28 0D
        LD D,$01                         ; $598E  16 01
        CP $49                           ; $5990  FE 49
        JR Z,STMT_OPEN_1                 ; $5992  28 07
        LD D,$03                         ; $5994  16 03
        CP $52                           ; $5996  FE 52
        JP NZ,RAISE_BAD_FILE_MODE        ; $5998  C2 6A 0D
STMT_OPEN_1:
        POP HL                           ; $599B  E1
        CALL SYNCHR                      ; $599C  CD A3 45
        DEFB    ','                      ; $599F  2C  inline char arg consumed by the preceding CALL
        PUSH DE                          ; $59A0  D5
        CP $23                           ; $59A1  FE 23
        CALL Z,CHRGET                    ; $59A3  CC E4 13
        CALL GETBYT                      ; $59A6  CD B2 20
        CALL SYNCHR                      ; $59A9  CD A3 45
        DEFB    ','                      ; $59AC  2C  inline char arg consumed by the preceding CALL
        LD A,E                           ; $59AD  7B
        OR A                             ; $59AE  B7
        JP Z,RAISE_BAD_FILE_NUMBER       ; $59AF  CA 70 0D
        POP DE                           ; $59B2  D1
STMT_OPEN_2:
        LD E,A                           ; $59B3  5F
        PUSH DE                          ; $59B4  D5
        CALL FILE_NUM_TO_FCB_A           ; $59B5  CD B8 52
        JP NZ,RAISE_FILE_ALREADY_OPEN    ; $59B8  C2 79 0D
        POP DE                           ; $59BB  D1
        PUSH BC                          ; $59BC  C5
        PUSH DE                          ; $59BD  D5
        CALL PARSE_FILENAME_TO_FCB       ; $59BE  CD A4 58
        POP DE                           ; $59C1  D1
        POP BC                           ; $59C2  C1
        PUSH BC                          ; $59C3  C5
        PUSH AF                          ; $59C4  F5
        LD A,D                           ; $59C5  7A
        CALL FILE_NUM_TO_FCB_2           ; $59C6  CD B1 5B
        POP AF                           ; $59C9  F1
        LD (DATA_LINE_TXTPTR_3),HL       ; $59CA  22 77 0B
        JR C,STMT_OPEN_3                 ; $59CD  38 15
        LD A,E                           ; $59CF  7B
        OR A                             ; $59D0  B7
        JP NZ,STMT_OPEN_3                ; $59D1  C2 E4 59
        LD HL,FILTAB_13                  ; $59D4  21 D6 08
        LD A,(HL)                        ; $59D7  7E
        CP $20                           ; $59D8  FE 20
        JR NZ,STMT_OPEN_3                ; $59DA  20 08
        LD (HL),$42                      ; $59DC  36 42
        INC HL                           ; $59DE  23
        LD (HL),$41                      ; $59DF  36 41
        INC HL                           ; $59E1  23
        LD (HL),$53                      ; $59E2  36 53
STMT_OPEN_3:
        POP HL                           ; $59E4  E1
        LD A,D                           ; $59E5  7A
        PUSH AF                          ; $59E6  F5
        LD (PTRFIL),HL                   ; $59E7  22 63 08
        PUSH HL                          ; $59EA  E5
        INC HL                           ; $59EB  23
        LD DE,FILTAB_11                  ; $59EC  11 CD 08
        LD C,$0C                         ; $59EF  0E 0C
STMT_OPEN_4:
        LD A,(DE)                        ; $59F1  1A
        LD (HL),A                        ; $59F2  77
        INC DE                           ; $59F3  13
        INC HL                           ; $59F4  23
        DEC C                            ; $59F5  0D
        JR NZ,STMT_OPEN_4                ; $59F6  20 F9
        LD (HL),$00                      ; $59F8  36 00
        LD DE,$0014                      ; $59FA  11 14 00
        ADD HL,DE                        ; $59FD  19
        LD (HL),$00                      ; $59FE  36 00
        POP DE                           ; $5A00  D1
        PUSH DE                          ; $5A01  D5
        INC DE                           ; $5A02  13
        CALL BDOS_SET_DMA_FCB            ; $5A03  CD 78 58
        POP HL                           ; $5A06  E1
        POP AF                           ; $5A07  F1
        PUSH AF                          ; $5A08  F5
        PUSH HL                          ; $5A09  E5
        CP $02                           ; $5A0A  FE 02
        JR NZ,STMT_OPEN_6                ; $5A0C  20 12
        PUSH DE                          ; $5A0E  D5
        LD C,$13                         ; $5A0F  0E 13
        CALL $0005                       ; $5A11  CD 05 00
        POP DE                           ; $5A14  D1
STMT_OPEN_5:
        LD C,$16                         ; $5A15  0E 16
        CALL $0005                       ; $5A17  CD 05 00
        INC A                            ; $5A1A  3C
        JP Z,RAISE_TOO_MANY_FILES        ; $5A1B  CA 85 0D
        JR STMT_OPEN_7                   ; $5A1E  18 13
STMT_OPEN_6:
        LD C,$0F                         ; $5A20  0E 0F
        CALL $0005                       ; $5A22  CD 05 00
        INC A                            ; $5A25  3C
        JR NZ,STMT_OPEN_7                ; $5A26  20 0B
        CALL RAM_DISPATCH_TRAMPOLINE     ; $5A28  CD 98 0C
        CP $03                           ; $5A2B  FE 03
        JP NZ,RAISE_FILE_NOT_FOUND       ; $5A2D  C2 6D 0D
        INC DE                           ; $5A30  13
        JR STMT_OPEN_5                   ; $5A31  18 E2
STMT_OPEN_7:
        POP DE                           ; $5A33  D1
        POP AF                           ; $5A34  F1
        LD (DE),A                        ; $5A35  12
        PUSH DE                          ; $5A36  D5
        LD HL,$0025                      ; $5A37  21 25 00
        ADD HL,DE                        ; $5A3A  19
        XOR A                            ; $5A3B  AF
        LD (HL),A                        ; $5A3C  77
        INC HL                           ; $5A3D  23
        LD (HL),A                        ; $5A3E  77
        INC HL                           ; $5A3F  23
        LD (HL),A                        ; $5A40  77
        INC HL                           ; $5A41  23
        LD (HL),A                        ; $5A42  77
        POP HL                           ; $5A43  E1
        LD A,(HL)                        ; $5A44  7E
        CP $03                           ; $5A45  FE 03
        JP Z,SUB_5A3B_1                  ; $5A47  CA 56 5A
        CP $01                           ; $5A4A  FE 01
        JP NZ,SUB_453A_3                 ; $5A4C  C2 99 45
        CALL FILE_READ_RECORD            ; $5A4F  CD 3F 58
        LD HL,(DATA_LINE_TXTPTR_3)       ; $5A52  2A 77 0B
        RET                              ; $5A55  C9
SUB_5A3B_1:
        LD BC,$0029                      ; $5A56  01 29 00
        ADD HL,BC                        ; $5A59  09
        LD C,$80                         ; $5A5A  0E 80
SUB_5A3B_2:
        LD (HL),B                        ; $5A5C  70
        INC HL                           ; $5A5D  23
        DEC C                            ; $5A5E  0D
        JR NZ,SUB_5A3B_2                 ; $5A5F  20 FB
        JP SUB_453A_3                    ; $5A61  C3 99 45
; [RE] SYSTEM statement handler (token $B7): exit GBASIC back to CP/M (shares the RET NZ pattern of the simple stubs).
STMT_SYSTEM:
        RET NZ                           ; $5A64  C0
        CALL CLOSE_ALL_FILES             ; $5A65  CD 4F 55
        CALL STMT_TEXT                   ; $5A68  CD D9 25
STMT_SYSTEM_1:
        JP $0000                         ; $5A6B  C3 00 00
; [RE] RESET statement handler (token $C5): close all files / reset the disk system.
STMT_RESET:
        RET NZ                           ; $5A6E  C0
        PUSH HL                          ; $5A6F  E5
        CALL CLOSE_ALL_FILES             ; $5A70  CD 4F 55
        LD C,$19                         ; $5A73  0E 19
        CALL $0005                       ; $5A75  CD 05 00
        PUSH AF                          ; $5A78  F5
        LD C,$0D                         ; $5A79  0E 0D
        CALL $0005                       ; $5A7B  CD 05 00
        POP AF                           ; $5A7E  F1
        LD E,A                           ; $5A7F  5F
        LD C,$0E                         ; $5A80  0E 0E
        CALL $0005                       ; $5A82  CD 05 00
        POP HL                           ; $5A85  E1
        RET                              ; $5A86  C9
; [RE] KILL statement: parse filename into the default FCB ($0080/$08AA) then BDOS delete-file (C=$13); '?' from BDOS -> error $0D4A. Reached via dispatch DEFW SUB_7E09 at $7A58.
STMT_KILL:
        CALL PARSE_FILENAME_TO_FCB       ; $5A87  CD A4 58
        PUSH HL                          ; $5A8A  E5
        LD DE,$0080                      ; $5A8B  11 80 00
        LD C,$1A                         ; $5A8E  0E 1A
        CALL $0005                       ; $5A90  CD 05 00
        LD DE,FILTAB_11                  ; $5A93  11 CD 08
        PUSH DE                          ; $5A96  D5
        LD C,$0F                         ; $5A97  0E 0F
        CALL $0005                       ; $5A99  CD 05 00
        INC A                            ; $5A9C  3C
        POP DE                           ; $5A9D  D1
        PUSH DE                          ; $5A9E  D5
        PUSH AF                          ; $5A9F  F5
        LD C,$10                         ; $5AA0  0E 10
        CALL NZ,$0005                    ; $5AA2  C4 05 00
        POP AF                           ; $5AA5  F1
        POP DE                           ; $5AA6  D1
        JP Z,RAISE_FILE_NOT_FOUND        ; $5AA7  CA 6D 0D
        LD C,$13                         ; $5AAA  0E 13
        CALL $0005                       ; $5AAC  CD 05 00
        POP HL                           ; $5AAF  E1
        RET                              ; $5AB0  C9
; [RE] FILES statement: directory listing. Optional filespec parsed into FCB ($08AA), '*' expanded to '?' (SUB_7EBB), BDOS set-DMA ($1A) + search-first ($11)/search-next ($12); prints each 11-char name with '.' between name and extension via OUTCHR, columns from print-col ($083B).
STMT_FILES:
        JR NZ,STMT_FILES_1               ; $5AB1  20 0D
        PUSH HL                          ; $5AB3  E5
        LD HL,FILTAB_11                  ; $5AB4  21 CD 08
        LD (HL),$00                      ; $5AB7  36 00
        INC HL                           ; $5AB9  23
        LD C,$0B                         ; $5ABA  0E 0B
        CALL FCB_WILD_EXPAND             ; $5ABC  CD 3D 5B
        POP HL                           ; $5ABF  E1
STMT_FILES_1:
        CALL NZ,PARSE_FILENAME_TO_FCB    ; $5AC0  C4 A4 58
        XOR A                            ; $5AC3  AF
        LD (FILTAB_14),A                 ; $5AC4  32 D9 08
        PUSH HL                          ; $5AC7  E5
        LD HL,FILTAB_12                  ; $5AC8  21 CE 08
        LD C,$08                         ; $5ACB  0E 08
        CALL FCB_WILD_IF_STAR            ; $5ACD  CD 39 5B
        LD HL,FILTAB_13                  ; $5AD0  21 D6 08
        LD C,$03                         ; $5AD3  0E 03
        CALL FCB_WILD_IF_STAR            ; $5AD5  CD 39 5B
        LD DE,$0080                      ; $5AD8  11 80 00
        LD C,$1A                         ; $5ADB  0E 1A
        CALL $0005                       ; $5ADD  CD 05 00
        LD DE,FILTAB_11                  ; $5AE0  11 CD 08
        LD C,$11                         ; $5AE3  0E 11
        CALL $0005                       ; $5AE5  CD 05 00
        CP $FF                           ; $5AE8  FE FF
        JP Z,RAISE_FILE_NOT_FOUND        ; $5AEA  CA 6D 0D
STMT_FILES_2:
        AND $03                          ; $5AED  E6 03
        ADD A,A                          ; $5AEF  87
        ADD A,A                          ; $5AF0  87
        ADD A,A                          ; $5AF1  87
        ADD A,A                          ; $5AF2  87
        ADD A,A                          ; $5AF3  87
        LD C,A                           ; $5AF4  4F
        LD B,$00                         ; $5AF5  06 00
        LD HL,$0081                      ; $5AF7  21 81 00
        ADD HL,BC                        ; $5AFA  09
        LD C,$0B                         ; $5AFB  0E 0B
STMT_FILES_3:
        LD A,(HL)                        ; $5AFD  7E
        INC HL                           ; $5AFE  23
        CALL OUTCHR                      ; $5AFF  CD 91 42
        LD A,C                           ; $5B02  79
        CP $04                           ; $5B03  FE 04
        JR NZ,STMT_FILES_5               ; $5B05  20 0A
        LD A,(HL)                        ; $5B07  7E
        CP $20                           ; $5B08  FE 20
        JR Z,STMT_FILES_4                ; $5B0A  28 02
        LD A,$2E                         ; $5B0C  3E 2E
STMT_FILES_4:
        CALL OUTCHR                      ; $5B0E  CD 91 42
STMT_FILES_5:
        DEC C                            ; $5B11  0D
        JR NZ,STMT_FILES_3               ; $5B12  20 E9
        LD A,(SUB_0B2A_2)                ; $5B14  3A 34 0B
        ADD A,$0F                        ; $5B17  C6 0F
        LD D,A                           ; $5B19  57
        LD A,(SUB_0752_34)               ; $5B1A  3A 5E 08
        CP D                             ; $5B1D  BA
        JR C,SUB_5B25_1                  ; $5B1E  38 08
        LD A,$20                         ; $5B20  3E 20
        CALL OUTCHR                      ; $5B22  CD 91 42
        CALL OUTCHR                      ; $5B25  CD 91 42
SUB_5B25_1:
        CALL C,CRLF                      ; $5B28  DC 06 44
        LD DE,FILTAB_11                  ; $5B2B  11 CD 08
        LD C,$12                         ; $5B2E  0E 12
        CALL $0005                       ; $5B30  CD 05 00
        CP $FF                           ; $5B33  FE FF
        JR NZ,STMT_FILES_2               ; $5B35  20 B6
        POP HL                           ; $5B37  E1
        RET                              ; $5B38  C9
; [RE] If FCB byte is '*' fall into FCB_WILD_EXPAND, else return: handles the leading-'*' wildcard in a FILES/KILL filespec.
FCB_WILD_IF_STAR:
        LD A,(HL)                        ; $5B39  7E
        CP $2A                           ; $5B3A  FE 2A
        RET NZ                           ; $5B3C  C0
; [RE] Fill C FCB name/ext bytes with '?' ($3F) to turn a '*' wildcard into an all-match field for BDOS directory search.
FCB_WILD_EXPAND:
        LD (HL),$3F                      ; $5B3D  36 3F
        INC HL                           ; $5B3F  23
        DEC C                            ; $5B40  0D
        JR NZ,FCB_WILD_EXPAND            ; $5B41  20 FA
        RET                              ; $5B43  C9
; [RE] BDOS file-op wrapper: issue BDOS function (A->C) with DE=FCB, then bump the random-record/overflow counter at FCB+$21..$23; map BDOS A-result to BASIC code (0=ok/RET Z, 5=dir-full err $0D62, else 1/2). Used by OPEN/CLOSE/random GET-PUT.
BDOS_FILE_CALL:
        PUSH DE                          ; $5B44  D5
        LD C,A                           ; $5B45  4F
        PUSH BC                          ; $5B46  C5
        CALL $0005                       ; $5B47  CD 05 00
        POP BC                           ; $5B4A  C1
        POP DE                           ; $5B4B  D1
        PUSH AF                          ; $5B4C  F5
        LD HL,$0021                      ; $5B4D  21 21 00
        ADD HL,DE                        ; $5B50  19
        INC (HL)                         ; $5B51  34
        JR NZ,BDOS_FILE_CALL_1           ; $5B52  20 06
        INC HL                           ; $5B54  23
        INC (HL)                         ; $5B55  34
        JR NZ,BDOS_FILE_CALL_1           ; $5B56  20 02
        INC HL                           ; $5B58  23
        INC (HL)                         ; $5B59  34
BDOS_FILE_CALL_1:
        LD A,C                           ; $5B5A  79
        CP $22                           ; $5B5B  FE 22
        JR NZ,BDOS_FILE_CALL_2           ; $5B5D  20 0F
        POP AF                           ; $5B5F  F1
        OR A                             ; $5B60  B7
        RET Z                            ; $5B61  C8
        CP $05                           ; $5B62  FE 05
        JP Z,RAISE_TOO_MANY_FILES        ; $5B64  CA 85 0D
        CP $03                           ; $5B67  FE 03
        LD A,$01                         ; $5B69  3E 01
        RET Z                            ; $5B6B  C8
        INC A                            ; $5B6C  3C
        RET                              ; $5B6D  C9
BDOS_FILE_CALL_2:
        POP AF                           ; $5B6E  F1
        RET                              ; $5B6F  C9
; [RE] Sequential file read into the data buffer: set DMA via FCB cursor, loop BDOS read-sequential ($14) of 128-byte records (SUB_7F25 sets FCB ptr), copying each record into the user buffer until DE count exhausted.
FILE_READ_RECORDS:
        EX DE,HL                         ; $5B70  EB
        CALL STRING_SPACE_ROOM_CHECK     ; $5B71  CD A3 5B
        LD HL,(PTRFIL)                   ; $5B74  2A 63 08
        PUSH HL                          ; $5B77  E5
        LD BC,$002A                      ; $5B78  01 2A 00
        ADD HL,BC                        ; $5B7B  09
        CALL COPY_128_BLOCK              ; $5B7C  CD 08 58
        DEC DE                           ; $5B7F  1B
        POP HL                           ; $5B80  E1
        LD BC,$0021                      ; $5B81  01 21 00
        ADD HL,BC                        ; $5B84  09
        INC (HL)                         ; $5B85  34
FILE_READ_RECORDS_1:
        CALL STRING_SPACE_ROOM_CHECK     ; $5B86  CD A3 5B
        PUSH DE                          ; $5B89  D5
        LD C,$1A                         ; $5B8A  0E 1A
        CALL $0005                       ; $5B8C  CD 05 00
        LD HL,(PTRFIL)                   ; $5B8F  2A 63 08
        INC HL                           ; $5B92  23
        EX DE,HL                         ; $5B93  EB
        LD C,$14                         ; $5B94  0E 14
        CALL $0005                       ; $5B96  CD 05 00
        OR A                             ; $5B99  B7
        POP DE                           ; $5B9A  D1
        LD HL,$0080                      ; $5B9B  21 80 00
        ADD HL,DE                        ; $5B9E  19
        RET NZ                           ; $5B9F  C0
        EX DE,HL                         ; $5BA0  EB
        JR FILE_READ_RECORDS_1           ; $5BA1  18 E3
; [RE] Compute the FCB working pointer (current file-table entry $0B48 - $2A*1 reverse offset) and verify stack room (SUB_691F/SUB_781A); used before each BDOS sequential transfer.
STRING_SPACE_ROOM_CHECK:
        LD HL,(FRETOP)                   ; $5BA3  2A 6B 0B
        LD BC,$FF2A                      ; $5BA6  01 2A FF
        ADD HL,BC                        ; $5BA9  09
        CALL CMP_HL_DE                   ; $5BAA  CD 9D 45
        RET NC                           ; $5BAD  D0
        JP RUN_CLEAR_AND_GO              ; $5BAE  C3 A1 54
; [RE] Range-check the file number against the open-file table limit ($0C97) via DCOMPR.
FILE_NUM_TO_FCB_2:
        CP $03                           ; $5BB1  FE 03
        RET NZ                           ; $5BB3  C0
        DEC HL                           ; $5BB4  2B
        CALL CHRGET                      ; $5BB5  CD E4 13
        PUSH DE                          ; $5BB8  D5
        LD DE,$0080                      ; $5BB9  11 80 00
        JR Z,FILE_NUM_TO_FCB_2_1         ; $5BBC  28 05
        PUSH BC                          ; $5BBE  C5
        CALL GETINT_CHRGET_POS           ; $5BBF  CD E4 14
        POP BC                           ; $5BC2  C1
FILE_NUM_TO_FCB_2_1:
        PUSH HL                          ; $5BC3  E5
        LD HL,(FILE_RECLEN_DEFAULT)      ; $5BC4  2A BA 0C
        CALL CMP_HL_DE                   ; $5BC7  CD 9D 45
        JP C,GETINT_POSITIVE_1           ; $5BCA  DA EB 14
        LD HL,$00A9                      ; $5BCD  21 A9 00
        ADD HL,BC                        ; $5BD0  09
        LD (HL),E                        ; $5BD1  73
        INC HL                           ; $5BD2  23
        LD (HL),D                        ; $5BD3  72
        XOR A                            ; $5BD4  AF
        LD E,$07                         ; $5BD5  1E 07
FILE_NUM_TO_FCB_2_2:
        INC HL                           ; $5BD7  23
        LD (HL),A                        ; $5BD8  77
        DEC E                            ; $5BD9  1D
        JR NZ,FILE_NUM_TO_FCB_2_2        ; $5BDA  20 FB
        POP HL                           ; $5BDC  E1
        POP DE                           ; $5BDD  D1
        RET                              ; $5BDE  C9
; [RE] PUT statement handler (token $BB): write a random-file record. GET (token $BA) enters one byte later at $7F62.
STMT_PUT:
        OR $AF                           ; $5BDF  F6 AF
        LD (ILLEGAL_DIRECT_CHECK_4),A    ; $5BE1  32 3A 5E
        CALL Z,EVAL_CHANNEL_OR_ITEM      ; $5BE4  CC CA 0F
        CALL FILE_NUM_TO_FCB             ; $5BE7  CD A9 52
STMT_PUT_1:
        CP $03                           ; $5BEA  FE 03
        JP NZ,RAISE_BAD_FILE_MODE        ; $5BEC  C2 6A 0D
        PUSH BC                          ; $5BEF  C5
        PUSH HL                          ; $5BF0  E5
        LD HL,$00AD                      ; $5BF1  21 AD 00
        ADD HL,BC                        ; $5BF4  09
        LD E,(HL)                        ; $5BF5  5E
        INC HL                           ; $5BF6  23
        LD D,(HL)                        ; $5BF7  56
        INC DE                           ; $5BF8  13
        EX (SP),HL                       ; $5BF9  E3
        LD A,(HL)                        ; $5BFA  7E
        CP $2C                           ; $5BFB  FE 2C
        CALL Z,GETINT_CHRGET_POS         ; $5BFD  CC E4 14
        DEC HL                           ; $5C00  2B
        CALL CHRGET                      ; $5C01  CD E4 13
        JP NZ,RAISE_SYNTAX_ERROR         ; $5C04  C2 92 0D
        EX (SP),HL                       ; $5C07  E3
        LD A,E                           ; $5C08  7B
        OR D                             ; $5C09  B2
        JP Z,RAISE_BAD_RECORD_NUMBER     ; $5C0A  CA 7F 0D
        DEC HL                           ; $5C0D  2B
        LD (HL),E                        ; $5C0E  73
        INC HL                           ; $5C0F  23
        LD (HL),D                        ; $5C10  72
        DEC DE                           ; $5C11  1B
        POP HL                           ; $5C12  E1
        POP BC                           ; $5C13  C1
        PUSH HL                          ; $5C14  E5
        PUSH BC                          ; $5C15  C5
        LD HL,$00B0                      ; $5C16  21 B0 00
        ADD HL,BC                        ; $5C19  09
        XOR A                            ; $5C1A  AF
        LD (HL),A                        ; $5C1B  77
        INC HL                           ; $5C1C  23
        LD (HL),A                        ; $5C1D  77
        LD HL,$00A9                      ; $5C1E  21 A9 00
        ADD HL,BC                        ; $5C21  09
        LD A,(HL)                        ; $5C22  7E
        INC HL                           ; $5C23  23
        LD H,(HL)                        ; $5C24  66
        LD L,A                           ; $5C25  6F
        EX DE,HL                         ; $5C26  EB
        PUSH DE                          ; $5C27  D5
        PUSH HL                          ; $5C28  E5
        LD HL,$0080                      ; $5C29  21 80 00
        CALL CMP_HL_DE                   ; $5C2C  CD 9D 45
        POP HL                           ; $5C2F  E1
        JR NZ,STMT_PUT_2                 ; $5C30  20 05
        LD DE,$0000                      ; $5C32  11 00 00
        JR STMT_PUT_9                    ; $5C35  18 38
STMT_PUT_2:
        LD B,D                           ; $5C37  42
        LD C,E                           ; $5C38  4B
        LD A,$10                         ; $5C39  3E 10
        EX DE,HL                         ; $5C3B  EB
        LD HL,$0000                      ; $5C3C  21 00 00
        PUSH HL                          ; $5C3F  E5
STMT_PUT_3:
        ADD HL,HL                        ; $5C40  29
        EX (SP),HL                       ; $5C41  E3
        JR NC,STMT_PUT_4                 ; $5C42  30 04
        ADD HL,HL                        ; $5C44  29
        INC HL                           ; $5C45  23
        JR STMT_PUT_5                    ; $5C46  18 01
STMT_PUT_4:
        ADD HL,HL                        ; $5C48  29
STMT_PUT_5:
        EX (SP),HL                       ; $5C49  E3
        EX DE,HL                         ; $5C4A  EB
        ADD HL,HL                        ; $5C4B  29
        EX DE,HL                         ; $5C4C  EB
        JR NC,STMT_PUT_7                 ; $5C4D  30 06
        ADD HL,BC                        ; $5C4F  09
        EX (SP),HL                       ; $5C50  E3
        JR NC,STMT_PUT_6                 ; $5C51  30 01
        INC HL                           ; $5C53  23
STMT_PUT_6:
        EX (SP),HL                       ; $5C54  E3
STMT_PUT_7:
        DEC A                            ; $5C55  3D
        JR NZ,STMT_PUT_3                 ; $5C56  20 E8
        LD A,L                           ; $5C58  7D
        AND $7F                          ; $5C59  E6 7F
        LD E,A                           ; $5C5B  5F
        LD D,$00                         ; $5C5C  16 00
        POP BC                           ; $5C5E  C1
        LD A,L                           ; $5C5F  7D
        LD L,H                           ; $5C60  6C
        LD H,C                           ; $5C61  61
        ADD HL,HL                        ; $5C62  29
        JP C,GETINT_POSITIVE_1           ; $5C63  DA EB 14
        RLA                              ; $5C66  17
        JR NC,STMT_PUT_8                 ; $5C67  30 01
        INC HL                           ; $5C69  23
STMT_PUT_8:
        LD A,B                           ; $5C6A  78
        OR A                             ; $5C6B  B7
        JP NZ,GETINT_POSITIVE_1          ; $5C6C  C2 EB 14
STMT_PUT_9:
        LD (ILLEGAL_DIRECT_CHECK_1),HL   ; $5C6F  22 34 5E
        POP HL                           ; $5C72  E1
        POP BC                           ; $5C73  C1
        PUSH HL                          ; $5C74  E5
        LD HL,$00B2                      ; $5C75  21 B2 00
        ADD HL,BC                        ; $5C78  09
        LD (ILLEGAL_DIRECT_CHECK_2),HL   ; $5C79  22 36 5E
STMT_PUT_10:
        LD HL,$0029                      ; $5C7C  21 29 00
        ADD HL,BC                        ; $5C7F  09
        ADD HL,DE                        ; $5C80  19
        LD (ILLEGAL_DIRECT_CHECK_3),HL   ; $5C81  22 38 5E
        POP HL                           ; $5C84  E1
        PUSH HL                          ; $5C85  E5
        LD HL,$0080                      ; $5C86  21 80 00
        LD A,L                           ; $5C89  7D
        SUB E                            ; $5C8A  93
        LD L,A                           ; $5C8B  6F
        LD A,H                           ; $5C8C  7C
        SBC A,D                          ; $5C8D  9A
        LD H,A                           ; $5C8E  67
        POP DE                           ; $5C8F  D1
        PUSH DE                          ; $5C90  D5
        CALL CMP_HL_DE                   ; $5C91  CD 9D 45
        JR C,STMT_PUT_11                 ; $5C94  38 02
        LD H,D                           ; $5C96  62
        LD L,E                           ; $5C97  6B
STMT_PUT_11:
        LD A,(ILLEGAL_DIRECT_CHECK_4)    ; $5C98  3A 3A 5E
        OR A                             ; $5C9B  B7
        JR Z,STMT_PUT_14                 ; $5C9C  28 3B
        LD DE,$0080                      ; $5C9E  11 80 00
        CALL CMP_HL_DE                   ; $5CA1  CD 9D 45
        JR NC,STMT_PUT_12                ; $5CA4  30 05
        PUSH HL                          ; $5CA6  E5
        CALL FIELD_WRITE_RECORD+1        ; $5CA7  CD F5 5C
        POP HL                           ; $5CAA  E1
STMT_PUT_12:
        PUSH BC                          ; $5CAB  C5
        LD B,H                           ; $5CAC  44
        LD C,L                           ; $5CAD  4D
        LD HL,(ILLEGAL_DIRECT_CHECK_3)   ; $5CAE  2A 38 5E
        EX DE,HL                         ; $5CB1  EB
        LD HL,(ILLEGAL_DIRECT_CHECK_2)   ; $5CB2  2A 36 5E
        CALL BLOCK_COPY_BC               ; $5CB5  CD 2A 5D
        LD (ILLEGAL_DIRECT_CHECK_2),HL   ; $5CB8  22 36 5E
        LD D,B                           ; $5CBB  50
        LD E,C                           ; $5CBC  59
        POP BC                           ; $5CBD  C1
        CALL FIELD_WRITE_RECORD          ; $5CBE  CD F4 5C
STMT_PUT_13:
        POP HL                           ; $5CC1  E1
        LD A,L                           ; $5CC2  7D
        SUB E                            ; $5CC3  93
        LD L,A                           ; $5CC4  6F
        LD A,H                           ; $5CC5  7C
        SBC A,D                          ; $5CC6  9A
        LD H,A                           ; $5CC7  67
        OR L                             ; $5CC8  B5
        LD DE,$0000                      ; $5CC9  11 00 00
        PUSH HL                          ; $5CCC  E5
        LD HL,(ILLEGAL_DIRECT_CHECK_1)   ; $5CCD  2A 34 5E
        INC HL                           ; $5CD0  23
        LD (ILLEGAL_DIRECT_CHECK_1),HL   ; $5CD1  22 34 5E
        JR NZ,STMT_PUT_10                ; $5CD4  20 A6
        POP HL                           ; $5CD6  E1
        POP HL                           ; $5CD7  E1
        RET                              ; $5CD8  C9
STMT_PUT_14:
        PUSH HL                          ; $5CD9  E5
        CALL FIELD_WRITE_RECORD+1        ; $5CDA  CD F5 5C
        POP HL                           ; $5CDD  E1
        PUSH BC                          ; $5CDE  C5
        LD B,H                           ; $5CDF  44
        LD C,L                           ; $5CE0  4D
        LD HL,(ILLEGAL_DIRECT_CHECK_2)   ; $5CE1  2A 36 5E
        EX DE,HL                         ; $5CE4  EB
        LD HL,(ILLEGAL_DIRECT_CHECK_3)   ; $5CE5  2A 38 5E
        CALL BLOCK_COPY_BC               ; $5CE8  CD 2A 5D
        EX DE,HL                         ; $5CEB  EB
        LD (ILLEGAL_DIRECT_CHECK_2),HL   ; $5CEC  22 36 5E
        LD D,B                           ; $5CEF  50
        LD E,C                           ; $5CF0  59
        POP BC                           ; $5CF1  C1
        JR STMT_PUT_13                   ; $5CF2  18 CD
; [RE] Random-file PUT inner helper: walk the FIELD descriptor chain (FCB+$AB pointer pair), advance the write cursor (SUB_81AC_1), and on buffer-full dispatch the record write (SUB_7B22_3 at $7B5D). Entered at $8077 (skip the OR $AF flag-set) for the no-flag variant.
FIELD_WRITE_RECORD:
        OR $AF                           ; $5CF4  F6 AF
        LD (TXTTAB_4),A                  ; $5CF6  32 6F 08
        PUSH BC                          ; $5CF9  C5
        PUSH DE                          ; $5CFA  D5
        PUSH HL                          ; $5CFB  E5
        LD HL,(ILLEGAL_DIRECT_CHECK_1)   ; $5CFC  2A 34 5E
        EX DE,HL                         ; $5CFF  EB
        LD HL,$00AB                      ; $5D00  21 AB 00
        ADD HL,BC                        ; $5D03  09
        PUSH HL                          ; $5D04  E5
        LD A,(HL)                        ; $5D05  7E
        INC HL                           ; $5D06  23
        LD H,(HL)                        ; $5D07  66
        LD L,A                           ; $5D08  6F
        INC DE                           ; $5D09  13
        CALL CMP_HL_DE                   ; $5D0A  CD 9D 45
        POP HL                           ; $5D0D  E1
        LD (HL),E                        ; $5D0E  73
        INC HL                           ; $5D0F  23
        LD (HL),D                        ; $5D10  72
        JR NZ,SUB_5D0D_1                 ; $5D11  20 06
        LD A,(TXTTAB_4)                  ; $5D13  3A 6F 08
        OR A                             ; $5D16  B7
        JR Z,FIELD_WRITE_RECORD_RET      ; $5D17  28 0D
SUB_5D0D_1:
        LD HL,FIELD_WRITE_RECORD_RET     ; $5D19  21 26 5D
        PUSH HL                          ; $5D1C  E5
        PUSH BC                          ; $5D1D  C5
        PUSH HL                          ; $5D1E  E5
        LD HL,$0026                      ; $5D1F  21 26 00
        ADD HL,BC                        ; $5D22  09
        JP PUTC_FILE_3                   ; $5D23  C3 DB 57
; Common register-restore epilogue of FIELD_WRITE_RECORD (POP HL/DE/BC; RET). The DEFW at $019F referencing it is a statement-dispatch-table misalignment artifact, not a real handler. Was SUB_5D26. [RE]
FIELD_WRITE_RECORD_RET:
        POP HL                           ; $5D26  E1
        POP DE                           ; $5D27  D1
        POP BC                           ; $5D28  C1
        RET                              ; $5D29  C9
; [RE] Copy BC bytes (HL)->(DE) for FIELD/GET/PUT record buffering; preserves BC.
BLOCK_COPY_BC:
        PUSH BC                          ; $5D2A  C5
BLOCK_COPY_BC_1:
        LD A,(HL)                        ; $5D2B  7E
        LD (DE),A                        ; $5D2C  12
        INC HL                           ; $5D2D  23
        INC DE                           ; $5D2E  13
        DEC BC                           ; $5D2F  0B
        LD A,B                           ; $5D30  78
        OR C                             ; $5D31  B1
        JR NZ,BLOCK_COPY_BC_1            ; $5D32  20 F7
        POP BC                           ; $5D34  C1
        RET                              ; $5D35  C9
BLOCK_COPY_BC_2:
        POP AF                           ; $5D36  F1
        PUSH DE                          ; $5D37  D5
        PUSH BC                          ; $5D38  C5
        PUSH AF                          ; $5D39  F5
        LD B,H                           ; $5D3A  44
        LD C,L                           ; $5D3B  4D
        CALL FILE_BUF_REMAIN_BC          ; $5D3C  CD 90 5D
        JP Z,RAISE_FIELD_OVERFLOW        ; $5D3F  CA 82 0D
BLOCK_COPY_BC_3:
        CALL FCB_STORE_POSPTR            ; $5D42  CD 85 5D
        LD HL,$00B1                      ; $5D45  21 B1 00
        ADD HL,BC                        ; $5D48  09
        ADD HL,DE                        ; $5D49  19
        POP AF                           ; $5D4A  F1
        LD (HL),A                        ; $5D4B  77
        PUSH AF                          ; $5D4C  F5
        LD HL,$0028                      ; $5D4D  21 28 00
        ADD HL,BC                        ; $5D50  09
        LD D,(HL)                        ; $5D51  56
        LD (HL),$00                      ; $5D52  36 00
        CP $0D                           ; $5D54  FE 0D
        JR Z,BLOCK_COPY_BC_4             ; $5D56  28 06
        ADD A,$E0                        ; $5D58  C6 E0
        LD A,D                           ; $5D5A  7A
        ADC A,$00                        ; $5D5B  CE 00
        LD (HL),A                        ; $5D5D  77
BLOCK_COPY_BC_4:
        POP AF                           ; $5D5E  F1
        POP BC                           ; $5D5F  C1
        POP DE                           ; $5D60  D1
        POP HL                           ; $5D61  E1
        RET                              ; $5D62  C9
BLOCK_COPY_BC_5:
        PUSH DE                          ; $5D63  D5
        CALL FILE_BUF_REMAIN             ; $5D64  CD 8E 5D
        JP Z,RAISE_FIELD_OVERFLOW        ; $5D67  CA 82 0D
        CALL FCB_STORE_POSPTR            ; $5D6A  CD 85 5D
        LD HL,$00B1                      ; $5D6D  21 B1 00
        ADD HL,BC                        ; $5D70  09
        ADD HL,DE                        ; $5D71  19
        LD A,(HL)                        ; $5D72  7E
        OR A                             ; $5D73  B7
        POP DE                           ; $5D74  D1
        POP HL                           ; $5D75  E1
        POP BC                           ; $5D76  C1
        RET                              ; $5D77  C9
; [RE] Load the FIELD buffer base pointer pair (FCB+$A9) into DE.
FCB_LOAD_BUFPTR:
        LD HL,$00A9                      ; $5D78  21 A9 00
        JR FCB_LOAD_POSPTR_1             ; $5D7B  18 03
; [RE] Load the FIELD current-position pointer pair (FCB+$B0) into DE.
FCB_LOAD_POSPTR:
        LD HL,$00B0                      ; $5D7D  21 B0 00
FCB_LOAD_POSPTR_1:
        ADD HL,BC                        ; $5D80  09
        LD E,(HL)                        ; $5D81  5E
        INC HL                           ; $5D82  23
        LD D,(HL)                        ; $5D83  56
        RET                              ; $5D84  C9
; [RE] Advance (INC DE) and store the FIELD current-position pointer (FCB+$B0).
FCB_STORE_POSPTR:
        INC DE                           ; $5D85  13
        LD HL,$00B0                      ; $5D86  21 B0 00
        ADD HL,BC                        ; $5D89  09
        LD (HL),E                        ; $5D8A  73
        INC HL                           ; $5D8B  23
        LD (HL),D                        ; $5D8C  72
        RET                              ; $5D8D  C9
; [RE] Set BC=FCB then compute remaining bytes in the FIELD buffer: position ptr (FCB+$B0) vs buffer base (FCB+$A9); Z when buffer exhausted (EOF/refill needed).
FILE_BUF_REMAIN:
        LD B,H                           ; $5D8E  44
        LD C,L                           ; $5D8F  4D
; [RE] Remaining-bytes-in-buffer test with BC already = FCB base (FCB+$B0 position vs FCB+$A9 base); returns Z if empty.
FILE_BUF_REMAIN_BC:
        CALL FCB_LOAD_POSPTR             ; $5D90  CD 7D 5D
        PUSH DE                          ; $5D93  D5
        CALL FCB_LOAD_BUFPTR             ; $5D94  CD 78 5D
        EX DE,HL                         ; $5D97  EB
        POP DE                           ; $5D98  D1
        CALL CMP_HL_DE                   ; $5D99  CD 9D 45
        RET                              ; $5D9C  C9
FILE_BUF_REMAIN_BC_1:
        CALL CHRGET                      ; $5D9D  CD E4 13
        LD (DATA_LINE_TXTPTR_3),HL       ; $5DA0  22 77 0B
        CALL RENUM_PATCH_LINEREFS        ; $5DA3  CD 8D 23
        CALL PROG_UNSCRAMBLE             ; $5DA6  CD B4 5D
        LD A,$FE                         ; $5DA9  3E FE
        CALL SAVE_WRITE_PROGRAM          ; $5DAB  CD 03 55
        CALL PROG_SCRAMBLE               ; $5DAE  CD EB 5D
        JP SUB_453A_3                    ; $5DB1  C3 99 45
; [RE] MS BASIC-80 protected-program DECODE: XOR each program byte ($0846..$0B6F) against two rotating key tables (period 13 from FN_TAN_2, period 11 from FN_RND_5) plus rotating additive constants -- the 'saved with ,P' obfuscation reversal.
PROG_UNSCRAMBLE:
        LD BC,SUB_0D04_3                 ; $5DB4  01 0B 0D
        LD HL,(TXTTAB)                   ; $5DB7  2A 69 08
        EX DE,HL                         ; $5DBA  EB
PROG_UNSCRAMBLE_1:
        LD HL,(VARTAB)                   ; $5DBB  2A 92 0B
        CALL CMP_HL_DE                   ; $5DBE  CD 9D 45
        RET Z                            ; $5DC1  C8
        LD HL,FN_TAN_2                   ; $5DC2  21 80 3B
        LD A,L                           ; $5DC5  7D
        ADD A,C                          ; $5DC6  81
        LD L,A                           ; $5DC7  6F
        LD A,H                           ; $5DC8  7C
        ADC A,$00                        ; $5DC9  CE 00
        LD H,A                           ; $5DCB  67
        LD A,(DE)                        ; $5DCC  1A
        SUB B                            ; $5DCD  90
        XOR (HL)                         ; $5DCE  AE
        PUSH AF                          ; $5DCF  F5
        LD HL,FN_RND_5                   ; $5DD0  21 30 3B
        LD A,L                           ; $5DD3  7D
        ADD A,B                          ; $5DD4  80
        LD L,A                           ; $5DD5  6F
        LD A,H                           ; $5DD6  7C
        ADC A,$00                        ; $5DD7  CE 00
        LD H,A                           ; $5DD9  67
        POP AF                           ; $5DDA  F1
        XOR (HL)                         ; $5DDB  AE
        ADD A,C                          ; $5DDC  81
        LD (DE),A                        ; $5DDD  12
        INC DE                           ; $5DDE  13
        DEC C                            ; $5DDF  0D
        JR NZ,PROG_UNSCRAMBLE_2          ; $5DE0  20 02
        LD C,$0B                         ; $5DE2  0E 0B
PROG_UNSCRAMBLE_2:
        DEC B                            ; $5DE4  05
        JR NZ,PROG_UNSCRAMBLE_1          ; $5DE5  20 D4
        LD B,$0D                         ; $5DE7  06 0D
        JR PROG_UNSCRAMBLE_1             ; $5DE9  18 D0
; [RE] MS BASIC-80 protected-program ENCODE: inverse of PROG_UNSCRAMBLE, re-applies the dual rotating-key XOR over the program area so the in-memory image stays protected.
PROG_SCRAMBLE:
        LD BC,SUB_0D04_3                 ; $5DEB  01 0B 0D
        LD HL,(TXTTAB)                   ; $5DEE  2A 69 08
        EX DE,HL                         ; $5DF1  EB
PROG_SCRAMBLE_1:
        LD HL,(VARTAB)                   ; $5DF2  2A 92 0B
        CALL CMP_HL_DE                   ; $5DF5  CD 9D 45
        RET Z                            ; $5DF8  C8
        LD HL,FN_RND_5                   ; $5DF9  21 30 3B
        LD A,L                           ; $5DFC  7D
        ADD A,B                          ; $5DFD  80
        LD L,A                           ; $5DFE  6F
        LD A,H                           ; $5DFF  7C
        ADC A,$00                        ; $5E00  CE 00
        LD H,A                           ; $5E02  67
        LD A,(DE)                        ; $5E03  1A
        SUB C                            ; $5E04  91
        XOR (HL)                         ; $5E05  AE
        PUSH AF                          ; $5E06  F5
        LD HL,FN_TAN_2                   ; $5E07  21 80 3B
        LD A,L                           ; $5E0A  7D
        ADD A,C                          ; $5E0B  81
        LD L,A                           ; $5E0C  6F
        LD A,H                           ; $5E0D  7C
        ADC A,$00                        ; $5E0E  CE 00
        LD H,A                           ; $5E10  67
        POP AF                           ; $5E11  F1
        XOR (HL)                         ; $5E12  AE
        ADD A,B                          ; $5E13  80
        LD (DE),A                        ; $5E14  12
        INC DE                           ; $5E15  13
        DEC C                            ; $5E16  0D
        JR NZ,PROG_SCRAMBLE_2            ; $5E17  20 02
        LD C,$0B                         ; $5E19  0E 0B
PROG_SCRAMBLE_2:
        DJNZ PROG_SCRAMBLE_1             ; $5E1B  10 D5
        LD B,$0D                         ; $5E1D  06 0D
        JR PROG_SCRAMBLE_1               ; $5E1F  18 D1
; [RE] RET unless SAVTXT ($0844) == $FFFF, in which case fall into the function-call guard.
DIRECT_MODE_GUARD:
        PUSH HL                          ; $5E21  E5
        LD HL,(SAVTXT)                   ; $5E22  2A 67 08
        LD A,H                           ; $5E25  7C
        AND L                            ; $5E26  A5
        POP HL                           ; $5E27  E1
        INC A                            ; $5E28  3C
        RET NZ                           ; $5E29  C0
; [RE] Illegal-direct guard: if the 'running a program' flag ($0C99) is clear -> $0D5C (Illegal direct), else RET preserving AF. Statements that need a stored line call here.
ILLEGAL_DIRECT_CHECK:
        PUSH AF                          ; $5E2A  F5
        LD A,(RUNNING_PROG_FLAG)         ; $5E2B  3A BC 0C
        OR A                             ; $5E2E  B7
        JP NZ,GETINT_POSITIVE_1          ; $5E2F  C2 EB 14
        POP AF                           ; $5E32  F1
        RET                              ; $5E33  C9
ILLEGAL_DIRECT_CHECK_1:
        NOP                              ; $5E34  00
        NOP                              ; $5E35  00
ILLEGAL_DIRECT_CHECK_2:
        NOP                              ; $5E36  00
        NOP                              ; $5E37  00
ILLEGAL_DIRECT_CHECK_3:
        NOP                              ; $5E38  00
        NOP                              ; $5E39  00
ILLEGAL_DIRECT_CHECK_4:
        NOP                              ; $5E3A  00
; [RE] Warm-start (READY/Ok) re-entry: re-init the program-end sentinel ($0846), then enter the direct-mode main loop. SUB_81AC_6 ($81C6) falls through to the immediate-statement executor at $0E23 if the start-up command pointer ($0850/$8350) is non-empty, else jumps to NEWSTT.
WARM_START:
        CALL RUN_CLEAR                   ; $5E3B  CD E0 44
        LD HL,(TXTTAB)                   ; $5E3E  2A 69 08
        DEC HL                           ; $5E41  2B
        LD (HL),$00                      ; $5E42  36 00
        LD HL,(COLD_SET_WIDTH_11)        ; $5E44  2A CE 5F
        LD A,(HL)                        ; $5E47  7E
        OR A                             ; $5E48  B7
        JP NZ,OPEN_NAMED_FILE_1          ; $5E49  C2 FD 53
        JP NEWSTT_READY                  ; $5E4C  C3 46 0E
SUB_5E44_1:
        NOP                              ; $5E4F  00
        NOP                              ; $5E50  00
; [RE] Interpreter cold-start entry (the $1000 relocator JPs here after copying the body up to $3000). Initializes the runtime: BDOS handshake, RAM-top, the BASIC work cells, the RPC trigger patch (see $8240), and the console width from the SoftCard card config (see $827A).
COLD_START:
        LD HL,$6146                      ; $5E51  21 46 61
        LD SP,HL                         ; $5E54  F9
        XOR A                            ; $5E55  AF
        LD (RUNNING_PROG_FLAG),A         ; $5E56  32 BC 0C
        LD (PTRFIL_2),HL                 ; $5E59  22 65 08
        LD (SAVSTK),HL                   ; $5E5C  22 81 0B
        LD HL,($0001)                    ; $5E5F  2A 01 00
        LD (STMT_SYSTEM_1+1),HL          ; $5E62  22 6C 5A
        LD A,H                           ; $5E65  7C
        LD (COM_ENTRY_2),A               ; $5E66  32 07 01
        LD BC,$0004                      ; $5E69  01 04 00
        ADD HL,BC                        ; $5E6C  09
        LD E,(HL)                        ; $5E6D  5E
        INC HL                           ; $5E6E  23
        LD D,(HL)                        ; $5E6F  56
        EX DE,HL                         ; $5E70  EB
        LD (INKEY_SCAN_3+1),HL           ; $5E71  22 54 44
        LD (RPC_CONST_POLL_1+1),HL       ; $5E74  22 30 44
        LD (STMT_FOR_9+1),HL             ; $5E77  22 88 13
        EX DE,HL                         ; $5E7A  EB
        INC HL                           ; $5E7B  23
        INC HL                           ; $5E7C  23
        LD E,(HL)                        ; $5E7D  5E
        INC HL                           ; $5E7E  23
        LD D,(HL)                        ; $5E7F  56
        EX DE,HL                         ; $5E80  EB
        LD (CONIN_1+1),HL                ; $5E81  22 DE 43
        EX DE,HL                         ; $5E84  EB
        INC HL                           ; $5E85  23
        INC HL                           ; $5E86  23
        LD E,(HL)                        ; $5E87  5E
        INC HL                           ; $5E88  23
        LD D,(HL)                        ; $5E89  56
        EX DE,HL                         ; $5E8A  EB
        LD (OUTDO_DEVICE2_1+1),HL        ; $5E8B  22 88 43
        EX DE,HL                         ; $5E8E  EB
        INC HL                           ; $5E8F  23
        INC HL                           ; $5E90  23
        LD E,(HL)                        ; $5E91  5E
        INC HL                           ; $5E92  23
        LD D,(HL)                        ; $5E93  56
        EX DE,HL                         ; $5E94  EB
        LD (OUTDO_DEVICE_1+1),HL         ; $5E95  22 F0 42
        EX DE,HL                         ; $5E98  EB
        LD DE,$F1F8                      ; $5E99  11 F8 F1
        ADD HL,DE                        ; $5E9C  19
        LD DE,SUB_27E1_3+1               ; $5E9D  11 F8 27
        LD (HL),E                        ; $5EA0  73
        INC HL                           ; $5EA1  23
        LD (HL),D                        ; $5EA2  72
        INC HL                           ; $5EA3  23
        LD DE,SUB_27E1_5+1               ; $5EA4  11 FE 27
        LD (HL),E                        ; $5EA7  73
        INC HL                           ; $5EA8  23
        LD (HL),D                        ; $5EA9  72
        INC HL                           ; $5EAA  23
        LD DE,SUB_27E1_4+1               ; $5EAB  11 FB 27
        LD (HL),E                        ; $5EAE  73
        INC HL                           ; $5EAF  23
        LD (HL),D                        ; $5EB0  72
        INC HL                           ; $5EB1  23
        LD DE,SUB_27E1_6+1               ; $5EB2  11 01 28
        LD (HL),E                        ; $5EB5  73
        INC HL                           ; $5EB6  23
        LD (HL),D                        ; $5EB7  72
        LD HL,SUB_27E1_2                 ; $5EB8  21 F5 27
        LD ($0001),HL                    ; $5EBB  22 01 00
        LD HL,(Z_CPU)                    ; $5EBE  2A DE F3
        LD (RPC_TRIGGER_STORE+1),HL      ; $5EC1  22 06 26
        LD C,$0C                         ; $5EC4  0E 0C
        CALL $0005                       ; $5EC6  CD 05 00
        LD (FILTAB_15),A                 ; $5EC9  32 EE 08
        OR A                             ; $5ECC  B7
        LD HL,LINGET_TOKLINE_1+2         ; $5ECD  21 14 15
        JP Z,SUB_5EBE_1                  ; $5ED0  CA D6 5E
        LD HL,IS_ALNUM_CHAR_2+1          ; $5ED3  21 21 22
SUB_5EBE_1:
        LD (FILTAB_16),HL                ; $5ED6  22 EF 08
        LD HL,$FFFE                      ; $5ED9  21 FE FF
        LD (SAVTXT),HL                   ; $5EDC  22 67 08
        XOR A                            ; $5EDF  AF
        LD (CTRL_O_SUPPRESS),A           ; $5EE0  32 62 08
        LD (SUB_0B2A_1),A                ; $5EE3  32 33 0B
        LD (CHAIN_BREAK_FLAG),A          ; $5EE6  32 C3 0C
        LD (CHAIN_PRESERVE_FLAG),A       ; $5EE9  32 BD 0C
        LD (SUB_0752_31+2),A             ; $5EEC  32 58 08
        LD HL,$0000                      ; $5EEF  21 00 00
        LD (SUB_0752_32),HL              ; $5EF2  22 5A 08
        LD (COLOR),A                     ; $5EF5  32 30 F0
        LD A,(SLTTYP3)                   ; $5EF8  3A BB F3
        SUB $03                          ; $5EFB  D6 03
        JR Z,COLD_SET_WIDTH+1            ; $5EFD  28 06
        DEC A                            ; $5EFF  3D
        JR Z,COLD_SET_WIDTH+1            ; $5F00  28 03
        LD A,$28                         ; $5F02  3E 28
; [RE] Select terminal line width during cold start: reads the configured console type ($F3BB) and sets the line-width work cell (SUB_4B20_12, $4B97) to 40 ($28) or the wide default, then initializes the file-control / disk-parameter pointers (SUB_4063).
COLD_SET_WIDTH:
        LD BC,$503E                      ; $5F04  01 3E 50
        LD (SUB_2803_3),A                ; $5F07  32 15 28
        CALL WIDTH_SET_CONSOLE           ; $5F0A  CD 7E 20
        LD HL,$0080                      ; $5F0D  21 80 00
        LD (FILE_RECLEN_DEFAULT),HL      ; $5F10  22 BA 0C
        LD HL,MEMSIZ_2                   ; $5F13  21 4A 0B
        LD (MEMSIZ_1),HL                 ; $5F16  22 48 0B
        LD HL,VARTAB_5                   ; $5F19  21 B4 0B
        LD (SUB_0C03_1),HL               ; $5F1C  22 1C 0C
        LD HL,($0006)                    ; $5F1F  2A 06 00
        LD (MEMSIZ),HL                   ; $5F22  22 46 0B
        LD A,$03                         ; $5F25  3E 03
        LD (FILTAB_4),A                  ; $5F27  32 93 08
        LD HL,COLD_SET_WIDTH_10          ; $5F2A  21 CD 5F
        LD (COLD_SET_WIDTH_11),HL        ; $5F2D  22 CE 5F
        LD A,(COLD_SET_WIDTH_12)         ; $5F30  3A D0 5F
        OR A                             ; $5F33  B7
        JP NZ,COLD_SET_WIDTH_13          ; $5F34  C2 D1 5F
        INC A                            ; $5F37  3C
        LD (COLD_SET_WIDTH_12),A         ; $5F38  32 D0 5F
        LD HL,$0080                      ; $5F3B  21 80 00
        LD A,(HL)                        ; $5F3E  7E
        OR A                             ; $5F3F  B7
        LD (COLD_SET_WIDTH_11),HL        ; $5F40  22 CE 5F
        JP Z,COLD_SET_WIDTH_13           ; $5F43  CA D1 5F
        LD B,(HL)                        ; $5F46  46
        INC HL                           ; $5F47  23
COLD_SET_WIDTH_1:
        LD A,(HL)                        ; $5F48  7E
        DEC HL                           ; $5F49  2B
        LD (HL),A                        ; $5F4A  77
        INC HL                           ; $5F4B  23
        INC HL                           ; $5F4C  23
        DEC B                            ; $5F4D  05
        JP NZ,COLD_SET_WIDTH_1           ; $5F4E  C2 48 5F
        DEC HL                           ; $5F51  2B
        LD (HL),$00                      ; $5F52  36 00
        LD (COLD_SET_WIDTH_11),HL        ; $5F54  22 CE 5F
        LD HL,$007F                      ; $5F57  21 7F 00
        CALL CHRGET                      ; $5F5A  CD E4 13
        OR A                             ; $5F5D  B7
        JP Z,COLD_SET_WIDTH_13           ; $5F5E  CA D1 5F
        CP $2F                           ; $5F61  FE 2F
        JR Z,COLD_SET_WIDTH_3            ; $5F63  28 14
        DEC HL                           ; $5F65  2B
        LD (HL),$22                      ; $5F66  36 22
        LD (COLD_SET_WIDTH_11),HL        ; $5F68  22 CE 5F
        INC HL                           ; $5F6B  23
COLD_SET_WIDTH_2:
        CP $2F                           ; $5F6C  FE 2F
        JR Z,COLD_SET_WIDTH_3            ; $5F6E  28 09
        CALL CHRGET                      ; $5F70  CD E4 13
        OR A                             ; $5F73  B7
        JR NZ,COLD_SET_WIDTH_2           ; $5F74  20 F6
        JP COLD_SET_WIDTH_13             ; $5F76  C3 D1 5F
COLD_SET_WIDTH_3:
        LD (HL),$00                      ; $5F79  36 00
        CALL CHRGET                      ; $5F7B  CD E4 13
COLD_SET_WIDTH_4:
        CP $53                           ; $5F7E  FE 53
        JR Z,COLD_SET_WIDTH_9            ; $5F80  28 3A
        CP $4D                           ; $5F82  FE 4D
        PUSH AF                          ; $5F84  F5
        JP Z,COLD_SET_WIDTH_5            ; $5F85  CA 8D 5F
        CP $46                           ; $5F88  FE 46
        JP NZ,RAISE_SYNTAX_ERROR         ; $5F8A  C2 92 0D
COLD_SET_WIDTH_5:
        CALL CHRGET                      ; $5F8D  CD E4 13
        CALL SYNCHR                      ; $5F90  CD A3 45
        DEFB    ':'                      ; $5F93  3A  inline char arg consumed by the preceding CALL
        CALL LINGET_OR_AMP               ; $5F94  CD F1 1C
        POP AF                           ; $5F97  F1
        JR Z,COLD_SET_WIDTH_7            ; $5F98  28 10
        LD A,D                           ; $5F9A  7A
        OR A                             ; $5F9B  B7
        JP NZ,GETINT_POSITIVE_1          ; $5F9C  C2 EB 14
        LD A,E                           ; $5F9F  7B
        CP $10                           ; $5FA0  FE 10
        JP NC,GETINT_POSITIVE_1          ; $5FA2  D2 EB 14
        LD (FILTAB_4),A                  ; $5FA5  32 93 08
COLD_SET_WIDTH_6:
        JR COLD_SET_WIDTH_8              ; $5FA8  18 05
COLD_SET_WIDTH_7:
        EX DE,HL                         ; $5FAA  EB
        LD (MEMSIZ),HL                   ; $5FAB  22 46 0B
        EX DE,HL                         ; $5FAE  EB
COLD_SET_WIDTH_8:
        DEC HL                           ; $5FAF  2B
        CALL CHRGET                      ; $5FB0  CD E4 13
        JR Z,COLD_SET_WIDTH_13           ; $5FB3  28 1C
        CALL SYNCHR                      ; $5FB5  CD A3 45
        DEFB    '/'                      ; $5FB8  2F  inline char arg consumed by the preceding CALL
        JP COLD_SET_WIDTH_4              ; $5FB9  C3 7E 5F
COLD_SET_WIDTH_9:
        CALL CHRGET                      ; $5FBC  CD E4 13
        CALL SYNCHR                      ; $5FBF  CD A3 45
        DEFB    ':'                      ; $5FC2  3A  inline char arg consumed by the preceding CALL
        CALL LINGET_OR_AMP               ; $5FC3  CD F1 1C
        EX DE,HL                         ; $5FC6  EB
        LD (FILE_RECLEN_DEFAULT),HL      ; $5FC7  22 BA 0C
        EX DE,HL                         ; $5FCA  EB
        JR COLD_SET_WIDTH_8              ; $5FCB  18 E2
COLD_SET_WIDTH_10:
        NOP                              ; $5FCD  00
COLD_SET_WIDTH_11:
        NOP                              ; $5FCE  00
        NOP                              ; $5FCF  00
COLD_SET_WIDTH_12:
        NOP                              ; $5FD0  00
COLD_SET_WIDTH_13:
        DEC HL                           ; $5FD1  2B
        LD HL,(MEMSIZ)                   ; $5FD2  2A 46 0B
        PUSH HL                          ; $5FD5  E5
        POP HL                           ; $5FD6  E1
        DEC HL                           ; $5FD7  2B
        LD (MEMSIZ),HL                   ; $5FD8  22 46 0B
        DEC HL                           ; $5FDB  2B
        PUSH HL                          ; $5FDC  E5
        LD A,(FILTAB_4)                  ; $5FDD  3A 93 08
        LD HL,SUB_5E44_1                 ; $5FE0  21 4F 5E
        LD (FILTAB_SLOT0_SEED),HL        ; $5FE3  22 71 08
        LD DE,FILTAB                     ; $5FE6  11 73 08
        LD (FILTAB_4),A                  ; $5FE9  32 93 08
        INC A                            ; $5FEC  3C
        LD BC,$00A9                      ; $5FED  01 A9 00
COLD_SET_WIDTH_14:
        EX DE,HL                         ; $5FF0  EB
        LD (HL),E                        ; $5FF1  73
        INC HL                           ; $5FF2  23
        LD (HL),D                        ; $5FF3  72
        INC HL                           ; $5FF4  23
        EX DE,HL                         ; $5FF5  EB
        ADD HL,BC                        ; $5FF6  09
        PUSH HL                          ; $5FF7  E5
        LD HL,(FILE_RECLEN_DEFAULT)      ; $5FF8  2A BA 0C
        LD BC,$00B2                      ; $5FFB  01 B2 00
        ADD HL,BC                        ; $5FFE  09
        LD B,H                           ; $5FFF  44
        LD C,L                           ; $6000  4D
        POP HL                           ; $6001  E1
        DEC A                            ; $6002  3D
        JR NZ,COLD_SET_WIDTH_14          ; $6003  20 EB
        INC HL                           ; $6005  23
        LD (TXTTAB),HL                   ; $6006  22 69 08
        LD (SAVSTK),HL                   ; $6009  22 81 0B
        POP DE                           ; $600C  D1
        LD A,E                           ; $600D  7B
        SUB L                            ; $600E  95
        LD L,A                           ; $600F  6F
        LD A,D                           ; $6010  7A
        SBC A,H                          ; $6011  9C
        LD H,A                           ; $6012  67
COLD_SET_WIDTH_15:
        JP C,CHECK_STACK_ROOM_1          ; $6013  DA B4 44
        LD B,$03                         ; $6016  06 03
COLD_SET_WIDTH_16:
        OR A                             ; $6018  B7
        LD A,H                           ; $6019  7C
        RRA                              ; $601A  1F
        LD H,A                           ; $601B  67
        LD A,L                           ; $601C  7D
        RRA                              ; $601D  1F
        LD L,A                           ; $601E  6F
        DJNZ COLD_SET_WIDTH_16           ; $601F  10 F7
        LD A,H                           ; $6021  7C
        CP $02                           ; $6022  FE 02
        JR C,COLD_SET_WIDTH_17           ; $6024  38 03
        LD HL,FUNC_DISPATCH_TBL+78       ; $6026  21 00 02
COLD_SET_WIDTH_17:
        LD A,E                           ; $6029  7B
        SUB L                            ; $602A  95
        LD L,A                           ; $602B  6F
        LD A,D                           ; $602C  7A
        SBC A,H                          ; $602D  9C
        LD H,A                           ; $602E  67
        JP C,CHECK_STACK_ROOM_1          ; $602F  DA B4 44
        LD (MEMSIZ),HL                   ; $6032  22 46 0B
        EX DE,HL                         ; $6035  EB
        LD (PTRFIL_2),HL                 ; $6036  22 65 08
        LD (FRETOP),HL                   ; $6039  22 6B 0B
        LD SP,HL                         ; $603C  F9
        LD (SAVSTK),HL                   ; $603D  22 81 0B
        LD HL,(TXTTAB)                   ; $6040  2A 69 08
        EX DE,HL                         ; $6043  EB
        CALL GC_CHECK_AND_COLLECT        ; $6044  CD C2 44
        LD A,L                           ; $6047  7D
        SUB E                            ; $6048  93
        LD L,A                           ; $6049  6F
        LD A,H                           ; $604A  7C
        SBC A,D                          ; $604B  9A
        LD H,A                           ; $604C  67
        DEC HL                           ; $604D  2B
        DEC HL                           ; $604E  2B
        PUSH HL                          ; $604F  E5
        CALL GFX_STMT_HOME               ; $6050  CD C3 25
        LD HL,SIGNON_BANNER_HEADER       ; $6053  21 9B 60
        CALL STROUT                      ; $6056  CD BE 48
        POP HL                           ; $6059  E1
        CALL FOUT                        ; $605A  CD 91 33
        LD HL,MSG_BYTES_FREE             ; $605D  21 8D 60
        CALL STROUT                      ; $6060  CD BE 48
        LD HL,STROUT                     ; $6063  21 BE 48
        LD (NEWSTT_READY_1+1),HL         ; $6066  22 57 0E
        CALL CRLF                        ; $6069  CD 06 44
        LD HL,STKFRAME_SCAN_3            ; $606C  21 4B 0D
        LD (COM_ENTRY+1),HL              ; $606F  22 01 01
        JP WARM_START                    ; $6072  C3 3B 5E
        DEC C                            ; $6075  0D
        LD A,(BC)                        ; $6076  0A
        LD A,(BC)                        ; $6077  0A
        LD C,A                           ; $6078  4F
        LD (HL),A                        ; $6079  77
        LD L,(HL)                        ; $607A  6E
        LD H,L                           ; $607B  65
        LD H,H                           ; $607C  64
        JR NZ,SUB_60AD_4                 ; $607D  20 62
        LD A,C                           ; $607F  79
        JR NZ,SUB_60AD_1                 ; $6080  20 4D
        LD L,C                           ; $6082  69
        LD H,E                           ; $6083  63
        LD (HL),D                        ; $6084  72
        LD L,A                           ; $6085  6F
        LD (HL),E                        ; $6086  73
        LD L,A                           ; $6087  6F
        LD H,(HL)                        ; $6088  66
        LD (HL),H                        ; $6089  74
        DEC C                            ; $608A  0D
        LD A,(BC)                        ; $608B  0A
        NOP                              ; $608C  00
; Data string ' Bytes free'+CRLF -- free-memory suffix printed after the byte count in the cold sign-on banner (loaded at $83DF, emitted via STROUT)
MSG_BYTES_FREE:
        JR NZ,SUB_60AD_2                 ; $608D  20 42
        LD A,C                           ; $608F  79
        LD (HL),H                        ; $6090  74
        LD H,L                           ; $6091  65
        LD (HL),E                        ; $6092  73
        JR NZ,SUB_60AD_6                 ; $6093  20 66
        LD (HL),D                        ; $6095  72
        LD H,L                           ; $6096  65
        LD H,L                           ; $6097  65
        DEC C                            ; $6098  0D
        LD A,(BC)                        ; $6099  0A
        NOP                              ; $609A  00
; Data string: leading sign-on banner text (CRLF CRLF CRLF then 'BASIC-80 ...'), printed first by COLD_SIGNON ($83D5 LD HL,$841D / STROUT) ahead of the free-bytes count
SIGNON_BANNER_HEADER:
        DEC C                            ; $609B  0D
        LD A,(BC)                        ; $609C  0A
        DEC C                            ; $609D  0D
        LD A,(BC)                        ; $609E  0A
        DEC C                            ; $609F  0D
        LD A,(BC)                        ; $60A0  0A
        LD B,D                           ; $60A1  42
        LD B,C                           ; $60A2  41
        LD D,E                           ; $60A3  53
        LD C,C                           ; $60A4  49
        LD B,E                           ; $60A5  43
        DEC L                            ; $60A6  2D
        JR C,SUB_60AD_3                  ; $60A7  38 30
        JR NZ,SUB_60AD_7                 ; $60A9  20 52
        LD H,L                           ; $60AB  65
        HALT                             ; $60AC  76
        LD L,$20                         ; $60AD  2E 20
        DEC (HL)                         ; $60AF  35
        LD L,$32                         ; $60B0  2E 32
        DEC C                            ; $60B2  0D
        LD A,(BC)                        ; $60B3  0A
        LD E,E                           ; $60B4  5B
        LD B,C                           ; $60B5  41
        LD (HL),B                        ; $60B6  70
        LD (HL),B                        ; $60B7  70
        LD L,H                           ; $60B8  6C
        LD H,L                           ; $60B9  65
        JR NZ,SUB_60AD_8                 ; $60BA  20 43
        LD D,B                           ; $60BC  50
        CPL                              ; $60BD  2F
        LD C,L                           ; $60BE  4D
        JR NZ,$6117                      ; $60BF  20 56
        LD H,L                           ; $60C1  65
        LD (HL),D                        ; $60C2  72
        LD (HL),E                        ; $60C3  73
        LD L,C                           ; $60C4  69
        LD L,A                           ; $60C5  6F
        LD L,(HL)                        ; $60C6  6E
        LD E,L                           ; $60C7  5D
        DEC C                            ; $60C8  0D
        LD A,(BC)                        ; $60C9  0A
        LD B,E                           ; $60CA  43
        LD L,A                           ; $60CB  6F
        LD (HL),B                        ; $60CC  70
        LD A,C                           ; $60CD  79
        LD (HL),D                        ; $60CE  72
SUB_60AD_1:
        LD L,C                           ; $60CF  69
        LD H,A                           ; $60D0  67
SUB_60AD_2:
        LD L,B                           ; $60D1  68
        LD (HL),H                        ; $60D2  74
        JR NZ,SUB_60AD_7                 ; $60D3  20 28
        LD B,E                           ; $60D5  43
        ADD HL,HL                        ; $60D6  29
        JR NZ,$610A                      ; $60D7  20 31
SUB_60AD_3:
        ADD HL,SP                        ; $60D9  39
        JR C,$610C                       ; $60DA  38 30
        JR NZ,$6140                      ; $60DC  20 62
        LD A,C                           ; $60DE  79
        JR NZ,$612E                      ; $60DF  20 4D
SUB_60AD_4:
        LD L,C                           ; $60E1  69
        LD H,E                           ; $60E2  63
        LD (HL),D                        ; $60E3  72
        LD L,A                           ; $60E4  6F
        LD (HL),E                        ; $60E5  73
        LD L,A                           ; $60E6  6F
        LD H,(HL)                        ; $60E7  66
        LD (HL),H                        ; $60E8  74
        DEC C                            ; $60E9  0D
SUB_60AD_5:
        LD A,(BC)                        ; $60EA  0A
        LD B,E                           ; $60EB  43
        LD (HL),D                        ; $60EC  72
        LD H,L                           ; $60ED  65
        LD H,C                           ; $60EE  61
        LD (HL),H                        ; $60EF  74
        LD H,L                           ; $60F0  65
        LD H,H                           ; $60F1  64
        LD A,($3220)                     ; $60F2  3A 20 32
        LD (HL),$2D                      ; $60F5  36 2D
        LD B,C                           ; $60F7  41
        LD (HL),L                        ; $60F8  75
        LD H,A                           ; $60F9  67
        DEC L                            ; $60FA  2D
SUB_60AD_6:
        JR C,$612D                       ; $60FB  38 30
SUB_60AD_7:
        DEC C                            ; $60FD  0D
        LD A,(BC)                        ; $60FE  0A
SUB_60AD_8:
        NOP                              ; $60FF  00

    SAVEBIN "MBASIC.bin", $0100, $6000
