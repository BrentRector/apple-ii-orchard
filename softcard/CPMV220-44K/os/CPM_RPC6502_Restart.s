; ============================================================================
; CPM_RPC6502_Restart.s -- embedded 6502 COLD-RESTART / RPC service of
; SoftCard CP/M 2.20 (44K). 257 bytes at Z-80 $9600-$9700 inside the CCP.
; The SoftCard runs them on the 6502 via the CPU switch; from the Z-80 they
; are opaque data, so CPM_CCP.asm INCBINs the assembled binary of THIS file
; and references its Z-80-visible entry points as RPC_RESTART_BLOCK + offset
; (which relocate with ORG). Sibling to CPM_RPC6502.s ($9400 block).
;
; What it does (OBSERVED): LC RAM write-enable; drive motor off; clear sector
; cells $0478/$04F8; Apple monitor console init (SETTXT/SETVID/SETKBD); reset
; 6502 stack; CMP #$06 -> either COUT a $00-string then JMP $FF65 (MONZ), or
; the full cold restart: copy loader blocks ($1168->$0FFF, $1200->$0200,
; $12FF->$02FF, $13EF->$03EF), slot/card-type scan (JSR $1180/$1117 vs
; $1176,X/$117A,X) writing slot-config cells $03B8/$03C7/$03C8/$03DE/$03DF and
; per-slot types $02F8,Y, then build the Z-80 BIOS handoff at $1000.
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-RPC mechanism.
;
; OPEN QUESTION (shared with CPM_RPC6502.s): how a Z-80 CALL/JP into $96xx
; SELECTS this 6502 service is NOT understood -- several Z-80 reference targets
; ($9659/$965E/$9690/$96A9/$96B9/$96C0/$96C8/$96DB/$96DF/$96E9) land
; MID-6502-INSTRUCTION, so they are not 6502 routine starts. Kept as
; RPC_RESTART_BLOCK + offset literals, NOT semantically named.
;
; [RE] $96FE STA $0902: operand high byte is $09, not the $10 the "STA $1002"
; intent (completing JMP $AA00 = C3 00 AA at $1000-$1002) would imply. UNKNOWN;
; preserved verbatim. Clean-room decompile; comments [AI] unless tagged.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502_restart).
; ============================================================================
.setcpu "6502"
.segment "CODE"

SETTXT  = $FB2F                 ; Apple II Monitor: select text mode
SETVID  = $FE93                 ; Apple II Monitor: reset output hook -> screen
SETKBD  = $FE89                 ; Apple II Monitor: reset input hook -> keyboard
COUT    = $FDED                 ; Apple II Monitor: output a character
MONZ    = $FF65                 ; Apple II Monitor: cold entry (Monitor prompt)

.org $9600

RPC_RESTART_9600:
        LDA $C081                    ; $9600  AD 81 C0
        LDA $C081                    ; $9603  AD 81 C0
        JSR $0F7D                    ; $9606  20 7D 0F
        PHA                          ; $9609  48
        STA $C088,X                  ; $960A  9D 88 C0
        LDA #$00                     ; $960D  A9 00
        STA $0478,Y                  ; $960F  99 78 04
        STA $04F8,Y                  ; $9612  99 F8 04
        JSR SETTXT                    ; $9615  20 2F FB
        JSR SETVID                    ; $9618  20 93 FE
        JSR SETKBD                    ; $961B  20 89 FE
        PLA                          ; $961E  68
        LDX #$FF                     ; $961F  A2 FF
        TXS                          ; $9621  9A
        CMP #$06                     ; $9622  C9 06
        BEQ COLD_RESTART             ; $9624  F0 10
        LDY #$00                     ; $9626  A0 00
SIGNON_COUT_LOOP:
        LDA $114A,Y                  ; $9628  B9 4A 11
        BEQ SIGNON_COUT_LOOP_1       ; $962B  F0 06
        JSR COUT                    ; $962D  20 ED FD
        INY                          ; $9630  C8
        BNE SIGNON_COUT_LOOP         ; $9631  D0 F5
SIGNON_COUT_LOOP_1:
        JMP MONZ                    ; $9633  4C 65 FF
COLD_RESTART:
        LDY #$0E                     ; $9636  A0 0E
COPY_1168_0FFF:
        LDA $1168,Y                  ; $9638  B9 68 11
        STA $0FFF,Y                  ; $963B  99 FF 0F
        DEY                          ; $963E  88
        BNE COPY_1168_0FFF           ; $963F  D0 F7
COPY_1200_0200:
        LDA $1200,Y                  ; $9641  B9 00 12
        STA $0200,Y                  ; $9644  99 00 02
        DEY                          ; $9647  88
        BNE COPY_1200_0200           ; $9648  D0 F7
        LDY #$F1                     ; $964A  A0 F1
COPY_12FF_02FF:
        LDA $12FF,Y                  ; $964C  B9 FF 12
        STA $02FF,Y                  ; $964F  99 FF 02
        DEY                          ; $9652  88
        BNE COPY_12FF_02FF           ; $9653  D0 F7
        STY $03B8                    ; $9655  8C B8 03
        STY $3C                      ; $9658  84 3C
        DEY                          ; $965A  88
        STY $3E                      ; $965B  84 3E
        LDY #$C7                     ; $965D  A0 C7
SLOT_SCAN_LOOP:
        JSR $1180                    ; $965F  20 80 11
        NOP                          ; $9662  EA
        LDA $3E                      ; $9663  A5 3E
        BEQ SLOT_SCAN_LOOP_1         ; $9665  F0 18
        JSR $1117                    ; $9667  20 17 11
        STA $40                      ; $966A  85 40
        STX $41                      ; $966C  86 41
        JSR $1117                    ; $966E  20 17 11
        CPX #$00                     ; $9671  E0 00
        BEQ SLOT_SCAN_LOOP_2         ; $9673  F0 1E
        CMP $40                      ; $9675  C5 40
        BNE SLOT_SCAN_LOOP_2         ; $9677  D0 1A
        CPX $41                      ; $9679  E4 41
        BEQ CARD_TYPE_MATCH          ; $967B  F0 1A
        BNE SLOT_SCAN_LOOP_2         ; $967D  D0 14
SLOT_SCAN_LOOP_1:
        INC $3E                      ; $967F  E6 3E
        STY $03C8                    ; $9681  8C C8 03
        LDA #$00                     ; $9684  A9 00
        STA $03C7                    ; $9686  8D C7 03
        STA $03DE                    ; $9689  8D DE 03
        TYA                          ; $968C  98
        CLC                          ; $968D  18
        ADC #$20                     ; $968E  69 20
        STA $03DF                    ; $9690  8D DF 03
SLOT_SCAN_LOOP_2:
        LDX #$00                     ; $9693  A2 00
        BEQ SLOT_TYPE_RECORD         ; $9695  F0 1F
CARD_TYPE_MATCH:
        LDX #$04                     ; $9697  A2 04
CARD_TYPE_MATCH_1:
        LDY #$05                     ; $9699  A0 05
        LDA ($3C),Y                  ; $969B  B1 3C
        CMP $1176,X                  ; $969D  DD 76 11
        BNE CARD_TYPE_MATCH_2        ; $96A0  D0 09
        LDY #$07                     ; $96A2  A0 07
        LDA ($3C),Y                  ; $96A4  B1 3C
        CMP $117A,X                  ; $96A6  DD 7A 11
        BEQ CARD_TYPE_MATCH_3        ; $96A9  F0 03
CARD_TYPE_MATCH_2:
        DEX                          ; $96AB  CA
        BNE CARD_TYPE_MATCH_1        ; $96AC  D0 EB
CARD_TYPE_MATCH_3:
        INX                          ; $96AE  E8
        CPX #$02                     ; $96AF  E0 02
        BNE SLOT_TYPE_RECORD         ; $96B1  D0 03
        INC $03B8                    ; $96B3  EE B8 03
SLOT_TYPE_RECORD:
        LDY $3D                      ; $96B6  A4 3D
        TXA                          ; $96B8  8A
        STA $02F8,Y                  ; $96B9  99 F8 02
        DEY                          ; $96BC  88
        CPY #$C0                     ; $96BD  C0 C0
        BNE SLOT_SCAN_LOOP           ; $96BF  D0 9E
        ASL $03B8                    ; $96C1  0E B8 03
        LDA $3E                      ; $96C4  A5 3E
        CMP #$01                     ; $96C6  C9 01
        BEQ BIOS_HANDOFF             ; $96C8  F0 1D
        STY $3D                      ; $96CA  84 3D
        LDA #$85                     ; $96CC  A9 85
        STA $3C                      ; $96CE  85 3C
        STA $C085                    ; $96D0  8D 85 C0
        LDA $3E                      ; $96D3  A5 3E
        BEQ BIOS_HANDOFF             ; $96D5  F0 10
        LDY #$00                     ; $96D7  A0 00
LC_COUT_LOOP:
        LDA $112B,Y                  ; $96D9  B9 2B 11
        BEQ LC_COUT_LOOP_1           ; $96DC  F0 06
        JSR COUT                    ; $96DE  20 ED FD
        INY                          ; $96E1  C8
        BNE LC_COUT_LOOP             ; $96E2  D0 F5
LC_COUT_LOOP_1:
        JMP MONZ                    ; $96E4  4C 65 FF
BIOS_HANDOFF:
        LDY #$10                     ; $96E7  A0 10
BIOS_HANDOFF_1:
        LDA $13EF,Y                  ; $96E9  B9 EF 13
        STA $03EF,Y                  ; $96EC  99 EF 03
        DEY                          ; $96EF  88
        BNE BIOS_HANDOFF_1           ; $96F0  D0 F7
        LDA #$C3                     ; $96F2  A9 C3
        STA $1000                    ; $96F4  8D 00 10
        LDA #$00                     ; $96F7  A9 00
        STA $1001                    ; $96F9  8D 01 10
        LDA #$AA                     ; $96FC  A9 AA
        STA $0902                    ; $96FE  8D 02 09
