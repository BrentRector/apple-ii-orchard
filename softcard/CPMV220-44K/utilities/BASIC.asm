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
; [RE] CRUNCH keyword-detect flag-skip (NOT a dispatch-table ref). $30E9 LD BC,CRUNCH_16+1 / PUSH BC arms $311A (LD A,$01) as the return for the CP nn / RET Z chain (sets A=1 on a separator-implying token). Fall-through: $3118 XOR A (Z) makes $3119 C2 3E 01 (JP NZ,$013E) a dead branch into $311C LD ($0B16),A with A=0. The cover IS executed; $013E merely coincides with STMT_DISPATCH_TBL+54 (STMT_LLIST) and is never used as a pointer.
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
        DEFW    OPEN_NAMED_FILE_1+1
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
        DEFW    FN_LOF
        DEFW    FN_LOF_1+1
        DEFW    FN_LOF_2+1
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
; [RE] PTRFIL: 16-bit pointer to the current file's FCB (MS BASIC PTRFIL). 0 = console/keyboard; nonzero = the FCB base of the file currently selected by a #file expression. Set by STORE_CUR_FCB_PTR ($7623-$7629, = the FCB pointer that FILE_NUM_TO_FCB resolved) for PRINT#/INPUT#/WRITE#/GET/PUT; cleared to 0 by the PRINT/INPUT epilogue ($3886) and CHAIN/OPEN reinit ($0F33). Read as a pointer (LD HL,(PTRFIL); LD A,H; OR L) by OUTCHR ($6615) and the per-PRINT-item path ($3788) to route a char to the file (FN_LOF_VALUE_1) instead of the console, and by INCHR ($6725) to read the next char from the file (GETC_FILE_EOF) instead of the keyboard. OBSERVED: every one of the 28 accesses is a 16-bit word move, never a bit/mask test, so this is a pointer, not a boolean redirect flag.
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
L_084C:
        DEFB    "\0\0"
; [RE] Seed pointer for slot 0 of the file/FOR-slot pointer array at $0850: cold-start loads it with the warm-start re-entry MAIN_LOOP_ENTRY_1 ($81D1) and the CHAIN/OPEN reinit copies $084E into $0850/$0840 after CLEAR_VARS. Effectively the default first-slot/command pointer.
FILTAB_SLOT0_SEED:
        DEFB    "\0\0"
; [RE] File/FOR-slot pointer array (MS BASIC FILTAB), indexed by max-open-files ($0870); each entry points at an FCB base. Slot 0 doubles as the deferred start-up command pointer consulted at the Ok/main-loop entry ($81D1). 126-byte region.
FILTAB:
        DEFS    32, $00                  ; fill
L_0870:
        DEFB    "\0"
L_0871:
        DEFB    "\0"
L_0872:
        DEFS    38, $00                  ; fill
L_0898:
        DEFB    "\0\0"
L_089A:
        DEFS    16, $00                  ; fill
L_08AA:
        DEFB    "\0"
L_08AB:
        DEFS    8, $00                   ; fill
L_08B3:
        DEFB    "\0\0\0"
L_08B6:
        DEFS    21, $00                  ; fill
L_08CB:
        DEFB    "\0"
L_08CC:
        DEFB    "\0"
L_08CD:
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
L_0B14:
        DEFB    "\0"
; [RE] CRUNCH_LITERAL_MODE: CRUNCH literal-passthrough flag (whole-byte boolean, no mask). Cleared at CRUNCH entry ($3004); set to 1 at $3201 right after emitting a ':' statement-separator or a DATA-class token; tested at CRUNCH_1 ($301C, OR A / JP NZ) -- when set, the current source character is copied through verbatim instead of being reserved-word-matched. TEMPORALLY REUSED (not concurrent) by FRMEVL as the binary-operator scratch: FRMEVL_OPCOMBINE writes the operator code here ($3B54) and the operator-dispatch index reads it ($3BA9). Same byte, different tenant at a different phase.
CRUNCH_LITERAL_MODE:
        DEFB    "\0"
; [RE] CRUNCH_LINENUM_MODE: CRUNCH line-number-introducer flag (whole-byte boolean, no mask). Set to 1 when the token just crunched is a keyword that is followed by a line number (GOTO/GOSUB/THEN/ELSE/RUN/LIST/RESTORE/etc.; armed via CRUNCH_16 $311C) and after ':' ($3204); cleared at CRUNCH entry ($3001) and $30D3. Tested at CRUNCH_18 ($314B, OR A / JR Z): when set, a following digit run is emitted as a line-number constant (token $0E + 2-byte line number via LINGET, $315C) instead of being parsed as an ordinary numeric literal (FIN at $3179).
CRUNCH_LINENUM_MODE:
        DEFB    "\0"
L_0B17:
        DEFB    "\0\0"
L_0B19:
        DEFB    "\0"
L_0B1A:
        DEFB    "\0"
L_0B1B:
        DEFB    "\0\0"
L_0B1D:
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
L_0B52:
        DEFB    "\0"
L_0B53:
        DEFB    "\0"
L_0B54:
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
L_0C6D:
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
L_0C97:
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
L_0CB1:
        DEFB    "\0\0"
L_0CB3:
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
        CALL LOAD_FINISH_CLOSE_CUR
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
; MS BASIC-80 CRUNCH: tokenizes an input line. Scans the source text, folds reserved words to single-byte tokens via the reserved-word name table (DE=$08CF/$04D8 reserved-word pointers), passes through string literals ($22) and REM/DATA text verbatim, and emits the crunched line. Handles the GOTO/GOSUB ('GO TO'/'GO SUB') two-word forms. $0B15/$0B16 are CRUNCH mode flags.
CRUNCH:
        XOR A
        LD (CRUNCH_LINENUM_MODE),A
        LD (CRUNCH_LITERAL_MODE),A
        LD BC,$013B
        LD DE,KBUF
CRUNCH_1:
        LD A,(HL)
        CP $22
        JP Z,CRUNCH_34
        CP $20
        JP Z,CRUNCH_30
        OR A
        JP Z,CRUNCH_36
        LD A,(CRUNCH_LITERAL_MODE)
        OR A
        LD A,(HL)
        JP NZ,CRUNCH_30
        CP $3F
        LD A,$91
CRUNCH_2:
        PUSH DE
        PUSH BC
        JP Z,CRUNCH_14
        LD DE,RESWORD_OPS
        CALL CHRGET_UPCASE
        CALL IS_LETTER_A
        JP C,CRUNCH_17
        PUSH HL
        LD BC,CRUNCH_RESWORD_TAIL
        PUSH BC
        CP $47
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        CP $4F
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        CP $20
        RET NZ
        INC HL
CRUNCH_3:
        CALL CHRGET_UPCASE
        INC HL
        CP $20
        JR Z,CRUNCH_3
        CP $53
        JR Z,CRUNCH_4
        CP $54
        RET NZ
        CALL CHRGET_UPCASE
        CP $4F
        LD A,TOK_GOTO
        JR CRUNCH_5
CRUNCH_4:
        CALL CHRGET_UPCASE
        CP $55
        RET NZ
        INC HL
        CALL CHRGET_UPCASE
        CP $42
        LD A,$8D
CRUNCH_5:
        RET NZ
        POP BC
        POP BC
        JP CRUNCH_14
; [RE] CRUNCH continuation reached via LD BC,$307C/PUSH BC/RET: finishes tokenizing the reserved word that IS_LETTER_A matched, emitting its token byte via CRUNCH_EMIT and looping back to CRUNCH_1.
CRUNCH_RESWORD_TAIL:
        POP HL
        CALL CHRGET_UPCASE
        PUSH HL
        LD HL,RESWORD_INDEX
        SUB $41
        ADD A,A
        LD C,A
        LD B,$00
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        POP HL
        INC HL
CRUNCH_7:
        PUSH HL
CRUNCH_8:
        CALL CHRGET_UPCASE
        LD C,A
        LD A,(DE)
        AND $7F
        JP Z,CRUNCH_EMIT_2
        INC HL
        CP C
        JR NZ,CRUNCH_11
        LD A,(DE)
        INC DE
        OR A
        JP P,CRUNCH_8
        LD A,C
        CP $28
        JR Z,CRUNCH_10
        LD A,(DE)
        CP $E2
        JR Z,CRUNCH_10
        CP $E1
        JR Z,CRUNCH_10
        CALL CHRGET_UPCASE
        CP $2E
        JR Z,CRUNCH_9
        CALL IS_ALNUM_CHAR
CRUNCH_9:
        LD A,$00
        JP NC,CRUNCH_EMIT_2
CRUNCH_10:
        POP AF
        LD A,(DE)
        OR A
        JP M,CRUNCH_13
        POP BC
        POP DE
        OR $80
        PUSH AF
        LD A,$FF
        CALL CRUNCH_EMIT
        XOR A
        LD (CRUNCH_LINENUM_MODE),A
        POP AF
        CALL CRUNCH_EMIT
        JP CRUNCH_1
CRUNCH_11:
        POP HL
CRUNCH_12:
        LD A,(DE)
        INC DE
        OR A
        JP P,CRUNCH_12
        INC DE
        JR CRUNCH_7
CRUNCH_13:
        DEC HL
CRUNCH_14:
        PUSH AF
        LD BC,CRUNCH_15+1
        PUSH BC
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
        XOR A
; [RE] Flag-skip into the JP-NZ operand. The CP nn / RET Z ladder above pushes CRUNCH_16+1 ($311A) as its return (LD BC,CRUNCH_16+1 / PUSH BC at $30E9/$30EC). A token MATCH returns into the operand of the cover, executing LD A,$01 then LD ($0B16),A (flag=1). NO match falls through POP AF / XOR A (A=0, Z set) -> the cover JP NZ,$013E is reached but NOT taken -> same LD ($0B16),A (flag=0). The C2 opcode byte of JP NZ is the one-byte cover both entrants step over; $0B16 records whether the prior token was a statement/clause introducer (CRUNCH mode flag, read at CRUNCH_19). VERIFIED: base_addr is real control flow (cover executed on fall-through), MBASIC twin byte-identical.
CRUNCH_15:
        JP NZ,$013E
CRUNCH_16:
        LD (CRUNCH_LINENUM_MODE),A
        POP AF
        POP BC
        POP DE
        CP TOK_ELSE
        PUSH AF
        CALL Z,CRUNCH_EMIT_COLON
        POP AF
        CP $EA
        JP NZ,CRUNCH_28
        PUSH AF
        CALL CRUNCH_EMIT_COLON
        LD A,TOK_REM
        CALL CRUNCH_EMIT
        POP AF
        PUSH AF
        JP CRUNCH_35
CRUNCH_17:
        LD A,(HL)
        CP $2E
        JR Z,CRUNCH_18
        CP $3A
        JP NC,CRUNCH_26
        CP $30
        JP C,CRUNCH_26
CRUNCH_18:
        LD A,(CRUNCH_LINENUM_MODE)
        OR A
        LD A,(HL)
        POP BC
        POP DE
        JP M,CRUNCH_30
        JR Z,CRUNCH_22
        CP $2E
        JP Z,CRUNCH_30
        LD A,$0E
        CALL CRUNCH_EMIT
        PUSH DE
        CALL LINGET
        CALL CRUNCH_SKIP_BLANKS_BACK
CRUNCH_19:
        EX (SP),HL
        EX DE,HL
CRUNCH_20:
        LD A,L
        CALL CRUNCH_EMIT
        LD A,H
CRUNCH_21:
        POP HL
        CALL CRUNCH_EMIT
        JP CRUNCH_1
CRUNCH_22:
        PUSH DE
        PUSH BC
        LD A,(HL)
        CALL FIN_1+1
        CALL CRUNCH_SKIP_BLANKS_BACK
        POP BC
        POP DE
        PUSH HL
        LD A,(L_0B14)
        CP VT_INT
        JR NZ,CRUNCH_23
        LD HL,(L_0CB1)
        LD A,H
        OR A
        LD A,$02
        JR NZ,CRUNCH_23
        LD A,L
        LD H,L
        LD L,$0F
        CP $0A
        JR NC,CRUNCH_20
        ADD A,$11
        JR CRUNCH_21
CRUNCH_23:
        PUSH AF
        RRCA
        ADD A,$1B
        CALL CRUNCH_EMIT
        LD HL,L_0CB1
        CALL FRMEVL_TEST_TYPE
        JR C,CRUNCH_24
        LD HL,L_0CAD
CRUNCH_24:
        POP AF
CRUNCH_25:
        PUSH AF
        LD A,(HL)
        CALL CRUNCH_EMIT
        POP AF
        INC HL
        DEC A
        JR NZ,CRUNCH_25
        POP HL
        JP CRUNCH_1
CRUNCH_26:
        LD DE,KWGRP_Z
CRUNCH_27:
        INC DE
        LD A,(DE)
        AND $7F
        JP Z,CRUNCH_EMIT_5
        INC DE
        CP (HL)
        LD A,(DE)
        JR NZ,CRUNCH_27
        JP CRUNCH_EMIT_6
CRUNCH_28:
        CP $26
        JR NZ,CRUNCH_30
        PUSH HL
        CALL CHRGET
        POP HL
        CALL TOUPPER_A
        CP $48
        LD A,$0B
        JR NZ,CRUNCH_29
        LD A,$0C
CRUNCH_29:
        CALL CRUNCH_EMIT
        PUSH DE
        PUSH BC
        CALL SCAN_AMP_RADIX_CONST
        POP BC
        JP CRUNCH_19
CRUNCH_30:
        INC HL
        PUSH AF
        CALL CRUNCH_EMIT
        POP AF
        SUB $3A
        JR Z,CRUNCH_31
        CP $4A
        JR NZ,CRUNCH_32
        LD A,$01
CRUNCH_31:
        LD (CRUNCH_LITERAL_MODE),A
        LD (CRUNCH_LINENUM_MODE),A
CRUNCH_32:
        SUB $55
        JP NZ,CRUNCH_1
        PUSH AF
CRUNCH_33:
        LD A,(HL)
        OR A
        EX (SP),HL
        LD A,H
        POP HL
        JR Z,CRUNCH_36
        CP (HL)
        JR Z,CRUNCH_30
CRUNCH_34:
        PUSH AF
        LD A,(HL)
CRUNCH_35:
        INC HL
        CALL CRUNCH_EMIT
        JR CRUNCH_33
CRUNCH_36:
        LD HL,$0140
        LD A,L
        SUB C
        LD C,A
        LD A,H
        SBC A,B
        LD B,A
        LD HL,L_08CE
        XOR A
        LD (DE),A
        INC DE
        LD (DE),A
        INC DE
        LD (DE),A
        RET
; [RE] Load A=':' ($3A) then fall into CRUNCH_EMIT: emit a statement-separator colon into the crunch buffer (used around tokens like ELSE/REM that imply a colon).
CRUNCH_EMIT_COLON:
        LD A,$3A
; [RE] CRUNCH output-byte helper: store A to the crunch buffer at (DE), advance DE, decrement remaining count BC; on buffer exhaustion raise error E=$17 (line/buffer overflow) via the RAISE_ERROR dispatcher.
CRUNCH_EMIT:
        LD (DE),A
        INC DE
        DEC BC
        LD A,C
        OR B
        RET NZ
CRUNCH_EMIT_1:
        LD E,ERR_LINE_BUFFER_OVERFLOW
        JP RAISE_ERROR
CRUNCH_EMIT_2:
        POP HL
        DEC HL
        DEC A
        LD (CRUNCH_LINENUM_MODE),A
        POP BC
        POP DE
        CALL CHRGET_UPCASE
CRUNCH_EMIT_3:
        CALL CRUNCH_EMIT
        INC HL
        CALL CHRGET_UPCASE
        CALL IS_LETTER_A
        JR NC,CRUNCH_EMIT_3
        CP $3A
        JR NC,CRUNCH_EMIT_4
        CP $30
        JR NC,CRUNCH_EMIT_3
        CP $2E
        JR Z,CRUNCH_EMIT_3
CRUNCH_EMIT_4:
        JP CRUNCH_1
CRUNCH_EMIT_5:
        LD A,(HL)
        CP $20
        JR NC,CRUNCH_EMIT_6
        CP $09
        JR Z,CRUNCH_EMIT_6
        CP $0A
        JR Z,CRUNCH_EMIT_6
        LD A,$20
CRUNCH_EMIT_6:
        PUSH AF
        LD A,(CRUNCH_LINENUM_MODE)
        INC A
        JR Z,CRUNCH_EMIT_7
        DEC A
CRUNCH_EMIT_7:
        JP CRUNCH_16
; [RE] CRUNCH helper: walk HL backward over trailing whitespace (space/$09/$0A), then INC HL to leave HL just past the last non-blank; used to trim blanks before re-scanning a number/reserved word.
CRUNCH_SKIP_BLANKS_BACK:
        DEC HL
        LD A,(HL)
        CP $20
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        CP $09
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        CP $0A
        JR Z,CRUNCH_SKIP_BLANKS_BACK
        INC HL
        RET
; [RE] FOR statement handler (token $82): sets up the FOR/NEXT loop frame on the runtime stack.
STMT_FOR:
        LD A,$64
        LD (L_0B52),A
        CALL PTRGET_1+1
        CALL SYNCHR
        DEFB    TOK_EQ                   ; inline keyword-token arg consumed by the preceding CALL
        PUSH DE
        EX DE,HL
        LD (L_0B54),HL
        EX DE,HL
        LD A,(L_0B14)
        PUSH AF
        CALL FRMEVL_NOPAREN
        POP AF
        PUSH HL
        CALL FRMEVL_APPLY_OP
        LD HL,L_0C6D
        CALL FP_MOVE_TO_FAC
        POP HL
        POP DE
        POP BC
        PUSH HL
        CALL STMT_DATA
        LD (L_0B4E),HL
        LD HL,$0002
        ADD HL,SP
STMT_FOR_1:
        CALL STKFRAME_SCAN
        POP DE
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
        LD HL,(L_0B4E)
        CALL CMP_HL_DE
        POP HL
        JP NZ,STMT_FOR_1
        POP DE
        LD SP,HL
        LD (SAVSTK),HL
STMT_FOR_2:
        EX DE,HL
        LD C,$08
        CALL CHECK_STACK_ROOM
        PUSH HL
        LD HL,(L_0B4E)
        EX (SP),HL
        PUSH HL
        LD HL,(SAVTXT)
        EX (SP),HL
        CALL SYNCHR
        DEFB    TOK_TO                   ; inline keyword-token arg consumed by the preceding CALL
        CALL FRMEVL_TEST_TYPE
        JP Z,RAISE_TYPE_MISMATCH
        JP NC,RAISE_TYPE_MISMATCH
        PUSH AF
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
STMT_FOR_3:
        CALL FN_CSNG
        CALL FP_LOAD_FAC
        POP HL
        PUSH BC
        PUSH DE
        LD BC,$8100
        LD D,C
        LD E,D
        LD A,(HL)
        CP TOK_STEP
        LD A,$01
        JR NZ,STMT_FOR_5
        CALL FRMEVL_LOWPREC
        PUSH HL
        CALL FN_CSNG
        CALL FP_LOAD_FAC
        CALL FP_SIGN
STMT_FOR_4:
        POP HL
STMT_FOR_5:
        PUSH BC
        PUSH DE
        LD C,A
        CALL FRMEVL_TEST_TYPE
        LD B,A
        PUSH BC
        DEC HL
        CALL CHRGET
        JP NZ,RAISE_SYNTAX_ERROR
        CALL BLOCK_SCAN_FORNEXT
        CALL CHRGET
        PUSH HL
        PUSH HL
        LD HL,(L_0C71)
        LD (SAVTXT),HL
        LD HL,(L_0B54)
        EX (SP),HL
        LD B,$82
        PUSH BC
        INC SP
        PUSH AF
        PUSH AF
        JP STMT_NEXT_1+1
STMT_FOR_6:
        LD B,$82
        PUSH BC
        INC SP
STMT_FOR_7:
        PUSH HL
; [RE] SMC console-status poll. CALL $0000 at $336C is a placeholder; its operand ($336D-$336E = STMT_FOR_8+1) is patched once at COLD_START. LD (STMT_FOR_8+1),HL at $81F9 stores HL = the BIOS CONST routine address (walked from the WBOOT vector at $0001 + offset 4) into the operand, the same address also stored to INKEY_SCAN_2+1 and RPC_CONST_POLL_1+1. Each NEWSTT statement then runs CALL CONST; POP HL; OR A; CALL NZ,INKEY_SCAN to poll for a pending key (Ctrl-C / break / pause). The on-disk $0000 is never executed. VERIFIED: operand really written ($81F9), patched CALL really executed per-statement (STMT_FOR_7 PUSH HL falls into it), MBASIC twin byte-identical.
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
; [RE] NEWSTT per-line entry: read the line link; if end-of-program go to the ready loop, else load the next line's text pointer into SAVTXT, and if the TRON trace flag ($0CAB) is set print [linenum] before resuming the statement executor.
NEWSTT_NEXTLINE:
        LD A,(HL)
        INC HL
        OR (HL)
        JP Z,PROGRAM_END
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        LD (SAVTXT),HL
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
NEWSTT_NEXTLINE_1:
        EX DE,HL
NEWSTT_NEXTLINE_2:
        CALL CHRGET
        LD DE,STMT_FOR_7
        PUSH DE
        RET Z
; [RE] Statement executor / dispatch. Token in A; SUB $81; if <0 not a statement; CP $5B reject tokens above the table; RLCA (index*2); index the statement-handler DEFW table at $0108 (addr = $0108 + (token-$81)*2), load handler into BC, PUSH BC, fall into CHRGET ($33C9) and RET to the handler. The graphics statement handlers (HOME..PLOT, tokens $C7-$D5) live in this table at $0194-$01B0.
NEWSTT_DISPATCH:
        SUB $81
        JP C,STMT_LET
        CP $5B
        JP NC,GETVAR_NAME_1
        RLCA
        LD C,A
        LD B,$00
        EX DE,HL
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
; MS BASIC CHRGET: INC HL then fetch the next program/text char at (HL) into A, skipping spaces, returning C set if it is a digit (0-9) and Z set at end-of-line ($00)/end-of-statement. Expands the embedded constant-token forms ($0B-$1E line-number/constant tokens, $1C/$1E etc.) into their literal values. Entry CHRGET_1 ($33CA) = CHRGOT (re-fetch current char without advancing).
CHRGET:
        INC HL
; CHRGOT: re-fetch the current text char at (HL) into A without advancing (CHRGET minus the leading INC HL); sets C if digit, Z at end-of-line/statement; expands embedded constant tokens $0B-$1E.
CHRGOT:
        LD A,(HL)
        CP $3A
        RET NC
CHRGOT_1:
        CP $20
        JR Z,CHRGET
        JR NC,CHRGOT_10
        OR A
        RET Z
        CP $0B
        JR C,CHRGOT_9
        CP $1E
        JR NZ,CHRGOT_2
        LD A,(L_0B19)
        OR A
        RET
CHRGOT_2:
        CP $10
        JR NZ,CHRGOT_4
CHRGOT_3:
        LD HL,(L_0B17)
        JR CHRGOT
CHRGOT_4:
        PUSH AF
        INC HL
        LD (L_0B19),A
        SUB $1C
        JR NC,CHRGOT_8
        SUB $F5
        JR NC,CHRGOT_5
        CP $FE
        JR NZ,CHRGOT_7
        LD A,(HL)
        INC HL
CHRGOT_5:
        LD (L_0B17),HL
        LD H,$00
CHRGOT_6:
        LD L,A
        LD (L_0B1B),HL
        LD A,$02
        LD (L_0B1A),A
        LD HL,CHRGOT_11
        POP AF
        OR A
        RET
CHRGOT_7:
        LD A,(HL)
        INC HL
        INC HL
        LD (L_0B17),HL
        DEC HL
        LD H,(HL)
        JR CHRGOT_6
CHRGOT_8:
        INC A
        RLCA
        LD (L_0B1A),A
        PUSH DE
        PUSH BC
        LD DE,L_0B1B
        EX DE,HL
        LD B,A
        CALL FP_MOVE_LOOP
        EX DE,HL
        POP BC
        POP DE
        LD (L_0B17),HL
        POP AF
        LD HL,CHRGOT_11
        OR A
        RET
CHRGOT_9:
        CP $09
        JP NC,CHRGET
CHRGOT_10:
        CP $30
        CCF
        INC A
        DEC A
        RET
CHRGOT_11:
        LD E,$10
; [RE] CHRGOT constant-token tail: for the embedded numeric-constant tokens ($0B-$1E) decoded by CHRGOT, materialise the literal value into FAC ($0CB1/$0CB3) and value-type ($0B14), then resume the char scan at CHRGOT_3 ($33E7).
CHRGOT_CONST_VALUE:
        LD A,(L_0B19)
        CP $0F
        JR NC,CHRGOT_CONST_VALUE_2
        CP $0D
        JR C,CHRGOT_CONST_VALUE_2
        LD HL,(L_0B1B)
        JR NZ,CHRGOT_CONST_VALUE_1
        INC HL
        INC HL
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
CHRGOT_CONST_VALUE_1:
        CALL INT_TO_SNG
        JP CHRGOT_3
CHRGOT_CONST_VALUE_2:
        LD A,(L_0B1A)
        LD (L_0B14),A
        CP VT_DBL
        JR Z,CHRGOT_CONST_VALUE_3
        LD HL,(L_0B1B)
        LD (L_0CB1),HL
        LD HL,(L_0B1D)
        LD (L_0CB3),HL
        JP CHRGOT_3
CHRGOT_CONST_VALUE_3:
        LD HL,L_0B1B
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
        LD HL,(L_0B1B)
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
        JP NZ,OPEN_NAMED_FILE_1
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
        LD A,(L_0B19)
        CP $0D
        EX DE,HL
        RET Z
        EX DE,HL
        PUSH HL
        LD HL,(L_0B17)
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
        LD (L_0B54),HL
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
        LD HL,(L_0B54)
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
        LD (L_0B54),HL
        EX DE,HL
        PUSH DE
        LD A,(L_0B14)
        PUSH AF
        CALL FRMEVL_NOPAREN
        POP AF
STMT_LET_1:
        EX (SP),HL
STMT_LET_2:
        LD B,A
        LD A,(L_0B14)
        CP B
        LD A,B
        JR Z,STMT_LET_4
        CALL FRMEVL_APPLY_OP
STMT_LET_3:
        LD A,(L_0B14)
STMT_LET_4:
        LD DE,L_0CB1
        CP $05
        JR C,STMT_LET_5
        LD DE,L_0CAD
STMT_LET_5:
        PUSH HL
        CP VT_STR
        JR NZ,STMT_LET_8
        LD HL,(L_0CB1)
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
        LD HL,(L_0B1B)
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
        LD HL,(L_0CB1)
        INC (HL)
STMT_PRINT_3:
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR NZ,STMT_PRINT_6
        LD HL,(L_0CB1)
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
        JP Z,FN_CVI_4
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
        LD (L_0B52),A
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
        JP NZ,FN_CVI_3
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
; MS BASIC-80 FRMEVL: evaluate a complete expression (numeric or string) at (HL) into the FAC ($0CB1). $3A71 calls SYNCHR-context entry; $3A76/$3A78 is the precedence-driven operator loop: fetch an operand (EVAL, FRMEVL_EVAL_OPERAND), then while the next token is a binary operator of high enough precedence, recurse and apply. Relational/arithmetic operator tokens >= $EF are handled here; precedence table at $04ED, operator-function dispatch table at $0517/$0503.
FRMEVL:
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
; [RE] Bare expression-evaluator entry (no leading '(' required): DEC HL to back up, then fall into the FRMEVL operator-precedence loop with D=0. The general 'evaluate expression at (HL) into FAC' call used throughout the parsers (60+ sites).
FRMEVL_NOPAREN:
        DEC HL
; [RE] FRMEVL body entry with D=$00 (lowest operator precedence); falls into the precedence loop. Canonical MS BASIC-80 FRMEVL after the SYNCHR-context check.
FRMEVL_LOWPREC:
        LD D,$00
; [RE] FRMEVL operator-precedence loop: save pending-operator precedence (D), check stack, fetch one operand (FRMEVL_EVAL_OPERAND); then while the next token at (HL) is a binary operator (>= $EF) of precedence > pending, recurse here and apply. Relational vs arithmetic vs string-concat dispatch follows.
FRMEVL_OPLOOP:
        PUSH DE
        LD C,$01
        CALL CHECK_STACK_ROOM
        CALL FRMEVL_EVAL_OPERAND
        XOR A
        LD (L_0CB6),A
FRMEVL_OPLOOP_1:
        LD (FRMEVL_TXTPTR_TEMP),HL
FRMEVL_OPLOOP_2:
        LD HL,(FRMEVL_TXTPTR_TEMP)
        POP BC
        LD A,(HL)
        LD (L_0B4A),HL
        CP TOK_GT
        RET C
        CP TOK_PLUS
        JP C,FRMEVL_RELOP
        SUB TOK_PLUS
        LD E,A
        JR NZ,FRMEVL_OPLOOP_3
        LD A,(L_0B14)
        CP VT_STR
        LD A,E
        JP Z,STR_CONCAT
FRMEVL_OPLOOP_3:
        CP $0C
        RET NC
        LD HL,FRMEVL_PREC_TBL
        LD D,$00
        ADD HL,DE
        LD A,B
        LD D,(HL)
        CP D
        RET NC
        PUSH BC
        LD BC,FRMEVL_OPLOOP_2
        PUSH BC
        LD A,D
        CP $7F
        JP Z,FRMEVL_OPLOOP_9
        CP $51
        JP C,FRMEVL_OPLOOP_10
        AND $FE
        CP $7A
        JP Z,FRMEVL_OPLOOP_10
FRMEVL_OPLOOP_4:
        LD HL,L_0CB1
        LD A,(L_0B14)
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
; [RE] Relational-operator collector: tokens $EF-$F1 (=,<,>) accumulate a 3-bit relation mask in D (RLA/XOR), advancing past consecutive relation tokens via CHRGET; falls to FRMEVL_ARITHOP when a non-relation operator is seen.
FRMEVL_RELOP:
        LD D,$00
FRMEVL_OPLOOP_8:
        SUB TOK_GT
        JP C,FRMEVL_ARITHOP
        CP $03
        JP NC,FRMEVL_ARITHOP
        CP $01
        RLA
        XOR D
        CP D
        LD D,A
        JP C,RAISE_SYNTAX_ERROR
        LD (L_0B4A),HL
        CALL CHRGET
        JR FRMEVL_OPLOOP_8
FRMEVL_OPLOOP_9:
        CALL FN_CSNG
        CALL FAC_PUSH
        LD BC,FN_SQR_1
        LD D,$7F
        JR FRMEVL_OPLOOP_6
FRMEVL_OPLOOP_10:
        PUSH DE
        CALL FN_CINT
        POP DE
        PUSH HL
        LD BC,FRMEVL_INT_OP_HANDLER
        JR FRMEVL_OPLOOP_6
; [RE] Arithmetic/string binary-operator apply: if pending precedence (B) < new operator precedence ($64 guard) push the FAC operand and recurse; sets up the operator-result combine via FRMEVL_OPCOMBINE.
FRMEVL_ARITHOP:
        LD A,B
        CP $64
        RET NC
        PUSH BC
        PUSH DE
        LD DE,$6404
        LD HL,FRMEVL_SCAN_UNARY_1
        PUSH HL
        CALL FRMEVL_TEST_TYPE
        JP NZ,FRMEVL_OPLOOP_4
        LD HL,(L_0CB1)
        PUSH HL
        LD BC,NEXT_LOOP_BODY_7
        JR FRMEVL_OPLOOP_6
; [RE] Operator-result combine: after the right operand is evaluated, recover operator code/type ($0B15/$0B14), coerce both operands to a common numeric type (CINT/CSNG paths) or take the string path ($08), then dispatch to the arithmetic operator routine via the $0517 (numeric) / $0503 (relational) vector tables.
FRMEVL_OPCOMBINE:
        POP BC
        LD A,C
        LD (CRUNCH_LITERAL_MODE),A
        LD A,(L_0B14)
        CP B
        JR NZ,FRMEVL_OPLOOP_13
        CP VT_INT
        JR Z,FRMEVL_OPLOOP_14
        CP VT_SNG
        JP Z,FRMEVL_OP_POP_FRAME
        JR NC,FRMEVL_OPLOOP_16
FRMEVL_OPLOOP_13:
        LD D,A
        LD A,B
        CP $08
        JR Z,FRMEVL_OPLOOP_15
        LD A,D
        CP $08
        JR Z,FRMEVL_OPLOOP_20
        LD A,B
        CP $04
        JR Z,FRMEVL_OP_COERCE_INT
        LD A,D
        CP $03
        JP Z,RAISE_TYPE_MISMATCH
        JR NC,FRMEVL_OP_COERCE_INT_3
FRMEVL_OPLOOP_14:
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_INT
        LD B,$00
        ADD HL,BC
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD B,(HL)
        POP DE
        LD HL,(L_0CB1)
        PUSH BC
        RET
FRMEVL_OPLOOP_15:
        CALL FN_CDBL
FRMEVL_OPLOOP_16:
        CALL FP_ARG_TO_TEMP2
        POP HL
        LD (L_0CAF),HL
        POP HL
        LD (L_0CAD),HL
FRMEVL_OPLOOP_17:
        POP BC
        POP DE
        CALL FP_STORE_FAC
FRMEVL_OPLOOP_18:
        CALL FN_CDBL
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_DBL
FRMEVL_OPLOOP_19:
        LD A,(CRUNCH_LITERAL_MODE)
        RLCA
        ADD A,L
        LD L,A
        ADC A,H
        SUB L
        LD H,A
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        JP (HL)
FRMEVL_OPLOOP_20:
        PUSH BC
        CALL FP_ARG_TO_TEMP2
        POP AF
        LD (L_0B14),A
        CP VT_SNG
        JR Z,FRMEVL_OPLOOP_17
        POP HL
        LD (L_0CB1),HL
        JR FRMEVL_OPLOOP_18
; [RE] FRMEVL operator-apply coercion (mis-split as DEFB, real code reached from FRMEVL_OPCOMBINE $3B76 when operand-type B==$04): CALL FN_CINT to force the operand to integer, then fall into FRMEVL_OP_POP_FRAME
FRMEVL_OP_COERCE_INT:
        CALL FN_CSNG
; [RE] FRMEVL operator-apply (mis-split DEFB code, target of JP Z at $3B63 for string type): POP BC / POP DE to recover the operator/operand frame, then fall into FRMEVL_OP_DISPATCH_REL
FRMEVL_OP_POP_FRAME:
        POP BC
        POP DE
; [RE] FRMEVL operator-apply tail (mis-split DEFB code): LD HL,$050D (relational/string-op handler vector base) then JR back into the operator-result combine loop at ~$3BA9 to dispatch the pending operator
FRMEVL_OP_DISPATCH_REL:
        LD HL,OPERATOR_ROUTINE_TBL+OP_BAND_SNG
        JR FRMEVL_OPLOOP_19
FRMEVL_OP_COERCE_INT_3:
        POP HL
        CALL FAC_PUSH
        CALL INT_TO_SINGLE_HL
        CALL FP_LOAD_FAC
        POP HL
        LD (L_0CB3),HL
        POP HL
        LD (L_0CB1),HL
        JR FRMEVL_OP_DISPATCH_REL
; [RE] Integer-division operator handler (OPERATOR_ROUTINE_TBL integer-divide slot $051D): promote both integer operands to single precision and tail-call FDIV -- MS BASIC '/' always yields a float.
IDIV:
        PUSH HL
        EX DE,HL
        CALL INT_TO_SINGLE_HL
        POP HL
        CALL FAC_PUSH
        CALL INT_TO_SINGLE_HL
        JP FDIV_BY_TEN_1
; [RE] EVAL: fetch one operand/factor for FRMEVL. Parses a numeric constant (-> $5F35 number scan), a parenthesized sub-expression, a string literal ($22), a variable reference, unary NOT ($E2)/minus, the FN call token ($E1), and the built-in function tokens (SCRN $CD/$EC/$ED, COLOR $D3, USR $E9, etc.) by dispatching to their FN_ handlers.
FRMEVL_EVAL_OPERAND:
        CALL CHRGET
        JP Z,RAISE_MISSING_OPERAND
        JP C,FIN_1+1
        CALL IS_LETTER_A
        JP NC,FRMEVL_PAREN_3
        CP $20
        JP C,CHRGOT_CONST_VALUE
        INC A
        JP Z,SCAN_AMP_RADIX_CONST_7
        DEC A
        CP TOK_PLUS
        JR Z,FRMEVL_EVAL_OPERAND
        CP TOK_MINUS
        JP Z,FRMEVL_PAREN_1
        CP $22
        JP Z,SCAN_STR_QUOTE
        CP TOK_NOT
        JP Z,FRMEVL_SCAN_UNARY_2
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
FRMEVL_EVAL_OPERAND_1:
        CP $E5
        JR NZ,FRMEVL_EVAL_OPERAND_2
        CALL CHRGET
        PUSH HL
        LD HL,(ERR_SAVTXT)
        CALL INT_TO_SNG
        POP HL
        RET
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
FRMEVL_EVAL_OPERAND_3:
        CALL PTRGET_1+1
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
        JP Z,FIELD_PAD_SPACES_4
        CP TOK_FN
        JP Z,STMT_DEF_2
; [RE] Evaluate a parenthesised expression / get a 16-bit integer argument: calls FRMEVL then converts the FAC to an integer in DE (ADD HL,HL). Used by functions and subscript evaluation.
FRMEVL_PAREN:
        CALL FRMEVL
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        RET
FRMEVL_PAREN_1:
        LD D,$7D
        CALL FRMEVL_OPLOOP
        LD HL,(FRMEVL_TXTPTR_TEMP)
        PUSH HL
        CALL FP_NEGATE_CHECKED
FRMEVL_PAREN_2:
        POP HL
        RET
FRMEVL_PAREN_3:
        CALL PTRGET_1+1
FRMEVL_PAREN_4:
        PUSH HL
        EX DE,HL
        LD (L_0CB1),HL
        CALL FRMEVL_TEST_TYPE
        CALL NZ,FP_ARG_SETUP1
        POP HL
        RET
; [RE] Read char at (HL) and fold ASCII lowercase a-z ($61-$7A) to uppercase (AND $5F); leaves other chars unchanged. CRUNCH's case-insensitive keyword matcher uses this. TOUPPER_A ($3CCD) is the same fold applied to the char already in A.
CHRGET_UPCASE:
        LD A,(HL)
; Fold the char already in A from ASCII lowercase a-z ($61-$7A) to uppercase (AND $5F); other chars unchanged. Entry to CHRGET_UPCASE that skips the LD A,(HL); used by CRUNCH keyword matching and the &H/&O scanner
TOUPPER_A:
        CP $61
        RET C
        CP $7B
        RET NC
        AND $5F
        RET
; [RE] Two-way operand guard: if the current char is '&' ($26) fall into the &H/&O radix-constant scanner, else JP LINGET to parse a decimal line number.
LINGET_OR_AMP:
        CP $26
        JP NZ,LINGET
; [RE] '&' radix-literal scanner (FRMEVL reaches it at $3C24 on token $26): parses &H<hex> (ADD HL,HL x4 + nibble) and &O<octal> (ADD HL,HL x3 + digit) into HL, stores as an integer in the FAC via FP_STORE_FAC_INT; Overflow (E=$06,$0D81) on too many digits, Syntax ($0D6F) on a bad octal digit
SCAN_AMP_RADIX_CONST:
        LD DE,$0000
        CALL CHRGET
        CALL TOUPPER_A
        CP $4F
        JR Z,SCAN_AMP_RADIX_CONST_5
        CP $48
        JR NZ,SCAN_AMP_RADIX_CONST_4
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
SCAN_AMP_RADIX_CONST_5:
        CALL CHRGET
        EX DE,HL
        JR NC,SCAN_AMP_RADIX_CONST_6
        CP $38
        JP NC,RAISE_SYNTAX_ERROR
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
SCAN_AMP_RADIX_CONST_6:
        CALL FP_STORE_FAC_INT
        EX DE,HL
        RET
SCAN_AMP_RADIX_CONST_7:
        INC HL
        LD A,(HL)
        SUB $81
        CP $07
        JR NZ,SCAN_AMP_RADIX_CONST_8
        PUSH HL
        CALL CHRGET
        CP $28
        POP HL
        JP NZ,POLY_EVAL_2
        LD A,$07
SCAN_AMP_RADIX_CONST_8:
        LD B,$00
        RLCA
        LD C,A
        PUSH BC
        CALL CHRGET
        LD A,C
        CP $05
        JP NC,SCAN_AMP_RADIX_CONST_9
        CALL FRMEVL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL FP_INT_CHECK
        EX DE,HL
        LD HL,(L_0CB1)
        EX (SP),HL
        PUSH HL
        EX DE,HL
        CALL GETBYT
        EX DE,HL
        EX (SP),HL
        JR SCAN_AMP_RADIX_CONST_11
SCAN_AMP_RADIX_CONST_9:
        CALL FRMEVL_PAREN
        EX (SP),HL
        LD A,L
        CP $0C
        JR C,SCAN_AMP_RADIX_CONST_10
        CP $1B
        PUSH HL
        CALL C,FN_CSNG
        POP HL
SCAN_AMP_RADIX_CONST_10:
        LD DE,FRMEVL_PAREN_2
        PUSH DE
        LD A,$01
        LD (L_0CB6),A
SCAN_AMP_RADIX_CONST_11:
        LD BC,FUNC_DISPATCH_TBL
; [RE] Indexed vector dispatch: ADD HL,BC then load the 16-bit target from (HL) and JP (HL). Shared by the operator-function table ($04F9) and other token-dispatch sites.
DISPATCH_VECTOR_HLBC:
        ADD HL,BC
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        JP (HL)
; [RE] Pre-scan a leading unary operator token: recognises NOT ($F3), unary minus ($2D)/$F2 and unary plus ($2B), toggling D; backs up (HL) one char when none match. Used when fetching a factor/operand.
FRMEVL_SCAN_UNARY:
        DEC D
        CP TOK_MINUS
        RET Z
        CP $2D
        RET Z
        INC D
        CP $2B
        RET Z
        CP TOK_PLUS
        RET Z
        DEC HL
        RET
FRMEVL_SCAN_UNARY_1:
        INC A
        ADC A,A
        POP BC
        AND B
        ADD A,$FF
        SBC A,A
        CALL INT16_TO_FP
        JR FRMEVL_SCAN_UNARY_3
FRMEVL_SCAN_UNARY_2:
        LD D,$5A
        CALL FRMEVL_OPLOOP
        CALL FN_CINT
        LD A,L
        CPL
        LD L,A
        LD A,H
        CPL
        LD H,A
        LD (L_0CB1),HL
        POP BC
FRMEVL_SCAN_UNARY_3:
        JP FRMEVL_OPLOOP_2
; [RE] VALTYP discriminator (canonical MS BASIC type test). Read the value-type byte $0B14 (VALTYP = storage width in bytes: 2=int, 3=string, 4=single, 8=double). CP $08 splits double (>=8 -> NC) from the rest; SUB $03 then makes Z when VALTYP=3 => returns Z iff STRING, sign(M) when integer (2-3=$FF), and SCF on the <8 path so callers can branch numeric-vs-string. Consumed by FN_CSNG/FN_CDBL/FN_CINT (M=int, Z=string).
FRMEVL_TEST_TYPE:
        LD A,(L_0B14)
        CP $08
        JR NC,FRMEVL_TEST_TYPE_1
        SUB $03
        OR A
        SCF
        RET
FRMEVL_TEST_TYPE_1:
        SUB $03
        OR A
        RET
; [RE] Integer-operands binary-operator handler (mis-split as DEFB, real code; set up by FRMEVL_OPLOOP_13 at $3B31 LD BC,$3DD8): pops operator token in A and the two integer operands (DE,HL), branches per token to integer add/sub/AND/OR/XOR/relational kernels, leaving the integer result in the FAC
FRMEVL_INT_OP_HANDLER:
        PUSH BC
        CALL FN_CINT
        POP AF
        POP DE
        CP $7A
        JP Z,INT_DIV_ROUND
        CP $7B
        JP Z,INT_DIV_KERNEL
        LD BC,FP_LOAD_INT_TO_FAC_1
        PUSH BC
        CP $46
        JR NZ,FRMEVL_TEST_TYPE_3
        LD A,E
        OR L
        LD L,A
        LD A,H
        OR D
        RET
FRMEVL_TEST_TYPE_3:
        CP $50
        JR NZ,FRMEVL_TEST_TYPE_4
        LD A,E
        AND L
        LD L,A
        LD A,H
        AND D
        RET
FRMEVL_TEST_TYPE_4:
        CP $3C
        JR NZ,FRMEVL_TEST_TYPE_5
        LD A,E
        XOR L
        LD L,A
        LD A,H
        XOR D
        RET
FRMEVL_TEST_TYPE_5:
        CP $32
        JR NZ,FRMEVL_TEST_TYPE_6
        LD A,E
        XOR L
        CPL
        LD L,A
        LD A,H
        XOR D
        CPL
        RET
FRMEVL_TEST_TYPE_6:
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
; [RE] 16-bit integer subtract (HL := HL - DE) then store the integer result into the FAC via FP_STORE (INT_TO_SNG).
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
        LD A,(L_0B14)
        PUSH AF
        CP $03
        CALL Z,FRESTR
        POP AF
        EX DE,HL
        LD HL,L_0CB1
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
        LD A,(L_0B1B)
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
        LD A,(L_0B14)
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
        LD (L_0B52),A
        CALL PTRGET_1+1
        EX DE,HL
        EX (SP),HL
        LD A,(L_0B14)
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
        LD A,(L_0B14)
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
        LD (L_0B14),A
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
        LD A,(L_0B14)
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
        LD HL,(L_0CB1)
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
; [RE] Apply a binary operator: mask the operator code (AND $07), index the operator-routine vector table at $04F9, and jump via DISPATCH_VECTOR_HLBC, preserving HL across the call.
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
FRMEVL_APPLY_OP_1:
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        DEC BC
; [RE] Copy BC bytes from (DE) to (HL), ascending (LDI-style hand loop). General memory-move helper used by DEF FN parameter save/restore and variable-table shuffling.
BLOCK_COPY_DE_HL:
        LD A,B
        OR C
        JR NZ,FRMEVL_APPLY_OP_1
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
        LD (L_0B52),A
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
        LD HL,(L_0B1B)
        JP FOUT_2
IS_ALNUM_CHAR_2:
        POP BC
        POP DE
        LD A,(L_0B19)
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
        LD A,(L_0B1A)
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
        LD A,(L_0B1A)
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
        LD HL,(L_0B17)
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
        LD A,(L_0CB3)
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
        LD HL,(L_0B17)
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
; -- Disk-error raise vectors. The disk/RWTS error path enters one of these (the
;    entries are also stored in the cold-start vector table); each sets E and falls
;    through the shared tail (DISK_RESELECT_AND_RAISE) which reselects the default
;    drive (BDOS fn 14) then JP RAISE_ERROR. Same overlap-skip idiom as the low-RAM
;    coded-error stubs; labelled DISK_RAISE_* so codes shared with the low-RAM run
;    don't collide.
DISK_RAISE_RESET_ERROR:
        LD E,ERR_RESET_ERROR             ; raise error 31
        DEFB    $01                      ; LD BC opcode = skip the next LD E
DISK_RAISE_DISK_I_O_ERROR:
        LD E,ERR_DISK_I_O_ERROR          ; raise error 57
        DEFB    $01                      ; LD BC opcode = skip the next LD E
DISK_RAISE_DISK_READ_ONLY:
        LD E,ERR_DISK_READ_ONLY          ; raise error 68
        DEFB    $01                      ; LD BC opcode = skip the next LD E
DISK_RAISE_DRIVE_SELECT_ERROR:
        LD E,ERR_DRIVE_SELECT_ERROR      ; raise error 69
        DEFB    $01                      ; LD BC opcode = skip the next LD E
DISK_RAISE_FILE_READ_ONLY:
        LD E,ERR_FILE_READ_ONLY          ; raise error 70
; [RE] Shared disk-error exit: save the code (E), issue BDOS Select-Disk (C=$0E) on
;    the CP/M current-drive byte ($0004) to reselect the default drive, then raise.
; Update existing comment phrasing to name the symbol: '...issue BDOS Select-Disk (C=DRV_SET) on the CP/M current-drive byte ($0004)...'
DISK_RESELECT_AND_RAISE:
        PUSH DE
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
        LD HL,L_0CB1
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
        LD HL,L_0CB1
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
        LD A,(L_0CB3)
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
        LD HL,L_0CB3
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
        LD HL,(L_0CB1)
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
        LD HL,(L_0CB1)
        EX (SP),HL
        PUSH HL
        LD HL,(L_0CB3)
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
        LD (L_0CB1),HL
        LD H,B
        LD L,C
        LD (L_0CB3),HL
        EX DE,HL
        RET
; [RE] MOVRF: load the FAC ($0CB1) 4-byte mantissa into E,D,C,B.
FP_LOAD_FAC:
        LD HL,L_0CB1
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
        LD DE,L_0CB1
; [RE] Block-copy 4 bytes (DE)->(HL); generic FP move primitive.
FP_MOVE4:
        LD B,$04
        JR FP_MOVE_LOOP
FP_MOVE4_1:
        EX DE,HL
; [RE] Typed block-copy (DE)->(HL): length B = VALTYP ($0B14), which IS the value's storage WIDTH in bytes (2=int,3=string-descriptor,4=single,8=double). DJNZ-copies exactly VALTYP bytes. This site is the direct proof that VALTYP encodes byte width.
FP_MOVE_TYPED:
        LD A,(L_0B14)
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
        LD HL,L_0CB3
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
        LD DE,L_0CB1
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
        LD HL,L_0CB3
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
        LD HL,L_0CB3
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
        LD HL,(L_0CB1)
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
        LD A,(L_0CB3)
        OR A
        PUSH AF
        AND $7F
        LD (L_0CB3),A
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
        LD (L_0CB1),HL
; [RE] SET_TYPE_INTEGER: set VALTYP $0B14 = $02 (=VT_INT, integer). Tail of FP_STORE_FAC_INT and the integer-result stores (e.g. INT_DIV_ROUND $5203).
SET_TYPE_INTEGER:
        LD A,$02
SET_TYPE_INTEGER_1:
        LD (L_0B14),A
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
        LD HL,(L_0CB1)
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
        LD A,(L_0CB1)
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
        LD A,(L_0CB3)
        LD C,A
        LD HL,L_0CB3
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
        LD HL,(L_0CB1)
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
        LD A,(L_0CB3)
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
        LD HL,L_0CB3
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
        LD HL,L_0CB3
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
        LD A,(L_0CB3)
        OR A
        JP P,FIN_DSCALE_DIV10_2
        AND $7F
        LD (L_0CB3),A
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
        LD A,(L_0CB3)
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
        LD A,(L_0B14)
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
        CALL FRMEVL_SCAN_UNARY
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
        LD HL,(L_0CB1)
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
        LD (L_0CB1),HL
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
        LD HL,L_0CB3
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
        LD A,(L_0CB3)
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
        LD A,(L_0CB3)
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
        LD HL,L_0CB1
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
        LD A,(L_0B14)
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
        LD HL,(L_0CB1)
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
        LD (L_0CB1),HL
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
        LD (L_0CB3),HL
        POP HL
        LD (L_0CB1),HL
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
        LD A,(L_0CB3)
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
        LD A,(L_0CB3)
        OR A
        PUSH AF
        JP P,FN_SIN_2
        XOR $80
        LD (L_0CB3),A
FN_SIN_2:
        LD HL,FP_POLY_SIN_COEFFS
        CALL POLY_EVAL_ODD
        POP AF
        RET P
        LD A,(L_0CB3)
        XOR $80
        LD (L_0CB3),A
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
        LD (L_0B14),A
        CALL CHRGET
        LD A,(L_0B52)
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
        LD (L_0B52),A
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
        LD A,(L_0B14)
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
        LD A,(L_0B14)
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
        LD (L_0CB1),HL
        CALL FRMEVL_TEST_TYPE
        JR NZ,PTRGET_SEARCH_13
        LD HL,L_0CF1
        LD (L_0CB1),HL
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
        LD A,(L_0B14)
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
        LD A,(L_0B14)
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
        LD A,(L_0B14)
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
        LD HL,(L_0CB1)
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
        LD HL,(L_0CB1)
        LD B,C
        LD C,$00
        PUSH BC
        CALL STR_SUBSTR_ALLOC_COPY_2+1
        CALL STRPRT
        LD HL,(L_0CB1)
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
        JP NZ,FN_LOF_VALUE_1
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
; [RE] INCHR / auto-page 'more' handler on the LIST/INPUT path: if a file is the current channel (PTRFIL $0840 nonzero) read the next byte from that file via GETC_FILE_EOF and return it; otherwise (console) tests the pending key, runs the input poll (LOAD_FINISH_CLOSE_CUR) and the Ctrl-C/break check ($0CA0), and on a full page pushes STMT_FOR_7 and prints the pause prompt string at $0CF2 via STROUT before resuming.
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
        CALL LOAD_FINISH_CLOSE_CUR
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
        LD (L_0CB1),HL
        LD A,VT_STR
        LD (L_0B14),A
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
        LD A,(L_0870)
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
        LD (L_0B54),HL
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
        LD (L_0B52),A
        PUSH HL
        PUSH BC
RESET_RUN_STATE_1:
        LD HL,(L_0B54)
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
        LD (L_0B52),A
        CALL PTRGET_1+1
        JP NZ,ERROR_FC
        PUSH HL
        LD (L_0B52),A
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
        LD (L_0B54),HL
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
        LD HL,L_0C6D
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
        LD HL,(L_0C6D)
        JR NEXT_LOOP_BODY_4
NEXT_LOOP_BODY_3:
        CALL IADD
        LD A,(L_0B14)
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
        LD HL,(L_0B54)
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
        LD (L_0CB1),HL
        LD A,VT_STR
        LD (L_0B14),A
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
        LD HL,(L_0CB1)
        EX (SP),HL
        CALL FRMEVL_EVAL_OPERAND
        EX (SP),HL
        CALL FP_INT_CHECK
        LD A,(HL)
        PUSH HL
        LD HL,(L_0CB1)
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
        LD HL,(L_0CB1)
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
        LD HL,(L_0CB1)
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
        JP CRUNCH_EMIT_1
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
        LD (L_0B52),A
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
        LD (L_0B54),HL
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
        LD (L_0B54),HL
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
        LD HL,(L_0B54)
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
        CALL OPEN_FILE_FOR_LOAD_D1
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
        LD (L_0B52),A
        CALL PTRGET_1+1
        JR Z,CHAIN_MARK_VAR_2
        LD A,B
        OR $80
        LD B,A
        XOR A
        CALL PTRGET_SEARCH_22+1
        LD A,$00
        LD (L_0B52),A
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
        LD A,(L_0B14)
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
        LD (L_0B52),A
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
        LD A,(L_0870)
        LD (L_084B),A
        JP OPEN_NAMED_FILE_2
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
; [RE] WRITE statement handler (token $B2): PRINT a comma-separated, quoted list to console/file.
STMT_WRITE:
        LD C,$02
        CALL PARSE_FILENUM_HASH
        DEC HL
        CALL CHRGET
        JR Z,STMT_WRITE_6
STMT_WRITE_1:
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FRMEVL_TEST_TYPE
        JR Z,STMT_WRITE_5
        CALL FOUT_2
        CALL SCAN_STR_LITERAL
        LD HL,(L_0CB1)
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD A,(DE)
        CP $20
        JR NZ,STMT_WRITE_2
        INC DE
        LD (HL),D
        DEC HL
        LD (HL),E
        DEC HL
        DEC (HL)
STMT_WRITE_2:
        CALL STRPRT
STMT_WRITE_3:
        POP HL
        DEC HL
        CALL CHRGET
        JR Z,STMT_WRITE_6
        CP $3B
        JR Z,STMT_WRITE_4
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        DEC HL
STMT_WRITE_4:
        CALL CHRGET
        LD A,$2C
        CALL OUTCHR
        JR STMT_WRITE_1
STMT_WRITE_5:
        LD A,$22
        CALL OUTCHR
        CALL STRPRT
        LD A,$22
        CALL OUTCHR
        JR STMT_WRITE_3
STMT_WRITE_6:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        JR Z,STMT_WRITE_8
        LD A,(HL)
        CP $03
        JR NZ,STMT_WRITE_8
        CALL FILE_BUF_REMAIN
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        LD DE,$FFFE
        ADD HL,DE
        JR NC,STMT_WRITE_8
STMT_WRITE_7:
        LD A,$20
        CALL OUTCHR
        DEC HL
        LD A,H
        OR L
        JR NZ,STMT_WRITE_7
STMT_WRITE_8:
        POP HL
        CALL CRLF
        JP PRINT_RESET_STATE
; [RE] Entry for routines needing a default file# of 1: sets C=1 then falls into PARSE_FILENUM_HASH.
GET_FILENUM_PREFIX_C1:
        LD C,$01
; [RE] If next char is '#', skip it and parse the file-number expr via FILE_NUM_TO_FCB; else return with file# defaulted (C). Used by PRINT#/INPUT#/WRITE#/GET/PUT.
PARSE_FILENUM_HASH:
        CP $23
        RET NZ
        PUSH BC
        CALL FILE_NUM_TO_FCB
        POP DE
        CP E
        JR Z,PARSE_FILENUM_HASH_1
        CP FCB_MODE_RANDOM
        JP NZ,RAISE_BAD_FILE_MODE
PARSE_FILENUM_HASH_1:
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
; [RE] Set current-file FCB pointer (PTRFIL $0840) = BC (the resolved file number); HL preserved.
STORE_CUR_FCB_PTR:
        EX DE,HL
        LD H,B
        LD L,C
        LD (PTRFIL),HL
        EX DE,HL
        RET
; [RE] CHRGET past optional '#', FRMEVL the file-number expr, range-check vs max open files ($0870); index file table at $0850 to BC=FCB base, return mode byte in A ('File not OPEN' if 0).
FILE_NUM_TO_FCB:
        DEC HL
        CALL CHRGET
        CP $23
        CALL Z,CHRGET
        CALL FRMEVL_NOPAREN
; [RE] FILE_NUM_TO_FCB wrapper that sets Z per the FCB mode byte (caller checks open/closed).
FILE_NUM_TO_FCB_NZ:
        CALL CONINT
; [RE] Resolve file# then return the FCB mode byte (file-open type) in A via the table lookup at 763B.
FILE_NUM_TO_FCB_A:
        LD E,A
; [RE] Given file# in E, index file-table $0850 to BC=FCB, load mode byte A=(FCB[0]); OR A sets flags.
FCB_MODE_BYTE:
        LD A,(L_0870)
        CP E
        JP C,RAISE_BAD_FILE_NUMBER
        LD D,$00
        PUSH HL
        LD HL,FILTAB
        ADD HL,DE
        ADD HL,DE
        LD C,(HL)
        INC HL
        LD B,(HL)
        LD A,(BC)
        OR A
        POP HL
        RET
; [RE] Return DE = pointer to the file's data buffer inside its FCB: offset $29 for sequential, $B2 for random (per mode byte).
FCB_BUFFER_PTR:
        CALL FCB_MODE_BYTE
        LD HL,FCB.SEQ_BUF
        CP FCB_MODE_RANDOM
        JR NZ,FCB_BUFFER_PTR_1
        LD HL,FCB.RND_BUF
FCB_BUFFER_PTR_1:
        ADD HL,BC
        EX DE,HL
        RET
; [RE] LOF() handler (function token $30): length-of-file in records (LD A,$02 selects the file-info op).
FN_LOF:
        LD A,$02
; [RE] LOF op-selector flag-skip. 01 here is the LD BC,nn skip-prefix, not a real load: falling through FN_LOF ($7661 LD A,$02) the 01 swallows 3E 04, so A stays $02. FUNC_DISPATCH_TBL $0214 (FN_LOF_1+1, $7664) instead runs 3E 04 = LD A,$04. Converge at $7669 PUSH AF -> CALL FRMEVL_APPLY_OP.
FN_LOF_1:
        LD BC,$043E
; [RE] LOF op-selector flag-skip, arm 3. 01 = LD BC,nn skip-prefix swallowing 3E 08; entrants from FN_LOF/FN_LOF_1+1 keep their A. FUNC_DISPATCH_TBL $0216 (FN_LOF_2+1, $7667) runs 3E 08 = LD A,$08. Converge at $7669 PUSH AF.
FN_LOF_2:
        LD BC,$083E
        PUSH AF
        CALL FRMEVL_APPLY_OP
        POP AF
        CALL ALLOC_STR_A
        LD HL,(L_0B46)
        CALL FP_ARG_SETUP2
        JP STR_FN_RETURN_CHAR_1
; [RE] CVI() function handler (FUNC_DISPATCH_TBL slot $0204; CVS/CVD enter at +offset with widths 2/4/8): free the argument string temp (FRETMP), check it is wide enough (else FC), reinterpret its bytes as a numeric and load the FAC.
FN_CVI:
        LD A,$01
; [RE] CVI/CVS/CVD width-selector flag-skip. 01 = LD BC,nn skip-prefix swallowing 3E 03; FN_CVI ($767A LD A,$01) keeps A=$01. FUNC_DISPATCH_TBL $0206 (FN_CVI_1+1, $767D) runs 3E 03 = LD A,$03. Converge at $7682 PUSH AF; A is the min-string-length checked at $7687 CP (HL).
FN_CVI_1:
        LD BC,$033E
; [RE] CVD width-selector flag-skip, arm 3. 01 = LD BC,nn skip-prefix swallowing 3E 07; entrants from FN_CVI/FN_CVI_1+1 keep their A. FUNC_DISPATCH_TBL $0208 (FN_CVI_2+1, $7680) runs 3E 07 = LD A,$07. Converge at $7682 PUSH AF.
FN_CVI_2:
        LD BC,$073E
        PUSH AF
        CALL FRETMP
        POP AF
        CP (HL)
        JP NC,ERROR_FC
        INC A
        INC HL
        LD C,(HL)
        INC HL
        LD H,(HL)
        LD L,C
        LD (L_0B14),A
        JP FP_ARG_SETUP1
FN_CVI_3:
        CALL FRMEVL_TEST_TYPE
        LD BC,STMT_READ_7
        LD DE,$2C20
        JR NZ,FN_CVI_5
        LD E,D
        JR FN_CVI_5
FN_CVI_4:
        CALL GET_FILENUM_PREFIX_C1
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        LD BC,PRINT_RESET_STATE
        PUSH BC
        PUSH DE
        LD BC,STMT_DATA_4
        XOR A
        LD D,A
        LD E,A
FN_CVI_5:
        PUSH AF
        PUSH BC
        PUSH HL
FN_CVI_6:
        CALL GETC_FILE_EOF
        JP C,RAISE_INPUT_PAST_END
        CP $20
        JR NZ,FN_CVI_7
        INC D
        DEC D
        JR NZ,FN_CVI_6
FN_CVI_7:
        CP $22
        JR NZ,FN_CVI_8
        LD B,A
        LD A,E
        CP $2C
        LD A,B
        JR NZ,FN_CVI_8
        LD D,B
        LD E,B
        CALL GETC_FILE_EOF
        JR C,FN_CVI_12
FN_CVI_8:
        LD HL,BUF
        LD B,$FF
FN_CVI_9:
        LD C,A
        LD A,D
        CP $22
        LD A,C
        JR Z,FN_CVI_10
        CP $0D
        PUSH HL
        JR Z,FN_CVI_15
        POP HL
        CP $0A
        JR NZ,FN_CVI_10
        LD C,A
        LD A,E
        CP $2C
        LD A,C
        CALL NZ,INPUT_BUF_STORE
        CALL GETC_FILE_EOF
        JR C,FN_CVI_12
        CP $0D
        JR NZ,FN_CVI_10
        LD A,E
        CP $20
        JR Z,FN_CVI_11
        CP $2C
        LD A,$0D
        JR Z,FN_CVI_11
FN_CVI_10:
        OR A
        JR Z,FN_CVI_11
        CP D
        JR Z,FN_CVI_12
        CP E
        JR Z,FN_CVI_12
        CALL INPUT_BUF_STORE
FN_CVI_11:
        CALL GETC_FILE_EOF
        JR NC,FN_CVI_9
FN_CVI_12:
        PUSH HL
        CP $22
        JR Z,FN_CVI_13
        CP $20
        JR NZ,FN_CVI_17
FN_CVI_13:
        CALL GETC_FILE_EOF
FN_CVI_14:
        JR C,FN_CVI_17
        CP $20
        JR Z,FN_CVI_13
        CP $2C
        JP Z,FN_CVI_17
        CP $0D
        JR NZ,FN_CVI_16
FN_CVI_15:
        CALL GETC_FILE_EOF
        JR C,FN_CVI_17
        CP $0A
        JR Z,FN_CVI_17
FN_CVI_16:
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_REM
        ADD HL,BC
        INC (HL)
FN_CVI_17:
        POP HL
FN_CVI_18:
        LD (HL),$00
        LD HL,L_0A0D
        LD A,E
        SUB $20
        JR Z,FN_CVI_19
        LD B,D
        LD D,$00
        CALL SCAN_STR_BODY
        POP HL
        RET
FN_CVI_19:
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
; [RE] INPUT#/LINE INPUT# helper: store char A into input buffer (HL++), decrement field count B; on underflow pop caller and bail.
INPUT_BUF_STORE:
        OR A
        RET Z
        LD (HL),A
        INC HL
        DEC B
        RET NZ
        POP BC
        JR FN_CVI_18
; [RE] LOAD entry: D=1 (open-for-input mode) then fall into the file-open core.
OPEN_FILE_FOR_LOAD_D1:
        LD D,$01
; [RE] LOAD/SAVE file-open stub: select channel #0 (XOR A) and enter the OPEN core with the access mode in D.
OPEN_NAMED_FILE:
        XOR A
        JP STMT_OPEN_2
; [RE] LOAD/RUN entry flag-skip. JP NZ,OPEN_NAMED_FILE_1 ($3522/$81CB) reaches $777F OR $AF -> A nonzero (run after load). STMT_DISPATCH_TBL $0180 (OPEN_NAMED_FILE_1+1, $7780) runs the swallowed AF = XOR A -> A=0 (plain LOAD). Converge at $7781 PUSH AF.
OPEN_NAMED_FILE_1:
        OR $AF
        PUSH AF
        CALL OPEN_FILE_FOR_LOAD_D1
        LD A,(L_0870)
        LD (L_084B),A
        DEC HL
        CALL CHRGET
        JR Z,OPEN_NAMED_FILE_3+1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'R'                      ; inline char arg consumed by the preceding CALL
        JP NZ,RAISE_SYNTAX_ERROR
        POP AF
OPEN_NAMED_FILE_2:
        XOR A
        LD (L_0870),A
; [RE] OPEN open-mode flag-skip. Fall-through reaches $77A1 OR $F1 -> A nonzero. JR Z,OPEN_NAMED_FILE_3+1 ($778F) enters $77A2 = the swallowed F1 = POP AF, restoring the saved flag. Converge at $77A3 LD ($084A),A.
OPEN_NAMED_FILE_3:
        OR $F1
        LD (L_084A),A
        LD HL,$0080
        LD (HL),$00
        LD (FILTAB),HL
        CALL CLEAR_VARS
        LD A,(L_084B)
        LD (L_0870),A
        LD HL,(FILTAB_SLOT0_SEED)
        LD (FILTAB),HL
        LD (PTRFIL),HL
        LD HL,(SAVTXT)
        INC HL
        LD A,H
        AND L
        INC A
        JR NZ,OPEN_NAMED_FILE_4
        LD (SAVTXT),HL
OPEN_NAMED_FILE_4:
        CALL GETC_FILE_EOF
        JP C,DIRECT_LINE_DISPATCH
        CP $FE
        JR NZ,OPEN_NAMED_FILE_5
        LD (L_0C99),A
        JR OPEN_NAMED_FILE_6
OPEN_NAMED_FILE_5:
        INC A
        JP NZ,STMT_MERGE_2
OPEN_NAMED_FILE_6:
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
        LD HL,L_0870
        LD A,(HL)
        LD (L_084B),A
        LD (HL),$00
        CALL CLEAR_RESET_DATAPTR
        LD A,(L_084B)
        LD (L_0870),A
        LD A,(CHAIN_BREAK_FLAG)
        OR A
        JP NZ,CHAIN_MOVE_STRING_VAR_3
        LD A,(L_084A)
        OR A
        JP Z,NEWSTT_READY
        JP STMT_FOR_7
; [RE] After LOAD/RUN: close all open files (via CLOSE-all) and re-init variable space (CLEAR_VARS).
LOAD_FINISH_CLOSE_CUR:
        CALL PRINT_RESET_STATE
        CALL FILE_CLOSE_ONE
        JP RESET_RUN_STATE_1
; [RE] RUN with no filename: CLEAR_VARS then jump into the program-run / stack-reset path.
RUN_CLEAR_AND_GO:
        CALL CLEAR_VARS
        JP CHECK_STACK_ROOM_1
; [RE] MERGE statement handler (token $BE): merge an ASCII program file into the current program.
STMT_MERGE:
        POP BC
        CALL OPEN_FILE_FOR_LOAD_D1
        DEC HL
        CALL CHRGET
        JR Z,STMT_MERGE_1
        CALL LOAD_FINISH_CLOSE_CUR
        JP RAISE_SYNTAX_ERROR
STMT_MERGE_1:
        XOR A
        LD (L_084A),A
        CALL GETC_FILE_EOF
        JP C,DIRECT_LINE_DISPATCH
        INC A
        JP Z,RAISE_BAD_FILE_MODE
STMT_MERGE_2:
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_REM
        ADD HL,BC
        INC (HL)
        JP DIRECT_LINE_DISPATCH
; [RE] Direct/immediate-mode statement entry: after CRUNCH tokenizes a console line with no line number, reject it if a file is active (PTRFIL != 0 -> error $42 'Direct statement in file') else execute it via the NEWSTT direct-statement path.
DIRECT_STMT_EXEC:
        PUSH HL
        LD HL,(PTRFIL)
        LD A,H
        OR L
        LD DE,ERR_DIRECT_STATEMENT_IN_FILE
        JP NZ,RAISE_ERROR
        POP HL
        JP NEWSTT_NEXTLINE_2
; [RE] SAVE statement handler (token $C4): save the program to disk (tokenized or ASCII).
STMT_SAVE:
        LD D,$02
        CALL OPEN_NAMED_FILE
        DEC HL
        CALL CHRGET
        JR Z,STMT_SAVE_1
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        CP $50
        JP Z,FILE_BUF_REMAIN_BC_1
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        JP STMT_LIST
STMT_SAVE_1:
        CALL RENUM_PATCH_LINEREFS
        CALL ILLEGAL_DIRECT_CHECK
        LD A,$FF
; [RE] SAVE core: write the tokenized program image (line links + text) byte-by-byte to the open output file via PUTC_FILE (PUTC_FILE), terminating at end-of-program.
SAVE_WRITE_PROGRAM:
        CALL PUTC_FILE
        LD HL,(VARTAB)
        EX DE,HL
        LD HL,(TXTTAB)
SAVE_WRITE_PROGRAM_1:
        CALL CMP_HL_DE
        JP Z,LOAD_FINISH_CLOSE_CUR
        LD A,(HL)
        INC HL
        PUSH DE
        CALL PUTC_FILE
        POP DE
        JR SAVE_WRITE_PROGRAM_1
; [RE] CLOSE statement handler (token $BC): close one or all open file channels.
STMT_CLOSE:
        LD BC,FILE_CLOSE_ONE
        LD A,(L_0870)
        JR NZ,STMT_CLOSE_4
        PUSH HL
STMT_CLOSE_1:
        PUSH BC
        PUSH AF
        LD DE,CLOSE_ALL_LOOP_NEXT
        PUSH DE
        PUSH BC
        RET
; [RE] CLOSE-all loop trampoline (executable bytes shown as DEFB): POP regs, decrement file index, loop to close next file, else POP HL/RET.
CLOSE_ALL_LOOP_NEXT:
        POP AF
        POP BC
        DEC A
        JP P,STMT_CLOSE_1
        POP HL
        RET
; [RE] CLOSE continuation trampoline (executable DEFB): after closing one file, restore BC and check for ',' to close the next listed file number.
CLOSE_ONE_THEN_COMMA:
        POP BC
        POP HL
        LD A,(HL)
        CP $2C
        RET NZ
        CALL CHRGET
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
; [RE] Close every open file (A=0 -> CLOSE-all path of STMT_CLOSE); preserves BC/DE. Used by RUN/NEW/SYSTEM/RESET.
CLOSE_ALL_FILES:
        PUSH DE
        PUSH BC
        XOR A
        CALL STMT_CLOSE
        POP BC
        POP DE
        XOR A
        RET
; [RE] FIELD statement handler (token $B9): define random-file buffer field variables.
STMT_FIELD:
        CALL FILE_NUM_TO_FCB
        JP Z,RAISE_BAD_FILE_NUMBER
        SUB $03
        JP NZ,RAISE_BAD_FILE_MODE
        EX DE,HL
        LD HL,FCB.FLD_BUF_PTR
        ADD HL,BC
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        LD (L_0C93),HL
        LD HL,$0000
        LD (ILLEGAL_DIRECT_CHECK_1),HL
        LD A,H
        EX DE,HL
        LD DE,FCB.RND_BUF
STMT_FIELD_1:
        EX DE,HL
        ADD HL,BC
        LD B,A
        EX DE,HL
        LD A,(HL)
        CP $2C
        RET NZ
        PUSH DE
        PUSH BC
        CALL GETBYT_CHRGET
        PUSH AF
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'S'                      ; inline char arg consumed by the preceding CALL
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        POP AF
        POP BC
        EX (SP),HL
        LD C,A
        PUSH DE
        PUSH HL
        LD HL,(ILLEGAL_DIRECT_CHECK_1)
        LD B,$00
        ADD HL,BC
        LD (ILLEGAL_DIRECT_CHECK_1),HL
        EX DE,HL
        LD HL,(L_0C93)
        CALL CMP_HL_DE
        JP C,RAISE_FIELD_OVERFLOW
        POP HL
        POP DE
        EX DE,HL
        LD (HL),C
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        POP HL
        JR STMT_FIELD_1
; [RE] RSET statement handler (token $C3): right-justify a string into a FIELD buffer variable. LSET (token $C2) enters at $793E with the justify flag cleared.
; [RE] LSET/RSET justify flag-skip via carry. RSET (dispatch $018C) enters $793D OR $37 -> CF cleared. LSET (dispatch $018A, STMT_RSET+1 $793E) runs the swallowed 37 = SCF -> CF set. Both PUSH AF at $793F; downstream reads carry for pad direction.
STMT_RSET:
        OR $37
        PUSH AF
        CALL PTRGET_1+1
        CALL FP_INT_CHECK
        PUSH DE
        CALL EVAL_EXPR_AFTER_SYNCHR
        POP BC
        EX (SP),HL
        PUSH HL
        PUSH BC
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
        JP C,FIELD_PAD_SPACES_2
STMT_RSET_1:
        POP AF
        LD A,C
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
        CP B
        JR NC,STMT_RSET_3
        LD B,A
STMT_RSET_3:
        SUB B
        LD C,A
        POP AF
        CALL NC,FIELD_PAD_SPACES
        INC B
STMT_RSET_4:
        DEC B
        JR Z,STMT_RSET_6
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        JP STMT_RSET_4
STMT_RSET_5:
        POP BC
        POP BC
        POP BC
        POP BC
        POP BC
STMT_RSET_6:
        CALL C,FIELD_PAD_SPACES
        POP HL
        RET
; [RE] LSET/RSET helper: pad the field buffer (DE) with C spaces; used to blank/justify the fixed-width field.
FIELD_PAD_SPACES:
        LD A,$20
        INC C
FIELD_PAD_SPACES_1:
        DEC C
        RET Z
        LD (DE),A
        INC DE
        JR FIELD_PAD_SPACES_1
FIELD_PAD_SPACES_2:
        POP AF
        POP HL
        POP BC
        EX (SP),HL
        EX DE,HL
        JR NZ,FIELD_PAD_SPACES_3
        PUSH BC
        LD A,B
        CALL ALLOC_STR_A
        CALL PUT_STR_TEMP
        POP BC
FIELD_PAD_SPACES_3:
        EX (SP),HL
        PUSH BC
        PUSH HL
        PUSH AF
        JP STMT_RSET_1
FIELD_PAD_SPACES_4:
        CALL CHRGET
        CALL SYNCHR
        DEFB    '$'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    '('                      ; inline char arg consumed by the preceding CALL
        CALL GETBYT
        PUSH DE
        LD A,(HL)
        CP $2C
        JR NZ,FIELD_PAD_SPACES_5
        CALL CHRGET
        CALL FILE_NUM_TO_FCB
        CP $02
        JP Z,RAISE_BAD_FILE_MODE
        CALL STORE_CUR_FCB_PTR
        XOR A
FIELD_PAD_SPACES_5:
        PUSH AF
        CALL SYNCHR
        DEFB    ')'                      ; inline char arg consumed by the preceding CALL
        POP AF
        EX (SP),HL
        PUSH AF
        LD A,L
        OR A
        JP Z,ERROR_FC
        PUSH HL
        CALL ALLOC_STR_A
        EX DE,HL
        POP BC
FIELD_PAD_SPACES_6:
        POP AF
        PUSH AF
        JR Z,FIELD_PAD_SPACES_10
        CALL GET_PENDING_KEY
        JR NZ,FIELD_PAD_SPACES_7
        CALL CONIN
FIELD_PAD_SPACES_7:
        CP $03
        JP Z,FIELD_PAD_SPACES_9
FIELD_PAD_SPACES_8:
        LD (HL),A
        INC HL
        DEC C
        JR NZ,FIELD_PAD_SPACES_6
        POP AF
        CALL PRINT_RESET_STATE
        JP PUT_STR_TEMP
FIELD_PAD_SPACES_9:
        LD HL,(SAVSTK)
        LD SP,HL
        JP RESUME_AT_DIRECT
FIELD_PAD_SPACES_10:
        CALL GETC_FILE_EOF
        JP C,RAISE_INPUT_PAST_END
        JP FIELD_PAD_SPACES_8
; [RE] EOF() function handler (FUNC_DISPATCH_TBL slot $020C): resolve the file number to its FCB and return the end-of-file boolean.
FN_EOF:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        CP $02
        JP Z,RAISE_BAD_FILE_MODE
FN_EOF_1:
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
        CALL FILE_READ_RECORD_FCB
        POP BC
        JR FN_EOF_1
FN_EOF_2:
        LD A,$80
        SUB (HL)
        LD C,A
        LD B,$00
        ADD HL,BC
        INC HL
        LD A,(HL)
        SUB $1A
FN_EOF_3:
        SUB $01
        SBC A,A
        JP INT16_TO_FP
; [RE] Flush the current record via BDOS Write-Sequential ($15) (read-seq = $14); function code from $08CD.
FILE_FLUSH_RECORD:
        LD D,B
        LD E,C
        INC DE
; [RE] Write-sequential error check: BDOS Write-Sequential = $15 (function code held at $08CD).
FILE_FLUSH_RECORD_CK:
        LD HL,FCB.BUF_CNT
        ADD HL,BC
        PUSH BC
        XOR A
        LD (HL),A
        CALL BDOS_SET_DMA_FCB
        LD A,(L_08CD)
        CALL BDOS_FILE_CALL
        CP $FF
        JP Z,RAISE_TOO_MANY_FILES
        DEC A
        JP Z,RAISE_DISK_I_O_ERROR
        DEC A
        JP NZ,FILE_FLUSH_RECORD_CK_1
        POP DE
        XOR A
        LD (DE),A
        LD C,F_CLOSE
        INC DE
        CALL BDOS
        JP RAISE_DISK_FULL
FILE_FLUSH_RECORD_CK_1:
        INC A
        JP Z,RAISE_TOO_MANY_FILES
        POP BC
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
; [RE] Close a single open file: write trailing Ctrl-Z/EOF + flush partial record if dirty, BDOS Close-File ($10), then zero the FCB slot.
FILE_CLOSE_ONE:
        CALL FILE_NUM_TO_FCB_A
        JR Z,FILE_CLOSE_ONE_4
        LD L,E
        PUSH BC
        LD A,(BC)
        LD D,B
        LD E,C
        INC DE
        PUSH DE
        CP $02
        JR NZ,FILE_CLOSE_ONE_3
        INC L
        DEC L
        JR NZ,FILE_CLOSE_ONE_1
        XOR A
        LD (BC),A
FILE_CLOSE_ONE_1:
        LD HL,FILE_CLOSE_ONE_2
        PUSH HL
        PUSH HL
        LD H,B
        LD L,C
        LD A,$1A
        JR PUTC_FILE_1
FILE_CLOSE_ONE_2:
        LD HL,FCB.BUF_CNT
        ADD HL,BC
        LD A,(HL)
        OR A
        CALL NZ,FILE_FLUSH_RECORD_CK
FILE_CLOSE_ONE_3:
        POP DE
        CALL BDOS_SET_DMA_FCB
        LD C,F_CLOSE
        CALL BDOS
        POP BC
FILE_CLOSE_ONE_4:
        LD D,$29
        XOR A
FILE_CLOSE_ONE_5:
        LD (BC),A
        INC BC
        DEC D
        JR NZ,FILE_CLOSE_ONE_5
        RET
; [RE] LOC() function body: return current record/position number from the FCB (random offset $AE vs sequential $26).
FN_LOC_VALUE:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        CP $03
        LD HL,FCB.SEQ_RECNO+1
        JR NZ,FN_LOC_VALUE_1
        LD HL,FCB.RND_RECNO+1
FN_LOC_VALUE_1:
        ADD HL,BC
        LD A,(HL)
        DEC HL
        LD L,(HL)
        JP FP_LOAD_INT_TO_FAC_1
; [RE] LOF()/file-size helper: read a length byte from the FCB ($10 field) and return it as a numeric value.
FN_LOF_VALUE:
        CALL FILE_NUM_TO_FCB_NZ
        JP Z,RAISE_BAD_FILE_NUMBER
        LD HL,FCB.CPM_RC
        ADD HL,BC
        LD A,(HL)
        JP FP_LOAD_INT_TO_FAC
FN_LOF_VALUE_1:
        POP HL
        POP AF
; [RE] Write one byte (A) to the open sequential file buffer; when the 128-byte record fills, flush it via FILE_FLUSH_RECORD and advance the record number.
PUTC_FILE:
        PUSH HL
        PUSH AF
        LD HL,(PTRFIL)
        LD A,(HL)
        CP $01
        JP Z,STMT_ERASE_3
        CP $03
        JP Z,BLOCK_COPY_BC_2
        POP AF
PUTC_FILE_1:
        PUSH DE
        PUSH BC
        LD B,H
        LD C,L
        PUSH AF
        LD DE,FCB.BUF_CNT
        ADD HL,DE
        LD A,(HL)
        CP $80
        PUSH HL
        CALL Z,FILE_FLUSH_RECORD
        POP HL
        INC (HL)
        LD C,(HL)
        LD B,$00
        INC HL
        POP AF
        PUSH AF
        LD D,(HL)
        CP $0D
        LD (HL),B
        JR Z,PUTC_FILE_2
        ADD A,$E0
        LD A,D
        ADC A,B
        LD (HL),A
PUTC_FILE_2:
        ADD HL,BC
        POP AF
        POP BC
        POP DE
        LD (HL),A
        POP HL
        RET
PUTC_FILE_3:
        DEC DE
        DEC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD (HL),$80
        INC HL
        LD (HL),$80
        POP HL
        EX (SP),HL
        LD B,H
        LD C,L
        PUSH HL
        LD HL,FCB.CPM_R0R1R2
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD (HL),$00
        POP HL
        LD A,(L_084C)
        OR A
        JR NZ,PUTC_FILE_4
        CALL FILE_READ_RECORD_FCB
        POP HL
        RET
PUTC_FILE_4:
        CALL FILE_FLUSH_RECORD
        POP HL
        JP PRINT_RESET_STATE
; [RE] LDIR copy of a 128-byte (one CP/M record) block; BC preserved.
COPY_128_BLOCK:
        PUSH BC
        LD BC,$0080
        LDIR
        POP BC
        RET
; [RE] Read next byte from the open sequential input file buffer; when the buffer is exhausted, refill it with the next record (sets carry/Ctrl-Z at EOF).
GETC_FILE:
        PUSH BC
        PUSH HL
GETC_FILE_1:
        LD HL,(PTRFIL)
        LD A,(HL)
        CP $03
        JP Z,BLOCK_COPY_BC_4
        LD BC,FCB.BUF_REM
        ADD HL,BC
        LD A,(HL)
        OR A
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
GETC_FILE_2:
        DEC HL
        LD A,(HL)
        OR A
        JR Z,GETC_FILE_3
        CALL FILE_READ_RECORD
        JR NZ,GETC_FILE_1
GETC_FILE_3:
        SCF
        POP HL
        POP BC
        LD A,$1A
        RET
; [RE] Read the next sequential record from the current file into its FCB buffer (entry that loads the current-file pointer PTRFIL $0840 first).
FILE_READ_RECORD:
        LD HL,(PTRFIL)
; [RE] Bump the FCB record number and BDOS Read-Sequential into the buffer; sets the buffer-status byte (0=data, $80=EOF).
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
        INC BC
        DEC HL
        LD (HL),C
        INC HL
        LD (HL),B
        INC HL
        INC HL
        PUSH HL
        LD BC,$007F
        LD (HL),$00
        PUSH DE
        LD D,H
        LD E,L
        INC DE
        LDIR
        POP DE
        CALL BDOS_SET_DMA_FCB
        LD A,(L_08CC)
        CALL BDOS_FILE_CALL
        OR A
        LD A,$00
        JR NZ,FILE_READ_RECORD_FCB_1
        LD A,$80
FILE_READ_RECORD_FCB_1:
        POP HL
        LD (HL),A
        DEC HL
        LD (HL),A
        OR A
        POP DE
        RET
; [RE] Point CP/M DMA at this file's 128-byte buffer (FCB+$28) via BDOS Set-DMA ($1A) before a read/write.
BDOS_SET_DMA_FCB:
        PUSH BC
        PUSH DE
        PUSH HL
        LD HL,FCB.BUF_REM
        ADD HL,DE
        EX DE,HL
        LD C,F_DMAOFF
        CALL BDOS
        POP HL
        POP DE
        POP BC
        RET
; [RE] GETC_FILE wrapper that detects Ctrl-Z ($1A) as end-of-file: marks the FCB EOF fields and returns carry on EOF.
GETC_FILE_EOF:
        CALL GETC_FILE
        RET C
        CP $1A
        SCF
        CCF
        RET NZ
        PUSH BC
        PUSH HL
        LD HL,(PTRFIL)
        LD BC,FCB.BUF_CNT
        ADD HL,BC
        LD (HL),$00
        INC HL
        LD (HL),$00
        SCF
        POP HL
        POP BC
        RET
; [RE] FRMEVL a string filename, then parse drive/name/ext into the scratch CP/M FCB at $08AA (uppercased, space-padded fields).
PARSE_FILENAME_TO_FCB:
        CALL FRMEVL_NOPAREN
        PUSH HL
        CALL FRETMP
        LD A,(HL)
        OR A
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
        CP $3A
        JR Z,PARSE_FILENAME_TO_FCB_2
        DEC HL
        INC E
PARSE_FILENAME_TO_FCB_1:
        DEC HL
        INC E
        LD C,$40
PARSE_FILENAME_TO_FCB_2:
        DEC E
        JP Z,RAISE_BAD_FILE_NAME
        LD A,C
        SUB $40
        JP C,RAISE_BAD_FILE_NAME
        CP $1B
        JP NC,RAISE_BAD_FILE_NAME
        LD BC,L_08AA
        LD (BC),A
        INC BC
        LD D,$0B
PARSE_FILENAME_TO_FCB_3:
        INC HL
PARSE_FILENAME_TO_FCB_4:
        DEC E
        JP M,FCB_PAD_FIELD_1
        LD A,(HL)
        CP $2E
        JR NZ,PARSE_FILENAME_TO_FCB_5
        CALL FCB_PAD_FIELD
        POP AF
        SCF
        PUSH AF
        JR PARSE_FILENAME_TO_FCB_3
PARSE_FILENAME_TO_FCB_5:
        LD (BC),A
        INC BC
        INC HL
        DEC D
        JR NZ,PARSE_FILENAME_TO_FCB_4
PARSE_FILENAME_TO_FCB_6:
        XOR A
        LD (L_08B6),A
        POP AF
        POP HL
        RET
; [RE] Pad the remaining name/extension field bytes of the FCB with spaces ($20) to the fixed width.
FCB_PAD_FIELD:
        LD A,D
        CP $0B
        JP Z,RAISE_BAD_FILE_NAME
        CP $03
        JP C,RAISE_BAD_FILE_NAME
        RET Z
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        JR FCB_PAD_FIELD
FCB_PAD_FIELD_1:
        INC D
        DEC D
        JR Z,PARSE_FILENAME_TO_FCB_6
FCB_PAD_FIELD_2:
        LD A,$20
        LD (BC),A
        INC BC
        DEC D
        JR NZ,FCB_PAD_FIELD_2
        JR PARSE_FILENAME_TO_FCB_6
; [RE] NAME statement handler (token $C0): rename a disk file (NAME old AS new).
STMT_NAME:
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,L_08AA
        LD C,F_OPEN
        CALL BDOS
        INC A
        JP Z,RAISE_FILE_NOT_FOUND
        LD HL,L_089A
        LD DE,L_08AA
        LD B,$0C
STMT_NAME_1:
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        DJNZ STMT_NAME_1
        POP HL
        CALL SYNCHR
        DEFB    'A'                      ; inline char arg consumed by the preceding CALL
        CALL SYNCHR
        DEFB    'S'                      ; inline char arg consumed by the preceding CALL
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        LD A,(L_08AA)
        LD HL,L_089A
        CP (HL)
        JP NZ,ERROR_FC
        LD DE,L_08AA
        LD C,F_OPEN
        CALL BDOS
        INC A
        JP NZ,RAISE_FILE_ALREADY_EXISTS
        LD C,F_RENAME
        LD DE,L_089A
        CALL BDOS
        POP HL
        RET
; [RE] OPEN statement handler (token $B8): open a disk file on a channel.
STMT_OPEN:
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
STMT_OPEN_1:
        POP HL
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        PUSH DE
        CP $23
        CALL Z,CHRGET
        CALL GETBYT
        CALL SYNCHR
        DEFB    ','                      ; inline char arg consumed by the preceding CALL
        LD A,E
        OR A
        JP Z,RAISE_BAD_FILE_NUMBER
        POP DE
STMT_OPEN_2:
        LD E,A
        PUSH DE
        CALL FILE_NUM_TO_FCB_A
        JP NZ,RAISE_FILE_ALREADY_OPEN
        POP DE
        PUSH BC
        PUSH DE
        CALL PARSE_FILENAME_TO_FCB
        POP DE
        POP BC
        PUSH BC
        PUSH AF
        LD A,D
        CALL FILE_NUM_TO_FCB_2
        POP AF
        LD (L_0B54),HL
        JR C,STMT_OPEN_3
        LD A,E
        OR A
        JP NZ,STMT_OPEN_3
        LD HL,L_08B3
        LD A,(HL)
        CP $20
        JR NZ,STMT_OPEN_3
        LD (HL),$42
        INC HL
        LD (HL),$41
        INC HL
        LD (HL),$53
STMT_OPEN_3:
        POP HL
        LD A,D
        PUSH AF
        LD (PTRFIL),HL
        PUSH HL
        INC HL
        LD DE,L_08AA
        LD C,$0C
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
STMT_OPEN_5:
        LD C,F_MAKE
        CALL BDOS
        INC A
        JP Z,RAISE_TOO_MANY_FILES
        JR STMT_OPEN_7
STMT_OPEN_6:
        LD C,F_OPEN
        CALL BDOS
        INC A
        JR NZ,STMT_OPEN_7
        CALL RAM_DISPATCH_TRAMPOLINE
        CP $03
        JP NZ,RAISE_FILE_NOT_FOUND
        INC DE
        JR STMT_OPEN_5
STMT_OPEN_7:
        POP DE
        POP AF
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
        CALL FILE_READ_RECORD
        LD HL,(L_0B54)
        RET
STMT_OPEN_8:
        LD BC,FCB.SEQ_BUF
        ADD HL,BC
        LD C,$80
STMT_OPEN_9:
        LD (HL),B
        INC HL
        DEC C
        JR NZ,STMT_OPEN_9
        JP RESET_RUN_STATE_1
; [RE] SYSTEM statement handler (token $B7): exit GBASIC back to CP/M (shares the RET NZ pattern of the simple stubs).
STMT_SYSTEM:
        RET NZ
        CALL CLOSE_ALL_FILES
        CALL STMT_TEXT
; [RE] SMC: SYSTEM-exit JP target. Image holds JP $0000 at $7DED; COLD_START ($81E1 LD HL,($0001) -> $81E4 LD (STMT_SYSTEM_WBOOT+1),HL) writes the CP/M BIOS WBOOT vector into the C3 operand. Running SYSTEM (reached from $0E18 or fall-through) then JP <WBOOT> to leave BASIC.
STMT_SYSTEM_WBOOT:
        JP $0000
; [RE] RESET statement handler (token $C5): close all files / reset the disk system.
STMT_RESET:
        RET NZ
        PUSH HL
        CALL CLOSE_ALL_FILES
        LD C,DRV_GET
        CALL BDOS
        PUSH AF
        LD C,DRV_ALLRESET
        CALL BDOS
        POP AF
        LD E,A
        LD C,DRV_SET
        CALL BDOS
        POP HL
        RET
; [RE] KILL statement: parse filename into the default FCB ($0080/$08AA) then BDOS delete-file (C=$13); '?' from BDOS -> error $0D4A. Reached via dispatch DEFW STMT_KILL at $7A58.
STMT_KILL:
        CALL PARSE_FILENAME_TO_FCB
        PUSH HL
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,L_08AA
        PUSH DE
        LD C,F_OPEN
        CALL BDOS
        INC A
        POP DE
        PUSH DE
        PUSH AF
STMT_KILL_1:
        LD C,F_CLOSE
        CALL NZ,BDOS
        POP AF
        POP DE
        JP Z,RAISE_FILE_NOT_FOUND
        LD C,F_DELETE
        CALL BDOS
        POP HL
        RET
; [RE] FILES statement: directory listing. Optional filespec parsed into FCB ($08AA), '*' expanded to '?' (FCB_WILD_IF_STAR), BDOS set-DMA ($1A) + search-first ($11)/search-next ($12); prints each 11-char name with '.' between name and extension via OUTCHR, columns from print-col ($083B).
STMT_FILES:
        JR NZ,STMT_FILES_1
        PUSH HL
        LD HL,L_08AA
        LD (HL),$00
        INC HL
        LD C,$0B
        CALL FCB_WILD_EXPAND
        POP HL
STMT_FILES_1:
        CALL NZ,PARSE_FILENAME_TO_FCB
        XOR A
        LD (L_08B6),A
        PUSH HL
        LD HL,L_08AB
        LD C,$08
        CALL FCB_WILD_IF_STAR
        LD HL,L_08B3
        LD C,$03
        CALL FCB_WILD_IF_STAR
        LD DE,$0080
        LD C,F_DMAOFF
        CALL BDOS
        LD DE,L_08AA
        LD C,F_SFIRST
        CALL BDOS
        CP $FF
        JP Z,RAISE_FILE_NOT_FOUND
STMT_FILES_2:
        AND $03
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        LD C,A
        LD B,$00
        LD HL,$0081
        ADD HL,BC
        LD C,$0B
STMT_FILES_3:
        LD A,(HL)
        INC HL
        CALL OUTCHR
        LD A,C
        CP $04
        JR NZ,STMT_FILES_5
        LD A,(HL)
        CP $20
        JR Z,STMT_FILES_4
        LD A,$2E
STMT_FILES_4:
        CALL OUTCHR
STMT_FILES_5:
        DEC C
        JR NZ,STMT_FILES_3
        LD A,(L_0B11)
        ADD A,$0F
        LD D,A
        LD A,(PRINT_WIDTH)
        CP D
        JR C,STMT_FILES_6
        LD A,$20
        CALL OUTCHR
        CALL OUTCHR
STMT_FILES_6:
        CALL C,CRLF
        LD DE,L_08AA
        LD C,F_SNEXT
        CALL BDOS
        CP $FF
        JR NZ,STMT_FILES_2
        POP HL
        RET
; [RE] If FCB byte is '*' fall into FCB_WILD_EXPAND, else return: handles the leading-'*' wildcard in a FILES/KILL filespec.
FCB_WILD_IF_STAR:
        LD A,(HL)
        CP $2A
        RET NZ
; [RE] Fill C FCB name/ext bytes with '?' ($3F) to turn a '*' wildcard into an all-match field for BDOS directory search.
FCB_WILD_EXPAND:
        LD (HL),$3F
        INC HL
        DEC C
        JR NZ,FCB_WILD_EXPAND
        RET
; [RE] BDOS file-op wrapper: issue BDOS function (A->C) with DE=FCB, then bump the random-record/overflow counter at FCB+$21..$23; map BDOS A-result to BASIC code (0=ok/RET Z, 5=dir-full err $0D62, else 1/2). Used by OPEN/CLOSE/random GET-PUT.
BDOS_FILE_CALL:
        PUSH DE
        LD C,A
        PUSH BC
        CALL BDOS
        POP BC
        POP DE
        PUSH AF
        LD HL,FCB.CPM_CR
        ADD HL,DE
        INC (HL)
        JR NZ,BDOS_FILE_CALL_1
        INC HL
        INC (HL)
        JR NZ,BDOS_FILE_CALL_1
        INC HL
        INC (HL)
BDOS_FILE_CALL_1:
        LD A,C
        CP $22
        JR NZ,BDOS_FILE_CALL_2
        POP AF
        OR A
        RET Z
        CP $05
        JP Z,RAISE_TOO_MANY_FILES
        CP $03
        LD A,$01
        RET Z
        INC A
        RET
BDOS_FILE_CALL_2:
        POP AF
        RET
; [RE] Sequential file read into the data buffer: set DMA via FCB cursor, loop BDOS read-sequential ($14) of 128-byte records (STRING_SPACE_ROOM_CHECK sets FCB ptr), copying each record into the user buffer until DE count exhausted.
FILE_READ_RECORDS:
        EX DE,HL
        CALL STRING_SPACE_ROOM_CHECK
        LD HL,(PTRFIL)
        PUSH HL
        LD BC,FCB.SEQ_BUF+1
        ADD HL,BC
FILE_READ_RECORDS_1:
        CALL COPY_128_BLOCK
        DEC DE
        POP HL
        LD BC,FCB.CPM_CR
        ADD HL,BC
        INC (HL)
FILE_READ_RECORDS_2:
        CALL STRING_SPACE_ROOM_CHECK
        PUSH DE
        LD C,F_DMAOFF
        CALL BDOS
        LD HL,(PTRFIL)
        INC HL
        EX DE,HL
        LD C,F_READ
        CALL BDOS
        OR A
        POP DE
FILE_READ_RECORDS_3:
        LD HL,$0080
        ADD HL,DE
        RET NZ
        EX DE,HL
        JR FILE_READ_RECORDS_2
; [RE] Sequential file read into the data buffer: copy from FCB.SEQ_BUF+1 into the user buffer, loop BDOS read-sequential ($14) of 128-byte records, calling STRING_SPACE_ROOM_CHECK ($7F25, a FRETOP room check -- it does NOT set an FCB ptr) before each transfer, until the DE byte count is exhausted.
STRING_SPACE_ROOM_CHECK:
        LD HL,(FRETOP)
        LD BC,$FF2A
        ADD HL,BC
        CALL CMP_HL_DE
        RET NC
        JP RUN_CLEAR_AND_GO
; [RE] Range-check the file number against the open-file table limit ($0C97) via DCOMPR.
FILE_NUM_TO_FCB_2:
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
FILE_NUM_TO_FCB_2_1:
        PUSH HL
        LD HL,(L_0C97)
        CALL CMP_HL_DE
        JP C,ERROR_FC
        LD HL,FCB.FLD_BUF_PTR
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        XOR A
        LD E,$07
FILE_NUM_TO_FCB_2_2:
        INC HL
        LD (HL),A
        DEC E
        JR NZ,FILE_NUM_TO_FCB_2_2
        POP HL
        POP DE
        RET
; [RE] PUT statement handler (token $BB): write a random-file record. GET (token $BA) enters one byte later at $7F62.
; [RE] GET/PUT direction flag-skip. PUT (dispatch $017C) enters $7F61 OR $AF -> A nonzero (write). GET (dispatch $017A, STMT_PUT+1 $7F62) runs the swallowed AF = XOR A -> A=0 (read). Stored at $7F63 ($81BC), read later to select read vs write.
STMT_PUT:
        OR $AF
        LD (ILLEGAL_DIRECT_CHECK_4),A
        CALL Z,EVAL_CHANNEL_OR_ITEM
        CALL FILE_NUM_TO_FCB
; [RE] GET/PUT random-file record core (shared by STMT_GET/STMT_PUT and PRINT#-to-random): require a mode-3 (random) FCB else 'Bad file mode', parse the optional record#, compute the record byte offset (record# x128) and read/write the 128-byte FIELD record.
GET_PUT_RECORD_CORE:
        CP $03
        JP NZ,RAISE_BAD_FILE_MODE
        PUSH BC
        PUSH HL
        LD HL,FCB.RND_RECNO
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC DE
        EX (SP),HL
        LD A,(HL)
        CP $2C
GET_PUT_RECORD_CORE_1:
        CALL Z,GETINT_CHRGET_POS
        DEC HL
        CALL CHRGET
        JP NZ,RAISE_SYNTAX_ERROR
        EX (SP),HL
        LD A,E
        OR D
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
GET_PUT_RECORD_CORE_2:
        LD B,D
        LD C,E
        LD A,$10
        EX DE,HL
        LD HL,$0000
        PUSH HL
GET_PUT_RECORD_CORE_3:
        ADD HL,HL
        EX (SP),HL
        JR NC,GET_PUT_RECORD_CORE_4
        ADD HL,HL
        INC HL
        JR GET_PUT_RECORD_CORE_5
GET_PUT_RECORD_CORE_4:
        ADD HL,HL
GET_PUT_RECORD_CORE_5:
        EX (SP),HL
        EX DE,HL
        ADD HL,HL
        EX DE,HL
        JR NC,GET_PUT_RECORD_CORE_7
        ADD HL,BC
        EX (SP),HL
        JR NC,GET_PUT_RECORD_CORE_6
        INC HL
GET_PUT_RECORD_CORE_6:
        EX (SP),HL
GET_PUT_RECORD_CORE_7:
        DEC A
        JR NZ,GET_PUT_RECORD_CORE_3
        LD A,L
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
GET_PUT_RECORD_CORE_8:
        LD A,B
        OR A
        JP NZ,ERROR_FC
GET_PUT_RECORD_CORE_9:
        LD (ILLEGAL_DIRECT_CHECK_1),HL
        POP HL
        POP BC
        PUSH HL
        LD HL,FCB.RND_BUF
        ADD HL,BC
        LD (ILLEGAL_DIRECT_CHECK_2),HL
GET_PUT_RECORD_CORE_10:
        LD HL,FCB.SEQ_BUF
        ADD HL,BC
        ADD HL,DE
        LD (ILLEGAL_DIRECT_CHECK_3),HL
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
GET_PUT_RECORD_CORE_11:
        LD A,(ILLEGAL_DIRECT_CHECK_4)
        OR A
        JR Z,GET_PUT_RECORD_CORE_15
        LD DE,$0080
        CALL CMP_HL_DE
        JR NC,GET_PUT_RECORD_CORE_12
        PUSH HL
        CALL FIELD_WRITE_RECORD+1
        POP HL
GET_PUT_RECORD_CORE_12:
        PUSH BC
        LD B,H
        LD C,L
GET_PUT_RECORD_CORE_13:
        LD HL,(ILLEGAL_DIRECT_CHECK_3)
        EX DE,HL
        LD HL,(ILLEGAL_DIRECT_CHECK_2)
        CALL BLOCK_COPY_BC
        LD (ILLEGAL_DIRECT_CHECK_2),HL
        LD D,B
        LD E,C
        POP BC
        CALL FIELD_WRITE_RECORD
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
        LD HL,(ILLEGAL_DIRECT_CHECK_1)
        INC HL
        LD (ILLEGAL_DIRECT_CHECK_1),HL
        JR NZ,GET_PUT_RECORD_CORE_10
        POP HL
        POP HL
        RET
GET_PUT_RECORD_CORE_15:
        PUSH HL
        CALL FIELD_WRITE_RECORD+1
        POP HL
        PUSH BC
        LD B,H
        LD C,L
        LD HL,(ILLEGAL_DIRECT_CHECK_2)
        EX DE,HL
        LD HL,(ILLEGAL_DIRECT_CHECK_3)
        CALL BLOCK_COPY_BC
        EX DE,HL
        LD (ILLEGAL_DIRECT_CHECK_2),HL
        LD D,B
        LD E,C
        POP BC
        JR GET_PUT_RECORD_CORE_14
; [RE] Random-file PUT inner helper: walk the FIELD descriptor chain (FCB+$AB pointer pair), advance the write cursor (ILLEGAL_DIRECT_CHECK_1), and on buffer-full dispatch the record write (PUTC_FILE_3 at $7B5D). Entered at $8077 (skip the OR $AF flag-set) for the no-flag variant.
; [RE] FIELD record-write flag-skip. CALL FIELD_WRITE_RECORD ($8040) hits $8076 OR $AF -> A nonzero. CALL FIELD_WRITE_RECORD+1 ($8029/$805C) runs the swallowed AF = XOR A -> A=0. Stored at $8078 ($084C), tested at $8095 to gate the record-write dispatch.
FIELD_WRITE_RECORD:
        OR $AF
        LD (L_084C),A
        PUSH BC
        PUSH DE
        PUSH HL
FIELD_WRITE_RECORD_1:
        LD HL,(ILLEGAL_DIRECT_CHECK_1)
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
        LD A,(L_084C)
        OR A
        JR Z,FIELD_WRITE_RECORD_3
FIELD_WRITE_RECORD_2:
        LD HL,FIELD_WRITE_RECORD_3
        PUSH HL
        PUSH BC
        PUSH HL
        LD HL,FCB.SEQ_RECNO+1
        ADD HL,BC
        JP PUTC_FILE_3
FIELD_WRITE_RECORD_3:
        POP HL
        POP DE
        POP BC
        RET
; [RE] Copy BC bytes (HL)->(DE) for FIELD/GET/PUT record buffering; preserves BC.
BLOCK_COPY_BC:
        PUSH BC
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
BLOCK_COPY_BC_2:
        POP AF
        PUSH DE
        PUSH BC
        PUSH AF
        LD B,H
        LD C,L
        CALL FILE_BUF_REMAIN_BC
        JP Z,RAISE_FIELD_OVERFLOW
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
        CP $0D
        JR Z,BLOCK_COPY_BC_3
        ADD A,$E0
        LD A,D
        ADC A,$00
        LD (HL),A
BLOCK_COPY_BC_3:
        POP AF
        POP BC
        POP DE
        POP HL
        RET
BLOCK_COPY_BC_4:
        PUSH DE
        CALL FILE_BUF_REMAIN
        JP Z,RAISE_FIELD_OVERFLOW
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
; [RE] Load the FIELD buffer base pointer pair (FCB+$A9) into DE.
FCB_LOAD_BUFPTR:
        LD HL,FCB.FLD_BUF_PTR
        JR FCB_LOAD_POSPTR_1
; [RE] Load the FIELD current-position pointer pair (FCB+$B0) into DE.
FCB_LOAD_POSPTR:
        LD HL,FCB.FLD_POS_PTR
FCB_LOAD_POSPTR_1:
        ADD HL,BC
        LD E,(HL)
        INC HL
        LD D,(HL)
        RET
; [RE] Advance (INC DE) and store the FIELD current-position pointer (FCB+$B0).
FCB_STORE_POSPTR:
        INC DE
        LD HL,FCB.FLD_POS_PTR
        ADD HL,BC
        LD (HL),E
        INC HL
        LD (HL),D
        RET
; [RE] Set BC=FCB then compute remaining bytes in the FIELD buffer: position ptr (FCB+$B0) vs buffer base (FCB+$A9); Z when buffer exhausted (EOF/refill needed).
FILE_BUF_REMAIN:
        LD B,H
        LD C,L
; [RE] Remaining-bytes-in-buffer test with BC already = FCB base (FCB+$B0 position vs FCB+$A9 base); returns Z if empty.
FILE_BUF_REMAIN_BC:
        CALL FCB_LOAD_POSPTR
        PUSH DE
        CALL FCB_LOAD_BUFPTR
        EX DE,HL
        POP DE
        CALL CMP_HL_DE
        RET
FILE_BUF_REMAIN_BC_1:
        CALL CHRGET
        LD (L_0B54),HL
        CALL RENUM_PATCH_LINEREFS
        CALL PROG_UNSCRAMBLE
        LD A,$FE
        CALL SAVE_WRITE_PROGRAM
        CALL PROG_SCRAMBLE
        JP RESET_RUN_STATE_1
; [RE] MS BASIC-80 protected-program DECODE: XOR each program byte ($0846..$0B6F) against two rotating key tables (period 13 from FN_TAN_2, period 11 from FN_RND_5) plus rotating additive constants -- the 'saved with ,P' obfuscation reversal.
PROG_UNSCRAMBLE:
        LD BC,$0D0B
        LD HL,(TXTTAB)
        EX DE,HL
PROG_UNSCRAMBLE_1:
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        RET Z
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
        LD (DE),A
        INC DE
        DEC C
        JR NZ,PROG_UNSCRAMBLE_2
        LD C,$0B
PROG_UNSCRAMBLE_2:
        DEC B
        JR NZ,PROG_UNSCRAMBLE_1
        LD B,$0D
        JR PROG_UNSCRAMBLE_1
; [RE] MS BASIC-80 protected-program ENCODE: inverse of PROG_UNSCRAMBLE, re-applies the dual rotating-key XOR over the program area so the in-memory image stays protected.
PROG_SCRAMBLE:
        LD BC,$0D0B
        LD HL,(TXTTAB)
        EX DE,HL
PROG_SCRAMBLE_1:
        LD HL,(VARTAB)
        CALL CMP_HL_DE
        RET Z
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
ILLEGAL_DIRECT_CHECK_1:
        NOP
        NOP
ILLEGAL_DIRECT_CHECK_2:
        NOP
        NOP
ILLEGAL_DIRECT_CHECK_3:
        NOP
        NOP
ILLEGAL_DIRECT_CHECK_4:
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
        JP NZ,OPEN_NAMED_FILE_1
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
        LD (L_08CC),HL
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
        LD (L_0C97),HL
        LD HL,TEMPST
        LD (TEMPPT),HL
        LD HL,L_0B91
        LD (L_0BF9),HL
        LD HL,($0006)
        LD (MEMSIZ),HL
        LD A,$03
        LD (L_0870),A
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
        LD (L_0870),A
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
        LD (L_0C97),HL
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
        LD A,(L_0870)
        LD HL,SUB_81C6_1
        LD (FILTAB_SLOT0_SEED),HL
        LD DE,FILTAB
        LD (L_0870),A
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
        LD HL,(L_0C97)
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
