# Microsoft SoftCard CP/M 2.23 — 6502 Boot Loader

This document walks the 6502-side boot loader of Microsoft SoftCard CP/M
2.23 from the moment the Apple ][ Disk II P6 PROM jumps into it, to the
moment the 6502 hands off to the Z-80 SoftCard. It complements the
fully-annotated assembly in [`CPM223_BootLoader.asm`](./CPM223_BootLoader.asm).

The loader for 2.20 is structurally identical except for the slot-scanner
delta documented in [`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md);
where this document calls out 2.20-only or 2.23-only behavior, it does so
explicitly.

## Architecture in One Diagram

```
Apple ][ memory after the boot stub finishes loading track 0:

  $0800 ─┬───────────────────────────────────────────────────┐
         │ Boot stub (sector 0, $0801-$083C)                 │
  $083D  │ Copyright strings in high-/low-ASCII              │
  $088D  │ Zeros (sector 0 padding)                          │
  $0900  │ Empty (P6 PROM working area, never reused)        │
  $0A00 ─┤ Disk read/write routines (GCR encode, decode,     │
         │   sector seek, RWTS-style — sectors 2-C of trk 0) │
  $1000 ─┤ Stage-2 entry point ◄── boot stub jumps here     │
         │ Boot setup, slot scanner, code installer           │
  $1100  │ Subroutines + data tables                          │
  $1200  │ Page-2 install image (copied to $0200 page)        │
  $1300  │ Page-3 install image (copied to $0300 page)        │
  $13FF ─┴───────────────────────────────────────────────────┘
```

The first 256 bytes (`$0800-$08FF`) are loaded by the Disk II P6 PROM —
just one sector — using a 16-bit page count of 1 stored at the very first
byte. The boot stub at `$0801` then loads ten more sectors using the
P6 PROM's "search for field prolog" entry at `$Cn5C` (where `n` is the
slot, typically 6).

After the boot stub completes, it jumps to `$1000`, which is the stage-2
entry point. Stage 2 is the loader proper.

## Stage 2's Job

Stage 2 has six tasks before it can boot the Z-80:

1. **Initialize the Apple ][.** Switch in the language card RAM (the Z-80
   needs RAM at the high addresses where the Apple's monitor ROM normally
   lives). Reset the Apple keyboard input switches to defaults.

2. **Self-check.** Verify a boot-success signal value in the accumulator
   matches `$06`. If not, print an error message and drop into the
   Apple monitor.

3. **Install fragments into low Apple ][ RAM.** Copy a small data block
   from `$11B0` to `$0FFF`, copy 256 bytes from `$1200` to `$0200`, and
   copy 241 bytes from `$1300` to `$0300`. The bytes copied to `$0200`
   and `$0300` are mostly Z-80 code that will execute after the SoftCard
   handoff (because the SoftCard maps Apple `$0xxx` to Z-80 `$1xxx` after
   its address-line XOR — see "SoftCard Memory Mapping" below).

4. **Scan the Apple slots.** Walk slots 7 → 1, page each slot's expansion
   ROM in, and check `$Cn05`/`$Cn07` against a small fixed signature
   table. Record a per-slot device code at `$03B9-$03BF`. **2.23 also
   reads `$Cn0B` and assigns Pascal-1.1 cards a special device code `$06`
   — see [`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md).**

5. **Final install.** Copy a 16-byte block from `$13EF` to `$03EF` (the
   SoftCard handoff vector and friends). Self-modify the JMP at `$1000`
   (the stage-2 entry) so a future re-entry through the warm-boot path
   lands somewhere different.

6. **Hand off to the Z-80.** Disable interrupts (`SEI`), call into the
   warm-boot routine at `$03C0` (which itself does the SoftCard switch
   via a write to `$C0Bx` for the Z-80's slot, typically slot 4).
   Execution continues on the Z-80 from a Z-80 reset vector that points
   into the just-installed code at `$0200`/`$0300` (mapped to Z-80
   `$1200`/`$1300`).

## SoftCard Memory Mapping (Critical Background)

The Microsoft Z-80 SoftCard maps Z-80 addresses to Apple ][ addresses
with a single XOR on bit 12 (i.e., `apple_addr = z80_addr XOR $1000`).
This swap exists because the Z-80 needs RAM at `$0000-$00FF` (its restart
vectors and zero page), but the Apple ][ has its 6502 zero page there
already. The XOR puts Apple page 1 (just RAM) at Z-80 page 0 instead.

In practice:

| Apple ][ address | Z-80 address |
|------------------|--------------|
| `$0000-$0FFF`    | `$1000-$1FFF` |
| `$1000-$1FFF`    | `$0000-$0FFF` |
| `$2000-$FFFF`    | `$2000-$FFFF` (no swap) |

So when the loader copies bytes from `$1300` to `$0300` (Apple addresses),
the Z-80 sees those bytes at Z-80 `$1300`. Code at Apple `$0344` is Z-80
code that executes from Z-80 `$1344`. Conversely, the loader's own 6502
code at Apple `$1000` would be Z-80 `$0000` — which is Z-80 zero page,
not where Z-80 looks for code. That's intentional: the 6502 finishes its
work and writes the actual Z-80 entry point into Z-80 reset vectors
before flipping the SoftCard switch.

## Walking Through the Code

### Phase 1 — Boot stub ($0801-$083C)

Loaded by the P6 PROM with `JSR $C600`, which reads sector 0 of track 0
to `$0800-$08FF` and `JMP $0801`. The boot stub uses the P6 PROM's
mid-routine entry at `$Cn5C` ("search for field prolog") to read 10
additional sectors of track 0 in CP/M sector skew order:

```
Iteration  Physical sector  Destination
   1         2                 $0A00
   2         4                 $0B00
   3         6                 $0C00
   4         8                 $0D00
   5         A                 $0E00
   6         C                 $0F00
   7         E                 $1000  ◄── stage-2 entry point
   8         1                 $1100
   9         3                 $1200
  10         5                 $1300
```

Then `JMP $1000`. Sectors 7, 9, B, D, F of track 0 are not loaded by the
boot stub and are left untouched on the disk-side; they're not part of
the loader image.

### Phase 2 — Stage-2 entry and self-check ($1000-$1037)

```
$1000: LDA $C081 / LDA $C081     ; language-card switch (read ROM, write RAM
                                 ; with second access enabling write)
$1006: TXA / LSR x4 / TAY        ; X = slot * 16 (P6 convention) → A = slot
$100B: PHA                       ; save slot number on stack
$100D: STA $C088,X               ; turn off disk drive motor
$1010: LDA #$00                  ; clear two screen-hole bytes for the slot:
$1012: STA $0478,Y               ;   $0478+slot
$1015: STA $04F8,Y               ;   $04F8+slot
$1018: JSR $FB2F                 ; Apple monitor: TEXT (set text mode)
$101B: JSR $FE93                 ; Apple monitor: SETVID (route output to screen)
$101E: JSR $FE89                 ; Apple monitor: SETKBD (route input from kbd)
$1021: PLA                       ; restore A (which is now... what?)
                                 ; Actually A was loaded with the boot signal
                                 ; before we got here; we saved it via PHA.
$1022: LDX #$FF / TXS            ; reset stack pointer to $01FF
$1025: CMP #$06                  ; boot signal == $06?
$1027: BEQ $1039                 ; yes, proceed to main path
```

If A != `$06` at `$1025`, the loader prints a string from `$1192`
(probably "BOOT ERROR" or similar) and drops into the Apple monitor at
`$FF65`:

```
$1029: LDY #$00
$102B: LDA $1192,Y               ; load char from string
$102E: BEQ $1036                 ; null terminator? exit loop
$1030: JSR $FDED                 ; COUT: print character
$1033: INY / BNE $102B           ; next char
$1036: JMP $FF65                 ; Apple monitor entry
```

### Phase 3 — Code installation ($1039-$1058)

Three back-to-back copy loops install Apple-ROM-area routines and the
device-table data structures into low Apple ][ RAM:

```
$1039: LDY #$0E                  ; copy 14 bytes from $11B0 to $0FFF
$103B: LDA $11B0,Y / STA $0FFF,Y / DEY / BNE -7
                                 ; Note: Y goes 14,13,...,1, so this writes
                                 ; $0FFF+14..$0FFF+1 = $100D..$1000. Wait.
                                 ; That's the entry-point area! This is
                                 ; modifying the loader code itself? Or
                                 ; pre-positioning data for later use.

$1044: LDA $1200,Y / STA $0200,Y / DEY / BNE -7
                                 ; copy 256 bytes from $1200-$12FF to $0200-$02FF

$104D: LDY #$F1                  ; copy 241 bytes from $1300+1..$13F1 to $0301..$03F1
$104F: LDA $12FF,Y / STA $02FF,Y / DEY / BNE -7

$1058: STY $03B8                 ; Y is now 0; zero the device-1 counter
```

The page-2 and page-3 destinations (`$0200-$03FF`) are exactly the
addresses that Z-80 `$1200-$13FF` map to under the SoftCard XOR. So
this is the loader staging the Z-80-side bootstrap into Apple memory
before the SoftCard switch.

### Phase 4 — Slot scanner ($1059-$10D5)

Documented in detail in [`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md).
Walks slots 7 → 1, identifies cards via the Pascal firmware ID byte
table at `$11BE/$11C2`, stores per-slot device codes at `$03B9-$03BF`,
self-modifies the slot-ROM-page byte at `$1069` to access each slot's
ROM in turn.

The 2.23 version inserts an 11-byte branch after a Pascal 1.0 ID match
to also check `$Cn0B` for the Pascal 1.1 signature byte; if found,
overrides the device code with `$06` (the Pascal 1.1 device code).

### Phase 5 — Post-scan dispatch ($10D6-$10F9)

```
$10D6: ASL $03B8                 ; double the device-1 counter
                                 ; (or extract bit 7 — sets carry from bit 7)
$10D9: LDA $3E                   ; the slot-scan iteration counter
$10DB: CMP #$01                  ; only one slot scanned?
$10DD: BEQ $10EF                 ; yes, skip the error path
                                 ; otherwise print error and exit:
$10DF: LDY #$00
$10E1: LDA $1173,Y / BEQ $10EC / JSR COUT / INY / BNE -7
$10EC: JMP $FF65                 ; drop into Apple monitor

$10EF: LDY #$10                  ; the success path: copy 16 bytes from
$10F1: LDA $13EF,Y / STA $03EF,Y ; $13EF to $03EF (the Z-80 reset vector
$10F7: DEY / BNE -7              ; staging area)
```

### Phase 6 — Plant the Z-80 reset vector ($10FA-$1106)

This is the cleanest find from working through the loader. The bytes
written into Apple `$1000-$1002` after the slot scan are not 6502
instructions at all. They're Z-80 machine code:

```
$10FA: LDA #$C3 / STA $1000     ; Apple $1000 = Z-80 $0000 (reset vector)
$10FF: LDA #$00 / STA $1001     ; low byte of JP target
$1104: LDA #$FA / STA $1002     ; high byte of JP target
```

After the SoftCard XOR, Apple `$1000` is Z-80 `$0000` — the Z-80's
reset vector address. The bytes `$C3 $00 $FA` decode as the Z-80
instruction `JP $FA00`. So when the SoftCard switch flips control to
the Z-80, the Z-80 fetches its first instruction at its `$0000`, sees
`JP $FA00`, and jumps directly into the 2.23 CP/M BIOS cold-boot entry
(the BOOT slot at the start of the BIOS jump table at `$FA00`).

This is the SoftCard handoff bridge: the 6502 finishes its work,
plants the Z-80 reset vector with the address of the CP/M BIOS, and
only then flips the SoftCard switch.

**CP/M 2.20 verified**: at the equivalent address (`$10F2-$10FE` in
2.20's loader image), 2.20 plants `$C3 $00 $DA` = Z-80 `JP $DA00` —
exactly consistent with its BIOS load address at `$DACC`. The
structural pattern (load-immediate-then-store, three pairs) is
byte-identical between versions; only the high byte of the JP target
differs (`$FA` in 2.23, `$DA` in 2.20). This independently confirms
the BIOS load address findings from jump-table scanning earlier in
the investigation — the same `$2000` shift, surfaced from the 6502
side this time.

### Phase 7 — SoftCard handoff (continues into installed code at $03C0+)

The final SoftCard switch lives in the **installed** code at `$03C0+`
(originally at `$13C0+` in the loader image). That code:

```
$03C0: LDA $C083 / LDA $C083     ; language card RAM enable (write+read)
$03C6: STA $FFFF                 ; ??? (target byte gets self-modified by
                                 ; the slot scanner when a slot was scanned)
$03C9: LDA $C081                 ; switch back to read-from-ROM
$03CC: JSR $0E36                 ; call back into loader (init?)
$03CF: JSR $FF58                 ; Apple monitor IORTS (returns immediately)
$03D2: STA $C081                 ; language card again
$03D5: SEI                       ; disable interrupts (about to switch CPUs)
$03D6: JSR $FF4A                 ; Apple monitor SAVE (save 6502 state)
$03D9: JMP $03C0                 ; loop / re-entry
```

The actual SoftCard CPU switch is via a write to `$C0Bx` where `x`
identifies the SoftCard's slot (typically slot 4, so `$C0C0` would be
the toggle... but the actual address depends on the SoftCard build —
verifying this is part of the open work).

## What's Open

This document covers the boot stub, stage-2 entry, install, slot scan,
and dispatch. The actual `$0A00-$0FFF` disk-routine block (sector
read/write, GCR encode/decode) is not yet annotated — it's a fairly
standard Apple Disk II-style RWTS implementation and the boot loader
calls into it for any disk reads it needs to do beyond track 0.

Also open: precise verification of the SoftCard switch sequence (the
exact `$C0Bx` write that flips the CPU), and the Z-80-side code that
runs immediately after the switch (which lives in the bytes installed
at `$0200-$03FF` — Apple addresses — equivalent to Z-80 `$1200-$13FF`).

The fully-annotated 6502 disassembly is in
[`CPM223_BootLoader.asm`](./CPM223_BootLoader.asm) — work in progress;
boot stub and stage-2 entry are complete, disk I/O block is not yet
annotated.
