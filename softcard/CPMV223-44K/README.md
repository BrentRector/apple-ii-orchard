# CPMV223-44K — Microsoft SoftCard CP/M 2.23 (44K)

A complete, **byte-identical** decompilation of the SoftCard CP/M **2.23** boot
disk — the Videx-aware release, and the basis for the 60K system (running
`CPM60.COM` converts this disk to [`../CPMV223-60K`](../CPMV223-60K)). Everything
on the disk, the operating system (6502 + Z-80) and every `.COM` program, is
here as commented assembly that reassembles to the original bytes, with an AI
prose layer (lines marked `[AI]`). See [`../README.md`](../README.md) for the
overview of all three releases and the shared tooling.

## What's in this folder

The reference disk image lives in the canonical archive at
[`../reference/softcard-cpm-archive/os/softcard-cpm2.23-44k-system.dsk`](../reference/softcard-cpm-archive/),
not in this folder; code resolves it via `cpm_pipeline.reference_data.DISK_2_23_44K_SYSTEM`.

```
CPMV223-44K/
  os/                   the operating system + boot pipeline, as source
  utilities/            one annotated .asm per .COM program on the disk
    bin/                those programs reassembled (byte-identical to the disk)
  BOOT_AND_PATCHING.md  how the system boots + what the running system builds
  README.md             this file
```

## `os/` — the operating system

The disk's system area (tracks 0-2) holds the boot pipeline and the staged CP/M
system. These sources reassemble to exactly those bytes; the disk build
(`chunk_map`) reads them directly.

| File | CPU | Load | What it is |
|------|-----|------|------------|
| `CPM_BootLoader.s` | 6502 | `$0800` | Stage-2 boot loader (`$0800-$13FF`): install-copy logic, the `LOAD_CPM` staging read, the RWTS (`$0A00-$0FFF`, GCR 6-and-2 codec), and the install image (`$1200-$13FF`, run at `$0200-$03FF`). The single canonical decode of the Apple-side OS |
| `CPM_DiskCallbacks.asm` | Z-80 | `$1A00` | Z-80 thunks bridging BDOS/BIOS disk requests to the 6502 RWTS |
| `CPM_CCP.asm` | Z-80 | `$8000` | The CCP module; also assembles the staged **CCP + BDOS** image `LOAD_CPM` reads, by INCLUDEing `CPM_BDOS.asm` (runs at `$9300`/`$9C00`) |
| `CPM_BDOS.asm` | Z-80 | `$9C00` | The 2.23 BDOS module (builds standalone; INCLUDEd by `CPM_CCP.asm` under `DISP $9C00`) |
| `CPM_BIOS.asm` | Z-80 | `$FA00` | The **as-shipped** pristine on-disk BIOS (`$FA00-$FDFF`); jump table + console/disk/IOBYTE primitives |

6502 regions are ca65 `.s` + a `.cfg` linker config; Z-80 regions are sjasmplus
`.asm`. The CP/M system image is **two independent module files** — `CPM_CCP.asm`
(the CCP) and `CPM_BDOS.asm` (the BDOS); the CCP INCLUDEs the BDOS so the two
compile as one staged image and reassemble byte-identical. The BIOS is the bytes on disk; the
running BIOS additionally builds a `$FE00-$FF47` device/console tail in RAM (the
Videx/Pascal path) — see [`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md).

## `utilities/` — the filesystem programs

19 of the 20 `.COM` programs in the disk's filesystem are here as annotated
`.asm` that reassemble byte-identical, with `bin/` holding the assembled output:

`APDOS ASM AUTORUN BOOT CAT COPY DDT DOWNLOAD DUMP ED GBASIC LOAD MBASIC MFT
PATCH PIP STAT SUBMIT XSUB`

The 20th, `CPM60.COM`, is built from the 60K master
[`../CPMV223-60K/CPM60.asm`](../CPMV223-60K/CPM60.asm).
(`CONFIGIO.BAS` and `DUMP.ASM` are BASIC/asm text files on the disk, not machine
code.) `GBASIC` self-relocates and is one file via `DISP`; see its header.

## How the disk is laid out

- **Tracks 0-2** — the reserved system area: the boot sector, the 6502 boot
  loader / RWTS / install fragments, and the `LOAD_CPM` staging (CCP + BDOS +
  disk callbacks + the on-disk BIOS).
- **Tracks 3+** — the CP/M filesystem (the 20 `.COM` + the `.BAS`/`.ASM` files).
- **`cp/m.sys`** — a hidden directory entry at user `$1F` reserving 12 KB of data
  blocks (`$80-$8B`); it's how `CPM60.COM` protects the embedded 60K system it
  writes to the data tracks during conversion.

The full boot/load/cold-boot-generate sequence is in
[`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md).

## Building the disk from source

From the repo root, with the toolchain on PATH:

```bash
source shared/toolchain/env.sh        # ca65 + ld65 + sjasmplus

# Rebuild the WHOLE disk from source and verify byte-identical:
python -m cpm_pipeline.reconstruct softcard/reference/softcard-cpm-archive/os/softcard-cpm2.23-44k-system.dsk rebuilt.dsk
```

This assembles the OS region from `os/`, lays in every `.COM` from
`utilities/bin/` (and `CPM60.COM` from the 60K master), carries the filesystem's
data files, and prints a per-byte provenance summary. It exits 0 only when the
result is **byte-identical** to the archived `softcard-cpm2.23-44k-system.dsk` (over 80% of the disk comes
from re-assembled source; the rest is filesystem data, the directory, and free
space). The same check runs in CI as
`test_cpm223_full_disk_reconstruct_byte_identical`.

`bin/` is the committed assembled output. To regenerate it from the sources
(each `.asm` SAVEBINs `<NAME>.bin`, which is the same bytes as the disk's
`<NAME>.COM`):

```bash
cd softcard/CPMV223-44K/utilities
for f in *.asm; do sjasmplus "$f" && mv "${f%.asm}.bin" "bin/${f%.asm}.COM"; done
```
