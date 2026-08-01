; cpm22.inc -- canonical Digital Research CP/M 2.2 definitions shared by SoftCard
; CP/M sources.  Defined ONCE here and INCLUDEd by each source rather than re-deriving
; magic numbers per file.  EQUs are zero-width, so including this is byte-identical.
; This is the OS/ABI counterpart to apple_softcard.inc (which holds the Apple/SoftCard
; HARDWARE externals); keep the two concerns separate.
;
; Source: CP/M 2.2 Interface Guide / "CP/M Reference Manual" [DOC CPMREF] (in the
; archive at softcard/reference/softcard-cpm-archive/manuals/transcribed/).
;
; NOTE on the base page: $0000 (warm-boot JP) and $0005 (BDOS JP) are implementation
; LABELS inside the BIOS/CCP/BDOS modules but CALL TARGETS in transient programs.  The
; cell EQUs below are for the transient-program (caller) view; an OS module that DEFINES
; these vectors as its own labels should not also pull in this base-page section.

; ---- base page (transient-program view) ----------------------------------------
    IFNDEF CPM22_INC
    DEFINE CPM22_INC

WBOOTV      EQU $0000      ; warm-boot vector: JP WBOOT (a CALL/JP $0000 restarts CP/M)
IOBYTE_ADDR EQU $0003      ; logical<->physical device map (STAT / fns 7,8)
CDISK_ADDR  EQU $0004      ; current drive (low nibble) / user (high nibble)
BDOS        EQU $0005      ; BDOS entry vector: CALL BDOS with C=function, DE=arg
RST2_VEC    EQU $0010      ; Z-80 RST 2 ($10) restart vector (8 bytes); CP/M leaves it for the app/debugger
RST4_VEC    EQU $0020      ; Z-80 RST 4 ($20) restart vector (8 bytes); CP/M leaves it for the app/debugger
TFCB        EQU $005C      ; default FCB parsed from the command tail
TFCB2       EQU $006C      ; second parsed FCB (overlaps TFCB+16)
TBUFF       EQU $0080      ; default DMA buffer (128 B); also the command-tail buffer
CMDLINE     EQU $0081      ; command-tail characters (TBUFF+1): $0080 = length, $0081+ = the upper-cased tail
TPA         EQU $0100      ; transient program area / load address

; ---- BDOS function numbers (register C) ----------------------------------------
P_TERMCPM   EQU 0          ; system reset (return to CCP)
C_READ      EQU 1          ; console input (echoed) -> A
C_WRITE     EQU 2          ; console output (E = char)
A_READ      EQU 3          ; reader (AUX) input -> A
A_WRITE     EQU 4          ; punch (AUX) output (E = char)
L_WRITE     EQU 5          ; list (printer) output (E = char)
C_RAWIO     EQU 6          ; direct console I/O (E=$FF read / else write)
A_STATIN    EQU 7          ; get IOBYTE -> A
A_STATOUT   EQU 8          ; set IOBYTE (E = value)
C_WRITESTR  EQU 9          ; print '$'-terminated string (DE -> string)
C_READSTR   EQU 10         ; buffered console line input (DE -> buffer)
C_STAT      EQU 11         ; console status -> A (0 = none ready)
S_BDOSVER   EQU 12         ; return BDOS version -> HL
DRV_ALLRESET EQU 13        ; reset disk system
DRV_SET     EQU 14         ; select drive (E = 0=A..15=P)
F_OPEN      EQU 15         ; open file (DE -> FCB)
F_CLOSE     EQU 16         ; close file (DE -> FCB)
F_SFIRST    EQU 17         ; search for first (DE -> FCB)
F_SNEXT     EQU 18         ; search for next
F_DELETE    EQU 19         ; delete file (DE -> FCB)
F_READ      EQU 20         ; read sequential (DE -> FCB)
F_WRITE     EQU 21         ; write sequential (DE -> FCB)
F_MAKE      EQU 22         ; create file (DE -> FCB)
F_RENAME    EQU 23         ; rename file (DE -> FCB)
DRV_LOGINVEC EQU 24        ; return login vector -> HL
DRV_GET     EQU 25         ; return current drive -> A
F_DMAOFF    EQU 26         ; set DMA address (DE)
DRV_ALLOCVEC EQU 27        ; return allocation vector -> HL
DRV_SETRO   EQU 28         ; write-protect current drive
DRV_ROVEC   EQU 29         ; return read-only vector -> HL
F_ATTRIB    EQU 30         ; set file attributes (DE -> FCB)
DRV_DPB     EQU 31         ; return DPB address -> HL
F_USERNUM   EQU 32         ; get/set user number (E=$FF get / else set)
F_READRAND  EQU 33         ; read random (DE -> FCB)
F_WRITERAND EQU 34         ; write random (DE -> FCB)
F_SIZE      EQU 35         ; compute file size (DE -> FCB)
F_RANDREC   EQU 36         ; set random record (DE -> FCB)
DRV_RESET   EQU 37         ; reset drives (DE = drive vector)
F_WRITEZF   EQU 40         ; write random with zero fill (DE -> FCB)

; ---- FCB field offsets (from the start of a 36-byte FCB) ------------------------
; ---------------------------------------------------------------------------
; CP/M 2.2 on-disk / in-memory STRUCTURES.
;
; These replace the flat FCB_* offset EQUs that used to live here. A structure
; gives the field a NAME at the use site instead of a bare number, and it lets a
; step between two fields be written as arithmetic on the names, which a magic
; number cannot be checked against. That is the same rule the repo already
; applies to code sizes (a size is label-after minus label-on-first-byte).
;
; It is not cosmetic. Every structure below had a field mislabelled in the
; sources at some point, and each time the cause was the same: the operand was a
; bare number, so nothing contradicted a wrong comment. FCB offset 12 was called
; "the current-record byte" at twelve sites across two trees; the DPB byte the
; deblock tests was called a "deblock flag"; the DPH word holding the DPB pointer
; was reached by an unnamed +10.
;
; A DIRECTORY ENTRY and an FCB are the same 32 bytes, with the FCB adding four:
;
;      0                              31 32   33 34 35
;     +--------------------------------+-----+--------+
;     |          DIRENT (32)           | CR  | R0 R1 R2|
;     +--------------------------------+-----+--------+
;     |<---------- FCB (36) ---------------------------->|
;
; So reach a shared field through the structure you actually hold:
;   holding an FCB          ->  FCB.DIRENT.EX
;   holding a directory     ->  DIRENT.EX          (e.g. entries in DIRBUF)
; Both are 12. The difference is that the NAME states which one the code has,
; and that distinction is real: ALLOC_FROM_FCB, despite its name, walks a
; DIRECTORY ENTRY out of DIRBUF, not a user FCB.
; ---------------------------------------------------------------------------
    STRUCT DIRENT
ST          BYTE           ; 0   status. In a DIRECTORY entry this is the user
                           ;     number (0..31), or $E5 for a free/deleted slot.
                           ;     In an FCB the same byte is DRI's DR, the drive
                           ;     code (0 = default, 1..16 = A..P). One byte, two
                           ;     meanings, depending on which structure you hold.
FN          BLOCK 8        ; 1   filename, space-padded
FT          BLOCK 3        ; 9   filetype; high bits flag R/O, SYS, archive
EX          BYTE           ; 12  extent number, LOW 5 BITS ONLY. The extent is a
                           ;     PAIR: EX + 32*S2. This is NOT the current record;
                           ;     CR is at offset 32 and is 7 bits (0..127).
S1          BYTE           ; 13  reserved
S2          BYTE           ; 14  extent number, high bits (see EX)
RC          BYTE           ; 15  record count for the current extent (0..128)
AL          BLOCK 16       ; 16  allocation map: 16 block bytes, or 8 block words
                           ;     when DSM > 255 (see BLOCK_WIDTH_FLAG)
    ENDS                   ; = 32

    STRUCT FCB
DIRENT      DIRENT         ; 0   the directory-entry image, byte for byte
CR          BYTE           ; 32  current record within the extent (0..127)
R0          BYTE           ; 33  random record number, low byte
R1          BYTE           ; 34  random record number, middle byte
R2          BYTE           ; 35  random record number, high byte (overflow)
    ENDS                   ; = 36

    ASSERT DIRENT == 32                  ; a directory entry is 32 bytes
    ASSERT FCB.CR == DIRENT              ; CR begins where the directory entry ends
    ASSERT FCB == DIRENT + 4
    ASSERT FCB.DIRENT.EX == DIRENT.EX    ; the prefix really is shared

; Disk Parameter Block, the 15 bytes the BIOS hands the BDOS per drive.
; NAMED *_LAYOUT because the OS sources already use DPB, DPH_TABLE, SPT, DSM and OFF as
; INSTANCE labels for the real data block in CPM_BIOS.asm. This is the TYPE, not the instance.
    STRUCT DPB_LAYOUT
SPT         WORD           ; 0   sectors (128-byte RECORDS) per track
BSH         BYTE           ; 2   block shift: log2(records per block)
BLM         BYTE           ; 3   block mask: (records per block) - 1
EXM         BYTE           ; 4   extent mask
DSM         WORD           ; 5   highest allocation block number
DRM         WORD           ; 7   highest directory entry number
AL0         BYTE           ; 9   directory-reserved block bitmap, high byte
AL1         BYTE           ; 10  ditto, low byte
CKS         WORD           ; 11  directory checksum vector size
OFF         WORD           ; 13  reserved tracks before the file area
    ENDS                   ; = 15

    ASSERT DPB_LAYOUT.DSM == 5      ; SELDSK reaches the DSM byte with a bare +5
    ASSERT DPB_LAYOUT == 15

; Disk Parameter Header, one per drive, 16 bytes.
    STRUCT DPH_LAYOUT
XLT         WORD           ; 0   sector-translate table, or 0 for none
SCRATCH     BLOCK 6        ; 2   BDOS scratch (3 words)
DIRBUF      WORD           ; 8   -> the 128-byte directory buffer (one per system)
DPB         WORD           ; 10  -> this drive's DPB
CSV         WORD           ; 12  -> directory checksum vector
ALV         WORD           ; 14  -> allocation vector
    ENDS                   ; = 16

    ASSERT DPH_LAYOUT.DPB == 10     ; SELDSK reaches the DPB pointer with a bare +10
    ASSERT DPH_LAYOUT == 16


    ENDIF
