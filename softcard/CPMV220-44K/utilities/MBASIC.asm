; MBASIC.COM -- Microsoft BASIC-80 Rev 5.2 interpreter (graphics OFF), SoftCard CP/M 2.20 (44K).
; Clean-slate disassembly of the MBASIC.COM bytes on the 2.20-44K system disk; reassembles
; byte-identically.  Range: $0100-$60FF (24576 bytes).  MBASIC runs IN PLACE at $0100 (entry
; $0100 = JP $5E51 cold start); it is the graphics-OFF build of the same engine as GBASIC,
; so the graphics tokens dispatch to a 'Graphics statement not implemented' error stub.

    DEVICE NOSLOT64K

    ORG $0100

SUB_0100:
        JP SUB_5E51                      ; $0100  C3 51 5E
SUB_0100_1:
        CALL P,SUB_552B                  ; $0103  F4 2B 55
SUB_0100_2:
        INC L                            ; $0106  2C
SUB_0100_3:
        NOP                              ; $0107  00
SUB_0100_4:
        CALL NC,$AA45                    ; $0108  D4 45 AA
        LD (DE),A                        ; $010B  12
        LD D,B                           ; $010C  50
        LD B,A                           ; $010D  47
        RST $08                          ; $010E  CF
        DEC D                            ; $010F  15
        INC DE                           ; $0110  13
        ADD HL,DE                        ; $0111  19
        XOR (HL)                         ; $0112  AE
        DEC SP                           ; $0113  3B
SUB_0100_5:
        JP NC,$F619                      ; $0114  D2 19 F6
        DEC D                            ; $0117  15
SUB_0100_6:
        LD H,B                           ; $0118  60
        DEC D                            ; $0119  15
        INC (HL)                         ; $011A  34
        DEC D                            ; $011B  15
        RRA                              ; $011C  1F
        RLA                              ; $011D  17
SUB_0100_7:
        OR L                             ; $011E  B5
        LD B,L                           ; $011F  45
        LD C,B                           ; $0120  48
        DEC D                            ; $0121  15
        OR H                             ; $0122  B4
        DEC D                            ; $0123  15
        POP DE                           ; $0124  D1
        DEC D                            ; $0125  15
        RST $08                          ; $0126  CF
        LD B,L                           ; $0127  45
SUB_0100_8:
        LD H,L                           ; $0128  65
        RLA                              ; $0129  17
        ADD A,$46                        ; $012A  C6 46
SUB_0100_9:
        ADD A,$20                        ; $012C  C6 20
        CALL P,SUB_5D26_5+2              ; $012E  F4 44 5D
        LD D,$A1                         ; $0131  16 A1
        LD E,$CC                         ; $0133  1E CC
        LD (SUB_4610_2),HL               ; $0135  22 29 46
        SUB D                            ; $0138  92
        DEC C                            ; $0139  0D
        SUB D                            ; $013A  92
SUB_0100_10:
        DEC C                            ; $013B  0D
        LD E,L                           ; $013C  5D
        RLA                              ; $013D  17
SUB_0100_11:
        POP BC                           ; $013E  C1
SUB_0100_12:
        JR NZ,SUB_0100_14                ; $013F  20 62
        JR NZ,SUB_0100_5                 ; $0141  20 D1
        DEC D                            ; $0143  15
        DEC A                            ; $0144  3D
SUB_0100_13:
        LD B,(HL)                        ; $0145  46
        LD A,$46                         ; $0146  3E 46
        LD B,E                           ; $0148  43
        LD B,(HL)                        ; $0149  46
        ADD A,C                          ; $014A  81
        LD B,(HL)                        ; $014B  46
        RET PE                           ; $014C  E8
        LD A,$E1                         ; $014D  3E E1
        LD D,$A7                         ; $014F  16 A7
        LD D,$8A                         ; $0151  16 8A
        LD (L_16EC),HL                   ; $0153  22 EC 16
        LD (SUB_1460_4),IY               ; $0156  FD 22 9F 14
        AND D                            ; $015A  A2
        INC D                            ; $015B  14
        AND L                            ; $015C  A5
        INC D                            ; $015D  14
        XOR B                            ; $015E  A8
        INC D                            ; $015F  14
        AND (HL)                         ; $0160  A6
        JR $00F9                         ; $0161  18 96
        DEFW    SUB_1C11_1+1             ; $0163
        DEFW    SUB_3D4E                 ; $0165
        DEFB    $4E,$AE                                          ; $0167
        DEFW    SUB_064E                 ; $0169
        DEFB    $52                                              ; $016B
        DEFW    SUB_15CF                 ; $016C
        DEFB    $37                                              ; $016E
        DEFW    SUB_2E4B_1+1             ; $016F
        DEFB    $24                                              ; $0171
        DEFW    SUB_2474_1               ; $0172
        DEFW    SUB_5A3B_4               ; $0174
        DEFB    $71                                              ; $0176
        DEFW    SUB_58FE_7+1             ; $0177
        DEFB    $55,$E0,$5B,$DF                                  ; $0179
        DEFW    SUB_1C11_4+1             ; $017D
        DEFB    $55,$FE,$53                                      ; $017F
        DEFW    SUB_5498_2               ; $0182
        DEFB    $B1                                              ; $0184
        DEFW    SUB_1E5A                 ; $0185
        DEFB    $59,$87,$5A,$BC,$55,$BB,$55,$E0,$54              ; $0187
        DEFW    SUB_5A3B_6               ; $0190
        DEFW    SUB_25D9                 ; $0192
        DEFW    SUB_25C3                 ; $0194
        DEFW    SUB_2554_1               ; $0196
        DEFB    $B2,$25,$CE,$25,$D1                              ; $0198
        DEFW    SUB_0925                 ; $019D
        DEFW    SUB_5D26                 ; $019F
        DEFB    $26,$93                                          ; $01A1
SUB_0100_14:
        LD H,$AA                         ; $01A3  26 AA
        LD H,$E1                         ; $01A5  26 E1
        LD H,$0F                         ; $01A7  26 0F
        JR Z,SUB_0100_16+2               ; $01A9  28 0F
        JR Z,SUB_0100_17                 ; $01AB  28 0F
        JR Z,SUB_0100_18                 ; $01AD  28 11
        DAA                              ; $01AF  27
        DEC A                            ; $01B0  3D
        DAA                              ; $01B1  27
SUB_0100_15:
        OUT ($4A),A                      ; $01B2  D3 4A
        INC BC                           ; $01B4  03
        LD C,E                           ; $01B5  4B
        INC C                            ; $01B6  0C
        LD C,E                           ; $01B7  4B
SUB_0100_16:
        CALL M,$F82A                     ; $01B8  FC 2A F8
        INC L                            ; $01BB  2C
SUB_0100_17:
        RST $20                          ; $01BC  E7
        LD HL,(SUB_3809_18)              ; $01BD  2A 0B 39
SUB_0100_18:
        JR SUB_0100_19                   ; $01C0  18 3A
        DEFB    $B8                                              ; $01C2
        DEFW    SUB_4A3A                 ; $01C3
        DEFB    $29                                              ; $01C5
        DEFW    SUB_3809_26              ; $01C6
        DEFB    $B2                                              ; $01C8
        DEFW    SUB_453A                 ; $01C9
        DEFW    SUB_5A3B                 ; $01CB
        DEFB    $3B,$71                                          ; $01CD
        DEFW    SUB_494C                 ; $01CF
        DEFB    $1E                                              ; $01D1
        DEFW    SUB_4A57_2               ; $01D2
        DEFB    $37                                              ; $01D4
        DEFW    SUB_2D48                 ; $01D5
        DEFB    $4B                                              ; $01D7
        DEFW    SUB_4A6B_2               ; $01D8
        DEFW    SUB_4A77_1               ; $01DA
        DEFW    SUB_22AF_2               ; $01DC
        DEFW    SUB_4A89_5               ; $01DE
        DEFW    SUB_475A_11              ; $01E0
        DEFB    $32                                              ; $01E2
        DEFW    SUB_4437_1+1             ; $01E3
        DEFB    $1E                                              ; $01E5
        DEFW    SUB_2BF4                 ; $01E6
        DEFW    SUB_2C6C                 ; $01E8
        DEFW    SUB_2C98                 ; $01EA
        DEFW    SUB_2CE3_1               ; $01EC
        DEFS    14, $00    ; $01EE  fill
SUB_0100_19:
        NOP                              ; $01FC  00
        NOP                              ; $01FD  00
        NOP                              ; $01FE  00
        NOP                              ; $01FF  00
SUB_0100_20:
        NOP                              ; $0200  00
        NOP                              ; $0201  00
        NOP                              ; $0202  00
        NOP                              ; $0203  00
        RET M                            ; $0204  F8
        LD D,D                           ; $0205  52
        EI                               ; $0206  FB
        LD D,D                           ; $0207  52
        CP $52                           ; $0208  FE 52
        NOP                              ; $020A  00
        NOP                              ; $020B  00
        RET Z                            ; $020C  C8
        LD D,(HL)                        ; $020D  56
SUB_0100_21:
        LD A,C                           ; $020E  79
        LD D,A                           ; $020F  57
        SUB B                            ; $0210  90
        LD D,A                           ; $0211  57
        RST $18                          ; $0212  DF
        LD D,D                           ; $0213  52
        JP PO,$E552                      ; $0214  E2 52 E5
        LD D,D                           ; $0217  52
        RLCA                             ; $0218  07
        DAA                              ; $0219  27
        LD E,(HL)                        ; $021A  5E
        DAA                              ; $021B  27
        DEFB $ED,$26  ; invalid ED prefix ; $021C  ED 26
        LD D,D                           ; $021E  52
        LD (BC),A                        ; $021F  02
SUB_0100_22:
        LD H,E                           ; $0220  63
SUB_0100_23:
        LD (BC),A                        ; $0221  02
        LD L,(HL)                        ; $0222  6E
        LD (BC),A                        ; $0223  02
        XOR L                            ; $0224  AD
        LD (BC),A                        ; $0225  02
        EXX                              ; $0226  D9
        LD (BC),A                        ; $0227  02
        CP $02                           ; $0228  FE 02
        INC D                            ; $022A  14
        INC BC                           ; $022B  03
        JR Z,SUB_0100_24                 ; $022C  28 03
        LD C,H                           ; $022E  4C
        INC BC                           ; $022F  03
        LD L,H                           ; $0230  6C
SUB_0100_24:
        INC BC                           ; $0231  03
        LD L,L                           ; $0232  6D
        INC BC                           ; $0233  03
        LD (HL),D                        ; $0234  72
        INC BC                           ; $0235  03
        AND (HL)                         ; $0236  A6
        INC BC                           ; $0237  03
SUB_0100_25:
        CP A                             ; $0238  BF
        INC BC                           ; $0239  03
        IN A,($03)                       ; $023A  DB 03
        XOR $03                          ; $023C  EE 03
SUB_0100_26:
        INC C                            ; $023E  0C
        INC B                            ; $023F  04
        DEC C                            ; $0240  0D
        INC B                            ; $0241  04
        LD C,E                           ; $0242  4B
        INC B                            ; $0243  04
        ADD A,H                          ; $0244  84
        INC B                            ; $0245  04
        SBC A,E                          ; $0246  9B
        INC B                            ; $0247  04
        AND H                            ; $0248  A4
        INC B                            ; $0249  04
        CP D                             ; $024A  BA
        INC B                            ; $024B  04
        JP NC,$D604                      ; $024C  D2 04 D6
        INC B                            ; $024F  04
        RST $10                          ; $0250  D7
SUB_0100_27:
        INC B                            ; $0251  04
        LD C,(HL)                        ; $0252  4E
        CALL NZ,SUB_42F7                 ; $0253  C4 F7 42
        OUT ($06),A                      ; $0256  D3 06
        LD D,H                           ; $0258  54
        ADC A,$0E                        ; $0259  CE 0E
        LD D,E                           ; $025B  53
        JP SUB_5503_2                    ; $025C  C3 14 55
        DEFB    $54,$CF,$A7,$00                                  ; $025F
        DEFB    $55,$54,$54,$4F,$CE,$36,$45,$45,$D0,$D4,$00      ; $0263  "UTTON6EEPT"
        DEFB    $4C,$4F,$53,$C5,$BC,$4F,$4E,$D4,$98,$4C,$45,$41,$D2 ; $026E
        DEFW    SUB_494C_7               ; $027B
        DEFB    $4E,$D4,$1B,$53,$4E                              ; $027D
        DEFW    SUB_1CC1_1               ; $0282
        DEFW    SUB_4068_46              ; $0284
        DEFW    SUB_1DB2_2               ; $0286
        DEFB    $56                                              ; $0288
        DEFW    SUB_2AC5_1               ; $0289
        DEFB    $56                                              ; $028B
        DEFW    SUB_2BC4_1               ; $028C
        DEFB    $56                                              ; $028E
        DEFW    SUB_2CBA_1               ; $028F
        DEFB    $4F                                              ; $0291
        DEFW    SUB_0C98_3               ; $0292
        DEFW    SUB_5226_5               ; $0294
        DEFW    SUB_1506_11              ; $0296
        DEFB    $41,$4C,$CC,$B1,$4F,$4D,$4D,$4F,$CE,$B3,$48,$41,$49,$CE,$B4,$4F ; $0298  "ALL1OMMON3HAIN4OLORM"
        DEFB    $4C,$4F,$D2,$CD,$00                              ; $02A8
        DEFW    SUB_53F7_5               ; $02AD
        DEFB    $C1                                              ; $02AF
        DEFW    SUB_494C_5               ; $02B0
        DEFB    $CD,$86,$45                                      ; $02B2
        DEFW    SUB_52CF_4               ; $02B5
        DEFB    $54,$D2                                          ; $02B7
        DEFW    SUB_45A8_1               ; $02B9
        DEFB    $46,$49,$4E,$D4                                  ; $02BB
        DEFW    SUB_45A8_2               ; $02BF
        DEFW    SUB_52CF_4               ; $02C1
        DEFB    $4E,$C7                                          ; $02C3
        DEFW    SUB_45A8_3               ; $02C5
        DEFB    $46                                              ; $02C7
        DEFW    SUB_4068_46              ; $02C8
        DEFB    $CC                                              ; $02CA
        DEFW    SUB_45A8_4               ; $02CB
        DEFB    $C6,$96                                          ; $02CD
        DEFB    $45,$4C,$45,$54,$C5,$A6,$45,$CC,$A6,$00          ; $02CF  "ELETE&EL&"
        DEFB    $4E,$C4,$81                                      ; $02D9
        DEFW    SUB_52CF_6               ; $02DC
        DEFB    $C5,$9E                                          ; $02DE
        DEFW    SUB_4068_24              ; $02E0
        DEFB    $53,$C5,$A2,$44,$49,$D4                          ; $02E2
        DEFW    SUB_52A1_1               ; $02E8
        DEFB    $52,$4F,$D2                                      ; $02EA
        DEFW    SUB_52A1_2               ; $02ED
        DEFB    $CC,$E5,$52,$D2,$E6,$58                          ; $02EF
        DEFW    SUB_0B2A_48              ; $02F5
        DEFB    $4F,$C6,$2E,$51,$D6,$FA,$00                      ; $02F7  "OF.QVz"
        DEFB    $4F,$D2                                          ; $02FE
L_0300:
        DEFB    $82,$49                                          ; $0300
        DEFW    SUB_4C03_4               ; $0302
        DEFB    $C4                                              ; $0304
        DEFW    SUB_49A6_1               ; $0305
        DEFB    $4C,$45,$D3,$BF,$CE,$E2,$52                      ; $0307
        DEFW    SUB_0FAB_3               ; $030E
        DEFB    $49                                              ; $0310
        DEFW    SUB_1E72_9               ; $0311
        DEFB    $00,$4F,$54,$CF,$89                              ; $0313
        DEFW    SUB_2041_1               ; $0318
        DEFB    $54,$CF,$89                                      ; $031A
        DEFB    $4F,$53,$55,$C2,$8D                              ; $031D  "OSUB"
        DEFB    $45,$D4,$BA,$D2,$CC,$00                          ; $0322  "ET:RL"
        DEFB    $4F,$4D,$C5                                      ; $0328
        DEFW    SUB_4CA1_4               ; $032B
        DEFB    $49,$CE                                          ; $032D
        DEFW    SUB_475A_4               ; $032F
        DEFB    $D2                                              ; $0331
        DEFW    SUB_43A2_1               ; $0332
        DEFW    SUB_4C03_5               ; $0334
        DEFB    $4F,$D2                                          ; $0336
        DEFW    SUB_50A6_5               ; $0338
        DEFB    $4C,$4F,$D4,$D2                                  ; $033A
        DEFW    SUB_4068_25              ; $033E
        DEFB    $C2                                              ; $0340
        DEFW    SUB_52CF_11              ; $0341
        DEFW    SUB_5226_3               ; $0343
        DEFB    $CE                                              ; $0345
        DEFW    SUB_45B5_10              ; $0346
        DEFB    $58,$A4,$19                                      ; $0348
        DEFW    SUB_4DC3_8               ; $034B
        DEFW    SUB_554F_1               ; $034D
        DEFB    $D4,$85,$C6,$8B                                  ; $034F
        DEFW    SUB_52CF_7               ; $0353
        DEFB    $54,$D2,$E9,$4E,$D4                              ; $0355
        DEFW    SUB_4CA1_11              ; $035A
        DEFB    $D0,$FB,$4E,$4B,$45,$59,$A4,$EE,$4E,$56,$45,$52,$53,$C5,$CA,$00 ; $035C  "P{NKEY$nNVERSEJ"
        DEFW    SUB_4900                 ; $036C
        DEFB    $4C,$CC,$C1,$00,$45,$D4                          ; $036E
        DEFW    SUB_494C_6               ; $0374
        DEFB    $4E,$C5,$AD                                      ; $0376
        DEFW    SUB_4068_23              ; $0379
        DEFB    $C4,$BD                                          ; $037B
        DEFW    SUB_453A_2               ; $037D
        DEFB    $D4,$C2,$50                                      ; $037F
        DEFW    SUB_494C_2               ; $0382
        DEFB    $4E,$D4,$9B                                      ; $0384
        DEFW    SUB_494C                 ; $0387
        DEFB    $53,$D4,$9C,$50,$4F                              ; $0389
        DEFW    SUB_1A93_6               ; $038E
        DEFB    $49,$53,$D4,$93,$4F                              ; $0390
        DEFW    SUB_0925_17              ; $0395
        DEFB    $4F                                              ; $0397
        DEFW    SUB_2FBC_1               ; $0398
        DEFB    $45                                              ; $039A
        DEFW    SUB_1128_18              ; $039B
        DEFB    $45,$46,$54,$A4,$01,$4F                          ; $039D
        DEFW    SUB_308B_5               ; $03A3
        DEFB    $00                                              ; $03A5
        DEFW    SUB_5226_4               ; $03A6
        DEFB    $47,$C5,$BE,$4F,$C4,$FC,$4B,$49,$A4,$31,$4B,$53  ; $03A8
        DEFW    SUB_3289_5               ; $03B4
        DEFB    $4B,$44                                          ; $03B6
        DEFW    SUB_33A1_1               ; $03B8
        DEFB    $49,$44,$A4,$03,$00                              ; $03BA
        DEFW    SUB_5842_1               ; $03BF
        DEFB    $D4,$83                                          ; $03C1
        DEFW    SUB_5226_6               ; $03C3
        DEFW    SUB_4068_22              ; $03C5
        DEFB    $CC                                              ; $03C7
        DEFW    SUB_4E80_4               ; $03C8
        DEFW    SUB_5226_7               ; $03CA
        DEFW    SUB_4300_6               ; $03CC
        DEFB    $C5                                              ; $03CE
        DEFW    SUB_4068_32              ; $03CF
        DEFB    $4D,$C5                                          ; $03D1
        DEFW    SUB_45B5_1               ; $03D3
        DEFB    $D7,$94,$4F,$D4,$E4,$00,$CE,$95                  ; $03D5
        DEFW    SUB_453A_1               ; $03DD
        DEFB    $CE,$B8,$D2                                      ; $03DF
        DEFW    SUB_43DA_2               ; $03E2
        DEFB    $54                                              ; $03E4
        DEFW    SUB_189A_1               ; $03E5
        DEFB    $50,$54,$49,$4F,$CE,$B5,$00                      ; $03E7  "PTION5"
        DEFB    $55,$D4,$BB                                      ; $03EE
        DEFW    SUB_4B4F                 ; $03F1
        DEFB    $C5,$97                                          ; $03F3
        DEFW    SUB_494C_2               ; $03F5
        DEFB    $4E,$D4,$91,$4F,$D3,$10,$45,$45,$CB              ; $03F7
        DEFW    SUB_4C03_2               ; $0400
        DEFB    $4F,$D4,$D0,$44,$CC,$35,$4F,$D0,$AE,$00          ; $0402  "OTPDL5OP."
        DEFB    $00,$45,$41,$C4,$87,$55                          ; $040C
SUB_0100_28:
        ADC A,$8A                        ; $0412  CE 8A
        LD B,L                           ; $0414  45
        LD D,E                           ; $0415  53
        LD D,H                           ; $0416  54
        LD C,A                           ; $0417  4F
SUB_0100_29:
        LD D,D                           ; $0418  52
        PUSH BC                          ; $0419  C5
        ADC A,H                          ; $041A  8C
        LD B,L                           ; $041B  45
        LD D,H                           ; $041C  54
        LD D,L                           ; $041D  55
SUB_0100_30:
        LD D,D                           ; $041E  52
        ADC A,$8E                        ; $041F  CE 8E
        LD B,L                           ; $0421  45
        CALL SUB_453A_5+1                ; $0422  CD 8F 45
        LD D,E                           ; $0425  53
        LD D,L                           ; $0426  55
        LD C,L                           ; $0427  4D
        PUSH BC                          ; $0428  C5
        AND L                            ; $0429  A5
        LD D,E                           ; $042A  53
        LD B,L                           ; $042B  45
        CALL NC,SUB_49C3                 ; $042C  D4 C3 49
        LD B,A                           ; $042F  47
SUB_0100_31:
        LD C,B                           ; $0430  48
        LD D,H                           ; $0431  54
        AND H                            ; $0432  A4
        LD (BC),A                        ; $0433  02
        LD C,(HL)                        ; $0434  4E
        CALL NZ,SUB_4508                 ; $0435  C4 08 45
        LD C,(HL)                        ; $0438  4E
        LD D,L                           ; $0439  55
        CALL SUB_45A8                    ; $043A  CD A8 45
        LD D,E                           ; $043D  53
L_043E:
        DEFB    $45,$D4,$C5,$41,$4E,$44,$4F,$4D,$49,$5A,$C5,$B6,$00 ; $043E  "ETEANDOMIZE6"
        DEFB    $54,$4F,$D0,$90,$57,$41,$D0                      ; $044B
        DEFW    SUB_4068_33              ; $0452
        DEFB    $56,$C5                                          ; $0454
        DEFW    SUB_50A6_3               ; $0456
        DEFB    $43,$A8,$E3                                      ; $0458
        DEFW    SUB_453A_3               ; $045B
        DEFB    $D0                                              ; $045D
        DEFW    SUB_475A_6               ; $045E
        DEFB    $CE,$04,$51,$D2,$07,$49                          ; $0460
        DEFW    SUB_0925_4               ; $0466
        DEFW    SUB_5226_7               ; $0468
        DEFW    SUB_129A_1               ; $046A
        DEFW    SUB_5226_7               ; $046C
        DEFB    $49,$4E,$47,$A4                                  ; $046E
        DEFW    SUB_50A6_6               ; $0472
        DEFW    SUB_4300_6               ; $0474
        DEFB    $45,$A4                                          ; $0476
        DEFW    SUB_58FE_3               ; $0478
        DEFB    $53,$54,$45,$CD,$B7,$43,$52,$CE,$EC,$00          ; $047A  "STEM7CRNl"
        DEFW    SUB_4068_24              ; $0484
        DEFB    $43,$C5,$9F                                      ; $0486
        DEFB    $41,$42,$A8,$DF,$CF,$DD,$48,$45,$CE,$DE,$41,$CE,$0D ; $0489  "AB(_O]HEN^AN"
        DEFB    $45,$58,$D4,$C6,$00                              ; $0496  "EXTF"
        DEFB    $53,$49,$4E,$C7,$E8,$53,$D2,$E1,$00              ; $049B  "SINGhSRa"
        DEFB    $41                                              ; $04A4
        DEFW    SUB_129A_19              ; $04A5
        DEFB    $41,$52,$50,$54,$D2,$EB,$4C,$49,$CE,$CF,$54,$41,$C2,$C8,$50,$4F ; $04A7  "ARPTRkLINOTABHPOS4"
        DEFB    $D3,$34,$00                                      ; $04B7
        DEFB    $49                                              ; $04BA
        DEFW    SUB_53F7_6               ; $04BB
        DEFB    $C8,$9D                                          ; $04BD
        DEFB    $41,$49,$D4,$D5,$48,$49,$4C,$C5,$AF,$45,$4E,$C4,$B0,$52,$49,$54 ; $04BF  "AITUHILE/END0RITE2"
        DEFB    $C5,$B2,$00                                      ; $04CF
        DEFB    $4F,$D2,$F9,$00,$00                              ; $04D2
L_04D7:
        DEFB    $00                                              ; $04D7
L_04D8:
        DEFB    $AB,$F2,$AD,$F3,$AA,$F4,$AF,$F5,$DE,$F6,$DC,$FD,$A7,$EA,$BE,$EF ; $04D8  "+r-s*t/u^v\}'j>o=p<q"
        DEFB    $BD,$F0,$BC,$F1,$00                              ; $04E8
L_04ED:
        DEFB    $79,$79,$7C,$7C                                  ; $04ED
        DEFW    SUB_503E_8               ; $04F1
        DEFB    $46                                              ; $04F3
        DEFW    SUB_3212_6+1             ; $04F4
        DEFB    $28,$7A,$7B                                      ; $04F6
L_04F9:
        DEFW    SUB_2C98                 ; $04F9
        DEFB    $00,$00                                          ; $04FB
        DEFW    SUB_2BF4                 ; $04FD
        DEFW    SUB_2CB3                 ; $04FF
        DEFW    SUB_2C6C                 ; $0501
L_0503:
        DEFW    SUB_2E8E                 ; $0503
        DEFW    SUB_2E76_1               ; $0505
        DEFW    SUB_2FBC                 ; $0507
        DEFW    SUB_308B_2               ; $0509
        DEFW    SUB_2BC4_5               ; $050B
        DEFW    SUB_2824                 ; $050D
        DEFW    SUB_2821                 ; $050F
        DEFW    SUB_2990                 ; $0511
        DEFW    SUB_29E8_3               ; $0513
        DEFW    SUB_2B81                 ; $0515
L_0517:
        DEFW    SUB_2DA1                 ; $0517
        DEFW    SUB_2D79_4               ; $0519
        DEFB    $C1,$2D,$02                                      ; $051B
L_051E:
        DEFB    $1C                                              ; $051E
        DEFW    SUB_2BAE                 ; $051F
L_0521:
        DEFW    SUB_4DC3_8               ; $0521
        DEFB    "EXT without FOR"    ; $0523  string
        DEFB    $00    ; $0532  terminator
        DEFB    "Syntax error"    ; $0533  string
        DEFB    $00    ; $053F  terminator
        DEFB    "RETURN without GOSUB"    ; $0540  string
        DEFB    $00    ; $0554  terminator
        DEFB    "Out of DATA"    ; $0555  string
        DEFB    $00    ; $0560  terminator
        DEFB    "Illegal function call"    ; $0561  string
        DEFB    $00    ; $0576  terminator
L_0577:
        DEFB    "Overflow"    ; $0577  string
        DEFB    $00    ; $057F  terminator
        DEFB    "Out of memory"    ; $0580  string
        DEFB    $00    ; $058D  terminator
        DEFB    "Undefined line number"    ; $058E  string
        DEFB    $00    ; $05A3  terminator
        DEFB    "Subscript out of range"    ; $05A4  string
        DEFB    $00    ; $05BA  terminator
        DEFB    "Duplicate Definition"    ; $05BB  string
        DEFB    $00    ; $05CF  terminator
L_05D0:
        DEFB    "Division by zero"    ; $05D0  string
        DEFB    $00    ; $05E0  terminator
        DEFB    "Illegal direct"    ; $05E1  string
        DEFB    $00    ; $05EF  terminator
        DEFB    "Type mismatch"    ; $05F0  string
        DEFB    $00    ; $05FD  terminator
        DEFB    $4F,$75,$74,$20,$6F                              ; $05FE
L_0603:
        DEFB    "f string space"    ; $0603  string
        DEFB    $00    ; $0611  terminator
        DEFB    $53,$74,$72,$69,$6E,$67,$20,$74,$6F,$6F,$20,$6C  ; $0612
L_061E:
        DEFB    $6F,$6E,$67,$00                                  ; $061E
        DEFB    "String formula too complex"    ; $0622  string
        DEFB    $00    ; $063C  terminator
        DEFB    "Can't continue"    ; $063D  string
        DEFB    $00    ; $064B  terminator
        DEFB    $55,$6E                                          ; $064C
SUB_064E:
        LD H,H                           ; $064E  64
SUB_064E_1:
        LD H,L                           ; $064F  65
        LD H,(HL)                        ; $0650  66
        LD L,C                           ; $0651  69
        LD L,(HL)                        ; $0652  6E
        LD H,L                           ; $0653  65
        LD H,H                           ; $0654  64
        JR NZ,SUB_064E_4                 ; $0655  20 75
        LD (HL),E                        ; $0657  73
        LD H,L                           ; $0658  65
        LD (HL),D                        ; $0659  72
        JR NZ,SUB_064E_3+1               ; $065A  20 66
        LD (HL),L                        ; $065C  75
        LD L,(HL)                        ; $065D  6E
        LD H,E                           ; $065E  63
        LD (HL),H                        ; $065F  74
        LD L,C                           ; $0660  69
        LD L,A                           ; $0661  6F
        LD L,(HL)                        ; $0662  6E
        NOP                              ; $0663  00
        LD C,(HL)                        ; $0664  4E
        LD L,A                           ; $0665  6F
        JR NZ,SUB_064E_2                 ; $0666  20 52
        LD B,L                           ; $0668  45
        LD D,E                           ; $0669  53
        LD D,L                           ; $066A  55
        LD C,L                           ; $066B  4D
        LD B,L                           ; $066C  45
        NOP                              ; $066D  00
        LD D,D                           ; $066E  52
        LD B,L                           ; $066F  45
        LD D,E                           ; $0670  53
        LD D,L                           ; $0671  55
        LD C,L                           ; $0672  4D
        LD B,L                           ; $0673  45
        JR NZ,SUB_064E_8                 ; $0674  20 77
        LD L,C                           ; $0676  69
        LD (HL),H                        ; $0677  74
        LD L,B                           ; $0678  68
        LD L,A                           ; $0679  6F
        LD (HL),L                        ; $067A  75
        LD (HL),H                        ; $067B  74
        JR NZ,SUB_064E_7                 ; $067C  20 65
        LD (HL),D                        ; $067E  72
        LD (HL),D                        ; $067F  72
        LD L,A                           ; $0680  6F
        LD (HL),D                        ; $0681  72
        NOP                              ; $0682  00
        LD D,L                           ; $0683  55
        LD L,(HL)                        ; $0684  6E
        LD (HL),B                        ; $0685  70
        LD (HL),D                        ; $0686  72
        LD L,C                           ; $0687  69
        LD L,(HL)                        ; $0688  6E
        LD (HL),H                        ; $0689  74
        LD H,C                           ; $068A  61
        LD H,D                           ; $068B  62
        LD L,H                           ; $068C  6C
        LD H,L                           ; $068D  65
        JR NZ,SUB_064E_9                 ; $068E  20 65
        LD (HL),D                        ; $0690  72
        LD (HL),D                        ; $0691  72
        LD L,A                           ; $0692  6F
        LD (HL),D                        ; $0693  72
        NOP                              ; $0694  00
        LD C,L                           ; $0695  4D
        LD L,C                           ; $0696  69
        LD (HL),E                        ; $0697  73
        LD (HL),E                        ; $0698  73
        LD L,C                           ; $0699  69
        LD L,(HL)                        ; $069A  6E
        LD H,A                           ; $069B  67
        JR NZ,SUB_064E_12                ; $069C  20 6F
        LD (HL),B                        ; $069E  70
        LD H,L                           ; $069F  65
        LD (HL),D                        ; $06A0  72
        LD H,C                           ; $06A1  61
        LD L,(HL)                        ; $06A2  6E
        LD H,H                           ; $06A3  64
        NOP                              ; $06A4  00
        LD C,H                           ; $06A5  4C
        LD L,C                           ; $06A6  69
        LD L,(HL)                        ; $06A7  6E
        LD H,L                           ; $06A8  65
        JR NZ,SUB_064E_12                ; $06A9  20 62
        LD (HL),L                        ; $06AB  75
        LD H,(HL)                        ; $06AC  66
        LD H,(HL)                        ; $06AD  66
        LD H,L                           ; $06AE  65
        LD (HL),D                        ; $06AF  72
        JR NZ,SUB_064E_15                ; $06B0  20 6F
        HALT                             ; $06B2  76
        DEFB    "erflow"    ; $06B3  string
        DEFB    $00    ; $06B9  terminator
SUB_064E_2:
        CCF                              ; $06BA  3F
        NOP                              ; $06BB  00
        CCF                              ; $06BC  3F
        NOP                              ; $06BD  00
        LD B,(HL)                        ; $06BE  46
        LD C,A                           ; $06BF  4F
        LD D,D                           ; $06C0  52
SUB_064E_3:
        JR NZ,SUB_064E_14                ; $06C1  20 57
        LD L,C                           ; $06C3  69
        LD (HL),H                        ; $06C4  74
        LD L,B                           ; $06C5  68
        LD L,A                           ; $06C6  6F
        LD (HL),L                        ; $06C7  75
        LD (HL),H                        ; $06C8  74
        JR NZ,SUB_064E_13                ; $06C9  20 4E
        LD B,L                           ; $06CB  45
SUB_064E_4:
        LD E,B                           ; $06CC  58
SUB_064E_5:
        LD D,H                           ; $06CD  54
        NOP                              ; $06CE  00
        CCF                              ; $06CF  3F
        NOP                              ; $06D0  00
        CCF                              ; $06D1  3F
        NOP                              ; $06D2  00
        LD D,A                           ; $06D3  57
SUB_064E_6:
        LD C,B                           ; $06D4  48
        LD C,C                           ; $06D5  49
        LD C,H                           ; $06D6  4C
        LD B,L                           ; $06D7  45
        JR NZ,SUB_064E_20                ; $06D8  20 77
        LD L,C                           ; $06DA  69
        LD (HL),H                        ; $06DB  74
        LD L,B                           ; $06DC  68
        LD L,A                           ; $06DD  6F
        LD (HL),L                        ; $06DE  75
        LD (HL),H                        ; $06DF  74
        JR NZ,SUB_064E_17                ; $06E0  20 57
        LD B,L                           ; $06E2  45
SUB_064E_7:
        LD C,(HL)                        ; $06E3  4E
        LD B,H                           ; $06E4  44
        NOP                              ; $06E5  00
        LD D,A                           ; $06E6  57
        LD B,L                           ; $06E7  45
        LD C,(HL)                        ; $06E8  4E
        LD B,H                           ; $06E9  44
        JR NZ,SUB_0752_1                 ; $06EA  20 77
        LD L,C                           ; $06EC  69
SUB_064E_8:
        LD (HL),H                        ; $06ED  74
        LD L,B                           ; $06EE  68
        LD L,A                           ; $06EF  6F
        LD (HL),L                        ; $06F0  75
        LD (HL),H                        ; $06F1  74
        JR NZ,SUB_064E_19                ; $06F2  20 57
        LD C,B                           ; $06F4  48
SUB_064E_9:
        LD C,C                           ; $06F5  49
        LD C,H                           ; $06F6  4C
        LD B,L                           ; $06F7  45
        NOP                              ; $06F8  00
        LD D,D                           ; $06F9  52
        LD H,L                           ; $06FA  65
        LD (HL),E                        ; $06FB  73
SUB_064E_10:
        LD H,L                           ; $06FC  65
        LD (HL),H                        ; $06FD  74
        JR NZ,SUB_0752_2                 ; $06FE  20 65
SUB_064E_11:
        LD (HL),D                        ; $0700  72
        LD (HL),D                        ; $0701  72
        LD L,A                           ; $0702  6F
        LD (HL),D                        ; $0703  72
        NOP                              ; $0704  00
        LD B,A                           ; $0705  47
        LD (HL),D                        ; $0706  72
        LD H,C                           ; $0707  61
        LD (HL),B                        ; $0708  70
        LD L,B                           ; $0709  68
        LD L,C                           ; $070A  69
        LD H,E                           ; $070B  63
        LD (HL),E                        ; $070C  73
SUB_064E_12:
        JR NZ,SUB_0752_3                 ; $070D  20 73
        LD (HL),H                        ; $070F  74
        LD H,C                           ; $0710  61
        LD (HL),H                        ; $0711  74
        LD H,L                           ; $0712  65
        LD L,L                           ; $0713  6D
        LD H,L                           ; $0714  65
        LD L,(HL)                        ; $0715  6E
        LD (HL),H                        ; $0716  74
        JR NZ,SUB_0752_5                 ; $0717  20 6E
SUB_064E_13:
        LD L,A                           ; $0719  6F
SUB_064E_14:
        LD (HL),H                        ; $071A  74
        JR NZ,SUB_0752_4                 ; $071B  20 69
        LD L,L                           ; $071D  6D
        LD (HL),B                        ; $071E  70
        LD L,H                           ; $071F  6C
        LD H,L                           ; $0720  65
SUB_064E_15:
        LD L,L                           ; $0721  6D
        LD H,L                           ; $0722  65
        LD L,(HL)                        ; $0723  6E
        LD (HL),H                        ; $0724  74
        LD H,L                           ; $0725  65
        LD H,H                           ; $0726  64
        NOP                              ; $0727  00
SUB_064E_16:
        LD B,(HL)                        ; $0728  46
        LD C,C                           ; $0729  49
        LD B,L                           ; $072A  45
        LD C,H                           ; $072B  4C
        LD B,H                           ; $072C  44
        JR NZ,SUB_0752_6                 ; $072D  20 6F
        HALT                             ; $072F  76
        DEFB    "erflow"    ; $0730  string
        DEFB    $00    ; $0736  terminator
        DEFB    $49,$6E                                          ; $0737
SUB_064E_17:
        LD (HL),H                        ; $0739  74
        LD H,L                           ; $073A  65
        LD (HL),D                        ; $073B  72
        LD L,(HL)                        ; $073C  6E
        LD H,C                           ; $073D  61
SUB_064E_18:
        LD L,H                           ; $073E  6C
        JR NZ,SUB_0752_7                 ; $073F  20 65
        LD (HL),D                        ; $0741  72
        LD (HL),D                        ; $0742  72
        LD L,A                           ; $0743  6F
        LD (HL),D                        ; $0744  72
        NOP                              ; $0745  00
        LD B,D                           ; $0746  42
        LD H,C                           ; $0747  61
        LD H,H                           ; $0748  64
        JR NZ,SUB_0752_8                 ; $0749  20 66
SUB_064E_19:
        LD L,C                           ; $074B  69
        LD L,H                           ; $074C  6C
        LD H,L                           ; $074D  65
        JR NZ,SUB_0752_9+1               ; $074E  20 6E
        LD (HL),L                        ; $0750  75
SUB_064E_20:
        LD L,L                           ; $0751  6D
SUB_0752:
        LD H,D                           ; $0752  62
        LD H,L                           ; $0753  65
        LD (HL),D                        ; $0754  72
        NOP                              ; $0755  00
        LD B,(HL)                        ; $0756  46
        LD L,C                           ; $0757  69
        LD L,H                           ; $0758  6C
        LD H,L                           ; $0759  65
        JR NZ,SUB_0752_11                ; $075A  20 6E
        LD L,A                           ; $075C  6F
        LD (HL),H                        ; $075D  74
        JR NZ,SUB_0752_10                ; $075E  20 66
        LD L,A                           ; $0760  6F
        LD (HL),L                        ; $0761  75
        LD L,(HL)                        ; $0762  6E
SUB_0752_1:
        LD H,H                           ; $0763  64
        NOP                              ; $0764  00
SUB_0752_2:
        LD B,D                           ; $0765  42
        LD H,C                           ; $0766  61
        LD H,H                           ; $0767  64
        JR NZ,SUB_0752_12                ; $0768  20 66
        LD L,C                           ; $076A  69
        LD L,H                           ; $076B  6C
        LD H,L                           ; $076C  65
        JR NZ,SUB_0752_15                ; $076D  20 6D
        LD L,A                           ; $076F  6F
        LD H,H                           ; $0770  64
        LD H,L                           ; $0771  65
        NOP                              ; $0772  00
        LD B,(HL)                        ; $0773  46
        LD L,C                           ; $0774  69
        LD L,H                           ; $0775  6C
        LD H,L                           ; $0776  65
        JR NZ,SUB_0752_14                ; $0777  20 61
        LD L,H                           ; $0779  6C
        LD (HL),D                        ; $077A  72
        LD H,L                           ; $077B  65
        LD H,C                           ; $077C  61
        LD H,H                           ; $077D  64
        LD A,C                           ; $077E  79
        JR NZ,SUB_0752_16+1              ; $077F  20 6F
        LD (HL),B                        ; $0781  70
SUB_0752_3:
        LD H,L                           ; $0782  65
        LD L,(HL)                        ; $0783  6E
        NOP                              ; $0784  00
        CCF                              ; $0785  3F
SUB_0752_4:
        NOP                              ; $0786  00
SUB_0752_5:
        LD B,H                           ; $0787  44
        LD L,C                           ; $0788  69
        LD (HL),E                        ; $0789  73
        LD L,E                           ; $078A  6B
        JR NZ,SUB_0752_13                ; $078B  20 49
        CPL                              ; $078D  2F
        LD C,A                           ; $078E  4F
        JR NZ,SUB_0752_17                ; $078F  20 65
        LD (HL),D                        ; $0791  72
        LD (HL),D                        ; $0792  72
        LD L,A                           ; $0793  6F
        LD (HL),D                        ; $0794  72
        NOP                              ; $0795  00
        LD B,(HL)                        ; $0796  46
        LD L,C                           ; $0797  69
        LD L,H                           ; $0798  6C
        LD H,L                           ; $0799  65
        JR NZ,SUB_0752_18+1              ; $079A  20 61
        LD L,H                           ; $079C  6C
        LD (HL),D                        ; $079D  72
SUB_0752_6:
        LD H,L                           ; $079E  65
        LD H,C                           ; $079F  61
        LD H,H                           ; $07A0  64
        LD A,C                           ; $07A1  79
        JR NZ,SUB_0752_20                ; $07A2  20 65
        LD A,B                           ; $07A4  78
        LD L,C                           ; $07A5  69
SUB_0752_7:
        LD (HL),E                        ; $07A6  73
        LD (HL),H                        ; $07A7  74
        LD (HL),E                        ; $07A8  73
        NOP                              ; $07A9  00
        CCF                              ; $07AA  3F
        NOP                              ; $07AB  00
        CCF                              ; $07AC  3F
        NOP                              ; $07AD  00
        LD B,H                           ; $07AE  44
        LD L,C                           ; $07AF  69
        LD (HL),E                        ; $07B0  73
SUB_0752_8:
        LD L,E                           ; $07B1  6B
        JR NZ,SUB_0752_22                ; $07B2  20 66
        LD (HL),L                        ; $07B4  75
        LD L,H                           ; $07B5  6C
        LD L,H                           ; $07B6  6C
        NOP                              ; $07B7  00
        LD C,C                           ; $07B8  49
        LD L,(HL)                        ; $07B9  6E
        LD (HL),B                        ; $07BA  70
        LD (HL),L                        ; $07BB  75
        LD (HL),H                        ; $07BC  74
SUB_0752_9:
        JR NZ,SUB_0752_26                ; $07BD  20 70
        LD H,C                           ; $07BF  61
        LD (HL),E                        ; $07C0  73
        LD (HL),H                        ; $07C1  74
        JR NZ,SUB_0752_25                ; $07C2  20 65
        LD L,(HL)                        ; $07C4  6E
        LD H,H                           ; $07C5  64
SUB_0752_10:
        NOP                              ; $07C6  00
        LD B,D                           ; $07C7  42
        LD H,C                           ; $07C8  61
        LD H,H                           ; $07C9  64
SUB_0752_11:
        JR NZ,SUB_0752_28                ; $07CA  20 72
        LD H,L                           ; $07CC  65
        LD H,E                           ; $07CD  63
        LD L,A                           ; $07CE  6F
        LD (HL),D                        ; $07CF  72
SUB_0752_12:
        LD H,H                           ; $07D0  64
        JR NZ,SUB_0752_29                ; $07D1  20 6E
        LD (HL),L                        ; $07D3  75
        LD L,L                           ; $07D4  6D
        LD H,D                           ; $07D5  62
SUB_0752_13:
        LD H,L                           ; $07D6  65
        LD (HL),D                        ; $07D7  72
        NOP                              ; $07D8  00
        LD B,D                           ; $07D9  42
SUB_0752_14:
        LD H,C                           ; $07DA  61
        LD H,H                           ; $07DB  64
SUB_0752_15:
        JR NZ,SUB_0752_31                ; $07DC  20 66
        LD L,C                           ; $07DE  69
        LD L,H                           ; $07DF  6C
        LD H,L                           ; $07E0  65
        JR NZ,SUB_0752_32                ; $07E1  20 6E
        LD H,C                           ; $07E3  61
        LD L,L                           ; $07E4  6D
        LD H,L                           ; $07E5  65
        NOP                              ; $07E6  00
        CCF                              ; $07E7  3F
        NOP                              ; $07E8  00
        LD B,H                           ; $07E9  44
        LD L,C                           ; $07EA  69
        LD (HL),D                        ; $07EB  72
        LD H,L                           ; $07EC  65
        LD H,E                           ; $07ED  63
        LD (HL),H                        ; $07EE  74
SUB_0752_16:
        JR NZ,SUB_0752_41                ; $07EF  20 73
        LD (HL),H                        ; $07F1  74
        LD H,C                           ; $07F2  61
        LD (HL),H                        ; $07F3  74
        LD H,L                           ; $07F4  65
        LD L,L                           ; $07F5  6D
SUB_0752_17:
        LD H,L                           ; $07F6  65
        LD L,(HL)                        ; $07F7  6E
        LD (HL),H                        ; $07F8  74
        JR NZ,SUB_0752_41                ; $07F9  20 69
        LD L,(HL)                        ; $07FB  6E
SUB_0752_18:
        JR NZ,SUB_0752_41                ; $07FC  20 66
        LD L,C                           ; $07FE  69
        LD L,H                           ; $07FF  6C
SUB_0752_19:
        LD H,L                           ; $0800  65
        NOP                              ; $0801  00
        LD D,H                           ; $0802  54
        LD L,A                           ; $0803  6F
        LD L,A                           ; $0804  6F
        JR NZ,SUB_0752_52                ; $0805  20 6D
        LD H,C                           ; $0807  61
        LD L,(HL)                        ; $0808  6E
SUB_0752_20:
        LD A,C                           ; $0809  79
        JR NZ,SUB_0752_50                ; $080A  20 66
        LD L,C                           ; $080C  69
        LD L,H                           ; $080D  6C
SUB_0752_21:
        LD H,L                           ; $080E  65
        LD (HL),E                        ; $080F  73
        NOP                              ; $0810  00
        LD B,H                           ; $0811  44
        LD L,C                           ; $0812  69
        LD (HL),E                        ; $0813  73
        LD L,E                           ; $0814  6B
        JR NZ,SUB_0752_44                ; $0815  20 52
        LD H,L                           ; $0817  65
        LD H,C                           ; $0818  61
        LD H,H                           ; $0819  64
SUB_0752_22:
        JR NZ,SUB_0752_45                ; $081A  20 4F
        LD L,(HL)                        ; $081C  6E
        LD L,H                           ; $081D  6C
        LD A,C                           ; $081E  79
        NOP                              ; $081F  00
        LD B,H                           ; $0820  44
        LD (HL),D                        ; $0821  72
        LD L,C                           ; $0822  69
        HALT                             ; $0823  76
SUB_0752_23:
        LD H,L                           ; $0824  65
        JR NZ,SUB_0752_59                ; $0825  20 73
        LD H,L                           ; $0827  65
SUB_0752_24:
        LD L,H                           ; $0828  6C
SUB_0752_25:
        LD H,L                           ; $0829  65
        LD H,E                           ; $082A  63
        LD (HL),H                        ; $082B  74
        JR NZ,SUB_0752_55                ; $082C  20 65
        LD (HL),D                        ; $082E  72
SUB_0752_26:
        LD (HL),D                        ; $082F  72
SUB_0752_27:
        LD L,A                           ; $0830  6F
        LD (HL),D                        ; $0831  72
        NOP                              ; $0832  00
        LD B,(HL)                        ; $0833  46
        LD L,C                           ; $0834  69
        LD L,H                           ; $0835  6C
        LD H,L                           ; $0836  65
        JR NZ,SUB_0752_53                ; $0837  20 52
        LD H,L                           ; $0839  65
        LD H,C                           ; $083A  61
        LD H,H                           ; $083B  64
        JR NZ,SUB_0752_54                ; $083C  20 4F
SUB_0752_28:
        LD L,(HL)                        ; $083E  6E
        LD L,H                           ; $083F  6C
        LD A,C                           ; $0840  79
SUB_0752_29:
        NOP                              ; $0841  00
SUB_0752_30:
        EX DE,HL                         ; $0842  EB
        INC D                            ; $0843  14
SUB_0752_31:
        EX DE,HL                         ; $0844  EB
        INC D                            ; $0845  14
        EX DE,HL                         ; $0846  EB
        INC D                            ; $0847  14
        EX DE,HL                         ; $0848  EB
        INC D                            ; $0849  14
        EX DE,HL                         ; $084A  EB
        INC D                            ; $084B  14
        EX DE,HL                         ; $084C  EB
        INC D                            ; $084D  14
        EX DE,HL                         ; $084E  EB
        INC D                            ; $084F  14
        EX DE,HL                         ; $0850  EB
SUB_0752_32:
        INC D                            ; $0851  14
        EX DE,HL                         ; $0852  EB
        INC D                            ; $0853  14
        EX DE,HL                         ; $0854  EB
        INC D                            ; $0855  14
SUB_0752_33:
        LD BC,$0000                      ; $0856  01 00 00
        NOP                              ; $0859  00
SUB_0752_34:
        LD BC,$7000                      ; $085A  01 00 70
SUB_0752_35:
        ADD A,H                          ; $085D  84
SUB_0752_36:
        LD D,B                           ; $085E  50
SUB_0752_37:
        JR SUB_0752_58                   ; $085F  18 38
SUB_0752_38:
        NOP                              ; $0861  00
SUB_0752_39:
        NOP                              ; $0862  00
SUB_0752_40:
        NOP                              ; $0863  00
SUB_0752_41:
        NOP                              ; $0864  00
SUB_0752_42:
        XOR D                            ; $0865  AA
        LD H,C                           ; $0866  61
SUB_0752_43:
        CP $FF                           ; $0867  FE FF
SUB_0752_44:
        LD B,A                           ; $0869  47
        LD H,C                           ; $086A  61
SUB_0752_45:
        LD (HL),A                        ; $086B  77
        DEC B                            ; $086C  05
SUB_0752_46:
        NOP                              ; $086D  00
SUB_0752_47:
        NOP                              ; $086E  00
SUB_0752_48:
        NOP                              ; $086F  00
        NOP                              ; $0870  00
SUB_0752_49:
        NOP                              ; $0871  00
SUB_0752_50:
        NOP                              ; $0872  00
SUB_0752_51:
        NOP                              ; $0873  00
SUB_0752_52:
        NOP                              ; $0874  00
        NOP                              ; $0875  00
        NOP                              ; $0876  00
        NOP                              ; $0877  00
        NOP                              ; $0878  00
        NOP                              ; $0879  00
        NOP                              ; $087A  00
        NOP                              ; $087B  00
        NOP                              ; $087C  00
        NOP                              ; $087D  00
        NOP                              ; $087E  00
        NOP                              ; $087F  00
        NOP                              ; $0880  00
        NOP                              ; $0881  00
        NOP                              ; $0882  00
        NOP                              ; $0883  00
        NOP                              ; $0884  00
        NOP                              ; $0885  00
        NOP                              ; $0886  00
        NOP                              ; $0887  00
        NOP                              ; $0888  00
        NOP                              ; $0889  00
        NOP                              ; $088A  00
SUB_0752_53:
        NOP                              ; $088B  00
        NOP                              ; $088C  00
SUB_0752_54:
        NOP                              ; $088D  00
        NOP                              ; $088E  00
        NOP                              ; $088F  00
        NOP                              ; $0890  00
        NOP                              ; $0891  00
        NOP                              ; $0892  00
SUB_0752_55:
        NOP                              ; $0893  00
SUB_0752_56:
        NOP                              ; $0894  00
SUB_0752_57:
        NOP                              ; $0895  00
        NOP                              ; $0896  00
        NOP                              ; $0897  00
        NOP                              ; $0898  00
SUB_0752_58:
        NOP                              ; $0899  00
SUB_0752_59:
        NOP                              ; $089A  00
        NOP                              ; $089B  00
        NOP                              ; $089C  00
        NOP                              ; $089D  00
        NOP                              ; $089E  00
        NOP                              ; $089F  00
        NOP                              ; $08A0  00
        NOP                              ; $08A1  00
        NOP                              ; $08A2  00
        NOP                              ; $08A3  00
        NOP                              ; $08A4  00
        NOP                              ; $08A5  00
        NOP                              ; $08A6  00
        NOP                              ; $08A7  00
        NOP                              ; $08A8  00
        NOP                              ; $08A9  00
        NOP                              ; $08AA  00
        NOP                              ; $08AB  00
        NOP                              ; $08AC  00
        NOP                              ; $08AD  00
        NOP                              ; $08AE  00
        NOP                              ; $08AF  00
        NOP                              ; $08B0  00
        NOP                              ; $08B1  00
        NOP                              ; $08B2  00
        NOP                              ; $08B3  00
        NOP                              ; $08B4  00
        NOP                              ; $08B5  00
        NOP                              ; $08B6  00
        NOP                              ; $08B7  00
        NOP                              ; $08B8  00
        NOP                              ; $08B9  00
        NOP                              ; $08BA  00
SUB_0752_60:
        NOP                              ; $08BB  00
        NOP                              ; $08BC  00
SUB_0752_61:
        NOP                              ; $08BD  00
        NOP                              ; $08BE  00
        NOP                              ; $08BF  00
        NOP                              ; $08C0  00
        NOP                              ; $08C1  00
        NOP                              ; $08C2  00
        NOP                              ; $08C3  00
        NOP                              ; $08C4  00
        NOP                              ; $08C5  00
        NOP                              ; $08C6  00
        NOP                              ; $08C7  00
        NOP                              ; $08C8  00
        NOP                              ; $08C9  00
        NOP                              ; $08CA  00
        NOP                              ; $08CB  00
        NOP                              ; $08CC  00
SUB_0752_62:
        NOP                              ; $08CD  00
SUB_0752_63:
        NOP                              ; $08CE  00
        NOP                              ; $08CF  00
        NOP                              ; $08D0  00
        NOP                              ; $08D1  00
        NOP                              ; $08D2  00
        NOP                              ; $08D3  00
        NOP                              ; $08D4  00
        NOP                              ; $08D5  00
SUB_0752_64:
        NOP                              ; $08D6  00
        NOP                              ; $08D7  00
        NOP                              ; $08D8  00
SUB_0752_65:
        NOP                              ; $08D9  00
        NOP                              ; $08DA  00
        NOP                              ; $08DB  00
        NOP                              ; $08DC  00
        NOP                              ; $08DD  00
        NOP                              ; $08DE  00
        NOP                              ; $08DF  00
        NOP                              ; $08E0  00
        NOP                              ; $08E1  00
        NOP                              ; $08E2  00
        NOP                              ; $08E3  00
        NOP                              ; $08E4  00
        NOP                              ; $08E5  00
        NOP                              ; $08E6  00
        NOP                              ; $08E7  00
        NOP                              ; $08E8  00
        NOP                              ; $08E9  00
        NOP                              ; $08EA  00
        NOP                              ; $08EB  00
        NOP                              ; $08EC  00
        NOP                              ; $08ED  00
SUB_0752_66:
        NOP                              ; $08EE  00
SUB_0752_67:
        NOP                              ; $08EF  00
SUB_0752_68:
        NOP                              ; $08F0  00
SUB_0752_69:
        LD A,($0000)                     ; $08F1  3A 00 00
        NOP                              ; $08F4  00
        NOP                              ; $08F5  00
        NOP                              ; $08F6  00
        NOP                              ; $08F7  00
        NOP                              ; $08F8  00
        NOP                              ; $08F9  00
        NOP                              ; $08FA  00
        NOP                              ; $08FB  00
        NOP                              ; $08FC  00
        NOP                              ; $08FD  00
        NOP                              ; $08FE  00
        NOP                              ; $08FF  00
SUB_0752_70:
        NOP                              ; $0900  00
        NOP                              ; $0901  00
        NOP                              ; $0902  00
        NOP                              ; $0903  00
        NOP                              ; $0904  00
        NOP                              ; $0905  00
SUB_0752_71:
        NOP                              ; $0906  00
        NOP                              ; $0907  00
        NOP                              ; $0908  00
        NOP                              ; $0909  00
        NOP                              ; $090A  00
        NOP                              ; $090B  00
        NOP                              ; $090C  00
        NOP                              ; $090D  00
        NOP                              ; $090E  00
        NOP                              ; $090F  00
        NOP                              ; $0910  00
        NOP                              ; $0911  00
        NOP                              ; $0912  00
        NOP                              ; $0913  00
        NOP                              ; $0914  00
        NOP                              ; $0915  00
        NOP                              ; $0916  00
        NOP                              ; $0917  00
        NOP                              ; $0918  00
        NOP                              ; $0919  00
        NOP                              ; $091A  00
        NOP                              ; $091B  00
        NOP                              ; $091C  00
        NOP                              ; $091D  00
        NOP                              ; $091E  00
        NOP                              ; $091F  00
SUB_0752_72:
        NOP                              ; $0920  00
        NOP                              ; $0921  00
        NOP                              ; $0922  00
        NOP                              ; $0923  00
        NOP                              ; $0924  00
SUB_0925:
        NOP                              ; $0925  00
        NOP                              ; $0926  00
        NOP                              ; $0927  00
SUB_0925_1:
        NOP                              ; $0928  00
        NOP                              ; $0929  00
        NOP                              ; $092A  00
        NOP                              ; $092B  00
        NOP                              ; $092C  00
        NOP                              ; $092D  00
        NOP                              ; $092E  00
        NOP                              ; $092F  00
SUB_0925_2:
        NOP                              ; $0930  00
        NOP                              ; $0931  00
        NOP                              ; $0932  00
        NOP                              ; $0933  00
        NOP                              ; $0934  00
        NOP                              ; $0935  00
        NOP                              ; $0936  00
        NOP                              ; $0937  00
        NOP                              ; $0938  00
        NOP                              ; $0939  00
        NOP                              ; $093A  00
        NOP                              ; $093B  00
        NOP                              ; $093C  00
        NOP                              ; $093D  00
        NOP                              ; $093E  00
        NOP                              ; $093F  00
        NOP                              ; $0940  00
        NOP                              ; $0941  00
        NOP                              ; $0942  00
        NOP                              ; $0943  00
        NOP                              ; $0944  00
        NOP                              ; $0945  00
        NOP                              ; $0946  00
        NOP                              ; $0947  00
        NOP                              ; $0948  00
        NOP                              ; $0949  00
        NOP                              ; $094A  00
        NOP                              ; $094B  00
        NOP                              ; $094C  00
        NOP                              ; $094D  00
        NOP                              ; $094E  00
        NOP                              ; $094F  00
        NOP                              ; $0950  00
        NOP                              ; $0951  00
        NOP                              ; $0952  00
        NOP                              ; $0953  00
        NOP                              ; $0954  00
        NOP                              ; $0955  00
        NOP                              ; $0956  00
        NOP                              ; $0957  00
        NOP                              ; $0958  00
        NOP                              ; $0959  00
        NOP                              ; $095A  00
        NOP                              ; $095B  00
        NOP                              ; $095C  00
        NOP                              ; $095D  00
        NOP                              ; $095E  00
        NOP                              ; $095F  00
        NOP                              ; $0960  00
        NOP                              ; $0961  00
        NOP                              ; $0962  00
        NOP                              ; $0963  00
        NOP                              ; $0964  00
        NOP                              ; $0965  00
        NOP                              ; $0966  00
        NOP                              ; $0967  00
        NOP                              ; $0968  00
        NOP                              ; $0969  00
        NOP                              ; $096A  00
        NOP                              ; $096B  00
        NOP                              ; $096C  00
        NOP                              ; $096D  00
        NOP                              ; $096E  00
        NOP                              ; $096F  00
        NOP                              ; $0970  00
        NOP                              ; $0971  00
        NOP                              ; $0972  00
        NOP                              ; $0973  00
        NOP                              ; $0974  00
        NOP                              ; $0975  00
        NOP                              ; $0976  00
        NOP                              ; $0977  00
        NOP                              ; $0978  00
        NOP                              ; $0979  00
        NOP                              ; $097A  00
        NOP                              ; $097B  00
        NOP                              ; $097C  00
        NOP                              ; $097D  00
        NOP                              ; $097E  00
        NOP                              ; $097F  00
        NOP                              ; $0980  00
        NOP                              ; $0981  00
        NOP                              ; $0982  00
        NOP                              ; $0983  00
        NOP                              ; $0984  00
        NOP                              ; $0985  00
        NOP                              ; $0986  00
        NOP                              ; $0987  00
        NOP                              ; $0988  00
        NOP                              ; $0989  00
        NOP                              ; $098A  00
        NOP                              ; $098B  00
        NOP                              ; $098C  00
        NOP                              ; $098D  00
        NOP                              ; $098E  00
        NOP                              ; $098F  00
        NOP                              ; $0990  00
        NOP                              ; $0991  00
        NOP                              ; $0992  00
        NOP                              ; $0993  00
        NOP                              ; $0994  00
        NOP                              ; $0995  00
        NOP                              ; $0996  00
        NOP                              ; $0997  00
        NOP                              ; $0998  00
        NOP                              ; $0999  00
        NOP                              ; $099A  00
        NOP                              ; $099B  00
        NOP                              ; $099C  00
        NOP                              ; $099D  00
        NOP                              ; $099E  00
        NOP                              ; $099F  00
        NOP                              ; $09A0  00
        NOP                              ; $09A1  00
        NOP                              ; $09A2  00
        NOP                              ; $09A3  00
        NOP                              ; $09A4  00
        NOP                              ; $09A5  00
        NOP                              ; $09A6  00
        NOP                              ; $09A7  00
        NOP                              ; $09A8  00
        NOP                              ; $09A9  00
        NOP                              ; $09AA  00
        NOP                              ; $09AB  00
        NOP                              ; $09AC  00
        NOP                              ; $09AD  00
        NOP                              ; $09AE  00
        NOP                              ; $09AF  00
        NOP                              ; $09B0  00
        NOP                              ; $09B1  00
        NOP                              ; $09B2  00
        NOP                              ; $09B3  00
        NOP                              ; $09B4  00
        NOP                              ; $09B5  00
        NOP                              ; $09B6  00
        NOP                              ; $09B7  00
        NOP                              ; $09B8  00
        NOP                              ; $09B9  00
        NOP                              ; $09BA  00
        NOP                              ; $09BB  00
        NOP                              ; $09BC  00
        NOP                              ; $09BD  00
        NOP                              ; $09BE  00
        NOP                              ; $09BF  00
        NOP                              ; $09C0  00
        NOP                              ; $09C1  00
        NOP                              ; $09C2  00
        NOP                              ; $09C3  00
        NOP                              ; $09C4  00
        NOP                              ; $09C5  00
        NOP                              ; $09C6  00
        NOP                              ; $09C7  00
        NOP                              ; $09C8  00
        NOP                              ; $09C9  00
SUB_0925_3:
        NOP                              ; $09CA  00
        NOP                              ; $09CB  00
        NOP                              ; $09CC  00
        NOP                              ; $09CD  00
SUB_0925_4:
        NOP                              ; $09CE  00
        NOP                              ; $09CF  00
        NOP                              ; $09D0  00
        NOP                              ; $09D1  00
        NOP                              ; $09D2  00
        NOP                              ; $09D3  00
        NOP                              ; $09D4  00
        NOP                              ; $09D5  00
        NOP                              ; $09D6  00
        NOP                              ; $09D7  00
        NOP                              ; $09D8  00
        NOP                              ; $09D9  00
        NOP                              ; $09DA  00
        NOP                              ; $09DB  00
        NOP                              ; $09DC  00
        NOP                              ; $09DD  00
        NOP                              ; $09DE  00
        NOP                              ; $09DF  00
        NOP                              ; $09E0  00
        NOP                              ; $09E1  00
        NOP                              ; $09E2  00
        NOP                              ; $09E3  00
        NOP                              ; $09E4  00
        NOP                              ; $09E5  00
        NOP                              ; $09E6  00
        NOP                              ; $09E7  00
        NOP                              ; $09E8  00
        NOP                              ; $09E9  00
        NOP                              ; $09EA  00
SUB_0925_5:
        NOP                              ; $09EB  00
        NOP                              ; $09EC  00
        NOP                              ; $09ED  00
        NOP                              ; $09EE  00
        NOP                              ; $09EF  00
        NOP                              ; $09F0  00
        NOP                              ; $09F1  00
        NOP                              ; $09F2  00
        NOP                              ; $09F3  00
        NOP                              ; $09F4  00
        NOP                              ; $09F5  00
        NOP                              ; $09F6  00
        NOP                              ; $09F7  00
        NOP                              ; $09F8  00
        NOP                              ; $09F9  00
        NOP                              ; $09FA  00
        NOP                              ; $09FB  00
        NOP                              ; $09FC  00
        NOP                              ; $09FD  00
        NOP                              ; $09FE  00
        NOP                              ; $09FF  00
SUB_0925_6:
        NOP                              ; $0A00  00
        NOP                              ; $0A01  00
        NOP                              ; $0A02  00
        NOP                              ; $0A03  00
        NOP                              ; $0A04  00
        NOP                              ; $0A05  00
        NOP                              ; $0A06  00
        NOP                              ; $0A07  00
        NOP                              ; $0A08  00
        NOP                              ; $0A09  00
        NOP                              ; $0A0A  00
        NOP                              ; $0A0B  00
        NOP                              ; $0A0C  00
SUB_0925_7:
        NOP                              ; $0A0D  00
        NOP                              ; $0A0E  00
        NOP                              ; $0A0F  00
        NOP                              ; $0A10  00
SUB_0925_8:
        NOP                              ; $0A11  00
        NOP                              ; $0A12  00
        NOP                              ; $0A13  00
        NOP                              ; $0A14  00
        NOP                              ; $0A15  00
        NOP                              ; $0A16  00
        NOP                              ; $0A17  00
        NOP                              ; $0A18  00
        NOP                              ; $0A19  00
        NOP                              ; $0A1A  00
        NOP                              ; $0A1B  00
        NOP                              ; $0A1C  00
        NOP                              ; $0A1D  00
SUB_0925_9:
        NOP                              ; $0A1E  00
        NOP                              ; $0A1F  00
        NOP                              ; $0A20  00
        NOP                              ; $0A21  00
        NOP                              ; $0A22  00
        NOP                              ; $0A23  00
        NOP                              ; $0A24  00
        NOP                              ; $0A25  00
        NOP                              ; $0A26  00
        NOP                              ; $0A27  00
SUB_0925_10:
        NOP                              ; $0A28  00
        NOP                              ; $0A29  00
        NOP                              ; $0A2A  00
        NOP                              ; $0A2B  00
        NOP                              ; $0A2C  00
        NOP                              ; $0A2D  00
        NOP                              ; $0A2E  00
        NOP                              ; $0A2F  00
SUB_0925_11:
        INC L                            ; $0A30  2C
SUB_0925_12:
        NOP                              ; $0A31  00
        NOP                              ; $0A32  00
        NOP                              ; $0A33  00
        NOP                              ; $0A34  00
        NOP                              ; $0A35  00
        NOP                              ; $0A36  00
        NOP                              ; $0A37  00
        NOP                              ; $0A38  00
        NOP                              ; $0A39  00
        NOP                              ; $0A3A  00
        NOP                              ; $0A3B  00
        NOP                              ; $0A3C  00
        NOP                              ; $0A3D  00
        NOP                              ; $0A3E  00
        NOP                              ; $0A3F  00
        NOP                              ; $0A40  00
        NOP                              ; $0A41  00
        NOP                              ; $0A42  00
        NOP                              ; $0A43  00
        NOP                              ; $0A44  00
        NOP                              ; $0A45  00
SUB_0925_13:
        NOP                              ; $0A46  00
        NOP                              ; $0A47  00
        NOP                              ; $0A48  00
        NOP                              ; $0A49  00
        NOP                              ; $0A4A  00
        NOP                              ; $0A4B  00
        NOP                              ; $0A4C  00
        NOP                              ; $0A4D  00
        NOP                              ; $0A4E  00
        NOP                              ; $0A4F  00
        NOP                              ; $0A50  00
        NOP                              ; $0A51  00
        NOP                              ; $0A52  00
        NOP                              ; $0A53  00
        NOP                              ; $0A54  00
        NOP                              ; $0A55  00
        NOP                              ; $0A56  00
        NOP                              ; $0A57  00
        NOP                              ; $0A58  00
        NOP                              ; $0A59  00
        NOP                              ; $0A5A  00
        NOP                              ; $0A5B  00
        NOP                              ; $0A5C  00
        NOP                              ; $0A5D  00
        NOP                              ; $0A5E  00
        NOP                              ; $0A5F  00
        NOP                              ; $0A60  00
        NOP                              ; $0A61  00
        NOP                              ; $0A62  00
        NOP                              ; $0A63  00
        NOP                              ; $0A64  00
        NOP                              ; $0A65  00
        NOP                              ; $0A66  00
        NOP                              ; $0A67  00
        NOP                              ; $0A68  00
        NOP                              ; $0A69  00
        NOP                              ; $0A6A  00
        NOP                              ; $0A6B  00
        NOP                              ; $0A6C  00
        NOP                              ; $0A6D  00
        NOP                              ; $0A6E  00
        NOP                              ; $0A6F  00
        NOP                              ; $0A70  00
        NOP                              ; $0A71  00
        NOP                              ; $0A72  00
        NOP                              ; $0A73  00
        NOP                              ; $0A74  00
        NOP                              ; $0A75  00
        NOP                              ; $0A76  00
        NOP                              ; $0A77  00
        NOP                              ; $0A78  00
        NOP                              ; $0A79  00
        NOP                              ; $0A7A  00
        NOP                              ; $0A7B  00
        NOP                              ; $0A7C  00
        NOP                              ; $0A7D  00
        NOP                              ; $0A7E  00
        NOP                              ; $0A7F  00
        NOP                              ; $0A80  00
        NOP                              ; $0A81  00
        NOP                              ; $0A82  00
SUB_0925_14:
        NOP                              ; $0A83  00
        NOP                              ; $0A84  00
        NOP                              ; $0A85  00
        NOP                              ; $0A86  00
        NOP                              ; $0A87  00
        NOP                              ; $0A88  00
        NOP                              ; $0A89  00
        NOP                              ; $0A8A  00
        NOP                              ; $0A8B  00
        NOP                              ; $0A8C  00
        NOP                              ; $0A8D  00
        NOP                              ; $0A8E  00
        NOP                              ; $0A8F  00
        NOP                              ; $0A90  00
        NOP                              ; $0A91  00
        NOP                              ; $0A92  00
        NOP                              ; $0A93  00
        NOP                              ; $0A94  00
        NOP                              ; $0A95  00
        NOP                              ; $0A96  00
        NOP                              ; $0A97  00
SUB_0925_15:
        NOP                              ; $0A98  00
SUB_0925_16:
        NOP                              ; $0A99  00
        NOP                              ; $0A9A  00
        NOP                              ; $0A9B  00
        NOP                              ; $0A9C  00
        NOP                              ; $0A9D  00
        NOP                              ; $0A9E  00
        NOP                              ; $0A9F  00
        NOP                              ; $0AA0  00
        NOP                              ; $0AA1  00
        NOP                              ; $0AA2  00
        NOP                              ; $0AA3  00
        NOP                              ; $0AA4  00
        NOP                              ; $0AA5  00
        NOP                              ; $0AA6  00
        NOP                              ; $0AA7  00
        NOP                              ; $0AA8  00
        NOP                              ; $0AA9  00
        NOP                              ; $0AAA  00
        NOP                              ; $0AAB  00
        NOP                              ; $0AAC  00
        NOP                              ; $0AAD  00
        NOP                              ; $0AAE  00
        NOP                              ; $0AAF  00
        NOP                              ; $0AB0  00
        NOP                              ; $0AB1  00
        NOP                              ; $0AB2  00
        NOP                              ; $0AB3  00
        NOP                              ; $0AB4  00
        NOP                              ; $0AB5  00
        NOP                              ; $0AB6  00
        NOP                              ; $0AB7  00
        NOP                              ; $0AB8  00
        NOP                              ; $0AB9  00
        NOP                              ; $0ABA  00
        NOP                              ; $0ABB  00
        NOP                              ; $0ABC  00
        NOP                              ; $0ABD  00
        NOP                              ; $0ABE  00
        NOP                              ; $0ABF  00
        NOP                              ; $0AC0  00
        NOP                              ; $0AC1  00
        NOP                              ; $0AC2  00
        NOP                              ; $0AC3  00
        NOP                              ; $0AC4  00
        NOP                              ; $0AC5  00
        NOP                              ; $0AC6  00
SUB_0925_17:
        NOP                              ; $0AC7  00
        NOP                              ; $0AC8  00
        NOP                              ; $0AC9  00
        NOP                              ; $0ACA  00
        NOP                              ; $0ACB  00
        NOP                              ; $0ACC  00
        NOP                              ; $0ACD  00
        NOP                              ; $0ACE  00
        NOP                              ; $0ACF  00
        NOP                              ; $0AD0  00
        NOP                              ; $0AD1  00
        NOP                              ; $0AD2  00
        NOP                              ; $0AD3  00
        NOP                              ; $0AD4  00
        NOP                              ; $0AD5  00
        NOP                              ; $0AD6  00
        NOP                              ; $0AD7  00
        NOP                              ; $0AD8  00
        NOP                              ; $0AD9  00
        NOP                              ; $0ADA  00
        NOP                              ; $0ADB  00
        NOP                              ; $0ADC  00
        NOP                              ; $0ADD  00
        NOP                              ; $0ADE  00
        NOP                              ; $0ADF  00
        NOP                              ; $0AE0  00
        NOP                              ; $0AE1  00
        NOP                              ; $0AE2  00
        NOP                              ; $0AE3  00
        NOP                              ; $0AE4  00
        NOP                              ; $0AE5  00
        NOP                              ; $0AE6  00
        NOP                              ; $0AE7  00
        NOP                              ; $0AE8  00
        NOP                              ; $0AE9  00
        NOP                              ; $0AEA  00
        NOP                              ; $0AEB  00
        NOP                              ; $0AEC  00
        NOP                              ; $0AED  00
        NOP                              ; $0AEE  00
        NOP                              ; $0AEF  00
        NOP                              ; $0AF0  00
        NOP                              ; $0AF1  00
        NOP                              ; $0AF2  00
        NOP                              ; $0AF3  00
        NOP                              ; $0AF4  00
        NOP                              ; $0AF5  00
        NOP                              ; $0AF6  00
        NOP                              ; $0AF7  00
        NOP                              ; $0AF8  00
        NOP                              ; $0AF9  00
        NOP                              ; $0AFA  00
        NOP                              ; $0AFB  00
        NOP                              ; $0AFC  00
        NOP                              ; $0AFD  00
SUB_0925_18:
        NOP                              ; $0AFE  00
        NOP                              ; $0AFF  00
        NOP                              ; $0B00  00
        NOP                              ; $0B01  00
        NOP                              ; $0B02  00
        NOP                              ; $0B03  00
        NOP                              ; $0B04  00
        NOP                              ; $0B05  00
        NOP                              ; $0B06  00
        NOP                              ; $0B07  00
        NOP                              ; $0B08  00
        NOP                              ; $0B09  00
        NOP                              ; $0B0A  00
        NOP                              ; $0B0B  00
        NOP                              ; $0B0C  00
        NOP                              ; $0B0D  00
SUB_0925_19:
        NOP                              ; $0B0E  00
        NOP                              ; $0B0F  00
        NOP                              ; $0B10  00
        NOP                              ; $0B11  00
        NOP                              ; $0B12  00
        NOP                              ; $0B13  00
        NOP                              ; $0B14  00
        NOP                              ; $0B15  00
        NOP                              ; $0B16  00
        NOP                              ; $0B17  00
        NOP                              ; $0B18  00
        NOP                              ; $0B19  00
        NOP                              ; $0B1A  00
        NOP                              ; $0B1B  00
        NOP                              ; $0B1C  00
        NOP                              ; $0B1D  00
SUB_0925_20:
        NOP                              ; $0B1E  00
        NOP                              ; $0B1F  00
SUB_0925_21:
        NOP                              ; $0B20  00
        NOP                              ; $0B21  00
        NOP                              ; $0B22  00
        NOP                              ; $0B23  00
        NOP                              ; $0B24  00
        NOP                              ; $0B25  00
        NOP                              ; $0B26  00
        NOP                              ; $0B27  00
        NOP                              ; $0B28  00
        NOP                              ; $0B29  00
SUB_0B2A:
        NOP                              ; $0B2A  00
        NOP                              ; $0B2B  00
        NOP                              ; $0B2C  00
        NOP                              ; $0B2D  00
        NOP                              ; $0B2E  00
        NOP                              ; $0B2F  00
        NOP                              ; $0B30  00
        NOP                              ; $0B31  00
        NOP                              ; $0B32  00
SUB_0B2A_1:
        NOP                              ; $0B33  00
SUB_0B2A_2:
        NOP                              ; $0B34  00
SUB_0B2A_3:
        NOP                              ; $0B35  00
SUB_0B2A_4:
        NOP                              ; $0B36  00
SUB_0B2A_5:
        NOP                              ; $0B37  00
SUB_0B2A_6:
        NOP                              ; $0B38  00
SUB_0B2A_7:
        NOP                              ; $0B39  00
SUB_0B2A_8:
        NOP                              ; $0B3A  00
        NOP                              ; $0B3B  00
SUB_0B2A_9:
        NOP                              ; $0B3C  00
SUB_0B2A_10:
        NOP                              ; $0B3D  00
SUB_0B2A_11:
        NOP                              ; $0B3E  00
        NOP                              ; $0B3F  00
SUB_0B2A_12:
        NOP                              ; $0B40  00
        NOP                              ; $0B41  00
        NOP                              ; $0B42  00
        NOP                              ; $0B43  00
        NOP                              ; $0B44  00
        NOP                              ; $0B45  00
SUB_0B2A_13:
        NOP                              ; $0B46  00
        NOP                              ; $0B47  00
SUB_0B2A_14:
        NOP                              ; $0B48  00
        NOP                              ; $0B49  00
SUB_0B2A_15:
        NOP                              ; $0B4A  00
        NOP                              ; $0B4B  00
        NOP                              ; $0B4C  00
        NOP                              ; $0B4D  00
        NOP                              ; $0B4E  00
        NOP                              ; $0B4F  00
        NOP                              ; $0B50  00
        NOP                              ; $0B51  00
        NOP                              ; $0B52  00
        NOP                              ; $0B53  00
        NOP                              ; $0B54  00
        NOP                              ; $0B55  00
        NOP                              ; $0B56  00
        NOP                              ; $0B57  00
        NOP                              ; $0B58  00
SUB_0B2A_16:
        NOP                              ; $0B59  00
        NOP                              ; $0B5A  00
        NOP                              ; $0B5B  00
        NOP                              ; $0B5C  00
        NOP                              ; $0B5D  00
        NOP                              ; $0B5E  00
        NOP                              ; $0B5F  00
        NOP                              ; $0B60  00
        NOP                              ; $0B61  00
        NOP                              ; $0B62  00
        NOP                              ; $0B63  00
        NOP                              ; $0B64  00
        NOP                              ; $0B65  00
        NOP                              ; $0B66  00
        NOP                              ; $0B67  00
SUB_0B2A_17:
        NOP                              ; $0B68  00
SUB_0B2A_18:
        NOP                              ; $0B69  00
        NOP                              ; $0B6A  00
SUB_0B2A_19:
        NOP                              ; $0B6B  00
        NOP                              ; $0B6C  00
SUB_0B2A_20:
        NOP                              ; $0B6D  00
        NOP                              ; $0B6E  00
SUB_0B2A_21:
        NOP                              ; $0B6F  00
        NOP                              ; $0B70  00
        NOP                              ; $0B71  00
        NOP                              ; $0B72  00
SUB_0B2A_22:
        NOP                              ; $0B73  00
        NOP                              ; $0B74  00
SUB_0B2A_23:
        NOP                              ; $0B75  00
SUB_0B2A_24:
        NOP                              ; $0B76  00
SUB_0B2A_25:
        NOP                              ; $0B77  00
        NOP                              ; $0B78  00
SUB_0B2A_26:
        NOP                              ; $0B79  00
SUB_0B2A_27:
        NOP                              ; $0B7A  00
SUB_0B2A_28:
        NOP                              ; $0B7B  00
        NOP                              ; $0B7C  00
SUB_0B2A_29:
        NOP                              ; $0B7D  00
        NOP                              ; $0B7E  00
SUB_0B2A_30:
        NOP                              ; $0B7F  00
        NOP                              ; $0B80  00
SUB_0B2A_31:
        NOP                              ; $0B81  00
        NOP                              ; $0B82  00
SUB_0B2A_32:
        NOP                              ; $0B83  00
        NOP                              ; $0B84  00
SUB_0B2A_33:
        NOP                              ; $0B85  00
        NOP                              ; $0B86  00
SUB_0B2A_34:
        NOP                              ; $0B87  00
        NOP                              ; $0B88  00
SUB_0B2A_35:
        NOP                              ; $0B89  00
        NOP                              ; $0B8A  00
SUB_0B2A_36:
        NOP                              ; $0B8B  00
SUB_0B2A_37:
        NOP                              ; $0B8C  00
        NOP                              ; $0B8D  00
SUB_0B2A_38:
        NOP                              ; $0B8E  00
        NOP                              ; $0B8F  00
SUB_0B2A_39:
        NOP                              ; $0B90  00
        NOP                              ; $0B91  00
SUB_0B2A_40:
        NOP                              ; $0B92  00
        NOP                              ; $0B93  00
SUB_0B2A_41:
        NOP                              ; $0B94  00
        NOP                              ; $0B95  00
SUB_0B2A_42:
        NOP                              ; $0B96  00
        NOP                              ; $0B97  00
SUB_0B2A_43:
        NOP                              ; $0B98  00
        NOP                              ; $0B99  00
SUB_0B2A_44:
        NOP                              ; $0B9A  00
        NOP                              ; $0B9B  00
        NOP                              ; $0B9C  00
        NOP                              ; $0B9D  00
        NOP                              ; $0B9E  00
        NOP                              ; $0B9F  00
        NOP                              ; $0BA0  00
        NOP                              ; $0BA1  00
        NOP                              ; $0BA2  00
        NOP                              ; $0BA3  00
        NOP                              ; $0BA4  00
        NOP                              ; $0BA5  00
        NOP                              ; $0BA6  00
        NOP                              ; $0BA7  00
        NOP                              ; $0BA8  00
        NOP                              ; $0BA9  00
        NOP                              ; $0BAA  00
        NOP                              ; $0BAB  00
        NOP                              ; $0BAC  00
        NOP                              ; $0BAD  00
        NOP                              ; $0BAE  00
        NOP                              ; $0BAF  00
        NOP                              ; $0BB0  00
        NOP                              ; $0BB1  00
        NOP                              ; $0BB2  00
        NOP                              ; $0BB3  00
SUB_0B2A_45:
        NOP                              ; $0BB4  00
        NOP                              ; $0BB5  00
SUB_0B2A_46:
        NOP                              ; $0BB6  00
        NOP                              ; $0BB7  00
SUB_0B2A_47:
        NOP                              ; $0BB8  00
        NOP                              ; $0BB9  00
        NOP                              ; $0BBA  00
        NOP                              ; $0BBB  00
        NOP                              ; $0BBC  00
        NOP                              ; $0BBD  00
        NOP                              ; $0BBE  00
        NOP                              ; $0BBF  00
        NOP                              ; $0BC0  00
        NOP                              ; $0BC1  00
        NOP                              ; $0BC2  00
        NOP                              ; $0BC3  00
        NOP                              ; $0BC4  00
        NOP                              ; $0BC5  00
        NOP                              ; $0BC6  00
        NOP                              ; $0BC7  00
        NOP                              ; $0BC8  00
        NOP                              ; $0BC9  00
        NOP                              ; $0BCA  00
        NOP                              ; $0BCB  00
        NOP                              ; $0BCC  00
        NOP                              ; $0BCD  00
        NOP                              ; $0BCE  00
        NOP                              ; $0BCF  00
SUB_0B2A_48:
        NOP                              ; $0BD0  00
        NOP                              ; $0BD1  00
        NOP                              ; $0BD2  00
        NOP                              ; $0BD3  00
        NOP                              ; $0BD4  00
        NOP                              ; $0BD5  00
        NOP                              ; $0BD6  00
        NOP                              ; $0BD7  00
        NOP                              ; $0BD8  00
        NOP                              ; $0BD9  00
        NOP                              ; $0BDA  00
        NOP                              ; $0BDB  00
        NOP                              ; $0BDC  00
        NOP                              ; $0BDD  00
        NOP                              ; $0BDE  00
        NOP                              ; $0BDF  00
        NOP                              ; $0BE0  00
        NOP                              ; $0BE1  00
        NOP                              ; $0BE2  00
        NOP                              ; $0BE3  00
SUB_0B2A_49:
        NOP                              ; $0BE4  00
        NOP                              ; $0BE5  00
        NOP                              ; $0BE6  00
        NOP                              ; $0BE7  00
        NOP                              ; $0BE8  00
        NOP                              ; $0BE9  00
        NOP                              ; $0BEA  00
        NOP                              ; $0BEB  00
        NOP                              ; $0BEC  00
        NOP                              ; $0BED  00
        NOP                              ; $0BEE  00
        NOP                              ; $0BEF  00
        NOP                              ; $0BF0  00
        NOP                              ; $0BF1  00
        NOP                              ; $0BF2  00
        NOP                              ; $0BF3  00
        NOP                              ; $0BF4  00
        NOP                              ; $0BF5  00
        NOP                              ; $0BF6  00
        NOP                              ; $0BF7  00
        NOP                              ; $0BF8  00
        NOP                              ; $0BF9  00
        NOP                              ; $0BFA  00
        NOP                              ; $0BFB  00
        NOP                              ; $0BFC  00
        NOP                              ; $0BFD  00
        NOP                              ; $0BFE  00
        NOP                              ; $0BFF  00
        NOP                              ; $0C00  00
        NOP                              ; $0C01  00
        NOP                              ; $0C02  00
SUB_0C03:
        NOP                              ; $0C03  00
        NOP                              ; $0C04  00
        NOP                              ; $0C05  00
        NOP                              ; $0C06  00
        NOP                              ; $0C07  00
        NOP                              ; $0C08  00
        NOP                              ; $0C09  00
        NOP                              ; $0C0A  00
        NOP                              ; $0C0B  00
        NOP                              ; $0C0C  00
        NOP                              ; $0C0D  00
        NOP                              ; $0C0E  00
        NOP                              ; $0C0F  00
        NOP                              ; $0C10  00
        NOP                              ; $0C11  00
        NOP                              ; $0C12  00
        NOP                              ; $0C13  00
        NOP                              ; $0C14  00
        NOP                              ; $0C15  00
        NOP                              ; $0C16  00
        NOP                              ; $0C17  00
        NOP                              ; $0C18  00
        NOP                              ; $0C19  00
        NOP                              ; $0C1A  00
        NOP                              ; $0C1B  00
SUB_0C03_1:
        OR H                             ; $0C1C  B4
        DEC BC                           ; $0C1D  0B
SUB_0C03_2:
        NOP                              ; $0C1E  00
        NOP                              ; $0C1F  00
SUB_0C03_3:
        NOP                              ; $0C20  00
        NOP                              ; $0C21  00
        NOP                              ; $0C22  00
        NOP                              ; $0C23  00
        NOP                              ; $0C24  00
        NOP                              ; $0C25  00
        NOP                              ; $0C26  00
        NOP                              ; $0C27  00
SUB_0C03_4:
        NOP                              ; $0C28  00
        NOP                              ; $0C29  00
        NOP                              ; $0C2A  00
        NOP                              ; $0C2B  00
        NOP                              ; $0C2C  00
        NOP                              ; $0C2D  00
        NOP                              ; $0C2E  00
        NOP                              ; $0C2F  00
        NOP                              ; $0C30  00
        NOP                              ; $0C31  00
        NOP                              ; $0C32  00
        NOP                              ; $0C33  00
        NOP                              ; $0C34  00
        NOP                              ; $0C35  00
        NOP                              ; $0C36  00
        NOP                              ; $0C37  00
SUB_0C03_5:
        NOP                              ; $0C38  00
        NOP                              ; $0C39  00
        NOP                              ; $0C3A  00
        NOP                              ; $0C3B  00
        NOP                              ; $0C3C  00
        NOP                              ; $0C3D  00
        NOP                              ; $0C3E  00
        NOP                              ; $0C3F  00
        NOP                              ; $0C40  00
        NOP                              ; $0C41  00
        NOP                              ; $0C42  00
        NOP                              ; $0C43  00
        NOP                              ; $0C44  00
        NOP                              ; $0C45  00
        NOP                              ; $0C46  00
        NOP                              ; $0C47  00
        NOP                              ; $0C48  00
        NOP                              ; $0C49  00
        NOP                              ; $0C4A  00
SUB_0C4B:
        NOP                              ; $0C4B  00
        NOP                              ; $0C4C  00
        NOP                              ; $0C4D  00
        NOP                              ; $0C4E  00
        NOP                              ; $0C4F  00
        NOP                              ; $0C50  00
        NOP                              ; $0C51  00
        NOP                              ; $0C52  00
        NOP                              ; $0C53  00
        NOP                              ; $0C54  00
        NOP                              ; $0C55  00
        NOP                              ; $0C56  00
        NOP                              ; $0C57  00
        NOP                              ; $0C58  00
        NOP                              ; $0C59  00
        NOP                              ; $0C5A  00
        NOP                              ; $0C5B  00
        NOP                              ; $0C5C  00
        NOP                              ; $0C5D  00
        NOP                              ; $0C5E  00
        NOP                              ; $0C5F  00
        NOP                              ; $0C60  00
        NOP                              ; $0C61  00
        NOP                              ; $0C62  00
        NOP                              ; $0C63  00
        NOP                              ; $0C64  00
        NOP                              ; $0C65  00
        NOP                              ; $0C66  00
        NOP                              ; $0C67  00
        NOP                              ; $0C68  00
        NOP                              ; $0C69  00
        NOP                              ; $0C6A  00
        NOP                              ; $0C6B  00
        NOP                              ; $0C6C  00
        NOP                              ; $0C6D  00
        NOP                              ; $0C6E  00
        NOP                              ; $0C6F  00
        NOP                              ; $0C70  00
        NOP                              ; $0C71  00
        NOP                              ; $0C72  00
        NOP                              ; $0C73  00
        NOP                              ; $0C74  00
        NOP                              ; $0C75  00
        NOP                              ; $0C76  00
        NOP                              ; $0C77  00
        NOP                              ; $0C78  00
        NOP                              ; $0C79  00
        NOP                              ; $0C7A  00
        NOP                              ; $0C7B  00
        NOP                              ; $0C7C  00
        NOP                              ; $0C7D  00
        NOP                              ; $0C7E  00
        NOP                              ; $0C7F  00
        NOP                              ; $0C80  00
        NOP                              ; $0C81  00
        NOP                              ; $0C82  00
        NOP                              ; $0C83  00
SUB_0C4B_1:
        NOP                              ; $0C84  00
SUB_0C4B_2:
        NOP                              ; $0C85  00
SUB_0C4B_3:
        NOP                              ; $0C86  00
SUB_0C4B_4:
        NOP                              ; $0C87  00
SUB_0C4B_5:
        NOP                              ; $0C88  00
        NOP                              ; $0C89  00
SUB_0C4B_6:
        NOP                              ; $0C8A  00
        NOP                              ; $0C8B  00
SUB_0C4B_7:
        NOP                              ; $0C8C  00
SUB_0C4B_8:
        NOP                              ; $0C8D  00
        NOP                              ; $0C8E  00
SUB_0C4B_9:
        NOP                              ; $0C8F  00
SUB_0C4B_10:
        NOP                              ; $0C90  00
        NOP                              ; $0C91  00
        NOP                              ; $0C92  00
        NOP                              ; $0C93  00
SUB_0C4B_11:
        NOP                              ; $0C94  00
        NOP                              ; $0C95  00
SUB_0C4B_12:
        NOP                              ; $0C96  00
SUB_0C4B_13:
        NOP                              ; $0C97  00
SUB_0C98:
        POP HL                           ; $0C98  E1
        POP DE                           ; $0C99  D1
        POP AF                           ; $0C9A  F1
        PUSH AF                          ; $0C9B  F5
        PUSH DE                          ; $0C9C  D5
        JP (HL)                          ; $0C9D  E9
        DEFS    24, $00    ; $0C9E  fill
L_0CB6:
        DEFB    $00,$00                                          ; $0CB6
L_0CB8:
        DEFB    $00,$00                                          ; $0CB8
L_0CBA:
        DEFB    $00,$00                                          ; $0CBA
L_0CBC:
        DEFB    $00                                              ; $0CBC
L_0CBD:
        DEFB    $00                                              ; $0CBD
L_0CBE:
        DEFB    $00                                              ; $0CBE
L_0CBF:
        DEFB    $00,$00                                          ; $0CBF
L_0CC1:
        DEFB    $00,$00                                          ; $0CC1
L_0CC3:
        DEFB    $00                                              ; $0CC3
L_0CC4:
        DEFB    $00,$00                                          ; $0CC4
L_0CC6:
        DEFB    $00,$00,$00,$00,$00,$00,$00                      ; $0CC6
L_0CCD:
        DEFB    $00                                              ; $0CCD
L_0CCE:
        DEFB    $00                                              ; $0CCE
L_0CCF:
        DEFB    $00                                              ; $0CCF
SUB_0C98_1:
        NOP                              ; $0CD0  00
        NOP                              ; $0CD1  00
SUB_0C98_2:
        NOP                              ; $0CD2  00
SUB_0C98_3:
        NOP                              ; $0CD3  00
SUB_0C98_4:
        NOP                              ; $0CD4  00
        NOP                              ; $0CD5  00
SUB_0C98_5:
        NOP                              ; $0CD6  00
SUB_0C98_6:
        NOP                              ; $0CD7  00
SUB_0C98_7:
        NOP                              ; $0CD8  00
SUB_0C98_8:
        NOP                              ; $0CD9  00
SUB_0C98_9:
        NOP                              ; $0CDA  00
SUB_0C98_10:
        NOP                              ; $0CDB  00
SUB_0C98_11:
        NOP                              ; $0CDC  00
SUB_0C98_12:
        NOP                              ; $0CDD  00
        NOP                              ; $0CDE  00
        NOP                              ; $0CDF  00
        NOP                              ; $0CE0  00
        NOP                              ; $0CE1  00
        NOP                              ; $0CE2  00
SUB_0C98_13:
        NOP                              ; $0CE3  00
SUB_0C98_14:
        NOP                              ; $0CE4  00
SUB_0C98_15:
        NOP                              ; $0CE5  00
L_0CE6:
        DEFS    26, $00    ; $0CE6  fill
L_0D00:
        DEFB    $00,$00,$00,$00                                  ; $0D00
SUB_0D04:
        NOP                              ; $0D04  00
        NOP                              ; $0D05  00
SUB_0D04_1:
        NOP                              ; $0D06  00
        NOP                              ; $0D07  00
        NOP                              ; $0D08  00
        NOP                              ; $0D09  00
        NOP                              ; $0D0A  00
SUB_0D04_2:
        NOP                              ; $0D0B  00
        NOP                              ; $0D0C  00
        NOP                              ; $0D0D  00
        NOP                              ; $0D0E  00
        NOP                              ; $0D0F  00
SUB_0D04_3:
        JR NZ,SUB_0D20_15                ; $0D10  20 69
        LD L,(HL)                        ; $0D12  6E
SUB_0D04_4:
        JR NZ,SUB_0D04_5                 ; $0D13  20 00
SUB_0D04_5:
        LD C,A                           ; $0D15  4F
        LD L,E                           ; $0D16  6B
        DEC C                            ; $0D17  0D
        LD A,(BC)                        ; $0D18  0A
        NOP                              ; $0D19  00
SUB_0D04_6:
        LD B,D                           ; $0D1A  42
        LD (HL),D                        ; $0D1B  72
        LD H,L                           ; $0D1C  65
        LD H,C                           ; $0D1D  61
SUB_0D04_7:
        LD L,E                           ; $0D1E  6B
        NOP                              ; $0D1F  00
SUB_0D20:
        LD HL,$0004                      ; $0D20  21 04 00
        ADD HL,SP                        ; $0D23  39
SUB_0D20_1:
        LD A,(HL)                        ; $0D24  7E
        INC HL                           ; $0D25  23
        CP $AF                           ; $0D26  FE AF
SUB_0D20_2:
        JR NZ,SUB_0D20_3                 ; $0D28  20 06
        LD BC,$0006                      ; $0D2A  01 06 00
        ADD HL,BC                        ; $0D2D  09
        JR SUB_0D20_1                    ; $0D2E  18 F4
SUB_0D20_3:
        CP $82                           ; $0D30  FE 82
        RET NZ                           ; $0D32  C0
        LD C,(HL)                        ; $0D33  4E
        INC HL                           ; $0D34  23
        LD B,(HL)                        ; $0D35  46
        INC HL                           ; $0D36  23
        PUSH HL                          ; $0D37  E5
        LD L,C                           ; $0D38  69
        LD H,B                           ; $0D39  60
        LD A,D                           ; $0D3A  7A
        OR E                             ; $0D3B  B3
        EX DE,HL                         ; $0D3C  EB
        JR Z,SUB_0D20_4                  ; $0D3D  28 04
        EX DE,HL                         ; $0D3F  EB
        CALL SUB_459D                    ; $0D40  CD 9D 45
SUB_0D20_4:
        LD BC,$0010                      ; $0D43  01 10 00
        POP HL                           ; $0D46  E1
        RET Z                            ; $0D47  C8
        ADD HL,BC                        ; $0D48  09
        JR SUB_0D20_1                    ; $0D49  18 D9
SUB_0D20_5:
        LD BC,SUB_0D20_38+1              ; $0D4B  01 45 0E
        JP SUB_0D20_30                   ; $0D4E  C3 C4 0D
SUB_0D20_6:
        LD HL,(SUB_0752_43)              ; $0D51  2A 67 08
        LD A,H                           ; $0D54  7C
        AND L                            ; $0D55  A5
        INC A                            ; $0D56  3C
        JR Z,SUB_0D20_7                  ; $0D57  28 08
        LD A,(SUB_0B2A_36)               ; $0D59  3A 8B 0B
        OR A                             ; $0D5C  B7
        LD E,$13                         ; $0D5D  1E 13
        JR NZ,SUB_0D20_28                ; $0D5F  20 4B
SUB_0D20_7:
        JP SUB_45B5_9                    ; $0D61  C3 E7 45
SUB_0D20_8:
        LD E,$3D                         ; $0D64  1E 3D
SUB_0D20_9:
        LD BC,SUB_3809_21                ; $0D66  01 1E 39
SUB_0D20_10:
        LD BC,SUB_3518_23                ; $0D69  01 1E 36
SUB_0D20_11:
        LD BC,SUB_3518_1                 ; $0D6C  01 1E 35
SUB_0D20_12:
        LD BC,SUB_3415_2                 ; $0D6F  01 1E 34
        LD BC,SUB_3289_25+1              ; $0D72  01 1E 33
SUB_0D20_13:
        LD BC,SUB_3D4E_19                ; $0D75  01 1E 3E
SUB_0D20_14:
        LD BC,SUB_370D_2                 ; $0D78  01 1E 37
SUB_0D20_15:
        LD BC,SUB_3FF9_5+1               ; $0D7B  01 1E 40
        LD BC,SUB_3EDB_11                ; $0D7E  01 1E 3F
SUB_0D20_16:
        LD BC,SUB_3212_2+1               ; $0D81  01 1E 32
SUB_0D20_17:
        LD BC,SUB_4300_3+1               ; $0D84  01 1E 43
SUB_0D20_18:
        LD BC,SUB_3A18_1                 ; $0D87  01 1E 3A
        JR SUB_0D20_28                   ; $0D8A  18 20
SUB_0D20_19:
        LD HL,(SUB_0B2A_22)              ; $0D8C  2A 73 0B
        LD (SUB_0752_43),HL              ; $0D8F  22 67 08
SUB_0D20_20:
        LD E,$02                         ; $0D92  1E 02
SUB_0D20_21:
        LD BC,SUB_0925_20                ; $0D94  01 1E 0B
SUB_0D20_22:
        LD BC,SUB_0100_7                 ; $0D97  01 1E 01
SUB_0D20_23:
        LD BC,SUB_0925_9                 ; $0D9A  01 1E 0A
SUB_0D20_24:
        LD BC,SUB_1128_25+2              ; $0D9D  01 1E 12
        LD BC,SUB_1402_4+1               ; $0DA0  01 1E 14
SUB_0D20_25:
        LD BC,L_061E                     ; $0DA3  01 1E 06
SUB_0D20_26:
        LD BC,SUB_15CF_12+1              ; $0DA6  01 1E 16
SUB_0D20_27:
        LD BC,SUB_0D04_7                 ; $0DA9  01 1E 0D
SUB_0D20_28:
        LD HL,(SUB_0752_43)              ; $0DAC  2A 67 08
        LD (SUB_0B2A_32),HL              ; $0DAF  22 83 0B
        XOR A                            ; $0DB2  AF
        LD (L_0CBD),A                    ; $0DB3  32 BD 0C
        LD (L_0CC3),A                    ; $0DB6  32 C3 0C
        LD A,H                           ; $0DB9  7C
        AND L                            ; $0DBA  A5
        INC A                            ; $0DBB  3C
        JR Z,SUB_0D20_29                 ; $0DBC  28 03
        LD (SUB_0B2A_33),HL              ; $0DBE  22 85 0B
SUB_0D20_29:
        LD BC,L_0DCA                     ; $0DC1  01 CA 0D
SUB_0D20_30:
        LD HL,(SUB_0B2A_31)              ; $0DC4  2A 81 0B
        JP SUB_453A_4                    ; $0DC7  C3 72 45
L_0DCA:
        DEFB    $C1,$7B,$4B,$32,$58                              ; $0DCA  "A{K2X"
        DEFB    $08,$2A                                          ; $0DCF
        DEFW    SUB_0B2A_30              ; $0DD1
        DEFB    $22                                              ; $0DD3
        DEFW    SUB_0B2A_34              ; $0DD4
        DEFW    SUB_2AEB                 ; $0DD6
        DEFW    SUB_0B2A_32              ; $0DD8
        DEFB    $7C                                              ; $0DDA
        DEFW    SUB_3C47_8               ; $0DDB
        DEFW    SUB_064E_16              ; $0DDD
        DEFB    $22                                              ; $0DDF
        DEFW    SUB_0B2A_38              ; $0DE0
        DEFB    $EB,$22                                          ; $0DE2
        DEFW    SUB_0B2A_39              ; $0DE4
        DEFB    $2A                                              ; $0DE6
        DEFW    SUB_0B2A_35              ; $0DE7
        DEFB    $7C,$B5,$EB,$21                                  ; $0DE9
        DEFW    SUB_0B2A_36              ; $0DED
        DEFW    SUB_0752_24              ; $0DEF
        DEFW    SUB_20A6                 ; $0DF1
        DEFB    $05,$35,$EB,$C3                                  ; $0DF3
        DEFW    SUB_129A_16              ; $0DF7
        DEFB    $AF,$77                                          ; $0DF9
        DEFW    SUB_3248_3               ; $0DFB
        DEFW    SUB_0752_39              ; $0DFD
        DEFB    $CD                                              ; $0DFF
        DEFW    SUB_43F9                 ; $0E00
        DEFW    SUB_211B_1               ; $0E02
        DEFB    $05,$7B                                          ; $0E04
        DEFW    SUB_475A_8               ; $0E06
        DEFW    SUB_0752_27              ; $0E08
        DEFB    $FE,$32,$30,$06,$FE,$21,$38,$05                  ; $0E0A
SUB_0D20_31:
        LD A,$26                         ; $0E12  3E 26
        SUB $11                          ; $0E14  D6 11
        LD E,A                           ; $0E16  5F
SUB_0D20_32:
        CALL SUB_15CF+2                  ; $0E17  CD D1 15
        INC HL                           ; $0E1A  23
SUB_0D20_33:
        DEC E                            ; $0E1B  1D
        JR NZ,SUB_0D20_32                ; $0E1C  20 F9
        PUSH HL                          ; $0E1E  E5
        LD HL,(SUB_0B2A_32)              ; $0E1F  2A 83 0B
        EX (SP),HL                       ; $0E22  E3
SUB_0D20_34:
        LD A,(HL)                        ; $0E23  7E
        CP $3F                           ; $0E24  FE 3F
        JR NZ,SUB_0D20_36                ; $0E26  20 06
SUB_0D20_35:
        POP HL                           ; $0E28  E1
        LD HL,L_0521                     ; $0E29  21 21 05
        JR SUB_0D20_31                   ; $0E2C  18 E4
SUB_0D20_36:
        CALL SUB_48BE                    ; $0E2E  CD BE 48
        POP HL                           ; $0E31  E1
        LD DE,$FFFE                      ; $0E32  11 FE FF
        CALL SUB_459D                    ; $0E35  CD 9D 45
SUB_0D20_37:
        CALL Z,SUB_4406                  ; $0E38  CC 06 44
        JP Z,SUB_5A3B_5                  ; $0E3B  CA 6B 5A
        LD A,H                           ; $0E3E  7C
        AND L                            ; $0E3F  A5
        INC A                            ; $0E40  3C
        CALL NZ,SUB_3389                 ; $0E41  C4 89 33
SUB_0D20_38:
        LD A,$C1                         ; $0E44  3E C1
SUB_0D20_39:
        CALL SUB_42F7                    ; $0E46  CD F7 42
        XOR A                            ; $0E49  AF
        LD (SUB_0752_39),A               ; $0E4A  32 62 08
        CALL SUB_5498                    ; $0E4D  CD 98 54
        CALL SUB_43F9                    ; $0E50  CD F9 43
        LD HL,SUB_0D04_5                 ; $0E53  21 15 0D
SUB_0D20_40:
        CALL $0000                       ; $0E56  CD 00 00
        LD A,(SUB_0752_33+2)             ; $0E59  3A 58 08
        SUB $02                          ; $0E5C  D6 02
        CALL Z,SUB_3EDB                  ; $0E5E  CC DB 3E
SUB_0D20_41:
        LD HL,$FFFF                      ; $0E61  21 FF FF
        LD (SUB_0752_43),HL              ; $0E64  22 67 08
        LD A,(SUB_0B2A_27)               ; $0E67  3A 7A 0B
        OR A                             ; $0E6A  B7
        JR Z,SUB_0D20_46                 ; $0E6B  28 43
        LD HL,(SUB_0B2A_28)              ; $0E6D  2A 7B 0B
        PUSH HL                          ; $0E70  E5
        CALL SUB_3391                    ; $0E71  CD 91 33
        POP DE                           ; $0E74  D1
        PUSH DE                          ; $0E75  D5
        CALL SUB_0FAB                    ; $0E76  CD AB 0F
        LD A,$2A                         ; $0E79  3E 2A
        JR C,SUB_0D20_42                 ; $0E7B  38 02
        LD A,$20                         ; $0E7D  3E 20
SUB_0D20_42:
        CALL SUB_4291                    ; $0E7F  CD 91 42
        CALL SUB_4CA1                    ; $0E82  CD A1 4C
        POP DE                           ; $0E85  D1
        JR NC,SUB_0D20_44                ; $0E86  30 0C
        XOR A                            ; $0E88  AF
        LD (SUB_0B2A_27),A               ; $0E89  32 7A 0B
        JR SUB_0D20_39                   ; $0E8C  18 B8
SUB_0D20_43:
        XOR A                            ; $0E8E  AF
        LD (SUB_0B2A_27),A               ; $0E8F  32 7A 0B
        JR SUB_0D20_45                   ; $0E92  18 13
SUB_0D20_44:
        LD HL,(SUB_0B2A_29)              ; $0E94  2A 7D 0B
        ADD HL,DE                        ; $0E97  19
        JR C,SUB_0D20_43                 ; $0E98  38 F4
        PUSH DE                          ; $0E9A  D5
        LD DE,$FFF9                      ; $0E9B  11 F9 FF
        CALL SUB_459D                    ; $0E9E  CD 9D 45
        POP DE                           ; $0EA1  D1
        JR NC,SUB_0D20_43                ; $0EA2  30 EA
        LD (SUB_0B2A_28),HL              ; $0EA4  22 7B 0B
SUB_0D20_45:
        LD A,(SUB_0925_12)               ; $0EA7  3A 31 0A
        OR A                             ; $0EAA  B7
        JR Z,SUB_0D20_41                 ; $0EAB  28 B4
        JP SUB_4068_10                   ; $0EAD  C3 C1 40
SUB_0D20_46:
        CALL SUB_4CA1                    ; $0EB0  CD A1 4C
        JR C,SUB_0D20_41                 ; $0EB3  38 AC
        CALL SUB_13E4                    ; $0EB5  CD E4 13
        INC A                            ; $0EB8  3C
        DEC A                            ; $0EB9  3D
        JR Z,SUB_0D20_41                 ; $0EBA  28 A5
        PUSH AF                          ; $0EBC  F5
        CALL SUB_14FB                    ; $0EBD  CD FB 14
        CALL SUB_129A                    ; $0EC0  CD 9A 12
        LD A,(HL)                        ; $0EC3  7E
        CP $20                           ; $0EC4  FE 20
        CALL Z,SUB_2B3D                  ; $0EC6  CC 3D 2B
SUB_0D20_47:
        PUSH DE                          ; $0EC9  D5
        CALL SUB_101B                    ; $0ECA  CD 1B 10
        POP DE                           ; $0ECD  D1
        POP AF                           ; $0ECE  F1
        LD (SUB_0B2A_30),HL              ; $0ECF  22 7F 0B
        JP NC,SUB_5498_5                 ; $0ED2  D2 D0 54
SUB_0D20_48:
        PUSH DE                          ; $0ED5  D5
        PUSH BC                          ; $0ED6  C5
        CALL SUB_5E2A                    ; $0ED7  CD 2A 5E
        CALL SUB_13E4                    ; $0EDA  CD E4 13
        OR A                             ; $0EDD  B7
        PUSH AF                          ; $0EDE  F5
        EX DE,HL                         ; $0EDF  EB
        LD (SUB_0B2A_33),HL              ; $0EE0  22 85 0B
        EX DE,HL                         ; $0EE3  EB
        CALL SUB_0FAB                    ; $0EE4  CD AB 0F
        JR C,SUB_0D20_50                 ; $0EE7  38 06
        POP AF                           ; $0EE9  F1
        PUSH AF                          ; $0EEA  F5
SUB_0D20_49:
        JP Z,SUB_1506_9                  ; $0EEB  CA 91 15
        OR A                             ; $0EEE  B7
SUB_0D20_50:
        PUSH BC                          ; $0EEF  C5
        PUSH AF                          ; $0EF0  F5
        PUSH HL                          ; $0EF1  E5
        CALL SUB_2426                    ; $0EF2  CD 26 24
SUB_0D20_51:
        POP HL                           ; $0EF5  E1
        POP AF                           ; $0EF6  F1
        POP BC                           ; $0EF7  C1
        PUSH BC                          ; $0EF8  C5
        CALL C,SUB_22AF                  ; $0EF9  DC AF 22
        POP DE                           ; $0EFC  D1
        POP AF                           ; $0EFD  F1
SUB_0D20_52:
        PUSH DE                          ; $0EFE  D5
        JR Z,SUB_0F28_3                  ; $0EFF  28 37
        POP DE                           ; $0F01  D1
        LD A,(L_0CC3)                    ; $0F02  3A C3 0C
        OR A                             ; $0F05  B7
        JR NZ,SUB_0D20_53                ; $0F06  20 06
        LD HL,(SUB_0B2A_13)              ; $0F08  2A 46 0B
        LD (SUB_0B2A_19),HL              ; $0F0B  22 6B 0B
SUB_0D20_53:
        LD HL,(SUB_0B2A_40)              ; $0F0E  2A 92 0B
        EX (SP),HL                       ; $0F11  E3
        POP BC                           ; $0F12  C1
        PUSH HL                          ; $0F13  E5
        ADD HL,BC                        ; $0F14  09
        PUSH HL                          ; $0F15  E5
        CALL SUB_448F                    ; $0F16  CD 8F 44
        POP HL                           ; $0F19  E1
        LD (SUB_0B2A_40),HL              ; $0F1A  22 92 0B
        EX DE,HL                         ; $0F1D  EB
        LD (HL),H                        ; $0F1E  74
        POP BC                           ; $0F1F  C1
        POP DE                           ; $0F20  D1
        PUSH HL                          ; $0F21  E5
        INC HL                           ; $0F22  23
        INC HL                           ; $0F23  23
        LD (HL),E                        ; $0F24  73
        INC HL                           ; $0F25  23
SUB_0F26:
        LD (HL),D                        ; $0F26  72
        INC HL                           ; $0F27  23
SUB_0F28:
        LD DE,SUB_0752_69+1              ; $0F28  11 F2 08
        DEC BC                           ; $0F2B  0B
        DEC BC                           ; $0F2C  0B
        DEC BC                           ; $0F2D  0B
        DEC BC                           ; $0F2E  0B
SUB_0F28_1:
        LD A,(DE)                        ; $0F2F  1A
SUB_0F28_2:
        LD (HL),A                        ; $0F30  77
        INC HL                           ; $0F31  23
        INC DE                           ; $0F32  13
        DEC BC                           ; $0F33  0B
        LD A,C                           ; $0F34  79
        OR B                             ; $0F35  B0
        JR NZ,SUB_0F28_1                 ; $0F36  20 F7
SUB_0F28_3:
        POP DE                           ; $0F38  D1
        CALL SUB_0F60                    ; $0F39  CD 60 0F
        LD HL,$0080                      ; $0F3C  21 80 00
        LD (HL),$00                      ; $0F3F  36 00
        LD (SUB_0752_51),HL              ; $0F41  22 73 08
        LD HL,(SUB_0752_40)              ; $0F44  2A 63 08
        LD (SUB_0B2A_37),HL              ; $0F47  22 8C 0B
        CALL SUB_450B                    ; $0F4A  CD 0B 45
        LD HL,(SUB_0752_49)              ; $0F4D  2A 71 08
        LD (SUB_0752_51),HL              ; $0F50  22 73 08
        LD HL,(SUB_0B2A_37)              ; $0F53  2A 8C 0B
        LD (SUB_0752_40),HL              ; $0F56  22 63 08
        JP SUB_0D20_41                   ; $0F59  C3 61 0E
SUB_0F5C:
        LD HL,(SUB_0752_44)              ; $0F5C  2A 69 08
        EX DE,HL                         ; $0F5F  EB
SUB_0F60:
        LD H,D                           ; $0F60  62
        LD L,E                           ; $0F61  6B
        LD A,(HL)                        ; $0F62  7E
        INC HL                           ; $0F63  23
        OR (HL)                          ; $0F64  B6
        RET Z                            ; $0F65  C8
        INC HL                           ; $0F66  23
        INC HL                           ; $0F67  23
SUB_0F60_1:
        INC HL                           ; $0F68  23
        LD A,(HL)                        ; $0F69  7E
SUB_0F60_2:
        OR A                             ; $0F6A  B7
        JR Z,SUB_0F60_3                  ; $0F6B  28 10
        CP $20                           ; $0F6D  FE 20
        JR NC,SUB_0F60_1                 ; $0F6F  30 F7
        CP $0B                           ; $0F71  FE 0B
        JR C,SUB_0F60_1                  ; $0F73  38 F3
        CALL SUB_13E5                    ; $0F75  CD E5 13
        CALL SUB_13E4                    ; $0F78  CD E4 13
        JR SUB_0F60_2                    ; $0F7B  18 ED
SUB_0F60_3:
        INC HL                           ; $0F7D  23
        EX DE,HL                         ; $0F7E  EB
        LD (HL),E                        ; $0F7F  73
        INC HL                           ; $0F80  23
        LD (HL),D                        ; $0F81  72
        JR SUB_0F60                      ; $0F82  18 DC
SUB_0F84:
        LD DE,$0000                      ; $0F84  11 00 00
        PUSH DE                          ; $0F87  D5
        JR Z,SUB_0F84_2                  ; $0F88  28 14
        POP DE                           ; $0F8A  D1
        CALL SUB_14F0                    ; $0F8B  CD F0 14
        PUSH DE                          ; $0F8E  D5
        JR Z,SUB_0F84_3                  ; $0F8F  28 16
        LD A,(HL)                        ; $0F91  7E
        CP $2C                           ; $0F92  FE 2C
        JR Z,SUB_0F84_1                  ; $0F94  28 05
        CP $F3                           ; $0F96  FE F3
        JP NZ,SUB_0D20_20                ; $0F98  C2 92 0D
SUB_0F84_1:
        CALL SUB_13E4                    ; $0F9B  CD E4 13
SUB_0F84_2:
        LD DE,$FFFA                      ; $0F9E  11 FA FF
        CALL NZ,SUB_14F0                 ; $0FA1  C4 F0 14
        JP NZ,SUB_0D20_20                ; $0FA4  C2 92 0D
SUB_0F84_3:
        EX DE,HL                         ; $0FA7  EB
        POP DE                           ; $0FA8  D1
SUB_0FA9:
        EX (SP),HL                       ; $0FA9  E3
        PUSH HL                          ; $0FAA  E5
SUB_0FAB:
        LD HL,(SUB_0752_44)              ; $0FAB  2A 69 08
SUB_0FAB_1:
        LD B,H                           ; $0FAE  44
        LD C,L                           ; $0FAF  4D
        LD A,(HL)                        ; $0FB0  7E
        INC HL                           ; $0FB1  23
        OR (HL)                          ; $0FB2  B6
        DEC HL                           ; $0FB3  2B
        RET Z                            ; $0FB4  C8
        INC HL                           ; $0FB5  23
        INC HL                           ; $0FB6  23
        LD A,(HL)                        ; $0FB7  7E
        INC HL                           ; $0FB8  23
        LD H,(HL)                        ; $0FB9  66
        LD L,A                           ; $0FBA  6F
        CALL SUB_459D                    ; $0FBB  CD 9D 45
        LD H,B                           ; $0FBE  60
        LD L,C                           ; $0FBF  69
        LD A,(HL)                        ; $0FC0  7E
        INC HL                           ; $0FC1  23
        LD H,(HL)                        ; $0FC2  66
SUB_0FAB_2:
        LD L,A                           ; $0FC3  6F
        CCF                              ; $0FC4  3F
SUB_0FAB_3:
        RET Z                            ; $0FC5  C8
        CCF                              ; $0FC6  3F
        RET NC                           ; $0FC7  D0
        JR SUB_0FAB_1                    ; $0FC8  18 E4
SUB_0FAB_4:
        CALL SUB_13E5                    ; $0FCA  CD E5 13
        CP $23                           ; $0FCD  FE 23
        RET Z                            ; $0FCF  C8
        PUSH HL                          ; $0FD0  E5
        CALL SUB_1A8C_1+1                ; $0FD1  CD 90 1A
        CALL SUB_1DE3                    ; $0FD4  CD E3 1D
        JR Z,SUB_0FAB_5                  ; $0FD7  28 08
        CALL SUB_52B5                    ; $0FD9  CD B5 52
        POP DE                           ; $0FDC  D1
        POP DE                           ; $0FDD  D1
        JP SUB_5BB1_3                    ; $0FDE  C3 EA 5B
SUB_0FAB_5:
        POP HL                           ; $0FE1  E1
        CALL SUB_3BB3                    ; $0FE2  CD B3 3B
        CALL SUB_1DE3                    ; $0FE5  CD E3 1D
        JP NZ,SUB_14E4_2                 ; $0FE8  C2 EB 14
        PUSH HL                          ; $0FEB  E5
        LD A,(DE)                        ; $0FEC  1A
        OR A                             ; $0FED  B7
        JR Z,SUB_0FAB_7                  ; $0FEE  28 0F
        PUSH DE                          ; $0FF0  D5
        EX DE,HL                         ; $0FF1  EB
SUB_0FAB_6:
        INC HL                           ; $0FF2  23
        LD E,(HL)                        ; $0FF3  5E
        INC HL                           ; $0FF4  23
        LD D,(HL)                        ; $0FF5  56
        LD HL,(SUB_0B2A_40)              ; $0FF6  2A 92 0B
        CALL SUB_459D                    ; $0FF9  CD 9D 45
        POP DE                           ; $0FFC  D1
        JR C,SUB_0FAB_9+1                ; $0FFD  38 0B
SUB_0FAB_7:
        LD A,$01                         ; $0FFF  3E 01
SUB_0FAB_8:
        PUSH DE                          ; $1001  D5
        CALL SUB_48D6                    ; $1002  CD D6 48
        POP HL                           ; $1005  E1
        CALL SUB_4860                    ; $1006  CD 60 48
SUB_0FAB_9:
        CP $EB                           ; $1009  FE EB
        LD (HL),$01                      ; $100B  36 01
        INC HL                           ; $100D  23
        LD E,(HL)                        ; $100E  5E
        INC HL                           ; $100F  23
        LD D,(HL)                        ; $1010  56
        CALL SUB_4472                    ; $1011  CD 72 44
        CALL Z,SUB_43A2                  ; $1014  CC A2 43
        LD (DE),A                        ; $1017  12
        POP HL                           ; $1018  E1
        POP BC                           ; $1019  C1
        RET                              ; $101A  C9
SUB_101B:
        XOR A                            ; $101B  AF
        LD (SUB_0B2A_7),A                ; $101C  32 39 0B
        LD (SUB_0B2A_6),A                ; $101F  32 38 0B
        LD BC,SUB_0100_10                ; $1022  01 3B 01
        LD DE,SUB_0752_69+1              ; $1025  11 F2 08
SUB_101B_1:
        LD A,(HL)                        ; $1028  7E
        CP $22                           ; $1029  FE 22
        JP Z,SUB_1128_28                 ; $102B  CA 32 12
        CP $20                           ; $102E  FE 20
        JP Z,SUB_1128_24                 ; $1030  CA 0C 12
        OR A                             ; $1033  B7
        JP Z,SUB_1128_30                 ; $1034  CA 3A 12
        LD A,(SUB_0B2A_6)                ; $1037  3A 38 0B
        OR A                             ; $103A  B7
        LD A,(HL)                        ; $103B  7E
        JP NZ,SUB_1128_24                ; $103C  C2 0C 12
        CP $3F                           ; $103F  FE 3F
        LD A,$91                         ; $1041  3E 91
        PUSH DE                          ; $1043  D5
        PUSH BC                          ; $1044  C5
        JP Z,SUB_101B_7                  ; $1045  CA 03 11
        LD DE,L_04D8                     ; $1048  11 D8 04
        CALL SUB_1CE7                    ; $104B  CD E7 1C
        CALL SUB_46BF                    ; $104E  CD BF 46
        JP C,SUB_1128_6                  ; $1051  DA 57 11
        PUSH HL                          ; $1054  E5
        LD BC,L_1097                     ; $1055  01 97 10
        PUSH BC                          ; $1058  C5
        CP $47                           ; $1059  FE 47
        RET NZ                           ; $105B  C0
        INC HL                           ; $105C  23
        CALL SUB_1CE7                    ; $105D  CD E7 1C
        CP $4F                           ; $1060  FE 4F
        RET NZ                           ; $1062  C0
        INC HL                           ; $1063  23
        CALL SUB_1CE7                    ; $1064  CD E7 1C
        CP $20                           ; $1067  FE 20
SUB_101B_2:
        RET NZ                           ; $1069  C0
        INC HL                           ; $106A  23
SUB_101B_3:
        CALL SUB_1CE7                    ; $106B  CD E7 1C
        INC HL                           ; $106E  23
        CP $20                           ; $106F  FE 20
        JR Z,SUB_101B_3                  ; $1071  28 F8
        CP $53                           ; $1073  FE 53
        JR Z,SUB_101B_5                  ; $1075  28 0C
        CP $54                           ; $1077  FE 54
        RET NZ                           ; $1079  C0
SUB_101B_4:
        CALL SUB_1CE7                    ; $107A  CD E7 1C
        CP $4F                           ; $107D  FE 4F
        LD A,$89                         ; $107F  3E 89
        JR SUB_101B_6                    ; $1081  18 0E
SUB_101B_5:
        CALL SUB_1CE7                    ; $1083  CD E7 1C
        CP $55                           ; $1086  FE 55
        RET NZ                           ; $1088  C0
        INC HL                           ; $1089  23
        CALL SUB_1CE7                    ; $108A  CD E7 1C
        CP $42                           ; $108D  FE 42
        LD A,$8D                         ; $108F  3E 8D
SUB_101B_6:
        RET NZ                           ; $1091  C0
        POP BC                           ; $1092  C1
        POP BC                           ; $1093  C1
        JP SUB_101B_7                    ; $1094  C3 03 11
L_1097:
        DEFB    $E1,$CD                                          ; $1097
        DEFW    SUB_1CE7                 ; $1099
        DEFB    $E5                                              ; $109B
        DEFW    SUB_1E1D_1               ; $109C
        DEFB    $02                                              ; $109E
        DEFW    SUB_4068_36              ; $109F
        DEFB    $87                                              ; $10A1
        DEFW    SUB_064E_1               ; $10A2
        DEFW    SUB_0752_70              ; $10A4
        DEFW    SUB_22E1_15              ; $10A6
        DEFB    $56,$E1,$23,$E5,$CD                              ; $10A8
        DEFW    SUB_1CE7                 ; $10AD
        DEFB    $4F,$1A,$E6,$7F,$CA                              ; $10AF
        DEFW    SUB_124F_2               ; $10B4
        DEFB    $23,$B9,$20,$3E,$1A,$13,$B7,$F2,$AC,$10,$79      ; $10B6
        DEFW    SUB_28F5_2               ; $10C1
        DEFW    SUB_15CF_34              ; $10C3
        DEFB    $1A,$FE,$E2                                      ; $10C5
        DEFW    SUB_129A_8               ; $10C8
        DEFB    $FE                                              ; $10CA
        DEFW    SUB_28E1                 ; $10CB
        DEFB    $0F,$CD                                          ; $10CD
        DEFW    SUB_1CE7                 ; $10CF
        DEFB    $FE                                              ; $10D1
        DEFW    SUB_2824_1               ; $10D2
        DEFB    $03                                              ; $10D4
        DEFB    $CD,$FC,$21,$3E,$00                              ; $10D5  "M|!>"
        DEFB    $D2                                              ; $10DA
        DEFW    SUB_124F_2               ; $10DB
        DEFW    SUB_1A93_9               ; $10DD
        DEFB    $B7,$FA,$02,$11,$C1,$D1,$F6,$80                  ; $10DF
        DEFW    SUB_3EDB_7               ; $10E7
        DEFB    $FF                                              ; $10E9
        DEFW    SUB_4E80_5               ; $10EA
        DEFB    $12,$AF                                          ; $10EC
        DEFW    SUB_3809_24              ; $10EE
        DEFB    $0B,$F1                                          ; $10F0
        DEFW    SUB_4E80_5               ; $10F2
        DEFB    $12                                              ; $10F4
        DEFW    SUB_2874_14              ; $10F5
        DEFB    $10,$E1,$1A,$13,$B7,$F2,$F9,$10,$13,$18          ; $10F7
        DEFW    SUB_2B9B_1               ; $1101
SUB_101B_7:
        PUSH AF                          ; $1103  F5
        LD BC,SUB_1128_3+1               ; $1104  01 35 11
        PUSH BC                          ; $1107  C5
        CP $8C                           ; $1108  FE 8C
        RET Z                            ; $110A  C8
        CP $A7                           ; $110B  FE A7
        RET Z                            ; $110D  C8
SUB_101B_8:
        CP $A8                           ; $110E  FE A8
        RET Z                            ; $1110  C8
        CP $A6                           ; $1111  FE A6
        RET Z                            ; $1113  C8
        CP $A3                           ; $1114  FE A3
        RET Z                            ; $1116  C8
        CP $A5                           ; $1117  FE A5
        RET Z                            ; $1119  C8
SUB_101B_9:
        CP $E5                           ; $111A  FE E5
        RET Z                            ; $111C  C8
        CP $9E                           ; $111D  FE 9E
        RET Z                            ; $111F  C8
SUB_101B_10:
        CP $8A                           ; $1120  FE 8A
        RET Z                            ; $1122  C8
        CP $93                           ; $1123  FE 93
        RET Z                            ; $1125  C8
        CP $9C                           ; $1126  FE 9C
SUB_1128:
        RET Z                            ; $1128  C8
        CP $89                           ; $1129  FE 89
SUB_1128_1:
        RET Z                            ; $112B  C8
SUB_1128_2:
        CP $DE                           ; $112C  FE DE
        RET Z                            ; $112E  C8
        CP $8D                           ; $112F  FE 8D
        RET Z                            ; $1131  C8
        POP AF                           ; $1132  F1
        XOR A                            ; $1133  AF
SUB_1128_3:
        JP NZ,SUB_0100_11                ; $1134  C2 3E 01
SUB_1128_4:
        LD (SUB_0B2A_7),A                ; $1137  32 39 0B
        POP AF                           ; $113A  F1
SUB_1128_5:
        POP BC                           ; $113B  C1
        POP DE                           ; $113C  D1
        CP $9E                           ; $113D  FE 9E
        PUSH AF                          ; $113F  F5
        CALL Z,SUB_124D                  ; $1140  CC 4D 12
        POP AF                           ; $1143  F1
        CP $EA                           ; $1144  FE EA
        JP NZ,SUB_1128_22                ; $1146  C2 EC 11
        PUSH AF                          ; $1149  F5
        CALL SUB_124D                    ; $114A  CD 4D 12
        LD A,$8F                         ; $114D  3E 8F
        CALL SUB_124F                    ; $114F  CD 4F 12
        POP AF                           ; $1152  F1
        PUSH AF                          ; $1153  F5
        JP SUB_1128_29                   ; $1154  C3 34 12
SUB_1128_6:
        LD A,(HL)                        ; $1157  7E
        CP $2E                           ; $1158  FE 2E
        JR Z,SUB_1128_7                  ; $115A  28 0A
        CP $3A                           ; $115C  FE 3A
        JP NC,SUB_1128_19                ; $115E  D2 DA 11
        CP $30                           ; $1161  FE 30
        JP C,SUB_1128_19                 ; $1163  DA DA 11
SUB_1128_7:
        LD A,(SUB_0B2A_7)                ; $1166  3A 39 0B
        OR A                             ; $1169  B7
        LD A,(HL)                        ; $116A  7E
        POP BC                           ; $116B  C1
        POP DE                           ; $116C  D1
        JP M,SUB_1128_24                 ; $116D  FA 0C 12
        JR Z,SUB_1128_13                 ; $1170  28 1F
SUB_1128_8:
        CP $2E                           ; $1172  FE 2E
        JP Z,SUB_1128_24                 ; $1174  CA 0C 12
        LD A,$0E                         ; $1177  3E 0E
        CALL SUB_124F                    ; $1179  CD 4F 12
        PUSH DE                          ; $117C  D5
        CALL SUB_14FB                    ; $117D  CD FB 14
SUB_1128_9:
        CALL SUB_129A                    ; $1180  CD 9A 12
SUB_1128_10:
        EX (SP),HL                       ; $1183  E3
        EX DE,HL                         ; $1184  EB
SUB_1128_11:
        LD A,L                           ; $1185  7D
        CALL SUB_124F                    ; $1186  CD 4F 12
        LD A,H                           ; $1189  7C
SUB_1128_12:
        POP HL                           ; $118A  E1
        CALL SUB_124F                    ; $118B  CD 4F 12
        JP SUB_101B_1                    ; $118E  C3 28 10
SUB_1128_13:
        PUSH DE                          ; $1191  D5
        PUSH BC                          ; $1192  C5
        LD A,(HL)                        ; $1193  7E
        CALL SUB_311E_1+1                ; $1194  CD 25 31
        CALL SUB_129A                    ; $1197  CD 9A 12
        POP BC                           ; $119A  C1
        POP DE                           ; $119B  D1
        PUSH HL                          ; $119C  E5
        LD A,(SUB_0B2A_5)                ; $119D  3A 37 0B
        CP $02                           ; $11A0  FE 02
        JR NZ,SUB_1128_15                ; $11A2  20 15
        LD HL,(SUB_0C98_4)               ; $11A4  2A D4 0C
        LD A,H                           ; $11A7  7C
        OR A                             ; $11A8  B7
        LD A,$02                         ; $11A9  3E 02
        JR NZ,SUB_1128_15                ; $11AB  20 0C
        LD A,L                           ; $11AD  7D
        LD H,L                           ; $11AE  65
        LD L,$0F                         ; $11AF  2E 0F
        CP $0A                           ; $11B1  FE 0A
        JR NC,SUB_1128_11                ; $11B3  30 D0
SUB_1128_14:
        ADD A,$11                        ; $11B5  C6 11
        JR SUB_1128_12                   ; $11B7  18 D1
SUB_1128_15:
        PUSH AF                          ; $11B9  F5
        RRCA                             ; $11BA  0F
        ADD A,$1B                        ; $11BB  C6 1B
        CALL SUB_124F                    ; $11BD  CD 4F 12
        LD HL,SUB_0C98_4                 ; $11C0  21 D4 0C
        CALL SUB_1DE3                    ; $11C3  CD E3 1D
        JR C,SUB_1128_16                 ; $11C6  38 03
        LD HL,SUB_0C98_1                 ; $11C8  21 D0 0C
SUB_1128_16:
        POP AF                           ; $11CB  F1
SUB_1128_17:
        PUSH AF                          ; $11CC  F5
        LD A,(HL)                        ; $11CD  7E
SUB_1128_18:
        CALL SUB_124F                    ; $11CE  CD 4F 12
        POP AF                           ; $11D1  F1
        INC HL                           ; $11D2  23
        DEC A                            ; $11D3  3D
        JR NZ,SUB_1128_17                ; $11D4  20 F6
        POP HL                           ; $11D6  E1
        JP SUB_101B_1                    ; $11D7  C3 28 10
SUB_1128_19:
        LD DE,L_04D7                     ; $11DA  11 D7 04
SUB_1128_20:
        INC DE                           ; $11DD  13
        LD A,(DE)                        ; $11DE  1A
        AND $7F                          ; $11DF  E6 7F
        JP Z,SUB_124F_5                  ; $11E1  CA 80 12
        INC DE                           ; $11E4  13
SUB_1128_21:
        CP (HL)                          ; $11E5  BE
        LD A,(DE)                        ; $11E6  1A
        JR NZ,SUB_1128_20                ; $11E7  20 F4
        JP SUB_124F_7                    ; $11E9  C3 8F 12
SUB_1128_22:
        CP $26                           ; $11EC  FE 26
        JR NZ,SUB_1128_24                ; $11EE  20 1C
        PUSH HL                          ; $11F0  E5
        CALL SUB_13E4                    ; $11F1  CD E4 13
        POP HL                           ; $11F4  E1
        CALL SUB_1CE8                    ; $11F5  CD E8 1C
        CP $48                           ; $11F8  FE 48
        LD A,$0B                         ; $11FA  3E 0B
        JR NZ,SUB_1128_23                ; $11FC  20 02
        LD A,$0C                         ; $11FE  3E 0C
SUB_1128_23:
        CALL SUB_124F                    ; $1200  CD 4F 12
        PUSH DE                          ; $1203  D5
        PUSH BC                          ; $1204  C5
        CALL SUB_1CF6                    ; $1205  CD F6 1C
        POP BC                           ; $1208  C1
        JP SUB_1128_10                   ; $1209  C3 83 11
SUB_1128_24:
        INC HL                           ; $120C  23
        PUSH AF                          ; $120D  F5
        CALL SUB_124F                    ; $120E  CD 4F 12
        POP AF                           ; $1211  F1
        SUB $3A                          ; $1212  D6 3A
        JR Z,SUB_1128_25                 ; $1214  28 06
        CP $4A                           ; $1216  FE 4A
        JR NZ,SUB_1128_26                ; $1218  20 08
        LD A,$01                         ; $121A  3E 01
SUB_1128_25:
        LD (SUB_0B2A_6),A                ; $121C  32 38 0B
        LD (SUB_0B2A_7),A                ; $121F  32 39 0B
SUB_1128_26:
        SUB $55                          ; $1222  D6 55
        JP NZ,SUB_101B_1                 ; $1224  C2 28 10
        PUSH AF                          ; $1227  F5
SUB_1128_27:
        LD A,(HL)                        ; $1228  7E
        OR A                             ; $1229  B7
        EX (SP),HL                       ; $122A  E3
        LD A,H                           ; $122B  7C
        POP HL                           ; $122C  E1
        JR Z,SUB_1128_30                 ; $122D  28 0B
        CP (HL)                          ; $122F  BE
        JR Z,SUB_1128_24                 ; $1230  28 DA
SUB_1128_28:
        PUSH AF                          ; $1232  F5
        LD A,(HL)                        ; $1233  7E
SUB_1128_29:
        INC HL                           ; $1234  23
        CALL SUB_124F                    ; $1235  CD 4F 12
        JR SUB_1128_27                   ; $1238  18 EE
SUB_1128_30:
        LD HL,SUB_0100_12+1              ; $123A  21 40 01
        LD A,L                           ; $123D  7D
        SUB C                            ; $123E  91
        LD C,A                           ; $123F  4F
        LD A,H                           ; $1240  7C
        SBC A,B                          ; $1241  98
        LD B,A                           ; $1242  47
        LD HL,SUB_0752_69                ; $1243  21 F1 08
        XOR A                            ; $1246  AF
        LD (DE),A                        ; $1247  12
        INC DE                           ; $1248  13
        LD (DE),A                        ; $1249  12
        INC DE                           ; $124A  13
        LD (DE),A                        ; $124B  12
        RET                              ; $124C  C9
SUB_124D:
        LD A,$3A                         ; $124D  3E 3A
SUB_124F:
        LD (DE),A                        ; $124F  12
        INC DE                           ; $1250  13
        DEC BC                           ; $1251  0B
        LD A,C                           ; $1252  79
        OR B                             ; $1253  B0
        RET NZ                           ; $1254  C0
SUB_124F_1:
        LD E,$17                         ; $1255  1E 17
        JP SUB_0D20_28                   ; $1257  C3 AC 0D
SUB_124F_2:
        POP HL                           ; $125A  E1
        DEC HL                           ; $125B  2B
        DEC A                            ; $125C  3D
        LD (SUB_0B2A_7),A                ; $125D  32 39 0B
        POP BC                           ; $1260  C1
        POP DE                           ; $1261  D1
        CALL SUB_1CE7                    ; $1262  CD E7 1C
SUB_124F_3:
        CALL SUB_124F                    ; $1265  CD 4F 12
        INC HL                           ; $1268  23
        CALL SUB_1CE7                    ; $1269  CD E7 1C
        CALL SUB_46BF                    ; $126C  CD BF 46
        JR NC,SUB_124F_3                 ; $126F  30 F4
        CP $3A                           ; $1271  FE 3A
        JR NC,SUB_124F_4                 ; $1273  30 08
        CP $30                           ; $1275  FE 30
        JR NC,SUB_124F_3                 ; $1277  30 EC
        CP $2E                           ; $1279  FE 2E
        JR Z,SUB_124F_3                  ; $127B  28 E8
SUB_124F_4:
        JP SUB_101B_1                    ; $127D  C3 28 10
SUB_124F_5:
        LD A,(HL)                        ; $1280  7E
SUB_124F_6:
        CP $20                           ; $1281  FE 20
        JR NC,SUB_124F_7                 ; $1283  30 0A
        CP $09                           ; $1285  FE 09
        JR Z,SUB_124F_7                  ; $1287  28 06
        CP $0A                           ; $1289  FE 0A
        JR Z,SUB_124F_7                  ; $128B  28 02
        LD A,$20                         ; $128D  3E 20
SUB_124F_7:
        PUSH AF                          ; $128F  F5
        LD A,(SUB_0B2A_7)                ; $1290  3A 39 0B
        INC A                            ; $1293  3C
        JR Z,SUB_124F_8                  ; $1294  28 01
        DEC A                            ; $1296  3D
SUB_124F_8:
        JP SUB_1128_4                    ; $1297  C3 37 11
SUB_129A:
        DEC HL                           ; $129A  2B
        LD A,(HL)                        ; $129B  7E
        CP $20                           ; $129C  FE 20
        JR Z,SUB_129A                    ; $129E  28 FA
        CP $09                           ; $12A0  FE 09
        JR Z,SUB_129A                    ; $12A2  28 F6
SUB_129A_1:
        CP $0A                           ; $12A4  FE 0A
        JR Z,SUB_129A                    ; $12A6  28 F2
        INC HL                           ; $12A8  23
        RET                              ; $12A9  C9
SUB_129A_2:
        LD A,$64                         ; $12AA  3E 64
        LD (SUB_0B2A_23),A               ; $12AC  32 75 0B
        CALL SUB_3BB3                    ; $12AF  CD B3 3B
        CALL SUB_45A3                    ; $12B2  CD A3 45
        RET P                            ; $12B5  F0
        PUSH DE                          ; $12B6  D5
        EX DE,HL                         ; $12B7  EB
        LD (SUB_0B2A_25),HL              ; $12B8  22 77 0B
        EX DE,HL                         ; $12BB  EB
        LD A,(SUB_0B2A_5)                ; $12BC  3A 37 0B
        PUSH AF                          ; $12BF  F5
        CALL SUB_1A8C_1+1                ; $12C0  CD 90 1A
        POP AF                           ; $12C3  F1
        PUSH HL                          ; $12C4  E5
        CALL SUB_201A                    ; $12C5  CD 1A 20
        LD HL,SUB_0C4B_10                ; $12C8  21 90 0C
        CALL SUB_2B3F                    ; $12CB  CD 3F 2B
        POP HL                           ; $12CE  E1
        POP DE                           ; $12CF  D1
        POP BC                           ; $12D0  C1
SUB_129A_3:
        PUSH HL                          ; $12D1  E5
        CALL SUB_15CF                    ; $12D2  CD CF 15
        LD ($0B71),HL                    ; $12D5  22 71 0B
        LD HL,$0002                      ; $12D8  21 02 00
        ADD HL,SP                        ; $12DB  39
SUB_129A_4:
        CALL SUB_0D20_1                  ; $12DC  CD 24 0D
        POP DE                           ; $12DF  D1
        JR NZ,SUB_129A_5                 ; $12E0  20 18
        ADD HL,BC                        ; $12E2  09
        PUSH DE                          ; $12E3  D5
        DEC HL                           ; $12E4  2B
        LD D,(HL)                        ; $12E5  56
        DEC HL                           ; $12E6  2B
        LD E,(HL)                        ; $12E7  5E
        INC HL                           ; $12E8  23
        INC HL                           ; $12E9  23
        PUSH HL                          ; $12EA  E5
        LD HL,($0B71)                    ; $12EB  2A 71 0B
        CALL SUB_459D                    ; $12EE  CD 9D 45
        POP HL                           ; $12F1  E1
        JP NZ,SUB_129A_4                 ; $12F2  C2 DC 12
        POP DE                           ; $12F5  D1
        LD SP,HL                         ; $12F6  F9
        LD (SUB_0B2A_31),HL              ; $12F7  22 81 0B
SUB_129A_5:
        EX DE,HL                         ; $12FA  EB
        LD C,$08                         ; $12FB  0E 08
        CALL SUB_449F                    ; $12FD  CD 9F 44
        PUSH HL                          ; $1300  E5
        LD HL,($0B71)                    ; $1301  2A 71 0B
        EX (SP),HL                       ; $1304  E3
        PUSH HL                          ; $1305  E5
        LD HL,(SUB_0752_43)              ; $1306  2A 67 08
        EX (SP),HL                       ; $1309  E3
        CALL SUB_45A3                    ; $130A  CD A3 45
        DEFB $DD  ; ignored IX prefix; inner: CALL SUB_1DE3 ; $130D  DD CD E3 1D
SUB_129A_6:
        CALL SUB_1DE3                    ; $130E  CD E3 1D
        JP Z,SUB_0D20_27+1               ; $1311  CA AA 0D
SUB_129A_7:
        JP NC,SUB_0D20_27+1              ; $1314  D2 AA 0D
        PUSH AF                          ; $1317  F5
        CALL SUB_1A8C_1+1                ; $1318  CD 90 1A
        POP AF                           ; $131B  F1
        PUSH HL                          ; $131C  E5
        JP P,SUB_129A_9                  ; $131D  F2 35 13
        CALL SUB_2BF4                    ; $1320  CD F4 2B
        EX (SP),HL                       ; $1323  E3
        LD DE,$0001                      ; $1324  11 01 00
        LD A,(HL)                        ; $1327  7E
SUB_129A_8:
        CP $E0                           ; $1328  FE E0
        CALL Z,SUB_20A0                  ; $132A  CC A0 20
        PUSH DE                          ; $132D  D5
        PUSH HL                          ; $132E  E5
        EX DE,HL                         ; $132F  EB
        CALL SUB_2B12                    ; $1330  CD 12 2B
        JR SUB_129A_10                   ; $1333  18 22
SUB_129A_9:
        CALL SUB_2C6C                    ; $1335  CD 6C 2C
        CALL SUB_2B33                    ; $1338  CD 33 2B
        POP HL                           ; $133B  E1
        PUSH BC                          ; $133C  C5
        PUSH DE                          ; $133D  D5
        LD BC,$8100                      ; $133E  01 00 81
        LD D,C                           ; $1341  51
        LD E,D                           ; $1342  5A
        LD A,(HL)                        ; $1343  7E
        CP $E0                           ; $1344  FE E0
        LD A,$01                         ; $1346  3E 01
        JR NZ,SUB_129A_11                ; $1348  20 0E
        CALL SUB_1A91                    ; $134A  CD 91 1A
        PUSH HL                          ; $134D  E5
        CALL SUB_2C6C                    ; $134E  CD 6C 2C
        CALL SUB_2B33                    ; $1351  CD 33 2B
        CALL SUB_2AC5                    ; $1354  CD C5 2A
SUB_129A_10:
        POP HL                           ; $1357  E1
SUB_129A_11:
        PUSH BC                          ; $1358  C5
        PUSH DE                          ; $1359  D5
        LD C,A                           ; $135A  4F
        CALL SUB_1DE3                    ; $135B  CD E3 1D
        LD B,A                           ; $135E  47
        PUSH BC                          ; $135F  C5
        DEC HL                           ; $1360  2B
        CALL SUB_13E4                    ; $1361  CD E4 13
        JP NZ,SUB_0D20_20                ; $1364  C2 92 0D
        CALL SUB_24D1                    ; $1367  CD D1 24
        CALL SUB_13E4                    ; $136A  CD E4 13
        PUSH HL                          ; $136D  E5
        PUSH HL                          ; $136E  E5
SUB_129A_12:
        LD HL,(SUB_0C4B_11)              ; $136F  2A 94 0C
        LD (SUB_0752_43),HL              ; $1372  22 67 08
        LD HL,(SUB_0B2A_25)              ; $1375  2A 77 0B
        EX (SP),HL                       ; $1378  E3
        LD B,$82                         ; $1379  06 82
        PUSH BC                          ; $137B  C5
        INC SP                           ; $137C  33
        PUSH AF                          ; $137D  F5
        PUSH AF                          ; $137E  F5
        JP SUB_46BF_1                    ; $137F  C3 52 47
SUB_129A_13:
        LD B,$82                         ; $1382  06 82
        PUSH BC                          ; $1384  C5
        INC SP                           ; $1385  33
SUB_129A_14:
        PUSH HL                          ; $1386  E5
SUB_129A_15:
        CALL $0000                       ; $1387  CD 00 00
        POP HL                           ; $138A  E1
        OR A                             ; $138B  B7
        CALL NZ,SUB_4437                 ; $138C  C4 37 44
        LD (SUB_0B2A_30),HL              ; $138F  22 7F 0B
        LD (SUB_0B2A_31),SP              ; $1392  ED 73 81 0B
        LD A,(HL)                        ; $1396  7E
        CP $3A                           ; $1397  FE 3A
        JR Z,SUB_129A_18                 ; $1399  28 29
        OR A                             ; $139B  B7
        JP NZ,SUB_0D20_20                ; $139C  C2 92 0D
        INC HL                           ; $139F  23
SUB_129A_16:
        LD A,(HL)                        ; $13A0  7E
        INC HL                           ; $13A1  23
        OR (HL)                          ; $13A2  B6
        JP Z,SUB_0D20_6                  ; $13A3  CA 51 0D
        INC HL                           ; $13A6  23
        LD E,(HL)                        ; $13A7  5E
        INC HL                           ; $13A8  23
        LD D,(HL)                        ; $13A9  56
        EX DE,HL                         ; $13AA  EB
        LD (SUB_0752_43),HL              ; $13AB  22 67 08
        LD A,(L_0CCE)                    ; $13AE  3A CE 0C
        OR A                             ; $13B1  B7
        JR Z,SUB_129A_17                 ; $13B2  28 0F
        PUSH DE                          ; $13B4  D5
        LD A,$5B                         ; $13B5  3E 5B
        CALL SUB_4291                    ; $13B7  CD 91 42
        CALL SUB_3391                    ; $13BA  CD 91 33
        LD A,$5D                         ; $13BD  3E 5D
        CALL SUB_4291                    ; $13BF  CD 91 42
        POP DE                           ; $13C2  D1
SUB_129A_17:
        EX DE,HL                         ; $13C3  EB
SUB_129A_18:
        CALL SUB_13E4                    ; $13C4  CD E4 13
        LD DE,SUB_129A_14                ; $13C7  11 86 13
        PUSH DE                          ; $13CA  D5
        RET Z                            ; $13CB  C8
SUB_129A_19:
        SUB $81                          ; $13CC  D6 81
        JP C,SUB_15CF_6                  ; $13CE  DA F6 15
        CP $5B                           ; $13D1  FE 5B
        JP NC,SUB_2041_1                 ; $13D3  D2 4F 20
        RLCA                             ; $13D6  07
        LD C,A                           ; $13D7  4F
        LD B,$00                         ; $13D8  06 00
        EX DE,HL                         ; $13DA  EB
        LD HL,SUB_0100_4                 ; $13DB  21 08 01
        ADD HL,BC                        ; $13DE  09
        LD C,(HL)                        ; $13DF  4E
        INC HL                           ; $13E0  23
        LD B,(HL)                        ; $13E1  46
        PUSH BC                          ; $13E2  C5
        EX DE,HL                         ; $13E3  EB
SUB_13E4:
        INC HL                           ; $13E4  23
SUB_13E5:
        LD A,(HL)                        ; $13E5  7E
        CP $3A                           ; $13E6  FE 3A
        RET NC                           ; $13E8  D0
SUB_13E5_1:
        CP $20                           ; $13E9  FE 20
        JR Z,SUB_13E4                    ; $13EB  28 F7
        JR NC,SUB_1402_9                 ; $13ED  30 69
        OR A                             ; $13EF  B7
        RET Z                            ; $13F0  C8
        CP $0B                           ; $13F1  FE 0B
        JR C,SUB_1402_8                  ; $13F3  38 5E
        CP $1E                           ; $13F5  FE 1E
        JR NZ,SUB_13E5_2                 ; $13F7  20 05
        LD A,(SUB_0B2A_9)                ; $13F9  3A 3C 0B
        OR A                             ; $13FC  B7
        RET                              ; $13FD  C9
SUB_13E5_2:
        CP $10                           ; $13FE  FE 10
        JR NZ,SUB_1402_1                 ; $1400  20 05
SUB_1402:
        LD HL,(SUB_0B2A_8)               ; $1402  2A 3A 0B
        JR SUB_13E5                      ; $1405  18 DE
SUB_1402_1:
        PUSH AF                          ; $1407  F5
        INC HL                           ; $1408  23
        LD (SUB_0B2A_9),A                ; $1409  32 3C 0B
        SUB $1C                          ; $140C  D6 1C
        JR NC,SUB_1402_7                 ; $140E  30 28
        SUB $F5                          ; $1410  D6 F5
        JR NC,SUB_1402_3                 ; $1412  30 06
        CP $FE                           ; $1414  FE FE
        JR NZ,SUB_1402_6                 ; $1416  20 16
SUB_1402_2:
        LD A,(HL)                        ; $1418  7E
        INC HL                           ; $1419  23
SUB_1402_3:
        LD (SUB_0B2A_8),HL               ; $141A  22 3A 0B
SUB_1402_4:
        LD H,$00                         ; $141D  26 00
SUB_1402_5:
        LD L,A                           ; $141F  6F
        LD (SUB_0B2A_11),HL              ; $1420  22 3E 0B
        LD A,$02                         ; $1423  3E 02
        LD (SUB_0B2A_10),A               ; $1425  32 3D 0B
        LD HL,SUB_1402_10                ; $1428  21 5E 14
        POP AF                           ; $142B  F1
        OR A                             ; $142C  B7
        RET                              ; $142D  C9
SUB_1402_6:
        LD A,(HL)                        ; $142E  7E
        INC HL                           ; $142F  23
        INC HL                           ; $1430  23
        LD (SUB_0B2A_8),HL               ; $1431  22 3A 0B
        DEC HL                           ; $1434  2B
        LD H,(HL)                        ; $1435  66
        JR SUB_1402_5                    ; $1436  18 E7
SUB_1402_7:
        INC A                            ; $1438  3C
        RLCA                             ; $1439  07
        LD (SUB_0B2A_10),A               ; $143A  32 3D 0B
        PUSH DE                          ; $143D  D5
        PUSH BC                          ; $143E  C5
        LD DE,SUB_0B2A_11                ; $143F  11 3E 0B
        EX DE,HL                         ; $1442  EB
        LD B,A                           ; $1443  47
        CALL SUB_2B4B                    ; $1444  CD 4B 2B
        EX DE,HL                         ; $1447  EB
        POP BC                           ; $1448  C1
        POP DE                           ; $1449  D1
        LD (SUB_0B2A_8),HL               ; $144A  22 3A 0B
        POP AF                           ; $144D  F1
        LD HL,SUB_1402_10                ; $144E  21 5E 14
        OR A                             ; $1451  B7
        RET                              ; $1452  C9
SUB_1402_8:
        CP $09                           ; $1453  FE 09
        JP NC,SUB_13E4                   ; $1455  D2 E4 13
SUB_1402_9:
        CP $30                           ; $1458  FE 30
        CCF                              ; $145A  3F
        INC A                            ; $145B  3C
        DEC A                            ; $145C  3D
        RET                              ; $145D  C9
SUB_1402_10:
        LD E,$10                         ; $145E  1E 10
SUB_1460:
        LD A,(SUB_0B2A_9)                ; $1460  3A 3C 0B
        CP $0F                           ; $1463  FE 0F
        JR NC,SUB_1460_2                 ; $1465  30 16
        CP $0D                           ; $1467  FE 0D
        JR C,SUB_1460_2                  ; $1469  38 12
        LD HL,(SUB_0B2A_11)              ; $146B  2A 3E 0B
        JR NZ,SUB_1460_1                 ; $146E  20 07
        INC HL                           ; $1470  23
        INC HL                           ; $1471  23
        INC HL                           ; $1472  23
        LD E,(HL)                        ; $1473  5E
        INC HL                           ; $1474  23
        LD D,(HL)                        ; $1475  56
        EX DE,HL                         ; $1476  EB
SUB_1460_1:
        CALL SUB_2E6C                    ; $1477  CD 6C 2E
        JP SUB_1402                      ; $147A  C3 02 14
SUB_1460_2:
        LD A,(SUB_0B2A_10)               ; $147D  3A 3D 0B
        LD (SUB_0B2A_5),A                ; $1480  32 37 0B
        CP $08                           ; $1483  FE 08
        JR Z,SUB_1460_3                  ; $1485  28 0F
        LD HL,(SUB_0B2A_11)              ; $1487  2A 3E 0B
        LD (SUB_0C98_4),HL               ; $148A  22 D4 0C
        LD HL,(SUB_0B2A_12)              ; $148D  2A 40 0B
        LD (SUB_0C98_5),HL               ; $1490  22 D6 0C
        JP SUB_1402                      ; $1493  C3 02 14
SUB_1460_3:
        LD HL,SUB_0B2A_11                ; $1496  21 3E 0B
        CALL SUB_2B6A                    ; $1499  CD 6A 2B
        JP SUB_1402                      ; $149C  C3 02 14
SUB_1460_4:
        LD E,$03                         ; $149F  1E 03
        LD BC,$021E                      ; $14A1  01 1E 02
        LD BC,SUB_0100_30                ; $14A4  01 1E 04
        LD BC,$081E                      ; $14A7  01 1E 08
SUB_1460_5:
        CALL SUB_46BE                    ; $14AA  CD BE 46
        LD BC,SUB_0D20_20                ; $14AD  01 92 0D
        PUSH BC                          ; $14B0  C5
        RET C                            ; $14B1  D8
        SUB $41                          ; $14B2  D6 41
        LD C,A                           ; $14B4  4F
        LD B,A                           ; $14B5  47
        CALL SUB_13E4                    ; $14B6  CD E4 13
        CP $F3                           ; $14B9  FE F3
        JR NZ,SUB_1460_6                 ; $14BB  20 0D
        CALL SUB_13E4                    ; $14BD  CD E4 13
        CALL SUB_46BE                    ; $14C0  CD BE 46
        RET C                            ; $14C3  D8
        SUB $41                          ; $14C4  D6 41
        LD B,A                           ; $14C6  47
        CALL SUB_13E4                    ; $14C7  CD E4 13
SUB_1460_6:
        LD A,B                           ; $14CA  78
        SUB C                            ; $14CB  91
        RET C                            ; $14CC  D8
        INC A                            ; $14CD  3C
        EX (SP),HL                       ; $14CE  E3
        LD HL,SUB_0B2A_44                ; $14CF  21 9A 0B
        LD B,$00                         ; $14D2  06 00
        ADD HL,BC                        ; $14D4  09
SUB_1460_7:
        LD (HL),E                        ; $14D5  73
        INC HL                           ; $14D6  23
        DEC A                            ; $14D7  3D
        JR NZ,SUB_1460_7                 ; $14D8  20 FB
        POP HL                           ; $14DA  E1
        LD A,(HL)                        ; $14DB  7E
        CP $2C                           ; $14DC  FE 2C
        RET NZ                           ; $14DE  C0
        CALL SUB_13E4                    ; $14DF  CD E4 13
        JR SUB_1460_5                    ; $14E2  18 C6
SUB_14E4:
        CALL SUB_13E4                    ; $14E4  CD E4 13
SUB_14E4_1:
        CALL SUB_20A3                    ; $14E7  CD A3 20
        RET P                            ; $14EA  F0
SUB_14E4_2:
        LD E,$05                         ; $14EB  1E 05
        JP SUB_0D20_28                   ; $14ED  C3 AC 0D
SUB_14F0:
        LD A,(HL)                        ; $14F0  7E
        CP $2E                           ; $14F1  FE 2E
        EX DE,HL                         ; $14F3  EB
        LD HL,(SUB_0B2A_33)              ; $14F4  2A 85 0B
        EX DE,HL                         ; $14F7  EB
        JP Z,SUB_13E4                    ; $14F8  CA E4 13
SUB_14FB:
        DEC HL                           ; $14FB  2B
SUB_14FB_1:
        CALL SUB_13E4                    ; $14FC  CD E4 13
        CP $0E                           ; $14FF  FE 0E
        JP Z,SUB_1506                    ; $1501  CA 06 15
        CP $0D                           ; $1504  FE 0D
SUB_1506:
        EX DE,HL                         ; $1506  EB
        LD HL,(SUB_0B2A_11)              ; $1507  2A 3E 0B
        EX DE,HL                         ; $150A  EB
        JP Z,SUB_13E4                    ; $150B  CA E4 13
        DEC HL                           ; $150E  2B
        LD DE,$0000                      ; $150F  11 00 00
SUB_1506_1:
        CALL SUB_13E4                    ; $1512  CD E4 13
        RET NC                           ; $1515  D0
        PUSH HL                          ; $1516  E5
        PUSH AF                          ; $1517  F5
        LD HL,L_1998                     ; $1518  21 98 19
        CALL SUB_459D                    ; $151B  CD 9D 45
        JR C,SUB_1506_3                  ; $151E  38 11
        LD H,D                           ; $1520  62
SUB_1506_2:
        LD L,E                           ; $1521  6B
        ADD HL,DE                        ; $1522  19
        ADD HL,HL                        ; $1523  29
        ADD HL,DE                        ; $1524  19
        ADD HL,HL                        ; $1525  29
        POP AF                           ; $1526  F1
        SUB $30                          ; $1527  D6 30
        LD E,A                           ; $1529  5F
        LD D,$00                         ; $152A  16 00
        ADD HL,DE                        ; $152C  19
        EX DE,HL                         ; $152D  EB
        POP HL                           ; $152E  E1
        JR SUB_1506_1                    ; $152F  18 E1
SUB_1506_3:
        POP AF                           ; $1531  F1
        POP HL                           ; $1532  E1
        RET                              ; $1533  C9
SUB_1506_4:
        JP Z,SUB_450B                    ; $1534  CA 0B 45
        CP $0E                           ; $1537  FE 0E
        JR Z,SUB_1506_5                  ; $1539  28 05
        CP $0D                           ; $153B  FE 0D
        JP NZ,SUB_53F7_2                 ; $153D  C2 FD 53
SUB_1506_5:
        CALL SUB_450F                    ; $1540  CD 0F 45
        LD BC,SUB_129A_14                ; $1543  01 86 13
        JR SUB_1506_6                    ; $1546  18 17
        DEFB    $0E,$03,$CD                                      ; $1548
        DEFW    SUB_449F                 ; $154B
        DEFB    $CD                                              ; $154D
        DEFW    SUB_14FB                 ; $154E
        DEFB    $C1,$E5,$E5,$2A                                  ; $1550
        DEFW    SUB_0752_43              ; $1554
        DEFW    SUB_3EDB_1               ; $1556
        DEFB    $8D,$F5,$33,$C5,$C3                              ; $1558
        DEFW    SUB_1506_8               ; $155D
SUB_1506_6:
        PUSH BC                          ; $155F  C5
SUB_1506_7:
        CALL SUB_14FB                    ; $1560  CD FB 14
SUB_1506_8:
        LD A,(SUB_0B2A_9)                ; $1563  3A 3C 0B
        CP $0D                           ; $1566  FE 0D
        EX DE,HL                         ; $1568  EB
        RET Z                            ; $1569  C8
        EX DE,HL                         ; $156A  EB
        PUSH HL                          ; $156B  E5
        LD HL,(SUB_0B2A_8)               ; $156C  2A 3A 0B
        EX (SP),HL                       ; $156F  E3
        CALL SUB_15CF+2                  ; $1570  CD D1 15
        INC HL                           ; $1573  23
        PUSH HL                          ; $1574  E5
        LD HL,(SUB_0752_43)              ; $1575  2A 67 08
        CALL SUB_459D                    ; $1578  CD 9D 45
        POP HL                           ; $157B  E1
        CALL C,SUB_0FAB_1                ; $157C  DC AE 0F
        CALL NC,SUB_0FAB                 ; $157F  D4 AB 0F
        JR NC,SUB_1506_9                 ; $1582  30 0D
        DEC BC                           ; $1584  0B
        LD A,$0D                         ; $1585  3E 0D
        LD (SUB_0B2A_26),A               ; $1587  32 79 0B
        POP HL                           ; $158A  E1
        CALL SUB_241D                    ; $158B  CD 1D 24
        LD H,B                           ; $158E  60
        LD L,C                           ; $158F  69
        RET                              ; $1590  C9
SUB_1506_9:
        LD E,$08                         ; $1591  1E 08
        JP SUB_0D20_28                   ; $1593  C3 AC 0D
SUB_1506_10:
        LD (SUB_0B2A_25),HL              ; $1596  22 77 0B
        LD D,$FF                         ; $1599  16 FF
        CALL SUB_0D20                    ; $159B  CD 20 0D
        LD SP,HL                         ; $159E  F9
        LD (SUB_0B2A_31),HL              ; $159F  22 81 0B
        CP $8D                           ; $15A2  FE 8D
SUB_1506_11:
        JR NZ,SUB_1506_12                ; $15A4  20 1A
        LD HL,$0004                      ; $15A6  21 04 00
        ADD HL,SP                        ; $15A9  39
        LD (SUB_0B2A_31),HL              ; $15AA  22 81 0B
        LD SP,HL                         ; $15AD  F9
        LD HL,(SUB_0B2A_25)              ; $15AE  2A 77 0B
        JP SUB_129A_14                   ; $15B1  C3 86 13
        DEFB    $C0,$16,$FF,$CD                                  ; $15B4
        DEFW    SUB_0D20                 ; $15B8
        DEFB    $F9,$22                                          ; $15BA
        DEFW    SUB_0B2A_31              ; $15BC
        DEFB    $FE,$8D                                          ; $15BE
SUB_1506_12:
        LD E,$03                         ; $15C0  1E 03
SUB_1506_13:
        JP NZ,SUB_0D20_28                ; $15C2  C2 AC 0D
        POP HL                           ; $15C5  E1
        LD (SUB_0752_43),HL              ; $15C6  22 67 08
        LD HL,SUB_129A_14                ; $15C9  21 86 13
        EX (SP),HL                       ; $15CC  E3
        LD A,$E1                         ; $15CD  3E E1
SUB_15CF:
        LD BC,SUB_0D20_37+2              ; $15CF  01 3A 0E
        NOP                              ; $15D2  00
        LD B,$00                         ; $15D3  06 00
SUB_15CF_1:
        LD A,C                           ; $15D5  79
        LD C,B                           ; $15D6  48
        LD B,A                           ; $15D7  47
SUB_15CF_2:
        DEC HL                           ; $15D8  2B
SUB_15CF_3:
        CALL SUB_13E4                    ; $15D9  CD E4 13
        OR A                             ; $15DC  B7
        RET Z                            ; $15DD  C8
        CP B                             ; $15DE  B8
        RET Z                            ; $15DF  C8
        INC HL                           ; $15E0  23
        CP $22                           ; $15E1  FE 22
        JR Z,SUB_15CF_1                  ; $15E3  28 F0
        INC A                            ; $15E5  3C
        JR Z,SUB_15CF_3                  ; $15E6  28 F1
        SUB $8C                          ; $15E8  D6 8C
        JR NZ,SUB_15CF_2                 ; $15EA  20 EC
        CP B                             ; $15EC  B8
        ADC A,D                          ; $15ED  8A
        LD D,A                           ; $15EE  57
        JR SUB_15CF_2                    ; $15EF  18 E7
SUB_15CF_4:
        POP AF                           ; $15F1  F1
        ADD A,$03                        ; $15F2  C6 03
SUB_15CF_5:
        JR SUB_15CF_9                    ; $15F4  18 15
SUB_15CF_6:
        CALL SUB_3BB3                    ; $15F6  CD B3 3B
        CALL SUB_45A3                    ; $15F9  CD A3 45
        RET P                            ; $15FC  F0
        EX DE,HL                         ; $15FD  EB
        LD (SUB_0B2A_25),HL              ; $15FE  22 77 0B
        EX DE,HL                         ; $1601  EB
SUB_15CF_7:
        PUSH DE                          ; $1602  D5
        LD A,(SUB_0B2A_5)                ; $1603  3A 37 0B
        PUSH AF                          ; $1606  F5
SUB_15CF_8:
        CALL SUB_1A8C_1+1                ; $1607  CD 90 1A
        POP AF                           ; $160A  F1
SUB_15CF_9:
        EX (SP),HL                       ; $160B  E3
        LD B,A                           ; $160C  47
        LD A,(SUB_0B2A_5)                ; $160D  3A 37 0B
        CP B                             ; $1610  B8
        LD A,B                           ; $1611  78
        JR Z,SUB_15CF_11                 ; $1612  28 06
        CALL SUB_201A                    ; $1614  CD 1A 20
SUB_15CF_10:
        LD A,(SUB_0B2A_5)                ; $1617  3A 37 0B
SUB_15CF_11:
        LD DE,SUB_0C98_4                 ; $161A  11 D4 0C
SUB_15CF_12:
        CP $05                           ; $161D  FE 05
        JR C,SUB_15CF_13                 ; $161F  38 03
        LD DE,SUB_0C98_1                 ; $1621  11 D0 0C
SUB_15CF_13:
        PUSH HL                          ; $1624  E5
        CP $03                           ; $1625  FE 03
        JR NZ,SUB_15CF_17                ; $1627  20 2E
        LD HL,(SUB_0C98_4)               ; $1629  2A D4 0C
        PUSH HL                          ; $162C  E5
SUB_15CF_14:
        INC HL                           ; $162D  23
        LD E,(HL)                        ; $162E  5E
        INC HL                           ; $162F  23
        LD D,(HL)                        ; $1630  56
        LD HL,(SUB_0752_44)              ; $1631  2A 69 08
        CALL SUB_459D                    ; $1634  CD 9D 45
        JR NC,SUB_15CF_15+1              ; $1637  30 12
        LD HL,(SUB_0B2A_42)              ; $1639  2A 96 0B
        CALL SUB_459D                    ; $163C  CD 9D 45
        POP DE                           ; $163F  D1
        JR NC,SUB_15CF_16                ; $1640  30 11
        LD HL,SUB_0B2A_17                ; $1642  21 68 0B
        CALL SUB_459D                    ; $1645  CD 9D 45
        JR NC,SUB_15CF_16                ; $1648  30 09
SUB_15CF_15:
        LD A,$D1                         ; $164A  3E D1
        CALL SUB_4A57                    ; $164C  CD 57 4A
        EX DE,HL                         ; $164F  EB
        CALL SUB_4844                    ; $1650  CD 44 48
SUB_15CF_16:
        CALL SUB_4A57                    ; $1653  CD 57 4A
        EX (SP),HL                       ; $1656  E3
SUB_15CF_17:
        CALL SUB_2B47                    ; $1657  CD 47 2B
        POP DE                           ; $165A  D1
        POP HL                           ; $165B  E1
        RET                              ; $165C  C9
SUB_15CF_18:
        CP $A4                           ; $165D  FE A4
SUB_15CF_19:
        JR NZ,L_168B                     ; $165F  20 2A
        CALL SUB_13E4                    ; $1661  CD E4 13
        CALL SUB_45A3                    ; $1664  CD A3 45
        ADC A,C                          ; $1667  89
        CALL SUB_14FB                    ; $1668  CD FB 14
        LD A,D                           ; $166B  7A
        OR E                             ; $166C  B3
        JR Z,SUB_15CF_20                 ; $166D  28 09
        CALL SUB_0FA9                    ; $166F  CD A9 0F
        LD D,B                           ; $1672  50
        LD E,C                           ; $1673  59
        POP HL                           ; $1674  E1
        JP NC,SUB_1506_9                 ; $1675  D2 91 15
SUB_15CF_20:
        EX DE,HL                         ; $1678  EB
        LD (SUB_0B2A_35),HL              ; $1679  22 89 0B
        EX DE,HL                         ; $167C  EB
        RET C                            ; $167D  D8
        LD A,(SUB_0B2A_36)               ; $167E  3A 8B 0B
        OR A                             ; $1681  B7
        LD A,E                           ; $1682  7B
        RET Z                            ; $1683  C8
        LD A,(SUB_0752_33+2)             ; $1684  3A 58 08
        LD E,A                           ; $1687  5F
        JP SUB_0D20_29                   ; $1688  C3 C1 0D
L_168B:
        DEFB    $CD,$B2,$20,$7E,$47,$FE,$8D                      ; $168B  "M2 ~G~"
        DEFB    $28,$05,$CD                                      ; $1692
        DEFW    SUB_45A3                 ; $1695
        DEFW    SUB_2B81_1               ; $1697
        DEFW    SUB_0D20_5               ; $1699
        DEFB    $78,$CA                                          ; $169B
        DEFW    SUB_129A_19              ; $169D
        DEFB    $CD                                              ; $169F
        DEFW    SUB_14FB_1               ; $16A0
        DEFW    SUB_2CF8_1               ; $16A2
        DEFW    SUB_189A_3               ; $16A4
        DEFB    $F3,$11                                          ; $16A6
        DEFW    SUB_0B2A_36              ; $16A8
        DEFB    $1A,$B7,$CA,$A1,$0D                              ; $16AA
        DEFW    SUB_3212_6+1             ; $16AF
        DEFW    SUB_0752_33+2            ; $16B1
        DEFB    $12,$7E,$FE                                      ; $16B3
        DEFW    SUB_2874_2               ; $16B6
        DEFB    $0C,$CD                                          ; $16B8
        DEFW    SUB_14FB                 ; $16BA
        DEFB    $C0,$7A,$B3,$C2                                  ; $16BC
        DEFW    SUB_1506_8               ; $16C0
        DEFW    SUB_15CF_38              ; $16C2
        DEFB    $04,$CD                                          ; $16C4
        DEFW    SUB_13E4                 ; $16C6
        DEFW    SUB_2AAE_1               ; $16C8
        DEFW    SUB_0B2A_34              ; $16CA
        DEFW    SUB_2AEB                 ; $16CC
        DEFW    SUB_0B2A_32              ; $16CE
        DEFB    $22                                              ; $16D0
        DEFW    SUB_0752_43              ; $16D1
        DEFB    $EB,$C0,$7E,$B7,$20,$04,$23,$23,$23,$23,$23,$C3  ; $16D3
        DEFW    SUB_15CF                 ; $16DF
        DEFB    $CD                                              ; $16E1
        DEFW    SUB_20B2                 ; $16E2
        DEFB    $C0,$B7,$CA                                      ; $16E4
        DEFW    SUB_14E4_2               ; $16E7
        DEFB    $C3                                              ; $16E9
        DEFW    SUB_0D20_28              ; $16EA
L_16EC:
        DEFW    SUB_0925_8               ; $16EC
        DEFB    $00                                              ; $16EE
        DEFW    SUB_28D5                 ; $16EF
        DEFB    $19,$CD                                          ; $16F1
        DEFW    SUB_14F0                 ; $16F3
        DEFB    $EB,$E3                                          ; $16F5
        DEFW    SUB_129A_8               ; $16F7
        DEFB    $EB,$CD                                          ; $16F9
        DEFW    SUB_45A3                 ; $16FB
        DEFB    $2C                                              ; $16FD
        DEFW    SUB_2AEB                 ; $16FE
        DEFW    SUB_0B2A_29              ; $1700
        DEFW    SUB_28E1_2               ; $1702
        DEFB    $06,$CD                                          ; $1704
        DEFW    SUB_14FB                 ; $1706
        DEFB    $C2                                              ; $1708
        DEFW    SUB_0D20_20              ; $1709
        DEFB    $EB,$7C,$B5,$CA                                  ; $170B
        DEFW    SUB_14E4_2               ; $170F
        DEFB    $22                                              ; $1711
        DEFW    SUB_0B2A_29              ; $1712
        DEFB    $32                                              ; $1714
        DEFW    SUB_0B2A_27              ; $1715
        DEFW    SUB_22E1                 ; $1717
        DEFW    SUB_0B2A_28              ; $1719
        DEFB    $C1,$C3                                          ; $171B
        DEFW    SUB_0D20_41              ; $171D
        DEFB    $CD                                              ; $171F
        DEFW    SUB_1A8C_1+1             ; $1720
        DEFB    $7E                                              ; $1722
        DEFW    SUB_2CF8_1               ; $1723
        DEFB    $CC                                              ; $1725
        DEFW    SUB_13E4                 ; $1726
        DEFB    $FE,$89,$28,$05,$CD                              ; $1728
        DEFW    SUB_45A3                 ; $172D
        DEFW    SUB_2BC4_2               ; $172F
        DEFB    $E5                                              ; $1731
        DEFW    SUB_064E_5               ; $1732
        DEFB    $2B                                              ; $1734
        DEFW    SUB_28E1                 ; $1735
        DEFB    $12,$CD                                          ; $1737
        DEFW    SUB_13E4                 ; $1739
        DEFB    $C8                                              ; $173B
        DEFW    SUB_0D20_52              ; $173C
        DEFB    $CA                                              ; $173E
        DEFW    SUB_1506_7               ; $173F
        DEFB    $FE,$0D,$C2                                      ; $1741
        DEFW    SUB_129A_19              ; $1744
        DEFW    SUB_3D4E_21              ; $1746
        DEFB    $0B,$C9,$16,$01,$CD                              ; $1748
        DEFW    SUB_15CF                 ; $174D
        DEFB    $B7,$C8,$CD                                      ; $174F
        DEFW    SUB_13E4                 ; $1752
        DEFB    $FE                                              ; $1754
        DEFW    SUB_2096_1               ; $1755
        DEFW    SUB_15CF_5               ; $1757
        DEFB    $20,$F1,$18                                      ; $1759
        DEFW    SUB_3EDB                 ; $175C
        DEFW    SUB_31F3_2               ; $175E
        DEFW    SUB_0752_34+1            ; $1760
        DEFB    $C3                                              ; $1762
        DEFW    SUB_15CF_21              ; $1763
        DEFW    SUB_0100_21              ; $1765
        DEFB    $CD                                              ; $1767
        DEFW    SUB_528B_1               ; $1768
SUB_15CF_21:
        DEC HL                           ; $176A  2B
        CALL SUB_13E4                    ; $176B  CD E4 13
        CALL Z,SUB_4406                  ; $176E  CC 06 44
SUB_15CF_22:
        JP Z,SUB_189A                    ; $1771  CA 9A 18
        CP $E8                           ; $1774  FE E8
        JP Z,SUB_4068_12                 ; $1776  CA D6 40
        CP $DF                           ; $1779  FE DF
        JP Z,SUB_15CF_33                 ; $177B  CA 20 18
        CP $E3                           ; $177E  FE E3
        JP Z,SUB_15CF_33                 ; $1780  CA 20 18
        PUSH HL                          ; $1783  E5
        CP $2C                           ; $1784  FE 2C
        JR Z,SUB_15CF_27                 ; $1786  28 5E
        CP $3B                           ; $1788  FE 3B
        JP Z,SUB_15CF_46                 ; $178A  CA 93 18
        POP BC                           ; $178D  C1
        CALL SUB_1A8C_1+1                ; $178E  CD 90 1A
        PUSH HL                          ; $1791  E5
        CALL SUB_1DE3                    ; $1792  CD E3 1D
        JR Z,SUB_15CF_23                 ; $1795  28 0C
        CALL SUB_33A0                    ; $1797  CD A0 33
        CALL SUB_4868                    ; $179A  CD 68 48
        LD (HL),$20                      ; $179D  36 20
        LD HL,(SUB_0C98_4)               ; $179F  2A D4 0C
        INC (HL)                         ; $17A2  34
SUB_15CF_23:
        LD HL,(SUB_0752_40)              ; $17A3  2A 63 08
        LD A,H                           ; $17A6  7C
        OR L                             ; $17A7  B5
        JR NZ,SUB_15CF_26                ; $17A8  20 35
        LD HL,(SUB_0C98_4)               ; $17AA  2A D4 0C
        LD A,(SUB_0752_34+1)             ; $17AD  3A 5B 08
        OR A                             ; $17B0  B7
        JR Z,SUB_15CF_24                 ; $17B1  28 16
        LD A,(SUB_0752_35)               ; $17B3  3A 5D 08
        LD B,A                           ; $17B6  47
        INC A                            ; $17B7  3C
        JP Z,SUB_15CF_26                 ; $17B8  CA DF 17
        LD A,(SUB_0752_34)               ; $17BB  3A 5A 08
        OR A                             ; $17BE  B7
        JP Z,SUB_15CF_26                 ; $17BF  CA DF 17
        ADD A,(HL)                       ; $17C2  86
        CCF                              ; $17C3  3F
        JR NC,SUB_15CF_25                ; $17C4  30 16
        CP B                             ; $17C6  B8
        JR SUB_15CF_25                   ; $17C7  18 13
SUB_15CF_24:
        LD A,(SUB_0752_36)               ; $17C9  3A 5E 08
        LD B,A                           ; $17CC  47
        INC A                            ; $17CD  3C
        JR Z,SUB_15CF_26                 ; $17CE  28 0F
        LD A,(SUB_0B2A_2)                ; $17D0  3A 34 0B
        OR A                             ; $17D3  B7
        JR Z,SUB_15CF_26                 ; $17D4  28 09
        ADD A,(HL)                       ; $17D6  86
        CCF                              ; $17D7  3F
        JR NC,SUB_15CF_25                ; $17D8  30 02
        DEC A                            ; $17DA  3D
        CP B                             ; $17DB  B8
SUB_15CF_25:
        CALL NC,SUB_4406                 ; $17DC  D4 06 44
SUB_15CF_26:
        CALL SUB_48C1                    ; $17DF  CD C1 48
        POP HL                           ; $17E2  E1
        JP SUB_15CF_21                   ; $17E3  C3 6A 17
SUB_15CF_27:
        LD HL,(SUB_0752_40)              ; $17E6  2A 63 08
        LD A,H                           ; $17E9  7C
        OR L                             ; $17EA  B5
        LD BC,$0028                      ; $17EB  01 28 00
        ADD HL,BC                        ; $17EE  09
        LD A,(HL)                        ; $17EF  7E
        JR NZ,SUB_15CF_32                ; $17F0  20 26
        LD A,(SUB_0752_34+1)             ; $17F2  3A 5B 08
        OR A                             ; $17F5  B7
        JR Z,SUB_15CF_29                 ; $17F6  28 0E
        LD A,(SUB_0752_34+2)             ; $17F8  3A 5C 08
        LD B,A                           ; $17FB  47
        INC A                            ; $17FC  3C
        LD A,(SUB_0752_34)               ; $17FD  3A 5A 08
SUB_15CF_28:
        JR Z,SUB_15CF_32                 ; $1800  28 16
        CP B                             ; $1802  B8
        JP SUB_15CF_31                   ; $1803  C3 12 18
SUB_15CF_29:
        LD A,(SUB_0752_37+1)             ; $1806  3A 60 08
        LD B,A                           ; $1809  47
        LD A,(SUB_0B2A_2)                ; $180A  3A 34 0B
SUB_15CF_30:
        CP $FF                           ; $180D  FE FF
        JR Z,SUB_15CF_32                 ; $180F  28 07
        CP B                             ; $1811  B8
SUB_15CF_31:
        CALL NC,SUB_4406                 ; $1812  D4 06 44
        JP NC,SUB_15CF_46                ; $1815  D2 93 18
SUB_15CF_32:
        SUB $0E                          ; $1818  D6 0E
        JR NC,SUB_15CF_32                ; $181A  30 FC
        CPL                              ; $181C  2F
        JP SUB_15CF_44                   ; $181D  C3 8A 18
SUB_15CF_33:
        PUSH AF                          ; $1820  F5
        CALL SUB_13E4                    ; $1821  CD E4 13
        CALL SUB_20A3                    ; $1824  CD A3 20
        POP AF                           ; $1827  F1
SUB_15CF_34:
        PUSH AF                          ; $1828  F5
        CP $E3                           ; $1829  FE E3
        JR Z,SUB_15CF_35                 ; $182B  28 01
        DEC DE                           ; $182D  1B
SUB_15CF_35:
        LD A,D                           ; $182E  7A
        OR A                             ; $182F  B7
        JP P,SUB_15CF_36                 ; $1830  F2 36 18
        LD DE,$0000                      ; $1833  11 00 00
SUB_15CF_36:
        PUSH HL                          ; $1836  E5
SUB_15CF_37:
        LD HL,(SUB_0752_40)              ; $1837  2A 63 08
        LD A,H                           ; $183A  7C
        OR L                             ; $183B  B5
SUB_15CF_38:
        JR NZ,SUB_15CF_41                ; $183C  20 16
        LD A,(SUB_0752_34+1)             ; $183E  3A 5B 08
        OR A                             ; $1841  B7
        LD A,(SUB_0752_35)               ; $1842  3A 5D 08
        JR NZ,SUB_15CF_39                ; $1845  20 03
        LD A,(SUB_0752_36)               ; $1847  3A 5E 08
SUB_15CF_39:
        LD L,A                           ; $184A  6F
        INC A                            ; $184B  3C
        JR Z,SUB_15CF_41                 ; $184C  28 06
SUB_15CF_40:
        LD H,$00                         ; $184E  26 00
        CALL SUB_2E76                    ; $1850  CD 76 2E
        EX DE,HL                         ; $1853  EB
SUB_15CF_41:
        POP HL                           ; $1854  E1
        CALL SUB_45A3                    ; $1855  CD A3 45
        ADD HL,HL                        ; $1858  29
        DEC HL                           ; $1859  2B
        POP AF                           ; $185A  F1
        SUB $E3                          ; $185B  D6 E3
        PUSH HL                          ; $185D  E5
        JR Z,SUB_15CF_43                 ; $185E  28 1B
        LD HL,(SUB_0752_40)              ; $1860  2A 63 08
        LD A,H                           ; $1863  7C
        OR L                             ; $1864  B5
        LD BC,$0028                      ; $1865  01 28 00
        ADD HL,BC                        ; $1868  09
        LD A,(HL)                        ; $1869  7E
        JR NZ,SUB_15CF_43                ; $186A  20 0F
        LD A,(SUB_0752_34+1)             ; $186C  3A 5B 08
        OR A                             ; $186F  B7
        JP Z,SUB_15CF_42                 ; $1870  CA 78 18
        LD A,(SUB_0752_34)               ; $1873  3A 5A 08
        JR SUB_15CF_43                   ; $1876  18 03
SUB_15CF_42:
        LD A,(SUB_0B2A_2)                ; $1878  3A 34 0B
SUB_15CF_43:
        CPL                              ; $187B  2F
        ADD A,E                          ; $187C  83
        JR C,SUB_15CF_44                 ; $187D  38 0B
        INC A                            ; $187F  3C
        JR Z,SUB_15CF_46                 ; $1880  28 11
        CALL SUB_4406                    ; $1882  CD 06 44
        LD A,E                           ; $1885  7B
        DEC A                            ; $1886  3D
        JP M,SUB_15CF_46                 ; $1887  FA 93 18
SUB_15CF_44:
        INC A                            ; $188A  3C
        LD B,A                           ; $188B  47
        LD A,$20                         ; $188C  3E 20
SUB_15CF_45:
        CALL SUB_4291                    ; $188E  CD 91 42
        DJNZ SUB_15CF_45                 ; $1891  10 FB
SUB_15CF_46:
        POP HL                           ; $1893  E1
        CALL SUB_13E4                    ; $1894  CD E4 13
        JP SUB_15CF_22                   ; $1897  C3 71 17
SUB_189A:
        XOR A                            ; $189A  AF
        LD (SUB_0752_34+1),A             ; $189B  32 5B 08
        PUSH HL                          ; $189E  E5
        LD H,A                           ; $189F  67
        LD L,A                           ; $18A0  6F
        LD (SUB_0752_40),HL              ; $18A1  22 63 08
SUB_189A_1:
        POP HL                           ; $18A4  E1
        RET                              ; $18A5  C9
SUB_189A_2:
        CALL SUB_45A3                    ; $18A6  CD A3 45
        ADD A,L                          ; $18A9  85
        CP $23                           ; $18AA  FE 23
        JP Z,SUB_52CF_2                  ; $18AC  CA 23 53
        CALL SUB_4DAC                    ; $18AF  CD AC 4D
        CALL SUB_191F                    ; $18B2  CD 1F 19
        CALL SUB_3BB3                    ; $18B5  CD B3 3B
        CALL SUB_2CB3                    ; $18B8  CD B3 2C
        PUSH DE                          ; $18BB  D5
        PUSH HL                          ; $18BC  E5
        CALL SUB_4CA1_1                  ; $18BD  CD A9 4C
SUB_189A_3:
        POP DE                           ; $18C0  D1
SUB_189A_4:
        POP BC                           ; $18C1  C1
        JP C,SUB_45B5_8+1                ; $18C2  DA E4 45
        PUSH BC                          ; $18C5  C5
        PUSH DE                          ; $18C6  D5
        LD B,$00                         ; $18C7  06 00
        CALL SUB_486B                    ; $18C9  CD 6B 48
        POP HL                           ; $18CC  E1
SUB_189A_5:
        LD A,$03                         ; $18CD  3E 03
        JP SUB_15CF_9                    ; $18CF  C3 0B 16
        DEFB    "?Redo from start"    ; $18D2  string
        DEFB    $0D    ; $18E2  terminator
        DEFB    $0A                                              ; $18E3
        DEFW    SUB_22E1_2               ; $18E4
        DEFB    $7E,$B7,$CA                                      ; $18E6
        DEFW    SUB_0D20_20              ; $18E9
        DEFB    $FE,$22,$20,$F6,$C3,$7D,$19,$E1,$E1,$C3,$FE      ; $18EB
        DEFW    SUB_3A18                 ; $18F6
        DEFW    SUB_0B2A_24              ; $18F8
        DEFB    $B7,$C2                                          ; $18FA
        DEFW    SUB_0D20_19              ; $18FC
        DEFW    SUB_2124_19              ; $18FE
        DEFB    $D2,$18,$CD                                      ; $1900
        DEFW    SUB_48BE                 ; $1903
        DEFB    $2A                                              ; $1905
        DEFW    SUB_0B2A_30              ; $1906
        DEFB    $C9,$CD                                          ; $1908
        DEFW    SUB_528B                 ; $190A
        DEFB    $E5                                              ; $190C
        DEFW    SUB_3006_3               ; $190D
        DEFB    $0A,$C3,$CE,$19,$FE,$23                          ; $190F
        DEFW    SUB_0925_3               ; $1915
        DEFB    $19,$CD                                          ; $1917
        DEFW    SUB_4DAC                 ; $1919
        DEFB    $01,$47,$19,$C5                                  ; $191B
SUB_191F:
        DEFB    $FE,$22,$3E,$00,$32                              ; $191F
        DEFW    SUB_0752_39              ; $1924
        DEFB    $3E,$FF,$32,$B7,$0C,$C0,$CD                      ; $1926
        DEFW    SUB_4868_1               ; $192D
        DEFB    $7E                                              ; $192F
        DEFW    SUB_2CF8_1               ; $1930
        DEFW    SUB_0752_72              ; $1932
        DEFB    $AF,$32,$B7,$0C,$CD                              ; $1934
        DEFW    SUB_13E4                 ; $1939
        DEFW    SUB_0100_29              ; $193B
        DEFB    $CD                                              ; $193D
        DEFW    SUB_45A3                 ; $193E
        DEFB    $3B,$E5,$CD                                      ; $1940
        DEFW    SUB_48C1                 ; $1943
        DEFB    $E1,$C9,$E5,$3A,$B7,$0C                          ; $1945
        DEFW    SUB_2874_11              ; $194B
        DEFW    SUB_3D4E_17              ; $194D
        DEFB    $3F,$CD                                          ; $194F
        DEFW    SUB_4291                 ; $1951
        DEFW    SUB_2033_1               ; $1953
        DEFB    $CD                                              ; $1955
        DEFW    SUB_4291                 ; $1956
        DEFB    $CD,$A9,$4C,$C1,$DA,$E4,$45,$C5,$36,$2C,$EB,$E1,$E5,$D5,$D5,$2B ; $1958  "M)LAZdEE6,kaeUU+>"
        DEFB    $3E,$80                                          ; $1968
        DEFB    $32                                              ; $196A
        DEFW    SUB_0B2A_23              ; $196B
        DEFB    $CD                                              ; $196D
        DEFW    SUB_13E4                 ; $196E
        DEFB    $CD                                              ; $1970
        DEFW    SUB_3BB3                 ; $1971
        DEFB    $7E,$2B                                          ; $1973
        DEFW    SUB_28F5_2               ; $1975
        DEFB    $20                                              ; $1977
        DEFW    SUB_22E1_6               ; $1978
        DEFB    $06,$00,$04,$CD                                  ; $197A
        DEFW    SUB_13E4                 ; $197E
        DEFB    $CA                                              ; $1980
        DEFW    SUB_0D20_20              ; $1981
        DEFB    $FE,$22,$CA,$E5,$18                              ; $1983
        DEFW    SUB_28F5_2               ; $1988
        DEFB    $28,$F0                                          ; $198A
        DEFW    SUB_29E8_4               ; $198C
        DEFB    $20,$ED,$10,$EB,$CD                              ; $198E
        DEFW    SUB_13E4                 ; $1993
        DEFB    $28,$05,$FE                                      ; $1995
L_1998:
        DEFB    $2C,$C2                                          ; $1998
        DEFW    SUB_0D20_20              ; $199A
        DEFB    $E3,$7E                                          ; $199C
        DEFW    SUB_2CF8_1               ; $199E
        DEFB    $C2,$F2                                          ; $19A0
        DEFW    SUB_3D4E_18              ; $19A2
        DEFW    SUB_31F3_2               ; $19A4
        DEFW    SUB_0C98_9               ; $19A6
        DEFB    $CD,$F4,$19,$3A                                  ; $19A8
        DEFW    SUB_0C98_9               ; $19AC
        DEFB    $3D,$C2,$F2,$18,$E5,$CD                          ; $19AE
        DEFW    SUB_1DE3                 ; $19B4
        DEFB    $CC                                              ; $19B6
        DEFW    SUB_4A3A                 ; $19B7
        DEFW    SUB_2BC4_3               ; $19B9
        DEFB    $CD                                              ; $19BB
        DEFW    SUB_13E4                 ; $19BC
        DEFB    $E3,$7E                                          ; $19BE
        DEFW    SUB_2CF8_1               ; $19C0
        DEFB    $28,$A4                                          ; $19C2
        DEFW    SUB_2BC4_3               ; $19C4
        DEFB    $CD                                              ; $19C6
        DEFW    SUB_13E4                 ; $19C7
        DEFB    $B7,$E1,$C2,$FE                                  ; $19C9
        DEFW    SUB_3518_22              ; $19CD
        DEFB    $2C,$18,$05,$E5,$2A                              ; $19CF
        DEFW    SUB_0B2A_43              ; $19D4
        DEFB    $F6,$AF,$32                                      ; $19D6
        DEFW    SUB_0B2A_24              ; $19D9
        DEFB    $E3                                              ; $19DB
        DEFW    SUB_0100_29              ; $19DC
        DEFB    $CD                                              ; $19DE
        DEFW    SUB_45A3                 ; $19DF
        DEFB    $2C,$CD                                          ; $19E1
        DEFW    SUB_3BB3                 ; $19E3
        DEFB    $E3,$D5,$7E                                      ; $19E5
        DEFW    SUB_2CF8_1               ; $19E8
        DEFW    SUB_064E_16              ; $19EA
        DEFB    $3A                                              ; $19EC
        DEFW    SUB_0B2A_24              ; $19ED
        DEFB    $B7,$C2,$63,$1A,$F6,$AF,$32                      ; $19EF
        DEFW    SUB_0C4B_7               ; $19F6
        DEFW    SUB_2AEB                 ; $19F8
        DEFW    SUB_0752_40              ; $19FA
        DEFB    $7C,$B5,$EB                                      ; $19FC
        DEFW    SUB_1506_13              ; $19FF
        DEFB    $53,$CD                                          ; $1A01
        DEFW    SUB_1DE3                 ; $1A03
        DEFW    SUB_20B5_4               ; $1A05
        DEFB    $2B,$CD                                          ; $1A07
        DEFW    SUB_13E4                 ; $1A09
        DEFW    SUB_46BF_2               ; $1A0B
        DEFB    $FE,$22                                          ; $1A0D
        DEFW    SUB_0C03_4               ; $1A0F
        DEFB    $3A                                              ; $1A11
        DEFW    SUB_0B2A_24              ; $1A12
        DEFB    $B7                                              ; $1A14
        DEFW    SUB_2824_5               ; $1A15
        DEFW    SUB_15CF_7               ; $1A17
        DEFB    $3A,$06                                          ; $1A19
        DEFW    SUB_2B28_1               ; $1A1B
        DEFB    $CD                                              ; $1A1D
        DEFW    SUB_486C                 ; $1A1E
        DEFB    $F1,$C6,$03                                      ; $1A20
        DEFW    SUB_3A18_4               ; $1A23
        DEFW    SUB_0C4B_7               ; $1A25
        DEFB    $B7,$C8,$79,$EB                                  ; $1A27
        DEFW    SUB_4068_41              ; $1A2B
        DEFB    $1A,$E3,$D5                                      ; $1A2D
        DEFW    L_0CC3                   ; $1A30
        DEFB    $16,$CD                                          ; $1A32
        DEFW    SUB_13E4                 ; $1A34
        DEFB    $F1,$F5                                          ; $1A36
        DEFW    SUB_1E72_21              ; $1A38
        DEFB    $1A,$C5                                          ; $1A3A
        DEFW    SUB_25D9_1               ; $1A3C
        DEFB    $31,$C3                                          ; $1A3E
        DEFW    SUB_311E                 ; $1A40
        DEFB    $2B,$CD                                          ; $1A42
        DEFW    SUB_13E4                 ; $1A44
        DEFB    $28,$05                                          ; $1A46
        DEFW    SUB_2CF8_1               ; $1A48
        DEFB    $C2,$F7,$18                                      ; $1A4A
        DEFW    SUB_2BC4_4               ; $1A4D
        DEFB    $CD                                              ; $1A4F
        DEFW    SUB_13E4                 ; $1A50
        DEFB    $C2,$DE,$19,$D1,$3A                              ; $1A52
        DEFW    SUB_0B2A_24              ; $1A57
        DEFB    $B7,$EB,$C2                                      ; $1A59
        DEFW    SUB_45B5_4               ; $1A5C
        DEFB    $D5,$E1,$C3                                      ; $1A5E
        DEFW    SUB_189A                 ; $1A61
        DEFB    $CD                                              ; $1A63
        DEFW    SUB_15CF                 ; $1A64
        DEFB    $B7,$20                                          ; $1A66
        DEFW    SUB_22E1_5               ; $1A68
        DEFB    $7E,$23                                          ; $1A6A
        DEFW    SUB_1E72_5               ; $1A6C
        DEFB    $04,$CA                                          ; $1A6E
        DEFW    SUB_0D20_28              ; $1A70
        DEFB    $23                                              ; $1A72
        DEFW    SUB_22E1_15              ; $1A73
        DEFB    $56,$EB,$22                                      ; $1A75
        DEFW    SUB_0B2A_22              ; $1A78
        DEFB    $EB,$CD                                          ; $1A7A
        DEFW    SUB_13E4                 ; $1A7C
        DEFB    $FE,$84,$20,$E1,$C3,$F3,$19                      ; $1A7E
SUB_1A85:
        CALL SUB_45A3                    ; $1A85  CD A3 45
        RET P                            ; $1A88  F0
        JP SUB_1A8C_1+1                  ; $1A89  C3 90 1A
SUB_1A8C:
        CALL SUB_45A3                    ; $1A8C  CD A3 45
SUB_1A8C_1:
        JR Z,SUB_1A93_3+1                ; $1A8F  28 2B
SUB_1A91:
        LD D,$00                         ; $1A91  16 00
SUB_1A93:
        PUSH DE                          ; $1A93  D5
        LD C,$01                         ; $1A94  0E 01
        CALL SUB_449F                    ; $1A96  CD 9F 44
        CALL SUB_1C11                    ; $1A99  CD 11 1C
        XOR A                            ; $1A9C  AF
        LD (SUB_0C98_8),A                ; $1A9D  32 D9 0C
SUB_1A93_1:
        LD (SUB_0B2A_37),HL              ; $1AA0  22 8C 0B
SUB_1A93_2:
        LD HL,(SUB_0B2A_37)              ; $1AA3  2A 8C 0B
        POP BC                           ; $1AA6  C1
        LD A,(HL)                        ; $1AA7  7E
        LD (SUB_0B2A_20),HL              ; $1AA8  22 6D 0B
        CP $EF                           ; $1AAB  FE EF
        RET C                            ; $1AAD  D8
        CP $F2                           ; $1AAE  FE F2
        JP C,SUB_1A93_12                 ; $1AB0  DA 1C 1B
        SUB $F2                          ; $1AB3  D6 F2
        LD E,A                           ; $1AB5  5F
        JR NZ,SUB_1A93_4                 ; $1AB6  20 09
        LD A,(SUB_0B2A_5)                ; $1AB8  3A 37 0B
SUB_1A93_3:
        CP $03                           ; $1ABB  FE 03
        LD A,E                           ; $1ABD  7B
        JP Z,SUB_49C3_3                  ; $1ABE  CA EE 49
SUB_1A93_4:
        CP $0C                           ; $1AC1  FE 0C
        RET NC                           ; $1AC3  D0
        LD HL,L_04ED                     ; $1AC4  21 ED 04
        LD D,$00                         ; $1AC7  16 00
        ADD HL,DE                        ; $1AC9  19
        LD A,B                           ; $1ACA  78
        LD D,(HL)                        ; $1ACB  56
        CP D                             ; $1ACC  BA
SUB_1A93_5:
        RET NC                           ; $1ACD  D0
        PUSH BC                          ; $1ACE  C5
        LD BC,SUB_1A93_2                 ; $1ACF  01 A3 1A
        PUSH BC                          ; $1AD2  C5
SUB_1A93_6:
        LD A,D                           ; $1AD3  7A
        CP $7F                           ; $1AD4  FE 7F
SUB_1A93_7:
        JP Z,SUB_1A93_14                 ; $1AD6  CA 39 1B
        CP $51                           ; $1AD9  FE 51
        JP C,SUB_1A93_15                 ; $1ADB  DA 46 1B
        AND $FE                          ; $1ADE  E6 FE
        CP $7A                           ; $1AE0  FE 7A
        JP Z,SUB_1A93_15                 ; $1AE2  CA 46 1B
SUB_1A93_8:
        LD HL,SUB_0C98_4                 ; $1AE5  21 D4 0C
        LD A,(SUB_0B2A_5)                ; $1AE8  3A 37 0B
        SUB $03                          ; $1AEB  D6 03
        JP Z,SUB_0D20_27+1               ; $1AED  CA AA 0D
        OR A                             ; $1AF0  B7
SUB_1A93_9:
        LD C,(HL)                        ; $1AF1  4E
        INC HL                           ; $1AF2  23
        LD B,(HL)                        ; $1AF3  46
        PUSH BC                          ; $1AF4  C5
        JP M,SUB_1A93_10                 ; $1AF5  FA 0D 1B
        INC HL                           ; $1AF8  23
        LD C,(HL)                        ; $1AF9  4E
        INC HL                           ; $1AFA  23
        LD B,(HL)                        ; $1AFB  46
        PUSH BC                          ; $1AFC  C5
        JP PO,SUB_1A93_10                ; $1AFD  E2 0D 1B
        INC HL                           ; $1B00  23
        LD HL,SUB_0C98_1                 ; $1B01  21 D0 0C
        LD C,(HL)                        ; $1B04  4E
        INC HL                           ; $1B05  23
        LD B,(HL)                        ; $1B06  46
        INC HL                           ; $1B07  23
        PUSH BC                          ; $1B08  C5
        LD C,(HL)                        ; $1B09  4E
        INC HL                           ; $1B0A  23
        LD B,(HL)                        ; $1B0B  46
        PUSH BC                          ; $1B0C  C5
SUB_1A93_10:
        ADD A,$03                        ; $1B0D  C6 03
        LD C,E                           ; $1B0F  4B
        LD B,A                           ; $1B10  47
        PUSH BC                          ; $1B11  C5
        LD BC,SUB_1A93_17                ; $1B12  01 6D 1B
SUB_1A93_11:
        PUSH BC                          ; $1B15  C5
        LD HL,(SUB_0B2A_20)              ; $1B16  2A 6D 0B
        JP SUB_1A93                      ; $1B19  C3 93 1A
SUB_1A93_12:
        LD D,$00                         ; $1B1C  16 00
SUB_1A93_13:
        SUB $EF                          ; $1B1E  D6 EF
        JP C,SUB_1A93_16                 ; $1B20  DA 51 1B
        CP $03                           ; $1B23  FE 03
        JP NC,SUB_1A93_16                ; $1B25  D2 51 1B
        CP $01                           ; $1B28  FE 01
        RLA                              ; $1B2A  17
        XOR D                            ; $1B2B  AA
        CP D                             ; $1B2C  BA
        LD D,A                           ; $1B2D  57
        JP C,SUB_0D20_20                 ; $1B2E  DA 92 0D
        LD (SUB_0B2A_20),HL              ; $1B31  22 6D 0B
        CALL SUB_13E4                    ; $1B34  CD E4 13
        JR SUB_1A93_13                   ; $1B37  18 E5
SUB_1A93_14:
        CALL SUB_2C6C                    ; $1B39  CD 6C 2C
        CALL SUB_2B18                    ; $1B3C  CD 18 2B
        LD BC,SUB_3809_19                ; $1B3F  01 16 39
        LD D,$7F                         ; $1B42  16 7F
        JR SUB_1A93_11                   ; $1B44  18 CF
SUB_1A93_15:
        PUSH DE                          ; $1B46  D5
        CALL SUB_2BF4                    ; $1B47  CD F4 2B
        POP DE                           ; $1B4A  D1
        PUSH HL                          ; $1B4B  E5
        LD BC,SUB_1DE3_2                 ; $1B4C  01 F3 1D
        JR SUB_1A93_11                   ; $1B4F  18 C4
SUB_1A93_16:
        LD A,B                           ; $1B51  78
        CP $64                           ; $1B52  FE 64
        RET NC                           ; $1B54  D0
        PUSH BC                          ; $1B55  C5
        PUSH DE                          ; $1B56  D5
        LD DE,$6404                      ; $1B57  11 04 64
        LD HL,SUB_1DB2_1                 ; $1B5A  21 C2 1D
        PUSH HL                          ; $1B5D  E5
        CALL SUB_1DE3                    ; $1B5E  CD E3 1D
        JP NZ,SUB_1A93_8                 ; $1B61  C2 E5 1A
        LD HL,(SUB_0C98_4)               ; $1B64  2A D4 0C
        PUSH HL                          ; $1B67  E5
        LD BC,SUB_475A_9                 ; $1B68  01 01 48
        JR SUB_1A93_11                   ; $1B6B  18 A8
SUB_1A93_17:
        POP BC                           ; $1B6D  C1
        LD A,C                           ; $1B6E  79
        LD (SUB_0B2A_6),A                ; $1B6F  32 38 0B
SUB_1A93_18:
        LD A,(SUB_0B2A_5)                ; $1B72  3A 37 0B
        CP B                             ; $1B75  B8
        JR NZ,SUB_1A93_19                ; $1B76  20 0B
        CP $02                           ; $1B78  FE 02
        JR Z,SUB_1A93_20                 ; $1B7A  28 1F
        CP $04                           ; $1B7C  FE 04
        JP Z,L_1BE7                      ; $1B7E  CA E7 1B
        JR NC,SUB_1A93_22                ; $1B81  30 2B
SUB_1A93_19:
        LD D,A                           ; $1B83  57
        LD A,B                           ; $1B84  78
        CP $08                           ; $1B85  FE 08
        JR Z,SUB_1A93_21                 ; $1B87  28 22
        LD A,D                           ; $1B89  7A
        CP $08                           ; $1B8A  FE 08
        JR Z,SUB_1A93_26                 ; $1B8C  28 44
        LD A,B                           ; $1B8E  78
        CP $04                           ; $1B8F  FE 04
        JR Z,L_1BE4                      ; $1B91  28 51
        LD A,D                           ; $1B93  7A
        CP $03                           ; $1B94  FE 03
        JP Z,SUB_0D20_27+1               ; $1B96  CA AA 0D
        JR NC,SUB_1A93_27                ; $1B99  30 53
SUB_1A93_20:
        LD HL,L_0517                     ; $1B9B  21 17 05
        LD B,$00                         ; $1B9E  06 00
        ADD HL,BC                        ; $1BA0  09
        ADD HL,BC                        ; $1BA1  09
        LD C,(HL)                        ; $1BA2  4E
        INC HL                           ; $1BA3  23
        LD B,(HL)                        ; $1BA4  46
        POP DE                           ; $1BA5  D1
        LD HL,(SUB_0C98_4)               ; $1BA6  2A D4 0C
        PUSH BC                          ; $1BA9  C5
        RET                              ; $1BAA  C9
SUB_1A93_21:
        CALL SUB_2C98                    ; $1BAB  CD 98 2C
SUB_1A93_22:
        CALL SUB_2B6F                    ; $1BAE  CD 6F 2B
        POP HL                           ; $1BB1  E1
        LD (SUB_0C98_2),HL               ; $1BB2  22 D2 0C
        POP HL                           ; $1BB5  E1
        LD (SUB_0C98_1),HL               ; $1BB6  22 D0 0C
SUB_1A93_23:
        POP BC                           ; $1BB9  C1
        POP DE                           ; $1BBA  D1
        CALL SUB_2B28                    ; $1BBB  CD 28 2B
        CALL SUB_2C98                    ; $1BBE  CD 98 2C
        LD HL,L_0503                     ; $1BC1  21 03 05
        LD A,(SUB_0B2A_6)                ; $1BC4  3A 38 0B
        RLCA                             ; $1BC7  07
        ADD A,L                          ; $1BC8  85
SUB_1A93_24:
        LD L,A                           ; $1BC9  6F
SUB_1A93_25:
        ADC A,H                          ; $1BCA  8C
        SUB L                            ; $1BCB  95
        LD H,A                           ; $1BCC  67
        LD A,(HL)                        ; $1BCD  7E
        INC HL                           ; $1BCE  23
        LD H,(HL)                        ; $1BCF  66
        LD L,A                           ; $1BD0  6F
        JP (HL)                          ; $1BD1  E9
SUB_1A93_26:
        PUSH BC                          ; $1BD2  C5
        CALL SUB_2B6F                    ; $1BD3  CD 6F 2B
        POP AF                           ; $1BD6  F1
        LD (SUB_0B2A_5),A                ; $1BD7  32 37 0B
        CP $04                           ; $1BDA  FE 04
        JR Z,SUB_1A93_23                 ; $1BDC  28 DB
        POP HL                           ; $1BDE  E1
        LD (SUB_0C98_4),HL               ; $1BDF  22 D4 0C
        DEFB    $18,$DA                                          ; $1BE2
L_1BE4:
        DEFB    $CD,$6C,$2C                                      ; $1BE4
L_1BE7:
        DEFB    $C1,$D1                                          ; $1BE7
L_1BE9:
        DEFB    $21,$0D,$05,$18,$D6                              ; $1BE9
SUB_1A93_27:
        POP HL                           ; $1BEE  E1
        CALL SUB_2B18                    ; $1BEF  CD 18 2B
        CALL SUB_2C8C                    ; $1BF2  CD 8C 2C
        CALL SUB_2B33                    ; $1BF5  CD 33 2B
        POP HL                           ; $1BF8  E1
        LD (SUB_0C98_5),HL               ; $1BF9  22 D6 0C
        POP HL                           ; $1BFC  E1
        LD (SUB_0C98_4),HL               ; $1BFD  22 D4 0C
        JR L_1BE9                        ; $1C00  18 E7
        DEFB    $E5,$EB,$CD                                      ; $1C02
        DEFW    SUB_2C8C                 ; $1C05
        DEFB    $E1                                              ; $1C07
        DEFW    SUB_189A_5               ; $1C08
        DEFB    $2B,$CD                                          ; $1C0A
        DEFW    SUB_2C8C                 ; $1C0C
        DEFB    $C3                                              ; $1C0E
        DEFW    SUB_29E8_2               ; $1C0F
SUB_1C11:
        CALL SUB_13E4                    ; $1C11  CD E4 13
SUB_1C11_1:
        JP Z,SUB_0D20_26+1               ; $1C14  CA A7 0D
        JP C,SUB_311E_1+1                ; $1C17  DA 25 31
        CALL SUB_46BF                    ; $1C1A  CD BF 46
        JP NC,SUB_1CC1_4                 ; $1C1D  D2 D7 1C
SUB_1C11_2:
        CP $20                           ; $1C20  FE 20
        JP C,SUB_1460                    ; $1C22  DA 60 14
        INC A                            ; $1C25  3C
        JP Z,SUB_1CF6_7                  ; $1C26  CA 56 1D
        DEC A                            ; $1C29  3D
        CP $F2                           ; $1C2A  FE F2
        JR Z,SUB_1C11                    ; $1C2C  28 E3
        CP $F3                           ; $1C2E  FE F3
        JP Z,SUB_1CC1_2                  ; $1C30  CA C9 1C
        CP $22                           ; $1C33  FE 22
        JP Z,SUB_4868_1                  ; $1C35  CA 69 48
        CP $E4                           ; $1C38  FE E4
        JP Z,SUB_1DB2_3                  ; $1C3A  CA CE 1D
        CP $26                           ; $1C3D  FE 26
        JP Z,SUB_1CF6                    ; $1C3F  CA F6 1C
        CP $E6                           ; $1C42  FE E6
        JR NZ,SUB_1C11_3                 ; $1C44  20 0C
        CALL SUB_13E4                    ; $1C46  CD E4 13
        LD A,(SUB_0752_33+2)             ; $1C49  3A 58 08
        PUSH HL                          ; $1C4C  E5
        CALL SUB_1E4D                    ; $1C4D  CD 4D 1E
        POP HL                           ; $1C50  E1
        RET                              ; $1C51  C9
SUB_1C11_3:
        CP $E5                           ; $1C52  FE E5
        JR NZ,SUB_1C11_5                 ; $1C54  20 0C
        CALL SUB_13E4                    ; $1C56  CD E4 13
        PUSH HL                          ; $1C59  E5
SUB_1C11_4:
        LD HL,(SUB_0B2A_32)              ; $1C5A  2A 83 0B
        CALL SUB_2E6C                    ; $1C5D  CD 6C 2E
        POP HL                           ; $1C60  E1
        RET                              ; $1C61  C9
SUB_1C11_5:
        CP $EB                           ; $1C62  FE EB
        JR NZ,SUB_1C11_9                 ; $1C64  20 29
        CALL SUB_13E4                    ; $1C66  CD E4 13
        CALL SUB_45A3                    ; $1C69  CD A3 45
SUB_1C11_6:
        JR Z,SUB_1C11_6                  ; $1C6C  28 FE
        INC HL                           ; $1C6E  23
        JR NZ,SUB_1C11_7                 ; $1C6F  20 0B
        CALL SUB_20AF                    ; $1C71  CD AF 20
        PUSH HL                          ; $1C74  E5
        CALL SUB_52CF                    ; $1C75  CD CF 52
        POP HL                           ; $1C78  E1
        JP SUB_1C11_8                    ; $1C79  C3 7F 1C
SUB_1C11_7:
        CALL SUB_3BB3                    ; $1C7C  CD B3 3B
SUB_1C11_8:
        CALL SUB_45A3                    ; $1C7F  CD A3 45
        ADD HL,HL                        ; $1C82  29
        PUSH HL                          ; $1C83  E5
        EX DE,HL                         ; $1C84  EB
        LD A,H                           ; $1C85  7C
        OR L                             ; $1C86  B5
        JP Z,SUB_14E4_2                  ; $1C87  CA EB 14
        CALL SUB_2C55                    ; $1C8A  CD 55 2C
        POP HL                           ; $1C8D  E1
        RET                              ; $1C8E  C9
SUB_1C11_9:
        CP $E1                           ; $1C8F  FE E1
        JP Z,SUB_1E4D_2                  ; $1C91  CA 53 1E
        CP $E9                           ; $1C94  FE E9
        JP Z,SUB_4B4F_1                  ; $1C96  CA 54 4B
        CP $CD                           ; $1C99  FE CD
        JP Z,SUB_2602_10                 ; $1C9B  CA 93 27
        CP $D3                           ; $1C9E  FE D3
        JP Z,SUB_2803_2+1                ; $1CA0  CA 0F 28
        CP $EC                           ; $1CA3  FE EC
        JP Z,SUB_2602_9                  ; $1CA5  CA 78 27
        CP $ED                           ; $1CA8  FE ED
        JP Z,SUB_2803_2+1                ; $1CAA  CA 0F 28
        CP $EE                           ; $1CAD  FE EE
        JP Z,SUB_4437_2                  ; $1CAF  CA 4A 44
        CP $E7                           ; $1CB2  FE E7
        JP Z,SUB_4A89_2                  ; $1CB4  CA 91 4A
        CP $85                           ; $1CB7  FE 85
        JP Z,SUB_5645_5                  ; $1CB9  CA 65 56
        CP $E2                           ; $1CBC  FE E2
        JP Z,SUB_1E72_7                  ; $1CBE  CA C8 1E
SUB_1CC1:
        CALL SUB_1A8C                    ; $1CC1  CD 8C 1A
        CALL SUB_45A3                    ; $1CC4  CD A3 45
SUB_1CC1_1:
        ADD HL,HL                        ; $1CC7  29
        RET                              ; $1CC8  C9
SUB_1CC1_2:
        LD D,$7D                         ; $1CC9  16 7D
        CALL SUB_1A93                    ; $1CCB  CD 93 1A
        LD HL,(SUB_0B2A_37)              ; $1CCE  2A 8C 0B
        PUSH HL                          ; $1CD1  E5
        CALL SUB_2AEB                    ; $1CD2  CD EB 2A
SUB_1CC1_3:
        POP HL                           ; $1CD5  E1
        RET                              ; $1CD6  C9
SUB_1CC1_4:
        CALL SUB_3BB3                    ; $1CD7  CD B3 3B
SUB_1CC1_5:
        PUSH HL                          ; $1CDA  E5
        EX DE,HL                         ; $1CDB  EB
        LD (SUB_0C98_4),HL               ; $1CDC  22 D4 0C
        CALL SUB_1DE3                    ; $1CDF  CD E3 1D
        CALL NZ,SUB_2B6A                 ; $1CE2  C4 6A 2B
        POP HL                           ; $1CE5  E1
        RET                              ; $1CE6  C9
SUB_1CE7:
        LD A,(HL)                        ; $1CE7  7E
SUB_1CE8:
        CP $61                           ; $1CE8  FE 61
        RET C                            ; $1CEA  D8
        CP $7B                           ; $1CEB  FE 7B
        RET NC                           ; $1CED  D0
        AND $5F                          ; $1CEE  E6 5F
        RET                              ; $1CF0  C9
SUB_1CE8_1:
        CP $26                           ; $1CF1  FE 26
        JP NZ,SUB_14FB                   ; $1CF3  C2 FB 14
SUB_1CF6:
        LD DE,$0000                      ; $1CF6  11 00 00
        CALL SUB_13E4                    ; $1CF9  CD E4 13
        CALL SUB_1CE8                    ; $1CFC  CD E8 1C
        CP $4F                           ; $1CFF  FE 4F
        JR Z,SUB_1CF6_5                  ; $1D01  28 2F
        CP $48                           ; $1D03  FE 48
        JR NZ,SUB_1CF6_4                 ; $1D05  20 2A
        LD B,$05                         ; $1D07  06 05
SUB_1CF6_1:
        INC HL                           ; $1D09  23
        LD A,(HL)                        ; $1D0A  7E
        CALL SUB_1CE8                    ; $1D0B  CD E8 1C
        CALL SUB_46BF                    ; $1D0E  CD BF 46
        EX DE,HL                         ; $1D11  EB
        JR NC,SUB_1CF6_2                 ; $1D12  30 0A
        CP $3A                           ; $1D14  FE 3A
        JR NC,SUB_1CF6_6                 ; $1D16  30 39
        SUB $30                          ; $1D18  D6 30
        JR C,SUB_1CF6_6                  ; $1D1A  38 35
        JR SUB_1CF6_3                    ; $1D1C  18 06
SUB_1CF6_2:
        CP $47                           ; $1D1E  FE 47
        JR NC,SUB_1CF6_6                 ; $1D20  30 2F
        SUB $37                          ; $1D22  D6 37
SUB_1CF6_3:
        ADD HL,HL                        ; $1D24  29
        ADD HL,HL                        ; $1D25  29
        ADD HL,HL                        ; $1D26  29
        ADD HL,HL                        ; $1D27  29
        OR L                             ; $1D28  B5
        LD L,A                           ; $1D29  6F
        DEC B                            ; $1D2A  05
        JP Z,SUB_0D20_25+1               ; $1D2B  CA A4 0D
        EX DE,HL                         ; $1D2E  EB
        JR SUB_1CF6_1                    ; $1D2F  18 D8
SUB_1CF6_4:
        DEC HL                           ; $1D31  2B
SUB_1CF6_5:
        CALL SUB_13E4                    ; $1D32  CD E4 13
        EX DE,HL                         ; $1D35  EB
        JR NC,SUB_1CF6_6                 ; $1D36  30 19
        CP $38                           ; $1D38  FE 38
        JP NC,SUB_0D20_20                ; $1D3A  D2 92 0D
        LD BC,SUB_0D20_25+1              ; $1D3D  01 A4 0D
        PUSH BC                          ; $1D40  C5
        ADD HL,HL                        ; $1D41  29
        RET C                            ; $1D42  D8
        ADD HL,HL                        ; $1D43  29
        RET C                            ; $1D44  D8
        ADD HL,HL                        ; $1D45  29
        RET C                            ; $1D46  D8
        POP BC                           ; $1D47  C1
        LD B,$00                         ; $1D48  06 00
        SUB $30                          ; $1D4A  D6 30
        LD C,A                           ; $1D4C  4F
        ADD HL,BC                        ; $1D4D  09
        EX DE,HL                         ; $1D4E  EB
        JR SUB_1CF6_5                    ; $1D4F  18 E1
SUB_1CF6_6:
        CALL SUB_2C55                    ; $1D51  CD 55 2C
        EX DE,HL                         ; $1D54  EB
        RET                              ; $1D55  C9
SUB_1CF6_7:
        INC HL                           ; $1D56  23
        LD A,(HL)                        ; $1D57  7E
        SUB $81                          ; $1D58  D6 81
        CP $07                           ; $1D5A  FE 07
        JR NZ,SUB_1CF6_8                 ; $1D5C  20 0C
        PUSH HL                          ; $1D5E  E5
        CALL SUB_13E4                    ; $1D5F  CD E4 13
        CP $28                           ; $1D62  FE 28
        POP HL                           ; $1D64  E1
        JP NZ,SUB_39E3_3                 ; $1D65  C2 07 3A
        LD A,$07                         ; $1D68  3E 07
SUB_1CF6_8:
        LD B,$00                         ; $1D6A  06 00
        RLCA                             ; $1D6C  07
        LD C,A                           ; $1D6D  4F
        PUSH BC                          ; $1D6E  C5
        CALL SUB_13E4                    ; $1D6F  CD E4 13
        LD A,C                           ; $1D72  79
        CP $05                           ; $1D73  FE 05
        JP NC,SUB_1CF6_9                 ; $1D75  D2 90 1D
        CALL SUB_1A8C                    ; $1D78  CD 8C 1A
        CALL SUB_45A3                    ; $1D7B  CD A3 45
        INC L                            ; $1D7E  2C
        CALL SUB_2CB3                    ; $1D7F  CD B3 2C
        EX DE,HL                         ; $1D82  EB
        LD HL,(SUB_0C98_4)               ; $1D83  2A D4 0C
        EX (SP),HL                       ; $1D86  E3
        PUSH HL                          ; $1D87  E5
        EX DE,HL                         ; $1D88  EB
        CALL SUB_20B2                    ; $1D89  CD B2 20
        EX DE,HL                         ; $1D8C  EB
        EX (SP),HL                       ; $1D8D  E3
        JR SUB_1CF6_11                   ; $1D8E  18 19
SUB_1CF6_9:
        CALL SUB_1CC1                    ; $1D90  CD C1 1C
        EX (SP),HL                       ; $1D93  E3
        LD A,L                           ; $1D94  7D
        CP $0C                           ; $1D95  FE 0C
        JR C,SUB_1CF6_10                 ; $1D97  38 07
        CP $1B                           ; $1D99  FE 1B
        PUSH HL                          ; $1D9B  E5
        CALL C,SUB_2C6C                  ; $1D9C  DC 6C 2C
        POP HL                           ; $1D9F  E1
SUB_1CF6_10:
        LD DE,SUB_1CC1_3                 ; $1DA0  11 D5 1C
        PUSH DE                          ; $1DA3  D5
        LD A,$01                         ; $1DA4  3E 01
        LD (SUB_0C98_8),A                ; $1DA6  32 D9 0C
SUB_1CF6_11:
        LD BC,SUB_0100_15                ; $1DA9  01 B2 01
SUB_1DAC:
        ADD HL,BC                        ; $1DAC  09
        LD C,(HL)                        ; $1DAD  4E
        INC HL                           ; $1DAE  23
        LD H,(HL)                        ; $1DAF  66
        LD L,C                           ; $1DB0  69
        JP (HL)                          ; $1DB1  E9
SUB_1DB2:
        DEC D                            ; $1DB2  15
        CP $F3                           ; $1DB3  FE F3
        RET Z                            ; $1DB5  C8
        CP $2D                           ; $1DB6  FE 2D
        RET Z                            ; $1DB8  C8
        INC D                            ; $1DB9  14
        CP $2B                           ; $1DBA  FE 2B
        RET Z                            ; $1DBC  C8
        CP $F2                           ; $1DBD  FE F2
        RET Z                            ; $1DBF  C8
        DEC HL                           ; $1DC0  2B
        RET                              ; $1DC1  C9
SUB_1DB2_1:
        INC A                            ; $1DC2  3C
        ADC A,A                          ; $1DC3  8F
        POP BC                           ; $1DC4  C1
        AND B                            ; $1DC5  A0
        ADD A,$FF                        ; $1DC6  C6 FF
        SBC A,A                          ; $1DC8  9F
        CALL SUB_2AFF                    ; $1DC9  CD FF 2A
SUB_1DB2_2:
        JR SUB_1DB2_4                    ; $1DCC  18 12
SUB_1DB2_3:
        LD D,$5A                         ; $1DCE  16 5A
        CALL SUB_1A93                    ; $1DD0  CD 93 1A
        CALL SUB_2BF4                    ; $1DD3  CD F4 2B
        LD A,L                           ; $1DD6  7D
        CPL                              ; $1DD7  2F
        LD L,A                           ; $1DD8  6F
        LD A,H                           ; $1DD9  7C
        CPL                              ; $1DDA  2F
        LD H,A                           ; $1DDB  67
        LD (SUB_0C98_4),HL               ; $1DDC  22 D4 0C
        POP BC                           ; $1DDF  C1
SUB_1DB2_4:
        JP SUB_1A93_2                    ; $1DE0  C3 A3 1A
SUB_1DE3:
        LD A,(SUB_0B2A_5)                ; $1DE3  3A 37 0B
        CP $08                           ; $1DE6  FE 08
        JR NC,SUB_1DE3_1                 ; $1DE8  30 05
        SUB $03                          ; $1DEA  D6 03
        OR A                             ; $1DEC  B7
        SCF                              ; $1DED  37
        RET                              ; $1DEE  C9
SUB_1DE3_1:
        SUB $03                          ; $1DEF  D6 03
        OR A                             ; $1DF1  B7
        RET                              ; $1DF2  C9
SUB_1DE3_2:
        PUSH BC                          ; $1DF3  C5
        CALL SUB_2BF4                    ; $1DF4  CD F4 2B
        POP AF                           ; $1DF7  F1
        POP DE                           ; $1DF8  D1
        CP $7A                           ; $1DF9  FE 7A
        JP Z,SUB_2E76                    ; $1DFB  CA 76 2E
        CP $7B                           ; $1DFE  FE 7B
        JP Z,SUB_2E14                    ; $1E00  CA 14 2E
        LD BC,SUB_1E4D_1                 ; $1E03  01 4F 1E
        PUSH BC                          ; $1E06  C5
        CP $46                           ; $1E07  FE 46
        JR NZ,SUB_1DE3_3                 ; $1E09  20 06
        LD A,E                           ; $1E0B  7B
        OR L                             ; $1E0C  B5
        LD L,A                           ; $1E0D  6F
        LD A,H                           ; $1E0E  7C
        OR D                             ; $1E0F  B2
        RET                              ; $1E10  C9
SUB_1DE3_3:
        CP $50                           ; $1E11  FE 50
        JR NZ,SUB_1DE3_4                 ; $1E13  20 06
        LD A,E                           ; $1E15  7B
        AND L                            ; $1E16  A5
        LD L,A                           ; $1E17  6F
        LD A,H                           ; $1E18  7C
        AND D                            ; $1E19  A2
        RET                              ; $1E1A  C9
SUB_1DE3_4:
        CP $3C                           ; $1E1B  FE 3C
SUB_1E1D:
        JR NZ,SUB_1E1D_2                 ; $1E1D  20 06
        LD A,E                           ; $1E1F  7B
        XOR L                            ; $1E20  AD
SUB_1E1D_1:
        LD L,A                           ; $1E21  6F
        LD A,H                           ; $1E22  7C
        XOR D                            ; $1E23  AA
        RET                              ; $1E24  C9
SUB_1E1D_2:
        CP $32                           ; $1E25  FE 32
        JR NZ,SUB_1E1D_3                 ; $1E27  20 08
        LD A,E                           ; $1E29  7B
        XOR L                            ; $1E2A  AD
        CPL                              ; $1E2B  2F
        LD L,A                           ; $1E2C  6F
        LD A,H                           ; $1E2D  7C
        XOR D                            ; $1E2E  AA
        CPL                              ; $1E2F  2F
        RET                              ; $1E30  C9
SUB_1E1D_3:
        LD A,L                           ; $1E31  7D
        CPL                              ; $1E32  2F
        AND E                            ; $1E33  A3
        CPL                              ; $1E34  2F
        LD L,A                           ; $1E35  6F
        LD A,H                           ; $1E36  7C
        CPL                              ; $1E37  2F
        AND D                            ; $1E38  A2
        CPL                              ; $1E39  2F
        RET                              ; $1E3A  C9
        DEFB    $7D,$93,$6F,$7C,$9A,$67,$C3                      ; $1E3B
        DEFW    SUB_2E6C                 ; $1E42
        DEFW    SUB_58FE_15              ; $1E44
        DEFB    $08,$18                                          ; $1E46
        DEFW    SUB_39E3_2               ; $1E48
        DEFW    SUB_0B2A_2               ; $1E4A
        DEFB    $3C                                              ; $1E4C
SUB_1E4D:
        LD L,A                           ; $1E4D  6F
        XOR A                            ; $1E4E  AF
SUB_1E4D_1:
        LD H,A                           ; $1E4F  67
        JP SUB_2C55                      ; $1E50  C3 55 2C
SUB_1E4D_2:
        CALL SUB_1E72                    ; $1E53  CD 72 1E
        PUSH DE                          ; $1E56  D5
        CALL SUB_1CC1                    ; $1E57  CD C1 1C
SUB_1E5A:
        EX (SP),HL                       ; $1E5A  E3
        LD C,(HL)                        ; $1E5B  4E
        INC HL                           ; $1E5C  23
        LD B,(HL)                        ; $1E5D  46
        LD HL,SUB_2990_7                 ; $1E5E  21 E1 29
        PUSH HL                          ; $1E61  E5
        PUSH BC                          ; $1E62  C5
        LD A,(SUB_0B2A_5)                ; $1E63  3A 37 0B
        PUSH AF                          ; $1E66  F5
        CP $03                           ; $1E67  FE 03
        CALL Z,SUB_4A3A                  ; $1E69  CC 3A 4A
        POP AF                           ; $1E6C  F1
        EX DE,HL                         ; $1E6D  EB
        LD HL,SUB_0C98_4                 ; $1E6E  21 D4 0C
        RET                              ; $1E71  C9
SUB_1E72:
        CALL SUB_13E4                    ; $1E72  CD E4 13
        LD BC,$0000                      ; $1E75  01 00 00
        CP $1B                           ; $1E78  FE 1B
        JR NC,SUB_1E72_1                 ; $1E7A  30 0D
        CP $11                           ; $1E7C  FE 11
        JR C,SUB_1E72_1                  ; $1E7E  38 09
        CALL SUB_13E4                    ; $1E80  CD E4 13
        LD A,(SUB_0B2A_11)               ; $1E83  3A 3E 0B
        OR A                             ; $1E86  B7
        RLA                              ; $1E87  17
        LD C,A                           ; $1E88  4F
SUB_1E72_1:
        EX DE,HL                         ; $1E89  EB
        LD HL,SUB_0752_30                ; $1E8A  21 42 08
        ADD HL,BC                        ; $1E8D  09
        EX DE,HL                         ; $1E8E  EB
        RET                              ; $1E8F  C9
SUB_1E72_2:
        CALL SUB_1E72                    ; $1E90  CD 72 1E
        PUSH DE                          ; $1E93  D5
        CALL SUB_45A3                    ; $1E94  CD A3 45
        RET P                            ; $1E97  F0
        CALL SUB_20A3                    ; $1E98  CD A3 20
        EX (SP),HL                       ; $1E9B  E3
        LD (HL),E                        ; $1E9C  73
        INC HL                           ; $1E9D  23
        LD (HL),D                        ; $1E9E  72
        POP HL                           ; $1E9F  E1
SUB_1E72_3:
        RET                              ; $1EA0  C9
SUB_1E72_4:
        CP $E1                           ; $1EA1  FE E1
        JR Z,SUB_1E72_2                  ; $1EA3  28 EB
        CALL SUB_2041                    ; $1EA5  CD 41 20
        CALL SUB_2033                    ; $1EA8  CD 33 20
        EX DE,HL                         ; $1EAB  EB
        LD (HL),E                        ; $1EAC  73
        INC HL                           ; $1EAD  23
        LD (HL),D                        ; $1EAE  72
        EX DE,HL                         ; $1EAF  EB
        LD A,(HL)                        ; $1EB0  7E
        CP $28                           ; $1EB1  FE 28
        JP NZ,SUB_15CF                   ; $1EB3  C2 CF 15
SUB_1E72_5:
        CALL SUB_13E4                    ; $1EB6  CD E4 13
SUB_1E72_6:
        CALL SUB_3BB3                    ; $1EB9  CD B3 3B
        LD A,(HL)                        ; $1EBC  7E
        CP $29                           ; $1EBD  FE 29
        JP Z,SUB_15CF                    ; $1EBF  CA CF 15
        CALL SUB_45A3                    ; $1EC2  CD A3 45
        INC L                            ; $1EC5  2C
        JR SUB_1E72_6                    ; $1EC6  18 F1
SUB_1E72_7:
        CALL SUB_2041                    ; $1EC8  CD 41 20
        LD A,(SUB_0B2A_5)                ; $1ECB  3A 37 0B
        OR A                             ; $1ECE  B7
        PUSH AF                          ; $1ECF  F5
        LD (SUB_0B2A_37),HL              ; $1ED0  22 8C 0B
        EX DE,HL                         ; $1ED3  EB
        LD A,(HL)                        ; $1ED4  7E
        INC HL                           ; $1ED5  23
        LD H,(HL)                        ; $1ED6  66
SUB_1E72_8:
        LD L,A                           ; $1ED7  6F
SUB_1E72_9:
        OR H                             ; $1ED8  B4
        JP Z,SUB_0D20_24+1               ; $1ED9  CA 9E 0D
        LD A,(HL)                        ; $1EDC  7E
        CP $28                           ; $1EDD  FE 28
        JP NZ,SUB_1E72_17+1              ; $1EDF  C2 8E 1F
        CALL SUB_13E4                    ; $1EE2  CD E4 13
        LD (SUB_0B2A_20),HL              ; $1EE5  22 6D 0B
        EX DE,HL                         ; $1EE8  EB
        LD HL,(SUB_0B2A_37)              ; $1EE9  2A 8C 0B
        CALL SUB_45A3                    ; $1EEC  CD A3 45
        JR Z,SUB_1E72_3                  ; $1EEF  28 AF
        PUSH AF                          ; $1EF1  F5
        PUSH HL                          ; $1EF2  E5
        EX DE,HL                         ; $1EF3  EB
SUB_1E72_10:
        LD A,$80                         ; $1EF4  3E 80
        LD (SUB_0B2A_23),A               ; $1EF6  32 75 0B
        CALL SUB_3BB3                    ; $1EF9  CD B3 3B
        EX DE,HL                         ; $1EFC  EB
        EX (SP),HL                       ; $1EFD  E3
        LD A,(SUB_0B2A_5)                ; $1EFE  3A 37 0B
        PUSH AF                          ; $1F01  F5
        PUSH DE                          ; $1F02  D5
        CALL SUB_1A8C_1+1                ; $1F03  CD 90 1A
        LD (SUB_0B2A_37),HL              ; $1F06  22 8C 0B
        POP HL                           ; $1F09  E1
        LD (SUB_0B2A_20),HL              ; $1F0A  22 6D 0B
        POP AF                           ; $1F0D  F1
        CALL SUB_201A                    ; $1F0E  CD 1A 20
        LD C,$04                         ; $1F11  0E 04
SUB_1E72_11:
        CALL SUB_449F                    ; $1F13  CD 9F 44
        LD HL,$FFF8                      ; $1F16  21 F8 FF
        ADD HL,SP                        ; $1F19  39
        LD SP,HL                         ; $1F1A  F9
        CALL SUB_2B72                    ; $1F1B  CD 72 2B
SUB_1E72_12:
        LD A,(SUB_0B2A_5)                ; $1F1E  3A 37 0B
        PUSH AF                          ; $1F21  F5
        LD HL,(SUB_0B2A_37)              ; $1F22  2A 8C 0B
        LD A,(HL)                        ; $1F25  7E
        CP $29                           ; $1F26  FE 29
        JR Z,SUB_1E72_14                 ; $1F28  28 12
        CALL SUB_45A3                    ; $1F2A  CD A3 45
        INC L                            ; $1F2D  2C
        PUSH HL                          ; $1F2E  E5
        LD HL,(SUB_0B2A_20)              ; $1F2F  2A 6D 0B
        CALL SUB_45A3                    ; $1F32  CD A3 45
        INC L                            ; $1F35  2C
        JR SUB_1E72_10                   ; $1F36  18 BC
SUB_1E72_13:
        POP AF                           ; $1F38  F1
        LD (SUB_0C03_2),A                ; $1F39  32 1E 0C
SUB_1E72_14:
        POP AF                           ; $1F3C  F1
        OR A                             ; $1F3D  B7
        JR Z,SUB_1E72_16                 ; $1F3E  28 3F
        LD (SUB_0B2A_5),A                ; $1F40  32 37 0B
        LD HL,$0000                      ; $1F43  21 00 00
        ADD HL,SP                        ; $1F46  39
        CALL SUB_2B6A                    ; $1F47  CD 6A 2B
        LD HL,$0008                      ; $1F4A  21 08 00
        ADD HL,SP                        ; $1F4D  39
        LD SP,HL                         ; $1F4E  F9
        POP DE                           ; $1F4F  D1
        LD L,$03                         ; $1F50  2E 03
SUB_1E72_15:
        INC L                            ; $1F52  2C
        DEC DE                           ; $1F53  1B
        LD A,(DE)                        ; $1F54  1A
        OR A                             ; $1F55  B7
        JP M,SUB_1E72_15                 ; $1F56  FA 52 1F
        DEC DE                           ; $1F59  1B
        DEC DE                           ; $1F5A  1B
        DEC DE                           ; $1F5B  1B
        LD A,(SUB_0B2A_5)                ; $1F5C  3A 37 0B
        ADD A,L                          ; $1F5F  85
        LD B,A                           ; $1F60  47
        LD A,(SUB_0C03_2)                ; $1F61  3A 1E 0C
        LD C,A                           ; $1F64  4F
        ADD A,B                          ; $1F65  80
        CP $64                           ; $1F66  FE 64
        JP NC,SUB_14E4_2                 ; $1F68  D2 EB 14
        PUSH AF                          ; $1F6B  F5
        LD A,L                           ; $1F6C  7D
        LD B,$00                         ; $1F6D  06 00
        LD HL,SUB_0C03_3                 ; $1F6F  21 20 0C
        ADD HL,BC                        ; $1F72  09
        LD C,A                           ; $1F73  4F
        CALL SUB_202E                    ; $1F74  CD 2E 20
        LD BC,SUB_1E72_13                ; $1F77  01 38 1F
        PUSH BC                          ; $1F7A  C5
        PUSH BC                          ; $1F7B  C5
        JP SUB_15CF_10                   ; $1F7C  C3 17 16
SUB_1E72_16:
        LD HL,(SUB_0B2A_37)              ; $1F7F  2A 8C 0B
        CALL SUB_13E4                    ; $1F82  CD E4 13
        PUSH HL                          ; $1F85  E5
        LD HL,(SUB_0B2A_20)              ; $1F86  2A 6D 0B
        CALL SUB_45A3                    ; $1F89  CD A3 45
        ADD HL,HL                        ; $1F8C  29
SUB_1E72_17:
        LD A,$D5                         ; $1F8D  3E D5
        LD (SUB_0B2A_20),HL              ; $1F8F  22 6D 0B
        LD A,(SUB_0B2A_46)               ; $1F92  3A B6 0B
        ADD A,$04                        ; $1F95  C6 04
        PUSH AF                          ; $1F97  F5
        RRCA                             ; $1F98  0F
        LD C,A                           ; $1F99  4F
        CALL SUB_449F                    ; $1F9A  CD 9F 44
        POP AF                           ; $1F9D  F1
        LD C,A                           ; $1F9E  4F
        CPL                              ; $1F9F  2F
        INC A                            ; $1FA0  3C
        LD L,A                           ; $1FA1  6F
        LD H,$FF                         ; $1FA2  26 FF
        ADD HL,SP                        ; $1FA4  39
        LD SP,HL                         ; $1FA5  F9
        PUSH HL                          ; $1FA6  E5
        LD DE,SUB_0B2A_45                ; $1FA7  11 B4 0B
        CALL SUB_202E                    ; $1FAA  CD 2E 20
        POP HL                           ; $1FAD  E1
        LD (SUB_0B2A_45),HL              ; $1FAE  22 B4 0B
        LD HL,(SUB_0C03_2)               ; $1FB1  2A 1E 0C
        LD (SUB_0B2A_46),HL              ; $1FB4  22 B6 0B
        LD B,H                           ; $1FB7  44
        LD C,L                           ; $1FB8  4D
        LD HL,SUB_0B2A_47                ; $1FB9  21 B8 0B
        LD DE,SUB_0C03_3                 ; $1FBC  11 20 0C
        CALL SUB_202E                    ; $1FBF  CD 2E 20
        LD H,A                           ; $1FC2  67
        LD L,A                           ; $1FC3  6F
        LD (SUB_0C03_2),HL               ; $1FC4  22 1E 0C
        LD HL,(SUB_0C4B_6)               ; $1FC7  2A 8A 0C
        INC HL                           ; $1FCA  23
        LD (SUB_0C4B_6),HL               ; $1FCB  22 8A 0C
        LD A,H                           ; $1FCE  7C
        OR L                             ; $1FCF  B5
        LD (SUB_0C4B_4),A                ; $1FD0  32 87 0C
        LD HL,(SUB_0B2A_20)              ; $1FD3  2A 6D 0B
        CALL SUB_1A85                    ; $1FD6  CD 85 1A
        DEC HL                           ; $1FD9  2B
        CALL SUB_13E4                    ; $1FDA  CD E4 13
        JP NZ,SUB_0D20_20                ; $1FDD  C2 92 0D
SUB_1E72_18:
        CALL SUB_1DE3                    ; $1FE0  CD E3 1D
        JR NZ,SUB_1E72_19                ; $1FE3  20 11
        LD DE,SUB_0B2A_17                ; $1FE5  11 68 0B
        LD HL,(SUB_0C98_4)               ; $1FE8  2A D4 0C
        CALL SUB_459D                    ; $1FEB  CD 9D 45
        JR C,SUB_1E72_19                 ; $1FEE  38 06
        CALL SUB_4844                    ; $1FF0  CD 44 48
        CALL SUB_486C_7+1                ; $1FF3  CD 9C 48
SUB_1E72_19:
        LD HL,(SUB_0B2A_45)              ; $1FF6  2A B4 0B
        LD D,H                           ; $1FF9  54
        LD E,L                           ; $1FFA  5D
        INC HL                           ; $1FFB  23
        INC HL                           ; $1FFC  23
        LD C,(HL)                        ; $1FFD  4E
        INC HL                           ; $1FFE  23
        LD B,(HL)                        ; $1FFF  46
SUB_1E72_20:
        INC BC                           ; $2000  03
SUB_1E72_21:
        INC BC                           ; $2001  03
        INC BC                           ; $2002  03
        INC BC                           ; $2003  03
        LD HL,SUB_0B2A_45                ; $2004  21 B4 0B
        CALL SUB_202E                    ; $2007  CD 2E 20
        EX DE,HL                         ; $200A  EB
        LD SP,HL                         ; $200B  F9
SUB_1E72_22:
        LD HL,(SUB_0C4B_6)               ; $200C  2A 8A 0C
        DEC HL                           ; $200F  2B
        LD (SUB_0C4B_6),HL               ; $2010  22 8A 0C
        LD A,H                           ; $2013  7C
        OR L                             ; $2014  B5
        LD (SUB_0C4B_4),A                ; $2015  32 87 0C
        POP HL                           ; $2018  E1
        POP AF                           ; $2019  F1
SUB_201A:
        PUSH HL                          ; $201A  E5
        AND $07                          ; $201B  E6 07
SUB_201A_1:
        LD HL,L_04F9                     ; $201D  21 F9 04
        LD C,A                           ; $2020  4F
        LD B,$00                         ; $2021  06 00
        ADD HL,BC                        ; $2023  09
        CALL SUB_1DAC                    ; $2024  CD AC 1D
SUB_201A_2:
        POP HL                           ; $2027  E1
        RET                              ; $2028  C9
SUB_201A_3:
        LD A,(DE)                        ; $2029  1A
        LD (HL),A                        ; $202A  77
        INC HL                           ; $202B  23
        INC DE                           ; $202C  13
        DEC BC                           ; $202D  0B
SUB_202E:
        LD A,B                           ; $202E  78
        OR C                             ; $202F  B1
        JR NZ,SUB_201A_3                 ; $2030  20 F7
        RET                              ; $2032  C9
SUB_2033:
        PUSH HL                          ; $2033  E5
        LD HL,(SUB_0752_43)              ; $2034  2A 67 08
        INC HL                           ; $2037  23
        LD A,H                           ; $2038  7C
        OR L                             ; $2039  B5
        POP HL                           ; $203A  E1
        RET NZ                           ; $203B  C0
        LD E,$0C                         ; $203C  1E 0C
SUB_2033_1:
        JP SUB_0D20_28                   ; $203E  C3 AC 0D
SUB_2041:
        CALL SUB_45A3                    ; $2041  CD A3 45
        JP PO,$803E                      ; $2044  E2 3E 80
        LD (SUB_0B2A_23),A               ; $2047  32 75 0B
        OR (HL)                          ; $204A  B6
        LD C,A                           ; $204B  4F
        JP SUB_3BB3_1                    ; $204C  C3 B8 3B
SUB_2041_1:
        CP $7E                           ; $204F  FE 7E
        JP NZ,SUB_0D20_20                ; $2051  C2 92 0D
        INC HL                           ; $2054  23
        LD A,(HL)                        ; $2055  7E
        CP $83                           ; $2056  FE 83
        JP NZ,SUB_0D20_20                ; $2058  C2 92 0D
        INC HL                           ; $205B  23
        JP SUB_4B4F_9                    ; $205C  C3 E1 4B
        DEFB    $C3                                              ; $205F
        DEFW    SUB_0D20_20              ; $2060
        DEFB    $FE,$9B                                          ; $2062
        DEFW    SUB_101B_10              ; $2064
        DEFB    $CD                                              ; $2066
        DEFW    SUB_13E4                 ; $2067
        DEFB    $CD                                              ; $2069
        DEFW    SUB_20B2                 ; $206A
        DEFW    SUB_5D26_3               ; $206C
        DEFB    $08,$5F,$CD                                      ; $206E
        DEFW    SUB_2096                 ; $2071
        DEFB    $32                                              ; $2073
        DEFW    SUB_0752_34+2            ; $2074
        DEFB    $C9                                              ; $2076
        DEFW    SUB_2CF8_1               ; $2077
        DEFW    SUB_1128                 ; $2079
        DEFB    $CD                                              ; $207B
        DEFW    SUB_20B2                 ; $207C
SUB_207E:
        LD (SUB_0752_36),A               ; $207E  32 5E 08
        LD E,A                           ; $2081  5F
        CALL SUB_2096                    ; $2082  CD 96 20
        LD (SUB_0752_37+1),A             ; $2085  32 60 08
        LD A,(HL)                        ; $2088  7E
        CP $2C                           ; $2089  FE 2C
        RET NZ                           ; $208B  C0
        CALL SUB_13E4                    ; $208C  CD E4 13
        CALL SUB_20B2                    ; $208F  CD B2 20
        LD (SUB_0752_37),A               ; $2092  32 5F 08
        RET                              ; $2095  C9
SUB_2096:
        SUB $0E                          ; $2096  D6 0E
        JR NC,SUB_2096                   ; $2098  30 FC
        ADD A,$1C                        ; $209A  C6 1C
        CPL                              ; $209C  2F
        INC A                            ; $209D  3C
SUB_2096_1:
        ADD A,E                          ; $209E  83
        RET                              ; $209F  C9
SUB_20A0:
        CALL SUB_13E4                    ; $20A0  CD E4 13
SUB_20A3:
        CALL SUB_1A8C_1+1                ; $20A3  CD 90 1A
SUB_20A6:
        PUSH HL                          ; $20A6  E5
        CALL SUB_2BF4                    ; $20A7  CD F4 2B
        EX DE,HL                         ; $20AA  EB
        POP HL                           ; $20AB  E1
        LD A,D                           ; $20AC  7A
        OR A                             ; $20AD  B7
        RET                              ; $20AE  C9
SUB_20AF:
        CALL SUB_13E4                    ; $20AF  CD E4 13
SUB_20B2:
        CALL SUB_1A8C_1+1                ; $20B2  CD 90 1A
SUB_20B5:
        CALL SUB_20A6                    ; $20B5  CD A6 20
        JP NZ,SUB_14E4_2                 ; $20B8  C2 EB 14
SUB_20B5_1:
        DEC HL                           ; $20BB  2B
        CALL SUB_13E4                    ; $20BC  CD E4 13
        LD A,E                           ; $20BF  7B
        RET                              ; $20C0  C9
SUB_20B5_2:
        LD A,$01                         ; $20C1  3E 01
        LD (SUB_0752_34+1),A             ; $20C3  32 5B 08
        POP BC                           ; $20C6  C1
        CALL SUB_0F84                    ; $20C7  CD 84 0F
        PUSH BC                          ; $20CA  C5
        CALL SUB_5E2A                    ; $20CB  CD 2A 5E
SUB_20B5_3:
        LD HL,$FFFF                      ; $20CE  21 FF FF
        LD (SUB_0752_43),HL              ; $20D1  22 67 08
        POP HL                           ; $20D4  E1
        POP DE                           ; $20D5  D1
        LD C,(HL)                        ; $20D6  4E
        INC HL                           ; $20D7  23
        LD B,(HL)                        ; $20D8  46
        INC HL                           ; $20D9  23
        LD A,B                           ; $20DA  78
        OR C                             ; $20DB  B1
        JP Z,SUB_0D20_39                 ; $20DC  CA 46 0E
        PUSH HL                          ; $20DF  E5
        LD HL,(SUB_0752_40)              ; $20E0  2A 63 08
        LD A,H                           ; $20E3  7C
        OR L                             ; $20E4  B5
        POP HL                           ; $20E5  E1
        CALL Z,SUB_442C                  ; $20E6  CC 2C 44
        PUSH BC                          ; $20E9  C5
        LD C,(HL)                        ; $20EA  4E
        INC HL                           ; $20EB  23
        LD B,(HL)                        ; $20EC  46
        INC HL                           ; $20ED  23
        PUSH BC                          ; $20EE  C5
        EX (SP),HL                       ; $20EF  E3
        EX DE,HL                         ; $20F0  EB
        CALL SUB_459D                    ; $20F1  CD 9D 45
        POP BC                           ; $20F4  C1
SUB_20B5_4:
        JP C,SUB_0D20_38+1               ; $20F5  DA 45 0E
        EX (SP),HL                       ; $20F8  E3
        PUSH HL                          ; $20F9  E5
        PUSH BC                          ; $20FA  C5
        EX DE,HL                         ; $20FB  EB
        LD (SUB_0B2A_33),HL              ; $20FC  22 85 0B
        CALL SUB_3391                    ; $20FF  CD 91 33
        POP HL                           ; $2102  E1
SUB_20B5_5:
        LD A,(HL)                        ; $2103  7E
        CP $09                           ; $2104  FE 09
        JR Z,SUB_20B5_6                  ; $2106  28 05
        LD A,$20                         ; $2108  3E 20
        CALL SUB_4291                    ; $210A  CD 91 42
SUB_20B5_6:
        CALL SUB_2124                    ; $210D  CD 24 21
        LD HL,SUB_0925_12                ; $2110  21 31 0A
        CALL SUB_211B                    ; $2113  CD 1B 21
        CALL SUB_4406                    ; $2116  CD 06 44
        JR SUB_20B5_3                    ; $2119  18 B3
SUB_211B:
        LD A,(HL)                        ; $211B  7E
        OR A                             ; $211C  B7
        RET Z                            ; $211D  C8
        CALL SUB_447E                    ; $211E  CD 7E 44
SUB_211B_1:
        INC HL                           ; $2121  23
        JR SUB_211B                      ; $2122  18 F7
SUB_2124:
        LD BC,SUB_0925_12                ; $2124  01 31 0A
SUB_2124_1:
        LD D,$FF                         ; $2127  16 FF
        XOR A                            ; $2129  AF
        LD (L_0CB6),A                    ; $212A  32 B6 0C
        CALL SUB_5E2A                    ; $212D  CD 2A 5E
        JR SUB_2124_3                    ; $2130  18 04
SUB_2124_2:
        INC BC                           ; $2132  03
        INC HL                           ; $2133  23
        DEC D                            ; $2134  15
        RET Z                            ; $2135  C8
SUB_2124_3:
        LD A,(HL)                        ; $2136  7E
        OR A                             ; $2137  B7
        LD (BC),A                        ; $2138  02
SUB_2124_4:
        RET Z                            ; $2139  C8
        CP $0B                           ; $213A  FE 0B
        JR C,SUB_2124_6                  ; $213C  38 05
SUB_2124_5:
        CP $20                           ; $213E  FE 20
        LD E,A                           ; $2140  5F
        JR C,SUB_2124_7                  ; $2141  38 12
SUB_2124_6:
        OR A                             ; $2143  B7
        JP M,SUB_2124_12                 ; $2144  FA 76 21
        LD E,A                           ; $2147  5F
        CP $2E                           ; $2148  FE 2E
        JR Z,SUB_2124_7                  ; $214A  28 09
        CALL SUB_21FC                    ; $214C  CD FC 21
        JP NC,SUB_2124_7                 ; $214F  D2 55 21
        XOR A                            ; $2152  AF
        JR SUB_2124_10                   ; $2153  18 11
SUB_2124_7:
        LD A,(L_0CB6)                    ; $2155  3A B6 0C
        OR A                             ; $2158  B7
        JR Z,SUB_2124_9                  ; $2159  28 09
SUB_2124_8:
        INC A                            ; $215B  3C
        JR NZ,SUB_2124_9                 ; $215C  20 06
        LD A,$20                         ; $215E  3E 20
        LD (BC),A                        ; $2160  02
        INC BC                           ; $2161  03
        DEC D                            ; $2162  15
        RET Z                            ; $2163  C8
SUB_2124_9:
        LD A,$01                         ; $2164  3E 01
SUB_2124_10:
        LD (L_0CB6),A                    ; $2166  32 B6 0C
        LD A,E                           ; $2169  7B
        CP $0B                           ; $216A  FE 0B
        JR C,SUB_2124_11                 ; $216C  38 05
        CP $20                           ; $216E  FE 20
        JP C,SUB_21FC_2                  ; $2170  DA 07 22
SUB_2124_11:
        LD (BC),A                        ; $2173  02
        JR SUB_2124_2                    ; $2174  18 BC
SUB_2124_12:
        INC A                            ; $2176  3C
        LD A,(HL)                        ; $2177  7E
        JR NZ,SUB_2124_13                ; $2178  20 04
        INC HL                           ; $217A  23
        LD A,(HL)                        ; $217B  7E
        AND $7F                          ; $217C  E6 7F
SUB_2124_13:
        INC HL                           ; $217E  23
        CP $EA                           ; $217F  FE EA
        JR NZ,SUB_2124_14                ; $2181  20 08
        DEC BC                           ; $2183  0B
        DEC BC                           ; $2184  0B
        DEC BC                           ; $2185  0B
        DEC BC                           ; $2186  0B
        INC D                            ; $2187  14
        INC D                            ; $2188  14
        INC D                            ; $2189  14
        INC D                            ; $218A  14
SUB_2124_14:
        CP $9E                           ; $218B  FE 9E
        CALL Z,SUB_2CE3                  ; $218D  CC E3 2C
        PUSH HL                          ; $2190  E5
        PUSH BC                          ; $2191  C5
        PUSH DE                          ; $2192  D5
        LD HL,SUB_0100_27                ; $2193  21 51 02
        LD B,A                           ; $2196  47
        LD C,$40                         ; $2197  0E 40
SUB_2124_15:
        INC C                            ; $2199  0C
SUB_2124_16:
        INC HL                           ; $219A  23
        LD D,H                           ; $219B  54
        LD E,L                           ; $219C  5D
SUB_2124_17:
        LD A,(HL)                        ; $219D  7E
        OR A                             ; $219E  B7
        JR Z,SUB_2124_15                 ; $219F  28 F8
        INC HL                           ; $21A1  23
        JP P,SUB_2124_17                 ; $21A2  F2 9D 21
        LD A,(HL)                        ; $21A5  7E
        CP B                             ; $21A6  B8
        JR NZ,SUB_2124_16                ; $21A7  20 F1
        EX DE,HL                         ; $21A9  EB
        CP $E1                           ; $21AA  FE E1
        JR Z,SUB_2124_18                 ; $21AC  28 02
        CP $E2                           ; $21AE  FE E2
SUB_2124_18:
        LD A,C                           ; $21B0  79
        POP DE                           ; $21B1  D1
        POP BC                           ; $21B2  C1
        LD E,A                           ; $21B3  5F
        JR NZ,SUB_2124_19                ; $21B4  20 0B
        LD A,(L_0CB6)                    ; $21B6  3A B6 0C
        OR A                             ; $21B9  B7
        LD A,$00                         ; $21BA  3E 00
        LD (L_0CB6),A                    ; $21BC  32 B6 0C
        JR SUB_2124_23                   ; $21BF  18 13
SUB_2124_19:
        CP $5B                           ; $21C1  FE 5B
        JR NZ,SUB_2124_21                ; $21C3  20 06
        XOR A                            ; $21C5  AF
        LD (L_0CB6),A                    ; $21C6  32 B6 0C
SUB_2124_20:
        JR SUB_2124_25                   ; $21C9  18 16
SUB_2124_21:
        LD A,(L_0CB6)                    ; $21CB  3A B6 0C
        OR A                             ; $21CE  B7
        LD A,$FF                         ; $21CF  3E FF
SUB_2124_22:
        LD (L_0CB6),A                    ; $21D1  32 B6 0C
SUB_2124_23:
        JR Z,SUB_2124_24                 ; $21D4  28 08
        LD A,$20                         ; $21D6  3E 20
        LD (BC),A                        ; $21D8  02
        INC BC                           ; $21D9  03
        DEC D                            ; $21DA  15
        JP Z,SUB_48D6_2                  ; $21DB  CA F1 48
SUB_2124_24:
        LD A,E                           ; $21DE  7B
        JR SUB_2124_26                   ; $21DF  18 03
SUB_2124_25:
        LD A,(HL)                        ; $21E1  7E
        INC HL                           ; $21E2  23
        LD E,A                           ; $21E3  5F
SUB_2124_26:
        AND $7F                          ; $21E4  E6 7F
        LD (BC),A                        ; $21E6  02
        INC BC                           ; $21E7  03
        DEC D                            ; $21E8  15
        JP Z,SUB_48D6_2                  ; $21E9  CA F1 48
        OR E                             ; $21EC  B3
        JP P,SUB_2124_25                 ; $21ED  F2 E1 21
        CP $A8                           ; $21F0  FE A8
        JR NZ,SUB_2124_27                ; $21F2  20 04
        XOR A                            ; $21F4  AF
        LD (L_0CB6),A                    ; $21F5  32 B6 0C
SUB_2124_27:
        POP HL                           ; $21F8  E1
        JP SUB_2124_3                    ; $21F9  C3 36 21
SUB_21FC:
        CALL SUB_46BF                    ; $21FC  CD BF 46
        RET NC                           ; $21FF  D0
SUB_21FC_1:
        CP $30                           ; $2200  FE 30
        RET C                            ; $2202  D8
        CP $3A                           ; $2203  FE 3A
        CCF                              ; $2205  3F
        RET                              ; $2206  C9
SUB_21FC_2:
        DEC HL                           ; $2207  2B
        CALL SUB_13E4                    ; $2208  CD E4 13
        PUSH DE                          ; $220B  D5
        PUSH BC                          ; $220C  C5
        PUSH AF                          ; $220D  F5
        CALL SUB_1460                    ; $220E  CD 60 14
        POP AF                           ; $2211  F1
        LD BC,SUB_21FC_5                 ; $2212  01 26 22
        PUSH BC                          ; $2215  C5
        CP $0B                           ; $2216  FE 0B
        JP Z,SUB_3809_7                  ; $2218  CA BC 38
        CP $0C                           ; $221B  FE 0C
        JP Z,SUB_3809_8+1                ; $221D  CA BF 38
SUB_21FC_3:
        LD HL,(SUB_0B2A_11)              ; $2220  2A 3E 0B
SUB_21FC_4:
        JP SUB_33A0                      ; $2223  C3 A0 33
SUB_21FC_5:
        POP BC                           ; $2226  C1
        POP DE                           ; $2227  D1
        LD A,(SUB_0B2A_9)                ; $2228  3A 3C 0B
        LD E,$4F                         ; $222B  1E 4F
        CP $0B                           ; $222D  FE 0B
        JR Z,SUB_21FC_6                  ; $222F  28 06
        CP $0C                           ; $2231  FE 0C
        LD E,$48                         ; $2233  1E 48
        JR NZ,SUB_21FC_7                 ; $2235  20 0B
SUB_21FC_6:
        LD A,$26                         ; $2237  3E 26
        LD (BC),A                        ; $2239  02
        INC BC                           ; $223A  03
        DEC D                            ; $223B  15
        RET Z                            ; $223C  C8
        LD A,E                           ; $223D  7B
        LD (BC),A                        ; $223E  02
        INC BC                           ; $223F  03
        DEC D                            ; $2240  15
        RET Z                            ; $2241  C8
SUB_21FC_7:
        LD A,(SUB_0B2A_10)               ; $2242  3A 3D 0B
        CP $04                           ; $2245  FE 04
        LD E,$00                         ; $2247  1E 00
        JR C,SUB_21FC_8                  ; $2249  38 06
        LD E,$21                         ; $224B  1E 21
        JR Z,SUB_21FC_8                  ; $224D  28 02
        LD E,$23                         ; $224F  1E 23
SUB_21FC_8:
        LD A,(HL)                        ; $2251  7E
        CP $20                           ; $2252  FE 20
        CALL Z,SUB_2B3D                  ; $2254  CC 3D 2B
SUB_21FC_9:
        LD A,(HL)                        ; $2257  7E
        INC HL                           ; $2258  23
        OR A                             ; $2259  B7
        JR Z,SUB_21FC_14                 ; $225A  28 20
        LD (BC),A                        ; $225C  02
SUB_21FC_10:
        INC BC                           ; $225D  03
        DEC D                            ; $225E  15
        RET Z                            ; $225F  C8
        LD A,(SUB_0B2A_10)               ; $2260  3A 3D 0B
        CP $04                           ; $2263  FE 04
        JR C,SUB_21FC_9                  ; $2265  38 F0
        DEC BC                           ; $2267  0B
        LD A,(BC)                        ; $2268  0A
SUB_21FC_11:
        INC BC                           ; $2269  03
        JR NZ,SUB_21FC_12                ; $226A  20 04
        CP $2E                           ; $226C  FE 2E
        JR Z,SUB_21FC_13                 ; $226E  28 08
SUB_21FC_12:
        CP $44                           ; $2270  FE 44
        JR Z,SUB_21FC_13                 ; $2272  28 04
        CP $45                           ; $2274  FE 45
        JR NZ,SUB_21FC_9                 ; $2276  20 DF
SUB_21FC_13:
        LD E,$00                         ; $2278  1E 00
        JR SUB_21FC_9                    ; $227A  18 DB
SUB_21FC_14:
        LD A,E                           ; $227C  7B
        OR A                             ; $227D  B7
        JR Z,SUB_21FC_15                 ; $227E  28 04
        LD (BC),A                        ; $2280  02
        INC BC                           ; $2281  03
        DEC D                            ; $2282  15
        RET Z                            ; $2283  C8
SUB_21FC_15:
        LD HL,(SUB_0B2A_8)               ; $2284  2A 3A 0B
        JP SUB_2124_3                    ; $2287  C3 36 21
        DEFB    $CD                                              ; $228A
        DEFW    SUB_0F84                 ; $228B
        DEFB    $C5,$CD                                          ; $228D
        DEFW    SUB_2426                 ; $228F
        DEFB    $C1,$D1,$C5,$C5,$CD                              ; $2291
        DEFW    SUB_0FAB                 ; $2296
        DEFB    $30,$07                                          ; $2298
        DEFW    SUB_5D26_6               ; $229A
        DEFB    $E3,$E5,$CD                                      ; $229C
        DEFW    SUB_459D                 ; $229F
        DEFB    $D2                                              ; $22A1
        DEFW    SUB_14E4_2               ; $22A2
        DEFW    SUB_1506_2               ; $22A4
        DEFB    $0D,$CD                                          ; $22A6
        DEFW    SUB_48BE                 ; $22A8
        DEFW    SUB_2124_19              ; $22AA
        DEFW    SUB_0F28_3               ; $22AC
        DEFB    $E3                                              ; $22AE
SUB_22AF:
        EX DE,HL                         ; $22AF  EB
        LD HL,(SUB_0B2A_40)              ; $22B0  2A 92 0B
SUB_22AF_1:
        LD A,(DE)                        ; $22B3  1A
        LD (BC),A                        ; $22B4  02
        INC BC                           ; $22B5  03
        INC DE                           ; $22B6  13
        CALL SUB_459D                    ; $22B7  CD 9D 45
        JR NZ,SUB_22AF_1                 ; $22BA  20 F7
        LD H,B                           ; $22BC  60
        LD L,C                           ; $22BD  69
        LD (SUB_0B2A_40),HL              ; $22BE  22 92 0B
        RET                              ; $22C1  C9
SUB_22AF_2:
        CALL SUB_22E1                    ; $22C2  CD E1 22
        CALL SUB_5E21                    ; $22C5  CD 21 5E
        LD A,(HL)                        ; $22C8  7E
        JP SUB_1E4D                      ; $22C9  C3 4D 1E
        DEFB    $CD                                              ; $22CC
        DEFW    SUB_1A8C_1+1             ; $22CD
        DEFB    $E5,$CD                                          ; $22CF
        DEFW    SUB_22E1                 ; $22D1
        DEFB    $E3,$CD                                          ; $22D3
        DEFW    SUB_5E21                 ; $22D5
        DEFB    $CD                                              ; $22D7
        DEFW    SUB_45A3                 ; $22D8
        DEFB    $2C,$CD                                          ; $22DA
        DEFW    SUB_20B2                 ; $22DC
        DEFW    SUB_129A_3               ; $22DE
        DEFB    $C9                                              ; $22E0
SUB_22E1:
        LD BC,SUB_2BF4                   ; $22E1  01 F4 2B
        PUSH BC                          ; $22E4  C5
        CALL SUB_1DE3                    ; $22E5  CD E3 1D
        RET M                            ; $22E8  F8
        LD A,(SUB_0C98_6)                ; $22E9  3A D7 0C
        CP $90                           ; $22EC  FE 90
        RET NZ                           ; $22EE  C0
        LD A,(SUB_0C98_5)                ; $22EF  3A D6 0C
        OR A                             ; $22F2  B7
        RET M                            ; $22F3  F8
        LD BC,$9180                      ; $22F4  01 80 91
        LD DE,$0000                      ; $22F7  11 00 00
        JP SUB_2824                      ; $22FA  C3 24 28
SUB_22E1_1:
        LD BC,$000A                      ; $22FD  01 0A 00
SUB_22E1_2:
        PUSH BC                          ; $2300  C5
SUB_22E1_3:
        LD D,B                           ; $2301  50
        LD E,B                           ; $2302  58
        JR Z,SUB_22E1_8                  ; $2303  28 2A
        CP $2C                           ; $2305  FE 2C
        JR Z,SUB_22E1_5                  ; $2307  28 09
SUB_22E1_4:
        PUSH DE                          ; $2309  D5
        CALL SUB_14F0                    ; $230A  CD F0 14
        LD B,D                           ; $230D  42
        LD C,E                           ; $230E  4B
        POP DE                           ; $230F  D1
        JR Z,SUB_22E1_8                  ; $2310  28 1D
SUB_22E1_5:
        CALL SUB_45A3                    ; $2312  CD A3 45
        INC L                            ; $2315  2C
        CALL SUB_14F0                    ; $2316  CD F0 14
SUB_22E1_6:
        JR Z,SUB_22E1_8                  ; $2319  28 14
        POP AF                           ; $231B  F1
        CALL SUB_45A3                    ; $231C  CD A3 45
        INC L                            ; $231F  2C
        PUSH DE                          ; $2320  D5
        CALL SUB_14FB                    ; $2321  CD FB 14
        JP NZ,SUB_0D20_20                ; $2324  C2 92 0D
        LD A,D                           ; $2327  7A
        OR E                             ; $2328  B3
SUB_22E1_7:
        JP Z,SUB_14E4_2                  ; $2329  CA EB 14
        EX DE,HL                         ; $232C  EB
        EX (SP),HL                       ; $232D  E3
        EX DE,HL                         ; $232E  EB
SUB_22E1_8:
        PUSH BC                          ; $232F  C5
        CALL SUB_0FAB                    ; $2330  CD AB 0F
        POP DE                           ; $2333  D1
SUB_22E1_9:
        PUSH DE                          ; $2334  D5
        PUSH BC                          ; $2335  C5
        CALL SUB_0FAB                    ; $2336  CD AB 0F
        LD H,B                           ; $2339  60
        LD L,C                           ; $233A  69
        POP DE                           ; $233B  D1
SUB_22E1_10:
        CALL SUB_459D                    ; $233C  CD 9D 45
        EX DE,HL                         ; $233F  EB
        JP C,SUB_14E4_2                  ; $2340  DA EB 14
        POP DE                           ; $2343  D1
        POP BC                           ; $2344  C1
        POP AF                           ; $2345  F1
        PUSH HL                          ; $2346  E5
        PUSH DE                          ; $2347  D5
        JR SUB_22E1_14                   ; $2348  18 10
SUB_22E1_11:
        ADD HL,BC                        ; $234A  09
        JP C,SUB_14E4_2                  ; $234B  DA EB 14
SUB_22E1_12:
        EX DE,HL                         ; $234E  EB
        PUSH HL                          ; $234F  E5
        LD HL,$FFF9                      ; $2350  21 F9 FF
        CALL SUB_459D                    ; $2353  CD 9D 45
SUB_22E1_13:
        POP HL                           ; $2356  E1
        JP C,SUB_14E4_2                  ; $2357  DA EB 14
SUB_22E1_14:
        PUSH DE                          ; $235A  D5
        LD E,(HL)                        ; $235B  5E
        LD A,E                           ; $235C  7B
        INC HL                           ; $235D  23
SUB_22E1_15:
        LD D,(HL)                        ; $235E  56
SUB_22E1_16:
        OR D                             ; $235F  B2
        EX DE,HL                         ; $2360  EB
        POP DE                           ; $2361  D1
        JR Z,SUB_22E1_17                 ; $2362  28 07
        LD A,(HL)                        ; $2364  7E
        INC HL                           ; $2365  23
        OR (HL)                          ; $2366  B6
        DEC HL                           ; $2367  2B
        EX DE,HL                         ; $2368  EB
        JR NZ,SUB_22E1_11                ; $2369  20 DF
SUB_22E1_17:
        PUSH BC                          ; $236B  C5
        DEFB    $CD,$8C                                          ; $236C
        DEFB    $23,$C1,$D1,$E1,$D5,$5E,$7B,$23,$56,$B2,$28,$0D  ; $236E  "#AQaU^{#V2("
        DEFB    $EB,$E3                                          ; $237A
        DEFW    SUB_22E1_24              ; $237C
        DEFB    $73,$23,$72                                      ; $237E
        DEFW    SUB_0925_5               ; $2381
        DEFB    $EB,$E1,$18,$EB                                  ; $2383
        DEFW    SUB_44F5_1               ; $2387
        DEFB    $0E,$C5,$FE,$F6                                  ; $2389
SUB_22E1_18:
        XOR A                            ; $238D  AF
        LD (SUB_0B2A_26),A               ; $238E  32 79 0B
        LD HL,(SUB_0752_44)              ; $2391  2A 69 08
        DEC HL                           ; $2394  2B
SUB_22E1_19:
        INC HL                           ; $2395  23
        LD A,(HL)                        ; $2396  7E
        INC HL                           ; $2397  23
        OR (HL)                          ; $2398  B6
        RET Z                            ; $2399  C8
        INC HL                           ; $239A  23
        LD E,(HL)                        ; $239B  5E
        INC HL                           ; $239C  23
        LD D,(HL)                        ; $239D  56
SUB_22E1_20:
        CALL SUB_13E4                    ; $239E  CD E4 13
SUB_22E1_21:
        OR A                             ; $23A1  B7
        JR Z,SUB_22E1_19                 ; $23A2  28 F1
        LD C,A                           ; $23A4  4F
        LD A,(SUB_0B2A_26)               ; $23A5  3A 79 0B
        OR A                             ; $23A8  B7
        LD A,C                           ; $23A9  79
        JR Z,SUB_22E1_27                 ; $23AA  28 57
        CP $A4                           ; $23AC  FE A4
        JR NZ,SUB_22E1_22                ; $23AE  20 18
        CALL SUB_13E4                    ; $23B0  CD E4 13
        CP $89                           ; $23B3  FE 89
        JR NZ,SUB_22E1_21                ; $23B5  20 EA
        CALL SUB_13E4                    ; $23B7  CD E4 13
        CP $0E                           ; $23BA  FE 0E
        JR NZ,SUB_22E1_21                ; $23BC  20 E3
        PUSH DE                          ; $23BE  D5
        CALL SUB_1506                    ; $23BF  CD 06 15
        LD A,D                           ; $23C2  7A
        OR E                             ; $23C3  B3
        JR NZ,SUB_22E1_23                ; $23C4  20 0A
        JR SUB_22E1_26                   ; $23C6  18 27
SUB_22E1_22:
        CP $0E                           ; $23C8  FE 0E
        JR NZ,SUB_22E1_20                ; $23CA  20 D2
        PUSH DE                          ; $23CC  D5
        CALL SUB_1506                    ; $23CD  CD 06 15
SUB_22E1_23:
        PUSH HL                          ; $23D0  E5
        CALL SUB_0FAB                    ; $23D1  CD AB 0F
        DEC BC                           ; $23D4  0B
        LD A,$0D                         ; $23D5  3E 0D
        JR C,SUB_22E1_28                 ; $23D7  38 3D
        CALL SUB_43F9                    ; $23D9  CD F9 43
        LD HL,L_23F3                     ; $23DC  21 F3 23
        PUSH DE                          ; $23DF  D5
        CALL SUB_48BE                    ; $23E0  CD BE 48
        POP HL                           ; $23E3  E1
        CALL SUB_3391                    ; $23E4  CD 91 33
        POP BC                           ; $23E7  C1
        POP HL                           ; $23E8  E1
        PUSH HL                          ; $23E9  E5
        PUSH BC                          ; $23EA  C5
SUB_22E1_24:
        CALL SUB_3389                    ; $23EB  CD 89 33
SUB_22E1_25:
        POP HL                           ; $23EE  E1
SUB_22E1_26:
        POP DE                           ; $23EF  D1
        DEC HL                           ; $23F0  2B
        JR SUB_22E1_20                   ; $23F1  18 AB
L_23F3:
        DEFB    "Undef"    ; $23F3  string
L_23F8:
        DEFB    "ined lin"    ; $23F8  string
L_2400:
        DEFB    $65,$20,$00                                      ; $2400
SUB_22E1_27:
        CP $0D                           ; $2403  FE 0D
        JP NZ,SUB_22E1_20                ; $2405  C2 9E 23
        PUSH DE                          ; $2408  D5
        CALL SUB_1506                    ; $2409  CD 06 15
        PUSH HL                          ; $240C  E5
        EX DE,HL                         ; $240D  EB
        INC HL                           ; $240E  23
        INC HL                           ; $240F  23
        INC HL                           ; $2410  23
        LD C,(HL)                        ; $2411  4E
        INC HL                           ; $2412  23
        LD B,(HL)                        ; $2413  46
        LD A,$0E                         ; $2414  3E 0E
SUB_22E1_28:
        LD HL,SUB_22E1_25                ; $2416  21 EE 23
        PUSH HL                          ; $2419  E5
        LD HL,(SUB_0B2A_8)               ; $241A  2A 3A 0B
SUB_241D:
        PUSH HL                          ; $241D  E5
        DEC HL                           ; $241E  2B
        LD (HL),B                        ; $241F  70
        DEC HL                           ; $2420  2B
        LD (HL),C                        ; $2421  71
        DEC HL                           ; $2422  2B
        LD (HL),A                        ; $2423  77
        POP HL                           ; $2424  E1
        RET                              ; $2425  C9
SUB_2426:
        LD A,(SUB_0B2A_26)               ; $2426  3A 79 0B
        OR A                             ; $2429  B7
        RET Z                            ; $242A  C8
SUB_242B:
        JP SUB_22E1_18                   ; $242B  C3 8D 23
SUB_242B_1:
        CALL SUB_45A3                    ; $242E  CD A3 45
        LD B,D                           ; $2431  42
        CALL SUB_45A3                    ; $2432  CD A3 45
        LD B,C                           ; $2435  41
        CALL SUB_45A3                    ; $2436  CD A3 45
        LD D,E                           ; $2439  53
        CALL SUB_45A3                    ; $243A  CD A3 45
        LD B,L                           ; $243D  45
        LD A,(SUB_0C4B_13)               ; $243E  3A 97 0C
        OR A                             ; $2441  B7
        JP NZ,SUB_0D20_23+1              ; $2442  C2 9B 0D
        PUSH HL                          ; $2445  E5
        LD HL,(SUB_0B2A_41)              ; $2446  2A 94 0B
        EX DE,HL                         ; $2449  EB
        LD HL,(SUB_0B2A_42)              ; $244A  2A 96 0B
        CALL SUB_459D                    ; $244D  CD 9D 45
        JP NZ,SUB_0D20_23+1              ; $2450  C2 9B 0D
        POP HL                           ; $2453  E1
        LD A,(HL)                        ; $2454  7E
        SUB $30                          ; $2455  D6 30
        JP C,SUB_0D20_20                 ; $2457  DA 92 0D
        CP $02                           ; $245A  FE 02
        JP NC,SUB_0D20_20                ; $245C  D2 92 0D
        LD (SUB_0C4B_12),A               ; $245F  32 96 0C
        INC A                            ; $2462  3C
        LD (SUB_0C4B_13),A               ; $2463  32 97 0C
        CALL SUB_13E4                    ; $2466  CD E4 13
        RET                              ; $2469  C9
SUB_246A:
        LD A,(HL)                        ; $246A  7E
        OR A                             ; $246B  B7
        RET Z                            ; $246C  C8
        CALL SUB_2474                    ; $246D  CD 74 24
        INC HL                           ; $2470  23
        JP SUB_246A                      ; $2471  C3 6A 24
SUB_2474:
        PUSH AF                          ; $2474  F5
        JP SUB_4300_2                    ; $2475  C3 0F 43
SUB_2474_1:
        JR Z,SUB_2474_2                  ; $2478  28 09
        CALL SUB_1A8C_1+1                ; $247A  CD 90 1A
        PUSH HL                          ; $247D  E5
        CALL SUB_2BF4                    ; $247E  CD F4 2B
        JR SUB_2474_4                    ; $2481  18 1B
SUB_2474_2:
        PUSH HL                          ; $2483  E5
SUB_2474_3:
        LD HL,L_24A6                     ; $2484  21 A6 24
        CALL SUB_48BE                    ; $2487  CD BE 48
        CALL SUB_4C87                    ; $248A  CD 87 4C
        POP DE                           ; $248D  D1
        JP C,SUB_45B5_8+1                ; $248E  DA E4 45
        PUSH DE                          ; $2491  D5
        INC HL                           ; $2492  23
        LD A,(HL)                        ; $2493  7E
        CALL SUB_311E_1+1                ; $2494  CD 25 31
        LD A,(HL)                        ; $2497  7E
        OR A                             ; $2498  B7
        JR NZ,SUB_2474_3                 ; $2499  20 E9
        CALL SUB_2BF4                    ; $249B  CD F4 2B
SUB_2474_4:
        LD (L_3AA3),HL                   ; $249E  22 A3 3A
        CALL SUB_3A0A                    ; $24A1  CD 0A 3A
        POP HL                           ; $24A4  E1
        RET                              ; $24A5  C9
L_24A6:
        DEFB    "Random number seed (-32768-"    ; $24A6  string
        DEFB    $08                                              ; $24C1
        DEFB    " to 32767)"    ; $24C2  string
        DEFB    $00    ; $24CC  terminator
SUB_24CD:
        LD C,$1D                         ; $24CD  0E 1D
        JR SUB_24D1_1                    ; $24CF  18 02
SUB_24D1:
        LD C,$1A                         ; $24D1  0E 1A
SUB_24D1_1:
        LD B,$00                         ; $24D3  06 00
        EX DE,HL                         ; $24D5  EB
        LD HL,(SUB_0752_43)              ; $24D6  2A 67 08
        LD (SUB_0C4B_11),HL              ; $24D9  22 94 0C
        EX DE,HL                         ; $24DC  EB
SUB_24D1_2:
        INC B                            ; $24DD  04
SUB_24D1_3:
        DEC HL                           ; $24DE  2B
SUB_24D1_4:
        CALL SUB_13E4                    ; $24DF  CD E4 13
        JR Z,SUB_24D1_5                  ; $24E2  28 08
        CP $9E                           ; $24E4  FE 9E
        JR Z,SUB_24D1_6                  ; $24E6  28 18
        CP $DE                           ; $24E8  FE DE
        JR NZ,SUB_24D1_4                 ; $24EA  20 F3
SUB_24D1_5:
        OR A                             ; $24EC  B7
        JR NZ,SUB_24D1_6                 ; $24ED  20 11
        INC HL                           ; $24EF  23
        LD A,(HL)                        ; $24F0  7E
        INC HL                           ; $24F1  23
        OR (HL)                          ; $24F2  B6
        LD E,C                           ; $24F3  59
        JP Z,SUB_0D20_28                 ; $24F4  CA AC 0D
        INC HL                           ; $24F7  23
        LD E,(HL)                        ; $24F8  5E
        INC HL                           ; $24F9  23
        LD D,(HL)                        ; $24FA  56
        EX DE,HL                         ; $24FB  EB
        LD (SUB_0C4B_11),HL              ; $24FC  22 94 0C
        EX DE,HL                         ; $24FF  EB
SUB_24D1_6:
        CALL SUB_13E4                    ; $2500  CD E4 13
        LD A,C                           ; $2503  79
        CP $1A                           ; $2504  FE 1A
        LD A,(HL)                        ; $2506  7E
        JR Z,SUB_24D1_7                  ; $2507  28 0B
        CP $AF                           ; $2509  FE AF
        JR Z,SUB_24D1_2                  ; $250B  28 D0
        CP $B0                           ; $250D  FE B0
        JR NZ,SUB_24D1_3                 ; $250F  20 CD
        DJNZ SUB_24D1_3                  ; $2511  10 CB
        RET                              ; $2513  C9
SUB_24D1_7:
        CP $82                           ; $2514  FE 82
        JR Z,SUB_24D1_2                  ; $2516  28 C5
        CP $83                           ; $2518  FE 83
        JR NZ,SUB_24D1_3                 ; $251A  20 C2
SUB_24D1_8:
        DEC B                            ; $251C  05
        RET Z                            ; $251D  C8
        CALL SUB_13E4                    ; $251E  CD E4 13
        JR Z,SUB_24D1_5                  ; $2521  28 C9
        EX DE,HL                         ; $2523  EB
        LD HL,(SUB_0752_43)              ; $2524  2A 67 08
        PUSH HL                          ; $2527  E5
        LD HL,(SUB_0C4B_11)              ; $2528  2A 94 0C
        LD (SUB_0752_43),HL              ; $252B  22 67 08
        EX DE,HL                         ; $252E  EB
        PUSH BC                          ; $252F  C5
        CALL SUB_3BB3                    ; $2530  CD B3 3B
        POP BC                           ; $2533  C1
        DEC HL                           ; $2534  2B
        CALL SUB_13E4                    ; $2535  CD E4 13
        LD DE,SUB_24D1_5                 ; $2538  11 EC 24
        JR Z,SUB_24D1_9                  ; $253B  28 08
        CALL SUB_45A3                    ; $253D  CD A3 45
        INC L                            ; $2540  2C
        DEC HL                           ; $2541  2B
        LD DE,SUB_24D1_8                 ; $2542  11 1C 25
SUB_24D1_9:
        EX (SP),HL                       ; $2545  E3
        LD (SUB_0752_43),HL              ; $2546  22 67 08
        POP HL                           ; $2549  E1
        PUSH DE                          ; $254A  D5
        RET                              ; $254B  C9
SUB_24D1_10:
        PUSH AF                          ; $254C  F5
        LD A,(SUB_0C98_8)                ; $254D  3A D9 0C
        LD (SUB_0C98_9),A                ; $2550  32 DA 0C
        POP AF                           ; $2553  F1
SUB_2554:
        PUSH AF                          ; $2554  F5
        XOR A                            ; $2555  AF
        LD (SUB_0C98_8),A                ; $2556  32 D9 0C
        POP AF                           ; $2559  F1
        RET                              ; $255A  C9
SUB_2554_1:
        CALL SUB_25A9                    ; $255B  CD A9 25
        PUSH HL                          ; $255E  E5
        LD HL,SUB_0752_37                ; $255F  21 5F 08
SUB_2554_2:
        SUB (HL)                         ; $2562  96
        JP P,SUB_2554_2                  ; $2563  F2 62 25
        ADD A,(HL)                       ; $2566  86
        LD (SUB_0B2A_3),A                ; $2567  32 35 0B
SUB_2554_3:
        CALL SUB_256F                    ; $256A  CD 6F 25
        POP HL                           ; $256D  E1
        RET                              ; $256E  C9
SUB_256F:
        LD E,$07                         ; $256F  1E 07
        CALL SUB_2590                    ; $2571  CD 90 25
        LD HL,(SUB_0B2A_2)               ; $2574  2A 34 0B
        LD A,($F396)                     ; $2577  3A 96 F3
        OR A                             ; $257A  B7
        JP P,SUB_256F_1                  ; $257B  F2 83 25
        AND $7F                          ; $257E  E6 7F
        LD E,L                           ; $2580  5D
        LD L,H                           ; $2581  6C
        LD H,E                           ; $2582  63
SUB_256F_1:
        LD E,A                           ; $2583  5F
        ADD A,L                          ; $2584  85
        LD L,A                           ; $2585  6F
        LD A,E                           ; $2586  7B
        ADD A,H                          ; $2587  84
        PUSH HL                          ; $2588  E5
        CALL SUB_4382                    ; $2589  CD 82 43
        POP HL                           ; $258C  E1
        LD A,L                           ; $258D  7D
        JR SUB_2590_1                    ; $258E  18 16
SUB_2590:
        LD D,$00                         ; $2590  16 00
        LD HL,$F397                      ; $2592  21 97 F3
        ADD HL,DE                        ; $2595  19
        LD A,(HL)                        ; $2596  7E
        OR A                             ; $2597  B7
        RET Z                            ; $2598  C8
        JP P,SUB_2590_1                  ; $2599  F2 A6 25
        AND $7F                          ; $259C  E6 7F
        PUSH AF                          ; $259E  F5
        LD A,($F397)                     ; $259F  3A 97 F3
        CALL SUB_4382                    ; $25A2  CD 82 43
        POP AF                           ; $25A5  F1
SUB_2590_1:
        JP SUB_4382                      ; $25A6  C3 82 43
SUB_25A9:
        CALL SUB_20B2                    ; $25A9  CD B2 20
        OR A                             ; $25AC  B7
        JP Z,SUB_14E4_2                  ; $25AD  CA EB 14
        DEC A                            ; $25B0  3D
        RET                              ; $25B1  C9
        DEFB    $CD                                              ; $25B2
        DEFW    SUB_25A9                 ; $25B3
        DEFB    $E5                                              ; $25B5
        DEFW    SUB_5E21                 ; $25B6
        DEFB    $08,$96,$F2,$B9,$25,$86,$32                      ; $25B8
        DEFW    SUB_0B2A_2               ; $25BF
SUB_25A9_1:
        JR SUB_2554_3                    ; $25C1  18 A7
SUB_25C3:
        PUSH HL                          ; $25C3  E5
        LD HL,$0000                      ; $25C4  21 00 00
        LD (SUB_0B2A_2),HL               ; $25C7  22 34 0B
        POP HL                           ; $25CA  E1
        LD E,$01                         ; $25CB  1E 01
        LD BC,L_051E                     ; $25CD  01 1E 05
        LD BC,SUB_0100_30                ; $25D0  01 1E 04
        PUSH HL                          ; $25D3  E5
        CALL SUB_2590                    ; $25D4  CD 90 25
        POP HL                           ; $25D7  E1
        RET                              ; $25D8  C9
SUB_25D9:
        PUSH HL                          ; $25D9  E5
SUB_25D9_1:
        LD HL,$FB2F                      ; $25DA  21 2F FB
        CALL SUB_2602                    ; $25DD  CD 02 26
        LD A,(SUB_0752_37)               ; $25E0  3A 5F 08
        DEC A                            ; $25E3  3D
        LD H,A                           ; $25E4  67
        LD L,$00                         ; $25E5  2E 00
        LD (SUB_0B2A_2),HL               ; $25E7  22 34 0B
        LD A,($E051)                     ; $25EA  3A 51 E0
        LD A,($E054)                     ; $25ED  3A 54 E0
        LD A,(SUB_2803_3)                ; $25F0  3A 14 28
        OR A                             ; $25F3  B7
        JR Z,SUB_25D9_2                  ; $25F4  28 06
        LD HL,$FC58                      ; $25F6  21 58 FC
        CALL SUB_2602                    ; $25F9  CD 02 26
SUB_25D9_2:
        XOR A                            ; $25FC  AF
        LD (SUB_2803_3),A                ; $25FD  32 14 28
        JR SUB_25A9_1                    ; $2600  18 BF
SUB_2602:
        LD ($F3D0),HL                    ; $2602  22 D0 F3
SUB_2602_1:
        LD ($0000),A                     ; $2605  32 00 00
        RET                              ; $2608  C9
        DEFB    $3E                                              ; $2609
        DEFW    SUB_31F3_1               ; $260A
        DEFB    $30,$F0,$C4                                      ; $260C
        DEFW    SUB_20B2                 ; $260F
        DEFB    $FE                                              ; $2611
        DEFW    L_3002                   ; $2612
        DEFB    $63,$E5                                          ; $2614
        DEFW    SUB_3EDB_7               ; $2616
        DEFW    SUB_3212_1               ; $2618
        DEFB    $22,$F0,$21,$00,$17                              ; $261A
        DEFW    SUB_341F_1               ; $261F
        DEFB    $0B,$CD                                          ; $2621
        DEFW    SUB_256F                 ; $2623
        DEFB    $3A,$56,$E0,$F1                                  ; $2625
        DEFW    SUB_3289_19              ; $2629
        DEFB    $56,$E0,$CD,$E0                                  ; $262B
        DEFW    SUB_201A_2               ; $262F
        DEFW    SUB_22E1_4               ; $2631
        DEFB    $D5,$CD                                          ; $2633
        DEFW    SUB_20B2                 ; $2635
        DEFB    $CD,$64,$26,$D1                                  ; $2637
        DEFW    SUB_3EDB_2               ; $263B
        DEFW    SUB_3212_5               ; $263D
        DEFB    $2C                                              ; $263F
        DEFW    SUB_42EA_1+1             ; $2640
        DEFB    $AF,$32,$47,$F0,$78,$3D                          ; $2642
        DEFW    SUB_450F_3               ; $2648
        DEFB    $F0                                              ; $264A
        DEFW    SUB_57A0_2               ; $264B
        DEFB    $26,$10                                          ; $264D
        DEFW    SUB_3EDB_6               ; $264F
        DEFB    $FF,$32                                          ; $2651
        DEFW    SUB_2803_3               ; $2653
        DEFB    $E1                                              ; $2655
        DEFW    SUB_2124_20              ; $2656
        DEFB    $19,$F8,$C3                                      ; $2658
        DEFW    SUB_2602                 ; $265B
        DEFB    $CD                                              ; $265D
        DEFW    SUB_45A3                 ; $265E
        DEFB    $F0,$CD                                          ; $2660
        DEFW    SUB_20B2                 ; $2662
        DEFB    $7B,$FE,$10                                      ; $2664
        DEFW    SUB_0F28_2               ; $2667
        DEFB    $87,$87,$87,$87                                  ; $2669
        DEFW    SUB_3289_8               ; $266D
        DEFB    $30,$F0,$C9,$C5,$CD,$C1,$26,$C1,$B8,$D2          ; $266F
        DEFW    SUB_14E4_2               ; $2679
        DEFB    $BB,$DA                                          ; $267B
        DEFW    SUB_14E4_2               ; $267D
        DEFB    $57,$D5,$C5,$CD                                  ; $267F
        DEFW    SUB_45A3                 ; $2683
        DEFB    $41,$CD                                          ; $2685
        DEFW    SUB_45A3                 ; $2687
        DEFB    $54,$CD                                          ; $2689
        DEFW    SUB_20B2                 ; $268B
        DEFB    $C1                                              ; $268D
        DEFW    SUB_308B_4               ; $268E
        DEFB    $E7,$D1,$C9,$01,$30,$28,$CD,$72                  ; $2690
        DEFW    SUB_3212_4               ; $2698
        DEFB    $45,$F0,$7B,$32,$47,$F0                          ; $269A
        DEFW    SUB_3248_7               ; $26A0
        DEFB    $2C,$F0,$E5                                      ; $26A2
        DEFW    SUB_57A0_2               ; $26A5
        DEFB    $26,$E1,$C9                                      ; $26A7
        DEFW    L_2801                   ; $26AA
        DEFB    $30,$CD,$72                                      ; $26AC
        DEFW    SUB_3212_4               ; $26AF
        DEFB    $47,$F0,$7B                                      ; $26B1
        DEFW    SUB_450F_3               ; $26B4
        DEFB    $F0                                              ; $26B6
        DEFW    SUB_3248_7               ; $26B7
        DEFB    $2D,$F0,$E5                                      ; $26B9
        DEFW    SUB_2821                 ; $26BC
        DEFB    $F8,$18,$27,$CD                                  ; $26BE
        DEFW    SUB_20B2                 ; $26C2
        DEFB    $D5,$CD                                          ; $26C4
        DEFW    SUB_45A3                 ; $26C6
        DEFB    $2C,$CD                                          ; $26C8
        DEFW    SUB_20B2                 ; $26CA
        DEFB    $D1,$C9,$CD,$C1,$26                              ; $26CC
        DEFW    SUB_30F2_2               ; $26D1
        DEFB    $30,$A3                                          ; $26D3
        DEFW    SUB_450F_3               ; $26D5
        DEFB    $F0,$7B                                          ; $26D7
        DEFW    SUB_28F5_2               ; $26D9
        DEFB    $30                                              ; $26DB
        DEFW    SUB_3289_3               ; $26DC
        DEFB    $47,$F0,$C9,$CD,$CE,$26,$E5,$21,$00              ; $26DE  "GpIMN&e!"
        DEFB    $F8                                              ; $26E7
SUB_2602_2:
        CALL SUB_2602                    ; $26E8  CD 02 26
        POP HL                           ; $26EB  E1
        RET                              ; $26EC  C9
        DEFB    $CD                                              ; $26ED
        DEFW    SUB_20B5                 ; $26EE
        DEFB    $7B,$FE,$03,$30,$6F,$7A,$B7,$20,$6B,$E5,$21,$61,$E0,$19,$7E,$E1 ; $26F0
        DEFB    $17,$9F,$6F,$67,$C3                              ; $2700
        DEFW    SUB_2C55                 ; $2705
        DEFB    $3A                                              ; $2707
        DEFW    SUB_0B2A_3               ; $2708
        DEFB    $3C                                              ; $270A
SUB_2602_3:
        PUSH HL                          ; $270B  E5
SUB_2602_4:
        CALL SUB_1E4D                    ; $270C  CD 4D 1E
        POP HL                           ; $270F  E1
SUB_2602_5:
        RET                              ; $2710  C9
        DEFB    $CD,$C1,$26,$3C,$32,$45,$F0,$7B,$3C,$32,$46,$F0,$E5,$21,$24,$37 ; $2711  "MA&<2Ep{<2Fpe!$7Ch& "
        DEFB    $C3,$E8,$26,$A0,$00                              ; $2721
        DEFW    SUB_308B_3               ; $2726
        DEFB    $C0,$88,$D0,$04                                  ; $2728
        DEFW    SUB_45B5_2               ; $272C
        DEFB    $F0                                              ; $272E
        DEFW    SUB_1E72_22              ; $272F
        DEFB    $57,$FF,$CA,$D0,$F3                              ; $2731
        DEFW    SUB_463E_6               ; $2736
        DEFB    $D0,$EC,$F0,$EA,$60,$CD                          ; $2738
        DEFW    SUB_20A3                 ; $273E
        DEFB    $D5,$CD                                          ; $2740
        DEFW    SUB_45A3                 ; $2742
        DEFB    $2C,$CD                                          ; $2744
        DEFW    SUB_20B2                 ; $2746
        DEFB    $F5,$1E,$00                                      ; $2748
        DEFW    SUB_064E_16              ; $274B
SUB_2602_6:
        CALL SUB_45A3                    ; $274D  CD A3 45
        INC L                            ; $2750  2C
        CALL SUB_20B2                    ; $2751  CD B2 20
        POP AF                           ; $2754  F1
        LD D,A                           ; $2755  57
        EX (SP),HL                       ; $2756  E3
SUB_2602_7:
        LD A,(HL)                        ; $2757  7E
        XOR E                            ; $2758  AB
        AND D                            ; $2759  A2
        JR Z,SUB_2602_7                  ; $275A  28 FB
        POP HL                           ; $275C  E1
        RET                              ; $275D  C9
SUB_2602_8:
        CALL SUB_20B5                    ; $275E  CD B5 20
        LD A,E                           ; $2761  7B
        CP $04                           ; $2762  FE 04
        JP NC,SUB_14E4_2                 ; $2764  D2 EB 14
        LD ($F046),A                     ; $2767  32 46 F0
        PUSH HL                          ; $276A  E5
        LD HL,$FB1E                      ; $276B  21 1E FB
        CALL SUB_2602                    ; $276E  CD 02 26
        POP HL                           ; $2771  E1
        LD A,($F047)                     ; $2772  3A 47 F0
        JP SUB_1E4D                      ; $2775  C3 4D 1E
SUB_2602_9:
        CALL SUB_13E4                    ; $2778  CD E4 13
        CALL SUB_45A3                    ; $277B  CD A3 45
        JR Z,SUB_2602_6                  ; $277E  28 CD
        ADC A,$26                        ; $2780  CE 26
        CALL SUB_45A3                    ; $2782  CD A3 45
        ADD HL,HL                        ; $2785  29
        PUSH HL                          ; $2786  E5
        LD HL,$F871                      ; $2787  21 71 F8
        CALL SUB_2602                    ; $278A  CD 02 26
        LD A,($F045)                     ; $278D  3A 45 F0
        JP SUB_2602_4                    ; $2790  C3 0C 27
SUB_2602_10:
        CALL SUB_13E4                    ; $2793  CD E4 13
        LD A,($F030)                     ; $2796  3A 30 F0
        AND $0F                          ; $2799  E6 0F
        JP SUB_2602_3                    ; $279B  C3 0B 27
SUB_2602_11:
        LD HL,$F045                      ; $279E  21 45 F0
        XOR A                            ; $27A1  AF
        LD (HL),A                        ; $27A2  77
        INC HL                           ; $27A3  23
        LD (HL),A                        ; $27A4  77
        INC HL                           ; $27A5  23
        LD (HL),A                        ; $27A6  77
        POP HL                           ; $27A7  E1
        CALL SUB_13E5                    ; $27A8  CD E5 13
        JR Z,SUB_2602_17                 ; $27AB  28 2C
        CALL SUB_45A3                    ; $27AD  CD A3 45
        JR Z,SUB_2602_13+1               ; $27B0  28 11
        LD B,L                           ; $27B2  45
        RET P                            ; $27B3  F0
        LD B,$03                         ; $27B4  06 03
SUB_2602_12:
        LD A,(HL)                        ; $27B6  7E
        CP $29                           ; $27B7  FE 29
        JR Z,SUB_2602_16                 ; $27B9  28 1A
        CP $2C                           ; $27BB  FE 2C
        JR NZ,SUB_2602_14                ; $27BD  20 05
        CALL SUB_13E4                    ; $27BF  CD E4 13
SUB_2602_13:
        JR SUB_2602_15                   ; $27C2  18 0F
SUB_2602_14:
        PUSH BC                          ; $27C4  C5
        PUSH DE                          ; $27C5  D5
        CALL SUB_20B2                    ; $27C6  CD B2 20
        POP DE                           ; $27C9  D1
        POP BC                           ; $27CA  C1
        LD (DE),A                        ; $27CB  12
        INC DE                           ; $27CC  13
        LD A,(HL)                        ; $27CD  7E
        CP $2C                           ; $27CE  FE 2C
        CALL Z,SUB_13E4                  ; $27D0  CC E4 13
SUB_2602_15:
        DJNZ SUB_2602_12                 ; $27D3  10 E1
SUB_2602_16:
        CALL SUB_45A3                    ; $27D5  CD A3 45
        ADD HL,HL                        ; $27D8  29
SUB_2602_17:
        PUSH HL                          ; $27D9  E5
        LD HL,(L_0CB6)                   ; $27DA  2A B6 0C
        JP SUB_2602_2                    ; $27DD  C3 E8 26
        DEFW    SUB_3289_20              ; $27E0
        DEFB    $50,$E0,$21,$53                                  ; $27E2
        DEFW    SUB_1E72_18              ; $27E6
        DEFW    SUB_2816                 ; $27E8
        DEFB    $30,$03                                          ; $27EA
        DEFW    SUB_15CF_14              ; $27EC
        DEFB    $30,$75,$E1,$7E                                  ; $27EE
        DEFW    SUB_2CF8_1               ; $27F2
        DEFB    $C9                                              ; $27F4
L_27F5:
        DEFW    SUB_1E72_12              ; $27F5
        DEFB    $01                                              ; $27F7
L_27F8:
        DEFW    SUB_3809_21              ; $27F8
        DEFB    $01                                              ; $27FA
L_27FB:
        DEFW    SUB_4410_2               ; $27FB
        DEFB    $01                                              ; $27FD
L_27FE:
        DEFB    $1E                                              ; $27FE
        DEFW    SUB_0100_13              ; $27FF
L_2801:
        DEFB    $1E,$46                                          ; $2801
SUB_2803:
        PUSH DE                          ; $2803  D5
        LD C,$0E                         ; $2804  0E 0E
        LD A,($0004)                     ; $2806  3A 04 00
        LD E,A                           ; $2809  5F
        CALL $0005                       ; $280A  CD 05 00
SUB_2803_1:
        POP DE                           ; $280D  D1
SUB_2803_2:
        LD BC,SUB_201A_1+1               ; $280E  01 1E 20
        JP SUB_0D20_28                   ; $2811  C3 AC 0D
SUB_2803_3:
        NOP                              ; $2814  00
SUB_2803_4:
        LD D,B                           ; $2815  50
SUB_2816:
        LD HL,L_385A                     ; $2816  21 5A 38
SUB_2819:
        CALL SUB_2B36                    ; $2819  CD 36 2B
        JR SUB_2824                      ; $281C  18 06
SUB_2819_1:
        CALL SUB_2B36                    ; $281E  CD 36 2B
SUB_2821:
        CALL SUB_2AEB_1                  ; $2821  CD F4 2A
SUB_2824:
        LD A,B                           ; $2824  78
        OR A                             ; $2825  B7
        RET Z                            ; $2826  C8
        LD A,(SUB_0C98_6)                ; $2827  3A D7 0C
        OR A                             ; $282A  B7
        JP Z,SUB_2B28                    ; $282B  CA 28 2B
SUB_2824_1:
        SUB B                            ; $282E  90
        JR NC,SUB_2824_3                 ; $282F  30 0C
        CPL                              ; $2831  2F
        INC A                            ; $2832  3C
        EX DE,HL                         ; $2833  EB
        CALL SUB_2B18                    ; $2834  CD 18 2B
        EX DE,HL                         ; $2837  EB
SUB_2824_2:
        CALL SUB_2B28                    ; $2838  CD 28 2B
        POP BC                           ; $283B  C1
        POP DE                           ; $283C  D1
SUB_2824_3:
        CP $19                           ; $283D  FE 19
        RET NC                           ; $283F  D0
        PUSH AF                          ; $2840  F5
        CALL SUB_2B52                    ; $2841  CD 52 2B
        LD H,A                           ; $2844  67
        POP AF                           ; $2845  F1
        CALL SUB_28F5                    ; $2846  CD F5 28
SUB_2824_4:
        LD A,H                           ; $2849  7C
        OR A                             ; $284A  B7
        LD HL,SUB_0C98_4                 ; $284B  21 D4 0C
        JP P,SUB_2824_6                  ; $284E  F2 63 28
        CALL SUB_28D5                    ; $2851  CD D5 28
        JP NC,SUB_2874_10                ; $2854  D2 B6 28
SUB_2824_5:
        INC HL                           ; $2857  23
        INC (HL)                         ; $2858  34
        JP Z,SUB_3289_15                 ; $2859  CA D4 32
        LD L,$01                         ; $285C  2E 01
        CALL SUB_2917                    ; $285E  CD 17 29
        JR SUB_2874_10                   ; $2861  18 53
SUB_2824_6:
        XOR A                            ; $2863  AF
        SUB B                            ; $2864  90
        LD B,A                           ; $2865  47
        LD A,(HL)                        ; $2866  7E
        SBC A,E                          ; $2867  9B
        LD E,A                           ; $2868  5F
        INC HL                           ; $2869  23
        LD A,(HL)                        ; $286A  7E
        SBC A,D                          ; $286B  9A
        LD D,A                           ; $286C  57
        INC HL                           ; $286D  23
        LD A,(HL)                        ; $286E  7E
        SBC A,C                          ; $286F  99
        LD C,A                           ; $2870  4F
SUB_2824_7:
        CALL C,SUB_28E1                  ; $2871  DC E1 28
SUB_2874:
        LD L,B                           ; $2874  68
        LD H,E                           ; $2875  63
        XOR A                            ; $2876  AF
SUB_2874_1:
        LD B,A                           ; $2877  47
        LD A,C                           ; $2878  79
        OR A                             ; $2879  B7
        JR NZ,SUB_2874_8                 ; $287A  20 27
        LD C,D                           ; $287C  4A
        LD D,H                           ; $287D  54
        LD H,L                           ; $287E  65
        LD L,A                           ; $287F  6F
        LD A,B                           ; $2880  78
        SUB $08                          ; $2881  D6 08
SUB_2874_2:
        CP $E0                           ; $2883  FE E0
        JR NZ,SUB_2874_1                 ; $2885  20 F0
SUB_2874_3:
        XOR A                            ; $2887  AF
SUB_2874_4:
        LD (SUB_0C98_6),A                ; $2888  32 D7 0C
        RET                              ; $288B  C9
SUB_2874_5:
        LD A,H                           ; $288C  7C
        OR L                             ; $288D  B5
        OR D                             ; $288E  B2
        JR NZ,SUB_2874_7                 ; $288F  20 0A
        LD A,C                           ; $2891  79
SUB_2874_6:
        DEC B                            ; $2892  05
        RLA                              ; $2893  17
        JR NC,SUB_2874_6                 ; $2894  30 FC
        INC B                            ; $2896  04
        RRA                              ; $2897  1F
        LD C,A                           ; $2898  4F
        JR SUB_2874_9                    ; $2899  18 0B
SUB_2874_7:
        DEC B                            ; $289B  05
        ADD HL,HL                        ; $289C  29
        LD A,D                           ; $289D  7A
        RLA                              ; $289E  17
        LD D,A                           ; $289F  57
        LD A,C                           ; $28A0  79
        ADC A,A                          ; $28A1  8F
        LD C,A                           ; $28A2  4F
SUB_2874_8:
        JP P,SUB_2874_5                  ; $28A3  F2 8C 28
SUB_2874_9:
        LD A,B                           ; $28A6  78
        LD E,H                           ; $28A7  5C
        LD B,L                           ; $28A8  45
        OR A                             ; $28A9  B7
        JR Z,SUB_2874_10                 ; $28AA  28 0A
        LD HL,SUB_0C98_6                 ; $28AC  21 D7 0C
        ADD A,(HL)                       ; $28AF  86
        LD (HL),A                        ; $28B0  77
        JR NC,SUB_2874_3                 ; $28B1  30 D4
        JP Z,SUB_2874_3                  ; $28B3  CA 87 28
SUB_2874_10:
        LD A,B                           ; $28B6  78
SUB_2874_11:
        LD HL,SUB_0C98_6                 ; $28B7  21 D7 0C
SUB_2874_12:
        OR A                             ; $28BA  B7
SUB_2874_13:
        CALL M,SUB_28C8                  ; $28BB  FC C8 28
        LD B,(HL)                        ; $28BE  46
        INC HL                           ; $28BF  23
        LD A,(HL)                        ; $28C0  7E
        AND $80                          ; $28C1  E6 80
SUB_2874_14:
        XOR C                            ; $28C3  A9
        LD C,A                           ; $28C4  4F
        JP SUB_2B28                      ; $28C5  C3 28 2B
SUB_28C8:
        INC E                            ; $28C8  1C
        RET NZ                           ; $28C9  C0
        INC D                            ; $28CA  14
        RET NZ                           ; $28CB  C0
        INC C                            ; $28CC  0C
SUB_28C8_1:
        RET NZ                           ; $28CD  C0
        LD C,$80                         ; $28CE  0E 80
        INC (HL)                         ; $28D0  34
        RET NZ                           ; $28D1  C0
        JP SUB_3289_14                   ; $28D2  C3 D3 32
SUB_28D5:
        LD A,(HL)                        ; $28D5  7E
        ADD A,E                          ; $28D6  83
        LD E,A                           ; $28D7  5F
        INC HL                           ; $28D8  23
        LD A,(HL)                        ; $28D9  7E
        ADC A,D                          ; $28DA  8A
        LD D,A                           ; $28DB  57
        INC HL                           ; $28DC  23
        LD A,(HL)                        ; $28DD  7E
        ADC A,C                          ; $28DE  89
        LD C,A                           ; $28DF  4F
        RET                              ; $28E0  C9
SUB_28E1:
        LD HL,SUB_0C98_7                 ; $28E1  21 D8 0C
        LD A,(HL)                        ; $28E4  7E
SUB_28E1_1:
        CPL                              ; $28E5  2F
        LD (HL),A                        ; $28E6  77
        XOR A                            ; $28E7  AF
        LD L,A                           ; $28E8  6F
        SUB B                            ; $28E9  90
        LD B,A                           ; $28EA  47
SUB_28E1_2:
        LD A,L                           ; $28EB  7D
        SBC A,E                          ; $28EC  9B
        LD E,A                           ; $28ED  5F
        LD A,L                           ; $28EE  7D
        SBC A,D                          ; $28EF  9A
        LD D,A                           ; $28F0  57
        LD A,L                           ; $28F1  7D
        SBC A,C                          ; $28F2  99
        LD C,A                           ; $28F3  4F
        RET                              ; $28F4  C9
SUB_28F5:
        LD B,$00                         ; $28F5  06 00
SUB_28F5_1:
        SUB $08                          ; $28F7  D6 08
        JR C,SUB_28F5_3                  ; $28F9  38 07
        LD B,E                           ; $28FB  43
        LD E,D                           ; $28FC  5A
        LD D,C                           ; $28FD  51
SUB_28F5_2:
        LD C,$00                         ; $28FE  0E 00
        JR SUB_28F5_1                    ; $2900  18 F5
SUB_28F5_3:
        ADD A,$09                        ; $2902  C6 09
        LD L,A                           ; $2904  6F
        LD A,D                           ; $2905  7A
        OR E                             ; $2906  B3
        OR B                             ; $2907  B0
        JR NZ,SUB_28F5_5                 ; $2908  20 09
        LD A,C                           ; $290A  79
SUB_28F5_4:
        DEC L                            ; $290B  2D
        RET Z                            ; $290C  C8
        RRA                              ; $290D  1F
        LD C,A                           ; $290E  4F
        JR NC,SUB_28F5_4                 ; $290F  30 FA
        JR SUB_2917_1                    ; $2911  18 06
SUB_28F5_5:
        XOR A                            ; $2913  AF
        DEC L                            ; $2914  2D
        RET Z                            ; $2915  C8
        LD A,C                           ; $2916  79
SUB_2917:
        RRA                              ; $2917  1F
        LD C,A                           ; $2918  4F
SUB_2917_1:
        LD A,D                           ; $2919  7A
        RRA                              ; $291A  1F
        LD D,A                           ; $291B  57
        LD A,E                           ; $291C  7B
        RRA                              ; $291D  1F
        LD E,A                           ; $291E  5F
        LD A,B                           ; $291F  78
        RRA                              ; $2920  1F
        LD B,A                           ; $2921  47
SUB_2922:
        JR SUB_28F5_5                    ; $2922  18 EF
L_2924:
        DEFB    $00,$00,$00,$81,$04,$9A,$F7,$19                  ; $2924
        DEFW    SUB_2474_2               ; $292C
        DEFB    $63,$43,$83,$75,$CD,$8D,$84,$A9,$7F,$83,$82,$04,$00,$00,$00,$81 ; $292E
        DEFB    $E2,$B0,$4D                                      ; $293E
        DEFW    SUB_0925_14              ; $2941
        DEFW    SUB_1128_8               ; $2943
        DEFB    $83,$F4                                          ; $2945
        DEFW    SUB_34D3_4               ; $2947
        DEFB    $7F                                              ; $2949
SUB_294A:
        CALL SUB_2AC5                    ; $294A  CD C5 2A
        OR A                             ; $294D  B7
        JP PE,SUB_14E4_2                 ; $294E  EA EB 14
        CALL SUB_295D                    ; $2951  CD 5D 29
        LD BC,$8031                      ; $2954  01 31 80
        LD DE,$7218                      ; $2957  11 18 72
        DEFB    $C3                                              ; $295A
        DEFW    SUB_2990                 ; $295B
SUB_295D:
        DEFB    $CD,$33,$2B,$3E,$80                              ; $295D  "M3+>"
        DEFB    $32                                              ; $2962
        DEFW    SUB_0C98_6               ; $2963
        DEFB    $A8,$F5                                          ; $2965
        DEFW    SUB_189A_5               ; $2967
        DEFB    $2B                                              ; $2969
        DEFW    SUB_2821                 ; $296A
        DEFB    $29,$CD                                          ; $296C
        DEFW    SUB_39E3                 ; $296E
        DEFB    $C1,$E1                                          ; $2970
        DEFW    SUB_189A_5               ; $2972
        DEFB    $2B,$EB                                          ; $2974
        DEFW    SUB_28C8_1               ; $2976
        DEFB    $2B                                              ; $2978
        DEFW    SUB_3809_22              ; $2979
        DEFB    $29,$CD                                          ; $297B
        DEFW    SUB_39E3                 ; $297D
        DEFB    $C1,$D1,$CD                                      ; $297F
        DEFW    SUB_29E8_3               ; $2982
        DEFB    $F1                                              ; $2984
        DEFW    SUB_189A_5               ; $2985
        DEFB    $2B,$CD                                          ; $2987
        DEFW    SUB_2AD4                 ; $2989
        DEFB    $C1,$D1,$C3                                      ; $298B
        DEFW    SUB_2824                 ; $298E
SUB_2990:
        CALL SUB_2AC5                    ; $2990  CD C5 2A
        RET Z                            ; $2993  C8
        LD L,$00                         ; $2994  2E 00
        CALL SUB_2A84                    ; $2996  CD 84 2A
        LD A,C                           ; $2999  79
        LD (SUB_2990_4+1),A              ; $299A  32 C7 29
        EX DE,HL                         ; $299D  EB
        LD (SUB_2990_3+1),HL             ; $299E  22 C2 29
        LD BC,$0000                      ; $29A1  01 00 00
        LD D,B                           ; $29A4  50
        LD E,B                           ; $29A5  58
        LD HL,SUB_2874                   ; $29A6  21 74 28
        PUSH HL                          ; $29A9  E5
        LD HL,SUB_2990_1                 ; $29AA  21 B2 29
        PUSH HL                          ; $29AD  E5
        PUSH HL                          ; $29AE  E5
        LD HL,SUB_0C98_4                 ; $29AF  21 D4 0C
SUB_2990_1:
        LD A,(HL)                        ; $29B2  7E
        INC HL                           ; $29B3  23
        OR A                             ; $29B4  B7
        JR Z,SUB_2990_8                  ; $29B5  28 2C
        PUSH HL                          ; $29B7  E5
        EX DE,HL                         ; $29B8  EB
        LD E,$08                         ; $29B9  1E 08
SUB_2990_2:
        RRA                              ; $29BB  1F
        LD D,A                           ; $29BC  57
        LD A,C                           ; $29BD  79
        JR NC,SUB_2990_5                 ; $29BE  30 08
        PUSH DE                          ; $29C0  D5
SUB_2990_3:
        LD DE,$0000                      ; $29C1  11 00 00
        ADD HL,DE                        ; $29C4  19
        POP DE                           ; $29C5  D1
SUB_2990_4:
        ADC A,$00                        ; $29C6  CE 00
SUB_2990_5:
        RRA                              ; $29C8  1F
        LD C,A                           ; $29C9  4F
        LD A,H                           ; $29CA  7C
        RRA                              ; $29CB  1F
        LD H,A                           ; $29CC  67
        LD A,L                           ; $29CD  7D
        RRA                              ; $29CE  1F
        LD L,A                           ; $29CF  6F
        LD A,B                           ; $29D0  78
        RRA                              ; $29D1  1F
        LD B,A                           ; $29D2  47
        AND $10                          ; $29D3  E6 10
        JP Z,SUB_2990_6                  ; $29D5  CA DC 29
        LD A,B                           ; $29D8  78
        OR $20                           ; $29D9  F6 20
        LD B,A                           ; $29DB  47
SUB_2990_6:
        DEC E                            ; $29DC  1D
        LD A,D                           ; $29DD  7A
        JR NZ,SUB_2990_2                 ; $29DE  20 DB
        EX DE,HL                         ; $29E0  EB
SUB_2990_7:
        POP HL                           ; $29E1  E1
        RET                              ; $29E2  C9
SUB_2990_8:
        LD B,E                           ; $29E3  43
        LD E,D                           ; $29E4  5A
SUB_2990_9:
        LD D,C                           ; $29E5  51
        LD C,A                           ; $29E6  4F
        RET                              ; $29E7  C9
SUB_29E8:
        CALL SUB_2B18                    ; $29E8  CD 18 2B
SUB_29E8_1:
        LD HL,L_3002                     ; $29EB  21 02 30
        CALL SUB_2B25                    ; $29EE  CD 25 2B
SUB_29E8_2:
        POP BC                           ; $29F1  C1
        POP DE                           ; $29F2  D1
SUB_29E8_3:
        CALL SUB_2AC5                    ; $29F3  CD C5 2A
        JP Z,SUB_3289_17                 ; $29F6  CA DC 32
        LD L,$FF                         ; $29F9  2E FF
        CALL SUB_2A84                    ; $29FB  CD 84 2A
SUB_29E8_4:
        INC (HL)                         ; $29FE  34
        INC (HL)                         ; $29FF  34
SUB_29E8_5:
        DEC HL                           ; $2A00  2B
        LD A,(HL)                        ; $2A01  7E
        LD (SUB_29E8_9+1),A              ; $2A02  32 24 2A
        DEC HL                           ; $2A05  2B
        LD A,(HL)                        ; $2A06  7E
        LD (SUB_29E8_8+1),A              ; $2A07  32 20 2A
        DEC HL                           ; $2A0A  2B
        LD A,(HL)                        ; $2A0B  7E
        LD (SUB_29E8_7+1),A              ; $2A0C  32 1C 2A
        LD B,C                           ; $2A0F  41
        EX DE,HL                         ; $2A10  EB
        XOR A                            ; $2A11  AF
        LD C,A                           ; $2A12  4F
        LD D,A                           ; $2A13  57
        LD E,A                           ; $2A14  5F
        LD (SUB_29E8_10+1),A             ; $2A15  32 27 2A
SUB_29E8_6:
        PUSH HL                          ; $2A18  E5
        PUSH BC                          ; $2A19  C5
        LD A,L                           ; $2A1A  7D
SUB_29E8_7:
        SUB $00                          ; $2A1B  D6 00
        LD L,A                           ; $2A1D  6F
        LD A,H                           ; $2A1E  7C
SUB_29E8_8:
        SBC A,$00                        ; $2A1F  DE 00
        LD H,A                           ; $2A21  67
        LD A,B                           ; $2A22  78
SUB_29E8_9:
        SBC A,$00                        ; $2A23  DE 00
        LD B,A                           ; $2A25  47
SUB_29E8_10:
        LD A,$00                         ; $2A26  3E 00
        SBC A,$00                        ; $2A28  DE 00
        CCF                              ; $2A2A  3F
        JR NC,SUB_29E8_11+1              ; $2A2B  30 07
        LD (SUB_29E8_10+1),A             ; $2A2D  32 27 2A
        POP AF                           ; $2A30  F1
        POP AF                           ; $2A31  F1
        SCF                              ; $2A32  37
SUB_29E8_11:
        JP NC,$E1C1                      ; $2A33  D2 C1 E1
        LD A,C                           ; $2A36  79
        INC A                            ; $2A37  3C
        DEC A                            ; $2A38  3D
        RRA                              ; $2A39  1F
        JP P,SUB_29E8_13                 ; $2A3A  F2 52 2A
        RLA                              ; $2A3D  17
        LD A,(SUB_29E8_10+1)             ; $2A3E  3A 27 2A
        RRA                              ; $2A41  1F
        AND $C0                          ; $2A42  E6 C0
        PUSH AF                          ; $2A44  F5
        LD A,B                           ; $2A45  78
        OR H                             ; $2A46  B4
        OR L                             ; $2A47  B5
        JP Z,SUB_29E8_12                 ; $2A48  CA 4D 2A
        LD A,$20                         ; $2A4B  3E 20
SUB_29E8_12:
        POP HL                           ; $2A4D  E1
        OR H                             ; $2A4E  B4
        JP SUB_2874_11                   ; $2A4F  C3 B7 28
SUB_29E8_13:
        RLA                              ; $2A52  17
        LD A,E                           ; $2A53  7B
        RLA                              ; $2A54  17
        LD E,A                           ; $2A55  5F
SUB_29E8_14:
        LD A,D                           ; $2A56  7A
        RLA                              ; $2A57  17
        LD D,A                           ; $2A58  57
        LD A,C                           ; $2A59  79
        RLA                              ; $2A5A  17
        LD C,A                           ; $2A5B  4F
        ADD HL,HL                        ; $2A5C  29
        LD A,B                           ; $2A5D  78
        RLA                              ; $2A5E  17
        LD B,A                           ; $2A5F  47
        LD A,(SUB_29E8_10+1)             ; $2A60  3A 27 2A
        RLA                              ; $2A63  17
        LD (SUB_29E8_10+1),A             ; $2A64  32 27 2A
        LD A,C                           ; $2A67  79
        OR D                             ; $2A68  B2
        OR E                             ; $2A69  B3
        JR NZ,SUB_29E8_6                 ; $2A6A  20 AC
        PUSH HL                          ; $2A6C  E5
        LD HL,SUB_0C98_6                 ; $2A6D  21 D7 0C
        DEC (HL)                         ; $2A70  35
        POP HL                           ; $2A71  E1
        JR NZ,SUB_29E8_6                 ; $2A72  20 A4
        JP SUB_2874_3                    ; $2A74  C3 87 28
SUB_29E8_15:
        LD A,$FF                         ; $2A77  3E FF
SUB_29E8_16:
        LD L,$AF                         ; $2A79  2E AF
        LD HL,SUB_0C98_13                ; $2A7B  21 E3 0C
        LD C,(HL)                        ; $2A7E  4E
        INC HL                           ; $2A7F  23
        XOR (HL)                         ; $2A80  AE
        LD B,A                           ; $2A81  47
        LD L,$00                         ; $2A82  2E 00
SUB_2A84:
        LD A,B                           ; $2A84  78
        OR A                             ; $2A85  B7
        JR Z,SUB_2A9F_3                  ; $2A86  28 1F
        LD A,L                           ; $2A88  7D
        LD HL,SUB_0C98_6                 ; $2A89  21 D7 0C
        XOR (HL)                         ; $2A8C  AE
        ADD A,B                          ; $2A8D  80
        LD B,A                           ; $2A8E  47
        RRA                              ; $2A8F  1F
        XOR B                            ; $2A90  A8
        LD A,B                           ; $2A91  78
        JP P,SUB_2A9F_2                  ; $2A92  F2 A6 2A
        ADD A,$80                        ; $2A95  C6 80
        LD (HL),A                        ; $2A97  77
        JP Z,SUB_2990_7                  ; $2A98  CA E1 29
        CALL SUB_2B52                    ; $2A9B  CD 52 2B
        LD (HL),A                        ; $2A9E  77
SUB_2A9F:
        DEC HL                           ; $2A9F  2B
        RET                              ; $2AA0  C9
SUB_2A9F_1:
        CALL SUB_2AC5                    ; $2AA1  CD C5 2A
        CPL                              ; $2AA4  2F
        POP HL                           ; $2AA5  E1
SUB_2A9F_2:
        OR A                             ; $2AA6  B7
SUB_2A9F_3:
        POP HL                           ; $2AA7  E1
        JP P,SUB_2874_3                  ; $2AA8  F2 87 28
        JP SUB_3289_7                    ; $2AAB  C3 AC 32
SUB_2AAE:
        CALL SUB_2B33                    ; $2AAE  CD 33 2B
        LD A,B                           ; $2AB1  78
        OR A                             ; $2AB2  B7
        RET Z                            ; $2AB3  C8
        ADD A,$02                        ; $2AB4  C6 02
        JP C,SUB_3289_13                 ; $2AB6  DA CC 32
        LD B,A                           ; $2AB9  47
        CALL SUB_2824                    ; $2ABA  CD 24 28
        LD HL,SUB_0C98_6                 ; $2ABD  21 D7 0C
SUB_2AAE_1:
        INC (HL)                         ; $2AC0  34
        RET NZ                           ; $2AC1  C0
        JP SUB_3289_13                   ; $2AC2  C3 CC 32
SUB_2AC5:
        LD A,(SUB_0C98_6)                ; $2AC5  3A D7 0C
        OR A                             ; $2AC8  B7
SUB_2AC5_1:
        RET Z                            ; $2AC9  C8
        LD A,(SUB_0C98_5)                ; $2ACA  3A D6 0C
SUB_2AC5_2:
        CP $2F                           ; $2ACD  FE 2F
SUB_2AC5_3:
        RLA                              ; $2ACF  17
SUB_2AC5_4:
        SBC A,A                          ; $2AD0  9F
        RET NZ                           ; $2AD1  C0
        INC A                            ; $2AD2  3C
        RET                              ; $2AD3  C9
SUB_2AD4:
        LD B,$88                         ; $2AD4  06 88
        LD DE,$0000                      ; $2AD6  11 00 00
SUB_2AD4_1:
        LD HL,SUB_0C98_6                 ; $2AD9  21 D7 0C
        LD C,A                           ; $2ADC  4F
        LD (HL),B                        ; $2ADD  70
        LD B,$00                         ; $2ADE  06 00
        INC HL                           ; $2AE0  23
        LD (HL),$80                      ; $2AE1  36 80
        RLA                              ; $2AE3  17
        JP SUB_2824_7                    ; $2AE4  C3 71 28
SUB_2AD4_2:
        CALL SUB_2B06                    ; $2AE7  CD 06 2B
        RET P                            ; $2AEA  F0
SUB_2AEB:
        CALL SUB_1DE3                    ; $2AEB  CD E3 1D
        JP M,SUB_2E57_1                  ; $2AEE  FA 61 2E
        JP Z,SUB_0D20_27+1               ; $2AF1  CA AA 0D
SUB_2AEB_1:
        LD HL,SUB_0C98_5                 ; $2AF4  21 D6 0C
        LD A,(HL)                        ; $2AF7  7E
        XOR $80                          ; $2AF8  EE 80
        LD (HL),A                        ; $2AFA  77
        RET                              ; $2AFB  C9
SUB_2AEB_2:
        CALL SUB_2B06                    ; $2AFC  CD 06 2B
SUB_2AFF:
        LD L,A                           ; $2AFF  6F
        RLA                              ; $2B00  17
        SBC A,A                          ; $2B01  9F
        LD H,A                           ; $2B02  67
        JP SUB_2C55                      ; $2B03  C3 55 2C
SUB_2B06:
        CALL SUB_1DE3                    ; $2B06  CD E3 1D
        JP Z,SUB_0D20_27+1               ; $2B09  CA AA 0D
        JP P,SUB_2AC5                    ; $2B0C  F2 C5 2A
        LD HL,(SUB_0C98_4)               ; $2B0F  2A D4 0C
SUB_2B12:
        LD A,H                           ; $2B12  7C
        OR L                             ; $2B13  B5
        RET Z                            ; $2B14  C8
        LD A,H                           ; $2B15  7C
        JR SUB_2AC5_3                    ; $2B16  18 B7
SUB_2B18:
        EX DE,HL                         ; $2B18  EB
        LD HL,(SUB_0C98_4)               ; $2B19  2A D4 0C
        EX (SP),HL                       ; $2B1C  E3
        PUSH HL                          ; $2B1D  E5
        LD HL,(SUB_0C98_5)               ; $2B1E  2A D6 0C
        EX (SP),HL                       ; $2B21  E3
        PUSH HL                          ; $2B22  E5
SUB_2B18_1:
        EX DE,HL                         ; $2B23  EB
        RET                              ; $2B24  C9
SUB_2B25:
        CALL SUB_2B36                    ; $2B25  CD 36 2B
SUB_2B28:
        EX DE,HL                         ; $2B28  EB
        LD (SUB_0C98_4),HL               ; $2B29  22 D4 0C
SUB_2B28_1:
        LD H,B                           ; $2B2C  60
        LD L,C                           ; $2B2D  69
        LD (SUB_0C98_5),HL               ; $2B2E  22 D6 0C
        EX DE,HL                         ; $2B31  EB
        RET                              ; $2B32  C9
SUB_2B33:
        LD HL,SUB_0C98_4                 ; $2B33  21 D4 0C
SUB_2B36:
        LD E,(HL)                        ; $2B36  5E
        INC HL                           ; $2B37  23
SUB_2B38:
        LD D,(HL)                        ; $2B38  56
        INC HL                           ; $2B39  23
        LD C,(HL)                        ; $2B3A  4E
        INC HL                           ; $2B3B  23
        LD B,(HL)                        ; $2B3C  46
SUB_2B3D:
        INC HL                           ; $2B3D  23
        RET                              ; $2B3E  C9
SUB_2B3F:
        LD DE,SUB_0C98_4                 ; $2B3F  11 D4 0C
SUB_2B42:
        LD B,$04                         ; $2B42  06 04
        JR SUB_2B4B                      ; $2B44  18 05
SUB_2B42_1:
        EX DE,HL                         ; $2B46  EB
SUB_2B47:
        LD A,(SUB_0B2A_5)                ; $2B47  3A 37 0B
        LD B,A                           ; $2B4A  47
SUB_2B4B:
        LD A,(DE)                        ; $2B4B  1A
        LD (HL),A                        ; $2B4C  77
        INC DE                           ; $2B4D  13
        INC HL                           ; $2B4E  23
        DJNZ SUB_2B4B                    ; $2B4F  10 FA
        RET                              ; $2B51  C9
SUB_2B52:
        LD HL,SUB_0C98_5                 ; $2B52  21 D6 0C
        LD A,(HL)                        ; $2B55  7E
        RLCA                             ; $2B56  07
        SCF                              ; $2B57  37
        RRA                              ; $2B58  1F
        LD (HL),A                        ; $2B59  77
        CCF                              ; $2B5A  3F
        RRA                              ; $2B5B  1F
        INC HL                           ; $2B5C  23
        INC HL                           ; $2B5D  23
        LD (HL),A                        ; $2B5E  77
        LD A,C                           ; $2B5F  79
        RLCA                             ; $2B60  07
        SCF                              ; $2B61  37
        RRA                              ; $2B62  1F
        LD C,A                           ; $2B63  4F
        RRA                              ; $2B64  1F
        XOR (HL)                         ; $2B65  AE
        RET                              ; $2B66  C9
SUB_2B52_1:
        LD HL,SUB_0C98_12                ; $2B67  21 DD 0C
SUB_2B6A:
        LD DE,SUB_2B42_1                 ; $2B6A  11 46 2B
        JR SUB_2B72_1                    ; $2B6D  18 06
SUB_2B6F:
        LD HL,SUB_0C98_12                ; $2B6F  21 DD 0C
SUB_2B72:
        LD DE,SUB_2B47                   ; $2B72  11 47 2B
SUB_2B72_1:
        PUSH DE                          ; $2B75  D5
        LD DE,SUB_0C98_4                 ; $2B76  11 D4 0C
        CALL SUB_1DE3                    ; $2B79  CD E3 1D
        RET C                            ; $2B7C  D8
        LD DE,SUB_0C98_1                 ; $2B7D  11 D0 0C
        RET                              ; $2B80  C9
SUB_2B81:
        LD A,B                           ; $2B81  78
        OR A                             ; $2B82  B7
        JP Z,SUB_2AC5                    ; $2B83  CA C5 2A
        LD HL,SUB_2AC5_2+1               ; $2B86  21 CE 2A
SUB_2B81_1:
        PUSH HL                          ; $2B89  E5
        CALL SUB_2AC5                    ; $2B8A  CD C5 2A
        LD A,C                           ; $2B8D  79
        RET Z                            ; $2B8E  C8
        LD HL,SUB_0C98_5                 ; $2B8F  21 D6 0C
        XOR (HL)                         ; $2B92  AE
        LD A,C                           ; $2B93  79
        RET M                            ; $2B94  F8
        CALL SUB_2B9B                    ; $2B95  CD 9B 2B
SUB_2B81_2:
        RRA                              ; $2B98  1F
        XOR C                            ; $2B99  A9
        RET                              ; $2B9A  C9
SUB_2B9B:
        INC HL                           ; $2B9B  23
        LD A,B                           ; $2B9C  78
        CP (HL)                          ; $2B9D  BE
        RET NZ                           ; $2B9E  C0
        DEC HL                           ; $2B9F  2B
        LD A,C                           ; $2BA0  79
        CP (HL)                          ; $2BA1  BE
        RET NZ                           ; $2BA2  C0
        DEC HL                           ; $2BA3  2B
        LD A,D                           ; $2BA4  7A
        CP (HL)                          ; $2BA5  BE
        RET NZ                           ; $2BA6  C0
        DEC HL                           ; $2BA7  2B
        LD A,E                           ; $2BA8  7B
SUB_2B9B_1:
        SUB (HL)                         ; $2BA9  96
        RET NZ                           ; $2BAA  C0
        POP HL                           ; $2BAB  E1
        POP HL                           ; $2BAC  E1
        RET                              ; $2BAD  C9
SUB_2BAE:
        LD A,D                           ; $2BAE  7A
        XOR H                            ; $2BAF  AC
        LD A,H                           ; $2BB0  7C
        JP M,SUB_2AC5_3                  ; $2BB1  FA CF 2A
        CP D                             ; $2BB4  BA
        JP NZ,SUB_2AC5_4                 ; $2BB5  C2 D0 2A
        LD A,L                           ; $2BB8  7D
        SUB E                            ; $2BB9  93
        JP NZ,SUB_2AC5_4                 ; $2BBA  C2 D0 2A
        RET                              ; $2BBD  C9
SUB_2BBE:
        LD HL,SUB_0C98_12                ; $2BBE  21 DD 0C
        CALL SUB_2B47                    ; $2BC1  CD 47 2B
SUB_2BC4:
        LD DE,SUB_0C98_14                ; $2BC4  11 E4 0C
        LD A,(DE)                        ; $2BC7  1A
        OR A                             ; $2BC8  B7
        JP Z,SUB_2AC5                    ; $2BC9  CA C5 2A
        LD HL,SUB_2AC5_2+1               ; $2BCC  21 CE 2A
        PUSH HL                          ; $2BCF  E5
        CALL SUB_2AC5                    ; $2BD0  CD C5 2A
SUB_2BC4_1:
        DEC DE                           ; $2BD3  1B
        LD A,(DE)                        ; $2BD4  1A
        LD C,A                           ; $2BD5  4F
        RET Z                            ; $2BD6  C8
        LD HL,SUB_0C98_5                 ; $2BD7  21 D6 0C
        XOR (HL)                         ; $2BDA  AE
        LD A,C                           ; $2BDB  79
        RET M                            ; $2BDC  F8
        INC DE                           ; $2BDD  13
SUB_2BC4_2:
        INC HL                           ; $2BDE  23
        LD B,$08                         ; $2BDF  06 08
SUB_2BC4_3:
        LD A,(DE)                        ; $2BE1  1A
        SUB (HL)                         ; $2BE2  96
SUB_2BC4_4:
        JP NZ,SUB_2B81_2                 ; $2BE3  C2 98 2B
        DEC DE                           ; $2BE6  1B
        DEC HL                           ; $2BE7  2B
        DEC B                            ; $2BE8  05
        JR NZ,SUB_2BC4_3                 ; $2BE9  20 F6
        POP BC                           ; $2BEB  C1
        RET                              ; $2BEC  C9
SUB_2BC4_5:
        CALL SUB_2BC4                    ; $2BED  CD C4 2B
        JP NZ,SUB_2AC5_2+1               ; $2BF0  C2 CE 2A
        RET                              ; $2BF3  C9
SUB_2BF4:
        CALL SUB_1DE3                    ; $2BF4  CD E3 1D
        LD HL,(SUB_0C98_4)               ; $2BF7  2A D4 0C
        RET M                            ; $2BFA  F8
        JP Z,SUB_0D20_27+1               ; $2BFB  CA AA 0D
        JP PO,SUB_2BF4_1                 ; $2BFE  E2 13 2C
        CALL SUB_2B6F                    ; $2C01  CD 6F 2B
        LD HL,L_3856                     ; $2C04  21 56 38
        CALL SUB_2B6A                    ; $2C07  CD 6A 2B
        CALL SUB_2E8E                    ; $2C0A  CD 8E 2E
        CALL SUB_2C76                    ; $2C0D  CD 76 2C
        JP SUB_2BF4_2                    ; $2C10  C3 16 2C
SUB_2BF4_1:
        CALL SUB_2816                    ; $2C13  CD 16 28
SUB_2BF4_2:
        LD A,(SUB_0C98_5)                ; $2C16  3A D6 0C
        OR A                             ; $2C19  B7
        PUSH AF                          ; $2C1A  F5
        AND $7F                          ; $2C1B  E6 7F
        LD (SUB_0C98_5),A                ; $2C1D  32 D6 0C
SUB_2BF4_3:
        LD A,(SUB_0C98_6)                ; $2C20  3A D7 0C
        CP $90                           ; $2C23  FE 90
        JP NC,SUB_0D20_25+1              ; $2C25  D2 A4 0D
        CALL SUB_2CBA                    ; $2C28  CD BA 2C
        LD A,(SUB_0C98_6)                ; $2C2B  3A D7 0C
        OR A                             ; $2C2E  B7
        JP NZ,SUB_2BF4_4                 ; $2C2F  C2 37 2C
        POP AF                           ; $2C32  F1
        EX DE,HL                         ; $2C33  EB
        JP SUB_2BF4_5                    ; $2C34  C3 3C 2C
SUB_2BF4_4:
        POP AF                           ; $2C37  F1
        EX DE,HL                         ; $2C38  EB
        JP P,SUB_2BF4_6                  ; $2C39  F2 42 2C
SUB_2BF4_5:
        LD A,H                           ; $2C3C  7C
        CPL                              ; $2C3D  2F
        LD H,A                           ; $2C3E  67
        LD A,L                           ; $2C3F  7D
        CPL                              ; $2C40  2F
        LD L,A                           ; $2C41  6F
SUB_2BF4_6:
        JP SUB_2C55                      ; $2C42  C3 55 2C
SUB_2BF4_7:
        LD HL,SUB_0D20_25+1              ; $2C45  21 A4 0D
        PUSH HL                          ; $2C48  E5
SUB_2C49:
        LD A,(SUB_0C98_6)                ; $2C49  3A D7 0C
        CP $90                           ; $2C4C  FE 90
        JR NC,SUB_2C5E                   ; $2C4E  30 0E
        CALL SUB_2CBA                    ; $2C50  CD BA 2C
        EX DE,HL                         ; $2C53  EB
SUB_2C49_1:
        POP DE                           ; $2C54  D1
SUB_2C55:
        LD (SUB_0C98_4),HL               ; $2C55  22 D4 0C
SUB_2C58:
        LD A,$02                         ; $2C58  3E 02
SUB_2C58_1:
        LD (SUB_0B2A_5),A                ; $2C5A  32 37 0B
        RET                              ; $2C5D  C9
SUB_2C5E:
        LD BC,$9080                      ; $2C5E  01 80 90
        LD DE,$0000                      ; $2C61  11 00 00
        CALL SUB_2B81                    ; $2C64  CD 81 2B
        RET NZ                           ; $2C67  C0
        LD H,C                           ; $2C68  61
        LD L,D                           ; $2C69  6A
        JR SUB_2C49_1                    ; $2C6A  18 E8
SUB_2C6C:
        CALL SUB_1DE3                    ; $2C6C  CD E3 1D
        RET PO                           ; $2C6F  E0
        JP M,SUB_2C89                    ; $2C70  FA 89 2C
        JP Z,SUB_0D20_27+1               ; $2C73  CA AA 0D
SUB_2C76:
        CALL SUB_2B33                    ; $2C76  CD 33 2B
        CALL SUB_2CAB_1+1                ; $2C79  CD AE 2C
        LD A,B                           ; $2C7C  78
        OR A                             ; $2C7D  B7
        RET Z                            ; $2C7E  C8
        CALL SUB_2B52                    ; $2C7F  CD 52 2B
        LD HL,SUB_0C98_3                 ; $2C82  21 D3 0C
        LD B,(HL)                        ; $2C85  46
        JP SUB_2874_10                   ; $2C86  C3 B6 28
SUB_2C89:
        LD HL,(SUB_0C98_4)               ; $2C89  2A D4 0C
SUB_2C8C:
        CALL SUB_2CAB_1+1                ; $2C8C  CD AE 2C
        LD A,H                           ; $2C8F  7C
        LD D,L                           ; $2C90  55
        LD E,$00                         ; $2C91  1E 00
        LD B,$90                         ; $2C93  06 90
        JP SUB_2AD4_1                    ; $2C95  C3 D9 2A
SUB_2C98:
        CALL SUB_1DE3                    ; $2C98  CD E3 1D
        RET NC                           ; $2C9B  D0
        JP Z,SUB_0D20_27+1               ; $2C9C  CA AA 0D
        CALL M,SUB_2C89                  ; $2C9F  FC 89 2C
SUB_2CA2:
        LD HL,$0000                      ; $2CA2  21 00 00
        LD (SUB_0C98_1),HL               ; $2CA5  22 D0 0C
        LD (SUB_0C98_2),HL               ; $2CA8  22 D2 0C
SUB_2CAB:
        LD A,$08                         ; $2CAB  3E 08
SUB_2CAB_1:
        LD BC,L_043E                     ; $2CAD  01 3E 04
        JP SUB_2C58_1                    ; $2CB0  C3 5A 2C
SUB_2CB3:
        CALL SUB_1DE3                    ; $2CB3  CD E3 1D
        RET Z                            ; $2CB6  C8
        JP SUB_0D20_27+1                 ; $2CB7  C3 AA 0D
SUB_2CBA:
        LD B,A                           ; $2CBA  47
        LD C,A                           ; $2CBB  4F
        LD D,A                           ; $2CBC  57
        LD E,A                           ; $2CBD  5F
        OR A                             ; $2CBE  B7
        RET Z                            ; $2CBF  C8
        PUSH HL                          ; $2CC0  E5
        CALL SUB_2B33                    ; $2CC1  CD 33 2B
SUB_2CBA_1:
        CALL SUB_2B52                    ; $2CC4  CD 52 2B
        XOR (HL)                         ; $2CC7  AE
        LD H,A                           ; $2CC8  67
        CALL M,SUB_2CDE                  ; $2CC9  FC DE 2C
        LD A,$98                         ; $2CCC  3E 98
        SUB B                            ; $2CCE  90
        CALL SUB_28F5                    ; $2CCF  CD F5 28
        LD A,H                           ; $2CD2  7C
        RLA                              ; $2CD3  17
        CALL C,SUB_28C8                  ; $2CD4  DC C8 28
        LD B,$00                         ; $2CD7  06 00
        CALL C,SUB_28E1                  ; $2CD9  DC E1 28
        POP HL                           ; $2CDC  E1
        RET                              ; $2CDD  C9
SUB_2CDE:
        DEC DE                           ; $2CDE  1B
        LD A,D                           ; $2CDF  7A
        AND E                            ; $2CE0  A3
        INC A                            ; $2CE1  3C
        RET NZ                           ; $2CE2  C0
SUB_2CE3:
        DEC BC                           ; $2CE3  0B
        RET                              ; $2CE4  C9
SUB_2CE3_1:
        CALL SUB_1DE3                    ; $2CE5  CD E3 1D
        RET M                            ; $2CE8  F8
        CALL SUB_2AC5                    ; $2CE9  CD C5 2A
        JP P,SUB_2CF8                    ; $2CEC  F2 F8 2C
        CALL SUB_2AEB_1                  ; $2CEF  CD F4 2A
        CALL SUB_2CF8                    ; $2CF2  CD F8 2C
        JP SUB_2AEB                      ; $2CF5  C3 EB 2A
SUB_2CF8:
        CALL SUB_1DE3                    ; $2CF8  CD E3 1D
        RET M                            ; $2CFB  F8
        JR NC,SUB_2D04_1                 ; $2CFC  30 1F
SUB_2CF8_1:
        JP Z,SUB_0D20_27+1               ; $2CFE  CA AA 0D
        CALL SUB_2C49                    ; $2D01  CD 49 2C
SUB_2D04:
        LD HL,SUB_0C98_6                 ; $2D04  21 D7 0C
        LD A,(HL)                        ; $2D07  7E
        CP $98                           ; $2D08  FE 98
        LD A,(SUB_0C98_4)                ; $2D0A  3A D4 0C
        RET NC                           ; $2D0D  D0
        LD A,(HL)                        ; $2D0E  7E
        CALL SUB_2CBA                    ; $2D0F  CD BA 2C
        LD (HL),$98                      ; $2D12  36 98
        LD A,E                           ; $2D14  7B
        PUSH AF                          ; $2D15  F5
        LD A,C                           ; $2D16  79
        RLA                              ; $2D17  17
        CALL SUB_2824_7                  ; $2D18  CD 71 28
        POP AF                           ; $2D1B  F1
        RET                              ; $2D1C  C9
SUB_2D04_1:
        LD HL,SUB_0C98_6                 ; $2D1D  21 D7 0C
        LD A,(HL)                        ; $2D20  7E
SUB_2D04_2:
        CP $90                           ; $2D21  FE 90
        JR NZ,SUB_2D04_3                 ; $2D23  20 1A
        DEFB    $4F,$2B,$7E,$EE,$80                              ; $2D25  "O+~n"
        DEFB    $06                                              ; $2D2A
        DEFW    SUB_2B06                 ; $2D2B
        DEFB    $B6,$05                                          ; $2D2D
        DEFB    $20,$FB,$B7,$21,$00                              ; $2D2F  " {7!"
        DEFB    $80                                              ; $2D34
        DEFW    SUB_3EC0_1               ; $2D35
        DEFB    $2D,$CD                                          ; $2D37
        DEFW    SUB_2C55                 ; $2D39
        DEFB    $C3                                              ; $2D3B
        DEFW    SUB_2C98                 ; $2D3C
        DEFB    $79                                              ; $2D3E
SUB_2D04_3:
        OR A                             ; $2D3F  B7
        RET Z                            ; $2D40  C8
        CP $B8                           ; $2D41  FE B8
        RET NC                           ; $2D43  D0
SUB_2D44:
        PUSH AF                          ; $2D44  F5
        CALL SUB_2B33                    ; $2D45  CD 33 2B
SUB_2D48:
        CALL SUB_2B52                    ; $2D48  CD 52 2B
        XOR (HL)                         ; $2D4B  AE
        DEC HL                           ; $2D4C  2B
        LD (HL),$B8                      ; $2D4D  36 B8
        PUSH AF                          ; $2D4F  F5
        DEC HL                           ; $2D50  2B
        LD (HL),C                        ; $2D51  71
        CALL M,SUB_2D6F                  ; $2D52  FC 6F 2D
        LD A,(SUB_0C98_5)                ; $2D55  3A D6 0C
        LD C,A                           ; $2D58  4F
        LD HL,SUB_0C98_5                 ; $2D59  21 D6 0C
        LD A,$B8                         ; $2D5C  3E B8
        SUB B                            ; $2D5E  90
        CALL SUB_2F84                    ; $2D5F  CD 84 2F
        POP AF                           ; $2D62  F1
        CALL M,SUB_2F3F                  ; $2D63  FC 3F 2F
        XOR A                            ; $2D66  AF
        LD (L_0CCF),A                    ; $2D67  32 CF 0C
        POP AF                           ; $2D6A  F1
        RET NC                           ; $2D6B  D0
        JP SUB_2E8E_4                    ; $2D6C  C3 F7 2E
SUB_2D6F:
        LD HL,SUB_0C98_1                 ; $2D6F  21 D0 0C
SUB_2D6F_1:
        LD A,(HL)                        ; $2D72  7E
        DEC (HL)                         ; $2D73  35
        OR A                             ; $2D74  B7
        INC HL                           ; $2D75  23
        JR Z,SUB_2D6F_1                  ; $2D76  28 FA
        RET                              ; $2D78  C9
SUB_2D79:
        PUSH HL                          ; $2D79  E5
        LD HL,$0000                      ; $2D7A  21 00 00
        LD A,B                           ; $2D7D  78
        OR C                             ; $2D7E  B1
        JR Z,SUB_2D79_3                  ; $2D7F  28 12
        LD A,$10                         ; $2D81  3E 10
SUB_2D79_1:
        ADD HL,HL                        ; $2D83  29
        JP C,SUB_3D4E_14                 ; $2D84  DA EA 3D
        EX DE,HL                         ; $2D87  EB
        ADD HL,HL                        ; $2D88  29
        EX DE,HL                         ; $2D89  EB
        JR NC,SUB_2D79_2                 ; $2D8A  30 04
        ADD HL,BC                        ; $2D8C  09
        JP C,SUB_3D4E_14                 ; $2D8D  DA EA 3D
SUB_2D79_2:
        DEC A                            ; $2D90  3D
        JR NZ,SUB_2D79_1                 ; $2D91  20 F0
SUB_2D79_3:
        EX DE,HL                         ; $2D93  EB
        POP HL                           ; $2D94  E1
        RET                              ; $2D95  C9
SUB_2D79_4:
        LD A,H                           ; $2D96  7C
        RLA                              ; $2D97  17
        SBC A,A                          ; $2D98  9F
        LD B,A                           ; $2D99  47
        CALL SUB_2E57                    ; $2D9A  CD 57 2E
        LD A,C                           ; $2D9D  79
        SBC A,B                          ; $2D9E  98
        JR SUB_2DA1_1                    ; $2D9F  18 03
SUB_2DA1:
        LD A,H                           ; $2DA1  7C
        RLA                              ; $2DA2  17
        SBC A,A                          ; $2DA3  9F
SUB_2DA1_1:
        LD B,A                           ; $2DA4  47
        PUSH HL                          ; $2DA5  E5
        LD A,D                           ; $2DA6  7A
        RLA                              ; $2DA7  17
        SBC A,A                          ; $2DA8  9F
        ADD HL,DE                        ; $2DA9  19
        ADC A,B                          ; $2DAA  88
        RRCA                             ; $2DAB  0F
        XOR H                            ; $2DAC  AC
        JP P,SUB_2C49_1                  ; $2DAD  F2 54 2C
        PUSH BC                          ; $2DB0  C5
        EX DE,HL                         ; $2DB1  EB
        CALL SUB_2C8C                    ; $2DB2  CD 8C 2C
        POP AF                           ; $2DB5  F1
        POP HL                           ; $2DB6  E1
        CALL SUB_2B18                    ; $2DB7  CD 18 2B
        EX DE,HL                         ; $2DBA  EB
        CALL SUB_2E71                    ; $2DBB  CD 71 2E
        JP SUB_3289_1                    ; $2DBE  C3 8F 32
        DEFB    $7C,$B5,$CA,$55,$2C,$E5,$D5,$CD,$4B,$2E,$C5,$44,$4D,$21,$00 ; $2DC1  "|5JU,eUMK.EDM!"
        DEFB    $00,$3E,$10                                      ; $2DD0
        DEFW    SUB_3809_3               ; $2DD3
        DEFB    $1F                                              ; $2DD5
        DEFW    SUB_29E8_1               ; $2DD6
        DEFB    $EB                                              ; $2DD8
        DEFW    SUB_0100_31              ; $2DD9
        DEFB    $09,$DA,$F5                                      ; $2DDB
        DEFW    SUB_3D15_4               ; $2DDE
        DEFB    $20,$F1,$C1,$D1                                  ; $2DE0
SUB_2DA1_2:
        LD A,H                           ; $2DE4  7C
        OR A                             ; $2DE5  B7
        JP M,SUB_2DA1_3                  ; $2DE6  FA EE 2D
        POP DE                           ; $2DE9  D1
        LD A,B                           ; $2DEA  78
        JP SUB_2E52_1                    ; $2DEB  C3 53 2E
SUB_2DA1_3:
        XOR $80                          ; $2DEE  EE 80
        OR L                             ; $2DF0  B5
        JR Z,SUB_2DA1_5                  ; $2DF1  28 13
        EX DE,HL                         ; $2DF3  EB
        LD BC,$E1C1                      ; $2DF4  01 C1 E1
        CALL SUB_2C8C                    ; $2DF7  CD 8C 2C
        POP HL                           ; $2DFA  E1
        CALL SUB_2B18                    ; $2DFB  CD 18 2B
        CALL SUB_2C8C                    ; $2DFE  CD 8C 2C
SUB_2DA1_4:
        POP BC                           ; $2E01  C1
        POP DE                           ; $2E02  D1
        JP SUB_2990                      ; $2E03  C3 90 29
SUB_2DA1_5:
        LD A,B                           ; $2E06  78
        OR A                             ; $2E07  B7
        POP BC                           ; $2E08  C1
        JP M,SUB_2C55                    ; $2E09  FA 55 2C
        PUSH DE                          ; $2E0C  D5
        CALL SUB_2C8C                    ; $2E0D  CD 8C 2C
        POP DE                           ; $2E10  D1
        JP SUB_2AEB_1                    ; $2E11  C3 F4 2A
SUB_2E14:
        LD A,H                           ; $2E14  7C
        OR L                             ; $2E15  B5
        JP Z,SUB_0D20_21+1               ; $2E16  CA 95 0D
        CALL SUB_2E4B                    ; $2E19  CD 4B 2E
        PUSH BC                          ; $2E1C  C5
        EX DE,HL                         ; $2E1D  EB
        CALL SUB_2E57                    ; $2E1E  CD 57 2E
        LD B,H                           ; $2E21  44
        LD C,L                           ; $2E22  4D
        LD HL,$0000                      ; $2E23  21 00 00
        LD A,$11                         ; $2E26  3E 11
        PUSH AF                          ; $2E28  F5
        OR A                             ; $2E29  B7
        JR SUB_2E14_3                    ; $2E2A  18 09
SUB_2E14_1:
        PUSH AF                          ; $2E2C  F5
        PUSH HL                          ; $2E2D  E5
        ADD HL,BC                        ; $2E2E  09
        JR NC,SUB_2E14_2+1               ; $2E2F  30 03
        POP AF                           ; $2E31  F1
        SCF                              ; $2E32  37
SUB_2E14_2:
        LD A,$E1                         ; $2E33  3E E1
SUB_2E14_3:
        LD A,E                           ; $2E35  7B
        RLA                              ; $2E36  17
        LD E,A                           ; $2E37  5F
        LD A,D                           ; $2E38  7A
        RLA                              ; $2E39  17
        LD D,A                           ; $2E3A  57
        LD A,L                           ; $2E3B  7D
        RLA                              ; $2E3C  17
        LD L,A                           ; $2E3D  6F
        LD A,H                           ; $2E3E  7C
        RLA                              ; $2E3F  17
        LD H,A                           ; $2E40  67
        POP AF                           ; $2E41  F1
        DEC A                            ; $2E42  3D
        JR NZ,SUB_2E14_1                 ; $2E43  20 E7
        EX DE,HL                         ; $2E45  EB
        POP BC                           ; $2E46  C1
        PUSH DE                          ; $2E47  D5
        JP SUB_2DA1_2                    ; $2E48  C3 E4 2D
SUB_2E4B:
        LD A,H                           ; $2E4B  7C
        XOR D                            ; $2E4C  AA
        LD B,A                           ; $2E4D  47
SUB_2E4B_1:
        CALL SUB_2E52                    ; $2E4E  CD 52 2E
        EX DE,HL                         ; $2E51  EB
SUB_2E52:
        LD A,H                           ; $2E52  7C
SUB_2E52_1:
        OR A                             ; $2E53  B7
        JP P,SUB_2C55                    ; $2E54  F2 55 2C
SUB_2E57:
        XOR A                            ; $2E57  AF
        LD C,A                           ; $2E58  4F
        SUB L                            ; $2E59  95
        LD L,A                           ; $2E5A  6F
        LD A,C                           ; $2E5B  79
        SBC A,H                          ; $2E5C  9C
        LD H,A                           ; $2E5D  67
        JP SUB_2C55                      ; $2E5E  C3 55 2C
SUB_2E57_1:
        LD HL,(SUB_0C98_4)               ; $2E61  2A D4 0C
        CALL SUB_2E57                    ; $2E64  CD 57 2E
        LD A,H                           ; $2E67  7C
        XOR $80                          ; $2E68  EE 80
        OR L                             ; $2E6A  B5
        RET NZ                           ; $2E6B  C0
SUB_2E6C:
        EX DE,HL                         ; $2E6C  EB
        CALL SUB_2CAB_1+1                ; $2E6D  CD AE 2C
        XOR A                            ; $2E70  AF
SUB_2E71:
        LD B,$98                         ; $2E71  06 98
        JP SUB_2AD4_1                    ; $2E73  C3 D9 2A
SUB_2E76:
        PUSH DE                          ; $2E76  D5
        CALL SUB_2E14                    ; $2E77  CD 14 2E
        XOR A                            ; $2E7A  AF
        ADD A,D                          ; $2E7B  82
        RRA                              ; $2E7C  1F
        LD H,A                           ; $2E7D  67
        LD A,E                           ; $2E7E  7B
        RRA                              ; $2E7F  1F
        LD L,A                           ; $2E80  6F
        CALL SUB_2C58                    ; $2E81  CD 58 2C
        POP AF                           ; $2E84  F1
        JR SUB_2E52_1                    ; $2E85  18 CC
SUB_2E76_1:
        LD HL,SUB_0C98_13                ; $2E87  21 E3 0C
        LD A,(HL)                        ; $2E8A  7E
        XOR $80                          ; $2E8B  EE 80
        LD (HL),A                        ; $2E8D  77
SUB_2E8E:
        LD HL,SUB_0C98_14                ; $2E8E  21 E4 0C
        LD A,(HL)                        ; $2E91  7E
        OR A                             ; $2E92  B7
        RET Z                            ; $2E93  C8
        LD B,A                           ; $2E94  47
        DEC HL                           ; $2E95  2B
        LD C,(HL)                        ; $2E96  4E
        LD DE,SUB_0C98_6                 ; $2E97  11 D7 0C
        LD A,(DE)                        ; $2E9A  1A
        OR A                             ; $2E9B  B7
        JP Z,SUB_2B52_1                  ; $2E9C  CA 67 2B
        SUB B                            ; $2E9F  90
        JR NC,SUB_2E8E_2                 ; $2EA0  30 16
        CPL                              ; $2EA2  2F
        INC A                            ; $2EA3  3C
        PUSH AF                          ; $2EA4  F5
        LD C,$08                         ; $2EA5  0E 08
        INC HL                           ; $2EA7  23
        PUSH HL                          ; $2EA8  E5
SUB_2E8E_1:
        LD A,(DE)                        ; $2EA9  1A
        LD B,(HL)                        ; $2EAA  46
        LD (HL),A                        ; $2EAB  77
        LD A,B                           ; $2EAC  78
        LD (DE),A                        ; $2EAD  12
        DEC DE                           ; $2EAE  1B
        DEC HL                           ; $2EAF  2B
        DEC C                            ; $2EB0  0D
        JR NZ,SUB_2E8E_1                 ; $2EB1  20 F6
        POP HL                           ; $2EB3  E1
        LD B,(HL)                        ; $2EB4  46
        DEC HL                           ; $2EB5  2B
        LD C,(HL)                        ; $2EB6  4E
        POP AF                           ; $2EB7  F1
SUB_2E8E_2:
        CP $39                           ; $2EB8  FE 39
        RET NC                           ; $2EBA  D0
        PUSH AF                          ; $2EBB  F5
        CALL SUB_2B52                    ; $2EBC  CD 52 2B
        LD HL,SUB_0C98_11                ; $2EBF  21 DC 0C
        LD B,A                           ; $2EC2  47
        LD A,$00                         ; $2EC3  3E 00
        LD (HL),A                        ; $2EC5  77
        LD (L_0CCF),A                    ; $2EC6  32 CF 0C
        POP AF                           ; $2EC9  F1
        LD HL,SUB_0C98_13                ; $2ECA  21 E3 0C
        CALL SUB_2F84                    ; $2ECD  CD 84 2F
        LD A,(SUB_0C98_11)               ; $2ED0  3A DC 0C
        LD (L_0CCF),A                    ; $2ED3  32 CF 0C
        LD A,B                           ; $2ED6  78
        OR A                             ; $2ED7  B7
        JP P,SUB_2E8E_3                  ; $2ED8  F2 EC 2E
        CALL SUB_2F5B                    ; $2EDB  CD 5B 2F
        JP NC,SUB_2E8E_9                 ; $2EDE  D2 2D 2F
        EX DE,HL                         ; $2EE1  EB
        INC (HL)                         ; $2EE2  34
        JP Z,SUB_3289_15                 ; $2EE3  CA D4 32
        CALL SUB_2FAB                    ; $2EE6  CD AB 2F
        JP SUB_2E8E_9                    ; $2EE9  C3 2D 2F
SUB_2E8E_3:
        LD A,$9E                         ; $2EEC  3E 9E
        CALL SUB_2F5D                    ; $2EEE  CD 5D 2F
        LD HL,SUB_0C98_7                 ; $2EF1  21 D8 0C
        CALL C,SUB_2F72                  ; $2EF4  DC 72 2F
SUB_2E8E_4:
        XOR A                            ; $2EF7  AF
SUB_2E8E_5:
        LD B,A                           ; $2EF8  47
        LD A,(SUB_0C98_5)                ; $2EF9  3A D6 0C
        OR A                             ; $2EFC  B7
        JR NZ,SUB_2E8E_8                 ; $2EFD  20 1E
        LD HL,L_0CCF                     ; $2EFF  21 CF 0C
        LD C,$08                         ; $2F02  0E 08
SUB_2E8E_6:
        LD D,(HL)                        ; $2F04  56
        LD (HL),A                        ; $2F05  77
        LD A,D                           ; $2F06  7A
        INC HL                           ; $2F07  23
        DEC C                            ; $2F08  0D
        JR NZ,SUB_2E8E_6                 ; $2F09  20 F9
        LD A,B                           ; $2F0B  78
        SUB $08                          ; $2F0C  D6 08
        CP $C0                           ; $2F0E  FE C0
        JR NZ,SUB_2E8E_5                 ; $2F10  20 E6
        JP SUB_2874_3                    ; $2F12  C3 87 28
SUB_2E8E_7:
        DEC B                            ; $2F15  05
        LD HL,L_0CCF                     ; $2F16  21 CF 0C
        CALL SUB_2FB2                    ; $2F19  CD B2 2F
        OR A                             ; $2F1C  B7
SUB_2E8E_8:
        JP P,SUB_2E8E_7                  ; $2F1D  F2 15 2F
        LD A,B                           ; $2F20  78
        OR A                             ; $2F21  B7
        JR Z,SUB_2E8E_9                  ; $2F22  28 09
        LD HL,SUB_0C98_6                 ; $2F24  21 D7 0C
        ADD A,(HL)                       ; $2F27  86
        LD (HL),A                        ; $2F28  77
        JP NC,SUB_2874_3                 ; $2F29  D2 87 28
        RET Z                            ; $2F2C  C8
SUB_2E8E_9:
        LD A,(L_0CCF)                    ; $2F2D  3A CF 0C
SUB_2E8E_10:
        OR A                             ; $2F30  B7
        CALL M,SUB_2F3F                  ; $2F31  FC 3F 2F
        LD HL,SUB_0C98_7                 ; $2F34  21 D8 0C
        LD A,(HL)                        ; $2F37  7E
        AND $80                          ; $2F38  E6 80
        DEC HL                           ; $2F3A  2B
        DEC HL                           ; $2F3B  2B
        XOR (HL)                         ; $2F3C  AE
        LD (HL),A                        ; $2F3D  77
        RET                              ; $2F3E  C9
SUB_2F3F:
        LD HL,SUB_0C98_1                 ; $2F3F  21 D0 0C
        LD B,$07                         ; $2F42  06 07
SUB_2F3F_1:
        INC (HL)                         ; $2F44  34
        RET NZ                           ; $2F45  C0
        INC HL                           ; $2F46  23
        DEC B                            ; $2F47  05
        JR NZ,SUB_2F3F_1                 ; $2F48  20 FA
        INC (HL)                         ; $2F4A  34
        JP Z,SUB_3289_15                 ; $2F4B  CA D4 32
        DEC HL                           ; $2F4E  2B
        LD (HL),$80                      ; $2F4F  36 80
        RET                              ; $2F51  C9
SUB_2F3F_2:
        LD DE,L_0D00                     ; $2F52  11 00 0D
        LD HL,SUB_0C98_12                ; $2F55  21 DD 0C
        JP SUB_2F60_1                    ; $2F58  C3 63 2F
SUB_2F5B:
        LD A,$8E                         ; $2F5B  3E 8E
SUB_2F5D:
        LD HL,SUB_0C98_12                ; $2F5D  21 DD 0C
SUB_2F60:
        LD DE,SUB_0C98_1                 ; $2F60  11 D0 0C
SUB_2F60_1:
        LD C,$07                         ; $2F63  0E 07
        LD (SUB_2F60_3),A                ; $2F65  32 6A 2F
        XOR A                            ; $2F68  AF
SUB_2F60_2:
        LD A,(DE)                        ; $2F69  1A
SUB_2F60_3:
        ADC A,(HL)                       ; $2F6A  8E
        LD (DE),A                        ; $2F6B  12
        INC DE                           ; $2F6C  13
        INC HL                           ; $2F6D  23
        DEC C                            ; $2F6E  0D
        JR NZ,SUB_2F60_2                 ; $2F6F  20 F8
        RET                              ; $2F71  C9
SUB_2F72:
        LD A,(HL)                        ; $2F72  7E
        CPL                              ; $2F73  2F
        LD (HL),A                        ; $2F74  77
        LD HL,L_0CCF                     ; $2F75  21 CF 0C
        LD B,$08                         ; $2F78  06 08
        XOR A                            ; $2F7A  AF
        LD C,A                           ; $2F7B  4F
SUB_2F72_1:
        LD A,C                           ; $2F7C  79
        SBC A,(HL)                       ; $2F7D  9E
        LD (HL),A                        ; $2F7E  77
        INC HL                           ; $2F7F  23
        DEC B                            ; $2F80  05
        JR NZ,SUB_2F72_1                 ; $2F81  20 F9
        RET                              ; $2F83  C9
SUB_2F84:
        LD (HL),C                        ; $2F84  71
        PUSH HL                          ; $2F85  E5
SUB_2F84_1:
        SUB $08                          ; $2F86  D6 08
        JR C,SUB_2F8B_2                  ; $2F88  38 0E
        POP HL                           ; $2F8A  E1
SUB_2F8B:
        PUSH HL                          ; $2F8B  E5
        LD DE,SUB_0752_19                ; $2F8C  11 00 08
SUB_2F8B_1:
        LD C,(HL)                        ; $2F8F  4E
        LD (HL),E                        ; $2F90  73
        LD E,C                           ; $2F91  59
        DEC HL                           ; $2F92  2B
        DEC D                            ; $2F93  15
        JR NZ,SUB_2F8B_1                 ; $2F94  20 F9
        JR SUB_2F84_1                    ; $2F96  18 EE
SUB_2F8B_2:
        ADD A,$09                        ; $2F98  C6 09
        LD D,A                           ; $2F9A  57
SUB_2F8B_3:
        XOR A                            ; $2F9B  AF
        POP HL                           ; $2F9C  E1
        DEC D                            ; $2F9D  15
        RET Z                            ; $2F9E  C8
SUB_2F8B_4:
        PUSH HL                          ; $2F9F  E5
        LD E,$08                         ; $2FA0  1E 08
SUB_2F8B_5:
        LD A,(HL)                        ; $2FA2  7E
        RRA                              ; $2FA3  1F
        LD (HL),A                        ; $2FA4  77
        DEC HL                           ; $2FA5  2B
        DEC E                            ; $2FA6  1D
        JR NZ,SUB_2F8B_5                 ; $2FA7  20 F9
        JR SUB_2F8B_3                    ; $2FA9  18 F0
SUB_2FAB:
        LD HL,SUB_0C98_5                 ; $2FAB  21 D6 0C
        LD D,$01                         ; $2FAE  16 01
        JR SUB_2F8B_4                    ; $2FB0  18 ED
SUB_2FB2:
        LD C,$08                         ; $2FB2  0E 08
SUB_2FB2_1:
        LD A,(HL)                        ; $2FB4  7E
        RLA                              ; $2FB5  17
        LD (HL),A                        ; $2FB6  77
        INC HL                           ; $2FB7  23
        DEC C                            ; $2FB8  0D
        JR NZ,SUB_2FB2_1                 ; $2FB9  20 F9
        RET                              ; $2FBB  C9
SUB_2FBC:
        CALL SUB_2AC5                    ; $2FBC  CD C5 2A
        RET Z                            ; $2FBF  C8
        LD A,(SUB_0C98_14)               ; $2FC0  3A E4 0C
SUB_2FBC_1:
        OR A                             ; $2FC3  B7
        JP Z,SUB_2874_3                  ; $2FC4  CA 87 28
        CALL SUB_29E8_16+1               ; $2FC7  CD 7A 2A
        CALL SUB_30F2                    ; $2FCA  CD F2 30
        LD (HL),C                        ; $2FCD  71
        INC DE                           ; $2FCE  13
        LD B,$07                         ; $2FCF  06 07
SUB_2FBC_2:
        LD A,(DE)                        ; $2FD1  1A
        INC DE                           ; $2FD2  13
        OR A                             ; $2FD3  B7
        PUSH DE                          ; $2FD4  D5
        JR Z,SUB_2FBC_5                  ; $2FD5  28 17
        LD C,$08                         ; $2FD7  0E 08
SUB_2FBC_3:
        PUSH BC                          ; $2FD9  C5
        RRA                              ; $2FDA  1F
        LD B,A                           ; $2FDB  47
        CALL C,SUB_2F5B                  ; $2FDC  DC 5B 2F
        CALL SUB_2FAB                    ; $2FDF  CD AB 2F
        LD A,B                           ; $2FE2  78
        POP BC                           ; $2FE3  C1
        DEC C                            ; $2FE4  0D
        JR NZ,SUB_2FBC_3                 ; $2FE5  20 F2
SUB_2FBC_4:
        POP DE                           ; $2FE7  D1
        DEC B                            ; $2FE8  05
        JR NZ,SUB_2FBC_2                 ; $2FE9  20 E6
        JP SUB_2E8E_4                    ; $2FEB  C3 F7 2E
SUB_2FBC_5:
        LD HL,SUB_0C98_5                 ; $2FEE  21 D6 0C
        CALL SUB_2F8B                    ; $2FF1  CD 8B 2F
        JR SUB_2FBC_4                    ; $2FF4  18 F1
L_2FF6:
        DEFB    $CD,$CC,$CC,$CC,$CC,$CC,$4C,$7D,$00              ; $2FF6  "MLLLLLL}"
        DEFB    $00,$00,$00                                      ; $2FFF
L_3002:
        DEFB    $00                                              ; $3002
        DEFW    SUB_1E72_20              ; $3003
        DEFB    $84                                              ; $3005
SUB_3006:
        LD A,(SUB_0C98_6)                ; $3006  3A D7 0C
        CP $41                           ; $3009  FE 41
        JP NC,SUB_3006_2                 ; $300B  D2 1A 30
        LD DE,L_2FF6                     ; $300E  11 F6 2F
        LD HL,SUB_0C98_12                ; $3011  21 DD 0C
        CALL SUB_2B47                    ; $3014  CD 47 2B
SUB_3006_1:
        JP SUB_2FBC                      ; $3017  C3 BC 2F
SUB_3006_2:
        LD A,(SUB_0C98_5)                ; $301A  3A D6 0C
        OR A                             ; $301D  B7
        JP P,SUB_3006_4                  ; $301E  F2 2A 30
SUB_3006_3:
        AND $7F                          ; $3021  E6 7F
        LD (SUB_0C98_5),A                ; $3023  32 D6 0C
        LD HL,SUB_2AEB_1                 ; $3026  21 F4 2A
        PUSH HL                          ; $3029  E5
SUB_3006_4:
        CALL SUB_3066                    ; $302A  CD 66 30
        LD DE,SUB_0C98_1                 ; $302D  11 D0 0C
SUB_3006_5:
        LD HL,SUB_0C98_12                ; $3030  21 DD 0C
        CALL SUB_2B47                    ; $3033  CD 47 2B
        CALL SUB_3066                    ; $3036  CD 66 30
        CALL SUB_2E8E                    ; $3039  CD 8E 2E
        LD DE,SUB_0C98_1                 ; $303C  11 D0 0C
        LD HL,SUB_0C98_12                ; $303F  21 DD 0C
        CALL SUB_2B47                    ; $3042  CD 47 2B
        LD A,$0F                         ; $3045  3E 0F
SUB_3006_6:
        PUSH AF                          ; $3047  F5
        CALL SUB_306E                    ; $3048  CD 6E 30
        CALL SUB_307A                    ; $304B  CD 7A 30
        CALL SUB_2E8E                    ; $304E  CD 8E 2E
        LD HL,SUB_0C98_13                ; $3051  21 E3 0C
        CALL SUB_308B                    ; $3054  CD 8B 30
        POP AF                           ; $3057  F1
        DEC A                            ; $3058  3D
        JP NZ,SUB_3006_6                 ; $3059  C2 47 30
        CALL SUB_3066                    ; $305C  CD 66 30
        CALL SUB_3066                    ; $305F  CD 66 30
        CALL SUB_3066                    ; $3062  CD 66 30
        RET                              ; $3065  C9
SUB_3066:
        LD HL,SUB_0C98_6                 ; $3066  21 D7 0C
        DEC (HL)                         ; $3069  35
        RET NZ                           ; $306A  C0
        JP SUB_2874_3                    ; $306B  C3 87 28
SUB_306E:
        LD HL,SUB_0C98_14                ; $306E  21 E4 0C
        LD A,$04                         ; $3071  3E 04
SUB_306E_1:
        DEC (HL)                         ; $3073  35
        RET Z                            ; $3074  C8
        DEC A                            ; $3075  3D
        JP NZ,SUB_306E_1                 ; $3076  C2 73 30
        RET                              ; $3079  C9
SUB_307A:
        POP DE                           ; $307A  D1
        LD A,$04                         ; $307B  3E 04
        LD HL,SUB_0C98_12                ; $307D  21 DD 0C
SUB_307A_1:
        LD C,(HL)                        ; $3080  4E
        INC HL                           ; $3081  23
        LD B,(HL)                        ; $3082  46
        INC HL                           ; $3083  23
        PUSH BC                          ; $3084  C5
        DEC A                            ; $3085  3D
        JP NZ,SUB_307A_1                 ; $3086  C2 80 30
        PUSH DE                          ; $3089  D5
        RET                              ; $308A  C9
SUB_308B:
        POP DE                           ; $308B  D1
        LD A,$04                         ; $308C  3E 04
        LD HL,SUB_0C98_14                ; $308E  21 E4 0C
SUB_308B_1:
        POP BC                           ; $3091  C1
        LD (HL),B                        ; $3092  70
        DEC HL                           ; $3093  2B
        LD (HL),C                        ; $3094  71
        DEC HL                           ; $3095  2B
        DEC A                            ; $3096  3D
        JP NZ,SUB_308B_1                 ; $3097  C2 91 30
        PUSH DE                          ; $309A  D5
        RET                              ; $309B  C9
SUB_308B_2:
        LD A,(SUB_0C98_14)               ; $309C  3A E4 0C
        OR A                             ; $309F  B7
        JP Z,SUB_3289_18                 ; $30A0  CA E0 32
        LD A,(SUB_0C98_6)                ; $30A3  3A D7 0C
        OR A                             ; $30A6  B7
        JP Z,SUB_2874_3                  ; $30A7  CA 87 28
        CALL SUB_29E8_15                 ; $30AA  CD 77 2A
SUB_308B_3:
        INC (HL)                         ; $30AD  34
        INC (HL)                         ; $30AE  34
        JP Z,SUB_3289_15                 ; $30AF  CA D4 32
        CALL SUB_30F2                    ; $30B2  CD F2 30
        LD HL,$0D07                      ; $30B5  21 07 0D
        LD (HL),C                        ; $30B8  71
SUB_308B_4:
        LD B,C                           ; $30B9  41
        LD A,$9E                         ; $30BA  3E 9E
        CALL SUB_2F3F_2                  ; $30BC  CD 52 2F
        LD A,(DE)                        ; $30BF  1A
        SBC A,C                          ; $30C0  99
        CCF                              ; $30C1  3F
        JR C,SUB_308B_6+1                ; $30C2  38 07
        LD A,$8E                         ; $30C4  3E 8E
SUB_308B_5:
        CALL SUB_2F3F_2                  ; $30C6  CD 52 2F
        XOR A                            ; $30C9  AF
SUB_308B_6:
        JP C,SUB_0100_28                 ; $30CA  DA 12 04
        LD A,(SUB_0C98_5)                ; $30CD  3A D6 0C
        INC A                            ; $30D0  3C
        DEC A                            ; $30D1  3D
        RRA                              ; $30D2  1F
        JP M,SUB_2E8E_10                 ; $30D3  FA 30 2F
        RLA                              ; $30D6  17
        LD HL,SUB_0C98_1                 ; $30D7  21 D0 0C
        LD C,$07                         ; $30DA  0E 07
        DEFB    $CD,$B4,$2F,$21,$00                              ; $30DC  "M4/!"
        DEFB    $0D,$CD                                          ; $30E1
        DEFW    SUB_2FB2                 ; $30E3
        DEFB    $78,$B7,$20                                      ; $30E5
        DEFW    SUB_2124_22              ; $30E8
        DEFW    SUB_0C98_6               ; $30EA
        DEFB    $35,$20,$CB,$C3                                  ; $30EC
        DEFW    SUB_2874_3               ; $30F0
SUB_30F2:
        LD A,C                           ; $30F2  79
        LD (SUB_0C98_13),A               ; $30F3  32 E3 0C
        DEC HL                           ; $30F6  2B
        LD DE,SUB_0D04_1                 ; $30F7  11 06 0D
        LD BC,SUB_064E_11                ; $30FA  01 00 07
SUB_30F2_1:
        LD A,(HL)                        ; $30FD  7E
SUB_30F2_2:
        LD (DE),A                        ; $30FE  12
        LD (HL),C                        ; $30FF  71
        DEC DE                           ; $3100  1B
        DEC HL                           ; $3101  2B
        DEC B                            ; $3102  05
        JR NZ,SUB_30F2_1                 ; $3103  20 F8
        RET                              ; $3105  C9
SUB_3106:
        CALL SUB_2B6F                    ; $3106  CD 6F 2B
        EX DE,HL                         ; $3109  EB
        DEC HL                           ; $310A  2B
        LD A,(HL)                        ; $310B  7E
        OR A                             ; $310C  B7
        RET Z                            ; $310D  C8
        ADD A,$02                        ; $310E  C6 02
        JP C,SUB_3289_15                 ; $3110  DA D4 32
        LD (HL),A                        ; $3113  77
        PUSH HL                          ; $3114  E5
        CALL SUB_2E8E                    ; $3115  CD 8E 2E
        POP HL                           ; $3118  E1
        INC (HL)                         ; $3119  34
        RET NZ                           ; $311A  C0
        JP SUB_3289_15                   ; $311B  C3 D4 32
SUB_311E:
        CALL SUB_2874_3                  ; $311E  CD 87 28
        CALL SUB_2CAB                    ; $3121  CD AB 2C
SUB_311E_1:
        OR $AF                           ; $3124  F6 AF
        LD BC,SUB_24D1_10                ; $3126  01 4C 25
        PUSH BC                          ; $3129  C5
        PUSH AF                          ; $312A  F5
        LD A,$01                         ; $312B  3E 01
        LD (SUB_0C98_8),A                ; $312D  32 D9 0C
        POP AF                           ; $3130  F1
        EX DE,HL                         ; $3131  EB
        LD BC,$00FF                      ; $3132  01 FF 00
        LD H,B                           ; $3135  60
        LD L,B                           ; $3136  68
        CALL Z,SUB_2C55                  ; $3137  CC 55 2C
        EX DE,HL                         ; $313A  EB
        LD A,(HL)                        ; $313B  7E
        CP $26                           ; $313C  FE 26
        JP Z,SUB_1CF6                    ; $313E  CA F6 1C
        CP $2D                           ; $3141  FE 2D
        PUSH AF                          ; $3143  F5
        JP Z,SUB_311E_2                  ; $3144  CA 4C 31
        CP $2B                           ; $3147  FE 2B
        JR Z,SUB_311E_2                  ; $3149  28 01
        DEC HL                           ; $314B  2B
SUB_311E_2:
        CALL SUB_13E4                    ; $314C  CD E4 13
        JP C,SUB_3212_3                  ; $314F  DA 25 32
        CP $2E                           ; $3152  FE 2E
        JP Z,SUB_311E_11                 ; $3154  CA CE 31
        CP $65                           ; $3157  FE 65
        JR Z,SUB_311E_3                  ; $3159  28 02
        CP $45                           ; $315B  FE 45
SUB_311E_3:
        JP NZ,SUB_311E_6                 ; $315D  C2 81 31
        PUSH HL                          ; $3160  E5
        CALL SUB_13E4                    ; $3161  CD E4 13
        CP $6C                           ; $3164  FE 6C
        JR Z,SUB_311E_4                  ; $3166  28 0A
        CP $4C                           ; $3168  FE 4C
        JR Z,SUB_311E_4                  ; $316A  28 06
        CP $71                           ; $316C  FE 71
        JR Z,SUB_311E_4                  ; $316E  28 02
        CP $51                           ; $3170  FE 51
SUB_311E_4:
        POP HL                           ; $3172  E1
        JR Z,SUB_311E_5                  ; $3173  28 0B
        LD A,(SUB_0B2A_5)                ; $3175  3A 37 0B
        CP $08                           ; $3178  FE 08
        JR Z,SUB_311E_7                  ; $317A  28 1C
        LD A,$00                         ; $317C  3E 00
        JR SUB_311E_7                    ; $317E  18 18
SUB_311E_5:
        LD A,(HL)                        ; $3180  7E
SUB_311E_6:
        CP $25                           ; $3181  FE 25
        JP Z,SUB_311E_12                 ; $3183  CA DA 31
        CP $23                           ; $3186  FE 23
        JP Z,SUB_311E_13                 ; $3188  CA EA 31
        CP $21                           ; $318B  FE 21
        JP Z,SUB_311E_14                 ; $318D  CA EB 31
        CP $64                           ; $3190  FE 64
        JR Z,SUB_311E_7                  ; $3192  28 04
        CP $44                           ; $3194  FE 44
        JR NZ,SUB_311E_9                 ; $3196  20 16
SUB_311E_7:
        OR A                             ; $3198  B7
        CALL SUB_31F3                    ; $3199  CD F3 31
        CALL SUB_13E4                    ; $319C  CD E4 13
        CALL SUB_1DB2                    ; $319F  CD B2 1D
SUB_311E_8:
        CALL SUB_13E4                    ; $31A2  CD E4 13
        JP C,SUB_3289_2                  ; $31A5  DA 94 32
        INC D                            ; $31A8  14
        JR NZ,SUB_311E_9                 ; $31A9  20 03
        XOR A                            ; $31AB  AF
        SUB E                            ; $31AC  93
        LD E,A                           ; $31AD  5F
SUB_311E_9:
        PUSH HL                          ; $31AE  E5
        LD A,E                           ; $31AF  7B
        SUB B                            ; $31B0  90
        LD E,A                           ; $31B1  5F
SUB_311E_10:
        CALL P,SUB_3202                  ; $31B2  F4 02 32
        CALL M,SUB_3212                  ; $31B5  FC 12 32
        JR NZ,SUB_311E_10                ; $31B8  20 F8
        POP HL                           ; $31BA  E1
        POP AF                           ; $31BB  F1
        PUSH HL                          ; $31BC  E5
        CALL Z,SUB_2AEB                  ; $31BD  CC EB 2A
        POP HL                           ; $31C0  E1
        CALL SUB_1DE3                    ; $31C1  CD E3 1D
        RET PE                           ; $31C4  E8
        PUSH HL                          ; $31C5  E5
        LD HL,SUB_2990_7                 ; $31C6  21 E1 29
        PUSH HL                          ; $31C9  E5
        CALL SUB_2C5E                    ; $31CA  CD 5E 2C
        RET                              ; $31CD  C9
SUB_311E_11:
        CALL SUB_1DE3                    ; $31CE  CD E3 1D
        INC C                            ; $31D1  0C
        JR NZ,SUB_311E_9                 ; $31D2  20 DA
        CALL C,SUB_31F3                  ; $31D4  DC F3 31
        JP SUB_311E_2                    ; $31D7  C3 4C 31
SUB_311E_12:
        CALL SUB_13E4                    ; $31DA  CD E4 13
        POP AF                           ; $31DD  F1
        PUSH HL                          ; $31DE  E5
        LD HL,SUB_2990_7                 ; $31DF  21 E1 29
        PUSH HL                          ; $31E2  E5
        LD HL,SUB_2BF4                   ; $31E3  21 F4 2B
        PUSH HL                          ; $31E6  E5
        PUSH AF                          ; $31E7  F5
        JR SUB_311E_9                    ; $31E8  18 C4
SUB_311E_13:
        OR A                             ; $31EA  B7
SUB_311E_14:
        CALL SUB_31F3                    ; $31EB  CD F3 31
        CALL SUB_13E4                    ; $31EE  CD E4 13
        JR SUB_311E_9                    ; $31F1  18 BB
SUB_31F3:
        PUSH HL                          ; $31F3  E5
        PUSH DE                          ; $31F4  D5
        PUSH BC                          ; $31F5  C5
        PUSH AF                          ; $31F6  F5
        CALL Z,SUB_2C6C                  ; $31F7  CC 6C 2C
        POP AF                           ; $31FA  F1
        CALL NZ,SUB_2C98                 ; $31FB  C4 98 2C
        POP BC                           ; $31FE  C1
        POP DE                           ; $31FF  D1
SUB_31F3_1:
        POP HL                           ; $3200  E1
SUB_31F3_2:
        RET                              ; $3201  C9
SUB_3202:
        RET Z                            ; $3202  C8
SUB_3203:
        PUSH AF                          ; $3203  F5
SUB_3203_1:
        CALL SUB_1DE3                    ; $3204  CD E3 1D
        PUSH AF                          ; $3207  F5
        CALL PO,SUB_2AAE                 ; $3208  E4 AE 2A
        POP AF                           ; $320B  F1
        CALL PE,SUB_3106                 ; $320C  EC 06 31
        POP AF                           ; $320F  F1
SUB_3210:
        DEC A                            ; $3210  3D
        RET                              ; $3211  C9
SUB_3212:
        PUSH DE                          ; $3212  D5
        PUSH HL                          ; $3213  E5
SUB_3212_1:
        PUSH AF                          ; $3214  F5
        CALL SUB_1DE3                    ; $3215  CD E3 1D
        PUSH AF                          ; $3218  F5
        CALL PO,SUB_29E8                 ; $3219  E4 E8 29
        POP AF                           ; $321C  F1
SUB_3212_2:
        CALL PE,SUB_3006                 ; $321D  EC 06 30
        POP AF                           ; $3220  F1
        POP HL                           ; $3221  E1
        POP DE                           ; $3222  D1
        INC A                            ; $3223  3C
        RET                              ; $3224  C9
SUB_3212_3:
        PUSH DE                          ; $3225  D5
SUB_3212_4:
        LD A,B                           ; $3226  78
SUB_3212_5:
        ADC A,C                          ; $3227  89
        LD B,A                           ; $3228  47
        PUSH BC                          ; $3229  C5
        PUSH HL                          ; $322A  E5
        LD A,(HL)                        ; $322B  7E
        SUB $30                          ; $322C  D6 30
        PUSH AF                          ; $322E  F5
        CALL SUB_1DE3                    ; $322F  CD E3 1D
        JP P,SUB_3248_4                  ; $3232  F2 5D 32
        LD HL,(SUB_0C98_4)               ; $3235  2A D4 0C
        LD DE,L_0CCD                     ; $3238  11 CD 0C
SUB_3212_6:
        CALL SUB_459D                    ; $323B  CD 9D 45
        JR NC,SUB_3248_3                 ; $323E  30 19
        LD D,H                           ; $3240  54
        LD E,L                           ; $3241  5D
        ADD HL,HL                        ; $3242  29
        ADD HL,HL                        ; $3243  29
        ADD HL,DE                        ; $3244  19
        ADD HL,HL                        ; $3245  29
        POP AF                           ; $3246  F1
        LD C,A                           ; $3247  4F
SUB_3248:
        ADD HL,BC                        ; $3248  09
        LD A,H                           ; $3249  7C
        OR A                             ; $324A  B7
        JP M,SUB_3248_2                  ; $324B  FA 57 32
        LD (SUB_0C98_4),HL               ; $324E  22 D4 0C
SUB_3248_1:
        POP HL                           ; $3251  E1
        POP BC                           ; $3252  C1
        POP DE                           ; $3253  D1
        JP SUB_311E_2                    ; $3254  C3 4C 31
SUB_3248_2:
        LD A,C                           ; $3257  79
        PUSH AF                          ; $3258  F5
SUB_3248_3:
        CALL SUB_2C89                    ; $3259  CD 89 2C
        SCF                              ; $325C  37
SUB_3248_4:
        JR NC,SUB_3248_6                 ; $325D  30 18
        LD BC,$9474                      ; $325F  01 74 94
        LD DE,L_2400                     ; $3262  11 00 24
        CALL SUB_2B81                    ; $3265  CD 81 2B
        JP P,SUB_3248_5                  ; $3268  F2 74 32
        CALL SUB_2AAE                    ; $326B  CD AE 2A
        POP AF                           ; $326E  F1
        CALL SUB_3289                    ; $326F  CD 89 32
        JR SUB_3248_1                    ; $3272  18 DD
SUB_3248_5:
        CALL SUB_2CA2                    ; $3274  CD A2 2C
SUB_3248_6:
        CALL SUB_3106                    ; $3277  CD 06 31
SUB_3248_7:
        CALL SUB_2B6F                    ; $327A  CD 6F 2B
        POP AF                           ; $327D  F1
        CALL SUB_2AD4                    ; $327E  CD D4 2A
        CALL SUB_2CA2                    ; $3281  CD A2 2C
        CALL SUB_2E8E                    ; $3284  CD 8E 2E
        JR SUB_3248_1                    ; $3287  18 C8
SUB_3289:
        CALL SUB_2B18                    ; $3289  CD 18 2B
        CALL SUB_2AD4                    ; $328C  CD D4 2A
SUB_3289_1:
        POP BC                           ; $328F  C1
        POP DE                           ; $3290  D1
        JP SUB_2824                      ; $3291  C3 24 28
SUB_3289_2:
        LD A,E                           ; $3294  7B
        CP $0A                           ; $3295  FE 0A
        JR NC,SUB_3289_4+1               ; $3297  30 09
        RLCA                             ; $3299  07
        RLCA                             ; $329A  07
SUB_3289_3:
        ADD A,E                          ; $329B  83
        RLCA                             ; $329C  07
        ADD A,(HL)                       ; $329D  86
        SUB $30                          ; $329E  D6 30
        LD E,A                           ; $32A0  5F
SUB_3289_4:
        JP M,$7F1E                       ; $32A1  FA 1E 7F
SUB_3289_5:
        JP SUB_311E_8                    ; $32A4  C3 A2 31
SUB_3289_6:
        OR A                             ; $32A7  B7
        JP SUB_3289_24                   ; $32A8  C3 09 33
        DEFB    $F1                                              ; $32AB
SUB_3289_7:
        PUSH HL                          ; $32AC  E5
        LD HL,SUB_0C98_5                 ; $32AD  21 D6 0C
        CALL SUB_1DE3                    ; $32B0  CD E3 1D
SUB_3289_8:
        JP PO,SUB_3289_9                 ; $32B3  E2 BC 32
        LD A,(SUB_0C98_13)               ; $32B6  3A E3 0C
        JP SUB_3289_10                   ; $32B9  C3 BD 32
SUB_3289_9:
        LD A,C                           ; $32BC  79
SUB_3289_10:
        XOR (HL)                         ; $32BD  AE
        RLA                              ; $32BE  17
        POP HL                           ; $32BF  E1
        JP SUB_3289_24                   ; $32C0  C3 09 33
SUB_3289_11:
        LD A,(SUB_0C98_7)                ; $32C3  3A D8 0C
        JP SUB_3289_16                   ; $32C6  C3 D8 32
        DEFB    $F1                                              ; $32C9
SUB_3289_12:
        POP AF                           ; $32CA  F1
        POP AF                           ; $32CB  F1
SUB_3289_13:
        LD A,(SUB_0C98_5)                ; $32CC  3A D6 0C
        RLA                              ; $32CF  17
        JP SUB_3289_24                   ; $32D0  C3 09 33
SUB_3289_14:
        POP AF                           ; $32D3  F1
SUB_3289_15:
        LD A,(SUB_0C98_7)                ; $32D4  3A D8 0C
        CPL                              ; $32D7  2F
SUB_3289_16:
        RLA                              ; $32D8  17
        JP SUB_3289_24                   ; $32D9  C3 09 33
SUB_3289_17:
        LD A,C                           ; $32DC  79
        JP SUB_3289_23                   ; $32DD  C3 02 33
SUB_3289_18:
        PUSH HL                          ; $32E0  E5
SUB_3289_19:
        PUSH DE                          ; $32E1  D5
        LD HL,SUB_0C98_1                 ; $32E2  21 D0 0C
SUB_3289_20:
        LD DE,SUB_3289_32                ; $32E5  11 85 33
        CALL SUB_2B42                    ; $32E8  CD 42 2B
        LD A,(SUB_3289_32)               ; $32EB  3A 85 33
        LD (SUB_0C98_2),A                ; $32EE  32 D2 0C
        CALL SUB_1DE3                    ; $32F1  CD E3 1D
        JP PO,SUB_3289_21                ; $32F4  E2 FD 32
        LD A,(SUB_0C98_5)                ; $32F7  3A D6 0C
        JP SUB_3289_22                   ; $32FA  C3 00 33
SUB_3289_21:
        LD A,(SUB_0C98_13)               ; $32FD  3A E3 0C
SUB_3289_22:
        POP DE                           ; $3300  D1
        POP HL                           ; $3301  E1
SUB_3289_23:
        RLA                              ; $3302  17
        LD HL,L_05D0                     ; $3303  21 D0 05
        LD (SUB_0752_45),HL              ; $3306  22 6B 08
SUB_3289_24:
        PUSH HL                          ; $3309  E5
        PUSH BC                          ; $330A  C5
        PUSH DE                          ; $330B  D5
        PUSH AF                          ; $330C  F5
        PUSH AF                          ; $330D  F5
        LD HL,(SUB_0B2A_35)              ; $330E  2A 89 0B
        LD A,H                           ; $3311  7C
        OR L                             ; $3312  B5
        JP NZ,SUB_3289_27                ; $3313  C2 3A 33
        LD A,(SUB_0C98_8)                ; $3316  3A D9 0C
        OR A                             ; $3319  B7
        JP Z,SUB_3289_26                 ; $331A  CA 27 33
SUB_3289_25:
        CP $01                           ; $331D  FE 01
        JP NZ,SUB_3289_27                ; $331F  C2 3A 33
        LD A,$02                         ; $3322  3E 02
        LD (SUB_0C98_8),A                ; $3324  32 D9 0C
SUB_3289_26:
        LD HL,(SUB_0752_45)              ; $3327  2A 6B 08
        CALL SUB_246A                    ; $332A  CD 6A 24
        LD (SUB_0B2A_2),A                ; $332D  32 34 0B
        LD A,$0D                         ; $3330  3E 0D
        CALL SUB_2474                    ; $3332  CD 74 24
        LD A,$0A                         ; $3335  3E 0A
        CALL SUB_2474                    ; $3337  CD 74 24
SUB_3289_27:
        POP AF                           ; $333A  F1
        LD HL,SUB_0C98_4                 ; $333B  21 D4 0C
        LD DE,SUB_3289_31                ; $333E  11 81 33
        JP NC,SUB_3289_28                ; $3341  D2 47 33
        LD DE,SUB_3289_32                ; $3344  11 85 33
SUB_3289_28:
        CALL SUB_2B42                    ; $3347  CD 42 2B
        CALL SUB_1DE3                    ; $334A  CD E3 1D
        JP PO,SUB_3289_29                ; $334D  E2 59 33
        LD HL,SUB_0C98_1                 ; $3350  21 D0 0C
        LD DE,SUB_3289_32                ; $3353  11 85 33
        CALL SUB_2B42                    ; $3356  CD 42 2B
SUB_3289_29:
        LD HL,(SUB_0B2A_35)              ; $3359  2A 89 0B
        LD A,H                           ; $335C  7C
        OR L                             ; $335D  B5
        JP Z,SUB_3289_30                 ; $335E  CA 76 33
        LD HL,(SUB_0752_45)              ; $3361  2A 6B 08
        LD DE,L_0577                     ; $3364  11 77 05
        CALL SUB_459D                    ; $3367  CD 9D 45
        LD HL,L_0577                     ; $336A  21 77 05
        LD (SUB_0752_45),HL              ; $336D  22 6B 08
        JP Z,SUB_0D20_25+1               ; $3370  CA A4 0D
        JP SUB_0D20_21+1                 ; $3373  C3 95 0D
SUB_3289_30:
        POP AF                           ; $3376  F1
        LD HL,L_0577                     ; $3377  21 77 05
        LD (SUB_0752_45),HL              ; $337A  22 6B 08
        POP DE                           ; $337D  D1
        POP BC                           ; $337E  C1
        POP HL                           ; $337F  E1
        RET                              ; $3380  C9
SUB_3289_31:
        RST $38                          ; $3381  FF
        RST $38                          ; $3382  FF
        LD A,A                           ; $3383  7F
        RST $38                          ; $3384  FF
SUB_3289_32:
        RST $38                          ; $3385  FF
        RST $38                          ; $3386  FF
        RST $38                          ; $3387  FF
        RST $38                          ; $3388  FF
SUB_3389:
        PUSH HL                          ; $3389  E5
        LD HL,SUB_0D04_3                 ; $338A  21 10 0D
        CALL SUB_48BE                    ; $338D  CD BE 48
        POP HL                           ; $3390  E1
SUB_3391:
        LD BC,SUB_486C_8                 ; $3391  01 BD 48
        PUSH BC                          ; $3394  C5
        CALL SUB_2C55                    ; $3395  CD 55 2C
        XOR A                            ; $3398  AF
        CALL SUB_341F                    ; $3399  CD 1F 34
        OR (HL)                          ; $339C  B6
        JP SUB_33A1_3                    ; $339D  C3 BC 33
SUB_33A0:
        XOR A                            ; $33A0  AF
SUB_33A1:
        CALL SUB_341F                    ; $33A1  CD 1F 34
SUB_33A1_1:
        AND $08                          ; $33A4  E6 08
        JR Z,SUB_33A1_2                  ; $33A6  28 02
        LD (HL),$2B                      ; $33A8  36 2B
SUB_33A1_2:
        EX DE,HL                         ; $33AA  EB
        CALL SUB_2B06                    ; $33AB  CD 06 2B
        EX DE,HL                         ; $33AE  EB
        JP P,SUB_33A1_3                  ; $33AF  F2 BC 33
        LD (HL),$2D                      ; $33B2  36 2D
        PUSH BC                          ; $33B4  C5
        PUSH HL                          ; $33B5  E5
        CALL SUB_2AEB                    ; $33B6  CD EB 2A
        POP HL                           ; $33B9  E1
        POP BC                           ; $33BA  C1
        OR H                             ; $33BB  B4
SUB_33A1_3:
        INC HL                           ; $33BC  23
        LD (HL),$30                      ; $33BD  36 30
        LD A,(SUB_0B2A_20)               ; $33BF  3A 6D 0B
        LD D,A                           ; $33C2  57
        RLA                              ; $33C3  17
        LD A,(SUB_0B2A_5)                ; $33C4  3A 37 0B
        JP C,SUB_3518_6                  ; $33C7  DA 40 35
        JP Z,SUB_3518_4                  ; $33CA  CA 38 35
SUB_33A1_4:
        CP $04                           ; $33CD  FE 04
        JP NC,SUB_341F_2                 ; $33CF  D2 28 34
        LD BC,$0000                      ; $33D2  01 00 00
        CALL SUB_3809                    ; $33D5  CD 09 38
SUB_33D8:
        LD HL,L_0CE6                     ; $33D8  21 E6 0C
        LD B,(HL)                        ; $33DB  46
        LD C,$20                         ; $33DC  0E 20
        LD A,(SUB_0B2A_20)               ; $33DE  3A 6D 0B
        LD E,A                           ; $33E1  5F
        AND $20                          ; $33E2  E6 20
        JR Z,SUB_33D8_1                  ; $33E4  28 0D
        LD A,B                           ; $33E6  78
        CP C                             ; $33E7  B9
        LD C,$2A                         ; $33E8  0E 2A
        JR NZ,SUB_33D8_1                 ; $33EA  20 07
        LD A,E                           ; $33EC  7B
        AND $04                          ; $33ED  E6 04
        JP NZ,SUB_33D8_1                 ; $33EF  C2 F3 33
        LD B,C                           ; $33F2  41
SUB_33D8_1:
        LD (HL),C                        ; $33F3  71
        CALL SUB_13E4                    ; $33F4  CD E4 13
        JR Z,SUB_33D8_2                  ; $33F7  28 14
        CP $45                           ; $33F9  FE 45
        JR Z,SUB_33D8_2                  ; $33FB  28 10
        CP $44                           ; $33FD  FE 44
        JR Z,SUB_33D8_2                  ; $33FF  28 0C
        CP $30                           ; $3401  FE 30
        JR Z,SUB_33D8_1                  ; $3403  28 EE
        CP $2C                           ; $3405  FE 2C
        JR Z,SUB_33D8_1                  ; $3407  28 EA
        CP $2E                           ; $3409  FE 2E
        JR NZ,SUB_33D8_3                 ; $340B  20 03
SUB_33D8_2:
        DEC HL                           ; $340D  2B
        LD (HL),$30                      ; $340E  36 30
SUB_33D8_3:
        LD A,E                           ; $3410  7B
        AND $10                          ; $3411  E6 10
        JR Z,SUB_3415_1                  ; $3413  28 03
SUB_3415:
        DEC HL                           ; $3415  2B
        LD (HL),$24                      ; $3416  36 24
SUB_3415_1:
        LD A,E                           ; $3418  7B
        AND $04                          ; $3419  E6 04
        RET NZ                           ; $341B  C0
        DEC HL                           ; $341C  2B
        LD (HL),B                        ; $341D  70
SUB_3415_2:
        RET                              ; $341E  C9
SUB_341F:
        LD (SUB_0B2A_20),A               ; $341F  32 6D 0B
SUB_341F_1:
        LD HL,L_0CE6                     ; $3422  21 E6 0C
        LD (HL),$20                      ; $3425  36 20
        RET                              ; $3427  C9
SUB_341F_2:
        CALL SUB_2B18                    ; $3428  CD 18 2B
        EX DE,HL                         ; $342B  EB
        LD HL,(SUB_0C98_1)               ; $342C  2A D0 0C
        PUSH HL                          ; $342F  E5
        LD HL,(SUB_0C98_2)               ; $3430  2A D2 0C
        PUSH HL                          ; $3433  E5
        EX DE,HL                         ; $3434  EB
        PUSH AF                          ; $3435  F5
        XOR A                            ; $3436  AF
        LD (SUB_0C98_10),A               ; $3437  32 DB 0C
        POP AF                           ; $343A  F1
        PUSH AF                          ; $343B  F5
        CALL SUB_34D3                    ; $343C  CD D3 34
        LD B,$45                         ; $343F  06 45
        LD C,$00                         ; $3441  0E 00
SUB_341F_3:
        PUSH HL                          ; $3443  E5
        LD A,(HL)                        ; $3444  7E
SUB_341F_4:
        CP B                             ; $3445  B8
        JP Z,SUB_341F_7                  ; $3446  CA 74 34
        CP $3A                           ; $3449  FE 3A
        JP NC,SUB_341F_5                 ; $344B  D2 54 34
        CP $30                           ; $344E  FE 30
        JP C,SUB_341F_5                  ; $3450  DA 54 34
        INC C                            ; $3453  0C
SUB_341F_5:
        INC HL                           ; $3454  23
        LD A,(HL)                        ; $3455  7E
        OR A                             ; $3456  B7
        JP NZ,SUB_341F_4                 ; $3457  C2 45 34
        LD A,$44                         ; $345A  3E 44
        CP B                             ; $345C  B8
        LD B,A                           ; $345D  47
        POP HL                           ; $345E  E1
        LD C,$00                         ; $345F  0E 00
        JP NZ,SUB_341F_3                 ; $3461  C2 43 34
SUB_341F_6:
        POP AF                           ; $3464  F1
        POP BC                           ; $3465  C1
        POP DE                           ; $3466  D1
        EX DE,HL                         ; $3467  EB
        LD (SUB_0C98_1),HL               ; $3468  22 D0 0C
        LD H,B                           ; $346B  60
        LD L,C                           ; $346C  69
        LD (SUB_0C98_2),HL               ; $346D  22 D2 0C
        EX DE,HL                         ; $3470  EB
        POP BC                           ; $3471  C1
        POP DE                           ; $3472  D1
        RET                              ; $3473  C9
SUB_341F_7:
        PUSH BC                          ; $3474  C5
        LD B,$00                         ; $3475  06 00
        INC HL                           ; $3477  23
        LD A,(HL)                        ; $3478  7E
SUB_341F_8:
        CP $2B                           ; $3479  FE 2B
        JP Z,SUB_341F_12                 ; $347B  CA BB 34
        CP $2D                           ; $347E  FE 2D
        JP Z,SUB_341F_9                  ; $3480  CA 92 34
        SUB $30                          ; $3483  D6 30
        LD C,A                           ; $3485  4F
        LD A,B                           ; $3486  78
        ADD A,A                          ; $3487  87
        ADD A,A                          ; $3488  87
        ADD A,B                          ; $3489  80
        ADD A,A                          ; $348A  87
        ADD A,C                          ; $348B  81
        LD B,A                           ; $348C  47
        CP $10                           ; $348D  FE 10
        JP NC,SUB_341F_12                ; $348F  D2 BB 34
SUB_341F_9:
        INC HL                           ; $3492  23
        LD A,(HL)                        ; $3493  7E
        OR A                             ; $3494  B7
        JP NZ,SUB_341F_8                 ; $3495  C2 79 34
        LD H,B                           ; $3498  60
        POP BC                           ; $3499  C1
        LD A,B                           ; $349A  78
        CP $45                           ; $349B  FE 45
        JP NZ,SUB_341F_11                ; $349D  C2 B0 34
        LD A,C                           ; $34A0  79
        ADD A,H                          ; $34A1  84
        CP $09                           ; $34A2  FE 09
        POP HL                           ; $34A4  E1
        JP NC,SUB_341F_6                 ; $34A5  D2 64 34
SUB_341F_10:
        LD A,$80                         ; $34A8  3E 80
        LD (SUB_0C98_10),A               ; $34AA  32 DB 0C
        JP SUB_341F_13                   ; $34AD  C3 C0 34
SUB_341F_11:
        LD A,H                           ; $34B0  7C
        ADD A,C                          ; $34B1  81
        CP $12                           ; $34B2  FE 12
        POP HL                           ; $34B4  E1
        JP NC,SUB_341F_6                 ; $34B5  D2 64 34
        JP SUB_341F_10                   ; $34B8  C3 A8 34
SUB_341F_12:
        POP BC                           ; $34BB  C1
        POP HL                           ; $34BC  E1
        JP SUB_341F_6                    ; $34BD  C3 64 34
SUB_341F_13:
        POP AF                           ; $34C0  F1
        POP BC                           ; $34C1  C1
        POP DE                           ; $34C2  D1
        EX DE,HL                         ; $34C3  EB
        LD (SUB_0C98_1),HL               ; $34C4  22 D0 0C
        LD H,B                           ; $34C7  60
        LD L,C                           ; $34C8  69
        LD (SUB_0C98_2),HL               ; $34C9  22 D2 0C
        EX DE,HL                         ; $34CC  EB
        POP BC                           ; $34CD  C1
        POP DE                           ; $34CE  D1
        CALL SUB_2B28                    ; $34CF  CD 28 2B
        INC HL                           ; $34D2  23
SUB_34D3:
        CP $05                           ; $34D3  FE 05
        PUSH HL                          ; $34D5  E5
        SBC A,$00                        ; $34D6  DE 00
        RLA                              ; $34D8  17
        LD D,A                           ; $34D9  57
        INC D                            ; $34DA  14
        CALL SUB_36BA                    ; $34DB  CD BA 36
        LD BC,L_0300                     ; $34DE  01 00 03
        PUSH AF                          ; $34E1  F5
        LD A,(SUB_0C98_10)               ; $34E2  3A DB 0C
        OR A                             ; $34E5  B7
        JP P,SUB_34D3_1                  ; $34E6  F2 EE 34
        POP AF                           ; $34E9  F1
        ADD A,D                          ; $34EA  82
        JP SUB_34D3_2                    ; $34EB  C3 F7 34
SUB_34D3_1:
        POP AF                           ; $34EE  F1
        ADD A,D                          ; $34EF  82
        JP M,SUB_34D3_3                  ; $34F0  FA FB 34
        INC D                            ; $34F3  14
        CP D                             ; $34F4  BA
        JR NC,SUB_34D3_3                 ; $34F5  30 04
SUB_34D3_2:
        INC A                            ; $34F7  3C
        LD B,A                           ; $34F8  47
        LD A,$02                         ; $34F9  3E 02
SUB_34D3_3:
        SUB $02                          ; $34FB  D6 02
        POP HL                           ; $34FD  E1
        PUSH AF                          ; $34FE  F5
        CALL SUB_3751                    ; $34FF  CD 51 37
        LD (HL),$30                      ; $3502  36 30
SUB_34D3_4:
        CALL Z,SUB_2B3D                  ; $3504  CC 3D 2B
        CALL SUB_3777                    ; $3507  CD 77 37
SUB_34D3_5:
        DEC HL                           ; $350A  2B
        LD A,(HL)                        ; $350B  7E
        CP $30                           ; $350C  FE 30
        JR Z,SUB_34D3_5                  ; $350E  28 FA
        CP $2E                           ; $3510  FE 2E
        CALL NZ,SUB_2B3D                 ; $3512  C4 3D 2B
        POP AF                           ; $3515  F1
        JR Z,SUB_3518_5                  ; $3516  28 21
SUB_3518:
        PUSH AF                          ; $3518  F5
        CALL SUB_1DE3                    ; $3519  CD E3 1D
        LD A,$22                         ; $351C  3E 22
SUB_3518_1:
        ADC A,A                          ; $351E  8F
        LD (HL),A                        ; $351F  77
        INC HL                           ; $3520  23
        POP AF                           ; $3521  F1
        LD (HL),$2B                      ; $3522  36 2B
        JP P,SUB_3518_2                  ; $3524  F2 2B 35
        LD (HL),$2D                      ; $3527  36 2D
        CPL                              ; $3529  2F
        INC A                            ; $352A  3C
SUB_3518_2:
        LD B,$2F                         ; $352B  06 2F
SUB_3518_3:
        INC B                            ; $352D  04
        SUB $0A                          ; $352E  D6 0A
        JR NC,SUB_3518_3                 ; $3530  30 FB
        ADD A,$3A                        ; $3532  C6 3A
        INC HL                           ; $3534  23
        LD (HL),B                        ; $3535  70
        INC HL                           ; $3536  23
        LD (HL),A                        ; $3537  77
SUB_3518_4:
        INC HL                           ; $3538  23
SUB_3518_5:
        LD (HL),$00                      ; $3539  36 00
        EX DE,HL                         ; $353B  EB
        LD HL,L_0CE6                     ; $353C  21 E6 0C
        RET                              ; $353F  C9
SUB_3518_6:
        INC HL                           ; $3540  23
        PUSH BC                          ; $3541  C5
        CP $04                           ; $3542  FE 04
        LD A,D                           ; $3544  7A
        JP NC,SUB_3518_15                ; $3545  D2 B3 35
        RRA                              ; $3548  1F
        JP C,SUB_3518_27                 ; $3549  DA 4D 36
        LD BC,L_0603                     ; $354C  01 03 06
        CALL SUB_3749                    ; $354F  CD 49 37
        POP DE                           ; $3552  D1
        LD A,D                           ; $3553  7A
        SUB $05                          ; $3554  D6 05
        CALL P,SUB_3729                  ; $3556  F4 29 37
        CALL SUB_3809                    ; $3559  CD 09 38
SUB_3518_7:
        LD A,E                           ; $355C  7B
        OR A                             ; $355D  B7
        CALL Z,SUB_2A9F                  ; $355E  CC 9F 2A
        DEC A                            ; $3561  3D
        CALL P,SUB_3729                  ; $3562  F4 29 37
SUB_3518_8:
        PUSH HL                          ; $3565  E5
        CALL SUB_33D8                    ; $3566  CD D8 33
        POP HL                           ; $3569  E1
        JR Z,SUB_3518_9                  ; $356A  28 02
        LD (HL),B                        ; $356C  70
        INC HL                           ; $356D  23
SUB_3518_9:
        LD (HL),$00                      ; $356E  36 00
        LD HL,SUB_0C98_15                ; $3570  21 E5 0C
SUB_3518_10:
        INC HL                           ; $3573  23
SUB_3518_11:
        LD A,(SUB_0B2A_37)               ; $3574  3A 8C 0B
        SUB L                            ; $3577  95
        SUB D                            ; $3578  92
        RET Z                            ; $3579  C8
        LD A,(HL)                        ; $357A  7E
        CP $20                           ; $357B  FE 20
        JR Z,SUB_3518_10                 ; $357D  28 F4
        CP $2A                           ; $357F  FE 2A
        JR Z,SUB_3518_10                 ; $3581  28 F0
        DEC HL                           ; $3583  2B
        PUSH HL                          ; $3584  E5
SUB_3518_12:
        PUSH AF                          ; $3585  F5
        LD BC,SUB_3518_12                ; $3586  01 85 35
        PUSH BC                          ; $3589  C5
        CALL SUB_13E4                    ; $358A  CD E4 13
        CP $2D                           ; $358D  FE 2D
        RET Z                            ; $358F  C8
        CP $2B                           ; $3590  FE 2B
        RET Z                            ; $3592  C8
        CP $24                           ; $3593  FE 24
        RET Z                            ; $3595  C8
        POP BC                           ; $3596  C1
        CP $30                           ; $3597  FE 30
        JR NZ,SUB_3518_14                ; $3599  20 11
        INC HL                           ; $359B  23
        CALL SUB_13E4                    ; $359C  CD E4 13
        JR NC,SUB_3518_14                ; $359F  30 0B
        DEC HL                           ; $35A1  2B
SUB_3518_13:
        LD BC,$772B                      ; $35A2  01 2B 77
        POP AF                           ; $35A5  F1
        JR Z,SUB_3518_13+1               ; $35A6  28 FB
        POP BC                           ; $35A8  C1
        JP SUB_3518_11                   ; $35A9  C3 74 35
SUB_3518_14:
        POP AF                           ; $35AC  F1
        JR Z,SUB_3518_14                 ; $35AD  28 FD
        POP HL                           ; $35AF  E1
        LD (HL),$25                      ; $35B0  36 25
        RET                              ; $35B2  C9
SUB_3518_15:
        PUSH HL                          ; $35B3  E5
        RRA                              ; $35B4  1F
        JP C,SUB_3518_28                 ; $35B5  DA 54 36
        JR Z,SUB_3518_17                 ; $35B8  28 14
        LD DE,L_385E                     ; $35BA  11 5E 38
        CALL SUB_2BBE                    ; $35BD  CD BE 2B
        LD D,$10                         ; $35C0  16 10
        JP M,SUB_3518_18                 ; $35C2  FA DC 35
SUB_3518_16:
        POP HL                           ; $35C5  E1
        POP BC                           ; $35C6  C1
        CALL SUB_33A0                    ; $35C7  CD A0 33
        DEC HL                           ; $35CA  2B
        LD (HL),$25                      ; $35CB  36 25
        RET                              ; $35CD  C9
SUB_3518_17:
        LD BC,$B60E                      ; $35CE  01 0E B6
        LD DE,SUB_1A93_25                ; $35D1  11 CA 1B
        CALL SUB_2B81                    ; $35D4  CD 81 2B
        JP P,SUB_3518_16                 ; $35D7  F2 C5 35
        LD D,$06                         ; $35DA  16 06
SUB_3518_18:
        CALL SUB_2AC5                    ; $35DC  CD C5 2A
        CALL NZ,SUB_36BA                 ; $35DF  C4 BA 36
        POP HL                           ; $35E2  E1
        POP BC                           ; $35E3  C1
        JP M,SUB_3518_19                 ; $35E4  FA 01 36
        PUSH BC                          ; $35E7  C5
        LD E,A                           ; $35E8  5F
        LD A,B                           ; $35E9  78
        SUB D                            ; $35EA  92
        SUB E                            ; $35EB  93
        CALL P,SUB_3729                  ; $35EC  F4 29 37
        CALL SUB_373D                    ; $35EF  CD 3D 37
        CALL SUB_3777                    ; $35F2  CD 77 37
        OR E                             ; $35F5  B3
        CALL NZ,SUB_3737                 ; $35F6  C4 37 37
        OR E                             ; $35F9  B3
        CALL NZ,SUB_3764                 ; $35FA  C4 64 37
        POP DE                           ; $35FD  D1
        JP SUB_3518_7                    ; $35FE  C3 5C 35
SUB_3518_19:
        LD E,A                           ; $3601  5F
        LD A,C                           ; $3602  79
        OR A                             ; $3603  B7
        CALL NZ,SUB_3210                 ; $3604  C4 10 32
        ADD A,E                          ; $3607  83
        JP M,SUB_3518_20                 ; $3608  FA 0C 36
        XOR A                            ; $360B  AF
SUB_3518_20:
        PUSH BC                          ; $360C  C5
        PUSH AF                          ; $360D  F5
SUB_3518_21:
        CALL M,SUB_3212                  ; $360E  FC 12 32
        JP M,SUB_3518_21                 ; $3611  FA 0E 36
        POP BC                           ; $3614  C1
        LD A,E                           ; $3615  7B
        SUB B                            ; $3616  90
        POP BC                           ; $3617  C1
SUB_3518_22:
        LD E,A                           ; $3618  5F
        ADD A,D                          ; $3619  82
        LD A,B                           ; $361A  78
        JP M,SUB_3518_24                 ; $361B  FA 29 36
SUB_3518_23:
        SUB D                            ; $361E  92
        SUB E                            ; $361F  93
        CALL P,SUB_3729                  ; $3620  F4 29 37
        PUSH BC                          ; $3623  C5
        CALL SUB_373D                    ; $3624  CD 3D 37
        JR SUB_3518_25                   ; $3627  18 11
SUB_3518_24:
        CALL SUB_3729                    ; $3629  CD 29 37
        LD A,C                           ; $362C  79
        CALL SUB_3767                    ; $362D  CD 67 37
        LD C,A                           ; $3630  4F
        XOR A                            ; $3631  AF
        SUB D                            ; $3632  92
        SUB E                            ; $3633  93
        CALL SUB_3729                    ; $3634  CD 29 37
        PUSH BC                          ; $3637  C5
        LD B,A                           ; $3638  47
        LD C,A                           ; $3639  4F
SUB_3518_25:
        CALL SUB_3777                    ; $363A  CD 77 37
        POP BC                           ; $363D  C1
        OR C                             ; $363E  B1
        JR NZ,SUB_3518_26                ; $363F  20 03
        LD HL,(SUB_0B2A_37)              ; $3641  2A 8C 0B
SUB_3518_26:
        ADD A,E                          ; $3644  83
        DEC A                            ; $3645  3D
        CALL P,SUB_3729                  ; $3646  F4 29 37
        LD D,B                           ; $3649  50
        JP SUB_3518_8                    ; $364A  C3 65 35
SUB_3518_27:
        PUSH HL                          ; $364D  E5
        PUSH DE                          ; $364E  D5
        CALL SUB_2C89                    ; $364F  CD 89 2C
        POP DE                           ; $3652  D1
        XOR A                            ; $3653  AF
SUB_3518_28:
        JP Z,SUB_3518_29+1               ; $3654  CA 5A 36
        LD E,$10                         ; $3657  1E 10
SUB_3518_29:
        LD BC,L_061E                     ; $3659  01 1E 06
        CALL SUB_2AC5                    ; $365C  CD C5 2A
        SCF                              ; $365F  37
        CALL NZ,SUB_36BA                 ; $3660  C4 BA 36
        POP HL                           ; $3663  E1
        POP BC                           ; $3664  C1
        PUSH AF                          ; $3665  F5
        LD A,C                           ; $3666  79
        OR A                             ; $3667  B7
        PUSH AF                          ; $3668  F5
        CALL NZ,SUB_3210                 ; $3669  C4 10 32
        ADD A,B                          ; $366C  80
        LD C,A                           ; $366D  4F
        LD A,D                           ; $366E  7A
        AND $04                          ; $366F  E6 04
        CP $01                           ; $3671  FE 01
        SBC A,A                          ; $3673  9F
        LD D,A                           ; $3674  57
        ADD A,C                          ; $3675  81
        LD C,A                           ; $3676  4F
        SUB E                            ; $3677  93
        PUSH AF                          ; $3678  F5
        PUSH BC                          ; $3679  C5
SUB_3518_30:
        CALL M,SUB_3212                  ; $367A  FC 12 32
        JP M,SUB_3518_30                 ; $367D  FA 7A 36
        POP BC                           ; $3680  C1
        POP AF                           ; $3681  F1
        PUSH BC                          ; $3682  C5
        PUSH AF                          ; $3683  F5
        JP M,SUB_3518_31                 ; $3684  FA 88 36
        XOR A                            ; $3687  AF
SUB_3518_31:
        CPL                              ; $3688  2F
        INC A                            ; $3689  3C
        ADD A,B                          ; $368A  80
        INC A                            ; $368B  3C
        ADD A,D                          ; $368C  82
        LD B,A                           ; $368D  47
        LD C,$00                         ; $368E  0E 00
        CALL SUB_3777                    ; $3690  CD 77 37
        POP AF                           ; $3693  F1
        CALL P,SUB_3731                  ; $3694  F4 31 37
        CALL SUB_3764                    ; $3697  CD 64 37
        POP BC                           ; $369A  C1
        POP AF                           ; $369B  F1
        JP NZ,SUB_3518_32                ; $369C  C2 AB 36
        CALL SUB_2A9F                    ; $369F  CD 9F 2A
        LD A,(HL)                        ; $36A2  7E
        CP $2E                           ; $36A3  FE 2E
        CALL NZ,SUB_2B3D                 ; $36A5  C4 3D 2B
        LD (SUB_0B2A_37),HL              ; $36A8  22 8C 0B
SUB_3518_32:
        POP AF                           ; $36AB  F1
        JR C,SUB_3518_33                 ; $36AC  38 03
        ADD A,E                          ; $36AE  83
        SUB B                            ; $36AF  90
        SUB D                            ; $36B0  92
SUB_3518_33:
        PUSH BC                          ; $36B1  C5
        CALL SUB_3518                    ; $36B2  CD 18 35
        EX DE,HL                         ; $36B5  EB
        POP DE                           ; $36B6  D1
        JP SUB_3518_8                    ; $36B7  C3 65 35
SUB_36BA:
        PUSH DE                          ; $36BA  D5
        XOR A                            ; $36BB  AF
        PUSH AF                          ; $36BC  F5
        CALL SUB_1DE3                    ; $36BD  CD E3 1D
        JP PO,SUB_36BA_2                 ; $36C0  E2 DD 36
SUB_36BA_1:
        LD A,(SUB_0C98_6)                ; $36C3  3A D7 0C
        CP $91                           ; $36C6  FE 91
        JP NC,SUB_36BA_2                 ; $36C8  D2 DD 36
        LD DE,SUB_3809_4                 ; $36CB  11 3E 38
        LD HL,SUB_0C98_12                ; $36CE  21 DD 0C
        CALL SUB_2B47                    ; $36D1  CD 47 2B
        CALL SUB_2FBC                    ; $36D4  CD BC 2F
        POP AF                           ; $36D7  F1
        SUB $0A                          ; $36D8  D6 0A
        PUSH AF                          ; $36DA  F5
        JR SUB_36BA_1                    ; $36DB  18 E6
SUB_36BA_2:
        CALL SUB_370D                    ; $36DD  CD 0D 37
SUB_36BA_3:
        CALL SUB_1DE3                    ; $36E0  CD E3 1D
        JP PE,SUB_36BA_4                 ; $36E3  EA F1 36
        LD BC,$9143                      ; $36E6  01 43 91
        LD DE,SUB_4E80_11+1              ; $36E9  11 F9 4F
        CALL SUB_2B81                    ; $36EC  CD 81 2B
        JR SUB_36BA_5                    ; $36EF  18 06
SUB_36BA_4:
        LD DE,SUB_3809_5                 ; $36F1  11 46 38
        CALL SUB_2BBE                    ; $36F4  CD BE 2B
SUB_36BA_5:
        JP P,SUB_36BA_7                  ; $36F7  F2 09 37
        POP AF                           ; $36FA  F1
        CALL SUB_3203                    ; $36FB  CD 03 32
        PUSH AF                          ; $36FE  F5
        JR SUB_36BA_3                    ; $36FF  18 DF
SUB_36BA_6:
        POP AF                           ; $3701  F1
        CALL SUB_3212                    ; $3702  CD 12 32
        PUSH AF                          ; $3705  F5
        CALL SUB_370D                    ; $3706  CD 0D 37
SUB_36BA_7:
        POP AF                           ; $3709  F1
        OR A                             ; $370A  B7
        POP DE                           ; $370B  D1
        RET                              ; $370C  C9
SUB_370D:
        CALL SUB_1DE3                    ; $370D  CD E3 1D
        JP PE,SUB_370D_2                 ; $3710  EA 1E 37
SUB_370D_1:
        LD BC,$9474                      ; $3713  01 74 94
        LD DE,L_23F8                     ; $3716  11 F8 23
        CALL SUB_2B81                    ; $3719  CD 81 2B
        JR SUB_370D_3                    ; $371C  18 06
SUB_370D_2:
        LD DE,SUB_3809_6                 ; $371E  11 4E 38
        CALL SUB_2BBE                    ; $3721  CD BE 2B
SUB_370D_3:
        POP HL                           ; $3724  E1
        JP P,SUB_36BA_6                  ; $3725  F2 01 37
        JP (HL)                          ; $3728  E9
SUB_3729:
        OR A                             ; $3729  B7
SUB_3729_1:
        RET Z                            ; $372A  C8
        DEC A                            ; $372B  3D
        LD (HL),$30                      ; $372C  36 30
        INC HL                           ; $372E  23
        JR SUB_3729_1                    ; $372F  18 F9
SUB_3731:
        JR NZ,SUB_3737                   ; $3731  20 04
SUB_3731_1:
        RET Z                            ; $3733  C8
        CALL SUB_3764                    ; $3734  CD 64 37
SUB_3737:
        LD (HL),$30                      ; $3737  36 30
        INC HL                           ; $3739  23
        DEC A                            ; $373A  3D
        JR SUB_3731_1                    ; $373B  18 F6
SUB_373D:
        LD A,E                           ; $373D  7B
        ADD A,D                          ; $373E  82
        INC A                            ; $373F  3C
        LD B,A                           ; $3740  47
        INC A                            ; $3741  3C
SUB_373D_1:
        SUB $03                          ; $3742  D6 03
        JR NC,SUB_373D_1                 ; $3744  30 FC
        ADD A,$05                        ; $3746  C6 05
        LD C,A                           ; $3748  4F
SUB_3749:
        LD A,(SUB_0B2A_20)               ; $3749  3A 6D 0B
        AND $40                          ; $374C  E6 40
        RET NZ                           ; $374E  C0
        LD C,A                           ; $374F  4F
        RET                              ; $3750  C9
SUB_3751:
        DEC B                            ; $3751  05
        JP P,SUB_3764_1                  ; $3752  F2 65 37
        LD (SUB_0B2A_37),HL              ; $3755  22 8C 0B
        LD (HL),$2E                      ; $3758  36 2E
SUB_3751_1:
        INC HL                           ; $375A  23
        LD (HL),$30                      ; $375B  36 30
        INC B                            ; $375D  04
        JP NZ,SUB_3751_1                 ; $375E  C2 5A 37
        INC HL                           ; $3761  23
        LD C,B                           ; $3762  48
        RET                              ; $3763  C9
SUB_3764:
        DEC B                            ; $3764  05
SUB_3764_1:
        JR NZ,SUB_3767_1                 ; $3765  20 08
SUB_3767:
        LD (HL),$2E                      ; $3767  36 2E
        LD (SUB_0B2A_37),HL              ; $3769  22 8C 0B
        INC HL                           ; $376C  23
        LD C,B                           ; $376D  48
        RET                              ; $376E  C9
SUB_3767_1:
        DEC C                            ; $376F  0D
        RET NZ                           ; $3770  C0
        LD (HL),$2C                      ; $3771  36 2C
        INC HL                           ; $3773  23
        LD C,$03                         ; $3774  0E 03
        RET                              ; $3776  C9
SUB_3777:
        PUSH DE                          ; $3777  D5
        CALL SUB_1DE3                    ; $3778  CD E3 1D
        JP PO,SUB_3777_3                 ; $377B  E2 C3 37
        PUSH BC                          ; $377E  C5
        PUSH HL                          ; $377F  E5
        CALL SUB_2B6F                    ; $3780  CD 6F 2B
        LD HL,L_3856                     ; $3783  21 56 38
        CALL SUB_2B6A                    ; $3786  CD 6A 2B
        CALL SUB_2E8E                    ; $3789  CD 8E 2E
        XOR A                            ; $378C  AF
        CALL SUB_2D44                    ; $378D  CD 44 2D
        POP HL                           ; $3790  E1
        POP BC                           ; $3791  C1
        LD DE,L_3866                     ; $3792  11 66 38
        LD A,$0A                         ; $3795  3E 0A
SUB_3777_1:
        CALL SUB_3764                    ; $3797  CD 64 37
        PUSH BC                          ; $379A  C5
        PUSH AF                          ; $379B  F5
        PUSH HL                          ; $379C  E5
        PUSH DE                          ; $379D  D5
        LD B,$2F                         ; $379E  06 2F
SUB_3777_2:
        INC B                            ; $37A0  04
        POP HL                           ; $37A1  E1
        PUSH HL                          ; $37A2  E5
        LD A,$9E                         ; $37A3  3E 9E
        CALL SUB_2F60                    ; $37A5  CD 60 2F
        JR NC,SUB_3777_2                 ; $37A8  30 F6
        POP HL                           ; $37AA  E1
        LD A,$8E                         ; $37AB  3E 8E
        CALL SUB_2F60                    ; $37AD  CD 60 2F
        EX DE,HL                         ; $37B0  EB
        POP HL                           ; $37B1  E1
        LD (HL),B                        ; $37B2  70
        INC HL                           ; $37B3  23
        POP AF                           ; $37B4  F1
        POP BC                           ; $37B5  C1
        DEC A                            ; $37B6  3D
        JR NZ,SUB_3777_1                 ; $37B7  20 DE
        PUSH BC                          ; $37B9  C5
        PUSH HL                          ; $37BA  E5
        LD HL,SUB_0C98_1                 ; $37BB  21 D0 0C
        CALL SUB_2B25                    ; $37BE  CD 25 2B
        JR SUB_3777_5                    ; $37C1  18 0D
SUB_3777_3:
        PUSH BC                          ; $37C3  C5
        PUSH HL                          ; $37C4  E5
        CALL SUB_2816                    ; $37C5  CD 16 28
        LD A,$01                         ; $37C8  3E 01
        CALL SUB_2CBA                    ; $37CA  CD BA 2C
SUB_3777_4:
        CALL SUB_2B28                    ; $37CD  CD 28 2B
SUB_3777_5:
        POP HL                           ; $37D0  E1
        POP BC                           ; $37D1  C1
        XOR A                            ; $37D2  AF
        LD DE,L_38AC                     ; $37D3  11 AC 38
SUB_3777_6:
        CCF                              ; $37D6  3F
        CALL SUB_3764                    ; $37D7  CD 64 37
        PUSH BC                          ; $37DA  C5
        PUSH AF                          ; $37DB  F5
        PUSH HL                          ; $37DC  E5
        PUSH DE                          ; $37DD  D5
        CALL SUB_2B33                    ; $37DE  CD 33 2B
        POP HL                           ; $37E1  E1
        LD B,$2F                         ; $37E2  06 2F
SUB_3777_7:
        INC B                            ; $37E4  04
        LD A,E                           ; $37E5  7B
        SUB (HL)                         ; $37E6  96
        LD E,A                           ; $37E7  5F
        INC HL                           ; $37E8  23
        LD A,D                           ; $37E9  7A
        SBC A,(HL)                       ; $37EA  9E
        LD D,A                           ; $37EB  57
        INC HL                           ; $37EC  23
        LD A,C                           ; $37ED  79
        SBC A,(HL)                       ; $37EE  9E
        LD C,A                           ; $37EF  4F
        DEC HL                           ; $37F0  2B
        DEC HL                           ; $37F1  2B
        JR NC,SUB_3777_7                 ; $37F2  30 F0
        CALL SUB_28D5                    ; $37F4  CD D5 28
        INC HL                           ; $37F7  23
        CALL SUB_2B28                    ; $37F8  CD 28 2B
        EX DE,HL                         ; $37FB  EB
        POP HL                           ; $37FC  E1
        LD (HL),B                        ; $37FD  70
        INC HL                           ; $37FE  23
        POP AF                           ; $37FF  F1
        POP BC                           ; $3800  C1
        JR C,SUB_3777_6                  ; $3801  38 D3
        INC DE                           ; $3803  13
        INC DE                           ; $3804  13
        LD A,$04                         ; $3805  3E 04
        JR SUB_3809_1                    ; $3807  18 06
SUB_3809:
        PUSH DE                          ; $3809  D5
        LD DE,L_38B2                     ; $380A  11 B2 38
        LD A,$05                         ; $380D  3E 05
SUB_3809_1:
        CALL SUB_3764                    ; $380F  CD 64 37
        PUSH BC                          ; $3812  C5
        PUSH AF                          ; $3813  F5
        PUSH HL                          ; $3814  E5
        EX DE,HL                         ; $3815  EB
        LD C,(HL)                        ; $3816  4E
        INC HL                           ; $3817  23
        LD B,(HL)                        ; $3818  46
        PUSH BC                          ; $3819  C5
        INC HL                           ; $381A  23
        EX (SP),HL                       ; $381B  E3
        EX DE,HL                         ; $381C  EB
        LD HL,(SUB_0C98_4)               ; $381D  2A D4 0C
        LD B,$2F                         ; $3820  06 2F
SUB_3809_2:
        INC B                            ; $3822  04
        LD A,L                           ; $3823  7D
        SUB E                            ; $3824  93
        LD L,A                           ; $3825  6F
        LD A,H                           ; $3826  7C
        SBC A,D                          ; $3827  9A
        LD H,A                           ; $3828  67
SUB_3809_3:
        JR NC,SUB_3809_2                 ; $3829  30 F7
        ADD HL,DE                        ; $382B  19
        LD (SUB_0C98_4),HL               ; $382C  22 D4 0C
        POP DE                           ; $382F  D1
        POP HL                           ; $3830  E1
        LD (HL),B                        ; $3831  70
        INC HL                           ; $3832  23
        POP AF                           ; $3833  F1
        POP BC                           ; $3834  C1
        DEC A                            ; $3835  3D
        JR NZ,SUB_3809_1                 ; $3836  20 D7
        CALL SUB_3764                    ; $3838  CD 64 37
        LD (HL),A                        ; $383B  77
        POP DE                           ; $383C  D1
        RET                              ; $383D  C9
SUB_3809_4:
        NOP                              ; $383E  00
        NOP                              ; $383F  00
        NOP                              ; $3840  00
        NOP                              ; $3841  00
        LD SP,HL                         ; $3842  F9
        LD (BC),A                        ; $3843  02
        DEC D                            ; $3844  15
        AND D                            ; $3845  A2
SUB_3809_5:
        POP HL                           ; $3846  E1
        RST $38                          ; $3847  FF
        SBC A,A                          ; $3848  9F
        LD SP,$5FA9                      ; $3849  31 A9 5F
        LD H,E                           ; $384C  63
        OR D                             ; $384D  B2
SUB_3809_6:
        CP $FF                           ; $384E  FE FF
        INC BC                           ; $3850  03
        CP A                             ; $3851  BF
        RET                              ; $3852  C9
        DEFW    SUB_0D20_33              ; $3853
        DEFB    $B6                                              ; $3855
L_3856:
        DEFB    $00,$00,$00,$00                                  ; $3856
L_385A:
        DEFB    $00,$00,$00,$80                                  ; $385A
L_385E:
        DEFB    $00,$00,$04,$BF                                  ; $385E
        DEFW    SUB_1A93_24              ; $3862
        DEFB    $0E,$B6                                          ; $3864
L_3866:
        DEFB    $00,$80,$C6,$A4,$7E,$8D,$03                      ; $3866
        DEFW    SUB_3FF9_2               ; $386D
        DEFW    SUB_101B_4               ; $386F
        DEFW    SUB_5A3B_8               ; $3871
        DEFB    $00,$00,$A0,$72                                  ; $3873
        DEFW    SUB_15CF_40              ; $3877
        DEFB    $09,$00,$00,$10,$A5,$D4,$E8,$00,$00,$00,$E8      ; $3879
        DEFW    SUB_486C_2               ; $3884
        DEFB    $17,$00,$00,$00                                  ; $3886
        DEFW    SUB_0B2A_49              ; $388A
        DEFB    $54,$02,$00,$00,$00,$CA,$9A,$3B,$00,$00,$00,$00,$E1,$F5,$05,$00 ; $388C
        DEFB    $00,$00,$80,$96,$98,$00,$00,$00                  ; $389C
        DEFW    SUB_3FF9_2               ; $38A4
        DEFB    $42,$0F,$00,$00,$00,$00                          ; $38A6
L_38AC:
        DEFB    $A0,$86                                          ; $38AC
        DEFW    SUB_0FAB_8               ; $38AE
        DEFB    $27,$00                                          ; $38B0
L_38B2:
        DEFW    SUB_2602_5               ; $38B2
        DEFB    $E8,$03,$64                                      ; $38B4
        DEFW    SUB_0925_6               ; $38B7
        DEFW    SUB_0100                 ; $38B9
        DEFB    $00                                              ; $38BB
SUB_3809_7:
        XOR A                            ; $38BC  AF
        LD B,A                           ; $38BD  47
SUB_3809_8:
        JP NZ,SUB_0100_2                 ; $38BE  C2 06 01
        PUSH BC                          ; $38C1  C5
        CALL SUB_22E1                    ; $38C2  CD E1 22
        POP BC                           ; $38C5  C1
        LD DE,SUB_0C98_15                ; $38C6  11 E5 0C
        PUSH DE                          ; $38C9  D5
        XOR A                            ; $38CA  AF
        LD (DE),A                        ; $38CB  12
        DEC B                            ; $38CC  05
        INC B                            ; $38CD  04
        LD C,$06                         ; $38CE  0E 06
        JR Z,SUB_3809_11                 ; $38D0  28 08
        LD C,$04                         ; $38D2  0E 04
SUB_3809_9:
        ADD HL,HL                        ; $38D4  29
        ADC A,A                          ; $38D5  8F
SUB_3809_10:
        ADD HL,HL                        ; $38D6  29
        ADC A,A                          ; $38D7  8F
        ADD HL,HL                        ; $38D8  29
        ADC A,A                          ; $38D9  8F
SUB_3809_11:
        ADD HL,HL                        ; $38DA  29
        ADC A,A                          ; $38DB  8F
        OR A                             ; $38DC  B7
        JP NZ,SUB_3809_12                ; $38DD  C2 EB 38
        LD A,C                           ; $38E0  79
        DEC A                            ; $38E1  3D
        JP Z,SUB_3809_12                 ; $38E2  CA EB 38
        LD A,(DE)                        ; $38E5  1A
        OR A                             ; $38E6  B7
        JP Z,SUB_3809_14                 ; $38E7  CA F7 38
        XOR A                            ; $38EA  AF
SUB_3809_12:
        ADD A,$30                        ; $38EB  C6 30
        CP $3A                           ; $38ED  FE 3A
        JP C,SUB_3809_13                 ; $38EF  DA F4 38
        ADD A,$07                        ; $38F2  C6 07
SUB_3809_13:
        LD (DE),A                        ; $38F4  12
        INC DE                           ; $38F5  13
        LD (DE),A                        ; $38F6  12
SUB_3809_14:
        XOR A                            ; $38F7  AF
        DEC C                            ; $38F8  0D
        JR Z,SUB_3809_16                 ; $38F9  28 08
        DEC B                            ; $38FB  05
        INC B                            ; $38FC  04
        JP Z,SUB_3809_10                 ; $38FD  CA D6 38
SUB_3809_15:
        JP SUB_3809_9                    ; $3900  C3 D4 38
SUB_3809_16:
        LD (DE),A                        ; $3903  12
        POP HL                           ; $3904  E1
        RET                              ; $3905  C9
SUB_3809_17:
        LD HL,SUB_2AEB_1                 ; $3906  21 F4 2A
        EX (SP),HL                       ; $3909  E3
        JP (HL)                          ; $390A  E9
SUB_3809_18:
        CALL SUB_2B18                    ; $390B  CD 18 2B
        LD HL,L_385A                     ; $390E  21 5A 38
        CALL SUB_2B25                    ; $3911  CD 25 2B
        JR SUB_3809_20                   ; $3914  18 03
SUB_3809_19:
        CALL SUB_2C6C                    ; $3916  CD 6C 2C
SUB_3809_20:
        POP BC                           ; $3919  C1
        POP DE                           ; $391A  D1
        LD HL,SUB_2554                   ; $391B  21 54 25
SUB_3809_21:
        PUSH HL                          ; $391E  E5
        LD A,$01                         ; $391F  3E 01
SUB_3809_22:
        LD (SUB_0C98_8),A                ; $3921  32 D9 0C
        CALL SUB_2AC5                    ; $3924  CD C5 2A
        LD A,B                           ; $3927  78
        JR Z,SUB_3809_26                 ; $3928  28 3C
        JP P,SUB_3809_23                 ; $392A  F2 31 39
        OR A                             ; $392D  B7
        JP Z,SUB_3289_23                 ; $392E  CA 02 33
SUB_3809_23:
        OR A                             ; $3931  B7
SUB_3809_24:
        JP Z,SUB_2874_4                  ; $3932  CA 88 28
        PUSH DE                          ; $3935  D5
        PUSH BC                          ; $3936  C5
        LD A,C                           ; $3937  79
        OR $7F                           ; $3938  F6 7F
        CALL SUB_2B33                    ; $393A  CD 33 2B
        JP P,SUB_3809_25                 ; $393D  F2 4E 39
        PUSH DE                          ; $3940  D5
        PUSH BC                          ; $3941  C5
        CALL SUB_2D04                    ; $3942  CD 04 2D
        POP BC                           ; $3945  C1
        POP DE                           ; $3946  D1
        PUSH AF                          ; $3947  F5
        CALL SUB_2B81                    ; $3948  CD 81 2B
        POP HL                           ; $394B  E1
        LD A,H                           ; $394C  7C
        RRA                              ; $394D  1F
SUB_3809_25:
        POP HL                           ; $394E  E1
        LD (SUB_0C98_5),HL               ; $394F  22 D6 0C
        POP HL                           ; $3952  E1
        LD (SUB_0C98_4),HL               ; $3953  22 D4 0C
        CALL C,SUB_3809_17               ; $3956  DC 06 39
        CALL Z,SUB_2AEB_1                ; $3959  CC F4 2A
        PUSH DE                          ; $395C  D5
        PUSH BC                          ; $395D  C5
        CALL SUB_294A                    ; $395E  CD 4A 29
        POP BC                           ; $3961  C1
        POP DE                           ; $3962  D1
        CALL SUB_2990                    ; $3963  CD 90 29
SUB_3809_26:
        LD BC,$8138                      ; $3966  01 38 81
        LD DE,$AA3B                      ; $3969  11 3B AA
        CALL SUB_2990                    ; $396C  CD 90 29
        LD A,(SUB_0C98_6)                ; $396F  3A D7 0C
        CP $88                           ; $3972  FE 88
        JP NC,SUB_3809_28                ; $3974  D2 9B 39
        CP $68                           ; $3977  FE 68
        JP C,SUB_3809_31                 ; $3979  DA AD 39
        CALL SUB_2B18                    ; $397C  CD 18 2B
        CALL SUB_2D04                    ; $397F  CD 04 2D
        ADD A,$81                        ; $3982  C6 81
        POP BC                           ; $3984  C1
        POP DE                           ; $3985  D1
        JP Z,SUB_3809_29                 ; $3986  CA 9E 39
        PUSH AF                          ; $3989  F5
        CALL SUB_2821                    ; $398A  CD 21 28
        LD HL,SUB_3809_32                ; $398D  21 B7 39
        CALL SUB_39E3                    ; $3990  CD E3 39
        POP BC                           ; $3993  C1
        LD DE,$0000                      ; $3994  11 00 00
        LD C,D                           ; $3997  4A
SUB_3809_27:
        JP SUB_2990                      ; $3998  C3 90 29
SUB_3809_28:
        CALL SUB_2B18                    ; $399B  CD 18 2B
SUB_3809_29:
        LD A,(SUB_0C98_5)                ; $399E  3A D6 0C
        OR A                             ; $39A1  B7
        JP P,SUB_3809_30                 ; $39A2  F2 AA 39
        POP AF                           ; $39A5  F1
        POP AF                           ; $39A6  F1
        JP SUB_2874_3                    ; $39A7  C3 87 28
SUB_3809_30:
        JP SUB_3289_12                   ; $39AA  C3 CA 32
SUB_3809_31:
        LD BC,$8100                      ; $39AD  01 00 81
        LD DE,$0000                      ; $39B0  11 00 00
        CALL SUB_2B28                    ; $39B3  CD 28 2B
        RET                              ; $39B6  C9
SUB_3809_32:
        RLCA                             ; $39B7  07
        LD A,H                           ; $39B8  7C
        ADC A,B                          ; $39B9  88
        LD E,C                           ; $39BA  59
        LD (HL),H                        ; $39BB  74
        RET PO                           ; $39BC  E0
        SUB A                            ; $39BD  97
        LD H,$77                         ; $39BE  26 77
        CALL NZ,SUB_1E1D                 ; $39C0  C4 1D 1E
        LD A,D                           ; $39C3  7A
        LD E,(HL)                        ; $39C4  5E
        LD D,B                           ; $39C5  50
        LD H,E                           ; $39C6  63
        LD A,H                           ; $39C7  7C
        LD A,(DE)                        ; $39C8  1A
        CP $75                           ; $39C9  FE 75
        LD A,(HL)                        ; $39CB  7E
        JR SUB_3A18_3                    ; $39CC  18 72
        DEFB    $31,$80,$00,$00,$00,$81                          ; $39CE
        DEFW    SUB_189A_5               ; $39D4
        DEFW    SUB_1128_1               ; $39D6
        DEFW    SUB_2DA1_4               ; $39D8
        DEFB    $D5,$E5                                          ; $39DA
        DEFW    SUB_33A1_4               ; $39DC
        DEFB    $2B,$CD                                          ; $39DE
        DEFW    SUB_2990                 ; $39E0
        DEFB    $E1                                              ; $39E2
SUB_39E3:
        CALL SUB_2B18                    ; $39E3  CD 18 2B
        LD A,(HL)                        ; $39E6  7E
        INC HL                           ; $39E7  23
        CALL SUB_2B25                    ; $39E8  CD 25 2B
SUB_39E3_1:
        LD B,$F1                         ; $39EB  06 F1
        POP BC                           ; $39ED  C1
        POP DE                           ; $39EE  D1
        DEC A                            ; $39EF  3D
        RET Z                            ; $39F0  C8
        PUSH DE                          ; $39F1  D5
        PUSH BC                          ; $39F2  C5
        PUSH AF                          ; $39F3  F5
        PUSH HL                          ; $39F4  E5
        CALL SUB_2990                    ; $39F5  CD 90 29
        POP HL                           ; $39F8  E1
        CALL SUB_2B36                    ; $39F9  CD 36 2B
        PUSH HL                          ; $39FC  E5
        CALL SUB_2824                    ; $39FD  CD 24 28
        POP HL                           ; $3A00  E1
        JR SUB_39E3_1+1                  ; $3A01  18 E9
SUB_39E3_2:
        LD D,D                           ; $3A03  52
        RST $00                          ; $3A04  C7
        LD C,A                           ; $3A05  4F
        ADD A,B                          ; $3A06  80
SUB_39E3_3:
        CALL SUB_13E4                    ; $3A07  CD E4 13
SUB_3A0A:
        PUSH HL                          ; $3A0A  E5
        LD HL,L_2924                     ; $3A0B  21 24 29
        CALL SUB_2B25                    ; $3A0E  CD 25 2B
        CALL SUB_3A18                    ; $3A11  CD 18 3A
        POP HL                           ; $3A14  E1
        JP SUB_2CAB_1+1                  ; $3A15  C3 AE 2C
SUB_3A18:
        CALL SUB_2AC5                    ; $3A18  CD C5 2A
        LD HL,SUB_3A18_11                ; $3A1B  21 81 3A
SUB_3A18_1:
        JP M,SUB_3A18_8                  ; $3A1E  FA 78 3A
        LD HL,L_3AA2                     ; $3A21  21 A2 3A
        CALL SUB_2B25                    ; $3A24  CD 25 2B
        LD HL,SUB_3A18_11                ; $3A27  21 81 3A
        RET Z                            ; $3A2A  C8
        ADD A,(HL)                       ; $3A2B  86
        AND $07                          ; $3A2C  E6 07
        LD B,$00                         ; $3A2E  06 00
        LD (HL),A                        ; $3A30  77
        INC HL                           ; $3A31  23
SUB_3A18_2:
        ADD A,A                          ; $3A32  87
        ADD A,A                          ; $3A33  87
        LD C,A                           ; $3A34  4F
        ADD HL,BC                        ; $3A35  09
        CALL SUB_2B36                    ; $3A36  CD 36 2B
        CALL SUB_2990                    ; $3A39  CD 90 29
        LD A,(SUB_3A18_10)               ; $3A3C  3A 80 3A
        INC A                            ; $3A3F  3C
SUB_3A18_3:
        AND $03                          ; $3A40  E6 03
        LD B,$00                         ; $3A42  06 00
        CP $01                           ; $3A44  FE 01
        ADC A,B                          ; $3A46  88
        LD (SUB_3A18_10),A               ; $3A47  32 80 3A
        LD HL,L_3AA2                     ; $3A4A  21 A2 3A
        ADD A,A                          ; $3A4D  87
        ADD A,A                          ; $3A4E  87
SUB_3A18_4:
        LD C,A                           ; $3A4F  4F
        ADD HL,BC                        ; $3A50  09
        CALL SUB_2819                    ; $3A51  CD 19 28
SUB_3A18_5:
        CALL SUB_2B33                    ; $3A54  CD 33 2B
        LD A,E                           ; $3A57  7B
        LD E,C                           ; $3A58  59
        XOR $4F                          ; $3A59  EE 4F
        LD C,A                           ; $3A5B  4F
        LD (HL),$80                      ; $3A5C  36 80
        DEC HL                           ; $3A5E  2B
        LD B,(HL)                        ; $3A5F  46
        LD (HL),$80                      ; $3A60  36 80
        LD HL,SUB_3A18_9                 ; $3A62  21 7F 3A
        INC (HL)                         ; $3A65  34
        LD A,(HL)                        ; $3A66  7E
        SUB $AB                          ; $3A67  D6 AB
        JR NZ,SUB_3A18_7                 ; $3A69  20 04
SUB_3A18_6:
        LD (HL),A                        ; $3A6B  77
        INC C                            ; $3A6C  0C
        DEC D                            ; $3A6D  15
        INC E                            ; $3A6E  1C
SUB_3A18_7:
        CALL SUB_2874                    ; $3A6F  CD 74 28
        LD HL,L_3AA2                     ; $3A72  21 A2 3A
        JP SUB_2B3F                      ; $3A75  C3 3F 2B
SUB_3A18_8:
        LD (HL),A                        ; $3A78  77
        DEC HL                           ; $3A79  2B
        LD (HL),A                        ; $3A7A  77
        DEC HL                           ; $3A7B  2B
        LD (HL),A                        ; $3A7C  77
        JR SUB_3A18_5                    ; $3A7D  18 D5
SUB_3A18_9:
        NOP                              ; $3A7F  00
SUB_3A18_10:
        NOP                              ; $3A80  00
SUB_3A18_11:
        NOP                              ; $3A81  00
        DEC (HL)                         ; $3A82  35
        LD C,D                           ; $3A83  4A
        JP Z,SUB_3809_27+1               ; $3A84  CA 99 39
        INC E                            ; $3A87  1C
        HALT                             ; $3A88  76
        DEFB    $98,$22,$95,$B3                                  ; $3A89
        DEFW    SUB_0925_15              ; $3A8D
        DEFW    SUB_475A_5               ; $3A8F
        DEFB    $98,$53,$D1,$99                                  ; $3A91
        DEFW    SUB_0925_16              ; $3A95
        DEFB    $1A,$9F,$98,$65,$BC,$CD,$98,$D6,$77,$3E,$98      ; $3A97
L_3AA2:
        DEFB    $52                                              ; $3AA2
L_3AA3:
        DEFB    $C7,$4F,$80,$68                                  ; $3AA3
        DEFW    SUB_463E_7               ; $3AA7
        DEFB    $68,$99,$E9,$92                                  ; $3AA9
        DEFW    SUB_101B_2               ; $3AAD
        DEFB    $D1,$75,$68                                      ; $3AAF
        DEFW    SUB_2821                 ; $3AB2
        DEFB    $3B,$CD                                          ; $3AB4
        DEFW    SUB_2819                 ; $3AB6
        DEFB    $3A                                              ; $3AB8
        DEFW    SUB_0C98_6               ; $3AB9
        DEFB    $FE,$77,$D8,$01,$22,$7E,$11,$83,$F9,$CD          ; $3ABB
        DEFW    SUB_2990                 ; $3AC5
        DEFW    SUB_189A_5               ; $3AC7
        DEFB    $2B,$CD                                          ; $3AC9
        DEFW    SUB_2D04                 ; $3ACB
        DEFB    $C1,$D1,$CD                                      ; $3ACD
        DEFW    SUB_2821                 ; $3AD0
        DEFB    $01,$00,$7F,$11,$00,$00,$CD                      ; $3AD2
        DEFW    SUB_2B81                 ; $3AD9
        DEFB    $FA,$02                                          ; $3ADB
        DEFW    SUB_0100_10              ; $3ADD
        DEFB    $80,$7F,$11,$00,$00                              ; $3ADF
        DEFW    SUB_24CD                 ; $3AE4
        DEFW    SUB_0100_8               ; $3AE6
        DEFB    $80                                              ; $3AE8
        DEFW    SUB_1128_9               ; $3AE9
        DEFB    $00,$00                                          ; $3AEB
        DEFW    SUB_24CD                 ; $3AED
        DEFB    $28,$CD                                          ; $3AEF
        DEFW    SUB_2AC5                 ; $3AF1
        DEFB    $F4                                              ; $3AF3
        DEFW    SUB_2AEB_1               ; $3AF4
        DEFB    $01,$00,$7F,$11,$00,$00                          ; $3AF6
        DEFW    SUB_24CD                 ; $3AFC
        DEFB    $28,$CD                                          ; $3AFE
        DEFW    SUB_2AEB_1               ; $3B00
        DEFB    $3A                                              ; $3B02
        DEFW    SUB_0C98_5               ; $3B03
        DEFB    $B7,$F5                                          ; $3B05
        DEFW    SUB_0FAB_6               ; $3B07
        DEFB    $3B,$EE,$80,$32                                  ; $3B09
        DEFW    SUB_0C98_5               ; $3B0D
        DEFW    SUB_3006_3               ; $3B0F
        DEFB    $3B,$CD,$D4,$39,$F1,$F0,$3A                      ; $3B11
        DEFW    SUB_0C98_5               ; $3B18
        DEFB    $EE,$80,$32                                      ; $3B1A
        DEFW    SUB_0C98_5               ; $3B1D
        DEFB    $C9,$00,$00,$00,$00,$83,$F9,$22,$7E,$DB,$0F,$49,$81,$00,$00,$00 ; $3B1F
        DEFB    $7F                                              ; $3B2F
L_3B30:
        DEFB    $05,$FB                                          ; $3B30
        DEFW    SUB_1E72_8               ; $3B32
        DEFB    $86,$65,$26,$99                                  ; $3B34
        DEFW    SUB_5878_1               ; $3B38
        DEFW    SUB_22E1_9               ; $3B3A
        DEFB    $87,$E1,$5D,$A5,$86,$DB,$0F,$49,$83              ; $3B3C
        DEFW    SUB_189A_5               ; $3B45
        DEFB    $2B,$CD,$B8,$3A,$C1,$E1                          ; $3B47
        DEFW    SUB_189A_5               ; $3B4D
        DEFB    $2B,$EB                                          ; $3B4F
        DEFW    SUB_28C8_1               ; $3B51
        DEFB    $2B,$CD,$B2,$3A,$C3                              ; $3B53
        DEFW    SUB_29E8_2               ; $3B58
        DEFB    $CD                                              ; $3B5A
        DEFW    SUB_2AC5                 ; $3B5B
        DEFW    SUB_064E_10              ; $3B5D
        DEFB    $39,$FC                                          ; $3B5F
        DEFW    SUB_2AEB_1               ; $3B61
        DEFB    $3A                                              ; $3B63
        DEFW    SUB_0C98_6               ; $3B64
        DEFB    $FE,$81                                          ; $3B66
        DEFW    SUB_0C03_5               ; $3B68
        DEFB    $01,$00                                          ; $3B6A
        DEFW    SUB_5143_2               ; $3B6C
        DEFB    $59,$CD                                          ; $3B6E
        DEFW    SUB_29E8_3               ; $3B70
        DEFW    SUB_1E1D_1               ; $3B72
        DEFB    $28,$E5,$21                                      ; $3B74
        DEFW    L_3B80                   ; $3B77
        DEFB    $CD,$D4                                          ; $3B79
        DEFW    SUB_2124_4               ; $3B7B
        DEFB    $28,$3B,$C9                                      ; $3B7D
L_3B80:
        DEFB    $09,$4A,$D7,$3B,$78,$02,$6E,$84,$7B,$FE,$C1,$2F,$7C,$74,$31,$9A ; $3B80
        DEFB    $7D,$84                                          ; $3B90
        DEFW    SUB_5A3B_1               ; $3B92
        DEFB    $7D,$C8,$7F,$91,$7E,$E4,$BB,$4C,$7E,$6C,$AA,$AA,$7F,$00,$00,$00 ; $3B94
        DEFW    SUB_2B81                 ; $3BA4
        DEFB    $CD                                              ; $3BA6
        DEFW    SUB_13E4                 ; $3BA7
        DEFB    $C8,$CD                                          ; $3BA9
        DEFW    SUB_45A3                 ; $3BAB
        DEFW    SUB_0100_9               ; $3BAD
        DEFB    $A5,$3B,$C5,$F6                                  ; $3BAF
SUB_3BB3:
        XOR A                            ; $3BB3  AF
        LD (SUB_0B2A_4),A                ; $3BB4  32 36 0B
        LD C,(HL)                        ; $3BB7  4E
SUB_3BB3_1:
        CALL SUB_46BE                    ; $3BB8  CD BE 46
        JP C,SUB_0D20_20                 ; $3BBB  DA 92 0D
        XOR A                            ; $3BBE  AF
        LD B,A                           ; $3BBF  47
        LD (SUB_0752_56),A               ; $3BC0  32 94 08
SUB_3BB3_2:
        INC HL                           ; $3BC3  23
        LD A,(HL)                        ; $3BC4  7E
        CP $2E                           ; $3BC5  FE 2E
        JR C,SUB_3BB3_7                  ; $3BC7  38 39
        JR Z,SUB_3BB3_4                  ; $3BC9  28 0D
        CP $3A                           ; $3BCB  FE 3A
        JR NC,SUB_3BB3_3                 ; $3BCD  30 04
        CP $30                           ; $3BCF  FE 30
        JR NC,SUB_3BB3_4                 ; $3BD1  30 05
SUB_3BB3_3:
        CALL SUB_46BF                    ; $3BD3  CD BF 46
        JR C,SUB_3BB3_7                  ; $3BD6  38 2A
SUB_3BB3_4:
        LD B,A                           ; $3BD8  47
        PUSH BC                          ; $3BD9  C5
        LD B,$FF                         ; $3BDA  06 FF
        LD DE,SUB_0752_56                ; $3BDC  11 94 08
SUB_3BB3_5:
        OR $80                           ; $3BDF  F6 80
        INC B                            ; $3BE1  04
        LD (DE),A                        ; $3BE2  12
        INC DE                           ; $3BE3  13
        INC HL                           ; $3BE4  23
        LD A,(HL)                        ; $3BE5  7E
        CP $3A                           ; $3BE6  FE 3A
        JR NC,SUB_3BB3_6                 ; $3BE8  30 04
        CP $30                           ; $3BEA  FE 30
        JR NC,SUB_3BB3_5                 ; $3BEC  30 F1
SUB_3BB3_6:
        CALL SUB_46BF                    ; $3BEE  CD BF 46
        JR NC,SUB_3BB3_5                 ; $3BF1  30 EC
        CP $2E                           ; $3BF3  FE 2E
        JR Z,SUB_3BB3_5                  ; $3BF5  28 E8
        LD A,B                           ; $3BF7  78
        CP $27                           ; $3BF8  FE 27
        JP NC,SUB_0D20_20                ; $3BFA  D2 92 0D
        POP BC                           ; $3BFD  C1
        LD (SUB_0752_56),A               ; $3BFE  32 94 08
        LD A,(HL)                        ; $3C01  7E
SUB_3BB3_7:
        CP $26                           ; $3C02  FE 26
        JR NC,SUB_3BB3_8                 ; $3C04  30 17
        LD DE,SUB_3BB3_9                 ; $3C06  11 2B 3C
        PUSH DE                          ; $3C09  D5
        LD D,$02                         ; $3C0A  16 02
        CP $25                           ; $3C0C  FE 25
        RET Z                            ; $3C0E  C8
        INC D                            ; $3C0F  14
        CP $24                           ; $3C10  FE 24
        RET Z                            ; $3C12  C8
        INC D                            ; $3C13  14
        CP $21                           ; $3C14  FE 21
        RET Z                            ; $3C16  C8
        LD D,$08                         ; $3C17  16 08
        CP $23                           ; $3C19  FE 23
        RET Z                            ; $3C1B  C8
        POP AF                           ; $3C1C  F1
SUB_3BB3_8:
        LD A,C                           ; $3C1D  79
        AND $7F                          ; $3C1E  E6 7F
        LD E,A                           ; $3C20  5F
        LD D,$00                         ; $3C21  16 00
        PUSH HL                          ; $3C23  E5
        LD HL,SUB_0B2A_16                ; $3C24  21 59 0B
        ADD HL,DE                        ; $3C27  19
        LD D,(HL)                        ; $3C28  56
        POP HL                           ; $3C29  E1
        DEC HL                           ; $3C2A  2B
SUB_3BB3_9:
        LD A,D                           ; $3C2B  7A
        LD (SUB_0B2A_5),A                ; $3C2C  32 37 0B
        CALL SUB_13E4                    ; $3C2F  CD E4 13
        LD A,(SUB_0B2A_23)               ; $3C32  3A 75 0B
        DEC A                            ; $3C35  3D
        JP Z,SUB_3D4E_6+1                ; $3C36  CA AB 3D
        JP P,SUB_3C47                    ; $3C39  F2 47 3C
        LD A,(HL)                        ; $3C3C  7E
        SUB $28                          ; $3C3D  D6 28
        JP Z,SUB_3D15_6                  ; $3C3F  CA 35 3D
        SUB $33                          ; $3C42  D6 33
        JP Z,SUB_3D15_6                  ; $3C44  CA 35 3D
SUB_3C47:
        XOR A                            ; $3C47  AF
        LD (SUB_0B2A_23),A               ; $3C48  32 75 0B
        PUSH HL                          ; $3C4B  E5
        LD A,(SUB_0C4B_4)                ; $3C4C  3A 87 0C
        OR A                             ; $3C4F  B7
        LD (SUB_0C4B_1),A                ; $3C50  32 84 0C
        JR Z,SUB_3C47_6                  ; $3C53  28 40
        LD HL,(SUB_0B2A_46)              ; $3C55  2A B6 0B
        LD DE,SUB_0B2A_47                ; $3C58  11 B8 0B
        ADD HL,DE                        ; $3C5B  19
        LD (SUB_0C4B_2),HL               ; $3C5C  22 85 0C
        EX DE,HL                         ; $3C5F  EB
        JR SUB_3C47_5                    ; $3C60  18 1B
SUB_3C47_1:
        LD A,(DE)                        ; $3C62  1A
        LD L,A                           ; $3C63  6F
        INC DE                           ; $3C64  13
        LD A,(DE)                        ; $3C65  1A
        INC DE                           ; $3C66  13
        CP C                             ; $3C67  B9
        JR NZ,SUB_3C47_2                 ; $3C68  20 0B
        LD A,(SUB_0B2A_5)                ; $3C6A  3A 37 0B
        CP L                             ; $3C6D  BD
        JR NZ,SUB_3C47_2                 ; $3C6E  20 05
        LD A,(DE)                        ; $3C70  1A
        CP B                             ; $3C71  B8
        JP Z,SUB_3C47_10                 ; $3C72  CA 06 3D
SUB_3C47_2:
        INC DE                           ; $3C75  13
SUB_3C47_3:
        LD A,(DE)                        ; $3C76  1A
SUB_3C47_4:
        LD H,$00                         ; $3C77  26 00
        ADD A,L                          ; $3C79  85
        INC A                            ; $3C7A  3C
        LD L,A                           ; $3C7B  6F
        ADD HL,DE                        ; $3C7C  19
SUB_3C47_5:
        EX DE,HL                         ; $3C7D  EB
        LD A,(SUB_0C4B_2)                ; $3C7E  3A 85 0C
        CP E                             ; $3C81  BB
        JP NZ,SUB_3C47_1                 ; $3C82  C2 62 3C
        LD A,(SUB_0C4B_3)                ; $3C85  3A 86 0C
        CP D                             ; $3C88  BA
        JR NZ,SUB_3C47_1                 ; $3C89  20 D7
        LD A,(SUB_0C4B_1)                ; $3C8B  3A 84 0C
        OR A                             ; $3C8E  B7
        JR Z,SUB_3C47_8                  ; $3C8F  28 14
        XOR A                            ; $3C91  AF
        LD (SUB_0C4B_1),A                ; $3C92  32 84 0C
SUB_3C47_6:
        LD HL,(SUB_0B2A_41)              ; $3C95  2A 94 0B
        LD (SUB_0C4B_2),HL               ; $3C98  22 85 0C
        LD HL,(SUB_0B2A_40)              ; $3C9B  2A 92 0B
        JR SUB_3C47_5                    ; $3C9E  18 DD
SUB_3C47_7:
        LD D,A                           ; $3CA0  57
        LD E,A                           ; $3CA1  5F
        POP BC                           ; $3CA2  C1
        EX (SP),HL                       ; $3CA3  E3
        RET                              ; $3CA4  C9
SUB_3C47_8:
        POP HL                           ; $3CA5  E1
        EX (SP),HL                       ; $3CA6  E3
        PUSH DE                          ; $3CA7  D5
        LD DE,SUB_1C11_8                 ; $3CA8  11 7F 1C
        CALL SUB_459D                    ; $3CAB  CD 9D 45
        JR Z,SUB_3C47_7                  ; $3CAE  28 F0
        LD DE,SUB_5012_3                 ; $3CB0  11 23 50
        CALL SUB_459D                    ; $3CB3  CD 9D 45
        JP Z,SUB_3C47_7                  ; $3CB6  CA A0 3C
        LD DE,SUB_5012_4                 ; $3CB9  11 32 50
        CALL SUB_459D                    ; $3CBC  CD 9D 45
        JR Z,SUB_3C47_7                  ; $3CBF  28 DF
        LD DE,SUB_1CC1_5                 ; $3CC1  11 DA 1C
        CALL SUB_459D                    ; $3CC4  CD 9D 45
        POP DE                           ; $3CC7  D1
        JR Z,SUB_3D15_2                  ; $3CC8  28 56
        EX (SP),HL                       ; $3CCA  E3
        PUSH HL                          ; $3CCB  E5
        PUSH BC                          ; $3CCC  C5
        LD A,(SUB_0B2A_5)                ; $3CCD  3A 37 0B
        LD B,A                           ; $3CD0  47
        LD A,(SUB_0752_56)               ; $3CD1  3A 94 08
        ADD A,B                          ; $3CD4  80
        INC A                            ; $3CD5  3C
        LD C,A                           ; $3CD6  4F
        PUSH BC                          ; $3CD7  C5
        LD B,$00                         ; $3CD8  06 00
        INC BC                           ; $3CDA  03
        INC BC                           ; $3CDB  03
        INC BC                           ; $3CDC  03
        LD HL,(SUB_0B2A_42)              ; $3CDD  2A 96 0B
        PUSH HL                          ; $3CE0  E5
        ADD HL,BC                        ; $3CE1  09
        POP BC                           ; $3CE2  C1
        PUSH HL                          ; $3CE3  E5
        CALL SUB_448F                    ; $3CE4  CD 8F 44
        POP HL                           ; $3CE7  E1
        LD (SUB_0B2A_42),HL              ; $3CE8  22 96 0B
        LD H,B                           ; $3CEB  60
        LD L,C                           ; $3CEC  69
        LD (SUB_0B2A_41),HL              ; $3CED  22 94 0B
SUB_3C47_9:
        DEC HL                           ; $3CF0  2B
        LD (HL),$00                      ; $3CF1  36 00
        CALL SUB_459D                    ; $3CF3  CD 9D 45
        JR NZ,SUB_3C47_9                 ; $3CF6  20 F8
        POP DE                           ; $3CF8  D1
        LD (HL),D                        ; $3CF9  72
        INC HL                           ; $3CFA  23
        POP DE                           ; $3CFB  D1
        LD (HL),E                        ; $3CFC  73
        INC HL                           ; $3CFD  23
        LD (HL),D                        ; $3CFE  72
        CALL SUB_3EAC                    ; $3CFF  CD AC 3E
        EX DE,HL                         ; $3D02  EB
        INC DE                           ; $3D03  13
        POP HL                           ; $3D04  E1
        RET                              ; $3D05  C9
SUB_3C47_10:
        INC DE                           ; $3D06  13
        LD A,(SUB_0752_56)               ; $3D07  3A 94 08
        LD H,A                           ; $3D0A  67
        LD A,(DE)                        ; $3D0B  1A
        CP H                             ; $3D0C  BC
        JP NZ,SUB_3C47_3                 ; $3D0D  C2 76 3C
        OR A                             ; $3D10  B7
        JR NZ,SUB_3D15_1                 ; $3D11  20 03
        INC DE                           ; $3D13  13
        POP HL                           ; $3D14  E1
SUB_3D15:
        RET                              ; $3D15  C9
SUB_3D15_1:
        EX DE,HL                         ; $3D16  EB
        CALL SUB_3EC0                    ; $3D17  CD C0 3E
        EX DE,HL                         ; $3D1A  EB
        JP NZ,SUB_3C47_4                 ; $3D1B  C2 77 3C
        POP HL                           ; $3D1E  E1
        RET                              ; $3D1F  C9
SUB_3D15_2:
        LD (SUB_0C98_6),A                ; $3D20  32 D7 0C
        LD H,A                           ; $3D23  67
        LD L,A                           ; $3D24  6F
SUB_3D15_3:
        LD (SUB_0C98_4),HL               ; $3D25  22 D4 0C
        CALL SUB_1DE3                    ; $3D28  CD E3 1D
        JR NZ,SUB_3D15_5                 ; $3D2B  20 06
SUB_3D15_4:
        LD HL,SUB_0D04_4+1               ; $3D2D  21 14 0D
        LD (SUB_0C98_4),HL               ; $3D30  22 D4 0C
SUB_3D15_5:
        POP HL                           ; $3D33  E1
        RET                              ; $3D34  C9
SUB_3D15_6:
        PUSH HL                          ; $3D35  E5
        LD HL,(SUB_0B2A_4)               ; $3D36  2A 36 0B
        EX (SP),HL                       ; $3D39  E3
        LD D,A                           ; $3D3A  57
SUB_3D15_7:
        PUSH DE                          ; $3D3B  D5
        PUSH BC                          ; $3D3C  C5
        LD DE,SUB_0752_56                ; $3D3D  11 94 08
        LD A,(DE)                        ; $3D40  1A
        OR A                             ; $3D41  B7
        JR Z,SUB_3D4E_2                  ; $3D42  28 2F
        EX DE,HL                         ; $3D44  EB
        ADD A,$02                        ; $3D45  C6 02
        RRA                              ; $3D47  1F
        LD C,A                           ; $3D48  4F
        CALL SUB_449F                    ; $3D49  CD 9F 44
        LD A,C                           ; $3D4C  79
SUB_3D15_8:
        LD C,(HL)                        ; $3D4D  4E
SUB_3D4E:
        INC HL                           ; $3D4E  23
        LD B,(HL)                        ; $3D4F  46
        INC HL                           ; $3D50  23
        PUSH BC                          ; $3D51  C5
        DEC A                            ; $3D52  3D
        JR NZ,SUB_3D15_8                 ; $3D53  20 F8
        PUSH HL                          ; $3D55  E5
        LD A,(SUB_0752_56)               ; $3D56  3A 94 08
        PUSH AF                          ; $3D59  F5
        EX DE,HL                         ; $3D5A  EB
        CALL SUB_14E4                    ; $3D5B  CD E4 14
        POP AF                           ; $3D5E  F1
        LD (SUB_0752_60),HL              ; $3D5F  22 BB 08
        POP HL                           ; $3D62  E1
        ADD A,$02                        ; $3D63  C6 02
        RRA                              ; $3D65  1F
SUB_3D4E_1:
        POP BC                           ; $3D66  C1
        DEC HL                           ; $3D67  2B
        LD (HL),B                        ; $3D68  70
        DEC HL                           ; $3D69  2B
        LD (HL),C                        ; $3D6A  71
        DEC A                            ; $3D6B  3D
        JR NZ,SUB_3D4E_1                 ; $3D6C  20 F8
        LD HL,(SUB_0752_60)              ; $3D6E  2A BB 08
        JR SUB_3D4E_3                    ; $3D71  18 07
SUB_3D4E_2:
        CALL SUB_14E4                    ; $3D73  CD E4 14
        XOR A                            ; $3D76  AF
        LD (SUB_0752_56),A               ; $3D77  32 94 08
SUB_3D4E_3:
        LD A,(SUB_0C4B_12)               ; $3D7A  3A 96 0C
        OR A                             ; $3D7D  B7
        JR Z,SUB_3D4E_4                  ; $3D7E  28 06
        LD A,D                           ; $3D80  7A
        OR E                             ; $3D81  B3
        DEC DE                           ; $3D82  1B
        JP Z,SUB_3D4E_14                 ; $3D83  CA EA 3D
SUB_3D4E_4:
        POP BC                           ; $3D86  C1
        POP AF                           ; $3D87  F1
        EX DE,HL                         ; $3D88  EB
        EX (SP),HL                       ; $3D89  E3
        PUSH HL                          ; $3D8A  E5
        EX DE,HL                         ; $3D8B  EB
        INC A                            ; $3D8C  3C
        LD D,A                           ; $3D8D  57
        LD A,(HL)                        ; $3D8E  7E
        CP $2C                           ; $3D8F  FE 2C
        JP Z,SUB_3D15_7                  ; $3D91  CA 3B 3D
        CP $29                           ; $3D94  FE 29
        JR Z,SUB_3D4E_5                  ; $3D96  28 05
        CP $5D                           ; $3D98  FE 5D
        JP NZ,SUB_0D20_20                ; $3D9A  C2 92 0D
SUB_3D4E_5:
        CALL SUB_13E4                    ; $3D9D  CD E4 13
        LD (SUB_0B2A_37),HL              ; $3DA0  22 8C 0B
        POP HL                           ; $3DA3  E1
        LD (SUB_0B2A_4),HL               ; $3DA4  22 36 0B
        LD E,$00                         ; $3DA7  1E 00
        PUSH DE                          ; $3DA9  D5
SUB_3D4E_6:
        LD DE,$F5E5                      ; $3DAA  11 E5 F5
        LD HL,(SUB_0B2A_41)              ; $3DAD  2A 94 0B
SUB_3D4E_7:
        LD A,$19                         ; $3DB0  3E 19
        EX DE,HL                         ; $3DB2  EB
        LD HL,(SUB_0B2A_42)              ; $3DB3  2A 96 0B
        EX DE,HL                         ; $3DB6  EB
        CALL SUB_459D                    ; $3DB7  CD 9D 45
        JR Z,SUB_3D4E_16                 ; $3DBA  28 45
        LD E,(HL)                        ; $3DBC  5E
        INC HL                           ; $3DBD  23
        LD A,(HL)                        ; $3DBE  7E
        INC HL                           ; $3DBF  23
        CP C                             ; $3DC0  B9
SUB_3D4E_8:
        JR NZ,SUB_3D4E_9                 ; $3DC1  20 0A
        LD A,(SUB_0B2A_5)                ; $3DC3  3A 37 0B
        CP E                             ; $3DC6  BB
        JR NZ,SUB_3D4E_9                 ; $3DC7  20 04
        LD A,(HL)                        ; $3DC9  7E
        CP B                             ; $3DCA  B8
        JR Z,SUB_3D4E_15                 ; $3DCB  28 23
SUB_3D4E_9:
        INC HL                           ; $3DCD  23
SUB_3D4E_10:
        LD E,(HL)                        ; $3DCE  5E
        INC E                            ; $3DCF  1C
        LD D,$00                         ; $3DD0  16 00
        ADD HL,DE                        ; $3DD2  19
SUB_3D4E_11:
        LD E,(HL)                        ; $3DD3  5E
        INC HL                           ; $3DD4  23
        LD D,(HL)                        ; $3DD5  56
        INC HL                           ; $3DD6  23
        JR NZ,SUB_3D4E_7+1               ; $3DD7  20 D8
        LD A,(SUB_0B2A_4)                ; $3DD9  3A 36 0B
        OR A                             ; $3DDC  B7
        JP NZ,SUB_0D20_23+1              ; $3DDD  C2 9B 0D
        POP AF                           ; $3DE0  F1
SUB_3D4E_12:
        LD B,H                           ; $3DE1  44
        LD C,L                           ; $3DE2  4D
SUB_3D4E_13:
        JP Z,SUB_2990_7                  ; $3DE3  CA E1 29
        SUB (HL)                         ; $3DE6  96
        JP Z,SUB_3D4E_28                 ; $3DE7  CA 69 3E
SUB_3D4E_14:
        LD DE,$0009                      ; $3DEA  11 09 00
        JP SUB_0D20_28                   ; $3DED  C3 AC 0D
SUB_3D4E_15:
        INC HL                           ; $3DF0  23
        LD A,(SUB_0752_56)               ; $3DF1  3A 94 08
        CP (HL)                          ; $3DF4  BE
        JR NZ,SUB_3D4E_10                ; $3DF5  20 D7
        INC HL                           ; $3DF7  23
        OR A                             ; $3DF8  B7
        JR Z,SUB_3D4E_11                 ; $3DF9  28 D8
        DEC HL                           ; $3DFB  2B
        CALL SUB_3EC0                    ; $3DFC  CD C0 3E
        JR SUB_3D4E_11                   ; $3DFF  18 D2
SUB_3D4E_16:
        LD A,(SUB_0B2A_5)                ; $3E01  3A 37 0B
        LD (HL),A                        ; $3E04  77
        INC HL                           ; $3E05  23
        LD E,A                           ; $3E06  5F
        LD D,$00                         ; $3E07  16 00
        POP AF                           ; $3E09  F1
SUB_3D4E_17:
        JP Z,SUB_3D4E_33                 ; $3E0A  CA 9F 3E
        LD (HL),C                        ; $3E0D  71
        INC HL                           ; $3E0E  23
        LD (HL),B                        ; $3E0F  70
        CALL SUB_3EAC                    ; $3E10  CD AC 3E
        INC HL                           ; $3E13  23
        LD C,A                           ; $3E14  4F
        CALL SUB_449F                    ; $3E15  CD 9F 44
SUB_3D4E_18:
        INC HL                           ; $3E18  23
        INC HL                           ; $3E19  23
        LD (SUB_0B2A_20),HL              ; $3E1A  22 6D 0B
        LD (HL),C                        ; $3E1D  71
SUB_3D4E_19:
        INC HL                           ; $3E1E  23
        LD A,(SUB_0B2A_4)                ; $3E1F  3A 36 0B
        RLA                              ; $3E22  17
        LD A,C                           ; $3E23  79
SUB_3D4E_20:
        JR C,SUB_3D4E_22                 ; $3E24  38 0C
        PUSH AF                          ; $3E26  F5
        LD A,(SUB_0C4B_12)               ; $3E27  3A 96 0C
SUB_3D4E_21:
        XOR $0B                          ; $3E2A  EE 0B
        LD C,A                           ; $3E2C  4F
        LD B,$00                         ; $3E2D  06 00
        POP AF                           ; $3E2F  F1
        JR NC,SUB_3D4E_23                ; $3E30  30 02
SUB_3D4E_22:
        POP BC                           ; $3E32  C1
        INC BC                           ; $3E33  03
SUB_3D4E_23:
        LD (HL),C                        ; $3E34  71
        PUSH AF                          ; $3E35  F5
        INC HL                           ; $3E36  23
        LD (HL),B                        ; $3E37  70
        INC HL                           ; $3E38  23
        CALL SUB_2D79                    ; $3E39  CD 79 2D
        POP AF                           ; $3E3C  F1
        DEC A                            ; $3E3D  3D
        JR NZ,SUB_3D4E_20                ; $3E3E  20 E4
        PUSH AF                          ; $3E40  F5
        LD B,D                           ; $3E41  42
        LD C,E                           ; $3E42  4B
        EX DE,HL                         ; $3E43  EB
        ADD HL,DE                        ; $3E44  19
SUB_3D4E_24:
        JP C,SUB_449F_1                  ; $3E45  DA B4 44
        CALL SUB_44C2                    ; $3E48  CD C2 44
SUB_3D4E_25:
        LD (SUB_0B2A_42),HL              ; $3E4B  22 96 0B
SUB_3D4E_26:
        DEC HL                           ; $3E4E  2B
        LD (HL),$00                      ; $3E4F  36 00
        CALL SUB_459D                    ; $3E51  CD 9D 45
        JR NZ,SUB_3D4E_26                ; $3E54  20 F8
        INC BC                           ; $3E56  03
        LD D,A                           ; $3E57  57
        LD HL,(SUB_0B2A_20)              ; $3E58  2A 6D 0B
        LD E,(HL)                        ; $3E5B  5E
        EX DE,HL                         ; $3E5C  EB
        ADD HL,HL                        ; $3E5D  29
SUB_3D4E_27:
        ADD HL,BC                        ; $3E5E  09
        EX DE,HL                         ; $3E5F  EB
        DEC HL                           ; $3E60  2B
        DEC HL                           ; $3E61  2B
        LD (HL),E                        ; $3E62  73
        INC HL                           ; $3E63  23
        LD (HL),D                        ; $3E64  72
        INC HL                           ; $3E65  23
        POP AF                           ; $3E66  F1
        JR C,SUB_3D4E_32                 ; $3E67  38 32
SUB_3D4E_28:
        LD B,A                           ; $3E69  47
        LD C,A                           ; $3E6A  4F
        LD A,(HL)                        ; $3E6B  7E
        INC HL                           ; $3E6C  23
SUB_3D4E_29:
        LD D,$E1                         ; $3E6D  16 E1
        LD E,(HL)                        ; $3E6F  5E
        INC HL                           ; $3E70  23
        LD D,(HL)                        ; $3E71  56
        INC HL                           ; $3E72  23
        EX (SP),HL                       ; $3E73  E3
        PUSH AF                          ; $3E74  F5
        CALL SUB_459D                    ; $3E75  CD 9D 45
        JP NC,SUB_3D4E_14                ; $3E78  D2 EA 3D
        CALL SUB_2D79                    ; $3E7B  CD 79 2D
        ADD HL,DE                        ; $3E7E  19
        POP AF                           ; $3E7F  F1
        DEC A                            ; $3E80  3D
        LD B,H                           ; $3E81  44
        LD C,L                           ; $3E82  4D
        JR NZ,SUB_3D4E_29+1              ; $3E83  20 E9
        LD A,(SUB_0B2A_5)                ; $3E85  3A 37 0B
        LD B,H                           ; $3E88  44
        LD C,L                           ; $3E89  4D
        ADD HL,HL                        ; $3E8A  29
        SUB $04                          ; $3E8B  D6 04
        JR C,SUB_3D4E_30                 ; $3E8D  38 04
        ADD HL,HL                        ; $3E8F  29
        JR Z,SUB_3D4E_31                 ; $3E90  28 06
        ADD HL,HL                        ; $3E92  29
SUB_3D4E_30:
        OR A                             ; $3E93  B7
        JP PO,SUB_3D4E_31                ; $3E94  E2 98 3E
        ADD HL,BC                        ; $3E97  09
SUB_3D4E_31:
        POP BC                           ; $3E98  C1
        ADD HL,BC                        ; $3E99  09
        EX DE,HL                         ; $3E9A  EB
SUB_3D4E_32:
        LD HL,(SUB_0B2A_37)              ; $3E9B  2A 8C 0B
        RET                              ; $3E9E  C9
SUB_3D4E_33:
        SCF                              ; $3E9F  37
        SBC A,A                          ; $3EA0  9F
        POP HL                           ; $3EA1  E1
        RET                              ; $3EA2  C9
SUB_3EA3:
        LD A,(HL)                        ; $3EA3  7E
        INC HL                           ; $3EA4  23
SUB_3EA5:
        PUSH BC                          ; $3EA5  C5
        LD B,$00                         ; $3EA6  06 00
        LD C,A                           ; $3EA8  4F
        ADD HL,BC                        ; $3EA9  09
        POP BC                           ; $3EAA  C1
        RET                              ; $3EAB  C9
SUB_3EAC:
        PUSH BC                          ; $3EAC  C5
        PUSH DE                          ; $3EAD  D5
        PUSH AF                          ; $3EAE  F5
        LD DE,SUB_0752_56                ; $3EAF  11 94 08
        LD A,(DE)                        ; $3EB2  1A
        LD B,A                           ; $3EB3  47
        INC B                            ; $3EB4  04
SUB_3EAC_1:
        LD A,(DE)                        ; $3EB5  1A
        INC DE                           ; $3EB6  13
        INC HL                           ; $3EB7  23
        LD (HL),A                        ; $3EB8  77
        DEC B                            ; $3EB9  05
        JR NZ,SUB_3EAC_1                 ; $3EBA  20 F9
        POP AF                           ; $3EBC  F1
        POP DE                           ; $3EBD  D1
        POP BC                           ; $3EBE  C1
        RET                              ; $3EBF  C9
SUB_3EC0:
        PUSH DE                          ; $3EC0  D5
        PUSH BC                          ; $3EC1  C5
SUB_3EC0_1:
        LD DE,SUB_0752_57                ; $3EC2  11 95 08
        LD B,A                           ; $3EC5  47
        INC HL                           ; $3EC6  23
        INC B                            ; $3EC7  04
SUB_3EC0_2:
        DEC B                            ; $3EC8  05
        JR Z,SUB_3EC0_3                  ; $3EC9  28 0D
        LD A,(DE)                        ; $3ECB  1A
        CP (HL)                          ; $3ECC  BE
        INC HL                           ; $3ECD  23
        INC DE                           ; $3ECE  13
        JR Z,SUB_3EC0_2                  ; $3ECF  28 F7
        LD A,B                           ; $3ED1  78
        DEC A                            ; $3ED2  3D
        CALL NZ,SUB_3EA5                 ; $3ED3  C4 A5 3E
        XOR A                            ; $3ED6  AF
        DEC A                            ; $3ED7  3D
SUB_3EC0_3:
        POP BC                           ; $3ED8  C1
        POP DE                           ; $3ED9  D1
        RET                              ; $3EDA  C9
SUB_3EDB:
        LD (SUB_0752_33+2),A             ; $3EDB  32 58 08
        LD HL,(SUB_0B2A_32)              ; $3EDE  2A 83 0B
        OR H                             ; $3EE1  B4
        AND L                            ; $3EE2  A5
SUB_3EDB_1:
        INC A                            ; $3EE3  3C
        EX DE,HL                         ; $3EE4  EB
SUB_3EDB_2:
        RET Z                            ; $3EE5  C8
        JR SUB_3EDB_4                    ; $3EE6  18 04
SUB_3EDB_3:
        CALL SUB_14F0                    ; $3EE8  CD F0 14
        RET NZ                           ; $3EEB  C0
SUB_3EDB_4:
        POP HL                           ; $3EEC  E1
SUB_3EDB_5:
        EX DE,HL                         ; $3EED  EB
        LD (SUB_0B2A_33),HL              ; $3EEE  22 85 0B
        EX DE,HL                         ; $3EF1  EB
SUB_3EDB_6:
        CALL SUB_0FAB                    ; $3EF2  CD AB 0F
SUB_3EDB_7:
        JP NC,SUB_1506_9                 ; $3EF5  D2 91 15
        LD H,B                           ; $3EF8  60
        LD L,C                           ; $3EF9  69
        INC HL                           ; $3EFA  23
        INC HL                           ; $3EFB  23
        LD C,(HL)                        ; $3EFC  4E
        INC HL                           ; $3EFD  23
        LD B,(HL)                        ; $3EFE  46
        INC HL                           ; $3EFF  23
        PUSH BC                          ; $3F00  C5
        CALL SUB_2124                    ; $3F01  CD 24 21
SUB_3EDB_8:
        POP HL                           ; $3F04  E1
SUB_3EDB_9:
        PUSH HL                          ; $3F05  E5
        LD A,H                           ; $3F06  7C
        AND L                            ; $3F07  A5
        INC A                            ; $3F08  3C
        LD A,$21                         ; $3F09  3E 21
        CALL Z,SUB_4291                  ; $3F0B  CC 91 42
        CALL NZ,SUB_3391                 ; $3F0E  C4 91 33
        LD A,$20                         ; $3F11  3E 20
        CALL SUB_4291                    ; $3F13  CD 91 42
        LD HL,SUB_0925_12                ; $3F16  21 31 0A
        PUSH HL                          ; $3F19  E5
        LD C,$FF                         ; $3F1A  0E FF
SUB_3EDB_10:
        INC C                            ; $3F1C  0C
        LD A,(HL)                        ; $3F1D  7E
SUB_3EDB_11:
        INC HL                           ; $3F1E  23
        OR A                             ; $3F1F  B7
        JR NZ,SUB_3EDB_10                ; $3F20  20 FA
        POP HL                           ; $3F22  E1
        LD B,A                           ; $3F23  47
SUB_3EDB_12:
        LD D,$00                         ; $3F24  16 00
SUB_3EDB_13:
        CALL SUB_43DA                    ; $3F26  CD DA 43
        OR A                             ; $3F29  B7
        JR Z,SUB_3EDB_13                 ; $3F2A  28 FA
        CALL SUB_1CE8                    ; $3F2C  CD E8 1C
        SUB $30                          ; $3F2F  D6 30
        JR C,SUB_3EDB_14                 ; $3F31  38 0E
        CP $0A                           ; $3F33  FE 0A
        JR NC,SUB_3EDB_14                ; $3F35  30 0A
        LD E,A                           ; $3F37  5F
        LD A,D                           ; $3F38  7A
        RLCA                             ; $3F39  07
        RLCA                             ; $3F3A  07
        ADD A,D                          ; $3F3B  82
        RLCA                             ; $3F3C  07
        ADD A,E                          ; $3F3D  83
        LD D,A                           ; $3F3E  57
        JR SUB_3EDB_13                   ; $3F3F  18 E5
SUB_3EDB_14:
        PUSH HL                          ; $3F41  E5
        LD HL,SUB_3EDB_12                ; $3F42  21 24 3F
        EX (SP),HL                       ; $3F45  E3
        DEC D                            ; $3F46  15
        INC D                            ; $3F47  14
        JP NZ,SUB_3EDB_15                ; $3F48  C2 4C 3F
        INC D                            ; $3F4B  14
SUB_3EDB_15:
        CP $D8                           ; $3F4C  FE D8
        JP Z,SUB_4068_6                  ; $3F4E  CA 9E 40
        CP $4F                           ; $3F51  FE 4F
        JP Z,SUB_4068_7                  ; $3F53  CA A9 40
        CP $DD                           ; $3F56  FE DD
        JP Z,SUB_4068_8                  ; $3F58  CA B6 40
        CP $F0                           ; $3F5B  FE F0
        JR Z,SUB_3FA4                    ; $3F5D  28 45
        CP $31                           ; $3F5F  FE 31
        JR C,SUB_3EDB_16                 ; $3F61  38 02
        SUB $20                          ; $3F63  D6 20
SUB_3EDB_16:
        CP $21                           ; $3F65  FE 21
        JP Z,SUB_4068_11                 ; $3F67  CA CB 40
        CP $1C                           ; $3F6A  FE 1C
        JP Z,SUB_3FA4_6                  ; $3F6C  CA DA 3F
        CP $23                           ; $3F6F  FE 23
        JR Z,SUB_3FA4_2                  ; $3F71  28 43
        CP $19                           ; $3F73  FE 19
        JP Z,SUB_3FF9_8                  ; $3F75  CA 2E 40
        CP $14                           ; $3F78  FE 14
        JP Z,SUB_3FA4_7                  ; $3F7A  CA E4 3F
        CP $13                           ; $3F7D  FE 13
        JP Z,SUB_3FF9_1                  ; $3F7F  CA FF 3F
        CP $15                           ; $3F82  FE 15
        JP Z,SUB_4068_9                  ; $3F84  CA B9 40
        CP $28                           ; $3F87  FE 28
        JP Z,SUB_3FF9_7                  ; $3F89  CA 29 40
        CP $1B                           ; $3F8C  FE 1B
        JR Z,SUB_3FA4_1                  ; $3F8E  28 20
        CP $18                           ; $3F90  FE 18
        JP Z,SUB_3FF9_6                  ; $3F92  CA 26 40
        CP $11                           ; $3F95  FE 11
        LD A,$07                         ; $3F97  3E 07
        JP NZ,SUB_4291                   ; $3F99  C2 91 42
        POP BC                           ; $3F9C  C1
        POP DE                           ; $3F9D  D1
        CALL SUB_4406                    ; $3F9E  CD 06 44
        JP SUB_3EDB_5                    ; $3FA1  C3 ED 3E
SUB_3FA4:
        LD A,(HL)                        ; $3FA4  7E
        OR A                             ; $3FA5  B7
        RET Z                            ; $3FA6  C8
        INC B                            ; $3FA7  04
        CALL SUB_447E                    ; $3FA8  CD 7E 44
        INC HL                           ; $3FAB  23
        DEC D                            ; $3FAC  15
        JR NZ,SUB_3FA4                   ; $3FAD  20 F5
        RET                              ; $3FAF  C9
SUB_3FA4_1:
        PUSH HL                          ; $3FB0  E5
        LD HL,SUB_3FF9                   ; $3FB1  21 F9 3F
        EX (SP),HL                       ; $3FB4  E3
        SCF                              ; $3FB5  37
SUB_3FA4_2:
        PUSH AF                          ; $3FB6  F5
        CALL SUB_43DA                    ; $3FB7  CD DA 43
        LD E,A                           ; $3FBA  5F
        POP AF                           ; $3FBB  F1
        PUSH AF                          ; $3FBC  F5
        CALL C,SUB_3FF9                  ; $3FBD  DC F9 3F
SUB_3FA4_3:
        LD A,(HL)                        ; $3FC0  7E
        OR A                             ; $3FC1  B7
        JP Z,SUB_3FA4_5                  ; $3FC2  CA D8 3F
        CALL SUB_447E                    ; $3FC5  CD 7E 44
        POP AF                           ; $3FC8  F1
        PUSH AF                          ; $3FC9  F5
        CALL C,SUB_4068                  ; $3FCA  DC 68 40
        JR C,SUB_3FA4_4                  ; $3FCD  38 02
        INC HL                           ; $3FCF  23
        INC B                            ; $3FD0  04
SUB_3FA4_4:
        LD A,(HL)                        ; $3FD1  7E
        CP E                             ; $3FD2  BB
        JR NZ,SUB_3FA4_3                 ; $3FD3  20 EB
        DEC D                            ; $3FD5  15
        JR NZ,SUB_3FA4_3                 ; $3FD6  20 E8
SUB_3FA4_5:
        POP AF                           ; $3FD8  F1
        RET                              ; $3FD9  C9
SUB_3FA4_6:
        CALL SUB_211B                    ; $3FDA  CD 1B 21
        CALL SUB_4406                    ; $3FDD  CD 06 44
        POP BC                           ; $3FE0  C1
        JP SUB_3EDB_8                    ; $3FE1  C3 04 3F
SUB_3FA4_7:
        LD A,(HL)                        ; $3FE4  7E
        OR A                             ; $3FE5  B7
        RET Z                            ; $3FE6  C8
        LD A,$5C                         ; $3FE7  3E 5C
        CALL SUB_447E                    ; $3FE9  CD 7E 44
SUB_3FA4_8:
        LD A,(HL)                        ; $3FEC  7E
        OR A                             ; $3FED  B7
        JR Z,SUB_3FF9                    ; $3FEE  28 09
        CALL SUB_447E                    ; $3FF0  CD 7E 44
        CALL SUB_4068                    ; $3FF3  CD 68 40
        DEC D                            ; $3FF6  15
        JR NZ,SUB_3FA4_8                 ; $3FF7  20 F3
SUB_3FF9:
        LD A,$5C                         ; $3FF9  3E 5C
        CALL SUB_4291                    ; $3FFB  CD 91 42
        RET                              ; $3FFE  C9
SUB_3FF9_1:
        LD A,(HL)                        ; $3FFF  7E
SUB_3FF9_2:
        OR A                             ; $4000  B7
        RET Z                            ; $4001  C8
SUB_3FF9_3:
        CALL SUB_43DA                    ; $4002  CD DA 43
        CP $20                           ; $4005  FE 20
        JR NC,SUB_3FF9_4                 ; $4007  30 13
        CP $0A                           ; $4009  FE 0A
        JR Z,SUB_3FF9_4                  ; $400B  28 0F
        CP $07                           ; $400D  FE 07
        JR Z,SUB_3FF9_4                  ; $400F  28 0B
        CP $09                           ; $4011  FE 09
        JR Z,SUB_3FF9_4                  ; $4013  28 07
        LD A,$07                         ; $4015  3E 07
        CALL SUB_4291                    ; $4017  CD 91 42
        JR SUB_3FF9_3                    ; $401A  18 E6
SUB_3FF9_4:
        LD (HL),A                        ; $401C  77
SUB_3FF9_5:
        CALL SUB_447E                    ; $401D  CD 7E 44
        INC HL                           ; $4020  23
        INC B                            ; $4021  04
        DEC D                            ; $4022  15
        JR NZ,SUB_3FF9_1                 ; $4023  20 DA
        RET                              ; $4025  C9
SUB_3FF9_6:
        LD (HL),$00                      ; $4026  36 00
        LD C,B                           ; $4028  48
SUB_3FF9_7:
        LD D,$FF                         ; $4029  16 FF
        CALL SUB_3FA4                    ; $402B  CD A4 3F
SUB_3FF9_8:
        CALL SUB_43DA                    ; $402E  CD DA 43
        CP $7F                           ; $4031  FE 7F
        JR Z,SUB_3FF9_9                  ; $4033  28 24
        CP $08                           ; $4035  FE 08
        JR Z,SUB_3FF9_10                 ; $4037  28 22
        CP $0D                           ; $4039  FE 0D
        JP Z,SUB_4068_8                  ; $403B  CA B6 40
        CP $1B                           ; $403E  FE 1B
        RET Z                            ; $4040  C8
        CP $08                           ; $4041  FE 08
        JR Z,SUB_3FF9_10                 ; $4043  28 16
        CP $0A                           ; $4045  FE 0A
        JR Z,SUB_4068_2                  ; $4047  28 2E
        CP $07                           ; $4049  FE 07
        JR Z,SUB_4068_2                  ; $404B  28 2A
        CP $09                           ; $404D  FE 09
        JR Z,SUB_4068_2                  ; $404F  28 26
        CP $20                           ; $4051  FE 20
        JR C,SUB_3FF9_8                  ; $4053  38 D9
        CP $5F                           ; $4055  FE 5F
        JR NZ,SUB_4068_2                 ; $4057  20 1E
SUB_3FF9_9:
        LD A,$5F                         ; $4059  3E 5F
SUB_3FF9_10:
        DEC B                            ; $405B  05
        INC B                            ; $405C  04
        JR Z,SUB_4068_3                  ; $405D  28 1F
        CALL SUB_447E                    ; $405F  CD 7E 44
        DEC HL                           ; $4062  2B
        DEC B                            ; $4063  05
        LD DE,SUB_3FF9_8                 ; $4064  11 2E 40
        PUSH DE                          ; $4067  D5
SUB_4068:
        PUSH HL                          ; $4068  E5
        DEC C                            ; $4069  0D
SUB_4068_1:
        LD A,(HL)                        ; $406A  7E
        OR A                             ; $406B  B7
        SCF                              ; $406C  37
        JP Z,SUB_2990_7                  ; $406D  CA E1 29
        INC HL                           ; $4070  23
        LD A,(HL)                        ; $4071  7E
        DEC HL                           ; $4072  2B
        LD (HL),A                        ; $4073  77
        INC HL                           ; $4074  23
        JR SUB_4068_1                    ; $4075  18 F3
SUB_4068_2:
        PUSH AF                          ; $4077  F5
        LD A,C                           ; $4078  79
        CP $FF                           ; $4079  FE FF
        JR C,SUB_4068_5                  ; $407B  38 08
        POP AF                           ; $407D  F1
SUB_4068_3:
        LD A,$07                         ; $407E  3E 07
        CALL SUB_4291                    ; $4080  CD 91 42
SUB_4068_4:
        JR SUB_3FF9_8                    ; $4083  18 A9
SUB_4068_5:
        SUB B                            ; $4085  90
        INC C                            ; $4086  0C
        INC B                            ; $4087  04
        PUSH BC                          ; $4088  C5
        EX DE,HL                         ; $4089  EB
        LD L,A                           ; $408A  6F
        LD H,$00                         ; $408B  26 00
        ADD HL,DE                        ; $408D  19
        LD B,H                           ; $408E  44
        LD C,L                           ; $408F  4D
        INC HL                           ; $4090  23
        CALL SUB_4492                    ; $4091  CD 92 44
        POP BC                           ; $4094  C1
        POP AF                           ; $4095  F1
        LD (HL),A                        ; $4096  77
        CALL SUB_447E                    ; $4097  CD 7E 44
        INC HL                           ; $409A  23
        JP SUB_4068_4                    ; $409B  C3 83 40
SUB_4068_6:
        LD A,B                           ; $409E  78
        OR A                             ; $409F  B7
        RET Z                            ; $40A0  C8
        CALL SUB_4DC3                    ; $40A1  CD C3 4D
        DEC B                            ; $40A4  05
        DEC D                            ; $40A5  15
        JR NZ,SUB_4068_7                 ; $40A6  20 01
        RET                              ; $40A8  C9
SUB_4068_7:
        LD A,B                           ; $40A9  78
        OR A                             ; $40AA  B7
        RET Z                            ; $40AB  C8
        DEC B                            ; $40AC  05
        DEC HL                           ; $40AD  2B
        LD A,(HL)                        ; $40AE  7E
        CALL SUB_447E                    ; $40AF  CD 7E 44
        DEC D                            ; $40B2  15
        JR NZ,SUB_4068_7                 ; $40B3  20 F4
        RET                              ; $40B5  C9
SUB_4068_8:
        CALL SUB_211B                    ; $40B6  CD 1B 21
SUB_4068_9:
        CALL SUB_4406                    ; $40B9  CD 06 44
        POP BC                           ; $40BC  C1
        POP DE                           ; $40BD  D1
        LD A,D                           ; $40BE  7A
        AND E                            ; $40BF  A3
        INC A                            ; $40C0  3C
SUB_4068_10:
        LD HL,SUB_0925_11                ; $40C1  21 30 0A
        RET Z                            ; $40C4  C8
        SCF                              ; $40C5  37
        PUSH AF                          ; $40C6  F5
        INC HL                           ; $40C7  23
        JP SUB_0D20_47                   ; $40C8  C3 C9 0E
SUB_4068_11:
        POP BC                           ; $40CB  C1
        POP DE                           ; $40CC  D1
        LD A,D                           ; $40CD  7A
        AND E                            ; $40CE  A3
        INC A                            ; $40CF  3C
        JP Z,SUB_43F9_1                  ; $40D0  CA 01 44
        JP SUB_0D20_39                   ; $40D3  C3 46 0E
SUB_4068_12:
        CALL SUB_1A91                    ; $40D6  CD 91 1A
        CALL SUB_2CB3                    ; $40D9  CD B3 2C
        CALL SUB_45A3                    ; $40DC  CD A3 45
        DEC SP                           ; $40DF  3B
        EX DE,HL                         ; $40E0  EB
        LD HL,(SUB_0C98_4)               ; $40E1  2A D4 0C
        JR SUB_4068_14                   ; $40E4  18 08
SUB_4068_13:
        LD A,(SUB_0B2A_24)               ; $40E6  3A 76 0B
        OR A                             ; $40E9  B7
        JR Z,SUB_4068_15                 ; $40EA  28 0C
        POP DE                           ; $40EC  D1
        EX DE,HL                         ; $40ED  EB
SUB_4068_14:
        PUSH HL                          ; $40EE  E5
        XOR A                            ; $40EF  AF
        LD (SUB_0B2A_24),A               ; $40F0  32 76 0B
        CP D                             ; $40F3  BA
        PUSH AF                          ; $40F4  F5
        PUSH DE                          ; $40F5  D5
        LD B,(HL)                        ; $40F6  46
        OR B                             ; $40F7  B0
SUB_4068_15:
        JP Z,SUB_14E4_2                  ; $40F8  CA EB 14
        INC HL                           ; $40FB  23
        LD C,(HL)                        ; $40FC  4E
        INC HL                           ; $40FD  23
        LD H,(HL)                        ; $40FE  66
        LD L,C                           ; $40FF  69
        JR SUB_4068_20                   ; $4100  18 1C
SUB_4068_16:
        LD E,B                           ; $4102  58
        PUSH HL                          ; $4103  E5
        LD C,$02                         ; $4104  0E 02
SUB_4068_17:
        LD A,(HL)                        ; $4106  7E
        INC HL                           ; $4107  23
        CP $5C                           ; $4108  FE 5C
        JP Z,SUB_4068_49+1               ; $410A  CA 50 42
        CP $20                           ; $410D  FE 20
        JR NZ,SUB_4068_18                ; $410F  20 03
        INC C                            ; $4111  0C
        DJNZ SUB_4068_17                 ; $4112  10 F2
SUB_4068_18:
        POP HL                           ; $4114  E1
        LD B,E                           ; $4115  43
        LD A,$5C                         ; $4116  3E 5C
SUB_4068_19:
        CALL SUB_4287                    ; $4118  CD 87 42
        CALL SUB_4291                    ; $411B  CD 91 42
SUB_4068_20:
        XOR A                            ; $411E  AF
        LD E,A                           ; $411F  5F
        LD D,A                           ; $4120  57
SUB_4068_21:
        CALL SUB_4287                    ; $4121  CD 87 42
        LD D,A                           ; $4124  57
        LD A,(HL)                        ; $4125  7E
        INC HL                           ; $4126  23
        CP $21                           ; $4127  FE 21
        JP Z,SUB_4068_48                 ; $4129  CA 4D 42
        CP $23                           ; $412C  FE 23
        JR Z,SUB_4068_29                 ; $412E  28 41
        CP $26                           ; $4130  FE 26
        JP Z,SUB_4068_47                 ; $4132  CA 49 42
        DEC B                            ; $4135  05
        JP Z,SUB_4068_42                 ; $4136  CA 28 42
        CP $2B                           ; $4139  FE 2B
        LD A,$08                         ; $413B  3E 08
        JR Z,SUB_4068_21                 ; $413D  28 E2
        DEC HL                           ; $413F  2B
        LD A,(HL)                        ; $4140  7E
        INC HL                           ; $4141  23
        CP $2E                           ; $4142  FE 2E
        JR Z,SUB_4068_30                 ; $4144  28 45
        CP $5F                           ; $4146  FE 5F
        JP Z,SUB_4068_45                 ; $4148  CA 3E 42
        CP $5C                           ; $414B  FE 5C
SUB_4068_22:
        JR Z,SUB_4068_16                 ; $414D  28 B3
SUB_4068_23:
        CP (HL)                          ; $414F  BE
        JR NZ,SUB_4068_19                ; $4150  20 C6
SUB_4068_24:
        CP $24                           ; $4152  FE 24
SUB_4068_25:
        JR Z,SUB_4068_27+1               ; $4154  28 14
        CP $2A                           ; $4156  FE 2A
        JR NZ,SUB_4068_19                ; $4158  20 BE
        LD A,B                           ; $415A  78
        INC HL                           ; $415B  23
        CP $02                           ; $415C  FE 02
        JR C,SUB_4068_26                 ; $415E  38 03
        LD A,(HL)                        ; $4160  7E
        CP $24                           ; $4161  FE 24
SUB_4068_26:
        LD A,$20                         ; $4163  3E 20
        JR NZ,SUB_4068_28                ; $4165  20 07
        DEC B                            ; $4167  05
        INC E                            ; $4168  1C
SUB_4068_27:
        CP $AF                           ; $4169  FE AF
        ADD A,$10                        ; $416B  C6 10
        INC HL                           ; $416D  23
SUB_4068_28:
        INC E                            ; $416E  1C
        ADD A,D                          ; $416F  82
        LD D,A                           ; $4170  57
SUB_4068_29:
        INC E                            ; $4171  1C
        LD C,$00                         ; $4172  0E 00
        DEC B                            ; $4174  05
        JR Z,SUB_4068_35                 ; $4175  28 48
        LD A,(HL)                        ; $4177  7E
        INC HL                           ; $4178  23
        CP $2E                           ; $4179  FE 2E
        JR Z,SUB_4068_31                 ; $417B  28 19
        CP $23                           ; $417D  FE 23
        JR Z,SUB_4068_29                 ; $417F  28 F0
        CP $2C                           ; $4181  FE 2C
        JR NZ,SUB_4068_32                ; $4183  20 1B
        LD A,D                           ; $4185  7A
        OR $40                           ; $4186  F6 40
        LD D,A                           ; $4188  57
        JR SUB_4068_29                   ; $4189  18 E6
SUB_4068_30:
        LD A,(HL)                        ; $418B  7E
        CP $23                           ; $418C  FE 23
        LD A,$2E                         ; $418E  3E 2E
        JP NZ,SUB_4068_19                ; $4190  C2 18 41
        LD C,$01                         ; $4193  0E 01
        INC HL                           ; $4195  23
SUB_4068_31:
        INC C                            ; $4196  0C
        DEC B                            ; $4197  05
        JR Z,SUB_4068_35                 ; $4198  28 25
        LD A,(HL)                        ; $419A  7E
        INC HL                           ; $419B  23
        CP $23                           ; $419C  FE 23
        JR Z,SUB_4068_31                 ; $419E  28 F6
SUB_4068_32:
        PUSH DE                          ; $41A0  D5
SUB_4068_33:
        LD DE,SUB_4068_34+1              ; $41A1  11 BD 41
        PUSH DE                          ; $41A4  D5
        LD D,H                           ; $41A5  54
        LD E,L                           ; $41A6  5D
        CP $5E                           ; $41A7  FE 5E
        RET NZ                           ; $41A9  C0
        CP (HL)                          ; $41AA  BE
        RET NZ                           ; $41AB  C0
        INC HL                           ; $41AC  23
        CP (HL)                          ; $41AD  BE
        RET NZ                           ; $41AE  C0
        INC HL                           ; $41AF  23
        CP (HL)                          ; $41B0  BE
        RET NZ                           ; $41B1  C0
        INC HL                           ; $41B2  23
        LD A,B                           ; $41B3  78
        SUB $04                          ; $41B4  D6 04
        RET C                            ; $41B6  D8
        POP DE                           ; $41B7  D1
        POP DE                           ; $41B8  D1
        LD B,A                           ; $41B9  47
        INC D                            ; $41BA  14
        INC HL                           ; $41BB  23
SUB_4068_34:
        JP Z,$D1EB                       ; $41BC  CA EB D1
SUB_4068_35:
        LD A,D                           ; $41BF  7A
        DEC HL                           ; $41C0  2B
        INC E                            ; $41C1  1C
        AND $08                          ; $41C2  E6 08
        JR NZ,SUB_4068_37                ; $41C4  20 15
        DEC E                            ; $41C6  1D
        LD A,B                           ; $41C7  78
        OR A                             ; $41C8  B7
        JR Z,SUB_4068_37                 ; $41C9  28 10
        LD A,(HL)                        ; $41CB  7E
        SUB $2D                          ; $41CC  D6 2D
        JR Z,SUB_4068_36                 ; $41CE  28 06
        CP $FE                           ; $41D0  FE FE
        JR NZ,SUB_4068_37                ; $41D2  20 07
        LD A,$08                         ; $41D4  3E 08
SUB_4068_36:
        ADD A,$04                        ; $41D6  C6 04
        ADD A,D                          ; $41D8  82
        LD D,A                           ; $41D9  57
        DEC B                            ; $41DA  05
SUB_4068_37:
        POP HL                           ; $41DB  E1
        POP AF                           ; $41DC  F1
        JR Z,SUB_4068_44                 ; $41DD  28 54
        PUSH BC                          ; $41DF  C5
        PUSH DE                          ; $41E0  D5
        CALL SUB_1A8C_1+1                ; $41E1  CD 90 1A
        POP DE                           ; $41E4  D1
        POP BC                           ; $41E5  C1
        PUSH BC                          ; $41E6  C5
        PUSH HL                          ; $41E7  E5
        LD B,E                           ; $41E8  43
        LD A,B                           ; $41E9  78
        ADD A,C                          ; $41EA  81
        CP $19                           ; $41EB  FE 19
        JP NC,SUB_14E4_2                 ; $41ED  D2 EB 14
        LD A,D                           ; $41F0  7A
        OR $80                           ; $41F1  F6 80
        CALL SUB_33A1                    ; $41F3  CD A1 33
        CALL SUB_48BE                    ; $41F6  CD BE 48
SUB_4068_38:
        POP HL                           ; $41F9  E1
        DEC HL                           ; $41FA  2B
        CALL SUB_13E4                    ; $41FB  CD E4 13
        SCF                              ; $41FE  37
        JR Z,SUB_4068_40                 ; $41FF  28 0F
        LD (SUB_0B2A_24),A               ; $4201  32 76 0B
        CP $3B                           ; $4204  FE 3B
        JR Z,SUB_4068_39                 ; $4206  28 05
        CP $2C                           ; $4208  FE 2C
        JP NZ,SUB_0D20_20                ; $420A  C2 92 0D
SUB_4068_39:
        CALL SUB_13E4                    ; $420D  CD E4 13
SUB_4068_40:
        POP BC                           ; $4210  C1
        EX DE,HL                         ; $4211  EB
        POP HL                           ; $4212  E1
        PUSH HL                          ; $4213  E5
        PUSH AF                          ; $4214  F5
        PUSH DE                          ; $4215  D5
        LD A,(HL)                        ; $4216  7E
        SUB B                            ; $4217  90
        INC HL                           ; $4218  23
        LD C,(HL)                        ; $4219  4E
        INC HL                           ; $421A  23
        LD H,(HL)                        ; $421B  66
        LD L,C                           ; $421C  69
        LD D,$00                         ; $421D  16 00
        LD E,A                           ; $421F  5F
        ADD HL,DE                        ; $4220  19
SUB_4068_41:
        LD A,B                           ; $4221  78
        OR A                             ; $4222  B7
        JP NZ,SUB_4068_20                ; $4223  C2 1E 41
        JR SUB_4068_43                   ; $4226  18 06
SUB_4068_42:
        CALL SUB_4287                    ; $4228  CD 87 42
        CALL SUB_4291                    ; $422B  CD 91 42
SUB_4068_43:
        POP HL                           ; $422E  E1
        POP AF                           ; $422F  F1
        JP NZ,SUB_4068_13                ; $4230  C2 E6 40
SUB_4068_44:
        CALL C,SUB_4406                  ; $4233  DC 06 44
        EX (SP),HL                       ; $4236  E3
        CALL SUB_4A3D                    ; $4237  CD 3D 4A
        POP HL                           ; $423A  E1
        JP SUB_189A                      ; $423B  C3 9A 18
SUB_4068_45:
        CALL SUB_4287                    ; $423E  CD 87 42
        DEC B                            ; $4241  05
        LD A,(HL)                        ; $4242  7E
        INC HL                           ; $4243  23
SUB_4068_46:
        CALL SUB_4291                    ; $4244  CD 91 42
        JR SUB_4068_41                   ; $4247  18 D8
SUB_4068_47:
        LD C,$FF                         ; $4249  0E FF
        JR SUB_4068_50                   ; $424B  18 04
SUB_4068_48:
        LD C,$01                         ; $424D  0E 01
SUB_4068_49:
        LD A,$F1                         ; $424F  3E F1
SUB_4068_50:
        DEC B                            ; $4251  05
        CALL SUB_4287                    ; $4252  CD 87 42
        POP HL                           ; $4255  E1
        POP AF                           ; $4256  F1
        JR Z,SUB_4068_44                 ; $4257  28 DA
        PUSH BC                          ; $4259  C5
        CALL SUB_1A8C_1+1                ; $425A  CD 90 1A
        CALL SUB_2CB3                    ; $425D  CD B3 2C
        POP BC                           ; $4260  C1
        PUSH BC                          ; $4261  C5
        PUSH HL                          ; $4262  E5
        LD HL,(SUB_0C98_4)               ; $4263  2A D4 0C
        LD B,C                           ; $4266  41
        LD C,$00                         ; $4267  0E 00
        PUSH BC                          ; $4269  C5
        CALL SUB_4ABF_4+1                ; $426A  CD DA 4A
        CALL SUB_48C1                    ; $426D  CD C1 48
        LD HL,(SUB_0C98_4)               ; $4270  2A D4 0C
        POP AF                           ; $4273  F1
        INC A                            ; $4274  3C
        JP Z,SUB_4068_38                 ; $4275  CA F9 41
        DEC A                            ; $4278  3D
        SUB (HL)                         ; $4279  96
        LD B,A                           ; $427A  47
        LD A,$20                         ; $427B  3E 20
        INC B                            ; $427D  04
SUB_4068_51:
        DEC B                            ; $427E  05
        JP Z,SUB_4068_38                 ; $427F  CA F9 41
        CALL SUB_4291                    ; $4282  CD 91 42
        JR SUB_4068_51                   ; $4285  18 F7
SUB_4287:
        PUSH AF                          ; $4287  F5
        LD A,D                           ; $4288  7A
        OR A                             ; $4289  B7
        LD A,$2B                         ; $428A  3E 2B
        CALL NZ,SUB_4291                 ; $428C  C4 91 42
        POP AF                           ; $428F  F1
        RET                              ; $4290  C9
SUB_4291:
        PUSH AF                          ; $4291  F5
        PUSH HL                          ; $4292  E5
        LD HL,(SUB_0752_40)              ; $4293  2A 63 08
        LD A,H                           ; $4296  7C
        OR L                             ; $4297  B5
        JP NZ,SUB_573C_6                 ; $4298  C2 9E 57
        POP HL                           ; $429B  E1
        LD A,(SUB_0752_34+1)             ; $429C  3A 5B 08
        OR A                             ; $429F  B7
        JP Z,SUB_4300_2                  ; $42A0  CA 0F 43
        POP AF                           ; $42A3  F1
        PUSH AF                          ; $42A4  F5
        CP $08                           ; $42A5  FE 08
        JR NZ,SUB_4291_1                 ; $42A7  20 0A
        LD A,(SUB_0752_34)               ; $42A9  3A 5A 08
        DEC A                            ; $42AC  3D
        LD (SUB_0752_34),A               ; $42AD  32 5A 08
        POP AF                           ; $42B0  F1
        JR SUB_42EA                      ; $42B1  18 37
SUB_4291_1:
        CP $09                           ; $42B3  FE 09
        JR NZ,SUB_4291_3                 ; $42B5  20 0E
SUB_4291_2:
        LD A,$20                         ; $42B7  3E 20
        CALL SUB_4291                    ; $42B9  CD 91 42
        LD A,(SUB_0752_34)               ; $42BC  3A 5A 08
        AND $07                          ; $42BF  E6 07
        JR NZ,SUB_4291_2                 ; $42C1  20 F4
        POP AF                           ; $42C3  F1
        RET                              ; $42C4  C9
SUB_4291_3:
        POP AF                           ; $42C5  F1
        PUSH AF                          ; $42C6  F5
        SUB $0D                          ; $42C7  D6 0D
        JR Z,SUB_4291_6                  ; $42C9  28 1B
        JR C,SUB_4291_7                  ; $42CB  38 1C
SUB_4291_4:
        LD A,(SUB_0752_35)               ; $42CD  3A 5D 08
        INC A                            ; $42D0  3C
        LD A,(SUB_0752_34)               ; $42D1  3A 5A 08
        JR Z,SUB_4291_5                  ; $42D4  28 0B
        PUSH HL                          ; $42D6  E5
        LD HL,SUB_0752_35                ; $42D7  21 5D 08
        CP (HL)                          ; $42DA  BE
        POP HL                           ; $42DB  E1
        CALL Z,SUB_4300                  ; $42DC  CC 00 43
        JR Z,SUB_4291_7                  ; $42DF  28 08
SUB_4291_5:
        CP $FF                           ; $42E1  FE FF
        JR Z,SUB_4291_7                  ; $42E3  28 04
        INC A                            ; $42E5  3C
SUB_4291_6:
        LD (SUB_0752_34),A               ; $42E6  32 5A 08
SUB_4291_7:
        POP AF                           ; $42E9  F1
SUB_42EA:
        PUSH AF                          ; $42EA  F5
        PUSH BC                          ; $42EB  C5
        PUSH DE                          ; $42EC  D5
        PUSH HL                          ; $42ED  E5
        LD C,A                           ; $42EE  4F
SUB_42EA_1:
        CALL $0000                       ; $42EF  CD 00 00
        POP HL                           ; $42F2  E1
        POP DE                           ; $42F3  D1
        POP BC                           ; $42F4  C1
        POP AF                           ; $42F5  F1
        RET                              ; $42F6  C9
SUB_42F7:
        XOR A                            ; $42F7  AF
        LD (SUB_0752_34+1),A             ; $42F8  32 5B 08
        LD A,(SUB_0752_34)               ; $42FB  3A 5A 08
        OR A                             ; $42FE  B7
        RET Z                            ; $42FF  C8
SUB_4300:
        LD A,$0D                         ; $4300  3E 0D
        CALL SUB_42EA                    ; $4302  CD EA 42
        LD A,$0A                         ; $4305  3E 0A
        CALL SUB_42EA                    ; $4307  CD EA 42
SUB_4300_1:
        XOR A                            ; $430A  AF
        LD (SUB_0752_34),A               ; $430B  32 5A 08
        RET                              ; $430E  C9
SUB_4300_2:
        LD A,(SUB_0752_39)               ; $430F  3A 62 08
        OR A                             ; $4312  B7
        JP NZ,SUB_48D6_2                 ; $4313  C2 F1 48
        POP AF                           ; $4316  F1
        PUSH BC                          ; $4317  C5
        PUSH AF                          ; $4318  F5
        CP $0A                           ; $4319  FE 0A
        JR NZ,SUB_4300_4                 ; $431B  20 05
SUB_4300_3:
        CALL SUB_4392                    ; $431D  CD 92 43
        LD A,$0A                         ; $4320  3E 0A
SUB_4300_4:
        CP $08                           ; $4322  FE 08
        JR NZ,SUB_4300_6                 ; $4324  20 1B
        LD A,(SUB_0B2A_2)                ; $4326  3A 34 0B
        OR A                             ; $4329  B7
        JR NZ,SUB_4300_5                 ; $432A  20 0D
        LD A,(SUB_0B2A_3)                ; $432C  3A 35 0B
        OR A                             ; $432F  B7
        JR Z,SUB_4300_8                  ; $4330  28 1F
        DEC A                            ; $4332  3D
        LD (SUB_0B2A_3),A                ; $4333  32 35 0B
        LD A,(SUB_0752_36)               ; $4336  3A 5E 08
SUB_4300_5:
        DEC A                            ; $4339  3D
        LD (SUB_0B2A_2),A                ; $433A  32 34 0B
        LD A,$08                         ; $433D  3E 08
        JR SUB_4300_10                   ; $433F  18 17
SUB_4300_6:
        CP $09                           ; $4341  FE 09
        JR NZ,SUB_4300_9                 ; $4343  20 0F
SUB_4300_7:
        LD A,$20                         ; $4345  3E 20
        CALL SUB_4291                    ; $4347  CD 91 42
        LD A,(SUB_0B2A_2)                ; $434A  3A 34 0B
        AND $07                          ; $434D  E6 07
        JR NZ,SUB_4300_7                 ; $434F  20 F4
SUB_4300_8:
        POP AF                           ; $4351  F1
        POP BC                           ; $4352  C1
        RET                              ; $4353  C9
SUB_4300_9:
        CP $20                           ; $4354  FE 20
        JR C,SUB_4300_10                 ; $4356  38 00
SUB_4300_10:
        POP AF                           ; $4358  F1
        PUSH AF                          ; $4359  F5
        CALL SUB_4382                    ; $435A  CD 82 43
        CP $20                           ; $435D  FE 20
        JR C,SUB_4300_11                 ; $435F  38 1E
        LD A,(SUB_0752_36)               ; $4361  3A 5E 08
        INC A                            ; $4364  3C
        JR Z,SUB_4300_11                 ; $4365  28 18
        DEC A                            ; $4367  3D
        LD B,A                           ; $4368  47
        LD A,(SUB_0B2A_2)                ; $4369  3A 34 0B
        INC A                            ; $436C  3C
        JR Z,SUB_4300_11                 ; $436D  28 10
        LD (SUB_0B2A_2),A                ; $436F  32 34 0B
        CP B                             ; $4372  B8
        JR NZ,SUB_4300_11                ; $4373  20 0A
        LD A,(SUB_2803_4)                ; $4375  3A 15 28
        CP B                             ; $4378  B8
        CALL Z,SUB_438F                  ; $4379  CC 8F 43
        CALL NZ,SUB_4406                 ; $437C  C4 06 44
SUB_4300_11:
        POP AF                           ; $437F  F1
        POP BC                           ; $4380  C1
        RET                              ; $4381  C9
SUB_4382:
        PUSH AF                          ; $4382  F5
        PUSH BC                          ; $4383  C5
        PUSH DE                          ; $4384  D5
        PUSH HL                          ; $4385  E5
        LD C,A                           ; $4386  4F
SUB_4382_1:
        CALL $0000                       ; $4387  CD 00 00
        POP HL                           ; $438A  E1
        POP DE                           ; $438B  D1
        POP BC                           ; $438C  C1
        POP AF                           ; $438D  F1
        RET                              ; $438E  C9
SUB_438F:
        CALL SUB_4410                    ; $438F  CD 10 44
SUB_4392:
        LD A,(SUB_0752_37)               ; $4392  3A 5F 08
        LD B,A                           ; $4395  47
        LD A,(SUB_0B2A_3)                ; $4396  3A 35 0B
        INC A                            ; $4399  3C
        CP B                             ; $439A  B8
        JR NC,SUB_4392_1                 ; $439B  30 03
        LD (SUB_0B2A_3),A                ; $439D  32 35 0B
SUB_4392_1:
        XOR A                            ; $43A0  AF
        RET                              ; $43A1  C9
SUB_43A2:
        PUSH HL                          ; $43A2  E5
        LD HL,(SUB_0752_40)              ; $43A3  2A 63 08
        LD A,H                           ; $43A6  7C
        OR L                             ; $43A7  B5
        JR Z,SUB_43A2_2                  ; $43A8  28 2F
        CALL SUB_5889                    ; $43AA  CD 89 58
        JP NC,SUB_2990_7                 ; $43AD  D2 E1 29
        PUSH BC                          ; $43B0  C5
        PUSH DE                          ; $43B1  D5
        PUSH HL                          ; $43B2  E5
        CALL SUB_5498                    ; $43B3  CD 98 54
        POP HL                           ; $43B6  E1
        POP DE                           ; $43B7  D1
        POP BC                           ; $43B8  C1
        LD A,(L_0CC3)                    ; $43B9  3A C3 0C
        OR A                             ; $43BC  B7
        JP NZ,SUB_5143_4                 ; $43BD  C2 BD 51
        LD A,(SUB_0752_46)               ; $43C0  3A 6D 08
        OR A                             ; $43C3  B7
        LD HL,SUB_129A_14                ; $43C4  21 86 13
        EX (SP),HL                       ; $43C7  E3
        JP NZ,SUB_450B                   ; $43C8  C2 0B 45
        EX (SP),HL                       ; $43CB  E3
        PUSH BC                          ; $43CC  C5
        PUSH DE                          ; $43CD  D5
        LD HL,SUB_0D04_5                 ; $43CE  21 15 0D
SUB_43A2_1:
        CALL SUB_48BE                    ; $43D1  CD BE 48
        POP DE                           ; $43D4  D1
        POP BC                           ; $43D5  C1
        XOR A                            ; $43D6  AF
        POP HL                           ; $43D7  E1
        RET                              ; $43D8  C9
SUB_43A2_2:
        POP HL                           ; $43D9  E1
SUB_43DA:
        PUSH BC                          ; $43DA  C5
        PUSH DE                          ; $43DB  D5
        PUSH HL                          ; $43DC  E5
SUB_43DA_1:
        CALL $0000                       ; $43DD  CD 00 00
        POP HL                           ; $43E0  E1
        POP DE                           ; $43E1  D1
        POP BC                           ; $43E2  C1
        AND $7F                          ; $43E3  E6 7F
        CP $0F                           ; $43E5  FE 0F
        RET NZ                           ; $43E7  C0
        LD A,(SUB_0752_39)               ; $43E8  3A 62 08
        OR A                             ; $43EB  B7
        CALL Z,SUB_460E                  ; $43EC  CC 0E 46
        CPL                              ; $43EF  2F
        LD (SUB_0752_39),A               ; $43F0  32 62 08
        OR A                             ; $43F3  B7
        JP Z,SUB_460E                    ; $43F4  CA 0E 46
        XOR A                            ; $43F7  AF
SUB_43DA_2:
        RET                              ; $43F8  C9
SUB_43F9:
        LD A,(SUB_0B2A_2)                ; $43F9  3A 34 0B
        OR A                             ; $43FC  B7
        RET Z                            ; $43FD  C8
        JP SUB_4406                      ; $43FE  C3 06 44
SUB_43F9_1:
        LD (HL),$00                      ; $4401  36 00
        LD HL,SUB_0925_11                ; $4403  21 30 0A
SUB_4406:
        LD A,$0D                         ; $4406  3E 0D
        CALL SUB_4291                    ; $4408  CD 91 42
        LD A,$0A                         ; $440B  3E 0A
        CALL SUB_4291                    ; $440D  CD 91 42
SUB_4410:
        PUSH HL                          ; $4410  E5
        LD HL,(SUB_0752_40)              ; $4411  2A 63 08
        LD A,H                           ; $4414  7C
        OR L                             ; $4415  B5
        POP HL                           ; $4416  E1
        JR Z,SUB_4410_1                  ; $4417  28 02
        XOR A                            ; $4419  AF
        RET                              ; $441A  C9
SUB_4410_1:
        LD A,(SUB_0752_34+1)             ; $441B  3A 5B 08
SUB_4410_2:
        OR A                             ; $441E  B7
        JR Z,SUB_4410_3                  ; $441F  28 05
        XOR A                            ; $4421  AF
        LD (SUB_0752_34),A               ; $4422  32 5A 08
        RET                              ; $4425  C9
SUB_4410_3:
        XOR A                            ; $4426  AF
        LD (SUB_0B2A_2),A                ; $4427  32 34 0B
        XOR A                            ; $442A  AF
        RET                              ; $442B  C9
SUB_442C:
        PUSH BC                          ; $442C  C5
        PUSH DE                          ; $442D  D5
        PUSH HL                          ; $442E  E5
SUB_442C_1:
        CALL $0000                       ; $442F  CD 00 00
        POP HL                           ; $4432  E1
        POP DE                           ; $4433  D1
        POP BC                           ; $4434  C1
        OR A                             ; $4435  B7
        RET Z                            ; $4436  C8
SUB_4437:
        CALL SUB_43DA                    ; $4437  CD DA 43
        CP $13                           ; $443A  FE 13
        CALL Z,SUB_43DA                  ; $443C  CC DA 43
        LD (SUB_0752_33+1),A             ; $443F  32 57 08
        CP $03                           ; $4442  FE 03
        CALL Z,SUB_4610                  ; $4444  CC 10 46
SUB_4437_1:
        JP SUB_45B5_5                    ; $4447  C3 CF 45
SUB_4437_2:
        CALL SUB_13E4                    ; $444A  CD E4 13
        PUSH HL                          ; $444D  E5
        CALL SUB_4472                    ; $444E  CD 72 44
        JR NZ,SUB_4437_4                 ; $4451  20 09
SUB_4437_3:
        CALL $0000                       ; $4453  CD 00 00
        OR A                             ; $4456  B7
        JR Z,SUB_4437_5                  ; $4457  28 0C
        CALL SUB_43DA                    ; $4459  CD DA 43
SUB_4437_4:
        PUSH AF                          ; $445C  F5
        CALL SUB_4858                    ; $445D  CD 58 48
        POP AF                           ; $4460  F1
        LD E,A                           ; $4461  5F
        CALL SUB_4A89                    ; $4462  CD 89 4A
SUB_4437_5:
        LD HL,SUB_0D04_4+1               ; $4465  21 14 0D
        LD (SUB_0C98_4),HL               ; $4468  22 D4 0C
        LD A,$03                         ; $446B  3E 03
        LD (SUB_0B2A_5),A                ; $446D  32 37 0B
        POP HL                           ; $4470  E1
        RET                              ; $4471  C9
SUB_4472:
        LD A,(SUB_0752_33+1)             ; $4472  3A 57 08
        OR A                             ; $4475  B7
        RET Z                            ; $4476  C8
        PUSH AF                          ; $4477  F5
        XOR A                            ; $4478  AF
        LD (SUB_0752_33+1),A             ; $4479  32 57 08
        POP AF                           ; $447C  F1
        RET                              ; $447D  C9
SUB_447E:
        CALL SUB_4291                    ; $447E  CD 91 42
        CP $0A                           ; $4481  FE 0A
        RET NZ                           ; $4483  C0
        LD A,$0D                         ; $4484  3E 0D
        CALL SUB_4291                    ; $4486  CD 91 42
        CALL SUB_4410                    ; $4489  CD 10 44
        LD A,$0A                         ; $448C  3E 0A
        RET                              ; $448E  C9
SUB_448F:
        CALL SUB_44C2                    ; $448F  CD C2 44
SUB_4492:
        PUSH BC                          ; $4492  C5
        EX (SP),HL                       ; $4493  E3
        POP BC                           ; $4494  C1
SUB_4492_1:
        CALL SUB_459D                    ; $4495  CD 9D 45
        LD A,(HL)                        ; $4498  7E
        LD (BC),A                        ; $4499  02
        RET Z                            ; $449A  C8
        DEC BC                           ; $449B  0B
        DEC HL                           ; $449C  2B
        JR SUB_4492_1                    ; $449D  18 F6
SUB_449F:
        PUSH HL                          ; $449F  E5
        LD HL,(SUB_0B2A_13)              ; $44A0  2A 46 0B
        LD B,$00                         ; $44A3  06 00
        ADD HL,BC                        ; $44A5  09
        ADD HL,BC                        ; $44A6  09
        LD A,$C6                         ; $44A7  3E C6
        SUB L                            ; $44A9  95
        LD L,A                           ; $44AA  6F
        LD A,$FF                         ; $44AB  3E FF
        SBC A,H                          ; $44AD  9C
        JR C,SUB_449F_1                  ; $44AE  38 04
        LD H,A                           ; $44B0  67
        ADD HL,SP                        ; $44B1  39
        POP HL                           ; $44B2  E1
        RET C                            ; $44B3  D8
SUB_449F_1:
        LD HL,(SUB_0752_42)              ; $44B4  2A 65 08
        DEC HL                           ; $44B7  2B
        DEC HL                           ; $44B8  2B
        LD (SUB_0B2A_31),HL              ; $44B9  22 81 0B
SUB_449F_2:
        LD DE,$0007                      ; $44BC  11 07 00
        JP SUB_0D20_28                   ; $44BF  C3 AC 0D
SUB_44C2:
        CALL SUB_44D5                    ; $44C2  CD D5 44
SUB_44C2_1:
        RET NC                           ; $44C5  D0
        PUSH BC                          ; $44C6  C5
        PUSH DE                          ; $44C7  D5
        PUSH HL                          ; $44C8  E5
        CALL SUB_4900                    ; $44C9  CD 00 49
        POP HL                           ; $44CC  E1
        POP DE                           ; $44CD  D1
        POP BC                           ; $44CE  C1
        CALL SUB_44D5                    ; $44CF  CD D5 44
        RET NC                           ; $44D2  D0
        JR SUB_449F_2                    ; $44D3  18 E7
SUB_44D5:
        PUSH DE                          ; $44D5  D5
        EX DE,HL                         ; $44D6  EB
        LD HL,(SUB_0B2A_19)              ; $44D7  2A 6B 0B
        CALL SUB_459D                    ; $44DA  CD 9D 45
        EX DE,HL                         ; $44DD  EB
        POP DE                           ; $44DE  D1
        RET                              ; $44DF  C9
SUB_44E0:
        LD A,(SUB_0752_55)               ; $44E0  3A 93 08
        LD B,A                           ; $44E3  47
        LD HL,SUB_0752_51                ; $44E4  21 73 08
        XOR A                            ; $44E7  AF
        INC B                            ; $44E8  04
SUB_44E0_1:
        LD E,(HL)                        ; $44E9  5E
        INC HL                           ; $44EA  23
        LD D,(HL)                        ; $44EB  56
        INC HL                           ; $44EC  23
        LD (DE),A                        ; $44ED  12
        DJNZ SUB_44E0_1                  ; $44EE  10 F9
        CALL SUB_554F                    ; $44F0  CD 4F 55
        XOR A                            ; $44F3  AF
        RET NZ                           ; $44F4  C0
SUB_44F5:
        LD HL,(SUB_0752_44)              ; $44F5  2A 69 08
        CALL SUB_463E                    ; $44F8  CD 3E 46
        LD (L_0CBC),A                    ; $44FB  32 BC 0C
        LD (SUB_0B2A_27),A               ; $44FE  32 7A 0B
SUB_44F5_1:
        LD (SUB_0B2A_26),A               ; $4501  32 79 0B
        LD (HL),A                        ; $4504  77
        INC HL                           ; $4505  23
        LD (HL),A                        ; $4506  77
        INC HL                           ; $4507  23
SUB_4508:
        LD (SUB_0B2A_40),HL              ; $4508  22 92 0B
SUB_450B:
        LD HL,(SUB_0752_44)              ; $450B  2A 69 08
        DEC HL                           ; $450E  2B
SUB_450F:
        LD (SUB_0B2A_25),HL              ; $450F  22 77 0B
        LD A,(L_0CBD)                    ; $4512  3A BD 0C
        OR A                             ; $4515  B7
        JR NZ,SUB_450F_2                 ; $4516  20 11
        XOR A                            ; $4518  AF
        LD (SUB_0C4B_13),A               ; $4519  32 97 0C
        LD (SUB_0C4B_12),A               ; $451C  32 96 0C
        LD B,$1A                         ; $451F  06 1A
        LD HL,SUB_0B2A_44                ; $4521  21 9A 0B
SUB_450F_1:
        LD (HL),$04                      ; $4524  36 04
        INC HL                           ; $4526  23
        DJNZ SUB_450F_1                  ; $4527  10 FB
SUB_450F_2:
        LD DE,SUB_39E3_2                 ; $4529  11 03 3A
        LD HL,L_3AA2                     ; $452C  21 A2 3A
        CALL SUB_2B42                    ; $452F  CD 42 2B
SUB_450F_3:
        LD HL,SUB_3A18_9                 ; $4532  21 7F 3A
        XOR A                            ; $4535  AF
        LD (HL),A                        ; $4536  77
        INC HL                           ; $4537  23
        LD (HL),A                        ; $4538  77
        INC HL                           ; $4539  23
SUB_453A:
        LD (HL),A                        ; $453A  77
        XOR A                            ; $453B  AF
        LD (SUB_0B2A_36),A               ; $453C  32 8B 0B
        LD L,A                           ; $453F  6F
        LD H,A                           ; $4540  67
        LD (SUB_0B2A_35),HL              ; $4541  22 89 0B
        LD (SUB_0B2A_39),HL              ; $4544  22 90 0B
        LD HL,(SUB_0B2A_13)              ; $4547  2A 46 0B
        LD A,(L_0CC3)                    ; $454A  3A C3 0C
        OR A                             ; $454D  B7
        JR NZ,SUB_453A_2                 ; $454E  20 03
SUB_453A_1:
        LD (SUB_0B2A_19),HL              ; $4550  22 6B 0B
SUB_453A_2:
        XOR A                            ; $4553  AF
SUB_453A_3:
        CALL SUB_45B5                    ; $4554  CD B5 45
        LD HL,(SUB_0B2A_40)              ; $4557  2A 92 0B
        LD (SUB_0B2A_41),HL              ; $455A  22 94 0B
        LD (SUB_0B2A_42),HL              ; $455D  22 96 0B
        LD A,(L_0CBD)                    ; $4560  3A BD 0C
        OR A                             ; $4563  B7
        CALL Z,SUB_554F                  ; $4564  CC 4F 55
        POP BC                           ; $4567  C1
        LD HL,(SUB_0752_42)              ; $4568  2A 65 08
        DEC HL                           ; $456B  2B
        DEC HL                           ; $456C  2B
        LD (SUB_0B2A_31),HL              ; $456D  22 81 0B
        INC HL                           ; $4570  23
        INC HL                           ; $4571  23
SUB_453A_4:
        LD SP,HL                         ; $4572  F9
        LD HL,SUB_0B2A_15                ; $4573  21 4A 0B
        LD (SUB_0B2A_14),HL              ; $4576  22 48 0B
        CALL SUB_2554                    ; $4579  CD 54 25
        CALL SUB_42F7                    ; $457C  CD F7 42
        CALL SUB_189A                    ; $457F  CD 9A 18
        XOR A                            ; $4582  AF
        LD H,A                           ; $4583  67
        LD L,A                           ; $4584  6F
        LD (SUB_0B2A_46),HL              ; $4585  22 B6 0B
        LD (SUB_0C4B_4),A                ; $4588  32 87 0C
        LD (SUB_0C03_2),HL               ; $458B  22 1E 0C
SUB_453A_5:
        LD (SUB_0C4B_6),HL               ; $458E  22 8A 0C
        LD (SUB_0B2A_45),HL              ; $4591  22 B4 0B
        LD (SUB_0B2A_23),A               ; $4594  32 75 0B
        PUSH HL                          ; $4597  E5
        PUSH BC                          ; $4598  C5
SUB_453A_6:
        LD HL,(SUB_0B2A_25)              ; $4599  2A 77 0B
        RET                              ; $459C  C9
SUB_459D:
        LD A,H                           ; $459D  7C
        SUB D                            ; $459E  92
        RET NZ                           ; $459F  C0
        LD A,L                           ; $45A0  7D
        SUB E                            ; $45A1  93
        RET                              ; $45A2  C9
SUB_45A3:
        LD A,(HL)                        ; $45A3  7E
        EX (SP),HL                       ; $45A4  E3
        CP (HL)                          ; $45A5  BE
        JR NZ,SUB_45A8_5                 ; $45A6  20 0A
SUB_45A8:
        INC HL                           ; $45A8  23
SUB_45A8_1:
        EX (SP),HL                       ; $45A9  E3
SUB_45A8_2:
        INC HL                           ; $45AA  23
SUB_45A8_3:
        LD A,(HL)                        ; $45AB  7E
SUB_45A8_4:
        CP $3A                           ; $45AC  FE 3A
        RET NC                           ; $45AE  D0
        JP SUB_13E5_1                    ; $45AF  C3 E9 13
SUB_45A8_5:
        JP SUB_0D20_20                   ; $45B2  C3 92 0D
SUB_45B5:
        EX DE,HL                         ; $45B5  EB
        LD HL,(SUB_0752_44)              ; $45B6  2A 69 08
        JR Z,SUB_45B5_3                  ; $45B9  28 0E
        EX DE,HL                         ; $45BB  EB
        CALL SUB_14FB                    ; $45BC  CD FB 14
        PUSH HL                          ; $45BF  E5
SUB_45B5_1:
        CALL SUB_0FAB                    ; $45C0  CD AB 0F
        LD H,B                           ; $45C3  60
        LD L,C                           ; $45C4  69
        POP DE                           ; $45C5  D1
SUB_45B5_2:
        JP NC,SUB_1506_9                 ; $45C6  D2 91 15
SUB_45B5_3:
        DEC HL                           ; $45C9  2B
SUB_45B5_4:
        LD (SUB_0B2A_43),HL              ; $45CA  22 98 0B
        EX DE,HL                         ; $45CD  EB
        RET                              ; $45CE  C9
SUB_45B5_5:
        RET NZ                           ; $45CF  C0
        INC A                            ; $45D0  3C
        JP SUB_45B5_7                    ; $45D1  C3 DA 45
SUB_45B5_6:
        RET NZ                           ; $45D4  C0
        PUSH AF                          ; $45D5  F5
        CALL Z,SUB_554F                  ; $45D6  CC 4F 55
        POP AF                           ; $45D9  F1
SUB_45B5_7:
        LD (SUB_0B2A_30),HL              ; $45DA  22 7F 0B
        LD HL,SUB_0B2A_15                ; $45DD  21 4A 0B
        LD (SUB_0B2A_14),HL              ; $45E0  22 48 0B
SUB_45B5_8:
        LD HL,$FFF6                      ; $45E3  21 F6 FF
        POP BC                           ; $45E6  C1
SUB_45B5_9:
        LD HL,(SUB_0752_43)              ; $45E7  2A 67 08
        PUSH HL                          ; $45EA  E5
        PUSH AF                          ; $45EB  F5
        LD A,L                           ; $45EC  7D
SUB_45B5_10:
        AND H                            ; $45ED  A4
        INC A                            ; $45EE  3C
        JR Z,SUB_45B5_11                 ; $45EF  28 09
        LD (SUB_0B2A_38),HL              ; $45F1  22 8E 0B
        LD HL,(SUB_0B2A_30)              ; $45F4  2A 7F 0B
        LD (SUB_0B2A_39),HL              ; $45F7  22 90 0B
SUB_45B5_11:
        XOR A                            ; $45FA  AF
        LD (SUB_0752_39),A               ; $45FB  32 62 08
        CALL SUB_42F7                    ; $45FE  CD F7 42
        CALL SUB_43F9                    ; $4601  CD F9 43
        POP AF                           ; $4604  F1
        LD HL,SUB_0D04_6                 ; $4605  21 1A 0D
        JP NZ,SUB_0D20_34                ; $4608  C2 23 0E
        JP SUB_0D20_38+1                 ; $460B  C3 45 0E
SUB_460E:
        LD A,$0F                         ; $460E  3E 0F
SUB_4610:
        PUSH AF                          ; $4610  F5
        SUB $03                          ; $4611  D6 03
        JR NZ,SUB_4610_1                 ; $4613  20 06
        LD (SUB_0752_34+1),A             ; $4615  32 5B 08
        LD (SUB_0752_39),A               ; $4618  32 62 08
SUB_4610_1:
        LD A,$5E                         ; $461B  3E 5E
        CALL SUB_4291                    ; $461D  CD 91 42
        POP AF                           ; $4620  F1
        ADD A,$40                        ; $4621  C6 40
        CALL SUB_4291                    ; $4623  CD 91 42
        JP SUB_4406                      ; $4626  C3 06 44
SUB_4610_2:
        LD HL,(SUB_0B2A_39)              ; $4629  2A 90 0B
        LD A,H                           ; $462C  7C
        OR L                             ; $462D  B5
        LD DE,$0011                      ; $462E  11 11 00
        JP Z,SUB_0D20_28                 ; $4631  CA AC 0D
        EX DE,HL                         ; $4634  EB
        LD HL,(SUB_0B2A_38)              ; $4635  2A 8E 0B
        LD (SUB_0752_43),HL              ; $4638  22 67 08
        EX DE,HL                         ; $463B  EB
        RET                              ; $463C  C9
        DEFB    $3E                                              ; $463D
SUB_463E:
        XOR A                            ; $463E  AF
        LD (L_0CCE),A                    ; $463F  32 CE 0C
        RET                              ; $4642  C9
SUB_463E_1:
        CALL SUB_3BB3                    ; $4643  CD B3 3B
        PUSH DE                          ; $4646  D5
        PUSH HL                          ; $4647  E5
        LD HL,L_0CC6                     ; $4648  21 C6 0C
        CALL SUB_2B47                    ; $464B  CD 47 2B
SUB_463E_2:
        LD HL,(SUB_0B2A_41)              ; $464E  2A 94 0B
        EX (SP),HL                       ; $4651  E3
        CALL SUB_1DE3                    ; $4652  CD E3 1D
        PUSH AF                          ; $4655  F5
        CALL SUB_45A3                    ; $4656  CD A3 45
        INC L                            ; $4659  2C
        CALL SUB_3BB3                    ; $465A  CD B3 3B
        POP BC                           ; $465D  C1
        CALL SUB_1DE3                    ; $465E  CD E3 1D
        CP B                             ; $4661  B8
        JP NZ,SUB_0D20_27+1              ; $4662  C2 AA 0D
        EX (SP),HL                       ; $4665  E3
        EX DE,HL                         ; $4666  EB
        PUSH HL                          ; $4667  E5
        LD HL,(SUB_0B2A_41)              ; $4668  2A 94 0B
        CALL SUB_459D                    ; $466B  CD 9D 45
        JP NZ,SUB_14E4_2                 ; $466E  C2 EB 14
        POP DE                           ; $4671  D1
        POP HL                           ; $4672  E1
        EX (SP),HL                       ; $4673  E3
        PUSH DE                          ; $4674  D5
        CALL SUB_2B47                    ; $4675  CD 47 2B
        POP HL                           ; $4678  E1
        LD DE,L_0CC6                     ; $4679  11 C6 0C
        CALL SUB_2B47                    ; $467C  CD 47 2B
        POP HL                           ; $467F  E1
        RET                              ; $4680  C9
SUB_463E_3:
        LD A,$01                         ; $4681  3E 01
        LD (SUB_0B2A_23),A               ; $4683  32 75 0B
        CALL SUB_3BB3                    ; $4686  CD B3 3B
        JP NZ,SUB_14E4_2                 ; $4689  C2 EB 14
        PUSH HL                          ; $468C  E5
        LD (SUB_0B2A_23),A               ; $468D  32 75 0B
        LD H,B                           ; $4690  60
        LD L,C                           ; $4691  69
        DEC BC                           ; $4692  0B
        DEC BC                           ; $4693  0B
        DEC BC                           ; $4694  0B
SUB_463E_4:
        LD A,(BC)                        ; $4695  0A
        DEC BC                           ; $4696  0B
        OR A                             ; $4697  B7
        JP M,SUB_463E_4                  ; $4698  FA 95 46
        DEC BC                           ; $469B  0B
        DEC BC                           ; $469C  0B
        ADD HL,DE                        ; $469D  19
        EX DE,HL                         ; $469E  EB
        LD HL,(SUB_0B2A_42)              ; $469F  2A 96 0B
SUB_463E_5:
        CALL SUB_459D                    ; $46A2  CD 9D 45
        LD A,(DE)                        ; $46A5  1A
SUB_463E_6:
        LD (BC),A                        ; $46A6  02
        INC DE                           ; $46A7  13
        INC BC                           ; $46A8  03
        JR NZ,SUB_463E_5                 ; $46A9  20 F7
        DEC BC                           ; $46AB  0B
        LD H,B                           ; $46AC  60
        LD L,C                           ; $46AD  69
        LD (SUB_0B2A_42),HL              ; $46AE  22 96 0B
SUB_463E_7:
        POP HL                           ; $46B1  E1
        LD A,(HL)                        ; $46B2  7E
        CP $2C                           ; $46B3  FE 2C
        RET NZ                           ; $46B5  C0
        CALL SUB_13E4                    ; $46B6  CD E4 13
        JR SUB_463E_3                    ; $46B9  18 C6
SUB_463E_8:
        POP AF                           ; $46BB  F1
        POP HL                           ; $46BC  E1
        RET                              ; $46BD  C9
SUB_46BE:
        LD A,(HL)                        ; $46BE  7E
SUB_46BF:
        CP $41                           ; $46BF  FE 41
        RET C                            ; $46C1  D8
        CP $5B                           ; $46C2  FE 5B
        CCF                              ; $46C4  3F
        RET                              ; $46C5  C9
        DEFW    SUB_0FAB_4               ; $46C6
        DEFB    $45                                              ; $46C8
        DEFW    SUB_2CF8_1               ; $46C9
        DEFW    SUB_0925_10              ; $46CB
        DEFB    $CD                                              ; $46CD
        DEFW    SUB_14E4_1               ; $46CE
        DEFB    $2B,$CD                                          ; $46D0
        DEFW    SUB_13E4                 ; $46D2
        DEFW    SUB_0FAB_4               ; $46D4
        DEFB    $45,$CD                                          ; $46D6
        DEFW    SUB_45A3                 ; $46D8
        DEFB    $2C                                              ; $46DA
        DEFW    SUB_0FAB_4               ; $46DB
        DEFB    $45                                              ; $46DD
        DEFW    SUB_2AEB                 ; $46DE
        DEFW    SUB_0752_42              ; $46E0
        DEFB    $EB                                              ; $46E2
        DEFW    SUB_2CF8_1               ; $46E3
        DEFW    SUB_0D20_35              ; $46E5
        DEFB    $CD                                              ; $46E7
        DEFW    SUB_1A8C_1+1             ; $46E8
        DEFB    $E5,$CD                                          ; $46EA
        DEFW    SUB_22E1                 ; $46EC
        DEFB    $7C,$B5,$CA                                      ; $46EE
        DEFW    SUB_14E4_2               ; $46F1
        DEFB    $EB                                              ; $46F3
        DEFW    SUB_2BC4_3               ; $46F4
        DEFB    $CD                                              ; $46F6
        DEFW    SUB_13E4                 ; $46F7
        DEFW    SUB_28D5                 ; $46F9
        DEFB    $3C,$CD                                          ; $46FB
        DEFW    SUB_45A3                 ; $46FD
        DEFB    $2C,$28,$36,$CD                                  ; $46FF
        DEFW    SUB_14E4_1               ; $4703
        DEFB    $2B,$CD                                          ; $4705
        DEFW    SUB_13E4                 ; $4707
        DEFB    $C2                                              ; $4709
        DEFW    SUB_0D20_20              ; $470A
        DEFB    $E3,$E5,$21,$4E,$00                              ; $470C  "ce!N"
        DEFB    $CD                                              ; $4711
        DEFW    SUB_459D                 ; $4712
        DEFB    $D2                                              ; $4714
        DEFW    SUB_449F_1               ; $4715
        DEFB    $E1                                              ; $4717
        DEFW    SUB_49C3_2               ; $4718
        DEFB    $47,$DA                                          ; $471A
        DEFW    SUB_449F_1               ; $471C
        DEFB    $E5,$2A                                          ; $471E
        DEFW    SUB_0B2A_40              ; $4720
        DEFB    $01,$14                                          ; $4722
        DEFW    SUB_0752_70              ; $4724
        DEFB    $CD                                              ; $4726
        DEFW    SUB_459D                 ; $4727
        DEFB    $D2                                              ; $4729
        DEFW    SUB_449F_1               ; $472A
        DEFB    $EB,$22                                          ; $472C
        DEFW    SUB_0B2A_13              ; $472E
        DEFW    SUB_22E1                 ; $4730
        DEFW    SUB_0752_42              ; $4732
        DEFB    $E1                                              ; $4734
        DEFW    SUB_0FAB_2               ; $4735
        DEFB    $45,$E5,$2A                                      ; $4737
        DEFW    SUB_0752_42              ; $473A
        DEFW    SUB_2AEB                 ; $473C
        DEFW    SUB_0B2A_13              ; $473E
        DEFB    $7B,$95,$5F,$7A,$9C,$57,$E1,$18,$C3,$7D          ; $4740
        DEFW    SUB_5E51_8               ; $474A
        DEFB    $7C,$9A,$57,$C9,$F5,$F6                          ; $474C
SUB_46BF_1:
        XOR A                            ; $4752  AF
        LD (SUB_0C4B_9),A                ; $4753  32 8F 0C
        POP AF                           ; $4756  F1
SUB_46BF_2:
        LD DE,$0000                      ; $4757  11 00 00
SUB_475A:
        LD (SUB_0C4B_8),HL               ; $475A  22 8D 0C
        CALL NZ,SUB_3BB3                 ; $475D  C4 B3 3B
        LD (SUB_0B2A_25),HL              ; $4760  22 77 0B
        CALL SUB_0D20                    ; $4763  CD 20 0D
        JP NZ,SUB_0D20_22+1              ; $4766  C2 98 0D
        LD SP,HL                         ; $4769  F9
        PUSH DE                          ; $476A  D5
        LD E,(HL)                        ; $476B  5E
        INC HL                           ; $476C  23
        LD D,(HL)                        ; $476D  56
        INC HL                           ; $476E  23
        PUSH HL                          ; $476F  E5
        LD HL,(SUB_0C4B_8)               ; $4770  2A 8D 0C
        CALL SUB_459D                    ; $4773  CD 9D 45
        JP NZ,SUB_0D20_22+1              ; $4776  C2 98 0D
        POP HL                           ; $4779  E1
        POP DE                           ; $477A  D1
        PUSH DE                          ; $477B  D5
        LD A,(HL)                        ; $477C  7E
        PUSH AF                          ; $477D  F5
        INC HL                           ; $477E  23
        PUSH DE                          ; $477F  D5
        LD A,(HL)                        ; $4780  7E
        INC HL                           ; $4781  23
        OR A                             ; $4782  B7
        JP M,SUB_475A_2                  ; $4783  FA A9 47
        CALL SUB_2B25                    ; $4786  CD 25 2B
        EX (SP),HL                       ; $4789  E3
        PUSH HL                          ; $478A  E5
        LD A,(SUB_0C4B_9)                ; $478B  3A 8F 0C
        OR A                             ; $478E  B7
        JR NZ,SUB_475A_1                 ; $478F  20 07
        LD HL,SUB_0C4B_10                ; $4791  21 90 0C
        CALL SUB_2B25                    ; $4794  CD 25 2B
        XOR A                            ; $4797  AF
SUB_475A_1:
        CALL NZ,SUB_2819                 ; $4798  C4 19 28
        POP HL                           ; $479B  E1
        CALL SUB_2B3F                    ; $479C  CD 3F 2B
        POP HL                           ; $479F  E1
        CALL SUB_2B36                    ; $47A0  CD 36 2B
        PUSH HL                          ; $47A3  E5
        CALL SUB_2B81                    ; $47A4  CD 81 2B
        JR SUB_475A_5                    ; $47A7  18 34
SUB_475A_2:
        INC HL                           ; $47A9  23
        INC HL                           ; $47AA  23
        INC HL                           ; $47AB  23
        INC HL                           ; $47AC  23
        LD C,(HL)                        ; $47AD  4E
        INC HL                           ; $47AE  23
        LD B,(HL)                        ; $47AF  46
        INC HL                           ; $47B0  23
        EX (SP),HL                       ; $47B1  E3
        LD E,(HL)                        ; $47B2  5E
        INC HL                           ; $47B3  23
        LD D,(HL)                        ; $47B4  56
        PUSH HL                          ; $47B5  E5
        LD L,C                           ; $47B6  69
        LD H,B                           ; $47B7  60
        LD A,(SUB_0C4B_9)                ; $47B8  3A 8F 0C
        OR A                             ; $47BB  B7
        JR NZ,SUB_475A_3                 ; $47BC  20 05
        LD HL,(SUB_0C4B_10)              ; $47BE  2A 90 0C
        JR SUB_475A_4                    ; $47C1  18 0B
SUB_475A_3:
        CALL SUB_2DA1                    ; $47C3  CD A1 2D
        LD A,(SUB_0B2A_5)                ; $47C6  3A 37 0B
        CP $04                           ; $47C9  FE 04
        JP Z,SUB_0D20_25+1               ; $47CB  CA A4 0D
SUB_475A_4:
        EX DE,HL                         ; $47CE  EB
        POP HL                           ; $47CF  E1
        LD (HL),D                        ; $47D0  72
        DEC HL                           ; $47D1  2B
        LD (HL),E                        ; $47D2  73
        POP HL                           ; $47D3  E1
        PUSH DE                          ; $47D4  D5
        LD E,(HL)                        ; $47D5  5E
        INC HL                           ; $47D6  23
        LD D,(HL)                        ; $47D7  56
        INC HL                           ; $47D8  23
        EX (SP),HL                       ; $47D9  E3
        CALL SUB_2BAE                    ; $47DA  CD AE 2B
SUB_475A_5:
        POP HL                           ; $47DD  E1
        POP BC                           ; $47DE  C1
        SUB B                            ; $47DF  90
SUB_475A_6:
        CALL SUB_2B36                    ; $47E0  CD 36 2B
        JR Z,SUB_475A_7                  ; $47E3  28 09
        EX DE,HL                         ; $47E5  EB
        LD (SUB_0752_43),HL              ; $47E6  22 67 08
        LD L,C                           ; $47E9  69
        LD H,B                           ; $47EA  60
        JP SUB_129A_13                   ; $47EB  C3 82 13
SUB_475A_7:
        LD SP,HL                         ; $47EE  F9
        LD (SUB_0B2A_31),HL              ; $47EF  22 81 0B
        LD HL,(SUB_0B2A_25)              ; $47F2  2A 77 0B
        LD A,(HL)                        ; $47F5  7E
        CP $2C                           ; $47F6  FE 2C
        JP NZ,SUB_129A_14                ; $47F8  C2 86 13
        CALL SUB_13E4                    ; $47FB  CD E4 13
SUB_475A_8:
        CALL SUB_475A                    ; $47FE  CD 5A 47
SUB_475A_9:
        CALL SUB_4A37                    ; $4801  CD 37 4A
        LD A,(HL)                        ; $4804  7E
        INC HL                           ; $4805  23
        LD C,(HL)                        ; $4806  4E
        INC HL                           ; $4807  23
        LD B,(HL)                        ; $4808  46
        POP DE                           ; $4809  D1
        PUSH BC                          ; $480A  C5
        PUSH AF                          ; $480B  F5
        CALL SUB_4A3E                    ; $480C  CD 3E 4A
        POP DE                           ; $480F  D1
        LD E,(HL)                        ; $4810  5E
        INC HL                           ; $4811  23
        LD C,(HL)                        ; $4812  4E
        INC HL                           ; $4813  23
        LD B,(HL)                        ; $4814  46
        POP HL                           ; $4815  E1
SUB_475A_10:
        LD A,E                           ; $4816  7B
        OR D                             ; $4817  B2
        RET Z                            ; $4818  C8
        LD A,D                           ; $4819  7A
        SUB $01                          ; $481A  D6 01
        RET C                            ; $481C  D8
        XOR A                            ; $481D  AF
        CP E                             ; $481E  BB
        INC A                            ; $481F  3C
        RET NC                           ; $4820  D0
        DEC D                            ; $4821  15
        DEC E                            ; $4822  1D
        LD A,(BC)                        ; $4823  0A
        INC BC                           ; $4824  03
        CP (HL)                          ; $4825  BE
        INC HL                           ; $4826  23
        JR Z,SUB_475A_10                 ; $4827  28 ED
        CCF                              ; $4829  3F
        JP SUB_2AC5_4                    ; $482A  C3 D0 2A
SUB_475A_11:
        CALL SUB_3809_7                  ; $482D  CD BC 38
        JR SUB_475A_12                   ; $4830  18 08
        DEFB    $CD                                              ; $4832
        DEFW    SUB_3809_8+1             ; $4833
        DEFB    $18,$03,$CD                                      ; $4835
        DEFW    SUB_33A0                 ; $4838
SUB_475A_12:
        CALL SUB_4868                    ; $483A  CD 68 48
        CALL SUB_4A3A                    ; $483D  CD 3A 4A
        LD BC,SUB_4A89_1                 ; $4840  01 8D 4A
        PUSH BC                          ; $4843  C5
SUB_4844:
        LD A,(HL)                        ; $4844  7E
SUB_4845:
        INC HL                           ; $4845  23
        PUSH HL                          ; $4846  E5
        CALL SUB_48D6                    ; $4847  CD D6 48
        POP HL                           ; $484A  E1
        LD C,(HL)                        ; $484B  4E
        INC HL                           ; $484C  23
        LD B,(HL)                        ; $484D  46
        CALL SUB_485D                    ; $484E  CD 5D 48
        PUSH HL                          ; $4851  E5
        LD L,A                           ; $4852  6F
        CALL SUB_4A2E                    ; $4853  CD 2E 4A
        POP DE                           ; $4856  D1
        RET                              ; $4857  C9
SUB_4858:
        LD A,$01                         ; $4858  3E 01
SUB_485A:
        CALL SUB_48D6                    ; $485A  CD D6 48
SUB_485D:
        LD HL,SUB_0B2A_17                ; $485D  21 68 0B
SUB_4860:
        PUSH HL                          ; $4860  E5
        LD (HL),A                        ; $4861  77
        INC HL                           ; $4862  23
        LD (HL),E                        ; $4863  73
        INC HL                           ; $4864  23
        LD (HL),D                        ; $4865  72
        POP HL                           ; $4866  E1
        RET                              ; $4867  C9
SUB_4868:
        DEC HL                           ; $4868  2B
SUB_4868_1:
        LD B,$22                         ; $4869  06 22
SUB_486B:
        LD D,B                           ; $486B  50
SUB_486C:
        PUSH HL                          ; $486C  E5
        LD C,$FF                         ; $486D  0E FF
SUB_486C_1:
        INC HL                           ; $486F  23
        LD A,(HL)                        ; $4870  7E
        INC C                            ; $4871  0C
        OR A                             ; $4872  B7
        JR Z,SUB_486C_3                  ; $4873  28 06
        CP D                             ; $4875  BA
SUB_486C_2:
        JR Z,SUB_486C_3                  ; $4876  28 03
        CP B                             ; $4878  B8
        JR NZ,SUB_486C_1                 ; $4879  20 F4
SUB_486C_3:
        CP $22                           ; $487B  FE 22
        CALL Z,SUB_13E4                  ; $487D  CC E4 13
        PUSH HL                          ; $4880  E5
        LD A,B                           ; $4881  78
        CP $2C                           ; $4882  FE 2C
        JR NZ,SUB_486C_5                 ; $4884  20 0A
        INC C                            ; $4886  0C
SUB_486C_4:
        DEC C                            ; $4887  0D
        JR Z,SUB_486C_5                  ; $4888  28 06
        DEC HL                           ; $488A  2B
        LD A,(HL)                        ; $488B  7E
        CP $20                           ; $488C  FE 20
        JR Z,SUB_486C_4                  ; $488E  28 F7
SUB_486C_5:
        POP HL                           ; $4890  E1
        EX (SP),HL                       ; $4891  E3
        INC HL                           ; $4892  23
        EX DE,HL                         ; $4893  EB
        LD A,C                           ; $4894  79
        CALL SUB_485D                    ; $4895  CD 5D 48
SUB_486C_6:
        LD DE,SUB_0B2A_17                ; $4898  11 68 0B
SUB_486C_7:
        LD A,$D5                         ; $489B  3E D5
        LD HL,(SUB_0B2A_14)              ; $489D  2A 48 0B
        LD (SUB_0C98_4),HL               ; $48A0  22 D4 0C
        LD A,$03                         ; $48A3  3E 03
        LD (SUB_0B2A_5),A                ; $48A5  32 37 0B
        CALL SUB_2B47                    ; $48A8  CD 47 2B
        LD DE,SUB_0B2A_19                ; $48AB  11 6B 0B
        CALL SUB_459D                    ; $48AE  CD 9D 45
        LD (SUB_0B2A_14),HL              ; $48B1  22 48 0B
        POP HL                           ; $48B4  E1
        LD A,(HL)                        ; $48B5  7E
        RET NZ                           ; $48B6  C0
        LD DE,$0010                      ; $48B7  11 10 00
        JP SUB_0D20_28                   ; $48BA  C3 AC 0D
SUB_486C_8:
        INC HL                           ; $48BD  23
SUB_48BE:
        CALL SUB_4868                    ; $48BE  CD 68 48
SUB_48C1:
        CALL SUB_4A3A                    ; $48C1  CD 3A 4A
        CALL SUB_2B38                    ; $48C4  CD 38 2B
        INC D                            ; $48C7  14
SUB_48C1_1:
        DEC D                            ; $48C8  15
        RET Z                            ; $48C9  C8
        LD A,(BC)                        ; $48CA  0A
        CALL SUB_4291                    ; $48CB  CD 91 42
        CP $0D                           ; $48CE  FE 0D
        CALL Z,SUB_4410                  ; $48D0  CC 10 44
        INC BC                           ; $48D3  03
        JR SUB_48C1_1                    ; $48D4  18 F2
SUB_48D6:
        OR A                             ; $48D6  B7
SUB_48D6_1:
        LD C,$F1                         ; $48D7  0E F1
        PUSH AF                          ; $48D9  F5
        LD HL,(SUB_0B2A_42)              ; $48DA  2A 96 0B
        EX DE,HL                         ; $48DD  EB
        LD HL,(SUB_0B2A_19)              ; $48DE  2A 6B 0B
        CPL                              ; $48E1  2F
        LD C,A                           ; $48E2  4F
        LD B,$FF                         ; $48E3  06 FF
        ADD HL,BC                        ; $48E5  09
        INC HL                           ; $48E6  23
        CALL SUB_459D                    ; $48E7  CD 9D 45
        JR C,SUB_48D6_3                  ; $48EA  38 07
        LD (SUB_0B2A_19),HL              ; $48EC  22 6B 0B
        INC HL                           ; $48EF  23
        EX DE,HL                         ; $48F0  EB
SUB_48D6_2:
        POP AF                           ; $48F1  F1
        RET                              ; $48F2  C9
SUB_48D6_3:
        POP AF                           ; $48F3  F1
        LD DE,$000E                      ; $48F4  11 0E 00
        JP Z,SUB_0D20_28                 ; $48F7  CA AC 0D
        CP A                             ; $48FA  BF
        PUSH AF                          ; $48FB  F5
        LD BC,SUB_48D6_1+1               ; $48FC  01 D8 48
        PUSH BC                          ; $48FF  C5
SUB_4900:
        LD HL,(SUB_0B2A_13)              ; $4900  2A 46 0B
SUB_4900_1:
        LD (SUB_0B2A_19),HL              ; $4903  22 6B 0B
        LD HL,$0000                      ; $4906  21 00 00
        PUSH HL                          ; $4909  E5
        LD HL,(SUB_0B2A_42)              ; $490A  2A 96 0B
        PUSH HL                          ; $490D  E5
        LD HL,SUB_0B2A_15                ; $490E  21 4A 0B
SUB_4900_2:
        EX DE,HL                         ; $4911  EB
        LD HL,(SUB_0B2A_14)              ; $4912  2A 48 0B
        EX DE,HL                         ; $4915  EB
        CALL SUB_459D                    ; $4916  CD 9D 45
        LD BC,SUB_4900_2                 ; $4919  01 11 49
        JP NZ,SUB_494C_9                 ; $491C  C2 A5 49
        LD HL,SUB_0C03_1                 ; $491F  21 1C 0C
        LD (SUB_0C4B_5),HL               ; $4922  22 88 0C
        LD HL,(SUB_0B2A_41)              ; $4925  2A 94 0B
        LD (SUB_0C4B_2),HL               ; $4928  22 85 0C
        LD HL,(SUB_0B2A_40)              ; $492B  2A 92 0B
SUB_4900_3:
        EX DE,HL                         ; $492E  EB
        LD HL,(SUB_0C4B_2)               ; $492F  2A 85 0C
        EX DE,HL                         ; $4932  EB
        CALL SUB_459D                    ; $4933  CD 9D 45
        JR Z,SUB_494C_1                  ; $4936  28 17
        LD A,(HL)                        ; $4938  7E
        INC HL                           ; $4939  23
        INC HL                           ; $493A  23
        INC HL                           ; $493B  23
        PUSH AF                          ; $493C  F5
        CALL SUB_3EA3                    ; $493D  CD A3 3E
        POP AF                           ; $4940  F1
        CP $03                           ; $4941  FE 03
        JR NZ,SUB_4900_4                 ; $4943  20 04
        CALL SUB_49A6                    ; $4945  CD A6 49
        XOR A                            ; $4948  AF
SUB_4900_4:
        LD E,A                           ; $4949  5F
        LD D,$00                         ; $494A  16 00
SUB_494C:
        ADD HL,DE                        ; $494C  19
        JR SUB_4900_3                    ; $494D  18 DF
SUB_494C_1:
        LD HL,(SUB_0C4B_5)               ; $494F  2A 88 0C
SUB_494C_2:
        LD A,(HL)                        ; $4952  7E
        INC HL                           ; $4953  23
        LD H,(HL)                        ; $4954  66
        LD L,A                           ; $4955  6F
        OR H                             ; $4956  B4
        EX DE,HL                         ; $4957  EB
        LD HL,(SUB_0B2A_41)              ; $4958  2A 94 0B
        JR Z,SUB_494C_4                  ; $495B  28 13
        EX DE,HL                         ; $495D  EB
        LD (SUB_0C4B_5),HL               ; $495E  22 88 0C
        INC HL                           ; $4961  23
        INC HL                           ; $4962  23
        LD E,(HL)                        ; $4963  5E
        INC HL                           ; $4964  23
        LD D,(HL)                        ; $4965  56
        INC HL                           ; $4966  23
        EX DE,HL                         ; $4967  EB
        ADD HL,DE                        ; $4968  19
        LD (SUB_0C4B_2),HL               ; $4969  22 85 0C
        EX DE,HL                         ; $496C  EB
        JR SUB_4900_3                    ; $496D  18 BF
SUB_494C_3:
        POP BC                           ; $496F  C1
SUB_494C_4:
        EX DE,HL                         ; $4970  EB
        LD HL,(SUB_0B2A_42)              ; $4971  2A 96 0B
        EX DE,HL                         ; $4974  EB
        CALL SUB_459D                    ; $4975  CD 9D 45
        JP Z,SUB_49C3_1                  ; $4978  CA CA 49
        LD A,(HL)                        ; $497B  7E
        INC HL                           ; $497C  23
        PUSH AF                          ; $497D  F5
        INC HL                           ; $497E  23
        INC HL                           ; $497F  23
        CALL SUB_3EA3                    ; $4980  CD A3 3E
        LD C,(HL)                        ; $4983  4E
SUB_494C_5:
        INC HL                           ; $4984  23
        LD B,(HL)                        ; $4985  46
        INC HL                           ; $4986  23
        POP AF                           ; $4987  F1
SUB_494C_6:
        PUSH HL                          ; $4988  E5
        ADD HL,BC                        ; $4989  09
        CP $03                           ; $498A  FE 03
        JR NZ,SUB_494C_3                 ; $498C  20 E1
        LD (SUB_0B2A_21),HL              ; $498E  22 6F 0B
        POP HL                           ; $4991  E1
SUB_494C_7:
        LD C,(HL)                        ; $4992  4E
        LD B,$00                         ; $4993  06 00
        ADD HL,BC                        ; $4995  09
        ADD HL,BC                        ; $4996  09
        INC HL                           ; $4997  23
SUB_494C_8:
        EX DE,HL                         ; $4998  EB
        LD HL,(SUB_0B2A_21)              ; $4999  2A 6F 0B
        EX DE,HL                         ; $499C  EB
        CALL SUB_459D                    ; $499D  CD 9D 45
        JR Z,SUB_494C_4                  ; $49A0  28 CE
        LD BC,SUB_494C_8                 ; $49A2  01 98 49
SUB_494C_9:
        PUSH BC                          ; $49A5  C5
SUB_49A6:
        XOR A                            ; $49A6  AF
        OR (HL)                          ; $49A7  B6
        INC HL                           ; $49A8  23
        LD E,(HL)                        ; $49A9  5E
        INC HL                           ; $49AA  23
        LD D,(HL)                        ; $49AB  56
        INC HL                           ; $49AC  23
        RET Z                            ; $49AD  C8
        LD B,H                           ; $49AE  44
        LD C,L                           ; $49AF  4D
        LD HL,(SUB_0B2A_19)              ; $49B0  2A 6B 0B
        CALL SUB_459D                    ; $49B3  CD 9D 45
        LD H,B                           ; $49B6  60
        LD L,C                           ; $49B7  69
        RET C                            ; $49B8  D8
SUB_49A6_1:
        POP HL                           ; $49B9  E1
        EX (SP),HL                       ; $49BA  E3
        CALL SUB_459D                    ; $49BB  CD 9D 45
        EX (SP),HL                       ; $49BE  E3
        PUSH HL                          ; $49BF  E5
        LD H,B                           ; $49C0  60
        LD L,C                           ; $49C1  69
        RET NC                           ; $49C2  D0
SUB_49C3:
        POP BC                           ; $49C3  C1
        POP AF                           ; $49C4  F1
        POP AF                           ; $49C5  F1
        PUSH HL                          ; $49C6  E5
        PUSH DE                          ; $49C7  D5
        PUSH BC                          ; $49C8  C5
        RET                              ; $49C9  C9
SUB_49C3_1:
        POP DE                           ; $49CA  D1
        POP HL                           ; $49CB  E1
        LD A,L                           ; $49CC  7D
SUB_49C3_2:
        OR H                             ; $49CD  B4
        RET Z                            ; $49CE  C8
        DEC HL                           ; $49CF  2B
        LD B,(HL)                        ; $49D0  46
        DEC HL                           ; $49D1  2B
        LD C,(HL)                        ; $49D2  4E
        PUSH HL                          ; $49D3  E5
        DEC HL                           ; $49D4  2B
        LD L,(HL)                        ; $49D5  6E
        LD H,$00                         ; $49D6  26 00
        ADD HL,BC                        ; $49D8  09
        LD D,B                           ; $49D9  50
        LD E,C                           ; $49DA  59
        DEC HL                           ; $49DB  2B
        LD B,H                           ; $49DC  44
        LD C,L                           ; $49DD  4D
        LD HL,(SUB_0B2A_19)              ; $49DE  2A 6B 0B
        CALL SUB_4492                    ; $49E1  CD 92 44
        POP HL                           ; $49E4  E1
        LD (HL),C                        ; $49E5  71
        INC HL                           ; $49E6  23
        LD (HL),B                        ; $49E7  70
        LD L,C                           ; $49E8  69
        LD H,B                           ; $49E9  60
        DEC HL                           ; $49EA  2B
        JP SUB_4900_1                    ; $49EB  C3 03 49
SUB_49C3_3:
        PUSH BC                          ; $49EE  C5
        PUSH HL                          ; $49EF  E5
        LD HL,(SUB_0C98_4)               ; $49F0  2A D4 0C
        EX (SP),HL                       ; $49F3  E3
        CALL SUB_1C11                    ; $49F4  CD 11 1C
        EX (SP),HL                       ; $49F7  E3
        CALL SUB_2CB3                    ; $49F8  CD B3 2C
        LD A,(HL)                        ; $49FB  7E
        PUSH HL                          ; $49FC  E5
        LD HL,(SUB_0C98_4)               ; $49FD  2A D4 0C
        PUSH HL                          ; $4A00  E5
        ADD A,(HL)                       ; $4A01  86
        LD DE,$000F                      ; $4A02  11 0F 00
        JP C,SUB_0D20_28                 ; $4A05  DA AC 0D
        CALL SUB_485A                    ; $4A08  CD 5A 48
        POP DE                           ; $4A0B  D1
        CALL SUB_4A3E                    ; $4A0C  CD 3E 4A
        EX (SP),HL                       ; $4A0F  E3
        CALL SUB_4A3D                    ; $4A10  CD 3D 4A
        PUSH HL                          ; $4A13  E5
        LD HL,(SUB_0B2A_18)              ; $4A14  2A 69 0B
        EX DE,HL                         ; $4A17  EB
        CALL SUB_4A26                    ; $4A18  CD 26 4A
        CALL SUB_4A26                    ; $4A1B  CD 26 4A
        LD HL,SUB_1A93_1                 ; $4A1E  21 A0 1A
        EX (SP),HL                       ; $4A21  E3
        PUSH HL                          ; $4A22  E5
        JP SUB_486C_6                    ; $4A23  C3 98 48
SUB_4A26:
        POP HL                           ; $4A26  E1
        EX (SP),HL                       ; $4A27  E3
        LD A,(HL)                        ; $4A28  7E
        INC HL                           ; $4A29  23
        LD C,(HL)                        ; $4A2A  4E
        INC HL                           ; $4A2B  23
        LD B,(HL)                        ; $4A2C  46
        LD L,A                           ; $4A2D  6F
SUB_4A2E:
        INC L                            ; $4A2E  2C
SUB_4A2E_1:
        DEC L                            ; $4A2F  2D
        RET Z                            ; $4A30  C8
        LD A,(BC)                        ; $4A31  0A
        LD (DE),A                        ; $4A32  12
        INC BC                           ; $4A33  03
        INC DE                           ; $4A34  13
        JR SUB_4A2E_1                    ; $4A35  18 F8
SUB_4A37:
        CALL SUB_2CB3                    ; $4A37  CD B3 2C
SUB_4A3A:
        LD HL,(SUB_0C98_4)               ; $4A3A  2A D4 0C
SUB_4A3D:
        EX DE,HL                         ; $4A3D  EB
SUB_4A3E:
        CALL SUB_4A57                    ; $4A3E  CD 57 4A
        EX DE,HL                         ; $4A41  EB
        RET NZ                           ; $4A42  C0
        PUSH DE                          ; $4A43  D5
        LD D,B                           ; $4A44  50
        LD E,C                           ; $4A45  59
        DEC DE                           ; $4A46  1B
        LD C,(HL)                        ; $4A47  4E
        LD HL,(SUB_0B2A_19)              ; $4A48  2A 6B 0B
        CALL SUB_459D                    ; $4A4B  CD 9D 45
        JR NZ,SUB_4A3E_1                 ; $4A4E  20 05
        LD B,A                           ; $4A50  47
        ADD HL,BC                        ; $4A51  09
        LD (SUB_0B2A_19),HL              ; $4A52  22 6B 0B
SUB_4A3E_1:
        POP HL                           ; $4A55  E1
        RET                              ; $4A56  C9
SUB_4A57:
        LD HL,(SUB_0B2A_14)              ; $4A57  2A 48 0B
        DEC HL                           ; $4A5A  2B
        LD B,(HL)                        ; $4A5B  46
        DEC HL                           ; $4A5C  2B
        LD C,(HL)                        ; $4A5D  4E
        DEC HL                           ; $4A5E  2B
        CALL SUB_459D                    ; $4A5F  CD 9D 45
        RET NZ                           ; $4A62  C0
        LD (SUB_0B2A_14),HL              ; $4A63  22 48 0B
SUB_4A57_1:
        RET                              ; $4A66  C9
SUB_4A57_2:
        LD BC,SUB_1E4D                   ; $4A67  01 4D 1E
        PUSH BC                          ; $4A6A  C5
SUB_4A6B:
        CALL SUB_4A37                    ; $4A6B  CD 37 4A
        XOR A                            ; $4A6E  AF
        LD D,A                           ; $4A6F  57
        LD A,(HL)                        ; $4A70  7E
SUB_4A6B_1:
        OR A                             ; $4A71  B7
        RET                              ; $4A72  C9
SUB_4A6B_2:
        LD BC,SUB_1E4D                   ; $4A73  01 4D 1E
        PUSH BC                          ; $4A76  C5
SUB_4A77:
        CALL SUB_4A6B                    ; $4A77  CD 6B 4A
        JP Z,SUB_14E4_2                  ; $4A7A  CA EB 14
        INC HL                           ; $4A7D  23
        LD E,(HL)                        ; $4A7E  5E
        INC HL                           ; $4A7F  23
        LD D,(HL)                        ; $4A80  56
        LD A,(DE)                        ; $4A81  1A
        RET                              ; $4A82  C9
SUB_4A77_1:
        CALL SUB_4858                    ; $4A83  CD 58 48
        CALL SUB_20B5                    ; $4A86  CD B5 20
SUB_4A89:
        LD HL,(SUB_0B2A_18)              ; $4A89  2A 69 0B
        LD (HL),E                        ; $4A8C  73
SUB_4A89_1:
        POP BC                           ; $4A8D  C1
        JP SUB_486C_6                    ; $4A8E  C3 98 48
SUB_4A89_2:
        CALL SUB_13E4                    ; $4A91  CD E4 13
        CALL SUB_45A3                    ; $4A94  CD A3 45
        JR Z,SUB_4A57_1                  ; $4A97  28 CD
        OR D                             ; $4A99  B2
        JR NZ,SUB_4A6B_1                 ; $4A9A  20 D5
        CALL SUB_45A3                    ; $4A9C  CD A3 45
        INC L                            ; $4A9F  2C
        CALL SUB_1A8C_1+1                ; $4AA0  CD 90 1A
        CALL SUB_45A3                    ; $4AA3  CD A3 45
        ADD HL,HL                        ; $4AA6  29
        EX (SP),HL                       ; $4AA7  E3
        PUSH HL                          ; $4AA8  E5
        CALL SUB_1DE3                    ; $4AA9  CD E3 1D
        JR Z,SUB_4A89_3                  ; $4AAC  28 05
        CALL SUB_20B5                    ; $4AAE  CD B5 20
        JR SUB_4A89_4                    ; $4AB1  18 03
SUB_4A89_3:
        CALL SUB_4A77                    ; $4AB3  CD 77 4A
SUB_4A89_4:
        POP DE                           ; $4AB6  D1
        CALL SUB_4ABF                    ; $4AB7  CD BF 4A
SUB_4A89_5:
        CALL SUB_20B5                    ; $4ABA  CD B5 20
        LD A,$20                         ; $4ABD  3E 20
SUB_4ABF:
        PUSH AF                          ; $4ABF  F5
        LD A,E                           ; $4AC0  7B
        CALL SUB_485A                    ; $4AC1  CD 5A 48
        LD B,A                           ; $4AC4  47
        POP AF                           ; $4AC5  F1
        INC B                            ; $4AC6  04
        DEC B                            ; $4AC7  05
        JR Z,SUB_4A89_1                  ; $4AC8  28 C3
        LD HL,(SUB_0B2A_18)              ; $4ACA  2A 69 0B
SUB_4ABF_1:
        LD (HL),A                        ; $4ACD  77
        INC HL                           ; $4ACE  23
        DJNZ SUB_4ABF_1                  ; $4ACF  10 FC
        JR SUB_4A89_1                    ; $4AD1  18 BA
SUB_4ABF_2:
        CALL SUB_4B4A                    ; $4AD3  CD 4A 4B
        XOR A                            ; $4AD6  AF
SUB_4ABF_3:
        EX (SP),HL                       ; $4AD7  E3
        LD C,A                           ; $4AD8  4F
SUB_4ABF_4:
        LD A,$E5                         ; $4AD9  3E E5
        PUSH HL                          ; $4ADB  E5
        LD A,(HL)                        ; $4ADC  7E
        CP B                             ; $4ADD  B8
        JR C,SUB_4ABF_5+1                ; $4ADE  38 02
        LD A,B                           ; $4AE0  78
SUB_4ABF_5:
        LD DE,$000E                      ; $4AE1  11 0E 00
        PUSH BC                          ; $4AE4  C5
        CALL SUB_48D6                    ; $4AE5  CD D6 48
        POP BC                           ; $4AE8  C1
        POP HL                           ; $4AE9  E1
        PUSH HL                          ; $4AEA  E5
        INC HL                           ; $4AEB  23
        LD B,(HL)                        ; $4AEC  46
        INC HL                           ; $4AED  23
        LD H,(HL)                        ; $4AEE  66
        LD L,B                           ; $4AEF  68
        LD B,$00                         ; $4AF0  06 00
        ADD HL,BC                        ; $4AF2  09
        LD B,H                           ; $4AF3  44
        LD C,L                           ; $4AF4  4D
        CALL SUB_485D                    ; $4AF5  CD 5D 48
        LD L,A                           ; $4AF8  6F
        CALL SUB_4A2E                    ; $4AF9  CD 2E 4A
        POP DE                           ; $4AFC  D1
        CALL SUB_4A3E                    ; $4AFD  CD 3E 4A
        JP SUB_486C_6                    ; $4B00  C3 98 48
SUB_4ABF_6:
        CALL SUB_4B4A                    ; $4B03  CD 4A 4B
        POP DE                           ; $4B06  D1
        PUSH DE                          ; $4B07  D5
        LD A,(DE)                        ; $4B08  1A
        SUB B                            ; $4B09  90
        JR SUB_4ABF_3                    ; $4B0A  18 CB
SUB_4ABF_7:
        EX DE,HL                         ; $4B0C  EB
        LD A,(HL)                        ; $4B0D  7E
        CALL SUB_4B4F                    ; $4B0E  CD 4F 4B
        INC B                            ; $4B11  04
        DEC B                            ; $4B12  05
        JP Z,SUB_14E4_2                  ; $4B13  CA EB 14
        PUSH BC                          ; $4B16  C5
        CALL SUB_4C5F                    ; $4B17  CD 5F 4C
        POP AF                           ; $4B1A  F1
        EX (SP),HL                       ; $4B1B  E3
        LD BC,$4ADB                      ; $4B1C  01 DB 4A
        PUSH BC                          ; $4B1F  C5
        DEC A                            ; $4B20  3D
        CP (HL)                          ; $4B21  BE
        LD B,$00                         ; $4B22  06 00
        RET NC                           ; $4B24  D0
        LD C,A                           ; $4B25  4F
        LD A,(HL)                        ; $4B26  7E
        SUB C                            ; $4B27  91
        CP E                             ; $4B28  BB
        LD B,A                           ; $4B29  47
        RET C                            ; $4B2A  D8
        LD B,E                           ; $4B2B  43
        RET                              ; $4B2C  C9
        DEFB    $CD                                              ; $4B2D
        DEFW    SUB_4A6B                 ; $4B2E
        DEFW    SUB_4DC3_1               ; $4B30
        DEFB    $1E                                              ; $4B32
        DEFW    SUB_22E1_16              ; $4B33
        DEFB    $7E,$23,$66,$6F,$E5,$19,$46,$72,$E3,$C5,$2B,$CD  ; $4B35
        DEFW    SUB_13E4                 ; $4B41
        DEFB    $CD                                              ; $4B43
        DEFW    SUB_311E                 ; $4B44
        DEFB    $C1,$E1,$70,$C9                                  ; $4B46
SUB_4B4A:
        EX DE,HL                         ; $4B4A  EB
        CALL SUB_45A3                    ; $4B4B  CD A3 45
        ADD HL,HL                        ; $4B4E  29
SUB_4B4F:
        POP BC                           ; $4B4F  C1
        POP DE                           ; $4B50  D1
        PUSH BC                          ; $4B51  C5
        LD B,E                           ; $4B52  43
        RET                              ; $4B53  C9
SUB_4B4F_1:
        CALL SUB_13E4                    ; $4B54  CD E4 13
        CALL SUB_1A8C                    ; $4B57  CD 8C 1A
        CALL SUB_1DE3                    ; $4B5A  CD E3 1D
        LD A,$01                         ; $4B5D  3E 01
        PUSH AF                          ; $4B5F  F5
        JR Z,SUB_4B4F_2                  ; $4B60  28 13
        POP AF                           ; $4B62  F1
        CALL SUB_20B5                    ; $4B63  CD B5 20
        OR A                             ; $4B66  B7
        JP Z,SUB_14E4_2                  ; $4B67  CA EB 14
        PUSH AF                          ; $4B6A  F5
        CALL SUB_45A3                    ; $4B6B  CD A3 45
        INC L                            ; $4B6E  2C
        CALL SUB_1A8C_1+1                ; $4B6F  CD 90 1A
        CALL SUB_2CB3                    ; $4B72  CD B3 2C
SUB_4B4F_2:
        CALL SUB_45A3                    ; $4B75  CD A3 45
        INC L                            ; $4B78  2C
        PUSH HL                          ; $4B79  E5
        LD HL,(SUB_0C98_4)               ; $4B7A  2A D4 0C
        EX (SP),HL                       ; $4B7D  E3
        CALL SUB_1A8C_1+1                ; $4B7E  CD 90 1A
        CALL SUB_45A3                    ; $4B81  CD A3 45
        ADD HL,HL                        ; $4B84  29
        PUSH HL                          ; $4B85  E5
        CALL SUB_4A37                    ; $4B86  CD 37 4A
        EX DE,HL                         ; $4B89  EB
        POP BC                           ; $4B8A  C1
        POP HL                           ; $4B8B  E1
        POP AF                           ; $4B8C  F1
        PUSH BC                          ; $4B8D  C5
        LD BC,SUB_2990_7                 ; $4B8E  01 E1 29
        PUSH BC                          ; $4B91  C5
        LD BC,SUB_1E4D                   ; $4B92  01 4D 1E
        PUSH BC                          ; $4B95  C5
        PUSH AF                          ; $4B96  F5
        PUSH DE                          ; $4B97  D5
        CALL SUB_4A3D                    ; $4B98  CD 3D 4A
        POP DE                           ; $4B9B  D1
        POP AF                           ; $4B9C  F1
        LD B,A                           ; $4B9D  47
        DEC A                            ; $4B9E  3D
        LD C,A                           ; $4B9F  4F
        CP (HL)                          ; $4BA0  BE
        LD A,$00                         ; $4BA1  3E 00
        RET NC                           ; $4BA3  D0
        LD A,(DE)                        ; $4BA4  1A
        OR A                             ; $4BA5  B7
        LD A,B                           ; $4BA6  78
        RET Z                            ; $4BA7  C8
        LD A,(HL)                        ; $4BA8  7E
        INC HL                           ; $4BA9  23
        LD B,(HL)                        ; $4BAA  46
        INC HL                           ; $4BAB  23
        LD H,(HL)                        ; $4BAC  66
        LD L,B                           ; $4BAD  68
        LD B,$00                         ; $4BAE  06 00
        ADD HL,BC                        ; $4BB0  09
        SUB C                            ; $4BB1  91
        LD B,A                           ; $4BB2  47
SUB_4B4F_3:
        PUSH BC                          ; $4BB3  C5
        PUSH DE                          ; $4BB4  D5
        EX (SP),HL                       ; $4BB5  E3
        LD C,(HL)                        ; $4BB6  4E
        INC HL                           ; $4BB7  23
        LD E,(HL)                        ; $4BB8  5E
        INC HL                           ; $4BB9  23
        LD D,(HL)                        ; $4BBA  56
        POP HL                           ; $4BBB  E1
SUB_4B4F_4:
        PUSH HL                          ; $4BBC  E5
        PUSH DE                          ; $4BBD  D5
        PUSH BC                          ; $4BBE  C5
SUB_4B4F_5:
        LD A,(DE)                        ; $4BBF  1A
        CP (HL)                          ; $4BC0  BE
        JR NZ,SUB_4B4F_8                 ; $4BC1  20 16
        INC DE                           ; $4BC3  13
        DEC C                            ; $4BC4  0D
        JR Z,SUB_4B4F_7                  ; $4BC5  28 09
        INC HL                           ; $4BC7  23
        DJNZ SUB_4B4F_5                  ; $4BC8  10 F5
        POP DE                           ; $4BCA  D1
        POP DE                           ; $4BCB  D1
        POP BC                           ; $4BCC  C1
SUB_4B4F_6:
        POP DE                           ; $4BCD  D1
        XOR A                            ; $4BCE  AF
        RET                              ; $4BCF  C9
SUB_4B4F_7:
        POP HL                           ; $4BD0  E1
        POP DE                           ; $4BD1  D1
        POP DE                           ; $4BD2  D1
        POP BC                           ; $4BD3  C1
        LD A,B                           ; $4BD4  78
        SUB H                            ; $4BD5  94
        ADD A,C                          ; $4BD6  81
        INC A                            ; $4BD7  3C
        RET                              ; $4BD8  C9
SUB_4B4F_8:
        POP BC                           ; $4BD9  C1
        POP DE                           ; $4BDA  D1
        POP HL                           ; $4BDB  E1
        INC HL                           ; $4BDC  23
        DJNZ SUB_4B4F_4                  ; $4BDD  10 DD
        JR SUB_4B4F_6                    ; $4BDF  18 EC
SUB_4B4F_9:
        CALL SUB_45A3                    ; $4BE1  CD A3 45
        JR Z,SUB_4B4F_3                  ; $4BE4  28 CD
        OR E                             ; $4BE6  B3
        DEC SP                           ; $4BE7  3B
        CALL SUB_2CB3                    ; $4BE8  CD B3 2C
        PUSH HL                          ; $4BEB  E5
        PUSH DE                          ; $4BEC  D5
        EX DE,HL                         ; $4BED  EB
        INC HL                           ; $4BEE  23
        LD E,(HL)                        ; $4BEF  5E
        INC HL                           ; $4BF0  23
        LD D,(HL)                        ; $4BF1  56
        LD HL,(SUB_0B2A_42)              ; $4BF2  2A 96 0B
        CALL SUB_459D                    ; $4BF5  CD 9D 45
        JR C,SUB_4C03_1                  ; $4BF8  38 12
        LD HL,(SUB_0752_44)              ; $4BFA  2A 69 08
        CALL SUB_459D                    ; $4BFD  CD 9D 45
        JR NC,SUB_4C03_1                 ; $4C00  30 0A
        POP HL                           ; $4C02  E1
SUB_4C03:
        PUSH HL                          ; $4C03  E5
        CALL SUB_4844                    ; $4C04  CD 44 48
        POP HL                           ; $4C07  E1
        PUSH HL                          ; $4C08  E5
        CALL SUB_2B47                    ; $4C09  CD 47 2B
SUB_4C03_1:
        POP HL                           ; $4C0C  E1
        EX (SP),HL                       ; $4C0D  E3
        CALL SUB_45A3                    ; $4C0E  CD A3 45
        INC L                            ; $4C11  2C
        CALL SUB_20B2                    ; $4C12  CD B2 20
        OR A                             ; $4C15  B7
SUB_4C03_2:
        JP Z,SUB_14E4_2                  ; $4C16  CA EB 14
        PUSH AF                          ; $4C19  F5
        LD A,(HL)                        ; $4C1A  7E
        CALL SUB_4C5F                    ; $4C1B  CD 5F 4C
        PUSH DE                          ; $4C1E  D5
        CALL SUB_1A85                    ; $4C1F  CD 85 1A
        PUSH HL                          ; $4C22  E5
        CALL SUB_4A37                    ; $4C23  CD 37 4A
        EX DE,HL                         ; $4C26  EB
        POP HL                           ; $4C27  E1
        POP BC                           ; $4C28  C1
        POP AF                           ; $4C29  F1
        LD B,A                           ; $4C2A  47
        EX (SP),HL                       ; $4C2B  E3
        PUSH HL                          ; $4C2C  E5
        LD HL,SUB_2990_7                 ; $4C2D  21 E1 29
        EX (SP),HL                       ; $4C30  E3
        LD A,C                           ; $4C31  79
        OR A                             ; $4C32  B7
        RET Z                            ; $4C33  C8
        LD A,(HL)                        ; $4C34  7E
        SUB B                            ; $4C35  90
        JP C,SUB_14E4_2                  ; $4C36  DA EB 14
        INC A                            ; $4C39  3C
        CP C                             ; $4C3A  B9
        JR C,SUB_4C03_3                  ; $4C3B  38 01
        LD A,C                           ; $4C3D  79
SUB_4C03_3:
        LD C,B                           ; $4C3E  48
        DEC C                            ; $4C3F  0D
        LD B,$00                         ; $4C40  06 00
        PUSH DE                          ; $4C42  D5
        INC HL                           ; $4C43  23
        LD E,(HL)                        ; $4C44  5E
SUB_4C03_4:
        INC HL                           ; $4C45  23
        LD H,(HL)                        ; $4C46  66
        LD L,E                           ; $4C47  6B
        ADD HL,BC                        ; $4C48  09
        LD B,A                           ; $4C49  47
        POP DE                           ; $4C4A  D1
        EX DE,HL                         ; $4C4B  EB
        LD C,(HL)                        ; $4C4C  4E
        INC HL                           ; $4C4D  23
        LD A,(HL)                        ; $4C4E  7E
SUB_4C03_5:
        INC HL                           ; $4C4F  23
        LD H,(HL)                        ; $4C50  66
        LD L,A                           ; $4C51  6F
        EX DE,HL                         ; $4C52  EB
        LD A,C                           ; $4C53  79
        OR A                             ; $4C54  B7
        RET Z                            ; $4C55  C8
SUB_4C03_6:
        LD A,(DE)                        ; $4C56  1A
        LD (HL),A                        ; $4C57  77
        INC DE                           ; $4C58  13
        INC HL                           ; $4C59  23
        DEC C                            ; $4C5A  0D
        RET Z                            ; $4C5B  C8
        DJNZ SUB_4C03_6                  ; $4C5C  10 F8
        RET                              ; $4C5E  C9
SUB_4C5F:
        LD E,$FF                         ; $4C5F  1E FF
        CP $29                           ; $4C61  FE 29
        JR Z,SUB_4C5F_1                  ; $4C63  28 07
        CALL SUB_45A3                    ; $4C65  CD A3 45
        INC L                            ; $4C68  2C
        CALL SUB_20B2                    ; $4C69  CD B2 20
SUB_4C5F_1:
        CALL SUB_45A3                    ; $4C6C  CD A3 45
        ADD HL,HL                        ; $4C6F  29
        RET                              ; $4C70  C9
        DEFB    $CD                                              ; $4C71
        DEFW    SUB_1DE3                 ; $4C72
        DEFB    $C2,$7D,$4C,$CD,$3A,$4A,$CD,$00                  ; $4C74  "B}LM:JM"
        DEFB    $49,$2A                                          ; $4C7C
        DEFW    SUB_0B2A_42              ; $4C7E
        DEFW    SUB_2AEB                 ; $4C80
        DEFW    SUB_0B2A_19              ; $4C82
        DEFW    SUB_3BB3_2               ; $4C84
        DEFB    $1E                                              ; $4C86
SUB_4C87:
        LD A,$3F                         ; $4C87  3E 3F
        CALL SUB_4291                    ; $4C89  CD 91 42
        LD A,$20                         ; $4C8C  3E 20
        CALL SUB_4291                    ; $4C8E  CD 91 42
        JP SUB_4CA1                      ; $4C91  C3 A1 4C
SUB_4C87_1:
        CALL SUB_43A2                    ; $4C94  CD A2 43
        CP $01                           ; $4C97  FE 01
        JP NZ,SUB_4CA1_9                 ; $4C99  C2 F0 4C
        LD (HL),$00                      ; $4C9C  36 00
        JR SUB_4CA1_2                    ; $4C9E  18 13
SUB_4C87_2:
        LD (HL),B                        ; $4CA0  70
SUB_4CA1:
        XOR A                            ; $4CA1  AF
        LD (SUB_0752_33+1),A             ; $4CA2  32 57 08
        XOR A                            ; $4CA5  AF
        LD (L_0CB6),A                    ; $4CA6  32 B6 0C
SUB_4CA1_1:
        CALL SUB_4DBC                    ; $4CA9  CD BC 4D
        CALL SUB_43A2                    ; $4CAC  CD A2 43
        CP $01                           ; $4CAF  FE 01
        JR NZ,SUB_4CA1_8                 ; $4CB1  20 32
SUB_4CA1_2:
        CALL SUB_4406                    ; $4CB3  CD 06 44
        LD HL,$FFFF                      ; $4CB6  21 FF FF
        JP SUB_3EDB_9                    ; $4CB9  C3 05 3F
SUB_4CA1_3:
        LD A,(SUB_0752_38)               ; $4CBC  3A 61 08
        OR A                             ; $4CBF  B7
        LD A,$5C                         ; $4CC0  3E 5C
        LD (SUB_0752_38),A               ; $4CC2  32 61 08
        JR NZ,SUB_4CA1_5                 ; $4CC5  20 07
SUB_4CA1_4:
        DEC B                            ; $4CC7  05
        JR Z,SUB_4C87_2                  ; $4CC8  28 D6
        CALL SUB_4291                    ; $4CCA  CD 91 42
        INC B                            ; $4CCD  04
SUB_4CA1_5:
        DEC B                            ; $4CCE  05
        DEC HL                           ; $4CCF  2B
        JR Z,SUB_4CA1_7                  ; $4CD0  28 0D
        LD A,(HL)                        ; $4CD2  7E
        CALL SUB_4291                    ; $4CD3  CD 91 42
        JR SUB_4C87_1                    ; $4CD6  18 BC
SUB_4CA1_6:
        DEC B                            ; $4CD8  05
        DEC HL                           ; $4CD9  2B
        CALL SUB_4291                    ; $4CDA  CD 91 42
        JR NZ,SUB_4C87_1                 ; $4CDD  20 B5
SUB_4CA1_7:
        CALL SUB_4291                    ; $4CDF  CD 91 42
        CALL SUB_4406                    ; $4CE2  CD 06 44
SUB_4CA1_8:
        LD HL,SUB_0925_12                ; $4CE5  21 31 0A
        LD B,$01                         ; $4CE8  06 01
        PUSH AF                          ; $4CEA  F5
        XOR A                            ; $4CEB  AF
        LD (SUB_0752_38),A               ; $4CEC  32 61 08
        POP AF                           ; $4CEF  F1
SUB_4CA1_9:
        LD C,A                           ; $4CF0  4F
        CP $7F                           ; $4CF1  FE 7F
        JR Z,SUB_4CA1_3                  ; $4CF3  28 C7
        LD A,(SUB_0752_38)               ; $4CF5  3A 61 08
        OR A                             ; $4CF8  B7
        JR Z,SUB_4CA1_10                 ; $4CF9  28 09
        LD A,$5C                         ; $4CFB  3E 5C
        CALL SUB_4291                    ; $4CFD  CD 91 42
        XOR A                            ; $4D00  AF
        LD (SUB_0752_38),A               ; $4D01  32 61 08
SUB_4CA1_10:
        LD A,C                           ; $4D04  79
SUB_4CA1_11:
        CP $07                           ; $4D05  FE 07
        JR Z,SUB_4CA1_16                 ; $4D07  28 58
        CP $03                           ; $4D09  FE 03
        CALL Z,SUB_4610                  ; $4D0B  CC 10 46
        SCF                              ; $4D0E  37
        RET Z                            ; $4D0F  C8
        CP $0D                           ; $4D10  FE 0D
        JP Z,SUB_4CA1_20                 ; $4D12  CA 9F 4D
        CP $09                           ; $4D15  FE 09
        JR Z,SUB_4CA1_16                 ; $4D17  28 48
        CP $0A                           ; $4D19  FE 0A
        JR NZ,SUB_4CA1_12                ; $4D1B  20 07
        DEC B                            ; $4D1D  05
        JP Z,SUB_4CA1                    ; $4D1E  CA A1 4C
        INC B                            ; $4D21  04
        JR SUB_4CA1_16                   ; $4D22  18 3D
SUB_4CA1_12:
        CP $15                           ; $4D24  FE 15
        CALL Z,SUB_4610                  ; $4D26  CC 10 46
        JP Z,SUB_4CA1                    ; $4D29  CA A1 4C
        CP $08                           ; $4D2C  FE 08
        JR NZ,SUB_4CA1_13                ; $4D2E  20 0A
        DEC B                            ; $4D30  05
        JP Z,SUB_4CA1_1                  ; $4D31  CA A9 4C
        CALL SUB_4DC3                    ; $4D34  CD C3 4D
        JP SUB_4C87_1                    ; $4D37  C3 94 4C
SUB_4CA1_13:
        CP $18                           ; $4D3A  FE 18
        JP NZ,SUB_4CA1_14                ; $4D3C  C2 44 4D
        LD A,$23                         ; $4D3F  3E 23
        JP SUB_4CA1_7                    ; $4D41  C3 DF 4C
SUB_4CA1_14:
        CP $12                           ; $4D44  FE 12
        JR NZ,SUB_4CA1_15                ; $4D46  20 14
        PUSH BC                          ; $4D48  C5
        PUSH DE                          ; $4D49  D5
        PUSH HL                          ; $4D4A  E5
        LD (HL),$00                      ; $4D4B  36 00
        CALL SUB_4406                    ; $4D4D  CD 06 44
        LD HL,SUB_0925_12                ; $4D50  21 31 0A
        CALL SUB_211B                    ; $4D53  CD 1B 21
        POP HL                           ; $4D56  E1
        POP DE                           ; $4D57  D1
        POP BC                           ; $4D58  C1
        JP SUB_4C87_1                    ; $4D59  C3 94 4C
SUB_4CA1_15:
        CP $20                           ; $4D5C  FE 20
        JP C,SUB_4C87_1                  ; $4D5E  DA 94 4C
SUB_4CA1_16:
        LD A,B                           ; $4D61  78
        INC A                            ; $4D62  3C
        JR NZ,SUB_4CA1_17                ; $4D63  20 18
        PUSH HL                          ; $4D65  E5
        LD HL,(SUB_0752_40)              ; $4D66  2A 63 08
        LD A,H                           ; $4D69  7C
        OR L                             ; $4D6A  B5
        POP HL                           ; $4D6B  E1
        LD A,$07                         ; $4D6C  3E 07
        JR Z,SUB_4CA1_18                 ; $4D6E  28 11
        LD HL,SUB_0925_12                ; $4D70  21 31 0A
        CALL SUB_14FB                    ; $4D73  CD FB 14
        EX DE,HL                         ; $4D76  EB
        LD (SUB_0752_43),HL              ; $4D77  22 67 08
        JP SUB_124F_1                    ; $4D7A  C3 55 12
SUB_4CA1_17:
        LD A,C                           ; $4D7D  79
        LD (HL),C                        ; $4D7E  71
        INC HL                           ; $4D7F  23
        INC B                            ; $4D80  04
SUB_4CA1_18:
        CALL SUB_4291                    ; $4D81  CD 91 42
        SUB $0A                          ; $4D84  D6 0A
        JP NZ,SUB_4C87_1                 ; $4D86  C2 94 4C
        LD (SUB_0B2A_2),A                ; $4D89  32 34 0B
        LD A,$0D                         ; $4D8C  3E 0D
        CALL SUB_4291                    ; $4D8E  CD 91 42
SUB_4CA1_19:
        CALL SUB_43A2                    ; $4D91  CD A2 43
        OR A                             ; $4D94  B7
        JR Z,SUB_4CA1_19                 ; $4D95  28 FA
        CP $0D                           ; $4D97  FE 0D
        JP Z,SUB_4C87_1                  ; $4D99  CA 94 4C
        JP SUB_4CA1_9                    ; $4D9C  C3 F0 4C
SUB_4CA1_20:
        LD A,(L_0CB6)                    ; $4D9F  3A B6 0C
        OR A                             ; $4DA2  B7
        JP Z,SUB_43F9_1                  ; $4DA3  CA 01 44
        XOR A                            ; $4DA6  AF
        LD (HL),A                        ; $4DA7  77
        LD HL,SUB_0925_11                ; $4DA8  21 30 0A
        RET                              ; $4DAB  C9
SUB_4DAC:
        PUSH AF                          ; $4DAC  F5
        LD A,$00                         ; $4DAD  3E 00
        LD (L_0CB6),A                    ; $4DAF  32 B6 0C
        POP AF                           ; $4DB2  F1
        CP $3B                           ; $4DB3  FE 3B
        RET NZ                           ; $4DB5  C0
        LD (L_0CB6),A                    ; $4DB6  32 B6 0C
        JP SUB_13E4                      ; $4DB9  C3 E4 13
SUB_4DBC:
        LD A,(SUB_0B2A_2)                ; $4DBC  3A 34 0B
        LD (SUB_4E06_2),A                ; $4DBF  32 1B 4E
        RET                              ; $4DC2  C9
SUB_4DC3:
        DEC HL                           ; $4DC3  2B
        LD A,(HL)                        ; $4DC4  7E
        CP $0A                           ; $4DC5  FE 0A
        JR NZ,SUB_4DC3_4                 ; $4DC7  20 10
        PUSH BC                          ; $4DC9  C5
SUB_4DC3_1:
        DEC B                            ; $4DCA  05
        JR Z,SUB_4DC3_3                  ; $4DCB  28 0A
        LD HL,SUB_0925_12                ; $4DCD  21 31 0A
SUB_4DC3_2:
        LD A,(HL)                        ; $4DD0  7E
        CALL SUB_4291                    ; $4DD1  CD 91 42
        INC HL                           ; $4DD4  23
        DJNZ SUB_4DC3_2                  ; $4DD5  10 F9
SUB_4DC3_3:
        POP BC                           ; $4DD7  C1
        RET                              ; $4DD8  C9
SUB_4DC3_4:
        CP $09                           ; $4DD9  FE 09
        JR NZ,SUB_4DC3_9                 ; $4DDB  20 27
        PUSH HL                          ; $4DDD  E5
        PUSH BC                          ; $4DDE  C5
        PUSH DE                          ; $4DDF  D5
        LD D,$00                         ; $4DE0  16 00
SUB_4DC3_5:
        DEC HL                           ; $4DE2  2B
        LD A,(HL)                        ; $4DE3  7E
        CP $09                           ; $4DE4  FE 09
        JR Z,SUB_4DC3_7                  ; $4DE6  28 0F
        CP $0A                           ; $4DE8  FE 0A
        JR Z,SUB_4DC3_7                  ; $4DEA  28 0B
        DEC B                            ; $4DEC  05
        JR Z,SUB_4DC3_6                  ; $4DED  28 03
        INC D                            ; $4DEF  14
        JR SUB_4DC3_5                    ; $4DF0  18 F0
SUB_4DC3_6:
        LD A,(SUB_4E06_2)                ; $4DF2  3A 1B 4E
        ADD A,D                          ; $4DF5  82
        LD D,A                           ; $4DF6  57
SUB_4DC3_7:
        LD A,D                           ; $4DF7  7A
        AND $07                          ; $4DF8  E6 07
        CPL                              ; $4DFA  2F
        ADD A,$09                        ; $4DFB  C6 09
        CALL SUB_4E06                    ; $4DFD  CD 06 4E
SUB_4DC3_8:
        POP DE                           ; $4E00  D1
        POP BC                           ; $4E01  C1
        POP HL                           ; $4E02  E1
        RET                              ; $4E03  C9
SUB_4DC3_9:
        LD A,$01                         ; $4E04  3E 01
SUB_4E06:
        PUSH BC                          ; $4E06  C5
        LD B,A                           ; $4E07  47
SUB_4E06_1:
        LD A,$08                         ; $4E08  3E 08
        CALL SUB_4291                    ; $4E0A  CD 91 42
        LD A,$20                         ; $4E0D  3E 20
        CALL SUB_4291                    ; $4E0F  CD 91 42
        LD A,$08                         ; $4E12  3E 08
        CALL SUB_4291                    ; $4E14  CD 91 42
        DJNZ SUB_4E06_1                  ; $4E17  10 EF
        POP BC                           ; $4E19  C1
        RET                              ; $4E1A  C9
SUB_4E06_2:
        NOP                              ; $4E1B  00
        LD ($0B71),HL                    ; $4E1C  22 71 0B
        CALL SUB_24CD                    ; $4E1F  CD CD 24
        CALL SUB_13E4                    ; $4E22  CD E4 13
        EX DE,HL                         ; $4E25  EB
        CALL SUB_4E80                    ; $4E26  CD 80 4E
        INC SP                           ; $4E29  33
        INC SP                           ; $4E2A  33
        JR NZ,SUB_4E06_3                 ; $4E2B  20 05
        ADD HL,BC                        ; $4E2D  09
        LD SP,HL                         ; $4E2E  F9
        LD (SUB_0B2A_31),HL              ; $4E2F  22 81 0B
SUB_4E06_3:
        LD HL,(SUB_0752_43)              ; $4E32  2A 67 08
        PUSH HL                          ; $4E35  E5
        LD HL,($0B71)                    ; $4E36  2A 71 0B
        PUSH HL                          ; $4E39  E5
        PUSH DE                          ; $4E3A  D5
        JR SUB_4E06_4                    ; $4E3B  18 24
        DEFB    $C2                                              ; $4E3D
        DEFW    SUB_0D20_20              ; $4E3E
        DEFB    $EB,$CD                                          ; $4E40
        DEFW    SUB_4E80                 ; $4E42
        DEFB    $C2,$A8,$4E,$F9,$22                              ; $4E44
        DEFW    SUB_0B2A_31              ; $4E49
        DEFW    SUB_2AEB                 ; $4E4B
        DEFW    SUB_0752_43              ; $4E4D
        DEFB    $22                                              ; $4E4F
        DEFW    SUB_0C4B_11              ; $4E50
        DEFW    SUB_22E1_24              ; $4E52
        DEFB    $23                                              ; $4E54
        DEFW    SUB_22E1_15              ; $4E55
        DEFW    SUB_22E1_13              ; $4E57
        DEFB    $7E,$23,$66,$6F,$22                              ; $4E59
        DEFW    SUB_0752_43              ; $4E5E
        DEFB    $EB                                              ; $4E60
SUB_4E06_4:
        CALL SUB_1A8C_1+1                ; $4E61  CD 90 1A
        PUSH HL                          ; $4E64  E5
        CALL SUB_2B06                    ; $4E65  CD 06 2B
        POP HL                           ; $4E68  E1
        JR Z,SUB_4E06_5                  ; $4E69  28 09
        LD BC,$00AF                      ; $4E6B  01 AF 00
        LD B,C                           ; $4E6E  41
        PUSH BC                          ; $4E6F  C5
        INC SP                           ; $4E70  33
        JP SUB_129A_14                   ; $4E71  C3 86 13
SUB_4E06_5:
        LD HL,(SUB_0C4B_11)              ; $4E74  2A 94 0C
        LD (SUB_0752_43),HL              ; $4E77  22 67 08
        POP HL                           ; $4E7A  E1
        POP AF                           ; $4E7B  F1
        POP AF                           ; $4E7C  F1
        JP SUB_129A_14                   ; $4E7D  C3 86 13
SUB_4E80:
        LD HL,$0004                      ; $4E80  21 04 00
        ADD HL,SP                        ; $4E83  39
SUB_4E80_1:
        LD A,(HL)                        ; $4E84  7E
        INC HL                           ; $4E85  23
        LD BC,$0082                      ; $4E86  01 82 00
        CP C                             ; $4E89  B9
        JR NZ,SUB_4E80_2                 ; $4E8A  20 06
        LD BC,$0010                      ; $4E8C  01 10 00
        ADD HL,BC                        ; $4E8F  09
        JR SUB_4E80_1                    ; $4E90  18 F2
SUB_4E80_2:
        LD BC,$00AF                      ; $4E92  01 AF 00
        CP C                             ; $4E95  B9
        RET NZ                           ; $4E96  C0
        PUSH HL                          ; $4E97  E5
        LD C,(HL)                        ; $4E98  4E
        INC HL                           ; $4E99  23
        LD B,(HL)                        ; $4E9A  46
        LD H,B                           ; $4E9B  60
        LD L,C                           ; $4E9C  69
        CALL SUB_459D                    ; $4E9D  CD 9D 45
        POP HL                           ; $4EA0  E1
        LD BC,$0006                      ; $4EA1  01 06 00
        RET Z                            ; $4EA4  C8
        ADD HL,BC                        ; $4EA5  09
        JR SUB_4E80_1                    ; $4EA6  18 DC
        DEFW    SUB_1DE3_3               ; $4EA8
        DEFB    $00,$C3                                          ; $4EAA
        DEFW    SUB_0D20_28              ; $4EAC
        DEFB    $3E,$80,$32                                      ; $4EAE
        DEFW    SUB_0B2A_23              ; $4EB1
        DEFB    $7E,$FE,$25,$F5,$CC                              ; $4EB3
        DEFW    SUB_13E4                 ; $4EB8
        DEFB    $CD                                              ; $4EBA
        DEFW    SUB_3BB3                 ; $4EBB
        DEFB    $E3,$E5,$EB,$CD                                  ; $4EBD
        DEFW    SUB_1DE3                 ; $4EC1
        DEFB    $CD                                              ; $4EC3
        DEFW    SUB_2B6A                 ; $4EC4
        DEFB    $CD                                              ; $4EC6
        DEFW    SUB_2BF4                 ; $4EC7
        DEFB    $22                                              ; $4EC9
        DEFW    L_0CB6                   ; $4ECA
        DEFB    $F1,$CA                                          ; $4ECC
        DEFW    SUB_2602_11              ; $4ECE
        DEFB    $0E,$20,$CD                                      ; $4ED0
        DEFW    SUB_449F                 ; $4ED3
        DEFW    SUB_2124_22              ; $4ED5
        DEFB    $C0,$FF,$39,$F9                                  ; $4ED7
        DEFW    SUB_0D20_49              ; $4EDB
        DEFB    $20,$2B,$CD                                      ; $4EDD
        DEFW    SUB_13E4                 ; $4EE0
        DEFB    $22                                              ; $4EE2
        DEFW    SUB_0B2A_25              ; $4EE3
        DEFB    $28,$3B,$CD                                      ; $4EE5
        DEFW    SUB_45A3                 ; $4EE8
        DEFB    $28,$C5,$D5,$CD                                  ; $4EEA
        DEFW    SUB_3BB3                 ; $4EEE
        DEFB    $E3,$73,$23,$72,$23,$E3,$D1,$C1,$7E              ; $4EF0
        DEFW    SUB_2CF8_1               ; $4EF9
        DEFB    $20                                              ; $4EFB
        DEFW    SUB_0D04_1               ; $4EFC
        DEFB    $CD                                              ; $4EFE
        DEFW    SUB_13E4                 ; $4EFF
        DEFB    $18,$E8,$CD                                      ; $4F01
        DEFW    SUB_45A3                 ; $4F04
        DEFB    $29,$22                                          ; $4F06
        DEFW    SUB_0B2A_25              ; $4F08
        DEFW    SUB_2124_5               ; $4F0A
        DEFB    $91                                              ; $4F0C
        DEFW    SUB_3D4E_12              ; $4F0D
        DEFW    SUB_1128                 ; $4F0F
        DEFB    $D1                                              ; $4F11
        DEFW    SUB_2824_3               ; $4F12
        DEFB    $0D                                              ; $4F14
        DEFW    SUB_3D4E_8               ; $4F15
        DEFW    SUB_0925_1               ; $4F17
        DEFB    $C5,$E5                                          ; $4F19
        DEFW    SUB_0100_23              ; $4F1B
        DEFW    SUB_3809_15              ; $4F1D
        DEFW    SUB_4CA1_14              ; $4F1F
        DEFB    $E1,$E5                                          ; $4F21
        DEFW    SUB_2D04_2               ; $4F23
        DEFB    $4F,$E3,$E5,$2A                                  ; $4F25
        DEFW    L_0CB6                   ; $4F29
        DEFB    $E3                                              ; $4F2B
        DEFW    SUB_2AC5_1               ; $4F2C
        DEFW    SUB_0B2A_31              ; $4F2E
        DEFB    $F9,$2A                                          ; $4F30
        DEFW    SUB_0B2A_25              ; $4F32
        DEFB    $C3                                              ; $4F34
        DEFW    SUB_129A_14              ; $4F35
        DEFB    $AF,$32                                          ; $4F37
        DEFW    L_0CBD                   ; $4F39
        DEFB    $32                                              ; $4F3B
        DEFW    L_0CBE                   ; $4F3C
        DEFB    $7E,$11,$BE,$00                                  ; $4F3E
        DEFW    SUB_20B5_1               ; $4F42
        DEFW    SUB_3203_1               ; $4F44
        DEFW    L_0CBD                   ; $4F46
        DEFW    SUB_2B18_1               ; $4F48
        DEFB    $CD                                              ; $4F4A
        DEFW    SUB_13E4                 ; $4F4B
        DEFB    $CD,$F7,$53,$E5,$21,$00                          ; $4F4D  "MwSe!"
        DEFW    SUB_21FC_1               ; $4F53
        DEFW    L_0CC4                   ; $4F55
        DEFW    SUB_2BC4_3               ; $4F57
        DEFB    $CD                                              ; $4F59
        DEFW    SUB_13E4                 ; $4F5A
        DEFB    $CA,$C5,$4F,$CD                                  ; $4F5C
        DEFW    SUB_45A3                 ; $4F60
        DEFB    $2C                                              ; $4F62
        DEFW    SUB_2CF8_1               ; $4F63
        DEFW    SUB_1128                 ; $4F65
        DEFB    $CD                                              ; $4F67
        DEFW    SUB_1A8C_1+1             ; $4F68
        DEFB    $E5,$CD                                          ; $4F6A
        DEFW    SUB_22E1                 ; $4F6C
        DEFB    $22                                              ; $4F6E
        DEFW    L_0CC4                   ; $4F6F
        DEFW    SUB_2BC4_3               ; $4F71
        DEFB    $CD                                              ; $4F73
        DEFW    SUB_13E4                 ; $4F74
        DEFB    $28,$4D,$CD                                      ; $4F76
        DEFW    SUB_45A3                 ; $4F79
        DEFW    SUB_1128_2               ; $4F7B
        DEFB    $A6,$00                                          ; $4F7D
        DEFW    SUB_2874_13              ; $4F7F
        DEFB    $18,$CD                                          ; $4F81
        DEFW    SUB_45A3                 ; $4F83
        DEFB    $41,$CD                                          ; $4F85
        DEFW    SUB_45A3                 ; $4F87
        DEFB    $4C,$CD                                          ; $4F89
        DEFW    SUB_45A3                 ; $4F8B
        DEFB    $4C,$CA                                          ; $4F8D
        DEFW    SUB_50A6_7               ; $4F8F
        DEFB    $CD                                              ; $4F91
        DEFW    SUB_45A3                 ; $4F92
        DEFB    $2C,$BB,$C2                                      ; $4F94
        DEFW    SUB_0D20_20              ; $4F97
        DEFB    $B7,$F5,$32                                      ; $4F99
        DEFW    L_0CBE                   ; $4F9C
        DEFB    $CD                                              ; $4F9E
        DEFW    SUB_13E4                 ; $4F9F
        DEFB    $CD                                              ; $4FA1
        DEFW    SUB_0F84                 ; $4FA2
        DEFB    $C5,$CD                                          ; $4FA4
        DEFW    SUB_2426                 ; $4FA6
        DEFB    $C1,$D1,$C5,$60                                  ; $4FA8
        DEFW    SUB_21FC_11              ; $4FAC
        DEFW    L_0CC1                   ; $4FAE
        DEFB    $CD                                              ; $4FB0
        DEFW    SUB_0FAB                 ; $4FB1
        DEFW    SUB_0925_2               ; $4FB3
        DEFW    SUB_5D26_6               ; $4FB5
        DEFB    $22                                              ; $4FB7
        DEFW    L_0CBF                   ; $4FB8
        DEFB    $E1,$CD                                          ; $4FBA
        DEFW    SUB_459D                 ; $4FBC
        DEFB    $D2                                              ; $4FBE
        DEFW    SUB_14E4_2               ; $4FBF
        DEFB    $F1,$C2                                          ; $4FC1
        DEFW    SUB_50A6_7               ; $4FC3
        DEFB    $2A                                              ; $4FC5
        DEFW    SUB_0752_44              ; $4FC6
        DEFB    $2B                                              ; $4FC8
SUB_4E80_3:
        INC HL                           ; $4FC9  23
        LD A,(HL)                        ; $4FCA  7E
SUB_4E80_4:
        INC HL                           ; $4FCB  23
        OR (HL)                          ; $4FCC  B6
SUB_4E80_5:
        JP Z,SUB_503E_6                  ; $4FCD  CA 75 50
        INC HL                           ; $4FD0  23
        LD E,(HL)                        ; $4FD1  5E
        INC HL                           ; $4FD2  23
        LD D,(HL)                        ; $4FD3  56
        EX DE,HL                         ; $4FD4  EB
        LD (SUB_0752_43),HL              ; $4FD5  22 67 08
        EX DE,HL                         ; $4FD8  EB
SUB_4E80_6:
        CALL SUB_13E4                    ; $4FD9  CD E4 13
SUB_4E80_7:
        OR A                             ; $4FDC  B7
        JR Z,SUB_4E80_3                  ; $4FDD  28 EA
        CP $3A                           ; $4FDF  FE 3A
        JR Z,SUB_4E80_6                  ; $4FE1  28 F6
SUB_4E80_8:
        LD DE,$00B3                      ; $4FE3  11 B3 00
        CP E                             ; $4FE6  BB
        JR Z,SUB_4E80_9                  ; $4FE7  28 09
        CALL SUB_13E4                    ; $4FE9  CD E4 13
        CALL SUB_15CF                    ; $4FEC  CD CF 15
        DEC HL                           ; $4FEF  2B
        JR SUB_4E80_6                    ; $4FF0  18 E7
SUB_4E80_9:
        CALL SUB_13E4                    ; $4FF2  CD E4 13
        JR Z,SUB_4E80_7                  ; $4FF5  28 E5
SUB_4E80_10:
        PUSH HL                          ; $4FF7  E5
SUB_4E80_11:
        LD A,$01                         ; $4FF8  3E 01
        LD (SUB_0B2A_23),A               ; $4FFA  32 75 0B
        CALL SUB_3BB3                    ; $4FFD  CD B3 3B
        JR Z,SUB_503E_2                  ; $5000  28 48
        LD A,B                           ; $5002  78
        OR $80                           ; $5003  F6 80
        LD B,A                           ; $5005  47
        XOR A                            ; $5006  AF
        CALL SUB_3D4E_6+1                ; $5007  CD AB 3D
        LD A,$00                         ; $500A  3E 00
        LD (SUB_0B2A_23),A               ; $500C  32 75 0B
        JR NZ,SUB_5012_1                 ; $500F  20 08
        LD A,(HL)                        ; $5011  7E
SUB_5012:
        CP $28                           ; $5012  FE 28
        JR NZ,SUB_5012_2                 ; $5014  20 09
        POP AF                           ; $5016  F1
        JR SUB_503E_4                    ; $5017  18 4B
SUB_5012_1:
        LD A,(HL)                        ; $5019  7E
        CP $28                           ; $501A  FE 28
        JP Z,SUB_14E4_2                  ; $501C  CA EB 14
SUB_5012_2:
        POP HL                           ; $501F  E1
        CALL SUB_3BB3                    ; $5020  CD B3 3B
SUB_5012_3:
        LD A,D                           ; $5023  7A
        OR E                             ; $5024  B3
        JR NZ,SUB_5012_5                 ; $5025  20 10
        LD A,B                           ; $5027  78
        OR $80                           ; $5028  F6 80
        LD B,A                           ; $502A  47
        LD A,(SUB_0B2A_5)                ; $502B  3A 37 0B
        LD D,A                           ; $502E  57
        CALL SUB_3C47                    ; $502F  CD 47 3C
SUB_5012_4:
        LD A,D                           ; $5032  7A
        OR E                             ; $5033  B3
        JP Z,SUB_14E4_2                  ; $5034  CA EB 14
SUB_5012_5:
        PUSH HL                          ; $5037  E5
        LD B,D                           ; $5038  42
        LD C,E                           ; $5039  4B
        LD HL,SUB_503E_3                 ; $503A  21 58 50
        PUSH HL                          ; $503D  E5
SUB_503E:
        DEC BC                           ; $503E  0B
SUB_503E_1:
        LD A,(BC)                        ; $503F  0A
        DEC BC                           ; $5040  0B
        OR A                             ; $5041  B7
        JP M,SUB_503E_1                  ; $5042  FA 3F 50
        LD A,(BC)                        ; $5045  0A
        OR $80                           ; $5046  F6 80
        LD (BC),A                        ; $5048  02
        RET                              ; $5049  C9
SUB_503E_2:
        LD (SUB_0B2A_23),A               ; $504A  32 75 0B
        LD A,(HL)                        ; $504D  7E
        CP $28                           ; $504E  FE 28
        JR NZ,SUB_5012_2                 ; $5050  20 CD
        EX (SP),HL                       ; $5052  E3
        DEC BC                           ; $5053  0B
        DEC BC                           ; $5054  0B
        CALL SUB_503E                    ; $5055  CD 3E 50
SUB_503E_3:
        POP HL                           ; $5058  E1
        DEC HL                           ; $5059  2B
        CALL SUB_13E4                    ; $505A  CD E4 13
        JP Z,SUB_4E80_7                  ; $505D  CA DC 4F
        CP $28                           ; $5060  FE 28
        JR NZ,SUB_503E_5                 ; $5062  20 0A
SUB_503E_4:
        CALL SUB_13E4                    ; $5064  CD E4 13
        CALL SUB_45A3                    ; $5067  CD A3 45
        ADD HL,HL                        ; $506A  29
        JP Z,SUB_4E80_7                  ; $506B  CA DC 4F
SUB_503E_5:
        CALL SUB_45A3                    ; $506E  CD A3 45
        INC L                            ; $5071  2C
        JP SUB_4E80_10                   ; $5072  C3 F7 4F
SUB_503E_6:
        LD HL,(SUB_0B2A_41)              ; $5075  2A 94 0B
        EX DE,HL                         ; $5078  EB
        LD HL,(SUB_0B2A_40)              ; $5079  2A 92 0B
SUB_503E_7:
        CALL SUB_459D                    ; $507C  CD 9D 45
SUB_503E_8:
        JR Z,SUB_50A6_2                  ; $507F  28 40
        PUSH HL                          ; $5081  E5
        LD C,(HL)                        ; $5082  4E
        INC HL                           ; $5083  23
        INC HL                           ; $5084  23
        LD A,(HL)                        ; $5085  7E
        OR A                             ; $5086  B7
        PUSH AF                          ; $5087  F5
        AND $7F                          ; $5088  E6 7F
        LD (HL),A                        ; $508A  77
        INC HL                           ; $508B  23
        CALL SUB_3EA3                    ; $508C  CD A3 3E
        LD B,$00                         ; $508F  06 00
        ADD HL,BC                        ; $5091  09
        POP AF                           ; $5092  F1
        POP BC                           ; $5093  C1
        JP M,SUB_503E_7                  ; $5094  FA 7C 50
        PUSH BC                          ; $5097  C5
        CALL SUB_50A6                    ; $5098  CD A6 50
        LD HL,(SUB_0B2A_41)              ; $509B  2A 94 0B
        ADD HL,DE                        ; $509E  19
        LD (SUB_0B2A_41),HL              ; $509F  22 94 0B
        EX DE,HL                         ; $50A2  EB
        POP HL                           ; $50A3  E1
        JR SUB_503E_7                    ; $50A4  18 D6
SUB_50A6:
        EX DE,HL                         ; $50A6  EB
        LD HL,(SUB_0B2A_42)              ; $50A7  2A 96 0B
SUB_50A6_1:
        CALL SUB_459D                    ; $50AA  CD 9D 45
        LD A,(DE)                        ; $50AD  1A
        LD (BC),A                        ; $50AE  02
        INC DE                           ; $50AF  13
        INC BC                           ; $50B0  03
        JR NZ,SUB_50A6_1                 ; $50B1  20 F7
        LD A,C                           ; $50B3  79
        SUB L                            ; $50B4  95
        LD E,A                           ; $50B5  5F
        LD A,B                           ; $50B6  78
        SBC A,H                          ; $50B7  9C
        LD D,A                           ; $50B8  57
        DEC DE                           ; $50B9  1B
        DEC BC                           ; $50BA  0B
        LD H,B                           ; $50BB  60
        LD L,C                           ; $50BC  69
        LD (SUB_0B2A_42),HL              ; $50BD  22 96 0B
        RET                              ; $50C0  C9
SUB_50A6_2:
        LD HL,(SUB_0B2A_42)              ; $50C1  2A 96 0B
SUB_50A6_3:
        EX DE,HL                         ; $50C4  EB
SUB_50A6_4:
        CALL SUB_459D                    ; $50C5  CD 9D 45
        JR Z,SUB_50A6_7                  ; $50C8  28 1F
        PUSH HL                          ; $50CA  E5
        INC HL                           ; $50CB  23
        INC HL                           ; $50CC  23
        LD A,(HL)                        ; $50CD  7E
        OR A                             ; $50CE  B7
        PUSH AF                          ; $50CF  F5
        AND $7F                          ; $50D0  E6 7F
        LD (HL),A                        ; $50D2  77
SUB_50A6_5:
        INC HL                           ; $50D3  23
        CALL SUB_3EA3                    ; $50D4  CD A3 3E
        LD C,(HL)                        ; $50D7  4E
        INC HL                           ; $50D8  23
        LD B,(HL)                        ; $50D9  46
        INC HL                           ; $50DA  23
        ADD HL,BC                        ; $50DB  09
        POP AF                           ; $50DC  F1
        POP BC                           ; $50DD  C1
        JP M,SUB_50A6_4                  ; $50DE  FA C5 50
        PUSH BC                          ; $50E1  C5
        CALL SUB_50A6                    ; $50E2  CD A6 50
        EX DE,HL                         ; $50E5  EB
        POP HL                           ; $50E6  E1
SUB_50A6_6:
        JR SUB_50A6_4                    ; $50E7  18 DC
SUB_50A6_7:
        LD HL,(SUB_0B2A_40)              ; $50E9  2A 92 0B
SUB_50A6_8:
        EX DE,HL                         ; $50EC  EB
        LD HL,(SUB_0B2A_41)              ; $50ED  2A 94 0B
        EX DE,HL                         ; $50F0  EB
        CALL SUB_459D                    ; $50F1  CD 9D 45
        JR Z,SUB_50A6_12                 ; $50F4  28 18
        LD A,(HL)                        ; $50F6  7E
        INC HL                           ; $50F7  23
        INC HL                           ; $50F8  23
        INC HL                           ; $50F9  23
        PUSH AF                          ; $50FA  F5
        CALL SUB_3EA3                    ; $50FB  CD A3 3E
SUB_50A6_9:
        POP AF                           ; $50FE  F1
        CP $03                           ; $50FF  FE 03
        JR NZ,SUB_50A6_10                ; $5101  20 04
        CALL SUB_5143                    ; $5103  CD 43 51
        XOR A                            ; $5106  AF
SUB_50A6_10:
        LD E,A                           ; $5107  5F
        LD D,$00                         ; $5108  16 00
        ADD HL,DE                        ; $510A  19
        JR SUB_50A6_8                    ; $510B  18 DF
SUB_50A6_11:
        POP BC                           ; $510D  C1
SUB_50A6_12:
        EX DE,HL                         ; $510E  EB
        LD HL,(SUB_0B2A_42)              ; $510F  2A 96 0B
        EX DE,HL                         ; $5112  EB
        CALL SUB_459D                    ; $5113  CD 9D 45
        JR Z,SUB_5143_1                  ; $5116  28 55
        LD A,(HL)                        ; $5118  7E
        INC HL                           ; $5119  23
        INC HL                           ; $511A  23
        PUSH AF                          ; $511B  F5
        INC HL                           ; $511C  23
        CALL SUB_3EA3                    ; $511D  CD A3 3E
        LD C,(HL)                        ; $5120  4E
        INC HL                           ; $5121  23
        LD B,(HL)                        ; $5122  46
        INC HL                           ; $5123  23
        POP AF                           ; $5124  F1
        PUSH HL                          ; $5125  E5
        ADD HL,BC                        ; $5126  09
        CP $03                           ; $5127  FE 03
        JR NZ,SUB_50A6_11                ; $5129  20 E2
        LD (SUB_0B2A_20),HL              ; $512B  22 6D 0B
        POP HL                           ; $512E  E1
        LD C,(HL)                        ; $512F  4E
        LD B,$00                         ; $5130  06 00
        ADD HL,BC                        ; $5132  09
        ADD HL,BC                        ; $5133  09
        INC HL                           ; $5134  23
SUB_50A6_13:
        EX DE,HL                         ; $5135  EB
        LD HL,(SUB_0B2A_20)              ; $5136  2A 6D 0B
        EX DE,HL                         ; $5139  EB
        CALL SUB_459D                    ; $513A  CD 9D 45
        JR Z,SUB_50A6_12                 ; $513D  28 CF
        LD BC,SUB_50A6_13                ; $513F  01 35 51
        PUSH BC                          ; $5142  C5
SUB_5143:
        XOR A                            ; $5143  AF
        OR (HL)                          ; $5144  B6
        INC HL                           ; $5145  23
        LD E,(HL)                        ; $5146  5E
        INC HL                           ; $5147  23
        LD D,(HL)                        ; $5148  56
        INC HL                           ; $5149  23
        RET Z                            ; $514A  C8
        PUSH HL                          ; $514B  E5
        LD HL,(SUB_0B2A_40)              ; $514C  2A 92 0B
        CALL SUB_459D                    ; $514F  CD 9D 45
        POP HL                           ; $5152  E1
        RET C                            ; $5153  D8
        PUSH HL                          ; $5154  E5
        LD HL,(SUB_0752_44)              ; $5155  2A 69 08
        CALL SUB_459D                    ; $5158  CD 9D 45
        POP HL                           ; $515B  E1
        RET NC                           ; $515C  D0
        PUSH HL                          ; $515D  E5
        DEC HL                           ; $515E  2B
        DEC HL                           ; $515F  2B
        DEC HL                           ; $5160  2B
        PUSH HL                          ; $5161  E5
        CALL SUB_4844                    ; $5162  CD 44 48
        POP HL                           ; $5165  E1
        LD B,$03                         ; $5166  06 03
        CALL SUB_2B4B                    ; $5168  CD 4B 2B
        POP HL                           ; $516B  E1
        RET                              ; $516C  C9
SUB_5143_1:
        CALL SUB_4900                    ; $516D  CD 00 49
        LD HL,(SUB_0B2A_42)              ; $5170  2A 96 0B
        LD B,H                           ; $5173  44
        LD C,L                           ; $5174  4D
        LD HL,(SUB_0B2A_40)              ; $5175  2A 92 0B
        EX DE,HL                         ; $5178  EB
        LD HL,(SUB_0B2A_41)              ; $5179  2A 94 0B
        LD A,L                           ; $517C  7D
        SUB E                            ; $517D  93
        LD L,A                           ; $517E  6F
        LD A,H                           ; $517F  7C
        SBC A,D                          ; $5180  9A
SUB_5143_2:
        LD H,A                           ; $5181  67
        LD (SUB_0C4B_5),HL               ; $5182  22 88 0C
        LD HL,(SUB_0B2A_19)              ; $5185  2A 6B 0B
        LD (L_0CB8),HL                   ; $5188  22 B8 0C
        CALL SUB_4492                    ; $518B  CD 92 44
        LD H,B                           ; $518E  60
        LD L,C                           ; $518F  69
        DEC HL                           ; $5190  2B
        LD (SUB_0B2A_19),HL              ; $5191  22 6B 0B
        LD A,(L_0CBE)                    ; $5194  3A BE 0C
        OR A                             ; $5197  B7
        JR Z,SUB_5143_3                  ; $5198  28 0E
        LD HL,(L_0CC1)                   ; $519A  2A C1 0C
        LD B,H                           ; $519D  44
        LD C,L                           ; $519E  4D
        LD HL,(L_0CBF)                   ; $519F  2A BF 0C
        CALL SUB_22AF                    ; $51A2  CD AF 22
        CALL SUB_0F5C                    ; $51A5  CD 5C 0F
SUB_5143_3:
        LD A,$01                         ; $51A8  3E 01
        LD (L_0CC3),A                    ; $51AA  32 C3 0C
        LD A,(L_0CBD)                    ; $51AD  3A BD 0C
        OR A                             ; $51B0  B7
        JP NZ,SUB_5498_3                 ; $51B1  C2 B7 54
        LD A,(SUB_0752_55)               ; $51B4  3A 93 08
        LD (SUB_0752_47),A               ; $51B7  32 6E 08
        JP SUB_53F7_3                    ; $51BA  C3 1B 54
SUB_5143_4:
        XOR A                            ; $51BD  AF
        LD (L_0CC3),A                    ; $51BE  32 C3 0C
        LD (L_0CBD),A                    ; $51C1  32 BD 0C
        LD HL,(SUB_0B2A_40)              ; $51C4  2A 92 0B
        LD B,H                           ; $51C7  44
        LD C,L                           ; $51C8  4D
        LD HL,(SUB_0C4B_5)               ; $51C9  2A 88 0C
        ADD HL,BC                        ; $51CC  09
        LD (SUB_0B2A_41),HL              ; $51CD  22 94 0B
        LD HL,(SUB_0B2A_19)              ; $51D0  2A 6B 0B
        INC HL                           ; $51D3  23
        EX DE,HL                         ; $51D4  EB
        LD HL,(L_0CB8)                   ; $51D5  2A B8 0C
        LD (SUB_0B2A_19),HL              ; $51D8  22 6B 0B
SUB_5143_5:
        CALL SUB_459D                    ; $51DB  CD 9D 45
        LD A,(DE)                        ; $51DE  1A
        LD (BC),A                        ; $51DF  02
        INC DE                           ; $51E0  13
        INC BC                           ; $51E1  03
        JR NZ,SUB_5143_5                 ; $51E2  20 F7
        DEC BC                           ; $51E4  0B
        LD H,B                           ; $51E5  60
        LD L,C                           ; $51E6  69
        LD (SUB_0B2A_42),HL              ; $51E7  22 96 0B
        LD HL,(L_0CC4)                   ; $51EA  2A C4 0C
        LD A,H                           ; $51ED  7C
        OR L                             ; $51EE  B5
        EX DE,HL                         ; $51EF  EB
        LD HL,(SUB_0752_44)              ; $51F0  2A 69 08
        DEC HL                           ; $51F3  2B
        JP Z,SUB_129A_14                 ; $51F4  CA 86 13
        CALL SUB_0FAB                    ; $51F7  CD AB 0F
        JP NC,SUB_1506_9                 ; $51FA  D2 91 15
        DEC BC                           ; $51FD  0B
        LD H,B                           ; $51FE  60
        LD L,C                           ; $51FF  69
        JP SUB_129A_14                   ; $5200  C3 86 13
        DEFB    $C3                                              ; $5203
        DEFW    SUB_15CF                 ; $5204
        DEFW    SUB_0100_21              ; $5206
        DEFB    $CD                                              ; $5208
        DEFW    SUB_528B_1               ; $5209
        DEFB    $2B,$CD                                          ; $520B
        DEFW    SUB_13E4                 ; $520D
        DEFB    $28,$4D                                          ; $520F
SUB_5143_6:
        CALL SUB_1A8C_1+1                ; $5211  CD 90 1A
        PUSH HL                          ; $5214  E5
        CALL SUB_1DE3                    ; $5215  CD E3 1D
        JR Z,SUB_5226_6                  ; $5218  28 35
        CALL SUB_33A0                    ; $521A  CD A0 33
        CALL SUB_4868                    ; $521D  CD 68 48
        LD HL,(SUB_0C98_4)               ; $5220  2A D4 0C
        INC HL                           ; $5223  23
        LD E,(HL)                        ; $5224  5E
        INC HL                           ; $5225  23
SUB_5226:
        LD D,(HL)                        ; $5226  56
        LD A,(DE)                        ; $5227  1A
        CP $20                           ; $5228  FE 20
        JR NZ,SUB_5226_1                 ; $522A  20 06
        INC DE                           ; $522C  13
        LD (HL),D                        ; $522D  72
        DEC HL                           ; $522E  2B
        LD (HL),E                        ; $522F  73
        DEC HL                           ; $5230  2B
        DEC (HL)                         ; $5231  35
SUB_5226_1:
        CALL SUB_48C1                    ; $5232  CD C1 48
SUB_5226_2:
        POP HL                           ; $5235  E1
        DEC HL                           ; $5236  2B
        CALL SUB_13E4                    ; $5237  CD E4 13
        JR Z,SUB_5226_8                  ; $523A  28 22
        CP $3B                           ; $523C  FE 3B
        JR Z,SUB_5226_4                  ; $523E  28 05
        CALL SUB_45A3                    ; $5240  CD A3 45
SUB_5226_3:
        INC L                            ; $5243  2C
        DEC HL                           ; $5244  2B
SUB_5226_4:
        CALL SUB_13E4                    ; $5245  CD E4 13
SUB_5226_5:
        LD A,$2C                         ; $5248  3E 2C
        CALL SUB_4291                    ; $524A  CD 91 42
        JR SUB_5143_6                    ; $524D  18 C2
SUB_5226_6:
        LD A,$22                         ; $524F  3E 22
        CALL SUB_4291                    ; $5251  CD 91 42
SUB_5226_7:
        CALL SUB_48C1                    ; $5254  CD C1 48
        LD A,$22                         ; $5257  3E 22
        CALL SUB_4291                    ; $5259  CD 91 42
        JR SUB_5226_2                    ; $525C  18 D7
SUB_5226_8:
        PUSH HL                          ; $525E  E5
        LD HL,(SUB_0752_40)              ; $525F  2A 63 08
        LD A,H                           ; $5262  7C
        OR L                             ; $5263  B5
        JR Z,SUB_5226_10                 ; $5264  28 1E
        LD A,(HL)                        ; $5266  7E
        CP $03                           ; $5267  FE 03
        JR NZ,SUB_5226_10                ; $5269  20 19
        CALL SUB_5D8E                    ; $526B  CD 8E 5D
        LD A,L                           ; $526E  7D
        SUB E                            ; $526F  93
        LD L,A                           ; $5270  6F
        LD A,H                           ; $5271  7C
        SBC A,D                          ; $5272  9A
        LD H,A                           ; $5273  67
        LD DE,$FFFE                      ; $5274  11 FE FF
        ADD HL,DE                        ; $5277  19
        JR NC,SUB_5226_10                ; $5278  30 0A
SUB_5226_9:
        LD A,$20                         ; $527A  3E 20
        CALL SUB_4291                    ; $527C  CD 91 42
        DEC HL                           ; $527F  2B
        LD A,H                           ; $5280  7C
        OR L                             ; $5281  B5
        JR NZ,SUB_5226_9                 ; $5282  20 F6
SUB_5226_10:
        POP HL                           ; $5284  E1
        CALL SUB_4406                    ; $5285  CD 06 44
        JP SUB_189A                      ; $5288  C3 9A 18
SUB_528B:
        LD C,$01                         ; $528B  0E 01
SUB_528B_1:
        CP $23                           ; $528D  FE 23
        RET NZ                           ; $528F  C0
        PUSH BC                          ; $5290  C5
        CALL SUB_52A9                    ; $5291  CD A9 52
        POP DE                           ; $5294  D1
        CP E                             ; $5295  BB
        JR Z,SUB_528B_2                  ; $5296  28 05
        CP $03                           ; $5298  FE 03
        JP NZ,SUB_0D20_10+1              ; $529A  C2 6A 0D
SUB_528B_2:
        CALL SUB_45A3                    ; $529D  CD A3 45
        INC L                            ; $52A0  2C
SUB_52A1:
        EX DE,HL                         ; $52A1  EB
        LD H,B                           ; $52A2  60
SUB_52A1_1:
        LD L,C                           ; $52A3  69
SUB_52A1_2:
        LD (SUB_0752_40),HL              ; $52A4  22 63 08
        EX DE,HL                         ; $52A7  EB
        RET                              ; $52A8  C9
SUB_52A9:
        DEC HL                           ; $52A9  2B
        CALL SUB_13E4                    ; $52AA  CD E4 13
        CP $23                           ; $52AD  FE 23
        CALL Z,SUB_13E4                  ; $52AF  CC E4 13
        CALL SUB_1A8C_1+1                ; $52B2  CD 90 1A
SUB_52B5:
        CALL SUB_20B5                    ; $52B5  CD B5 20
SUB_52B8:
        LD E,A                           ; $52B8  5F
SUB_52B9:
        LD A,(SUB_0752_55)               ; $52B9  3A 93 08
        CP E                             ; $52BC  BB
        JP C,SUB_0D20_12+1               ; $52BD  DA 70 0D
        LD D,$00                         ; $52C0  16 00
        PUSH HL                          ; $52C2  E5
        LD HL,SUB_0752_51                ; $52C3  21 73 08
        ADD HL,DE                        ; $52C6  19
        ADD HL,DE                        ; $52C7  19
        LD C,(HL)                        ; $52C8  4E
        INC HL                           ; $52C9  23
        LD B,(HL)                        ; $52CA  46
        LD A,(BC)                        ; $52CB  0A
        OR A                             ; $52CC  B7
        POP HL                           ; $52CD  E1
        RET                              ; $52CE  C9
SUB_52CF:
        CALL SUB_52B9                    ; $52CF  CD B9 52
        LD HL,$0029                      ; $52D2  21 29 00
        CP $03                           ; $52D5  FE 03
        JR NZ,SUB_52CF_1                 ; $52D7  20 03
        LD HL,$00B2                      ; $52D9  21 B2 00
SUB_52CF_1:
        ADD HL,BC                        ; $52DC  09
        EX DE,HL                         ; $52DD  EB
        RET                              ; $52DE  C9
        DEFW    SUB_0100_26              ; $52DF
        DEFW    SUB_3D4E_16              ; $52E1
        DEFB    $04                                              ; $52E3
        DEFW    SUB_3D4E_16              ; $52E4
        DEFB    $08,$F5                                          ; $52E6
        DEFW    SUB_1A93_5               ; $52E8
        DEFB    $20,$F1,$CD                                      ; $52EA
        DEFW    SUB_485A                 ; $52ED
        DEFB    $2A                                              ; $52EF
        DEFW    SUB_0B2A_18              ; $52F0
        DEFB    $CD,$72,$2B,$C3,$8D                              ; $52F2  "Mr+C"
        DEFB    $4A                                              ; $52F7
        DEFW    SUB_0100_11              ; $52F8
        DEFW    SUB_3D4E_16              ; $52FA
        DEFW    SUB_0100_1               ; $52FC
        DEFW    SUB_064E_18              ; $52FE
        DEFB    $F5                                              ; $5300
        DEFW    SUB_3777_4               ; $5301
        DEFB    $4A,$F1,$BE,$D2                                  ; $5303
        DEFW    SUB_14E4_2               ; $5307
        DEFW    SUB_22E1_10              ; $5309
        DEFW    SUB_22E1_12              ; $530B
        DEFB    $66,$69,$32                                      ; $530D
        DEFW    SUB_0B2A_5               ; $5310
        DEFB    $C3                                              ; $5312
        DEFW    SUB_2B6A                 ; $5313
        DEFB    $CD                                              ; $5315
        DEFW    SUB_1DE3                 ; $5316
        DEFW    SUB_1E72_21              ; $5318
        DEFW    SUB_101B_9               ; $531A
        DEFW    SUB_2BF4_3               ; $531C
        DEFB    $20                                              ; $531E
        DEFW    SUB_58FE_12              ; $531F
        DEFW    SUB_1402_2               ; $5321
SUB_52CF_2:
        CALL SUB_528B                    ; $5323  CD 8B 52
        CALL SUB_3BB3                    ; $5326  CD B3 3B
        CALL SUB_2CB3                    ; $5329  CD B3 2C
        LD BC,SUB_189A                   ; $532C  01 9A 18
        PUSH BC                          ; $532F  C5
        PUSH DE                          ; $5330  D5
        LD BC,SUB_15CF_4                 ; $5331  01 F1 15
        XOR A                            ; $5334  AF
        LD D,A                           ; $5335  57
        LD E,A                           ; $5336  5F
        PUSH AF                          ; $5337  F5
        PUSH BC                          ; $5338  C5
        PUSH HL                          ; $5339  E5
SUB_52CF_3:
        CALL SUB_5889                    ; $533A  CD 89 58
        JP C,SUB_0D20_13+1               ; $533D  DA 76 0D
        CP $20                           ; $5340  FE 20
        JR NZ,SUB_52CF_5                 ; $5342  20 04
        INC D                            ; $5344  14
        DEC D                            ; $5345  15
SUB_52CF_4:
        JR NZ,SUB_52CF_3                 ; $5346  20 F2
SUB_52CF_5:
        CP $22                           ; $5348  FE 22
        JR NZ,SUB_52CF_8                 ; $534A  20 0E
SUB_52CF_6:
        LD B,A                           ; $534C  47
        LD A,E                           ; $534D  7B
SUB_52CF_7:
        CP $2C                           ; $534E  FE 2C
        LD A,B                           ; $5350  78
        JR NZ,SUB_52CF_8                 ; $5351  20 07
        LD D,B                           ; $5353  50
        LD E,B                           ; $5354  58
        CALL SUB_5889                    ; $5355  CD 89 58
        JR C,SUB_52CF_9                  ; $5358  38 43
SUB_52CF_8:
        LD HL,SUB_0925_12                ; $535A  21 31 0A
        LD B,$FF                         ; $535D  06 FF
        DEFB    $4F,$7A,$FE,$22,$79,$28,$26,$FE,$0D              ; $535F  "Oz~"y(&~"
        DEFW    SUB_28E1_1               ; $5368
        DEFB    $4D,$E1                                          ; $536A
        DEFW    SUB_0925_18              ; $536C
        DEFW    SUB_1C11_2               ; $536E
        DEFB    $4F,$7B                                          ; $5370
        DEFW    SUB_2CF8_1               ; $5372
        DEFB    $79,$C4,$EE,$53,$CD                              ; $5374
        DEFW    SUB_5889                 ; $5379
        DEFB    $38,$20,$FE,$0D                                  ; $537B
        DEFW    SUB_0925_21              ; $537F
        DEFB    $7B,$FE,$20                                      ; $5381
        DEFW    SUB_1128_27              ; $5384
        DEFW    SUB_2CF8_1               ; $5386
        DEFB    $3E                                              ; $5388
        DEFW    SUB_2803_1               ; $5389
        DEFB    $0C                                              ; $538B
        DEFW    SUB_2874_11              ; $538C
        DEFB    $09                                              ; $538E
        DEFW    SUB_2874_12              ; $538F
        DEFB    $0B                                              ; $5391
        DEFW    SUB_2874_13              ; $5392
        DEFB    $08,$CD,$EE,$53,$CD                              ; $5394
        DEFW    SUB_5889                 ; $5399
        DEFB    $30,$C2                                          ; $539B
SUB_52CF_9:
        PUSH HL                          ; $539D  E5
        CP $22                           ; $539E  FE 22
        JR Z,SUB_52CF_10                 ; $53A0  28 04
        CP $20                           ; $53A2  FE 20
        JR NZ,SUB_52CF_11                ; $53A4  20 23
SUB_52CF_10:
        CALL SUB_5889                    ; $53A6  CD 89 58
        JR C,SUB_52CF_11                 ; $53A9  38 1E
        DEFB    $FE,$20,$28,$F7,$FE,$2C,$CA,$C9,$53,$FE,$0D      ; $53AB  "~ (w~,JIS~"
        DEFW    SUB_0752_72              ; $53B6
        DEFB    $CD                                              ; $53B8
        DEFW    SUB_5889                 ; $53B9
        DEFW    SUB_0C03_5               ; $53BB
        DEFW    SUB_0925_18              ; $53BD
        DEFW    SUB_0752_24              ; $53BF
        DEFB    $2A                                              ; $53C1
        DEFW    SUB_0752_40              ; $53C2
        DEFW    L_2801                   ; $53C4
        DEFW    SUB_0752_70              ; $53C6
        DEFB    $34                                              ; $53C8
SUB_52CF_11:
        POP HL                           ; $53C9  E1
        LD (HL),$00                      ; $53CA  36 00
        LD HL,SUB_0925_11                ; $53CC  21 30 0A
        LD A,E                           ; $53CF  7B
        SUB $20                          ; $53D0  D6 20
        JR Z,SUB_52CF_12                 ; $53D2  28 08
        LD B,D                           ; $53D4  42
        LD D,$00                         ; $53D5  16 00
        CALL SUB_486C                    ; $53D7  CD 6C 48
        POP HL                           ; $53DA  E1
        RET                              ; $53DB  C9
SUB_52CF_12:
        CALL SUB_1DE3                    ; $53DC  CD E3 1D
        PUSH AF                          ; $53DF  F5
        CALL SUB_13E4                    ; $53E0  CD E4 13
        POP AF                           ; $53E3  F1
        PUSH AF                          ; $53E4  F5
        CALL C,SUB_311E_1+1              ; $53E5  DC 25 31
        POP AF                           ; $53E8  F1
        CALL NC,SUB_311E                 ; $53E9  D4 1E 31
        POP HL                           ; $53EC  E1
        RET                              ; $53ED  C9
        DEFB    $B7,$C8,$77,$23,$05,$C0                          ; $53EE
        DEFW    SUB_189A_4               ; $53F4
        DEFB    $D3                                              ; $53F6
SUB_53F7:
        LD D,$01                         ; $53F7  16 01
SUB_53F7_1:
        XOR A                            ; $53F9  AF
        JP SUB_58FE_8                    ; $53FA  C3 B3 59
SUB_53F7_2:
        OR $AF                           ; $53FD  F6 AF
        PUSH AF                          ; $53FF  F5
        CALL SUB_53F7                    ; $5400  CD F7 53
        LD A,(SUB_0752_55)               ; $5403  3A 93 08
        LD (SUB_0752_47),A               ; $5406  32 6E 08
        DEC HL                           ; $5409  2B
        CALL SUB_13E4                    ; $540A  CD E4 13
        JR Z,SUB_53F7_4+1                ; $540D  28 11
        CALL SUB_45A3                    ; $540F  CD A3 45
        INC L                            ; $5412  2C
        CALL SUB_45A3                    ; $5413  CD A3 45
        LD D,D                           ; $5416  52
        JP NZ,SUB_0D20_20                ; $5417  C2 92 0D
        POP AF                           ; $541A  F1
SUB_53F7_3:
        XOR A                            ; $541B  AF
        LD (SUB_0752_55),A               ; $541C  32 93 08
SUB_53F7_4:
        OR $F1                           ; $541F  F6 F1
        LD (SUB_0752_46),A               ; $5421  32 6D 08
        LD HL,$0080                      ; $5424  21 80 00
        LD (HL),$00                      ; $5427  36 00
        LD (SUB_0752_51),HL              ; $5429  22 73 08
        CALL SUB_44F5                    ; $542C  CD F5 44
        LD A,(SUB_0752_47)               ; $542F  3A 6E 08
        LD (SUB_0752_55),A               ; $5432  32 93 08
        LD HL,(SUB_0752_49)              ; $5435  2A 71 08
        LD (SUB_0752_51),HL              ; $5438  22 73 08
        LD (SUB_0752_40),HL              ; $543B  22 63 08
        LD HL,(SUB_0752_43)              ; $543E  2A 67 08
SUB_53F7_5:
        INC HL                           ; $5441  23
        LD A,H                           ; $5442  7C
        AND L                            ; $5443  A5
SUB_53F7_6:
        INC A                            ; $5444  3C
        JR NZ,SUB_53F7_7                 ; $5445  20 03
        LD (SUB_0752_43),HL              ; $5447  22 67 08
SUB_53F7_7:
        CALL SUB_5889                    ; $544A  CD 89 58
        JP C,SUB_0D20_41                 ; $544D  DA 61 0E
        CP $FE                           ; $5450  FE FE
        JR NZ,SUB_53F7_8                 ; $5452  20 05
        LD (L_0CBC),A                    ; $5454  32 BC 0C
        JR SUB_53F7_9                    ; $5457  18 04
SUB_53F7_8:
        INC A                            ; $5459  3C
        JP NZ,SUB_5498_4                 ; $545A  C2 C5 54
SUB_53F7_9:
        LD HL,(SUB_0752_44)              ; $545D  2A 69 08
        CALL SUB_5B70                    ; $5460  CD 70 5B
        LD (SUB_0B2A_40),HL              ; $5463  22 92 0B
        LD A,(L_0CBC)                    ; $5466  3A BC 0C
        OR A                             ; $5469  B7
        CALL NZ,SUB_5DEB                 ; $546A  C4 EB 5D
        CALL SUB_0F5C                    ; $546D  CD 5C 0F
        INC HL                           ; $5470  23
        INC HL                           ; $5471  23
        LD (SUB_0B2A_40),HL              ; $5472  22 92 0B
        LD HL,SUB_0752_55                ; $5475  21 93 08
        LD A,(HL)                        ; $5478  7E
        LD (SUB_0752_47),A               ; $5479  32 6E 08
        LD (HL),$00                      ; $547C  36 00
        CALL SUB_450B                    ; $547E  CD 0B 45
        LD A,(SUB_0752_47)               ; $5481  3A 6E 08
        LD (SUB_0752_55),A               ; $5484  32 93 08
        LD A,(L_0CC3)                    ; $5487  3A C3 0C
        OR A                             ; $548A  B7
        JP NZ,SUB_5143_4                 ; $548B  C2 BD 51
        LD A,(SUB_0752_46)               ; $548E  3A 6D 08
        OR A                             ; $5491  B7
        JP Z,SUB_0D20_39                 ; $5492  CA 46 0E
        JP SUB_129A_14                   ; $5495  C3 86 13
SUB_5498:
        CALL SUB_189A                    ; $5498  CD 9A 18
        CALL SUB_573C                    ; $549B  CD 3C 57
        JP SUB_453A_6                    ; $549E  C3 99 45
SUB_5498_1:
        CALL SUB_44F5                    ; $54A1  CD F5 44
        JP SUB_449F_1                    ; $54A4  C3 B4 44
SUB_5498_2:
        POP BC                           ; $54A7  C1
        CALL SUB_53F7                    ; $54A8  CD F7 53
        DEC HL                           ; $54AB  2B
        CALL SUB_13E4                    ; $54AC  CD E4 13
        JR Z,SUB_5498_3                  ; $54AF  28 06
        CALL SUB_5498                    ; $54B1  CD 98 54
        JP SUB_0D20_20                   ; $54B4  C3 92 0D
SUB_5498_3:
        XOR A                            ; $54B7  AF
        LD (SUB_0752_46),A               ; $54B8  32 6D 08
        CALL SUB_5889                    ; $54BB  CD 89 58
        JP C,SUB_0D20_41                 ; $54BE  DA 61 0E
        INC A                            ; $54C1  3C
        JP Z,SUB_0D20_10+1               ; $54C2  CA 6A 0D
SUB_5498_4:
        LD HL,(SUB_0752_40)              ; $54C5  2A 63 08
        LD BC,$0028                      ; $54C8  01 28 00
        ADD HL,BC                        ; $54CB  09
        INC (HL)                         ; $54CC  34
        JP SUB_0D20_41                   ; $54CD  C3 61 0E
SUB_5498_5:
        PUSH HL                          ; $54D0  E5
        LD HL,(SUB_0752_40)              ; $54D1  2A 63 08
        LD A,H                           ; $54D4  7C
        OR L                             ; $54D5  B5
        LD DE,$0042                      ; $54D6  11 42 00
        JP NZ,SUB_0D20_28                ; $54D9  C2 AC 0D
        POP HL                           ; $54DC  E1
        JP SUB_129A_18                   ; $54DD  C3 C4 13
        DEFB    $16,$02,$CD                                      ; $54E0
        DEFW    SUB_53F7_1               ; $54E3
        DEFB    $2B,$CD                                          ; $54E5
        DEFW    SUB_13E4                 ; $54E7
        DEFW    SUB_101B_1               ; $54E9
        DEFB    $CD                                              ; $54EB
        DEFW    SUB_45A3                 ; $54EC
        DEFB    $2C                                              ; $54EE
        DEFW    SUB_50A6_9               ; $54EF
        DEFB    $CA                                              ; $54F1
        DEFW    SUB_5D90_1               ; $54F2
        DEFB    $CD,$A3,$45,$41,$C3,$C6,$20,$CD,$8D              ; $54F4  "M#EACF M"
        DEFB    $23                                              ; $54FD
        DEFW    SUB_2AC5_2               ; $54FE
        DEFW    SUB_3D4E_27              ; $5500
        DEFB    $FF                                              ; $5502
SUB_5503:
        CALL SUB_57A0                    ; $5503  CD A0 57
        LD HL,(SUB_0B2A_40)              ; $5506  2A 92 0B
        EX DE,HL                         ; $5509  EB
        LD HL,(SUB_0752_44)              ; $550A  2A 69 08
SUB_5503_1:
        CALL SUB_459D                    ; $550D  CD 9D 45
        JP Z,SUB_5498                    ; $5510  CA 98 54
        LD A,(HL)                        ; $5513  7E
SUB_5503_2:
        INC HL                           ; $5514  23
        PUSH DE                          ; $5515  D5
        CALL SUB_57A0                    ; $5516  CD A0 57
        POP DE                           ; $5519  D1
        JR SUB_5503_1                    ; $551A  18 F1
SUB_551C:
        LD BC,SUB_573C                   ; $551C  01 3C 57
        LD A,(SUB_0752_55)               ; $551F  3A 93 08
        JR NZ,SUB_552B_1                 ; $5522  20 1A
        PUSH HL                          ; $5524  E5
        PUSH BC                          ; $5525  C5
        PUSH AF                          ; $5526  F5
        LD DE,L_552D                     ; $5527  11 2D 55
        PUSH DE                          ; $552A  D5
SUB_552B:
        PUSH BC                          ; $552B  C5
        RET                              ; $552C  C9
L_552D:
        DEFB    $F1,$C1,$3D,$F2,$25,$55,$E1,$C9                  ; $552D  "qA=r%UaI"
L_5535:
        DEFB    $C1,$E1,$7E                                      ; $5535
        DEFW    SUB_2CF8_1               ; $5538
        DEFB    $C0,$CD                                          ; $553A
        DEFW    SUB_13E4                 ; $553C
SUB_552B_1:
        PUSH BC                          ; $553E  C5
        LD A,(HL)                        ; $553F  7E
        CP $23                           ; $5540  FE 23
        CALL Z,SUB_13E4                  ; $5542  CC E4 13
        CALL SUB_20B2                    ; $5545  CD B2 20
        EX (SP),HL                       ; $5548  E3
        PUSH HL                          ; $5549  E5
        LD DE,L_5535                     ; $554A  11 35 55
        PUSH DE                          ; $554D  D5
        JP (HL)                          ; $554E  E9
SUB_554F:
        PUSH DE                          ; $554F  D5
SUB_554F_1:
        PUSH BC                          ; $5550  C5
        XOR A                            ; $5551  AF
        CALL SUB_551C                    ; $5552  CD 1C 55
        POP BC                           ; $5555  C1
        POP DE                           ; $5556  D1
        XOR A                            ; $5557  AF
        RET                              ; $5558  C9
        DEFB    $CD,$A9,$52,$CA,$70,$0D                          ; $5559  "M)RJp"
        DEFB    $D6,$03,$C2                                      ; $555F
        DEFW    SUB_0D20_10+1            ; $5562
        DEFB    $EB,$21,$A9                                      ; $5564
        DEFW    SUB_0752_70              ; $5567
        DEFB    $7E,$23,$66,$6F,$22                              ; $5569
        DEFW    L_0CB6                   ; $556E
        DEFB    $21,$00                                          ; $5570
        DEFW    SUB_21FC_1               ; $5572
        DEFW    SUB_5E2A_1               ; $5574
        DEFB    $7C,$EB,$11,$B2,$00                              ; $5576
        DEFW    SUB_0925_5               ; $557B
        DEFB    $47,$EB,$7E                                      ; $557D
        DEFW    SUB_2CF8_1               ; $5580
        DEFB    $C0,$D5,$C5,$CD                                  ; $5582
        DEFW    SUB_20AF                 ; $5586
        DEFB    $F5,$CD                                          ; $5588
        DEFW    SUB_45A3                 ; $558A
        DEFB    $41,$CD                                          ; $558C
        DEFW    SUB_45A3                 ; $558E
        DEFB    $53,$CD                                          ; $5590
        DEFW    SUB_3BB3                 ; $5592
        DEFB    $CD                                              ; $5594
        DEFW    SUB_2CB3                 ; $5595
        DEFB    $F1,$C1                                          ; $5597
        DEFW    SUB_4E80_8               ; $5599
        DEFB    $D5,$E5,$2A                                      ; $559B
        DEFW    SUB_5E2A_1               ; $559E
        DEFB    $06                                              ; $55A0
        DEFW    SUB_0752_70              ; $55A1
        DEFW    SUB_341F_1               ; $55A3
        DEFB    $5E                                              ; $55A5
        DEFW    SUB_2AEB                 ; $55A6
        DEFW    L_0CB6                   ; $55A8
        DEFB    $CD                                              ; $55AA
        DEFW    SUB_459D                 ; $55AB
        DEFB    $DA                                              ; $55AD
        DEFW    SUB_0D20_16+1            ; $55AE
        DEFB    $E1,$D1,$EB,$71,$23,$73,$23,$72,$E1,$18,$C0,$F6,$37,$F5,$CD ; $55B0
        DEFW    SUB_3BB3                 ; $55BF
        DEFB    $CD                                              ; $55C1
        DEFW    SUB_2CB3                 ; $55C2
        DEFB    $D5,$CD                                          ; $55C4
        DEFW    SUB_1A85                 ; $55C6
        DEFB    $C1,$E3,$E5,$C5                                  ; $55C8
        DEFW    SUB_3777_4               ; $55CC
        DEFB    $4A,$46,$E3,$7E,$4F,$C5,$E5,$F5,$23              ; $55CE
        DEFW    SUB_22E1_15              ; $55D7
        DEFB    $56,$B7,$CA,$3B                                  ; $55D9
        DEFW    SUB_29E8_14              ; $55DD
        DEFW    SUB_0752_44              ; $55DF
        DEFB    $CD                                              ; $55E1
        DEFW    SUB_459D                 ; $55E2
        DEFW    SUB_3006_5               ; $55E4
        DEFB    $2A                                              ; $55E6
        DEFW    SUB_0B2A_40              ; $55E7
        DEFB    $CD                                              ; $55E9
        DEFW    SUB_459D                 ; $55EA
        DEFW    SUB_2824_2               ; $55EC
        DEFB    $59,$16                                          ; $55EE
        DEFW    SUB_29E8_5               ; $55F0
        DEFW    SUB_0B2A_42              ; $55F2
        DEFB    $19                                              ; $55F4
        DEFW    SUB_2AEB                 ; $55F5
        DEFW    SUB_0B2A_19              ; $55F7
        DEFB    $CD                                              ; $55F9
        DEFW    SUB_459D                 ; $55FA
        DEFB    $DA                                              ; $55FC
        DEFW    SUB_5645_3               ; $55FD
SUB_554F_2:
        POP AF                           ; $55FF  F1
        LD A,C                           ; $5600  79
        CALL SUB_48D6                    ; $5601  CD D6 48
        POP HL                           ; $5604  E1
        POP BC                           ; $5605  C1
        EX (SP),HL                       ; $5606  E3
        PUSH DE                          ; $5607  D5
        PUSH BC                          ; $5608  C5
        CALL SUB_4A37                    ; $5609  CD 37 4A
        POP BC                           ; $560C  C1
        POP DE                           ; $560D  D1
        EX (SP),HL                       ; $560E  E3
        PUSH BC                          ; $560F  C5
        PUSH HL                          ; $5610  E5
        INC HL                           ; $5611  23
        LD (HL),E                        ; $5612  73
        INC HL                           ; $5613  23
        LD (HL),D                        ; $5614  72
        PUSH AF                          ; $5615  F5
        POP AF                           ; $5616  F1
        POP HL                           ; $5617  E1
        INC HL                           ; $5618  23
        LD E,(HL)                        ; $5619  5E
        INC HL                           ; $561A  23
        LD D,(HL)                        ; $561B  56
        POP BC                           ; $561C  C1
        POP HL                           ; $561D  E1
        PUSH DE                          ; $561E  D5
        INC HL                           ; $561F  23
        LD E,(HL)                        ; $5620  5E
        INC HL                           ; $5621  23
        LD D,(HL)                        ; $5622  56
        EX DE,HL                         ; $5623  EB
        POP DE                           ; $5624  D1
        LD A,C                           ; $5625  79
        CP B                             ; $5626  B8
        JR NC,SUB_554F_3                 ; $5627  30 01
        LD B,A                           ; $5629  47
SUB_554F_3:
        SUB B                            ; $562A  90
        LD C,A                           ; $562B  4F
        POP AF                           ; $562C  F1
        CALL NC,SUB_5645                 ; $562D  D4 45 56
        INC B                            ; $5630  04
SUB_554F_4:
        DEC B                            ; $5631  05
        JR Z,SUB_554F_6                  ; $5632  28 0C
        LD A,(HL)                        ; $5634  7E
        LD (DE),A                        ; $5635  12
        INC HL                           ; $5636  23
        INC DE                           ; $5637  13
        JP SUB_554F_4                    ; $5638  C3 31 56
        DEFB    $C1,$C1,$C1                                      ; $563B
SUB_554F_5:
        POP BC                           ; $563E  C1
        POP BC                           ; $563F  C1
SUB_554F_6:
        CALL C,SUB_5645                  ; $5640  DC 45 56
        POP HL                           ; $5643  E1
        RET                              ; $5644  C9
SUB_5645:
        LD A,$20                         ; $5645  3E 20
        INC C                            ; $5647  0C
SUB_5645_1:
        DEC C                            ; $5648  0D
SUB_5645_2:
        RET Z                            ; $5649  C8
        LD (DE),A                        ; $564A  12
        INC DE                           ; $564B  13
        JR SUB_5645_1                    ; $564C  18 FA
SUB_5645_3:
        POP AF                           ; $564E  F1
        POP HL                           ; $564F  E1
        POP BC                           ; $5650  C1
        EX (SP),HL                       ; $5651  E3
        EX DE,HL                         ; $5652  EB
        JR NZ,SUB_5645_4                 ; $5653  20 09
        PUSH BC                          ; $5655  C5
        LD A,B                           ; $5656  78
        CALL SUB_485A                    ; $5657  CD 5A 48
        CALL SUB_486C_6                  ; $565A  CD 98 48
        POP BC                           ; $565D  C1
SUB_5645_4:
        EX (SP),HL                       ; $565E  E3
        PUSH BC                          ; $565F  C5
        PUSH HL                          ; $5660  E5
        PUSH AF                          ; $5661  F5
        JP SUB_554F_2                    ; $5662  C3 FF 55
SUB_5645_5:
        CALL SUB_13E4                    ; $5665  CD E4 13
        CALL SUB_45A3                    ; $5668  CD A3 45
        INC H                            ; $566B  24
        CALL SUB_45A3                    ; $566C  CD A3 45
        JR Z,SUB_554F_5                  ; $566F  28 CD
        OR D                             ; $5671  B2
        JR NZ,SUB_5645_2                 ; $5672  20 D5
        LD A,(HL)                        ; $5674  7E
        CP $2C                           ; $5675  FE 2C
        JR NZ,SUB_5645_6                 ; $5677  20 0F
        CALL SUB_13E4                    ; $5679  CD E4 13
        CALL SUB_52A9                    ; $567C  CD A9 52
        CP $02                           ; $567F  FE 02
        JP Z,SUB_0D20_10+1               ; $5681  CA 6A 0D
        CALL SUB_52A1                    ; $5684  CD A1 52
        XOR A                            ; $5687  AF
SUB_5645_6:
        PUSH AF                          ; $5688  F5
        CALL SUB_45A3                    ; $5689  CD A3 45
        ADD HL,HL                        ; $568C  29
        POP AF                           ; $568D  F1
        EX (SP),HL                       ; $568E  E3
        PUSH AF                          ; $568F  F5
        LD A,L                           ; $5690  7D
        OR A                             ; $5691  B7
        JP Z,SUB_14E4_2                  ; $5692  CA EB 14
        PUSH HL                          ; $5695  E5
        CALL SUB_485A                    ; $5696  CD 5A 48
        EX DE,HL                         ; $5699  EB
        POP BC                           ; $569A  C1
SUB_5645_7:
        POP AF                           ; $569B  F1
        PUSH AF                          ; $569C  F5
        JR Z,SUB_5645_11                 ; $569D  28 20
        CALL SUB_4472                    ; $569F  CD 72 44
        JR NZ,SUB_5645_8                 ; $56A2  20 03
        CALL SUB_43DA                    ; $56A4  CD DA 43
SUB_5645_8:
        CP $03                           ; $56A7  FE 03
        JP Z,SUB_5645_10                 ; $56A9  CA B8 56
SUB_5645_9:
        LD (HL),A                        ; $56AC  77
        INC HL                           ; $56AD  23
        DEC C                            ; $56AE  0D
        JR NZ,SUB_5645_7                 ; $56AF  20 EA
        POP AF                           ; $56B1  F1
        CALL SUB_189A                    ; $56B2  CD 9A 18
        JP SUB_486C_6                    ; $56B5  C3 98 48
SUB_5645_10:
        LD HL,(SUB_0B2A_31)              ; $56B8  2A 81 0B
        LD SP,HL                         ; $56BB  F9
        JP SUB_45B5_9                    ; $56BC  C3 E7 45
SUB_5645_11:
        CALL SUB_5889                    ; $56BF  CD 89 58
        JP C,SUB_0D20_13+1               ; $56C2  DA 76 0D
        JP SUB_5645_9                    ; $56C5  C3 AC 56
        DEFB    $CD,$B5,$52,$CA,$70,$0D                          ; $56C8  "M5RJp"
        DEFB    $FE,$02,$CA                                      ; $56CE
        DEFW    SUB_0D20_10+1            ; $56D1
        DEFB    $21,$27                                          ; $56D3
        DEFW    SUB_0752_70              ; $56D5
        DEFB    $7E                                              ; $56D7
        DEFW    SUB_2874_11              ; $56D8
        DEFW    SUB_0925_9               ; $56DA
        DEFB    $FE                                              ; $56DC
        DEFW    SUB_2803                 ; $56DD
        DEFW    SUB_22E1_6               ; $56DF
        DEFB    $7E,$B7                                          ; $56E1
        DEFW    SUB_0752_72              ; $56E3
        DEFB    $C5,$60,$69                                      ; $56E5
        DEFW    SUB_4291_4               ; $56E8
        DEFB    $58                                              ; $56EA
        DEFW    SUB_189A_4               ; $56EB
        DEFW    SUB_3EDB_2               ; $56ED
        DEFB    $80,$96                                          ; $56EF
        DEFW    SUB_064E_1               ; $56F1
        DEFW    SUB_0752_70              ; $56F3
        DEFB    $23,$7E                                          ; $56F5
        DEFW    SUB_1A93_7               ; $56F7
        DEFB    $D6,$01,$9F,$C3                                  ; $56F9
        DEFW    SUB_2AFF                 ; $56FD
SUB_56FF:
        LD D,B                           ; $56FF  50
        LD E,C                           ; $5700  59
        INC DE                           ; $5701  13
SUB_5702:
        LD HL,$0027                      ; $5702  21 27 00
        ADD HL,BC                        ; $5705  09
        PUSH BC                          ; $5706  C5
        XOR A                            ; $5707  AF
        LD (HL),A                        ; $5708  77
        CALL SUB_5878                    ; $5709  CD 78 58
        LD A,(SUB_0752_68)               ; $570C  3A F0 08
        CALL SUB_5B44                    ; $570F  CD 44 5B
        CP $FF                           ; $5712  FE FF
        JP Z,SUB_0D20_17+1               ; $5714  CA 85 0D
        DEC A                            ; $5717  3D
        JP Z,SUB_0D20_9+1                ; $5718  CA 67 0D
        DEC A                            ; $571B  3D
        JP NZ,SUB_5702_1                 ; $571C  C2 2B 57
        POP DE                           ; $571F  D1
        XOR A                            ; $5720  AF
        LD (DE),A                        ; $5721  12
        LD C,$10                         ; $5722  0E 10
        INC DE                           ; $5724  13
        CALL $0005                       ; $5725  CD 05 00
        JP SUB_0D20_8                    ; $5728  C3 64 0D
SUB_5702_1:
        INC A                            ; $572B  3C
        JP Z,SUB_0D20_17+1               ; $572C  CA 85 0D
        POP BC                           ; $572F  C1
        LD HL,$0025                      ; $5730  21 25 00
        ADD HL,BC                        ; $5733  09
        LD E,(HL)                        ; $5734  5E
        INC HL                           ; $5735  23
        LD D,(HL)                        ; $5736  56
        INC DE                           ; $5737  13
        LD (HL),D                        ; $5738  72
        DEC HL                           ; $5739  2B
        LD (HL),E                        ; $573A  73
        RET                              ; $573B  C9
SUB_573C:
        CALL SUB_52B8                    ; $573C  CD B8 52
        JR Z,SUB_573C_4                  ; $573F  28 2F
        LD L,E                           ; $5741  6B
        PUSH BC                          ; $5742  C5
        LD A,(BC)                        ; $5743  0A
        LD D,B                           ; $5744  50
        LD E,C                           ; $5745  59
        INC DE                           ; $5746  13
        PUSH DE                          ; $5747  D5
        CP $02                           ; $5748  FE 02
        JR NZ,SUB_573C_3                 ; $574A  20 1A
        INC L                            ; $574C  2C
        DEC L                            ; $574D  2D
        JR NZ,SUB_573C_1                 ; $574E  20 02
        XOR A                            ; $5750  AF
        LD (BC),A                        ; $5751  02
SUB_573C_1:
        LD HL,SUB_573C_2                 ; $5752  21 5D 57
        PUSH HL                          ; $5755  E5
        PUSH HL                          ; $5756  E5
        LD H,B                           ; $5757  60
        LD L,C                           ; $5758  69
        LD A,$1A                         ; $5759  3E 1A
        JR SUB_57A0_1                    ; $575B  18 54
SUB_573C_2:
        LD HL,$0027                      ; $575D  21 27 00
        ADD HL,BC                        ; $5760  09
        LD A,(HL)                        ; $5761  7E
        OR A                             ; $5762  B7
        CALL NZ,SUB_5702                 ; $5763  C4 02 57
SUB_573C_3:
        POP DE                           ; $5766  D1
        CALL SUB_5878                    ; $5767  CD 78 58
        LD C,$10                         ; $576A  0E 10
        CALL $0005                       ; $576C  CD 05 00
        POP BC                           ; $576F  C1
SUB_573C_4:
        LD D,$29                         ; $5770  16 29
        XOR A                            ; $5772  AF
SUB_573C_5:
        LD (BC),A                        ; $5773  02
        INC BC                           ; $5774  03
        DEC D                            ; $5775  15
        JR NZ,SUB_573C_5                 ; $5776  20 FB
        RET                              ; $5778  C9
        DEFB    $CD,$B5,$52,$CA,$70,$0D                          ; $5779  "M5RJp"
        DEFB    $FE                                              ; $577F
        DEFW    SUB_20B5_5               ; $5780
        DEFB    $26                                              ; $5782
        DEFW    SUB_1E72_20              ; $5783
        DEFW    SUB_20B5_5               ; $5785
        DEFB    $AE                                              ; $5787
        DEFW    SUB_0752_70              ; $5788
        DEFB    $7E,$2B,$6E,$C3                                  ; $578A
        DEFW    SUB_1E4D_1               ; $578E
        DEFB    $CD,$B5,$52,$CA,$70,$0D                          ; $5790  "M5RJp"
        DEFB    $21,$10                                          ; $5796
        DEFW    SUB_0752_70              ; $5798
        DEFB    $7E                                              ; $579A
        DEFW    SUB_4DC3                 ; $579B
        DEFB    $1E                                              ; $579D
SUB_573C_6:
        POP HL                           ; $579E  E1
        POP AF                           ; $579F  F1
SUB_57A0:
        PUSH HL                          ; $57A0  E5
        PUSH AF                          ; $57A1  F5
        LD HL,(SUB_0752_40)              ; $57A2  2A 63 08
        LD A,(HL)                        ; $57A5  7E
        CP $01                           ; $57A6  FE 01
        JP Z,SUB_463E_8                  ; $57A8  CA BB 46
        CP $03                           ; $57AB  FE 03
        JP Z,SUB_5D26_4                  ; $57AD  CA 36 5D
        POP AF                           ; $57B0  F1
SUB_57A0_1:
        PUSH DE                          ; $57B1  D5
        PUSH BC                          ; $57B2  C5
        LD B,H                           ; $57B3  44
        LD C,L                           ; $57B4  4D
        PUSH AF                          ; $57B5  F5
        LD DE,$0027                      ; $57B6  11 27 00
        ADD HL,DE                        ; $57B9  19
        LD A,(HL)                        ; $57BA  7E
        CP $80                           ; $57BB  FE 80
        PUSH HL                          ; $57BD  E5
        CALL Z,SUB_56FF                  ; $57BE  CC FF 56
        POP HL                           ; $57C1  E1
        INC (HL)                         ; $57C2  34
        LD C,(HL)                        ; $57C3  4E
        LD B,$00                         ; $57C4  06 00
        INC HL                           ; $57C6  23
        POP AF                           ; $57C7  F1
        PUSH AF                          ; $57C8  F5
        LD D,(HL)                        ; $57C9  56
        CP $0D                           ; $57CA  FE 0D
        LD (HL),B                        ; $57CC  70
SUB_57A0_2:
        JR Z,SUB_57A0_3                  ; $57CD  28 05
        ADD A,$E0                        ; $57CF  C6 E0
        LD A,D                           ; $57D1  7A
        ADC A,B                          ; $57D2  88
        LD (HL),A                        ; $57D3  77
SUB_57A0_3:
        ADD HL,BC                        ; $57D4  09
        POP AF                           ; $57D5  F1
        POP BC                           ; $57D6  C1
        POP DE                           ; $57D7  D1
        LD (HL),A                        ; $57D8  77
        POP HL                           ; $57D9  E1
        RET                              ; $57DA  C9
SUB_57A0_4:
        DEC DE                           ; $57DB  1B
        DEC HL                           ; $57DC  2B
        LD (HL),E                        ; $57DD  73
        INC HL                           ; $57DE  23
        LD (HL),D                        ; $57DF  72
        INC HL                           ; $57E0  23
        LD (HL),$80                      ; $57E1  36 80
        INC HL                           ; $57E3  23
        LD (HL),$80                      ; $57E4  36 80
        POP HL                           ; $57E6  E1
        EX (SP),HL                       ; $57E7  E3
        LD B,H                           ; $57E8  44
        LD C,L                           ; $57E9  4D
        PUSH HL                          ; $57EA  E5
        LD HL,$0022                      ; $57EB  21 22 00
        ADD HL,BC                        ; $57EE  09
        LD (HL),E                        ; $57EF  73
        INC HL                           ; $57F0  23
        LD (HL),D                        ; $57F1  72
        INC HL                           ; $57F2  23
        LD (HL),$00                      ; $57F3  36 00
        POP HL                           ; $57F5  E1
        LD A,(SUB_0752_48)               ; $57F6  3A 6F 08
        OR A                             ; $57F9  B7
        JR NZ,SUB_57A0_5                 ; $57FA  20 05
        CALL SUB_5842                    ; $57FC  CD 42 58
        POP HL                           ; $57FF  E1
        RET                              ; $5800  C9
SUB_57A0_5:
        CALL SUB_56FF                    ; $5801  CD FF 56
        POP HL                           ; $5804  E1
        JP SUB_189A                      ; $5805  C3 9A 18
SUB_5808:
        PUSH BC                          ; $5808  C5
        LD BC,$0080                      ; $5809  01 80 00
        LDIR                             ; $580C  ED B0
        POP BC                           ; $580E  C1
        RET                              ; $580F  C9
SUB_5810:
        PUSH BC                          ; $5810  C5
        PUSH HL                          ; $5811  E5
SUB_5810_1:
        LD HL,(SUB_0752_40)              ; $5812  2A 63 08
        LD A,(HL)                        ; $5815  7E
        CP $03                           ; $5816  FE 03
        JP Z,SUB_5D26_8                  ; $5818  CA 63 5D
        LD BC,$0028                      ; $581B  01 28 00
        ADD HL,BC                        ; $581E  09
        LD A,(HL)                        ; $581F  7E
        OR A                             ; $5820  B7
        JR Z,SUB_5810_2                  ; $5821  28 0C
        DEC HL                           ; $5823  2B
        LD A,(HL)                        ; $5824  7E
        INC HL                           ; $5825  23
        DEC (HL)                         ; $5826  35
        SUB (HL)                         ; $5827  96
        LD C,A                           ; $5828  4F
        ADD HL,BC                        ; $5829  09
        LD A,(HL)                        ; $582A  7E
        OR A                             ; $582B  B7
        POP HL                           ; $582C  E1
        POP BC                           ; $582D  C1
        RET                              ; $582E  C9
SUB_5810_2:
        DEC HL                           ; $582F  2B
        LD A,(HL)                        ; $5830  7E
        OR A                             ; $5831  B7
        JR Z,SUB_5810_3                  ; $5832  28 05
        CALL SUB_583F                    ; $5834  CD 3F 58
        JR NZ,SUB_5810_1                 ; $5837  20 D9
SUB_5810_3:
        SCF                              ; $5839  37
        POP HL                           ; $583A  E1
        POP BC                           ; $583B  C1
        LD A,$1A                         ; $583C  3E 1A
        RET                              ; $583E  C9
SUB_583F:
        LD HL,(SUB_0752_40)              ; $583F  2A 63 08
SUB_5842:
        PUSH DE                          ; $5842  D5
        LD D,H                           ; $5843  54
        LD E,L                           ; $5844  5D
SUB_5842_1:
        INC DE                           ; $5845  13
        LD BC,$0025                      ; $5846  01 25 00
        ADD HL,BC                        ; $5849  09
        LD C,(HL)                        ; $584A  4E
        INC HL                           ; $584B  23
        LD B,(HL)                        ; $584C  46
        INC BC                           ; $584D  03
        DEC HL                           ; $584E  2B
        LD (HL),C                        ; $584F  71
        INC HL                           ; $5850  23
        LD (HL),B                        ; $5851  70
        INC HL                           ; $5852  23
        INC HL                           ; $5853  23
        PUSH HL                          ; $5854  E5
        LD BC,$007F                      ; $5855  01 7F 00
        LD (HL),$00                      ; $5858  36 00
        PUSH DE                          ; $585A  D5
        LD D,H                           ; $585B  54
        LD E,L                           ; $585C  5D
        INC DE                           ; $585D  13
        LDIR                             ; $585E  ED B0
        POP DE                           ; $5860  D1
        CALL SUB_5878                    ; $5861  CD 78 58
        LD A,(SUB_0752_67)               ; $5864  3A EF 08
        CALL SUB_5B44                    ; $5867  CD 44 5B
        OR A                             ; $586A  B7
        LD A,$00                         ; $586B  3E 00
        JR NZ,SUB_5842_2                 ; $586D  20 02
        LD A,$80                         ; $586F  3E 80
SUB_5842_2:
        POP HL                           ; $5871  E1
        LD (HL),A                        ; $5872  77
        DEC HL                           ; $5873  2B
        LD (HL),A                        ; $5874  77
        OR A                             ; $5875  B7
        POP DE                           ; $5876  D1
        RET                              ; $5877  C9
SUB_5878:
        PUSH BC                          ; $5878  C5
        PUSH DE                          ; $5879  D5
        PUSH HL                          ; $587A  E5
        LD HL,$0028                      ; $587B  21 28 00
        ADD HL,DE                        ; $587E  19
        EX DE,HL                         ; $587F  EB
        LD C,$1A                         ; $5880  0E 1A
        CALL $0005                       ; $5882  CD 05 00
        POP HL                           ; $5885  E1
        POP DE                           ; $5886  D1
SUB_5878_1:
        POP BC                           ; $5887  C1
        RET                              ; $5888  C9
SUB_5889:
        CALL SUB_5810                    ; $5889  CD 10 58
        RET C                            ; $588C  D8
        CP $1A                           ; $588D  FE 1A
        SCF                              ; $588F  37
        CCF                              ; $5890  3F
        RET NZ                           ; $5891  C0
        PUSH BC                          ; $5892  C5
        PUSH HL                          ; $5893  E5
        LD HL,(SUB_0752_40)              ; $5894  2A 63 08
        LD BC,$0027                      ; $5897  01 27 00
        ADD HL,BC                        ; $589A  09
        LD (HL),$00                      ; $589B  36 00
        INC HL                           ; $589D  23
        LD (HL),$00                      ; $589E  36 00
        SCF                              ; $58A0  37
        POP HL                           ; $58A1  E1
        POP BC                           ; $58A2  C1
        RET                              ; $58A3  C9
SUB_58A4:
        CALL SUB_1A8C_1+1                ; $58A4  CD 90 1A
        PUSH HL                          ; $58A7  E5
        CALL SUB_4A37                    ; $58A8  CD 37 4A
        LD A,(HL)                        ; $58AB  7E
        OR A                             ; $58AC  B7
        JP Z,SUB_0D20_15+1               ; $58AD  CA 7C 0D
        PUSH AF                          ; $58B0  F5
        INC HL                           ; $58B1  23
        LD E,(HL)                        ; $58B2  5E
        INC HL                           ; $58B3  23
        LD H,(HL)                        ; $58B4  66
        LD L,E                           ; $58B5  6B
        LD E,A                           ; $58B6  5F
        CP $02                           ; $58B7  FE 02
        JR C,SUB_58A4_1                  ; $58B9  38 0A
        LD C,(HL)                        ; $58BB  4E
        INC HL                           ; $58BC  23
        LD A,(HL)                        ; $58BD  7E
        DEC E                            ; $58BE  1D
        CP $3A                           ; $58BF  FE 3A
        JR Z,SUB_58A4_2                  ; $58C1  28 06
        DEC HL                           ; $58C3  2B
        INC E                            ; $58C4  1C
SUB_58A4_1:
        DEC HL                           ; $58C5  2B
        INC E                            ; $58C6  1C
        LD C,$40                         ; $58C7  0E 40
SUB_58A4_2:
        DEC E                            ; $58C9  1D
        JP Z,SUB_0D20_15+1               ; $58CA  CA 7C 0D
        LD A,C                           ; $58CD  79
        SUB $40                          ; $58CE  D6 40
        JP C,SUB_0D20_15+1               ; $58D0  DA 7C 0D
        CP $1B                           ; $58D3  FE 1B
        JP NC,SUB_0D20_15+1              ; $58D5  D2 7C 0D
        LD BC,SUB_0752_62                ; $58D8  01 CD 08
        LD (BC),A                        ; $58DB  02
        INC BC                           ; $58DC  03
        LD D,$0B                         ; $58DD  16 0B
SUB_58A4_3:
        INC HL                           ; $58DF  23
SUB_58A4_4:
        DEC E                            ; $58E0  1D
        JP M,SUB_58FE_1                  ; $58E1  FA 11 59
        LD A,(HL)                        ; $58E4  7E
        CP $2E                           ; $58E5  FE 2E
        JR NZ,SUB_58A4_5                 ; $58E7  20 08
        CALL SUB_58FE                    ; $58E9  CD FE 58
        POP AF                           ; $58EC  F1
        SCF                              ; $58ED  37
        PUSH AF                          ; $58EE  F5
        JR SUB_58A4_3                    ; $58EF  18 EE
SUB_58A4_5:
        LD (BC),A                        ; $58F1  02
        INC BC                           ; $58F2  03
        INC HL                           ; $58F3  23
        DEC D                            ; $58F4  15
        JR NZ,SUB_58A4_4                 ; $58F5  20 E9
SUB_58A4_6:
        XOR A                            ; $58F7  AF
        LD (SUB_0752_65),A               ; $58F8  32 D9 08
        POP AF                           ; $58FB  F1
        POP HL                           ; $58FC  E1
        RET                              ; $58FD  C9
SUB_58FE:
        LD A,D                           ; $58FE  7A
        CP $0B                           ; $58FF  FE 0B
        JP Z,SUB_0D20_15+1               ; $5901  CA 7C 0D
        CP $03                           ; $5904  FE 03
        JP C,SUB_0D20_15+1               ; $5906  DA 7C 0D
        RET Z                            ; $5909  C8
        LD A,$20                         ; $590A  3E 20
        LD (BC),A                        ; $590C  02
        INC BC                           ; $590D  03
        DEC D                            ; $590E  15
        JR SUB_58FE                      ; $590F  18 ED
SUB_58FE_1:
        INC D                            ; $5911  14
        DEC D                            ; $5912  15
        JR Z,SUB_58A4_6                  ; $5913  28 E2
SUB_58FE_2:
        LD A,$20                         ; $5915  3E 20
SUB_58FE_3:
        LD (BC),A                        ; $5917  02
        INC BC                           ; $5918  03
        DEC D                            ; $5919  15
        JR NZ,SUB_58FE_2                 ; $591A  20 F9
        JR SUB_58A4_6                    ; $591C  18 D9
SUB_58FE_4:
        CALL SUB_58A4                    ; $591E  CD A4 58
        PUSH HL                          ; $5921  E5
        LD DE,$0080                      ; $5922  11 80 00
        LD C,$1A                         ; $5925  0E 1A
        CALL $0005                       ; $5927  CD 05 00
        LD DE,SUB_0752_62                ; $592A  11 CD 08
        LD C,$0F                         ; $592D  0E 0F
        CALL $0005                       ; $592F  CD 05 00
        INC A                            ; $5932  3C
        JP Z,SUB_0D20_11+1               ; $5933  CA 6D 0D
        LD HL,SUB_0752_61                ; $5936  21 BD 08
        LD DE,SUB_0752_62                ; $5939  11 CD 08
        LD B,$0C                         ; $593C  06 0C
SUB_58FE_5:
        LD A,(DE)                        ; $593E  1A
        LD (HL),A                        ; $593F  77
        INC HL                           ; $5940  23
        INC DE                           ; $5941  13
        DJNZ SUB_58FE_5                  ; $5942  10 FA
        POP HL                           ; $5944  E1
        CALL SUB_45A3                    ; $5945  CD A3 45
        LD B,C                           ; $5948  41
        CALL SUB_45A3                    ; $5949  CD A3 45
        LD D,E                           ; $594C  53
        CALL SUB_58A4                    ; $594D  CD A4 58
SUB_58FE_6:
        PUSH HL                          ; $5950  E5
        LD A,(SUB_0752_62)               ; $5951  3A CD 08
        LD HL,SUB_0752_61                ; $5954  21 BD 08
        CP (HL)                          ; $5957  BE
SUB_58FE_7:
        JP NZ,SUB_14E4_2                 ; $5958  C2 EB 14
        LD DE,SUB_0752_62                ; $595B  11 CD 08
        LD C,$0F                         ; $595E  0E 0F
        CALL $0005                       ; $5960  CD 05 00
        INC A                            ; $5963  3C
        JP NZ,SUB_0D20_18+1              ; $5964  C2 88 0D
        LD C,$17                         ; $5967  0E 17
        LD DE,SUB_0752_61                ; $5969  11 BD 08
        CALL $0005                       ; $596C  CD 05 00
        POP HL                           ; $596F  E1
        RET                              ; $5970  C9
        DEFB    $01                                              ; $5971
        DEFW    SUB_189A                 ; $5972
        DEFB    $C5,$CD                                          ; $5974
        DEFW    SUB_1A8C_1+1             ; $5976
        DEFB    $E5,$CD,$37,$4A,$7E,$B7,$CA,$6A,$0D              ; $5978  "eM7J~7Jj"
        DEFB    $23                                              ; $5981
        DEFW    SUB_22E1_12              ; $5982
        DEFW    SUB_0925_13              ; $5984
        DEFB    $E6,$DF,$16,$02,$FE,$4F                          ; $5986
        DEFW    SUB_0D20_2               ; $598C
        DEFB    $16,$01,$FE                                      ; $598E
        DEFW    SUB_2824_4               ; $5991
        DEFW    SUB_15CF_8               ; $5993
        DEFB    $03                                              ; $5995
        DEFB    $FE,$52,$C2,$6A,$0D                              ; $5996  "~RBj"
        DEFB    $E1,$CD                                          ; $599B
        DEFW    SUB_45A3                 ; $599D
        DEFB    $2C,$D5,$FE,$23,$CC                              ; $599F
        DEFW    SUB_13E4                 ; $59A4
        DEFB    $CD,$B2,$20,$CD,$A3,$45,$2C,$7B,$B7,$CA,$70,$0D  ; $59A6  "M2 M#E,{7Jp"
        DEFB    $D1                                              ; $59B2
SUB_58FE_8:
        LD E,A                           ; $59B3  5F
        PUSH DE                          ; $59B4  D5
        CALL SUB_52B8                    ; $59B5  CD B8 52
        JP NZ,SUB_0D20_14+1              ; $59B8  C2 79 0D
        POP DE                           ; $59BB  D1
        PUSH BC                          ; $59BC  C5
        PUSH DE                          ; $59BD  D5
        CALL SUB_58A4                    ; $59BE  CD A4 58
        POP DE                           ; $59C1  D1
        POP BC                           ; $59C2  C1
        PUSH BC                          ; $59C3  C5
        PUSH AF                          ; $59C4  F5
        LD A,D                           ; $59C5  7A
        CALL SUB_5BB1                    ; $59C6  CD B1 5B
        POP AF                           ; $59C9  F1
        LD (SUB_0B2A_25),HL              ; $59CA  22 77 0B
        JR C,SUB_58FE_9                  ; $59CD  38 15
        LD A,E                           ; $59CF  7B
        OR A                             ; $59D0  B7
        JP NZ,SUB_58FE_9                 ; $59D1  C2 E4 59
        LD HL,SUB_0752_64                ; $59D4  21 D6 08
        LD A,(HL)                        ; $59D7  7E
        CP $20                           ; $59D8  FE 20
        JR NZ,SUB_58FE_9                 ; $59DA  20 08
        LD (HL),$42                      ; $59DC  36 42
        INC HL                           ; $59DE  23
        LD (HL),$41                      ; $59DF  36 41
        INC HL                           ; $59E1  23
        LD (HL),$53                      ; $59E2  36 53
SUB_58FE_9:
        POP HL                           ; $59E4  E1
        LD A,D                           ; $59E5  7A
        PUSH AF                          ; $59E6  F5
        LD (SUB_0752_40),HL              ; $59E7  22 63 08
        PUSH HL                          ; $59EA  E5
        INC HL                           ; $59EB  23
        LD DE,SUB_0752_62                ; $59EC  11 CD 08
        LD C,$0C                         ; $59EF  0E 0C
SUB_58FE_10:
        LD A,(DE)                        ; $59F1  1A
        LD (HL),A                        ; $59F2  77
        INC DE                           ; $59F3  13
        INC HL                           ; $59F4  23
        DEC C                            ; $59F5  0D
        JR NZ,SUB_58FE_10                ; $59F6  20 F9
        LD (HL),$00                      ; $59F8  36 00
        LD DE,$0014                      ; $59FA  11 14 00
        ADD HL,DE                        ; $59FD  19
        LD (HL),$00                      ; $59FE  36 00
        POP DE                           ; $5A00  D1
        PUSH DE                          ; $5A01  D5
        INC DE                           ; $5A02  13
        CALL SUB_5878                    ; $5A03  CD 78 58
        POP HL                           ; $5A06  E1
        POP AF                           ; $5A07  F1
        PUSH AF                          ; $5A08  F5
        PUSH HL                          ; $5A09  E5
        CP $02                           ; $5A0A  FE 02
        JR NZ,SUB_58FE_13                ; $5A0C  20 12
        PUSH DE                          ; $5A0E  D5
        LD C,$13                         ; $5A0F  0E 13
        CALL $0005                       ; $5A11  CD 05 00
        POP DE                           ; $5A14  D1
SUB_58FE_11:
        LD C,$16                         ; $5A15  0E 16
SUB_58FE_12:
        CALL $0005                       ; $5A17  CD 05 00
        INC A                            ; $5A1A  3C
        JP Z,SUB_0D20_17+1               ; $5A1B  CA 85 0D
        JR SUB_58FE_14                   ; $5A1E  18 13
SUB_58FE_13:
        LD C,$0F                         ; $5A20  0E 0F
        CALL $0005                       ; $5A22  CD 05 00
        INC A                            ; $5A25  3C
        JR NZ,SUB_58FE_14                ; $5A26  20 0B
        CALL SUB_0C98                    ; $5A28  CD 98 0C
        CP $03                           ; $5A2B  FE 03
        JP NZ,SUB_0D20_11+1              ; $5A2D  C2 6D 0D
        INC DE                           ; $5A30  13
        JR SUB_58FE_11                   ; $5A31  18 E2
SUB_58FE_14:
        POP DE                           ; $5A33  D1
        POP AF                           ; $5A34  F1
        LD (DE),A                        ; $5A35  12
        PUSH DE                          ; $5A36  D5
        LD HL,$0025                      ; $5A37  21 25 00
SUB_58FE_15:
        ADD HL,DE                        ; $5A3A  19
SUB_5A3B:
        XOR A                            ; $5A3B  AF
        LD (HL),A                        ; $5A3C  77
SUB_5A3B_1:
        INC HL                           ; $5A3D  23
        LD (HL),A                        ; $5A3E  77
        INC HL                           ; $5A3F  23
        LD (HL),A                        ; $5A40  77
        INC HL                           ; $5A41  23
        LD (HL),A                        ; $5A42  77
        POP HL                           ; $5A43  E1
        LD A,(HL)                        ; $5A44  7E
        CP $03                           ; $5A45  FE 03
        JP Z,SUB_5A3B_2                  ; $5A47  CA 56 5A
        CP $01                           ; $5A4A  FE 01
        JP NZ,SUB_453A_6                 ; $5A4C  C2 99 45
        CALL SUB_583F                    ; $5A4F  CD 3F 58
        LD HL,(SUB_0B2A_25)              ; $5A52  2A 77 0B
        RET                              ; $5A55  C9
SUB_5A3B_2:
        LD BC,$0029                      ; $5A56  01 29 00
        ADD HL,BC                        ; $5A59  09
        LD C,$80                         ; $5A5A  0E 80
SUB_5A3B_3:
        LD (HL),B                        ; $5A5C  70
        INC HL                           ; $5A5D  23
        DEC C                            ; $5A5E  0D
        JR NZ,SUB_5A3B_3                 ; $5A5F  20 FB
        JP SUB_453A_6                    ; $5A61  C3 99 45
SUB_5A3B_4:
        RET NZ                           ; $5A64  C0
        CALL SUB_554F                    ; $5A65  CD 4F 55
        CALL SUB_25D9                    ; $5A68  CD D9 25
SUB_5A3B_5:
        JP $0000                         ; $5A6B  C3 00 00
SUB_5A3B_6:
        RET NZ                           ; $5A6E  C0
        PUSH HL                          ; $5A6F  E5
        CALL SUB_554F                    ; $5A70  CD 4F 55
        LD C,$19                         ; $5A73  0E 19
        CALL $0005                       ; $5A75  CD 05 00
        PUSH AF                          ; $5A78  F5
        LD C,$0D                         ; $5A79  0E 0D
        CALL $0005                       ; $5A7B  CD 05 00
        POP AF                           ; $5A7E  F1
        LD E,A                           ; $5A7F  5F
        LD C,$0E                         ; $5A80  0E 0E
        CALL $0005                       ; $5A82  CD 05 00
        POP HL                           ; $5A85  E1
        RET                              ; $5A86  C9
        DEFB    $CD                                              ; $5A87
        DEFW    SUB_58A4                 ; $5A88
        DEFW    SUB_1128_21              ; $5A8A
        DEFB    $80,$00,$0E,$1A,$CD,$05,$00,$11                  ; $5A8C
        DEFW    SUB_0752_62              ; $5A94
        DEFW    SUB_0D20_48              ; $5A96
        DEFB    $0F,$CD,$05,$00,$3C,$D1,$D5                      ; $5A98
        DEFW    SUB_0D20_51              ; $5A9F
        DEFB    $10,$C4,$05,$00                                  ; $5AA1
        DEFB    $F1,$D1,$CA,$6D,$0D                              ; $5AA5  "qQJm"
        DEFW    SUB_129A_6               ; $5AAA
        DEFB    $CD,$05,$00,$E1,$C9                              ; $5AAC
        DEFW    SUB_0D20                 ; $5AB1
        DEFB    $E5,$21                                          ; $5AB3
        DEFW    SUB_0752_62              ; $5AB5
        DEFB    $36                                              ; $5AB7
        DEFW    SUB_22E1_2               ; $5AB8
        DEFW    SUB_0925_19              ; $5ABA
        DEFW    SUB_3D4E_9               ; $5ABC
        DEFB    $5B,$E1,$C4                                      ; $5ABE
        DEFW    SUB_58A4                 ; $5AC1
        DEFB    $AF,$32                                          ; $5AC3
        DEFW    SUB_0752_65              ; $5AC5
        DEFB    $E5,$21                                          ; $5AC7
        DEFW    SUB_0752_63              ; $5AC9
        DEFW    SUB_0752_21              ; $5ACB
        DEFB    $CD,$39                                          ; $5ACD
        DEFW    SUB_2124_8               ; $5ACF
        DEFW    SUB_0752_64              ; $5AD1
        DEFB    $0E,$03,$CD,$39,$5B,$11,$80,$00,$0E,$1A,$CD,$05,$00,$11 ; $5AD3
        DEFW    SUB_0752_62              ; $5AE1
        DEFW    SUB_101B_8               ; $5AE3
        DEFB    $CD,$05,$00,$FE,$FF,$CA                          ; $5AE5
        DEFW    SUB_0D20_11+1            ; $5AEB
SUB_5A3B_7:
        AND $03                          ; $5AED  E6 03
        ADD A,A                          ; $5AEF  87
        ADD A,A                          ; $5AF0  87
        ADD A,A                          ; $5AF1  87
        ADD A,A                          ; $5AF2  87
SUB_5A3B_8:
        ADD A,A                          ; $5AF3  87
        LD C,A                           ; $5AF4  4F
        LD B,$00                         ; $5AF5  06 00
        LD HL,$0081                      ; $5AF7  21 81 00
        ADD HL,BC                        ; $5AFA  09
        LD C,$0B                         ; $5AFB  0E 0B
SUB_5A3B_9:
        LD A,(HL)                        ; $5AFD  7E
        INC HL                           ; $5AFE  23
        CALL SUB_4291                    ; $5AFF  CD 91 42
        LD A,C                           ; $5B02  79
        CP $04                           ; $5B03  FE 04
        JR NZ,SUB_5A3B_12                ; $5B05  20 0A
        LD A,(HL)                        ; $5B07  7E
        CP $20                           ; $5B08  FE 20
SUB_5A3B_10:
        JR Z,SUB_5A3B_11                 ; $5B0A  28 02
        LD A,$2E                         ; $5B0C  3E 2E
SUB_5A3B_11:
        CALL SUB_4291                    ; $5B0E  CD 91 42
SUB_5A3B_12:
        DEC C                            ; $5B11  0D
        JR NZ,SUB_5A3B_9                 ; $5B12  20 E9
        LD A,(SUB_0B2A_2)                ; $5B14  3A 34 0B
        ADD A,$0F                        ; $5B17  C6 0F
        LD D,A                           ; $5B19  57
        LD A,(SUB_0752_36)               ; $5B1A  3A 5E 08
        CP D                             ; $5B1D  BA
        JR C,SUB_5B25_1                  ; $5B1E  38 08
        LD A,$20                         ; $5B20  3E 20
        CALL SUB_4291                    ; $5B22  CD 91 42
SUB_5B25:
        CALL SUB_4291                    ; $5B25  CD 91 42
SUB_5B25_1:
        CALL C,SUB_4406                  ; $5B28  DC 06 44
        LD DE,SUB_0752_62                ; $5B2B  11 CD 08
        LD C,$12                         ; $5B2E  0E 12
        CALL $0005                       ; $5B30  CD 05 00
        CP $FF                           ; $5B33  FE FF
        JR NZ,SUB_5A3B_7                 ; $5B35  20 B6
        POP HL                           ; $5B37  E1
        RET                              ; $5B38  C9
        DEFB    $7E,$FE,$2A,$C0,$36,$3F,$23,$0D                  ; $5B39  "~~*@6?#"
        DEFB    $20,$FA,$C9                                      ; $5B41
SUB_5B44:
        PUSH DE                          ; $5B44  D5
        LD C,A                           ; $5B45  4F
        PUSH BC                          ; $5B46  C5
        CALL $0005                       ; $5B47  CD 05 00
        POP BC                           ; $5B4A  C1
        POP DE                           ; $5B4B  D1
        PUSH AF                          ; $5B4C  F5
        LD HL,$0021                      ; $5B4D  21 21 00
        ADD HL,DE                        ; $5B50  19
        INC (HL)                         ; $5B51  34
        JR NZ,SUB_5B44_1                 ; $5B52  20 06
        INC HL                           ; $5B54  23
        INC (HL)                         ; $5B55  34
        JR NZ,SUB_5B44_1                 ; $5B56  20 02
        INC HL                           ; $5B58  23
        INC (HL)                         ; $5B59  34
SUB_5B44_1:
        LD A,C                           ; $5B5A  79
        CP $22                           ; $5B5B  FE 22
        JR NZ,SUB_5B44_2                 ; $5B5D  20 0F
        POP AF                           ; $5B5F  F1
        OR A                             ; $5B60  B7
        RET Z                            ; $5B61  C8
        CP $05                           ; $5B62  FE 05
        JP Z,SUB_0D20_17+1               ; $5B64  CA 85 0D
        CP $03                           ; $5B67  FE 03
        LD A,$01                         ; $5B69  3E 01
        RET Z                            ; $5B6B  C8
        INC A                            ; $5B6C  3C
        RET                              ; $5B6D  C9
SUB_5B44_2:
        POP AF                           ; $5B6E  F1
        RET                              ; $5B6F  C9
SUB_5B70:
        EX DE,HL                         ; $5B70  EB
        CALL SUB_5BA3                    ; $5B71  CD A3 5B
        LD HL,(SUB_0752_40)              ; $5B74  2A 63 08
        PUSH HL                          ; $5B77  E5
        LD BC,$002A                      ; $5B78  01 2A 00
        ADD HL,BC                        ; $5B7B  09
        CALL SUB_5808                    ; $5B7C  CD 08 58
        DEC DE                           ; $5B7F  1B
        POP HL                           ; $5B80  E1
        LD BC,$0021                      ; $5B81  01 21 00
        ADD HL,BC                        ; $5B84  09
        INC (HL)                         ; $5B85  34
SUB_5B70_1:
        CALL SUB_5BA3                    ; $5B86  CD A3 5B
        PUSH DE                          ; $5B89  D5
        LD C,$1A                         ; $5B8A  0E 1A
        CALL $0005                       ; $5B8C  CD 05 00
        LD HL,(SUB_0752_40)              ; $5B8F  2A 63 08
        INC HL                           ; $5B92  23
        EX DE,HL                         ; $5B93  EB
        LD C,$14                         ; $5B94  0E 14
        CALL $0005                       ; $5B96  CD 05 00
        OR A                             ; $5B99  B7
        POP DE                           ; $5B9A  D1
        LD HL,$0080                      ; $5B9B  21 80 00
        ADD HL,DE                        ; $5B9E  19
        RET NZ                           ; $5B9F  C0
        EX DE,HL                         ; $5BA0  EB
        JR SUB_5B70_1                    ; $5BA1  18 E3
SUB_5BA3:
        LD HL,(SUB_0B2A_19)              ; $5BA3  2A 6B 0B
        LD BC,$FF2A                      ; $5BA6  01 2A FF
        ADD HL,BC                        ; $5BA9  09
        CALL SUB_459D                    ; $5BAA  CD 9D 45
        RET NC                           ; $5BAD  D0
        JP SUB_5498_1                    ; $5BAE  C3 A1 54
SUB_5BB1:
        CP $03                           ; $5BB1  FE 03
        RET NZ                           ; $5BB3  C0
        DEC HL                           ; $5BB4  2B
        CALL SUB_13E4                    ; $5BB5  CD E4 13
        PUSH DE                          ; $5BB8  D5
        LD DE,$0080                      ; $5BB9  11 80 00
        JR Z,SUB_5BB1_1                  ; $5BBC  28 05
        PUSH BC                          ; $5BBE  C5
        CALL SUB_14E4                    ; $5BBF  CD E4 14
        POP BC                           ; $5BC2  C1
SUB_5BB1_1:
        PUSH HL                          ; $5BC3  E5
        LD HL,(L_0CBA)                   ; $5BC4  2A BA 0C
        CALL SUB_459D                    ; $5BC7  CD 9D 45
        JP C,SUB_14E4_2                  ; $5BCA  DA EB 14
        LD HL,$00A9                      ; $5BCD  21 A9 00
        ADD HL,BC                        ; $5BD0  09
        LD (HL),E                        ; $5BD1  73
        INC HL                           ; $5BD2  23
        LD (HL),D                        ; $5BD3  72
        XOR A                            ; $5BD4  AF
        LD E,$07                         ; $5BD5  1E 07
SUB_5BB1_2:
        INC HL                           ; $5BD7  23
        LD (HL),A                        ; $5BD8  77
        DEC E                            ; $5BD9  1D
        JR NZ,SUB_5BB1_2                 ; $5BDA  20 FB
        POP HL                           ; $5BDC  E1
        POP DE                           ; $5BDD  D1
        RET                              ; $5BDE  C9
        DEFB    $F6,$AF                                          ; $5BDF
        DEFW    SUB_3A18_2               ; $5BE1
        DEFB    $5E,$CC                                          ; $5BE3
        DEFW    SUB_0FAB_4               ; $5BE5
        DEFB    $CD                                              ; $5BE7
        DEFW    SUB_52A9                 ; $5BE8
SUB_5BB1_3:
        CP $03                           ; $5BEA  FE 03
        JP NZ,SUB_0D20_10+1              ; $5BEC  C2 6A 0D
        DEFB    $C5,$E5,$21,$AD,$00                              ; $5BEF  "Ee!-"
        DEFB    $09                                              ; $5BF4
        DEFW    SUB_22E1_15              ; $5BF5
        DEFB    $56,$13,$E3,$7E                                  ; $5BF7
        DEFW    SUB_2CF8_1               ; $5BFB
        DEFB    $CC                                              ; $5BFD
        DEFW    SUB_14E4                 ; $5BFE
        DEFB    $2B,$CD                                          ; $5C00
        DEFW    SUB_13E4                 ; $5C02
        DEFB    $C2                                              ; $5C04
        DEFW    SUB_0D20_20              ; $5C05
        DEFB    $E3,$7B,$B2,$CA,$7F,$0D,$2B,$73,$23              ; $5C07
        DEFW    SUB_1A93_18              ; $5C10
        DEFB    $E1,$C1,$E5,$C5,$21,$B0,$00                      ; $5C12  "aAeE!0"
        DEFB    $09                                              ; $5C19
        DEFB    $AF,$77,$23,$77,$21,$A9,$00                      ; $5C1A  "/w#w!)"
        DEFB    $09                                              ; $5C21
        DEFB    $7E,$23,$66,$6F,$EB,$D5,$E5,$21,$80              ; $5C22  "~#fokUe!"
        DEFB    $00,$CD                                          ; $5C2B
        DEFW    SUB_459D                 ; $5C2D
        DEFB    $E1,$20,$05,$11,$00                              ; $5C2F
        DEFW    SUB_15CF_28              ; $5C34
        DEFB    $38,$42                                          ; $5C36
        DEFW    SUB_3D4E_25              ; $5C38
        DEFB    $10,$EB,$21,$00,$00                              ; $5C3A
        DEFW    SUB_2990_9               ; $5C3F
        DEFB    $E3                                              ; $5C41
        DEFW    SUB_0100_31              ; $5C42
        DEFW    SUB_22E1_7               ; $5C44
        DEFW    SUB_0100_6               ; $5C46
        DEFB    $29,$E3                                          ; $5C48
        DEFW    SUB_29E8_1               ; $5C4A
        DEFB    $EB,$30                                          ; $5C4C
        DEFW    SUB_0752_71              ; $5C4E
        DEFB    $E3,$30                                          ; $5C50
        DEFW    SUB_22E1_3               ; $5C52
        DEFW    SUB_3D4E_13              ; $5C54
        DEFB    $20,$E8,$7D,$E6,$7F                              ; $5C56
        DEFW    SUB_15CF_19              ; $5C5B
        DEFB    $00,$C1,$7D,$6C,$61,$29,$DA                      ; $5C5D
        DEFW    SUB_14E4_2               ; $5C64
        DEFW    SUB_3006_1               ; $5C66
        DEFW    SUB_22E1_3               ; $5C68
        DEFB    $78,$B7,$C2                                      ; $5C6A
        DEFW    SUB_14E4_2               ; $5C6D
        DEFB    $22,$34,$5E,$E1,$C1,$E5,$21,$B2,$00              ; $5C6F  ""4^aAe!2"
        DEFB    $09                                              ; $5C78
        DEFB    $22,$36,$5E,$21,$29,$00                          ; $5C79  ""6^!)"
        DEFB    $09,$19                                          ; $5C7F
        DEFB    $22,$38,$5E,$E1,$E5,$21,$80                      ; $5C81  ""8^ae!"
        DEFB    $00,$7D,$93,$6F,$7C,$9A,$67,$D1,$D5,$CD          ; $5C88
        DEFW    SUB_459D                 ; $5C92
        DEFW    SUB_0100_25              ; $5C94
        DEFB    $62                                              ; $5C96
        DEFW    SUB_3A18_6               ; $5C97
        DEFW    SUB_5E2A_4               ; $5C99
        DEFW    SUB_2874_11              ; $5C9B
        DEFW    SUB_1128_5               ; $5C9D
        DEFB    $80,$00,$CD                                      ; $5C9F
        DEFW    SUB_459D                 ; $5CA2
        DEFB    $30,$05,$E5,$CD,$F5,$5C,$E1                      ; $5CA4
        DEFW    SUB_44C2_1               ; $5CAB
        DEFW    SUB_29E8_12              ; $5CAD
        DEFW    SUB_5E2A_3               ; $5CAF
        DEFW    SUB_2AEB                 ; $5CB1
        DEFW    SUB_5E2A_2               ; $5CB3
        DEFW    SUB_2AC5_2               ; $5CB5
        DEFW    SUB_21FC_10              ; $5CB7
        DEFW    SUB_5E2A_2               ; $5CB9
        DEFW    SUB_58FE_6               ; $5CBB
        DEFB    $C1,$CD,$F4,$5C,$E1,$7D,$93,$6F,$7C,$9A,$67      ; $5CBD
        DEFW    SUB_1128_14              ; $5CC8
        DEFB    $00,$00,$E5,$2A                                  ; $5CCA
        DEFW    SUB_5E2A_1               ; $5CCE
        DEFW    SUB_21FC_4               ; $5CD0
        DEFW    SUB_5E2A_1               ; $5CD2
        DEFB    $20,$A6,$E1,$E1,$C9,$E5,$CD,$F5,$5C,$E1          ; $5CD4
        DEFW    SUB_44C2_1               ; $5CDE
        DEFW    SUB_29E8_12              ; $5CE0
        DEFW    SUB_5E2A_2               ; $5CE2
        DEFW    SUB_2AEB                 ; $5CE4
        DEFW    SUB_5E2A_3               ; $5CE6
        DEFW    SUB_2AC5_2               ; $5CE8
        DEFB    $5D,$EB,$22                                      ; $5CEA
        DEFW    SUB_5E2A_2               ; $5CED
        DEFW    SUB_58FE_6               ; $5CEF
        DEFW    SUB_189A_4               ; $5CF1
        DEFB    $CD,$F6,$AF,$32                                  ; $5CF3
        DEFW    SUB_0752_48              ; $5CF7
        DEFB    $C5,$D5,$E5,$2A,$34,$5E,$EB,$21,$AB,$00          ; $5CF9  "EUe*4^k!+"
        DEFB    $09,$E5,$7E,$23,$66                              ; $5D03
        DEFW    SUB_129A_12              ; $5D08
        DEFB    $CD                                              ; $5D0A
        DEFW    SUB_459D                 ; $5D0B
SUB_5D0D:
        POP HL                           ; $5D0D  E1
        LD (HL),E                        ; $5D0E  73
        INC HL                           ; $5D0F  23
        LD (HL),D                        ; $5D10  72
        JR NZ,SUB_5D0D_1                 ; $5D11  20 06
        LD A,(SUB_0752_48)               ; $5D13  3A 6F 08
        OR A                             ; $5D16  B7
        JR Z,SUB_5D26                    ; $5D17  28 0D
SUB_5D0D_1:
        LD HL,SUB_5D26                   ; $5D19  21 26 5D
        PUSH HL                          ; $5D1C  E5
        PUSH BC                          ; $5D1D  C5
        PUSH HL                          ; $5D1E  E5
        LD HL,$0026                      ; $5D1F  21 26 00
        ADD HL,BC                        ; $5D22  09
        JP SUB_57A0_4                    ; $5D23  C3 DB 57
SUB_5D26:
        POP HL                           ; $5D26  E1
        POP DE                           ; $5D27  D1
        POP BC                           ; $5D28  C1
        RET                              ; $5D29  C9
SUB_5D26_1:
        PUSH BC                          ; $5D2A  C5
SUB_5D26_2:
        LD A,(HL)                        ; $5D2B  7E
        LD (DE),A                        ; $5D2C  12
        INC HL                           ; $5D2D  23
        INC DE                           ; $5D2E  13
        DEC BC                           ; $5D2F  0B
        LD A,B                           ; $5D30  78
        OR C                             ; $5D31  B1
SUB_5D26_3:
        JR NZ,SUB_5D26_2                 ; $5D32  20 F7
        POP BC                           ; $5D34  C1
        RET                              ; $5D35  C9
SUB_5D26_4:
        POP AF                           ; $5D36  F1
        PUSH DE                          ; $5D37  D5
        PUSH BC                          ; $5D38  C5
        PUSH AF                          ; $5D39  F5
        LD B,H                           ; $5D3A  44
        LD C,L                           ; $5D3B  4D
        CALL SUB_5D90                    ; $5D3C  CD 90 5D
        JP Z,SUB_0D20_16+1               ; $5D3F  CA 82 0D
SUB_5D26_5:
        CALL SUB_5D85                    ; $5D42  CD 85 5D
        LD HL,$00B1                      ; $5D45  21 B1 00
        ADD HL,BC                        ; $5D48  09
        ADD HL,DE                        ; $5D49  19
        POP AF                           ; $5D4A  F1
        LD (HL),A                        ; $5D4B  77
        PUSH AF                          ; $5D4C  F5
        LD HL,$0028                      ; $5D4D  21 28 00
        ADD HL,BC                        ; $5D50  09
        LD D,(HL)                        ; $5D51  56
        LD (HL),$00                      ; $5D52  36 00
SUB_5D26_6:
        CP $0D                           ; $5D54  FE 0D
        JR Z,SUB_5D26_7                  ; $5D56  28 06
        ADD A,$E0                        ; $5D58  C6 E0
        LD A,D                           ; $5D5A  7A
        ADC A,$00                        ; $5D5B  CE 00
        LD (HL),A                        ; $5D5D  77
SUB_5D26_7:
        POP AF                           ; $5D5E  F1
        POP BC                           ; $5D5F  C1
        POP DE                           ; $5D60  D1
        POP HL                           ; $5D61  E1
        RET                              ; $5D62  C9
SUB_5D26_8:
        PUSH DE                          ; $5D63  D5
        CALL SUB_5D8E                    ; $5D64  CD 8E 5D
        JP Z,SUB_0D20_16+1               ; $5D67  CA 82 0D
        CALL SUB_5D85                    ; $5D6A  CD 85 5D
        LD HL,$00B1                      ; $5D6D  21 B1 00
        ADD HL,BC                        ; $5D70  09
        ADD HL,DE                        ; $5D71  19
        LD A,(HL)                        ; $5D72  7E
        OR A                             ; $5D73  B7
        POP DE                           ; $5D74  D1
        POP HL                           ; $5D75  E1
        POP BC                           ; $5D76  C1
        RET                              ; $5D77  C9
SUB_5D78:
        LD HL,$00A9                      ; $5D78  21 A9 00
        JR SUB_5D7D_1                    ; $5D7B  18 03
SUB_5D7D:
        LD HL,$00B0                      ; $5D7D  21 B0 00
SUB_5D7D_1:
        ADD HL,BC                        ; $5D80  09
        LD E,(HL)                        ; $5D81  5E
        INC HL                           ; $5D82  23
        LD D,(HL)                        ; $5D83  56
        RET                              ; $5D84  C9
SUB_5D85:
        INC DE                           ; $5D85  13
        LD HL,$00B0                      ; $5D86  21 B0 00
        ADD HL,BC                        ; $5D89  09
        LD (HL),E                        ; $5D8A  73
        INC HL                           ; $5D8B  23
        LD (HL),D                        ; $5D8C  72
        RET                              ; $5D8D  C9
SUB_5D8E:
        LD B,H                           ; $5D8E  44
        LD C,L                           ; $5D8F  4D
SUB_5D90:
        CALL SUB_5D7D                    ; $5D90  CD 7D 5D
        PUSH DE                          ; $5D93  D5
        CALL SUB_5D78                    ; $5D94  CD 78 5D
        EX DE,HL                         ; $5D97  EB
        POP DE                           ; $5D98  D1
        CALL SUB_459D                    ; $5D99  CD 9D 45
        RET                              ; $5D9C  C9
SUB_5D90_1:
        CALL SUB_13E4                    ; $5D9D  CD E4 13
        LD (SUB_0B2A_25),HL              ; $5DA0  22 77 0B
        CALL SUB_22E1_18                 ; $5DA3  CD 8D 23
        CALL SUB_5DB4                    ; $5DA6  CD B4 5D
        LD A,$FE                         ; $5DA9  3E FE
        CALL SUB_5503                    ; $5DAB  CD 03 55
        CALL SUB_5DEB                    ; $5DAE  CD EB 5D
        JP SUB_453A_6                    ; $5DB1  C3 99 45
SUB_5DB4:
        LD BC,SUB_0D04_2                 ; $5DB4  01 0B 0D
        LD HL,(SUB_0752_44)              ; $5DB7  2A 69 08
        EX DE,HL                         ; $5DBA  EB
        LD HL,(SUB_0B2A_40)              ; $5DBB  2A 92 0B
        CALL SUB_459D                    ; $5DBE  CD 9D 45
        RET Z                            ; $5DC1  C8
        LD HL,L_3B80                     ; $5DC2  21 80 3B
        LD A,L                           ; $5DC5  7D
        ADD A,C                          ; $5DC6  81
        LD L,A                           ; $5DC7  6F
        LD A,H                           ; $5DC8  7C
        ADC A,$00                        ; $5DC9  CE 00
        LD H,A                           ; $5DCB  67
        LD A,(DE)                        ; $5DCC  1A
        SUB B                            ; $5DCD  90
        DEFB    $AE,$F5,$21,$30,$3B,$7D,$80                      ; $5DCE  ".u!0;}"
        DEFB    $6F,$7C,$CE,$00,$67,$F1,$AE                      ; $5DD5
        DEFW    SUB_124F_6               ; $5DDC
        DEFW    SUB_0D04_4               ; $5DDE
        DEFW    SUB_0100_22              ; $5DE0
        DEFW    SUB_0925_19              ; $5DE2
        DEFB    $05,$20                                          ; $5DE4
        DEFW    SUB_064E_6               ; $5DE6
        DEFW    SUB_15CF_30              ; $5DE8
        DEFB    $D0                                              ; $5DEA
SUB_5DEB:
        LD BC,SUB_0D04_2                 ; $5DEB  01 0B 0D
        LD HL,(SUB_0752_44)              ; $5DEE  2A 69 08
        EX DE,HL                         ; $5DF1  EB
SUB_5DEB_1:
        LD HL,(SUB_0B2A_40)              ; $5DF2  2A 92 0B
        CALL SUB_459D                    ; $5DF5  CD 9D 45
        RET Z                            ; $5DF8  C8
        LD HL,L_3B30                     ; $5DF9  21 30 3B
        LD A,L                           ; $5DFC  7D
        ADD A,B                          ; $5DFD  80
        LD L,A                           ; $5DFE  6F
        LD A,H                           ; $5DFF  7C
        ADC A,$00                        ; $5E00  CE 00
        LD H,A                           ; $5E02  67
        LD A,(DE)                        ; $5E03  1A
        SUB C                            ; $5E04  91
        XOR (HL)                         ; $5E05  AE
        PUSH AF                          ; $5E06  F5
        LD HL,L_3B80                     ; $5E07  21 80 3B
        LD A,L                           ; $5E0A  7D
        ADD A,C                          ; $5E0B  81
        LD L,A                           ; $5E0C  6F
        LD A,H                           ; $5E0D  7C
        ADC A,$00                        ; $5E0E  CE 00
        LD H,A                           ; $5E10  67
        POP AF                           ; $5E11  F1
        XOR (HL)                         ; $5E12  AE
        ADD A,B                          ; $5E13  80
        LD (DE),A                        ; $5E14  12
        INC DE                           ; $5E15  13
        DEC C                            ; $5E16  0D
        JR NZ,SUB_5DEB_2                 ; $5E17  20 02
        LD C,$0B                         ; $5E19  0E 0B
SUB_5DEB_2:
        DJNZ SUB_5DEB_1                  ; $5E1B  10 D5
        LD B,$0D                         ; $5E1D  06 0D
        JR SUB_5DEB_1                    ; $5E1F  18 D1
SUB_5E21:
        PUSH HL                          ; $5E21  E5
        LD HL,(SUB_0752_43)              ; $5E22  2A 67 08
        LD A,H                           ; $5E25  7C
        AND L                            ; $5E26  A5
SUB_5E27:
        POP HL                           ; $5E27  E1
        INC A                            ; $5E28  3C
        RET NZ                           ; $5E29  C0
SUB_5E2A:
        PUSH AF                          ; $5E2A  F5
        LD A,(L_0CBC)                    ; $5E2B  3A BC 0C
        OR A                             ; $5E2E  B7
        JP NZ,SUB_14E4_2                 ; $5E2F  C2 EB 14
        POP AF                           ; $5E32  F1
        RET                              ; $5E33  C9
SUB_5E2A_1:
        NOP                              ; $5E34  00
        NOP                              ; $5E35  00
SUB_5E2A_2:
        NOP                              ; $5E36  00
        NOP                              ; $5E37  00
SUB_5E2A_3:
        NOP                              ; $5E38  00
        NOP                              ; $5E39  00
SUB_5E2A_4:
        NOP                              ; $5E3A  00
SUB_5E2A_5:
        CALL SUB_44E0                    ; $5E3B  CD E0 44
        LD HL,(SUB_0752_44)              ; $5E3E  2A 69 08
        DEC HL                           ; $5E41  2B
        LD (HL),$00                      ; $5E42  36 00
        LD HL,(SUB_5E51_13)              ; $5E44  2A CE 5F
        LD A,(HL)                        ; $5E47  7E
        OR A                             ; $5E48  B7
        JP NZ,SUB_53F7_2                 ; $5E49  C2 FD 53
        JP SUB_0D20_39                   ; $5E4C  C3 46 0E
SUB_5E2A_6:
        NOP                              ; $5E4F  00
        NOP                              ; $5E50  00
SUB_5E51:
        LD HL,$6146                      ; $5E51  21 46 61
        LD SP,HL                         ; $5E54  F9
        XOR A                            ; $5E55  AF
        LD (L_0CBC),A                    ; $5E56  32 BC 0C
        LD (SUB_0752_42),HL              ; $5E59  22 65 08
        LD (SUB_0B2A_31),HL              ; $5E5C  22 81 0B
        LD HL,($0001)                    ; $5E5F  2A 01 00
        LD (SUB_5A3B_5+1),HL             ; $5E62  22 6C 5A
        LD A,H                           ; $5E65  7C
        LD (SUB_0100_3),A                ; $5E66  32 07 01
        LD BC,$0004                      ; $5E69  01 04 00
        ADD HL,BC                        ; $5E6C  09
        LD E,(HL)                        ; $5E6D  5E
        INC HL                           ; $5E6E  23
        LD D,(HL)                        ; $5E6F  56
        EX DE,HL                         ; $5E70  EB
        LD (SUB_4437_3+1),HL             ; $5E71  22 54 44
        LD (SUB_442C_1+1),HL             ; $5E74  22 30 44
        LD (SUB_129A_15+1),HL            ; $5E77  22 88 13
        EX DE,HL                         ; $5E7A  EB
        INC HL                           ; $5E7B  23
        INC HL                           ; $5E7C  23
        LD E,(HL)                        ; $5E7D  5E
        INC HL                           ; $5E7E  23
        LD D,(HL)                        ; $5E7F  56
        EX DE,HL                         ; $5E80  EB
        LD (SUB_43DA_1+1),HL             ; $5E81  22 DE 43
        EX DE,HL                         ; $5E84  EB
        INC HL                           ; $5E85  23
        INC HL                           ; $5E86  23
        LD E,(HL)                        ; $5E87  5E
        INC HL                           ; $5E88  23
        LD D,(HL)                        ; $5E89  56
        EX DE,HL                         ; $5E8A  EB
        LD (SUB_4382_1+1),HL             ; $5E8B  22 88 43
        EX DE,HL                         ; $5E8E  EB
        INC HL                           ; $5E8F  23
        INC HL                           ; $5E90  23
        LD E,(HL)                        ; $5E91  5E
        INC HL                           ; $5E92  23
        LD D,(HL)                        ; $5E93  56
        EX DE,HL                         ; $5E94  EB
        LD (SUB_42EA_1+1),HL             ; $5E95  22 F0 42
        EX DE,HL                         ; $5E98  EB
        LD DE,$F1F8                      ; $5E99  11 F8 F1
        ADD HL,DE                        ; $5E9C  19
        LD DE,L_27F8                     ; $5E9D  11 F8 27
        LD (HL),E                        ; $5EA0  73
        INC HL                           ; $5EA1  23
        LD (HL),D                        ; $5EA2  72
        INC HL                           ; $5EA3  23
        LD DE,L_27FE                     ; $5EA4  11 FE 27
        LD (HL),E                        ; $5EA7  73
        INC HL                           ; $5EA8  23
        LD (HL),D                        ; $5EA9  72
        INC HL                           ; $5EAA  23
        LD DE,L_27FB                     ; $5EAB  11 FB 27
        LD (HL),E                        ; $5EAE  73
        INC HL                           ; $5EAF  23
        LD (HL),D                        ; $5EB0  72
        INC HL                           ; $5EB1  23
        LD DE,L_2801                     ; $5EB2  11 01 28
        LD (HL),E                        ; $5EB5  73
        INC HL                           ; $5EB6  23
        LD (HL),D                        ; $5EB7  72
        LD HL,L_27F5                     ; $5EB8  21 F5 27
        LD ($0001),HL                    ; $5EBB  22 01 00
        LD HL,($F3DE)                    ; $5EBE  2A DE F3
        LD (SUB_2602_1+1),HL             ; $5EC1  22 06 26
        LD C,$0C                         ; $5EC4  0E 0C
        CALL $0005                       ; $5EC6  CD 05 00
        LD (SUB_0752_66),A               ; $5EC9  32 EE 08
        OR A                             ; $5ECC  B7
        LD HL,SUB_1506_1+2               ; $5ECD  21 14 15
        JP Z,SUB_5E51_1                  ; $5ED0  CA D6 5E
        LD HL,SUB_21FC_3+1               ; $5ED3  21 21 22
SUB_5E51_1:
        LD (SUB_0752_67),HL              ; $5ED6  22 EF 08
        LD HL,$FFFE                      ; $5ED9  21 FE FF
        LD (SUB_0752_43),HL              ; $5EDC  22 67 08
        XOR A                            ; $5EDF  AF
        LD (SUB_0752_39),A               ; $5EE0  32 62 08
        LD (SUB_0B2A_1),A                ; $5EE3  32 33 0B
        LD (L_0CC3),A                    ; $5EE6  32 C3 0C
        LD (L_0CBD),A                    ; $5EE9  32 BD 0C
        LD (SUB_0752_33+2),A             ; $5EEC  32 58 08
        LD HL,$0000                      ; $5EEF  21 00 00
        LD (SUB_0752_34),HL              ; $5EF2  22 5A 08
        LD ($F030),A                     ; $5EF5  32 30 F0
        LD A,($F3BB)                     ; $5EF8  3A BB F3
        SUB $03                          ; $5EFB  D6 03
        JR Z,SUB_5E51_2+1                ; $5EFD  28 06
        DEC A                            ; $5EFF  3D
        JR Z,SUB_5E51_2+1                ; $5F00  28 03
        LD A,$28                         ; $5F02  3E 28
SUB_5E51_2:
        LD BC,SUB_503E                   ; $5F04  01 3E 50
        LD (SUB_2803_4),A                ; $5F07  32 15 28
        CALL SUB_207E                    ; $5F0A  CD 7E 20
        LD HL,$0080                      ; $5F0D  21 80 00
        LD (L_0CBA),HL                   ; $5F10  22 BA 0C
        LD HL,SUB_0B2A_15                ; $5F13  21 4A 0B
        LD (SUB_0B2A_14),HL              ; $5F16  22 48 0B
        LD HL,SUB_0B2A_45                ; $5F19  21 B4 0B
        LD (SUB_0C03_1),HL               ; $5F1C  22 1C 0C
        LD HL,($0006)                    ; $5F1F  2A 06 00
        LD (SUB_0B2A_13),HL              ; $5F22  22 46 0B
        LD A,$03                         ; $5F25  3E 03
        LD (SUB_0752_55),A               ; $5F27  32 93 08
        LD HL,SUB_5E51_12                ; $5F2A  21 CD 5F
        LD (SUB_5E51_13),HL              ; $5F2D  22 CE 5F
        LD A,(SUB_5E51_14)               ; $5F30  3A D0 5F
        OR A                             ; $5F33  B7
        JP NZ,SUB_5E51_15                ; $5F34  C2 D1 5F
        INC A                            ; $5F37  3C
        LD (SUB_5E51_14),A               ; $5F38  32 D0 5F
        LD HL,$0080                      ; $5F3B  21 80 00
        LD A,(HL)                        ; $5F3E  7E
        OR A                             ; $5F3F  B7
        LD (SUB_5E51_13),HL              ; $5F40  22 CE 5F
        JP Z,SUB_5E51_15                 ; $5F43  CA D1 5F
        LD B,(HL)                        ; $5F46  46
        INC HL                           ; $5F47  23
SUB_5E51_3:
        LD A,(HL)                        ; $5F48  7E
        DEC HL                           ; $5F49  2B
        LD (HL),A                        ; $5F4A  77
        INC HL                           ; $5F4B  23
        INC HL                           ; $5F4C  23
        DEC B                            ; $5F4D  05
        JP NZ,SUB_5E51_3                 ; $5F4E  C2 48 5F
        DEC HL                           ; $5F51  2B
        LD (HL),$00                      ; $5F52  36 00
        LD (SUB_5E51_13),HL              ; $5F54  22 CE 5F
        LD HL,$007F                      ; $5F57  21 7F 00
        CALL SUB_13E4                    ; $5F5A  CD E4 13
        OR A                             ; $5F5D  B7
        JP Z,SUB_5E51_15                 ; $5F5E  CA D1 5F
        CP $2F                           ; $5F61  FE 2F
        JR Z,SUB_5E51_5                  ; $5F63  28 14
        DEC HL                           ; $5F65  2B
        LD (HL),$22                      ; $5F66  36 22
        LD (SUB_5E51_13),HL              ; $5F68  22 CE 5F
        INC HL                           ; $5F6B  23
SUB_5E51_4:
        CP $2F                           ; $5F6C  FE 2F
        JR Z,SUB_5E51_5                  ; $5F6E  28 09
        CALL SUB_13E4                    ; $5F70  CD E4 13
        OR A                             ; $5F73  B7
        JR NZ,SUB_5E51_4                 ; $5F74  20 F6
        JP SUB_5E51_15                   ; $5F76  C3 D1 5F
SUB_5E51_5:
        LD (HL),$00                      ; $5F79  36 00
        CALL SUB_13E4                    ; $5F7B  CD E4 13
SUB_5E51_6:
        CP $53                           ; $5F7E  FE 53
        JR Z,SUB_5E51_11                 ; $5F80  28 3A
        CP $4D                           ; $5F82  FE 4D
        PUSH AF                          ; $5F84  F5
        JP Z,SUB_5E51_7                  ; $5F85  CA 8D 5F
        CP $46                           ; $5F88  FE 46
        JP NZ,SUB_0D20_20                ; $5F8A  C2 92 0D
SUB_5E51_7:
        CALL SUB_13E4                    ; $5F8D  CD E4 13
        CALL SUB_45A3                    ; $5F90  CD A3 45
SUB_5E51_8:
        LD A,($F1CD)                     ; $5F93  3A CD F1
        INC E                            ; $5F96  1C
        POP AF                           ; $5F97  F1
        JR Z,SUB_5E51_9                  ; $5F98  28 10
        LD A,D                           ; $5F9A  7A
        OR A                             ; $5F9B  B7
        JP NZ,SUB_14E4_2                 ; $5F9C  C2 EB 14
        LD A,E                           ; $5F9F  7B
        CP $10                           ; $5FA0  FE 10
        JP NC,SUB_14E4_2                 ; $5FA2  D2 EB 14
        LD (SUB_0752_55),A               ; $5FA5  32 93 08
        JR SUB_5E51_10                   ; $5FA8  18 05
SUB_5E51_9:
        EX DE,HL                         ; $5FAA  EB
        LD (SUB_0B2A_13),HL              ; $5FAB  22 46 0B
        EX DE,HL                         ; $5FAE  EB
SUB_5E51_10:
        DEC HL                           ; $5FAF  2B
        CALL SUB_13E4                    ; $5FB0  CD E4 13
        JR Z,SUB_5E51_15                 ; $5FB3  28 1C
        CALL SUB_45A3                    ; $5FB5  CD A3 45
        CPL                              ; $5FB8  2F
        JP SUB_5E51_6                    ; $5FB9  C3 7E 5F
SUB_5E51_11:
        CALL SUB_13E4                    ; $5FBC  CD E4 13
        CALL SUB_45A3                    ; $5FBF  CD A3 45
        LD A,($F1CD)                     ; $5FC2  3A CD F1
        INC E                            ; $5FC5  1C
        EX DE,HL                         ; $5FC6  EB
        LD (L_0CBA),HL                   ; $5FC7  22 BA 0C
        EX DE,HL                         ; $5FCA  EB
        JR SUB_5E51_10                   ; $5FCB  18 E2
SUB_5E51_12:
        NOP                              ; $5FCD  00
SUB_5E51_13:
        NOP                              ; $5FCE  00
        NOP                              ; $5FCF  00
SUB_5E51_14:
        NOP                              ; $5FD0  00
SUB_5E51_15:
        DEC HL                           ; $5FD1  2B
        LD HL,(SUB_0B2A_13)              ; $5FD2  2A 46 0B
        PUSH HL                          ; $5FD5  E5
        POP HL                           ; $5FD6  E1
        DEC HL                           ; $5FD7  2B
        LD (SUB_0B2A_13),HL              ; $5FD8  22 46 0B
        DEC HL                           ; $5FDB  2B
        PUSH HL                          ; $5FDC  E5
        LD A,(SUB_0752_55)               ; $5FDD  3A 93 08
        LD HL,SUB_5E2A_6                 ; $5FE0  21 4F 5E
        LD (SUB_0752_49),HL              ; $5FE3  22 71 08
        LD DE,SUB_0752_51                ; $5FE6  11 73 08
        LD (SUB_0752_55),A               ; $5FE9  32 93 08
        INC A                            ; $5FEC  3C
        LD BC,$00A9                      ; $5FED  01 A9 00
SUB_5E51_16:
        EX DE,HL                         ; $5FF0  EB
        LD (HL),E                        ; $5FF1  73
        INC HL                           ; $5FF2  23
        LD (HL),D                        ; $5FF3  72
        INC HL                           ; $5FF4  23
        EX DE,HL                         ; $5FF5  EB
        ADD HL,BC                        ; $5FF6  09
        PUSH HL                          ; $5FF7  E5
        LD HL,(L_0CBA)                   ; $5FF8  2A BA 0C
        LD BC,$00B2                      ; $5FFB  01 B2 00
        ADD HL,BC                        ; $5FFE  09
        LD B,H                           ; $5FFF  44
        LD C,L                           ; $6000  4D
        POP HL                           ; $6001  E1
        DEC A                            ; $6002  3D
        JR NZ,SUB_5E51_16                ; $6003  20 EB
        INC HL                           ; $6005  23
        LD (SUB_0752_44),HL              ; $6006  22 69 08
        LD (SUB_0B2A_31),HL              ; $6009  22 81 0B
        POP DE                           ; $600C  D1
        LD A,E                           ; $600D  7B
        SUB L                            ; $600E  95
        LD L,A                           ; $600F  6F
        LD A,D                           ; $6010  7A
        SBC A,H                          ; $6011  9C
        LD H,A                           ; $6012  67
SUB_5E51_17:
        JP C,SUB_449F_1                  ; $6013  DA B4 44
        LD B,$03                         ; $6016  06 03
SUB_5E51_18:
        OR A                             ; $6018  B7
        LD A,H                           ; $6019  7C
        RRA                              ; $601A  1F
        LD H,A                           ; $601B  67
        LD A,L                           ; $601C  7D
        RRA                              ; $601D  1F
        LD L,A                           ; $601E  6F
        DJNZ SUB_5E51_18                 ; $601F  10 F7
        LD A,H                           ; $6021  7C
        CP $02                           ; $6022  FE 02
        JR C,SUB_5E51_19                 ; $6024  38 03
        LD HL,SUB_0100_20                ; $6026  21 00 02
SUB_5E51_19:
        LD A,E                           ; $6029  7B
        SUB L                            ; $602A  95
        LD L,A                           ; $602B  6F
        LD A,D                           ; $602C  7A
        SBC A,H                          ; $602D  9C
        LD H,A                           ; $602E  67
        JP C,SUB_449F_1                  ; $602F  DA B4 44
        LD (SUB_0B2A_13),HL              ; $6032  22 46 0B
        EX DE,HL                         ; $6035  EB
        LD (SUB_0752_42),HL              ; $6036  22 65 08
        LD (SUB_0B2A_19),HL              ; $6039  22 6B 0B
        LD SP,HL                         ; $603C  F9
        LD (SUB_0B2A_31),HL              ; $603D  22 81 0B
        LD HL,(SUB_0752_44)              ; $6040  2A 69 08
        EX DE,HL                         ; $6043  EB
        CALL SUB_44C2                    ; $6044  CD C2 44
        LD A,L                           ; $6047  7D
        SUB E                            ; $6048  93
        LD L,A                           ; $6049  6F
        LD A,H                           ; $604A  7C
        SBC A,D                          ; $604B  9A
        LD H,A                           ; $604C  67
        DEC HL                           ; $604D  2B
        DEC HL                           ; $604E  2B
        PUSH HL                          ; $604F  E5
        CALL SUB_25C3                    ; $6050  CD C3 25
        LD HL,L_609B                     ; $6053  21 9B 60
        CALL SUB_48BE                    ; $6056  CD BE 48
        POP HL                           ; $6059  E1
        CALL SUB_3391                    ; $605A  CD 91 33
        LD HL,L_608D                     ; $605D  21 8D 60
        CALL SUB_48BE                    ; $6060  CD BE 48
        LD HL,SUB_48BE                   ; $6063  21 BE 48
        LD (SUB_0D20_40+1),HL            ; $6066  22 57 0E
        CALL SUB_4406                    ; $6069  CD 06 44
        LD HL,SUB_0D20_5                 ; $606C  21 4B 0D
        LD (SUB_0100+1),HL               ; $606F  22 01 01
        JP SUB_5E2A_5                    ; $6072  C3 3B 5E
        DEFW    SUB_0925_7               ; $6075
        DEFB    $0A                                              ; $6077
        DEFB    "Owned by Microsoft"    ; $6078  string
        DEFB    $0D    ; $608A  terminator
        DEFB    $0A,$00                                          ; $608B
L_608D:
        DEFB    " Bytes free"    ; $608D  string
        DEFB    $0D    ; $6098  terminator
        DEFB    $0A,$00                                          ; $6099
L_609B:
        DEFW    SUB_0925_7               ; $609B
        DEFW    SUB_0925_7               ; $609D
        DEFW    SUB_0925_7               ; $609F
        DEFB    "BASIC-80 Rev. 5.2"    ; $60A1  string
        DEFB    $0D    ; $60B2  terminator
        DEFW    SUB_5A3B_10              ; $60B3
        DEFB    "Apple CP/M Version]"    ; $60B5  string
        DEFB    $0D    ; $60C8  terminator
        DEFW    SUB_4300_1               ; $60C9
        DEFB    "opyright (C) 1980 by Microsoft"    ; $60CB  string
        DEFB    $0D    ; $60E9  terminator
        DEFW    SUB_4300_1               ; $60EA
        DEFB    "reated: 26-Aug-80"    ; $60EC  string
        DEFB    $0D    ; $60FD  terminator
        DEFB    $0A,$00                                          ; $60FE

    SAVEBIN "MBASIC.bin", $0100, $6000
