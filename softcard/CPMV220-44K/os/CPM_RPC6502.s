; ============================================================================
; CPM_RPC6502.s -- embedded 6502 RPC block of SoftCard CP/M 2.20 (44K)
; ----------------------------------------------------------------------------
; 257 bytes that live at Z-80 $9400-$9500 inside the CCP. The SoftCard runs
; them on the 6502 via the CPU switch; from the Z-80 they are opaque data, so
; the Z-80 SystemImage INCBINs the assembled binary of THIS file and references
; the entry points below as L_9400 + offset (which relocate with ORG).
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-subroutine-call (RPC)
; mechanism: the Z-80 loads parameter cells, stores the 6502 target at A$VEC
; (0F3D0H) and writes the SoftCard location Z$CPU (0F3DEH) -> 6502 runs the code,
; results read back from the same cells. (How a given Z-80 CALL site SELECTS this
; particular 6502 service remains the OPEN QUESTION below -- [RE], not manual.)
;
; The block is position-independent (all internal refs are fixed low Apple
; addresses: I/O-config cells $03E0-$03EB, the slot-ROM page $C088,X, monitor
; $FF2D, RWTS helpers $0A25/$0B00/$0BC6/$0BDE/$0E10/$0F3E/$0F5A/$0F7D/$0FAD; all
; branches relative). The $03E0-$03EB working cells sit inside the I/O
; Configuration Block region [DOC S&HD 2-6 ; facts sec.2.2/3] (6502 $200-$3FF =
; Z-80 0F200H-0F3FFH); they are this disk-service's own scratch cells, NOT the
; manual's named config-block structures. This whole block is a warm-boot/RWTS
; disk service; the "Apple disk drivers and disk buffers" concept it implements
; is the documented 6502 $800-$FFF region [DOC S&HD 2-6 ; facts sec.2.2] (Z-80
; 0F800H-0FFFFH) -- though the citation is weak here: this block's OWN sector
; buffers ($0478/$04F8) are screen-page-adjacent, not in $800-$FFF, and the RWTS
; entry points it calls ($0A25/$0B00/...) are not individually enumerated in the
; manual. The SAME bytes serve 44K and 56K -- EXCEPT one byte:
;   $94AE = high byte of the warm-boot disk-load buffer ($A400 44K / $E400 56K),
;           emitted as #>$A400 / #>$E400 under CFG_56K.
;           44K $A400 IS a documented boundary: the start of the "44K CP/M"
;           region $A400-$BFFF [DOC S&HD 2-6 ; facts sec.2.2] (the CP/M system
;           base, just above free-RAM top $A3FF -- NOT itself the free-RAM top).
;           56K $E400 is [RE], taken from the as-shipped 2.20B-56K image: it is
;           NOT in the manual's sec.2.2 56K layout (which is all $D000-$FFFF).
;           It corresponds to the documented 56K CCP base C400H
;           [DOC S&HD 3-41/3-42 ; facts sec.2.3] only AFTER the Z-80<->6502
;           address-translation table [DOC S&HD 2-6/2-32 ; facts sec.2.1] maps
;           Z-80 0C400H -> 6502 $E400 (that derivation is [RE], not a 2-6 read).
;
; What it does (warm-boot / RPC disk service, by routine):
;   $9400  decrement retry counter, restore A/flags, JMP $0F3E (RWTS entry)
;   $940E  match requested sector against the address field (skew via $0F9D,Y)
;   $943A  set up the drive: motor on ($C088,X), clear flags
;   $945A  read/write the sector data buffer ($0478 / $04F8 banked by bit-7 of $35)
;   $9484  (self-modified via cells $9488/$948A) sector-data mover
;   $94AD  warm-boot reload: point the load buffer at $A400 (44K)/$E400 (56K),
;          slot 6, loop reading sectors via $0E10, advancing the buffer page
;
; OPEN QUESTION -- the Z-80->6502 dispatch is NOT understood. The Z-80 CCP/BDOS
; CALLs several addresses in this block (e.g. CALL $9498, CALL $948C), but those
; land mid-6502-instruction or inside the skew table, not on 6502 routine starts.
; So "the Z-80 CALL target is a 6502 run-address" is WRONG, and a simple
; "address = RPC selector" was a hand-wave. How a Z-80 CALL into $94xx actually
; reaches/selects this 6502 service is unresolved (the SoftCard CPU-switch detail).
; The 6502 CODE here is coherent and named accordingly; the Z-80-side entry
; symbols are kept verbatim, NOT semantically named, pending that investigation.
; The several backward branches to $93Dx/$93Ex/$93CC target the Z-80 CCP region
; BELOW this image, so they stay literal ([?], part of the same open question).
;
; Clean-room decompile; comment PROSE is [AI] inference unless tagged [DOC]/[RE];
; [?] = open question. Cross-module cells/helpers are external to this $9400
; image, so they stay literal (the block is already fully relocatable -- every
; INTERNAL branch targets a label; the one former `+1` cover entry is now a clean
; label, no arithmetic). Per-line addresses live in the generated CPM_RPC6502.lst.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502).
; ============================================================================
.setcpu "6502"
.segment "CODE"

PRERR           = $FF2D         ; Apple II Monitor: print "ERR" + bell

.org $9400

; ----------------------------------------------------------------------------
; SECTOR_RW -- RWTS retry tail. Restore the saved processor flags and re-enter
;   the RWTS dispatcher ($0F3E) with the read ($40) or write ($20) command in A.
;   The two backward branches ($93EA/$93D1) re-enter the surrounding RWTS driver
;   (below this image -- kept literal, [?]).
;   Clobbers: A, flags, stack (PLA/PLP).
; ----------------------------------------------------------------------------
SECTOR_RW:
        DEC $04F8                    ; retry counter (low sector cell)
        BNE $93EA                    ; more retries -> back into the RWTS driver [?]
        BEQ $93D1                    ; exhausted -> error exit [?]
        PLA
        LDA #$40                     ; command = read
SECTOR_RW_1:
        PLP                          ; restore caller's flags
        JMP $0F3E                    ; -> RWTS dispatcher

; ----------------------------------------------------------------------------
; SECTOR_MATCH -- compare the requested sector ($2D, post-skew) against the
;   address field just read. On a match, fall to DRIVE_MOTOR_ON; on the wrong
;   sector, retry with command $20/$10; the skew maps logical->physical via the
;   $0F9D translate table.
;   Clobbers: A, Y, flags.
; ----------------------------------------------------------------------------
SECTOR_MATCH:
        BEQ DRIVE_MOTOR_ON           ; already positioned -> set up the drive
        LDA $2F
        STA $03E3                    ; save current track
        LDA $03E2
        BEQ SECTOR_MATCH_1           ; no target track yet -> accept
        CMP $2F
        BEQ SECTOR_MATCH_1           ; on the target track -> accept
        LDA #$20                     ; wrong track -> re-seek command
        BNE SECTOR_RW_1
SECTOR_MATCH_1:
        LDA $03E1                    ; requested logical sector
        TAY
        LDA $0F9D,Y                  ; physical sector via the skew table
        CMP $2D                      ; == the sector just found?
        BNE $93CC                    ; no -> back into the RWTS driver [?]
        PLP
        BCC DRIVE_MOTOR_ON_2         ; carry clear -> seek/settle path
        JSR $0B00                    ; read the sector
        PHP
        BCS $93CC                    ; read error -> driver [?]
        PLP
        JSR $0BC6                    ; post-read processing

; ----------------------------------------------------------------------------
; DRIVE_MOTOR_ON -- finalize drive state: clear (or, via DRIVE_MOTOR_ON_SEC, set)
;   the carry-into-$03EA flag, then touch the slot's $C088,X soft switch (motor).
;   DRIVE_MOTOR_ON_1 holds a BIT-cover byte so the CLC fall-through path skips the
;   SEC that the LDA #$10 path (DRIVE_MOTOR_ON_2) jumps into.
;   Clobbers: A, X, flags.  Returns via RTS.
; ----------------------------------------------------------------------------
DRIVE_MOTOR_ON:
        CLC
        LDA #$00                     ; A=0, carry clear (no-error path)
DRIVE_MOTOR_ON_1:
        .byte $24                    ; cover byte (BIT-zp opcode): on fall-through this
                                     ;   eats the next byte as `BIT $38`, skipping the SEC
DRIVE_MOTOR_ON_SEC:                  ; entered via DRIVE_MOTOR_ON_2 -> set carry first
        SEC                          ; ($38) error path: carry set
        STA $03EA                    ; record the result flag
        LDX $05F8                    ; slot soft-switch offset
        LDA $C088,X                  ; drive motor toggle
        RTS
DRIVE_MOTOR_ON_2:
        JSR $0A25                    ; seek/settle the arm
        BCC DRIVE_MOTOR_ON           ; settled -> finalize (no error)
        LDA #$10                     ; seek-error result code
        BNE DRIVE_MOTOR_ON_SEC       ; -> SEC; STA $03EA (error path)
        ASL                          ; (dead tail after the BNE-always above)
        JSR $0F5A
        LSR $0478
        RTS

; ----------------------------------------------------------------------------
; SECTOR_XFER_BYTE -- move one sector-data byte between the caller (A) and the
;   active half of the sector buffer. Bit 7 of $35 selects which buffer page
;   ($0478 vs $04F8) is the source and which the destination, then jumps into
;   the RWTS nibble path ($0BDE).
;   In: A = byte, Y = buffer index, $35 bit7 = direction.  Clobbers: A, flags.
; ----------------------------------------------------------------------------
SECTOR_XFER_BYTE:
        STA $2E                      ; stash the byte
        JSR $0F7D                    ; RWTS helper (sync/position)
        LDA $0478,Y                  ; read from buffer page A ...
        BIT $35
        BMI SECTOR_XFER_BYTE_1
        LDA $04F8,Y                  ; ... or page B (bit7 clear)
SECTOR_XFER_BYTE_1:
        STA $0478                    ; latch into the working cell
        LDA $2E                      ; recover the byte
        BIT $35
        BMI SECTOR_XFER_BYTE_2
        STA $04F8,Y                  ; write to page B ...
        BPL SECTOR_XFER_BYTE_3
SECTOR_XFER_BYTE_2:
        STA $0478,Y                  ; ... or page A (bit7 set)
SECTOR_XFER_BYTE_3:
        JMP $0BDE                    ; -> RWTS nibble routine

; ----------------------------------------------------------------------------
; SLOT_TO_INDEX -- convert a Disk II slot soft-switch offset (X = slot<<4) to a
;   slot index (Y = slot number) by four logical shifts.
;   In: X = slot<<4.  Out: Y = slot.  Clobbers: A, Y.
; ----------------------------------------------------------------------------
SLOT_TO_INDEX:
        TXA
        LSR
        LSR
        LSR
        LSR
        TAY
        RTS

; ----------------------------------------------------------------------------
; SECTOR_MOVE -- self-modified sector-data mover. The four bytes at $9488 are
;   PATCHED at run time (via cells $9488/$948A) to become the active move/rotate
;   instruction; bit 7 of $35 again selects the $0478/$04F8 buffer half. Decoded
;   statically (on-disk bytes), so $9488 shows as `.byte` and $948C's `ADC` is
;   the unpatched form -- [RE], the live opcodes differ.
;   Clobbers: A, flags.  Returns via RTS.
; ----------------------------------------------------------------------------
SECTOR_MOVE:
        PHA
        LDA $03E4                    ; current move parameter
        .byte   $6A, $66, $35, $20   ; self-modified slot ($9488-$948B); see header [RE]
SECTOR_MOVE_1:
        ADC $680F,X                  ; (unpatched static form; operand self-modified [RE])
        ASL
        BIT $35
SECTOR_MOVE_2:
        BMI SECTOR_MOVE_4            ; bit7 set -> page A
        STA $04F8,Y                  ; page B
SECTOR_MOVE_3:
        BPL SECTOR_MOVE_5
SECTOR_MOVE_4:
        STA $0478,Y                  ; page A
SECTOR_MOVE_5:
        RTS

; ----------------------------------------------------------------------------
; SECTOR_XLATE_TABLE -- 16-entry logical->physical sector interleave (the 2:1
;   "soft" skew: 0,2,4,...,E,1,3,...,F), indexed by SECTOR_MATCH via $0F9D.
; ----------------------------------------------------------------------------
SECTOR_XLATE_TABLE:
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $01, $03, $05, $07, $09, $0B, $0D, $0F

; ----------------------------------------------------------------------------
; WBOOT_LOAD -- warm-boot reload: re-read CP/M (CCP+BDOS) from the boot disk into
;   the system image, which is why only ~5K of CP/M's 7K stays resident during a
;   transient. [DOC Vol1 1-19 ; facts sec.8.7]. Points the load buffer high byte
;   at the CP/M base ($A400 44K / $E400 56K), seeds the RWTS config cells, then
;   loops over $1C sectors via $0E10, advancing the buffer page each time.
;   Clobbers: A, X, Y, flags.  Returns via RTS (or aborts to the Monitor on error).
; ----------------------------------------------------------------------------
WBOOT_LOAD:
        .ifdef CFG_56K
            lda     #>$E400          ; warm-boot load buffer hi (56K)
        .else
            lda     #>$A400          ; warm-boot load buffer hi (44K)
        .endif
        STA $03E9                    ; buffer page
        LDY #$00
        STY $03E8
WBOOT_LOAD_1:
        STY $03E0                    ; track = 0
        INY
WBOOT_LOAD_2:
        STY $03E4
        STY $03EB
        LDA #$60                     ; slot 6 (6<<4): the boot disk
        STA $03E6                    ; controller, drives A:/B:, MUST be present [DOC Vol1 1-3/1-4 ; facts sec.8.9]
        LDA #$0B
        STA $03E1                    ; starting sector
        LDA #$1C                     ; sector count to load ($1C)
WBOOT_READ_SECTOR:
        PHA                          ; save the remaining count
        PHP
        SEI                          ; reads are timing-critical
WBOOT_READ_SECTOR_1:
        JSR $0E10                    ; read one sector
        BCC WBOOT_NEXT_SECTOR        ; ok -> advance
        JSR PRERR                    ; error -> "ERR" + bell ...
        PLP
        PLA
WBOOT_ERR_MONITOR:
        JMP $0FAD                    ; ... and abort to the Monitor
WBOOT_NEXT_SECTOR:
        PLP
        INC $03E9                    ; next buffer page
        LDX $03E1                    ; current sector
WBOOT_NEXT_SECTOR_1:
        INX
        CPX #$10                     ; past sector $0F?
        BNE WBOOT_NEXT_SECTOR_3
WBOOT_NEXT_SECTOR_2:
        LDX #$00                     ; wrap to sector 0 ...
        INC $03E0                    ; ... and step to the next track
WBOOT_NEXT_SECTOR_3:
        STX $03E1
        PLA                          ; remaining count
        SEC
        SBC #$01
        BNE WBOOT_READ_SECTOR        ; more -> read the next sector
        LDA #$08                     ; done: reset the buffer page marker
        STA $03E9
        RTS
        .byte   $FF, $FF, $FF, $00   ; pad to $9500 (block tail)
