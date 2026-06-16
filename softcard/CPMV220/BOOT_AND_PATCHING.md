# CPMV220 — Boot, Load, and Runtime Setup

How the 2.20 SoftCard CP/M system comes up, and which bytes the running system
builds that are **not** in the as-shipped source. The `os/` sources are the
as-shipped, on-disk code; this document holds the boot-time behavior so it does
not have to be baked into the sources. The structure parallels
[the 2.23 boot](../CPMV223-44K/BOOT_AND_PATCHING.md); the differences from 2.23
are called out.

The disk is a standard 16-sector Apple II floppy. Tracks 0-2 are the reserved
system area (the boot loader + the staged CP/M system); tracks 3+ are the CP/M
filesystem (the 11 `.COM` + data files in `utilities/`).

## 1. Boot, in three stages

1. **Disk II P6 boot ROM** reads track 0 sector 0 to `$0800` and jumps in.
2. **6502 boot loader** (`os/CPM_BootLoader.s`, runs `$0800`) pulls in the
   **RWTS** (`os/CPM_RWTS.s`) and **install fragments**
   (`os/CPM_InstallFragments.s`), then runs `LOAD_CPM`, the staged-system read off
   tracks 0-2 that lands the Z-80 system into low memory:

   | staging offset | bytes | source (`os/`) | what it is |
   |---|---|---|---|
   | `$0000-$16FF` | `$1700` | `CPM_SystemImage.asm` | CCP + BDOS |
   | `$1700-$1BFF` | `$0500` | `CPM_BIOS.asm` | the pristine on-disk BIOS, landed at `$DA00-$DEFF` |

   Unlike 2.23, 2.20 has **no `DiskCallbacks` region** — the 2.20 `LOAD_CPM` reads
   28 sectors (vs 2.23's 29), one short, with the BIOS staged directly after the
   system image.
3. **CPU switch + Z-80 cold boot.** The loader arms the SoftCard CPU switch and
   the Z-80 enters the BIOS, which runs the cold-boot generator.

## 2. The BIOS: as-shipped `$DA00-$DEFF` vs the resident BIOS

`os/CPM_BIOS.asm` is exactly the 1280 bytes on disk (`$DA00-$DEFF`), loaded as
read. The resident BIOS is larger (the captured runtime image `bios_220.bin` is
`$0800`, `$DA00-$E1FF`): the on-disk cold-boot code **builds a device/console
tail in RAM above `$DEFF`** — it is not on disk. The BIOS jump table already
points into that tail, so the tail must be populated before any BIOS call is
serviced.

The cold-boot generator scans the Apple slots and installs the matching console
handlers. **This is the key 2.20 ⇄ 2.23 difference:** 2.20's generator has **no
Videx/Pascal-1.1 (device-2/Videoterm) path** — that console support is exactly
what 2.23 adds. The routine-level delta is in
[`../docs/CPM_Videx_Difference.md`](../docs/CPM_Videx_Difference.md); the
`version_delta` tool traces both variants' cold-boot dispatch from their runtime
BIOS binaries (`bios_220.bin` / `bios_223.bin`), which is why those binaries, not
these sources, drive that comparison.

## 3. Page-zero and vectors

Cold boot also plants the standard CP/M page-zero cells (not part of the BIOS
image): `JP WBOOT` at `$0000`, the `JP BDOS` vector at `$0005-$0007`, and
re-issues `SETDMA($0080)`.

## 4. `cp/m.sys` — the hidden block reservation

Like every SoftCard CP/M disk, 2.20 carries a directory entry `cp/m.sys` at
**user `$1F`** (31) — outside the normal user range, so no ordinary `DIR` shows
it. It reserves data-area blocks so the CP/M allocator does not reuse them. (On
the 2.23 disk this is the mechanism `CPM60.COM` uses to protect the embedded 60K
system; see [`../CPMV223-60K/CPM60_COM.md`](../CPMV223-60K/CPM60_COM.md).)
