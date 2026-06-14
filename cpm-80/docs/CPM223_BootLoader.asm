; ============================================================================
; Microsoft SoftCard CP/M 2.23 -- 6502 Boot Loader (integrated source)
; Annotated disassembly of the loader as it exists in Apple ][ RAM
; after the boot stub completes.
;
; The loader occupies $0800-$13FF in Apple ][ RAM. It is loaded by the
; Disk II P6 PROM (sector 0 -> $0800) and then by the boot stub itself
; (10 more sectors of track 0 -> $0A00-$1300, in CP/M sector skew order).
;
; THIS FILE COVERS
;   $0800-$08FF  Boot stub (sector 0; first 60 bytes are code, rest data)
;   $1000-$11FF  Stage-2 entry, install loops, slot scanner, dispatch,
;                boot-finalization, page-copy + checksum subroutines,
;                strings, signature tables
;   $13C0-$13DC  Warm-boot routine source (gets COPIED to runtime $03C0;
;                full annotated source in CPM223_InstallFragments.asm)
;
; COMPANION FILES (separate ORG'd source for the same project)
;   CPM223_InstallFragments.asm
;     ORG $0200. The runtime view of $0200-$03FF, containing the
;     warm-boot routine, per-device handler-target table, and small
;     data blocks. Sourced FROM loader $1200-$13FF (this file's "page-2
;     install image" and "page-3 install image" regions); installed
;     by the copy loops at $1044, $104F, $10F1 in this file.
;
;   CPM223_RWTS.asm
;     ORG $0A00. The clean 6502 disk-routine block at $0A00-$0C38
;     (WRITE_SECTOR, READ_SECTOR, SEEK_TRACK, LOAD_CPM_LOOP). The bytes
;     at $0C39-$0FFF in the loader image are BIOS first 1 KB content
;     (Z-80 code, not 6502) and will be covered in CPM223_BIOS.asm.
;
; SECTIONS PARTIALLY ANNOTATED HERE
;   The disk I/O block at $0A00-$0FFF is summarized below by entry
;   point only; per-instruction disassembly is in CPM223_RWTS.asm.
;   The page-2 and page-3 install images at $1200-$13FF are documented
;   structurally; their runtime form is in CPM223_InstallFragments.asm.
;
; The companion narrative is docs/CPM_BootLoader.md and the
; per-physical-sector reference is docs/CPM_DiskSectorMap.md.
;
; Source: nibbler 6502 disassembly of CPMV233.DSK track 0, reconstructed
; into the Apple ][ memory layout the boot stub creates.
; ============================================================================

; ============================================================================
; Zero-page and Apple ][ memory references used by the loader
; ============================================================================
zp_ptr_lo       = $3C        ; 16-bit pointer, used as $Cn00 base for slot ROM
zp_ptr_hi       = $3D
zp_jmp_lo       = $3E        ; indirect-JMP target low (also: scan iter counter)
zp_jmp_hi       = $3F        ; indirect-JMP target high
zp_temp_a       = $40        ; scratch byte 1
zp_temp_b       = $41        ; scratch byte 2
zp_count        = $00        ; sector count from boot stub
zp_p6_count     = $27        ; P6 PROM's destination-page counter

dev_count_d2    = $03B8      ; counter for "type-2" (Pascal-1.0-match-X=2) cards
dev_table       = $03B9      ; per-slot device codes ($03B9..$03BF for slots 1-7)
warm_boot       = $03C0      ; SoftCard handoff routine (installed from $13C0)

; Apple monitor / firmware entry points (Apple II Reference Manual)
TEXT            = $FB2F      ; set text mode
SETVID          = $FE93      ; set output device to screen
SETKBD          = $FE89      ; set input device to keyboard
COUT            = $FDED      ; output character in A
IORTS           = $FF58      ; immediate-RTS (used as a known-RTS landing pad)
SAVE            = $FF4A      ; save A,X,Y,P to $45-$48
MONITOR         = $FF65      ; Apple monitor entry (debugger prompt)

; Apple soft switches
KBD             = $C000      ; read keyboard / strobe
LC_RD_RAM       = $C081      ; language card: read ROM, write RAM (2nd access)
LC_WR_RAM       = $C083      ; language card: read RAM, write RAM (2nd access)
DISK_MOTOR_OFF  = $C088      ; disk II motor off (slot N: $C088+slot*16)


; ============================================================================
; SECTION 1 — Boot stub (sector 0, file offset $0800-$08FF)
;
; Loaded by the Disk II P6 PROM. The P6 PROM reads sector 0 of track 0 to
; $0800-$08FF, then JSRs to $0801. On entry: X = slot*16 (e.g., $60 for
; slot 6), $27 = $09 (one page after $0800), $3D = 1 (next sector index).
;
; The boot stub uses the P6 PROM's "search for field prolog" entry at
; $Cn5C (mid-routine) to read additional sectors on demand. It loads 10
; more sectors of track 0 in CP/M skew order, then JMP $1000.
; ============================================================================

.setcpu "6502X"
.segment "CODE"
            .org $0800

; Byte at $0800 is the page-count signal that P6 PROM checks.
; $01 means "one page loaded" (just the boot sector).
.byte $01

BOOT_STUB:
LDA $27             ; $27 = page count P6 has loaded so far
CMP #$09            ; first re-entry from P6: $27 = $09 ($08+1)
BNE @skip_init      ; on subsequent iterations skip the init block
                                ;
                                ; First entry: do one-time setup
TXA                 ; X = slot*16 (e.g. $60 for slot 6)
LSR                 ;
LSR                 ;
LSR                 ;
LSR                 ; A = slot number 0-7
ORA #$C0            ; A = $C0 + slot (e.g. $C6 for slot 6)
STA zp_jmp_hi       ; $3F = $C6 (slot ROM page hi)
LDA #$5C            ;
STA zp_jmp_lo       ; $3E = $5C; ($3E/$3F) = $C65C
                                ; $C65C is the P6 PROM "search for field
                                ; prolog" entry (mid-routine, reads one
                                ; sector identified by $3D, stores at ($26))
LDA #$00            ;
STA zp_count        ; $00 = 0 (sector-table index)
INC zp_p6_count     ; $27 = $0A (so first read goes to $0A00)
                                ;
@skip_init:
INC zp_count        ; $00 += 1 (advance sector-table index)
LDY zp_count        ; Y = current index
CPY #$0B            ; loaded all 10 sectors yet? (Y=$0B = 11)
BNE @read_next      ;
JMP $1000           ; YES — transfer to stage-2 entry
                                ;
@read_next:
LDA $082D,Y         ; A = physical sector number from skew table
STA $3D             ; tell P6 which physical sector to find
JMP ($003E)         ; JMP $C65C — read sector to ($26),Y
                                ; P6 PROM increments $27 after read,
                                ; then JMP $0801 (its end-of-load behavior
                                ; persists for these mid-routine calls)

; ----------------------------------------------------------------------------
; CP/M sector skew table — physical sector to read for each iteration.
; Iteration 1 reads physical sector 2, iteration 2 reads sector 4, etc.
; The skew (0,2,4,6,8,A,C,E,1,3,5,7,9,B,D,F) optimizes for sequential
; CP/M block reads on a rotating disk: alternate even-then-odd minimizes
; rotational delay between consecutive sectors in CP/M block order.
; The skew is "baked in" — Apple Disk II controllers use DOS 3.3 logical
; ordering by default; SoftCard CP/M imposes its own skew at this level.
; ----------------------------------------------------------------------------
SKEW_TABLE:
.byte $00,$02,$04,$06,$08,$0A,$0C,$0E
.byte $01,$03,$05,$07,$09,$0B,$0D,$0F


; ----------------------------------------------------------------------------
; Copyright strings
; ----------------------------------------------------------------------------
; High-ASCII copyright (older Microsoft string, present in 2.20 and 2.23):
;     " COPYRIGHT (C) 1980 MICROSOFT - NK "
.byte $A0,$C3,$CF,$D0,$D9,$D2,$C9,$C7,$C8,$D4    ; " COPYRIGHT"
.byte $A0,$A8,$C3,$A9,$A0,$B1,$B9,$B8,$B0,$A0    ; " (C) 1980 "
.byte $CD,$C9,$C3,$D2,$CF,$D3,$CF,$C6,$D4,$A0    ; "MICROSOFT "
.byte $AD,$A0,$CE,$CB,$A0                        ; "- NK "

; Low-ASCII copyright (added in 2.23 only, $FF-filled in 2.20):
;     " COPYRIGHT (C) 1982 MICROSOFT - CP "
.byte $20,$43,$4F,$50,$59,$52,$49,$47,$48,$54    ; " COPYRIGHT"
.byte $20,$28,$43,$29,$20,$31,$39,$38,$32,$20    ; " (C) 1982 "
.byte $4D,$49,$43,$52,$4F,$53,$4F,$46,$54,$20    ; "MICROSOFT "
.byte $2D,$20,$43,$50,$20                        ; "- CP "

; Remainder of $0800 sector is zero-filled.
.res  $7D, $00


; ============================================================================
; SECTION 2 — Disk I/O routines + GCR tables ($0900-$0FFF)
;
; Loaded from physical sectors 2-C of track 0 (in CP/M skew order). These
; are the loader's RWTS-style routines and the GCR translation tables.
; The same bytes are documented in detail in CPM223_RWTS.asm; rather than
; duplicate the per-instruction annotation here, we INCBIN the bytes
; directly (the round-trip property requires them to be present so the
; full loader binary reassembles).
;
; Region map (per CPM223_RWTS.asm):
;   $0A00-$0A8D  WRITE_SECTOR
;   $0A8E-$0A98  WRITE_BYTE helper
;   $0A99-$0B5E  READ_SECTOR
;   $0B5F-$0BFF  SEEK_TRACK + LOAD_CPM_LOOP body
;   $0C00-$0C38  end of LOAD_CPM_LOOP + RTS
;   $0C39-$0DFF  Z-80 BIOS init code + GCR codec tables
;   $0E00-$0FFF  more 6502 RWTS code + sector skew table
; ============================================================================

            .incbin "cpm-investigation/loader_223.bin", $100, $700


; ============================================================================
; SECTION 3 — Stage-2 entry point ($1000)
;
; Boot stub jumps here after loading 10 sectors. On entry:
;   X = slot*16   (e.g., $60 for slot 6)
;   A = ?         (will be tested for boot-success signal)
;   $27 = $14     (P6/stub destination counter, now past last loaded sector)
;
; The first thing stage-2 does is enable the language card RAM (writable
; high memory) because the Z-80 will need RAM at the addresses where the
; Apple's monitor ROM normally lives.
; ============================================================================

            .org $1000

STAGE2_ENTRY:
LDA LC_RD_RAM       ; first access: enable read-from-ROM,
                                ; write-to-RAM (still reads ROM)
LDA LC_RD_RAM       ; second access: now writable RAM is
                                ; banked in at $D000-$FFFF
TXA                 ; X = slot*16 → A
LSR                 ;
LSR                 ;
LSR                 ;
LSR                 ; A = slot number (0-7)
TAY                 ; Y = slot number (used as index below)
PHA                 ; save slot on stack for later
STA DISK_MOTOR_OFF,X ; turn off the disk II motor
                                ; (X is still slot*16; $C088+slot*16 hits
                                ; the motor-off soft switch)
LDA #$00            ;
STA $0478,Y         ; clear screen-hole "scratch" for this slot
STA $04F8,Y         ; (Apple II monitor convention: $0478+$Cn
                                ; and $04F8+$Cn are per-slot scratch bytes)
JSR TEXT            ; set Apple text mode
JSR SETVID          ; route output through standard CSW
JSR SETKBD          ; route input through standard KSW
PLA                 ; restore A (the boot-success signal)
LDX #$FF            ;
TXS                 ; reset stack pointer to $01FF
CMP #$06            ; was the boot-success signal $06?
BEQ MAIN_PATH       ; yes — proceed to main loader path

; ----------------------------------------------------------------------------
; Boot failure path: print error string from $1192 and drop to monitor
; ----------------------------------------------------------------------------
BOOT_FAIL:
LDY #$00
LDA $1192,Y         ; load char from string at $1192
BEQ @done           ; null terminator → exit print loop
JSR COUT            ; print character
INY
BNE $102B
@done:
JMP MONITOR         ; drop into Apple monitor


; ============================================================================
; SECTION 4 — Code installation ($1039-$1058)
;
; Three back-to-back copy loops that install boot-loader-staged data
; and Z-80 code into low Apple ][ RAM. The destinations $0200-$03FF map
; to Z-80 $1200-$13FF after the SoftCard XOR; the bytes copied here will
; be live Z-80 code after the SoftCard switch.
; ============================================================================

MAIN_PATH:
; Copy 14 bytes from $11B0..$11BD to $0FFF..$100C
; Y goes 14 → 1 (BNE exits when Y=0).
; Note destination overlaps the loader entry point at $1000 — yes,
; the $1000-$100C bytes get overwritten here. That's fine because
; we're past them in execution.
LDY #$0E
LDA $11B0,Y
STA $0FFF,Y
DEY
BNE $103B

; Copy 256 bytes from $1200..$12FF to $0200..$02FF
; (Y wraps from 0 back to $FF on the first DEY; loop runs $FF, $FE, ..., $01
;  then BNE exits when Y=0. So byte at $1200+0 = $1200 is NOT copied via this
;  loop — that's the byte we'll handle in the next loop.)
LDA $1200,Y         ; Y is 0 entering, so first iteration reads
                                ; $1200+0 = $1200 and writes $0200+0 = $0200,
                                ; then DEY makes Y=$FF, then BNE loops $FF..$01.
STA $0200,Y
DEY
BNE $1044

; Copy 241 bytes from $1300..$13F0 to $0300..$03F0
LDY #$F1
LDA $12FF,Y         ; reads $12FF+1..$12FF+$F1 = $1300..$13F0
STA $02FF,Y         ; writes to $0300..$03F0
DEY
BNE $104F

STY dev_count_d2    ; Y is now 0; zero the device-count counter
STY zp_ptr_lo       ; $3C = 0 (low byte of slot-ROM pointer)
DEY                 ; Y = $FF
STY zp_jmp_lo       ; $3E = $FF (initial value: "no slot iter yet")


; ============================================================================
; SECTION 5 — Slot scanner ($1060-$10D5)
;
; Walks slots 7 → 1, identifies cards via the Pascal firmware ID byte
; table at $11BE/$11C2, stores per-slot device codes at $03B9-$03BF.
;
; THIS IS THE SECTION THAT DIFFERS BETWEEN 2.20 AND 2.23 — see
; docs/CPM_Videx_Difference.md for the side-by-side annotated diff.
; The version below is 2.23 (with the 11-byte Pascal-1.1 check).
; ============================================================================

SLOT_SCAN:
LDY #$C7            ; Y = $C7 (slot ROM page for slot 7)
STY zp_ptr_hi       ; $3D = $C7 (slot ROM hi byte)
STY $1069           ; SELF-MODIFY the operand at $1069 below
                                ; (changes "STA $C000" to "STA $Cn00", which
                                ; touches the slot's expansion-ROM-select
                                ; soft switch on the next read of $Cn00)
STA KBD             ; clear keyboard strobe (originally STA $C000;
                                ; after the self-modify above, this becomes
                                ; STA $Cn00 — accessing slot ROM page)
LDA zp_jmp_lo       ; $3E (slot iteration counter)
BEQ SCAN_INIT_SLOT  ; first slot ($3E=$FF coming in is non-zero;
                                ; this branch only taken on subsequent loops
                                ; when $3E has been incremented past 0)

; (Subsequent-iteration code path: validate slot ROM is stable across reads)
JSR CKSUM_SLOT      ; checksum the slot ROM page
STA zp_temp_a       ; save first checksum
STX zp_temp_b
JSR CKSUM_SLOT      ; checksum again
CPX #$00            ; if X=0, slot ROM might be empty/unstable
BEQ SCAN_NO_MATCH   ; → no card here, default to code 0
CMP zp_temp_a       ; checksums differ → unstable
BNE SCAN_NO_MATCH
CPX zp_temp_b
BEQ SCAN_DO_PROBE   ; checksums match → real ROM, proceed to probe
BNE SCAN_NO_MATCH

SCAN_INIT_SLOT:
INC zp_jmp_lo       ; $3E += 1 (advance iteration counter)
STY $03C8           ; record slot ROM page in handoff routine
LDA #$00            ;
STA $03C7           ; clear handoff routine's low-byte slot offset
STA $03DE           ;   and another scratch
TYA                 ;
CLC                 ;
ADC #$20            ;
STA $03DF           ; store $Cn + $20 in another handoff slot

SCAN_NO_MATCH:
LDX #$00            ; X = 0 (will become device code 1 after INX)
BEQ STORE_DEV_CODE

; ----------------------------------------------------------------------------
; Pascal signature probe — match $Cn05 and $Cn07 against the 4-entry
; signature table at $11BE/$11C2. X starts at 4 and decrements; matched
; index becomes the device code after INX.
; ----------------------------------------------------------------------------
SCAN_DO_PROBE:
LDX #$04            ; check entries 4, 3, 2, 1

@probe_loop:
LDY #$05            ; offset of Pascal 1.0 ID byte 1
LDA ($3C),Y         ; A = $Cn05 of current slot ROM
CMP $11BE,X         ; compare against signature table[X]
BNE @next_sig       ; mismatch → try next signature
LDY #$07            ; offset of Pascal 1.0 ID byte 2
LDA ($3C),Y         ; A = $Cn07
CMP $11C2,X         ; compare against second-byte table[X]
BEQ @matched        ; both match → done

@next_sig:
DEX                 ; try next signature entry (X = 3, 2, 1)
BNE @probe_loop     ; loop while X != 0

@matched:
INX                 ; X is now (matched_index + 1), or 1 if no match.
                                ; Possible values: 1 (no match), 2..5 (matched
                                ; signature index from end-of-table).

CPX #$02            ; matched signature 1 (the $03/$3C card)?
BNE @check_pascal   ; no — skip the type-2 counter
INC dev_count_d2    ; bump "type 2 device" counter

; ----------------------------------------------------------------------------
; *** 11-BYTE PASCAL 1.1 CHECK — NEW IN 2.23, ABSENT FROM 2.20 ***
; If the Pascal 1.0 ID matched (X=4 after INX, meaning matched table[3] which
; is $38/$18 = the standard Pascal 1.0 firmware ID), additionally read the
; Pascal 1.1 signature byte at $Cn0B. If it equals $01 (the Pascal 1.1
; marker), override the device code to $06 (the Pascal-1.1 device code).
; ----------------------------------------------------------------------------
@check_pascal:
CPX #$04            ; matched the Pascal 1.0 ID? (X=4 = matched
                                ; table[3] = the $38/$18 entry)
BNE STORE_DEV_CODE  ; no — store the matched-index value
LDY #$0B            ; Y = offset of Pascal 1.1 signature byte
LDA ($3C),Y         ; A = $Cn0B
CMP #$01            ; is it the Pascal 1.1 marker?
BNE STORE_DEV_CODE  ; no — keep device code = 4 (Pascal 1.0)
LDX #$06            ; YES — override device code to $06

; ----------------------------------------------------------------------------
; Store the device code at the per-slot table ($03B9-$03BF) and continue
; scanning the next slot down (or exit when we reach slot 0).
; ----------------------------------------------------------------------------
STORE_DEV_CODE:
LDY zp_ptr_hi       ; Y = current slot ROM page ($Cn)
TXA                 ; A = device code
STA $02F8,Y         ; STA $02F8+$Cn = STA $03B9..$03BF for slot 1..7
DEY                 ; advance to next-lower slot
CPY #$C0            ; have we just done slot 0?
BNE $1062           ; no — loop back to scan next slot


; ============================================================================
; SECTION 6 — Post-scan dispatch and Z-80 hand-off staging
; ============================================================================

POST_SCAN:
ASL dev_count_d2    ; double the type-2 counter (sets carry from b7)
LDA zp_jmp_lo       ; A = number of slots that had non-empty ROM
CMP #$01            ; only one slot had a real card?
BEQ DISPATCH_OK     ; yes — proceed to handoff staging

; (More-than-one slot had cards — print info string and drop to monitor.
;  The string at $1173 is probably a "select boot device" prompt.)
LDY #$00
LDA $1173,Y
BEQ @done
JSR COUT
INY
BNE $10E1
@done:
JMP MONITOR

; ----------------------------------------------------------------------------
; Final install: copy 16 bytes from $13EF to $03EF (Z-80 reset vector
; staging), then self-modify the loader's entry point.
; ----------------------------------------------------------------------------
DISPATCH_OK:
LDY #$10
LDA $13EF,Y
STA $03EF,Y
DEY
BNE $10F1

; ----------------------------------------------------------------------------
; Plant the Z-80 reset vector at Apple $1000 (= Z-80 $0000 after SoftCard XOR).
;
; The bytes are NOT 6502 instructions — they are Z-80 machine code:
;   $C3 = Z-80 'JP nn' opcode
;   $00 $FA = little-endian address $FA00 (the Z-80 cold-boot entry of the
;             2.23 CP/M BIOS — sits right next to the BIOS jump table at $FAB8)
;
; After the SoftCard switch flips control to the Z-80, the Z-80 fetches its
; first instruction from its $0000 (which is Apple $1000), sees the JP $FA00
; we just planted, and jumps into the BIOS cold-boot routine.
;
; 2.20 plants a different address here (its BIOS is at Z-80 $DACC, so the
; cold-boot entry is somewhere in the $DA00 region).
; ----------------------------------------------------------------------------
LDA #$C3            ; A = $C3 (Z-80 "JP nn" opcode)
STA $1000           ; Apple $1000 = Z-80 $0000 (reset vector)
LDA #$00            ;
STA $1001           ; Apple $1001 = low byte of JP target
LDA #$FA            ;
STA $1002           ; Apple $1002 = high byte of JP target
                                ; → Z-80 reads "JP $FA00" at its reset

; ----------------------------------------------------------------------------
; Copy disk I/O routines into the language card RAM area, then load
; replacement code over the original disk I/O area, then jump into the
; warm-boot routine (which is now installed at $03C0).
; ----------------------------------------------------------------------------
PREP_HANDOFF:
LDA #$0A            ; source high byte: $0A00 (the disk I/O block)
STA $53             ;   ($52/$53 = source pointer)
LDA #$BA            ; dest high byte: $BA00 (in language card RAM)
STA $51             ;   ($50/$51 = dest pointer)
LDA #$00            ;
STA $52             ; source low = 0
STA $50             ; dest low = 0
LDX #$06            ; copy 6 pages = $600 bytes
JSR PAGE_COPY       ; copy $0A00..$0FFF → $BA00..$BFFF
                                ; (preserves the disk I/O routines in LC RAM
                                ; so they remain reachable after the original
                                ; $0A00 block gets overwritten below)

LDA #$80
JSR $BBEB           ; call into LC RAM (was loaded at $9700 earlier
                                ; or staged elsewhere — purpose: TBD, possibly
                                ; an init or sector seek)
LDA #$0A
STA $BC08           ; configure something at $BC08 (LC RAM byte)

; Second copy: replace the disk I/O block with content from $9700-$9CFF
LDA #$97
STA $53             ; source high = $97 ($9700)
LDA #$0A
STA $51             ; dest high = $0A ($0A00)
LDX #$06
JSR PAGE_COPY       ; copy $9700..$9CFF → $0A00..$0FFF
                                ; (replaces the original boot-stub-loaded disk
                                ; routines with a different version, possibly
                                ; CP/M-aware variants or ones with new entry
                                ; points the Z-80 will call into)

; Third copy: another smaller block
LDA #$80
STA $53             ; source high = $80
LDA #$A3
STA $51             ; dest high = $A3
LDX #$17            ; X = $17 = 23 pages = $1700 bytes
JSR PAGE_COPY       ; copy $8000..$96FF → $A300..$B9FF
                                ; This stages a substantial chunk into the LC
                                ; RAM area below where the disk routines were
                                ; preserved. Likely the CP/M system image
                                ; (CCP+BDOS+BIOS) being moved into position
                                ; for the Z-80 to find at fixed addresses.

; Patch Apple monitor reset vector at $FFF9 with custom values
LDY #$06
LDA $116C,Y         ; load 6 bytes from data block at $116C
STA $FFF9,Y         ; store to $FFF9..$FFFF (Apple monitor reset
                                ; vectors area: $FFFA/$FFFB = NMI vector,
                                ; $FFFC/$FFFD = RESET vector,
                                ; $FFFE/$FFFF = IRQ/BRK vector)
DEY
BNE $1142
JMP $03D2           ; jump into the installed warm-boot routine
                                ; at offset $D2 — past the JSR $0E36 (which
                                ; this code path handled directly) — landing
                                ; at: STA $C081 / SEI / JSR $FF4A / JMP $03C0
                                ; (which loops back to warm-boot start)


; ============================================================================
; SECTION 9 — Subroutines ($114E-$116C)
; ============================================================================

; ----------------------------------------------------------------------------
; CKSUM_SLOT — accumulate all 256 bytes of the slot ROM page
;
; Sums all bytes at ($3C),Y for Y = 0..$FF, returning checksum in (A,X).
; X is incremented each time the addition wraps (carries past 8 bits).
; Used by the slot scanner to verify that the slot ROM is stable across
; consecutive reads (real ROMs return the same bytes; absent slots return
; floating-bus garbage that varies between reads).
; ----------------------------------------------------------------------------
CKSUM_SLOT:
LDA #$00
TAX                 ; X = 0 (carry counter)
TAY                 ; Y = 0 (offset counter)
@loop:
CLC                 ; (note: BNE @loop targets HERE, not the ADC)
ADC ($3C),Y         ; A += slot ROM byte
BCC @nocarry
INX                 ; bump carry counter on overflow
@nocarry:
INY
BNE @loop           ; loop 256 times (Y = $00..$FF then wrap)
RTS

; ----------------------------------------------------------------------------
; PAGE_COPY — copy X pages from ($52/$53) to ($50/$51)
;
; Used by the install/staging code to move blocks of 256 * X bytes from
; one Apple memory region to another. Increments source/dest high bytes
; after each page; X is the page count.
;
; Inputs:
;   X    = number of pages to copy
;   $50/51 = destination pointer
;   $52/53 = source pointer
; ----------------------------------------------------------------------------
PAGE_COPY:
LDY #$00
@byte_loop:
LDA ($52),Y
STA ($50),Y
DEY
BNE @byte_loop      ; loop $FF, $FE, ..., $01, then exit (Y = 0
                                ; was the first iteration; DEY wraps to $FF)
                                ; Note: this misses Y=0! Probably intentional —
                                ; the CALLER initializes the pointers' low
                                ; bytes to handle Y=0 separately, or accepts
                                ; that one byte is uncopied per page.
                                ; (Actually: re-examining, this loop runs
                                ; for Y=$00, then DEY makes Y=$FF, then BNE
                                ; takes ($FF != 0). So Y=$00 IS the first
                                ; iteration. Loop body runs Y=$00, $FF, $FE,
                                ; ..., $01. Total 256 bytes copied per page.)
INC $53             ; advance source page
INC $51             ; advance dest page
DEX                 ; decrement page count
BNE PAGE_COPY       ; another page?
RTS


; ============================================================================
; SECTION 10 — Data tables and strings ($116D-$11AF)
; ============================================================================

; ============================================================================
; SECTION 6 — Reset-vector bytes, error/info strings, slot signature tables,
;              and install-fragments source ($116D-$13BF, 595 bytes)
;
; This region contains:
;
;   $116D-$1172  Reset-vector replacement bytes installed at $FFFA-$FFFF
;                by the patch loop at $1140-$1149. The vectors decoded:
;                  $FFFA-B = NMI = $03C0
;                  $FFFC-D = RESET = $03C0
;                  $FFFE-F = IRQ = $8D8D (in normal RAM; suspicious)
;
;   $1173-$11BD  High-ASCII boot info/error strings, e.g. "CAN'T FIND Z80
;                SOFTCARD" and "MUST BOOT FROM SLOT SIX". Used by the
;                error-print loops at $10DF-$10EB and $1029-$1035, both
;                null-terminated.
;
;   $11BE-$11C1  SIG_TABLE_BYTE1: 4 bytes, $Cn05 expected values for slot
;                signature scan (X-indexed, entries 4..1).
;                  X=1: $03 (Apple Disk II)
;                  X=2: $18 (unknown)
;                  X=3: $38 (Pascal 1.0 ID byte 1)
;                  X=4: $48 (unknown; reads ONE PAST byte1 -> byte2[0])
;
;   $11C2-$11C5  SIG_TABLE_BYTE2: 4 bytes, $Cn07 expected values.
;                  X=1: $3C (Apple Disk II)
;                  X=2: $38, X=3: $18, X=4: ?
;
;   $11C6-$13BF  INSTALL-IMAGE source bytes for what becomes Apple
;                $0200-$03BF after the three install-copy loops. Annotated
;                source for the runtime form is in CPM223_InstallFragments.asm.
;
; The exact byte-by-byte annotations of the strings and tables in earlier
; revisions of this file had several offset errors that drifted the
; subsequent assembly. Rather than maintain duplicate per-byte annotation
; here, we INCBIN the entire region from the canonical loader image,
; preserving byte-identical round-trip while the structural prose above
; documents what's in the bytes.
; ============================================================================

            .incbin "cpm-investigation/loader_223.bin", $96D, $253


; ============================================================================
; SECTION 8 -- Warm-boot routine source ($13C0-$13DC)
;
; This routine is COPIED to $03C0 by the install loop at $10F1 (Section 4).
; It RUNS at $03C0 after the install. Full annotated source — including
; the discovery that JSR $0E36 is the SoftCard CPU-switch trigger — is
; in CPM223_InstallFragments.asm. The bytes here in the loader image
; are the SOURCE (loaded from track 0 physical sector 5).
; ============================================================================

WARM_BOOT_IMAGE:
LDA LC_WR_RAM       ; (1) bank in LC RAM (read+write, bank 1)
LDA LC_WR_RAM       ; (2) twice -- Apple LC bank-switch protocol
STA $FFFF           ; (3) write to $FFFF -- touch LC RAM top page
LDA LC_RD_RAM       ; (4) bank to LC bank 2
JSR $0E36           ; (5) <- CPU-SWITCH TRIGGER
                                ;     Apple $0E36 holds Z-80 instruction
                                ;     bytes (C3 39 FB = JP $FB39); the
                                ;     SoftCard hardware monitors the 6502's
                                ;     fetch and uses it to flip the bus to
                                ;     Z-80. See CPM223_InstallFragments.asm
                                ;     and Part 10 of the article series.
JSR IORTS           ; (6) one-byte RTS at $FF58 (no-op call)
STA LC_RD_RAM       ; (7) touch LC RAM read switch
SEI                 ; (8) disable interrupts
JSR SAVE            ; (9) call $FF4A monitor routine
JMP $03C0           ; (10) loop back to start (perpetual)

            ; Trailing install-fragments source bytes $13DC-$13FF (36 bytes,
            ; copied to runtime $03DC-$03FF — see CPM223_InstallFragments.asm).
            .incbin "cpm-investigation/loader_223.bin", $BDC, $24
