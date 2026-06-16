# CPMV223-44K — Microsoft SoftCard CP/M 2.23 (`CPMV223-44K.DSK`)

A complete decompilation of `CPMV223-44K.DSK` (SoftCard CP/M **2.23**, the Videx-aware
release): the operating system (6502 + Z-80) and every `.COM` program in the
filesystem, as commented assembly that reassembles **byte-identical**, with an AI
prose layer (`[AI]`). See [`../README.md`](../README.md) for the overview of both
distributions and the shared tooling.

## `os/` — the operating system

| File | CPU | Load | What it is |
|------|-----|------|------------|
| `CPM_BootLoader.s` | 6502 | `$0800` | Stage-2 boot loader, install-copy logic, LOAD_CPM staging |
| `CPM_RWTS.s` | 6502 | `$0A00` | Read/Write Track-Sector engine (GCR 6-and-2 codec) |
| `CPM_InstallFragments.s` | 6502 | `$0200` | Fragments the stage-2 loader copies into place |
| `CPM_DiskCallbacks.asm` | Z-80 | `$1A00` | Z-80 thunks bridging BDOS/BIOS disk requests to the 6502 RWTS |
| `CPM_SystemImage.asm` | Z-80 | `$8000` | CCP (command processor) + BDOS |
| `CPM_BIOS.asm` | Z-80 | `$FA00` | BIOS: 17-entry jump table + console/disk/IOBYTE primitives (incl. the Videx device-6 path) |

6502 regions ship as ca65 `.s` + a `.cfg` linker config; Z-80 regions as sjasmplus
`.asm`.

## `utilities/` — the filesystem programs (20 `.COM`)

`APDOS ASM AUTORUN BOOT CAT COPY CPM60 DDT DOWNLOAD DUMP ED GBASIC LOAD MBASIC
MFT PATCH PIP STAT SUBMIT XSUB`

(`CONFIGIO.BAS` and `DUMP.ASM` are BASIC/asm source, not machine code, so they're
not decompiled.)

## Rebuild

```bash
source ../../../shared/toolchain/env.sh
bash ../rebuild.sh CPMV223-44K               # -> rebuilt/CPMV223-44K.DSK  (BYTE-IDENTICAL)
python ../verify_roundtrip.py CPMV223-44K    # reassemble every source file, compare to original
```

The full-disk reconstruction assembles the boot-pipeline sources and carries the
CP/M filesystem (the user programs) from the reference image; ~7.4 KB of CCP/BDOS
staging not yet split into annotated source is carried from the prior extraction
(see [`../../cpm_pipeline/chunk_map.py`](../../cpm_pipeline/chunk_map.py)).
