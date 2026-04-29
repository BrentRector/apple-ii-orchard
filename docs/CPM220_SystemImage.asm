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
$8000: CF        RST $08
$8001: C7        RST $00
$8002: 13        INC DE
$8003: 23        INC HL
$8004: 05        DEC B
$8005: C2 FD C5  JP NZ,C5FD
$8008: C9        RET
$8009: CD 98 C4  CALL C498
$800C: 2A 8A C4  LD HL,(C48A)
$800F: 7E        LD A,(HL)
$8010: FE 20     CP 20
$8012: CA 22 C6  JP Z,C622
$8015: B7        OR A
$8016: CA 22 C6  JP Z,C622
$8019: E5        PUSH HL
$801A: CD 8C C4  CALL C48C
$801D: E1        POP HL
$801E: 23        INC HL
$801F: C3 0F C6  JP C60F
$8022: 3E 3F     LD A,3F
$8024: CD 8C C4  CALL C48C
$8027: CD 98 C4  CALL C498
$802A: CD DD C5  CALL C5DD
$802D: C3 82 C7  JP C782
$8030: 1A        LD A,(DE)
$8031: B7        OR A
$8032: C8        RET Z
$8033: FE 20     CP 20
$8035: DA 09 C6  JP C,C609
$8038: C8        RET Z
$8039: FE 3D     CP 3D
$803B: C8        RET Z
$803C: FE 5F     CP 5F
$803E: C8        RET Z
$803F: FE 2E     CP 2E
$8041: C8        RET Z
$8042: FE 3A     CP 3A
$8044: C8        RET Z
$8045: FE 3B     CP 3B
$8047: C8        RET Z
$8048: FE 3C     CP 3C
$804A: C8        RET Z
$804B: FE 3E     CP 3E
$804D: C8        RET Z
$804E: C9        RET
$804F: 1A        LD A,(DE)
$8050: B7        OR A
$8051: C8        RET Z
$8052: FE 20     CP 20
$8054: C0        RET NZ
$8055: 13        INC DE
$8056: C3 4F C6  JP C64F
$8059: 85        ADD A,L
$805A: 6F        LD L,A
$805B: D0        RET NC
$805C: 24        INC H
$805D: C9        RET
$805E: 3E 00     LD A,00
$8060: 21 CD CB  LD HL,CBCD
$8063: CD 59 C6  CALL C659
$8066: E5        PUSH HL
$8067: E5        PUSH HL
$8068: AF        XOR A
$8069: 32 F0 CB  LD (CBF0),A
$806C: 2A 88 C4  LD HL,(C488)
$806F: EB        EX DE,HL
$8070: CD 4F C6  CALL C64F
$8073: EB        EX DE,HL
$8074: 22 8A C4  LD (C48A),HL
$8077: EB        EX DE,HL
$8078: E1        POP HL
$8079: 1A        LD A,(DE)
$807A: B7        OR A
$807B: CA 89 C6  JP Z,C689
$807E: DE 40     SBC A,40
$8080: 47        LD B,A
$8081: 13        INC DE
$8082: 1A        LD A,(DE)
$8083: FE 3A     CP 3A
$8085: CA 90 C6  JP Z,C690
$8088: 1B        DEC DE
$8089: 3A EF CB  LD A,(CBEF)
$808C: 77        LD (HL),A
$808D: C3 96 C6  JP C696
$8090: 78        LD A,B
$8091: 32 F0 CB  LD (CBF0),A
$8094: 70        LD (HL),B
$8095: 13        INC DE
$8096: 06 08     LD B,08
$8098: CD 30 C6  CALL C630
$809B: CA B9 C6  JP Z,C6B9
$809E: 23        INC HL
$809F: FE 2A     CP 2A
$80A1: C2 A9 C6  JP NZ,C6A9
$80A4: 36 3F     LD (HL),3F
$80A6: C3 AB C6  JP C6AB
$80A9: 77        LD (HL),A
$80AA: 13        INC DE
$80AB: 05        DEC B
$80AC: C2 98 C6  JP NZ,C698
$80AF: CD 30 C6  CALL C630
$80B2: CA C0 C6  JP Z,C6C0
$80B5: 13        INC DE
$80B6: C3 AF C6  JP C6AF
$80B9: 23        INC HL
$80BA: 36 20     LD (HL),20
$80BC: 05        DEC B
$80BD: C2 B9 C6  JP NZ,C6B9
$80C0: 06 03     LD B,03
$80C2: FE 2E     CP 2E
$80C4: C2 E9 C6  JP NZ,C6E9
$80C7: 13        INC DE
$80C8: CD 30 C6  CALL C630
$80CB: CA E9 C6  JP Z,C6E9
$80CE: 23        INC HL
$80CF: FE 2A     CP 2A
$80D1: C2 D9 C6  JP NZ,C6D9
$80D4: 36 3F     LD (HL),3F
$80D6: C3 DB C6  JP C6DB
$80D9: 77        LD (HL),A
$80DA: 13        INC DE
$80DB: 05        DEC B
$80DC: C2 C8 C6  JP NZ,C6C8
$80DF: CD 30 C6  CALL C630
$80E2: CA F0 C6  JP Z,C6F0
$80E5: 13        INC DE
$80E6: C3 DF C6  JP C6DF
$80E9: 23        INC HL
$80EA: 36 20     LD (HL),20
$80EC: 05        DEC B
$80ED: C2 E9 C6  JP NZ,C6E9
$80F0: 06 03     LD B,03
$80F2: 23        INC HL
$80F3: 36 00     LD (HL),00
$80F5: 05        DEC B
$80F6: C2 F2 C6  JP NZ,C6F2
$80F9: EB        EX DE,HL
$80FA: 22 88 C4  LD (C488),HL
$80FD: E1        POP HL
$80FE: 01 0B CE  LD BC,CE0B
$8101: F8        RET M
$8102: 04        INC B
$8103: D0        RET NC
$8104: E5        PUSH HL
$8105: F0        RET P
$8106: CA 68 A9  JP Z,A968
$8109: 40        LD B,B
$810A: 28 4C     JR Z,8158
$810C: 3E 0F     LD A,0F
$810E: F0        RET P
$810F: 2A A5 2F  LD HL,(2FA5)
$8112: 8D        ADC A,L
$8113: E3        EX (SP),HL
$8114: 03        INC BC
$8115: AD        XOR L
$8116: E2 03 F0  JP PO,F003
$8119: 08        EX AF,AF'
$811A: C5        PUSH BC
$811B: 2F        CPL
$811C: F0        RET P
$811D: 04        INC B
$811E: A9        XOR C
$811F: 20 D0     JR NZ,80F1
$8121: E8        RET PE
$8122: AD        XOR L
$8123: E1        POP HL
$8124: 03        INC BC
$8125: A8        XOR B
$8126: B9        CP C
$8127: 9D        SBC A,L
$8128: 0F        RRCA
$8129: C5        PUSH BC
$812A: 2D        DEC L
$812B: D0        RET NC
$812C: 9F        SBC A,A
$812D: 28 90     JR Z,80BF
$812F: 19        ADD HL,DE
$8130: 20 00     JR NZ,8132
$8132: 0B        DEC BC
$8133: 08        EX AF,AF'
$8134: B0        OR B
$8135: 96        SUB (HL)
$8136: 28 20     JR Z,8158
$8138: C6 0B     ADD A,0B
$813A: 18 A9     JR 80E5
$813C: 00        NOP
$813D: 24        INC H
$813E: 38 8D     JR C,80CD
$8140: EA 03 AE  JP PE,AE03
$8143: F8        RET M
$8144: 05        DEC B
$8145: BD        CP L
$8146: 88        ADC A,B
$8147: C0        RET NZ
$8148: 60        LD H,B
$8149: 20 25     JR NZ,8170
$814B: 0A        LD A,(BC)
$814C: 90        SUB B
$814D: EC A9 10  CALL PE,10A9
$8150: D0        RET NC
$8151: EC 0A 20  CALL PE,200A
$8154: 5A        LD E,D
$8155: 0F        RRCA
$8156: 4E        LD C,(HL)
$8157: 78        LD A,B
$8158: 04        INC B
$8159: 60        LD H,B
$815A: 85        ADD A,L
$815B: 2E 20     LD L,20
$815D: 7D        LD A,L
$815E: 0F        RRCA
$815F: B9        CP C
$8160: 78        LD A,B
$8161: 04        INC B
$8162: 24        INC H
$8163: 35        DEC (HL)
$8164: 30 03     JR NC,8169
$8166: B9        CP C
$8167: F8        RET M
$8168: 04        INC B
$8169: 8D        ADC A,L
$816A: 78        LD A,B
$816B: 04        INC B
$816C: A5        AND L
$816D: 2E 24     LD L,24
$816F: 35        DEC (HL)
$8170: 30 05     JR NC,8177
$8172: 99        SBC A,C
$8173: F8        RET M
$8174: 04        INC B
$8175: 10 03     DJNZ 817A
$8177: 99        SBC A,C
$8178: 78        LD A,B
$8179: 04        INC B
$817A: 4C        LD C,H
$817B: DE 0B     SBC A,0B
$817D: 8A        ADC A,D
$817E: 4A        LD C,D
$817F: 4A        LD C,D
$8180: 4A        LD C,D
$8181: 4A        LD C,D
$8182: A8        XOR B
$8183: 60        LD H,B
$8184: 48        LD C,B
$8185: AD        XOR L
$8186: E4 03 6A  CALL PO,6A03
$8189: 66        LD H,(HL)
$818A: 35        DEC (HL)
$818B: 20 7D     JR NZ,820A
$818D: 0F        RRCA
$818E: 68        LD L,B
$818F: 0A        LD A,(BC)
$8190: 24        INC H
$8191: 35        DEC (HL)
$8192: 30 05     JR NC,8199
$8194: 99        SBC A,C
$8195: F8        RET M
$8196: 04        INC B
$8197: 10 03     DJNZ 819C
$8199: 99        SBC A,C
$819A: 78        LD A,B
$819B: 04        INC B
$819C: 60        LD H,B
$819D: 00        NOP
$819E: 02        LD (BC),A
$819F: 04        INC B
$81A0: 06 08     LD B,08
$81A2: 0A        LD A,(BC)
$81A3: 0C        INC C
$81A4: 0E 01     LD C,01
$81A6: 03        INC BC
$81A7: 05        DEC B
$81A8: 07        RLCA
$81A9: 09        ADD HL,BC
$81AA: 0B        DEC BC
$81AB: 0D        DEC C
$81AC: 0F        RRCA
$81AD: A9        XOR C
$81AE: E4 8D E9  CALL PO,E98D
$81B1: 03        INC BC
$81B2: A0        AND B
$81B3: 00        NOP
$81B4: 8C        ADC A,H
$81B5: E8        RET PE
$81B6: 03        INC BC
$81B7: 8C        ADC A,H
$81B8: E0        RET PO
$81B9: 03        INC BC
$81BA: C8        RET Z
$81BB: 8C        ADC A,H
$81BC: E4 03 8C  CALL PO,8C03
$81BF: EB        EX DE,HL
$81C0: 03        INC BC
$81C1: A9        XOR C
$81C2: 60        LD H,B
$81C3: 8D        ADC A,L
$81C4: E6 03     AND 03
$81C6: A9        XOR C
$81C7: 0B        DEC BC
$81C8: 8D        ADC A,L
$81C9: E1        POP HL
$81CA: 03        INC BC
$81CB: A9        XOR C
$81CC: 1C        INC E
$81CD: 48        LD C,B
$81CE: 08        EX AF,AF'
$81CF: 78        LD A,B
$81D0: 20 10     JR NZ,81E2
$81D2: 0E 90     LD C,90
$81D4: 08        EX AF,AF'
$81D5: 20 2D     JR NZ,8204
$81D7: FF        RST $38
$81D8: 28 68     JR Z,8242
$81DA: 4C        LD C,H
$81DB: AD        XOR L
$81DC: 0F        RRCA
$81DD: 28 EE     JR Z,81CD
$81DF: E9        JP (HL)
$81E0: 03        INC BC
$81E1: AE        XOR (HL)
$81E2: E1        POP HL
$81E3: 03        INC BC
$81E4: E8        RET PE
$81E5: E0        RET PO
$81E6: 10 D0     DJNZ 81B8
$81E8: 05        DEC B
$81E9: A2        AND D
$81EA: 00        NOP
$81EB: EE E0     XOR E0
$81ED: 03        INC BC
$81EE: 8E        ADC A,(HL)
$81EF: E1        POP HL
$81F0: 03        INC BC
$81F1: 68        LD L,B
$81F2: 38 E9     JR C,81DD
$81F4: 01 D0 D6  LD BC,D6D0
$81F7: A9        XOR C
$81F8: 08        EX AF,AF'
$81F9: 8D        ADC A,L
$81FA: E9        JP (HL)
$81FB: 03        INC BC
$81FC: 60        LD H,B
$81FD: FF        RST $38
$81FE: FF        RST $38
$81FF: FF        RST $38
$8200: 00        NOP
$8201: 23        INC HL
$8202: 7E        LD A,(HL)
$8203: FE 3F     CP 3F
$8205: C2 09 C7  JP NZ,C709
$8208: 04        INC B
$8209: 0D        DEC C
$820A: C2 01 C7  JP NZ,C701
$820D: 78        LD A,B
$820E: B7        OR A
$820F: C9        RET
$8210: 44        LD B,H
$8211: 49        LD C,C
$8212: 52        LD D,D
$8213: 20 45     JR NZ,825A
$8215: 52        LD D,D
$8216: 41        LD B,C
$8217: 20 54     JR NZ,826D
$8219: 59        LD E,C
$821A: 50        LD D,B
$821B: 45        LD B,L
$821C: 53        LD D,E
$821D: 41        LD B,C
$821E: 56        LD D,(HL)
$821F: 45        LD B,L
$8220: 52        LD D,D
$8221: 45        LD B,L
$8222: 4E        LD C,(HL)
$8223: 20 55     JR NZ,827A
$8225: 53        LD D,E
$8226: 45        LD B,L
$8227: 52        LD D,D
$8228: BD        CP L
$8229: 16 00     LD D,00
$822B: 00        NOP
$822C: 60        LD H,B
$822D: D9        EXX
$822E: 21 10 C7  LD HL,C710
$8231: 0E 00     LD C,00
$8233: 79        LD A,C
$8234: FE 06     CP 06
$8236: D0        RET NC
$8237: 11 CE CB  LD DE,CBCE
$823A: 06 04     LD B,04
$823C: 1A        LD A,(DE)
$823D: BE        CP (HL)
$823E: C2 4F C7  JP NZ,C74F
$8241: 13        INC DE
$8242: 23        INC HL
$8243: 05        DEC B
$8244: C2 3C C7  JP NZ,C73C
$8247: 1A        LD A,(DE)
$8248: FE 20     CP 20
$824A: C2 54 C7  JP NZ,C754
$824D: 79        LD A,C
$824E: C9        RET
$824F: 23        INC HL
$8250: 05        DEC B
$8251: C2 4F C7  JP NZ,C74F
$8254: 0C        INC C
$8255: C3 33 C7  JP C733
$8258: AF        XOR A
$8259: 32 07 C4  LD (C407),A
$825C: 31 AB CB  LD SP,CBAB
$825F: C5        PUSH BC
$8260: 79        LD A,C
$8261: 1F        RRA
$8262: 1F        RRA
$8263: 1F        RRA
$8264: 1F        RRA
$8265: E6 0F     AND 0F
$8267: 5F        LD E,A
$8268: CD 15 C5  CALL C515
$826B: CD B8 C4  CALL C4B8
$826E: 32 AB CB  LD (CBAB),A
$8271: C1        POP BC
$8272: 79        LD A,C
$8273: E6 0F     AND 0F
$8275: 32 EF CB  LD (CBEF),A
$8278: CD BD C4  CALL C4BD
$827B: 3A 07 C4  LD A,(C407)
$827E: B7        OR A
$827F: C2 98 C7  JP NZ,C798
$8282: 31 AB CB  LD SP,CBAB
$8285: CD 98 C4  CALL C498
$8288: CD D0 C5  CALL C5D0
$828B: C6 41     ADD A,41
$828D: CD 8C C4  CALL C48C
$8290: 3E 3E     LD A,3E
$8292: CD 8C C4  CALL C48C
$8295: CD 39 C5  CALL C539
$8298: 11 80 00  LD DE,0080
$829B: CD D8 C5  CALL C5D8
$829E: CD D0 C5  CALL C5D0
$82A1: 32 EF CB  LD (CBEF),A
$82A4: CD 5E C6  CALL C65E
$82A7: C4 09 C6  CALL NZ,C609
$82AA: 3A F0 CB  LD A,(CBF0)
$82AD: B7        OR A
$82AE: C2 A5 CA  JP NZ,CAA5
$82B1: CD 2E C7  CALL C72E
$82B4: 21 C1 C7  LD HL,C7C1
$82B7: 5F        LD E,A
$82B8: 16 00     LD D,00
$82BA: 19        ADD HL,DE
$82BB: 19        ADD HL,DE
$82BC: 7E        LD A,(HL)
$82BD: 23        INC HL
$82BE: 66        LD H,(HL)
$82BF: 6F        LD L,A
$82C0: E9        JP (HL)
$82C1: 77        LD (HL),A
$82C2: C8        RET Z
$82C3: 1F        RRA
$82C4: C9        RET
$82C5: 5D        LD E,L
$82C6: C9        RET
$82C7: AD        XOR L
$82C8: C9        RET
$82C9: 10 CA     DJNZ 8295
$82CB: 8E        ADC A,(HL)
$82CC: CA A5 CA  JP Z,CAA5
$82CF: 21 F3 76  LD HL,76F3
$82D2: 22 00 C4  LD (C400),HL
$82D5: 21 00 C4  LD HL,C400
$82D8: E9        JP (HL)
$82D9: 01 DF C7  LD BC,C7DF
$82DC: C3 A7 C4  JP C4A7
$82DF: 52        LD D,D
$82E0: 45        LD B,L
$82E1: 41        LD B,C
$82E2: 44        LD B,H
$82E3: 20 45     JR NZ,832A
$82E5: 52        LD D,D
$82E6: 52        LD D,D
$82E7: 4F        LD C,A
$82E8: 52        LD D,D
$82E9: 00        NOP
$82EA: 01 F0 C7  LD BC,C7F0
$82ED: C3 A7 C4  JP C4A7
$82F0: 4E        LD C,(HL)
$82F1: 4F        LD C,A
$82F2: 20 46     JR NZ,833A
$82F4: 49        LD C,C
$82F5: 4C        LD C,H
$82F6: 45        LD B,L
$82F7: 00        NOP
$82F8: CD 5E C6  CALL C65E
$82FB: 3A F0 CB  LD A,(CBF0)
$82FE: B7        OR A
$82FF: C2 AD 81  JP NZ,81AD
$8302: C0        RET NZ
$8303: AD        XOR L
$8304: 81        ADD A,C
$8305: C0        RET NZ
$8306: 20 7D     JR NZ,8385
$8308: 0F        RRCA
$8309: 48        LD C,B
$830A: 9D        SBC A,L
$830B: 88        ADC A,B
$830C: C0        RET NZ
$830D: A9        XOR C
$830E: 00        NOP
$830F: 99        SBC A,C
$8310: 78        LD A,B
$8311: 04        INC B
$8312: 99        SBC A,C
$8313: F8        RET M
$8314: 04        INC B
$8315: 20 2F     JR NZ,8346
$8317: FB        EI
$8318: 20 93     JR NZ,82AD
$831A: FE 20     CP 20
$831C: 89        ADC A,C
$831D: FE 68     CP 68
$831F: A2        AND D
$8320: FF        RST $38
$8321: 9A        SBC A,D
$8322: C9        RET
$8323: 06 F0     LD B,F0
$8325: 10 A0     DJNZ 82C7
$8327: 00        NOP
$8328: B9        CP C
$8329: 4A        LD C,D
$832A: 11 F0 06  LD DE,06F0
$832D: 20 ED     JR NZ,831C
$832F: FD        DB $FD
$8330: C8        RET Z
$8331: D0        RET NC
$8332: F5        PUSH AF
$8333: 4C        LD C,H
$8334: 65        LD H,L
$8335: FF        RST $38
$8336: A0        AND B
$8337: 0E B9     LD C,B9
$8339: 68        LD L,B
$833A: 11 99 FF  LD DE,FF99
$833D: 0F        RRCA
$833E: 88        ADC A,B
$833F: D0        RET NC
$8340: F7        RST $30
$8341: B9        CP C
$8342: 00        NOP
$8343: 12        LD (DE),A
$8344: 99        SBC A,C
$8345: 00        NOP
$8346: 02        LD (BC),A
$8347: 88        ADC A,B
$8348: D0        RET NC
$8349: F7        RST $30
$834A: A0        AND B
$834B: F1        POP AF
$834C: B9        CP C
$834D: FF        RST $38
$834E: 12        LD (DE),A
$834F: 99        SBC A,C
$8350: FF        RST $38
$8351: 02        LD (BC),A
$8352: 88        ADC A,B
$8353: D0        RET NC
$8354: F7        RST $30
$8355: 8C        ADC A,H
$8356: B8        CP B
$8357: 03        INC BC
$8358: 84        ADD A,H
$8359: 3C        INC A
$835A: 88        ADC A,B
$835B: 84        ADD A,H
$835C: 3E A0     LD A,A0
$835E: C7        RST $00
$835F: 20 80     JR NZ,82E1
$8361: 11 EA A5  LD DE,A5EA
$8364: 3E F0     LD A,F0
$8366: 18 20     JR 8388
$8368: 17        RLA
$8369: 11 85 40  LD DE,4085
$836C: 86        ADD A,(HL)
$836D: 41        LD B,C
$836E: 20 17     JR NZ,8387
$8370: 11 E0 00  LD DE,00E0
$8373: F0        RET P
$8374: 1E C5     LD E,C5
$8376: 40        LD B,B
$8377: D0        RET NC
$8378: 1A        LD A,(DE)
$8379: E4 41 F0  CALL PO,F041
$837C: 1A        LD A,(DE)
$837D: D0        RET NC
$837E: 14        INC D
$837F: E6 3E     AND 3E
$8381: 8C        ADC A,H
$8382: C8        RET Z
$8383: 03        INC BC
$8384: A9        XOR C
$8385: 00        NOP
$8386: 8D        ADC A,L
$8387: C7        RST $00
$8388: 03        INC BC
$8389: 8D        ADC A,L
$838A: DE 03     SBC A,03
$838C: 98        SBC A,B
$838D: 18 69     JR 83F8
$838F: 20 8D     JR NZ,831E
$8391: DF        RST $18
$8392: 03        INC BC
$8393: A2        AND D
$8394: 00        NOP
$8395: F0        RET P
$8396: 1F        RRA
$8397: A2        AND D
$8398: 04        INC B
$8399: A0        AND B
$839A: 05        DEC B
$839B: B1        OR C
$839C: 3C        INC A
$839D: DD        DB $DD
$839E: 76        HALT
$839F: 11 D0 09  LD DE,09D0
$83A2: A0        AND B
$83A3: 07        RLCA
$83A4: B1        OR C
$83A5: 3C        INC A
$83A6: DD        DB $DD
$83A7: 7A        LD A,D
$83A8: 11 F0 03  LD DE,03F0
$83AB: CA D0 EB  JP Z,EBD0
$83AE: E8        RET PE
$83AF: E0        RET PO
$83B0: 02        LD (BC),A
$83B1: D0        RET NC
$83B2: 03        INC BC
$83B3: EE B8     XOR B8
$83B5: 03        INC BC
$83B6: A4        AND H
$83B7: 3D        DEC A
$83B8: 8A        ADC A,D
$83B9: 99        SBC A,C
$83BA: F8        RET M
$83BB: 02        LD (BC),A
$83BC: 88        ADC A,B
$83BD: C0        RET NZ
$83BE: C0        RET NZ
$83BF: D0        RET NC
$83C0: 9E        SBC A,(HL)
$83C1: 0E B8     LD C,B8
$83C3: 03        INC BC
$83C4: A5        AND L
$83C5: 3E C9     LD A,C9
$83C7: 01 F0 1D  LD BC,1DF0
$83CA: 84        ADD A,H
$83CB: 3D        DEC A
$83CC: A9        XOR C
$83CD: 85        ADD A,L
$83CE: 85        ADD A,L
$83CF: 3C        INC A
$83D0: 8D        ADC A,L
$83D1: 85        ADD A,L
$83D2: C0        RET NZ
$83D3: A5        AND L
$83D4: 3E F0     LD A,F0
$83D6: 10 A0     DJNZ 8378
$83D8: 00        NOP
$83D9: B9        CP C
$83DA: 2B        DEC HL
$83DB: 11 F0 06  LD DE,06F0
$83DE: 20 ED     JR NZ,83CD
$83E0: FD        DB $FD
$83E1: C8        RET Z
$83E2: D0        RET NC
$83E3: F5        PUSH AF
$83E4: 4C        LD C,H
$83E5: 65        LD H,L
$83E6: FF        RST $38
$83E7: A0        AND B
$83E8: 10 B9     DJNZ 83A3
$83EA: EF        RST $28
$83EB: 13        INC DE
$83EC: 99        SBC A,C
$83ED: EF        RST $28
$83EE: 03        INC BC
$83EF: 88        ADC A,B
$83F0: D0        RET NC
$83F1: F7        RST $30
$83F2: A9        XOR C
$83F3: C3 8D 00  JP 008D
$83F6: 10 A9     DJNZ 83A1
$83F8: 00        NOP
$83F9: 8D        ADC A,L
$83FA: 01 10 A9  LD BC,A910
$83FD: DA 8D 02  JP C,028D
$8400: 09        ADD HL,BC
$8401: C6 21     ADD A,21
$8403: CE CB     ADC A,CB
$8405: 01 0B 00  LD BC,000B
$8408: 7E        LD A,(HL)
$8409: FE 20     CP 20
$840B: CA 33 C8  JP Z,C833
$840E: 23        INC HL
$840F: D6 30     SUB 30
$8411: FE 0A     CP 0A
$8413: D2 09 C6  JP NC,C609
$8416: 57        LD D,A
$8417: 78        LD A,B
$8418: E6 E0     AND E0
$841A: C2 09 C6  JP NZ,C609
$841D: 78        LD A,B
$841E: 07        RLCA
$841F: 07        RLCA
$8420: 07        RLCA
$8421: 80        ADD A,B
$8422: DA 09 C6  JP C,C609
$8425: 80        ADD A,B
$8426: DA 09 C6  JP C,C609
$8429: 82        ADD A,D
$842A: DA 09 C6  JP C,C609
$842D: 47        LD B,A
$842E: 0D        DEC C
$842F: C2 08 C8  JP NZ,C808
$8432: C9        RET
$8433: 7E        LD A,(HL)
$8434: FE 20     CP 20
$8436: C2 09 C6  JP NZ,C609
$8439: 23        INC HL
$843A: 0D        DEC C
$843B: C2 33 C8  JP NZ,C833
$843E: 78        LD A,B
$843F: C9        RET
$8440: 06 03     LD B,03
$8442: 7E        LD A,(HL)
$8443: 12        LD (DE),A
$8444: 23        INC HL
$8445: 13        INC DE
$8446: 05        DEC B
$8447: C2 42 C8  JP NZ,C842
$844A: C9        RET
$844B: 21 80 00  LD HL,0080
$844E: 81        ADD A,C
$844F: CD 59 C6  CALL C659
$8452: 7E        LD A,(HL)
$8453: C9        RET
$8454: AF        XOR A
$8455: 32 CD CB  LD (CBCD),A
$8458: 3A F0 CB  LD A,(CBF0)
$845B: B7        OR A
$845C: C8        RET Z
$845D: 3D        DEC A
$845E: 21 EF CB  LD HL,CBEF
$8461: BE        CP (HL)
$8462: C8        RET Z
$8463: C3 BD C4  JP C4BD
$8466: 3A F0 CB  LD A,(CBF0)
$8469: B7        OR A
$846A: C8        RET Z
$846B: 3D        DEC A
$846C: 21 EF CB  LD HL,CBEF
$846F: BE        CP (HL)
$8470: C8        RET Z
$8471: 3A EF CB  LD A,(CBEF)
$8474: C3 BD C4  JP C4BD
$8477: CD 5E C6  CALL C65E
$847A: CD 54 C8  CALL C854
$847D: 21 CE CB  LD HL,CBCE
$8480: 7E        LD A,(HL)
$8481: FE 20     CP 20
$8483: C2 8F C8  JP NZ,C88F
$8486: 06 0B     LD B,0B
$8488: 36 3F     LD (HL),3F
$848A: 23        INC HL
$848B: 05        DEC B
$848C: C2 88 C8  JP NZ,C888
$848F: 1E 00     LD E,00
$8491: D5        PUSH DE
$8492: CD E9 C4  CALL C4E9
$8495: CC EA C7  CALL Z,C7EA
$8498: CA 1B C9  JP Z,C91B
$849B: 3A EE CB  LD A,(CBEE)
$849E: 0F        RRCA
$849F: 0F        RRCA
$84A0: 0F        RRCA
$84A1: E6 60     AND 60
$84A3: 4F        LD C,A
$84A4: 3E 0A     LD A,0A
$84A6: CD 4B C8  CALL C84B
$84A9: 17        RLA
$84AA: DA 0F C9  JP C,C90F
$84AD: D1        POP DE
$84AE: 7B        LD A,E
$84AF: 1C        INC E
$84B0: D5        PUSH DE
$84B1: E6 03     AND 03
$84B3: F5        PUSH AF
$84B4: C2 CC C8  JP NZ,C8CC
$84B7: CD 98 C4  CALL C498
$84BA: C5        PUSH BC
$84BB: CD D0 C5  CALL C5D0
$84BE: C1        POP BC
$84BF: C6 41     ADD A,41
$84C1: CD 92 C4  CALL C492
$84C4: 3E 3A     LD A,3A
$84C6: CD 92 C4  CALL C492
$84C9: C3 D4 C8  JP C8D4
$84CC: CD A2 C4  CALL C4A2
$84CF: 3E 3A     LD A,3A
$84D1: CD 92 C4  CALL C492
$84D4: CD A2 C4  CALL C4A2
$84D7: 06 01     LD B,01
$84D9: 78        LD A,B
$84DA: CD 4B C8  CALL C84B
$84DD: E6 7F     AND 7F
$84DF: FE 20     CP 20
$84E1: C2 F9 C8  JP NZ,C8F9
$84E4: F1        POP AF
$84E5: F5        PUSH AF
$84E6: FE 03     CP 03
$84E8: C2 F7 C8  JP NZ,C8F7
$84EB: 3E 09     LD A,09
$84ED: CD 4B C8  CALL C84B
$84F0: E6 7F     AND 7F
$84F2: FE 20     CP 20
$84F4: CA 0E C9  JP Z,C90E
$84F7: 3E 20     LD A,20
$84F9: CD 92 C4  CALL C492
$84FC: 04        INC B
$84FD: 78        LD A,B
$84FE: FE 0C     CP 0C
$8500: D2 0E C9  JP NC,C90E
$8503: FE 09     CP 09
$8505: C2 D9 C8  JP NZ,C8D9
$8508: CD A2 C4  CALL C4A2
$850B: C3 D9 C8  JP C8D9
$850E: F1        POP AF
$850F: CD C2 C5  CALL C5C2
$8512: C2 1B C9  JP NZ,C91B
$8515: CD E4 C4  CALL C4E4
$8518: C3 98 C8  JP C898
$851B: D1        POP DE
$851C: C3 86 CB  JP CB86
$851F: CD 5E C6  CALL C65E
$8522: FE 0B     CP 0B
$8524: C2 42 C9  JP NZ,C942
$8527: 01 52 C9  LD BC,C952
$852A: CD A7 C4  CALL C4A7
$852D: CD 39 C5  CALL C539
$8530: 21 07 C4  LD HL,C407
$8533: 35        DEC (HL)
$8534: C2 82 C7  JP NZ,C782
$8537: 23        INC HL
$8538: 7E        LD A,(HL)
$8539: FE 59     CP 59
$853B: C2 82 C7  JP NZ,C782
$853E: 23        INC HL
$853F: 22 88 C4  LD (C488),HL
$8542: CD 54 C8  CALL C854
$8545: 11 CD CB  LD DE,CBCD
$8548: CD EF C4  CALL C4EF
$854B: 3C        INC A
$854C: CC EA C7  CALL Z,C7EA
$854F: C3 86 CB  JP CB86
$8552: 41        LD B,C
$8553: 4C        LD C,H
$8554: 4C        LD C,H
$8555: 20 28     JR NZ,857F
$8557: 59        LD E,C
$8558: 2F        CPL
$8559: 4E        LD C,(HL)
$855A: 29        ADD HL,HL
$855B: 3F        CCF
$855C: 00        NOP
$855D: CD 5E C6  CALL C65E
$8560: C2 09 C6  JP NZ,C609
$8563: CD 54 C8  CALL C854
$8566: CD D0 C4  CALL C4D0
$8569: CA A7 C9  JP Z,C9A7
$856C: CD 98 C4  CALL C498
$856F: 21 F1 CB  LD HL,CBF1
$8572: 36 FF     LD (HL),FF
$8574: 21 F1 CB  LD HL,CBF1
$8577: 7E        LD A,(HL)
$8578: FE 80     CP 80
$857A: DA 87 C9  JP C,C987
$857D: E5        PUSH HL
$857E: CD FE C4  CALL C4FE
$8581: E1        POP HL
$8582: C2 A0 C9  JP NZ,C9A0
$8585: AF        XOR A
$8586: 77        LD (HL),A
$8587: 34        INC (HL)
$8588: 21 80 00  LD HL,0080
$858B: CD 59 C6  CALL C659
$858E: 7E        LD A,(HL)
$858F: FE 1A     CP 1A
$8591: CA 86 CB  JP Z,CB86
$8594: CD 8C C4  CALL C48C
$8597: CD C2 C5  CALL C5C2
$859A: C2 86 CB  JP NZ,CB86
$859D: C3 74 C9  JP C974
$85A0: 3D        DEC A
$85A1: CA 86 CB  JP Z,CB86
$85A4: CD D9 C7  CALL C7D9
$85A7: CD 66 C8  CALL C866
$85AA: C3 09 C6  JP C609
$85AD: CD F8 C7  CALL C7F8
$85B0: F5        PUSH AF
$85B1: CD 5E C6  CALL C65E
$85B4: C2 09 C6  JP NZ,C609
$85B7: CD 54 C8  CALL C854
$85BA: 11 CD CB  LD DE,CBCD
$85BD: D5        PUSH DE
$85BE: CD EF C4  CALL C4EF
$85C1: D1        POP DE
$85C2: CD 09 C5  CALL C509
$85C5: CA FB C9  JP Z,C9FB
$85C8: AF        XOR A
$85C9: 32 ED CB  LD (CBED),A
$85CC: F1        POP AF
$85CD: 6F        LD L,A
$85CE: 26 00     LD H,00
$85D0: 29        ADD HL,HL
$85D1: 11 00 01  LD DE,0100
$85D4: 7C        LD A,H
$85D5: B5        OR L
$85D6: CA F1 C9  JP Z,C9F1
$85D9: 2B        DEC HL
$85DA: E5        PUSH HL
$85DB: 21 80 00  LD HL,0080
$85DE: 19        ADD HL,DE
$85DF: E5        PUSH HL
$85E0: CD D8 C5  CALL C5D8
$85E3: 11 CD CB  LD DE,CBCD
$85E6: CD 04 C5  CALL C504
$85E9: D1        POP DE
$85EA: E1        POP HL
$85EB: C2 FB C9  JP NZ,C9FB
$85EE: C3 D4 C9  JP C9D4
$85F1: 11 CD CB  LD DE,CBCD
$85F4: CD DA C4  CALL C4DA
$85F7: 3C        INC A
$85F8: C2 01 CA  JP NZ,CA01
$85FB: 01 07 CA  LD BC,CA07
$85FE: CD A7 C2  CALL C2A7
$8601: FD        DB $FD
$8602: D0        RET NC
$8603: C9        RET
$8604: 0C        INC C
$8605: 0D        DEC C
$8606: C8        RET Z
$8607: 29        ADD HL,HL
$8608: C3 05 D1  JP D105
$860B: C5        PUSH BC
$860C: 3A 42 CF  LD A,(CF42)
$860F: 4F        LD C,A
$8610: 21 01 00  LD HL,0001
$8613: CD 04 D1  CALL D104
$8616: C1        POP BC
$8617: 79        LD A,C
$8618: B5        OR L
$8619: 6F        LD L,A
$861A: 78        LD A,B
$861B: B4        OR H
$861C: 67        LD H,A
$861D: C9        RET
$861E: 2A AD D9  LD HL,(D9AD)
$8621: 3A 42 CF  LD A,(CF42)
$8624: 4F        LD C,A
$8625: CD EA D0  CALL D0EA
$8628: 7D        LD A,L
$8629: E6 01     AND 01
$862B: C9        RET
$862C: 21 AD D9  LD HL,D9AD
$862F: 4E        LD C,(HL)
$8630: 23        INC HL
$8631: 46        LD B,(HL)
$8632: CD 0B D1  CALL D10B
$8635: 22 AD D9  LD (D9AD),HL
$8638: 2A C8 D9  LD HL,(D9C8)
$863B: 23        INC HL
$863C: EB        EX DE,HL
$863D: 2A B3 D9  LD HL,(D9B3)
$8640: 73        LD (HL),E
$8641: 23        INC HL
$8642: 72        LD (HL),D
$8643: C9        RET
$8644: CD 5E D1  CALL D15E
$8647: 11 09 00  LD DE,0009
$864A: 19        ADD HL,DE
$864B: 7E        LD A,(HL)
$864C: 17        RLA
$864D: D0        RET NC
$864E: 21 0F CC  LD HL,CC0F
$8651: C3 4A CF  JP CF4A
$8654: CD 1E D1  CALL D11E
$8657: C8        RET Z
$8658: 21 0D CC  LD HL,CC0D
$865B: C3 4A CF  JP CF4A
$865E: 2A B9 D9  LD HL,(D9B9)
$8661: 3A E9 D9  LD A,(D9E9)
$8664: 85        ADD A,L
$8665: 6F        LD L,A
$8666: D0        RET NC
$8667: 24        INC H
$8668: C9        RET
$8669: 2A 43 CF  LD HL,(CF43)
$866C: 11 0E 00  LD DE,000E
$866F: 19        ADD HL,DE
$8670: 7E        LD A,(HL)
$8671: C9        RET
$8672: CD 69 D1  CALL D169
$8675: 36 00     LD (HL),00
$8677: C9        RET
$8678: CD 69 D1  CALL D169
$867B: F6 80     OR 80
$867D: 77        LD (HL),A
$867E: C9        RET
$867F: 2A EA D9  LD HL,(D9EA)
$8682: EB        EX DE,HL
$8683: 2A B3 D9  LD HL,(D9B3)
$8686: 7B        LD A,E
$8687: 96        SUB (HL)
$8688: 23        INC HL
$8689: 7A        LD A,D
$868A: 9E        SBC A,(HL)
$868B: C9        RET
$868C: CD 7F D1  CALL D17F
$868F: D8        RET C
$8690: 13        INC DE
$8691: 72        LD (HL),D
$8692: 2B        DEC HL
$8693: 73        LD (HL),E
$8694: C9        RET
$8695: 7B        LD A,E
$8696: 95        SUB L
$8697: 6F        LD L,A
$8698: 7A        LD A,D
$8699: 9C        SBC A,H
$869A: 67        LD H,A
$869B: C9        RET
$869C: 0E FF     LD C,FF
$869E: 2A EC D9  LD HL,(D9EC)
$86A1: EB        EX DE,HL
$86A2: 2A CC D9  LD HL,(D9CC)
$86A5: CD 95 D1  CALL D195
$86A8: D0        RET NC
$86A9: C5        PUSH BC
$86AA: CD F7 D0  CALL D0F7
$86AD: 2A BD D9  LD HL,(D9BD)
$86B0: EB        EX DE,HL
$86B1: 2A EC D9  LD HL,(D9EC)
$86B4: 19        ADD HL,DE
$86B5: C1        POP BC
$86B6: 0C        INC C
$86B7: CA C4 D1  JP Z,D1C4
$86BA: BE        CP (HL)
$86BB: C8        RET Z
$86BC: CD 7F D1  CALL D17F
$86BF: D0        RET NC
$86C0: CD 2C D1  CALL D12C
$86C3: C9        RET
$86C4: 77        LD (HL),A
$86C5: C9        RET
$86C6: CD 9C D1  CALL D19C
$86C9: CD E0 D1  CALL D1E0
$86CC: 0E 01     LD C,01
$86CE: CD B8 CF  CALL CFB8
$86D1: C3 DA D1  JP D1DA
$86D4: CD E0 D1  CALL D1E0
$86D7: CD B2 CF  CALL CFB2
$86DA: 21 B1 D9  LD HL,D9B1
$86DD: C3 E3 D1  JP D1E3
$86E0: 21 B9 D9  LD HL,D9B9
$86E3: 4E        LD C,(HL)
$86E4: 23        INC HL
$86E5: 46        LD B,(HL)
$86E6: C3 24 DA  JP DA24
$86E9: 2A B9 D9  LD HL,(D9B9)
$86EC: EB        EX DE,HL
$86ED: 2A B1 D9  LD HL,(D9B1)
$86F0: 0E 80     LD C,80
$86F2: C3 4F CF  JP CF4F
$86F5: 21 EA D9  LD HL,D9EA
$86F8: 7E        LD A,(HL)
$86F9: 23        INC HL
$86FA: BE        CP (HL)
$86FB: C0        RET NZ
$86FC: 3C        INC A
$86FD: C9        RET
$86FE: 21 FF C4  LD HL,C4FF
$8701: CD D5 C5  CALL C5D5
$8704: C3 86 CB  JP CB86
$8707: 4E        LD C,(HL)
$8708: 4F        LD C,A
$8709: 20 53     JR NZ,875E
$870B: 50        LD D,B
$870C: 41        LD B,C
$870D: 43        LD B,E
$870E: 45        LD B,L
$870F: 00        NOP
$8710: CD 5E C6  CALL C65E
$8713: C2 09 C6  JP NZ,C609
$8716: 3A F0 CB  LD A,(CBF0)
$8719: F5        PUSH AF
$871A: CD 54 C8  CALL C854
$871D: CD E9 C4  CALL C4E9
$8720: C2 79 CA  JP NZ,CA79
$8723: 21 CD CB  LD HL,CBCD
$8726: 11 DD CB  LD DE,CBDD
$8729: 06 10     LD B,10
$872B: CD 42 C8  CALL C842
$872E: 2A 88 C4  LD HL,(C488)
$8731: EB        EX DE,HL
$8732: CD 4F C6  CALL C64F
$8735: FE 3D     CP 3D
$8737: CA 3F CA  JP Z,CA3F
$873A: FE 5F     CP 5F
$873C: C2 73 CA  JP NZ,CA73
$873F: EB        EX DE,HL
$8740: 23        INC HL
$8741: 22 88 C4  LD (C488),HL
$8744: CD 5E C6  CALL C65E
$8747: C2 73 CA  JP NZ,CA73
$874A: F1        POP AF
$874B: 47        LD B,A
$874C: 21 F0 CB  LD HL,CBF0
$874F: 7E        LD A,(HL)
$8750: B7        OR A
$8751: CA 59 CA  JP Z,CA59
$8754: B8        CP B
$8755: 70        LD (HL),B
$8756: C2 73 CA  JP NZ,CA73
$8759: 70        LD (HL),B
$875A: AF        XOR A
$875B: 32 CD CB  LD (CBCD),A
$875E: CD E9 C4  CALL C4E9
$8761: CA 6D CA  JP Z,CA6D
$8764: 11 CD CB  LD DE,CBCD
$8767: CD 0E C5  CALL C50E
$876A: C3 86 CB  JP CB86
$876D: CD EA C7  CALL C7EA
$8770: C3 86 CB  JP CB86
$8773: CD 66 C8  CALL C866
$8776: C3 09 C6  JP C609
$8779: 01 82 CA  LD BC,CA82
$877C: CD A7 C4  CALL C4A7
$877F: C3 86 CB  JP CB86
$8782: 46        LD B,(HL)
$8783: 49        LD C,C
$8784: 4C        LD C,H
$8785: 45        LD B,L
$8786: 20 45     JR NZ,87CD
$8788: 58        LD E,B
$8789: 49        LD C,C
$878A: 53        LD D,E
$878B: 54        LD D,H
$878C: 53        LD D,E
$878D: 00        NOP
$878E: CD F8 C7  CALL C7F8
$8791: FE 10     CP 10
$8793: D2 09 C6  JP NC,C609
$8796: 5F        LD E,A
$8797: 3A CE CB  LD A,(CBCE)
$879A: FE 20     CP 20
$879C: CA 09 C6  JP Z,C609
$879F: CD 15 C5  CALL C515
$87A2: C3 89 CB  JP CB89
$87A5: CD F5 C5  CALL C5F5
$87A8: 3A CE CB  LD A,(CBCE)
$87AB: FE 20     CP 20
$87AD: C2 C4 CA  JP NZ,CAC4
$87B0: 3A F0 CB  LD A,(CBF0)
$87B3: B7        OR A
$87B4: CA 89 CB  JP Z,CB89
$87B7: 3D        DEC A
$87B8: 32 EF CB  LD (CBEF),A
$87BB: CD 29 C5  CALL C529
$87BE: CD BD C4  CALL C4BD
$87C1: C3 89 CB  JP CB89
$87C4: 11 D6 CB  LD DE,CBD6
$87C7: 1A        LD A,(DE)
$87C8: FE 20     CP 20
$87CA: C2 09 C6  JP NZ,C609
$87CD: D5        PUSH DE
$87CE: CD 54 C8  CALL C854
$87D1: D1        POP DE
$87D2: 21 83 CB  LD HL,CB83
$87D5: CD 40 C8  CALL C840
$87D8: CD D0 C4  CALL C4D0
$87DB: CA 6B CB  JP Z,CB6B
$87DE: 21 00 01  LD HL,0100
$87E1: E5        PUSH HL
$87E2: EB        EX DE,HL
$87E3: CD D8 C5  CALL C5D8
$87E6: 11 CD CB  LD DE,CBCD
$87E9: CD F9 C4  CALL C4F9
$87EC: C2 01 CB  JP NZ,CB01
$87EF: E1        POP HL
$87F0: 11 80 00  LD DE,0080
$87F3: 19        ADD HL,DE
$87F4: 11 00 C4  LD DE,C400
$87F7: 7D        LD A,L
$87F8: 93        SUB E
$87F9: 7C        LD A,H
$87FA: 9A        SBC A,D
$87FB: D2 71 CB  JP NC,CB71
$87FE: C3 E1 FF  JP FFE1
$8801: 22 EA D9  LD (D9EA),HL
$8804: C9        RET
$8805: 2A C8 D9  LD HL,(D9C8)
$8808: EB        EX DE,HL
$8809: 2A EA D9  LD HL,(D9EA)
$880C: 23        INC HL
$880D: 22 EA D9  LD (D9EA),HL
$8810: CD 95 D1  CALL D195
$8813: D2 19 D2  JP NC,D219
$8816: C3 FE D1  JP D1FE
$8819: 3A EA D9  LD A,(D9EA)
$881C: E6 03     AND 03
$881E: 06 05     LD B,05
$8820: 87        ADD A,A
$8821: 05        DEC B
$8822: C2 20 D2  JP NZ,D220
$8825: 32 E9 D9  LD (D9E9),A
$8828: B7        OR A
$8829: C0        RET NZ
$882A: C5        PUSH BC
$882B: CD C3 CF  CALL CFC3
$882E: CD D4 D1  CALL D1D4
$8831: C1        POP BC
$8832: C3 9E D1  JP D19E
$8835: 79        LD A,C
$8836: E6 07     AND 07
$8838: 3C        INC A
$8839: 5F        LD E,A
$883A: 57        LD D,A
$883B: 79        LD A,C
$883C: 0F        RRCA
$883D: 0F        RRCA
$883E: 0F        RRCA
$883F: E6 1F     AND 1F
$8841: 4F        LD C,A
$8842: 78        LD A,B
$8843: 87        ADD A,A
$8844: 87        ADD A,A
$8845: 87        ADD A,A
$8846: 87        ADD A,A
$8847: 87        ADD A,A
$8848: B1        OR C
$8849: 4F        LD C,A
$884A: 78        LD A,B
$884B: 0F        RRCA
$884C: 0F        RRCA
$884D: 0F        RRCA
$884E: E6 1F     AND 1F
$8850: 47        LD B,A
$8851: 2A BF D9  LD HL,(D9BF)
$8854: 09        ADD HL,BC
$8855: 7E        LD A,(HL)
$8856: 07        RLCA
$8857: 1D        DEC E
$8858: C2 56 D2  JP NZ,D256
$885B: C9        RET
$885C: D5        PUSH DE
$885D: CD 35 D2  CALL D235
$8860: E6 FE     AND FE
$8862: C1        POP BC
$8863: B1        OR C
$8864: 0F        RRCA
$8865: 15        DEC D
$8866: C2 64 D2  JP NZ,D264
$8869: 77        LD (HL),A
$886A: C9        RET
$886B: CD 5E D1  CALL D15E
$886E: 11 10 00  LD DE,0010
$8871: 19        ADD HL,DE
$8872: C5        PUSH BC
$8873: 0E 11     LD C,11
$8875: D1        POP DE
$8876: 0D        DEC C
$8877: C8        RET Z
$8878: D5        PUSH DE
$8879: 3A DD D9  LD A,(D9DD)
$887C: B7        OR A
$887D: CA 88 D2  JP Z,D288
$8880: C5        PUSH BC
$8881: E5        PUSH HL
$8882: 4E        LD C,(HL)
$8883: 06 00     LD B,00
$8885: C3 8E D2  JP D28E
$8888: 0D        DEC C
$8889: C5        PUSH BC
$888A: 4E        LD C,(HL)
$888B: 23        INC HL
$888C: 46        LD B,(HL)
$888D: E5        PUSH HL
$888E: 79        LD A,C
$888F: B0        OR B
$8890: CA 9D D2  JP Z,D29D
$8893: 2A C6 D9  LD HL,(D9C6)
$8896: 7D        LD A,L
$8897: 91        SUB C
$8898: 7C        LD A,H
$8899: 98        SBC A,B
$889A: D4 5C D2  CALL NC,D25C
$889D: E1        POP HL
$889E: 23        INC HL
$889F: C1        POP BC
$88A0: C3 75 D2  JP D275
$88A3: 2A C6 D9  LD HL,(D9C6)
$88A6: 0E 03     LD C,03
$88A8: CD EA D0  CALL D0EA
$88AB: 23        INC HL
$88AC: 44        LD B,H
$88AD: 4D        LD C,L
$88AE: 2A BF D9  LD HL,(D9BF)
$88B1: 36 00     LD (HL),00
$88B3: 23        INC HL
$88B4: 0B        DEC BC
$88B5: 78        LD A,B
$88B6: B1        OR C
$88B7: C2 B1 D2  JP NZ,D2B1
$88BA: 2A CA D9  LD HL,(D9CA)
$88BD: EB        EX DE,HL
$88BE: 2A BF D9  LD HL,(D9BF)
$88C1: 73        LD (HL),E
$88C2: 23        INC HL
$88C3: 72        LD (HL),D
$88C4: CD A1 CF  CALL CFA1
$88C7: 2A B3 D9  LD HL,(D9B3)
$88CA: 36 03     LD (HL),03
$88CC: 23        INC HL
$88CD: 36 00     LD (HL),00
$88CF: CD FE D1  CALL D1FE
$88D2: 0E FF     LD C,FF
$88D4: CD 05 D2  CALL D205
$88D7: CD F5 D1  CALL D1F5
$88DA: C8        RET Z
$88DB: CD 5E D1  CALL D15E
$88DE: 3E E5     LD A,E5
$88E0: BE        CP (HL)
$88E1: CA D2 D2  JP Z,D2D2
$88E4: 3A 41 CF  LD A,(CF41)
$88E7: BE        CP (HL)
$88E8: C2 F6 D2  JP NZ,D2F6
$88EB: 23        INC HL
$88EC: 7E        LD A,(HL)
$88ED: D6 24     SUB 24
$88EF: C2 F6 D2  JP NZ,D2F6
$88F2: 3D        DEC A
$88F3: 32 45 CF  LD (CF45),A
$88F6: 0E 01     LD C,01
$88F8: CD 6B D2  CALL D26B
$88FB: CD 8C D1  CALL D18C
$88FE: C3 D2 CA  JP CAD2
$8901: E1        POP HL
$8902: 3D        DEC A
$8903: C2 71 CB  JP NZ,CB71
$8906: CD 66 C8  CALL C866
$8909: CD 5E C6  CALL C65E
$890C: 21 F0 CB  LD HL,CBF0
$890F: E5        PUSH HL
$8910: 7E        LD A,(HL)
$8911: 32 CD CB  LD (CBCD),A
$8914: 3E 10     LD A,10
$8916: CD 60 C6  CALL C660
$8919: E1        POP HL
$891A: 7E        LD A,(HL)
$891B: 32 DD CB  LD (CBDD),A
$891E: AF        XOR A
$891F: 32 ED CB  LD (CBED),A
$8922: 11 5C 00  LD DE,005C
$8925: 21 CD CB  LD HL,CBCD
$8928: 06 21     LD B,21
$892A: CD 42 C8  CALL C842
$892D: 21 08 C4  LD HL,C408
$8930: 7E        LD A,(HL)
$8931: B7        OR A
$8932: CA 3E CB  JP Z,CB3E
$8935: FE 20     CP 20
$8937: CA 3E CB  JP Z,CB3E
$893A: 23        INC HL
$893B: C3 30 CB  JP CB30
$893E: 06 00     LD B,00
$8940: 11 81 00  LD DE,0081
$8943: 7E        LD A,(HL)
$8944: 12        LD (DE),A
$8945: B7        OR A
$8946: CA 4F CB  JP Z,CB4F
$8949: 04        INC B
$894A: 23        INC HL
$894B: 13        INC DE
$894C: C3 43 CB  JP CB43
$894F: 78        LD A,B
$8950: 32 80 00  LD (0080),A
$8953: CD 98 C4  CALL C498
$8956: CD D5 C5  CALL C5D5
$8959: CD 1A C5  CALL C51A
$895C: CD 00 01  CALL 0100
$895F: 31 AB CB  LD SP,CBAB
$8962: CD 29 C5  CALL C529
$8965: CD BD C4  CALL C4BD
$8968: C3 82 C7  JP C782
$896B: CD 66 C8  CALL C866
$896E: C3 09 C6  JP C609
$8971: 01 7A CB  LD BC,CB7A
$8974: CD A7 C4  CALL C4A7
$8977: C3 86 CB  JP CB86
$897A: 42        LD B,D
$897B: 41        LD B,C
$897C: 44        LD B,H
$897D: 20 4C     JR NZ,89CB
$897F: 4F        LD C,A
$8980: 41        LD B,C
$8981: 44        LD B,H
$8982: 00        NOP
$8983: 43        LD B,E
$8984: 4F        LD C,A
$8985: 4D        LD C,L
$8986: CD 66 C8  CALL C866
$8989: CD 5E C6  CALL C65E
$898C: 3A CE CB  LD A,(CBCE)
$898F: D6 20     SUB 20
$8991: 21 F0 CB  LD HL,CBF0
$8994: B6        OR (HL)
$8995: C2 09 C6  JP NZ,C609
$8998: C3 82 C7  JP C782
$899B: 00        NOP
$899C: 00        NOP
$899D: 00        NOP
$899E: 00        NOP
$899F: 00        NOP
$89A0: 00        NOP
$89A1: 00        NOP
$89A2: 00        NOP
$89A3: 00        NOP
$89A4: 00        NOP
$89A5: 00        NOP
$89A6: 00        NOP
$89A7: 00        NOP
$89A8: 00        NOP
$89A9: 00        NOP
$89AA: 00        NOP
$89AB: 00        NOP
$89AC: 00        NOP
$89AD: 24        INC H
$89AE: 24        INC H
$89AF: 24        INC H
$89B0: 20 20     JR NZ,89D2
$89B2: 20 20     JR NZ,89D4
$89B4: 20 53     JR NZ,8A09
$89B6: 55        LD D,L
$89B7: 42        LD B,D
$89B8: 00        NOP
$89B9: 00        NOP
$89BA: 00        NOP
$89BB: 00        NOP
$89BC: 00        NOP
$89BD: 00        NOP
$89BE: 00        NOP
$89BF: 00        NOP
$89C0: 00        NOP
$89C1: 00        NOP
$89C2: 00        NOP
$89C3: 00        NOP
$89C4: 00        NOP
$89C5: 00        NOP
$89C6: 00        NOP
$89C7: 00        NOP
$89C8: 00        NOP
$89C9: 00        NOP
$89CA: 00        NOP
$89CB: 00        NOP
$89CC: 00        NOP
$89CD: 00        NOP
$89CE: 00        NOP
$89CF: 00        NOP
$89D0: 00        NOP
$89D1: 00        NOP
$89D2: 00        NOP
$89D3: 00        NOP
$89D4: 00        NOP
$89D5: 00        NOP
$89D6: 00        NOP
$89D7: 00        NOP
$89D8: 00        NOP
$89D9: 00        NOP
$89DA: 00        NOP
$89DB: 00        NOP
$89DC: 00        NOP
$89DD: 00        NOP
$89DE: 00        NOP
$89DF: 00        NOP
$89E0: 00        NOP
$89E1: 00        NOP
$89E2: 00        NOP
$89E3: 00        NOP
$89E4: 00        NOP
$89E5: 00        NOP
$89E6: 00        NOP
$89E7: 00        NOP
$89E8: 00        NOP
$89E9: 00        NOP
$89EA: 00        NOP
$89EB: 00        NOP
$89EC: 00        NOP
$89ED: 00        NOP
$89EE: 00        NOP
$89EF: 00        NOP
$89F0: 00        NOP
$89F1: 00        NOP
$89F2: 00        NOP
$89F3: 00        NOP
$89F4: 00        NOP
$89F5: 00        NOP
$89F6: 00        NOP
$89F7: 00        NOP
$89F8: 00        NOP
$89F9: 00        NOP
$89FA: 00        NOP
$89FB: 00        NOP
$89FC: 00        NOP
$89FD: 00        NOP
$89FE: 00        NOP
$89FF: 00        NOP
$8A00: D2 3A D4  JP NC,D43A
$8A03: D9        EXX
$8A04: C3 01 CF  JP CF01
$8A07: C5        PUSH BC
$8A08: F5        PUSH AF
$8A09: 3A C5 D9  LD A,(D9C5)
$8A0C: 2F        CPL
$8A0D: 47        LD B,A
$8A0E: 79        LD A,C
$8A0F: A0        AND B
$8A10: 4F        LD C,A
$8A11: F1        POP AF
$8A12: A0        AND B
$8A13: 91        SUB C
$8A14: E6 1F     AND 1F
$8A16: C1        POP BC
$8A17: C9        RET
$8A18: 3E FF     LD A,FF
$8A1A: 32 D4 D9  LD (D9D4),A
$8A1D: 21 D8 D9  LD HL,D9D8
$8A20: 71        LD (HL),C
$8A21: 2A 43 CF  LD HL,(CF43)
$8A24: 22 D9 D9  LD (D9D9),HL
$8A27: CD FE D1  CALL D1FE
$8A2A: CD A1 CF  CALL CFA1
$8A2D: 0E 00     LD C,00
$8A2F: CD 05 D2  CALL D205
$8A32: CD F5 D1  CALL D1F5
$8A35: CA 94 D3  JP Z,D394
$8A38: 2A D9 D9  LD HL,(D9D9)
$8A3B: EB        EX DE,HL
$8A3C: 1A        LD A,(DE)
$8A3D: FE E5     CP E5
$8A3F: CA 4A D3  JP Z,D34A
$8A42: D5        PUSH DE
$8A43: CD 7F D1  CALL D17F
$8A46: D1        POP DE
$8A47: D2 94 D3  JP NC,D394
$8A4A: CD 5E D1  CALL D15E
$8A4D: 3A D8 D9  LD A,(D9D8)
$8A50: 4F        LD C,A
$8A51: 06 00     LD B,00
$8A53: 79        LD A,C
$8A54: B7        OR A
$8A55: CA 83 D3  JP Z,D383
$8A58: 1A        LD A,(DE)
$8A59: FE 3F     CP 3F
$8A5B: CA 7C D3  JP Z,D37C
$8A5E: 78        LD A,B
$8A5F: FE 0D     CP 0D
$8A61: CA 7C D3  JP Z,D37C
$8A64: FE 0C     CP 0C
$8A66: 1A        LD A,(DE)
$8A67: CA 73 D3  JP Z,D373
$8A6A: 96        SUB (HL)
$8A6B: E6 7F     AND 7F
$8A6D: C2 2D D3  JP NZ,D32D
$8A70: C3 7C D3  JP D37C
$8A73: C5        PUSH BC
$8A74: 4E        LD C,(HL)
$8A75: CD 07 D3  CALL D307
$8A78: C1        POP BC
$8A79: C2 2D D3  JP NZ,D32D
$8A7C: 13        INC DE
$8A7D: 23        INC HL
$8A7E: 04        INC B
$8A7F: 0D        DEC C
$8A80: C3 53 D3  JP D353
$8A83: 3A EA D9  LD A,(D9EA)
$8A86: E6 03     AND 03
$8A88: 32 45 CF  LD (CF45),A
$8A8B: 21 D4 D9  LD HL,D9D4
$8A8E: 7E        LD A,(HL)
$8A8F: 17        RLA
$8A90: D0        RET NC
$8A91: AF        XOR A
$8A92: 77        LD (HL),A
$8A93: C9        RET
$8A94: CD FE D1  CALL D1FE
$8A97: 3E FF     LD A,FF
$8A99: C3 01 CF  JP CF01
$8A9C: CD 54 D1  CALL D154
$8A9F: 0E 0C     LD C,0C
$8AA1: CD 18 D3  CALL D318
$8AA4: CD F5 D1  CALL D1F5
$8AA7: C8        RET Z
$8AA8: CD 44 D1  CALL D144
$8AAB: CD 5E D1  CALL D15E
$8AAE: 36 E5     LD (HL),E5
$8AB0: 0E 00     LD C,00
$8AB2: CD 6B D2  CALL D26B
$8AB5: CD C6 D1  CALL D1C6
$8AB8: CD 2D D3  CALL D32D
$8ABB: C3 A4 D3  JP D3A4
$8ABE: 50        LD D,B
$8ABF: 59        LD E,C
$8AC0: 79        LD A,C
$8AC1: B0        OR B
$8AC2: CA D1 D3  JP Z,D3D1
$8AC5: 0B        DEC BC
$8AC6: D5        PUSH DE
$8AC7: C5        PUSH BC
$8AC8: CD 35 D2  CALL D235
$8ACB: 1F        RRA
$8ACC: D2 EC D3  JP NC,D3EC
$8ACF: C1        POP BC
$8AD0: D1        POP DE
$8AD1: 2A C6 D9  LD HL,(D9C6)
$8AD4: 7B        LD A,E
$8AD5: 95        SUB L
$8AD6: 7A        LD A,D
$8AD7: 9C        SBC A,H
$8AD8: D2 F4 D3  JP NC,D3F4
$8ADB: 13        INC DE
$8ADC: C5        PUSH BC
$8ADD: D5        PUSH DE
$8ADE: 42        LD B,D
$8ADF: 4B        LD C,E
$8AE0: CD 35 D2  CALL D235
$8AE3: 1F        RRA
$8AE4: D2 EC D3  JP NC,D3EC
$8AE7: D1        POP DE
$8AE8: C1        POP BC
$8AE9: C3 C0 D3  JP D3C0
$8AEC: 17        RLA
$8AED: 3C        INC A
$8AEE: CD 64 D2  CALL D264
$8AF1: E1        POP HL
$8AF2: D1        POP DE
$8AF3: C9        RET
$8AF4: 79        LD A,C
$8AF5: B0        OR B
$8AF6: C2 C0 D3  JP NZ,D3C0
$8AF9: 21 00 00  LD HL,0000
$8AFC: C9        RET
$8AFD: 0E 00     LD C,00
$8AFF: 1E BD     LD E,BD
$8B01: 16 00     LD D,00
$8B03: 00        NOP
$8B04: 60        LD H,B
$8B05: D9        EXX
$8B06: C3 11 CC  JP CC11
$8B09: 99        SBC A,C
$8B0A: CC A5 CC  CALL Z,CCA5
$8B0D: AB        XOR E
$8B0E: CC B1 CC  CALL Z,CCB1
$8B11: EB        EX DE,HL
$8B12: 22 43 CF  LD (CF43),HL
$8B15: EB        EX DE,HL
$8B16: 7B        LD A,E
$8B17: 32 D6 D9  LD (D9D6),A
$8B1A: 21 00 00  LD HL,0000
$8B1D: 22 45 CF  LD (CF45),HL
$8B20: 39        ADD HL,SP
$8B21: 22 0F CF  LD (CF0F),HL
$8B24: 31 41 CF  LD SP,CF41
$8B27: AF        XOR A
$8B28: 32 E0 D9  LD (D9E0),A
$8B2B: 32 DE D9  LD (D9DE),A
$8B2E: 21 74 D9  LD HL,D974
$8B31: E5        PUSH HL
$8B32: 79        LD A,C
$8B33: FE 29     CP 29
$8B35: D0        RET NC
$8B36: 4B        LD C,E
$8B37: 21 47 CC  LD HL,CC47
$8B3A: 5F        LD E,A
$8B3B: 16 00     LD D,00
$8B3D: 19        ADD HL,DE
$8B3E: 19        ADD HL,DE
$8B3F: 5E        LD E,(HL)
$8B40: 23        INC HL
$8B41: 56        LD D,(HL)
$8B42: 2A 43 CF  LD HL,(CF43)
$8B45: EB        EX DE,HL
$8B46: E9        JP (HL)
$8B47: 03        INC BC
$8B48: DA C8 CE  JP C,CEC8
$8B4B: 90        SUB B
$8B4C: CD CE CE  CALL CECE
$8B4F: 12        LD (DE),A
$8B50: DA 0F DA  JP C,DA0F
$8B53: D4 CE ED  CALL NC,EDCE
$8B56: CE F3     ADC A,F3
$8B58: CE F8     ADC A,F8
$8B5A: CE E1     ADC A,E1
$8B5C: CD FE CE  CALL CEFE
$8B5F: 7E        LD A,(HL)
$8B60: D8        RET C
$8B61: 83        ADD A,E
$8B62: D8        RET C
$8B63: 45        LD B,L
$8B64: D8        RET C
$8B65: 9C        SBC A,H
$8B66: D8        RET C
$8B67: A5        AND L
$8B68: D8        RET C
$8B69: AB        XOR E
$8B6A: D8        RET C
$8B6B: C8        RET Z
$8B6C: D8        RET C
$8B6D: D7        RST $10
$8B6E: D8        RET C
$8B6F: E0        RET PO
$8B70: D8        RET C
$8B71: E6 D8     AND D8
$8B73: EC D8 F5  CALL PE,F5D8
$8B76: D8        RET C
$8B77: FE D8     CP D8
$8B79: 04        INC B
$8B7A: D9        EXX
$8B7B: 0A        LD A,(BC)
$8B7C: D9        EXX
$8B7D: 11 D9 2C  LD DE,2CD9
$8B80: D1        POP DE
$8B81: 17        RLA
$8B82: D9        EXX
$8B83: 1D        DEC E
$8B84: D9        EXX
$8B85: 26 D9     LD H,D9
$8B87: 2D        DEC L
$8B88: D9        EXX
$8B89: 41        LD B,C
$8B8A: D9        EXX
$8B8B: 47        LD B,A
$8B8C: D9        EXX
$8B8D: 4D        LD C,L
$8B8E: D9        EXX
$8B8F: 0E D8     LD C,D8
$8B91: 53        LD D,E
$8B92: D9        EXX
$8B93: 04        INC B
$8B94: CF        RST $08
$8B95: 04        INC B
$8B96: CF        RST $08
$8B97: 9B        SBC A,E
$8B98: D9        EXX
$8B99: 21 CA CC  LD HL,CCCA
$8B9C: CD E5 CC  CALL CCE5
$8B9F: FE 03     CP 03
$8BA1: CA 00 00  JP Z,0000
$8BA4: C9        RET
$8BA5: 21 D5 CC  LD HL,CCD5
$8BA8: C3 B4 CC  JP CCB4
$8BAB: 21 E1 CC  LD HL,CCE1
$8BAE: C3 B4 CC  JP CCB4
$8BB1: 21 DC CC  LD HL,CCDC
$8BB4: CD E5 CC  CALL CCE5
$8BB7: C3 00 00  JP 0000
$8BBA: 42        LD B,D
$8BBB: 64        LD H,H
$8BBC: 6F        LD L,A
$8BBD: 73        LD (HL),E
$8BBE: 20 45     JR NZ,8C05
$8BC0: 72        LD (HL),D
$8BC1: 72        LD (HL),D
$8BC2: 20 4F     JR NZ,8C13
$8BC4: 6E        LD L,(HL)
$8BC5: 20 20     JR NZ,8BE7
$8BC7: 3A 20 24  LD A,(2420)
$8BCA: 42        LD B,D
$8BCB: 61        LD H,C
$8BCC: 64        LD H,H
$8BCD: 20 53     JR NZ,8C22
$8BCF: 65        LD H,L
$8BD0: 63        LD H,E
$8BD1: 74        LD (HL),H
$8BD2: 6F        LD L,A
$8BD3: 72        LD (HL),D
$8BD4: 24        INC H
$8BD5: 53        LD D,E
$8BD6: 65        LD H,L
$8BD7: 6C        LD L,H
$8BD8: 65        LD H,L
$8BD9: 63        LD H,E
$8BDA: 74        LD (HL),H
$8BDB: 24        INC H
$8BDC: 46        LD B,(HL)
$8BDD: 69        LD L,C
$8BDE: 6C        LD L,H
$8BDF: 65        LD H,L
$8BE0: 20 52     JR NZ,8C34
$8BE2: 2F        CPL
$8BE3: 4F        LD C,A
$8BE4: 24        INC H
$8BE5: E5        PUSH HL
$8BE6: CD C9 CD  CALL CDC9
$8BE9: 3A 42 CF  LD A,(CF42)
$8BEC: C6 41     ADD A,41
$8BEE: 32 C6 CC  LD (CCC6),A
$8BF1: 01 BA CC  LD BC,CCBA
$8BF4: CD D3 CD  CALL CDD3
$8BF7: C1        POP BC
$8BF8: CD D3 CD  CALL CDD3
$8BFB: 21 0E CF  LD HL,CF0E
$8BFE: 7E        LD A,(HL)
$8BFF: 36 20     LD (HL),20
$8C01: D5        PUSH DE
$8C02: 06 00     LD B,00
$8C04: 2A 43 CF  LD HL,(CF43)
$8C07: 09        ADD HL,BC
$8C08: EB        EX DE,HL
$8C09: CD 5E D1  CALL D15E
$8C0C: C1        POP BC
$8C0D: CD 4F CF  CALL CF4F
$8C10: CD C3 CF  CALL CFC3
$8C13: C3 C6 D1  JP D1C6
$8C16: CD 54 D1  CALL D154
$8C19: 0E 0C     LD C,0C
$8C1B: CD 18 D3  CALL D318
$8C1E: 2A 43 CF  LD HL,(CF43)
$8C21: 7E        LD A,(HL)
$8C22: 11 10 00  LD DE,0010
$8C25: 19        ADD HL,DE
$8C26: 77        LD (HL),A
$8C27: CD F5 D1  CALL D1F5
$8C2A: C8        RET Z
$8C2B: CD 44 D1  CALL D144
$8C2E: 0E 10     LD C,10
$8C30: 1E 0C     LD E,0C
$8C32: CD 01 D4  CALL D401
$8C35: CD 2D D3  CALL D32D
$8C38: C3 27 D4  JP D427
$8C3B: 0E 0C     LD C,0C
$8C3D: CD 18 D3  CALL D318
$8C40: CD F5 D1  CALL D1F5
$8C43: C8        RET Z
$8C44: 0E 00     LD C,00
$8C46: 1E 0C     LD E,0C
$8C48: CD 01 D4  CALL D401
$8C4B: CD 2D D3  CALL D32D
$8C4E: C3 40 D4  JP D440
$8C51: 0E 0F     LD C,0F
$8C53: CD 18 D3  CALL D318
$8C56: CD F5 D1  CALL D1F5
$8C59: C8        RET Z
$8C5A: CD A6 D0  CALL D0A6
$8C5D: 7E        LD A,(HL)
$8C5E: F5        PUSH AF
$8C5F: E5        PUSH HL
$8C60: CD 5E D1  CALL D15E
$8C63: EB        EX DE,HL
$8C64: 2A 43 CF  LD HL,(CF43)
$8C67: 0E 20     LD C,20
$8C69: D5        PUSH DE
$8C6A: CD 4F CF  CALL CF4F
$8C6D: CD 78 D1  CALL D178
$8C70: D1        POP DE
$8C71: 21 0C 00  LD HL,000C
$8C74: 19        ADD HL,DE
$8C75: 4E        LD C,(HL)
$8C76: 21 0F 00  LD HL,000F
$8C79: 19        ADD HL,DE
$8C7A: 46        LD B,(HL)
$8C7B: E1        POP HL
$8C7C: F1        POP AF
$8C7D: 77        LD (HL),A
$8C7E: 79        LD A,C
$8C7F: BE        CP (HL)
$8C80: 78        LD A,B
$8C81: CA 8B D4  JP Z,D48B
$8C84: 3E 00     LD A,00
$8C86: DA 8B D4  JP C,D48B
$8C89: 3E 80     LD A,80
$8C8B: 2A 43 CF  LD HL,(CF43)
$8C8E: 11 0F 00  LD DE,000F
$8C91: 19        ADD HL,DE
$8C92: 77        LD (HL),A
$8C93: C9        RET
$8C94: 7E        LD A,(HL)
$8C95: 23        INC HL
$8C96: B6        OR (HL)
$8C97: 2B        DEC HL
$8C98: C0        RET NZ
$8C99: 1A        LD A,(DE)
$8C9A: 77        LD (HL),A
$8C9B: 13        INC DE
$8C9C: 23        INC HL
$8C9D: 1A        LD A,(DE)
$8C9E: 77        LD (HL),A
$8C9F: 1B        DEC DE
$8CA0: 2B        DEC HL
$8CA1: C9        RET
$8CA2: AF        XOR A
$8CA3: 32 45 CF  LD (CF45),A
$8CA6: 32 EA D9  LD (D9EA),A
$8CA9: 32 EB D9  LD (D9EB),A
$8CAC: CD 1E D1  CALL D11E
$8CAF: C0        RET NZ
$8CB0: CD 69 D1  CALL D169
$8CB3: E6 80     AND 80
$8CB5: C0        RET NZ
$8CB6: 0E 0F     LD C,0F
$8CB8: CD 18 D3  CALL D318
$8CBB: CD F5 D1  CALL D1F5
$8CBE: C8        RET Z
$8CBF: 01 10 00  LD BC,0010
$8CC2: CD 5E D1  CALL D15E
$8CC5: 09        ADD HL,BC
$8CC6: EB        EX DE,HL
$8CC7: 2A 43 CF  LD HL,(CF43)
$8CCA: 09        ADD HL,BC
$8CCB: 0E 10     LD C,10
$8CCD: 3A DD D9  LD A,(D9DD)
$8CD0: B7        OR A
$8CD1: CA E8 D4  JP Z,D4E8
$8CD4: 7E        LD A,(HL)
$8CD5: B7        OR A
$8CD6: 1A        LD A,(DE)
$8CD7: C2 DB D4  JP NZ,D4DB
$8CDA: 77        LD (HL),A
$8CDB: B7        OR A
$8CDC: C2 E1 D4  JP NZ,D4E1
$8CDF: 7E        LD A,(HL)
$8CE0: 12        LD (DE),A
$8CE1: BE        CP (HL)
$8CE2: C2 1F D5  JP NZ,D51F
$8CE5: C3 FD D4  JP D4FD
$8CE8: CD 94 D4  CALL D494
$8CEB: EB        EX DE,HL
$8CEC: CD 94 D4  CALL D494
$8CEF: EB        EX DE,HL
$8CF0: 1A        LD A,(DE)
$8CF1: BE        CP (HL)
$8CF2: C2 1F D5  JP NZ,D51F
$8CF5: 13        INC DE
$8CF6: 23        INC HL
$8CF7: 1A        LD A,(DE)
$8CF8: BE        CP (HL)
$8CF9: C2 1F D5  JP NZ,D51F
$8CFC: 0D        DEC C
$8CFD: 13        INC DE
$8CFE: 23        INC HL
$8CFF: 0D        DEC C
$8D00: 00        NOP
$8D01: B7        OR A
$8D02: C0        RET NZ
$8D03: C3 09 DA  JP DA09
$8D06: CD FB CC  CALL CCFB
$8D09: CD 14 CD  CALL CD14
$8D0C: D8        RET C
$8D0D: F5        PUSH AF
$8D0E: 4F        LD C,A
$8D0F: CD 90 CD  CALL CD90
$8D12: F1        POP AF
$8D13: C9        RET
$8D14: FE 0D     CP 0D
$8D16: C8        RET Z
$8D17: FE 0A     CP 0A
$8D19: C8        RET Z
$8D1A: FE 09     CP 09
$8D1C: C8        RET Z
$8D1D: FE 08     CP 08
$8D1F: C8        RET Z
$8D20: FE 20     CP 20
$8D22: C9        RET
$8D23: 3A 0E CF  LD A,(CF0E)
$8D26: B7        OR A
$8D27: C2 45 CD  JP NZ,CD45
$8D2A: CD 06 DA  CALL DA06
$8D2D: E6 01     AND 01
$8D2F: C8        RET Z
$8D30: CD 09 DA  CALL DA09
$8D33: FE 13     CP 13
$8D35: C2 42 CD  JP NZ,CD42
$8D38: CD 09 DA  CALL DA09
$8D3B: FE 03     CP 03
$8D3D: CA 00 00  JP Z,0000
$8D40: AF        XOR A
$8D41: C9        RET
$8D42: 32 0E CF  LD (CF0E),A
$8D45: 3E 01     LD A,01
$8D47: C9        RET
$8D48: 3A 0A CF  LD A,(CF0A)
$8D4B: B7        OR A
$8D4C: C2 62 CD  JP NZ,CD62
$8D4F: C5        PUSH BC
$8D50: CD 23 CD  CALL CD23
$8D53: C1        POP BC
$8D54: C5        PUSH BC
$8D55: CD 0C DA  CALL DA0C
$8D58: C1        POP BC
$8D59: C5        PUSH BC
$8D5A: 3A 0D CF  LD A,(CF0D)
$8D5D: B7        OR A
$8D5E: C4 0F DA  CALL NZ,DA0F
$8D61: C1        POP BC
$8D62: 79        LD A,C
$8D63: 21 0C CF  LD HL,CF0C
$8D66: FE 7F     CP 7F
$8D68: C8        RET Z
$8D69: 34        INC (HL)
$8D6A: FE 20     CP 20
$8D6C: D0        RET NC
$8D6D: 35        DEC (HL)
$8D6E: 7E        LD A,(HL)
$8D6F: B7        OR A
$8D70: C8        RET Z
$8D71: 79        LD A,C
$8D72: FE 08     CP 08
$8D74: C2 79 CD  JP NZ,CD79
$8D77: 35        DEC (HL)
$8D78: C9        RET
$8D79: FE 0A     CP 0A
$8D7B: C0        RET NZ
$8D7C: 36 00     LD (HL),00
$8D7E: C9        RET
$8D7F: 79        LD A,C
$8D80: CD 14 CD  CALL CD14
$8D83: D2 90 CD  JP NC,CD90
$8D86: F5        PUSH AF
$8D87: 0E 5E     LD C,5E
$8D89: CD 48 CD  CALL CD48
$8D8C: F1        POP AF
$8D8D: F6 40     OR 40
$8D8F: 4F        LD C,A
$8D90: 79        LD A,C
$8D91: FE 09     CP 09
$8D93: C2 48 CD  JP NZ,CD48
$8D96: 0E 20     LD C,20
$8D98: CD 48 CD  CALL CD48
$8D9B: 3A 0C CF  LD A,(CF0C)
$8D9E: E6 07     AND 07
$8DA0: C2 96 CD  JP NZ,CD96
$8DA3: C9        RET
$8DA4: CD AC CD  CALL CDAC
$8DA7: 0E 20     LD C,20
$8DA9: CD 0C DA  CALL DA0C
$8DAC: 0E 08     LD C,08
$8DAE: C3 0C DA  JP DA0C
$8DB1: 0E 23     LD C,23
$8DB3: CD 48 CD  CALL CD48
$8DB6: CD C9 CD  CALL CDC9
$8DB9: 3A 0C CF  LD A,(CF0C)
$8DBC: 21 0B CF  LD HL,CF0B
$8DBF: BE        CP (HL)
$8DC0: D0        RET NC
$8DC1: 0E 20     LD C,20
$8DC3: CD 48 CD  CALL CD48
$8DC6: C3 B9 CD  JP CDB9
$8DC9: 0E 0D     LD C,0D
$8DCB: CD 48 CD  CALL CD48
$8DCE: 0E 0A     LD C,0A
$8DD0: C3 48 CD  JP CD48
$8DD3: 0A        LD A,(BC)
$8DD4: FE 24     CP 24
$8DD6: C8        RET Z
$8DD7: 03        INC BC
$8DD8: C5        PUSH BC
$8DD9: 4F        LD C,A
$8DDA: CD 90 CD  CALL CD90
$8DDD: C1        POP BC
$8DDE: C3 D3 CD  JP CDD3
$8DE1: 3A 0C CF  LD A,(CF0C)
$8DE4: 32 0B CF  LD (CF0B),A
$8DE7: 2A 43 CF  LD HL,(CF43)
$8DEA: 4E        LD C,(HL)
$8DEB: 23        INC HL
$8DEC: E5        PUSH HL
$8DED: 06 00     LD B,00
$8DEF: C5        PUSH BC
$8DF0: E5        PUSH HL
$8DF1: CD FB CC  CALL CCFB
$8DF4: E6 7F     AND 7F
$8DF6: E1        POP HL
$8DF7: C1        POP BC
$8DF8: FE 0D     CP 0D
$8DFA: CA C1 CE  JP Z,CEC1
$8DFD: FE 0A     CP 0A
$8DFF: CA C2 CD  JP Z,CDC2
$8E02: D4 01 EC  CALL NC,EC01
$8E05: FF        RST $38
$8E06: 09        ADD HL,BC
$8E07: EB        EX DE,HL
$8E08: 09        ADD HL,BC
$8E09: 1A        LD A,(DE)
$8E0A: BE        CP (HL)
$8E0B: DA 17 D5  JP C,D517
$8E0E: 77        LD (HL),A
$8E0F: 01 03 00  LD BC,0003
$8E12: 09        ADD HL,BC
$8E13: EB        EX DE,HL
$8E14: 09        ADD HL,BC
$8E15: 7E        LD A,(HL)
$8E16: 12        LD (DE),A
$8E17: 3E FF     LD A,FF
$8E19: 32 D2 D9  LD (D9D2),A
$8E1C: C3 10 D4  JP D410
$8E1F: 21 45 CF  LD HL,CF45
$8E22: 35        DEC (HL)
$8E23: C9        RET
$8E24: CD 54 D1  CALL D154
$8E27: 2A 43 CF  LD HL,(CF43)
$8E2A: E5        PUSH HL
$8E2B: 21 AC D9  LD HL,D9AC
$8E2E: 22 43 CF  LD (CF43),HL
$8E31: 0E 01     LD C,01
$8E33: CD 18 D3  CALL D318
$8E36: CD F5 D1  CALL D1F5
$8E39: E1        POP HL
$8E3A: 22 43 CF  LD (CF43),HL
$8E3D: C8        RET Z
$8E3E: EB        EX DE,HL
$8E3F: 21 0F 00  LD HL,000F
$8E42: 19        ADD HL,DE
$8E43: 0E 11     LD C,11
$8E45: AF        XOR A
$8E46: 77        LD (HL),A
$8E47: 23        INC HL
$8E48: 0D        DEC C
$8E49: C2 46 D5  JP NZ,D546
$8E4C: 21 0D 00  LD HL,000D
$8E4F: 19        ADD HL,DE
$8E50: 77        LD (HL),A
$8E51: CD 8C D1  CALL D18C
$8E54: CD FD D3  CALL D3FD
$8E57: C3 78 D1  JP D178
$8E5A: AF        XOR A
$8E5B: 32 D2 D9  LD (D9D2),A
$8E5E: CD A2 D4  CALL D4A2
$8E61: CD F5 D1  CALL D1F5
$8E64: C8        RET Z
$8E65: 2A 43 CF  LD HL,(CF43)
$8E68: 01 0C 00  LD BC,000C
$8E6B: 09        ADD HL,BC
$8E6C: 7E        LD A,(HL)
$8E6D: 3C        INC A
$8E6E: E6 1F     AND 1F
$8E70: 77        LD (HL),A
$8E71: CA 83 D5  JP Z,D583
$8E74: 47        LD B,A
$8E75: 3A C5 D9  LD A,(D9C5)
$8E78: A0        AND B
$8E79: 21 D2 D9  LD HL,D9D2
$8E7C: A6        AND (HL)
$8E7D: CA 8E D5  JP Z,D58E
$8E80: C3 AC D5  JP D5AC
$8E83: 01 02 00  LD BC,0002
$8E86: 09        ADD HL,BC
$8E87: 34        INC (HL)
$8E88: 7E        LD A,(HL)
$8E89: E6 0F     AND 0F
$8E8B: CA B6 D5  JP Z,D5B6
$8E8E: 0E 0F     LD C,0F
$8E90: CD 18 D3  CALL D318
$8E93: CD F5 D1  CALL D1F5
$8E96: C2 AC D5  JP NZ,D5AC
$8E99: 3A D3 D9  LD A,(D9D3)
$8E9C: 3C        INC A
$8E9D: CA B6 D5  JP Z,D5B6
$8EA0: CD 24 D5  CALL D524
$8EA3: CD F5 D1  CALL D1F5
$8EA6: CA B6 D5  JP Z,D5B6
$8EA9: C3 AF D5  JP D5AF
$8EAC: CD 5A D4  CALL D45A
$8EAF: CD BB D0  CALL D0BB
$8EB2: AF        XOR A
$8EB3: C3 01 CF  JP CF01
$8EB6: CD 05 CF  CALL CF05
$8EB9: C3 78 D1  JP D178
$8EBC: 3E 01     LD A,01
$8EBE: 32 D5 D9  LD (D9D5),A
$8EC1: 3E FF     LD A,FF
$8EC3: 32 D3 D9  LD (D9D3),A
$8EC6: CD BB D0  CALL D0BB
$8EC9: 3A E3 D9  LD A,(D9E3)
$8ECC: 21 E1 D9  LD HL,D9E1
$8ECF: BE        CP (HL)
$8ED0: DA E6 D5  JP C,D5E6
$8ED3: FE 80     CP 80
$8ED5: C2 FB D5  JP NZ,D5FB
$8ED8: CD 5A D5  CALL D55A
$8EDB: AF        XOR A
$8EDC: 32 E3 D9  LD (D9E3),A
$8EDF: 3A 45 CF  LD A,(CF45)
$8EE2: B7        OR A
$8EE3: C2 FB D5  JP NZ,D5FB
$8EE6: CD 77 D0  CALL D077
$8EE9: CD 84 D0  CALL D084
$8EEC: CA FB D5  JP Z,D5FB
$8EEF: CD 8A D0  CALL D08A
$8EF2: CD D1 CF  CALL CFD1
$8EF5: CD B2 CF  CALL CFB2
$8EF8: C3 D2 D0  JP D0D2
$8EFB: C3 05 CF  JP CF05
$8EFE: 3E 01     LD A,01
$8F00: C1        POP BC
$8F01: CE FE     ADC A,FE
$8F03: 08        EX AF,AF'
$8F04: C2 16 CE  JP NZ,CE16
$8F07: 78        LD A,B
$8F08: B7        OR A
$8F09: CA EF CD  JP Z,CDEF
$8F0C: 05        DEC B
$8F0D: 3A 0C CF  LD A,(CF0C)
$8F10: 32 0A CF  LD (CF0A),A
$8F13: C3 70 CE  JP CE70
$8F16: FE 7F     CP 7F
$8F18: C2 26 CE  JP NZ,CE26
$8F1B: 78        LD A,B
$8F1C: B7        OR A
$8F1D: CA EF CD  JP Z,CDEF
$8F20: 7E        LD A,(HL)
$8F21: 05        DEC B
$8F22: 2B        DEC HL
$8F23: C3 A9 CE  JP CEA9
$8F26: FE 05     CP 05
$8F28: C2 37 CE  JP NZ,CE37
$8F2B: C5        PUSH BC
$8F2C: E5        PUSH HL
$8F2D: CD C9 CD  CALL CDC9
$8F30: AF        XOR A
$8F31: 32 0B CF  LD (CF0B),A
$8F34: C3 F1 CD  JP CDF1
$8F37: FE 10     CP 10
$8F39: C2 48 CE  JP NZ,CE48
$8F3C: E5        PUSH HL
$8F3D: 21 0D CF  LD HL,CF0D
$8F40: 3E 01     LD A,01
$8F42: 96        SUB (HL)
$8F43: 77        LD (HL),A
$8F44: E1        POP HL
$8F45: C3 EF CD  JP CDEF
$8F48: FE 18     CP 18
$8F4A: C2 5F CE  JP NZ,CE5F
$8F4D: E1        POP HL
$8F4E: 3A 0B CF  LD A,(CF0B)
$8F51: 21 0C CF  LD HL,CF0C
$8F54: BE        CP (HL)
$8F55: D2 E1 CD  JP NC,CDE1
$8F58: 35        DEC (HL)
$8F59: CD A4 CD  CALL CDA4
$8F5C: C3 4E CE  JP CE4E
$8F5F: FE 15     CP 15
$8F61: C2 6B CE  JP NZ,CE6B
$8F64: CD B1 CD  CALL CDB1
$8F67: E1        POP HL
$8F68: C3 E1 CD  JP CDE1
$8F6B: FE 12     CP 12
$8F6D: C2 A6 CE  JP NZ,CEA6
$8F70: C5        PUSH BC
$8F71: CD B1 CD  CALL CDB1
$8F74: C1        POP BC
$8F75: E1        POP HL
$8F76: E5        PUSH HL
$8F77: C5        PUSH BC
$8F78: 78        LD A,B
$8F79: B7        OR A
$8F7A: CA 8A CE  JP Z,CE8A
$8F7D: 23        INC HL
$8F7E: 4E        LD C,(HL)
$8F7F: 05        DEC B
$8F80: C5        PUSH BC
$8F81: E5        PUSH HL
$8F82: CD 7F CD  CALL CD7F
$8F85: E1        POP HL
$8F86: C1        POP BC
$8F87: C3 78 CE  JP CE78
$8F8A: E5        PUSH HL
$8F8B: 3A 0A CF  LD A,(CF0A)
$8F8E: B7        OR A
$8F8F: CA F1 CD  JP Z,CDF1
$8F92: 21 0C CF  LD HL,CF0C
$8F95: 96        SUB (HL)
$8F96: 32 0A CF  LD (CF0A),A
$8F99: CD A4 CD  CALL CDA4
$8F9C: 21 0A CF  LD HL,CF0A
$8F9F: 35        DEC (HL)
$8FA0: C2 99 CE  JP NZ,CE99
$8FA3: C3 F1 CD  JP CDF1
$8FA6: 23        INC HL
$8FA7: 77        LD (HL),A
$8FA8: 04        INC B
$8FA9: C5        PUSH BC
$8FAA: E5        PUSH HL
$8FAB: 4F        LD C,A
$8FAC: CD 7F CD  CALL CD7F
$8FAF: E1        POP HL
$8FB0: C1        POP BC
$8FB1: 7E        LD A,(HL)
$8FB2: FE 03     CP 03
$8FB4: 78        LD A,B
$8FB5: C2 BD CE  JP NZ,CEBD
$8FB8: FE 01     CP 01
$8FBA: CA 00 00  JP Z,0000
$8FBD: B9        CP C
$8FBE: DA EF CD  JP C,CDEF
$8FC1: E1        POP HL
$8FC2: 70        LD (HL),B
$8FC3: 0E 0D     LD C,0D
$8FC5: C3 48 CD  JP CD48
$8FC8: CD 06 CD  CALL CD06
$8FCB: C3 01 CF  JP CF01
$8FCE: CD 15 DA  CALL DA15
$8FD1: C3 01 CF  JP CF01
$8FD4: 79        LD A,C
$8FD5: 3C        INC A
$8FD6: CA E0 CE  JP Z,CEE0
$8FD9: 3C        INC A
$8FDA: CA 06 DA  JP Z,DA06
$8FDD: C3 0C DA  JP DA0C
$8FE0: CD 06 DA  CALL DA06
$8FE3: B7        OR A
$8FE4: CA 91 D9  JP Z,D991
$8FE7: CD 09 DA  CALL DA09
$8FEA: C3 01 CF  JP CF01
$8FED: 3A 03 00  LD A,(0003)
$8FF0: C3 01 CF  JP CF01
$8FF3: 21 03 00  LD HL,0003
$8FF6: 71        LD (HL),C
$8FF7: C9        RET
$8FF8: EB        EX DE,HL
$8FF9: 4D        LD C,L
$8FFA: 44        LD B,H
$8FFB: C3 D3 CD  JP CDD3
$8FFE: CD 23 32  CALL 3223
$9001: D5        PUSH DE
$9002: D9        EXX
$9003: 3E 00     LD A,00
$9005: 32 D3 D9  LD (D9D3),A
$9008: CD 54 D1  CALL D154
$900B: 2A 43 CF  LD HL,(CF43)
$900E: CD 47 D1  CALL D147
$9011: CD BB D0  CALL D0BB
$9014: 3A E3 D9  LD A,(D9E3)
$9017: FE 80     CP 80
$9019: D2 05 CF  JP NC,CF05
$901C: CD 77 D0  CALL D077
$901F: CD 84 D0  CALL D084
$9022: 0E 00     LD C,00
$9024: C2 6E D6  JP NZ,D66E
$9027: CD 3E D0  CALL D03E
$902A: 32 D7 D9  LD (D9D7),A
$902D: 01 00 00  LD BC,0000
$9030: B7        OR A
$9031: CA 3B D6  JP Z,D63B
$9034: 4F        LD C,A
$9035: 0B        DEC BC
$9036: CD 5E D0  CALL D05E
$9039: 44        LD B,H
$903A: 4D        LD C,L
$903B: CD BE D3  CALL D3BE
$903E: 7D        LD A,L
$903F: B4        OR H
$9040: C2 48 D6  JP NZ,D648
$9043: 3E 02     LD A,02
$9045: C3 01 CF  JP CF01
$9048: 22 E5 D9  LD (D9E5),HL
$904B: EB        EX DE,HL
$904C: 2A 43 CF  LD HL,(CF43)
$904F: 01 10 00  LD BC,0010
$9052: 09        ADD HL,BC
$9053: 3A DD D9  LD A,(D9DD)
$9056: B7        OR A
$9057: 3A D7 D9  LD A,(D9D7)
$905A: CA 64 D6  JP Z,D664
$905D: CD 64 D1  CALL D164
$9060: 73        LD (HL),E
$9061: C3 6C D6  JP D66C
$9064: 4F        LD C,A
$9065: 06 00     LD B,00
$9067: 09        ADD HL,BC
$9068: 09        ADD HL,BC
$9069: 73        LD (HL),E
$906A: 23        INC HL
$906B: 72        LD (HL),D
$906C: 0E 02     LD C,02
$906E: 3A 45 CF  LD A,(CF45)
$9071: B7        OR A
$9072: C0        RET NZ
$9073: C5        PUSH BC
$9074: CD 8A D0  CALL D08A
$9077: 3A D5 D9  LD A,(D9D5)
$907A: 3D        DEC A
$907B: 3D        DEC A
$907C: C2 BB D6  JP NZ,D6BB
$907F: C1        POP BC
$9080: C5        PUSH BC
$9081: 79        LD A,C
$9082: 3D        DEC A
$9083: 3D        DEC A
$9084: C2 BB D6  JP NZ,D6BB
$9087: E5        PUSH HL
$9088: 2A B9 D9  LD HL,(D9B9)
$908B: 57        LD D,A
$908C: 77        LD (HL),A
$908D: 23        INC HL
$908E: 14        INC D
$908F: F2 8C D6  JP P,D68C
$9092: CD E0 D1  CALL D1E0
$9095: 2A E7 D9  LD HL,(D9E7)
$9098: 0E 02     LD C,02
$909A: 22 E5 D9  LD (D9E5),HL
$909D: C5        PUSH BC
$909E: CD D1 CF  CALL CFD1
$90A1: C1        POP BC
$90A2: CD B8 CF  CALL CFB8
$90A5: 2A E5 D9  LD HL,(D9E5)
$90A8: 0E 00     LD C,00
$90AA: 3A C4 D9  LD A,(D9C4)
$90AD: 47        LD B,A
$90AE: A5        AND L
$90AF: B8        CP B
$90B0: 23        INC HL
$90B1: C2 9A D6  JP NZ,D69A
$90B4: E1        POP HL
$90B5: 22 E5 D9  LD (D9E5),HL
$90B8: CD DA D1  CALL D1DA
$90BB: CD D1 CF  CALL CFD1
$90BE: C1        POP BC
$90BF: C5        PUSH BC
$90C0: CD B8 CF  CALL CFB8
$90C3: C1        POP BC
$90C4: 3A E3 D9  LD A,(D9E3)
$90C7: 21 E1 D9  LD HL,D9E1
$90CA: BE        CP (HL)
$90CB: DA D2 D6  JP C,D6D2
$90CE: 77        LD (HL),A
$90CF: 34        INC (HL)
$90D0: 0E 02     LD C,02
$90D2: 00        NOP
$90D3: 00        NOP
$90D4: 21 DF D6  LD HL,D6DF
$90D7: F5        PUSH AF
$90D8: CD 69 D1  CALL D169
$90DB: E6 7F     AND 7F
$90DD: 77        LD (HL),A
$90DE: F1        POP AF
$90DF: FE 7F     CP 7F
$90E1: C2 00 D7  JP NZ,D700
$90E4: 3A D5 D9  LD A,(D9D5)
$90E7: FE 01     CP 01
$90E9: C2 00 D7  JP NZ,D700
$90EC: CD D2 D0  CALL D0D2
$90EF: CD 5A D5  CALL D55A
$90F2: 21 45 CF  LD HL,CF45
$90F5: 7E        LD A,(HL)
$90F6: B7        OR A
$90F7: C2 FE D6  JP NZ,D6FE
$90FA: 3D        DEC A
$90FB: 32 E3 D9  LD (D9E3),A
$90FE: 36 00     LD (HL),00
$9100: CD 32 45  CALL 4532
$9103: CF        RST $08
$9104: C9        RET
$9105: 3E 01     LD A,01
$9107: C3 01 CF  JP CF01
$910A: 00        NOP
$910B: 00        NOP
$910C: 00        NOP
$910D: 00        NOP
$910E: 00        NOP
$910F: 00        NOP
$9110: 00        NOP
$9111: 00        NOP
$9112: 00        NOP
$9113: 00        NOP
$9114: 00        NOP
$9115: 00        NOP
$9116: 00        NOP
$9117: 00        NOP
$9118: 00        NOP
$9119: 00        NOP
$911A: 00        NOP
$911B: 00        NOP
$911C: 00        NOP
$911D: 00        NOP
$911E: 00        NOP
$911F: 00        NOP
$9120: 00        NOP
$9121: 00        NOP
$9122: 00        NOP
$9123: 00        NOP
$9124: 00        NOP
$9125: 00        NOP
$9126: 00        NOP
$9127: 00        NOP
$9128: 00        NOP
$9129: 00        NOP
$912A: 00        NOP
$912B: 00        NOP
$912C: 00        NOP
$912D: 00        NOP
$912E: 00        NOP
$912F: 00        NOP
$9130: 00        NOP
$9131: 00        NOP
$9132: 00        NOP
$9133: 00        NOP
$9134: 00        NOP
$9135: 00        NOP
$9136: 00        NOP
$9137: 00        NOP
$9138: 00        NOP
$9139: 00        NOP
$913A: 00        NOP
$913B: 00        NOP
$913C: 00        NOP
$913D: 00        NOP
$913E: 00        NOP
$913F: 00        NOP
$9140: 00        NOP
$9141: 00        NOP
$9142: 00        NOP
$9143: 00        NOP
$9144: 00        NOP
$9145: 00        NOP
$9146: 00        NOP
$9147: 21 0B CC  LD HL,CC0B
$914A: 5E        LD E,(HL)
$914B: 23        INC HL
$914C: 56        LD D,(HL)
$914D: EB        EX DE,HL
$914E: E9        JP (HL)
$914F: 0C        INC C
$9150: 0D        DEC C
$9151: C8        RET Z
$9152: 1A        LD A,(DE)
$9153: 77        LD (HL),A
$9154: 13        INC DE
$9155: 23        INC HL
$9156: C3 50 CF  JP CF50
$9159: 3A 42 CF  LD A,(CF42)
$915C: 4F        LD C,A
$915D: CD 1B DA  CALL DA1B
$9160: 7C        LD A,H
$9161: B5        OR L
$9162: C8        RET Z
$9163: 5E        LD E,(HL)
$9164: 23        INC HL
$9165: 56        LD D,(HL)
$9166: 23        INC HL
$9167: 22 B3 D9  LD (D9B3),HL
$916A: 23        INC HL
$916B: 23        INC HL
$916C: 22 B5 D9  LD (D9B5),HL
$916F: 23        INC HL
$9170: 23        INC HL
$9171: 22 B7 D9  LD (D9B7),HL
$9174: 23        INC HL
$9175: 23        INC HL
$9176: EB        EX DE,HL
$9177: 22 D0 D9  LD (D9D0),HL
$917A: 21 B9 D9  LD HL,D9B9
$917D: 0E 08     LD C,08
$917F: CD 4F CF  CALL CF4F
$9182: 2A BB D9  LD HL,(D9BB)
$9185: EB        EX DE,HL
$9186: 21 C1 D9  LD HL,D9C1
$9189: 0E 0F     LD C,0F
$918B: CD 4F CF  CALL CF4F
$918E: 2A C6 D9  LD HL,(D9C6)
$9191: 7C        LD A,H
$9192: 21 DD D9  LD HL,D9DD
$9195: 36 FF     LD (HL),FF
$9197: B7        OR A
$9198: CA 9D CF  JP Z,CF9D
$919B: 36 00     LD (HL),00
$919D: 3E FF     LD A,FF
$919F: B7        OR A
$91A0: C9        RET
$91A1: CD 18 DA  CALL DA18
$91A4: AF        XOR A
$91A5: 2A B5 D9  LD HL,(D9B5)
$91A8: 77        LD (HL),A
$91A9: 23        INC HL
$91AA: 77        LD (HL),A
$91AB: 2A B7 D9  LD HL,(D9B7)
$91AE: 77        LD (HL),A
$91AF: 23        INC HL
$91B0: 77        LD (HL),A
$91B1: C9        RET
$91B2: CD 27 DA  CALL DA27
$91B5: C3 BB CF  JP CFBB
$91B8: CD 2A DA  CALL DA2A
$91BB: B7        OR A
$91BC: C8        RET Z
$91BD: 21 09 CC  LD HL,CC09
$91C0: C3 4A CF  JP CF4A
$91C3: 2A EA D9  LD HL,(D9EA)
$91C6: 0E 02     LD C,02
$91C8: CD EA D0  CALL D0EA
$91CB: 22 E5 D9  LD (D9E5),HL
$91CE: 22 EC D9  LD (D9EC),HL
$91D1: 21 E5 D9  LD HL,D9E5
$91D4: 4E        LD C,(HL)
$91D5: 23        INC HL
$91D6: 46        LD B,(HL)
$91D7: 2A B7 D9  LD HL,(D9B7)
$91DA: 5E        LD E,(HL)
$91DB: 23        INC HL
$91DC: 56        LD D,(HL)
$91DD: 2A B5 D9  LD HL,(D9B5)
$91E0: 7E        LD A,(HL)
$91E1: 23        INC HL
$91E2: 66        LD H,(HL)
$91E3: 6F        LD L,A
$91E4: 79        LD A,C
$91E5: 93        SUB E
$91E6: 78        LD A,B
$91E7: 9A        SBC A,D
$91E8: D2 FA CF  JP NC,CFFA
$91EB: E5        PUSH HL
$91EC: 2A C1 D9  LD HL,(D9C1)
$91EF: 7B        LD A,E
$91F0: 95        SUB L
$91F1: 5F        LD E,A
$91F2: 7A        LD A,D
$91F3: 9C        SBC A,H
$91F4: 57        LD D,A
$91F5: E1        POP HL
$91F6: 2B        DEC HL
$91F7: C3 E4 CF  JP CFE4
$91FA: E5        PUSH HL
$91FB: 2A C1 D9  LD HL,(D9C1)
$91FE: 19        ADD HL,DE
$91FF: DA C3 D2  JP C,D2C3
$9202: D0        RET NC
$9203: AF        XOR A
$9204: 32 D5 D9  LD (D9D5),A
$9207: C5        PUSH BC
$9208: 2A 43 CF  LD HL,(CF43)
$920B: EB        EX DE,HL
$920C: 21 21 00  LD HL,0021
$920F: 19        ADD HL,DE
$9210: 7E        LD A,(HL)
$9211: E6 7F     AND 7F
$9213: F5        PUSH AF
$9214: 7E        LD A,(HL)
$9215: 17        RLA
$9216: 23        INC HL
$9217: 7E        LD A,(HL)
$9218: 17        RLA
$9219: E6 1F     AND 1F
$921B: 4F        LD C,A
$921C: 7E        LD A,(HL)
$921D: 1F        RRA
$921E: 1F        RRA
$921F: 1F        RRA
$9220: 1F        RRA
$9221: E6 0F     AND 0F
$9223: 47        LD B,A
$9224: F1        POP AF
$9225: 23        INC HL
$9226: 6E        LD L,(HL)
$9227: 2C        INC L
$9228: 2D        DEC L
$9229: 2E 06     LD L,06
$922B: C2 8B D7  JP NZ,D78B
$922E: 21 20 00  LD HL,0020
$9231: 19        ADD HL,DE
$9232: 77        LD (HL),A
$9233: 21 0C 00  LD HL,000C
$9236: 19        ADD HL,DE
$9237: 79        LD A,C
$9238: 96        SUB (HL)
$9239: C2 47 D7  JP NZ,D747
$923C: 21 0E 00  LD HL,000E
$923F: 19        ADD HL,DE
$9240: 78        LD A,B
$9241: 96        SUB (HL)
$9242: E6 7F     AND 7F
$9244: CA 7F D7  JP Z,D77F
$9247: C5        PUSH BC
$9248: D5        PUSH DE
$9249: CD A2 D4  CALL D4A2
$924C: D1        POP DE
$924D: C1        POP BC
$924E: 2E 03     LD L,03
$9250: 3A 45 CF  LD A,(CF45)
$9253: 3C        INC A
$9254: CA 84 D7  JP Z,D784
$9257: 21 0C 00  LD HL,000C
$925A: 19        ADD HL,DE
$925B: 71        LD (HL),C
$925C: 21 0E 00  LD HL,000E
$925F: 19        ADD HL,DE
$9260: 70        LD (HL),B
$9261: CD 51 D4  CALL D451
$9264: 3A 45 CF  LD A,(CF45)
$9267: 3C        INC A
$9268: C2 7F D7  JP NZ,D77F
$926B: C1        POP BC
$926C: C5        PUSH BC
$926D: 2E 04     LD L,04
$926F: 0C        INC C
$9270: CA 84 D7  JP Z,D784
$9273: CD 24 D5  CALL D524
$9276: 2E 05     LD L,05
$9278: 3A 45 CF  LD A,(CF45)
$927B: 3C        INC A
$927C: CA 84 D7  JP Z,D784
$927F: C1        POP BC
$9280: AF        XOR A
$9281: C3 01 CF  JP CF01
$9284: E5        PUSH HL
$9285: CD 69 D1  CALL D169
$9288: 36 C0     LD (HL),C0
$928A: E1        POP HL
$928B: C1        POP BC
$928C: 7D        LD A,L
$928D: 32 45 CF  LD (CF45),A
$9290: C3 78 D1  JP D178
$9293: 0E FF     LD C,FF
$9295: CD 03 D7  CALL D703
$9298: CC C1 D5  CALL Z,D5C1
$929B: C9        RET
$929C: 0E 00     LD C,00
$929E: CD 03 D7  CALL D703
$92A1: CC 03 D6  CALL Z,D603
$92A4: C9        RET
$92A5: EB        EX DE,HL
$92A6: 19        ADD HL,DE
$92A7: 4E        LD C,(HL)
$92A8: 06 00     LD B,00
$92AA: 21 0C 00  LD HL,000C
$92AD: 19        ADD HL,DE
$92AE: 7E        LD A,(HL)
$92AF: 0F        RRCA
$92B0: E6 80     AND 80
$92B2: 81        ADD A,C
$92B3: 4F        LD C,A
$92B4: 3E 00     LD A,00
$92B6: 88        ADC A,B
$92B7: 47        LD B,A
$92B8: 7E        LD A,(HL)
$92B9: 0F        RRCA
$92BA: E6 0F     AND 0F
$92BC: 80        ADD A,B
$92BD: 47        LD B,A
$92BE: 21 0E 00  LD HL,000E
$92C1: 19        ADD HL,DE
$92C2: 7E        LD A,(HL)
$92C3: 87        ADD A,A
$92C4: 87        ADD A,A
$92C5: 87        ADD A,A
$92C6: 87        ADD A,A
$92C7: F5        PUSH AF
$92C8: 80        ADD A,B
$92C9: 47        LD B,A
$92CA: F5        PUSH AF
$92CB: E1        POP HL
$92CC: 7D        LD A,L
$92CD: E1        POP HL
$92CE: B5        OR L
$92CF: E6 01     AND 01
$92D1: C9        RET
$92D2: 0E 0C     LD C,0C
$92D4: CD 18 D3  CALL D318
$92D7: 2A 43 CF  LD HL,(CF43)
$92DA: 11 21 00  LD DE,0021
$92DD: 19        ADD HL,DE
$92DE: E5        PUSH HL
$92DF: 72        LD (HL),D
$92E0: 23        INC HL
$92E1: 72        LD (HL),D
$92E2: 23        INC HL
$92E3: 72        LD (HL),D
$92E4: CD F5 D1  CALL D1F5
$92E7: CA 0C D8  JP Z,D80C
$92EA: CD 5E D1  CALL D15E
$92ED: 11 0F 00  LD DE,000F
$92F0: CD A5 D7  CALL D7A5
$92F3: E1        POP HL
$92F4: E5        PUSH HL
$92F5: 5F        LD E,A
$92F6: 79        LD A,C
$92F7: 96        SUB (HL)
$92F8: 23        INC HL
$92F9: 78        LD A,B
$92FA: 9E        SBC A,(HL)
$92FB: 23        INC HL
$92FC: 7B        LD A,E
$92FD: 9E        SBC A,(HL)
$92FE: DA 06 0F  JP C,0F06
$9301: D0        RET NC
$9302: 79        LD A,C
$9303: 95        SUB L
$9304: 78        LD A,B
$9305: 9C        SBC A,H
$9306: DA 0F D0  JP C,D00F
$9309: EB        EX DE,HL
$930A: E1        POP HL
$930B: 23        INC HL
$930C: C3 FA CF  JP CFFA
$930F: E1        POP HL
$9310: C5        PUSH BC
$9311: D5        PUSH DE
$9312: E5        PUSH HL
$9313: EB        EX DE,HL
$9314: 2A CE D9  LD HL,(D9CE)
$9317: 19        ADD HL,DE
$9318: 44        LD B,H
$9319: 4D        LD C,L
$931A: CD 1E DA  CALL DA1E
$931D: D1        POP DE
$931E: 2A B5 D9  LD HL,(D9B5)
$9321: 73        LD (HL),E
$9322: 23        INC HL
$9323: 72        LD (HL),D
$9324: D1        POP DE
$9325: 2A B7 D9  LD HL,(D9B7)
$9328: 73        LD (HL),E
$9329: 23        INC HL
$932A: 72        LD (HL),D
$932B: C1        POP BC
$932C: 79        LD A,C
$932D: 93        SUB E
$932E: 4F        LD C,A
$932F: 78        LD A,B
$9330: 9A        SBC A,D
$9331: 47        LD B,A
$9332: 2A D0 D9  LD HL,(D9D0)
$9335: EB        EX DE,HL
$9336: CD 30 DA  CALL DA30
$9339: 4D        LD C,L
$933A: 44        LD B,H
$933B: C3 21 DA  JP DA21
$933E: 21 C3 D9  LD HL,D9C3
$9341: 4E        LD C,(HL)
$9342: 3A E3 D9  LD A,(D9E3)
$9345: B7        OR A
$9346: 1F        RRA
$9347: 0D        DEC C
$9348: C2 45 D0  JP NZ,D045
$934B: 47        LD B,A
$934C: 3E 08     LD A,08
$934E: 96        SUB (HL)
$934F: 4F        LD C,A
$9350: 3A E2 D9  LD A,(D9E2)
$9353: 0D        DEC C
$9354: CA 5C D0  JP Z,D05C
$9357: B7        OR A
$9358: 17        RLA
$9359: C3 53 D0  JP D053
$935C: 80        ADD A,B
$935D: C9        RET
$935E: 2A 43 CF  LD HL,(CF43)
$9361: 11 10 00  LD DE,0010
$9364: 19        ADD HL,DE
$9365: 09        ADD HL,BC
$9366: 3A DD D9  LD A,(D9DD)
$9369: B7        OR A
$936A: CA 71 D0  JP Z,D071
$936D: 6E        LD L,(HL)
$936E: 26 00     LD H,00
$9370: C9        RET
$9371: 09        ADD HL,BC
$9372: 5E        LD E,(HL)
$9373: 23        INC HL
$9374: 56        LD D,(HL)
$9375: EB        EX DE,HL
$9376: C9        RET
$9377: CD 3E D0  CALL D03E
$937A: 4F        LD C,A
$937B: 06 00     LD B,00
$937D: CD 5E D0  CALL D05E
$9380: 22 E5 D9  LD (D9E5),HL
$9383: C9        RET
$9384: 2A E5 D9  LD HL,(D9E5)
$9387: 7D        LD A,L
$9388: B4        OR H
$9389: C9        RET
$938A: 3A C3 D9  LD A,(D9C3)
$938D: 2A E5 D9  LD HL,(D9E5)
$9390: 29        ADD HL,HL
$9391: 3D        DEC A
$9392: C2 90 D0  JP NZ,D090
$9395: 22 E7 D9  LD (D9E7),HL
$9398: 3A C4 D9  LD A,(D9C4)
$939B: 4F        LD C,A
$939C: 3A E3 D9  LD A,(D9E3)
$939F: A1        AND C
$93A0: B5        OR L
$93A1: 6F        LD L,A
$93A2: 22 E5 D9  LD (D9E5),HL
$93A5: C9        RET
$93A6: 2A 43 CF  LD HL,(CF43)
$93A9: 11 0C 00  LD DE,000C
$93AC: 19        ADD HL,DE
$93AD: C9        RET
$93AE: 2A 43 CF  LD HL,(CF43)
$93B1: 11 0F 00  LD DE,000F
$93B4: 19        ADD HL,DE
$93B5: EB        EX DE,HL
$93B6: 21 11 00  LD HL,0011
$93B9: 19        ADD HL,DE
$93BA: C9        RET
$93BB: CD AE D0  CALL D0AE
$93BE: 7E        LD A,(HL)
$93BF: 32 E3 D9  LD (D9E3),A
$93C2: EB        EX DE,HL
$93C3: 7E        LD A,(HL)
$93C4: 32 E1 D9  LD (D9E1),A
$93C7: CD A6 D0  CALL D0A6
$93CA: 3A C5 D9  LD A,(D9C5)
$93CD: A6        AND (HL)
$93CE: 32 E2 D9  LD (D9E2),A
$93D1: C9        RET
$93D2: CD AE D0  CALL D0AE
$93D5: 3A D5 D9  LD A,(D9D5)
$93D8: FE 02     CP 02
$93DA: C2 DE D0  JP NZ,D0DE
$93DD: AF        XOR A
$93DE: 4F        LD C,A
$93DF: 3A E3 D9  LD A,(D9E3)
$93E2: 81        ADD A,C
$93E3: 77        LD (HL),A
$93E4: EB        EX DE,HL
$93E5: 3A E1 D9  LD A,(D9E1)
$93E8: 77        LD (HL),A
$93E9: C9        RET
$93EA: 0C        INC C
$93EB: 0D        DEC C
$93EC: C8        RET Z
$93ED: 7C        LD A,H
$93EE: B7        OR A
$93EF: 1F        RRA
$93F0: 67        LD H,A
$93F1: 7D        LD A,L
$93F2: 1F        RRA
$93F3: 6F        LD L,A
$93F4: C3 EB D0  JP D0EB
$93F7: 0E 80     LD C,80
$93F9: 2A B9 D9  LD HL,(D9B9)
$93FC: AF        XOR A
$93FD: 86        ADD A,(HL)
$93FE: 23        INC HL
$93FF: 0D        DEC C
$9400: D8        RET C
$9401: 73        LD (HL),E
$9402: 2B        DEC HL
$9403: 70        LD (HL),B
$9404: 2B        DEC HL
$9405: 71        LD (HL),C
$9406: CD 2D D3  CALL D32D
$9409: C3 E4 D7  JP D7E4
$940C: E1        POP HL
$940D: C9        RET
$940E: 2A 43 CF  LD HL,(CF43)
$9411: 11 20 00  LD DE,0020
$9414: CD A5 D7  CALL D7A5
$9417: 21 21 00  LD HL,0021
$941A: 19        ADD HL,DE
$941B: 71        LD (HL),C
$941C: 23        INC HL
$941D: 70        LD (HL),B
$941E: 23        INC HL
$941F: 77        LD (HL),A
$9420: C9        RET
$9421: 2A AF D9  LD HL,(D9AF)
$9424: 3A 42 CF  LD A,(CF42)
$9427: 4F        LD C,A
$9428: CD EA D0  CALL D0EA
$942B: E5        PUSH HL
$942C: EB        EX DE,HL
$942D: CD 59 CF  CALL CF59
$9430: E1        POP HL
$9431: CC 47 CF  CALL Z,CF47
$9434: 7D        LD A,L
$9435: 1F        RRA
$9436: D8        RET C
$9437: 2A AF D9  LD HL,(D9AF)
$943A: 4D        LD C,L
$943B: 44        LD B,H
$943C: CD 0B D1  CALL D10B
$943F: 22 AF D9  LD (D9AF),HL
$9442: C3 A3 D2  JP D2A3
$9445: 3A D6 D9  LD A,(D9D6)
$9448: 21 42 CF  LD HL,CF42
$944B: BE        CP (HL)
$944C: C8        RET Z
$944D: 77        LD (HL),A
$944E: C3 21 D8  JP D821
$9451: 3E FF     LD A,FF
$9453: 32 DE D9  LD (D9DE),A
$9456: 2A 43 CF  LD HL,(CF43)
$9459: 7E        LD A,(HL)
$945A: E6 1F     AND 1F
$945C: 3D        DEC A
$945D: 32 D6 D9  LD (D9D6),A
$9460: FE 1E     CP 1E
$9462: D2 75 D8  JP NC,D875
$9465: 3A 42 CF  LD A,(CF42)
$9468: 32 DF D9  LD (D9DF),A
$946B: 7E        LD A,(HL)
$946C: 32 E0 D9  LD (D9E0),A
$946F: E6 E0     AND E0
$9471: 77        LD (HL),A
$9472: CD 45 D8  CALL D845
$9475: 3A 41 CF  LD A,(CF41)
$9478: 2A 43 CF  LD HL,(CF43)
$947B: B6        OR (HL)
$947C: 77        LD (HL),A
$947D: C9        RET
$947E: 3E 22     LD A,22
$9480: C3 01 CF  JP CF01
$9483: 21 00 00  LD HL,0000
$9486: 22 AD D9  LD (D9AD),HL
$9489: 22 AF D9  LD (D9AF),HL
$948C: AF        XOR A
$948D: 32 42 CF  LD (CF42),A
$9490: 21 80 00  LD HL,0080
$9493: 22 B1 D9  LD (D9B1),HL
$9496: CD DA D1  CALL D1DA
$9499: C3 21 D8  JP D821
$949C: CD 72 D1  CALL D172
$949F: CD 51 D8  CALL D851
$94A2: C3 51 D4  JP D451
$94A5: CD 51 D8  CALL D851
$94A8: C3 A2 D4  JP D4A2
$94AB: 0E 00     LD C,00
$94AD: EB        EX DE,HL
$94AE: 7E        LD A,(HL)
$94AF: FE 3F     CP 3F
$94B1: CA C2 D8  JP Z,D8C2
$94B4: CD A6 D0  CALL D0A6
$94B7: 7E        LD A,(HL)
$94B8: FE 3F     CP 3F
$94BA: C4 72 D1  CALL NZ,D172
$94BD: CD 51 D8  CALL D851
$94C0: 0E 0F     LD C,0F
$94C2: CD 18 D3  CALL D318
$94C5: C3 E9 D1  JP D1E9
$94C8: 2A D9 D9  LD HL,(D9D9)
$94CB: 22 43 CF  LD (CF43),HL
$94CE: CD 51 D8  CALL D851
$94D1: CD 2D D3  CALL D32D
$94D4: C3 E9 D1  JP D1E9
$94D7: CD 51 D8  CALL D851
$94DA: CD 9C D3  CALL D39C
$94DD: C3 01 D3  JP D301
$94E0: CD 51 D8  CALL D851
$94E3: C3 BC D5  JP D5BC
$94E6: CD 51 D8  CALL D851
$94E9: C3 FE D5  JP D5FE
$94EC: CD 72 D1  CALL D172
$94EF: CD 51 D8  CALL D851
$94F2: C3 24 D5  JP D524
$94F5: CD 51 D8  CALL D851
$94F8: CD 16 D4  CALL D416
$94FB: C3 01 D3  JP D301
$94FE: 2A AF D9  LD HL,(D9AF)
$9501: C3 29 D9  JP D929
$9504: 3A 42 CF  LD A,(CF42)
$9507: C3 01 CF  JP CF01
$950A: EB        EX DE,HL
$950B: 22 B1 D9  LD (D9B1),HL
$950E: C3 DA D1  JP D1DA
$9511: 2A BF D9  LD HL,(D9BF)
$9514: C3 29 D9  JP D929
$9517: 2A AD D9  LD HL,(D9AD)
$951A: C3 29 D9  JP D929
$951D: CD 51 D8  CALL D851
$9520: CD 3B D4  CALL D43B
$9523: C3 01 D3  JP D301
$9526: 2A BB D9  LD HL,(D9BB)
$9529: 22 45 CF  LD (CF45),HL
$952C: C9        RET
$952D: 3A D6 D9  LD A,(D9D6)
$9530: FE FF     CP FF
$9532: C2 3B D9  JP NZ,D93B
$9535: 3A 41 CF  LD A,(CF41)
$9538: C3 01 CF  JP CF01
$953B: E6 1F     AND 1F
$953D: 32 41 CF  LD (CF41),A
$9540: C9        RET
$9541: CD 51 D8  CALL D851
$9544: C3 93 D7  JP D793
$9547: CD 51 D8  CALL D851
$954A: C3 9C D7  JP D79C
$954D: CD 51 D8  CALL D851
$9550: C3 D2 D7  JP D7D2
$9553: 2A 43 CF  LD HL,(CF43)
$9556: 7D        LD A,L
$9557: 2F        CPL
$9558: 5F        LD E,A
$9559: 7C        LD A,H
$955A: 2F        CPL
$955B: 2A AF D9  LD HL,(D9AF)
$955E: A4        AND H
$955F: 57        LD D,A
$9560: 7D        LD A,L
$9561: A3        AND E
$9562: 5F        LD E,A
$9563: 2A AD D9  LD HL,(D9AD)
$9566: EB        EX DE,HL
$9567: 22 AF D9  LD (D9AF),HL
$956A: 7D        LD A,L
$956B: A3        AND E
$956C: 6F        LD L,A
$956D: 7C        LD A,H
$956E: A2        AND D
$956F: 67        LD H,A
$9570: 22 AD D9  LD (D9AD),HL
$9573: C9        RET
$9574: 3A DE D9  LD A,(D9DE)
$9577: B7        OR A
$9578: CA 91 D9  JP Z,D991
$957B: 2A 43 CF  LD HL,(CF43)
$957E: 36 00     LD (HL),00
$9580: 3A E0 D9  LD A,(D9E0)
$9583: B7        OR A
$9584: CA 91 D9  JP Z,D991
$9587: 77        LD (HL),A
$9588: 3A DF D9  LD A,(D9DF)
$958B: 32 D6 D9  LD (D9D6),A
$958E: CD 45 D8  CALL D845
$9591: 2A 0F CF  LD HL,(CF0F)
$9594: F9        LD SP,HL
$9595: 2A 45 CF  LD HL,(CF45)
$9598: 7D        LD A,L
$9599: 44        LD B,H
$959A: C9        RET
$959B: CD 51 D8  CALL D851
$959E: 3E 02     LD A,02
$95A0: 32 D5 D9  LD (D9D5),A
$95A3: 0E 00     LD C,00
$95A5: CD 07 D7  CALL D707
$95A8: CC 03 D6  CALL Z,D603
$95AB: C9        RET
$95AC: E5        PUSH HL
$95AD: 00        NOP
$95AE: 00        NOP
$95AF: 00        NOP
$95B0: 00        NOP
$95B1: 80        ADD A,B
$95B2: 00        NOP
$95B3: 00        NOP
$95B4: 00        NOP
$95B5: 00        NOP
$95B6: 00        NOP
$95B7: 00        NOP
$95B8: 00        NOP
$95B9: 00        NOP
$95BA: 00        NOP
$95BB: 00        NOP
$95BC: 00        NOP
$95BD: 00        NOP
$95BE: 00        NOP
$95BF: 00        NOP
$95C0: 00        NOP
$95C1: 00        NOP
$95C2: 00        NOP
$95C3: 00        NOP
$95C4: 00        NOP
$95C5: 00        NOP
$95C6: 00        NOP
$95C7: 00        NOP
$95C8: 00        NOP
$95C9: 00        NOP
$95CA: 00        NOP
$95CB: 00        NOP
$95CC: 00        NOP
$95CD: 00        NOP
$95CE: 00        NOP
$95CF: 00        NOP
$95D0: 00        NOP
$95D1: 00        NOP
$95D2: 00        NOP
$95D3: 00        NOP
$95D4: 00        NOP
$95D5: 00        NOP
$95D6: 00        NOP
$95D7: 00        NOP
$95D8: 00        NOP
$95D9: 00        NOP
$95DA: 00        NOP
$95DB: 00        NOP
$95DC: 00        NOP
$95DD: 00        NOP
$95DE: 00        NOP
$95DF: 00        NOP
$95E0: 00        NOP
$95E1: 00        NOP
$95E2: 00        NOP
$95E3: 00        NOP
$95E4: 00        NOP
$95E5: 00        NOP
$95E6: 00        NOP
$95E7: 00        NOP
$95E8: 00        NOP
$95E9: 00        NOP
$95EA: 00        NOP
$95EB: 00        NOP
$95EC: 00        NOP
$95ED: 00        NOP
$95EE: 00        NOP
$95EF: 00        NOP
$95F0: 00        NOP
$95F1: 00        NOP
$95F2: 00        NOP
$95F3: 00        NOP
$95F4: 00        NOP
$95F5: 00        NOP
$95F6: 00        NOP
$95F7: 00        NOP
$95F8: 00        NOP
$95F9: 00        NOP
$95FA: 00        NOP
$95FB: 00        NOP
$95FC: 00        NOP
$95FD: 00        NOP
$95FE: 00        NOP
$95FF: 00        NOP
$9600: E5        PUSH HL
$9601: E5        PUSH HL
$9602: E5        PUSH HL
$9603: E5        PUSH HL
$9604: E5        PUSH HL
$9605: E5        PUSH HL
$9606: E5        PUSH HL
$9607: E5        PUSH HL
$9608: E5        PUSH HL
$9609: E5        PUSH HL
$960A: E5        PUSH HL
$960B: E5        PUSH HL
$960C: E5        PUSH HL
$960D: E5        PUSH HL
$960E: E5        PUSH HL
$960F: E5        PUSH HL
$9610: E5        PUSH HL
$9611: E5        PUSH HL
$9612: E5        PUSH HL
$9613: E5        PUSH HL
$9614: E5        PUSH HL
$9615: E5        PUSH HL
$9616: E5        PUSH HL
$9617: E5        PUSH HL
$9618: E5        PUSH HL
$9619: E5        PUSH HL
$961A: E5        PUSH HL
$961B: E5        PUSH HL
$961C: E5        PUSH HL
$961D: E5        PUSH HL
$961E: E5        PUSH HL
$961F: E5        PUSH HL
$9620: E5        PUSH HL
$9621: E5        PUSH HL
$9622: E5        PUSH HL
$9623: E5        PUSH HL
$9624: E5        PUSH HL
$9625: E5        PUSH HL
$9626: E5        PUSH HL
$9627: E5        PUSH HL
$9628: E5        PUSH HL
$9629: E5        PUSH HL
$962A: E5        PUSH HL
$962B: E5        PUSH HL
$962C: E5        PUSH HL
$962D: E5        PUSH HL
$962E: E5        PUSH HL
$962F: E5        PUSH HL
$9630: E5        PUSH HL
$9631: E5        PUSH HL
$9632: E5        PUSH HL
$9633: E5        PUSH HL
$9634: E5        PUSH HL
$9635: E5        PUSH HL
$9636: E5        PUSH HL
$9637: E5        PUSH HL
$9638: E5        PUSH HL
$9639: E5        PUSH HL
$963A: E5        PUSH HL
$963B: E5        PUSH HL
$963C: E5        PUSH HL
$963D: E5        PUSH HL
$963E: E5        PUSH HL
$963F: E5        PUSH HL
$9640: E5        PUSH HL
$9641: E5        PUSH HL
$9642: E5        PUSH HL
$9643: E5        PUSH HL
$9644: E5        PUSH HL
$9645: E5        PUSH HL
$9646: E5        PUSH HL
$9647: E5        PUSH HL
$9648: E5        PUSH HL
$9649: E5        PUSH HL
$964A: E5        PUSH HL
$964B: E5        PUSH HL
$964C: E5        PUSH HL
$964D: E5        PUSH HL
$964E: E5        PUSH HL
$964F: E5        PUSH HL
$9650: E5        PUSH HL
$9651: E5        PUSH HL
$9652: E5        PUSH HL
$9653: E5        PUSH HL
$9654: E5        PUSH HL
$9655: E5        PUSH HL
$9656: E5        PUSH HL
$9657: E5        PUSH HL
$9658: E5        PUSH HL
$9659: E5        PUSH HL
$965A: E5        PUSH HL
$965B: E5        PUSH HL
$965C: E5        PUSH HL
$965D: E5        PUSH HL
$965E: E5        PUSH HL
$965F: E5        PUSH HL
$9660: E5        PUSH HL
$9661: E5        PUSH HL
$9662: E5        PUSH HL
$9663: E5        PUSH HL
$9664: E5        PUSH HL
$9665: E5        PUSH HL
$9666: E5        PUSH HL
$9667: E5        PUSH HL
$9668: E5        PUSH HL
$9669: E5        PUSH HL
$966A: E5        PUSH HL
$966B: E5        PUSH HL
$966C: E5        PUSH HL
$966D: E5        PUSH HL
$966E: E5        PUSH HL
$966F: E5        PUSH HL
$9670: E5        PUSH HL
$9671: E5        PUSH HL
$9672: E5        PUSH HL
$9673: E5        PUSH HL
$9674: E5        PUSH HL
$9675: E5        PUSH HL
$9676: E5        PUSH HL
$9677: E5        PUSH HL
$9678: E5        PUSH HL
$9679: E5        PUSH HL
$967A: E5        PUSH HL
$967B: E5        PUSH HL
$967C: E5        PUSH HL
$967D: E5        PUSH HL
$967E: E5        PUSH HL
$967F: E5        PUSH HL
$9680: E5        PUSH HL
$9681: E5        PUSH HL
$9682: E5        PUSH HL
$9683: E5        PUSH HL
$9684: E5        PUSH HL
$9685: E5        PUSH HL
$9686: E5        PUSH HL
$9687: E5        PUSH HL
$9688: E5        PUSH HL
$9689: E5        PUSH HL
$968A: E5        PUSH HL
$968B: E5        PUSH HL
$968C: E5        PUSH HL
$968D: E5        PUSH HL
$968E: E5        PUSH HL
$968F: E5        PUSH HL
$9690: E5        PUSH HL
$9691: E5        PUSH HL
$9692: E5        PUSH HL
$9693: E5        PUSH HL
$9694: E5        PUSH HL
$9695: E5        PUSH HL
$9696: E5        PUSH HL
$9697: E5        PUSH HL
$9698: E5        PUSH HL
$9699: E5        PUSH HL
$969A: E5        PUSH HL
$969B: E5        PUSH HL
$969C: E5        PUSH HL
$969D: E5        PUSH HL
$969E: E5        PUSH HL
$969F: E5        PUSH HL
$96A0: E5        PUSH HL
$96A1: E5        PUSH HL
$96A2: E5        PUSH HL
$96A3: E5        PUSH HL
$96A4: E5        PUSH HL
$96A5: E5        PUSH HL
$96A6: E5        PUSH HL
$96A7: E5        PUSH HL
$96A8: E5        PUSH HL
$96A9: E5        PUSH HL
$96AA: E5        PUSH HL
$96AB: E5        PUSH HL
$96AC: E5        PUSH HL
$96AD: E5        PUSH HL
$96AE: E5        PUSH HL
$96AF: E5        PUSH HL
$96B0: E5        PUSH HL
$96B1: E5        PUSH HL
$96B2: E5        PUSH HL
$96B3: E5        PUSH HL
$96B4: E5        PUSH HL
$96B5: E5        PUSH HL
$96B6: E5        PUSH HL
$96B7: E5        PUSH HL
$96B8: E5        PUSH HL
$96B9: E5        PUSH HL
$96BA: E5        PUSH HL
$96BB: E5        PUSH HL
$96BC: E5        PUSH HL
$96BD: E5        PUSH HL
$96BE: E5        PUSH HL
$96BF: E5        PUSH HL
$96C0: E5        PUSH HL
$96C1: E5        PUSH HL
$96C2: E5        PUSH HL
$96C3: E5        PUSH HL
$96C4: E5        PUSH HL
$96C5: E5        PUSH HL
$96C6: E5        PUSH HL
$96C7: E5        PUSH HL
$96C8: E5        PUSH HL
$96C9: E5        PUSH HL
$96CA: E5        PUSH HL
$96CB: E5        PUSH HL
$96CC: E5        PUSH HL
$96CD: E5        PUSH HL
$96CE: E5        PUSH HL
$96CF: E5        PUSH HL
$96D0: E5        PUSH HL
$96D1: E5        PUSH HL
$96D2: E5        PUSH HL
$96D3: E5        PUSH HL
$96D4: E5        PUSH HL
$96D5: E5        PUSH HL
$96D6: E5        PUSH HL
$96D7: E5        PUSH HL
$96D8: E5        PUSH HL
$96D9: E5        PUSH HL
$96DA: E5        PUSH HL
$96DB: E5        PUSH HL
$96DC: E5        PUSH HL
$96DD: E5        PUSH HL
$96DE: E5        PUSH HL
$96DF: E5        PUSH HL
$96E0: E5        PUSH HL
$96E1: E5        PUSH HL
$96E2: E5        PUSH HL
$96E3: E5        PUSH HL
$96E4: E5        PUSH HL
$96E5: E5        PUSH HL
$96E6: E5        PUSH HL
$96E7: E5        PUSH HL
$96E8: E5        PUSH HL
$96E9: E5        PUSH HL
$96EA: E5        PUSH HL
$96EB: E5        PUSH HL
$96EC: E5        PUSH HL
$96ED: E5        PUSH HL
$96EE: E5        PUSH HL
$96EF: E5        PUSH HL
$96F0: E5        PUSH HL
$96F1: E5        PUSH HL
$96F2: E5        PUSH HL
$96F3: E5        PUSH HL
$96F4: E5        PUSH HL
$96F5: E5        PUSH HL
$96F6: E5        PUSH HL
$96F7: E5        PUSH HL
$96F8: E5        PUSH HL
$96F9: E5        PUSH HL
$96FA: E5        PUSH HL
$96FB: E5        PUSH HL
$96FC: E5        PUSH HL
$96FD: E5        PUSH HL
$96FE: E5        PUSH HL


; ============================================================================
; END OF SYSIMG -- 2.20 has no boot banner; sysimg tail is $E5 filler.
; ============================================================================
