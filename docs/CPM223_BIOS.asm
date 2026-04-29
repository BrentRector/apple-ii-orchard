; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- Z-80 BIOS ($FAB8-$FFFF, 1352 bytes)
; Annotated Z-80 assembly source for the BIOS region as Z-80 sees it
; in LC RAM after the SoftCard CPU switch.
;
; STRUCTURE
;   The BIOS uses a 256-byte interleaved layout: code pages alternating
;   with runtime-generated pages.
;
;     Page 0  $FAB8-$FBB7  Jump table, dispatch table, generator (CODE)
;     Page 1  $FBB8-$FCB7  Trap markers (RUNTIME-POPULATED)
;     Page 2  $FCB8-$FDB7  Per-device init helpers (CODE)
;     Page 3  $FDB8-$FEB7  Trap markers (RUNTIME-POPULATED)
;     Page 4  $FEB8-$FFB7  Device-scan + BOOT vector landing (CODE)
;     Page 5  $FFB8-$FFFF  Trap markers partial (RUNTIME-POPULATED, 72 bytes)
;
;   Trap markers are "FF FF 00 00 / F7 F7 00 00" patterns that decode
;   as RST $38 / RST $30. Static BIOS code calls/jumps into these
;   pages; the bytes get populated at runtime by the cold-boot
;   generator before any such call/jump fires.
;
; THE COLD-BOOT GENERATOR (Z-80 side of the Videx fix)
;   At $FB3A. Walks the slot-info table at $F3B8+E for E=7..1, dispatches
;   per device code:
;     3 -> $FE81
;     4 -> $FD83 (Pascal 1.0)
;     6 -> $FDB0 (Pascal 1.1) <- NEW IN 2.23
;   The 11-byte 6502 slot-scanner branch (in CPM223_BootLoader.asm) is
;   what writes "6" into the slot-info table for Pascal 1.1 cards. The
;   generator's branch here turns that into a runtime dispatch.
;
; DUAL ADDRESSING
;   The BIOS first 1 KB ($FAB8-$FEB7) ALSO appears at Z-80 $1C38-$1FB7
;   under SoftCard's bit-12 XOR for low addresses. Same physical bytes,
;   accessed via two different Z-80 views of memory. This is how the
;   inter-CPU sync polling loop at $1E39 (the Z-80 disk-callback area)
;   reaches the same code that the BIOS jump table dispatches.
;
; SOURCE
;   Loaded by the 6502 from disk via two LOAD_CPM passes (the second
;   one bank-switches LC RAM via STA $C083 to write into the SoftCard's
;   high-RAM area). The bytes here at $FAB8 ultimately come from
;   physical disk sectors trk2:phys4-9 of CPMV233.DSK.
; ============================================================================

; ----------------------------------------------------------------------------
; Z-80 BIOS state slots (in trap-marker pages, populated at runtime)
; ----------------------------------------------------------------------------
state_FECB      = $FECB       ; current track
state_FED2      = $FED2       ; current sector
state_FED4      = $FED4       ; current DMA address (16-bit)
state_FECD      = $FECD       ; cold-boot state byte (preflight check)
state_FED8      = $FED8       ; (zeroed by cold-boot setup at $FB9F)
state_FEDD      = $FEDD       ; (zeroed by cold-boot setup at $FB9C)

; ----------------------------------------------------------------------------
; TPA-area state (above BDOS, below BIOS)
; ----------------------------------------------------------------------------
slot_info_F3A0  = $F3A0       ; device-code table base (scanned by device-scan)
slot_info_F3B8  = $F3B8       ; slot-info table for cold-boot generator
                              ;   F3B8+E = slot E's device code (E=1..7)
state_F397      = $F397       ; (read by preflight code at $FF17)

; ----------------------------------------------------------------------------
; CCP+BDOS final positions (after relocation by loader's third page copy)
; ----------------------------------------------------------------------------
BDOS_ENTRY      = $9C06       ; planted at $0005-$0007 as "JP $9C06"
BDOS_SENTINEL   = $9C08       ; first-boot vs warm-boot detect

; ----------------------------------------------------------------------------
; Apple I/O (used by BIOS for Apple ][ video state)
; ----------------------------------------------------------------------------
APPLE_TEXT_FLAG = $E051       ; Apple ][ video text/graphics state

            .ORG $FAB8


; ============================================================================
; SECTION 1 -- BIOS Jump Table ($FAB8-$FAE4)
;
; Standard CP/M 2.x 15-entry jump table. Each entry is "JP target".
; Many targets land in trap-marker pages, where bytes get populated
; at runtime by the cold-boot generator before any of these jumps fire.
;
;   Offset  Address  Routine     Target
;   0       $FAB8    BOOT        $FED1  (NOP slide -> device-scan)
;   3       $FABB    WBOOT       $FAB8  (jumps to BOOT)
;   6       $FABE    CONST       $FB10  (in code page 0)
;   9       $FAC1    CONIN       $FB1A
;   12      $FAC4    CONOUT      $FB4D
;   15      $FAC7    LIST        $FB70  (cold-boot continuation routine
;                                        also reachable here)
;   18      $FACA    PUNCH       $FB7F
;   21      $FACD    READER      $FB91
;   24      $FAD0    HOME        $FE6C
;   27      $FAD3    SELDSK      $FE8E
;   30      $FAD6    SETTRK      $FE77
;   33      $FAD9    SETSEC      $FBF4
;   36      $FADC    SETDMA      $FBF9
;   39      $FADF    READ        $FEBD
;   42      $FAE2    WRITE       $FEC0
;
; Many READ/WRITE/HOME/etc. targets land in the NOP slide of code page 4.
; Their actual handler bytes get planted there at boot time.
; ============================================================================

JUMP_TABLE:
$FAB8: C3 D1 FE  JP FED1
$FABB: C3 B8 FA  JP FAB8
$FABE: C3 10 FB  JP FB10
$FAC1: C3 1A FB  JP FB1A
$FAC4: C3 4D FB  JP FB4D
$FAC7: C3 70 FB  JP FB70
$FACA: C3 7F FB  JP FB7F
$FACD: C3 91 FB  JP FB91
$FAD0: C3 6C FE  JP FE6C
$FAD3: C3 8E FE  JP FE8E
$FAD6: C3 77 FE  JP FE77
$FAD9: C3 F4 FB  JP FBF4
$FADC: C3 F9 FB  JP FBF9
$FADF: C3 BD FE  JP FEBD
$FAE2: C3 C0 FE  JP FEC0
$FAE5: AF        XOR A
$FAE6: C9        RET
$FAE7: 00        NOP
$FAE8: 60        LD H,B
$FAE9: 69        LD L,C
$FAEA: C9        RET

; ============================================================================
; SECTION 3 -- Per-device dispatch table ($FAEB-$FB29)
;
; 4 entries x 16 bytes each = 64 bytes. Each entry holds 8 zero/state
; bytes followed by 4 pointers:
;   bytes 0-7: per-entry runtime-mutable state (set at boot, modified
;              during cooperative-CPU operations)
;   bytes 8-9: $FEE4 (state-byte address common to all entries)
;   bytes 10-11: $FE73 or similar (entry-point trampoline)
;   bytes 12-13: per-entry handler 1 address (for one of CONOUT/CONIN/etc)
;   bytes 14-15: per-entry handler 2 address
;
; All 4 dispatch targets land in TRAP-MARKER PAGES on disk -- they're
; populated at runtime by the cold-boot generator. See Part 6 of the
; article series ("The BIOS Factory").
; ============================================================================


$FAEB: 00        NOP
$FAEC: 00        NOP
$FAED: 00        NOP
$FAEE: 00        NOP
$FAEF: 00        NOP
$FAF0: 00        NOP
$FAF1: 00        NOP
$FAF2: 00        NOP
$FAF3: E4 FE 73  CALL PO,73FE
$FAF6: FA AC FF  JP M,FFAC
$FAF9: 64        LD H,H
$FAFA: FF        RST $38
$FAFB: 00        NOP
$FAFC: 00        NOP
$FAFD: 00        NOP
$FAFE: 00        NOP
$FAFF: 00        NOP
$FB00: 00        NOP
$FB01: 00        NOP
$FB02: 00        NOP
$FB03: E4 FE 73  CALL PO,73FE
$FB06: FA B8 FF  JP M,FFB8
$FB09: 76        HALT
$FB0A: FF        RST $38
$FB0B: 00        NOP
$FB0C: 00        NOP
$FB0D: 00        NOP
$FB0E: 00        NOP
$FB0F: 00        NOP
$FB10: 00        NOP
$FB11: 00        NOP
$FB12: 00        NOP
$FB13: E4 FE 73  CALL PO,73FE
$FB16: FA C4 FF  JP M,FFC4
$FB19: 88        ADC A,B
$FB1A: FF        RST $38
$FB1B: 00        NOP
$FB1C: 00        NOP
$FB1D: 00        NOP
$FB1E: 00        NOP
$FB1F: 00        NOP
$FB20: 00        NOP
$FB21: 00        NOP
$FB22: 00        NOP
$FB23: E4 FE 73  CALL PO,73FE
$FB26: FA D0 FF  JP M,FFD0
$FB29: 9A        SBC A,D
$FB2A: FF        RST $38

; ============================================================================
; SECTION 4 -- Control-character data table ($FB2B-$FB39)
; ============================================================================


$FB2B: 20 00     JR NZ,FB2D
$FB2D: 03        INC BC
$FB2E: 07        RLCA
$FB2F: 00        NOP
$FB30: 8B        ADC A,E
$FB31: 00        NOP
$FB32: 2F        CPL
$FB33: 00        NOP
$FB34: C0        RET NZ
$FB35: 00        NOP
$FB36: 0C        INC C
$FB37: 00        NOP
$FB38: 03        INC BC
$FB39: 00        NOP

; ============================================================================
; SECTION 5 -- COLD-BOOT GENERATOR ($FB3A-$FB68) - "THE BIOS FACTORY"
;
; Walks slots 7..1 looking up device codes from the slot-info table
; built by the 6502 slot scanner. Dispatches per-device init based on
; what was detected.
;
; Device codes handled:
;   3 -> CALL $FE81
;   4 -> CALL $FD83 (Pascal 1.0; +HL=$C800 setup)
;   6 -> CALL $FDB0 (Pascal 1.1 / Videx) <- NEW IN 2.23, ABSENT FROM 2.20
;
; This is the Z-80 side of the Videx fix. See Part 6 of the article
; series for full context.
; ============================================================================


$FB3A: 11 07 00  LD DE,0007
$FB3D: 21 B8 F3  LD HL,F3B8
$FB40: 19        ADD HL,DE
$FB41: 7E        LD A,(HL)
$FB42: D6 03     SUB 03
$FB44: 20 07     JR NZ,FB4D
$FB46: CD 81 FE  CALL FE81
$FB49: 36 03     LD (HL),03
$FB4B: 36 15     LD (HL),15
$FB4D: 3D        DEC A
$FB4E: 20 0B     JR NZ,FB5B
$FB50: CD 83 FD  CALL FD83
$FB53: 21 00 C8  LD HL,C800
$FB56: CD 45 FB  CALL FB45
$FB59: 18 0A     JR FB65
$FB5B: FE 02     CP 02
$FB5D: 20 06     JR NZ,FB65
$FB5F: 21 D0 0D  LD HL,0DD0
$FB62: CD B0 FD  CALL FDB0
$FB65: 1D        DEC E
$FB66: 20 D5     JR NZ,FB3D
$FB68: C9        RET

; ============================================================================
; SECTION 6 -- Small helper ($FB69-$FB6F)
; ============================================================================


$FB69: 21 00 E0  LD HL,E000
$FB6C: 7B        LD A,E
$FB6D: B4        OR H
$FB6E: 67        LD H,A
$FB6F: C9        RET

; ============================================================================
; SECTION 7 -- Cold-boot continuation / WBOOT ($FB70-$FBB6)
;
; The bytes at $FB70 are reached as the LIST jump-table entry but the
; code is cold-boot-style: stack init, BDOS-vector planting, Z-80 reset
; vector rewrite. The actual BOOT vector ($FED1) presumably reaches
; this code via runtime-installed bytes in its NOP-slide region.
;
; Key actions:
;   - Init Z-80 stack to $0080
;   - First-boot vs warm-boot detect via $9C08 sentinel
;   - Plant $C3 at Z-80 $0000-$0002: rewrites reset vector from
;     "JP $FA00" (planted by 6502) to "JP $FA03" (skip first-instruction
;     init on subsequent warm-boots)
;   - Plant $C3 + $9C06 at $0005-$0007: standard CP/M BDOS call vector
;     pointing at the relocated BDOS at $9C06
; ============================================================================


$FB70: 31 80 00  LD SP,0080
$FB73: 3A 51 E0  LD A,(E051)
$FB76: 21 00 0E  LD HL,0E00
$FB79: CD 45 FB  CALL FB45
$FB7C: CD 82 FA  CALL FA82
$FB7F: 3A 08 9C  LD A,(9C08)
$FB82: FE 9C     CP 9C
$FB84: 28 11     JR Z,FB97
$FB86: 21 59 FF  LD HL,FF59
$FB89: 22 D0 F3  LD (F3D0),HL
$FB8C: 2A DE F3  LD HL,(F3DE)
$FB8F: 3E 77     LD A,77
$FB91: 32 0B 00  LD (000B),A
$FB94: C3 0B 00  JP 000B
$FB97: AF        XOR A
$FB98: 32 07 93  LD (9307),A
$FB9B: AF        XOR A
$FB9C: 32 DD FE  LD (FEDD),A
$FB9F: 32 D8 FE  LD (FED8),A
$FBA2: 3E C3     LD A,C3
$FBA4: 32 00 00  LD (0000),A
$FBA7: 21 03 FA  LD HL,FA03
$FBAA: 22 01 00  LD (0001),HL
$FBAD: 32 05 00  LD (0005),A
$FBB0: 21 06 9C  LD HL,9C06
$FBB3: 22 06 00  LD (0006),HL
$FBB6: 01 80 FF  LD BC,FF80
$FBB9: FF        RST $38
$FBBA: 00        NOP
$FBBB: 00        NOP
$FBBC: FF        RST $38
$FBBD: FF        RST $38
$FBBE: 00        NOP
$FBBF: 00        NOP
$FBC0: FF        RST $38
$FBC1: FF        RST $38
$FBC2: 00        NOP
$FBC3: 00        NOP
$FBC4: FF        RST $38
$FBC5: FF        RST $38
$FBC6: 00        NOP
$FBC7: 00        NOP
$FBC8: F7        RST $30
$FBC9: F7        RST $30
$FBCA: 00        NOP
$FBCB: 00        NOP
$FBCC: F7        RST $30
$FBCD: F7        RST $30
$FBCE: 00        NOP
$FBCF: 00        NOP
$FBD0: F7        RST $30
$FBD1: F7        RST $30
$FBD2: 00        NOP
$FBD3: 00        NOP
$FBD4: F7        RST $30
$FBD5: F7        RST $30
$FBD6: 00        NOP
$FBD7: 00        NOP
$FBD8: FF        RST $38
$FBD9: FF        RST $38
$FBDA: 00        NOP
$FBDB: 00        NOP
$FBDC: FF        RST $38
$FBDD: FF        RST $38
$FBDE: 00        NOP
$FBDF: 00        NOP
$FBE0: FF        RST $38
$FBE1: FF        RST $38
$FBE2: 00        NOP
$FBE3: 00        NOP
$FBE4: FF        RST $38
$FBE5: FF        RST $38
$FBE6: 00        NOP
$FBE7: 00        NOP
$FBE8: FF        RST $38
$FBE9: FF        RST $38
$FBEA: 00        NOP
$FBEB: 00        NOP
$FBEC: FF        RST $38
$FBED: FF        RST $38
$FBEE: 00        NOP
$FBEF: 00        NOP
$FBF0: FF        RST $38
$FBF1: FF        RST $38
$FBF2: 00        NOP
$FBF3: 00        NOP
$FBF4: FF        RST $38
$FBF5: FF        RST $38
$FBF6: 00        NOP
$FBF7: 00        NOP
$FBF8: FF        RST $38
$FBF9: FF        RST $38
$FBFA: 00        NOP
$FBFB: 00        NOP
$FBFC: FF        RST $38
$FBFD: FF        RST $38
$FBFE: 00        NOP
$FBFF: 00        NOP
$FC00: FF        RST $38
$FC01: FF        RST $38
$FC02: 00        NOP
$FC03: 00        NOP
$FC04: FF        RST $38
$FC05: FF        RST $38
$FC06: 00        NOP
$FC07: 00        NOP
$FC08: FF        RST $38
$FC09: FF        RST $38
$FC0A: 00        NOP
$FC0B: 00        NOP
$FC0C: FF        RST $38
$FC0D: FF        RST $38
$FC0E: 00        NOP
$FC0F: 00        NOP
$FC10: FF        RST $38
$FC11: FF        RST $38
$FC12: 00        NOP
$FC13: 00        NOP
$FC14: FF        RST $38
$FC15: FF        RST $38
$FC16: 00        NOP
$FC17: 00        NOP
$FC18: FF        RST $38
$FC19: FF        RST $38
$FC1A: 00        NOP
$FC1B: 00        NOP
$FC1C: FF        RST $38
$FC1D: FF        RST $38
$FC1E: 00        NOP
$FC1F: 00        NOP
$FC20: FF        RST $38
$FC21: FF        RST $38
$FC22: 00        NOP
$FC23: 00        NOP
$FC24: FF        RST $38
$FC25: FF        RST $38
$FC26: 00        NOP
$FC27: 00        NOP
$FC28: F7        RST $30
$FC29: F7        RST $30
$FC2A: 00        NOP
$FC2B: 00        NOP
$FC2C: F7        RST $30
$FC2D: F7        RST $30
$FC2E: 00        NOP
$FC2F: 00        NOP
$FC30: F7        RST $30
$FC31: F7        RST $30
$FC32: 00        NOP
$FC33: 00        NOP
$FC34: F7        RST $30
$FC35: F7        RST $30
$FC36: 00        NOP
$FC37: 00        NOP
$FC38: FF        RST $38
$FC39: FF        RST $38
$FC3A: 00        NOP
$FC3B: 00        NOP
$FC3C: FF        RST $38
$FC3D: FF        RST $38
$FC3E: 00        NOP
$FC3F: 00        NOP
$FC40: FF        RST $38
$FC41: FF        RST $38
$FC42: 00        NOP
$FC43: 00        NOP
$FC44: FF        RST $38
$FC45: FF        RST $38
$FC46: 00        NOP
$FC47: 00        NOP
$FC48: FF        RST $38
$FC49: FF        RST $38
$FC4A: 00        NOP
$FC4B: 00        NOP
$FC4C: FF        RST $38
$FC4D: FF        RST $38
$FC4E: 00        NOP
$FC4F: 00        NOP
$FC50: FF        RST $38
$FC51: FF        RST $38
$FC52: 00        NOP
$FC53: 00        NOP
$FC54: FF        RST $38
$FC55: FF        RST $38
$FC56: 00        NOP
$FC57: 00        NOP
$FC58: FF        RST $38
$FC59: FF        RST $38
$FC5A: 00        NOP
$FC5B: 00        NOP
$FC5C: FF        RST $38
$FC5D: FF        RST $38
$FC5E: 00        NOP
$FC5F: 00        NOP
$FC60: FF        RST $38
$FC61: FF        RST $38
$FC62: 00        NOP
$FC63: 00        NOP
$FC64: FF        RST $38
$FC65: FF        RST $38
$FC66: 00        NOP
$FC67: 00        NOP
$FC68: FF        RST $38
$FC69: FF        RST $38
$FC6A: 00        NOP
$FC6B: 00        NOP
$FC6C: FF        RST $38
$FC6D: FF        RST $38
$FC6E: 00        NOP
$FC6F: 00        NOP
$FC70: FF        RST $38
$FC71: FF        RST $38
$FC72: 00        NOP
$FC73: 00        NOP
$FC74: FF        RST $38
$FC75: FF        RST $38
$FC76: 00        NOP
$FC77: 00        NOP
$FC78: FF        RST $38
$FC79: FF        RST $38
$FC7A: 00        NOP
$FC7B: 00        NOP
$FC7C: FF        RST $38
$FC7D: FF        RST $38
$FC7E: 00        NOP
$FC7F: 00        NOP
$FC80: FF        RST $38
$FC81: FF        RST $38
$FC82: 00        NOP
$FC83: 00        NOP
$FC84: FF        RST $38
$FC85: FF        RST $38
$FC86: 00        NOP
$FC87: 00        NOP
$FC88: FF        RST $38
$FC89: FF        RST $38
$FC8A: 00        NOP
$FC8B: 00        NOP
$FC8C: FF        RST $38
$FC8D: FF        RST $38
$FC8E: 00        NOP
$FC8F: 00        NOP
$FC90: FF        RST $38
$FC91: FF        RST $38
$FC92: 00        NOP
$FC93: 00        NOP
$FC94: FF        RST $38
$FC95: FF        RST $38
$FC96: 00        NOP
$FC97: 00        NOP
$FC98: FF        RST $38
$FC99: FF        RST $38
$FC9A: 00        NOP
$FC9B: 00        NOP
$FC9C: FF        RST $38
$FC9D: FF        RST $38
$FC9E: 00        NOP
$FC9F: 00        NOP
$FCA0: FF        RST $38
$FCA1: FF        RST $38
$FCA2: 00        NOP
$FCA3: 00        NOP
$FCA4: FF        RST $38
$FCA5: FF        RST $38
$FCA6: 00        NOP
$FCA7: 00        NOP
$FCA8: F7        RST $30
$FCA9: FF        RST $38
$FCAA: 00        NOP
$FCAB: 00        NOP
$FCAC: FF        RST $38
$FCAD: FF        RST $38
$FCAE: 00        NOP
$FCAF: 00        NOP
$FCB0: FF        RST $38
$FCB1: FF        RST $38
$FCB2: 00        NOP
$FCB3: 00        NOP
$FCB4: FF        RST $38
$FCB5: FF        RST $38
$FCB6: 00        NOP
$FCB7: 00        NOP

; ============================================================================
; SECTION 9 -- Code page 2 ($FCB8-$FDB7)
;
; Per-device init helpers and dispatch helpers. Includes:
;   $FD83  device-4 (Pascal 1.0) init -- called by generator
;   $FDB0  device-6 (Pascal 1.1) init -- called by generator
;          NOTE: as it appears on disk, $FDB0 is ONE BYTE: a "RET"
;          stub. The actual driver-install path lives elsewhere.
;          See $FDB0-stub devlog for the dead-end finding.
; ============================================================================


$FCB8: 00        NOP
$FCB9: CD F9 FB  CALL FBF9
$FCBC: 3E 01     LD A,01
$FCBE: 32 4E 97  LD (974E),A
$FCC1: 3A 04 00  LD A,(0004)
$FCC4: 4F        LD C,A
$FCC5: C3 00 93  JP 9300
$FCC8: 2A 80 F3  LD HL,(F380)
$FCCB: E9        JP (HL)
$FCCC: 3A 00 E0  LD A,(E000)
$FCCF: 17        RLA
$FCD0: 9F        SBC A,A
$FCD1: C9        RET
$FCD2: CD 5A FB  CALL FB5A
$FCD5: E6 7F     AND 7F
$FCD7: 21 AB F3  LD HL,F3AB
$FCDA: 06 06     LD B,06
$FCDC: 4F        LD C,A
$FCDD: 23        INC HL
$FCDE: 7E        LD A,(HL)
$FCDF: 23        INC HL
$FCE0: B7        OR A
$FCE1: FA 31 FB  JP M,FB31
$FCE4: B9        CP C
$FCE5: 7E        LD A,(HL)
$FCE6: C8        RET Z
$FCE7: 10 F4     DJNZ FCDD
$FCE9: 79        LD A,C
$FCEA: C9        RET
$FCEB: 11 03 00  LD DE,0003
$FCEE: C3 39 FB  JP FB39
$FCF1: 3A 00 E0  LD A,(E000)
$FCF4: 17        RLA
$FCF5: 30 FA     JR NC,FCF1
$FCF7: 32 10 E0  LD (E010),A
$FCFA: 3F        CCF
$FCFB: 1F        RRA
$FCFC: C9        RET
$FCFD: 22 D0 F3  LD (F3D0),HL
$FD00: 32 00 00  LD (0000),A
$FD03: C9        RET
$FD04: 4F        LD C,A
$FD05: 3A 03 00  LD A,(0003)
$FD08: E6 03     AND 03
$FD0A: FE 02     CP 02
$FD0C: 20 4B     JR NZ,FD59
$FD0E: 2A 92 F3  LD HL,(F392)
$FD11: E9        JP (HL)
$FD12: 3A 03 00  LD A,(0003)
$FD15: E6 03     AND 03
$FD17: FE 02     CP 02
$FD19: 2A 84 F3  LD HL,(F384)
$FD1C: 28 06     JR Z,FD24
$FD1E: 30 07     JR NC,FD27
$FD20: 2A 82 F3  LD HL,(F382)
$FD23: E9        JP (HL)
$FD24: 2A 8A F3  LD HL,(F38A)
$FD27: E9        JP (HL)
$FD28: 3A 03 00  LD A,(0003)
$FD2B: E6 C0     AND C0
$FD2D: FE 80     CP 80
$FD2F: 38 27     JR C,FD58
$FD31: 28 DB     JR Z,FD0E
$FD33: 2A 94 F3  LD HL,(F394)
$FD36: E9        JP (HL)
$FD37: 3A 03 00  LD A,(0003)
$FD3A: E6 30     AND 30
$FD3C: FE 10     CP 10
$FD3E: 38 18     JR C,FD58
$FD40: 2A 8E F3  LD HL,(F38E)
$FD43: 28 E2     JR Z,FD27
$FD45: 2A 90 F3  LD HL,(F390)
$FD48: E9        JP (HL)
$FD49: 3A 03 00  LD A,(0003)
$FD4C: E6 0C     AND 0C
$FD4E: FE 08     CP 08
$FD50: 38 CE     JR C,FD20
$FD52: 28 D0     JR Z,FD24
$FD54: 2A 8C F3  LD HL,(F38C)
$FD57: E9        JP (HL)
$FD58: 37        SCF
$FD59: 9F        SBC A,A
$FD5A: 21 A2 F3  LD HL,F3A2
$FD5D: 6E        LD L,(HL)
$FD5E: 2C        INC L
$FD5F: CA A4 FC  JP Z,FCA4
$FD62: 21 CB FE  LD HL,FECB
$FD65: 77        LD (HL),A
$FD66: CB        DB $CB
$FD67: B9        CP C
$FD68: 23        INC HL
$FD69: 7E        LD A,(HL)
$FD6A: B7        OR A
$FD6B: CA 56 FC  JP Z,FC56
$FD6E: 35        DEC (HL)
$FD6F: 3A 96 F3  LD A,(F396)
$FD72: 21 D4 FE  LD HL,FED4
$FD75: 28 0C     JR Z,FD83
$FD77: B7        OR A
$FD78: F2 C6 FB  JP P,FBC6
$FD7B: 2B        DEC HL
$FD7C: E6 7F     AND 7F
$FD7E: 5F        LD E,A
$FD7F: 79        LD A,C
$FD80: 93        SUB E
$FD81: 77        LD (HL),A
$FD82: C9        RET
$FD83: B7        OR A
$FD84: FA D0 FB  JP M,FBD0
$FD87: 2B        DEC HL
$FD88: CD C4 FB  CALL FBC4
$FD8B: 2A D3 FE  LD HL,(FED3)
$FD8E: 3A A1 F3  LD A,(F3A1)
$FD91: B7        OR A
$FD92: F2 E2 FB  JP P,FBE2
$FD95: E6 7F     AND 7F
$FD97: 5D        LD E,L
$FD98: 6C        LD L,H
$FD99: 63        LD H,E
$FD9A: 5F        LD E,A
$FD9B: 84        ADD A,H
$FD9C: 4F        LD C,A
$FD9D: 7B        LD A,E
$FD9E: 85        ADD A,L
$FD9F: F5        PUSH AF
$FDA0: 06 07     LD B,07
$FDA2: CD A4 FC  CALL FCA4
$FDA5: F1        POP AF
$FDA6: 06 0A     LD B,0A
$FDA8: 4F        LD C,A
$FDA9: C3 A4 FC  JP FCA4
$FDAC: 79        LD A,C
$FDAD: 32 D2 FE  LD (FED2),A
$FDB0: C9        RET
$FDB1: ED        DB $ED
$FDB2: 43        LD B,E
$FDB3: E1        POP HL
$FDB4: FE C9     CP C9
$FDB6: 00        NOP
$FDB7: 00        NOP

; ============================================================================
; SECTION 10 -- TRAP-MARKER PAGE 3 ($FDB8-$FEB7)
;
; Another 256-byte runtime-population zone. The cold-boot generator's
; CALL $FE81 (device-3 init) lands HERE when this page is populated;
; on disk, $FE81 is a trap marker.
; ============================================================================


$FDB8: FF        RST $38
$FDB9: FF        RST $38
$FDBA: 00        NOP
$FDBB: 00        NOP
$FDBC: FF        RST $38
$FDBD: FF        RST $38
$FDBE: 00        NOP
$FDBF: 00        NOP
$FDC0: FF        RST $38
$FDC1: FF        RST $38
$FDC2: 00        NOP
$FDC3: 00        NOP
$FDC4: FF        RST $38
$FDC5: FF        RST $38
$FDC6: 00        NOP
$FDC7: 00        NOP
$FDC8: F7        RST $30
$FDC9: F7        RST $30
$FDCA: 00        NOP
$FDCB: 00        NOP
$FDCC: F7        RST $30
$FDCD: F7        RST $30
$FDCE: 00        NOP
$FDCF: 00        NOP
$FDD0: F7        RST $30
$FDD1: F7        RST $30
$FDD2: 00        NOP
$FDD3: 00        NOP
$FDD4: F7        RST $30
$FDD5: F7        RST $30
$FDD6: 10 00     DJNZ FDD8
$FDD8: FF        RST $38
$FDD9: FF        RST $38
$FDDA: 00        NOP
$FDDB: 00        NOP
$FDDC: FF        RST $38
$FDDD: FF        RST $38
$FDDE: 00        NOP
$FDDF: 00        NOP
$FDE0: FF        RST $38
$FDE1: FF        RST $38
$FDE2: 00        NOP
$FDE3: 00        NOP
$FDE4: FF        RST $38
$FDE5: FF        RST $38
$FDE6: 00        NOP
$FDE7: 00        NOP
$FDE8: FF        RST $38
$FDE9: FF        RST $38
$FDEA: 00        NOP
$FDEB: 00        NOP
$FDEC: FF        RST $38
$FDED: FF        RST $38
$FDEE: 00        NOP
$FDEF: 00        NOP
$FDF0: FF        RST $38
$FDF1: FF        RST $38
$FDF2: 00        NOP
$FDF3: 00        NOP
$FDF4: FF        RST $38
$FDF5: FF        RST $38
$FDF6: 00        NOP
$FDF7: 00        NOP
$FDF8: FF        RST $38
$FDF9: FF        RST $38
$FDFA: 00        NOP
$FDFB: 00        NOP
$FDFC: FF        RST $38
$FDFD: FF        RST $38
$FDFE: 00        NOP
$FDFF: 00        NOP
$FE00: FF        RST $38
$FE01: FF        RST $38
$FE02: 00        NOP
$FE03: 00        NOP
$FE04: FF        RST $38
$FE05: FF        RST $38
$FE06: 00        NOP
$FE07: 00        NOP
$FE08: FF        RST $38
$FE09: FF        RST $38
$FE0A: 00        NOP
$FE0B: 00        NOP
$FE0C: FF        RST $38
$FE0D: FF        RST $38
$FE0E: 00        NOP
$FE0F: 00        NOP
$FE10: FF        RST $38
$FE11: FF        RST $38
$FE12: 00        NOP
$FE13: 00        NOP
$FE14: FF        RST $38
$FE15: FF        RST $38
$FE16: 00        NOP
$FE17: 00        NOP
$FE18: FF        RST $38
$FE19: FF        RST $38
$FE1A: 00        NOP
$FE1B: 00        NOP
$FE1C: FF        RST $38
$FE1D: FF        RST $38
$FE1E: 00        NOP
$FE1F: 00        NOP
$FE20: FF        RST $38
$FE21: FF        RST $38
$FE22: 00        NOP
$FE23: 00        NOP
$FE24: FF        RST $38
$FE25: FF        RST $38
$FE26: 10 00     DJNZ FE28
$FE28: F7        RST $30
$FE29: F7        RST $30
$FE2A: 00        NOP
$FE2B: 00        NOP
$FE2C: F7        RST $30
$FE2D: F7        RST $30
$FE2E: 00        NOP
$FE2F: 00        NOP
$FE30: F7        RST $30
$FE31: F7        RST $30
$FE32: 00        NOP
$FE33: 00        NOP
$FE34: F7        RST $30
$FE35: F7        RST $30
$FE36: 00        NOP
$FE37: 00        NOP
$FE38: FF        RST $38
$FE39: FF        RST $38
$FE3A: 00        NOP
$FE3B: 00        NOP
$FE3C: FF        RST $38
$FE3D: FF        RST $38
$FE3E: 00        NOP
$FE3F: 00        NOP
$FE40: FF        RST $38
$FE41: FF        RST $38
$FE42: 00        NOP
$FE43: 00        NOP
$FE44: FF        RST $38
$FE45: FF        RST $38
$FE46: 00        NOP
$FE47: 00        NOP
$FE48: F7        RST $30
$FE49: F7        RST $30
$FE4A: 00        NOP
$FE4B: 00        NOP
$FE4C: F7        RST $30
$FE4D: F7        RST $30
$FE4E: 00        NOP
$FE4F: 00        NOP
$FE50: F7        RST $30
$FE51: F7        RST $30
$FE52: 00        NOP
$FE53: 00        NOP
$FE54: FF        RST $38
$FE55: F7        RST $30
$FE56: 00        NOP
$FE57: 00        NOP
$FE58: FF        RST $38
$FE59: FF        RST $38
$FE5A: 00        NOP
$FE5B: 00        NOP
$FE5C: FF        RST $38
$FE5D: FF        RST $38
$FE5E: 00        NOP
$FE5F: 00        NOP
$FE60: FF        RST $38
$FE61: FF        RST $38
$FE62: 00        NOP
$FE63: 00        NOP
$FE64: FF        RST $38
$FE65: FF        RST $38
$FE66: 00        NOP
$FE67: 00        NOP
$FE68: FF        RST $38
$FE69: FF        RST $38
$FE6A: 00        NOP
$FE6B: 00        NOP
$FE6C: FF        RST $38
$FE6D: FF        RST $38
$FE6E: 00        NOP
$FE6F: 00        NOP
$FE70: FF        RST $38
$FE71: FF        RST $38
$FE72: 00        NOP
$FE73: 00        NOP
$FE74: FF        RST $38
$FE75: FF        RST $38
$FE76: 00        NOP
$FE77: 00        NOP
$FE78: FF        RST $38
$FE79: FF        RST $38
$FE7A: 00        NOP
$FE7B: 00        NOP
$FE7C: FF        RST $38
$FE7D: FF        RST $38
$FE7E: 00        NOP
$FE7F: 00        NOP
$FE80: FF        RST $38
$FE81: FF        RST $38
$FE82: 00        NOP
$FE83: 00        NOP
$FE84: FF        RST $38
$FE85: FF        RST $38
$FE86: 00        NOP
$FE87: 00        NOP
$FE88: FF        RST $38
$FE89: FF        RST $38
$FE8A: 00        NOP
$FE8B: 00        NOP
$FE8C: FF        RST $38
$FE8D: FF        RST $38
$FE8E: 00        NOP
$FE8F: 00        NOP
$FE90: FF        RST $38
$FE91: FF        RST $38
$FE92: 00        NOP
$FE93: 00        NOP
$FE94: FF        RST $38
$FE95: FF        RST $38
$FE96: 00        NOP
$FE97: 00        NOP
$FE98: FF        RST $38
$FE99: FF        RST $38
$FE9A: 00        NOP
$FE9B: 00        NOP
$FE9C: FF        RST $38
$FE9D: FF        RST $38
$FE9E: 00        NOP
$FE9F: 00        NOP
$FEA0: FF        RST $38
$FEA1: FF        RST $38
$FEA2: 00        NOP
$FEA3: 00        NOP
$FEA4: FF        RST $38
$FEA5: FF        RST $38
$FEA6: 00        NOP
$FEA7: 00        NOP
$FEA8: F7        RST $30
$FEA9: F7        RST $30
$FEAA: 00        NOP
$FEAB: 00        NOP
$FEAC: F7        RST $30
$FEAD: F7        RST $30
$FEAE: 00        NOP
$FEAF: 00        NOP
$FEB0: F7        RST $30
$FEB1: F7        RST $30
$FEB2: 00        NOP
$FEB3: 00        NOP
$FEB4: F7        RST $30
$FEB5: F7        RST $30
$FEB6: 00        NOP
$FEB7: 00        NOP

; ============================================================================
; SECTION 11 -- Code page 4 ($FEB8-$FFB7)
;
; Contains the BOOT vector landing zone (NOP slide $FED1-$FF0D) and
; the static device-scan loop at $FF0E.
;
; The BIOS jump table sends BOOT to $FED1, which is in the NOP slide.
; Execution flows through ~60 NOPs and reaches the device-scan code at
; $FF0E. The scan walks 9 entries from $F3A0 (slot info) looking for a
; match against the current device code.
;
; HOME ($FE6C), SETTRK ($FE77), SELDSK ($FE8E), READ ($FEBD), WRITE
; ($FEC0) all jump-table targets land in this page or the NOP slide.
; READ and WRITE specifically land at $FEBD/$FEC0 in the NOP region;
; their actual handler bytes get installed there at boot.
; ============================================================================


$FEB8: 00        NOP
$FEB9: 00        NOP
$FEBA: 00        NOP
$FEBB: 00        NOP
$FEBC: 00        NOP
$FEBD: 00        NOP
$FEBE: 00        NOP
$FEBF: 00        NOP
$FEC0: 00        NOP
$FEC1: 00        NOP
$FEC2: 00        NOP
$FEC3: 00        NOP
$FEC4: 00        NOP
$FEC5: 00        NOP
$FEC6: 00        NOP
$FEC7: 00        NOP
$FEC8: 00        NOP
$FEC9: 00        NOP
$FECA: 00        NOP
$FECB: 00        NOP
$FECC: 00        NOP
$FECD: 00        NOP
$FECE: 00        NOP
$FECF: 00        NOP
$FED0: 00        NOP
$FED1: 00        NOP
$FED2: 00        NOP
$FED3: 00        NOP
$FED4: 00        NOP
$FED5: 00        NOP
$FED6: 00        NOP
$FED7: 00        NOP
$FED8: 00        NOP
$FED9: 00        NOP
$FEDA: 00        NOP
$FEDB: 00        NOP
$FEDC: 00        NOP
$FEDD: 00        NOP
$FEDE: 00        NOP
$FEDF: 00        NOP
$FEE0: 00        NOP
$FEE1: 00        NOP
$FEE2: 00        NOP
$FEE3: 00        NOP
$FEE4: 00        NOP
$FEE5: 00        NOP
$FEE6: 00        NOP
$FEE7: 00        NOP
$FEE8: 00        NOP
$FEE9: 00        NOP
$FEEA: 00        NOP
$FEEB: 00        NOP
$FEEC: 00        NOP
$FEED: 00        NOP
$FEEE: 00        NOP
$FEEF: 00        NOP
$FEF0: 00        NOP
$FEF1: 00        NOP
$FEF2: 00        NOP
$FEF3: 00        NOP
$FEF4: 00        NOP
$FEF5: 00        NOP
$FEF6: 00        NOP
$FEF7: 00        NOP
$FEF8: 00        NOP
$FEF9: 00        NOP
$FEFA: 00        NOP
$FEFB: 00        NOP
$FEFC: 00        NOP
$FEFD: 00        NOP
$FEFE: 00        NOP
$FEFF: 00        NOP
$FF00: 00        NOP
$FF01: 00        NOP
$FF02: 00        NOP
$FF03: 00        NOP
$FF04: 00        NOP
$FF05: 00        NOP
$FF06: 00        NOP
$FF07: 00        NOP
$FF08: 00        NOP
$FF09: 00        NOP
$FF0A: 00        NOP
$FF0B: 00        NOP
$FF0C: 00        NOP
$FF0D: 00        NOP
$FF0E: 47        LD B,A
$FF0F: 21 CD FE  LD HL,FECD
$FF12: 7E        LD A,(HL)
$FF13: 5F        LD E,A
$FF14: B7        OR A
$FF15: 20 12     JR NZ,FF29
$FF17: 3A 97 F3  LD A,(F397)
$FF1A: B7        OR A
$FF1B: 28 06     JR Z,FF23
$FF1D: B9        CP C
$FF1E: 20 03     JR NZ,FF23
$FF20: 36 80     LD (HL),80
$FF22: C9        RET
$FF23: 3E 1F     LD A,1F
$FF25: B9        CP C
$FF26: DA A4 FC  JP C,FCA4
$FF29: 21 A0 F3  LD HL,F3A0
$FF2C: 06 09     LD B,09
$FF2E: 7E        LD A,(HL)
$FF2F: B7        OR A
$FF30: 28 04     JR Z,FF36
$FF32: AB        XOR E
$FF33: B9        CP C
$FF34: 28 05     JR Z,FF3B
$FF36: 2B        DEC HL
$FF37: 10 F5     DJNZ FF2E
$FF39: 18 21     JR FF5C
$FF3B: 11 0B 00  LD DE,000B
$FF3E: 19        ADD HL,DE
$FF3F: 7E        LD A,(HL)
$FF40: B7        OR A
$FF41: 4F        LD C,A
$FF42: F2 9A FC  JP P,FC9A
$FF45: E6 7F     AND 7F
$FF47: 4F        LD C,A
$FF48: C5        PUSH BC
$FF49: 3A A2 F3  LD A,(F3A2)
$FF4C: 06 07     LD B,07
$FF4E: CD F0 FB  CALL FBF0
$FF51: C1        POP BC
$FF52: 78        LD A,B
$FF53: FE 07     CP 07
$FF55: 20 05     JR NZ,FF5C
$FF57: 3E 02     LD A,02
$FF59: 32 CC FE  LD (FECC),A
$FF5C: AF        XOR A
$FF5D: 32 CD FE  LD (FECD),A
$FF60: 3A CB FE  LD A,(FECB)
$FF63: B7        OR A
$FF64: 2A 88 F3  LD HL,(F388)
$FF67: 28 03     JR Z,FF6C
$FF69: 2A 86 F3  LD HL,(F386)
$FF6C: E9        JP (HL)
$FF6D: 11 03 00  LD DE,0003
$FF70: C3 BB FC  JP FCBB
$FF73: 2A CE FE  LD HL,(FECE)
$FF76: 3A D0 FE  LD A,(FED0)
$FF79: 77        LD (HL),A
$FF7A: CD E2 FC  CALL FCE2
$FF7D: 2A 28 F0  LD HL,(F028)
$FF80: 3A 24 F0  LD A,(F024)
$FF83: 5F        LD E,A
$FF84: 16 F0     LD D,F0
$FF86: 19        ADD HL,DE
$FF87: 22 CE FE  LD (FECE),HL
$FF8A: 7E        LD A,(HL)
$FF8B: 32 D0 FE  LD (FED0),A
$FF8E: FE E0     CP E0
$FF90: 38 02     JR C,FF94
$FF92: EE 20     XOR 20
$FF94: E6 3F     AND 3F
$FF96: F6 40     OR 40
$FF98: 77        LD (HL),A
$FF99: C9        RET
$FF9A: 78        LD A,B
$FF9B: B7        OR A
$FF9C: 28 0B     JR Z,FFA9
$FF9E: 21 45 FB  LD HL,FB45
$FFA1: E5        PUSH HL
$FFA2: 21 66 FD  LD HL,FD66
$FFA5: 85        ADD A,L
$FFA6: 6F        LD L,A
$FFA7: 6E        LD L,(HL)
$FFA8: E9        JP (HL)
$FFA9: 79        LD A,C
$FFAA: FE 0D     CP 0D
$FFAC: 20 05     JR NZ,FFB3
$FFAE: AF        XOR A
$FFAF: 32 24 F0  LD (F024),A
$FFB2: C9        RET
$FFB3: F6 80     OR 80
$FFB5: FE E0     CP E0
$FFB7: 38 FF     JR C,FFB8
$FFB9: FF        RST $38
$FFBA: 00        NOP
$FFBB: 00        NOP
$FFBC: FF        RST $38
$FFBD: FF        RST $38
$FFBE: 00        NOP
$FFBF: 00        NOP
$FFC0: FF        RST $38
$FFC1: FF        RST $38
$FFC2: 00        NOP
$FFC3: 00        NOP
$FFC4: FF        RST $38
$FFC5: FF        RST $38
$FFC6: 00        NOP
$FFC7: 00        NOP
$FFC8: FF        RST $38
$FFC9: FF        RST $38
$FFCA: 00        NOP
$FFCB: 00        NOP
$FFCC: FF        RST $38
$FFCD: FF        RST $38
$FFCE: 00        NOP
$FFCF: 00        NOP
$FFD0: FF        RST $38
$FFD1: FF        RST $38
$FFD2: 00        NOP
$FFD3: 00        NOP
$FFD4: FF        RST $38
$FFD5: FF        RST $38
$FFD6: 00        NOP
$FFD7: 00        NOP
$FFD8: FF        RST $38
$FFD9: FF        RST $38
$FFDA: 00        NOP
$FFDB: 00        NOP
$FFDC: FF        RST $38
$FFDD: FF        RST $38
$FFDE: 00        NOP
$FFDF: 00        NOP
$FFE0: FF        RST $38
$FFE1: FF        RST $38
$FFE2: 00        NOP
$FFE3: 00        NOP
$FFE4: FF        RST $38
$FFE5: FF        RST $38
$FFE6: 00        NOP
$FFE7: 00        NOP
$FFE8: FF        RST $38
$FFE9: FF        RST $38
$FFEA: 00        NOP
$FFEB: 00        NOP
$FFEC: FF        RST $38
$FFED: FF        RST $38
$FFEE: 00        NOP
$FFEF: 00        NOP
$FFF0: FF        RST $38
$FFF1: FF        RST $38
$FFF2: 00        NOP
$FFF3: 00        NOP
$FFF4: FF        RST $38
$FFF5: FF        RST $38
$FFF6: 00        NOP
$FFF7: 00        NOP
$FFF8: FF        RST $38
$FFF9: FF        RST $38
$FFFA: 00        NOP
$FFFB: 00        NOP
$FFFC: FF        RST $38
$FFFD: FF        RST $38
$FFFE: 00        NOP


; ============================================================================
; END OF BIOS ($FFFF)
;
; Z-80 reset vector at $0000 was planted by the 6502 as "JP $FA00".
; $FA00 is below this BIOS (in another runtime-generated region 184
; bytes long). Cold-boot setup at $FB70 rewrites $0001-$0002 to
; "JP $FA03" so subsequent warm-boots skip the cold-only first
; instruction.
;
; The cold-boot setup also plants the standard CP/M BDOS call vector:
;   $0005: $C3 (JP opcode)
;   $0006-$0007: $9C06 (BDOS entry after relocation)
; This is what user programs call via "CALL $0005" to reach BDOS.
; ============================================================================
