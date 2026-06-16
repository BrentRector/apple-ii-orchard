# Microsoft Z-80 SoftCard — CP/M on the Apple II

The **Microsoft SoftCard** is a Z-80 card for the Apple II that lets the machine
run CP/M-80: the Z-80 executes CP/M while the host 6502 keeps driving the Apple's
disk, keyboard, and screen. This tree is a complete reverse-engineering of that
system — how it boots, how the two CPUs cooperate, and what every byte on the
disk does — rendered as commented assembly that **reassembles byte-identically**
to the original disks, plus the tooling and a whole-system emulator.

Three releases are decompiled, each a self-contained folder (its OS source, every
`.COM` program, the disk image(s), and a master README with a one-command
byte-identical rebuild):

| Folder | CP/M | Disk(s) | What's distinct |
|--------|------|---------|-----------------|
| [`CPMV223-44K/`](CPMV223-44K/) | **2.23** (44K) | `CPMV223-44K.DSK` | the Videx-aware release; the basis for 60K |
| [`CPMV223-60K/`](CPMV223-60K/) | **2.23** (60K) | `CPMV223-60K.DSK` | CCP/BDOS relocated into the language card (≈55K TPA); built by `CPM60.COM` |
| [`CPMV220/`](CPMV220/) | **2.20** | `CPMV220-Disk1/2` (`.po`+`.dsk`) | the earlier, pre-Videx release; ships on two disks |

## How a SoftCard CP/M disk works

A 16-sector Apple floppy with a CP/M system on it has three layers:

- **Boot (track 0, sector 0).** The Disk II P6 ROM loads one standard sector to
  `$0800` and jumps in. From there the SoftCard's own **6502 boot loader** takes
  over: it pulls in the RWTS (the GCR sector engine) and runs `LOAD_CPM`, reading
  the staged Z-80 system (CCP + BDOS + BIOS) off the reserved **system tracks
  (0-2)** into memory.
- **CPU switch + cold boot.** The loader arms the SoftCard CPU switch and the
  Z-80 enters the BIOS, whose cold-boot routine scans the Apple slots and **builds
  the device/console handlers in RAM** (this is where the 2.23 Videx path lives;
  2.20 has none), plants the CP/M page-zero vectors, and drops to the `A>` prompt.
- **Filesystem (tracks 3+).** A standard CP/M 2.2 directory + the `.COM`/data
  files. A hidden `cp/m.sys` entry at user `$1F` reserves blocks `$80-$8B` — the
  mechanism `CPM60.COM` uses to protect the embedded 60K system on the data tracks.

The Z-80 sees Apple memory through the SoftCard's address translation (e.g. Z-80
`$E08B` → Apple I/O `$C08B`; `$Bxxx-$Dxxx` → the language card). The full story is
in the reference docs below — start with
[`CPM_BootTrace.md`](docs/CPM_BootTrace.md) and
[`CPM_Memory_Layout.md`](docs/CPM_Memory_Layout.md).

## Map of this tree

| Path | Contents |
|------|----------|
| [`CPMV223-44K/`](CPMV223-44K/) · [`CPMV223-60K/`](CPMV223-60K/) · [`CPMV220/`](CPMV220/) | The three release folders. Each holds `os/` (one canonical source set: boot loader, RWTS, install fragments, CCP/BDOS, BIOS), `utilities/` (one annotated `.asm` per `.COM`) + `utilities/bin/` (the assembled binaries), the disk image, a master **README**, and a **BOOT_AND_PATCHING.md**. |
| [`cpm_pipeline/`](cpm_pipeline/) | The toolchain package: detect → trace → decompile → reconstruct a `.dsk`/`.po`. See its [README](cpm_pipeline/README.md). |
| [`softcard_emu/`](softcard_emu/) | A reusable whole-system emulator — 6502 + Z-80 on one shared Apple memory bus, the CPU switch, a Disk II, a Videx Videoterm, and a language card. Boots an unmodified disk to `A>` and can run `CPM60.COM` to convert a disk to 60K. See its [README](softcard_emu/README.md). |
| [`src/`](src/) | Shared OS source: the CCP that builds the 44K *and* 60K systems from one file (two symbols). See its [README](src/README.md). |
| [`docs/`](docs/) | The analysis write-ups — the deep reference for the boot, memory map, filesystem, and the version deltas (indexed below). |
| [`cpm-investigation/`](cpm-investigation/) | The original extraction scripts and the intermediate region binaries the pipeline assembles against. |

## The toolchain — `python -m cpm_pipeline <verb>`

Given any SoftCard CP/M `.dsk`/`.po`, the pipeline verifies it, decompiles the OS
and the programs to commented assembly, and rebuilds a byte-identical image. Full
detail in [`cpm_pipeline/README.md`](cpm_pipeline/README.md); the design/roadmap
is in [`docs/CPM_PIPELINE_ROADMAP.md`](docs/CPM_PIPELINE_ROADMAP.md).

| Verb | What it does |
|------|--------------|
| `list-files <disk>` | Parse the CP/M directory; list every file with size + attributes. |
| `detect <disk>` | Format, boot-stub fingerprint, sector skew, CP/M variant + confidence. |
| `decompile-os <disk> <out>` | Reverse-engineer the whole OS into `out/auto/` (machine disassembly, both CPUs) and, for the 2.20/2.23 family, `out/gold/` (the byte-identical annotated source). |
| `decompile-file <disk> NAME.COM <out>` | Decompile one program (emulation-assisted; static fallback). Round-trips byte-identical. |
| `decompile-disk <disk> <out>` | Interactive, end-to-end: OS + a chosen program. `--select NAME` runs non-interactively. |
| `trace` / `trace-z80` / `handoff` / `diff` | Lower-level analyses: boot-loader trace, Z-80 cold-boot dispatch, the 6502→Z-80 handoff, and routine-level deltas between two disks. |
| `generate <disk> <out>` | A full annotated source tree + analysis reports + a `build.sh`. |

Add `--ai` to any decompile verb to layer in `[AI]` prose comments from Claude
(`claude-opus-4-8`, via the Claude Code CLI or `ANTHROPIC_API_KEY`); the comments
are assembler comments, so the source still reassembles byte-identically.

## Building & verifying a disk

Each release rebuilds **byte-identical from its committed sources**. From the repo
root with the toolchain on PATH (`source shared/toolchain/env.sh`):

```bash
# Whole 2.23 (44K) disk from os/ + utilities/bin/:
python -m cpm_pipeline.reconstruct softcard/CPMV223-44K/CPMV223-44K.DSK rebuilt.dsk
# Whole 2.20 disk:
python -m cpm_pipeline.reconstruct softcard/CPMV220/CPMV220-Disk1.po rebuilt.po
# The 60K installer (the 60K disk is this applied to a 44K disk):
python -c "from cpm_pipeline.build_cpm60 import build_cpm60_com, reference_com; \
import sys; sys.exit(0 if build_cpm60_com()==reference_com() else 1)"
```

Each exits 0 only on a byte-identical result; the same checks run in CI
(`test_reconstruct.py`, `test_build_cpm60.py`). Each release folder's README has
the per-disk details.

## Reference docs ([`docs/`](docs/))

| Doc | What it covers |
|-----|----------------|
| [`CPM_BootTrace.md`](docs/CPM_BootTrace.md) | End-to-end boot trace: P6 ROM → 6502 loader → `LOAD_CPM` → CPU switch → Z-80 cold boot. |
| [`CPM_BootLoader.md`](docs/CPM_BootLoader.md) | The 6502 boot loader in detail (install-copy logic, the staging read). |
| [`CPM_Memory_Layout.md`](docs/CPM_Memory_Layout.md) | The 44K and 60K memory maps + the Z-80↔Apple address translation. |
| [`CPM_Filesystem.md`](docs/CPM_Filesystem.md) | The CP/M 2.2 filesystem on tracks 3+ (directory, blocks, the `(L*3)%16` skew). |
| [`CPM_DiskSectorMap.md`](docs/CPM_DiskSectorMap.md) | Per-sector map of a 2.23 disk: which sector holds what. |
| [`CPM_44K_vs_60K_Differences.md`](docs/CPM_44K_vs_60K_Differences.md) | What actually changes between the 44K and 60K systems. |
| [`CPM_Videx_Difference.md`](docs/CPM_Videx_Difference.md) | The 2.20 → 2.23 Videx-detection delta (the cold-boot device dispatch). |
| [`CPM_SoftCard_RealMap_Findings.md`](docs/CPM_SoftCard_RealMap_Findings.md) | The real SoftCard address map + the corrected 2.20-hang analysis. |
| [`CPM_Disk_To_Source_Roundtrip.md`](docs/CPM_Disk_To_Source_Roundtrip.md) | The method: from an unknown disk to byte-identical source and back. |
| [`CPM_PIPELINE_ROADMAP.md`](docs/CPM_PIPELINE_ROADMAP.md) | The pipeline's design + roadmap. |

## Setup

```bash
source ../shared/toolchain/env.sh    # ca65 + ld65 + sjasmplus on PATH; packages on PYTHONPATH
# or:  pip install -e .   (from the repo root)
```

The disassembly + filesystem features are pure Python; reassembly/rebuild needs
the local assemblers (install per [`../shared/toolchain/README.md`](../shared/toolchain/README.md)).

## Scope and honest caveats

- **Variant recognition** is structural (boot-stub signature + skew + fingerprint);
  it knows the SoftCard 2.20/2.23 family with high confidence and flags anything else.
- **OS decompilation** is byte-identical for the recognized family; for an unknown
  variant the auto path is best-effort.
- **`.COM` decompilation** is emulation-assisted with a static fallback. Programs
  that block on interactive console I/O trace shallowly (more data, less code), but
  the output always round-trips byte-identical.
- **The `--ai` layer** degrades gracefully when no Claude backend is available —
  the deterministic, byte-identical output is produced regardless.
