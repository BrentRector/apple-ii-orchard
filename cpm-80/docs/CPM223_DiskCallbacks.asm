; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- BDOS-support thunks (true home: Z-80
; $A900+ = Apple $B900+; previously misidentified as "Z-80 disk
; callbacks at $1A00")
;
; FRAMING CORRECTED 2026-06-11 (see CPM_SoftCard_RealMap_Findings.md /
; wiseowl.com Part 13). This file's original identity -- "Z-80 disk
; callbacks at $1A00, dual-mapped, separate from the BIOS" -- was an
; artifact of the bit-12-XOR address model; under the real map Z-80
; $1A00 is Apple $2A00 (TPA), and there is no dual mapping anywhere.
;
; VERIFIED PROVENANCE (emu_softcard_v2 byte search, 2026-06-11): these
; bytes live on disk at track 2 file-sector 14, are staged by LOAD_CPM
; at Apple $9600+, and PREP_HANDOFF #3 lands them at Apple $B900+ =
; Z-80 $A900+ -- which is self-consistent with the operands below
; (JP $A929, LD ($A9B1),HL, ... reference the code's own page). They
; are CCP/BDOS-support thunks in the system image, not BIOS disk
; callbacks. The cooperative-CPU disk path actually runs through the
; BIOS RPC machinery (see CPM223_BIOS.asm and the findings doc).
;
; The .ORG $1A00 below is retained as a load-image artifact so the
; byte stream reassembles identically; it has no runtime meaning. All
; "$1Axx" addresses in comments below are therefore file-local labels,
; not Z-80 runtime addresses (true runtime address = $1Axx + $8F00).
; Full re-annotation pending.
; ============================================================================

; ----------------------------------------------------------------------------
; BDOS-area addresses (after CCP+BDOS relocation to $9C06+)
; ----------------------------------------------------------------------------
BDOS_9F01       = $9F01       ; BDOS internal entry
BDOS_9F41       = $9F41       ; BDOS state byte
BDOS_9F42       = $9F42       ; BDOS state byte
BDOS_9F43       = $9F43       ; BDOS state byte
BDOS_9F45       = $9F45       ; BDOS state pointer

BDOS_A301       = $A301       ; BDOS function dispatch
BDOS_A43B       = $A43B
BDOS_A793       = $A793
BDOS_A79C       = $A79C
BDOS_A7D2       = $A7D2
BDOS_A851       = $A851
BDOS_A929       = $A929       ; common BDOS entry
BDOS_A9AD       = $A9AD       ; (state byte address)
BDOS_A9AF       = $A9AF
BDOS_A9B1       = $A9B1
BDOS_A9BB       = $A9BB
BDOS_A9BF       = $A9BF
BDOS_A9D6       = $A9D6
BDOS_A93B       = $A93B

BDOS_A1DA       = $A1DA

; ----------------------------------------------------------------------------
; BIOS state (in trap-marker pages within $FAB8-$FFFF, dual-mapped at
; $1Cxx-$1FFF here)
; ----------------------------------------------------------------------------
state_FECB      = $FECB
state_FED2      = $FED2
state_FED4      = $FED4

    DEVICE NOSLOT64K
            .ORG $1A00


; ============================================================================
; SECTION 1 -- BDOS dispatch thunks ($1A00-$1A40)
;
; Small entry points that do parameter setup and JP into the BDOS
; proper. Some are 4-byte (single-byte op + 3-byte JP); others have
; a small prologue. Indexed/used by CCP and other BDOS-callers.
; ============================================================================

CALLBACKS_START:
          XOR C                           ; $1A00 A9
          JP $A929                        ; $1A01 C3 29 A9
          LD A,($9F42)                    ; $1A04 3A 42 9F
          JP $9F01                        ; $1A07 C3 01 9F
          EX DE,HL                        ; $1A0A EB
          LD ($A9B1),HL                   ; $1A0B 22 B1 A9
          JP $A1DA                        ; $1A0E C3 DA A1
          LD HL,($A9BF)                   ; $1A11 2A BF A9
          JP $A929                        ; $1A14 C3 29 A9
          LD HL,($A9AD)                   ; $1A17 2A AD A9
          JP $A929                        ; $1A1A C3 29 A9
          CALL $A851                      ; $1A1D CD 51 A8
          CALL $A43B                      ; $1A20 CD 3B A4
          JP $A301                        ; $1A23 C3 01 A3
          LD HL,($A9BB)                   ; $1A26 2A BB A9
          LD ($9F45),HL                   ; $1A29 22 45 9F
          RET                             ; $1A2C C9
          LD A,($A9D6)                    ; $1A2D 3A D6 A9
          CP $FF                          ; $1A30 FE FF
          JP NZ,$A93B                     ; $1A32 C2 3B A9
          LD A,($9F41)                    ; $1A35 3A 41 9F
          JP $9F01                        ; $1A38 C3 01 9F
          AND $1F                         ; $1A3B E6 1F
          LD ($9F41),A                    ; $1A3D 32 41 9F
          RET                             ; $1A40 C9
          CALL $A851                      ; $1A41 CD 51 A8
          JP $A793                        ; $1A44 C3 93 A7
          CALL $A851                      ; $1A47 CD 51 A8
          JP $A79C                        ; $1A4A C3 9C A7
          CALL $A851                      ; $1A4D CD 51 A8
          JP $A7D2                        ; $1A50 C3 D2 A7
          LD HL,($9F43)                   ; $1A53 2A 43 9F
          LD A,L                          ; $1A56 7D
          CPL                             ; $1A57 2F
          LD E,A                          ; $1A58 5F
          LD A,H                          ; $1A59 7C
          CPL                             ; $1A5A 2F
          LD HL,($A9AF)                   ; $1A5B 2A AF A9
          AND H                           ; $1A5E A4
          LD D,A                          ; $1A5F 57
          LD A,L                          ; $1A60 7D
          AND E                           ; $1A61 A3
          LD E,A                          ; $1A62 5F
          LD HL,($A9AD)                   ; $1A63 2A AD A9
          EX DE,HL                        ; $1A66 EB
          LD ($A9AF),HL                   ; $1A67 22 AF A9
          LD A,L                          ; $1A6A 7D
          AND E                           ; $1A6B A3
          LD L,A                          ; $1A6C 6F
          LD A,H                          ; $1A6D 7C
          AND D                           ; $1A6E A2
          LD H,A                          ; $1A6F 67
          LD ($A9AD),HL                   ; $1A70 22 AD A9
          RET                             ; $1A73 C9
          LD A,($A9DE)                    ; $1A74 3A DE A9
          OR A                            ; $1A77 B7
          JP Z,$A991                      ; $1A78 CA 91 A9
          LD HL,($9F43)                   ; $1A7B 2A 43 9F
          LD (HL),$00                     ; $1A7E 36 00
          LD A,($A9E0)                    ; $1A80 3A E0 A9
          OR A                            ; $1A83 B7
          JP Z,$A991                      ; $1A84 CA 91 A9
          LD (HL),A                       ; $1A87 77
          LD A,($A9DF)                    ; $1A88 3A DF A9
          LD ($A9D6),A                    ; $1A8B 32 D6 A9
          CALL $A845                      ; $1A8E CD 45 A8
          LD HL,($9F0F)                   ; $1A91 2A 0F 9F
          LD SP,HL                        ; $1A94 F9
          LD HL,($9F45)                   ; $1A95 2A 45 9F
          LD A,L                          ; $1A98 7D
          LD B,H                          ; $1A99 44
          RET                             ; $1A9A C9
          CALL $A851                      ; $1A9B CD 51 A8
          LD A,$02                        ; $1A9E 3E 02
          LD ($A9D5),A                    ; $1AA0 32 D5 A9
          LD C,$00                        ; $1AA3 0E 00
          CALL $A707                      ; $1AA5 CD 07 A7
          CALL Z,$A603                    ; $1AA8 CC 03 A6
          RET                             ; $1AAB C9
          PUSH HL                         ; $1AAC E5
          NOP                             ; $1AAD 00
          NOP                             ; $1AAE 00
          NOP                             ; $1AAF 00
          NOP                             ; $1AB0 00
          ADD A,B                         ; $1AB1 80
          NOP                             ; $1AB2 00
          NOP                             ; $1AB3 00
          NOP                             ; $1AB4 00
          NOP                             ; $1AB5 00
          NOP                             ; $1AB6 00
          NOP                             ; $1AB7 00
          NOP                             ; $1AB8 00
          NOP                             ; $1AB9 00
          NOP                             ; $1ABA 00
          NOP                             ; $1ABB 00
          NOP                             ; $1ABC 00
          NOP                             ; $1ABD 00
          NOP                             ; $1ABE 00
          NOP                             ; $1ABF 00
          NOP                             ; $1AC0 00
          NOP                             ; $1AC1 00
          NOP                             ; $1AC2 00
          NOP                             ; $1AC3 00
          NOP                             ; $1AC4 00
          NOP                             ; $1AC5 00
          NOP                             ; $1AC6 00
          NOP                             ; $1AC7 00
          NOP                             ; $1AC8 00
          NOP                             ; $1AC9 00
          NOP                             ; $1ACA 00
          NOP                             ; $1ACB 00
          NOP                             ; $1ACC 00
          NOP                             ; $1ACD 00
          NOP                             ; $1ACE 00
          NOP                             ; $1ACF 00
          NOP                             ; $1AD0 00
          NOP                             ; $1AD1 00
          NOP                             ; $1AD2 00
          NOP                             ; $1AD3 00
          NOP                             ; $1AD4 00
          NOP                             ; $1AD5 00
          NOP                             ; $1AD6 00
          NOP                             ; $1AD7 00
          NOP                             ; $1AD8 00
          NOP                             ; $1AD9 00
          NOP                             ; $1ADA 00
          NOP                             ; $1ADB 00
          NOP                             ; $1ADC 00
          NOP                             ; $1ADD 00
          NOP                             ; $1ADE 00
          NOP                             ; $1ADF 00
          NOP                             ; $1AE0 00
          NOP                             ; $1AE1 00
          NOP                             ; $1AE2 00
          NOP                             ; $1AE3 00
          NOP                             ; $1AE4 00
          NOP                             ; $1AE5 00
          NOP                             ; $1AE6 00
          NOP                             ; $1AE7 00
          NOP                             ; $1AE8 00
          NOP                             ; $1AE9 00
          NOP                             ; $1AEA 00
          NOP                             ; $1AEB 00
          NOP                             ; $1AEC 00
          NOP                             ; $1AED 00
          NOP                             ; $1AEE 00
          NOP                             ; $1AEF 00
          NOP                             ; $1AF0 00
          NOP                             ; $1AF1 00
          NOP                             ; $1AF2 00
          NOP                             ; $1AF3 00
          NOP                             ; $1AF4 00
          NOP                             ; $1AF5 00
          NOP                             ; $1AF6 00
          NOP                             ; $1AF7 00
          NOP                             ; $1AF8 00
          NOP                             ; $1AF9 00
          NOP                             ; $1AFA 00
          NOP                             ; $1AFB 00
          NOP                             ; $1AFC 00
          NOP                             ; $1AFD 00
          NOP                             ; $1AFE 00
          NOP                             ; $1AFF 00
          RST $38                         ; $1B00 FF
          RST $38                         ; $1B01 FF
          NOP                             ; $1B02 00
          NOP                             ; $1B03 00
          RST $38                         ; $1B04 FF
          RST $38                         ; $1B05 FF
          NOP                             ; $1B06 00
          NOP                             ; $1B07 00
          RST $38                         ; $1B08 FF
          RST $38                         ; $1B09 FF
          NOP                             ; $1B0A 00
          NOP                             ; $1B0B 00
          RST $38                         ; $1B0C FF
          RST $38                         ; $1B0D FF
          NOP                             ; $1B0E 00
          NOP                             ; $1B0F 00
          RST $38                         ; $1B10 FF
          RST $38                         ; $1B11 FF
          NOP                             ; $1B12 00
          NOP                             ; $1B13 00
          RST $38                         ; $1B14 FF
          RST $38                         ; $1B15 FF
          DJNZ $1B28                      ; $1B16 10 10
          RST $38                         ; $1B18 FF
          RST $38                         ; $1B19 FF
          NOP                             ; $1B1A 00
          DJNZ $1B1C                      ; $1B1B 10 FF
          RST $38                         ; $1B1D FF
          DJNZ $1B20                      ; $1B1E 10 00
          RST $38                         ; $1B20 FF
          RST $38                         ; $1B21 FF
          NOP                             ; $1B22 00
          NOP                             ; $1B23 00
          RST $38                         ; $1B24 FF
          RST $38                         ; $1B25 FF
          DJNZ $1B38                      ; $1B26 10 10
          RST $38                         ; $1B28 FF
          RST $38                         ; $1B29 FF
          NOP                             ; $1B2A 00
          DJNZ $1B2C                      ; $1B2B 10 FF
          RST $38                         ; $1B2D FF
          DJNZ $1B30                      ; $1B2E 10 00
          RST $30                         ; $1B30 F7
          RST $30                         ; $1B31 F7
          NOP                             ; $1B32 00
          NOP                             ; $1B33 00
          RST $30                         ; $1B34 F7
          RST $30                         ; $1B35 F7
          NOP                             ; $1B36 00
          DJNZ $1B30                      ; $1B37 10 F7
          RST $30                         ; $1B39 F7
          NOP                             ; $1B3A 00
          NOP                             ; $1B3B 00
          RST $30                         ; $1B3C F7
          RST $30                         ; $1B3D F7
          DJNZ $1B40                      ; $1B3E 10 00
          RST $38                         ; $1B40 FF
          RST $38                         ; $1B41 FF
          NOP                             ; $1B42 00
          NOP                             ; $1B43 00
          RST $38                         ; $1B44 FF
          RST $38                         ; $1B45 FF
          DJNZ $1B58                      ; $1B46 10 10
          RST $38                         ; $1B48 FF
          RST $38                         ; $1B49 FF
          NOP                             ; $1B4A 00
          DJNZ $1B4C                      ; $1B4B 10 FF
          RST $38                         ; $1B4D FF
          DJNZ $1B50                      ; $1B4E 10 00
          RST $38                         ; $1B50 FF
          RST $38                         ; $1B51 FF
          NOP                             ; $1B52 00
          NOP                             ; $1B53 00
          RST $38                         ; $1B54 FF
          RST $38                         ; $1B55 FF
          NOP                             ; $1B56 00
          NOP                             ; $1B57 00
          RST $38                         ; $1B58 FF
          RST $38                         ; $1B59 FF
          NOP                             ; $1B5A 00
          NOP                             ; $1B5B 00
          RST $38                         ; $1B5C FF
          RST $38                         ; $1B5D FF
          NOP                             ; $1B5E 00
          NOP                             ; $1B5F 00
          RST $38                         ; $1B60 FF
          RST $38                         ; $1B61 FF
          NOP                             ; $1B62 00
          NOP                             ; $1B63 00
          RST $38                         ; $1B64 FF
          RST $38                         ; $1B65 FF
          NOP                             ; $1B66 00
          NOP                             ; $1B67 00
          RST $38                         ; $1B68 FF
          RST $38                         ; $1B69 FF
          NOP                             ; $1B6A 00
          NOP                             ; $1B6B 00
          RST $38                         ; $1B6C FF
          RST $38                         ; $1B6D FF
          NOP                             ; $1B6E 00
          NOP                             ; $1B6F 00
          RST $30                         ; $1B70 F7
          RST $30                         ; $1B71 F7
          NOP                             ; $1B72 00
          NOP                             ; $1B73 00
          RST $30                         ; $1B74 F7
          RST $30                         ; $1B75 F7
          NOP                             ; $1B76 00
          NOP                             ; $1B77 00
          RST $30                         ; $1B78 F7
          RST $30                         ; $1B79 F7
          NOP                             ; $1B7A 00
          NOP                             ; $1B7B 00
          RST $30                         ; $1B7C F7
          RST $30                         ; $1B7D F7
          NOP                             ; $1B7E 00
          NOP                             ; $1B7F 00
          RST $38                         ; $1B80 FF
          RST $38                         ; $1B81 FF
          NOP                             ; $1B82 00
          NOP                             ; $1B83 00
          RST $38                         ; $1B84 FF
          RST $38                         ; $1B85 FF
          NOP                             ; $1B86 00
          NOP                             ; $1B87 00
          RST $38                         ; $1B88 FF
          RST $38                         ; $1B89 FF
          NOP                             ; $1B8A 00
          NOP                             ; $1B8B 00
          RST $38                         ; $1B8C FF
          RST $38                         ; $1B8D FF
          NOP                             ; $1B8E 00
          NOP                             ; $1B8F 00
          RST $38                         ; $1B90 FF
          RST $38                         ; $1B91 FF
          NOP                             ; $1B92 00
          NOP                             ; $1B93 00
          RST $38                         ; $1B94 FF
          RST $38                         ; $1B95 FF
          NOP                             ; $1B96 00
          NOP                             ; $1B97 00
          RST $38                         ; $1B98 FF
          RST $38                         ; $1B99 FF
          NOP                             ; $1B9A 00
          NOP                             ; $1B9B 00
          RST $38                         ; $1B9C FF
          RST $38                         ; $1B9D FF
          NOP                             ; $1B9E 00
          NOP                             ; $1B9F 00
          RST $38                         ; $1BA0 FF
          RST $38                         ; $1BA1 FF
          NOP                             ; $1BA2 00
          NOP                             ; $1BA3 00
          RST $38                         ; $1BA4 FF
          RST $38                         ; $1BA5 FF
          NOP                             ; $1BA6 00
          NOP                             ; $1BA7 00
          RST $38                         ; $1BA8 FF
          RST $38                         ; $1BA9 FF
          NOP                             ; $1BAA 00
          NOP                             ; $1BAB 00
          RST $38                         ; $1BAC FF
          RST $38                         ; $1BAD FF
          NOP                             ; $1BAE 00
          NOP                             ; $1BAF 00
          RST $30                         ; $1BB0 F7
          RST $30                         ; $1BB1 F7
          NOP                             ; $1BB2 00
          NOP                             ; $1BB3 00
          RST $30                         ; $1BB4 F7
          RST $30                         ; $1BB5 F7
          NOP                             ; $1BB6 00
          NOP                             ; $1BB7 00
          RST $30                         ; $1BB8 F7
          RST $30                         ; $1BB9 F7
          NOP                             ; $1BBA 00
          NOP                             ; $1BBB 00
          RST $30                         ; $1BBC F7
          RST $30                         ; $1BBD F7
          NOP                             ; $1BBE 00
          NOP                             ; $1BBF 00
          RST $38                         ; $1BC0 FF
          RST $38                         ; $1BC1 FF
          NOP                             ; $1BC2 00
          NOP                             ; $1BC3 00
          RST $38                         ; $1BC4 FF
          RST $38                         ; $1BC5 FF
          NOP                             ; $1BC6 00
          NOP                             ; $1BC7 00
          RST $38                         ; $1BC8 FF
          RST $38                         ; $1BC9 FF
          NOP                             ; $1BCA 00
          NOP                             ; $1BCB 00
          RST $38                         ; $1BCC FF
          RST $38                         ; $1BCD FF
          NOP                             ; $1BCE 00
          NOP                             ; $1BCF 00
          RST $38                         ; $1BD0 FF
          RST $38                         ; $1BD1 FF
          NOP                             ; $1BD2 00
          NOP                             ; $1BD3 00
          RST $38                         ; $1BD4 FF
          RST $38                         ; $1BD5 FF
          NOP                             ; $1BD6 00
          NOP                             ; $1BD7 00
          RST $38                         ; $1BD8 FF
          RST $38                         ; $1BD9 FF
          NOP                             ; $1BDA 00
          NOP                             ; $1BDB 00
          RST $38                         ; $1BDC FF
          RST $38                         ; $1BDD FF
          NOP                             ; $1BDE 00
          NOP                             ; $1BDF 00
          RST $38                         ; $1BE0 FF
          RST $38                         ; $1BE1 FF
          NOP                             ; $1BE2 00
          NOP                             ; $1BE3 00
          RST $38                         ; $1BE4 FF
          RST $38                         ; $1BE5 FF
          NOP                             ; $1BE6 00
          NOP                             ; $1BE7 00
          RST $38                         ; $1BE8 FF
          RST $38                         ; $1BE9 FF
          NOP                             ; $1BEA 00
          NOP                             ; $1BEB 00
          RST $38                         ; $1BEC FF
          RST $38                         ; $1BED FF
          NOP                             ; $1BEE 00
          NOP                             ; $1BEF 00
          RST $30                         ; $1BF0 F7
          RST $30                         ; $1BF1 F7
          NOP                             ; $1BF2 00
          NOP                             ; $1BF3 00
          RST $30                         ; $1BF4 F7
          RST $30                         ; $1BF5 F7
          NOP                             ; $1BF6 00
          NOP                             ; $1BF7 00
          RST $30                         ; $1BF8 F7
          RST $30                         ; $1BF9 F7
          NOP                             ; $1BFA 00
          NOP                             ; $1BFB 00
          RST $30                         ; $1BFC F7
          RST $30                         ; $1BFD F7
          NOP                             ; $1BFE 00


; ============================================================================
; The bytes from approximately $1AAB-$1BFF in newdisk_223 are mostly
; zero-filled and trap-marker patterns, similar to the BIOS layout.
; They serve as state-storage and runtime-installed-handler slots.
; ============================================================================

    SAVEBIN "build/CPM223_DiskCallbacks.bin", $1A00, $0200
