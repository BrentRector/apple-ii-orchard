; ============================================================================
; Microsoft SoftCard CP/M 2.23 (44K) -- CCP module (+ system-image assembler)
; ----------------------------------------------------------------------------
; The CP/M "system" the boot loader reads off the system tracks is TWO independent
; modules -- the CCP and the BDOS -- each its own source file. This is the CCP
; module. It also assembles the full $8000 LOAD_CPM staging image by INCLUDEing the
; BDOS module (CPM_BDOS.asm) at its staged position, so the two compile as ONE unit
; and reassemble BYTE-IDENTICAL to the on-disk system tracks. (Mirrors the
; CPMV220-44K CPM_CCP.asm + CPM_BDOS.asm split.)
;
; Staging layout (ORG $8000, 5888 bytes; SYS_INIT relocates it at boot):
;   $8000-$8CFF  CCP, staged in RELOCATABLE form -- SYS_INIT patches its internal
;                addresses as it lifts it to the $9300 run address, so these staged
;                bytes are NOT the $9300 run form (kept as DEFB here; a clean $9300
;                decode is the relocation-tooling follow-up, not yet done).
;   $8D00-$96FF  BDOS, INCLUDEd from CPM_BDOS.asm under DISP $9C00 (its labels are
;                $9C00-based, its bytes land at staging offset $0D00). SYS_INIT, the
;                in-place relocator, lives in the BDOS tail and runs at staging
;                ($9631) before the copy-up to $9C00.
;
; This file DEFINEs CPM_LINK around the INCLUDE so CPM_BDOS.asm emits body-only
; (its own DEVICE/ORG/SAVEBIN are IFNDEF CPM_LINK and run only when it builds
; standalone). The [AI]/[DOC] comment conventions are as in the sibling sources.
; ============================================================================

    IFNDEF CPM_LINK
    DEVICE NOSLOT64K
    ENDIF

; -- Staging-image routines the CCP calls. SYS_INIT is the in-place relocator: its
;    bytes sit in the BDOS-staging tail (INCLUDEd below, decoded there at the BDOS
;    run address), but it EXECUTES here at its staging address before the copy-up, so
;    the CCP references it by staging address. --
SYS_INIT             EQU $9631               ; system init / relocator entry (runs in-place at staging)
SYS_INIT_4           EQU $967B               ; SYS_INIT inner loop ($967B)

    ORG $8000

; [AI] ORG $8000 entry point of the loaded system image; its only instruction is a JP to the real
;       initialization routine SYS_INIT ($9631), with the bytes that follow being CCP/BDOS code and
;       data the disassembler emitted as DEFB. The image carries the CCP + BDOS plus the page-zero
;       template the system installs (warm-boot JMP at $0000, BDOS entry vector at $0005, default
;       FCB at $005C, default DMA / command-tail buffer at $0080). [DOC CPMREF 3-44] $0005 holds a
;       JMP to FBASE (the BDOS) and the word at $0006 doubles as the top-of-TPA / start-of-FDOS
;       pointer; OS calls pass the function number in C and the info address in DE through $0005.
SYSIMG_ENTRY:
        JP SYS_INIT                      ; $8000  C3 31 96
        DEFB    $1A,$B7,$C8,$FE,$20,$38,$D5,$C8,$FE,$3D,$C8,$FE,$5F,$C8,$FE,$2E ; $8003
        DEFB    $C8,$FE,$3A,$C8,$FE,$3B,$C8,$FE,$3C,$C8,$FE,$3E,$C8,$C9,$1A,$B7 ; $8013
        DEFB    $C8,$FE,$20,$C0,$13,$18,$F7,$85,$6F,$D0,$24,$C9,$3E,$00,$21,$86 ; $8023
        DEFB    $9B,$CD,$2A,$95,$E5,$E5,$AF,$32,$A9,$9B,$2A,$88,$93,$EB,$CD,$21 ; $8033
        DEFB    $95,$EB,$22,$8A,$93,$EB,$E1,$1A,$B7,$28,$0A,$DE,$40,$47,$13,$1A ; $8043
        DEFB    $FE,$3A,$28,$07,$1B,$3A,$A8,$9B,$77,$18,$06,$78,$32,$A9,$9B,$70 ; $8053
        DEFB    $13,$06,$08,$CD,$03,$95,$28,$15,$23,$FE,$2A,$20,$04,$36,$3F,$18 ; $8063
        DEFB    $02,$77,$13,$10,$EE,$CD,$03,$95,$28,$08,$13,$18,$F8,$23,$36,$20 ; $8073
        DEFB    $10,$FB,$06,$03,$FE,$2E,$20,$1B,$13,$CD,$03,$95,$28,$15,$23,$FE ; $8083
        DEFB    $2A,$20,$04,$36,$3F,$18,$02,$77,$13,$10,$EE,$CD,$03,$95,$28,$08 ; $8093
        DEFB    $13,$18,$F8,$23,$36,$20,$10,$FB,$06,$03,$23,$36,$00,$10,$FB,$EB ; $80A3
        DEFB    $22,$88,$93,$E1,$01,$0B,$00,$23,$7E,$FE,$3F,$20,$01,$04,$0D,$20 ; $80B3
        DEFB    $F6,$78,$B7,$C9,$44,$49,$52,$20,$45,$52,$41,$20,$54,$59,$50,$45 ; $80C3
        DEFB    $53,$41,$56,$45,$52,$45,$4E,$20,$55,$53,$45,$52,$BD,$16,$00,$01 ; $80D3
        DEFB    $4D,$40,$21,$C7,$95,$0E,$00,$79,$FE,$06,$D0,$11,$87,$9B,$06,$04 ; $80E3
        DEFB    $1A,$BE,$20,$0B,$13,$23,$10,$F8,$1A,$FE,$20,$20,$05,$68,$CE,$F8 ; $80F3
        DEFB    $04,$D0,$E5,$F0,$CA,$68,$A9,$40,$28,$4C,$3F,$BF,$F0,$2A,$A5,$2F ; $8103
        DEFB    $8D,$E3,$03,$AD,$E2,$03,$F0,$08,$C5,$2F,$F0,$04,$A9,$20,$D0,$E8 ; $8113
        DEFB    $AD,$E1,$03,$A8,$B9,$9E,$BF,$C5,$2D,$D0,$9F,$28,$90,$19,$20,$99 ; $8123
        DEFB    $BA,$08,$B0,$96,$28,$20,$D3,$BF,$18,$A9,$00,$24,$38,$8D,$EA,$03 ; $8133
        DEFB    $AE,$F8,$05,$BD,$88,$C0,$60,$20,$00,$BA,$90,$EC,$A9,$10,$D0,$EC ; $8143
        DEFB    $0A,$20,$5B,$BF,$4E,$78,$04,$60,$85,$2E,$20,$7E,$BF,$B9,$78,$04 ; $8153
        DEFB    $24,$35,$30,$03,$B9,$F8,$04,$8D,$78,$04,$A5,$2E,$24,$35,$30,$05 ; $8163
        DEFB    $99,$F8,$04,$10,$03,$99,$78,$04,$4C,$5F,$BB,$8A,$4A,$4A,$4A,$4A ; $8173
        DEFB    $A8,$60,$48,$AD,$E4,$03,$6A,$66,$35,$20,$7E,$BF,$68,$0A,$24,$35 ; $8183
        DEFB    $30,$05,$99,$F8,$04,$10,$03,$99,$78,$04,$60,$00,$02,$04,$06,$08 ; $8193
        DEFB    $0A,$0C,$0E,$01,$03,$05,$07,$09,$0B,$0D,$0F,$A2,$55,$A9,$00,$9D ; $81A3
        DEFB    $00,$0C,$CA,$10,$FA,$A8,$A2,$AC,$2C,$A2,$AA,$88,$B1,$3E,$4A,$3E ; $81B3
        DEFB    $56,$0B,$4A,$3E,$56,$0B,$99,$00,$09,$E8,$D0,$EF,$98,$D0,$EA,$60 ; $81C3
        DEFB    $A0,$00,$A2,$56,$CA,$30,$FB,$B9,$00,$09,$5E,$00,$0C,$2A,$5E,$00 ; $81D3
        DEFB    $0C,$2A,$91,$3E,$C8,$D0,$ED,$60,$00,$00,$00,$00,$00,$00,$00,$00 ; $81E3
        DEFS    13, $00    ; $81F3  fill
        DEFB    $79,$C9,$23,$10,$FD,$0C,$18,$E2,$AF,$32,$07,$93,$31,$64,$9B,$C5 ; $8200
        DEFB    $79,$1F,$1F,$1F,$1F,$E6,$0F,$5F,$CD,$F8,$93,$CD,$B2,$93,$32,$64 ; $8210
        DEFB    $9B,$C1,$79,$E6,$0F,$32,$A8,$9B,$CD,$B6,$93,$3A,$07,$93,$B7,$20 ; $8220
        DEFB    $16,$31,$64,$9B,$CD,$99,$93,$CD,$A8,$94,$C6,$41,$CD,$8C,$93,$3E ; $8230
        DEFB    $3E,$CD,$8C,$93,$CD,$1B,$94,$11,$80,$00,$CD,$B0,$94,$CD,$A8,$94 ; $8240
        DEFB    $32,$A8,$9B,$CD,$2F,$95,$C4,$DF,$94,$3A,$A9,$9B,$B7,$C2,$26,$99 ; $8250
        DEFB    $CD,$E5,$95,$21,$70,$96,$5F,$16,$00,$19,$19,$7E,$23,$66,$6F,$E9 ; $8260
        DEFB    $18,$97,$B1,$97,$EE,$97,$3A,$98,$98,$98,$0F,$99,$26,$99,$21,$F3 ; $8270
        DEFB    $76,$22,$00,$93,$21,$00,$93,$E9,$01,$8E,$96,$C3,$A2,$93,$52,$65 ; $8280
        DEFB    "ad error"    ; $8290  string
        DEFB    $00    ; $8298  terminator
        DEFB    $01,$9F,$96,$C3,$A2,$93,$4E,$6F,$20,$66,$69,$6C,$65,$00,$CD,$2F ; $8299
        DEFB    $95,$3A,$A9,$9B,$B7,$C2,$DF,$94,$21,$87,$9B,$01,$0B,$00,$7E,$FE ; $82A9
        DEFB    $20,$28,$24,$23,$D6,$30,$FE,$0A,$D2,$DF,$94,$57,$78,$E6,$E0,$C2 ; $82B9
        DEFB    $DF,$94,$78,$07,$07,$07,$80,$DA,$DF,$94,$80,$DA,$DF,$94,$82,$DA ; $82C9
        DEFB    $DF,$94,$47,$0D,$20,$D8,$C9,$7E,$FE,$20,$C2,$DF,$94,$23,$0D,$20 ; $82D9
        DEFB    $F6,$78,$C9,$21,$80                              ; $82E9  "vxI!"
        DEFB    $00,$81,$CD,$2A,$95,$7E,$C9,$AF,$32,$86,$9B,$3A,$A9,$9B,$B7,$C8 ; $82EE
        DEFB    $3D,$21,$AD,$81,$C0,$AD,$81,$C0,$8A,$4A,$4A,$4A,$4A,$A8,$48,$9D ; $82FE
        DEFB    $88,$C0,$A9,$00,$99,$78,$04,$99,$F8,$04,$20,$2F,$FB,$20,$93,$FE ; $830E
        DEFB    $20,$89,$FE,$68,$A2,$FF,$9A,$C9,$06,$F0,$10,$A0,$00,$B9,$92,$11 ; $831E
        DEFB    $F0,$06,$20,$ED,$FD,$C8,$D0,$F5,$4C,$65,$FF,$A0,$0E,$B9,$B0,$11 ; $832E
        DEFB    $99,$FF,$0F,$88,$D0,$F7,$B9,$00,$12,$99,$00,$02,$88,$D0,$F7,$A0 ; $833E
        DEFB    $F1,$B9,$FF,$12,$99,$FF,$02,$88,$D0,$F7,$8C,$B8,$03,$84,$3C,$88 ; $834E
        DEFB    $84,$3E,$A0,$C7,$84,$3D,$8C,$69,$10,$8D,$00,$C0,$A5,$3E,$F0,$18 ; $835E
        DEFB    $20,$4E,$11,$85,$40,$86,$41,$20,$4E,$11,$E0,$00,$F0,$1E,$C5,$40 ; $836E
        DEFB    $D0,$1A,$E4,$41,$F0,$1A,$D0,$14,$E6,$3E,$8C,$C8,$03,$A9,$00,$8D ; $837E
        DEFB    $C7,$03,$8D,$DE,$03,$98,$18,$69,$20,$8D,$DF,$03,$A2,$00,$F0,$2D ; $838E
        DEFB    $A2,$04,$A0,$05,$B1,$3C,$DD,$BE,$11,$D0,$09,$A0,$07,$B1,$3C,$DD ; $839E
        DEFB    $C2,$11,$F0,$03,$CA,$D0,$EB,$E8,$E0,$02,$D0,$03,$EE,$B8,$03,$E0 ; $83AE
        DEFB    $04,$D0,$0A,$A0,$0B,$B1,$3C,$C9,$01,$D0,$02,$A2,$06,$A4,$3D,$8A ; $83BE
        DEFB    $99,$F8,$02,$88,$C0,$C0,$D0,$8C,$0E,$B8,$03,$A5,$3E,$C9,$01,$F0 ; $83CE
        DEFB    $10,$A0,$00,$B9,$73,$11,$F0,$06,$20,$ED,$FD,$C8,$D0,$F5,$4C,$65 ; $83DE
        DEFB    $FF,$A0,$10,$B9,$EF,$13,$99,$EF,$03,$88,$D0,$F7,$A9,$C3,$8D,$00 ; $83EE
        DEFB    $10,$A9,$A8,$9B,$BE,$C8,$C3,$B6,$93,$3A,$A9,$9B,$B7,$C8,$3D,$21 ; $83FE
        DEFB    $A8,$9B,$BE,$C8,$3A,$A8,$9B,$C3,$B6,$93,$CD,$2F,$95,$CD,$F5,$96 ; $840E
        DEFB    $21,$87,$9B,$7E,$FE,$20,$20,$07,$06,$0B,$36,$3F,$23,$10,$FB,$1E ; $841E
        DEFB    $00,$D5,$CD,$D1,$93,$CC,$99,$96,$28,$75,$3A,$A7,$9B,$0F,$0F,$0F ; $842E
        DEFB    $E6,$60,$4F,$3E,$0A,$CD,$EC,$96,$17,$38,$5A,$D1,$7B,$1C,$D5,$E6 ; $843E
        DEFB    $03,$F5,$20,$14,$CD,$99,$93,$C5,$CD,$A8,$94,$C1,$C6,$41,$CD,$93 ; $844E
        DEFB    $93,$3E,$3A,$CD,$93,$93,$18,$08,$CD,$91,$93,$3E,$3A,$CD,$93,$93 ; $845E
        DEFB    $CD,$91,$93,$06,$01,$78,$CD,$EC,$96,$E6,$7F,$FE,$20,$20,$13,$F1 ; $846E
        DEFB    $F5,$FE,$03,$20,$0B,$3E,$09,$CD,$EC,$96,$E6,$7F,$FE,$20,$28,$14 ; $847E
        DEFB    $3E,$20,$CD,$93,$93,$04,$78,$FE,$0C,$30,$09,$FE,$09,$20,$D6,$CD ; $848E
        DEFB    $91,$93,$18,$D1,$F1,$CD,$9A,$94,$20,$05,$CD,$D8,$93,$18,$89,$D1 ; $849E
        DEFB    $C3,$38,$9A,$CD,$2F,$95,$FE,$0B,$20,$1B,$01,$E3,$97,$CD,$A2,$93 ; $84AE
        DEFB    $CD,$1B,$94,$21,$07,$93,$35,$C2                  ; $84BE
        DEFW    SYS_INIT                 ; $84C6
        DEFB    $23,$7E,$FE,$59,$C2                              ; $84C8
        DEFW    SYS_INIT                 ; $84CD
        DEFB    $23,$22,$88,$93,$CD,$F5,$96,$11,$86,$9B,$CD,$DC,$93,$3C,$CC,$99 ; $84CF
        DEFB    $96,$C3,$38,$9A,$41,$6C,$6C,$20,$28,$79,$2F,$6E,$29,$3F,$00,$CD ; $84DF
        DEFB    $2F,$95,$C2,$DF,$94,$CD,$F5,$96,$CD,$C6,$93,$28,$38,$CD,$99,$93 ; $84EF
        DEFB    $21,$AA,$9B,$36,$FF,$21,$AA,$9B,$7E,$FE,$80,$38,$09,$E5,$CD,$E0 ; $84FF
        DEFB    $93,$E1,$20,$1A,$AF,$77,$34,$21,$80,$00,$CD,$2A,$95,$7E,$FE,$1A ; $850F
        DEFB    $CA,$38,$9A,$CD,$8C,$93,$CD,$9A,$94,$C2,$38,$9A,$18,$D7,$3D,$CA ; $851F
        DEFB    $38,$9A,$CD,$88,$96,$CD,$07,$97,$C3,$DF,$94,$CD,$A7,$96,$F5,$CD ; $852F
        DEFB    $2F,$95,$C2,$DF,$94,$CD,$F5,$96,$11,$86,$9B,$D5,$CD,$DC,$93,$D1 ; $853F
        DEFB    $CD,$EE,$93,$28,$2F,$AF,$32,$A6,$9B,$F1,$6F,$26,$00,$29,$11,$00 ; $854F
        DEFB    $01,$7C,$B5,$28,$16,$2B,$E5,$21,$80,$00,$19,$E5,$CD,$B0,$94,$11 ; $855F
        DEFB    $86,$9B,$CD,$EA,$93,$D1,$E1,$20,$0B,$18,$E6,$11,$86,$9B,$CD,$BC ; $856F
        DEFB    $93,$3C,$20,$06,$01,$8F,$98,$CD,$A2,$93,$CD,$AD,$94,$C3,$38,$9A ; $857F
        DEFB    "No space"    ; $858F  string
        DEFB    $00    ; $8597  terminator
        DEFB    $CD,$2F,$95,$C2,$DF,$94,$3A,$A9,$9B,$F5,$CD,$F5,$96,$CD,$D1,$93 ; $8598
        DEFB    $20,$50,$21,$86,$9B,$11,$96,$9B,$01,$10,$00,$ED,$B0,$2A,$88,$93 ; $85A8
        DEFB    $EB,$CD,$21,$95,$FE,$3D,$28,$04,$FE,$5F,$20,$30,$EB,$23,$22,$88 ; $85B8
        DEFB    $93,$CD,$2F,$95,$20,$26,$F1,$47,$21,$A9,$9B,$7E,$B7,$28,$04,$B8 ; $85C8
        DEFB    $70,$20,$19,$70,$AF,$32,$86,$9B,$CD,$D1,$93,$28,$09,$11,$86,$9B ; $85D8
        DEFB    $CD,$F2,$93,$C3,$38,$9A,$CD,$99,$96,$C3,$38,$9A,$CD,$07,$97,$C3 ; $85E8
        DEFB    $DF,$94,$01,$03,$99,$CD,$A2,$93,$0F,$A0,$79,$95,$78,$9C,$DA,$0F ; $85F8
        DEFB    $A0,$EB,$E1,$23,$C3,$FA,$9F,$E1,$C5,$D5,$E5,$EB,$2A,$CE,$A9,$19 ; $8608
        DEFB    $44,$4D,$CD,$1E,$FA,$D1,$2A,$B5,$A9,$73,$23,$72,$D1,$2A,$B7,$A9 ; $8618
        DEFB    $73,$23,$72,$C1,$79,$93,$4F,$78,$9A,$47,$2A,$D0,$A9,$EB,$CD,$30 ; $8628
        DEFB    $FA,$4D,$44,$C3,$21,$FA,$21,$C3,$A9,$4E,$3A,$E3,$A9,$B7,$1F,$0D ; $8638
        DEFB    $C2,$45,$A0,$47,$3E,$08,$96,$4F,$3A,$E2,$A9,$0D,$CA,$5C,$A0,$B7 ; $8648
        DEFB    $17,$C3,$53,$A0,$80,$C9,$2A,$43,$9F,$11,$10,$00,$19,$09,$3A,$DD ; $8658
        DEFB    $A9,$B7,$CA,$71,$A0,$6E,$26,$00                  ; $8668  ")7Jq n&"
        DEFB    $C9,$09,$5E,$23,$56,$EB,$C9,$CD,$3E,$A0,$4F,$06,$00,$CD,$5E,$A0 ; $8670
        DEFB    $22,$E5,$A9,$C9,$2A,$E5,$A9,$7D,$B4,$C9,$3A,$C3,$A9,$2A,$E5,$A9 ; $8680
        DEFB    $29,$3D,$C2,$90,$A0,$22,$E7,$A9,$3A,$C4,$A9,$4F,$3A,$E3,$A9,$A1 ; $8690
        DEFB    $B5,$6F,$22,$E5,$A9,$C9,$2A,$43,$9F,$11,$0C,$00,$19,$C9,$2A,$43 ; $86A0
        DEFB    $9F,$11,$0F,$00,$19,$EB,$21,$11,$00,$19,$C9,$CD,$AE,$A0,$7E,$32 ; $86B0
        DEFB    $E3,$A9,$EB,$7E,$32,$E1,$A9,$CD,$A6,$A0,$3A,$C5,$A9,$A6,$32,$E2 ; $86C0
        DEFB    $A9,$C9,$CD,$AE,$A0,$3A,$D5,$A9,$FE,$02,$C2,$DE,$A0,$AF,$4F,$3A ; $86D0
        DEFB    $E3,$A9,$81,$77,$EB,$3A,$E1,$A9,$77,$C9,$0C,$0D,$C8,$7C,$B7,$1F ; $86E0
        DEFB    $67,$7D,$1F,$6F,$C3,$EB,$A0,$0E,$80,$2A,$B9,$A9,$AF,$86,$23,$0D ; $86F0
        DEFB    $C3,$38,$9A,$46,$69,$6C,$65,$20,$65,$78,$69,$73,$74,$73,$00,$CD ; $8700
        DEFB    $A7,$96,$FE,$10,$D2,$DF,$94,$5F,$3A,$87,$9B,$FE,$20,$CA,$DF,$94 ; $8710
        DEFB    $CD,$F8,$93,$C3,$3B,$9A,$CD,$CD,$94,$3A,$87,$9B,$FE,$20,$20,$16 ; $8720
        DEFB    $3A,$A9,$9B,$B7,$CA,$3B,$9A,$3D,$F5,$CD,$B6,$93,$F1,$32,$A8,$9B ; $8730
        DEFB    $CD,$0B,$94,$C3,$3B,$9A,$CD,$F6,$93,$32,$43,$9B,$11,$8F,$9B,$1A ; $8740
        DEFB    $FE,$20,$C2,$DF,$94,$D5,$CD,$F5,$96,$D1,$21,$35,$9A,$01,$03,$00 ; $8750
        DEFB    $ED,$B0,$CD,$C6,$93,$20,$0D,$CD,$F6,$93,$B7,$CA,$1B,$9A,$AF,$CD ; $8760
        DEFB    $50,$9A,$18,$EE,$3A,$86,$9B,$B7,$28,$04,$3D,$CD,$B6,$93,$0E,$1F ; $8770
        DEFB    $CD,$05,$00,$23,$23,$7E,$FE,$03,$20,$09,$23,$23,$23,$7E,$FE,$8B ; $8780
        DEFB    $CA,$54,$9A,$21,$00,$01,$E5,$EB,$CD,$B0,$94,$11,$86,$9B,$CD,$E3 ; $8790
        DEFB    $93,$20,$11,$E1,$11,$80,$00,$19,$11,$00,$93,$B7,$E5,$ED,$52,$E1 ; $87A0
        DEFB    $30,$72,$18,$E2,$E1,$3D,$20,$6C,$CD,$4D,$9A,$CD,$07,$97,$CD,$2F ; $87B0
        DEFB    $95,$21,$A9,$9B,$E5,$7E,$32,$86,$9B,$3E,$10,$CD,$31,$95,$E1,$7E ; $87C0
        DEFB    $32,$96,$9B,$AF,$32,$A6,$9B,$11,$5C,$00,$21,$86,$9B,$01,$21,$00 ; $87D0
        DEFB    $ED,$B0,$21,$08,$93,$7E,$B7,$28,$07,$FE,$20,$28,$03,$23,$18,$F5 ; $87E0
        DEFB    $06,$00,$11,$81,$00,$7E,$12,$B7,$28,$05,$04,$23,$13,$18,$F6,$78 ; $87F0
        DEFB    $C2,$FD,$A0,$C9,$0C,$0D,$C8,$29,$C3,$05,$A1,$C5,$3A,$42,$9F,$4F ; $8800
        DEFB    $21,$01,$00,$CD,$04,$A1,$C1,$79,$B5,$6F,$78,$B4,$67,$C9,$2A,$AD ; $8810
        DEFB    $A9,$3A,$42,$9F,$4F,$CD,$EA,$A0,$7D,$E6,$01,$C9,$21,$AD,$A9,$4E ; $8820
        DEFB    $23,$46,$CD,$0B,$A1,$22,$AD,$A9,$2A,$C8,$A9,$23,$EB,$2A,$B3,$A9 ; $8830
        DEFB    $73,$23,$72,$C9,$CD,$5E,$A1,$11,$09,$00,$19,$7E,$17,$D0,$21,$0F ; $8840
        DEFB    $9C,$C3,$4A,$9F,$CD,$1E,$A1,$C8,$21,$0D,$9C,$C3,$4A,$9F,$2A,$B9 ; $8850
        DEFB    $A9,$3A,$E9,$A9,$85,$6F,$D0,$24,$C9,$2A,$43,$9F,$11,$0E,$00,$19 ; $8860
        DEFB    $7E,$C9,$CD,$69,$A1,$36,$00                      ; $8870  "~IMi!6"
        DEFB    $C9,$CD,$69,$A1,$F6,$80                          ; $8877  "IMi!v"
        DEFB    $77,$C9,$2A,$EA,$A9,$EB,$2A,$B3,$A9              ; $887D
        DEFW    SYS_INIT_4               ; $8886
        DEFB    $23,$7A,$9E,$C9,$CD,$7F,$A1,$D8,$13,$72,$2B,$73,$C9,$7B,$95,$6F ; $8888
        DEFB    $7A,$9C,$67,$C9,$0E,$FF,$2A,$EC,$A9,$EB,$2A,$CC,$A9,$CD,$95,$A1 ; $8898
        DEFB    $D0,$C5,$CD,$F7,$A0,$2A,$BD,$A9,$EB,$2A,$EC,$A9,$19,$C1,$0C,$CA ; $88A8
        DEFB    $C4,$A1,$BE,$C8,$CD,$7F,$A1,$D0,$CD,$2C,$A1,$C9,$77,$C9,$CD,$9C ; $88B8
        DEFB    $A1,$CD,$E0,$A1,$0E,$01,$CD,$B8,$9F,$C3,$DA,$A1,$CD,$E0,$A1,$CD ; $88C8
        DEFB    $B2,$9F,$21,$B1,$A9,$C3,$E3,$A1,$21,$B9,$A9,$4E,$23,$46,$C3,$24 ; $88D8
        DEFB    $FA,$2A,$B9,$A9,$EB,$2A,$B1,$A9,$0E,$80,$C3,$4F,$9F,$21,$EA,$A9 ; $88E8
        DEFB    $7E,$23,$BE,$C0,$3C,$C9,$21,$FF,$32,$80,$00,$CD,$99,$93,$CD,$AD ; $88F8
        DEFB    $94,$CD,$FC,$93,$CD,$00,$01,$31,$64,$9B,$CD,$0B,$94,$CD,$B6,$93 ; $8908
        DEFB    $C3                                              ; $8918
        DEFW    SYS_INIT                 ; $8919
        DEFB    $CD,$4D,$9A,$CD,$07,$97,$C3,$DF,$94,$01,$2C,$9A,$CD,$A2,$93,$18 ; $891B
        DEFB    $0C,$42,$61,$64,$20,$6C,$6F,$61,$64,$00,$43,$4F,$4D,$CD,$07,$97 ; $892B
        DEFB    $CD,$2F,$95,$3A,$87,$9B,$D6,$20,$21,$A9,$9B,$B6,$C2,$DF,$94,$C3 ; $893B
        DEFW    SYS_INIT                 ; $894B
        DEFB    $3A,$43,$9B,$5F,$C3,$F8,$93,$2A,$DE,$F3,$22,$26,$9B,$AF,$32,$92 ; $894D
        DEFB    $9B,$3E,$11,$32,$41,$9B,$11,$FF,$92,$AF,$32,$A6,$9B,$21,$96,$9B ; $895D
        DEFB    $7E,$B7,$28,$06,$CD,$8D,$9A,$23,$18,$F6,$3E,$A6,$BD,$C2,$82,$9A ; $896D
        DEFB    $CD,$C8,$9A,$20,$E4,$AF,$12,$CD,$D4,$9A,$CD,$06,$9B,$C3,$B8,$99 ; $897D
        DEFB    $E5,$F5,$CB,$3F,$CB,$3F,$C6,$03,$32,$42,$9B,$F1,$E6,$03,$87,$87 ; $898D
        DEFB    $21,$31,$9B,$85,$6F,$30,$01,$24,$06,$04,$3A,$42,$9B,$12,$1B,$7E ; $899D
        DEFB    $23,$12,$1B,$3A,$41,$9B,$FE,$A1,$CA,$24,$9A,$FE,$C0,$20,$02,$3E ; $89AD
        DEFB    $D0,$12,$3C,$1B,$32,$41,$9B,$10,$E1,$E1,$C9,$E5,$D5,$21,$92,$9B ; $89BD
        DEFB    $34,$CD,$C6,$93,$D1,$E1,$C9,$21,$FF,$92,$54,$5D,$1B,$1B,$1B,$1A ; $89CD
        DEFB    $B7,$28,$1E,$BE,$38,$0A,$20,$F4,$1B,$1A,$13,$2B,$BE,$23,$30,$EC ; $89DD
        DEFB    $E5,$D5,$06,$03,$1A,$4E,$77,$79,$12,$2B,$1B,$10,$F7,$D1,$E1,$18 ; $89ED
        DEFB    $DB,$2B,$2B,$FF,$22,$EA,$A9,$C9,$2A,$C8,$A9,$EB,$2A,$EA,$A9,$23 ; $89FD
        DEFB    $22,$EA,$A9,$CD,$95,$A1,$D2,$19,$A2,$C3,$FE,$A1,$3A,$EA,$A9,$E6 ; $8A0D
        DEFB    $03,$06,$05,$87,$05,$C2,$20,$A2,$32,$E9,$A9,$B7,$C0,$C5,$CD,$C3 ; $8A1D
        DEFB    $9F,$CD,$D4,$A1,$C1,$C3,$9E,$A1,$79,$E6,$07,$3C,$5F,$57,$79,$0F ; $8A2D
        DEFB    $0F,$0F,$E6,$1F,$4F,$78,$87,$87,$87,$87,$87,$B1,$4F,$78,$0F,$0F ; $8A3D
        DEFB    $0F,$E6,$1F,$47,$2A,$BF,$A9,$09,$7E,$07,$1D,$C2,$56,$A2,$C9,$D5 ; $8A4D
        DEFB    $CD,$35,$A2,$E6,$FE,$C1,$B1,$0F,$15,$C2,$64,$A2,$77,$C9,$CD,$5E ; $8A5D
        DEFB    $A1,$11,$10,$00,$19,$C5,$0E,$11,$D1,$0D,$C8,$D5,$3A,$DD,$A9,$B7 ; $8A6D
        DEFB    $CA,$88,$A2,$C5,$E5,$4E,$06,$00,$C3,$8E,$A2,$0D,$C5,$4E,$23,$46 ; $8A7D
        DEFB    $E5,$79,$B0,$CA,$9D,$A2,$2A,$C6,$A9,$7D,$91,$7C,$98,$D4,$5C,$A2 ; $8A8D
        DEFB    $E1,$23,$C1,$C3,$75,$A2,$2A,$C6,$A9,$0E,$03,$CD,$EA,$A0,$23,$44 ; $8A9D
        DEFB    $4D,$2A,$BF,$A9,$36,$00                          ; $8AAD  "M*?)6"
        DEFB    $23,$0B,$78,$B1,$C2,$B1,$A2,$2A,$CA,$A9,$EB,$2A,$BF,$A9,$73,$23 ; $8AB3
        DEFB    $72,$CD,$A1,$9F,$2A,$B3,$A9,$36,$03,$23,$36,$00,$CD,$FE,$A1,$0E ; $8AC3
        DEFB    $FF,$CD,$05,$A2,$CD,$F5,$A1,$C8,$CD,$5E,$A1,$3E,$E5,$BE,$CA,$D2 ; $8AD3
        DEFB    $A2,$3A,$41,$9F,$BE,$C2,$F6,$A2,$23,$7E,$D6,$24,$C2,$F6,$A2,$3D ; $8AE3
        DEFB    $32,$45,$9F,$0E,$01,$CD,$6B,$A2,$CD,$8C,$A1,$C3,$D2,$2B,$7E,$B7 ; $8AF3
        DEFB    $20,$D2,$C9,$11,$FF,$92,$1A,$B7,$C8,$32,$E0,$F3,$1B,$1A,$32,$E1 ; $8B03
        DEFB    $F3,$1B,$1A,$32,$E9,$F3,$1B,$3E,$01,$32,$EB,$F3,$21,$03,$0E,$22 ; $8B13
        DEFB    $D0,$F3,$32,$00,$00,$3A,$EA,$F3,$B7,$28,$DB,$C3,$93,$99,$00,$09 ; $8B23
        DEFB    $03,$0C,$06,$0F,$01,$0A,$04,$0D,$07,$08,$02,$0B,$05,$0E,$00,$00 ; $8B33
        DEFS    35, $00    ; $8B43  fill
        DEFB    "$$$     SUB"    ; $8B66  string
        DEFB    $00    ; $8B71  terminator
        DEFS    142, $00    ; $8B72  fill
        DEFB    $A2,$3A,$D4,$A9,$C3,$01,$9F,$C5,$F5,$3A,$C5,$A9,$2F,$47,$79,$A0 ; $8C00
        DEFB    $4F,$F1,$A0,$91,$E6,$1F,$C1,$C9,$3E,$FF,$32,$D4,$A9,$21,$D8,$A9 ; $8C10
        DEFB    $71,$2A,$43,$9F,$22,$D9,$A9,$CD,$FE,$A1,$CD,$A1,$9F,$0E,$00,$CD ; $8C20
        DEFB    $05,$A2,$CD,$F5,$A1,$CA,$94,$A3,$2A,$D9,$A9,$EB,$1A,$FE,$E5,$CA ; $8C30
        DEFB    $4A,$A3,$D5,$CD,$7F,$A1,$D1,$D2,$94,$A3,$CD,$5E,$A1,$3A,$D8,$A9 ; $8C40
        DEFB    $4F,$06,$00,$79,$B7,$CA,$83,$A3,$1A,$FE,$3F,$CA,$7C,$A3,$78,$FE ; $8C50
        DEFB    $0D,$CA,$7C,$A3,$FE,$0C,$1A,$CA,$73,$A3,$96,$E6,$7F,$C2,$2D,$A3 ; $8C60
        DEFB    $C3,$7C,$A3,$C5,$4E,$CD,$07,$A3,$C1,$C2,$2D,$A3,$13,$23,$04,$0D ; $8C70
        DEFB    $C3,$53,$A3,$3A,$EA,$A9,$E6,$03,$32,$45,$9F,$21,$D4,$A9,$7E,$17 ; $8C80
        DEFB    $D0,$AF,$77,$C9,$CD,$FE,$A1,$3E,$FF,$C3,$01,$9F,$CD,$54,$A1,$0E ; $8C90
        DEFB    $0C,$CD,$18,$A3,$CD,$F5,$A1,$C8,$CD,$44,$A1,$CD,$5E,$A1,$36,$E5 ; $8CA0
        DEFB    $0E,$00,$CD,$6B,$A2,$CD,$C6,$A1,$CD,$2D,$A3,$C3,$A4,$A3,$50,$59 ; $8CB0
        DEFB    $79,$B0,$CA,$D1,$A3,$0B,$D5,$C5,$CD,$35,$A2,$1F,$D2,$EC,$A3,$C1 ; $8CC0
        DEFB    $D1,$2A,$C6,$A9,$7B,$95,$7A,$9C,$D2,$F4,$A3,$13,$C5,$D5,$42,$4B ; $8CD0
        DEFB    $CD,$35,$A2,$1F,$D2,$EC,$A3,$D1,$C1,$C3,$C0,$A3,$17,$3C,$CD,$64 ; $8CE0
        DEFB    $A2,$E1,$D1,$C9,$79,$B0,$C2,$C0,$A3,$21,$00      ; $8CF0  ""aQIy0B@#!"
        DEFB    $00,$C9,$0E,$00,$1E                              ; $8CFB  CCP tail (last 5 staged-CCP bytes; $8D00+ is BDOS)

; ---------------------------------------------------------------------------
; BDOS module ($8D00 staged -> $9C00 run). DISP makes its labels $9C00-based while
; its bytes are placed here at staging offset $0D00; DEFINE CPM_LINK keeps its
; standalone DEVICE/ORG/SAVEBIN out of this combined build.
; ---------------------------------------------------------------------------
    DISP $9C00
    DEFINE CPM_LINK
    INCLUDE "CPM_BDOS.asm"
    UNDEFINE CPM_LINK
    ENT

    IFNDEF CPM_LINK
    SAVEBIN "{out_bin}", $8000, $1700
    ENDIF
