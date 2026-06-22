; msbasic_fcb.inc -- MS BASIC-80 file-control-block (FCB) / per-file entry layout (SoftCard CP/M).
;
; FILTAB ($0850) is a packed array of 2-byte little-endian pointers, one per file number; each
; points at ONE FCB -- the per-file record modeled by this struct. The file-I/O code accesses the
; record by byte offset from the FCB base, so this STRUCT lets those offset literals read as
; FCB.<field>. It emits NO bytes (offset/size EQUs only): FCB.<field> = the field's byte offset,
; FCB = the full entry size ($132).
;
; The embedded standard 36-byte CP/M FCB begins at entry offset $01 (every BDOS call is passed
; DE = FCB_base + 1), so the CP/M sub-fields below are CP/M-convention offsets within that block.
; Two entry sizes exist: file #0 (the program / LOAD-SAVE channel) uses only the first $A9 bytes
; (through SEQ_BUF; it never enters random mode), while user files #1..N use the full $132-byte
; entry (the random FIELD window + RND_BUF). Offsets are byte-verified against GBASIC.COM.
    STRUCT FCB
MODE          BYTE          ; $00  file mode: 0=closed, 1=seq input, 2=seq output, 3=random
CPM_DR        BYTE          ; $01  CP/M FCB drive (start of the embedded 36-byte CP/M FCB)
CPM_NAME      BLOCK 8       ; $02  CP/M filename[8]
CPM_EXT       BLOCK 3       ; $0A  CP/M type/extension[3]
CPM_EX        BYTE          ; $0D  CP/M current extent
CPM_S1        BYTE          ; $0E  CP/M reserved (S1)
CPM_S2        BYTE          ; $0F  CP/M reserved (S2)
CPM_RC        BYTE          ; $10  CP/M record count in this extent (read by LOF)
CPM_ALLOC     BLOCK 16      ; $11  CP/M allocation map (disk block list)
CPM_CR        BYTE          ; $21  CP/M current record within the extent
CPM_R0R1R2    BLOCK 3       ; $22  CP/M random-record number (24-bit, R0/R1/R2)
SEQ_RECNO     WORD          ; $25  MS-BASIC sequential record number
BUF_CNT       BYTE          ; $27  byte count / fill level within the data buffer
BUF_REM       BYTE          ; $28  buffer status (0=data, $80=EOF) / remaining-bytes counter
SEQ_BUF       BLOCK 128     ; $29  sequential data buffer (one CP/M record; also the BDOS DMA target)
FLD_BUF_PTR   WORD          ; $A9  FIELD buffer base pointer (random entries only)
FLD_DESC_PTR  WORD          ; $AB  FIELD descriptor / field-end pointer
RND_RECNO     WORD          ; $AD  random record number (LOC returns its high byte)
PAD_AF        BYTE          ; $AF  unused/padding between RND_RECNO and FLD_POS_PTR
FLD_POS_PTR   WORD          ; $B0  FIELD current-position (write/read cursor) pointer
RND_BUF       BLOCK 128     ; $B2  random data buffer (FIELD window)
    ENDS                    ; sizeof(FCB) = $132 (user file entry); file #0 uses only $00..$A8
