; ============================================================================
; CPM_RPC6502.s -- embedded 6502 RPC block of SoftCard CP/M 2.20 (44K)
; ----------------------------------------------------------------------------
; 257 bytes that live at Z-80 $9400-$9500 inside the CCP. The SoftCard runs
; them on the 6502 via the CPU switch; from the Z-80 they are opaque data, so
; the Z-80 SystemImage INCBINs the assembled binary of THIS file and references
; the entry points below as L_9400 + offset (which relocate with ORG).
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-subroutine-call (RPC)
; mechanism: the Z-80 loads parameter cells, stores the 6502 target at A$VEC
; (0F3D0H) and writes the SoftCard location Z$CPU (0F3DEH) -> 6502 runs the code,
; results read back from the same cells. (How a given Z-80 CALL site SELECTS this
; particular 6502 service remains the OPEN QUESTION below -- [RE], not manual.)
;
; The block is position-independent (all internal refs are fixed low Apple
; addresses: I/O-config cells $03E0-$03EB, the slot-ROM page $C088,X, monitor
; $FF2D, RWTS helpers $0A25/$0B00/$0BC6/$0BDE/$0E10/$0F3E/$0F5A/$0F7D/$0FAD; all
; branches relative). The $03E0-$03EB working cells sit inside the I/O
; Configuration Block region [DOC S&HD 2-6 ; facts sec.2.2/3] (6502 $200-$3FF =
; Z-80 0F200H-0F3FFH); they are this disk-service's own scratch cells, NOT the
; manual's named config-block structures. This whole block is a warm-boot/RWTS
; disk service; the "Apple disk drivers and disk buffers" concept it implements
; is the documented 6502 $800-$FFF region [DOC S&HD 2-6 ; facts sec.2.2] (Z-80
; 0F800H-0FFFFH) -- though the citation is weak here: this block's OWN sector
; buffers ($0478/$04F8) are screen-page-adjacent, not in $800-$FFF, and the RWTS
; entry points it calls ($0A25/$0B00/...) are not individually enumerated in the
; manual. The SAME bytes serve 44K and 56K -- EXCEPT one byte:
;   $94AE = high byte of the warm-boot disk-load buffer ($A400 44K / $E400 56K),
;           emitted as #>$A400 / #>$E400 under CFG_56K.
;           44K $A400 IS a documented boundary: the start of the "44K CP/M"
;           region $A400-$BFFF [DOC S&HD 2-6 ; facts sec.2.2] (the CP/M system
;           base, just above free-RAM top $A3FF -- NOT itself the free-RAM top).
;           56K $E400 is [RE], taken from the as-shipped 2.20B-56K image: it is
;           NOT in the manual's sec.2.2 56K layout (which is all $D000-$FFFF).
;           It corresponds to the documented 56K CCP base C400H
;           [DOC S&HD 3-41/3-42 ; facts sec.2.3] only AFTER the Z-80<->6502
;           address-translation table [DOC S&HD 2-6/2-32 ; facts sec.2.1] maps
;           Z-80 0C400H -> 6502 $E400 (that derivation is [RE], not a 2-6 read).
;
; What it does (warm-boot / RPC disk service, by routine):
;   $9400  decrement retry counter, restore A/flags, JMP $0F3E (RWTS entry)
;   $940E  match requested sector against the address field (skew via $0F9D,Y)
;   $943A  set up the drive: motor on ($C088,X), clear flags
;   $945A  read/write the sector data buffer ($0478 / $04F8 banked by bit-7 of $35)
;   $9484  (self-modified via cells $9488/$948A) sector-data mover
;   $94AD  warm-boot reload: point the load buffer at $A400 (44K)/$E400 (56K),
;          slot 6, loop reading sectors via $0E10, advancing the buffer page
;
; OPEN QUESTION -- the Z-80->6502 dispatch is NOT understood. The Z-80 CCP/BDOS
; CALLs several addresses in this block (e.g. CALL $9498, CALL $948C), but those
; land mid-6502-instruction or inside the skew table, not on 6502 routine starts.
; So "the Z-80 CALL target is a 6502 run-address" is WRONG, and a simple
; "address = RPC selector" was a hand-wave. How a Z-80 CALL into $94xx actually
; reaches/selects this 6502 service is unresolved (the SoftCard CPU-switch detail).
; The 6502 CODE here is coherent and named accordingly; the Z-80-side entry
; symbols (CPM_SystemImage.asm SUB_94xx EQUs) are kept verbatim, NOT semantically
; named, pending that investigation.
;
; Clean-room decompile; comments are [AI] inference unless tagged otherwise.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502_build).
; ============================================================================
.setcpu "6502"
.segment "CODE"

PRERR           = $FF2D         ; Apple II Monitor: print "ERR" + bell

.org $9400

SECTOR_RW:
        DEC $04F8                    ; $9400  CE F8 04
        BNE $93EA                    ; $9403  D0 E5
        BEQ $93D1                    ; $9405  F0 CA
        PLA                          ; $9407  68
        LDA #$40                     ; $9408  A9 40
SECTOR_RW_1:
        PLP                          ; $940A  28
        JMP $0F3E                    ; $940B  4C 3E 0F
SECTOR_MATCH:
        BEQ DRIVE_MOTOR_ON           ; $940E  F0 2A
        LDA $2F                      ; $9410  A5 2F
        STA $03E3                    ; $9412  8D E3 03
        LDA $03E2                    ; $9415  AD E2 03
        BEQ SECTOR_MATCH_1           ; $9418  F0 08
        CMP $2F                      ; $941A  C5 2F
        BEQ SECTOR_MATCH_1           ; $941C  F0 04
        LDA #$20                     ; $941E  A9 20
        BNE SECTOR_RW_1              ; $9420  D0 E8
SECTOR_MATCH_1:
        LDA $03E1                    ; $9422  AD E1 03
        TAY                          ; $9425  A8
        LDA $0F9D,Y                  ; $9426  B9 9D 0F
        CMP $2D                      ; $9429  C5 2D
        BNE $93CC                    ; $942B  D0 9F
        PLP                          ; $942D  28
        BCC DRIVE_MOTOR_ON_2         ; $942E  90 19
        JSR $0B00                    ; $9430  20 00 0B
        PHP                          ; $9433  08
        BCS $93CC                    ; $9434  B0 96
        PLP                          ; $9436  28
        JSR $0BC6                    ; $9437  20 C6 0B
DRIVE_MOTOR_ON:
        CLC                          ; $943A  18
        LDA #$00                     ; $943B  A9 00
DRIVE_MOTOR_ON_1:
        BIT $38                      ; $943D  24 38
        STA $03EA                    ; $943F  8D EA 03
        LDX $05F8                    ; $9442  AE F8 05
        LDA $C088,X                  ; $9445  BD 88 C0
        RTS                          ; $9448  60
DRIVE_MOTOR_ON_2:
        JSR $0A25                    ; $9449  20 25 0A
        BCC DRIVE_MOTOR_ON           ; $944C  90 EC
        LDA #$10                     ; $944E  A9 10
        BNE DRIVE_MOTOR_ON_1+1       ; $9450  D0 EC
        ASL                          ; $9452  0A
        JSR $0F5A                    ; $9453  20 5A 0F
        LSR $0478                    ; $9456  4E 78 04
        RTS                          ; $9459  60
SECTOR_XFER_BYTE:
        STA $2E                      ; $945A  85 2E
        JSR $0F7D                    ; $945C  20 7D 0F
        LDA $0478,Y                  ; $945F  B9 78 04
        BIT $35                      ; $9462  24 35
        BMI SECTOR_XFER_BYTE_1       ; $9464  30 03
        LDA $04F8,Y                  ; $9466  B9 F8 04
SECTOR_XFER_BYTE_1:
        STA $0478                    ; $9469  8D 78 04
        LDA $2E                      ; $946C  A5 2E
        BIT $35                      ; $946E  24 35
        BMI SECTOR_XFER_BYTE_2       ; $9470  30 05
        STA $04F8,Y                  ; $9472  99 F8 04
        BPL SECTOR_XFER_BYTE_3       ; $9475  10 03
SECTOR_XFER_BYTE_2:
        STA $0478,Y                  ; $9477  99 78 04
SECTOR_XFER_BYTE_3:
        JMP $0BDE                    ; $947A  4C DE 0B
SLOT_TO_INDEX:
        TXA                          ; $947D  8A
        LSR                          ; $947E  4A
        LSR                          ; $947F  4A
        LSR                          ; $9480  4A
        LSR                          ; $9481  4A
        TAY                          ; $9482  A8
        RTS                          ; $9483  60
SECTOR_MOVE:
        PHA                          ; $9484  48
        LDA $03E4                    ; $9485  AD E4 03
        .byte   $6A, $66, $35, $20                               ; $9488
SECTOR_MOVE_1:
        ADC $680F,X                  ; $948C  7D 0F 68
        ASL                          ; $948F  0A
        BIT $35                      ; $9490  24 35
SECTOR_MOVE_2:
        BMI SECTOR_MOVE_4            ; $9492  30 05
        STA $04F8,Y                  ; $9494  99 F8 04
SECTOR_MOVE_3:
        BPL SECTOR_MOVE_5            ; $9497  10 03
SECTOR_MOVE_4:
        STA $0478,Y                  ; $9499  99 78 04
SECTOR_MOVE_5:
        RTS                          ; $949C  60
SECTOR_XLATE_TABLE:
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $949D
; Warm-boot reload: re-reads CP/M (CCP+BDOS) from the boot disk into the system
; image, which is why only ~5K of CP/M's 7K stays resident during a transient.
; [DOC Vol1 1-19 ; facts sec.8.7]
WBOOT_LOAD:
        .ifdef CFG_56K
            lda     #>$E400          ; $94AD  warm-boot load buffer hi (56K)
        .else
            lda     #>$A400          ; $94AD  warm-boot load buffer hi (44K)
        .endif
        STA $03E9                    ; $94AF  8D E9 03
        LDY #$00                     ; $94B2  A0 00
        STY $03E8                    ; $94B4  8C E8 03
WBOOT_LOAD_1:
        STY $03E0                    ; $94B7  8C E0 03
        INY                          ; $94BA  C8
WBOOT_LOAD_2:
        STY $03E4                    ; $94BB  8C E4 03
        STY $03EB                    ; $94BE  8C EB 03
        LDA #$60                     ; $94C1  A9 60   slot 6 (6<<4): the boot disk
        STA $03E6                    ; $94C3  8D E6 03  controller, drives A:/B:, MUST be present [DOC Vol1 1-3/1-4 ; facts sec.8.9]
        LDA #$0B                     ; $94C6  A9 0B
        STA $03E1                    ; $94C8  8D E1 03
        LDA #$1C                     ; $94CB  A9 1C
WBOOT_READ_SECTOR:
        PHA                          ; $94CD  48
        PHP                          ; $94CE  08
        SEI                          ; $94CF  78
WBOOT_READ_SECTOR_1:
        JSR $0E10                    ; $94D0  20 10 0E
        BCC WBOOT_NEXT_SECTOR        ; $94D3  90 08
        JSR PRERR                    ; $94D5  20 2D FF
        PLP                          ; $94D8  28
        PLA                          ; $94D9  68
WBOOT_ERR_MONITOR:
        JMP $0FAD                    ; $94DA  4C AD 0F
WBOOT_NEXT_SECTOR:
        PLP                          ; $94DD  28
        INC $03E9                    ; $94DE  EE E9 03
        LDX $03E1                    ; $94E1  AE E1 03
WBOOT_NEXT_SECTOR_1:
        INX                          ; $94E4  E8
        CPX #$10                     ; $94E5  E0 10
        BNE WBOOT_NEXT_SECTOR_3      ; $94E7  D0 05
WBOOT_NEXT_SECTOR_2:
        LDX #$00                     ; $94E9  A2 00
        INC $03E0                    ; $94EB  EE E0 03
WBOOT_NEXT_SECTOR_3:
        STX $03E1                    ; $94EE  8E E1 03
        PLA                          ; $94F1  68
        SEC                          ; $94F2  38
        SBC #$01                     ; $94F3  E9 01
        BNE WBOOT_READ_SECTOR        ; $94F5  D0 D6
        LDA #$08                     ; $94F7  A9 08
        STA $03E9                    ; $94F9  8D E9 03
        RTS                          ; $94FC  60
        .byte   $FF, $FF, $FF, $00                               ; $94FD
