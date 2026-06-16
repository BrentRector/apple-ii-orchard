# CPMV220 — Microsoft SoftCard CP/M 2.20 (`CPMV220-Disk1.po`)

A complete decompilation of `CPMV220-Disk1.po` (SoftCard CP/M **2.20**, the
pre-Videx release): the operating system (6502 + Z-80) and every `.COM` program in
the filesystem, as commented assembly that reassembles **byte-identical**, with an
AI prose layer (`[AI]`). See [`../README.md`](../README.md) for the overview of both
distributions and the shared tooling.

## `os/` — the operating system

| File | CPU | Load | What it is |
|------|-----|------|------------|
| `CPM_BootLoader.s` | 6502 | `$0800` | Stage-2 boot loader, install-copy logic, LOAD_CPM staging |
| `CPM_RWTS.s` | 6502 | `$0A00` | Read/Write Track-Sector engine (GCR 6-and-2 codec) |
| `CPM_InstallFragments.s` | 6502 | `$0200` | Fragments the stage-2 loader copies into place |
| `CPM_SystemImage.asm` | Z-80 | `$8000` | CCP (command processor) + BDOS |
| `CPM_BIOS.asm` | Z-80 | `$DA00` | BIOS: jump table + console/disk/IOBYTE primitives |

2.20 has **no `CPM_DiskCallbacks` region** and its BIOS lacks the Videx device-6
console path that 2.23 adds — that difference is the heart of the
[cpm-videx investigation](../../docs/CPM_Videx_Difference.md). 6502 regions ship as
ca65 `.s` + a `.cfg`; Z-80 regions as sjasmplus `.asm`.

## `utilities/` — the filesystem programs (11 `.COM`)

`APDOS BOOT COPY CPM56 DOWNLOAD FORMAT GBASIC MBASIC PIP RW13 STAT`

Note the 2.20-specific tools: `CPM56.COM` (the 56K loader, vs 2.23's `CPM60`),
`FORMAT.COM`, and `RW13.COM`. (`CONFIGIO.BAS` and `DUMP.ASM` are source text, not
machine code, so they're not decompiled. `CPMV220-Disk2.po` is a second distribution
disk and is not part of this bootable-system distribution.)

## Rebuild

```bash
source ../../../shared/toolchain/env.sh
bash ../rebuild.sh CPMV220                # -> rebuilt/CPMV220.po  (BYTE-IDENTICAL)
python ../verify_roundtrip.py CPMV220     # reassemble every source file, compare to original
```
