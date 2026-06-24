# CPMV220-44K — Microsoft SoftCard CP/M 2.20, 44K (original 1980)

A **clean-room** decompile of the original 1980 SoftCard CP/M 2.20 / 44K system
disk (`reference/softcard-cpm-archive/.../softcard-cpm2.20-44k-system-1980.dsk`).
Every byte of source here was derived **only** from that disk's bytes plus general
CP/M 2.2 / Z-80 / 6502 / Apple II knowledge and the primary-source 2.20 manuals —
**no 56K (`CPMV220`) or 2.23 (`CPMV223-*`) source was consulted.** The whole disk
reconstructs **byte-identical** from this tree.

This is the canonical 2.20-44K tree: it owns the byte-identical shared utilities and
the GBASIC/MBASIC masters. This README covers the **OS core** in `os/` — how to
assemble the four components and how their binaries land on the disk's boot tracks.

## The one thing to understand first: the de-skew

The CCP, BDOS, and BIOS are stored on the system tracks **sector-interleaved**. The
cold loader reads *logical* sectors (RWTS skew) into *contiguous* RAM, so the bytes
**execute in a different order than they sit on disk**. These sources are written at
each component's true **runtime address** (every label a real run-time address), and
the disk producer **re-applies the skew** when writing them back to disk.

The runtime-page → disk-sector map is emulator-derived and lives in
[`cpm_pipeline/deskew.py`](../cpm_pipeline/deskew.py) (`PAGE_TO_SECTOR` for CCP+BDOS,
`BIOS_PAGE_TO_SECTOR` for the BIOS). See
[`docs/CPM_Skew_Findings.md`](../docs/CPM_Skew_Findings.md) for the full story.
**Decode/edit the de-skewed runtime image, never the raw on-disk bytes.**

## os/ — the operating system (44K runtime bases)

Each region was independently decompiled and **adversarially verified**, and
reassembles byte-identical.

| Source | CPU | Runtime ORG | Size | Role |
|---|---|---|---|---|
| `os/CPM_BootLoader.s` | 6502 | `$0800` | `$0C00` | Track-0 boot stub + RWTS that loads the system into RAM |
| `os/CPM_CCP.asm` | Z-80 | `$9400` | `$0800` | Console Command Processor |
| `os/CPM_BDOS.asm` | Z-80 | `$9C00` | `$0E00` | Basic Disk Operating System (entry `$9C06`, dispatcher `$9C47`) |
| `os/CPM_BIOS.asm` | Z-80 | `$AA00` | `$0600` | Basic I/O System: 15-entry jump vector, IOBYTE-routed console/list/punch/reader RPC, RWTS disk I/O with CP/M record deblocking |

The CCP and BDOS are **two independent compilations** (separate `.bin`s, concatenated
in RAM). On the correctly de-skewed source they are almost decoupled: the CCP calls
the BDOS only through the page-zero `$0005` ABI (`include/cpm22.inc`), and the only
direct cross-module symbols are the two module bases in `include/cpm_system_220.inc`
(`CCP_ENTRY=$9400`, `BDOS_FBASE=$9C00`). (The earlier "59 CCP→BDOS cross-refs" were
sector-skew artifacts and do not exist on the de-skewed source.)

`CPM_BootLoader.s` (6502) embeds two Z-80 blocks, each sub-assembled by sjasmplus and
`INCBIN`'d at its offset (the slot-probe handshake `CPM_BootLoader_ProbeOvl.asm` and
the console driver `CPM_BootLoader_ConInit.asm`). The BIOS contains no embedded
foreign code: its 6502 work is done by the Apple monitor ROM, reached through the
SoftCard RPC mailbox (`RPC_TRIGGER`, Apple `$03D0`).

Each Z-80 source carries `IFNDEF CPM_LINK / DEVICE NOSLOT64K / ORG <addr> / ENDIF` at
the top and `SAVEBIN "<out>", <addr>, <size>` at the bottom, so it assembles standalone
with **sjasmplus**. The 6502 boot loader assembles with **ca65/ld65**. Addresses and
machine bytes are kept in a generated `.lst` (`os/*.lst`, git-ignored), not inline —
see [`cpm_pipeline/os_listing.py`](../cpm_pipeline/os_listing.py).

## How the binaries are written to the boot tracks

The disk layout is declarative, in
[`cpm_pipeline/chunk_map.py`](../cpm_pipeline/chunk_map.py) (`SOURCES_220_44K` +
`_build_chunks_220_44k`). The producer assembles each source, then places 256-byte
slices at physical disk sectors:

1. **Boot stub — track 0.** `CPM_BootLoader` (`$0800–$13FF`) is laid down as 11
   sectors on track 0 (physical sectors `0,2,4,6,8,A,C,E,1,3,5` ← loader offsets
   `$0800–$1300`). Sector T0S0 is the `$C600`-PROM-loaded boot-0; it pulls in the rest
   of the loader, which loads the system tracks and starts the Z-80.

2. **CCP + BDOS — scattered across tracks 0–2.** The 22 contiguous runtime pages
   (`$9400–$A9FF`) are written back to the interleaved sectors the cold loader read
   them from. For each runtime page the producer looks up its `.dsk` *linear* sector
   `S` in `PAGE_TO_SECTOR`, then writes to `track = S // 16`, `physical sector =
   DOS33_INTERLEAVE⁻¹[S % 16]`. Pages `$9400–$9BFF` come from `CPM_CCP.asm`;
   `$9C00–$A9FF` from `CPM_BDOS.asm`.

3. **BIOS — track 2.** The 6 runtime pages (`$AA00–$AFFF`) are scattered the same way
   via `BIOS_PAGE_TO_SECTOR` (`.dsk` linear sectors 41–46, all on track 2).

4. **Filesystem (tracks 3+)** is carried verbatim from the reference image; it is not
   part of the OS build.

Sectors not written by any chunk keep their reference bytes, so the round-trip is
exact: *gather the de-skewed image, edit at runtime addresses, scatter back*
reproduces the disk byte-for-byte.

## Build and verify

```bash
# from the repo root
source shared/toolchain/env.sh          # puts ca65/ld65/sjasmplus on PATH (+ PYTHONPATH)

# rebuild the whole 2.20-44K disk from source and verify byte-identical:
python -m cpm_pipeline.reconstruct \
    softcard/reference/softcard-cpm-archive/.../softcard-cpm2.20-44k-system-1980.dsk \
    /tmp/cpm220_44k_rebuilt.dsk --variant 220-44k

# or run the gate (OS region + CCP/BDOS de-skew round-trip + full disk):
python -m pytest softcard/cpm_pipeline/tests/test_reconstruct.py -k 220_44k
```

(`reconstruct._detect_variant` auto-selects `220-44k` for this disk by the Z-80
reset-plant base `$AA00`, vs `$DA00` for the 2.20B-56K build.) `reconstruct_disk`
rebuilds just the OS region over a reference image; `reconstruct_full_disk` rebuilds
the whole disk (OS region from `os/`, every `.COM` from `utilities/`, only filesystem
data carried). Both assert **0 byte differences**. Without `env.sh` the assemblers are
off `PATH` and the byte-identical cases **skip** rather than fail — always confirm they
show PASSED. To (re)generate a component listing:
`python -m cpm_pipeline.os_listing softcard/CPMV220-44K/os/CPM_BIOS.asm --write`.

## Reverse-engineering conventions used here

- **C-level function headers** (Purpose / In / Out / Clobbers / Algorithm) on every
  routine; high-level body comments; semantic UPPER_SNAKE labels (zero machine labels).
- **Full relocatability**: every in-image operand is a LABEL, not a literal address.
- **Self-modifying code** that patches an instruction's operand keeps a semantic label
  on the instruction and references the patch site as `LABEL+1` / `LABEL+2` (e.g.
  `DEV_OUT_1_JP+1`). The DEFB-cover idiom (unlabeled `DEFB $xx` + the real instruction
  at its own clean label) is reserved for true skip idioms.
- **OBSERVED vs `[RE]` inference vs UNKNOWN** is marked explicitly; byte-identical
  reassembly is the floor, total semantic understanding is the goal.

## utilities/ — the .COM programs

**CPMV220-44K is the BASE source tree:** the utility `.asm` here are the single
source-of-record for every `.COM` byte-identical across the 44K releases, so the
2.23-44K tree carries only the utilities whose bytes differ. Each `.asm` reassembles
byte-identical to its disk `.COM` (gated by `test_utilities_roundtrip.py`; shared ones
cross-checked against the 2.23-44K disk).

| Group | Files |
|-------|-------|
| shared base (byte-identical on both 44K disks) | `APDOS ASM DOWNLOAD DUMP ED LOAD PIP STAT XSUB` |
| 2.20-44K-specific (bytes differ from 2.23-44K) | `CPM56` (SoftCard 56K-overlay installer), `DDT`, `SUBMIT`, `COPY`, `FORMAT`, `RW13` |
| BASIC masters | `BASIC.asm` → byte-identical to both `GBASIC.COM` (`DEFINE GBASIC`) and `MBASIC.COM` |

`COPY`, `FORMAT`, and `RW13` are 2.20-44K-specific (and `FORMAT`/`RW13` are absent from
2.23, which folded `FORMAT` into `COPY`); each embeds a 6502 disk engine extracted to a
sibling `<NAME>_6502.s` (ca65) and `INCBIN`'d back, byte-identical. `CONFIGIO.BAS` and
`DUMP.ASM` are genuine source-text files, carried verbatim as data.
