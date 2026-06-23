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
; preserved verbatim. Clean-room decompile; comment PROSE is [AI] machine-
; inferred unless tagged [DOC]/[RE]; [?] = open question. The cross-module
; loader cells/blocks ($0Fxx/$11xx/$12xx/$13xx/$03xx/$02F8/...) are external to
; this $9600 image, so they stay literal (full relocatability needs no labels
; here -- every internal branch already targets a label). Per-line addresses
; live in the generated CPM_RPC6502_Restart.lst (the BASIC.asm convention).
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

; ----------------------------------------------------------------------------
; RPC_RESTART_9600 -- service entry. Quiesce the machine (LC RAM writable, drive
;   motor off, console back to the Apple text screen, 6502 stack reset), then
;   read the caller's mode byte (A, returned by the loader routine $0F7D) and
;   branch: A==6 -> full COLD_RESTART; else print the $114A message and drop to
;   the Monitor.
;   In:        X = Disk II slot soft-switch offset (slot<<4); Y = sector-cell
;              index -- both set up by the caller. (Selection mechanism: see the
;              file header OPEN QUESTION.)
;   Out:       falls into SIGNON_COUT_LOOP or branches to COLD_RESTART.
;   Clobbers:  A, X, Y, the 6502 stack pointer, processor flags.
; ----------------------------------------------------------------------------
RPC_RESTART_9600:
        LDA $C081                    ; enable language-card RAM for writing:
        LDA $C081                    ;   two reads of $C081 (read ROM / write RAM bank 2)
        JSR $0F7D                    ; [AI] loader routine; returns the mode byte in A
        PHA                          ; save the mode byte across the quiesce sequence
        STA $C088,X                  ; drive motor OFF (Disk II $C088 + slot offset in X)
        LDA #$00
        STA $0478,Y                  ; clear the RWTS sector cells (index Y)
        STA $04F8,Y
        JSR SETTXT                   ; Apple text mode
        JSR SETVID                   ; output hook -> screen
        JSR SETKBD                   ; input hook -> keyboard
        PLA                          ; recover the mode byte
        LDX #$FF
        TXS                          ; reset the 6502 stack pointer
        CMP #$06                     ; mode 6 = full cold restart?
        BEQ COLD_RESTART             ; yes -> COLD_RESTART
        LDY #$00                     ; no -> print the $114A message, then Monitor

; ----------------------------------------------------------------------------
; SIGNON_COUT_LOOP -- COUT the $00-terminated string at $114A (in the loader
;   image), then enter the Apple Monitor. The non-cold-restart path.
; ----------------------------------------------------------------------------
SIGNON_COUT_LOOP:
        LDA $114A,Y                  ; next message byte
        BEQ SIGNON_COUT_LOOP_1       ; $00 terminator -> done
        JSR COUT                     ; print it
        INY
        BNE SIGNON_COUT_LOOP         ; (Y wraps at 256 -- a guard, never reached)
SIGNON_COUT_LOOP_1:
        JMP MONZ                     ; drop to the Monitor prompt

; ----------------------------------------------------------------------------
; COLD_RESTART -- the full restart. Stage three loader blocks down into low
;   memory ($1168->$0FFF [15B], $1200->$0200 [page], $12FF->$02FF [partial
;   $0300 page]), seed the scan cells ($03B8=0, $3C=0, $3E=$FF), then scan the
;   slots from $C7 down.
; ----------------------------------------------------------------------------
COLD_RESTART:
        LDY #$0E
COPY_1168_0FFF:                      ; copy $1168..$1176 -> $0FFF.. (Y = $0E..1)
        LDA $1168,Y
        STA $0FFF,Y
        DEY
        BNE COPY_1168_0FFF
COPY_1200_0200:                      ; copy the $1200 page -> $0200 (Y = 0, then $FF..1)
        LDA $1200,Y
        STA $0200,Y
        DEY
        BNE COPY_1200_0200
        LDY #$F1
COPY_12FF_02FF:                      ; copy $1300..$13F0 -> $0300..$03F0 (Y = $F1..1)
        LDA $12FF,Y
        STA $02FF,Y
        DEY
        BNE COPY_12FF_02FF
        STY $03B8                    ; $03B8 = 0  (slot-config scratch; Y is 0 here)
        STY $3C                      ; $3C = 0    (ZP card-ROM pointer low)
        DEY
        STY $3E                      ; $3E = $FF  (scan "card found" flag, [AI])
        LDY #$C7                     ; start at slot 7 ($Cn high byte $C7)

; ----------------------------------------------------------------------------
; SLOT_SCAN_LOOP -- walk the slots (Y = $C7..$C1). For each, probe via the
;   loader ($1180), then read two card-ROM bytes ($1117) and compare them: a
;   self-consistent pair selects the card-type test (CARD_TYPE_MATCH); the
;   $3E==0 branch records this slot as the boot card (SLOT_SCAN_LOOP_1).
;   [AI] cell semantics inferred from the writes; the loader subroutines
;   ($1180/$1117) are not decoded here.
; ----------------------------------------------------------------------------
SLOT_SCAN_LOOP:
        JSR $1180                    ; [AI] loader: probe slot Y
        NOP
        LDA $3E
        BEQ SLOT_SCAN_LOOP_1         ; $3E==0 -> record this slot as the boot card
        JSR $1117                    ; [AI] loader: read a card-ROM byte -> A
        STA $40                      ; stash first byte/addr
        STX $41
        JSR $1117                    ; read again
        CPX #$00
        BEQ SLOT_SCAN_LOOP_2         ; X==0 -> not a candidate
        CMP $40                      ; bytes self-consistent?
        BNE SLOT_SCAN_LOOP_2
        CPX $41
        BEQ CARD_TYPE_MATCH          ; consistent -> run the card-type test
        BNE SLOT_SCAN_LOOP_2
SLOT_SCAN_LOOP_1:                    ; record slot Y as the boot card
        INC $3E
        STY $03C8                    ; $03C8 = slot $Cn high byte
        LDA #$00
        STA $03C7
        STA $03DE
        TYA
        CLC
        ADC #$20                     ; $Cn + $20  ([AI] slot ROM page derivation)
        STA $03DF
SLOT_SCAN_LOOP_2:
        LDX #$00                     ; card type 0 (none) ...
        BEQ SLOT_TYPE_RECORD         ; ... record it (always taken, X==0)
CARD_TYPE_MATCH:
        LDX #$04                     ; test the 4 known card types (X = 4..1)

; ----------------------------------------------------------------------------
; CARD_TYPE_MATCH_1 -- compare the candidate card's ROM bytes at offsets 5 and 7
;   (via (ZP $3C),Y) against the card-type signature tables $1176,X / $117A,X.
;   A full match leaves X = the card type; type 2 also bumps $03B8.
; ----------------------------------------------------------------------------
CARD_TYPE_MATCH_1:
        LDY #$05
        LDA ($3C),Y                  ; card ROM byte at offset 5
        CMP $1176,X                  ; vs signature table A
        BNE CARD_TYPE_MATCH_2        ; mismatch -> next type
        LDY #$07
        LDA ($3C),Y                  ; card ROM byte at offset 7
        CMP $117A,X                  ; vs signature table B
        BEQ CARD_TYPE_MATCH_3        ; both match -> this type
CARD_TYPE_MATCH_2:
        DEX
        BNE CARD_TYPE_MATCH_1        ; try the next type
CARD_TYPE_MATCH_3:
        INX                          ; (restore the matched index)
        CPX #$02
        BNE SLOT_TYPE_RECORD
        INC $03B8                    ; type 2 -> bump $03B8 ([AI])

; ----------------------------------------------------------------------------
; SLOT_TYPE_RECORD -- store the resolved card type (X) for this slot into the
;   per-slot type table $02F8,Y, step to the next slot, and loop until $C0.
; ----------------------------------------------------------------------------
SLOT_TYPE_RECORD:
        LDY $3D                      ; slot index ($3D)
        TXA
        STA $02F8,Y                  ; per-slot card type
        DEY
        CPY #$C0                     ; scanned past slot 0?
        BNE SLOT_SCAN_LOOP           ; no -> next slot
        ASL $03B8                    ; finalize $03B8 ([AI])
        LDA $3E
        CMP #$01                     ; exactly one boot card found?
        BEQ BIOS_HANDOFF             ; yes -> hand off to the Z-80 BIOS
        STY $3D                      ; ($3D = $BF here)
        LDA #$85
        STA $3C
        STA $C085                    ; [AI] language-card bank select
        LDA $3E
        BEQ BIOS_HANDOFF             ; none found -> hand off anyway
        LDY #$00                     ; >1 found -> print the $112B message, Monitor

; ----------------------------------------------------------------------------
; LC_COUT_LOOP -- COUT the $00-terminated message at $112B, then the Monitor.
; ----------------------------------------------------------------------------
LC_COUT_LOOP:
        LDA $112B,Y
        BEQ LC_COUT_LOOP_1
        JSR COUT
        INY
        BNE LC_COUT_LOOP
LC_COUT_LOOP_1:
        JMP MONZ

; ----------------------------------------------------------------------------
; BIOS_HANDOFF -- copy the 16-byte handoff block $13EF->$03EF and plant the Z-80
;   entry jump at $1000 (the SoftCard maps the Z-80 reset $0000 to Apple $1000):
;   C3 00 AA = `JMP $AA00`, the 44K BIOS cold-start. NOTE the $96FE anomaly --
;   the $AA byte is stored to $0902, not $1002 (see the file header [RE] note).
; ----------------------------------------------------------------------------
BIOS_HANDOFF:
        LDY #$10
BIOS_HANDOFF_1:                      ; copy $13EF..$13FF -> $03EF.. (16 bytes)
        LDA $13EF,Y
        STA $03EF,Y
        DEY
        BNE BIOS_HANDOFF_1
        LDA #$C3                     ; JMP opcode ...
        STA $1000                    ; ... at the Z-80 reset target $1000
        LDA #$00
        STA $1001                    ; low byte of $AA00
        LDA #$AA
        STA $0902                    ; [RE] high byte -> $0902, not $1002 (UNKNOWN; verbatim)
