# Microsoft SoftCard CP/M 2.23 — Disk Sector Map

This is the per-physical-sector reference for `CPMV233.DSK` — the
Microsoft SoftCard CP/M 2.23 disk image. For every physical sector,
it identifies the bytes' content, the runtime memory address (Apple
side and Z-80 side where they differ), and the mechanism that loads
those bytes from disk into memory.

The disk is 35 tracks × 16 sectors × 256 bytes = 143,360 bytes total.
This map covers the boot-relevant tracks (0, 1, 2, partial 3). Tracks
3 onward are the CP/M filesystem and aren't part of the boot pipeline.

The map uses **physical sector numbers** (the order sectors appear on
the disk surface). The boot stub and LOAD_CPM both reference logical
sectors via the CP/M skew table `0,2,4,6,8,A,C,E,1,3,5`, so a
"logical sector 1" is read from physical sector 6, etc. To avoid
ambiguity, this map is anchored to physical positions throughout.

## Track 0

Track 0 is loaded entirely by the boot pipeline — first the P6 PROM
loads sector 0, then the boot stub at `$0801-$083C` loads ten more
sectors in CP/M skew order, then the stage-2 loader at `$1000` reads
the rest via LOAD_CPM into staging.

| Phys | Skew→Logical | Loaded by | Apple address | Contents |
|------|--------------|-----------|---------------|----------|
| 0 | 0 | P6 PROM (boot sector 0) | `$0800-$08FF` | Boot stub at `$0801-$083C` (60 bytes); rest is sector skew table and zero padding. **Byte-identical between 2.20 and 2.23.** |
| 1 | 8 | Boot stub | `$1100-$11FF` | Stage-2 loader continuation. Boot-finalization sequence at `$1100-$114B` (formerly mislabeled "$1900"). Contains the Z-80 reset vector planting (`STA $1001 / LDA #$FA / STA $1002`), the CCP+BDOS reverse-staging copy, and `JMP $03D2` into the warm-boot routine. |
| 2 | 1 | Boot stub | `$0A00-$0AFF` | RWTS code (low half). Preserved at `$BA00-$BAFF` after PREP_HANDOFF. |
| 3 | 9 | Boot stub | `$1200-$12FF` | **Install-fragment source.** Stage-2 loader copies this to Apple `$0200-$02FF` via the loop at Apple `$1044`. |
| 4 | 2 | Boot stub | `$0B00-$0BFF` | RWTS code (mid). Preserved at `$BB00-$BBFF`. |
| 5 | 10 | Boot stub | `$1300-$13FF` | **Install-fragment source.** Becomes Apple `$0300-$03FF` via loops at Apple `$104F` (most of it) and `$10F1` (last 16 bytes). The warm-boot routine at runtime `$03C0-$03DC` is sourced from `$13C0-$13DC`. |
| 6 | 3 | Boot stub | `$0C00-$0CFF` | First 256 bytes of BIOS first 1 KB at runtime; also part of Z-80 disk-callback area. (Note: PREP_HANDOFF moves this — see below.) |
| 7 | 11 | Not loaded by boot stub | — | Skipped by the CP/M skew. May be unused or read later by LOAD_CPM. |
| 8 | 4 | Boot stub | `$0D00-$0DFF` | More RWTS-area / callback bytes. |
| 9 | 12 | Not loaded by boot stub | — | Skipped. |
| A | 5 | Boot stub | `$0E00-$0EFF` | Z-80 disk-callback area. Contains the inter-CPU sync polling loop at offset `$36-$44` (= Apple `$0E36-$0E44`, Z-80 `$1E36-$1E44`). The `JSR $0E36` from the warm-boot routine targets this. |
| B | 13 | Not loaded by boot stub | — | Skipped. |
| C | 6 | Boot stub | `$0F00-$0FFF` | BIOS first 1 KB continuation. |
| D | 14 | Not loaded by boot stub | — | Skipped. |
| E | 7 | Boot stub | `$1000-$10FF` | **Stage-2 loader entry.** `JMP $1000` from the boot stub lands at the entry. Contains the install loops that copy `$1200-$13FF` → `$0200-$03FF`. |
| F | 15 | Not loaded by boot stub | — | Skipped. |

The boot stub physically reads 11 sectors from track 0 (sector 0 plus
the ten in skew order). After it completes, control passes to
`$1000`. The stage-2 loader runs the install loops, the slot scanner,
and then issues the first LOAD_CPM call.

## LOAD_CPM (first call) — 29 sectors starting at trk0:logical 0x0B

The stage-2 loader at Apple `$1407`+ does:

```
LDA #$1D     ; 29 sectors
JMP $BBE9    ; (or $BBEB; equivalent entry into LOAD_CPM)
```

The 29 sectors are read in CP/M skew order, into Apple `$8000-$9CFF`
(29 × 256 = 7424 bytes). The skew advances logical sectors `0xB, 0xC,
0xD, 0xE, 0xF` on track 0, then all of track 1, then logical sectors
`0x00-0x07` on track 2 — under the standard skew table that maps
logical → physical.

Result in staging at `$8000-$9CFF`:
- `$8000-$96FF` (5888 bytes): CCP + BDOS image plus a banner string
  at the tail (`Softcard CP/M / 60K Ver. 2.23 / (c) 1980,1982 Microsoft`).
- `$9700-$9CFF` (1536 bytes): Z-80 disk callbacks (first 512 bytes)
  followed by BIOS first 1 KB (1024 bytes).

## PREP_HANDOFF — three page copies

Before the SoftCard CPU switch, the loader does:

1. **Preserve RWTS**: copy Apple `$0A00-$0FFF` (the RWTS area loaded
   by the boot stub) to `$BA00-$BFFF`. After this copy the original
   RWTS is at `$BAxx`; the `$0Axx` slots are about to be overwritten.

2. **Install Z-80 callbacks + BIOS first 1 KB**: copy the staging tail
   `$9700-$9CFF` to `$0A00-$0FFF`. The Z-80 disk callbacks now sit at
   Apple `$0A00-$0BFF` (Z-80 `$1A00-$1BFF` after bit-12 XOR), and the
   BIOS first 1 KB at Apple `$0C00-$0FFF`.

3. **Relocate CCP+BDOS**: copy staging `$A300-$B9FF` to `$8000-$96FF`
   via the loop at Apple `$113D`. The BDOS final position is `$9C06`,
   which lands inside this range (CCP just above; BDOS occupies
   `$8E06-$9C05`-ish).

## LOAD_CPM (second call) — at Apple `$111E`

After PREP_HANDOFF, the loader does a second `JSR $BBEB` with `A=$80`.
This call reads additional sectors from disk. The destination and
exact sector count haven't been fully traced, but evidence suggests
it loads the bytes that end up at the runtime BIOS regions visible to
Z-80 only via LC RAM.

Candidate bytes that this call would source:
- `trk2:phys8` — first 256 bytes of BIOS page 4 area (covers `$FEB8-$FFB7`).
  Confirmed contains the cold-boot device-scan code at offset 86+
  (i.e., Apple `$0E56`-relative once mapped).
- `trk2:phys9-physF` — additional BIOS-related bytes including the
  `$FFB8-$FFFF` partial page.
- `trk2:physA` — 256 bytes of real Z-80 code that calls into BIOS
  routines, **not in the first LOAD_CPM staging** — strong candidate
  for a runtime-installed handler template.

## Track 2 partial map

| Phys | Read by? | Likely destination | Contents |
|------|----------|---------------------|----------|
| 0-7 | First LOAD_CPM (mapped via skew) | Various within `$8000-$9CFF` staging | CCP+BDOS+callbacks+BIOS first 1 KB |
| 8 | Second LOAD_CPM (likely) | LC RAM at runtime BIOS area | First 256 bytes of BIOS page 4: NOP slide + cold-boot device-scan starting at offset 86 |
| 9 | Second LOAD_CPM (likely) | LC RAM at `$FFB8`-area | Trap-marker pattern (`FF FF 00 00 / F7 F7 00 00`) — runtime handler slots |
| A | Second LOAD_CPM (probable) | Likely Z-80 `$0Bxx` or BIOS handler page | 256 bytes of real Z-80 code calling BIOS routines (`$FE81`, `$FB45`, `$FD80`). Not in first LOAD_CPM staging. |
| B | Possibly read | — | Trap markers |
| C-F | Possibly read | — | Mixed code/markers |

Track 3 onward is the CP/M filesystem (directory entries with file
names like `CAT`, `STAT`, `DUMP`, `CP/M`). Not part of the boot
pipeline.

## After the CPU switch

The 6502 has finished its loader work. It runs a 24-byte loop at
Apple `$03C0-$03DC` perpetually:

```
$03C0: LDA $C083; LDA $C083; STA $FFFF; LDA $C081
$03CC: JSR $0E36           ← CPU-switch trigger
$03CF: JSR $FF58
$03D2: STA $C081; SEI; JSR $FF4A
$03D9: JMP $03C0
```

The Z-80 sees the same physical bytes via SoftCard's memory mapping:

- Apple `$1000-$1FFF` ↔ Z-80 `$0000-$0FFF` (bit-12 XOR for low addresses)
- Apple `$0000-$0FFF` ↔ Z-80 `$1000-$1FFF`
- Apple `$2000-$BFFF` ↔ Z-80 `$2000-$BFFF` (no swap)
- Apple `$D000-$FFFF` LC RAM ↔ Z-80 `$D000-$FFFF` (high addresses; LC RAM is the storage)

Z-80 starts at its reset vector `$0000` (= Apple `$1000`), reads
`JP $FA00`, and runs cold-boot.

## What's still open in the sector map

- The exact sector range and destination of the second LOAD_CPM call.
- Whether the SoftCard's high-RAM ($D000-$FFFF) gets populated
  separately from the first LOAD_CPM (probably yes, via the second
  call into LC RAM with `LDA $C083` enabling LC writes).
- The exact mechanism by which the runtime-generated trap-marker pages
  get filled — whether it's a Z-80-side cold-boot pass that reads more
  disk sectors, the second LOAD_CPM call, or both.

---

This document is the byte-and-sector reference companion to the
[cpm-videx article series](https://wiseowl.com/projects/cpm-videx).
For the architectural narrative, follow the articles in published
order. For the discovery process with dead ends, see the dev logs.
For the boot-loader 6502 disassembly itself, see
[`docs/CPM_BootLoader.md`](./CPM_BootLoader.md) and
[`docs/CPM223_BootLoader.asm`](./CPM223_BootLoader.asm) in the
same repository.
