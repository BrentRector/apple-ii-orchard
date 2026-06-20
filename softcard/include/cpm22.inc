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
WBOOTV      EQU $0000      ; warm-boot vector: JP WBOOT (a CALL/JP $0000 restarts CP/M)
BDOS        EQU $0005      ; BDOS entry vector: CALL BDOS with C=function, DE=arg
CDISK_ADDR  EQU $0004      ; current drive (low nibble) / user (high nibble)
IOBYTE_ADDR EQU $0003      ; logical<->physical device map (STAT / fns 7,8)
TFCB        EQU $005C      ; default FCB parsed from the command tail
TFCB2       EQU $006C      ; second parsed FCB (overlaps TFCB+16)
TBUFF       EQU $0080      ; default DMA buffer (128 B); also the command-tail buffer
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
FCB_DR      EQU 0          ; drive code (0 = default, 1..16 = A..P)
FCB_F       EQU 1          ; filename (8 bytes, space-padded)
FCB_T       EQU 9          ; filetype (3 bytes; hi bits = R/O, SYS, archive)
FCB_EX      EQU 12         ; current extent
FCB_S1      EQU 13         ; reserved
FCB_S2      EQU 14         ; reserved (extent high)
FCB_RC      EQU 15         ; record count for the current extent (0..128)
FCB_CR      EQU 32         ; current record within the extent
FCB_R0      EQU 33         ; random record number, low byte
FCB_R1      EQU 34         ; random record number, middle byte
FCB_R2      EQU 35         ; random record number, high byte (overflow)
