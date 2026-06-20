; ============================================================================
; CPM_RPC6502.s -- embedded 6502 RPC block of SoftCard CP/M 2.23 (44K)
; ----------------------------------------------------------------------------
; 255 bytes that live at Z-80 $9401-$94FF inside the CCP (the preceding $9400 =
; LD L,B is genuine Z-80; the $9500 = LD A,C resumes Z-80). The SoftCard runs
; these bytes on the 6502 via the CPU switch; from the Z-80 they are opaque
; data, so the Z-80 CCP INCBINs the assembled binary of THIS file and references
; interior addresses below as L_9400 + offset (which relocate with ORG).
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-subroutine-call (RPC)
; mechanism: the Z-80 loads parameter cells, stores the 6502 target at A$VEC
; (0F3D0H) and writes the SoftCard location Z$CPU (0F3DEH) -> 6502 runs the code,
; results read back from the same cells. (How a given Z-80 CALL site SELECTS this
; particular 6502 service remains the OPEN QUESTION below -- [RE], not manual.)
;
; The block is position-independent: every internal reference is a fixed low
; Apple address (I/O-config cells $03E0-$03EB, zero page $2D/$2E/$2F/$35/$38/$3E,
; the slot-ROM page $C088,X, screen holes $0478/$04F8/$05F8, work buffers
; $0900/$0B56/$0C00) or a fixed call into the 2.23 RWTS, and every branch is
; relative. [AI] The $03E0-$03EB working cells sit inside the I/O Configuration
; Block region [DOC S&HD 2-6 ; facts sec.2.2/3] (6502 $200-$3FF = Z-80
; 0F200H-0F3FFH); they are this disk-service's own scratch cells, NOT the manual's
; named config-block structures. The sector buffers ($0478/$04F8) are screen-page-
; adjacent, and the RWTS entry points it calls ($BA99/$BA00/$BF3F/...) are not
; individually enumerated in the manual, so those stay [AI]/[RE].
;
; DIFFERS FROM THE 2.20-44K BLOCK (CPMV220-44K/os/CPM_RPC6502.s). The 2.20 and
; 2.23 blocks share the first ~$84 bytes of structure (retry/restore, sector
; address-field match + skew lookup, motor-on, sector-data mover, slot->index)
; and the IDENTICAL 16-byte sector-skew table at $949E-$94AD, but: [AI]
;   - The absolute RWTS calls target a DIFFERENT fixed region. 2.20 calls the
;     $0Bxx/$0Fxx RWTS ($0F3E/$0F5A/$0F7D/$0B00/$0BC6/$0BDE/$0A25) and reads the
;     skew table via $0F9D,Y; 2.23's RWTS is relocated, so the same logic calls
;     $BA99/$BA00/$BB5F/$BF5B/$BF7E/$BFD3, JMPs $BF3F, and reads skew via $BF9E,Y.
;   - The tail is COMPLETELY different code. 2.20 ends with a warm-boot sector
;     RELOAD routine ($94AD WBOOT_LOAD: point the load buffer at $A400/$E400,
;     loop reading sectors via $0E10). 2.23 instead ends with two NIBBLE
;     translate loops ($94AE-$94EA, below) that pack/unpack a 256-byte page
;     through the 6-and-2 nibble buffers $0900/$0C00 via ($3E),Y.
;   - Trailing fill: 2.20 = FF FF FF 00; 2.23 = 21 bytes of $00 (its routine is
;     shorter, ending at $94EA RTS, so more of the $94xx page is zero padding).
;
; What it does, by routine (run addresses; [AI] inference):
;   $9401  decrement retry counter, restore A/flags, JMP $BF3F (2.23 RWTS entry)
;   $940F  match requested sector against the address field (skew via $BF9E,Y)
;   $943B  set up the drive: motor on ($C088,X), clear flags
;   $945B  read/write the sector data buffer ($0478 / $04F8 banked by bit-7 of $35)
;   $947E  slot ($Cn -> index N): TXA / 4x LSR
;   $9485  (self-modified via $03E4 + ROR $35) sector-data mover
;   $94AE  PRENIBBLE pack: clear $0C00.., then read a page via ($3E),Y, peel the
;          low two bits of each byte into the $0B56,X 2-bit buffer (2x LSR/ROL)
;          and store the high six bits to $0900,Y -- the 6-and-2 disk-write encode
;   $94D3  POSTNIBBLE unpack: re-inject the 2-bit buffer ($0C00,X via 2x LSR/ROL)
;          back into the $0900,Y six-bit data and write the rebuilt page via
;          ($3E),Y -- the 6-and-2 disk-read decode
;
; OPEN QUESTION (carried from the 2.20 analysis) -- the Z-80->6502 dispatch is
; NOT understood. The Z-80 CCP/BDOS CALL several addresses in this block, but
; those land mid-6502-instruction or inside the skew table, not on 6502 routine
; starts, so "the Z-80 CALL target is a 6502 run-address" is WRONG and "address =
; RPC selector" was a hand-wave. How a Z-80 CALL into $94xx actually reaches/
; selects this 6502 service is unresolved (a SoftCard CPU-switch detail). The
; 6502 CODE here is coherent and named accordingly; the Z-80-side entry symbols
; (CPM_CCP.asm SUB_94xx EQUs) are kept verbatim, NOT semantically named.
;
; Clean-room decompile; comments are [AI] inference unless tagged otherwise.
; Reassembles BYTE-IDENTICAL to the on-disk block (ld65 emits the .bin via the
; .cfg; no SAVEBIN). See test_cpm223_reconstruct_byte_identical.
; ============================================================================
.setcpu "6502"
.segment "CODE"

.org $9401

SECTOR_RW:
        DEC $04F8                    ; $9401  CE F8 04   [AI] retry counter (slot-0 screen hole)
        BNE $93EB                    ; $9404  D0 E5      [AI] -> RWTS body (out of block)
        BEQ $93D2                    ; $9406  F0 CA      [AI] -> RWTS body (out of block)
SECTOR_RW_1:
        PLA                          ; $9408  68
        LDA #$40                     ; $9409  A9 40
SECTOR_RW_2:
        PLP                          ; $940B  28
        JMP $BF3F                    ; $940C  4C 3F BF   [AI] 2.23 RWTS entry (2.20: $0F3E)
SECTOR_MATCH:
        BEQ DRIVE_MOTOR_ON           ; $940F  F0 2A
        LDA $2F                      ; $9411  A5 2F
        STA $03E3                    ; $9413  8D E3 03   [AI] I/O-config cell
        LDA $03E2                    ; $9416  AD E2 03
        BEQ SECTOR_MATCH_1           ; $9419  F0 08
        CMP $2F                      ; $941B  C5 2F
        BEQ SECTOR_MATCH_1           ; $941D  F0 04
        LDA #$20                     ; $941F  A9 20
        BNE SECTOR_RW_2              ; $9421  D0 E8
SECTOR_MATCH_1:
        LDA $03E1                    ; $9423  AD E1 03
        TAY                          ; $9426  A8
        LDA $BF9E,Y                  ; $9427  B9 9E BF   [AI] skew lookup (2.20: $0F9D,Y)
        CMP $2D                      ; $942A  C5 2D
        BNE $93CD                    ; $942C  D0 9F      [AI] -> RWTS body (out of block)
        PLP                          ; $942E  28
        BCC DRIVE_MOTOR_ON_2         ; $942F  90 19
        JSR $BA99                    ; $9431  20 99 BA   [AI] 2.23 RWTS helper (2.20: $0B00)
        PHP                          ; $9434  08
        BCS $93CD                    ; $9435  B0 96      [AI] -> RWTS body (out of block)
        PLP                          ; $9437  28
        JSR $BFD3                    ; $9438  20 D3 BF   [AI] 2.23 RWTS helper (2.20: $0BC6)
DRIVE_MOTOR_ON:
        CLC                          ; $943B  18
        LDA #$00                     ; $943C  A9 00
DRIVE_MOTOR_ON_1:
        BIT $38                      ; $943E  24 38      ; (also entered at +1 as LDA #$10/$38 -> see $9451)
        STA $03EA                    ; $9440  8D EA 03   [AI] I/O-config cell
        LDX $05F8                    ; $9443  AE F8 05   [AI] slot index (screen hole)
        LDA $C088,X                  ; $9446  BD 88 C0   [AI] motor on ($C088+slot*16)
        RTS                          ; $9449  60
DRIVE_MOTOR_ON_2:
        JSR $BA00                    ; $944A  20 00 BA   [AI] 2.23 RWTS helper (2.20: $0A25)
        BCC DRIVE_MOTOR_ON           ; $944D  90 EC
        LDA #$10                     ; $944F  A9 10
        BNE DRIVE_MOTOR_ON_1+1       ; $9451  D0 EC      [AI] skip BIT opcode: enters operand $38 of $943E
        ASL                          ; $9453  0A
        JSR $BF5B                    ; $9454  20 5B BF   [AI] 2.23 RWTS helper (2.20: $0F5A)
        LSR $0478                    ; $9457  4E 78 04
        RTS                          ; $945A  60
SECTOR_XFER_BYTE:
        STA $2E                      ; $945B  85 2E
        JSR $BF7E                    ; $945D  20 7E BF   [AI] 2.23 RWTS helper (2.20: $0F7D)
        LDA $0478,Y                  ; $9460  B9 78 04
        BIT $35                      ; $9463  24 35      [AI] bit-7 selects buffer bank
        BMI SECTOR_XFER_BYTE_1       ; $9465  30 03
        LDA $04F8,Y                  ; $9467  B9 F8 04
SECTOR_XFER_BYTE_1:
        STA $0478                    ; $946A  8D 78 04
        LDA $2E                      ; $946D  A5 2E
        BIT $35                      ; $946F  24 35
        BMI SECTOR_XFER_BYTE_2       ; $9471  30 05
        STA $04F8,Y                  ; $9473  99 F8 04
        BPL SECTOR_XFER_BYTE_3       ; $9476  10 03
SECTOR_XFER_BYTE_2:
        STA $0478,Y                  ; $9478  99 78 04
SECTOR_XFER_BYTE_3:
        JMP $BB5F                    ; $947B  4C 5F BB   [AI] 2.23 RWTS continue (2.20: $0BDE)
SLOT_TO_INDEX:
        TXA                          ; $947E  8A         [AI] $Cn slot byte -> index N
        LSR                          ; $947F  4A
        LSR                          ; $9480  4A
        LSR                          ; $9481  4A
        LSR                          ; $9482  4A
        TAY                          ; $9483  A8
        RTS                          ; $9484  60
SECTOR_MOVE:
        PHA                          ; $9485  48
        LDA $03E4                    ; $9486  AD E4 03   [AI] I/O-config cell
        ROR                          ; $9489  6A
        ROR $35                      ; $948A  66 35      [AI] shift bank-select bit into $35
SECTOR_MOVE_1:
        JSR $BF7E                    ; $948C  20 7E BF   [AI] 2.23 RWTS helper (2.20: $0F7D analog)
        PLA                          ; $948F  68
        ASL                          ; $9490  0A
SECTOR_MOVE_2:
        BIT $35                      ; $9491  24 35
        BMI SECTOR_MOVE_4            ; $9493  30 05
        STA $04F8,Y                  ; $9495  99 F8 04
SECTOR_MOVE_3:
        BPL SECTOR_MOVE_5            ; $9498  10 03
SECTOR_MOVE_4:
        STA $0478,Y                  ; $949A  99 78 04
SECTOR_MOVE_5:
        RTS                          ; $949D  60
; [AI] Sector-skew translate table (logical->physical), 16 bytes. IDENTICAL to
;      the 2.20-44K block's table at $949D. Genuine DATA, kept as .byte.
SECTOR_XLATE_TABLE:
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $949E
; [AI] PRENIBBLE encode: pack a 256-byte page (read via ($3E),Y) into 6-and-2
;      nibble form -- high six bits to $0900,Y, the two low bits accumulated into
;      the $0B56,X 2-bit buffer. (Replaces the 2.20 warm-boot sector RELOAD here.)
PRENIBBLE:
        LDX #$55                     ; $94AE  A2 55
        LDA #$00                     ; $94B0  A9 00
PRENIBBLE_CLR:
        STA $0C00,X                  ; $94B2  9D 00 0C   [AI] clear the $0C00 2-bit scratch
        DEX                          ; $94B5  CA
        BPL PRENIBBLE_CLR            ; $94B6  10 FA
PRENIBBLE_INIT:
        TAY                          ; $94B8  A8
        LDX #$AC                     ; $94B9  A2 AC      [AI] entry 1: X = -$54 (high half)
PRENIBBLE_ALT:
        BIT $AAA2                    ; $94BB  2C A2 AA   [AI] skip idiom: entry at +1 = LDX #$AA (entry 2)
PRENIBBLE_LOOP:
        DEY                          ; $94BE  88
        LDA ($3E),Y                  ; $94BF  B1 3E      [AI] source page pointer in $3E/$3F
        LSR                          ; $94C1  4A
        ROL $0B56,X                  ; $94C2  3E 56 0B   [AI] save low bit 0 into 2-bit buffer
        LSR                          ; $94C5  4A
        ROL $0B56,X                  ; $94C6  3E 56 0B   [AI] save low bit 1 into 2-bit buffer
        STA $0900,Y                  ; $94C9  99 00 09   [AI] high six bits -> $0900 buffer
        INX                          ; $94CC  E8
        BNE PRENIBBLE_LOOP           ; $94CD  D0 EF
        TYA                          ; $94CF  98
        BNE PRENIBBLE_ALT+1          ; $94D0  D0 EA      [AI] second pass via skip idiom (LDX #$AA)
        RTS                          ; $94D2  60
; [AI] POSTNIBBLE decode: the inverse -- re-inject the $0C00,X 2-bit buffer into
;      the $0900,Y six-bit data and write the rebuilt page back via ($3E),Y.
POSTNIBBLE:
        LDY #$00                     ; $94D3  A0 00
POSTNIBBLE_NEXT:
        LDX #$56                     ; $94D5  A2 56
POSTNIBBLE_DEX:
        DEX                          ; $94D7  CA
        BMI POSTNIBBLE_NEXT          ; $94D8  30 FB      [AI] wrap X back to $56
        LDA $0900,Y                  ; $94DA  B9 00 09   [AI] six-bit data
        LSR $0C00,X                  ; $94DD  5E 00 0C   [AI] pull low bit 0 from 2-bit buffer
        ROL                          ; $94E0  2A
        LSR $0C00,X                  ; $94E1  5E 00 0C   [AI] pull low bit 1 from 2-bit buffer
        ROL                          ; $94E4  2A
        STA ($3E),Y                  ; $94E5  91 3E      [AI] rebuilt byte -> dest page
        INY                          ; $94E7  C8
        BNE POSTNIBBLE_DEX           ; $94E8  D0 ED
        RTS                          ; $94EA  60
; [AI] Tail padding to the end of the $94xx page (the routine ends at $94EA).
        .res    21, $00              ; $94EB  00 x21
