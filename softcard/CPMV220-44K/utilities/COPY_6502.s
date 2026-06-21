; ============================================================================
; COPY_6502.s -- embedded 6502 track-copy driver of the COPY.COM utility (2.20 44K)
; ----------------------------------------------------------------------------
; 82 bytes that COPY.COM carries at file $04AE-$04FF as 6502 machine code. COPY
; runs on the Z-80; this block runs on the 6502 (SoftCard CPU switch), so from
; the Z-80 it is opaque data. Rather than bury it as a DEFB blob, it is
; disassembled as real 6502 and assembled separately with ca65; COPY.asm INCBINs
; the byte-identical binary.
;
; RELOCATED +$1000 AT RUNTIME. The block is stored at $04AE in the .COM but the
; Z-80 hands the 6502 the run-address $14AE via the SoftCard handoff cell A$VEC
; ($F3D0): COPY.asm does LD HL,$14AE / LD ($F3D0),HL before ringing the $F000
; doorbell. So the entry self-reference (the BNE back to $14B0) is written here
; at the RUN address $14B0, not the file address $04B0. External fixed addresses
; (the page-3 RWTS parameter cells $03E0/$03E1/$03E9/$03EA, the zero-page track
; counter $00, and the inner read/write-track engine at $0E03) appear as
; themselves -- they are NOT relocated with the block.
;
; ENTRY POINT: $14AE (the only run-address the Z-80 stages into A$VEC).
;
; What it does -- the per-disk track/sector copy loop coordinator. It does NOT
; itself touch the Disk II hardware: it drives the SoftCard's inner read/write-
; track engine (JSR $0E03) once per sector, walking the destination buffer page
; and the track/sector counters, and bails on the first I/O error. The $03Exx
; cells are this disk-service's own page-3 scratch (6502 $200-$3FF = Z-80
; $F200-$F3FF, inside the I/O Configuration Block region [DOC S&HD 2-6 ; facts
; sec.2.2/3]); they are NOT the manual's named config-block structures:
;   $00    zero-page track-count loop counter -- the Z-80 pokes it via the $F000
;          doorbell (6502 $0000); decremented once per call to the inner engine.
;   $03E0  current track number (Z-80 $F3E0 track counter)
;   $03E1  current sector number within the track (wraps 0..$0F)
;   $03E9  destination-buffer memory page; walks up from $15, and at $C0 skips to
;          $D0 to step over the Apple $C0xx I/O hole.
;   $03EA  status byte returned by the inner engine (0 = OK); Z-80 reads $F3EA.
;   $0E03  inner read/write-track engine (the SoftCard disk driver staged into
;          Apple RAM); reached as a fixed absolute call, not part of this block.
;
; The Z-80->6502 dispatch SELECTION (how ringing $F000 reaches THIS routine on
; the 6502) is the SoftCard CPU-switch detail and is [RE], not asserted here.
;
; TRAILING DATA $14DD-$14FF (35 bytes): kept as `.byte`, preserved verbatim.
; They are NOT reachable code -- the only 6502 routine here ends at the RTS at
; $14DC, and nothing in the .COM (no Z-80 word, no relocated 6502 word) refers to
; any address in $14DD-$14FF. They do not decode to coherent, self-consistent
; 6502 from any entry (illegal opcodes, out-of-range operands). They are not a
; stale assembler tail either: the same 35 bytes appear identically in the
; 2.20B-56K build of COPY (file $04DD, right after the byte-identical 47-byte
; driver), so they travel WITH the driver and are emitted verbatim, unclassified.
;
; Clean-room decompile; comments are [AI] inference unless tagged. Reassembles
; BYTE-IDENTICAL to the on-disk block (see cpm_pipeline test_utilities_roundtrip).
; ============================================================================
.setcpu "6502"
.segment "CODE"

.org $14AE

; [AI] Per-disk track/sector copy loop. Drives the inner read/write-track engine
; ($0E03) once per sector; advances the buffer page + track/sector counters;
; stops on the first nonzero status or when the $00 track-count loop runs out.
COPY_TRACK_LOOP:
        LDX #$15                     ; $14AE  A2 15      ; [AI] initial destination-buffer page = $15
SECTOR_STEP:
        STX $03E9                    ; $14B0  8E E9 03   ; [AI] store current buffer page for the inner engine
        JSR $0E03                    ; $14B3  20 03 0E   ; [AI] read/write one track/sector via the inner Disk II engine
        LDA $03EA                    ; $14B6  AD EA 03   ; [AI] inner engine status (0 = OK)
        BNE COPY_TRACK_LOOP_DONE     ; $14B9  D0 21      ; [AI] I/O error -> bail (Z-80 reads $F3EA, reports it)
        LDX $03E1                    ; $14BB  AE E1 03   ; [AI] sector number within track
        INX                          ; $14BE  E8         ; [AI] next sector
        CPX #$10                     ; $14BF  E0 10      ; [AI] past sector $0F (16 sectors/track)?
        BCC SECTOR_NO_WRAP           ; $14C1  90 05      ; [AI] no -> keep same track
        LDX #$00                     ; $14C3  A2 00      ; [AI] wrap sector to 0
        INC $03E0                    ; $14C5  EE E0 03   ; [AI] and advance to the next track
SECTOR_NO_WRAP:
        STX $03E1                    ; $14C8  8E E1 03   ; [AI] save updated sector number
        LDX $03E9                    ; $14CB  AE E9 03   ; [AI] current buffer page
        INX                          ; $14CE  E8         ; [AI] next page
        CPX #$C0                     ; $14CF  E0 C0      ; [AI] reached the $C0xx I/O hole?
        BNE BUF_NO_SKIP              ; $14D1  D0 02      ; [AI] no -> use it
        LDX #$D0                     ; $14D3  A2 D0      ; [AI] skip $C0xx-$CFxx I/O space -> resume at page $D0
BUF_NO_SKIP:
        STX $03E9                    ; $14D5  8E E9 03   ; [AI] save updated buffer page
        DEC $00                      ; $14D8  C6 00      ; [AI] one fewer track to copy (count poked via the $F000 doorbell)
        BNE SECTOR_STEP              ; $14DA  D0 D4      ; [AI] loop until the batch count reaches 0
COPY_TRACK_LOOP_DONE:
        RTS                          ; $14DC  60         ; [AI] return to the SoftCard handoff (Z-80 resumes)

; [AI] Trailing non-code bytes ($14DD-$14FF, 35 bytes). Unreferenced and not a
; coherent 6502 routine; preserved verbatim (identical in the 2.20B-56K build).
        .byte   $10, $49, $B0, $20, $ED, $FD, $C9, $B0, $66, $06, $88, $D0, $D6, $A9, $A0, $4C ; $14DD
        .byte   $ED, $FD, $19, $4D, $0F, $01, $8B, $20, $89, $F6, $25, $39, $2B, $31, $B0, $3B ; $14ED
        .byte   $EB, $F1, $06                                    ; $14FD
