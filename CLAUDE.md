# CLAUDE.md — Apple ][ Orchard

Orientation for any Claude session working in this repo. Keep it short; deep
state lives in [`resume-prompt.md`](resume-prompt.md) and in the semantic memory
(`C:/Users/brent/.claude/projects/E--Orchard/memory/`, indexed by `MEMORY.md`).

## What this repo is

Reverse-engineering of vintage Apple II software and hardware: the **Apple Panic**
game (copy-protection + boot trace) and the **Microsoft Z-80 SoftCard CP/M**
operating system (why 2.20 hangs with a Videx Videoterm where 2.23 runs, the full
boot pipeline, a reconstruction toolchain, and a whole-system emulator). The CP/M
sources reassemble to **byte-identical** disk images.

## Repository layout (three top-level trees)

```
apple-ii/    Apple II RE — apple-panic/ (game RE), scripts/ (~38 investigation scripts), docs/ (Disk II P6 ROM)
softcard/    CP/M-80 / Microsoft SoftCard
  CPMV220-44K/  CPMV223-44K/  CPMV223-60K/  CPMV220/   per-release SOURCE trees: os/ + utilities/ (reference disk images live
                                          in the archive, NOT here). CPMV220-44K = the BASE 2.20-44K tree (canonical; owns the
                                          byte-identical-shared utilities + GBASIC + MBASIC, both fully RE'd to 0 machine labels);
                                          CPMV220 = the 2.20B-56K build; CPMV223-60K keeps its DERIVED 60K disk. Both 44K trees are at
                                          the full standard (2026-06-20)
  include/         apple_softcard.inc (Apple/SoftCard hardware externals) + cpm22.inc (CP/M 2.2 ABI): SHARED EQU includes =
                   the single source of truth for external names; INCLUDEd by the sources, staged into every Z-80 build path
  cpm_pipeline/    .DSK -> annotated source pipeline (detect/trace/reconstruct/decompile-*), byte-identical rebuild.
                   reference_data.py = SINGLE SOURCE OF TRUTH for disk/test-data paths (import its DISK_* constants + present()/bios_bin(); never hard-code a path)
  softcard_emu/    whole-system emulator: 6502 + Z-80 on one Apple memory bus (python -m softcard_emu DISK --keys "DIR\r")
  cpm-investigation/  extraction scripts + intermediate binaries (bios_NNN.bin etc., located package-relative)
  docs/            CPM_*.md analysis write-ups
  reference/       softcard-cpm-archive/ = canonical MS SoftCard/CP/M archive AND the tracked single source of truth for
                   every reference disk image (manuals, schematics, datasheets, photos too); MANIFEST.csv is authoritative
shared/      reusable tooling used by both trees
  nibbler/  disasm6502/  disasm_z80/  disasm_common/  symbols/  toolchain/
```

NOTE: the top-level CP/M tree is `softcard/`, NOT `cpm-80/` (an older memory note
mislabels it). Verify paths against the filesystem, which is authoritative.

## Setup, build, test

Python packages live inside the trees but import by **bare name**; a repo-root
`conftest.py` handles `sys.path` for pytest, so tests need no install.

```bash
source shared/toolchain/env.sh   # no install; also puts ca65/ld65/sjasmplus on PATH (+ packages on PYTHONPATH)
# or: pip install -e .
python -m pytest softcard/ shared/   # the CP/M gate: 226 passed with env.sh active (2026-06-22)
python -m pytest                      # whole repo incl. apple-ii (larger total; fewer + skips without the toolchain)
```
The canonical CP/M byte-identical gate is `source shared/toolchain/env.sh && python -m pytest softcard/ shared/`
(**226 passed** as of 2026-06-22, after the BASIC C-level RE + fold). Note: WITHOUT sourcing env.sh, sjasmplus/ca65 are off PATH and the byte-identical
round-trip cases **SKIP** (they do not fail) — always source env.sh and confirm new cases show PASSED, not SKIPPED.

The `CPM*.asm` build sources resolve assembler paths with `cwd=softcard/`. The
pipeline `--ai` layer needs `ANTHROPIC_API_KEY` and uses `claude-opus-4-8`.

**Test data & disk paths (single source of truth).** Every reference disk image
lives ONLY in `softcard/reference/softcard-cpm-archive/` (tracked). Tests and build
code import named `DISK_*` constants (+ `present()`, `bios_bin()`) from
`cpm_pipeline/reference_data.py` — never hard-code a disk path and never infer a
repo root by walking up from a data file's location (auxiliary binaries like
`cpm-investigation/bios_NNN.bin` are located relative to the package). This keeps
disks relocatable and the test suite reproducible from a clean checkout.

## Publishing site

Write-ups publish to **wiseowl.com** (Astro v6, Cloudflare Pages) at
`E:/Sites/wiseowl.com/`. This is the personal "Wise Owl — Brent Rector" site and is
**not** wiseowlsoftware.com (the separate Demeanor product site). Devlogs live in
`src/content/devlogs/`, articles in `src/pages`/content collections. Build:
`npm run build`; deploy: `npm run deploy`.

## Working conventions (durable; also in memory)

- **wiseowl.com article/devlog voice:** NO em dashes, ever (hard rule). No LLM
  tells. Missteps stated matter-of-fact, not as confessions. The honest human/AI
  division of labor is the through-line (Claude built the impractical tooling;
  Brent supplied the insights). Intro/overview pieces: conversational, zero
  assumed knowledge, introduce terms on arrival.
- **Corrections, not rewrites** (devlogs): devlogs are immutable; refine with
  forward-pointer Update notes. Articles may be restructured when a finding is
  structurally wrong (precedent: the softcard-videx series replacing cpm-videx).
- **Lead with consequence, not detection** in RE writeups: finding a code delta
  is the door, not the room — pivot to behavioral consequence.
- **Write devlogs incrementally**, one per milestone, not in a catch-up batch.
- **Don't conflate shared Apple II address spaces with specific cards** (e.g.
  `$C800-$CFFF` is the shared expansion-ROM window, used by many cards).
- **Disassembly labels:** inline `cover+offset` at the use site (no `SUB_xxxx EQU`
  for mid-instruction refs); semantic names via Claude + `FUNCNAME_N` locals
  instead of `L_xxxx`.
- **The SoftCard has no on-board ROM:** cold-boot Z-80 bytes come from 6502
  writes, disk loads, or runtime Z-80 generation — never a card ROM.

## Current focus

**LIVE (2026-06-22, on `main`, gate 226): the BASIC interpreter is RE'd to C-level and the
GBASIC/MBASIC FOLD is DONE — merged to `main` (merge `b398441`, pushed).** ONE editable master
**`CPMV220-44K/utilities/BASIC.asm`** assembles byte-identical to BOTH GBASIC.COM (`DEFINE
GBASIC`, body self-relocates to `$3000`, 25600 B) and MBASIC.COM (no define, flat at `$0100`,
24576 B). All **14 subsystems** carry C-level function headers (Purpose/In/Out/Clobbers/
Algorithm) + high-level body comments; only **3 genuine `IFDEF GBASIC` islands** remain.
Enrichment was applied byte-safely by **`cpm_pipeline.basic.enrich_apply`** (insert +
global-rename + length-preserving operand-rewrite only — the fold byte-gate is the proof),
driven by a per-subsystem **map -> enrich -> ADVERSARIAL verify** workflow that caught real
mis-decodes (FN_LOF->MKI$, FN_CVI->INPUT# scan, STKFRAME_SCAN->FNDFOR, VALTYP legend inverted,
&O/&H swap). BASIC.asm is the editable MASTER (the gen_gbasic/apply_naming/fold_gen pipeline is
provenance-only; `fold_gen` needs `--write-master`); per-build addresses live in git-ignored
`GBASIC.lst`/`MBASIC.lst` (`fold_build --lst`); `GBASIC.asm`/`MBASIC.asm` are byte-pinned
reference views whose annotations now lag. Also landed: canonical `STRUCT CPMFCB` + the
type-model includes, `ORG TPA` across all 4 trees, character literals, 100-col comment wrapping.
GOAL = total semantic understanding; byte-identical is the floor
(`feedback_semantic_understanding_is_the_goal`). Read `resume-prompt.md` (top) + memory
`project_basic_gbasic_mbasic_fold` for the full handoff.

**NEXT (live track): the CP/M-constant rename across the utilities** (Brent's sequencing: BASIC
enrichment first, now done). Across the ~30 utility `.asm` files now carrying `cpm22.inc`:
`CALL $0005` -> `CALL BDOS`, `LD C,$nn` -> `F_*`/`DRV_*`, `$0080` -> `TBUFF`, `$005C` -> `TFCB`.
CAUTION: 3 files (STAT/CPMV220, DDT/CPMV220-44K, DDT/CPMV223-44K) keep a local `TPA EQU` to
dodge a BDOS-symbol collision, and the 60K build (CPM60.asm/CPM60_installer.asm) keeps it too
(no shared includes staged — adding cpm22.inc there broke `build_cpm60`). Suggested: a per-file
byte-safe rewrite applier, base tree CPMV220-44K first. The two shared includes remain the
SINGLE SOURCE OF TRUTH (conform files to them): `softcard/include/apple_softcard.inc` (Apple/
SoftCard hardware externals) + `softcard/include/cpm22.inc` (CP/M 2.2 ABI). THEN the held
low-confidence BASIC items; retire standalone MBASIC.asm; the older queue: 2.20<->2.23 BASIC
patch consolidation; finish include propagation (CPMV223-60K + `src` build wiring, the
`CPM60_installer` disk path, a 6502-side include for the `.s` files); the 56K/60K trees to the
same standard, the CPM56->os/ fold, and the wiseowl "Guided Tour" article series. Plan:
`softcard/docs/CPM_Source_Completion_and_Tour_Plan.md`, `project_softcard_source_completion_and_tour`.

Background (the longer-running asset): the **canonical SoftCard / Apple CP/M archive**
at `softcard/reference/softcard-cpm-archive/` (one-stop source: disk images, manuals,
schematics, datasheets, photos; `MANIFEST.csv` authoritative; manuals AI-transcribed
to `manuals/transcribed/`, scanned PDFs authoritative). Open: archive hosting
decision, secondary MS cards.
