; ============================================================================
; Microsoft SoftCard CP/M 2.23 — 6502 Boot Loader
; Annotated disassembly of the loader as it exists in Apple ][ RAM
; after the boot stub completes.
;
; The loader occupies $0800-$13FF in Apple ][ RAM. It is loaded by the
; Disk II P6 PROM (sector 0 → $0800) and then by the boot stub itself
; (10 more sectors of track 0 → $0A00-$1300, in CP/M sector skew order).
;
; This file annotates the well-understood sections:
;   $0800-$083C  Boot stub (sector 0, runs first)
;   $1000-$10FF  Stage-2 entry, install loops, slot scanner, dispatch
;   $11BE-$11C5  Slot-scanner signature data table
;   $13C0-$13DC  SoftCard handoff routine (gets installed at $03C0)
;
; Sections NOT yet annotated:
;   $0A00-$0FFF  Disk read/write (RWTS-style GCR routines)
;   $1100-$11AF  Subroutines + strings + small data tables
;   $11B0-$11FF  More data
;   $1200-$12FF  Page-2 install image (becomes Z-80 code at Apple $0200)
;   $1300-$13BF  Page-3 install image (becomes Z-80 code at Apple $0300)
;
; The companion narrative is docs/CPM_BootLoader.md.
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
$0800:      .BYTE $01

BOOT_STUB:
$0801:      LDA $27             ; $27 = page count P6 has loaded so far
$0803:      CMP #$09            ; first re-entry from P6: $27 = $09 ($08+1)
$0805:      BNE .skip_init      ; on subsequent iterations skip the init block
                                ;
                                ; First entry: do one-time setup
$0807:      TXA                 ; X = slot*16 (e.g. $60 for slot 6)
$0808:      LSR                 ;
$0809:      LSR                 ;
$080A:      LSR                 ;
$080B:      LSR                 ; A = slot number 0-7
$080C:      ORA #$C0            ; A = $C0 + slot (e.g. $C6 for slot 6)
$080E:      STA zp_jmp_hi       ; $3F = $C6 (slot ROM page hi)
$0810:      LDA #$5C            ;
$0812:      STA zp_jmp_lo       ; $3E = $5C; ($3E/$3F) = $C65C
                                ; $C65C is the P6 PROM "search for field
                                ; prolog" entry (mid-routine, reads one
                                ; sector identified by $3D, stores at ($26))
$0814:      LDA #$00            ;
$0816:      STA zp_count        ; $00 = 0 (sector-table index)
$0818:      INC zp_p6_count     ; $27 = $0A (so first read goes to $0A00)
                                ;
.skip_init:
$081A:      INC zp_count        ; $00 += 1 (advance sector-table index)
$081C:      LDY zp_count        ; Y = current index
$081E:      CPY #$0B            ; loaded all 10 sectors yet? (Y=$0B = 11)
$0820:      BNE .read_next      ;
$0822:      JMP $1000           ; YES — transfer to stage-2 entry
                                ;
.read_next:
$0825:      LDA $082D,Y         ; A = physical sector number from skew table
$0828:      STA $3D             ; tell P6 which physical sector to find
$082A:      JMP ($003E)         ; JMP $C65C — read sector to ($26),Y
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
$082D:      .BYTE $00,$02,$04,$06,$08,$0A,$0C,$0E
$0835:      .BYTE $01,$03,$05,$07,$09,$0B,$0D,$0F


; ----------------------------------------------------------------------------
; Copyright strings
; ----------------------------------------------------------------------------
; High-ASCII copyright (older Microsoft string, present in 2.20 and 2.23):
;     " COPYRIGHT (C) 1980 MICROSOFT - NK "
$083D:      .BYTE $A0,$C3,$CF,$D0,$D9,$D2,$C9,$C7,$C8,$D4    ; " COPYRIGHT"
$0847:      .BYTE $A0,$A8,$C3,$A9,$A0,$B1,$B9,$B8,$B0,$A0    ; " (C) 1980 "
$0851:      .BYTE $CD,$C9,$C3,$D2,$CF,$D3,$CF,$C6,$D4,$A0    ; "MICROSOFT "
$085B:      .BYTE $AD,$A0,$CE,$CB,$A0                        ; "- NK "

; Low-ASCII copyright (added in 2.23 only, $FF-filled in 2.20):
;     " COPYRIGHT (C) 1982 MICROSOFT - CP "
$0860:      .BYTE $20,$43,$4F,$50,$59,$52,$49,$47,$48,$54    ; " COPYRIGHT"
$086A:      .BYTE $20,$28,$43,$29,$20,$31,$39,$38,$32,$20    ; " (C) 1982 "
$0874:      .BYTE $4D,$49,$43,$52,$4F,$53,$4F,$46,$54,$20    ; "MICROSOFT "
$087E:      .BYTE $2D,$20,$43,$50,$20                        ; "- CP "

; Remainder of $0800 sector is zero-filled.
$0883:      .DS  $7D, $00


; ============================================================================
; SECTION 2 — Disk I/O routines ($0A00-$0FFF)
;
; Loaded from physical sectors 2-C of track 0 (in CP/M skew order). These
; are the loader's RWTS-style routines: GCR encode/decode, sector seek,
; sector read, sector write. The loader uses these for any disk reads
; beyond track 0 (loading the rest of CP/M from disk).
;
; Not yet annotated — they're a fairly standard Apple Disk II RWTS
; implementation. See the existing nibbler GCR module for parallel
; reference implementations.
; ============================================================================
$0A00:      .DS  $600, $00      ; disk I/O block (placeholder)


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
$1000:      LDA LC_RD_RAM       ; first access: enable read-from-ROM,
                                ; write-to-RAM (still reads ROM)
$1003:      LDA LC_RD_RAM       ; second access: now writable RAM is
                                ; banked in at $D000-$FFFF
$1006:      TXA                 ; X = slot*16 → A
$1007:      LSR                 ;
$1008:      LSR                 ;
$1009:      LSR                 ;
$100A:      LSR                 ; A = slot number (0-7)
$100B:      TAY                 ; Y = slot number (used as index below)
$100C:      PHA                 ; save slot on stack for later
$100D:      STA DISK_MOTOR_OFF,X ; turn off the disk II motor
                                ; (X is still slot*16; $C088+slot*16 hits
                                ; the motor-off soft switch)
$1010:      LDA #$00            ;
$1012:      STA $0478,Y         ; clear screen-hole "scratch" for this slot
$1015:      STA $04F8,Y         ; (Apple II monitor convention: $0478+$Cn
                                ; and $04F8+$Cn are per-slot scratch bytes)
$1018:      JSR TEXT            ; set Apple text mode
$101B:      JSR SETVID          ; route output through standard CSW
$101E:      JSR SETKBD          ; route input through standard KSW
$1021:      PLA                 ; restore A (the boot-success signal)
$1022:      LDX #$FF            ;
$1024:      TXS                 ; reset stack pointer to $01FF
$1025:      CMP #$06            ; was the boot-success signal $06?
$1027:      BEQ MAIN_PATH       ; yes — proceed to main loader path

; ----------------------------------------------------------------------------
; Boot failure path: print error string from $1192 and drop to monitor
; ----------------------------------------------------------------------------
BOOT_FAIL:
$1029:      LDY #$00
$102B:      LDA $1192,Y         ; load char from string at $1192
$102E:      BEQ .done           ; null terminator → exit print loop
$1030:      JSR COUT            ; print character
$1033:      INY
$1034:      BNE $102B
.done:
$1036:      JMP MONITOR         ; drop into Apple monitor


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
$1039:      LDY #$0E
$103B:      LDA $11B0,Y
$103E:      STA $0FFF,Y
$1041:      DEY
$1042:      BNE $103B

; Copy 256 bytes from $1200..$12FF to $0200..$02FF
; (Y wraps from 0 back to $FF on the first DEY; loop runs $FF, $FE, ..., $01
;  then BNE exits when Y=0. So byte at $1200+0 = $1200 is NOT copied via this
;  loop — that's the byte we'll handle in the next loop.)
$1044:      LDA $1200,Y         ; Y is 0 entering, so first iteration reads
                                ; $1200+0 = $1200 and writes $0200+0 = $0200,
                                ; then DEY makes Y=$FF, then BNE loops $FF..$01.
$1047:      STA $0200,Y
$104A:      DEY
$104B:      BNE $1044

; Copy 241 bytes from $1300..$13F0 to $0300..$03F0
$104D:      LDY #$F1
$104F:      LDA $12FF,Y         ; reads $12FF+1..$12FF+$F1 = $1300..$13F0
$1052:      STA $02FF,Y         ; writes to $0300..$03F0
$1055:      DEY
$1056:      BNE $104F

$1058:      STY dev_count_d2    ; Y is now 0; zero the device-count counter
$105B:      STY zp_ptr_lo       ; $3C = 0 (low byte of slot-ROM pointer)
$105D:      DEY                 ; Y = $FF
$105E:      STY zp_jmp_lo       ; $3E = $FF (initial value: "no slot iter yet")


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
$1060:      LDY #$C7            ; Y = $C7 (slot ROM page for slot 7)
$1062:      STY zp_ptr_hi       ; $3D = $C7 (slot ROM hi byte)
$1064:      STY $1069           ; SELF-MODIFY the operand at $1069 below
                                ; (changes "STA $C000" to "STA $Cn00", which
                                ; touches the slot's expansion-ROM-select
                                ; soft switch on the next read of $Cn00)
$1067:      STA KBD             ; clear keyboard strobe (originally STA $C000;
                                ; after the self-modify above, this becomes
                                ; STA $Cn00 — accessing slot ROM page)
$106A:      LDA zp_jmp_lo       ; $3E (slot iteration counter)
$106C:      BEQ SCAN_INIT_SLOT  ; first slot ($3E=$FF coming in is non-zero;
                                ; this branch only taken on subsequent loops
                                ; when $3E has been incremented past 0)

; (Subsequent-iteration code path: validate slot ROM is stable across reads)
$106E:      JSR CKSUM_SLOT      ; checksum the slot ROM page
$1071:      STA zp_temp_a       ; save first checksum
$1073:      STX zp_temp_b
$1075:      JSR CKSUM_SLOT      ; checksum again
$1078:      CPX #$00            ; if X=0, slot ROM might be empty/unstable
$107A:      BEQ SCAN_NO_MATCH   ; → no card here, default to code 0
$107C:      CMP zp_temp_a       ; checksums differ → unstable
$107E:      BNE SCAN_NO_MATCH
$1080:      CPX zp_temp_b
$1082:      BEQ SCAN_DO_PROBE   ; checksums match → real ROM, proceed to probe
$1084:      BNE SCAN_NO_MATCH

SCAN_INIT_SLOT:
$1086:      INC zp_jmp_lo       ; $3E += 1 (advance iteration counter)
$1088:      STY $03C8           ; record slot ROM page in handoff routine
$108B:      LDA #$00            ;
$108D:      STA $03C7           ; clear handoff routine's low-byte slot offset
$1090:      STA $03DE           ;   and another scratch
$1093:      TYA                 ;
$1094:      CLC                 ;
$1095:      ADC #$20            ;
$1097:      STA $03DF           ; store $Cn + $20 in another handoff slot

SCAN_NO_MATCH:
$109A:      LDX #$00            ; X = 0 (will become device code 1 after INX)
$109C:      BEQ STORE_DEV_CODE

; ----------------------------------------------------------------------------
; Pascal signature probe — match $Cn05 and $Cn07 against the 4-entry
; signature table at $11BE/$11C2. X starts at 4 and decrements; matched
; index becomes the device code after INX.
; ----------------------------------------------------------------------------
SCAN_DO_PROBE:
$109E:      LDX #$04            ; check entries 4, 3, 2, 1

.probe_loop:
$10A0:      LDY #$05            ; offset of Pascal 1.0 ID byte 1
$10A2:      LDA ($3C),Y         ; A = $Cn05 of current slot ROM
$10A4:      CMP $11BE,X         ; compare against signature table[X]
$10A7:      BNE .next_sig       ; mismatch → try next signature
$10A9:      LDY #$07            ; offset of Pascal 1.0 ID byte 2
$10AB:      LDA ($3C),Y         ; A = $Cn07
$10AD:      CMP $11C2,X         ; compare against second-byte table[X]
$10B0:      BEQ .matched        ; both match → done

.next_sig:
$10B2:      DEX                 ; try next signature entry (X = 3, 2, 1)
$10B3:      BNE .probe_loop     ; loop while X != 0

.matched:
$10B5:      INX                 ; X is now (matched_index + 1), or 1 if no match.
                                ; Possible values: 1 (no match), 2..5 (matched
                                ; signature index from end-of-table).

$10B6:      CPX #$02            ; matched signature 1 (the $03/$3C card)?
$10B8:      BNE .check_pascal   ; no — skip the type-2 counter
$10BA:      INC dev_count_d2    ; bump "type 2 device" counter

; ----------------------------------------------------------------------------
; *** 11-BYTE PASCAL 1.1 CHECK — NEW IN 2.23, ABSENT FROM 2.20 ***
; If the Pascal 1.0 ID matched (X=4 after INX, meaning matched table[3] which
; is $38/$18 = the standard Pascal 1.0 firmware ID), additionally read the
; Pascal 1.1 signature byte at $Cn0B. If it equals $01 (the Pascal 1.1
; marker), override the device code to $06 (the Pascal-1.1 device code).
; ----------------------------------------------------------------------------
.check_pascal:
$10BD:      CPX #$04            ; matched the Pascal 1.0 ID? (X=4 = matched
                                ; table[3] = the $38/$18 entry)
$10BF:      BNE STORE_DEV_CODE  ; no — store the matched-index value
$10C1:      LDY #$0B            ; Y = offset of Pascal 1.1 signature byte
$10C3:      LDA ($3C),Y         ; A = $Cn0B
$10C5:      CMP #$01            ; is it the Pascal 1.1 marker?
$10C7:      BNE STORE_DEV_CODE  ; no — keep device code = 4 (Pascal 1.0)
$10C9:      LDX #$06            ; YES — override device code to $06

; ----------------------------------------------------------------------------
; Store the device code at the per-slot table ($03B9-$03BF) and continue
; scanning the next slot down (or exit when we reach slot 0).
; ----------------------------------------------------------------------------
STORE_DEV_CODE:
$10CB:      LDY zp_ptr_hi       ; Y = current slot ROM page ($Cn)
$10CD:      TXA                 ; A = device code
$10CE:      STA $02F8,Y         ; STA $02F8+$Cn = STA $03B9..$03BF for slot 1..7
$10D1:      DEY                 ; advance to next-lower slot
$10D2:      CPY #$C0            ; have we just done slot 0?
$10D4:      BNE $1062           ; no — loop back to scan next slot


; ============================================================================
; SECTION 6 — Post-scan dispatch and Z-80 hand-off staging
; ============================================================================

POST_SCAN:
$10D6:      ASL dev_count_d2    ; double the type-2 counter (sets carry from b7)
$10D9:      LDA zp_jmp_lo       ; A = number of slots that had non-empty ROM
$10DB:      CMP #$01            ; only one slot had a real card?
$10DD:      BEQ DISPATCH_OK     ; yes — proceed to handoff staging

; (More-than-one slot had cards — print info string and drop to monitor.
;  The string at $1173 is probably a "select boot device" prompt.)
$10DF:      LDY #$00
$10E1:      LDA $1173,Y
$10E4:      BEQ .done
$10E6:      JSR COUT
$10E9:      INY
$10EA:      BNE $10E1
.done:
$10EC:      JMP MONITOR

; ----------------------------------------------------------------------------
; Final install: copy 16 bytes from $13EF to $03EF (Z-80 reset vector
; staging), then self-modify the loader's entry point.
; ----------------------------------------------------------------------------
DISPATCH_OK:
$10EF:      LDY #$10
$10F1:      LDA $13EF,Y
$10F4:      STA $03EF,Y
$10F7:      DEY
$10F8:      BNE $10F1

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
$10FA:      LDA #$C3            ; A = $C3 (Z-80 "JP nn" opcode)
$10FC:      STA $1000           ; Apple $1000 = Z-80 $0000 (reset vector)
$10FF:      LDA #$00            ;
$1101:      STA $1001           ; Apple $1001 = low byte of JP target
$1104:      LDA #$FA            ;
$1106:      STA $1002           ; Apple $1002 = high byte of JP target
                                ; → Z-80 reads "JP $FA00" at its reset

; ----------------------------------------------------------------------------
; Copy disk I/O routines into the language card RAM area, then load
; replacement code over the original disk I/O area, then jump into the
; warm-boot routine (which is now installed at $03C0).
; ----------------------------------------------------------------------------
PREP_HANDOFF:
$1109:      LDA #$0A            ; source high byte: $0A00 (the disk I/O block)
$110B:      STA $53             ;   ($52/$53 = source pointer)
$110D:      LDA #$BA            ; dest high byte: $BA00 (in language card RAM)
$110F:      STA $51             ;   ($50/$51 = dest pointer)
$1111:      LDA #$00            ;
$1113:      STA $52             ; source low = 0
$1115:      STA $50             ; dest low = 0
$1117:      LDX #$06            ; copy 6 pages = $600 bytes
$1119:      JSR PAGE_COPY       ; copy $0A00..$0FFF → $BA00..$BFFF
                                ; (preserves the disk I/O routines in LC RAM
                                ; so they remain reachable after the original
                                ; $0A00 block gets overwritten below)

$111C:      LDA #$80
$111E:      JSR $BBEB           ; call into LC RAM (was loaded at $9700 earlier
                                ; or staged elsewhere — purpose: TBD, possibly
                                ; an init or sector seek)
$1121:      LDA #$0A
$1123:      STA $BC08           ; configure something at $BC08 (LC RAM byte)

; Second copy: replace the disk I/O block with content from $9700-$9CFF
$1126:      LDA #$97
$1128:      STA $53             ; source high = $97 ($9700)
$112A:      LDA #$0A
$112C:      STA $51             ; dest high = $0A ($0A00)
$112E:      LDX #$06
$1130:      JSR PAGE_COPY       ; copy $9700..$9CFF → $0A00..$0FFF
                                ; (replaces the original boot-stub-loaded disk
                                ; routines with a different version, possibly
                                ; CP/M-aware variants or ones with new entry
                                ; points the Z-80 will call into)

; Third copy: another smaller block
$1133:      LDA #$80
$1135:      STA $53             ; source high = $80
$1137:      LDA #$A3
$1139:      STA $51             ; dest high = $A3
$113B:      LDX #$17            ; X = $17 = 23 pages = $1700 bytes
$113D:      JSR PAGE_COPY       ; copy $8000..$96FF → $A300..$B9FF
                                ; This stages a substantial chunk into the LC
                                ; RAM area below where the disk routines were
                                ; preserved. Likely the CP/M system image
                                ; (CCP+BDOS+BIOS) being moved into position
                                ; for the Z-80 to find at fixed addresses.

; Patch Apple monitor reset vector at $FFF9 with custom values
$1140:      LDY #$06
$1142:      LDA $116C,Y         ; load 6 bytes from data block at $116C
$1145:      STA $FFF9,Y         ; store to $FFF9..$FFFF (Apple monitor reset
                                ; vectors area: $FFFA/$FFFB = NMI vector,
                                ; $FFFC/$FFFD = RESET vector,
                                ; $FFFE/$FFFF = IRQ/BRK vector)
$1148:      DEY
$1149:      BNE $1142
$114B:      JMP $03D2           ; jump into the installed warm-boot routine
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
$114E:      LDA #$00
$1150:      TAX                 ; X = 0 (carry counter)
$1151:      TAY                 ; Y = 0 (offset counter)
$1152:      CLC
.loop:
$1153:      ADC ($3C),Y         ; A += slot ROM byte
$1155:      BCC .nocarry
$1157:      INX                 ; bump carry counter on overflow
.nocarry:
$1158:      INY
$1159:      BNE .loop           ; loop 256 times (Y = $00..$FF then wrap)
$115B:      RTS

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
$115C:      LDY #$00
.byte_loop:
$115E:      LDA ($52),Y
$1160:      STA ($50),Y
$1162:      DEY
$1163:      BNE .byte_loop      ; loop $FF, $FE, ..., $01, then exit (Y = 0
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
$1165:      INC $53             ; advance source page
$1167:      INC $51             ; advance dest page
$1169:      DEX                 ; decrement page count
$116A:      BNE PAGE_COPY       ; another page?
$116C:      RTS


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
$116C:      .BYTE $60                                ; (RTS of PAGE_COPY)
RESET_VECS:
$116D:      .BYTE $C0,$03,$C0,$03,$8D,$8D,$8D        ; → $FFFA-$FFFF
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
$1173:      .BYTE $8D,$8D,$8D,$8D,$00                ; CR CR CR CR null
$1178:      .BYTE $8D,$8D,$8D,$8D,$8D,$CD,$D5,$D3    ; "...MUS"
$1180:      .BYTE $D4,$A0,$C2,$CF,$CF,$D4,$A0,$C6    ; "T BOOT F"
$1188:      .BYTE $D2,$CF,$CD,$A0,$D3,$CC,$CF,$D4    ; "ROM SLOT"
$1190:      .BYTE $A0,$D3,$C9,$D8,$8D,$8D,$8D,$8D    ; " SIX" + CRs
                                                     ; → "MUST BOOT FROM SLOT SIX"

$1198:      .BYTE $00,$AF,$32,$3E,$F0,$6F,$3A,$3D    ; (probably part of next
$11A0:      .BYTE $F0,$C6,$20,$67,$77,$18            ; data block — TBD)

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
$11BE:      .BYTE $F2, $03, $18, $38     ; expected $Cn05 for entries 4,3,2,1
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
$11C2:      .BYTE $48, $3C, $38, $18     ; expected $Cn07 for entries 4,3,2,1
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
; SECTION 8 — SoftCard handoff routine ($13C0-$13DC)
;
; This routine is COPIED to $03C0 by the install loop (Section 4). It
; runs there, performing the actual CPU switch from 6502 to Z-80.
;
; Self-modifying: the STA $FFFF at $13C6 has its operand overwritten
; by the slot scanner ($1064 STY $1069 modifies $1069, but a separate
; mechanism patches the $03C7/$03C8 handoff code via $108B/$108D STAs).
; ============================================================================

; Bytes here as they exist in the loader image; once installed at $03C0
; they execute from there.

WARM_BOOT_IMAGE:
$13C0:      LDA LC_WR_RAM       ;
$13C3:      LDA LC_WR_RAM       ; second access: enable write+read RAM
$13C6:      STA $FFFF           ; SELF-MODIFIED operand. After scanner runs,
                                ; the operand becomes $Cn00 — touching the
                                ; slot's expansion-ROM-select switch to page
                                ; the slot's ROM into $C800-$CFFF.
$13C9:      LDA LC_RD_RAM       ; back to read-from-ROM mode
$13CC:      JSR $0E36           ; call into the loader's Phase-3 install fragment
                                ; (this is in the loader area at Apple $0E36 —
                                ; loaded from sector A of track 0 at offset $E36
                                ; within that sector)
$13CF:      JSR IORTS           ; immediate-RTS landing pad (no-op call)
$13D2:      STA LC_RD_RAM       ;
$13D5:      SEI                 ; disable interrupts (about to switch CPUs)
$13D6:      JSR SAVE            ; save 6502 register state
$13D9:      JMP $03C0           ; loop back to start of warm-boot

; The actual SoftCard CPU-switch toggle (write to $C0Bx for the Z-80's
; slot) is not visible here — it lives elsewhere, possibly in the JSR
; $0E36 callee. Identifying that exact instruction is open work.
