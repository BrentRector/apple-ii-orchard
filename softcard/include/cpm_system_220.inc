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

CCP_ENTRY  EQU $9400      ; CBASE: CCP cold entry (JP cold-start); BDOS fn 0 / warm boot returns here
BDOS_FBASE EQU $9C00      ; FBASE: BDOS image base (6-byte serial + JP $9C06 entry); top-of-TPA marker the CCP loads
BIOS_FBASE EQU $AA00      ; WBOOT/BIOS base = the first byte PAST the BDOS image (CPM_BDOS asserts $ == this)

; Region sizes are computed from the contiguous module boundaries above -- never a magic
; number -- so they track the image layout (and the byte gate catches any overrun via the
; CPM_BDOS end-of-image ASSERT). CCP -> BDOS -> BIOS are back-to-back.
CCP_SIZE   EQU BDOS_FBASE - CCP_ENTRY     ; $0800: CCP image size  = (first BDOS byte) - (first CCP byte)
BDOS_SIZE  EQU BIOS_FBASE - BDOS_FBASE    ; $0E00: BDOS image size = (byte after BDOS) - (first BDOS byte)
