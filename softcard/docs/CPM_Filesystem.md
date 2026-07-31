# Microsoft SoftCard CP/M 2.23 — Filesystem (Tracks 3+)

The boot pipeline traced in [the cpm-videx investigation](https://wiseowl.com/projects/cpm-videx) covers tracks 0-2 of `CPMV223-44K.DSK` — the boot stub, RWTS, stage-2 loader, install fragments, the 29-sector LOAD_CPM staging, and the BIOS handler bytes loaded by the second `JSR $BBEB`. **Tracks 3-34 are CP/M filesystem data** — standard CP/M 2.x directory and file allocation, holding the user-visible programs that ship on the disk.

This document inventories what's on the user-visible side. The boot pipeline has nothing to do with this content; the Disk II's RWTS reads it on demand once the system is up and CP/M is running.

## CP/M filesystem layout

For Microsoft SoftCard CP/M 5.25" floppies, the filesystem parameters are:

| Parameter | Value |
|-----------|-------|
| Tracks | 35 (per Apple Disk II standard) |
| Sectors / track | 16 |
| Bytes / sector | 256 |
| Total bytes | 143,360 (140 KB) |
| Reserved tracks | 3 (tracks 0-2 = boot pipeline) |
| Block size | 1 KB |
| Directory entries | 64 |
| Directory tracks | 3-4 (first 32 sectors of the file area) |
| Records / block | 8 (CP/M 128-byte records) |

Each directory entry is 32 bytes: 1 byte user/status, 8 bytes filename, 3 bytes extension, 4 bytes extent metadata, 16 bytes allocation block list.

## How a formatted disk gets an empty directory

Nothing writes a directory structure, and nothing needs to. A directory slot whose first byte is `$E5` is a **free** slot, and the 6502 formatter fills every data field on the medium with `$E5`, so track 3 comes out of a format already a valid empty directory with all 64 slots free.

That the fill really is `$E5` is provable from the two 6-and-2 encoder constants the formatter pre-loads (`FORMAT_TRACK` at `$17DA` in `CPMV220-44K/utilities/FORMAT_6502.s`): primary `$39`, secondary `$2A`. The primary buffer holds `byte >> 2` and the secondary packs three 2-bit fields, each the byte's low two bits with the bit order reversed, so `$E5 = %11100101` gives `$E5 >> 2 = $39` and `%01` reversed thrice = `%00101010 = $2A`. No neighbouring value produces both; `$E6` would need `$15`. The 2.23 formatter embedded in `COPY.COM` (`COPY_6502.s`, buffers at `$1F00`) uses the identical pair.

This is why the packer note below says `$E5`-fill and not zero-fill.

## The `cp/m    sys` reservation entry

Every `$8B`-DPB image carries one directory entry that no `DIR` will show:

```
user  name          EX  S1  S2   RC    block map
$1F   "cp/m    sys"  0   0   0   $60   128 129 130 131 132 133 134 135 136 137 138 139
```

It exists to absorb the twelve blocks Microsoft's 2.23 DPB over-counts. `DSM` is `$8B` (139 → 140 blocks) where the 2.20 lineage uses `$7F` (127 → 128); the larger value counts the whole medium without subtracting the three reserved tracks, so blocks 128-139 map to tracks 35-37 on a 35-track disk and do not exist. Reserving them in a file keeps the allocator away.

Two hiding mechanisms are stacked on it: the **user number is 31**, outside the 0-15 the CCP's `DIR` and `USER` reach, and the **name is lowercase and contains a `/`**, which the CCP's command-line parser cannot produce. Neither is a barrier to a program that supplies its own 11-byte FCB, which is how it gets written.

**Two shipped Microsoft tools write it**, running the same sequence: `CPM60.COM` (`CPMV223-60K/CPM60_installer.asm`) and `COPY.COM` on its `/S` path (`CPMV223-44K/utilities/COPY.asm` `$037F`). Both set user 31, delete any stale entry, verify blocks 128-139 are free in the allocation bitmap, `F_MAKE`, hand-fill the block map with `$80..$8B`, set `RC`=`$60`/`EX`=`$00`, and `F_CLOSE`. It is a designed convention, not a mastering-time patch.

Consequently a disk formatted **without** `/S` has a valid empty directory and no reservation, so its last twelve blocks are addressable and absent. Full trace in [`CPM_Disk_Creation.md`](CPM_Disk_Creation.md).

## File inventory

Parsing the directory entries on tracks 3-4 of `CPMV223-44K.DSK` (skipping deleted files marked `$E5`):

| Filename | Records | Bytes | Notes |
|----------|---------|-------|-------|
| `APDOS.COM` | 13 | 1,664 | Apple ProDOS interface (?) |
| `ASM.COM` | 64 | 8,192 | CP/M 8080 assembler (Digital Research) |
| `AUTORUN.COM` | 1 | 128 | Auto-execute on boot |
| `BOOT.COM` | 4 | 512 | Re-boot utility |
| `CAT.COM` | 6 | 768 | Microsoft directory listing |
| `CONFIGIO.BAS` | 58 | 7,424 | BASIC I/O configuration tool |
| `COPY.COM` | 28 | 3,584 | File copy |
| `CPM60.COM` | 88 | 11,264 | 60K CP/M loader variant |
| `DDT.COM` | 40 | 5,120 | Dynamic Debugging Tool (Digital Research) |
| `DOWNLOAD.COM` | 4 | 512 | File transfer utility |
| `DUMP.ASM` | 33 | 4,224 | DUMP source |
| `DUMP.COM` | 4 | 512 | Hex dump utility |
| `ED.COM` | 52 | 6,656 | CP/M line editor (Digital Research) |
| `GBASIC.COM` | 200 | 25,600 | Microsoft Graphics BASIC |
| `LOAD.COM` | 14 | 1,792 | Convert .HEX to .COM |
| `MBASIC.COM` | 192 | 24,576 | Microsoft BASIC |
| `MFT.COM` | 12 | 1,536 | Move/transfer utility |
| `PATCH.COM` | 8 | 1,024 | Patch utility |
| `PIP.COM` | 58 | 7,424 | Peripheral Interchange (copy/concat) |
| `STAT.COM` | 48 | 6,144 | File and disk stats |
| `SUBMIT.COM` | 10 | 1,280 | Batch file submission |
| `XSUB.COM` | 6 | 768 | Extended SUBMIT |

(There are additional directory entries containing apparently-corrupted filenames — these are leftover entries from deleted files whose directory slots haven't been reused yet. CP/M doesn't actively scrub deleted entries; it just sets the user byte to `$E5`.)

The mix is **standard 1981/1982 Microsoft SoftCard distribution**: Digital Research's CP/M utilities (`ASM`, `DDT`, `ED`, `LOAD`, `PIP`, `STAT`, `SUBMIT`, `XSUB`) plus Microsoft additions (`AUTORUN`, `BOOT`, `CAT`, `CONFIGIO`, `COPY`, `CPM60`, `DUMP`, `GBASIC`, `MBASIC`, `MFT`, `PATCH`).

## Why the build pipeline doesn't touch the filesystem

The OS-region build ([`cpm_pipeline.reconstruct.reconstruct_disk`](https://github.com/BrentRector/orchard/blob/main/softcard/cpm_pipeline/reconstruct.py), the `build` verb) starts from the reference `.DSK` and overwrites only the boot-pipeline sectors (tracks 0-2 plus parts of track 0's file system) from re-assembled source. Tracks 3+ are carried through unchanged. (A full source rebuild that also regenerates each file in the filesystem is `reconstruct_full_disk`.)

This is intentional. The filesystem content is *user data* — Microsoft's distribution programs. The cpm-videx investigation isn't about reverse-engineering those individual `.COM` files; it's about how the boot pipeline gets CP/M up and running. Once CP/M is running and the `A>` prompt is visible, the user can do `DIR` to see the file list, run `BASIC`, write programs, or whatever. That's normal CP/M operation, identical to any other CP/M system.

If the goal were to produce a *minimal bootable* CP/M disk with no user files — just the boot pipeline — the packer would fill tracks 3-34 with **`$E5`**, and the resulting `.DSK` would boot to `A>` with an empty directory. Note it must be `$E5`, not zero: a zero-filled slot is a *valid* entry for user 0 with a blank name, so a zero-filled track 3 reads as 64 files rather than as free space. See "How a formatted disk gets an empty directory" below. Conversely, if the goal were to study a specific `.COM` file, that's standard CP/M reverse-engineering — the file lives on the disk, can be read out by any CP/M tool, and disassembled with `DDT` or any 8080/Z-80 debugger.

The boot pipeline is the *interesting* part of SoftCard CP/M because it's specific to the SoftCard and to the Apple ][ host. The filesystem and the user-level programs are stock CP/M 2.2 behavior, not unique to this disk.
