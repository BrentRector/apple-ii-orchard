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

            .ORG $0800

; Byte at $0800 is the page-count signal that P6 PROM checks.
; $01 means "one page loaded" (just the boot sector).
            .BYTE $01                       ; $0800

BOOT_STUB:
            LDA $27             ; $27 = page count P6 has loaded so far; $0801
            CMP #$09            ; first re-entry from P6: $27 = $09 ($08+1); $0803
            BNE .skip_init      ; on subsequent iterations skip the init block; $0805
                                ;
                                ; First entry: do one-time setup
            TXA                 ; X = slot*16 (e.g. $60 for slot 6); $0807
            LSR                 ;           ; $0808
            LSR                 ;           ; $0809
            LSR                 ;           ; $080A
            LSR                 ; A = slot number 0-7; $080B
            ORA #$C0            ; A = $C0 + slot (e.g. $C6 for slot 6); $080C
            STA zp_jmp_hi       ; $3F = $C6 (slot ROM page hi); $080E
            LDA #$5C            ;           ; $0810
            STA zp_jmp_lo       ; $3E = $5C; ($3E/$3F) = $C65C; $0812
                                ; $C65C is the P6 PROM "search for field
                                ; prolog" entry (mid-routine, reads one
                                ; sector identified by $3D, stores at ($26))
            LDA #$00            ;           ; $0814
            STA zp_count        ; $00 = 0 (sector-table index); $0816
            INC zp_p6_count     ; $27 = $0A (so first read goes to $0A00); $0818
                                ;
.skip_init:
            INC zp_count        ; $00 += 1 (advance sector-table index); $081A
            LDY zp_count        ; Y = current index; $081C
            CPY #$0B            ; loaded all 10 sectors yet? (Y=$0B = 11); $081E
            BNE .read_next      ;           ; $0820
            JMP $1000           ; YES — transfer to stage-2 entry; $0822
                                ;
.read_next:
            LDA $082D,Y         ; A = physical sector number from skew table; $0825
            STA $3D             ; tell P6 which physical sector to find; $0828
            JMP ($003E)         ; JMP $C65C — read sector to ($26),Y; $082A
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
            .BYTE $00,$02,$04,$06,$08,$0A,$0C,$0E; $082D
            .BYTE $01,$03,$05,$07,$09,$0B,$0D,$0F; $0835


; ----------------------------------------------------------------------------
; Copyright strings
; ----------------------------------------------------------------------------
; High-ASCII copyright (older Microsoft string, present in 2.20 and 2.23):
;     " COPYRIGHT (C) 1980 MICROSOFT - NK "
            .BYTE $A0,$C3,$CF,$D0,$D9,$D2,$C9,$C7,$C8,$D4    ; " COPYRIGHT"; $083D
            .BYTE $A0,$A8,$C3,$A9,$A0,$B1,$B9,$B8,$B0,$A0    ; " (C) 1980 "; $0847
            .BYTE $CD,$C9,$C3,$D2,$CF,$D3,$CF,$C6,$D4,$A0    ; "MICROSOFT "; $0851
            .BYTE $AD,$A0,$CE,$CB,$A0                        ; "- NK "; $085B

; Low-ASCII copyright (added in 2.23 only, $FF-filled in 2.20):
;     " COPYRIGHT (C) 1982 MICROSOFT - CP "
            .BYTE $20,$43,$4F,$50,$59,$52,$49,$47,$48,$54    ; " COPYRIGHT"; $0860
            .BYTE $20,$28,$43,$29,$20,$31,$39,$38,$32,$20    ; " (C) 1982 "; $086A
            .BYTE $4D,$49,$43,$52,$4F,$53,$4F,$46,$54,$20    ; "MICROSOFT "; $0874
            .BYTE $2D,$20,$43,$50,$20                        ; "- CP "; $087E

; Remainder of $0800 sector is zero-filled.
            .DS  $7D, $00                   ; $0883


; ============================================================================
; SECTION 2 — Disk I/O routines ($0A00-$0FFF)
;
; Loaded from physical sectors 2-C of track 0 (in CP/M skew order). These
; are the loader's RWTS-style routines: GCR encode/decode, sector seek,
; sector read, sector write. The loader uses these for any disk reads
; beyond track 0 (loading the rest of CP/M from disk).
;
; Standard Apple Disk II RWTS pattern, not annotated per-instruction —
; see the apple-panic disassembly in the same repo or the nibbler GCR
; module for parallel reference implementations. Survey of major entry
; points below.
; ============================================================================

; ----------------------------------------------------------------------------
; WRITE_SECTOR ($0A00) — write 256 bytes at $0C00 to current track/sector
;
; Inputs: X = slot*16, $3D = sector, current track is from earlier seek.
; Writes D5 AA AD (data prolog), 342 GCR-encoded data nibbles + checksum,
; then DE AA EB FF (data epilog). Uses the 6-and-2 GCR encoding tables
; in the language card area.
;
; Helper at $0A8F-$0A98 = WRITE_BYTE: send one nibble out the data shift
; register (Q6H/Q6L sequence). Used by WRITE_SECTOR for prolog/epilog.
; ----------------------------------------------------------------------------
WRITE_SECTOR:
            .DS  $8E, $00       ; (write routine — see binary); $0A00
WRITE_BYTE:
            .DS  $0B, $00       ; (write-byte helper); $0A8E


; ----------------------------------------------------------------------------
; READ_SECTOR ($0A99) — read current track/sector to $002C-$012B
;
; Loops looking for the address field prolog D5 AA 96, decodes the
; 4-and-4 encoded vol/track/sector/checksum, validates against the
; requested sector, then reads the data field at D5 AA AD prolog,
; decodes 342 nibbles into 256 data bytes, validates the DE AA EB
; epilog, returns with carry clear on success / set on failure.
;
; Standard Apple Disk II 6-and-2 GCR read pattern — see the apple-panic
; reference implementation in this repo for fully-annotated equivalent.
; ----------------------------------------------------------------------------
READ_SECTOR:
            .DS  $C7, $00       ; (read routine, address field search +; $0A99
                                ;  data field decode + epilog check)


; ----------------------------------------------------------------------------
; SEEK_TRACK ($0B5F) — move drive head to requested track
;
; Standard four-phase stepper sequence. Reads current head position from
; $0478 (Apple monitor screen-hole convention), compares with desired
; track, energizes phase coils to step in or out one half-track at a time
; until current = desired. Settling delay between steps.
; ----------------------------------------------------------------------------
SEEK_TRACK:
            .DS  $A1, $00       ; (seek-track routine, phase-coil sequencing); $0B5F


; ----------------------------------------------------------------------------
; LOAD_CPM ($0C00) — high-level "load N sectors from track T to memory"
;
; Increments a sector counter at $0003, sets up entry-point at $03E1,
; saves processor flags, disables interrupts, and CALLS into LC RAM at
; $BE11 — which is presumably another loader stage that orchestrates
; reading the CP/M system image (CCP+BDOS+BIOS) from the disk's system
; tracks (typically tracks 1-2 on Microsoft SoftCard CP/M disks) into
; the high-memory area $A300-$BFFF that PREP_HANDOFF will later move
; into final position before the SoftCard switch.
;
; If LC RAM call returns carry-clear (success), advances $03E9 and
; rotates the sector counter. If carry-set (failure), prints an error
; via JSR $FF2D / JMP $BBE9 and aborts.
; ----------------------------------------------------------------------------
LOAD_CPM:
            .DS  $200, $00      ; (sector-load orchestrator); $0C00


; ----------------------------------------------------------------------------
; GCR encoding tables (in this region or the next)
; Standard 6-and-2 encode/decode tables, indexed by 6-bit value or
; nibble. Likely at $0BD5A or similar — these are the lookup tables
; that the WRITE_SECTOR uses (`LDA $BD5A,X`).
; ----------------------------------------------------------------------------
            .DS  $200, $00      ; (more disk I/O code + tables, includes; $0E00
                                ; the JSR \$0E36 callee that the warm-boot
                                ; routine invokes — turns out to be a disk
                                ; read entry, NOT the SoftCard switch)


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

            .ORG $1000

STAGE2_ENTRY:
            LDA LC_RD_RAM       ; first access: enable read-from-ROM,; $1000
                                ; write-to-RAM (still reads ROM)
            LDA LC_RD_RAM       ; second access: now writable RAM is; $1003
                                ; banked in at $D000-$FFFF
            TXA                 ; X = slot*16 → A; $1006
            LSR                 ;           ; $1007
            LSR                 ;           ; $1008
            LSR                 ;           ; $1009
            LSR                 ; A = slot number (0-7); $100A
            TAY                 ; Y = slot number (used as index below); $100B
            PHA                 ; save slot on stack for later; $100C
            STA DISK_MOTOR_OFF,X ; turn off the disk II motor; $100D
                                ; (X is still slot*16; $C088+slot*16 hits
                                ; the motor-off soft switch)
            LDA #$00            ;           ; $1010
            STA $0478,Y         ; clear screen-hole "scratch" for this slot; $1012
            STA $04F8,Y         ; (Apple II monitor convention: $0478+$Cn; $1015
                                ; and $04F8+$Cn are per-slot scratch bytes)
            JSR TEXT            ; set Apple text mode; $1018
            JSR SETVID          ; route output through standard CSW; $101B
            JSR SETKBD          ; route input through standard KSW; $101E
            PLA                 ; restore A (the boot-success signal); $1021
            LDX #$FF            ;           ; $1022
            TXS                 ; reset stack pointer to $01FF; $1024
            CMP #$06            ; was the boot-success signal $06?; $1025
            BEQ MAIN_PATH       ; yes — proceed to main loader path; $1027

; ----------------------------------------------------------------------------
; Boot failure path: print error string from $1192 and drop to monitor
; ----------------------------------------------------------------------------
BOOT_FAIL:
            LDY #$00                        ; $1029
            LDA $1192,Y         ; load char from string at $1192; $102B
            BEQ .done           ; null terminator → exit print loop; $102E
            JSR COUT            ; print character; $1030
            INY                             ; $1033
            BNE $102B                       ; $1034
.done:
            JMP MONITOR         ; drop into Apple monitor; $1036


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
            LDY #$0E                        ; $1039
            LDA $11B0,Y                     ; $103B
            STA $0FFF,Y                     ; $103E
            DEY                             ; $1041
            BNE $103B                       ; $1042

; Copy 256 bytes from $1200..$12FF to $0200..$02FF
; (Y wraps from 0 back to $FF on the first DEY; loop runs $FF, $FE, ..., $01
;  then BNE exits when Y=0. So byte at $1200+0 = $1200 is NOT copied via this
;  loop — that's the byte we'll handle in the next loop.)
            LDA $1200,Y         ; Y is 0 entering, so first iteration reads; $1044
                                ; $1200+0 = $1200 and writes $0200+0 = $0200,
                                ; then DEY makes Y=$FF, then BNE loops $FF..$01.
            STA $0200,Y                     ; $1047
            DEY                             ; $104A
            BNE $1044                       ; $104B

; Copy 241 bytes from $1300..$13F0 to $0300..$03F0
            LDY #$F1                        ; $104D
            LDA $12FF,Y         ; reads $12FF+1..$12FF+$F1 = $1300..$13F0; $104F
            STA $02FF,Y         ; writes to $0300..$03F0; $1052
            DEY                             ; $1055
            BNE $104F                       ; $1056

            STY dev_count_d2    ; Y is now 0; zero the device-count counter; $1058
            STY zp_ptr_lo       ; $3C = 0 (low byte of slot-ROM pointer); $105B
            DEY                 ; Y = $FF   ; $105D
            STY zp_jmp_lo       ; $3E = $FF (initial value: "no slot iter yet"); $105E


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
            LDY #$C7            ; Y = $C7 (slot ROM page for slot 7); $1060
            STY zp_ptr_hi       ; $3D = $C7 (slot ROM hi byte); $1062
            STY $1069           ; SELF-MODIFY the operand at $1069 below; $1064
                                ; (changes "STA $C000" to "STA $Cn00", which
                                ; touches the slot's expansion-ROM-select
                                ; soft switch on the next read of $Cn00)
            STA KBD             ; clear keyboard strobe (originally STA $C000;; $1067
                                ; after the self-modify above, this becomes
                                ; STA $Cn00 — accessing slot ROM page)
            LDA zp_jmp_lo       ; $3E (slot iteration counter); $106A
            BEQ SCAN_INIT_SLOT  ; first slot ($3E=$FF coming in is non-zero;; $106C
                                ; this branch only taken on subsequent loops
                                ; when $3E has been incremented past 0)

; (Subsequent-iteration code path: validate slot ROM is stable across reads)
            JSR CKSUM_SLOT      ; checksum the slot ROM page; $106E
            STA zp_temp_a       ; save first checksum; $1071
            STX zp_temp_b                   ; $1073
            JSR CKSUM_SLOT      ; checksum again; $1075
            CPX #$00            ; if X=0, slot ROM might be empty/unstable; $1078
            BEQ SCAN_NO_MATCH   ; → no card here, default to code 0; $107A
            CMP zp_temp_a       ; checksums differ → unstable; $107C
            BNE SCAN_NO_MATCH               ; $107E
            CPX zp_temp_b                   ; $1080
            BEQ SCAN_DO_PROBE   ; checksums match → real ROM, proceed to probe; $1082
            BNE SCAN_NO_MATCH               ; $1084

SCAN_INIT_SLOT:
            INC zp_jmp_lo       ; $3E += 1 (advance iteration counter); $1086
            STY $03C8           ; record slot ROM page in handoff routine; $1088
            LDA #$00            ;           ; $108B
            STA $03C7           ; clear handoff routine's low-byte slot offset; $108D
            STA $03DE           ;   and another scratch; $1090
            TYA                 ;           ; $1093
            CLC                 ;           ; $1094
            #$20            ;               ; $1095 ADC
            STA $03DF           ; store $Cn + $20 in another handoff slot; $1097

SCAN_NO_MATCH:
            LDX #$00            ; X = 0 (will become device code 1 after INX); $109A
            BEQ STORE_DEV_CODE              ; $109C

; ----------------------------------------------------------------------------
; Pascal signature probe — match $Cn05 and $Cn07 against the 4-entry
; signature table at $11BE/$11C2. X starts at 4 and decrements; matched
; index becomes the device code after INX.
; ----------------------------------------------------------------------------
SCAN_DO_PROBE:
            LDX #$04            ; check entries 4, 3, 2, 1; $109E

.probe_loop:
            LDY #$05            ; offset of Pascal 1.0 ID byte 1; $10A0
            LDA ($3C),Y         ; A = $Cn05 of current slot ROM; $10A2
            CMP $11BE,X         ; compare against signature table[X]; $10A4
            BNE .next_sig       ; mismatch → try next signature; $10A7
            LDY #$07            ; offset of Pascal 1.0 ID byte 2; $10A9
            LDA ($3C),Y         ; A = $Cn07 ; $10AB
            CMP $11C2,X         ; compare against second-byte table[X]; $10AD
            BEQ .matched        ; both match → done; $10B0

.next_sig:
            DEX                 ; try next signature entry (X = 3, 2, 1); $10B2
            BNE .probe_loop     ; loop while X != 0; $10B3

.matched:
            INX                 ; X is now (matched_index + 1), or 1 if no match.; $10B5
                                ; Possible values: 1 (no match), 2..5 (matched
                                ; signature index from end-of-table).

            CPX #$02            ; matched signature 1 (the $03/$3C card)?; $10B6
            BNE .check_pascal   ; no — skip the type-2 counter; $10B8
            INC dev_count_d2    ; bump "type 2 device" counter; $10BA

; ----------------------------------------------------------------------------
; *** 11-BYTE PASCAL 1.1 CHECK — NEW IN 2.23, ABSENT FROM 2.20 ***
; If the Pascal 1.0 ID matched (X=4 after INX, meaning matched table[3] which
; is $38/$18 = the standard Pascal 1.0 firmware ID), additionally read the
; Pascal 1.1 signature byte at $Cn0B. If it equals $01 (the Pascal 1.1
; marker), override the device code to $06 (the Pascal-1.1 device code).
; ----------------------------------------------------------------------------
.check_pascal:
            CPX #$04            ; matched the Pascal 1.0 ID? (X=4 = matched; $10BD
                                ; table[3] = the $38/$18 entry)
            BNE STORE_DEV_CODE  ; no — store the matched-index value; $10BF
            LDY #$0B            ; Y = offset of Pascal 1.1 signature byte; $10C1
            LDA ($3C),Y         ; A = $Cn0B ; $10C3
            CMP #$01            ; is it the Pascal 1.1 marker?; $10C5
            BNE STORE_DEV_CODE  ; no — keep device code = 4 (Pascal 1.0); $10C7
            LDX #$06            ; YES — override device code to $06; $10C9

; ----------------------------------------------------------------------------
; Store the device code at the per-slot table ($03B9-$03BF) and continue
; scanning the next slot down (or exit when we reach slot 0).
; ----------------------------------------------------------------------------
STORE_DEV_CODE:
            LDY zp_ptr_hi       ; Y = current slot ROM page ($Cn); $10CB
            TXA                 ; A = device code; $10CD
            STA $02F8,Y         ; STA $02F8+$Cn = STA $03B9..$03BF for slot 1..7; $10CE
            DEY                 ; advance to next-lower slot; $10D1
            CPY #$C0            ; have we just done slot 0?; $10D2
            BNE $1062           ; no — loop back to scan next slot; $10D4


; ============================================================================
; SECTION 6 — Post-scan dispatch and Z-80 hand-off staging
; ============================================================================

POST_SCAN:
            ASL dev_count_d2    ; double the type-2 counter (sets carry from b7); $10D6
            LDA zp_jmp_lo       ; A = number of slots that had non-empty ROM; $10D9
            CMP #$01            ; only one slot had a real card?; $10DB
            BEQ DISPATCH_OK     ; yes — proceed to handoff staging; $10DD

; (More-than-one slot had cards — print info string and drop to monitor.
;  The string at $1173 is probably a "select boot device" prompt.)
            LDY #$00                        ; $10DF
            LDA $1173,Y                     ; $10E1
            BEQ .done                       ; $10E4
            JSR COUT                        ; $10E6
            INY                             ; $10E9
            BNE $10E1                       ; $10EA
.done:
            JMP MONITOR                     ; $10EC

; ----------------------------------------------------------------------------
; Final install: copy 16 bytes from $13EF to $03EF (Z-80 reset vector
; staging), then self-modify the loader's entry point.
; ----------------------------------------------------------------------------
DISPATCH_OK:
            LDY #$10                        ; $10EF
            LDA $13EF,Y                     ; $10F1
            STA $03EF,Y                     ; $10F4
            DEY                             ; $10F7
            BNE $10F1                       ; $10F8

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
            LDA #$C3            ; A = $C3 (Z-80 "JP nn" opcode); $10FA
            STA $1000           ; Apple $1000 = Z-80 $0000 (reset vector); $10FC
            LDA #$00            ;           ; $10FF
            STA $1001           ; Apple $1001 = low byte of JP target; $1101
            LDA #$FA            ;           ; $1104
            STA $1002           ; Apple $1002 = high byte of JP target; $1106
                                ; → Z-80 reads "JP $FA00" at its reset

; ----------------------------------------------------------------------------
; Copy disk I/O routines into the language card RAM area, then load
; replacement code over the original disk I/O area, then jump into the
; warm-boot routine (which is now installed at $03C0).
; ----------------------------------------------------------------------------
PREP_HANDOFF:
            LDA #$0A            ; source high byte: $0A00 (the disk I/O block); $1109
            STA $53             ;   ($52/$53 = source pointer); $110B
            LDA #$BA            ; dest high byte: $BA00 (in language card RAM); $110D
            STA $51             ;   ($50/$51 = dest pointer); $110F
            LDA #$00            ;           ; $1111
            STA $52             ; source low = 0; $1113
            STA $50             ; dest low = 0; $1115
            LDX #$06            ; copy 6 pages = $600 bytes; $1117
            JSR PAGE_COPY       ; copy $0A00..$0FFF → $BA00..$BFFF; $1119
                                ; (preserves the disk I/O routines in LC RAM
                                ; so they remain reachable after the original
                                ; $0A00 block gets overwritten below)

            LDA #$80                        ; $111C
            JSR $BBEB           ; call into LC RAM (was loaded at $9700 earlier; $111E
                                ; or staged elsewhere — purpose: TBD, possibly
                                ; an init or sector seek)
            LDA #$0A                        ; $1121
            STA $BC08           ; configure something at $BC08 (LC RAM byte); $1123

; Second copy: replace the disk I/O block with content from $9700-$9CFF
            LDA #$97                        ; $1126
            STA $53             ; source high = $97 ($9700); $1128
            LDA #$0A                        ; $112A
            STA $51             ; dest high = $0A ($0A00); $112C
            LDX #$06                        ; $112E
            JSR PAGE_COPY       ; copy $9700..$9CFF → $0A00..$0FFF; $1130
                                ; (replaces the original boot-stub-loaded disk
                                ; routines with a different version, possibly
                                ; CP/M-aware variants or ones with new entry
                                ; points the Z-80 will call into)

; Third copy: another smaller block
            LDA #$80                        ; $1133
            STA $53             ; source high = $80; $1135
            LDA #$A3                        ; $1137
            STA $51             ; dest high = $A3; $1139
            LDX #$17            ; X = $17 = 23 pages = $1700 bytes; $113B
            JSR PAGE_COPY       ; copy $8000..$96FF → $A300..$B9FF; $113D
                                ; This stages a substantial chunk into the LC
                                ; RAM area below where the disk routines were
                                ; preserved. Likely the CP/M system image
                                ; (CCP+BDOS+BIOS) being moved into position
                                ; for the Z-80 to find at fixed addresses.

; Patch Apple monitor reset vector at $FFF9 with custom values
            LDY #$06                        ; $1140
            LDA $116C,Y         ; load 6 bytes from data block at $116C; $1142
            STA $FFF9,Y         ; store to $FFF9..$FFFF (Apple monitor reset; $1145
                                ; vectors area: $FFFA/$FFFB = NMI vector,
                                ; $FFFC/$FFFD = RESET vector,
                                ; $FFFE/$FFFF = IRQ/BRK vector)
            DEY                             ; $1148
            BNE $1142                       ; $1149
            JMP $03D2           ; jump into the installed warm-boot routine; $114B
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
            LDA #$00                        ; $114E
            TAX                 ; X = 0 (carry counter); $1150
            TAY                 ; Y = 0 (offset counter); $1151
            CLC                             ; $1152
.loop:
            ($3C),Y         ; A += slot ROM byte; $1153 ADC
            .nocarry                        ; $1155 BCC
            INX                 ; bump carry counter on overflow; $1157
.nocarry:
            INY                             ; $1158
            BNE .loop           ; loop 256 times (Y = $00..$FF then wrap); $1159
            RTS                             ; $115B

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
            LDY #$00                        ; $115C
.byte_loop:
            LDA ($52),Y                     ; $115E
            STA ($50),Y                     ; $1160
            DEY                             ; $1162
            BNE .byte_loop      ; loop $FF, $FE, ..., $01, then exit (Y = 0; $1163
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
            INC $53             ; advance source page; $1165
            INC $51             ; advance dest page; $1167
            DEX                 ; decrement page count; $1169
            BNE PAGE_COPY       ; another page?; $116A
            RTS                             ; $116C


; ============================================================================
; SECTION 10 — Data tables and strings ($116D-$11AF)
; ============================================================================

; ----------------------------------------------------------------------------
; Apple monitor reset-vector replacement bytes
; Loaded into $FFFA-$FFFF by the patch loop at $1140-$1149.
; Y goes 6,5,4,3,2,1 — so byte at $116C+1=$116D goes to $FFFA;
; byte at $116C+6=$1172 goes to $FFFF. The 6 bytes installed are:
;   $FFFA/B = NMI vector
;   $FFFC/D = RESET vector
;   $FFFE/F = IRQ/BRK vector
; (Byte at $116C is the RTS of the PAGE_COPY routine just above; not used
; here because Y starts at 6 and counts down, and BNE exits at Y=0 —
; but the code uses STA $FFF9,Y which means $FFF9+6 = $FFFF. So the
; SOURCE bytes are $116C+0..$116C+6, and they map to $FFF9..$FFFF.
; The Y=0 case is excluded by BNE so $116C+0 = $60 = RTS is not loaded.)
; ----------------------------------------------------------------------------
            .BYTE $60                                ; (RTS of PAGE_COPY); $116C
RESET_VECS:
            .BYTE $C0,$03,$C0,$03,$8D,$8D,$8D        ; → $FFFA-$FFFF; $116D
                                                     ; (interpreted as 3 vectors:
                                                     ;  NMI=$03C0, RST=$03C0,
                                                     ;  IRQ=$8D8D — note IRQ vector
                                                     ;  high byte is suspicious;
                                                     ;  $8D8D is in normal RAM)

; ----------------------------------------------------------------------------
; High-ASCII strings (boot info / error messages)
; Used by the error-print loop at $10DF-$10EB and the boot-fail loop at
; $1029-$1035. Both are terminated by null ($00) bytes.
; ----------------------------------------------------------------------------
STRING_BLOCK:
            .BYTE $8D,$8D,$8D,$8D,$00                ; CR CR CR CR null; $1173
            .BYTE $8D,$8D,$8D,$8D,$8D,$CD,$D5,$D3    ; "...MUS"; $1178
            .BYTE $D4,$A0,$C2,$CF,$CF,$D4,$A0,$C6    ; "T BOOT F"; $1180
            .BYTE $D2,$CF,$CD,$A0,$D3,$CC,$CF,$D4    ; "ROM SLOT"; $1188
            .BYTE $A0,$D3,$C9,$D8,$8D,$8D,$8D,$8D    ; " SIX" + CRs; $1190
                                                     ; → "MUST BOOT FROM SLOT SIX"

            .BYTE $00,$AF,$32,$3E,$F0,$6F,$3A,$3D    ; (probably part of next; $1198
            .BYTE $F0,$C6,$20,$67,$77,$18            ; data block — TBD); $11A0

; ----------------------------------------------------------------------------
; Slot scanner signature data table (Section 7 above) — $11BE-$11C5
; ----------------------------------------------------------------------------


; ============================================================================
; SECTION 7 — Slot scanner signature data table ($11BE-$11C5)
;
; Eight bytes, two parallel 4-entry tables. Indexed by X=4..1 in the
; scanner. Byte-identical between 2.20 and 2.23 (only the location
; differs; 2.20 has it at $1176-$117D).
; ============================================================================

SIG_TABLE_BYTE1:
            .BYTE $F2, $03, $18, $38     ; expected $Cn05 for entries 4,3,2,1; $11BE
                                         ; (read with X-indexing: entry index
                                         ; X reads byte at $11BE+X)
                                         ;   X=4: $48 ← actually offset +4 reads
                                         ;        ONE PAST end of byte1 table;
                                         ;        the table layout means X=4
                                         ;        reads $11BE+4 = $11C2 = $48
                                         ;        which is the FIRST byte of
                                         ;        the byte2 table. So X=4 is
                                         ;        effectively the "$48/?" pair.
                                         ;   X=3: $38 (Pascal 1.0 ID byte 1!)
                                         ;   X=2: $18
                                         ;   X=1: $03

SIG_TABLE_BYTE2:
            .BYTE $48, $3C, $38, $18     ; expected $Cn07 for entries 4,3,2,1; $11C2
                                         ;   X=3: $18 (Pascal 1.0 ID byte 2!)
                                         ;   X=2: $38
                                         ;   X=1: $3C
                                         ;
                                         ; Combined signatures:
                                         ;   X=1: $Cn05=$03, $Cn07=$3C
                                         ;        → Apple Disk II controller
                                         ;          (verified: P6 ROM bytes
                                         ;          at $C605=$03 and $C607=$3C)
                                         ;   X=2: $Cn05=$18, $Cn07=$38
                                         ;        → unknown (Microsoft serial?)
                                         ;   X=3: $Cn05=$38, $Cn07=$18
                                         ;        → APPLE PASCAL 1.0 firmware
                                         ;   X=4: $Cn05=$48, $Cn07=??
                                         ;        → unknown (Microsoft printer?)


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
            LDA LC_WR_RAM       ; (1) bank in LC RAM (read+write, bank 1); $13C0
            LDA LC_WR_RAM       ; (2) twice -- Apple LC bank-switch protocol; $13C3
            STA $FFFF           ; (3) write to $FFFF -- touch LC RAM top page; $13C6
            LDA LC_RD_RAM       ; (4) bank to LC bank 2; $13C9
            JSR $0E36           ; (5) <- CPU-SWITCH TRIGGER; $13CC
                                ;     Apple $0E36 holds Z-80 instruction
                                ;     bytes (C3 39 FB = JP $FB39); the
                                ;     SoftCard hardware monitors the 6502's
                                ;     fetch and uses it to flip the bus to
                                ;     Z-80. See CPM223_InstallFragments.asm
                                ;     and Part 10 of the article series.
            JSR IORTS           ; (6) one-byte RTS at $FF58 (no-op call); $13CF
            STA LC_RD_RAM       ; (7) touch LC RAM read switch; $13D2
            SEI                 ; (8) disable interrupts; $13D5
            JSR SAVE            ; (9) call $FF4A monitor routine; $13D6
            JMP $03C0           ; (10) loop back to start (perpetual); $13D9
