; BASIC.asm -- MASTER SOURCE for the GBASIC/MBASIC one-conditional-source fold.
; Edit THIS file directly. Assemble with the GBASIC symbol defined -> GBASIC.COM
; (self-relocating, graphics-ON); without it -> MBASIC.COM (in place, graphics-OFF).
; Byte-fidelity gate: test_fold_build_byte_identical (assemble both modes, diff the
; genuine .COMs). PROVENANCE (how it was first derived from the .COM bytes, now
; provenance-only -- do NOT regenerate over direct edits): cpm_pipeline.basic
; gen_gbasic + GBASIC.overlay.json + fold_gen; see CPMV220-44K/utilities/PROVENANCE.md.
; GBASIC.COM -- Microsoft BASIC-80 Rev 5.2 graphics interpreter, SoftCard CP/M 2.20 (44K).
; Clean-slate disassembly of the GBASIC.COM bytes on the 2.20-44K system disk
; (softcard-cpm2.20-44k-system.dsk); reassembles byte-identically to GBASIC.COM.
; Range:  $0100-$64FF  (25600 bytes)
;
; GBASIC self-relocates.  Entry ($0100) is JP $1000; the $1000 stub block-copies the
; interpreter from its on-disk position ($100E-$6490) UP to $3000-$8482 with LDDR, then
; JP $81D3 runs it at $3000+.  The interpreter body is therefore decoded at its run
; address $3000 and folded back to the .COM file offset with DISP/ENT: the bytes stay
; contiguous at their file position while every label resolves to the $3000+ run address.
;
; BASE decode: machine labels (L_/SUB_); semantic naming, strings, and [DOC] citations
; are layered on during enrichment.  Derived from the 2.20 binary only -- NOT the 2.23 .asm.

    DEVICE NOSLOT64K
    INCLUDE "apple_softcard.inc"   ; canonical Apple/SoftCard external names
    INCLUDE "msbasic_tokens.inc"   ; MS BASIC keyword-token names
    INCLUDE "msbasic_errors.inc"   ; MS BASIC error-code names (ERR_*)
    INCLUDE "msbasic_fcb.inc"   ; MS BASIC file-control-block STRUCT
    INCLUDE "msbasic_line.inc"   ; MS BASIC program-line record STRUCT (BASLINE)
    INCLUDE "msbasic_valtyp.inc"   ; MS BASIC VALTYP value-type EQUs (VT_*) + operator bands
    INCLUDE "msbasic_strdesc.inc"   ; MS BASIC string-descriptor STRUCT (STRDESC)
    INCLUDE "msbasic_var.inc"   ; MS BASIC variable/array storage STRUCTs
    INCLUDE "cpm22.inc"   ; CP/M 2.2 BDOS ABI (BDOS + F_*/DRV_*)

    ORG $0100

    IFDEF GBASIC
        JP RELOCATE_AND_RUN              ; (GBASIC: relocate body to $3000 first)
    ELSE
        JP COLD_START                    ; (MBASIC: runs in place, jump straight to cold start)
    ENDIF
        DEFW    FN_CINT
        DEFW    FP_STORE_FAC_INT
        DEFB    "\0"
; [RE] CRUNCH keyword-detect flag-skip (NOT a dispatch-table ref). $30E9 LD BC,CRUNCH_STORE_FLAG_AND_EMIT+1 / PUSH BC arms $311A (LD A,$01) as the return for the CP nn / RET Z chain (sets A=1 on a separator-implying token). Fall-through: $3118 XOR A (Z) makes $3119 C2 3E 01 (JP NZ,$013E) a dead branch into $311C LD ($0B16),A with A=0. The cover IS executed; $013E merely coincides with STMT_DISPATCH_TBL+54 (STMT_LLIST) and is never used as a pointer.
STMT_DISPATCH_TBL:
        DEFW    STMT_END
        DEFW    STMT_FOR
        DEFW    STMT_NEXT
        DEFW    STMT_DATA
        DEFW    STMT_INPUT
        DEFW    PTRGET
        DEFW    STMT_READ
        DEFW    STMT_LET
        DEFW    STMT_GOTO
        DEFW    STMT_RUN
        DEFW    STMT_IF
        DEFW    STMT_RESTORE
        DEFW    STMT_GOSUB
        DEFW    STMT_RETURN
        DEFW    STMT_DATA+2
        DEFW    STMT_STOP
        DEFW    STMT_PRINT
        DEFW    STMT_CLEAR
        DEFW    STMT_LIST
        DEFW    STMT_NEW
        DEFW    STMT_ON
        DEFW    STMT_DEF
        DEFW    STMT_POKE
        DEFW    STMT_CONT
        DEFW    RAISE_SYNTAX_ERROR
        DEFW    RAISE_SYNTAX_ERROR
        DEFW    STMT_LPRINT
        DEFW    STMT_LLIST
        DEFW    STMT_WIDTH
        DEFW    STMT_DATA+2
        DEFW    STMT_TRACE
        DEFW    STMT_TRACE+1
        DEFW    STMT_SWAP
        DEFW    STMT_ERASE
        DEFW    STMT_EDIT
        DEFW    STMT_ERROR
        DEFW    STMT_RESUME
        DEFW    STMT_DELETE
        DEFW    SCAN_LINE_RANGE_RESUME
        DEFW    STMT_RENUM
        DEFW    STMT_DEFSTR
        DEFW    STMT_DEFSTR_1+1
        DEFW    STMT_DEFSTR_2+1
        DEFW    STMT_DEFSTR_3+1
        DEFW    STMT_LINE
        DEFW    STMT_POP
        DEFW    STMT_WHILE
        DEFW    STMT_WEND
        DEFW    STMT_CALL
        DEFW    STMT_WRITE
        DEFW    STMT_DATA
        DEFW    STMT_CHAIN
        DEFW    STMT_OPTION
        DEFW    STMT_RANDOMIZE
        DEFW    STMT_SYSTEM
        DEFW    STMT_OPEN
        DEFW    STMT_FIELD
        DEFW    STMT_PUT+1
        DEFW    STMT_PUT
        DEFW    STMT_CLOSE
        DEFW    LOAD_PROGRAM+1
        DEFW    STMT_MERGE
        DEFW    STMT_FILES
        DEFW    STMT_NAME
        DEFW    STMT_KILL
        DEFW    STMT_RSET+1
        DEFW    STMT_RSET
        DEFW    STMT_SAVE
        DEFW    STMT_RESET
        DEFW    STMT_TEXT
        DEFW    GFX_STMT_HOME
        DEFW    GFX_STMT_VTAB
        DEFW    GFX_STMT_HTAB
        DEFW    GFX_STMT_HOME_1+1
        DEFW    GFX_STMT_HOME_2+1
        DEFW    GFX_STMT_GR
        DEFW    GFX_STMT_COLOR
        DEFW    GFX_STMT_HLIN
        DEFW    GFX_STMT_VLIN
        DEFW    GFX_STMT_PLOT
    IFDEF GBASIC
        DEFW    GFX_STMT_HGR
        DEFW    GFX_STMT_HPLOT
        DEFW    GFX_STMT_HCOLOR
    ELSE
        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; HGR   -> not-implemented stub
        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; HPLOT -> not-implemented stub
        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; HCOLOR-> not-implemented stub
    ENDIF
        DEFW    GFX_STMT_BEEP
        DEFW    STMT_WAIT
FUNC_DISPATCH_TBL:
        DEFW    STR_SUBSTR_ALLOC_COPY
        DEFW    FN_LEFT_STR
        DEFW    FN_RIGHT_STR
        DEFW    FN_MID_STR
        DEFW    FN_SGN
        DEFW    FN_INT
        DEFW    FN_SQR
        DEFW    FN_RND
        DEFW    FN_SIN
        DEFW    FN_LOG
        DEFW    FN_EXP
        DEFW    FN_COS
        DEFW    FN_TAN
        DEFW    FN_ATN
        DEFW    FN_FRE
        DEFW    FN_POS
        DEFW    FN_LEN
        DEFW    FN_STR
        DEFW    FN_VAL
        DEFW    FN_ASC
        DEFW    FN_CHR
        DEFW    FN_PEEK
        DEFW    FN_SPACE
        DEFW    FN_OCT_STR
        DEFW    FN_HEX_STR
        DEFW    FN_LPOS
        DEFW    FN_CINT
        DEFW    FN_CSNG
        DEFW    FN_CDBL
        DEFW    FN_FIX
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    $0000
        DEFW    FN_CVI
        DEFW    FN_CVI_1+1
        DEFW    FN_CVI_2+1
        DEFW    $0000
        DEFW    FN_EOF
        DEFW    FN_LOC_VALUE
        DEFW    FN_LOF_VALUE
        DEFW    FN_MKI_STR
        DEFW    FN_MKS_STR+1
        DEFW    FN_MKD_STR+1
        DEFW    GFX_FN_MKD_STR
        DEFW    GFX_FN_VPOS
        DEFW    GFX_FN_PDL
; -- Reserved-word / token table (CRUNCH keyword<->token map). The
;    per-letter index points at each first-letter group; a name entry
;    is the keyword TAIL (first letter implied), last char high-bit set,
;    then the token byte; $00 ends a group. Operator sub-table = (char,
;    token) pairs. Byte-identical to the original DEFB bytes.
RESWORD_INDEX:                           ; per-letter group pointers A-Z
        DEFW    KWGRP_A,KWGRP_B,KWGRP_C,KWGRP_D,KWGRP_E,KWGRP_F
        DEFW    KWGRP_G,KWGRP_H,KWGRP_I,KWGRP_J,KWGRP_K,KWGRP_L
        DEFW    KWGRP_M,KWGRP_N,KWGRP_O,KWGRP_P,KWGRP_Q,KWGRP_R
        DEFW    KWGRP_S,KWGRP_T,KWGRP_U,KWGRP_V,KWGRP_W,KWGRP_X
        DEFW    KWGRP_Y,KWGRP_Z
KWGRP_A:
        DEFB    'N','D'+$80,TOK_AND          ; AND
        DEFB    'B','S'+$80,TOK_ABS          ; ABS
        DEFB    'T','N'+$80,TOK_ATN          ; ATN
        DEFB    'S','C'+$80,TOK_ASC          ; ASC
        DEFB    'U','T','O'+$80,TOK_AUTO     ; AUTO
        DEFB    $00                          ; end A-group
KWGRP_B:
        DEFB    'U','T','T','O','N'+$80,TOK_BUTTON ; BUTTON
        DEFB    'E','E','P'+$80,TOK_BEEP     ; BEEP
        DEFB    $00                          ; end B-group
KWGRP_C:
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
KWGRP_D:
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
KWGRP_E:
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
KWGRP_F:
        DEFB    'O','R'+$80,TOK_FOR          ; FOR
        DEFB    'I','E','L','D'+$80,TOK_FIELD ; FIELD
        DEFB    'I','L','E','S'+$80,TOK_FILES ; FILES
        DEFB    'N'+$80,TOK_FN               ; FN
        DEFB    'R','E'+$80,TOK_FRE          ; FRE
        DEFB    'I','X'+$80,TOK_FIX          ; FIX
        DEFB    $00                          ; end F-group
KWGRP_G:
        DEFB    'O','T','O'+$80,TOK_GOTO     ; GOTO
        DEFB    'O',' ','T','O'+$80,TOK_GOTO ; GO TO
        DEFB    'O','S','U','B'+$80,TOK_GOSUB ; GOSUB
        DEFB    'E','T'+$80,TOK_GET          ; GET
        DEFB    'R'+$80,TOK_GR               ; GR
        DEFB    $00                          ; end G-group
KWGRP_H:
        DEFB    'O','M','E'+$80,TOK_HOME     ; HOME
        DEFB    'L','I','N'+$80,TOK_HLIN     ; HLIN
        DEFB    'G','R'+$80,TOK_HGR          ; HGR
        DEFB    'C','O','L','O','R'+$80,TOK_HCOLOR ; HCOLOR
        DEFB    'P','L','O','T'+$80,TOK_HPLOT ; HPLOT
        DEFB    'T','A','B'+$80,TOK_HTAB     ; HTAB
        DEFB    'S','C','R','N'+$80,TOK_HSCRN ; HSCRN
        DEFB    'E','X','$'+$80,TOK_HEXS     ; HEX$
        DEFB    $00                          ; end H-group
KWGRP_I:
        DEFB    'N','P','U','T'+$80,TOK_INPUT ; INPUT
        DEFB    'F'+$80,TOK_IF               ; IF
        DEFB    'N','S','T','R'+$80,TOK_INSTR ; INSTR
        DEFB    'N','T'+$80,TOK_INT          ; INT
        DEFB    'M','P'+$80,TOK_IMP          ; IMP
        DEFB    'N','K','E','Y','$'+$80,TOK_INKEYS ; INKEY$
        DEFB    'N','V','E','R','S','E'+$80,TOK_INVERSE ; INVERSE
        DEFB    $00                          ; end I-group
KWGRP_J:
        DEFB    $00                          ; end J-group
KWGRP_K:
        DEFB    'I','L','L'+$80,TOK_KILL     ; KILL
        DEFB    $00                          ; end K-group
KWGRP_L:
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
KWGRP_M:
        DEFB    'E','R','G','E'+$80,TOK_MERGE ; MERGE
        DEFB    'O','D'+$80,TOK_MOD          ; MOD
        DEFB    'K','I','$'+$80,TOK_MKIS     ; MKI$
        DEFB    'K','S','$'+$80,TOK_MKSS     ; MKS$
        DEFB    'K','D','$'+$80,TOK_MKDS     ; MKD$
        DEFB    'I','D','$'+$80,TOK_MIDS     ; MID$
        DEFB    $00                          ; end M-group
KWGRP_N:
        DEFB    'E','X','T'+$80,TOK_NEXT     ; NEXT
        DEFB    'O','R','M','A','L'+$80,TOK_NORMAL ; NORMAL
        DEFB    'O','T','R','A','C','E'+$80,TOK_NOTRACE ; NOTRACE
        DEFB    'A','M','E'+$80,TOK_NAME     ; NAME
        DEFB    'E','W'+$80,TOK_NEW          ; NEW
        DEFB    'O','T'+$80,TOK_NOT          ; NOT
        DEFB    $00                          ; end N-group
KWGRP_O:
        DEFB    'N'+$80,TOK_ON               ; ON
        DEFB    'P','E','N'+$80,TOK_OPEN     ; OPEN
        DEFB    'R'+$80,TOK_OR               ; OR
        DEFB    'C','T','$'+$80,TOK_OCTS     ; OCT$
        DEFB    'P','T','I','O','N'+$80,TOK_OPTION ; OPTION
        DEFB    $00                          ; end O-group
KWGRP_P:
        DEFB    'U','T'+$80,TOK_PUT          ; PUT
        DEFB    'O','K','E'+$80,TOK_POKE     ; POKE
        DEFB    'R','I','N','T'+$80,TOK_PRINT ; PRINT
        DEFB    'O','S'+$80,TOK_POS          ; POS
        DEFB    'E','E','K'+$80,TOK_PEEK     ; PEEK
        DEFB    'L','O','T'+$80,TOK_PLOT     ; PLOT
        DEFB    'D','L'+$80,TOK_PDL          ; PDL
        DEFB    'O','P'+$80,TOK_POP          ; POP
        DEFB    $00                          ; end P-group
KWGRP_Q:
        DEFB    $00                          ; end Q-group
KWGRP_R:
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
KWGRP_S:
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
KWGRP_T:
        DEFB    'R','A','C','E'+$80,TOK_TRACE ; TRACE
        DEFB    'A','B','('+$80,TOK_TAB_LP   ; TAB(
        DEFB    'O'+$80,TOK_TO               ; TO
        DEFB    'H','E','N'+$80,TOK_THEN     ; THEN
        DEFB    'A','N'+$80,TOK_TAN          ; TAN
        DEFB    'E','X','T'+$80,TOK_TEXT     ; TEXT
        DEFB    $00                          ; end T-group
KWGRP_U:
        DEFB    'S','I','N','G'+$80,TOK_USING ; USING
        DEFB    'S','R'+$80,TOK_USR          ; USR
        DEFB    $00                          ; end U-group
KWGRP_V:
        DEFB    'A','L'+$80,TOK_VAL          ; VAL
        DEFB    'A','R','P','T','R'+$80,TOK_VARPTR ; VARPTR
        DEFB    'L','I','N'+$80,TOK_VLIN     ; VLIN
        DEFB    'T','A','B'+$80,TOK_VTAB     ; VTAB
        DEFB    'P','O','S'+$80,TOK_VPOS     ; VPOS
        DEFB    $00                          ; end V-group
KWGRP_W:
        DEFB    'I','D','T','H'+$80,TOK_WIDTH ; WIDTH
        DEFB    'A','I','T'+$80,TOK_WAIT     ; WAIT
        DEFB    'H','I','L','E'+$80,TOK_WHILE ; WHILE
        DEFB    'E','N','D'+$80,TOK_WEND     ; WEND
        DEFB    'R','I','T','E'+$80,TOK_WRITE ; WRITE
        DEFB    $00                          ; end W-group
KWGRP_X:
        DEFB    'O','R'+$80,TOK_XOR          ; XOR
        DEFB    $00                          ; end X-group
KWGRP_Y:
        DEFB    $00                          ; end Y-group
KWGRP_Z:
        DEFB    $00                          ; end Z-group
RESWORD_OPS:                             ; operator (char,token) pairs
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
        DEFB    $79,$79,$7C,$7C,$7F,$50,$46,$3C,$32,$28,$7A,$7B
; [RE] Error-message table base. LD HL,$0521 (OPERATOR_ROUTINE_TBL+40 = the $00 before 'NEXT without FOR' at $0522); ERROR_REPORT_BODY_5 walks E NUL-terminated strings (CALL STMT_DATA+2 / INC HL / DEC E) to reach message #E for printing. $0521 is the string-table leading terminator, a real data base, not an operator-routine entry. / [RE] Integer-operator dispatch base. LD HL,OPERATOR_ROUTINE_TBL+30 ($0517 = IADD entry); LD B,$00 / ADD HL,BC twice (HL += 2*opcode), then LD C,(HL)/INC HL/LD B,(HL)/PUSH BC/RET jumps to IADD/INT_SIGNEXT_SUB/IMUL/IDIV/INT16_COMP. Genuine DEFW table-index dispatch. / [RE] Double-precision operator dispatch base. LD HL,OPERATOR_ROUTINE_TBL+10 ($0503 = DADD entry); A=($0B15), RLCA (2*op), 8-bit add into HL, then LD A,(HL)/INC HL/LD H,(HL)/LD L,A/JP (HL) jumps to DADD/DP_NEGATE_SIGN/DMUL/DDIV/DCOMP_REL. Genuine DEFW table-index dispatch.
OPERATOR_ROUTINE_TBL:
        DEFW    FN_CDBL
        DEFW    $0000
        DEFW    FN_CINT
        DEFW    FP_INT_CHECK
        DEFW    FN_CSNG
        DEFW    DADD
        DEFW    DP_NEGATE_SIGN
        DEFW    DMUL
        DEFW    DDIV
        DEFW    DCOMP_REL
        DEFW    FADD_ALIGN
        DEFW    FSUB
        DEFW    FMUL
        DEFW    FDIV
        DEFW    FCOMP
        DEFW    IADD
        DEFW    INT_SIGNEXT_SUB
        DEFW    IMUL
        DEFW    IDIV
        DEFW    INT16_COMP
; -- Error-message table. RAISE_ERROR is entered with the error code in E.
;    The base ERROR_MESSAGE_TABLE ($0521) is a $00 = the empty message 0; the printer
;    scans E terminators forward from it, so code E selects the E-th message (err 1 =
;    'NEXT without FOR'). BASIC errors are codes 1..N; the disk errors (FIELD overflow
;    on) are remapped to codes 50..70 (the scan does CP $32 / SUB $12). Codes are the
;    ERR_* equates (msbasic_errors.inc); messages are not individually referenced, so
;    only the few a trap loads by pointer keep an ERRMSG_* label.
; [RE] Error-message table base AND the direct-mode empty message: the $00 here is error message 0 (the scan base) and is also printed by ERROR_RESUME_FROM_DIRECT as the empty '?<>' direct-mode error text.
ERROR_MESSAGE_TABLE:
        DEFB    $00                      ; err 0 (empty message, scan base)
        DEFB    "NEXT without FOR",$00   ; ERR_NEXT_WITHOUT_FOR = 1
        DEFB    "Syntax error",$00       ; ERR_SYNTAX_ERROR = 2
        DEFB    "RETURN without GOSUB",$00  ; ERR_RETURN_WITHOUT_GOSUB = 3
        DEFB    "Out of DATA",$00        ; ERR_OUT_OF_DATA = 4
        DEFB    "Illegal function call",$00  ; ERR_ILLEGAL_FUNCTION_CALL = 5
; [RE] Error message string "Overflow" (error $06): loaded by the error reporter; the overflow trap also sets the current-message pointer ($0848) to it.
ERRMSG_OVERFLOW:
        DEFB    "Overflow",$00           ; ERR_OVERFLOW = 6
        DEFB    "Out of memory",$00      ; ERR_OUT_OF_MEMORY = 7
        DEFB    "Undefined line number",$00  ; ERR_UNDEFINED_LINE_NUMBER = 8
        DEFB    "Subscript out of range",$00  ; ERR_SUBSCRIPT_OUT_OF_RANGE = 9
        DEFB    "Duplicate Definition",$00  ; ERR_DUPLICATE_DEFINITION = 10
; [RE] Error message string "Division by zero" (error $0B): the FP divide-by-zero path stores this pointer into the current-error-message cell ($0848).
ERRMSG_DIVISION_BY_ZERO:
        DEFB    "Division by zero",$00   ; ERR_DIVISION_BY_ZERO = 11
        DEFB    "Illegal direct",$00     ; ERR_ILLEGAL_DIRECT = 12
        DEFB    "Type mismatch",$00      ; ERR_TYPE_MISMATCH = 13
        DEFB    "Out of string space",$00  ; ERR_OUT_OF_STRING_SPACE = 14
        DEFB    "String too long",$00    ; ERR_STRING_TOO_LONG = 15
        DEFB    "String formula too complex",$00  ; ERR_STRING_FORMULA_TOO_COMPLEX = 16
        DEFB    "Can't continue",$00     ; ERR_CANT_CONTINUE = 17
        DEFB    "Undefined user function",$00  ; ERR_UNDEFINED_USER_FUNCTION = 18
        DEFB    "No RESUME",$00          ; ERR_NO_RESUME = 19
        DEFB    "RESUME without error",$00  ; ERR_RESUME_WITHOUT_ERROR = 20
        DEFB    "Unprintable error",$00  ; ERR_UNPRINTABLE_ERROR = 21
        DEFB    "Missing operand",$00    ; ERR_MISSING_OPERAND = 22
        DEFB    "Line buffer overflow",$00  ; ERR_LINE_BUFFER_OVERFLOW = 23
        DEFB    "?",$00                  ; ERR_UNUSED_24 = 24
        DEFB    "?",$00                  ; ERR_UNUSED_25 = 25
        DEFB    "FOR Without NEXT",$00   ; ERR_FOR_WITHOUT_NEXT = 26
        DEFB    "?",$00                  ; ERR_UNUSED_27 = 27
        DEFB    "?",$00                  ; ERR_UNUSED_28 = 28
        DEFB    "WHILE without WEND",$00 ; ERR_WHILE_WITHOUT_WEND = 29
        DEFB    "WEND without WHILE",$00 ; ERR_WEND_WITHOUT_WHILE = 30
        DEFB    "Reset error",$00        ; ERR_RESET_ERROR = 31
    IFNDEF GBASIC
        DEFB    "Graphics statement not implemented",$00  ; MBASIC $0705  ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED = 32 (graphics-OFF marker; absent in GBASIC)
    ENDIF
        DEFB    "FIELD overflow",$00     ; ERR_FIELD_OVERFLOW = 50
        DEFB    "Internal error",$00     ; ERR_INTERNAL_ERROR = 51
        DEFB    "Bad file number",$00    ; ERR_BAD_FILE_NUMBER = 52
        DEFB    "File not found",$00     ; ERR_FILE_NOT_FOUND = 53
        DEFB    "Bad file mode",$00      ; ERR_BAD_FILE_MODE = 54
        DEFB    "File already open",$00  ; ERR_FILE_ALREADY_OPEN = 55
        DEFB    "?",$00                  ; ERR_UNUSED_56 = 56
        DEFB    "Disk I/O error",$00     ; ERR_DISK_I_O_ERROR = 57
        DEFB    "File already exists",$00  ; ERR_FILE_ALREADY_EXISTS = 58
        DEFB    "?",$00                  ; ERR_UNUSED_59 = 59
        DEFB    "?",$00                  ; ERR_UNUSED_60 = 60
        DEFB    "Disk full",$00          ; ERR_DISK_FULL = 61
        DEFB    "Input past end",$00     ; ERR_INPUT_PAST_END = 62
        DEFB    "Bad record number",$00  ; ERR_BAD_RECORD_NUMBER = 63
        DEFB    "Bad file name",$00      ; ERR_BAD_FILE_NAME = 64
        DEFB    "?",$00                  ; ERR_UNUSED_65 = 65
        DEFB    "Direct statement in file",$00  ; ERR_DIRECT_STATEMENT_IN_FILE = 66
        DEFB    "Too many files",$00     ; ERR_TOO_MANY_FILES = 67
        DEFB    "Disk Read Only",$00     ; ERR_DISK_READ_ONLY = 68
        DEFB    "Drive select error",$00 ; ERR_DRIVE_SELECT_ERROR = 69
        DEFB    "File Read Only",$00     ; ERR_FILE_READ_ONLY = 70
L_081F:
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFW    ERROR_FC
        DEFB    $01
; [RE] Pending-key cell: a console char captured by the Ctrl-C/Ctrl-S/INKEY$ poll (CONIN / keyboard scan); read by INKEY$, cleared on INLIN restart.
PENDING_KEY:
        DEFB    "\0"
; [RE] Active-error/RESUME state flag (MS BASIC ERRFLG): ON-ERROR loads it as the in-effect error code E ($3669); RESUME stores INC'd value ($3695); cold-start zeroes it ($826E). Same byte reused as the LIST/EDIT mode flag by the EDIT line resolver ($625D).
ERRFLG:
        DEFB    "\0\0"
; [RE] Current output column for the active device, tracked by OUTCHR (TAB stops, CR/backspace). LPOS() returns it; PRINT zone logic consults it.
OUTPUT_COLUMN:
        DEFB    $01
; [RE] PRTFLG (printer-output selector, whole-byte boolean -- no mask). Set to $01 by LPRINT ($3744) and LLIST ($40A8); cleared to 0 by the PRINT epilogue ($3880), OUTDO_RESET_COL ($667A), RESET_PRINT_STATE ($679D), and Ctrl-C ($6997). Read by OUTCHR ($661E, OR A / JP Z): nonzero routes the character through the printer-device path (with printer-specific backspace at $6627) instead of the console. UNKNOWN/CONFLICT: some in-file prose ($667A, $6997) describes this cell as an 'output-suppress' flag; that does not match the LPRINT/LLIST set sites (which mean 'direct output to printer'). Treat the 'suppress' wording as a probable mislabel pending a dedicated audit; do not assume a suppress semantic.
PRTFLG:
        DEFB    "\0"
L_0839:
        DEFB    "p"
L_083A:
        DEFB    $84
; [RE] Terminal/output line width in columns; set by WIDTH, used by PRINT comma-zones and the FILES directory column layout.
PRINT_WIDTH:
        DEFB    "P"
; [RE] Lines-per-page for the LIST/output auto-page pause; compared against the printed-line counter ($0B12).
PAGE_LENGTH:
        DEFB    $18
; [RE] Per-file output line width (set by WIDTH #file,width).
WIDTH_FILE:
        DEFB    "8"
L_083E:
        DEFB    "\0"
; Ctrl-O output-suppress toggle: nonzero discards console output. Cleared at READY/cold-start, toggled by CONIN on Ctrl-O ($0F) and cleared on Ctrl-C. (Already commented in file.)
CTRL_O_SUPPRESS:
        DEFB    "\0"
; [RE] PTRFIL: 16-bit pointer to the current file's FCB (MS BASIC PTRFIL). 0 = console/keyboard; nonzero = the FCB base of the file currently selected by a #file expression. Set by STORE_CUR_FCB_PTR ($7623-$7629, = the FCB pointer that FILE_NUM_TO_FCB resolved) for PRINT#/INPUT#/WRITE#/GET/PUT; cleared to 0 by the PRINT/INPUT epilogue ($3886) and CHAIN/OPEN reinit ($0F33). Read as a pointer (LD HL,(PTRFIL); LD A,H; OR L) by OUTCHR ($6615) and the per-PRINT-item path ($3788) to route a char to the file (PUTC_FILE_RESUME) instead of the console, and by INCHR ($6725) to read the next char from the file (GETC_FILE_EOF) instead of the keyboard. OBSERVED: every one of the 28 accesses is a 16-bit word move, never a bit/mask test, so this is a pointer, not a boolean redirect flag.
PTRFIL:
        DEFB    "\0\0"
; [RE] Top-of-stack-room / stack-limit pointer (MS BASIC STKTOP family); cold start sets it = COLD_STACK_BASE ($81DB). The image default is a relocatable placeholder, overwritten before use.
TOP_OF_STACK_ROOM:
        DEFW    INTERP_RUN_TOP+$3A
; [RE] Saved current text/statement pointer (MS BASIC SAVTXT): the running program pointer loaded into HL to execute; set to $FFFF in direct mode; CONT checks ==$FFFF for 'no continue'. Default $FFFE. Loaded/saved across CONT/RESUME and the storage-overflow guard.
SAVTXT:
        DEFB    $FE,$FF
; [RE] TXTTAB: start-of-BASIC-program-text pointer = head of the singly-linked list of BASLINE program-line nodes (see msbasic_line.inc); walked forward by FNDLIN/CHEAD-relink/RUN/CLEAR. Cold-start default = COLD_STACK_BASE+1, i.e. one byte past the $00 link-null sentinel at the cold-start stack base; reset when a program is loaded.
TXTTAB:
        DEFW    COLD_STACK_BASE+1
L_0848:
        DEFB    $77,$05
L_084A:
        DEFB    "\0"
L_084B:
        DEFB    "\0"
FIELD_WRITE_FLAG:
        DEFB    "\0\0"
; [RE] Seed pointer for slot 0 of the file/FOR-slot pointer array at $0850: cold-start loads it with the warm-start re-entry MAIN_LOOP_ENTRY_1 ($81D1) and the CHAIN/OPEN reinit copies $084E into $0850/$0840 after CLEAR_VARS. Effectively the default first-slot/command pointer.
FILTAB_SLOT0_SEED:
        DEFB    "\0\0"
; [RE] File/FOR-slot pointer array (MS BASIC FILTAB), indexed by max-open-files ($0870); each entry points at an FCB base. Slot 0 doubles as the deferred start-up command pointer consulted at the Ok/main-loop entry ($81D1). 126-byte region.
FILTAB:
        DEFS    32, $00                  ; fill
MAX_FILE_NUM:
        DEFB    "\0"
L_0871:
        DEFB    "\0"
L_0872:
        DEFS    38, $00                  ; fill
L_0898:
        DEFB    "\0\0"
RENAME_FCB:
        DEFS    16, $00                  ; fill
SCRATCH_FCB:
        DEFB    "\0"
SCRATCH_FCB_NAME:
        DEFS    8, $00                   ; fill
SCRATCH_FCB_TYPE:
        DEFB    "\0\0\0"
SCRATCH_FCB_EX:
        DEFS    21, $00                  ; fill
L_08CB:
        DEFB    "\0"
BDOS_FN_RECREAD:
        DEFB    "\0"
BDOS_FN_RECWRITE:
        DEFB    "\0"
L_08CE:
        DEFB    ":"
; [RE] CRUNCH tokenizer line work buffer (MS BASIC KBUF): 318-byte zero-init RAM area; CRUNCH loads DE=$08CF as the destination where the crunched/tokenized line is built (and the LIST de-tokenizer reuses it). NOT the reserved-word name table (those strings live at $025E-$04D7; $04D8 is the operator sub-table).
KBUF:
        DEFS    49, $00                  ; fill
        DEFS    56, $00                  ; fill
        DEFS    23, $00                  ; fill
        DEFS    123, $00                 ; fill
        DEFS    52, $00                  ; fill
        DEFB    "\0"
        DEFS    14, $00                  ; fill
L_0A0D:
        DEFB    ","
; Console line-input buffer (MS BASIC BUF): INLIN reads/echoes the edited input line here; Ctrl-U/Ctrl-R reset the pointer to $0A0E. Buffer body continues through $0A1E.
BUF:
        DEFS    16, $00                  ; fill
        DEFS    242, $00                 ; fill
L_0B10:
        DEFB    "\0"
L_0B11:
        DEFB    "\0"
L_0B12:
        DEFB    "\0"
L_0B13:
        DEFB    "\0"
VALTYP:
        DEFB    "\0"
; [RE] CRUNCH_LITERAL_MODE: CRUNCH literal-passthrough flag (whole-byte boolean, no mask). Cleared at CRUNCH entry ($3004); set to 1 at $3201 right after emitting a ':' statement-separator or a DATA-class token; tested at CRUNCH_SCAN ($301C, OR A / JP NZ) -- when set, the current source character is copied through verbatim instead of being reserved-word-matched. TEMPORALLY REUSED (not concurrent) by FRMEVL as the binary-operator scratch: FRMEVL_OPCOMBINE writes the operator code here ($3B54) and the operator-dispatch index reads it ($3BA9). Same byte, different tenant at a different phase.
CRUNCH_LITERAL_MODE:
        DEFB    "\0"
; [RE] CRUNCH_LINENUM_MODE: CRUNCH line-number-introducer flag (whole-byte boolean, no mask). Set to 1 when the token just crunched is a keyword that is followed by a line number (GOTO/GOSUB/THEN/ELSE/RUN/LIST/RESTORE/etc.; armed via CRUNCH_STORE_FLAG_AND_EMIT $311C) and after ':' ($3204); cleared at CRUNCH entry ($3001) and $30D3. Tested at CRUNCH_18 ($314B, OR A / JR Z): when set, a following digit run is emitted as a line-number constant (token $0E + 2-byte line number via LINGET, $315C) instead of being parsed as an ordinary numeric literal (FIN at $3179).
CRUNCH_LINENUM_MODE:
        DEFB    "\0"
CONST_TEXT_RESUME:
        DEFB    "\0\0"
CONST_TOKEN:
        DEFB    "\0"
CONST_VALTYP:
        DEFB    "\0"
CONST_VALUE:
        DEFB    "\0\0"
CONST_VALUE_HI:
        DEFB    "\0"
        DEFB    "\0\0\0\0\0"
; Top-of-storage / highest usable RAM pointer (MS BASIC MEMSIZ): cold-start sets it below the stack; GETSTK checks SP vs MEMSIZ; the string heap top ($0B48) seeds from it. Read by GARBAG.
MEMSIZ:
        DEFB    "\0\0"
TEMPPT:
        DEFB    "\0\0"
; [RE] TEMPST: base of the temporary string-descriptor stack -- a small array of STRDESC records (msbasic_strdesc.inc, 3 bytes each) holding intermediate string FRMEVL results. TEMPPT ($0B25) is the live top-of-stack pointer; PUT_STR_TEMP pushes here, FREE_TOP_TEMP_DESCR pops. Overflowing this region raises 'String formula too complex'. The DEFS reservation spans the descriptor slots (followed by DSCTMP at $0B45).
TEMPST:
        DEFS    15, $00                  ; fill
; [RE] NOT a data object: $0B36 is the bias base used to index DEFTYPE_TBL ($0B77) by a variable's raw ASCII first-letter code. PTRGET ($5FA6) loads HL = DEFTYPE_TBL-$41 (= $0B36) then ADD HL,(letter&$7F) so $0B36+$41('A')=$0B77 ... $0B36+$5A('Z')=$0B90. The 15-byte DEFS here ($0B36-$0B44) is unrelated workspace/padding; the per-letter default-type cells physically live at DEFTYPE_TBL ($0B77).
L_0B36:
        DEFS    15, $00                  ; fill
; [RE] DSCTMP: the one-entry working string descriptor (STRDESC, msbasic_strdesc.inc) -- STORE_STR_DESC writes the freshly-built len/pointer here ($6BDF LD HL,DSCTMP then STR_DESC_STORE), and PUT_STR_TEMP ($6C1A) copies it from here onto the temp-descriptor stack (TEMPPT/TEMPST). DSCTMP.LEN=$0B45, DSCTMP.PTR=$0B46 (the existing $0B46 word).
DSCTMP:
        DEFB    "\0"
L_0B46:
        DEFB    "\0\0"
; [RE] Top-of-free-string-space pointer (MS BASIC FRETOP): the string heap allocates downward from here; GETSPA decrements it, FRESTR1 hands back the topmost string, GARBAG slides live strings up to it. Seeded from MEMSIZ at cold-start/CLEAR.
FRETOP:
        DEFB    "\0\0"
L_0B4A:
        DEFB    "\0\0"
L_0B4C:
        DEFB    "\0\0"
L_0B4E:
        DEFB    "\0\0"
; [RE] Saved text pointer of the current DATA line during a READ ($3A5C stores the located DATA line ptr). On a READ-time parse error STMT_LINE_1 restores it into SAVTXT ($0D69 -> $0844) so '? ... in <line>' reports against the DATA line, not the READ line.
DATA_LINE_TXTPTR:
        DEFB    "\0\0"
PTRGET_SUBSCRIPT_FLAG:
        DEFB    "\0"
L_0B53:
        DEFB    "\0"
OPEN_RESUME_TEXT_PTR:
        DEFB    "\0\0"
L_0B56:
        DEFB    "\0"
; [RE] AUTO line-numbering mode flag: AUTO sets it nonzero ($36F9) with start/increment in $0B58/$0B5A; the READY/line dispatcher checks it to auto-generate the next line-number prompt and clears it on completion/overflow; CLEAR_VARS zeroes it.
AUTFLG:
        DEFB    "\0"
; [RE] AUTO current/next line number: set by the AUTO command ($36FD) and advanced by $0B5A each input; the line dispatcher uses it to prompt/insert the next auto-numbered line.
AUTLIN:
        DEFB    "\0\0"
; [RE] AUTO line-number increment (default $000A): set by the AUTO command ($36F6) and added to AUTLIN ($0B58) by the line dispatcher to form the next auto line number.
AUTINC:
        DEFB    "\0\0"
; [RE] Saved text pointer of the current statement (MS BASIC OLDTXT): NEWSTT records it each statement ($3374); STOP/END copies it to the CONT save ($0B6D at $6979); error/'Redo from start' restores from it.
OLDTXT:
        DEFB    "\0\0"
; [RE] Saved stack pointer (MS BASIC SAVSTK): written via LD ($0B5E),SP at NEWSTT ($3377) and cold-start; restored to SP on error-recovery / FOR-stack unwinding (e.g. STMT_CALL_6 $72AF) to discard pending expression frames.
SAVSTK:
        DEFB    "\0\0"
; [RE] Error-handler saved text pointer: RAISE_ERROR stores SAVTXT ($0844) here ($0D8C); the message printer reads it ($0DFC/$0E00) to decide direct vs '? ... in <line>'; RESUME reloads it into SAVTXT ($36B5).
ERR_SAVTXT:
        DEFB    "\0\0"
; [RE] Saved program line of the last error (MS BASIC ERRLIN): RAISE_ERROR records the offending line ($0D9B) for ERR/ERL reporting; LINGET '.' shortcut substitutes it as the current line number ($34D9).
ERRLIN:
        DEFB    "\0\0"
; [RE] Saved current-statement text pointer for RESUME (copy of OLDTXT, stashed by the error reporter at $0DB0); RESUME ($36AE) reloads it to re-execute the statement that errored.
RESUME_TXTPTR:
        DEFB    "\0\0"
; [RE] ON ERROR GOTO handler pointer (MS BASIC ONELIN): set by ON ERROR ($365E); the error reporter ($0DC3) traps to it when nonzero, else prints the error. Zero = no active handler.
ON_ERROR_LINE:
        DEFB    "\0\0"
; [RE] ON-ERROR trap-active flag (MS BASIC ONEFLG): nonzero while inside an error handler. Gates ON-ERROR dispatch and RESUME, and is tested by PROGRAM_END so a handler that runs off the end of the program raises 'No RESUME' (ERR_NO_RESUME); cleared by CLEAR.
ONEFLG:
        DEFB    "\0"
; [RE] FRMEVL operand text-pointer scratch (general TEMP): the precedence loop saves/reloads the current (HL) here ($3A85/$3A88) across operator recursion. The same cell is reused by FOUT to record the decimal-point buffer position during numeric formatting.
FRMEVL_TXTPTR_TEMP:
        DEFB    "\0\0"
; [RE] Saved error/statement text pointer (copy of ERR_SAVTXT when valid), stashed by the error reporter ($0DBC) and reloaded by CONT ($69B7).
SAVED_ERR_TXTPTR:
        DEFB    "\0\0"
; [RE] CONT resume text pointer (copy of OLDTXT): STOP/END save it ($6979), the error reporter saves it ($0DC0), and CONT ($69AB) reloads it to resume the stopped program.
CONT_TXTPTR:
        DEFB    "\0\0"
; [RE] VARTAB: base of the SIMPLE-VARIABLE table (SIMPLEVAR records, see msbasic_var.inc). Table runs VARTAB($0B6F)..ARYTAB($0B71); the array table follows ARYTAB..STREND($0B73). Walked by PTRGET ($5FC9) and GARBAG ($6CAD); CLEAR re-points all three just above program text ($68D9). Each SIMPLEVAR = {valtyp byte; 2 name bytes; namextlen byte; namext[]; value[valtyp]} reached by computed stride (NAMEXTLEN+VALTYP+1), never base+offset.
VARTAB:
        DEFB    "\0\0"
ARYTAB:
        DEFB    "\0\0"
STREND:
        DEFB    "\0\0"
L_0B75:
        DEFB    "\0\0"
; [RE] DEFTYPE_TBL: the 26-byte per-letter default value-type array (one VALTYP byte per variable initial letter A..Z; MS BASIC DEFTBL). Written by the DEF* statement handler (STMT_DEFSTR $34B4: stores the requested type code E across the letter range) and reset to the default ($04) for all 26 letters by CLEAR/RUN ($68A3). PTRGET reads the default type for a variable's first letter via the bias-base addressing at $5FA6 (base $0B36 + ASCII-letter-code lands here: $0B36+$41='A'->$0B77 ... $0B36+$5A='Z'->$0B90). NOTE the default fill value is $04; the exact VALTYP code->precision mapping is not asserted here (the file's own type-code notes are inconsistent) -- see UNKNOWNS.
DEFTYPE_TBL:
        DEFS    26, $00                  ; fill
L_0B91:
        DEFB    "\0\0"
L_0B93:
        DEFB    "\0\0"
L_0B95:
        DEFS    78, $00                  ; fill
        DEFS    22, $00                  ; fill
L_0BF9:
        DEFW    L_0B91
L_0BFB:
        DEFB    "\0\0"
L_0BFD:
        DEFS    38, $00                  ; fill
        DEFB    "\0\0\0\0\0"
        DEFS    57, $00                  ; fill
L_0C61:
        DEFB    "\0"
L_0C62:
        DEFB    "\0"
L_0C63:
        DEFB    "\0"
L_0C64:
        DEFB    "\0"
L_0C65:
        DEFB    "\0\0"
L_0C67:
        DEFB    "\0\0"
L_0C69:
        DEFB    "\0"
L_0C6A:
        DEFB    "\0\0"
L_0C6C:
        DEFB    "\0"
FOR_NEXT_VALUE_TEMP:
        DEFB    "\0\0\0\0"
L_0C71:
        DEFB    "\0\0"
L_0C73:
        DEFB    "\0"
L_0C74:
        DEFB    "\0"
; [RE] In-RAM call trampoline: POP return addr into HL, restore AF/DE off the stack, JP (HL). Re-enters caller with saved A/flags and DE.
RAM_DISPATCH_TRAMPOLINE:
        POP HL
        POP DE
        POP AF
        PUSH AF
        PUSH DE
        JP (HL)
        DEFS    24, $00                  ; fill
L_0C93:
        DEFB    "\0"
L_0C94:
        DEFB    "\0"
L_0C95:
        DEFB    "\0\0"
FIELD_BUF_ADDR_LIMIT:
        DEFB    "\0\0"
L_0C99:
        DEFB    "\0"
; [RE] CHAIN/ON-ERROR 'preserve variables' flag: CHAIN-with-ALL and CHAIN set it ($72BA/$72C7) so the CLEAR storage reset skips clearing variable space ($6894 test); RAISE_ERROR clears it ($0D90); cold-start zeroes it.
CHAIN_PRESERVE_FLAG:
        DEFB    "\0"
L_0C9B:
        DEFB    "\0"
L_0C9C:
        DEFB    "\0\0"
L_0C9E:
        DEFB    "\0\0"
; [RE] CHAIN-in-progress / break-pause flag: set to 1 during CHAIN string-var move ($752C) so the CLEAR reset preserves the string heap ($68CC test); also the Ctrl-C/list-pause flag polled by the auto-page LIST 'more' handler ($673B). Cleared by RAISE_ERROR and cold-start.
CHAIN_BREAK_FLAG:
        DEFB    "\0"
L_0CA1:
        DEFB    "\0\0"
L_0CA3:
        DEFS    8, $00                   ; fill
; [RE] TRCFLG: MS BASIC execution-trace flag (whole-byte boolean). TRON sets it $AF, TROFF / program start sets it $00 (STMT_TRACE $69BF, via the AF/XOR-A dual-entry skip). NEWSTT reads it each line ($3393, OR A / JR Z) and, when nonzero, prints '[<linenum>]' before executing the line. No bitmask -- any nonzero value means trace on.
TRCFLG:
        DEFB    "\0"
L_0CAC:
        DEFB    "\0"
L_0CAD:
        DEFB    "\0\0"
L_0CAF:
        DEFB    "\0"
L_0CB0:
        DEFB    "\0"
FAC:
        DEFB    "\0\0"
FACHI:
        DEFB    "\0"
L_0CB4:
        DEFB    "\0"
L_0CB5:
        DEFB    "\0"
L_0CB6:
        DEFB    "\0"
L_0CB7:
        DEFB    "\0"
L_0CB8:
        DEFB    "\0"
L_0CB9:
        DEFB    "\0"
L_0CBA:
        DEFB    "\0\0\0\0\0\0"
L_0CC0:
        DEFB    "\0"
L_0CC1:
        DEFB    "\0"
L_0CC2:
        DEFB    "\0"
L_0CC3:
        DEFS    10, $00                  ; fill
        DEFS    16, $00                  ; fill
L_0CDD:
        DEFB    "\0\0\0\0\0\0"
L_0CE3:
        DEFB    "\0"
L_0CE4:
        DEFS    9, $00                   ; fill
L_0CED:
        DEFB    " in "
L_0CF1:
        DEFB    "\0"
; [RE] The 'Ok' ready-prompt string (Ok CR LF NUL), printed by the READY loop / direct-mode return.
MSG_OK:
        DEFB    "Ok\r\n\0"
; [RE] The 'Break' message string, printed by STOP / Ctrl-C ('Break' [+ ' in <line>']).
MSG_BREAK:
        DEFB    "Break"                  ; string
        DEFB    $00                      ; terminator
; [RE] Entry to FOR/GOSUB stack-frame fixup: HL = SP+4, fall into STKFRAME_SCAN to walk the runtime stack.
STKFRAME_SCAN_INIT:
        LD HL,$0004
        ADD HL,SP
; [RE] Walk runtime stack frames: skip FOR frames (token $AF, +16/+6 bytes), find GOSUB markers ($82), compare each frame's text pointer vs HL via FNDLIN-cmp ($691F) to fix up frames after a program edit/delete.
STKFRAME_SCAN:
        LD A,(HL)
        INC HL
        CP $AF
STKFRAME_SCAN_1:
        JR NZ,STKFRAME_SCAN_3
        LD BC,$0006
        ADD HL,BC
STKFRAME_SCAN_2:
        JR STKFRAME_SCAN
STKFRAME_SCAN_3:
        CP $82
        RET NZ
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH HL
        LD L,C
        LD H,B
        LD A,D
        OR E
        EX DE,HL
        JR Z,STKFRAME_SCAN_5
        EX DE,HL
STKFRAME_SCAN_4:
        CALL CMP_HL_DE
STKFRAME_SCAN_5:
        LD BC,$0010
        POP HL
        RET Z
        ADD HL,BC
        JR STKFRAME_SCAN
SUB_0D28:
        LD BC,ERROR_RESUME_FROM_DIRECT_3+1
        JP ERROR_PRINT_SETUP_1
; [RE] PROGRAM_END: reached from NEWSTT (JP Z) when a line link is $0000 -- execution ran off the end of the program. If SAVTXT is $FFFF (direct mode), fall through to the ready/Ok-prompt return; otherwise, if an error handler is active (ONEFLG set) it ran off the end without RESUME, so raise 'No RESUME' (ERR_NO_RESUME). The CONT command and its 'Can't continue' error live in STMT_CONT, not here.
PROGRAM_END:
        LD HL,(SAVTXT)
        LD A,H
        AND L
        INC A
        JR Z,PROGRAM_END_1
        LD A,(ONEFLG)
        OR A
        LD E,ERR_NO_RESUME
        JR NZ,RAISE_ERROR
PROGRAM_END_1:
        JP RESUME_AT_DIRECT
; Named-error entry stubs: each loads an error code into E (LD E,ERR_* via the $1E opcode of the next LD BC) then falls through to RAISE_ERROR. Overlapping table of error vectors -- code JPs to a specific entry to raise that error.
RAISE_DISK_FULL:
        LD E,ERR_DISK_FULL               ; raise error 61
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_DISK_I_O_ERROR:
        LD E,ERR_DISK_I_O_ERROR          ; raise error 57
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_BAD_FILE_MODE:
        LD E,ERR_BAD_FILE_MODE           ; raise error 54
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_FILE_NOT_FOUND:
        LD E,ERR_FILE_NOT_FOUND          ; raise error 53
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_BAD_FILE_NUMBER:
        LD E,ERR_BAD_FILE_NUMBER         ; raise error 52
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_INTERNAL_ERROR:
        LD E,ERR_INTERNAL_ERROR          ; raise error 51
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_INPUT_PAST_END:
        LD E,ERR_INPUT_PAST_END          ; raise error 62
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_FILE_ALREADY_OPEN:
        LD E,ERR_FILE_ALREADY_OPEN       ; raise error 55
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_BAD_FILE_NAME:
        LD E,ERR_BAD_FILE_NAME           ; raise error 64
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_BAD_RECORD_NUMBER:
        LD E,ERR_BAD_RECORD_NUMBER       ; raise error 63
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_FIELD_OVERFLOW:
        LD E,ERR_FIELD_OVERFLOW          ; raise error 50
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_TOO_MANY_FILES:
        LD E,ERR_TOO_MANY_FILES          ; raise error 67
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_FILE_ALREADY_EXISTS:
        LD E,ERR_FILE_ALREADY_EXISTS     ; raise error 58
        JR RAISE_ERROR
; [RE] Restore saved program pointer ($0B50 -> $0844) on the no-continue path before re-entering the error/ready flow.
CONT_RESUME_RESTORE:
        LD HL,(DATA_LINE_TXTPTR)
        LD (SAVTXT),HL
; Syntax-error entry: LD E,ERR_SYNTAX_ERROR then fall through the coded-error table into RAISE_ERROR. Common target of statement parsers (JP RAISE_SYNTAX_ERROR).
RAISE_SYNTAX_ERROR:
        LD E,ERR_SYNTAX_ERROR            ; raise error 2
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_DIVISION_BY_ZERO:
        LD E,ERR_DIVISION_BY_ZERO        ; raise error 11
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_NEXT_WITHOUT_FOR:
        LD E,ERR_NEXT_WITHOUT_FOR        ; raise error 1
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_DUPLICATE_DEFINITION:
        LD E,ERR_DUPLICATE_DEFINITION    ; raise error 10
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_UNDEFINED_USER_FUNCTION:
        LD E,ERR_UNDEFINED_USER_FUNCTION ; raise error 18
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_RESUME_WITHOUT_ERROR:
        LD E,ERR_RESUME_WITHOUT_ERROR    ; raise error 20
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_OVERFLOW:
        LD E,ERR_OVERFLOW                ; raise error 6
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_MISSING_OPERAND:
        LD E,ERR_MISSING_OPERAND         ; raise error 22
        DEFB    $01                      ; LD BC opcode = skip the next LD E
RAISE_TYPE_MISMATCH:
        LD E,ERR_TYPE_MISMATCH           ; raise error 13
; [RE] Raise/report error #E (entered with the error code in E). Saves the current text pointer (SAVTXT) to ERR_SAVTXT, clears the ON-ERROR/CHAIN flags (CHAIN_PRESERVE_FLAG / CHAIN_BREAK_FLAG), records the offending line in ERRLIN, then either dispatches to the ON ERROR handler or prints '?<message> Error[ in <line>]' and returns to direct mode via RESET_RUN_STATE. The message is found by scanning E entries from ERROR_MESSAGE_TABLE; the error codes are the ERR_* equates.
RAISE_ERROR:
        LD HL,(SAVTXT)
        LD (ERR_SAVTXT),HL
        XOR A
        LD (CHAIN_PRESERVE_FLAG),A
        LD (CHAIN_BREAK_FLAG),A
        LD A,H
        AND L
        INC A
        JR Z,ERROR_PRINT_SETUP
        LD (ERRLIN),HL
; [RE] ERROR_PRINT_SETUP: stages BC=ERROR_REPORT_BODY and HL=(SAVSTK), then JP RESET_RUN_STATE. Prints nothing itself; there is no '?'+mnemonic+' Error' assembly here (BASIC-80 uses full-word error messages).
ERROR_PRINT_SETUP:
        LD BC,ERROR_REPORT_BODY
ERROR_PRINT_SETUP_1:
        LD HL,(SAVSTK)
        JP RESET_RUN_STATE
; [RE] ERROR_REPORT_BODY: the error-print body, reached via RESET_RUN_STATE's RET. Indexes ERROR_MESSAGE_TABLE by the clamped/remapped error code and prints the full-word message string. There is NO packed 2-letter-mnemonic table and no ERROR_PRINT_MSG routine (those belong to the smaller 4K/8K BASIC; this is BASIC-80).
ERROR_REPORT_BODY:
        POP BC
        LD A,E
        LD C,E
        LD (ERRFLG),A
        LD HL,(OLDTXT)
        LD (RESUME_TXTPTR),HL
        EX DE,HL
        LD HL,(ERR_SAVTXT)
        LD A,H
        AND L
        INC A
        JR Z,ERROR_REPORT_BODY_1
        LD (SAVED_ERR_TXTPTR),HL
        EX DE,HL
        LD (CONT_TXTPTR),HL
ERROR_REPORT_BODY_1:
        LD HL,(ON_ERROR_LINE)
        LD A,H
        OR L
        EX DE,HL
        LD HL,ONEFLG
        JR Z,ERROR_REPORT_BODY_2
        AND (HL)
        JR NZ,ERROR_REPORT_BODY_2
        DEC (HL)
        EX DE,HL
        JP NEWSTT_NEXTLINE
ERROR_REPORT_BODY_2:
        XOR A
        LD (HL),A
        LD E,C
        LD (CTRL_O_SUPPRESS),A
        CALL PRINT_CRLF_IF_COL
        LD HL,ERROR_MESSAGE_TABLE
        LD A,E
        CP $47
        JR NC,ERROR_REPORT_BODY_3
        CP $32
        JR NC,ERROR_REPORT_BODY_4
    IFDEF GBASIC
        CP $20                           ; (printable-range upper bound)
    ELSE
        CP $21                           ;        MBASIC: +1, the code-32 graphics slot
    ENDIF
        JR C,ERROR_REPORT_BODY_5
ERROR_REPORT_BODY_3:
    IFDEF GBASIC
        LD A,$27                         ; (clamp index for codes >= $20)
    ELSE
        LD A,$26                         ;        MBASIC: -1 (one more printable slot)
    ENDIF
ERROR_REPORT_BODY_4:
    IFDEF GBASIC
        SUB $12                          ; (disk-code -> message-index bias)
    ELSE
        SUB $11                          ;        MBASIC: -1, the code-32 graphics slot
    ENDIF
        LD E,A
ERROR_REPORT_BODY_5:
        CALL STMT_DATA+2
        INC HL
        DEC E
        JR NZ,ERROR_REPORT_BODY_5
        PUSH HL
ERROR_REPORT_BODY_6:
        LD HL,(ERR_SAVTXT)
        EX (SP),HL
; [RE] After error message: if current line is direct (text begins '?'), point at the canned direct-mode message ($0521); else print ' in <line>' and drop to READY.
ERROR_RESUME_FROM_DIRECT:
        LD A,(HL)
        CP $3F
        JR NZ,STOP_BREAK
        POP HL
        LD HL,ERROR_MESSAGE_TABLE
        JR ERROR_REPORT_BODY_3
; [RE] STOP/Ctrl-C break: print 'Break' message ($6C40 STROUT), compute/print the current line number, then fall into the READY prompt and NEWSTT main loop.
STOP_BREAK:
        CALL STROUT
        POP HL
        LD DE,$FFFE
        CALL CMP_HL_DE
        CALL Z,CRLF
        JP Z,STMT_SYSTEM_WBOOT
        LD A,H
        AND L
        INC A
ERROR_RESUME_FROM_DIRECT_2:
        CALL NZ,FOUT_PRINT
ERROR_RESUME_FROM_DIRECT_3:
        DEFB    $3E                      ; LD A,# cover -- the fall-through loads A=$C1 from the next byte
; [RE] POP one return frame off the stack, then fall into the prompt/READY loop (NEWSTT_READY). Entered mid-instruction as the $C1 (POP BC) operand byte of the LD A,$C1 cover at the preceding label; the cover's fall-through instead loads A=$C1 (default prompt char).
READY_POP_FRAME:
        POP BC                           ; the LD operand byte, entered here as an opcode (coded overlap)
; READY/main interpreter loop: print prompt char, clear output column $083F, read a console line ($781A), then process it (tokenize or execute).
NEWSTT_READY:
        CALL OUTDO_RESET_COL
        XOR A
        LD (CTRL_O_SUPPRESS),A
        CALL LOAD_CLEANUP_RESET
        CALL PRINT_CRLF_IF_COL
        LD HL,MSG_OK
NEWSTT_READY_1:
        DEFB    $CD                      ; LL opcode -- target word self-modified at runtime (patched via LD (next),HL)
; [RE] Self-modified operand word of the CALL at $0E33 in the prompt/message print path (LD HL,<msg> / CALL through here). The cold sign-on patches it ONCE to STROUT ($6C40), via LD HL,STROUT / LD (STROUT_CALL_VECTOR),HL at $83E8 -- byte-scan confirms a SINGLE writer in both builds and it is never re-pointed, so after init the call is effectively CALL STROUT, not a runtime-varying dispatch. The indirection is NOT an address-resolution workaround: low-RAM JPs into the relocated body directly elsewhere (e.g. JP RESET_RUN_STATE = $68F4 at $0DA4). Why the original used a patchable cell here rather than a direct CALL is not determinable from the bytes. Init $0000.
STROUT_CALL_VECTOR:
        DEFW    $0000                    ; the patched CALL target (init $0000)
        LD A,(ERRFLG)
NEWSTT_READY_2:
        SUB $02
        CALL Z,STMT_EDIT_LINENUM
; [RE] Process the input line: FOUT the leading line number, FNDLIN to locate it, CRUNCH-tokenize ($3000), then insert/replace/delete in the program or execute as a direct statement.
DIRECT_LINE_DISPATCH:
        LD HL,$FFFF
        LD (SAVTXT),HL
        LD A,(AUTFLG)
        OR A
        JR Z,SUB_0E7B_2
        LD HL,(AUTLIN)
        PUSH HL
        CALL FOUT
        POP DE
        PUSH DE
        CALL FNDLIN
        LD A,$2A
        JR C,DIRECT_LINE_DISPATCH_1
        LD A,$20
DIRECT_LINE_DISPATCH_1:
        CALL OUTCHR
        CALL INLIN_RESET_LINE
        POP DE
        JR NC,DIRECT_LINE_DISPATCH_3
        XOR A
        LD (AUTFLG),A
        JR NEWSTT_READY
DIRECT_LINE_DISPATCH_2:
        XOR A
        LD (AUTFLG),A
        JR SUB_0E7B_1
DIRECT_LINE_DISPATCH_3:
        LD HL,(AUTINC)
        ADD HL,DE
        JR C,DIRECT_LINE_DISPATCH_2
        PUSH DE
        LD DE,$FFF9
        CALL CMP_HL_DE
        POP DE
        JR NC,DIRECT_LINE_DISPATCH_2
        LD (AUTLIN),HL
SUB_0E7B_1:
        LD A,(BUF)
        OR A
        JR Z,DIRECT_LINE_DISPATCH
        JP PRINT_LIST_ENTRY
SUB_0E7B_2:
        CALL INLIN_RESET_LINE
        JR C,DIRECT_LINE_DISPATCH
        CALL CHRGET
        INC A
        DEC A
        JR Z,DIRECT_LINE_DISPATCH
        PUSH AF
        CALL LINGET
        CALL CRUNCH_SKIP_BLANKS_BACK
        LD A,(HL)
        CP $20
        CALL Z,FP_LOAD_DONE
; [RE] Execute a tokenized direct-mode statement: CHRGET-prime and call the statement dispatcher; on a bare line number fall to edit/insert.
DIRECT_EXEC_STMT:
        PUSH DE
        CALL CRUNCH
        POP DE
        POP AF
        LD (OLDTXT),HL
        JP NC,DIRECT_STMT_EXEC
        PUSH DE
        PUSH BC
        CALL ILLEGAL_DIRECT_CHECK
        CALL CHRGET
        OR A
        PUSH AF
        EX DE,HL
        LD (ERRLIN),HL
        EX DE,HL
        CALL FNDLIN
        JR C,SUB_0EB7_1
        POP AF
        PUSH AF
        JP Z,ERROR_UL
        OR A
SUB_0EB7_1:
        PUSH BC
        PUSH AF
        PUSH HL
        CALL RENUM_FIXUP_IF_PENDING
        POP HL
        POP AF
        POP BC
        PUSH BC
        CALL C,BLOCK_MOVE_TO_VARTAB
        POP DE
        POP AF
        PUSH DE
        JR Z,SUB_0EB7_4
        POP DE
        LD A,(CHAIN_BREAK_FLAG)
        OR A
        JR NZ,SUB_0EB7_2
        LD HL,(MEMSIZ)
        LD (FRETOP),HL
SUB_0EB7_2:
        LD HL,(VARTAB)
        EX (SP),HL
        POP BC
        PUSH HL
        ADD HL,BC
        PUSH HL
        CALL STR_COPY_DOWN
        POP HL
        LD (VARTAB),HL
        EX DE,HL
        LD (HL),H                        ; store a BASLINE.LINK placeholder here; CHEAD ($0F39) rebuilds the real forward link
        POP BC
        POP DE
        PUSH HL
        INC HL
        INC HL
        LD (HL),E                        ; write BASLINE.LINENUM (the two INC HL at $0EFF/$0F00 skipped past BASLINE.LINK)
        INC HL
        LD (HL),D
        INC HL
        LD DE,KBUF
        DEC BC
        DEC BC
        DEC BC
        DEC BC
SUB_0EB7_3:
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        DEC BC
        LD A,C
        OR B
        JR NZ,SUB_0EB7_3
SUB_0EB7_4:
        POP DE
        CALL CHEAD_LOOP
        LD HL,$0080
        LD (HL),$00
SUB_0EB7_5:
        LD (FILTAB),HL
        LD HL,(PTRFIL)
        LD (FRMEVL_TXTPTR_TEMP),HL
        CALL CLEAR_RESET_DATAPTR
        LD HL,(FILTAB_SLOT0_SEED)
        LD (FILTAB),HL
        LD HL,(FRMEVL_TXTPTR_TEMP)
        LD (PTRFIL),HL
        JP DIRECT_LINE_DISPATCH
; [RE] CHEAD: relink the BASLINE program-line list from TXTTAB ($0846). Walk each node to its $00 token terminator and rewrite its BASLINE.LINK (the forward-link word) to address the next node, so the singly-linked chain stays contiguous after an insert/delete; stops at the $0000 link (end of program). See msbasic_line.inc.
CHEAD:
        LD HL,(TXTTAB)
        EX DE,HL
; [RE] CHEAD scan loop: for each line walk to its terminating $00, fold embedded tokens, and write the next-line link pointer; stop at the program's double-zero end marker.
CHEAD_LOOP:
        LD H,D
        LD L,E
        LD A,(HL)                        ; read BASLINE.LINK low (OR its high byte next: a $0000 link = end of program)
        INC HL
        OR (HL)
        RET Z
        INC HL
        INC HL
CHEAD_LOOP_1:
        INC HL
        LD A,(HL)
CHEAD_LOOP_2:
        OR A
        JR Z,CHEAD_LOOP_3
        CP $20
        JR NC,CHEAD_LOOP_1
        CP $0B
        JR C,CHEAD_LOOP_1
        CALL CHRGOT
        CALL CHRGET
        JR CHEAD_LOOP_2
CHEAD_LOOP_3:
        INC HL
        EX DE,HL
        LD (HL),E                        ; write the rebuilt BASLINE.LINK (forward link to the next node)
        INC HL
        LD (HL),D
        JR CHEAD_LOOP
; [RE] Parse an optional 'start[-end]' line-number range (LIST/DELETE): get first line# ($34D5), accept ',' / '-' ($F3) separator, get second; syntax-error to $0D6F on malformed input.
SCAN_LINE_RANGE:
        LD DE,$0000
        PUSH DE
        JR Z,SCAN_LINE_RANGE_2
        POP DE
        CALL LINGET_DOT
        PUSH DE
        JR Z,SCAN_LINE_RANGE_3
        LD A,(HL)
        CP $2C
        JR Z,SCAN_LINE_RANGE_1
        CP TOK_MINUS
        JP NZ,RAISE_SYNTAX_ERROR
SCAN_LINE_RANGE_1:
        CALL CHRGET
SCAN_LINE_RANGE_2:
        LD DE,$FFFA
        CALL NZ,LINGET_DOT
        JP NZ,RAISE_SYNTAX_ERROR
SCAN_LINE_RANGE_3:
        EX DE,HL
        POP DE
; [RE] FNDLIN entry that takes the line number already in DE (via the stack) before searching the program.
FNDLIN_FROM_TEXT:
        EX (SP),HL
        PUSH HL
; FNDLIN: find a program line by number -- walk the singly-linked BASLINE list from TXTTAB ($0846) via each node's BASLINE.LINK, comparing BASLINE.LINENUM against the target; returns C set/clear and BC = the prior node (the insert point). A $0000 BASLINE.LINK ends the search (past end of program). See msbasic_line.inc.
FNDLIN:
        LD HL,(TXTTAB)
; FNDLIN inner loop: follow each node's BASLINE.LINK, load its BASLINE.LINENUM, FNDLIN-compare vs target; return when found or when the number passes the target.
FNDLIN_LOOP:
        LD B,H
        LD C,L
        LD A,(HL)                        ; read BASLINE.LINK low byte (BC = this node, the prospective insert point)
        INC HL
        OR (HL)                          ; OR BASLINE.LINK high byte: a $0000 link = end of program -> return
        DEC HL
        RET Z
        INC HL                           ; advance past BASLINE.LINK to BASLINE.LINENUM (+2)
        INC HL
        LD A,(HL)                        ; read BASLINE.LINENUM (low here, high at $0F96) to compare vs target
        INC HL
        LD H,(HL)
        LD L,A
        CALL CMP_HL_DE
        LD H,B
        LD L,C
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        CCF
        RET Z
        CCF
        RET NC
        JR FNDLIN_LOOP
; [RE] Evaluate a PRINT/INPUT-style item with optional '#'(file/channel $23) prefix: CHRGOT, FRMEVL the operand ($3A75), branch on numeric vs string ($3DC8), and stage it into the string/var area ($0B6F).
EVAL_CHANNEL_OR_ITEM:
        CALL CHRGOT
        CP $23
        RET Z
        PUSH HL
        CALL FRMEVL_NOPAREN
        CALL FRMEVL_TEST_TYPE
        JR Z,EVAL_CHANNEL_OR_ITEM_1
        CALL FILE_NUM_TO_FCB_NZ
        POP DE
        POP DE
        JP GET_PUT_RECORD_CORE
EVAL_CHANNEL_OR_ITEM_1:
        POP HL
        CALL PTRGET_1+1
        CALL FRMEVL_TEST_TYPE
        JP NZ,ERROR_FC
        PUSH HL
        LD A,(DE)
        OR A
        JR Z,EVAL_CHANNEL_OR_ITEM_2
        PUSH DE
        EX DE,HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        POP DE
        JR C,EVAL_CHANNEL_OR_ITEM_3+1
EVAL_CHANNEL_OR_ITEM_2:
        LD A,$01
        PUSH DE
        CALL GETSPA
        POP HL
        CALL STR_DESC_STORE
; [RE] Flag-skip: FE EB at $0FE6 is CP $EB whose $EB immediate is the EX DE,HL opcode. The new-descriptor fall-through ($0FE3 CALL STR_DESC_STORE, which RETs with HL = descriptor pointer) lands on $0FE6, where CP $EB harmlessly swallows the EX DE,HL and runs straight into LD (HL),$01. The reuse-in-place branch (JR C at $0FDA, carry from CMP_HL_DE vs VARTAB, with the descriptor pointer in DE after POP DE at $0FD9) enters at +1 ($0FE7) to execute EX DE,HL first. Both paths converge at $0FE8 LD (HL),$01. Cover is genuinely executed via fall-through; byte readings verified; MBASIC confirms identical structure at $1009.
EVAL_CHANNEL_OR_ITEM_3:
        CP $EB
        LD (HL),$01
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        CALL GET_PENDING_KEY
        CALL Z,INCHR
        LD (DE),A
        POP HL
        POP BC
        RET
    IFDEF GBASIC
        DEFS    8, $00                   ; fill

; ======================================================================
; SELF-RELOCATOR (runs at load address $1000)
; ======================================================================
; [RE] Entry stub (reached by JP from $0100). LDDR block-copies the interpreter body from its on-disk position UP to run address $3000-$8482, then JP $81D3 to cold-start it. HL=$6490 (src end), DE=$8482 (dst end), BC=$5483 (count).
RELOCATE_AND_RUN:
        LD HL,INTERP_LOAD_START+(INTERP_COPY_END-INTERP_RUN_START)-1
        LD DE,INTERP_COPY_END-1
        LD BC,INTERP_COPY_END-INTERP_RUN_START
        LDDR
        JP COLD_START

INTERP_LOAD_START:           ; physical $100E -- interpreter's first .COM byte (LDDR source)
    DISP $3000               ; runs at $3000 (the $1000 relocator LDDRs it up, then JP $81D3)
    ENDIF
INTERP_RUN_START:

; ======================================================================
; TOKENIZER (CRUNCH) -- run $3000+
; ======================================================================
; ----------------------------------------------------------------------
; CRUNCH -- tokenize one source line of BASIC text into the crunch buffer.
;   In:        HL -> source text (raw input line), NUL-terminated.
;   Out:       crunched/tokenized line built at KBUF; reserved words folded to single-byte tokens, string/REM/DATA text and digits passed through. Exits through CRUNCH_36 (end-of-line) which sets A=0, appends three trailing NUL bytes, and recomputes BC = bytes-emitted for the caller; DE then points at the last of those NUL slots.
;   Clobbers:  AF, BC, DE, HL; CRUNCH_LINENUM_MODE, CRUNCH_LITERAL_MODE; the crunch buffer at KBUF.
;   Algorithm: Reset both crunch-mode flags (line-number-introducer and literal-passthrough), set the output byte budget BC=$013B (315) and aim the output pointer DE at KBUF. Then fall into the per-character scan loop (CRUNCH_SCAN): classify each source char as quote / blank / end-of-line / (when not in literal mode) a candidate reserved word, and dispatch; reserved words are folded to tokens, '?' shorthand to PRINT.
; ----------------------------------------------------------------------
CRUNCH:
        ; Clear both crunch-mode flags: not after a line-number-introducing keyword, and not in literal (REM/DATA/string) passthrough.
        XOR A
        LD (CRUNCH_LINENUM_MODE),A
        LD (CRUNCH_LITERAL_MODE),A
        ; Remaining output budget = 315 bytes; CRUNCH_EMIT decrements it per emitted byte and raises ERR_LINE_BUFFER_OVERFLOW if it reaches 0.
        LD BC,$013B
        ; Aim the output pointer at the crunch/tokenize work buffer; the tokenized line is built forward from here.
        LD DE,KBUF
; ----------------------------------------------------------------------
; CRUNCH_SCAN (was CRUNCH_1) -- per-character scan/dispatch at the top of the crunch loop.
;   In:        HL -> current source char; DE -> next output slot; BC = remaining output budget; CRUNCH_LITERAL_MODE = passthrough flag.
;   Out:       branches to the handler for the current char class; on a reserved-word candidate, falls into CRUNCH_RESWORD_BEGIN with A = TOK_PRINT preloaded and Z set iff the char is '?'.
;   Clobbers:  AF.
;   Algorithm: Read (HL); dispatch: '"' -> string-literal copy (CRUNCH_34); ' ' -> verbatim blank (CRUNCH_30); NUL -> end-of-line finish (CRUNCH_36). Otherwise, if literal-passthrough mode is set, copy the char verbatim (CRUNCH_30); else compare the char to '?' then preload A=TOK_PRINT (the CP's Z flag survives the LD; Z => emit PRINT) before entering the reserved-word fold.
; ----------------------------------------------------------------------
CRUNCH_SCAN:
        ; Fetch the current source character (HL walks the raw input line).
        LD A,(HL)
        ; A double-quote opens a string literal: copy it through verbatim (CRUNCH_34).
        CP $22
        JP Z,CRUNCH_COPY_QUOTED
        ; A blank is copied through unchanged (CRUNCH_30).
        CP $20
        JP Z,CRUNCH_PASS_CHAR
        ; NUL marks end of the source line: finish the crunched line (CRUNCH_36).
        OR A
        JP Z,CRUNCH_FINALIZE_LINE
        ; In literal-passthrough mode (inside REM/DATA text) emit the raw char verbatim (CRUNCH_30) instead of attempting a reserved-word match.
        LD A,(CRUNCH_LITERAL_MODE)
        OR A
        LD A,(HL)
        JP NZ,CRUNCH_PASS_CHAR
        ; '?' is shorthand for PRINT: this CP sets Z iff the char is '?'; the following LD A,$91 preloads TOK_PRINT without disturbing Z, so CRUNCH_RESWORD_BEGIN can emit PRINT directly.
        CP $3F
        LD A,$91
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_BEGIN (was CRUNCH_2) -- start the reserved-word fold for the current candidate.
;   In:        HL -> first char of candidate word; DE/BC = output pointer/budget; A = TOK_PRINT and Z set iff the char was '?'.
;   Out:       If '?' : emits PRINT (jumps CRUNCH_14 with A=TOK_PRINT). If NOT a letter (operator/punctuation/digit) : CRUNCH_17. If a letter : either runs the 'GO TO'/'GO SUB' two-word recognizer or arms CRUNCH_RESWORD_TAIL (via LD BC,CRUNCH_RESWORD_TAIL / PUSH BC / RET) to look the word up in the keyword name table.
;   Clobbers:  AF, BC, DE, HL (saved copies of DE/BC pushed for the matcher to restore).
;   Algorithm: Save the output pointer/budget (PUSH DE / PUSH BC). If the char was '?', emit PRINT. Else upcase the current char and test it with IS_LETTER_A. If it is NOT a letter A-Z, hand it to CRUNCH_17 (operators/punctuation/digits). If it IS a letter, push HL and arm CRUNCH_RESWORD_TAIL as the continuation (LD BC,CRUNCH_RESWORD_TAIL / PUSH BC); then test for a leading 'G' to enter the 'GO TO'/'GO SUB' two-word recognizer; any non-'G' letter RETs into CRUNCH_RESWORD_TAIL for the ordinary keyword lookup.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_BEGIN:
        ; Save the output pointer and budget; the keyword matcher restores them on success (token replaces the spelled-out word) or failure (word copied verbatim).
        PUSH DE
        PUSH BC
        ; '?' shorthand: emit the PRINT token (A=TOK_PRINT) and skip the table lookup.
        JP Z,CRUNCH_CLASSIFY_TOKEN
        ; [RE] Loads DE=RESWORD_OPS (operator sub-table at $04D8) but, in every path through this cluster, DE is overwritten before any read: the letter path reloads DE from RESWORD_INDEX in CRUNCH_RESWORD_TAIL; the digit path does POP DE in CRUNCH_18; and the operator path (CRUNCH_17->CRUNCH_26) reloads DE=KWGRP_Z and scans the operators itself. So this load appears dead/vestigial here. UNKNOWN why it is loaded; do not assume it feeds the operator match.
        LD DE,RESWORD_OPS
        CALL CHRGET_UPCASE
        ; Carry set means NOT 'A'..'Z': hand operators/punctuation/digits to CRUNCH_17 instead of the keyword matcher (carry clear = letter, continue the fold).
        CALL IS_LETTER_A
        JP C,CRUNCH_17
        PUSH HL
        ; Arm CRUNCH_RESWORD_TAIL as the continuation: a following RET (taken on any non-'GO' word) drops into the first-letter keyword-table lookup.
        LD BC,CRUNCH_RESWORD_TAIL
        PUSH BC
        ; Leading 'G' opens the 'GO TO'/'GO SUB' two-word recognizer; RET NZ falls through (into CRUNCH_RESWORD_TAIL) for any other first letter.
        CP $47
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        ; Require 'O' after 'G' ("GO"); otherwise abandon the two-word path (RET NZ).
        CP $4F
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        ; Require a blank after "GO" (the two-word forms are spelled "GO TO"/"GO SUB"); otherwise fall back to the keyword lookup (RET NZ).
        CP $20
        RET NZ
        INC HL
; ----------------------------------------------------------------------
; CRUNCH_GOTO_SUB_SCAN (was CRUNCH_3) -- recognize 'GO TO' / 'GO SUB' after a confirmed leading "GO ".
;   In:        HL -> first char after "GO " (the mandatory single blank already consumed in CRUNCH_RESWORD_BEGIN).
;   Out:       On "GO SUB" -> CRUNCH_4 (GOSUB tail). On "GO TO" -> A=TOK_GOTO, then CRUNCH_5. On anything else: RET NZ, returning into CRUNCH_RESWORD_TAIL to try an ordinary keyword.
;   Clobbers:  AF, HL.
;   Algorithm: Skip any further run of blanks after the first "GO " blank. On 'S' branch to the GOSUB recognizer (CRUNCH_4). On 'T' continue the GOTO recognizer: read the next char (expect 'O'), preload TOK_GOTO (preserving the compare's Z), and join CRUNCH_5 which commits only if the 'O' matched. Any other char aborts the special case (RET NZ).
; ----------------------------------------------------------------------
CRUNCH_GOTO_SUB_SCAN:
        CALL CHRGET_UPCASE
        INC HL
        CP $20
        ; Allow extra blanks between "GO" and "TO"/"SUB" beyond the first mandatory one (keep skipping spaces).
        JR Z,CRUNCH_GOTO_SUB_SCAN
        ; 'S' -> the "GO SUB" recognizer (CRUNCH_4).
        CP $53
        JR Z,CRUNCH_GOSUB_TAIL
        ; 'T' -> the "GO TO" recognizer; any other character aborts the two-word special case (RET NZ).
        CP $54
        RET NZ
        CALL CHRGET_UPCASE
        CP $4F
        ; Preload the GOTO token (does not disturb the preceding CP $4F flags); CRUNCH_5 commits it only if that 'O' matched (Z set).
        LD A,TOK_GOTO
        JR CRUNCH_GOTO_SUB_COMMIT
; ----------------------------------------------------------------------
; CRUNCH_GOSUB_TAIL (was CRUNCH_4) -- match the 'UB' tail of 'GO SUB' and stage the GOSUB token.
;   In:        HL -> char after the 'S' of "GO S...".
;   Out:       If "...UB" matches: A=TOK_GOSUB and falls into CRUNCH_5 (commit). Otherwise RET NZ (abandon the special case, fall back to ordinary keyword lookup).
;   Clobbers:  AF, HL.
;   Algorithm: Require 'U' (RET NZ on mismatch) then 'B' after "GO S"; load TOK_GOSUB ($8D) without disturbing the 'B' compare's flags and fall through to CRUNCH_5, which commits only when that final 'B' compared equal.
; ----------------------------------------------------------------------
CRUNCH_GOSUB_TAIL:
        CALL CHRGET_UPCASE
        ; Require 'U' after "GO S"; otherwise abandon (RET NZ) and try an ordinary keyword.
        CP $55
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        ; Require the final 'B' of "SUB"; CRUNCH_5 commits GOSUB only if this compares equal.
        CP $42
        ; Stage the GOSUB token (TOK_GOSUB=$8D) for CRUNCH_5; the LD leaves the preceding 'B' compare's Z flag intact.
        LD A,$8D
; ----------------------------------------------------------------------
; CRUNCH_GOTO_SUB_COMMIT (was CRUNCH_5) -- commit the recognized GOTO/GOSUB token, discarding the keyword-lookup continuation.
;   In:        A = TOK_GOTO or TOK_GOSUB; Z set iff the final keyword char matched; the stack holds (top-down) the armed CRUNCH_RESWORD_TAIL return address, then the saved HL (PUSH HL in CRUNCH_RESWORD_BEGIN), then the saved budget BC and output pointer DE.
;   Out:       On match: pops the two staged stack words (the CRUNCH_RESWORD_TAIL return address and the saved HL) and jumps to CRUNCH_14 to emit the token (leaving the saved BC/DE on the stack for CRUNCH_16 to restore). On mismatch: RET NZ, returning into CRUNCH_RESWORD_TAIL to fall back to the ordinary keyword table lookup.
;   Clobbers:  AF, BC (two stack pops).
;   Algorithm: If the trailing char did not match (NZ), bail out via RET into the keyword-lookup continuation. Otherwise drop the CRUNCH_RESWORD_TAIL return word and the saved-HL word from the stack (the two-word form is fully matched, no table lookup needed) and emit the token through CRUNCH_14.
; ----------------------------------------------------------------------
CRUNCH_GOTO_SUB_COMMIT:
        ; Trailing char mismatched: return into CRUNCH_RESWORD_TAIL to retry as an ordinary keyword.
        RET NZ
        ; Two-word form fully matched: discard the armed CRUNCH_RESWORD_TAIL return address and the saved HL (no table lookup needed); the second POP BC drops the second of these.
        POP BC
        POP BC
        ; Emit the recognized GOTO/GOSUB token (A); CRUNCH_14 matches it in its keyword list and marks it a line-number-introducing keyword.
        JP CRUNCH_CLASSIFY_TOKEN
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_TAIL -- look the candidate word up in the keyword name table, indexed by its first letter.
;   In:        Reached by RET through the armed LD BC,CRUNCH_RESWORD_TAIL / PUSH BC continuation. Stack top holds the saved HL (HL -> first letter of the candidate, pushed in CRUNCH_RESWORD_BEGIN); the output pointer/budget were saved earlier (PUSH DE / PUSH BC).
;   Out:       DE -> the keyword name-table group for the candidate's first letter; HL -> the second char of the candidate (first letter consumed). Falls into the per-keyword comparison loop (CRUNCH_7/CRUNCH_8).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Recover HL (saved candidate pointer), read+upcase its first letter (CHRGET_UPCASE does not advance HL), re-save HL, then index RESWORD_INDEX by (letter-'A')*2 to fetch the 16-bit group pointer for that letter into DE. Restore HL and INC past the first letter (which the group implies, so name entries store only the tail), then drop into the per-keyword comparison loop.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_TAIL:
        ; Recover the candidate pointer saved by CRUNCH_RESWORD_BEGIN (HL -> first letter of the word).
        POP HL
        CALL CHRGET_UPCASE
        PUSH HL
        ; Base of the per-letter group-pointer table (A->Z); each entry is a 16-bit pointer to that letter's keyword group.
        LD HL,RESWORD_INDEX
        ; Convert the first letter to a 0-based index ('A'->0 ... 'Z'->25).
        SUB $41
        ; Double the index because each group pointer is two bytes.
        ADD A,A
        LD C,A
        LD B,$00
        ADD HL,BC
        ; Fetch the 16-bit pointer to this letter's keyword group into DE (E here, D from the next byte) -- the group of tail+token entries to match against.
        LD E,(HL)
        INC HL
        LD D,(HL)
        POP HL
        ; Skip the implied first letter: name-table entries store only the keyword tail, so matching starts at the candidate's second char.
        INC HL
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_TRY_ENTRY -- per-candidate setup for the reserved-word name match loop
;   In:        HL = source text pointer at the 2nd character of the candidate word (the first
;              letter already selected the keyword group via RESWORD_INDEX). DE = pointer into the
;              current keyword group (KWGRP_x), positioned at the first stored character of the next
;              candidate name. Stack carries the CRUNCH_2-saved DE (output cursor) and BC (count).
;   Out:       Falls through to CRUNCH_8 with HL (source pointer) saved on the stack.
;   Clobbers:  none here; pushes HL.
;   Algorithm: Re-entered once per candidate name in the letter's group (looped back from
;              CRUNCH_12). Pushes the source pointer so that on a mismatch (CRUNCH_11) it can be
;              restored to the word start before trying the next candidate.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_TRY_ENTRY:
        ; remember the word start so a mismatch can rewind to try the next keyword in this letter group
        PUSH HL
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_CMP_LOOP -- compare the candidate keyword name against the source word
;   In:        HL -> current source char (uppercased on read). DE -> current char of the candidate
;              name in the keyword group. Name chars are stored ASCII with the FINAL char's high
;              bit set as terminator; the byte AFTER the terminated name is the token value; a $00
;              byte ends the letter group.
;   Out:       Full name matched: falls through with C = last matched source char and DE -> the
;              token byte, into the follow-char acceptance checks below. Char mismatch: JR CRUNCH_11
;              (try next candidate). Group exhausted ($00 end marker): JP CRUNCH_EMIT_2 (not a
;              keyword; emit verbatim).
;   Clobbers:  A, C, HL, DE.
;   Algorithm: Character loop. Reads one uppercased source char (saved in C), reads the table name
;              char and masks the terminator bit (AND $7F): a 0 result is the group-end $00 marker
;              -> word is not in this group. Otherwise compares the masked table char to C; on
;              inequality goes to the next candidate. On equality it reloads the UNMASKED table byte
;              and advances DE: high bit clear -> more name chars remain (loop); high bit set -> that
;              was the terminator (last char) and DE now points at the token byte -> fall through.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_CMP_LOOP:
        ; fetch and fold the source char to uppercase for case-insensitive keyword matching
        CALL CHRGET_UPCASE
        LD C,A
        LD A,(DE)
        ; drop the name-terminator high bit; a zero result is the group-end ($00) marker = word not found in this group
        AND $7F
        ; ran off the end of the letter group with no match: treat the word as an ordinary identifier
        JP Z,CRUNCH_COPY_IDENT
        INC HL
        CP C
        ; this char differs: abandon this candidate and skip to the next keyword in the group
        JR NZ,CRUNCH_RESWORD_MISMATCH
        LD A,(DE)
        INC DE
        OR A
        ; unmasked table byte still positive: not the terminator yet, more name characters follow, keep comparing
        JP P,CRUNCH_RESWORD_CMP_LOOP
        LD A,C
        CP $28
        JR Z,CRUNCH_RESWORD_EMIT_TOKEN
        LD A,(DE)
        CP $E2
        JR Z,CRUNCH_RESWORD_EMIT_TOKEN
        CP $E1
        JR Z,CRUNCH_RESWORD_EMIT_TOKEN
        CALL CHRGET_UPCASE
        CP $2E
        JR Z,CRUNCH_RESWORD_REJECT_PREFIX
        CALL IS_ALNUM_CHAR
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_REJECT_PREFIX -- reject a name match that is only a prefix of a longer identifier
;   In:        Reached after a full keyword name matched and the acceptance exceptions failed: the
;              keyword's own last char C was not '(' and its token byte was not $E1 (USR) / $E2 (FN).
;              Carry from IS_ALNUM_CHAR reports whether the NEXT source char continues an identifier;
;              the '.' branch ($2E) jumps in directly with NC (CP-equal clears carry).
;   Out:       Next source char is alphanumeric or '.' (NC): JP CRUNCH_EMIT_2 with A=0 -> emit the
;              word as an identifier, not the keyword. Next char ends the word (C set): fall into
;              CRUNCH_10 to accept the token.
;   Clobbers:  A.
;   Algorithm: Pre-loads A=0 (so CRUNCH_EMIT_2's DEC A stores the $FF 'no line-number' sentinel) and
;              takes the verbatim-emit exit when the matched keyword is actually the start of a
;              longer variable name (e.g. 'ANDY' must not tokenize as AND followed by 'Y').
; ----------------------------------------------------------------------
CRUNCH_RESWORD_REJECT_PREFIX:
        ; seed A=0 so the verbatim-emit path (CRUNCH_EMIT_2 DEC A) records the $FF no-line-number sentinel
        LD A,$00
        ; the word continues with another alnum/'.' char, so it is an identifier, not this keyword: emit it as text
        JP NC,CRUNCH_COPY_IDENT
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_EMIT_TOKEN -- a keyword was confirmed; emit its token byte(s)
;   In:        DE -> the matched name's token byte. HL -> source char just past the keyword (the
;              advanced compare-loop pointer). Stack top = the CRUNCH_7-saved word-start HL
;              (discarded here).
;   Out:       Ordinary token (byte >= $80, sign bit set) case: JP M,CRUNCH_13 (back up HL then
;              classify/emit via CRUNCH_13/14). Extended token (byte < $80) case: pops the
;              CRUNCH_2-saved cursor/count, emits $FF then (token|$80), clears CRUNCH_LINENUM_MODE,
;              and loops to CRUNCH_1.
;   Clobbers:  A, BC, DE, HL, the crunch output cursor.
;   Algorithm: Discards the saved word-start pointer (keeps the advanced HL). Reads the token byte:
;              if its high bit is set it is a normal one-byte token -> CRUNCH_13/CRUNCH_14. If
;              positive (< $80) it is an extended/secondary token: pops the saved cursor/count, emits
;              the $FF escape prefix, then emits the token with bit7 forced on, and resumes scanning.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_EMIT_TOKEN:
        ; drop the saved word-start pointer: the match is good, keep the advanced HL
        POP AF
        LD A,(DE)
        OR A
        ; ordinary one-byte token (bit7 set): hand off to the token classifier
        JP M,CRUNCH_RESWORD_FIXUP_HL
        POP BC
        POP DE
        ; force bit7 on the stored secondary-token value
        OR $80
        PUSH AF
        ; extended token: emit the $FF escape prefix before the secondary token byte
        LD A,$FF
        CALL CRUNCH_EMIT
        XOR A
        LD (CRUNCH_LINENUM_MODE),A
        POP AF
        CALL CRUNCH_EMIT
        JP CRUNCH_SCAN
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_MISMATCH -- restore the source pointer after a character mismatch
;   In:        Stack top = the CRUNCH_7-saved word-start HL. DE -> somewhere mid-name in the failed
;              candidate.
;   Out:       HL rewound to the word start; falls into CRUNCH_12 to skip past the rest of the
;              failed candidate's bytes.
;   Clobbers:  HL.
;   Algorithm: Pops the saved source pointer so the next candidate is compared from the same word
;              start (the 2nd char).
; ----------------------------------------------------------------------
CRUNCH_RESWORD_MISMATCH:
        ; rewind to the word start so the next keyword is matched from the same first letter
        POP HL
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_NEXT_ENTRY -- advance DE to the next keyword entry in the group
;   In:        DE -> mid-name in the failed candidate.
;   Out:       DE -> first character of the next candidate name; jumps to CRUNCH_7 to retry.
;   Clobbers:  A, DE.
;   Algorithm: Skips remaining name bytes (high bit clear) until it consumes the high-bit terminator
;              char, then skips the one token byte, leaving DE on the next entry. If that entry is
;              actually the trailing $00 group-end marker, CRUNCH_8's AND-$7F test catches it next
;              pass, not here.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_NEXT_ENTRY:
        LD A,(DE)
        INC DE
        OR A
        ; skip name characters until the high-bit-set terminator is passed
        JP P,CRUNCH_RESWORD_NEXT_ENTRY
        ; step over the entry's token byte; DE now points at the next keyword
        INC DE
        JR CRUNCH_RESWORD_TRY_ENTRY
; ----------------------------------------------------------------------
; CRUNCH_RESWORD_FIXUP_HL -- back up HL by one before token classification
;   In:        A = matched token byte (>= $80). HL = source char just past the keyword (left by the
;              compare loop's per-char INC HL).
;   Out:       HL decremented to point AT the keyword's last character; falls into CRUNCH_14.
;   Clobbers:  HL.
;   Algorithm: Backs HL up one so it sits on the keyword's final char; the generic emit path
;              (CRUNCH_30) does a matching INC HL to step past it before writing the token. The
;              non-table entrants into CRUNCH_14 ('?'->PRINT and GO TO/GO SUB) bypass this DEC HL
;              because their HL is already correctly positioned.
; ----------------------------------------------------------------------
CRUNCH_RESWORD_FIXUP_HL:
        ; rewind onto the keyword's last char (the name-compare loop overshot by one; CRUNCH_30 will re-advance)
        DEC HL
; ----------------------------------------------------------------------
; CRUNCH_CLASSIFY_TOKEN -- classify the just-matched token and set the line-number-mode flag
;   In:        A = token byte about to be emitted (>= $80). Entered from CRUNCH_13 for table matches,
;              and directly from the '?'->PRINT shortcut (A=$91) and the GO TO/GO SUB folder
;              (A=GOTO/GOSUB). Stack below the entry holds the CRUNCH_2-saved BC (count) and DE
;              (output cursor).
;   Out:       Via the cover idiom at CRUNCH_15/CRUNCH_16: A=1 (token introduces a line number) or
;              A=0 (not) is written to CRUNCH_LINENUM_MODE, then CRUNCH_16 handles the ELSE/apostrophe
;              special cases and finishes emitting.
;   Clobbers:  A, BC; pushes the token (PUSH AF) for CRUNCH_16.
;   Algorithm: Saves the token, then pushes CRUNCH_15+1 ($311A) as a fake return so that each
;              'CP nn / RET Z' in the ladder that MATCHES returns INTO the operand of the CRUNCH_15
;              JP-NZ cover, executing its LD A,$01 (flag=1) and skipping the C2 jump opcode. The 14
;              listed values decode to RESTORE($8C), AUTO($A7), RENUM($A8), DELETE($A6), EDIT($A3),
;              RESUME($A5), ERL($E5), ELSE, RUN($8A), LIST($93), LLIST($9C), GOTO, THEN, GOSUB($8D)
;              -- the keywords followed by a line number. No match runs POP AF (discarding the cover
;              address) / XOR A -> flag=0.
; ----------------------------------------------------------------------
CRUNCH_CLASSIFY_TOKEN:
        ; stash the token byte; CRUNCH_16 re-reads it for the ELSE / apostrophe-REM cases and the final emit
        PUSH AF
        ; fake return ($311A): a matching RET Z below lands on the LD A,$01 operand of CRUNCH_15's JP-NZ (flag=1), past the C2 jump opcode
        LD BC,CRUNCH_LINENUM_FLAG_COVER+1
        PUSH BC
        ; test the token against the line-number-introducer set (RESTORE/AUTO/RENUM/DELETE/EDIT/RESUME/ERL/ELSE/RUN/LIST/LLIST/GOTO/THEN/GOSUB)
        CP $8C
        RET Z
        CP $A7
        RET Z
        CP $A8
        RET Z
        CP $A6
        RET Z
        CP $A3
        RET Z
        CP $A5
        RET Z
        CP $E5
        RET Z
        CP TOK_ELSE
        RET Z
        CP $8A
        RET Z
        CP $93
        RET Z
        CP $9C
        RET Z
        CP TOK_GOTO
        RET Z
        CP TOK_THEN
        RET Z
        CP $8D
        RET Z
        POP AF
        ; no line-number keyword matched: clear A so CRUNCH_16 records flag=0
        XOR A
; ----------------------------------------------------------------------
; CRUNCH_LINENUM_FLAG_COVER -- one-byte cover whose JP-NZ operand doubles as 'flag := 1'
;   In:        Two entry forms. A matching RET Z from CRUNCH_14 returns to CRUNCH_15+1 ($311A),
;              executing the operand bytes 3E 01 ('LD A,$01'). The no-match fall-through arrives at
;              CRUNCH_15 ($3119) itself with A=0 and Z set.
;   Out:       Reaches CRUNCH_16 with A = 1 (line-number keyword) or A = 0 (other). The JP NZ is
;              never taken (Z is set on the fall-through entrant).
;   Clobbers:  A (on the matched path only).
;   Algorithm: Data-as-cover idiom. The C2 opcode of 'JP NZ,$013E' is the single byte the matched
;              entrant skips over by returning to +1, so the 3E 01 tail sets the flag; the unmatched
;              entrant executes the JP NZ but never branches. $013E is not a real target (it only
;              coincides with an entry in the statement dispatch table).
; ----------------------------------------------------------------------
CRUNCH_LINENUM_FLAG_COVER:
        JP NZ,$013E
; ----------------------------------------------------------------------
; CRUNCH_STORE_FLAG_AND_EMIT -- store the line-number flag, handle ELSE / apostrophe-REM, emit the token
;   In:        A = line-number flag (0 or 1) from the cover. Stack: token byte (PUSH AF in
;              CRUNCH_14), then the CRUNCH_2-saved BC (count) and DE (output cursor).
;   Out:       CRUNCH_LINENUM_MODE updated. ELSE ($9E) gets a leading ':' emitted. The apostrophe
;              remark token ($EA, TOK_REM_QUOTE) is rewritten to ':' + the REM token ($8F) and
;              continues into the verbatim remark-text copier (CRUNCH_35). All other tokens jump to
;              CRUNCH_28 to emit normally.
;   Clobbers:  A, BC, DE; manipulates the crunch output cursor.
;   Algorithm: Writes the flag, restores the token and output state (count/cursor), then special-
;              cases two tokens: ELSE (a statement separator, so prefix a colon) and the apostrophe
;              form of REM ($EA) which is emitted as ':' + the $8F REM token followed by the rest of
;              the line copied literally. Everything else is routed to the generic single-token
;              emitter at CRUNCH_28.
; ----------------------------------------------------------------------
CRUNCH_STORE_FLAG_AND_EMIT:
        ; record whether the next digits form a line number (set for GOTO/THEN/ELSE/RUN/LIST/RESTORE/... )
        LD (CRUNCH_LINENUM_MODE),A
        POP AF
        POP BC
        POP DE
        CP TOK_ELSE
        PUSH AF
        ; ELSE acts as a statement separator: emit an implicit ':' before it
        CALL Z,CRUNCH_EMIT_COLON
        POP AF
        CP $EA
        ; not the apostrophe-REM token: emit this token through the generic path
        JP NZ,CRUNCH_AMP_HEX_OCT
        PUSH AF
        CALL CRUNCH_EMIT_COLON
        ; apostrophe (') remark: after the ':' emit the canonical REM token ($8F), then copy the remark text verbatim via CRUNCH_35
        LD A,TOK_REM
        CALL CRUNCH_EMIT
        POP AF
        PUSH AF
        JP CRUNCH_EMIT_AND_LOOP
; ----------------------------------------------------------------------
; CRUNCH_17 -- decide whether the current source character begins a number/line-number that CRUNCH must convert to a packed numeric token.
;   In:        HL -> current source character in the input line; reached from CRUNCH_2 via JP C,CRUNCH_17 (IS_LETTER_A returned carry = NOT a letter). The DE(crunch-dest)/BC(remaining) pair is on the stack (DE PUSHed first, BC on top) from CRUNCH_2.
;   Out:       Falls into CRUNCH_18 if the char is a numeric-constant lead ('.', or a digit '0'-'9'); jumps to CRUNCH_26 (operator/punctuation reserved-word rescan) otherwise.
;   Clobbers:  A.
;   Algorithm: Re-load (HL) into A and classify: a leading '.' is accepted as a possible decimal point (JR Z,CRUNCH_18); bytes >= ':' ($3A) and bytes < '0' ($30) are not digits, so route to CRUNCH_26 which retries the char against the operator name-table (catches +-*/^=<>'\ that IS_LETTER_A rejected); '0'-'9' fall through to CRUNCH_18.
; ----------------------------------------------------------------------
CRUNCH_17:
        LD A,(HL)
        ; a leading '.' may start a fractional constant like .5 -> treat as numeric
        CP $2E
        JR Z,CRUNCH_18
        CP $3A
        ; char is >= ':' (past the digits): not a number, retry it as an operator char
        JP NC,CRUNCH_26
        CP $30
        ; char is below '0': not a digit either, retry it as an operator char
        JP C,CRUNCH_26
; ----------------------------------------------------------------------
; CRUNCH_18 -- tokenize a numeric constant or a line-number reference at (HL).
;   In:        HL -> first character of the number; CRUNCH_LINENUM_MODE ($0B16) holds the line-number-introducer flag (set to $01 when the preceding crunched token was GOTO/GOSUB/THEN/RUN/LIST/RESTORE/etc., $00 otherwise -- the only values written by CRUNCH_16/CRUNCH_30 in normal operation); DE(dest)/BC(count) on the stack from CRUNCH_2.
;   Out:       Restores BC(count)/DE(dest) from the stack, then either: emits a line-number-reference token ($0E + 2-byte line number) when the flag is positive nonzero, or hands an ordinary numeric literal to CRUNCH_22 when the flag is zero. A stray '.' in line-number mode escapes to CRUNCH_30 (copy the char verbatim).
;   Clobbers:  A, DE, BC, HL.
;   Algorithm: OR A on CRUNCH_LINENUM_MODE sets flags that survive the LD A,(HL)/POP BC/POP DE that follow. If zero -> ordinary numeric literal (JR Z,CRUNCH_22, FIN parse + packed token). If positive nonzero (line-number mode) and the char is not '.' -> emit token $0E, CALL LINGET to read the decimal line number into DE, trim trailing blanks, and fall into CRUNCH_19/20/21 to emit the 2-byte line number. [RE] A JP M,CRUNCH_30 also guards the sign-bit-set case (flag value $80-$FF), but the documented flag writers only ever store $00/$01, so this passthrough branch is not exercised by those paths; UNKNOWN which writer (if any) leaves the flag negative.
; ----------------------------------------------------------------------
CRUNCH_18:
        ; is the preceding keyword one that introduces a target line number?
        LD A,(CRUNCH_LINENUM_MODE)
        OR A
        LD A,(HL)
        POP BC
        POP DE
        ; [RE] flag has its sign bit set: copy this char verbatim (documented writers store only $00/$01, so this branch is normally unreached)
        JP M,CRUNCH_PASS_CHAR
        ; ordinary numeric literal (not a line number): pack it via FIN in CRUNCH_22
        JR Z,CRUNCH_22
        CP $2E
        JP Z,CRUNCH_PASS_CHAR
        ; emit the line-number-reference token ($0E) ahead of the 2-byte line number
        LD A,$0E
        CALL CRUNCH_EMIT
        PUSH DE
        ; parse the decimal line number into DE
        CALL LINGET
        CALL CRUNCH_SKIP_BLANKS_BACK
; ----------------------------------------------------------------------
; CRUNCH_19 -- emit a 2-byte little-endian constant (line number or &-radix value) into the crunch buffer.
;   In:        DE = the 16-bit value to emit; HL -> source text continuation (just past the number); top of stack = the crunch write-cursor saved by the caller (CRUNCH_18's PUSH DE at $3161, or CRUNCH_29's PUSH DE at $31E8).
;   Out:       Falls into CRUNCH_20/CRUNCH_21 which emit the value's low then high byte and resume the main scan at CRUNCH_1.
;   Clobbers:  HL, DE, A.
;   Algorithm: EX (SP),HL swaps the live source pointer onto the stack and brings the saved crunch write-cursor into HL; EX DE,HL then puts the 16-bit value into HL and the write-cursor into DE. Net result entering CRUNCH_20: HL = value, DE = write-cursor, stack top = post-number source pointer (which CRUNCH_21 POPs back).
; ----------------------------------------------------------------------
CRUNCH_19:
        ; swap source pointer onto the stack; bring the saved write-cursor into HL
        EX (SP),HL
        ; move the 16-bit value into HL (and the write-cursor into DE) so CRUNCH_20/21 can emit its two bytes
        EX DE,HL
; ----------------------------------------------------------------------
; CRUNCH_20 -- emit the low byte of a 2-byte numeric token payload, then set up the high byte.
;   In:        HL = the 16-bit value to emit (L = low byte, H = high byte); DE -> crunch-buffer write cursor; BC = remaining buffer count.
;   Out:       Low byte (L) written via CRUNCH_EMIT; A loaded with H ready for CRUNCH_21 to write the high byte.
;   Clobbers:  A, DE, BC.
;   Algorithm: Write L to the output, then load A=H and fall into CRUNCH_21 to write the high byte and resume scanning. Also the join point for the integer '10 <= value <= 255' path from CRUNCH_22, where HL was pre-arranged so L = $0F (the 1-byte-integer token) and H = the value byte: here LD A,L emits the $0F token and CRUNCH_21 emits the value.
; ----------------------------------------------------------------------
CRUNCH_20:
        ; emit the low byte first (little-endian); on the CRUNCH_22 path this is the $0F 1-byte-int token
        LD A,L
        CALL CRUNCH_EMIT
        LD A,H
; ----------------------------------------------------------------------
; CRUNCH_21 -- emit the high (second) byte of a 2-byte numeric token payload and return to the main scan.
;   In:        A = the byte to emit; the post-number source pointer is on top of stack; DE/BC = crunch cursor/count.
;   Out:       Byte emitted; HL reloaded with the saved source pointer; control rejoins the tokenizer loop at CRUNCH_1.
;   Clobbers:  HL, DE, BC, A.
;   Algorithm: POP the saved source pointer back into HL, emit A (the high byte / second payload byte), then JP CRUNCH_1 to continue tokenizing. Also reached from CRUNCH_22's small-integer path with A = value+$11 (the single-byte embedded constants $11-$1A for digits 0-9).
; ----------------------------------------------------------------------
CRUNCH_21:
        ; restore the source pointer to just past the number
        POP HL
        CALL CRUNCH_EMIT
        ; number fully emitted: resume scanning the rest of the line
        JP CRUNCH_SCAN
; ----------------------------------------------------------------------
; CRUNCH_22 -- parse a numeric literal with FIN and emit it as the smallest MS-BASIC packed numeric token.
;   In:        HL -> first char of the numeric literal; DE = crunch write-cursor, BC = remaining count (live registers restored at CRUNCH_18; CRUNCH_22 re-PUSHes them around the FIN call).
;   Out:       The constant is parsed into the FAC (VALTYP = L_0B14 ($0B14); 16-bit int in FAC ($0CB1)); the correctly-sized token is emitted: $11-$1A for integers 0-9, $0F+byte for 10-255, $1C+word for 16-bit ints, or via CRUNCH_23 for single/double; control returns to CRUNCH_1.
;   Clobbers:  A, HL, DE, BC, FAC cells.
;   Algorithm: PUSH dest/count, CALL FIN_1+1 (the FIN numeric scanner entered at its +1 byte so the XOR-A flag-skip pre-seeds the FAC integer), trim trailing blanks, restore dest/count, PUSH the post-number source pointer. If VALTYP is integer ($02): read the 16-bit value from $0CB1; when the high byte is zero, values 0-9 emit as the compact $11-$1A tokens (ADD A,$11 -> CRUNCH_21) and 10-255 as the $0F 1-byte-int token + the byte (pre-staged HL then CRUNCH_20); when the high byte is nonzero the full 16-bit value goes to CRUNCH_23 (with A reloaded to $02). Non-integer (single/double) literals always go to CRUNCH_23.
; ----------------------------------------------------------------------
CRUNCH_22:
        PUSH DE
        PUSH BC
        LD A,(HL)
        ; parse the literal into the FAC (FIN entered +1 so XOR-A pre-seeds the integer FAC), setting VALTYP and the value cells
        CALL FIN_1+1
        CALL CRUNCH_SKIP_BLANKS_BACK
        POP BC
        POP DE
        PUSH HL
        LD A,(VALTYP)
        ; integer literal? non-integers (single/double) emit via CRUNCH_23
        CP VT_INT
        JR NZ,CRUNCH_23
        LD HL,(FAC)
        LD A,H
        ; test the value's high byte: nonzero -> needs the full 2-byte integer token ($1C)
        OR A
        LD A,$02
        JR NZ,CRUNCH_23
        LD A,L
        ; value 0-255: stage HL as (H=value, L=$0F 1-byte-int token) for the emit helpers
        LD H,L
        LD L,$0F
        ; values 0-9 get the ultra-compact $11-$1A tokens; 10-255 use $0F + one byte
        CP $0A
        JR NC,CRUNCH_20
        ; map digit value 0..9 to its embedded constant token $11..$1A
        ADD A,$11
        JR CRUNCH_21
; ----------------------------------------------------------------------
; CRUNCH_23 -- emit a wide numeric constant token ($1C 2-byte int / $1D single / $1F double) followed by its raw FAC bytes.
;   In:        A = the width code to encode: $02 (2-byte int), $04 (single) or $08 (double); the FAC holds the value (int/single at $0CB1, double field at $0CAD); the post-number source pointer is on the stack.
;   Out:       The type token and exactly VALTYP value-bytes are copied into the crunch buffer; control returns to CRUNCH_1 via CRUNCH_24/CRUNCH_25.
;   Clobbers:  A, HL, DE, BC.
;   Algorithm: PUSH A (the width, so the FRMEVL_TEST_TYPE call below can clobber it). RRCA halves the width ($02->$01, $04->$02, $08->$04) and ADD $1B yields the token $1C (2-byte int), $1D (single) or $1F (double); emit it. Select the FAC source: set HL=$0CB1, then FRMEVL_TEST_TYPE returns carry SET for VALTYP < $08 (int/single) and CLEAR for VALTYP >= $08 (double); on carry (int/single) JR C,CRUNCH_24 keeps HL=$0CB1, otherwise LD HL,$0CAD selects the wider double field. CRUNCH_24 then POPs the width back into A for the copy loop.
; ----------------------------------------------------------------------
CRUNCH_23:
        PUSH AF
        ; halve the width code so $02/$04/$08 map onto the constant-token range
        RRCA
        ; form the wide-constant token: $1C=2-byte int, $1D=single, $1F=double
        ADD A,$1B
        CALL CRUNCH_EMIT
        LD HL,FAC
        ; carry SET if VALTYP<8 (int/single -> use $0CB1), CLEAR if VALTYP>=8 (double -> use $0CAD)
        CALL FRMEVL_TEST_TYPE
        JR C,CRUNCH_24
        ; double precision: copy from the wider FAC field at $0CAD instead of $0CB1
        LD HL,L_0CAD
; ----------------------------------------------------------------------
; CRUNCH_24 -- recover the value-byte count after the FAC source pointer has been selected.
;   In:        The width code (VALTYP) PUSHed at CRUNCH_23 is on the stack; HL -> the chosen FAC source field.
;   Out:       A = the byte count (VALTYP); falls into CRUNCH_25 to perform the copy loop.
;   Clobbers:  A.
;   Algorithm: POP the width that CRUNCH_23 saved (so the FRMEVL_TEST_TYPE call could clobber A) back into A, then drop into the byte-copy loop CRUNCH_25. This is the merge point of the int/single (carry, JR C) and double (no-carry, fell through LD HL,$0CAD) source-select branches.
; ----------------------------------------------------------------------
CRUNCH_24:
        POP AF
; ----------------------------------------------------------------------
; CRUNCH_25 -- copy A raw value-bytes from the FAC into the crunch buffer (the wide-constant payload loop).
;   In:        A = number of bytes to copy (VALTYP width: 2 int / 4 single / 8 double); HL -> FAC source field; DE/BC = crunch cursor/count; the post-number source pointer is on the stack.
;   Out:       A bytes emitted via CRUNCH_EMIT; HL (source text) restored; control returns to CRUNCH_1.
;   Clobbers:  A, HL, DE, BC.
;   Algorithm: Loop: PUSH the remaining count, load (HL) and emit it via CRUNCH_EMIT, POP the count, INC HL, DEC A, repeat while nonzero. When done, POP the saved source-text pointer into HL and JP CRUNCH_1 to continue tokenizing.
; ----------------------------------------------------------------------
CRUNCH_25:
        PUSH AF
        ; copy the next raw value byte from the FAC into the line
        LD A,(HL)
        CALL CRUNCH_EMIT
        POP AF
        INC HL
        DEC A
        ; loop until all VALTYP bytes of the constant are emitted
        JR NZ,CRUNCH_25
        ; restore the source-text pointer past the number
        POP HL
        JP CRUNCH_SCAN
; ----------------------------------------------------------------------
; CRUNCH_26 -- match the current character against the operator/punctuation reserved-word table (the non-letter keyword scan).
;   In:        HL -> current source character; reached from CRUNCH_17 for characters that are neither letters nor digits.
;   Out:       On a match, emits the operator token (CRUNCH_EMIT_6 with A = the token); on no match (table terminator), passes the character through as-is (CRUNCH_EMIT_5).
;   Clobbers:  A, DE.
;   Algorithm: Load DE with KWGRP_Z ($04D7), the $00 Z-group terminator that sits immediately before the operator (char,token) table RESWORD_OPS ($04D8); CRUNCH_27's leading INC DE advances DE onto the first operator entry. This gives non-letter chars (+ - * / ^ = < > backslash quote-rem) a chance to tokenize as operators before being copied through verbatim.
; ----------------------------------------------------------------------
CRUNCH_26:
        ; point DE at the $00 group-terminator that precedes the operator table RESWORD_OPS; CRUNCH_27's INC DE steps onto the first operator entry
        LD DE,KWGRP_Z
; ----------------------------------------------------------------------
; CRUNCH_27 -- inner scan of the operator name-table, comparing each entry's char to (HL).
;   In:        DE -> the byte just before a (char+$80, token) operator entry; HL -> the source character to match.
;   Out:       On the table terminator ($00) -> CRUNCH_EMIT_5 (pass the char through); on a char match -> CRUNCH_EMIT_6 with A = the entry's token byte.
;   Clobbers:  A, DE.
;   Algorithm: INC DE to the entry's char byte; read it and AND $7F to drop the always-set high bit (the marker that flags a name char) -- if the result is $00 the byte was the table terminator, so no operator matched and the char is copied verbatim. Otherwise INC DE to the token byte, CP (HL) the masked char against the source char, then LD A,(token) (does not disturb the CP flags) so a hit leaves the token in A; loop on mismatch, fall through to CRUNCH_EMIT_6 on a match.
;   Note:      This walks the operator sub-table RESWORD_OPS (anchored just past KWGRP_Z), the same (char+$80, token) layout used by the per-letter keyword groups.
; ----------------------------------------------------------------------
CRUNCH_27:
        INC DE
        ; preload A with the entry's token byte (keeps the CP flags) so a match emits it
        LD A,(DE)
        ; drop the high bit that marks every name char; a resulting $00 is the table-end terminator
        AND $7F
        ; end of operator table, nothing matched: pass the character through unchanged
        JP Z,CRUNCH_NORMALIZE_CTRL
        INC DE
        ; does this entry's operator char match the source character?
        CP (HL)
        LD A,(DE)
        JR NZ,CRUNCH_27
        JP CRUNCH_EMIT_OP
; ----------------------------------------------------------------------
; CRUNCH_AMP_HEX_OCT -- post-keyword char/token emit router: special-case an '&' (&H hex / &O octal radix literal), otherwise emit the byte verbatim.
;   In:        A = the byte routed in through CRUNCH_16 from CRUNCH_EMIT_6 -- either an operator token (operator-match path) or a normalized source char (non-operator CRUNCH_EMIT_5 path); HL -> the source char. DE/BC are LIVE (already POPped from the stack by CRUNCH_16), DE = output cursor, BC = remaining count. Reached only from CRUNCH_16 when A is neither ELSE nor $EA (TOK_REM_QUOTE).
;   Out:       if A != '&' ($26), branches to CRUNCH_30 to emit the byte (char or token). If '&', emits the radix marker token ($0B octal / $0C hex), scans and converts the radix digits, and rejoins the numeric-literal emit path at CRUNCH_19.
;   Clobbers:  A, HL (advanced past the digits by SCAN_AMP_RADIX_CONST in the '&' case), DE/BC (saved/restored across the scan).
;   Algorithm: Test for '&' ($26). On '&', peek the next char (CHRGET), upper-case it (TOUPPER_A), and choose the marker: $0C if 'H' (hex), else $0B (octal). Fall into CRUNCH_29 to emit the marker and parse the constant. Note '&' is NOT in RESWORD_OPS, so it arrives here as a normalized char via CRUNCH_EMIT_5.
; ----------------------------------------------------------------------
CRUNCH_AMP_HEX_OCT:
        ; is this byte an '&' radix-constant prefix (&H hex / &O octal)?
        CP $26
        ; not '&': branch to CRUNCH_30 to emit the byte (ordinary char or operator token)
        JR NZ,CRUNCH_PASS_CHAR
        PUSH HL
        ; peek the char after '&' to distinguish &H from &O
        CALL CHRGET
        POP HL
        CALL TOUPPER_A
        ; 'H' -> hex; otherwise treat as octal
        CP $48
        ; default radix marker = octal ($0B), loaded before the branch resolves
        LD A,$0B
        JR NZ,CRUNCH_AMP_EMIT_AND_SCAN
        ; 'H' matched: override with the hex radix marker ($0C)
        LD A,$0C
; ----------------------------------------------------------------------
; CRUNCH_AMP_EMIT_AND_SCAN -- emit the chosen &-radix marker, parse the radix digits, and rejoin the numeric emit path.
;   In:        A = radix marker ($0B octal / $0C hex) chosen by CRUNCH_AMP_HEX_OCT; HL -> first radix digit in source; DE/BC live (DE = output cursor, BC = remaining count).
;   Out:       radix marker written to the output buffer; the 16-bit converted value handed to CRUNCH_19 (which emits it low byte then high byte via CRUNCH_20/21); HL advanced past the constant.
;   Clobbers:  A, HL, DE/BC (saved across the scan; BC restored by POP, DE left on the stack for CRUNCH_19 to recover).
;   Algorithm: Write the radix marker via CRUNCH_EMIT, PUSH DE/BC to preserve the output cursor, CALL SCAN_AMP_RADIX_CONST to convert the hex/octal digits to a 16-bit integer, POP BC, then JP CRUNCH_19. [RE] CRUNCH_19 (EX (SP),HL recovering the saved DE) emits the value through CRUNCH_20/21; the exact register holding the converted value depends on SCAN_AMP_RADIX_CONST's contract (not re-verified here).
; ----------------------------------------------------------------------
CRUNCH_AMP_EMIT_AND_SCAN:
        ; write the &O/&H radix-marker byte to the crunch buffer
        CALL CRUNCH_EMIT
        PUSH DE
        PUSH BC
        ; convert the following hex/octal digits to a 16-bit integer
        CALL SCAN_AMP_RADIX_CONST
        POP BC
        ; rejoin the numeric-literal path to emit the converted value's two bytes
        JP CRUNCH_19
; ----------------------------------------------------------------------
; CRUNCH_PASS_CHAR -- emit the byte in A (an ordinary char, a space, or an operator/radix token) to the output buffer and update the literal/line-number mode flags it triggers.
;   In:        A = the byte to emit; HL -> that char in the source line; DE = output cursor, BC = remaining count (live working values; reached from CRUNCH_1, CRUNCH_18, CRUNCH_28, or CRUNCH_33).
;   Out:       byte written to (DE) with DE advanced / BC decremented (CRUNCH_EMIT); CRUNCH_LITERAL_MODE and CRUNCH_LINENUM_MODE updated for ':' and the DATA token; control returns to CRUNCH_1 for the next char, EXCEPT when the byte is the REM token ($8F = TOK_REM), which falls into the verbatim copy loop (CRUNCH_33) to copy the rest of the line.
;   Clobbers:  A, HL (INC'd past the char), DE/BC (advanced by emit).
;   Algorithm: INC HL past the char, copy A to the output via CRUNCH_EMIT (AF preserved across the call by PUSH/POP). Then classify by subtracting code points: SUB $3A == 0 means ':' (statement separator) -> arm both modes with A=$00; CP $4A (testing char == $3A+$4A = $84 = TOK_DATA) means DATA -> set A=$01 and arm both modes (DATA text is copied raw). Finally at CRUNCH_32 the residual (char-$3A) SUB $55 == 0 means char == $8F = TOK_REM -> enter the verbatim copy-to-end-of-line loop (CRUNCH_33); any other byte loops back to CRUNCH_1.
; ----------------------------------------------------------------------
CRUNCH_PASS_CHAR:
        ; consume this source char
        INC HL
        PUSH AF
        ; copy the byte through to the output buffer unchanged (AF preserved across the call)
        CALL CRUNCH_EMIT
        POP AF
        ; classify the char: $3A == ':' arms literal+linenum modes
        SUB $3A
        JR Z,CRUNCH_SET_LITERAL_MODE
        ; residual $4A means char == $84 = TOK_DATA: DATA text is also copied raw
        CP $4A
        JR NZ,CRUNCH_CHECK_REM_TEXT
        ; DATA: flag value 1 to arm literal mode below
        LD A,$01
; ----------------------------------------------------------------------
; CRUNCH_SET_LITERAL_MODE -- arm both CRUNCH mode flags so following text is passed through and a following number is treated as a line number.
;   In:        A = flag value ($00 from the ':' / SUB $3A == 0 path, $01 from the DATA token).
;   Out:       CRUNCH_LITERAL_MODE ($0B15) and CRUNCH_LINENUM_MODE ($0B16) both set to A.
;   Clobbers:  (memory only) the two mode cells; A unchanged, then falls into CRUNCH_32.
;   Algorithm: Store A into both mode flags, then fall into CRUNCH_CHECK_REM_TEXT. For ':' A is already $00; the DATA path enters with A=$01.
; ----------------------------------------------------------------------
CRUNCH_SET_LITERAL_MODE:
        ; arm verbatim pass-through for the text that follows ':' or DATA
        LD (CRUNCH_LITERAL_MODE),A
        ; also arm line-number mode (a following digit run becomes a line number)
        LD (CRUNCH_LINENUM_MODE),A
; ----------------------------------------------------------------------
; CRUNCH_CHECK_REM_TEXT -- decide whether the just-emitted byte is the REM token (and thus starts verbatim REM text), else resume the main loop.
;   In:        A = the char's residual after the SUB $3A classification in CRUNCH_PASS_CHAR (so A = char - $3A on the fall-through path, or $00/$01 from the ':' / DATA paths).
;   Out:       SUB $55; if non-zero, jumps to CRUNCH_1 (continue normal crunching); if zero (the byte was $8F = TOK_REM), PUSH AF (saving A=$00, the REM verbatim-loop's stop byte) and fall into CRUNCH_33 to copy the rest of the line raw.
;   Clobbers:  A.
;   Algorithm: SUB $55. A non-zero result returns to the main per-char loop. A zero result (char == $8F = TOK_REM) identifies REM, so push the now-zero AF as the verbatim loop's saved stop byte ($00) and drop into the raw copy loop.
; ----------------------------------------------------------------------
CRUNCH_CHECK_REM_TEXT:
        SUB $55
        ; not the REM token: continue the normal per-char crunch loop
        JP NZ,CRUNCH_SCAN
        ; REM: save A=$00 as the verbatim loop's stop byte and copy the line tail raw
        PUSH AF
; ----------------------------------------------------------------------
; CRUNCH_VERBATIM_LOOP -- copy source characters to the output unchanged until end-of-line, or until a saved stop/delimiter byte is hit.
;   In:        HL -> next source char; DE = output cursor, BC = remaining count; top of stack holds the saved stop byte ($00 for the REM/apostrophe-comment paths, the closing quote $22 for the string-literal path, $EA for the apostrophe-REM path), re-pushed each iteration by CRUNCH_34.
;   Out:       on $00 (end of line) -> CRUNCH_36 to finalize; on a char equal to the saved stop byte -> CRUNCH_30 to emit that delimiter and resume normal crunching; otherwise the char is emitted and the loop repeats.
;   Clobbers:  A, HL, DE/BC (advanced by CRUNCH_35 emit), and the top stack slot via EX (SP),HL.
;   Algorithm: LD A,(HL); OR A tests for the $00 line terminator (and leaves A=char). The EX (SP),HL / LD A,H / POP HL idiom swaps the saved stop byte off the stack: HL = saved AF (H = the stop byte), then A = H = stop byte, then POP HL restores the source pointer; the source char's Z-flag from OR A survives. If the char was $00, finalize (CRUNCH_36). If the char equals the stop byte, emit it via CRUNCH_30 (ending the run). Otherwise fall into CRUNCH_34/CRUNCH_35 to emit it and loop.
; ----------------------------------------------------------------------
CRUNCH_VERBATIM_LOOP:
        ; fetch the next source char of the literal/REM run
        LD A,(HL)
        ; test for the end-of-line $00 (leaves A = the char)
        OR A
        ; swap the saved stop byte off the stack while keeping the source pointer accessible
        EX (SP),HL
        LD A,H
        POP HL
        ; end of line: go finalize the crunched line
        JR Z,CRUNCH_FINALIZE_LINE
        ; did we reach the stop byte (e.g. the matching quote)?
        CP (HL)
        ; stop byte reached: emit it via CRUNCH_30 and leave the verbatim run
        JR Z,CRUNCH_PASS_CHAR
; ----------------------------------------------------------------------
; CRUNCH_COPY_QUOTED -- string-literal entry AND per-iteration delimiter re-push for the verbatim loop.
;   In:        as a CRUNCH_1 entry: (HL)=='"' with A = the quote ($22) and HL -> the opening quote; DE/BC live. As the loop continuation from CRUNCH_33: A = the saved stop byte (from LD A,H) and HL -> the source char to emit.
;   Out:       PUSH AF re-saves the stop/delimiter byte for the next iteration; A reloaded from (HL) (the char to emit); falls into CRUNCH_35 to write it and loop in CRUNCH_VERBATIM_LOOP until the stop byte or end-of-line.
;   Clobbers:  A, HL, DE/BC.
;   Algorithm: PUSH AF saves the delimiter (the quote $22 on string entry, or the same stop byte each loop iteration); LD A,(HL) loads the source char to emit. Fall into CRUNCH_35. On the CRUNCH_1 quote entry this copies the opening quote first and uses $22 as the closing delimiter.
; ----------------------------------------------------------------------
CRUNCH_COPY_QUOTED:
        ; save the current stop/delimiter byte (the quote $22 on entry) for the next loop iteration
        PUSH AF
        ; load the source char to copy (the opening quote on first entry)
        LD A,(HL)
; ----------------------------------------------------------------------
; CRUNCH_EMIT_AND_LOOP -- emit one verbatim char and continue the literal copy loop.
;   In:        A = char/byte to write; HL -> the source char (advanced here); DE/BC live.
;   Out:       byte written via CRUNCH_EMIT, HL advanced past it, loops back to CRUNCH_VERBATIM_LOOP.
;   Clobbers:  A, HL, DE/BC.
;   Algorithm: INC HL to consume the source char, copy A to the output through CRUNCH_EMIT, then JR back to CRUNCH_VERBATIM_LOOP for the next char. Also reached from CRUNCH_16's $EA (TOK_REM_QUOTE, apostrophe-comment) handler, which has just emitted ':' + REM and re-pushed $EA as the loop stop byte.
; ----------------------------------------------------------------------
CRUNCH_EMIT_AND_LOOP:
        ; consume this source char
        INC HL
        CALL CRUNCH_EMIT
        ; continue copying the literal/REM run
        JR CRUNCH_VERBATIM_LOOP
; ----------------------------------------------------------------------
; CRUNCH_FINALIZE_LINE -- terminate the crunched line, compute its stored length in BC, and return the tokenized line pointer.
;   In:        DE -> just past the last emitted token byte (output cursor); BC = remaining buffer count, started at $013B in CRUNCH and decremented once per emitted byte.
;   Out:       three $00 bytes written at (DE) (the line's terminating NUL plus two zero bytes); BC = $0140 - BC = (bytes emitted) + 5; HL = L_08CE ($08CE) = KBUF-1, a CHRGET-style 'line minus one' pointer (it holds a ':' guard byte, so an INC HL/LD A,(HL) lands on the first token).
;   Clobbers:  A (zeroed), HL, BC, DE (advanced by the three stores).
;   Algorithm: Compute BC = $0140 - BC via L-then-H subtract-with-borrow. Since BC = $013B - emitted, this yields emitted + 5 ([RE] the +5 corresponds to the 4-byte stored-line header (link word + line-number word) plus the terminating NUL). Point HL at L_08CE = $08CE (the ':' guard one byte before KBUF). Zero A and store it three times at the output: the terminating NUL plus two zero bytes ([RE] the zero link that marks end-of-program when this line is later inserted). RET.
; ----------------------------------------------------------------------
CRUNCH_FINALIZE_LINE:
        ; compute stored length: BC = $0140 - BC = (bytes emitted) + 5 ([RE] header + NUL bias)
        LD HL,$0140
        LD A,L
        SUB C
        LD C,A
        LD A,H
        SBC A,B
        LD B,A
        ; return HL = $08CE = KBUF-1 (the ':' guard) so CHRGET lands on the first token
        LD HL,L_08CE
        ; write the terminating NUL plus two zero bytes ([RE] the end-of-program zero link)
        XOR A
        LD (DE),A
        INC DE
        LD (DE),A
        INC DE
        LD (DE),A
        RET
; ----------------------------------------------------------------------
; CRUNCH_EMIT_COLON -- emit a statement-separator colon (':') into the crunch output buffer
;   In:        DE = next free byte of the crunch output buffer (KBUF/$0140-sized window); BC = bytes of buffer space remaining
;   Out:       ':' ($3A) appended; DE advanced by 1; BC decremented by 1 (does not return on buffer exhaustion -- falls into the overflow tail of CRUNCH_EMIT)
;   Clobbers:  A (loaded with $3A), then whatever CRUNCH_EMIT clobbers (A,DE,BC,(DE))
;   Algorithm: Load A=':' and fall straight into CRUNCH_EMIT. Called only from CRUNCH_16 to synthesize the implicit ':' inserted before an ELSE clause (CP TOK_ELSE / CALL Z) and the ':' that prefixes the apostrophe-comment token $EA before its emitted REM ($EA -> :REM), so the runtime sees a real statement boundary.
; ----------------------------------------------------------------------
CRUNCH_EMIT_COLON:
        LD A,$3A
; ----------------------------------------------------------------------
; CRUNCH_EMIT -- append one tokenized byte to the crunch output buffer with overflow check
;   In:        A = byte to store; DE = next free output position in the crunch buffer; BC = remaining output-buffer space
;   Out:       On success: byte stored at (DE), DE incremented, BC decremented, returns to caller. When BC reaches 0 it does NOT return -- it falls into CRUNCH_EMIT_OVERFLOW and raises error 23.
;   Clobbers:  A (reloaded with C then OR'd with B for the zero test); memory at (DE); DE; BC
;   Algorithm: Store A->(DE); INC DE; DEC BC; if BC != 0 (LD A,C / OR B / RET NZ) return. The single low-level writer for every byte the tokenizer emits (token bytes, copied identifier characters, line-number constants); centralizing it gives one overflow guard for the whole CRUNCH pass.
; ----------------------------------------------------------------------
CRUNCH_EMIT:
        LD (DE),A
        INC DE
        ; one fewer byte of output-buffer room; falls into the overflow tail when it reaches zero
        DEC BC
        LD A,C
        OR B
        RET NZ
; ----------------------------------------------------------------------
; CRUNCH_EMIT_OVERFLOW -- raise "Line buffer overflow" (error 23) when the crunch/input line is too long
;   In:        (no register inputs of interest -- entered on output-buffer exhaustion, or jumped to directly from the line-input path)
;   Out:       Never returns; transfers to the error dispatcher RAISE_ERROR with E = ERR_LINE_BUFFER_OVERFLOW (23 = $17)
;   Clobbers:  E
;   Algorithm: Load E = 23 (ERR_LINE_BUFFER_OVERFLOW) and JP RAISE_ERROR. Reached two ways: (1) fall-through from CRUNCH_EMIT when the crunched line would overrun the output buffer; (2) an explicit JP from INLIN_STORE_CHAR when a line being read FROM AN ACTIVE FILE (PTRFIL != 0) exceeds 255 characters -- [RE] note: the console/no-file case (PTRFIL == 0) does NOT reach here, it rings the bell at INLIN_15 instead. Either way the line is too long to tokenize.
; ----------------------------------------------------------------------
CRUNCH_EMIT_OVERFLOW:
        LD E,ERR_LINE_BUFFER_OVERFLOW
        JP RAISE_ERROR
; ----------------------------------------------------------------------
; CRUNCH_COPY_IDENT -- begin copying a non-keyword word (variable/identifier) to the output verbatim
;   In:        On stack (top-down): saved word-start text pointer (pushed at CRUNCH_7), then saved BC (remaining output space) and DE (output ptr) pushed at the top of the per-token loop (CRUNCH_2); A = 0 (both entries set A=0 -- via AND $7F yielding Z at $3098, or explicit LD A,$00 at $30BF)
;   Out:       Falls into CRUNCH_COPY_IDENT_LOOP with HL at the word's first character, BC/DE restored, A = that first character, and CRUNCH_LINENUM_MODE = $FF (the "just-emitted-an-identifier" sentinel)
;   Clobbers:  A, HL, BC, DE, CRUNCH_LINENUM_MODE
;   Algorithm: Reached when the reserved-word matcher found the word matches NO keyword (the name table ran out at CRUNCH_8, or a non-abbreviated word ran past with no match). POP the saved word-start pointer; [RE] DEC HL backs it up one so the first letter is re-read (the saved pointer had been advanced past the first char during matching). DEC A turns the incoming A=0 into $FF and stores it into CRUNCH_LINENUM_MODE to record that an identifier was just emitted (so a following digit run is NOT taken as a target line number). Restore the output cursor (BC,DE); prime A with the first character via CHRGET_UPCASE (which reads (HL), does not advance); fall into the copy loop.
; ----------------------------------------------------------------------
CRUNCH_COPY_IDENT:
        ; word matched no keyword: recover the saved pointer to the word's start
        POP HL
        DEC HL
        DEC A
        ; A=$FF here (0 then DEC A): mark "an identifier was just emitted" so a following digit run is not treated as a target line number
        LD (CRUNCH_LINENUM_MODE),A
        POP BC
        POP DE
        CALL CHRGET_UPCASE
; ----------------------------------------------------------------------
; CRUNCH_COPY_IDENT_LOOP -- copy an identifier (letters, digits, '.') to the output verbatim
;   In:        A = current character to emit; HL -> that character in the source text; DE/BC = crunch output cursor/room
;   Out:       Each accepted character appended via CRUNCH_EMIT and HL advanced; on the first character outside {A-Z, 0-9, '.'} it exits to CRUNCH_COPY_IDENT_DONE (-> CRUNCH_1) with HL at that terminating character
;   Clobbers:  A, HL, DE, BC, flags
;   Algorithm: Loop: emit A; INC HL and fetch+upcase the next char (CHRGET_UPCASE). IS_LETTER_A returns carry CLEAR for a letter A-Z and SET for a non-letter, so JR NC loops on letters. Otherwise the char is accepted only if it is a digit ($30-$39, after rejecting >= ':' first) or a literal '.' ($2E), both legal in BASIC variable names, and the loop continues on those; any other byte (space, ':', operator, end) terminates the name.
; ----------------------------------------------------------------------
CRUNCH_COPY_IDENT_LOOP:
        ; append this identifier character to the output line
        CALL CRUNCH_EMIT
        INC HL
        CALL CHRGET_UPCASE
        CALL IS_LETTER_A
        ; carry clear = letter (A-Z): still inside the identifier, keep copying
        JR NC,CRUNCH_COPY_IDENT_LOOP
        CP $3A
        ; char >= ':' (and not a letter) ends the name -- stop copying
        JR NC,CRUNCH_COPY_IDENT_DONE
        CP $30
        ; digit 0-9: a legal identifier continuation character, keep copying
        JR NC,CRUNCH_COPY_IDENT_LOOP
        CP $2E
        ; '.' is allowed inside BASIC variable names, keep copying
        JR Z,CRUNCH_COPY_IDENT_LOOP
; ----------------------------------------------------------------------
; CRUNCH_COPY_IDENT_DONE -- identifier fully copied; resume the main tokenizer scan
;   In:        HL -> the first character that is not part of the identifier
;   Out:       Jumps to CRUNCH_1 to tokenize from that character
;   Clobbers:  (none beyond the jump)
;   Algorithm: Single JP CRUNCH_1. Common exit for the identifier-copy loop, reached when the next source character is outside {A-Z, 0-9, '.'}.
; ----------------------------------------------------------------------
CRUNCH_COPY_IDENT_DONE:
        JP CRUNCH_SCAN
; ----------------------------------------------------------------------
; CRUNCH_NORMALIZE_CTRL -- normalize an unmatched punctuation/control character before emitting it
;   In:        HL -> the current (unmatched) source character; reached from CRUNCH_27 when the operator table scan (which walks RESWORD_OPS, starting one past the KWGRP_Z $00 terminator) hit its terminator with no match
;   Out:       Falls into CRUNCH_EMIT_OP with A = the character to emit: the original byte if printable ($20+) or TAB/LF, otherwise $20 (space)
;   Clobbers:  A, flags
;   Algorithm: Load the source byte (HL). If >= $20 (printable) keep it. Otherwise keep it only if it is TAB ($09) or LF ($0A); any other control character is replaced by a space ($20) so stray control bytes do not leak into the tokenized line. Then fall through to the single-character emit path.
; ----------------------------------------------------------------------
CRUNCH_NORMALIZE_CTRL:
        ; no operator matched: take the raw source character
        LD A,(HL)
        CP $20
        JR NC,CRUNCH_EMIT_OP
        CP $09
        JR Z,CRUNCH_EMIT_OP
        CP $0A
        JR Z,CRUNCH_EMIT_OP
        ; a stray control char (not TAB/LF): substitute a space
        LD A,$20
; ----------------------------------------------------------------------
; CRUNCH_EMIT_OP -- finalize a single-character operator/punctuation byte and rejoin the matched-token epilogue
;   In:        A = byte to emit -- the operator TOKEN byte loaded from the RESWORD_OPS table by CRUNCH_27 on a match, or a normalized punctuation/control char from CRUNCH_NORMALIZE_CTRL
;   Out:       Pushes A (byte to emit), recomputes the line-number-mode flag into A, then JP CRUNCH_16 where the byte is popped and emitted by the shared token epilogue
;   Clobbers:  A, stack (one PUSH AF consumed by CRUNCH_16's POP AF), flags
;   Algorithm: Save the byte to emit (PUSH AF). Read CRUNCH_LINENUM_MODE: INC A maps the $FF "identifier-just-emitted" sentinel to 0 (Z set -> JR Z skips the following DEC A, committing 0), while any other value (0 normal, 1 line-number-keyword) is restored by the DEC A. Carry the resulting flag in A into CRUNCH_16, which stores it back to CRUNCH_LINENUM_MODE and emits the saved byte. This funnels single-char operators through the same ELSE/REM-colon-aware epilogue used by reserved-word tokens.
; ----------------------------------------------------------------------
CRUNCH_EMIT_OP:
        ; stash the byte to emit; CRUNCH_16 will POP and write it
        PUSH AF
        LD A,(CRUNCH_LINENUM_MODE)
        ; if line-number-mode held the $FF identifier sentinel, INC->0 (Z) clears it and skips the DEC that restores 0/1 values
        INC A
        JR Z,CRUNCH_EMIT_OP_1
        DEC A
; ----------------------------------------------------------------------
; CRUNCH_EMIT_OP_1 -- shared tail of CRUNCH_EMIT_OP: jump into the matched-token epilogue with the flag already in A
;   In:        A = line-number-mode flag value to commit; byte to emit on the stack
;   Out:       Jumps to CRUNCH_16 (stores A to CRUNCH_LINENUM_MODE, pops and emits the stacked byte, handles ELSE/REM colon insertion)
;   Clobbers:  (none beyond the jump)
;   Algorithm: Single JP CRUNCH_16, reached both by the JR Z that skips DEC A (when the $FF sentinel was just folded to 0) and by fall-through after DEC A.
; ----------------------------------------------------------------------
CRUNCH_EMIT_OP_1:
        JP CRUNCH_STORE_FLAG_AND_EMIT
; ----------------------------------------------------------------------
; CRUNCH_SKIP_BLANKS_BACK -- back HL up over trailing whitespace, leaving it just past the last non-blank
;   In:        HL -> one past the end of a just-scanned token (e.g. after LINGET parsed a line number, or after a numeric/reserved-word scan)
;   Out:       HL points to the first character AFTER the last non-blank character (trailing space/TAB/LF trimmed); A = that last NON-blank byte (the byte that stopped the backward walk)
;   Clobbers:  A, HL, flags
;   Algorithm: Walk backward (DEC HL) skipping space ($20), TAB ($09), and LF ($0A); on the first non-whitespace byte (still in A), step forward once (INC HL) and return. Effectively trims trailing blanks so the tokenizer resumes immediately after the meaningful text rather than re-scanning the gap.
; ----------------------------------------------------------------------
CRUNCH_SKIP_BLANKS_BACK:
        ; step back over a trailing whitespace byte
        DEC HL
        LD A,(HL)
        CP $20
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        CP $09
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        CP $0A
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        ; hit a non-blank: re-advance one so HL sits just past the last real character
        INC HL
        RET
; ----------------------------------------------------------------------
; STMT_FOR -- FOR statement handler (token $82): begin building the FOR/NEXT loop frame.
;   In:        HL -> crunched text just past the FOR token (at the index variable name).
;   Out:       Falls through to the FOR-frame reuse scan (STMT_FOR_1). On completion a FOR
;              frame is pushed on the runtime stack and control enters the NEXT body for the
;              zero-trip test.
;   Clobbers:  AF,BC,DE,HL,SP,FAC; PTRGET_SUBSCRIPT_FLAG, OPEN_RESUME_TEXT_PTR, L_0C6D, L_0B4E, VALTYP.
;   Algorithm: Parse 'FOR var = init'. Force scalar-variable context (PTRGET_SUBSCRIPT_FLAG=$64 so
;              PTRGET rejects an array element), PTRGET the index variable -> its address in DE.
;              SYNCHR the '=' token. Save the index-variable address (via OPEN_RESUME_TEXT_PTR).
;              [RE] Evaluate the initial expression (FRMEVL_NOPAREN) into the FAC, coerce it to
;              the index variable's type (FRMEVL_APPLY_OP dispatched by the saved VALTYP), and copy
;              the coerced FAC into the scratch numeric cell L_0C6D. [RE] Then CALL STMT_DATA to
;              scan forward over the rest of the FOR statement and record the resulting text
;              pointer in L_0B4E (used as this loop's frame-match key). HL=SP+2 prepares the
;              runtime-stack walk in STMT_FOR_1. UNKNOWN: the precise field-by-field frame layout
;              and exactly where the init value is ultimately written into the variable are not
;              fully pinned by static reading; treat the cell roles as [RE].
; ----------------------------------------------------------------------
STMT_FOR:
        ; Force scalar (non-array) variable resolution in PTRGET so the FOR index cannot be an array element.
        LD A,$64
        LD (PTRGET_SUBSCRIPT_FLAG),A
        ; Resolve the index variable name -> its storage address in DE; HL advances past the name.
        CALL PTRGET_1+1
        ; Require the '=' token after the index variable (syntax error otherwise).
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        PUSH DE
        EX DE,HL
        ; [RE] Save the index-variable address here (HL holds the var address after the EX DE,HL above, not a text pointer).
        LD (OPEN_RESUME_TEXT_PTR),HL
        EX DE,HL
        LD A,(VALTYP)
        PUSH AF
        ; Evaluate the initial-value expression into the FAC.
        CALL FRMEVL_NOPAREN
        POP AF
        PUSH HL
        ; [RE] Coerce the FAC to the index variable's type: the saved VALTYP (AND $07) indexes the type-conversion entries of OPERATOR_ROUTINE_TBL (CINT/CSNG/CDBL).
        CALL FRMEVL_APPLY_OP
        ; [RE] Copy the coerced FAC into the scratch numeric cell L_0C6D (FP_MOVE_TO_FAC copies FAC->here); reused later by NEXT, not a write into the variable itself.
        LD HL,FOR_NEXT_VALUE_TEMP
        CALL FP_MOVE_TO_FAC
        POP HL
        POP DE
        POP BC
        PUSH HL
        ; [RE] Scan forward over the remainder of the FOR statement; the returned text pointer becomes this loop's frame key.
        CALL STMT_DATA
        ; [RE] Record that scanned text pointer as the frame-match key for the reuse scan.
        LD (L_0B4E),HL
        ; Point HL at the live runtime stack (SP+2) to begin the open-frame scan.
        LD HL,$0002
        ADD HL,SP
; ----------------------------------------------------------------------
; STMT_FOR_1 -- FOR-frame reuse scan: discard any open FOR frame on the same loop key.
;   In:        HL -> a runtime-stack position to scan; L_0B4E = this loop's frame-match key (set by STMT_FOR).
;   Out:       On a match, SP/SAVSTK are rewound to drop the stale frame (and the frames pushed
;              inside it); always continues into STMT_FOR_2 to push the new frame.
;   Clobbers:  AF,BC,DE,HL,SP,SAVSTK.
;   Algorithm: [RE] Call STKFRAME_SCAN to find the next open FOR marker ($82) frame on the stack;
;              if none (NZ) go push a fresh frame. Otherwise read that frame's stored key pointer
;              and compare it (CMP_HL_DE) to L_0B4E: mismatch -> keep scanning outward; match -> a
;              re-entered loop, so reset SP to that frame (discarding it and everything pushed
;              inside) before pushing anew. This prevents a GOTO back into a FOR from leaking
;              stack frames. UNKNOWN: STKFRAME_SCAN and STMT_FOR_1 read two different frame fields
;              (the marker-adjacent word vs a word near the 16-byte frame top); the exact field
;              each matches is not fully disambiguated statically.
; ----------------------------------------------------------------------
STMT_FOR_1:
        ; Find the next open FOR frame on the runtime stack.
        CALL STKFRAME_SCAN
        POP DE
        ; No more FOR frames found: this is a brand-new loop, go push its frame.
        JR NZ,STMT_FOR_2
        ADD HL,BC
        PUSH DE
        DEC HL
        LD D,(HL)
        DEC HL
        LD E,(HL)
        INC HL
        INC HL
        PUSH HL
        ; [RE] Compare the scanned frame's key against this loop's key.
        LD HL,(L_0B4E)
        CALL CMP_HL_DE
        POP HL
        ; Different loop: keep scanning further out on the stack.
        JP NZ,STMT_FOR_1
        POP DE
        ; Same loop re-entered: rewind the stack to drop the stale frame and any nested frames.
        LD SP,HL
        LD (SAVSTK),HL
; ----------------------------------------------------------------------
; STMT_FOR_2 -- push the FOR frame header (key word + body text pointer) and parse TO.
;   In:        Comes from STMT_FOR_1; L_0B4E = the loop key; SAVTXT = current line text pointer.
;   Out:       8 stack bytes reserved; the frame's key word and the SAVTXT word are pushed; the
;              TO limit expression has been evaluated into the FAC.
;   Clobbers:  AF,BC,DE,HL,SP,FAC.
;   Algorithm: Ensure 8 bytes of stack headroom (CHECK_STACK_ROOM). Push L_0B4E and the current
;              SAVTXT into the new frame (via the PUSH/EX (SP),HL idiom). SYNCHR the 'TO' token.
;              [RE] FRMEVL_TEST_TYPE then JP Z/JP NC reject a non-acceptable limit type (string
;              gives Z; the NC arm also rejects, e.g. a double-precision limit) with TYPE
;              MISMATCH. Evaluate the TO limit expression into the FAC for STMT_FOR_3/_4.
; ----------------------------------------------------------------------
STMT_FOR_2:
        EX DE,HL
        ; Reserve 8 bytes of stack room for the next part of the FOR frame.
        LD C,$08
        CALL CHECK_STACK_ROOM
        PUSH HL
        ; [RE] Push this loop's key pointer into the frame.
        LD HL,(L_0B4E)
        EX (SP),HL
        PUSH HL
        ; Push the current line text pointer (SAVTXT) into the frame.
        LD HL,(SAVTXT)
        EX (SP),HL
        ; Require the 'TO' token before the limit expression.
        CALL SYNCHR
        DEFB    TOK_TO                   ; inline keyword-token arg consumed by the preceding CALL
        ; [RE] Test the limit's VALTYP: reject a string (Z) or the NC type with TYPE MISMATCH (the limit must be an acceptable numeric type).
        CALL FRMEVL_TEST_TYPE
        JP Z,RAISE_TYPE_MISMATCH
        JP NC,RAISE_TYPE_MISMATCH
        PUSH AF
        ; Evaluate the TO limit expression into the FAC.
        CALL FRMEVL_NOPAREN
        POP AF
        PUSH HL
        JP P,STMT_FOR_3
        CALL FN_CINT
        EX (SP),HL
        LD DE,$0001
        LD A,(HL)
        CP TOK_STEP
        CALL Z,GETINT_CHRGET
        PUSH DE
        PUSH HL
        EX DE,HL
        CALL FP_MANT_SIGN
        JR STMT_FOR_4
; ----------------------------------------------------------------------
; STMT_FOR_3 -- single-precision TO/STEP path: capture a floating limit and STEP value.
;   In:        FAC = TO limit (numeric); HL -> text after the limit; entered when the limit type's
;              sign flag was positive (single/general path).
;   Out:       Limit (single) and a STEP value pushed; STEP sign computed; A = $01 (single marker).
;   Clobbers:  AF,BC,DE,HL,SP,FAC.
;   Algorithm: Coerce the limit to single (FN_CSNG), load it from the FAC (FP_LOAD_FAC), push it.
;              Default STEP = +1.0 (BC=$8100 seeds single exponent $81 / mantissa, spread to D,E;
;              A=$01). If a STEP token follows, evaluate the STEP expression (FRMEVL_LOWPREC),
;              coerce to single, load it, and take its sign (FP_SIGN, -1/0/+1) so NEXT knows the
;              loop direction. Joins STMT_FOR_5 to push the frame tail.
; ----------------------------------------------------------------------
STMT_FOR_3:
        ; Coerce the TO limit to single precision.
        CALL FN_CSNG
        CALL FP_LOAD_FAC
        POP HL
        PUSH BC
        PUSH DE
        ; Seed the default STEP of +1.0 (single: exponent $81, zero mantissa spread into D,E).
        LD BC,$8100
        LD D,C
        LD E,D
        LD A,(HL)
        ; Is an explicit STEP clause present?
        CP TOK_STEP
        LD A,$01
        JR NZ,STMT_FOR_5
        ; Evaluate the explicit STEP expression.
        CALL FRMEVL_LOWPREC
        PUSH HL
        CALL FN_CSNG
        CALL FP_LOAD_FAC
        ; Compute the STEP's sign (-1/0/+1) so NEXT knows whether the loop counts up or down.
        CALL FP_SIGN
; ----------------------------------------------------------------------
; STMT_FOR_4 -- integer-path STEP join point: recover the text pointer before pushing the frame tail.
;   In:        Stack top = text pointer saved on the integer (FN_CINT) branch.
;   Out:       HL = text pointer; falls into STMT_FOR_5.
;   Clobbers:  HL.
;   Algorithm: One-instruction landing pad (POP HL) for the integer branch (the FN_CINT path that
;              defaulted STEP=$0001 and took its sign via FP_MANT_SIGN); pops the saved text
;              pointer and continues into the common frame-tail push.
; ----------------------------------------------------------------------
STMT_FOR_4:
        POP HL
; ----------------------------------------------------------------------
; STMT_FOR_5 -- push the FOR frame tail (STEP value, STEP sign, VALTYP, key/marker) and verify end-of-statement.
;   In:        BC/DE = STEP value bytes; A = STEP sign/direction marker; HL -> text after TO/STEP clause.
;   Out:       STEP value, STEP sign and the loop variable's VALTYP pushed; HL re-fetched; SYNTAX
;              ERROR unless at end-of-statement; control jumps into the NEXT body for the
;              zero-trip test.
;   Clobbers:  AF,BC,DE,HL,SP.
;   Algorithm: Push the STEP value (BC,DE) and the STEP-sign byte (A). Push the loop variable's
;              VALTYP (FRMEVL_TEST_TYPE -> A). Re-fetch the text (DEC HL; CHRGET) and require
;              end-of-statement (Z) or raise SYNTAX ERROR. [RE] CALL BLOCK_SCAN_FORNEXT (which
;              records the current line text pointer in L_0C71 as it scans the line); store that
;              into SAVTXT, push OPEN_RESUME_TEXT_PTR (the saved index-variable address) and the
;              $82 FOR marker, then jump into the NEXT body (STMT_NEXT_1+1) to run the zero-trip
;              test. UNKNOWN: BLOCK_SCAN_FORNEXT's exact role here (it is a THEN/ELSE/line scanner,
;              not obviously a 'find matching NEXT' search) is not fully pinned.
; ----------------------------------------------------------------------
STMT_FOR_5:
        PUSH BC
        PUSH DE
        ; Stage the STEP value and its sign byte to push into the frame.
        LD C,A
        ; Push the loop variable's VALTYP (type/precision) into the frame.
        CALL FRMEVL_TEST_TYPE
        LD B,A
        PUSH BC
        DEC HL
        ; Re-fetch the text; require end-of-statement after the FOR clause.
        CALL CHRGET
        ; Anything other than end-of-statement after the FOR clause is a syntax error.
        JP NZ,RAISE_SYNTAX_ERROR
        ; [RE] Scan the line, tracking the current line text pointer in L_0C71.
        CALL BLOCK_SCAN_FORNEXT
        CALL CHRGET
        PUSH HL
        PUSH HL
        ; Use the tracked line pointer as SAVTXT for the frame.
        LD HL,(L_0C71)
        LD (SAVTXT),HL
        ; [RE] Push the saved index-variable address into the frame.
        LD HL,(OPEN_RESUME_TEXT_PTR)
        EX (SP),HL
        ; Tag the frame with the $82 FOR marker so STKFRAME_SCAN/NEXT recognize it.
        LD B,$82
        PUSH BC
        INC SP
        PUSH AF
        PUSH AF
        ; Enter the NEXT body to run the zero-trip test and start the loop (NEXT flag byte = 0).
        JP STMT_NEXT_1+1
; ----------------------------------------------------------------------
; STMT_FOR_6 -- loop re-iteration entry from NEXT: re-tag the FOR frame and resume the body.
;   In:        HL -> the loop body's resume text pointer (set up by NEXT before jumping here).
;   Out:       Re-stamps the FOR marker on the retained frame; falls into STMT_FOR_7 to execute
;              the next statement.
;   Clobbers:  BC,SP.
;   Algorithm: When NEXT decides the loop continues (JP STMT_FOR_6 from NEXT_LOOP_BODY), re-stamp
;              the $82 FOR marker on the kept frame (PUSH BC then INC SP trims the high byte of
;              the pushed pair) and drop into the per-statement executor with HL at the loop
;              body's first statement.
; ----------------------------------------------------------------------
STMT_FOR_6:
        ; Re-stamp the $82 FOR marker on the retained frame as the loop continues.
        LD B,$82
        PUSH BC
        INC SP
; ----------------------------------------------------------------------
; STMT_FOR_7 -- per-statement execution entry: poll the console, then run the next statement.
;   In:        HL -> the next statement's crunched text (at ':' or a statement token).
;   Out:       Dispatches the statement; services a pending key via INKEY_SCAN (Ctrl-C/break/pause);
;              refreshes OLDTXT and SAVSTK for error recovery and CONT.
;   Clobbers:  AF,HL (plus whatever the dispatched statement clobbers).
;   Algorithm: The universal 'execute next statement' re-entry. Save HL, call the BIOS
;              console-status routine (the cold-start-patched CALL at STMT_FOR_8), and if a key is
;              waiting run INKEY_SCAN. Record OLDTXT (current statement) and SAVSTK (stack mark).
;              If the next char is ':' continue with the next statement on the same line
;              (NEWSTT_NEXTLINE_2); if end-of-line ($00) advance to the next line (NEWSTT_NEXTLINE);
;              anything else is a SYNTAX ERROR.
; ----------------------------------------------------------------------
STMT_FOR_7:
        PUSH HL
; ----------------------------------------------------------------------
; STMT_FOR_8 -- self-modified console-status poll site (the cold-start-patched CALL).
;   In:        Operand at STMT_FOR_8+1 patched at cold start to the BIOS CONST routine address.
;   Out:       A/flags = console status (nonzero if a key is pending).
;   Clobbers:  per the BIOS CONST routine.
;   Algorithm: The on-disk operand is $0000 (placeholder); COLD_START stores the BIOS CONST
;              address into STMT_FOR_8+1 (LD (STMT_FOR_8+1),HL at $81F9 -> patch slot $336D; the
;              same HL is written to INKEY_SCAN_2+1 and RPC_CONST_POLL_1+1). Every statement then
;              polls the keyboard here without re-walking the BIOS jump table; the literal CALL
;              $0000 is never executed. (Corroborated by the existing VERIFIED [RE] comment above.)
; ----------------------------------------------------------------------
STMT_FOR_8:
        CALL $0000
        POP HL
        OR A
        CALL NZ,INKEY_SCAN
        LD (OLDTXT),HL
        LD (SAVSTK),SP
        LD A,(HL)
        CP $3A
        JR Z,NEWSTT_NEXTLINE_2
        OR A
        JP NZ,RAISE_SYNTAX_ERROR
        INC HL
; ----------------------------------------------------------------------
; NEWSTT_NEXTLINE -- advance to the next program line and optionally emit a TRON trace.
;   In:        HL -> the link field at the start of the next program line.
;   Out:       SAVTXT = the new line's text pointer; control resumes the statement executor; or
;              jumps to PROGRAM_END if the line link is $0000 (ran off the end of the program).
;   Clobbers:  AF,DE,HL.
;   Algorithm: Read the 2-byte next-line link; if zero, jump to PROGRAM_END. Otherwise read the
;              line-number word, stash the line's text pointer in SAVTXT, and if TRCFLG is set
;              print '[<linenum>]' (OUTCHR '[', FOUT, OUTCHR ']') before continuing into the
;              statement fetch/dispatch.
; ----------------------------------------------------------------------
NEWSTT_NEXTLINE:
        LD A,(HL)
        INC HL
        ; A $0000 line link marks end-of-program.
        OR (HL)
        ; Ran off the end: go to the program-end/ready path.
        JP Z,PROGRAM_END
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        ; Record this line's text pointer as the current statement source.
        LD (SAVTXT),HL
        ; If TRON tracing is on, print the line number in brackets before executing the line.
        LD A,(TRCFLG)
        OR A
        JR Z,NEWSTT_NEXTLINE_1
        PUSH DE
        LD A,$5B
        CALL OUTCHR
        CALL FOUT
        LD A,$5D
        CALL OUTCHR
        POP DE
; ----------------------------------------------------------------------
; NEWSTT_NEXTLINE_1 -- post-trace join: restore the text pointer into HL.
;   In:        DE -> the new line's text (preserved across the optional trace print).
;   Out:       HL -> the new line's text; falls into NEWSTT_NEXTLINE_2.
;   Clobbers:  HL,DE (swapped).
;   Algorithm: Single EX DE,HL landing pad so the trace and no-trace paths converge with HL at
;              the line's first statement.
; ----------------------------------------------------------------------
NEWSTT_NEXTLINE_1:
        EX DE,HL
; ----------------------------------------------------------------------
; NEWSTT_NEXTLINE_2 -- fetch the next statement token and route to the dispatcher.
;   In:        HL -> crunched text at the next statement (after ':' or at line start).
;   Out:       STMT_FOR_7 pushed as the post-statement return; on end-of-statement returns to it
;              immediately; otherwise falls into NEWSTT_DISPATCH with the token in A.
;   Clobbers:  AF,DE,HL.
;   Algorithm: CHRGET the next token. Push STMT_FOR_7 so the dispatched statement returns into the
;              per-statement executor. On end-of-statement ($00, Z) RET immediately to STMT_FOR_7
;              (empty statement / trailing ':'); otherwise fall through to decode and dispatch.
; ----------------------------------------------------------------------
NEWSTT_NEXTLINE_2:
        CALL CHRGET
        ; Arrange to return to the per-statement executor after this statement runs.
        LD DE,STMT_FOR_7
        PUSH DE
        ; Empty statement (end-of-line): return straight to the executor for the next statement/line.
        RET Z
; ----------------------------------------------------------------------
; NEWSTT_DISPATCH -- decode a statement token and jump through the statement-handler table.
;   In:        A = the leading token of the statement; HL -> text just past it.
;   Out:       Transfers to the matching statement handler (HL advanced by the falling-through CHRGET).
;   Clobbers:  AF,BC,DE,HL.
;   Algorithm: Bias the token by $81 (first statement token). On underflow (carry) the line does
;              not start with a statement keyword -> implied LET (STMT_LET). If >= $5B (past the
;              table) -> GETVAR_NAME_1 (non-statement/variable path). Otherwise scale by 2 (RLCA),
;              index STMT_DISPATCH_TBL ($0108), load the handler address into BC, PUSH it, and fall
;              into CHRGET so the handler starts at the first argument character and returns via
;              the previously pushed STMT_FOR_7.
; ----------------------------------------------------------------------
NEWSTT_DISPATCH:
        ; Bias to a 0-based statement index (first statement token = $81).
        SUB $81
        ; Not a statement keyword: treat the line as an implied LET assignment.
        JP C,STMT_LET
        ; Reject tokens past the end of the statement-handler table.
        CP $5B
        JP NC,GETVAR_NAME_1
        ; Scale the index by 2 for the word-wide DEFW table.
        RLCA
        LD C,A
        LD B,$00
        EX DE,HL
        ; Index the statement-handler table; load the handler address into BC.
        LD HL,STMT_DISPATCH_TBL
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        PUSH BC
        EX DE,HL

; ======================================================================
; CHARACTER FETCH (CHRGET / CHRGOT) + reserved-word fold
; ======================================================================
; ----------------------------------------------------------------------
; CHRGET -- advance the BASIC text pointer one byte, then fall into CHRGOT to fetch/classify it.
;   In:        HL -> current byte in the crunched program/text line.
;   Out:       HL incremented to the next byte, then (via CHRGOT) A = next significant char; C set iff A is an ASCII digit '0'-'9'; Z set at end-of-line/statement ($00); embedded constant tokens are expanded (see CHRGOT).
;   Clobbers:  A, HL, flags (plus the CHRGOT constant-staging cells on a constant token).
;   Algorithm: INC HL to step over the just-consumed byte, then drop straight into CHRGOT so a single fall-through path does the fetch, space-skipping, digit test and embedded-constant decode. The workhorse 'get next char' primitive called pervasively by the tokenizer, statement executor and expression evaluator.
; ----------------------------------------------------------------------
CHRGET:
        ; advance past the byte just consumed, then fall into CHRGOT to fetch the next one
        INC HL
; ----------------------------------------------------------------------
; CHRGOT -- re-fetch the CURRENT text char at (HL) into A without advancing, skipping spaces and expanding embedded constant tokens.
;   In:        HL -> current byte in the crunched program/text line.
;   Out:       A = next significant char (spaces skipped); C set iff A is an ASCII digit '0'-'9'; Z set at end-of-line/statement ($00). If (HL) is an embedded numeric-constant token ($0B-$1F) the staged constant is decoded into the CHRGOT_CONST_* cells, A returns the token byte (carry clear), and HL is loaded with the CHRGOT_11 continuation address.
;   Clobbers:  A, flags; on a constant token also HL and the CHRGOT_CONST_* staging cells.
;   Algorithm: Load (HL). Fast-path: if the char is >= ':' ($3A) RET NC -- carry is CLEAR there, which correctly reports 'not a digit' for keywords/operators/letters. Otherwise enter CHRGOT_1 to handle spaces, the $00 terminator, the digit range and the $0B-$1F embedded-constant tokens. CHRGET enters here after its INC HL; callers needing the current char without advancing call CHRGOT directly.
; ----------------------------------------------------------------------
CHRGOT:
        ; fetch the current text character
        LD A,(HL)
        ; fast exit for anything >= ':' (keywords, operators, letters): RET NC leaves carry clear = 'not a digit'
        CP $3A
        RET NC
; ----------------------------------------------------------------------
; CHRGOT_1 -- classify a char below ':' : skip spaces, detect end-of-line, split digits from the embedded constant tokens.
;   In:        A = char (< $3A) from CHRGOT; HL -> that char.
;   Out:       Spaces are skipped (loops back through CHRGET). $00 returns Z. Chars $21-$39 fall to the digit classifier CHRGOT_10 (C set iff digit). Tokens $01-$0A go to CHRGOT_9. Token $1E re-returns the prior decoded token byte. Other $0B-$1D (and $1F) tokens are decoded by CHRGOT_2..CHRGOT_8.
;   Clobbers:  A, flags; HL on the space-skip and constant-decode paths.
;   Algorithm: If char == ' ' ($20) loop to CHRGET to swallow the blank. If char > ' ' (so $21-$39) it is printable below ':' -> CHRGOT_10 digit test. Otherwise it is a control byte/token (< $20): OR A returns Z on the $00 terminator; CP $0B sends the very low control bytes ($01-$0A) to CHRGOT_9; the special $1E token re-loads and returns the previously decoded token byte from CHRGOT_CONST_TOKEN; all remaining tokens ($0B-$1D and $1F) fall to CHRGOT_2.
; ----------------------------------------------------------------------
CHRGOT_1:
        CP $20
        ; skip a literal space: loop back to CHRGET to fetch the following char
        JR Z,CHRGET
        ; printable char in $21-$39: go classify it as digit vs non-digit
        JR NC,CHRGOT_10
        OR A
        ; $00 = end of line / end of statement: return with Z set
        RET Z
        CP $0B
        ; control bytes $01-$0A (below the constant-token range): handle in CHRGOT_9
        JR C,CHRGOT_9
        ; $1E = 're-emit the last decoded constant token byte'
        CP $1E
        JR NZ,CHRGOT_2
        ; return the token byte that was stashed when this constant was first decoded
        LD A,(CONST_TOKEN)
        OR A
        RET
; ----------------------------------------------------------------------
; CHRGOT_2 -- handle the $10 'resume at saved pointer' marker, else dispatch a fresh constant token to CHRGOT_4.
;   In:        A = embedded token ($0B-$1D or $1F, already excluding $1E); HL -> that token byte.
;   Out:       For $10, jump to CHRGOT_3 to reload the saved post-constant text pointer and re-scan. For any other token, fall into CHRGOT_4 to decode and stage the constant.
;   Clobbers:  A, HL, flags.
;   Algorithm: CP $10: if the token is $10 (the marker meaning 'the real next char lives at the saved continuation pointer'), branch to CHRGOT_3 which reloads CHRGOT_CONST_TXTPTR and loops back into CHRGOT; otherwise this is a genuine constant token to expand, so fall through to CHRGOT_4.
; ----------------------------------------------------------------------
CHRGOT_2:
        ; $10 = 'resume scan at the saved text pointer' marker
        CP $10
        JR NZ,CHRGOT_4
; ----------------------------------------------------------------------
; CHRGOT_3 -- reload the saved post-constant text pointer and re-enter the scanner.
;   In:        CHRGOT_CONST_TXTPTR = text pointer just past a previously decoded embedded constant.
;   Out:       HL = that saved pointer; control falls into CHRGOT to fetch the next char from there.
;   Clobbers:  HL (and whatever CHRGOT clobbers).
;   Algorithm: After a constant has been expanded and consumed, scanning must continue at the byte following the constant. CHRGOT_3 loads HL from CHRGOT_CONST_TXTPTR and jumps to CHRGOT to resume. Reached from the $10 marker (CHRGOT_2) and as the common return target of all CHRGOT_CONST_VALUE paths after they materialize the value into the FAC.
; ----------------------------------------------------------------------
CHRGOT_3:
        ; restore the scan position to just past the decoded constant
        LD HL,(CONST_TEXT_RESUME)
        JR CHRGOT
; ----------------------------------------------------------------------
; CHRGOT_4 -- decode one embedded numeric-constant token, staging its value/type/text-pointer for the caller.
;   In:        A = token byte ($0B-$1D or $1F, not $10/$1E); HL -> the token byte (CHRGOT_4 immediately INC HLs past it); the token is also pushed (PUSH AF).
;   Out:       The decoded constant is staged: CHRGOT_CONST_TOKEN = token, CHRGOT_CONST_VALUE_CELL = value word (or FP bytes), CHRGOT_CONST_VALTYP = width/valtyp, CHRGOT_CONST_TXTPTR = text pointer past the constant; HL = CHRGOT_11; A = token (POPped), carry CLEAR; RET to caller.
;   Clobbers:  A, HL, flags, the CHRGOT_CONST_* cells (CHRGOT_8 also touches but restores DE/BC).
;   Algorithm: PUSH the token (AF) and INC HL past it. Stash the token in CHRGOT_CONST_TOKEN. Classify by range arithmetic (verified by exhaustive simulation): SUB $1C -> NC selects the wide forms $1C/$1D/$1F (CHRGOT_8). Else SUB $F5 -> NC selects the compact single-byte integer tokens, decoded value left in A (CHRGOT_5; $11..$1A -> 0..9, $1B -> 10). Else CP $FE detects the $0F token (1-byte int 10-255): read the value byte from (HL), INC HL, fall into CHRGOT_5. All remaining values ($0B-$0E) take CHRGOT_7 to read a 2-byte word.
; ----------------------------------------------------------------------
CHRGOT_4:
        ; preserve the token byte (and flags) to hand back to the caller after staging
        PUSH AF
        INC HL
        ; record which constant token this is, for the FAC-materialize step and the LIST/GOTO/IF discriminators
        LD (CONST_TOKEN),A
        ; tokens >= $1C ($1C 2-byte int, $1D single, $1F double) are the wide multi-byte forms -> CHRGOT_8
        SUB $1C
        JR NC,CHRGOT_8
        ; after the SUB $1C, NC here selects the compact integer tokens $11-$1B mapping to value 0-10 in A -> CHRGOT_5
        SUB $F5
        JR NC,CHRGOT_5
        ; the $0F token (1-byte int 10-255): the value byte follows inline in the text
        CP $FE
        JR NZ,CHRGOT_7
        ; fetch the inline 1-byte integer value
        LD A,(HL)
        INC HL
; ----------------------------------------------------------------------
; CHRGOT_5 -- stage a 1-byte integer constant value held in A (entry for the compact / $0F int tokens).
;   In:        A = the 8-bit integer value (0-255); HL -> the byte just past the constant in the text.
;   Out:       CHRGOT_CONST_TXTPTR = HL (post-constant pointer); H cleared to $00, then falls into CHRGOT_6 to set L=value and mark VALTYP=integer.
;   Clobbers:  H, CHRGOT_CONST_TXTPTR.
;   Algorithm: Save the continuation text pointer, zero the high byte (H=$00) so the byte in A becomes the low half of a 16-bit integer, and fall into CHRGOT_6 which sets L=A and records the value/type. Common tail for the $11-$1B compact integers and the $0F one-byte integer.
; ----------------------------------------------------------------------
CHRGOT_5:
        ; save where scanning resumes after this constant
        LD (CONST_TEXT_RESUME),HL
        ; zero-extend the 8-bit value to 16 bits (low byte set in CHRGOT_6)
        LD H,$00
; ----------------------------------------------------------------------
; CHRGOT_6 -- finalize a 16-bit integer constant: store the value, mark VALTYP=integer, return the token to the caller.
;   In:        H = high byte (already set), A = low byte; the original token is on the stack (PUSHed at CHRGOT_4).
;   Out:       CHRGOT_CONST_VALUE_CELL = HL (the 16-bit value); CHRGOT_CONST_VALTYP = $02 (VT_INT); HL = CHRGOT_11; A = token (POPped), carry CLEAR; RET to caller.
;   Clobbers:  A, L, HL, flags, CHRGOT_CONST_VALUE_CELL, CHRGOT_CONST_VALTYP.
;   Algorithm: Set L = A to complete the 16-bit value in HL, store it in CHRGOT_CONST_VALUE_CELL, and record VALTYP=2 (integer) in CHRGOT_CONST_VALTYP. Load HL=CHRGOT_11, POP the token back into A, OR A to clear carry (caller sees 'not a digit'), and RET. Shared tail for all integer-valued embedded tokens decoded as compact / 2-byte ints. UNKNOWN: the HL=CHRGOT_11 handoff is not consumed by the current callers (FRMEVL and LIST jump to CHRGOT_CONST_VALUE directly), so its original purpose is unclear.
; ----------------------------------------------------------------------
CHRGOT_6:
        ; combine low byte (A) with high byte (H) to form the 16-bit value
        LD L,A
        LD (CONST_VALUE),HL
        ; mark the staged constant as integer (VT_INT, 2-byte width)
        LD A,$02
        LD (CONST_VALTYP),A
        ; load the CHRGOT_11 continuation address (handoff unused by current callers)
        LD HL,CHRGOT_11
        POP AF
        ; clear carry so the caller does not mistake the token for a digit; A = the token byte
        OR A
        RET
; ----------------------------------------------------------------------
; CHRGOT_7 -- decode a 2-byte embedded constant ($0B-$0E) into a 16-bit integer value.
;   In:        HL -> the first of the two value bytes (CHRGOT_4 already advanced past the token); token in CHRGOT_CONST_TOKEN.
;   Out:       CHRGOT_CONST_TXTPTR = pointer just past the 2-byte value; A = low byte, H = high byte; falls into CHRGOT_6 to store the value and mark VALTYP=integer.
;   Clobbers:  A, H, HL, CHRGOT_CONST_TXTPTR.
;   Algorithm: Read the low byte into A; INC HL twice to position just past the 2-byte field and save that as CHRGOT_CONST_TXTPTR; DEC HL back to the high byte and load it into H. Falling into CHRGOT_6 (LD L,A) assembles HL = the little-endian 16-bit word and stages it as an integer. Path for the four 2-byte tokens: $0B = &O OCTAL radix constant, $0C = &H HEX radix constant, $0D = cached resolved line-pointer, $0E = 2-byte line-number constant.
; ----------------------------------------------------------------------
CHRGOT_7:
        ; read the low byte of the 16-bit operand
        LD A,(HL)
        INC HL
        INC HL
        ; HL now points just past both value bytes: save the resume position
        LD (CONST_TEXT_RESUME),HL
        DEC HL
        ; read the high byte; CHRGOT_6 supplies the low byte to complete HL
        LD H,(HL)
        JR CHRGOT_6
; ----------------------------------------------------------------------
; CHRGOT_8 -- decode a wide multi-byte numeric constant ($1C 2-byte int / $1D single / $1F double) by block-copying its bytes into the staging cell.
;   In:        A = token-$1C (0 for $1C, 1 for $1D, 3 for $1F); HL -> the first value byte; original token on the stack; DE/BC live (saved and restored here).
;   Out:       CHRGOT_CONST_VALTYP = width in bytes (2 for $1C, 4 for $1D, 8 for $1F); the value bytes copied to CHRGOT_CONST_VALUE_CELL; CHRGOT_CONST_TXTPTR = pointer past the value; HL = CHRGOT_11; A = token (POPped), carry CLEAR; RET. DE and BC are restored (POPped) before return.
;   Clobbers:  A, HL, flags, CHRGOT_CONST_* cells. DE/BC preserved (saved/restored).
;   Algorithm: INC A then RLCA converts the index 0/1/3 into a byte width 2/4/8 and stores it in CHRGOT_CONST_VALTYP. PUSH DE/BC, LD DE,CHRGOT_CONST_VALUE_CELL then EX DE,HL so DE=text source / HL=staging dest, LD B=width, CALL FP_MOVE_LOOP to copy width bytes text->staging. EX DE,HL leaves HL at the byte past the constant; save it to CHRGOT_CONST_TXTPTR, POP BC/DE, POP the token, load HL=CHRGOT_11, clear carry and RET. (Widths 2/4/8 verified by simulation of INC A;RLCA over indices 0/1/3.)
; ----------------------------------------------------------------------
CHRGOT_8:
        ; convert the wide-token index 0/1/3 into the byte width 2/4/8 (INC then RLCA = 2*(index+1))
        INC A
        RLCA
        ; record the constant's width / value-type for the FAC-materialize step
        LD (CONST_VALTYP),A
        PUSH DE
        PUSH BC
        ; destination = the constant staging cell; EX DE,HL then makes DE=text source, HL=dest
        LD DE,CONST_VALUE
        EX DE,HL
        LD B,A
        ; block-copy the constant's raw value bytes from the text into the staging cell
        CALL FP_MOVE_LOOP
        EX DE,HL
        POP BC
        POP DE
        ; save the resume position just past the multi-byte constant
        LD (CONST_TEXT_RESUME),HL
        POP AF
        ; load the CHRGOT_11 continuation address (handoff unused by current callers)
        LD HL,CHRGOT_11
        OR A
        RET
; ----------------------------------------------------------------------
; CHRGOT_9 -- handle the low control bytes ($01-$0A): skip $09/$0A, else fall into the digit classifier.
;   In:        A = control byte (< $0B); HL -> that byte.
;   Out:       For A >= $09 ($09/$0A) loop back to CHRGET to skip it. For A < $09, fall into CHRGOT_10 which returns NC (not a digit) with Z reflecting A.
;   Clobbers:  A, flags; HL on the skip path.
;   Algorithm: CP $09: if the byte is $09 or $0A, JP CHRGET to fetch the next char (these two low controls are skipped like spaces -- [RE] their precise original role is unconfirmed); otherwise ($01-$08) drop into CHRGOT_10 to run it through the digit/zero classifier (which reports not-a-digit).
; ----------------------------------------------------------------------
CHRGOT_9:
        ; $09/$0A are skipped like spaces ([RE] exact original meaning unconfirmed)
        CP $09
        JP NC,CHRGET
; ----------------------------------------------------------------------
; CHRGOT_10 -- the shared digit classifier: set carry iff the char in A is an ASCII digit, set Z iff A is zero.
;   In:        A = char known to be < $3A (':'), reached for $21-$39 from CHRGOT_1 or for low controls via CHRGOT_9.
;   Out:       Carry SET iff A is an ASCII digit '0'-'9' ($30-$39); carry CLEAR otherwise; Z set iff A == 0; A unchanged.
;   Clobbers:  flags only (A preserved by the INC A/DEC A pair).
;   Algorithm: CP $30 sets carry when A < '0'; CCF inverts it so carry is set when A >= '0'. Because the entry guarantees A < ':' , 'A >= $30' is exactly the digit range $30-$39, so carry now means 'is a digit'. INC A then DEC A restores A while re-deriving Z (Z iff A==0) without disturbing carry. This is the carry=digit contract every CHRGET/CHRGOT caller relies on.
; ----------------------------------------------------------------------
CHRGOT_10:
        ; compare against '0'; combined with the <':' entry this isolates the digit range
        CP $30
        ; invert so carry SET == 'char is a digit 0-9'
        CCF
        ; INC/DEC pair restores A and sets Z iff A==0, leaving carry intact
        INC A
        DEC A
        RET
; ----------------------------------------------------------------------
; CHRGOT_11 / CHRGOT_CONST_VALUE -- materialize the staged embedded constant into the floating-point accumulator (FAC) and resume scanning.
;   In:        The CHRGOT_CONST_* cells hold the decoded constant (CHRGOT_CONST_TOKEN, CHRGOT_CONST_VALTYP, CHRGOT_CONST_VALUE_CELL/_HI).
;   Out:       The constant is loaded into the FAC (and VALTYP set for the wide forms); control resumes at CHRGOT_3 (reload CHRGOT_CONST_TXTPTR and re-scan).
;   Clobbers:  A, DE, HL, FAC, VALTYP.
;   Algorithm: Read CHRGOT_CONST_TOKEN. Tokens $0D and $0E take the INT_TO_SNG path: $0D (the cached resolved line-pointer) DEREFERENCES the cached pointer in CHRGOT_CONST_VALUE_CELL (INC HL x3 then load the 2-byte line number) before INT_TO_SNG; $0E uses the staged 16-bit line number directly. All other tokens ($0B,$0C and >= $0F) go to CHRGOT_CONST_VALUE_2, which copies CHRGOT_CONST_VALTYP into the global VALTYP and either moves the single bytes into the FAC cells $0CB1/$0CB3 (VALTYP != 8) or runs the typed double move via FP_ARG_SETUP1 (VALTYP == 8). Then JP CHRGOT_3 to continue scanning. This is the consumer half that FRMEVL_EVAL_OPERAND (CP $20 / JP C,CHRGOT_CONST_VALUE) and the LIST emitter reach directly. UNKNOWN: the leading LD E,$10 at CHRGOT_11 is not consumed before E is reloaded (vestigial), and the HL=CHRGOT_11 handoff from the decode is never used by the current callers.
; ----------------------------------------------------------------------
CHRGOT_11:
        LD E,$10
; ----------------------------------------------------------------------
; CHRGOT_CONST_VALUE -- materialize a scanner-staged embedded numeric-constant token into the FAC.
;   In:        CONST_TOKEN ($0B19) = the constant-form token the scanner last saw ($0B-$1F, excluding $10/$1E); CONST_VALUE ($0B1B)/CONST_VALUE_HI ($0B1D) = the staged value bytes (or, for token $0D, a -1-biased pointer to the located BASLINE node); CONST_VALTYP ($0B1A) = the value width (VT_INT/VT_SNG/VT_DBL), consumed only on the binary-copy path.
;   Out:       FAC ($0CB1) holds the constant; VALTYP ($0B14) set to its type; character scan resumed at CHRGOT_3 (which reloads CONST_TEXT_RESUME, the text pointer just past the constant).
;   Clobbers:  A, HL, DE, VALTYP, FAC cells.
;   Algorithm: Branch on CONST_TOKEN. Tokens $0D/$0E denote a line number that must become a float: float the 16-bit value through INT_TO_SNG (CHRGOT_CONST_VALUE_1). Token $0E carries the line number directly in CONST_VALUE; token $0D carries the runtime-resolved line-link cache pointer, so the line number is fetched from the located node's BASLINE.LINENUM. All other tokens ($0B octal, $0C hex, $0F/$11-$1A/$1C int, $1D single, $1F double) already hold the value in final binary form and go to CHRGOT_CONST_VALUE_2 to copy the FAC bytes by width. Called by FRMEVL_EVAL_OPERAND ($3BF6, via 'JP C,CHRGOT_CONST_VALUE' at $3C07) to evaluate an in-expression constant, and by the LIST detokenizer (IS_ALNUM_CHAR_1, 'CALL CHRGOT_CONST_VALUE' at $41F3) to recover a constant's value for printing.
; ----------------------------------------------------------------------
CHRGOT_CONST_VALUE:
        ; select the materialize path by the staged constant-form token
        LD A,(CONST_TOKEN)
        CP $0F
        ; tokens >= $0F ($0F/$11-$1A int, $1C int, $1D single, $1F double): value is already in final binary form -> copy it into the FAC
        JR NC,CHRGOT_CONST_VALUE_2
        CP $0D
        ; tokens < $0D ($0B octal &O, $0C hex &H): a 2-byte integer literal -> also copy it into the FAC; only $0D/$0E fall through
        JR C,CHRGOT_CONST_VALUE_2
        ; $0D/$0E line-number form: load the staged value (for $0E the line number itself; for $0D the runtime-cached, -1-biased pointer to the located line node)
        LD HL,(CONST_VALUE)
        ; token $0E (NZ from the CP $0D): line number is already in HL, go float it directly
        JR NZ,CHRGOT_CONST_VALUE_1
        ; token $0D (cached line-link, pointer = node_base - 1): step +3 to reach BASLINE.LINENUM (struct offset +2 after undoing the -1 bias) and read the line number into HL
        INC HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
; ----------------------------------------------------------------------
; CHRGOT_CONST_VALUE_1 -- float a 16-bit line number into the FAC as single precision, then resume scanning.
;   In:        HL = the 16-bit line number to materialize (from token $0E directly, or token $0D via the BASLINE.LINENUM fetch).
;   Out:       FAC holds the value as a single-precision float; VALTYP set to VT_SNG ($04) by INT_TO_SNG; control returns to the char scanner at CHRGOT_3.
;   Clobbers:  A, HL, DE, FAC cells, VALTYP.
;   Algorithm: Call INT_TO_SNG to convert the signed 16-bit integer in HL to a single-precision FAC value (INT_TO_SNG sets VALTYP=VT_SNG via SET_TYPE_DOUBLE_1+1 = LD A,$04), then JP CHRGOT_3 to reload the post-constant text pointer and continue the scan. Line numbers appearing in an expression are always promoted to a float here.
; ----------------------------------------------------------------------
CHRGOT_CONST_VALUE_1:
        ; promote the line number to a single-precision float in the FAC (line numbers are evaluated as floats; INT_TO_SNG sets VALTYP=VT_SNG)
        CALL INT_TO_SNG
        ; resume the character scan just past the consumed constant
        JP CHRGOT_3
; ----------------------------------------------------------------------
; CHRGOT_CONST_VALUE_2 -- copy an already-binary integer/single constant from the staging cells into the FAC, then resume scanning.
;   In:        CONST_VALTYP ($0B1A) = the value width (VT_INT=2 for $0B/$0C/$0F/$11-$1A/$1C, VT_SNG=4 for $1D, VT_DBL=8 for $1F); CONST_VALUE ($0B1B)/CONST_VALUE_HI ($0B1D) = the staged value bytes.
;   Out:       VALTYP ($0B14) set from CONST_VALTYP; for int/single the value words are stored into FAC ($0CB1) and FAC+2 ($0CB3); double precision is diverted to CHRGOT_CONST_VALUE_3; control returns to the scanner at CHRGOT_3.
;   Clobbers:  A, HL, VALTYP, FAC cells.
;   Algorithm: Set VALTYP from the staged width. If the width is VT_DBL, hand off to CHRGOT_CONST_VALUE_3 (the 8-byte path). Otherwise copy the staged value as two 16-bit words: CONST_VALUE -> FAC and CONST_VALUE_HI -> FAC+2. This covers both the 2-byte integer (where the upper word written to FAC+2 is stale/irrelevant, since VALTYP=int) and the 4-byte single (where FAC+2 receives the sign byte + exponent). Then JP CHRGOT_3 to continue the scan.
; ----------------------------------------------------------------------
CHRGOT_CONST_VALUE_2:
        ; publish the constant's value type (width) into VALTYP for the evaluator
        LD A,(CONST_VALTYP)
        LD (VALTYP),A
        CP VT_DBL
        ; double precision (VALTYP=VT_DBL) needs the full 8-byte move -> divert to the FP_ARG_SETUP1 path
        JR Z,CHRGOT_CONST_VALUE_3
        ; copy the staged value into the FAC: low word to FAC, high word to FAC+2 (handles both 2-byte int and 4-byte single)
        LD HL,(CONST_VALUE)
        LD (FAC),HL
        LD HL,(CONST_VALUE_HI)
        LD (FACHI),HL
        JP CHRGOT_3
; ----------------------------------------------------------------------
; CHRGOT_CONST_VALUE_3 -- materialize a staged double-precision constant into the FAC, then resume scanning.
;   In:        CONST_VALUE ($0B1B) = the base of the 8-byte double-precision value staged by the scanner; VALTYP already set to VT_DBL by CHRGOT_CONST_VALUE_2.
;   Out:       FAC double field populated from the staged bytes via FP_ARG_SETUP1; control returns to the scanner at CHRGOT_3.
;   Clobbers:  A, HL, DE, BC, FAC cells.
;   Algorithm: Point HL at CONST_VALUE (the move SOURCE) and call FP_ARG_SETUP1, the standard FP operand-setup helper that type-checks (FRMEVL_TEST_TYPE picks the FAC double field $0CAD for VALTYP>=8) and returns into the typed move routine (FP_MOVE4_1) to copy the staged operand into the FAC's working field. Then JP CHRGOT_3 to continue scanning past the constant. This is the 8-byte counterpart of the 2/4-byte copy in CHRGOT_CONST_VALUE_2.
; ----------------------------------------------------------------------
CHRGOT_CONST_VALUE_3:
        ; point at the staged 8-byte double value as the FP move source
        LD HL,CONST_VALUE
        ; type-checked, width-driven move of the double-precision operand into the FAC double field
        CALL FP_ARG_SETUP1
        JP CHRGOT_3
; [RE] DEFSTR statement handler (token $A9): declare a default-string letter range. DEFINT/DEFSNG/DEFDBL ($AA-$AC) enter a few bytes later with a different type code.
STMT_DEFSTR:
        LD E,$03
; [RE] Dual-entry type-code skip. DEFSTR (token $A9) enters at STMT_DEFSTR ($3484, LD E,$03); the $01 (LD BC,nn) opcodes act as 2-byte skips over each following LD E,nn. DEFINT (token $AA) is dispatched to STMT_DEFSTR_1+1 ($3487), which decodes 1E 02 as LD E,$02 (type code 2). All four entries converge at STMT_DEFSTR_4 ($348F). The DEFW is written +1 so it relocates.
STMT_DEFSTR_1:
        LD BC,$021E
; [RE] DEFSNG entry of the DEFxxx type-code skip chain. Token $AB dispatches to STMT_DEFSTR_2+1 ($348A) which decodes 1E 04 as LD E,$04 (single-precision code), then the $01 (LD BC) at $348C skips the next LD E. Joins the shared scanner at STMT_DEFSTR_4 ($348F).
STMT_DEFSTR_2:
        LD BC,$041E
; [RE] DEFDBL entry of the DEFxxx skip chain. Token $AC dispatches to STMT_DEFSTR_3+1 ($348D) which decodes 1E 08 as LD E,$08 (double-precision code), then falls into the shared CALL IS_LETTER at STMT_DEFSTR_4 ($348F). The four DEFxxx variants (string/int/sng/dbl) differ only by which LD E,nn they land on.
STMT_DEFSTR_3:
        LD BC,$081E
STMT_DEFSTR_4:
        CALL IS_LETTER
        LD BC,RAISE_SYNTAX_ERROR
        PUSH BC
        RET C
        SUB $41
        LD C,A
        LD B,A
        CALL CHRGET
        CP TOK_MINUS
        JR NZ,STMT_DEFSTR_5
        CALL CHRGET
        CALL IS_LETTER
        RET C
        SUB $41
        LD B,A
        CALL CHRGET
STMT_DEFSTR_5:
        LD A,B
        SUB C
        RET C
        INC A
        EX (SP),HL
        LD HL,DEFTYPE_TBL
        LD B,$00
        ADD HL,BC
STMT_DEFSTR_6:
        LD (HL),E
        INC HL
        DEC A
        JR NZ,STMT_DEFSTR_6
        POP HL
        LD A,(HL)
        CP $2C
        RET NZ
        CALL CHRGET
        JR STMT_DEFSTR_4
; [RE] CHRGET then GETINT-positive: advances the text pointer, evaluates an expr to a signed 16-bit int (via GETINT_POSITIVE); used where a leading char must be skipped first (e.g. WIDTH/coord parsers at $60DD/$60F5/$7F41/$7F7F)
GETINT_CHRGET_POS:
        CALL CHRGET
; [RE] GETINT requiring a non-negative result: CALL GETINT; RET P if the high byte (D) is sign-positive (0..$7FFF), else fall into GETINT_POSITIVE_1 which loads E=$05 and JP RAISE_ERROR -> 'Illegal function call' (FC). Widely used by graphics/coord and array parsers
GETINT_POSITIVE:
        CALL GETINT
        RET P
; [RE] 'Illegal function call' (FC, error $05) trap: LD E,$05; JP RAISE_ERROR. Common target of the range/argument guards throughout the interpreter.
ERROR_FC:
        LD E,ERR_ILLEGAL_FUNCTION_CALL
        JP RAISE_ERROR
; [RE] LINGET entry handling the '.' shortcut: if current char is '.' ($2E) substitute the current line number from $0B62 and CHRGET past it; otherwise fall into LINGET to parse an explicit decimal line number into DE.
LINGET_DOT:
        LD A,(HL)
        CP $2E
        EX DE,HL
        LD HL,(ERRLIN)
        EX DE,HL
        JP Z,CHRGET
; LINGET: DEC HL then parse a decimal line number from the text at (HL) into DE (range-checked); standard MS BASIC line-number reader used by GOTO/GOSUB/ON/RESUME/THEN.
LINGET:
        DEC HL
; LINGET entry without the leading DEC HL: CHRGET the first char then parse the decimal line number into DE (LINGET re-entry used by ON-GOTO list scanning).
LINGET_NEXT:
        CALL CHRGET
        CP $0E
        JP Z,LINGET_TOKLINE
        CP $0D
; [RE] LINGET digit-accumulation loop: read ASCII digits, DE = DE*10 + digit (via the *10 sequence and $1998 overflow guard at CMP_HL_DE) until a non-digit; returns the parsed line number in DE.
LINGET_TOKLINE:
        EX DE,HL
        LD HL,(CONST_VALUE)
        EX DE,HL
        JP Z,CHRGET
        DEC HL
        LD DE,$0000
LINGET_TOKLINE_1:
        CALL CHRGET
        RET NC
        PUSH HL
        PUSH AF
        LD HL,$1998
        CALL CMP_HL_DE
        JR C,LINGET_TOKLINE_2
        LD H,D
        LD L,E
        ADD HL,DE
        ADD HL,HL
        ADD HL,DE
        ADD HL,HL
        POP AF
        SUB $30
        LD E,A
        LD D,$00
        ADD HL,DE
        EX DE,HL
        POP HL
        JR LINGET_TOKLINE_1
LINGET_TOKLINE_2:
        POP AF
        POP HL
        RET
; [RE] RUN statement handler (token $8A): clears variables and begins execution at the start (or a given line).
STMT_RUN:
        JP Z,CLEAR_RESET_DATAPTR
        CP $0E
        JR Z,STMT_RUN_1
        CP $0D
        JP NZ,LOAD_PROGRAM
STMT_RUN_1:
        CALL CLEAR_RESET_STORAGE
        LD BC,STMT_FOR_7
        JR STMT_GOSUB_1
; [RE] GOSUB statement handler (token $8D): pushes a return frame then transfers like GOTO.
STMT_GOSUB:
        LD C,$03
        CALL CHECK_STACK_ROOM
        CALL LINGET
        POP BC
        PUSH HL
        PUSH HL
        LD HL,(SAVTXT)
        EX (SP),HL
        LD A,$8D
        PUSH AF
        INC SP
        PUSH BC
        JP STMT_GOTO_1
STMT_GOSUB_1:
        PUSH BC
; [RE] GOTO statement handler (token $89): parses a line number, FNDLIN search, sets the text pointer.
STMT_GOTO:
        CALL LINGET
STMT_GOTO_1:
        LD A,(CONST_TOKEN)
        CP $0D
        EX DE,HL
        RET Z
        EX DE,HL
        PUSH HL
        LD HL,(CONST_TEXT_RESUME)
        EX (SP),HL
        CALL STMT_DATA+2
        INC HL
        PUSH HL
        LD HL,(SAVTXT)
        CALL CMP_HL_DE
        POP HL
        CALL C,FNDLIN_LOOP
        CALL NC,FNDLIN
        JR NC,ERROR_UL
        DEC BC
        LD A,$0D
        LD (L_0B56),A
        POP HL
        CALL RENUM_STORE_LINEREF
        LD H,B
        LD L,C
        RET
; [RE] 'Undefined line number' (error $08) trap: LD E,$08; JP RAISE_ERROR. Reached when FNDLIN cannot locate a target line (GOTO/GOSUB/ON/RESUME).
ERROR_UL:
        LD E,ERR_UNDEFINED_LINE_NUMBER
        JP RAISE_ERROR
; [RE] POP statement handler (token $AE): discard the top GOSUB return frame.
STMT_POP:
        LD (OPEN_RESUME_TEXT_PTR),HL
        LD D,$FF
        CALL STKFRAME_SCAN_INIT
        LD SP,HL
        LD (SAVSTK),HL
        CP $8D
        JR NZ,STMT_RETURN_1
        LD HL,$0004
        ADD HL,SP
        LD (SAVSTK),HL
        LD SP,HL
        LD HL,(OPEN_RESUME_TEXT_PTR)
        JP STMT_FOR_7
; [RE] RETURN statement handler (token $8E): pops the GOSUB return frame and resumes.
STMT_RETURN:
        RET NZ
        LD D,$FF
        CALL STKFRAME_SCAN_INIT
        LD SP,HL
        LD (SAVSTK),HL
        CP $8D
STMT_RETURN_1:
        LD E,ERR_RETURN_WITHOUT_GOSUB
        JP NZ,RAISE_ERROR
        POP HL
        LD (SAVTXT),HL
        LD HL,STMT_FOR_7
        EX (SP),HL
        LD A,$E1
; [RE] DATA statement handler (token $84): no-op at run time (scanned/skipped). COMMON (token $B3) also dispatches to this same entry. Dual-entry skip idiom: the $01 (LD BC,nn) opcode doubles as a 2-byte skip. Entered here, the full LD BC,$0E3A executes; entered at STMT_DATA+2 ($35B6, called from ERROR_PRINT_SETUP) the embedded bytes start LD C,$00 ($0E $00) instead. Two paths share these bytes; the literal CALL $35B6 is written STMT_DATA+2 so it relocates.
; [RE] DATA/COMMON statement scanner with a dual-entry terminator skip. Entered at STMT_DATA ($35B4): LD BC,$0E3A loads C=':' so the scan stops at a colon (DATA item separator) -- token $84/$B3. Entered at STMT_DATA+2 ($35B6): the $01 opcode is sidestepped, 0E 00 decodes as LD C,$00 so B ends $00 and the scan runs to end-of-line only (REM-class, and the generic skip used by $0DF4/$3555). The CALL/DEFW targets are written +2 so they relocate.
STMT_DATA:
        LD BC,$0E3A
        NOP
        LD B,$00
STMT_DATA_1:
        LD A,C
        LD C,B
        LD B,A
STMT_DATA_2:
        DEC HL
STMT_DATA_3:
        CALL CHRGET
        OR A
        RET Z
        CP B
        RET Z
        INC HL
        CP $22
        JR Z,STMT_DATA_1
        INC A
        JR Z,STMT_DATA_3
        SUB $8C
        JR NZ,STMT_DATA_2
        CP B
        ADC A,D
        LD D,A
        JR STMT_DATA_2
STMT_DATA_4:
        POP AF
        ADD A,$03
        JR STMT_LET_1
; [RE] LET / implicit-assignment handler (token $88): evaluates RHS (CALL $5F35) and stores into the target variable.
STMT_LET:
        CALL PTRGET_1+1
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        EX DE,HL
        LD (OPEN_RESUME_TEXT_PTR),HL
        EX DE,HL
        PUSH DE
        LD A,(VALTYP)
        PUSH AF
        CALL FRMEVL_NOPAREN
        POP AF
STMT_LET_1:
        EX (SP),HL
STMT_LET_2:
        LD B,A
        LD A,(VALTYP)
        CP B
        LD A,B
        JR Z,STMT_LET_4
        CALL FRMEVL_APPLY_OP
STMT_LET_3:
        LD A,(VALTYP)
STMT_LET_4:
        LD DE,FAC
        CP $05
        JR C,STMT_LET_5
        LD DE,L_0CAD
STMT_LET_5:
        PUSH HL
        CP VT_STR
        JR NZ,STMT_LET_8
        LD HL,(FAC)
        PUSH HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD HL,(TXTTAB)
        CALL CMP_HL_DE
        JR NC,STMT_LET_6+1
        LD HL,(STREND)
        CALL CMP_HL_DE
        POP DE
        JR NC,STMT_LET_7
        LD HL,DSCTMP
        CALL CMP_HL_DE
        JR NC,STMT_LET_7
; [RE] Stack-balancing entry skip. STMT_LET_6 ($362F) is entered by fall-through and runs LD A,$D1 (A=flag for FREE_TOP_TEMP_DESCR). The first range compare jumps JR NC,STMT_LET_6+1 ($3630), where the $D1 immediate decodes as POP DE, discarding the pointer PUSHed at $3611 (the POP DE at $3624 was skipped on that branch) before the shared CALL FREE_TOP_TEMP_DESCR. (MBASIC labels the same site STMT_LET_7+1.)
STMT_LET_6:
        LD A,$D1
        CALL FREE_TOP_TEMP_DESCR
        EX DE,HL
        CALL STR_BUILD_FROM_DESC
STMT_LET_7:
        CALL FREE_TOP_TEMP_DESCR
        EX (SP),HL
STMT_LET_8:
        CALL FP_MOVE_TYPED
        POP DE
        POP HL
        RET
; [RE] ON statement handler (token $95): ON..GOTO/GOSUB/ERROR computed branch (CP $A4 tests for ERROR).
STMT_ON:
        CP $A4
        JR NZ,STMT_ON_2
        CALL CHRGET
        CALL SYNCHR
        DEFB    TOK_GOTO                 ; inline keyword-token arg consumed by the preceding CALL
        CALL LINGET
        LD A,D
        OR E
        JR Z,STMT_ON_1
        CALL FNDLIN_FROM_TEXT
        LD D,B
        LD E,C
        POP HL
        JP NC,ERROR_UL
STMT_ON_1:
        EX DE,HL
        LD (ON_ERROR_LINE),HL
        EX DE,HL
        RET C
        LD A,(ONEFLG)
        OR A
        LD A,E
        RET Z
        LD A,(ERRFLG)
        LD E,A
        JP ERROR_PRINT_SETUP
STMT_ON_2:
        CALL GETBYT
        LD A,(HL)
        LD B,A
        CP $8D
        JR Z,STMT_ON_3
        CALL SYNCHR
        DEFB    TOK_GOTO                 ; inline keyword-token arg consumed by the preceding CALL
        DEC HL
STMT_ON_3:
        LD C,E
STMT_ON_4:
        DEC C
        LD A,B
        JP Z,NEWSTT_DISPATCH
        CALL LINGET_NEXT
        CP $2C
        RET NZ
        JR STMT_ON_4
; [RE] RESUME statement handler (token $A5): return from an ON ERROR handler (RESUME/RESUME NEXT/RESUME line).
STMT_RESUME:
        LD DE,ONEFLG
        LD A,(DE)
        OR A
        JP Z,RAISE_RESUME_WITHOUT_ERROR
        INC A
        LD (ERRFLG),A
        LD (DE),A
        LD A,(HL)
        CP $83
        JR Z,STMT_RESUME_1
        CALL LINGET
        RET NZ
        LD A,D
        OR E
        JP NZ,STMT_GOTO_1
        INC A
        JR STMT_RESUME_2
STMT_RESUME_1:
        CALL CHRGET
        RET NZ
STMT_RESUME_2:
        LD HL,(RESUME_TXTPTR)
        EX DE,HL
        LD HL,(ERR_SAVTXT)
        LD (SAVTXT),HL
        EX DE,HL
        RET NZ
        LD A,(HL)
        OR A
        JR NZ,STMT_RESUME_3
        INC HL
        INC HL
        INC HL
        INC HL
STMT_RESUME_3:
        INC HL
        JP STMT_DATA
; [RE] ERROR statement handler (token $A4): force the given error code through the ERROR handler.
STMT_ERROR:
        CALL GETBYT
        RET NZ
        OR A
        JP Z,ERROR_FC
        JP RAISE_ERROR
; [RE] Parse an optional line-number range (default span $000A) via LINGET_DOT/LINGET, store the start/end pointers into the continue/trace cells $0B5A/$0B57/$0B58, then JP $0E3E to re-enter the NEWSTT main loop at that line.
SCAN_LINE_RANGE_RESUME:
        LD DE,$000A
        PUSH DE
        JR Z,SCAN_LINE_RANGE_RESUME_1
        CALL LINGET_DOT
        EX DE,HL
        EX (SP),HL
        JR Z,SCAN_LINE_RANGE_RESUME_2
        EX DE,HL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        EX DE,HL
        LD HL,(AUTINC)
        EX DE,HL
        JR Z,SCAN_LINE_RANGE_RESUME_1
        CALL LINGET
        JP NZ,RAISE_SYNTAX_ERROR
SCAN_LINE_RANGE_RESUME_1:
        EX DE,HL
SCAN_LINE_RANGE_RESUME_2:
        LD A,H
        OR L
        JP Z,ERROR_FC
        LD (AUTINC),HL
        LD (AUTFLG),A
        POP HL
        LD (AUTLIN),HL
        POP BC
        JP DIRECT_LINE_DISPATCH
; [RE] IF statement handler: evaluate the condition via FRMEVL, skip an optional ',' and the THEN/GOTO token; if true, a following line-number token ($0E) means GOTO (JP STMT_GOTO) else execute the THEN clause via NEWSTT_DISPATCH; if false, scan forward over the matching ELSE ($9E) depth (STMT_IF_4) to the alternate/next line.
STMT_IF:
        CALL FRMEVL_NOPAREN
        LD A,(HL)
        CP $2C
        CALL Z,CHRGET
        CP TOK_GOTO
        JR Z,STMT_IF_1
        CALL SYNCHR
        DEFB    TOK_THEN                 ; inline keyword-token arg consumed by the preceding CALL
        DEC HL
STMT_IF_1:
        PUSH HL
        CALL FP_TEST_SIGN
        POP HL
        JR Z,STMT_IF_3
STMT_IF_2:
        CALL CHRGET
        RET Z
        CP $0E
        JP Z,STMT_GOTO
        CP $0D
        JP NZ,NEWSTT_DISPATCH
        LD HL,(CONST_VALUE)
        RET
STMT_IF_3:
        LD D,$01
STMT_IF_4:
        CALL STMT_DATA
        OR A
        RET Z
        CALL CHRGET
        CP TOK_ELSE
        JR NZ,STMT_IF_4
        DEC D
        JR NZ,STMT_IF_4
        JR STMT_IF_2
; [RE] LPRINT statement handler (token $9B): PRINT directed to the line printer; falls into the shared PRINT engine.
STMT_LPRINT:
        LD A,$01
        LD (PRTFLG),A
        JP STMT_PRINT_1
; PRINT statement engine (shared by PRINT/LPRINT/PRINT#): walk the print list emitting expressions, honour ',' tab zones and ';' (no-space), TAB($E8)/SPC($DF)/USING($E3) functions, and emit CRLF unless suppressed; column tracking via $0837/$0B11.
STMT_PRINT:
        LD C,$02
        CALL PARSE_FILENUM_HASH
STMT_PRINT_1:
        DEC HL
        CALL CHRGET
        CALL Z,CRLF
STMT_PRINT_2:
        JP Z,PRINT_RESET_STATE
        CP TOK_USING
        JP Z,PRINT_USING
        CP $DF
        JP Z,STMT_PRINT_11
        CP $E3
        JP Z,STMT_PRINT_11
        PUSH HL
        CP $2C
        JR Z,STMT_PRINT_7
        CP $3B
        JP Z,STMT_PRINT_20
        POP BC
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FRMEVL_TEST_TYPE
        JR Z,STMT_PRINT_3
        CALL FOUT_2
        CALL SCAN_STR_LITERAL
        LD (HL),$20
        LD HL,(FAC)
        INC (HL)
STMT_PRINT_3:
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR NZ,STMT_PRINT_6
        LD HL,(FAC)
        LD A,(PRTFLG)
        OR A
        JR Z,STMT_PRINT_4
        LD A,(L_083A)
        LD B,A
        INC A
        JP Z,STMT_PRINT_6
        LD A,(OUTPUT_COLUMN)
        OR A
        JP Z,STMT_PRINT_6
        ADD A,(HL)
        CCF
        JR NC,STMT_PRINT_5
        CP B
        JR STMT_PRINT_5
STMT_PRINT_4:
        LD A,(PRINT_WIDTH)
        LD B,A
        INC A
        JR Z,STMT_PRINT_6
        LD A,(L_0B11)
        OR A
        JR Z,STMT_PRINT_6
        ADD A,(HL)
        CCF
        JR NC,STMT_PRINT_5
        DEC A
        CP B
STMT_PRINT_5:
        CALL NC,CRLF
STMT_PRINT_6:
        CALL STRPRT
        POP HL
        JP STMT_PRINT_1
STMT_PRINT_7:
        LD HL,(PTRFIL)
        LD A,H
        OR L
        LD BC,FCB.BUF_REM
        ADD HL,BC
        LD A,(HL)
        JR NZ,STMT_PRINT_10
        LD A,(PRTFLG)
        OR A
        JR Z,STMT_PRINT_8
        LD A,(L_0839)
        LD B,A
        INC A
        LD A,(OUTPUT_COLUMN)
        JR Z,STMT_PRINT_10
        CP B
        JP STMT_PRINT_9
STMT_PRINT_8:
        LD A,(WIDTH_FILE)
        LD B,A
        LD A,(L_0B11)
        CP $FF
        JR Z,STMT_PRINT_10
        CP B
STMT_PRINT_9:
        CALL NC,CRLF
        JP NC,STMT_PRINT_20
STMT_PRINT_10:
        SUB $0E
        JR NC,STMT_PRINT_10
        CPL
        JP STMT_PRINT_18
STMT_PRINT_11:
        PUSH AF
        CALL CHRGET
        CALL GETINT
        POP AF
        PUSH AF
        CP $E3
        JR Z,STMT_PRINT_12
        DEC DE
STMT_PRINT_12:
        LD A,D
        OR A
        JP P,STMT_PRINT_13
        LD DE,$0000
STMT_PRINT_13:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR NZ,STMT_PRINT_15
        LD A,(PRTFLG)
        OR A
        LD A,(L_083A)
        JR NZ,STMT_PRINT_14
        LD A,(PRINT_WIDTH)
STMT_PRINT_14:
        LD L,A
        INC A
        JR Z,STMT_PRINT_15
        LD H,$00
        CALL INT_DIV_ROUND
        EX DE,HL
STMT_PRINT_15:
        POP HL
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        DEC HL
        POP AF
        SUB $E3
        PUSH HL
        JR Z,STMT_PRINT_17
        LD HL,(PTRFIL)
        LD A,H
        OR L
        LD BC,FCB.BUF_REM
        ADD HL,BC
        LD A,(HL)
        JR NZ,STMT_PRINT_17
        LD A,(PRTFLG)
        OR A
        JP Z,STMT_PRINT_16
        LD A,(OUTPUT_COLUMN)
        JR STMT_PRINT_17
STMT_PRINT_16:
        LD A,(L_0B11)
STMT_PRINT_17:
        CPL
        ADD A,E
        JR C,STMT_PRINT_18
        INC A
        JR Z,STMT_PRINT_20
        CALL CRLF
        LD A,E
        DEC A
        JP M,STMT_PRINT_20
STMT_PRINT_18:
        INC A
        LD B,A
        LD A,$20
STMT_PRINT_19:
        CALL OUTCHR
        DJNZ STMT_PRINT_19
STMT_PRINT_20:
        POP HL
        CALL CHRGET
        JP STMT_PRINT_2
; [RE] PRINT epilogue/reset: clear the LPRINT-direction flag $0838 and the file/device pointer $0840 back to console defaults at the end of a PRINT statement.
PRINT_RESET_STATE:
        XOR A                            ; [RE] PRINT epilogue/reset: clear the printer-output selector PRTFLG ($0838) and the current-file pointer PTRFIL ($0840) back to console defaults (0) at the end of a PRINT statement.
        LD (PRTFLG),A
        PUSH HL
        LD H,A
        LD L,A
        LD (PTRFIL),HL
        POP HL
        RET
; [RE] LINE statement handler (token $AD): LINE INPUT (read a whole console line into a string).
STMT_LINE:
        CALL SYNCHR
        DEFB    TOK_INPUT                ; inline keyword-token arg consumed by the preceding CALL
        CP $23
        JP Z,LINE_INPUT_FILE
        CALL INPUT_PROMPT_SEP
        CALL INPUT_PROMPT
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        PUSH DE
        PUSH HL
        CALL INLIN
        POP DE
        POP BC
        JP C,STMT_END_2+1
        PUSH BC
        PUSH DE
        LD B,$00
        CALL SCAN_STR_TERM
        POP HL
        LD A,$03
        JP STMT_LET_1
; INPUT error literal "?Redo from start" + CR/LF; STROUT'd by the INPUT re-prompt path (STMT_LINE_2) when the user's typed reply does not parse. The INPUT value-parse code follows the $00 terminator.
MSG_REDO_FROM_START:
        DEFB    "?Redo from start"       ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n\0"
STMT_LINE_1:
        INC HL
        LD A,(HL)
        OR A
        JP Z,RAISE_SYNTAX_ERROR
        CP $22
        JR NZ,STMT_LINE_1
        JP INPUT_PROMPT_8
STMT_LINE_2:
        POP HL
        POP HL
        JP STMT_LINE_4
STMT_LINE_3:
        LD A,(L_0B53)
        OR A
        JP NZ,CONT_RESUME_RESTORE
STMT_LINE_4:
        POP BC
        LD HL,MSG_REDO_FROM_START
        CALL STROUT
        LD HL,(OLDTXT)
        RET
STMT_LINE_5:
        CALL GET_FILENUM_PREFIX_C1
        PUSH HL
        LD HL,L_0A0D
        JP INPUT_PROMPT_12
; [RE] INPUT statement handler (token $85): prompt + read console line, parse values into the variable list.
STMT_INPUT:
        CP $23
        JP Z,STMT_LINE_5
        CALL INPUT_PROMPT_SEP
        LD BC,INPUT_EMIT_PROMPT
        PUSH BC
; [RE] INPUT prompt parser: if the next token is '"' read the quoted prompt string and emit it; the following ';' vs ',' sets the suppress-'?'-mark flag ($0C94) and trailing-comma flag ($083F); shared prompt setup before reading the console line.
INPUT_PROMPT:
        CP $22
        LD A,$00
        LD (CTRL_O_SUPPRESS),A
        LD A,$FF
        LD (L_0C94),A
        RET NZ
        CALL SCAN_STR_QUOTE
        LD A,(HL)
        CP $2C
        JR NZ,INPUT_PROMPT_2
        XOR A
        LD (L_0C94),A
INPUT_PROMPT_1:
        CALL CHRGET
        JR INPUT_PROMPT_3
INPUT_PROMPT_2:
        CALL SYNCHR
        DEFB    ';'                      ; inline char arg consumed by the preceding CALL
INPUT_PROMPT_3:
        PUSH HL
        CALL STRPRT
        POP HL
        RET
; [RE] INPUT continuation: emits the '? ' prompt via OUTCHR, reads the console line (INLIN), and on empty/abort branches to STMT_END; falls through to the value-parse loop $394D.
INPUT_EMIT_PROMPT:
        PUSH HL
        LD A,(L_0C94)
        OR A
        JR Z,INPUT_PROMPT_5
        LD A,$3F
        CALL OUTCHR
        LD A,$20
        CALL OUTCHR
INPUT_PROMPT_5:
        CALL INLIN
        POP BC
        JP C,STMT_END_2+1
        PUSH BC
        LD (HL),$2C
        EX DE,HL
        POP HL
        PUSH HL
        PUSH DE
        PUSH DE
        DEC HL
; [RE] INPUT value-parse loop: for each variable, read a field from the typed line (honouring quotes and ',' separators), convert and assign via STMT_LET_2; on mismatch jumps to the '?Redo from start' re-prompt (STMT_LINE_1/2).
INPUT_PARSE_VALUES:
        LD A,$80
        LD (PTRGET_SUBSCRIPT_FLAG),A
        CALL CHRGET
        CALL PTRGET_1+1
        LD A,(HL)
        DEC HL
        CP $28
        JR NZ,INPUT_PROMPT_9
        INC HL
        LD B,$00
INPUT_PROMPT_7:
        INC B
INPUT_PROMPT_8:
        CALL CHRGET
        JP Z,RAISE_SYNTAX_ERROR
        CP $22
        JP Z,STMT_LINE_1
        CP $28
        JR Z,INPUT_PROMPT_7
        CP $29
        JR NZ,INPUT_PROMPT_8
        DJNZ INPUT_PROMPT_8
INPUT_PROMPT_9:
        CALL CHRGET
        JR Z,INPUT_PROMPT_10
        CP $2C
        JP NZ,RAISE_SYNTAX_ERROR
INPUT_PROMPT_10:
        EX (SP),HL
        LD A,(HL)
        CP $2C
        JP NZ,STMT_LINE_2
        LD A,$01
        LD (L_0CB7),A
        CALL STMT_READ_4+1
        LD A,(L_0CB7)
        DEC A
        JP NZ,STMT_LINE_2
        PUSH HL
INPUT_PROMPT_11:
        CALL FRMEVL_TEST_TYPE
        CALL Z,FRESTR
        POP HL
        DEC HL
        CALL CHRGET
        EX (SP),HL
        LD A,(HL)
        CP $2C
        JR Z,INPUT_PARSE_VALUES
        POP HL
        DEC HL
        CALL CHRGET
        OR A
        POP HL
        JP NZ,STMT_LINE_4
INPUT_PROMPT_12:
        LD (HL),$2C
        JR STMT_READ_1+1
; [RE] READ statement handler (token $87): reads the next DATA item into a variable.
STMT_READ:
        PUSH HL
        LD HL,(L_0B75)
; [RE] READ/INPUT source-flag skip. STMT_READ ($39B7) falls into STMT_READ_1 ($39BB OR $AF), forcing A nonzero so $0B53 marks 'READ from program DATA'. The INPUT path jumps JR STMT_READ_1+1 ($39BC) where the $AF byte is XOR A, clearing A so $0B53 marks 'console INPUT'. Both converge at LD ($0B53),A.
STMT_READ_1:
        OR $AF
        LD (L_0B53),A
        EX (SP),HL
        JR STMT_READ_3
STMT_READ_2:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
STMT_READ_3:
        CALL PTRGET_1+1
        EX (SP),HL
        PUSH DE
        LD A,(HL)
        CP $2C
        JR Z,STMT_READ_4
        LD A,(L_0B53)
        OR A
        JP NZ,STMT_READ_11
; [RE] STMT_READ_4 mode-flag skip. Entered at the label ($39D8 OR $AF) the $0C69 flag is set nonzero; entered at STMT_READ_4+1 ($39D9) via CALL at $398D the $AF byte is XOR A, clearing $0C69. The OR immediate operand doubles as the XOR A opcode; both paths share LD ($0C69),A.
STMT_READ_4:
        OR $AF
        LD (L_0C69),A
        EX DE,HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        EX DE,HL
        JP NZ,INPUT_FILE_SCAN
        CALL FRMEVL_TEST_TYPE
        PUSH AF
        JR NZ,STMT_READ_8
        CALL CHRGET
        LD D,A
        LD B,A
        CP $22
        JR Z,STMT_READ_6
        LD A,(L_0B53)
        OR A
        LD D,A
        JR Z,STMT_READ_5
        LD D,$3A
STMT_READ_5:
        LD B,$2C
        DEC HL
STMT_READ_6:
        CALL SCAN_STR_BODY
STMT_READ_7:
        POP AF
        ADD A,$03
        LD C,A
        LD A,(L_0C69)
        OR A
        RET Z
        LD A,C
        EX DE,HL
        LD HL,STMT_READ_9
        EX (SP),HL
        PUSH DE
        JP STMT_LET_2
STMT_READ_8:
        CALL CHRGET
        POP AF
        PUSH AF
        LD BC,STMT_READ_7
        PUSH BC
        JP C,FIN_1+1
        JP FIN
STMT_READ_9:
        DEC HL
        CALL CHRGET
        JR Z,STMT_READ_10
        CP $2C
        JP NZ,STMT_LINE_3
STMT_READ_10:
        EX (SP),HL
        DEC HL
        CALL CHRGET
        JP NZ,STMT_READ_2
        POP DE
        LD A,(L_0B53)
        OR A
        EX DE,HL
        JP NZ,STMT_RESTORE_2
        PUSH DE
        POP HL
        JP PRINT_RESET_STATE
STMT_READ_11:
        CALL STMT_DATA
        OR A
        JR NZ,STMT_READ_12
        INC HL
        LD A,(HL)
        INC HL
        OR (HL)
        LD E,ERR_OUT_OF_DATA
        JP Z,RAISE_ERROR
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (DATA_LINE_TXTPTR),HL
        EX DE,HL
STMT_READ_12:
        CALL CHRGET
        CP $84
        JR NZ,STMT_READ_11
        JP STMT_READ_4
; [RE] Evaluate-expression wrapper: SYNCHR the current char (advance past a required token), RET if at end-of-statement (P flag), else JP into FRMEVL to evaluate the following expression into FAC.
EVAL_EXPR_AFTER_SYNCHR:
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        JP FRMEVL_NOPAREN

; ======================================================================
; EXPRESSION EVALUATOR (FRMEVL) + operator-precedence loop
; ======================================================================
; ----------------------------------------------------------------------
; FRMEVL -- evaluate a parenthesized expression: require '(', evaluate to FAC.
;   In:        HL -> text pointer, positioned just before a '(' token.
;   Out:       FAC ($0CB1) = expression value; VALTYP ($0B14) = its type; HL past the expression.
;   Clobbers:  A, BC, DE, HL, FAC; consumes one stack frame via the operator loop.
;   Algorithm: SYNCHR-assert the next non-blank token is '(' (the inline DEFB '(' is the char
;              argument the preceding CALL SYNCHR consumes; raises Syntax error if absent), then
;              fall through to FRMEVL_NOPAREN to evaluate the sub-expression. SYNCHR-context entry
;              used where a leading parenthesis is mandatory.
; ----------------------------------------------------------------------
FRMEVL:
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
; ----------------------------------------------------------------------
; FRMEVL_NOPAREN -- bare expression-evaluator entry (no leading '(' required).
;   In:        HL -> text pointer at the first operand token.
;   Out:       FAC = expression value; VALTYP set; HL advanced past the expression.
;   Clobbers:  A, BC, DE, HL, FAC.
;   Algorithm: DEC HL so the CHRGET inside FRMEVL_EVAL_OPERAND re-reads the current token (the
;              caller has typically already advanced past it), then fall into FRMEVL_LOWPREC. This
;              is the general 'evaluate the expression at (HL) into FAC' entry used by ~60 callers.
; ----------------------------------------------------------------------
FRMEVL_NOPAREN:
        DEC HL
; ----------------------------------------------------------------------
; FRMEVL_LOWPREC -- start an expression at the lowest operator precedence.
;   In:        HL -> one before the first operand token.
;   Out:       falls into the precedence loop with the pending-operator precedence D = 0.
;   Clobbers:  D (set to 0).
;   Algorithm: Seed the pending-operator precedence D = $00 (lower than every entry in
;              FRMEVL_PREC_TBL) so the first binary operator encountered always binds, then enter
;              FRMEVL_OPLOOP. Recursive entries instead arrive with D = the precedence of the
;              operator currently being applied (set in the OPLOOP_9/_10/ARITHOP apply arms).
; ----------------------------------------------------------------------
FRMEVL_LOWPREC:
        LD D,$00
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP -- operator-precedence loop: parse one operand, then bind operators.
;   In:        D = pending-operator precedence (0 at top level, the operator's prec on recursion);
;              HL -> one before the next operand token.
;   Out:       FAC = value of the sub-expression bound at precedence > D; HL past it. Returns to
;              caller when the next operator's precedence <= D (or the token is not an operator).
;   Clobbers:  A, BC, DE, HL, FAC; L_0CB6.
;   Algorithm: PUSH DE to save the pending precedence D, verify stack headroom (CHECK_STACK_ROOM
;              with C=1 = two bytes of headroom), then evaluate one operand (factor) into the FAC
;              via FRMEVL_EVAL_OPERAND and clear the floating-point sign flag L_0CB6. Then loop:
;              read the next token; if below the relational band ('>'=$EF) return; if a relational
;              token dispatch to FRMEVL_RELOP to gather a comparison mask, else map
;              +/-/*//^/AND/OR/XOR/EQV/IMP/MOD/\ to its precedence in FRMEVL_PREC_TBL. While that
;              precedence > D, push the left operand and recurse to evaluate the right operand at
;              the operator's precedence, then apply the operator.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP:
        PUSH DE
        ; request two bytes of Z-80 stack headroom (CHECK_STACK_ROOM reserves 2*C) before recursing
        LD C,$01
        CALL CHECK_STACK_ROOM
        ; evaluate the next operand/factor into the FAC
        CALL FRMEVL_EVAL_OPERAND
        ; [RE] clear the FP sign flag L_0CB6 (set later by the '^'/numeric-input paths) before scanning operators
        XOR A
        LD (L_0CB6),A
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_1 -- record the current text position as the operator scan point.
;   In:        HL -> the just-evaluated operand's trailing token (the candidate operator).
;   Out:       FRMEVL_TXTPTR_TEMP ($0B69) = HL; falls into FRMEVL_OPLOOP_2.
;   Clobbers:  (FRMEVL_TXTPTR_TEMP).
;   Algorithm: Stash HL so the loop can reload it after a recursive operand evaluation has moved
;              HL on. Re-entered here after the relational-mask collector / recursion returns.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_1:
        LD (FRMEVL_TXTPTR_TEMP),HL
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_2 -- classify the next token as terminator / relational / binary operator.
;   In:        FRMEVL_TXTPTR_TEMP = saved text pointer; top of stack = the pushed pending-precedence
;              frame (DE), popped into BC so B = pending precedence.
;   Out:       returns to caller if the token ends the (sub)expression; else dispatches to the
;              relational collector, the string-concat path, or the precedence test (OPLOOP_3).
;   Clobbers:  A, BC, DE, HL, (L_0B4A).
;   Algorithm: Reload HL from FRMEVL_TXTPTR_TEMP; POP BC so B = pending precedence. Read the
;              operator token A and store its address in L_0B4A. If A < '>' ($EF) it is not an
;              operator -> RET. If A < '+' ($F2) it is a relational ('>','=','<') -> FRMEVL_RELOP.
;              Otherwise E = A-'+' is the binary-operator index (0='+',1='-',2='*',3='/',4='^',
;              5=AND,6=OR,7=XOR,8=EQV,9=IMP,10=MOD,11='\'). Special-case '+' (E=0): if the current
;              FAC value is a string (VALTYP=$03) divert to STR_CONCAT instead of numeric add.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_2:
        LD HL,(FRMEVL_TXTPTR_TEMP)
        ; recover the pushed pending-precedence frame; B = pending-operator precedence for the test below
        POP BC
        LD A,(HL)
        ; remember the address of this operator token (reloaded by FRMEVL_OPLOOP_6 when applying)
        LD (L_0B4A),HL
        ; token below the relational band ($EF) is not a binary operator -> end of (sub)expression
        CP TOK_GT
        RET C
        CP TOK_PLUS
        ; '>','=','<' (tokens $EF-$F1) -> gather the relational comparison mask
        JP C,FRMEVL_RELOP
        ; E = binary-operator index (0='+',1='-',2='*',3='/',4='^',5=AND,...,10=MOD,11='\')
        SUB TOK_PLUS
        LD E,A
        JR NZ,FRMEVL_OPLOOP_3
        LD A,(VALTYP)
        CP VT_STR
        LD A,E
        ; '+' (index 0) applied to a string operand is concatenation, not numeric add
        JP Z,STR_CONCAT
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_3 -- precedence test and recursion setup for a non-relational binary operator.
;   In:        E = operator index (token-'+', 0..11); A still = that index; B = pending precedence;
;              HL = (reloaded) operator address via L_0B4A in the apply arms.
;   Out:       if the operator binds, recurses into FRMEVL_OPLOOP for the right operand; else RET.
;              D = new operator precedence; the chosen apply arm is queued on the stack.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: Reject indices >= 12 ('CP $0C / RET NC') -> not a valid binary operator. Index
;              FRMEVL_PREC_TBL ($79,$79,$7C,$7C,$7F,$50,$46,$3C,$32,$28,$7A,$7B) by E to fetch this
;              operator's precedence into D. If pending precedence B >= D ('CP D / RET NC') the
;              operator does not bind here (left-associative cutoff) -> RET to apply it at an outer
;              level. Otherwise push the pending-precedence frame, push the return address
;              FRMEVL_OPLOOP_2 (so control resumes scanning the next operator), and select the apply
;              arm by precedence value: $7F selects '^' -> power arm FRMEVL_OPLOOP_9; < $51 are the
;              logical ops AND($50)/OR($46)/XOR($3C)/EQV($32)/IMP($28) -> integer-coerce arm
;              FRMEVL_OPLOOP_10; $7A/$7B fold to $7A under AND $FE (MOD=$7A, '\'=$7B) -> the same
;              integer-coerce arm; the rest ($79 '+'/'-', $7C '*'/'/') fall to the float arm OPLOOP_4.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_3:
        ; operator index >= 12 is not a binary operator -> done
        CP $0C
        RET NC
        LD HL,FRMEVL_PREC_TBL
        LD D,$00
        ADD HL,DE
        LD A,B
        ; D = this operator's precedence from FRMEVL_PREC_TBL
        LD D,(HL)
        ; if pending precedence >= new precedence the operator binds outward -> RET to apply it later
        CP D
        RET NC
        PUSH BC
        ; after the right operand is evaluated, resume scanning operators here
        LD BC,FRMEVL_OPLOOP_2
        PUSH BC
        LD A,D
        ; precedence $7F selects '^' (exponentiation) -> power arm
        CP $7F
        JP Z,FRMEVL_OPLOOP_9
        CP $51
        ; precedence < $51 are the logical ops (AND/OR/XOR/EQV/IMP) -> integer-coerce arm
        JP C,FRMEVL_OPLOOP_10
        ; fold $7A (MOD) and $7B ('\') to $7A so both route to the integer-coerce arm
        AND $FE
        CP $7A
        JP Z,FRMEVL_OPLOOP_10
FRMEVL_OPLOOP_4:
        LD HL,FAC
        LD A,(VALTYP)
        SUB VT_STR
        JP Z,RAISE_TYPE_MISMATCH
        OR A
        LD C,(HL)
        INC HL
        LD B,(HL)
        PUSH BC
        JP M,FRMEVL_OPLOOP_5
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        PUSH BC
        JP PO,FRMEVL_OPLOOP_5
        INC HL
        LD HL,L_0CAD
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        PUSH BC
FRMEVL_OPLOOP_5:
        ADD A,$03
        LD C,E
        LD B,A
        PUSH BC
        LD BC,FRMEVL_OPCOMBINE
FRMEVL_OPLOOP_6:
        PUSH BC
        LD HL,(L_0B4A)
        JP FRMEVL_OPLOOP
; ----------------------------------------------------------------------
; FRMEVL_RELOP -- begin gathering a relational comparison from one or more of '>','=','<'.
;   In:        A = first relational token ('>','=','<'); HL -> that token; B = pending precedence.
;   Out:       D = accumulated 3-bit relation mask; falls into the per-token collector loop.
;   Clobbers:  D.
;   Algorithm: Initialize the relation mask D = 0, then fall into FRMEVL_OPLOOP_8 which folds each
;              consecutive relational token into the mask. BASIC allows the three relational tokens
;              combined ('<=','=<','><','<>', etc.); the mask encodes which of greater/equal/less
;              were requested so the comparison kernel can test the right combination.
; ----------------------------------------------------------------------
FRMEVL_RELOP:
        LD D,$00
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_8 -- fold consecutive relational tokens into a 3-bit comparison mask.
;   In:        A = current token; D = mask so far; HL -> current token.
;   Out:       on a non-relational token, falls to FRMEVL_ARITHOP carrying D = the relation mask;
;              HL advanced past the run.
;   Clobbers:  A, D, HL, (L_0B4A); calls CHRGET.
;   Algorithm: Compute A = token-'>' giving 0='>',1='=',2='<'; carry (token < '>') or A >= 3 ends
;              the run (-> FRMEVL_ARITHOP). Convert to a single bit (CP $01 / RLA: '>'->1,'='->2,
;              '<'->4) and XOR it into mask D. XOR-ing a bit already set (e.g. '>>') clears it, so
;              the new mask < old D; CP D then sets carry -> RAISE_SYNTAX_ERROR. Save the pointer
;              in L_0B4A, CHRGET past the token, and loop. Completed mask uses the MS BASIC code
;              1='>', 2='=', 4='<', combined for '>=','<=','<>','='.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_8:
        ; A = 0/1/2 for '>'/'='/'<'; out of range (or below '>') ends the relational run
        SUB TOK_GT
        JP C,FRMEVL_ARITHOP
        CP $03
        JP NC,FRMEVL_ARITHOP
        CP $01
        ; turn the token into its single relation bit (1='>',2='=',4='<')
        RLA
        ; merge the bit into the accumulated comparison mask
        XOR D
        CP D
        LD D,A
        ; the same relational symbol appeared twice (e.g. '>>') -> syntax error
        JP C,RAISE_SYNTAX_ERROR
        LD (L_0B4A),HL
        ; consume this relational token and look at the next one
        CALL CHRGET
        JR FRMEVL_OPLOOP_8
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_9 -- power-operator ('^') apply arm: set up x^y.
;   In:        FAC = left operand x; the OPLOOP_2 return address and pending-precedence frame are
;              already pushed by FRMEVL_OPLOOP_3.
;   Out:       queues the power kernel FN_SQR_1 as the apply routine and recurses (via OPLOOP_6)
;              to evaluate the exponent y at precedence $7F.
;   Clobbers:  A, BC, DE, HL, FAC; pushes the coerced left operand.
;   Algorithm: Coerce the base to single precision (FN_CSNG) and push it (FAC_PUSH) so the kernel
;              can recover it after y is evaluated. Set BC = FN_SQR_1 (the single-precision power
;              kernel; it begins with FN_CSNG, sets the L_0CB6 sign flag, and [RE] computes x^y
;              via exp(y*log x)) and D = $7F as the recursion precedence, then join FRMEVL_OPLOOP_6
;              to push the apply routine and recurse for the exponent.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_9:
        ; force the base to single precision ('^' is computed in single precision)
        CALL FN_CSNG
        ; save the base so the power kernel can recover it after the exponent is evaluated
        CALL FAC_PUSH
        ; [RE] FN_SQR_1 is the x^y power kernel, applied once the exponent is in the FAC
        LD BC,FN_SQR_1
        LD D,$7F
        JR FRMEVL_OPLOOP_6
; ----------------------------------------------------------------------
; FRMEVL_OPLOOP_10 -- integer-operator apply arm ('\','MOD', and the logical ops).
;   In:        FAC = left operand; the OPLOOP_2 return / pending-precedence frame already pushed.
;   Out:       queues FRMEVL_INT_OP_HANDLER as the apply routine and recurses (via OPLOOP_6) for
;              the right operand.
;   Clobbers:  A, BC, DE, HL, FAC; pushes the coerced left operand (HL).
;   Algorithm: Coerce the left operand to a 16-bit integer (FN_CINT, with DE saved/restored across
;              the call) and push it (PUSH HL) so the handler can recover it. Set BC =
;              FRMEVL_INT_OP_HANDLER (which re-coerces the right operand to integer, pops both, and
;              dispatches by precedence code: $7A=MOD, $7B='\', else AND/OR/XOR/etc. via the
;              integer operator band), then join FRMEVL_OPLOOP_6 to recurse for the right operand.
;              '\', MOD and the bitwise/logical operators all require integer operands, hence the
;              coercion here.
; ----------------------------------------------------------------------
FRMEVL_OPLOOP_10:
        PUSH DE
        ; force the left operand to a 16-bit integer (integer/logical operators require integers)
        CALL FN_CINT
        POP DE
        PUSH HL
        ; queue the integer apply handler that dispatches MOD/'\'/AND/OR/XOR by precedence code
        LD BC,FRMEVL_INT_OP_HANDLER
        JR FRMEVL_OPLOOP_6
; ----------------------------------------------------------------------
; FRMEVL_ARITHOP -- relational binary-operator apply guard and frame setup.
;   In:        D = relation mask (from FRMEVL_RELOP/_OPLOOP_8); B = pending precedence;
;              FAC = left operand; HL -> the token after the relational run.
;   Out:       if the relational operator binds, pushes the operand frame and recurses for the
;              right operand at precedence $64 with the relational-result handler queued; else RET.
;   Clobbers:  A, BC, DE, HL; pushes operand/return frames.
;   Algorithm: Relational operators have pseudo-precedence $64 (100); if pending precedence B >=
;              $64 the relational does not bind here -> RET to apply it outward. Otherwise push B
;              and the relation mask D, set DE = $6404 (D=$64 = recursion precedence for the right
;              operand; E=$04 = the operator code that, doubled, selects the compare slot in each
;              type's operator band: DCOMP_REL/FCOMP/INT16_COMP). Queue FRMEVL_SCAN_UNARY_1 ([RE]
;              the relational-result finalizer: it combines the compare result with the relation
;              mask to yield -1/0 into the FAC) as the post-recursion return, then test the left
;              operand's type via FRMEVL_TEST_TYPE. If numeric (NZ), take the compare path through
;              FRMEVL_OPLOOP_4; if string (Z), push the string descriptor (LD HL,(FAC)) and queue
;              the string-compare handler ([RE] NEXT_LOOP_BODY_7, a mislabel) before joining
;              FRMEVL_OPLOOP_6 to recurse for the right side.
; ----------------------------------------------------------------------
FRMEVL_ARITHOP:
        LD A,B
        ; relational pseudo-precedence is $64; if a higher op is pending the comparison binds outward
        CP $64
        RET NC
        PUSH BC
        PUSH DE
        ; D=$64 = recursion precedence for the right operand; E=$04 = compare-slot index within the operator band
        LD DE,$6404
        LD HL,FRMEVL_RELOP_RESULT
        PUSH HL
        ; classify the left operand: numeric (NZ) -> compare path, string (Z) -> string compare
        CALL FRMEVL_TEST_TYPE
        ; numeric left operand: take the numeric comparison path
        JP NZ,FRMEVL_OPLOOP_4
        ; string left operand: load/push its descriptor for the string-comparison handler
        LD HL,(FAC)
        PUSH HL
        LD BC,NEXT_LOOP_BODY_7
        JR FRMEVL_OPLOOP_6
; ----------------------------------------------------------------------
; FRMEVL_OPCOMBINE -- combine a binary operator with its two evaluated operands
;   In:        Right operand in the FAC, its type in VALTYP ($0B14: 2=int,4=single,8=double,3=string).
;              Stack (top first): a frame BC where C = operator routine index and B = the LEFT operand's VALTYP,
;              pushed earlier by FRMEVL_OPLOOP_4/5; below it the LEFT operand's mantissa bytes (2/4/8 by its type).
;              [RE] C = (operator token - TOK_PLUS): 0=add,1=sub,2=mul,3=div; the compare slot (band entry 5) is
;              supplied via the relational path, and power '^' is handled earlier and never reaches here.
;   Out:       Tail-jumps (JP (HL) or PUSH/RET) to the selected OPERATOR_ROUTINE_TBL handler. The handler leaves
;              the result in the FAC with VALTYP set; control does not return here.
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC and its extension cells, CRUNCH_LITERAL_MODE, the operand stack frame.
;   Algorithm: Pop the frame: save C (operator index) into CRUNCH_LITERAL_MODE (reused as the operator scratch),
;              leaving B = left operand type. Compare the right type (VALTYP) with the left type B. If equal,
;              branch to the matching dispatch band (int/single/double). If they differ, fall into FRMEVL_OPC_
;              PROMOTE to widen the narrower operand (int<single<double; string is a TYPE MISMATCH). Once both
;              share a type, index that band of OPERATOR_ROUTINE_TBL by 2*operator-index and dispatch.
; ----------------------------------------------------------------------
FRMEVL_OPCOMBINE:
        POP BC
        LD A,C
        ; Stash the operator routine index (C) in the scratch byte; the band-dispatch tail reads it back to pick the add/sub/mul/div/compare handler within the chosen type band.
        LD (CRUNCH_LITERAL_MODE),A
        LD A,(VALTYP)
        ; Compare the right operand's type (VALTYP) against the left operand's type B.
        CP B
        ; Types differ: go promote the narrower operand to the wider common type.
        JR NZ,FRMEVL_OPC_PROMOTE
        CP VT_INT
        ; Both integer: dispatch through the integer operator band.
        JR Z,FRMEVL_OPC_DISPATCH_INT
        CP VT_SNG
        ; Both single: pop the single-precision left operand and dispatch the single band.
        JP Z,FRMEVL_OPC_DISPATCH_SNG
        ; Both double ($08): stage the double operands and dispatch the double band.
        JR NC,FRMEVL_OPC_DBL_SETUP
; ----------------------------------------------------------------------
; FRMEVL_OPC_PROMOTE (was FRMEVL_OPLOOP_13) -- coerce two differently-typed operands to a common numeric type
;   In:        A = right operand type (VALTYP), B = left operand type; operands as for FRMEVL_OPCOMBINE.
;   Out:       Branches to the path that widens the narrower operand to the wider of the two types, then into
;              that type's dispatch band.
;   Clobbers:  A,D,F (D = right operand type held for the comparisons).
;   Algorithm: Decide the common type by descending width. If the LEFT is double ($08) widen the right/FAC
;              operand to double (FRMEVL_OPC_WIDEN_RIGHT_DBL); if the RIGHT is double widen the left (FRMEVL_OPC_
;              WIDEN_LEFT_DBL). Else if the LEFT is single ($04) widen the right/FAC operand to single (FRMEVL_
;              OPC_WIDEN_RIGHT_SNG). A string right operand ($03) is rejected as TYPE MISMATCH. Otherwise (right
;              single, left integer) widen the left integer to single (FRMEVL_OPC_WIDEN_LEFT_SNG).
; ----------------------------------------------------------------------
FRMEVL_OPC_PROMOTE:
        ; Keep the right operand's type in D; A is reused to test the left type B.
        LD D,A
        LD A,B
        CP $08
        ; Left operand is double: widen the right/FAC operand to double.
        JR Z,FRMEVL_OPC_WIDEN_RIGHT_DBL
        LD A,D
        CP $08
        ; Right operand is double: widen the left operand to double.
        JR Z,FRMEVL_OPC_WIDEN_LEFT_DBL
        LD A,B
        CP $04
        ; Left operand is single: widen the right/FAC operand to single.
        JR Z,FRMEVL_OPC_WIDEN_RIGHT_SNG
        LD A,D
        CP $03
        ; Right operand is a string: arithmetic on a string is a Type mismatch error.
        JP Z,RAISE_TYPE_MISMATCH
        ; Right is single and left is integer: widen the left integer operand to single.
        JR NC,FRMEVL_OPC_WIDEN_LEFT_SNG
; ----------------------------------------------------------------------
; FRMEVL_OPC_DISPATCH_INT (was FRMEVL_OPLOOP_14) -- dispatch a two-integer operation through the integer band
;   In:        Both operands integer. C holds the operator routine index from the popped frame; B is zeroed here.
;              The left integer operand is on the stack; the right integer operand is in the FAC.
;   Out:       PUSH/RET tail-jumps to the integer operator handler (IADD/INT_SIGNEXT_SUB/IMUL/IDIV/INT16_COMP)
;              with DE = left operand (popped) and HL = right operand (from FAC).
;   Clobbers:  A,B,C,D,E,H,L,F.
;   Algorithm: Form HL = OPERATOR_ROUTINE_TBL+OP_BAND_INT ($0517) + 2*index by zeroing B and adding BC twice,
;              load the 16-bit handler address from that DEFW slot into BC, pop the left operand into DE and load
;              the right operand from the FAC into HL, then PUSH handler / RET. (The integer band has its OWN
;              PUSH/RET dispatcher here, distinct from the single/double band dispatcher.)
; ----------------------------------------------------------------------
FRMEVL_OPC_DISPATCH_INT:
        ; Index the integer operator band ($0517: IADD,INT_SIGNEXT_SUB,IMUL,IDIV,INT16_COMP) by 2*operator-index (ADD HL,BC twice with B zeroed).
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_INT
        LD B,$00
        ADD HL,BC
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        ; Recover the left integer operand into DE; the right integer operand is read from the FAC into HL.
        POP DE
        LD HL,(FAC)
        ; PUSH handler address / RET = computed jump into the integer operator routine.
        PUSH BC
        RET
; ----------------------------------------------------------------------
; FRMEVL_OPC_WIDEN_RIGHT_DBL (was FRMEVL_OPLOOP_15) -- widen the right operand to double, then take the double path
;   In:        Right operand in the FAC (narrower numeric type); the left operand is already double on the stack.
;   Out:       Falls into FRMEVL_OPC_DBL_SETUP with the FAC holding a double-precision right operand.
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC.
;   Algorithm: CALL FN_CDBL converts the FAC in place to double precision, then falls through into the
;              double-operand setup.
; ----------------------------------------------------------------------
FRMEVL_OPC_WIDEN_RIGHT_DBL:
        ; Promote the right operand (in the FAC) up to double precision.
        CALL FN_CDBL
; ----------------------------------------------------------------------
; FRMEVL_OPC_DBL_SETUP (was FRMEVL_OPLOOP_16) -- stage the right double operand and the left operand's low words
;   In:        Right operand is double in the FAC; the left double operand's mantissa bytes are on the stack
;              (low extension words on top). Operator index already saved in CRUNCH_LITERAL_MODE.
;   Out:       Falls into FRMEVL_OPC_DBL_LOADFAC with the right operand moved to the secondary FP temp ($0CBA)
;              and the FAC's two low double extension words ($0CAF/$0CB0 then $0CAD/$0CAE) loaded from the LEFT
;              operand's low words.
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC, the secondary FP temp ($0CBA), $0CAD-$0CB0.
;   Algorithm: FP_ARG_TO_TEMP2 copies the right (FAC) double into the secondary operand temp. Then pop the LEFT
;              operand's two low extension words off the stack into the FAC extension cells $0CAF and $0CAD (the
;              low 4 bytes of the 8-byte double FAC), and fall through to load the left operand's high
;              mantissa/sign and dispatch the double band.
; ----------------------------------------------------------------------
FRMEVL_OPC_DBL_SETUP:
        ; Move the right double operand from the FAC into the secondary FP operand temp ($0CBA).
        CALL FP_ARG_TO_TEMP2
        POP HL
        ; Pop the left double operand's two low extension words into the FAC's low double bytes ($0CAF/$0CB0 then $0CAD/$0CAE).
        LD (L_0CAF),HL
        POP HL
        LD (L_0CAD),HL
; ----------------------------------------------------------------------
; FRMEVL_OPC_DBL_LOADFAC (was FRMEVL_OPLOOP_17) -- load the left double operand's high mantissa into the FAC
;   In:        Stack holds the left double operand's remaining high mantissa bytes; the FAC low extension words
;              were already loaded by FRMEVL_OPC_DBL_SETUP (or this is entered from the left-was-single path).
;   Out:       Falls into FRMEVL_OPC_DISPATCH_DBL with the full left operand assembled in the FAC.
;   Clobbers:  B,C,D,E,H,L,F, the FAC.
;   Algorithm: POP BC / POP DE recover the left operand's high mantissa/sign bytes and FP_STORE_FAC writes DE
;              into the FAC mantissa-low ($0CB1) and BC into FACHI ($0CB3), completing the LEFT double operand
;              in the FAC.
; ----------------------------------------------------------------------
FRMEVL_OPC_DBL_LOADFAC:
        ; Recover the left operand's high mantissa/sign bytes (BC,DE) from the stack.
        POP BC
        POP DE
        ; Write DE->FAC mantissa-low and BC->FACHI, completing the left operand in the FAC.
        CALL FP_STORE_FAC
; ----------------------------------------------------------------------
; FRMEVL_OPC_DISPATCH_DBL (was FRMEVL_OPLOOP_18) -- dispatch a two-double operation through the double band
;   In:        Left double operand in the FAC, right double operand in the secondary FP temp ($0CBA); the
;              operator index lives in CRUNCH_LITERAL_MODE.
;   Out:       JP (HL) to the double operator handler (DADD/DP_NEGATE_SIGN/DMUL/DDIV/DCOMP_REL).
;   Clobbers:  A,H,L,F (then the handler).
;   Algorithm: CALL FN_CDBL guarantees the FAC is double, then load HL = OPERATOR_ROUTINE_TBL+OP_BAND_DBL ($0503)
;              and fall into the shared band dispatcher FRMEVL_OPC_BAND_DISPATCH.
; ----------------------------------------------------------------------
FRMEVL_OPC_DISPATCH_DBL:
        ; Ensure the FAC (left operand) is double precision before the double handler runs.
        CALL FN_CDBL
        ; Select the double operator band ($0503: DADD,DP_NEGATE_SIGN,DMUL,DDIV,DCOMP_REL).
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_DBL
; ----------------------------------------------------------------------
; FRMEVL_OPC_BAND_DISPATCH (was FRMEVL_OPLOOP_19) -- index a band of OPERATOR_ROUTINE_TBL and jump to the handler
;   In:        HL = the chosen band base (OP_BAND_SNG/DBL entry of OPERATOR_ROUTINE_TBL); CRUNCH_LITERAL_MODE =
;              operator routine index. Operands already staged in the FAC and the secondary temp.
;   Out:       JP (HL) into the selected DEFW handler; never returns here.
;   Clobbers:  A,H,L,F.
;   Algorithm: Reload the operator index, RLCA to get 2*index, add it to HL (8-bit add into L with carry
;              propagated into H via the ADD A,L / LD L,A / ADC A,H / SUB L / LD H,A idiom), then load the
;              16-bit handler address from that DEFW slot into HL and JP (HL). Shared by the single and double
;              bands (the integer band uses its own PUSH/RET dispatcher in FRMEVL_OPC_DISPATCH_INT).
; ----------------------------------------------------------------------
FRMEVL_OPC_BAND_DISPATCH:
        ; Reload the operator routine index (saved by FRMEVL_OPCOMBINE).
        LD A,(CRUNCH_LITERAL_MODE)
        ; Double it to a byte offset into the band (each entry is a 2-byte DEFW).
        RLCA
        ; Add the offset to the band base HL; the ADC A,H / SUB L sequence propagates the carry into H.
        ADD A,L
        LD L,A
        ADC A,H
        SUB L
        LD H,A
        ; Load the 16-bit handler address from the DEFW slot, then JP (HL).
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        JP (HL)
; ----------------------------------------------------------------------
; FRMEVL_OPC_WIDEN_LEFT_DBL (was FRMEVL_OPLOOP_20) -- widen the left operand to double when only the right is double
;   In:        Right operand is double in the FAC; left operand (narrower: int or single) is on the stack with
;              its type byte. B = left VALTYP, C = operator index on entry (but see below).
;   Out:       Joins the double dispatch path: if the left was single, into FRMEVL_OPC_DBL_LOADFAC (reusing the
;              staged right operand); otherwise loads the left integer into the FAC and falls into FRMEVL_OPC_
;              DISPATCH_DBL (whose FN_CDBL widens it to double).
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC, VALTYP, the secondary FP temp.
;   Algorithm: Stash the right double operand into the secondary temp (FP_ARG_TO_TEMP2). PUSH BC / POP AF
;              recovers the LEFT operand's type byte (old B) into A and sets VALTYP from it (the operator index
;              in old C is dropped into F here -- it survives only because OPCOMBINE already saved it in CRUNCH_
;              LITERAL_MODE). If the left was already single ($04) the staged operand suffices, so branch to the
;              high-mantissa load; otherwise the left is a 16-bit integer -- load it into the FAC and fall through,
;              where FN_CDBL widens it to double.
; ----------------------------------------------------------------------
FRMEVL_OPC_WIDEN_LEFT_DBL:
        PUSH BC
        ; Stash the right double operand into the secondary FP temp before rebuilding the left operand in the FAC.
        CALL FP_ARG_TO_TEMP2
        ; Recover the left operand's type byte (pushed as B) into A and set it as the current VALTYP; the operator index (old C) is discarded here, having already been saved in CRUNCH_LITERAL_MODE.
        POP AF
        LD (VALTYP),A
        CP VT_SNG
        ; Left was already single: its mantissa words are still staged, so join the high-mantissa load.
        JR Z,FRMEVL_OPC_DBL_LOADFAC
        POP HL
        ; Left was a 16-bit integer: load it into the FAC and fall into the double dispatch (FN_CDBL widens it).
        LD (FAC),HL
        JR FRMEVL_OPC_DISPATCH_DBL
; ----------------------------------------------------------------------
; FRMEVL_OPC_WIDEN_RIGHT_SNG (was FRMEVL_OP_COERCE_INT) -- widen the right operand to single, then dispatch single
;   In:        Right operand in the FAC (narrower than single: integer); the left single operand is on the stack.
;              Reached from the promotion tree when the LEFT operand is single ($04).
;   Out:       Falls into FRMEVL_OPC_DISPATCH_SNG (pops the left single operand and dispatches the single band).
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC.
;   Algorithm: CALL FN_CSNG promotes the FAC (right operand) up to single precision, then falls through to the
;              single-precision dispatch tail.
;   Note:      The prior label/comment ('coerce to INT', CALL FN_CINT) was WRONG -- the bytes at $3BC9 are
;              CD EE 4F = CALL FN_CSNG ($4FEE), the single-precision conversion. This is the single-widen path.
; ----------------------------------------------------------------------
FRMEVL_OPC_WIDEN_RIGHT_SNG:
        ; Promote the right operand (in the FAC) up to single precision to match the single left operand.
        CALL FN_CSNG
; ----------------------------------------------------------------------
; FRMEVL_OPC_DISPATCH_SNG (was FRMEVL_OP_POP_FRAME) -- recover the left single operand and dispatch the single band
;   In:        Left single operand pushed on the stack as two register pairs; right single operand in the FAC.
;              Entered directly from FRMEVL_OPCOMBINE when BOTH operands are single, or by fall-through after the
;              right operand was widened to single.
;   Out:       Falls into FRMEVL_OPC_SNG_BAND, which selects the single band and dispatches.
;   Clobbers:  B,C,D,E.
;   Algorithm: POP BC / POP DE recover the left single operand into BC,DE (the FP register operand the single
;              handlers expect alongside the FAC), then fall through to load the single band base.
; ----------------------------------------------------------------------
FRMEVL_OPC_DISPATCH_SNG:
        ; Recover the left single operand into BC/DE (the register operand the single-precision handlers take alongside the FAC).
        POP BC
        POP DE
; ----------------------------------------------------------------------
; FRMEVL_OPC_SNG_BAND (was FRMEVL_OP_DISPATCH_REL) -- select the single-precision operator band and dispatch
;   In:        Both operands staged for a single-precision op (left in BC/DE, right in the FAC); operator index
;              in CRUNCH_LITERAL_MODE.
;   Out:       Branches into FRMEVL_OPC_BAND_DISPATCH, which JP (HL)s to FADD_ALIGN/FSUB/FMUL/FDIV/FCOMP.
;   Clobbers:  H,L.
;   Algorithm: Load HL = OPERATOR_ROUTINE_TBL+OP_BAND_SNG ($050D, the single-precision band) and jump to the
;              shared band dispatcher.
;   Note:      Prior comment ('relational/string handler vector $050D') was WRONG. $050D = OP_BAND_SNG, the
;              single-precision arithmetic band (FADD_ALIGN,FSUB,FMUL,FDIV,FCOMP); the relational op is just the
;              compare slot (FCOMP) within it, not a separate string vector.
; ----------------------------------------------------------------------
FRMEVL_OPC_SNG_BAND:
        ; Select the single-precision operator band ($050D: FADD_ALIGN,FSUB,FMUL,FDIV,FCOMP).
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_SNG
        JR FRMEVL_OPC_BAND_DISPATCH
; ----------------------------------------------------------------------
; FRMEVL_OPC_WIDEN_LEFT_SNG (was FRMEVL_OP_COERCE_INT_3) -- widen the integer left operand to single, dispatch single
;   In:        Right operand is single in the FAC; left operand is a 16-bit integer pushed on the stack. Reached
;              when the right is single and the left is integer.
;   Out:       Branches to FRMEVL_OPC_SNG_BAND for single-precision dispatch, with the widened LEFT operand in
;              registers (E,D,C,B from FP_LOAD_FAC) and the original RIGHT operand restored in the FAC.
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC, FACHI.
;   Algorithm: POP the integer left operand into HL, FAC_PUSH saves the current single FAC (the RIGHT operand)
;              on the stack, INT_TO_SINGLE_HL converts the integer to single in the FAC, FP_LOAD_FAC loads that
;              widened LEFT single into the E,D,C,B registers, then POP/POP restore the saved RIGHT operand back
;              into FACHI ($0CB3) and FAC ($0CB1), and JR to the single-band dispatch.
;   Note:      Mislabeled '..._INT': this is an integer->SINGLE widen of the LEFT operand, not an integer coerce.
; ----------------------------------------------------------------------
FRMEVL_OPC_WIDEN_LEFT_SNG:
        ; Recover the integer left operand from the stack.
        POP HL
        ; Save the single right operand (currently in the FAC) on the stack while the left integer is converted.
        CALL FAC_PUSH
        ; Convert the 16-bit integer left operand in HL to single precision in the FAC.
        CALL INT_TO_SINGLE_HL
        CALL FP_LOAD_FAC
        POP HL
        ; Restore the saved single right operand back into the FAC (FACHI then FAC); the widened left operand stays in the E,D,C,B registers loaded by FP_LOAD_FAC.
        LD (FACHI),HL
        POP HL
        LD (FAC),HL
        JR FRMEVL_OPC_SNG_BAND
; ----------------------------------------------------------------------
; IDIV -- integer-band slot for '/' division: promote both integer operands to single and divide as floats
;   In:        DE = left integer operand, HL = right integer operand, as set by the integer dispatcher FRMEVL_
;              OPC_DISPATCH_INT (POP DE = left, LD HL,(FAC) = right). Reached only as the integer band's divide
;              slot ($051D).
;   Out:       Tail-jumps to FDIV_BY_TEN_1 (the FDIV pop-and-divide entry); the result is a single-precision
;              float in the FAC. VALTYP is set to single by the conversion path.
;   Clobbers:  A,B,C,D,E,H,L,F, the FAC.
;   Algorithm: '/' in MS BASIC always yields a float even on two integers. PUSH HL saves the right operand;
;              EX DE,HL moves the LEFT operand into HL and INT_TO_SINGLE_HL converts the LEFT operand to single
;              in the FAC; FAC_PUSH then pushes that LEFT single (the dividend). POP HL restores the RIGHT
;              operand and a second INT_TO_SINGLE_HL converts the RIGHT operand to single in the FAC (the
;              divisor). JP FDIV_BY_TEN_1 pops the pushed dividend into BC/DE and FDIV computes popped/FAC =
;              left/right -> single-precision quotient.
;   Note:      The two INT_TO_SINGLE_HL calls convert the LEFT operand first (then the RIGHT), opposite to a
;              prior gloss; after EX DE,HL the first call operates on the LEFT operand.
; ----------------------------------------------------------------------
IDIV:
        PUSH HL
        EX DE,HL
        ; Convert the LEFT integer operand (moved into HL by EX DE,HL) to single precision in the FAC -- this is the dividend.
        CALL INT_TO_SINGLE_HL
        POP HL
        ; Push the LEFT single (dividend) aside; HL is then restored to the RIGHT operand for conversion to the divisor.
        CALL FAC_PUSH
        CALL INT_TO_SINGLE_HL
        ; FAC now holds the RIGHT single (divisor); the FDIV pop entry recovers the pushed dividend and computes left/right -> single quotient.
        JP FDIV_BY_TEN_1
; ----------------------------------------------------------------------
; EVAL fetch one operand. [FIX] $FF=extended-function-token escape -> FUNC_DISPATCH_TBL, NOT radix; ampersand $26=radix path.
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND:
        CALL CHRGET
        JP Z,RAISE_MISSING_OPERAND
        JP C,FIN_1+1
        CALL IS_LETTER_A
        JP NC,FRMEVL_PAREN_3
        CP $20
        JP C,CHRGOT_CONST_VALUE
        INC A
        JP Z,FRMEVL_FUNC_TOKEN
        DEC A
        CP TOK_PLUS
        JR Z,FRMEVL_EVAL_OPERAND
        CP TOK_MINUS
        JP Z,FRMEVL_PAREN_1
        CP $22
        JP Z,SCAN_STR_QUOTE
        CP TOK_NOT
        JP Z,FRMEVL_NOT
        CP $26
        JP Z,SCAN_AMP_RADIX_CONST
        CP $E6
        JR NZ,FRMEVL_EVAL_OPERAND_1
        CALL CHRGET
        LD A,(ERRFLG)
        PUSH HL
        CALL FP_LOAD_INT_TO_FAC
        POP HL
        RET
; ----------------------------------------------------------------------
; ERL floats ERR_SAVTXT($0B60). [FIX/UNKNOWN] $0B60 is a saved TEXT POINTER, NOT the line number (that is ERRLIN $0B62).
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND_1:
        CP $E5
        JR NZ,FRMEVL_EVAL_OPERAND_2
        CALL CHRGET
        PUSH HL
        LD HL,(ERR_SAVTXT)
        CALL INT_TO_SNG
        POP HL
        RET
; ----------------------------------------------------------------------
; VARPTR head: SYNCHR '('; '#'($23)->#n via FCB_BUFFER_PTR then _4; else var->_3 (PTRGET).
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND_2:
        CP $EB
        JR NZ,FRMEVL_EVAL_OPERAND_5
        CALL CHRGET
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CP $23
        JR NZ,FRMEVL_EVAL_OPERAND_3
        CALL GETBYT_CHRGET
        PUSH HL
        CALL FCB_BUFFER_PTR
        POP HL
        JP FRMEVL_EVAL_OPERAND_4
; ----------------------------------------------------------------------
; VARPTR(var): PTRGET (PTRGET_1+1, XOR A=scalar-ref/non-DIM, not no-create) returns the data addr in DE.
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND_3:
        CALL PTRGET_1+1
; ----------------------------------------------------------------------
; VARPTR tail: SYNCHR ')'; 0 addr->ERROR_FC; else FP_STORE_FAC_INT stores the address as an integer FAC.
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND_4:
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        EX DE,HL
        LD A,H
        OR L
        JP Z,ERROR_FC
        CALL FP_STORE_FAC_INT
        POP HL
        RET
; ----------------------------------------------------------------------
; fn tokens: USR INSTR COLOR$CD(plot-color not SCRN) HCOLOR SCRN HSCRN INKEY$ STRING$ INPUT$ FN; none->FRMEVL_PAREN.
; ----------------------------------------------------------------------
FRMEVL_EVAL_OPERAND_5:
        CP $E1
        JP Z,FP_LOAD_INT_TO_FAC_2
        CP $E9
        JP Z,FN_INSTR
        CP $CD
        JP Z,GFX_FN_VPOS_3
        CP $D3
    IFDEF GBASIC
        JP Z,GFX_FN_HCOLOR               ; (GBASIC: HCOLOR() fn handler)
    ELSE
        JP Z,RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $3C85->$280F  HCOLOR() fn -> not-impl (MBASIC)
    ENDIF
        CP $EC
        JP Z,GFX_FN_VPOS_2
        CP $ED
    IFDEF GBASIC
        JP Z,GFX_FN_HSCRN                ; (GBASIC: HSCRN() fn handler)
    ELSE
        JP Z,RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $3C8F->$280F  HSCRN() fn -> not-impl (MBASIC)
    ENDIF
        CP $EE
        JP Z,INKEY_SCAN_1
        CP $E7
        JP Z,FN_STRING_STR
        CP TOK_INPUT
        JP Z,FN_INPUT_DOLLAR
        CP TOK_FN
        JP Z,STMT_DEF_2
; ----------------------------------------------------------------------
; paren subexpr: FRMEVL + SYNCHR ')'. Pre-existing 'ADD HL,HL FAC->integer' source comment is WRONG.
; ----------------------------------------------------------------------
FRMEVL_PAREN:
        CALL FRMEVL
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        RET
; ----------------------------------------------------------------------
; unary minus: D=$7D, FRMEVL_OPLOOP, reload FRMEVL_TXTPTR_TEMP($0B69), FP_NEGATE_CHECKED; exit via _2.
; ----------------------------------------------------------------------
FRMEVL_PAREN_1:
        LD D,$7D
        CALL FRMEVL_OPLOOP
        LD HL,(FRMEVL_TXTPTR_TEMP)
        PUSH HL
        CALL FP_NEGATE_CHECKED
; ----------------------------------------------------------------------
; common exit: POP HL; RET. Shared by _1 and the extended-function dispatch path.
; ----------------------------------------------------------------------
FRMEVL_PAREN_2:
        POP HL
        RET
; ----------------------------------------------------------------------
; variable-ref: PTRGET (PTRGET_1+1, XOR A) returns the data addr in DE and writes VALTYP; falls into _4.
; ----------------------------------------------------------------------
FRMEVL_PAREN_3:
        CALL PTRGET_1+1
; ----------------------------------------------------------------------
; load var into FAC: store addr into FAC($0CB1); FRMEVL_TEST_TYPE Z=string keeps the ptr, NZ=FP_ARG_SETUP1 copies the value.
; ----------------------------------------------------------------------
FRMEVL_PAREN_4:
        PUSH HL
        EX DE,HL
        LD (FAC),HL
        CALL FRMEVL_TEST_TYPE
        CALL NZ,FP_ARG_SETUP1
        POP HL
        RET
; ----------------------------------------------------------------------
; CHRGET_UPCASE -- read the current tokenizer char and fold it to upper case
;   In:        HL -> current character in the BASIC text/console line buffer
;   Out:       A = (HL) with ASCII lowercase a-z folded to uppercase; all other bytes unchanged. HL is NOT advanced (peek, not consume). [RE] Carry is left in a defined state by TOUPPER_A's compares (set if A < 'a', else clear) but is an INCIDENTAL side effect -- no caller consumes it; every caller either uses A or recomputes flags (e.g. via IS_LETTER_A / its own CP).
;   Clobbers:  A, F. HL preserved.
;   Algorithm: Load A from (HL) -- the CURRENT char, with NO INC HL, so it differs from the true CHRGET ($33C9, first byte INC HL) which advances first (and which also skips spaces / expands constant tokens; CHRGET_UPCASE does neither). Fall straight into TOUPPER_A to upcase a-z. [RE] Used by CRUNCH's case-insensitive keyword/identifier scan so 'print' and 'PRINT' tokenize identically.
; ----------------------------------------------------------------------
CHRGET_UPCASE:
        ; Peek the CURRENT char (no INC HL -- unlike the real CHRGET, this does not advance the text pointer), then fall into TOUPPER_A to fold it.
        LD A,(HL)
; ----------------------------------------------------------------------
; TOUPPER_A -- fold the ASCII letter already in A to upper case
;   In:        A = candidate character (entry used when the caller already holds the char, skipping CHRGET_UPCASE's LD A,(HL))
;   Out:       A = uppercase if input was 'a'-'z' ($61-$7A), otherwise A unchanged. [RE] Carry is defined but incidental (set when A < 'a' via the early RET C; clear on the A >= '{' passthrough and on the folded a-z path since AND $5F resets carry) -- no caller relies on it.
;   Clobbers:  A, F
;   Algorithm: Range-guard then mask. CP $61/RET C passes through anything below 'a'. CP $7B/RET NC passes through anything at or above '{' ($7B), i.e. above 'z'. The remaining a-z range is folded with AND $5F, which clears bit 5 ($20) to map lowercase to uppercase. Digits, punctuation, control codes, and already-uppercase letters are returned untouched. [RE] Direct callers (non-exhaustive): the &H/&O radix-literal scanner (SCAN_AMP_RADIX_CONST and SCAN_AMP_RADIX_CONST_1), the '&' marker chooser (CRUNCH_AMP_HEX_OCT), and the EDIT-mode keystroke handler (STMT_EDIT).
; ----------------------------------------------------------------------
TOUPPER_A:
        ; Below 'a' ($61): not lowercase, return char unchanged.
        CP $61
        RET C
        ; At or above '{' ($7B), i.e. past 'z': not lowercase, return char unchanged.
        CP $7B
        RET NC
        ; In a-z: clear bit 5 ($20) to fold lowercase to uppercase.
        AND $5F
        RET
; ----------------------------------------------------------------------
; LINGET_OR_AMP -- dispatch on '&': scan a radix literal, else parse a decimal line number
;   In:        A = current source character (already fetched by the caller); HL -> that char in the BASIC text
;   Out:       Falls through to SCAN_AMP_RADIX_CONST when A=='&' ($26); otherwise tail-jumps to LINGET (decimal line-number parser). Result delivered by whichever path runs.
;   Clobbers:  F (the CP); otherwise per the path taken.
;   Algorithm: One-byte guard. If the lookahead char is '&' ($26) drop into the &H/&O radix-constant scanner; any other char means the operand is a plain decimal line number, so JP LINGET. Lets line-number contexts (GOTO/GOSUB target lists) also accept an &H/&O constant.
; ----------------------------------------------------------------------
LINGET_OR_AMP:
        ; '&' introduces an &H/&O radix literal; anything else is a decimal line number.
        CP $26
        JP NZ,LINGET
; ----------------------------------------------------------------------
; SCAN_AMP_RADIX_CONST -- parse an &H<hex> or &O<octal> integer literal into the FAC
;   In:        HL -> the '&' in the source text (CHRGET advances past it). Reached from FRMEVL_EVAL_OPERAND ($3C24) on token $26 and by fall-through from LINGET_OR_AMP.
;   Out:       16-bit value stored in the FAC as a VT_INT integer (via FP_STORE_FAC_INT); HL advanced past the literal. RET to caller.
;   Clobbers:  A, BC, DE, HL, F. The running accumulator lives in DE BETWEEN digit iterations and is swapped into HL (EX DE,HL) for each shift-and-add.
;   Algorithm: CHRGET the radix letter and upcase it. 'O' selects the octal path (SCAN_AMP_RADIX_CONST_5); 'H' selects the hex path (digit-count guard B=5, loop _1.._3). Any other letter defaults to octal with the radix char un-consumed (DEC HL at _4, so it is re-read as the first digit). Hex accumulates value = value*16 + nibble (ADD HL,HL x4) up to 4 hex digits; octal accumulates value*8 + digit (ADD HL,HL x3). Overflow past the field width raises Overflow; an octal digit >= '8' raises Syntax error. The value is converted to a FAC integer at _6.
; ----------------------------------------------------------------------
SCAN_AMP_RADIX_CONST:
        ; DE = running accumulator (zero); the value lives in DE between digits and is swapped into HL for each shift-and-add.
        LD DE,$0000
        CALL CHRGET
        CALL TOUPPER_A
        ; 'O' -> octal scanner.
        CP $4F
        JR Z,SCAN_AMP_RADIX_CONST_5
        ; 'H' -> hex scanner; any other letter defaults to octal with the char pushed back (DEC HL at _4).
        CP $48
        JR NZ,SCAN_AMP_RADIX_CONST_4
        ; Hex digit-count guard: at most 4 nibbles fit in 16 bits, so a 5th decrements B to zero -> Overflow.
        LD B,$05
SCAN_AMP_RADIX_CONST_1:
        INC HL
        LD A,(HL)
        CALL TOUPPER_A
        CALL IS_LETTER_A
        EX DE,HL
        JR NC,SCAN_AMP_RADIX_CONST_2
        CP $3A
        JR NC,SCAN_AMP_RADIX_CONST_6
        SUB $30
        JR C,SCAN_AMP_RADIX_CONST_6
        JR SCAN_AMP_RADIX_CONST_3
SCAN_AMP_RADIX_CONST_2:
        CP $47
        JR NC,SCAN_AMP_RADIX_CONST_6
        SUB $37
SCAN_AMP_RADIX_CONST_3:
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        OR L
        LD L,A
        DEC B
        JP Z,RAISE_OVERFLOW
        EX DE,HL
        JR SCAN_AMP_RADIX_CONST_1
SCAN_AMP_RADIX_CONST_4:
        DEC HL
; ----------------------------------------------------------------------
; SCAN_AMP_RADIX_CONST_5 -- octal-literal accumulation loop (value = value*8 + digit)
;   In:        DE = running 16-bit accumulator; HL -> next source char (radix char already positioned).
;   Out:       On a non-digit char: leaves the assembled value in HL (via EX DE,HL) and branches to _6 to store it. Otherwise loops.
;   Clobbers:  A, BC, DE, HL, F.
;   Algorithm: CHRGET the next char; EX DE,HL (value into HL); CHRGET returned carry-clear iff the char is not an ASCII digit, which ends the literal (JR NC to _6). A digit >= '8' is illegal octal -> Syntax error. Otherwise shift the value in HL left by 3 (ADD HL,HL x3) with carry-out checked after each shift (RET C -> the pushed RAISE_OVERFLOW), then add digit-'0' (in C) and EX DE,HL back before looping.
; ----------------------------------------------------------------------
SCAN_AMP_RADIX_CONST_5:
        CALL CHRGET
        EX DE,HL
        JR NC,SCAN_AMP_RADIX_CONST_6
        ; Digit '8' or '9' is not a valid octal digit -> Syntax error.
        CP $38
        JP NC,RAISE_SYNTAX_ERROR
        ; Arm RAISE_OVERFLOW as the return target so the three RET C shift-overflow checks raise Overflow with no explicit branch each.
        LD BC,RAISE_OVERFLOW
        PUSH BC
        ADD HL,HL
        RET C
        ADD HL,HL
        RET C
        ADD HL,HL
        RET C
        POP BC
        LD B,$00
        SUB $30
        LD C,A
        ADD HL,BC
        EX DE,HL
        JR SCAN_AMP_RADIX_CONST_5
; ----------------------------------------------------------------------
; SCAN_AMP_RADIX_CONST_6 -- store the scanned radix value into the FAC and return
;   In:        HL = the assembled 16-bit value (every path EX DE,HL's the accumulator into HL before branching here); DE = the saved source text pointer (first char past the literal).
;   Out:       FAC holds the value as a VT_INT integer; HL = source pointer past the literal (restored from DE). RET.
;   Clobbers:  A, DE, HL, F.
;   Algorithm: CALL FP_STORE_FAC_INT first -- it does LD (FAC),HL, so HL must already hold the value -- then EX DE,HL swaps the saved text pointer (in DE) back into HL for the caller, and RET. NOTE: the EX DE,HL is AFTER the store (to recover the text pointer), not before it; the value is never in DE here.
; ----------------------------------------------------------------------
SCAN_AMP_RADIX_CONST_6:
        CALL FP_STORE_FAC_INT
        EX DE,HL
        RET
; ----------------------------------------------------------------------
; FRMEVL_FUNC_TOKEN -- FRMEVL handler for an extended function token (the $FF escape); NOT part of the &H/&O scanner
;   In:        Entered from FRMEVL_EVAL_OPERAND at $3C0A when the current source char is $FF (the function-escape token): the code does INC A (A=$FF -> $00), JP Z,_7. So on entry A=$00 (the INC A result, immediately overwritten); HL -> the $FF byte.
;   Out:       Tail-dispatches to the function's handler via the FUNC_DISPATCH_TBL vector (jumps, does not return here). For RND with no '(' it diverts to the RND-no-argument entry ($5D89).
;   Clobbers:  A, BC, HL, F (and FAC/stack via the argument evaluation in the sub-paths).
;   Algorithm: Step past the $FF escape (INC HL; LD A,(HL)) to read the function sub-token and form index = sub-token - $81. Special-case index 7 (= FUNC_DISPATCH_TBL slot 7 = RND): peek the next char via CHRGET; if it is not '(' this is RND with no argument so JP to the RND-no-arg path; if '(' force A=index 7 and continue. Fall into FRMEVL_FUNC_TOKEN_1 to dispatch.
;   [RE] The $FF-then-byte scheme is the MS BASIC-80 extended-function token path. UNKNOWN: the full sub-token -> table-slot mapping is fixed by the tokenizer; only the RND index (7) is special-cased in code here.
; ----------------------------------------------------------------------
FRMEVL_FUNC_TOKEN:
        ; Step past the $FF function-escape byte to the function sub-token.
        INC HL
        LD A,(HL)
        ; Function sub-tokens start at $81; subtract to get the 0-based FUNC_DISPATCH_TBL index.
        SUB $81
        ; Index 7 is RND, the only function allowing the no-argument form RND with no parens.
        CP $07
        JR NZ,FRMEVL_FUNC_TOKEN_1
        PUSH HL
        CALL CHRGET
        CP $28
        POP HL
        ; [RE] RND with no '(': divert to the RND-no-argument entry ($5D89), which CHRGETs, loads a default arg, and calls FN_RND -- POLY_EVAL_2 is a mislabel of that entry.
        JP NZ,POLY_EVAL_2
        LD A,$07
; ----------------------------------------------------------------------
; FRMEVL_FUNC_TOKEN_1 -- build the dispatch index and evaluate the function argument list
;   In:        A = function table index (0-based; 7 forced for RND-with-parens); HL -> the function token.
;   Out:       For the multi-argument string functions (raw indices 0,1,2) both arguments are evaluated and staged on the stack, then JR to the dispatch tail (_11) with HL=doubled index; otherwise control passes to FRMEVL_FUNC_ARG_PAREN for the single-(arg) form.
;   Clobbers:  A, BC, DE, HL, F, FAC, stack.
;   Algorithm: Double the index into a byte offset (RLCA) and save it (PUSH BC, B=0). CHRGET past the function token. If the doubled index (in C) < $05 (raw index 0,1,2) evaluate the first argument with FRMEVL, require ',' via SYNCHR, integer-check it (FP_INT_CHECK), juggle it onto the stack, GETBYT the second argument, recover the doubled index into HL via EX (SP),HL, and JR to _11. Doubled index >= $05 (raw index >= 3) takes the single-(arg) path at FRMEVL_FUNC_ARG_PAREN.
; ----------------------------------------------------------------------
FRMEVL_FUNC_TOKEN_1:
        LD B,$00
        ; Double the index to a 2-byte (DEFW) offset into FUNC_DISPATCH_TBL.
        RLCA
        LD C,A
        PUSH BC
        CALL CHRGET
        LD A,C
        ; Doubled index < 5 (raw 0,1,2) = multi-argument string functions (STR_SUBSTR/LEFT$/RIGHT$); otherwise a single parenthesised argument.
        CP $05
        JP NC,FRMEVL_FUNC_ARG_PAREN
        CALL FRMEVL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL FP_INT_CHECK
        EX DE,HL
        LD HL,(FAC)
        EX (SP),HL
        PUSH HL
        EX DE,HL
        CALL GETBYT
        EX DE,HL
        EX (SP),HL
        JR FRMEVL_FUNC_DISPATCH
; ----------------------------------------------------------------------
; FRMEVL_FUNC_ARG_PAREN -- evaluate a single parenthesised function argument
;   In:        Doubled dispatch index on the stack; HL -> '(' of the argument; entered when the doubled index >= $05.
;   Out:       Argument value left in the FAC (promoted to single precision when the index falls in the math band); falls into FRMEVL_FUNC_ARG_PROMOTE then the dispatch tail.
;   Clobbers:  A, DE, HL, F, FAC, stack.
;   Algorithm: FRMEVL_PAREN evaluates the (expr) and consumes the ')'. Recover the doubled index (EX (SP),HL) and inspect L (= index*2): if L < $0C skip coercion; if $0C <= L < $1B call FN_CSNG to coerce the argument to single precision. [RE] That $0C..$1B band is doubled raw indices 6-13 = SQR/RND/SIN/LOG/EXP/COS/TAN/ATN -- the transcendental functions whose handlers want a single-precision float argument (enumerated from FUNC_DISPATCH_TBL).
; ----------------------------------------------------------------------
FRMEVL_FUNC_ARG_PAREN:
        ; Evaluate the parenthesised argument expression and consume the closing ')'.
        CALL FRMEVL_PAREN
        EX (SP),HL
        LD A,L
        CP $0C
        JR C,FRMEVL_FUNC_ARG_PROMOTE
        CP $1B
        PUSH HL
        ; [RE] Coerce the argument to single precision for the transcendental functions (raw indices 6-13: SQR/RND/SIN/LOG/EXP/COS/TAN/ATN).
        CALL C,FN_CSNG
        POP HL
; ----------------------------------------------------------------------
; FRMEVL_FUNC_ARG_PROMOTE -- arm the function return and mark function-eval in progress
;   In:        Doubled dispatch index on the stack (with the saved text pointer below it); argument staged in the FAC.
;   Out:       FRMEVL_PAREN_2 (POP HL; RET) pushed as the handler's return; L_0CB6 set to 1; falls into FRMEVL_FUNC_DISPATCH.
;   Clobbers:  A, DE, F.
;   Algorithm: Push FRMEVL_PAREN_2 so the function handler, when it RETs, pops the saved text pointer and returns through it. Set L_0CB6 = 1. [RE] L_0CB6 here is the FRMEVL function-evaluation-in-progress flag (cleared to 0 by XOR A; LD (L_0CB6),A at FRMEVL_OPLOOP $3A82). DUAL-USE CAVEAT: GFX_CLR_REVERSE_FLAG ($4539) treats the same cell $0CB6 as a screen reverse/INVERSE flag; the two uses are NOT reconciled, so the label is left unrenamed.
; ----------------------------------------------------------------------
FRMEVL_FUNC_ARG_PROMOTE:
        ; Arm FRMEVL_PAREN_2 (POP HL; RET) as the function handler's return path; its POP HL recovers the saved text pointer.
        LD DE,FRMEVL_PAREN_2
        PUSH DE
        LD A,$01
        ; [RE] Flag that a function argument is being evaluated (cleared at FRMEVL_OPLOOP $3A82). NOTE $0CB6 is also used as a screen-INVERSE flag elsewhere -- dual-use, unreconciled.
        LD (L_0CB6),A
; ----------------------------------------------------------------------
; FRMEVL_FUNC_DISPATCH -- jump to the selected function handler via FUNC_DISPATCH_TBL
;   In:        HL = the 2-byte (DEFW) index offset for the function (= raw index * 2, recovered from the stack by the argument paths); arguments staged in the FAC/stack.
;   Out:       Tail-jumps to the function's handler (via DISPATCH_VECTOR_HLBC). Does not return here.
;   Clobbers:  BC, HL (then per the target handler).
;   Algorithm: Load BC = FUNC_DISPATCH_TBL base and fall into DISPATCH_VECTOR_HLBC, which forms base + (index*2), loads the 16-bit handler address from that DEFW slot, and JP (HL). Because the index is already doubled, DISPATCH_VECTOR_HLBC's ADD HL,BC here just adds the pre-doubled offset to the base.
; ----------------------------------------------------------------------
FRMEVL_FUNC_DISPATCH:
        ; BC = function vector-table base; the doubled index offset is already in HL.
        LD BC,FUNC_DISPATCH_TBL
; ----------------------------------------------------------------------
; DISPATCH_VECTOR_HLBC -- indexed vector dispatch: jump through a DEFW table slot
;   In:        HL and BC such that HL+BC = the address of a 2-byte DEFW vector slot.
;   Out:       Jumps to the 16-bit address stored at (HL+BC). Never returns here (control leaves via JP (HL)); a caller wanting a return either pushes one first or CALLs this routine.
;   Clobbers:  HL, C (C reused to hold the target's low byte).
;   Algorithm: ADD HL,BC to address the slot, read the little-endian target word (C=low byte, then H=high byte), set L=C so HL=target, JP (HL). Two callers split base/offset differently: FRMEVL_FUNC_DISPATCH passes BC=FUNC_DISPATCH_TBL base and HL=index*2 (pre-doubled); FRMEVL_APPLY_OP ($3FFF) passes HL=OPERATOR_ROUTINE_TBL+rawindex and BC=rawindex, so its ADD HL,BC adds rawindex a second time, effectively doubling the raw index. Either way HL+BC must equal the slot address.
; ----------------------------------------------------------------------
DISPATCH_VECTOR_HLBC:
        ; Form the address of the DEFW vector slot (HL+BC).
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        ; Jump to the handler address read from the slot.
        JP (HL)
; ----------------------------------------------------------------------
; FIN_EXP_SIGN_SCAN -- consume an optional leading sign while scanning a number's exponent
;   In:        A = current char (the char after the 'E'/'D' exponent marker in a numeric literal); D = exponent-sign accumulator (FIN_7 pre-loads it); HL -> that char.
;   Out:       RET with D toggled per the sign: '-' (raw $2D or token TOK_MINUS $F3) leaves D decremented (sign flipped); '+' (raw $2B or token TOK_PLUS $F2) leaves D unchanged (the DEC/INC cancel). Neither sign -> DEC HL backs the pointer up so the caller re-reads the char as the first exponent digit, then RET. Z is set when a sign matched (incidental: the caller FIN_8 re-reads via CHRGET and does not consume this Z).
;   Clobbers:  D, HL, F.
;   Algorithm: Pre-decrement D, then test the two minus encodings (TOK_MINUS $F3, ASCII '-' $2D) -- a match RETs with the toggle applied. For plus, INC D undoes the pre-decrement before testing '+' ($2B) and TOK_PLUS ($F2). No match -> DEC HL (push the char back) and RET. [RE] Sole caller is the FIN number scanner's exponent handler (FIN_7 $551A, reached on 'D'/'d'/'E'); FIN_8 ($552A) does INC D / JR NZ then negates the exponent E when D wrapped to 0 -- so D's value here is the exponent sign. This is an exponent-sign scan, NOT a general unary-operator factor prescan.
; ----------------------------------------------------------------------
FIN_EXP_SIGN_SCAN:
        ; Tentatively flip the exponent-sign accumulator; undone below for the '+' / no-sign cases.
        DEC D
        CP TOK_MINUS
        RET Z
        CP $2D
        RET Z
        ; Cancel the tentative flip for the '+' / no-sign cases.
        INC D
        CP $2B
        RET Z
        CP TOK_PLUS
        RET Z
        ; No sign present: back up so the caller re-reads this char as the first exponent digit.
        DEC HL
        RET
; ----------------------------------------------------------------------
; FRMEVL_RELOP_RESULT -- turn a comparison's flags + relation mask into a BASIC truth value
;   In:        A = ordering result of the just-applied numeric comparison (sign of left-right, one of $FF/$00/$01); the requested relation mask is on the stack (it was accumulated in D by FRMEVL_RELOP and pushed via PUSH DE in FRMEVL_ARITHOP, so POP BC recovers it into B).
;   Out:       FAC = 0 (false) or -1 (true) as a VT_INT integer (via INT16_TO_FP); continues into FRMEVL_OPLOOP_2 via the shared tail _3.
;   Clobbers:  A, BC, HL, F, FAC.
;   Algorithm: This routine is pushed as a RETURN ADDRESS by FRMEVL_ARITHOP ($3B3F LD HL,this; PUSH HL) so the comparison kernel RETs into it. INC A then ADC A,A maps the ordering code into a small index; POP BC recovers the relation mask into B; AND B tests whether the requested relation holds; ADD $FF then SBC A,A folds non-zero -> $FF (true,-1) and zero -> $00 (false), which INT16_TO_FP stores as a 16-bit integer in the FAC. [RE] The exact bit assignment of the INC A;ADC A,A index is the canonical MS BASIC relational fold; the precise {LT,EQ,GT} bit positions were not pinned and are not load-bearing here.
; ----------------------------------------------------------------------
FRMEVL_RELOP_RESULT:
        INC A
        ADC A,A
        ; Recover the requested relation mask into B (accumulated in D by FRMEVL_RELOP, pushed via PUSH DE).
        POP BC
        ; Keep only the bit matching the actual ordering: non-zero iff the requested relation holds.
        AND B
        ADD A,$FF
        ; Fold to BASIC truth: -1 (true) when the relation held, 0 (false) otherwise.
        SBC A,A
        CALL INT16_TO_FP
        JR FRMEVL_RESULT_DONE
; ----------------------------------------------------------------------
; FRMEVL_NOT -- evaluate the NOT operator (bitwise one's-complement of an integer)
;   In:        HL -> source just past the NOT token; entered from FRMEVL_EVAL_OPERAND ($3C1F) on token TOK_NOT ($E4).
;   Out:       FAC = NOT(operand) as a VT_INT integer; continues into the operator loop via the shared tail _3 (JP FRMEVL_OPLOOP_2).
;   Clobbers:  A, BC, D, HL, F, FAC.
;   Algorithm: Set D = $5A (the binding precedence passed to FRMEVL_OPLOOP) and CALL FRMEVL_OPLOOP to evaluate the operand at that precedence. FN_CINT coerces it to a 16-bit integer in HL, both bytes are CPL'd (one's complement), the result is stored to the FAC (LD (FAC),HL; type stays integer from FN_CINT), POP BC discards the saved precedence frame, then fall into _3 -> JP FRMEVL_OPLOOP_2 to resume operator scanning. [RE] $5A read as NOT's operator precedence (the D byte FRMEVL_OPLOOP saves as 'pending-operator precedence').
; ----------------------------------------------------------------------
FRMEVL_NOT:
        ; [RE] D = NOT's binding precedence; FRMEVL_OPLOOP evaluates the operand bound at this level.
        LD D,$5A
        CALL FRMEVL_OPLOOP
        ; NOT operates on integers: coerce the operand to a 16-bit int before complementing.
        CALL FN_CINT
        LD A,L
        CPL
        LD L,A
        LD A,H
        CPL
        LD H,A
        LD (FAC),HL
        POP BC
; ----------------------------------------------------------------------
; FRMEVL_RESULT_DONE -- shared tail that resumes the operator loop after a NOT or relational result
;   In:        Result already in the FAC; pending-operator frame restored.
;   Out:       Jumps to FRMEVL_OPLOOP_2 to continue evaluating any following binary operators.
;   Clobbers:  (none of its own).
;   Algorithm: Single JP FRMEVL_OPLOOP_2 -- shared continuation reached BOTH from FRMEVL_NOT (fall-through) AND from FRMEVL_RELOP_RESULT (JR _3).
; ----------------------------------------------------------------------
FRMEVL_RESULT_DONE:
        JP FRMEVL_OPLOOP_2
; ----------------------------------------------------------------------
; FRMEVL_TEST_TYPE -- classify the current value's type from VALTYP and return it in the flags
;   In:        VALTYP ($0B14) = storage width of the FAC value (VT_INT=2, VT_STR=3, VT_SNG=4, VT_DBL=8).
;   Out:       Flags encode the type (verified byte-for-byte): Z set <=> string (VALTYP==3); carry set <=> VALTYP < 8 (i.e. NOT double, because the >=8 path's OR A clears carry and there is no SCF there); sign M set <=> integer (VALTYP==2, since 2-3=$FF). A = VALTYP-3.
;   Clobbers:  A, F.
;   Algorithm: Load VALTYP and CP $08 to split double (>= 8) from the rest. On the < 8 path: SUB $03 (int->$FF/M, string->$00/Z, single->$01/P), OR A to set S/Z, then SCF (carry SET unconditionally). On the >= 8 (double) path: the same SUB $03; OR A, but NO SCF, so OR A leaves carry CLEAR. Callers (FN_CSNG/FN_CDBL/FN_CINT, CRUNCH type split, PRINT type split) branch on Z for string and on carry for double-vs-rest.
; ----------------------------------------------------------------------
FRMEVL_TEST_TYPE:
        LD A,(VALTYP)
        ; Split double precision (VALTYP>=8) from int/string/single.
        CP $08
        JR NC,FRMEVL_TEST_TYPE_1
        SUB $03
        OR A
        SCF
        RET
; ----------------------------------------------------------------------
; FRMEVL_TEST_TYPE_1 -- double-precision tail of the VALTYP type test (carry left clear)
;   In:        A = VALTYP, reached (via JR NC) with VALTYP >= 8 (double).
;   Out:       A = VALTYP-3 (=5 for VT_DBL); Z clear, sign positive, carry CLEAR -- the cleared carry signals 'this value is double precision'. RET.
;   Clobbers:  A, F.
;   Algorithm: SUB $03; OR A; RET. Identical arithmetic to the main path but WITHOUT the SCF, so OR A leaves carry clear and the double case is distinguished purely by carry-clear. Not an independent entry point (only the internal JR NC reaches it).
; ----------------------------------------------------------------------
FRMEVL_TEST_TYPE_1:
        SUB $03
        OR A
        RET
; ----------------------------------------------------------------------
; FRMEVL_INT_OP_HANDLER -- integer binary-op kernel. In: B=dispatch; FAC=right operand; LEFT on stack. PUSH BC; FN_CINT->HL; POP AF->dispatch; POP DE->LEFT.
; ----------------------------------------------------------------------
FRMEVL_INT_OP_HANDLER:
        PUSH BC
        CALL FN_CINT
        POP AF
        ; DE = left operand (pushed before recursing on the right operand)
        POP DE
        CP $7A
        JP Z,INT_DIV_ROUND
        CP $7B
        JP Z,INT_DIV_KERNEL
        LD BC,FP_LOAD_INT_TO_FAC_1
        PUSH BC
        CP $46
        JR NZ,INT_OP_AND
        LD A,E
        OR L
        LD L,A
        LD A,H
        OR D
        RET
; ----------------------------------------------------------------------
; INT_OP_AND -- AND arm (50): L=E&L,A=H&D. MIS-NAMED.
; ----------------------------------------------------------------------
INT_OP_AND:
        CP $50
        JR NZ,INT_OP_XOR
        LD A,E
        AND L
        LD L,A
        LD A,H
        AND D
        RET
; ----------------------------------------------------------------------
; INT_OP_XOR -- XOR arm (3C): L=E^L,A=H^D. MIS-NAMED.
; ----------------------------------------------------------------------
INT_OP_XOR:
        CP $3C
        JR NZ,INT_OP_EQV
        LD A,E
        XOR L
        LD L,A
        LD A,H
        XOR D
        RET
; ----------------------------------------------------------------------
; INT_OP_EQV -- EQV arm (32): NOT(a XOR b). MIS-NAMED.
; ----------------------------------------------------------------------
INT_OP_EQV:
        CP $32
        JR NZ,INT_OP_IMP
        LD A,E
        XOR L
        CPL
        LD L,A
        LD A,H
        XOR D
        CPL
        RET
; ----------------------------------------------------------------------
; INT_OP_IMP -- IMP arm (28): (NOT a) OR b. MIS-NAMED.
; ----------------------------------------------------------------------
INT_OP_IMP:
        LD A,L
        CPL
        AND E
        CPL
        LD L,A
        LD A,H
        CPL
        AND D
        CPL
        RET
; ----------------------------------------------------------------------
; FP_INT_SUB_TO_FAC -- subtract HL-DE then INT_TO_SNG. STANDALONE; caller FN_FRE (line 13375).
; ----------------------------------------------------------------------
FP_INT_SUB_TO_FAC:
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        JP INT_TO_SNG
; [RE] LPOS(x) handler (function token $1A): current line-printer column (($0837)) into the FAC.
FN_LPOS:
        LD A,(OUTPUT_COLUMN)
        JR FN_POS_1
; [RE] POS(x) handler (function token $10): current console output column (($0B11)+1) into the FAC; shares the integer-load tail with FP_LOAD_INT_TO_FAC.
FN_POS:
        LD A,(L_0B11)
FN_POS_1:
        INC A
; [RE] Store the 8-bit value in A (zero-extended to HL) as an integer into the FAC via FP_STORE_FAC_INT.
FP_LOAD_INT_TO_FAC:
        LD L,A
        XOR A
FP_LOAD_INT_TO_FAC_1:
        LD H,A
        JP FP_STORE_FAC_INT
FP_LOAD_INT_TO_FAC_2:
        CALL USRVEC_ADDR
        PUSH DE
        CALL FRMEVL_PAREN
        EX (SP),HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD HL,FMUL_7
        PUSH HL
        PUSH BC
        LD A,(VALTYP)
        PUSH AF
        CP $03
        CALL Z,FRESTR
        POP AF
        EX DE,HL
        LD HL,FAC
        RET
; [RE] Compute the address of a USR(n) dispatch vector: base $081F + (digit index*2 from $0B1B if a numeric suffix follows the USR token), returned in DE. Used by DEF USR / USR-call setup.
USRVEC_ADDR:
        CALL CHRGET
        LD BC,$0000
        CP $1B
        JR NC,USRVEC_ADDR_1
        CP $11
        JR C,USRVEC_ADDR_1
        CALL CHRGET
        LD A,(CONST_VALUE)
        OR A
        RLA
        LD C,A
USRVEC_ADDR_1:
        EX DE,HL
        LD HL,L_081F
        ADD HL,BC
        EX DE,HL
        RET
USRVEC_ADDR_2:
        CALL USRVEC_ADDR
        PUSH DE
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        CALL GETINT
        EX (SP),HL
        LD (HL),E
        INC HL
        LD (HL),D
        POP HL
        RET
; [RE] DEF statement handler (token $96): DEF FN user-function definition / DEF USR (CP $E1 = USR token).
STMT_DEF:
        CP $E1
        JR Z,USRVEC_ADDR_2
        CALL GETVAR_NAME
        CALL CHECK_MEM_TOP
        EX DE,HL
        LD (HL),E
        INC HL
        LD (HL),D
        EX DE,HL
        LD A,(HL)
        CP $28
        JP NZ,STMT_DATA
        CALL CHRGET
STMT_DEF_1:
        CALL PTRGET_1+1
        LD A,(HL)
        CP $29
        JP Z,STMT_DATA
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        JR STMT_DEF_1
STMT_DEF_2:
        CALL GETVAR_NAME
        LD A,(VALTYP)
        OR A
        PUSH AF
        LD (FRMEVL_TXTPTR_TEMP),HL
        EX DE,HL
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        OR H
        JP Z,RAISE_UNDEFINED_USER_FUNCTION
        LD A,(HL)
        CP $28
        JP NZ,STMT_DEF_8+1
        CALL CHRGET
        LD (L_0B4A),HL
        EX DE,HL
        LD HL,(FRMEVL_TXTPTR_TEMP)
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        XOR A
        PUSH AF
        PUSH HL
        EX DE,HL
STMT_DEF_3:
        LD A,$80
        LD (PTRGET_SUBSCRIPT_FLAG),A
        CALL PTRGET_1+1
        EX DE,HL
        EX (SP),HL
        LD A,(VALTYP)
        PUSH AF
        PUSH DE
        CALL FRMEVL_NOPAREN
        LD (FRMEVL_TXTPTR_TEMP),HL
        POP HL
        LD (L_0B4A),HL
        POP AF
        CALL FRMEVL_APPLY_OP
        LD C,$04
        CALL CHECK_STACK_ROOM
        LD HL,$FFF8
        ADD HL,SP
        LD SP,HL
        CALL FP_ARG_SETUP2
        LD A,(VALTYP)
        PUSH AF
        LD HL,(FRMEVL_TXTPTR_TEMP)
        LD A,(HL)
        CP $29
        JR Z,STMT_DEF_5
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        LD HL,(L_0B4A)
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        JR STMT_DEF_3
STMT_DEF_4:
        POP AF
        LD (L_0BFB),A
STMT_DEF_5:
        POP AF
        OR A
        JR Z,STMT_DEF_7
        LD (VALTYP),A
        LD HL,$0000
        ADD HL,SP
        CALL FP_ARG_SETUP1
        LD HL,$0008
        ADD HL,SP
        LD SP,HL
        POP DE
        LD L,$03
STMT_DEF_6:
        INC L
        DEC DE
        LD A,(DE)
        OR A
        JP M,STMT_DEF_6
        DEC DE
        DEC DE
        DEC DE
        LD A,(VALTYP)
        ADD A,L
        LD B,A
        LD A,(L_0BFB)
        LD C,A
        ADD A,B
        CP $64
        JP NC,ERROR_FC
        PUSH AF
        LD A,L
        LD B,$00
        LD HL,L_0BFD
        ADD HL,BC
        LD C,A
        CALL BLOCK_COPY_DE_HL
        LD BC,STMT_DEF_4
        PUSH BC
        PUSH BC
        JP STMT_LET_3
STMT_DEF_7:
        LD HL,(FRMEVL_TXTPTR_TEMP)
        CALL CHRGET
        PUSH HL
        LD HL,(L_0B4A)
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
; [RE] PUSH-skip cover. 3E D5 = LD A,$D5: the fall-through (parenthesized DEF FN arglist done, from STMT_DEF_7 $3F6E CALL SYNCHR/$3F71 DEFB ')') absorbs the D5 and skips a PUSH DE. JP NZ,STMT_DEF_8+1 at $3EC4 (no-paren function ref, when $3EC2 CP $28 fails) lands on the bare D5 = PUSH DE to save the text pointer; both then fall into LD ($0B4A),HL at $3F74. Independently verified; confirmed against MBASIC label shift.
STMT_DEF_8:
        LD A,$D5
        LD (L_0B4A),HL
        LD A,(L_0B93)
        ADD A,$04
        PUSH AF
        RRCA
        LD C,A
        CALL CHECK_STACK_ROOM
        POP AF
        LD C,A
        CPL
        INC A
        LD L,A
        LD H,$FF
        ADD HL,SP
        LD SP,HL
        PUSH HL
        LD DE,L_0B91
        CALL BLOCK_COPY_DE_HL
        POP HL
        LD (L_0B91),HL
        LD HL,(L_0BFB)
        LD (L_0B93),HL
        LD B,H
        LD C,L
        LD HL,L_0B95
        LD DE,L_0BFD
        CALL BLOCK_COPY_DE_HL
        LD H,A
        LD L,A
        LD (L_0BFB),HL
        LD HL,(L_0C67)
        INC HL
        LD (L_0C67),HL
        LD A,H
        OR L
        LD (L_0C64),A
        LD HL,(L_0B4A)
        CALL EVAL_EXPR_AFTER_SYNCHR
        DEC HL
        CALL CHRGET
        JP NZ,RAISE_SYNTAX_ERROR
        CALL FRMEVL_TEST_TYPE
        JR NZ,STMT_DEF_9
        LD DE,DSCTMP
        LD HL,(FAC)
        CALL CMP_HL_DE
        JR C,STMT_DEF_9
        CALL STR_BUILD_FROM_DESC
        CALL PUT_STR_TEMP_1+1
STMT_DEF_9:
        LD HL,(L_0B91)
        LD D,H
        LD E,L
        INC HL
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC BC
        INC BC
        INC BC
        INC BC
        LD HL,L_0B91
        CALL BLOCK_COPY_DE_HL
        EX DE,HL
        LD SP,HL
        LD HL,(L_0C67)
        DEC HL
        LD (L_0C67),HL
        LD A,H
        OR L
        LD (L_0C64),A
        POP HL
        POP AF
; ----------------------------------------------------------------------
; FRMEVL_APPLY_OP -- coerce FAC via OPERATOR_ROUTINE_TBL[A&7]; HL preserved.
; ----------------------------------------------------------------------
FRMEVL_APPLY_OP:
        PUSH HL
        AND $07
        LD HL,OPERATOR_ROUTINE_TBL
        LD C,A
        LD B,$00
        ADD HL,BC
        CALL DISPATCH_VECTOR_HLBC
        POP HL
        RET
; ----------------------------------------------------------------------
; BLOCK_COPY_DE_HL_LOOP -- loop body of BLOCK_COPY_DE_HL. MIS-NAMED.
; ----------------------------------------------------------------------
BLOCK_COPY_DE_HL_LOOP:
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        DEC BC
; [RE] Copy BC bytes from (DE) to (HL), ascending (LDI-style hand loop). General memory-move helper used by DEF FN parameter save/restore and variable-table shuffling.
BLOCK_COPY_DE_HL:
        LD A,B
        OR C
        JR NZ,BLOCK_COPY_DE_HL_LOOP
        RET
; [RE] Variable-space overflow guard: if the free-space-remaining counter ($0844) has wrapped to 0, raise 'Out of memory' (E=$0C) via RAISE_ERROR. Called before allocating variable/array storage.
CHECK_MEM_TOP:
        PUSH HL
        LD HL,(SAVTXT)
        INC HL
        LD A,H
        OR L
        POP HL
        RET NZ
        LD E,ERR_ILLEGAL_DIRECT
        JP RAISE_ERROR
; [RE] Fetch and validate a variable-name token after SYNCHR: requires an alphabetic first char (JP PO on letter test), records the name in $0B52, then resolves it via PTRGET (PTRGET_2).
GETVAR_NAME:
        CALL SYNCHR
        DEFB    TOK_FN                   ; inline keyword-token arg consumed by the preceding CALL
        LD A,$80
        LD (PTRGET_SUBSCRIPT_FLAG),A
        OR (HL)
        LD C,A
        JP PTRGET_2
GETVAR_NAME_1:
        CP $7E
        JP NZ,RAISE_SYNTAX_ERROR
        INC HL
        LD A,(HL)
        CP $83
        JP NZ,RAISE_SYNTAX_ERROR
        INC HL
        JP STMT_MID_ASSIGN
        JP RAISE_SYNTAX_ERROR
; [RE] WIDTH statement handler (token $9D): set console/printer output line width (CP $9B tests for LPRINT form).
STMT_WIDTH:
        CP $9B
        JR NZ,STMT_WIDTH_1
        CALL CHRGET
        CALL GETBYT
        LD (L_083A),A
        LD E,A
        CALL WIDTH_CLAMP_COLUMN
        LD (L_0839),A
        RET
STMT_WIDTH_1:
        CP $2C
        JR Z,WIDTH_SET_CONSOLE_1
        CALL GETBYT
; [RE] WIDTH continuation: parse 'WIDTH #file,width' branch - stores file-width to $083B/$083D, then handles optional ',pos' second field.
WIDTH_SET_CONSOLE:
        LD (PRINT_WIDTH),A
        LD E,A
        CALL WIDTH_CLAMP_COLUMN
        LD (WIDTH_FILE),A
        LD A,(HL)
        CP $2C
        RET NZ
WIDTH_SET_CONSOLE_1:
        CALL CHRGET
        CALL GETBYT
        LD (PAGE_LENGTH),A
        RET
; [RE] WIDTH helper: fold the requested column count into the valid 1..n range by repeated SUB $0E, then bias by E (original value); returns the clamped width byte.
WIDTH_CLAMP_COLUMN:
        SUB $0E
        JR NC,WIDTH_CLAMP_COLUMN
        ADD A,$1C
        CPL
        INC A
        ADD A,E
        RET
; [RE] MS BASIC GETINT entry: advance the text pointer (CHRGET) then evaluate a numeric expression and return it as a 16-bit integer (falls into GETINT).
GETINT_CHRGET:
        CALL CHRGET
; [RE] MS BASIC GETINT: evaluate expression at the text pointer (FRMEVL), convert FAC to signed 16-bit (FN_LPOS) into DE; flags set from high byte.
GETINT:
        CALL FRMEVL_NOPAREN
; [RE] Convert current numeric value (FAC) to a 16-bit integer in DE via FN_LPOS; A=high byte, OR A sets Z if value fits in one byte (used by GETBYT/POKE/PEEK).
FRC_INT_DE:
        PUSH HL
        CALL FN_CINT
        EX DE,HL
        POP HL
        LD A,D
        OR A
        RET
; [RE] MS BASIC GETBYT entry: advance the text pointer (CHRGET) then fall into GETBYT (0..255 byte evaluator).
GETBYT_CHRGET:
        CALL CHRGET
; [RE] MS BASIC GETBYT: evaluate expression (FRMEVL) then fall into CONINT to range-check it as a 0..255 byte in A/E.
GETBYT:
        CALL FRMEVL_NOPAREN
; [RE] MS BASIC CONINT: require the integer to fit in one byte - convert via FRC_INT_DE and 'Illegal function call' (GETINT_POSITIVE_1) if the high byte is non-zero; returns the byte in A and E.
CONINT:
        CALL FRC_INT_DE
        JP NZ,ERROR_FC
        DEC HL
        CALL CHRGET
        LD A,E
        RET
; [RE] LLIST statement handler (token $9C): LIST directed to the line printer (sets printer flag then joins LIST).
STMT_LLIST:
        LD A,$01
        LD (PRTFLG),A
; [RE] LIST statement handler (token $93): detokenizes program lines to the console (uses the reserved-word table walk at $4178).
STMT_LIST:
        POP BC
        CALL SCAN_LINE_RANGE
        PUSH BC
        CALL ILLEGAL_DIRECT_CHECK
STMT_LIST_1:
        LD HL,$FFFF
        LD (SAVTXT),HL
        POP HL
        POP DE
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD A,B
        OR C
        JP Z,NEWSTT_READY
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        POP HL
STMT_LIST_2:
        CALL Z,RPC_CONST_POLL
        PUSH BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH BC
        EX (SP),HL
        EX DE,HL
        CALL CMP_HL_DE
        POP BC
        JP C,READY_POP_FRAME
        EX (SP),HL
        PUSH HL
        PUSH BC
        EX DE,HL
        LD (ERRLIN),HL
        CALL FOUT
        POP HL
        LD A,(HL)
        CP $09
        JR Z,STMT_LIST_3
        LD A,$20
        CALL OUTCHR
STMT_LIST_3:
        CALL DETOKENIZE_LINE
        LD HL,BUF
        CALL PRINT_ZSTRING
        CALL CRLF
        JR STMT_LIST_1
; [RE] Print a $00-terminated message byte-by-byte through OUTCHR_LF_EXPAND (console out); used by LIST to emit the post-line trailer text at $0A0E.
PRINT_ZSTRING:
        LD A,(HL)
        OR A
        RET Z
        CALL OUTCHR_LF_EXPAND
        INC HL
        JR PRINT_ZSTRING

; ======================================================================
; LIST / DETOKENIZER (uncrunch token -> ASCII)
; ======================================================================
; [RE] LIST de-tokenizer: expand a crunched line back to ASCII into a buffer (BC=dest, D=remaining length). Copies literal bytes, and for reserved-word tokens (>= $0B) looks the keyword name up (IS_ALNUM_CHAR) and copies its spelling. Used by LIST and by the sign-on/error formatting. $0C93 tracks inter-token spacing.
DETOKENIZE_LINE:
        LD BC,BUF
        LD D,$FF
        XOR A
        LD (L_0C93),A
        CALL ILLEGAL_DIRECT_CHECK
        JR DETOKENIZE_LINE_2
DETOKENIZE_LINE_1:
        INC BC
        INC HL
        DEC D
        RET Z
DETOKENIZE_LINE_2:
        LD A,(HL)
        OR A
        LD (BC),A
        RET Z
        CP $0B
        JR C,DETOKENIZE_LINE_3
        CP $20
        LD E,A
        JR C,DETOKENIZE_LINE_4
DETOKENIZE_LINE_3:
        OR A
        JP M,DETOKENIZE_LINE_8
        LD E,A
        CP $2E
        JR Z,DETOKENIZE_LINE_4
        CALL IS_ALNUM_CHAR
        JP NC,DETOKENIZE_LINE_4
        XOR A
        JR DETOKENIZE_LINE_6
DETOKENIZE_LINE_4:
        LD A,(L_0C93)
        OR A
        JR Z,DETOKENIZE_LINE_5
        INC A
        JR NZ,DETOKENIZE_LINE_5
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        RET Z
DETOKENIZE_LINE_5:
        LD A,$01
DETOKENIZE_LINE_6:
        LD (L_0C93),A
        LD A,E
        CP $0B
        JR C,DETOKENIZE_LINE_7
        CP $20
        JP C,IS_ALNUM_CHAR_1
DETOKENIZE_LINE_7:
        LD (BC),A
        JR DETOKENIZE_LINE_1
DETOKENIZE_LINE_8:
        INC A
        LD A,(HL)
        JR NZ,DETOKENIZE_LINE_9
        INC HL
        LD A,(HL)
        AND $7F
DETOKENIZE_LINE_9:
        INC HL
        CP $EA
        JR NZ,DETOKENIZE_LINE_10
        DEC BC
        DEC BC
        DEC BC
        DEC BC
        INC D
        INC D
        INC D
        INC D
DETOKENIZE_LINE_10:
        CP TOK_ELSE
        CALL Z,DEC_BC
        PUSH HL
        PUSH BC
        PUSH DE
        LD HL,RESWORD_INDEX+51
        LD B,A
        LD C,$40
DETOKENIZE_LINE_11:
        INC C
DETOKENIZE_LINE_12:
        INC HL
        LD D,H
        LD E,L
DETOKENIZE_LINE_13:
        LD A,(HL)
        OR A
        JR Z,DETOKENIZE_LINE_11
        INC HL
        JP P,DETOKENIZE_LINE_13
        LD A,(HL)
        CP B
        JR NZ,DETOKENIZE_LINE_12
        EX DE,HL
        CP $E1
        JR Z,DETOKENIZE_LINE_14
        CP TOK_FN
DETOKENIZE_LINE_14:
        LD A,C
        POP DE
        POP BC
        LD E,A
        JR NZ,DETOKENIZE_LINE_15
        LD A,(L_0C93)
        OR A
        LD A,$00
        LD (L_0C93),A
        JR DETOKENIZE_LINE_17
DETOKENIZE_LINE_15:
        CP $5B
        JR NZ,DETOKENIZE_LINE_16
        XOR A
        LD (L_0C93),A
        JR DETOKENIZE_LINE_19
DETOKENIZE_LINE_16:
        LD A,(L_0C93)
        OR A
        LD A,$FF
        LD (L_0C93),A
DETOKENIZE_LINE_17:
        JR Z,DETOKENIZE_LINE_18
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        JP Z,GETSPA_2
DETOKENIZE_LINE_18:
        LD A,E
        JR DETOKENIZE_LINE_20
DETOKENIZE_LINE_19:
        LD A,(HL)
        INC HL
        LD E,A
DETOKENIZE_LINE_20:
        AND $7F
        LD (BC),A
        INC BC
        DEC D
        JP Z,GETSPA_2
        OR E
        JP P,DETOKENIZE_LINE_19
        CP $A8
        JR NZ,DETOKENIZE_LINE_21
        XOR A
        LD (L_0C93),A
DETOKENIZE_LINE_21:
        POP HL
        JP DETOKENIZE_LINE_2
; [RE] LIST detokenizer helper: classify the next program byte - returns NC for an alpha/keyword char, C (with CCF) for ASCII digit 0-9, controlling whether DETOKENIZE_LINE treats it as a reserved-word token or literal.
IS_ALNUM_CHAR:
        CALL IS_LETTER_A
        RET NC
        CP $30
        RET C
        CP $3A
        CCF
        RET
IS_ALNUM_CHAR_1:
        DEC HL
        CALL CHRGET
        PUSH DE
        PUSH BC
        PUSH AF
        CALL CHRGOT_CONST_VALUE
        POP AF
        LD BC,IS_ALNUM_CHAR_2
        PUSH BC
        CP $0B
        JP Z,HEX_OCT_OUT
        CP $0C
        JP Z,HEX_OCT_OUT_1+1
        LD HL,(CONST_VALUE)
        JP FOUT_2
IS_ALNUM_CHAR_2:
        POP BC
        POP DE
        LD A,(CONST_TOKEN)
        LD E,$4F
        CP $0B
        JR Z,IS_ALNUM_CHAR_3
        CP $0C
        LD E,$48
        JR NZ,IS_ALNUM_CHAR_4
IS_ALNUM_CHAR_3:
        LD A,$26
        LD (BC),A
        INC BC
        DEC D
        RET Z
        LD A,E
        LD (BC),A
        INC BC
        DEC D
        RET Z
IS_ALNUM_CHAR_4:
        LD A,(CONST_VALTYP)
        CP $04
        LD E,$00
        JR C,IS_ALNUM_CHAR_5
        LD E,$21
        JR Z,IS_ALNUM_CHAR_5
        LD E,$23
IS_ALNUM_CHAR_5:
        LD A,(HL)
        CP $20
        CALL Z,FP_LOAD_DONE
IS_ALNUM_CHAR_6:
        LD A,(HL)
        INC HL
        OR A
        JR Z,IS_ALNUM_CHAR_9
        LD (BC),A
        INC BC
        DEC D
        RET Z
        LD A,(CONST_VALTYP)
        CP $04
        JR C,IS_ALNUM_CHAR_6
        DEC BC
        LD A,(BC)
        INC BC
        JR NZ,IS_ALNUM_CHAR_7
        CP $2E
        JR Z,IS_ALNUM_CHAR_8
IS_ALNUM_CHAR_7:
        CP $44
        JR Z,IS_ALNUM_CHAR_8
        CP $45
        JR NZ,IS_ALNUM_CHAR_6
IS_ALNUM_CHAR_8:
        LD E,$00
        JR IS_ALNUM_CHAR_6
IS_ALNUM_CHAR_9:
        LD A,E
        OR A
        JR Z,IS_ALNUM_CHAR_10
        LD (BC),A
        INC BC
        DEC D
        RET Z
IS_ALNUM_CHAR_10:
        LD HL,(CONST_TEXT_RESUME)
        JP DETOKENIZE_LINE_2
; [RE] DELETE statement handler (token $A6): delete a range of program lines (CALL $0F61 parses the range).
STMT_DELETE:
        CALL SCAN_LINE_RANGE
        PUSH BC
        CALL RENUM_FIXUP_IF_PENDING
        POP BC
        POP DE
        PUSH BC
        PUSH BC
        CALL FNDLIN
        JR NC,STMT_DELETE_1
        LD D,H
        LD E,L
        EX (SP),HL
        PUSH HL
        CALL CMP_HL_DE
STMT_DELETE_1:
        JP NC,ERROR_FC
        LD HL,MSG_OK
        CALL STROUT
        POP BC
        LD HL,SUB_0EB7_4
        EX (SP),HL
; [RE] Copy a string from (DE) into the string pool growing at $0B6F, byte-by-byte via CMP_HL_DE until done; updates the $0B6F string-area pointer. Used by DELETE/edit to relocate text.
BLOCK_MOVE_TO_VARTAB:
        EX DE,HL
        LD HL,(VARTAB)
BLOCK_MOVE_TO_VARTAB_1:
        LD A,(DE)
        LD (BC),A
        INC BC
        INC DE
        CALL CMP_HL_DE
        JR NZ,BLOCK_MOVE_TO_VARTAB_1
        LD H,B
        LD L,C
        LD (VARTAB),HL
        RET
; [RE] PEEK(addr) handler (function token $16): read one memory byte at addr into the FAC.
FN_PEEK:
        CALL GETADR
        CALL DIRECT_MODE_GUARD
        LD A,(HL)
        JP FP_LOAD_INT_TO_FAC
; [RE] POKE statement handler (token $97): evaluate address,value then store to memory.
STMT_POKE:
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL GETADR
        EX (SP),HL
        CALL DIRECT_MODE_GUARD
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        POP DE
        LD (DE),A
        RET
; [RE] MS BASIC GETADR: evaluate FAC and convert to an unsigned 16-bit address in BC/$9180-bias form (for POKE/PEEK); rejects out-of-range via FADD_ALIGN. Pushes FN_LPOS as the integer-fetch continuation.
GETADR:
        LD BC,FN_CINT
        PUSH BC
        CALL FRMEVL_TEST_TYPE
        RET M
        LD A,(L_0CB4)
        CP $90
        RET NZ
        LD A,(FACHI)
        OR A
        RET M
        LD BC,$9180
        LD DE,$0000
        JP FADD_ALIGN
; [RE] RENUM statement handler (token $A8): renumber program lines (defaults start/step in the LD BC,$000A).
STMT_RENUM:
        LD BC,$000A
        PUSH BC
        LD D,B
        LD E,B
        JR Z,STMT_RENUM_2
        CP $2C
        JR Z,STMT_RENUM_1
        PUSH DE
        CALL LINGET_DOT
        LD B,D
        LD C,E
        POP DE
        JR Z,STMT_RENUM_2
STMT_RENUM_1:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL LINGET_DOT
        JR Z,STMT_RENUM_2
        POP AF
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        PUSH DE
        CALL LINGET
        JP NZ,RAISE_SYNTAX_ERROR
        LD A,D
        OR E
        JP Z,ERROR_FC
        EX DE,HL
        EX (SP),HL
        EX DE,HL
STMT_RENUM_2:
        PUSH BC
        CALL FNDLIN
        POP DE
        PUSH DE
        PUSH BC
        CALL FNDLIN
        LD H,B
        LD L,C
        POP DE
        CALL CMP_HL_DE
        EX DE,HL
        JP C,ERROR_FC
        POP DE
        POP BC
        POP AF
        PUSH HL
        PUSH DE
        JR STMT_RENUM_4
STMT_RENUM_3:
        ADD HL,BC
        JP C,ERROR_FC
        EX DE,HL
        PUSH HL
        LD HL,$FFF9
        CALL CMP_HL_DE
        POP HL
        JP C,ERROR_FC
STMT_RENUM_4:
        PUSH DE
        LD E,(HL)
        LD A,E
        INC HL
        LD D,(HL)
        OR D
        EX DE,HL
        POP DE
        JR Z,STMT_RENUM_5
        LD A,(HL)
        INC HL
        OR (HL)
        DEC HL
        EX DE,HL
        JR NZ,STMT_RENUM_3
STMT_RENUM_5:
        PUSH BC
        CALL STMT_RENUM_8+1
        POP BC
        POP DE
        POP HL
STMT_RENUM_6:
        PUSH DE
        LD E,(HL)
        LD A,E
        INC HL
        LD D,(HL)
        OR D
        JR Z,STMT_RENUM_7
        EX DE,HL
        EX (SP),HL
        EX DE,HL
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        EX DE,HL
        ADD HL,BC
        EX DE,HL
        POP HL
        JR STMT_RENUM_6
STMT_RENUM_7:
        LD BC,READY_POP_FRAME
        PUSH BC
; [RE] Flag-skip into RENUM line-ref pass setup. FE F6 = CP $F6: fall-through (from PUSH BC at $436F) absorbs F6 and runs XOR A; LD ($0B56),A = clear the pending-refs flag. CALL STMT_RENUM_8+1 ($4351) re-decodes F6 AF as OR $AF; LD ($0B56),A = set the flag nonzero. $0B56 read at $438A / gated at $440B drives RENUM_PATCH_LINEREFS. Independently verified; MBASIC twin confirms.
STMT_RENUM_8:
        CP $F6
; [RE] RENUM pass 2: walk every program line, find line-number references after GOTO/GOSUB/THEN tokens ($A4/$0E markers), translate each old line number to its new value (LINGET_TOKLINE lookup) and rewrite the 3-byte encoded line-number token in place; reports 'Undefined line' for missing targets.
RENUM_PATCH_LINEREFS:
        XOR A
        LD (L_0B56),A
        LD HL,(TXTTAB)
        DEC HL
RENUM_PATCH_LINEREFS_1:
        INC HL
        LD A,(HL)
        INC HL
        OR (HL)
        RET Z
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
RENUM_PATCH_LINEREFS_2:
        CALL CHRGET
RENUM_PATCH_LINEREFS_3:
        OR A
        JR Z,RENUM_PATCH_LINEREFS_1
        LD C,A
        LD A,(L_0B56)
        OR A
        LD A,C
        JR Z,RENUM_PATCH_LINEREFS_8
        CP $A4
        JR NZ,RENUM_PATCH_LINEREFS_4
        CALL CHRGET
        CP TOK_GOTO
        JR NZ,RENUM_PATCH_LINEREFS_3
        CALL CHRGET
        CP $0E
        JR NZ,RENUM_PATCH_LINEREFS_3
        PUSH DE
        CALL LINGET_TOKLINE
        LD A,D
        OR E
        JR NZ,RENUM_PATCH_LINEREFS_5
        JR RENUM_PATCH_LINEREFS_7
RENUM_PATCH_LINEREFS_4:
        CP $0E
        JR NZ,RENUM_PATCH_LINEREFS_2
        PUSH DE
        CALL LINGET_TOKLINE
RENUM_PATCH_LINEREFS_5:
        PUSH HL
        CALL FNDLIN
        DEC BC
        LD A,$0D
        JR C,RENUM_PATCH_LINEREFS_9
        CALL PRINT_CRLF_IF_COL
        LD HL,MSG_UNDEFINED_LINE
        PUSH DE
        CALL STROUT
        POP HL
        CALL FOUT
        POP BC
        POP HL
        PUSH HL
        PUSH BC
        CALL FOUT_PRINT
RENUM_PATCH_LINEREFS_6:
        POP HL
RENUM_PATCH_LINEREFS_7:
        POP DE
        DEC HL
        JR RENUM_PATCH_LINEREFS_2
; Data string 'Undefined line ' (+NUL) printed by the RENUM/line-reference checker (loaded at $43C1, emitted via STROUT) before the offending line number
MSG_UNDEFINED_LINE:
        DEFB    "Undefined line "        ; string
        DEFB    $00                      ; terminator
RENUM_PATCH_LINEREFS_8:
        CP $0D
        JP NZ,RENUM_PATCH_LINEREFS_2
        PUSH DE
        CALL LINGET_TOKLINE
        PUSH HL
        EX DE,HL
        INC HL
        INC HL
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD A,$0E
RENUM_PATCH_LINEREFS_9:
        LD HL,RENUM_PATCH_LINEREFS_6
        PUSH HL
        LD HL,(CONST_TEXT_RESUME)
; [RE] Write the 3-byte encoded line-number token (marker A, line# in BC) backward into the program text just before the pointer in $0B17.
RENUM_STORE_LINEREF:
        PUSH HL
        DEC HL
        LD (HL),B
        DEC HL
        LD (HL),C
        DEC HL
        LD (HL),A
        POP HL
        RET
; [RE] If the renumber-pending flag $0B56 is set, run the line-reference fix-up pass (RENUM_PATCH_LINEREFS); otherwise return. Called after DELETE edits the program.
RENUM_FIXUP_IF_PENDING:
        LD A,(L_0B56)
        OR A
        RET Z
        JP RENUM_PATCH_LINEREFS
; [RE] OPTION statement handler (token $B5): OPTION BASE 0/1 array lower-bound selector.
STMT_OPTION:
        CALL SYNCHR
        DEFB    'B'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'S'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'E'                      ; inline char arg consumed by the preceding CALL
        LD A,(L_0C74)
        OR A
        JP NZ,RAISE_DUPLICATE_DEFINITION
        PUSH HL
        LD HL,(ARYTAB)
        EX DE,HL
        LD HL,(STREND)
        CALL CMP_HL_DE
        JP NZ,RAISE_DUPLICATE_DEFINITION
        POP HL
        LD A,(HL)
        SUB $30
        JP C,RAISE_SYNTAX_ERROR
        CP $02
        JP NC,RAISE_SYNTAX_ERROR
        LD (L_0C73),A
        INC A
        LD (L_0C74),A
        CALL CHRGET
        RET
; [RE] Print a $00-terminated string at (HL) through STROUT_PUTC_SAVE, preserving registers; loops to end of string.
STROUT_NOFLAGS:
        LD A,(HL)
        OR A
        RET Z
        CALL STROUT_PUTC
        INC HL
        JP STROUT_NOFLAGS
; [RE] Emit one character (A) to the console via OUTDO (OUTDO_WIDTH_1) while preserving AF across the call.
STROUT_PUTC:
        PUSH AF
        JP OUTDO_WIDTH_1
; [RE] RANDOMIZE statement handler (token $B6): reseed the RND generator (prompts for a seed if none given).
STMT_RANDOMIZE:
        JR Z,STMT_RANDOMIZE_1
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FN_CINT
        JR STMT_RANDOMIZE_3
STMT_RANDOMIZE_1:
        PUSH HL
STMT_RANDOMIZE_2:
        LD HL,MSG_RANDOMIZE_PROMPT
        CALL STROUT
        CALL QINLIN
        POP DE
        JP C,STMT_END_2+1
        PUSH DE
        INC HL
        LD A,(HL)
        CALL FIN_1+1
        LD A,(HL)
        OR A
        JR NZ,STMT_RANDOMIZE_2
        CALL FN_CINT
STMT_RANDOMIZE_3:
        LD (RNDX_SEED_WORD),HL
        CALL POLY_EVAL_SQR
        POP HL
        RET
; Data string 'Random number seed (-32768- to 32767)' (with a $08 backspace splice) -- the interactive RANDOMIZE prompt emitted by STMT_RANDOMIZE via STROUT/QINLIN
MSG_RANDOMIZE_PROMPT:
        DEFB    "Random number seed (-32768-"  ; string
        DEFB    $08
        DEFB    " to 32767)"             ; string
        DEFB    $00                      ; terminator
; [RE] Enter the structured-block program scanner with delimiter set for WHILE/WEND (C=$1D); used to balance nested block-statement keywords while searching forward through program text.
BLOCK_SCAN_WHILE:
        LD C,$1D
        JR BLOCK_SCAN_FORNEXT_1
; [RE] Structured-block program scanner (FOR/NEXT default, C=$1A): walk crunched program text counting nesting of the matching open/close keyword tokens (e.g. FOR vs NEXT, $82/$83), tracking the current line pointer in $0C71; returns when the balancing close at depth 0 is found.
BLOCK_SCAN_FORNEXT:
        LD C,$1A
BLOCK_SCAN_FORNEXT_1:
        LD B,$00
        EX DE,HL
        LD HL,(SAVTXT)
        LD (L_0C71),HL
        EX DE,HL
BLOCK_SCAN_FORNEXT_2:
        INC B
BLOCK_SCAN_FORNEXT_3:
        DEC HL
BLOCK_SCAN_FORNEXT_4:
        CALL CHRGET
        JR Z,BLOCK_SCAN_FORNEXT_5
        CP TOK_ELSE
        JR Z,BLOCK_SCAN_FORNEXT_6
        CP TOK_THEN
        JR NZ,BLOCK_SCAN_FORNEXT_4
BLOCK_SCAN_FORNEXT_5:
        OR A
        JR NZ,BLOCK_SCAN_FORNEXT_6
        INC HL
        LD A,(HL)
        INC HL
        OR (HL)
        LD E,C
        JP Z,RAISE_ERROR
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (L_0C71),HL
        EX DE,HL
BLOCK_SCAN_FORNEXT_6:
        CALL CHRGET
        LD A,C
        CP $1A
        LD A,(HL)
        JR Z,BLOCK_SCAN_FORNEXT_7
        CP $AF
        JR Z,BLOCK_SCAN_FORNEXT_2
        CP $B0
        JR NZ,BLOCK_SCAN_FORNEXT_3
        DJNZ BLOCK_SCAN_FORNEXT_3
        RET
BLOCK_SCAN_FORNEXT_7:
        CP $82
        JR Z,BLOCK_SCAN_FORNEXT_2
        CP $83
        JR NZ,BLOCK_SCAN_FORNEXT_3
BLOCK_SCAN_FORNEXT_8:
        DEC B
        RET Z
        CALL CHRGET
        JR Z,BLOCK_SCAN_FORNEXT_5
        EX DE,HL
        LD HL,(SAVTXT)
        PUSH HL
        LD HL,(L_0C71)
        LD (SAVTXT),HL
        EX DE,HL
        PUSH BC
        CALL PTRGET_1+1
        POP BC
        DEC HL
        CALL CHRGET
BLOCK_SCAN_FORNEXT_9:
        LD DE,BLOCK_SCAN_FORNEXT_5
        JR Z,BLOCK_SCAN_FORNEXT_10
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        DEC HL
        LD DE,BLOCK_SCAN_FORNEXT_8
BLOCK_SCAN_FORNEXT_10:
        EX (SP),HL
        LD (SAVTXT),HL
        POP HL
        PUSH DE
        RET
BLOCK_SCAN_FORNEXT_11:
        PUSH AF
        LD A,(L_0CB6)
        LD (L_0CB7),A
        POP AF

; ======================================================================
; GRAPHICS + TEXT-SCREEN STATEMENTS and the 6502 RPC PATH (SoftCard superset)  ---  Apple soft-switches reached as $E0xx (Z-80 $E000-$EFFF == Apple $C000-$CFFF); Apple monitor-ROM calls reached by the 6502 RPC (A$VEC=$F3D0, Z$CPU=$F3DE, SLTTYP+2=$F3BB).  Handlers $45xx-$4Bxx; dispatch table $0194-$01B0.
; ======================================================================
; [RE] Clears the screen reverse/INVERSE flag cell ($0CB6=0) used by the console attribute path. Entry just below the VTAB/HTAB cursor helpers.
GFX_CLR_REVERSE_FLAG:
        PUSH AF
        XOR A
        LD (L_0CB6),A
        POP AF
        RET
; [RE] VTAB statement handler (token $C8): Apple graphics superset -- set the text cursor row (CALL $458E reads the operand).
GFX_STMT_VTAB:
        CALL GFX_GET_BYTE_ARG
        PUSH HL
        LD HL,PAGE_LENGTH
GFX_STMT_VTAB_1:
        SUB (HL)
        JP P,GFX_STMT_VTAB_1
        ADD A,(HL)
        LD (L_0B12),A
GFX_STMT_VTAB_2:
        CALL SCREEN_POS_FROM_TABLE
        POP HL
        RET
; [RE] Cursor/position helper used by HTAB/VTAB/HOME. Reads the per-screen cursor-config cells SLTTYP table at $F396/$F397 (40 vs 80-column geometry; bit7 selects swap of H/L) and folds the BASIC position ($0B11) into a console call via $6704. $F396/$F397 are SoftCard I/O-config screen cells in the $F3xx block.
SCREEN_POS_FROM_TABLE:
        LD E,$07
        CALL SCREEN_POS_EMIT
        LD HL,(L_0B11)
        LD A,(SXYOFF)
        OR A
        JP P,SCREEN_POS_FROM_TABLE_1
        AND $7F
        LD E,L
        LD L,H
        LD H,E
SCREEN_POS_FROM_TABLE_1:
        LD E,A
        ADD A,L
        LD L,A
        LD A,E
        ADD A,H
        PUSH HL
        CALL OUTDO_DEVICE2
        POP HL
        LD A,L
        JR SCREEN_POS_EMIT_1
; [RE] Emits one cursor-position component. Indexes the $F397 screen-config cell by E, applies the bit7 'present' test (AND $7F), and routes the value through the console output routine $6704. Part of the HTAB/VTAB cursor positioning path.
SCREEN_POS_EMIT:
        LD D,$00
        LD HL,SFLDIN
        ADD HL,DE
        LD A,(HL)
        OR A
        RET Z
        JP P,SCREEN_POS_EMIT_1
        AND $7F
        PUSH AF
        LD A,(SFLDIN)
        CALL OUTDO_DEVICE2
        POP AF
SCREEN_POS_EMIT_1:
        JP OUTDO_DEVICE2
; [RE] Evaluate one expression and return it as an 8-bit value (CALL FRMEVL-byte $4097); A=0 -> error ($34D0), else returns A-1. Argument fetch shared by the cursor/graphics statements.
GFX_GET_BYTE_ARG:
        CALL GETBYT
        OR A
        JP Z,ERROR_FC
        DEC A
        RET
; [RE] HTAB statement handler (token $C9): Apple graphics superset -- set the text cursor column.
GFX_STMT_HTAB:
        CALL GFX_GET_BYTE_ARG
        PUSH HL
        LD HL,PRINT_WIDTH
GFX_STMT_HTAB_1:
        SUB (HL)
        JP P,GFX_STMT_HTAB_1
        ADD A,(HL)
        LD (L_0B11),A
; [RE] HOME statement (token $C7, dispatch $0194 -> $45A8). $45A6 JRs into $4539_3; $45A8 zeroes the BASIC cursor-position cell $0B11, selects the screen attribute table entry (E=1, BC=$051E/$041E mode index) and calls SCREEN_POS_EMIT to clear/home the text cursor.
STMT_HOME:
        JR GFX_STMT_VTAB_2
; [RE] HOME statement handler (token $C7): Apple graphics superset -- clear the text screen / home cursor via the 6502 RPC.
GFX_STMT_HOME:
        PUSH HL
        LD HL,$0000
        LD (L_0B11),HL
        POP HL
        LD E,$01
; [RE] Shared cursor handler via LD BC,nn cover. 01 1E 05 at $45B2 = LD BC,$051E: the HOME path ($0194, E=$01 from $45B0) absorbs 1E 05 and keeps E. DEFW GFX_STMT_HOME_1+1 ($019A) enters at $45B3 so 1E 05 = LD E,$05 (screen-config cell 5); both share the SCREEN_POS_EMIT tail. Independently verified; MBASIC dispatch confirms.
GFX_STMT_HOME_1:
        LD BC,$051E
; [RE] Shared cursor handler. 01 1E 04 at $45B5 = LD BC,$041E covers the LD E,$04 inside. Dispatch entry GFX_STMT_HOME_2+1 ($019C) enters at $45B6 = LD E,$04 (screen-config cell 4); the fall-through chain from HOME/_1 keeps its prior E. Common tail = SCREEN_POS_EMIT. Independently verified; MBASIC dispatch confirms.
GFX_STMT_HOME_2:
        LD BC,$041E
        PUSH HL
        CALL SCREEN_POS_EMIT
        POP HL
        RET
; [RE] GFX_ TEXT statement handler (token $C6): Apple graphics superset -- return the screen to text mode (RPC to the 6502 side).
STMT_TEXT:
        PUSH HL
        LD HL,TEXT_ROM
        CALL RPC_CALL
        LD A,(PAGE_LENGTH)
        DEC A
        LD H,A
        LD L,$00
        LD (L_0B11),HL
        LD A,(TXTSET)
        LD A,(TXTPAGE1)
        LD A,(GFX_STMT_HPLOT_8)
        OR A
        JR Z,SUB_45CF_1
        LD HL,HOME_ROM
        CALL RPC_CALL
SUB_45CF_1:
        XOR A
        LD (GFX_STMT_HPLOT_8),A
        JR STMT_HOME

; ======================================================================
; GRAPHICS SUBSYSTEM (GFX_) + 6502 RPC bridge
; ======================================================================
; [RE] 6502 remote-procedure-call dispatcher. HL = Apple monitor-ROM target address; stores it at A$VEC ($F3D0) then writes the trigger cell whose operand was self-modified at cold start to Z$CPU ($F3DE) (the 'LD ($0000),A' at $45EA is patched to 'LD ($F3DE),A' by the init at $8243). Storing to Z$CPU hands control to the 6502, which runs the Apple monitor routine and returns. This is the bridge graphics uses to reach the Apple ROM (TEXT/HOME/PREAD/etc.).
RPC_CALL:
        LD (A_VEC),HL
; [RE] Self-modified store. Assembled as LD ($0000),A; cold-start init ($8240-$8245) reads Z$CPU ($F3DE) and patches this operand so it becomes LD (Z$CPU),A -- the write that actually triggers the 6502 to service the call queued at A$VEC.
; [RE] SMC operand patch (not a flag-skip). $45EA = LD ($0000),A; cold-start init at $8243 loads (Z$CPU)=$F3DE ($8240) and writes it into the operand at $45EB, making the instruction LD ($F3DE),A. RPC_CALL runs the patched store to trigger the 6502 to service the routine queued at A$VEC ($F3D0). Both write AND later execute confirmed; MBASIC patches the same cell.
RPC_TRIGGER_STORE:
        LD ($0000),A
        RET
; [RE] GR statement handler (token $CC): Apple graphics superset -- enter low-res graphics mode (loads mode byte then 6502 RPC).
GFX_STMT_GR:
        LD A,$00
        LD (COLOR),A
        CALL NZ,GETBYT
        CP $02
        JR NC,GFX_PARSE_LINE_COORDS_1
        PUSH HL
        PUSH AF
        LD A,$14
        LD (WNDTOP),A
        LD HL,$1700
        LD (L_0B11),HL
        CALL SCREEN_POS_FROM_TABLE
        LD A,(LORES)
        POP AF
        POP HL
        LD (LORES),A
        CALL GFX_SET_DISPLAY_MODE
        JR NZ,GFX_STMT_GR_2
        INC HL
        PUSH DE
        CALL GETBYT
GFX_STMT_GR_1:
        CALL GFX_SET_LORES_COLOR
        POP DE
GFX_STMT_GR_2:
        PUSH HL
        LD A,$27
        LD (H2),A
        LD B,D
GFX_STMT_GR_3:
        XOR A
        LD (RPC_YREG),A
        LD A,B
        DEC A
        LD (RPC_ACC),A
        CALL GFX_LORES_HLIN_RPC
        DJNZ GFX_STMT_GR_3
        LD A,$FF
        LD (GFX_STMT_HPLOT_8),A
        POP HL
        RET
; [RE] Low-res block-draw RPC tail: LD HL,$F819 (6502 HLIN handler entry) then JP RPC_CALL. Called by GR fill, HLIN setup to execute the horizontal-segment draw on the 6502 side.
GFX_LORES_HLIN_RPC:
        LD HL,HLINE
        JP RPC_CALL
; [RE] COLOR statement handler (token $CD): Apple graphics superset -- set the low-res plotting color.
GFX_STMT_COLOR:
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        CALL GETBYT
; [RE] COLOR statement body: validate color E<16, replicate it into both nibbles (4x ADD A,A; OR E) and store the packed low-res color byte to $F030.
GFX_SET_LORES_COLOR:
        LD A,E
        CP $10
        JR NC,GFX_PARSE_LINE_COORDS_1
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        OR E
        LD (COLOR),A
        RET
; [RE] GFX parse line coordinates: returns A = cross-axis coord, E = start, D = end.
GFX_PARSE_LINE_COORDS:
        PUSH BC
        CALL GFX_PARSE_TWO_BYTES
        POP BC
        CP B
GFX_PARSE_LINE_COORDS_1:
        JP NC,ERROR_FC
        CP E
        JP C,ERROR_FC
        LD D,A
        PUSH DE
        PUSH BC
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'T'                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        POP BC
        CP C
        JR NC,GFX_PARSE_LINE_COORDS_1
        POP DE
        RET
; [RE] HLIN statement handler (token $CE): Apple graphics superset -- draw a horizontal low-res line.
GFX_STMT_HLIN:
        LD BC,$2830
        CALL GFX_PARSE_LINE_COORDS
        LD (RPC_ACC),A
        LD A,E
        LD (RPC_YREG),A
        LD A,D
        LD (H2),A
        PUSH HL
        CALL GFX_LORES_HLIN_RPC
        POP HL
        RET
; [RE] VLIN statement body (mirror of GFX_STMT_HLIN): parse coords, store Y0/Y1->$F045/$F047 and X->$F02D, then fall to the low-res draw RPC ($F828) via GFX_STMT_PLOT_1.
GFX_STMT_VLIN:
        LD BC,$3028
        CALL GFX_PARSE_LINE_COORDS
        LD (RPC_YREG),A
        LD A,E
        LD (RPC_ACC),A
        LD A,D
        LD (V2),A
        PUSH HL
        LD HL,VLINE
        JR GFX_STMT_PLOT_1
; [RE] Parse two comma-separated byte expressions (X then Y): eval first into A, SYNCHR ',', eval second into A; preserves DE across. Used by PLOT/SCRN/BEEP coordinate reads.
GFX_PARSE_TWO_BYTES:
        CALL GETBYT
        PUSH DE
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        POP DE
        RET
; [RE] Parse+range-check a low-res PLOT coordinate pair: X<$30 and Y<$28 (else FC error), store X->$F045 and Y->$F047.
GFX_PARSE_PLOT_COORD:
        CALL GFX_PARSE_TWO_BYTES
        CP $30
        JR NC,GFX_PARSE_LINE_COORDS_1
        LD (RPC_ACC),A
        LD A,E
        CP $28
        JR NC,GFX_PARSE_LINE_COORDS_1
        LD (RPC_YREG),A
        RET
; [RE] PLOT statement body: parse+validate coords (GFX_PARSE_PLOT_COORD), set HL=$F800 (6502 PLOT handler) and fall into the RPC tail.
GFX_STMT_PLOT:
        CALL GFX_PARSE_PLOT_COORD
        PUSH HL
        LD HL,$F800
GFX_STMT_PLOT_1:
        CALL RPC_CALL
        POP HL
        RET
; [RE] PDL() handler (function token $35): Apple graphics superset -- read a game paddle/analog value via the 6502 RPC.
GFX_FN_PDL:
        CALL CONINT
        LD A,E
        CP $03
        JR NC,GFX_FN_VPOS_1
        LD A,D
        OR A
        JR NZ,GFX_FN_VPOS_1
        PUSH HL
        LD HL,BUTN0
        ADD HL,DE
        LD A,(HL)
        POP HL
        RLA
        SBC A,A
; [RE] Store a sign-extended byte (A, sign already in carry from RLA/SBC A,A) as a 16-bit integer in HL and JP FP_STORE_FAC_INT. Result tail for PDL().
GFX_STORE_SIGNED_BYTE_FAC:
        LD L,A
        LD H,A
        JP FP_STORE_FAC_INT
; [RE] MKD$() handler (function token $33): pack a double into an 8-byte string for random files (note: this entry sits in the Apple graphics block region).
GFX_FN_MKD_STR:
        LD A,(L_0B12)
        INC A
GFX_FN_MKD_STR_1:
        PUSH HL
GFX_FN_MKD_STR_2:
        CALL FP_LOAD_INT_TO_FAC
        POP HL
        RET
; [RE] BEEP statement handler (token $D4): Apple graphics superset -- sound the console bell via the 6502 RPC.
GFX_STMT_BEEP:
        CALL GFX_PARSE_TWO_BYTES
        INC A
        LD (RPC_ACC),A
        LD A,E
        INC A
        LD (RPC_XREG),A
        PUSH HL
        LD HL,BEEP_6502_PAYLOAD+$1000
        JP GFX_STMT_PLOT_1
; [RE] Embedded 6502 BEEP tone-loop, run by GFX_STMT_BEEP via the Z80->6502 RPC. From the 6502's view this lives at $4709+$1000=$5709 (the SoftCard maps a Z80 address X to 6502 address X+$1000), which is the value GFX_STMT_BEEP loads into HL (= A_VEC, the 6502 subroutine address) before triggering the RPC. 6502 listing: LDY #$00 / LDA $C030 (toggle speaker) / DEY / BNE +4 / DEC $45 (duration, =RPC_ACC) / BEQ done / JSR $FF57 (Monitor WAIT, delay) / DEX / BNE loop / LDX $46 (pitch, =RPC_XREG) / loop / RTS. Reads zp $45/$46 = the duration/pitch cells GFX_STMT_BEEP staged. Opaque DEFB from the Z80 view; the +$1000 in the operand expression is the documented SoftCard CPU-view offset, not a relocation artifact.
BEEP_6502_PAYLOAD:
        DEFB    $A0,$00,$AD,$30,$C0,$88,$D0,$04,$C6,$45,$F0,$0C,$20,$57,$FF,$CA
        DEFB    $D0,$F3,$A6,$46,$D0,$EC,$F0,$EA,$60
; [RE] WAIT statement handler (token $D5): poll an I/O port until (in AND mask) XOR xor is non-zero.
STMT_WAIT:
        CALL GETINT
        PUSH DE
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        PUSH AF
        LD E,$00
        JR Z,STMT_WAIT_1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
STMT_WAIT_1:
        POP AF
        LD D,A
        EX (SP),HL
STMT_WAIT_2:
        LD A,(HL)
        XOR E
        AND D
        JR Z,STMT_WAIT_2
        POP HL
        RET
; [RE] VPOS() handler (function token $34): Apple graphics superset -- current text cursor row (CALL $409A).
GFX_FN_VPOS:
        CALL CONINT
        LD A,E
        CP $04
GFX_FN_VPOS_1:
        JP NC,ERROR_FC
        LD (RPC_XREG),A
        PUSH HL
        LD HL,PREAD
        CALL RPC_CALL
        POP HL
        LD A,(RPC_YREG)
        JP FP_LOAD_INT_TO_FAC
GFX_FN_VPOS_2:
        CALL CHRGET
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CALL GFX_PARSE_PLOT_COORD
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        LD HL,SCRN_ROM
        CALL RPC_CALL
        LD A,(RPC_ACC)
        JP GFX_FN_MKD_STR_2
GFX_FN_VPOS_3:
        CALL CHRGET
        LD A,(COLOR)
        AND $0F
        JP GFX_FN_MKD_STR_1
GFX_FN_VPOS_4:
        LD HL,RPC_ACC
        XOR A
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
        POP HL
        CALL CHRGOT
        JR Z,GFX_FN_VPOS_9
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        LD DE,RPC_ACC
        LD B,$03
GFX_FN_VPOS_5:
        LD A,(HL)
        CP $29
        JR Z,GFX_FN_VPOS_8
        CP $2C
        JR NZ,GFX_FN_VPOS_6
        CALL CHRGET
        JR GFX_FN_VPOS_7
GFX_FN_VPOS_6:
        PUSH BC
        PUSH DE
        CALL GETBYT
        POP DE
        POP BC
        LD (DE),A
        INC DE
        LD A,(HL)
        CP $2C
        CALL Z,CHRGET
GFX_FN_VPOS_7:
        DJNZ GFX_FN_VPOS_5
GFX_FN_VPOS_8:
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
GFX_FN_VPOS_9:
        PUSH HL
        LD HL,(L_0C93)
        JP GFX_STMT_PLOT_1
; [RE] Graphics display-mode soft-switch helper. LD ($E050),A = $C050 TXTCLR (graphics on); LD HL,$E053; RRA selects mixed vs full screen: NC -> use $E053 ($C053 MIXSET, mixed text+graphics, D=$28 rows); C -> DEC L to $E052 ($C052 MIXCLR, full-screen graphics, D=$30 rows); the LD (HL),L touches the chosen switch. Sets the Apple display into the requested graphics mode.
GFX_SET_DISPLAY_MODE:
        PUSH HL
        LD (TXTCLR),A
        LD HL,MIXSET
        RRA
        LD D,$28
        JR NC,SUB_47C6_1
        DEC L
        LD D,$30
SUB_47C6_1:
        LD (HL),L
        POP HL
        LD A,(HL)
        CP $2C
        RET
    IFDEF GBASIC
; ====================================================================== GRAPHICS (GBASIC only)
; [RE] Current hi-res plot color/mode index. Set by COLOR=/HCOLOR= (GFX_SET_COLOR_INDEX $4847); read by GFX_SELECT_COLOR_MASK ($4A91) and the SCRN color read to pick the bit-pattern mask.
GFX_COLOR_INDEX:
        DEFB    "\0"
; [RE] Two-byte hi-res pixel bit pattern for the current color (stored by GFX_SET_COLOR_INDEX_4 $4871); loaded into DE by GFX_LOAD_STEP_STATE ($49EF) for the plot/line writer.
GFX_COLOR_PATTERN:
        DEFB    "\0\0"
; [RE] Hi-res screen byte address of the current plot point (init $8081). Computed by GFX_XY_TO_HIRES_ADDR; loaded into BC by GFX_LOAD_STEP_STATE; saved/restored around a SCRN(x,y) read.
GFX_HIRES_BYTE_ADDR:
        DEFB    $81,$80
; [RE] Hi-res row base screen address of the current point (init $1000). Built by GFX_XY_TO_HIRES_ADDR and advanced a row/column at a time by the Bresenham step routines.
GFX_HIRES_ROW_BASE:
        DEFB    $00,$10
; [RE] Intra-byte bit/column index of the current hi-res point (set $49D1; read $49A6/$49DB to index the column mask). The COLOR/SCRN state save reads it as a word spanning into GFX_X_FRACTION.
GFX_HIRES_BIT_INDEX:
        DEFB    "\0"
; [RE] X sub-byte offset added to the row base in GFX_LOAD_STEP_STATE ($49F3) to reach the plot byte; set by GFX_XY_TO_HIRES_ADDR_2 and recomputed at HPLOT line end.
GFX_X_FRACTION:
        DEFB    "\0"
; [RE] Current hi-res X coordinate (0-279), stored by GFX_XY_TO_HIRES_ADDR ($4978); reloaded by GFX_DRAW_LINE and at HPLOT line end to seed the next segment's delta.
GFX_X_COORD:
        DEFB    "\0\0"
; [RE] Current hi-res Y/row coordinate, stored by GFX_XY_TO_HIRES_ADDR ($497D); read/updated by GFX_DRAW_LINE to compute the vertical delta for Bresenham stepping.
GFX_Y_COORD:
        DEFB    "\0"
; [RE] HCOLOR() function handler (token $D3): hi-res color read; reached via the special-case FUNCTION dispatch JP Z at $3C85. MBASIC (graphics-OFF) routes this to RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED.
GFX_FN_HCOLOR:
        CALL CHRGET
        LD A,(GFX_COLOR_INDEX)
        JP GFX_FN_MKD_STR_1
; [RE] HSCRN() function handler (token $ED): hi-res screen-point read; reached via the special-case FUNCTION dispatch JP Z at $3C8F. MBASIC routes it to the not-implemented stub.
GFX_FN_HSCRN:
        CALL CHRGET
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CALL GFX_READ_COORD_PAIR
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        LD HL,(GFX_HIRES_BYTE_ADDR)
        PUSH HL
        LD HL,(GFX_HIRES_ROW_BASE)
        PUSH HL
        LD HL,(GFX_HIRES_BIT_INDEX)
        PUSH HL
        LD HL,SUB_47C6_4
        PUSH HL
        PUSH HL
        LD HL,GFX_HIRES_COLOR_MASK_TABLE_B
        LD (GFX_XY_TO_HIRES_ADDR_4+1),HL
        LD A,C
        JP GFX_XY_TO_HIRES_ADDR_1
SUB_47C6_4:
        CALL GFX_LOAD_STEP_STATE
        EXX
        LD A,(HL)
        AND C
        ADD A,A
        JR NZ,SUB_47C6_5
        INC HL
        LD A,(HL)
        AND B
        ADD A,A
        JR Z,SUB_47C6_6
SUB_47C6_5:
        LD A,$FF
SUB_47C6_6:
        CALL GFX_STORE_SIGNED_BYTE_FAC
        POP HL
        LD (GFX_HIRES_BIT_INDEX),HL
        POP HL
        LD (GFX_HIRES_ROW_BASE),HL
        POP HL
        LD (GFX_HIRES_BYTE_ADDR),HL
        POP HL
        RET
; [RE] HCOLOR statement handler (token $D3): Apple graphics superset -- set the hi-res plotting color (CALL $6925 evaluates the operand).
GFX_STMT_HCOLOR:
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        CALL GETBYT
; [RE] Set the current plotting color/mode index (0-12, else error). Stores the index at $47DA and selects the corresponding hi-res bit-pattern mask routine ($4888 family) and color bit table; shared setup for COLOR/HCOLOR plotting.
GFX_SET_COLOR_INDEX:
        CP $0D
        JP NC,ERROR_FC
        LD (GFX_COLOR_INDEX),A
        PUSH HL
        CP $08
        JR NC,GFX_SET_COLOR_INDEX_1
        LD HL,GFX_HIRES_COLOR_WORDS
        ADD A,A
        LD E,A
        LD D,$00
        ADD HL,DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        JR GFX_SET_COLOR_INDEX_4
GFX_SET_COLOR_INDEX_1:
        CP $0C
        JR Z,GFX_SET_COLOR_INDEX_6
        CP $0A
        JR NC,GFX_SET_COLOR_INDEX_2
        RRA
        SBC A,A
        AND $7F
        JR GFX_SET_COLOR_INDEX_3
GFX_SET_COLOR_INDEX_2:
        RRA
        SBC A,A
        SET 7,A
GFX_SET_COLOR_INDEX_3:
        LD H,A
        LD L,A
GFX_SET_COLOR_INDEX_4:
        LD (GFX_COLOR_PATTERN),HL
        LD HL,GFX_PLOT_BYTE_2
        LD (GFX_PLOT_BYTE_1+1),HL
GFX_SET_COLOR_INDEX_5:
        CALL GFX_SELECT_COLOR_MASK
        JP GFX_XY_TO_HIRES_ADDR_3
GFX_SET_COLOR_INDEX_6:
        LD HL,GFX_PLOT_BYTE_7
        LD (GFX_PLOT_BYTE_1+1),HL
        JR GFX_SET_COLOR_INDEX_5
; [RE] Plot one hi-res byte: with the screen address in the alternate HL (EXX), XOR/AND the color bit-mask (B/C and D/E pixel patterns) into the hi-res page byte and its neighbor, honoring the even/odd column ($4888_1 self-modified jump selects the masking variant). Core pixel writer for HPLOT and the line drawer.
GFX_PLOT_BYTE:
        EXX
        BIT 0,L
; [RE] SMC: JP operand patched by GFX_SET_COLOR_INDEX. $4877 (SET_COLOR_INDEX_4) stores GFX_PLOT_BYTE_2 ($488E, color XOR/AND variant); $4883 (SET_COLOR_INDEX_6, index $0C) stores GFX_PLOT_BYTE_7 ($48C1, AND $7F erase variant). $488C is the operand byte, not code.
GFX_PLOT_BYTE_1:
        JP GFX_PLOT_BYTE_2
GFX_PLOT_BYTE_2:
        JP NZ,GFX_PLOT_BYTE_4
        LD A,C
        ADD A,A
        JP Z,GFX_PLOT_BYTE_3
        LD A,(HL)
        XOR E
        AND C
        XOR (HL)
        LD (HL),A
        LD A,B
        ADD A,A
        JP Z,GFX_PLOT_BYTE_6
GFX_PLOT_BYTE_3:
        INC L
        LD A,(HL)
        XOR D
        AND B
        XOR (HL)
        LD (HL),A
        DEC L
        EXX
        RET
GFX_PLOT_BYTE_4:
        LD A,B
        ADD A,A
        JP Z,GFX_PLOT_BYTE_5
        LD A,(HL)
        XOR D
        AND B
        XOR (HL)
        LD (HL),A
        LD A,C
        ADD A,A
        JP Z,GFX_PLOT_BYTE_6
GFX_PLOT_BYTE_5:
        INC L
        LD A,(HL)
        XOR E
        AND C
        XOR (HL)
        LD (HL),A
        DEC L
GFX_PLOT_BYTE_6:
        EXX
        RET
GFX_PLOT_BYTE_7:
        JP NZ,GFX_PLOT_BYTE_9
        LD A,C
        ADD A,A
        JP Z,GFX_PLOT_BYTE_8
        LD A,C
        AND $7F
        XOR (HL)
        LD (HL),A
        LD A,B
        ADD A,A
        JP Z,GFX_PLOT_BYTE_6
GFX_PLOT_BYTE_8:
        INC L
        AND $7F
        XOR (HL)
        LD (HL),A
        DEC L
        EXX
        RET
GFX_PLOT_BYTE_9:
        LD A,B
        ADD A,A
        JP Z,GFX_PLOT_BYTE_10
        LD A,B
        AND $7F
        XOR (HL)
        LD (HL),A
        LD A,C
        ADD A,A
        JP Z,GFX_PLOT_BYTE_6
GFX_PLOT_BYTE_10:
        INC L
        LD A,C
        AND $7F
        XOR B
        LD (HL),A
        DEC L
        EXX
        RET
; [RE] Bresenham line draw between the current point and a new endpoint. Computes |dx|,|dy|, picks X-major vs Y-major stepping ($4A1B / $4A65 step routines, self-modified into $4955/$4966), and walks the segment calling GFX_PLOT_BYTE ($4888) at each step. Drives HPLOT ... TO ... and connected HPLOT lists.
GFX_DRAW_LINE:
        CALL GFX_SELECT_COLOR_MASK
        LD A,(GFX_Y_COORD)
        LD HL,GFX_LOAD_STEP_STATE_1
        SUB C
        JR NC,GFX_DRAW_LINE_1
        CPL
        INC A
        LD HL,GFX_STEP_ROW
GFX_DRAW_LINE_1:
        PUSH HL
        PUSH AF
        LD A,C
        LD (GFX_Y_COORD),A
        LD HL,(GFX_X_COORD)
        EX DE,HL
        LD (GFX_X_COORD),HL
        OR A
        SBC HL,DE
        JR NC,GFX_DRAW_LINE_2
        ADD HL,DE
        EX DE,HL
        OR A
        SBC HL,DE
        LD DE,GFX_STEP_ROW_6
        JR GFX_DRAW_LINE_3
GFX_DRAW_LINE_2:
        LD DE,GFX_STEP_BIT
GFX_DRAW_LINE_3:
        POP BC
        LD A,H
        OR A
        LD A,B
        JR NZ,GFX_DRAW_LINE_4
        CP L
        JR C,GFX_DRAW_LINE_4
        EX (SP),HL
        LD (GFX_DRAW_LINE_7+1),HL
        EX DE,HL
        LD (GFX_DRAW_LINE_9+1),HL
        LD L,A
        LD H,$00
        POP DE
        PUSH HL
        JR GFX_DRAW_LINE_5
GFX_DRAW_LINE_4:
        EX (SP),HL
        LD (GFX_DRAW_LINE_9+1),HL
        EX DE,HL
        LD (GFX_DRAW_LINE_7+1),HL
        LD E,A
        LD D,$00
GFX_DRAW_LINE_5:
        POP HL
        LD (GFX_DRAW_LINE_10+1),HL
        LD B,H
        LD C,L
        INC BC
        OR A
        RR H
        RR L
        JR GFX_DRAW_LINE_8
GFX_DRAW_LINE_6:
        EXX
; [RE] SMC: CALL operand = the per-step major-axis stepper. $492D/$4940 patch it to GFX_STEP_ROW ($4A1B) or GFX_STEP_ROW_6 ($4A4E) per the X/Y-major branch. $4956 is the operand, not code.
GFX_DRAW_LINE_7:
        CALL GFX_STEP_ROW
        EXX
        CALL GFX_PLOT_BYTE
GFX_DRAW_LINE_8:
        DEC BC
        LD A,B
        OR C
        RET Z
        AND A
        SBC HL,DE
        JR NC,GFX_DRAW_LINE_6
        EXX
; [RE] SMC: CALL operand = the per-step minor-axis stepper, paired with GFX_DRAW_LINE_7. $4931/$493C patch it to GFX_STEP_BIT ($4A65) or GFX_STEP_ROW_6 ($4A4E) per the X/Y-major branch. $4967 is the operand, not code.
GFX_DRAW_LINE_9:
        CALL GFX_STEP_BIT
        EXX
        PUSH DE
; [RE] SMC: LD DE immediate = the minor-axis screen-pointer increment, patched at $4947 from line setup; $496E ADD HL,DE applies it each step. $496C is the operand, not code.
GFX_DRAW_LINE_10:
        LD DE,$0000
        ADD HL,DE
        POP DE
        JP GFX_DRAW_LINE_6
; [RE] Convert an (X,Y) hi-res coordinate to a screen byte address + intra-byte bit position. Stores X in $47E3 and the byte address in $47DF, builds the interleaved Apple hi-res row address (AND $C0 / shifts / ADD $10 page base) and the bit index within the byte. Used by HPLOT and GFX_DRAW_LINE.
GFX_XY_TO_HIRES_ADDR:
        PUSH HL
        CALL GFX_SELECT_COLOR_MASK
        EX DE,HL
        LD (GFX_X_COORD),HL
        EX DE,HL
        LD A,C
        LD (GFX_Y_COORD),A
GFX_XY_TO_HIRES_ADDR_1:
        AND $C0
        LD L,A
        RRA
        RRA
        OR L
        LD L,A
        LD A,C
        ADD A,A
        ADD A,A
        LD H,A
        ADD A,A
        RLA
        RLA
        RR L
        OR H
        AND $1F
        ADD A,$10
        LD H,A
        LD (GFX_HIRES_ROW_BASE),HL
        EX DE,HL
        CALL GFX_XY_HELPER
        SUB $07
        JR C,GFX_XY_TO_HIRES_ADDR_2
        INC B
GFX_XY_TO_HIRES_ADDR_2:
        LD A,B
        LD (GFX_X_FRACTION),A
GFX_XY_TO_HIRES_ADDR_3:
        LD A,(GFX_HIRES_BIT_INDEX)
        LD C,A
; [RE] SMC: LD HL immediate = the active hi-res color-mask table base. $4812 stores GFX_HIRES_COLOR_MASK_TABLE_B ($4AC5); GFX_SELECT_COLOR_MASK $4AB3 stores table A ($4AB7) or B ($4AC5) per color index. $49AB is the operand, not code.
GFX_XY_TO_HIRES_ADDR_4:
        LD HL,$0000
        PUSH HL
        LD B,$00
        ADD HL,BC
        LD E,(HL)
        LD A,C
        POP HL
        ADD A,$07
        LD C,A
        SUB $0E
        JR C,GFX_XY_TO_HIRES_ADDR_5
        LD C,A
GFX_XY_TO_HIRES_ADDR_5:
        ADD HL,BC
        LD D,(HL)
        EX DE,HL
        LD (GFX_HIRES_BYTE_ADDR),HL
        POP HL
        RET
; [RE] Coordinate sub-helper for GFX_XY_TO_HIRES_ADDR / line setup (divides/normalizes the X column into byte+bit). Called from the address-computation and line code.
GFX_XY_HELPER:
        LD DE,$FFF2
        LD A,D
GFX_XY_HELPER_1:
        INC A
        ADD HL,DE
        JR C,GFX_XY_HELPER_1
        ADD A,A
        LD B,A
        LD A,L
        ADD A,$0E
        LD (GFX_HIRES_BIT_INDEX),A
        RET
; [RE] Load the hi-res color bit-mask byte for the current intra-byte column: index the active pattern table ($4AC5, wrapping the 7-bit column via -7) and stash the masked pattern in A'.
GFX_LOAD_COLUMN_MASK:
        EXX
        LD HL,GFX_HIRES_COLOR_MASK_TABLE_B
        LD D,$00
        LD A,(GFX_HIRES_BIT_INDEX)
        SUB $07
        JR NC,GFX_LOAD_COLUMN_MASK_1
        ADD A,$07
GFX_LOAD_COLUMN_MASK_1:
        LD E,A
        ADD HL,DE
        LD A,(HL)
        AND $7F
        EX AF,AF'
; [RE] Load the line/plot working state from the soft-switch save cells into the alternate registers: BC=byte addr ($47DD), DE=color pattern ($47DB), HL=row base+X-offset ($47DF + $47E2); used at each Bresenham step.
GFX_LOAD_STEP_STATE:
        LD HL,(GFX_HIRES_BYTE_ADDR)
        LD C,L
        LD B,H
        LD HL,(GFX_COLOR_PATTERN)
        EX DE,HL
        LD A,(GFX_X_FRACTION)
        LD HL,(GFX_HIRES_ROW_BASE)
        ADD A,L
        LD L,A
        EXX
        RET
GFX_LOAD_STEP_STATE_1:
        LD A,L
        LD HL,(GFX_HIRES_ROW_BASE)
        SUB L
        PUSH AF
        LD A,H
        SUB $14
        JR NC,GFX_STEP_ROW_3
        RL L
        RLA
        DEC A
        BIT 3,A
        JR NZ,GFX_STEP_ROW_1
        LD H,$2F
        SCF
        LD A,L
        RRA
        SUB $28
        LD L,A
        JP GFX_STEP_ROW_5
; [RE] X-major Bresenham step: advance the hi-res X position by one pixel, recomputing the byte address (row table $47DF, page-base groups via SUB $0C/ADD $10) and the intra-byte bit so GFX_PLOT_BYTE writes the next column.
GFX_STEP_ROW:
        LD A,L
        LD HL,(GFX_HIRES_ROW_BASE)
        SUB L
        PUSH AF
        LD A,H
        SUB $0C
        BIT 5,A
        JR Z,GFX_STEP_ROW_3
        RL L
        RLA
        INC A
        BIT 3,A
        JR Z,GFX_STEP_ROW_2
        LD H,$10
        LD A,L
        RRA
        ADD A,$28
        LD L,A
        JP GFX_STEP_ROW_5
GFX_STEP_ROW_1:
        AND $3F
GFX_STEP_ROW_2:
        XOR $60
        RRA
        RR L
        JP GFX_STEP_ROW_4
GFX_STEP_ROW_3:
        ADD A,$10
GFX_STEP_ROW_4:
        LD H,A
GFX_STEP_ROW_5:
        LD (GFX_HIRES_ROW_BASE),HL
        POP AF
        ADD A,L
        LD L,A
        RET
GFX_STEP_ROW_6:
        EX AF,AF'
        RRCA
        JP NC,GFX_STEP_ROW_7
        DEC L
        RRCA
GFX_STEP_ROW_7:
        EX AF,AF'
        SCF
        RR B
        JP C,GFX_STEP_ROW_8
        RES 7,C
GFX_STEP_ROW_8:
        SCF
        RR C
        RET C
        RES 6,B
        RET
; [RE] GFX hi-res horizontal X step: advance the bit mask / X coordinate one pixel (not Y-major).
GFX_STEP_BIT:
        EX AF,AF'
        ADD A,A
        JP P,GFX_STEP_BIT_1
        INC L
        RLCA
GFX_STEP_BIT_1:
        EX AF,AF'
        SCF
        BIT 6,B
        JP NZ,GFX_STEP_BIT_2
        OR A
GFX_STEP_BIT_2:
        RL C
        JP M,GFX_STEP_BIT_3
        OR A
        SET 7,C
GFX_STEP_BIT_3:
        RL B
        SET 7,B
        RET
; [RE] Apple hi-res color/pixel-pattern word table, indexed at $484F as base + 2*color: black($0000), violet($552A), green($2A55), white($7F7F) and their high-bit blue/orange variants. Supplies the two-byte plot pattern at GFX_COLOR_PATTERN.
GFX_HIRES_COLOR_WORDS:
        DEFB    $00,$00,$2A,$55,$55,$2A,$7F,$7F,$80,$80,$AA,$D5,$D5,$AA,$FF,$FF
; [RE] Select the color bit-pattern table for the current color index ($47DA). Picks one of the mask tables ($4AB7 / $4AC5) and stores its pointer into the plot routine's self-modified operand ($49AB), so GFX_PLOT_BYTE uses the right 2-byte pixel pattern. The tables at $4AB7/$4AC5 are the hi-res color bit patterns.
GFX_SELECT_COLOR_MASK:
        LD A,(GFX_COLOR_INDEX)
        LD HL,GFX_HIRES_COLOR_MASK_TABLE_B
        CP $0C
        JR Z,GFX_SELECT_COLOR_MASK_3
        CP $08
        JR NC,GFX_SELECT_COLOR_MASK_1
        AND $03
        JR Z,GFX_SELECT_COLOR_MASK_3
        CP $03
        JR Z,GFX_SELECT_COLOR_MASK_3
GFX_SELECT_COLOR_MASK_1:
        LD HL,$FEE9
        AND A
        ADC HL,DE
        JR NZ,GFX_SELECT_COLOR_MASK_2
        DEC DE
GFX_SELECT_COLOR_MASK_2:
        LD HL,GFX_HIRES_COLOR_MASK_TABLE_A
GFX_SELECT_COLOR_MASK_3:
        LD (GFX_XY_TO_HIRES_ADDR_4+1),HL
        RET
; [RE] Hi-res color bit-pattern table A (odd/violet-green palette masks $83,$86,$8C,$98,$B0,$E0,$C0,...) selected by GFX_SELECT_COLOR_MASK for the plot/line writer.
GFX_HIRES_COLOR_MASK_TABLE_A:
        DEFB    $83,$86,$8C,$98,$B0,$E0,$C0,$80,$80,$80,$80,$80,$80,$81
; [RE] Hi-res color bit-pattern table B (even/blue-orange palette masks ...,$84,$88,$90,$A0,$C0, then $80 fill) selected by GFX_SELECT_COLOR_MASK; default table set at routine entry.
GFX_HIRES_COLOR_MASK_TABLE_B:
        DEFB    $81,$82,$84,$88,$90,$A0,$C0
        DEFS    8, $80                   ; fill
; [RE] HGR statement handler (token $D1): Apple graphics superset -- enter hi-res graphics mode (loads mode byte then 6502 RPC).
GFX_STMT_HGR:
        LD A,$00
        CALL NZ,GETBYT
        CP $04
GFX_STMT_HGR_1:
        JP NC,ERROR_FC
        LD (HIRES),A
        PUSH AF
        CALL GFX_SET_DISPLAY_MODE
        LD A,$00
        JR NZ,SUB_4ADE_1
        INC HL
        CALL GETBYT
SUB_4ADE_1:
        PUSH AF
        CALL GFX_SET_COLOR_INDEX
        POP BC
        POP AF
        AND $02
        RET NZ
        LD A,B
        CP $0C
        JR Z,SUB_4ADE_2
        PUSH HL
        LD HL,RELOCATE_AND_RUN
        LD HL,(GFX_COLOR_PATTERN)
        LD (RELOCATE_AND_RUN),HL
        LD HL,RELOCATE_AND_RUN
        LD DE,$1002
        LD BC,$1FFE
        LDIR
        POP HL
        RET
SUB_4ADE_2:
        LD DE,RELOCATE_AND_RUN
SUB_4ADE_3:
        LD A,(DE)
        XOR $7F
        LD (DE),A
        INC DE
        LD A,D
        CP $30
        JR NZ,SUB_4ADE_3
        RET
; [RE] Read and range-check a hi-res coordinate pair: row 0-23 (CP $18) via $4088, column 0-191 (CP $C0) via CHRGET+eval; errors to $34D0 on overflow. Coordinate parser for HLIN/VLIN/HPLOT/PLOT.
GFX_READ_COORD_PAIR:
        CALL GETINT
        LD A,E
        CP $18
        LD A,D
        SBC A,$01
        JR NC,GFX_STMT_HGR_1
        PUSH DE
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        CP $C0
        JR NC,GFX_STMT_HGR_1
        LD C,A
        POP DE
        RET
; [RE] HPLOT statement handler (token $D2): Apple graphics superset -- hi-res plot/line-draw (CP $DD tests for TO continuation).
GFX_STMT_HPLOT:
        CP TOK_TO
        JR NZ,GFX_STMT_HPLOT_1
        CALL GFX_LOAD_COLUMN_MASK
        JR GFX_STMT_HPLOT_2
GFX_STMT_HPLOT_1:
        CALL GFX_READ_COORD_PAIR
        CALL GFX_XY_TO_HIRES_ADDR
        CALL GFX_LOAD_COLUMN_MASK
        CALL GFX_PLOT_BYTE
        CALL CHRGOT
        RET Z
GFX_STMT_HPLOT_2:
        CALL CHRGET
        CALL GFX_READ_COORD_PAIR
        PUSH HL
        CALL GFX_DRAW_LINE
        POP HL
        LD A,(HL)
        CP TOK_TO
        JR Z,GFX_STMT_HPLOT_2
        EXX
        LD A,(GFX_HIRES_ROW_BASE)
        SUB L
        CPL
        INC A
        LD (GFX_X_FRACTION),A
        LD L,C
        LD H,B
        LD (GFX_HIRES_BYTE_ADDR),HL
        LD HL,(GFX_X_COORD)
        CALL GFX_XY_HELPER
        EXX
        RET
    ENDIF
; ----------------------------------------------------------------------
; DISK_RAISE_RESET_ERROR -- raise BASIC error 31 "Reset error" (head of the disk-error raise vector chain).
;   In:        (none)
;   Out:       falls into the shared tail with E = ERR_RESET_ERROR; never returns (jumps to RAISE_ERROR).
;   Clobbers:  E (then DISK_RESELECT_AND_RAISE clobbers A,C,DE and issues a BDOS call).
;   Algorithm: Set E to the disk-reset error code, then fall through the overlap-skip chain (the trailing
;              DEFB $01 = LD BC opcode swallows the next routine's LD E,n) into DISK_RESELECT_AND_RAISE.
;              These vectors are also stored in the cold-start vector table so the disk/RWTS error path can
;              jump to one directly.
; ----------------------------------------------------------------------
DISK_RAISE_RESET_ERROR:
        LD E,ERR_RESET_ERROR             ; raise error 31
        DEFB    $01                      ; LD BC opcode = skip the next LD E
; ----------------------------------------------------------------------
; DISK_RAISE_DISK_I_O_ERROR -- raise BASIC error 57 "Disk I/O error".
;   In:        (none)
;   Out:       falls into the shared tail with E = ERR_DISK_I_O_ERROR; never returns.
;   Clobbers:  E (and the shared tail's clobbers).
;   Algorithm: Set E to the disk-I/O error code; the trailing DEFB $01 swallows the next LD E so control
;              reaches DISK_RESELECT_AND_RAISE, which reselects the default drive and raises the error.
; ----------------------------------------------------------------------
DISK_RAISE_DISK_I_O_ERROR:
        LD E,ERR_DISK_I_O_ERROR          ; raise error 57
        DEFB    $01                      ; LD BC opcode = skip the next LD E
; ----------------------------------------------------------------------
; DISK_RAISE_DISK_READ_ONLY -- raise BASIC error 68 "Disk Read Only".
;   In:        (none)
;   Out:       falls into the shared tail with E = ERR_DISK_READ_ONLY; never returns.
;   Clobbers:  E (and the shared tail's clobbers).
;   Algorithm: Load the read-only-disk error code into E and fall through (DEFB $01 skip-idiom) to
;              DISK_RESELECT_AND_RAISE.
; ----------------------------------------------------------------------
DISK_RAISE_DISK_READ_ONLY:
        LD E,ERR_DISK_READ_ONLY          ; raise error 68
        DEFB    $01                      ; LD BC opcode = skip the next LD E
; ----------------------------------------------------------------------
; DISK_RAISE_DRIVE_SELECT_ERROR -- raise BASIC error 69 "Drive select error".
;   In:        (none)
;   Out:       falls into the shared tail with E = ERR_DRIVE_SELECT_ERROR; never returns.
;   Clobbers:  E (and the shared tail's clobbers).
;   Algorithm: Load the drive-select error code into E and fall through (DEFB $01 skip-idiom) to
;              DISK_RESELECT_AND_RAISE.
; ----------------------------------------------------------------------
DISK_RAISE_DRIVE_SELECT_ERROR:
        LD E,ERR_DRIVE_SELECT_ERROR      ; raise error 69
        DEFB    $01                      ; LD BC opcode = skip the next LD E
; ----------------------------------------------------------------------
; DISK_RAISE_FILE_READ_ONLY -- raise BASIC error 70 "File Read Only" (last vector before the shared tail).
;   In:        (none)
;   Out:       falls straight into the shared tail with E = ERR_FILE_READ_ONLY; never returns.
;   Clobbers:  E (and the shared tail's clobbers).
;   Algorithm: Load the file-read-only error code into E; with no skip idiom it simply falls into
;              DISK_RESELECT_AND_RAISE.
; ----------------------------------------------------------------------
DISK_RAISE_FILE_READ_ONLY:
        LD E,ERR_FILE_READ_ONLY          ; raise error 70
; ----------------------------------------------------------------------
; DISK_RESELECT_AND_RAISE -- shared tail of the disk-error vectors: reselect the recorded default drive, then raise.
;   In:        E = BASIC error code (set by one of the DISK_RAISE_* vectors above).
;   Out:       never returns; jumps to RAISE_ERROR with E = the error code.
;   Clobbers:  A, C, DE around the BDOS call; E is preserved across it (saved/restored via the stack).
;   Algorithm: After a disk fault the BDOS may have left a non-default drive selected; save the error code,
;              issue BDOS Select-Disk (C=DRV_SET) with E = the CP/M current-drive byte at $0004 to re-log
;              the recorded default drive, restore the code, then JP RAISE_ERROR. In the GBASIC build it
;              falls straight to the JP; in MBASIC an IFNDEF island injects the hi-res "Graphics statement
;              not implemented" raise (error 32) sharing this same JP RAISE_ERROR exit.
; ----------------------------------------------------------------------
DISK_RESELECT_AND_RAISE:
        PUSH DE
        ; reselect the recorded default drive (E = CP/M current-drive byte at $0004) to undo any drive the failed BDOS op left logged
        LD C,DRV_SET
        LD A,($0004)
        LD E,A
        CALL BDOS
        POP DE
    IFNDEF GBASIC
        DEFB    $01                      ;        LD BC opcode = skip the LD E on the reselect fall-through
RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED:
        LD E,ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; HGR/HPLOT/HCOLOR raise (MBASIC has no hi-res)
    ENDIF
        JP RAISE_ERROR
GFX_STMT_HPLOT_8:
        NOP
GFX_STMT_HPLOT_9:
        LD D,B
; [RE] FADDT entry: load constant pointer ($5BDC) then fall into FADD-with-operand; adds the FP value at (HL) to FAC.
FADD_LOAD_CONST:
        LD HL,FP_CONST_HALF_SNG
; [RE] FADD with operand at (HL): load the addend mantissa/exp into regs (FP_LOAD_MEM) then align-and-add against FAC.
FADD_FROM_MEM:
        CALL FP_LOAD_MEM
        JR FADD_ALIGN
FADD_FROM_MEM_1:
        CALL FP_LOAD_MEM
; [RE] FADD entry when addend already supplied; loads FAC into HL-pair (FP_NEG negate path) then aligns exponents.
FSUB:
        CALL FP_NEG
; [RE] FADD core: compare exponents of addend (B) and FAC ($0CB4); if FAC=0 just store addend; shift the smaller mantissa right to align, then add.
FADD_ALIGN:
        LD A,B
        OR A
        RET Z
        LD A,(L_0CB4)
        OR A
        JP Z,FP_STORE_FAC
        SUB B
        JR NC,FADD_ALIGN_1
        CPL
        INC A
        EX DE,HL
        CALL FAC_PUSH
        EX DE,HL
        CALL FP_STORE_FAC
        POP BC
        POP DE
FADD_ALIGN_1:
        CP $19
        RET NC
        PUSH AF
        CALL FP_UNPACK_MSB
        LD H,A
        POP AF
        CALL MANT_SHIFT_BYTES
        LD A,H
        OR A
        LD HL,FAC
        JP P,FADD_ALIGN_2
        CALL MANT_ADD
        JP NC,FP_SET_ZERO_7
        INC HL
        INC (HL)
        JP Z,FIN_DONE_12
        LD L,$01
        CALL MANT_SHIFT_BITS
        JR FP_SET_ZERO_7
FADD_ALIGN_2:
        XOR A
        SUB B
        LD B,A
        LD A,(HL)
        SBC A,E
        LD E,A
        INC HL
        LD A,(HL)
        SBC A,D
        LD D,A
        INC HL
        LD A,(HL)
        SBC A,C
        LD C,A
; [RE] FADD mantissa combine: CALL C,FCOMPL (sign disagreement) then drop into FADD proper to add/subtract the aligned mantissas.
FADD_COMBINE:
        CALL C,FCOMPL
; [RE] FP add/normalize core (FADDT path): align exponents, add/subtract mantissas, and renormalize the result in the FAC ($0CB1/$0CB4). FP_SET_ZERO ($4C09) is the normalize/round tail that writes the final exponent to $0CB4.
FADD:
        LD L,B
        LD H,E
        XOR A
FADD_1:
        LD B,A
        LD A,C
        OR A
        JR NZ,FP_SET_ZERO_5
        LD C,D
        LD D,H
        LD H,L
        LD L,A
        LD A,B
        SUB $08
        CP $E0
        JR NZ,FADD_1
; [RE] MBF normalize/round tail: left-justify the summed mantissa (B=shift count), adjust the FAC exponent at $0CB4, round, store result back (JP FADD_STORE).
FP_SET_ZERO:
        XOR A
FP_SET_ZERO_1:
        LD (L_0CB4),A
        RET
FP_SET_ZERO_2:
        LD A,H
        OR L
        OR D
        JR NZ,FP_SET_ZERO_4
        LD A,C
FP_SET_ZERO_3:
        DEC B
        RLA
        JR NC,FP_SET_ZERO_3
        INC B
        RRA
        LD C,A
        JR FP_SET_ZERO_6
FP_SET_ZERO_4:
        DEC B
        ADD HL,HL
        LD A,D
        RLA
        LD D,A
        LD A,C
        ADC A,A
        LD C,A
FP_SET_ZERO_5:
        JP P,FP_SET_ZERO_2
FP_SET_ZERO_6:
        LD A,B
        LD E,H
        LD B,L
        OR A
        JR Z,FP_SET_ZERO_7
        LD HL,L_0CB4
        ADD A,(HL)
        LD (HL),A
        JR NC,FP_SET_ZERO
        JP Z,FP_SET_ZERO
FP_SET_ZERO_7:
        LD A,B
FP_SET_ZERO_8:
        LD HL,L_0CB4
        OR A
        CALL M,FADD_ROUND_CARRY
        LD B,(HL)
        INC HL
        LD A,(HL)
        AND $80
        XOR C
        LD C,A
        JP FP_STORE_FAC
; [RE] Round/carry propagation: bump mantissa bytes E,D,C and exponent on a rounding carry; overflow to error if the exponent wraps.
FADD_ROUND_CARRY:
        INC E
        RET NZ
        INC D
        RET NZ
        INC C
        RET NZ
        LD C,$80
        INC (HL)
        RET NZ
        JP FIN_DONE_11
; [RE] 3-byte mantissa add: (HL..)+E,D,C with carry into the FAC mantissa registers.
MANT_ADD:
        LD A,(HL)
        ADD A,E
        LD E,A
        INC HL
        LD A,(HL)
        ADC A,D
        LD D,A
        INC HL
        LD A,(HL)
        ADC A,C
        LD C,A
        RET
; [RE] FCOMPL: two's-complement negate the working mantissa (B,E,D,C) and flip the sign byte at $0CB5; used when adding operands of opposite sign.
FCOMPL:
        LD HL,L_0CB5
        LD A,(HL)
        CPL
        LD (HL),A
        XOR A
        LD L,A
        SUB B
        LD B,A
        LD A,L
        SBC A,E
        LD E,A
        LD A,L
        SBC A,D
        LD D,A
        LD A,L
        SBC A,C
        LD C,A
        RET
; [RE] Byte-granular mantissa right-shift: shift the 4-byte mantissa right whole bytes by (exponent diff)/8, then fall into the bit-shift remainder.
MANT_SHIFT_BYTES:
        LD B,$00
MANT_SHIFT_BYTES_1:
        SUB $08
        JR C,MANT_SHIFT_BYTES_2
        LD B,E
        LD E,D
        LD D,C
        LD C,$00
        JR MANT_SHIFT_BYTES_1
MANT_SHIFT_BYTES_2:
        ADD A,$09
        LD L,A
        LD A,D
        OR E
        OR B
        JR NZ,MANT_SHIFT_BYTES_4
        LD A,C
MANT_SHIFT_BYTES_3:
        DEC L
        RET Z
        RRA
        LD C,A
        JR NC,MANT_SHIFT_BYTES_3
        JR MANT_SHIFT_BITS_1
MANT_SHIFT_BYTES_4:
        XOR A
        DEC L
        RET Z
        LD A,C
; [RE] Bit-granular mantissa right-shift: rotate C,D,E,B right one bit per step to finish exponent alignment.
MANT_SHIFT_BITS:
        RRA
        LD C,A
MANT_SHIFT_BITS_1:
        LD A,D
        RRA
        LD D,A
        LD A,E
        RRA
        LD E,A
        LD A,B
        RRA
        LD B,A
        JR MANT_SHIFT_BYTES_4
L_4CA6:
        DEFB    $00,$00,$00,$81
; [RE] LOG() numerator coefficient pool: MBF (4-byte single) polynomial, layout { count byte; N x 4-byte MBF coefficient } with count=$04 -> 4 coefficients ($4CAB-$4CBA). Evaluated by POLY_EVAL (Horner) from the LOG mantissa-reduction routine at $4CDF ($4CEC/$4CEF). Paired with FP_POLY_LOG_DEN; the two are FDIV'd ($4D03) to form the rational approximation of ln over the reduced interval.
FP_POLY_LOG_NUM:
        DEFB    $04,$9A,$F7,$19,$83,$24,$63,$43,$83,$75,$CD,$8D,$84,$A9,$7F,$83
        DEFB    $82
; [RE] LOG() denominator coefficient pool: MBF polynomial { count byte; N x 4-byte MBF } with count=$04 -> 4 coefficients ($4CBC-$4CCB). Evaluated by POLY_EVAL from $4CFB/$4CFE; the result divides the FP_POLY_LOG_NUM result (FDIV at $4D03) to yield ln of the range-reduced mantissa.
FP_POLY_LOG_DEN:
        DEFB    $04,$00,$00,$00,$81,$E2,$B0,$4D,$83,$0A,$72,$11,$83,$F4,$04,$35
        DEFB    $7F
; [RE] LOG(x) handler (function token $0A): natural logarithm (MBF math package).
FN_LOG:
        CALL FP_SIGN
        OR A
        JP PE,ERROR_FC
        CALL FN_SIN_REDUCE
        LD BC,$8031
        LD DE,$7218
        JP FMUL
; [RE] SIN range reduction / polynomial preprocessor: folds the argument into the principal interval before the Chebyshev poly (CALL $5D65 poly eval); helper for FN_SIN.
FN_SIN_REDUCE:
        CALL FP_LOAD_FAC
        LD A,$80
        LD (L_0CB4),A
        XOR B
        PUSH AF
        CALL FAC_PUSH
        LD HL,FP_POLY_LOG_NUM
        CALL POLY_EVAL
        POP BC
        POP HL
        CALL FAC_PUSH
        EX DE,HL
        CALL FP_STORE_FAC
        LD HL,FP_POLY_LOG_DEN
        CALL POLY_EVAL
        POP BC
        POP DE
        CALL FDIV
        POP AF
        CALL FAC_PUSH
        CALL FLOAT_A
        POP BC
        POP DE
        JP FADD_ALIGN

; ======================================================================
; FLOATING-POINT MATH PACKAGE (MBF) -- FAC at $0CB1/$0CB4
; ======================================================================
; [RE] MS BASIC-80 floating-point multiply (FMULT): multiply the argument FP value by the FAC (mantissa at $0CB1, exponent $0CB4) using the shift-and-add mantissa loop, producing the product in the FAC.
FMUL:
        CALL FP_SIGN
        RET Z
        LD L,$00
        CALL EXP_ADD
        LD A,C
        LD (FMUL_4+1),A
        EX DE,HL
        LD (FMUL_3+1),HL
        LD BC,$0000
        LD D,B
        LD E,B
        LD HL,FADD
        PUSH HL
        LD HL,FMUL_1
        PUSH HL
        PUSH HL
        LD HL,FAC
FMUL_1:
        LD A,(HL)
        INC HL
        OR A
        JR Z,FMUL_8
        PUSH HL
        EX DE,HL
        LD E,$08
FMUL_2:
        RRA
        LD D,A
        LD A,C
        JR NC,FMUL_5
        PUSH DE
; [RE] SMC operand cell: LD DE,nnnn at $4D43 is patched by FMUL setup ($4D20 LD (FMUL_3+1),HL) to the multiplicand mantissa low word; the shift-and-add loop then accumulates it via ADD HL,DE ($4D46). FMUL_3+1 is the immediate field, not a code entry.
FMUL_3:
        LD DE,$0000
        ADD HL,DE
        POP DE
; [RE] SMC operand cell: the immediate of ADC A,nn at $4D48 is patched by FMUL prologue ($4D1C LD (FMUL_4+1),A) to the multiplicand high byte; folded into the running product high byte each loop pass. FMUL_4+1 is the immediate, not a code entry.
FMUL_4:
        ADC A,$00
FMUL_5:
        RRA
        LD C,A
        LD A,H
        RRA
        LD H,A
        LD A,L
        RRA
        LD L,A
        LD A,B
        RRA
        LD B,A
        AND $10
        JP Z,FMUL_6
        LD A,B
        OR $20
        LD B,A
FMUL_6:
        DEC E
        LD A,D
        JR NZ,FMUL_2
        EX DE,HL
FMUL_7:
        POP HL
        RET
FMUL_8:
        LD B,E
        LD E,D
        LD D,C
        LD C,A
        RET
; [RE] FDIV reciprocal-divide setup: pushes the divisor (FAC_PUSH) and constant DP_CONST_2, then falls into FDIV restoring-division.
FDIV_BY_TEN:
        CALL FAC_PUSH
        LD HL,DP_CONST_2
        CALL FP_STORE_REGS_LD
FDIV_BY_TEN_1:
        POP BC
        POP DE
; [RE] MBF floating-point divide: divisor self-modified into the subtract trio ($4D9D/$4DA1/$4DA5), restoring long division of the FAC mantissa, result normalized via FADD_NORMALIZE.
FDIV:
        CALL FP_SIGN
        JP Z,FIN_DONE_14
        LD L,$FF
        CALL EXP_ADD
        INC (HL)
        INC (HL)
        DEC HL
        LD A,(HL)
        LD (FDIV_4+1),A
        DEC HL
        LD A,(HL)
        LD (FDIV_3+1),A
        DEC HL
        LD A,(HL)
        LD (FDIV_2+1),A
        LD B,C
        EX DE,HL
        XOR A
        LD C,A
        LD D,A
        LD E,A
        LD (FDIV_5+1),A
FDIV_1:
        PUSH HL
        PUSH BC
        LD A,L
; [RE] SMC operand cell: the SUB nn immediate at $4D9D is patched by FDIV setup ($4D8E LD (FDIV_2+1),A) to divisor mantissa byte 0; the restoring-division loop subtracts it from the remainder low byte. FDIV_2+1 is the immediate, not a code entry.
FDIV_2:
        SUB $00
        LD L,A
        LD A,H
; [RE] SMC operand cell: the SBC A,nn immediate at $4DA1 is patched by FDIV setup ($4D89 LD (FDIV_3+1),A) to divisor mantissa byte 1; subtracted-with-borrow from the remainder middle byte. FDIV_3+1 is the immediate, not a code entry.
FDIV_3:
        SBC A,$00
        LD H,A
        LD A,B
; [RE] SMC operand cell: the SBC A,nn immediate at $4DA5 is patched by FDIV setup ($4D84 LD (FDIV_4+1),A) to divisor mantissa byte 2; subtracted-with-borrow from the remainder high byte. FDIV_4+1 is the immediate, not a code entry.
FDIV_4:
        SBC A,$00
        LD B,A
; [RE] SMC scratch cell: the LD A,nn immediate at $4DA8 is the running quotient/borrow byte. Init 0 at $4D97; rewritten $4DAF/$4DE6; read back LD A,(FDIV_5+1) at $4DC0/$4DE2 to assemble the result. The byte is both the executed immediate and a self-modified scratch; FDIV_5+1 is not a code entry.
FDIV_5:
        LD A,$00
        SBC A,$00
        CCF
        JR NC,FDIV_6+1
        LD (FDIV_5+1),A
        POP AF
        POP AF
        SCF
; [RE] Flag-skip dual tail: $4DB5 JP NC,$E1C1 -- on the success branch JR NC,FDIV_7+1 ($4DAD) lands at $4DB6 and runs the operand bytes C1 E1 as POP BC; POP HL to discard the FDIV_1 loop saves. On fall-through SCF ($4DB4) leaves carry set so the JP NC is not taken (the POPs were already done as POP AF/POP AF). Both paths converge at $4DB8.
FDIV_6:
        JP NC,$E1C1
        LD A,C
        INC A
        DEC A
        RRA
        JP P,FDIV_8
        RLA
        LD A,(FDIV_5+1)
        RRA
        AND $C0
        PUSH AF
        LD A,B
        OR H
        OR L
        JP Z,FDIV_7
        LD A,$20
FDIV_7:
        POP HL
        OR H
        JP FP_SET_ZERO_8
FDIV_8:
        RLA
        LD A,E
        RLA
        LD E,A
        LD A,D
        RLA
        LD D,A
        LD A,C
        RLA
        LD C,A
        ADD HL,HL
        LD A,B
        RLA
        LD B,A
        LD A,(FDIV_5+1)
        RLA
        LD (FDIV_5+1),A
        LD A,C
        OR D
        OR E
        JR NZ,FDIV_1
        PUSH HL
        LD HL,L_0CB4
        DEC (HL)
        POP HL
        JR NZ,FDIV_1
        JP FP_SET_ZERO
; [RE] MUL/DIV sign+exponent combine: XOR the two operand sign bytes ($0CC0/$0CC1) and add the biased exponents; produces the result sign/exponent for FMUL and FDIV.
MULDIV_SIGN:
        LD A,$FF
; [RE] Flag-skip sign-combine: $4DFB LD L,$AF is a dead load whose $AF immediate doubles as XOR A. DDIV enters via MULDIV_SIGN ($4DF9, A=$FF preserved) so the sign-byte XOR is complemented; DMUL enters at +1 ($4DFC) running XOR A (A=0) for a straight sign XOR. Both fall into LD HL,$0CC0 and XOR the $0CC0/$0CC1 operand signs.
MULDIV_SIGN_1:
        LD L,$AF
        LD HL,L_0CC0
        LD C,(HL)
        INC HL
        XOR (HL)
        LD B,A
        LD L,$00
; [RE] Add operand exponent (B) to FAC exponent at $0CB4 with overflow/underflow detection; jumps to over/underflow handlers; shared by FMUL/FDIV.
EXP_ADD:
        LD A,B
        OR A
        JR Z,DEC_HL_RET_3
        LD A,L
        LD HL,L_0CB4
        XOR (HL)
        ADD A,B
        LD B,A
        RRA
        XOR B
        LD A,B
        JP P,DEC_HL_RET_2
        ADD A,$80
        LD (HL),A
        JP Z,FMUL_7
        CALL FP_UNPACK_MSB
        LD (HL),A
; [RE] Exponent-result finalize: pop saved sign, branch to zero result (FADD clear) on underflow or overflow error on overflow.
DEC_HL_RET:
        DEC HL
        RET
; [RE] Over/underflow decision: re-test FAC sign (FP_SIGN), complement, and route to zero-result vs overflow-error.
EXP_OVUN_TEST:
        CALL FP_SIGN
        CPL
        POP HL
DEC_HL_RET_2:
        OR A
DEC_HL_RET_3:
        POP HL
        JP P,FP_SET_ZERO
        JP FIN_DONE_5
; [RE] Scale FAC by a small power of two: load FAC, add 2 to the exponent (x4), renormalize via FADD_ALIGN, bump $0CB4; used by SIN/EXP poly scaling.
FP_SCALE2:
        CALL FP_LOAD_FAC
        LD A,B
        OR A
        RET Z
        ADD A,$02
        JP C,FIN_DONE_10
        LD B,A
        CALL FADD_ALIGN
        LD HL,L_0CB4
        INC (HL)
        RET NZ
        JP FIN_DONE_10
; [RE] SIGN of FAC: returns A=0 if exponent($0CB4)=0, else A=$01 (positive) or $FF (negative) from the sign byte $0CB3.
FP_SIGN:
        LD A,(L_0CB4)
        OR A
        RET Z
        LD A,(FACHI)
; [RE] Flag-skip shared sign tail: $4E4F CP $2F is the FP_SIGN body; FCOMP/DCOMP reuse the tail by entering at FP_SIGN_1+1 ($4E50) where the $2F operand byte runs as CPL, then the shared RLA/SBC A,A ($4E51-$4E55) collapses A to -1/0/+1. The full entry tests the sign byte; the +1 entry complements a precomputed difference.
FP_SIGN_1:
        CP $2F
FP_SIGN_2:
        RLA
FP_SIGN_3:
        SBC A,A
        RET NZ
        INC A
        RET
; [RE] Float the signed byte in A into the FAC: set exponent $88, clear low mantissa, set sign, normalize via FADD_COMBINE.
FLOAT_A:
        LD B,$88
        LD DE,$0000
FLOAT_A_1:
        LD HL,L_0CB4
        LD C,A
        LD (HL),B
        LD B,$00
        INC HL
        LD (HL),$80
        RLA
        JP FADD_COMBINE
; [RE] INT() handler (function token $05): floor to integer.
FN_INT:
        CALL FP_TEST_SIGN
        RET P
; [RE] Negate-FAC-and-continue: toggle the FAC sign (FP_NEG) then re-dispatch through the integer/type check ($3DC8) path.
FP_NEGATE_CHECKED:
        CALL FRMEVL_TEST_TYPE
        JP M,INT_NEGATE_FAC
        JP Z,RAISE_TYPE_MISMATCH
; [RE] Negate FAC: flip the high (sign) bit of the FAC sign byte at $0CB3.
FP_NEG:
        LD HL,FACHI
        LD A,(HL)
        XOR $80
        LD (HL),A
        RET
; [RE] MID$() handler (function token $03): substring extraction.
FN_MID_STR:
        CALL FP_TEST_SIGN
; [RE] Store signed 16-bit value in A (sign-extended into HL) into the FAC as an integer (JP FP_STORE_FAC_INT).
INT16_TO_FP:
        LD L,A
        RLA
        SBC A,A
        LD H,A
        JP FP_STORE_FAC_INT
; [RE] Type/sign test for INT-class coercion: $3DC8 type-check, error on zero/string, return sign of mantissa for integer values.
FP_TEST_SIGN:
        CALL FRMEVL_TEST_TYPE
        JP Z,RAISE_TYPE_MISMATCH
        JP P,FP_SIGN
        LD HL,(FAC)
; [RE] Test FAC integer mantissa ($0CB1) for zero and return its sign via the SIGN tail.
FP_MANT_SIGN:
        LD A,H
        OR L
        RET Z
        LD A,H
        JR FP_SIGN_2
; [RE] PUSHF: push the FAC mantissa ($0CB1) and sign/low-exp ($0CB3) onto the stack while preserving the caller return address (EX (SP),HL).
FAC_PUSH:
        EX DE,HL
        LD HL,(FAC)
        EX (SP),HL
        PUSH HL
        LD HL,(FACHI)
        EX (SP),HL
        PUSH HL
        EX DE,HL
        RET
; [RE] Load operand at (HL) into regs (FP_LOAD_MEM) then store DE/BC into the FAC; combined load-then-store helper.
FP_STORE_REGS_LD:
        CALL FP_LOAD_MEM
; [RE] MOVFR: store DE (mantissa low) and B,C (sign/high) into the FAC cells $0CB1/$0CB3.
FP_STORE_FAC:
        EX DE,HL
        LD (FAC),HL
        LD H,B
        LD L,C
        LD (FACHI),HL
        EX DE,HL
        RET
; [RE] MOVRF: load the FAC ($0CB1) 4-byte mantissa into E,D,C,B.
FP_LOAD_FAC:
        LD HL,FAC
; [RE] Load 4 FP mantissa bytes from (HL) into E,D,C,B (advancing HL).
FP_LOAD_MEM:
        LD E,(HL)
        INC HL
; [RE] Load 3 FP bytes from (HL) into D,C,B (entry past the first byte).
FP_LOAD_MEM3:
        LD D,(HL)
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
; [RE] Tail of the (HL)->regs loaders: final INC HL and RET.
FP_LOAD_DONE:
        INC HL
        RET
; [RE] MOVE: copy 4 bytes from (DE) into the FAC at $0CB1.
FP_MOVE_TO_FAC:
        LD DE,FAC
; [RE] Block-copy 4 bytes (DE)->(HL); generic FP move primitive.
FP_MOVE4:
        LD B,$04
        JR FP_MOVE_LOOP
FP_MOVE4_1:
        EX DE,HL
; [RE] Typed block-copy (DE)->(HL): length B = VALTYP ($0B14), which IS the value's storage WIDTH in bytes (2=int,3=string-descriptor,4=single,8=double). DJNZ-copies exactly VALTYP bytes. This site is the direct proof that VALTYP encodes byte width.
FP_MOVE_TYPED:
        LD A,(VALTYP)
        LD B,A
; [RE] Byte-copy loop body for the FP block moves (DJNZ over B bytes).
FP_MOVE_LOOP:
        LD A,(DE)
        LD (HL),A
        INC DE
        INC HL
        DJNZ FP_MOVE_LOOP
        RET
; [RE] Set the hidden mantissa MSB and extract the sign: force bit7 of $0CB3 high byte, save sign, return rounding bit in A.
FP_UNPACK_MSB:
        LD HL,FACHI
        LD A,(HL)
        RLCA
        SCF
        RRA
        LD (HL),A
        CCF
        RRA
        INC HL
        INC HL
        LD (HL),A
        LD A,C
        RLCA
        SCF
        RRA
        LD C,A
        RRA
        XOR (HL)
        RET
; [RE] Load second operand from temp ($0CBA) and set up the typed-move target (FP_MOVE4_1) before a compare/op.
FP_ARG_TO_TEMP1:
        LD HL,L_0CBA
; [RE] Operand setup: push the typed-move routine, type-check ($3DC8), and select the temp source ($0CAD or $0CB1) for the pending op.
FP_ARG_SETUP1:
        LD DE,FP_MOVE4_1
        JR FP_ARG_SETUP2_1
; [RE] Load second operand from temp ($0CBA) and set up the type-driven move (FP_MOVE_TYPED) before a compare/op.
FP_ARG_TO_TEMP2:
        LD HL,L_0CBA
; [RE] Operand setup variant selecting the typed-move (FP_MOVE_TYPED); type-check and pick temp source $0CAD/$0CB1.
FP_ARG_SETUP2:
        LD DE,FP_MOVE_TYPED
FP_ARG_SETUP2_1:
        PUSH DE
        LD DE,FAC
        CALL FRMEVL_TEST_TYPE
        RET C
        LD DE,L_0CAD
        RET
; [RE] Floating-point compare (FAC vs regs operand): returns A=0 equal, $01 / $FF for greater/less from sign+exponent+mantissa comparison.
FCOMP:
        LD A,B
        OR A
        JP Z,FP_SIGN
        LD HL,FP_SIGN_1+1
        PUSH HL
        CALL FP_SIGN
        LD A,C
        RET Z
        LD HL,FACHI
        XOR (HL)
        LD A,C
        RET M
        CALL FP_MANT_EQ
FCOMP_1:
        RRA
        XOR C
        RET
; [RE] Mantissa-equality test: compare the 4 mantissa bytes (B,C,D,E) against (HL..); on full match pops two return levels (equal).
FP_MANT_EQ:
        INC HL
        LD A,B
        CP (HL)
        RET NZ
        DEC HL
        LD A,C
        CP (HL)
        RET NZ
        DEC HL
        LD A,D
        CP (HL)
        RET NZ
        DEC HL
        LD A,E
        SUB (HL)
        RET NZ
        POP HL
        POP HL
        RET
; [RE] 16-bit integer compare of D:E vs H:L returning the SIGN-style -1/0/+1 result via the FP_SIGN tail.
INT16_COMP:
        LD A,D
        XOR H
        LD A,H
        JP M,FP_SIGN_2
        CP D
        JP NZ,FP_SIGN_3
        LD A,L
        SUB E
        JP NZ,FP_SIGN_3
        RET
; [RE] Compare two FP operands (one in temp $0CBA): sign+exponent then 8-byte mantissa compare; the relational-operator comparator.
DCOMP:
        LD HL,L_0CBA
        CALL FP_MOVE_TYPED
; [RE] Body of the FP operand compare: byte-by-byte mantissa comparison ($0CC1 down) yielding the ordering result.
DCOMP_BODY:
        LD DE,L_0CC1
        LD A,(DE)
        OR A
        JP Z,FP_SIGN
        LD HL,FP_SIGN_1+1
        PUSH HL
        CALL FP_SIGN
        DEC DE
        LD A,(DE)
        LD C,A
        RET Z
        LD HL,FACHI
        XOR (HL)
        LD A,C
        RET M
        INC DE
        INC HL
        LD B,$08
DCOMP_BODY_1:
        LD A,(DE)
        SUB (HL)
        JP NZ,FCOMP_1
        DEC DE
        DEC HL
        DEC B
        JR NZ,DCOMP_BODY_1
        POP BC
        RET
; [RE] Double-precision relational comparator (OPERATOR_ROUTINE_TBL double-compare slot $050B): CALL DCOMP_BODY then collapse the result to A=-1/0/+1 (FP_SIGN_1+1) -- the double analog of FCOMP.
DCOMP_REL:
        CALL DCOMP_BODY
        JP NZ,FP_SIGN_1+1
        RET
; [RE] CINT(x) handler (function token $1B): coerce the FAC to a signed 16-bit integer with rounding (adds FP_CONST_HALF then truncates). Also the universal FAC->int16 entry (FRCINT) reused by GETINT/GETBYT/GETADR.
FN_CINT:
        CALL FRMEVL_TEST_TYPE
        LD HL,(FAC)
        RET M
        JP Z,RAISE_TYPE_MISMATCH
        JP PO,FN_CINT_1
        CALL FP_ARG_TO_TEMP2
        LD HL,FP_CONST_HALF_DBL
        CALL FP_ARG_SETUP1
        CALL DADD
        CALL FIX_TO_INT
        JP FN_CINT_2
FN_CINT_1:
        CALL FADD_LOAD_CONST
FN_CINT_2:
        LD A,(FACHI)
        OR A
        PUSH AF
        AND $7F
        LD (FACHI),A
        LD A,(L_0CB4)
        CP $90
        JP NC,RAISE_OVERFLOW
        CALL FP_SHIFT_MANTISSA
        LD A,(L_0CB4)
        OR A
        JP NZ,FN_CINT_3
        POP AF
        EX DE,HL
        JP FN_CINT_4
FN_CINT_3:
        POP AF
        EX DE,HL
        JP P,FN_CINT_5
FN_CINT_4:
        LD A,H
        CPL
        LD H,A
        LD A,L
        CPL
        LD L,A
FN_CINT_5:
        JP FP_STORE_FAC_INT
FN_CINT_6:
        LD HL,RAISE_OVERFLOW
        PUSH HL
; [RE] Convert FAC to a 16-bit integer in HL: error if exponent>=$90 (out of range), else shift the mantissa down (FP_SHIFT_MANTISSA).
FP_TO_INT:
        LD A,(L_0CB4)
        CP $90
        JR NC,FP_TO_INT_RANGE
        CALL FP_SHIFT_MANTISSA
        EX DE,HL
FP_TO_INT_1:
        POP DE
; [RE] FP_STORE_FAC_INT: store the 16-bit integer in HL into the FAC low cells ($0CB1) and fall into SET_TYPE_INTEGER, setting VALTYP $0B14 = $02 (=VT_INT, integer, 2-byte width). The integer-into-FAC primitive used throughout the evaluator (MOVFR for the integer case).
FP_STORE_FAC_INT:
        LD (FAC),HL
; [RE] SET_TYPE_INTEGER: set VALTYP $0B14 = $02 (=VT_INT, integer). Tail of FP_STORE_FAC_INT and the integer-result stores (e.g. INT_DIV_ROUND $5203).
SET_TYPE_INTEGER:
        LD A,$02
SET_TYPE_INTEGER_1:
        LD (VALTYP),A
        RET
; [RE] Range-check helper for FP->int: compare FAC against the $8000 boundary (FCOMP) and finalize the integer result.
FP_TO_INT_RANGE:
        LD BC,$9080
        LD DE,$0000
        CALL FCOMP
        RET NZ
        LD H,C
        LD L,D
        JR FP_TO_INT_1
; [RE] CSNG(x) handler (function token $1C): coerce the FAC to single precision.
FN_CSNG:
        CALL FRMEVL_TEST_TYPE
        RET PO
        JP M,INT_TO_SINGLE
        JP Z,RAISE_TYPE_MISMATCH
; [RE] CINT body: load FAC, round/scale to an integer, set the high byte and store back via FADD_NORMALIZE.
FIX_TO_INT:
        CALL FP_LOAD_FAC
        CALL SET_TYPE_DOUBLE_1+1
        LD A,B
        OR A
        RET Z
        CALL FP_UNPACK_MSB
        LD HL,L_0CB0
        LD B,(HL)
        JP FP_SET_ZERO_7
; [RE] Convert the signed 16-bit FAC integer ($0CB1) to single precision: build exponent $90 and normalize via FADD_ALIGN.
INT_TO_SINGLE:
        LD HL,(FAC)
; [RE] INT_TO_SINGLE entry with the integer already in HL: set type, form exponent $90, normalize.
INT_TO_SINGLE_HL:
        CALL SET_TYPE_DOUBLE_1+1
        LD A,H
        LD D,L
        LD E,$00
        LD B,$90
        JP FLOAT_A_1
; [RE] CDBL(x) handler (function token $1D): coerce the FAC to double precision.
FN_CDBL:
        CALL FRMEVL_TEST_TYPE
        RET NC
        JP Z,RAISE_TYPE_MISMATCH
        CALL M,INT_TO_SINGLE
; [RE] Clear the FAC double-precision extension cells ($0CAD/$0CAF) when widening to single.
FP_CLEAR_EXT:
        LD HL,$0000
        LD (L_0CAD),HL
        LD (L_0CAF),HL
; [RE] SET_TYPE_DOUBLE: set VALTYP $0B14 = $08 (=VT_DBL, double). LD A,$08 then the LD BC,$043E at $502F acts as a 3E-04 cover so the +1 entry ($5030) sets single ($04) instead. Used to seed the numeric-literal accumulator as double (FIN $54A3) and clear-extend to double (FP_CLEAR_EXT fall-through).
SET_TYPE_DOUBLE:
        LD A,$08
; [RE] Flag-skip type select. SET_TYPE_DOUBLE ($502D) loads A=$08 then $502F LD BC,$043E swallows the 3E 04 bytes (BC scratch), so the double entry keeps A=$08. Callers entering at SET_TYPE_DOUBLE_1+1 ($5030) instead execute those bytes as LD A,$04. Both JP SET_TYPE_INTEGER_1 ($4FDC) -> LD ($0B14),A: VALTYP $08=VT_DBL (double) vs $04=VT_SNG (single). VALTYP = storage width in bytes (int=2,string=3,single=4,double=8).
SET_TYPE_DOUBLE_1:
        LD BC,$043E
        JP SET_TYPE_INTEGER_1
; [RE] Type-check requiring a numeric value; error ($0D87) if string/zero ??" gatekeeper for an INT-class operation.
FP_INT_CHECK:
        CALL FRMEVL_TEST_TYPE
        RET Z
        JP RAISE_TYPE_MISMATCH
; [RE] FP mantissa right-shift / denormalize-align helper: shifts the FAC mantissa (B,C,D,E build the 4-byte mantissa) right by the exponent difference so two FP values can be added; common to FADD/FP_INT.
FP_SHIFT_MANTISSA:
        LD B,A
        LD C,A
FP_SHIFT_MANTISSA_1:
        LD D,A
        LD E,A
        OR A
        RET Z
        PUSH HL
        CALL FP_LOAD_FAC
        CALL FP_UNPACK_MSB
        XOR (HL)
        LD H,A
        CALL M,DEC_DE_WITH_BORROW
        LD A,$98
        SUB B
        CALL MANT_SHIFT_BYTES
        LD A,H
        RLA
        CALL C,FADD_ROUND_CARRY
        LD B,$00
        CALL C,FCOMPL
        POP HL
        RET
; [RE] Decrement DE and, on borrow (DE wrapped to $FFFF), fall through to also decrement BC; multi-byte counter for the shift loop.
DEC_DE_WITH_BORROW:
        DEC DE
        LD A,D
        AND E
        INC A
        RET NZ
; [RE] Decrement BC (low half of the shift/round counter) and return.
DEC_BC:
        DEC BC
        RET
; [RE] FIX(x) handler (function token $1E): truncate toward zero to an integer-valued float.
FN_FIX:
        CALL FRMEVL_TEST_TYPE
        RET M
        CALL FP_SIGN
        JP P,FN_SGN
        CALL FP_NEG
        CALL FN_SGN
        JP FP_NEGATE_CHECKED
; [RE] SGN() handler (function token $04): sign of a number (-1/0/+1).
FN_SGN:
        CALL FRMEVL_TEST_TYPE
        RET M
        JR NC,FIX_SCALE_1
        JP Z,RAISE_TYPE_MISMATCH
        CALL FP_TO_INT
; [RE] FIX/round scaling: if exponent>=$98 already integral; else shift mantissa down to the integer position and re-round via FADD_COMBINE.
FIX_SCALE:
        LD HL,L_0CB4
        LD A,(HL)
        CP $98
        LD A,(FAC)
        RET NC
        LD A,(HL)
        CALL FP_SHIFT_MANTISSA
        LD (HL),$98
        LD A,E
        PUSH AF
        LD A,C
        RLA
        CALL FADD_COMBINE
        POP AF
        RET
FIX_SCALE_1:
        LD HL,L_0CB4
        LD A,(HL)
        CP $90
        JR NZ,FIX_SCALE_4
        LD C,A
        DEC HL
        LD A,(HL)
        XOR $80
        LD B,$06
FIX_SCALE_2:
        DEC HL
        OR (HL)
        DEC B
        JR NZ,FIX_SCALE_2
        OR A
        LD HL,$8000
        JP NZ,FIX_SCALE_3
        CALL FP_STORE_FAC_INT
        JP FN_CDBL
FIX_SCALE_3:
        LD A,C
FIX_SCALE_4:
        OR A
        RET Z
        CP $B8
        RET NC
; [RE] Denormalize toward the integer point for FIX: set exponent $B8, align the mantissa (DP_SHIFT_RIGHT_N) and clear the guard cell $0CAC.
FIX_DENORM:
        PUSH AF
        CALL FP_LOAD_FAC
        CALL FP_UNPACK_MSB
        XOR (HL)
        DEC HL
        LD (HL),$B8
        PUSH AF
        DEC HL
        LD (HL),C
        CALL M,DBL_EXT_DEC
        LD A,(FACHI)
        LD C,A
        LD HL,FACHI
        LD A,$B8
        SUB B
        CALL DP_SHIFT_RIGHT_N
        POP AF
        CALL M,DP_ROUND_CARRY
        XOR A
        LD (L_0CAC),A
        POP AF
        RET NC
        JP DADD_4
; [RE] Borrow-decrement the FAC double-precision extension bytes from $0CAD upward (propagating the borrow through the low mantissa).
DBL_EXT_DEC:
        LD HL,L_0CAD
DBL_EXT_DEC_1:
        LD A,(HL)
        DEC (HL)
        OR A
        INC HL
        JR Z,DBL_EXT_DEC_1
        RET
; [RE] 16x16 unsigned multiply for array subscript/offset computation (callers in PTRGET array code $61BB/$61FD): HL_running*BC accumulated by 16-iteration shift-add into DE; on overflow JP PTRGET_SEARCH_27 -> 'Subscript out of range' (E=$09). Result in DE
ARRAY_INDEX_MUL16:
        PUSH HL
        LD HL,$0000
        LD A,B
        OR C
        JR Z,ARRAY_INDEX_MUL16_3
        LD A,$10
ARRAY_INDEX_MUL16_1:
        ADD HL,HL
        JP C,PTRGET_SEARCH_27
        EX DE,HL
        ADD HL,HL
        EX DE,HL
        JR NC,ARRAY_INDEX_MUL16_2
        ADD HL,BC
        JP C,PTRGET_SEARCH_27
ARRAY_INDEX_MUL16_2:
        DEC A
        JR NZ,ARRAY_INDEX_MUL16_1
ARRAY_INDEX_MUL16_3:
        EX DE,HL
        POP HL
        RET
; [RE] Sign-extend HL into B (LD A,H/RLA/SBC A,A), negate via INT_NEG ($51D9), then SBC the high parts; entry into the signed-integer combine path feeding IADD_1.
INT_SIGNEXT_SUB:
        LD A,H
        RLA
        SBC A,A
        LD B,A
        CALL INT_NEG_STORE
        LD A,C
        SBC A,B
        JR IADD_1
; Integer ADD operator: sign-extend HL and DE, ADD HL,DE with carry into the sign byte, detect signed overflow (JP P to FP_RECOVER $4FD6); on overflow promote both operands to single via FLOAT_FROM_INT ($51F3) and re-add through FADD. MS BASIC-80 integer addition.
IADD:
        LD A,H
        RLA
        SBC A,A
IADD_1:
        LD B,A
        PUSH HL
        LD A,D
        RLA
        SBC A,A
        ADD HL,DE
        ADC A,B
        RRCA
        XOR H
        JP P,FP_TO_INT_1
        PUSH BC
        EX DE,HL
        CALL INT_TO_SINGLE_HL
        POP AF
        POP HL
        CALL FAC_PUSH
        EX DE,HL
        CALL FLOAT_FROM_INT
        JP FIN_DONE_1
; [RE] 16-bit signed integer multiply (OPERATOR_ROUTINE_TBL integer-multiply slot $051B): sign-normalize then a 16-iteration shift-and-add of BC into HL; on overflow promote both operands to single and re-enter FMUL.
IMUL:
        LD A,H
        OR L
        JP Z,FP_STORE_FAC_INT
        PUSH HL
        PUSH DE
        CALL INT_SETSIGN_NEG
        PUSH BC
        LD B,H
        LD C,L
        LD HL,$0000
        LD A,$10
IMUL_1:
        ADD HL,HL
        JR C,IMUL_5+1
        EX DE,HL
        ADD HL,HL
        EX DE,HL
        JR NC,IMUL_2
        ADD HL,BC
        JP C,IMUL_5+1
IMUL_2:
        DEC A
        JR NZ,IMUL_1
        POP BC
        POP DE
; [RE] Tail of integer multiply/divide: test product sign, on overflow promote operands to float and dispatch to FMUL ($4D12) / FADD-store paths; otherwise store signed integer result via INT_NEG/FP_STORE_FAC_INT.
IMULDIV_FINISH:
        LD A,H
        OR A
        JP M,IMUL_4
        POP DE
        LD A,B
        JP INT_ABS_STORE_1
IMUL_4:
        XOR $80
        OR L
        JR Z,IMULDIV_FLOAT_FALLBACK
        EX DE,HL
; [RE] Flag-skip stack cleanup: $5176 LD BC,$E1C1 -- the C1 E1 operand bytes double as POP BC; POP HL. On integer-mul overflow, JR/JP C,IMUL_5+1 ($5156/$515E) enters $5177 to pop the pre-loop saves (PUSH BC $514D, PUSH HL $5148); the IMUL_4 fall-through reaches $5176 with the stack already balanced and skips them via the junk LD BC. Both converge at $5179.
IMUL_5:
        LD BC,$E1C1
        CALL INT_TO_SINGLE_HL
        POP HL
        CALL FAC_PUSH
        CALL INT_TO_SINGLE_HL
IMUL_6:
        POP BC
        POP DE
        JP FMUL
; [RE] Float fallback for integer mul/div overflow: if result negative store integer (FP_STORE_FAC_INT $4FD7), else convert and re-enter via INT_TO_SINGLE_HL and jump to FP_NEG (FAC load).
IMULDIV_FLOAT_FALLBACK:
        LD A,B
        OR A
        POP BC
        JP M,FP_STORE_FAC_INT
        PUSH DE
        CALL INT_TO_SINGLE_HL
        POP DE
        JP FP_NEG
; [RE] INT_DIV_KERNEL: signed 16-bit DIVIDE (JP Z,RAISE_DIVISION_BY_ZERO on a zero divisor, then a 17-iteration restoring shift-subtract). Earlier mislabeled as multiply.
INT_DIV_KERNEL:
        LD A,H
        OR L
        JP Z,RAISE_DIVISION_BY_ZERO
        CALL INT_SETSIGN_NEG
        PUSH BC
        EX DE,HL
        CALL INT_NEG_STORE
        LD B,H
        LD C,L
        LD HL,$0000
        LD A,$11
        PUSH AF
        OR A
        JR INT_DIV_KERNEL_3
INT_DIV_KERNEL_1:
        PUSH AF
        PUSH HL
        ADD HL,BC
        JR NC,INT_DIV_KERNEL_2+1
        POP AF
        SCF
; [RE] Flag-skip stack balance: $51B5 LD A,$E1 -- the $E1 immediate doubles as POP HL. After ADD HL,BC: no-carry takes JR NC,INT_DIV_KERNEL_2+1 ($51B1) to $51B6 = POP HL (restore the pre-add HL); the carry path consumed that saved HL via POP AF/SCF ($51B3-$51B4) and must skip the POP, so the junk LD A,$E1 swallows the E1. Each path pops the single $51AF push; both fall into $51B7 LD A,E.
INT_DIV_KERNEL_2:
        LD A,$E1
INT_DIV_KERNEL_3:
        LD A,E
        RLA
        LD E,A
        LD A,D
        RLA
        LD D,A
        LD A,L
        RLA
        LD L,A
        LD A,H
        RLA
        LD H,A
        POP AF
        DEC A
        JR NZ,INT_DIV_KERNEL_1
        EX DE,HL
        POP BC
        PUSH DE
        JP IMULDIV_FINISH
; [RE] Combine signs of HL and DE into B, then take absolute value of HL via INT_ABS_STORE; sign-management prologue for signed integer multiply/divide.
INT_SETSIGN_NEG:
        LD A,H
        XOR D
        LD B,A
        CALL INT_ABS_STORE
        EX DE,HL
; [RE] If HL is non-negative store it as a signed integer to the FAC (FP_STORE_FAC_INT $4FD7); otherwise fall through to INT_NEG to negate first.
INT_ABS_STORE:
        LD A,H
INT_ABS_STORE_1:
        OR A
        JP P,FP_STORE_FAC_INT
; [RE] Two's-complement negate the 16-bit integer in HL (0-L, 0-H with borrow) then store to the integer FAC via FP_STORE_FAC_INT ($4FD7).
INT_NEG_STORE:
        XOR A
        LD C,A
        SUB L
        LD L,A
        LD A,C
        SBC A,H
        LD H,A
        JP FP_STORE_FAC_INT
; [RE] Negate the integer FAC: load HL from $0CB1, negate via INT_NEG, return NZ unless result is the $8000 sentinel (then fall into INT_TO_SNG to promote).
INT_NEGATE_FAC:
        LD HL,(FAC)
        CALL INT_NEG_STORE
        LD A,H
        XOR $80
        OR L
        RET NZ
; [RE] Promote integer FAC to single-precision: move to DE, set up via SET_TYPE_DOUBLE, clear A, fall into FLOAT_FROM_INT.
INT_TO_SNG:
        EX DE,HL
        CALL SET_TYPE_DOUBLE_1+1
        XOR A
; Build a single-precision FAC from the signed integer in HL: load binary exponent $98 (2^24 bias) and enter the FP normalize/pack path at $4E5B. MS BASIC-80 float-from-integer.
FLOAT_FROM_INT:
        LD B,$98
        JP FLOAT_A_1
; 16-bit integer DIVIDE: multiply-by-reciprocal then RRA-shift the quotient (D:E) into H:L with rounding, store via SET_TYPE_INTEGER and INT_ABS_STORE. MS BASIC-80 integer divide.
INT_DIV_ROUND:
        PUSH DE
        CALL INT_DIV_KERNEL
        XOR A
        ADD A,D
        RRA
        LD H,A
        LD A,E
        RRA
        LD L,A
        CALL SET_TYPE_INTEGER
        POP AF
        JR INT_ABS_STORE_1
; [RE] Flip the sign byte of the double-precision operand at $0CC0 (XOR $80), then fall into DADD (double-precision add) to perform a double subtract.
DP_NEGATE_SIGN:
        LD HL,L_0CC0
        LD A,(HL)
        XOR $80
        LD (HL),A
; Double-precision (8-byte mantissa) ADD/SUBTRACT: align the operand exponent at $0CC1 against the accumulator exponent $0CB4, denormalize-shift, add/subtract the 8-byte mantissas at $0CAC vs $0CBA, renormalize. Core of MBF double-precision addition.
DADD:
        LD HL,L_0CC1
        LD A,(HL)
        OR A
        RET Z
        LD B,A
        DEC HL
        LD C,(HL)
        LD DE,L_0CB4
        LD A,(DE)
        OR A
        JP Z,FP_ARG_TO_TEMP1
        SUB B
        JR NC,DADD_2
        CPL
        INC A
        PUSH AF
        LD C,$08
        INC HL
        PUSH HL
DADD_1:
        LD A,(DE)
        LD B,(HL)
        LD (HL),A
        LD A,B
        LD (DE),A
        DEC DE
        DEC HL
        DEC C
        JR NZ,DADD_1
        POP HL
        LD B,(HL)
        DEC HL
        LD C,(HL)
        POP AF
DADD_2:
        CP $39
        RET NC
        PUSH AF
        CALL FP_UNPACK_MSB
        LD HL,L_0CB9
        LD B,A
        LD A,$00
        LD (HL),A
        LD (L_0CAC),A
        POP AF
        LD HL,L_0CC0
        CALL DP_SHIFT_RIGHT_N
        LD A,(L_0CB9)
        LD (L_0CAC),A
        LD A,B
        OR A
        JP P,DADD_3
        CALL DP_ADD_CONST_8E
        JP NC,DADD_9
        EX DE,HL
        INC (HL)
        JP Z,FIN_DONE_12
        CALL DP_SHIFT_RIGHT_FROM_CB3
        JP DADD_9
DADD_3:
        LD A,$9E
        CALL DP_ADD_BLOCK_INIT
        LD HL,L_0CB5
        CALL C,DP_NEG_MANTISSA
DADD_4:
        XOR A
DADD_5:
        LD B,A
        LD A,(FACHI)
        OR A
        JR NZ,DADD_8
        LD HL,L_0CAC
        LD C,$08
DADD_6:
        LD D,(HL)
        LD (HL),A
        LD A,D
        INC HL
        DEC C
        JR NZ,DADD_6
        LD A,B
        SUB $08
        CP $C0
        JR NZ,DADD_5
        JP FP_SET_ZERO
DADD_7:
        DEC B
        LD HL,L_0CAC
        CALL DP_SHIFT_LEFT_8
        OR A
DADD_8:
        JP P,DADD_7
        LD A,B
        OR A
        JR Z,DADD_9
        LD HL,L_0CB4
        ADD A,(HL)
        LD (HL),A
        JP NC,FP_SET_ZERO
        RET Z
DADD_9:
        LD A,(L_0CAC)
DADD_10:
        OR A
        CALL M,DP_ROUND_CARRY
        LD HL,L_0CB5
        LD A,(HL)
        AND $80
        DEC HL
        DEC HL
        XOR (HL)
        LD (HL),A
        RET
; [RE] Round-up / carry-propagate the 8-byte double mantissa (INC through $0CAD..; on full carry set MSB $80 and bump exponent), called when the high mantissa byte is negative after add.
DP_ROUND_CARRY:
        LD HL,L_0CAD
        LD B,$07
DP_ROUND_CARRY_1:
        INC (HL)
        RET NZ
        INC HL
        DEC B
        JR NZ,DP_ROUND_CARRY_1
        INC (HL)
        JP Z,FIN_DONE_12
        DEC HL
        LD (HL),$80
        RET
; [RE] Subtract constant $8E from accumulator and add the 7-byte block $0CBA into $0CAD; thin wrapper that presets A and falls into the multi-byte add loop DP_ADD_BLOCK.
DP_SUB_CONST_8E:
        LD DE,L_0CDD
        LD HL,L_0CBA
        JP DP_ADD_BLOCK_1
; [RE] Preset constant $8E (LD A,$8E) for the multi-byte mantissa add, then fall into DP_ADD_BLOCK; used by the double multiply/divide inner loop.
DP_ADD_CONST_8E:
        LD A,$8E
; [RE] Set up source $0CBA and dest $0CAD for a 7-byte chained ADC, store the constant operand byte into the loop, then run DP_ADD_BLOCK.
DP_ADD_BLOCK_INIT:
        LD HL,L_0CBA
; [RE] 7-byte chained add-with-carry loop: ADC each byte of [HL]=$0CBA into [DE]=$0CAD, advancing both pointers. Multi-byte mantissa addition primitive for double-precision arithmetic.
DP_ADD_BLOCK:
        LD DE,L_0CAD
DP_ADD_BLOCK_1:
        LD C,$07
        LD (DP_ADD_BLOCK_3),A
        XOR A
DP_ADD_BLOCK_2:
        LD A,(DE)
DP_ADD_BLOCK_3:
        ADC A,(HL)
        LD (DE),A
        INC DE
        INC HL
        DEC C
        JR NZ,DP_ADD_BLOCK_2
        RET
; [RE] Two's-complement negate the 8-byte double mantissa starting at $0CAC (CPL the guard byte, then chained 0-byte SBC across 8 bytes).
DP_NEG_MANTISSA:
        LD A,(HL)
        CPL
        LD (HL),A
        LD HL,L_0CAC
        LD B,$08
        XOR A
        LD C,A
DP_NEG_MANTISSA_1:
        LD A,C
        SBC A,(HL)
        LD (HL),A
        INC HL
        DEC B
        JR NZ,DP_NEG_MANTISSA_1
        RET
; [RE] Denormalize: shift the 8-byte double mantissa right by N bit-positions (in groups of 8 via byte moves, remainder by per-bit RRA) to align exponents before DADD.
DP_SHIFT_RIGHT_N:
        LD (HL),C
        PUSH HL
DP_SHIFT_RIGHT_N_1:
        SUB $08
        JR C,DP_SHIFT_RIGHT_LOOP_2
        POP HL
; [RE] Inner byte/bit right-shift loop for DP_SHIFT_RIGHT_N: moves whole bytes while the shift count exceeds 8, then performs the leftover bit shifts.
DP_SHIFT_RIGHT_LOOP:
        PUSH HL
        LD DE,$0800
DP_SHIFT_RIGHT_LOOP_1:
        LD C,(HL)
        LD (HL),E
        LD E,C
        DEC HL
        DEC D
        JR NZ,DP_SHIFT_RIGHT_LOOP_1
        JR DP_SHIFT_RIGHT_N_1
DP_SHIFT_RIGHT_LOOP_2:
        ADD A,$09
        LD D,A
DP_SHIFT_RIGHT_LOOP_3:
        XOR A
        POP HL
        DEC D
        RET Z
DP_SHIFT_RIGHT_LOOP_4:
        PUSH HL
        LD E,$08
DP_SHIFT_RIGHT_LOOP_5:
        LD A,(HL)
        RRA
        LD (HL),A
        DEC HL
        DEC E
        JR NZ,DP_SHIFT_RIGHT_LOOP_5
        JR DP_SHIFT_RIGHT_LOOP_3
; [RE] Right-shift the double mantissa by 1 starting at $0CB3 (sets D=$01), used between partial products in the double multiply.
DP_SHIFT_RIGHT_FROM_CB3:
        LD HL,FACHI
        LD D,$01
        JR DP_SHIFT_RIGHT_LOOP_4
; [RE] Shift the 8-byte double mantissa left by one bit (chained RLA across 8 bytes from [HL]); partial-product accumulation step for double multiply.
DP_SHIFT_LEFT_8:
        LD C,$08
DP_SHIFT_LEFT_8_1:
        LD A,(HL)
        RLA
        LD (HL),A
        INC HL
        DEC C
        JR NZ,DP_SHIFT_LEFT_8_1
        RET
; Double-precision MULTIPLY: for each of 7 mantissa bytes / 8 bits, conditionally add (DP_ADD_CONST) the multiplicand and shift, accumulating the 8-byte product; guards against multiply-by-zero. MS BASIC-80 double multiply.
DMUL:
        CALL FP_SIGN
        RET Z
        LD A,(L_0CC1)
        OR A
        JP Z,FP_SET_ZERO
        CALL MULDIV_SIGN_1+1
        CALL DP_COPY_TEMP
        LD (HL),C
        INC DE
        LD B,$07
DMUL_1:
        LD A,(DE)
        INC DE
        OR A
        PUSH DE
        JR Z,DMUL_4
        LD C,$08
DMUL_2:
        PUSH BC
        RRA
        LD B,A
        CALL C,DP_ADD_CONST_8E
        CALL DP_SHIFT_RIGHT_FROM_CB3
        LD A,B
        POP BC
        DEC C
        JR NZ,DMUL_2
DMUL_3:
        POP DE
        DEC B
        JR NZ,DMUL_1
        JP DADD_4
DMUL_4:
        LD HL,FACHI
        CALL DP_SHIFT_RIGHT_LOOP
        JR DMUL_3
; [RE] Double-precision MBF constant (8-byte mantissa $CD CC CC CC CC CC 4C exp $7D ~= 0.1) used as the divide-by-ten reciprocal seed by DDIV/the decimal scaler. [RE] MBF double-precision constant 0.1 (CD CC CC CC CC CC 4C 7D). Loaded by the double-precision code (LD DE,DP_CONST_TENTH at $5390). The repeating $CC is 0.1's mantissa.
DP_CONST_TENTH:
        DEFB    $CD,$CC,$CC,$CC,$CC,$CC,$4C,$7D,$00  ; "MLLLLLL}"
        DEFB    "\0\0\0"
; [RE] Small double-precision MBF constant ($00 $00 $20 $84) following DP_CONST_TENTH, used as a rounding/scaling constant by the double-precision path.
DP_CONST_2:
        DEFB    $00,$00,$20,$84
; Double-precision DIVIDE: handle exponent/sign, restoring-division by 15 iterations (DP_PUSH_OPERAND / DADD / DP_POP_OPERAND), building the quotient mantissa; promotes to single (FP_NEG) when exponent small. MS BASIC-80 double divide.
FIN_DSCALE_DIV10:
        LD A,(L_0CB4)
        CP $41
        JP NC,FIN_DSCALE_DIV10_1
        LD DE,DP_CONST_TENTH
        LD HL,L_0CBA
        CALL FP_MOVE_TYPED
        JP DMUL
FIN_DSCALE_DIV10_1:
        LD A,(FACHI)
        OR A
        JP P,FIN_DSCALE_DIV10_2
        AND $7F
        LD (FACHI),A
        LD HL,FP_NEG
        PUSH HL
FIN_DSCALE_DIV10_2:
        CALL DP_DEC_EXP
        LD DE,L_0CAD
        LD HL,L_0CBA
        CALL FP_MOVE_TYPED
        CALL DP_DEC_EXP
        CALL DADD
        LD DE,L_0CAD
        LD HL,L_0CBA
        CALL FP_MOVE_TYPED
        LD A,$0F
FIN_DSCALE_DIV10_3:
        PUSH AF
        CALL DP_DEC_EXP_BY4
        CALL DP_PUSH_OPERAND
        CALL DADD
        LD HL,L_0CC0
        CALL DP_POP_OPERAND
        POP AF
        DEC A
        JP NZ,FIN_DSCALE_DIV10_3
        CALL DP_DEC_EXP
        CALL DP_DEC_EXP
        CALL DP_DEC_EXP
        RET
; [RE] Decrement the double-precision exponent at $0CB4; on underflow to zero jump to FP_ZERO ($4C09). Renormalization step for DMUL/DDIV.
DP_DEC_EXP:
        LD HL,L_0CB4
        DEC (HL)
        RET NZ
        JP FP_SET_ZERO
; [RE] Decrement the operand exponent byte $0CC1 by up to 4, returning early when it reaches zero; quad-loop counter for the divide reciprocal expansion.
DP_DEC_EXP_BY4:
        LD HL,L_0CC1
        LD A,$04
DP_DEC_EXP_BY4_1:
        DEC (HL)
        RET Z
        DEC A
        JP NZ,DP_DEC_EXP_BY4_1
        RET
; [RE] Push the 4 word-pairs of the 8-byte double operand at $0CBA onto the stack (saving the return address), preserving it across an inner DADD in DDIV.
DP_PUSH_OPERAND:
        POP DE
        LD A,$04
        LD HL,L_0CBA
DP_PUSH_OPERAND_1:
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH BC
        DEC A
        JP NZ,DP_PUSH_OPERAND_1
        PUSH DE
        RET
; [RE] Restore the 8-byte double operand into $0CC1..$0CBA from the stack (inverse of DP_PUSH_OPERAND).
DP_POP_OPERAND:
        POP DE
        LD A,$04
        LD HL,L_0CC1
DP_POP_OPERAND_1:
        POP BC
        LD (HL),B
        DEC HL
        LD (HL),C
        DEC HL
        DEC A
        JP NZ,DP_POP_OPERAND_1
        PUSH DE
        RET
; [RE] Double-precision FIX/INT and decimal-scale helper: validates exponents, copies FAC to temp via DP_COPY_TEMP ($5474), then repeatedly subtracts powers of ten ($9E/$8E constants) to extract integer digits.
DDIV:
        LD A,(L_0CC1)
        OR A
        JP Z,FIN_DONE_15
        LD A,(L_0CB4)
        OR A
        JP Z,FP_SET_ZERO
        CALL MULDIV_SIGN
        INC (HL)
        INC (HL)
        JP Z,FIN_DONE_12
        CALL DP_COPY_TEMP
        LD HL,L_0CE4
        LD (HL),C
        LD B,C
DDIV_1:
        LD A,$9E
        CALL DP_SUB_CONST_8E
        LD A,(DE)
        SBC A,C
        CCF
        JR C,DDIV_2+1
        LD A,$8E
        CALL DP_SUB_CONST_8E
        XOR A
; [RE] DDIV digit-loop overlap (VERIFIED). DA 12 04 = JP C,$0412 only on the carry-CLEAR fall-through ($544B XOR A guarantees carry clear, so the JP is a never-taken 2-byte skip of its own operand). The carry-SET branch (JR C,DDIV_2+1 at $5444) enters at +1 and runs 12 04 = LD (DE),A / INC B: store the reduced remainder, count one decimal digit. Both paths land at $544F. MBASIC DDIV_3 byte-identical.
DDIV_2:
        JP C,$0412
        LD A,(FACHI)
        INC A
        DEC A
        RRA
        JP M,DADD_10
        RLA
        LD HL,L_0CAD
        LD C,$07
        CALL DP_SHIFT_LEFT_8_1
        LD HL,L_0CDD
        CALL DP_SHIFT_LEFT_8
        LD A,B
        OR A
        JR NZ,DDIV_1
        LD HL,L_0CB4
        DEC (HL)
        JR NZ,DDIV_1
        JP FP_SET_ZERO
; [RE] Copy the 7-byte double mantissa down into temp buffer $0CE3 (and clear the source), saving the leading byte to $0CC0; scratch save used by DMUL/DDIV/DP_FIX.
DP_COPY_TEMP:
        LD A,C
        LD (L_0CC0),A
        DEC HL
        LD DE,L_0CE3
        LD BC,$0700
DP_COPY_TEMP_1:
        LD A,(HL)
        LD (DE),A
        LD (HL),C
        DEC DE
        DEC HL
        DEC B
        JR NZ,DP_COPY_TEMP_1
        RET
; [RE] Multiply the double accumulator by ten: bump the mantissa length, add the value to itself shifted (DADD), used by the decimal input/output scaler. Double-precision *10 step.
DP_MUL10:
        CALL FP_ARG_TO_TEMP2
        EX DE,HL
        DEC HL
        LD A,(HL)
        OR A
        RET Z
        ADD A,$02
        JP C,FIN_DONE_12
        LD (HL),A
        PUSH HL
        CALL DADD
        POP HL
        INC (HL)
        RET NZ
        JP FIN_DONE_12
; FIN: parse an ASCII numeric literal into the FAC. Handles leading sign, decimal point, E/D exponent markers, and type suffixes (%=int, !=sng, #=dbl, $=str); accumulates digits with integer->single->double promotion. MS BASIC-80 string-to-number.
FIN:
        CALL FP_SET_ZERO
        CALL SET_TYPE_DOUBLE
; [RE] FIN flag-skip (VERIFIED). F6 AF = OR $AF on FIN's top entry can never give zero, so Z stays clear and the later CALL Z,FP_STORE_FAC_INT ($54B9) is skipped (parse from FAC=0). The five +1 entrants run the operand AF = XOR A, setting Z so FP_STORE_FAC_INT pre-seeds the FAC integer first. Z is carried across PUSH AF/POP AF ($54AC/$54B2). The OR operand $AF is exactly the XOR A opcode. MBASIC FIN_1 byte-identical.
FIN_1:
        OR $AF
        LD BC,BLOCK_SCAN_FORNEXT_11
        PUSH BC
        PUSH AF
        LD A,$01
        LD (L_0CB6),A
        POP AF
        EX DE,HL
        LD BC,$00FF
        LD H,B
        LD L,B
        CALL Z,FP_STORE_FAC_INT
        EX DE,HL
        LD A,(HL)
        CP $26
        JP Z,SCAN_AMP_RADIX_CONST
        CP $2D
        PUSH AF
        JP Z,FIN_2
        CP $2B
        JR Z,FIN_2
        DEC HL
FIN_2:
        CALL CHRGET
        JP C,FIN_ACCUM_DIGIT
        CP $2E
        JP Z,FIN_11
        CP $65
        JR Z,FIN_3
        CP $45
FIN_3:
        JP NZ,FIN_6
        PUSH HL
        CALL CHRGET
        CP $6C
        JR Z,FIN_4
        CP $4C
        JR Z,FIN_4
        CP $71
        JR Z,FIN_4
        CP $51
FIN_4:
        POP HL
        JR Z,FIN_5
        LD A,(VALTYP)
        CP VT_DBL
        JR Z,FIN_7
        LD A,$00
        JR FIN_7
FIN_5:
        LD A,(HL)
FIN_6:
        CP $25
        JP Z,FIN_12
        CP $23
        JP Z,FIN_13
        CP $21
        JP Z,FIN_14
        CP $64
        JR Z,FIN_7
        CP $44
        JR NZ,FIN_9
FIN_7:
        OR A
        CALL FIN_TYPE_FIXUP
        CALL CHRGET
        CALL FIN_EXP_SIGN_SCAN
FIN_8:
        CALL CHRGET
        JP C,FIN_EXP_DIGIT
        INC D
        JR NZ,FIN_9
        XOR A
        SUB E
        LD E,A
FIN_9:
        PUSH HL
        LD A,E
        SUB B
        LD E,A
FIN_10:
        CALL P,FIN_MUL10
        CALL M,FIN_DIV10
        JR NZ,FIN_10
        POP HL
        POP AF
        PUSH HL
        CALL Z,FP_NEGATE_CHECKED
        POP HL
        CALL FRMEVL_TEST_TYPE
        RET PE
        PUSH HL
        LD HL,FMUL_7
        PUSH HL
        CALL FP_TO_INT_RANGE
        RET
FIN_11:
        CALL FRMEVL_TEST_TYPE
        INC C
        JR NZ,FIN_9
        CALL C,FIN_TYPE_FIXUP
        JP FIN_2
FIN_12:
        CALL CHRGET
        POP AF
        PUSH HL
        LD HL,FMUL_7
        PUSH HL
        LD HL,FN_CINT
        PUSH HL
        PUSH AF
        JR FIN_9
FIN_13:
        OR A
FIN_14:
        CALL FIN_TYPE_FIXUP
        CALL CHRGET
        JR FIN_9
; [RE] FIN coercion: force the parsed value to integer (FN_CINT) when Z, else to single (FN_CSNG) when NZ, preserving all registers.
FIN_TYPE_FIXUP:
        PUSH HL
        PUSH DE
        PUSH BC
        PUSH AF
        CALL Z,FN_CSNG
        POP AF
        CALL NZ,FN_CDBL
        POP BC
        POP DE
        POP HL
        RET
; [RE] FIN accumulate digit *10: RET if count zero, else multiply the running value by ten using the single-precision (FP_SCALE2) or double-precision (DP_MUL10 $5488) path per type parity; returns A decremented.
FIN_MUL10:
        RET Z
; [RE] Body of FIN_MUL10 (entry past the RET Z guard): performs the *10 multiply by single- or double-precision path.
FIN_MUL10_DO:
        PUSH AF
        CALL FRMEVL_TEST_TYPE
        PUSH AF
        CALL PO,FP_SCALE2
        POP AF
        CALL PE,DP_MUL10
        POP AF
; [RE] Shared 'DEC A; RET' counter helper: decrements the digit/exponent count in A. Tail of FIN_MUL10 and called conditionally by the FOUT exponent formatter ($5986)
DEC_A_RET:
        DEC A
        RET
; [RE] FIN fractional scale-down: divide the running value by ten via the single-precision (FDIV_BY_TEN) or double-precision (DDIV $5388) path per type parity; returns A incremented to track the decimal exponent.
FIN_DIV10:
        PUSH DE
        PUSH HL
        PUSH AF
        CALL FRMEVL_TEST_TYPE
        PUSH AF
        CALL PO,FDIV_BY_TEN
        POP AF
        CALL PE,FIN_DSCALE_DIV10
        POP AF
        POP HL
        POP DE
        INC A
        RET
; [RE] FIN integer-accumulate a decimal digit into $0CB1 (HL = HL*10 + digit) while the value still fits 16 bits; on overflow it promotes to single/double (constant $9474/$2400) and continues in float.
FIN_ACCUM_DIGIT:
        PUSH DE
        LD A,B
        ADC A,C
        LD B,A
        PUSH BC
        PUSH HL
        LD A,(HL)
        SUB $30
        PUSH AF
        CALL FRMEVL_TEST_TYPE
        JP P,FIN_DIV10_5
        LD HL,(FAC)
        LD DE,$0CCD
        CALL CMP_HL_DE
        JR NC,FIN_DIV10_4
        LD D,H
        LD E,L
        ADD HL,HL
        ADD HL,HL
        ADD HL,DE
        ADD HL,HL
        POP AF
        LD C,A
        ADD HL,BC
        LD A,H
        OR A
        JP M,FIN_DIV10_3
        LD (FAC),HL
FIN_DIV10_2:
        POP HL
        POP BC
        POP DE
        JP FIN_2
FIN_DIV10_3:
        LD A,C
        PUSH AF
FIN_DIV10_4:
        CALL INT_TO_SINGLE
        SCF
FIN_DIV10_5:
        JR NC,FIN_DIV10_7
        LD BC,$9474
        LD DE,$2400
        CALL FCOMP
        JP P,FIN_DIV10_6
        CALL FP_SCALE2
        POP AF
        CALL FIN_DONE
        JR FIN_DIV10_2
FIN_DIV10_6:
        CALL FP_CLEAR_EXT
FIN_DIV10_7:
        CALL DP_MUL10
        CALL FP_ARG_TO_TEMP2
        POP AF
        CALL FLOAT_A
        CALL FP_CLEAR_EXT
        CALL DADD
        JR FIN_DIV10_2
; [RE] FIN finalize: store the completed FAC (FAC_PUSH / FLOAT_A), unwind the saved registers and dispatch through FADD_ALIGN to return the converted number to the expression evaluator.
FIN_DONE:
        CALL FAC_PUSH
        CALL FLOAT_A
FIN_DONE_1:
        POP BC
        POP DE
        JP FADD_ALIGN
; [RE] FIN exponent-field digit accumulate: E*10+digit into E with range guard (<10), used while reading the E/D exponent of a numeric literal; errors via $0D81 path on overflow.
FIN_EXP_DIGIT:
        LD A,E
        CP $0A
        JR NC,FIN_DONE_3+1
        RLCA
        RLCA
        ADD A,E
        RLCA
        ADD A,(HL)
        SUB $30
        LD E,A
; [RE] FIN exponent-overflow flag-skip (VERIFIED). On the accumulate path (E<10) FA 1E 7F = JP M,$7F1E never triggers (E*10+digit stays positive, <100) and just skips its operand to reach JP FIN_8. The E>=10 branch (JR NC,FIN_DONE_3+1 at $5619) enters at +1 to run 1E 7F = LD E,$7F, saturating the exponent so the literal overflows. Both converge at $5626. MBASIC FIN_EXP_DIGIT_1 byte-identical.
FIN_DONE_3:
        JP M,$7F1E
        JP FIN_8
FIN_DONE_4:
        OR A
        JP FIN_DONE_19
        POP AF
FIN_DONE_5:
        PUSH HL
        LD HL,FACHI
        CALL FRMEVL_TEST_TYPE
        JP PO,FIN_DONE_6
        LD A,(L_0CC0)
        JP FIN_DONE_7
FIN_DONE_6:
        LD A,C
FIN_DONE_7:
        XOR (HL)
        RLA
        POP HL
        JP FIN_DONE_19
FIN_DONE_8:
        LD A,(L_0CB5)
        JP FIN_DONE_13
        POP AF
FIN_DONE_9:
        POP AF
        POP AF
FIN_DONE_10:
        LD A,(FACHI)
        RLA
        JP FIN_DONE_19
FIN_DONE_11:
        POP AF
FIN_DONE_12:
        LD A,(L_0CB5)
        CPL
FIN_DONE_13:
        RLA
        JP FIN_DONE_19
FIN_DONE_14:
        LD A,C
        JP FIN_DONE_18
FIN_DONE_15:
        PUSH HL
        PUSH DE
        LD HL,L_0CAD
        LD DE,L_5707
        CALL FP_MOVE4
        LD A,(L_5707)
        LD (L_0CAF),A
        CALL FRMEVL_TEST_TYPE
        JP PO,FIN_DONE_16
        LD A,(FACHI)
        JP FIN_DONE_17
FIN_DONE_16:
        LD A,(L_0CC0)
FIN_DONE_17:
        POP DE
        POP HL
FIN_DONE_18:
        RLA
        LD HL,ERRMSG_DIVISION_BY_ZERO
        LD (L_0848),HL
FIN_DONE_19:
        PUSH HL
        PUSH BC
        PUSH DE
        PUSH AF
        PUSH AF
        LD HL,(ON_ERROR_LINE)
        LD A,H
        OR L
        JP NZ,FIN_DONE_21
        LD A,(L_0CB6)
        OR A
        JP Z,FIN_DONE_20
        CP $01
        JP NZ,FIN_DONE_21
        LD A,$02
        LD (L_0CB6),A
FIN_DONE_20:
        LD HL,(L_0848)
        CALL STROUT_NOFLAGS
        LD (L_0B11),A
        LD A,$0D
        CALL STROUT_PUTC
        LD A,$0A
        CALL STROUT_PUTC
FIN_DONE_21:
        POP AF
        LD HL,FAC
        LD DE,L_5703
        JP NC,FIN_DONE_22
        LD DE,L_5707
FIN_DONE_22:
        CALL FP_MOVE4
        CALL FRMEVL_TEST_TYPE
        JP PO,FIN_DONE_23
        LD HL,L_0CAD
        LD DE,L_5707
        CALL FP_MOVE4
FIN_DONE_23:
        LD HL,(ON_ERROR_LINE)
        LD A,H
        OR L
        JP Z,FIN_DONE_24
        LD HL,(L_0848)
        LD DE,ERRMSG_OVERFLOW
        CALL CMP_HL_DE
        LD HL,ERRMSG_OVERFLOW
        LD (L_0848),HL
        JP Z,RAISE_OVERFLOW
        JP RAISE_DIVISION_BY_ZERO
FIN_DONE_24:
        POP AF
        LD HL,ERRMSG_OVERFLOW
        LD (L_0848),HL
        POP DE
        POP BC
        POP HL
        RET
L_5703:
        DEFB    $FF,$FF,$7F,$FF
L_5707:
        DEFB    $FF,$FF,$FF,$FF
; [RE] Print the FOUT-formatted ASCII number string from buffer $0CED via STROUT ($6C40), preserving HL; the console-output wrapper used after FOUT builds the digit string.
FOUT_PRINT:
        PUSH HL
        LD HL,L_0CED
        CALL STROUT
        POP HL

; ======================================================================
; NUMBER <-> ASCII (FOUT formatter)
; ======================================================================
; MS BASIC-80 FOUT: convert the FP value in the FAC ($0CB1) to a printable decimal ASCII string (sign $2B/$2D, digits, decimal point, E-exponent). Used by PRINT, STR$, and the sign-on free-bytes report. Value type read from $0B14.
FOUT:
        LD BC,PUT_STR_TEMP_2
        PUSH BC
        CALL FP_STORE_FAC_INT
        XOR A
        CALL FOUT_SET_FORMAT
        OR (HL)
        JP FOUT_BODY_2
; [RE] MS BASIC-80 FOUT: convert FAC (mantissa $0CB1 / exp $0CB4 / type $0B14) to a decimal/exponential ASCII string in the $0CC3 buffer, A=0 -> no format flags. Returns HL -> string. Used by STR$/PRINT/LIST.
FOUT_2:
        XOR A
; [RE] FOUT with PRINT USING format flags in A (stored to $0B4A via FOUT_SET_FORMAT); handles sign placement then dispatches by value type.
FOUT_BODY:
        CALL FOUT_SET_FORMAT
        AND $08
        JR Z,FOUT_BODY_1
        LD (HL),$2B
FOUT_BODY_1:
        EX DE,HL
        CALL FP_TEST_SIGN
        EX DE,HL
        JP P,FOUT_BODY_2
        LD (HL),$2D
        PUSH BC
        PUSH HL
        CALL FP_NEGATE_CHECKED
        POP HL
        POP BC
        OR H
FOUT_BODY_2:
        INC HL
        LD (HL),$30
        LD A,(L_0B4A)
        LD D,A
        RLA
        LD A,(VALTYP)
        JP C,FOUT_EXPONENT_5
        JP Z,FOUT_EXPONENT_3
        CP VT_SNG
        JP NC,FOUT_DOUBLE_FMT
        LD BC,$0000
        CALL FOUT_DIGITS_INT
; [RE] PRINT USING numeric-field scanner: walks the format-image field at $0CC3 ('#', '.', ',', '$', '*', '+', 'E/D' exponent), records width/flags, and rewrites fill characters (space/'*'/'$').
PRUSING_FIELD:
        LD HL,L_0CC3
        LD B,(HL)
        LD C,$20
        LD A,(L_0B4A)
        LD E,A
        AND $20
        JR Z,PRUSING_FIELD_1
        LD A,B
        CP C
        LD C,$2A
        JR NZ,PRUSING_FIELD_1
        LD A,E
        AND $04
        JP NZ,PRUSING_FIELD_1
        LD B,C
PRUSING_FIELD_1:
        LD (HL),C
        CALL CHRGET
        JR Z,PRUSING_FIELD_2
        CP $45
        JR Z,PRUSING_FIELD_2
        CP $44
        JR Z,PRUSING_FIELD_2
        CP $30
        JR Z,PRUSING_FIELD_1
        CP $2C
        JR Z,PRUSING_FIELD_1
        CP $2E
        JR NZ,PRUSING_FIELD_3
PRUSING_FIELD_2:
        DEC HL
        LD (HL),$30
PRUSING_FIELD_3:
        LD A,E
        AND $10
        JR Z,PRUSING_FIELD_4
        DEC HL
        LD (HL),$24
PRUSING_FIELD_4:
        LD A,E
        AND $04
        RET NZ
        DEC HL
        LD (HL),B
        RET
; [RE] Store the PRINT USING format byte (A) to $0B4A and reset the output buffer head ($0CC3) to a leading space.
FOUT_SET_FORMAT:
        LD (L_0B4A),A
        LD HL,L_0CC3
        LD (HL),$20
        RET
; [RE] FIN core (ASCII -> floating): scans the digit/decimal/exponent text, counts integer+fraction digits, parses the E/D exponent ($CB8 = exp-overflow flag), and converts via the decimal-accumulate path (CALLs FOUT_DIGITS_* / power-of-ten scaling). Returns the value in FAC.
FOUT_DOUBLE_FMT:
        CALL FAC_PUSH
        EX DE,HL
        LD HL,(L_0CAD)
        PUSH HL
        LD HL,(L_0CAF)
        PUSH HL
        EX DE,HL
        PUSH AF
        XOR A
        LD (L_0CB8),A
        POP AF
        PUSH AF
        CALL FOUT_CORE
        LD B,$45
        LD C,$00
FOUT_SET_FORMAT_2:
        PUSH HL
        LD A,(HL)
FOUT_SET_FORMAT_3:
        CP B
        JP Z,FOUT_SET_FORMAT_6
        CP $3A
        JP NC,FOUT_SET_FORMAT_4
        CP $30
        JP C,FOUT_SET_FORMAT_4
        INC C
FOUT_SET_FORMAT_4:
        INC HL
        LD A,(HL)
        OR A
        JP NZ,FOUT_SET_FORMAT_3
        LD A,$44
        CP B
        LD B,A
        POP HL
        LD C,$00
        JP NZ,FOUT_SET_FORMAT_2
FOUT_SET_FORMAT_5:
        POP AF
        POP BC
        POP DE
        EX DE,HL
        LD (L_0CAD),HL
        LD H,B
        LD L,C
        LD (L_0CAF),HL
        EX DE,HL
        POP BC
        POP DE
        RET
FOUT_SET_FORMAT_6:
        PUSH BC
        LD B,$00
        INC HL
        LD A,(HL)
FOUT_SET_FORMAT_7:
        CP $2B
        JP Z,SUB_5822_3
        CP $2D
        JP Z,FOUT_SET_FORMAT_8
        SUB $30
        LD C,A
        LD A,B
        ADD A,A
        ADD A,A
        ADD A,B
        ADD A,A
        ADD A,C
        LD B,A
        CP $10
        JP NC,SUB_5822_3
FOUT_SET_FORMAT_8:
        INC HL
        LD A,(HL)
        OR A
        JP NZ,FOUT_SET_FORMAT_7
        LD H,B
        POP BC
        LD A,B
        CP $45
        JP NZ,SUB_5822_2
        LD A,C
        ADD A,H
        CP $09
        POP HL
        JP NC,FOUT_SET_FORMAT_5
SUB_5822_1:
        LD A,$80
        LD (L_0CB8),A
        JP SUB_5822_4
SUB_5822_2:
        LD A,H
        ADD A,C
        CP $12
        POP HL
        JP NC,FOUT_SET_FORMAT_5
        JP SUB_5822_1
SUB_5822_3:
        POP BC
        POP HL
        JP FOUT_SET_FORMAT_5
SUB_5822_4:
        POP AF
        POP BC
        POP DE
        EX DE,HL
        LD (L_0CAD),HL
        LD H,B
        LD L,C
        LD (L_0CAF),HL
        EX DE,HL
        POP BC
        POP DE
        CALL FP_STORE_FAC
        INC HL
; [RE] FOUT decimal core: rounds the FAC to N significant digits, computes the base-10 exponent, generates the digit string and trims trailing zeros; decides fixed vs E-notation.
FOUT_CORE:
        CP $05
        PUSH HL
        SBC A,$00
        RLA
        LD D,A
        INC D
        CALL FOUT_SCALE10
        LD BC,$0300
        PUSH AF
        LD A,(L_0CB8)
        OR A
        JP P,FOUT_CORE_1
        POP AF
        ADD A,D
        JP FOUT_CORE_2
FOUT_CORE_1:
        POP AF
        ADD A,D
        JP M,FOUT_CORE_3
        INC D
        CP D
        JR NC,FOUT_CORE_3
FOUT_CORE_2:
        INC A
        LD B,A
        LD A,$02
FOUT_CORE_3:
        SUB $02
        POP HL
        PUSH AF
        CALL FOUT_LEADING_FRAC
        LD (HL),$30
        CALL Z,FP_LOAD_DONE
        CALL FOUT_DIGITS_FRAC
FOUT_CORE_4:
        DEC HL
        LD A,(HL)
        CP $30
        JR Z,FOUT_CORE_4
        CP $2E
        CALL NZ,FP_LOAD_DONE
        POP AF
        JR Z,FOUT_EXPONENT_4
; [RE] Append the exponent suffix (E/D, sign, two decimal digits) to the formatted number and NUL-terminate; also the PRINT USING field-assembly path that interleaves the digit string with the format image (commas, '$', '*', '+'/'-').
FOUT_EXPONENT:
        PUSH AF
        CALL FRMEVL_TEST_TYPE
        LD A,$22
        ADC A,A
        LD (HL),A
        INC HL
        POP AF
        LD (HL),$2B
        JP P,FOUT_EXPONENT_1
        LD (HL),$2D
        CPL
        INC A
FOUT_EXPONENT_1:
        LD B,$2F
FOUT_EXPONENT_2:
        INC B
        SUB $0A
        JR NC,FOUT_EXPONENT_2
        ADD A,$3A
        INC HL
        LD (HL),B
        INC HL
        LD (HL),A
FOUT_EXPONENT_3:
        INC HL
FOUT_EXPONENT_4:
        LD (HL),$00
        EX DE,HL
        LD HL,L_0CC3
        RET
FOUT_EXPONENT_5:
        INC HL
        PUSH BC
        CP $04
        LD A,D
        JP NC,FOUT_EXPONENT_14
        RRA
        JP C,FOUT_EXPONENT_24
        LD BC,$0603
        CALL PRUSING_COMMA_FLAG
        POP DE
        LD A,D
        SUB $05
        CALL P,FOUT_EMIT_ZEROS
        CALL FOUT_DIGITS_INT
FOUT_EXPONENT_6:
        LD A,E
        OR A
        CALL Z,DEC_HL_RET
        DEC A
        CALL P,FOUT_EMIT_ZEROS
FOUT_EXPONENT_7:
        PUSH HL
        CALL PRUSING_FIELD
        POP HL
        JR Z,FOUT_EXPONENT_8
        LD (HL),B
        INC HL
FOUT_EXPONENT_8:
        LD (HL),$00
        LD HL,L_0CC2
FOUT_EXPONENT_9:
        INC HL
FOUT_EXPONENT_10:
        LD A,(FRMEVL_TXTPTR_TEMP)
        SUB L
        SUB D
        RET Z
        LD A,(HL)
        CP $20
        JR Z,FOUT_EXPONENT_9
        CP $2A
        JR Z,FOUT_EXPONENT_9
        DEC HL
        PUSH HL
FOUT_EXPONENT_11:
        PUSH AF
        LD BC,FOUT_EXPONENT_11
        PUSH BC
        CALL CHRGET
        CP $2D
        RET Z
        CP $2B
        RET Z
        CP $24
        RET Z
        POP BC
        CP $30
        JR NZ,FOUT_EXPONENT_13
        INC HL
        CALL CHRGET
        JR NC,FOUT_EXPONENT_13
        DEC HL
; [RE] FOUT trailing-zero strip-loop overlap (VERIFIED). 01 2B 77 = LD BC,$772B runs once on first entry; the JR Z self-loop (28 FB at $5928) re-enters at +1, skipping the 01 opcode (BC kept) and re-executing 2B 77 = DEC HL / LD (HL),A as the loop body. The LD BC operand bytes double as the strip-and-overwrite step. MBASIC FOUT_EXPONENT_13 byte-identical.
FOUT_EXPONENT_12:
        LD BC,$772B
        POP AF
        JR Z,FOUT_EXPONENT_12+1
        POP BC
        JP FOUT_EXPONENT_10
FOUT_EXPONENT_13:
        POP AF
        JR Z,FOUT_EXPONENT_13
        POP HL
        LD (HL),$25
        RET
FOUT_EXPONENT_14:
        PUSH HL
        RRA
        JP C,FOUT_EXPONENT_25
        JR Z,FOUT_EXPONENT_16
        LD DE,FP_CONST_ENOTATION_THRESHOLD
        CALL DCOMP
        LD D,$10
        JP M,FOUT_EXPONENT_17
FOUT_EXPONENT_15:
        POP HL
        POP BC
        CALL FOUT_2
        DEC HL
        LD (HL),$25
        RET
FOUT_EXPONENT_16:
        LD BC,$B60E
        LD DE,$1BCA
        CALL FCOMP
        JP P,FOUT_EXPONENT_15
        LD D,$06
FOUT_EXPONENT_17:
        CALL FP_SIGN
        CALL NZ,FOUT_SCALE10
        POP HL
        POP BC
        JP M,FOUT_EXPONENT_18
        PUSH BC
        LD E,A
        LD A,B
        SUB D
        SUB E
        CALL P,FOUT_EMIT_ZEROS
        CALL PRUSING_DIGIT_COUNT
        CALL FOUT_DIGITS_FRAC
        OR E
        CALL NZ,FOUT_EMIT_ZERO_LOOP
        OR E
        CALL NZ,FOUT_DIGIT_SEP
        POP DE
        JP FOUT_EXPONENT_6
FOUT_EXPONENT_18:
        LD E,A
        LD A,C
        OR A
        CALL NZ,DEC_A_RET
        ADD A,E
        JP M,FOUT_EXPONENT_19
        XOR A
FOUT_EXPONENT_19:
        PUSH BC
        PUSH AF
FOUT_EXPONENT_20:
        CALL M,FIN_DIV10
        JP M,FOUT_EXPONENT_20
        POP BC
        LD A,E
        SUB B
        POP BC
        LD E,A
        ADD A,D
        LD A,B
        JP M,FOUT_EXPONENT_21
        SUB D
        SUB E
        CALL P,FOUT_EMIT_ZEROS
        PUSH BC
        CALL PRUSING_DIGIT_COUNT
        JR FOUT_EXPONENT_22
FOUT_EXPONENT_21:
        CALL FOUT_EMIT_ZEROS
        LD A,C
        CALL FOUT_DECIMAL_POINT
        LD C,A
        XOR A
        SUB D
        SUB E
        CALL FOUT_EMIT_ZEROS
        PUSH BC
        LD B,A
        LD C,A
FOUT_EXPONENT_22:
        CALL FOUT_DIGITS_FRAC
        POP BC
        OR C
        JR NZ,FOUT_EXPONENT_23
        LD HL,(FRMEVL_TXTPTR_TEMP)
FOUT_EXPONENT_23:
        ADD A,E
        DEC A
        CALL P,FOUT_EMIT_ZEROS
        LD D,B
        JP FOUT_EXPONENT_7
FOUT_EXPONENT_24:
        PUSH HL
        PUSH DE
        CALL INT_TO_SINGLE
        POP DE
        XOR A
FOUT_EXPONENT_25:
        JP Z,FOUT_EXPONENT_26+1
        LD E,$10
; [RE] FOUT field-select flag-skip (VERIFIED, reached_cover refined). The NZ entry (JP C,FOUT_EXPONENT_25 at $5937 reaching $59D6 with Z clear, then $59D9 LD E,$10) runs 01 1E 06 = LD BC,$061E; the Z entry (JP Z,FOUT_EXPONENT_26+1 at $59D6) enters at +1 and runs 1E 06 = LD E,$06, skipping the LD BC opcode. So E becomes $10 (16) vs $06 (6). Both converge at $59DE CALL FP_SIGN. Note: the local $59D5 XOR A always forces the +1 path; the cover is exercised only via the external $5937 NZ entry. MBASIC FOUT_EXPONENT_29 byte-identical.
FOUT_EXPONENT_26:
        LD BC,$061E
        CALL FP_SIGN
        SCF
        CALL NZ,FOUT_SCALE10
        POP HL
        POP BC
        PUSH AF
        LD A,C
        OR A
        PUSH AF
        CALL NZ,DEC_A_RET
        ADD A,B
        LD C,A
        LD A,D
        AND $04
        CP $01
        SBC A,A
        LD D,A
        ADD A,C
        LD C,A
        SUB E
        PUSH AF
        PUSH BC
FOUT_EXPONENT_27:
        CALL M,FIN_DIV10
        JP M,FOUT_EXPONENT_27
        POP BC
        POP AF
        PUSH BC
        PUSH AF
        JP M,FOUT_EXPONENT_28
        XOR A
FOUT_EXPONENT_28:
        CPL
        INC A
        ADD A,B
        INC A
        ADD A,D
        LD B,A
        LD C,$00
        CALL FOUT_DIGITS_FRAC
        POP AF
        CALL P,FOUT_EMIT_ZEROS_DP
        CALL FOUT_DIGIT_SEP
        POP BC
        POP AF
        JP NZ,FOUT_EXPONENT_29
        CALL DEC_HL_RET
        LD A,(HL)
        CP $2E
        CALL NZ,FP_LOAD_DONE
        LD (FRMEVL_TXTPTR_TEMP),HL
FOUT_EXPONENT_29:
        POP AF
        JR C,FOUT_EXPONENT_30
        ADD A,E
        SUB B
        SUB D
FOUT_EXPONENT_30:
        PUSH BC
        CALL FOUT_EXPONENT
        EX DE,HL
        POP DE
        JP FOUT_EXPONENT_7
; [RE] Scale FAC into the [1,10) digit-generation range by repeated multiply/divide by powers of ten (tables at $5BC0/$5BC8/$5BD0), tracking the decimal exponent in the saved counter.
FOUT_SCALE10:
        PUSH DE
        XOR A
        PUSH AF
        CALL FRMEVL_TEST_TYPE
        JP PO,FOUT_SCALE10_2
FOUT_SCALE10_1:
        LD A,(L_0CB4)
        CP $91
        JP NC,FOUT_SCALE10_2
        LD DE,FOUT_DIGITS_INT_3
        LD HL,L_0CBA
        CALL FP_MOVE_TYPED
        CALL DMUL
        POP AF
        SUB $0A
        PUSH AF
        JR FOUT_SCALE10_1
FOUT_SCALE10_2:
        CALL FOUT_SCALE10_STEP
FOUT_SCALE10_3:
        CALL FRMEVL_TEST_TYPE
        JP PE,FOUT_SCALE10_4
        LD BC,$9143
        LD DE,$4FF9
        CALL FCOMP
        JR FOUT_SCALE10_5
FOUT_SCALE10_4:
        LD DE,FOUT_DIGITS_INT_4
        CALL DCOMP
FOUT_SCALE10_5:
        JP P,FOUT_SCALE10_7
        POP AF
        CALL FIN_MUL10_DO
        PUSH AF
        JR FOUT_SCALE10_3
FOUT_SCALE10_6:
        POP AF
        CALL FIN_DIV10
        PUSH AF
        CALL FOUT_SCALE10_STEP
FOUT_SCALE10_7:
        POP AF
        OR A
        POP DE
        RET
; [RE] One power-of-ten comparison/normalize step for FOUT_SCALE10: compares FAC against 10 / 1e-? bounds and multiplies or divides as needed.
FOUT_SCALE10_STEP:
        CALL FRMEVL_TEST_TYPE
        JP PE,FOUT_SCALE10_STEP_1
        LD BC,$9474
        LD DE,$23F8
        CALL FCOMP
        JR FOUT_SCALE10_STEP_2
FOUT_SCALE10_STEP_1:
        LD DE,FOUT_DIGITS_INT_5
        CALL DCOMP
FOUT_SCALE10_STEP_2:
        POP HL
        JP P,FOUT_SCALE10_6
        JP (HL)
; [RE] Emit A leading/trailing '0' digits into the output buffer (HL), decrementing A to zero.
FOUT_EMIT_ZEROS:
        OR A
FOUT_EMIT_ZEROS_1:
        RET Z
        DEC A
        LD (HL),$30
        INC HL
        JR FOUT_EMIT_ZEROS_1
; [RE] Emit A '0' digits, inserting the decimal point / comma separators via FOUT_DIGIT_SEP as the digit position requires (PRINT USING fractional fill).
FOUT_EMIT_ZEROS_DP:
        JR NZ,FOUT_EMIT_ZERO_LOOP
FOUT_EMIT_ZEROS_DP_1:
        RET Z
        CALL FOUT_DIGIT_SEP
; [RE] Inner loop: store a '0' digit, advance, decrement count (shared tail of FOUT_EMIT_ZEROS_DP).
FOUT_EMIT_ZERO_LOOP:
        LD (HL),$30
        INC HL
        DEC A
        JR FOUT_EMIT_ZEROS_DP_1
; [RE] Compute the comma-group digit counter (C) and total digit width (B) for a PRINT USING numeric field from the integer/fraction digit counts in D/E.
PRUSING_DIGIT_COUNT:
        LD A,E
        ADD A,D
        INC A
        LD B,A
        INC A
PRUSING_DIGIT_COUNT_1:
        SUB $03
        JR NC,PRUSING_DIGIT_COUNT_1
        ADD A,$05
        LD C,A
; [RE] Test the PRINT USING comma-grouping flag (bit 6 of format byte $0B4A); returns with C set/cleared to enable thousands separators.
PRUSING_COMMA_FLAG:
        LD A,(L_0B4A)
        AND $40
        RET NZ
        LD C,A
        RET
; [RE] Emit the decimal point plus leading-zero run for a pure-fraction value (|x|<1): records the decimal-point position at $0B69 and fills '0' digits.
FOUT_LEADING_FRAC:
        DEC B
        JP P,FOUT_DIGIT_SEP_1
        LD (FRMEVL_TXTPTR_TEMP),HL
        LD (HL),$2E
FOUT_LEADING_FRAC_1:
        INC HL
        LD (HL),$30
        INC B
        JP NZ,FOUT_LEADING_FRAC_1
        INC HL
        LD C,B
        RET
; [RE] Per-digit separator emitter: drops the decimal point ('.', records pos at $0B69) when the integer digits are exhausted, or a comma every 3 digits when grouping is enabled.
FOUT_DIGIT_SEP:
        DEC B
FOUT_DIGIT_SEP_1:
        JR NZ,FOUT_DECIMAL_POINT_1
; [RE] Emit the decimal point '.', record its buffer position at $0B69, and (when grouping) reseed the comma counter to 3.
FOUT_DECIMAL_POINT:
        LD (HL),$2E
        LD (FRMEVL_TXTPTR_TEMP),HL
        INC HL
        LD C,B
        RET
FOUT_DECIMAL_POINT_1:
        DEC C
        RET NZ
        LD (HL),$2C
        INC HL
        LD C,$03
        RET
; [RE] Generate fractional decimal digits: repeatedly multiply the FAC fraction by 10 (via the BCD constant tables $5BD8/$5BE8/$5C2E) and emit each integer digit through FOUT_DIGIT_SEP.
FOUT_DIGITS_FRAC:
        PUSH DE
        CALL FRMEVL_TEST_TYPE
        JP PO,FOUT_DIGITS_FRAC_3
        PUSH BC
        PUSH HL
        CALL FP_ARG_TO_TEMP2
        LD HL,FP_CONST_HALF_DBL
        CALL FP_ARG_SETUP1
        CALL DADD
        XOR A
        CALL FIX_DENORM
        POP HL
        POP BC
        LD DE,FP_POW10_FRAC_TABLE
        LD A,$0A
FOUT_DIGITS_FRAC_1:
        CALL FOUT_DIGIT_SEP
        PUSH BC
        PUSH AF
        PUSH HL
        PUSH DE
        LD B,$2F
FOUT_DIGITS_FRAC_2:
        INC B
        POP HL
        PUSH HL
        LD A,$9E
        CALL DP_ADD_BLOCK
        JR NC,FOUT_DIGITS_FRAC_2
        POP HL
        LD A,$8E
        CALL DP_ADD_BLOCK
        EX DE,HL
        POP HL
        LD (HL),B
        INC HL
        POP AF
        POP BC
        DEC A
        JR NZ,FOUT_DIGITS_FRAC_1
        PUSH BC
        PUSH HL
        LD HL,L_0CAD
        CALL FP_STORE_REGS_LD
        JR FOUT_DIGITS_FRAC_4
FOUT_DIGITS_FRAC_3:
        PUSH BC
        PUSH HL
        CALL FADD_LOAD_CONST
        LD A,$01
        CALL FP_SHIFT_MANTISSA
        CALL FP_STORE_FAC
FOUT_DIGITS_FRAC_4:
        POP HL
        POP BC
        XOR A
        LD DE,FP_POW10_FRAC_TABLE2
FOUT_DIGITS_FRAC_5:
        CCF
        CALL FOUT_DIGIT_SEP
        PUSH BC
        PUSH AF
        PUSH HL
        PUSH DE
        CALL FP_LOAD_FAC
        POP HL
        LD B,$2F
FOUT_DIGITS_FRAC_6:
        INC B
        LD A,E
        SUB (HL)
        LD E,A
        INC HL
        LD A,D
        SBC A,(HL)
        LD D,A
        INC HL
        LD A,C
        SBC A,(HL)
        LD C,A
        DEC HL
        DEC HL
        JR NC,FOUT_DIGITS_FRAC_6
        CALL MANT_ADD
        INC HL
        CALL FP_STORE_FAC
        EX DE,HL
        POP HL
        LD (HL),B
        INC HL
        POP AF
        POP BC
        JR C,FOUT_DIGITS_FRAC_5
        INC DE
        INC DE
        LD A,$04
        JR FOUT_DIGITS_INT_1
; [RE] Generate integer decimal digits by repeated subtraction of the power-of-ten table at $5C34 (10000/1000/100/10/1) from the FAC mantissa $0CB1, emitting each via FOUT_DIGIT_SEP.
FOUT_DIGITS_INT:
        PUSH DE
        LD DE,POW10_INT_TABLE
        LD A,$05
FOUT_DIGITS_INT_1:
        CALL FOUT_DIGIT_SEP
        PUSH BC
        PUSH AF
        PUSH HL
        EX DE,HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        PUSH BC
        INC HL
        EX (SP),HL
        EX DE,HL
        LD HL,(FAC)
        LD B,$2F
FOUT_DIGITS_INT_2:
        INC B
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        JR NC,FOUT_DIGITS_INT_2
        ADD HL,DE
        LD (FAC),HL
        POP DE
        POP HL
        LD (HL),B
        INC HL
        POP AF
        POP BC
        DEC A
        JR NZ,FOUT_DIGITS_INT_1
        CALL FOUT_DIGIT_SEP
        LD (HL),A
        POP DE
        RET
FOUT_DIGITS_INT_3:
        NOP
        NOP
        NOP
        NOP
        LD SP,HL
        LD (BC),A
        DEC D
        AND D
FOUT_DIGITS_INT_4:
        POP HL
        RST $38
        SBC A,A
        LD SP,$5FA9
        LD H,E
        OR D
FOUT_DIGITS_INT_5:
        CP $FF
        INC BC
        CP A
        RET
        DEC DE
        LD C,$B6
; [RE] Double-precision 0.5 rounding-bias FP constant: DADD'd to the value before FIX in FN_LPOS ($4F86) and in the fractional-digit generator ($5B05) to round-to-nearest [RE] MBF double-precision constant 0.5.
FP_CONST_HALF_DBL:
        NOP
        NOP
        NOP
        NOP
; [RE] Single-precision 0.5 rounding constant loaded by FADD_LOAD_CONST/FADDT ($4B98, $5C90): added to the FAC during single-precision round-before-truncate in FOUT/FIX [RE] MBF single-precision constant 0.5.
FP_CONST_HALF_SNG:
        NOP
        NOP
        NOP
        ADD A,B
; [RE] FP magnitude threshold constant compared via DCOMP in the FOUT exponent path ($593C): the value above which numeric output switches to E (scientific) notation
FP_CONST_ENOTATION_THRESHOLD:
        NOP
        NOP
        INC B
        CP A
        RET
        DEFB    $1B,$0E,$B6
; [RE] Double-precision power-of-ten (negative-exponent) table used by FOUT_DIGITS_FRAC ($5B14): each fractional decimal digit extracted by repeated subtraction of these scaled-ten constants from the FAC fraction
FP_POW10_FRAC_TABLE:
        DEFB    $00,$80,$C6,$A4,$7E,$8D,$03,$00,$40,$7A,$10,$F3,$5A,$00,$00,$A0
        DEFB    $72,$4E,$18,$09,$00,$00,$10,$A5,$D4,$E8,$00,$00,$00,$E8,$76,$48
        DEFB    $17,$00,$00,$00,$E4,$0B,$54,$02,$00,$00,$00,$CA,$9A,$3B,$00,$00
        DEFB    $00,$00,$E1,$F5,$05,$00,$00,$00,$80,$96,$98,$00,$00,$00,$00,$40
        DEFB    $42,$0F,$00,$00,$00,$00
; [RE] Second double-precision power-of-ten constant block for fractional-digit generation (loaded as DE at $5B55 in the FOUT fraction loop), companion to the $5BE8 table
FP_POW10_FRAC_TABLE2:
        DEFB    $A0,$86,$01,$10,$27,$00
; [RE] Little-endian integer power-of-ten table 10000/1000/100/10/1 ($10 27 / E8 03 / 64 00 / 0A 00 / 01 00) used by FOUT_DIGITS_INT ($5B8C): each integer decimal digit produced by repeated subtraction from the FAC mantissa
POW10_INT_TABLE:
        DEFB    $10,$27,$E8,$03,$64,$00,$0A,$00,$01,$00
; [RE] HEX$/OCT$ and LIST &H/&O converter: turns the 16-bit integer in HL into a hex (4 nibbles) or octal (6 groups) ASCII string at $0CC2; B selects base (0=octal width, hex entry at $5C41). Dispatched from the LIST detokenizer ($41FD/$4202).
HEX_OCT_OUT:
        XOR A
        LD B,A
; [RE] HEX$/OCT$ base-selector flag-skip (VERIFIED). Octal entry ($5C3E) does XOR A / LD B,A (B=0) then C2 06 01 = JP NZ,$0106, never taken (Z set), skipping its operand so B stays 0. Hex callers (JP/CALL HEX_OCT_OUT_1+1 at $4202/$6BB4) enter at +1 and run 06 01 = LD B,$01 (B=1). DEC B/INC B at $5C4E then picks C=$06 octal groups vs C=$04 hex nibbles. Converge at $5C43 PUSH BC. MBASIC twin (POW10_INT_TABLE region) byte-identical.
HEX_OCT_OUT_1:
        JP NZ,$0106
        PUSH BC
        CALL GETADR
        POP BC
        LD DE,L_0CC2
        PUSH DE
        XOR A
        LD (DE),A
        DEC B
        INC B
        LD C,$06
        JR Z,HEX_OCT_OUT_4
        LD C,$04
HEX_OCT_OUT_2:
        ADD HL,HL
        ADC A,A
HEX_OCT_OUT_3:
        ADD HL,HL
        ADC A,A
        ADD HL,HL
        ADC A,A
HEX_OCT_OUT_4:
        ADD HL,HL
        ADC A,A
        OR A
        JP NZ,HEX_OCT_OUT_5
        LD A,C
        DEC A
        JP Z,HEX_OCT_OUT_5
        LD A,(DE)
        OR A
        JP Z,HEX_OCT_OUT_7
        XOR A
HEX_OCT_OUT_5:
        ADD A,$30
        CP $3A
        JP C,HEX_OCT_OUT_6
        ADD A,$07
HEX_OCT_OUT_6:
        LD (DE),A
        INC DE
        LD (DE),A
HEX_OCT_OUT_7:
        XOR A
        DEC C
        JR Z,HEX_OCT_OUT_8
        DEC B
        INC B
        JP Z,HEX_OCT_OUT_3
        JP HEX_OCT_OUT_2
HEX_OCT_OUT_8:
        LD (DE),A
        POP HL
        RET
; [RE] Helper that pushes the FAC-negate routine ($4E76) as a return address then JP (HL); used to conditionally negate the FAC in the transcendental handlers.
FAC_NEGATE_VIA:
        LD HL,FP_NEG
        EX (SP),HL
        JP (HL)
; [RE] SQR(x) handler (function token $07): square root (MBF).
FN_SQR:
        CALL FAC_PUSH
        LD HL,FP_CONST_HALF_SNG
        CALL FP_STORE_REGS_LD
        JR FN_SQR_2
FN_SQR_1:
        CALL FN_CSNG
FN_SQR_2:
        POP BC
        POP DE
        LD HL,GFX_CLR_REVERSE_FLAG
        PUSH HL
        LD A,$01
        LD (L_0CB6),A
        CALL FP_SIGN
        LD A,B
        JR Z,FN_EXP
        JP P,FN_SQR_3
        OR A
        JP Z,FIN_DONE_18
FN_SQR_3:
        OR A
        JP Z,FP_SET_ZERO_1
        PUSH DE
        PUSH BC
        LD A,C
        OR $7F
        CALL FP_LOAD_FAC
        JP P,FN_SQR_4
        PUSH DE
        PUSH BC
        CALL FIX_SCALE
        POP BC
        POP DE
        PUSH AF
        CALL FCOMP
        POP HL
        LD A,H
        RRA
FN_SQR_4:
        POP HL
        LD (FACHI),HL
        POP HL
        LD (FAC),HL
        CALL C,FAC_NEGATE_VIA
        CALL Z,FP_NEG
        PUSH DE
        PUSH BC
        CALL FN_LOG
        POP BC
        POP DE
        CALL FMUL
; [RE] EXP(x) handler (function token $0B): e raised to x (MBF).
FN_EXP:
        LD BC,$8138
        LD DE,$AA3B
        CALL FMUL
        LD A,(L_0CB4)
        CP $88
        JP NC,FN_EXP_1
        CP $68
        JP C,FN_EXP_4
        CALL FAC_PUSH
        CALL FIX_SCALE
        ADD A,$81
        POP BC
        POP DE
        JP Z,FN_EXP_2
        PUSH AF
        CALL FSUB
        LD HL,FP_POLY_EXP_COEFFS
        CALL POLY_EVAL
        POP BC
        LD DE,$0000
        LD C,D
        JP FMUL
FN_EXP_1:
        CALL FAC_PUSH
FN_EXP_2:
        LD A,(FACHI)
        OR A
        JP P,FN_EXP_3
        POP AF
        POP AF
        JP FP_SET_ZERO
FN_EXP_3:
        JP FIN_DONE_9
FN_EXP_4:
        LD BC,$8100
        LD DE,$0000
        CALL FP_STORE_FAC
        RET
; [RE] EXP() coefficient pool: MBF polynomial { count byte; N x 4-byte MBF } with count=$07 -> 7 coefficients ($5D3A-$5D55). Evaluated by POLY_EVAL (Horner) from FN_EXP ($5D0F/$5D12) to approximate 2^f for the fractional part f after FN_EXP scales x by log2(e) and splits off the integer exponent (FIX_SCALE).
FP_POLY_EXP_COEFFS:
        DEFB    $07,$7C,$88,$59,$74,$E0,$97,$26,$77,$C4,$1D,$1E,$7A,$5E,$50,$63
        DEFB    $7C,$1A,$FE,$75,$7E,$18,$72,$31,$80,$00,$00,$00,$81
; [RE] Odd-power polynomial evaluator: forms x*P(x^2) for the series approximations (SIN/ATN/TAN), squaring the argument then calling the Horner evaluator POLY_EVAL.
POLY_EVAL_ODD:
        CALL FAC_PUSH
        LD DE,IMUL_6
        PUSH DE
        PUSH HL
        CALL FP_LOAD_FAC
        CALL FMUL
        POP HL
; [RE] MS BASIC-80 polynomial (Horner) evaluator: HL -> coefficient table (count byte then MBF coefficients); repeatedly FMUL by the argument and FADD the next coefficient. Shared by LOG/EXP/SIN/COS/TAN/ATN.
POLY_EVAL:
        CALL FAC_PUSH
        LD A,(HL)
        INC HL
        CALL FP_STORE_REGS_LD
; [RE] VERIFIED flag-skip. POLY_EVAL_1 ($5D6D) opcode-eating dual entry. First pass (fall-through from FP_STORE_REGS_LD CALL at $5D6A) executes LD B,$F1 (06 F1); the $06 opcode swallows the $F1, so the first iteration pops only BC,DE. The Horner loop re-enters via JR POLY_EVAL_1+1 ($5D6E), running $F1 as POP AF to discard the per-iteration PUSH AF ($5D75) before popping BC,DE. B=$F1 is dead (overwritten by POP BC at $5D6F). Cover is genuinely executed on fall-through; MBASIC twin byte-identical.
POLY_EVAL_1:
        LD B,$F1
        POP BC
        POP DE
        DEC A
        RET Z
        PUSH DE
        PUSH BC
        PUSH AF
        PUSH HL
        CALL FMUL
        POP HL
        CALL FP_LOAD_MEM
        PUSH HL
        CALL FADD_ALIGN
        POP HL
        JR POLY_EVAL_1+1
L_5D85:
        DEFB    $52,$C7,$4F,$80
POLY_EVAL_2:
        CALL CHRGET
; [RE] Evaluate a polynomial in sqrt(x): pushes the argument, runs FN_SQR, then evaluates the series via POLY_EVAL (used by the ATN/LOG support path called at $4486).
POLY_EVAL_SQR:
        PUSH HL
        LD HL,L_4CA6
        CALL FP_STORE_REGS_LD
        CALL FN_RND
        POP HL
        JP SET_TYPE_DOUBLE_1+1
; [RE] RND(x) handler (function token $08): pseudo-random number; updates/reads the RND seed (RNDX_SEED).
FN_RND:
        CALL FP_SIGN
        LD HL,FN_RND_6
        JP M,FN_RND_3
        LD HL,RNDX_SEED
        CALL FP_STORE_REGS_LD
        LD HL,FN_RND_6
        RET Z
        ADD A,(HL)
        AND $07
        LD B,$00
        LD (HL),A
        INC HL
        ADD A,A
        ADD A,A
        LD C,A
        ADD HL,BC
        CALL FP_LOAD_MEM
        CALL FMUL
        LD A,(FN_RND_5)
        INC A
        AND $03
        LD B,$00
        CP $01
        ADC A,B
        LD (FN_RND_5),A
        LD HL,RNDX_SEED
        ADD A,A
        ADD A,A
        LD C,A
        ADD HL,BC
        CALL FADD_FROM_MEM
FN_RND_1:
        CALL FP_LOAD_FAC
        LD A,E
        LD E,C
        XOR $4F
        LD C,A
        LD (HL),$80
        DEC HL
        LD B,(HL)
        LD (HL),$80
        LD HL,FN_RND_4
        INC (HL)
        LD A,(HL)
        SUB $AB
        JR NZ,FN_RND_2
        LD (HL),A
        INC C
        DEC D
        INC E
FN_RND_2:
        CALL FADD
        LD HL,RNDX_SEED
        JP FP_MOVE_TO_FAC
FN_RND_3:
        LD (HL),A
        DEC HL
        LD (HL),A
        DEC HL
        LD (HL),A
        JR FN_RND_1
FN_RND_4:
        NOP
FN_RND_5:
        NOP
FN_RND_6:
        NOP
        DEC (HL)
        LD C,D
        JP Z,$3999
        INC E
        HALT
        DEFB    $98,$22,$95,$B3,$98,$0A,$DD,$47,$98,$53,$D1,$99,$99,$0A,$1A,$9F
        DEFB    $98,$65,$BC,$CD,$98,$D6,$77,$3E,$98
; [RE] RND seed (RNDX) work cell, low byte of the 4-byte running random state at $5E24-$5E27. CLEAR/RUN re-initializes it from a default constant ($68AE FP_MOVE4 from $5D85); FN_RND multiplies/updates it; also reused as FP scratch by FN_SQR ($5DA3/$5DCC/$5DF4)
RNDX_SEED:
        DEFB    "R"
; [RE] RND seed mantissa word (upper 3 bytes of the RNDX state at $5E25-$5E27): RANDOMIZE stores the new seed here via STMT_RANDOMIZE_3 ($4483 LD ($5E25),HL)
RNDX_SEED_WORD:
        DEFB    $C7,$4F,$80,$68,$B1,$46,$68,$99,$E9,$92,$69,$10,$D1,$75,$68
; [RE] COS(x) handler (function token $0C): cosine; adds a quarter period and falls into the SIN path.
FN_COS:
        LD HL,FP_CONST_EXP_LOG2E
        CALL FADD_FROM_MEM
; [RE] SIN(x) handler (function token $09): sine (MBF; range-reduced then series).
FN_SIN:
        LD A,(L_0CB4)
        CP $77
        RET C
        LD BC,$7E22
        LD DE,$F983
        CALL FMUL
        CALL FAC_PUSH
        CALL FIX_SCALE
        POP BC
        POP DE
        CALL FSUB
        LD BC,$7F00
        LD DE,$0000
        CALL FCOMP
        JP M,FN_SIN_1
        LD BC,$7F80
        LD DE,$0000
        CALL FADD_ALIGN
        LD BC,$8080
        LD DE,$0000
        CALL FADD_ALIGN
        CALL FP_SIGN
        CALL P,FP_NEG
        LD BC,$7F00
        LD DE,$0000
        CALL FADD_ALIGN
        CALL FP_NEG
FN_SIN_1:
        LD A,(FACHI)
        OR A
        PUSH AF
        JP P,FN_SIN_2
        XOR $80
        LD (FACHI),A
FN_SIN_2:
        LD HL,FP_POLY_SIN_COEFFS
        CALL POLY_EVAL_ODD
        POP AF
        RET P
        LD A,(FACHI)
        XOR $80
        LD (FACHI),A
        RET
        DEFB    $00,$00,$00,$00,$83,$F9,$22,$7E
; [RE] MBF constant pair for the transcendental code: log2(e)=1.442695 followed by 0.5. FN_EXP loads it ($5E34) to scale x by log2(e); FN_TAN returns with HL pointing here ($5EFE).
FP_CONST_EXP_LOG2E:
        DEFB    $DB,$0F,$49,$81,$00,$00,$00,$7F
; [RE] SIN/COS coefficient pool (FP_POLY_SIN_COEFFS): MBF polynomial { count byte; N x 4-byte MBF } with count=$05 -> 5 coefficients ($5EB3-$5EC6, 20 bytes). Evaluated as x*P(x^2) by POLY_EVAL_ODD from FN_SIN ($5E91; the call site label FN_RND_2 is a code-overlap artifact, not RND). DUAL USE: reused as a rotating XOR key table by the protected-program scramble (PROG_UNSCRAMBLE $8152, PROG_SCRAMBLE $817B), indexed mod-11 by the C counter -- name KEPT to preserve both identities.
FP_POLY_SIN_COEFFS:
        DEFB    $05,$FB,$D7,$1E,$86,$65,$26,$99,$87,$58,$34,$23,$87,$E1,$5D,$A5
        DEFB    $86,$DB,$0F,$49,$83
; [RE] TAN(x) handler (function token $0D): tangent (SIN/COS).
FN_TAN:
        CALL FAC_PUSH
        CALL FN_SIN
        POP BC
        POP HL
        CALL FAC_PUSH
        EX DE,HL
        CALL FP_STORE_FAC
        CALL FN_COS
        JP FDIV_BY_TEN_1
; [RE] ATN(x) handler (function token $0E): arctangent (MBF).
FN_ATN:
        CALL FP_SIGN
        CALL M,FAC_NEGATE_VIA
        CALL M,FP_NEG
        LD A,(L_0CB4)
        CP $81
        JR C,FN_ATN_1
        LD BC,$8100
        LD D,C
        LD E,C
        CALL FDIV
        LD HL,FADD_FROM_MEM_1
        PUSH HL
FN_ATN_1:
        LD HL,FP_POLY_ATN_COEFFS
        CALL POLY_EVAL_ODD
        LD HL,FP_CONST_EXP_LOG2E
        RET
; [RE] ATN() coefficient pool: MBF polynomial { count byte; N x 4-byte MBF } with count=$09 -> 9 coefficients ($5F03-$5F26, 36 bytes). Evaluated as x*P(x^2) by POLY_EVAL_ODD from FN_ATN ($5EF8/$5EFB) (the odd-power series for arctangent). DUAL USE: the protected-program scrambler reuses these raw bytes as a rotating XOR key (PROG_UNSCRAMBLE $8144, PROG_SCRAMBLE $8189), indexed mod-13 by the B counter -- the byte values, not their FP value, are what matter there.
FP_POLY_ATN_COEFFS:
        DEFB    $09,$4A,$D7,$3B,$78,$02,$6E,$84,$7B,$FE,$C1,$2F,$7C,$74,$31,$9A
        DEFB    $7D,$84,$3D,$5A,$7D,$C8,$7F,$91,$7E,$E4,$BB,$4C,$7E,$6C,$AA,$AA
        DEFB    $7F,$00,$00,$00,$81
L_5F27:
        DEFB    $2B,$CD
        DEFW    CHRGET
        DEFB    $C8,$CD
        DEFW    SYNCHR
        DEFB    ","
; [RE] PTRGET front-end: scan a variable name at the BASIC text pointer (HL). Accumulates the leading alpha + following alphanumerics (high-bit set) into the VARNAM buffer $0871, honouring type-suffix chars %/$/!/# to set VALTYP $0B14 (and the default-type table at $0B36), then falls into the table search at PTRGET_SEARCH ($5FC9). Called by LET ($5F35) and FRMEVL operand fetch. PTRGET_1 ($5F34, OR $AF) is a dual-entry skip idiom: the $F6 (OR n) opcode consumes the next byte ($AF), so falling in from PUSH BC leaves A non-zero; entering at PTRGET_1+1 ($5F35) via CALL runs that $AF byte as XOR A, zeroing A. Both reach LD ($0B13),A at $5F36 with the entry-selected flag. Every CALL $5F35 is written PTRGET_1+1 so it relocates.
PTRGET:
        LD BC,L_5F27
        PUSH BC
; [RE] VERIFIED flag-skip (count corrected to 22 CALL +1 sites, not 23). PTRGET_1 ($5F34) opcode-eating flag select. Fall-through from the PTRGET head -- reached via the DIM statement dispatch DEFW PTRGET at $0112 -- runs OR $AF (F6 swallows the AF), leaving A nonzero so $0B13 gets the 'array/create' context; the 22 CALL PTRGET_1+1 ($5F35) callers run that AF as XOR A, zeroing A and $0B13. Both reach LD ($0B13),A at $5F36. Cover genuinely executed (DIM path); MBASIC twin matches (22 sites).
PTRGET_1:
        OR $AF
        LD (L_0B13),A
        LD C,(HL)
PTRGET_2:
        CALL IS_LETTER
        JP C,RAISE_SYNTAX_ERROR
        XOR A
        LD B,A
        LD (L_0871),A
        INC HL
        LD A,(HL)
        CP $2E
        JR C,PTRGET_7
        JR Z,PTRGET_4
        CP $3A
        JR NC,PTRGET_3
        CP $30
        JR NC,PTRGET_4
PTRGET_3:
        CALL IS_LETTER_A
        JR C,PTRGET_7
PTRGET_4:
        LD B,A
        PUSH BC
        LD B,$FF
        LD DE,L_0871
PTRGET_5:
        OR $80
        INC B
        LD (DE),A
        INC DE
        INC HL
        LD A,(HL)
        CP $3A
        JR NC,PTRGET_6
        CP $30
        JR NC,PTRGET_5
PTRGET_6:
        CALL IS_LETTER_A
        JR NC,PTRGET_5
        CP $2E
        JR Z,PTRGET_5
        LD A,B
        CP $27
        JP NC,RAISE_SYNTAX_ERROR
        POP BC
        LD (L_0871),A
        LD A,(HL)
PTRGET_7:
        CP $26
        JR NC,PTRGET_8
        LD DE,PTRGET_10
        PUSH DE
        LD D,$02
        CP $25
        RET Z
        INC D
        CP $24
        RET Z
        INC D
        CP $21
        RET Z
        LD D,$08
        CP $23
        RET Z
        POP AF
PTRGET_8:
        LD A,C
        AND $7F
        LD E,A
        LD D,$00
        PUSH HL
        LD HL,DEFTYPE_TBL-$41
PTRGET_9:
        ADD HL,DE
        LD D,(HL)
        POP HL
        DEC HL
PTRGET_10:
        LD A,D
        LD (VALTYP),A
        CALL CHRGET
        LD A,(PTRGET_SUBSCRIPT_FLAG)
        DEC A
        JP Z,PTRGET_SEARCH_22+1
        JP P,PTRGET_SEARCH
        LD A,(HL)
        SUB $28
        JP Z,PTRGET_SEARCH_14
        SUB $33
        JP Z,PTRGET_SEARCH_14
; [RE] PTRGET search/allocate core: walk the simple-variable table ($0B6F..$0B71) for the packed name in C/$0B14/$0871; on a hit return its address, on a miss create a new entry (allocate via STR/var-space grow, STR_COPY_DOWN/VARNAM_STORE). Detects '(' to branch to the array path (subscript eval + array search/alloc, $612C loop) honouring DIM and OPTION BASE.
PTRGET_SEARCH:
        XOR A
        LD (PTRGET_SUBSCRIPT_FLAG),A
        PUSH HL
        LD A,(L_0C64)
        OR A
        LD (L_0C61),A
        JR Z,PTRGET_SEARCH_6
        LD HL,(L_0B93)
        LD DE,L_0B95
        ADD HL,DE
        LD (L_0C62),HL
        EX DE,HL
        JR PTRGET_SEARCH_5
; [RE] SIMPLE-VARIABLE table scan (SIMPLEVAR walk). DE walks VARTAB..ARYTAB. Per entry: read SV_VALTYP into L ($5FE4), compare SV_NAME0 to C ($5FE9) and live VALTYP $0B14 to L ($5FEC) and SV_NAME1 to B ($5FF3). On a 2-char hit -> PTRGET_SEARCH_10 (checks SV_NAMEXTLEN/long-name match). On miss, fall through to the computed-stride advance: next = cur + (SV_NAMEXTLEN + SV_VALTYP + 1). Sequential walk -- no base+offset access. See msbasic_var.inc.
PTRGET_SEARCH_1:
        LD A,(DE)
        LD L,A
        INC DE
        LD A,(DE)
        INC DE
        CP C
        JR NZ,PTRGET_SEARCH_2
        LD A,(VALTYP)
        CP L
        JR NZ,PTRGET_SEARCH_2
        LD A,(DE)
        CP B
        JP Z,PTRGET_SEARCH_10
PTRGET_SEARCH_2:
        INC DE
PTRGET_SEARCH_3:
        LD A,(DE)                        ; SV_NAMEXTLEN: A = extra-name-char count for stride
PTRGET_SEARCH_4:
        LD H,$00
        ADD A,L                          ; + SV_VALTYP (L still holds the type/width read at $5FE5); INC A; ADD HL,DE = next entry
        INC A
        LD L,A
        ADD HL,DE
PTRGET_SEARCH_5:
        EX DE,HL
        LD A,(L_0C62)
        CP E
        JP NZ,PTRGET_SEARCH_1
        LD A,(L_0C63)
        CP D
        JR NZ,PTRGET_SEARCH_1
        LD A,(L_0C61)
        OR A
        JR Z,PTRGET_SEARCH_8
        XOR A
        LD (L_0C61),A
PTRGET_SEARCH_6:
        LD HL,(ARYTAB)
        LD (L_0C62),HL
        LD HL,(VARTAB)
        JR PTRGET_SEARCH_5
PTRGET_SEARCH_7:
        LD D,A
        LD E,A
        POP BC
        EX (SP),HL
        RET
PTRGET_SEARCH_8:
        POP HL
        EX (SP),HL
        PUSH DE
        LD DE,FRMEVL_EVAL_OPERAND_4
        CALL CMP_HL_DE
        JR Z,PTRGET_SEARCH_7
        LD DE,STMT_CHAIN_13
        CALL CMP_HL_DE
        JP Z,PTRGET_SEARCH_7
        LD DE,STMT_CHAIN_14
        CALL CMP_HL_DE
        JR Z,PTRGET_SEARCH_7
        LD DE,FRMEVL_PAREN_4
        CALL CMP_HL_DE
        POP DE
        JR Z,PTRGET_SEARCH_12
        EX (SP),HL
        PUSH HL
        PUSH BC
        LD A,(VALTYP)
        LD B,A
        LD A,(L_0871)
        ADD A,B
        INC A
        LD C,A
        PUSH BC
        LD B,$00
        INC BC
        INC BC
        INC BC
        LD HL,(STREND)
        PUSH HL
        ADD HL,BC
        POP BC
        PUSH HL
        CALL STR_COPY_DOWN
        POP HL
        LD (STREND),HL
        LD H,B
        LD L,C
        LD (ARYTAB),HL
PTRGET_SEARCH_9:
        DEC HL
        LD (HL),$00
        CALL CMP_HL_DE
        JR NZ,PTRGET_SEARCH_9
        POP DE
        LD (HL),D
        INC HL
        POP DE
        LD (HL),E
        INC HL
        LD (HL),D
        CALL VARNAM_STORE
        EX DE,HL
        INC DE
        POP HL
        RET
; [RE] SIMPLE-VARIABLE long-name confirm: a 2-char header matched; now compare SV_NAMEXTLEN (offset $03, $608D) to the scanned name's extra-length ($0871). If both 0 -> exact short-name hit, return DE -> value ($6095 INC DE). Else VARNAM_COMPARE the namext bytes; on mismatch resume the stride walk (PTRGET_SEARCH_4).
PTRGET_SEARCH_10:
        INC DE
        LD A,(L_0871)
        LD H,A
        LD A,(DE)
        CP H
        JP NZ,PTRGET_SEARCH_3
        OR A
        JR NZ,PTRGET_SEARCH_11
        INC DE
        POP HL
        RET
PTRGET_SEARCH_11:
        EX DE,HL
        CALL VARNAM_COMPARE
        EX DE,HL
        JP NZ,PTRGET_SEARCH_4
        POP HL
        RET
PTRGET_SEARCH_12:
        LD (L_0CB4),A
        LD H,A
        LD L,A
        LD (FAC),HL
        CALL FRMEVL_TEST_TYPE
        JR NZ,PTRGET_SEARCH_13
        LD HL,L_0CF1
        LD (FAC),HL
PTRGET_SEARCH_13:
        POP HL
        RET
PTRGET_SEARCH_14:
        PUSH HL
        LD HL,(L_0B13)
        EX (SP),HL
        LD D,A
PTRGET_SEARCH_15:
        PUSH DE
        PUSH BC
        LD DE,L_0871
        LD A,(DE)
        OR A
        JR Z,PTRGET_SEARCH_18
        EX DE,HL
        ADD A,$02
        RRA
        LD C,A
        CALL CHECK_STACK_ROOM
        LD A,C
PTRGET_SEARCH_16:
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH BC
        DEC A
        JR NZ,PTRGET_SEARCH_16
        PUSH HL
        LD A,(L_0871)
        PUSH AF
        EX DE,HL
        CALL GETINT_CHRGET_POS
        POP AF
        LD (L_0898),HL
        POP HL
        ADD A,$02
        RRA
PTRGET_SEARCH_17:
        POP BC
        DEC HL
        LD (HL),B
        DEC HL
        LD (HL),C
        DEC A
        JR NZ,PTRGET_SEARCH_17
        LD HL,(L_0898)
        JR PTRGET_SEARCH_19
PTRGET_SEARCH_18:
        CALL GETINT_CHRGET_POS
        XOR A
        LD (L_0871),A
PTRGET_SEARCH_19:
        LD A,(L_0C73)
        OR A
        JR Z,PTRGET_SEARCH_20
        LD A,D
        OR E
        DEC DE
        JP Z,PTRGET_SEARCH_27
PTRGET_SEARCH_20:
        POP BC
        POP AF
        EX DE,HL
        EX (SP),HL
        PUSH HL
        EX DE,HL
        INC A
        LD D,A
        LD A,(HL)
        CP $2C
        JP Z,PTRGET_SEARCH_15
        CP $29
        JR Z,PTRGET_SEARCH_21
        CP $5D
        JP NZ,RAISE_SYNTAX_ERROR
PTRGET_SEARCH_21:
        CALL CHRGET
        LD (FRMEVL_TXTPTR_TEMP),HL
        POP HL
        LD (L_0B13),HL
        LD E,$00
        PUSH DE
; [RE] VERIFIED flag-skip. PTRGET_SEARCH_23 ($612C) opcode-eating entry. Fall-through (from PTRGET_SEARCH_22 PUSH DE at $612B) executes LD DE,$F5E5; the $11 opcode swallows E5 F5 so the first pass skips PUSH HL/PUSH AF and loads a dead DE. The two +1 entrants ($612D, JP Z at $5FB8 / CALL at $7389) run E5 F5 as PUSH HL / PUSH AF to save caller state. Both reach LD HL,($0B71) at $612F. Cover genuinely executed; MBASIC twin (SUB_3D4E_6, still machine-labeled) byte-identical.
PTRGET_SEARCH_22:
        LD DE,$F5E5
        LD HL,(ARYTAB)
; [RE] VERIFIED flag-skip. PTRGET_SEARCH_24 ($6132) opcode-eating loop advance. Fall-through (from $612F) runs LD A,$19 (3E swallows 19); the first array-table pass skips ADD HL,DE because HL is already at the table head. The loop re-enters via JR NZ,PTRGET_SEARCH_24+1 ($6133) at $6159, running 19 as ADD HL,DE to step to the next ARRAYVAR by the stored AV_BLKLEN stride (DE loaded at $6155-$6158). A=$19 is dead (clobbered at $6140). Both reach EX DE,HL / CMP_HL_DE at $6134. Cover genuinely executed; MBASIC twin (SUB_3D4E_7) byte-identical (20 D8). ARRAY-TABLE scan: compares AV_NAME0/$0B14/AV_NAME1 to C/$0B14/B ($6142/$6148/$614C); see msbasic_var.inc.
PTRGET_SEARCH_23:
        LD A,$19
        EX DE,HL
        LD HL,(STREND)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,PTRGET_SEARCH_29
        LD E,(HL)
        INC HL
        LD A,(HL)
        INC HL
        CP C
        JR NZ,PTRGET_SEARCH_24
        LD A,(VALTYP)
        CP E
        JR NZ,PTRGET_SEARCH_24
        LD A,(HL)
        CP B
        JR Z,PTRGET_SEARCH_28
PTRGET_SEARCH_24:
        INC HL
; [RE] ARRAYVAR advance to next descriptor: at the AV_NAMEXTLEN byte ($6150 LD E,(HL); INC E) skip the variable name extension, then PTRGET_SEARCH_26 ($6155) loads AV_BLKLEN (the stored inter-entry stride word) into DE; the loop top adds it (flag-skip ADD HL,DE at $6132/$6159) to reach the next ARRAYVAR. Stored-stride sequential walk -- no base+offset.
PTRGET_SEARCH_25:
        LD E,(HL)
        INC E
        LD D,$00
        ADD HL,DE
PTRGET_SEARCH_26:
        LD E,(HL)                        ; AV_BLKLEN word -> DE = stride to next array descriptor
        INC HL
        LD D,(HL)
        INC HL
        JR NZ,PTRGET_SEARCH_23+1
        LD A,(L_0B13)
        OR A
        JP NZ,RAISE_DUPLICATE_DEFINITION
        POP AF
        LD B,H
        LD C,L
        JP Z,FMUL_7
        SUB (HL)
        JP Z,PTRGET_SEARCH_34
PTRGET_SEARCH_27:
        LD DE,ERR_SUBSCRIPT_OUT_OF_RANGE
        JP RAISE_ERROR
PTRGET_SEARCH_28:
        INC HL
        LD A,(L_0871)
        CP (HL)
        JR NZ,PTRGET_SEARCH_25
        INC HL
        OR A
        JR Z,PTRGET_SEARCH_26
        DEC HL
        CALL VARNAM_COMPARE
        JR PTRGET_SEARCH_26
PTRGET_SEARCH_29:
        LD A,(VALTYP)
        LD (HL),A
        INC HL
        LD E,A
        LD D,$00
        POP AF
        JP Z,PTRGET_SEARCH_39
        LD (HL),C
        INC HL
        LD (HL),B
        CALL VARNAM_STORE
        INC HL
        LD C,A
        CALL CHECK_STACK_ROOM
        INC HL
        INC HL
        LD (L_0B4A),HL
        LD (HL),C
        INC HL
        LD A,(L_0B13)
        RLA
        LD A,C
PTRGET_SEARCH_30:
        JR C,PTRGET_SEARCH_31
        PUSH AF
        LD A,(L_0C73)
        XOR $0B
        LD C,A
        LD B,$00
        POP AF
        JR NC,PTRGET_SEARCH_32
PTRGET_SEARCH_31:
        POP BC
        INC BC
PTRGET_SEARCH_32:
        LD (HL),C
        PUSH AF
        INC HL
        LD (HL),B
        INC HL
        CALL ARRAY_INDEX_MUL16
        POP AF
        DEC A
        JR NZ,PTRGET_SEARCH_30
        PUSH AF
        LD B,D
        LD C,E
        EX DE,HL
        ADD HL,DE
        JP C,CHECK_STACK_ROOM_1
        CALL GC_CHECK_AND_COLLECT
        LD (STREND),HL
PTRGET_SEARCH_33:
        DEC HL
        LD (HL),$00
        CALL CMP_HL_DE
        JR NZ,PTRGET_SEARCH_33
        INC BC
        LD D,A
        LD HL,(L_0B4A)
        LD E,(HL)
        EX DE,HL
        ADD HL,HL
        ADD HL,BC
        EX DE,HL
        DEC HL
        DEC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        POP AF
        JR C,PTRGET_SEARCH_38
PTRGET_SEARCH_34:
        LD B,A
        LD C,A
        LD A,(HL)
        INC HL
; [RE] VERIFIED flag-skip. PTRGET_SEARCH_36 ($61EF) opcode-eating dimension loop. Fall-through (from PTRGET_SEARCH_35) runs LD D,$E1 (16 swallows E1); the first array dimension skips POP HL because HL is already valid. The loop re-enters via JR NZ,PTRGET_SEARCH_36+1 ($61F0) at $6205, running E1 as POP HL to restore the per-dimension HL save (EX (SP),HL/PUSH AF at $61F5/$61F6). D=$E1 is dead (clobbered at $61F3). Both reach LD E,(HL) at $61F1. Cover genuinely executed; MBASIC twin (SUB_3D4E_21) byte-identical (20 E9).
PTRGET_SEARCH_35:
        LD D,$E1
        LD E,(HL)                        ; AV_DIMSIZE[i] word (high dim first) -> DE for the index/offset accumulate
        INC HL
        LD D,(HL)
        INC HL
        EX (SP),HL
        PUSH AF
        CALL CMP_HL_DE
        JP NC,PTRGET_SEARCH_27
        CALL ARRAY_INDEX_MUL16
        ADD HL,DE
        POP AF
        DEC A
        LD B,H
        LD C,L
        JR NZ,PTRGET_SEARCH_35+1
        LD A,(VALTYP)
        LD B,H
        LD C,L
        ADD HL,HL
        SUB $04
        JR C,PTRGET_SEARCH_36
        ADD HL,HL
        JR Z,PTRGET_SEARCH_37
        ADD HL,HL
PTRGET_SEARCH_36:
        OR A
        JP PO,PTRGET_SEARCH_37
        ADD HL,BC
PTRGET_SEARCH_37:
        POP BC
        ADD HL,BC
        EX DE,HL
PTRGET_SEARCH_38:
        LD HL,(FRMEVL_TXTPTR_TEMP)
        RET
PTRGET_SEARCH_39:
        SCF
        SBC A,A
        POP HL
        RET
; [RE] Advance HL past one variable/array-table entry: load length byte at (HL), then add it to HL (falls into VARTAB_ADD_LEN). Used while scanning the array table during PTRGET and by the array-walk in DIM/index code ($6CBF, $740E...).
VARTAB_SKIP_ENTRY:
        LD A,(HL)
        INC HL
; [RE] HL += A (zero-extended) preserving BC: B:=0, C:=A, ADD HL,BC. Entry point used to step over a table entry whose length is already in A.
VARTAB_ADD_LEN:
        PUSH BC
        LD B,$00
        LD C,A
        ADD HL,BC
        POP BC
        RET
; [RE] Copy the scanned variable name from the VARNAM buffer $0871 (length-prefixed) into the new variable-table entry at (HL), advancing HL. Used by PTRGET_SEARCH when creating a fresh entry.
VARNAM_STORE:
        PUSH BC
        PUSH DE
        PUSH AF
        LD DE,L_0871
        LD A,(DE)
        LD B,A
        INC B
VARNAM_STORE_1:
        LD A,(DE)
        INC DE
        INC HL
        LD (HL),A
        DEC B
        JR NZ,VARNAM_STORE_1
        POP AF
        POP DE
        POP BC
        RET
; [RE] Compare the variable name held at (HL) in a table entry against the scanned name in buffer $0872, length A. Returns Z on full match; on mismatch advances HL past the rest of the name (via VARTAB_ADD_LEN) and returns NZ. Drives the linear scan in PTRGET_SEARCH.
VARNAM_COMPARE:
        PUSH DE
        PUSH BC
        LD DE,L_0872
        LD B,A
        INC HL
        INC B
VARNAM_COMPARE_1:
        DEC B
        JR Z,VARNAM_COMPARE_2
        LD A,(DE)
        CP (HL)
        INC HL
        INC DE
        JR Z,VARNAM_COMPARE_1
        LD A,B
        DEC A
        CALL NZ,VARTAB_ADD_LEN
        XOR A
        DEC A
VARNAM_COMPARE_2:
        POP BC
        POP DE
        RET
; [RE] EDIT-statement line-number resolver: store the LIST/edit flag at $0835, fetch the current/target line pointer from $0B60, and fall into the EDIT statement handler (STMT_EDIT) to enter the line editor.
STMT_EDIT_LINENUM:
        LD (ERRFLG),A
        LD HL,(ERR_SAVTXT)
        OR H
        AND L
        INC A
        EX DE,HL
        RET Z
        JR STMT_EDIT_1
; [RE] EDIT statement handler (token $A3): enter the line editor for a program line.
STMT_EDIT:
        CALL LINGET_DOT
        RET NZ
STMT_EDIT_1:
        POP HL
STMT_EDIT_2:
        EX DE,HL
        LD (ERRLIN),HL
        EX DE,HL
        CALL FNDLIN
        JP NC,ERROR_UL
        LD H,B
        LD L,C
        INC HL
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        PUSH BC
        CALL DETOKENIZE_LINE
STMT_EDIT_3:
        POP HL
STMT_EDIT_4:
        PUSH HL
        LD A,H
        AND L
        INC A
        LD A,$21
        CALL Z,OUTCHR
        CALL NZ,FOUT
        LD A,$20
        CALL OUTCHR
        LD HL,BUF
        PUSH HL
        LD C,$FF
STMT_EDIT_5:
        INC C
        LD A,(HL)
        INC HL
        OR A
        JR NZ,STMT_EDIT_5
        POP HL
        LD B,A
STMT_EDIT_6:
        LD D,$00
STMT_EDIT_7:
        CALL CONIN
        OR A
        JR Z,STMT_EDIT_7
        CALL TOUPPER_A
        SUB $30
        JR C,STMT_EDIT_8
        CP $0A
        JR NC,STMT_EDIT_8
        LD E,A
        LD A,D
        RLCA
        RLCA
        ADD A,D
        RLCA
        ADD A,E
        LD D,A
        JR STMT_EDIT_7
STMT_EDIT_8:
        PUSH HL
        LD HL,STMT_EDIT_6
        EX (SP),HL
        DEC D
        INC D
        JP NZ,STMT_EDIT_9
        INC D
STMT_EDIT_9:
        CP $D8
        JP Z,EDIT_BUF_SHIFT_7
        CP $4F
        JP Z,EDIT_BUF_SHIFT_8
        CP $DD
        JP Z,EDIT_BUF_SHIFT_9
        CP $F0
        JR Z,EDIT_ECHO_SPAN
        CP $31
        JR C,STMT_EDIT_10
        SUB $20
STMT_EDIT_10:
        CP $21
        JP Z,PRINT_LIST_ENTRY_1
        CP $1C
        JP Z,EDIT_ECHO_SPAN_6
        CP $23
        JR Z,EDIT_ECHO_SPAN_2
        CP $19
        JP Z,EDIT_EMIT_BACKSLASH_6
        CP $14
        JP Z,EDIT_ECHO_SPAN_7
        CP $13
        JP Z,EDIT_EMIT_BACKSLASH_1
        CP $15
        JP Z,EDIT_BUF_SHIFT_10
        CP $28
        JP Z,EDIT_EMIT_BACKSLASH_5
        CP $1B
        JR Z,EDIT_ECHO_SPAN_1
        CP $18
        JP Z,EDIT_EMIT_BACKSLASH_4
        CP $11
        LD A,$07
        JP NZ,OUTCHR
        POP BC
        POP DE
        CALL CRLF
        JP STMT_EDIT_2
; [RE] Line-editor helper: echo D characters of the line buffer at (HL) to the console (OUTCHR via OUTCHR_LF_EXPAND), advancing HL and the column count B; ESC ($1B) enters the copy/scan sub-mode (EDIT_COPY_MODE). Part of the EDIT/line-input screen editor.
EDIT_ECHO_SPAN:
        LD A,(HL)
        OR A
        RET Z
        INC B
        CALL OUTCHR_LF_EXPAND
        INC HL
        DEC D
        JR NZ,EDIT_ECHO_SPAN
        RET
EDIT_ECHO_SPAN_1:
        PUSH HL
        LD HL,EDIT_EMIT_BACKSLASH
        EX (SP),HL
        SCF
EDIT_ECHO_SPAN_2:
        PUSH AF
        CALL CONIN
        LD E,A
        POP AF
        PUSH AF
        CALL C,EDIT_EMIT_BACKSLASH
EDIT_ECHO_SPAN_3:
        LD A,(HL)
        OR A
        JP Z,EDIT_ECHO_SPAN_5
        CALL OUTCHR_LF_EXPAND
        POP AF
        PUSH AF
        CALL C,EDIT_BUF_SHIFT
        JR C,EDIT_ECHO_SPAN_4
        INC HL
        INC B
EDIT_ECHO_SPAN_4:
        LD A,(HL)
        CP E
        JR NZ,EDIT_ECHO_SPAN_3
        DEC D
        JR NZ,EDIT_ECHO_SPAN_3
EDIT_ECHO_SPAN_5:
        POP AF
        RET
EDIT_ECHO_SPAN_6:
        CALL PRINT_ZSTRING
        CALL CRLF
        POP BC
        JP STMT_EDIT_3
EDIT_ECHO_SPAN_7:
        LD A,(HL)
        OR A
        RET Z
        LD A,$5C
        CALL OUTCHR_LF_EXPAND
EDIT_ECHO_SPAN_8:
        LD A,(HL)
        OR A
        JR Z,EDIT_EMIT_BACKSLASH
        CALL OUTCHR_LF_EXPAND
        CALL EDIT_BUF_SHIFT
        DEC D
        JR NZ,EDIT_ECHO_SPAN_8
; [RE] Line-editor helper: emit a '\' ($5C) line-terminator marker through OUTCHR; entry EDIT_EMIT_BACKSLASH_1/_2 read replacement characters from the console (CONIN), filtering control chars, and overwrite the buffer (insert/overtype) for the EDIT screen editor.
EDIT_EMIT_BACKSLASH:
        LD A,$5C
        CALL OUTCHR
        RET
EDIT_EMIT_BACKSLASH_1:
        LD A,(HL)
        OR A
        RET Z
EDIT_EMIT_BACKSLASH_2:
        CALL CONIN
        CP $20
        JR NC,EDIT_EMIT_BACKSLASH_3
        CP $0A
        JR Z,EDIT_EMIT_BACKSLASH_3
        CP $07
        JR Z,EDIT_EMIT_BACKSLASH_3
        CP $09
        JR Z,EDIT_EMIT_BACKSLASH_3
        LD A,$07
        CALL OUTCHR
        JR EDIT_EMIT_BACKSLASH_2
EDIT_EMIT_BACKSLASH_3:
        LD (HL),A
        CALL OUTCHR_LF_EXPAND
        INC HL
        INC B
        DEC D
        JR NZ,EDIT_EMIT_BACKSLASH_1
        RET
EDIT_EMIT_BACKSLASH_4:
        LD (HL),$00
        LD C,B
EDIT_EMIT_BACKSLASH_5:
        LD D,$FF
        CALL EDIT_ECHO_SPAN
EDIT_EMIT_BACKSLASH_6:
        CALL CONIN
        CP $7F
        JR Z,EDIT_EMIT_BACKSLASH_7
        CP $08
        JR Z,EDIT_EMIT_BACKSLASH_8
        CP $0D
        JP Z,EDIT_BUF_SHIFT_9
        CP $1B
        RET Z
        CP $08
        JR Z,EDIT_EMIT_BACKSLASH_8
        CP $0A
        JR Z,EDIT_BUF_SHIFT_2
        CP $07
        JR Z,EDIT_BUF_SHIFT_2
        CP $09
        JR Z,EDIT_BUF_SHIFT_2
        CP $20
        JR C,EDIT_EMIT_BACKSLASH_6
        CP $5F
        JR NZ,EDIT_BUF_SHIFT_2
EDIT_EMIT_BACKSLASH_7:
        LD A,$5F
EDIT_EMIT_BACKSLASH_8:
        DEC B
        INC B
        JR Z,EDIT_BUF_SHIFT_3
        CALL OUTCHR_LF_EXPAND
        DEC HL
        DEC B
        LD DE,EDIT_EMIT_BACKSLASH_6
        PUSH DE
; [RE] Line-editor buffer-shift helper: pull characters down within the edit buffer at (HL) until the NUL terminator (used for delete/backspace in the EDIT screen editor). The continuation labels EDIT_BUF_SHIFT_9.. share code into the PRINT USING formatter below.
EDIT_BUF_SHIFT:
        PUSH HL
        DEC C
EDIT_BUF_SHIFT_1:
        LD A,(HL)
        OR A
        SCF
        JP Z,FMUL_7
        INC HL
        LD A,(HL)
        DEC HL
        LD (HL),A
        INC HL
        JR EDIT_BUF_SHIFT_1
EDIT_BUF_SHIFT_2:
        PUSH AF
        LD A,C
        CP $FF
        JR C,EDIT_BUF_SHIFT_6
        POP AF
EDIT_BUF_SHIFT_3:
        LD A,$07
EDIT_BUF_SHIFT_4:
        CALL OUTCHR
EDIT_BUF_SHIFT_5:
        JR EDIT_EMIT_BACKSLASH_6
EDIT_BUF_SHIFT_6:
        SUB B
        INC C
        INC B
        PUSH BC
        EX DE,HL
        LD L,A
        LD H,$00
        ADD HL,DE
        LD B,H
        LD C,L
        INC HL
        CALL STR_COPY_DOWN_NOCHK
        POP BC
        POP AF
        LD (HL),A
        CALL OUTCHR_LF_EXPAND
        INC HL
        JP EDIT_BUF_SHIFT_5
EDIT_BUF_SHIFT_7:
        LD A,B
        OR A
        RET Z
        CALL INLIN_BACKSPACE
        DEC B
        DEC D
        JR NZ,EDIT_BUF_SHIFT_8
        RET
EDIT_BUF_SHIFT_8:
        LD A,B
        OR A
        RET Z
        DEC B
        DEC HL
        LD A,(HL)
        CALL OUTCHR_LF_EXPAND
        DEC D
        JR NZ,EDIT_BUF_SHIFT_8
        RET
EDIT_BUF_SHIFT_9:
        CALL PRINT_ZSTRING
EDIT_BUF_SHIFT_10:
        CALL CRLF
        POP BC
        POP DE
        LD A,D
        AND E
        INC A
; [RE] PRINT / '?' entry (direct + statement dispatcher at $0E8A): with no argument print CRLF (HL=$0A0D=CR,LF), else run the PRINT-item / PRINT USING engine over the value list.
PRINT_LIST_ENTRY:
        LD HL,L_0A0D
        RET Z
        SCF
        PUSH AF
        INC HL
        JP DIRECT_EXEC_STMT
PRINT_LIST_ENTRY_1:
        POP BC
        POP DE
        LD A,D
        AND E
        INC A
        JP Z,PRINT_CRLF_IF_COL_1
        JP NEWSTT_READY
; [RE] PRINT USING statement engine (reached from the PRINT dispatcher on token $E8 'USING'): evaluate the format string, then scan its field characters - '#' digit positions, '.' decimal point, ',' grouping, '+'/'-' sign, '$$' float-dollar, '**' asterisk-fill, '^^^^' exponential, '\ \' string field, '!' first-char, '&' variable string - formatting each argument (FOUT/FOUT_BODY for numbers, STROUT for strings) and looping over the value list.
PRINT_USING:
        CALL FRMEVL_LOWPREC
        CALL FP_INT_CHECK
        CALL SYNCHR
        DEFB    ';'                      ; inline char arg consumed by the preceding CALL
        EX DE,HL
        LD HL,(FAC)
        JR PRINT_LIST_ENTRY_4
PRINT_LIST_ENTRY_3:
        LD A,(L_0B53)
        OR A
        JR Z,PRINT_LIST_ENTRY_5
        POP DE
        EX DE,HL
PRINT_LIST_ENTRY_4:
        PUSH HL
        XOR A
        LD (L_0B53),A
        CP D
        PUSH AF
        PUSH DE
        LD B,(HL)
        OR B
PRINT_LIST_ENTRY_5:
        JP Z,ERROR_FC
        INC HL
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        JR PRINT_LIST_ENTRY_10
PRINT_LIST_ENTRY_6:
        LD E,B
        PUSH HL
        LD C,$02
PRINT_LIST_ENTRY_7:
        LD A,(HL)
        INC HL
        CP $5C
        JP Z,PRINT_LIST_ENTRY_33+1
        CP $20
        JR NZ,PRINT_LIST_ENTRY_8
        INC C
        DJNZ PRINT_LIST_ENTRY_7
PRINT_LIST_ENTRY_8:
        POP HL
        LD B,E
        LD A,$5C
PRINT_LIST_ENTRY_9:
        CALL PRINT_USING_PUT_SIGN
        CALL OUTCHR
PRINT_LIST_ENTRY_10:
        XOR A
        LD E,A
        LD D,A
PRINT_LIST_ENTRY_11:
        CALL PRINT_USING_PUT_SIGN
        LD D,A
        LD A,(HL)
        INC HL
        CP $21
        JP Z,PRINT_LIST_ENTRY_32
        CP $23
        JR Z,PRINT_LIST_ENTRY_15
        CP $26
        JP Z,PRINT_LIST_ENTRY_31
        DEC B
        JP Z,PRINT_LIST_ENTRY_27
        CP $2B
        LD A,$08
        JR Z,PRINT_LIST_ENTRY_11
        DEC HL
        LD A,(HL)
        INC HL
        CP $2E
        JR Z,PRINT_LIST_ENTRY_16
        CP $5F
        JP Z,PRINT_LIST_ENTRY_30
        CP $5C
        JR Z,PRINT_LIST_ENTRY_6
        CP (HL)
        JR NZ,PRINT_LIST_ENTRY_9
        CP $24
        JR Z,PRINT_LIST_ENTRY_13+1
        CP $2A
        JR NZ,PRINT_LIST_ENTRY_9
        LD A,B
        INC HL
        CP $02
        JR C,PRINT_LIST_ENTRY_12
        LD A,(HL)
        CP $24
PRINT_LIST_ENTRY_12:
        LD A,$20
        JR NZ,PRINT_LIST_ENTRY_14
        DEC B
        INC E
; [RE] VERIFIED flag-skip. PRINT_LIST_ENTRY_13 ($64EB) opcode-eating field seed. Fall-through (numeric-digit path via $64E9 DEC B / $64EA INC E) runs CP $AF (FE swallows AF), a flags-only compare leaving the digit char in A before ADD A,$10. The floating-currency '$$' entry JR Z,PRINT_LIST_ENTRY_13+1 ($64EC) at $64D6 runs AF as XOR A, so ADD A,$10 starts from $10. Both reach ADD A,$10 / INC HL at $64ED. Cover genuinely executed; MBASIC twin (PRINT_USING_11) byte-identical (28 14).
PRINT_LIST_ENTRY_13:
        CP $AF
        ADD A,$10
        INC HL
PRINT_LIST_ENTRY_14:
        INC E
        ADD A,D
        LD D,A
PRINT_LIST_ENTRY_15:
        INC E
        LD C,$00
        DEC B
        JR Z,PRINT_LIST_ENTRY_20
        LD A,(HL)
        INC HL
        CP $2E
        JR Z,PRINT_LIST_ENTRY_17
        CP $23
        JR Z,PRINT_LIST_ENTRY_15
        CP $2C
        JR NZ,PRINT_LIST_ENTRY_18
        LD A,D
        OR $40
        LD D,A
        JR PRINT_LIST_ENTRY_15
PRINT_LIST_ENTRY_16:
        LD A,(HL)
        CP $23
        LD A,$2E
        JP NZ,PRINT_LIST_ENTRY_9
        LD C,$01
        INC HL
PRINT_LIST_ENTRY_17:
        INC C
        DEC B
        JR Z,PRINT_LIST_ENTRY_20
        LD A,(HL)
        INC HL
        CP $23
        JR Z,PRINT_LIST_ENTRY_17
PRINT_LIST_ENTRY_18:
        PUSH DE
        LD DE,PRINT_LIST_ENTRY_19+1
        PUSH DE
        LD D,H
        LD E,L
        CP $5E
        RET NZ
        CP (HL)
        RET NZ
        INC HL
        CP (HL)
        RET NZ
        INC HL
        CP (HL)
        RET NZ
        INC HL
        LD A,B
        SUB $04
        RET C
        POP DE
        POP DE
        LD B,A
        INC D
        INC HL
; [RE] VERIFIED flag-skip (with nuance). PRINT_LIST_ENTRY_19+1 ($653F) is a RET landing pad, not a JP target. The '^^^^' field parser pushes $653F ($6523/$6526) and saves HL into DE ($6527); the RET NZ/RET C chain returns to $653F to run EX DE,HL / POP DE and unwind. The cover at $653E (CA EB D1) is a genuine, executed JP Z,$D1EB whose Z comes from INC D ($653C) and whose $D1EB target is unreachable BIOS-region junk, so it is effectively never taken -- the CA opcode hides the EB D1 (EX DE,HL/POP DE) on the fall-through. Both reach PRINT_LIST_ENTRY_20 ($6541). MBASIC twin (PRINT_USING_17) byte-identical.
PRINT_LIST_ENTRY_19:
        JP Z,$D1EB
PRINT_LIST_ENTRY_20:
        LD A,D
        DEC HL
        INC E
        AND $08
        JR NZ,PRINT_LIST_ENTRY_22
        DEC E
        LD A,B
        OR A
        JR Z,PRINT_LIST_ENTRY_22
        LD A,(HL)
        SUB $2D
        JR Z,PRINT_LIST_ENTRY_21
        CP $FE
        JR NZ,PRINT_LIST_ENTRY_22
        LD A,$08
PRINT_LIST_ENTRY_21:
        ADD A,$04
        ADD A,D
        LD D,A
        DEC B
PRINT_LIST_ENTRY_22:
        POP HL
        POP AF
        JR Z,PRINT_LIST_ENTRY_29
        PUSH BC
        PUSH DE
        CALL FRMEVL_NOPAREN
        POP DE
        POP BC
        PUSH BC
        PUSH HL
        LD B,E
        LD A,B
        ADD A,C
        CP $19
        JP NC,ERROR_FC
        LD A,D
        OR $80
        CALL FOUT_BODY
        CALL STROUT
PRINT_LIST_ENTRY_23:
        POP HL
        DEC HL
        CALL CHRGET
        SCF
        JR Z,PRINT_LIST_ENTRY_25
        LD (L_0B53),A
        CP $3B
        JR Z,PRINT_LIST_ENTRY_24
        CP $2C
        JP NZ,RAISE_SYNTAX_ERROR
PRINT_LIST_ENTRY_24:
        CALL CHRGET
PRINT_LIST_ENTRY_25:
        POP BC
        EX DE,HL
        POP HL
        PUSH HL
        PUSH AF
        PUSH DE
        LD A,(HL)
        SUB B
        INC HL
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        LD D,$00
        LD E,A
        ADD HL,DE
PRINT_LIST_ENTRY_26:
        LD A,B
        OR A
        JP NZ,PRINT_LIST_ENTRY_10
        JR PRINT_LIST_ENTRY_28
PRINT_LIST_ENTRY_27:
        CALL PRINT_USING_PUT_SIGN
        CALL OUTCHR
PRINT_LIST_ENTRY_28:
        POP HL
        POP AF
        JP NZ,PRINT_LIST_ENTRY_3
PRINT_LIST_ENTRY_29:
        CALL C,CRLF
        EX (SP),HL
        CALL FRESTR_DE
        POP HL
        JP PRINT_RESET_STATE
PRINT_LIST_ENTRY_30:
        CALL PRINT_USING_PUT_SIGN
        DEC B
        LD A,(HL)
        INC HL
        CALL OUTCHR
        JR PRINT_LIST_ENTRY_26
PRINT_LIST_ENTRY_31:
        LD C,$FF
        JR PRINT_LIST_ENTRY_34
PRINT_LIST_ENTRY_32:
        LD C,$01
; [RE] VERIFIED flag-skip. PRINT_LIST_ENTRY_34 ($65D1) opcode-eating stack rebalance. Fall-through (numeric/sign field, from PRINT_LIST_ENTRY_33 $65CF) runs LD A,$F1 (3E swallows F1) so no POP; A=$F1 is dead. The '\' string-field entry JP Z,PRINT_LIST_ENTRY_34+1 ($65D2) at $648C runs F1 as POP AF to drop the PUSH the scanner left. (PRINT_LIST_ENTRY_32 at $65CB JRs straight to _35 at $65D3, bypassing the cover.) Both reach DEC B / CALL PRINT_USING_PUT_SIGN at $65D3. Cover genuinely executed on fall-through; MBASIC twin (PRINT_USING_31) byte-identical.
PRINT_LIST_ENTRY_33:
        LD A,$F1
PRINT_LIST_ENTRY_34:
        DEC B
        CALL PRINT_USING_PUT_SIGN
        POP HL
        POP AF
        JR Z,PRINT_LIST_ENTRY_29
        PUSH BC
        CALL FRMEVL_NOPAREN
        CALL FP_INT_CHECK
        POP BC
        PUSH BC
        PUSH HL
        LD HL,(FAC)
        LD B,C
        LD C,$00
        PUSH BC
        CALL STR_SUBSTR_ALLOC_COPY_2+1
        CALL STRPRT
        LD HL,(FAC)
        POP AF
        INC A
        JP Z,PRINT_LIST_ENTRY_23
        DEC A
        SUB (HL)
        LD B,A
        LD A,$20
        INC B
PRINT_LIST_ENTRY_35:
        DEC B
        JP Z,PRINT_LIST_ENTRY_23
        CALL OUTCHR
        JR PRINT_LIST_ENTRY_35
; [RE] PRINT USING helper: if the pending-sign flag in D is set, emit a leading '+' ($2B) via OUTCHR before the formatted field; preserves AF.
PRINT_USING_PUT_SIGN:
        PUSH AF
        LD A,D
        OR A
        LD A,$2B
        CALL NZ,OUTCHR
        POP AF
        RET
; [RE] OUTCHR: console character output with column tracking ($0837 cursor column), TAB ($09) expansion to 8-col stops, backspace ($08) and CR handling, then emits the byte through the BIOS console-out vector (OUTDO_DEVICE, CALL into the runtime-patched $0000 cell).
OUTCHR:
        PUSH AF
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JP NZ,PUTC_FILE_RESUME
        POP HL
        LD A,(PRTFLG)
        OR A
        JP Z,OUTDO_WIDTH_1
        POP AF
        PUSH AF
        CP $08
        JR NZ,OUTCHR_1
        LD A,(OUTPUT_COLUMN)
        DEC A
        LD (OUTPUT_COLUMN),A
        POP AF
        JR OUTDO_DEVICE
OUTCHR_1:
        CP $09
        JR NZ,OUTCHR_3
OUTCHR_2:
        LD A,$20
        CALL OUTCHR
        LD A,(OUTPUT_COLUMN)
        AND $07
        JR NZ,OUTCHR_2
        POP AF
        RET
OUTCHR_3:
        POP AF
        PUSH AF
        SUB $0D
        JR Z,OUTCHR_5
        JR C,OUTCHR_6
        LD A,(L_083A)
        INC A
        LD A,(OUTPUT_COLUMN)
        JR Z,OUTCHR_4
        PUSH HL
        LD HL,L_083A
        CP (HL)
        POP HL
        CALL Z,OUTDO_WIDTH
        JR Z,OUTCHR_6
OUTCHR_4:
        CP $FF
        JR Z,OUTCHR_6
        INC A
OUTCHR_5:
        LD (OUTPUT_COLUMN),A
OUTCHR_6:
        POP AF
; [RE] Low-level BIOS console-out vector wrapper: char in A, saves BC/DE/HL, copies to C, CALLs the runtime-patched $0000 cell (CP/M BIOS CONOUT, installed by cold start at OUTDO_DEVICE_1+1 / $8217). The device-output primitive that OUTCHR ($6613) and OUTDO_WIDTH ($6682) route through.
OUTDO_DEVICE:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD C,A
; [RE] VERIFIED smc. OUTDO_DEVICE_1+1 ($6672) is the SMC operand of CALL $0000 ($6671), reached by fall-through from OUTDO_DEVICE ($666C). COLD_START LD (OUTDO_DEVICE_1+1),HL at $8217 patches it to the live CP/M BIOS CONOUT entry (walked from $0001 through the BIOS jump table). The CD 00 00 is a placeholder; +1 is the patch slot, written never jumped-to, and the patched CALL executes on every console output. MBASIC twin patches at $5E95.
OUTDO_DEVICE_1:
        CALL $0000
        POP HL
        POP DE
        POP BC
        POP AF
        RET
; [RE] Clears the output-suppress flag ($0838) and, if the print column ($0837) is nonzero, falls through to OUTDO_WIDTH to emit CRLF and reset the column. The 'return to start of line' helper before fresh output.
OUTDO_RESET_COL:
        XOR A
        LD (PRTFLG),A
        LD A,(OUTPUT_COLUMN)
        OR A
        RET Z
; [RE] High-level char-out with line-width/auto-CR logic: enforces the terminal width, expands TAB, handles backspace against the column counter ($0B11), and issues CRLF when the print column reaches the width. Wraps the OUTCHR primitive (OUTDO_DEVICE2).
OUTDO_WIDTH:
        LD A,$0D
        CALL OUTDO_DEVICE
        LD A,$0A
        CALL OUTDO_DEVICE
        XOR A
        LD (OUTPUT_COLUMN),A
        RET
OUTDO_WIDTH_1:
        LD A,(CTRL_O_SUPPRESS)
        OR A
        JP NZ,GETSPA_2
        POP AF
        PUSH BC
        PUSH AF
        CP $0A
        JR NZ,OUTDO_WIDTH_2
        CALL LINE_COUNT_INC
        LD A,$0A
OUTDO_WIDTH_2:
        CP $08
        JR NZ,OUTDO_WIDTH_4
        LD A,(L_0B11)
        OR A
        JR NZ,OUTDO_WIDTH_3
        LD A,(L_0B12)
        OR A
        JR Z,OUTDO_WIDTH_6
        DEC A
        LD (L_0B12),A
        LD A,(PRINT_WIDTH)
OUTDO_WIDTH_3:
        DEC A
        LD (L_0B11),A
        LD A,$08
        JR OUTDO_WIDTH_8
OUTDO_WIDTH_4:
        CP $09
        JR NZ,OUTDO_WIDTH_7
OUTDO_WIDTH_5:
        LD A,$20
        CALL OUTCHR
        LD A,(L_0B11)
        AND $07
        JR NZ,OUTDO_WIDTH_5
OUTDO_WIDTH_6:
        POP AF
        POP BC
        RET
OUTDO_WIDTH_7:
        CP $20
        JR C,OUTDO_WIDTH_8
OUTDO_WIDTH_8:
        POP AF
        PUSH AF
        CALL OUTDO_DEVICE2
        CP $20
        JR C,OUTDO_WIDTH_9
        LD A,(PRINT_WIDTH)
        INC A
        JR Z,OUTDO_WIDTH_9
        DEC A
        LD B,A
        LD A,(L_0B11)
        INC A
        JR Z,OUTDO_WIDTH_9
        LD (L_0B11),A
        CP B
        JR NZ,OUTDO_WIDTH_9
        LD A,(GFX_STMT_HPLOT_9)
        CP B
        CALL Z,LIST_NEWLINE_COUNT
        CALL NZ,CRLF
OUTDO_WIDTH_9:
        POP AF
        POP BC
        RET
; [RE] Second BIOS console-out vector wrapper (raw byte emit): char in A->C, saves regs, CALLs the runtime-patched $0000 cell (separate CP/M BIOS output entry installed by cold start at OUTDO_DEVICE2_1+1 / $820D). Used by OUTDO_WIDTH for the actual character emission distinct from OUTDO_DEVICE.
OUTDO_DEVICE2:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD C,A
; [RE] VERIFIED smc. OUTDO_DEVICE2_1+1 ($670A) is the SMC operand of CALL $0000 ($6709), reached by fall-through from OUTDO_DEVICE2 ($6704). COLD_START LD (OUTDO_DEVICE2_1+1),HL at $820D patches it to the live CP/M BIOS list/raw-output entry (from the BIOS jump-table walk). +1 is the patch slot, not a code entry; the patched CALL executes at runtime. MBASIC twin patches at $5E8B.
OUTDO_DEVICE2_1:
        CALL $0000
        POP HL
        POP DE
        POP BC
        POP AF
        RET
; [RE] Force end-of-line bookkeeping: calls RESET_PRINT_STATE to clear column state, then falls into LINE_COUNT_INC to bump the printed-line counter / page check ($0B12 vs $083C).
LIST_NEWLINE_COUNT:
        CALL RESET_PRINT_STATE
; [RE] Increments the printed-line counter ($0B12) up to the page limit ($083C); clamps at the limit and returns A=0. Drives the auto-page / line-width newline logic in OUTDO_WIDTH.
LINE_COUNT_INC:
        LD A,(PAGE_LENGTH)
        LD B,A
        LD A,(L_0B12)
        INC A
        CP B
        JR NC,LINE_COUNT_INC_1
        LD (L_0B12),A
LINE_COUNT_INC_1:
        XOR A
        RET
; [RE] INCHR / auto-page 'more' handler on the LIST/INPUT path: if a file is the current channel (PTRFIL $0840 nonzero) read the next byte from that file via GETC_FILE_EOF and return it; otherwise (console) tests the pending key, runs the input poll (LOAD_CLEANUP_RESET) and the Ctrl-C/break check ($0CA0), and on a full page pushes STMT_FOR_7 and prints the pause prompt string at $0CF2 via STROUT before resuming.
INCHR:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR Z,INCHR_1
        CALL GETC_FILE_EOF
        JP NC,FMUL_7
        PUSH BC
        PUSH DE
        PUSH HL
        CALL LOAD_CLEANUP_RESET
        POP HL
        POP DE
        POP BC
        LD A,(CHAIN_BREAK_FLAG)
        OR A
        JP NZ,CHAIN_MOVE_STRING_VAR_3
        LD A,(L_084A)
        OR A
        LD HL,STMT_FOR_7
        EX (SP),HL
        JP NZ,CLEAR_RESET_DATAPTR
        EX (SP),HL
        PUSH BC
        PUSH DE
        LD HL,MSG_OK
        CALL STROUT
        POP DE
        POP BC
        XOR A
        POP HL
        RET
INCHR_1:
        POP HL
; [RE] CONIN: read one console character via the BIOS console-in vector (CALL into the runtime-patched $0000 cell), mask to 7 bits, and service the Ctrl-O ($0F) output-suppress toggle ($083F). The keyboard input primitive.
CONIN:
        PUSH BC
        PUSH DE
        PUSH HL
; [RE] VERIFIED smc. CONIN_1+1 ($6760) is the SMC operand of CALL $0000 ($675F), reached by fall-through from CONIN ($675C). COLD_START LD (CONIN_1+1),HL at $8203 patches it to the live CP/M BIOS CONIN entry (from the BIOS jump-table walk). +1 is the patch slot; the patched CALL executes on every console read. MBASIC twin patches at $5E81.
CONIN_1:
        CALL $0000
        POP HL
        POP DE
        POP BC
        AND $7F
        CP $0F
        RET NZ
        LD A,(CTRL_O_SUPPRESS)
        OR A
        CALL Z,ECHO_CTRL_O
        CPL
        LD (CTRL_O_SUPPRESS),A
        OR A
        JP Z,ECHO_CTRL_O
        XOR A
        RET
; [RE] If the auto-print column flag ($0B11) is nonzero, emit CR/LF (CRLF $6788); else return. Ensures output starts on a fresh line.
PRINT_CRLF_IF_COL:
        LD A,(L_0B11)
        OR A
        RET Z
        JP CRLF
PRINT_CRLF_IF_COL_1:
        LD (HL),$00
        LD HL,L_0A0D
; [RE] Output CR ($0D) + LF ($0A) to the console (via OUTCHR), then clear pending auto-line state. The print-newline routine; used by the sign-on and after each Ok prompt.
CRLF:
        LD A,$0D
        CALL OUTCHR
        LD A,$0A
        CALL OUTCHR
; [RE] RESET_PRINT_STATE: clear pending auto-line / print-column state ($0837 column, PRTFLG $0838, $0B11) after a newline. (The cell consulted here is PTRFIL $0840, the current-file pointer, not a 'line-input-in-progress' flag.)
RESET_PRINT_STATE:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        POP HL
        JR Z,RESET_PRINT_STATE_1
        XOR A
        RET
RESET_PRINT_STATE_1:
        LD A,(PRTFLG)
        OR A
        JR Z,RESET_PRINT_STATE_2
        XOR A
        LD (OUTPUT_COLUMN),A
        RET
RESET_PRINT_STATE_2:
        XOR A
        LD (L_0B11),A
        XOR A
        RET
; [RE] RPC stub: CALL the runtime-patched 6502-bridge vector at $0000 (cell filled by cold-start from the CP/M BIOS jump table) to poll console status; returns Z per result. One of several $0000 RPC call sites the cold-start patcher fixes up.
RPC_CONST_POLL:
        PUSH BC
        PUSH DE
        PUSH HL
; [RE] VERIFIED smc. RPC_CONST_POLL_1+1 ($67B2) is the SMC operand of CALL $0000 ($67B1), reached by fall-through from RPC_CONST_POLL ($67AE). COLD_START LD (RPC_CONST_POLL_1+1),HL at $81F6 patches it to the live CP/M BIOS CONST entry (BIOS base+4, the same HL written to INKEY_SCAN_2+1 at $81F3). +1 is the patch slot; the patched CALL executes when polling console status. MBASIC twin patches at $5E74.
RPC_CONST_POLL_1:
        CALL $0000
        POP HL
        POP DE
        POP BC
        OR A
        RET Z
; [RE] Keyboard scan / pending-char handler (INKEY$ / Ctrl-C-Ctrl-S poll): reads a console char (CONIN), processes the Ctrl-S ($13) pause and Ctrl-C ($03) break ($0834 pending-key cell), and returns it. INKEY_SCAN_1 ($67CC) is the INKEY$ function evaluator.
INKEY_SCAN:
        CALL CONIN
        CP $13
        CALL Z,CONIN
        LD (PENDING_KEY),A
        CP $03
        CALL Z,ECHO_CTRL_CHAR
        JP STMT_STOP
INKEY_SCAN_1:
        CALL CHRGET
        PUSH HL
        CALL GET_PENDING_KEY
        JR NZ,INKEY_SCAN_3
; [RE] VERIFIED smc. INKEY_SCAN_2+1 ($67D6) is the SMC operand of CALL $0000 ($67D5), reached by fall-through from INKEY_SCAN_1 ($67CC) on the no-pending-key path. COLD_START LD (INKEY_SCAN_2+1),HL at $81F3 patches it to the live CP/M BIOS CONST entry for INKEY$ polling (BIOS base+4, same HL also written to RPC_CONST_POLL_1+1 at $81F6). +1 is the patch slot; the patched CALL executes when polling for a key. MBASIC twin uses the same COLD_START BIOS-table walk.
INKEY_SCAN_2:
        CALL $0000
        OR A
        JR Z,INKEY_SCAN_4
        CALL CONIN
INKEY_SCAN_3:
        PUSH AF
        CALL ALLOC_STR_1
        POP AF
        LD E,A
        CALL STR_FN_RETURN_CHAR
INKEY_SCAN_4:
        LD HL,L_0CF1
        LD (FAC),HL
        LD A,VT_STR
        LD (VALTYP),A
        POP HL
        RET
; [RE] Fetch and clear the pending-key cell ($0834) set by INKEY_SCAN; returns Z if no key pending, else the key in A with the cell zeroed.
GET_PENDING_KEY:
        LD A,(PENDING_KEY)
        OR A
        RET Z
        PUSH AF
        XOR A
        LD (PENDING_KEY),A
        POP AF
        RET
; [RE] Print a char via OUTCHR ($6613); if it was LF ($0A) also emit CR ($0D) and reset print state. Newline-expanding console write.
OUTCHR_LF_EXPAND:
        CALL OUTCHR
        CP $0A
        RET NZ
        LD A,$0D
        CALL OUTCHR
        CALL RESET_PRINT_STATE
        LD A,$0A
        RET
; [RE] After GC_CHECK_AND_COLLECT, copy a string of BC bytes downward from (HL) to (BC dest), comparing via HL/DE-compare; the string-move primitive used by string assignment.
STR_COPY_DOWN:
        CALL GC_CHECK_AND_COLLECT
; [RE] String copy loop without the prior heap check: move bytes from (HL) to (BC) decrementing both until HL==DE (CMP_HL_DE compare). Tail of STR_COPY_DOWN.
STR_COPY_DOWN_NOCHK:
        PUSH BC
        EX (SP),HL
        POP BC
STR_COPY_DOWN_NOCHK_1:
        CALL CMP_HL_DE
        LD A,(HL)
        LD (BC),A
        RET Z
        DEC BC
        DEC HL
        JR STR_COPY_DOWN_NOCHK_1
; [RE] GETSTK/stack-room check: verify BC*2 bytes are available between SP and the top-of-storage pointer ($0B23); on failure fall through to CHECK_STACK_ROOM_1 which raises 'Out of memory' (error E=$07) via the RAISE_ERROR dispatcher.
CHECK_STACK_ROOM:
        PUSH HL
        LD HL,(MEMSIZ)
        LD B,$00
        ADD HL,BC
        ADD HL,BC
        LD A,$C6
        SUB L
        LD L,A
        LD A,$FF
        SBC A,H
        JR C,CHECK_STACK_ROOM_1
        LD H,A
        ADD HL,SP
        POP HL
        RET C
CHECK_STACK_ROOM_1:
        LD HL,(TOP_OF_STACK_ROOM)
        DEC HL
        DEC HL
        LD (SAVSTK),HL
CHECK_STACK_ROOM_2:
        LD DE,ERR_OUT_OF_MEMORY
        JP RAISE_ERROR
; [RE] String free/space guard: if the requested string allocation would collide with the variable space, trigger garbage collection (GARBAG) and retry; if still no room raise 'Out of string space' (E=$07/$0E) via RAISE_ERROR.
GC_CHECK_AND_COLLECT:
        CALL CMP_STR_VS_VARTOP
        RET NC
        PUSH BC
        PUSH DE
        PUSH HL
        CALL GARBAG
        POP HL
        POP DE
        POP BC
        CALL CMP_STR_VS_VARTOP
        RET NC
        JR CHECK_STACK_ROOM_2
; [RE] Compare a candidate string-heap address (HL) against the string/var-space top pointer ($0B48) via the 16-bit compare; returns carry if the allocation would collide. Used by GC_CHECK_AND_COLLECT.
CMP_STR_VS_VARTOP:
        PUSH DE
        EX DE,HL
        LD HL,(FRETOP)
        CALL CMP_HL_DE
        EX DE,HL
        POP DE
        RET

; ======================================================================
; PROGRAM / VARIABLE MANAGEMENT (CLEAR, NEW, GC)
; ======================================================================
; [RE] RUN/CLEAR setup: zero the array of work-pointers indexed by $0870 (file/FOR slots) starting at $0850, then fall through to clear variables. Entry from the warm-start path ($81BD).
RUN_CLEAR:
        LD A,(MAX_FILE_NUM)
        LD B,A
        LD HL,FILTAB
        XOR A
        INC B
RUN_CLEAR_1:
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD (DE),A
        DJNZ RUN_CLEAR_1
        CALL CLOSE_ALL_FILES
        XOR A
; [RE] NEW statement handler (token $94): erases the current program and variables.
STMT_NEW:
        RET NZ
; [RE] CLEARC: reset the variable, array and string-heap pointers ($0B57/$0B56/$0B6F, top-of-string), clearing all variables. The NEW/CLEAR/RUN re-initialization of the dynamic storage map.
CLEAR_VARS:
        LD HL,(TXTTAB)
        CALL STMT_TRACE+1
        LD (L_0C99),A
        LD (AUTFLG),A
        LD (L_0B56),A
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (VARTAB),HL
; [RE] CLEAR/RUN reinit: load program start ($0846), step back, fall into the storage-map reset that re-points the variable/array/string base pointers ($0B54 etc.).
CLEAR_RESET_DATAPTR:
        LD HL,(TXTTAB)
        DEC HL
; [RE] Core CLEAR/NEW/RUN storage re-initialization: rebuilds the variable, array, FOR/file-slot, DATA and string-heap pointers, clears the math accumulator slots, resets stack and graphics state; common tail of NEW/CLEAR/RUN.
CLEAR_RESET_STORAGE:
        LD (OPEN_RESUME_TEXT_PTR),HL
        LD A,(CHAIN_PRESERVE_FLAG)
        OR A
        JR NZ,CLEAR_RESET_STORAGE_2
        XOR A
        LD (L_0C74),A
        LD (L_0C73),A
        LD B,$1A
        LD HL,DEFTYPE_TBL
CLEAR_RESET_STORAGE_1:
        LD (HL),$04
        INC HL
        DJNZ CLEAR_RESET_STORAGE_1
CLEAR_RESET_STORAGE_2:
        LD DE,L_5D85
        LD HL,RNDX_SEED
        CALL FP_MOVE4
        LD HL,FN_RND_4
        XOR A
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
        XOR A
        LD (ONEFLG),A
        LD L,A
        LD H,A
        LD (ON_ERROR_LINE),HL
        LD (CONT_TXTPTR),HL
        LD HL,(MEMSIZ)
        LD A,(CHAIN_BREAK_FLAG)
        OR A
        JR NZ,CLEAR_RESET_STORAGE_3
        LD (FRETOP),HL
CLEAR_RESET_STORAGE_3:
        XOR A
        CALL STMT_RESTORE
        LD HL,(VARTAB)
        LD (ARYTAB),HL
        LD (STREND),HL
        LD A,(CHAIN_PRESERVE_FLAG)
        OR A
        CALL Z,CLOSE_ALL_FILES
        POP BC
        LD HL,(TOP_OF_STACK_ROOM)
        DEC HL
        DEC HL
        LD (SAVSTK),HL
        INC HL
        INC HL
; [RE] Stack-reset / run-state init trampoline (RUN/LOAD/file-error unwind): LD SP,HL restores the stack, reinits the stack guard ($0B25), clears reverse-video + output column, and zeroes the run-time work cells. The +offset entry just reloads the text pointer from $0B54.
RESET_RUN_STATE:
        LD SP,HL
        LD HL,TEMPST
        LD (TEMPPT),HL
        CALL GFX_CLR_REVERSE_FLAG
        CALL OUTDO_RESET_COL
        CALL PRINT_RESET_STATE
        XOR A
        LD H,A
        LD L,A
        LD (L_0B93),HL
        LD (L_0C64),A
        LD (L_0BFB),HL
        LD (L_0C67),HL
        LD (L_0B91),HL
        LD (PTRGET_SUBSCRIPT_FLAG),A
        PUSH HL
        PUSH BC
RESET_RUN_STATE_1:
        LD HL,(OPEN_RESUME_TEXT_PTR)
        RET
; MS BASIC 16-bit compare: A=H-D then (if equal) A=L-E, setting Z when HL==DE and carry per HL<DE. The pervasive pointer-compare primitive (68 call sites).
CMP_HL_DE:
        LD A,H
        SUB D
        RET NZ
        LD A,L
        SUB E
        RET

; ======================================================================
; CORE HELPERS (SYNCHR, FNDLIN, stack/mem checks)
; ======================================================================
; MS BASIC SYNCHR: verify the current char at (HL) equals the literal byte placed inline immediately after the CALL; if it matches, advance past it and CHRGET the next char; on mismatch JP to Syntax Error ($0D6F). The pervasive 'expect this token' primitive.
SYNCHR:
        LD A,(HL)
        EX (SP),HL
        CP (HL)
        JR NZ,SYNCHR_1
        INC HL
        EX (SP),HL
        INC HL
        LD A,(HL)
        CP $3A
        RET NC
        JP CHRGOT_1
SYNCHR_1:
        JP RAISE_SYNTAX_ERROR
; [RE] RESTORE statement handler (token $8C): resets the DATA read pointer (optionally to a line number).
STMT_RESTORE:
        EX DE,HL
        LD HL,(TXTTAB)
        JR Z,STMT_RESTORE_1
        EX DE,HL
        CALL LINGET
        PUSH HL
        CALL FNDLIN
        LD H,B
        LD L,C
        POP DE
        JP NC,ERROR_UL
STMT_RESTORE_1:
        DEC HL
STMT_RESTORE_2:
        LD (L_0B75),HL
        EX DE,HL
        RET
; [RE] STOP statement handler (token $90): break to direct mode with a Break message (shares logic with END at $6956).
STMT_STOP:
        RET NZ
        INC A
        JP STMT_END_1

; ======================================================================
; BASIC-80 statement dispatch handlers (table base $0108, indexed by (token-$81)*2)
; ======================================================================
; [RE] END statement handler (token $81). Reached via the GONE/NEWSTT statement dispatcher at $33B1 (SUB $81; RLCA; LD HL,$0108; ADD HL,BC; load handler; JP).
STMT_END:
        RET NZ
        PUSH AF
        CALL Z,CLOSE_ALL_FILES
        POP AF
STMT_END_1:
        LD (OLDTXT),HL
        LD HL,TEMPST
        LD (TEMPPT),HL
; [RE] Dual entry. Fall-through (END/stop tail from STMT_END_1) runs LD HL,$FFF6 whose value is dead (RESUME_AT_DIRECT at $6969 reloads HL from SAVTXT); its only job is to eat the F6 FF bytes so A is preserved. The three JP C,STMT_END_2+1 sites (after INLIN returns carry = input aborted) enter +1 so F6 FF runs as OR $FF, flagging the break in A=$FF. Both merge at $6968 POP BC.
STMT_END_2:
        LD HL,$FFF6
        POP BC
; [RE] Return to direct/command mode after a statement or error: snapshot SAVTXT ($0844), save the RESUME/CONT pointers, clear the Ctrl-O suppress flag ($083F), reset the output column and emit a pending CRLF, then dispatch to the error-resume path or the 'Ok' ready prompt.
RESUME_AT_DIRECT:
        LD HL,(SAVTXT)
        PUSH HL
        PUSH AF
        LD A,L
        AND H
        INC A
        JR Z,RESUME_AT_DIRECT_1
        LD (SAVED_ERR_TXTPTR),HL
        LD HL,(OLDTXT)
        LD (CONT_TXTPTR),HL
RESUME_AT_DIRECT_1:
        XOR A
        LD (CTRL_O_SUPPRESS),A
        CALL OUTDO_RESET_COL
        CALL PRINT_CRLF_IF_COL
        POP AF
        LD HL,MSG_BREAK
        JP NZ,ERROR_RESUME_FROM_DIRECT
        JP READY_POP_FRAME
; [RE] Entry with A=$0F: echo a Ctrl-O as '^O'; falls into ECHO_CTRL_CHAR to print '^' + (ctrl+$40) then CRLF.
ECHO_CTRL_O:
        LD A,$0F
; [RE] Echo a control character as caret notation: prints '^' ($5E) then the char+$40 via OUTCHR, then CRLF; on Ctrl-C ($03) also clears the pause/suppress flags ($0838/$083F).
ECHO_CTRL_CHAR:
        PUSH AF
        SUB $03
        JR NZ,ECHO_CTRL_CHAR_1
        LD (PRTFLG),A
        LD (CTRL_O_SUPPRESS),A
ECHO_CTRL_CHAR_1:
        LD A,$5E
        CALL OUTCHR
        POP AF
        ADD A,$40
        CALL OUTCHR
        JP CRLF
; [RE] CONT statement handler (token $98): resume a stopped program from the saved text pointer ($0B6D).
STMT_CONT:
        LD HL,(CONT_TXTPTR)
        LD A,H
        OR L
        LD DE,ERR_CANT_CONTINUE
        JP Z,RAISE_ERROR
        EX DE,HL
        LD HL,(SAVED_ERR_TXTPTR)
        LD (SAVTXT),HL
        EX DE,HL
        RET
; [RE] TRACE statement handler (token $9F): enable execution trace (TRON-equivalent); sets the trace flag.
; [RE] TRON/TROFF share one tail. TRON (DEFW at $0144) enters $69BF and runs LD A,$AF (trace ON); TROFF (DEFW at $0146) and program-start (CALL from $687A) enter +1 so the AF byte runs as XOR A (trace OFF). Both fall into LD ($0CAB),A; RET, storing $AF or 0 into the trace flag read at $3393.
STMT_TRACE:
        LD A,$AF
        LD (TRCFLG),A
        RET
; [RE] SWAP statement handler (token $A1): exchange the values of two variables.
STMT_SWAP:
        CALL PTRGET_1+1
        PUSH DE
        PUSH HL
        LD HL,L_0CA3
        CALL FP_MOVE_TYPED
        LD HL,(ARYTAB)
        EX (SP),HL
        CALL FRMEVL_TEST_TYPE
        PUSH AF
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1
        POP BC
        CALL FRMEVL_TEST_TYPE
        CP B
        JP NZ,RAISE_TYPE_MISMATCH
        EX (SP),HL
        EX DE,HL
        PUSH HL
        LD HL,(ARYTAB)
        CALL CMP_HL_DE
        JP NZ,ERROR_FC
        POP DE
        POP HL
        EX (SP),HL
        PUSH DE
        CALL FP_MOVE_TYPED
        POP HL
        LD DE,L_0CA3
        CALL FP_MOVE_TYPED
        POP HL
        RET
; [RE] ERASE statement handler (token $A2): delete a dimensioned array, freeing its ARRAYVAR storage. PTRGET returns BC -> the array DATA; ERASE reconstructs the descriptor BASE by reverse sequential stepping: DEC BC x3 over {ndims, blklen-word} ($6A14), then walk the packed name backward while the high bit is set ($6A17 LD A,(BC)/DEC BC/JP M), then DEC BC x2 over {name0/name1, valtyp}. ADD HL,DE (HL=data, DE=AV_BLKLEN) gives the array end, then the block above slides down ($6A24-$6A30) and STREND is lowered. No base+offset; the descriptor base is found by walking, not a fixed offset.
STMT_ERASE:
        LD A,$01
        LD (PTRGET_SUBSCRIPT_FLAG),A
        CALL PTRGET_1+1
        JP NZ,ERROR_FC
        PUSH HL
        LD (PTRGET_SUBSCRIPT_FLAG),A
        LD H,B
        LD L,C
        DEC BC
        DEC BC
        DEC BC
STMT_ERASE_1:
        LD A,(BC)
        DEC BC
        OR A
        JP M,STMT_ERASE_1
        DEC BC
        DEC BC
        ADD HL,DE
        EX DE,HL
        LD HL,(STREND)
STMT_ERASE_2:
        CALL CMP_HL_DE
        LD A,(DE)
        LD (BC),A
        INC DE
        INC BC
        JR NZ,STMT_ERASE_2
        DEC BC
        LD H,B
        LD L,C
        LD (STREND),HL
        POP HL
        LD A,(HL)
        CP $2C
        RET NZ
        CALL CHRGET
        JR STMT_ERASE
STMT_ERASE_3:
        POP AF
        POP HL
        RET
; [RE] Test (HL): set carry if the char is a letter A-Z ($41-$5A); returns carry/no-carry to classify identifier start chars.
IS_LETTER:
        LD A,(HL)
; [RE] Same letter test on the char already in A: carry if A in $41-$5A, else clear (CCF after the upper-bound test).
IS_LETTER_A:
        CP $41
        RET C
        CP $5B
        CCF
        RET
; [RE] CLEAR statement handler (token $92): clears variables/strings and optionally sets memory/stack limits.
STMT_CLEAR:
        JP Z,CLEAR_RESET_STORAGE
        CP $2C
        JR Z,STMT_CLEAR_1
        CALL GETINT_POSITIVE
        DEC HL
        CALL CHRGET
        JP Z,CLEAR_RESET_STORAGE
STMT_CLEAR_1:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        JP Z,CLEAR_RESET_STORAGE
        EX DE,HL
        LD HL,(TOP_OF_STACK_ROOM)
        EX DE,HL
        CP $2C
        JR Z,STMT_CLEAR_2
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL GETADR
        LD A,H
        OR L
        JP Z,ERROR_FC
        EX DE,HL
        POP HL
STMT_CLEAR_2:
        DEC HL
        CALL CHRGET
        PUSH DE
        JR Z,STMT_CLEAR_4
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        JR Z,STMT_CLEAR_4
        CALL GETINT_POSITIVE
        DEC HL
        CALL CHRGET
        JP NZ,RAISE_SYNTAX_ERROR
STMT_CLEAR_3:
        EX (SP),HL
        PUSH HL
        LD HL,$004E
        CALL CMP_HL_DE
        JP NC,CHECK_STACK_ROOM_1
        POP HL
        CALL SUB_HL_DE
        JP C,CHECK_STACK_ROOM_1
        PUSH HL
        LD HL,(VARTAB)
        LD BC,$0014
        ADD HL,BC
        CALL CMP_HL_DE
        JP NC,CHECK_STACK_ROOM_1
        EX DE,HL
        LD (MEMSIZ),HL
        POP HL
        LD (TOP_OF_STACK_ROOM),HL
        POP HL
        JP CLEAR_RESET_STORAGE
STMT_CLEAR_4:
        PUSH HL
        LD HL,(TOP_OF_STACK_ROOM)
        EX DE,HL
        LD HL,(MEMSIZ)
        LD A,E
        SUB L
        LD E,A
        LD A,D
        SBC A,H
        LD D,A
        POP HL
        JR STMT_CLEAR_3
; [RE] 16-bit subtract: DE = HL - DE (LD A,L/SUB E / LD A,H/SBC D), used by CLEAR to size the protected memory region.
SUB_HL_DE:
        LD A,L
        SUB E
        LD E,A
        LD A,H
        SBC A,D
        LD D,A
        RET
; [RE] NEXT statement handler (token $83): advances/closes the current FOR loop frame.
STMT_NEXT:
        PUSH AF
; [RE] Shared NEXT body, two entries. NEXT statement falls through $6AD3 OR $AF (A nonzero) so the $0C6C flag marks 'NEXT'; the FOR-loop re-iteration (JP STMT_NEXT_1+1 from $3364) enters +1 so the AF byte runs as XOR A (flag 0). Both store via LD ($0C6C),A; POP AF; the flag is read at $6B0D/$6B3A.
STMT_NEXT_1:
        OR $AF
        LD (L_0C6C),A
        POP AF
        LD DE,$0000
; [RE] Core of the NEXT statement: locate the matching FOR frame on the stack ($0CFD search), apply the STEP, compare against the limit, and either re-enter the loop (STMT_FOR_6) or fall through to loop exit; also handles 'NEXT var,var'.
NEXT_LOOP_BODY:
        LD (L_0C6A),HL
        CALL NZ,PTRGET_1+1
        LD (OPEN_RESUME_TEXT_PTR),HL
        CALL STKFRAME_SCAN_INIT
        JP NZ,RAISE_NEXT_WITHOUT_FOR
        LD SP,HL
        PUSH DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        PUSH HL
        LD HL,(L_0C6A)
        CALL CMP_HL_DE
        JP NZ,RAISE_NEXT_WITHOUT_FOR
        POP HL
        POP DE
        PUSH DE
        LD A,(HL)
        PUSH AF
        INC HL
        PUSH DE
        LD A,(HL)
        INC HL
        OR A
        JP M,NEXT_LOOP_BODY_2
        CALL FP_STORE_REGS_LD
        EX (SP),HL
        PUSH HL
        LD A,(L_0C6C)
        OR A
        JR NZ,NEXT_LOOP_BODY_1
        LD HL,FOR_NEXT_VALUE_TEMP
        CALL FP_STORE_REGS_LD
        XOR A
NEXT_LOOP_BODY_1:
        CALL NZ,FADD_FROM_MEM
        POP HL
        CALL FP_MOVE_TO_FAC
        POP HL
        CALL FP_LOAD_MEM
        PUSH HL
        CALL FCOMP
        JR NEXT_LOOP_BODY_5
NEXT_LOOP_BODY_2:
        INC HL
        INC HL
        INC HL
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        EX (SP),HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        PUSH HL
        LD L,C
        LD H,B
        LD A,(L_0C6C)
        OR A
        JR NZ,NEXT_LOOP_BODY_3
        LD HL,(FOR_NEXT_VALUE_TEMP)
        JR NEXT_LOOP_BODY_4
NEXT_LOOP_BODY_3:
        CALL IADD
        LD A,(VALTYP)
        CP VT_SNG
        JP Z,RAISE_OVERFLOW
NEXT_LOOP_BODY_4:
        EX DE,HL
        POP HL
        LD (HL),D
        DEC HL
        LD (HL),E
        POP HL
        PUSH DE
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        EX (SP),HL
        CALL INT16_COMP
NEXT_LOOP_BODY_5:
        POP HL
        POP BC
        SUB B
        CALL FP_LOAD_MEM
        JR Z,NEXT_LOOP_BODY_6
        EX DE,HL
        LD (SAVTXT),HL
        LD L,C
        LD H,B
        JP STMT_FOR_6
NEXT_LOOP_BODY_6:
        LD SP,HL
        LD (SAVSTK),HL
        LD HL,(OPEN_RESUME_TEXT_PTR)
        LD A,(HL)
        CP $2C
        JP NZ,STMT_FOR_7
        CALL CHRGET
        CALL NEXT_LOOP_BODY
NEXT_LOOP_BODY_7:
        CALL FRETMP
        LD A,(HL)
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        POP DE
        PUSH BC
        PUSH AF
        CALL FRESTR1
        POP DE
        LD E,(HL)
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        POP HL
NEXT_LOOP_BODY_8:
        LD A,E
        OR D
        RET Z
        LD A,D
        SUB $01
        RET C
        XOR A
        CP E
        INC A
        RET NC
        DEC D
        DEC E
        LD A,(BC)
        INC BC
        CP (HL)
        INC HL
        JR Z,NEXT_LOOP_BODY_8
        CCF
        JP FP_SIGN_3
; [RE] OCT$(x) handler (function token $18): format x as octal-digit text (shared STR_FN_FINALIZE_1 tail).
FN_OCT_STR:
        CALL HEX_OCT_OUT
        JR FN_STR_1
; [RE] HEX$(x) handler (function token $19): format x as hex-digit text (shared STR_FN_FINALIZE_1 tail).
FN_HEX_STR:
        CALL HEX_OCT_OUT_1+1
        JR FN_STR_1
; [RE] STR$(x) handler (function token $12): format a number as its ASCII text (FOUT) and return a string temporary. The finalize tail (STR_FN_FINALIZE_1) is shared by OCT$/HEX$/SPACE$.
FN_STR:
        CALL FOUT_2
FN_STR_1:
        CALL SCAN_STR_LITERAL
        CALL FRESTR
        LD BC,STR_FN_RETURN_CHAR_1
        PUSH BC
; [RE] STR_BUILD_FROM_DESC: given (HL) -> a source STRDESC (msbasic_strdesc.inc), read STRDESC.LEN ($6BC6), GETSPA that many heap bytes, then read STRDESC.PTR (LD C,(HL)$6BCD / LD B,(HL)$6BCF) and copy LEN bytes (BLOCK_COPY_BC_TO_DE) into the new heap block, recording the result via STORE_STR_DESC. Materialises a string value's bytes into freshly owned heap space; used by string concatenation/formatting and CHAIN string preservation.
STR_BUILD_FROM_DESC:
        LD A,(HL)
        INC HL
        PUSH HL
        CALL GETSPA
        POP HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        CALL STORE_STR_DESC
        PUSH HL
        LD L,A
        CALL BLOCK_COPY_BC_TO_DE
        POP DE
        RET
; [RE] Allocate a 1-byte string (A=1) then build its descriptor; convenience entry into the descriptor builder for single-char string results (e.g. CHR$, INKEY$).
ALLOC_STR_1:
        LD A,$01
; [RE] Allocate an A-byte string via GETSPA, then fall into STORE_STR_DESC to record length/pointer.
ALLOC_STR_A:
        CALL GETSPA
; [RE] Store a string descriptor (length A, body pointer DE) into the temporary descriptor cell $0B45..$0B47 and return HL pointing at it.
STORE_STR_DESC:
        LD HL,DSCTMP
; [RE] STR_DESC_STORE: write a STRDESC (see msbasic_strdesc.inc) at (HL) -- STRDESC.LEN=A, STRDESC.PTR=DE (low E at +1, high D at +2); preserves HL. The universal 3-byte string-value-descriptor writer (length byte then heap/text pointer word); used right after GETSPA reserves string space and by SCAN_STR_BODY when measuring a literal.
STR_DESC_STORE:
        PUSH HL
        LD (HL),A
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        POP HL
        RET
; [RE] Scan a quoted/argument string starting before (HL): default terminator '"' ($22); measures length to the closing quote/NUL and forms a descriptor. PRINT/string-constant scanner (call sites in CRUNCH/FRMEVL/PRINT).
SCAN_STR_LITERAL:
        DEC HL
; [RE] Entry with B set to the open-quote terminator $22; sets D=B and scans the string body.
SCAN_STR_QUOTE:
        LD B,$22
; [RE] Entry with the terminator byte preset in B; copies to D and scans to that terminator or NUL.
SCAN_STR_TERM:
        LD D,B
; [RE] String-scan inner loop: walk (HL) counting chars in C until a NUL, the B-terminator or D-terminator; trims trailing spaces after a comma terminator and stores the resulting descriptor (length C).
SCAN_STR_BODY:
        PUSH HL
        LD C,$FF
SCAN_STR_BODY_1:
        INC HL
        LD A,(HL)
        INC C
        OR A
        JR Z,SCAN_STR_BODY_2
        CP D
        JR Z,SCAN_STR_BODY_2
        CP B
        JR NZ,SCAN_STR_BODY_1
SCAN_STR_BODY_2:
        CP $22
        CALL Z,CHRGET
        PUSH HL
        LD A,B
        CP $2C
        JR NZ,SCAN_STR_BODY_4
        INC C
SCAN_STR_BODY_3:
        DEC C
        JR Z,SCAN_STR_BODY_4
        DEC HL
        LD A,(HL)
        CP $20
        JR Z,SCAN_STR_BODY_3
SCAN_STR_BODY_4:
        POP HL
        EX (SP),HL
        INC HL
        EX DE,HL
        LD A,C
        CALL STORE_STR_DESC
; [RE] Place a string descriptor into the rotating string-temporary table (pointer $0B25, base $0B48): records type=string ($0B14=3), stores the descriptor and advances the temp pointer; on overflow raises 'String formula too complex' (E=$10 via RAISE_ERROR). Widely used to stage string FRMEVL results.
PUT_STR_TEMP:
        LD DE,DSCTMP
; [RE] Two entries to the string-temp store. PUT_STR_TEMP (fall-through, and JP from $6E82) enters $6C1D LD A,$D5 (A dead) so no DE is pushed and the later POP HL ($6C36) takes the return address. CALL PUT_STR_TEMP_1+1 (from $3FD8, DEF-string) enters +1 so the D5 byte runs as PUSH DE, making that POP HL retrieve the descriptor pointer instead.
PUT_STR_TEMP_1:
        LD A,$D5
        LD HL,(TEMPPT)
        LD (FAC),HL
        LD A,VT_STR
        LD (VALTYP),A
        CALL FP_MOVE_TYPED
        LD DE,FRETOP
        CALL CMP_HL_DE
        LD (TEMPPT),HL
        POP HL
        LD A,(HL)
        RET NZ
        LD DE,ERR_STRING_FORMULA_TOO_COMPLEX
        JP RAISE_ERROR
PUT_STR_TEMP_2:
        INC HL

; ======================================================================
; CONSOLE / I-O (OUTCHR, CONIN, STROUT, RPC bridge)
; ======================================================================
; [RE] STROUT/print-message: print the NUL-terminated string at (HL) (or counted string) to the console one char at a time via OUTCHR ($6613), translating CR. Used for the sign-on banner and error messages.
STROUT:
        CALL SCAN_STR_LITERAL
; [RE] STRPRT: print a string VALUE. FRESTR frees/locates the value's STRDESC (msbasic_strdesc.inc), then the generic 3-byte loader FP_LOAD_MEM3 ($6C46) reads the descriptor as D=STRDESC.LEN, C=STRDESC.PTR.lo, B=STRDESC.PTR.hi; STRPRT_1 then outputs LEN (D) bytes from (BC) via OUTCHR, resetting print state on CR. Entry past STROUT's literal scan; used by PRINT/LPRINT/INPUT-prompt ($37C4/$3927/$65EF/$75B4/$75D6).
STRPRT:
        CALL FRESTR
        CALL FP_LOAD_MEM3
        INC D
STRPRT_1:
        DEC D
        RET Z
        LD A,(BC)
        CALL OUTCHR
        CP $0D
        CALL Z,RESET_PRINT_STATE
        INC BC
        JR STRPRT_1
; [RE] String-space allocator (GETSPA): reserve A bytes at the top of the string heap (top-of-string pointer $0B48, string area base $0B73), invoking garbage collection on exhaustion; raises 'Out of string space' (E=$0E).
GETSPA:
        OR A
; [RE] GC-retry tail. GETSPA falls into $6C59 LD C,$F1 (sentinel, C overwritten at $6C64) then PUSH AF and checks the heap. On exhaustion GETSPA_3 (after CP A) pushes GETSPA_1+1 ($6C5A) as GARBAG's return address; GARBAG RETs into +1 where the F1 byte runs as POP AF (undo the $6C7D saved-flags push) and the allocation is retried.
GETSPA_1:
        LD C,$F1
        PUSH AF
        LD HL,(STREND)
        EX DE,HL
        LD HL,(FRETOP)
        CPL
        LD C,A
        LD B,$FF
        ADD HL,BC
        INC HL
        CALL CMP_HL_DE
        JR C,GETSPA_3
        LD (FRETOP),HL
        INC HL
        EX DE,HL
GETSPA_2:
        POP AF
        RET
GETSPA_3:
        POP AF
        LD DE,ERR_OUT_OF_STRING_SPACE
        JP Z,RAISE_ERROR
        CP A
        PUSH AF
        LD BC,GETSPA_1+1
        PUSH BC
; MS BASIC-80 GARBAG: garbage-collect / compact the string heap. Scans simple string variables, string arrays and string temporaries (pointers $0B23/$0B73/$0B27/$0B25) to find the highest still-referenced string and slide live strings up, reclaiming free space. Called by GETSPA when the heap is full.
GARBAG:
        LD HL,(MEMSIZ)
GARBAG_1:
        LD (FRETOP),HL
        LD HL,$0000
        PUSH HL
        LD HL,(STREND)
        PUSH HL
        LD HL,TEMPST
GARBAG_2:
        EX DE,HL
        LD HL,(TEMPPT)
        EX DE,HL
        CALL CMP_HL_DE
        LD BC,GARBAG_2
        JP NZ,GARBAG_9
        LD HL,L_0BF9
        LD (L_0C65),HL
        LD HL,(ARYTAB)
        LD (L_0C62),HL
        LD HL,(VARTAB)
; [RE] GC simple-variable walk over SIMPLEVAR records (VARTAB..ARYTAB, cmp to $0C62). Per entry: SV_VALTYP ($6CBA), skip 3-byte header ($6CBB-BD), VARTAB_SKIP_ENTRY consumes SV_NAMEXTLEN+namext ($6CBF) leaving HL at value; if VALTYP==3 (string) fix its descriptor (GARBAG_FIX_STR_PTR $6CC7) else add SV_VALTYP to step past the value ($6CCB-CE). Sequential walk.
GARBAG_3:
        EX DE,HL
        LD HL,(L_0C62)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,GARBAG_5
        LD A,(HL)
        INC HL
        INC HL
        INC HL
        PUSH AF
        CALL VARTAB_SKIP_ENTRY
        POP AF
        CP $03
        JR NZ,GARBAG_4
        CALL GARBAG_FIX_STR_PTR
        XOR A
GARBAG_4:
        LD E,A
        LD D,$00
        ADD HL,DE
        JR GARBAG_3
GARBAG_5:
        LD HL,(L_0C65)
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        OR H
        EX DE,HL
        LD HL,(ARYTAB)
        JR Z,GARBAG_7
        EX DE,HL
        LD (L_0C65),HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        EX DE,HL
        ADD HL,DE
        LD (L_0C62),HL
        EX DE,HL
        JR GARBAG_3
GARBAG_6:
        POP BC
; [RE] GC array-table walk over ARRAYVAR records (ARYTAB..STREND, cmp to $0B73). Per entry: read AV_VALTYP ($6CFD), skip the 3-byte header ($6D00-01 + the type byte already consumed) and the name via VARTAB_SKIP_ENTRY ($6D02), load AV_BLKLEN ($6D05-08) to find the next descriptor; only VALTYP==3 (string) arrays have their element descriptors scanned (loop GARBAG_8 $6D1A using AV_NDIMS at $6D14 to size the element block). Sequential, stored-stride.
GARBAG_7:
        EX DE,HL
        LD HL,(STREND)
        EX DE,HL
        CALL CMP_HL_DE
        JP Z,GARBAG_FIX_STR_PTR_1
        LD A,(HL)
        INC HL
        PUSH AF
        INC HL
        INC HL
        CALL VARTAB_SKIP_ENTRY
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        POP AF
        PUSH HL
        ADD HL,BC
        CP $03
        JR NZ,GARBAG_6
        LD (L_0B4C),HL
        POP HL
        LD C,(HL)
        LD B,$00
        ADD HL,BC
        ADD HL,BC
        INC HL
GARBAG_8:
        EX DE,HL
        LD HL,(L_0B4C)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,GARBAG_7
        LD BC,GARBAG_8
GARBAG_9:
        PUSH BC
; [RE] GARBAG helper: scan a string descriptor (length+ptr at HL) and, if the string lives below the current collection watermark ($0B48), record it as the new candidate highest free-able block; advances HL past the descriptor.
GARBAG_FIX_STR_PTR:
        XOR A
        OR (HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        RET Z
        LD B,H
        LD C,L
        LD HL,(FRETOP)
        CALL CMP_HL_DE
        LD H,B
        LD L,C
        RET C
        POP HL
        EX (SP),HL
        CALL CMP_HL_DE
        EX (SP),HL
        PUSH HL
        LD H,B
        LD L,C
        RET NC
        POP BC
        POP AF
        POP AF
        PUSH HL
        PUSH DE
        PUSH BC
        RET
GARBAG_FIX_STR_PTR_1:
        POP DE
        POP HL
        LD A,L
        OR H
        RET Z
        DEC HL
        LD B,(HL)
        DEC HL
        LD C,(HL)
        PUSH HL
        DEC HL
        LD L,(HL)
        LD H,$00
        ADD HL,BC
        LD D,B
        LD E,C
        DEC HL
        LD B,H
        LD C,L
        LD HL,(FRETOP)
        CALL STR_COPY_DOWN_NOCHK
        POP HL
        LD (HL),C
        INC HL
        LD (HL),B
        LD L,C
        LD H,B
        DEC HL
        JP GARBAG_1
; [RE] FRESTR/movestring helper: pull a string's descriptor (via FRMEVL_EVAL_OPERAND), free its data with FRESTR1, then copy the bytes into freshly-allocated string space (STR_COPY_DESCR_DATA block copies); returns through FRMEVL fixup.
STR_CONCAT:
        PUSH BC
        PUSH HL
        LD HL,(FAC)
        EX (SP),HL
        CALL FRMEVL_EVAL_OPERAND
        EX (SP),HL
        CALL FP_INT_CHECK
        LD A,(HL)
        PUSH HL
        LD HL,(FAC)
        PUSH HL
        ADD A,(HL)
        LD DE,ERR_STRING_TOO_LONG
        JP C,RAISE_ERROR
        CALL ALLOC_STR_A
        POP DE
        CALL FRESTR1
        EX (SP),HL
        CALL FRESTR_DE
        PUSH HL
        LD HL,(L_0B46)
        EX DE,HL
        CALL STR_COPY_DESCR_DATA
        CALL STR_COPY_DESCR_DATA
        LD HL,FRMEVL_OPLOOP_1
        EX (SP),HL
        PUSH HL
        JP PUT_STR_TEMP
; [RE] copy one string-descriptor's data: pops the descriptor (len in A, addr in BC) off the caller's stack and block-copies len bytes from (BC) to (DE) via BLOCK_COPY_BC_TO_DE.
STR_COPY_DESCR_DATA:
        POP HL
        EX (SP),HL
        LD A,(HL)
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD L,A
; [RE] copy A (=L) bytes from (BC) to (DE), ascending; INC L / DEC L sets the counter, RET Z when done. Generic ascending memory move.
BLOCK_COPY_BC_TO_DE:
        INC L
BLOCK_COPY_BC_TO_DE_1:
        DEC L
        RET Z
        LD A,(BC)
        LD (DE),A
        INC BC
        INC DE
        JR BLOCK_COPY_BC_TO_DE_1
; MS BASIC-80 FRETMP: free the most-recent temporary string descriptor (CALL FREFAC at $5035), then fall into FRESTR to reclaim its heap bytes if it was the topmost allocation.
FRETMP:
        CALL FP_INT_CHECK
; MS BASIC-80 FRESTR: free the string whose descriptor pointer is in FAC ($0CB1); loads the descriptor then frees its data via FRESTR1 (FRESTR1).
FRESTR:
        LD HL,(FAC)
; MS BASIC-80 FRESTR entry with descriptor address already in HL: EX DE,HL then free.
FRESTR_DE:
        EX DE,HL
; MS BASIC-80 FRESTR1: if the descriptor points at the topmost string-heap allocation, hand its bytes back by advancing the top-of-free-string pointer ($0B48); otherwise leave the heap unchanged.
FRESTR1:
        CALL FREE_TOP_TEMP_DESCR
        EX DE,HL
        RET NZ
        PUSH DE
        LD D,B
        LD E,C
        DEC DE
        LD C,(HL)
        LD HL,(FRETOP)
        CALL CMP_HL_DE
        JR NZ,FRESTR1_1
        LD B,A
        ADD HL,BC
        LD (FRETOP),HL
FRESTR1_1:
        POP HL
        RET
; [RE] pop the most-recently-pushed temporary string descriptor off the temp-descriptor stack ($0B25): if HL matches, retract the temp pointer by one descriptor and clear Z.
FREE_TOP_TEMP_DESCR:
        LD HL,(TEMPPT)
        DEC HL
        LD B,(HL)
        DEC HL
        LD C,(HL)
        DEC HL
        CALL CMP_HL_DE
        RET NZ
        LD (TEMPPT),HL
        RET
; [RE] LEN(a$) handler (function token $11): length of a string (its descriptor count byte) into the FAC.
FN_LEN:
        LD BC,FP_LOAD_INT_TO_FAC
        PUSH BC
; [RE] evaluate the pending string argument to a descriptor (via FRETMP), returning the descriptor's length in A and address in HL; Z set if the string is empty.
GET_STR_DESCR_PTR:
        CALL FRETMP
        XOR A
        LD D,A
        LD A,(HL)
        OR A
        RET
; [RE] ASC(a$) handler (function token $14): character code of the string FIRST byte into the FAC (FC error if the string is empty).
FN_ASC:
        LD BC,FP_LOAD_INT_TO_FAC
        PUSH BC
; [RE] FN_VAL_BODY: fetch the argument's STRDESC (msbasic_strdesc.inc) via GET_STR_DESCR_PTR (HL -> descriptor, A=STRDESC.LEN), FC error if empty, then read STRDESC.PTR into DE (INC HL/LD E,(HL)$6E00/INC HL/LD D,(HL)$6E02) and LD A,(DE) to fetch the first character for numeric parsing (FIN).
FN_VAL_BODY:
        CALL GET_STR_DESCR_PTR
        JP Z,ERROR_FC
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD A,(DE)
        RET
; [RE] CHR$(n) handler (function token $15): allocate a 1-byte string holding character n; returned as a string temporary.
FN_CHR:
        CALL ALLOC_STR_1
        CALL CONINT
; [RE] string-function epilogue: store result char (E) into the string work buffer at ($0B46) and return through PUT_STR_TEMP (FRMEVL string-temp fixup).
STR_FN_RETURN_CHAR:
        LD HL,(L_0B46)
        LD (HL),E
STR_FN_RETURN_CHAR_1:
        POP BC
        JP PUT_STR_TEMP
; [RE] STRING$() body (token $E7): parse (count, char-or-string$) then pad-fill the new string via STR_FILL_ALLOC. NOT MID$ -- MID$ is FN_MID_STR $6582, token $03.
FN_STRING_STR:
        CALL CHRGET
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        PUSH DE
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL FRMEVL_NOPAREN
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        EX (SP),HL
        PUSH HL
        CALL FRMEVL_TEST_TYPE
        JR Z,FN_STRING_FROM_STR
        CALL CONINT
        JR STR_FN_RETURN_CHAR_4
; [RE] STRING$ branch when the fill argument is a string: use its first byte as the pad character (FN_VAL_BODY), then STR_FILL_ALLOC.
FN_STRING_FROM_STR:
        CALL FN_VAL_BODY
STR_FN_RETURN_CHAR_4:
        POP DE
        CALL STR_FILL_ALLOC
; [RE] SPACE$(n) handler (function token $17): build a string of n blanks via the shared string-fill allocator.
FN_SPACE:
        CALL CONINT
        LD A,$20
; [RE] STRING$/SPACE$ build helper: allocate B bytes of string space, fill with the pad char in A, returning the new descriptor; entry from the function epilogue at STR_FN_RETURN_CHAR.
STR_FILL_ALLOC:
        PUSH AF
        LD A,E
        CALL ALLOC_STR_A
        LD B,A
        POP AF
        INC B
        DEC B
        JR Z,STR_FN_RETURN_CHAR_1
        LD HL,(L_0B46)
; [RE] fill loop: write fill char A into B successive bytes of the freshly allocated string buffer at ($0B46).
STR_FILL_LOOP:
        LD (HL),A
        INC HL
        DJNZ STR_FILL_LOOP
        JR STR_FN_RETURN_CHAR_1
; [RE] LEFT$/RIGHT$/MID$ common tail: parse the length byte, clamp it to the source length, allocate a new string of that size and copy the selected substring into it; returns via FRMEVL string-temp fixup.
STR_SUBSTR_ALLOC_COPY:
        CALL PARSE_BYTE_ARG
        XOR A
STR_SUBSTR_ALLOC_COPY_1:
        EX (SP),HL
        LD C,A
; [RE] Substring alloc tail, two entries. LEFT$/MID$/RIGHT$ fall into $6E5B LD A,$E5 (A dead) and push HL once at _3 ($6E5D). PRINT-USING (CALL +1 from $65EC) enters $6E5C so the E5 byte runs as PUSH HL, then _3 pushes HL again, giving the second stacked HL that the normal callers supply via the pre-pushed descriptor.
STR_SUBSTR_ALLOC_COPY_2:
        LD A,$E5
STR_SUBSTR_ALLOC_COPY_3:
        PUSH HL
        LD A,(HL)
        CP B
        JR C,STR_SUBSTR_ALLOC_COPY_4+1
        LD A,B
; [RE] Length-clamp merge. No-carry (source>=requested) clamps A=B then runs LD DE,$000E (DE unused -> filler) and PRESERVES the copy-offset in C (set at $6E5A). The JR C from $6E60 (source<requested) enters +1 so the 0E 00 bytes run as LD C,$00, RESETTING the copy-offset to 0 while keeping A=source length. Both merge at $6E66 PUSH BC; CALL GETSPA; C is consumed at $6E74 ADD HL,BC. The 11 opcode hides the LD C,$00 on the no-carry path. (Refines prior 'value-neutral' note: C IS affected.)
STR_SUBSTR_ALLOC_COPY_4:
        LD DE,$000E
        PUSH BC
        CALL GETSPA
        POP BC
        POP HL
        PUSH HL
        INC HL
        LD B,(HL)
        INC HL
        LD H,(HL)
        LD L,B
        LD B,$00
        ADD HL,BC
        LD B,H
        LD C,L
        CALL STORE_STR_DESC
        LD L,A
        CALL BLOCK_COPY_BC_TO_DE
        POP DE
        CALL FRESTR1
        JP PUT_STR_TEMP

; ======================================================================
; BASIC-80 function dispatch handlers (table base $01B2, indexed by token*2; dispatcher at $3D8E)
; ======================================================================
; [RE] LEFT$() handler (function token $01): leftmost n chars of a string.
FN_LEFT_STR:
        CALL PARSE_BYTE_ARG
        POP DE
        PUSH DE
        LD A,(DE)
        SUB B
        JR STR_SUBSTR_ALLOC_COPY_1
; [RE] RIGHT$() handler (function token $02): rightmost n chars of a string.
FN_RIGHT_STR:
        EX DE,HL
        LD A,(HL)
        CALL POP_LEN_TO_B
        INC B
        DEC B
        JP Z,ERROR_FC
        PUSH BC
        CALL PARSE_OPT_LEN_ARG
        POP AF
        EX (SP),HL
        LD BC,STR_SUBSTR_ALLOC_COPY_3
        PUSH BC
        DEC A
        CP (HL)
        LD B,$00
        RET NC
        LD C,A
        LD A,(HL)
        SUB C
        CP E
        LD B,A
        RET C
        LD B,E
        RET
; [RE] VAL(a$) handler (function token $13): numeric value of a string (parsed via FIN); NUL-terminates the source then converts.
FN_VAL:
        CALL GET_STR_DESCR_PTR
        JP Z,FP_LOAD_INT_TO_FAC
        LD E,A
        INC HL
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        PUSH HL
        ADD HL,DE
        LD B,(HL)
        LD (HL),D
        EX (SP),HL
        PUSH BC
        DEC HL
        CALL CHRGET
        CALL FIN
        POP BC
        POP HL
        LD (HL),B
        RET
; [RE] parse a required numeric byte argument terminated by ')': SYNCHR ')' then return the prior length byte in B from the caller's pushed args.
PARSE_BYTE_ARG:
        EX DE,HL
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
; [RE] recover the source-string length byte into B from the two stacked descriptor halves, preserving the return address.
POP_LEN_TO_B:
        POP BC
        POP DE
        PUSH BC
        LD B,E
        RET
; [RE] INSTR() body (token $E9): parse optional start position then the two string arguments, search for the second string inside the first and return the 1-based match index (0 if not found).
FN_INSTR:
        CALL CHRGET
        CALL FRMEVL
        CALL FRMEVL_TEST_TYPE
        LD A,$01
        PUSH AF
        JR Z,POP_LEN_TO_B_2
        POP AF
        CALL CONINT
        OR A
        JP Z,ERROR_FC
        PUSH AF
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL FRMEVL_NOPAREN
        CALL FP_INT_CHECK
POP_LEN_TO_B_2:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        LD HL,(FAC)
        EX (SP),HL
        CALL FRMEVL_NOPAREN
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        PUSH HL
        CALL FRETMP
        EX DE,HL
        POP BC
        POP HL
        POP AF
        PUSH BC
        LD BC,FMUL_7
        PUSH BC
        LD BC,FP_LOAD_INT_TO_FAC
        PUSH BC
        PUSH AF
        PUSH DE
        CALL FRESTR_DE
        POP DE
        POP AF
        LD B,A
        DEC A
        LD C,A
        CP (HL)
        LD A,$00
        RET NC
        LD A,(DE)
        OR A
        LD A,B
        RET Z
        LD A,(HL)
        INC HL
        LD B,(HL)
        INC HL
        LD H,(HL)
        LD L,B
        LD B,$00
        ADD HL,BC
        SUB C
        LD B,A
        PUSH BC
        PUSH DE
        EX (SP),HL
        LD C,(HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        POP HL
POP_LEN_TO_B_3:
        PUSH HL
        PUSH DE
        PUSH BC
POP_LEN_TO_B_4:
        LD A,(DE)
        CP (HL)
        JR NZ,POP_LEN_TO_B_7
        INC DE
        DEC C
        JR Z,POP_LEN_TO_B_6
        INC HL
        DJNZ POP_LEN_TO_B_4
        POP DE
        POP DE
        POP BC
POP_LEN_TO_B_5:
        POP DE
        XOR A
        RET
POP_LEN_TO_B_6:
        POP HL
        POP DE
        POP DE
        POP BC
        LD A,B
        SUB H
        ADD A,C
        INC A
        RET
POP_LEN_TO_B_7:
        POP BC
        POP DE
        POP HL
        INC HL
        DJNZ POP_LEN_TO_B_3
        JR POP_LEN_TO_B_5
; [RE] LET MID$(var$,start[,len])=src$ assignment body: locate the target string in place (allocating/copying it down out of program/heap space if needed), then overwrite the selected character range with the source string's bytes (no length change).
STMT_MID_ASSIGN:
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        PUSH HL
        PUSH DE
        EX DE,HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD HL,(STREND)
        CALL CMP_HL_DE
        JR C,POP_LEN_TO_B_9
        LD HL,(TXTTAB)
        CALL CMP_HL_DE
        JR NC,POP_LEN_TO_B_9
        POP HL
        PUSH HL
        CALL STR_BUILD_FROM_DESC
        POP HL
        PUSH HL
        CALL FP_MOVE_TYPED
POP_LEN_TO_B_9:
        POP HL
        EX (SP),HL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        OR A
        JP Z,ERROR_FC
        PUSH AF
        LD A,(HL)
        CALL PARSE_OPT_LEN_ARG
        PUSH DE
        CALL EVAL_EXPR_AFTER_SYNCHR
        PUSH HL
        CALL FRETMP
        EX DE,HL
        POP HL
        POP BC
        POP AF
        LD B,A
        EX (SP),HL
        PUSH HL
        LD HL,FMUL_7
        EX (SP),HL
        LD A,C
        OR A
        RET Z
        LD A,(HL)
        SUB B
        JP C,ERROR_FC
        INC A
        CP C
        JR C,POP_LEN_TO_B_10
        LD A,C
POP_LEN_TO_B_10:
        LD C,B
        DEC C
        LD B,$00
        PUSH DE
        INC HL
        LD E,(HL)
        INC HL
        LD H,(HL)
        LD L,E
        ADD HL,BC
        LD B,A
        POP DE
        EX DE,HL
        LD C,(HL)
        INC HL
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        EX DE,HL
        LD A,C
        OR A
        RET Z
; [RE] MID$-assignment inner copy: write up to C bytes from the source (DE) over the target slice (HL), stopping at the shorter of source length or remaining target room.
MID_ASSIGN_COPY:
        LD A,(DE)
        LD (HL),A
        INC DE
        INC HL
        DEC C
        RET Z
        DJNZ MID_ASSIGN_COPY
        RET
; [RE] parse an optional second/length argument: default $FF (whole string) when next char is ')', otherwise SYNCHR ',' and read a byte expression; ends by checking for ')'.
PARSE_OPT_LEN_ARG:
        LD E,$FF
        CP $29
        JR Z,PARSE_OPT_LEN_ARG_1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
PARSE_OPT_LEN_ARG_1:
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        RET
; [RE] FRE() handler (function token $0F): free memory. A string arg triggers FRESTR+GARBAG (garbage collect); returns FRETOP minus the top of the variable/array area as the free byte count.
FN_FRE:
        CALL FRMEVL_TEST_TYPE
        JP NZ,FN_FRE_1
        CALL FRESTR
        CALL GARBAG
FN_FRE_1:
        LD HL,(STREND)
        EX DE,HL
        LD HL,(FRETOP)
        JP FP_INT_SUB_TO_FAC
; MS BASIC-80 QINLIN: print the '? ' input prompt then fall into the console line-input editor (INLIN). Called for INPUT and for the RANDOMIZE seed prompt.
QINLIN:
        LD A,$3F
        CALL OUTCHR
        LD A,$20
        CALL OUTCHR
        JP INLIN_RESET_LINE
; [RE] INLIN per-character fetch: read one console key (CONIN at $6724); Ctrl-A ($01) toggles into line-edit/redisplay, otherwise dispatch the character in the editor.
INLIN_GETCH:
        CALL INCHR
        CP $01
        JP NZ,INLIN_DISPATCH
        LD (HL),$00
        JR INLIN_1
; [RE] store char then reset editor state: clear the pending-control and auto-quote flags ($0834/$0C93) at the start of a fresh input line.
INLIN_PUT_AND_RESET:
        LD (HL),B
; [RE] INLIN restart-current-line entry: clear the pending-control flag ($0834) and the quote/literal flag ($0C93), then fall into INLIN to re-read the console input line (Ctrl-U line-kill / LF).
INLIN_RESET_LINE:
        XOR A
        LD (PENDING_KEY),A
        XOR A
        LD (L_0C93),A
; MS BASIC-80 INLIN: console line-input editor main loop. Reads keys, echoes printable characters into the line buffer at $0A0E, and handles control keys (CR, BS/Ctrl-H, Ctrl-U, Ctrl-R, Ctrl-X, Tab, LF, DEL) building an edited line; returns it with CY=Ctrl-C abort.
INLIN:
        CALL INLIN_SAVE_COLUMN
        CALL INCHR
        CP $01
        JR NZ,INLIN_6
INLIN_1:
        CALL CRLF
        LD HL,$FFFF
        JP STMT_EDIT_4
; [RE] DEL/rubout handling: echo a backslash on first delete, then erase one character from the buffer, updating the echo state at $083E.
INLIN_DELETE_CHAR:
        LD A,(L_083E)
        OR A
        LD A,$5C
        LD (L_083E),A
        JR NZ,INLIN_3
        DEC B
        JR Z,INLIN_PUT_AND_RESET
        CALL OUTCHR
        INC B
INLIN_3:
        DEC B
        DEC HL
        JR Z,INLIN_KILL_LINE
        LD A,(HL)
        CALL OUTCHR
        JR INLIN_GETCH
; [RE] continue rubout: emit the deleted character (in backslash-echo mode) and loop while more remain.
INLIN_ECHO_DELETED:
        DEC B
        DEC HL
        CALL OUTCHR
        JR NZ,INLIN_GETCH
; [RE] Ctrl-U / line-kill finish: echo the trailing char, CRLF, reset the prompt buffer pointer ($0A0E) and start the line over.
INLIN_KILL_LINE:
        CALL OUTCHR
        CALL CRLF
INLIN_6:
        LD HL,BUF
        LD B,$01
        PUSH AF
        XOR A
        LD (L_083E),A
        POP AF
; [RE] INLIN control-character dispatch: classify the input char (Bell $07, CR $0D, Tab $09, LF $0A, Ctrl-U $15, BS $08, Ctrl-X $18, Ctrl-R $12, < $20 ignore) and branch; printable chars fall through to the store path.
INLIN_DISPATCH:
        LD C,A
        CP $7F
        JR Z,INLIN_DELETE_CHAR
        LD A,(L_083E)
        OR A
        JR Z,INLIN_8
        LD A,$5C
        CALL OUTCHR
        XOR A
        LD (L_083E),A
INLIN_8:
        LD A,C
        CP $07
        JR Z,INLIN_STORE_CHAR
        CP $03
        CALL Z,ECHO_CTRL_CHAR
        SCF
        RET Z
        CP $0D
        JP Z,INLIN_CR_FINISH
        CP $09
        JR Z,INLIN_STORE_CHAR
        CP $0A
        JR NZ,INLIN_9
        DEC B
        JP Z,INLIN_RESET_LINE
        INC B
        JR INLIN_STORE_CHAR
INLIN_9:
        CP $15
        CALL Z,ECHO_CTRL_CHAR
        JP Z,INLIN_RESET_LINE
        CP $08
        JR NZ,INLIN_CTRL_X
        DEC B
        JP Z,INLIN
        CALL INLIN_BACKSPACE
        JP INLIN_GETCH
; [RE] Ctrl-X handling: discard the current line by echoing '#' and restarting the editor (jumps to the line-kill finish).
INLIN_CTRL_X:
        CP $18
        JP NZ,INLIN_CTRL_R
        LD A,$23
        JP INLIN_KILL_LINE
; [RE] Ctrl-R / retype-line: terminate the buffer, CRLF, redisplay the line accumulated so far (PRINT_ZSTRING) from $0A0E, then resume editing.
INLIN_CTRL_R:
        CP $12
        JR NZ,INLIN_12
        PUSH BC
        PUSH DE
        PUSH HL
        LD (HL),$00
        CALL CRLF
        LD HL,BUF
        CALL PRINT_ZSTRING
        POP HL
        POP DE
        POP BC
        JP INLIN_GETCH
INLIN_12:
        CP $20
        JP C,INLIN_GETCH
; [RE] store a printable character: guard against buffer overflow (255 chars -> Bell and reformat via $34E0/CRUNCH_EMIT), else append to the buffer, echo it, and detect end-of-line on LF.
INLIN_STORE_CHAR:
        LD A,B
        INC A
        JR NZ,INLIN_APPEND_ECHO
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        POP HL
        LD A,$07
        JR Z,INLIN_15
        LD HL,BUF
        CALL LINGET
        EX DE,HL
        LD (SAVTXT),HL
        JP CRUNCH_EMIT_OVERFLOW
; [RE] append the accepted char C to the buffer, bump the count, echo it; on a literal newline reset the print column ($0B11) and wait for the continuation key.
INLIN_APPEND_ECHO:
        LD A,C
        LD (HL),C
        INC HL
        INC B
INLIN_15:
        CALL OUTCHR
        SUB $0A
        JP NZ,INLIN_GETCH
        LD (L_0B11),A
        LD A,$0D
        CALL OUTCHR
; [RE] after echoing a hard LF, poll the console until a non-null key arrives; CR ends the line, anything else re-enters the dispatcher.
INLIN_WAIT_AFTER_LF:
        CALL INCHR
        OR A
        JR Z,INLIN_WAIT_AFTER_LF
        CP $0D
        JP Z,INLIN_GETCH
        JP INLIN_DISPATCH
; [RE] CR / end-of-line: if in auto-quote ('?') redisplay mode return the editor's prefilled buffer ($0A0D); otherwise terminate the buffer and return the completed line.
INLIN_CR_FINISH:
        LD A,(L_0C93)
        OR A
        JP Z,PRINT_CRLF_IF_COL_1
        XOR A
        LD (HL),A
        LD HL,L_0A0D
        RET
; [RE] INPUT/LINE-INPUT prompt-separator: clear the auto-prompt flag ($0C93); if the next char is ';' set the flag (suppress the trailing '?') and CHRGET past it.
INPUT_PROMPT_SEP:
        PUSH AF
        LD A,$00
        LD (L_0C93),A
        POP AF
        CP $3B
        RET NZ
        LD (L_0C93),A
        JP CHRGET
; [RE] snapshot the current print column ($0B11) into the Tab-expansion base cell (self-modified operand at $719D) so Tab stops align to where the prompt left the cursor.
INLIN_SAVE_COLUMN:
        LD A,(L_0B11)
        LD (INLIN_ERASE_N_COLS_2),A
        RET
; [RE] backspace/Ctrl-H handling: if erasing over a LF redisplay the line; if over a Tab recompute and back up the right number of columns to the previous tab stop; else erase one echoed character.
INLIN_BACKSPACE:
        DEC HL
        LD A,(HL)
        CP $0A
        JR NZ,INLIN_BACKSPACE_3
        PUSH BC
        DEC B
        JR Z,INLIN_BACKSPACE_2
        LD HL,BUF
; [RE] re-echo the buffered line characters from HL for B bytes (used when backspacing past a newline).
INLIN_REDISPLAY_LINE:
        LD A,(HL)
        CALL OUTCHR
        INC HL
        DJNZ INLIN_REDISPLAY_LINE
INLIN_BACKSPACE_2:
        POP BC
        RET
INLIN_BACKSPACE_3:
        CP $09
        JR NZ,INLIN_BACKSPACE_7
        PUSH HL
        PUSH BC
        PUSH DE
        LD D,$00
INLIN_BACKSPACE_4:
        DEC HL
        LD A,(HL)
        CP $09
        JR Z,INLIN_BACKSPACE_6
        CP $0A
        JR Z,INLIN_BACKSPACE_6
        DEC B
        JR Z,INLIN_BACKSPACE_5
        INC D
        JR INLIN_BACKSPACE_4
INLIN_BACKSPACE_5:
        LD A,(INLIN_ERASE_N_COLS_2)
        ADD A,D
        LD D,A
INLIN_BACKSPACE_6:
        LD A,D
        AND $07
        CPL
        ADD A,$09
        CALL INLIN_ERASE_N_COLS
        POP DE
        POP BC
        POP HL
        RET
INLIN_BACKSPACE_7:
        LD A,$01
; [RE] erase A character cells on the console by emitting BS/space/BS B times (visual rubout of B columns).
INLIN_ERASE_N_COLS:
        PUSH BC
        LD B,A
INLIN_ERASE_N_COLS_1:
        LD A,$08
        CALL OUTCHR
        LD A,$20
        CALL OUTCHR
        LD A,$08
        CALL OUTCHR
        DJNZ INLIN_ERASE_N_COLS_1
        POP BC
        RET
INLIN_ERASE_N_COLS_2:
        NOP
; [RE] WHILE statement handler (token $AF): begin a WHILE/WEND loop; records the loop text pointer ($0B4E).
STMT_WHILE:
        LD (L_0B4E),HL
        CALL BLOCK_SCAN_WHILE
        CALL CHRGET
        EX DE,HL
        CALL WHILE_FIND_FRAME
        INC SP
        INC SP
        JR NZ,STMT_WHILE_1
        ADD HL,BC
        LD SP,HL
        LD (SAVSTK),HL
STMT_WHILE_1:
        LD HL,(SAVTXT)
        PUSH HL
        LD HL,(L_0B4E)
        PUSH HL
        PUSH DE
        JR STMT_WEND_1
; [RE] WEND statement handler (token $B0): test the WHILE condition and loop or fall through.
STMT_WEND:
        JP NZ,RAISE_SYNTAX_ERROR
        EX DE,HL
        CALL WHILE_FIND_FRAME
        JP NZ,WEND_NO_WHILE_ERR
        LD SP,HL
        LD (SAVSTK),HL
        EX DE,HL
        LD HL,(SAVTXT)
        LD (L_0C71),HL
        EX DE,HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        LD (SAVTXT),HL
        EX DE,HL
STMT_WEND_1:
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FP_TEST_SIGN
        POP HL
        JR Z,STMT_WEND_2
        LD BC,$00AF
        LD B,C
        PUSH BC
        INC SP
        JP STMT_FOR_7
STMT_WEND_2:
        LD HL,(L_0C71)
        LD (SAVTXT),HL
        POP HL
        POP AF
        POP AF
        JP STMT_FOR_7
; [RE] WHILE/WEND helper: walk the runtime stack frames (skipping FOR entries, marker $82) looking for a matching WHILE frame (marker $AF) whose loop-text pointer matches; returns the frame in HL with Z set on match.
WHILE_FIND_FRAME:
        LD HL,$0004
        ADD HL,SP
WHILE_FIND_FRAME_1:
        LD A,(HL)
        INC HL
        LD BC,$0082
        CP C
        JR NZ,WHILE_FIND_FRAME_2
        LD BC,$0010
        ADD HL,BC
        JR WHILE_FIND_FRAME_1
WHILE_FIND_FRAME_2:
        LD BC,$00AF
        CP C
WHILE_FIND_FRAME_3:
        RET NZ
        PUSH HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD H,B
        LD L,C
        CALL CMP_HL_DE
        POP HL
        LD BC,$0006
        RET Z
        ADD HL,BC
        JR WHILE_FIND_FRAME_1
; [RE] WEND without matching WHILE: raise coded error $1E ('WEND without WHILE') via the error dispatcher at RAISE_ERROR.
WEND_NO_WHILE_ERR:
        LD DE,ERR_WEND_WITHOUT_WHILE
        JP RAISE_ERROR
; [RE] CALL statement handler (token $B1): call an external machine-code routine.
STMT_CALL:
        LD A,$80
        LD (PTRGET_SUBSCRIPT_FLAG),A
        LD A,(HL)
        CP $25
        PUSH AF
        CALL Z,CHRGET
        CALL PTRGET_1+1
        EX (SP),HL
        PUSH HL
        EX DE,HL
        CALL FRMEVL_TEST_TYPE
        CALL FP_ARG_SETUP1
        CALL FN_CINT
        LD (L_0C93),HL
        POP AF
        JP Z,GFX_FN_VPOS_4
        LD C,$20
        CALL CHECK_STACK_ROOM
        POP DE
        LD HL,$FFC0
        ADD HL,SP
        LD SP,HL
        EX DE,HL
        LD C,$20
        DEC HL
        CALL CHRGET
        LD (OPEN_RESUME_TEXT_PTR),HL
        JR Z,STMT_CALL_3
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
STMT_CALL_1:
        PUSH BC
        PUSH DE
        CALL PTRGET_1+1
        EX (SP),HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        EX (SP),HL
        POP DE
        POP BC
        LD A,(HL)
        CP $2C
        JR NZ,STMT_CALL_2
        DEC C
        CALL CHRGET
        JR STMT_CALL_1
STMT_CALL_2:
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        LD (OPEN_RESUME_TEXT_PTR),HL
        LD A,$21
        SUB C
        POP HL
        DEC A
        JR Z,STMT_CALL_3
        POP DE
        DEC A
        JR Z,STMT_CALL_3
        POP BC
        DEC A
        JR Z,STMT_CALL_3
        PUSH BC
        PUSH HL
        LD HL,$0002
        ADD HL,SP
        LD B,H
        LD C,L
        POP HL
STMT_CALL_3:
        PUSH HL
        LD HL,STMT_CALL_4
        EX (SP),HL
        PUSH HL
        LD HL,(L_0C93)
        EX (SP),HL
        RET
STMT_CALL_4:
        LD HL,(SAVSTK)
        LD SP,HL
        LD HL,(OPEN_RESUME_TEXT_PTR)
        JP STMT_FOR_7
; [RE] CHAIN statement handler (token $B4): load and run another program, optionally preserving variables.
STMT_CHAIN:
        XOR A
        LD (CHAIN_PRESERVE_FLAG),A
        LD (L_0C9B),A
        LD A,(HL)
        LD DE,$00BE
        CP E
        JR NZ,STMT_CHAIN_1
        LD (CHAIN_PRESERVE_FLAG),A
        INC HL
STMT_CHAIN_1:
        DEC HL
        CALL CHRGET
        CALL LOAD_OPEN_INPUT
        PUSH HL
        LD HL,$0000
        LD (L_0CA1),HL
        POP HL
        DEC HL
        CALL CHRGET
        JP Z,STMT_CHAIN_5
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CP $2C
        JR Z,STMT_CHAIN_2
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL GETADR
        LD (L_0CA1),HL
        POP HL
        DEC HL
        CALL CHRGET
        JR Z,STMT_CHAIN_5
STMT_CHAIN_2:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        LD DE,$00A6
        CP E
        JR Z,STMT_CHAIN_3
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'L'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'L'                      ; inline char arg consumed by the preceding CALL
        JP Z,CHAIN_SCAN_STRINGS
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CP E
        JP NZ,RAISE_SYNTAX_ERROR
        OR A
STMT_CHAIN_3:
        PUSH AF
        LD (L_0C9B),A
        CALL CHRGET
        CALL SCAN_LINE_RANGE
        PUSH BC
        CALL RENUM_FIXUP_IF_PENDING
        POP BC
        POP DE
        PUSH BC
        LD H,B
        LD L,C
        LD (L_0C9E),HL
        CALL FNDLIN
        JR NC,STMT_CHAIN_4
        LD D,H
        LD E,L
        LD (L_0C9C),HL
        POP HL
        CALL CMP_HL_DE
STMT_CHAIN_4:
        JP NC,ERROR_FC
        POP AF
        JP NZ,CHAIN_SCAN_STRINGS
STMT_CHAIN_5:
        LD HL,(TXTTAB)
        DEC HL
STMT_CHAIN_6:
        INC HL
        LD A,(HL)
        INC HL
        OR (HL)
        JP Z,CHAIN_MARK_VAR_6
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (SAVTXT),HL
        EX DE,HL
STMT_CHAIN_7:
        CALL CHRGET
STMT_CHAIN_8:
        OR A
        JR Z,STMT_CHAIN_6
        CP $3A
        JR Z,STMT_CHAIN_7
        LD DE,$00B3
        CP E
        JR Z,STMT_CHAIN_9
        CALL CHRGET
        CALL STMT_DATA
        DEC HL
        JR STMT_CHAIN_7
STMT_CHAIN_9:
        CALL CHRGET
        JR Z,STMT_CHAIN_8
STMT_CHAIN_10:
        PUSH HL
        LD A,$01
        LD (PTRGET_SUBSCRIPT_FLAG),A
        CALL PTRGET_1+1
        JR Z,CHAIN_MARK_VAR_2
        LD A,B
        OR $80
        LD B,A
        XOR A
        CALL PTRGET_SEARCH_22+1
        LD A,$00
        LD (PTRGET_SUBSCRIPT_FLAG),A
        JR NZ,STMT_CHAIN_11
        LD A,(HL)
        CP $28
        JR NZ,STMT_CHAIN_12
        POP AF
        JR CHAIN_MARK_VAR_4
STMT_CHAIN_11:
        LD A,(HL)
        CP $28
        JP Z,ERROR_FC
STMT_CHAIN_12:
        POP HL
        CALL PTRGET_1+1
STMT_CHAIN_13:
        LD A,D
        OR E
        JR NZ,STMT_CHAIN_15
        LD A,B
        OR $80
        LD B,A
        LD A,(VALTYP)
        LD D,A
        CALL PTRGET_SEARCH
STMT_CHAIN_14:
        LD A,D
        OR E
        JP Z,ERROR_FC
STMT_CHAIN_15:
        PUSH HL
        LD B,D
        LD C,E
        LD HL,CHAIN_MARK_VAR_3
        PUSH HL
; [RE] CHAIN-ALL/COMMON helper: set the high bit (preserve flag) on a named variable so the post-CHAIN cleanup keeps it across the program reload.
CHAIN_MARK_VAR:
        DEC BC
CHAIN_MARK_VAR_1:
        LD A,(BC)
        DEC BC
        OR A
        JP M,CHAIN_MARK_VAR_1
        LD A,(BC)
        OR $80
        LD (BC),A
        RET
CHAIN_MARK_VAR_2:
        LD (PTRGET_SUBSCRIPT_FLAG),A
        LD A,(HL)
        CP $28
        JR NZ,STMT_CHAIN_12
        EX (SP),HL
        DEC BC
        DEC BC
        CALL CHAIN_MARK_VAR
CHAIN_MARK_VAR_3:
        POP HL
        DEC HL
        CALL CHRGET
        JP Z,STMT_CHAIN_8
        CP $28
        JR NZ,CHAIN_MARK_VAR_5
CHAIN_MARK_VAR_4:
        CALL CHRGET
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        JP Z,STMT_CHAIN_8
CHAIN_MARK_VAR_5:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        JP STMT_CHAIN_10
CHAIN_MARK_VAR_6:
        LD HL,(ARYTAB)
        EX DE,HL
        LD HL,(VARTAB)
CHAIN_MARK_VAR_7:
        CALL CMP_HL_DE
        JR Z,CHAIN_SCAN_ARRAYS
        PUSH HL
        LD C,(HL)
        INC HL
        INC HL
        LD A,(HL)
        OR A
        PUSH AF
        AND $7F
        LD (HL),A
        INC HL
        CALL VARTAB_SKIP_ENTRY
        LD B,$00
        ADD HL,BC
        POP AF
        POP BC
        JP M,CHAIN_MARK_VAR_7
        PUSH BC
        CALL CHAIN_COPY_VAR_BLOCK
        LD HL,(ARYTAB)
        ADD HL,DE
        LD (ARYTAB),HL
        EX DE,HL
        POP HL
        JR CHAIN_MARK_VAR_7
; [RE] CHAIN preserve pass: relocate kept simple/array variables, copying their bytes up out of the way (via CMP_HL_DE compare and block move) and adjusting the variable/array area pointers ($0B71/$0B73) so they survive the new program load.
CHAIN_COPY_VAR_BLOCK:
        EX DE,HL
        LD HL,(STREND)
CHAIN_COPY_VAR_BLOCK_1:
        CALL CMP_HL_DE
        LD A,(DE)
        LD (BC),A
        INC DE
        INC BC
        JR NZ,CHAIN_COPY_VAR_BLOCK_1
        LD A,C
        SUB L
        LD E,A
        LD A,B
        SBC A,H
        LD D,A
        DEC DE
        DEC BC
        LD H,B
        LD L,C
        LD (STREND),HL
        RET
; [RE] CHAIN preserve pass over arrays: walk the array table, temporarily clearing each entry's preserve bit, summing sizes (VARTAB_SKIP_ENTRY) and relocating the kept ones.
CHAIN_SCAN_ARRAYS:
        LD HL,(STREND)
        EX DE,HL
CHAIN_COPY_VAR_BLOCK_3:
        CALL CMP_HL_DE
        JR Z,CHAIN_SCAN_STRINGS
        PUSH HL
        INC HL
        INC HL
        LD A,(HL)
        OR A
        PUSH AF
        AND $7F
        LD (HL),A
        INC HL
        CALL VARTAB_SKIP_ENTRY
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        ADD HL,BC
        POP AF
        POP BC
        JP M,CHAIN_COPY_VAR_BLOCK_3
        PUSH BC
        CALL CHAIN_COPY_VAR_BLOCK
        EX DE,HL
        POP HL
        JR CHAIN_COPY_VAR_BLOCK_3
; [RE] CHAIN preserve pass over string variables/arrays: walk simple-variable and array storage ($0B6F/$0B71), freeing/relocating string descriptors (type 3) of kept variables via CHAIN_MOVE_STRING_VAR.
CHAIN_SCAN_STRINGS:
        LD HL,(VARTAB)
CHAIN_COPY_VAR_BLOCK_5:
        EX DE,HL
        LD HL,(ARYTAB)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,CHAIN_COPY_VAR_BLOCK_8
        LD A,(HL)
        INC HL
        INC HL
        INC HL
        PUSH AF
        CALL VARTAB_SKIP_ENTRY
        POP AF
        CP $03
        JR NZ,CHAIN_COPY_VAR_BLOCK_6
        CALL CHAIN_MOVE_STRING_VAR
        XOR A
CHAIN_COPY_VAR_BLOCK_6:
        LD E,A
        LD D,$00
        ADD HL,DE
        JR CHAIN_COPY_VAR_BLOCK_5
CHAIN_COPY_VAR_BLOCK_7:
        POP BC
CHAIN_COPY_VAR_BLOCK_8:
        EX DE,HL
        LD HL,(STREND)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,CHAIN_COMPACT_STRINGS
        LD A,(HL)
        INC HL
        INC HL
        PUSH AF
        INC HL
        CALL VARTAB_SKIP_ENTRY
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        POP AF
        PUSH HL
        ADD HL,BC
        CP $03
        JR NZ,CHAIN_COPY_VAR_BLOCK_7
        LD (L_0B4A),HL
        POP HL
        LD C,(HL)
        LD B,$00
        ADD HL,BC
        ADD HL,BC
        INC HL
CHAIN_COPY_VAR_BLOCK_9:
        EX DE,HL
        LD HL,(L_0B4A)
        EX DE,HL
        CALL CMP_HL_DE
        JR Z,CHAIN_COPY_VAR_BLOCK_8
        LD BC,CHAIN_COPY_VAR_BLOCK_9
        PUSH BC
; [RE] move one kept string's data during CHAIN: if the string lives in program/heap space that the reload will clobber, copy it up into safe string space (STR_BUILD_FROM_DESC/FP_MOVE_LOOP) and rewrite its descriptor pointer.
CHAIN_MOVE_STRING_VAR:
        XOR A
        OR (HL)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        RET Z
        PUSH HL
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        POP HL
        RET C
        PUSH HL
        LD HL,(TXTTAB)
        CALL CMP_HL_DE
        POP HL
        RET NC
        PUSH HL
        DEC HL
        DEC HL
        DEC HL
        PUSH HL
        CALL STR_BUILD_FROM_DESC
        POP HL
        LD B,$03
        CALL FP_MOVE_LOOP
        POP HL
        RET
; [RE] CHAIN string-space compaction: garbage-collect, then slide the preserved string heap (between $0B6F/$0B71/$0B73) to its new base, recording the move delta for descriptor fixups.
CHAIN_COMPACT_STRINGS:
        CALL GARBAG
        LD HL,(STREND)
        LD B,H
        LD C,L
        LD HL,(VARTAB)
        EX DE,HL
        LD HL,(ARYTAB)
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        LD (L_0C65),HL
        LD HL,(FRETOP)
        LD (L_0C95),HL
        CALL STR_COPY_DOWN_NOCHK
        LD H,B
        LD L,C
        DEC HL
        LD (FRETOP),HL
        LD A,(L_0C9B)
        OR A
        JR Z,CHAIN_MOVE_STRING_VAR_2
        LD HL,(L_0C9E)
        LD B,H
        LD C,L
        LD HL,(L_0C9C)
        CALL BLOCK_MOVE_TO_VARTAB
        CALL CHEAD
CHAIN_MOVE_STRING_VAR_2:
        LD A,$01
        LD (CHAIN_BREAK_FLAG),A
        LD A,(CHAIN_PRESERVE_FLAG)
        OR A
        JP NZ,STMT_MERGE_1
        LD A,(MAX_FILE_NUM)
        LD (L_084B),A
        JP LOAD_PROGRAM_2
CHAIN_MOVE_STRING_VAR_3:
        XOR A
        LD (CHAIN_BREAK_FLAG),A
        LD (CHAIN_PRESERVE_FLAG),A
        LD HL,(VARTAB)
        LD B,H
        LD C,L
        LD HL,(L_0C65)
        ADD HL,BC
        LD (ARYTAB),HL
        LD HL,(FRETOP)
        INC HL
        EX DE,HL
        LD HL,(L_0C95)
        LD (FRETOP),HL
CHAIN_MOVE_STRING_VAR_4:
        CALL CMP_HL_DE
        LD A,(DE)
        LD (BC),A
        INC DE
        INC BC
        JR NZ,CHAIN_MOVE_STRING_VAR_4
        DEC BC
        LD H,B
        LD L,C
        LD (STREND),HL
        LD HL,(L_0CA1)
        LD A,H
        OR L
        EX DE,HL
        LD HL,(TXTTAB)
        DEC HL
        JP Z,STMT_FOR_7
        CALL FNDLIN
        JP NC,ERROR_UL
        DEC BC
        LD H,B
        LD L,C
        JP STMT_FOR_7
        DEFB    $C3
        DEFW    STMT_DATA
; ----------------------------------------------------------------------
; STMT_WRITE -- WRITE# / WRITE statement handler (token).
;   In:        HL -> source text after WRITE; C preset $02 (sequential-output mode required).
;   Out:       Each expression in the list emitted to the selected channel (file via PTRFIL, else
;              console) as a comma-separated, quoted-string record terminated by CRLF.
;   Clobbers:  AF, BC, DE, HL; PRTFLG and PTRFIL reset to console at exit.
;   Algorithm: Parse optional '#file,' prefix (PARSE_FILENUM_HASH with required mode=output), then
;              loop over the value list: evaluate each item (FRMEVL_NOPAREN); a string is emitted
;              wrapped in double-quotes, a number is formatted (FOUT) with its leading sign-space
;              stripped; items are separated by emitting ','. WRITE writes the value list with the
;              quoting/comma conventions that INPUT# can read back. The list ends at end-of-line or
;              a separator; then fall into STMT_WRITE_6.
; ----------------------------------------------------------------------
STMT_WRITE:
        LD C,$02
        ; parse optional '#file,' prefix; C=$02 requires the file be open for sequential output
        CALL PARSE_FILENUM_HASH
        DEC HL
        CALL CHRGET
        JR Z,STMT_WRITE_6
; ----------------------------------------------------------------------
; STMT_WRITE_1 -- WRITE# numeric-item branch / list-loop top.
;   In:        HL -> next text item; current channel = PTRFIL.
;   Out:       The numeric value formatted (FOUT) and emitted with its leading blank trimmed.
;   Clobbers:  AF, DE, HL.
;   Algorithm: Evaluate the item; if string type, divert to STMT_WRITE_5 (quoted emit). Otherwise
;              FOUT_2 builds the number's text and SCAN_STR_LITERAL forms a string descriptor for it;
;              the FAC word at $0CB1 then points at that descriptor. The code reads the body pointer,
;              and if the first byte is FOUT's leading-sign space ($20) it shortens the descriptor by
;              one so WRITE emits no leading blank, then STRPRT outputs it.
; ----------------------------------------------------------------------
STMT_WRITE_1:
        CALL FRMEVL_NOPAREN
        PUSH HL
        ; string operand (Z) -> quote-and-emit path; numeric (NZ) -> format-and-emit
        CALL FRMEVL_TEST_TYPE
        JR Z,STMT_WRITE_5
        CALL FOUT_2
        CALL SCAN_STR_LITERAL
        ; [RE] FAC word at $0CB1 -> the FOUT result string descriptor (length byte then body pointer)
        LD HL,(FAC)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD A,(DE)
        ; strip FOUT's leading sign-space so WRITE has no padding before the number
        CP $20
        JR NZ,STMT_WRITE_2
        INC DE
        LD (HL),D
        DEC HL
        LD (HL),E
        DEC HL
        DEC (HL)
; ----------------------------------------------------------------------
; STMT_WRITE_2 -- WRITE# emit formatted numeric text.
;   In:        FAC word $0CB1 points at the (possibly de-padded) number-text descriptor.
;   Out:       Text sent to the current channel via STRPRT.
;   Clobbers:  AF, DE, HL.
;   Algorithm: STRPRT the formatted number, then fall into the separator handler STMT_WRITE_3.
; ----------------------------------------------------------------------
STMT_WRITE_2:
        CALL STRPRT
; ----------------------------------------------------------------------
; STMT_WRITE_3 -- WRITE# inter-item separator / list continuation.
;   In:        Saved text pointer on stack; HL invalid until POP.
;   Out:       On ',' or ';' continues the list emitting a comma; at end-of-line finishes (STMT_WRITE_6).
;   Clobbers:  AF, HL.
;   Algorithm: Restore the text pointer, CHRGET the next token; end-of-line -> STMT_WRITE_6. A ';'
;              behaves like ',' (STMT_WRITE_4); a ',' is required otherwise (SYNCHR ','). WRITE always
;              separates output items with a comma regardless of the source ';'/',' separator.
; ----------------------------------------------------------------------
STMT_WRITE_3:
        POP HL
        DEC HL
        CALL CHRGET
        JR Z,STMT_WRITE_6
        CP $3B
        JR Z,STMT_WRITE_4
        ; require a ',' or ';' between list items (syntax error otherwise)
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        DEC HL
; ----------------------------------------------------------------------
; STMT_WRITE_4 -- WRITE# emit the ',' item separator and loop.
;   In:        HL -> next item text.
;   Out:       ',' sent to the current channel; control returns to STMT_WRITE_1 for the next value.
;   Clobbers:  AF.
;   Algorithm: CHRGET past the separator, OUTCHR a ',' to the channel, jump back to the list top.
; ----------------------------------------------------------------------
STMT_WRITE_4:
        CALL CHRGET
        LD A,$2C
        CALL OUTCHR
        JR STMT_WRITE_1
; ----------------------------------------------------------------------
; STMT_WRITE_5 -- WRITE# string-item branch: emit a quoted string.
;   In:        FAC/temp descriptor holds the string operand.
;   Out:       '"' + string body + '"' sent to the current channel.
;   Clobbers:  AF.
;   Algorithm: OUTCHR an opening double-quote, STRPRT the string body, OUTCHR a closing double-quote,
;              then rejoin the separator handler (STMT_WRITE_3). The surrounding quotes are what let
;              INPUT# re-read a string containing commas/leading spaces verbatim.
; ----------------------------------------------------------------------
STMT_WRITE_5:
        LD A,$22
        CALL OUTCHR
        CALL STRPRT
        LD A,$22
        CALL OUTCHR
        JR STMT_WRITE_3
; ----------------------------------------------------------------------
; STMT_WRITE_6 -- WRITE# end-of-record: terminate and (random files) pad the record.
;   In:        PTRFIL = current-file FCB base (or 0 for console).
;   Out:       For a RANDOM-mode file the remaining bytes of the 128-byte FIELD record are space-filled;
;              then a CRLF is written and PRINT state is reset.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: If PTRFIL is nonzero and FCB.MODE (offset $00) == FCB_MODE_RANDOM ($03), compute how
;              many bytes remain free in the field record (FILE_BUF_REMAIN returns the FIELD position
;              vs buffer base; subtract, then add -2 (LD DE,$FFFE / ADD HL) to reserve the trailing
;              CRLF). If room remains (no carry) fall into STMT_WRITE_7 to blank-fill so the fixed-
;              length random record is fully written; otherwise skip to the CRLF terminator.
; ----------------------------------------------------------------------
STMT_WRITE_6:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR Z,STMT_WRITE_8
        LD A,(HL)
        ; only RANDOM-mode files (FCB.MODE==3) get their fixed-length record space-padded
        CP $03
        JR NZ,STMT_WRITE_8
        ; DE = FIELD current-position ptr, HL = buffer base ptr; the WRITE code then computes bytes still free
        CALL FILE_BUF_REMAIN
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        ; add -2: reserve 2 bytes for the terminating CRLF before padding
        LD DE,$FFFE
        ADD HL,DE
        JR NC,STMT_WRITE_8
; ----------------------------------------------------------------------
; STMT_WRITE_7 -- WRITE# random-record space-pad loop.
;   In:        HL = count of pad bytes to emit (>0).
;   Out:       HL spaces written to the current channel.
;   Clobbers:  AF, HL.
;   Algorithm: OUTCHR a space and decrement HL until zero, filling the remainder of the fixed-length
;              random record so the on-disk record is exactly one CP/M record long.
; ----------------------------------------------------------------------
STMT_WRITE_7:
        LD A,$20
        CALL OUTCHR
        DEC HL
        LD A,H
        OR L
        JR NZ,STMT_WRITE_7
; ----------------------------------------------------------------------
; STMT_WRITE_8 -- WRITE# record terminator / PRINT-state reset epilogue.
;   In:        Saved text pointer on stack.
;   Out:       CRLF written to the channel; PRTFLG and PTRFIL reset to console.
;   Clobbers:  AF, HL.
;   Algorithm: Restore HL, emit CRLF (CRLF), then tail-jump PRINT_RESET_STATE which clears the printer
;              selector PRTFLG ($0838) and the current-file pointer PTRFIL ($0840) back to console.
; ----------------------------------------------------------------------
STMT_WRITE_8:
        POP HL
        CALL CRLF
        JP PRINT_RESET_STATE
; ----------------------------------------------------------------------
; GET_FILENUM_PREFIX_C1 -- enter PARSE_FILENUM_HASH with default/required mode = sequential input ($01).
;   In:        A = current source char; HL -> source text.
;   Out:       Falls into PARSE_FILENUM_HASH with C=$01.
;   Clobbers:  C.
;   Algorithm: Set C=FCB_MODE_SEQ_IN as the required access mode, then fall through. Used by the read
;              side (INPUT#/LINE INPUT#) where the file must be open for input.
; ----------------------------------------------------------------------
GET_FILENUM_PREFIX_C1:
        LD C,$01
; ----------------------------------------------------------------------
; PARSE_FILENUM_HASH -- parse an optional leading '#file,' channel prefix and select that file.
;   In:        A = current char; HL -> source text; C = required access mode (1=input, 2=output).
;   Out:       If '#' present: file resolved, PTRFIL set to its FCB, and a following ',' consumed; if
;              absent, returns immediately leaving the default channel.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: If the next char is not '#' ($23), return (no file prefix). Otherwise FILE_NUM_TO_FCB
;              evaluates the file-number expression and returns the FCB mode byte in A; the required
;              mode C is recovered into E (POP DE) and compared (CP E): a mismatch is allowed only when
;              the actual mode is RANDOM ($03), else raise 'Bad file mode'. Require the trailing ','
;              (SYNCHR) and fall into STORE_CUR_FCB_PTR to record the selection.
; ----------------------------------------------------------------------
PARSE_FILENUM_HASH:
        CP $23
        RET NZ
        PUSH BC
        ; evaluate the file-number expression -> BC=FCB base, A=mode byte
        CALL FILE_NUM_TO_FCB
        POP DE
        CP E
        JR Z,PARSE_FILENUM_HASH_1
        ; a mode mismatch is tolerated only when the file is actually RANDOM; otherwise the open mode is wrong
        CP FCB_MODE_RANDOM
        JP NZ,RAISE_BAD_FILE_MODE
; ----------------------------------------------------------------------
; PARSE_FILENUM_HASH_1 -- consume the ',' after a valid '#file' prefix, then record the channel.
;   In:        BC = resolved FCB base; HL -> char after the file-number expression.
;   Out:       ',' consumed (syntax error if absent); falls into STORE_CUR_FCB_PTR.
;   Clobbers:  AF, DE, HL.
;   Algorithm: SYNCHR a comma separating the file number from the I/O list, then store PTRFIL.
; ----------------------------------------------------------------------
PARSE_FILENUM_HASH_1:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
; ----------------------------------------------------------------------
; STORE_CUR_FCB_PTR -- set the current-file pointer PTRFIL ($0840) = BC (the resolved FCB base).
;   In:        BC = FCB base of the selected file (0 selects console).
;   Out:       PTRFIL := BC; HL preserved (swapped out and back).
;   Clobbers:  DE.
;   Algorithm: Move BC into HL, store to PTRFIL, restore HL. After this the PRINT/INPUT char routers
;              (OUTCHR/GETC) route I/O to this file instead of the console until PTRFIL is recleared.
; ----------------------------------------------------------------------
STORE_CUR_FCB_PTR:
        EX DE,HL
        LD H,B
        LD L,C
        LD (PTRFIL),HL
        EX DE,HL
        RET
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB -- evaluate a file-number expression and resolve it to its FCB base + mode byte.
;   In:        HL -> source text positioned just before the file number (possibly a leading '#').
;   Out:       BC = FCB base for that file; A = FCB mode byte (FCB_MODE_*), flags from OR A;
;              HL advanced past the expression.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: CHRGET, skip an optional '#', FRMEVL the numeric file-number expression, then fall
;              through to coerce it to an integer and index FILTAB. The resolved FCB's mode byte is
;              returned so callers can verify the file is open and in the right mode.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB:
        DEC HL
        CALL CHRGET
        CP $23
        ; skip the '#' if present before evaluating the file number
        CALL Z,CHRGET
        CALL FRMEVL_NOPAREN
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB_NZ -- coerce the evaluated file-number to an integer, then resolve to FCB+mode.
;   In:        FAC holds the file-number value.
;   Out:       BC = FCB base; A = mode byte with flags set (Z => file not open).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: CONINT converts the FAC to a 0..255 integer file number, then falls into
;              FILE_NUM_TO_FCB_A. Callers test Z to detect a closed file.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB_NZ:
        CALL CONINT
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB_A -- given an integer file number in A, resolve FILTAB to the FCB base + mode.
;   In:        A = file number (0..max).
;   Out:       E = file number; BC = FCB base; A = mode byte (Z if 0/closed).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Move A into E and fall into FCB_MODE_BYTE, the shared FILTAB index/lookup.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB_A:
        LD E,A
; ----------------------------------------------------------------------
; FCB_MODE_BYTE -- index FILTAB by file number E to get the FCB base (BC) and its mode byte (A).
;   In:        E = file number; MAX_FILE_NUM ($0870) = highest valid file number (max open files).
;   Out:       BC = FILTAB[E] (FCB base); A = FCB.MODE with flags (Z => closed); HL preserved.
;   Clobbers:  AF, BC, DE.
;   Algorithm: Range-check E against MAX_FILE_NUM (RAISE_BAD_FILE_NUMBER if E exceeds it). FILTAB
;              ($0850) is a packed array of 2-byte little-endian FCB pointers; index by 2*E to fetch
;              BC, then read the FCB's first byte (FCB.MODE) and OR it so Z indicates a closed slot.
; ----------------------------------------------------------------------
FCB_MODE_BYTE:
        LD A,(MAX_FILE_NUM)
        CP E
        JP C,RAISE_BAD_FILE_NUMBER
        LD D,$00
        PUSH HL
        ; FILTAB[file#] is a 2-byte little-endian pointer to that file's FCB; index by 2*E
        LD HL,FILTAB
        ADD HL,DE
        ADD HL,DE
        LD C,(HL)
        INC HL
        LD B,(HL)
        ; FCB.MODE: 0=closed, 1=seq-in, 2=seq-out, 3=random
        LD A,(BC)
        OR A
        POP HL
        RET
; ----------------------------------------------------------------------
; FCB_BUFFER_PTR -- return DE = pointer to the file's data buffer within its FCB, per access mode.
;   In:        E = file number.
;   Out:       DE -> FCB.SEQ_BUF (offset $29) for sequential files, or FCB.RND_BUF ($B2) for random;
;              BC = FCB base; A = mode byte.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: FCB_MODE_BYTE resolves the FCB and mode. Default the buffer offset to FCB.SEQ_BUF; if
;              the mode is RANDOM ($03) use FCB.RND_BUF (the FIELD window) instead, then add the FCB
;              base to form the absolute buffer pointer in DE.
; ----------------------------------------------------------------------
FCB_BUFFER_PTR:
        CALL FCB_MODE_BYTE
        LD HL,FCB.SEQ_BUF
        CP FCB_MODE_RANDOM
        JR NZ,FCB_BUFFER_PTR_1
        LD HL,FCB.RND_BUF
; ----------------------------------------------------------------------
; FCB_BUFFER_PTR_1 -- finalize FCB_BUFFER_PTR: add the FCB base and return the pointer in DE.
;   In:        HL = chosen buffer field offset ($29 or $B2); BC = FCB base.
;   Out:       DE = HL + BC (absolute buffer address).
;   Clobbers:  HL, DE.
;   Algorithm: ADD HL,BC; EX DE,HL.
; ----------------------------------------------------------------------
FCB_BUFFER_PTR_1:
        ADD HL,BC
        EX DE,HL
        RET
; ----------------------------------------------------------------------
; FN_MKI_STR -- MKI$() function (token TOK_MKIS $31): pack a numeric into a 2-byte INT string.
;   In:        Numeric argument already in the FAC (entered via FUNC_DISPATCH_TBL slot $0212).
;   Out:       Returns a 2-byte string whose bytes are the integer image of the argument.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] MISLABEL CORRECTED -- this is MKI$, not LOF(); the real LOF() is FN_LOF_VALUE.
;              FUNC_DISPATCH_TBL slot index = token-1, so $0212/$0214/$0216 = tokens $31/$32/$33 =
;              MKI$/MKS$/MKD$, and the body BUILDS and returns a STRING. A=$02 selects the result
;              width; FRMEVL_APPLY_OP(A&7) coerces the FAC to the matching numeric type via
;              OPERATOR_ROUTINE_TBL (A&7=2 -> FN_CINT). ALLOC_STR_A allocates A bytes of string heap
;              (the heap body pointer lands in DSCTMP.PTR $0B46), FP_ARG_SETUP2 copies the FAC bytes
;              (source FAC $0CB1/$0CAD) into that heap buffer (HL = $0B46 contents = destination),
;              and STR_FN_RETURN_CHAR_1 pushes the result onto the string-temp stack. The leading 01
;              byte at FN_LOF_1 is the LD BC,nn skip-prefix idiom (preserve).
; ----------------------------------------------------------------------
FN_MKI_STR:
        LD A,$02
; ----------------------------------------------------------------------
; FN_MKS_STR -- MKS$() function (token TOK_MKSS $32): pack a numeric into a 4-byte SNG string.
;   In:        Entered at FN_MKS_STR+1 ($0214) with A preset $04; numeric arg in the FAC.
;   Out:       Returns a 4-byte string holding the single-precision image of the argument.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] MISLABEL CORRECTED -- MKS$, not part of LOF. Same path as FN_MKI_STR with width
;              A=$04 so FRMEVL_APPLY_OP(A&7=4) coerces to SNG (-> FN_CSNG) and a 4-byte string is built.
;              The 01 prefix here is the LD BC,nn skip idiom swallowing the 'LD A,$04' on the fall-
;              through path (already documented; preserve).
; ----------------------------------------------------------------------
FN_MKS_STR:
        LD BC,$043E
; ----------------------------------------------------------------------
; FN_MKD_STR -- MKD$() function (token TOK_MKDS $33): pack a numeric into an 8-byte DBL string.
;   In:        Entered at FN_MKD_STR+1 ($0216) with A preset $08; numeric arg in the FAC.
;   Out:       Returns an 8-byte string holding the double-precision image of the argument.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] MISLABEL CORRECTED -- MKD$, the convergence point of the MKI$/MKS$/MKD$ trio.
;              A=$08 -> FRMEVL_APPLY_OP(A&7=0) coerces to DBL (-> FN_CDBL); ALLOC_STR_A(8) reserves the
;              string (body ptr -> DSCTMP.PTR $0B46), FP_ARG_SETUP2 copies the 8 FAC bytes (from the
;              FAC, $0CB1/$0CAD) into the heap buffer at HL=$0B46 contents, and STR_FN_RETURN_CHAR_1
;              returns it as a string temp. The 01 prefix is again the LD BC,nn skip idiom.
; ----------------------------------------------------------------------
FN_MKD_STR:
        LD BC,$083E
        PUSH AF
        ; coerce the FAC to the result numeric type (A&7 indexes OPERATOR_ROUTINE_TBL -> CINT/CSNG/CDBL) before extracting its bytes
        CALL FRMEVL_APPLY_OP
        POP AF
        ; allocate A (2/4/8) bytes of string heap for the packed value; the heap body pointer lands in DSCTMP.PTR ($0B46)
        CALL ALLOC_STR_A
        LD HL,(L_0B46)
        CALL FP_ARG_SETUP2
        JP STR_FN_RETURN_CHAR_1
; ----------------------------------------------------------------------
; FN_CVI -- CVI() function (token TOK_CVI $2A): reinterpret a >=2-byte string's bytes as an integer.
;   In:        String argument's descriptor reached via FUNC_DISPATCH_TBL slot $0204; A preset $01.
;   Out:       FAC = the numeric value formed from the first 2 bytes of the string; VALTYP=INT ($02).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: A holds (min length - 1): $01 for CVI. FRETMP frees/locates the argument string temp;
;              the descriptor's length must EXCEED A (CP (HL) then JP NC,ERROR_FC: error if A >= len),
;              else 'Illegal function call'. Then INC A -> A=2 is written to VALTYP ($0B14) so the value
;              is typed INT, the string's body pointer is loaded into HL, and FP_ARG_SETUP1 moves those
;              bytes into the FAC. CVI is the inverse of MKI$. The 01 byte before LD BC at FN_CVI_1 is
;              the LD BC,nn skip-prefix idiom (preserve).
; ----------------------------------------------------------------------
FN_CVI:
        LD A,$01
; ----------------------------------------------------------------------
; FN_CVS -- CVS() function (token TOK_CVS $2B): reinterpret a >=4-byte string as a single.
;   In:        Entered at FN_CVS+1 ($0206) with A preset $03 (min length-1 = 3).
;   Out:       FAC = single-precision value from the string's first 4 bytes; VALTYP=SNG ($04).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Same body as FN_CVI with width selector $03; INC A -> 4 stored to VALTYP. Inverse of
;              MKS$. The 01 prefix is the LD BC,nn skip idiom over the fall-through 'LD A,$03'.
; ----------------------------------------------------------------------
FN_CVI_1:
        LD BC,$033E
; ----------------------------------------------------------------------
; FN_CVD -- CVD() function (token TOK_CVD $2C): reinterpret a >=8-byte string as a double.
;   In:        Entered at FN_CVD+1 ($0208) with A preset $07 (min length-1 = 7).
;   Out:       FAC = double-precision value from the string's first 8 bytes; VALTYP=DBL ($08).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Convergence body for CVI/CVS/CVD. After the length check, INC A types VALTYP, and
;              FP_ARG_SETUP1 loads the bytes into the FAC. Inverse of MKD$.
; ----------------------------------------------------------------------
FN_CVI_2:
        LD BC,$073E
        PUSH AF
        ; release/locate the argument string temp; HL -> its descriptor (length byte then body ptr)
        CALL FRETMP
        POP AF
        ; string length must EXCEED A (need >=2/4/8 bytes); too short -> Illegal function call
        CP (HL)
        JP NC,ERROR_FC
        INC A
        INC HL
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        ; set VALTYP to the result type (INT=2 / SNG=4 / DBL=8) so the FAC is read with the right width
        LD (VALTYP),A
        JP FP_ARG_SETUP1
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN -- INPUT#/READ# value scanner: parse one numeric/string field from the current file.
;   In:        HL -> the variable being assigned; PTRFIL = current-file FCB (nonzero; the file branch
;              of STMT_READ_4 does JP NZ,here when PTRFIL!=0).
;   Out:       One field parsed from the file stream and assigned; HL advanced.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] This is the file-INPUT scanner, NOT part of CVI -- it sits next to it in file order.
;              FRMEVL_TEST_TYPE sets Z=string/NZ=numeric. Sets BC=STMT_READ_7 (the value-assign
;              finisher) and DE=$2C20 (D=',' E=' '). On NZ (NUMERIC field) it jumps to the scan loop
;              with those delimiters, so a numeric field ends on a comma OR a space. On Z (STRING
;              field) it first does LD E,D (E=','), so a string field's two terminators are both ','
;              -- it ends only at a comma, letting embedded spaces be kept. Joins the common scan loop
;              at INPUT_FILE_SCAN_5.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN:
        CALL FRMEVL_TEST_TYPE
        LD BC,STMT_READ_7
        ; D=',' E=' ': the NUMERIC-field delimiter pair (ends on comma or space). The string path below does LD E,D so a string field ends only on a comma
        LD DE,$2C20
        JR NZ,INPUT_FILE_SCAN_5
        LD E,D
        JR INPUT_FILE_SCAN_5
; ----------------------------------------------------------------------
; LINE_INPUT_FILE -- LINE INPUT# entry: read a whole line (to CR) from the file into a string var.
;   In:        HL -> '#file' text (a '#' was just detected by STMT_LINE, which JP Z,here).
;   Out:       The destination string variable receives the rest of the line up to CR; PTRFIL selected.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] LINE INPUT# path, not CVI. GET_FILENUM_PREFIX_C1 parses '#file,' requiring input
;              mode and sets PTRFIL. PTRGET locates the target string variable; FP_INT_CHECK validates
;              it. Pushes the PRINT_RESET_STATE epilogue and the variable pointer, then sets the scan to
;              'read until CR with no delimiter trimming' (BC=STMT_DATA_4 finisher; D=E=0 = no comma/
;              space delimiter) before joining the scan loop -- so the whole remaining line is captured.
; ----------------------------------------------------------------------
LINE_INPUT_FILE:
        ; parse '#file,' (file must be open for input) and select it via PTRFIL
        CALL GET_FILENUM_PREFIX_C1
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        LD BC,PRINT_RESET_STATE
        PUSH BC
        PUSH DE
        ; use the LINE-INPUT finisher; D=E=0 means no delimiter so the whole line to CR is read
        LD BC,STMT_DATA_4
        XOR A
        LD D,A
        LD E,A
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_5 -- common entry to the INPUT#/LINE-INPUT# field scan loop.
;   In:        A/BC/HL set by the INPUT_FILE_SCAN or LINE_INPUT_FILE setup; D/E = delimiter config.
;   Out:       Saves scan context (AF,BC,HL) and falls into the leading-space skipper.
;   Clobbers:  stack.
;   Algorithm: Push the type/finisher/var context, then fall into INPUT_FILE_SCAN_6 to begin reading
;              characters from the file via GETC_FILE_EOF.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_5:
        PUSH AF
        PUSH BC
        PUSH HL
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_6 -- skip leading spaces before a field.
;   In:        D = leading-blank flag (nonzero when blanks should be skipped).
;   Out:       A = first non-space char; carry from GETC_FILE_EOF signals premature EOF.
;   Clobbers:  AF.
;   Algorithm: GETC_FILE_EOF reads the next file byte; carry -> 'Input past end' error. Loops while the
;              char is a space ($20) and D!=0 (leading blanks are eaten).
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_6:
        ; read next byte from the current file; carry => EOF -> Input past end
        CALL GETC_FILE_EOF
        JP C,RAISE_INPUT_PAST_END
        CP $20
        JR NZ,INPUT_FILE_SCAN_7
        INC D
        DEC D
        JR NZ,INPUT_FILE_SCAN_6
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_7 -- detect a leading quote to start a quoted-string field.
;   In:        A = first significant char of the field; E = the field's primary delimiter.
;   Out:       If a '"' opens a (comma-delimited) string field, arms the quote terminator in D/E and
;              reads the next char; otherwise falls into the unquoted accumulation path.
;   Clobbers:  AF, BC, DE.
;   Algorithm: If A=='"' and E==',' (a string field), arm a quoted string: set D=E=quote so only a
;              closing '"' terminates the body, and GETC_FILE_EOF the first body char (EOF -> finish at
;              INPUT_FILE_FINISH). Else continue to the byte-accumulation loop.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_7:
        ; a leading quote opens a quoted string field (commas/spaces become literal until the closing quote)
        CP $22
        JR NZ,INPUT_FILE_SCAN_8
        LD B,A
        LD A,E
        CP $2C
        LD A,B
        JR NZ,INPUT_FILE_SCAN_8
        LD D,B
        LD E,B
        CALL GETC_FILE_EOF
        JR C,INPUT_FILE_FINISH
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_8 -- initialize the field accumulation buffer.
;   In:        A = current char to begin storing.
;   Out:       HL = BUF (console input buffer reused as the field staging area); B=$FF max-count guard.
;   Clobbers:  HL, B.
;   Algorithm: Point HL at BUF and set B=$FF (the field-length limit counter used by INPUT_BUF_STORE),
;              then fall into the per-character accumulation loop.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_8:
        ; stage the field in BUF; B=$FF caps the field length (INPUT_BUF_STORE counts down)
        LD HL,BUF
        LD B,$FF
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_9 -- per-character field accumulation loop with CR/LF record handling.
;   In:        A = current char; D/E = active terminators; HL -> BUF write cursor; B = remaining room.
;   Out:       Characters stored to BUF until a terminator/EOF; control transfers to the finish path.
;   Clobbers:  AF, BC, HL.
;   Algorithm: [RE] Inside a quoted field (D=='"') jump straight to the store/terminator test. A CR
;              ($0D) goes to the CR/LF separator handler (INPUT_FILE_CR). A bare LF ($0A) not preceded
;              by CR is stored into the field unless the field is comma-delimited (E==','), then the
;              next byte is read and a following CR is examined. Other chars fall to the store-or-stop
;              test (INPUT_FILE_SCAN_10).
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_9:
        LD C,A
        LD A,D
        CP $22
        LD A,C
        JR Z,INPUT_FILE_SCAN_10
        CP $0D
        PUSH HL
        JR Z,INPUT_FILE_CR
        POP HL
        CP $0A
        JR NZ,INPUT_FILE_SCAN_10
        LD C,A
        LD A,E
        CP $2C
        LD A,C
        ; [RE] store this bare LF into the field unless the field is comma-delimited (E==',')
        CALL NZ,INPUT_BUF_STORE
        CALL GETC_FILE_EOF
        JR C,INPUT_FILE_FINISH
        CP $0D
        JR NZ,INPUT_FILE_SCAN_10
        LD A,E
        CP $20
        JR Z,INPUT_FILE_SCAN_11
        CP $2C
        LD A,$0D
        JR Z,INPUT_FILE_SCAN_11
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_10 -- terminator test then store-or-stop for the accumulation loop.
;   In:        A = current char; D/E = the active terminator characters.
;   Out:       On a terminator (NUL/D/E) branches to finish; otherwise stores the char and continues.
;   Clobbers:  AF, HL.
;   Algorithm: A NUL ends the field; if the char equals the D or E delimiter, finish (INPUT_FILE_FINISH);
;              else INPUT_BUF_STORE it and fall into INPUT_FILE_SCAN_11 to fetch the next char.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_10:
        OR A
        JR Z,INPUT_FILE_SCAN_11
        CP D
        JR Z,INPUT_FILE_FINISH
        CP E
        JR Z,INPUT_FILE_FINISH
        CALL INPUT_BUF_STORE
; ----------------------------------------------------------------------
; INPUT_FILE_SCAN_11 -- fetch the next field character and continue the loop.
;   In:        HL -> BUF cursor.
;   Out:       A = next file byte; loops back to INPUT_FILE_SCAN_9 unless EOF.
;   Clobbers:  AF.
;   Algorithm: GETC_FILE_EOF; on carry (EOF) fall into the finish path, else continue scanning.
; ----------------------------------------------------------------------
INPUT_FILE_SCAN_11:
        CALL GETC_FILE_EOF
        JR NC,INPUT_FILE_SCAN_9
; ----------------------------------------------------------------------
; INPUT_FILE_FINISH -- field terminated: consume a trailing delimiter, then convert/assign.
;   In:        A = terminator char; saved scan context on stack.
;   Out:       Cursor positioned past the field's trailing delimiter(s); falls into the converter.
;   Clobbers:  AF, BC, HL.
;   Algorithm: If the field ended on a closing quote ('"') or a space, skip following whitespace via
;              INPUT_FILE_SKIPWS so the next field starts clean; otherwise go straight to the value
;              finalizer (INPUT_FILE_CONVERT).
; ----------------------------------------------------------------------
INPUT_FILE_FINISH:
        PUSH HL
        CP $22
        JR Z,INPUT_FILE_SKIPWS
        CP $20
        JR NZ,INPUT_FILE_CONVERT
; ----------------------------------------------------------------------
; INPUT_FILE_SKIPWS -- skip the inter-field delimiter run (spaces, one comma, optional CRLF).
;   In:        Current file position just after a field body.
;   Out:       File positioned at the start of the next field or at EOF.
;   Clobbers:  AF.
;   Algorithm: GETC_FILE_EOF and fall into INPUT_FILE_SKIPWS_14 to test the byte.
; ----------------------------------------------------------------------
INPUT_FILE_SKIPWS:
        CALL GETC_FILE_EOF
; ----------------------------------------------------------------------
; INPUT_FILE_SKIPWS_14 -- classify the delimiter byte while skipping inter-field whitespace.
;   In:        A = candidate byte (carry => EOF).
;   Out:       Loops on spaces; stops on ',' (consumes it) or CR; otherwise treats as field start.
;   Clobbers:  AF.
;   Algorithm: EOF -> finish. Space ($20) loops (INPUT_FILE_SKIPWS). Comma ($2C) is the field
;              separator -> done (INPUT_FILE_CONVERT). CR ($0D) starts the CRLF handling at
;              INPUT_FILE_CR; any other byte is the next field and is handled at INPUT_FILE_PUSHBACK
;              (re-presents it by bumping the in-buffer counter).
; ----------------------------------------------------------------------
INPUT_FILE_SKIPWS_14:
        JR C,INPUT_FILE_CONVERT
        CP $20
        JR Z,INPUT_FILE_SKIPWS
        CP $2C
        JP Z,INPUT_FILE_CONVERT
        CP $0D
        JR NZ,INPUT_FILE_PUSHBACK
; ----------------------------------------------------------------------
; INPUT_FILE_CR -- handle a CR field separator and swallow a following LF.
;   In:        A = CR; current file position after the CR.
;   Out:       A trailing LF (if present) is consumed; control reaches the value converter.
;   Clobbers:  AF.
;   Algorithm: GETC_FILE_EOF the byte after CR; if it is LF ($0A) consume it (CRLF pair) and finish at
;              INPUT_FILE_CONVERT; EOF here also finishes; a non-LF byte falls into INPUT_FILE_PUSHBACK
;              to be re-presented.
; ----------------------------------------------------------------------
INPUT_FILE_CR:
        CALL GETC_FILE_EOF
        JR C,INPUT_FILE_CONVERT
        CP $0A
        JR Z,INPUT_FILE_CONVERT
; ----------------------------------------------------------------------
; INPUT_FILE_PUSHBACK -- non-delimiter look-ahead byte: re-present it on the next read.
;   In:        PTRFIL = current-file FCB; a non-delimiter byte was read past the field.
;   Out:       FCB.BUF_REM (offset $28) incremented so the over-read byte is re-presented next read.
;   Clobbers:  AF, BC, HL.
;   Algorithm: [RE] BUF_REM is the count of still-unread bytes in the FCB record (GETC_FILE decrements
;              it on each read). One byte was consumed past the field; INC (HL) on PTRFIL+FCB.BUF_REM
;              increases the remaining count by one so the next GETC_FILE re-reads that byte. This is
;              the scanner's one-character look-ahead pushback.
; ----------------------------------------------------------------------
INPUT_FILE_PUSHBACK:
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_REM
        ADD HL,BC
        ; [RE] increment FCB.BUF_REM (remaining-bytes count) so the next read re-presents the look-ahead byte
        INC (HL)
; ----------------------------------------------------------------------
; INPUT_FILE_CONVERT -- terminate the staged field text and dispatch numeric vs string conversion.
;   In:        HL -> end of the field text in BUF; E = delimiter mode (space => numeric path).
;   Out:       Falls into the NUL-terminate + convert step.
;   Clobbers:  HL.
;   Algorithm: Restore the BUF write cursor and fall into INPUT_FILE_CONVERT_18 to NUL-terminate and
;              convert.
; ----------------------------------------------------------------------
INPUT_FILE_CONVERT:
        POP HL
; ----------------------------------------------------------------------
; INPUT_FILE_CONVERT_18 -- NUL-terminate the field and convert it to a string or numeric value.
;   In:        HL -> field end in BUF; E = delimiter mode; B/D scan state.
;   Out:       The variable identified by the saved pointer is assigned the parsed value.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Write a terminating NUL after the field text. If E indicates a numeric field (E==space,
;              so E-$20==0) jump to INPUT_FILE_CONVERT_NUM to run the numeric reader. Otherwise treat
;              the field as a string: SCAN_STR_BODY measures it and builds a string descriptor from BUF,
;              which the caller's READ/INPUT assignment consumes.
; ----------------------------------------------------------------------
INPUT_FILE_CONVERT_18:
        LD (HL),$00
        LD HL,L_0A0D
        LD A,E
        ; E==space ($20) marks a numeric field -> numeric reader; otherwise build a string from BUF
        SUB $20
        JR Z,INPUT_FILE_CONVERT_NUM
        LD B,D
        LD D,$00
        CALL SCAN_STR_BODY
        POP HL
        RET
; ----------------------------------------------------------------------
; INPUT_FILE_CONVERT_NUM -- numeric-field path: parse the staged digits into the FAC.
;   In:        HL -> the field text in BUF (NUL-terminated).
;   Out:       FAC = parsed number (integer-form via FIN_1+1, else general via FIN).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Test the value type, then run the number reader: the carry from CHRGET's first-char
;              classification selects FIN_1+1 (integer form) vs FIN (general numeric). The parsed value
;              becomes the field assigned to the INPUT#/READ target.
; ----------------------------------------------------------------------
INPUT_FILE_CONVERT_NUM:
        CALL FRMEVL_TEST_TYPE
        PUSH AF
        CALL CHRGET
        POP AF
        PUSH AF
        CALL C,FIN_1+1
        POP AF
        CALL NC,FIN
        POP HL
        RET
; ----------------------------------------------------------------------
; INPUT_BUF_STORE -- store one field byte into the staging buffer with an overflow guard.
;   In:        A = byte to store; HL = BUF write cursor; B = remaining room counter.
;   Out:       Byte stored, HL advanced, B decremented; on B underflow the caller's return is popped
;              and the field is force-finished.
;   Clobbers:  AF, BC, HL.
;   Algorithm: A NUL is dropped (RET Z). Otherwise store (HL)<-A, INC HL, DEC B; while B>0 return to
;              the loop. If B hits 0 the field overran its limit, so POP the caller and jump to
;              INPUT_FILE_CONVERT_18 to terminate and convert what was collected.
; ----------------------------------------------------------------------
INPUT_BUF_STORE:
        OR A
        RET Z
        LD (HL),A
        INC HL
        DEC B
        RET NZ
        ; field hit the length limit: discard the loop's return and force-finish the field
        POP BC
        JR INPUT_FILE_CONVERT_18
; ----------------------------------------------------------------------
; LOAD_OPEN_INPUT -- LOAD/MERGE entry: set D=1 (FCB_MODE_SEQ_IN), fall into LOAD_OPEN_CHANNEL0 to open the program file on channel #0 for sequential input.
; ----------------------------------------------------------------------
LOAD_OPEN_INPUT:
        LD D,$01
; ----------------------------------------------------------------------
; LOAD_OPEN_CHANNEL0 -- XOR A selects file #0, JP STMT_OPEN_2 with the mode in D. File #0 is the reserved program-image channel.
; ----------------------------------------------------------------------
LOAD_OPEN_CHANNEL0:
        XOR A
        JP STMT_OPEN_2
; ----------------------------------------------------------------------
; LOAD_PROGRAM -- LOAD/RUN handler: flag-skip ($AF=opcode of XOR A; +1 entry = plain LOAD) sets the run disposition, PUSH AF, open file #0, save MAX_FILE_NUM to L_084B, parse ,R; no ,R -> LOAD_PROGRAM_3+1 (POP AF), ,R -> LOAD_PROGRAM_2.
; ----------------------------------------------------------------------
LOAD_PROGRAM:
        OR $AF
        PUSH AF
        CALL LOAD_OPEN_INPUT
        LD A,(MAX_FILE_NUM)
        LD (L_084B),A
        DEC HL
        CALL CHRGET
        JR Z,LOAD_PROGRAM_3+1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'R'                      ; inline char arg consumed by the preceding CALL
        JP NZ,RAISE_SYNTAX_ERROR
        POP AF
; ----------------------------------------------------------------------
; LOAD_PROGRAM_2 -- the ,R-PRESENT arm: XOR A; LD (MAX_FILE_NUM),A zeroes L_0870 (MAX_FILE_NUM, NOT the run flag); OR $F1 in LOAD_PROGRAM_3 then sets the run flag. The no-,R path skips this routine.
; ----------------------------------------------------------------------
LOAD_PROGRAM_2:
        XOR A
        LD (MAX_FILE_NUM),A
; ----------------------------------------------------------------------
; LOAD_PROGRAM_3 -- store RUN_AFTER_LOAD_FLAG (entered at +1=POP AF on no-,R), FILTAB:=$0080, CLEAR_VARS, restore MAX_FILE_NUM, reload FILTAB[0]/PTRFIL from FILTAB_SLOT0_SEED ([RE] file #0 FCB base $81D1). [RE] SAVTXT guard fires only when SAVTXT==$FFFE, setting $FFFF; intent UNKNOWN.
; ----------------------------------------------------------------------
LOAD_PROGRAM_3:
        OR $F1
        LD (L_084A),A
        LD HL,$0080
        LD (HL),$00
        LD (FILTAB),HL
        CALL CLEAR_VARS
        LD A,(L_084B)
        LD (MAX_FILE_NUM),A
        LD HL,(FILTAB_SLOT0_SEED)
        LD (FILTAB),HL
        LD (PTRFIL),HL
        LD HL,(SAVTXT)
        INC HL
        LD A,H
        AND L
        INC A
        JR NZ,LOAD_PROGRAM_4
        LD (SAVTXT),HL
; ----------------------------------------------------------------------
; LOAD_PROGRAM_4 -- GETC_FILE_EOF the lead byte: empty -> DIRECT_LINE_DISPATCH; $FE -> set LOAD_PROTECT_FLAG (L_0C99) then read; else LOAD_PROGRAM_5.
; ----------------------------------------------------------------------
LOAD_PROGRAM_4:
        CALL GETC_FILE_EOF
        JP C,DIRECT_LINE_DISPATCH
        CP $FE
        JR NZ,LOAD_PROGRAM_5
        LD (L_0C99),A
        JR LOAD_PROGRAM_6
; ----------------------------------------------------------------------
; LOAD_PROGRAM_5 -- INC A; $FF -> binary (fall through); else JP STMT_MERGE_2 (ASCII source).
; ----------------------------------------------------------------------
LOAD_PROGRAM_5:
        INC A
        JP NZ,STMT_MERGE_2
; ----------------------------------------------------------------------
; LOAD_PROGRAM_6 -- FILE_READ_RECORDS reads to TXTTAB, returns end into VARTAB; PROG_SCRAMBLE if protected; CHEAD relinks; save/restore MAX_FILE_NUM around CLEAR_RESET_DATAPTR; then CHAIN -> string-move, RUN_AFTER_LOAD_FLAG clear -> READY, else JP STMT_FOR_7.
; ----------------------------------------------------------------------
LOAD_PROGRAM_6:
        LD HL,(TXTTAB)
        CALL FILE_READ_RECORDS
        LD (VARTAB),HL
        LD A,(L_0C99)
        OR A
        CALL NZ,PROG_SCRAMBLE
        CALL CHEAD
        INC HL
        INC HL
        LD (VARTAB),HL
        LD HL,MAX_FILE_NUM
        LD A,(HL)
        LD (L_084B),A
        LD (HL),$00
        CALL CLEAR_RESET_DATAPTR
        LD A,(L_084B)
        LD (MAX_FILE_NUM),A
        LD A,(CHAIN_BREAK_FLAG)
        OR A
        JP NZ,CHAIN_MOVE_STRING_VAR_3
        LD A,(L_084A)
        OR A
        JP Z,NEWSTT_READY
        JP STMT_FOR_7
; ----------------------------------------------------------------------
; LOAD_CLEANUP_RESET -- PRINT_RESET_STATE clears PRTFLG/PTRFIL (leaves A=0); FILE_CLOSE_ONE with A=0 closes FILE #0; JP RESET_RUN_STATE_1 reloads HL from L_0B54. Tail of SAVE and the MERGE error path.
; ----------------------------------------------------------------------
LOAD_CLEANUP_RESET:
        CALL PRINT_RESET_STATE
        CALL FILE_CLOSE_ONE
        JP RESET_RUN_STATE_1
; ----------------------------------------------------------------------
; RUN_NO_FILENAME -- CLEAR_VARS then JP CHECK_STACK_ROOM_1; STRING_SPACE_ROOM_CHECK jumps here on string overflow.
; ----------------------------------------------------------------------
RUN_NO_FILENAME:
        CALL CLEAR_VARS
        JP CHECK_STACK_ROOM_1
; ----------------------------------------------------------------------
; STMT_MERGE -- POP BC discards the dispatcher return (MERGE jumps into the line dispatcher), open file #0 for input, require end-of-statement. Text-only; shares the LOAD-ASCII path.
; ----------------------------------------------------------------------
STMT_MERGE:
        POP BC
        CALL LOAD_OPEN_INPUT
        DEC HL
        CALL CHRGET
        JR Z,STMT_MERGE_1
        CALL LOAD_CLEANUP_RESET
        JP RAISE_SYNTAX_ERROR
; ----------------------------------------------------------------------
; STMT_MERGE_1 -- zero RUN_AFTER_LOAD_FLAG (MERGE never auto-runs), GETC_FILE_EOF: empty -> DIRECT_LINE_DISPATCH; $FF binary -> RAISE_BAD_FILE_MODE.
; ----------------------------------------------------------------------
STMT_MERGE_1:
        XOR A
        LD (L_084A),A
        CALL GETC_FILE_EOF
        JP C,DIRECT_LINE_DISPATCH
        INC A
        JP Z,RAISE_BAD_FILE_MODE
; ----------------------------------------------------------------------
; STMT_MERGE_2 -- via PTRFIL INC FCB.BUF_REM (remaining-bytes counter, offset $28) so the next GETC re-delivers the consumed byte (ungetc; index = BUF_CNT-BUF_REM), JP DIRECT_LINE_DISPATCH. Shared LOAD-ASCII/MERGE reader.
; ----------------------------------------------------------------------
STMT_MERGE_2:
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_REM
        ADD HL,BC
        INC (HL)
        JP DIRECT_LINE_DISPATCH
; ----------------------------------------------------------------------
; DIRECT_STMT_EXEC -- PTRFIL != 0 -> RAISE_ERROR ERR_DIRECT_STATEMENT_IN_FILE; else restore HL and JP NEWSTT_NEXTLINE_2.
; ----------------------------------------------------------------------
DIRECT_STMT_EXEC:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        LD DE,ERR_DIRECT_STATEMENT_IN_FILE
        JP NZ,RAISE_ERROR
        POP HL
        JP NEWSTT_NEXTLINE_2
; ----------------------------------------------------------------------
; STMT_SAVE -- D=mode 2, open file #0; no suffix -> STMT_SAVE_1 ($FF); ,P -> protected writer (FILE_BUF_REMAIN_BC_1, mislabeled); ,A -> JP STMT_LIST (ASCII).
; ----------------------------------------------------------------------
STMT_SAVE:
        LD D,$02
        CALL LOAD_OPEN_CHANNEL0
        DEC HL
        CALL CHRGET
        JR Z,STMT_SAVE_1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CP $50
        JP Z,SAVE_PROTECTED_PROGRAM
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        JP STMT_LIST
; ----------------------------------------------------------------------
; STMT_SAVE_1 -- RENUM_PATCH_LINEREFS (L_0B56=0) VALIDATES GOTO/GOSUB/THEN line refs ('Undefined line'; NOT a relink); ILLEGAL_DIRECT_CHECK tests LOAD_PROTECT_FLAG (L_0C99) -> ERROR_FC if a protected program is plain-SAVEd; A=$FF, fall into SAVE_WRITE_PROGRAM.
; ----------------------------------------------------------------------
STMT_SAVE_1:
        CALL RENUM_PATCH_LINEREFS
        CALL ILLEGAL_DIRECT_CHECK
        LD A,$FF
; ----------------------------------------------------------------------
; SAVE_WRITE_PROGRAM -- PUTC_FILE the lead byte in A, DE=VARTAB (end), HL=TXTTAB (start), fall into the copy loop. Shared by tokenized ($FF) and protected ($FE) SAVE.
; ----------------------------------------------------------------------
SAVE_WRITE_PROGRAM:
        CALL PUTC_FILE
        LD HL,(VARTAB)
        EX DE,HL
        LD HL,(TXTTAB)
; ----------------------------------------------------------------------
; SAVE_WRITE_PROGRAM_1 -- CMP_HL_DE; equal -> JP LOAD_CLEANUP_RESET (close); else read (HL), advance, preserve DE across PUTC_FILE, write, loop.
; ----------------------------------------------------------------------
SAVE_WRITE_PROGRAM_1:
        CALL CMP_HL_DE
        JP Z,LOAD_CLEANUP_RESET
        LD A,(HL)
        INC HL
        PUSH DE
        CALL PUTC_FILE
        POP DE
        JR SAVE_WRITE_PROGRAM_1
; ----------------------------------------------------------------------
; STMT_CLOSE -- BC=FILE_CLOSE_ONE; dispatcher Z: NZ -> JR STMT_CLOSE_4 (#n list); Z(no args) -> A=MAX_FILE_NUM seeds the count-down close-all loop. Also the A=0 entry from CLOSE_ALL_FILES; LD A,(L_0870) does not change Z.
; ----------------------------------------------------------------------
STMT_CLOSE:
        LD BC,FILE_CLOSE_ONE
        LD A,(MAX_FILE_NUM)
        JR NZ,STMT_CLOSE_4
        PUSH HL
; ----------------------------------------------------------------------
; STMT_CLOSE_1 -- PUSH BC, PUSH AF, stage CLOSE_ALL_LOOP_NEXT as the return, PUSH/RET to FILE_CLOSE_ONE so closing file #A loops back.
; ----------------------------------------------------------------------
STMT_CLOSE_1:
        PUSH BC
        PUSH AF
        LD DE,CLOSE_ALL_LOOP_NEXT
        PUSH DE
        PUSH BC
        RET
; ----------------------------------------------------------------------
; CLOSE_ALL_LOOP_NEXT -- close-all loop tail (executable PUSH/RET target): POP index (AF)+BC, DEC A; JP P -> STMT_CLOSE_1, else POP HL/RET. CODE, not data.
; ----------------------------------------------------------------------
CLOSE_ALL_LOOP_NEXT:
        POP AF
        POP BC
        DEC A
        JP P,STMT_CLOSE_1
        POP HL
        RET
; ----------------------------------------------------------------------
; CLOSE_ONE_THEN_COMMA -- POP BC+text pointer; (HL) != ',' -> RET; on ',' CHRGET past it, fall into STMT_CLOSE_4. PUSH/RET return target, not data.
; ----------------------------------------------------------------------
CLOSE_ONE_THEN_COMMA:
        POP BC
        POP HL
        LD A,(HL)
        CP $2C
        RET NZ
        CALL CHRGET
; ----------------------------------------------------------------------
; STMT_CLOSE_4 -- skip optional '#', GETBYT the file number, swap onto the stack, stage CLOSE_ONE_THEN_COMMA as the return, JP (HL) to FILE_CLOSE_ONE; the comma list continues.
; ----------------------------------------------------------------------
STMT_CLOSE_4:
        PUSH BC
        LD A,(HL)
        CP $23
        CALL Z,CHRGET
        CALL GETBYT
        EX (SP),HL
        PUSH HL
        LD DE,CLOSE_ONE_THEN_COMMA
        PUSH DE
        JP (HL)
; ----------------------------------------------------------------------
; CLOSE_ALL_FILES -- save BC/DE, XOR A, CALL STMT_CLOSE (closes files MAX_FILE_NUM..0), restore BC/DE, return A=0. Invoked by NEW/CLEAR/RUN, SYSTEM, RESET.
; ----------------------------------------------------------------------
CLOSE_ALL_FILES:
        PUSH DE
        PUSH BC
        XOR A
        CALL STMT_CLOSE
        POP BC
        POP DE
        XOR A
        RET
; ----------------------------------------------------------------------
; STMT_FIELD -- FIELD statement (token $B9): bind FIELD string variables to fixed-width windows inside a random file's record buffer.
;   In:        HL = BASIC text cursor just past FIELD; the file/record-buffer FCB is resolved from the '#n' that follows (FILE_NUM_TO_FCB -> BC = FCB base, A = mode byte).
;   Out:       Each named string variable's 3-byte descriptor is rewritten so its body pointer aims at the next slice of FCB.RND_BUF; RET at the comma-less end of the field list.
;   Clobbers:  A,BC,DE,HL; scratch word L_0C93 (the record length, used here as the field-overflow limit) and RND_SECTOR_NUM (running field offset accumulator).
;   Algorithm: Require a mode-3 (random) FCB else 'Bad file mode'. Read the record length from FCB.FLD_BUF_PTR and save it to L_0C93 as the overflow limit; seed the running field offset (RND_SECTOR_NUM) to 0. Then loop (STMT_FIELD_1): each entry is 'width AS strvar' -- read the byte width, PTRGET the string variable, bump the running offset by the width, and if it exceeds the record length raise 'FIELD overflow'; otherwise overwrite the variable's descriptor with {len=width, ptr=RND_BUF + previous_offset} so the variable maps onto that window. Continue while the next char is ','. [RE] FCB.FLD_BUF_PTR is read here as a length/count, not a pointer, despite the include's 'buffer base pointer' name.
; ----------------------------------------------------------------------
STMT_FIELD:
        CALL FILE_NUM_TO_FCB
        JP Z,RAISE_BAD_FILE_NUMBER
        SUB $03
        ; FIELD requires a random (mode 3) file
        JP NZ,RAISE_BAD_FILE_MODE
        EX DE,HL
        LD HL,FCB.FLD_BUF_PTR
        ADD HL,BC
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        ; remember the record length as the field-overflow limit
        LD (L_0C93),HL
        LD HL,$0000
        ; running byte offset of the next field within the buffer = 0
        LD (RND_SECTOR_NUM),HL
        LD A,H
        EX DE,HL
        ; fields are mapped into the random data buffer (the FIELD window)
        LD DE,FCB.RND_BUF
; ----------------------------------------------------------------------
; STMT_FIELD_1 -- FIELD field-list loop body: consume one 'width AS variable' clause and map the variable onto the next buffer slice.
;   In:        BC = FCB base, DE/HL carry the running RND_BUF window pointer and text cursor; loop entry after each field.
;   Out:       On ',' processes the next field then re-enters; on any other char RET (end of FIELD list).
;   Clobbers:  A,BC,DE,HL; updates RND_SECTOR_NUM (cumulative offset) and the target variable's descriptor.
;   Algorithm: If the next text char is not ',' the field list is done -> RET. Otherwise parse the leading byte width (GETBYT_CHRGET), require the 'AS' keyword (SYNCHR 'A','S'), PTRGET the destination string variable, integer-type-check it (FP_INT_CHECK), add the width to the cumulative offset (RND_SECTOR_NUM), range-check the new offset against the record length (L_0C93) raising 'FIELD overflow' on excess, then write the variable's descriptor = {len=width, ptr=RND_BUF+old_offset}.
; ----------------------------------------------------------------------
STMT_FIELD_1:
        EX DE,HL
        ADD HL,BC
        LD B,A
        EX DE,HL
        LD A,(HL)
        ; ',' separates fields; anything else ends the FIELD list
        CP $2C
        RET NZ
        PUSH DE
        PUSH BC
        ; parse this field's byte width
        CALL GETBYT_CHRGET
        PUSH AF
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'S'                      ; inline char arg consumed by the preceding CALL
        ; locate the destination string variable's descriptor
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        POP AF
        POP BC
        EX (SP),HL
        LD C,A
        PUSH DE
        PUSH HL
        LD HL,(RND_SECTOR_NUM)
        LD B,$00
        ADD HL,BC
        LD (RND_SECTOR_NUM),HL
        EX DE,HL
        LD HL,(L_0C93)
        CALL CMP_HL_DE
        ; fields would overrun the record buffer
        JP C,RAISE_FIELD_OVERFLOW
        POP HL
        POP DE
        EX DE,HL
        ; rewrite the variable as a fixed-width window onto the buffer: len=width, ptr=RND_BUF+offset
        LD (HL),C
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        POP HL
        JR STMT_FIELD_1
; ----------------------------------------------------------------------
; STMT_RSET -- RSET statement (token $C3): right-justify a string value into a FIELD buffer variable. LSET (token $C2) enters at STMT_RSET+1 with the swallowed SCF giving the opposite carry.
;   In:        HL = text cursor past RSET/LSET; statement form is 'fieldvar = expr$'. The OR $37 (RSET) vs swallowed $37=SCF (LSET) flag-skip sets carry to distinguish the two; the carry is saved via PUSH AF and read later for pad direction.
;   Out:       The FIELD variable's window is overwritten with the source string, left-justified (LSET) or right-justified (RSET) and space-padded to the field width; RET.
;   Clobbers:  A,BC,DE,HL and the string temporaries/heap.
;   Algorithm: PTRGET the destination FIELD string variable and integer-type-check it; FRMEVL the right-hand string expression (EVAL_EXPR_AFTER_SYNCHR); FRETMP to resolve/free the source string temp leaving HL at its {len, ptr} descriptor. If the source length is 0 branch to STMT_RSET_5 (nothing to copy). [RE] Otherwise, if the source body lives in the movable dynamic string area (DE >= VARTAB and STREND+len > FRETOP) copy it to a fresh string temporary first (FIELD_PAD_SPACES_2 path) so the field move is stable; sources in program text are used directly (STMT_RSET_2). Then compute copy count = min(srclen, fieldwidth); for RSET pre-pad the leading bytes with spaces (NC path), copy the bytes, and for LSET trailing-pad with spaces (STMT_RSET_6).
; ----------------------------------------------------------------------
STMT_RSET:
        OR $37
        PUSH AF
        ; locate the destination FIELD variable (its descriptor = field width + buffer pointer)
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        PUSH DE
        ; evaluate the right-hand '= expr$' source string
        CALL EVAL_EXPR_AFTER_SYNCHR
        POP BC
        EX (SP),HL
        PUSH HL
        PUSH BC
        ; resolve/free the source string temp; HL -> its {len, ptr} descriptor
        CALL FRETMP
        LD B,(HL)
        EX (SP),HL
        LD A,(HL)
        LD C,A
        PUSH BC
        PUSH HL
        PUSH AF
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        OR A
        ; empty source string -> skip the copy, just pad the field
        JP Z,STMT_RSET_5
        LD HL,(TXTTAB)
        CALL CMP_HL_DE
        JR NC,STMT_RSET_2
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        JR C,STMT_RSET_2
        LD E,C
        LD D,$00
        LD HL,(STREND)
        ADD HL,DE
        EX DE,HL
        LD HL,(FRETOP)
        CALL CMP_HL_DE
        ; [RE] source lives in movable string space -> stage it to a fresh temp first
        JP C,FIELD_PAD_SPACES_2
; ----------------------------------------------------------------------
; STMT_RSET_1 -- LSET/RSET: allocate fresh string space for a movable source, copy it in, and rejoin the justify path.
;   In:        Saved source length and descriptor pointers on the stack from STMT_RSET / FIELD_PAD_SPACES_2.
;   Out:       The source string is materialised in newly allocated heap space whose descriptor pointer is patched in; falls into STMT_RSET_2 to perform the justified copy.
;   Clobbers:  A,BC,DE,HL; allocates string heap via GETSPA.
;   Algorithm: GETSPA(C) reserves field-width bytes of string space, FRETMP retires the temporary source descriptor, the new heap pointer is written back into the source descriptor, and control falls through to the descriptor-unpack + copy in STMT_RSET_2.
; ----------------------------------------------------------------------
STMT_RSET_1:
        POP AF
        LD A,C
        ; reserve fresh string space the field copy can safely move into
        CALL GETSPA
        POP HL
        POP BC
        EX (SP),HL
        PUSH DE
        PUSH BC
        CALL FRETMP
        POP BC
        POP DE
        EX (SP),HL
        PUSH BC
        PUSH HL
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        PUSH AF
; ----------------------------------------------------------------------
; STMT_RSET_2 -- LSET/RSET justify core: unpack both descriptors and clamp the copy count.
;   In:        Stacked descriptor pointers for destination (FIELD var) and source string; the saved LSET/RSET carry flag is on the stack.
;   Out:       HL = source body ptr, DE = destination (FIELD-window) body ptr, B = copy count = min(srclen, fieldwidth); falls into STMT_RSET_3.
;   Clobbers:  A,BC,DE,HL.
;   Algorithm: Pop and unpack the two descriptors (each {len/width, ptr}); arrange source ptr in HL and field-window ptr in DE; compare source length (C) with field width (B) and set B = min(srclen, width) as the number of bytes to copy. Fall through to compute the pad count and dispatch the justified move. [RE] The exact register that holds width vs source-length through the stack juggling is not separately verified; the net effect (B = clamped copy count) is.
; ----------------------------------------------------------------------
STMT_RSET_2:
        POP AF
        POP HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        POP BC
        POP HL
        PUSH DE
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        POP DE
        LD A,C
        ; clamp the copy count to the field width
        CP B
        JR NC,STMT_RSET_3
        LD B,A
; ----------------------------------------------------------------------
; STMT_RSET_3 -- compute pad count and perform the RSET right-justify pre-pad.
;   In:        B = bytes-to-copy; the saved LSET/RSET carry flag selects justification.
;   Out:       C = pad count = fieldwidth - copylen; for RSET (NC) the leading C bytes of the field are space-filled; then the byte copy proceeds in STMT_RSET_4.
;   Clobbers:  A,BC,DE.
;   Algorithm: pad = fieldwidth - copylen -> C; restore the saved justify flag; on the RSET branch (CALL NC,FIELD_PAD_SPACES) blank that many leading bytes so the data lands flush-right; INC B to prime the copy loop counter; then enter the copy loop.
; ----------------------------------------------------------------------
STMT_RSET_3:
        ; pad count = field width - bytes to copy
        SUB B
        LD C,A
        POP AF
        ; RSET: blank the leading bytes so the data is right-justified
        CALL NC,FIELD_PAD_SPACES
        INC B
; ----------------------------------------------------------------------
; STMT_RSET_4 -- byte-copy loop: move B bytes from source (HL) into the FIELD window (DE).
;   In:        B = byte count (pre-incremented), HL = source ptr, DE = destination ptr.
;   Out:       B bytes copied; on B reaching 0 branch to STMT_RSET_6 to apply any LSET trailing pad.
;   Clobbers:  A,B,DE,HL.
;   Algorithm: DEC B and test; copy (HL)->(DE), INC both, repeat until B reaches 0.
; ----------------------------------------------------------------------
STMT_RSET_4:
        DEC B
        JR Z,STMT_RSET_6
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        JP STMT_RSET_4
; ----------------------------------------------------------------------
; STMT_RSET_5 -- LSET/RSET empty-source path: discard the staged work frames when the source string has zero length.
;   In:        Reached from STMT_RSET when the source string length is 0 (the OR A / JP Z test).
;   Out:       Five staged work words are dropped; falls into STMT_RSET_6, which space-fills the whole field on the LSET (carry) path.
;   Clobbers:  BC, SP (frame cleanup).
;   Algorithm: Five POP BC instructions unwind the descriptor/length/flag frames pushed by STMT_RSET, then fall through to the common exit where an empty source means the field is fully padded.
; ----------------------------------------------------------------------
STMT_RSET_5:
        ; drop the five staged work words (empty source, nothing to copy)
        POP BC
        POP BC
        POP BC
        POP BC
        POP BC
; ----------------------------------------------------------------------
; STMT_RSET_6 -- LSET/RSET common exit: apply the LSET trailing pad and return.
;   In:        Carry (the saved justify flag) set for LSET, with C = remaining pad count and DE = current field position.
;   Out:       For LSET the unused tail of the field is space-filled; the saved text cursor is restored to HL; RET.
;   Clobbers:  A,C,DE,HL.
;   Algorithm: On carry (LSET) call FIELD_PAD_SPACES to blank the trailing bytes after the copied data; POP HL restores the caller's text cursor; RET.
; ----------------------------------------------------------------------
STMT_RSET_6:
        ; LSET: blank the trailing bytes so the data is left-justified
        CALL C,FIELD_PAD_SPACES
        POP HL
        RET
; ----------------------------------------------------------------------
; FIELD_PAD_SPACES -- fill C bytes at (DE) with ASCII spaces; the LSET/RSET field-blanking primitive.
;   In:        C = byte count, DE = destination pointer.
;   Out:       C bytes set to $20 (space); DE advanced past them; RET when the count reaches 0.
;   Clobbers:  A,C,DE.
;   Algorithm: Load A=$20, INC C, then store-decrement in the FIELD_PAD_SPACES_1 loop until the count is exhausted.
; ----------------------------------------------------------------------
FIELD_PAD_SPACES:
        LD A,$20
        INC C
; ----------------------------------------------------------------------
; FIELD_PAD_SPACES_1 -- inner loop of FIELD_PAD_SPACES: store A (space) at (DE)++ while decrementing C.
;   In:        A = $20, C = remaining count, DE = destination.
;   Out:       RET when C reaches 0.
;   Clobbers:  C,DE.
;   Algorithm: DEC C; RET Z; store A at (DE); INC DE; repeat.
; ----------------------------------------------------------------------
FIELD_PAD_SPACES_1:
        DEC C
        RET Z
        LD (DE),A
        INC DE
        JR FIELD_PAD_SPACES_1
; ----------------------------------------------------------------------
; FIELD_PAD_SPACES_2 -- RSET/LSET movable-source handler: when the source string body lives in the dynamic string area, copy it to a string temporary before the field move.
;   In:        Stacked descriptor/flag frames from STMT_RSET; B = source length.
;   Out:       The source body is staged into a fresh temporary descriptor (when the type discriminator requires it); rejoins via FIELD_PAD_SPACES_3 -> STMT_RSET_1.
;   Clobbers:  A,BC,DE,HL; may allocate via ALLOC_STR_A and stage via PUT_STR_TEMP.
;   Algorithm: Pop the saved flags/pointers; [RE] if a non-zero discriminator is set, ALLOC_STR_A(B) reserves space and PUT_STR_TEMP records the temporary; then re-push the working frames and fall into FIELD_PAD_SPACES_3.
; ----------------------------------------------------------------------
FIELD_PAD_SPACES_2:
        POP AF
        POP HL
        POP BC
        EX (SP),HL
        EX DE,HL
        JR NZ,FIELD_PAD_SPACES_3
        PUSH BC
        LD A,B
        ; copy the movable source to a fresh string temporary so the field move is stable
        CALL ALLOC_STR_A
        CALL PUT_STR_TEMP
        POP BC
; ----------------------------------------------------------------------
; FIELD_PAD_SPACES_3 -- re-stack the working frames and jump back into the RSET allocate/copy path.
;   In:        Working pointers in HL/BC and saved flags around the stack from FIELD_PAD_SPACES_2.
;   Out:       Re-pushes the frames and JP STMT_RSET_1 to finish the justified store.
;   Clobbers:  HL,BC, stack.
;   Algorithm: EX (SP),HL / PUSH BC / PUSH HL / PUSH AF to rebuild the expected frame layout, then JP STMT_RSET_1.
; ----------------------------------------------------------------------
FIELD_PAD_SPACES_3:
        EX (SP),HL
        PUSH BC
        PUSH HL
        PUSH AF
        JP STMT_RSET_1
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR -- INPUT$() function handler (FRMEVL function dispatch on TOK_INPUT at $3450): read exactly N characters from the console or an open file into a string.
;   In:        HL = text cursor at 'INPUT$' call; syntax INPUT$(count [,#filenum]).
;   Out:       FAC holds a string descriptor for the N collected characters (staged via PUT_STR_TEMP); on Ctrl-C from the console it aborts to direct mode.
;   Clobbers:  A,BC,DE,HL; allocates string space; sets the current file via PTRFIL when a file source is given.
;   Algorithm: CHRGET, then require '$' and '(' (SYNCHR), GETBYT the character count. If a ',' follows, CHRGET past it, FILE_NUM_TO_FCB the file number (reject mode 2 = sequential-output as 'Bad file mode'), set it current (STORE_CUR_FCB_PTR) and select the file source (XOR A => Z); else select the console source. Require ')'. Reject count 0 ('Illegal function call'). ALLOC_STR_A reserves count bytes, then FN_INPUT_DOLLAR_2 fills them from either the file (GETC_FILE_EOF) or the pending-key/CONIN console read.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR:
        CALL CHRGET
        CALL SYNCHR
        DEFB    '$'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        ; parse the character count
        CALL GETBYT
        PUSH DE
        LD A,(HL)
        ; ',' introduces an optional '#filenum' source
        CP $2C
        JR NZ,FN_INPUT_DOLLAR_1
        CALL CHRGET
        CALL FILE_NUM_TO_FCB
        CP $02
        ; INPUT$ cannot read from a mode-2 sequential-output file
        JP Z,RAISE_BAD_FILE_MODE
        ; make this file the current input source
        CALL STORE_CUR_FCB_PTR
        XOR A
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_1 -- INPUT$ source-selected join point: require the closing ')' and validate the count.
;   In:        A/flags hold the console-vs-file source selector (Z = file); the count is staged on the stack.
;   Out:       Falls through to the allocate-and-read body; raises 'Illegal function call' if the count is 0.
;   Clobbers:  A,HL, stack.
;   Algorithm: SYNCHR ')', recover the count into L, reject 0 (ERROR_FC), then ALLOC_STR_A the result string and continue into the read loop.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_1:
        PUSH AF
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        POP AF
        EX (SP),HL
        PUSH AF
        LD A,L
        OR A
        ; INPUT$(0) is illegal
        JP Z,ERROR_FC
        PUSH HL
        ; reserve count bytes for the result string
        CALL ALLOC_STR_A
        EX DE,HL
        POP BC
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_2 -- INPUT$ character-collection loop: gather one character per iteration from the selected source.
;   In:        HL = next byte slot in the allocated string, C = remaining count, the source selector saved on the stack (Z = file).
;   Out:       Loops to FN_INPUT_DOLLAR_4 to store each char; on the file source jumps to FN_INPUT_DOLLAR_6.
;   Clobbers:  A,HL,C.
;   Algorithm: Restore the source flag; if file-source (Z) go to FN_INPUT_DOLLAR_6 (GETC_FILE_EOF). Otherwise read the console: take a pending typed-ahead key if any (GET_PENDING_KEY), else CONIN.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_2:
        POP AF
        PUSH AF
        ; file source: read the next file byte instead of the console
        JR Z,FN_INPUT_DOLLAR_6
        ; consume a typed-ahead key if one is pending
        CALL GET_PENDING_KEY
        JR NZ,FN_INPUT_DOLLAR_3
        ; otherwise read a raw character from the console
        CALL CONIN
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_3 -- INPUT$ Ctrl-C test before storing a console character.
;   In:        A = freshly read console character.
;   Out:       On Ctrl-C ($03) abort to direct mode (FN_INPUT_DOLLAR_5); else fall into FN_INPUT_DOLLAR_4 to store the byte.
;   Clobbers:  none beyond the branch.
;   Algorithm: CP $03; JP Z to the break path; otherwise continue to store the byte.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_3:
        CP $03
        JP Z,FN_INPUT_DOLLAR_5
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_4 -- INPUT$ store-and-count: write the character and finish when the count reaches 0.
;   In:        A = character, HL = destination slot, C = remaining count.
;   Out:       When all characters are collected, resets print state (PRINT_RESET_STATE) and stages the string via PUT_STR_TEMP (the function result).
;   Clobbers:  A,HL,C.
;   Algorithm: Store A at (HL), INC HL, DEC C; loop back to FN_INPUT_DOLLAR_2 while C != 0; when done, PRINT_RESET_STATE then JP PUT_STR_TEMP to return the descriptor.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_4:
        LD (HL),A
        INC HL
        DEC C
        JR NZ,FN_INPUT_DOLLAR_2
        POP AF
        CALL PRINT_RESET_STATE
        ; all characters collected -> return the string value
        JP PUT_STR_TEMP
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_5 -- INPUT$ console Ctrl-C abort: drop to direct-command mode.
;   In:        Ctrl-C detected during a console INPUT$.
;   Out:       Stack reset to SAVSTK; control transferred to the direct-mode resume point (never returns).
;   Clobbers:  SP,HL.
;   Algorithm: Reload SP from SAVSTK to discard the pending expression frames, then JP RESUME_AT_DIRECT.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_5:
        LD HL,(SAVSTK)
        LD SP,HL
        JP RESUME_AT_DIRECT
; ----------------------------------------------------------------------
; FN_INPUT_DOLLAR_6 -- INPUT$ file-source character read: fetch one byte from the open file, trapping EOF.
;   In:        The current file (PTRFIL) is the input source; HL/C are the collection cursor/count.
;   Out:       A = next file byte; on EOF raises 'Input past end' (error 62); otherwise rejoins FN_INPUT_DOLLAR_4 to store the byte.
;   Clobbers:  A (and whatever GETC_FILE_EOF touches).
;   Algorithm: CALL GETC_FILE_EOF; on carry (EOF) JP RAISE_INPUT_PAST_END; else JP FN_INPUT_DOLLAR_4 to store the byte.
; ----------------------------------------------------------------------
FN_INPUT_DOLLAR_6:
        ; read the next byte from the file source
        CALL GETC_FILE_EOF
        ; ran off the end of the file
        JP C,RAISE_INPUT_PAST_END
        JP FN_INPUT_DOLLAR_4
; ----------------------------------------------------------------------
; FN_EOF -- EOF() function (token TOK_EOF $2E): test whether the file's input stream is at end.
;   In:        File-number expression in source (FUNC_DISPATCH_TBL slot $020C).
;   Out:       FAC = -1 (true) at end-of-file, 0 (false) otherwise.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Resolve the file number to its FCB; 'Bad file number' if closed, 'Bad file mode' if the
;              file is open for output (mode $02). Then fall into FN_EOF_1 to inspect the read buffer.
; ----------------------------------------------------------------------
FN_EOF:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        ; EOF is meaningless on a sequential-output file -> Bad file mode
        CP $02
        JP Z,RAISE_BAD_FILE_MODE
; ----------------------------------------------------------------------
; FN_EOF_1 -- EOF core: determine end-of-file by examining/refilling the file buffer.
;   In:        BC = FCB base.
;   Out:       Result truth value computed and tail-jumped to INT16_TO_FP (A entering FN_EOF_3:
;              $00 => not-EOF, otherwise => EOF).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Read FCB.BUF_CNT (offset $27, record fill level). If 0 the buffer is empty => EOF
;              (FN_EOF_3 with A=0). [RE] Otherwise, if the file is RANDOM (FCB.MODE $03) it jumps to
;              FN_EOF_3 carrying A=$03, which maps to NOT-EOF (false) -- EOF on a buffered random file
;              reports false here. Else check FCB.BUF_REM (offset $28): if bytes remain, go to FN_EOF_2
;              to look for a Ctrl-Z; if the buffer is exhausted (BUF_REM 0) but the status byte allows,
;              read the next record (FILE_READ_RECORD_FCB) and retry. This look-ahead lets sequential
;              EOF report true exactly when only the $1A marker / nothing remains.
; ----------------------------------------------------------------------
FN_EOF_1:
        ; FCB.BUF_CNT ($27): how many bytes the current record holds; 0 => buffer empty => EOF
        LD HL,FCB.BUF_CNT
        ADD HL,BC
        LD A,(HL)
        OR A
        JR Z,FN_EOF_3
        LD A,(BC)
        CP $03
        JR Z,FN_EOF_3
        INC HL
        LD A,(HL)
        OR A
        JR NZ,FN_EOF_2
        PUSH BC
        LD H,B
        LD L,C
        ; buffer drained: read the next sequential record into the FCB buffer and re-test
        CALL FILE_READ_RECORD_FCB
        POP BC
        JR FN_EOF_1
; ----------------------------------------------------------------------
; FN_EOF_2 -- EOF: test for the Ctrl-Z ($1A) text end-of-file marker at the buffer's next byte.
;   In:        HL at FCB.BUF_REM ($28); FCB buffer holds the current record.
;   Out:       A = 0 if the next unread byte is the $1A EOF mark, nonzero otherwise.
;   Clobbers:  AF, BC, HL.
;   Algorithm: Compute the position of the next unread byte within the 128-byte record as
;              ($80 - BUF_REM), index into SEQ_BUF, load that byte and SUB $1A so a $1A (Ctrl-Z, CP/M
;              text EOF) yields zero. Fall into FN_EOF_3 to turn the test into the BASIC truth value.
; ----------------------------------------------------------------------
FN_EOF_2:
        LD A,$80
        SUB (HL)
        LD C,A
        LD B,$00
        ADD HL,BC
        INC HL
        LD A,(HL)
        ; $1A = Ctrl-Z, the CP/M soft end-of-file marker for text files
        SUB $1A
; ----------------------------------------------------------------------
; FN_EOF_3 -- EOF: convert the at-end test into a BASIC boolean and return it as a number.
;   In:        A = 0 when at end-of-file, nonzero otherwise (from the buffer/marker tests above).
;   Out:       FAC = -1 (true) or 0 (false) via INT16_TO_FP.
;   Clobbers:  AF, HL.
;   Algorithm: SUB $01 / SBC A,A maps A==0 -> $FF (true) and A!=0 -> $00 (false), then INT16_TO_FP
;              sign-extends A into a 16-bit integer FAC (the BASIC TRUE/FALSE convention).
; ----------------------------------------------------------------------
FN_EOF_3:
        SUB $01
        SBC A,A
        JP INT16_TO_FP
; ----------------------------------------------------------------------
; FILE_FLUSH_RECORD -- flush the current output record to disk, then advance the record number
;   In:        BC = FCB base of the open output file
;   Out:       FCB.SEQ_RECNO incremented; record written via BDOS
;   Clobbers:  A, DE, HL, flags
;   Algorithm: Sets DE = &FCB.CPM (BC+1) for the BDOS call, then falls into
;              FILE_FLUSH_RECORD_CK which clears BUF_CNT, points the CP/M DMA at the
;              record buffer, issues the BDOS record-write (function code held in
;              BDOS_FN_RECWRITE -- random-write $22 on CP/M 2.x / sequential-write
;              $15 on 1.x, selected at cold start), maps the result to a BASIC error,
;              and bumps SEQ_RECNO.
; ----------------------------------------------------------------------
FILE_FLUSH_RECORD:
        LD D,B
        LD E,C
        ; DE = &FCB.CPM (FCB base + 1) -- the pointer every BDOS file call expects
        INC DE
; ----------------------------------------------------------------------
; FILE_FLUSH_RECORD_CK -- write one 128-byte record to disk and translate the BDOS result
;   In:        BC = FCB base; DE = &FCB.CPM (BC+1)
;   Out:       record written; on the disk-full code the file is closed and DISK FULL is raised
;   Clobbers:  A, HL, BC/DE (BC popped back in the success tail), flags
;   Algorithm: Zeroes FCB.BUF_CNT (record now empty), sets the CP/M DMA to the
;              record buffer, then issues the record write through BDOS_FILE_CALL
;              using the cold-start-selected function code BDOS_FN_RECWRITE. Decodes
;              BDOS_FILE_CALL's (already-partially-translated) return: $FF -> too many
;              files; $01 -> disk I/O error; $02 -> zero the MODE byte, BDOS-close the
;              FCB, and raise DISK FULL; any other value -> the success tail
;              FILE_FLUSH_RECORD_CK_1.
;   [RE] Several BDOS result codes are pre-mapped inside BDOS_FILE_CALL on the 2.x
;   random-write path, so the $FF/$01/$02 split here is this routine's view of the
;   already-translated code, not the raw BDOS return.
; ----------------------------------------------------------------------
FILE_FLUSH_RECORD_CK:
        LD HL,FCB.BUF_CNT
        ADD HL,BC
        PUSH BC
        ; disk full: zero the MODE byte (FCB base) so the slot reads as closed
        XOR A
        ; reset BUF_CNT = 0: the record buffer is now considered empty
        LD (HL),A
        ; aim the CP/M DMA at this file's 128-byte record buffer before the write
        CALL BDOS_SET_DMA_FCB
        ; load the write function code chosen at startup (random-write on 2.x, seq-write on 1.x)
        LD A,(BDOS_FN_RECWRITE)
        CALL BDOS_FILE_CALL
        ; [RE] $FF -> too many open files
        CP $FF
        JP Z,RAISE_TOO_MANY_FILES
        DEC A
        ; translated code $01 = disk I/O error
        JP Z,RAISE_DISK_I_O_ERROR
        DEC A
        JP NZ,FILE_FLUSH_RECORD_CK_1
        POP DE
        XOR A
        LD (DE),A
        ; BDOS Close-File on the FCB before raising DISK FULL
        LD C,F_CLOSE
        INC DE
        CALL BDOS
        JP RAISE_DISK_FULL
; ----------------------------------------------------------------------
; FILE_FLUSH_RECORD_CK_1 -- success tail of the record write: bump the sequential record number
;   In:        A = (translated) BDOS result, already known to be neither $FF/$01/$02; BC = FCB base (on stack, popped here)
;   Out:       FCB.SEQ_RECNO incremented by 1
;   Clobbers:  A, BC, DE, HL, flags
;   Algorithm: Loads the 16-bit SEQ_RECNO from the FCB, increments it, and stores it
;              back so the next write targets the following record.
;   [RE] The leading INC A / JP Z,RAISE_TOO_MANY_FILES is a redundant guard: the
;   only path here is the JP NZ for result != $02, and result $01 (which INC A would
;   catch) was already diverted to RAISE_DISK_I_O_ERROR upstream, so it never fires
;   under the current decode (likely a vestige of generic BDOS-result handling).
; ----------------------------------------------------------------------
FILE_FLUSH_RECORD_CK_1:
        INC A
        JP Z,RAISE_TOO_MANY_FILES
        POP BC
        ; advance the 16-bit sequential record counter for the next write
        LD HL,FCB.SEQ_RECNO
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC DE
        LD (HL),D
        DEC HL
        LD (HL),E
        RET
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE -- close one open file: pad/flush, BDOS close, and clear the FCB slot
;   In:        E = file number (from the caller via FILE_NUM_TO_FCB_A, which also sets BC = FCB base)
;   Out:       file closed on disk; the FCB header ($29 bytes) zeroed (MODE back to closed)
;   Clobbers:  A, BC, DE, HL, flags
;   Algorithm: Resolves the file number to its FCB; if already closed (MODE=0) jumps
;              straight to the slot-clear. For a sequential-output file (MODE=2) it
;              appends a trailing Ctrl-Z/EOF byte (via the PUTC_FILE_1 path) and
;              flushes the final partial record, then issues BDOS F_CLOSE, and finally
;              zeroes the FCB header so the slot reads as closed.
;   [RE] When MODE=2 AND the file number is 0 (the program / LOAD-SAVE channel) it
;   first zeroes the MODE byte before padding -- exact reason for the file#0
;   special-case is UNKNOWN.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE:
        ; resolve file number -> BC=FCB base, A=MODE byte; Z if the slot is already closed
        CALL FILE_NUM_TO_FCB_A
        JR Z,FILE_CLOSE_ONE_4
        LD L,E
        PUSH BC
        LD A,(BC)
        LD D,B
        LD E,C
        INC DE
        PUSH DE
        ; only sequential-output files (MODE=2) need the Ctrl-Z pad and final-record flush
        CP $02
        JR NZ,FILE_CLOSE_ONE_3
        INC L
        DEC L
        JR NZ,FILE_CLOSE_ONE_1
        XOR A
        LD (BC),A
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE_1 -- emit the trailing Ctrl-Z EOF marker into the output buffer
;   In:        BC = FCB base of the sequential-output file
;   Out:       Ctrl-Z ($1A) appended to the buffer (record flushed first if it filled)
;   Clobbers:  A, BC, DE, HL, flags; returns into FILE_CLOSE_ONE_2
;   Algorithm: Pushes the return address FILE_CLOSE_ONE_2 twice (PUTC_FILE_1's tail
;              does POP HL/RET, so the first copy satisfies its saved-HL POP and the
;              second is the actual return), sets HL = FCB base, A = $1A, and jumps
;              into PUTC_FILE_1 to append the EOF byte through the buffered-write path.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE_1:
        LD HL,FILE_CLOSE_ONE_2
        PUSH HL
        PUSH HL
        LD H,B
        LD L,C
        ; A = Ctrl-Z (CP/M text EOF); append it via the buffered PUTC path
        LD A,$1A
        JR PUTC_FILE_1
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE_2 -- after EOF byte: flush the final partial record if non-empty
;   In:        BC = FCB base
;   Out:       any buffered bytes written to disk
;   Clobbers:  A, HL, DE, flags; falls into FILE_CLOSE_ONE_3
;   Algorithm: Reads FCB.BUF_CNT; if non-zero (a partly-filled record remains) calls
;              FILE_FLUSH_RECORD_CK to write it, then falls through to the BDOS close.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE_2:
        LD HL,FCB.BUF_CNT
        ADD HL,BC
        LD A,(HL)
        OR A
        ; flush the last partial record only if it holds data
        CALL NZ,FILE_FLUSH_RECORD_CK
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE_3 -- issue BDOS Close-File on the FCB
;   In:        FCB+1 (&FCB.CPM) saved on the stack; FCB base also on the stack
;   Out:       file directory entry committed by the BDOS; BC = FCB base recovered
;   Clobbers:  A, BC, DE, HL, flags; falls into FILE_CLOSE_ONE_4
;   Algorithm: Pops DE = &FCB.CPM, sets the DMA via BDOS_SET_DMA_FCB (carried over;
;              F_CLOSE itself does not use the DMA), then calls BDOS F_CLOSE ($10) to
;              commit the directory entry, and pops BC = FCB base for the slot-clear.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE_3:
        POP DE
        CALL BDOS_SET_DMA_FCB
        ; BDOS Close-File: commit the directory entry to disk
        LD C,F_CLOSE
        CALL BDOS
        POP BC
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE_4 -- prepare to wipe the FCB header
;   In:        BC = FCB base
;   Out:       D = $29 (byte count to clear), A = 0
;   Clobbers:  A, D; falls into FILE_CLOSE_ONE_5
;   Algorithm: Loads the clear length D = $29 (offsets $00..$28: MODE + 36-byte CP/M
;              FCB + SEQ_RECNO + BUF_CNT + BUF_REM, i.e. everything before SEQ_BUF) and
;              A = 0 fill byte.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE_4:
        ; $29 bytes = the FCB header (MODE + CP/M FCB + SEQ_RECNO + BUF_CNT/BUF_REM), i.e. through the byte before SEQ_BUF ($29)
        LD D,$29
        XOR A
; ----------------------------------------------------------------------
; FILE_CLOSE_ONE_5 -- zero-fill loop that clears the FCB header
;   In:        BC = FCB base; D = byte count; A = 0
;   Out:       D bytes from FCB base cleared to 0 (MODE=0 -> slot reads as closed)
;   Clobbers:  BC (advanced), D (to 0), flags
;   Algorithm: Stores A=0 into (BC), increments BC, decrements D, loops until D=0,
;              then returns.
; ----------------------------------------------------------------------
FILE_CLOSE_ONE_5:
        LD (BC),A
        INC BC
        DEC D
        JR NZ,FILE_CLOSE_ONE_5
        RET
; ----------------------------------------------------------------------
; FN_LOC_VALUE -- LOC() function (token TOK_LOC $2F): current record/position number of a file.
;   In:        File-number expression in source (FUNC_DISPATCH_TBL slot $020E).
;   Out:       FAC = the file's current 16-bit record number.
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: Resolve the file number to its FCB ('Bad file number' if closed). Select the record-
;              number field by mode: random (mode $03) uses FCB.RND_RECNO ($AD), sequential uses
;              FCB.SEQ_RECNO ($25). It points HL at the field's HIGH byte (+1) and falls into
;              FN_LOC_VALUE_1, which assembles the FULL 16-bit value into the FAC (not just the high
;              byte).
; ----------------------------------------------------------------------
FN_LOC_VALUE:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        ; random files report RND_RECNO ($AD); sequential files report SEQ_RECNO ($25)
        CP $03
        LD HL,FCB.SEQ_RECNO+1
        JR NZ,FN_LOC_VALUE_1
        LD HL,FCB.RND_RECNO+1
; ----------------------------------------------------------------------
; FN_LOC_VALUE_1 -- LOC() tail: load the selected 16-bit record number into the FAC.
;   In:        HL = FCB-relative high-byte address of the chosen record-number field; BC = FCB base.
;   Out:       FAC = the 16-bit record number (loaded via FP_LOAD_INT_TO_FAC_1).
;   Clobbers:  AF, HL.
;   Algorithm: ADD HL,BC to make it absolute, read the high byte (A) then DEC HL and read the low byte
;              (L), so HL=record number; FP_LOAD_INT_TO_FAC_1 (LD H,A) stores it as an integer in the FAC.
; ----------------------------------------------------------------------
FN_LOC_VALUE_1:
        ADD HL,BC
        LD A,(HL)
        DEC HL
        LD L,(HL)
        JP FP_LOAD_INT_TO_FAC_1
; ----------------------------------------------------------------------
; FN_LOF_VALUE -- LOF() function (token TOK_LOF $30): length of the open file, in CP/M records.
;   In:        File-number expression in source (FUNC_DISPATCH_TBL slot $0210).
;   Out:       FAC = the record count from the FCB's current extent (0..128).
;   Clobbers:  AF, BC, DE, HL.
;   Algorithm: [RE] This is the REAL LOF(); the similarly named FN_LOF/_1/_2 above are actually MKI$/
;              MKS$/MKD$. Resolve the file number to its FCB ('Bad file number' if closed), read the
;              single byte FCB.CPM.RC (offset $0F, record count in the current extent) and return it as
;              a number via FP_LOAD_INT_TO_FAC (8-bit, high byte 0). [RE] this reports the size of the
;              current extent, not necessarily the whole multi-extent file -- consistent with CP/M's RC
;              field semantics.
; ----------------------------------------------------------------------
FN_LOF_VALUE:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        ; FCB.CPM.RC ($0F): record count in the current extent = file length in 128-byte records
        LD HL,FCB.CPM.RC
        ADD HL,BC
        LD A,(HL)
        JP FP_LOAD_INT_TO_FAC
; ----------------------------------------------------------------------
; PUTC_FILE_RESUME -- restore caller context and fall into the file-byte writer.
;   In:        Two saved words on the stack: AF (the char) and HL, pushed by OUTCHR before it
;              jumped here (OUTCHR does JP NZ,here when PTRFIL!=0).
;   Out:       Restores HL and AF, then falls into PUTC_FILE to emit the byte to the current file.
;   Clobbers:  AF, HL.
;   Algorithm: [RE] Despite the FN_LOF_VALUE_1 name this is part of the file-output character path, not
;              LOF. OUTCHR (PUSH AF/PUSH HL, then detects PTRFIL!=0) jumps here; this POPs HL and AF so
;              PUTC_FILE can buffer the byte and flush full records. Naming-only mismatch (it shares
;              the address region with the LOF code).
; ----------------------------------------------------------------------
PUTC_FILE_RESUME:
        POP HL
        POP AF
; ----------------------------------------------------------------------
; PUTC_FILE -- write one byte to the open file, dispatching on file mode
;   In:        A = byte to write; PTRFIL ($0840) = current file's FCB base
;   Out:       byte routed to the sequential buffer, or to the random/FIELD-store path
;   Clobbers:  A, HL, flags (the saved A/HL are popped per path)
;   Algorithm: Pushes HL and A, reads the current file's MODE byte. MODE=1 (seq
;              input) -> STMT_ERASE_3, which simply pops the saved A/HL and RETs to the
;              caller (the byte is discarded -- this is NOT an error raise). MODE=3
;              (random) -> BLOCK_COPY_BC_2, the FIELD-buffer store path. Otherwise (seq
;              output, MODE=2) it pops A and falls into PUTC_FILE_1 to append the byte.
;   [RE] Writing to a MODE=1 (input) file is silently a no-op here; if BASIC reports
;   a 'bad file mode' it must do so elsewhere -- UNKNOWN whether any error surfaces.
; ----------------------------------------------------------------------
PUTC_FILE:
        PUSH HL
        PUSH AF
        ; HL = current file's FCB base; (HL) = its MODE byte
        LD HL,(PTRFIL)
        LD A,(HL)
        CP $01
        ; MODE=1 (sequential input): pop saved A/HL and return to caller -- the byte is discarded
        JP Z,STMT_ERASE_3
        CP $03
        ; MODE=3 (random): divert to the FIELD-buffer store path
        JP Z,PUTC_FILE_RANDOM
        POP AF
; ----------------------------------------------------------------------
; PUTC_FILE_1 -- append one byte to the sequential output record buffer
;   In:        A = byte; HL = FCB base; (an extra saved HL is on the stack per the caller contract)
;   Out:       byte stored into SEQ_BUF at the current fill offset; record flushed first if it was full
;   Clobbers:  A, BC, DE, HL, flags (the byte and a saved HL are consumed)
;   Algorithm: If FCB.BUF_CNT == $80 the 128-byte record is full, so it calls
;              FILE_FLUSH_RECORD to write it and reset the count; then it increments
;              BUF_CNT to claim the next slot and computes BC = new BUF_CNT. It also
;              maintains FCB.BUF_REM ($28) as a per-file output column counter: a CR
;              byte ($0D) resets it to 0, otherwise it adds 1 for a printable byte
;              (>= $20). Finally it stores the byte into the buffer via PUTC_FILE_2.
;   [RE] BUF_REM ($28) is dual-use: a per-file print-column counter on the write
;   path (here) and the remaining-bytes/EOF status on the read path. Its exact role
;   in PRINT# TAB/comma-zone alignment is inferred, not verified.
; ----------------------------------------------------------------------
PUTC_FILE_1:
        PUSH DE
        PUSH BC
        LD B,H
        LD C,L
        PUSH AF
        LD DE,FCB.BUF_CNT
        ADD HL,DE
        LD A,(HL)
        ; BUF_CNT == 128: the record is full, flush it before adding more
        CP $80
        PUSH HL
        ; write the full record and reset the fill count
        CALL Z,FILE_FLUSH_RECORD
        POP HL
        ; claim the next buffer slot: BUF_CNT++
        INC (HL)
        LD C,(HL)
        LD B,$00
        INC HL
        POP AF
        PUSH AF
        LD D,(HL)
        ; [RE] CR resets the per-file output column counter (FCB.BUF_REM); other printable bytes increment it
        CP $0D
        LD (HL),B
        JR Z,PUTC_FILE_2
        ADD A,$E0
        LD A,D
        ADC A,B
        LD (HL),A
; ----------------------------------------------------------------------
; PUTC_FILE_2 -- store the byte at the computed buffer offset and restore state
;   In:        HL = FCB+$28 (one before SEQ_BUF); BC = new BUF_CNT; saved A/BC/DE/HL on stack
;   Out:       byte written into SEQ_BUF at the just-claimed slot
;   Clobbers:  HL; restores A, BC, DE, HL from the stack
;   Algorithm: Adds BC (new BUF_CNT) to HL so HL = FCB+$28+BUF_CNT = &SEQ_BUF[BUF_CNT-1],
;              pops the saved byte and registers, writes the byte, and returns.
; ----------------------------------------------------------------------
PUTC_FILE_2:
        ; HL = FCB+$28 + BUF_CNT -> the SEQ_BUF slot for this byte
        ADD HL,BC
        POP AF
        POP BC
        POP DE
        LD (HL),A
        POP HL
        RET
; ----------------------------------------------------------------------
; PUTC_FILE_3 -- random GET/PUT: position the CP/M record from SEQ_RECNO, then read or flush
;   In:        HL = &FCB.SEQ_RECNO+1; DE = record number; FCB base reachable via the stacked caller frame
;   Out:       SEQ_RECNO and FCB.CPM.R0/R1/R2 set from the (decremented) record number; record read or flushed
;   Clobbers:  A, BC, DE, HL, flags
;   Algorithm: Decrements the 16-bit record number (DE), stores it back into
;              SEQ_RECNO, and marks the buffer full by writing $80 into both BUF_CNT
;              and BUF_REM. Recovers BC = FCB base and copies the record number into
;              the CP/M random-record fields R0 (low), R1 (high), R2=0 so a random
;              BDOS call addresses that record. Then on FIELD_WRITE_FLAG (L_084C): if
;              clear (GET / read-modify) it refills the record via FILE_READ_RECORD_FCB;
;              if set (PUT) it falls to PUTC_FILE_4 to flush via FILE_FLUSH_RECORD and
;              reset the print state.
;   [RE] This is the bridge that lets random GET/PUT reuse the sequential buffer
;   engine: it positions by record number through R0/R1/R2.
; ----------------------------------------------------------------------
PUTC_FILE_3:
        DEC DE
        DEC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        ; mark the buffer full: BUF_CNT = BUF_REM = $80 before positioning the record
        LD (HL),$80
        INC HL
        LD (HL),$80
        POP HL
        EX (SP),HL
        LD B,H
        LD C,L
        PUSH HL
        ; copy the BASIC record number into the CP/M random-record fields R0/R1, R2=0
        LD HL,FCB.CPM.R0
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD (HL),$00
        POP HL
        ; FIELD write-flag: 0 = GET/read-modify (refill record), nonzero = PUT (flush record)
        LD A,(FIELD_WRITE_FLAG)
        OR A
        JR NZ,PUTC_FILE_4
        ; GET / read-before-write: load the existing record into the buffer
        CALL FILE_READ_RECORD_FCB
        POP HL
        RET
PUTC_FILE_4:
        CALL FILE_FLUSH_RECORD
        POP HL
        JP PRINT_RESET_STATE
; ----------------------------------------------------------------------
; COPY_128_BLOCK -- copy one 128-byte CP/M record (LDIR), preserving BC
;   In:        HL = source, DE = destination
;   Out:       128 bytes copied HL->DE; HL/DE advanced past the block
;   Clobbers:  HL, DE, flags (BC saved and restored)
;   Algorithm: Saves BC, sets BC = $80, LDIRs 128 bytes, restores BC, returns.
; ----------------------------------------------------------------------
COPY_128_BLOCK:
        PUSH BC
        LD BC,$0080
        LDIR
        POP BC
        RET
; ----------------------------------------------------------------------
; GETC_FILE -- read the next byte from the open input file, refilling the buffer at end of record
;   In:        PTRFIL ($0840) = current file's FCB base
;   Out:       A = next byte, NC; at EOF A = Ctrl-Z ($1A) with carry set
;   Clobbers:  A, flags (BC/HL saved and restored)
;   Algorithm: For a random file (MODE=3) it diverts to the FIELD-read path
;              (BLOCK_COPY_BC_4). Otherwise it checks FCB.BUF_REM (remaining-byte
;              count): if bytes remain it returns the next one from SEQ_BUF (index =
;              BUF_CNT - decremented BUF_REM) and decrements the count; if the record
;              is exhausted (BUF_REM=0) it falls into GETC_FILE_2 to refill or signal
;              EOF.
; ----------------------------------------------------------------------
GETC_FILE:
        PUSH BC
        PUSH HL
; ----------------------------------------------------------------------
; GETC_FILE_1 -- re-entry point after a successful refill (re-read mode and remaining count)
;   In:        PTRFIL = FCB base
;   Out:       same as GETC_FILE (A = next byte / EOF)
;   Clobbers:  A, BC, HL, flags
;   Algorithm: Identical to the GETC_FILE body but without re-pushing BC/HL; reached
;              after FILE_READ_RECORD loads a fresh record so the next byte can be
;              returned.
; ----------------------------------------------------------------------
GETC_FILE_1:
        LD HL,(PTRFIL)
        LD A,(HL)
        CP $03
        ; MODE=3 (random): read from the FIELD buffer instead
        JP Z,GETC_FILE_RANDOM
        ; FCB.BUF_REM = bytes still available in the current record
        LD BC,FCB.BUF_REM
        ADD HL,BC
        LD A,(HL)
        OR A
        ; no bytes left in this record -> refill or hit EOF
        JR Z,GETC_FILE_2
        DEC HL
        LD A,(HL)
        INC HL
        DEC (HL)
        SUB (HL)
        LD C,A
        ADD HL,BC
        LD A,(HL)
        OR A
        POP HL
        POP BC
        RET
; ----------------------------------------------------------------------
; GETC_FILE_2 -- record exhausted: refill from disk or report EOF
;   In:        HL = FCB+$28 (BUF_REM); PTRFIL = FCB base
;   Out:       on more data: loops back to GETC_FILE_1; on EOF: falls into GETC_FILE_3
;   Clobbers:  A, BC, DE, HL, flags
;   Algorithm: Reads the EOF status byte FCB.BUF_CNT (the 0/$80 marker set by the
;              last read): if it is $00 (EOF latched) it signals end-of-file; otherwise
;              it calls FILE_READ_RECORD to fetch the next record and, if that returned
;              data (NZ), loops back to deliver the first byte.
; ----------------------------------------------------------------------
GETC_FILE_2:
        DEC HL
        LD A,(HL)
        OR A
        JR Z,GETC_FILE_3
        ; fetch the next 128-byte record from disk into the buffer
        CALL FILE_READ_RECORD
        JR NZ,GETC_FILE_1
; ----------------------------------------------------------------------
; GETC_FILE_3 -- end-of-file return: carry set, A = Ctrl-Z
;   In:        (none)
;   Out:       CY=1, A = $1A (Ctrl-Z); BC/HL restored
;   Clobbers:  A, flags
;   Algorithm: Sets carry as the EOF flag, restores HL/BC, loads A = Ctrl-Z, returns.
; ----------------------------------------------------------------------
GETC_FILE_3:
        SCF
        POP HL
        POP BC
        ; return Ctrl-Z as the EOF sentinel byte
        LD A,$1A
        RET
; ----------------------------------------------------------------------
; FILE_READ_RECORD -- read the next record of the CURRENT file (loads PTRFIL first)
;   In:        PTRFIL ($0840) = current file's FCB base
;   Out:       next record loaded into SEQ_BUF; status bytes set (see FILE_READ_RECORD_FCB)
;   Clobbers:  A, BC, DE, HL, flags (DE saved/restored inside the FCB entry)
;   Algorithm: Loads HL = current FCB base from PTRFIL and falls into
;              FILE_READ_RECORD_FCB to do the actual BDOS read.
; ----------------------------------------------------------------------
FILE_READ_RECORD:
        LD HL,(PTRFIL)
; ----------------------------------------------------------------------
; FILE_READ_RECORD_FCB -- read one record into SEQ_BUF and set the data/EOF status
;   In:        HL = FCB base
;   Out:       record read into SEQ_BUF ($29); FCB.BUF_CNT and FCB.BUF_REM both set to
;              $80 if data was read, $00 at EOF; A = that status; OR A sets Z on EOF
;   Clobbers:  A, BC, DE, HL, flags
;   Algorithm: Sets DE = FCB+1 (&FCB.CPM) for the DMA/BDOS calls, increments the
;              16-bit SEQ_RECNO, advances HL to BUF_REM ($28), zeroes it and LDIR-clears
;              the following 127 bytes (BUF_REM + SEQ_BUF[0..126]) so a short record
;              reads as zeros, points the DMA at SEQ_BUF, and issues the BDOS record
;              read using the cold-start-selected function code BDOS_FN_RECREAD
;              (random-read $21 on 2.x / sequential-read $14 on 1.x). A nonzero BDOS
;              return (no data / EOF) yields status $00; a zero return (data) yields
;              $80; the status is stored into BUF_CNT and BUF_REM and Z is set on EOF.
; ----------------------------------------------------------------------
FILE_READ_RECORD_FCB:
        PUSH DE
        LD D,H
        LD E,L
        INC DE
        LD BC,FCB.SEQ_RECNO
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        ; advance the 16-bit sequential record number before the read
        INC BC
        DEC HL
        LD (HL),C
        INC HL
        LD (HL),B
        INC HL
        INC HL
        PUSH HL
        ; pre-clear BUF_REM + SEQ_BUF[0..126] to 0 so a short/partial record reads as zeros
        LD BC,$007F
        LD (HL),$00
        PUSH DE
        LD D,H
        LD E,L
        INC DE
        LDIR
        POP DE
        ; aim the CP/M DMA at SEQ_BUF for the read
        CALL BDOS_SET_DMA_FCB
        ; load the read function code chosen at startup (random-read on 2.x, seq-read on 1.x)
        LD A,(BDOS_FN_RECREAD)
        CALL BDOS_FILE_CALL
        OR A
        LD A,$00
        JR NZ,FILE_READ_RECORD_FCB_1
        ; data was read: mark the buffer status as 'data present' ($80)
        LD A,$80
; ----------------------------------------------------------------------
; FILE_READ_RECORD_FCB_1 -- store the buffer status into BUF_CNT/BUF_REM and set Z on EOF
;   In:        A = status ($00 EOF / $80 data); HL = FCB+$28 (BUF_REM)
;   Out:       status written into FCB.BUF_REM ($28) and FCB.BUF_CNT ($27); OR A sets Z when A=0 (EOF)
;   Clobbers:  A, HL, DE, flags
;   Algorithm: Writes A into BUF_REM ($28) then BUF_CNT ($27), does OR A so the
;              caller's branch tests EOF, restores DE, returns.
; ----------------------------------------------------------------------
FILE_READ_RECORD_FCB_1:
        POP HL
        LD (HL),A
        DEC HL
        LD (HL),A
        OR A
        POP DE
        RET
; ----------------------------------------------------------------------
; BDOS_SET_DMA_FCB -- point the CP/M DMA at this file's 128-byte record buffer (SEQ_BUF)
;   In:        DE = &FCB.CPM (FCB base + 1) -- as passed by every caller in this cluster
;   Out:       CP/M DMA address set to &FCB.SEQ_BUF (= DE + $28 = FCB base + $29)
;   Clobbers:  none (BC/DE/HL saved and restored)
;   Algorithm: Computes HL = DE + $28, moves it into DE, and calls BDOS F_DMAOFF
;              ($1A) Set-DMA so the next read/write transfers into this file's record
;              buffer.
;   [RE] The added offset is $28 (the FCB.BUF_REM field offset), but because callers
;   pass DE = FCB base + 1 (&FCB.CPM), the resulting DMA address is FCB base + $29 =
;   SEQ_BUF exactly. The 128-byte DMA window is SEQ_BUF[0..127]; it does NOT include
;   the BUF_CNT/BUF_REM status bytes that sit ahead of SEQ_BUF.
; ----------------------------------------------------------------------
BDOS_SET_DMA_FCB:
        PUSH BC
        PUSH DE
        PUSH HL
        LD HL,FCB.BUF_REM
        ADD HL,DE
        EX DE,HL
        ; BDOS Set-DMA: route the next disk transfer into this file's SEQ_BUF
        LD C,F_DMAOFF
        CALL BDOS
        POP HL
        POP DE
        POP BC
        RET
; ----------------------------------------------------------------------
; GETC_FILE_EOF -- GETC_FILE wrapper that treats Ctrl-Z as a hard EOF and latches it in the FCB
;   In:        PTRFIL = current file's FCB base
;   Out:       A = byte, NC on data; on EOF (real or Ctrl-Z) CY=1 and FCB.BUF_CNT/
;              BUF_REM are zeroed so subsequent reads stay at EOF
;   Clobbers:  A, flags (BC/HL saved and restored)
;   Algorithm: Calls GETC_FILE; if it already returned carry (EOF) returns as-is. The
;              SCF/CCF pair clears carry so a non-Ctrl-Z byte returns with CY=0. If the
;              byte is Ctrl-Z ($1A) it zeroes BUF_CNT and BUF_REM (sticky EOF) and sets
;              carry.
; ----------------------------------------------------------------------
GETC_FILE_EOF:
        CALL GETC_FILE
        RET C
        ; Ctrl-Z = CP/M text EOF marker: treat it as hard end-of-file
        CP $1A
        SCF
        CCF
        RET NZ
        PUSH BC
        PUSH HL
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_CNT
        ADD HL,BC
        ; latch EOF: zero BUF_CNT then BUF_REM so further reads keep returning EOF
        LD (HL),$00
        INC HL
        LD (HL),$00
        SCF
        POP HL
        POP BC
        RET
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB -- evaluate a string filename and parse "d:NAME.EXT" into the scratch CP/M FCB.
;   In:        HL = BASIC text pointer at the filename expression.
;   Out:       SCRATCH_FCB ($08AA) = a freshly built CP/M FCB: DR byte = drive (0=default, 1.. = A:..),
;              8-byte name + 3-byte type space-padded; SCRATCH_FCB_EX ($08B6, the EX byte) zeroed. HL = text
;              pointer past the consumed expression. Returned CY = an extension separator ('.') was seen.
;   Clobbers:  A, BC, DE, HL; writes SCRATCH_FCB.. through the EX byte.
;   Algorithm: FRMEVL the expression, FRETMP-free the result string, reject an empty string (Bad file name).
;              Point HL at the string body via its descriptor; if a 2nd char is ':' treat the 1st as a drive
;              letter -> DR = (letter-$40); range-check 0..26 (0=default). Then copy up to 8 name chars; on
;              '.' pad the name field with spaces and switch to the 3-char type; finally FCB_PAD_FIELD pads
;              any short field. Raises Bad file name on empty/over-length fields.
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB:
        ; evaluate the filename string expression
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FRETMP
        LD A,(HL)
        OR A
        ; empty filename string -> Bad file name
        JP Z,RAISE_BAD_FILE_NAME
        PUSH AF
        INC HL
        LD E,(HL)
        INC HL
        LD H,(HL)
        LD L,E
        LD E,A
        CP $02
        JR C,PARSE_FILENAME_TO_FCB_1
        LD C,(HL)
        INC HL
        LD A,(HL)
        DEC E
        ; second char is ':' ? then the first char is a drive letter (d:)
        CP $3A
        JR Z,PARSE_FILENAME_TO_FCB_2
        DEC HL
        INC E
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_1 -- no-drive-prefix entry: default the drive and rewind to the name start.
;   In:        HL points one past the (rejected) drive area; E = remaining char count.
;   Out:       C = '@' ($40) so the drive byte computes to 0 (default drive); HL/E rewound to the name.
;   Clobbers:  C, E, HL.
;   Algorithm: Back HL/E up and seed C with '@' so the shared (C-$40) drive computation yields the
;              default-drive code 0; falls into the common validation at PARSE_FILENAME_TO_FCB_2.
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_1:
        DEC HL
        INC E
        ; no drive prefix: seed C='@' ($40) so (C-$40)=0 selects the default drive
        LD C,$40
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_2 -- validate drive code and store FCB.CPM.DR, then begin the name copy.
;   In:        C = drive char ('@'+n), E = remaining filename length, HL -> first name char.
;   Out:       SCRATCH_FCB.DR set; BC -> SCRATCH_FCB_NAME; D = $0B field width counter (8 name + 3 type).
;   Clobbers:  A, BC, D.
;   Algorithm: Reject an empty remaining name (Bad file name); compute drive = C-$40, range-check it
;              (carry, i.e. C<'@', or >=27 -> Bad file name; 0=default); store it as the FCB drive byte; set
;              D=$0B and fall into the per-character copy loop.
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_2:
        DEC E
        JP Z,RAISE_BAD_FILE_NAME
        LD A,C
        ; convert drive letter to CP/M drive number (A:->1 ..); range-check 0..26, 0 = default
        SUB $40
        JP C,RAISE_BAD_FILE_NAME
        CP $1B
        JP NC,RAISE_BAD_FILE_NAME
        ; store the drive byte as FCB.CPM.DR, then advance BC to the 11-byte name+type area
        LD BC,SCRATCH_FCB
        LD (BC),A
        INC BC
        LD D,$0B
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_3 -- advance past the '.' separator and continue copying into the type field.
;   In:        HL -> the '.' just matched; BC -> the type field; D = remaining field width; AF saved on stack.
;   Out:       HL advanced past '.'; loop continues into the 3-char type field.
;   Clobbers:  HL.
;   Algorithm: Skip the dot and re-enter the copy loop (the SCF/PUSH AF in the caller records that the
;              extension separator was seen, surfacing as the returned CY).
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_3:
        INC HL
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_4 -- per-character copy loop body: emit one name/type byte to the FCB.
;   In:        HL -> source char, E = input chars left (signed), BC -> FCB dest, D = field bytes left.
;   Out:       on input exhausted (E goes negative) jumps to FCB_PAD_FIELD_1 to space-fill the rest;
;              on '.' calls FCB_PAD_FIELD then PARSE_FILENAME_TO_FCB_3 to switch to the type field.
;   Clobbers:  A, BC, D, E, HL.
;   Algorithm: Decrement the input counter; if no more input, pad the field; if the char is '.', finish the
;              current field (pad to width) and move to the type field; otherwise store the char and loop
;              until the 11-byte name+type area (D) is full. (Characters are stored verbatim; no upper-case
;              fold here -- only the OPEN mode letter is upper-cased.)
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_4:
        DEC E
        ; input exhausted -> space-pad the remaining FCB field bytes
        JP M,FCB_PAD_FIELD_1
        LD A,(HL)
        ; '.' starts the extension: pad the name field then switch to the type field
        CP $2E
        JR NZ,PARSE_FILENAME_TO_FCB_5
        CALL FCB_PAD_FIELD
        POP AF
        SCF
        PUSH AF
        JR PARSE_FILENAME_TO_FCB_3
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_5 -- store one ordinary filename character into the FCB and advance.
;   In:        A = char to store, BC -> FCB dest, HL -> source, D = field bytes left.
;   Out:       char written; BC,HL advanced; D decremented; loops back to PARSE_FILENAME_TO_FCB_4 until full.
;   Clobbers:  BC, D, HL.
;   Algorithm: Write the byte to the FCB, bump both pointers, and decrement the field-width counter D;
;              when D reaches 0 (all 11 bytes placed) fall into PARSE_FILENAME_TO_FCB_6 to finish.
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_5:
        LD (BC),A
        INC BC
        INC HL
        DEC D
        JR NZ,PARSE_FILENAME_TO_FCB_4
; ----------------------------------------------------------------------
; PARSE_FILENAME_TO_FCB_6 -- finish parsing: clear the FCB extent byte and restore the caller's state.
;   In:        SCRATCH_FCB name/type fully built; AF (carry=ext-seen) and HL saved on stack.
;   Out:       SCRATCH_FCB_EX ($08B6, EX byte) = 0; HL restored to the post-filename text pointer; CY from
;              the popped AF = extension-separator-seen; RET.
;   Clobbers:  A.
;   Algorithm: Zero the current-extent byte (so a fresh OPEN starts at extent 0), pop the saved AF (whose
;              carry flag tells the caller whether a '.' extension was present) and the saved text pointer,
;              and return.
; ----------------------------------------------------------------------
PARSE_FILENAME_TO_FCB_6:
        XOR A
        ; clear the FCB current-extent (EX) byte for a fresh open
        LD (SCRATCH_FCB_EX),A
        POP AF
        POP HL
        RET
; ----------------------------------------------------------------------
; FCB_PAD_FIELD -- space-pad the rest of the current FCB field when a separator/end is hit early.
;   In:        D = bytes remaining in the 11-byte name+type window; BC -> next FCB dest byte.
;   Out:       writes ' ' ($20) until D hits the field boundary; returns when the field is full.
;   Clobbers:  A, BC, D.
;   Algorithm: Validate position (D==$0B means a leading '.' with empty name, or D<3 means an over-long
;              name -> Bad file name); if exactly at the type boundary (D==3) return; otherwise pad with
;              spaces toward the next field boundary. Used to right-pad the name to 8 chars before the type.
; ----------------------------------------------------------------------
FCB_PAD_FIELD:
        LD A,D
        CP $0B
        ; field counter still full ($0B) -> a leading '.' / empty name -> Bad file name
        JP Z,RAISE_BAD_FILE_NAME
        CP $03
        ; fewer than 3 bytes left means the name over-ran the 8-char field -> Bad file name
        JP C,RAISE_BAD_FILE_NAME
        RET Z
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        JR FCB_PAD_FIELD
; ----------------------------------------------------------------------
; FCB_PAD_FIELD_1 -- end-of-input entry: if any field bytes remain, space-fill them, else finish.
;   In:        D = FCB field bytes left (0 means exactly filled).
;   Out:       branches to PARSE_FILENAME_TO_FCB_6 when nothing remains; else falls into the pad loop.
;   Clobbers:  sets Z via INC D / DEC D (D otherwise unchanged).
;   Algorithm: Test D for zero without disturbing it; if the name+type area is already full go finish,
;              otherwise fall into FCB_PAD_FIELD_2 to space-fill the remainder.
; ----------------------------------------------------------------------
FCB_PAD_FIELD_1:
        INC D
        DEC D
        JR Z,PARSE_FILENAME_TO_FCB_6
; ----------------------------------------------------------------------
; FCB_PAD_FIELD_2 -- fill the remaining D FCB name/type bytes with spaces.
;   In:        D = bytes to fill, BC -> next FCB dest byte.
;   Out:       D bytes set to ' ' ($20); jumps to PARSE_FILENAME_TO_FCB_6 to finish.
;   Clobbers:  A, BC, D.
;   Algorithm: Store ' ' and advance until D is exhausted, then complete the parse (zero EX, restore HL).
; ----------------------------------------------------------------------
FCB_PAD_FIELD_2:
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        JR NZ,FCB_PAD_FIELD_2
        JR PARSE_FILENAME_TO_FCB_6
; ----------------------------------------------------------------------
; STMT_NAME -- NAME statement: rename a disk file (NAME "old" AS "new").
;   In:        HL = BASIC text pointer after the NAME token.
;   Out:       file renamed on disk; HL = text pointer past the statement. Raises File not found,
;              File already exists, or 'FC' on a drive mismatch.
;   Clobbers:  A, BC, DE, HL; uses SCRATCH_FCB ($08AA) and the rename block at $089A.
;   Algorithm: Parse the old filename into SCRATCH_FCB; set the BDOS DMA back to the default $0080 buffer;
;              OPEN the old file (FF -> File not found). Copy its 12-byte FCB (drive+name+type) into the
;              low half of the rename block at $089A. Then SYNCHR the 'AS' keyword and parse the new name
;              into SCRATCH_FCB. Require the same drive byte (else FC), and verify the new name does NOT
;              already exist via F_OPEN (success -> File already exists). Finally BDOS F_RENAME with DE
;              pointing at the rename block (old FCB at +0, new drive+name at +16).
; ----------------------------------------------------------------------
STMT_NAME:
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        ; restore the BDOS DMA to the standard $0080 buffer before the directory ops
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,SCRATCH_FCB
        ; open the old file to confirm it exists (and resolves its directory entry)
        LD C,F_OPEN
        CALL BDOS
        ; BDOS $FF (not found) + 1 = 0 -> File not found
        INC A
        JP Z,RAISE_FILE_NOT_FOUND
        ; copy the resolved old FCB (12 bytes: drive+8 name+3 type) into the low half of the F_RENAME block
        LD HL,RENAME_FCB
        LD DE,SCRATCH_FCB
        LD B,$0C
; ----------------------------------------------------------------------
; STMT_NAME_1 -- copy loop: move the 12-byte resolved old FCB into the rename block.
;   In:        DE -> SCRATCH_FCB, HL -> RENAME_FCB, B = 12.
;   Out:       12 bytes (DR+name+type) copied; HL/DE advanced past them.
;   Clobbers:  A, B, DE, HL.
;   Algorithm: Byte copy of the just-opened old FCB into the rename block's first half so F_RENAME can
;              pair it with the new drive+name written into the second half.
; ----------------------------------------------------------------------
STMT_NAME_1:
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        DJNZ STMT_NAME_1
        POP HL
        ; require the literal 'AS' between the two filenames
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'S'                      ; inline char arg consumed by the preceding CALL
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        LD A,(SCRATCH_FCB)
        LD HL,RENAME_FCB
        ; old and new must name the same drive (compare scratch DR vs saved DR) else FC
        CP (HL)
        JP NZ,ERROR_FC
        LD DE,SCRATCH_FCB
        LD C,F_OPEN
        CALL BDOS
        INC A
        ; new name already opens -> target exists -> File already exists
        JP NZ,RAISE_FILE_ALREADY_EXISTS
        ; BDOS rename: DE -> 32-byte block holding old FCB (+0) and new drive+name (+16)
        LD C,F_RENAME
        LD DE,RENAME_FCB
        CALL BDOS
        POP HL
        RET
; ----------------------------------------------------------------------
; STMT_OPEN -- OPEN statement: OPEN mode$, [#] filenum, name$  -- open a disk file on a channel.
;   In:        HL = BASIC text pointer after the OPEN token.
;   Out:       the file's per-file FCB entry initialised (MODE set, CP/M FCB built, buffers cleared) and
;              registered in FILTAB; for sequential input it pre-reads the first record. HL = text past the
;              statement. Raises Bad file mode / Bad file number / File already open / File not found /
;              Too many files.
;   Clobbers:  A, BC, DE, HL; SCRATCH_FCB; the chosen FCB entry; PTRFIL; OPEN_RESUME_TEXT_PTR.
;   Algorithm: Push PRINT_RESET_STATE as a return so PRINT state is reset on exit. FRMEVL the mode string;
;              its first letter (upper-cased via AND $DF) selects FCB_MODE_SEQ_OUT('O'), FCB_MODE_SEQ_IN('I')
;              or FCB_MODE_RANDOM('R') (else Bad file mode). SYNCHR ',', optional '#', GETBYT the file number
;              (0 -> Bad file number), SYNCHR ','. Verify the slot is free (FILE_NUM_TO_FCB_A returns the
;              slot mode in A; nonzero -> File already open). Parse the filename into SCRATCH_FCB. Copy
;              SCRATCH_FCB into the entry's CP/M-FCB slot, zero EX and CR, set DMA, then: for output
;              DELETE+MAKE (handle extents/Too many files), for input/random OPEN (auto-MAKE on $03
;              not-found from the RAM trampoline). Stamp MODE, and for sequential-input pre-read the first
;              record; for random zero-fill the buffer. (NOTE: FILE_NUM_TO_FCB_A, not FILE_NUM_TO_FCB_2,
;              resolves the entry pointer BC.)
; ----------------------------------------------------------------------
STMT_OPEN:
        ; arrange to reset PRINT state when OPEN returns (pushed as the return address)
        LD BC,PRINT_RESET_STATE
        PUSH BC
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FRETMP
        LD A,(HL)
        OR A
        JP Z,RAISE_BAD_FILE_MODE
        INC HL
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD A,(BC)
        ; upper-case the mode letter so 'o'/'i'/'r' match 'O'/'I'/'R'
        AND $DF
        LD D,FCB_MODE_SEQ_OUT
        CP $4F
        JR Z,STMT_OPEN_1
        LD D,FCB_MODE_SEQ_IN
        CP $49
        JR Z,STMT_OPEN_1
        LD D,FCB_MODE_RANDOM
        CP $52
        JP NZ,RAISE_BAD_FILE_MODE
; ----------------------------------------------------------------------
; STMT_OPEN_1 -- OPEN mode resolved: parse the file-number argument.
;   In:        D = selected FCB mode; HL -> text pointer at the comma after the mode.
;   Out:       A/E = file number (1..); D still = mode; raises Bad file number on 0.
;   Clobbers:  A, E, HL.
;   Algorithm: SYNCHR the ',', skip an optional '#', GETBYT the channel number, SYNCHR the next ','; a
;              zero channel raises Bad file number. Mode is carried on the stack across the parse.
; ----------------------------------------------------------------------
STMT_OPEN_1:
        POP HL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        PUSH DE
        ; optional '#' before the file number -- skip it if present
        CP $23
        CALL Z,CHRGET
        CALL GETBYT
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        LD A,E
        OR A
        JP Z,RAISE_BAD_FILE_NUMBER
        POP DE
; ----------------------------------------------------------------------
; STMT_OPEN_2 -- check the channel is free, parse the filename, and (random) read the FIELD argument.
;   In:        A = file number, D = mode.
;   Out:       BC = base of the resolved per-file FCB entry; OPEN_RESUME_TEXT_PTR = the post-args BASIC
;              text pointer; AF restored from the parse (CY = extension-was-typed).
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: FILE_NUM_TO_FCB_A resolves the entry (BC) and returns its mode -> if already open, File
;              already open. Parse the filename into SCRATCH_FCB. Then FILE_NUM_TO_FCB_2 (A = mode) parses
;              the optional FIELD record/buffer argument for a RANDOM file and returns HL = the continuation
;              text pointer, saved to OPEN_RESUME_TEXT_PTR. [RE] If no extension was typed (NC) and E==0 and
;              the type field is blank, default the filetype to 'BAS'.
; ----------------------------------------------------------------------
STMT_OPEN_2:
        LD E,A
        PUSH DE
        ; resolve the slot's FCB entry (BC) and return its mode in A; nonzero means it is already open
        CALL FILE_NUM_TO_FCB_A
        ; slot already has an open file -> File already open
        JP NZ,RAISE_FILE_ALREADY_OPEN
        POP DE
        PUSH BC
        PUSH DE
        ; parse the name$ into the scratch CP/M FCB
        CALL PARSE_FILENAME_TO_FCB
        POP DE
        POP BC
        PUSH BC
        PUSH AF
        LD A,D
        CALL FILE_NUM_TO_FCB_2
        POP AF
        LD (OPEN_RESUME_TEXT_PTR),HL
        JR C,STMT_OPEN_3
        LD A,E
        OR A
        JP NZ,STMT_OPEN_3
        ; no extension typed: default the filetype to 'BAS'
        LD HL,SCRATCH_FCB_TYPE
        LD A,(HL)
        CP $20
        JR NZ,STMT_OPEN_3
        LD (HL),$42
        INC HL
        LD (HL),$41
        INC HL
        LD (HL),$53
; ----------------------------------------------------------------------
; STMT_OPEN_3 -- copy the scratch FCB into the channel's entry and clear its open-state bytes.
;   In:        D = mode; entry pointer on the stack (-> HL); SCRATCH_FCB holds the parsed name.
;   Out:       PTRFIL = entry base; entry's CP/M FCB filled from SCRATCH_FCB with EX ($0C) and CR ($20)
;              zeroed; DE -> the entry's CP/M FCB (entry+1) for the upcoming BDOS calls; mode saved on stack.
;   Clobbers:  A, C, DE, HL.
;   Algorithm: Set PTRFIL to this entry; copy the 12-byte drive+name+type from SCRATCH_FCB into entry+1
;              (=FCB.CPM), then store 0 at the EX byte ($0C) and, $14 further on, at the CR byte ($20, the
;              current-record cursor) so the file opens at extent 0 / record 0. DE is left at the CP/M FCB
;              for OPEN/MAKE/DELETE.
; ----------------------------------------------------------------------
STMT_OPEN_3:
        POP HL
        LD A,D
        PUSH AF
        ; make this entry the current file (PTRFIL) for the rest of OPEN
        LD (PTRFIL),HL
        PUSH HL
        INC HL
        LD DE,SCRATCH_FCB
        LD C,$0C
; ----------------------------------------------------------------------
; STMT_OPEN_4 -- copy loop: move the 12-byte parsed FCB (drive+name+type) into the channel entry.
;   In:        DE -> SCRATCH_FCB, HL -> entry's CP/M FCB, C = 12.
;   Out:       12 bytes copied; HL left just past the type; then the EX byte ($0C) and the CR byte ($20)
;              are zeroed.
;   Clobbers:  A, C, DE, HL.
;   Algorithm: Byte-copy drive+name+type, then clear the EX byte ($0C) and (after a +$14 step) the CR byte
;              ($20) so the file opens at extent 0 / record 0.
; ----------------------------------------------------------------------
STMT_OPEN_4:
        LD A,(DE)
        LD (HL),A
        INC DE
        INC HL
        DEC C
        JR NZ,STMT_OPEN_4
        LD (HL),$00
        LD DE,$0014
        ADD HL,DE
        LD (HL),$00
        POP DE
        PUSH DE
        INC DE
        CALL BDOS_SET_DMA_FCB
        POP HL
        POP AF
        PUSH AF
        PUSH HL
        CP FCB_MODE_SEQ_OUT
        JR NZ,STMT_OPEN_6
        PUSH DE
        LD C,F_DELETE
        CALL BDOS
        POP DE
; ----------------------------------------------------------------------
; STMT_OPEN_5 -- create the output file (BDOS F_MAKE), failing with Too many files if the directory is full.
;   In:        DE -> the channel's CP/M FCB.
;   Out:       file created; on BDOS $FF (no directory room) raises Too many files; else continues at
;              STMT_OPEN_7.
;   Clobbers:  A, C.
;   Algorithm: BDOS F_MAKE; ($FF+1)==0 means the directory is full -> Too many files.
; ----------------------------------------------------------------------
STMT_OPEN_5:
        LD C,F_MAKE
        CALL BDOS
        ; BDOS $FF (directory full) + 1 = 0 -> Too many files
        INC A
        JP Z,RAISE_TOO_MANY_FILES
        JR STMT_OPEN_7
; ----------------------------------------------------------------------
; STMT_OPEN_6 -- open an existing file for input/random; auto-create on a missing extent.
;   In:        DE -> the channel's CP/M FCB.
;   Out:       file open; on not-found, may advance the extent and retry MAKE, or raise File not found.
;   Clobbers:  A, C, DE.
;   Algorithm: BDOS F_OPEN; success -> STMT_OPEN_7. On failure call the RAM dispatch trampoline (extended
;              error class); class $03 means the requested extent doesn't exist -> bump the extent byte and
;              go MAKE it (STMT_OPEN_5); any other class -> File not found.
; ----------------------------------------------------------------------
STMT_OPEN_6:
        LD C,F_OPEN
        CALL BDOS
        INC A
        JR NZ,STMT_OPEN_7
        ; consult the extended-error path; A=$03 means the extent is missing (create it) rather than a hard not-found
        CALL RAM_DISPATCH_TRAMPOLINE
        CP $03
        JP NZ,RAISE_FILE_NOT_FOUND
        INC DE
        JR STMT_OPEN_5
; ----------------------------------------------------------------------
; STMT_OPEN_7 -- finalise the open: stamp the file mode and clear the sequential record/position cells.
;   In:        entry pointer and mode saved on the stack.
;   Out:       entry MODE byte set; FCB.SEQ_RECNO and the following 3 bytes zeroed; A = mode.
;   Clobbers:  A, DE, HL.
;   Algorithm: Write the mode to the entry's MODE byte, then zero the 4-byte sequential bookkeeping block
;              at FCB.SEQ_RECNO (record number word + buffer count/status). Dispatch on mode: random ->
;              STMT_OPEN_8 (clear the record buffer); sequential-input -> pre-read first record then return
;              the resume text pointer; sequential-output -> just reset run state.
; ----------------------------------------------------------------------
STMT_OPEN_7:
        POP DE
        POP AF
        ; stamp the channel's MODE byte (1/2/3) marking it open
        LD (DE),A
        PUSH DE
        LD HL,FCB.SEQ_RECNO
        ADD HL,DE
        XOR A
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
        INC HL
        LD (HL),A
        POP HL
        LD A,(HL)
        CP FCB_MODE_RANDOM
        JP Z,STMT_OPEN_8
        CP FCB_MODE_SEQ_IN
        JP NZ,RESET_RUN_STATE_1
        ; sequential input: pre-read the first 128-byte record into the buffer
        CALL FILE_READ_RECORD
        LD HL,(OPEN_RESUME_TEXT_PTR)
        RET
; ----------------------------------------------------------------------
; STMT_OPEN_8 -- random-mode open tail: zero the 128-byte record buffer (SEQ_BUF), then finish.
;   In:        HL -> the channel entry (MODE byte).
;   Out:       the 128-byte FCB.SEQ_BUF region cleared to 0 (stores B, which = 0 here); then resets run
;              state and returns the resume text pointer.
;   Clobbers:  A, BC, HL.
;   Algorithm: Point at FCB.SEQ_BUF (entry+$29) and store B (=0, the high byte of the LD BC,$0029 just
;              executed) across 128 bytes to clear the record buffer, then JP RESET_RUN_STATE_1 which
;              returns OPEN_RESUME_TEXT_PTR in HL.
; ----------------------------------------------------------------------
STMT_OPEN_8:
        ; point at the 128-byte record buffer (offset $29) to clear for the freshly opened random file
        LD BC,FCB.SEQ_BUF
        ADD HL,BC
        LD C,$80
; ----------------------------------------------------------------------
; STMT_OPEN_9 -- buffer-clear loop for the random open: zero 128 buffer bytes.
;   In:        HL -> buffer, C = 128, B = 0.
;   Out:       128 bytes set to 0; jumps to RESET_RUN_STATE_1.
;   Clobbers:  C, HL.
;   Algorithm: Store B (0) and advance until C exhausts the 128-byte record.
; ----------------------------------------------------------------------
STMT_OPEN_9:
        LD (HL),B
        INC HL
        DEC C
        JR NZ,STMT_OPEN_9
        JP RESET_RUN_STATE_1
; ----------------------------------------------------------------------
; STMT_SYSTEM -- SYSTEM statement: close all files and exit BASIC back to CP/M.
;   In:        Z flag from the statement-end check (RET NZ if extra text follows).
;   Out:       does not return to BASIC; closes files, restores the text screen, then warm-boots CP/M.
;   Clobbers:  all.
;   Algorithm: Refuse trailing garbage (RET NZ), CLOSE_ALL_FILES, switch the Apple to text mode
;              (STMT_TEXT), then fall into STMT_SYSTEM_WBOOT which jumps to the CP/M WBOOT vector.
; ----------------------------------------------------------------------
STMT_SYSTEM:
        RET NZ
        ; flush and close every open file before leaving BASIC
        CALL CLOSE_ALL_FILES
        CALL STMT_TEXT
; ----------------------------------------------------------------------
; STMT_SYSTEM_WBOOT -- self-modified jump to the CP/M warm-boot (WBOOT) vector; leaves BASIC.
;   In:        (none) -- the JP operand was patched at cold start.
;   Out:       transfers control to CP/M's WBOOT; never returns.
;   Clobbers:  n/a.
;   Algorithm: The image holds JP $0000 here; COLD_START reads the BIOS WBOOT vector from base-page
;              $0001..$0002 and writes it into this JP's operand, so running SYSTEM jumps to the live
;              warm-boot entry. (Self-modifying code; comment preserved.)
; ----------------------------------------------------------------------
STMT_SYSTEM_WBOOT:
        JP $0000
; ----------------------------------------------------------------------
; STMT_RESET -- RESET statement: close all files and re-log the disk system, preserving the current drive.
;   In:        Z flag from the statement-end check (RET NZ if extra text follows).
;   Out:       all files closed, BDOS disk system reset, the previously-current drive reselected; HL preserved.
;   Clobbers:  A, C, E (HL saved/restored).
;   Algorithm: CLOSE_ALL_FILES, read the current drive (BDOS DRV_GET), reset the whole disk system
;              (BDOS DRV_ALLRESET, which logs out all drives and re-reads directories), then reselect the
;              saved drive (BDOS DRV_SET) so the user's default is unchanged.
; ----------------------------------------------------------------------
STMT_RESET:
        RET NZ
        PUSH HL
        ; close every open file before resetting the disk system
        CALL CLOSE_ALL_FILES
        ; remember the current drive so it can be reselected after the reset
        LD C,DRV_GET
        CALL BDOS
        PUSH AF
        ; BDOS reset disk system: log out all drives and force directory re-read
        LD C,DRV_ALLRESET
        CALL BDOS
        POP AF
        LD E,A
        LD C,DRV_SET
        CALL BDOS
        POP HL
        RET
; ----------------------------------------------------------------------
; STMT_KILL -- KILL statement: delete a disk file by name.
;   In:        HL = BASIC text pointer after the KILL token.
;   Out:       the named file deleted from disk; HL past the statement. Raises File not found if absent.
;   Clobbers:  A, BC, DE, HL; uses SCRATCH_FCB.
;   Algorithm: Parse the filename into SCRATCH_FCB; restore BDOS DMA to $0080; OPEN the file to confirm
;              it exists (and so an open directory entry is closed first). If found, CLOSE it then
;              BDOS F_DELETE; if not found, raise File not found.
; ----------------------------------------------------------------------
STMT_KILL:
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,SCRATCH_FCB
        PUSH DE
        ; open to confirm the file exists before deleting (FF -> not found)
        LD C,F_OPEN
        CALL BDOS
        INC A
        POP DE
        PUSH DE
        PUSH AF
; ----------------------------------------------------------------------
; STMT_KILL_1 -- KILL tail: close the just-opened file (if present), then delete it.
;   In:        Z flag = file-not-found indicator; DE -> SCRATCH_FCB; A (saved) = open+1 result.
;   Out:       file closed and deleted, or File not found raised.
;   Clobbers:  A, C, DE, HL.
;   Algorithm: If the OPEN succeeded (NZ), BDOS F_CLOSE the directory entry; if it failed (Z) raise File
;              not found; then BDOS F_DELETE to remove the file.
; ----------------------------------------------------------------------
STMT_KILL_1:
        ; close the entry the confirming OPEN left open (only if it was found)
        LD C,F_CLOSE
        CALL NZ,BDOS
        POP AF
        POP DE
        JP Z,RAISE_FILE_NOT_FOUND
        ; BDOS delete the file
        LD C,F_DELETE
        CALL BDOS
        POP HL
        RET
; ----------------------------------------------------------------------
; STMT_FILES -- FILES statement: list directory entries matching an optional filespec.
;   In:        Z flag = 'no argument' indicator; HL = text pointer (filespec expression if present).
;   Out:       prints matching 11-char filenames (NAME.EXT) in columns to the console; HL past statement.
;              Raises File not found if nothing matches.
;   Clobbers:  A, BC, DE, HL; SCRATCH_FCB.
;   Algorithm: With no argument, build an all-'?' wildcard FCB ('????????.???'); with an argument parse it
;              into SCRATCH_FCB. Turn any leading '*' in the name (8) or type (3) field into all-'?'
;              (FCB_WILD_IF_STAR). Set DMA to $0080, BDOS Search-First; loop Search-Next, printing each
;              directory entry's 11 name bytes via OUTCHR with a '.' inserted before a non-blank extension,
;              wrapping columns using the print width and current column.
; ----------------------------------------------------------------------
STMT_FILES:
        JR NZ,STMT_FILES_1
        PUSH HL
        LD HL,SCRATCH_FCB
        LD (HL),$00
        INC HL
        LD C,$0B
        ; no filespec: fill the 11-byte name+type with '?' to match every file
        CALL FCB_WILD_EXPAND
        POP HL
; ----------------------------------------------------------------------
; STMT_FILES_1 -- prepare the search FCB: expand leading '*' wildcards and issue Search-First.
;   In:        SCRATCH_FCB holds the parsed/wildcard filespec.
;   Out:       BDOS Search-First done; A = directory index (0..3) of the first match, or File not found.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: Zero the EX byte; if the name field starts with '*' fill 8 chars with '?'; if the type field
;              starts with '*' fill 3 chars with '?'. Set DMA to $0080 and BDOS F_SFIRST; $FF -> File not
;              found.
; ----------------------------------------------------------------------
STMT_FILES_1:
        ; a filespec was supplied: parse it into the scratch FCB
        CALL NZ,PARSE_FILENAME_TO_FCB
        XOR A
        LD (SCRATCH_FCB_EX),A
        PUSH HL
        LD HL,SCRATCH_FCB_NAME
        LD C,$08
        CALL FCB_WILD_IF_STAR
        LD HL,SCRATCH_FCB_TYPE
        LD C,$03
        CALL FCB_WILD_IF_STAR
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,SCRATCH_FCB
        ; BDOS search-first: A returns the matched entry's index (0..3) within the $0080 buffer
        LD C,F_SFIRST
        CALL BDOS
        CP $FF
        JP Z,RAISE_FILE_NOT_FOUND
; ----------------------------------------------------------------------
; STMT_FILES_2 -- locate the matched directory entry in the DMA buffer and start printing its name.
;   In:        A = BDOS search return (low 2 bits select which of the 4 entries in the $0080 buffer).
;   Out:       HL -> the entry's 11-byte filename; C = 11 (byte counter) for the print loop.
;   Clobbers:  A, BC, HL.
;   Algorithm: Each directory record holds 4 entries of 32 bytes; A&3 picks one, *32 (five ADD A,A) gives
;              its offset, +$0081 skips the per-entry user-code byte to the 11-char name; set C=11 and print.
; ----------------------------------------------------------------------
STMT_FILES_2:
        ; BDOS returns the entry index; the buffer holds 4 directory entries of 32 bytes each
        AND $03
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        LD C,A
        LD B,$00
        ; $0080+1 skips the entry's drive/user byte to its 11-char name+type
        LD HL,$0081
        ADD HL,BC
        LD C,$0B
; ----------------------------------------------------------------------
; STMT_FILES_3 -- print-name loop: emit each filename char, inserting '.' before a non-blank extension.
;   In:        HL -> next name byte, C = bytes left (counts 11..1).
;   Out:       characters written via OUTCHR; '.' printed between name and a non-blank type.
;   Clobbers:  A, HL.
;   Algorithm: Output the current char; when 8 name chars have been printed (C==4, i.e. 3 type bytes left)
;              and the next (type) byte is non-blank, output '.' first; loop until all 11 chars are shown.
; ----------------------------------------------------------------------
STMT_FILES_3:
        LD A,(HL)
        INC HL
        CALL OUTCHR
        LD A,C
        ; after the 8-char name (3 type bytes remain) decide whether to print the '.' separator
        CP $04
        JR NZ,STMT_FILES_5
        LD A,(HL)
        CP $20
        JR Z,STMT_FILES_4
        LD A,$2E
; ----------------------------------------------------------------------
; STMT_FILES_4 -- emit the chosen name/extension boundary byte.
;   In:        A = '.' ($2E, when the extension is non-blank) or the actual type byte (when ext is blank).
;   Out:       one char written via OUTCHR.
;   Clobbers:  A.
;   Algorithm: Output the separator (or the falls-through type byte), then continue the 11-char print loop.
; ----------------------------------------------------------------------
STMT_FILES_4:
        CALL OUTCHR
; ----------------------------------------------------------------------
; STMT_FILES_5 -- name-loop counter and end-of-name column handling.
;   In:        C = remaining name bytes; PRINT_WIDTH and the current print column ($0B11) for layout.
;   Out:       loops back while bytes remain; at end, prints two spaces to tab to the next column, or sets
;              CY to wrap to a new line.
;   Clobbers:  A, D.
;   Algorithm: Decrement C and loop until the 11-char name is printed; then compute (column+$0F) and
;              compare PRINT_WIDTH to it -- if PRINT_WIDTH < column+$0F the next column would overflow (CY
;              set) so skip the spaces and let STMT_FILES_6 CRLF; otherwise print two spaces to tab over.
; ----------------------------------------------------------------------
STMT_FILES_5:
        DEC C
        JR NZ,STMT_FILES_3
        LD A,(L_0B11)
        ADD A,$0F
        LD D,A
        ; decide whether the next column fits on the current line
        LD A,(PRINT_WIDTH)
        CP D
        JR C,STMT_FILES_6
        LD A,$20
        CALL OUTCHR
        CALL OUTCHR
; ----------------------------------------------------------------------
; STMT_FILES_6 -- advance to the next matching entry (Search-Next) or finish the listing.
;   In:        CY from the column test (set -> wrap line); SCRATCH_FCB still holds the search pattern.
;   Out:       prints a CRLF if wrapping, BDOS Search-Next; loops to STMT_FILES_2 on a match, else RET.
;   Clobbers:  A, C, DE.
;   Algorithm: Optionally CRLF (CALL C,CRLF), then BDOS F_SNEXT; A=$FF ends the listing (restore HL and
;              return), any other value loops back to print the next name.
; ----------------------------------------------------------------------
STMT_FILES_6:
        CALL C,CRLF
        LD DE,SCRATCH_FCB
        ; BDOS search-next: fetch the next matching directory entry, $FF ends the listing
        LD C,F_SNEXT
        CALL BDOS
        CP $FF
        JR NZ,STMT_FILES_2
        POP HL
        RET
; ----------------------------------------------------------------------
; FCB_WILD_IF_STAR -- if an FCB name/type field begins with '*', expand it to all-'?' wildcards.
;   In:        HL -> start of the field; C = field width (8 for name, 3 for type).
;   Out:       if (HL)=='*', the C bytes are set to '?'; otherwise the field is unchanged. RET.
;   Clobbers:  A (and, when expanding, C, HL via the fall-through).
;   Algorithm: Test the first byte; if not '*' return immediately, else fall into FCB_WILD_EXPAND to fill
;              the field with '?' so BDOS directory search matches any name/extension.
; ----------------------------------------------------------------------
FCB_WILD_IF_STAR:
        LD A,(HL)
        CP $2A
        RET NZ
; ----------------------------------------------------------------------
; FCB_WILD_EXPAND -- fill C FCB field bytes with '?' ($3F) (a match-anything wildcard for BDOS search).
;   In:        HL -> field, C = byte count.
;   Out:       C bytes set to '?'; HL advanced past them; RET.
;   Clobbers:  C, HL.
;   Algorithm: Store '?' across C bytes. Used to build the default all-files pattern and to expand a
;              leading '*' wildcard.
; ----------------------------------------------------------------------
FCB_WILD_EXPAND:
        LD (HL),$3F
        INC HL
        DEC C
        JR NZ,FCB_WILD_EXPAND
        RET
; ----------------------------------------------------------------------
; BDOS_FILE_CALL -- shared BDOS file-op wrapper: issue the call, advance the random record number, map result.
;   In:        A = BDOS function number, DE = FCB pointer (= &FCB.CPM, i.e. entry+1).
;   Out:       For read-random (C==$22 on return) returns a mapped BASIC status in A and flags: 0/Z on
;              success, 1 on 'reading unwritten data' ($03), else 2; dir-full ($05) -> Too many files. For
;              other functions returns the raw BDOS A.
;   Clobbers:  A, BC, HL; increments the 3-byte random record number R0/R1/R2 of the FCB.
;   Algorithm: Call BDOS with C=A, DE=FCB; on return increment the 24-bit random record number with carry
;              -- the operand FCB.CPM.CR assembles to $21 and is added to DE (=entry+1), so the first byte
;              touched is R0 (CPMFCB offset $21), then R1 ($22), then R2 ($23); CR ($20) is NOT touched here.
;              If the function was read-random ($22), translate the BDOS error code into BASIC's small codes;
;              otherwise pass the BDOS result through unchanged. [RE] The R0/R1/R2 bump advances the random
;              record cursor so a subsequent random op addresses the following record.
; ----------------------------------------------------------------------
BDOS_FILE_CALL:
        PUSH DE
        LD C,A
        PUSH BC
        ; perform the requested BDOS file operation (C=function, DE=FCB)
        CALL BDOS
        POP BC
        POP DE
        PUSH AF
        ; advance the 24-bit random record number R0/R1/R2 with carry (operand $21 added to DE=entry+1 lands on R0); next random op reads the following record
        LD HL,FCB.CPM.CR
        ADD HL,DE
        INC (HL)
        JR NZ,BDOS_FILE_CALL_1
        INC HL
        INC (HL)
        JR NZ,BDOS_FILE_CALL_1
        INC HL
        INC (HL)
; ----------------------------------------------------------------------
; BDOS_FILE_CALL_1 -- result-mapping arm for a read-random BDOS call.
;   In:        C = the BDOS function that was called; BDOS A-result saved on the stack.
;   Out:       A = mapped BASIC status (0 ok, 1 for code 3, 2 otherwise); errors jumped out above.
;   Clobbers:  A.
;   Algorithm: If the function was read-random ($22): success -> RET Z; code 5 -> Too many files;
;              code 3 (reading unwritten data) -> A=1 RET; any other -> A=2 RET. Non-random calls fall
;              to BDOS_FILE_CALL_2 which returns the raw result.
; ----------------------------------------------------------------------
BDOS_FILE_CALL_1:
        LD A,C
        ; only read-random ($22) results get translated to BASIC codes; others pass through
        CP $22
        JR NZ,BDOS_FILE_CALL_2
        POP AF
        OR A
        RET Z
        CP $05
        ; BDOS code 5 (no directory space) -> Too many files
        JP Z,RAISE_TOO_MANY_FILES
        CP $03
        LD A,$01
        RET Z
        INC A
        RET
; ----------------------------------------------------------------------
; BDOS_FILE_CALL_2 -- pass-through arm: return the raw BDOS result for non-read-random functions.
;   In:        BDOS A-result saved on the stack.
;   Out:       A = original BDOS result; RET.
;   Clobbers:  A.
;   Algorithm: Pop the saved BDOS A and return it unmodified.
; ----------------------------------------------------------------------
BDOS_FILE_CALL_2:
        POP AF
        RET
; ----------------------------------------------------------------------
; FILE_READ_RECORDS -- read DE bytes of a file as whole 128-byte sequential records into the data buffer.
;   In:        HL/DE describe the transfer: on entry EX DE,HL makes DE = byte/record count; PTRFIL = file.
;   Out:       successive 128-byte records read via BDOS into the file's buffer and copied out until the
;              count is exhausted.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: Check string space (STRING_SPACE_ROOM_CHECK); then loop: copy the current 128-byte record
;              out of FCB.SEQ_BUF, decrement the remaining count, bump the FCB current-record byte CR, set
;              DMA and BDOS F_READ the next record, until DE reaches zero.
; ----------------------------------------------------------------------
FILE_READ_RECORDS:
        EX DE,HL
        ; ensure free string space remains before buffering more file data
        CALL STRING_SPACE_ROOM_CHECK
        LD HL,(PTRFIL)
        PUSH HL
        LD BC,FCB.SEQ_BUF+1
        ADD HL,BC
; ----------------------------------------------------------------------
; FILE_READ_RECORDS_1 -- per-record body: copy one buffered record out and advance the file record cursor.
;   In:        HL -> file entry base (from PTRFIL, on stack), DE = records/bytes remaining.
;   Out:       128 bytes copied; DE decremented; FCB current-record (CR, offset $20) incremented.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: COPY_128_BLOCK out of the file buffer, decrement the count, then add the FCB.CPM.CR offset
;              ($21) to the entry base HL (=entry+$21 = CR at CPMFCB $20) and INC it so the next BDOS read
;              fetches the following record.
; ----------------------------------------------------------------------
FILE_READ_RECORDS_1:
        CALL COPY_128_BLOCK
        DEC DE
        POP HL
        LD BC,FCB.CPM.CR
        ADD HL,BC
        INC (HL)
; ----------------------------------------------------------------------
; FILE_READ_RECORDS_2 -- fetch the next 128-byte record from disk via BDOS read-sequential.
;   In:        DE = remaining count; PTRFIL = file entry.
;   Out:       one record read into the file's buffer at PTRFIL+1; A = BDOS status.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: Room-check string space, set DMA to the default buffer, point DE at the file buffer
;              (PTRFIL+1), BDOS F_READ, and fall into the count test.
; ----------------------------------------------------------------------
FILE_READ_RECORDS_2:
        CALL STRING_SPACE_ROOM_CHECK
        PUSH DE
        LD C,F_DMAOFF
        CALL BDOS
        LD HL,(PTRFIL)
        INC HL
        EX DE,HL
        ; BDOS read-sequential one 128-byte record into the file buffer
        LD C,F_READ
        CALL BDOS
        OR A
        POP DE
; ----------------------------------------------------------------------
; FILE_READ_RECORDS_3 -- loop test: stop on a short/last record, else fetch another.
;   In:        A = BDOS read status (NZ at EOF/short), DE = remaining count.
;   Out:       returns when the read hit end-of-file; otherwise loops to read the next record.
;   Clobbers:  DE, HL.
;   Algorithm: Advance the destination by 128 ($0080); if the last BDOS read returned non-zero (no more
;              data) RET, else swap and loop back to FILE_READ_RECORDS_2.
; ----------------------------------------------------------------------
FILE_READ_RECORDS_3:
        LD HL,$0080
        ADD HL,DE
        RET NZ
        EX DE,HL
        JR FILE_READ_RECORDS_2
; ----------------------------------------------------------------------
; STRING_SPACE_ROOM_CHECK -- guard that enough free string space remains before buffering more data.
;   In:        FRETOP = top of free string area; DE = the pointer about to be used.
;   Out:       RET if (FRETOP - $D6) >= DE (room ok); otherwise jumps to RUN_CLEAR_AND_GO (Out of string
;              space cleanup).
;   Clobbers:  A, BC, HL.
;   Algorithm: Compute FRETOP minus a $D6-byte safety margin (LD BC,$FF2A; ADD HL,BC) and compare to DE;
;              carry-clear (enough room) returns, else divert to the string-space exhaustion handler.
; ----------------------------------------------------------------------
STRING_SPACE_ROOM_CHECK:
        LD HL,(FRETOP)
        LD BC,$FF2A
        ADD HL,BC
        CALL CMP_HL_DE
        RET NC
        JP RUN_NO_FILENAME
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB_2 -- for a RANDOM file, parse the optional FIELD record/buffer argument and seed its cursors.
;   In:        A = the file MODE (CP $03 tests FCB_MODE_RANDOM); BC -> the file's FCB entry; HL = text pointer.
;   Out:       For a non-random file: returns immediately, HL unchanged (= continuation text pointer). For
;              random: FCB.FLD_BUF_PTR (+$A9) = the FIELD buffer pointer (DE; default $0080 or the parsed
;              value), the following 7 FIELD descriptor/position bytes zeroed, and HL = the post-argument
;              text pointer. FC if the pointer exceeds FIELD_BUF_ADDR_LIMIT.
;   Clobbers:  A, DE, HL.
;   Algorithm: If A != FCB_MODE_RANDOM ($03) RET NZ (sequential files take no FIELD arg). Otherwise step
;              back, CHRGET; if the next token is a number parse it (GETINT_CHRGET_POS) as the FIELD buffer
;              address, else default DE=$0080; verify DE <= FIELD_BUF_ADDR_LIMIT (else FC), store it as the
;              FIELD buffer pointer in the FCB, and zero the following 7 FIELD descriptor/position cells.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB_2:
        ; only a RANDOM-mode file (mode 3) reads the optional FIELD record/buffer argument; others return at once
        CP $03
        RET NZ
        DEC HL
        CALL CHRGET
        PUSH DE
        LD DE,$0080
        JR Z,FILE_NUM_TO_FCB_2_1
        PUSH BC
        CALL GETINT_CHRGET_POS
        POP BC
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB_2_1 -- common tail: validate the FIELD pointer and store it into the FCB.
;   In:        DE = FIELD buffer pointer (parsed or default $0080); BC -> FCB entry.
;   Out:       FCB.FLD_BUF_PTR set; following 7 FIELD bytes zeroed; HL/DE restored. FC on overflow.
;   Clobbers:  A, HL.
;   Algorithm: Compare FIELD_BUF_ADDR_LIMIT to DE (carry, i.e. limit<DE -> FC), write DE into
;              FCB.FLD_BUF_PTR, then fall into the zero-fill of the FIELD descriptor/position cursors.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB_2_1:
        PUSH HL
        ; [RE] range-check the FIELD buffer pointer against the configured buffer-address limit
        LD HL,(FIELD_BUF_ADDR_LIMIT)
        CALL CMP_HL_DE
        JP C,ERROR_FC
        ; store the FIELD buffer base pointer into the FCB
        LD HL,FCB.FLD_BUF_PTR
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        XOR A
        LD E,$07
; ----------------------------------------------------------------------
; FILE_NUM_TO_FCB_2_2 -- zero the FIELD descriptor/position cursor bytes after the buffer pointer.
;   In:        HL -> just past FCB.FLD_BUF_PTR, E = 7 (count), A = 0.
;   Out:       7 bytes (FIELD descriptor + record number + position pointers) cleared.
;   Clobbers:  E, HL.
;   Algorithm: Store 0 across the 7 FIELD bookkeeping bytes so a fresh FIELD/GET/PUT starts clean.
; ----------------------------------------------------------------------
FILE_NUM_TO_FCB_2_2:
        INC HL
        LD (HL),A
        DEC E
        JR NZ,FILE_NUM_TO_FCB_2_2
        POP HL
        POP DE
        RET
; ----------------------------------------------------------------------
; STMT_PUT -- PUT statement (token $BB): write a random-file record. GET (token $BA) enters one byte later at STMT_PUT+1.
;   In:        HL = text cursor; syntax PUT[#]filenum[,recordnum]. PUT runs OR $AF (A != 0 = write, NZ); GET runs the swallowed $AF = XOR A (A = 0 = read, Z).
;   Out:       The direction byte is latched in RND_GET_PUT_DIR; FILE_NUM_TO_FCB resolves the channel; falls into GET_PUT_RECORD_CORE which performs the transfer.
;   Clobbers:  A,BC,DE,HL.
;   Algorithm: Latch A (the direction) into RND_GET_PUT_DIR. The GET entry (Z) calls EVAL_CHANNEL_OR_ITEM (which parses the '#' channel); the PUT entry (NZ) skips that call. Then FILE_NUM_TO_FCB and fall into the shared record core. [RE] The exact reason only the GET entry calls EVAL_CHANNEL_OR_ITEM (the OR $AF/XOR A Z flag, not a 'channel already parsed' flag) is not fully explained by these bytes.
; ----------------------------------------------------------------------
STMT_PUT:
        OR $AF
        ; latch transfer direction: PUT=write (nonzero), GET=read (zero)
        LD (RND_GET_PUT_DIR),A
        CALL Z,EVAL_CHANNEL_OR_ITEM
        CALL FILE_NUM_TO_FCB
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE -- shared GET/PUT random-record engine: validate the file, resolve the record number, map it to a CP/M sector + offset, and read or write the FIELD window record.
;   In:        BC = FCB base, A = FCB mode byte, HL = text cursor; RND_GET_PUT_DIR already latched (0=GET/read, nonzero=PUT/write).
;   Out:       The requested record is transferred between the file's sector buffer (FCB.SEQ_BUF) and the FIELD window (FCB.RND_BUF); FCB.RND_RECNO updated to the record used; RET.
;   Clobbers:  A,BC,DE,HL; scratch words RND_SECTOR_NUM, RND_FIELD_PTR, RND_SECTOR_PTR.
;   Algorithm: Require mode 3 (random) else 'Bad file mode'. Default record = FCB.RND_RECNO+1; if a ',' follows parse an explicit record number (GETINT_CHRGET_POS), requiring end-of-statement after it. Reject record 0 ('Bad record number'); store the 1-based record back to FCB.RND_RECNO; convert to 0-based (DEC DE). Zero FCB.FLD_POS_PTR. [RE] Multiply the record length (FCB.FLD_BUF_PTR, read as a count) by (record-1) as a 16x16->32-bit product (GET_PUT_RECORD_CORE_2..8), splitting the byte offset into RND_SECTOR_NUM = offset/128 (the CP/M sector index) and DE = offset mod 128 (within-sector position). When the length equals 128 a shortcut sets DE=0 and skips the multiply (GET_PUT_RECORD_CORE_9). Then loop (GET_PUT_RECORD_CORE_10): set the FIELD pointer (RND_BUF base) and the sector pointer (SEQ_BUF + within-sector offset), copy min(bytes-left, 128-position) bytes between them in the latched direction, calling FIELD_WRITE_RECORD to flush/read each sector, until the whole record is transferred.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE:
        CP $03
        ; GET/PUT require a random (mode 3) file
        JP NZ,RAISE_BAD_FILE_MODE
        PUSH BC
        PUSH HL
        LD HL,FCB.RND_RECNO
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        ; default record = last record used + 1
        INC DE
        EX (SP),HL
        LD A,(HL)
        CP $2C
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_1 -- parse the optional explicit record number and validate the statement tail.
;   In:        A = current text char (',' if a record number is present), HL = text cursor, DE = default record.
;   Out:       DE = chosen record number; HL repositioned; 'Syntax error' if extra tokens follow.
;   Clobbers:  A,DE,HL.
;   Algorithm: If the char is ',' call GETINT_CHRGET_POS to read the record number into DE; then CHRGET must reach end-of-statement (else 'Syntax error').
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_1:
        ; ',' present -> read the explicit record number
        CALL Z,GETINT_CHRGET_POS
        DEC HL
        CALL CHRGET
        ; nothing else may follow the record number
        JP NZ,RAISE_SYNTAX_ERROR
        EX (SP),HL
        LD A,E
        OR D
        ; record numbers are 1-based; 0 is invalid
        JP Z,RAISE_BAD_RECORD_NUMBER
        DEC HL
        LD (HL),E
        INC HL
        LD (HL),D
        DEC DE
        POP HL
        POP BC
        PUSH HL
        PUSH BC
        LD HL,FCB.FLD_POS_PTR
        ADD HL,BC
        XOR A
        LD (HL),A
        INC HL
        LD (HL),A
        LD HL,FCB.FLD_BUF_PTR
        ADD HL,BC
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        EX DE,HL
        PUSH DE
        PUSH HL
        LD HL,$0080
        CALL CMP_HL_DE
        POP HL
        JR NZ,GET_PUT_RECORD_CORE_2
        LD DE,$0000
        JR GET_PUT_RECORD_CORE_9
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_2 -- record-offset multiply setup: prime a 32-bit shift-add product of the record length by the record index.
;   In:        DE = record length (from FCB.FLD_BUF_PTR), HL = (record-1) the 0-based record index.
;   Out:       BC = length (multiplicand), DE = record index (multiplier), HL=0 (product low) and a 0 word pushed (product high), A = 16 (iteration count); falls into the shift-add loop.
;   Clobbers:  A,BC,DE,HL, stack.
;   Algorithm: Copy the length into BC, set A=16, swap the index into DE, clear the low product word (HL) and push a zero high word -- a classic 16x16->32 binary multiply seed.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_2:
        LD B,D
        LD C,E
        ; 16-bit multiply: 16 shift-add iterations
        LD A,$10
        EX DE,HL
        LD HL,$0000
        PUSH HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_3 -- multiply loop top: shift the 32-bit partial product left by one bit.
;   In:        HL = product low word, stack top = product high word.
;   Out:       Product shifted left 1 bit (carry threaded low->high); continues into the multiplier-bit test.
;   Clobbers:  HL, stack.
;   Algorithm: ADD HL,HL on the low word, propagate carry into the high word on the stack (the +INC HL form when carry is set).
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_3:
        ADD HL,HL
        EX (SP),HL
        JR NC,GET_PUT_RECORD_CORE_4
        ADD HL,HL
        INC HL
        JR GET_PUT_RECORD_CORE_5
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_4 -- multiply loop: high-word shift, no carry-in case.
;   In:        Product high word in HL (just exchanged off the stack).
;   Out:       High word shifted left without the +1 carry bit; falls into the merge.
;   Clobbers:  HL.
;   Algorithm: ADD HL,HL only (carry-clear branch of the partial-product shift).
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_4:
        ADD HL,HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_5 -- multiply loop: shift the multiplier and conditionally add the multiplicand.
;   In:        Stack/HL hold the partial product; DE = multiplier, BC = multiplicand (record length).
;   Out:       If the multiplier's top bit was set, the multiplicand is added into the 32-bit product (with carry into the high word).
;   Clobbers:  A,DE,HL, stack.
;   Algorithm: Shift the multiplier (DE) left one bit; on a 1 bit add BC to the product low word and propagate carry into the high word; otherwise skip the add (GET_PUT_RECORD_CORE_7).
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_5:
        EX (SP),HL
        EX DE,HL
        ADD HL,HL
        EX DE,HL
        JR NC,GET_PUT_RECORD_CORE_7
        ; multiplier bit set -> add the record length into the product
        ADD HL,BC
        EX (SP),HL
        JR NC,GET_PUT_RECORD_CORE_6
        INC HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_6 -- multiply loop: carry the add into the product high word.
;   In:        Carry out of the low-word add; product high word on stack.
;   Out:       High word incremented when the add carried; rejoins the loop counter step.
;   Clobbers:  HL, stack.
;   Algorithm: EX (SP),HL to bring the high word into HL where the preceding INC HL applied the carry, then continue.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_6:
        EX (SP),HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_7 -- multiply loop counter and extraction of the within-sector offset.
;   In:        A = remaining iteration count; on loop end HL/stack hold the 32-bit product = record_index * record_length.
;   Out:       On loop end: DE = product & $7F (byte offset within a 128-byte sector); continues to derive the sector number.
;   Clobbers:  A,DE,HL.
;   Algorithm: DEC A and re-loop while non-zero. When done, mask the low product byte to 7 bits (offset mod 128) into DE and fall through to compute the sector index = offset / 128.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_7:
        DEC A
        JR NZ,GET_PUT_RECORD_CORE_3
        LD A,L
        ; byte position within the 128-byte sector = offset mod 128
        AND $7F
        LD E,A
        LD D,$00
        POP BC
        LD A,L
        LD L,H
        LD H,C
        ADD HL,HL
        JP C,ERROR_FC
        RLA
        JR NC,GET_PUT_RECORD_CORE_8
        INC HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_8 -- finish the sector-number derivation and overflow-check it.
;   In:        HL holds the realigned product bytes; B = the product's top byte.
;   Out:       HL = CP/M sector index (byte offset / 128); 'Illegal function call' if it overflows; falls into GET_PUT_RECORD_CORE_9.
;   Clobbers:  A,HL.
;   Algorithm: Realign the product bytes and shift right by 7 (byte-swap + ADD HL,HL + RLA carry-in) to obtain offset/128 in HL; if the carry out of ADD HL,HL or any remaining high byte (B) is non-zero the record is past the addressable limit -> FC error.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_8:
        LD A,B
        OR A
        ; record offset exceeds the addressable sector range
        JP NZ,ERROR_FC
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_9 -- latch the sector index and set up the FIELD-window pointer.
;   In:        HL = CP/M sector index for the record start, DE = within-sector byte offset; BC restored to the FCB base.
;   Out:       RND_SECTOR_NUM = sector index; RND_FIELD_PTR = FCB.RND_BUF base; falls into the per-sector transfer loop.
;   Clobbers:  HL, scratch words.
;   Algorithm: Store HL to RND_SECTOR_NUM, recover the FCB base, and record the FIELD-window pointer (RND_BUF) in RND_FIELD_PTR.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_9:
        ; RND_SECTOR_NUM = CP/M sector index of the field start
        LD (RND_SECTOR_NUM),HL
        POP HL
        POP BC
        PUSH HL
        LD HL,FCB.RND_BUF
        ADD HL,BC
        ; RND_FIELD_PTR = FIELD window base (RND_BUF)
        LD (RND_FIELD_PTR),HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_10 -- per-sector transfer loop top: point at the within-sector position and size this chunk.
;   In:        BC = FCB base, DE = within-sector byte offset, RND_FIELD_PTR set; the stack holds the field bytes still to transfer.
;   Out:       RND_SECTOR_PTR = FCB.SEQ_BUF + offset; HL = min(bytes-remaining, 128 - offset) = this iteration's byte count; dispatches the read or write path.
;   Clobbers:  A,DE,HL, scratch RND_SECTOR_PTR.
;   Algorithm: Compute the sector-buffer pointer (SEQ_BUF + within-sector offset) into RND_SECTOR_PTR; chunk = 128 - offset, clamped to the remaining field bytes; branch on RND_GET_PUT_DIR (GET -> GET_PUT_RECORD_CORE_15 read path; PUT -> the write path).
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_10:
        LD HL,FCB.SEQ_BUF
        ADD HL,BC
        ADD HL,DE
        ; RND_SECTOR_PTR = sector buffer (SEQ_BUF) + within-sector offset
        LD (RND_SECTOR_PTR),HL
        POP HL
        PUSH HL
        LD HL,$0080
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        POP DE
        PUSH DE
        CALL CMP_HL_DE
        JR C,GET_PUT_RECORD_CORE_11
        LD H,D
        LD L,E
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_11 -- PUT path: on a full-sector chunk, read the existing sector first, then size the copy.
;   In:        HL = this chunk's byte count, BC = FCB base.
;   Out:       If the chunk fills a whole 128-byte sector, the sector is first read in (FIELD_WRITE_RECORD+1); HL preserved as the chunk size.
;   Clobbers:  A,DE,HL, stack.
;   Algorithm: Read RND_GET_PUT_DIR; on the write path compare the chunk size with $0080 and, when it is a full sector, CALL FIELD_WRITE_RECORD+1 to load the existing sector before overwriting part of it.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_11:
        LD A,(RND_GET_PUT_DIR)
        OR A
        JR Z,GET_PUT_RECORD_CORE_15
        LD DE,$0080
        CALL CMP_HL_DE
        JR NC,GET_PUT_RECORD_CORE_12
        PUSH HL
        CALL FIELD_WRITE_RECORD+1
        POP HL
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_12 -- PUT path: set up the copy length for this sector chunk.
;   In:        HL = chunk byte count, BC = FCB base.
;   Out:       BC = chunk byte count for BLOCK_COPY_BC; FCB base saved on the stack; falls into the copy+flush step.
;   Clobbers:  BC, stack.
;   Algorithm: Save the FCB base, move the chunk count into BC for the block copier.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_12:
        PUSH BC
        LD B,H
        LD C,L
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_13 -- PUT path: copy FIELD-window bytes into the sector buffer and flush the sector.
;   In:        RND_SECTOR_PTR = dest (in the sector buffer), RND_FIELD_PTR = source (FIELD window), BC = chunk count.
;   Out:       Chunk copied; RND_FIELD_PTR advanced; FIELD_WRITE_RECORD invoked to write the sector when the boundary is crossed; falls into the loop-bottom bookkeeping.
;   Clobbers:  A,BC,DE,HL, scratch RND_FIELD_PTR.
;   Algorithm: Set DE=RND_SECTOR_PTR, HL=RND_FIELD_PTR, BLOCK_COPY_BC the chunk (field -> sector), store the advanced FIELD pointer back to RND_FIELD_PTR, restore BC=FCB base, then CALL FIELD_WRITE_RECORD to commit the sector.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_13:
        LD HL,(RND_SECTOR_PTR)
        EX DE,HL
        LD HL,(RND_FIELD_PTR)
        ; copy the FIELD-window bytes into the sector buffer
        CALL BLOCK_COPY_BC
        LD (RND_FIELD_PTR),HL
        LD D,B
        LD E,C
        POP BC
        ; advance the cursor and flush the sector when the boundary is reached
        CALL FIELD_WRITE_RECORD
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_14 -- per-sector loop bottom: subtract this chunk, advance the sector, and continue or finish.
;   In:        Stack top = field bytes remaining, DE = bytes transferred this chunk, RND_SECTOR_NUM = current sector.
;   Out:       Remaining count reduced; RND_SECTOR_NUM incremented; loops to GET_PUT_RECORD_CORE_10 while bytes remain, else cleans up the stack and RET.
;   Clobbers:  A,DE,HL, scratch RND_SECTOR_NUM.
;   Algorithm: remaining -= transferred; reset the within-sector offset (DE=0) for the next full sector; INC RND_SECTOR_NUM; re-loop if remaining != 0, otherwise pop the work frames and return.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_14:
        POP HL
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        OR L
        LD DE,$0000
        PUSH HL
        LD HL,(RND_SECTOR_NUM)
        ; advance to the next CP/M sector
        INC HL
        LD (RND_SECTOR_NUM),HL
        ; more field bytes -> transfer the next sector
        JR NZ,GET_PUT_RECORD_CORE_10
        POP HL
        POP HL
        RET
; ----------------------------------------------------------------------
; GET_PUT_RECORD_CORE_15 -- GET path: read the sector then copy its bytes into the FIELD window.
;   In:        HL = chunk byte count, BC = FCB base, RND_SECTOR_PTR = source (sector buffer), RND_FIELD_PTR = dest (FIELD window).
;   Out:       The disk sector is loaded (FIELD_WRITE_RECORD+1 read/no-flush entry), the chunk copied into the FIELD window, RND_FIELD_PTR advanced; rejoins the loop bottom.
;   Clobbers:  A,BC,DE,HL, scratch RND_FIELD_PTR.
;   Algorithm: CALL FIELD_WRITE_RECORD+1 to read the sector into the buffer, BLOCK_COPY_BC the chunk from RND_SECTOR_PTR -> RND_FIELD_PTR, store the advanced destination back to RND_FIELD_PTR (via EX DE,HL), and JR to GET_PUT_RECORD_CORE_14.
; ----------------------------------------------------------------------
GET_PUT_RECORD_CORE_15:
        PUSH HL
        ; GET: load the disk sector into the buffer (no-flush entry)
        CALL FIELD_WRITE_RECORD+1
        POP HL
        PUSH BC
        LD B,H
        LD C,L
        LD HL,(RND_FIELD_PTR)
        EX DE,HL
        LD HL,(RND_SECTOR_PTR)
        ; copy the sector bytes into the FIELD window
        CALL BLOCK_COPY_BC
        EX DE,HL
        LD (RND_FIELD_PTR),HL
        LD D,B
        LD E,C
        POP BC
        JR GET_PUT_RECORD_CORE_14
; ----------------------------------------------------------------------
; FIELD_WRITE_RECORD -- random-record sector-commit helper: advance the running sector cursor and, when it crosses the tracked boundary (or the flush flag forces it), dispatch the CP/M record read/write via PUTC_FILE_3. Entered at +1 (skip the OR $AF) for the read/no-flush variant.
;   In:        BC = FCB base; the running cursor lives in RND_SECTOR_NUM; full entry runs OR $AF (flush/write), entry+1 runs the swallowed XOR A (no-flush/read).
;   Out:       RND_WRITE_FLAG latched; FCB.FLD_DESC_PTR updated to the new cursor; on a boundary crossing (or with the flush flag set) PUTC_FILE_3 performs the record I/O; registers restored; RET.
;   Clobbers:  A,BC,DE,HL (PUSH/POP-saved around the body).
;   Algorithm: Latch the direction into RND_WRITE_FLAG. Save registers, then in FIELD_WRITE_RECORD_1 advance the cursor: read RND_SECTOR_NUM, compare (RND_SECTOR_NUM+1) against FCB.FLD_DESC_PTR, store the incremented cursor back into FCB.FLD_DESC_PTR. [RE] If they differ (boundary reached) OR the flush flag is set, dispatch the record I/O through PUTC_FILE_3 (passing FCB.SEQ_RECNO+1) which itself selects read vs write from RND_WRITE_FLAG; otherwise just return.
; ----------------------------------------------------------------------
FIELD_WRITE_RECORD:
        OR $AF
        ; latch direction: full entry = write/flush, +1 entry = read/no-flush
        LD (FIELD_WRITE_FLAG),A
        PUSH BC
        PUSH DE
        PUSH HL
; ----------------------------------------------------------------------
; FIELD_WRITE_RECORD_1 -- cursor-advance + boundary test inside FIELD_WRITE_RECORD.
;   In:        BC = FCB base; RND_SECTOR_NUM = current cursor; FCB.FLD_DESC_PTR = the previously-stored cursor/boundary.
;   Out:       FCB.FLD_DESC_PTR updated to (RND_SECTOR_NUM+1); the compare result and flush flag decide whether to commit the record.
;   Clobbers:  A,DE,HL.
;   Algorithm: DE = RND_SECTOR_NUM; read FCB.FLD_DESC_PTR into HL; INC DE; compare; write the incremented cursor (DE) back into FCB.FLD_DESC_PTR. If the compare matched (no crossing) and the flush flag (RND_WRITE_FLAG) is clear, skip the I/O (FIELD_WRITE_RECORD_3); otherwise dispatch the record I/O.
; ----------------------------------------------------------------------
FIELD_WRITE_RECORD_1:
        LD HL,(RND_SECTOR_NUM)
        EX DE,HL
        LD HL,FCB.FLD_DESC_PTR
        ADD HL,BC
        PUSH HL
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        INC DE
        CALL CMP_HL_DE
        POP HL
        LD (HL),E
        INC HL
        LD (HL),D
        JR NZ,FIELD_WRITE_RECORD_2
        ; no crossing; only commit if the flush flag is set
        LD A,(FIELD_WRITE_FLAG)
        OR A
        JR Z,FIELD_WRITE_RECORD_3
; ----------------------------------------------------------------------
; FIELD_WRITE_RECORD_2 -- commit one random-file record via the sequential record handler.
;   In:        BC = FCB base; the random record number is taken from FCB.SEQ_RECNO+1.
;   Out:       The sector buffer is read or written by PUTC_FILE_3 (direction from RND_WRITE_FLAG); returns to FIELD_WRITE_RECORD_3.
;   Clobbers:  A,BC,DE,HL.
;   Algorithm: Stage FIELD_WRITE_RECORD_3 as the return point and the FCB base on the stack, point HL at FCB.SEQ_RECNO+1, and JP PUTC_FILE_3 to perform the record I/O.
; ----------------------------------------------------------------------
FIELD_WRITE_RECORD_2:
        LD HL,FIELD_WRITE_RECORD_3
        PUSH HL
        PUSH BC
        PUSH HL
        LD HL,FCB.SEQ_RECNO+1
        ADD HL,BC
        ; read or write the sector for this record number (PUTC_FILE_3 picks the direction)
        JP PUTC_FILE_3
; ----------------------------------------------------------------------
; FIELD_WRITE_RECORD_3 -- FIELD_WRITE_RECORD epilogue: restore registers and return.
;   In:        Saved HL/DE/BC on the stack from the routine entry.
;   Out:       Registers restored; RET.
;   Clobbers:  none (restores).
;   Algorithm: POP HL/DE/BC; RET.
; ----------------------------------------------------------------------
FIELD_WRITE_RECORD_3:
        POP HL
        POP DE
        POP BC
        RET
; ----------------------------------------------------------------------
; BLOCK_COPY_BC -- copy BC bytes from (HL) to (DE) for FIELD/GET/PUT record buffering; preserves BC.
;   In:        HL = source, DE = destination, BC = byte count.
;   Out:       BC bytes copied; HL and DE advanced past the block; BC restored to its original value; RET.
;   Clobbers:  A,DE,HL (BC preserved via PUSH/POP).
;   Algorithm: Save BC, then a byte-at-a-time LD (HL)->(DE)/INC/DEC-BC loop until BC reaches 0, then restore BC. (Byte loop rather than LDIR because BC must survive the call.)
; ----------------------------------------------------------------------
BLOCK_COPY_BC:
        PUSH BC
; ----------------------------------------------------------------------
; BLOCK_COPY_BC_1 -- BLOCK_COPY_BC inner copy loop.
;   In:        HL = source, DE = dest, BC = remaining count.
;   Out:       Loops until BC=0.
;   Clobbers:  A,BC,DE,HL.
;   Algorithm: A=(HL); (DE)=A; INC HL; INC DE; DEC BC; repeat while B|C nonzero.
; ----------------------------------------------------------------------
BLOCK_COPY_BC_1:
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        DEC BC
        LD A,B
        OR C
        JR NZ,BLOCK_COPY_BC_1
        POP BC
        RET
; ----------------------------------------------------------------------
; PUTC_FILE_RANDOM -- random-mode byte-output entry from PUTC_FILE: place one character into the current random FIELD position, tracking the field cursor and print column.
;   In:        On stack: the caller's saved return/registers and the byte to output; HL = FCB base via PTRFIL; the file is mode 3.
;   Out:       The character is stored at FCB.FLD_POS_PTR+1 within the FIELD window, the position cursor advanced (FCB_STORE_POSPTR), and the output column (FCB.BUF_REM) updated; on a full buffer raises 'FIELD overflow'.
;   Clobbers:  A,BC,DE,HL (restores the caller's saved registers).
;   Algorithm: Reorder the stacked frame; compute remaining FIELD space (FILE_BUF_REMAIN_BC); if exhausted raise 'FIELD overflow'. Advance and store the position pointer (FCB_STORE_POSPTR), write the byte at FCB.FLD_POS_PTR+1+offset, and maintain FCB.BUF_REM: reset to 0 on CR, else increment by 1 when the char is printable (the ADD A,$E0 / ADC carry idiom, matching PUTC_FILE).
; ----------------------------------------------------------------------
PUTC_FILE_RANDOM:
        POP AF
        PUSH DE
        PUSH BC
        PUSH AF
        LD B,H
        LD C,L
        ; how many bytes of FIELD space remain
        CALL FILE_BUF_REMAIN_BC
        ; no room left in the FIELD buffer
        JP Z,RAISE_FIELD_OVERFLOW
        ; advance and save the FIELD write position
        CALL FCB_STORE_POSPTR
        LD HL,FCB.FLD_POS_PTR+1
        ADD HL,BC
        ADD HL,DE
        POP AF
        LD (HL),A
        PUSH AF
        LD HL,FCB.BUF_REM
        ADD HL,BC
        LD D,(HL)
        LD (HL),$00
        ; CR resets the print column; printable chars bump it
        CP $0D
        JR Z,PUTC_FILE_RANDOM_1
        ADD A,$E0
        LD A,D
        ADC A,$00
        LD (HL),A
; ----------------------------------------------------------------------
; PUTC_FILE_RANDOM_1 -- PUTC_FILE_RANDOM epilogue: restore registers and return.
;   In:        Saved AF/BC/DE/HL on the stack.
;   Out:       Caller's registers restored; RET.
;   Clobbers:  none (restores).
;   Algorithm: POP AF/BC/DE/HL; RET.
; ----------------------------------------------------------------------
PUTC_FILE_RANDOM_1:
        POP AF
        POP BC
        POP DE
        POP HL
        RET
; ----------------------------------------------------------------------
; GETC_FILE_RANDOM -- random-mode byte-input entry from GETC_FILE: fetch one character from the current random FIELD position.
;   In:        DE saved on entry; HL = FCB base via PTRFIL; the file is mode 3.
;   Out:       A = the byte at the current FIELD position; the position cursor advanced; on an exhausted buffer raises 'FIELD overflow'; flags reflect the byte (OR A); RET.
;   Clobbers:  A,BC,DE,HL (restores the caller's saved DE/HL/BC).
;   Algorithm: Compute remaining FIELD bytes (FILE_BUF_REMAIN); if none raise 'FIELD overflow'; advance/store the position pointer (FCB_STORE_POSPTR); read the byte at FCB.FLD_POS_PTR+1+offset and OR A to set flags; restore registers and RET.
; ----------------------------------------------------------------------
GETC_FILE_RANDOM:
        PUSH DE
        ; how many bytes of FIELD data remain to read
        CALL FILE_BUF_REMAIN
        ; FIELD buffer exhausted
        JP Z,RAISE_FIELD_OVERFLOW
        ; advance and save the FIELD read position
        CALL FCB_STORE_POSPTR
        LD HL,FCB.FLD_POS_PTR+1
        ADD HL,BC
        ADD HL,DE
        LD A,(HL)
        OR A
        POP DE
        POP HL
        POP BC
        RET
; ----------------------------------------------------------------------
; FCB_LOAD_BUFPTR -- load the word at FCB.FLD_BUF_PTR (offset $A9) into DE.
;   In:        BC = FCB base.
;   Out:       DE = the 16-bit value at FCB.FLD_BUF_PTR.
;   Clobbers:  HL,DE.
;   Algorithm: Point HL at FCB.FLD_BUF_PTR and fall into FCB_LOAD_POSPTR_1 to read the little-endian word into DE. [RE] This field holds the record length (a count), not an address, despite the include's 'buffer base pointer' name.
; ----------------------------------------------------------------------
FCB_LOAD_BUFPTR:
        LD HL,FCB.FLD_BUF_PTR
        JR FCB_LOAD_POSPTR_1
; ----------------------------------------------------------------------
; FCB_LOAD_POSPTR -- load the word at FCB.FLD_POS_PTR (offset $B0) into DE: the random read/write position index within the FIELD window.
;   In:        BC = FCB base.
;   Out:       DE = the 16-bit value at FCB.FLD_POS_PTR (a within-record byte index, used as FCB_base+$B1+pos for the data byte).
;   Clobbers:  HL,DE.
;   Algorithm: Point HL at FCB.FLD_POS_PTR and fall into FCB_LOAD_POSPTR_1.
; ----------------------------------------------------------------------
FCB_LOAD_POSPTR:
        LD HL,FCB.FLD_POS_PTR
; ----------------------------------------------------------------------
; FCB_LOAD_POSPTR_1 -- shared little-endian word loader: DE = word at FCB_base + (HL offset).
;   In:        BC = FCB base, HL = field offset within the FCB.
;   Out:       DE = the 16-bit value stored at that FCB field.
;   Clobbers:  HL,DE.
;   Algorithm: HL += BC; E = (HL); INC HL; D = (HL); RET.
; ----------------------------------------------------------------------
FCB_LOAD_POSPTR_1:
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        RET
; ----------------------------------------------------------------------
; FCB_STORE_POSPTR -- advance (INC DE) and store the FIELD current-position index (FCB.FLD_POS_PTR, offset $B0).
;   In:        BC = FCB base, DE = the position value to store after incrementing.
;   Out:       FCB.FLD_POS_PTR = DE+1; DE incremented.
;   Clobbers:  HL.
;   Algorithm: INC DE; point HL at FCB.FLD_POS_PTR; write E then D (little-endian); RET.
; ----------------------------------------------------------------------
FCB_STORE_POSPTR:
        INC DE
        LD HL,FCB.FLD_POS_PTR
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        RET
; ----------------------------------------------------------------------
; FILE_BUF_REMAIN -- set BC = FCB base (from HL) then test whether the FIELD buffer position has reached the record length.
;   In:        HL = FCB base.
;   Out:       Z set when the FIELD position index equals the record length (buffer used up); compare result in flags.
;   Clobbers:  A,BC,DE,HL.
;   Algorithm: Copy HL into BC, then fall into FILE_BUF_REMAIN_BC to compare the position index (FCB.FLD_POS_PTR) against the record length (FCB.FLD_BUF_PTR).
; ----------------------------------------------------------------------
FILE_BUF_REMAIN:
        LD B,H
        LD C,L
; ----------------------------------------------------------------------
; FILE_BUF_REMAIN_BC -- FIELD position-vs-length test with BC already = FCB base.
;   In:        BC = FCB base.
;   Out:       Flags from comparing FCB.FLD_POS_PTR vs FCB.FLD_BUF_PTR; Z when the position index has reached the record length (buffer full/exhausted).
;   Clobbers:  A,DE,HL.
;   Algorithm: Load the position index (FCB_LOAD_POSPTR) and the record length (FCB_LOAD_BUFPTR), arrange them in HL/DE, and CMP_HL_DE to set the zero/carry result the random-I/O entries use to detect FIELD overflow/exhaustion.
; ----------------------------------------------------------------------
FILE_BUF_REMAIN_BC:
        CALL FCB_LOAD_POSPTR
        PUSH DE
        CALL FCB_LOAD_BUFPTR
        EX DE,HL
        POP DE
        ; position index vs record length -> Z when the FIELD buffer is full/used up
        CALL CMP_HL_DE
        RET
; ----------------------------------------------------------------------
; SAVE_PROTECTED_PROGRAM -- SAVE ... ,P entry: write the current program to disk in obfuscated ('protected') form.
;   In:        HL = text cursor after the ',P' option; the program occupies the text area; the output file is already open (STMT_SAVE opened it with D=2).
;   Out:       The program is transformed in place, written via SAVE_WRITE_PROGRAM with the $FE 'protected' file tag, then transformed back to its plain in-memory form; JP RESET_RUN_STATE_1.
;   Clobbers:  A,BC,DE,HL and program memory (the two transforms are reversible in place).
;   Algorithm: CHRGET past the option, save the cursor (L_0B54), fix up line references (RENUM_PATCH_LINEREFS), CALL PROG_UNSCRAMBLE, SAVE_WRITE_PROGRAM with A=$FE (protected file type), CALL PROG_SCRAMBLE, then JP RESET_RUN_STATE_1. [RE] The code calls PROG_UNSCRAMBLE *before* the write and PROG_SCRAMBLE *after*; the encode/decode roles of those two routines are labeled elsewhere and not re-verified here -- the order of calls (UNSCRAMBLE, write, SCRAMBLE) is what is observed.
;   Note: This is NOT part of the random-file FIELD cluster -- it is the protected-SAVE path reached by JP Z,FILE_BUF_REMAIN_BC_1 from STMT_SAVE (CP $50 = 'P'), physically adjacent to FILE_BUF_REMAIN_BC and mis-chained as its _1 local.
; ----------------------------------------------------------------------
SAVE_PROTECTED_PROGRAM:
        CALL CHRGET
        LD (OPEN_RESUME_TEXT_PTR),HL
        CALL RENUM_PATCH_LINEREFS
        ; transform the in-memory program before writing the protected copy
        CALL PROG_UNSCRAMBLE
        LD A,$FE
        ; write the program with the $FE protected-file tag
        CALL SAVE_WRITE_PROGRAM
        ; transform the in-memory program back to its plain running form
        CALL PROG_SCRAMBLE
        JP RESET_RUN_STATE_1
; ----------------------------------------------------------------------
; PROG_UNSCRAMBLE -- decode a protected (SAVE ",P") program image in place to runnable tokens.
;   In:        TXTTAB = program start, VARTAB = program end; the program bytes are encoded.
;   Out:       the program text from TXTTAB..VARTAB decoded in place; RET when the end is reached.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: MS BASIC-80 protected-program cipher. Two rotating key indices B (starts 13, cycles 13) and
;              C (starts 11, cycles 11) walk independently; B indexes the SIN coefficient table and C indexes
;              the ATN coefficient table. For each program byte: b = ((byte - B) XOR atn_key[C]); then
;              b = (b XOR sin_key[B]) + C; store b; then C decrements (wrapping 0->reload 11) and B
;              decrements (wrapping 0->reload 13). The FP polynomial coefficient tables double as cipher
;              keys -- their raw bytes, not their FP value, matter here. PROG_SCRAMBLE is the exact inverse.
; ----------------------------------------------------------------------
PROG_UNSCRAMBLE:
        LD BC,$0D0B
        LD HL,(TXTTAB)
        EX DE,HL
; ----------------------------------------------------------------------
; PROG_UNSCRAMBLE_1 -- decode-loop body: test for program end, then decode one byte with the dual key.
;   In:        DE -> current program byte, B/C = the two rotating key indices.
;   Out:       RET when DE == VARTAB (whole program decoded); else one byte decoded and DE advanced.
;   Clobbers:  A, HL (and updates the byte at DE).
;   Algorithm: Compare DE to VARTAB (end); if equal return; otherwise apply (byte-B) XOR atn[C], then
;              XOR sin[B], then +C, and store; fall into the key-index update.
; ----------------------------------------------------------------------
PROG_UNSCRAMBLE_1:
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        RET Z
        ; first key stream: index the ATN coefficient bytes by C
        LD HL,FP_POLY_ATN_COEFFS
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,$00
        LD H,A
        LD A,(DE)
        SUB B
        XOR (HL)
        PUSH AF
        ; second key stream: index the SIN coefficient bytes by B
        LD HL,FP_POLY_SIN_COEFFS
        LD A,L
        ADD A,B
        LD L,A
        LD A,H
        ADC A,$00
        LD H,A
        POP AF
        XOR (HL)
        ADD A,C
        ; store the decoded program byte back in place
        LD (DE),A
        INC DE
        DEC C
        JR NZ,PROG_UNSCRAMBLE_2
        LD C,$0B
; ----------------------------------------------------------------------
; PROG_UNSCRAMBLE_2 -- advance the dual key indices (B cycles 13, C cycles 11) for the next byte.
;   In:        B, C = key indices.
;   Out:       C decremented (reloaded to 11 at 0), B decremented (reloaded to 13 at 0); loops to decode next.
;   Clobbers:  B, C.
;   Algorithm: Step both rotating counters with wrap-around so the two key streams cycle at periods 11 and
;              13, then re-enter the decode loop.
; ----------------------------------------------------------------------
PROG_UNSCRAMBLE_2:
        DEC B
        JR NZ,PROG_UNSCRAMBLE_1
        LD B,$0D
        JR PROG_UNSCRAMBLE_1
; ----------------------------------------------------------------------
; PROG_SCRAMBLE -- re-encode the in-memory program for protected (SAVE ",P") storage; inverse of UNSCRAMBLE.
;   In:        TXTTAB = program start, VARTAB = program end; program is in plain token form.
;   Out:       the program text encoded in place; RET at the end.
;   Clobbers:  A, BC, DE, HL.
;   Algorithm: Exact inverse of PROG_UNSCRAMBLE using the same two key streams in mirrored order: for each
;              byte, b = ((byte - C) XOR sin_key[B]); then b = (b XOR atn_key[C]) + B; store; then step C
;              (cycle 11) and B (cycle 13). Produces the encoded image written by a protected SAVE so a LIST
;              cannot reveal it.
; ----------------------------------------------------------------------
PROG_SCRAMBLE:
        LD BC,$0D0B
        LD HL,(TXTTAB)
        EX DE,HL
; ----------------------------------------------------------------------
; PROG_SCRAMBLE_1 -- encode-loop body: end test then encode one byte with the dual key.
;   In:        DE -> current program byte, B/C = rotating key indices.
;   Out:       RET at VARTAB; else one byte encoded, DE advanced.
;   Clobbers:  A, HL (and the byte at DE).
;   Algorithm: Compare DE to VARTAB; if at end return; else (byte-C) XOR sin[B], XOR atn[C], +B, store;
;              fall into the key-index update.
; ----------------------------------------------------------------------
PROG_SCRAMBLE_1:
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        RET Z
        ; first key stream (encode swaps the two): index SIN coefficient bytes by B
        LD HL,FP_POLY_SIN_COEFFS
        LD A,L
        ADD A,B
        LD L,A
        LD A,H
        ADC A,$00
        LD H,A
        LD A,(DE)
        SUB C
        XOR (HL)
        PUSH AF
        ; second key stream: index ATN coefficient bytes by C
        LD HL,FP_POLY_ATN_COEFFS
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,$00
        LD H,A
        POP AF
        XOR (HL)
        ADD A,B
        LD (DE),A
        INC DE
        DEC C
        JR NZ,PROG_SCRAMBLE_2
        LD C,$0B
; ----------------------------------------------------------------------
; PROG_SCRAMBLE_2 -- advance the dual key indices for the encoder (C cycles 11, B cycles 13).
;   In:        B, C = key indices.
;   Out:       C stepped (reload 11), B stepped via DJNZ (reload 13); loops to encode the next byte.
;   Clobbers:  B, C.
;   Algorithm: Step both rotating counters with wrap-around (mirroring PROG_UNSCRAMBLE_2) so encode and
;              decode use identical key cycles.
; ----------------------------------------------------------------------
PROG_SCRAMBLE_2:
        DJNZ PROG_SCRAMBLE_1
        LD B,$0D
        JR PROG_SCRAMBLE_1
; [RE] RET unless SAVTXT ($0844) == $FFFF, in which case fall into the function-call guard.
DIRECT_MODE_GUARD:
        PUSH HL
        LD HL,(SAVTXT)
        LD A,H
        AND L
        POP HL
        INC A
        RET NZ
; [RE] Illegal-direct guard: if the 'running a program' flag ($0C99) is clear -> $0D5C (Illegal direct), else RET preserving AF. Statements that need a stored line call here.
ILLEGAL_DIRECT_CHECK:
        PUSH AF
        LD A,(L_0C99)
        OR A
        JP NZ,ERROR_FC
        POP AF
        RET
RND_SECTOR_NUM:
        NOP
        NOP
RND_FIELD_PTR:
        NOP
        NOP
RND_SECTOR_PTR:
        NOP
        NOP
RND_GET_PUT_DIR:
        NOP

; ======================================================================
; COLD / WARM START + SIGN-ON
; ======================================================================
; [RE] Warm-start (READY/Ok) re-entry: re-init the program-end sentinel ($0846), then enter the direct-mode main loop. ILLEGAL_DIRECT_CHECK_6 ($81C6) falls through to the immediate-statement executor at $0E23 if the start-up command pointer ($0850/$8350) is non-empty, else jumps to NEWSTT.
WARM_START:
        CALL RUN_CLEAR
        LD HL,(TXTTAB)
        DEC HL
        LD (HL),$00
        LD HL,(COLD_SET_WIDTH_11)
        LD A,(HL)
        OR A
        JP NZ,LOAD_PROGRAM
        JP NEWSTT_READY
SUB_81C6_1:
        NOP
        NOP
; [RE] Interpreter cold-start entry (the $1000 relocator JPs here after copying the body up to $3000). Initializes the runtime: BDOS handshake, RAM-top, the BASIC work cells, the RPC trigger patch (see $8240), and the console width from the SoftCard card config (see $827A).
COLD_START:
        LD HL,COLD_STACK_BASE
        LD SP,HL
        XOR A
        LD (L_0C99),A
        LD (TOP_OF_STACK_ROOM),HL
        LD (SAVSTK),HL
        LD HL,($0001)
        LD (STMT_SYSTEM_WBOOT+1),HL
        LD A,H
        LD ($0107),A
        LD BC,$0004
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (INKEY_SCAN_2+1),HL
        LD (RPC_CONST_POLL_1+1),HL
        LD (STMT_FOR_8+1),HL
        EX DE,HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (CONIN_1+1),HL
        EX DE,HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (OUTDO_DEVICE2_1+1),HL
        EX DE,HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (OUTDO_DEVICE_1+1),HL
        EX DE,HL
        LD DE,$F1F8
        ADD HL,DE
        LD DE,DISK_RAISE_DISK_I_O_ERROR
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD DE,DISK_RAISE_DRIVE_SELECT_ERROR
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD DE,DISK_RAISE_DISK_READ_ONLY
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD DE,DISK_RAISE_FILE_READ_ONLY
        LD (HL),E
        INC HL
        LD (HL),D
        LD HL,DISK_RAISE_RESET_ERROR
        LD ($0001),HL
        LD HL,(Z_CPU)
        LD (RPC_TRIGGER_STORE+1),HL
        LD C,S_BDOSVER
        CALL BDOS
        LD (L_08CB),A
        OR A
        LD HL,$1514
        JP Z,SUB_8240_1
        LD HL,$2221
SUB_8240_1:
        LD (BDOS_FN_RECREAD),HL
        LD HL,$FFFE
        LD (SAVTXT),HL
        XOR A
        LD (CTRL_O_SUPPRESS),A
        LD (L_0B10),A
        LD (CHAIN_BREAK_FLAG),A
        LD (CHAIN_PRESERVE_FLAG),A
        LD (ERRFLG),A
        LD HL,$0000
        LD (OUTPUT_COLUMN),HL
        LD (COLOR),A
        LD A,(SLTTYP3)
        SUB $03
        JR Z,COLD_SET_WIDTH+1
        DEC A
        JR Z,COLD_SET_WIDTH+1
        LD A,$28
; [RE] Select terminal line width during cold start: reads the configured console type ($F3BB) and sets the line-width work cell (GFX_READ_COORD_PAIR_12, $4B97) to 40 ($28) or the wide default, then initializes the file-control / disk-parameter pointers (WIDTH_SET_CONSOLE).
; [RE] 40/80 line-width flag-skip. Default console falls through $8284 LD A,$28 (40), and 01 at $8286 swallows 3E 50 so A stays $28. JR Z,COLD_SET_WIDTH+1 ($827F/$8282, console type 3/4) enters $8287 = LD A,$50 (80). Converge at $8289 store of the width cell.
COLD_SET_WIDTH:
        LD BC,$503E
        LD (GFX_STMT_HPLOT_9),A
        CALL WIDTH_SET_CONSOLE
        LD HL,$0080
        LD (FIELD_BUF_ADDR_LIMIT),HL
        LD HL,TEMPST
        LD (TEMPPT),HL
        LD HL,L_0B91
        LD (L_0BF9),HL
        LD HL,($0006)
        LD (MEMSIZ),HL
        LD A,$03
        LD (MAX_FILE_NUM),A
        LD HL,COLD_SET_WIDTH_10
        LD (COLD_SET_WIDTH_11),HL
        LD A,(COLD_SET_WIDTH_12)
        OR A
        JP NZ,COLD_SET_WIDTH_13
        INC A
        LD (COLD_SET_WIDTH_12),A
        LD HL,$0080
        LD A,(HL)
        OR A
        LD (COLD_SET_WIDTH_11),HL
        JP Z,COLD_SET_WIDTH_13
        LD B,(HL)
        INC HL
COLD_SET_WIDTH_1:
        LD A,(HL)
        DEC HL
        LD (HL),A
        INC HL
        INC HL
        DEC B
        JP NZ,COLD_SET_WIDTH_1
        DEC HL
        LD (HL),$00
        LD (COLD_SET_WIDTH_11),HL
        LD HL,$007F
        CALL CHRGET
        OR A
        JP Z,COLD_SET_WIDTH_13
        CP $2F
        JR Z,COLD_SET_WIDTH_3
        DEC HL
        LD (HL),$22
        LD (COLD_SET_WIDTH_11),HL
        INC HL
COLD_SET_WIDTH_2:
        CP $2F
        JR Z,COLD_SET_WIDTH_3
        CALL CHRGET
        OR A
        JR NZ,COLD_SET_WIDTH_2
        JP COLD_SET_WIDTH_13
COLD_SET_WIDTH_3:
        LD (HL),$00
COLD_SET_WIDTH_4:
        CALL CHRGET
COLD_SET_WIDTH_5:
        CP $53
        JR Z,COLD_SET_WIDTH_9
        CP $4D
        PUSH AF
        JP Z,COLD_SET_WIDTH_6
        CP $46
        JP NZ,RAISE_SYNTAX_ERROR
COLD_SET_WIDTH_6:
        CALL CHRGET
        CALL SYNCHR
        DEFB    ':'                      ; inline char arg consumed by the preceding CALL
        CALL LINGET_OR_AMP
        POP AF
        JR Z,COLD_SET_WIDTH_7
        LD A,D
        OR A
        JP NZ,ERROR_FC
        LD A,E
        CP $10
        JP NC,ERROR_FC
        LD (MAX_FILE_NUM),A
        JR COLD_SET_WIDTH_8
COLD_SET_WIDTH_7:
        EX DE,HL
        LD (MEMSIZ),HL
        EX DE,HL
COLD_SET_WIDTH_8:
        DEC HL
        CALL CHRGET
        JR Z,COLD_SET_WIDTH_13
        CALL SYNCHR
        DEFB    '/'                      ; inline char arg consumed by the preceding CALL
        JP COLD_SET_WIDTH_5
COLD_SET_WIDTH_9:
        CALL CHRGET
        CALL SYNCHR
        DEFB    ':'                      ; inline char arg consumed by the preceding CALL
        CALL LINGET_OR_AMP
        EX DE,HL
        LD (FIELD_BUF_ADDR_LIMIT),HL
        EX DE,HL
        JR COLD_SET_WIDTH_8
COLD_SET_WIDTH_10:
        NOP
COLD_SET_WIDTH_11:
        NOP
        NOP
COLD_SET_WIDTH_12:
        NOP
COLD_SET_WIDTH_13:
        DEC HL
        LD HL,(MEMSIZ)
        PUSH HL
        POP HL
        DEC HL
        LD (MEMSIZ),HL
        DEC HL
        PUSH HL
        LD A,(MAX_FILE_NUM)
        LD HL,SUB_81C6_1
        LD (FILTAB_SLOT0_SEED),HL
        LD DE,FILTAB
        LD (MAX_FILE_NUM),A
        INC A
        LD BC,FCB.FLD_BUF_PTR
COLD_SET_WIDTH_14:
        EX DE,HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        EX DE,HL
        ADD HL,BC
        PUSH HL
        LD HL,(FIELD_BUF_ADDR_LIMIT)
        LD BC,FCB.RND_BUF
        ADD HL,BC
        LD B,H
        LD C,L
        POP HL
        DEC A
        JR NZ,COLD_SET_WIDTH_14
        INC HL
        LD (TXTTAB),HL
        LD (SAVSTK),HL
        POP DE
        LD A,E
        SUB L
        LD L,A
        LD A,D
        SBC A,H
        LD H,A
        JP C,CHECK_STACK_ROOM_1
        LD B,$03
COLD_SET_WIDTH_15:
        OR A
        LD A,H
        RRA
        LD H,A
        LD A,L
        RRA
        LD L,A
        DJNZ COLD_SET_WIDTH_15
        LD A,H
        CP $02
        JR C,COLD_SET_WIDTH_16
        LD HL,$0200
COLD_SET_WIDTH_16:
        LD A,E
        SUB L
        LD L,A
        LD A,D
        SBC A,H
        LD H,A
        JP C,CHECK_STACK_ROOM_1
        LD (MEMSIZ),HL
        EX DE,HL
        LD (TOP_OF_STACK_ROOM),HL
        LD (FRETOP),HL
        LD SP,HL
        LD (SAVSTK),HL
        LD HL,(TXTTAB)
        EX DE,HL
        CALL GC_CHECK_AND_COLLECT
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        DEC HL
        DEC HL
        PUSH HL
        CALL GFX_STMT_HOME
        LD HL,SIGNON_BANNER_HEADER
        CALL STROUT
        POP HL
        CALL FOUT
        LD HL,MSG_BYTES_FREE
        CALL STROUT
        LD HL,STROUT
        LD (STROUT_CALL_VECTOR),HL
        CALL CRLF
        LD HL,SUB_0D28
        LD ($0101),HL
        JP WARM_START
        DEFB    "\r\n\n"
        DEFB    "Owned by Microsoft"     ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n\0"
; Data string ' Bytes free'+CRLF -- free-memory suffix printed after the byte count in the cold sign-on banner (loaded at $83DF, emitted via STROUT)
MSG_BYTES_FREE:
        DEFB    " Bytes free"            ; string
        DEFB    $0D                      ; terminator
        DEFB    "\n\0"
; Data string: leading sign-on banner text (CRLF CRLF CRLF then 'BASIC-80 ...'), printed first by COLD_SIGNON ($83D5 LD HL,$841D / STROUT) ahead of the free-bytes count
SIGNON_BANNER_HEADER:
        DEFB    "\r\n\r\n\r\nBASIC-80 Rev"
        DEFB    ". 5.2\r\n[Apple CP/M Version]\r\nCopyright (C) 1980 by Micro"
        DEFB    "soft\r\nCreated: 26-Aug-80\r\n\0"
        DEFB    "\0"
; [RE] Top of the relocated interpreter (LDDR copy boundary): the $1000 relocator copies INTERP_RUN_START..INTERP_COPY_END-1 ($3000-$8482) up from the load image. $8483-$84F1 is dead .COM padding (not copied).
INTERP_COPY_END:
        DEFS    69, $00                  ; fill
; [RE] Cold-start stack base: cold start does LD SP,COLD_STACK_BASE ($81D6) and seeds the stack-room pointer (TOP_OF_STACK_ROOM $0842) and SAVSTK from it, then resizes the work-area from CP/M memory top ($0001). The byte here is $00 (head of the 42-byte zero fill) and doubles as the link-null sentinel before program text, so TXTTAB = COLD_STACK_BASE+1.
COLD_STACK_BASE:
        DEFS    42, $00                  ; fill
INTERP_RUN_TOP:
    IFDEF GBASIC
    ENT
    ENDIF

    IFDEF GBASIC
    SAVEBIN "GBASIC.bin", $0100, $6400
    ELSE
    SAVEBIN "MBASIC.bin", $0100, $6000
    ENDIF
