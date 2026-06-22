; msbasic_var.inc -- MS BASIC-80 in-memory variable storage records (SoftCard CP/M GBASIC/MBASIC).
;
; Three pointer cells in the interpreter low-RAM workspace bound two contiguous tables that grow
; upward from just above the tokenized program text:
;
;   VARTAB ($0B6F) .. ARYTAB ($0B71) : the SIMPLE-VARIABLE table (one SIMPLEVAR record per scalar)
;   ARYTAB ($0B71) .. STREND ($0B73) : the ARRAY table          (one ARRAYVAR record per array)
;   STREND ($0B73)                   : first free byte above the array table (string heap below it
;                                      grows DOWN from FRETOP $0B48; the two meet on Out of memory)
;
; ACCESS PATTERN (the reason this is a DOCUMENTATION struct, not a base+offset one): every field is
; reached by SEQUENTIAL pointer stepping (LD x,(HL)/INC HL) or a COMPUTED stride (ADD HL,DE), never
; by a constant base+offset literal -- the records are variable-length (long names + per-array dim
; lists) so there are no fixed offsets to rewrite. The whole file uses NO IX/IY indexed addressing.
; Like BASLINE, sjasmplus STRUCT emits NO bytes here: SIMPLEVAR.<field>/ARRAYVAR.<field> are byte
; offsets and SIMPLEVAR/ARRAYVAR are the fixed-header sizes; the variable tails (NAMEXT, DIMSIZE,
; DATA) are flexible-array members (BLOCK 0). This file is the C-level declaration of the two
; central runtime records; it generates no operand rewrites and is byte-neutral.
;
; The type/width byte at offset 0 of both records is the stored copy of VALTYP (the live cell is
; $0B14); it follows the canonical width scheme (see msbasic_valtyp.inc, VT_*):
;   VT_INT=$02 integer (2B)   VT_STR=$03 string descriptor (len + 2-byte ptr)
;   VT_SNG=$04 single  (4B)   VT_DBL=$08 double (8B)
; (set/test helpers at $4FDA/$502D/$3DC8; the descriptor itself is { byte len; word data-ptr } --
;  see GETSPA/STR_DESC_STORE at $6C58/$6BE2 and msbasic_strdesc.inc.)
;
;   C-level shapes:
;     struct simplevar { uint8_t valtyp; uint8_t name0, name1; uint8_t namextlen;
;                        uint8_t namext[namextlen]; uint8_t value[valtyp]; };
;     struct arrayvar  { uint8_t valtyp; uint8_t name0, name1; uint8_t namextlen;
;                        uint8_t namext[namextlen]; uint16_t blklen; uint8_t ndims;
;                        uint16_t dimsize[ndims];  /* high dim first */
;                        uint8_t  data[/*prod(dimsize)*/ * valtyp]; /* row-major */ };

    STRUCT SIMPLEVAR
SV_VALTYP    BYTE        ; $00  value type/width: VT_INT $02 / VT_STR $03 / VT_SNG $04 / VT_DBL $08 (= live $0B14)
SV_NAME0     BYTE        ; $01  packed name char 1   (search compares to C, e.g. $5FE9)
SV_NAME1     BYTE        ; $02  packed name char 2   (search compares to B, e.g. $5FF3)
SV_NAMEXTLEN BYTE        ; $03  count of extra name chars that follow (0 if name <= 2 chars)
SV_NAMEXT    BLOCK 0     ; $04  namext[SV_NAMEXTLEN] then value[SV_VALTYP]; stride = NAMEXTLEN+VALTYP+1
    ENDS                 ; sizeof header = $04; record is variable-length (computed stride)

    STRUCT ARRAYVAR
AV_VALTYP    BYTE        ; $00  element type/width (VT_INT/STR/SNG/DBL) (= live $0B14, stored $6186)
AV_NAME0     BYTE        ; $01  packed name char 1   (search compares to C, $6142)
AV_NAME1     BYTE        ; $02  packed name char 2   (search compares to B, $614C)
AV_NAMEXTLEN BYTE        ; $03  count of extra name chars that follow (skipped at $6150)
AV_NAMEXT    BLOCK 0     ; $04  namext[AV_NAMEXTLEN] then: blklen word, ndims byte, dimsize[ndims], data[]
    ENDS                 ; header to start-of-name = $04; blklen/ndims/dims follow the (variable) name

; Fixed sub-fields that follow the variable name extension (offsets RELATIVE to end of NAMEXT):
AV_BLKLEN    EQU 0       ; word: total bytes from this descriptor's blklen field to the next descriptor
                         ;       (the stored inter-entry stride; read $6155, used in GARBAG_7 $6CE5)
AV_NDIMS     EQU 2       ; byte: number of dimensions (stored $619F; read $61ED; ERASE walks $6A17)
AV_DIMSIZE   EQU 3       ; word[NDIMS]: per-dimension size, HIGH dimension first (read $61F1)
                         ; data[] (VALTYP-wide, row-major) follows the dim list
