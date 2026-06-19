; ============================================================================
; CPM_RPC6502.s -- embedded 6502 RPC block of SoftCard CP/M 2.20 (44K)
; ----------------------------------------------------------------------------
; 257 bytes that live at Z-80 $9400-$9500 inside the CCP. The SoftCard runs
; them on the 6502 via the CPU switch; from the Z-80 they are opaque data, so
; the Z-80 SystemImage INCBINs the assembled binary of THIS file and references
; the entry points below as L_9400 + offset (which relocate with ORG).
;
; The block is position-independent (all internal refs are fixed low Apple
; addresses: I/O-config cells $03E0-$03EB, the slot-ROM page $C088,X, monitor
; $FF2D, RWTS helpers $0A25/$0B00/$0BC6/$0BDE/$0E10/$0F3E/$0F5A/$0F7D/$0FAD; all
; branches relative). The SAME bytes serve 44K and 56K -- EXCEPT one byte:
;   $94AE = high byte of the warm-boot disk-load buffer ($A400 44K / $E400 56K),
;           emitted as #>$A400 / #>$E400 under CFG_56K.
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
; Clean-room decompile; comments are [AI] inference unless tagged otherwise.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502_build).
; ============================================================================
.setcpu "6502"
.segment "CODE"

.org $9400

L_9400:
        DEC $04F8                    ; $9400  CE F8 04
        BNE $93EA                    ; $9403  D0 E5
        BEQ $93D1                    ; $9405  F0 CA
        PLA                          ; $9407  68
        LDA #$40                     ; $9408  A9 40
L_940A:
        PLP                          ; $940A  28
        JMP $0F3E                    ; $940B  4C 3E 0F
L_940E:
        BEQ L_943A                   ; $940E  F0 2A
        LDA $2F                      ; $9410  A5 2F
        STA $03E3                    ; $9412  8D E3 03
        LDA $03E2                    ; $9415  AD E2 03
        BEQ L_9422                   ; $9418  F0 08
        CMP $2F                      ; $941A  C5 2F
        BEQ L_9422                   ; $941C  F0 04
        LDA #$20                     ; $941E  A9 20
        BNE L_940A                   ; $9420  D0 E8
L_9422:
        LDA $03E1                    ; $9422  AD E1 03
        TAY                          ; $9425  A8
        LDA $0F9D,Y                  ; $9426  B9 9D 0F
        CMP $2D                      ; $9429  C5 2D
        BNE $93CC                    ; $942B  D0 9F
        PLP                          ; $942D  28
        BCC L_9449                   ; $942E  90 19
        JSR $0B00                    ; $9430  20 00 0B
        PHP                          ; $9433  08
        BCS $93CC                    ; $9434  B0 96
        PLP                          ; $9436  28
        JSR $0BC6                    ; $9437  20 C6 0B
L_943A:
        CLC                          ; $943A  18
        LDA #$00                     ; $943B  A9 00
L_943D:
        BIT $38                      ; $943D  24 38
        STA $03EA                    ; $943F  8D EA 03
        LDX $05F8                    ; $9442  AE F8 05
        LDA $C088,X                  ; $9445  BD 88 C0
        RTS                          ; $9448  60
L_9449:
        JSR $0A25                    ; $9449  20 25 0A
        BCC L_943A                   ; $944C  90 EC
        LDA #$10                     ; $944E  A9 10
        BNE L_943D+1                 ; $9450  D0 EC
        ASL                          ; $9452  0A
        JSR $0F5A                    ; $9453  20 5A 0F
        LSR $0478                    ; $9456  4E 78 04
        RTS                          ; $9459  60
L_945A:
        STA $2E                      ; $945A  85 2E
        JSR $0F7D                    ; $945C  20 7D 0F
        LDA $0478,Y                  ; $945F  B9 78 04
        BIT $35                      ; $9462  24 35
        BMI L_9469                   ; $9464  30 03
        LDA $04F8,Y                  ; $9466  B9 F8 04
L_9469:
        STA $0478                    ; $9469  8D 78 04
        LDA $2E                      ; $946C  A5 2E
        BIT $35                      ; $946E  24 35
        BMI L_9477                   ; $9470  30 05
        STA $04F8,Y                  ; $9472  99 F8 04
        BPL L_947A                   ; $9475  10 03
L_9477:
        STA $0478,Y                  ; $9477  99 78 04
L_947A:
        JMP $0BDE                    ; $947A  4C DE 0B
L_947D:
        TXA                          ; $947D  8A
        LSR                          ; $947E  4A
        LSR                          ; $947F  4A
        LSR                          ; $9480  4A
        LSR                          ; $9481  4A
        TAY                          ; $9482  A8
        RTS                          ; $9483  60
L_9484:
        PHA                          ; $9484  48
        LDA $03E4                    ; $9485  AD E4 03
        .byte   $6A, $66, $35, $20                               ; $9488
L_948C:
        ADC $680F,X                  ; $948C  7D 0F 68
        ASL                          ; $948F  0A
        BIT $35                      ; $9490  24 35
L_9492:
        BMI L_9499                   ; $9492  30 05
        STA $04F8,Y                  ; $9494  99 F8 04
L_9497:
        BPL L_949C                   ; $9497  10 03
L_9499:
        STA $0478,Y                  ; $9499  99 78 04
L_949C:
        RTS                          ; $949C  60
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F ; $949D
L_94AD:
        .ifdef CFG_56K
            lda     #>$E400          ; $94AD  warm-boot load buffer hi (56K)
        .else
            lda     #>$A400          ; $94AD  warm-boot load buffer hi (44K)
        .endif
        STA $03E9                    ; $94AF  8D E9 03
        LDY #$00                     ; $94B2  A0 00
        STY $03E8                    ; $94B4  8C E8 03
L_94B7:
        STY $03E0                    ; $94B7  8C E0 03
        INY                          ; $94BA  C8
L_94BB:
        STY $03E4                    ; $94BB  8C E4 03
        STY $03EB                    ; $94BE  8C EB 03
        LDA #$60                     ; $94C1  A9 60
        STA $03E6                    ; $94C3  8D E6 03
        LDA #$0B                     ; $94C6  A9 0B
        STA $03E1                    ; $94C8  8D E1 03
        LDA #$1C                     ; $94CB  A9 1C
L_94CD:
        PHA                          ; $94CD  48
        PHP                          ; $94CE  08
        SEI                          ; $94CF  78
L_94D0:
        JSR $0E10                    ; $94D0  20 10 0E
        BCC L_94DD                   ; $94D3  90 08
        JSR $FF2D                    ; $94D5  20 2D FF
        PLP                          ; $94D8  28
        PLA                          ; $94D9  68
L_94DA:
        JMP $0FAD                    ; $94DA  4C AD 0F
L_94DD:
        PLP                          ; $94DD  28
        INC $03E9                    ; $94DE  EE E9 03
        LDX $03E1                    ; $94E1  AE E1 03
L_94E4:
        INX                          ; $94E4  E8
        CPX #$10                     ; $94E5  E0 10
        BNE L_94EE                   ; $94E7  D0 05
L_94E9:
        LDX #$00                     ; $94E9  A2 00
        INC $03E0                    ; $94EB  EE E0 03
L_94EE:
        STX $03E1                    ; $94EE  8E E1 03
        PLA                          ; $94F1  68
        SEC                          ; $94F2  38
        SBC #$01                     ; $94F3  E9 01
        BNE L_94CD                   ; $94F5  D0 D6
        LDA #$08                     ; $94F7  A9 08
        STA $03E9                    ; $94F9  8D E9 03
        RTS                          ; $94FC  60
        .byte   $FF, $FF, $FF, $00                               ; $94FD
