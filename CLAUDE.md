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

**LIVE (2026-06-23, on `main`, gate 228): the CP/M source quality-uplift to the BASIC.asm bar.**
Bring every CP/M source to the standard BASIC.asm set — C-level function headers (Purpose/In/Out/
Clobbers/Algorithm) + high-level body comments, semantic names, char + CP/M-constant literals,
100-col wrap, FULL relocatability (every in-image operand a LABEL), shared includes, **ZERO
inline `; $addr` comments** (addresses live in a generated `.lst` via the new `os_listing.py`),
adversarial-verify to catch byte-identical-but-WRONG decodes. **Byte-identical is the FLOOR;
total semantic understanding is the goal** (`feedback_semantic_understanding_is_the_goal`).
Sequencing (Brent): TWO INDEPENDENT uplifts — **2.20-44K fully, then 2.23-44K clean-slate** (NOT
derived), both fully relocatable; THEN decide whether to fold. Within the OS: **finish the core
(BIOS/BDOS/CCP) first**, same depth, before utilities.

State — **OS core COMPLETE** (commits aac0bb0→**508c406**, gate 228): **CPM_BIOS.asm / CPM_CCP.asm /
CPM_BDOS.asm all DONE** (correctly decoded, fully relocatable, all techniques, ZERO inline `; $addr`
→ `.lst`). CPM_CCP's 2nd embedded 6502 block `$9600-$9700` was a byte-identical-but-WRONG Z-80
decode the verify CAUGHT, EXTRACTED to `CPM_RPC6502_Restart.s`. **#7 overlap audit DONE** (agent
`ad3162a1dfc6260da`, spec `E:/tmp/ccp_bdos_overlap_spec.json`, applied in 508c406): the `$9Bxx`
region is genuine DUAL code/data = the CCP command-FCB build buffer at **CCP_FCB=$9BCD**,
cross-validated against the 2.23 twin — NOT a mis-decode; 46/47 deferred operands relocatized, the
1 unverifiable (`LD HL,$9710`) kept LITERAL + UNKNOWN. Side fix: **`os_listing` strip is now
quote-aware** (`CP ';'` no longer hides the trailing listing comment) — caught 39 residual `; $addr`
in BIOS + 2 in CCP. Infra reused/built: generalized **`cpm_pipeline.basic.enrich_apply`** (`--target`,
byte-safe `splits`/cover-idiom re-render, `labels`, `includes`, `equ_to_include`),
**`cpm_pipeline/os_listing.py`** (strip `; $addr` + emit `.lst`), and the full-technique enrichment
workflow saved at **`softcard/cpm_pipeline/workflows/cpm_os_enrich.workflow.js`** (`args` doesn't
bind — hardcode TARGET). **COVER IDIOM = unlabeled `DEFB $01` + the real instr at its OWN clean
label, NO label arithmetic.** Read `resume-prompt.md` (top) + memory
`project_cpm_source_quality_uplift` for the full handoff; plan docs `CPM_Source_Quality_Uplift_Plan.md`
/ `CPM_Lift_Techniques_From_BASIC.md` (27-technique checklist) / `CPM_Disk_Build_Plan.md`.

**6502 OS phase DONE** (fb7a7e5/c3e569a/9797001/bcc7e6c) → the WHOLE 2.20-44K OS is at the bar:
CPM_RPC6502_Restart.s ($9600), CPM_RPC6502.s ($9400; cover idiom `BIT $38`→`.byte $24`+`SEC`), the
two embedded Z-80 boot fragments (ConInit/ProbeOvl), and **CPM_BootLoader.s** (1284 lines, enriched
via a 6502-aware multi-agent Workflow `cpm_bootloader_enrich.workflow.js` -- 12 clusters/25 agents →
per-cluster `E:/tmp/bl_spec_<i>.json` → Python merge → enrich_apply; adversarial verify caught real
mis-decodes: BOOT0 `$27`/`CMP #$09`=dest PAGE not "sector 9", swapped 6-and-2 buffers, a
PHTAB_ON2-vs-NIBBUF-$AA relocation base). Built ca65 `-l` listing support; generated-6502-source
tests pin BYTES not text; `enrich_apply.body_end` fixed to end at the next SPEC routine. **NEXT:**
the ~16 shared Z-80 utilities + their `_6502.s` payloads (this absorbs the queued
**CP/M-constant rename** across the ~30 `cpm22.inc`-carrying utilities: `CALL $0005`→`CALL BDOS`,
`LD C,$nn`→`F_*`/`DRV_*`, `$0080`→`TBUFF`, `$005C`→`TFCB`; CAUTION 3 files STAT/CPMV220 +
DDT/CPMV220-44K + DDT/CPMV223-44K keep a local `TPA EQU` to dodge a BDOS collision, and the 60K
build keeps it too — adding cpm22.inc there broke `build_cpm60`) → then the independent **2.23-44K**
uplift → then the emulator-driven disk producer (capstone). The DONE BASIC track (one master
`BASIC.asm` byte-identical to both GBASIC/MBASIC, all 14 subsystems C-level, merged `b398441`)
is the model — see `project_basic_gbasic_mbasic_fold`. Older queue still open: 2.20↔2.23 BASIC
patch consolidation; the 56K/60K trees to the same standard, the CPM56→os/ fold, and the wiseowl
"Guided Tour" article series (`softcard/docs/CPM_Source_Completion_and_Tour_Plan.md`,
`project_softcard_source_completion_and_tour`).

Background (the longer-running asset): the **canonical SoftCard / Apple CP/M archive**
at `softcard/reference/softcard-cpm-archive/` (one-stop source: disk images, manuals,
schematics, datasheets, photos; `MANIFEST.csv` authoritative; manuals AI-transcribed
to `manuals/transcribed/`, scanned PDFs authoritative). Open: archive hosting
decision, secondary MS cards.
