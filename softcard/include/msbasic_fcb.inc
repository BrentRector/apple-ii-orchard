; msbasic_fcb.inc -- MS BASIC-80 file-control-block (FCB) / per-file entry layout (SoftCard CP/M).
;
; FILTAB ($0850) is a packed array of 2-byte little-endian pointers, one per file number; each
; points at ONE FCB -- the per-file record modeled by STRUCT FCB below. The file-I/O code accesses
; the record by byte offset from the FCB base, so this STRUCT lets those offset literals read as
; FCB.<field>. It emits NO bytes (offset/size EQUs only).
;
; The per-file entry is BASIC's own 1-byte MODE followed by a STANDARD CP/M 2.2 File Control Block
; (modeled as the nested STRUCT CPMFCB) followed by BASIC's sequential/random buffers and FIELD
; cursors. Because the embedded block is the canonical CP/M FCB, we use the canonical Digital
; Research field names (DR/F/T/EX/S1/S2/RC/AL/CR/R0/R1/R2) rather than ad-hoc ones, reached as
; FCB.CPM.<field>. The CP/M FCB sits at entry offset $01, so every BDOS call is passed
; DE = FCB_base + 1 = &FCB.CPM. Two entry sizes exist: file #0 (the program / LOAD-SAVE channel)
; uses only the first $A9 bytes (through SEQ_BUF; it never enters random mode), while user files
; #1..N use the full $132-byte entry (the random FIELD window + RND_BUF). Offsets are byte-verified
; against GBASIC.COM.

; ---- Standard CP/M 2.2 File Control Block (36 bytes) -----------------------------------------
; Canonical Digital Research layout. [DOC CP/M 2.2 Interface Guide, Sec. 5; cross-checked against
; www.seasip.info/Cpm/fcb.html and the CP/M 2.2 manual at www.gaby.de/cpm.] The same layout is
; carried as flat offset EQUs (FCB_DR..FCB_R2) in cpm22.inc.
    STRUCT CPMFCB
DR    BYTE          ; $00  drive: 0 = use default, 1-16 = A-P
F     BLOCK 8       ; $01  filename F1-F8 (7-bit ASCII, space-padded)
T     BLOCK 3       ; $09  type T1-T3 (high bits: T1'=read-only, T2'=system/hidden, T3'=archive)
EX    BYTE          ; $0C  current extent (low byte); set to 0 when opening
S1    BYTE          ; $0D  reserved for the BDOS
S2    BYTE          ; $0E  reserved (extent high byte / module); set to 0 when opening
RC    BYTE          ; $0F  record count in the current extent (0-128); read by LOF
AL    BLOCK 16      ; $10  allocation map D0-D15 (the file's disk block list)
CR    BYTE          ; $20  current record within the extent (sequential read/write cursor)
R0    BYTE          ; $21  random record number, low byte
R1    BYTE          ; $22  random record number, middle byte
R2    BYTE          ; $23  random record number, high byte (overflow)
    ENDS            ; sizeof(CPMFCB) = $24 (36)

; ---- BASIC per-file entry: MODE + the CP/M FCB + BASIC's buffers/FIELD cursors ----------------
    STRUCT FCB
MODE          BYTE          ; $00  file mode: 0=closed, 1=seq input, 2=seq output, 3=random (FCB_MODE_*)
CPM           CPMFCB        ; $01  the standard CP/M FCB (BDOS calls pass DE = FCB_base+1 = &FCB.CPM)
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

; FCB.MODE values (file open-mode; FCB[0]). Set by STMT_OPEN from the mode letter
; (I/O/R); read by the sequential-vs-random data-path dispatch to route GET/PUT/print.
; Distinct from VALTYP (msbasic_valtyp.inc) which also uses 2/3/8 -- these are file
; modes, not variable types. Pure numeric EQUs (build-independent, byte-safe).
FCB_MODE_CLOSED   EQU 0   ; file slot not open
FCB_MODE_SEQ_IN   EQU 1   ; OPEN "I" -- sequential input
FCB_MODE_SEQ_OUT  EQU 2   ; OPEN "O" -- sequential output
FCB_MODE_RANDOM   EQU 3   ; OPEN "R" -- random access (FIELD/GET/PUT)
