; ============================================================================
; cpm_system_223.inc -- CP/M 2.23 (44K) cross-module system contract
; ----------------------------------------------------------------------------
; The de-skewed 2.23-44K system image is TWO independent compilations -- the CCP
; ($9300-$9BFF) and the BDOS ($9C00-$A9FF) -- decoded at their true RUNTIME
; addresses (see ../docs/CPM_Skew_Findings.md). On the correctly-addressed source
; the two are almost decoupled: the CCP calls the BDOS only through the page-zero
; $0005 ABI (cpm22.inc :: BDOS), and the ONLY direct cross-module symbols are the
; module bases + the warm-boot re-entry below. Defined ONCE here, INCLUDEd by both
; (never duplicated -- feedback_no_duplicate_symbol_definitions).
; ============================================================================

CCP_BASE   EQU $9300      ; CCP cold entry (the BIOS cold/warm boot lands here)
CCP_WBOOT  EQU $9B06      ; CCP warm-boot re-entry the BDOS returns through
BDOS_FBASE EQU $9C00      ; FBASE: BDOS image base (6-byte serial + JP entry)
BDOS_FLIMIT EQU $AA00     ; first byte PAST the BDOS image (CPM_BDOS asserts $ == this)

; Region sizes computed from the contiguous CCP -> BDOS boundaries above -- never a magic
; number (the byte gate catches any overrun via the CPM_CCP/CPM_BDOS end-of-image ASSERTs).
CCP_SIZE   EQU BDOS_FBASE - CCP_BASE     ; $0900: CCP image size  = (first BDOS byte) - (first CCP byte)
BDOS_SIZE  EQU BDOS_FLIMIT - BDOS_FBASE  ; $0E00: BDOS image size = (byte after BDOS) - (first BDOS byte)
