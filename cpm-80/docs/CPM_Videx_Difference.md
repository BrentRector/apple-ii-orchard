# CP/M 2.20 vs 2.23 — The Videx-Detection Delta

This document identifies the specific code change in Microsoft's Apple II
SoftCard CP/M between version 2.20 (which fails to boot with a Videx
Videoterm 80-column card installed) and version 2.23 (which boots and
runs correctly with one).

## TL;DR

The change is in the **6502 boot loader**, not the Z-80 BIOS. Both versions
scan slots 1-7 looking for cards that match a small table of known Pascal
firmware signatures. 2.23 added a single extra check: after the standard
**Apple Pascal 1.0** ID bytes ($Cn05=$38, $Cn07=$18) match, 2.23 also
reads the **Pascal 1.1 signature byte at $Cn0B**. If that byte is `$01`
(the value Pascal 1.1 cards stamp there), the slot is tagged with device
code `$06` (a new code that 2.20 doesn't know about). The Videx Videoterm's
expansion ROM stores `$01` at $CB0B (mirrored to $Cn0B when the slot ROM
is paged in), which is exactly what 2.23 looks for. The extra check is
11 bytes of inserted 6502 code.

This means **2.23 is not "Videx-aware" but "Pascal-1.1-aware"**. Any slot
card that follows the Apple II Pascal 1.1 firmware protocol gets the
new device code, regardless of what *kind* of device it claims to be.
2.23 doesn't even read the device-type byte at $Cn0C — it treats every
Pascal 1.1 card identically. The Videx is the most common Pascal 1.1
card on the Apple ][ in 1982; it benefits accordingly.

The canonical reference for the protocol is **Apple II Technical Note
Misc #8**, "Pascal 1.1 Firmware Protocol ID Bytes" by Cameron Birse and
Matt Deatherage (Apple DTS, 1986–1988) — the only document Apple ever
formally published on this protocol.

## The 8 byte Pascal signature table — identical in both versions

Both loaders contain the same 8-byte data table holding four 2-byte
device signatures. In 2.20 it sits at `$1176-$117D`; in 2.23 it has
shifted to `$11BE-$11C5`. The bytes are byte-for-byte identical:

```
F2 03 18 38   <- bytes expected at $Cn05 (column-indexed via X=4..1)
48 3C 38 18   <- bytes expected at $Cn07
```

Read column-wise, the four signatures are:

| X | $Cn05 | $Cn07 | Identifies |
|---|------|------|------------|
| 1 | $03  | $3C  | (Microsoft-specific?) |
| 2 | $18  | $38  | (reversed Pascal — Microsoft serial?) |
| 3 | $38  | $18  | **Standard Apple II Pascal 1.1** |
| 4 | $F2  | $48  | (unknown — possibly an early Microsoft card) |

The first comparison (X=4 entering the loop) is against signature #4 ($F2/$48);
the loop decrements X, so #3 (Pascal) is checked second, #2 third, #1 last.
After a match, `INX` makes X one more than the matching index, so X holds
2..5 to indicate which signature matched.

## The slot scanner — annotated diff

Both versions share the same outer structure: walk slots 7 → 1, set
`$3C/$3D = $Cn00` (pointer to the slot ROM page), test the bytes there,
record a per-slot device code at `$02F8+slot`. The code below uses
symbolic names from the Videx Videoterm ROM disassembly
(`e:/a2fpga_core/hdl/videx/Videx Videoterm ROM 2.4.asm`) where
applicable:

```
SLOTROM_PTR    = $3C    ; 16-bit pointer to $Cn00 (slot ROM base)
PASCAL10_ID1   = $05    ; offset of Pascal 1.0 ID byte 1 ($Cn05 = $38)
PASCAL10_ID2   = $07    ; offset of Pascal 1.0 ID byte 2 ($Cn07 = $18)
PASCAL11_SIG   = $0B    ; offset of Pascal 1.1 signature byte ($Cn0B = $01)
DEV_TABLE      = $02F8  ; per-slot device-code byte ($02F8+$Cn = $03B9..$03BF)
COUNT_DEV2     = $03B8  ; counter for "type-2" matches
```

### CP/M 2.20 — slot scanner

```asm
; ---------------------------------------------------------------------
; Slot scanner: 2.20 version. Recognizes 4 Pascal-style signatures
; from a fixed table and tags slots that match. Has no concept of a
; "device class" beyond the raw signature pair.
; ---------------------------------------------------------------------
$1097: A2 04        LDX #$04           ; X = 4: start at table entry 4
                                       ; (loop will check entries 4,3,2,1)
$1099: A0 05        LDY #$05           ; Y = SIG_BYTE_1 offset
$109B: B1 3C        LDA ($3C),Y        ; A = byte at $Cn05 of slot ROM
$109D: DD 76 11     CMP $1176,X        ; compare to SIG1 table[X]
$10A0: D0 09        BNE $10AB          ; mismatch -> try next entry
$10A2: A0 07        LDY #$07           ; Y = SIG_BYTE_2 offset
$10A4: B1 3C        LDA ($3C),Y        ; A = byte at $Cn07 of slot ROM
$10A6: DD 7A 11     CMP $117A,X        ; compare to SIG2 table[X]
$10A9: F0 03        BEQ $10AE          ; full match -> exit loop
$10AB: CA           DEX                ; mismatch on byte 2 -> next entry
$10AC: D0 EB        BNE $1099          ; loop while X != 0
$10AE: E8           INX                ; X is now (matched_index + 1)
                                       ;   = 2..5 if matched, 1 if not
$10AF: E0 02        CPX #$02           ; matched signature #1?
$10B1: D0 03        BNE $10B6          ; no -> skip the type-1 counter
$10B3: EE B8 03     INC $03B8          ; yes -> bump COUNT_DEV2
$10B6: A4 3D        LDY $3D            ; Y = current slot ROM page ($Cn)
$10B8: 8A           TXA                ; A = device code (1..5)
$10B9: 99 F8 02     STA $02F8,Y        ; write to DEV_TABLE[$Cn]
$10BC: 88           DEY                ; advance to next-lower slot
$10BD: C0 C0        CPY #$C0           ; done after slot 0?
$10BF: D0 9E        BNE $105F          ; no -> next slot
$10C1: 0E B8 03     ASL $03B8          ; (continue with post-scan logic)
```

### CP/M 2.23 — slot scanner (with the new Videx-detection branch)

```asm
; ---------------------------------------------------------------------
; Slot scanner: 2.23 version. Same 4-signature table, same outer loop,
; but adds an extra check after a signature #4 match: if $Cn0B == $01
; (Pascal generic device byte == $01, e.g., the Videx Videoterm),
; tag the slot with the special device code $06 instead of the raw
; matched-index value.
; ---------------------------------------------------------------------
$109E: A2 04        LDX #$04           ; X = 4: start at table entry 4
$10A0: A0 05        LDY #$05           ; Y = SIG_BYTE_1 offset
$10A2: B1 3C        LDA ($3C),Y        ; A = byte at $Cn05 of slot ROM
$10A4: DD BE 11     CMP $11BE,X        ; compare to SIG1 table[X]
$10A7: D0 09        BNE $10B2          ; mismatch -> try next entry
$10A9: A0 07        LDY #$07           ; Y = SIG_BYTE_2 offset
$10AB: B1 3C        LDA ($3C),Y        ; A = byte at $Cn07 of slot ROM
$10AD: DD C2 11     CMP $11C2,X        ; compare to SIG2 table[X]
$10B0: F0 03        BEQ $10B5          ; full match -> exit loop
$10B2: CA           DEX                ; mismatch on byte 2 -> next entry
$10B3: D0 EB        BNE $10A0          ; loop while X != 0
$10B5: E8           INX                ; X is now (matched_index + 1)
$10B6: E0 02        CPX #$02           ; matched signature #1?
$10B8: D0 03        BNE $10BD          ; no -> skip the type-1 counter
$10BA: EE B8 03     INC $03B8          ; yes -> bump COUNT_DEV2
$10BD: E0 04        CPX #$04           ; ============================
                                       ; NEW IN 2.23: did we match the
                                       ; STANDARD APPLE II PASCAL
                                       ; signature ($38/$18, signature
                                       ; #3 in the table, X=4 after
                                       ; the loop)?
$10BF: D0 0A        BNE $10CB          ; no -> normal handling
$10C1: A0 0B        LDY #$0B           ; Y = DEV_CLASS offset
$10C3: B1 3C        LDA ($3C),Y        ; A = Pascal generic device byte
                                       ; (Videx Videoterm: $CB0B = $01)
$10C5: C9 01        CMP #$01           ; is it $01?
$10C7: D0 02        BNE $10CB          ; no -> normal handling
$10C9: A2 06        LDX #$06           ; YES -> override device code: $06
                                       ; ============================
$10CB: A4 3D        LDY $3D            ; Y = current slot ROM page ($Cn)
$10CD: 8A           TXA                ; A = device code (1..5, or 6 for
                                       ;   Videx-class Pascal device)
$10CE: 99 F8 02     STA $02F8,Y        ; write to DEV_TABLE[$Cn]
$10D1: 88           DEY                ; advance to next-lower slot
$10D2: C0 C0        CPY #$C0           ; done after slot 0?
$10D4: D0 8C        BNE $1062          ; no -> next slot
$10D6: 0E B8 03     ASL $03B8          ; (continue with post-scan logic)
```

The full insertion is **11 bytes** (`E0 04 D0 0A A0 0B B1 3C C9 01 D0 02`
plus `A2 06`) added between the type-2 counter and the per-slot store.
The two loaders are otherwise structurally identical in this region.

## Why the new check matters

In 2.20, when the boot loader sees a card with the Apple Pascal 1.0 ID
bytes ($Cn05=$38, $Cn07=$18), it tags the slot with device code 4
(matched_index 3 + 1). The remainder of the boot loader and the Z-80
BIOS treat all device-code-4 slots the same way — most likely as a
generic Pascal-protocol I/O device, routing character I/O through the
Pascal 1.0 entry-point convention. That works for older Pascal 1.0
cards (like Apple's parallel/serial cards). It does not work for cards
that need the Pascal 1.1 entry-point convention.

The Videx Videoterm is a Pascal **1.1** card. It declares the full
Pascal 1.1 signature: not just the 1.0 ID bytes at $Cn05/$Cn07, but
also $Cn0B=$01 (Pascal 1.1 signature) and $Cn0C=$82 (device-type
nibble $8 — informally a display — plus instance ID $2). 2.20 only
checks the Pascal 1.0 bytes; it sees a Pascal-compatible card and
treats it generically.

2.23 added the check for $Cn0B=$01 and assigns Pascal 1.1 cards a
dedicated device code ($06). It does not check the device-type byte
at $Cn0C, so it doesn't differentiate displays from other Pascal 1.1
device classes — it just identifies "this is a Pascal 1.1 card,
drive it through the Pascal 1.1 path." The Videx is the dominant
Pascal 1.1 card on Apple ][ in 1982; it benefits.

The Videx ROM disassembly ([Videx ROM 2.4 line 706-708](
file:///e:/a2fpga_core/hdl/videx/Videx%20Videoterm%20ROM%202.4.asm#L706))
documents the bytes:

```
$CB05 = $38       Pascal 1.0 ID byte 1
$CB07 = $18       Pascal 1.0 ID byte 2 (also OUTENTR opcode)
$CB0B = $01       Pascal 1.1 signature
$CB0C = $82       device type $8 (display, informal), instance $2
```

The bytes at $CB05/$CB07/$CB0B/$CB0C are what the Videx exposes when its
expansion ROM is paged in and slot 3 is selected (the Videx is
typically installed in slot 3); they appear at $C305/$C307/$C30B/$C30C
when the slot ROM is windowed in via PR#3 or direct hardware selection.

The canonical Pascal protocol reference is Apple II Technical Note
Misc #8, "Pascal 1.1 Firmware Protocol ID Bytes" — see the device-type
nibble registry there. Apple never maintained a public list of
device-type assignments; the `$8` for display is informal but
universally observed on display cards of the era.

## What we still don't know

This finding identifies the *detection* delta — how 2.23 recognizes
the Videx where 2.20 does not. The corresponding code that *consumes*
the new device code `$06` lives further into the boot loader and in
the Z-80 BIOS's CONOUT/BOOT routines, and would presumably know how
to drive a Videx Videoterm specifically: program the 6845 CRTC at
`$C0B0/$C0B1`, write characters into the `$CC00-$CDFF` VRAM window,
manage the `$CFFF` ROM-release switch, etc. Documenting that path
is a follow-up — the present finding is sufficient to explain why
2.20 fails to boot on a Videx system.

## Reproduction

The disassembly was produced by:

1. Running `python -m disasm6502` on a 3 KB Apple II memory image
   reconstructed from the disk's track-0 sectors in the order the boot
   stub loads them (sectors 0, 2, 4, 6, 8, A, C, E, 1, 3, 5 → memory
   addresses $0800, $0A00, $0B00, $0C00, $0D00, $0E00, $0F00, $1000,
   $1100, $1200, $1300).
2. Both `cpm-80/disks/CPMV233.DSK` (CP/M 2.23, DOS 3.3 sector order) and
   `cpm-80/disks/CPM220Disk1.po` (CP/M 2.20, ProDOS sector order) yield the
   same boot-stub bytes at file offset 0 and the same boot-stub-loaded
   bytes at $1000 (`AD 81 C0 AD 81 C0 ...` — the Apple II language
   card switch).
3. The build scripts and intermediate artifacts live in
   `cpm-80/cpm-investigation/`.

Files of interest:

| File | Purpose |
|------|---------|
| `cpm-80/cpm-investigation/extract_loader.py` | Builds the 3 KB Apple II memory image |
| `cpm-80/cpm-investigation/loader_223.bin` | 2.23 boot loader image ($0800-$13FF) |
| `cpm-80/cpm-investigation/loader_220.bin` | 2.20 boot loader image ($0800-$13FF) |
| `cpm-80/cpm-investigation/disasm_223_linear.txt` | Full 6502 linear disassembly |
| `cpm-80/cpm-investigation/disasm_220_linear.txt` | Full 6502 linear disassembly |
