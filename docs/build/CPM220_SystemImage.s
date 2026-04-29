; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- System Image (CCP + BDOS, 5888 bytes)
; Annotated Z-80 assembly source for 2.20's CP/M 2.0 system image.
;
; STRUCTURE
;   Same overall shape as 2.23's sysimg but Digital Research CP/M 2.0
;   underneath instead of 2.2. The two differ in 5807 of 5888 bytes
;   (98.6%) -- mostly because 2.0 -> 2.2 is a substantial BDOS rewrite,
;   plus absolute-address relocation differences.
;
;   $8000-$80C7  CCP entry + initial dispatch
;   $80C7-$80DC  CCP built-in command table ("DIR ERA TYPE SAVE REN USER")
;   $80DD-$..    CCP body
;   $..-$96FF    BDOS body + various scratch (no boot banner; 2.20's
;                sysimg ends in $E5 filler instead)
;
; KEY DIFFERENCES FROM 2.23
;   - Underlying CP/M 2.0 instead of 2.2 -- 98.6% byte-different
;   - No boot banner string (last 64 bytes are $E5 filler)
;   - BDOS final position $CC06 in 2.20 vs $9C06 in 2.23 -- a 12 KB
;     relocation shift between the two builds
;
; PRACTICAL NOTE
;   Per-instruction annotation is left to standard CP/M 2.0 reference
;   disassemblies. The Videx-fix-relevant code is in BIOS (cpm220_BIOS.asm),
;   not here.
; ============================================================================

            .ORG $8000


; ============================================================================
; CCP ENTRY ($8000)
; ============================================================================

CCP_ENTRY:
            RST $08                         ; $8000 CF
            RST $00                         ; $8001 C7
            INC DE                          ; $8002 13
            INC HL                          ; $8003 23
            DEC B                           ; $8004 05
            JP NZ,C5FD                      ; $8005 C2 FD C5
            RET                             ; $8008 C9
            CALL C498                       ; $8009 CD 98 C4
            LD HL,(C48A)                    ; $800C 2A 8A C4
            LD A,(HL)                       ; $800F 7E
            CP 20                           ; $8010 FE 20
            JP Z,C622                       ; $8012 CA 22 C6
            OR A                            ; $8015 B7
            JP Z,C622                       ; $8016 CA 22 C6
            PUSH HL                         ; $8019 E5
            CALL C48C                       ; $801A CD 8C C4
            POP HL                          ; $801D E1
            INC HL                          ; $801E 23
            JP C60F                         ; $801F C3 0F C6
            LD A,3F                         ; $8022 3E 3F
            CALL C48C                       ; $8024 CD 8C C4
            CALL C498                       ; $8027 CD 98 C4
            CALL C5DD                       ; $802A CD DD C5
            JP C782                         ; $802D C3 82 C7
            LD A,(DE)                       ; $8030 1A
            OR A                            ; $8031 B7
            RET Z                           ; $8032 C8
            CP 20                           ; $8033 FE 20
            JP C,C609                       ; $8035 DA 09 C6
            RET Z                           ; $8038 C8
            CP 3D                           ; $8039 FE 3D
            RET Z                           ; $803B C8
            CP 5F                           ; $803C FE 5F
            RET Z                           ; $803E C8
            CP 2E                           ; $803F FE 2E
            RET Z                           ; $8041 C8
            CP 3A                           ; $8042 FE 3A
            RET Z                           ; $8044 C8
            CP 3B                           ; $8045 FE 3B
            RET Z                           ; $8047 C8
            CP 3C                           ; $8048 FE 3C
            RET Z                           ; $804A C8
            CP 3E                           ; $804B FE 3E
            RET Z                           ; $804D C8
            RET                             ; $804E C9
            LD A,(DE)                       ; $804F 1A
            OR A                            ; $8050 B7
            RET Z                           ; $8051 C8
            CP 20                           ; $8052 FE 20
            RET NZ                          ; $8054 C0
            INC DE                          ; $8055 13
            JP C64F                         ; $8056 C3 4F C6
            ADD A,L                         ; $8059 85
            LD L,A                          ; $805A 6F
            RET NC                          ; $805B D0
            INC H                           ; $805C 24
            RET                             ; $805D C9
            LD A,00                         ; $805E 3E 00
            LD HL,CBCD                      ; $8060 21 CD CB
            CALL C659                       ; $8063 CD 59 C6
            PUSH HL                         ; $8066 E5
            PUSH HL                         ; $8067 E5
            XOR A                           ; $8068 AF
            LD (CBF0),A                     ; $8069 32 F0 CB
            LD HL,(C488)                    ; $806C 2A 88 C4
            EX DE,HL                        ; $806F EB
            CALL C64F                       ; $8070 CD 4F C6
            EX DE,HL                        ; $8073 EB
            LD (C48A),HL                    ; $8074 22 8A C4
            EX DE,HL                        ; $8077 EB
            POP HL                          ; $8078 E1
            LD A,(DE)                       ; $8079 1A
            OR A                            ; $807A B7
            JP Z,C689                       ; $807B CA 89 C6
            SBC A,40                        ; $807E DE 40
            LD B,A                          ; $8080 47
            INC DE                          ; $8081 13
            LD A,(DE)                       ; $8082 1A
            CP 3A                           ; $8083 FE 3A
            JP Z,C690                       ; $8085 CA 90 C6
            DEC DE                          ; $8088 1B
            LD A,(CBEF)                     ; $8089 3A EF CB
            LD (HL),A                       ; $808C 77
            JP C696                         ; $808D C3 96 C6
            LD A,B                          ; $8090 78
            LD (CBF0),A                     ; $8091 32 F0 CB
            LD (HL),B                       ; $8094 70
            INC DE                          ; $8095 13
            LD B,08                         ; $8096 06 08
            CALL C630                       ; $8098 CD 30 C6
            JP Z,C6B9                       ; $809B CA B9 C6
            INC HL                          ; $809E 23
            CP 2A                           ; $809F FE 2A
            JP NZ,C6A9                      ; $80A1 C2 A9 C6
            LD (HL),3F                      ; $80A4 36 3F
            JP C6AB                         ; $80A6 C3 AB C6
            LD (HL),A                       ; $80A9 77
            INC DE                          ; $80AA 13
            DEC B                           ; $80AB 05
            JP NZ,C698                      ; $80AC C2 98 C6
            CALL C630                       ; $80AF CD 30 C6
            JP Z,C6C0                       ; $80B2 CA C0 C6
            INC DE                          ; $80B5 13
            JP C6AF                         ; $80B6 C3 AF C6
            INC HL                          ; $80B9 23
            LD (HL),20                      ; $80BA 36 20
            DEC B                           ; $80BC 05
            JP NZ,C6B9                      ; $80BD C2 B9 C6
            LD B,03                         ; $80C0 06 03
            CP 2E                           ; $80C2 FE 2E
            JP NZ,C6E9                      ; $80C4 C2 E9 C6
            INC DE                          ; $80C7 13
            CALL C630                       ; $80C8 CD 30 C6
            JP Z,C6E9                       ; $80CB CA E9 C6
            INC HL                          ; $80CE 23
            CP 2A                           ; $80CF FE 2A
            JP NZ,C6D9                      ; $80D1 C2 D9 C6
            LD (HL),3F                      ; $80D4 36 3F
            JP C6DB                         ; $80D6 C3 DB C6
            LD (HL),A                       ; $80D9 77
            INC DE                          ; $80DA 13
            DEC B                           ; $80DB 05
            JP NZ,C6C8                      ; $80DC C2 C8 C6
            CALL C630                       ; $80DF CD 30 C6
            JP Z,C6F0                       ; $80E2 CA F0 C6
            INC DE                          ; $80E5 13
            JP C6DF                         ; $80E6 C3 DF C6
            INC HL                          ; $80E9 23
            LD (HL),20                      ; $80EA 36 20
            DEC B                           ; $80EC 05
            JP NZ,C6E9                      ; $80ED C2 E9 C6
            LD B,03                         ; $80F0 06 03
            INC HL                          ; $80F2 23
            LD (HL),00                      ; $80F3 36 00
            DEC B                           ; $80F5 05
            JP NZ,C6F2                      ; $80F6 C2 F2 C6
            EX DE,HL                        ; $80F9 EB
            LD (C488),HL                    ; $80FA 22 88 C4
            POP HL                          ; $80FD E1
            LD BC,CE0B                      ; $80FE 01 0B CE
            RET M                           ; $8101 F8
            INC B                           ; $8102 04
            RET NC                          ; $8103 D0
            PUSH HL                         ; $8104 E5
            RET P                           ; $8105 F0
            JP Z,A968                       ; $8106 CA 68 A9
            LD B,B                          ; $8109 40
            JR Z,8158                       ; $810A 28 4C
            LD A,0F                         ; $810C 3E 0F
            RET P                           ; $810E F0
            LD HL,(2FA5)                    ; $810F 2A A5 2F
            ADC A,L                         ; $8112 8D
            EX (SP),HL                      ; $8113 E3
            INC BC                          ; $8114 03
            XOR L                           ; $8115 AD
            JP PO,F003                      ; $8116 E2 03 F0
            EX AF,AF'                       ; $8119 08
            PUSH BC                         ; $811A C5
            CPL                             ; $811B 2F
            RET P                           ; $811C F0
            INC B                           ; $811D 04
            XOR C                           ; $811E A9
            JR NZ,80F1                      ; $811F 20 D0
            RET PE                          ; $8121 E8
            XOR L                           ; $8122 AD
            POP HL                          ; $8123 E1
            INC BC                          ; $8124 03
            XOR B                           ; $8125 A8
            CP C                            ; $8126 B9
            SBC A,L                         ; $8127 9D
            RRCA                            ; $8128 0F
            PUSH BC                         ; $8129 C5
            DEC L                           ; $812A 2D
            RET NC                          ; $812B D0
            SBC A,A                         ; $812C 9F
            JR Z,80BF                       ; $812D 28 90
            ADD HL,DE                       ; $812F 19
            JR NZ,8132                      ; $8130 20 00
            DEC BC                          ; $8132 0B
            EX AF,AF'                       ; $8133 08
            OR B                            ; $8134 B0
            SUB (HL)                        ; $8135 96
            JR Z,8158                       ; $8136 28 20
            ADD A,0B                        ; $8138 C6 0B
            JR 80E5                         ; $813A 18 A9
            NOP                             ; $813C 00
            INC H                           ; $813D 24
            JR C,80CD                       ; $813E 38 8D
            JP PE,AE03                      ; $8140 EA 03 AE
            RET M                           ; $8143 F8
            DEC B                           ; $8144 05
            CP L                            ; $8145 BD
            ADC A,B                         ; $8146 88
            RET NZ                          ; $8147 C0
            LD H,B                          ; $8148 60
            JR NZ,8170                      ; $8149 20 25
            LD A,(BC)                       ; $814B 0A
            SUB B                           ; $814C 90
            CALL PE,10A9                    ; $814D EC A9 10
            RET NC                          ; $8150 D0
            CALL PE,200A                    ; $8151 EC 0A 20
            LD E,D                          ; $8154 5A
            RRCA                            ; $8155 0F
            LD C,(HL)                       ; $8156 4E
            LD A,B                          ; $8157 78
            INC B                           ; $8158 04
            LD H,B                          ; $8159 60
            ADD A,L                         ; $815A 85
            LD L,20                         ; $815B 2E 20
            LD A,L                          ; $815D 7D
            RRCA                            ; $815E 0F
            CP C                            ; $815F B9
            LD A,B                          ; $8160 78
            INC B                           ; $8161 04
            INC H                           ; $8162 24
            DEC (HL)                        ; $8163 35
            JR NC,8169                      ; $8164 30 03
            CP C                            ; $8166 B9
            RET M                           ; $8167 F8
            INC B                           ; $8168 04
            ADC A,L                         ; $8169 8D
            LD A,B                          ; $816A 78
            INC B                           ; $816B 04
            AND L                           ; $816C A5
            LD L,24                         ; $816D 2E 24
            DEC (HL)                        ; $816F 35
            JR NC,8177                      ; $8170 30 05
            SBC A,C                         ; $8172 99
            RET M                           ; $8173 F8
            INC B                           ; $8174 04
            DJNZ 817A                       ; $8175 10 03
            SBC A,C                         ; $8177 99
            LD A,B                          ; $8178 78
            INC B                           ; $8179 04
            LD C,H                          ; $817A 4C
            SBC A,0B                        ; $817B DE 0B
            ADC A,D                         ; $817D 8A
            LD C,D                          ; $817E 4A
            LD C,D                          ; $817F 4A
            LD C,D                          ; $8180 4A
            LD C,D                          ; $8181 4A
            XOR B                           ; $8182 A8
            LD H,B                          ; $8183 60
            LD C,B                          ; $8184 48
            XOR L                           ; $8185 AD
            CALL PO,6A03                    ; $8186 E4 03 6A
            LD H,(HL)                       ; $8189 66
            DEC (HL)                        ; $818A 35
            JR NZ,820A                      ; $818B 20 7D
            RRCA                            ; $818D 0F
            LD L,B                          ; $818E 68
            LD A,(BC)                       ; $818F 0A
            INC H                           ; $8190 24
            DEC (HL)                        ; $8191 35
            JR NC,8199                      ; $8192 30 05
            SBC A,C                         ; $8194 99
            RET M                           ; $8195 F8
            INC B                           ; $8196 04
            DJNZ 819C                       ; $8197 10 03
            SBC A,C                         ; $8199 99
            LD A,B                          ; $819A 78
            INC B                           ; $819B 04
            LD H,B                          ; $819C 60
            NOP                             ; $819D 00
            LD (BC),A                       ; $819E 02
            INC B                           ; $819F 04
            LD B,08                         ; $81A0 06 08
            LD A,(BC)                       ; $81A2 0A
            INC C                           ; $81A3 0C
            LD C,01                         ; $81A4 0E 01
            INC BC                          ; $81A6 03
            DEC B                           ; $81A7 05
            RLCA                            ; $81A8 07
            ADD HL,BC                       ; $81A9 09
            DEC BC                          ; $81AA 0B
            DEC C                           ; $81AB 0D
            RRCA                            ; $81AC 0F
            XOR C                           ; $81AD A9
            CALL PO,E98D                    ; $81AE E4 8D E9
            INC BC                          ; $81B1 03
            AND B                           ; $81B2 A0
            NOP                             ; $81B3 00
            ADC A,H                         ; $81B4 8C
            RET PE                          ; $81B5 E8
            INC BC                          ; $81B6 03
            ADC A,H                         ; $81B7 8C
            RET PO                          ; $81B8 E0
            INC BC                          ; $81B9 03
            RET Z                           ; $81BA C8
            ADC A,H                         ; $81BB 8C
            CALL PO,8C03                    ; $81BC E4 03 8C
            EX DE,HL                        ; $81BF EB
            INC BC                          ; $81C0 03
            XOR C                           ; $81C1 A9
            LD H,B                          ; $81C2 60
            ADC A,L                         ; $81C3 8D
            AND 03                          ; $81C4 E6 03
            XOR C                           ; $81C6 A9
            DEC BC                          ; $81C7 0B
            ADC A,L                         ; $81C8 8D
            POP HL                          ; $81C9 E1
            INC BC                          ; $81CA 03
            XOR C                           ; $81CB A9
            INC E                           ; $81CC 1C
            LD C,B                          ; $81CD 48
            EX AF,AF'                       ; $81CE 08
            LD A,B                          ; $81CF 78
            JR NZ,81E2                      ; $81D0 20 10
            LD C,90                         ; $81D2 0E 90
            EX AF,AF'                       ; $81D4 08
            JR NZ,8204                      ; $81D5 20 2D
            RST $38                         ; $81D7 FF
            JR Z,8242                       ; $81D8 28 68
            LD C,H                          ; $81DA 4C
            XOR L                           ; $81DB AD
            RRCA                            ; $81DC 0F
            JR Z,81CD                       ; $81DD 28 EE
            JP (HL)                         ; $81DF E9
            INC BC                          ; $81E0 03
            XOR (HL)                        ; $81E1 AE
            POP HL                          ; $81E2 E1
            INC BC                          ; $81E3 03
            RET PE                          ; $81E4 E8
            RET PO                          ; $81E5 E0
            DJNZ 81B8                       ; $81E6 10 D0
            DEC B                           ; $81E8 05
            AND D                           ; $81E9 A2
            NOP                             ; $81EA 00
            XOR E0                          ; $81EB EE E0
            INC BC                          ; $81ED 03
            ADC A,(HL)                      ; $81EE 8E
            POP HL                          ; $81EF E1
            INC BC                          ; $81F0 03
            LD L,B                          ; $81F1 68
            JR C,81DD                       ; $81F2 38 E9
            LD BC,D6D0                      ; $81F4 01 D0 D6
            XOR C                           ; $81F7 A9
            EX AF,AF'                       ; $81F8 08
            ADC A,L                         ; $81F9 8D
            JP (HL)                         ; $81FA E9
            INC BC                          ; $81FB 03
            LD H,B                          ; $81FC 60
            RST $38                         ; $81FD FF
            RST $38                         ; $81FE FF
            RST $38                         ; $81FF FF
            NOP                             ; $8200 00
            INC HL                          ; $8201 23
            LD A,(HL)                       ; $8202 7E
            CP 3F                           ; $8203 FE 3F
            JP NZ,C709                      ; $8205 C2 09 C7
            INC B                           ; $8208 04
            DEC C                           ; $8209 0D
            JP NZ,C701                      ; $820A C2 01 C7
            LD A,B                          ; $820D 78
            OR A                            ; $820E B7
            RET                             ; $820F C9
            LD B,H                          ; $8210 44
            LD C,C                          ; $8211 49
            LD D,D                          ; $8212 52
            JR NZ,825A                      ; $8213 20 45
            LD D,D                          ; $8215 52
            LD B,C                          ; $8216 41
            JR NZ,826D                      ; $8217 20 54
            LD E,C                          ; $8219 59
            LD D,B                          ; $821A 50
            LD B,L                          ; $821B 45
            LD D,E                          ; $821C 53
            LD B,C                          ; $821D 41
            LD D,(HL)                       ; $821E 56
            LD B,L                          ; $821F 45
            LD D,D                          ; $8220 52
            LD B,L                          ; $8221 45
            LD C,(HL)                       ; $8222 4E
            JR NZ,827A                      ; $8223 20 55
            LD D,E                          ; $8225 53
            LD B,L                          ; $8226 45
            LD D,D                          ; $8227 52
            CP L                            ; $8228 BD
            LD D,00                         ; $8229 16 00
            NOP                             ; $822B 00
            LD H,B                          ; $822C 60
            EXX                             ; $822D D9
            LD HL,C710                      ; $822E 21 10 C7
            LD C,00                         ; $8231 0E 00
            LD A,C                          ; $8233 79
            CP 06                           ; $8234 FE 06
            RET NC                          ; $8236 D0
            LD DE,CBCE                      ; $8237 11 CE CB
            LD B,04                         ; $823A 06 04
            LD A,(DE)                       ; $823C 1A
            CP (HL)                         ; $823D BE
            JP NZ,C74F                      ; $823E C2 4F C7
            INC DE                          ; $8241 13
            INC HL                          ; $8242 23
            DEC B                           ; $8243 05
            JP NZ,C73C                      ; $8244 C2 3C C7
            LD A,(DE)                       ; $8247 1A
            CP 20                           ; $8248 FE 20
            JP NZ,C754                      ; $824A C2 54 C7
            LD A,C                          ; $824D 79
            RET                             ; $824E C9
            INC HL                          ; $824F 23
            DEC B                           ; $8250 05
            JP NZ,C74F                      ; $8251 C2 4F C7
            INC C                           ; $8254 0C
            JP C733                         ; $8255 C3 33 C7
            XOR A                           ; $8258 AF
            LD (C407),A                     ; $8259 32 07 C4
            LD SP,CBAB                      ; $825C 31 AB CB
            PUSH BC                         ; $825F C5
            LD A,C                          ; $8260 79
            RRA                             ; $8261 1F
            RRA                             ; $8262 1F
            RRA                             ; $8263 1F
            RRA                             ; $8264 1F
            AND 0F                          ; $8265 E6 0F
            LD E,A                          ; $8267 5F
            CALL C515                       ; $8268 CD 15 C5
            CALL C4B8                       ; $826B CD B8 C4
            LD (CBAB),A                     ; $826E 32 AB CB
            POP BC                          ; $8271 C1
            LD A,C                          ; $8272 79
            AND 0F                          ; $8273 E6 0F
            LD (CBEF),A                     ; $8275 32 EF CB
            CALL C4BD                       ; $8278 CD BD C4
            LD A,(C407)                     ; $827B 3A 07 C4
            OR A                            ; $827E B7
            JP NZ,C798                      ; $827F C2 98 C7
            LD SP,CBAB                      ; $8282 31 AB CB
            CALL C498                       ; $8285 CD 98 C4
            CALL C5D0                       ; $8288 CD D0 C5
            ADD A,41                        ; $828B C6 41
            CALL C48C                       ; $828D CD 8C C4
            LD A,3E                         ; $8290 3E 3E
            CALL C48C                       ; $8292 CD 8C C4
            CALL C539                       ; $8295 CD 39 C5
            LD DE,0080                      ; $8298 11 80 00
            CALL C5D8                       ; $829B CD D8 C5
            CALL C5D0                       ; $829E CD D0 C5
            LD (CBEF),A                     ; $82A1 32 EF CB
            CALL C65E                       ; $82A4 CD 5E C6
            CALL NZ,C609                    ; $82A7 C4 09 C6
            LD A,(CBF0)                     ; $82AA 3A F0 CB
            OR A                            ; $82AD B7
            JP NZ,CAA5                      ; $82AE C2 A5 CA
            CALL C72E                       ; $82B1 CD 2E C7
            LD HL,C7C1                      ; $82B4 21 C1 C7
            LD E,A                          ; $82B7 5F
            LD D,00                         ; $82B8 16 00
            ADD HL,DE                       ; $82BA 19
            ADD HL,DE                       ; $82BB 19
            LD A,(HL)                       ; $82BC 7E
            INC HL                          ; $82BD 23
            LD H,(HL)                       ; $82BE 66
            LD L,A                          ; $82BF 6F
            JP (HL)                         ; $82C0 E9
            LD (HL),A                       ; $82C1 77
            RET Z                           ; $82C2 C8
            RRA                             ; $82C3 1F
            RET                             ; $82C4 C9
            LD E,L                          ; $82C5 5D
            RET                             ; $82C6 C9
            XOR L                           ; $82C7 AD
            RET                             ; $82C8 C9
            DJNZ 8295                       ; $82C9 10 CA
            ADC A,(HL)                      ; $82CB 8E
            JP Z,CAA5                       ; $82CC CA A5 CA
            LD HL,76F3                      ; $82CF 21 F3 76
            LD (C400),HL                    ; $82D2 22 00 C4
            LD HL,C400                      ; $82D5 21 00 C4
            JP (HL)                         ; $82D8 E9
            LD BC,C7DF                      ; $82D9 01 DF C7
            JP C4A7                         ; $82DC C3 A7 C4
            LD D,D                          ; $82DF 52
            LD B,L                          ; $82E0 45
            LD B,C                          ; $82E1 41
            LD B,H                          ; $82E2 44
            JR NZ,832A                      ; $82E3 20 45
            LD D,D                          ; $82E5 52
            LD D,D                          ; $82E6 52
            LD C,A                          ; $82E7 4F
            LD D,D                          ; $82E8 52
            NOP                             ; $82E9 00
            LD BC,C7F0                      ; $82EA 01 F0 C7
            JP C4A7                         ; $82ED C3 A7 C4
            LD C,(HL)                       ; $82F0 4E
            LD C,A                          ; $82F1 4F
            JR NZ,833A                      ; $82F2 20 46
            LD C,C                          ; $82F4 49
            LD C,H                          ; $82F5 4C
            LD B,L                          ; $82F6 45
            NOP                             ; $82F7 00
            CALL C65E                       ; $82F8 CD 5E C6
            LD A,(CBF0)                     ; $82FB 3A F0 CB
            OR A                            ; $82FE B7
            JP NZ,81AD                      ; $82FF C2 AD 81
            RET NZ                          ; $8302 C0
            XOR L                           ; $8303 AD
            ADD A,C                         ; $8304 81
            RET NZ                          ; $8305 C0
            JR NZ,8385                      ; $8306 20 7D
            RRCA                            ; $8308 0F
            LD C,B                          ; $8309 48
            SBC A,L                         ; $830A 9D
            ADC A,B                         ; $830B 88
            RET NZ                          ; $830C C0
            XOR C                           ; $830D A9
            NOP                             ; $830E 00
            SBC A,C                         ; $830F 99
            LD A,B                          ; $8310 78
            INC B                           ; $8311 04
            SBC A,C                         ; $8312 99
            RET M                           ; $8313 F8
            INC B                           ; $8314 04
            JR NZ,8346                      ; $8315 20 2F
            EI                              ; $8317 FB
            JR NZ,82AD                      ; $8318 20 93
            CP 20                           ; $831A FE 20
            ADC A,C                         ; $831C 89
            CP 68                           ; $831D FE 68
            AND D                           ; $831F A2
            RST $38                         ; $8320 FF
            SBC A,D                         ; $8321 9A
            RET                             ; $8322 C9
            LD B,F0                         ; $8323 06 F0
            DJNZ 82C7                       ; $8325 10 A0
            NOP                             ; $8327 00
            CP C                            ; $8328 B9
            LD C,D                          ; $8329 4A
            LD DE,06F0                      ; $832A 11 F0 06
            JR NZ,831C                      ; $832D 20 ED
            DB $FD                          ; $832F FD
            RET Z                           ; $8330 C8
            RET NC                          ; $8331 D0
            PUSH AF                         ; $8332 F5
            LD C,H                          ; $8333 4C
            LD H,L                          ; $8334 65
            RST $38                         ; $8335 FF
            AND B                           ; $8336 A0
            LD C,B9                         ; $8337 0E B9
            LD L,B                          ; $8339 68
            LD DE,FF99                      ; $833A 11 99 FF
            RRCA                            ; $833D 0F
            ADC A,B                         ; $833E 88
            RET NC                          ; $833F D0
            RST $30                         ; $8340 F7
            CP C                            ; $8341 B9
            NOP                             ; $8342 00
            LD (DE),A                       ; $8343 12
            SBC A,C                         ; $8344 99
            NOP                             ; $8345 00
            LD (BC),A                       ; $8346 02
            ADC A,B                         ; $8347 88
            RET NC                          ; $8348 D0
            RST $30                         ; $8349 F7
            AND B                           ; $834A A0
            POP AF                          ; $834B F1
            CP C                            ; $834C B9
            RST $38                         ; $834D FF
            LD (DE),A                       ; $834E 12
            SBC A,C                         ; $834F 99
            RST $38                         ; $8350 FF
            LD (BC),A                       ; $8351 02
            ADC A,B                         ; $8352 88
            RET NC                          ; $8353 D0
            RST $30                         ; $8354 F7
            ADC A,H                         ; $8355 8C
            CP B                            ; $8356 B8
            INC BC                          ; $8357 03
            ADD A,H                         ; $8358 84
            INC A                           ; $8359 3C
            ADC A,B                         ; $835A 88
            ADD A,H                         ; $835B 84
            LD A,A0                         ; $835C 3E A0
            RST $00                         ; $835E C7
            JR NZ,82E1                      ; $835F 20 80
            LD DE,A5EA                      ; $8361 11 EA A5
            LD A,F0                         ; $8364 3E F0
            JR 8388                         ; $8366 18 20
            RLA                             ; $8368 17
            LD DE,4085                      ; $8369 11 85 40
            ADD A,(HL)                      ; $836C 86
            LD B,C                          ; $836D 41
            JR NZ,8387                      ; $836E 20 17
            LD DE,00E0                      ; $8370 11 E0 00
            RET P                           ; $8373 F0
            LD E,C5                         ; $8374 1E C5
            LD B,B                          ; $8376 40
            RET NC                          ; $8377 D0
            LD A,(DE)                       ; $8378 1A
            CALL PO,F041                    ; $8379 E4 41 F0
            LD A,(DE)                       ; $837C 1A
            RET NC                          ; $837D D0
            INC D                           ; $837E 14
            AND 3E                          ; $837F E6 3E
            ADC A,H                         ; $8381 8C
            RET Z                           ; $8382 C8
            INC BC                          ; $8383 03
            XOR C                           ; $8384 A9
            NOP                             ; $8385 00
            ADC A,L                         ; $8386 8D
            RST $00                         ; $8387 C7
            INC BC                          ; $8388 03
            ADC A,L                         ; $8389 8D
            SBC A,03                        ; $838A DE 03
            SBC A,B                         ; $838C 98
            JR 83F8                         ; $838D 18 69
            JR NZ,831E                      ; $838F 20 8D
            RST $18                         ; $8391 DF
            INC BC                          ; $8392 03
            AND D                           ; $8393 A2
            NOP                             ; $8394 00
            RET P                           ; $8395 F0
            RRA                             ; $8396 1F
            AND D                           ; $8397 A2
            INC B                           ; $8398 04
            AND B                           ; $8399 A0
            DEC B                           ; $839A 05
            OR C                            ; $839B B1
            INC A                           ; $839C 3C
            DB $DD                          ; $839D DD
            HALT                            ; $839E 76
            LD DE,09D0                      ; $839F 11 D0 09
            AND B                           ; $83A2 A0
            RLCA                            ; $83A3 07
            OR C                            ; $83A4 B1
            INC A                           ; $83A5 3C
            DB $DD                          ; $83A6 DD
            LD A,D                          ; $83A7 7A
            LD DE,03F0                      ; $83A8 11 F0 03
            JP Z,EBD0                       ; $83AB CA D0 EB
            RET PE                          ; $83AE E8
            RET PO                          ; $83AF E0
            LD (BC),A                       ; $83B0 02
            RET NC                          ; $83B1 D0
            INC BC                          ; $83B2 03
            XOR B8                          ; $83B3 EE B8
            INC BC                          ; $83B5 03
            AND H                           ; $83B6 A4
            DEC A                           ; $83B7 3D
            ADC A,D                         ; $83B8 8A
            SBC A,C                         ; $83B9 99
            RET M                           ; $83BA F8
            LD (BC),A                       ; $83BB 02
            ADC A,B                         ; $83BC 88
            RET NZ                          ; $83BD C0
            RET NZ                          ; $83BE C0
            RET NC                          ; $83BF D0
            SBC A,(HL)                      ; $83C0 9E
            LD C,B8                         ; $83C1 0E B8
            INC BC                          ; $83C3 03
            AND L                           ; $83C4 A5
            LD A,C9                         ; $83C5 3E C9
            LD BC,1DF0                      ; $83C7 01 F0 1D
            ADD A,H                         ; $83CA 84
            DEC A                           ; $83CB 3D
            XOR C                           ; $83CC A9
            ADD A,L                         ; $83CD 85
            ADD A,L                         ; $83CE 85
            INC A                           ; $83CF 3C
            ADC A,L                         ; $83D0 8D
            ADD A,L                         ; $83D1 85
            RET NZ                          ; $83D2 C0
            AND L                           ; $83D3 A5
            LD A,F0                         ; $83D4 3E F0
            DJNZ 8378                       ; $83D6 10 A0
            NOP                             ; $83D8 00
            CP C                            ; $83D9 B9
            DEC HL                          ; $83DA 2B
            LD DE,06F0                      ; $83DB 11 F0 06
            JR NZ,83CD                      ; $83DE 20 ED
            DB $FD                          ; $83E0 FD
            RET Z                           ; $83E1 C8
            RET NC                          ; $83E2 D0
            PUSH AF                         ; $83E3 F5
            LD C,H                          ; $83E4 4C
            LD H,L                          ; $83E5 65
            RST $38                         ; $83E6 FF
            AND B                           ; $83E7 A0
            DJNZ 83A3                       ; $83E8 10 B9
            RST $28                         ; $83EA EF
            INC DE                          ; $83EB 13
            SBC A,C                         ; $83EC 99
            RST $28                         ; $83ED EF
            INC BC                          ; $83EE 03
            ADC A,B                         ; $83EF 88
            RET NC                          ; $83F0 D0
            RST $30                         ; $83F1 F7
            XOR C                           ; $83F2 A9
            JP 008D                         ; $83F3 C3 8D 00
            DJNZ 83A1                       ; $83F6 10 A9
            NOP                             ; $83F8 00
            ADC A,L                         ; $83F9 8D
            LD BC,A910                      ; $83FA 01 10 A9
            JP C,028D                       ; $83FD DA 8D 02
            ADD HL,BC                       ; $8400 09
            ADD A,21                        ; $8401 C6 21
            ADC A,CB                        ; $8403 CE CB
            LD BC,000B                      ; $8405 01 0B 00
            LD A,(HL)                       ; $8408 7E
            CP 20                           ; $8409 FE 20
            JP Z,C833                       ; $840B CA 33 C8
            INC HL                          ; $840E 23
            SUB 30                          ; $840F D6 30
            CP 0A                           ; $8411 FE 0A
            JP NC,C609                      ; $8413 D2 09 C6
            LD D,A                          ; $8416 57
            LD A,B                          ; $8417 78
            AND E0                          ; $8418 E6 E0
            JP NZ,C609                      ; $841A C2 09 C6
            LD A,B                          ; $841D 78
            RLCA                            ; $841E 07
            RLCA                            ; $841F 07
            RLCA                            ; $8420 07
            ADD A,B                         ; $8421 80
            JP C,C609                       ; $8422 DA 09 C6
            ADD A,B                         ; $8425 80
            JP C,C609                       ; $8426 DA 09 C6
            ADD A,D                         ; $8429 82
            JP C,C609                       ; $842A DA 09 C6
            LD B,A                          ; $842D 47
            DEC C                           ; $842E 0D
            JP NZ,C808                      ; $842F C2 08 C8
            RET                             ; $8432 C9
            LD A,(HL)                       ; $8433 7E
            CP 20                           ; $8434 FE 20
            JP NZ,C609                      ; $8436 C2 09 C6
            INC HL                          ; $8439 23
            DEC C                           ; $843A 0D
            JP NZ,C833                      ; $843B C2 33 C8
            LD A,B                          ; $843E 78
            RET                             ; $843F C9
            LD B,03                         ; $8440 06 03
            LD A,(HL)                       ; $8442 7E
            LD (DE),A                       ; $8443 12
            INC HL                          ; $8444 23
            INC DE                          ; $8445 13
            DEC B                           ; $8446 05
            JP NZ,C842                      ; $8447 C2 42 C8
            RET                             ; $844A C9
            LD HL,0080                      ; $844B 21 80 00
            ADD A,C                         ; $844E 81
            CALL C659                       ; $844F CD 59 C6
            LD A,(HL)                       ; $8452 7E
            RET                             ; $8453 C9
            XOR A                           ; $8454 AF
            LD (CBCD),A                     ; $8455 32 CD CB
            LD A,(CBF0)                     ; $8458 3A F0 CB
            OR A                            ; $845B B7
            RET Z                           ; $845C C8
            DEC A                           ; $845D 3D
            LD HL,CBEF                      ; $845E 21 EF CB
            CP (HL)                         ; $8461 BE
            RET Z                           ; $8462 C8
            JP C4BD                         ; $8463 C3 BD C4
            LD A,(CBF0)                     ; $8466 3A F0 CB
            OR A                            ; $8469 B7
            RET Z                           ; $846A C8
            DEC A                           ; $846B 3D
            LD HL,CBEF                      ; $846C 21 EF CB
            CP (HL)                         ; $846F BE
            RET Z                           ; $8470 C8
            LD A,(CBEF)                     ; $8471 3A EF CB
            JP C4BD                         ; $8474 C3 BD C4
            CALL C65E                       ; $8477 CD 5E C6
            CALL C854                       ; $847A CD 54 C8
            LD HL,CBCE                      ; $847D 21 CE CB
            LD A,(HL)                       ; $8480 7E
            CP 20                           ; $8481 FE 20
            JP NZ,C88F                      ; $8483 C2 8F C8
            LD B,0B                         ; $8486 06 0B
            LD (HL),3F                      ; $8488 36 3F
            INC HL                          ; $848A 23
            DEC B                           ; $848B 05
            JP NZ,C888                      ; $848C C2 88 C8
            LD E,00                         ; $848F 1E 00
            PUSH DE                         ; $8491 D5
            CALL C4E9                       ; $8492 CD E9 C4
            CALL Z,C7EA                     ; $8495 CC EA C7
            JP Z,C91B                       ; $8498 CA 1B C9
            LD A,(CBEE)                     ; $849B 3A EE CB
            RRCA                            ; $849E 0F
            RRCA                            ; $849F 0F
            RRCA                            ; $84A0 0F
            AND 60                          ; $84A1 E6 60
            LD C,A                          ; $84A3 4F
            LD A,0A                         ; $84A4 3E 0A
            CALL C84B                       ; $84A6 CD 4B C8
            RLA                             ; $84A9 17
            JP C,C90F                       ; $84AA DA 0F C9
            POP DE                          ; $84AD D1
            LD A,E                          ; $84AE 7B
            INC E                           ; $84AF 1C
            PUSH DE                         ; $84B0 D5
            AND 03                          ; $84B1 E6 03
            PUSH AF                         ; $84B3 F5
            JP NZ,C8CC                      ; $84B4 C2 CC C8
            CALL C498                       ; $84B7 CD 98 C4
            PUSH BC                         ; $84BA C5
            CALL C5D0                       ; $84BB CD D0 C5
            POP BC                          ; $84BE C1
            ADD A,41                        ; $84BF C6 41
            CALL C492                       ; $84C1 CD 92 C4
            LD A,3A                         ; $84C4 3E 3A
            CALL C492                       ; $84C6 CD 92 C4
            JP C8D4                         ; $84C9 C3 D4 C8
            CALL C4A2                       ; $84CC CD A2 C4
            LD A,3A                         ; $84CF 3E 3A
            CALL C492                       ; $84D1 CD 92 C4
            CALL C4A2                       ; $84D4 CD A2 C4
            LD B,01                         ; $84D7 06 01
            LD A,B                          ; $84D9 78
            CALL C84B                       ; $84DA CD 4B C8
            AND 7F                          ; $84DD E6 7F
            CP 20                           ; $84DF FE 20
            JP NZ,C8F9                      ; $84E1 C2 F9 C8
            POP AF                          ; $84E4 F1
            PUSH AF                         ; $84E5 F5
            CP 03                           ; $84E6 FE 03
            JP NZ,C8F7                      ; $84E8 C2 F7 C8
            LD A,09                         ; $84EB 3E 09
            CALL C84B                       ; $84ED CD 4B C8
            AND 7F                          ; $84F0 E6 7F
            CP 20                           ; $84F2 FE 20
            JP Z,C90E                       ; $84F4 CA 0E C9
            LD A,20                         ; $84F7 3E 20
            CALL C492                       ; $84F9 CD 92 C4
            INC B                           ; $84FC 04
            LD A,B                          ; $84FD 78
            CP 0C                           ; $84FE FE 0C
            JP NC,C90E                      ; $8500 D2 0E C9
            CP 09                           ; $8503 FE 09
            JP NZ,C8D9                      ; $8505 C2 D9 C8
            CALL C4A2                       ; $8508 CD A2 C4
            JP C8D9                         ; $850B C3 D9 C8
            POP AF                          ; $850E F1
            CALL C5C2                       ; $850F CD C2 C5
            JP NZ,C91B                      ; $8512 C2 1B C9
            CALL C4E4                       ; $8515 CD E4 C4
            JP C898                         ; $8518 C3 98 C8
            POP DE                          ; $851B D1
            JP CB86                         ; $851C C3 86 CB
            CALL C65E                       ; $851F CD 5E C6
            CP 0B                           ; $8522 FE 0B
            JP NZ,C942                      ; $8524 C2 42 C9
            LD BC,C952                      ; $8527 01 52 C9
            CALL C4A7                       ; $852A CD A7 C4
            CALL C539                       ; $852D CD 39 C5
            LD HL,C407                      ; $8530 21 07 C4
            DEC (HL)                        ; $8533 35
            JP NZ,C782                      ; $8534 C2 82 C7
            INC HL                          ; $8537 23
            LD A,(HL)                       ; $8538 7E
            CP 59                           ; $8539 FE 59
            JP NZ,C782                      ; $853B C2 82 C7
            INC HL                          ; $853E 23
            LD (C488),HL                    ; $853F 22 88 C4
            CALL C854                       ; $8542 CD 54 C8
            LD DE,CBCD                      ; $8545 11 CD CB
            CALL C4EF                       ; $8548 CD EF C4
            INC A                           ; $854B 3C
            CALL Z,C7EA                     ; $854C CC EA C7
            JP CB86                         ; $854F C3 86 CB
            LD B,C                          ; $8552 41
            LD C,H                          ; $8553 4C
            LD C,H                          ; $8554 4C
            JR NZ,857F                      ; $8555 20 28
            LD E,C                          ; $8557 59
            CPL                             ; $8558 2F
            LD C,(HL)                       ; $8559 4E
            ADD HL,HL                       ; $855A 29
            CCF                             ; $855B 3F
            NOP                             ; $855C 00
            CALL C65E                       ; $855D CD 5E C6
            JP NZ,C609                      ; $8560 C2 09 C6
            CALL C854                       ; $8563 CD 54 C8
            CALL C4D0                       ; $8566 CD D0 C4
            JP Z,C9A7                       ; $8569 CA A7 C9
            CALL C498                       ; $856C CD 98 C4
            LD HL,CBF1                      ; $856F 21 F1 CB
            LD (HL),FF                      ; $8572 36 FF
            LD HL,CBF1                      ; $8574 21 F1 CB
            LD A,(HL)                       ; $8577 7E
            CP 80                           ; $8578 FE 80
            JP C,C987                       ; $857A DA 87 C9
            PUSH HL                         ; $857D E5
            CALL C4FE                       ; $857E CD FE C4
            POP HL                          ; $8581 E1
            JP NZ,C9A0                      ; $8582 C2 A0 C9
            XOR A                           ; $8585 AF
            LD (HL),A                       ; $8586 77
            INC (HL)                        ; $8587 34
            LD HL,0080                      ; $8588 21 80 00
            CALL C659                       ; $858B CD 59 C6
            LD A,(HL)                       ; $858E 7E
            CP 1A                           ; $858F FE 1A
            JP Z,CB86                       ; $8591 CA 86 CB
            CALL C48C                       ; $8594 CD 8C C4
            CALL C5C2                       ; $8597 CD C2 C5
            JP NZ,CB86                      ; $859A C2 86 CB
            JP C974                         ; $859D C3 74 C9
            DEC A                           ; $85A0 3D
            JP Z,CB86                       ; $85A1 CA 86 CB
            CALL C7D9                       ; $85A4 CD D9 C7
            CALL C866                       ; $85A7 CD 66 C8
            JP C609                         ; $85AA C3 09 C6
            CALL C7F8                       ; $85AD CD F8 C7
            PUSH AF                         ; $85B0 F5
            CALL C65E                       ; $85B1 CD 5E C6
            JP NZ,C609                      ; $85B4 C2 09 C6
            CALL C854                       ; $85B7 CD 54 C8
            LD DE,CBCD                      ; $85BA 11 CD CB
            PUSH DE                         ; $85BD D5
            CALL C4EF                       ; $85BE CD EF C4
            POP DE                          ; $85C1 D1
            CALL C509                       ; $85C2 CD 09 C5
            JP Z,C9FB                       ; $85C5 CA FB C9
            XOR A                           ; $85C8 AF
            LD (CBED),A                     ; $85C9 32 ED CB
            POP AF                          ; $85CC F1
            LD L,A                          ; $85CD 6F
            LD H,00                         ; $85CE 26 00
            ADD HL,HL                       ; $85D0 29
            LD DE,0100                      ; $85D1 11 00 01
            LD A,H                          ; $85D4 7C
            OR L                            ; $85D5 B5
            JP Z,C9F1                       ; $85D6 CA F1 C9
            DEC HL                          ; $85D9 2B
            PUSH HL                         ; $85DA E5
            LD HL,0080                      ; $85DB 21 80 00
            ADD HL,DE                       ; $85DE 19
            PUSH HL                         ; $85DF E5
            CALL C5D8                       ; $85E0 CD D8 C5
            LD DE,CBCD                      ; $85E3 11 CD CB
            CALL C504                       ; $85E6 CD 04 C5
            POP DE                          ; $85E9 D1
            POP HL                          ; $85EA E1
            JP NZ,C9FB                      ; $85EB C2 FB C9
            JP C9D4                         ; $85EE C3 D4 C9
            LD DE,CBCD                      ; $85F1 11 CD CB
            CALL C4DA                       ; $85F4 CD DA C4
            INC A                           ; $85F7 3C
            JP NZ,CA01                      ; $85F8 C2 01 CA
            LD BC,CA07                      ; $85FB 01 07 CA
            CALL C2A7                       ; $85FE CD A7 C2
            DB $FD                          ; $8601 FD
            RET NC                          ; $8602 D0
            RET                             ; $8603 C9
            INC C                           ; $8604 0C
            DEC C                           ; $8605 0D
            RET Z                           ; $8606 C8
            ADD HL,HL                       ; $8607 29
            JP D105                         ; $8608 C3 05 D1
            PUSH BC                         ; $860B C5
            LD A,(CF42)                     ; $860C 3A 42 CF
            LD C,A                          ; $860F 4F
            LD HL,0001                      ; $8610 21 01 00
            CALL D104                       ; $8613 CD 04 D1
            POP BC                          ; $8616 C1
            LD A,C                          ; $8617 79
            OR L                            ; $8618 B5
            LD L,A                          ; $8619 6F
            LD A,B                          ; $861A 78
            OR H                            ; $861B B4
            LD H,A                          ; $861C 67
            RET                             ; $861D C9
            LD HL,(D9AD)                    ; $861E 2A AD D9
            LD A,(CF42)                     ; $8621 3A 42 CF
            LD C,A                          ; $8624 4F
            CALL D0EA                       ; $8625 CD EA D0
            LD A,L                          ; $8628 7D
            AND 01                          ; $8629 E6 01
            RET                             ; $862B C9
            LD HL,D9AD                      ; $862C 21 AD D9
            LD C,(HL)                       ; $862F 4E
            INC HL                          ; $8630 23
            LD B,(HL)                       ; $8631 46
            CALL D10B                       ; $8632 CD 0B D1
            LD (D9AD),HL                    ; $8635 22 AD D9
            LD HL,(D9C8)                    ; $8638 2A C8 D9
            INC HL                          ; $863B 23
            EX DE,HL                        ; $863C EB
            LD HL,(D9B3)                    ; $863D 2A B3 D9
            LD (HL),E                       ; $8640 73
            INC HL                          ; $8641 23
            LD (HL),D                       ; $8642 72
            RET                             ; $8643 C9
            CALL D15E                       ; $8644 CD 5E D1
            LD DE,0009                      ; $8647 11 09 00
            ADD HL,DE                       ; $864A 19
            LD A,(HL)                       ; $864B 7E
            RLA                             ; $864C 17
            RET NC                          ; $864D D0
            LD HL,CC0F                      ; $864E 21 0F CC
            JP CF4A                         ; $8651 C3 4A CF
            CALL D11E                       ; $8654 CD 1E D1
            RET Z                           ; $8657 C8
            LD HL,CC0D                      ; $8658 21 0D CC
            JP CF4A                         ; $865B C3 4A CF
            LD HL,(D9B9)                    ; $865E 2A B9 D9
            LD A,(D9E9)                     ; $8661 3A E9 D9
            ADD A,L                         ; $8664 85
            LD L,A                          ; $8665 6F
            RET NC                          ; $8666 D0
            INC H                           ; $8667 24
            RET                             ; $8668 C9
            LD HL,(CF43)                    ; $8669 2A 43 CF
            LD DE,000E                      ; $866C 11 0E 00
            ADD HL,DE                       ; $866F 19
            LD A,(HL)                       ; $8670 7E
            RET                             ; $8671 C9
            CALL D169                       ; $8672 CD 69 D1
            LD (HL),00                      ; $8675 36 00
            RET                             ; $8677 C9
            CALL D169                       ; $8678 CD 69 D1
            OR 80                           ; $867B F6 80
            LD (HL),A                       ; $867D 77
            RET                             ; $867E C9
            LD HL,(D9EA)                    ; $867F 2A EA D9
            EX DE,HL                        ; $8682 EB
            LD HL,(D9B3)                    ; $8683 2A B3 D9
            LD A,E                          ; $8686 7B
            SUB (HL)                        ; $8687 96
            INC HL                          ; $8688 23
            LD A,D                          ; $8689 7A
            SBC A,(HL)                      ; $868A 9E
            RET                             ; $868B C9
            CALL D17F                       ; $868C CD 7F D1
            RET C                           ; $868F D8
            INC DE                          ; $8690 13
            LD (HL),D                       ; $8691 72
            DEC HL                          ; $8692 2B
            LD (HL),E                       ; $8693 73
            RET                             ; $8694 C9
            LD A,E                          ; $8695 7B
            SUB L                           ; $8696 95
            LD L,A                          ; $8697 6F
            LD A,D                          ; $8698 7A
            SBC A,H                         ; $8699 9C
            LD H,A                          ; $869A 67
            RET                             ; $869B C9
            LD C,FF                         ; $869C 0E FF
            LD HL,(D9EC)                    ; $869E 2A EC D9
            EX DE,HL                        ; $86A1 EB
            LD HL,(D9CC)                    ; $86A2 2A CC D9
            CALL D195                       ; $86A5 CD 95 D1
            RET NC                          ; $86A8 D0
            PUSH BC                         ; $86A9 C5
            CALL D0F7                       ; $86AA CD F7 D0
            LD HL,(D9BD)                    ; $86AD 2A BD D9
            EX DE,HL                        ; $86B0 EB
            LD HL,(D9EC)                    ; $86B1 2A EC D9
            ADD HL,DE                       ; $86B4 19
            POP BC                          ; $86B5 C1
            INC C                           ; $86B6 0C
            JP Z,D1C4                       ; $86B7 CA C4 D1
            CP (HL)                         ; $86BA BE
            RET Z                           ; $86BB C8
            CALL D17F                       ; $86BC CD 7F D1
            RET NC                          ; $86BF D0
            CALL D12C                       ; $86C0 CD 2C D1
            RET                             ; $86C3 C9
            LD (HL),A                       ; $86C4 77
            RET                             ; $86C5 C9
            CALL D19C                       ; $86C6 CD 9C D1
            CALL D1E0                       ; $86C9 CD E0 D1
            LD C,01                         ; $86CC 0E 01
            CALL CFB8                       ; $86CE CD B8 CF
            JP D1DA                         ; $86D1 C3 DA D1
            CALL D1E0                       ; $86D4 CD E0 D1
            CALL CFB2                       ; $86D7 CD B2 CF
            LD HL,D9B1                      ; $86DA 21 B1 D9
            JP D1E3                         ; $86DD C3 E3 D1
            LD HL,D9B9                      ; $86E0 21 B9 D9
            LD C,(HL)                       ; $86E3 4E
            INC HL                          ; $86E4 23
            LD B,(HL)                       ; $86E5 46
            JP DA24                         ; $86E6 C3 24 DA
            LD HL,(D9B9)                    ; $86E9 2A B9 D9
            EX DE,HL                        ; $86EC EB
            LD HL,(D9B1)                    ; $86ED 2A B1 D9
            LD C,80                         ; $86F0 0E 80
            JP CF4F                         ; $86F2 C3 4F CF
            LD HL,D9EA                      ; $86F5 21 EA D9
            LD A,(HL)                       ; $86F8 7E
            INC HL                          ; $86F9 23
            CP (HL)                         ; $86FA BE
            RET NZ                          ; $86FB C0
            INC A                           ; $86FC 3C
            RET                             ; $86FD C9
            LD HL,C4FF                      ; $86FE 21 FF C4
            CALL C5D5                       ; $8701 CD D5 C5
            JP CB86                         ; $8704 C3 86 CB
            LD C,(HL)                       ; $8707 4E
            LD C,A                          ; $8708 4F
            JR NZ,875E                      ; $8709 20 53
            LD D,B                          ; $870B 50
            LD B,C                          ; $870C 41
            LD B,E                          ; $870D 43
            LD B,L                          ; $870E 45
            NOP                             ; $870F 00
            CALL C65E                       ; $8710 CD 5E C6
            JP NZ,C609                      ; $8713 C2 09 C6
            LD A,(CBF0)                     ; $8716 3A F0 CB
            PUSH AF                         ; $8719 F5
            CALL C854                       ; $871A CD 54 C8
            CALL C4E9                       ; $871D CD E9 C4
            JP NZ,CA79                      ; $8720 C2 79 CA
            LD HL,CBCD                      ; $8723 21 CD CB
            LD DE,CBDD                      ; $8726 11 DD CB
            LD B,10                         ; $8729 06 10
            CALL C842                       ; $872B CD 42 C8
            LD HL,(C488)                    ; $872E 2A 88 C4
            EX DE,HL                        ; $8731 EB
            CALL C64F                       ; $8732 CD 4F C6
            CP 3D                           ; $8735 FE 3D
            JP Z,CA3F                       ; $8737 CA 3F CA
            CP 5F                           ; $873A FE 5F
            JP NZ,CA73                      ; $873C C2 73 CA
            EX DE,HL                        ; $873F EB
            INC HL                          ; $8740 23
            LD (C488),HL                    ; $8741 22 88 C4
            CALL C65E                       ; $8744 CD 5E C6
            JP NZ,CA73                      ; $8747 C2 73 CA
            POP AF                          ; $874A F1
            LD B,A                          ; $874B 47
            LD HL,CBF0                      ; $874C 21 F0 CB
            LD A,(HL)                       ; $874F 7E
            OR A                            ; $8750 B7
            JP Z,CA59                       ; $8751 CA 59 CA
            CP B                            ; $8754 B8
            LD (HL),B                       ; $8755 70
            JP NZ,CA73                      ; $8756 C2 73 CA
            LD (HL),B                       ; $8759 70
            XOR A                           ; $875A AF
            LD (CBCD),A                     ; $875B 32 CD CB
            CALL C4E9                       ; $875E CD E9 C4
            JP Z,CA6D                       ; $8761 CA 6D CA
            LD DE,CBCD                      ; $8764 11 CD CB
            CALL C50E                       ; $8767 CD 0E C5
            JP CB86                         ; $876A C3 86 CB
            CALL C7EA                       ; $876D CD EA C7
            JP CB86                         ; $8770 C3 86 CB
            CALL C866                       ; $8773 CD 66 C8
            JP C609                         ; $8776 C3 09 C6
            LD BC,CA82                      ; $8779 01 82 CA
            CALL C4A7                       ; $877C CD A7 C4
            JP CB86                         ; $877F C3 86 CB
            LD B,(HL)                       ; $8782 46
            LD C,C                          ; $8783 49
            LD C,H                          ; $8784 4C
            LD B,L                          ; $8785 45
            JR NZ,87CD                      ; $8786 20 45
            LD E,B                          ; $8788 58
            LD C,C                          ; $8789 49
            LD D,E                          ; $878A 53
            LD D,H                          ; $878B 54
            LD D,E                          ; $878C 53
            NOP                             ; $878D 00
            CALL C7F8                       ; $878E CD F8 C7
            CP 10                           ; $8791 FE 10
            JP NC,C609                      ; $8793 D2 09 C6
            LD E,A                          ; $8796 5F
            LD A,(CBCE)                     ; $8797 3A CE CB
            CP 20                           ; $879A FE 20
            JP Z,C609                       ; $879C CA 09 C6
            CALL C515                       ; $879F CD 15 C5
            JP CB89                         ; $87A2 C3 89 CB
            CALL C5F5                       ; $87A5 CD F5 C5
            LD A,(CBCE)                     ; $87A8 3A CE CB
            CP 20                           ; $87AB FE 20
            JP NZ,CAC4                      ; $87AD C2 C4 CA
            LD A,(CBF0)                     ; $87B0 3A F0 CB
            OR A                            ; $87B3 B7
            JP Z,CB89                       ; $87B4 CA 89 CB
            DEC A                           ; $87B7 3D
            LD (CBEF),A                     ; $87B8 32 EF CB
            CALL C529                       ; $87BB CD 29 C5
            CALL C4BD                       ; $87BE CD BD C4
            JP CB89                         ; $87C1 C3 89 CB
            LD DE,CBD6                      ; $87C4 11 D6 CB
            LD A,(DE)                       ; $87C7 1A
            CP 20                           ; $87C8 FE 20
            JP NZ,C609                      ; $87CA C2 09 C6
            PUSH DE                         ; $87CD D5
            CALL C854                       ; $87CE CD 54 C8
            POP DE                          ; $87D1 D1
            LD HL,CB83                      ; $87D2 21 83 CB
            CALL C840                       ; $87D5 CD 40 C8
            CALL C4D0                       ; $87D8 CD D0 C4
            JP Z,CB6B                       ; $87DB CA 6B CB
            LD HL,0100                      ; $87DE 21 00 01
            PUSH HL                         ; $87E1 E5
            EX DE,HL                        ; $87E2 EB
            CALL C5D8                       ; $87E3 CD D8 C5
            LD DE,CBCD                      ; $87E6 11 CD CB
            CALL C4F9                       ; $87E9 CD F9 C4
            JP NZ,CB01                      ; $87EC C2 01 CB
            POP HL                          ; $87EF E1
            LD DE,0080                      ; $87F0 11 80 00
            ADD HL,DE                       ; $87F3 19
            LD DE,C400                      ; $87F4 11 00 C4
            LD A,L                          ; $87F7 7D
            SUB E                           ; $87F8 93
            LD A,H                          ; $87F9 7C
            SBC A,D                         ; $87FA 9A
            JP NC,CB71                      ; $87FB D2 71 CB
            JP FFE1                         ; $87FE C3 E1 FF
            LD (D9EA),HL                    ; $8801 22 EA D9
            RET                             ; $8804 C9
            LD HL,(D9C8)                    ; $8805 2A C8 D9
            EX DE,HL                        ; $8808 EB
            LD HL,(D9EA)                    ; $8809 2A EA D9
            INC HL                          ; $880C 23
            LD (D9EA),HL                    ; $880D 22 EA D9
            CALL D195                       ; $8810 CD 95 D1
            JP NC,D219                      ; $8813 D2 19 D2
            JP D1FE                         ; $8816 C3 FE D1
            LD A,(D9EA)                     ; $8819 3A EA D9
            AND 03                          ; $881C E6 03
            LD B,05                         ; $881E 06 05
            ADD A,A                         ; $8820 87
            DEC B                           ; $8821 05
            JP NZ,D220                      ; $8822 C2 20 D2
            LD (D9E9),A                     ; $8825 32 E9 D9
            OR A                            ; $8828 B7
            RET NZ                          ; $8829 C0
            PUSH BC                         ; $882A C5
            CALL CFC3                       ; $882B CD C3 CF
            CALL D1D4                       ; $882E CD D4 D1
            POP BC                          ; $8831 C1
            JP D19E                         ; $8832 C3 9E D1
            LD A,C                          ; $8835 79
            AND 07                          ; $8836 E6 07
            INC A                           ; $8838 3C
            LD E,A                          ; $8839 5F
            LD D,A                          ; $883A 57
            LD A,C                          ; $883B 79
            RRCA                            ; $883C 0F
            RRCA                            ; $883D 0F
            RRCA                            ; $883E 0F
            AND 1F                          ; $883F E6 1F
            LD C,A                          ; $8841 4F
            LD A,B                          ; $8842 78
            ADD A,A                         ; $8843 87
            ADD A,A                         ; $8844 87
            ADD A,A                         ; $8845 87
            ADD A,A                         ; $8846 87
            ADD A,A                         ; $8847 87
            OR C                            ; $8848 B1
            LD C,A                          ; $8849 4F
            LD A,B                          ; $884A 78
            RRCA                            ; $884B 0F
            RRCA                            ; $884C 0F
            RRCA                            ; $884D 0F
            AND 1F                          ; $884E E6 1F
            LD B,A                          ; $8850 47
            LD HL,(D9BF)                    ; $8851 2A BF D9
            ADD HL,BC                       ; $8854 09
            LD A,(HL)                       ; $8855 7E
            RLCA                            ; $8856 07
            DEC E                           ; $8857 1D
            JP NZ,D256                      ; $8858 C2 56 D2
            RET                             ; $885B C9
            PUSH DE                         ; $885C D5
            CALL D235                       ; $885D CD 35 D2
            AND FE                          ; $8860 E6 FE
            POP BC                          ; $8862 C1
            OR C                            ; $8863 B1
            RRCA                            ; $8864 0F
            DEC D                           ; $8865 15
            JP NZ,D264                      ; $8866 C2 64 D2
            LD (HL),A                       ; $8869 77
            RET                             ; $886A C9
            CALL D15E                       ; $886B CD 5E D1
            LD DE,0010                      ; $886E 11 10 00
            ADD HL,DE                       ; $8871 19
            PUSH BC                         ; $8872 C5
            LD C,11                         ; $8873 0E 11
            POP DE                          ; $8875 D1
            DEC C                           ; $8876 0D
            RET Z                           ; $8877 C8
            PUSH DE                         ; $8878 D5
            LD A,(D9DD)                     ; $8879 3A DD D9
            OR A                            ; $887C B7
            JP Z,D288                       ; $887D CA 88 D2
            PUSH BC                         ; $8880 C5
            PUSH HL                         ; $8881 E5
            LD C,(HL)                       ; $8882 4E
            LD B,00                         ; $8883 06 00
            JP D28E                         ; $8885 C3 8E D2
            DEC C                           ; $8888 0D
            PUSH BC                         ; $8889 C5
            LD C,(HL)                       ; $888A 4E
            INC HL                          ; $888B 23
            LD B,(HL)                       ; $888C 46
            PUSH HL                         ; $888D E5
            LD A,C                          ; $888E 79
            OR B                            ; $888F B0
            JP Z,D29D                       ; $8890 CA 9D D2
            LD HL,(D9C6)                    ; $8893 2A C6 D9
            LD A,L                          ; $8896 7D
            SUB C                           ; $8897 91
            LD A,H                          ; $8898 7C
            SBC A,B                         ; $8899 98
            CALL NC,D25C                    ; $889A D4 5C D2
            POP HL                          ; $889D E1
            INC HL                          ; $889E 23
            POP BC                          ; $889F C1
            JP D275                         ; $88A0 C3 75 D2
            LD HL,(D9C6)                    ; $88A3 2A C6 D9
            LD C,03                         ; $88A6 0E 03
            CALL D0EA                       ; $88A8 CD EA D0
            INC HL                          ; $88AB 23
            LD B,H                          ; $88AC 44
            LD C,L                          ; $88AD 4D
            LD HL,(D9BF)                    ; $88AE 2A BF D9
            LD (HL),00                      ; $88B1 36 00
            INC HL                          ; $88B3 23
            DEC BC                          ; $88B4 0B
            LD A,B                          ; $88B5 78
            OR C                            ; $88B6 B1
            JP NZ,D2B1                      ; $88B7 C2 B1 D2
            LD HL,(D9CA)                    ; $88BA 2A CA D9
            EX DE,HL                        ; $88BD EB
            LD HL,(D9BF)                    ; $88BE 2A BF D9
            LD (HL),E                       ; $88C1 73
            INC HL                          ; $88C2 23
            LD (HL),D                       ; $88C3 72
            CALL CFA1                       ; $88C4 CD A1 CF
            LD HL,(D9B3)                    ; $88C7 2A B3 D9
            LD (HL),03                      ; $88CA 36 03
            INC HL                          ; $88CC 23
            LD (HL),00                      ; $88CD 36 00
            CALL D1FE                       ; $88CF CD FE D1
            LD C,FF                         ; $88D2 0E FF
            CALL D205                       ; $88D4 CD 05 D2
            CALL D1F5                       ; $88D7 CD F5 D1
            RET Z                           ; $88DA C8
            CALL D15E                       ; $88DB CD 5E D1
            LD A,E5                         ; $88DE 3E E5
            CP (HL)                         ; $88E0 BE
            JP Z,D2D2                       ; $88E1 CA D2 D2
            LD A,(CF41)                     ; $88E4 3A 41 CF
            CP (HL)                         ; $88E7 BE
            JP NZ,D2F6                      ; $88E8 C2 F6 D2
            INC HL                          ; $88EB 23
            LD A,(HL)                       ; $88EC 7E
            SUB 24                          ; $88ED D6 24
            JP NZ,D2F6                      ; $88EF C2 F6 D2
            DEC A                           ; $88F2 3D
            LD (CF45),A                     ; $88F3 32 45 CF
            LD C,01                         ; $88F6 0E 01
            CALL D26B                       ; $88F8 CD 6B D2
            CALL D18C                       ; $88FB CD 8C D1
            JP CAD2                         ; $88FE C3 D2 CA
            POP HL                          ; $8901 E1
            DEC A                           ; $8902 3D
            JP NZ,CB71                      ; $8903 C2 71 CB
            CALL C866                       ; $8906 CD 66 C8
            CALL C65E                       ; $8909 CD 5E C6
            LD HL,CBF0                      ; $890C 21 F0 CB
            PUSH HL                         ; $890F E5
            LD A,(HL)                       ; $8910 7E
            LD (CBCD),A                     ; $8911 32 CD CB
            LD A,10                         ; $8914 3E 10
            CALL C660                       ; $8916 CD 60 C6
            POP HL                          ; $8919 E1
            LD A,(HL)                       ; $891A 7E
            LD (CBDD),A                     ; $891B 32 DD CB
            XOR A                           ; $891E AF
            LD (CBED),A                     ; $891F 32 ED CB
            LD DE,005C                      ; $8922 11 5C 00
            LD HL,CBCD                      ; $8925 21 CD CB
            LD B,21                         ; $8928 06 21
            CALL C842                       ; $892A CD 42 C8
            LD HL,C408                      ; $892D 21 08 C4
            LD A,(HL)                       ; $8930 7E
            OR A                            ; $8931 B7
            JP Z,CB3E                       ; $8932 CA 3E CB
            CP 20                           ; $8935 FE 20
            JP Z,CB3E                       ; $8937 CA 3E CB
            INC HL                          ; $893A 23
            JP CB30                         ; $893B C3 30 CB
            LD B,00                         ; $893E 06 00
            LD DE,0081                      ; $8940 11 81 00
            LD A,(HL)                       ; $8943 7E
            LD (DE),A                       ; $8944 12
            OR A                            ; $8945 B7
            JP Z,CB4F                       ; $8946 CA 4F CB
            INC B                           ; $8949 04
            INC HL                          ; $894A 23
            INC DE                          ; $894B 13
            JP CB43                         ; $894C C3 43 CB
            LD A,B                          ; $894F 78
            LD (0080),A                     ; $8950 32 80 00
            CALL C498                       ; $8953 CD 98 C4
            CALL C5D5                       ; $8956 CD D5 C5
            CALL C51A                       ; $8959 CD 1A C5
            CALL 0100                       ; $895C CD 00 01
            LD SP,CBAB                      ; $895F 31 AB CB
            CALL C529                       ; $8962 CD 29 C5
            CALL C4BD                       ; $8965 CD BD C4
            JP C782                         ; $8968 C3 82 C7
            CALL C866                       ; $896B CD 66 C8
            JP C609                         ; $896E C3 09 C6
            LD BC,CB7A                      ; $8971 01 7A CB
            CALL C4A7                       ; $8974 CD A7 C4
            JP CB86                         ; $8977 C3 86 CB
            LD B,D                          ; $897A 42
            LD B,C                          ; $897B 41
            LD B,H                          ; $897C 44
            JR NZ,89CB                      ; $897D 20 4C
            LD C,A                          ; $897F 4F
            LD B,C                          ; $8980 41
            LD B,H                          ; $8981 44
            NOP                             ; $8982 00
            LD B,E                          ; $8983 43
            LD C,A                          ; $8984 4F
            LD C,L                          ; $8985 4D
            CALL C866                       ; $8986 CD 66 C8
            CALL C65E                       ; $8989 CD 5E C6
            LD A,(CBCE)                     ; $898C 3A CE CB
            SUB 20                          ; $898F D6 20
            LD HL,CBF0                      ; $8991 21 F0 CB
            OR (HL)                         ; $8994 B6
            JP NZ,C609                      ; $8995 C2 09 C6
            JP C782                         ; $8998 C3 82 C7
            NOP                             ; $899B 00
            NOP                             ; $899C 00
            NOP                             ; $899D 00
            NOP                             ; $899E 00
            NOP                             ; $899F 00
            NOP                             ; $89A0 00
            NOP                             ; $89A1 00
            NOP                             ; $89A2 00
            NOP                             ; $89A3 00
            NOP                             ; $89A4 00
            NOP                             ; $89A5 00
            NOP                             ; $89A6 00
            NOP                             ; $89A7 00
            NOP                             ; $89A8 00
            NOP                             ; $89A9 00
            NOP                             ; $89AA 00
            NOP                             ; $89AB 00
            NOP                             ; $89AC 00
            INC H                           ; $89AD 24
            INC H                           ; $89AE 24
            INC H                           ; $89AF 24
            JR NZ,89D2                      ; $89B0 20 20
            JR NZ,89D4                      ; $89B2 20 20
            JR NZ,8A09                      ; $89B4 20 53
            LD D,L                          ; $89B6 55
            LD B,D                          ; $89B7 42
            NOP                             ; $89B8 00
            NOP                             ; $89B9 00
            NOP                             ; $89BA 00
            NOP                             ; $89BB 00
            NOP                             ; $89BC 00
            NOP                             ; $89BD 00
            NOP                             ; $89BE 00
            NOP                             ; $89BF 00
            NOP                             ; $89C0 00
            NOP                             ; $89C1 00
            NOP                             ; $89C2 00
            NOP                             ; $89C3 00
            NOP                             ; $89C4 00
            NOP                             ; $89C5 00
            NOP                             ; $89C6 00
            NOP                             ; $89C7 00
            NOP                             ; $89C8 00
            NOP                             ; $89C9 00
            NOP                             ; $89CA 00
            NOP                             ; $89CB 00
            NOP                             ; $89CC 00
            NOP                             ; $89CD 00
            NOP                             ; $89CE 00
            NOP                             ; $89CF 00
            NOP                             ; $89D0 00
            NOP                             ; $89D1 00
            NOP                             ; $89D2 00
            NOP                             ; $89D3 00
            NOP                             ; $89D4 00
            NOP                             ; $89D5 00
            NOP                             ; $89D6 00
            NOP                             ; $89D7 00
            NOP                             ; $89D8 00
            NOP                             ; $89D9 00
            NOP                             ; $89DA 00
            NOP                             ; $89DB 00
            NOP                             ; $89DC 00
            NOP                             ; $89DD 00
            NOP                             ; $89DE 00
            NOP                             ; $89DF 00
            NOP                             ; $89E0 00
            NOP                             ; $89E1 00
            NOP                             ; $89E2 00
            NOP                             ; $89E3 00
            NOP                             ; $89E4 00
            NOP                             ; $89E5 00
            NOP                             ; $89E6 00
            NOP                             ; $89E7 00
            NOP                             ; $89E8 00
            NOP                             ; $89E9 00
            NOP                             ; $89EA 00
            NOP                             ; $89EB 00
            NOP                             ; $89EC 00
            NOP                             ; $89ED 00
            NOP                             ; $89EE 00
            NOP                             ; $89EF 00
            NOP                             ; $89F0 00
            NOP                             ; $89F1 00
            NOP                             ; $89F2 00
            NOP                             ; $89F3 00
            NOP                             ; $89F4 00
            NOP                             ; $89F5 00
            NOP                             ; $89F6 00
            NOP                             ; $89F7 00
            NOP                             ; $89F8 00
            NOP                             ; $89F9 00
            NOP                             ; $89FA 00
            NOP                             ; $89FB 00
            NOP                             ; $89FC 00
            NOP                             ; $89FD 00
            NOP                             ; $89FE 00
            NOP                             ; $89FF 00
            JP NC,D43A                      ; $8A00 D2 3A D4
            EXX                             ; $8A03 D9
            JP CF01                         ; $8A04 C3 01 CF
            PUSH BC                         ; $8A07 C5
            PUSH AF                         ; $8A08 F5
            LD A,(D9C5)                     ; $8A09 3A C5 D9
            CPL                             ; $8A0C 2F
            LD B,A                          ; $8A0D 47
            LD A,C                          ; $8A0E 79
            AND B                           ; $8A0F A0
            LD C,A                          ; $8A10 4F
            POP AF                          ; $8A11 F1
            AND B                           ; $8A12 A0
            SUB C                           ; $8A13 91
            AND 1F                          ; $8A14 E6 1F
            POP BC                          ; $8A16 C1
            RET                             ; $8A17 C9
            LD A,FF                         ; $8A18 3E FF
            LD (D9D4),A                     ; $8A1A 32 D4 D9
            LD HL,D9D8                      ; $8A1D 21 D8 D9
            LD (HL),C                       ; $8A20 71
            LD HL,(CF43)                    ; $8A21 2A 43 CF
            LD (D9D9),HL                    ; $8A24 22 D9 D9
            CALL D1FE                       ; $8A27 CD FE D1
            CALL CFA1                       ; $8A2A CD A1 CF
            LD C,00                         ; $8A2D 0E 00
            CALL D205                       ; $8A2F CD 05 D2
            CALL D1F5                       ; $8A32 CD F5 D1
            JP Z,D394                       ; $8A35 CA 94 D3
            LD HL,(D9D9)                    ; $8A38 2A D9 D9
            EX DE,HL                        ; $8A3B EB
            LD A,(DE)                       ; $8A3C 1A
            CP E5                           ; $8A3D FE E5
            JP Z,D34A                       ; $8A3F CA 4A D3
            PUSH DE                         ; $8A42 D5
            CALL D17F                       ; $8A43 CD 7F D1
            POP DE                          ; $8A46 D1
            JP NC,D394                      ; $8A47 D2 94 D3
            CALL D15E                       ; $8A4A CD 5E D1
            LD A,(D9D8)                     ; $8A4D 3A D8 D9
            LD C,A                          ; $8A50 4F
            LD B,00                         ; $8A51 06 00
            LD A,C                          ; $8A53 79
            OR A                            ; $8A54 B7
            JP Z,D383                       ; $8A55 CA 83 D3
            LD A,(DE)                       ; $8A58 1A
            CP 3F                           ; $8A59 FE 3F
            JP Z,D37C                       ; $8A5B CA 7C D3
            LD A,B                          ; $8A5E 78
            CP 0D                           ; $8A5F FE 0D
            JP Z,D37C                       ; $8A61 CA 7C D3
            CP 0C                           ; $8A64 FE 0C
            LD A,(DE)                       ; $8A66 1A
            JP Z,D373                       ; $8A67 CA 73 D3
            SUB (HL)                        ; $8A6A 96
            AND 7F                          ; $8A6B E6 7F
            JP NZ,D32D                      ; $8A6D C2 2D D3
            JP D37C                         ; $8A70 C3 7C D3
            PUSH BC                         ; $8A73 C5
            LD C,(HL)                       ; $8A74 4E
            CALL D307                       ; $8A75 CD 07 D3
            POP BC                          ; $8A78 C1
            JP NZ,D32D                      ; $8A79 C2 2D D3
            INC DE                          ; $8A7C 13
            INC HL                          ; $8A7D 23
            INC B                           ; $8A7E 04
            DEC C                           ; $8A7F 0D
            JP D353                         ; $8A80 C3 53 D3
            LD A,(D9EA)                     ; $8A83 3A EA D9
            AND 03                          ; $8A86 E6 03
            LD (CF45),A                     ; $8A88 32 45 CF
            LD HL,D9D4                      ; $8A8B 21 D4 D9
            LD A,(HL)                       ; $8A8E 7E
            RLA                             ; $8A8F 17
            RET NC                          ; $8A90 D0
            XOR A                           ; $8A91 AF
            LD (HL),A                       ; $8A92 77
            RET                             ; $8A93 C9
            CALL D1FE                       ; $8A94 CD FE D1
            LD A,FF                         ; $8A97 3E FF
            JP CF01                         ; $8A99 C3 01 CF
            CALL D154                       ; $8A9C CD 54 D1
            LD C,0C                         ; $8A9F 0E 0C
            CALL D318                       ; $8AA1 CD 18 D3
            CALL D1F5                       ; $8AA4 CD F5 D1
            RET Z                           ; $8AA7 C8
            CALL D144                       ; $8AA8 CD 44 D1
            CALL D15E                       ; $8AAB CD 5E D1
            LD (HL),E5                      ; $8AAE 36 E5
            LD C,00                         ; $8AB0 0E 00
            CALL D26B                       ; $8AB2 CD 6B D2
            CALL D1C6                       ; $8AB5 CD C6 D1
            CALL D32D                       ; $8AB8 CD 2D D3
            JP D3A4                         ; $8ABB C3 A4 D3
            LD D,B                          ; $8ABE 50
            LD E,C                          ; $8ABF 59
            LD A,C                          ; $8AC0 79
            OR B                            ; $8AC1 B0
            JP Z,D3D1                       ; $8AC2 CA D1 D3
            DEC BC                          ; $8AC5 0B
            PUSH DE                         ; $8AC6 D5
            PUSH BC                         ; $8AC7 C5
            CALL D235                       ; $8AC8 CD 35 D2
            RRA                             ; $8ACB 1F
            JP NC,D3EC                      ; $8ACC D2 EC D3
            POP BC                          ; $8ACF C1
            POP DE                          ; $8AD0 D1
            LD HL,(D9C6)                    ; $8AD1 2A C6 D9
            LD A,E                          ; $8AD4 7B
            SUB L                           ; $8AD5 95
            LD A,D                          ; $8AD6 7A
            SBC A,H                         ; $8AD7 9C
            JP NC,D3F4                      ; $8AD8 D2 F4 D3
            INC DE                          ; $8ADB 13
            PUSH BC                         ; $8ADC C5
            PUSH DE                         ; $8ADD D5
            LD B,D                          ; $8ADE 42
            LD C,E                          ; $8ADF 4B
            CALL D235                       ; $8AE0 CD 35 D2
            RRA                             ; $8AE3 1F
            JP NC,D3EC                      ; $8AE4 D2 EC D3
            POP DE                          ; $8AE7 D1
            POP BC                          ; $8AE8 C1
            JP D3C0                         ; $8AE9 C3 C0 D3
            RLA                             ; $8AEC 17
            INC A                           ; $8AED 3C
            CALL D264                       ; $8AEE CD 64 D2
            POP HL                          ; $8AF1 E1
            POP DE                          ; $8AF2 D1
            RET                             ; $8AF3 C9
            LD A,C                          ; $8AF4 79
            OR B                            ; $8AF5 B0
            JP NZ,D3C0                      ; $8AF6 C2 C0 D3
            LD HL,0000                      ; $8AF9 21 00 00
            RET                             ; $8AFC C9
            LD C,00                         ; $8AFD 0E 00
            LD E,BD                         ; $8AFF 1E BD
            LD D,00                         ; $8B01 16 00
            NOP                             ; $8B03 00
            LD H,B                          ; $8B04 60
            EXX                             ; $8B05 D9
            JP CC11                         ; $8B06 C3 11 CC
            SBC A,C                         ; $8B09 99
            CALL Z,CCA5                     ; $8B0A CC A5 CC
            XOR E                           ; $8B0D AB
            CALL Z,CCB1                     ; $8B0E CC B1 CC
            EX DE,HL                        ; $8B11 EB
            LD (CF43),HL                    ; $8B12 22 43 CF
            EX DE,HL                        ; $8B15 EB
            LD A,E                          ; $8B16 7B
            LD (D9D6),A                     ; $8B17 32 D6 D9
            LD HL,0000                      ; $8B1A 21 00 00
            LD (CF45),HL                    ; $8B1D 22 45 CF
            ADD HL,SP                       ; $8B20 39
            LD (CF0F),HL                    ; $8B21 22 0F CF
            LD SP,CF41                      ; $8B24 31 41 CF
            XOR A                           ; $8B27 AF
            LD (D9E0),A                     ; $8B28 32 E0 D9
            LD (D9DE),A                     ; $8B2B 32 DE D9
            LD HL,D974                      ; $8B2E 21 74 D9
            PUSH HL                         ; $8B31 E5
            LD A,C                          ; $8B32 79
            CP 29                           ; $8B33 FE 29
            RET NC                          ; $8B35 D0
            LD C,E                          ; $8B36 4B
            LD HL,CC47                      ; $8B37 21 47 CC
            LD E,A                          ; $8B3A 5F
            LD D,00                         ; $8B3B 16 00
            ADD HL,DE                       ; $8B3D 19
            ADD HL,DE                       ; $8B3E 19
            LD E,(HL)                       ; $8B3F 5E
            INC HL                          ; $8B40 23
            LD D,(HL)                       ; $8B41 56
            LD HL,(CF43)                    ; $8B42 2A 43 CF
            EX DE,HL                        ; $8B45 EB
            JP (HL)                         ; $8B46 E9
            INC BC                          ; $8B47 03
            JP C,CEC8                       ; $8B48 DA C8 CE
            SUB B                           ; $8B4B 90
            CALL CECE                       ; $8B4C CD CE CE
            LD (DE),A                       ; $8B4F 12
            JP C,DA0F                       ; $8B50 DA 0F DA
            CALL NC,EDCE                    ; $8B53 D4 CE ED
            ADC A,F3                        ; $8B56 CE F3
            ADC A,F8                        ; $8B58 CE F8
            ADC A,E1                        ; $8B5A CE E1
            CALL CEFE                       ; $8B5C CD FE CE
            LD A,(HL)                       ; $8B5F 7E
            RET C                           ; $8B60 D8
            ADD A,E                         ; $8B61 83
            RET C                           ; $8B62 D8
            LD B,L                          ; $8B63 45
            RET C                           ; $8B64 D8
            SBC A,H                         ; $8B65 9C
            RET C                           ; $8B66 D8
            AND L                           ; $8B67 A5
            RET C                           ; $8B68 D8
            XOR E                           ; $8B69 AB
            RET C                           ; $8B6A D8
            RET Z                           ; $8B6B C8
            RET C                           ; $8B6C D8
            RST $10                         ; $8B6D D7
            RET C                           ; $8B6E D8
            RET PO                          ; $8B6F E0
            RET C                           ; $8B70 D8
            AND D8                          ; $8B71 E6 D8
            CALL PE,F5D8                    ; $8B73 EC D8 F5
            RET C                           ; $8B76 D8
            CP D8                           ; $8B77 FE D8
            INC B                           ; $8B79 04
            EXX                             ; $8B7A D9
            LD A,(BC)                       ; $8B7B 0A
            EXX                             ; $8B7C D9
            LD DE,2CD9                      ; $8B7D 11 D9 2C
            POP DE                          ; $8B80 D1
            RLA                             ; $8B81 17
            EXX                             ; $8B82 D9
            DEC E                           ; $8B83 1D
            EXX                             ; $8B84 D9
            LD H,D9                         ; $8B85 26 D9
            DEC L                           ; $8B87 2D
            EXX                             ; $8B88 D9
            LD B,C                          ; $8B89 41
            EXX                             ; $8B8A D9
            LD B,A                          ; $8B8B 47
            EXX                             ; $8B8C D9
            LD C,L                          ; $8B8D 4D
            EXX                             ; $8B8E D9
            LD C,D8                         ; $8B8F 0E D8
            LD D,E                          ; $8B91 53
            EXX                             ; $8B92 D9
            INC B                           ; $8B93 04
            RST $08                         ; $8B94 CF
            INC B                           ; $8B95 04
            RST $08                         ; $8B96 CF
            SBC A,E                         ; $8B97 9B
            EXX                             ; $8B98 D9
            LD HL,CCCA                      ; $8B99 21 CA CC
            CALL CCE5                       ; $8B9C CD E5 CC
            CP 03                           ; $8B9F FE 03
            JP Z,0000                       ; $8BA1 CA 00 00
            RET                             ; $8BA4 C9
            LD HL,CCD5                      ; $8BA5 21 D5 CC
            JP CCB4                         ; $8BA8 C3 B4 CC
            LD HL,CCE1                      ; $8BAB 21 E1 CC
            JP CCB4                         ; $8BAE C3 B4 CC
            LD HL,CCDC                      ; $8BB1 21 DC CC
            CALL CCE5                       ; $8BB4 CD E5 CC
            JP 0000                         ; $8BB7 C3 00 00
            LD B,D                          ; $8BBA 42
            LD H,H                          ; $8BBB 64
            LD L,A                          ; $8BBC 6F
            LD (HL),E                       ; $8BBD 73
            JR NZ,8C05                      ; $8BBE 20 45
            LD (HL),D                       ; $8BC0 72
            LD (HL),D                       ; $8BC1 72
            JR NZ,8C13                      ; $8BC2 20 4F
            LD L,(HL)                       ; $8BC4 6E
            JR NZ,8BE7                      ; $8BC5 20 20
            LD A,(2420)                     ; $8BC7 3A 20 24
            LD B,D                          ; $8BCA 42
            LD H,C                          ; $8BCB 61
            LD H,H                          ; $8BCC 64
            JR NZ,8C22                      ; $8BCD 20 53
            LD H,L                          ; $8BCF 65
            LD H,E                          ; $8BD0 63
            LD (HL),H                       ; $8BD1 74
            LD L,A                          ; $8BD2 6F
            LD (HL),D                       ; $8BD3 72
            INC H                           ; $8BD4 24
            LD D,E                          ; $8BD5 53
            LD H,L                          ; $8BD6 65
            LD L,H                          ; $8BD7 6C
            LD H,L                          ; $8BD8 65
            LD H,E                          ; $8BD9 63
            LD (HL),H                       ; $8BDA 74
            INC H                           ; $8BDB 24
            LD B,(HL)                       ; $8BDC 46
            LD L,C                          ; $8BDD 69
            LD L,H                          ; $8BDE 6C
            LD H,L                          ; $8BDF 65
            JR NZ,8C34                      ; $8BE0 20 52
            CPL                             ; $8BE2 2F
            LD C,A                          ; $8BE3 4F
            INC H                           ; $8BE4 24
            PUSH HL                         ; $8BE5 E5
            CALL CDC9                       ; $8BE6 CD C9 CD
            LD A,(CF42)                     ; $8BE9 3A 42 CF
            ADD A,41                        ; $8BEC C6 41
            LD (CCC6),A                     ; $8BEE 32 C6 CC
            LD BC,CCBA                      ; $8BF1 01 BA CC
            CALL CDD3                       ; $8BF4 CD D3 CD
            POP BC                          ; $8BF7 C1
            CALL CDD3                       ; $8BF8 CD D3 CD
            LD HL,CF0E                      ; $8BFB 21 0E CF
            LD A,(HL)                       ; $8BFE 7E
            LD (HL),20                      ; $8BFF 36 20
            PUSH DE                         ; $8C01 D5
            LD B,00                         ; $8C02 06 00
            LD HL,(CF43)                    ; $8C04 2A 43 CF
            ADD HL,BC                       ; $8C07 09
            EX DE,HL                        ; $8C08 EB
            CALL D15E                       ; $8C09 CD 5E D1
            POP BC                          ; $8C0C C1
            CALL CF4F                       ; $8C0D CD 4F CF
            CALL CFC3                       ; $8C10 CD C3 CF
            JP D1C6                         ; $8C13 C3 C6 D1
            CALL D154                       ; $8C16 CD 54 D1
            LD C,0C                         ; $8C19 0E 0C
            CALL D318                       ; $8C1B CD 18 D3
            LD HL,(CF43)                    ; $8C1E 2A 43 CF
            LD A,(HL)                       ; $8C21 7E
            LD DE,0010                      ; $8C22 11 10 00
            ADD HL,DE                       ; $8C25 19
            LD (HL),A                       ; $8C26 77
            CALL D1F5                       ; $8C27 CD F5 D1
            RET Z                           ; $8C2A C8
            CALL D144                       ; $8C2B CD 44 D1
            LD C,10                         ; $8C2E 0E 10
            LD E,0C                         ; $8C30 1E 0C
            CALL D401                       ; $8C32 CD 01 D4
            CALL D32D                       ; $8C35 CD 2D D3
            JP D427                         ; $8C38 C3 27 D4
            LD C,0C                         ; $8C3B 0E 0C
            CALL D318                       ; $8C3D CD 18 D3
            CALL D1F5                       ; $8C40 CD F5 D1
            RET Z                           ; $8C43 C8
            LD C,00                         ; $8C44 0E 00
            LD E,0C                         ; $8C46 1E 0C
            CALL D401                       ; $8C48 CD 01 D4
            CALL D32D                       ; $8C4B CD 2D D3
            JP D440                         ; $8C4E C3 40 D4
            LD C,0F                         ; $8C51 0E 0F
            CALL D318                       ; $8C53 CD 18 D3
            CALL D1F5                       ; $8C56 CD F5 D1
            RET Z                           ; $8C59 C8
            CALL D0A6                       ; $8C5A CD A6 D0
            LD A,(HL)                       ; $8C5D 7E
            PUSH AF                         ; $8C5E F5
            PUSH HL                         ; $8C5F E5
            CALL D15E                       ; $8C60 CD 5E D1
            EX DE,HL                        ; $8C63 EB
            LD HL,(CF43)                    ; $8C64 2A 43 CF
            LD C,20                         ; $8C67 0E 20
            PUSH DE                         ; $8C69 D5
            CALL CF4F                       ; $8C6A CD 4F CF
            CALL D178                       ; $8C6D CD 78 D1
            POP DE                          ; $8C70 D1
            LD HL,000C                      ; $8C71 21 0C 00
            ADD HL,DE                       ; $8C74 19
            LD C,(HL)                       ; $8C75 4E
            LD HL,000F                      ; $8C76 21 0F 00
            ADD HL,DE                       ; $8C79 19
            LD B,(HL)                       ; $8C7A 46
            POP HL                          ; $8C7B E1
            POP AF                          ; $8C7C F1
            LD (HL),A                       ; $8C7D 77
            LD A,C                          ; $8C7E 79
            CP (HL)                         ; $8C7F BE
            LD A,B                          ; $8C80 78
            JP Z,D48B                       ; $8C81 CA 8B D4
            LD A,00                         ; $8C84 3E 00
            JP C,D48B                       ; $8C86 DA 8B D4
            LD A,80                         ; $8C89 3E 80
            LD HL,(CF43)                    ; $8C8B 2A 43 CF
            LD DE,000F                      ; $8C8E 11 0F 00
            ADD HL,DE                       ; $8C91 19
            LD (HL),A                       ; $8C92 77
            RET                             ; $8C93 C9
            LD A,(HL)                       ; $8C94 7E
            INC HL                          ; $8C95 23
            OR (HL)                         ; $8C96 B6
            DEC HL                          ; $8C97 2B
            RET NZ                          ; $8C98 C0
            LD A,(DE)                       ; $8C99 1A
            LD (HL),A                       ; $8C9A 77
            INC DE                          ; $8C9B 13
            INC HL                          ; $8C9C 23
            LD A,(DE)                       ; $8C9D 1A
            LD (HL),A                       ; $8C9E 77
            DEC DE                          ; $8C9F 1B
            DEC HL                          ; $8CA0 2B
            RET                             ; $8CA1 C9
            XOR A                           ; $8CA2 AF
            LD (CF45),A                     ; $8CA3 32 45 CF
            LD (D9EA),A                     ; $8CA6 32 EA D9
            LD (D9EB),A                     ; $8CA9 32 EB D9
            CALL D11E                       ; $8CAC CD 1E D1
            RET NZ                          ; $8CAF C0
            CALL D169                       ; $8CB0 CD 69 D1
            AND 80                          ; $8CB3 E6 80
            RET NZ                          ; $8CB5 C0
            LD C,0F                         ; $8CB6 0E 0F
            CALL D318                       ; $8CB8 CD 18 D3
            CALL D1F5                       ; $8CBB CD F5 D1
            RET Z                           ; $8CBE C8
            LD BC,0010                      ; $8CBF 01 10 00
            CALL D15E                       ; $8CC2 CD 5E D1
            ADD HL,BC                       ; $8CC5 09
            EX DE,HL                        ; $8CC6 EB
            LD HL,(CF43)                    ; $8CC7 2A 43 CF
            ADD HL,BC                       ; $8CCA 09
            LD C,10                         ; $8CCB 0E 10
            LD A,(D9DD)                     ; $8CCD 3A DD D9
            OR A                            ; $8CD0 B7
            JP Z,D4E8                       ; $8CD1 CA E8 D4
            LD A,(HL)                       ; $8CD4 7E
            OR A                            ; $8CD5 B7
            LD A,(DE)                       ; $8CD6 1A
            JP NZ,D4DB                      ; $8CD7 C2 DB D4
            LD (HL),A                       ; $8CDA 77
            OR A                            ; $8CDB B7
            JP NZ,D4E1                      ; $8CDC C2 E1 D4
            LD A,(HL)                       ; $8CDF 7E
            LD (DE),A                       ; $8CE0 12
            CP (HL)                         ; $8CE1 BE
            JP NZ,D51F                      ; $8CE2 C2 1F D5
            JP D4FD                         ; $8CE5 C3 FD D4
            CALL D494                       ; $8CE8 CD 94 D4
            EX DE,HL                        ; $8CEB EB
            CALL D494                       ; $8CEC CD 94 D4
            EX DE,HL                        ; $8CEF EB
            LD A,(DE)                       ; $8CF0 1A
            CP (HL)                         ; $8CF1 BE
            JP NZ,D51F                      ; $8CF2 C2 1F D5
            INC DE                          ; $8CF5 13
            INC HL                          ; $8CF6 23
            LD A,(DE)                       ; $8CF7 1A
            CP (HL)                         ; $8CF8 BE
            JP NZ,D51F                      ; $8CF9 C2 1F D5
            DEC C                           ; $8CFC 0D
            INC DE                          ; $8CFD 13
            INC HL                          ; $8CFE 23
            DEC C                           ; $8CFF 0D
            NOP                             ; $8D00 00
            OR A                            ; $8D01 B7
            RET NZ                          ; $8D02 C0
            JP DA09                         ; $8D03 C3 09 DA
            CALL CCFB                       ; $8D06 CD FB CC
            CALL CD14                       ; $8D09 CD 14 CD
            RET C                           ; $8D0C D8
            PUSH AF                         ; $8D0D F5
            LD C,A                          ; $8D0E 4F
            CALL CD90                       ; $8D0F CD 90 CD
            POP AF                          ; $8D12 F1
            RET                             ; $8D13 C9
            CP 0D                           ; $8D14 FE 0D
            RET Z                           ; $8D16 C8
            CP 0A                           ; $8D17 FE 0A
            RET Z                           ; $8D19 C8
            CP 09                           ; $8D1A FE 09
            RET Z                           ; $8D1C C8
            CP 08                           ; $8D1D FE 08
            RET Z                           ; $8D1F C8
            CP 20                           ; $8D20 FE 20
            RET                             ; $8D22 C9
            LD A,(CF0E)                     ; $8D23 3A 0E CF
            OR A                            ; $8D26 B7
            JP NZ,CD45                      ; $8D27 C2 45 CD
            CALL DA06                       ; $8D2A CD 06 DA
            AND 01                          ; $8D2D E6 01
            RET Z                           ; $8D2F C8
            CALL DA09                       ; $8D30 CD 09 DA
            CP 13                           ; $8D33 FE 13
            JP NZ,CD42                      ; $8D35 C2 42 CD
            CALL DA09                       ; $8D38 CD 09 DA
            CP 03                           ; $8D3B FE 03
            JP Z,0000                       ; $8D3D CA 00 00
            XOR A                           ; $8D40 AF
            RET                             ; $8D41 C9
            LD (CF0E),A                     ; $8D42 32 0E CF
            LD A,01                         ; $8D45 3E 01
            RET                             ; $8D47 C9
            LD A,(CF0A)                     ; $8D48 3A 0A CF
            OR A                            ; $8D4B B7
            JP NZ,CD62                      ; $8D4C C2 62 CD
            PUSH BC                         ; $8D4F C5
            CALL CD23                       ; $8D50 CD 23 CD
            POP BC                          ; $8D53 C1
            PUSH BC                         ; $8D54 C5
            CALL DA0C                       ; $8D55 CD 0C DA
            POP BC                          ; $8D58 C1
            PUSH BC                         ; $8D59 C5
            LD A,(CF0D)                     ; $8D5A 3A 0D CF
            OR A                            ; $8D5D B7
            CALL NZ,DA0F                    ; $8D5E C4 0F DA
            POP BC                          ; $8D61 C1
            LD A,C                          ; $8D62 79
            LD HL,CF0C                      ; $8D63 21 0C CF
            CP 7F                           ; $8D66 FE 7F
            RET Z                           ; $8D68 C8
            INC (HL)                        ; $8D69 34
            CP 20                           ; $8D6A FE 20
            RET NC                          ; $8D6C D0
            DEC (HL)                        ; $8D6D 35
            LD A,(HL)                       ; $8D6E 7E
            OR A                            ; $8D6F B7
            RET Z                           ; $8D70 C8
            LD A,C                          ; $8D71 79
            CP 08                           ; $8D72 FE 08
            JP NZ,CD79                      ; $8D74 C2 79 CD
            DEC (HL)                        ; $8D77 35
            RET                             ; $8D78 C9
            CP 0A                           ; $8D79 FE 0A
            RET NZ                          ; $8D7B C0
            LD (HL),00                      ; $8D7C 36 00
            RET                             ; $8D7E C9
            LD A,C                          ; $8D7F 79
            CALL CD14                       ; $8D80 CD 14 CD
            JP NC,CD90                      ; $8D83 D2 90 CD
            PUSH AF                         ; $8D86 F5
            LD C,5E                         ; $8D87 0E 5E
            CALL CD48                       ; $8D89 CD 48 CD
            POP AF                          ; $8D8C F1
            OR 40                           ; $8D8D F6 40
            LD C,A                          ; $8D8F 4F
            LD A,C                          ; $8D90 79
            CP 09                           ; $8D91 FE 09
            JP NZ,CD48                      ; $8D93 C2 48 CD
            LD C,20                         ; $8D96 0E 20
            CALL CD48                       ; $8D98 CD 48 CD
            LD A,(CF0C)                     ; $8D9B 3A 0C CF
            AND 07                          ; $8D9E E6 07
            JP NZ,CD96                      ; $8DA0 C2 96 CD
            RET                             ; $8DA3 C9
            CALL CDAC                       ; $8DA4 CD AC CD
            LD C,20                         ; $8DA7 0E 20
            CALL DA0C                       ; $8DA9 CD 0C DA
            LD C,08                         ; $8DAC 0E 08
            JP DA0C                         ; $8DAE C3 0C DA
            LD C,23                         ; $8DB1 0E 23
            CALL CD48                       ; $8DB3 CD 48 CD
            CALL CDC9                       ; $8DB6 CD C9 CD
            LD A,(CF0C)                     ; $8DB9 3A 0C CF
            LD HL,CF0B                      ; $8DBC 21 0B CF
            CP (HL)                         ; $8DBF BE
            RET NC                          ; $8DC0 D0
            LD C,20                         ; $8DC1 0E 20
            CALL CD48                       ; $8DC3 CD 48 CD
            JP CDB9                         ; $8DC6 C3 B9 CD
            LD C,0D                         ; $8DC9 0E 0D
            CALL CD48                       ; $8DCB CD 48 CD
            LD C,0A                         ; $8DCE 0E 0A
            JP CD48                         ; $8DD0 C3 48 CD
            LD A,(BC)                       ; $8DD3 0A
            CP 24                           ; $8DD4 FE 24
            RET Z                           ; $8DD6 C8
            INC BC                          ; $8DD7 03
            PUSH BC                         ; $8DD8 C5
            LD C,A                          ; $8DD9 4F
            CALL CD90                       ; $8DDA CD 90 CD
            POP BC                          ; $8DDD C1
            JP CDD3                         ; $8DDE C3 D3 CD
            LD A,(CF0C)                     ; $8DE1 3A 0C CF
            LD (CF0B),A                     ; $8DE4 32 0B CF
            LD HL,(CF43)                    ; $8DE7 2A 43 CF
            LD C,(HL)                       ; $8DEA 4E
            INC HL                          ; $8DEB 23
            PUSH HL                         ; $8DEC E5
            LD B,00                         ; $8DED 06 00
            PUSH BC                         ; $8DEF C5
            PUSH HL                         ; $8DF0 E5
            CALL CCFB                       ; $8DF1 CD FB CC
            AND 7F                          ; $8DF4 E6 7F
            POP HL                          ; $8DF6 E1
            POP BC                          ; $8DF7 C1
            CP 0D                           ; $8DF8 FE 0D
            JP Z,CEC1                       ; $8DFA CA C1 CE
            CP 0A                           ; $8DFD FE 0A
            JP Z,CDC2                       ; $8DFF CA C2 CD
            CALL NC,EC01                    ; $8E02 D4 01 EC
            RST $38                         ; $8E05 FF
            ADD HL,BC                       ; $8E06 09
            EX DE,HL                        ; $8E07 EB
            ADD HL,BC                       ; $8E08 09
            LD A,(DE)                       ; $8E09 1A
            CP (HL)                         ; $8E0A BE
            JP C,D517                       ; $8E0B DA 17 D5
            LD (HL),A                       ; $8E0E 77
            LD BC,0003                      ; $8E0F 01 03 00
            ADD HL,BC                       ; $8E12 09
            EX DE,HL                        ; $8E13 EB
            ADD HL,BC                       ; $8E14 09
            LD A,(HL)                       ; $8E15 7E
            LD (DE),A                       ; $8E16 12
            LD A,FF                         ; $8E17 3E FF
            LD (D9D2),A                     ; $8E19 32 D2 D9
            JP D410                         ; $8E1C C3 10 D4
            LD HL,CF45                      ; $8E1F 21 45 CF
            DEC (HL)                        ; $8E22 35
            RET                             ; $8E23 C9
            CALL D154                       ; $8E24 CD 54 D1
            LD HL,(CF43)                    ; $8E27 2A 43 CF
            PUSH HL                         ; $8E2A E5
            LD HL,D9AC                      ; $8E2B 21 AC D9
            LD (CF43),HL                    ; $8E2E 22 43 CF
            LD C,01                         ; $8E31 0E 01
            CALL D318                       ; $8E33 CD 18 D3
            CALL D1F5                       ; $8E36 CD F5 D1
            POP HL                          ; $8E39 E1
            LD (CF43),HL                    ; $8E3A 22 43 CF
            RET Z                           ; $8E3D C8
            EX DE,HL                        ; $8E3E EB
            LD HL,000F                      ; $8E3F 21 0F 00
            ADD HL,DE                       ; $8E42 19
            LD C,11                         ; $8E43 0E 11
            XOR A                           ; $8E45 AF
            LD (HL),A                       ; $8E46 77
            INC HL                          ; $8E47 23
            DEC C                           ; $8E48 0D
            JP NZ,D546                      ; $8E49 C2 46 D5
            LD HL,000D                      ; $8E4C 21 0D 00
            ADD HL,DE                       ; $8E4F 19
            LD (HL),A                       ; $8E50 77
            CALL D18C                       ; $8E51 CD 8C D1
            CALL D3FD                       ; $8E54 CD FD D3
            JP D178                         ; $8E57 C3 78 D1
            XOR A                           ; $8E5A AF
            LD (D9D2),A                     ; $8E5B 32 D2 D9
            CALL D4A2                       ; $8E5E CD A2 D4
            CALL D1F5                       ; $8E61 CD F5 D1
            RET Z                           ; $8E64 C8
            LD HL,(CF43)                    ; $8E65 2A 43 CF
            LD BC,000C                      ; $8E68 01 0C 00
            ADD HL,BC                       ; $8E6B 09
            LD A,(HL)                       ; $8E6C 7E
            INC A                           ; $8E6D 3C
            AND 1F                          ; $8E6E E6 1F
            LD (HL),A                       ; $8E70 77
            JP Z,D583                       ; $8E71 CA 83 D5
            LD B,A                          ; $8E74 47
            LD A,(D9C5)                     ; $8E75 3A C5 D9
            AND B                           ; $8E78 A0
            LD HL,D9D2                      ; $8E79 21 D2 D9
            AND (HL)                        ; $8E7C A6
            JP Z,D58E                       ; $8E7D CA 8E D5
            JP D5AC                         ; $8E80 C3 AC D5
            LD BC,0002                      ; $8E83 01 02 00
            ADD HL,BC                       ; $8E86 09
            INC (HL)                        ; $8E87 34
            LD A,(HL)                       ; $8E88 7E
            AND 0F                          ; $8E89 E6 0F
            JP Z,D5B6                       ; $8E8B CA B6 D5
            LD C,0F                         ; $8E8E 0E 0F
            CALL D318                       ; $8E90 CD 18 D3
            CALL D1F5                       ; $8E93 CD F5 D1
            JP NZ,D5AC                      ; $8E96 C2 AC D5
            LD A,(D9D3)                     ; $8E99 3A D3 D9
            INC A                           ; $8E9C 3C
            JP Z,D5B6                       ; $8E9D CA B6 D5
            CALL D524                       ; $8EA0 CD 24 D5
            CALL D1F5                       ; $8EA3 CD F5 D1
            JP Z,D5B6                       ; $8EA6 CA B6 D5
            JP D5AF                         ; $8EA9 C3 AF D5
            CALL D45A                       ; $8EAC CD 5A D4
            CALL D0BB                       ; $8EAF CD BB D0
            XOR A                           ; $8EB2 AF
            JP CF01                         ; $8EB3 C3 01 CF
            CALL CF05                       ; $8EB6 CD 05 CF
            JP D178                         ; $8EB9 C3 78 D1
            LD A,01                         ; $8EBC 3E 01
            LD (D9D5),A                     ; $8EBE 32 D5 D9
            LD A,FF                         ; $8EC1 3E FF
            LD (D9D3),A                     ; $8EC3 32 D3 D9
            CALL D0BB                       ; $8EC6 CD BB D0
            LD A,(D9E3)                     ; $8EC9 3A E3 D9
            LD HL,D9E1                      ; $8ECC 21 E1 D9
            CP (HL)                         ; $8ECF BE
            JP C,D5E6                       ; $8ED0 DA E6 D5
            CP 80                           ; $8ED3 FE 80
            JP NZ,D5FB                      ; $8ED5 C2 FB D5
            CALL D55A                       ; $8ED8 CD 5A D5
            XOR A                           ; $8EDB AF
            LD (D9E3),A                     ; $8EDC 32 E3 D9
            LD A,(CF45)                     ; $8EDF 3A 45 CF
            OR A                            ; $8EE2 B7
            JP NZ,D5FB                      ; $8EE3 C2 FB D5
            CALL D077                       ; $8EE6 CD 77 D0
            CALL D084                       ; $8EE9 CD 84 D0
            JP Z,D5FB                       ; $8EEC CA FB D5
            CALL D08A                       ; $8EEF CD 8A D0
            CALL CFD1                       ; $8EF2 CD D1 CF
            CALL CFB2                       ; $8EF5 CD B2 CF
            JP D0D2                         ; $8EF8 C3 D2 D0
            JP CF05                         ; $8EFB C3 05 CF
            LD A,01                         ; $8EFE 3E 01
            POP BC                          ; $8F00 C1
            ADC A,FE                        ; $8F01 CE FE
            EX AF,AF'                       ; $8F03 08
            JP NZ,CE16                      ; $8F04 C2 16 CE
            LD A,B                          ; $8F07 78
            OR A                            ; $8F08 B7
            JP Z,CDEF                       ; $8F09 CA EF CD
            DEC B                           ; $8F0C 05
            LD A,(CF0C)                     ; $8F0D 3A 0C CF
            LD (CF0A),A                     ; $8F10 32 0A CF
            JP CE70                         ; $8F13 C3 70 CE
            CP 7F                           ; $8F16 FE 7F
            JP NZ,CE26                      ; $8F18 C2 26 CE
            LD A,B                          ; $8F1B 78
            OR A                            ; $8F1C B7
            JP Z,CDEF                       ; $8F1D CA EF CD
            LD A,(HL)                       ; $8F20 7E
            DEC B                           ; $8F21 05
            DEC HL                          ; $8F22 2B
            JP CEA9                         ; $8F23 C3 A9 CE
            CP 05                           ; $8F26 FE 05
            JP NZ,CE37                      ; $8F28 C2 37 CE
            PUSH BC                         ; $8F2B C5
            PUSH HL                         ; $8F2C E5
            CALL CDC9                       ; $8F2D CD C9 CD
            XOR A                           ; $8F30 AF
            LD (CF0B),A                     ; $8F31 32 0B CF
            JP CDF1                         ; $8F34 C3 F1 CD
            CP 10                           ; $8F37 FE 10
            JP NZ,CE48                      ; $8F39 C2 48 CE
            PUSH HL                         ; $8F3C E5
            LD HL,CF0D                      ; $8F3D 21 0D CF
            LD A,01                         ; $8F40 3E 01
            SUB (HL)                        ; $8F42 96
            LD (HL),A                       ; $8F43 77
            POP HL                          ; $8F44 E1
            JP CDEF                         ; $8F45 C3 EF CD
            CP 18                           ; $8F48 FE 18
            JP NZ,CE5F                      ; $8F4A C2 5F CE
            POP HL                          ; $8F4D E1
            LD A,(CF0B)                     ; $8F4E 3A 0B CF
            LD HL,CF0C                      ; $8F51 21 0C CF
            CP (HL)                         ; $8F54 BE
            JP NC,CDE1                      ; $8F55 D2 E1 CD
            DEC (HL)                        ; $8F58 35
            CALL CDA4                       ; $8F59 CD A4 CD
            JP CE4E                         ; $8F5C C3 4E CE
            CP 15                           ; $8F5F FE 15
            JP NZ,CE6B                      ; $8F61 C2 6B CE
            CALL CDB1                       ; $8F64 CD B1 CD
            POP HL                          ; $8F67 E1
            JP CDE1                         ; $8F68 C3 E1 CD
            CP 12                           ; $8F6B FE 12
            JP NZ,CEA6                      ; $8F6D C2 A6 CE
            PUSH BC                         ; $8F70 C5
            CALL CDB1                       ; $8F71 CD B1 CD
            POP BC                          ; $8F74 C1
            POP HL                          ; $8F75 E1
            PUSH HL                         ; $8F76 E5
            PUSH BC                         ; $8F77 C5
            LD A,B                          ; $8F78 78
            OR A                            ; $8F79 B7
            JP Z,CE8A                       ; $8F7A CA 8A CE
            INC HL                          ; $8F7D 23
            LD C,(HL)                       ; $8F7E 4E
            DEC B                           ; $8F7F 05
            PUSH BC                         ; $8F80 C5
            PUSH HL                         ; $8F81 E5
            CALL CD7F                       ; $8F82 CD 7F CD
            POP HL                          ; $8F85 E1
            POP BC                          ; $8F86 C1
            JP CE78                         ; $8F87 C3 78 CE
            PUSH HL                         ; $8F8A E5
            LD A,(CF0A)                     ; $8F8B 3A 0A CF
            OR A                            ; $8F8E B7
            JP Z,CDF1                       ; $8F8F CA F1 CD
            LD HL,CF0C                      ; $8F92 21 0C CF
            SUB (HL)                        ; $8F95 96
            LD (CF0A),A                     ; $8F96 32 0A CF
            CALL CDA4                       ; $8F99 CD A4 CD
            LD HL,CF0A                      ; $8F9C 21 0A CF
            DEC (HL)                        ; $8F9F 35
            JP NZ,CE99                      ; $8FA0 C2 99 CE
            JP CDF1                         ; $8FA3 C3 F1 CD
            INC HL                          ; $8FA6 23
            LD (HL),A                       ; $8FA7 77
            INC B                           ; $8FA8 04
            PUSH BC                         ; $8FA9 C5
            PUSH HL                         ; $8FAA E5
            LD C,A                          ; $8FAB 4F
            CALL CD7F                       ; $8FAC CD 7F CD
            POP HL                          ; $8FAF E1
            POP BC                          ; $8FB0 C1
            LD A,(HL)                       ; $8FB1 7E
            CP 03                           ; $8FB2 FE 03
            LD A,B                          ; $8FB4 78
            JP NZ,CEBD                      ; $8FB5 C2 BD CE
            CP 01                           ; $8FB8 FE 01
            JP Z,0000                       ; $8FBA CA 00 00
            CP C                            ; $8FBD B9
            JP C,CDEF                       ; $8FBE DA EF CD
            POP HL                          ; $8FC1 E1
            LD (HL),B                       ; $8FC2 70
            LD C,0D                         ; $8FC3 0E 0D
            JP CD48                         ; $8FC5 C3 48 CD
            CALL CD06                       ; $8FC8 CD 06 CD
            JP CF01                         ; $8FCB C3 01 CF
            CALL DA15                       ; $8FCE CD 15 DA
            JP CF01                         ; $8FD1 C3 01 CF
            LD A,C                          ; $8FD4 79
            INC A                           ; $8FD5 3C
            JP Z,CEE0                       ; $8FD6 CA E0 CE
            INC A                           ; $8FD9 3C
            JP Z,DA06                       ; $8FDA CA 06 DA
            JP DA0C                         ; $8FDD C3 0C DA
            CALL DA06                       ; $8FE0 CD 06 DA
            OR A                            ; $8FE3 B7
            JP Z,D991                       ; $8FE4 CA 91 D9
            CALL DA09                       ; $8FE7 CD 09 DA
            JP CF01                         ; $8FEA C3 01 CF
            LD A,(0003)                     ; $8FED 3A 03 00
            JP CF01                         ; $8FF0 C3 01 CF
            LD HL,0003                      ; $8FF3 21 03 00
            LD (HL),C                       ; $8FF6 71
            RET                             ; $8FF7 C9
            EX DE,HL                        ; $8FF8 EB
            LD C,L                          ; $8FF9 4D
            LD B,H                          ; $8FFA 44
            JP CDD3                         ; $8FFB C3 D3 CD
            CALL 3223                       ; $8FFE CD 23 32
            PUSH DE                         ; $9001 D5
            EXX                             ; $9002 D9
            LD A,00                         ; $9003 3E 00
            LD (D9D3),A                     ; $9005 32 D3 D9
            CALL D154                       ; $9008 CD 54 D1
            LD HL,(CF43)                    ; $900B 2A 43 CF
            CALL D147                       ; $900E CD 47 D1
            CALL D0BB                       ; $9011 CD BB D0
            LD A,(D9E3)                     ; $9014 3A E3 D9
            CP 80                           ; $9017 FE 80
            JP NC,CF05                      ; $9019 D2 05 CF
            CALL D077                       ; $901C CD 77 D0
            CALL D084                       ; $901F CD 84 D0
            LD C,00                         ; $9022 0E 00
            JP NZ,D66E                      ; $9024 C2 6E D6
            CALL D03E                       ; $9027 CD 3E D0
            LD (D9D7),A                     ; $902A 32 D7 D9
            LD BC,0000                      ; $902D 01 00 00
            OR A                            ; $9030 B7
            JP Z,D63B                       ; $9031 CA 3B D6
            LD C,A                          ; $9034 4F
            DEC BC                          ; $9035 0B
            CALL D05E                       ; $9036 CD 5E D0
            LD B,H                          ; $9039 44
            LD C,L                          ; $903A 4D
            CALL D3BE                       ; $903B CD BE D3
            LD A,L                          ; $903E 7D
            OR H                            ; $903F B4
            JP NZ,D648                      ; $9040 C2 48 D6
            LD A,02                         ; $9043 3E 02
            JP CF01                         ; $9045 C3 01 CF
            LD (D9E5),HL                    ; $9048 22 E5 D9
            EX DE,HL                        ; $904B EB
            LD HL,(CF43)                    ; $904C 2A 43 CF
            LD BC,0010                      ; $904F 01 10 00
            ADD HL,BC                       ; $9052 09
            LD A,(D9DD)                     ; $9053 3A DD D9
            OR A                            ; $9056 B7
            LD A,(D9D7)                     ; $9057 3A D7 D9
            JP Z,D664                       ; $905A CA 64 D6
            CALL D164                       ; $905D CD 64 D1
            LD (HL),E                       ; $9060 73
            JP D66C                         ; $9061 C3 6C D6
            LD C,A                          ; $9064 4F
            LD B,00                         ; $9065 06 00
            ADD HL,BC                       ; $9067 09
            ADD HL,BC                       ; $9068 09
            LD (HL),E                       ; $9069 73
            INC HL                          ; $906A 23
            LD (HL),D                       ; $906B 72
            LD C,02                         ; $906C 0E 02
            LD A,(CF45)                     ; $906E 3A 45 CF
            OR A                            ; $9071 B7
            RET NZ                          ; $9072 C0
            PUSH BC                         ; $9073 C5
            CALL D08A                       ; $9074 CD 8A D0
            LD A,(D9D5)                     ; $9077 3A D5 D9
            DEC A                           ; $907A 3D
            DEC A                           ; $907B 3D
            JP NZ,D6BB                      ; $907C C2 BB D6
            POP BC                          ; $907F C1
            PUSH BC                         ; $9080 C5
            LD A,C                          ; $9081 79
            DEC A                           ; $9082 3D
            DEC A                           ; $9083 3D
            JP NZ,D6BB                      ; $9084 C2 BB D6
            PUSH HL                         ; $9087 E5
            LD HL,(D9B9)                    ; $9088 2A B9 D9
            LD D,A                          ; $908B 57
            LD (HL),A                       ; $908C 77
            INC HL                          ; $908D 23
            INC D                           ; $908E 14
            JP P,D68C                       ; $908F F2 8C D6
            CALL D1E0                       ; $9092 CD E0 D1
            LD HL,(D9E7)                    ; $9095 2A E7 D9
            LD C,02                         ; $9098 0E 02
            LD (D9E5),HL                    ; $909A 22 E5 D9
            PUSH BC                         ; $909D C5
            CALL CFD1                       ; $909E CD D1 CF
            POP BC                          ; $90A1 C1
            CALL CFB8                       ; $90A2 CD B8 CF
            LD HL,(D9E5)                    ; $90A5 2A E5 D9
            LD C,00                         ; $90A8 0E 00
            LD A,(D9C4)                     ; $90AA 3A C4 D9
            LD B,A                          ; $90AD 47
            AND L                           ; $90AE A5
            CP B                            ; $90AF B8
            INC HL                          ; $90B0 23
            JP NZ,D69A                      ; $90B1 C2 9A D6
            POP HL                          ; $90B4 E1
            LD (D9E5),HL                    ; $90B5 22 E5 D9
            CALL D1DA                       ; $90B8 CD DA D1
            CALL CFD1                       ; $90BB CD D1 CF
            POP BC                          ; $90BE C1
            PUSH BC                         ; $90BF C5
            CALL CFB8                       ; $90C0 CD B8 CF
            POP BC                          ; $90C3 C1
            LD A,(D9E3)                     ; $90C4 3A E3 D9
            LD HL,D9E1                      ; $90C7 21 E1 D9
            CP (HL)                         ; $90CA BE
            JP C,D6D2                       ; $90CB DA D2 D6
            LD (HL),A                       ; $90CE 77
            INC (HL)                        ; $90CF 34
            LD C,02                         ; $90D0 0E 02
            NOP                             ; $90D2 00
            NOP                             ; $90D3 00
            LD HL,D6DF                      ; $90D4 21 DF D6
            PUSH AF                         ; $90D7 F5
            CALL D169                       ; $90D8 CD 69 D1
            AND 7F                          ; $90DB E6 7F
            LD (HL),A                       ; $90DD 77
            POP AF                          ; $90DE F1
            CP 7F                           ; $90DF FE 7F
            JP NZ,D700                      ; $90E1 C2 00 D7
            LD A,(D9D5)                     ; $90E4 3A D5 D9
            CP 01                           ; $90E7 FE 01
            JP NZ,D700                      ; $90E9 C2 00 D7
            CALL D0D2                       ; $90EC CD D2 D0
            CALL D55A                       ; $90EF CD 5A D5
            LD HL,CF45                      ; $90F2 21 45 CF
            LD A,(HL)                       ; $90F5 7E
            OR A                            ; $90F6 B7
            JP NZ,D6FE                      ; $90F7 C2 FE D6
            DEC A                           ; $90FA 3D
            LD (D9E3),A                     ; $90FB 32 E3 D9
            LD (HL),00                      ; $90FE 36 00
            CALL 4532                       ; $9100 CD 32 45
            RST $08                         ; $9103 CF
            RET                             ; $9104 C9
            LD A,01                         ; $9105 3E 01
            JP CF01                         ; $9107 C3 01 CF
            NOP                             ; $910A 00
            NOP                             ; $910B 00
            NOP                             ; $910C 00
            NOP                             ; $910D 00
            NOP                             ; $910E 00
            NOP                             ; $910F 00
            NOP                             ; $9110 00
            NOP                             ; $9111 00
            NOP                             ; $9112 00
            NOP                             ; $9113 00
            NOP                             ; $9114 00
            NOP                             ; $9115 00
            NOP                             ; $9116 00
            NOP                             ; $9117 00
            NOP                             ; $9118 00
            NOP                             ; $9119 00
            NOP                             ; $911A 00
            NOP                             ; $911B 00
            NOP                             ; $911C 00
            NOP                             ; $911D 00
            NOP                             ; $911E 00
            NOP                             ; $911F 00
            NOP                             ; $9120 00
            NOP                             ; $9121 00
            NOP                             ; $9122 00
            NOP                             ; $9123 00
            NOP                             ; $9124 00
            NOP                             ; $9125 00
            NOP                             ; $9126 00
            NOP                             ; $9127 00
            NOP                             ; $9128 00
            NOP                             ; $9129 00
            NOP                             ; $912A 00
            NOP                             ; $912B 00
            NOP                             ; $912C 00
            NOP                             ; $912D 00
            NOP                             ; $912E 00
            NOP                             ; $912F 00
            NOP                             ; $9130 00
            NOP                             ; $9131 00
            NOP                             ; $9132 00
            NOP                             ; $9133 00
            NOP                             ; $9134 00
            NOP                             ; $9135 00
            NOP                             ; $9136 00
            NOP                             ; $9137 00
            NOP                             ; $9138 00
            NOP                             ; $9139 00
            NOP                             ; $913A 00
            NOP                             ; $913B 00
            NOP                             ; $913C 00
            NOP                             ; $913D 00
            NOP                             ; $913E 00
            NOP                             ; $913F 00
            NOP                             ; $9140 00
            NOP                             ; $9141 00
            NOP                             ; $9142 00
            NOP                             ; $9143 00
            NOP                             ; $9144 00
            NOP                             ; $9145 00
            NOP                             ; $9146 00
            LD HL,CC0B                      ; $9147 21 0B CC
            LD E,(HL)                       ; $914A 5E
            INC HL                          ; $914B 23
            LD D,(HL)                       ; $914C 56
            EX DE,HL                        ; $914D EB
            JP (HL)                         ; $914E E9
            INC C                           ; $914F 0C
            DEC C                           ; $9150 0D
            RET Z                           ; $9151 C8
            LD A,(DE)                       ; $9152 1A
            LD (HL),A                       ; $9153 77
            INC DE                          ; $9154 13
            INC HL                          ; $9155 23
            JP CF50                         ; $9156 C3 50 CF
            LD A,(CF42)                     ; $9159 3A 42 CF
            LD C,A                          ; $915C 4F
            CALL DA1B                       ; $915D CD 1B DA
            LD A,H                          ; $9160 7C
            OR L                            ; $9161 B5
            RET Z                           ; $9162 C8
            LD E,(HL)                       ; $9163 5E
            INC HL                          ; $9164 23
            LD D,(HL)                       ; $9165 56
            INC HL                          ; $9166 23
            LD (D9B3),HL                    ; $9167 22 B3 D9
            INC HL                          ; $916A 23
            INC HL                          ; $916B 23
            LD (D9B5),HL                    ; $916C 22 B5 D9
            INC HL                          ; $916F 23
            INC HL                          ; $9170 23
            LD (D9B7),HL                    ; $9171 22 B7 D9
            INC HL                          ; $9174 23
            INC HL                          ; $9175 23
            EX DE,HL                        ; $9176 EB
            LD (D9D0),HL                    ; $9177 22 D0 D9
            LD HL,D9B9                      ; $917A 21 B9 D9
            LD C,08                         ; $917D 0E 08
            CALL CF4F                       ; $917F CD 4F CF
            LD HL,(D9BB)                    ; $9182 2A BB D9
            EX DE,HL                        ; $9185 EB
            LD HL,D9C1                      ; $9186 21 C1 D9
            LD C,0F                         ; $9189 0E 0F
            CALL CF4F                       ; $918B CD 4F CF
            LD HL,(D9C6)                    ; $918E 2A C6 D9
            LD A,H                          ; $9191 7C
            LD HL,D9DD                      ; $9192 21 DD D9
            LD (HL),FF                      ; $9195 36 FF
            OR A                            ; $9197 B7
            JP Z,CF9D                       ; $9198 CA 9D CF
            LD (HL),00                      ; $919B 36 00
            LD A,FF                         ; $919D 3E FF
            OR A                            ; $919F B7
            RET                             ; $91A0 C9
            CALL DA18                       ; $91A1 CD 18 DA
            XOR A                           ; $91A4 AF
            LD HL,(D9B5)                    ; $91A5 2A B5 D9
            LD (HL),A                       ; $91A8 77
            INC HL                          ; $91A9 23
            LD (HL),A                       ; $91AA 77
            LD HL,(D9B7)                    ; $91AB 2A B7 D9
            LD (HL),A                       ; $91AE 77
            INC HL                          ; $91AF 23
            LD (HL),A                       ; $91B0 77
            RET                             ; $91B1 C9
            CALL DA27                       ; $91B2 CD 27 DA
            JP CFBB                         ; $91B5 C3 BB CF
            CALL DA2A                       ; $91B8 CD 2A DA
            OR A                            ; $91BB B7
            RET Z                           ; $91BC C8
            LD HL,CC09                      ; $91BD 21 09 CC
            JP CF4A                         ; $91C0 C3 4A CF
            LD HL,(D9EA)                    ; $91C3 2A EA D9
            LD C,02                         ; $91C6 0E 02
            CALL D0EA                       ; $91C8 CD EA D0
            LD (D9E5),HL                    ; $91CB 22 E5 D9
            LD (D9EC),HL                    ; $91CE 22 EC D9
            LD HL,D9E5                      ; $91D1 21 E5 D9
            LD C,(HL)                       ; $91D4 4E
            INC HL                          ; $91D5 23
            LD B,(HL)                       ; $91D6 46
            LD HL,(D9B7)                    ; $91D7 2A B7 D9
            LD E,(HL)                       ; $91DA 5E
            INC HL                          ; $91DB 23
            LD D,(HL)                       ; $91DC 56
            LD HL,(D9B5)                    ; $91DD 2A B5 D9
            LD A,(HL)                       ; $91E0 7E
            INC HL                          ; $91E1 23
            LD H,(HL)                       ; $91E2 66
            LD L,A                          ; $91E3 6F
            LD A,C                          ; $91E4 79
            SUB E                           ; $91E5 93
            LD A,B                          ; $91E6 78
            SBC A,D                         ; $91E7 9A
            JP NC,CFFA                      ; $91E8 D2 FA CF
            PUSH HL                         ; $91EB E5
            LD HL,(D9C1)                    ; $91EC 2A C1 D9
            LD A,E                          ; $91EF 7B
            SUB L                           ; $91F0 95
            LD E,A                          ; $91F1 5F
            LD A,D                          ; $91F2 7A
            SBC A,H                         ; $91F3 9C
            LD D,A                          ; $91F4 57
            POP HL                          ; $91F5 E1
            DEC HL                          ; $91F6 2B
            JP CFE4                         ; $91F7 C3 E4 CF
            PUSH HL                         ; $91FA E5
            LD HL,(D9C1)                    ; $91FB 2A C1 D9
            ADD HL,DE                       ; $91FE 19
            JP C,D2C3                       ; $91FF DA C3 D2
            RET NC                          ; $9202 D0
            XOR A                           ; $9203 AF
            LD (D9D5),A                     ; $9204 32 D5 D9
            PUSH BC                         ; $9207 C5
            LD HL,(CF43)                    ; $9208 2A 43 CF
            EX DE,HL                        ; $920B EB
            LD HL,0021                      ; $920C 21 21 00
            ADD HL,DE                       ; $920F 19
            LD A,(HL)                       ; $9210 7E
            AND 7F                          ; $9211 E6 7F
            PUSH AF                         ; $9213 F5
            LD A,(HL)                       ; $9214 7E
            RLA                             ; $9215 17
            INC HL                          ; $9216 23
            LD A,(HL)                       ; $9217 7E
            RLA                             ; $9218 17
            AND 1F                          ; $9219 E6 1F
            LD C,A                          ; $921B 4F
            LD A,(HL)                       ; $921C 7E
            RRA                             ; $921D 1F
            RRA                             ; $921E 1F
            RRA                             ; $921F 1F
            RRA                             ; $9220 1F
            AND 0F                          ; $9221 E6 0F
            LD B,A                          ; $9223 47
            POP AF                          ; $9224 F1
            INC HL                          ; $9225 23
            LD L,(HL)                       ; $9226 6E
            INC L                           ; $9227 2C
            DEC L                           ; $9228 2D
            LD L,06                         ; $9229 2E 06
            JP NZ,D78B                      ; $922B C2 8B D7
            LD HL,0020                      ; $922E 21 20 00
            ADD HL,DE                       ; $9231 19
            LD (HL),A                       ; $9232 77
            LD HL,000C                      ; $9233 21 0C 00
            ADD HL,DE                       ; $9236 19
            LD A,C                          ; $9237 79
            SUB (HL)                        ; $9238 96
            JP NZ,D747                      ; $9239 C2 47 D7
            LD HL,000E                      ; $923C 21 0E 00
            ADD HL,DE                       ; $923F 19
            LD A,B                          ; $9240 78
            SUB (HL)                        ; $9241 96
            AND 7F                          ; $9242 E6 7F
            JP Z,D77F                       ; $9244 CA 7F D7
            PUSH BC                         ; $9247 C5
            PUSH DE                         ; $9248 D5
            CALL D4A2                       ; $9249 CD A2 D4
            POP DE                          ; $924C D1
            POP BC                          ; $924D C1
            LD L,03                         ; $924E 2E 03
            LD A,(CF45)                     ; $9250 3A 45 CF
            INC A                           ; $9253 3C
            JP Z,D784                       ; $9254 CA 84 D7
            LD HL,000C                      ; $9257 21 0C 00
            ADD HL,DE                       ; $925A 19
            LD (HL),C                       ; $925B 71
            LD HL,000E                      ; $925C 21 0E 00
            ADD HL,DE                       ; $925F 19
            LD (HL),B                       ; $9260 70
            CALL D451                       ; $9261 CD 51 D4
            LD A,(CF45)                     ; $9264 3A 45 CF
            INC A                           ; $9267 3C
            JP NZ,D77F                      ; $9268 C2 7F D7
            POP BC                          ; $926B C1
            PUSH BC                         ; $926C C5
            LD L,04                         ; $926D 2E 04
            INC C                           ; $926F 0C
            JP Z,D784                       ; $9270 CA 84 D7
            CALL D524                       ; $9273 CD 24 D5
            LD L,05                         ; $9276 2E 05
            LD A,(CF45)                     ; $9278 3A 45 CF
            INC A                           ; $927B 3C
            JP Z,D784                       ; $927C CA 84 D7
            POP BC                          ; $927F C1
            XOR A                           ; $9280 AF
            JP CF01                         ; $9281 C3 01 CF
            PUSH HL                         ; $9284 E5
            CALL D169                       ; $9285 CD 69 D1
            LD (HL),C0                      ; $9288 36 C0
            POP HL                          ; $928A E1
            POP BC                          ; $928B C1
            LD A,L                          ; $928C 7D
            LD (CF45),A                     ; $928D 32 45 CF
            JP D178                         ; $9290 C3 78 D1
            LD C,FF                         ; $9293 0E FF
            CALL D703                       ; $9295 CD 03 D7
            CALL Z,D5C1                     ; $9298 CC C1 D5
            RET                             ; $929B C9
            LD C,00                         ; $929C 0E 00
            CALL D703                       ; $929E CD 03 D7
            CALL Z,D603                     ; $92A1 CC 03 D6
            RET                             ; $92A4 C9
            EX DE,HL                        ; $92A5 EB
            ADD HL,DE                       ; $92A6 19
            LD C,(HL)                       ; $92A7 4E
            LD B,00                         ; $92A8 06 00
            LD HL,000C                      ; $92AA 21 0C 00
            ADD HL,DE                       ; $92AD 19
            LD A,(HL)                       ; $92AE 7E
            RRCA                            ; $92AF 0F
            AND 80                          ; $92B0 E6 80
            ADD A,C                         ; $92B2 81
            LD C,A                          ; $92B3 4F
            LD A,00                         ; $92B4 3E 00
            ADC A,B                         ; $92B6 88
            LD B,A                          ; $92B7 47
            LD A,(HL)                       ; $92B8 7E
            RRCA                            ; $92B9 0F
            AND 0F                          ; $92BA E6 0F
            ADD A,B                         ; $92BC 80
            LD B,A                          ; $92BD 47
            LD HL,000E                      ; $92BE 21 0E 00
            ADD HL,DE                       ; $92C1 19
            LD A,(HL)                       ; $92C2 7E
            ADD A,A                         ; $92C3 87
            ADD A,A                         ; $92C4 87
            ADD A,A                         ; $92C5 87
            ADD A,A                         ; $92C6 87
            PUSH AF                         ; $92C7 F5
            ADD A,B                         ; $92C8 80
            LD B,A                          ; $92C9 47
            PUSH AF                         ; $92CA F5
            POP HL                          ; $92CB E1
            LD A,L                          ; $92CC 7D
            POP HL                          ; $92CD E1
            OR L                            ; $92CE B5
            AND 01                          ; $92CF E6 01
            RET                             ; $92D1 C9
            LD C,0C                         ; $92D2 0E 0C
            CALL D318                       ; $92D4 CD 18 D3
            LD HL,(CF43)                    ; $92D7 2A 43 CF
            LD DE,0021                      ; $92DA 11 21 00
            ADD HL,DE                       ; $92DD 19
            PUSH HL                         ; $92DE E5
            LD (HL),D                       ; $92DF 72
            INC HL                          ; $92E0 23
            LD (HL),D                       ; $92E1 72
            INC HL                          ; $92E2 23
            LD (HL),D                       ; $92E3 72
            CALL D1F5                       ; $92E4 CD F5 D1
            JP Z,D80C                       ; $92E7 CA 0C D8
            CALL D15E                       ; $92EA CD 5E D1
            LD DE,000F                      ; $92ED 11 0F 00
            CALL D7A5                       ; $92F0 CD A5 D7
            POP HL                          ; $92F3 E1
            PUSH HL                         ; $92F4 E5
            LD E,A                          ; $92F5 5F
            LD A,C                          ; $92F6 79
            SUB (HL)                        ; $92F7 96
            INC HL                          ; $92F8 23
            LD A,B                          ; $92F9 78
            SBC A,(HL)                      ; $92FA 9E
            INC HL                          ; $92FB 23
            LD A,E                          ; $92FC 7B
            SBC A,(HL)                      ; $92FD 9E
            JP C,0F06                       ; $92FE DA 06 0F
            RET NC                          ; $9301 D0
            LD A,C                          ; $9302 79
            SUB L                           ; $9303 95
            LD A,B                          ; $9304 78
            SBC A,H                         ; $9305 9C
            JP C,D00F                       ; $9306 DA 0F D0
            EX DE,HL                        ; $9309 EB
            POP HL                          ; $930A E1
            INC HL                          ; $930B 23
            JP CFFA                         ; $930C C3 FA CF
            POP HL                          ; $930F E1
            PUSH BC                         ; $9310 C5
            PUSH DE                         ; $9311 D5
            PUSH HL                         ; $9312 E5
            EX DE,HL                        ; $9313 EB
            LD HL,(D9CE)                    ; $9314 2A CE D9
            ADD HL,DE                       ; $9317 19
            LD B,H                          ; $9318 44
            LD C,L                          ; $9319 4D
            CALL DA1E                       ; $931A CD 1E DA
            POP DE                          ; $931D D1
            LD HL,(D9B5)                    ; $931E 2A B5 D9
            LD (HL),E                       ; $9321 73
            INC HL                          ; $9322 23
            LD (HL),D                       ; $9323 72
            POP DE                          ; $9324 D1
            LD HL,(D9B7)                    ; $9325 2A B7 D9
            LD (HL),E                       ; $9328 73
            INC HL                          ; $9329 23
            LD (HL),D                       ; $932A 72
            POP BC                          ; $932B C1
            LD A,C                          ; $932C 79
            SUB E                           ; $932D 93
            LD C,A                          ; $932E 4F
            LD A,B                          ; $932F 78
            SBC A,D                         ; $9330 9A
            LD B,A                          ; $9331 47
            LD HL,(D9D0)                    ; $9332 2A D0 D9
            EX DE,HL                        ; $9335 EB
            CALL DA30                       ; $9336 CD 30 DA
            LD C,L                          ; $9339 4D
            LD B,H                          ; $933A 44
            JP DA21                         ; $933B C3 21 DA
            LD HL,D9C3                      ; $933E 21 C3 D9
            LD C,(HL)                       ; $9341 4E
            LD A,(D9E3)                     ; $9342 3A E3 D9
            OR A                            ; $9345 B7
            RRA                             ; $9346 1F
            DEC C                           ; $9347 0D
            JP NZ,D045                      ; $9348 C2 45 D0
            LD B,A                          ; $934B 47
            LD A,08                         ; $934C 3E 08
            SUB (HL)                        ; $934E 96
            LD C,A                          ; $934F 4F
            LD A,(D9E2)                     ; $9350 3A E2 D9
            DEC C                           ; $9353 0D
            JP Z,D05C                       ; $9354 CA 5C D0
            OR A                            ; $9357 B7
            RLA                             ; $9358 17
            JP D053                         ; $9359 C3 53 D0
            ADD A,B                         ; $935C 80
            RET                             ; $935D C9
            LD HL,(CF43)                    ; $935E 2A 43 CF
            LD DE,0010                      ; $9361 11 10 00
            ADD HL,DE                       ; $9364 19
            ADD HL,BC                       ; $9365 09
            LD A,(D9DD)                     ; $9366 3A DD D9
            OR A                            ; $9369 B7
            JP Z,D071                       ; $936A CA 71 D0
            LD L,(HL)                       ; $936D 6E
            LD H,00                         ; $936E 26 00
            RET                             ; $9370 C9
            ADD HL,BC                       ; $9371 09
            LD E,(HL)                       ; $9372 5E
            INC HL                          ; $9373 23
            LD D,(HL)                       ; $9374 56
            EX DE,HL                        ; $9375 EB
            RET                             ; $9376 C9
            CALL D03E                       ; $9377 CD 3E D0
            LD C,A                          ; $937A 4F
            LD B,00                         ; $937B 06 00
            CALL D05E                       ; $937D CD 5E D0
            LD (D9E5),HL                    ; $9380 22 E5 D9
            RET                             ; $9383 C9
            LD HL,(D9E5)                    ; $9384 2A E5 D9
            LD A,L                          ; $9387 7D
            OR H                            ; $9388 B4
            RET                             ; $9389 C9
            LD A,(D9C3)                     ; $938A 3A C3 D9
            LD HL,(D9E5)                    ; $938D 2A E5 D9
            ADD HL,HL                       ; $9390 29
            DEC A                           ; $9391 3D
            JP NZ,D090                      ; $9392 C2 90 D0
            LD (D9E7),HL                    ; $9395 22 E7 D9
            LD A,(D9C4)                     ; $9398 3A C4 D9
            LD C,A                          ; $939B 4F
            LD A,(D9E3)                     ; $939C 3A E3 D9
            AND C                           ; $939F A1
            OR L                            ; $93A0 B5
            LD L,A                          ; $93A1 6F
            LD (D9E5),HL                    ; $93A2 22 E5 D9
            RET                             ; $93A5 C9
            LD HL,(CF43)                    ; $93A6 2A 43 CF
            LD DE,000C                      ; $93A9 11 0C 00
            ADD HL,DE                       ; $93AC 19
            RET                             ; $93AD C9
            LD HL,(CF43)                    ; $93AE 2A 43 CF
            LD DE,000F                      ; $93B1 11 0F 00
            ADD HL,DE                       ; $93B4 19
            EX DE,HL                        ; $93B5 EB
            LD HL,0011                      ; $93B6 21 11 00
            ADD HL,DE                       ; $93B9 19
            RET                             ; $93BA C9
            CALL D0AE                       ; $93BB CD AE D0
            LD A,(HL)                       ; $93BE 7E
            LD (D9E3),A                     ; $93BF 32 E3 D9
            EX DE,HL                        ; $93C2 EB
            LD A,(HL)                       ; $93C3 7E
            LD (D9E1),A                     ; $93C4 32 E1 D9
            CALL D0A6                       ; $93C7 CD A6 D0
            LD A,(D9C5)                     ; $93CA 3A C5 D9
            AND (HL)                        ; $93CD A6
            LD (D9E2),A                     ; $93CE 32 E2 D9
            RET                             ; $93D1 C9
            CALL D0AE                       ; $93D2 CD AE D0
            LD A,(D9D5)                     ; $93D5 3A D5 D9
            CP 02                           ; $93D8 FE 02
            JP NZ,D0DE                      ; $93DA C2 DE D0
            XOR A                           ; $93DD AF
            LD C,A                          ; $93DE 4F
            LD A,(D9E3)                     ; $93DF 3A E3 D9
            ADD A,C                         ; $93E2 81
            LD (HL),A                       ; $93E3 77
            EX DE,HL                        ; $93E4 EB
            LD A,(D9E1)                     ; $93E5 3A E1 D9
            LD (HL),A                       ; $93E8 77
            RET                             ; $93E9 C9
            INC C                           ; $93EA 0C
            DEC C                           ; $93EB 0D
            RET Z                           ; $93EC C8
            LD A,H                          ; $93ED 7C
            OR A                            ; $93EE B7
            RRA                             ; $93EF 1F
            LD H,A                          ; $93F0 67
            LD A,L                          ; $93F1 7D
            RRA                             ; $93F2 1F
            LD L,A                          ; $93F3 6F
            JP D0EB                         ; $93F4 C3 EB D0
            LD C,80                         ; $93F7 0E 80
            LD HL,(D9B9)                    ; $93F9 2A B9 D9
            XOR A                           ; $93FC AF
            ADD A,(HL)                      ; $93FD 86
            INC HL                          ; $93FE 23
            DEC C                           ; $93FF 0D
            RET C                           ; $9400 D8
            LD (HL),E                       ; $9401 73
            DEC HL                          ; $9402 2B
            LD (HL),B                       ; $9403 70
            DEC HL                          ; $9404 2B
            LD (HL),C                       ; $9405 71
            CALL D32D                       ; $9406 CD 2D D3
            JP D7E4                         ; $9409 C3 E4 D7
            POP HL                          ; $940C E1
            RET                             ; $940D C9
            LD HL,(CF43)                    ; $940E 2A 43 CF
            LD DE,0020                      ; $9411 11 20 00
            CALL D7A5                       ; $9414 CD A5 D7
            LD HL,0021                      ; $9417 21 21 00
            ADD HL,DE                       ; $941A 19
            LD (HL),C                       ; $941B 71
            INC HL                          ; $941C 23
            LD (HL),B                       ; $941D 70
            INC HL                          ; $941E 23
            LD (HL),A                       ; $941F 77
            RET                             ; $9420 C9
            LD HL,(D9AF)                    ; $9421 2A AF D9
            LD A,(CF42)                     ; $9424 3A 42 CF
            LD C,A                          ; $9427 4F
            CALL D0EA                       ; $9428 CD EA D0
            PUSH HL                         ; $942B E5
            EX DE,HL                        ; $942C EB
            CALL CF59                       ; $942D CD 59 CF
            POP HL                          ; $9430 E1
            CALL Z,CF47                     ; $9431 CC 47 CF
            LD A,L                          ; $9434 7D
            RRA                             ; $9435 1F
            RET C                           ; $9436 D8
            LD HL,(D9AF)                    ; $9437 2A AF D9
            LD C,L                          ; $943A 4D
            LD B,H                          ; $943B 44
            CALL D10B                       ; $943C CD 0B D1
            LD (D9AF),HL                    ; $943F 22 AF D9
            JP D2A3                         ; $9442 C3 A3 D2
            LD A,(D9D6)                     ; $9445 3A D6 D9
            LD HL,CF42                      ; $9448 21 42 CF
            CP (HL)                         ; $944B BE
            RET Z                           ; $944C C8
            LD (HL),A                       ; $944D 77
            JP D821                         ; $944E C3 21 D8
            LD A,FF                         ; $9451 3E FF
            LD (D9DE),A                     ; $9453 32 DE D9
            LD HL,(CF43)                    ; $9456 2A 43 CF
            LD A,(HL)                       ; $9459 7E
            AND 1F                          ; $945A E6 1F
            DEC A                           ; $945C 3D
            LD (D9D6),A                     ; $945D 32 D6 D9
            CP 1E                           ; $9460 FE 1E
            JP NC,D875                      ; $9462 D2 75 D8
            LD A,(CF42)                     ; $9465 3A 42 CF
            LD (D9DF),A                     ; $9468 32 DF D9
            LD A,(HL)                       ; $946B 7E
            LD (D9E0),A                     ; $946C 32 E0 D9
            AND E0                          ; $946F E6 E0
            LD (HL),A                       ; $9471 77
            CALL D845                       ; $9472 CD 45 D8
            LD A,(CF41)                     ; $9475 3A 41 CF
            LD HL,(CF43)                    ; $9478 2A 43 CF
            OR (HL)                         ; $947B B6
            LD (HL),A                       ; $947C 77
            RET                             ; $947D C9
            LD A,22                         ; $947E 3E 22
            JP CF01                         ; $9480 C3 01 CF
            LD HL,0000                      ; $9483 21 00 00
            LD (D9AD),HL                    ; $9486 22 AD D9
            LD (D9AF),HL                    ; $9489 22 AF D9
            XOR A                           ; $948C AF
            LD (CF42),A                     ; $948D 32 42 CF
            LD HL,0080                      ; $9490 21 80 00
            LD (D9B1),HL                    ; $9493 22 B1 D9
            CALL D1DA                       ; $9496 CD DA D1
            JP D821                         ; $9499 C3 21 D8
            CALL D172                       ; $949C CD 72 D1
            CALL D851                       ; $949F CD 51 D8
            JP D451                         ; $94A2 C3 51 D4
            CALL D851                       ; $94A5 CD 51 D8
            JP D4A2                         ; $94A8 C3 A2 D4
            LD C,00                         ; $94AB 0E 00
            EX DE,HL                        ; $94AD EB
            LD A,(HL)                       ; $94AE 7E
            CP 3F                           ; $94AF FE 3F
            JP Z,D8C2                       ; $94B1 CA C2 D8
            CALL D0A6                       ; $94B4 CD A6 D0
            LD A,(HL)                       ; $94B7 7E
            CP 3F                           ; $94B8 FE 3F
            CALL NZ,D172                    ; $94BA C4 72 D1
            CALL D851                       ; $94BD CD 51 D8
            LD C,0F                         ; $94C0 0E 0F
            CALL D318                       ; $94C2 CD 18 D3
            JP D1E9                         ; $94C5 C3 E9 D1
            LD HL,(D9D9)                    ; $94C8 2A D9 D9
            LD (CF43),HL                    ; $94CB 22 43 CF
            CALL D851                       ; $94CE CD 51 D8
            CALL D32D                       ; $94D1 CD 2D D3
            JP D1E9                         ; $94D4 C3 E9 D1
            CALL D851                       ; $94D7 CD 51 D8
            CALL D39C                       ; $94DA CD 9C D3
            JP D301                         ; $94DD C3 01 D3
            CALL D851                       ; $94E0 CD 51 D8
            JP D5BC                         ; $94E3 C3 BC D5
            CALL D851                       ; $94E6 CD 51 D8
            JP D5FE                         ; $94E9 C3 FE D5
            CALL D172                       ; $94EC CD 72 D1
            CALL D851                       ; $94EF CD 51 D8
            JP D524                         ; $94F2 C3 24 D5
            CALL D851                       ; $94F5 CD 51 D8
            CALL D416                       ; $94F8 CD 16 D4
            JP D301                         ; $94FB C3 01 D3
            LD HL,(D9AF)                    ; $94FE 2A AF D9
            JP D929                         ; $9501 C3 29 D9
            LD A,(CF42)                     ; $9504 3A 42 CF
            JP CF01                         ; $9507 C3 01 CF
            EX DE,HL                        ; $950A EB
            LD (D9B1),HL                    ; $950B 22 B1 D9
            JP D1DA                         ; $950E C3 DA D1
            LD HL,(D9BF)                    ; $9511 2A BF D9
            JP D929                         ; $9514 C3 29 D9
            LD HL,(D9AD)                    ; $9517 2A AD D9
            JP D929                         ; $951A C3 29 D9
            CALL D851                       ; $951D CD 51 D8
            CALL D43B                       ; $9520 CD 3B D4
            JP D301                         ; $9523 C3 01 D3
            LD HL,(D9BB)                    ; $9526 2A BB D9
            LD (CF45),HL                    ; $9529 22 45 CF
            RET                             ; $952C C9
            LD A,(D9D6)                     ; $952D 3A D6 D9
            CP FF                           ; $9530 FE FF
            JP NZ,D93B                      ; $9532 C2 3B D9
            LD A,(CF41)                     ; $9535 3A 41 CF
            JP CF01                         ; $9538 C3 01 CF
            AND 1F                          ; $953B E6 1F
            LD (CF41),A                     ; $953D 32 41 CF
            RET                             ; $9540 C9
            CALL D851                       ; $9541 CD 51 D8
            JP D793                         ; $9544 C3 93 D7
            CALL D851                       ; $9547 CD 51 D8
            JP D79C                         ; $954A C3 9C D7
            CALL D851                       ; $954D CD 51 D8
            JP D7D2                         ; $9550 C3 D2 D7
            LD HL,(CF43)                    ; $9553 2A 43 CF
            LD A,L                          ; $9556 7D
            CPL                             ; $9557 2F
            LD E,A                          ; $9558 5F
            LD A,H                          ; $9559 7C
            CPL                             ; $955A 2F
            LD HL,(D9AF)                    ; $955B 2A AF D9
            AND H                           ; $955E A4
            LD D,A                          ; $955F 57
            LD A,L                          ; $9560 7D
            AND E                           ; $9561 A3
            LD E,A                          ; $9562 5F
            LD HL,(D9AD)                    ; $9563 2A AD D9
            EX DE,HL                        ; $9566 EB
            LD (D9AF),HL                    ; $9567 22 AF D9
            LD A,L                          ; $956A 7D
            AND E                           ; $956B A3
            LD L,A                          ; $956C 6F
            LD A,H                          ; $956D 7C
            AND D                           ; $956E A2
            LD H,A                          ; $956F 67
            LD (D9AD),HL                    ; $9570 22 AD D9
            RET                             ; $9573 C9
            LD A,(D9DE)                     ; $9574 3A DE D9
            OR A                            ; $9577 B7
            JP Z,D991                       ; $9578 CA 91 D9
            LD HL,(CF43)                    ; $957B 2A 43 CF
            LD (HL),00                      ; $957E 36 00
            LD A,(D9E0)                     ; $9580 3A E0 D9
            OR A                            ; $9583 B7
            JP Z,D991                       ; $9584 CA 91 D9
            LD (HL),A                       ; $9587 77
            LD A,(D9DF)                     ; $9588 3A DF D9
            LD (D9D6),A                     ; $958B 32 D6 D9
            CALL D845                       ; $958E CD 45 D8
            LD HL,(CF0F)                    ; $9591 2A 0F CF
            LD SP,HL                        ; $9594 F9
            LD HL,(CF45)                    ; $9595 2A 45 CF
            LD A,L                          ; $9598 7D
            LD B,H                          ; $9599 44
            RET                             ; $959A C9
            CALL D851                       ; $959B CD 51 D8
            LD A,02                         ; $959E 3E 02
            LD (D9D5),A                     ; $95A0 32 D5 D9
            LD C,00                         ; $95A3 0E 00
            CALL D707                       ; $95A5 CD 07 D7
            CALL Z,D603                     ; $95A8 CC 03 D6
            RET                             ; $95AB C9
            PUSH HL                         ; $95AC E5
            NOP                             ; $95AD 00
            NOP                             ; $95AE 00
            NOP                             ; $95AF 00
            NOP                             ; $95B0 00
            ADD A,B                         ; $95B1 80
            NOP                             ; $95B2 00
            NOP                             ; $95B3 00
            NOP                             ; $95B4 00
            NOP                             ; $95B5 00
            NOP                             ; $95B6 00
            NOP                             ; $95B7 00
            NOP                             ; $95B8 00
            NOP                             ; $95B9 00
            NOP                             ; $95BA 00
            NOP                             ; $95BB 00
            NOP                             ; $95BC 00
            NOP                             ; $95BD 00
            NOP                             ; $95BE 00
            NOP                             ; $95BF 00
            NOP                             ; $95C0 00
            NOP                             ; $95C1 00
            NOP                             ; $95C2 00
            NOP                             ; $95C3 00
            NOP                             ; $95C4 00
            NOP                             ; $95C5 00
            NOP                             ; $95C6 00
            NOP                             ; $95C7 00
            NOP                             ; $95C8 00
            NOP                             ; $95C9 00
            NOP                             ; $95CA 00
            NOP                             ; $95CB 00
            NOP                             ; $95CC 00
            NOP                             ; $95CD 00
            NOP                             ; $95CE 00
            NOP                             ; $95CF 00
            NOP                             ; $95D0 00
            NOP                             ; $95D1 00
            NOP                             ; $95D2 00
            NOP                             ; $95D3 00
            NOP                             ; $95D4 00
            NOP                             ; $95D5 00
            NOP                             ; $95D6 00
            NOP                             ; $95D7 00
            NOP                             ; $95D8 00
            NOP                             ; $95D9 00
            NOP                             ; $95DA 00
            NOP                             ; $95DB 00
            NOP                             ; $95DC 00
            NOP                             ; $95DD 00
            NOP                             ; $95DE 00
            NOP                             ; $95DF 00
            NOP                             ; $95E0 00
            NOP                             ; $95E1 00
            NOP                             ; $95E2 00
            NOP                             ; $95E3 00
            NOP                             ; $95E4 00
            NOP                             ; $95E5 00
            NOP                             ; $95E6 00
            NOP                             ; $95E7 00
            NOP                             ; $95E8 00
            NOP                             ; $95E9 00
            NOP                             ; $95EA 00
            NOP                             ; $95EB 00
            NOP                             ; $95EC 00
            NOP                             ; $95ED 00
            NOP                             ; $95EE 00
            NOP                             ; $95EF 00
            NOP                             ; $95F0 00
            NOP                             ; $95F1 00
            NOP                             ; $95F2 00
            NOP                             ; $95F3 00
            NOP                             ; $95F4 00
            NOP                             ; $95F5 00
            NOP                             ; $95F6 00
            NOP                             ; $95F7 00
            NOP                             ; $95F8 00
            NOP                             ; $95F9 00
            NOP                             ; $95FA 00
            NOP                             ; $95FB 00
            NOP                             ; $95FC 00
            NOP                             ; $95FD 00
            NOP                             ; $95FE 00
            NOP                             ; $95FF 00
            PUSH HL                         ; $9600 E5
            PUSH HL                         ; $9601 E5
            PUSH HL                         ; $9602 E5
            PUSH HL                         ; $9603 E5
            PUSH HL                         ; $9604 E5
            PUSH HL                         ; $9605 E5
            PUSH HL                         ; $9606 E5
            PUSH HL                         ; $9607 E5
            PUSH HL                         ; $9608 E5
            PUSH HL                         ; $9609 E5
            PUSH HL                         ; $960A E5
            PUSH HL                         ; $960B E5
            PUSH HL                         ; $960C E5
            PUSH HL                         ; $960D E5
            PUSH HL                         ; $960E E5
            PUSH HL                         ; $960F E5
            PUSH HL                         ; $9610 E5
            PUSH HL                         ; $9611 E5
            PUSH HL                         ; $9612 E5
            PUSH HL                         ; $9613 E5
            PUSH HL                         ; $9614 E5
            PUSH HL                         ; $9615 E5
            PUSH HL                         ; $9616 E5
            PUSH HL                         ; $9617 E5
            PUSH HL                         ; $9618 E5
            PUSH HL                         ; $9619 E5
            PUSH HL                         ; $961A E5
            PUSH HL                         ; $961B E5
            PUSH HL                         ; $961C E5
            PUSH HL                         ; $961D E5
            PUSH HL                         ; $961E E5
            PUSH HL                         ; $961F E5
            PUSH HL                         ; $9620 E5
            PUSH HL                         ; $9621 E5
            PUSH HL                         ; $9622 E5
            PUSH HL                         ; $9623 E5
            PUSH HL                         ; $9624 E5
            PUSH HL                         ; $9625 E5
            PUSH HL                         ; $9626 E5
            PUSH HL                         ; $9627 E5
            PUSH HL                         ; $9628 E5
            PUSH HL                         ; $9629 E5
            PUSH HL                         ; $962A E5
            PUSH HL                         ; $962B E5
            PUSH HL                         ; $962C E5
            PUSH HL                         ; $962D E5
            PUSH HL                         ; $962E E5
            PUSH HL                         ; $962F E5
            PUSH HL                         ; $9630 E5
            PUSH HL                         ; $9631 E5
            PUSH HL                         ; $9632 E5
            PUSH HL                         ; $9633 E5
            PUSH HL                         ; $9634 E5
            PUSH HL                         ; $9635 E5
            PUSH HL                         ; $9636 E5
            PUSH HL                         ; $9637 E5
            PUSH HL                         ; $9638 E5
            PUSH HL                         ; $9639 E5
            PUSH HL                         ; $963A E5
            PUSH HL                         ; $963B E5
            PUSH HL                         ; $963C E5
            PUSH HL                         ; $963D E5
            PUSH HL                         ; $963E E5
            PUSH HL                         ; $963F E5
            PUSH HL                         ; $9640 E5
            PUSH HL                         ; $9641 E5
            PUSH HL                         ; $9642 E5
            PUSH HL                         ; $9643 E5
            PUSH HL                         ; $9644 E5
            PUSH HL                         ; $9645 E5
            PUSH HL                         ; $9646 E5
            PUSH HL                         ; $9647 E5
            PUSH HL                         ; $9648 E5
            PUSH HL                         ; $9649 E5
            PUSH HL                         ; $964A E5
            PUSH HL                         ; $964B E5
            PUSH HL                         ; $964C E5
            PUSH HL                         ; $964D E5
            PUSH HL                         ; $964E E5
            PUSH HL                         ; $964F E5
            PUSH HL                         ; $9650 E5
            PUSH HL                         ; $9651 E5
            PUSH HL                         ; $9652 E5
            PUSH HL                         ; $9653 E5
            PUSH HL                         ; $9654 E5
            PUSH HL                         ; $9655 E5
            PUSH HL                         ; $9656 E5
            PUSH HL                         ; $9657 E5
            PUSH HL                         ; $9658 E5
            PUSH HL                         ; $9659 E5
            PUSH HL                         ; $965A E5
            PUSH HL                         ; $965B E5
            PUSH HL                         ; $965C E5
            PUSH HL                         ; $965D E5
            PUSH HL                         ; $965E E5
            PUSH HL                         ; $965F E5
            PUSH HL                         ; $9660 E5
            PUSH HL                         ; $9661 E5
            PUSH HL                         ; $9662 E5
            PUSH HL                         ; $9663 E5
            PUSH HL                         ; $9664 E5
            PUSH HL                         ; $9665 E5
            PUSH HL                         ; $9666 E5
            PUSH HL                         ; $9667 E5
            PUSH HL                         ; $9668 E5
            PUSH HL                         ; $9669 E5
            PUSH HL                         ; $966A E5
            PUSH HL                         ; $966B E5
            PUSH HL                         ; $966C E5
            PUSH HL                         ; $966D E5
            PUSH HL                         ; $966E E5
            PUSH HL                         ; $966F E5
            PUSH HL                         ; $9670 E5
            PUSH HL                         ; $9671 E5
            PUSH HL                         ; $9672 E5
            PUSH HL                         ; $9673 E5
            PUSH HL                         ; $9674 E5
            PUSH HL                         ; $9675 E5
            PUSH HL                         ; $9676 E5
            PUSH HL                         ; $9677 E5
            PUSH HL                         ; $9678 E5
            PUSH HL                         ; $9679 E5
            PUSH HL                         ; $967A E5
            PUSH HL                         ; $967B E5
            PUSH HL                         ; $967C E5
            PUSH HL                         ; $967D E5
            PUSH HL                         ; $967E E5
            PUSH HL                         ; $967F E5
            PUSH HL                         ; $9680 E5
            PUSH HL                         ; $9681 E5
            PUSH HL                         ; $9682 E5
            PUSH HL                         ; $9683 E5
            PUSH HL                         ; $9684 E5
            PUSH HL                         ; $9685 E5
            PUSH HL                         ; $9686 E5
            PUSH HL                         ; $9687 E5
            PUSH HL                         ; $9688 E5
            PUSH HL                         ; $9689 E5
            PUSH HL                         ; $968A E5
            PUSH HL                         ; $968B E5
            PUSH HL                         ; $968C E5
            PUSH HL                         ; $968D E5
            PUSH HL                         ; $968E E5
            PUSH HL                         ; $968F E5
            PUSH HL                         ; $9690 E5
            PUSH HL                         ; $9691 E5
            PUSH HL                         ; $9692 E5
            PUSH HL                         ; $9693 E5
            PUSH HL                         ; $9694 E5
            PUSH HL                         ; $9695 E5
            PUSH HL                         ; $9696 E5
            PUSH HL                         ; $9697 E5
            PUSH HL                         ; $9698 E5
            PUSH HL                         ; $9699 E5
            PUSH HL                         ; $969A E5
            PUSH HL                         ; $969B E5
            PUSH HL                         ; $969C E5
            PUSH HL                         ; $969D E5
            PUSH HL                         ; $969E E5
            PUSH HL                         ; $969F E5
            PUSH HL                         ; $96A0 E5
            PUSH HL                         ; $96A1 E5
            PUSH HL                         ; $96A2 E5
            PUSH HL                         ; $96A3 E5
            PUSH HL                         ; $96A4 E5
            PUSH HL                         ; $96A5 E5
            PUSH HL                         ; $96A6 E5
            PUSH HL                         ; $96A7 E5
            PUSH HL                         ; $96A8 E5
            PUSH HL                         ; $96A9 E5
            PUSH HL                         ; $96AA E5
            PUSH HL                         ; $96AB E5
            PUSH HL                         ; $96AC E5
            PUSH HL                         ; $96AD E5
            PUSH HL                         ; $96AE E5
            PUSH HL                         ; $96AF E5
            PUSH HL                         ; $96B0 E5
            PUSH HL                         ; $96B1 E5
            PUSH HL                         ; $96B2 E5
            PUSH HL                         ; $96B3 E5
            PUSH HL                         ; $96B4 E5
            PUSH HL                         ; $96B5 E5
            PUSH HL                         ; $96B6 E5
            PUSH HL                         ; $96B7 E5
            PUSH HL                         ; $96B8 E5
            PUSH HL                         ; $96B9 E5
            PUSH HL                         ; $96BA E5
            PUSH HL                         ; $96BB E5
            PUSH HL                         ; $96BC E5
            PUSH HL                         ; $96BD E5
            PUSH HL                         ; $96BE E5
            PUSH HL                         ; $96BF E5
            PUSH HL                         ; $96C0 E5
            PUSH HL                         ; $96C1 E5
            PUSH HL                         ; $96C2 E5
            PUSH HL                         ; $96C3 E5
            PUSH HL                         ; $96C4 E5
            PUSH HL                         ; $96C5 E5
            PUSH HL                         ; $96C6 E5
            PUSH HL                         ; $96C7 E5
            PUSH HL                         ; $96C8 E5
            PUSH HL                         ; $96C9 E5
            PUSH HL                         ; $96CA E5
            PUSH HL                         ; $96CB E5
            PUSH HL                         ; $96CC E5
            PUSH HL                         ; $96CD E5
            PUSH HL                         ; $96CE E5
            PUSH HL                         ; $96CF E5
            PUSH HL                         ; $96D0 E5
            PUSH HL                         ; $96D1 E5
            PUSH HL                         ; $96D2 E5
            PUSH HL                         ; $96D3 E5
            PUSH HL                         ; $96D4 E5
            PUSH HL                         ; $96D5 E5
            PUSH HL                         ; $96D6 E5
            PUSH HL                         ; $96D7 E5
            PUSH HL                         ; $96D8 E5
            PUSH HL                         ; $96D9 E5
            PUSH HL                         ; $96DA E5
            PUSH HL                         ; $96DB E5
            PUSH HL                         ; $96DC E5
            PUSH HL                         ; $96DD E5
            PUSH HL                         ; $96DE E5
            PUSH HL                         ; $96DF E5
            PUSH HL                         ; $96E0 E5
            PUSH HL                         ; $96E1 E5
            PUSH HL                         ; $96E2 E5
            PUSH HL                         ; $96E3 E5
            PUSH HL                         ; $96E4 E5
            PUSH HL                         ; $96E5 E5
            PUSH HL                         ; $96E6 E5
            PUSH HL                         ; $96E7 E5
            PUSH HL                         ; $96E8 E5
            PUSH HL                         ; $96E9 E5
            PUSH HL                         ; $96EA E5
            PUSH HL                         ; $96EB E5
            PUSH HL                         ; $96EC E5
            PUSH HL                         ; $96ED E5
            PUSH HL                         ; $96EE E5
            PUSH HL                         ; $96EF E5
            PUSH HL                         ; $96F0 E5
            PUSH HL                         ; $96F1 E5
            PUSH HL                         ; $96F2 E5
            PUSH HL                         ; $96F3 E5
            PUSH HL                         ; $96F4 E5
            PUSH HL                         ; $96F5 E5
            PUSH HL                         ; $96F6 E5
            PUSH HL                         ; $96F7 E5
            PUSH HL                         ; $96F8 E5
            PUSH HL                         ; $96F9 E5
            PUSH HL                         ; $96FA E5
            PUSH HL                         ; $96FB E5
            PUSH HL                         ; $96FC E5
            PUSH HL                         ; $96FD E5
            PUSH HL                         ; $96FE E5


; ============================================================================
; END OF SYSIMG -- 2.20 has no boot banner; sysimg tail is $E5 filler.
; ============================================================================
