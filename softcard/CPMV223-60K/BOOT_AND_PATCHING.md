# How the 60K SoftCard CP/M system comes up — and every byte it patches on the way

This document describes the dynamic behaviour the checked-in sources deliberately
do **not** capture. The `os/*.asm` / `os/*.s` files are the **as-shipped** code —
exactly the bytes on `CPMV223-60K.DSK` and inside `CPM60.COM`. As the system
installs and boots, it *modifies* a small set of those bytes in place. Each such
spot is left as-shipped in the source (with a meaningful label and a pointer to
this file); the *what / why* of the change lives here.

Everything below is grounded in the actual installer (`CPM60_installer.asm`) and
6502 boot loader (`os/CPM_BootLoader.s`) instructions; addresses are cited. Where
a writer could not be located it says so rather than guess.

---

## 0. Why any of this exists

The 60K conversion has exactly one goal: a bigger Transient Program Area. The
resident CP/M system (CCP + BDOS) moves **+$4000 higher**, out of main RAM and up
into the Apple **Language Card** (`$D000-$FFFF`). The page-zero proof: the BDOS
`JP` at `$0005` goes `$9C06 → $DC06` and the top-of-TPA word at `$0006` goes
`$9C06 → $DC06` — both exactly +$4000 — while the BIOS warm-boot `JP` at `$0000`
stays `$FA03`. That frees the 16 KB the system used to occupy low in RAM, so the
TPA (`$0100`..BDOS−1) grows from ~39 KB (`$0100-$9C05`) to ~55 KB (`$0100-$DC05`).
The filesystem (tracks 3+) is untouched; only the boot tracks and the OS pieces
differ from the 44K disk.

SoftCard window map (Z-80 → Apple): `$B000-$DFFF` → Apple `$D000-$FFFF` (+$2000,
the 16 KB LC); `$E000-$EFFF` → Apple `$C000-$CFFF` (−$2000, the I/O page, so Z-80
`$E08B`/`$E083` hit Apple `$C08B`/`$C083`). So the LC bank soft-switches are
reachable from the Z-80 as `$E08x`.

---

## 1. Install path — `CPM60.COM` writing the system to disk (once, under the 44K system)

`CPM60.COM` is 11,264 bytes: the first 608 (ORG `$0100`) are the Z-80 installer
driver; the rest is the embedded 60K system image.

1. **Validate entirely through BDOS first** (`CPM60_installer.asm $0100-$012F`):
   fn `$20`/`$1F` get-user, fn `$19` get-disk (or the explicit FCB drive byte,
   stashed as `drive & 3` in `$F3E4`), fn `$0E` select, fn `$13` delete a stale
   `CP/M.SYS`, fn `$1B` read the DPB + a geometry sanity check, fn `$16` make
   `cp/m    sys` (proves the disk is writable **and** reserves a directory
   entry), fill the FCB alloc map with blocks `$80-$8B`, fn `$10` close.
2. **Raw-write the embedded image** (`$0168-$0197`): set `$F3EB`=2 (sector count),
   `$F3E9`=`$14` (track 20), `B`=`$30` (48 pages), source page in `H`. Each pass
   pokes `$F3E0`, loads `HL`=`$0E03` (page `$0E`, function `$03` = write), and
   calls `SUB_01F9`: `LD ($F3D0),HL ; LD HL,($F3DE) ; LD (HL),A` — it writes the
   opcode byte through the live RPC trampoline pointer (`$F3DE`), which lands on
   a `$C700`/`$E700` slot access that fires the 6502 RWTS. After each unit it
   reads `$F3EA`: `$10` → "Disk write protected", other nonzero → "Disk I/O
   error". This is the **same path** as the in-system CCP sysgen (`CPM_CCP.asm`
   `$DB06`) and BIOS `RPC_DISPATCH` (`$FB45`) — the installer is a stand-alone
   clone. **Skew:** the installer feeds 512-byte records in plain logical order;
   the 60K BIOS deblock applies the `(L*3)%16` physical sector skew as they land.
3. **Hand off** (`$0210-$0216`): plant `$C777` at `$000B`, set `$F3D0`=`$C600`
   (slot-6 Disk II boot ROM), `JP $000B` — fire the 6502 cold-boot relocator.

---

## 2. Boot path — the 6502 loader relocating the system into the Language Card (every boot)

`os/CPM_BootLoader.s` (ORG `$0800`, also covering the `$1000` relocator) reads the
system tracks into main RAM, prints the banner, and probes for the Z-80 card
("FIND Z80 SOFTCARD" / "MUST BOOT FROM SLOT SIX" at `$11A7`/`$11C9`). Then
`RELOC_SYS_TO_LC` (`$10FE-$117A`):

| Step | Code | What |
|---|---|---|
| (a) Reset-plant | `$10FC` STA `$1000` #`$C3` / `$1101` STA `$1001` #`$00` / `$1106` STA `$1002` #`$FA` | writes `C3 00 FA` = Z-80 `JP $FA00` into the Z-80 base page, so the Z-80 cold-starts in the BIOS |
| (b) Bank in LC | `$110D` STA `$C08B` | select LC bank-1 read/write-enable (so the relocator can write into the card) |
| (c) Copy +$4000 | `COPY_PAGES` `$1187`, four moves | copy the resident system up into the LC and build the low mirror (below) |
| (d) Patch in-LC RWTS | `$1128` STA `$D216` / `$1131` STA `$D549` / `$1134` STA `$D548` | fix the relocated RWTS's own addresses |
| (e) Hand off | `$117A` JMP `$03C0` | enter the CPU-switch glue, which flips control to the Z-80 |

The four `COPY_PAGES` moves: `$0A00→$D000` (6 pp, RWTS into the LC), `$9800→$0A00`
(6 pp), `$8D00→$D5C0` (11 pp), and **`$8000→$F300` (13 pp) — the +$4000 move of the
resident system**: Apple `$F300`==Z-80 `$D300` (CCP) and Apple `$FC00`==Z-80
`$DC00` (BDOS) fall inside it. The split BDOS's lower half is also made visible at
Z-80 `$B000-$C0BF` (Apple `$D000-$E0BF`) — the "low mirror" — from the first/third
copies. (The exact page-to-mirror mapping is taken from `CPM60_COM.md §6`, not
re-traced byte-by-byte here.)

The handoff glue at `$03C0` (== InstallFragments `$0DC0`): `LDA $C083 x2` (LC
bank-2 read), `LDA $C081`, `JSR`, `STA $C081`, `SEI`, `JSR`, then the slot access
that starts the Z-80. The Z-80 powers up at `$0000` → `JP $FA00` → BIOS cold start,
now with CCP at `$D300` and BDOS at `$DC00` in the Language Card.

---

## 3. The patch catalogue — every modified byte, what / why

### 3a. Boot-loader self-patches (6502, applied during relocation)

| Addr | As-shipped | Becomes | Who / why |
|---|---|---|---|
| `$1000-$1002` | live 6502 read-loop code (`LDA $C081`×2; TXA; LSR×4; TAY; PHA; STA $C088,X) | `C3 00 FA` = `JP $FA00` | reset-plant (a) — arm the Z-80 cold-start vector |
| `$1069` | `$C0` (operand-high of `STA $C000`, placeholder) | `$C7` → `STA $C700` | `$1064` `STY $1069` (Y=`$C7` from `$1060` `LDY #$C7`) — point the CPU-switch store at the real slot soft switch |
| `$1176` | `$98` (TYA placeholder) before operand `D2 03` | `$4C` → `JMP $03D2` | `$1146` `STA $1176` (value `($8900)+$8F` = `$BD+$8F` = `$4C`) — arm the jump into the handoff glue |

### 3b. InstallFragments — the unrelocated CPU-switch handoff template (`$03B8-$03EB`)

The card slot isn't known at assembly, so these address/parameter cells ship as
placeholders and the relocator fills them in place:

| Addr | As-shipped | Becomes | Who / why |
|---|---|---|---|
| `$03C7-C8` | `FF FF` → `STA $FFFF` | `00 C7` → `STA $C700` | `$108D` STA `$03C7` (#`$00`) / `$1088` STY `$03C8` (Y=`$C7`) — the live slot CPU-switch store |
| `$03DE-DF` | `00 00` → `JSR $0000` | `00 E7` → `JSR $E700` | `$1090`/`$1097` — Apple `$C700` seen through the Z-80 `$E0xx` I/O window (`$C7`+`$20`) |
| `$03B8` | `00` | `02` | `$1058` STY / `$10BA` INC / `$10D7` ASL — a table-walk index parameter |
| `$03BD-BE` | `00 00` | `00 02` (`$0200`=`IN`) | self-reference filled at relocation (writer not located in the decoded region) |
| `$03BB`, `$03E0-E1`, `$03E3-E6`, `$03E9`, `$03EB` | `00` | misc params | relocation/sysgen parameter cells — **exact 6502 writers not located** (see Open questions) |

### 3c. BIOS cold-boot **self-modifications** (Z-80, run once at `$FA00` cold start)

Crucial correction: these are **not** patched by the 6502 loader. The loader only
*copies* the BIOS. The Z-80 BIOS cold-boot routine `BIOS_BOOT` (`$FEEA`,
`LD SP,$0100 / XOR A / LD HL,$FA00 / LD (HL),A …`) runs exactly once and rewrites
its own image:

| Addr | As-shipped | Becomes | Who / why |
|---|---|---|---|
| `$FA00-$FA02` | `C3 EA FE` = `JP BIOS_BOOT` (cold entry) | `00 00 00` (NOP) | `BIOS_BOOT` zeroes `$FA00` (`LD HL,$FA00 / LD (HL),A`×3). On 60K, cold start is driven from the reset-plant; the warm-boot `$FA03` vector is the live entry thereafter |
| `$FB37-38` | console-input vector placeholder | resolved handler (`$FDB7`) | `$FF34` `LD (L_FB37),HL` — bind CONIN to the installed card type (from the `$F3B8` slot-info device byte) |
| `$FCB9-BA` | console-output vector placeholder | resolved handler (`$FDA9`) | `$FF2E` `LD (L_FCB9),HL` — bind CONOUT to the installed card |
| `$FB4A` | `00` (hi byte of `LD ($0000),A` in `RPC_DISPATCH`) | `E7` → `$E700` | `$FEFE` `LD (RPC_DISPATCH_1+1),HL`, HL=`($F3DE)` — bind the RPC store to `$E700` (Apple `$C700`), the live 6502↔Z-80 trampoline |
| `$FB05` | `01` (operand of `LD A,$01` at WBOOT) | `03` | `$FF39` `LD (BIOS_WBOOT_3+1),A` (A=`$03`) — warm-boot CCP-reload count, set once the device set is known |
| `$FE72-74` | `C3 00 00` (unfilled JP) | `3E 1A C9` = `LD A,$1A / RET` | `$FF67`/`$FF6C` when a logical device has no card — install a benign EOF stub |

After it runs, the one-shot cold-boot routine at `$FEEA-$FF8D` (~150 bytes) is dead
and the running system reuses that span as scratch/stack — which is why a captured
booted image shows ~147 bytes of `$E5`/`$FF` fill there. **Those are not patches**;
they are post-boot memory reuse the realmap snapshot happened to catch. (The
earlier "the boot loader patches 185 bytes" framing conflated ~38 real cold-boot
self-mods with ~147 such fill bytes and is retired.)

---

## 4. Steady-state banking architecture (the LC stays callable)

Once up, the resident OS lives in the Language Card and the BDOS manages the bank
on every call. The page-zero `$0005` vector is `JP $DC06` — straight into the LC
BDOS. `BDOS_ENTRY` (`$DC11`) **opens with `LD ($E08B),A`** — select LC read-RAM
**bank 1** — does its work, and its exit selects **bank 2** (`$C083`). Both are
read-RAM modes; the switch is between the BDOS's split upper (`$DCxx`) and lower
(`$Bxxx`/Apple `$Dxxx`, double-banked) halves. So control entering the OS re-asserts
the OS's bank before running and restores the caller's on exit — there is no
separate stub layer, the BDOS does it itself. (The system relies on the LC staying
in read-RAM mode during normal operation; recovery from a disturbed card is via the
BIOS warm-boot path at `$0000` → `$FA03`, which re-establishes everything.)

---

## 5. Order of operations

**Install (once, under 44K):** validate via BDOS + reserve `CP/M.SYS` → raw-write
the 48-page image to track 0 + system tracks via the `$0E03` RPC loop (BIOS deblock
applies the skew) → plant `$C777`/`$F3D0`=`$C600`, `JP $000B` to fire the relocator.

**Every boot:** 6502 boot1 reads the system tracks + probes the Z-80 card →
reset-plant `JP $FA00` at Z-80 `$0000` → `STA $C08B` bank the LC in → four
`COPY_PAGES` moves (+$4000 into the LC, build the low mirror) → patch the in-LC
RWTS (`$D216`/`$D548`/`$D549`) → CPU-switch glue at `$03C0` flips to the Z-80 →
Z-80 resets to `$0000` → `JP $FA00` → BIOS cold start (runs once, self-modifies as
in §3c) → thereafter the BDOS banks the LC per call. Net: CCP+BDOS resident in the
LC, BIOS at `$FA00`, TPA grown +$4000.

---

## Open questions (not yet traced)

* The exact 6502 store instructions that fill InstallFragments `$03BB`, `$03BD-BE`,
  `$03E0-E1`, `$03E3-E6`, `$03E9`, `$03EB` are not present in the decoded
  `$0800`/`$1000` boot-loader region. Candidates: a not-yet-decoded relocator path,
  the standalone RWTS block, or sysgen-time fills.
* Whether the `$1003-$100D` running bytes our source had captured were window
  content vs. anything functional — concluded to be a capture artifact (no writer);
  reverted to the as-shipped 6502 read-loop code.
* The remaining BIOS cold-boot self-mods beyond the ~6 catalogued above (e.g.
  `$FA35`→`$19` DPH scratch) are runtime drive/console state, written on first
  SELDSK / console use; individual stores not all traced.
