; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- 6502 Boot Loader (integrated source)
; Annotated disassembly of the loader as it exists in Apple ][ RAM
; after the boot stub completes.
;
; The loader occupies $0800-$13FF in Apple ][ RAM. Loaded by the Disk II
; P6 PROM (sector 0 -> $0800) and the boot stub itself (10 more sectors
; of track 0 -> $0A00-$1300, in CP/M sector skew order).
;
; THIS FILE COVERS
;   $0800-$08FF  Boot stub (sector 0; 60 bytes of code, BYTE-IDENTICAL
;                to 2.23; rest is sector skew table and old/new copyright
;                strings)
;   $1000-$11FF  Stage-2 entry, install loops, slot scanner, dispatch,
;                boot-finalization. NOTE: 74% of stage-2 bytes differ
;                from 2.23. Same overall structure but different
;                addresses and code shape.
;
; KEY DIFFERENCES FROM 2.23
;   - Z-80 BIOS at $DACC (vs 2.23's $FAB8); reset vector planted as
;     "JP $DA00" not "JP $FA00"
;   - BDOS final position $CC06 (vs 2.23's $9C06)
;   - LOAD_CPM at Apple $0E10 (vs $0BEB / $BBEB in 2.23)
;   - Main load reads 28 sectors (LDA #$1C) vs 2.23's 29 (LDA #$1D)
;   - 11-byte Pascal 1.1 detection branch ABSENT (the Videx-fix delta;
;     see CPM_Videx_Difference.md and Part 1 of the article series)
;   - Install copy loops at $1041, $104C, $10E9 (vs $1044, $104F, $10F1)
;   - Warm-boot routine bytes at $13C0+ have STA $C400 + JSR $1010
;     instead of 2.23's STA $FFFF + JSR $0E36 -- different CPU-switch
;     mechanism (slot-4 I/O vs Z-80-byte fetch)
;   - No copyright string at $0860 (zero-filled in 2.20)
;
; COMPANION FILES
;   CPM220_InstallFragments.asm  ORG $0200, runtime view of the bytes
;                                 sourced from $1200-$13FF (different
;                                 from 2.23's install fragments).
;   CPM220_RWTS.asm              ORG $0A00, disk-routine block.
;
; The companion narrative is the cpm-videx article series and
; docs/CPM_Videx_Difference.md.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols (same set as 2.23 since the underlying Apple platform is the same)
; ----------------------------------------------------------------------------
zp_ptr_lo       = $3C        ; 16-bit pointer / slot ROM base
zp_ptr_hi       = $3D
zp_jmp_lo       = $3E        ; indirect-JMP target
zp_jmp_hi       = $3F
zp_count        = $00
zp_p6_count     = $27

dev_count_d2    = $03B8
dev_table       = $03B9
warm_boot       = $03C0

TEXT            = $FB2F
SETVID          = $FE93
SETKBD          = $FE89
COUT            = $FDED
IORTS           = $FF58
SAVE            = $FF4A
RESTORE         = $FF3F
MONITOR         = $FF65

KBD             = $C000
LC_RD_RAM       = $C081
LC_WR_RAM       = $C083
DISK_MOTOR_OFF  = $C088


; ============================================================================
; SECTION 1 -- Boot stub (sector 0, $0800-$08FF)
;
; 60 bytes of code at $0801-$083C. BYTE-IDENTICAL to 2.23's boot stub.
; Loads 10 more sectors of track 0 in CP/M skew order, then JMP $1000.
; ============================================================================

            .ORG $0800

$0800:      .BYTE $01

BOOT_STUB:
$0800: 01 A5    ORA ($A5,X)
$0802: 27 C9    RLA $C9
$0804: 09 D0    ORA #$D0
$0806: 13 8A    SLO ($8A),Y
$0808: 4A       LSR
$0809: 4A       LSR
$080A: 4A       LSR
$080B: 4A       LSR
$080C: 09 C0    ORA #$C0
$080E: 85 3F    STA $3F
$0810: A9 5C    LDA #$5C
$0812: 85 3E    STA $3E
$0814: A9 00    LDA #$00
$0816: 85 00    STA $00
$0818: E6 27    INC $27
$081A: E6 00    INC $00
$081C: A4 00    LDY $00
$081E: C0 0B    CPY #$0B
$0820: D0 03    BNE $0825
$0822: 4C 00 10 JMP $1000
$0825: B9 2D 08 LDA $082D,Y
$0828: 85 3D    STA $3D
$082A: 6C 3E 00 JMP ($003E)
$082D: 00       BRK
$082E: 02       KIL
$082F: 04 06    NOP $06
$0831: 08       PHP
$0832: 0A       ASL
$0833: 0C 0E 01 NOP $010E
$0836: 03 05    SLO ($05,X)
$0838: 07 09    SLO $09
$083A: 0B 0D    ANC #$0D
$083C: 0F A0 C3 SLO $C3A0
$083F: CF D0 D9 DCP $D9D0

; (Sector skew table at $082D-$083C, then old-style copyright string
;  through $085C, then ZERO-FILLED to $08FF. 2.20 lacks the second
;  1982 copyright that 2.23 added at $0860.)


; ============================================================================
; SECTION 2 -- Disk I/O block ($0A00-$0FFF, summary only)
;
; Standard Apple Disk II RWTS routines. Per-instruction disassembly is
; in CPM220_RWTS.asm. Major entry points (analogous to 2.23):
;   $0A00  WRITE_SECTOR
;   $0A99  READ_SECTOR
;   $0B5F  SEEK_TRACK
;   $0BEE  LOAD_CPM_LOOP (28-sector main load)
;   $0E10  LOAD_CPM (entry called from stage-2 $1608, $17D0)
;
; Bytes in $0C39-$0FFF that LOOK like illegal 6502 opcodes are likely
; data tables (GCR encode/decode lookup) plus state slots. Not Z-80
; code -- 2.20's BIOS at $DACC doesn't overlap into Apple $0Cxx the
; way 2.23's BIOS at $FAB8 does.
; ============================================================================


; ============================================================================
; SECTION 3 -- Stage-2 loader ($1000-$11FF)
;
; Entry point reached via JMP $1000 from the boot stub. Sets up Apple
; ][ environment, runs install loops, runs the slot scanner, sets up
; the device-code table, runs LOAD_CPM, then runs boot-finalization
; that sets up the Z-80 reset vector and triggers the SoftCard switch.
; ============================================================================

            .ORG $1000

STAGE2_ENTRY:
$1000: AD 81 C0 LDA $C081
$1003: AD 81 C0 LDA $C081
$1006: 20 7D 0F JSR $0F7D
$1009: 48       PHA
$100A: 9D 88 C0 STA $C088,X
$100D: A9 00    LDA #$00
$100F: 99 78 04 STA $0478,Y
$1012: 99 F8 04 STA $04F8,Y
$1015: 20 2F FB JSR $FB2F
$1018: 20 93 FE JSR $FE93  ; OUTPORT
$101B: 20 89 FE JSR $FE89  ; INPORT
$101E: 68       PLA
$101F: A2 FF    LDX #$FF
$1021: 9A       TXS
$1022: C9 06    CMP #$06
$1024: F0 10    BEQ $1036
$1026: A0 00    LDY #$00
$1028: B9 4A 11 LDA $114A,Y
$102B: F0 06    BEQ $1033
$102D: 20 ED FD JSR $FDED  ; COUT (print character)
$1030: C8       INY
$1031: D0 F5    BNE $1028
$1033: 4C 65 FF JMP $FF65
$1036: A0 0E    LDY #$0E
$1038: B9 68 11 LDA $1168,Y
$103B: 99 FF 0F STA $0FFF,Y
$103E: 88       DEY
$103F: D0 F7    BNE $1038
$1041: B9 00 12 LDA $1200,Y
$1044: 99 00 02 STA $0200,Y
$1047: 88       DEY
$1048: D0 F7    BNE $1041
$104A: A0 F1    LDY #$F1
$104C: B9 FF 12 LDA $12FF,Y
$104F: 99 FF 02 STA $02FF,Y
$1052: 88       DEY
$1053: D0 F7    BNE $104C
$1055: 8C B8 03 STY $03B8
$1058: 84 3C    STY $3C
$105A: 88       DEY
$105B: 84 3E    STY $3E
$105D: A0 C7    LDY #$C7
$105F: 20 80 11 JSR $1180
$1062: EA       NOP
$1063: A5 3E    LDA $3E
$1065: F0 18    BEQ $107F
$1067: 20 17 11 JSR $1117
$106A: 85 40    STA $40
$106C: 86 41    STX $41
$106E: 20 17 11 JSR $1117
$1071: E0 00    CPX #$00
$1073: F0 1E    BEQ $1093
$1075: C5 40    CMP $40
$1077: D0 1A    BNE $1093
$1079: E4 41    CPX $41
$107B: F0 1A    BEQ $1097
$107D: D0 14    BNE $1093
$107F: E6 3E    INC $3E
$1081: 8C C8 03 STY $03C8
$1084: A9 00    LDA #$00
$1086: 8D C7 03 STA $03C7
$1089: 8D DE 03 STA $03DE
$108C: 98       TYA
$108D: 18       CLC
$108E: 69 20    ADC #$20
$1090: 8D DF 03 STA $03DF
$1093: A2 00    LDX #$00
$1095: F0 1F    BEQ $10B6
$1097: A2 04    LDX #$04
$1099: A0 05    LDY #$05
$109B: B1 3C    LDA ($3C),Y
$109D: DD 76 11 CMP $1176,X
$10A0: D0 09    BNE $10AB
$10A2: A0 07    LDY #$07
$10A4: B1 3C    LDA ($3C),Y
$10A6: DD 7A 11 CMP $117A,X
$10A9: F0 03    BEQ $10AE
$10AB: CA       DEX
$10AC: D0 EB    BNE $1099
$10AE: E8       INX
$10AF: E0 02    CPX #$02
$10B1: D0 03    BNE $10B6
$10B3: EE B8 03 INC $03B8
$10B6: A4 3D    LDY $3D
$10B8: 8A       TXA
$10B9: 99 F8 02 STA $02F8,Y
$10BC: 88       DEY
$10BD: C0 C0    CPY #$C0
$10BF: D0 9E    BNE $105F
$10C1: 0E B8 03 ASL $03B8
$10C4: A5 3E    LDA $3E
$10C6: C9 01    CMP #$01
$10C8: F0 1D    BEQ $10E7
$10CA: 84 3D    STY $3D
$10CC: A9 85    LDA #$85
$10CE: 85 3C    STA $3C
$10D0: 8D 85 C0 STA $C085
$10D3: A5 3E    LDA $3E
$10D5: F0 10    BEQ $10E7
$10D7: A0 00    LDY #$00
$10D9: B9 2B 11 LDA $112B,Y
$10DC: F0 06    BEQ $10E4
$10DE: 20 ED FD JSR $FDED  ; COUT (print character)
$10E1: C8       INY
$10E2: D0 F5    BNE $10D9
$10E4: 4C 65 FF JMP $FF65
$10E7: A0 10    LDY #$10
$10E9: B9 EF 13 LDA $13EF,Y
$10EC: 99 EF 03 STA $03EF,Y
$10EF: 88       DEY
$10F0: D0 F7    BNE $10E9
$10F2: A9 C3    LDA #$C3
$10F4: 8D 00 10 STA $1000
$10F7: A9 00    LDA #$00
$10F9: 8D 01 10 STA $1001
$10FC: A9 DA    LDA #$DA
$10FE: 8D 02 10 STA $1002
$1101: 20 AD 0F JSR $0FAD
$1104: A9 16    LDA #$16
$1106: 8D CC 0F STA $0FCC
$1109: A0 06    LDY #$06
$110B: B9 24 11 LDA $1124,Y
$110E: 99 F9 FF STA $FFF9,Y
$1111: 88       DEY
$1112: D0 F7    BNE $110B
$1114: 4C D2 03 JMP $03D2
$1117: A9 00    LDA #$00
$1119: AA       TAX
$111A: A8       TAY
$111B: 18       CLC
$111C: 71 3C    ADC ($3C),Y
$111E: 90 01    BCC $1121
$1120: E8       INX
$1121: C8       INY
$1122: D0 F7    BNE $111B
$1124: 60       RTS
$1125: C0 03    CPY #$03
$1127: C0 03    CPY #$03
$1129: C0 03    CPY #$03
$112B: 8D 8D 8D STA $8D8D
$112E: 8D C3 C1 STA $C1C3
$1131: CE A7 D4 DEC $D4A7
$1134: A0 C6    LDY #$C6
$1136: C9 CE    CMP #$CE
$1138: C4 A0    CPY $A0
$113A: DA       NOP
$113B: B8       CLV
$113C: B0 A0    BCS $10DE
$113E: D3 CF    DCP ($CF),Y
$1140: C6 D4    DEC $D4
$1142: C3 C1    DCP ($C1,X)
$1144: D2       KIL
$1145: C4 8D    CPY $8D
$1147: 8D 8D 00 STA $008D
$114A: 8D 8D 8D STA $8D8D
$114D: 8D CD D5 STA $D5CD
$1150: D3 D4    DCP ($D4),Y
$1152: A0 C2    LDY #$C2
$1154: CF CF D4 DCP $D4CF
$1157: A0 C6    LDY #$C6
$1159: D2       KIL
$115A: CF CD A0 DCP $A0CD
$115D: D3 CC    DCP ($CC),Y
$115F: CF D4 A0 DCP $A0D4
$1162: D3 C9    DCP ($C9),Y
$1164: D8       CLD
$1165: 8D 8D 8D STA $8D8D
$1168: 00       BRK
$1169: AF 32 3E LAX $3E32
$116C: F0 6F    BEQ $11DD
$116E: 3A       NOP
$116F: 3D F0 C6 AND $C6F0,X
$1172: 20 67 77 JSR $7767
$1175: 18       CLC
$1176: F2       KIL
$1177: 03 18    SLO ($18,X)
$1179: 38       SEC
$117A: 48       PHA
$117B: 3C 38 18 NOP $1838,X
$117E: 48       PHA
$117F: FF 84 3D ISC $3D84,X
$1182: 8C 87 11 STY $1187
$1185: 8D 00 00 STA $0000
$1188: 60       RTS
$1189: FF FF FF ISC $FFFF,X
$118C: FF FF FF ISC $FFFF,X
$118F: FF FF FF ISC $FFFF,X
$1192: FF FF FF ISC $FFFF,X
$1195: FF FF FF ISC $FFFF,X
$1198: FF FF FF ISC $FFFF,X
$119B: FF FF FF ISC $FFFF,X
$119E: FF FF FF ISC $FFFF,X
$11A1: FF FF FF ISC $FFFF,X
$11A4: FF FF FF ISC $FFFF,X
$11A7: FF FF FF ISC $FFFF,X
$11AA: FF FF FF ISC $FFFF,X
$11AD: FF FF FF ISC $FFFF,X
$11B0: FF FF FF ISC $FFFF,X
$11B3: FF FF FF ISC $FFFF,X
$11B6: FF FF FF ISC $FFFF,X
$11B9: FF FF FF ISC $FFFF,X
$11BC: FF FF FF ISC $FFFF,X
$11BF: FF FF FF ISC $FFFF,X
$11C2: FF FF FF ISC $FFFF,X
$11C5: FF FF FF ISC $FFFF,X
$11C8: FF FF FF ISC $FFFF,X
$11CB: FF FF FF ISC $FFFF,X
$11CE: FF FF FF ISC $FFFF,X
$11D1: FF FF FF ISC $FFFF,X
$11D4: FF FF FF ISC $FFFF,X
$11D7: FF FF FF ISC $FFFF,X
$11DA: FF FF FF ISC $FFFF,X
$11DD: FF FF FF ISC $FFFF,X
$11E0: FF FF FF ISC $FFFF,X
$11E3: FF FF FF ISC $FFFF,X
$11E6: FF FF FF ISC $FFFF,X
$11E9: FF FF FF ISC $FFFF,X
$11EC: FF FF FF ISC $FFFF,X
$11EF: FF FF FF ISC $FFFF,X
$11F2: FF FF FF ISC $FFFF,X
$11F5: FF FF FF ISC $FFFF,X
$11F8: FF FF FF ISC $FFFF,X
$11FB: FF FF FF ISC $FFFF,X
$11FE: FF FF 00 ISC $00FF,X


; ============================================================================
; SECTION 4 -- Page-2 install image source ($1200-$12FF, source-only)
;
; This 256-byte block gets copied to Apple $0200-$02FF by the install
; loop at $1041. The runtime form is in CPM220_InstallFragments.asm.
; The bytes here are the SOURCE; they're meaningless to 6502 disasm at
; $12xx because they execute as 6502 (or are read as data) at $02xx.
; ============================================================================


; ============================================================================
; SECTION 5 -- Page-3 install image source ($1300-$13FF, source-only)
;
; Copied to $0300-$03FF by the install loops at $104C (most of it) and
; $10E9 (last 16 bytes). Includes the warm-boot routine source bytes
; at $13C0-$13DC. Runtime form is in CPM220_InstallFragments.asm.
; ============================================================================
