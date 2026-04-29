; ============================================================================
; Microsoft SoftCard CP/M 2.23 — Install Fragments (Runtime Apple $0200-$03FF)
; Annotated 6502 assembly source for the bytes the stage-2 loader installs
; at Apple $0200-$03FF before triggering the SoftCard CPU switch.
;
; SOURCE
;   These bytes live in the loader binary at Apple $1200-$13FF (loaded by
;   the boot stub from track 0, physical sectors 3 and 5). Three copy
;   loops at Apple $1044, $104F, and $10F1 — in CPM223_BootLoader.asm —
;   move them to Apple $0200-$03FF.
;
; RUNTIME EXECUTION
;   The 6502 jumps into this region via "JMP $03D2" at the end of the
;   loader's boot-finalization. The warm-boot routine at $03C0 runs
;   perpetually until the system is reset or shut down.
;
; AT THIS POINT IN MEMORY
;   The 6502 sees the warm-boot routine and various small data tables.
;   The Z-80 sees these same physical bytes at $1200-$13FF after bit-12
;   XOR mapping, where they're part of TPA-area state. The 6502 is the
;   intended audience.
;
; THE CPU-SWITCH TRIGGER
;   The "JSR $0E36" at $03CC is what flips the bus from 6502 to Z-80.
;   See docs/CPM_DiskSectorMap.md and Part 10 of the article series for
;   the mechanism: Apple $0E36 holds Z-80 instructions (C3 39 FB =
;   JP $FB39); the SoftCard hardware monitors the 6502's fetch into that
;   range and uses it as the CPU-switch trigger.
; ============================================================================

; ----------------------------------------------------------------------------
; Symbols referenced by this fragment
; ----------------------------------------------------------------------------

; Apple monitor / firmware (Apple II Reference Manual entry points)
IORTS           = $FF58       ; immediate-RTS landing pad
SAVE            = $FF4A       ; save A,X,Y,P to $45-$48 (also called PREAD)

; Apple soft switches (Apple II language card / I/O page)
LC_RD_RAM       = $C081       ; LC: read ROM, write RAM (2nd access enables write)
LC_WR_RAM       = $C083       ; LC: read+write RAM, bank 1

; Z-80 disk-callback area (Apple side; Z-80 sees same bytes at $1E36)
Z80_SYNC_POLL   = $0E36       ; Z-80 sees as $1E36; first instruction of the
                              ; six-instruction sync polling loop. The 6502
                              ; "executes" this address only as a CPU-switch
                              ; trigger — the SoftCard hardware intercepts
                              ; the fetch.

; LC RAM trap address (writing here touches the LC RAM top page)
LC_RAM_TOP      = $FFFF


; ============================================================================
; FRAGMENT MAP — Apple $0200-$03FF
;
; $0200-$037F  zero (cleared by install copy from source $1200-$137F)
; $0380-$03B7  per-device handler-target table + slot info (data)
; $03B8-$03BF  zero
; $03C0-$03DD  WARM-BOOT ROUTINE (the 6502's main loop after handoff)
; $03DE-$03EF  zero / state slots
; $03F0-$03FF  jump-target table (multiple "JMP $03C0" entries)
; ============================================================================

            .ORG $0200

; ----------------------------------------------------------------------------
; Apple $0200-$037F is zero-filled at install time. These addresses overlap
; the Apple monitor's input buffer ($0200-$02FF), but CP/M doesn't use
; the monitor input buffer once running, so the area is repurposed as
; mostly-empty state space.
; ----------------------------------------------------------------------------
            .DS  $180, $00          ; zero-filled; $0200


; ============================================================================
; SECTION 1 — Per-device handler-target table ($0380-$0397)
;
; A 24-byte table of 16-bit Z-80 BIOS addresses, used as a lookup by the
; Z-80 cold-boot generator. Each pair is duplicated; the table likely has
; 6 entries × 2 addresses each = 12 addresses, with each address repeated
; for readability or for left/right-half access.
;
; Address layout (little-endian, low byte first):
;   $0380: $FB14, $FB33, $FB33, $FCB5, $FCB5, $FE66
;   $038C: $FE66, $FE60, $FE60, $FE4C, $FE4C, ...
;
; The targets ($FB14, $FB33, $FCB5, $FE66, $FE60, $FE4C) are all in the
; 2.23 BIOS code pages. They're per-device handler entry points for
; CONIN/CONOUT/STATUS-style operations on different device classes.
; The Z-80 at runtime indexes into this table by device code to find
; the right handler.
; ============================================================================

DEV_HANDLER_TABLE:
            .WORD $FB14         ; entry 0 handler 1; $0380
            .WORD $FB33         ; entry 1 handler 1; $0382
            .WORD $FB33         ; entry 1 handler 2 (same address); $0384
            .WORD $FCB5         ; entry 2 handler 1; $0386
            .WORD $FCB5         ; entry 2 handler 2; $0388
            .WORD $FE66         ; entry 3 handler 1; $038A
            .WORD $FE66         ; entry 3 handler 2; $038C
            .WORD $FE60         ; entry 4 handler 1; $038E
            .WORD $FE60         ; entry 4 handler 2; $0390
            .WORD $FE4C         ; entry 5 handler 1; $0392
            .WORD $FE4C         ; entry 5 handler 2; $0394
            .BYTE $20, $1B      ; tail of last entry / start of next data; $0396


; ============================================================================
; SECTION 2 — Slot/dispatch metadata ($0398-$03B7)
;
; Mixed data: device-code-keyed table indices, slot bits, and a small
; fragment of state. Read by both 6502-side dispatch and the Z-80's
; cold-boot generator (which reads $03B9-$03BF for slot device codes
; the slot scanner left there).
; ============================================================================

SLOT_INFO_BLOCK:
            .BYTE $AA, $D9, $D4, $A9, $A8, $1E, $BD, $0B; $0398
            .BYTE $0C, $A0, $00, $0C, $0B, $1D, $0E, $0F; $03A0
            .BYTE $19, $1E, $1F, $1C, $0B, $5B, $00, $7F; $03A8
            .BYTE $02, $5C, $15, $09, $FF, $FF, $FF, $FF; $03B0

; Per-slot device-code table — one byte per slot, written by the slot
; scanner (in stage-2 loader at $10CE: STA $02F8,Y where Y = slot ROM
; high byte). The Z-80 cold-boot generator at $FB3A reads from $F3B8+E
; for E = 7..1, which under the SoftCard's bit-12 XOR maps to the same
; physical bytes as $03B8+E... no wait — $F3B8 is a TPA-area address,
; not $03B8. The slot scanner writes to $03B9 (= $02F8 + $C1, etc.).
; The bytes here at install time are zero-filled placeholder; the scanner
; fills $03B9-$03BF after install.
SLOT_DEV_CODES:
            .DS  $08, $00          ; $03B8 = type-2 counter; $03B9-$03BF = slots 1-7; $03B8


; ============================================================================
; SECTION 3 — The Warm-Boot Routine ($03C0-$03DD)
;
; THIS IS THE 6502'S MAIN LOOP AFTER THE SOFTCARD HANDOFF.
;
; Twenty-four bytes that run perpetually until the system is reset.
; Entered via "JMP $03D2" from the loader's boot-finalization (at Apple
; $1100-$114B); subsequent iterations cycle through the full body via
; "JMP $03C0" at the bottom.
;
; The CPU-switch trigger is JSR $0E36 — see annotation below.
; ============================================================================

WARM_BOOT:
            LDA LC_WR_RAM       ; (1) bank in LC RAM (read+write, bank 1); $03C0
            LDA LC_WR_RAM       ; (2) twice — Apple LC bank-switch protocol; $03C3
                                ;     (the LC switch latches on the second
                                ;     consecutive access)

            STA LC_RAM_TOP      ; (3) write to $FFFF — touch LC RAM top page; $03C6
                                ;     (purpose: presumably to "kick" the
                                ;     SoftCard's LC-RAM-tracking state, or
                                ;     to flush some pending value into the
                                ;     LC RAM that Z-80 will read; not yet
                                ;     fully traced)

            LDA LC_RD_RAM       ; (4) bank to LC bank 2 (read+write switches off); $03C9

; ----------------------------------------------------------------------------
; THE CPU-SWITCH TRIGGER
;
; Apple $0E36 in the BIOS first 1 KB area holds the Z-80 instruction
; bytes "C3 39 FB" — that's "JP $FB39" in Z-80, into the 2.23 BIOS code
; page. As 6502 code, $C3 is an illegal opcode; if the 6502 actually
; executed it, it would halt or wander.
;
; The SoftCard hardware monitors the 6502's address bus. The combination
; of (a) the JSR landing in the BIOS-shared region and (b) the byte fetched
; not being a valid 6502 instruction is what flips the bus to Z-80 mode.
;
; After the switch, the Z-80 runs from its own program counter. On first
; boot, that's $0000 (= Apple $1000), where "JP $FA00" was planted by
; the stage-2 loader's boot-finalization. The Z-80 jumps to $FA00 and
; begins BIOS cold-boot.
;
; On subsequent yields-back-from-CP/M, the Z-80 resumes at whatever PC
; it was at when the previous switch fired — typically inside the
; sync polling loop at Z-80 $1E39, which expects to read $E000 with the
; high bit set after the 6502 has finished servicing a request.
; ----------------------------------------------------------------------------
            JSR Z80_SYNC_POLL   ; (5) ← CPU SWITCH TRIGGER; $03CC
                                ;     6502 sees: JSR $0E36
                                ;     SoftCard sees: a fetch into a watched
                                ;       BIOS-mapped address range; flips to
                                ;       Z-80
                                ;     Z-80 wakes and runs.
                                ;     When the Z-80 yields back to the 6502
                                ;     (via its sync polling loop reading
                                ;     $E000), execution here resumes at $03CF.

; ----------------------------------------------------------------------------
; Code below runs after the Z-80 yields back to 6502.
; ----------------------------------------------------------------------------
            JSR IORTS           ; (6) call $FF58 — monitor's IORTS instruction.; $03CF
                                ;     This is a one-byte RTS at $FF58. The JSR
                                ;     pushes return $03D1, the call lands on
                                ;     RTS, which immediately pops and returns.
                                ;     Net effect: a 6-cycle no-op. Probably a
                                ;     "kick" that the SoftCard is watching, OR
                                ;     a symmetry-restoring pseudo-call after
                                ;     the asymmetric JSR $0E36 (which pushed
                                ;     a return address but never returned
                                ;     normally).

            STA LC_RD_RAM       ; (7) touch LC RAM read switch — STA semantics; $03D2
                                ;     differ from LDA at this address (write
                                ;     to LC switch may have a side effect the
                                ;     SoftCard monitors)

            SEI                 ; (8) disable interrupts; $03D5
                                ;     (CP/M doesn't use Apple interrupts;
                                ;     this ensures the next cycle isn't
                                ;     interrupted)

            JSR SAVE            ; (9) call $FF4A — saves A,X,Y,P to $45-$48; $03D6
                                ;     (an Apple monitor convenience routine).
                                ;     Used here as the disk-service hand-off
                                ;     dispatch point: somewhere between this
                                ;     call returning and the next JMP $03C0,
                                ;     the 6502 services whatever the Z-80
                                ;     yielded for. The exact mechanism is
                                ;     not fully traced — likely involves
                                ;     monitor-vector patches at $FFF9-$FFFF
                                ;     (set by the loader at $1140-$1149)
                                ;     redirecting some Apple-monitor entry
                                ;     into the preserved RWTS code at
                                ;     $BA00-$BFFF.

            JMP WARM_BOOT       ; (10) loop back to top — re-trigger the switch; $03D9
                                ;      next time around

; ----------------------------------------------------------------------------
; Trailing data — possibly a saved-state byte or function selector
; ----------------------------------------------------------------------------
            .BYTE $00            ; (state placeholder); $03DC
            .BYTE $20, $00, $00  ; (state placeholder; $20 looks like a; $03DD
                                 ; literal byte, not opcode)


; ============================================================================
; SECTION 4 — Misc state and trampolines ($03E0-$03EF)
;
; Mostly zeros, with a single $60 (RTS) at $03E7 — a landing pad for
; uses where some routine needs to "return" but its RTS target lives
; here. Function unclear without more tracing.
; ============================================================================

            .DS  $07, $00                   ; $03E0
            .BYTE $60           ; lone RTS — landing pad; $03E7
            .DS  $08, $00                   ; $03E8


; ============================================================================
; SECTION 5 — Jump-target table ($03F0-$03FF)
;
; Sixteen bytes: multiple "$03C0" addresses interleaved with "JMP $03C0"
; encoded instructions. Reads as both a data table (4-entry pointer list
; pointing to $03C0) and as code (3-byte JMP $03C0 instructions).
;
; Likely a vector/jump table that gets indexed by some dispatcher to
; restart the warm-boot loop from various contexts (different yield
; reasons).
; ============================================================================

JMP_TABLE:
            .WORD $03C0         ; pointer entry 0 → warm-boot; $03F0
            .WORD $03C0         ; pointer entry 1 → warm-boot; $03F2
            .BYTE $A6, $4C      ; LDX $4C (zp); leftover byte $4C is also the; $03F4
                                ; opcode for JMP, suggesting this is a packed
                                ; mix of data and code
            JMP WARM_BOOT       ; ($4C $C0 $03); $03F6
            JMP WARM_BOOT       ; ($4C $C0 $03); $03F9
            JMP WARM_BOOT       ; ($4C $C0 $03); $03FC
            .BYTE $03           ; (single byte — last byte of $03FE+2); $03FF


; ============================================================================
; ASSEMBLY NOTE
;
; Reassembling this file with a 6502 assembler ORG'd at $0200 should
; produce 512 bytes byte-identical to the install-fragment source bytes
; at loader Apple $1200-$13FF.
;
; The bytes are extracted from CPMV233.DSK at:
;   trk0:phys3 → 256 bytes that source Apple $1200-$12FF (= here $0200-$02FF)
;   trk0:phys5 → 256 bytes that source Apple $1300-$13FF (= here $0300-$03FF)
;
; (Track 0 physical sectors 3 and 5; logical sectors 9 and 10 in CP/M skew.)
;
; See docs/CPM_DiskSectorMap.md for the full per-physical-sector
; reference, and CPM223_BootLoader.asm for the install loops at
; Apple $1044, $104F, and $10F1 that perform the copy.
; ============================================================================
