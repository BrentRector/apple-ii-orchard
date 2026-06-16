# CP/M-80 — Microsoft SoftCard reverse-engineering toolchain

This tree reverse-engineers Microsoft SoftCard CP/M for the Apple II: how it
boots, how the 6502 and Z-80 cooperate, and what every byte on the disk does.
The [`cpm_pipeline`](cpm_pipeline/) package is the toolchain — given a `.DSK`/`.po`
image it will **verify** the disk, **decompile** the entire operating system
(6502 *and* Z-80) and any program in the filesystem into commented assembly, and
**rebuild** a byte-identical disk from that source.

Fully decompiled, AI-annotated distributions of **both** releases — CP/M **2.23**
(`CPMV223-44K.DSK`) and **2.20** (`CPMV220-Disk1.po`): boot loader, RWTS, BIOS, CCP/BDOS,
and every `.COM` utility, plus one-command byte-identical rebuilds — live in
[`decompiled/`](decompiled/).

## Setup

```bash
source ../shared/toolchain/env.sh    # ca65 + ld65 + sjasmplus on PATH, packages on PYTHONPATH
# or:  pip install -e .   (from the repo root)
```

The disassembly and filesystem features are pure Python. Reassembly / rebuild
needs the local assemblers (`ca65`, `ld65`, `sjasmplus`) — install per
[`../shared/toolchain/README.md`](../shared/toolchain/README.md).

## The toolchain — `python -m cpm_pipeline <verb>`

### Decompilation (the high-level flow)

| Verb | What it does |
|------|--------------|
| `decompile-disk <disk> <out>` | **Interactive, end-to-end.** Verify the disk is SoftCard CP/M → decompile the whole OS → list the filesystem → pick a program → decompile it to Z-80 source. `--select NAME` (repeatable) runs non-interactively. |
| `decompile-os <disk> <out>` | Reverse-engineer the entire OS into `out/auto/` (machine disassembly of every region, 6502 + Z-80, jump tables seeded, symbol tables applied) and, for the recognized 2.20/2.23 family, `out/gold/` (the hand-annotated, byte-identical source). |
| `decompile-file <disk> NAME.COM <out>` | Decompile one program to Z-80 source. **Emulation-assisted**: the program runs under the Z-80 core with a CP/M BDOS shim so runtime-only code paths are discovered, then fed to the disassembler (static fallback if emulation finds nothing). Output round-trips byte-identical. |
| `list-files <disk>` | Parse the CP/M 2.2 directory (tracks 3+) and list every file with size and attributes. |

Add `--ai` to any decompile verb to layer in machine-generated prose comments
(marked `[AI]`) from Claude `claude-opus-4-8`. With **no API key**, `--ai` uses the
**Claude Code** CLI (`claude -p`), which authenticates through Claude Code; with an
`ANTHROPIC_API_KEY` it can use the Anthropic API instead. Pick explicitly with
`--ai-backend {auto,cli,api}` (default `auto` prefers the CLI). If neither backend
is available the layer is skipped and the deterministic output is produced as usual.
The comments are inserted as assembler comments, so the source still reassembles
byte-identically.

### Analysis + rebuild (the lower-level stages)

| Verb | What it does |
|------|--------------|
| `detect <disk>` | Format, boot-stub fingerprint, sector skew, CP/M variant + confidence. |
| `trace <disk>` | Boot-loader trace: install-copies + disk-helper calls. |
| `trace-z80 <bios>` | Z-80 BIOS: jump table, trap pages, cold-boot generator + dispatch. |
| `handoff <disk>` | The 6502→Z-80 handoff: planted vectors + CPU-switch trigger. |
| `diff <a> <b>` | Routine-level delta between two CP/M disks. |
| `generate <disk> <out>` | Full annotated source tree + analysis + `build.sh`. |
| `build {220\|223} --reference <disk> --output <out> [--verify]` | Reassemble the OS sources and reconstruct a **byte-identical** image. `--source-dir DIR` assembles the OS `.asm` from `DIR` instead of `docs/`. |

## Example

```bash
source ../shared/toolchain/env.sh
python -m cpm_pipeline list-files     CPMV223-44K/CPMV223-44K.DSK
python -m cpm_pipeline decompile-disk CPMV223-44K/CPMV223-44K.DSK /tmp/out        # interactive
python -m cpm_pipeline decompile-file CPMV223-44K/CPMV223-44K.DSK CPM60.COM /tmp/cpm60 --ai
python -m cpm_pipeline build 223 --reference CPMV223-44K/CPMV223-44K.DSK --output /tmp/rebuilt.dsk --verify
# → BYTE-IDENTICAL to CPMV223-44K/CPMV223-44K.DSK
```

## What's in this tree

| Path | Contents |
|------|----------|
| [`cpm_pipeline/`](cpm_pipeline/) | The toolchain package (detect/trace/decompile/build). See its [README](cpm_pipeline/README.md). |
| [`softcard_emu/`](softcard_emu/) | Reusable whole-system emulator (subsystem architecture around a central memory bus): 6502 + Z-80 share one Apple memory image; boots the 44K/56K/60K configurations to the `A>` prompt and can run `CPM60.COM` to convert a disk to 60K. See its [README](softcard_emu/README.md). |
| [`cpm-investigation/`](cpm-investigation/) | The original extraction scripts and the intermediate region binaries the pipeline assembles against. |
| [`docs/`](docs/) | The hand-annotated, byte-identical `CPM*.asm` sources and the analysis write-ups (`CPM_*.md`). |
| [`disks/`](disks/) | The disk images: `CPMV223-44K.DSK` (2.23, 44K), `CPMV223-60K.DSK` (the same after `CPM60`, from a real Apple), `CPMV220-Disk1.po` / `CPMV220-Disk2.po` (2.20, 56K). `CPMV223-60K-EMU.DSK` is the emulator-produced 60K disk (regenerable). |
| [`decompiled/`](decompiled/) | Fully decompiled, AI-annotated distributions of both releases (`CPMV223-44K` + `CPMV220`) + one-command byte-identical rebuilds. |

## Scope and honest caveats

- **Verification** is structural (boot-stub signature + skew table + variant
  fingerprint). It recognizes the SoftCard CP/M 2.20 and 2.23 family with high
  confidence; an unrecognized variant is flagged and handled best-effort.
- **OS-region segmentation** is gold for the recognized 2.20/2.23 family; for an
  unknown variant the auto path is best-effort.
- **`.COM` decompilation** is emulation-assisted with a static fallback. Programs
  that block on real hardware / interactive console I/O (e.g. `MBASIC`, `ED`)
  trace shallowly under the non-interactive BDOS shim, so they come out as mostly
  data — the code/data split is best-effort, but the output always round-trips.
- **The `--ai` layer** uses the Claude Code CLI when available (no API key) or the
  Anthropic API with `ANTHROPIC_API_KEY`; it degrades gracefully if neither is present.
