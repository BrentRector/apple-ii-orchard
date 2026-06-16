# Orchard

I always wanted to know how Apple II copy protection actually worked.

Back in the day, I knew certain disks couldn't be copied — you'd run COPYA or Locksmith and the copy would just fail, or worse, it would seem to work and then crash on boot. The protection was down in the disk format itself, in the way bits were laid down on the magnetic surface, but I never understood the specifics. What exactly was different about those bits? What did the boot code do that was so clever? Why couldn't the copiers handle it?

Recently, after restoring a vintage Apple ][+ to better-than-original condition, I found a [WOZ file](https://applesaucefdc.com/woz/) of *Apple Panic* — one of my favorite idle timewasters from back in the day — captured at the magnetic flux level by modern hardware. A WOZ file preserves everything about the original disk: every bit pattern, every non-standard marker, every copy protection trick, exactly as it existed on the physical media. Unlike a `.dsk` image, which stores only the decoded sector data, a WOZ file gives you the raw magnetic flux stream that the drive read head would actually detect.

I started poking at it. How does this disk boot? What format are the sectors in? Why does it look so weird compared to a standard DOS 3.3 disk?

One thing led to another. I built a WOZ parser, then a GCR decoder, then a full 6502 CPU emulator, then a Disk II disk drive emulator, then a boot tracer. I hit dead ends — spent hours debugging a checksum failure that turned out to be in my own tooling, not the disk. I discovered nine distinct layers of copy protection, each one defeating a different class of copy tool. I traced 69.8 million emulated CPU instructions from power-on to game start.

That first investigation grew into a second one — the Microsoft SoftCard, the Z-80 card that let an Apple II run CP/M — and the tooling I'd built for 6502 disks turned out to be the foundation for understanding a whole different CPU on the same hardware. This repo is the result of both.

## Highlights

A few pieces of this repo stand on their own:

- **Complete, rebuildable source for two CP/M boot disks.** [`softcard/decompiled/`](softcard/decompiled/) holds the *entire* Microsoft SoftCard CP/M operating system for both **version 2.20** and **version 2.23** — boot loader, RWTS, BIOS, CCP, and BDOS — rendered as commented assembly, alongside every `.COM` utility in each disk's filesystem (20 programs on the 2.23 disk, 11 on 2.20: the Digital Research tools plus the Microsoft/SoftCard additions). It all reassembles to **byte-identical** disk images, proven by `rebuild.sh`. This is the artifact the whole CP/M investigation was built to produce.
- **A whole-system SoftCard emulator.** [`softcard/softcard_emu/`](softcard/softcard_emu/) boots an unmodified CP/M `.dsk` to an interactive `A>` prompt — 6502 and Z-80 on one shared memory bus, the SoftCard's address translation and CPU switch, a Disk II, a Videx Videoterm, and a language card. It reproduces the historical 2.20-with-Videx hang fault-for-fault, boots the 44K / 56K / 60K builds, and even runs `CPM60.COM` itself to relocate a system into the language card.
- **Apple Panic, fully reverse engineered.** [`apple-ii/apple-panic/`](apple-ii/apple-panic/) — nine layers of copy protection defeated, the boot traced across ~70 million emulated instructions, and the game extracted into ~8,800 lines of commented 6502 assembly.
- **The tooling underneath it all.** A from-scratch WOZ/DSK toolkit with full 6502 and Z-80 emulators ([`nibbler`](shared/nibbler/)), ca65/sjasmplus-compatible round-tripping disassemblers for both CPUs, and a `.DSK` → annotated-source decompilation pipeline ([`cpm_pipeline`](softcard/cpm_pipeline/)).

## Repository layout

The project is organized into three top-level trees:

| Tree | Contents |
|------|----------|
| [`apple-ii/`](apple-ii/) | Apple II reverse-engineering work — the Apple Panic game RE, the investigation scripts, and Apple-specific reference docs |
| [`softcard/`](softcard/) | CP/M-80 / Microsoft SoftCard work — the complete decompiled source for the 2.20 and 2.23 boot disks, the boot-pipeline investigation, the reconstruction pipeline, the whole-system emulator, CP/M docs, and the disk images |
| [`shared/`](shared/) | Reusable tooling used by both — the `nibbler` disk toolkit, the 6502 / Z-80 disassemblers, symbol tables, and the local assembler toolchain |

```
apple-ii/
  apple-panic/    game RE: WOZ, disassembly, assets, write-ups
  scripts/        ~38 investigation scripts (working artifacts)
  docs/           Disk II P6 Boot ROM reference
softcard/
  decompiled/         complete rebuildable source for the 2.20 + 2.23 boot disks
  cpm-investigation/  extraction scripts + intermediate binaries
  cpm_pipeline/       productized detect → trace → reconstruct pipeline
  softcard_emu/       reusable whole-system SoftCard emulator
  docs/               CPM*.asm (annotated source) + CPM_*.md (analysis)
  disks/              CPMV233.DSK, CPM220Disk{1,2}.po, CPMV233-60K.DSK
shared/
  nibbler/        WOZ/DSK toolkit + 6502 and Z-80 emulators
  disasm6502/     6502 disassembler (ca65-compatible, round-trips)
  disasm_z80/     Z-80 disassembler (sjasmplus-compatible, round-trips)
  disasm_common/  shared disassembly analyzer
  symbols/        JSON symbol tables (apple2, cpm_2_2, cpm_2_23_bios)
  toolchain/      env.sh + smoke tests (local cc65/sjasmplus install)
```

## Setup

The Python packages (`nibbler`, `cpm_pipeline`, `softcard_emu`, `disasm6502`, …) live inside the three trees but are imported by their bare names. Pick either mechanism to make them resolvable:

```bash
# Option A — no install. Also puts ca65/ld65/sjasmplus on PATH.
source shared/toolchain/env.sh

# Option B — editable install into your environment.
pip install -e .
```

The test suite needs neither (a repo-root `conftest.py` handles `sys.path` during collection):

```bash
python -m pytest        # 109 passed, 24 skipped without the assembler toolchain
                        # 133 passed once `source shared/toolchain/env.sh` is active
```

## Games

### [Apple Panic](apple-ii/apple-panic/) (Broderbund, 1981)

![Apple Panic Instructions](apple-ii/apple-panic/ApplePanicInstructions.png)

A platformer with **nine layers of copy protection** — dual-format tracks, GCR table corruption, self-modifying code, non-standard address markers, and more. Fully reverse engineered: boot traced, all protection defeated, game binary extracted and disassembled into ~8,800 lines of commented assembly.

The reverse engineering follows a chain of discovery: each protection layer, once defeated, reveals what to investigate next. The Disk II P6 ROM loads one standard boot sector — after that, the software on the disk is in charge, and the nine protection layers activate one by one as the boot progresses through five stages and ~70 million emulated instructions.

- **[Walkthrough](apple-ii/apple-panic/Walkthrough.md)** — Step-by-step guide: what to do, in what order, what each step reveals, and what protection technique each step defeats
- **[The Full Story](apple-ii/apple-panic/ReverseEngineeringHistory.md)** — The investigation narrative, including dead ends and breakthroughs
- **[Copy Protection Reference](apple-ii/apple-panic/CopyProtection.md)** — Technical analysis of all 9 protection layers

## nibbler — WOZ Disk Analysis Toolkit

[`shared/nibbler/`](shared/nibbler/) is a reusable Python package for analyzing Apple II WOZ disk images. Works on any WOZ2 file.

```
python -m nibbler <command> <woz_file> [options]
```

| Command   | Purpose                                            |
|-----------|----------------------------------------------------|
| `info`    | Show WOZ metadata, track map, half-track data      |
| `scan`    | Scan tracks for encoding type, sector counts, checksums |
| `protect` | Detect copy protection techniques, generate report |
| `nibbles` | Dump raw nibbles for a track with optional byte highlighting |
| `boot`    | Emulate 6502 boot process, capture memory at stop point |
| `decode`  | Decode specific track/sector to hex dump or binary |
| `dsk`     | Convert WOZ to standard 140K DSK image             |
| `flux`    | Render magnetic flux patterns as a grayscale PNG   |

For 6502 / Z-80 disassembly, see the standalone packages [`shared/disasm6502/`](shared/disasm6502/) and [`shared/disasm_z80/`](shared/disasm_z80/). Both produce ca65/sjasmplus-compatible source that round-trips byte-identical.

**11 modules:** WOZ2 parser, GCR 6-and-2 / 5-and-3 codec with auto-detection of non-standard address prologs, full NMOS 6502 emulator (all 256 opcodes including 29 undocumented), Disk II controller simulation with stepper motor and I/O tracing, boot emulation framework, copy protection analyzer, DSK converter, and magnetic flux visualizer.

No external dependencies for core functionality. Python 3.10+. The `flux` command additionally requires numpy and Pillow (`pip install -e .[flux]`).

See [`shared/nibbler/USAGE.md`](shared/nibbler/USAGE.md) for detailed usage with examples.

### Quick Start

```bash
# What's on a disk?
python -m nibbler info "apple-ii/apple-panic/Apple Panic - Disk 1, Side A.woz"

# Scan for encoding and checksums
python -m nibbler scan "apple-ii/apple-panic/Apple Panic - Disk 1, Side A.woz"

# Detect copy protection techniques
python -m nibbler protect "apple-ii/apple-panic/Apple Panic - Disk 1, Side A.woz"

# Visualize the magnetic flux patterns
python -m nibbler flux "apple-ii/apple-panic/Apple Panic - Disk 1, Side A.woz"

# Boot-trace and extract the game binary
python -m nibbler boot "apple-ii/apple-panic/Apple Panic - Disk 1, Side A.woz" \
    --stop 0x4000 --dump 0x4000-0xA7FF --save game.bin

# Disassemble the extracted binary (use the standalone disasm6502 package)
source shared/toolchain/env.sh   # puts ca65 + ld65 on PATH and packages on PYTHONPATH
python -m disasm6502 game.bin --org $4000 --entry $4000 \
    --symbols shared/symbols/apple2.json --output game
ca65 game.s -o game.o && ld65 -C game.cfg -o game.bin game.o
```

## CP/M-80 (Microsoft SoftCard)

The [`softcard/`](softcard/) tree investigates how Microsoft SoftCard CP/M boots on an Apple II, why version 2.20 hangs where 2.23 runs, and how the Videx Videoterm 80-column support was added. The [`cpm_pipeline`](softcard/cpm_pipeline/) package turns a CP/M disk image into an annotated, reassemble-to-byte-identical source tree; [`softcard_emu`](softcard/softcard_emu/) is a reusable whole-system emulator (6502 + Z-80 sharing one Apple memory image). See [`softcard/docs/`](softcard/docs/) for the analysis write-ups.

```bash
source shared/toolchain/env.sh
python -m cpm_pipeline detect softcard/disks/CPMV233.DSK
python -m softcard_emu softcard/disks/CPMV233.DSK --keys "DIR\r"
```

### Decompiled distributions

[`softcard/decompiled/`](softcard/decompiled/) is the headline deliverable: the complete source for **both** boot disks (CP/M 2.20 and 2.23), each rendered as commented assembly and organized identically —

```
decompiled/
  CPMV233/   CP/M 2.23  — os/ (boot loader, RWTS, BIOS, CCP+BDOS) + utilities/ (20 .COM programs)
  CPM220/    CP/M 2.20  — os/ (boot loader, RWTS, BIOS, CCP+BDOS) + utilities/ (11 .COM programs)
  rebuild.sh verify_roundtrip.py generate_distribution.py
```

Every source file reassembles to the original bytes, and `rebuild.sh` reconstructs each disk image byte-for-byte. Diffing the two `os/CPM_BIOS.asm` files is exactly where the 2.20 → 2.23 Videx fix becomes visible. See [`softcard/decompiled/README.md`](softcard/decompiled/README.md).

```bash
source shared/toolchain/env.sh
bash softcard/decompiled/rebuild.sh CPMV233      # -> byte-identical CPMV233.DSK
python softcard/decompiled/verify_roundtrip.py   # reassemble every file, both releases
```

### Decompilation toolchain

Given a `.DSK`, the pipeline verifies it's a SoftCard CP/M disk, reverse-engineers the entire OS (6502 + Z-80) into commented assembly, lists the CP/M filesystem, and decompiles a chosen `.COM` program to Z-80 source. See [`cpm_pipeline/README.md`](softcard/cpm_pipeline/README.md#decompilation-toolchain).

```bash
source shared/toolchain/env.sh
python -m cpm_pipeline list-files     softcard/disks/CPMV233.DSK
python -m cpm_pipeline decompile-os   softcard/disks/CPMV233.DSK out_os
python -m cpm_pipeline decompile-disk softcard/disks/CPMV233.DSK out   # interactive: verify → OS → pick a file → decompile it
```

Add `--ai` to layer in machine-generated prose comments via Claude (`claude-opus-4-8`; needs `ANTHROPIC_API_KEY`).

## Other Resources

### [`apple-ii/scripts/`](apple-ii/scripts/) — Investigation Scripts

The ~38 Python scripts written during the Apple Panic investigation. Each one represents a question that was asked — and answered or abandoned. Preserved as-is: working artifacts, not polished tools. See [`apple-ii/scripts/README.md`](apple-ii/scripts/README.md) for a complete guide.

### [`apple-ii/docs/`](apple-ii/docs/) — Apple II Reference

| Document | Description |
|----------|-------------|
| [DiskII_BootROM.md](apple-ii/docs/DiskII_BootROM.md) | Apple II Disk II P6 Boot ROM documentation |
| [DiskII_BootROM.asm](apple-ii/docs/DiskII_BootROM.asm) | Fully disassembled and commented P6 Boot ROM |

## License

The investigation scripts, nibbler package, documentation, and analysis are original work.

Game disk images and binaries are included for research and preservation purposes. All game copyrights belong to their respective owners.
