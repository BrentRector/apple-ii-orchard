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

## `os/` — the operating system (de-skewed, runtime-addressed)

The disk's system area (tracks 0-2) holds the boot pipeline and the CP/M system.
Like 2.20-44K, the CCP/BDOS/BIOS are stored **sector-interleaved**; the cold loader
stages them at Apple `$8000` then relocates them to their runtime addresses. These
sources are decoded at their true **runtime** addresses, and the disk producer
re-applies the skew (`cpm_pipeline/deskew.py :: PAGE_TO_SECTOR_223` /
`BIOS_PAGE_TO_SECTOR_223`; see [`../docs/CPM_Skew_Findings.md`](../docs/CPM_Skew_Findings.md)).
**Decode/edit the de-skewed runtime image, never the raw on-disk bytes.**

| File | CPU | Runtime ORG | Size | What it is |
|------|-----|------|------|------------|
| `CPM_BootLoader.s` | 6502 | `$0800` | `$0C00` | Track-0 boot stub + RWTS (GCR 6-and-2) + the `LOAD_CPM` staging read + install image |
| `CPM_CCP.asm` | Z-80 | `$9300` | `$0900` | Console Command Processor (one page lower than 2.20's `$9400`); includes a 2.23-only SoftCard fast `.COM` loader |
| `CPM_BDOS.asm` | Z-80 | `$9C00` | `$0E00` | Basic Disk Operating System; an independent compilation |
| `CPM_BIOS.asm` | Z-80 | `$FA00` | `$0600` | Basic I/O System at z80 `$FA00` = **Apple `$0A00` low RAM** (not `$AA00` like 2.20). Console/IOBYTE RPC; disk deblock is **delegated off-image** (`READ -> JP $AC39`, `WRITE -> JP $AC49`) |

6502 regions are ca65 `.s`; Z-80 regions are sjasmplus `.asm`. The CP/M system image
is **two independent compilations** — `CPM_CCP.asm` (`$9300`) and `CPM_BDOS.asm`
(`$9C00`) — sharing only the `$0005` ABI (`cpm22.inc`) and the cross-module symbols in
`../include/cpm_system_223.inc` (`BDOS_FBASE=$9C00`, `CCP_WBOOT=$9B06`). Each carries
`IFNDEF CPM_LINK / DEVICE / ORG / SAVEBIN` so it assembles standalone, byte-identical.
Addresses live in the generated `os/*.lst` (not inline). 2.23 vs 2.20 highlights: the
BIOS runs in Apple low RAM and delegates deblock off-image, the DPB has DSM=139 (vs 127)
with 4 drives (vs 6), and the Videx 80-col card vs 40-col Apple screen are both handled
(see [`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md)). The boot loader's two embedded
Z-80 blocks are sub-assembled and INCBIN'd; the BIOS carries an embedded 6502 RPC
service (`$FDD1-$FE40`) and Z-80 device-handler stubs that are flagged for the same
cross-CPU extraction treatment.

## `utilities/` — the filesystem programs

[`../CPMV220-44K`](../CPMV220-44K) is the **base** source tree, so the 9 `.COM`
that are byte-identical across the 44K releases live there (one source for all),
not here: `APDOS ASM DOWNLOAD DUMP ED LOAD PIP STAT XSUB`.

The 10 whose bytes differ from 2.20-44K or are 2.23-only are here as annotated
`.asm` that reassemble byte-identical (with `bin/` holding the assembled output):

`AUTORUN BOOT CAT COPY DDT GBASIC MBASIC MFT PATCH SUBMIT`

The 20th, `CPM60.COM`, is built from the 60K master
[`../CPMV223-60K/CPM60.asm`](../CPMV223-60K/CPM60.asm).
(`CONFIGIO.BAS` and `DUMP.ASM` are BASIC/asm text files on the disk, not machine
code.) `GBASIC` self-relocates and is one file via `DISP`; see its header.

## How the binaries are written to the boot tracks

The disk layout is declarative, in
[`../cpm_pipeline/chunk_map.py`](../cpm_pipeline/chunk_map.py) (`SOURCES_223` +
`_build_chunks_223`). The producer assembles each source, then places 256-byte slices
at physical disk sectors. Because the system tracks are sector-interleaved, the producer
**re-applies the skew**: it writes each de-skewed runtime page back to the `.dsk` sector
the cold loader read it from (`deskew.py :: PAGE_TO_SECTOR_223` / `BIOS_PAGE_TO_SECTOR_223`),
i.e. runtime page -> `.dsk` linear sector `S` -> `(track = S // 16, physical sector whose
DOS-3.3 on-disk position is S % 16)`.

1. **Boot stub — track 0.** `CPM_BootLoader` (`$0800-$13FF`) is laid down as 11 sectors on
   track 0 (physical sectors `0,2,4,6,8,A,C,E,1,3,5` <- loader offsets `$0800-$1300`).
   Sector T0S0 is the `$C600`-PROM-loaded boot-0; it pulls in the rest of the loader, which
   stages the system at Apple `$8000`, relocates it to the runtime addresses, and starts the
   Z-80.
2. **CCP + BDOS — scattered across tracks 0-2.** The 23 runtime pages (`$9300-$A9FF`) are
   scattered back to their source sectors via `PAGE_TO_SECTOR_223`. Pages `$9300-$9BFF` come
   from `CPM_CCP.asm`; `$9C00-$A9FF` from `CPM_BDOS.asm`.
3. **BIOS — track 2.** The 6 runtime pages (`$FA00-$FFFF` = Apple `$0A00-$0FFF`) are scattered
   to `.dsk` linear sectors 40-45 (all on track 2) via `BIOS_PAGE_TO_SECTOR_223`. The BIOS
   also INCBINs its embedded 6502 RPC service (`CPM_RPC6502_223.bin`) at the `$FDD0` position.
4. **Tracks 3+** — the CP/M filesystem (the 20 `.COM` + the `.BAS`/`.ASM` files), carried
   verbatim from the reference image. Sectors not written by any chunk keep their reference
   bytes, so the round-trip is exact.

`cp/m.sys` is a hidden directory entry at user `$1F` reserving 12 KB of data blocks
(`$80-$8B`); it's how `CPM60.COM` protects the embedded 60K system it writes to the data
tracks during conversion. The full boot/load/cold-boot-generate sequence is in
[`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md).

## Step 1 — compile the OS sources into binaries

Each source assembles, standalone, to a fixed-size binary at its runtime ORG: the Z-80
sources `SAVEBIN` their image (sjasmplus), the 6502 sources link to a flat binary
(ca65 + ld65). Two sources pull in a foreign-CPU binary by `INCBIN`, so that dependency
is compiled first.

| Source | Assembler | Produces | At ORG | Size | Notes |
|--------|-----------|----------|--------|------|-------|
| `os/CPM_RPC6502_223.s` | ca65 + ld65 | `CPM_RPC6502_223.bin` | `$0DD0` | `$0072` | the embedded 6502 RPC service (INCBIN'd by the BIOS) |
| `os/CPM_BIOS.asm` | sjasmplus | `CPM_BIOS.bin` | `$FA00` | `$0600` | INCBINs `CPM_RPC6502_223.bin` |
| `os/CPM_CCP.asm` | sjasmplus | `CPM_CCP.bin` | `$9300` | `$0900` | needs `cpm22.inc` + `cpm_system_223.inc` |
| `os/CPM_BDOS.asm` | sjasmplus | `CPM_BDOS.bin` | `$9C00` | `$0E00` | needs `cpm22.inc` + `cpm_system_223.inc` |
| `os/CPM_BootLoader.s` | ca65 + ld65 | the `$0800-$13FF` boot image | `$0800` | `$0C00` | INCBINs two Z-80 fragments (sub-assembled by sjasmplus) |

The pipeline knows each source's ORG/size, include path, and INCBIN dependencies
(`cpm_pipeline/chunk_map.py :: SOURCES_223`), so the one call below compiles a source and
returns its bytes (it stages the includes/deps and rewrites the source's `SAVEBIN`
target into a temp file):

```bash
source shared/toolchain/env.sh                  # puts ca65 + ld65 + sjasmplus on PATH
python -c "from cpm_pipeline.chunk_map import SOURCES_223; \
from cpm_pipeline.assemble import assemble_chunk; \
open('CPM_BIOS.bin','wb').write(assemble_chunk(SOURCES_223['CPM223_BIOS_Disk']))"
# -> CPM_BIOS.bin (1536 bytes); likewise CPM223_44K_CCP / CPM223_44K_BDOS / CPM223_BootLoader.
```

(The `.COM` utility programs assemble the same way -- each `utilities/*.asm` self-`SAVEBIN`s
its `<NAME>.bin`, byte-identical to the disk's `<NAME>.COM`; `bin/` holds the committed output.)

## Step 2 — lay the compiled binaries onto the disk tracks

The binaries are placed onto a disk image by the de-skew scatter described in **"How the
binaries are written to the boot tracks"** above: each binary's 256-byte pages go to the
specific (track, physical sector) the cold loader reads them from. The filesystem (tracks
3+, the `.COM` and `.BAS`/`.ASM` files) is carried verbatim, since the OS sources own only
tracks 0-2. One call compiles every source and lays the result onto a disk image:

```bash
python -m cpm_pipeline.reconstruct \
    softcard/reference/softcard-cpm-archive/os/softcard-cpm2.23-44k-system.dsk \
    softcard-cpm2.23-44k-built.dsk
```

The first argument supplies the filesystem (tracks 3+) and the OS tracks are overwritten
with the freshly compiled binaries; the second is the disk image written out. As a
build-correctness check it also confirms the result is **byte-identical** to the original
2.23-44K disk (it exits non-zero otherwise; CI runs this as
`test_cpm223_full_disk_reconstruct_byte_identical`). **Source `env.sh` first** -- without
the assemblers on `PATH` the byte-identical build cases skip rather than run. Addresses and
machine bytes live in the generated `os/*.lst`, not inline; regenerate one with
`python -m cpm_pipeline.os_listing softcard/CPMV223-44K/os/CPM_BIOS.asm --write`.
