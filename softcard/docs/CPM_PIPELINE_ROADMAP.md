# CP/M Pipeline Toolset — Roadmap

The future-tool vision laid out in [`CPM_BootTrace.md`](./CPM_BootTrace.md)
calls for a toolset that takes a CP/M `.dsk` (or WOZ) image as input and
produces:

- A per-sector → memory-address map (which disk byte ends up where in RAM)
- Fully-commented disassembled source files (ca65 / sjasmplus syntax)
- A reassembled binary chain that round-trips byte-identical
- A reconstructed `.dsk` image, also byte-identical to the original

In short: feed in a CP/M disk; get back a fully-understood, modifiable
source tree plus a verified rebuild.

This roadmap turns that vision into a buildable plan. The seven stages
from `CPM_BootTrace.md` are reproduced here as concrete deliverables in
**recommended build order** with rationale and scope.

---

## Recommended order

The order optimizes for **closing the loop quickly with existing assets**,
then progressively automating the manual steps from inside-out:

| Order | Stage | Why this order |
|---|---|---|
| 1 | **Stage 7 — `.dsk` reconstruction** | Closes the loop end-to-end with existing manually-annotated sources; biggest psychological + functional payoff for least new work |
| 2 | **Stage 1 — Disk-format detection** | Foundation everything else depends on; generalizes the tool from "works on the disks we know" to "works on any CP/M disk" |
| 3 | **Stage 2 — Boot-loader tracing** | The biggest single new capability; automates the per-sector → memory map that's currently in [`CPM_DiskSectorMap.md`](./CPM_DiskSectorMap.md) |
| 4 | **Stage 5 — Z-80 cold-boot tracing** | Extends Stage 2's control-flow tracing across the SoftCard handoff into Z-80 land; requires modeling the cooperative-CPU disk loop |
| 5 | **Stage 4 — Handoff identification** | Connects 6502 trace (Stage 2) with Z-80 trace (Stage 5); identifies the CPU-switch trigger automatically |
| 6 | **Stage 3 — Version delta detection** | Identifies version-specific modifications (e.g., the 11-byte Pascal-1.1 branch) by comparing against a canonical baseline |
| 7 | **Stage 6 — Annotated source generation** | The orchestration layer that pulls Stages 2-5 together and emits the deliverable |

This order delivers a working tool at each phase. After Phase 1 you can
take any disk in the existing manual catalog and round-trip it; after
Phase 2-3 you can do that for unknown disks; after Phases 4-7 the
annotated output approaches the quality of the current hand work.

The "manual fallback at each stage" principle: at every phase, the tool
should accept manual hints (CLI flags, config files) for whatever it
can't yet automate. This way you can always make progress on a new disk
even before the relevant stage is fully automated.

---

## Phase 1 — Stage 7: `.dsk` reconstruction

**Goal.** Given a list of `(binary_file, sector_layout)` tuples, produce a
`.dsk` file that's byte-identical to the original it was extracted from.

**Why first.**

- It uses **only existing assets**: the 11 manually-annotated source
  files all round-trip byte-identical to their constituent binaries via
  the existing harness. The missing piece is composing those binaries
  back into a disk image.
- It validates the whole architecture end-to-end with the smallest new
  surface area. After Phase 1, "I changed a comment in
  CPM223_BIOS.asm" produces a verified rebuilt disk.
- It surfaces format issues early (sector ordering, fill bytes between
  binaries, the boot stub's special `$0800` byte) without the
  complications of automated tracing.

**Deliverables.**

- New module `softcard/cpm_pipeline/disk_writer.py` (or similar). Inverse of
  the format-reading code in nibbler.
- CLI tool: `python -m cpm_pipeline build-dsk <chunk-list> <output.dsk>`.
- Update `softcard/cpm-investigation/build_dsk.py` to use the new module
  (it already documents the intended pipeline; replace the
  fallback-to-pre-extracted-bin path with one that genuinely assembles
  + reconstructs).
- Round-trip test: build CPMV220Disk1.po and CPMV223-44K.DSK from their
  manually-annotated sources, byte-compare against originals.

**Scope estimate.** 1-2 sessions. The write side of the format is
significantly simpler than the read side because we already know the
layout; we don't need to detect anything.

**Risk.** Low. Disk format inversion is mechanical. The only nuance is
DOS 3.3 vs ProDOS sector ordering on the `.dsk` side, both of which
nibbler already understands on the read side.

---

## Phase 2 — Stage 1: disk-format detection

**Goal.** Given an unknown `.dsk` or WOZ image, automatically determine:

- GCR encoding (6-and-2 vs 5-and-3)
- Address-prolog bytes (custom prologs are a copy-protection technique)
- CP/M sector skew (the boot loader's per-iteration sector number table)
- Number of sectors per track
- Sector ordering convention (DOS 3.3 vs ProDOS vs CP/M-physical)

Output: a metadata file describing the disk's layout that Stages 2-7
can consume without re-detecting.

**Why second.**

- It's the foundation. Every later stage assumes you can read the disk
  correctly. Without Stage 1, Stage 2 has nothing to disassemble.
- nibbler's existing format detection is good but specific to known
  disks. Generalizing it surfaces edge cases that other CP/M vendors
  (or earlier Microsoft revisions) might use.

**Deliverables.**

- Extended `nibbler.gcr.auto_detect_address_prologs()` to also detect
  the data prolog, sector count, and sector ordering.
- New `softcard/cpm_pipeline/disk_format.py` that produces a structured
  `DiskFormat` object capturing all detected parameters.
- CLI tool: `python -m cpm_pipeline detect-format <disk.dsk>`.
- Test corpus: at minimum the two SoftCard CP/M disks (2.20, 2.23)
  plus a couple of known-good standard 6-and-2 disks.

**Scope estimate.** 2-3 sessions. The format-detection logic is
straightforward; the work is in building a robust test corpus and
handling format variations.

**Risk.** Medium. CP/M-side disks may use formats nibbler hasn't seen.
Mitigation: start with the two known SoftCard disks; the tool can
require a manual `--format-hint` flag when detection fails, and
each new format detected becomes a regression case.

---

## Phase 3 — Stage 2: boot-loader tracing

**Goal.** Given a disk with detected format, disassemble the boot stub,
follow control flow through stage 2, and output a per-sector →
memory-address map.

This is the biggest single new capability. It automates what
[`CPM_DiskSectorMap.md`](./CPM_DiskSectorMap.md) does manually.

**Why third.**

- It's the foundation of the actual reverse engineering. Once you know
  which sector ends up at which address at which point in the boot
  sequence, the rest of the pipeline can produce annotated source for
  every region.
- All later stages (handoff, Z-80 cold boot, source generation) can
  consume this output as a structured artifact.

**Deliverables.**

- New module `softcard/cpm_pipeline/loader_trace.py`.
- Identifies the boot stub at `$0801`, follows the P6 PROM
  re-entry pattern (`JMP ($003E)` to `$Cn5C` and back), tracks the
  sector counter and skew table, builds a sector-load schedule.
- Identifies stage-2 entry, install copies, LOAD_CPM call.
- Output: a structured `LoadSchedule` object: `[(sector_id,
  source_disk_offset, dest_apple_addr, dest_z80_addr, copy_phase)]`.
- CLI: `python -m cpm_pipeline trace-loader <disk.dsk>` produces a
  human-readable map plus the structured artifact for consumption by
  later stages.

**Scope estimate.** 3-5 sessions. This is the meat of the new work.
The control-flow tracing reuses `disasm6502`'s walker but needs
extensions for indirect control flow patterns specific to boot
loaders (`JMP ($XXXX)`, P6 PROM re-entry, runtime-computed jump
targets).

**Risk.** Medium-high. Boot loaders use indirect control flow heavily
because they're patching themselves and reusing the P6 PROM. Some
patterns may require **symbolic execution** rather than pure recursive
descent — track register/zero-page values across instructions to
resolve indirect targets. Mitigation: start with patterns that
recursive descent handles, add symbolic execution incrementally.

---

## Phase 4 — Stage 5: Z-80 cold-boot tracing

**Goal.** Extend Stage 2's control-flow tracing across the SoftCard
handoff into the Z-80 cold-boot generator. Output: a runtime BIOS
layout (which addresses hold static code, which hold runtime-generated
code, which trap-marker pages get populated by which generator
dispatch case).

**Why fourth.**

- It mirrors Stage 2 on the Z-80 side. Same algorithmic shape (recursive
  descent + symbolic state tracking) but over `disasm_z80` and the
  cooperative-CPU disk loop.
- It's the piece the existing emulator pass [Part 11](https://wiseowl.com/articles/cpm-videx-11-emulator-verified)
  built but didn't generalize. The plumbing is there; this stage makes
  it pipeline-callable.
- Required for the toolset to handle disks where the Z-80 side has
  more elaborate runtime population (CP/M-86, CP/M Plus, etc.).

**Deliverables.**

- New module `softcard/cpm_pipeline/z80_trace.py`.
- Reuses `disasm_z80`'s walker; adds the cooperative-CPU model as an
  oracle for cross-CPU calls.
- Output: a `RuntimeBiosLayout` object mapping each Z-80-visible
  address to one of: static-from-disk, runtime-generated-by-X, or
  state-slot.
- CLI: `python -m cpm_pipeline trace-z80 <disk.dsk>`.

**Scope estimate.** 2-3 sessions plus modeling the bidirectional CPU
switch (one of the two unknowns in [Part 12](https://wiseowl.com/articles/cpm-videx-12-the-investigation-closes)).

**Risk.** Medium. Most of the Z-80 disasm machinery exists; the new
risk is modeling the cooperative-CPU loop in a way that lets the
trace cross from Z-80 back to 6502 and back.

---

## Phase 5 — Stage 4: handoff identification

**Goal.** Automatically identify the SoftCard CPU-switch trigger
(`JSR $0E36` or equivalent), the warm-boot routine, and the planted
Z-80 reset/BDOS vectors.

**Why fifth.**

- Connects Stage 2 (6502 trace) and Stage 5 (Z-80 trace) into one
  story. Without this, the two traces are isolated.
- It's a small, well-defined piece. Pattern-match for the SoftCard's
  characteristic instruction sequences (LC bank protocol, then
  `JSR $XX36` where `$XX` matches the cooperative-CPU sync polling
  loop's address).

**Deliverables.**

- New module `softcard/cpm_pipeline/handoff.py`.
- Pattern-match for known handoff signatures: SoftCard
  (`JSR $0E36` after LC bank-in), CompuPro Disk 1+ alternate, etc.
- Output: a `HandoffPoint` object describing where and how the CPU
  switch happens.

**Scope estimate.** 1-2 sessions. Pattern-matching is straightforward.
The harder work is cataloging the variants that actually exist on
SoftCard-era CP/M disks.

**Risk.** Low. The mechanism is well-understood for SoftCard; other
CP/M variants have their own switch patterns that can be added as
detected.

---

## Phase 6 — Stage 3: version delta detection

**Goal.** Compare a disk against a canonical baseline (e.g., the
"reference" CP/M 2.2 BDOS) and identify the modifications a particular
vendor or version applied. Specifically the 11-byte Pascal-1.1 branch
that distinguishes 2.23 from 2.20.

**Why sixth.**

- This is the *useful* output for someone who wants to know "what did
  Microsoft change in 2.23 vs 2.20" or "what does this third-party
  patch do." The cpm-videx investigation answered that question
  manually for one specific delta; the tool would automate it for any
  pair.
- Requires the prior stages to have identified comparable regions
  (e.g., "the slot scanner") so the delta can be expressed at the
  routine level rather than as a raw byte diff.

**Deliverables.**

- New module `softcard/cpm_pipeline/version_delta.py`.
- Takes two disk analyses (output of Phase 5) and produces a
  structured diff: which routines are byte-identical, which differ,
  what the differences look like at the instruction level.
- Bonus: maintain a library of known patches/deltas with their
  semantic meaning ("this 11-byte sequence is the Pascal-1.1
  detection branch") so the tool can name what it sees.

**Scope estimate.** 2-3 sessions. The diff machinery is
straightforward; the harder part is naming what's different in a way
that's useful for a human reading the report.

**Risk.** Low-medium. Diffing arbitrary disks may produce noisy
output if the regions don't line up cleanly. Mitigation: anchor
the diff at function/routine boundaries identified by Stages 2-5.

---

## Phase 7 — Stage 6: annotated source generation

**Goal.** Orchestrate Stages 1-5's outputs into a complete, compilable,
round-tripping source tree for the entire disk.

**Why last.**

- It's the orchestration layer. Most of the work is wiring the prior
  stages together and emitting `.asm` / `.cfg` files in the right
  places.
- The disasm packages already emit clean source per chunk; this stage
  splits the disk into chunks (per Stage 2's load schedule), runs the
  appropriate disassembler with the appropriate symbol tables, and
  glues together the output with a top-level Makefile (or Python
  build script).

**Deliverables.**

- New module `softcard/cpm_pipeline/generate.py`.
- CLI: `python -m cpm_pipeline annotate <disk.dsk> <output_dir>`.
- Produces a directory with: per-chunk `.asm` files (regenerated each
  run from current symbol tables + walker output), a top-level build
  script that runs ca65/ld65/sjasmplus + the new Phase 1
  `.dsk` reconstruction.
- Default symbol tables ship with the tool; user-provided ones via
  `--symbols` extend them.

**Scope estimate.** 1-2 sessions. Most of the heavy lifting is in
prior phases.

**Risk.** Low. By the time this phase starts, the components have all
been built; this is plumbing.

---

## Architectural decisions

A few cross-cutting choices to lock in early:

**Where the new code lives.** A new top-level package `cpm_pipeline/`
at the repo root, parallel to `disasm6502/` and `disasm_z80/`. It
imports from the disasm packages, the symbol-table loader, and
nibbler's GCR/disk machinery. It does NOT modify those packages —
they stay focused.

**Pipeline as a library + a CLI.** Each stage is a Python module
that other stages can import. The CLI surface (`python -m cpm_pipeline
<verb> ...`) is for end users; internally the stages call each other
as functions.

**Intermediate artifacts as JSON.** Each stage emits a JSON file
describing its output (`disk_format.json`, `load_schedule.json`,
`runtime_layout.json`, `version_delta.json`, etc.). This lets you run
stages independently, debug intermediate state, and lets the user
override any stage's output by hand-editing its JSON before the next
stage consumes it. (Same pattern as `shared/symbols/*.json`.)

**Format support: `.dsk` and WOZ both.** Accept either as input. nibbler
already converts WOZ to nibble streams; the pipeline normalizes
internally and emits to whichever format the user requests.

**Symbol tables: ship a default set, accept extensions.** The default
covers standard CP/M 2.x conventions (BIOS jump table layout, BDOS
function numbers, zero page) and Apple II conventions for SoftCard
disks. Users add `--symbols my_custom.json` for vendor-specific labels.
The current `shared/symbols/` files are the starting set.

**Manual hints at every stage.** If automatic detection fails (or the
user wants to override it), every stage accepts CLI flags or a
config-file overlay that can specify its outputs directly. This keeps
the pipeline usable for new disks even while individual stages are
incomplete.

**Tests gate every stage.** Each phase ships with regression tests:
the SoftCard 2.20 and 2.23 disks are the always-on test corpus. New
detected disk formats become permanent test cases. The round-trip
property (Phase 1's invariant) is the master gate: the final disk
must be byte-identical to the input.

---

## Open questions

A few things the roadmap doesn't yet decide:

**Q1. Should the pipeline support non-Microsoft CP/M variants from the
start, or focus on SoftCard CP/M and add others later?** The cpm-videx
investigation is entirely SoftCard. Other vendors (Apple's own CP/M
card, IBM-PC CP/M-86, CP/M Plus, etc.) have different boot
architectures. **Recommendation:** SoftCard-first. Add other variants
after Phase 7 ships, when the architecture has been stress-tested
against one variant end-to-end.

**Q2. How modifiable should the output be?** The user mentioned
"creates fully commented source files... resembles the original source
code used to compile CP/M." There's a spectrum from "byte-identical
disassembly with prose comments" (what the current annotated docs
do) to "structurally-organized source that looks like Microsoft's
original Z-80 / 6502 source files" (which would require inferring
function boundaries, naming, original section organization).
**Recommendation:** start with byte-identical-with-prose; the
structural rewrite is a Phase-8 ambition.

**Q3. What's the format for the symbol-extension files?** The current
`shared/symbols/*.json` schema works for static address → name mappings.
Routine boundaries, function signatures, calling conventions, struct
layouts (for things like the FCB) are NOT yet expressible.
**Recommendation:** evolve the schema as Stage 6 needs it. Start with
the v1.0 schema; when Phase 7 needs a "this routine takes args in
HL/DE and returns A" annotation, extend the schema then.

**Q4. Should the .dsk reconstruction be byte-identical with the disk's
unused regions, or just with the *used* sectors?** SoftCard disks
typically have ~4KB of unused sectors (boot tracks 1-2 partial, etc.).
**Recommendation:** byte-identical including unused regions, since the
round-trip is the whole point of the pipeline. Capture the unused
bytes via `.incbin` from the original.

---

## Effort and value summary

| Phase | Stage | Sessions | Cumulative value at completion |
|---|---|---|---|
| 1 | Stage 7 — disk reconstruction | 1-2 | "I can change comments and rebuild a verified disk" |
| 2 | Stage 1 — format detection | 2-3 | "I can read any standard CP/M disk" |
| 3 | Stage 2 — loader tracing | 3-5 | "I can produce the per-sector → memory map automatically" |
| 4 | Stage 5 — Z-80 trace | 2-3 | "Cold-boot generator and runtime BIOS layout fall out automatically" |
| 5 | Stage 4 — handoff ID | 1-2 | "The 6502 → Z-80 transition is identified automatically" |
| 6 | Stage 3 — version delta | 2-3 | "I can diff two disks and get a routine-level delta report" |
| 7 | Stage 6 — annotation | 1-2 | "End-to-end: disk in, fully-annotated round-tripping source out" |
| **Total** | | **12-20** | **Full vision realized** |

After Phase 1 the tool is *useful*. After Phase 3 the tool is *useful
for unknown disks*. After Phase 7 the original vision is realized:
disk-image-in, fully-understood source-out, with byte-identical
verification at every step.

---

## Status

**REALIZED.** This roadmap is DONE — `cpm_pipeline` is fully built (the detect / trace /
trace-z80 / handoff / diff / build / generate verbs, plus reconstruct / version_delta /
regenerate / the BASIC fold tooling). Both target disks reconstruct byte-identical from the
annotated sources, and the work has since gone well beyond this plan (per-release source trees for
all four CP/M builds, the whole-system emulator, and the GBASIC/MBASIC fold). This file is kept as
the historical roadmap.
