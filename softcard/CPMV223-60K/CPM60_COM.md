# CPM60.COM — Definitive Decompilation Reference

## 1. Overview

`CPM60.COM` is the **Softcard CP/M 60K CP/M Disk update program, (C) 1982 Microsoft** — an in-place disk upgrader for the Apple/Microsoft SoftCard. It runs as an ordinary CP/M utility in the TPA under an existing 44K SoftCard CP/M system, and rewrites a target boot disk's system tracks so that the disk subsequently boots as a 60K (Language-Card) system.

- **File size:** 11,264 bytes (0x2C00).
- **Form:** A self-contained CP/M `.COM` whose first 608 bytes are the Z-80 installer driver (ORG `$0100`); the remaining bytes are the embedded system image (6502 boot/relocation machinery plus the Z-80 CCP/BDOS/BIOS payloads) that the driver writes onto the disk.
- **What it does, in one line:** validates the target disk through BDOS, reserves directory space via a placeholder file `CP/M.SYS`, then writes the embedded 60K system image directly to track 0 and the system tracks using the in-system RWTS-bridge primitive (not BDOS file writes), and finally hands off to the 6502 cold-boot relocator.

The 60K layout it installs moves the CCP and BDOS up into the 16K Language Card so the TPA (Z-80 `$0000-$AFFF`) grows to roughly 60K. Only the **CCP** is a pure relocation; the **BDOS** and **BIOS** are also *modified* to bank and span the Language Card (see §5 and §7).

## 2. Byte Map (all 11,264 bytes accounted for)

The SoftCard window translation used throughout (Z-80 address vs. Apple address):
- Z-80 `$B000-$DFFF` == Apple `$D000-$FFFF` (Apple = Z80 + `$2000`, the 16K Language Card)
- Z-80 `$E000-$EFFF` == Apple `$C000-$CFFF` (Apple = Z80 − `$2000`, the I/O page; so Z-80 `$E08B`/`$E083` hit Apple `$C08B`/`$C083`)
- Z-80 `$F000-$FFFF` == Apple `$F000-$FFFF` (identity)
- Z-80 `$0000-$AFFF` == Apple `$0000-$AFFF` (identity, the TPA)

| COM offset range | CPU | Component | Target ORG (load address) | Role |
|---|---|---|---|---|
| `0x000-0x10C` | Z-80 | Installer driver code | `$0100` | Drive select, BDOS validation, RPC system-track write loop, 6502 handoff |
| `0x10D-0x111` | Z-80 | `PRINT_STR` helper | `$020D` | BDOS fn `$09` trampoline |
| `0x112-0x252` | Z-80 (data) | User-facing `$`-strings | `$0212` | Banner, prompts, 4 error messages |
| `0x253-0x254` | data | Trailer | `$0353` | `0D 0A 24 00` |
| `0x255-0x260` | data | FCB template | `$0355` | `00 'cp/m    ' 'sys'` — placeholder file `CP/M.SYS` (the `'s'` of `sys` is the installer's last byte, file `0x260`) |
| `0x261-0x2FF` | — | Zero pad | — | Unused gap to next region |
| `0x300-0x3FF` | 6502 | BootLoader install/denibble-prep page | `$0800` | Install/denibble-prep, Microsoft signon fragments, 6-and-2 postnibble loop at `$0885` (byte-identical, ca65/ld65 verified) |
| `0x400-0x9BC` | 6502 | RWTS Disk II driver (STANDALONE) | `~$0400` (helpers at `$D000-$D3xx`) | Disk II read/write/seek; head `38 86 27 8E 78 06`; `D5 AA AD` prologue; `C08C`/`C08D,X` switches; `D369` table. Not present in any of the three OS sources |
| `0x9BD-0x9FF` | — | Zero pad | — | Tail of RWTS region |
| `0xA00-0xA0D` | 6502 | Relocator LC-bank/handoff prologue (COM-only) | `$1000` | 14-byte COM-specific Language-Card bank/handoff preamble |
| `0xA0E-0xBF1` | 6502 | BootLoader 1000 relocator + `COPY_PAGES` +`$4000` LC mover | `$1000` | `FIND Z80 SOFTCARD`/`MUST BOOT FROM SLOT SIX`; reset-plant; the four page copies into the LC (byte-identical to mem `$100E-$11F1`) |
| `0xBF2-0xD7F` | — | Zero gap | — | BootLoader `$11F9-$137F` fill |
| `0xD80-0xDA1` | 6502 (data) | BIOS address/patch table | `$0380` (InstallFragments) | Duplicated LE source/dest word pairs `FB14 FB33 FCB5 FE6F FE69 FE55` |
| `0xDA2-0xDB7` | 6502 (data) | Aux keymap table | `$03A2` (InstallFragments) | Auxiliary keymap, ends `FF FF FF FF` |
| `0xDB8-0xDBF` | — | Zeros | — | Gap |
| `0xDC0-0xDDB` | 6502 | 6502-to-Z80 CPU-switch handoff glue | `$03C0` (InstallFragments) | `LDA C083 x2; STA FFFF` (template, runtime-patched to `STA C700`); `LDA C081`; `JSR 0E3F`; `JSR FF58`; `STA C081`; `SEI`; `JSR FF4A`; `JMP 03C0` |
| `0xDDC-0xDEF` | — | Unrelocated template/zero bytes | — | Template remnants |
| `0xDF0-0xDFF` | 6502 (data) | Jump-vector tail | `$03F0` (InstallFragments) | Vector tail to `$03C0` |
| `0xE00-0x1670` | Z-80 | CCP payload | `$D300` (== Apple `$F300`) | CP/M CCP; head `c3 0c d6` (`JP $D60C`) |
| `0x1671-0x16FF` | — | Pad | — | Gap to BDOS payload |
| `0x1700-0x24FF` | Z-80 | BDOS payload (60K, modified) | `$DC00` (== Apple `$FC00`), split-mirrored to `$B000-$C0BF` | CP/M 2.2 BDOS (`0xE00` bytes) with LC bank-switch insertions; head `bd 16 00`, entry `JP $DC11`. Its first 6 bytes (`bd 16 00 01 4d 40`) are the serial shared with the CCP's tail at `0x1700-0x1705` |
| `0x2500-0x25FF` | — | Pad | — | Gap to BIOS payload |
| `0x2600-0x2BFF` | Z-80 | BIOS payload | `$FA00` (== Apple `$FA00`, identity band) | 60K BIOS; jump table `c3 ea fe`/`c3 b8 fa`; RWTS bridge + RPC dispatch. RWTS.s window reconstructs to an exact 1536-byte match here |

Every byte in `0x300-0xDFF` is classified as code, table, string, or zero-pad, with zero unclassified nonzero bytes. The Z-80 payload heads (`c3 0c d6` @ `0xE00`, `bd 16 00` @ `0x1700`, `c3 ea fe` @ `0x2600`) all match the established region map.

### Single-source reassembly

The whole file rebuilds byte-for-byte from one master assembler source, [`CPM60.asm`](CPM60.asm). It places each piece at its `.COM` offset, `INCBIN`s the three 6502 pieces (boot loader / RWTS / install fragments, ca65) at their slices, and assembles the relocating Z-80 modules (`CCP`→`$D300`, `BDOS`→`$DC00`, `BIOS`→`$FA00`) as **real code at their run address** via `DISP … ENT` — the same technique GBASIC.COM's interpreter uses — so their labels resolve correctly while the bytes stay at the `.COM` offset. Each Z-80 module is `INCLUDE`d from its canonical source (wrapped in a `MODULE`, with `DEVICE`/`ORG`/`SAVEBIN` bracketed behind `IFNDEF CPM60_LINK` so it still assembles standalone). The CCP/BDOS file regions overlap by 6 bytes (`0x1700-0x1705`) — the shared `BD160001 4D40` serial that ends the CCP and begins the BDOS — and the gaps are `$00`. The pipeline build is `cpm_pipeline.build_cpm60.build_cpm60_com()`; `build_cpm60_com_via_layout()` is an independent component-concat cross-check, and both equal the genuine file on `CPMV223-44K.DSK`.

## 3. The Installer Driver

The driver occupies file `0x000-0x260` (609 bytes, `$0261`, ORG `$0100`) and reassembles via sjasmplus to exactly `CPM60.COM[0x000:0x261]` with zero diffs. It is a stand-alone clone of the in-system sysgen / disk-write path: it pokes the same `$F3Dx`/`$F3Ex` bridge variables and uses the same `$0E03` RPC opcode as `CPM_CCP.asm SUB_DB06` (`$DB06`, the CCP sysgen path) and `BIOS RPC_DISPATCH` (`$FB45`, `LD ($E700),A`).

Step by step:

1. **Select target drive.** Pick the drive from the command-line FCB drive byte, or the current disk if none was given (BDOS fn `$19` get-current-disk; fn `$20` get-user with E=`$1F`). Stash `drive & 3` in the 6502-RWTS bridge variable `$F3E4`.

2. **Validate the disk entirely through BDOS, before any raw write:**
   - fn `$0E` select-disk
   - fn `$13` delete-file — remove any stale `CP/M.SYS` placeholder
   - fn `$1B` get-alloc/DPB — returns `HL` → DPB; sanity-check two geometry bytes at DPB+`$10`
   - fn `$16` make-file on `"cp/m    sys"` (FCB at `$0355`) — both proves the disk is writable and reserves directory space. A `$FF` failure prints `"Disk space already in use"`.

3. **Commit the directory entry.** Fill the new file's allocation map with 12 blocks `$80-$8B`, set the record/extent fields, and CLOSE the file (fn `$10`).

4. **Prompt the operator.** Build drive-letter glyphs (the `'Z'` at `$0284` is patched to the real drive letter), print the banner / `"Insert 16 sector disk into drive Z: Press RETURN to begin"`, and wait for a key via direct console I/O (fn `$06`, E=`$FF` polled).

5. **Write the embedded system to the system tracks — NOT via BDOS file writes.** It pokes the 60K BIOS's own RWTS-bridge variables in high RAM:
   - `$F3E0` = sector
   - `$F3E9` = track (`$14`)
   - `$F3EB` = sector count (2)
   - status read back from `$F3EA`

   and issues a 6502 "RPC": `SUB_01F9` stores the parameter word to `$F3D0`, then writes an opcode byte through the live trampoline pointer `($F3DE)` — `LD ($F3D0),HL ; LD HL,($F3DE) ; LD (HL),A` — which lands on a `$C700`/`$E700` slot access that runs the 6502 RWTS. The **write loop at `$0196`** runs `B=$30` (48) source pages starting at the `$0E00` payload page, opcode word `$0E03` (`$0E` page, fn `$03` = write). After each unit it reads `$F3EA`: status `$10` → `"Disk write protected"`; any other nonzero → `"Disk I/O error"`. The BIOS deblock applies the `(L*3)%16` sector skew when landing the logical records on physical system-track sectors; the installer feeds records in logical order.

6. **Hand off to the 6502 cold-boot relocator.** On success, print `"Disk has been updated to 60K"` and `"Press RETURN to re-boot system"`, then plant the `$C777` RPC vector at `$000B`, set `$F3D0=$C600` (slot-6 Disk II boot ROM entry), load `HL=($F3DE)`, and `JP $000B` — firing the 6502 cold-boot relocator to boot the freshly written 60K system.

**User-facing strings (`$0212-$0334`):** banner; `"Insert 16 sector disk into drive Z:"`; `"Press RETURN to begin"`; `"Disk has been updated to 60K"`; `"Press RETURN to re-boot system"`; and the four error messages `"Disk I/O error"`, `"Disk write protected"`, `"Disk space already in use"`, `"Not enough directory space"`.

## 4. The Embedded Payload

The `.COM` carries the complete bootable 60K system image. It splits into a 6502 (Apple-side) half and a Z-80 (CP/M) half.

**6502 boot/relocation machinery (`0x300-0xDFF`):**
- `0x300-0x3FF` — BootLoader `$0800` page (install/denibble-prep, Microsoft signon fragments, 6-and-2 postnibble loop). **Byte-identical** to `os/CPM_BootLoader.s` (ca65/ld65 round-trip, 256/256).
- `0x400-0x9BC` — RWTS Disk II driver. **STANDALONE** — not present in any of the three provided OS sources.
- `0xA00-0xBF1` — BootLoader `$1000` relocator. The first 14 bytes (`0xA00-0xA0D`) are a COM-specific LC-bank/handoff prologue; from mem `$100E` (== COM `0xA0E`) onward it is **byte-identical** to BootLoader mem `$100E-$11F1`.
- `0xD80-0xDFF` — InstallFragments tail: BIOS address/patch table, aux keymap table, and the 6502-to-Z80 CPU-switch handoff glue. The COM holds the **unrelocated** template (`STA FFFF`), not the runtime-patched `STA C700` (`8D 00 C7`).

A correction surfaced during this work: the source `CPM_RWTS.s` is **mislabeled** — its window `$0A00-$0FFF` is actually the Z-80 BIOS image (`C3 EA FE` jump table) and reconstructs to an exact 1536-byte match at COM `0x2600`. The real RWTS is the unrelated standalone block at COM `0x400-0x9BC`.

**Z-80 CP/M payloads:**
- **CCP** (`0xE00-0x1670`, ORG `$D300`, head `c3 0c d6`) — matches the established `os/` region map; placed at Apple `$F300`.
- **BDOS** (`0x1700-0x24FE`, ORG `$DC00`, head `bd 16 00`, entry `JP $DC11`) — the 60K BDOS. **No 60K BDOS source previously existed; it was newly recovered here.** Byte-identical reassembly confirmed (3584 bytes, want == got).
- **BIOS** (`0x2600-0x2BFF`, ORG `$FA00`, jump table `c3 ea fe`/`c3 b8 fa`) — matches the established region map; placed at Apple `$FA00` (identity band).

## 5. The 60K BDOS

The 60K BDOS is the **same CP/M 2.2 BDOS** as the 44K system — the serial number is unchanged, the `CP 29h` function-range guard is identical, and dispatch is the same table-indexed `JP (HL)`. The entry `JP DC11h` mirrors the 44K `JP 9C11h`. Byte-identical reassembly was confirmed (3584 bytes). This source fills a gap: no 60K BDOS source existed before; the 44K reference (`sysimg_223` offset `0xD00`, running `$9C00`) is now cross-checked against it.

What is **MODIFIED** relative to the 44K BDOS are the Language-Card bank-switch insertions and the resulting split-across-LC layout:

**LC bank-switch insertions — 13 accesses, all writes, no ROM read modes** (`E081h`/`E089h` absent):
- 5 writes to `E08Bh` (Apple `C08Bh`, LC bank-1)
- 8 writes to `E083h` (Apple `C083h`, LC bank-2)
- Full address list: `DC11h DC3Fh DD5Bh DD64h DF1Ch DF20h DF28h DF36h DF3Ch DF41h DF45h DF63h DF81h`

**Entry/exit envelope:**
- `DC11h` banks the LC in.
- `DC36h` pushes the `DF45h` return address.
- The epilogue at `DF45h` banks the LC out on every exit.
- `DC3Fh` selects bank-2 for functions below 12.

**Split layout (the proven dispatch difference vs. 44K):** the 41-entry dispatch table at `DC53h` is split across the Language Card:
- 11 functions in the upper LC (`DCxx-DFxx`, Apple `FCxx-FFxx`)
- 27 functions in the lower LC (`Bxxx`, Apple `Dxxx`)
- 3 entries to the BIOS (`FA03h FA0Fh FA12h`)

**Scratch/stack relocation:** BDOS scratch variables are relocated to `BFxx` (Apple `DFxx`) — about 130 references; the private stack at `DF0Fh` is set at `DC26h`.

**Preamble delta vs. 44K:** the 44K BDOS opens `EX DE,HL` then `LD 9F43h,HL` in flat RAM with no soft switches. The 60K BDOS prepends a write to `E08Bh` (bank LC in), saves DE to `DF11h` and mirrors it to `BFE3h`, wrapping the call in a bank-in / bank-out pair.

## 6. The Relocation / Banking Mechanism

There are two phases: install-time (this `.COM`) and boot-time (the next cold boot of the written disk).

**Install-time data flow.** The Z-80 installer driver at `$0100` writes the embedded image — 6502 boot/relocator (`0xA00`) + RWTS (`0x400`) + CCP (`0xE00`) + BDOS (`0x1700`) + BIOS (`0x2600`) — onto track 0 plus the system tracks. It does this not through BDOS file writes but by driving the 60K BIOS RWTS-bridge variables (`$F3D0`/`$F3DE`/`$F3E0`/`$F3E9`/`$F3EA`/`$F3EB`) via the `$0E03` RPC opcode in the 48-record loop at `$0191`/`$0196`. The BIOS deblock applies the `(L*3)%16` sector skew as records land on physical sectors.

**Boot-time data flow.** On the next cold boot the 6502 boot loader runs (source `os/CPM_BootLoader.s`, ORG `$0800`, byte-identical to COM `0xA00`):
- Boot1 does `LDA $C081 x2`, resets text/video/keyboard, prints the banner, and probes for the Z-80 card (`"FIND Z80 SOFTCARD"` / `"MUST BOOT FROM SLOT SIX"` at `$11A7`).
- `RELOC_SYS_TO_LC` (BootLoader `$1100`):
  - **(a) Plant the Z-80 reset.** `STA $1000 #$C3 / STA $1001 #$00 / STA $1002 #$FA` writes `JP $FA00` into the Z-80 base page `$0000-$0002`, so the Z-80 cold-starts in the BIOS. (Reset-plant code sits at COM `0xAFC-0xB0B`.)
  - **(b) Enable the LC for writing.** `STA $C08B` selects bank-1 read/write.
  - **(c) Run four `COPY_PAGES` block moves** (`$1187`, src `$53:$52` → dst `$51:$50`), self-modifying `$1176` (`LDA $8900`/`ADC #$8F`) and patching the in-LC RWTS at `$D216`/`$D548`/`$D549`:
    - COPY#1: Apple `$0A00` → `$D000` (6 pages)
    - COPY#2: Apple `$9800` → `$0A00` (6 pages)
    - COPY#3: Apple `$8D00` → `$D5C0` (11 pages)
    - COPY#4: Apple `$8000` → `$F300` (13 pages)
  - Finally it lays a 6-byte tail at `$FFF9` and enters the CPU-switch handoff (`$03C0`/`$0DC0`): `LDA $C083 x2` (LC bank-2 read), `STA $C081`, which flips control to the Z-80. The Z-80 powers up at `$0000` → `JP $FA00` → BIOS cold start.

**Final placement** resolves cleanly through the window map:
- CCP: Apple `$F300` == Z-80 `$D300` (COPY#4)
- BDOS: Apple `$FC00` == Z-80 `$DC00` (COPY#4)
- BIOS: Apple `$FA00` == Z-80 `$FA00` (COPY#4, identity band)
- Plus a **LOW mirror** of the system at Apple `$D000-$E0BF` == Z-80 `$B000-$C0BF` from COPY#1 + COPY#3.

**The BDOS straddle is avoided by design.** The BDOS entry and dispatcher live at Z-80 `$DC00-$DFFF` (Apple `$FC00-$FFFF`), entirely inside the LC window — they never straddle up into the `$E000` I/O page. The 60K BDOS is split, with the part that must live below `$E000` mirrored into the LC low half (`$B000-$C0BF`); the modified dispatch opens `LD ($E08B),A` (bank LC in) before touching data, and no BDOS code or data ever indexes across `$E000` into I/O. The `$E000` I/O window is used only for the deliberate bank-switch stores (`$E08B`/`$E083`).

**Why the TPA grows to ~60K:** CCP and BDOS were moved out of low RAM up into the 16K Language Card, so Z-80 `$0000-$AFFF` == Apple `$0000-$AFFF` stays 1:1 as the enlarged TPA.

## 7. Bottom Line for the Shared-Source Question

Mapping each component to whether 44K and 60K can share one source, or whether the 60K variant needs conditional assembly for LC banking/relocation:

- **CCP — pure re-ORG.** The CCP differs only in load address (Apple `$F300` / Z-80 `$D300`). It carries no LC bank-switch logic. A single source assembled at a different ORG produces both variants.

- **BDOS — needs conditional assembly.** Although it is the same CP/M 2.2 BDOS (unchanged serial, same `CP 29h` guard, same table-indexed dispatch), the 60K variant is genuinely modified: 13 LC bank-switch writes (`E08Bh`/`E083h`) inserted around the entry/exit envelope and at specific dispatch points, the dispatch table split across the LC upper/lower halves, ~130 scratch-variable references relocated to `BFxx`, a private stack at `DF0Fh`, and a re-worked preamble. These are conditional insertions, not a re-ORG.

- **BIOS — needs conditional assembly.** It carries the LC/RWTS-bridge and RPC-dispatch machinery (`$E700`/`$C700` switch, `$F3Dx`/`$F3Ex` bridge) intrinsic to the 60K banked system; it is not a simple relocation of the 44K BIOS.

- **Boot loader — needs conditional assembly (60K-specific).** The relocator embeds the LC bank enable (`STA $C08B`), the four `COPY_PAGES` moves into the Language Card, the self-modifying copy setup, the in-LC RWTS patches (`$D216`/`$D548`/`$D549`), and the Z-80 reset-plant (`JP $FA00`). Additionally the COM image carries a 14-byte COM-specific LC-bank prologue (`0xA00-0xA0D`) ahead of the otherwise byte-identical relocator, and the CPU-switch glue ships as an unrelocated template (`STA FFFF`) that is runtime-patched to `STA C700`. This logic exists only to perform the 60K relocation and has no 44K counterpart.

- **RWTS — standalone, shared as-is.** The Disk II driver at COM `0x400-0x9BC` is independent of the banking decision and appears in none of the three OS sources; it is carried verbatim and patched in place by the relocator at boot.

In short: only the **CCP** is a clean re-ORG. The **BDOS**, **BIOS**, and **boot loader** all require conditional assembly to handle the Language-Card banking and the install-time/boot-time relocation; the **RWTS** is a standalone driver shared without change.