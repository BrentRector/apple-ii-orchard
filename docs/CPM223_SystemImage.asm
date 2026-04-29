; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- System Image (CCP + BDOS at $8000-$96FF)
; Annotated Z-80 assembly source for the CP/M 2.2 system image as it
; sits at runtime $8000-$96FF after the loader's third page copy.
;
; SCOPE
;   This region is Digital Research's stock CP/M 2.2 (CCP + BDOS) plus
;   Microsoft's boot banner. Microsoft provides only the BIOS (covered
;   in CPM223_BIOS.asm); the CCP and BDOS here are the standard 1981
;   CP/M 2.2 codebase with absolute-address relocation applied for the
;   $8000-$96FF runtime range.
;
; STRUCTURE
;   $8000-$80C6  CCP entry + initial dispatch code
;   $80C7-$80DD  CCP built-in command table ("DIR ERA TYPE SAVE REN USER")
;   $80DE-$8B69  CCP body: command parser, file-name parser, drive
;                  selector, error-message printer
;   $8B70-$96BA  BDOS body: function dispatcher + handler routines
;   $96BB-$96FF  Boot banner string
;
; SOURCE
;   Loaded by LOAD_CPM (29-sector read into Apple $8000-$9CFF staging)
;   and relocated to runtime position by the loader's third page copy
;   at Apple $113D (copies $A300-$B9FF -> $8000-$96FF).
;
; PRACTICAL NOTE
;   Per-instruction annotation of CCP+BDOS is left to the reader's
;   standard CP/M 2.2 reference disassembly (Heath / Digital Research
;   archives). Microsoft's modifications to CCP+BDOS for the SoftCard
;   are minimal -- the boot banner string and any absolute-address
;   relocation, primarily. The Videx-fix-relevant code is in BIOS
;   (covered in CPM223_BIOS.asm), not here.
; ============================================================================

            .ORG $8000


; ============================================================================
; CCP ENTRY ($8000)
;
; Cold-start jumps to the CCP main loop at $9631 (near top of CCP).
; That's where the prompt-display + command-read loop lives.
; ============================================================================

CCP_ENTRY:
$8000: C3 31 96  JP 9631
$8003: 1A        LD A,(DE)
$8004: B7        OR A
$8005: C8        RET Z
$8006: FE 20     CP 20
$8008: 38 D5     JR C,7FDF
$800A: C8        RET Z
$800B: FE 3D     CP 3D
$800D: C8        RET Z
$800E: FE 5F     CP 5F
$8010: C8        RET Z
$8011: FE 2E     CP 2E
$8013: C8        RET Z
$8014: FE 3A     CP 3A
$8016: C8        RET Z
$8017: FE 3B     CP 3B
$8019: C8        RET Z
$801A: FE 3C     CP 3C
$801C: C8        RET Z
$801D: FE 3E     CP 3E
$801F: C8        RET Z
$8020: C9        RET
$8021: 1A        LD A,(DE)
$8022: B7        OR A
$8023: C8        RET Z
$8024: FE 20     CP 20
$8026: C0        RET NZ
$8027: 13        INC DE
$8028: 18 F7     JR 8021
$802A: 85        ADD A,L
$802B: 6F        LD L,A
$802C: D0        RET NC
$802D: 24        INC H
$802E: C9        RET
$802F: 3E 00     LD A,00
$8031: 21 86 9B  LD HL,9B86
$8034: CD 2A 95  CALL 952A
$8037: E5        PUSH HL
$8038: E5        PUSH HL
$8039: AF        XOR A
$803A: 32 A9 9B  LD (9BA9),A
$803D: 2A 88 93  LD HL,(9388)
$8040: EB        EX DE,HL
$8041: CD 21 95  CALL 9521
$8044: EB        EX DE,HL
$8045: 22 8A 93  LD (938A),HL
$8048: EB        EX DE,HL
$8049: E1        POP HL
$804A: 1A        LD A,(DE)
$804B: B7        OR A
$804C: 28 0A     JR Z,8058
$804E: DE 40     SBC A,40
$8050: 47        LD B,A
$8051: 13        INC DE
$8052: 1A        LD A,(DE)
$8053: FE 3A     CP 3A
$8055: 28 07     JR Z,805E
$8057: 1B        DEC DE
$8058: 3A A8 9B  LD A,(9BA8)
$805B: 77        LD (HL),A
$805C: 18 06     JR 8064
$805E: 78        LD A,B
$805F: 32 A9 9B  LD (9BA9),A
$8062: 70        LD (HL),B
$8063: 13        INC DE
$8064: 06 08     LD B,08
$8066: CD 03 95  CALL 9503
$8069: 28 15     JR Z,8080
$806B: 23        INC HL
$806C: FE 2A     CP 2A
$806E: 20 04     JR NZ,8074
$8070: 36 3F     LD (HL),3F
$8072: 18 02     JR 8076
$8074: 77        LD (HL),A
$8075: 13        INC DE
$8076: 10 EE     DJNZ 8066
$8078: CD 03 95  CALL 9503
$807B: 28 08     JR Z,8085
$807D: 13        INC DE
$807E: 18 F8     JR 8078
$8080: 23        INC HL
$8081: 36 20     LD (HL),20
$8083: 10 FB     DJNZ 8080
$8085: 06 03     LD B,03
$8087: FE 2E     CP 2E
$8089: 20 1B     JR NZ,80A6
$808B: 13        INC DE
$808C: CD 03 95  CALL 9503
$808F: 28 15     JR Z,80A6
$8091: 23        INC HL
$8092: FE 2A     CP 2A
$8094: 20 04     JR NZ,809A
$8096: 36 3F     LD (HL),3F
$8098: 18 02     JR 809C
$809A: 77        LD (HL),A
$809B: 13        INC DE
$809C: 10 EE     DJNZ 808C
$809E: CD 03 95  CALL 9503
$80A1: 28 08     JR Z,80AB
$80A3: 13        INC DE
$80A4: 18 F8     JR 809E
$80A6: 23        INC HL
$80A7: 36 20     LD (HL),20
$80A9: 10 FB     DJNZ 80A6
$80AB: 06 03     LD B,03
$80AD: 23        INC HL
$80AE: 36 00     LD (HL),00
$80B0: 10 FB     DJNZ 80AD
$80B2: EB        EX DE,HL
$80B3: 22 88 93  LD (9388),HL
$80B6: E1        POP HL
$80B7: 01 0B 00  LD BC,000B
$80BA: 23        INC HL
$80BB: 7E        LD A,(HL)
$80BC: FE 3F     CP 3F
$80BE: 20 01     JR NZ,80C1
$80C0: 04        INC B
$80C1: 0D        DEC C
$80C2: 20 F6     JR NZ,80BA
$80C4: 78        LD A,B
$80C5: B7        OR A
$80C6: C9        RET

; ============================================================================
; CCP BUILT-IN COMMAND TABLE ($80C7-$80DD)
;
; Six four-character entries, each padded with spaces to 4 chars:
;   DIR   list directory
;   ERA   erase file
;   TYPE  type file to console
;   SAVE  save N pages of memory to file
;   REN   rename file
;   USER  set/show current user area
;
; The CCP command parser tokenizes input and matches against this
; table; non-matching commands are loaded as .COM files from disk.
; ============================================================================


$80C7: 44        LD B,H
$80C8: 49        LD C,C
$80C9: 52        LD D,D
$80CA: 20 45     JR NZ,8111
$80CC: 52        LD D,D
$80CD: 41        LD B,C
$80CE: 20 54     JR NZ,8124
$80D0: 59        LD E,C
$80D1: 50        LD D,B
$80D2: 45        LD B,L
$80D3: 53        LD D,E
$80D4: 41        LD B,C
$80D5: 56        LD D,(HL)
$80D6: 45        LD B,L
$80D7: 52        LD D,D
$80D8: 45        LD B,L
$80D9: 4E        LD C,(HL)
$80DA: 20 55     JR NZ,8131
$80DC: 53        LD D,E
$80DD: 45        LD B,L
$80DE: 52        LD D,D
$80DF: BD        CP L
$80E0: 16 00     LD D,00
$80E2: 01 4D 40  LD BC,404D
$80E5: 21 C7 95  LD HL,95C7
$80E8: 0E 00     LD C,00
$80EA: 79        LD A,C
$80EB: FE 06     CP 06
$80ED: D0        RET NC
$80EE: 11 87 9B  LD DE,9B87
$80F1: 06 04     LD B,04
$80F3: 1A        LD A,(DE)
$80F4: BE        CP (HL)
$80F5: 20 0B     JR NZ,8102
$80F7: 13        INC DE
$80F8: 23        INC HL
$80F9: 10 F8     DJNZ 80F3
$80FB: 1A        LD A,(DE)
$80FC: FE 20     CP 20
$80FE: 20 05     JR NZ,8105
$8100: 68        LD L,B
$8101: CE F8     ADC A,F8
$8103: 04        INC B
$8104: D0        RET NC
$8105: E5        PUSH HL
$8106: F0        RET P
$8107: CA 68 A9  JP Z,A968
$810A: 40        LD B,B
$810B: 28 4C     JR Z,8159
$810D: 3F        CCF
$810E: BF        CP A
$810F: F0        RET P
$8110: 2A A5 2F  LD HL,(2FA5)
$8113: 8D        ADC A,L
$8114: E3        EX (SP),HL
$8115: 03        INC BC
$8116: AD        XOR L
$8117: E2 03 F0  JP PO,F003
$811A: 08        EX AF,AF'
$811B: C5        PUSH BC
$811C: 2F        CPL
$811D: F0        RET P
$811E: 04        INC B
$811F: A9        XOR C
$8120: 20 D0     JR NZ,80F2
$8122: E8        RET PE
$8123: AD        XOR L
$8124: E1        POP HL
$8125: 03        INC BC
$8126: A8        XOR B
$8127: B9        CP C
$8128: 9E        SBC A,(HL)
$8129: BF        CP A
$812A: C5        PUSH BC
$812B: 2D        DEC L
$812C: D0        RET NC
$812D: 9F        SBC A,A
$812E: 28 90     JR Z,80C0
$8130: 19        ADD HL,DE
$8131: 20 99     JR NZ,80CC
$8133: BA        CP D
$8134: 08        EX AF,AF'
$8135: B0        OR B
$8136: 96        SUB (HL)
$8137: 28 20     JR Z,8159
$8139: D3 BF     OUT (BF),A
$813B: 18 A9     JR 80E6
$813D: 00        NOP
$813E: 24        INC H
$813F: 38 8D     JR C,80CE
$8141: EA 03 AE  JP PE,AE03
$8144: F8        RET M
$8145: 05        DEC B
$8146: BD        CP L
$8147: 88        ADC A,B
$8148: C0        RET NZ
$8149: 60        LD H,B
$814A: 20 00     JR NZ,814C
$814C: BA        CP D
$814D: 90        SUB B
$814E: EC A9 10  CALL PE,10A9
$8151: D0        RET NC
$8152: EC 0A 20  CALL PE,200A
$8155: 5B        LD E,E
$8156: BF        CP A
$8157: 4E        LD C,(HL)
$8158: 78        LD A,B
$8159: 04        INC B
$815A: 60        LD H,B
$815B: 85        ADD A,L
$815C: 2E 20     LD L,20
$815E: 7E        LD A,(HL)
$815F: BF        CP A
$8160: B9        CP C
$8161: 78        LD A,B
$8162: 04        INC B
$8163: 24        INC H
$8164: 35        DEC (HL)
$8165: 30 03     JR NC,816A
$8167: B9        CP C
$8168: F8        RET M
$8169: 04        INC B
$816A: 8D        ADC A,L
$816B: 78        LD A,B
$816C: 04        INC B
$816D: A5        AND L
$816E: 2E 24     LD L,24
$8170: 35        DEC (HL)
$8171: 30 05     JR NC,8178
$8173: 99        SBC A,C
$8174: F8        RET M
$8175: 04        INC B
$8176: 10 03     DJNZ 817B
$8178: 99        SBC A,C
$8179: 78        LD A,B
$817A: 04        INC B
$817B: 4C        LD C,H
$817C: 5F        LD E,A
$817D: BB        CP E
$817E: 8A        ADC A,D
$817F: 4A        LD C,D
$8180: 4A        LD C,D
$8181: 4A        LD C,D
$8182: 4A        LD C,D
$8183: A8        XOR B
$8184: 60        LD H,B
$8185: 48        LD C,B
$8186: AD        XOR L
$8187: E4 03 6A  CALL PO,6A03
$818A: 66        LD H,(HL)
$818B: 35        DEC (HL)
$818C: 20 7E     JR NZ,820C
$818E: BF        CP A
$818F: 68        LD L,B
$8190: 0A        LD A,(BC)
$8191: 24        INC H
$8192: 35        DEC (HL)
$8193: 30 05     JR NC,819A
$8195: 99        SBC A,C
$8196: F8        RET M
$8197: 04        INC B
$8198: 10 03     DJNZ 819D
$819A: 99        SBC A,C
$819B: 78        LD A,B
$819C: 04        INC B
$819D: 60        LD H,B
$819E: 00        NOP
$819F: 02        LD (BC),A
$81A0: 04        INC B
$81A1: 06 08     LD B,08
$81A3: 0A        LD A,(BC)
$81A4: 0C        INC C
$81A5: 0E 01     LD C,01
$81A7: 03        INC BC
$81A8: 05        DEC B
$81A9: 07        RLCA
$81AA: 09        ADD HL,BC
$81AB: 0B        DEC BC
$81AC: 0D        DEC C
$81AD: 0F        RRCA
$81AE: A2        AND D
$81AF: 55        LD D,L
$81B0: A9        XOR C
$81B1: 00        NOP
$81B2: 9D        SBC A,L
$81B3: 00        NOP
$81B4: 0C        INC C
$81B5: CA 10 FA  JP Z,FA10
$81B8: A8        XOR B
$81B9: A2        AND D
$81BA: AC        XOR H
$81BB: 2C        INC L
$81BC: A2        AND D
$81BD: AA        XOR D
$81BE: 88        ADC A,B
$81BF: B1        OR C
$81C0: 3E 4A     LD A,4A
$81C2: 3E 56     LD A,56
$81C4: 0B        DEC BC
$81C5: 4A        LD C,D
$81C6: 3E 56     LD A,56
$81C8: 0B        DEC BC
$81C9: 99        SBC A,C
$81CA: 00        NOP
$81CB: 09        ADD HL,BC
$81CC: E8        RET PE
$81CD: D0        RET NC
$81CE: EF        RST $28
$81CF: 98        SBC A,B
$81D0: D0        RET NC
$81D1: EA 60 A0  JP PE,A060
$81D4: 00        NOP
$81D5: A2        AND D
$81D6: 56        LD D,(HL)
$81D7: CA 30 FB  JP Z,FB30
$81DA: B9        CP C
$81DB: 00        NOP
$81DC: 09        ADD HL,BC
$81DD: 5E        LD E,(HL)
$81DE: 00        NOP
$81DF: 0C        INC C
$81E0: 2A 5E 00  LD HL,(005E)
$81E3: 0C        INC C
$81E4: 2A 91 3E  LD HL,(3E91)
$81E7: C8        RET Z
$81E8: D0        RET NC
$81E9: ED        DB $ED
$81EA: 60        LD H,B
$81EB: 00        NOP
$81EC: 00        NOP
$81ED: 00        NOP
$81EE: 00        NOP
$81EF: 00        NOP
$81F0: 00        NOP
$81F1: 00        NOP
$81F2: 00        NOP
$81F3: 00        NOP
$81F4: 00        NOP
$81F5: 00        NOP
$81F6: 00        NOP
$81F7: 00        NOP
$81F8: 00        NOP
$81F9: 00        NOP
$81FA: 00        NOP
$81FB: 00        NOP
$81FC: 00        NOP
$81FD: 00        NOP
$81FE: 00        NOP
$81FF: 00        NOP
$8200: 79        LD A,C
$8201: C9        RET
$8202: 23        INC HL
$8203: 10 FD     DJNZ 8202
$8205: 0C        INC C
$8206: 18 E2     JR 81EA
$8208: AF        XOR A
$8209: 32 07 93  LD (9307),A
$820C: 31 64 9B  LD SP,9B64
$820F: C5        PUSH BC
$8210: 79        LD A,C
$8211: 1F        RRA
$8212: 1F        RRA
$8213: 1F        RRA
$8214: 1F        RRA
$8215: E6 0F     AND 0F
$8217: 5F        LD E,A
$8218: CD F8 93  CALL 93F8
$821B: CD B2 93  CALL 93B2
$821E: 32 64 9B  LD (9B64),A
$8221: C1        POP BC
$8222: 79        LD A,C
$8223: E6 0F     AND 0F
$8225: 32 A8 9B  LD (9BA8),A
$8228: CD B6 93  CALL 93B6
$822B: 3A 07 93  LD A,(9307)
$822E: B7        OR A
$822F: 20 16     JR NZ,8247
$8231: 31 64 9B  LD SP,9B64
$8234: CD 99 93  CALL 9399
$8237: CD A8 94  CALL 94A8
$823A: C6 41     ADD A,41
$823C: CD 8C 93  CALL 938C
$823F: 3E 3E     LD A,3E
$8241: CD 8C 93  CALL 938C
$8244: CD 1B 94  CALL 941B
$8247: 11 80 00  LD DE,0080
$824A: CD B0 94  CALL 94B0
$824D: CD A8 94  CALL 94A8
$8250: 32 A8 9B  LD (9BA8),A
$8253: CD 2F 95  CALL 952F
$8256: C4 DF 94  CALL NZ,94DF
$8259: 3A A9 9B  LD A,(9BA9)
$825C: B7        OR A
$825D: C2 26 99  JP NZ,9926
$8260: CD E5 95  CALL 95E5
$8263: 21 70 96  LD HL,9670
$8266: 5F        LD E,A
$8267: 16 00     LD D,00
$8269: 19        ADD HL,DE
$826A: 19        ADD HL,DE
$826B: 7E        LD A,(HL)
$826C: 23        INC HL
$826D: 66        LD H,(HL)
$826E: 6F        LD L,A
$826F: E9        JP (HL)
$8270: 18 97     JR 8209
$8272: B1        OR C
$8273: 97        SUB A
$8274: EE 97     XOR 97
$8276: 3A 98 98  LD A,(9898)
$8279: 98        SBC A,B
$827A: 0F        RRCA
$827B: 99        SBC A,C
$827C: 26 99     LD H,99
$827E: 21 F3 76  LD HL,76F3
$8281: 22 00 93  LD (9300),HL
$8284: 21 00 93  LD HL,9300
$8287: E9        JP (HL)
$8288: 01 8E 96  LD BC,968E
$828B: C3 A2 93  JP 93A2

; ============================================================================
; CCP messages and error strings ($828E-$8B69)
;
; Mostly $-terminated CP/M-style strings interspersed with the CCP's
; runtime code (file-name parser, command dispatcher, drive-select
; handler, error-message printer).
; ============================================================================


$828E: 52        LD D,D
$828F: 65        LD H,L
$8290: 61        LD H,C
$8291: 64        LD H,H
$8292: 20 65     JR NZ,82F9
$8294: 72        LD (HL),D
$8295: 72        LD (HL),D
$8296: 6F        LD L,A
$8297: 72        LD (HL),D
$8298: 00        NOP
$8299: 01 9F 96  LD BC,969F
$829C: C3 A2 93  JP 93A2
$829F: 4E        LD C,(HL)
$82A0: 6F        LD L,A
$82A1: 20 66     JR NZ,8309
$82A3: 69        LD L,C
$82A4: 6C        LD L,H
$82A5: 65        LD H,L
$82A6: 00        NOP
$82A7: CD 2F 95  CALL 952F
$82AA: 3A A9 9B  LD A,(9BA9)
$82AD: B7        OR A
$82AE: C2 DF 94  JP NZ,94DF
$82B1: 21 87 9B  LD HL,9B87
$82B4: 01 0B 00  LD BC,000B
$82B7: 7E        LD A,(HL)
$82B8: FE 20     CP 20
$82BA: 28 24     JR Z,82E0
$82BC: 23        INC HL
$82BD: D6 30     SUB 30
$82BF: FE 0A     CP 0A
$82C1: D2 DF 94  JP NC,94DF
$82C4: 57        LD D,A
$82C5: 78        LD A,B
$82C6: E6 E0     AND E0
$82C8: C2 DF 94  JP NZ,94DF
$82CB: 78        LD A,B
$82CC: 07        RLCA
$82CD: 07        RLCA
$82CE: 07        RLCA
$82CF: 80        ADD A,B
$82D0: DA DF 94  JP C,94DF
$82D3: 80        ADD A,B
$82D4: DA DF 94  JP C,94DF
$82D7: 82        ADD A,D
$82D8: DA DF 94  JP C,94DF
$82DB: 47        LD B,A
$82DC: 0D        DEC C
$82DD: 20 D8     JR NZ,82B7
$82DF: C9        RET
$82E0: 7E        LD A,(HL)
$82E1: FE 20     CP 20
$82E3: C2 DF 94  JP NZ,94DF
$82E6: 23        INC HL
$82E7: 0D        DEC C
$82E8: 20 F6     JR NZ,82E0
$82EA: 78        LD A,B
$82EB: C9        RET
$82EC: 21 80 00  LD HL,0080
$82EF: 81        ADD A,C
$82F0: CD 2A 95  CALL 952A
$82F3: 7E        LD A,(HL)
$82F4: C9        RET
$82F5: AF        XOR A
$82F6: 32 86 9B  LD (9B86),A
$82F9: 3A A9 9B  LD A,(9BA9)
$82FC: B7        OR A
$82FD: C8        RET Z
$82FE: 3D        DEC A
$82FF: 21 AD 81  LD HL,81AD
$8302: C0        RET NZ
$8303: AD        XOR L
$8304: 81        ADD A,C
$8305: C0        RET NZ
$8306: 8A        ADC A,D
$8307: 4A        LD C,D
$8308: 4A        LD C,D
$8309: 4A        LD C,D
$830A: 4A        LD C,D
$830B: A8        XOR B
$830C: 48        LD C,B
$830D: 9D        SBC A,L
$830E: 88        ADC A,B
$830F: C0        RET NZ
$8310: A9        XOR C
$8311: 00        NOP
$8312: 99        SBC A,C
$8313: 78        LD A,B
$8314: 04        INC B
$8315: 99        SBC A,C
$8316: F8        RET M
$8317: 04        INC B
$8318: 20 2F     JR NZ,8349
$831A: FB        EI
$831B: 20 93     JR NZ,82B0
$831D: FE 20     CP 20
$831F: 89        ADC A,C
$8320: FE 68     CP 68
$8322: A2        AND D
$8323: FF        RST $38
$8324: 9A        SBC A,D
$8325: C9        RET
$8326: 06 F0     LD B,F0
$8328: 10 A0     DJNZ 82CA
$832A: 00        NOP
$832B: B9        CP C
$832C: 92        SUB D
$832D: 11 F0 06  LD DE,06F0
$8330: 20 ED     JR NZ,831F
$8332: FD        DB $FD
$8333: C8        RET Z
$8334: D0        RET NC
$8335: F5        PUSH AF
$8336: 4C        LD C,H
$8337: 65        LD H,L
$8338: FF        RST $38
$8339: A0        AND B
$833A: 0E B9     LD C,B9
$833C: B0        OR B
$833D: 11 99 FF  LD DE,FF99
$8340: 0F        RRCA
$8341: 88        ADC A,B
$8342: D0        RET NC
$8343: F7        RST $30
$8344: B9        CP C
$8345: 00        NOP
$8346: 12        LD (DE),A
$8347: 99        SBC A,C
$8348: 00        NOP
$8349: 02        LD (BC),A
$834A: 88        ADC A,B
$834B: D0        RET NC
$834C: F7        RST $30
$834D: A0        AND B
$834E: F1        POP AF
$834F: B9        CP C
$8350: FF        RST $38
$8351: 12        LD (DE),A
$8352: 99        SBC A,C
$8353: FF        RST $38
$8354: 02        LD (BC),A
$8355: 88        ADC A,B
$8356: D0        RET NC
$8357: F7        RST $30
$8358: 8C        ADC A,H
$8359: B8        CP B
$835A: 03        INC BC
$835B: 84        ADD A,H
$835C: 3C        INC A
$835D: 88        ADC A,B
$835E: 84        ADD A,H
$835F: 3E A0     LD A,A0
$8361: C7        RST $00
$8362: 84        ADD A,H
$8363: 3D        DEC A
$8364: 8C        ADC A,H
$8365: 69        LD L,C
$8366: 10 8D     DJNZ 82F5
$8368: 00        NOP
$8369: C0        RET NZ
$836A: A5        AND L
$836B: 3E F0     LD A,F0
$836D: 18 20     JR 838F
$836F: 4E        LD C,(HL)
$8370: 11 85 40  LD DE,4085
$8373: 86        ADD A,(HL)
$8374: 41        LD B,C
$8375: 20 4E     JR NZ,83C5
$8377: 11 E0 00  LD DE,00E0
$837A: F0        RET P
$837B: 1E C5     LD E,C5
$837D: 40        LD B,B
$837E: D0        RET NC
$837F: 1A        LD A,(DE)
$8380: E4 41 F0  CALL PO,F041
$8383: 1A        LD A,(DE)
$8384: D0        RET NC
$8385: 14        INC D
$8386: E6 3E     AND 3E
$8388: 8C        ADC A,H
$8389: C8        RET Z
$838A: 03        INC BC
$838B: A9        XOR C
$838C: 00        NOP
$838D: 8D        ADC A,L
$838E: C7        RST $00
$838F: 03        INC BC
$8390: 8D        ADC A,L
$8391: DE 03     SBC A,03
$8393: 98        SBC A,B
$8394: 18 69     JR 83FF
$8396: 20 8D     JR NZ,8325
$8398: DF        RST $18
$8399: 03        INC BC
$839A: A2        AND D
$839B: 00        NOP
$839C: F0        RET P
$839D: 2D        DEC L
$839E: A2        AND D
$839F: 04        INC B
$83A0: A0        AND B
$83A1: 05        DEC B
$83A2: B1        OR C
$83A3: 3C        INC A
$83A4: DD        DB $DD
$83A5: BE        CP (HL)
$83A6: 11 D0 09  LD DE,09D0
$83A9: A0        AND B
$83AA: 07        RLCA
$83AB: B1        OR C
$83AC: 3C        INC A
$83AD: DD        DB $DD
$83AE: C2 11 F0  JP NZ,F011
$83B1: 03        INC BC
$83B2: CA D0 EB  JP Z,EBD0
$83B5: E8        RET PE
$83B6: E0        RET PO
$83B7: 02        LD (BC),A
$83B8: D0        RET NC
$83B9: 03        INC BC
$83BA: EE B8     XOR B8
$83BC: 03        INC BC
$83BD: E0        RET PO
$83BE: 04        INC B
$83BF: D0        RET NC
$83C0: 0A        LD A,(BC)
$83C1: A0        AND B
$83C2: 0B        DEC BC
$83C3: B1        OR C
$83C4: 3C        INC A
$83C5: C9        RET
$83C6: 01 D0 02  LD BC,02D0
$83C9: A2        AND D
$83CA: 06 A4     LD B,A4
$83CC: 3D        DEC A
$83CD: 8A        ADC A,D
$83CE: 99        SBC A,C
$83CF: F8        RET M
$83D0: 02        LD (BC),A
$83D1: 88        ADC A,B
$83D2: C0        RET NZ
$83D3: C0        RET NZ
$83D4: D0        RET NC
$83D5: 8C        ADC A,H
$83D6: 0E B8     LD C,B8
$83D8: 03        INC BC
$83D9: A5        AND L
$83DA: 3E C9     LD A,C9
$83DC: 01 F0 10  LD BC,10F0
$83DF: A0        AND B
$83E0: 00        NOP
$83E1: B9        CP C
$83E2: 73        LD (HL),E
$83E3: 11 F0 06  LD DE,06F0
$83E6: 20 ED     JR NZ,83D5
$83E8: FD        DB $FD
$83E9: C8        RET Z
$83EA: D0        RET NC
$83EB: F5        PUSH AF
$83EC: 4C        LD C,H
$83ED: 65        LD H,L
$83EE: FF        RST $38
$83EF: A0        AND B
$83F0: 10 B9     DJNZ 83AB
$83F2: EF        RST $28
$83F3: 13        INC DE
$83F4: 99        SBC A,C
$83F5: EF        RST $28
$83F6: 03        INC BC
$83F7: 88        ADC A,B
$83F8: D0        RET NC
$83F9: F7        RST $30
$83FA: A9        XOR C
$83FB: C3 8D 00  JP 008D
$83FE: 10 A9     DJNZ 83A9
$8400: A8        XOR B
$8401: 9B        SBC A,E
$8402: BE        CP (HL)
$8403: C8        RET Z
$8404: C3 B6 93  JP 93B6
$8407: 3A A9 9B  LD A,(9BA9)
$840A: B7        OR A
$840B: C8        RET Z
$840C: 3D        DEC A
$840D: 21 A8 9B  LD HL,9BA8
$8410: BE        CP (HL)
$8411: C8        RET Z
$8412: 3A A8 9B  LD A,(9BA8)
$8415: C3 B6 93  JP 93B6
$8418: CD 2F 95  CALL 952F
$841B: CD F5 96  CALL 96F5
$841E: 21 87 9B  LD HL,9B87
$8421: 7E        LD A,(HL)
$8422: FE 20     CP 20
$8424: 20 07     JR NZ,842D
$8426: 06 0B     LD B,0B
$8428: 36 3F     LD (HL),3F
$842A: 23        INC HL
$842B: 10 FB     DJNZ 8428
$842D: 1E 00     LD E,00
$842F: D5        PUSH DE
$8430: CD D1 93  CALL 93D1
$8433: CC 99 96  CALL Z,9699
$8436: 28 75     JR Z,84AD
$8438: 3A A7 9B  LD A,(9BA7)
$843B: 0F        RRCA
$843C: 0F        RRCA
$843D: 0F        RRCA
$843E: E6 60     AND 60
$8440: 4F        LD C,A
$8441: 3E 0A     LD A,0A
$8443: CD EC 96  CALL 96EC
$8446: 17        RLA
$8447: 38 5A     JR C,84A3
$8449: D1        POP DE
$844A: 7B        LD A,E
$844B: 1C        INC E
$844C: D5        PUSH DE
$844D: E6 03     AND 03
$844F: F5        PUSH AF
$8450: 20 14     JR NZ,8466
$8452: CD 99 93  CALL 9399
$8455: C5        PUSH BC
$8456: CD A8 94  CALL 94A8
$8459: C1        POP BC
$845A: C6 41     ADD A,41
$845C: CD 93 93  CALL 9393
$845F: 3E 3A     LD A,3A
$8461: CD 93 93  CALL 9393
$8464: 18 08     JR 846E
$8466: CD 91 93  CALL 9391
$8469: 3E 3A     LD A,3A
$846B: CD 93 93  CALL 9393
$846E: CD 91 93  CALL 9391
$8471: 06 01     LD B,01
$8473: 78        LD A,B
$8474: CD EC 96  CALL 96EC
$8477: E6 7F     AND 7F
$8479: FE 20     CP 20
$847B: 20 13     JR NZ,8490
$847D: F1        POP AF
$847E: F5        PUSH AF
$847F: FE 03     CP 03
$8481: 20 0B     JR NZ,848E
$8483: 3E 09     LD A,09
$8485: CD EC 96  CALL 96EC
$8488: E6 7F     AND 7F
$848A: FE 20     CP 20
$848C: 28 14     JR Z,84A2
$848E: 3E 20     LD A,20
$8490: CD 93 93  CALL 9393
$8493: 04        INC B
$8494: 78        LD A,B
$8495: FE 0C     CP 0C
$8497: 30 09     JR NC,84A2
$8499: FE 09     CP 09
$849B: 20 D6     JR NZ,8473
$849D: CD 91 93  CALL 9391
$84A0: 18 D1     JR 8473
$84A2: F1        POP AF
$84A3: CD 9A 94  CALL 949A
$84A6: 20 05     JR NZ,84AD
$84A8: CD D8 93  CALL 93D8
$84AB: 18 89     JR 8436
$84AD: D1        POP DE
$84AE: C3 38 9A  JP 9A38
$84B1: CD 2F 95  CALL 952F
$84B4: FE 0B     CP 0B
$84B6: 20 1B     JR NZ,84D3
$84B8: 01 E3 97  LD BC,97E3
$84BB: CD A2 93  CALL 93A2
$84BE: CD 1B 94  CALL 941B
$84C1: 21 07 93  LD HL,9307
$84C4: 35        DEC (HL)
$84C5: C2 31 96  JP NZ,9631
$84C8: 23        INC HL
$84C9: 7E        LD A,(HL)
$84CA: FE 59     CP 59
$84CC: C2 31 96  JP NZ,9631
$84CF: 23        INC HL
$84D0: 22 88 93  LD (9388),HL
$84D3: CD F5 96  CALL 96F5
$84D6: 11 86 9B  LD DE,9B86
$84D9: CD DC 93  CALL 93DC
$84DC: 3C        INC A
$84DD: CC 99 96  CALL Z,9699
$84E0: C3 38 9A  JP 9A38
$84E3: 41        LD B,C
$84E4: 6C        LD L,H
$84E5: 6C        LD L,H
$84E6: 20 28     JR NZ,8510
$84E8: 79        LD A,C
$84E9: 2F        CPL
$84EA: 6E        LD L,(HL)
$84EB: 29        ADD HL,HL
$84EC: 3F        CCF
$84ED: 00        NOP
$84EE: CD 2F 95  CALL 952F
$84F1: C2 DF 94  JP NZ,94DF
$84F4: CD F5 96  CALL 96F5
$84F7: CD C6 93  CALL 93C6
$84FA: 28 38     JR Z,8534
$84FC: CD 99 93  CALL 9399
$84FF: 21 AA 9B  LD HL,9BAA
$8502: 36 FF     LD (HL),FF
$8504: 21 AA 9B  LD HL,9BAA
$8507: 7E        LD A,(HL)
$8508: FE 80     CP 80
$850A: 38 09     JR C,8515
$850C: E5        PUSH HL
$850D: CD E0 93  CALL 93E0
$8510: E1        POP HL
$8511: 20 1A     JR NZ,852D
$8513: AF        XOR A
$8514: 77        LD (HL),A
$8515: 34        INC (HL)
$8516: 21 80 00  LD HL,0080
$8519: CD 2A 95  CALL 952A
$851C: 7E        LD A,(HL)
$851D: FE 1A     CP 1A
$851F: CA 38 9A  JP Z,9A38
$8522: CD 8C 93  CALL 938C
$8525: CD 9A 94  CALL 949A
$8528: C2 38 9A  JP NZ,9A38
$852B: 18 D7     JR 8504
$852D: 3D        DEC A
$852E: CA 38 9A  JP Z,9A38
$8531: CD 88 96  CALL 9688
$8534: CD 07 97  CALL 9707
$8537: C3 DF 94  JP 94DF
$853A: CD A7 96  CALL 96A7
$853D: F5        PUSH AF
$853E: CD 2F 95  CALL 952F
$8541: C2 DF 94  JP NZ,94DF
$8544: CD F5 96  CALL 96F5
$8547: 11 86 9B  LD DE,9B86
$854A: D5        PUSH DE
$854B: CD DC 93  CALL 93DC
$854E: D1        POP DE
$854F: CD EE 93  CALL 93EE
$8552: 28 2F     JR Z,8583
$8554: AF        XOR A
$8555: 32 A6 9B  LD (9BA6),A
$8558: F1        POP AF
$8559: 6F        LD L,A
$855A: 26 00     LD H,00
$855C: 29        ADD HL,HL
$855D: 11 00 01  LD DE,0100
$8560: 7C        LD A,H
$8561: B5        OR L
$8562: 28 16     JR Z,857A
$8564: 2B        DEC HL
$8565: E5        PUSH HL
$8566: 21 80 00  LD HL,0080
$8569: 19        ADD HL,DE
$856A: E5        PUSH HL
$856B: CD B0 94  CALL 94B0
$856E: 11 86 9B  LD DE,9B86
$8571: CD EA 93  CALL 93EA
$8574: D1        POP DE
$8575: E1        POP HL
$8576: 20 0B     JR NZ,8583
$8578: 18 E6     JR 8560
$857A: 11 86 9B  LD DE,9B86
$857D: CD BC 93  CALL 93BC
$8580: 3C        INC A
$8581: 20 06     JR NZ,8589
$8583: 01 8F 98  LD BC,988F
$8586: CD A2 93  CALL 93A2
$8589: CD AD 94  CALL 94AD
$858C: C3 38 9A  JP 9A38
$858F: 4E        LD C,(HL)
$8590: 6F        LD L,A
$8591: 20 73     JR NZ,8606
$8593: 70        LD (HL),B
$8594: 61        LD H,C
$8595: 63        LD H,E
$8596: 65        LD H,L
$8597: 00        NOP
$8598: CD 2F 95  CALL 952F
$859B: C2 DF 94  JP NZ,94DF
$859E: 3A A9 9B  LD A,(9BA9)
$85A1: F5        PUSH AF
$85A2: CD F5 96  CALL 96F5
$85A5: CD D1 93  CALL 93D1
$85A8: 20 50     JR NZ,85FA
$85AA: 21 86 9B  LD HL,9B86
$85AD: 11 96 9B  LD DE,9B96
$85B0: 01 10 00  LD BC,0010
$85B3: ED        DB $ED
$85B4: B0        OR B
$85B5: 2A 88 93  LD HL,(9388)
$85B8: EB        EX DE,HL
$85B9: CD 21 95  CALL 9521
$85BC: FE 3D     CP 3D
$85BE: 28 04     JR Z,85C4
$85C0: FE 5F     CP 5F
$85C2: 20 30     JR NZ,85F4
$85C4: EB        EX DE,HL
$85C5: 23        INC HL
$85C6: 22 88 93  LD (9388),HL
$85C9: CD 2F 95  CALL 952F
$85CC: 20 26     JR NZ,85F4
$85CE: F1        POP AF
$85CF: 47        LD B,A
$85D0: 21 A9 9B  LD HL,9BA9
$85D3: 7E        LD A,(HL)
$85D4: B7        OR A
$85D5: 28 04     JR Z,85DB
$85D7: B8        CP B
$85D8: 70        LD (HL),B
$85D9: 20 19     JR NZ,85F4
$85DB: 70        LD (HL),B
$85DC: AF        XOR A
$85DD: 32 86 9B  LD (9B86),A
$85E0: CD D1 93  CALL 93D1
$85E3: 28 09     JR Z,85EE
$85E5: 11 86 9B  LD DE,9B86
$85E8: CD F2 93  CALL 93F2
$85EB: C3 38 9A  JP 9A38
$85EE: CD 99 96  CALL 9699
$85F1: C3 38 9A  JP 9A38
$85F4: CD 07 97  CALL 9707
$85F7: C3 DF 94  JP 94DF
$85FA: 01 03 99  LD BC,9903
$85FD: CD A2 93  CALL 93A2
$8600: 0F        RRCA
$8601: A0        AND B
$8602: 79        LD A,C
$8603: 95        SUB L
$8604: 78        LD A,B
$8605: 9C        SBC A,H
$8606: DA 0F A0  JP C,A00F
$8609: EB        EX DE,HL
$860A: E1        POP HL
$860B: 23        INC HL
$860C: C3 FA 9F  JP 9FFA
$860F: E1        POP HL
$8610: C5        PUSH BC
$8611: D5        PUSH DE
$8612: E5        PUSH HL
$8613: EB        EX DE,HL
$8614: 2A CE A9  LD HL,(A9CE)
$8617: 19        ADD HL,DE
$8618: 44        LD B,H
$8619: 4D        LD C,L
$861A: CD 1E FA  CALL FA1E
$861D: D1        POP DE
$861E: 2A B5 A9  LD HL,(A9B5)
$8621: 73        LD (HL),E
$8622: 23        INC HL
$8623: 72        LD (HL),D
$8624: D1        POP DE
$8625: 2A B7 A9  LD HL,(A9B7)
$8628: 73        LD (HL),E
$8629: 23        INC HL
$862A: 72        LD (HL),D
$862B: C1        POP BC
$862C: 79        LD A,C
$862D: 93        SUB E
$862E: 4F        LD C,A
$862F: 78        LD A,B
$8630: 9A        SBC A,D
$8631: 47        LD B,A
$8632: 2A D0 A9  LD HL,(A9D0)
$8635: EB        EX DE,HL
$8636: CD 30 FA  CALL FA30
$8639: 4D        LD C,L
$863A: 44        LD B,H
$863B: C3 21 FA  JP FA21
$863E: 21 C3 A9  LD HL,A9C3
$8641: 4E        LD C,(HL)
$8642: 3A E3 A9  LD A,(A9E3)
$8645: B7        OR A
$8646: 1F        RRA
$8647: 0D        DEC C
$8648: C2 45 A0  JP NZ,A045
$864B: 47        LD B,A
$864C: 3E 08     LD A,08
$864E: 96        SUB (HL)
$864F: 4F        LD C,A
$8650: 3A E2 A9  LD A,(A9E2)
$8653: 0D        DEC C
$8654: CA 5C A0  JP Z,A05C
$8657: B7        OR A
$8658: 17        RLA
$8659: C3 53 A0  JP A053
$865C: 80        ADD A,B
$865D: C9        RET
$865E: 2A 43 9F  LD HL,(9F43)
$8661: 11 10 00  LD DE,0010
$8664: 19        ADD HL,DE
$8665: 09        ADD HL,BC
$8666: 3A DD A9  LD A,(A9DD)
$8669: B7        OR A
$866A: CA 71 A0  JP Z,A071
$866D: 6E        LD L,(HL)
$866E: 26 00     LD H,00
$8670: C9        RET
$8671: 09        ADD HL,BC
$8672: 5E        LD E,(HL)
$8673: 23        INC HL
$8674: 56        LD D,(HL)
$8675: EB        EX DE,HL
$8676: C9        RET
$8677: CD 3E A0  CALL A03E
$867A: 4F        LD C,A
$867B: 06 00     LD B,00
$867D: CD 5E A0  CALL A05E
$8680: 22 E5 A9  LD (A9E5),HL
$8683: C9        RET
$8684: 2A E5 A9  LD HL,(A9E5)
$8687: 7D        LD A,L
$8688: B4        OR H
$8689: C9        RET
$868A: 3A C3 A9  LD A,(A9C3)
$868D: 2A E5 A9  LD HL,(A9E5)
$8690: 29        ADD HL,HL
$8691: 3D        DEC A
$8692: C2 90 A0  JP NZ,A090
$8695: 22 E7 A9  LD (A9E7),HL
$8698: 3A C4 A9  LD A,(A9C4)
$869B: 4F        LD C,A
$869C: 3A E3 A9  LD A,(A9E3)
$869F: A1        AND C
$86A0: B5        OR L
$86A1: 6F        LD L,A
$86A2: 22 E5 A9  LD (A9E5),HL
$86A5: C9        RET
$86A6: 2A 43 9F  LD HL,(9F43)
$86A9: 11 0C 00  LD DE,000C
$86AC: 19        ADD HL,DE
$86AD: C9        RET
$86AE: 2A 43 9F  LD HL,(9F43)
$86B1: 11 0F 00  LD DE,000F
$86B4: 19        ADD HL,DE
$86B5: EB        EX DE,HL
$86B6: 21 11 00  LD HL,0011
$86B9: 19        ADD HL,DE
$86BA: C9        RET
$86BB: CD AE A0  CALL A0AE
$86BE: 7E        LD A,(HL)
$86BF: 32 E3 A9  LD (A9E3),A
$86C2: EB        EX DE,HL
$86C3: 7E        LD A,(HL)
$86C4: 32 E1 A9  LD (A9E1),A
$86C7: CD A6 A0  CALL A0A6
$86CA: 3A C5 A9  LD A,(A9C5)
$86CD: A6        AND (HL)
$86CE: 32 E2 A9  LD (A9E2),A
$86D1: C9        RET
$86D2: CD AE A0  CALL A0AE
$86D5: 3A D5 A9  LD A,(A9D5)
$86D8: FE 02     CP 02
$86DA: C2 DE A0  JP NZ,A0DE
$86DD: AF        XOR A
$86DE: 4F        LD C,A
$86DF: 3A E3 A9  LD A,(A9E3)
$86E2: 81        ADD A,C
$86E3: 77        LD (HL),A
$86E4: EB        EX DE,HL
$86E5: 3A E1 A9  LD A,(A9E1)
$86E8: 77        LD (HL),A
$86E9: C9        RET
$86EA: 0C        INC C
$86EB: 0D        DEC C
$86EC: C8        RET Z
$86ED: 7C        LD A,H
$86EE: B7        OR A
$86EF: 1F        RRA
$86F0: 67        LD H,A
$86F1: 7D        LD A,L
$86F2: 1F        RRA
$86F3: 6F        LD L,A
$86F4: C3 EB A0  JP A0EB
$86F7: 0E 80     LD C,80
$86F9: 2A B9 A9  LD HL,(A9B9)
$86FC: AF        XOR A
$86FD: 86        ADD A,(HL)
$86FE: 23        INC HL
$86FF: 0D        DEC C
$8700: C3 38 9A  JP 9A38
$8703: 46        LD B,(HL)
$8704: 69        LD L,C
$8705: 6C        LD L,H
$8706: 65        LD H,L
$8707: 20 65     JR NZ,876E
$8709: 78        LD A,B
$870A: 69        LD L,C
$870B: 73        LD (HL),E
$870C: 74        LD (HL),H
$870D: 73        LD (HL),E
$870E: 00        NOP
$870F: CD A7 96  CALL 96A7
$8712: FE 10     CP 10
$8714: D2 DF 94  JP NC,94DF
$8717: 5F        LD E,A
$8718: 3A 87 9B  LD A,(9B87)
$871B: FE 20     CP 20
$871D: CA DF 94  JP Z,94DF
$8720: CD F8 93  CALL 93F8
$8723: C3 3B 9A  JP 9A3B
$8726: CD CD 94  CALL 94CD
$8729: 3A 87 9B  LD A,(9B87)
$872C: FE 20     CP 20
$872E: 20 16     JR NZ,8746
$8730: 3A A9 9B  LD A,(9BA9)
$8733: B7        OR A
$8734: CA 3B 9A  JP Z,9A3B
$8737: 3D        DEC A
$8738: F5        PUSH AF
$8739: CD B6 93  CALL 93B6
$873C: F1        POP AF
$873D: 32 A8 9B  LD (9BA8),A
$8740: CD 0B 94  CALL 940B
$8743: C3 3B 9A  JP 9A3B
$8746: CD F6 93  CALL 93F6
$8749: 32 43 9B  LD (9B43),A
$874C: 11 8F 9B  LD DE,9B8F
$874F: 1A        LD A,(DE)
$8750: FE 20     CP 20
$8752: C2 DF 94  JP NZ,94DF
$8755: D5        PUSH DE
$8756: CD F5 96  CALL 96F5
$8759: D1        POP DE
$875A: 21 35 9A  LD HL,9A35
$875D: 01 03 00  LD BC,0003
$8760: ED        DB $ED
$8761: B0        OR B
$8762: CD C6 93  CALL 93C6
$8765: 20 0D     JR NZ,8774
$8767: CD F6 93  CALL 93F6
$876A: B7        OR A
$876B: CA 1B 9A  JP Z,9A1B
$876E: AF        XOR A
$876F: CD 50 9A  CALL 9A50
$8772: 18 EE     JR 8762
$8774: 3A 86 9B  LD A,(9B86)
$8777: B7        OR A
$8778: 28 04     JR Z,877E
$877A: 3D        DEC A
$877B: CD B6 93  CALL 93B6
$877E: 0E 1F     LD C,1F
$8780: CD 05 00  CALL 0005
$8783: 23        INC HL
$8784: 23        INC HL
$8785: 7E        LD A,(HL)
$8786: FE 03     CP 03
$8788: 20 09     JR NZ,8793
$878A: 23        INC HL
$878B: 23        INC HL
$878C: 23        INC HL
$878D: 7E        LD A,(HL)
$878E: FE 8B     CP 8B
$8790: CA 54 9A  JP Z,9A54
$8793: 21 00 01  LD HL,0100
$8796: E5        PUSH HL
$8797: EB        EX DE,HL
$8798: CD B0 94  CALL 94B0
$879B: 11 86 9B  LD DE,9B86
$879E: CD E3 93  CALL 93E3
$87A1: 20 11     JR NZ,87B4
$87A3: E1        POP HL
$87A4: 11 80 00  LD DE,0080
$87A7: 19        ADD HL,DE
$87A8: 11 00 93  LD DE,9300
$87AB: B7        OR A
$87AC: E5        PUSH HL
$87AD: ED        DB $ED
$87AE: 52        LD D,D
$87AF: E1        POP HL
$87B0: 30 72     JR NC,8824
$87B2: 18 E2     JR 8796
$87B4: E1        POP HL
$87B5: 3D        DEC A
$87B6: 20 6C     JR NZ,8824
$87B8: CD 4D 9A  CALL 9A4D
$87BB: CD 07 97  CALL 9707
$87BE: CD 2F 95  CALL 952F
$87C1: 21 A9 9B  LD HL,9BA9
$87C4: E5        PUSH HL
$87C5: 7E        LD A,(HL)
$87C6: 32 86 9B  LD (9B86),A
$87C9: 3E 10     LD A,10
$87CB: CD 31 95  CALL 9531
$87CE: E1        POP HL
$87CF: 7E        LD A,(HL)
$87D0: 32 96 9B  LD (9B96),A
$87D3: AF        XOR A
$87D4: 32 A6 9B  LD (9BA6),A
$87D7: 11 5C 00  LD DE,005C
$87DA: 21 86 9B  LD HL,9B86
$87DD: 01 21 00  LD BC,0021
$87E0: ED        DB $ED
$87E1: B0        OR B
$87E2: 21 08 93  LD HL,9308
$87E5: 7E        LD A,(HL)
$87E6: B7        OR A
$87E7: 28 07     JR Z,87F0
$87E9: FE 20     CP 20
$87EB: 28 03     JR Z,87F0
$87ED: 23        INC HL
$87EE: 18 F5     JR 87E5
$87F0: 06 00     LD B,00
$87F2: 11 81 00  LD DE,0081
$87F5: 7E        LD A,(HL)
$87F6: 12        LD (DE),A
$87F7: B7        OR A
$87F8: 28 05     JR Z,87FF
$87FA: 04        INC B
$87FB: 23        INC HL
$87FC: 13        INC DE
$87FD: 18 F6     JR 87F5
$87FF: 78        LD A,B
$8800: C2 FD A0  JP NZ,A0FD
$8803: C9        RET
$8804: 0C        INC C
$8805: 0D        DEC C
$8806: C8        RET Z
$8807: 29        ADD HL,HL
$8808: C3 05 A1  JP A105
$880B: C5        PUSH BC
$880C: 3A 42 9F  LD A,(9F42)
$880F: 4F        LD C,A
$8810: 21 01 00  LD HL,0001
$8813: CD 04 A1  CALL A104
$8816: C1        POP BC
$8817: 79        LD A,C
$8818: B5        OR L
$8819: 6F        LD L,A
$881A: 78        LD A,B
$881B: B4        OR H
$881C: 67        LD H,A
$881D: C9        RET
$881E: 2A AD A9  LD HL,(A9AD)
$8821: 3A 42 9F  LD A,(9F42)
$8824: 4F        LD C,A
$8825: CD EA A0  CALL A0EA
$8828: 7D        LD A,L
$8829: E6 01     AND 01
$882B: C9        RET
$882C: 21 AD A9  LD HL,A9AD
$882F: 4E        LD C,(HL)
$8830: 23        INC HL
$8831: 46        LD B,(HL)
$8832: CD 0B A1  CALL A10B
$8835: 22 AD A9  LD (A9AD),HL
$8838: 2A C8 A9  LD HL,(A9C8)
$883B: 23        INC HL
$883C: EB        EX DE,HL
$883D: 2A B3 A9  LD HL,(A9B3)
$8840: 73        LD (HL),E
$8841: 23        INC HL
$8842: 72        LD (HL),D
$8843: C9        RET
$8844: CD 5E A1  CALL A15E
$8847: 11 09 00  LD DE,0009
$884A: 19        ADD HL,DE
$884B: 7E        LD A,(HL)
$884C: 17        RLA
$884D: D0        RET NC
$884E: 21 0F 9C  LD HL,9C0F
$8851: C3 4A 9F  JP 9F4A
$8854: CD 1E A1  CALL A11E
$8857: C8        RET Z
$8858: 21 0D 9C  LD HL,9C0D
$885B: C3 4A 9F  JP 9F4A
$885E: 2A B9 A9  LD HL,(A9B9)
$8861: 3A E9 A9  LD A,(A9E9)
$8864: 85        ADD A,L
$8865: 6F        LD L,A
$8866: D0        RET NC
$8867: 24        INC H
$8868: C9        RET
$8869: 2A 43 9F  LD HL,(9F43)
$886C: 11 0E 00  LD DE,000E
$886F: 19        ADD HL,DE
$8870: 7E        LD A,(HL)
$8871: C9        RET
$8872: CD 69 A1  CALL A169
$8875: 36 00     LD (HL),00
$8877: C9        RET
$8878: CD 69 A1  CALL A169
$887B: F6 80     OR 80
$887D: 77        LD (HL),A
$887E: C9        RET
$887F: 2A EA A9  LD HL,(A9EA)
$8882: EB        EX DE,HL
$8883: 2A B3 A9  LD HL,(A9B3)
$8886: 7B        LD A,E
$8887: 96        SUB (HL)
$8888: 23        INC HL
$8889: 7A        LD A,D
$888A: 9E        SBC A,(HL)
$888B: C9        RET
$888C: CD 7F A1  CALL A17F
$888F: D8        RET C
$8890: 13        INC DE
$8891: 72        LD (HL),D
$8892: 2B        DEC HL
$8893: 73        LD (HL),E
$8894: C9        RET
$8895: 7B        LD A,E
$8896: 95        SUB L
$8897: 6F        LD L,A
$8898: 7A        LD A,D
$8899: 9C        SBC A,H
$889A: 67        LD H,A
$889B: C9        RET
$889C: 0E FF     LD C,FF
$889E: 2A EC A9  LD HL,(A9EC)
$88A1: EB        EX DE,HL
$88A2: 2A CC A9  LD HL,(A9CC)
$88A5: CD 95 A1  CALL A195
$88A8: D0        RET NC
$88A9: C5        PUSH BC
$88AA: CD F7 A0  CALL A0F7
$88AD: 2A BD A9  LD HL,(A9BD)
$88B0: EB        EX DE,HL
$88B1: 2A EC A9  LD HL,(A9EC)
$88B4: 19        ADD HL,DE
$88B5: C1        POP BC
$88B6: 0C        INC C
$88B7: CA C4 A1  JP Z,A1C4
$88BA: BE        CP (HL)
$88BB: C8        RET Z
$88BC: CD 7F A1  CALL A17F
$88BF: D0        RET NC
$88C0: CD 2C A1  CALL A12C
$88C3: C9        RET
$88C4: 77        LD (HL),A
$88C5: C9        RET
$88C6: CD 9C A1  CALL A19C
$88C9: CD E0 A1  CALL A1E0
$88CC: 0E 01     LD C,01
$88CE: CD B8 9F  CALL 9FB8
$88D1: C3 DA A1  JP A1DA
$88D4: CD E0 A1  CALL A1E0
$88D7: CD B2 9F  CALL 9FB2
$88DA: 21 B1 A9  LD HL,A9B1
$88DD: C3 E3 A1  JP A1E3
$88E0: 21 B9 A9  LD HL,A9B9
$88E3: 4E        LD C,(HL)
$88E4: 23        INC HL
$88E5: 46        LD B,(HL)
$88E6: C3 24 FA  JP FA24
$88E9: 2A B9 A9  LD HL,(A9B9)
$88EC: EB        EX DE,HL
$88ED: 2A B1 A9  LD HL,(A9B1)
$88F0: 0E 80     LD C,80
$88F2: C3 4F 9F  JP 9F4F
$88F5: 21 EA A9  LD HL,A9EA
$88F8: 7E        LD A,(HL)
$88F9: 23        INC HL
$88FA: BE        CP (HL)
$88FB: C0        RET NZ
$88FC: 3C        INC A
$88FD: C9        RET
$88FE: 21 FF 32  LD HL,32FF
$8901: 80        ADD A,B
$8902: 00        NOP
$8903: CD 99 93  CALL 9399
$8906: CD AD 94  CALL 94AD
$8909: CD FC 93  CALL 93FC
$890C: CD 00 01  CALL 0100
$890F: 31 64 9B  LD SP,9B64
$8912: CD 0B 94  CALL 940B
$8915: CD B6 93  CALL 93B6
$8918: C3 31 96  JP 9631
$891B: CD 4D 9A  CALL 9A4D
$891E: CD 07 97  CALL 9707
$8921: C3 DF 94  JP 94DF
$8924: 01 2C 9A  LD BC,9A2C
$8927: CD A2 93  CALL 93A2
$892A: 18 0C     JR 8938
$892C: 42        LD B,D
$892D: 61        LD H,C
$892E: 64        LD H,H
$892F: 20 6C     JR NZ,899D
$8931: 6F        LD L,A
$8932: 61        LD H,C
$8933: 64        LD H,H
$8934: 00        NOP
$8935: 43        LD B,E
$8936: 4F        LD C,A
$8937: 4D        LD C,L
$8938: CD 07 97  CALL 9707
$893B: CD 2F 95  CALL 952F
$893E: 3A 87 9B  LD A,(9B87)
$8941: D6 20     SUB 20
$8943: 21 A9 9B  LD HL,9BA9
$8946: B6        OR (HL)
$8947: C2 DF 94  JP NZ,94DF
$894A: C3 31 96  JP 9631
$894D: 3A 43 9B  LD A,(9B43)
$8950: 5F        LD E,A
$8951: C3 F8 93  JP 93F8
$8954: 2A DE F3  LD HL,(F3DE)
$8957: 22 26 9B  LD (9B26),HL
$895A: AF        XOR A
$895B: 32 92 9B  LD (9B92),A
$895E: 3E 11     LD A,11
$8960: 32 41 9B  LD (9B41),A
$8963: 11 FF 92  LD DE,92FF
$8966: AF        XOR A
$8967: 32 A6 9B  LD (9BA6),A
$896A: 21 96 9B  LD HL,9B96
$896D: 7E        LD A,(HL)
$896E: B7        OR A
$896F: 28 06     JR Z,8977
$8971: CD 8D 9A  CALL 9A8D
$8974: 23        INC HL
$8975: 18 F6     JR 896D
$8977: 3E A6     LD A,A6
$8979: BD        CP L
$897A: C2 82 9A  JP NZ,9A82
$897D: CD C8 9A  CALL 9AC8
$8980: 20 E4     JR NZ,8966
$8982: AF        XOR A
$8983: 12        LD (DE),A
$8984: CD D4 9A  CALL 9AD4
$8987: CD 06 9B  CALL 9B06
$898A: C3 B8 99  JP 99B8
$898D: E5        PUSH HL
$898E: F5        PUSH AF
$898F: CB        DB $CB
$8990: 3F        CCF
$8991: CB        DB $CB
$8992: 3F        CCF
$8993: C6 03     ADD A,03
$8995: 32 42 9B  LD (9B42),A
$8998: F1        POP AF
$8999: E6 03     AND 03
$899B: 87        ADD A,A
$899C: 87        ADD A,A
$899D: 21 31 9B  LD HL,9B31
$89A0: 85        ADD A,L
$89A1: 6F        LD L,A
$89A2: 30 01     JR NC,89A5
$89A4: 24        INC H
$89A5: 06 04     LD B,04
$89A7: 3A 42 9B  LD A,(9B42)
$89AA: 12        LD (DE),A
$89AB: 1B        DEC DE
$89AC: 7E        LD A,(HL)
$89AD: 23        INC HL
$89AE: 12        LD (DE),A
$89AF: 1B        DEC DE
$89B0: 3A 41 9B  LD A,(9B41)
$89B3: FE A1     CP A1
$89B5: CA 24 9A  JP Z,9A24
$89B8: FE C0     CP C0
$89BA: 20 02     JR NZ,89BE
$89BC: 3E D0     LD A,D0
$89BE: 12        LD (DE),A
$89BF: 3C        INC A
$89C0: 1B        DEC DE
$89C1: 32 41 9B  LD (9B41),A
$89C4: 10 E1     DJNZ 89A7
$89C6: E1        POP HL
$89C7: C9        RET
$89C8: E5        PUSH HL
$89C9: D5        PUSH DE
$89CA: 21 92 9B  LD HL,9B92
$89CD: 34        INC (HL)
$89CE: CD C6 93  CALL 93C6
$89D1: D1        POP DE
$89D2: E1        POP HL
$89D3: C9        RET
$89D4: 21 FF 92  LD HL,92FF
$89D7: 54        LD D,H
$89D8: 5D        LD E,L
$89D9: 1B        DEC DE
$89DA: 1B        DEC DE
$89DB: 1B        DEC DE
$89DC: 1A        LD A,(DE)
$89DD: B7        OR A
$89DE: 28 1E     JR Z,89FE
$89E0: BE        CP (HL)
$89E1: 38 0A     JR C,89ED
$89E3: 20 F4     JR NZ,89D9
$89E5: 1B        DEC DE
$89E6: 1A        LD A,(DE)
$89E7: 13        INC DE
$89E8: 2B        DEC HL
$89E9: BE        CP (HL)
$89EA: 23        INC HL
$89EB: 30 EC     JR NC,89D9
$89ED: E5        PUSH HL
$89EE: D5        PUSH DE
$89EF: 06 03     LD B,03
$89F1: 1A        LD A,(DE)
$89F2: 4E        LD C,(HL)
$89F3: 77        LD (HL),A
$89F4: 79        LD A,C
$89F5: 12        LD (DE),A
$89F6: 2B        DEC HL
$89F7: 1B        DEC DE
$89F8: 10 F7     DJNZ 89F1
$89FA: D1        POP DE
$89FB: E1        POP HL
$89FC: 18 DB     JR 89D9
$89FE: 2B        DEC HL
$89FF: 2B        DEC HL
$8A00: FF        RST $38
$8A01: 22 EA A9  LD (A9EA),HL
$8A04: C9        RET
$8A05: 2A C8 A9  LD HL,(A9C8)
$8A08: EB        EX DE,HL
$8A09: 2A EA A9  LD HL,(A9EA)
$8A0C: 23        INC HL
$8A0D: 22 EA A9  LD (A9EA),HL
$8A10: CD 95 A1  CALL A195
$8A13: D2 19 A2  JP NC,A219
$8A16: C3 FE A1  JP A1FE
$8A19: 3A EA A9  LD A,(A9EA)
$8A1C: E6 03     AND 03
$8A1E: 06 05     LD B,05
$8A20: 87        ADD A,A
$8A21: 05        DEC B
$8A22: C2 20 A2  JP NZ,A220
$8A25: 32 E9 A9  LD (A9E9),A
$8A28: B7        OR A
$8A29: C0        RET NZ
$8A2A: C5        PUSH BC
$8A2B: CD C3 9F  CALL 9FC3
$8A2E: CD D4 A1  CALL A1D4
$8A31: C1        POP BC
$8A32: C3 9E A1  JP A19E
$8A35: 79        LD A,C
$8A36: E6 07     AND 07
$8A38: 3C        INC A
$8A39: 5F        LD E,A
$8A3A: 57        LD D,A
$8A3B: 79        LD A,C
$8A3C: 0F        RRCA
$8A3D: 0F        RRCA
$8A3E: 0F        RRCA
$8A3F: E6 1F     AND 1F
$8A41: 4F        LD C,A
$8A42: 78        LD A,B
$8A43: 87        ADD A,A
$8A44: 87        ADD A,A
$8A45: 87        ADD A,A
$8A46: 87        ADD A,A
$8A47: 87        ADD A,A
$8A48: B1        OR C
$8A49: 4F        LD C,A
$8A4A: 78        LD A,B
$8A4B: 0F        RRCA
$8A4C: 0F        RRCA
$8A4D: 0F        RRCA
$8A4E: E6 1F     AND 1F
$8A50: 47        LD B,A
$8A51: 2A BF A9  LD HL,(A9BF)
$8A54: 09        ADD HL,BC
$8A55: 7E        LD A,(HL)
$8A56: 07        RLCA
$8A57: 1D        DEC E
$8A58: C2 56 A2  JP NZ,A256
$8A5B: C9        RET
$8A5C: D5        PUSH DE
$8A5D: CD 35 A2  CALL A235
$8A60: E6 FE     AND FE
$8A62: C1        POP BC
$8A63: B1        OR C
$8A64: 0F        RRCA
$8A65: 15        DEC D
$8A66: C2 64 A2  JP NZ,A264
$8A69: 77        LD (HL),A
$8A6A: C9        RET
$8A6B: CD 5E A1  CALL A15E
$8A6E: 11 10 00  LD DE,0010
$8A71: 19        ADD HL,DE
$8A72: C5        PUSH BC
$8A73: 0E 11     LD C,11
$8A75: D1        POP DE
$8A76: 0D        DEC C
$8A77: C8        RET Z
$8A78: D5        PUSH DE
$8A79: 3A DD A9  LD A,(A9DD)
$8A7C: B7        OR A
$8A7D: CA 88 A2  JP Z,A288
$8A80: C5        PUSH BC
$8A81: E5        PUSH HL
$8A82: 4E        LD C,(HL)
$8A83: 06 00     LD B,00
$8A85: C3 8E A2  JP A28E
$8A88: 0D        DEC C
$8A89: C5        PUSH BC
$8A8A: 4E        LD C,(HL)
$8A8B: 23        INC HL
$8A8C: 46        LD B,(HL)
$8A8D: E5        PUSH HL
$8A8E: 79        LD A,C
$8A8F: B0        OR B
$8A90: CA 9D A2  JP Z,A29D
$8A93: 2A C6 A9  LD HL,(A9C6)
$8A96: 7D        LD A,L
$8A97: 91        SUB C
$8A98: 7C        LD A,H
$8A99: 98        SBC A,B
$8A9A: D4 5C A2  CALL NC,A25C
$8A9D: E1        POP HL
$8A9E: 23        INC HL
$8A9F: C1        POP BC
$8AA0: C3 75 A2  JP A275
$8AA3: 2A C6 A9  LD HL,(A9C6)
$8AA6: 0E 03     LD C,03
$8AA8: CD EA A0  CALL A0EA
$8AAB: 23        INC HL
$8AAC: 44        LD B,H
$8AAD: 4D        LD C,L
$8AAE: 2A BF A9  LD HL,(A9BF)
$8AB1: 36 00     LD (HL),00
$8AB3: 23        INC HL
$8AB4: 0B        DEC BC
$8AB5: 78        LD A,B
$8AB6: B1        OR C
$8AB7: C2 B1 A2  JP NZ,A2B1
$8ABA: 2A CA A9  LD HL,(A9CA)
$8ABD: EB        EX DE,HL
$8ABE: 2A BF A9  LD HL,(A9BF)
$8AC1: 73        LD (HL),E
$8AC2: 23        INC HL
$8AC3: 72        LD (HL),D
$8AC4: CD A1 9F  CALL 9FA1
$8AC7: 2A B3 A9  LD HL,(A9B3)
$8ACA: 36 03     LD (HL),03
$8ACC: 23        INC HL
$8ACD: 36 00     LD (HL),00
$8ACF: CD FE A1  CALL A1FE
$8AD2: 0E FF     LD C,FF
$8AD4: CD 05 A2  CALL A205
$8AD7: CD F5 A1  CALL A1F5
$8ADA: C8        RET Z
$8ADB: CD 5E A1  CALL A15E
$8ADE: 3E E5     LD A,E5
$8AE0: BE        CP (HL)
$8AE1: CA D2 A2  JP Z,A2D2
$8AE4: 3A 41 9F  LD A,(9F41)
$8AE7: BE        CP (HL)
$8AE8: C2 F6 A2  JP NZ,A2F6
$8AEB: 23        INC HL
$8AEC: 7E        LD A,(HL)
$8AED: D6 24     SUB 24
$8AEF: C2 F6 A2  JP NZ,A2F6
$8AF2: 3D        DEC A
$8AF3: 32 45 9F  LD (9F45),A
$8AF6: 0E 01     LD C,01
$8AF8: CD 6B A2  CALL A26B
$8AFB: CD 8C A1  CALL A18C
$8AFE: C3 D2 2B  JP 2BD2
$8B01: 7E        LD A,(HL)
$8B02: B7        OR A
$8B03: 20 D2     JR NZ,8AD7
$8B05: C9        RET
$8B06: 11 FF 92  LD DE,92FF
$8B09: 1A        LD A,(DE)
$8B0A: B7        OR A
$8B0B: C8        RET Z
$8B0C: 32 E0 F3  LD (F3E0),A
$8B0F: 1B        DEC DE
$8B10: 1A        LD A,(DE)
$8B11: 32 E1 F3  LD (F3E1),A
$8B14: 1B        DEC DE
$8B15: 1A        LD A,(DE)
$8B16: 32 E9 F3  LD (F3E9),A
$8B19: 1B        DEC DE
$8B1A: 3E 01     LD A,01
$8B1C: 32 EB F3  LD (F3EB),A
$8B1F: 21 03 0E  LD HL,0E03
$8B22: 22 D0 F3  LD (F3D0),HL
$8B25: 32 00 00  LD (0000),A
$8B28: 3A EA F3  LD A,(F3EA)
$8B2B: B7        OR A
$8B2C: 28 DB     JR Z,8B09
$8B2E: C3 93 99  JP 9993
$8B31: 00        NOP
$8B32: 09        ADD HL,BC
$8B33: 03        INC BC
$8B34: 0C        INC C
$8B35: 06 0F     LD B,0F
$8B37: 01 0A 04  LD BC,040A
$8B3A: 0D        DEC C
$8B3B: 07        RLCA
$8B3C: 08        EX AF,AF'
$8B3D: 02        LD (BC),A
$8B3E: 0B        DEC BC
$8B3F: 05        DEC B
$8B40: 0E 00     LD C,00
$8B42: 00        NOP
$8B43: 00        NOP
$8B44: 00        NOP
$8B45: 00        NOP
$8B46: 00        NOP
$8B47: 00        NOP
$8B48: 00        NOP
$8B49: 00        NOP
$8B4A: 00        NOP
$8B4B: 00        NOP
$8B4C: 00        NOP
$8B4D: 00        NOP
$8B4E: 00        NOP
$8B4F: 00        NOP
$8B50: 00        NOP
$8B51: 00        NOP
$8B52: 00        NOP
$8B53: 00        NOP
$8B54: 00        NOP
$8B55: 00        NOP
$8B56: 00        NOP
$8B57: 00        NOP
$8B58: 00        NOP
$8B59: 00        NOP
$8B5A: 00        NOP
$8B5B: 00        NOP
$8B5C: 00        NOP
$8B5D: 00        NOP
$8B5E: 00        NOP
$8B5F: 00        NOP
$8B60: 00        NOP
$8B61: 00        NOP
$8B62: 00        NOP
$8B63: 00        NOP
$8B64: 00        NOP
$8B65: 00        NOP
$8B66: 24        INC H
$8B67: 24        INC H
$8B68: 24        INC H
$8B69: 20 20     JR NZ,8B8B
$8B6B: 20 20     JR NZ,8B8D
$8B6D: 20 53     JR NZ,8BC2
$8B6F: 55        LD D,L

; ============================================================================
; BDOS BODY ($8B70-$96BA)
;
; Digital Research's CP/M 2.2 BDOS, ~2.7 KB. Standard structure:
;   - Function dispatcher: receives C = function code, dispatches via
;     a jump table to the appropriate handler
;   - File operations: open, close, read sequential, write sequential,
;     read random, write random (BDOS functions 15-21, 33-34)
;   - Console operations: read char, write char, print string (functions
;     1-12)
;   - Drive operations: select disk, get/set DMA, login (functions
;     13-14, 24-26)
;   - Error handling: BDOS error trap (the "Bdos Err On %c: %s" path
;     using the strings at $8DBA)
;
; Key entry point reached via the cold-boot's plant at $0005-$0007:
;   $0005: JP $9C06    ; user-program -> BDOS interface
; Wait -- $9C06 is past sysimg's end ($96FF). The actual BDOS entry
; address used at runtime depends on the relocation by the loader's
; third page copy. After that copy, sysimg lives at $8000-$96FF; the
; BDOS body is somewhere within this range; the cold-boot plants the
; correct entry-point address there.
;
; Per-instruction annotation is omitted here -- the BDOS matches the
; standard Digital Research CP/M 2.2 reference disassembly with
; absolute-address relocation. See standard CP/M reference materials
; for the full instruction-level breakdown.
; ============================================================================


$8B70: 42        LD B,D
$8B71: 00        NOP
$8B72: 00        NOP
$8B73: 00        NOP
$8B74: 00        NOP
$8B75: 00        NOP
$8B76: 00        NOP
$8B77: 00        NOP
$8B78: 00        NOP
$8B79: 00        NOP
$8B7A: 00        NOP
$8B7B: 00        NOP
$8B7C: 00        NOP
$8B7D: 00        NOP
$8B7E: 00        NOP
$8B7F: 00        NOP
$8B80: 00        NOP
$8B81: 00        NOP
$8B82: 00        NOP
$8B83: 00        NOP
$8B84: 00        NOP
$8B85: 00        NOP
$8B86: 00        NOP
$8B87: 00        NOP
$8B88: 00        NOP
$8B89: 00        NOP
$8B8A: 00        NOP
$8B8B: 00        NOP
$8B8C: 00        NOP
$8B8D: 00        NOP
$8B8E: 00        NOP
$8B8F: 00        NOP
$8B90: 00        NOP
$8B91: 00        NOP
$8B92: 00        NOP
$8B93: 00        NOP
$8B94: 00        NOP
$8B95: 00        NOP
$8B96: 00        NOP
$8B97: 00        NOP
$8B98: 00        NOP
$8B99: 00        NOP
$8B9A: 00        NOP
$8B9B: 00        NOP
$8B9C: 00        NOP
$8B9D: 00        NOP
$8B9E: 00        NOP
$8B9F: 00        NOP
$8BA0: 00        NOP
$8BA1: 00        NOP
$8BA2: 00        NOP
$8BA3: 00        NOP
$8BA4: 00        NOP
$8BA5: 00        NOP
$8BA6: 00        NOP
$8BA7: 00        NOP
$8BA8: 00        NOP
$8BA9: 00        NOP
$8BAA: 00        NOP
$8BAB: 00        NOP
$8BAC: 00        NOP
$8BAD: 00        NOP
$8BAE: 00        NOP
$8BAF: 00        NOP
$8BB0: 00        NOP
$8BB1: 00        NOP
$8BB2: 00        NOP
$8BB3: 00        NOP
$8BB4: 00        NOP
$8BB5: 00        NOP
$8BB6: 00        NOP
$8BB7: 00        NOP
$8BB8: 00        NOP
$8BB9: 00        NOP
$8BBA: 00        NOP
$8BBB: 00        NOP
$8BBC: 00        NOP
$8BBD: 00        NOP
$8BBE: 00        NOP
$8BBF: 00        NOP
$8BC0: 00        NOP
$8BC1: 00        NOP
$8BC2: 00        NOP
$8BC3: 00        NOP
$8BC4: 00        NOP
$8BC5: 00        NOP
$8BC6: 00        NOP
$8BC7: 00        NOP
$8BC8: 00        NOP
$8BC9: 00        NOP
$8BCA: 00        NOP
$8BCB: 00        NOP
$8BCC: 00        NOP
$8BCD: 00        NOP
$8BCE: 00        NOP
$8BCF: 00        NOP
$8BD0: 00        NOP
$8BD1: 00        NOP
$8BD2: 00        NOP
$8BD3: 00        NOP
$8BD4: 00        NOP
$8BD5: 00        NOP
$8BD6: 00        NOP
$8BD7: 00        NOP
$8BD8: 00        NOP
$8BD9: 00        NOP
$8BDA: 00        NOP
$8BDB: 00        NOP
$8BDC: 00        NOP
$8BDD: 00        NOP
$8BDE: 00        NOP
$8BDF: 00        NOP
$8BE0: 00        NOP
$8BE1: 00        NOP
$8BE2: 00        NOP
$8BE3: 00        NOP
$8BE4: 00        NOP
$8BE5: 00        NOP
$8BE6: 00        NOP
$8BE7: 00        NOP
$8BE8: 00        NOP
$8BE9: 00        NOP
$8BEA: 00        NOP
$8BEB: 00        NOP
$8BEC: 00        NOP
$8BED: 00        NOP
$8BEE: 00        NOP
$8BEF: 00        NOP
$8BF0: 00        NOP
$8BF1: 00        NOP
$8BF2: 00        NOP
$8BF3: 00        NOP
$8BF4: 00        NOP
$8BF5: 00        NOP
$8BF6: 00        NOP
$8BF7: 00        NOP
$8BF8: 00        NOP
$8BF9: 00        NOP
$8BFA: 00        NOP
$8BFB: 00        NOP
$8BFC: 00        NOP
$8BFD: 00        NOP
$8BFE: 00        NOP
$8BFF: 00        NOP
$8C00: A2        AND D
$8C01: 3A D4 A9  LD A,(A9D4)
$8C04: C3 01 9F  JP 9F01
$8C07: C5        PUSH BC
$8C08: F5        PUSH AF
$8C09: 3A C5 A9  LD A,(A9C5)
$8C0C: 2F        CPL
$8C0D: 47        LD B,A
$8C0E: 79        LD A,C
$8C0F: A0        AND B
$8C10: 4F        LD C,A
$8C11: F1        POP AF
$8C12: A0        AND B
$8C13: 91        SUB C
$8C14: E6 1F     AND 1F
$8C16: C1        POP BC
$8C17: C9        RET
$8C18: 3E FF     LD A,FF
$8C1A: 32 D4 A9  LD (A9D4),A
$8C1D: 21 D8 A9  LD HL,A9D8
$8C20: 71        LD (HL),C
$8C21: 2A 43 9F  LD HL,(9F43)
$8C24: 22 D9 A9  LD (A9D9),HL
$8C27: CD FE A1  CALL A1FE
$8C2A: CD A1 9F  CALL 9FA1
$8C2D: 0E 00     LD C,00
$8C2F: CD 05 A2  CALL A205
$8C32: CD F5 A1  CALL A1F5
$8C35: CA 94 A3  JP Z,A394
$8C38: 2A D9 A9  LD HL,(A9D9)
$8C3B: EB        EX DE,HL
$8C3C: 1A        LD A,(DE)
$8C3D: FE E5     CP E5
$8C3F: CA 4A A3  JP Z,A34A
$8C42: D5        PUSH DE
$8C43: CD 7F A1  CALL A17F
$8C46: D1        POP DE
$8C47: D2 94 A3  JP NC,A394
$8C4A: CD 5E A1  CALL A15E
$8C4D: 3A D8 A9  LD A,(A9D8)
$8C50: 4F        LD C,A
$8C51: 06 00     LD B,00
$8C53: 79        LD A,C
$8C54: B7        OR A
$8C55: CA 83 A3  JP Z,A383
$8C58: 1A        LD A,(DE)
$8C59: FE 3F     CP 3F
$8C5B: CA 7C A3  JP Z,A37C
$8C5E: 78        LD A,B
$8C5F: FE 0D     CP 0D
$8C61: CA 7C A3  JP Z,A37C
$8C64: FE 0C     CP 0C
$8C66: 1A        LD A,(DE)
$8C67: CA 73 A3  JP Z,A373
$8C6A: 96        SUB (HL)
$8C6B: E6 7F     AND 7F
$8C6D: C2 2D A3  JP NZ,A32D
$8C70: C3 7C A3  JP A37C
$8C73: C5        PUSH BC
$8C74: 4E        LD C,(HL)
$8C75: CD 07 A3  CALL A307
$8C78: C1        POP BC
$8C79: C2 2D A3  JP NZ,A32D
$8C7C: 13        INC DE
$8C7D: 23        INC HL
$8C7E: 04        INC B
$8C7F: 0D        DEC C
$8C80: C3 53 A3  JP A353
$8C83: 3A EA A9  LD A,(A9EA)
$8C86: E6 03     AND 03
$8C88: 32 45 9F  LD (9F45),A
$8C8B: 21 D4 A9  LD HL,A9D4
$8C8E: 7E        LD A,(HL)
$8C8F: 17        RLA
$8C90: D0        RET NC
$8C91: AF        XOR A
$8C92: 77        LD (HL),A
$8C93: C9        RET
$8C94: CD FE A1  CALL A1FE
$8C97: 3E FF     LD A,FF
$8C99: C3 01 9F  JP 9F01
$8C9C: CD 54 A1  CALL A154
$8C9F: 0E 0C     LD C,0C
$8CA1: CD 18 A3  CALL A318
$8CA4: CD F5 A1  CALL A1F5
$8CA7: C8        RET Z
$8CA8: CD 44 A1  CALL A144
$8CAB: CD 5E A1  CALL A15E
$8CAE: 36 E5     LD (HL),E5
$8CB0: 0E 00     LD C,00
$8CB2: CD 6B A2  CALL A26B
$8CB5: CD C6 A1  CALL A1C6
$8CB8: CD 2D A3  CALL A32D
$8CBB: C3 A4 A3  JP A3A4
$8CBE: 50        LD D,B
$8CBF: 59        LD E,C
$8CC0: 79        LD A,C
$8CC1: B0        OR B
$8CC2: CA D1 A3  JP Z,A3D1
$8CC5: 0B        DEC BC
$8CC6: D5        PUSH DE
$8CC7: C5        PUSH BC
$8CC8: CD 35 A2  CALL A235
$8CCB: 1F        RRA
$8CCC: D2 EC A3  JP NC,A3EC
$8CCF: C1        POP BC
$8CD0: D1        POP DE
$8CD1: 2A C6 A9  LD HL,(A9C6)
$8CD4: 7B        LD A,E
$8CD5: 95        SUB L
$8CD6: 7A        LD A,D
$8CD7: 9C        SBC A,H
$8CD8: D2 F4 A3  JP NC,A3F4
$8CDB: 13        INC DE
$8CDC: C5        PUSH BC
$8CDD: D5        PUSH DE
$8CDE: 42        LD B,D
$8CDF: 4B        LD C,E
$8CE0: CD 35 A2  CALL A235
$8CE3: 1F        RRA
$8CE4: D2 EC A3  JP NC,A3EC
$8CE7: D1        POP DE
$8CE8: C1        POP BC
$8CE9: C3 C0 A3  JP A3C0
$8CEC: 17        RLA
$8CED: 3C        INC A
$8CEE: CD 64 A2  CALL A264
$8CF1: E1        POP HL
$8CF2: D1        POP DE
$8CF3: C9        RET
$8CF4: 79        LD A,C
$8CF5: B0        OR B
$8CF6: C2 C0 A3  JP NZ,A3C0
$8CF9: 21 00 00  LD HL,0000
$8CFC: C9        RET
$8CFD: 0E 00     LD C,00
$8CFF: 1E BD     LD E,BD
$8D01: 16 00     LD D,00
$8D03: 01 4D 40  LD BC,404D
$8D06: C3 11 9C  JP 9C11
$8D09: 99        SBC A,C
$8D0A: 9C        SBC A,H
$8D0B: A5        AND L
$8D0C: 9C        SBC A,H
$8D0D: AB        XOR E
$8D0E: 9C        SBC A,H
$8D0F: B1        OR C
$8D10: 9C        SBC A,H
$8D11: EB        EX DE,HL
$8D12: 22 43 9F  LD (9F43),HL
$8D15: EB        EX DE,HL
$8D16: 7B        LD A,E
$8D17: 32 D6 A9  LD (A9D6),A
$8D1A: 21 00 00  LD HL,0000
$8D1D: 22 45 9F  LD (9F45),HL
$8D20: 39        ADD HL,SP
$8D21: 22 0F 9F  LD (9F0F),HL
$8D24: 31 41 9F  LD SP,9F41
$8D27: AF        XOR A
$8D28: 32 E0 A9  LD (A9E0),A
$8D2B: 32 DE A9  LD (A9DE),A
$8D2E: 21 74 A9  LD HL,A974
$8D31: E5        PUSH HL
$8D32: 79        LD A,C
$8D33: FE 29     CP 29
$8D35: D0        RET NC
$8D36: 4B        LD C,E
$8D37: 21 47 9C  LD HL,9C47
$8D3A: 5F        LD E,A
$8D3B: 16 00     LD D,00
$8D3D: 19        ADD HL,DE
$8D3E: 19        ADD HL,DE
$8D3F: 5E        LD E,(HL)
$8D40: 23        INC HL
$8D41: 56        LD D,(HL)
$8D42: 2A 43 9F  LD HL,(9F43)
$8D45: EB        EX DE,HL
$8D46: E9        JP (HL)
$8D47: 03        INC BC
$8D48: FA C8 9E  JP M,9EC8
$8D4B: 90        SUB B
$8D4C: 9D        SBC A,L
$8D4D: CE 9E     ADC A,9E
$8D4F: 12        LD (DE),A
$8D50: FA 0F FA  JP M,FA0F
$8D53: D4 9E ED  CALL NC,ED9E
$8D56: 9E        SBC A,(HL)
$8D57: F3        DI
$8D58: 9E        SBC A,(HL)
$8D59: F8        RET M
$8D5A: 9E        SBC A,(HL)
$8D5B: E1        POP HL
$8D5C: 9D        SBC A,L
$8D5D: FE 9E     CP 9E
$8D5F: 7E        LD A,(HL)
$8D60: A8        XOR B
$8D61: 83        ADD A,E
$8D62: A8        XOR B
$8D63: 45        LD B,L
$8D64: A8        XOR B
$8D65: 9C        SBC A,H
$8D66: A8        XOR B
$8D67: A5        AND L
$8D68: A8        XOR B
$8D69: AB        XOR E
$8D6A: A8        XOR B
$8D6B: C8        RET Z
$8D6C: A8        XOR B
$8D6D: D7        RST $10
$8D6E: A8        XOR B
$8D6F: E0        RET PO
$8D70: A8        XOR B
$8D71: E6 A8     AND A8
$8D73: EC A8 F5  CALL PE,F5A8
$8D76: A8        XOR B
$8D77: FE A8     CP A8
$8D79: 04        INC B
$8D7A: A9        XOR C
$8D7B: 0A        LD A,(BC)
$8D7C: A9        XOR C
$8D7D: 11 A9 2C  LD DE,2CA9
$8D80: A1        AND C
$8D81: 17        RLA
$8D82: A9        XOR C
$8D83: 1D        DEC E
$8D84: A9        XOR C
$8D85: 26 A9     LD H,A9
$8D87: 2D        DEC L
$8D88: A9        XOR C
$8D89: 41        LD B,C
$8D8A: A9        XOR C
$8D8B: 47        LD B,A
$8D8C: A9        XOR C
$8D8D: 4D        LD C,L
$8D8E: A9        XOR C
$8D8F: 0E A8     LD C,A8
$8D91: 53        LD D,E
$8D92: A9        XOR C
$8D93: 04        INC B
$8D94: 9F        SBC A,A
$8D95: 04        INC B
$8D96: 9F        SBC A,A
$8D97: 9B        SBC A,E
$8D98: A9        XOR C
$8D99: 21 CA 9C  LD HL,9CCA
$8D9C: CD E5 9C  CALL 9CE5
$8D9F: FE 03     CP 03
$8DA1: CA 00 00  JP Z,0000
$8DA4: C9        RET
$8DA5: 21 D5 9C  LD HL,9CD5
$8DA8: C3 B4 9C  JP 9CB4
$8DAB: 21 E1 9C  LD HL,9CE1
$8DAE: C3 B4 9C  JP 9CB4
$8DB1: 21 DC 9C  LD HL,9CDC
$8DB4: CD E5 9C  CALL 9CE5
$8DB7: C3 00 00  JP 0000
$8DBA: 42        LD B,D
$8DBB: 64        LD H,H
$8DBC: 6F        LD L,A
$8DBD: 73        LD (HL),E
$8DBE: 20 45     JR NZ,8E05
$8DC0: 72        LD (HL),D
$8DC1: 72        LD (HL),D
$8DC2: 20 4F     JR NZ,8E13
$8DC4: 6E        LD L,(HL)
$8DC5: 20 20     JR NZ,8DE7
$8DC7: 3A 20 24  LD A,(2420)
$8DCA: 42        LD B,D
$8DCB: 61        LD H,C
$8DCC: 64        LD H,H
$8DCD: 20 53     JR NZ,8E22
$8DCF: 65        LD H,L
$8DD0: 63        LD H,E
$8DD1: 74        LD (HL),H
$8DD2: 6F        LD L,A
$8DD3: 72        LD (HL),D
$8DD4: 24        INC H
$8DD5: 53        LD D,E
$8DD6: 65        LD H,L
$8DD7: 6C        LD L,H
$8DD8: 65        LD H,L
$8DD9: 63        LD H,E
$8DDA: 74        LD (HL),H
$8DDB: 24        INC H
$8DDC: 46        LD B,(HL)
$8DDD: 69        LD L,C
$8DDE: 6C        LD L,H
$8DDF: 65        LD H,L
$8DE0: 20 52     JR NZ,8E34
$8DE2: 2F        CPL
$8DE3: 4F        LD C,A
$8DE4: 24        INC H
$8DE5: E5        PUSH HL
$8DE6: CD C9 9D  CALL 9DC9
$8DE9: 3A 42 9F  LD A,(9F42)
$8DEC: C6 41     ADD A,41
$8DEE: 32 C6 9C  LD (9CC6),A
$8DF1: 01 BA 9C  LD BC,9CBA
$8DF4: CD D3 9D  CALL 9DD3
$8DF7: C1        POP BC
$8DF8: CD D3 9D  CALL 9DD3
$8DFB: 21 0E 9F  LD HL,9F0E
$8DFE: 7E        LD A,(HL)
$8DFF: 36 20     LD (HL),20
$8E01: D5        PUSH DE
$8E02: 06 00     LD B,00
$8E04: 2A 43 9F  LD HL,(9F43)
$8E07: 09        ADD HL,BC
$8E08: EB        EX DE,HL
$8E09: CD 5E A1  CALL A15E
$8E0C: C1        POP BC
$8E0D: CD 4F 9F  CALL 9F4F
$8E10: CD C3 9F  CALL 9FC3
$8E13: C3 C6 A1  JP A1C6
$8E16: CD 54 A1  CALL A154
$8E19: 0E 0C     LD C,0C
$8E1B: CD 18 A3  CALL A318
$8E1E: 2A 43 9F  LD HL,(9F43)
$8E21: 7E        LD A,(HL)
$8E22: 11 10 00  LD DE,0010
$8E25: 19        ADD HL,DE
$8E26: 77        LD (HL),A
$8E27: CD F5 A1  CALL A1F5
$8E2A: C8        RET Z
$8E2B: CD 44 A1  CALL A144
$8E2E: 0E 10     LD C,10
$8E30: 1E 0C     LD E,0C
$8E32: CD 01 A4  CALL A401
$8E35: CD 2D A3  CALL A32D
$8E38: C3 27 A4  JP A427
$8E3B: 0E 0C     LD C,0C
$8E3D: CD 18 A3  CALL A318
$8E40: CD F5 A1  CALL A1F5
$8E43: C8        RET Z
$8E44: 0E 00     LD C,00
$8E46: 1E 0C     LD E,0C
$8E48: CD 01 A4  CALL A401
$8E4B: CD 2D A3  CALL A32D
$8E4E: C3 40 A4  JP A440
$8E51: 0E 0F     LD C,0F
$8E53: CD 18 A3  CALL A318
$8E56: CD F5 A1  CALL A1F5
$8E59: C8        RET Z
$8E5A: CD A6 A0  CALL A0A6
$8E5D: 7E        LD A,(HL)
$8E5E: F5        PUSH AF
$8E5F: E5        PUSH HL
$8E60: CD 5E A1  CALL A15E
$8E63: EB        EX DE,HL
$8E64: 2A 43 9F  LD HL,(9F43)
$8E67: 0E 20     LD C,20
$8E69: D5        PUSH DE
$8E6A: CD 4F 9F  CALL 9F4F
$8E6D: CD 78 A1  CALL A178
$8E70: D1        POP DE
$8E71: 21 0C 00  LD HL,000C
$8E74: 19        ADD HL,DE
$8E75: 4E        LD C,(HL)
$8E76: 21 0F 00  LD HL,000F
$8E79: 19        ADD HL,DE
$8E7A: 46        LD B,(HL)
$8E7B: E1        POP HL
$8E7C: F1        POP AF
$8E7D: 77        LD (HL),A
$8E7E: 79        LD A,C
$8E7F: BE        CP (HL)
$8E80: 78        LD A,B
$8E81: CA 8B A4  JP Z,A48B
$8E84: 3E 00     LD A,00
$8E86: DA 8B A4  JP C,A48B
$8E89: 3E 80     LD A,80
$8E8B: 2A 43 9F  LD HL,(9F43)
$8E8E: 11 0F 00  LD DE,000F
$8E91: 19        ADD HL,DE
$8E92: 77        LD (HL),A
$8E93: C9        RET
$8E94: 7E        LD A,(HL)
$8E95: 23        INC HL
$8E96: B6        OR (HL)
$8E97: 2B        DEC HL
$8E98: C0        RET NZ
$8E99: 1A        LD A,(DE)
$8E9A: 77        LD (HL),A
$8E9B: 13        INC DE
$8E9C: 23        INC HL
$8E9D: 1A        LD A,(DE)
$8E9E: 77        LD (HL),A
$8E9F: 1B        DEC DE
$8EA0: 2B        DEC HL
$8EA1: C9        RET
$8EA2: AF        XOR A
$8EA3: 32 45 9F  LD (9F45),A
$8EA6: 32 EA A9  LD (A9EA),A
$8EA9: 32 EB A9  LD (A9EB),A
$8EAC: CD 1E A1  CALL A11E
$8EAF: C0        RET NZ
$8EB0: CD 69 A1  CALL A169
$8EB3: E6 80     AND 80
$8EB5: C0        RET NZ
$8EB6: 0E 0F     LD C,0F
$8EB8: CD 18 A3  CALL A318
$8EBB: CD F5 A1  CALL A1F5
$8EBE: C8        RET Z
$8EBF: 01 10 00  LD BC,0010
$8EC2: CD 5E A1  CALL A15E
$8EC5: 09        ADD HL,BC
$8EC6: EB        EX DE,HL
$8EC7: 2A 43 9F  LD HL,(9F43)
$8ECA: 09        ADD HL,BC
$8ECB: 0E 10     LD C,10
$8ECD: 3A DD A9  LD A,(A9DD)
$8ED0: B7        OR A
$8ED1: CA E8 A4  JP Z,A4E8
$8ED4: 7E        LD A,(HL)
$8ED5: B7        OR A
$8ED6: 1A        LD A,(DE)
$8ED7: C2 DB A4  JP NZ,A4DB
$8EDA: 77        LD (HL),A
$8EDB: B7        OR A
$8EDC: C2 E1 A4  JP NZ,A4E1
$8EDF: 7E        LD A,(HL)
$8EE0: 12        LD (DE),A
$8EE1: BE        CP (HL)
$8EE2: C2 1F A5  JP NZ,A51F
$8EE5: C3 FD A4  JP A4FD
$8EE8: CD 94 A4  CALL A494
$8EEB: EB        EX DE,HL
$8EEC: CD 94 A4  CALL A494
$8EEF: EB        EX DE,HL
$8EF0: 1A        LD A,(DE)
$8EF1: BE        CP (HL)
$8EF2: C2 1F A5  JP NZ,A51F
$8EF5: 13        INC DE
$8EF6: 23        INC HL
$8EF7: 1A        LD A,(DE)
$8EF8: BE        CP (HL)
$8EF9: C2 1F A5  JP NZ,A51F
$8EFC: 0D        DEC C
$8EFD: 13        INC DE
$8EFE: 23        INC HL
$8EFF: 0D        DEC C
$8F00: 00        NOP
$8F01: B7        OR A
$8F02: C0        RET NZ
$8F03: C3 09 FA  JP FA09
$8F06: CD FB 9C  CALL 9CFB
$8F09: CD 14 9D  CALL 9D14
$8F0C: D8        RET C
$8F0D: F5        PUSH AF
$8F0E: 4F        LD C,A
$8F0F: CD 90 9D  CALL 9D90
$8F12: F1        POP AF
$8F13: C9        RET
$8F14: FE 0D     CP 0D
$8F16: C8        RET Z
$8F17: FE 0A     CP 0A
$8F19: C8        RET Z
$8F1A: FE 09     CP 09
$8F1C: C8        RET Z
$8F1D: FE 08     CP 08
$8F1F: C8        RET Z
$8F20: FE 20     CP 20
$8F22: C9        RET
$8F23: 3A 0E 9F  LD A,(9F0E)
$8F26: B7        OR A
$8F27: C2 45 9D  JP NZ,9D45
$8F2A: CD 06 FA  CALL FA06
$8F2D: E6 01     AND 01
$8F2F: C8        RET Z
$8F30: CD 09 FA  CALL FA09
$8F33: FE 13     CP 13
$8F35: C2 42 9D  JP NZ,9D42
$8F38: CD 09 FA  CALL FA09
$8F3B: FE 03     CP 03
$8F3D: CA 00 00  JP Z,0000
$8F40: AF        XOR A
$8F41: C9        RET
$8F42: 32 0E 9F  LD (9F0E),A
$8F45: 3E 01     LD A,01
$8F47: C9        RET
$8F48: 3A 0A 9F  LD A,(9F0A)
$8F4B: B7        OR A
$8F4C: C2 62 9D  JP NZ,9D62
$8F4F: C5        PUSH BC
$8F50: CD 23 9D  CALL 9D23
$8F53: C1        POP BC
$8F54: C5        PUSH BC
$8F55: CD 0C FA  CALL FA0C
$8F58: C1        POP BC
$8F59: C5        PUSH BC
$8F5A: 3A 0D 9F  LD A,(9F0D)
$8F5D: B7        OR A
$8F5E: C4 0F FA  CALL NZ,FA0F
$8F61: C1        POP BC
$8F62: 79        LD A,C
$8F63: 21 0C 9F  LD HL,9F0C
$8F66: FE 7F     CP 7F
$8F68: C8        RET Z
$8F69: 34        INC (HL)
$8F6A: FE 20     CP 20
$8F6C: D0        RET NC
$8F6D: 35        DEC (HL)
$8F6E: 7E        LD A,(HL)
$8F6F: B7        OR A
$8F70: C8        RET Z
$8F71: 79        LD A,C
$8F72: FE 08     CP 08
$8F74: C2 79 9D  JP NZ,9D79
$8F77: 35        DEC (HL)
$8F78: C9        RET
$8F79: FE 0A     CP 0A
$8F7B: C0        RET NZ
$8F7C: 36 00     LD (HL),00
$8F7E: C9        RET
$8F7F: 79        LD A,C
$8F80: CD 14 9D  CALL 9D14
$8F83: D2 90 9D  JP NC,9D90
$8F86: F5        PUSH AF
$8F87: 0E 5E     LD C,5E
$8F89: CD 48 9D  CALL 9D48
$8F8C: F1        POP AF
$8F8D: F6 40     OR 40
$8F8F: 4F        LD C,A
$8F90: 79        LD A,C
$8F91: FE 09     CP 09
$8F93: C2 48 9D  JP NZ,9D48
$8F96: 0E 20     LD C,20
$8F98: CD 48 9D  CALL 9D48
$8F9B: 3A 0C 9F  LD A,(9F0C)
$8F9E: E6 07     AND 07
$8FA0: C2 96 9D  JP NZ,9D96
$8FA3: C9        RET
$8FA4: CD AC 9D  CALL 9DAC
$8FA7: 0E 20     LD C,20
$8FA9: CD 0C FA  CALL FA0C
$8FAC: 0E 08     LD C,08
$8FAE: C3 0C FA  JP FA0C
$8FB1: 0E 23     LD C,23
$8FB3: CD 48 9D  CALL 9D48
$8FB6: CD C9 9D  CALL 9DC9
$8FB9: 3A 0C 9F  LD A,(9F0C)
$8FBC: 21 0B 9F  LD HL,9F0B
$8FBF: BE        CP (HL)
$8FC0: D0        RET NC
$8FC1: 0E 20     LD C,20
$8FC3: CD 48 9D  CALL 9D48
$8FC6: C3 B9 9D  JP 9DB9
$8FC9: 0E 0D     LD C,0D
$8FCB: CD 48 9D  CALL 9D48
$8FCE: 0E 0A     LD C,0A
$8FD0: C3 48 9D  JP 9D48
$8FD3: 0A        LD A,(BC)
$8FD4: FE 24     CP 24
$8FD6: C8        RET Z
$8FD7: 03        INC BC
$8FD8: C5        PUSH BC
$8FD9: 4F        LD C,A
$8FDA: CD 90 9D  CALL 9D90
$8FDD: C1        POP BC
$8FDE: C3 D3 9D  JP 9DD3
$8FE1: 3A 0C 9F  LD A,(9F0C)
$8FE4: 32 0B 9F  LD (9F0B),A
$8FE7: 2A 43 9F  LD HL,(9F43)
$8FEA: 4E        LD C,(HL)
$8FEB: 23        INC HL
$8FEC: E5        PUSH HL
$8FED: 06 00     LD B,00
$8FEF: C5        PUSH BC
$8FF0: E5        PUSH HL
$8FF1: CD FB 9C  CALL 9CFB
$8FF4: E6 7F     AND 7F
$8FF6: E1        POP HL
$8FF7: C1        POP BC
$8FF8: FE 0D     CP 0D
$8FFA: CA C1 9E  JP Z,9EC1
$8FFD: FE 0A     CP 0A
$8FFF: CA C2 CD  JP Z,CDC2
$9002: A4        AND H
$9003: 01 EC FF  LD BC,FFEC
$9006: 09        ADD HL,BC
$9007: EB        EX DE,HL
$9008: 09        ADD HL,BC
$9009: 1A        LD A,(DE)
$900A: BE        CP (HL)
$900B: DA 17 A5  JP C,A517
$900E: 77        LD (HL),A
$900F: 01 03 00  LD BC,0003
$9012: 09        ADD HL,BC
$9013: EB        EX DE,HL
$9014: 09        ADD HL,BC
$9015: 7E        LD A,(HL)
$9016: 12        LD (DE),A
$9017: 3E FF     LD A,FF
$9019: 32 D2 A9  LD (A9D2),A
$901C: C3 10 A4  JP A410
$901F: 21 45 9F  LD HL,9F45
$9022: 35        DEC (HL)
$9023: C9        RET
$9024: CD 54 A1  CALL A154
$9027: 2A 43 9F  LD HL,(9F43)
$902A: E5        PUSH HL
$902B: 21 AC A9  LD HL,A9AC
$902E: 22 43 9F  LD (9F43),HL
$9031: 0E 01     LD C,01
$9033: CD 18 A3  CALL A318
$9036: CD F5 A1  CALL A1F5
$9039: E1        POP HL
$903A: 22 43 9F  LD (9F43),HL
$903D: C8        RET Z
$903E: EB        EX DE,HL
$903F: 21 0F 00  LD HL,000F
$9042: 19        ADD HL,DE
$9043: 0E 11     LD C,11
$9045: AF        XOR A
$9046: 77        LD (HL),A
$9047: 23        INC HL
$9048: 0D        DEC C
$9049: C2 46 A5  JP NZ,A546
$904C: 21 0D 00  LD HL,000D
$904F: 19        ADD HL,DE
$9050: 77        LD (HL),A
$9051: CD 8C A1  CALL A18C
$9054: CD FD A3  CALL A3FD
$9057: C3 78 A1  JP A178
$905A: AF        XOR A
$905B: 32 D2 A9  LD (A9D2),A
$905E: CD A2 A4  CALL A4A2
$9061: CD F5 A1  CALL A1F5
$9064: C8        RET Z
$9065: 2A 43 9F  LD HL,(9F43)
$9068: 01 0C 00  LD BC,000C
$906B: 09        ADD HL,BC
$906C: 7E        LD A,(HL)
$906D: 3C        INC A
$906E: E6 1F     AND 1F
$9070: 77        LD (HL),A
$9071: CA 83 A5  JP Z,A583
$9074: 47        LD B,A
$9075: 3A C5 A9  LD A,(A9C5)
$9078: A0        AND B
$9079: 21 D2 A9  LD HL,A9D2
$907C: A6        AND (HL)
$907D: CA 8E A5  JP Z,A58E
$9080: C3 AC A5  JP A5AC
$9083: 01 02 00  LD BC,0002
$9086: 09        ADD HL,BC
$9087: 34        INC (HL)
$9088: 7E        LD A,(HL)
$9089: E6 0F     AND 0F
$908B: CA B6 A5  JP Z,A5B6
$908E: 0E 0F     LD C,0F
$9090: CD 18 A3  CALL A318
$9093: CD F5 A1  CALL A1F5
$9096: C2 AC A5  JP NZ,A5AC
$9099: 3A D3 A9  LD A,(A9D3)
$909C: 3C        INC A
$909D: CA B6 A5  JP Z,A5B6
$90A0: CD 24 A5  CALL A524
$90A3: CD F5 A1  CALL A1F5
$90A6: CA B6 A5  JP Z,A5B6
$90A9: C3 AF A5  JP A5AF
$90AC: CD 5A A4  CALL A45A
$90AF: CD BB A0  CALL A0BB
$90B2: AF        XOR A
$90B3: C3 01 9F  JP 9F01
$90B6: CD 05 9F  CALL 9F05
$90B9: C3 78 A1  JP A178
$90BC: 3E 01     LD A,01
$90BE: 32 D5 A9  LD (A9D5),A
$90C1: 3E FF     LD A,FF
$90C3: 32 D3 A9  LD (A9D3),A
$90C6: CD BB A0  CALL A0BB
$90C9: 3A E3 A9  LD A,(A9E3)
$90CC: 21 E1 A9  LD HL,A9E1
$90CF: BE        CP (HL)
$90D0: DA E6 A5  JP C,A5E6
$90D3: FE 80     CP 80
$90D5: C2 FB A5  JP NZ,A5FB
$90D8: CD 5A A5  CALL A55A
$90DB: AF        XOR A
$90DC: 32 E3 A9  LD (A9E3),A
$90DF: 3A 45 9F  LD A,(9F45)
$90E2: B7        OR A
$90E3: C2 FB A5  JP NZ,A5FB
$90E6: CD 77 A0  CALL A077
$90E9: CD 84 A0  CALL A084
$90EC: CA FB A5  JP Z,A5FB
$90EF: CD 8A A0  CALL A08A
$90F2: CD D1 9F  CALL 9FD1
$90F5: CD B2 9F  CALL 9FB2
$90F8: C3 D2 A0  JP A0D2
$90FB: C3 05 9F  JP 9F05
$90FE: 3E 01     LD A,01
$9100: C1        POP BC
$9101: 9E        SBC A,(HL)
$9102: FE 08     CP 08
$9104: C2 16 9E  JP NZ,9E16
$9107: 78        LD A,B
$9108: B7        OR A
$9109: CA EF 9D  JP Z,9DEF
$910C: 05        DEC B
$910D: 3A 0C 9F  LD A,(9F0C)
$9110: 32 0A 9F  LD (9F0A),A
$9113: C3 70 9E  JP 9E70
$9116: FE 7F     CP 7F
$9118: C2 26 9E  JP NZ,9E26
$911B: 78        LD A,B
$911C: B7        OR A
$911D: CA EF 9D  JP Z,9DEF
$9120: 7E        LD A,(HL)
$9121: 05        DEC B
$9122: 2B        DEC HL
$9123: C3 A9 9E  JP 9EA9
$9126: FE 05     CP 05
$9128: C2 37 9E  JP NZ,9E37
$912B: C5        PUSH BC
$912C: E5        PUSH HL
$912D: CD C9 9D  CALL 9DC9
$9130: AF        XOR A
$9131: 32 0B 9F  LD (9F0B),A
$9134: C3 F1 9D  JP 9DF1
$9137: FE 10     CP 10
$9139: C2 48 9E  JP NZ,9E48
$913C: E5        PUSH HL
$913D: 21 0D 9F  LD HL,9F0D
$9140: 3E 01     LD A,01
$9142: 96        SUB (HL)
$9143: 77        LD (HL),A
$9144: E1        POP HL
$9145: C3 EF 9D  JP 9DEF
$9148: FE 18     CP 18
$914A: C2 5F 9E  JP NZ,9E5F
$914D: E1        POP HL
$914E: 3A 0B 9F  LD A,(9F0B)
$9151: 21 0C 9F  LD HL,9F0C
$9154: BE        CP (HL)
$9155: D2 E1 9D  JP NC,9DE1
$9158: 35        DEC (HL)
$9159: CD A4 9D  CALL 9DA4
$915C: C3 4E 9E  JP 9E4E
$915F: FE 15     CP 15
$9161: C2 6B 9E  JP NZ,9E6B
$9164: CD B1 9D  CALL 9DB1
$9167: E1        POP HL
$9168: C3 E1 9D  JP 9DE1
$916B: FE 12     CP 12
$916D: C2 A6 9E  JP NZ,9EA6
$9170: C5        PUSH BC
$9171: CD B1 9D  CALL 9DB1
$9174: C1        POP BC
$9175: E1        POP HL
$9176: E5        PUSH HL
$9177: C5        PUSH BC
$9178: 78        LD A,B
$9179: B7        OR A
$917A: CA 8A 9E  JP Z,9E8A
$917D: 23        INC HL
$917E: 4E        LD C,(HL)
$917F: 05        DEC B
$9180: C5        PUSH BC
$9181: E5        PUSH HL
$9182: CD 7F 9D  CALL 9D7F
$9185: E1        POP HL
$9186: C1        POP BC
$9187: C3 78 9E  JP 9E78
$918A: E5        PUSH HL
$918B: 3A 0A 9F  LD A,(9F0A)
$918E: B7        OR A
$918F: CA F1 9D  JP Z,9DF1
$9192: 21 0C 9F  LD HL,9F0C
$9195: 96        SUB (HL)
$9196: 32 0A 9F  LD (9F0A),A
$9199: CD A4 9D  CALL 9DA4
$919C: 21 0A 9F  LD HL,9F0A
$919F: 35        DEC (HL)
$91A0: C2 99 9E  JP NZ,9E99
$91A3: C3 F1 9D  JP 9DF1
$91A6: 23        INC HL
$91A7: 77        LD (HL),A
$91A8: 04        INC B
$91A9: C5        PUSH BC
$91AA: E5        PUSH HL
$91AB: 4F        LD C,A
$91AC: CD 7F 9D  CALL 9D7F
$91AF: E1        POP HL
$91B0: C1        POP BC
$91B1: 7E        LD A,(HL)
$91B2: FE 03     CP 03
$91B4: 78        LD A,B
$91B5: C2 BD 9E  JP NZ,9EBD
$91B8: FE 01     CP 01
$91BA: CA 00 00  JP Z,0000
$91BD: B9        CP C
$91BE: DA EF 9D  JP C,9DEF
$91C1: E1        POP HL
$91C2: 70        LD (HL),B
$91C3: 0E 0D     LD C,0D
$91C5: C3 48 9D  JP 9D48
$91C8: CD 06 9D  CALL 9D06
$91CB: C3 01 9F  JP 9F01
$91CE: CD 15 FA  CALL FA15
$91D1: C3 01 9F  JP 9F01
$91D4: 79        LD A,C
$91D5: 3C        INC A
$91D6: CA E0 9E  JP Z,9EE0
$91D9: 3C        INC A
$91DA: CA 06 FA  JP Z,FA06
$91DD: C3 0C FA  JP FA0C
$91E0: CD 06 FA  CALL FA06
$91E3: B7        OR A
$91E4: CA 91 A9  JP Z,A991
$91E7: CD 09 FA  CALL FA09
$91EA: C3 01 9F  JP 9F01
$91ED: 3A 03 00  LD A,(0003)
$91F0: C3 01 9F  JP 9F01
$91F3: 21 03 00  LD HL,0003
$91F6: 71        LD (HL),C
$91F7: C9        RET
$91F8: EB        EX DE,HL
$91F9: 4D        LD C,L
$91FA: 44        LD B,H
$91FB: C3 D3 9D  JP 9DD3
$91FE: CD 23 32  CALL 3223
$9201: D5        PUSH DE
$9202: A9        XOR C
$9203: 3E 00     LD A,00
$9205: 32 D3 A9  LD (A9D3),A
$9208: CD 54 A1  CALL A154
$920B: 2A 43 9F  LD HL,(9F43)
$920E: CD 47 A1  CALL A147
$9211: CD BB A0  CALL A0BB
$9214: 3A E3 A9  LD A,(A9E3)
$9217: FE 80     CP 80
$9219: D2 05 9F  JP NC,9F05
$921C: CD 77 A0  CALL A077
$921F: CD 84 A0  CALL A084
$9222: 0E 00     LD C,00
$9224: C2 6E A6  JP NZ,A66E
$9227: CD 3E A0  CALL A03E
$922A: 32 D7 A9  LD (A9D7),A
$922D: 01 00 00  LD BC,0000
$9230: B7        OR A
$9231: CA 3B A6  JP Z,A63B
$9234: 4F        LD C,A
$9235: 0B        DEC BC
$9236: CD 5E A0  CALL A05E
$9239: 44        LD B,H
$923A: 4D        LD C,L
$923B: CD BE A3  CALL A3BE
$923E: 7D        LD A,L
$923F: B4        OR H
$9240: C2 48 A6  JP NZ,A648
$9243: 3E 02     LD A,02
$9245: C3 01 9F  JP 9F01
$9248: 22 E5 A9  LD (A9E5),HL
$924B: EB        EX DE,HL
$924C: 2A 43 9F  LD HL,(9F43)
$924F: 01 10 00  LD BC,0010
$9252: 09        ADD HL,BC
$9253: 3A DD A9  LD A,(A9DD)
$9256: B7        OR A
$9257: 3A D7 A9  LD A,(A9D7)
$925A: CA 64 A6  JP Z,A664
$925D: CD 64 A1  CALL A164
$9260: 73        LD (HL),E
$9261: C3 6C A6  JP A66C
$9264: 4F        LD C,A
$9265: 06 00     LD B,00
$9267: 09        ADD HL,BC
$9268: 09        ADD HL,BC
$9269: 73        LD (HL),E
$926A: 23        INC HL
$926B: 72        LD (HL),D
$926C: 0E 02     LD C,02
$926E: 3A 45 9F  LD A,(9F45)
$9271: B7        OR A
$9272: C0        RET NZ
$9273: C5        PUSH BC
$9274: CD 8A A0  CALL A08A
$9277: 3A D5 A9  LD A,(A9D5)
$927A: 3D        DEC A
$927B: 3D        DEC A
$927C: C2 BB A6  JP NZ,A6BB
$927F: C1        POP BC
$9280: C5        PUSH BC
$9281: 79        LD A,C
$9282: 3D        DEC A
$9283: 3D        DEC A
$9284: C2 BB A6  JP NZ,A6BB
$9287: E5        PUSH HL
$9288: 2A B9 A9  LD HL,(A9B9)
$928B: 57        LD D,A
$928C: 77        LD (HL),A
$928D: 23        INC HL
$928E: 14        INC D
$928F: F2 8C A6  JP P,A68C
$9292: CD E0 A1  CALL A1E0
$9295: 2A E7 A9  LD HL,(A9E7)
$9298: 0E 02     LD C,02
$929A: 22 E5 A9  LD (A9E5),HL
$929D: C5        PUSH BC
$929E: CD D1 9F  CALL 9FD1
$92A1: C1        POP BC
$92A2: CD B8 9F  CALL 9FB8
$92A5: 2A E5 A9  LD HL,(A9E5)
$92A8: 0E 00     LD C,00
$92AA: 3A C4 A9  LD A,(A9C4)
$92AD: 47        LD B,A
$92AE: A5        AND L
$92AF: B8        CP B
$92B0: 23        INC HL
$92B1: C2 9A A6  JP NZ,A69A
$92B4: E1        POP HL
$92B5: 22 E5 A9  LD (A9E5),HL
$92B8: CD DA A1  CALL A1DA
$92BB: CD D1 9F  CALL 9FD1
$92BE: C1        POP BC
$92BF: C5        PUSH BC
$92C0: CD B8 9F  CALL 9FB8
$92C3: C1        POP BC
$92C4: 3A E3 A9  LD A,(A9E3)
$92C7: 21 E1 A9  LD HL,A9E1
$92CA: BE        CP (HL)
$92CB: DA D2 A6  JP C,A6D2
$92CE: 77        LD (HL),A
$92CF: 34        INC (HL)
$92D0: 0E 02     LD C,02
$92D2: 0D        DEC C
$92D3: 0D        DEC C
$92D4: 21 DF A6  LD HL,A6DF
$92D7: F5        PUSH AF
$92D8: CD 69 A1  CALL A169
$92DB: E6 7F     AND 7F
$92DD: 77        LD (HL),A
$92DE: F1        POP AF
$92DF: FE 7F     CP 7F
$92E1: C2 00 A7  JP NZ,A700
$92E4: 3A D5 A9  LD A,(A9D5)
$92E7: FE 01     CP 01
$92E9: C2 00 A7  JP NZ,A700
$92EC: CD D2 A0  CALL A0D2
$92EF: CD 5A A5  CALL A55A
$92F2: 21 45 9F  LD HL,9F45
$92F5: 7E        LD A,(HL)
$92F6: B7        OR A
$92F7: C2 FE A6  JP NZ,A6FE
$92FA: 3D        DEC A
$92FB: 32 E3 A9  LD (A9E3),A
$92FE: 36 00     LD (HL),00
$9300: 9D        SBC A,L
$9301: 32 45 9F  LD (9F45),A
$9304: C9        RET
$9305: 3E 01     LD A,01
$9307: C3 01 9F  JP 9F01
$930A: 00        NOP
$930B: 00        NOP
$930C: 00        NOP
$930D: 00        NOP
$930E: 00        NOP
$930F: 00        NOP
$9310: 00        NOP
$9311: 00        NOP
$9312: 00        NOP
$9313: 00        NOP
$9314: 00        NOP
$9315: 00        NOP
$9316: 00        NOP
$9317: 00        NOP
$9318: 00        NOP
$9319: 00        NOP
$931A: 00        NOP
$931B: 00        NOP
$931C: 00        NOP
$931D: 00        NOP
$931E: 00        NOP
$931F: 00        NOP
$9320: 00        NOP
$9321: 00        NOP
$9322: 00        NOP
$9323: 00        NOP
$9324: 00        NOP
$9325: 00        NOP
$9326: 00        NOP
$9327: 00        NOP
$9328: 00        NOP
$9329: 00        NOP
$932A: 00        NOP
$932B: 00        NOP
$932C: 00        NOP
$932D: 00        NOP
$932E: 00        NOP
$932F: 00        NOP
$9330: 00        NOP
$9331: 00        NOP
$9332: 00        NOP
$9333: 00        NOP
$9334: 00        NOP
$9335: 00        NOP
$9336: 00        NOP
$9337: 00        NOP
$9338: 00        NOP
$9339: 00        NOP
$933A: 00        NOP
$933B: 00        NOP
$933C: 00        NOP
$933D: 00        NOP
$933E: 00        NOP
$933F: 00        NOP
$9340: 00        NOP
$9341: 00        NOP
$9342: 00        NOP
$9343: 00        NOP
$9344: 00        NOP
$9345: 00        NOP
$9346: 00        NOP
$9347: 21 0B 9C  LD HL,9C0B
$934A: 5E        LD E,(HL)
$934B: 23        INC HL
$934C: 56        LD D,(HL)
$934D: EB        EX DE,HL
$934E: E9        JP (HL)
$934F: 0C        INC C
$9350: 0D        DEC C
$9351: C8        RET Z
$9352: 1A        LD A,(DE)
$9353: 77        LD (HL),A
$9354: 13        INC DE
$9355: 23        INC HL
$9356: C3 50 9F  JP 9F50
$9359: 3A 42 9F  LD A,(9F42)
$935C: 4F        LD C,A
$935D: CD 1B FA  CALL FA1B
$9360: 7C        LD A,H
$9361: B5        OR L
$9362: C8        RET Z
$9363: 5E        LD E,(HL)
$9364: 23        INC HL
$9365: 56        LD D,(HL)
$9366: 23        INC HL
$9367: 22 B3 A9  LD (A9B3),HL
$936A: 23        INC HL
$936B: 23        INC HL
$936C: 22 B5 A9  LD (A9B5),HL
$936F: 23        INC HL
$9370: 23        INC HL
$9371: 22 B7 A9  LD (A9B7),HL
$9374: 23        INC HL
$9375: 23        INC HL
$9376: EB        EX DE,HL
$9377: 22 D0 A9  LD (A9D0),HL
$937A: 21 B9 A9  LD HL,A9B9
$937D: 0E 08     LD C,08
$937F: CD 4F 9F  CALL 9F4F
$9382: 2A BB A9  LD HL,(A9BB)
$9385: EB        EX DE,HL
$9386: 21 C1 A9  LD HL,A9C1
$9389: 0E 0F     LD C,0F
$938B: CD 4F 9F  CALL 9F4F
$938E: 2A C6 A9  LD HL,(A9C6)
$9391: 7C        LD A,H
$9392: 21 DD A9  LD HL,A9DD
$9395: 36 FF     LD (HL),FF
$9397: B7        OR A
$9398: CA 9D 9F  JP Z,9F9D
$939B: 36 00     LD (HL),00
$939D: 3E FF     LD A,FF
$939F: B7        OR A
$93A0: C9        RET
$93A1: CD 18 FA  CALL FA18
$93A4: AF        XOR A
$93A5: 2A B5 A9  LD HL,(A9B5)
$93A8: 77        LD (HL),A
$93A9: 23        INC HL
$93AA: 77        LD (HL),A
$93AB: 2A B7 A9  LD HL,(A9B7)
$93AE: 77        LD (HL),A
$93AF: 23        INC HL
$93B0: 77        LD (HL),A
$93B1: C9        RET
$93B2: CD 27 FA  CALL FA27
$93B5: C3 BB 9F  JP 9FBB
$93B8: CD 2A FA  CALL FA2A
$93BB: B7        OR A
$93BC: C8        RET Z
$93BD: 21 09 9C  LD HL,9C09
$93C0: C3 4A 9F  JP 9F4A
$93C3: 2A EA A9  LD HL,(A9EA)
$93C6: 0E 02     LD C,02
$93C8: CD EA A0  CALL A0EA
$93CB: 22 E5 A9  LD (A9E5),HL
$93CE: 22 EC A9  LD (A9EC),HL
$93D1: 21 E5 A9  LD HL,A9E5
$93D4: 4E        LD C,(HL)
$93D5: 23        INC HL
$93D6: 46        LD B,(HL)
$93D7: 2A B7 A9  LD HL,(A9B7)
$93DA: 5E        LD E,(HL)
$93DB: 23        INC HL
$93DC: 56        LD D,(HL)
$93DD: 2A B5 A9  LD HL,(A9B5)
$93E0: 7E        LD A,(HL)
$93E1: 23        INC HL
$93E2: 66        LD H,(HL)
$93E3: 6F        LD L,A
$93E4: 79        LD A,C
$93E5: 93        SUB E
$93E6: 78        LD A,B
$93E7: 9A        SBC A,D
$93E8: D2 FA 9F  JP NC,9FFA
$93EB: E5        PUSH HL
$93EC: 2A C1 A9  LD HL,(A9C1)
$93EF: 7B        LD A,E
$93F0: 95        SUB L
$93F1: 5F        LD E,A
$93F2: 7A        LD A,D
$93F3: 9C        SBC A,H
$93F4: 57        LD D,A
$93F5: E1        POP HL
$93F6: 2B        DEC HL
$93F7: C3 E4 9F  JP 9FE4
$93FA: E5        PUSH HL
$93FB: 2A C1 A9  LD HL,(A9C1)
$93FE: 19        ADD HL,DE
$93FF: DA C3 D2  JP C,D2C3
$9402: A0        AND B
$9403: AF        XOR A
$9404: 32 D5 A9  LD (A9D5),A
$9407: C5        PUSH BC
$9408: 2A 43 9F  LD HL,(9F43)
$940B: EB        EX DE,HL
$940C: 21 21 00  LD HL,0021
$940F: 19        ADD HL,DE
$9410: 7E        LD A,(HL)
$9411: E6 7F     AND 7F
$9413: F5        PUSH AF
$9414: 7E        LD A,(HL)
$9415: 17        RLA
$9416: 23        INC HL
$9417: 7E        LD A,(HL)
$9418: 17        RLA
$9419: E6 1F     AND 1F
$941B: 4F        LD C,A
$941C: 7E        LD A,(HL)
$941D: 1F        RRA
$941E: 1F        RRA
$941F: 1F        RRA
$9420: 1F        RRA
$9421: E6 0F     AND 0F
$9423: 47        LD B,A
$9424: F1        POP AF
$9425: 23        INC HL
$9426: 6E        LD L,(HL)
$9427: 2C        INC L
$9428: 2D        DEC L
$9429: 2E 06     LD L,06
$942B: C2 8B A7  JP NZ,A78B
$942E: 21 20 00  LD HL,0020
$9431: 19        ADD HL,DE
$9432: 77        LD (HL),A
$9433: 21 0C 00  LD HL,000C
$9436: 19        ADD HL,DE
$9437: 79        LD A,C
$9438: 96        SUB (HL)
$9439: C2 47 A7  JP NZ,A747
$943C: 21 0E 00  LD HL,000E
$943F: 19        ADD HL,DE
$9440: 78        LD A,B
$9441: 96        SUB (HL)
$9442: E6 7F     AND 7F
$9444: CA 7F A7  JP Z,A77F
$9447: C5        PUSH BC
$9448: D5        PUSH DE
$9449: CD A2 A4  CALL A4A2
$944C: D1        POP DE
$944D: C1        POP BC
$944E: 2E 03     LD L,03
$9450: 3A 45 9F  LD A,(9F45)
$9453: 3C        INC A
$9454: CA 84 A7  JP Z,A784
$9457: 21 0C 00  LD HL,000C
$945A: 19        ADD HL,DE
$945B: 71        LD (HL),C
$945C: 21 0E 00  LD HL,000E
$945F: 19        ADD HL,DE
$9460: 70        LD (HL),B
$9461: CD 51 A4  CALL A451
$9464: 3A 45 9F  LD A,(9F45)
$9467: 3C        INC A
$9468: C2 7F A7  JP NZ,A77F
$946B: C1        POP BC
$946C: C5        PUSH BC
$946D: 2E 04     LD L,04
$946F: 0C        INC C
$9470: CA 84 A7  JP Z,A784
$9473: CD 24 A5  CALL A524
$9476: 2E 05     LD L,05
$9478: 3A 45 9F  LD A,(9F45)
$947B: 3C        INC A
$947C: CA 84 A7  JP Z,A784
$947F: C1        POP BC
$9480: AF        XOR A
$9481: C3 01 9F  JP 9F01
$9484: E5        PUSH HL
$9485: CD 69 A1  CALL A169
$9488: 36 C0     LD (HL),C0
$948A: E1        POP HL
$948B: C1        POP BC
$948C: 7D        LD A,L
$948D: 32 45 9F  LD (9F45),A
$9490: C3 78 A1  JP A178
$9493: 0E FF     LD C,FF
$9495: CD 03 A7  CALL A703
$9498: CC C1 A5  CALL Z,A5C1
$949B: C9        RET
$949C: 0E 00     LD C,00
$949E: CD 03 A7  CALL A703
$94A1: CC 03 A6  CALL Z,A603
$94A4: C9        RET
$94A5: EB        EX DE,HL
$94A6: 19        ADD HL,DE
$94A7: 4E        LD C,(HL)
$94A8: 06 00     LD B,00
$94AA: 21 0C 00  LD HL,000C
$94AD: 19        ADD HL,DE
$94AE: 7E        LD A,(HL)
$94AF: 0F        RRCA
$94B0: E6 80     AND 80
$94B2: 81        ADD A,C
$94B3: 4F        LD C,A
$94B4: 3E 00     LD A,00
$94B6: 88        ADC A,B
$94B7: 47        LD B,A
$94B8: 7E        LD A,(HL)
$94B9: 0F        RRCA
$94BA: E6 0F     AND 0F
$94BC: 80        ADD A,B
$94BD: 47        LD B,A
$94BE: 21 0E 00  LD HL,000E
$94C1: 19        ADD HL,DE
$94C2: 7E        LD A,(HL)
$94C3: 87        ADD A,A
$94C4: 87        ADD A,A
$94C5: 87        ADD A,A
$94C6: 87        ADD A,A
$94C7: F5        PUSH AF
$94C8: 80        ADD A,B
$94C9: 47        LD B,A
$94CA: F5        PUSH AF
$94CB: E1        POP HL
$94CC: 7D        LD A,L
$94CD: E1        POP HL
$94CE: B5        OR L
$94CF: E6 01     AND 01
$94D1: C9        RET
$94D2: 0E 0C     LD C,0C
$94D4: CD 18 A3  CALL A318
$94D7: 2A 43 9F  LD HL,(9F43)
$94DA: 11 21 00  LD DE,0021
$94DD: 19        ADD HL,DE
$94DE: E5        PUSH HL
$94DF: 72        LD (HL),D
$94E0: 23        INC HL
$94E1: 72        LD (HL),D
$94E2: 23        INC HL
$94E3: 72        LD (HL),D
$94E4: CD F5 A1  CALL A1F5
$94E7: CA 0C A8  JP Z,A80C
$94EA: CD 5E A1  CALL A15E
$94ED: 11 0F 00  LD DE,000F
$94F0: CD A5 A7  CALL A7A5
$94F3: E1        POP HL
$94F4: E5        PUSH HL
$94F5: 5F        LD E,A
$94F6: 79        LD A,C
$94F7: 96        SUB (HL)
$94F8: 23        INC HL
$94F9: 78        LD A,B
$94FA: 9E        SBC A,(HL)
$94FB: 23        INC HL
$94FC: 7B        LD A,E
$94FD: 9E        SBC A,(HL)
$94FE: DA 06 A8  JP C,A806
$9501: 73        LD (HL),E
$9502: 2B        DEC HL
$9503: 70        LD (HL),B
$9504: 2B        DEC HL
$9505: 71        LD (HL),C
$9506: CD 2D A3  CALL A32D
$9509: C3 E4 A7  JP A7E4
$950C: E1        POP HL
$950D: C9        RET
$950E: 2A 43 9F  LD HL,(9F43)
$9511: 11 20 00  LD DE,0020
$9514: CD A5 A7  CALL A7A5
$9517: 21 21 00  LD HL,0021
$951A: 19        ADD HL,DE
$951B: 71        LD (HL),C
$951C: 23        INC HL
$951D: 70        LD (HL),B
$951E: 23        INC HL
$951F: 77        LD (HL),A
$9520: C9        RET
$9521: 2A AF A9  LD HL,(A9AF)
$9524: 3A 42 9F  LD A,(9F42)
$9527: 4F        LD C,A
$9528: CD EA A0  CALL A0EA
$952B: E5        PUSH HL
$952C: EB        EX DE,HL
$952D: CD 59 9F  CALL 9F59
$9530: E1        POP HL
$9531: CC 47 9F  CALL Z,9F47
$9534: 7D        LD A,L
$9535: 1F        RRA
$9536: D8        RET C
$9537: 2A AF A9  LD HL,(A9AF)
$953A: 4D        LD C,L
$953B: 44        LD B,H
$953C: CD 0B A1  CALL A10B
$953F: 22 AF A9  LD (A9AF),HL
$9542: C3 A3 A2  JP A2A3
$9545: 3A D6 A9  LD A,(A9D6)
$9548: 21 42 9F  LD HL,9F42
$954B: BE        CP (HL)
$954C: C8        RET Z
$954D: 77        LD (HL),A
$954E: C3 21 A8  JP A821
$9551: 3E FF     LD A,FF
$9553: 32 DE A9  LD (A9DE),A
$9556: 2A 43 9F  LD HL,(9F43)
$9559: 7E        LD A,(HL)
$955A: E6 1F     AND 1F
$955C: 3D        DEC A
$955D: 32 D6 A9  LD (A9D6),A
$9560: FE 1E     CP 1E
$9562: D2 75 A8  JP NC,A875
$9565: 3A 42 9F  LD A,(9F42)
$9568: 32 DF A9  LD (A9DF),A
$956B: 7E        LD A,(HL)
$956C: 32 E0 A9  LD (A9E0),A
$956F: E6 E0     AND E0
$9571: 77        LD (HL),A
$9572: CD 45 A8  CALL A845
$9575: 3A 41 9F  LD A,(9F41)
$9578: 2A 43 9F  LD HL,(9F43)
$957B: B6        OR (HL)
$957C: 77        LD (HL),A
$957D: C9        RET
$957E: 3E 22     LD A,22
$9580: C3 01 9F  JP 9F01
$9583: 21 00 00  LD HL,0000
$9586: 22 AD A9  LD (A9AD),HL
$9589: 22 AF A9  LD (A9AF),HL
$958C: AF        XOR A
$958D: 32 42 9F  LD (9F42),A
$9590: 21 80 00  LD HL,0080
$9593: 22 B1 A9  LD (A9B1),HL
$9596: CD DA A1  CALL A1DA
$9599: C3 21 A8  JP A821
$959C: CD 72 A1  CALL A172
$959F: CD 51 A8  CALL A851
$95A2: C3 51 A4  JP A451
$95A5: CD 51 A8  CALL A851
$95A8: C3 A2 A4  JP A4A2
$95AB: 0E 00     LD C,00
$95AD: EB        EX DE,HL
$95AE: 7E        LD A,(HL)
$95AF: FE 3F     CP 3F
$95B1: CA C2 A8  JP Z,A8C2
$95B4: CD A6 A0  CALL A0A6
$95B7: 7E        LD A,(HL)
$95B8: FE 3F     CP 3F
$95BA: C4 72 A1  CALL NZ,A172
$95BD: CD 51 A8  CALL A851
$95C0: 0E 0F     LD C,0F
$95C2: CD 18 A3  CALL A318
$95C5: C3 E9 A1  JP A1E9
$95C8: 2A D9 A9  LD HL,(A9D9)
$95CB: 22 43 9F  LD (9F43),HL
$95CE: CD 51 A8  CALL A851
$95D1: CD 2D A3  CALL A32D
$95D4: C3 E9 A1  JP A1E9
$95D7: CD 51 A8  CALL A851
$95DA: CD 9C A3  CALL A39C
$95DD: C3 01 A3  JP A301
$95E0: CD 51 A8  CALL A851
$95E3: C3 BC A5  JP A5BC
$95E6: CD 51 A8  CALL A851
$95E9: C3 FE A5  JP A5FE
$95EC: CD 72 A1  CALL A172
$95EF: CD 51 A8  CALL A851
$95F2: C3 24 A5  JP A524
$95F5: CD 51 A8  CALL A851
$95F8: CD 16 A4  CALL A416
$95FB: C3 01 A3  JP A301
$95FE: 2A AF FB  LD HL,(FBAF)
$9601: AF        XOR A
$9602: 32 04 00  LD (0004),A
$9605: 3A BB F3  LD A,(F3BB)
$9608: FE 06     CP 06
$960A: 20 0A     JR NZ,9616
$960C: 21 99 FD  LD HL,FD99
$960F: 22 80 F3  LD (F380),HL
$9612: D6 03     SUB 03
$9614: 18 13     JR 9629
$9616: FE 05     CP 05
$9618: 28 22     JR Z,963C
$961A: D6 03     SUB 03
$961C: 38 1E     JR C,963C
$961E: 20 09     JR NZ,9629
$9620: 21 15 FB  LD HL,FB15
$9623: 36 BE     LD (HL),BE
$9625: 23        INC HL
$9626: 23        INC HL
$9627: 36 1F     LD (HL),1F
$9629: F5        PUSH AF
$962A: CD 9D FF  CALL FF9D
$962D: F1        POP AF
$962E: 22 B9 FC  LD (FCB9),HL
$9631: CD 98 FF  CALL FF98
$9634: 22 37 FB  LD (FB37),HL
$9637: 3E 03     LD A,03
$9639: 32 05 FB  LD (FB05),A
$963C: 3A B9 F3  LD A,(F3B9)
$963F: D6 03     SUB 03
$9641: 38 06     JR C,9649
$9643: CD 9D FF  CALL FF9D
$9646: 22 59 FE  LD (FE59),HL
$9649: 3A BA F3  LD A,(F3BA)
$964C: D6 03     SUB 03
$964E: 38 14     JR C,9664
$9650: F5        PUSH AF
$9651: CD 9D FF  CALL FF9D
$9654: 22 6D FE  LD (FE6D),HL
$9657: F1        POP AF
$9658: FE 02     CP 02
$965A: 28 08     JR Z,9664
$965C: CD 98 FF  CALL FF98
$965F: 22 73 FE  LD (FE73),HL
$9662: 18 0B     JR 966F
$9664: 21 3E 1A  LD HL,1A3E
$9667: 22 72 FE  LD (FE72),HL
$966A: 3E C9     LD A,C9
$966C: 32 74 FE  LD (FE74),A
$966F: CD 82 FA  CALL FA82
$9672: 3A 98 F3  LD A,(F398)
$9675: CD A8 FF  CALL FFA8
$9678: 21 B7 FF  LD HL,FFB7
$967B: 7E        LD A,(HL)
$967C: B7        OR A
$967D: CA E3 FA  JP Z,FAE3
$9680: E5        PUSH HL
$9681: CD 4C FB  CALL FB4C
$9684: E1        POP HL
$9685: 23        INC HL
$9686: 18 F3     JR 967B
$9688: 0E FD     LD C,FD
$968A: 71        LD (HL),C
$968B: FD        DB $FD
$968C: 5B        LD E,E
$968D: FE A9     CP A9
$968F: FD        DB $FD
$9690: 4B        LD C,E
$9691: FE C1     CP C1
$9693: FD        DB $FD
$9694: B7        OR A
$9695: FD        DB $FD
$9696: B7        OR A
$9697: FD        DB $FD
$9698: 21 90 FF  LD HL,FF90
$969B: 18 03     JR 96A0
$969D: 21 88 FF  LD HL,FF88
$96A0: 87        ADD A,A
$96A1: 85        ADD A,L
$96A2: 6F        LD L,A
$96A3: 7E        LD A,(HL)
$96A4: 2C        INC L
$96A5: 66        LD H,(HL)
$96A6: 6F        LD L,A
$96A7: C9        RET
$96A8: B7        OR A
$96A9: F2 B4 FF  JP P,FFB4
$96AC: F5        PUSH AF
$96AD: 3A 97 F3  LD A,(F397)
$96B0: CD 4C FB  CALL FB4C
$96B3: F1        POP AF
$96B4: C3 4C FB  JP FB4C
$96B7: 0D        DEC C
$96B8: 0A        LD A,(BC)
$96B9: 0A        LD A,(BC)
$96BA: 0A        LD A,(BC)


; ============================================================================
; BOOT BANNER ($96BB-$96FF)
; ============================================================================

BOOT_BANNER:
            .BYTE $0D, $0A, $0A, $0A
            .ASCII "     Softcard CP/M"
            .BYTE $0D, $0A
            .ASCII "     60K Ver. 2.23"
            .BYTE $0D, $0A
            .ASCII "(c) 1980,1982 Microsoft"
            .BYTE $0D, $0A, $0D, $0A, $00
            .BYTE $FA       ; trailing byte (purpose: TBD)
