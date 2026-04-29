; ============================================================================
; Microsoft SoftCard CP/M 2.20 -- Install Fragments (Runtime Apple $0200-$03FF)
; Annotated assembly source for the bytes the stage-2 loader installs at
; Apple $0200-$03FF before triggering the SoftCard CPU switch.
;
; SOURCE
;   These bytes live in the loader binary at Apple $1200-$13FF (loaded by
;   the boot stub from track 0, physical sectors 3 and 5). Three copy
;   loops in the stage-2 loader at Apple $1041, $104C, and $10E9 (NOT the
;   $1044/$104F/$10F1 of 2.23 -- the addresses shifted) move them to
;   Apple $0200-$03FF.
;
; CONTENTS DIFFER FROM 2.23
;   2.20's install fragments contain a continuous block at $034A-$03FF
;   while 2.23's data starts at $0380. Notably, 2.20 has a chunk of
;   Z-80 BIOS callback code embedded at $034A-$037B that Z-80 sees at
;   $134A-$137B under bit-12 XOR. 2.23 puts those callbacks in the
;   newdisk staging area instead.
;
; THE WARM-BOOT ROUTINE IS DIFFERENT TOO
;   2.20's warm-boot at $03C0 has the same skeleton as 2.23's but
;   different specifics. Notable: 2.20 does NOT have JSR $0E36 (the
;   2.23 CPU-switch trigger). 2.20 has STA $C400 + JSR $1010 instead.
;   Whether the CPU switch in 2.20 fires on a different read/write or
;   on a different fetch address is open work.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols
; ----------------------------------------------------------------------------
LC_RD_RAM       = $C081
LC_WR_RAM       = $C083
SAVE            = $FF4A       ; monitor save A,X,Y,P
RESTORE         = $FF3F       ; monitor restore A,X,Y,P from $45-$48

; Slot 4 ROM area (where the SoftCard sits in the configuration 2.20 assumes)
SLOT4_ROM       = $C400


; ============================================================================
; FRAGMENT MAP -- Apple $0200-$03FF
;
; $0200-$0349  zero (cleared by install copy from source $1200-$1349)
; $034A-$037B  Z-80 BIOS callback code (Z-80 view: $134A-$137B)
; $037C-$03BB  Z-80 dispatch table + small data
; $03BC-$03BF  device-code metadata (signature counts)
; $03C0-$03DC  WARM-BOOT ROUTINE (6502; differs from 2.23)
; $03DD-$03EF  state slots
; $03F0-$03FF  jump-target table (multiple "JMP $03C0" entries)
; ============================================================================

            .ORG $0200

            .DS  $14A, $00          ; zero-filled; $0200


; ============================================================================
; SECTION 1 -- Z-80 BIOS callback code ($034A-$037B; Z-80 view: $134A-$137B)
;
; These are Z-80 instructions, not 6502. They live here because the
; Z-80 sees Apple $034A as Z-80 $134A under SoftCard's bit-12 XOR.
; The bytes execute under the Z-80 after the CPU switch.
;
; Decoded as Z-80:
;   $134A: 3A BB F3        LD A,($F3BB)        ; read slot info byte
;   $134D: FE 03           CP $03              ; compare to 3
;   $134F: C2 0C DB        JP NZ,$DB0C         ; not 3 -> jump to BIOS
;   $1352: 3A BE E0        LD A,($E0BE)        ; read keyboard latch
;   $1355: 1F              RRA                 ; bit 0 to carry
;   $1356: 9F              SBC A,A             ; A = 0 or $FF
;   $1357: C9              RET
;   $1358: CD 29 DB        CALL $DB29
;   $135B: E6 7F           AND $7F             ; mask to 7 bits
;   $135D: C9              RET
;   ... etc
; ============================================================================

Z80_CALLBACKS:
            .BYTE $3A, $BB, $F3, $FE, $03, $C2, $0C, $DB    ; LD A,(F3BB); CP 3; JP NZ,DB0C; $034A
            .BYTE $3A, $BE, $E0, $1F, $9F, $C9              ; LD A,(E0BE); RRA; SBC A,A; RET; $0352
            .BYTE $CD, $29, $DB, $E6, $7F, $C9              ; CALL DB29; AND 7F; RET; $0358
            .BYTE $3A, $BB, $F3, $FE, $03, $C2, $3E, $DC    ; LD A,(F3BB); CP 3; JP NZ,DC3E; $035E
            .BYTE $3A, $BE, $E0, $E6, $02, $28, $F9         ; LD A,(E0BE); AND 02; JR Z,-7; $0366
            .BYTE $79, $32, $45, $F0                         ; LD A,C; LD (F045),A; $036D
            .BYTE $21, $7C, $03, $22, $D0, $F3              ; LD HL,037C; LD (F3D0),HL; $0371
            .BYTE $2A, $DE, $F3, $77, $C9                    ; LD HL,(F3DE); LD (HL),A; RET; $0377


; ============================================================================
; SECTION 2 -- Dispatch state and per-device metadata ($037C-$03BF)
;
; Mixed Z-80 thunks and data tables. The slot scanner (in stage-2 loader)
; writes per-slot device codes here.
; ============================================================================

DISPATCH_DATA:
            .BYTE $8D, $BF, $C0, $60                         ; STA $C0BF; RTS (6502); $037C
            .BYTE $4A, $F3, $58, $F3, $29, $DB, $5E, $F3    ; address table (Z-80 BIOS); $0380
            .BYTE $3E, $DC, $45, $DD, $45, $DD, $3F, $DD; $0388
            .BYTE $3F, $DD, $2B, $DD, $2B, $DD               ; more BIOS targets; $0390
            .BYTE $20, $1B, $AA, $D9, $D4, $A9, $A8, $1E; $0396
            .BYTE $BD, $0B, $0C, $A0, $00, $0C, $0B, $1D; $039E
            .BYTE $0F, $0E, $19, $1E, $1F, $1C, $0B, $5B; $03A6
            .BYTE $00, $7F, $02, $5C, $15, $09, $FF, $FF; $03AE

; Per-slot device metadata
SLOT_DEV_META:
            .BYTE $FF, $FF, $02, $05, $03, $04, $00, $00     ; per-slot dev codes / classes; $03B6
            .BYTE $02, $00                  ; $03BE


; ============================================================================
; SECTION 3 -- The Warm-Boot Routine ($03C0-$03DC) - 2.20 version
;
; 24 bytes. Same skeleton as 2.23 but different specifics:
;   - STA $C400 instead of STA $FFFF (LC RAM top)
;   - JSR $FF3F (REGSTORE) where 2.23 had JSR $0E36 (Z-80 byte fetch trigger)
;   - JSR $1010 (call into stage-2 area, contains illegal opcodes from
;     6502 viewpoint) where 2.23 had JSR $FF58 (IORTS no-op)
;
; The CPU-switch trigger in 2.20 is one of these accesses; without
; hardware documentation I can't say which definitively. Likely
; candidates: STA $C400 (slot 4 I/O write -- if the SoftCard is in
; slot 4 this could be its switch port), or JSR $1010 (the 6502 attempts
; to fetch instructions from $1010 where bytes don't form valid 6502
; code, so the SoftCard could intercept the fetch).
; ============================================================================

WARM_BOOT:
            LDA LC_WR_RAM       ; (1) bank in LC RAM (read+write, bank 1); $03C0
            LDA LC_WR_RAM       ; (2) twice -- LC bank-switch protocol; $03C3

            STA SLOT4_ROM       ; (3) write to slot 4 ROM area $C400; $03C6
                                ;     2.23 wrote to $FFFF (LC RAM top).
                                ;     2.20's $C400 is slot-4-specific;
                                ;     this may be the CPU-switch trigger
                                ;     for SoftCard-in-slot-4 configuration.

            LDA LC_RD_RAM       ; (4) bank to LC bank 2; $03C9

            JSR RESTORE         ; (5) call $FF3F -- monitor REGSTORE; $03CC
                                ;     restores A,X,Y,P from $45-$48

            JSR $1010           ; (6) call into stage-2 area at $1010.; $03CF
                                ;     The bytes there are mid-instruction
                                ;     from a 6502 viewpoint (78 04 99 F8...
                                ;     after a 99 78 04 STA from earlier in
                                ;     stage-2). If the 6502 actually fetches
                                ;     here it gets garbage. The SoftCard
                                ;     hardware may use this fetch as the
                                ;     CPU-switch trigger -- analogous to
                                ;     2.23's JSR $0E36 mechanism, just with
                                ;     a different watched address.

            STA LC_RD_RAM       ; (7) touch LC RAM read switch; $03D2

            JSR SAVE            ; (8) save 6502 register state via $FF4A; $03D5
                                ;     (used here as another monitor-vector
                                ;     touch, possibly with patched semantics)

            JMP WARM_BOOT       ; (9) loop back to top; $03D8

            .BYTE $00, $00      ; trailing data; $03DB


; ============================================================================
; SECTION 4 -- State slots ($03DD-$03EF)
; ============================================================================

            .BYTE $20, $00, $E4, $00, $0A, $00, $CD          ; state values; $03DD
            .BYTE $01, $01, $60                              ; state + RTS; $03E4
            .BYTE $60, $00, $03, $00, $02, $00, $00, $00, $00; $03E7


; ============================================================================
; SECTION 5 -- Jump-target table ($03F0-$03FF)
;
; Multiple "$03C0" pointers and JMP $03C0 instructions, similar to 2.23's
; $03F0-$03FF table.
; ============================================================================

JMP_TABLE:
            .WORD $03C0                     ; $03F0
            .WORD $03C0                     ; $03F2
            .BYTE $A6, $4C                  ; $03F4
            JMP WARM_BOOT                   ; $03F6
            JMP WARM_BOOT                   ; $03F9
            JMP WARM_BOOT                   ; $03FC
            .BYTE $03                       ; $03FF


; ============================================================================
; ASSEMBLY NOTE
;
; Reassembling this file with a 6502 assembler ORG'd at $0200 should
; produce 512 bytes byte-identical to the install-fragment source bytes
; at loader Apple $1200-$13FF in CPMV220Disk1.po.
;
; See docs/CPM_DiskSectorMap.md for the per-sector reference and
; CPM220_BootLoader.asm for the install loops at Apple $1041, $104C,
; and $10E9 that perform the copy.
; ============================================================================
