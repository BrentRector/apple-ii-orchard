# CPMV223-60K — Microsoft SoftCard CP/M 2.23 (60K)

The **60K** SoftCard CP/M 2.23 system: the same CP/M 2.23 as
[`../CPMV223-44K`](../CPMV223-44K), but with the CCP and BDOS lifted out of the
TPA and into the Apple II **language card**, so the Transient Program Area grows
from ~39K to ~55K. You don't get this disk by a fresh install — you get it by
running **`CPM60.COM`** (the in-place updater that ships on the 44K disk) on a
44K boot disk. So this folder is really two things: the **installer**
(`CPM60.COM`, reproduced byte-for-byte from source) and the **relocated OS** it
writes.

## What's in this folder

```
CPMV223-60K/
  CPMV223-60K.DSK     the original 60K disk image
  CPM60.asm           the master that assembles CPM60.COM byte-identically
  CPM60_installer.asm the Z-80 installer driver (INCLUDEd by CPM60.asm)
  os/                 the relocated 60K OS components CPM60.COM carries + installs
  CPM60_COM.md        definitive byte map of CPM60.COM (the 11,264-byte installer)
  DELTA.md            the 44K -> 60K delta: exactly what CPM60.COM changes
  BOOT_AND_PATCHING.md how the 60K system boots + every byte it patches on the way
  README.md           this file
```

## `CPM60.asm` — the installer, byte-identical from source

`CPM60.COM` (11,264 bytes) is a mixed-CPU `.COM`: a Z-80 installer driver plus an
embedded system image (6502 boot/relocation + the relocated Z-80 CCP/BDOS/BIOS).
[`CPM60.asm`](CPM60.asm) assembles it from **one master source** — it places each
piece at its `.COM` offset, `INCBIN`s the 6502 pieces, and assembles the
relocating Z-80 modules as real code at their run address (`CCP`→`$D300`,
`BDOS`→`$DC00`, `BIOS`→`$FA00`) via `DISP … ENT`. Full detail in
[`CPM60_COM.md`](CPM60_COM.md).

```bash
source shared/toolchain/env.sh        # from the repo root
python -c "from cpm_pipeline.build_cpm60 import build_cpm60_com, reference_com; \
import sys; sys.exit(0 if build_cpm60_com()==reference_com() else 1)" \
  && echo 'CPM60.COM: BYTE-IDENTICAL from source'
```

This is what the CI test `test_master_build_is_byte_identical` checks; a second
path (`build_cpm60_com_via_layout`) cross-checks it, and the reference is the
genuine `CPM60.COM` extracted from the disk.

## `os/` — the relocated 60K OS

| File | CPU | Run addr | What changed vs 44K |
|------|-----|----------|---------------------|
| `CPM_CCP.asm` | Z-80 | `$D300` | the 44K CCP re-ORG'd +$4000 into the language card (shared source builds both) |
| `CPM_BDOS.asm` | Z-80 | `$DC00` | the BDOS, modified for LC banking + the split layout |
| `CPM_BIOS.asm` | Z-80 | `$FA00` | the as-shipped 60K BIOS template (LC-aware) |
| `CPM_BootLoader.s` | 6502 | `$0800` | adds the LC-bank relocator + the four `COPY_PAGES` moves into the card |
| `CPM_RWTS.s` · `CPM_InstallFragments.s` | 6502 | — | the Disk II engine + install fragments |

These are the components `CPM60.asm` INCLUDEs/INCBINs (each wrapped behind
`IFNDEF CPM60_LINK` so it also assembles standalone). The exact 44K→60K
differences are catalogued in [`DELTA.md`](DELTA.md).

## How the 60K disk is built

The byte-identical buildable artifact is **`CPM60.COM`** (above). The 60K **disk**
is then produced by running `CPM60.COM` on a 44K boot disk — it rewrites only the
system tracks (0-2); the entire filesystem (tracks 3+, the 20 `.COM` + the
`.BAS`/`.ASM` files) is **byte-identical to `../CPMV223-44K/CPMV223-44K.DSK`**.
The cold-boot relocation `CPM60.COM` performs (the `COPY_PAGES` moves into the
language card, the in-LC patches, the reset-plant) is documented byte-by-byte in
[`BOOT_AND_PATCHING.md`](BOOT_AND_PATCHING.md). `softcard_emu` reproduces this
conversion in-emulator (the result is the regenerable `CPMV223-60K-EMU.DSK`).
