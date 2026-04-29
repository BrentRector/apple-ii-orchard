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
          JP $FED1                        ; $FAB8 C3 D1 FE
          JP $FAB8                        ; $FABB C3 B8 FA
          JP $FB10                        ; $FABE C3 10 FB
          JP $FB1A                        ; $FAC1 C3 1A FB
          JP $FB4D                        ; $FAC4 C3 4D FB
          JP $FB70                        ; $FAC7 C3 70 FB
          JP $FB7F                        ; $FACA C3 7F FB
          JP $FB91                        ; $FACD C3 91 FB
          JP $FE6C                        ; $FAD0 C3 6C FE
          JP $FE8E                        ; $FAD3 C3 8E FE
          JP $FE77                        ; $FAD6 C3 77 FE
          JP $FBF4                        ; $FAD9 C3 F4 FB
          JP $FBF9                        ; $FADC C3 F9 FB
          JP $FEBD                        ; $FADF C3 BD FE
          JP $FEC0                        ; $FAE2 C3 C0 FE
          XOR A                           ; $FAE5 AF
          RET                             ; $FAE6 C9
          NOP                             ; $FAE7 00
          LD H,B                          ; $FAE8 60
          LD L,C                          ; $FAE9 69
          RET                             ; $FAEA C9
          NOP                             ; $FAEB 00
          NOP                             ; $FAEC 00
          NOP                             ; $FAED 00
          NOP                             ; $FAEE 00
          NOP                             ; $FAEF 00
          NOP                             ; $FAF0 00
          NOP                             ; $FAF1 00
          NOP                             ; $FAF2 00
          CALL PO,$73FE                   ; $FAF3 E4 FE 73
          JP M,$FFAC                      ; $FAF6 FA AC FF
          LD H,H                          ; $FAF9 64
          RST $38                         ; $FAFA FF
          NOP                             ; $FAFB 00
          NOP                             ; $FAFC 00
          NOP                             ; $FAFD 00
          NOP                             ; $FAFE 00
          NOP                             ; $FAFF 00
          NOP                             ; $FB00 00
          NOP                             ; $FB01 00
          NOP                             ; $FB02 00
          CALL PO,$73FE                   ; $FB03 E4 FE 73
          JP M,$FFB8                      ; $FB06 FA B8 FF
          HALT                            ; $FB09 76
          RST $38                         ; $FB0A FF
          NOP                             ; $FB0B 00
          NOP                             ; $FB0C 00
          NOP                             ; $FB0D 00
          NOP                             ; $FB0E 00
          NOP                             ; $FB0F 00
          NOP                             ; $FB10 00
          NOP                             ; $FB11 00
          NOP                             ; $FB12 00
          CALL PO,$73FE                   ; $FB13 E4 FE 73
          JP M,$FFC4                      ; $FB16 FA C4 FF
          ADC A,B                         ; $FB19 88
          RST $38                         ; $FB1A FF
          NOP                             ; $FB1B 00
          NOP                             ; $FB1C 00
          NOP                             ; $FB1D 00
          NOP                             ; $FB1E 00
          NOP                             ; $FB1F 00
          NOP                             ; $FB20 00
          NOP                             ; $FB21 00
          NOP                             ; $FB22 00
          CALL PO,$73FE                   ; $FB23 E4 FE 73
          JP M,$FFD0                      ; $FB26 FA D0 FF
          SBC A,D                         ; $FB29 9A
          RST $38                         ; $FB2A FF
          JR NZ,$FB2D                     ; $FB2B 20 00
          INC BC                          ; $FB2D 03
          RLCA                            ; $FB2E 07
          NOP                             ; $FB2F 00
          ADC A,E                         ; $FB30 8B
          NOP                             ; $FB31 00
          CPL                             ; $FB32 2F
          NOP                             ; $FB33 00
          RET NZ                          ; $FB34 C0
          NOP                             ; $FB35 00
          INC C                           ; $FB36 0C
          NOP                             ; $FB37 00
          INC BC                          ; $FB38 03
          NOP                             ; $FB39 00
          LD DE,$0007                     ; $FB3A 11 07 00
          LD HL,$F3B8                     ; $FB3D 21 B8 F3
          ADD HL,DE                       ; $FB40 19
          LD A,(HL)                       ; $FB41 7E
          SUB $03                         ; $FB42 D6 03
          JR NZ,$FB4D                     ; $FB44 20 07
          CALL $FE81                      ; $FB46 CD 81 FE
          LD (HL),$03                     ; $FB49 36 03
          LD (HL),$15                     ; $FB4B 36 15
          DEC A                           ; $FB4D 3D
          JR NZ,$FB5B                     ; $FB4E 20 0B
          CALL $FD83                      ; $FB50 CD 83 FD
          LD HL,$C800                     ; $FB53 21 00 C8
          CALL $FB45                      ; $FB56 CD 45 FB
          JR $FB65                        ; $FB59 18 0A
          CP $02                          ; $FB5B FE 02
          JR NZ,$FB65                     ; $FB5D 20 06
          LD HL,$0DD0                     ; $FB5F 21 D0 0D
          CALL $FDB0                      ; $FB62 CD B0 FD
          DEC E                           ; $FB65 1D
          JR NZ,$FB3D                     ; $FB66 20 D5
          RET                             ; $FB68 C9
          LD HL,$E000                     ; $FB69 21 00 E0
          LD A,E                          ; $FB6C 7B
          OR H                            ; $FB6D B4
          LD H,A                          ; $FB6E 67
          RET                             ; $FB6F C9
          LD SP,$0080                     ; $FB70 31 80 00
          LD A,($E051)                    ; $FB73 3A 51 E0
          LD HL,$0E00                     ; $FB76 21 00 0E
          CALL $FB45                      ; $FB79 CD 45 FB
          CALL $FA82                      ; $FB7C CD 82 FA
          LD A,($9C08)                    ; $FB7F 3A 08 9C
          CP $9C                          ; $FB82 FE 9C
          JR Z,$FB97                      ; $FB84 28 11
          LD HL,$FF59                     ; $FB86 21 59 FF
          LD ($F3D0),HL                   ; $FB89 22 D0 F3
          LD HL,($F3DE)                   ; $FB8C 2A DE F3
          LD A,$77                        ; $FB8F 3E 77
          LD ($000B),A                    ; $FB91 32 0B 00
          JP $000B                        ; $FB94 C3 0B 00
          XOR A                           ; $FB97 AF
          LD ($9307),A                    ; $FB98 32 07 93
          XOR A                           ; $FB9B AF
          LD ($FEDD),A                    ; $FB9C 32 DD FE
          LD ($FED8),A                    ; $FB9F 32 D8 FE
          LD A,$C3                        ; $FBA2 3E C3
          LD ($0000),A                    ; $FBA4 32 00 00
          LD HL,$FA03                     ; $FBA7 21 03 FA
          LD ($0001),HL                   ; $FBAA 22 01 00
          LD ($0005),A                    ; $FBAD 32 05 00
          LD HL,$9C06                     ; $FBB0 21 06 9C
          LD ($0006),HL                   ; $FBB3 22 06 00
          LD BC,$FF80                     ; $FBB6 01 80 FF
          RST $38                         ; $FBB9 FF
          NOP                             ; $FBBA 00
          NOP                             ; $FBBB 00
          RST $38                         ; $FBBC FF
          RST $38                         ; $FBBD FF
          NOP                             ; $FBBE 00
          NOP                             ; $FBBF 00
          RST $38                         ; $FBC0 FF
          RST $38                         ; $FBC1 FF
          NOP                             ; $FBC2 00
          NOP                             ; $FBC3 00
          RST $38                         ; $FBC4 FF
          RST $38                         ; $FBC5 FF
          NOP                             ; $FBC6 00
          NOP                             ; $FBC7 00
          RST $30                         ; $FBC8 F7
          RST $30                         ; $FBC9 F7
          NOP                             ; $FBCA 00
          NOP                             ; $FBCB 00
          RST $30                         ; $FBCC F7
          RST $30                         ; $FBCD F7
          NOP                             ; $FBCE 00
          NOP                             ; $FBCF 00
          RST $30                         ; $FBD0 F7
          RST $30                         ; $FBD1 F7
          NOP                             ; $FBD2 00
          NOP                             ; $FBD3 00
          RST $30                         ; $FBD4 F7
          RST $30                         ; $FBD5 F7
          NOP                             ; $FBD6 00
          NOP                             ; $FBD7 00
          RST $38                         ; $FBD8 FF
          RST $38                         ; $FBD9 FF
          NOP                             ; $FBDA 00
          NOP                             ; $FBDB 00
          RST $38                         ; $FBDC FF
          RST $38                         ; $FBDD FF
          NOP                             ; $FBDE 00
          NOP                             ; $FBDF 00
          RST $38                         ; $FBE0 FF
          RST $38                         ; $FBE1 FF
          NOP                             ; $FBE2 00
          NOP                             ; $FBE3 00
          RST $38                         ; $FBE4 FF
          RST $38                         ; $FBE5 FF
          NOP                             ; $FBE6 00
          NOP                             ; $FBE7 00
          RST $38                         ; $FBE8 FF
          RST $38                         ; $FBE9 FF
          NOP                             ; $FBEA 00
          NOP                             ; $FBEB 00
          RST $38                         ; $FBEC FF
          RST $38                         ; $FBED FF
          NOP                             ; $FBEE 00
          NOP                             ; $FBEF 00
          RST $38                         ; $FBF0 FF
          RST $38                         ; $FBF1 FF
          NOP                             ; $FBF2 00
          NOP                             ; $FBF3 00
          RST $38                         ; $FBF4 FF
          RST $38                         ; $FBF5 FF
          NOP                             ; $FBF6 00
          NOP                             ; $FBF7 00
          RST $38                         ; $FBF8 FF
          RST $38                         ; $FBF9 FF
          NOP                             ; $FBFA 00
          NOP                             ; $FBFB 00
          RST $38                         ; $FBFC FF
          RST $38                         ; $FBFD FF
          NOP                             ; $FBFE 00
          NOP                             ; $FBFF 00
          RST $38                         ; $FC00 FF
          RST $38                         ; $FC01 FF
          NOP                             ; $FC02 00
          NOP                             ; $FC03 00
          RST $38                         ; $FC04 FF
          RST $38                         ; $FC05 FF
          NOP                             ; $FC06 00
          NOP                             ; $FC07 00
          RST $38                         ; $FC08 FF
          RST $38                         ; $FC09 FF
          NOP                             ; $FC0A 00
          NOP                             ; $FC0B 00
          RST $38                         ; $FC0C FF
          RST $38                         ; $FC0D FF
          NOP                             ; $FC0E 00
          NOP                             ; $FC0F 00
          RST $38                         ; $FC10 FF
          RST $38                         ; $FC11 FF
          NOP                             ; $FC12 00
          NOP                             ; $FC13 00
          RST $38                         ; $FC14 FF
          RST $38                         ; $FC15 FF
          NOP                             ; $FC16 00
          NOP                             ; $FC17 00
          RST $38                         ; $FC18 FF
          RST $38                         ; $FC19 FF
          NOP                             ; $FC1A 00
          NOP                             ; $FC1B 00
          RST $38                         ; $FC1C FF
          RST $38                         ; $FC1D FF
          NOP                             ; $FC1E 00
          NOP                             ; $FC1F 00
          RST $38                         ; $FC20 FF
          RST $38                         ; $FC21 FF
          NOP                             ; $FC22 00
          NOP                             ; $FC23 00
          RST $38                         ; $FC24 FF
          RST $38                         ; $FC25 FF
          NOP                             ; $FC26 00
          NOP                             ; $FC27 00
          RST $30                         ; $FC28 F7
          RST $30                         ; $FC29 F7
          NOP                             ; $FC2A 00
          NOP                             ; $FC2B 00
          RST $30                         ; $FC2C F7
          RST $30                         ; $FC2D F7
          NOP                             ; $FC2E 00
          NOP                             ; $FC2F 00
          RST $30                         ; $FC30 F7
          RST $30                         ; $FC31 F7
          NOP                             ; $FC32 00
          NOP                             ; $FC33 00
          RST $30                         ; $FC34 F7
          RST $30                         ; $FC35 F7
          NOP                             ; $FC36 00
          NOP                             ; $FC37 00
          RST $38                         ; $FC38 FF
          RST $38                         ; $FC39 FF
          NOP                             ; $FC3A 00
          NOP                             ; $FC3B 00
          RST $38                         ; $FC3C FF
          RST $38                         ; $FC3D FF
          NOP                             ; $FC3E 00
          NOP                             ; $FC3F 00
          RST $38                         ; $FC40 FF
          RST $38                         ; $FC41 FF
          NOP                             ; $FC42 00
          NOP                             ; $FC43 00
          RST $38                         ; $FC44 FF
          RST $38                         ; $FC45 FF
          NOP                             ; $FC46 00
          NOP                             ; $FC47 00
          RST $38                         ; $FC48 FF
          RST $38                         ; $FC49 FF
          NOP                             ; $FC4A 00
          NOP                             ; $FC4B 00
          RST $38                         ; $FC4C FF
          RST $38                         ; $FC4D FF
          NOP                             ; $FC4E 00
          NOP                             ; $FC4F 00
          RST $38                         ; $FC50 FF
          RST $38                         ; $FC51 FF
          NOP                             ; $FC52 00
          NOP                             ; $FC53 00
          RST $38                         ; $FC54 FF
          RST $38                         ; $FC55 FF
          NOP                             ; $FC56 00
          NOP                             ; $FC57 00
          RST $38                         ; $FC58 FF
          RST $38                         ; $FC59 FF
          NOP                             ; $FC5A 00
          NOP                             ; $FC5B 00
          RST $38                         ; $FC5C FF
          RST $38                         ; $FC5D FF
          NOP                             ; $FC5E 00
          NOP                             ; $FC5F 00
          RST $38                         ; $FC60 FF
          RST $38                         ; $FC61 FF
          NOP                             ; $FC62 00
          NOP                             ; $FC63 00
          RST $38                         ; $FC64 FF
          RST $38                         ; $FC65 FF
          NOP                             ; $FC66 00
          NOP                             ; $FC67 00
          RST $38                         ; $FC68 FF
          RST $38                         ; $FC69 FF
          NOP                             ; $FC6A 00
          NOP                             ; $FC6B 00
          RST $38                         ; $FC6C FF
          RST $38                         ; $FC6D FF
          NOP                             ; $FC6E 00
          NOP                             ; $FC6F 00
          RST $38                         ; $FC70 FF
          RST $38                         ; $FC71 FF
          NOP                             ; $FC72 00
          NOP                             ; $FC73 00
          RST $38                         ; $FC74 FF
          RST $38                         ; $FC75 FF
          NOP                             ; $FC76 00
          NOP                             ; $FC77 00
          RST $38                         ; $FC78 FF
          RST $38                         ; $FC79 FF
          NOP                             ; $FC7A 00
          NOP                             ; $FC7B 00
          RST $38                         ; $FC7C FF
          RST $38                         ; $FC7D FF
          NOP                             ; $FC7E 00
          NOP                             ; $FC7F 00
          RST $38                         ; $FC80 FF
          RST $38                         ; $FC81 FF
          NOP                             ; $FC82 00
          NOP                             ; $FC83 00
          RST $38                         ; $FC84 FF
          RST $38                         ; $FC85 FF
          NOP                             ; $FC86 00
          NOP                             ; $FC87 00
          RST $38                         ; $FC88 FF
          RST $38                         ; $FC89 FF
          NOP                             ; $FC8A 00
          NOP                             ; $FC8B 00
          RST $38                         ; $FC8C FF
          RST $38                         ; $FC8D FF
          NOP                             ; $FC8E 00
          NOP                             ; $FC8F 00
          RST $38                         ; $FC90 FF
          RST $38                         ; $FC91 FF
          NOP                             ; $FC92 00
          NOP                             ; $FC93 00
          RST $38                         ; $FC94 FF
          RST $38                         ; $FC95 FF
          NOP                             ; $FC96 00
          NOP                             ; $FC97 00
          RST $38                         ; $FC98 FF
          RST $38                         ; $FC99 FF
          NOP                             ; $FC9A 00
          NOP                             ; $FC9B 00
          RST $38                         ; $FC9C FF
          RST $38                         ; $FC9D FF
          NOP                             ; $FC9E 00
          NOP                             ; $FC9F 00
          RST $38                         ; $FCA0 FF
          RST $38                         ; $FCA1 FF
          NOP                             ; $FCA2 00
          NOP                             ; $FCA3 00
          RST $38                         ; $FCA4 FF
          RST $38                         ; $FCA5 FF
          NOP                             ; $FCA6 00
          NOP                             ; $FCA7 00
          RST $30                         ; $FCA8 F7
          RST $38                         ; $FCA9 FF
          NOP                             ; $FCAA 00
          NOP                             ; $FCAB 00
          RST $38                         ; $FCAC FF
          RST $38                         ; $FCAD FF
          NOP                             ; $FCAE 00
          NOP                             ; $FCAF 00
          RST $38                         ; $FCB0 FF
          RST $38                         ; $FCB1 FF
          NOP                             ; $FCB2 00
          NOP                             ; $FCB3 00
          RST $38                         ; $FCB4 FF
          RST $38                         ; $FCB5 FF
          NOP                             ; $FCB6 00
          NOP                             ; $FCB7 00
          NOP                             ; $FCB8 00
          CALL $FBF9                      ; $FCB9 CD F9 FB
          LD A,$01                        ; $FCBC 3E 01
          LD ($974E),A                    ; $FCBE 32 4E 97
          LD A,($0004)                    ; $FCC1 3A 04 00
          LD C,A                          ; $FCC4 4F
          JP $9300                        ; $FCC5 C3 00 93
          LD HL,($F380)                   ; $FCC8 2A 80 F3
          JP (HL)                         ; $FCCB E9
          LD A,($E000)                    ; $FCCC 3A 00 E0
          RLA                             ; $FCCF 17
          SBC A,A                         ; $FCD0 9F
          RET                             ; $FCD1 C9
          CALL $FB5A                      ; $FCD2 CD 5A FB
          AND $7F                         ; $FCD5 E6 7F
          LD HL,$F3AB                     ; $FCD7 21 AB F3
          LD B,$06                        ; $FCDA 06 06
          LD C,A                          ; $FCDC 4F
          INC HL                          ; $FCDD 23
          LD A,(HL)                       ; $FCDE 7E
          INC HL                          ; $FCDF 23
          OR A                            ; $FCE0 B7
          JP M,$FB31                      ; $FCE1 FA 31 FB
          CP C                            ; $FCE4 B9
          LD A,(HL)                       ; $FCE5 7E
          RET Z                           ; $FCE6 C8
          DJNZ $FCDD                      ; $FCE7 10 F4
          LD A,C                          ; $FCE9 79
          RET                             ; $FCEA C9
          LD DE,$0003                     ; $FCEB 11 03 00
          JP $FB39                        ; $FCEE C3 39 FB
          LD A,($E000)                    ; $FCF1 3A 00 E0
          RLA                             ; $FCF4 17
          JR NC,$FCF1                     ; $FCF5 30 FA
          LD ($E010),A                    ; $FCF7 32 10 E0
          CCF                             ; $FCFA 3F
          RRA                             ; $FCFB 1F
          RET                             ; $FCFC C9
          LD ($F3D0),HL                   ; $FCFD 22 D0 F3
          LD ($0000),A                    ; $FD00 32 00 00
          RET                             ; $FD03 C9
          LD C,A                          ; $FD04 4F
          LD A,($0003)                    ; $FD05 3A 03 00
          AND $03                         ; $FD08 E6 03
          CP $02                          ; $FD0A FE 02
          JR NZ,$FD59                     ; $FD0C 20 4B
          LD HL,($F392)                   ; $FD0E 2A 92 F3
          JP (HL)                         ; $FD11 E9
          LD A,($0003)                    ; $FD12 3A 03 00
          AND $03                         ; $FD15 E6 03
          CP $02                          ; $FD17 FE 02
          LD HL,($F384)                   ; $FD19 2A 84 F3
          JR Z,$FD24                      ; $FD1C 28 06
          JR NC,$FD27                     ; $FD1E 30 07
          LD HL,($F382)                   ; $FD20 2A 82 F3
          JP (HL)                         ; $FD23 E9
          LD HL,($F38A)                   ; $FD24 2A 8A F3
          JP (HL)                         ; $FD27 E9
          LD A,($0003)                    ; $FD28 3A 03 00
          AND $C0                         ; $FD2B E6 C0
          CP $80                          ; $FD2D FE 80
          JR C,$FD58                      ; $FD2F 38 27
          JR Z,$FD0E                      ; $FD31 28 DB
          LD HL,($F394)                   ; $FD33 2A 94 F3
          JP (HL)                         ; $FD36 E9
          LD A,($0003)                    ; $FD37 3A 03 00
          AND $30                         ; $FD3A E6 30
          CP $10                          ; $FD3C FE 10
          JR C,$FD58                      ; $FD3E 38 18
          LD HL,($F38E)                   ; $FD40 2A 8E F3
          JR Z,$FD27                      ; $FD43 28 E2
          LD HL,($F390)                   ; $FD45 2A 90 F3
          JP (HL)                         ; $FD48 E9
          LD A,($0003)                    ; $FD49 3A 03 00
          AND $0C                         ; $FD4C E6 0C
          CP $08                          ; $FD4E FE 08
          JR C,$FD20                      ; $FD50 38 CE
          JR Z,$FD24                      ; $FD52 28 D0
          LD HL,($F38C)                   ; $FD54 2A 8C F3
          JP (HL)                         ; $FD57 E9
          SCF                             ; $FD58 37
          SBC A,A                         ; $FD59 9F
          LD HL,$F3A2                     ; $FD5A 21 A2 F3
          LD L,(HL)                       ; $FD5D 6E
          INC L                           ; $FD5E 2C
          JP Z,$FCA4                      ; $FD5F CA A4 FC
          LD HL,$FECB                     ; $FD62 21 CB FE
          LD (HL),A                       ; $FD65 77
          DB $CB                          ; $FD66 CB
          CP C                            ; $FD67 B9
          INC HL                          ; $FD68 23
          LD A,(HL)                       ; $FD69 7E
          OR A                            ; $FD6A B7
          JP Z,$FC56                      ; $FD6B CA 56 FC
          DEC (HL)                        ; $FD6E 35
          LD A,($F396)                    ; $FD6F 3A 96 F3
          LD HL,$FED4                     ; $FD72 21 D4 FE
          JR Z,$FD83                      ; $FD75 28 0C
          OR A                            ; $FD77 B7
          JP P,$FBC6                      ; $FD78 F2 C6 FB
          DEC HL                          ; $FD7B 2B
          AND $7F                         ; $FD7C E6 7F
          LD E,A                          ; $FD7E 5F
          LD A,C                          ; $FD7F 79
          SUB E                           ; $FD80 93
          LD (HL),A                       ; $FD81 77
          RET                             ; $FD82 C9
          OR A                            ; $FD83 B7
          JP M,$FBD0                      ; $FD84 FA D0 FB
          DEC HL                          ; $FD87 2B
          CALL $FBC4                      ; $FD88 CD C4 FB
          LD HL,($FED3)                   ; $FD8B 2A D3 FE
          LD A,($F3A1)                    ; $FD8E 3A A1 F3
          OR A                            ; $FD91 B7
          JP P,$FBE2                      ; $FD92 F2 E2 FB
          AND $7F                         ; $FD95 E6 7F
          LD E,L                          ; $FD97 5D
          LD L,H                          ; $FD98 6C
          LD H,E                          ; $FD99 63
          LD E,A                          ; $FD9A 5F
          ADD A,H                         ; $FD9B 84
          LD C,A                          ; $FD9C 4F
          LD A,E                          ; $FD9D 7B
          ADD A,L                         ; $FD9E 85
          PUSH AF                         ; $FD9F F5
          LD B,$07                        ; $FDA0 06 07
          CALL $FCA4                      ; $FDA2 CD A4 FC
          POP AF                          ; $FDA5 F1
          LD B,$0A                        ; $FDA6 06 0A
          LD C,A                          ; $FDA8 4F
          JP $FCA4                        ; $FDA9 C3 A4 FC
          LD A,C                          ; $FDAC 79
          LD ($FED2),A                    ; $FDAD 32 D2 FE
          RET                             ; $FDB0 C9
          DB $ED                          ; $FDB1 ED
          LD B,E                          ; $FDB2 43
          POP HL                          ; $FDB3 E1
          CP $C9                          ; $FDB4 FE C9
          NOP                             ; $FDB6 00
          NOP                             ; $FDB7 00
          RST $38                         ; $FDB8 FF
          RST $38                         ; $FDB9 FF
          NOP                             ; $FDBA 00
          NOP                             ; $FDBB 00
          RST $38                         ; $FDBC FF
          RST $38                         ; $FDBD FF
          NOP                             ; $FDBE 00
          NOP                             ; $FDBF 00
          RST $38                         ; $FDC0 FF
          RST $38                         ; $FDC1 FF
          NOP                             ; $FDC2 00
          NOP                             ; $FDC3 00
          RST $38                         ; $FDC4 FF
          RST $38                         ; $FDC5 FF
          NOP                             ; $FDC6 00
          NOP                             ; $FDC7 00
          RST $30                         ; $FDC8 F7
          RST $30                         ; $FDC9 F7
          NOP                             ; $FDCA 00
          NOP                             ; $FDCB 00
          RST $30                         ; $FDCC F7
          RST $30                         ; $FDCD F7
          NOP                             ; $FDCE 00
          NOP                             ; $FDCF 00
          RST $30                         ; $FDD0 F7
          RST $30                         ; $FDD1 F7
          NOP                             ; $FDD2 00
          NOP                             ; $FDD3 00
          RST $30                         ; $FDD4 F7
          RST $30                         ; $FDD5 F7
          DJNZ $FDD8                      ; $FDD6 10 00
          RST $38                         ; $FDD8 FF
          RST $38                         ; $FDD9 FF
          NOP                             ; $FDDA 00
          NOP                             ; $FDDB 00
          RST $38                         ; $FDDC FF
          RST $38                         ; $FDDD FF
          NOP                             ; $FDDE 00
          NOP                             ; $FDDF 00
          RST $38                         ; $FDE0 FF
          RST $38                         ; $FDE1 FF
          NOP                             ; $FDE2 00
          NOP                             ; $FDE3 00
          RST $38                         ; $FDE4 FF
          RST $38                         ; $FDE5 FF
          NOP                             ; $FDE6 00
          NOP                             ; $FDE7 00
          RST $38                         ; $FDE8 FF
          RST $38                         ; $FDE9 FF
          NOP                             ; $FDEA 00
          NOP                             ; $FDEB 00
          RST $38                         ; $FDEC FF
          RST $38                         ; $FDED FF
          NOP                             ; $FDEE 00
          NOP                             ; $FDEF 00
          RST $38                         ; $FDF0 FF
          RST $38                         ; $FDF1 FF
          NOP                             ; $FDF2 00
          NOP                             ; $FDF3 00
          RST $38                         ; $FDF4 FF
          RST $38                         ; $FDF5 FF
          NOP                             ; $FDF6 00
          NOP                             ; $FDF7 00
          RST $38                         ; $FDF8 FF
          RST $38                         ; $FDF9 FF
          NOP                             ; $FDFA 00
          NOP                             ; $FDFB 00
          RST $38                         ; $FDFC FF
          RST $38                         ; $FDFD FF
          NOP                             ; $FDFE 00
          NOP                             ; $FDFF 00
          RST $38                         ; $FE00 FF
          RST $38                         ; $FE01 FF
          NOP                             ; $FE02 00
          NOP                             ; $FE03 00
          RST $38                         ; $FE04 FF
          RST $38                         ; $FE05 FF
          NOP                             ; $FE06 00
          NOP                             ; $FE07 00
          RST $38                         ; $FE08 FF
          RST $38                         ; $FE09 FF
          NOP                             ; $FE0A 00
          NOP                             ; $FE0B 00
          RST $38                         ; $FE0C FF
          RST $38                         ; $FE0D FF
          NOP                             ; $FE0E 00
          NOP                             ; $FE0F 00
          RST $38                         ; $FE10 FF
          RST $38                         ; $FE11 FF
          NOP                             ; $FE12 00
          NOP                             ; $FE13 00
          RST $38                         ; $FE14 FF
          RST $38                         ; $FE15 FF
          NOP                             ; $FE16 00
          NOP                             ; $FE17 00
          RST $38                         ; $FE18 FF
          RST $38                         ; $FE19 FF
          NOP                             ; $FE1A 00
          NOP                             ; $FE1B 00
          RST $38                         ; $FE1C FF
          RST $38                         ; $FE1D FF
          NOP                             ; $FE1E 00
          NOP                             ; $FE1F 00
          RST $38                         ; $FE20 FF
          RST $38                         ; $FE21 FF
          NOP                             ; $FE22 00
          NOP                             ; $FE23 00
          RST $38                         ; $FE24 FF
          RST $38                         ; $FE25 FF
          DJNZ $FE28                      ; $FE26 10 00
          RST $30                         ; $FE28 F7
          RST $30                         ; $FE29 F7
          NOP                             ; $FE2A 00
          NOP                             ; $FE2B 00
          RST $30                         ; $FE2C F7
          RST $30                         ; $FE2D F7
          NOP                             ; $FE2E 00
          NOP                             ; $FE2F 00
          RST $30                         ; $FE30 F7
          RST $30                         ; $FE31 F7
          NOP                             ; $FE32 00
          NOP                             ; $FE33 00
          RST $30                         ; $FE34 F7
          RST $30                         ; $FE35 F7
          NOP                             ; $FE36 00
          NOP                             ; $FE37 00
          RST $38                         ; $FE38 FF
          RST $38                         ; $FE39 FF
          NOP                             ; $FE3A 00
          NOP                             ; $FE3B 00
          RST $38                         ; $FE3C FF
          RST $38                         ; $FE3D FF
          NOP                             ; $FE3E 00
          NOP                             ; $FE3F 00
          RST $38                         ; $FE40 FF
          RST $38                         ; $FE41 FF
          NOP                             ; $FE42 00
          NOP                             ; $FE43 00
          RST $38                         ; $FE44 FF
          RST $38                         ; $FE45 FF
          NOP                             ; $FE46 00
          NOP                             ; $FE47 00
          RST $30                         ; $FE48 F7
          RST $30                         ; $FE49 F7
          NOP                             ; $FE4A 00
          NOP                             ; $FE4B 00
          RST $30                         ; $FE4C F7
          RST $30                         ; $FE4D F7
          NOP                             ; $FE4E 00
          NOP                             ; $FE4F 00
          RST $30                         ; $FE50 F7
          RST $30                         ; $FE51 F7
          NOP                             ; $FE52 00
          NOP                             ; $FE53 00
          RST $38                         ; $FE54 FF
          RST $30                         ; $FE55 F7
          NOP                             ; $FE56 00
          NOP                             ; $FE57 00
          RST $38                         ; $FE58 FF
          RST $38                         ; $FE59 FF
          NOP                             ; $FE5A 00
          NOP                             ; $FE5B 00
          RST $38                         ; $FE5C FF
          RST $38                         ; $FE5D FF
          NOP                             ; $FE5E 00
          NOP                             ; $FE5F 00
          RST $38                         ; $FE60 FF
          RST $38                         ; $FE61 FF
          NOP                             ; $FE62 00
          NOP                             ; $FE63 00
          RST $38                         ; $FE64 FF
          RST $38                         ; $FE65 FF
          NOP                             ; $FE66 00
          NOP                             ; $FE67 00
          RST $38                         ; $FE68 FF
          RST $38                         ; $FE69 FF
          NOP                             ; $FE6A 00
          NOP                             ; $FE6B 00
          RST $38                         ; $FE6C FF
          RST $38                         ; $FE6D FF
          NOP                             ; $FE6E 00
          NOP                             ; $FE6F 00
          RST $38                         ; $FE70 FF
          RST $38                         ; $FE71 FF
          NOP                             ; $FE72 00
          NOP                             ; $FE73 00
          RST $38                         ; $FE74 FF
          RST $38                         ; $FE75 FF
          NOP                             ; $FE76 00
          NOP                             ; $FE77 00
          RST $38                         ; $FE78 FF
          RST $38                         ; $FE79 FF
          NOP                             ; $FE7A 00
          NOP                             ; $FE7B 00
          RST $38                         ; $FE7C FF
          RST $38                         ; $FE7D FF
          NOP                             ; $FE7E 00
          NOP                             ; $FE7F 00
          RST $38                         ; $FE80 FF
          RST $38                         ; $FE81 FF
          NOP                             ; $FE82 00
          NOP                             ; $FE83 00
          RST $38                         ; $FE84 FF
          RST $38                         ; $FE85 FF
          NOP                             ; $FE86 00
          NOP                             ; $FE87 00
          RST $38                         ; $FE88 FF
          RST $38                         ; $FE89 FF
          NOP                             ; $FE8A 00
          NOP                             ; $FE8B 00
          RST $38                         ; $FE8C FF
          RST $38                         ; $FE8D FF
          NOP                             ; $FE8E 00
          NOP                             ; $FE8F 00
          RST $38                         ; $FE90 FF
          RST $38                         ; $FE91 FF
          NOP                             ; $FE92 00
          NOP                             ; $FE93 00
          RST $38                         ; $FE94 FF
          RST $38                         ; $FE95 FF
          NOP                             ; $FE96 00
          NOP                             ; $FE97 00
          RST $38                         ; $FE98 FF
          RST $38                         ; $FE99 FF
          NOP                             ; $FE9A 00
          NOP                             ; $FE9B 00
          RST $38                         ; $FE9C FF
          RST $38                         ; $FE9D FF
          NOP                             ; $FE9E 00
          NOP                             ; $FE9F 00
          RST $38                         ; $FEA0 FF
          RST $38                         ; $FEA1 FF
          NOP                             ; $FEA2 00
          NOP                             ; $FEA3 00
          RST $38                         ; $FEA4 FF
          RST $38                         ; $FEA5 FF
          NOP                             ; $FEA6 00
          NOP                             ; $FEA7 00
          RST $30                         ; $FEA8 F7
          RST $30                         ; $FEA9 F7
          NOP                             ; $FEAA 00
          NOP                             ; $FEAB 00
          RST $30                         ; $FEAC F7
          RST $30                         ; $FEAD F7
          NOP                             ; $FEAE 00
          NOP                             ; $FEAF 00
          RST $30                         ; $FEB0 F7
          RST $30                         ; $FEB1 F7
          NOP                             ; $FEB2 00
          NOP                             ; $FEB3 00
          RST $30                         ; $FEB4 F7
          RST $30                         ; $FEB5 F7
          NOP                             ; $FEB6 00
          NOP                             ; $FEB7 00
          NOP                             ; $FEB8 00
          NOP                             ; $FEB9 00
          NOP                             ; $FEBA 00
          NOP                             ; $FEBB 00
          NOP                             ; $FEBC 00
          NOP                             ; $FEBD 00
          NOP                             ; $FEBE 00
          NOP                             ; $FEBF 00
          NOP                             ; $FEC0 00
          NOP                             ; $FEC1 00
          NOP                             ; $FEC2 00
          NOP                             ; $FEC3 00
          NOP                             ; $FEC4 00
          NOP                             ; $FEC5 00
          NOP                             ; $FEC6 00
          NOP                             ; $FEC7 00
          NOP                             ; $FEC8 00
          NOP                             ; $FEC9 00
          NOP                             ; $FECA 00
          NOP                             ; $FECB 00
          NOP                             ; $FECC 00
          NOP                             ; $FECD 00
          NOP                             ; $FECE 00
          NOP                             ; $FECF 00
          NOP                             ; $FED0 00
          NOP                             ; $FED1 00
          NOP                             ; $FED2 00
          NOP                             ; $FED3 00
          NOP                             ; $FED4 00
          NOP                             ; $FED5 00
          NOP                             ; $FED6 00
          NOP                             ; $FED7 00
          NOP                             ; $FED8 00
          NOP                             ; $FED9 00
          NOP                             ; $FEDA 00
          NOP                             ; $FEDB 00
          NOP                             ; $FEDC 00
          NOP                             ; $FEDD 00
          NOP                             ; $FEDE 00
          NOP                             ; $FEDF 00
          NOP                             ; $FEE0 00
          NOP                             ; $FEE1 00
          NOP                             ; $FEE2 00
          NOP                             ; $FEE3 00
          NOP                             ; $FEE4 00
          NOP                             ; $FEE5 00
          NOP                             ; $FEE6 00
          NOP                             ; $FEE7 00
          NOP                             ; $FEE8 00
          NOP                             ; $FEE9 00
          NOP                             ; $FEEA 00
          NOP                             ; $FEEB 00
          NOP                             ; $FEEC 00
          NOP                             ; $FEED 00
          NOP                             ; $FEEE 00
          NOP                             ; $FEEF 00
          NOP                             ; $FEF0 00
          NOP                             ; $FEF1 00
          NOP                             ; $FEF2 00
          NOP                             ; $FEF3 00
          NOP                             ; $FEF4 00
          NOP                             ; $FEF5 00
          NOP                             ; $FEF6 00
          NOP                             ; $FEF7 00
          NOP                             ; $FEF8 00
          NOP                             ; $FEF9 00
          NOP                             ; $FEFA 00
          NOP                             ; $FEFB 00
          NOP                             ; $FEFC 00
          NOP                             ; $FEFD 00
          NOP                             ; $FEFE 00
          NOP                             ; $FEFF 00
          NOP                             ; $FF00 00
          NOP                             ; $FF01 00
          NOP                             ; $FF02 00
          NOP                             ; $FF03 00
          NOP                             ; $FF04 00
          NOP                             ; $FF05 00
          NOP                             ; $FF06 00
          NOP                             ; $FF07 00
          NOP                             ; $FF08 00
          NOP                             ; $FF09 00
          NOP                             ; $FF0A 00
          NOP                             ; $FF0B 00
          NOP                             ; $FF0C 00
          NOP                             ; $FF0D 00
          LD B,A                          ; $FF0E 47
          LD HL,$FECD                     ; $FF0F 21 CD FE
          LD A,(HL)                       ; $FF12 7E
          LD E,A                          ; $FF13 5F
          OR A                            ; $FF14 B7
          JR NZ,$FF29                     ; $FF15 20 12
          LD A,($F397)                    ; $FF17 3A 97 F3
          OR A                            ; $FF1A B7
          JR Z,$FF23                      ; $FF1B 28 06
          CP C                            ; $FF1D B9
          JR NZ,$FF23                     ; $FF1E 20 03
          LD (HL),$80                     ; $FF20 36 80
          RET                             ; $FF22 C9
          LD A,$1F                        ; $FF23 3E 1F
          CP C                            ; $FF25 B9
          JP C,$FCA4                      ; $FF26 DA A4 FC
          LD HL,$F3A0                     ; $FF29 21 A0 F3
          LD B,$09                        ; $FF2C 06 09
          LD A,(HL)                       ; $FF2E 7E
          OR A                            ; $FF2F B7
          JR Z,$FF36                      ; $FF30 28 04
          XOR E                           ; $FF32 AB
          CP C                            ; $FF33 B9
          JR Z,$FF3B                      ; $FF34 28 05
          DEC HL                          ; $FF36 2B
          DJNZ $FF2E                      ; $FF37 10 F5
          JR $FF5C                        ; $FF39 18 21
          LD DE,$000B                     ; $FF3B 11 0B 00
          ADD HL,DE                       ; $FF3E 19
          LD A,(HL)                       ; $FF3F 7E
          OR A                            ; $FF40 B7
          LD C,A                          ; $FF41 4F
          JP P,$FC9A                      ; $FF42 F2 9A FC
          AND $7F                         ; $FF45 E6 7F
          LD C,A                          ; $FF47 4F
          PUSH BC                         ; $FF48 C5
          LD A,($F3A2)                    ; $FF49 3A A2 F3
          LD B,$07                        ; $FF4C 06 07
          CALL $FBF0                      ; $FF4E CD F0 FB
          POP BC                          ; $FF51 C1
          LD A,B                          ; $FF52 78
          CP $07                          ; $FF53 FE 07
          JR NZ,$FF5C                     ; $FF55 20 05
          LD A,$02                        ; $FF57 3E 02
          LD ($FECC),A                    ; $FF59 32 CC FE
          XOR A                           ; $FF5C AF
          LD ($FECD),A                    ; $FF5D 32 CD FE
          LD A,($FECB)                    ; $FF60 3A CB FE
          OR A                            ; $FF63 B7
          LD HL,($F388)                   ; $FF64 2A 88 F3
          JR Z,$FF6C                      ; $FF67 28 03
          LD HL,($F386)                   ; $FF69 2A 86 F3
          JP (HL)                         ; $FF6C E9
          LD DE,$0003                     ; $FF6D 11 03 00
          JP $FCBB                        ; $FF70 C3 BB FC
          LD HL,($FECE)                   ; $FF73 2A CE FE
          LD A,($FED0)                    ; $FF76 3A D0 FE
          LD (HL),A                       ; $FF79 77
          CALL $FCE2                      ; $FF7A CD E2 FC
          LD HL,($F028)                   ; $FF7D 2A 28 F0
          LD A,($F024)                    ; $FF80 3A 24 F0
          LD E,A                          ; $FF83 5F
          LD D,$F0                        ; $FF84 16 F0
          ADD HL,DE                       ; $FF86 19
          LD ($FECE),HL                   ; $FF87 22 CE FE
          LD A,(HL)                       ; $FF8A 7E
          LD ($FED0),A                    ; $FF8B 32 D0 FE
          CP $E0                          ; $FF8E FE E0
          JR C,$FF94                      ; $FF90 38 02
          XOR $20                         ; $FF92 EE 20
          AND $3F                         ; $FF94 E6 3F
          OR $40                          ; $FF96 F6 40
          LD (HL),A                       ; $FF98 77
          RET                             ; $FF99 C9
          LD A,B                          ; $FF9A 78
          OR A                            ; $FF9B B7
          JR Z,$FFA9                      ; $FF9C 28 0B
          LD HL,$FB45                     ; $FF9E 21 45 FB
          PUSH HL                         ; $FFA1 E5
          LD HL,$FD66                     ; $FFA2 21 66 FD
          ADD A,L                         ; $FFA5 85
          LD L,A                          ; $FFA6 6F
          LD L,(HL)                       ; $FFA7 6E
          JP (HL)                         ; $FFA8 E9
          LD A,C                          ; $FFA9 79
          CP $0D                          ; $FFAA FE 0D
          JR NZ,$FFB3                     ; $FFAC 20 05
          XOR A                           ; $FFAE AF
          LD ($F024),A                    ; $FFAF 32 24 F0
          RET                             ; $FFB2 C9
          OR $80                          ; $FFB3 F6 80
          CP $E0                          ; $FFB5 FE E0
          JR C,$FFB8                      ; $FFB7 38 FF
          RST $38                         ; $FFB9 FF
          NOP                             ; $FFBA 00
          NOP                             ; $FFBB 00
          RST $38                         ; $FFBC FF
          RST $38                         ; $FFBD FF
          NOP                             ; $FFBE 00
          NOP                             ; $FFBF 00
          RST $38                         ; $FFC0 FF
          RST $38                         ; $FFC1 FF
          NOP                             ; $FFC2 00
          NOP                             ; $FFC3 00
          RST $38                         ; $FFC4 FF
          RST $38                         ; $FFC5 FF
          NOP                             ; $FFC6 00
          NOP                             ; $FFC7 00
          RST $38                         ; $FFC8 FF
          RST $38                         ; $FFC9 FF
          NOP                             ; $FFCA 00
          NOP                             ; $FFCB 00
          RST $38                         ; $FFCC FF
          RST $38                         ; $FFCD FF
          NOP                             ; $FFCE 00
          NOP                             ; $FFCF 00
          RST $38                         ; $FFD0 FF
          RST $38                         ; $FFD1 FF
          NOP                             ; $FFD2 00
          NOP                             ; $FFD3 00
          RST $38                         ; $FFD4 FF
          RST $38                         ; $FFD5 FF
          NOP                             ; $FFD6 00
          NOP                             ; $FFD7 00
          RST $38                         ; $FFD8 FF
          RST $38                         ; $FFD9 FF
          NOP                             ; $FFDA 00
          NOP                             ; $FFDB 00
          RST $38                         ; $FFDC FF
          RST $38                         ; $FFDD FF
          NOP                             ; $FFDE 00
          NOP                             ; $FFDF 00
          RST $38                         ; $FFE0 FF
          RST $38                         ; $FFE1 FF
          NOP                             ; $FFE2 00
          NOP                             ; $FFE3 00
          RST $38                         ; $FFE4 FF
          RST $38                         ; $FFE5 FF
          NOP                             ; $FFE6 00
          NOP                             ; $FFE7 00
          RST $38                         ; $FFE8 FF
          RST $38                         ; $FFE9 FF
          NOP                             ; $FFEA 00
          NOP                             ; $FFEB 00
          RST $38                         ; $FFEC FF
          RST $38                         ; $FFED FF
          NOP                             ; $FFEE 00
          NOP                             ; $FFEF 00
          RST $38                         ; $FFF0 FF
          RST $38                         ; $FFF1 FF
          NOP                             ; $FFF2 00
          NOP                             ; $FFF3 00
          RST $38                         ; $FFF4 FF
          RST $38                         ; $FFF5 FF
          NOP                             ; $FFF6 00
          NOP                             ; $FFF7 00
          RST $38                         ; $FFF8 FF
          RST $38                         ; $FFF9 FF
          NOP                             ; $FFFA 00
          NOP                             ; $FFFB 00
          RST $38                         ; $FFFC FF
          RST $38                         ; $FFFD FF
          NOP                             ; $FFFE 00


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
