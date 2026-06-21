; msbasic_tokens.inc -- Microsoft BASIC-80 Rev 5.2 (SoftCard CP/M 2.20) single-byte
; keyword/operator TOKENS.  CRUNCH folds reserved words to these one-byte tokens via
; the per-letter index at $021E, the name table at $0252-$04D7 (last char high-bit set,
; token byte follows), and the operator sub-table at $04D8.  SYNCHR matches an expected
; token as the inline byte after `CALL SYNCHR`; this include NAMES those token bytes so
; the source reads `DEFB TOK_TO` instead of `DEFB $DD`.
;
; Validated against the $0108 statement-dispatch table (every $81-$D5 entry resolves to
; its STMT_* handler).  EQUs are zero-width, so INCLUDEing this is byte-identical.
;
; Naming: TOK_<KEYWORD>; operators (not valid identifiers) get a mnemonic name.  This is
; the subset reached inline by the parsers (SYNCHR / FRMEVL); the full token table lives
; in the reserved-word table itself and can be added here as needed.

; -- Tokens matched inline by SYNCHR (the parser's expected-token checks) --
TOK_INPUT       EQU $85   ; INPUT                 (e.g. LINE INPUT, in STMT_LINE)
TOK_GOTO        EQU $89   ; GOTO (also 'GO TO')   (e.g. ON ... GOTO, in STMT_ON)
TOK_TO          EQU $DD   ; TO                    (FOR ... TO, in STMT_FOR)
TOK_THEN        EQU $DE   ; THEN                  (IF ... THEN, in STMT_IF)
TOK_FN          EQU $E2   ; FN                    (DEF FN / FN call name)
TOK_EQ          EQU $F0   ; '=' assign/relational (FOR/LET/DEF/COLOR= , in STMT_FOR/LET/...)

; -- Other sequencing keywords a parser may match inline --
TOK_ELSE        EQU $9E   ; ELSE
TOK_STEP        EQU $E0   ; STEP
TOK_USING       EQU $E8   ; PRINT USING
TOK_REM         EQU $8F   ; REM  (the "'" operator token $EA expands to ':REM')

; -- Operator tokens (CRUNCH operator sub-table at $04D8; matched by FRMEVL) --
TOK_GT          EQU $EF   ; '>'
TOK_LT          EQU $F1   ; '<'
TOK_PLUS        EQU $F2   ; '+'
TOK_MINUS       EQU $F3   ; '-'
TOK_MUL         EQU $F4   ; '*'
TOK_DIV         EQU $F5   ; '/'
TOK_POW         EQU $F6   ; '^'
TOK_IDIV        EQU $FD   ; '\' integer divide
TOK_AND         EQU $F7   ; AND
TOK_OR          EQU $F8   ; OR
TOK_XOR         EQU $F9   ; XOR
TOK_EQV         EQU $FA   ; EQV
TOK_IMP         EQU $FB   ; IMP
TOK_MOD         EQU $FC   ; MOD
TOK_NOT         EQU $E4   ; NOT
