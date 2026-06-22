; msbasic_strdesc.inc -- MS BASIC-80 string value descriptor (the universal "string fat pointer").
;
; Every string VALUE in BASIC-80 is represented not by its bytes but by a 3-byte DESCRIPTOR:
; a length byte followed by a 2-byte little-endian pointer to the character data (which lives in
; the string heap, in program text for constants, or in a FIELD buffer). It is the string analogue
; of BASLINE: a small fixed record the interpreter threads pointers to, never copying the body
; until it must. String-type variables hold a descriptor in the variable table; FRMEVL string
; results are staged as descriptors on the temp-descriptor stack (TEMPPT $0B25 / TEMPST $0B27);
; STORE_STR_DESC builds them in the scratch descriptor DSCTMP ($0B45); GETSPA hands one back for
; freshly allocated heap space.
;
; The descriptor is always touched by SEQUENTIAL pointer stepping (LD A,(HL)=len, INC HL, then the
; pointer word), never by a base+offset literal -- so, like BASLINE, this STRUCT emits NO bytes and
; generates NO operand rewrites; it is the C-level declaration that names the shape and lets the
; reader see "len then ptr" at the descriptor sites. sjasmplus STRUCT emits offset/size EQUs only:
; STRDESC.<field> = byte offset, STRDESC = sizeof ($03).
;
; Canonical access sites (GBASIC run addresses):
;   STR_DESC_STORE ($6BE2)   WRITE: LD (HL),A / INC HL / LD (HL),E / INC HL / LD (HL),D
;                                   -> STRDESC.LEN=A, STRDESC.PTR=DE (low E, high D)
;   STR_BUILD_FROM_DESC ($6BC6) READ: LD A,(HL)=LEN, INC HL, LD C,(HL)/INC HL/LD B,(HL)=PTR
;   FN_VAL_BODY ($6DF2/$6E00) READ: A=LEN, then E=PTR.lo / D=PTR.hi, then LD A,(DE) (first char)
;   STRPRT ($6C46) READ via FP_LOAD_MEM3: D=LEN, C=PTR.lo, B=PTR.hi (then print LEN bytes from BC)
;   NEXT_LOOP_BODY_7 ($6B83) READ: A=LEN, C=PTR.lo, B=PTR.hi (string relational compare)
;
;   C-level shape:  struct strdesc { uint8_t len; uint8_t *ptr; };   /* sizeof == 3 */
    STRUCT STRDESC
LEN     BYTE          ; $00  string length in bytes (0..255)
PTR     WORD          ; $01  little-endian pointer to the character data
    ENDS              ; sizeof(STRDESC) = $03
