; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- Z-80 BIOS ($DACC-$E2CB, 2 KB)
; Annotated Z-80 assembly source for the 2.20 BIOS region.
;
; STRUCTURE
;   2.20's BIOS uses a 256-byte interleaved layout (same as 2.23) but
;   has 4 code pages + 4 filler pages = 2 KB total.
;
;     Page 0  $DACC-$DBCB  Jump table, dispatch table, generator (CODE)
;     Page 1  $DBCC-$DCCB  $E5 filler
;     Page 2  $DCCC-$DDCB  Per-device init helpers (CODE)
;     Page 3  $DDCC-$DECB  $E5 filler (BOOT vector lands here)
;     Page 4  $DECC-$DFCB  Cold-boot device-scan + helpers (CODE)
;     Page 5  $DFCC-$E0CB  $E5 filler
;     Page 6  $E0CC-$E1CB  STATIC PER-DEVICE HANDLERS (CODE) <- 2.23 lacks this
;     Page 7  $E1CC-$E2CB  $E5 filler
;
;   Filler is $E5 (CP/M deleted-file marker / Z-80 PUSH HL). 2.23 uses
;   FF/F7/00 trap markers instead -- a safety upgrade so premature
;   execution lands in a defined trap rather than thrashing the stack.
;
; KEY DIFFERENCES FROM 2.23
;   - 2 KB total (vs 2.23's 1.35 KB) -- 2.20 is bigger because of the
;     static-handler page.
;   - Page 6 ($E0CC-$E1CB) holds STATIC device handlers. 2.23 generates
;     equivalents at runtime instead.
;   - Cold-boot generator at $DB6E lacks the device-6 (Pascal 1.1)
;     branch that 2.23 added -- the Videx-fix is precisely this absence.
;   - Dispatch table at $DAFF has 6 entries (vs 2.23's 4), with entries
;     0-3 pointing to static handlers and entries 4-5 to runtime slots.
;   - BDOS final position $CC06 (vs 2.23's $9C06 -- 12 KB shift).
; ============================================================================

; ----------------------------------------------------------------------------
; State slots (in $E5-filled pages at runtime)
; ----------------------------------------------------------------------------
state_DEA4      = $DEA4
state_DEA5      = $DEA5
state_DEA7      = $DEA7
state_DEAF      = $DEAF
state_DEB4      = $DEB4
state_DEB1      = $DEB1
state_DEB6      = $DEB6
state_E5B2      = $E5B2

; ----------------------------------------------------------------------------
; TPA-area state (above BDOS at $CC06)
; ----------------------------------------------------------------------------
slot_info_F3B8  = $F3B8       ; slot-info table base
state_F386      = $F386
state_F388      = $F388
state_F397      = $F397

; ----------------------------------------------------------------------------
; CCP+BDOS final positions
; ----------------------------------------------------------------------------
BDOS_ENTRY      = $CC06       ; 2.20: BDOS at $CC06 (vs 2.23 at $9C06)

; ----------------------------------------------------------------------------
; Apple I/O
; ----------------------------------------------------------------------------
APPLE_TEXT_FLAG = $E051

    DEVICE NOSLOT64K
            .ORG $DACC


; ============================================================================
; SECTION 1 -- BIOS Jump Table ($DACC-$DAF8)
;
; Standard CP/M 2.x 15-entry jump table. Targets are in 2.20-specific
; addresses; structure parallels 2.23.
;
;   Offset  Address  Routine     Target
;   0       $DACC    BOOT        $DEA8  (lands in $E5 filler page 3)
;   3       $DACF    WBOOT       $DACC  (-> BOOT)
;   6       $DAD2    CONST       $DB08
;   9       $DAD5    CONIN       $DB12
;   12      $DAD8    CONOUT      $DB43
;   15      $DADB    LIST        $DB66
;   18      $DADE    PUNCH       $DB75
;   21      $DAE1    READER      $DB87
;   24      $DAE4    HOME        $DD4B
;   27      $DAE7    SELDSK      $DD6D
;   30      $DAEA    SETTRK      $DD56
;   33      $DAED    SETSEC      $DD89
;   36      $DAF0    SETDMA      $DD8E
;   39      $DAF3    READ        $DD93
;   42      $DAF6    WRITE       $DDA3
; ============================================================================

JUMP_TABLE:
          JP $DEA8                        ; $DACC C3 A8 DE
          JP $DACC                        ; $DACF C3 CC DA
          JP $DB08                        ; $DAD2 C3 08 DB
          JP $DB12                        ; $DAD5 C3 12 DB
          JP $DB43                        ; $DAD8 C3 43 DB
          JP $DB66                        ; $DADB C3 66 DB
          JP $DB75                        ; $DADE C3 75 DB
          JP $DB87                        ; $DAE1 C3 87 DB
          JP $DD4B                        ; $DAE4 C3 4B DD
          JP $DD6D                        ; $DAE7 C3 6D DD
          JP $DD56                        ; $DAEA C3 56 DD
          JP $DD89                        ; $DAED C3 89 DD
          JP $DD8E                        ; $DAF0 C3 8E DD
          JP $DD93                        ; $DAF3 C3 93 DD
          JP $DDA3                        ; $DAF6 C3 A3 DD
          XOR A                           ; $DAF9 AF
          RET                             ; $DAFA C9
          NOP                             ; $DAFB 00
          LD H,B                          ; $DAFC 60
          LD L,C                          ; $DAFD 69
          RET                             ; $DAFE C9
          NOP                             ; $DAFF 00
          NOP                             ; $DB00 00
          NOP                             ; $DB01 00
          NOP                             ; $DB02 00
          NOP                             ; $DB03 00
          NOP                             ; $DB04 00
          NOP                             ; $DB05 00
          NOP                             ; $DB06 00
          CP D                            ; $DB07 BA
          SBC A,$93                       ; $DB08 DE 93
          JP C,$DF9A                      ; $DB0A DA 9A DF
          LD A,($00DF)                    ; $DB0D 3A DF 00
          NOP                             ; $DB10 00
          NOP                             ; $DB11 00
          NOP                             ; $DB12 00
          NOP                             ; $DB13 00
          NOP                             ; $DB14 00
          NOP                             ; $DB15 00
          NOP                             ; $DB16 00
          CP D                            ; $DB17 BA
          SBC A,$93                       ; $DB18 DE 93
          JP C,$DFA6                      ; $DB1A DA A6 DF
          LD C,D                          ; $DB1D 4A
          RST $18                         ; $DB1E DF
          NOP                             ; $DB1F 00
          NOP                             ; $DB20 00
          NOP                             ; $DB21 00
          NOP                             ; $DB22 00
          NOP                             ; $DB23 00
          NOP                             ; $DB24 00
          NOP                             ; $DB25 00
          NOP                             ; $DB26 00
          CP D                            ; $DB27 BA
          SBC A,$93                       ; $DB28 DE 93
          JP C,$DFB2                      ; $DB2A DA B2 DF
          LD E,D                          ; $DB2D 5A
          RST $18                         ; $DB2E DF
          NOP                             ; $DB2F 00
          NOP                             ; $DB30 00
          NOP                             ; $DB31 00
          NOP                             ; $DB32 00
          NOP                             ; $DB33 00
          NOP                             ; $DB34 00
          NOP                             ; $DB35 00
          NOP                             ; $DB36 00
          CP D                            ; $DB37 BA
          SBC A,$93                       ; $DB38 DE 93
          JP C,$DFBE                      ; $DB3A DA BE DF
          LD L,D                          ; $DB3D 6A
          RST $18                         ; $DB3E DF
          NOP                             ; $DB3F 00
          NOP                             ; $DB40 00
          NOP                             ; $DB41 00
          NOP                             ; $DB42 00
          NOP                             ; $DB43 00
          NOP                             ; $DB44 00
          NOP                             ; $DB45 00
          NOP                             ; $DB46 00
          CP D                            ; $DB47 BA
          SBC A,$93                       ; $DB48 DE 93
          JP C,$DFCA                      ; $DB4A DA CA DF
          LD A,D                          ; $DB4D 7A
          RST $18                         ; $DB4E DF
          NOP                             ; $DB4F 00
          NOP                             ; $DB50 00
          NOP                             ; $DB51 00
          NOP                             ; $DB52 00
          NOP                             ; $DB53 00
          NOP                             ; $DB54 00
          NOP                             ; $DB55 00
          NOP                             ; $DB56 00
          CP D                            ; $DB57 BA
          SBC A,$93                       ; $DB58 DE 93
          JP C,$DFD6                      ; $DB5A DA D6 DF
          ADC A,D                         ; $DB5D 8A
          RST $18                         ; $DB5E DF
          JR NZ,$DB61                     ; $DB5F 20 00
          INC BC                          ; $DB61 03
          RLCA                            ; $DB62 07
          NOP                             ; $DB63 00
          LD A,A                          ; $DB64 7F
          NOP                             ; $DB65 00
          CPL                             ; $DB66 2F
          NOP                             ; $DB67 00
          RET NZ                          ; $DB68 C0
          NOP                             ; $DB69 00
          INC C                           ; $DB6A 0C
          NOP                             ; $DB6B 00
          INC BC                          ; $DB6C 03
          NOP                             ; $DB6D 00
          LD DE,$0007                     ; $DB6E 11 07 00
          LD HL,$F3B8                     ; $DB71 21 B8 F3
          ADD HL,DE                       ; $DB74 19
          LD A,(HL)                       ; $DB75 7E
          SUB $03                         ; $DB76 D6 03
          JR NZ,$DB81                     ; $DB78 20 07
          CALL $DD60                      ; $DB7A CD 60 DD
          LD (HL),$03                     ; $DB7D 36 03
          LD (HL),$15                     ; $DB7F 36 15
          DEC A                           ; $DB81 3D
          JR NZ,$DB8D                     ; $DB82 20 09
          CALL $DCEE                      ; $DB84 CD EE DC
          LD HL,$C800                     ; $DB87 21 00 C8
          CALL $DB3B                      ; $DB8A CD 3B DB
          DEC E                           ; $DB8D 1D
          JR NZ,$DB71                     ; $DB8E 20 E1
          RET                             ; $DB90 C9
          LD HL,$E000                     ; $DB91 21 00 E0
          LD A,E                          ; $DB94 7B
          OR H                            ; $DB95 B4
          LD H,A                          ; $DB96 67
          RET                             ; $DB97 C9
          LD SP,$0080                     ; $DB98 31 80 00
          LD A,($E051)                    ; $DB9B 3A 51 E0
          LD HL,$0E00                     ; $DB9E 21 00 0E
          CALL $DFE8                      ; $DBA1 CD E8 DF
          CALL $DAA2                      ; $DBA4 CD A2 DA
          XOR A                           ; $DBA7 AF
          LD ($DEB4),A                    ; $DBA8 32 B4 DE
          LD ($DEAF),A                    ; $DBAB 32 AF DE
          LD A,$C3                        ; $DBAE 3E C3
          LD ($0000),A                    ; $DBB0 32 00 00
          LD HL,$DA03                     ; $DBB3 21 03 DA
          LD ($0001),HL                   ; $DBB6 22 01 00
          LD ($0005),A                    ; $DBB9 32 05 00
          LD HL,$CC06                     ; $DBBC 21 06 CC
          LD ($0006),HL                   ; $DBBF 22 06 00
          LD BC,$0080                     ; $DBC2 01 80 00
          CALL $DD8E                      ; $DBC5 CD 8E DD
          LD A,$01                        ; $DBC8 3E 01
          LD ($E5B2),A                    ; $DBCA 32 B2 E5
          PUSH HL                         ; $DBCD E5
          PUSH HL                         ; $DBCE E5
          PUSH HL                         ; $DBCF E5
          PUSH HL                         ; $DBD0 E5
          PUSH HL                         ; $DBD1 E5
          PUSH HL                         ; $DBD2 E5
          PUSH HL                         ; $DBD3 E5
          PUSH HL                         ; $DBD4 E5
          PUSH HL                         ; $DBD5 E5
          PUSH HL                         ; $DBD6 E5
          PUSH HL                         ; $DBD7 E5
          PUSH HL                         ; $DBD8 E5
          PUSH HL                         ; $DBD9 E5
          PUSH HL                         ; $DBDA E5
          PUSH HL                         ; $DBDB E5
          PUSH HL                         ; $DBDC E5
          PUSH HL                         ; $DBDD E5
          PUSH HL                         ; $DBDE E5
          PUSH HL                         ; $DBDF E5
          PUSH HL                         ; $DBE0 E5
          PUSH HL                         ; $DBE1 E5
          PUSH HL                         ; $DBE2 E5
          PUSH HL                         ; $DBE3 E5
          PUSH HL                         ; $DBE4 E5
          PUSH HL                         ; $DBE5 E5
          PUSH HL                         ; $DBE6 E5
          PUSH HL                         ; $DBE7 E5
          PUSH HL                         ; $DBE8 E5
          PUSH HL                         ; $DBE9 E5
          PUSH HL                         ; $DBEA E5
          PUSH HL                         ; $DBEB E5
          PUSH HL                         ; $DBEC E5
          PUSH HL                         ; $DBED E5
          PUSH HL                         ; $DBEE E5
          PUSH HL                         ; $DBEF E5
          PUSH HL                         ; $DBF0 E5
          PUSH HL                         ; $DBF1 E5
          PUSH HL                         ; $DBF2 E5
          PUSH HL                         ; $DBF3 E5
          PUSH HL                         ; $DBF4 E5
          PUSH HL                         ; $DBF5 E5
          PUSH HL                         ; $DBF6 E5
          PUSH HL                         ; $DBF7 E5
          PUSH HL                         ; $DBF8 E5
          PUSH HL                         ; $DBF9 E5
          PUSH HL                         ; $DBFA E5
          PUSH HL                         ; $DBFB E5
          PUSH HL                         ; $DBFC E5
          PUSH HL                         ; $DBFD E5
          PUSH HL                         ; $DBFE E5
          PUSH HL                         ; $DBFF E5
          PUSH HL                         ; $DC00 E5
          PUSH HL                         ; $DC01 E5
          PUSH HL                         ; $DC02 E5
          PUSH HL                         ; $DC03 E5
          PUSH HL                         ; $DC04 E5
          PUSH HL                         ; $DC05 E5
          PUSH HL                         ; $DC06 E5
          PUSH HL                         ; $DC07 E5
          PUSH HL                         ; $DC08 E5
          PUSH HL                         ; $DC09 E5
          PUSH HL                         ; $DC0A E5
          PUSH HL                         ; $DC0B E5
          PUSH HL                         ; $DC0C E5
          PUSH HL                         ; $DC0D E5
          PUSH HL                         ; $DC0E E5
          PUSH HL                         ; $DC0F E5
          PUSH HL                         ; $DC10 E5
          PUSH HL                         ; $DC11 E5
          PUSH HL                         ; $DC12 E5
          PUSH HL                         ; $DC13 E5
          PUSH HL                         ; $DC14 E5
          PUSH HL                         ; $DC15 E5
          PUSH HL                         ; $DC16 E5
          PUSH HL                         ; $DC17 E5
          PUSH HL                         ; $DC18 E5
          PUSH HL                         ; $DC19 E5
          PUSH HL                         ; $DC1A E5
          PUSH HL                         ; $DC1B E5
          PUSH HL                         ; $DC1C E5
          PUSH HL                         ; $DC1D E5
          PUSH HL                         ; $DC1E E5
          PUSH HL                         ; $DC1F E5
          PUSH HL                         ; $DC20 E5
          PUSH HL                         ; $DC21 E5
          PUSH HL                         ; $DC22 E5
          PUSH HL                         ; $DC23 E5
          PUSH HL                         ; $DC24 E5
          PUSH HL                         ; $DC25 E5
          PUSH HL                         ; $DC26 E5
          PUSH HL                         ; $DC27 E5
          PUSH HL                         ; $DC28 E5
          PUSH HL                         ; $DC29 E5
          PUSH HL                         ; $DC2A E5
          PUSH HL                         ; $DC2B E5
          PUSH HL                         ; $DC2C E5
          PUSH HL                         ; $DC2D E5
          PUSH HL                         ; $DC2E E5
          PUSH HL                         ; $DC2F E5
          PUSH HL                         ; $DC30 E5
          PUSH HL                         ; $DC31 E5
          PUSH HL                         ; $DC32 E5
          PUSH HL                         ; $DC33 E5
          PUSH HL                         ; $DC34 E5
          PUSH HL                         ; $DC35 E5
          PUSH HL                         ; $DC36 E5
          PUSH HL                         ; $DC37 E5
          PUSH HL                         ; $DC38 E5
          PUSH HL                         ; $DC39 E5
          PUSH HL                         ; $DC3A E5
          PUSH HL                         ; $DC3B E5
          PUSH HL                         ; $DC3C E5
          PUSH HL                         ; $DC3D E5
          PUSH HL                         ; $DC3E E5
          PUSH HL                         ; $DC3F E5
          PUSH HL                         ; $DC40 E5
          PUSH HL                         ; $DC41 E5
          PUSH HL                         ; $DC42 E5
          PUSH HL                         ; $DC43 E5
          PUSH HL                         ; $DC44 E5
          PUSH HL                         ; $DC45 E5
          PUSH HL                         ; $DC46 E5
          PUSH HL                         ; $DC47 E5
          PUSH HL                         ; $DC48 E5
          PUSH HL                         ; $DC49 E5
          PUSH HL                         ; $DC4A E5
          PUSH HL                         ; $DC4B E5
          PUSH HL                         ; $DC4C E5
          PUSH HL                         ; $DC4D E5
          PUSH HL                         ; $DC4E E5
          PUSH HL                         ; $DC4F E5
          PUSH HL                         ; $DC50 E5
          PUSH HL                         ; $DC51 E5
          PUSH HL                         ; $DC52 E5
          PUSH HL                         ; $DC53 E5
          PUSH HL                         ; $DC54 E5
          PUSH HL                         ; $DC55 E5
          PUSH HL                         ; $DC56 E5
          PUSH HL                         ; $DC57 E5
          PUSH HL                         ; $DC58 E5
          PUSH HL                         ; $DC59 E5
          PUSH HL                         ; $DC5A E5
          PUSH HL                         ; $DC5B E5
          PUSH HL                         ; $DC5C E5
          PUSH HL                         ; $DC5D E5
          PUSH HL                         ; $DC5E E5
          PUSH HL                         ; $DC5F E5
          PUSH HL                         ; $DC60 E5
          PUSH HL                         ; $DC61 E5
          PUSH HL                         ; $DC62 E5
          PUSH HL                         ; $DC63 E5
          PUSH HL                         ; $DC64 E5
          PUSH HL                         ; $DC65 E5
          PUSH HL                         ; $DC66 E5
          PUSH HL                         ; $DC67 E5
          PUSH HL                         ; $DC68 E5
          PUSH HL                         ; $DC69 E5
          PUSH HL                         ; $DC6A E5
          PUSH HL                         ; $DC6B E5
          PUSH HL                         ; $DC6C E5
          PUSH HL                         ; $DC6D E5
          PUSH HL                         ; $DC6E E5
          PUSH HL                         ; $DC6F E5
          PUSH HL                         ; $DC70 E5
          PUSH HL                         ; $DC71 E5
          PUSH HL                         ; $DC72 E5
          PUSH HL                         ; $DC73 E5
          PUSH HL                         ; $DC74 E5
          PUSH HL                         ; $DC75 E5
          PUSH HL                         ; $DC76 E5
          PUSH HL                         ; $DC77 E5
          PUSH HL                         ; $DC78 E5
          PUSH HL                         ; $DC79 E5
          PUSH HL                         ; $DC7A E5
          PUSH HL                         ; $DC7B E5
          PUSH HL                         ; $DC7C E5
          PUSH HL                         ; $DC7D E5
          PUSH HL                         ; $DC7E E5
          PUSH HL                         ; $DC7F E5
          PUSH HL                         ; $DC80 E5
          PUSH HL                         ; $DC81 E5
          PUSH HL                         ; $DC82 E5
          PUSH HL                         ; $DC83 E5
          PUSH HL                         ; $DC84 E5
          PUSH HL                         ; $DC85 E5
          PUSH HL                         ; $DC86 E5
          PUSH HL                         ; $DC87 E5
          PUSH HL                         ; $DC88 E5
          PUSH HL                         ; $DC89 E5
          PUSH HL                         ; $DC8A E5
          PUSH HL                         ; $DC8B E5
          PUSH HL                         ; $DC8C E5
          PUSH HL                         ; $DC8D E5
          PUSH HL                         ; $DC8E E5
          PUSH HL                         ; $DC8F E5
          PUSH HL                         ; $DC90 E5
          PUSH HL                         ; $DC91 E5
          PUSH HL                         ; $DC92 E5
          PUSH HL                         ; $DC93 E5
          PUSH HL                         ; $DC94 E5
          PUSH HL                         ; $DC95 E5
          PUSH HL                         ; $DC96 E5
          PUSH HL                         ; $DC97 E5
          PUSH HL                         ; $DC98 E5
          PUSH HL                         ; $DC99 E5
          PUSH HL                         ; $DC9A E5
          PUSH HL                         ; $DC9B E5
          PUSH HL                         ; $DC9C E5
          PUSH HL                         ; $DC9D E5
          PUSH HL                         ; $DC9E E5
          PUSH HL                         ; $DC9F E5
          PUSH HL                         ; $DCA0 E5
          PUSH HL                         ; $DCA1 E5
          PUSH HL                         ; $DCA2 E5
          PUSH HL                         ; $DCA3 E5
          PUSH HL                         ; $DCA4 E5
          PUSH HL                         ; $DCA5 E5
          PUSH HL                         ; $DCA6 E5
          PUSH HL                         ; $DCA7 E5
          PUSH HL                         ; $DCA8 E5
          PUSH HL                         ; $DCA9 E5
          PUSH HL                         ; $DCAA E5
          PUSH HL                         ; $DCAB E5
          PUSH HL                         ; $DCAC E5
          PUSH HL                         ; $DCAD E5
          PUSH HL                         ; $DCAE E5
          PUSH HL                         ; $DCAF E5
          PUSH HL                         ; $DCB0 E5
          PUSH HL                         ; $DCB1 E5
          PUSH HL                         ; $DCB2 E5
          PUSH HL                         ; $DCB3 E5
          PUSH HL                         ; $DCB4 E5
          PUSH HL                         ; $DCB5 E5
          PUSH HL                         ; $DCB6 E5
          PUSH HL                         ; $DCB7 E5
          PUSH HL                         ; $DCB8 E5
          PUSH HL                         ; $DCB9 E5
          PUSH HL                         ; $DCBA E5
          PUSH HL                         ; $DCBB E5
          PUSH HL                         ; $DCBC E5
          PUSH HL                         ; $DCBD E5
          PUSH HL                         ; $DCBE E5
          PUSH HL                         ; $DCBF E5
          PUSH HL                         ; $DCC0 E5
          PUSH HL                         ; $DCC1 E5
          PUSH HL                         ; $DCC2 E5
          PUSH HL                         ; $DCC3 E5
          PUSH HL                         ; $DCC4 E5
          PUSH HL                         ; $DCC5 E5
          PUSH HL                         ; $DCC6 E5
          PUSH HL                         ; $DCC7 E5
          PUSH HL                         ; $DCC8 E5
          PUSH HL                         ; $DCC9 E5
          PUSH HL                         ; $DCCA E5
          PUSH HL                         ; $DCCB E5
          RET Z                           ; $DCCC C8
          LD A,($0004)                    ; $DCCD 3A 04 00
          LD C,A                          ; $DCD0 4F
          JP $C400                        ; $DCD1 C3 00 C4
          LD HL,($F380)                   ; $DCD4 2A 80 F3
          JP (HL)                         ; $DCD7 E9
          LD A,($E000)                    ; $DCD8 3A 00 E0
          RLA                             ; $DCDB 17
          SBC A,A                         ; $DCDC 9F
          RET                             ; $DCDD C9
          CALL $DB50                      ; $DCDE CD 50 DB
          LD HL,$F3AB                     ; $DCE1 21 AB F3
          LD B,$06                        ; $DCE4 06 06
          LD C,A                          ; $DCE6 4F
          INC HL                          ; $DCE7 23
          LD A,(HL)                       ; $DCE8 7E
          INC HL                          ; $DCE9 23
          OR A                            ; $DCEA B7
          JP M,$DB27                      ; $DCEB FA 27 DB
          CP C                            ; $DCEE B9
          LD A,(HL)                       ; $DCEF 7E
          RET Z                           ; $DCF0 C8
          DJNZ $DCE7                      ; $DCF1 10 F4
          LD A,C                          ; $DCF3 79
          RET                             ; $DCF4 C9
          LD DE,$0003                     ; $DCF5 11 03 00
          JP $DB2F                        ; $DCF8 C3 2F DB
          LD A,($E000)                    ; $DCFB 3A 00 E0
          RLA                             ; $DCFE 17
          JR NC,$DCFB                     ; $DCFF 30 FA
          LD ($E010),A                    ; $DD01 32 10 E0
          CCF                             ; $DD04 3F
          RRA                             ; $DD05 1F
          RET                             ; $DD06 C9
          LD ($F3D0),HL                   ; $DD07 22 D0 F3
          LD ($0000),A                    ; $DD0A 32 00 00
          RET                             ; $DD0D C9
          LD C,A                          ; $DD0E 4F
          LD A,($0003)                    ; $DD0F 3A 03 00
          AND $03                         ; $DD12 E6 03
          CP $02                          ; $DD14 FE 02
          JR NZ,$DD63                     ; $DD16 20 4B
          LD HL,($F392)                   ; $DD18 2A 92 F3
          JP (HL)                         ; $DD1B E9
          LD A,($0003)                    ; $DD1C 3A 03 00
          AND $03                         ; $DD1F E6 03
          CP $02                          ; $DD21 FE 02
          LD HL,($F384)                   ; $DD23 2A 84 F3
          JR Z,$DD2E                      ; $DD26 28 06
          JR NC,$DD31                     ; $DD28 30 07
          LD HL,($F382)                   ; $DD2A 2A 82 F3
          JP (HL)                         ; $DD2D E9
          LD HL,($F38A)                   ; $DD2E 2A 8A F3
          JP (HL)                         ; $DD31 E9
          LD A,($0003)                    ; $DD32 3A 03 00
          AND $C0                         ; $DD35 E6 C0
          CP $80                          ; $DD37 FE 80
          JR C,$DD62                      ; $DD39 38 27
          JR Z,$DD18                      ; $DD3B 28 DB
          LD HL,($F394)                   ; $DD3D 2A 94 F3
          JP (HL)                         ; $DD40 E9
          LD A,($0003)                    ; $DD41 3A 03 00
          AND $30                         ; $DD44 E6 30
          CP $10                          ; $DD46 FE 10
          JR C,$DD62                      ; $DD48 38 18
          LD HL,($F38E)                   ; $DD4A 2A 8E F3
          JR NZ,$DD31                     ; $DD4D 20 E2
          LD HL,($F390)                   ; $DD4F 2A 90 F3
          JP (HL)                         ; $DD52 E9
          LD A,($0003)                    ; $DD53 3A 03 00
          AND $0C                         ; $DD56 E6 0C
          CP $04                          ; $DD58 FE 04
          JR C,$DD2A                      ; $DD5A 38 CE
          JR Z,$DD2E                      ; $DD5C 28 D0
          LD HL,($F38C)                   ; $DD5E 2A 8C F3
          JP (HL)                         ; $DD61 E9
          SCF                             ; $DD62 37
          SBC A,A                         ; $DD63 9F
          LD HL,$DEA2                     ; $DD64 21 A2 DE
          LD (HL),A                       ; $DD67 77
          DB $CB                          ; $DD68 CB
          CP C                            ; $DD69 B9
          INC HL                          ; $DD6A 23
          LD A,(HL)                       ; $DD6B 7E
          OR A                            ; $DD6C B7
          JR Z,$DDAC                      ; $DD6D 28 3D
          DEC (HL)                        ; $DD6F 35
          LD A,($F396)                    ; $DD70 3A 96 F3
          LD HL,$DEAB                     ; $DD73 21 AB DE
          JR Z,$DD84                      ; $DD76 28 0C
          OR A                            ; $DD78 B7
          JP P,$DBB3                      ; $DD79 F2 B3 DB
          DEC HL                          ; $DD7C 2B
          AND $7F                         ; $DD7D E6 7F
          LD E,A                          ; $DD7F 5F
          LD A,C                          ; $DD80 79
          SUB E                           ; $DD81 93
          LD (HL),A                       ; $DD82 77
          RET                             ; $DD83 C9
          OR A                            ; $DD84 B7
          JP M,$DBBD                      ; $DD85 FA BD DB
          DEC HL                          ; $DD88 2B
          CALL $DBB1                      ; $DD89 CD B1 DB
          LD HL,($DEAA)                   ; $DD8C 2A AA DE
          LD A,($F3A1)                    ; $DD8F 3A A1 F3
          OR A                            ; $DD92 B7
          JP P,$DBCF                      ; $DD93 F2 CF DB
          AND $7F                         ; $DD96 E6 7F
          LD E,L                          ; $DD98 5D
          LD L,H                          ; $DD99 6C
          LD H,E                          ; $DD9A 63
          LD E,A                          ; $DD9B 5F
          ADD A,H                         ; $DD9C 84
          LD C,A                          ; $DD9D 4F
          LD A,E                          ; $DD9E 7B
          ADD A,L                         ; $DD9F 85
          PUSH AF                         ; $DDA0 F5
          LD B,$07                        ; $DDA1 06 07
          CALL $DC2D                      ; $DDA3 CD 2D DC
          POP AF                          ; $DDA6 F1
          LD B,$0A                        ; $DDA7 06 0A
          LD C,A                          ; $DDA9 4F
          JR $DDF9                        ; $DDAA 18 4D
          LD B,A                          ; $DDAC 47
          LD HL,$DEA4                     ; $DDAD 21 A4 DE
          LD A,(HL)                       ; $DDB0 7E
          LD E,A                          ; $DDB1 5F
          OR A                            ; $DDB2 B7
          JR NZ,$DDC6                     ; $DDB3 20 11
          LD A,($F397)                    ; $DDB5 3A 97 F3
          OR A                            ; $DDB8 B7
          JR Z,$DDC1                      ; $DDB9 28 06
          CP C                            ; $DDBB B9
          JR NZ,$DDC1                     ; $DDBC 20 03
          LD (HL),$80                     ; $DDBE 36 80
          RET                             ; $DDC0 C9
          LD A,$1F                        ; $DDC1 3E 1F
          CP C                            ; $DDC3 B9
          JR C,$DDF9                      ; $DDC4 38 33
          LD HL,$F3A0                     ; $DDC6 21 A0 F3
          LD B,$09                        ; $DDC9 06 09
          LD A,(HL)                       ; $DDCB 7E
          PUSH HL                         ; $DDCC E5
          PUSH HL                         ; $DDCD E5
          PUSH HL                         ; $DDCE E5
          PUSH HL                         ; $DDCF E5
          PUSH HL                         ; $DDD0 E5
          PUSH HL                         ; $DDD1 E5
          PUSH HL                         ; $DDD2 E5
          PUSH HL                         ; $DDD3 E5
          PUSH HL                         ; $DDD4 E5
          PUSH HL                         ; $DDD5 E5
          PUSH HL                         ; $DDD6 E5
          PUSH HL                         ; $DDD7 E5
          PUSH HL                         ; $DDD8 E5
          PUSH HL                         ; $DDD9 E5
          PUSH HL                         ; $DDDA E5
          PUSH HL                         ; $DDDB E5
          PUSH HL                         ; $DDDC E5
          PUSH HL                         ; $DDDD E5
          PUSH HL                         ; $DDDE E5
          PUSH HL                         ; $DDDF E5
          PUSH HL                         ; $DDE0 E5
          PUSH HL                         ; $DDE1 E5
          PUSH HL                         ; $DDE2 E5
          PUSH HL                         ; $DDE3 E5
          PUSH HL                         ; $DDE4 E5
          PUSH HL                         ; $DDE5 E5
          PUSH HL                         ; $DDE6 E5
          PUSH HL                         ; $DDE7 E5
          PUSH HL                         ; $DDE8 E5
          PUSH HL                         ; $DDE9 E5
          PUSH HL                         ; $DDEA E5
          PUSH HL                         ; $DDEB E5
          PUSH HL                         ; $DDEC E5
          PUSH HL                         ; $DDED E5
          PUSH HL                         ; $DDEE E5
          PUSH HL                         ; $DDEF E5
          PUSH HL                         ; $DDF0 E5
          PUSH HL                         ; $DDF1 E5
          PUSH HL                         ; $DDF2 E5
          PUSH HL                         ; $DDF3 E5
          PUSH HL                         ; $DDF4 E5
          PUSH HL                         ; $DDF5 E5
          PUSH HL                         ; $DDF6 E5
          PUSH HL                         ; $DDF7 E5
          PUSH HL                         ; $DDF8 E5
          PUSH HL                         ; $DDF9 E5
          PUSH HL                         ; $DDFA E5
          PUSH HL                         ; $DDFB E5
          PUSH HL                         ; $DDFC E5
          PUSH HL                         ; $DDFD E5
          PUSH HL                         ; $DDFE E5
          PUSH HL                         ; $DDFF E5
          PUSH HL                         ; $DE00 E5
          PUSH HL                         ; $DE01 E5
          PUSH HL                         ; $DE02 E5
          PUSH HL                         ; $DE03 E5
          PUSH HL                         ; $DE04 E5
          PUSH HL                         ; $DE05 E5
          PUSH HL                         ; $DE06 E5
          PUSH HL                         ; $DE07 E5
          PUSH HL                         ; $DE08 E5
          PUSH HL                         ; $DE09 E5
          PUSH HL                         ; $DE0A E5
          PUSH HL                         ; $DE0B E5
          PUSH HL                         ; $DE0C E5
          PUSH HL                         ; $DE0D E5
          PUSH HL                         ; $DE0E E5
          PUSH HL                         ; $DE0F E5
          PUSH HL                         ; $DE10 E5
          PUSH HL                         ; $DE11 E5
          PUSH HL                         ; $DE12 E5
          PUSH HL                         ; $DE13 E5
          PUSH HL                         ; $DE14 E5
          PUSH HL                         ; $DE15 E5
          PUSH HL                         ; $DE16 E5
          PUSH HL                         ; $DE17 E5
          PUSH HL                         ; $DE18 E5
          PUSH HL                         ; $DE19 E5
          PUSH HL                         ; $DE1A E5
          PUSH HL                         ; $DE1B E5
          PUSH HL                         ; $DE1C E5
          PUSH HL                         ; $DE1D E5
          PUSH HL                         ; $DE1E E5
          PUSH HL                         ; $DE1F E5
          PUSH HL                         ; $DE20 E5
          PUSH HL                         ; $DE21 E5
          PUSH HL                         ; $DE22 E5
          PUSH HL                         ; $DE23 E5
          PUSH HL                         ; $DE24 E5
          PUSH HL                         ; $DE25 E5
          PUSH HL                         ; $DE26 E5
          PUSH HL                         ; $DE27 E5
          PUSH HL                         ; $DE28 E5
          PUSH HL                         ; $DE29 E5
          PUSH HL                         ; $DE2A E5
          PUSH HL                         ; $DE2B E5
          PUSH HL                         ; $DE2C E5
          PUSH HL                         ; $DE2D E5
          PUSH HL                         ; $DE2E E5
          PUSH HL                         ; $DE2F E5
          PUSH HL                         ; $DE30 E5
          PUSH HL                         ; $DE31 E5
          PUSH HL                         ; $DE32 E5
          PUSH HL                         ; $DE33 E5
          PUSH HL                         ; $DE34 E5
          PUSH HL                         ; $DE35 E5
          PUSH HL                         ; $DE36 E5
          PUSH HL                         ; $DE37 E5
          PUSH HL                         ; $DE38 E5
          PUSH HL                         ; $DE39 E5
          PUSH HL                         ; $DE3A E5
          PUSH HL                         ; $DE3B E5
          PUSH HL                         ; $DE3C E5
          PUSH HL                         ; $DE3D E5
          PUSH HL                         ; $DE3E E5
          PUSH HL                         ; $DE3F E5
          PUSH HL                         ; $DE40 E5
          PUSH HL                         ; $DE41 E5
          PUSH HL                         ; $DE42 E5
          PUSH HL                         ; $DE43 E5
          PUSH HL                         ; $DE44 E5
          PUSH HL                         ; $DE45 E5
          PUSH HL                         ; $DE46 E5
          PUSH HL                         ; $DE47 E5
          PUSH HL                         ; $DE48 E5
          PUSH HL                         ; $DE49 E5
          PUSH HL                         ; $DE4A E5
          PUSH HL                         ; $DE4B E5
          PUSH HL                         ; $DE4C E5
          PUSH HL                         ; $DE4D E5
          PUSH HL                         ; $DE4E E5
          PUSH HL                         ; $DE4F E5
          PUSH HL                         ; $DE50 E5
          PUSH HL                         ; $DE51 E5
          PUSH HL                         ; $DE52 E5
          PUSH HL                         ; $DE53 E5
          PUSH HL                         ; $DE54 E5
          PUSH HL                         ; $DE55 E5
          PUSH HL                         ; $DE56 E5
          PUSH HL                         ; $DE57 E5
          PUSH HL                         ; $DE58 E5
          PUSH HL                         ; $DE59 E5
          PUSH HL                         ; $DE5A E5
          PUSH HL                         ; $DE5B E5
          PUSH HL                         ; $DE5C E5
          PUSH HL                         ; $DE5D E5
          PUSH HL                         ; $DE5E E5
          PUSH HL                         ; $DE5F E5
          PUSH HL                         ; $DE60 E5
          PUSH HL                         ; $DE61 E5
          PUSH HL                         ; $DE62 E5
          PUSH HL                         ; $DE63 E5
          PUSH HL                         ; $DE64 E5
          PUSH HL                         ; $DE65 E5
          PUSH HL                         ; $DE66 E5
          PUSH HL                         ; $DE67 E5
          PUSH HL                         ; $DE68 E5
          PUSH HL                         ; $DE69 E5
          PUSH HL                         ; $DE6A E5
          PUSH HL                         ; $DE6B E5
          PUSH HL                         ; $DE6C E5
          PUSH HL                         ; $DE6D E5
          PUSH HL                         ; $DE6E E5
          PUSH HL                         ; $DE6F E5
          PUSH HL                         ; $DE70 E5
          PUSH HL                         ; $DE71 E5
          PUSH HL                         ; $DE72 E5
          PUSH HL                         ; $DE73 E5
          PUSH HL                         ; $DE74 E5
          PUSH HL                         ; $DE75 E5
          PUSH HL                         ; $DE76 E5
          PUSH HL                         ; $DE77 E5
          PUSH HL                         ; $DE78 E5
          PUSH HL                         ; $DE79 E5
          PUSH HL                         ; $DE7A E5
          PUSH HL                         ; $DE7B E5
          PUSH HL                         ; $DE7C E5
          PUSH HL                         ; $DE7D E5
          PUSH HL                         ; $DE7E E5
          PUSH HL                         ; $DE7F E5
          PUSH HL                         ; $DE80 E5
          PUSH HL                         ; $DE81 E5
          PUSH HL                         ; $DE82 E5
          PUSH HL                         ; $DE83 E5
          PUSH HL                         ; $DE84 E5
          PUSH HL                         ; $DE85 E5
          PUSH HL                         ; $DE86 E5
          PUSH HL                         ; $DE87 E5
          PUSH HL                         ; $DE88 E5
          PUSH HL                         ; $DE89 E5
          PUSH HL                         ; $DE8A E5
          PUSH HL                         ; $DE8B E5
          PUSH HL                         ; $DE8C E5
          PUSH HL                         ; $DE8D E5
          PUSH HL                         ; $DE8E E5
          PUSH HL                         ; $DE8F E5
          PUSH HL                         ; $DE90 E5
          PUSH HL                         ; $DE91 E5
          PUSH HL                         ; $DE92 E5
          PUSH HL                         ; $DE93 E5
          PUSH HL                         ; $DE94 E5
          PUSH HL                         ; $DE95 E5
          PUSH HL                         ; $DE96 E5
          PUSH HL                         ; $DE97 E5
          PUSH HL                         ; $DE98 E5
          PUSH HL                         ; $DE99 E5
          PUSH HL                         ; $DE9A E5
          PUSH HL                         ; $DE9B E5
          PUSH HL                         ; $DE9C E5
          PUSH HL                         ; $DE9D E5
          PUSH HL                         ; $DE9E E5
          PUSH HL                         ; $DE9F E5
          PUSH HL                         ; $DEA0 E5
          PUSH HL                         ; $DEA1 E5
          PUSH HL                         ; $DEA2 E5
          PUSH HL                         ; $DEA3 E5
          PUSH HL                         ; $DEA4 E5
          PUSH HL                         ; $DEA5 E5
          PUSH HL                         ; $DEA6 E5
          PUSH HL                         ; $DEA7 E5
          PUSH HL                         ; $DEA8 E5
          PUSH HL                         ; $DEA9 E5
          PUSH HL                         ; $DEAA E5
          PUSH HL                         ; $DEAB E5
          PUSH HL                         ; $DEAC E5
          PUSH HL                         ; $DEAD E5
          PUSH HL                         ; $DEAE E5
          PUSH HL                         ; $DEAF E5
          PUSH HL                         ; $DEB0 E5
          PUSH HL                         ; $DEB1 E5
          PUSH HL                         ; $DEB2 E5
          PUSH HL                         ; $DEB3 E5
          PUSH HL                         ; $DEB4 E5
          PUSH HL                         ; $DEB5 E5
          PUSH HL                         ; $DEB6 E5
          PUSH HL                         ; $DEB7 E5
          PUSH HL                         ; $DEB8 E5
          PUSH HL                         ; $DEB9 E5
          PUSH HL                         ; $DEBA E5
          PUSH HL                         ; $DEBB E5
          PUSH HL                         ; $DEBC E5
          PUSH HL                         ; $DEBD E5
          PUSH HL                         ; $DEBE E5
          PUSH HL                         ; $DEBF E5
          PUSH HL                         ; $DEC0 E5
          PUSH HL                         ; $DEC1 E5
          PUSH HL                         ; $DEC2 E5
          PUSH HL                         ; $DEC3 E5
          PUSH HL                         ; $DEC4 E5
          PUSH HL                         ; $DEC5 E5
          PUSH HL                         ; $DEC6 E5
          PUSH HL                         ; $DEC7 E5
          PUSH HL                         ; $DEC8 E5
          PUSH HL                         ; $DEC9 E5
          PUSH HL                         ; $DECA E5
          PUSH HL                         ; $DECB E5
          OR A                            ; $DECC B7
          JR Z,$DED3                      ; $DECD 28 04
          XOR E                           ; $DECF AB
          CP C                            ; $DED0 B9
          JR Z,$DED8                      ; $DED1 28 05
          DEC HL                          ; $DED3 2B
          DJNZ $DECB                      ; $DED4 10 F5
          JR $DEF9                        ; $DED6 18 21
          LD DE,$000B                     ; $DED8 11 0B 00
          ADD HL,DE                       ; $DEDB 19
          LD A,(HL)                       ; $DEDC 7E
          OR A                            ; $DEDD B7
          LD C,A                          ; $DEDE 4F
          JP P,$DC23                      ; $DEDF F2 23 DC
          AND $7F                         ; $DEE2 E6 7F
          LD C,A                          ; $DEE4 4F
          PUSH BC                         ; $DEE5 C5
          LD A,($F3A2)                    ; $DEE6 3A A2 F3
          LD B,$07                        ; $DEE9 06 07
          CALL $DBDD                      ; $DEEB CD DD DB
          POP BC                          ; $DEEE C1
          LD A,B                          ; $DEEF 78
          CP $07                          ; $DEF0 FE 07
          JR NZ,$DEF9                     ; $DEF2 20 05
          LD A,$02                        ; $DEF4 3E 02
          LD ($DEA3),A                    ; $DEF6 32 A3 DE
          XOR A                           ; $DEF9 AF
          LD ($DEA4),A                    ; $DEFA 32 A4 DE
          LD A,($DEA2)                    ; $DEFD 3A A2 DE
          OR A                            ; $DF00 B7
          LD HL,($F388)                   ; $DF01 2A 88 F3
          JR Z,$DF09                      ; $DF04 28 03
          LD HL,($F386)                   ; $DF06 2A 86 F3
          JP (HL)                         ; $DF09 E9
          LD DE,$0003                     ; $DF0A 11 03 00
          JP $DC44                        ; $DF0D C3 44 DC
          LD HL,($DEA5)                   ; $DF10 2A A5 DE
          LD A,($DEA7)                    ; $DF13 3A A7 DE
          LD (HL),A                       ; $DF16 77
          CALL $DC6B                      ; $DF17 CD 6B DC
          LD HL,($F028)                   ; $DF1A 2A 28 F0
          LD A,($F024)                    ; $DF1D 3A 24 F0
          LD E,A                          ; $DF20 5F
          LD D,$F0                        ; $DF21 16 F0
          ADD HL,DE                       ; $DF23 19
          LD ($DEA5),HL                   ; $DF24 22 A5 DE
          LD A,(HL)                       ; $DF27 7E
          LD ($DEA7),A                    ; $DF28 32 A7 DE
          CP $E0                          ; $DF2B FE E0
          JR C,$DF31                      ; $DF2D 38 02
          XOR $20                         ; $DF2F EE 20
          AND $3F                         ; $DF31 E6 3F
          OR $40                          ; $DF33 F6 40
          LD (HL),A                       ; $DF35 77
          RET                             ; $DF36 C9
          LD A,B                          ; $DF37 78
          OR A                            ; $DF38 B7
          JR Z,$DF46                      ; $DF39 28 0B
          LD HL,$DB3B                     ; $DF3B 21 3B DB
          PUSH HL                         ; $DF3E E5
          LD HL,$DCD4                     ; $DF3F 21 D4 DC
          ADD A,L                         ; $DF42 85
          LD L,A                          ; $DF43 6F
          LD L,(HL)                       ; $DF44 6E
          JP (HL)                         ; $DF45 E9
          LD A,C                          ; $DF46 79
          CP $0D                          ; $DF47 FE 0D
          JR NZ,$DF50                     ; $DF49 20 05
          XOR A                           ; $DF4B AF
          LD ($F024),A                    ; $DF4C 32 24 F0
          RET                             ; $DF4F C9
          OR $80                          ; $DF50 F6 80
          CP $E0                          ; $DF52 FE E0
          JR C,$DF5A                      ; $DF54 38 04
          LD HL,$F3DD                     ; $DF56 21 DD F3
          XOR (HL)                        ; $DF59 AE
          LD ($F045),A                    ; $DF5A 32 45 F0
          LD HL,$FDF0                     ; $DF5D 21 F0 FD
          JR $DFDB                        ; $DF60 18 79
          LD A,$FF                        ; $DF62 3E FF
          LD BC,$3F3E                     ; $DF64 01 3E 3F
          LD ($F032),A                    ; $DF67 32 32 F0
          POP HL                          ; $DF6A E1
          RET                             ; $DF6B C9
          LD HL,$FBF4                     ; $DF6C 21 F4 FB
          RET                             ; $DF6F C9
          XOR A                           ; $DF70 AF
          LD L,A                          ; $DF71 6F
          LD H,A                          ; $DF72 67
          LD ($F024),HL                   ; $DF73 22 24 F0
          LD ($F045),A                    ; $DF76 32 45 F0
          LD HL,$FBC1                     ; $DF79 21 C1 FB
          RET                             ; $DF7C C9
          LD L,$42                        ; $DF7D 2E 42
          LD BC,$9C2E                     ; $DF7F 01 2E 9C
          LD BC,$1A2E                     ; $DF82 01 2E 1A
          LD BC,$582E                     ; $DF85 01 2E 58
          LD H,$FC                        ; $DF88 26 FC
          RET                             ; $DF8A C9
          LD HL,($DEAA)                   ; $DF8B 2A AA DE
          LD A,L                          ; $DF8E 7D
          CP $28                          ; $DF8F FE 28
          JR C,$DF95                      ; $DF91 38 02
          LD L,$00                        ; $DF93 2E 00
          LD A,H                          ; $DF95 7C
          CP $18                          ; $DF96 FE 18
          JR C,$DF9C                      ; $DF98 38 02
          LD H,$00                        ; $DF9A 26 00
          LD ($F024),HL                   ; $DF9C 22 24 F0
          JR $DF76                        ; $DF9F 18 D5
          CP D                            ; $DFA1 BA
          OR C                            ; $DFA2 B1
          OR H                            ; $DFA3 B4
          SUB (HL)                        ; $DFA4 96
          SBC A,C                         ; $DFA5 99
          AND H                           ; $DFA6 A4
          SBC A,(HL)                      ; $DFA7 9E
          OR A                            ; $DFA8 B7
          AND B                           ; $DFA9 A0
          CP A                            ; $DFAA BF
          CALL $DD60                      ; $DFAB CD 60 DD
          LD A,(HL)                       ; $DFAE 7E
          AND $02                         ; $DFAF E6 02
          JR Z,$DFAE                      ; $DFB1 28 FB
          INC L                           ; $DFB3 2C
          LD (HL),C                       ; $DFB4 71
          RET                             ; $DFB5 C9
          LD A,C                          ; $DFB6 79
          LD ($F045),A                    ; $DFB7 32 45 F0
          CALL $DD5B                      ; $DFBA CD 5B DD
          LD ($F6F8),A                    ; $DFBD 32 F8 F6
          LD ($F047),A                    ; $DFC0 32 47 F0
          LD A,($EFFF)                    ; $DFC3 3A FF EF
          CALL $DAC5                      ; $DFC6 CD C5 DA
          SUB $20                         ; $DFC9 D6 20
          LD ($E5E5),A                    ; $DFCB 32 E5 E5
          PUSH HL                         ; $DFCE E5
          PUSH HL                         ; $DFCF E5
          PUSH HL                         ; $DFD0 E5
          PUSH HL                         ; $DFD1 E5
          PUSH HL                         ; $DFD2 E5
          PUSH HL                         ; $DFD3 E5
          PUSH HL                         ; $DFD4 E5
          PUSH HL                         ; $DFD5 E5
          PUSH HL                         ; $DFD6 E5
          PUSH HL                         ; $DFD7 E5
          PUSH HL                         ; $DFD8 E5
          PUSH HL                         ; $DFD9 E5
          PUSH HL                         ; $DFDA E5
          PUSH HL                         ; $DFDB E5
          PUSH HL                         ; $DFDC E5
          PUSH HL                         ; $DFDD E5
          PUSH HL                         ; $DFDE E5
          PUSH HL                         ; $DFDF E5
          PUSH HL                         ; $DFE0 E5
          PUSH HL                         ; $DFE1 E5
          PUSH HL                         ; $DFE2 E5
          PUSH HL                         ; $DFE3 E5
          PUSH HL                         ; $DFE4 E5
          PUSH HL                         ; $DFE5 E5
          PUSH HL                         ; $DFE6 E5
          PUSH HL                         ; $DFE7 E5
          PUSH HL                         ; $DFE8 E5
          PUSH HL                         ; $DFE9 E5
          PUSH HL                         ; $DFEA E5
          PUSH HL                         ; $DFEB E5
          PUSH HL                         ; $DFEC E5
          PUSH HL                         ; $DFED E5
          PUSH HL                         ; $DFEE E5
          PUSH HL                         ; $DFEF E5
          PUSH HL                         ; $DFF0 E5
          PUSH HL                         ; $DFF1 E5
          PUSH HL                         ; $DFF2 E5
          PUSH HL                         ; $DFF3 E5
          PUSH HL                         ; $DFF4 E5
          PUSH HL                         ; $DFF5 E5
          PUSH HL                         ; $DFF6 E5
          PUSH HL                         ; $DFF7 E5
          PUSH HL                         ; $DFF8 E5
          PUSH HL                         ; $DFF9 E5
          PUSH HL                         ; $DFFA E5
          PUSH HL                         ; $DFFB E5
          PUSH HL                         ; $DFFC E5
          PUSH HL                         ; $DFFD E5
          PUSH HL                         ; $DFFE E5
          PUSH HL                         ; $DFFF E5
          PUSH HL                         ; $E000 E5
          PUSH HL                         ; $E001 E5
          PUSH HL                         ; $E002 E5
          PUSH HL                         ; $E003 E5
          PUSH HL                         ; $E004 E5
          PUSH HL                         ; $E005 E5
          PUSH HL                         ; $E006 E5
          PUSH HL                         ; $E007 E5
          PUSH HL                         ; $E008 E5
          PUSH HL                         ; $E009 E5
          PUSH HL                         ; $E00A E5
          PUSH HL                         ; $E00B E5
          PUSH HL                         ; $E00C E5
          PUSH HL                         ; $E00D E5
          PUSH HL                         ; $E00E E5
          PUSH HL                         ; $E00F E5
          PUSH HL                         ; $E010 E5
          PUSH HL                         ; $E011 E5
          PUSH HL                         ; $E012 E5
          PUSH HL                         ; $E013 E5
          PUSH HL                         ; $E014 E5
          PUSH HL                         ; $E015 E5
          PUSH HL                         ; $E016 E5
          PUSH HL                         ; $E017 E5
          PUSH HL                         ; $E018 E5
          PUSH HL                         ; $E019 E5
          PUSH HL                         ; $E01A E5
          PUSH HL                         ; $E01B E5
          PUSH HL                         ; $E01C E5
          PUSH HL                         ; $E01D E5
          PUSH HL                         ; $E01E E5
          PUSH HL                         ; $E01F E5
          PUSH HL                         ; $E020 E5
          PUSH HL                         ; $E021 E5
          PUSH HL                         ; $E022 E5
          PUSH HL                         ; $E023 E5
          PUSH HL                         ; $E024 E5
          PUSH HL                         ; $E025 E5
          PUSH HL                         ; $E026 E5
          PUSH HL                         ; $E027 E5
          PUSH HL                         ; $E028 E5
          PUSH HL                         ; $E029 E5
          PUSH HL                         ; $E02A E5
          PUSH HL                         ; $E02B E5
          PUSH HL                         ; $E02C E5
          PUSH HL                         ; $E02D E5
          PUSH HL                         ; $E02E E5
          PUSH HL                         ; $E02F E5
          PUSH HL                         ; $E030 E5
          PUSH HL                         ; $E031 E5
          PUSH HL                         ; $E032 E5
          PUSH HL                         ; $E033 E5
          PUSH HL                         ; $E034 E5
          PUSH HL                         ; $E035 E5
          PUSH HL                         ; $E036 E5
          PUSH HL                         ; $E037 E5
          PUSH HL                         ; $E038 E5
          PUSH HL                         ; $E039 E5
          PUSH HL                         ; $E03A E5
          PUSH HL                         ; $E03B E5
          PUSH HL                         ; $E03C E5
          PUSH HL                         ; $E03D E5
          PUSH HL                         ; $E03E E5
          PUSH HL                         ; $E03F E5
          PUSH HL                         ; $E040 E5
          PUSH HL                         ; $E041 E5
          PUSH HL                         ; $E042 E5
          PUSH HL                         ; $E043 E5
          PUSH HL                         ; $E044 E5
          PUSH HL                         ; $E045 E5
          PUSH HL                         ; $E046 E5
          PUSH HL                         ; $E047 E5
          PUSH HL                         ; $E048 E5
          PUSH HL                         ; $E049 E5
          PUSH HL                         ; $E04A E5
          PUSH HL                         ; $E04B E5
          PUSH HL                         ; $E04C E5
          PUSH HL                         ; $E04D E5
          PUSH HL                         ; $E04E E5
          PUSH HL                         ; $E04F E5
          PUSH HL                         ; $E050 E5
          PUSH HL                         ; $E051 E5
          PUSH HL                         ; $E052 E5
          PUSH HL                         ; $E053 E5
          PUSH HL                         ; $E054 E5
          PUSH HL                         ; $E055 E5
          PUSH HL                         ; $E056 E5
          PUSH HL                         ; $E057 E5
          PUSH HL                         ; $E058 E5
          PUSH HL                         ; $E059 E5
          PUSH HL                         ; $E05A E5
          PUSH HL                         ; $E05B E5
          PUSH HL                         ; $E05C E5
          PUSH HL                         ; $E05D E5
          PUSH HL                         ; $E05E E5
          PUSH HL                         ; $E05F E5
          PUSH HL                         ; $E060 E5
          PUSH HL                         ; $E061 E5
          PUSH HL                         ; $E062 E5
          PUSH HL                         ; $E063 E5
          PUSH HL                         ; $E064 E5
          PUSH HL                         ; $E065 E5
          PUSH HL                         ; $E066 E5
          PUSH HL                         ; $E067 E5
          PUSH HL                         ; $E068 E5
          PUSH HL                         ; $E069 E5
          PUSH HL                         ; $E06A E5
          PUSH HL                         ; $E06B E5
          PUSH HL                         ; $E06C E5
          PUSH HL                         ; $E06D E5
          PUSH HL                         ; $E06E E5
          PUSH HL                         ; $E06F E5
          PUSH HL                         ; $E070 E5
          PUSH HL                         ; $E071 E5
          PUSH HL                         ; $E072 E5
          PUSH HL                         ; $E073 E5
          PUSH HL                         ; $E074 E5
          PUSH HL                         ; $E075 E5
          PUSH HL                         ; $E076 E5
          PUSH HL                         ; $E077 E5
          PUSH HL                         ; $E078 E5
          PUSH HL                         ; $E079 E5
          PUSH HL                         ; $E07A E5
          PUSH HL                         ; $E07B E5
          PUSH HL                         ; $E07C E5
          PUSH HL                         ; $E07D E5
          PUSH HL                         ; $E07E E5
          PUSH HL                         ; $E07F E5
          PUSH HL                         ; $E080 E5
          PUSH HL                         ; $E081 E5
          PUSH HL                         ; $E082 E5
          PUSH HL                         ; $E083 E5
          PUSH HL                         ; $E084 E5
          PUSH HL                         ; $E085 E5
          PUSH HL                         ; $E086 E5
          PUSH HL                         ; $E087 E5
          PUSH HL                         ; $E088 E5
          PUSH HL                         ; $E089 E5
          PUSH HL                         ; $E08A E5
          PUSH HL                         ; $E08B E5
          PUSH HL                         ; $E08C E5
          PUSH HL                         ; $E08D E5
          PUSH HL                         ; $E08E E5
          PUSH HL                         ; $E08F E5
          PUSH HL                         ; $E090 E5
          PUSH HL                         ; $E091 E5
          PUSH HL                         ; $E092 E5
          PUSH HL                         ; $E093 E5
          PUSH HL                         ; $E094 E5
          PUSH HL                         ; $E095 E5
          PUSH HL                         ; $E096 E5
          PUSH HL                         ; $E097 E5
          PUSH HL                         ; $E098 E5
          PUSH HL                         ; $E099 E5
          PUSH HL                         ; $E09A E5
          PUSH HL                         ; $E09B E5
          PUSH HL                         ; $E09C E5
          PUSH HL                         ; $E09D E5
          PUSH HL                         ; $E09E E5
          PUSH HL                         ; $E09F E5
          PUSH HL                         ; $E0A0 E5
          PUSH HL                         ; $E0A1 E5
          PUSH HL                         ; $E0A2 E5
          PUSH HL                         ; $E0A3 E5
          PUSH HL                         ; $E0A4 E5
          PUSH HL                         ; $E0A5 E5
          PUSH HL                         ; $E0A6 E5
          PUSH HL                         ; $E0A7 E5
          PUSH HL                         ; $E0A8 E5
          PUSH HL                         ; $E0A9 E5
          PUSH HL                         ; $E0AA E5
          PUSH HL                         ; $E0AB E5
          PUSH HL                         ; $E0AC E5
          PUSH HL                         ; $E0AD E5
          PUSH HL                         ; $E0AE E5
          PUSH HL                         ; $E0AF E5
          PUSH HL                         ; $E0B0 E5
          PUSH HL                         ; $E0B1 E5
          PUSH HL                         ; $E0B2 E5
          PUSH HL                         ; $E0B3 E5
          PUSH HL                         ; $E0B4 E5
          PUSH HL                         ; $E0B5 E5
          PUSH HL                         ; $E0B6 E5
          PUSH HL                         ; $E0B7 E5
          PUSH HL                         ; $E0B8 E5
          PUSH HL                         ; $E0B9 E5
          PUSH HL                         ; $E0BA E5
          PUSH HL                         ; $E0BB E5
          PUSH HL                         ; $E0BC E5
          PUSH HL                         ; $E0BD E5
          PUSH HL                         ; $E0BE E5
          PUSH HL                         ; $E0BF E5
          PUSH HL                         ; $E0C0 E5
          PUSH HL                         ; $E0C1 E5
          PUSH HL                         ; $E0C2 E5
          PUSH HL                         ; $E0C3 E5
          PUSH HL                         ; $E0C4 E5
          PUSH HL                         ; $E0C5 E5
          PUSH HL                         ; $E0C6 E5
          PUSH HL                         ; $E0C7 E5
          PUSH HL                         ; $E0C8 E5
          PUSH HL                         ; $E0C9 E5
          PUSH HL                         ; $E0CA E5
          PUSH HL                         ; $E0CB E5
          LD B,(HL)                       ; $E0CC 46
          RET P                           ; $E0CD F0
          LD A,(HL)                       ; $E0CE 7E
          RET                             ; $E0CF C9
          CALL $DCEA                      ; $E0D0 CD EA DC
          LD HL,$F678                     ; $E0D3 21 78 F6
          ADD HL,DE                       ; $E0D6 19
          LD (HL),C                       ; $E0D7 71
          LD HL,$C9AA                     ; $E0D8 21 AA C9
          JP $DB3B                        ; $E0DB C3 3B DB
          CALL $DD60                      ; $E0DE CD 60 DD
          LD A,(HL)                       ; $E0E1 7E
          RRA                             ; $E0E2 1F
          JR NC,$E0E1                     ; $E0E3 30 FC
          INC L                           ; $E0E5 2C
          LD A,(HL)                       ; $E0E6 7E
          RET                             ; $E0E7 C9
          CALL $DCEE                      ; $E0E8 CD EE DC
          LD HL,$C84D                     ; $E0EB 21 4D C8
          CALL $DB3B                      ; $E0EE CD 3B DB
          LD HL,$F678                     ; $E0F1 21 78 F6
          ADD HL,DE                       ; $E0F4 19
          LD A,(HL)                       ; $E0F5 7E
          RET                             ; $E0F6 C9
          LD DE,$0001                     ; $E0F7 11 01 00
          JP $DD3E                        ; $E0FA C3 3E DD
          CALL $DAC5                      ; $E0FD CD C5 DA
          LD L,$C1                        ; $E100 2E C1
          LD A,(HL)                       ; $E102 7E
          RLA                             ; $E103 17
          JR C,$E102                      ; $E104 38 FC
          CALL $DD5B                      ; $E106 CD 5B DD
          LD (HL),C                       ; $E109 71
          RET                             ; $E10A C9
          LD DE,$0002                     ; $E10B 11 02 00
          JP $DD3E                        ; $E10E C3 3E DD
          LD DE,$0002                     ; $E111 11 02 00
          JP $0000                        ; $E114 C3 00 00
          LD A,($DEB0)                    ; $E117 3A B0 DE
          OR A                            ; $E11A B7
          JR NZ,$E120                     ; $E11B 20 03
          LD ($DEAF),A                    ; $E11D 32 AF DE
          LD C,$00                        ; $E120 0E 00
          LD A,C                          ; $E122 79
          LD ($DEA8),A                    ; $E123 32 A8 DE
          RET                             ; $E126 C9
          LD HL,$E080                     ; $E127 21 80 E0
          JR $E12F                        ; $E12A 18 03
          LD HL,$E08E                     ; $E12C 21 8E E0
          LD A,E                          ; $E12F 7B
          ADD A,A                         ; $E130 87
          ADD A,A                         ; $E131 87
          ADD A,A                         ; $E132 87
          ADD A,A                         ; $E133 87
          PUSH AF                         ; $E134 F5
          ADD A,L                         ; $E135 85
          LD L,A                          ; $E136 6F
          POP AF                          ; $E137 F1
          RET                             ; $E138 C9
          LD DE,$DEAC                     ; $E139 11 AC DE
          LD HL,$0004                     ; $E13C 21 04 00
          LD A,($F3B8)                    ; $E13F 3A B8 F3
          DEC A                           ; $E142 3D
          CP C                            ; $E143 B9
          JR C,$E150                      ; $E144 38 0A
          LD A,(HL)                       ; $E146 7E
          LD (DE),A                       ; $E147 12
          INC DE                          ; $E148 13
          LD A,C                          ; $E149 79
          LD (DE),A                       ; $E14A 12
          LD HL,$DA33                     ; $E14B 21 33 DA
          JR $E130                        ; $E14E 18 E0
          LD A,(DE)                       ; $E150 1A
          LD (HL),A                       ; $E151 77
          LD L,$00                        ; $E152 2E 00
          RET                             ; $E154 C9
          LD A,C                          ; $E155 79
          LD ($DEA9),A                    ; $E156 32 A9 DE
          RET                             ; $E159 C9
          DB $ED                          ; $E15A ED
          LD B,E                          ; $E15B 43
          CP B                            ; $E15C B8
          SBC A,$C9                       ; $E15D DE C9
          XOR A                           ; $E15F AF
          LD ($DEB4),A                    ; $E160 32 B4 DE
          LD A,$02                        ; $E163 3E 02
          LD HL,$DEB1                     ; $E165 21 B1 DE
          LD (HL),A                       ; $E168 77
          INC HL                          ; $E169 23
          LD (HL),A                       ; $E16A 77
          INC HL                          ; $E16B 23
          LD (HL),A                       ; $E16C 77
          JR $E1BE                        ; $E16D 18 4F
          LD H,C                          ; $E16F 61
          LD L,$00                        ; $E170 2E 00
          LD ($DEB1),HL                   ; $E172 22 B1 DE
          LD A,C                          ; $E175 79
          CP $02                          ; $E176 FE 02
          JR NZ,$E189                     ; $E178 20 0F
          LD L,$08                        ; $E17A 2E 08
          LD A,($DEAD)                    ; $E17C 3A AD DE
          LD H,A                          ; $E17F 67
          LD ($DEB4),HL                   ; $E180 22 B4 DE
          LD HL,($DEA8)                   ; $E183 2A A8 DE
          LD ($DEB6),HL                   ; $E186 22 B6 DE
          LD HL,$DEB4                     ; $E189 21 B4 DE
          LD A,(HL)                       ; $E18C 7E
          OR A                            ; $E18D B7
          JR Z,$E1B8                      ; $E18E 28 28
          DEC (HL)                        ; $E190 35
          LD A,($DEAD)                    ; $E191 3A AD DE
          INC HL                          ; $E194 23
          CP (HL)                         ; $E195 BE
          JR NZ,$E1B8                     ; $E196 20 20
          LD A,($DEA8)                    ; $E198 3A A8 DE
          LD HL,($DEB6)                   ; $E19B 2A B6 DE
          CP L                            ; $E19E BD
          JR NZ,$E1B8                     ; $E19F 20 17
          LD A,($DEA9)                    ; $E1A1 3A A9 DE
          CP H                            ; $E1A4 BC
          JR NZ,$E1B8                     ; $E1A5 20 11
          INC H                           ; $E1A7 24
          LD A,H                          ; $E1A8 7C
          SUB $20                         ; $E1A9 D6 20
          JR C,$E1AF                      ; $E1AB 38 02
          LD H,A                          ; $E1AD 67
          INC L                           ; $E1AE 2C
          LD ($DEB6),HL                   ; $E1AF 22 B6 DE
          XOR A                           ; $E1B2 AF
          LD ($DEB3),A                    ; $E1B3 32 B3 DE
          JR $E1BE                        ; $E1B6 18 06
          LD HL,$0001                     ; $E1B8 21 01 00
          LD ($DEB3),HL                   ; $E1BB 22 B3 DE
          CALL $DFF0                      ; $E1BE CD F0 DF
          LD E,A                          ; $E1C1 5F
          RRA                             ; $E1C2 1F
          LD HL,$DE92                     ; $E1C3 21 92 DE
          ADD A,L                         ; $E1C6 85
          LD L,A                          ; $E1C7 6F
          LD C,(HL)                       ; $E1C8 4E
          LD HL,$DEAF                     ; $E1C9 21 AF DE
          PUSH HL                         ; $E1CC E5
          PUSH HL                         ; $E1CD E5
          PUSH HL                         ; $E1CE E5
          PUSH HL                         ; $E1CF E5
          PUSH HL                         ; $E1D0 E5
          PUSH HL                         ; $E1D1 E5
          PUSH HL                         ; $E1D2 E5
          PUSH HL                         ; $E1D3 E5
          PUSH HL                         ; $E1D4 E5
          PUSH HL                         ; $E1D5 E5
          PUSH HL                         ; $E1D6 E5
          PUSH HL                         ; $E1D7 E5
          PUSH HL                         ; $E1D8 E5
          PUSH HL                         ; $E1D9 E5
          PUSH HL                         ; $E1DA E5
          PUSH HL                         ; $E1DB E5
          PUSH HL                         ; $E1DC E5
          PUSH HL                         ; $E1DD E5
          PUSH HL                         ; $E1DE E5
          PUSH HL                         ; $E1DF E5
          PUSH HL                         ; $E1E0 E5
          PUSH HL                         ; $E1E1 E5
          PUSH HL                         ; $E1E2 E5
          PUSH HL                         ; $E1E3 E5
          PUSH HL                         ; $E1E4 E5
          PUSH HL                         ; $E1E5 E5
          PUSH HL                         ; $E1E6 E5
          PUSH HL                         ; $E1E7 E5
          PUSH HL                         ; $E1E8 E5
          PUSH HL                         ; $E1E9 E5
          PUSH HL                         ; $E1EA E5
          PUSH HL                         ; $E1EB E5
          PUSH HL                         ; $E1EC E5
          PUSH HL                         ; $E1ED E5
          PUSH HL                         ; $E1EE E5
          PUSH HL                         ; $E1EF E5
          PUSH HL                         ; $E1F0 E5
          PUSH HL                         ; $E1F1 E5
          PUSH HL                         ; $E1F2 E5
          PUSH HL                         ; $E1F3 E5
          PUSH HL                         ; $E1F4 E5
          PUSH HL                         ; $E1F5 E5
          PUSH HL                         ; $E1F6 E5
          PUSH HL                         ; $E1F7 E5
          PUSH HL                         ; $E1F8 E5
          PUSH HL                         ; $E1F9 E5
          PUSH HL                         ; $E1FA E5
          PUSH HL                         ; $E1FB E5
          PUSH HL                         ; $E1FC E5
          PUSH HL                         ; $E1FD E5
          PUSH HL                         ; $E1FE E5
          PUSH HL                         ; $E1FF E5
          PUSH HL                         ; $E200 E5
          PUSH HL                         ; $E201 E5
          PUSH HL                         ; $E202 E5
          PUSH HL                         ; $E203 E5
          PUSH HL                         ; $E204 E5
          PUSH HL                         ; $E205 E5
          PUSH HL                         ; $E206 E5
          PUSH HL                         ; $E207 E5
          PUSH HL                         ; $E208 E5
          PUSH HL                         ; $E209 E5
          PUSH HL                         ; $E20A E5
          PUSH HL                         ; $E20B E5
          PUSH HL                         ; $E20C E5
          PUSH HL                         ; $E20D E5
          PUSH HL                         ; $E20E E5
          PUSH HL                         ; $E20F E5
          PUSH HL                         ; $E210 E5
          PUSH HL                         ; $E211 E5
          PUSH HL                         ; $E212 E5
          PUSH HL                         ; $E213 E5
          PUSH HL                         ; $E214 E5
          PUSH HL                         ; $E215 E5
          PUSH HL                         ; $E216 E5
          PUSH HL                         ; $E217 E5
          PUSH HL                         ; $E218 E5
          PUSH HL                         ; $E219 E5
          PUSH HL                         ; $E21A E5
          PUSH HL                         ; $E21B E5
          PUSH HL                         ; $E21C E5
          PUSH HL                         ; $E21D E5
          PUSH HL                         ; $E21E E5
          PUSH HL                         ; $E21F E5
          PUSH HL                         ; $E220 E5
          PUSH HL                         ; $E221 E5
          PUSH HL                         ; $E222 E5
          PUSH HL                         ; $E223 E5
          PUSH HL                         ; $E224 E5
          PUSH HL                         ; $E225 E5
          PUSH HL                         ; $E226 E5
          PUSH HL                         ; $E227 E5
          PUSH HL                         ; $E228 E5
          PUSH HL                         ; $E229 E5
          PUSH HL                         ; $E22A E5
          PUSH HL                         ; $E22B E5
          PUSH HL                         ; $E22C E5
          PUSH HL                         ; $E22D E5
          PUSH HL                         ; $E22E E5
          PUSH HL                         ; $E22F E5
          PUSH HL                         ; $E230 E5
          PUSH HL                         ; $E231 E5
          PUSH HL                         ; $E232 E5
          PUSH HL                         ; $E233 E5
          PUSH HL                         ; $E234 E5
          PUSH HL                         ; $E235 E5
          PUSH HL                         ; $E236 E5
          PUSH HL                         ; $E237 E5
          PUSH HL                         ; $E238 E5
          PUSH HL                         ; $E239 E5
          PUSH HL                         ; $E23A E5
          PUSH HL                         ; $E23B E5
          PUSH HL                         ; $E23C E5
          PUSH HL                         ; $E23D E5
          PUSH HL                         ; $E23E E5
          PUSH HL                         ; $E23F E5
          PUSH HL                         ; $E240 E5
          PUSH HL                         ; $E241 E5
          PUSH HL                         ; $E242 E5
          PUSH HL                         ; $E243 E5
          PUSH HL                         ; $E244 E5
          PUSH HL                         ; $E245 E5
          PUSH HL                         ; $E246 E5
          PUSH HL                         ; $E247 E5
          PUSH HL                         ; $E248 E5
          PUSH HL                         ; $E249 E5
          PUSH HL                         ; $E24A E5
          PUSH HL                         ; $E24B E5
          PUSH HL                         ; $E24C E5
          PUSH HL                         ; $E24D E5
          PUSH HL                         ; $E24E E5
          PUSH HL                         ; $E24F E5
          PUSH HL                         ; $E250 E5
          PUSH HL                         ; $E251 E5
          PUSH HL                         ; $E252 E5
          PUSH HL                         ; $E253 E5
          PUSH HL                         ; $E254 E5
          PUSH HL                         ; $E255 E5
          PUSH HL                         ; $E256 E5
          PUSH HL                         ; $E257 E5
          PUSH HL                         ; $E258 E5
          PUSH HL                         ; $E259 E5
          PUSH HL                         ; $E25A E5
          PUSH HL                         ; $E25B E5
          PUSH HL                         ; $E25C E5
          PUSH HL                         ; $E25D E5
          PUSH HL                         ; $E25E E5
          PUSH HL                         ; $E25F E5
          PUSH HL                         ; $E260 E5
          PUSH HL                         ; $E261 E5
          PUSH HL                         ; $E262 E5
          PUSH HL                         ; $E263 E5
          PUSH HL                         ; $E264 E5
          PUSH HL                         ; $E265 E5
          PUSH HL                         ; $E266 E5
          PUSH HL                         ; $E267 E5
          PUSH HL                         ; $E268 E5
          PUSH HL                         ; $E269 E5
          PUSH HL                         ; $E26A E5
          PUSH HL                         ; $E26B E5
          PUSH HL                         ; $E26C E5
          PUSH HL                         ; $E26D E5
          PUSH HL                         ; $E26E E5
          PUSH HL                         ; $E26F E5
          PUSH HL                         ; $E270 E5
          PUSH HL                         ; $E271 E5
          PUSH HL                         ; $E272 E5
          PUSH HL                         ; $E273 E5
          PUSH HL                         ; $E274 E5
          PUSH HL                         ; $E275 E5
          PUSH HL                         ; $E276 E5
          PUSH HL                         ; $E277 E5
          PUSH HL                         ; $E278 E5
          PUSH HL                         ; $E279 E5
          PUSH HL                         ; $E27A E5
          PUSH HL                         ; $E27B E5
          PUSH HL                         ; $E27C E5
          PUSH HL                         ; $E27D E5
          PUSH HL                         ; $E27E E5
          PUSH HL                         ; $E27F E5
          PUSH HL                         ; $E280 E5
          PUSH HL                         ; $E281 E5
          PUSH HL                         ; $E282 E5
          PUSH HL                         ; $E283 E5
          PUSH HL                         ; $E284 E5
          PUSH HL                         ; $E285 E5
          PUSH HL                         ; $E286 E5
          PUSH HL                         ; $E287 E5
          PUSH HL                         ; $E288 E5
          PUSH HL                         ; $E289 E5
          PUSH HL                         ; $E28A E5
          PUSH HL                         ; $E28B E5
          PUSH HL                         ; $E28C E5
          PUSH HL                         ; $E28D E5
          PUSH HL                         ; $E28E E5
          PUSH HL                         ; $E28F E5
          PUSH HL                         ; $E290 E5
          PUSH HL                         ; $E291 E5
          PUSH HL                         ; $E292 E5
          PUSH HL                         ; $E293 E5
          PUSH HL                         ; $E294 E5
          PUSH HL                         ; $E295 E5
          PUSH HL                         ; $E296 E5
          PUSH HL                         ; $E297 E5
          PUSH HL                         ; $E298 E5
          PUSH HL                         ; $E299 E5
          PUSH HL                         ; $E29A E5
          PUSH HL                         ; $E29B E5
          PUSH HL                         ; $E29C E5
          PUSH HL                         ; $E29D E5
          PUSH HL                         ; $E29E E5
          PUSH HL                         ; $E29F E5
          PUSH HL                         ; $E2A0 E5
          PUSH HL                         ; $E2A1 E5
          PUSH HL                         ; $E2A2 E5
          PUSH HL                         ; $E2A3 E5
          PUSH HL                         ; $E2A4 E5
          PUSH HL                         ; $E2A5 E5
          PUSH HL                         ; $E2A6 E5
          PUSH HL                         ; $E2A7 E5
          PUSH HL                         ; $E2A8 E5
          PUSH HL                         ; $E2A9 E5
          PUSH HL                         ; $E2AA E5
          PUSH HL                         ; $E2AB E5
          PUSH HL                         ; $E2AC E5
          PUSH HL                         ; $E2AD E5
          PUSH HL                         ; $E2AE E5
          PUSH HL                         ; $E2AF E5
          PUSH HL                         ; $E2B0 E5
          PUSH HL                         ; $E2B1 E5
          PUSH HL                         ; $E2B2 E5
          PUSH HL                         ; $E2B3 E5
          PUSH HL                         ; $E2B4 E5
          PUSH HL                         ; $E2B5 E5
          PUSH HL                         ; $E2B6 E5
          PUSH HL                         ; $E2B7 E5
          PUSH HL                         ; $E2B8 E5
          PUSH HL                         ; $E2B9 E5
          PUSH HL                         ; $E2BA E5
          PUSH HL                         ; $E2BB E5
          PUSH HL                         ; $E2BC E5
          PUSH HL                         ; $E2BD E5
          PUSH HL                         ; $E2BE E5
          PUSH HL                         ; $E2BF E5
          PUSH HL                         ; $E2C0 E5
          PUSH HL                         ; $E2C1 E5
          PUSH HL                         ; $E2C2 E5
          PUSH HL                         ; $E2C3 E5
          PUSH HL                         ; $E2C4 E5
          PUSH HL                         ; $E2C5 E5
          PUSH HL                         ; $E2C6 E5
          PUSH HL                         ; $E2C7 E5
          PUSH HL                         ; $E2C8 E5
          PUSH HL                         ; $E2C9 E5
          PUSH HL                         ; $E2CA E5
          DEFB    $E5                     ; $E2CB (trailing byte; loose half of next PUSH)


; ============================================================================
; END OF BIOS ($E2CB)
;
; Z-80 reset vector at $0000 was planted by the 6502 as "JP $DA00".
; $DA00 is below this BIOS (in a runtime-generated region 204 bytes
; long, $DA00-$DACB). Cold-boot setup rewrites the reset vector to
; "JP $DA03" for warm-boot use.
;
; The cold-boot setup plants the BDOS call vector at $0005-$0007:
;   $0005: $C3 (JP opcode)
;   $0006-$0007: $CC06 (BDOS entry after relocation)
; ============================================================================

    SAVEBIN "build/CPM220_BIOS.bin", $DACC, $0800
