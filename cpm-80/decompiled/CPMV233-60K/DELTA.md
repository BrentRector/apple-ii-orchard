# SoftCard CP/M 2.23 — the 44K → 60K delta (what `CPM60.COM` changes)

This tree is the decompilation of the **60K** SoftCard CP/M system (the disk
`CPMV233-60K.DSK`, which is `CPMV233.DSK` after running `CPM60.COM`). It exists to
answer one question: **what does the 60K conversion change, and how does it give a
larger transient program area?**

The short answer: the resident CP/M system (the **CCP and BDOS**) moves **`+$4000`
higher**, out of main RAM and up into the Apple **Language Card** at `$D000+`. That
frees the 16 KB of main RAM the system used to occupy, and the transient program
area (TPA) grows by exactly that 16 KB. The **BIOS does not move** (it stays at
`$FA00`), and the **filesystem is untouched**.

But "moves higher" is the whole story only for the **CCP** (a clean re-ORG). The
**BDOS** is also *patched* to bank the Language Card, and the **BIOS**, though it
stays at `$FA00`, gains the relocation/banking code (it is ~184 bytes longer). The
byte-level evidence is in the per-module sections below.

## Ground truth: the page-zero vectors

CP/M records its resident-system addresses in page zero. Reading them from a booted
image of each disk (Z-80 address space):

| vector | 44K (`CPMV233.DSK`) | 60K (`CPMV233-60K.DSK`) | delta |
|---|---|---|---|
| BDOS entry (`JP` at `$0005`) | `$9C06` | `$DC06` | **+$4000** |
| BIOS warm boot (`JP` at `$0000`) | `$FA03` | `$FA03` | **0 (unchanged)** |
| top of TPA (word at `$0006`) | `$9C06` | `$DC06` | **+$4000** |

The TPA runs `$0100`..(BDOS-1):

* 44K: `$0100`–`$9C05`  ≈ **39 KB**
* 60K: `$0100`–`$DC05`  ≈ **55 KB**

The growth is exactly **`$4000` = 16 KB**, the size of the Apple Language Card. The
"44K"/"60K" are the product names; the relocation moves the system up by one
Language Card's worth of RAM and hands that RAM to the TPA.

## The relocation, verified

Disassembling the **CCP** at its new origin (`$D300`) and comparing it byte-for-byte
to the 44K CCP at `$9300`, aligned at +$4000:

```
CCP  $9300-$9C05  ->  $D300-$DC05 (+$4000):
     2001 identical + 308 relocated-high-byte (operand +$40) + 1 other  =  99% explained
```

That is the signature of a clean **re-ORG**: the same source, re-assembled at a
`$4000`-higher origin, with every absolute-address operand bumped `+$4000`
(high byte `$9x` → `$Dx`). `os/CPM_CCP.asm` is that relocated CCP (byte-identical to
the booted image at `$D300`); it is the 44K CCP we already decompiled, moved up.

The **BDOS** vector relocates the same way (`$9C06` → `$DC06`), but — unlike the
CCP — the BDOS is **not** a clean re-ORG. Comparing the pristine 60K BDOS (carved
from `CPM60.COM`'s embedded payload) against the pristine 44K BDOS (`sysimg_223`),
relocation-aware, the two diverge well beyond operand bumps: the 60K dispatch opens
`LD ($E08B),A` (bank the Language Card in) where the 44K opens `EX DE,HL` /
`LD ($9F43),HL`, Language-Card bank switches (`$E08B`/`$E083`) are woven through the
body, and the module is split across the card (body addresses span both the
lower-LC `$Bxxx` window and `$DCxx`). It is the same CP/M 2.2 BDOS, **modified** to
live in and bank the Language Card — not merely re-assembled higher.

The **BIOS** stays at `$FA00` (it is *not* relocated), but it is **substantially
modified**, not "mostly identical." Byte-for-byte at the same origin, the 60K BIOS
is **~184 bytes longer** and only ~19% identical to the 44K BIOS: it carries the
cold-boot relocation loop and the LC banking. What the two share is the jump-table
skeleton at the top, where the embedded CCP/BDOS base constants are patched
(`9C`→`DC`, `93`→`D3`).

## What does the relocation: the 6502 boot loader

The conversion is carried out on the **6502 side**, by the boot loader. Compared to
the 44K loader, the 60K loader (`os/CPM_BootLoader.s`):

* runs **~45× more instructions** before handing off to the Z-80 (≈2.5 M vs ≈55 K) —
  it is doing the extra work of copying the system into the Language Card;
* contains **~289 bytes of new code** in regions that are all-zero in the 44K loader
  (clustered around `$0905`–`$09FF` and `$11DC`): a packed table at `$0900` plus an
  unpack/relocate loop near `$0885` that writes through the `$3E/$3F` destination
  pointer; and
* enables the Language Card RAM — total `$C080`–`$C08B` soft-switch accesses rise,
  most visibly `$C08B` (bank-1 read+write-enable) going from 1 use to 7.

So the boot path: load the standard system, **bank in the Language Card, copy the
relocated CCP/BDOS up to `$D000+`, and run from there** — leaving the BIOS at
`$FA00` and the lower 16 KB free for programs.

## What does NOT change

* **BIOS** — same code, same `$FA00` origin (it already lives high; it does not need
  to move).
* **Filesystem** — tracks 3+ are byte-for-byte identical between the two disks; only
  the system tracks (0–2) differ.
* **Disk I/O / RWTS** — the same routines, with their absolute operands relocated to
  follow the system and its Language-Card copies.

## Files

| File | Origin | What it is |
|---|---|---|
| `os/CPM_BootLoader.s` | `$0800` | 6502 boot loader (does the LC relocation; the new code) |
| `os/CPM_InstallFragments.s` | `$0200` | 6502 install fragments |
| `os/CPM_CCP.asm` | `$D300` | Z-80 CCP, the 44K CCP re-ORG'd +$4000 into the Language Card |
| `os/CPM_BDOS.asm` | `$DC00` | Z-80 BDOS — the 60K BDOS, recovered from `CPM60.COM`'s payload (byte-identical). Same CP/M 2.2 BDOS, modified for LC banking + split layout |
| `os/CPM_BIOS.asm` | `$FA00` | Z-80 BIOS — the **unpatched template** as shipped in `CPM60.COM` (COM `0x2600`). The 6502 boot loader patches 185 bytes into it at boot (most visibly NOP-ing the `$FA00` cold-boot `JP BIOS_BOOT`); `bios_boot_patches.json` records them and `derive_booted_bios()` reproduces the running image. |
| `bios_boot_patches.json` | — | The 185 boot-loader patches (template → booted) for the BIOS. |
| `os/CPM_RWTS.s` | `$D000` | 6502 Disk II RWTS — the real disk driver, recovered from `CPM60.COM` offset `0x400` (`$D000-$D5BC`, byte-identical). Runs at Apple `$D000` in the Language Card (boot loader copies it there from `$0A00` and patches `$D216/$D548/$D549`). **Fixed:** this file previously held the mislabeled Z-80 BIOS image (`$0A00` = Z-80 `$FA00`), a duplicate of `CPM_BIOS.asm`. |
| `CPM60_installer.asm` | `$0100` | Z-80 installer driver — the `CPM60.COM` `.COM` program that writes the 60K system to disk (byte-identical) |
| `cpm60_com_overlay.json` | — | The 125 COM-specific bytes (bootstrap glue, unrelocated InstallFragments template, CCP install data) that the component build cannot source. |
| `CPM60_COM.md` | — | Full decompilation of `CPM60.COM` (byte map, installer, payload, install/boot mechanism) |

The Z-80 OS sources reassemble byte-identical to the booted 60K image at their
origins — **except `os/CPM_BIOS.asm`, which is the unpatched COM template** (the
booted image is derived via `derive_booted_bios()`). The `CPM60.COM` payload
sources reassemble to the `.COM` file.

`cpm_pipeline.build_cpm60.build_cpm60_com()` reassembles the whole 11,264-byte
`CPM60.COM` from these component sources (99%) plus the documented overlay (1%),
byte-identical to the original — so the BIOS that ships in the COM is the
unpatched template above.

## Method

Both disks were booted in `softcard_emu` (which models the Language Card). The 6502
loader was captured at the 6502→Z-80 handoff (clean execution layout); the resident
Z-80 system was read from the post-boot image through the SoftCard window
(`realmap`) with Language-Card bank 1 mapped at `$D000–$DFFF`. The relocation offset
was confirmed from the page-zero vectors and a byte-level alignment of the CCP.
