; msbasic_line.inc -- MS BASIC-80 program-line record (the program-text linked-list node).
;
; A BASIC program is stored as a SINGLY-LINKED list of variable-length line records, head at
; TXTTAB. Each node is { LINK word, LINENUM word, CRUNCH-tokenized text, $00 }. The list is
; walked FORWARD only (FNDLIN $0F88; CHEAD relink $0F39); a LINK word of $0000 terminates the
; program (the "double-zero" end marker). There is NO back-link -- edits rebuild the forward
; chain (CHEAD) and close gaps with block moves rather than splicing a doubly-linked node out.
;
; The interpreter reaches the fields by SEQUENTIAL pointer stepping (LD A,(HL)/INC HL), never by
; a base+offset literal, so -- unlike the FCB -- this STRUCT generates no operand rewrites; it is
; the canonical C-level declaration of the program's central record and gives the forward LINK a
; name. sjasmplus STRUCT emits NO bytes (offset/size EQUs only): BASLINE.<field> = byte offset,
; BASLINE = the fixed-header size ($04). TOKENS is a zero-length flexible-array member (the C
; `uint8_t tokens[]` idiom): BASLINE.TOKENS names where the token bytes begin (+$04) without
; contributing to the header size, since the tail is variable-length and $00-terminated.
;
;   C-level shape:  struct line { struct line *link; uint16_t linenum; uint8_t tokens[]; };
    STRUCT BASLINE
LINK    WORD          ; $00  forward link -> next line node ($0000 = end of program)
LINENUM WORD          ; $02  line number
TOKENS  BLOCK 0       ; $04  CRUNCH-tokenized statement bytes, $00-terminated (flexible tail)
    ENDS              ; sizeof(BASLINE) = $04 (fixed header; tokens follow, variable length)
