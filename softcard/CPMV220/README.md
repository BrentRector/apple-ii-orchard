# CPMV220 — Microsoft SoftCard CP/M 2.20

A complete, **byte-identical** decompilation of SoftCard CP/M **2.20** — the
earlier, pre-Videx release. Everything on the bootable **Disk1**, the operating
system (6502 + Z-80) and every `.COM` program on it, is here as commented
assembly that reassembles to the original bytes. (Disk2 is a companion tools
disk; its extra programs are not decompiled — see below.) See [`../README.md`](../README.md) for the
overview of all three releases and the shared tooling.

2.20 ships on **two disks**: **Disk1** is the bootable system + the core SoftCard
utilities (the one this folder decompiles); **Disk2** is a second distribution
disk of extra tools — the Digital Research dev set (`ASM` `DDT` `ED` `LOAD`
`SUBMIT` `XSUB`), Apple-DOS file-transfer utilities (`ADOSXFER` `DOSRDSK`
`NRDRDSK` `DRIVERS`), and a `TIMER` example. The two disks share the OS staging
(tracks 1-2) but differ on the boot sector and filesystem.

Each disk is provided in **both** `.po` (ProDOS sector order — the original) and
`.dsk` (DOS 3.3 sector order — a lossless conversion of the same physical
sectors, for DOS-3.3-oriented tooling/emulators).

## What's in this folder

```
CPMV220/
  CPMV220-Disk1.po / .dsk   the bootable 2.20 disk (ProDOS / DOS 3.3 order)
  CPMV220-Disk2.po / .dsk   the second distribution disk (extra DR + Apple-DOS tools)
  os/                   the operating system + boot pipeline, as source
  utilities/            one annotated .asm per .COM on Disk1
    bin/                those programs reassembled (byte-identical to the disk)
  BOOT_AND_PATCHING.md  how the system boots + what the running system builds
  README.md             this file
```

## `os/` — the operating system

| File | CPU | Load | What it is |
|------|-----|------|------------|
| `CPM_BootLoader.s` | 6502 | `$0800` | Stage-2 boot loader, install-copy logic, the `LOAD_CPM` staging read |
| `CPM_RWTS.s` | 6502 | `$0A00` | Read/Write Track-Sector engine (GCR 6-and-2 codec) |
| `CPM_InstallFragments.s` | 6502 | `$0200` | Fragments the stage-2 loader copies into place |
| `CPM_SystemImage.asm` | Z-80 | `$8000` | the staged **CCP + BDOS** image `LOAD_CPM` reads |
| `CPM_BIOS.asm` | Z-80 | `$DA00` | the **as-shipped** pristine on-disk BIOS (`$DA00-$DEFF`); jump table + console/disk/IOBYTE primitives |

2.20 has **no `CPM_DiskCallbacks` region**, and its BIOS lacks the Videx device-6
console path that 2.23 adds — that difference is the heart of the
[Videx investigation](../docs/CPM_Videx_Difference.md). The BIOS here is the bytes
on disk; the running BIOS additionally builds a device/console tail in RAM at cold
boot — see [`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md). 6502 regions are ca65
`.s` + a `.cfg`; Z-80 regions are sjasmplus `.asm`.

## `utilities/` — the filesystem programs (11 `.COM`)

Each as an annotated `.asm` that reassembles byte-identical, with `bin/` holding
the assembled output:

`APDOS BOOT COPY CPM56 DOWNLOAD FORMAT GBASIC MBASIC PIP RW13 STAT`

Note the 2.20-specific tools: `CPM56.COM` (the 56K loader, the 2.20 analogue of
2.23's `CPM60`), `FORMAT.COM`, and `RW13.COM`. (`CONFIGIO.BAS` and `DUMP.ASM` are
BASIC/asm text on the disk, not machine code.)

## How the disk is laid out

- **Tracks 0-2** — the reserved system area: the boot sector, the 6502 boot
  loader / RWTS / install fragments, and the `LOAD_CPM` staging (CCP + BDOS + the
  on-disk BIOS).
- **Tracks 3+** — the CP/M filesystem (the 11 `.COM` + the `.BAS`/`.ASM`).
- **`cp/m.sys`** — a hidden directory entry at user `$1F` reserving data blocks
  (see [`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md)).

## Building the disk from source

From the repo root, with the toolchain on PATH:

```bash
source shared/toolchain/env.sh        # ca65 + ld65 + sjasmplus
python -m cpm_pipeline.reconstruct softcard/CPMV220/CPMV220-Disk1.po rebuilt.po
# -> BYTE-IDENTICAL to CPMV220-Disk1.po
```

This assembles the OS region from `os/`, lays in every `.COM` from
`utilities/bin/`, carries the filesystem data, and exits 0 only when the result
is byte-identical (checked in CI by `test_cpm220_reconstruct_byte_identical`). To
regenerate `bin/` from the sources:

```bash
cd softcard/CPMV220/utilities
for f in *.asm; do sjasmplus "$f" && mv "${f%.asm}.bin" "bin/${f%.asm}.COM"; done
```
