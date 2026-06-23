# CP/M Source Quality-Uplift Plan -- to BASIC.asm Standard

**Status: PLAN (2026-06-22), recommended, not yet started.** Brings the CP/M
**2.20-44K** and **2.23-44K** source files up to the quality bar set by
`CPMV220-44K/utilities/BASIC.asm` (the GBASIC/MBASIC fold master): C-level function
headers, a high-level body-comment layer, adversarial-verify mis-decode catching,
type/struct modeling, idiom polish, **full label-based relocatability**, and the same
byte-identical gates.

**Approach (Brent, 2026-06-22): TWO INDEPENDENT uplifts, then decide the fold.** Uplift
2.20-44K fully first, then 2.23-44K **separately and independently** (clean-slate, NOT
derived from 2.20 -- see `feedback_clean_slate_not_patch_prior_decompile`). Both trees
become **totally relocatable using labels** (every absolute in-image operand a label).
ONLY AFTER both are done do we evaluate whether a single conditionally-compiled 44K
source per module (`IF REV_B`) makes sense; see Section 9 (the structural evaluation
says it is feasible and same-order, but the go/no-go is the per-module residual count,
which the relocatable uplifts produce as a by-product). The full set of BASIC RE "lift" techniques
the uplift must apply (and the gap-closure folded into the workflow) is the checklist of record in
`CPM_Lift_Techniques_From_BASIC.md`. Companion to
`CPM_Source_Completion_and_Tour_Plan.md` (this is the quality tier above that doc's
"full standard").

---

## 1. Where things stand (the gap)

The 2.20-44K and 2.23-44K sources are already at the 2026-06-20 "full standard":
0 machine labels, semantically named, strings-as-literals, `[AI]`/`[DOC]` one-liner
comments, byte-identical reassembly. Many routines already carry the BASIC-style
frame + a one-line purpose. Measured against BASIC.asm they are exactly **one tier
below**:

| Dimension            | BASIC.asm (target)                              | CP/M sources (now)                       |
|----------------------|-------------------------------------------------|------------------------------------------|
| Function headers     | Purpose / **In / Out / Clobbers / Algorithm**   | one-line purpose only (0 structured fields) |
| Body comments        | high-level "what it accomplishes" layer         | sparse `[AI]` opcode-glosses             |
| Mis-decode eval      | adversarial map -> enrich -> **verify**         | not run at this depth                    |
| Type modeling        | CPMFCB, BASLINE, STRDESC, VALTYP structs        | FCB only (CPMFCB exists)                 |
| Idiom polish         | char literals, `CALL BDOS`/`F_*`, 100-col wrap  | hex literals, raw `CALL $0005`, ad-hoc   |

The applier and gates already exist and are nearly file-agnostic:
`cpm_pipeline/basic/enrich_apply.py` is byte-safe by construction (insert + rename +
length-preserving operand-rewrite only); the only hardcoded BASIC dependency is
`MASTER = ...BASIC.asm`. The byte-identical gates already pin every OS file
(`test_decompile_os`, `test_reconstruct`) and every utility
(`test_utilities_roundtrip`, with CPMV220-44K owning the shared copies), and
`test_basic_master` is the model for an ASCII lint.

---

## 2. Definition of done (per file)

A CP/M source file is "BASIC.asm quality" when ALL of:

1. **Every routine has a framed C-level header** -- Purpose / In / Out / Clobbers /
   Algorithm (the Algorithm 2-5 lines at C abstraction, not opcode-by-opcode).
2. **A high-level body-comment layer** -- full-line "what this step accomplishes"
   comments at the meaningful boundaries (not "INC HL").
3. **Adversarial-verify clean** -- a skeptical pass re-checked the In/Out/Algorithm
   and every dataflow/ABI/table claim against the actual bytes; any mis-decode
   (mislabeled BDOS fn, BIOS jump-table slot, IOB cell, RPC cell, DPB field) fixed.
4. **Idiom polish + shared includes** -- character comparisons as char literals; CP/M
   constants named (`CALL BDOS`, `LD C,F_*`/`DRV_*`, `$0080`->`TBUFF`, `$005C`->`TFCB`);
   comments wrapped to 100 cols; consistent section banners; "see"-pointers between
   related routines. **INCLUDE and USE the pertinent system includes (`cpm22.inc` /
   `apple_softcard.inc` / the struct includes) for any external symbol -- NEVER a local
   re-definition of what an include already provides (single source of truth). The
   applier's `equ_to_include` folds a redundant local EQU into the include's symbol and
   drops the local def.**
5. **Type modeling applied** where it raises abstraction (see section 6).
6. **Fully relocatable (label-based)** -- every absolute operand that points INTO the
   module's own image is a LABEL, not a frozen hex literal; the module assembles at its
   run address via `ORG`/`DISP` and a relocation audit shows 0 image-pointing literals.
   This is the BASIC standard (`feedback_image_refs_are_relocatable_labels`): RAM/stack
   workspace, hardware addresses, and numeric constants STAY literal; only in-image
   code/data/table references become labels. Relocatability is the property that later
   makes a same-order fold possible, and the per-module residual diff falls out of it.
7. **Gates green** -- byte-identical reassembly + full pytest + the CP/M ASCII lint.

OBSERVED vs `[RE]` inference vs UNKNOWN is honored throughout; byte-identical is the
FLOOR, total semantic understanding is the goal (`feedback_semantic_understanding_is_the_goal`).
Both CPUs are in scope: Z-80 `.asm` AND 6502 `.s` (boot loaders, RPC blocks, utility
disk-engine payloads).

---

## 3. Scope (the files; BASICs already done)

**2.20-44K OS** (canonical / clean-room decoded):
`CPM_CCP.asm` (1628), `CPM_BDOS.asm` (2154), `CPM_BIOS.asm` (755),
`CPM_BootLoader.s` (1284, **6502**), `CPM_RPC6502.s` (218, 6502),
`CPM_BootLoader_ConInit.asm` (51), `CPM_BootLoader_ProbeOvl.asm` (34).

**Shared utilities** (owned by CPMV220-44K; the 2.23-44K tree inherits byte-identical
copies): PIP, ED, ASM, STAT, DDT, LOAD, APDOS, SUBMIT, DUMP, COPY, XSUB, DOWNLOAD,
FORMAT, RW13, CPM56 (`.asm`) + their `_6502.s` disk-engine payloads
(CPM56_6502, FORMAT_6502, RW13_6502, STAT_6502, COPY_6502).

**2.23-44K OS** (reconcile against the enriched 2.20):
`CPM_CCP.asm` (2174), `CPM_BDOS.asm` (1689), `CPM_BIOS.asm` (877),
`CPM_BootLoader.s` (1374, 6502), `CPM_DiskCallbacks.asm` (178),
`CPM_BootLoader_DiskXlate.asm` (230), `CPM_RPC6502.s` (221), `CPM_BootLoader_ProbeOvl.asm`.
**2.23-only utilities**: AUTORUN, CAT, MFT, PATCH.

Roughly 40-50 enrichment units. Each file is one "subsystem" (or a few clusters
within the larger ones); the per-file loop is the gated unit of work and commit.

---

## 4. The phased plan (2.20-first; each phase gated)

**Phase 0 -- Infrastructure (1 short session).**
- Generalize `enrich_apply.py` to take any target path (parameterize `MASTER`; add an
  `os_path()`/`util_path()` helper). No change to the BASIC path or its gate.
- Author a **CP/M `STYLE` prompt** for the per-subsystem workflow (replacing the
  BASIC one): cite `cpm22.inc` (BDOS ABI: BDOS=$0005, F_*/DRV_*, FCB offsets),
  `apple_softcard.inc` (I/O Config Block, Card Type Table, I/O Vector Table, A_VEC/
  Z_CPU RPC cells), the RWTS IOB doc, the CCP/BDOS/BIOS module boundaries, and the
  manuals (`CPM_Manual_Reconcile_Facts.md`) for `[DOC]` grounding.
- Add a **CP/M ASCII lint** gate (extend/parametrize `test_basic_master` over the
  enriched OS + utility files: no non-ASCII, no over-long lines, no dead label refs).
- Decide and stage the **type/struct includes** (section 6).

**Phase 1 -- Pilot: `CPM_BIOS` 2.20-44K (755 lines).** Smallest meaningful OS file,
most SoftCard-specific (highest RE value; where mis-decodes are most likely), and it
exercises the IOB struct + RPC + the 6502 boundary. Run the full per-file loop,
confirm byte-identical + lint + that adversarial-verify catches real issues, then lock
the template. **Checkpoint with Brent before the wider rollout.**

**Phase 2 -- 2.20-44K OS rollout.** `CPM_BDOS` (the canonical kernel -- biggest
reference-value win; validates the FCB/DPB path), then `CPM_CCP`, then the boot loader
+ RPC (6502) and the two boot fragments.

**Phase 3 -- 2.20-44K shared utilities.** Enrich once in the base tree (2.23 inherits
the byte-identical copies). This phase **subsumes the deferred CP/M-constant rename**
as part of each file's pass (same byte-safe applier). CAUTION: STAT/CPMV220,
DDT/CPMV220-44K, DDT/CPMV223-44K keep a local `TPA EQU` to dodge a BDOS-symbol
collision, and the 60K build keeps it too (no shared includes staged).

**Phase 4 -- 2.23-44K, INDEPENDENTLY.** Uplift the 2.23-44K tree to the SAME standard
as its own clean-slate pass -- **not** derived from 2.20, no lockstep comment transfer
(`feedback_clean_slate_not_patch_prior_decompile`). Same per-file loop, same gates,
same full relocatability. The 2.23-only files (DiskCallbacks, DiskXlate,
AUTORUN/CAT/MFT/PATCH) are enriched here too. The 2.20 enrichment may serve as a naming
LEAD during this pass, but each 2.23 file is understood and commented on its own bytes.
(Rationale for independence: it keeps the clean-room discipline, and it produces two
genuinely independent relocatable sources whose residual diff is then a trustworthy
fold signal rather than a self-fulfilling copy.)

**Phase 5 -- 6502 `.s` payloads.** The utility disk-engine blocks
(CPM56/COPY/FORMAT/RW13/STAT 6502) to the same C-level standard, with 6502 idioms.

**Phase 6 -- Capstone: cross-tree consistency + lint sweep.** One pass for consistent
banners, naming, char literals, and cross-references; confirm the whole suite green.

---

## 5. The per-file loop (the gated unit -- identical to BASIC's)

`map` the file into 1-N clusters -> `enrich` each (C-level header + high-level body
comments + renames + char/constant rewrites) -> **adversarial `verify`** each against
the bytes/ABI -> merge specs -> `enrich_apply --write` -> **byte-identical gate + full
pytest + ASCII lint** -> commit one file/subsystem. Run from `/e/Orchard` with
`shared/toolchain/env.sh` sourced. Parallelize clusters via the Workflow tool exactly
as the BASIC subsystems were.

---

## 6. Type / struct modeling (the "raise abstraction" parallel)

Model the canonical CP/M + SoftCard structures in shared includes, then rewrite the
base+offset literals to `STRUCT.field` (documentation-only or operand-rewrite,
byte-safe), exactly as BASIC got CPMFCB/BASLINE/STRDESC:

- **CPMFCB** -- done (`include/msbasic_fcb.inc`); reuse for BDOS file I/O.
- **IOB** -- the SoftCard RWTS I/O block (`CPM_SoftCard_RWTS_IOB.md`): caller
  track/sector/drive/slot/DMA/status/command cells. Model + apply in BIOS/RWTS.
- **DPB / DPH** -- CP/M disk parameter block / header (BDOS/BIOS disk geometry).
- **BIOS jump table** -- the 17-entry vector layout (BOOT/WBOOT/CONST/.../SECTRAN).
- **CCP command-line buffer** + the BDOS directory entry.
- **I/O Config Block / Card Type Table** -- already EQU'd in `apple_softcard.inc`;
  promote to a struct view for the config-block accesses.

Cite `[DOC]` per `feedback_use_softcard_docs_for_config_blocks` (read the transcribed
manuals; never `[AI]`-guess config-block semantics).

---

## 7. "All the same gates"

Every commit keeps green: byte-identical reassembly of the touched file
(`test_decompile_os` / `test_utilities_roundtrip` / `test_rpc6502` / `test_stat_6502`
/ `test_reconstruct` as applicable), the **full**
`source shared/toolchain/env.sh && python -m pytest softcard/ shared/` (currently 226,
grows as lint cases are added), and the new CP/M ASCII lint. Comment-only / rename /
length-preserving rewrite means the byte gate is the proof, same as BASIC.

---

## 8. Risks & decisions

- **Both CPUs.** The 6502 `.s` files build with ca65/ld65 (not sjasmplus); their
  byte-gates already exist. C-level commenting applies equally (the standing rule).
- **Shared-utility ownership.** Enrich each shared utility ONCE in CPMV220-44K; the
  2.23 tree's copy is byte-identical and re-verified by `test_utilities_roundtrip`.
- **Two INDEPENDENT uplifts (no lockstep copy).** Each tree is uplifted on its own
  bytes; the 2.20 pass may be a naming LEAD for 2.23 but is not transferred wholesale
  (`feedback_clean_slate_not_patch_prior_decompile`). This keeps the per-module residual
  diff a trustworthy fold signal instead of a self-fulfilling copy.
- **Mis-decodes are expected.** The adversarial-verify pass is where the RE wins are
  (mislabeled BDOS fns, BIOS jump-table slots, IOB/DPB cells, the RPC mechanism);
  budget for fixes that change names/comments but not bytes. `[DOC]`-cite, never guess.
- **Gate cwd.** Run the gate from `/e/Orchard`, not from `softcard/` (env.sh sourcing
  + the `pytest softcard/ shared/` collection both depend on it).

---

## 9. The fold decision -- AFTER both uplifts (structural evaluation, recorded 2026-06-22)

Whether to fold 2.20-44K and 2.23-44K into one conditionally-compiled source per module
(`IF REV_B`) is decided ONLY after both relocatable uplifts exist. A structural
evaluation (2026-06-22) already establishes the shape:

**Same-order? YES.** The two 44K builds are the SAME OS with every module RELOCATED plus
a small Videx-fix delta -- structurally the GBASIC/MBASIC situation, not a reordering.
The modules run at different addresses (CCP `$9400` vs `$9300`; BDOS `$9A00` vs `$9C00`;
BIOS `$AA00` vs `$FA00` = Apple `$0A00`, low MAIN RAM -- neither 44K config uses the
language card), so every absolute operand byte differs and a raw byte diff LOOKS
divergent (BIOS ~29%, loader ~18% byte-match). That apparent divergence is the address
shift, not function reordering: the project's validated diff shows the GENUINE functional
delta is small and localized -- dispatch case 6 only in 2.23 (the Videx/Pascal-1.1 fix),
the ~11-byte `$Cn0B` probe in the loader, the CPU-switch trigger address, the case-3
handler (because the BIOS moved), and the `$E5`->RST-trap filler. Large in-order shared
runs confirm the body is common (BDOS 724+267 mnemonics; sysimg 543/434/331-byte
identical runs).

**Cost: GBASIC/MBASIC-class, not the trivial 2.20<->2.23-BASIC-patch class.** Because the
modules run at different addresses, a fold needs full label relocatability (which these
uplifts deliver) + per-version `ORG`/`DISP` + `IF REV_B` islands for the deltas. (The
2.20<->2.23 BASIC delta was 50-56 bytes at the SAME address -- trivial; the OS is not.)

**Per-module fold verdict (revisit with real residual counts after the uplifts):**

| Module | Same-order | Genuine delta | Fold verdict |
|--------|-----------|---------------|--------------|
| BDOS   | yes, high | small | **Good** -- clear win |
| CCP    | yes, high | small | **Good** -- one-page shift + a few islands |
| BIOS   | yes-ish   | Videx fix concentrates here + moved to `$0A00` | **Marginal** -- more conditional content; judgment call |
| 6502 boot loader | partial (layout churn) | the `$Cn0B` probe -- the project's whole payoff | **Likely KEEP SPLIT** -- two clear loaders read better than one `#ifdef`-heavy file |

**Decision rule:** the two relocatable sources yield a per-module RESIDUAL count
(assemble 2.20's relocatable module in 2.23 mode and diff, BASIC-style). Fold the modules
whose residuals are few localized islands (expected: BDOS, CCP); leave split the modules
where islands dominate or two files are more readable (expected: the 6502 boot loader;
BIOS TBD). The capstone fold target is `CPM_Source_Completion_and_Tour_Plan.md` task #4;
the "Guided Tour" article series follows it.

---

## 10. Recommendation

Proceed **2.20-44K-fully-then-2.23-44K**, **OS-before-utilities**, **`CPM_BIOS` as the
pilot**, one file per commit, adversarial-verify on every file. This reuses ~90% of
the BASIC machinery, folds in the deferred CP/M-constant rename for free, and leaves
the trees fold-ready for the capstone.
