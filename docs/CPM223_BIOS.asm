; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- Z-80 BIOS  (true base $FA00; this chunk
; covers $FA00-$FF47, 1352 bytes)
;
; Annotated Z-80 source for the BIOS region. Reassembles byte-identically:
;
;     sjasmplus docs/CPM223_BIOS.asm
;
; RE-BASED 2026-06-11 (see docs/CPM_SoftCard_RealMap_Findings.md). This
; file previously carried ORG $FAB8: an artifact of the wrong SoftCard
; address model. The jump table is the FIRST thing in this image, and it
; lives at Z-80 $FA00 (= Apple $0A00 through the real map's -$F000
; window -- same bytes, no copy, no banking). All section-comment
; addresses below were written under the old base and read $B8 high
; until individually swept; the byte stream is unaffected (all absolute
; operands are hex literals).
;
; STRUCTURE -- corrected 2026-06-11
; ---------------------------------
; The old "alternating CODE / trap-marker pages, runtime-generated"
; story is dead. Page provenance (emu_softcard_v2 snapshot vs raw disk):
; the ENTIRE runtime BIOS $FA00-$FFFF arrives VERBATIM from CPMV233.DSK
; track 2, file-sectors 13..8 (one page each, descending). Cold boot
; then patches only ~185 bytes -- per-device dispatch operands, state
; slots, and scan workspace, concentrated in $FE00/$FF00. The
; FF FF 00 00 / F7 F7 00 00 fill patterns seen in older extractions
; belong to other disk regions, not to this runtime image.
;
; THE COLD-BOOT PASS (a fixup linker, not a factory)
; --------------------------------------------------
; Generator entry at true $FA82 (old docs: "$FB3A"). Walks the slot-info
; table at Z-80 $F3B8+E (= Apple $03B8+E, no copy) for E=7..1 and
; dispatches by device code; case 6 (Pascal 1.1) is new in 2.23.
; NOTE (Part 13): the device-6 path's significance is the 6502-side
; Pascal 1.1 client island ($0DD0-$0E35 Apple) doing the $CFFF/$C3xx
; expansion-ROM ownership handshake AFTER the CPU switch; the device-4
; path (2.20) did the same dance Z-80-side, where the $C700 switch
; access destroys it.
;
; SOURCE
; ------
; Loaded whole by the 6502 boot path; this chunk's bytes sit at track 2,
; file-sectors 13..8 of CPMV233.DSK (and the first two pages also ride
; track 0 for the boot stub's early load).
; ============================================================================

    DEVICE NOSLOT64K

; -- Code-overlap labels (target falls inside another instruction) --
BIOS_PRINT_C800      EQU $FB45

    ORG $FA00


; ============================================================================
; SECTION 1 -- BIOS Jump Table  ($FAB8-$FAEA)
;
; Standard CP/M 2.x 17-entry jump table (15 disk/console + LISTST + SECTRAN).
; Entries 0-14 are 3-byte JP instructions whose targets land in code page 0,
; code page 4, or runtime-populated dispatch slots in pages 1/3/5.
; Entries 15 (LISTST) and 16 (SECTRAN) are inline 1- to 3-byte routines.
;
; Targets:
;   BOOT  -> L_FE19 ($FED1) -- NOP slide leading to device-scan
;   WBOOT -> BOOT itself          -- on this build, warm boot = cold boot
;   CONST/CONIN/CONOUT/LIST/PUNCH/READER -> page-0 dispatch stubs
;   HOME/SELDSK/SETTRK            -> page-4 (BOOT vector landing area)
;   SETSEC/SETDMA                 -> page-1 (trap-marker dispatch slots)
;   READ/WRITE                    -> page-4 (overwritten by cold-boot generator)
; ============================================================================

BOOT:
        JP $FED1                  ; $FAB8  C3 D1 FE
WBOOT:
        JP L_FAB8                          ; $FABB  C3 B8 FA
CONST:
        JP $FB10                        ; $FABE  C3 10 FB
CONIN:
        JP $FB1A                        ; $FAC1  C3 1A FB
CONOUT:
        JP $FB4D                        ; $FAC4  C3 4D FB
LIST:
        JP $FB70                        ; $FAC7  C3 70 FB
PUNCH:
        JP $FB7F                        ; $FACA  C3 7F FB
READER:
        JP $FB91                        ; $FACD  C3 91 FB
HOME:
        JP $FE6C                        ; $FAD0  C3 6C FE
SELDSK:
        JP $FE8E                        ; $FAD3  C3 8E FE
SETTRK:
        JP $FE77                        ; $FAD6  C3 77 FE
SETSEC:
        JP $FBF4                        ; $FAD9  C3 F4 FB
SETDMA:
        JP $FBF9                        ; $FADC  C3 F9 FB
READ:
        JP $FEBD                        ; $FADF  C3 BD FE
WRITE:
        JP $FEC0                        ; $FAE2  C3 C0 FE
LISTST:
        XOR A                            ; $FAE5  AF
        RET                              ; $FAE6  C9
        DEFB    $00                                              ; $FAE7
SECTRAN:
        LD H,B                           ; $FAE8  60
        LD L,C                           ; $FAE9  69
        RET                              ; $FAEA  C9
        DEFS    8, $00    ; $FAEB  fill
        DEFB    $E4,$FE,$73,$FA,$AC,$FF,$64,$FF,$00,$00,$00,$00,$00,$00,$00,$00 ; $FAF3
        DEFB    $E4,$FE,$73,$FA,$B8,$FF,$76,$FF,$00,$00,$00,$00,$00 ; $FB03

; ============================================================================
; SECTION 2 -- Code-page 0 dispatch stubs  ($FAEB-$FB39)
;
; Each console/list/punch/reader BIOS entry above lands in this page.
; The static bytes here are mostly $00 / $E4 $FE $73 $FA / $FF $FF patterns
; that look like CALL PO,$73FE / JP M,nnnn instructions but are inert at boot
; time -- the cold-boot generator at SECTION 3 overwrites them with the
; appropriate device dispatch code before any jump-table entry can fire.
;
; The lookup table at $FB2B-$FB39 is the device-code -> per-character-device
; init parameter table (read by SECTION 3).
; ============================================================================

L_FA58:
        NOP                              ; $FB10  00
        NOP                              ; $FB11  00
        NOP                              ; $FB12  00
        CALL PO,$73FE                    ; $FB13  E4 FE 73
        JP M,$FFC4                      ; $FB16  FA C4 FF
        ADC A,B                          ; $FB19  88
L_FA62:
        RST $38                          ; $FB1A  FF
        NOP                              ; $FB1B  00
        NOP                              ; $FB1C  00
        NOP                              ; $FB1D  00
        NOP                              ; $FB1E  00
        NOP                              ; $FB1F  00
        NOP                              ; $FB20  00
        NOP                              ; $FB21  00
        NOP                              ; $FB22  00
        CALL PO,$73FE                    ; $FB23  E4 FE 73
        JP M,$FFD0                      ; $FB26  FA D0 FF
        SBC A,D                          ; $FB29  9A
        RST $38                          ; $FB2A  FF
        JR NZ,L_FA75                     ; $FB2B  20 00
L_FA75:
        INC BC                           ; $FB2D  03
        RLCA                             ; $FB2E  07
        NOP                              ; $FB2F  00
        ADC A,E                          ; $FB30  8B
        NOP                              ; $FB31  00
        CPL                              ; $FB32  2F
        NOP                              ; $FB33  00
        RET NZ                           ; $FB34  C0
        NOP                              ; $FB35  00
        INC C                            ; $FB36  0C
        NOP                              ; $FB37  00
        INC BC                           ; $FB38  03
        NOP                              ; $FB39  00
        LD DE,$0007                      ; $FB3A  11 07 00

; ============================================================================
; SECTION 3 -- Cold-boot generator (the Z-80 side of the Videx fix)
;
; Walks the slot-info table at $F3B8+E for E=7,6,...,1, dispatching by
; device code:
;   3 -> CALL L_FDC9     ($FE81)
;   4 -> CALL L_FCCB   ($FD83)  -- old Pascal firmware
;   6 -> CALL L_FCF8   ($FDB0)  -- NEW IN 2.23 (the Videx delta)
;
; The 11-byte 6502 slot-scanner branch in the boot loader writes '6' into
; this slot-info table for Pascal-1.1 cards (Videx Videoterm). Without that
; branch on the 6502 side, only codes 3 and 4 are ever generated, and a
; 2.20 system trying to call L_FCF8 would land on whatever bytes
; happen to live at $FDB0 (a JR NZ to a trap marker -> system hang).
;
; Loop body (per slot E):
;   * read device code from $F3B8+E
;   * if code==3, fill HL with $0315 and call $FE81
;   * if code==4, call $FD83 and then PRINT_STR (HL := $C800)
;   * if code==6, set HL := $0DD0 and call $FDB0 (Pascal 1.1 init)
; ============================================================================

L_FA85:
        LD HL,$F3B8                      ; $FB3D  21 B8 F3
        ADD HL,DE                        ; $FB40  19
        LD A,(HL)                        ; $FB41  7E
        SUB $03                          ; $FB42  D6 03
        JR NZ,L_FA95                     ; $FB44  20 07
        CALL $FE81               ; $FB46  CD 81 FE
        LD (HL),$03                      ; $FB49  36 03
        LD (HL),$15                      ; $FB4B  36 15
L_FA95:
        DEC A                            ; $FB4D  3D
        JR NZ,L_FAA3                     ; $FB4E  20 0B
        CALL $FD83             ; $FB50  CD 83 FD
        LD HL,$C800                      ; $FB53  21 00 C8
        CALL BIOS_PRINT_C800             ; $FB56  CD 45 FB
        JR L_FAAD                        ; $FB59  18 0A
L_FAA3:
        CP $02                           ; $FB5B  FE 02
        JR NZ,L_FAAD                     ; $FB5D  20 06
        LD HL,$0DD0                      ; $FB5F  21 D0 0D
        CALL $FDB0             ; $FB62  CD B0 FD
L_FAAD:
        DEC E                            ; $FB65  1D
        JR NZ,L_FA85                     ; $FB66  20 D5
        RET                              ; $FB68  C9
        DEFB    $21,$00,$E0,$7B,$B4,$67,$C9                      ; $FB69

; ============================================================================
; SECTION 4 -- Stage 2 cold boot  ($FB70-$FB96)
;
; Sets the Z-80 stack to $0080 (CP/M default), reads Apple text-mode flag,
; loads HL with $0E00, calls SECTION 3 ($FB45 = code-overlap entry into the
; generator), then CALL $FA82 (a routine in the BDOS area that performs
; remaining device init).
;
; The check at $FB7F-$FB85 reads BDOS_SENTINEL ($9C08): if it equals $9C
; we're cold-booting (no warm-boot state yet), so jump to SECTION 5; otherwise
; continue with a warm-boot path that points $0006 at $9C06 (BDOS entry) and
; jumps through $000B (the warm-boot vector planted at boot).
; ============================================================================

L_FAB8:
        LD SP,$0080                      ; $FB70  31 80 00
        LD A,($E051)                     ; $FB73  3A 51 E0
        LD HL,$0E00                      ; $FB76  21 00 0E
        CALL BIOS_PRINT_C800             ; $FB79  CD 45 FB
        CALL $FA82                       ; $FB7C  CD 82 FA
L_FAC7:
        LD A,($9C08)                     ; $FB7F  3A 08 9C
        CP $9C                           ; $FB82  FE 9C
        JR Z,L_FADF                      ; $FB84  28 11
        LD HL,$FF59                      ; $FB86  21 59 FF
        LD ($F3D0),HL                    ; $FB89  22 D0 F3
        LD HL,($F3DE)                    ; $FB8C  2A DE F3
        LD A,$77                         ; $FB8F  3E 77
L_FAD9:
        LD ($000B),A                     ; $FB91  32 0B 00
        JP $000B                         ; $FB94  C3 0B 00

; ============================================================================
; SECTION 5 -- Stage 3 cold boot  ($FB97-$FBB7)
;
; Initial cold-boot setup. Zeros several state bytes, then plants the
; CP/M conventional vectors at the bottom of memory:
;   $0000-$0002 := JP $FA03    (warm-boot vector via BIOS)
;   $0005-$0007 := JP $9C06    (BDOS entry)
;
; After this, falls into the trap-marker page where the cold-boot generator
; has installed runtime code that completes initialization.
; ============================================================================

L_FADF:
        XOR A                            ; $FB97  AF
        LD ($9307),A                     ; $FB98  32 07 93
        XOR A                            ; $FB9B  AF
        LD ($FEDD),A                     ; $FB9C  32 DD FE
        LD ($FED8),A                     ; $FB9F  32 D8 FE
        LD A,$C3                         ; $FBA2  3E C3
        LD ($0000),A                     ; $FBA4  32 00 00
        LD HL,$FA03                      ; $FBA7  21 03 FA
        LD ($0001),HL                    ; $FBAA  22 01 00
        LD ($0005),A                     ; $FBAD  32 05 00
        LD HL,$9C06                      ; $FBB0  21 06 9C
        LD ($0006),HL                    ; $FBB3  22 06 00
        DEFB    $01,$80,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FBB6
SUB_FB0C:
        DEFB    $FF,$FF,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00  ; $FBC4
L_FB18:
        DEFB    $F7,$F7,$00,$00,$F7,$F7,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FBD0
        DEFB    $FF,$FF                                          ; $FBE0
L_FB2A:
        DEFB    $00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FBE2
SUB_FB38:
        DEFB    $FF,$FF,$00,$00                                  ; $FBF0
L_FB3C:
        DEFB    $FF,$FF,$00,$00,$FF                              ; $FBF4
L_FB41:
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FBF9
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC09
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$F7 ; $FC19
        DEFB    $F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$FF ; $FC29
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC39
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC49
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC59
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC69
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC79
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF ; $FC89
        DEFB    $FF                                              ; $FC99
L_FBE2:
        DEFB    $00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00          ; $FC9A
SUB_FBEC:
        DEFB    $FF,$FF,$00,$00,$F7,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FCA4
        DEFB    $FF,$FF,$00,$00,$00,$CD,$F9,$FB,$3E,$01,$32,$4E,$97,$3A,$04,$00 ; $FCB4
        DEFB    $4F,$C3,$00,$93,$2A,$80,$F3,$E9,$3A,$00,$E0,$17,$9F,$C9,$CD,$5A ; $FCC4
        DEFB    $FB,$E6,$7F,$21,$AB,$F3,$06,$06,$4F,$23,$7E,$23,$B7,$FA,$31,$FB ; $FCD4
        DEFB    $B9,$7E,$C8,$10,$F4,$79,$C9,$11,$03,$00,$C3,$39,$FB,$3A,$00,$E0 ; $FCE4
        DEFB    $17,$30,$FA,$32,$10,$E0,$3F,$1F,$C9,$22,$D0,$F3,$32,$00,$00,$C9 ; $FCF4
        DEFB    $4F,$3A,$03,$00,$E6,$03,$FE,$02,$20,$4B,$2A,$92,$F3,$E9,$3A,$03 ; $FD04
        DEFB    $00,$E6,$03,$FE,$02,$2A,$84,$F3,$28,$06,$30,$07,$2A,$82,$F3,$E9 ; $FD14
        DEFB    $2A,$8A,$F3,$E9,$3A,$03,$00,$E6,$C0,$FE,$80,$38,$27,$28,$DB,$2A ; $FD24
        DEFB    $94,$F3,$E9,$3A,$03,$00,$E6,$30,$FE,$10,$38,$18,$2A,$8E,$F3,$28 ; $FD34
        DEFB    $E2,$2A,$90,$F3,$E9,$3A,$03,$00,$E6,$0C,$FE,$08,$38,$CE,$28,$D0 ; $FD44
        DEFB    $2A,$8C,$F3,$E9,$37,$9F,$21,$A2,$F3,$6E,$2C,$CA,$A4,$FC,$21,$CB ; $FD54
        DEFB    $FE,$77,$CB,$B9,$23,$7E,$B7,$CA,$56,$FC,$35,$3A,$96,$F3,$21,$D4 ; $FD64
        DEFB    $FE,$28,$0C,$B7,$F2,$C6,$FB,$2B,$E6,$7F,$5F,$79,$93,$77,$C9 ; $FD74

; ============================================================================
; L_FCCB -- per-slot Pascal 1.0 firmware init  ($FD83)
;
; Called by SECTION 3 when slot E's device code == 4. Walks the per-slot
; state from $F388 / $F3A1 etc., and calls the per-device helpers in page 1
; that the trap-marker bytes have been overwritten with.
; ============================================================================

L_FCCB:   ; (formerly annotated "INIT_PASCAL_1_0" -- name attached under the +$B8 org; re-attachment pending)
        OR A                             ; $FD83  B7
        JP M,$FBD0                      ; $FD84  FA D0 FB
        DEC HL                           ; $FD87  2B
        CALL $FBC4                    ; $FD88  CD C4 FB
        LD HL,($FED3)                    ; $FD8B  2A D3 FE
        LD A,($F3A1)                     ; $FD8E  3A A1 F3
        OR A                             ; $FD91  B7
        JP P,L_FBE2                      ; $FD92  F2 E2 FB
        AND $7F                          ; $FD95  E6 7F
        LD E,L                           ; $FD97  5D
        LD L,H                           ; $FD98  6C
        LD H,E                           ; $FD99  63
        LD E,A                           ; $FD9A  5F
        ADD A,H                          ; $FD9B  84
        LD C,A                           ; $FD9C  4F
        LD A,E                           ; $FD9D  7B
        ADD A,L                          ; $FD9E  85
        PUSH AF                          ; $FD9F  F5
        LD B,$07                         ; $FDA0  06 07
        CALL $FCA4                    ; $FDA2  CD A4 FC
        POP AF                           ; $FDA5  F1
        LD B,$0A                         ; $FDA6  06 0A
        LD C,A                           ; $FDA8  4F
        JP $FCA4                      ; $FDA9  C3 A4 FC
        DEFB    $79,$32,$D2,$FE                                  ; $FDAC

; ============================================================================
; L_FCF8 -- per-slot Pascal 1.1 firmware init  ($FDB0)  *** 2.23 NEW ***
;
; In 2.23 this is just RET. Its existence (versus 2.20's $FDB0 falling on a
; trap marker that happens to decode as a JR NZ branching into more trap
; markers) is what allows the cold-boot generator to dispatch device code 6
; to a known landing spot. The actual Pascal-1.1 init is performed by code
; that 2.23's BIOS sets up via runtime patching of higher addresses.
;
; This RET is the literal one-byte fix that makes Videx Videoterm work on
; CP/M 2.23: 2.20 had no entry here, so a slot reporting device code 6
; would crash the cold-boot generator.
; ============================================================================

L_FCF8:   ; (formerly annotated "INIT_PASCAL_1_1" -- name attached under the +$B8 org; re-attachment pending)
        RET                              ; $FDB0  C9
        DEFB    $ED,$43,$E1,$FE,$C9,$00                          ; $FDB1  "mCa~I"
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FDB7
        DEFB    $00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$10 ; $FDC7
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FDD7
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FDE7
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FDF7
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FE07
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$10 ; $FE17
        DEFB    $00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00 ; $FE27
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FE37
        DEFB    $00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$FF,$F7,$00 ; $FE47
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00 ; $FE57
        DEFB    $00,$FF,$FF,$00,$00                              ; $FE67
L_FDB4:
        DEFB    $FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00      ; $FE6C
L_FDBF:
        DEFB    $00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF          ; $FE77
L_FDC9:   ; (formerly annotated "INIT_KEYBOARD" -- name attached under the +$B8 org; re-attachment pending)
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF ; $FE81
L_FDD6:
        DEFB    $00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF ; $FE8E
        DEFB    $00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$F7,$F7,$00,$00,$F7,$F7 ; $FE9E
        DEFB    $00,$00,$F7,$F7,$00,$00,$F7,$F7,$00,$00,$00,$00,$00,$00,$00 ; $FEAE
L_FE05:
        NOP                              ; $FEBD  00
        NOP                              ; $FEBE  00
        NOP                              ; $FEBF  00
L_FE08:
        NOP                              ; $FEC0  00
        NOP                              ; $FEC1  00
        NOP                              ; $FEC2  00
        NOP                              ; $FEC3  00
        NOP                              ; $FEC4  00
        NOP                              ; $FEC5  00
        NOP                              ; $FEC6  00
        NOP                              ; $FEC7  00
        NOP                              ; $FEC8  00
        NOP                              ; $FEC9  00
        NOP                              ; $FECA  00
        NOP                              ; $FECB  00
        NOP                              ; $FECC  00
        NOP                              ; $FECD  00
        NOP                              ; $FECE  00
        NOP                              ; $FECF  00
        NOP                              ; $FED0  00
L_FE19:   ; (formerly annotated "BOOT_LANDING" -- name attached under the +$B8 org; re-attachment pending)
        NOP                              ; $FED1  00
        NOP                              ; $FED2  00
        NOP                              ; $FED3  00
        NOP                              ; $FED4  00
        NOP                              ; $FED5  00
        NOP                              ; $FED6  00
        NOP                              ; $FED7  00
        NOP                              ; $FED8  00
        NOP                              ; $FED9  00
        NOP                              ; $FEDA  00
        NOP                              ; $FEDB  00
        NOP                              ; $FEDC  00
        NOP                              ; $FEDD  00
        NOP                              ; $FEDE  00
        NOP                              ; $FEDF  00
        NOP                              ; $FEE0  00
        NOP                              ; $FEE1  00
        NOP                              ; $FEE2  00
        NOP                              ; $FEE3  00
        NOP                              ; $FEE4  00
        NOP                              ; $FEE5  00
        NOP                              ; $FEE6  00
        NOP                              ; $FEE7  00
        NOP                              ; $FEE8  00
        NOP                              ; $FEE9  00
        NOP                              ; $FEEA  00
        NOP                              ; $FEEB  00
        NOP                              ; $FEEC  00
        NOP                              ; $FEED  00
        NOP                              ; $FEEE  00
        NOP                              ; $FEEF  00
        NOP                              ; $FEF0  00
        NOP                              ; $FEF1  00
        NOP                              ; $FEF2  00
        NOP                              ; $FEF3  00
        NOP                              ; $FEF4  00
        NOP                              ; $FEF5  00
        NOP                              ; $FEF6  00
        NOP                              ; $FEF7  00
        NOP                              ; $FEF8  00
        NOP                              ; $FEF9  00
        NOP                              ; $FEFA  00
        NOP                              ; $FEFB  00
        NOP                              ; $FEFC  00
        NOP                              ; $FEFD  00
        NOP                              ; $FEFE  00
        NOP                              ; $FEFF  00
        NOP                              ; $FF00  00
        NOP                              ; $FF01  00
        NOP                              ; $FF02  00
        NOP                              ; $FF03  00
        NOP                              ; $FF04  00
        NOP                              ; $FF05  00
        NOP                              ; $FF06  00
        NOP                              ; $FF07  00
        NOP                              ; $FF08  00
        NOP                              ; $FF09  00
        NOP                              ; $FF0A  00
        NOP                              ; $FF0B  00
        NOP                              ; $FF0C  00
        NOP                              ; $FF0D  00
        LD B,A                           ; $FF0E  47
        LD HL,$FECD                      ; $FF0F  21 CD FE
        LD A,(HL)                        ; $FF12  7E
        LD E,A                           ; $FF13  5F
        OR A                             ; $FF14  B7
        JR NZ,L_FE71                     ; $FF15  20 12
        LD A,($F397)                     ; $FF17  3A 97 F3
        OR A                             ; $FF1A  B7
        JR Z,L_FE6B                      ; $FF1B  28 06
        CP C                             ; $FF1D  B9
        JR NZ,L_FE6B                     ; $FF1E  20 03
        LD (HL),$80                      ; $FF20  36 80
        RET                              ; $FF22  C9
L_FE6B:
        LD A,$1F                         ; $FF23  3E 1F
        CP C                             ; $FF25  B9
        JP C,$FCA4                    ; $FF26  DA A4 FC
L_FE71:
        LD HL,$F3A0                      ; $FF29  21 A0 F3
        LD B,$09                         ; $FF2C  06 09
L_FE76:
        LD A,(HL)                        ; $FF2E  7E
        OR A                             ; $FF2F  B7
        JR Z,L_FE7E                      ; $FF30  28 04
        XOR E                            ; $FF32  AB
        CP C                             ; $FF33  B9
        JR Z,L_FE83                      ; $FF34  28 05
L_FE7E:
        DEC HL                           ; $FF36  2B
        DJNZ L_FE76                      ; $FF37  10 F5
        JR L_FEA4                        ; $FF39  18 21
L_FE83:
        LD DE,$000B                      ; $FF3B  11 0B 00
        ADD HL,DE                        ; $FF3E  19
        LD A,(HL)                        ; $FF3F  7E
        OR A                             ; $FF40  B7
        LD C,A                           ; $FF41  4F
        JP P,$FC9A                      ; $FF42  F2 9A FC
        AND $7F                          ; $FF45  E6 7F
        LD C,A                           ; $FF47  4F
        PUSH BC                          ; $FF48  C5
        LD A,($F3A2)                     ; $FF49  3A A2 F3
        LD B,$07                         ; $FF4C  06 07
        CALL $FBF0                    ; $FF4E  CD F0 FB
        POP BC                           ; $FF51  C1
        LD A,B                           ; $FF52  78
        CP $07                           ; $FF53  FE 07
        JR NZ,L_FEA4                     ; $FF55  20 05
        LD A,$02                         ; $FF57  3E 02
        LD ($FECC),A                     ; $FF59  32 CC FE
L_FEA4:
        XOR A                            ; $FF5C  AF
        LD ($FECD),A                     ; $FF5D  32 CD FE
        LD A,($FECB)                     ; $FF60  3A CB FE
        OR A                             ; $FF63  B7
        LD HL,($F388)                    ; $FF64  2A 88 F3
        JR Z,L_FEB4                      ; $FF67  28 03
        LD HL,($F386)                    ; $FF69  2A 86 F3
L_FEB4:
        JP (HL)                          ; $FF6C  E9
        DEFB    $11,$03,$00,$C3,$BB,$FC,$2A,$CE,$FE,$3A,$D0,$FE,$77,$CD,$E2,$FC ; $FF6D
        DEFB    $2A,$28,$F0,$3A,$24,$F0,$5F,$16,$F0,$19,$22,$CE,$FE,$7E,$32,$D0 ; $FF7D
        DEFB    $FE,$FE,$E0,$38,$02,$EE,$20,$E6,$3F,$F6,$40,$77,$C9,$78,$B7,$28 ; $FF8D
        DEFB    $0B,$21,$45,$FB,$E5,$21,$66,$FD,$85,$6F,$6E,$E9,$79,$FE,$0D,$20 ; $FF9D
        DEFB    $05,$AF,$32,$24,$F0,$C9,$F6,$80,$FE,$E0,$38,$FF,$FF,$00,$00,$FF ; $FFAD
        DEFB    $FF,$00,$00,$FF,$FF,$00,$00                      ; $FFBD
L_FF0C:
        DEFB    $FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00  ; $FFC4
L_FF18:
        DEFB    $FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FFD0
        DEFB    $FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FFE0
        DEFB    $FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00,$FF,$FF,$00,$00 ; $FFF0

    SAVEBIN "build/CPM223_BIOS.bin", $FA00, $0548
