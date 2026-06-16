# CPMV223-44K — Boot, Load, and Runtime Setup

How the 44K SoftCard CP/M 2.23 system comes up, and which bytes the running
system builds that are **not** in the as-shipped source. The `os/` sources are
the as-shipped, on-disk code; this document is where the boot-time behavior
lives, so it does not have to be baked into the sources.

The disk is a standard 16-sector Apple II floppy. Tracks 0-2 are the reserved
system area (the boot loader + the staged CP/M system); tracks 3+ are the CP/M
filesystem (the 20 `.COM`/data files in `utilities/`).

## 1. Boot, in three stages

1. **Disk II P6 boot ROM** reads track 0 sector 0 to `$0800` and jumps in — the
   one standard sector. Everything after is the SoftCard's own code.
2. **6502 boot loader** (`os/CPM_BootLoader.s`, runs `$0800`; the `$1000` page is
   the relocator). It pulls in the **RWTS** (`os/CPM_RWTS.s`) and the
   **install fragments** (`os/CPM_InstallFragments.s`), then runs `LOAD_CPM`: a
   29-sector read off tracks 0-2 (phys `0:$B..$F`, `1:$0..$F`, `2:$0..$7`) that
   stages the Z-80 system into low memory:

   | staging offset | bytes | source (`os/`) | what it is |
   |---|---|---|---|
   | `$0000-$16FF` | `$1700` | `CPM_SystemImage.asm` | CCP + BDOS (loaded high into `$9300`/`$9C00`) |
   | `$1700-$18FF` | `$0200` | `CPM_DiskCallbacks.asm` | Z-80 thunks bridging BDOS/BIOS disk I/O to the 6502 RWTS |
   | `$1900-$1CFF` | `$0400` | `CPM_BIOS.asm` | the pristine on-disk BIOS, landed at `$FA00-$FDFF` |

3. **CPU switch + Z-80 cold boot.** The loader arms the SoftCard CPU switch and
   the Z-80 enters the BIOS at `BOOT` (`$FA00`), which runs the cold-boot
   generator described next.

## 2. The BIOS: as-shipped `$FA00-$FDFF` vs the resident `$FA00-$FF47`

`os/CPM_BIOS.asm` is exactly the 1024 bytes on disk (`$FA00-$FDFF`). They are
loaded **verbatim** — there is no in-place self-modification of that region
(byte-for-byte identical to the running image there; verified against the
post-cold-boot snapshot `cpm-investigation/bios_223.bin`).

The resident BIOS is larger (`$FA00-$FF47`, 1352 bytes) because the on-disk
cold-boot code **builds the `$FE00-$FF47` device/console tail in RAM** — it is
not on disk. The 17-entry jump table at `$FA00` already points into that tail
(`HOME_IMPL=$FE6C`, `SETTRK_IMPL=$FE77`, `SELDSK_IMPL=$FE8E`, `READ_IMPL=$FEBD`,
`WRITE_IMPL=$FEC0`, `BOOT_LANDING=$FED1`), so the tail must be populated before
any BIOS call is serviced.

**Who builds it — the slot scan (`SLOT_SCAN`, `$FA82`).** Cold boot walks Apple
slots 7..1, indexing `SLOT_INFO_BASE` (`$F3B8`) by slot to read each card's
device code, and dispatches:

- **device 3** → `INIT_KEYBOARD` (`$FE81`): generic keyboard/console.
- **device 1** → `INIT_PASCAL_1_0` (`$FD83`): Pascal-1.0 firmware card; also pokes
  the `$C800` expansion window via `RPC_DISPATCH`.
- **device 2** → `INIT_PASCAL_1_1` (`$FDB0`): Pascal-1.1-class card (this is the
  **Videx Videoterm** path) using its `$0DD0` / `$C800`-window firmware.

Each init writes the matching console read/write handlers into the `$FE00-$FF47`
tail, so the jump-table targets resolve to the right device. **This is where the
2.20 → 2.23 Videx fix lives** (see `../docs/CPM_Videx_Difference.md`); the
`version_delta` tool traces this dispatch from `bios_223.bin` (the runtime
image, tail included), which is why that binary, not this source, drives the
cold-boot trace.

## 3. Page-zero and vectors

Cold boot also plants the standard CP/M page-zero cells (not part of the BIOS
image): `JP WBOOT` at `$0000`, `JP BDOS_ENTRY` (`$9C06`) at `$0005-$0007`, and
re-issues `SETDMA($0080)`. `WBOOT_IMPL` re-establishes the 6502-side console via
`RPC_DISPATCH`, rescans slots, and either cold-starts (when `BDOS_SENTINEL`
`$9C08` still reads `$9C`) or hands control to the resident CCP.

## 4. `cp/m.sys` — the hidden block reservation

Every SoftCard CP/M disk carries a directory entry `cp/m.sys` at **user `$1F`**
(31) — outside the normal user range, so no ordinary `DIR` shows it. Its
allocation map is hand-filled with blocks `$80-$8B` (12 blocks = 12 KB). It is
not a normal file: it reserves the data-area blocks that `CPM60.COM` overwrites
with the embedded 60K system image when converting a 44K disk to 60K (the raw
write goes to track `$14`). On the 44K disk it simply marks those blocks
reserved. See `../CPMV223-60K/CPM60_COM.md` for the conversion that uses it.
