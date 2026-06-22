; msbasic_valtyp.inc -- Microsoft BASIC-80 Rev 5.2 (SoftCard CP/M 2.20)
; VALTYP value-type code stored in the 1-byte cell $0B14 (L_0B14).
;
; CANONICAL MS BASIC-80 SCHEME: VALTYP == the storage width, in bytes, of
; the value currently held in the FAC ($0CB1 mantissa cells). This is the
; SAME convention as Microsoft 8080/Z80 BASIC-80 (the "VALTYP" byte) and is
; what the interpreter relies on directly: FP_MOVE_TYPED ($4EC9) loads VALTYP
; into B and DJNZ-copies exactly that many bytes, and PTRGET adds VALTYP to
; the variable-name length to size a simple variable's storage ($6053).
;
; OBSERVED proof (all in GBASIC.COM, addresses are run-image $):
;   VT_INT=2  FP_STORE_FAC_INT ($4FD7) stores the 16-bit integer in HL then
;             SET_TYPE_INTEGER ($4FDA) writes $02; FN_CSNG ($4FF2 JP M) treats
;             $02 (2-3=$FF -> sign set) as the integer-to-single source.
;   VT_STR=3  FRMEVL_TEST_TYPE ($3DCF SUB $03) returns Z only for $03 = string;
;             INKEY$/string-temp stores write $03 ($67ED, $6C25) and copy the
;             3-byte string descriptor (length + 2-byte text pointer).
;   VT_SNG=4  SET_TYPE_DOUBLE_1+1 ($5030 LD A,$04) sets single (RND, CINT->SNG,
;             INT_TO_SINGLE); FOUT ($574F CP $04) splits single vs double print.
;   VT_DBL=8  SET_TYPE_DOUBLE ($502D LD A,$08); FRMEVL_TEST_TYPE ($3DCB CP $08)
;             & FN_CDBL ($501D RET NC) treat >=8 as already-double; FIN ($54A3)
;             seeds the numeric-literal accumulator as double.
;
; Ordering note: the codes also sort by precision width (2<3<4<8), which the
; numeric/string discriminator exploits ("CP $08" / "SUB $03" / "CP $05").
; EQUs are zero-width, so INCLUDEing this is byte-identical.

VT_INT           EQU $02   ; integer  : 16-bit signed, stored at $0CB1 (2 bytes)
VT_STR           EQU $03   ; string   : 3-byte descriptor = length + 2-byte ptr
VT_SNG           EQU $04   ; single   : 4-byte MBF float
VT_DBL           EQU $08   ; double   : 8-byte MBF float

; -- Operator-routine dispatch bands (OPERATOR_ROUTINE_TBL $04F9). The arithmetic
;    dispatch table holds one 5-entry band (ADD / SUB-or-NEG / MUL / DIV / COMPARE,
;    each a 2-byte DEFW) per numeric VALTYP, selected by adding the band base to the
;    table address. Naming the +10/+20/+30 offsets ties FRMEVL's type-banded dispatch
;    ($3B80/$3BA6/$3BCE/$4002) to the VT_* widths above. Pure offset EQUs (byte-safe).
OP_BAND_DBL      EQU 10    ; +10 ($0503): double-precision arithmetic band (VT_DBL)
OP_BAND_SNG      EQU 20    ; +20 ($050D): single-precision arithmetic band (VT_SNG)
OP_BAND_INT      EQU 30    ; +30 ($0517): 16-bit integer arithmetic band   (VT_INT)
