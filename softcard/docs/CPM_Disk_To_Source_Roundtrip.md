# From an unknown disk image to byte-identical source, and back

This is the end-to-end result of the SoftCard CP/M decompilation work: starting
from nothing but a disk image, the toolchain identifies it, turns **everything
executable on it** into human-readable assembly source, reassembles that source,
and produces a new disk image that is **byte-for-byte identical** to the original.
The rebuilt image also boots and runs in the emulator.

Two disks are covered: `CPMV223-44K.DSK` (CP/M 2.23) and `CPMV220-Disk1.po` (CP/M 2.20).

## The flow

```sh
source shared/toolchain/env.sh

# 1. Treat the image as unknown. Identify it.
python -m cpm_pipeline detect softcard/CPMV223-44K/CPMV223-44K.DSK
#   -> DSK format, 35T x 16S; boot stub present; variant softcard_cpm_2_23 (high)

# 2. Decompile the whole operating system (6502 boot + Z-80 BIOS/CCP/BDOS) to source.
python -m cpm_pipeline decompile-os   softcard/CPMV223-44K/CPMV223-44K.DSK out/os --ai --ai-backend cli

# 3. Decompile every program in the CP/M filesystem (emulation-assisted) to source.
python -m cpm_pipeline decompile-disk softcard/CPMV223-44K/CPMV223-44K.DSK out --select <each .COM> --ai --ai-backend cli

# 4. Reassemble EVERYTHING and rebuild the whole disk from source; verify byte-identical.
python -m cpm_pipeline.reconstruct softcard/CPMV223-44K/CPMV223-44K.DSK build/cpm223_fromsource.dsk

# 5. Boot the rebuilt-from-source image to prove it is not just identical but live.
python -m softcard_emu build/cpm223_fromsource.dsk --keys "DIR\r"
```

## What "everything" means

The disk is two regions: the boot/OS pipeline (tracks 0-2) and a standard CP/M 2.2
filesystem (tracks 3+).

**The operating system (tracks 0-2) now comes 100% from re-assembled source.**
Previously ~28% of the OS bytes were disassembled and the 7.4 KB CCP+BDOS+BIOS
staging area was copied verbatim from a pre-extracted `.bin`. The staging area is
now split into three annotated sources that tile it exactly:

| Staging bytes | Source | What it is |
|---|---|---|
| `$0000-$16FF` (5888 B) | `CPM_CCP.asm` + `CPM_BDOS.asm` | CCP + BDOS (two module files; CCP INCLUDEs BDOS) |
| `$1700-$18FF` (512 B)  | `CPM223_DiskCallbacks.asm` | Z-80 -> 6502 disk thunks (2.23 only) |
| `$1900-$1CFF` (1024 B) | `CPM223_BIOS_Disk.asm` | the **pristine on-disk BIOS image** @ `$FA00` |

The last one was the missing piece. The disk holds the BIOS in its *un-patched*
form (the jump table `JP $FED1 / JP $FAB8 / ...` is the give-away); the cold boot
patches ~185 bytes of it at runtime, which is why it differs from the runtime
BIOS image (`CPM223_BIOS.asm`) and needed its own source. 2.20 is the same shape
with the BIOS jump table at `$DA00`.

`python -m cpm_pipeline build --reference <disk> --verify` now reports
**100.0% from freshly assembled source, 0 bytes from `.bin`**, byte-identical,
for both variants.

**Every program is disassembled from the disk.** All 31 `.COM` files (20 on 2.23,
11 on 2.20) are extracted straight from the CP/M filesystem and disassembled
emulation-assisted (the program is run under the Z-80 interpreter with a BDOS
shim, executed addresses seed the disassembler, the rest is data). Every one
reassembles **byte-identical** to the original file.

## Whole-disk provenance (built component-by-component, never copied wholesale)

`reconstruct_full_disk` writes a blank image and fills it from source/data components,
then verifies the whole thing equals the original:

| | CP/M 2.23 | CP/M 2.20 |
|---|---|---|
| **byte-identical to original** | yes | yes |
| from re-assembled **source** (OS + every .COM) | 118,784 B (82.9%) | 92,160 B (64.3%) |
| data files (tokenised BASIC, text) | 11,648 B | 11,648 B |
| CP/M directory | 2,048 B | 2,048 B |
| file padding / residue | 8,320 B | 6,016 B |
| free space / boot gaps | 2,560 B | 31,488 B |

Every byte of *code* (the OS and all programs) is regenerated from human-readable
source. The bytes that are *not* from source are exactly the things that aren't
code: data files, the filesystem directory, end-of-file padding, and free space.
The 2.20 disk is mostly free space, which is why its source fraction is lower.

## New tooling built for this

- **On-disk BIOS disassembly** (`docs/CPM2*_BIOS_Disk.asm`): the pristine,
  un-patched BIOS image as it sits in the staging area, disassembled with full
  jump-table seeding and the BIOS symbol tables, round-tripping byte-identical.
- **Staging fully sourced** (`cpm_pipeline/chunk_map.py`): the 28/29 LOAD_CPM
  staging sectors are now tiled by `SystemImage` + `DiskCallbacks` + `BIOS_Disk`
  instead of a pre-extracted `staging_*.bin`.
- **Whole-disk reconstruction from source** (`cpm_pipeline/reconstruct.py`, `reconstruct_full_disk`):
  builds the entire image component-by-component from re-assembled OS source,
  re-assembled `.COM` source, and filesystem data, and reports per-byte
  provenance + byte-identical verification.

## The interpreter as the code/data oracle

Static disassembly cannot tell code from data and renders fill (`$00/$FF/$F7`)
as bogus `NOP`/`RST` runs. The interpreter avoids that: every `.COM` is *run*,
and only addresses that actually execute (extended by recursive descent from
those seeds and from jump tables) are treated as code. Two caveats are handled
honestly rather than papered over:

- **Unreached code.** Some routines (error/print paths) are never exercised by a
  given run, so execution alone under-covers them; recursive descent from the
  executed seeds and from jump-table / vector entries recovers the reachable
  remainder. Anything still unreached stays as faithful data (byte-identical
  either way).
- **Garbage / uninitialised bytes.** Staging buffers and free space contain
  residue (the same class of "garbage" `CPM60.COM` writes when it rewrites the
  OS). These are emitted as data, not invented code.

Finally, the rebuilt-from-source `CPMV223-44K.DSK` **boots in the emulator** and runs
`DIR`, listing the disk's files — the reassembled source is not just byte-identical,
it is live.
