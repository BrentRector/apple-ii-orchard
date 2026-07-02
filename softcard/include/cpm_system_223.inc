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

; Memory-config axis. The 60K build lifts the CCP+BDOS +$4000 into the Apple Language
; Card (CCP $9300->$D300, BDOS $9C00->$DC00; the BIOS stays at $FA00). Defining CFG_60K
; re-homes the CCP by re-assembly alone, so the ONE C-level CCP source folds to both the
; 2.23-44K disk (no define) and the 60K CPM60.COM image (CPMV223-60K/CPM60.asm INCLUDEs
; it with -DCFG_60K). The 60K BDOS is a SEPARATE bank-woven build and does NOT fold here.
; See ../CPMV223-60K/CPM60_COM.md and docs/CPM_Unified_Build_Plan.md.
    IFDEF CFG_60K
CCP_BASE   EQU $D300      ; 60K: CCP cold entry, relocated into the language card
CCP_WBOOT  EQU $DB06      ; 60K: CCP warm-boot re-entry
BDOS_FBASE EQU $DC00      ; 60K: BDOS image base (page-zero $0005 JP target)
BDOS_FLIMIT EQU $EA00     ; 60K: first byte past the BDOS image
FASTLOAD_TOP_PAGE EQU $F0 ; 60K: fast-loader top page (TPA reaches up into the LC)
    ELSE
CCP_BASE   EQU $9300      ; CCP cold entry (the BIOS cold/warm boot lands here)
CCP_WBOOT  EQU $9B06      ; CCP warm-boot re-entry the BDOS returns through
BDOS_FBASE EQU $9C00      ; FBASE: BDOS image base (6-byte serial + JP entry)
BDOS_FLIMIT EQU $AA00     ; first byte PAST the BDOS image (CPM_BDOS asserts $ == this)
FASTLOAD_TOP_PAGE EQU $A1 ; 44K: fast-loader top page = just below the CCP ($A1xx)
    ENDIF

; Region sizes computed from the contiguous CCP -> BDOS boundaries above -- never a magic
; number (the byte gate catches any overrun via the CPM_CCP/CPM_BDOS end-of-image ASSERTs).
CCP_SIZE   EQU BDOS_FBASE - CCP_BASE     ; $0900: CCP image size  = (first BDOS byte) - (first CCP byte)
BDOS_SIZE  EQU BDOS_FLIMIT - BDOS_FBASE  ; $0E00: BDOS image size = (byte after BDOS) - (first BDOS byte)
