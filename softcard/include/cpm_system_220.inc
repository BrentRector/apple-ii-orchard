; ============================================================================
; cpm_system_220.inc -- CP/M 2.20 (44K) cross-module system contract
; ----------------------------------------------------------------------------
; The de-skewed 2.20-44K system image is TWO independent compilations -- the CCP
; ($9400-$9BFF) and the BDOS ($9C00-$A9FF) -- decoded at their true RUNTIME
; addresses (see ../docs/CPM_Skew_Findings.md). On the correctly-addressed source
; the two are almost decoupled: the CCP calls the BDOS only through the page-zero
; $0005 ABI (cpm22.inc :: BDOS), and the ONLY direct cross-module symbols are the
; two module bases below. They are defined ONCE here and INCLUDEd by both modules
; (never duplicated -- feedback_no_duplicate_symbol_definitions). The earlier
; "59 CCP->BDOS cross-refs" were sector-skew artifacts and do not exist on the
; de-skewed source.
; ============================================================================

; Memory-config axis: the 56K (Language Card) system is the 44K image lifted +$3000
; (CCP $9400->$C400, BDOS $9C00->$CC00, BIOS $AA00->$DA00 = Apple LC $D400/$DC00/$EA00).
; Because every address below is derived from this single offset, defining CFG_56K
; (the build's -D flag) re-homes the whole 2.20 OS by re-assembly alone -- no per-cell
; edits. See ../docs/CPM_56K_60K_Fold_Plan.md.
    IFDEF CFG_56K
OS_RELOC   EQU $3000      ; 56K: OS relocated into the Apple Language Card
    ELSE
OS_RELOC   EQU $0000      ; 44K: OS in main RAM (the base build)
    ENDIF

CCP_ENTRY  EQU $9400 + OS_RELOC  ; CBASE: CCP cold entry (JP cold-start); BDOS fn 0 / warm boot returns here
BDOS_FBASE EQU $9C00 + OS_RELOC  ; FBASE: BDOS image base (6-byte serial + JP +6 entry); top-of-TPA marker the CCP loads
BIOS_FBASE EQU $AA00 + OS_RELOC  ; WBOOT/BIOS base = the first byte PAST the BDOS image (CPM_BDOS asserts $ == this)

; Region sizes are computed from the contiguous module boundaries above -- never a magic
; number -- so they track the image layout (and the byte gate catches any overrun via the
; CPM_BDOS end-of-image ASSERT). CCP -> BDOS -> BIOS are back-to-back.
CCP_SIZE   EQU BDOS_FBASE - CCP_ENTRY     ; $0800: CCP image size  = (first BDOS byte) - (first CCP byte)
BDOS_SIZE  EQU BIOS_FBASE - BDOS_FBASE    ; $0E00: BDOS image size = (byte after BDOS) - (first BDOS byte)

; --- CCP cells referenced cross-module (single source of truth, by label arithmetic) ---
; CCP_INLEN ($9407 = CCP_ENTRY+7): the CCP console-line returned-count byte (CCP_INBUF+1).
; It doubles as the staged / auto-command flag -- nonzero on CCP entry means a command line
; is already staged in CCP_CMDTEXT and is re-parsed instead of re-prompting (the SUBMIT/$SUB
; chaining hook). The CCP warm-start clears it; the 2.20B BIOS warm-boot path ALSO clears it
; (XOR A; LD (CCP_INLEN),A) so a BIOS-driven warm boot discards any stale staged command and
; the CCP re-prompts cleanly. (The base 2.20 BIOS does not reference it; this is the lone
; genuine BIOS->CCP cell, introduced by 2.20B.)
CCP_INLEN  EQU CCP_ENTRY + 7
