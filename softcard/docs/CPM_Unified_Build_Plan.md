# SoftCard CP/M — Unified Build Plan (one source base + build script + release)

**Status:** plan of record, 2026-06-30. Council-reviewed (`council-one-source-base` workflow:
pragmatic-hybridist + build/release-engineer + risk-adversary + chair synthesis; the maximalist
member dropped on an API error, but the three surviving members were unanimous and their
conclusions were verified against the actual bytes). This plan tells a **fresh session** exactly
what to do, in order, with a byte-identity gate at every step.

Companion docs: `CPM_56K_60K_Fold_Plan.md` (the 2.20 fold that is already DONE), memories
`project_cpm_unified_build_plan`, `project_cpm_56k_60k_fold_eval`, `project_shared_source_tree`.

---

## 0. Where we are (the regression floor — do NOT break this)

**Gate:** `cd /e/Orchard && source shared/toolchain/env.sh && python -m pytest softcard/ shared/`
= **238 passed** (working tree clean). ALWAYS `source shared/toolchain/env.sh`
first — without it the byte-identical round-trip tests **SKIP silently** (they do not fail).

> **PROGRESS (2026-07-01, this session): Step 0 + Step 5 DONE (gate 230 → 238).**
> - **Step 0 DONE** — two transitive derived-cell gates added to `test_reconstruct.py`
>   (`test_cpm220_derived_2_20b_44k_is_2_20b_56k_relocated`,
>   `test_cpm220_derived_2_20_56k_is_2_20_44k_relocated`): each derived cell, relocated by
>   the memory axis, == the byte-gated diagonal (pure +$3000; CCP/BDOS 0 genuine, BIOS 2 =
>   the "44K"→"56K" banner). Proves the CFG_56K / V220B axes are orthogonal.
> - **Step 5 DONE** — `cpm_pipeline/targets.py` (6-cell registry + `resolve()` + `verify_derived()`),
>   `chunk_map` generalized (`get_variant` table + the two derived variants `220b-44k`/`220-56k`
>   + the 60K carry `223-60k` + `os_module_sources()`), `cpm_pipeline/release.py` + the `release`
>   verb (12 images, SHA256SUMS + `release_manifest.json`, **skip-is-failure**, CPM60.COM anchor),
>   and `build --target VER/MEM/FMT` (legacy positional `build {220|223}` unchanged). Tests in
>   `test_targets.py`. `python -m cpm_pipeline release --out dist/` produces all 6 cells × {.dsk,.po}.
> - **REMAINING (deferred, order per the release-first sequencing):** Step 1 (labelize the BIOS
>   `(OS_RELOC>>8)` dead-mirror arithmetic), Step 2 (labelize ~40 CCP/BDOS DEFB self-pointers),
>   Step 3 (`CPM60_LINK`→`CPM_LINK`), Step 4 (fold CCP to 4 cells; retire the 2 duplicate CCP
>   sources). Step 6 optional. The 60K disk stays `installer-derived` until a `SOURCES_223_60K`
>   reconstruct path exists (do NOT fold the 60K BDOS).

**DONE this session (commits `f2fb84b`→`4c7748c`, 10 commits):** the **entire 2.20 family OS core
folds from ONE 44K source set.** `CPMV220-44K/os/CPM_{CCP,BDOS,BIOS}.asm` each compile
byte-identical to BOTH the 2.20-44K disk (no defines) AND the real 2.20B-56K disk
(`-DCFG_56K -DV220B`). The whole 2.20B-56K **disk** reconstructs from these folded sources
(`reconstruct_disk("220")` → diff 0). Either `.dsk` or `.po` is emitted per the output extension.
The legacy `CPMV220/os/CPM_SystemImage.asm` + 56K `CPM_BIOS.asm` are retired. An adversarial
review verified the BIOS fold against the raw disk + a boot + a negative control, and caught one
real over-relocation (now fixed). The derived 2.20B-44K cell is verified (clean +$3000 relocation
of the 2.20B-56K modulo the `"44K"→"56K"` banner token).

Fold tests already green (the pins — never regress): `test_cpm220_bios_folds_44k_and_2_20b_56k...`,
`test_cpm220_ccp_bdos_fold_44k_and_2_20b_56k...`, `test_reconstruct_emits_either_dsk_or_po...`,
`test_cpm220b_56k_bios_deskew_roundtrip...`, + the four whole-disk reconstruct tests.

---

## 1. The decision — a DISCIPLINED one-base fold (fold along the assembler's grain; stop where it stops)

**Two orthogonal `-D` axes, NEVER entangled:**
- **MEMORY axis.** `CFG_56K` → `OS_RELOC=$3000` (a single scalar in `include/cpm_system_220.inc`;
  all three module bases + every in-image pointer derive from it). `CFG_60K` → **per-module bases**
  in `cpm_system_223.inc` (CCP/BDOS +$4000, **BIOS +$0**). The 60K's non-uniform offset **is** the
  split — NEVER express 60K as one scalar `OS_RELOC` (it would silently mis-ORG the BIOS).
- **VERSION axis.** `V220B` (the 2.20→2.20B island), `V223` (the 2.23 release deltas), `V60`
  (optional 60K-BIOS-upper-page island). Mutually exclusive on the version dimension.
- **Hard rule:** `CFG_56K` must never imply `V220B` (or vice-versa). The chunk map currently pairs
  them only because the sole 56K reference IS 2.20B. The two derived off-diagonal cells
  (2.20B-44K, 2.20-56K) are the ONLY proof the axes are independent → each MUST get a gate (Step 0).
- **LINK token:** unify `CPM60_LINK` → a single `CPM_LINK` so one CCP/BDOS/BIOS source can be
  INCLUDEd by the 60K master or stand alone.

### End-state architecture (module × the 6 target cells)

`()` = no defines. Format is a build-time request (every cell emits `.dsk` OR `.po`).

| Target cell | CCP | BDOS | BIOS | BootLoader | Reference |
|---|---|---|---|---|---|
| 2.20 / 44K | one-src `()` | one-src `()` | one-src `()` | 2.20 loader `()` | ref `.dsk` |
| 2.20B / 56K | one-src `CFG_56K,V220B` | one-src `CFG_56K,V220B` | one-src (island) `CFG_56K,V220B` | 2.20 loader `()` | ref `.po` |
| 2.20B / 44K (derived) | `V220B` | `V220B` | `V220B` | 2.20 loader `()` | **transitive** |
| 2.20 / 56K (derived) | `CFG_56K` | `CFG_56K` | `CFG_56K` | 2.20 loader `()` | **transitive** |
| 2.23 / 44K | one-src `V223` | 2.23-family src `()` | 2.23-family src `()` | 2.23 loader `()` | ref `.dsk` |
| 2.23 / 60K | one-src `V223,CFG_60K` | **SEPARATE** `CPM60.asm` | 2.23-family src (`V60` island, optional) | 2.23 loader (installer form) | installer-derived `.DSK` |

**Per-module end state:**
- **CCP — ONE source, all 4 version×memory cells.** The only module folded across *both* axes
  (near-identical; every twin already byte-proven). Retire `CPMV223-44K/os/CPM_CCP.asm` + the 60K's
  CCP into the canonical `CPMV220-44K/os/CPM_CCP.asm`.
- **BDOS — two version families** (2.20, 2.23), each memory-folded internally. The 2.20 family is
  DONE. The **2.23-60K BDOS stays a permanently SEPARATE build** under `CPM60.asm`.
- **BIOS — two version families**, memory-folded within each (2.20 DONE). The 60K BIOS upper page
  is an *optional* island (prefer a separate INCLUDEd file if it grows).
- **BootLoader / RWTS — stay separate per version** (6502, ORG `$0800` fixed, does not move with the
  memory axis; RWTS already lives inside `CPM_BootLoader.s`).

### DO-NOT-FOLD list (architectural guardrails)
1. **The 2.23-60K BDOS.** Two non-contiguous LC banks (41 `$E0xx` soft-switches, per-call
   bank-in/out envelope, dispatch across banks, ~2700 B still an undisassembled blob). No single ORG
   expresses it; no folded-source reference validates it. Stays under `CPM60.asm`. Revisit ONLY if
   the lower bank is someday fully disassembled AND proven to be the 44K body verbatim-relocated.
2. **2.20 and 2.23 into one BDOS or one BIOS source.** ~50-56 B of scattered deltas; each cell
   already has its own reference + gate; folding buys no new attested target. (CCP is the sole
   exception — near-identical + every twin byte-proven.)
3. **The BootLoader across versions.** ORG `$0800` fixed, zero conditionals today.
4. **A standalone RWTS source for the 44K/56K family** (it lives inside `CPM_BootLoader.s`).
5. **The 60K memory cell as a scalar `OS_RELOC`** (+$4000 CCP/BDOS but +$0 BIOS → per-module bases
   behind `CFG_60K`).
6. **Any combined define** (e.g. `CFG_56K_V220B`) — re-entangles the axes, defeats derived-cell gates.

---

## 2. Migration sequence — one module / one gate / one commit (no big-bang)

Every step keeps all four trees byte-identical and adds a gate *before* it adds a capability.

**Step 0 — Gate the derived cells FIRST (before touching any source). — DONE (gate 232).** Two
transitive CI gates in `test_reconstruct.py`: for each of the 2.20 modules, assert that the
`-DV220B`-only build (2.20B-44K), relocated +$3000, equals the `-DCFG_56K -DV220B` build (2.20B-56K)
MODULO the memory axis (all diffs are either identical, a +$30 relocation high-byte, or the
`"44K"→"56K"` banner token). Same for the base 2.20 (`()` vs `CFG_56K`). This pins the two
reference-less cells and makes axis-entanglement impossible to miss. *(Empirically: CCP/BDOS 0
genuine, BIOS 2 = the banner token at BIOS+$0588.)* **Gate:** 2 new tests green; all existing green.

**Step 1 — De-risk the relocation arithmetic (highest silent-regression risk).** Disassemble the
BIOS "dead DEV_HANDLER mirror" (the block emitted as `DEFB $xx,$yy+(OS_RELOC>>8),...` — a dead,
LDIR-guarded copy of `$xF44-$xF67`) into real instructions/`DEFW LABEL`, and convert the
`DEFW $AA12+OS_RELOC` dispatch lists to `DEFW BIOS_FBASE+n`. This removes the only relocation
arithmetic sjasmplus cannot validate (an `(OS_RELOC>>8)` edit correct at 44K can be wrong at 56K,
caught only by the 56K gate — which SKIPs silently if the assembler is off PATH). **Gate:** the two
2.20 fold tests green.

**Step 2 — Labelize the ~40 CCP/BDOS DEFB self-pointers** (the plan's known prerequisite), file by
file. Makes the memory axis genuinely mechanical (not "clean only on the tested diagonal"). Use the
same technique as the BIOS DPH fix / the error-vec + dispatch-table decode already done: in-image
address operands → `+OS_RELOC` or `BASE+offset` labels; the byte gate proves each. **Gate:** the
CCP/BDOS fold test green after each file.

**Step 3 — Unify the link token** `CPM60_LINK` → `CPM_LINK` across `CPMV223-60K/CPM60.asm`,
`CPM60_installer.asm`, and the INCLUDEd modules (`regenerate.py` writes the guard — update its
`_LINK_NOTE`). **Gate:** `build_cpm60_com()` byte-identical (`test_regenerate_60k`); the 60K disk
still reconstructs.

**Step 4 — Fold CCP to 4 cells.** Add `V223` (base `$9300`) and `CFG_60K` (base `$D300`, one memsize
byte `$A1→$F0`) to the canonical `CPMV220-44K/os/CPM_CCP.asm`. **Gate:** byte-identical to the
2.23-44K CCP reference AND to the CCP region `CPM60.asm` currently INCLUDEs; retire the two duplicate
CCP sources. (This is the one genuinely-new unification; CCP is the clean case.)

**Step 5 — Build harness (additive, no source change). — DONE (gate 238).** `targets.py` registry
(6-cell `Target` + `resolve()` + `verify_derived()`) + `chunk_map` generalization (`get_variant`
table + derived variants `220b-44k`/`220-56k` + 60K carry `223-60k` + `os_module_sources()`) +
`release.py` + the `build --target` / `release` verbs (see §3). It only calls already-gated
reconstruct paths, so it cannot regress a byte gate. **Gate:** `test_targets.py` — all 6 cells build
+ byte-verify through `release`; the skip-is-failure guard proves the verb refuses to run with an
assembler off PATH. `python -m cpm_pipeline release --out dist/` emits the 12 images + SHA256SUMS +
manifest.

**Step 6 — Optional convenience only if a target demands it.** The 60K BIOS upper-page `V60` island
(as a separate INCLUDEd file, not inline IFDEFs). **NEVER** fold the 60K BDOS.

**Sequencing note (per the release ask):** if downloadable builds are the priority, do Step 0 → then
jump to Step 5 (harness/release) so a fork can build all six disks soon; Steps 1-4 (the deeper
labelization + CCP fold) can follow. Steps 1-2 are safe to interleave.

---

## 3. Build script + 6-disk release design

**One Python build brain** (the engine already exists: `assemble.py` runs sjasmplus/ca65 and turns
`ChunkSource.defines` into `-D` flags [DONE this session]; `chunk_map.py` places chunks;
`reconstruct.py::reconstruct_disk` emits `.dsk`/`.po` by extension and byte-verifies; `deskew.py`
holds the reskew maps). Thin `Makefile` (POSIX) + `tasks.py`/`invoke` (Windows) that ONLY call the
Python — a real Makefile would duplicate the engine and break on Windows.

**`cpm_pipeline/targets.py` — the single source of truth for the matrix.** One dataclass per cell:
`Target(version, memory, format-agnostic, defines: tuple, chunk_variant, reskew_map_name,
reference: DISK_* | None, derived_from: <sibling> | None, provenance ∈ {canonical, derived,
installer-derived})`. Import `DISK_*` ONLY from `reference_data.py` (never hard-code a path).

**Two chunk_map gaps to close (verified):**
1. `get_variant` knows only `220`/`223`/`220-44k` (3 variants for a 6-cell matrix; NO 60K disk
   variant). Generalize into a factory that threads a `Target`'s `defines` into `ChunkSource.defines`
   and selects the reskew map by name. Add the two derived cells + a `SOURCES_223_60K`/`CHUNKS_223_60K`.
2. The `build` verb hard-requires `--reference` and takes only `choices=("220","223","auto")` — it
   CANNOT build the derived cells or request by cell/format. Add `build --target VER/MEM/FMT` that
   resolves the cell from `targets.py` (keep the old positional form for back-compat).

**Derived cells (2.20B-44K, 2.20-56K, no reference disk):** synthesize the OS region from folded
source at the derived ORG, borrow the filesystem/boot sectors from the nearest same-version
reference, self-check **transitively** (`derived ±$3000 == the real diagonal reference`), and mark
`DERIVED` in filename + manifest (they never shipped).

**The 60K disk (honesty constraint, verified):** only `CPM60.COM` is pipeline-built byte-exact;
`CPMV223-60K.DSK` is a committed derived artifact with NO chunk-map/reconstruct path. Until Step 5
adds `SOURCES_223_60K`, "build 2.23/60K/.dsk" can only reproduce the committed disk by carrying it
as its own reference. Mark it `installer-derived` (CPM60.COM byte-identical; lower BDOS bank still a
blob) — do NOT claim full source reconstruction.

**`release` verb** (`python -m cpm_pipeline release --out dist/`):
1. **Hard-assert** ca65/ld65/sjasmplus on PATH — fail nonzero, NEVER skip. (**Skip-is-failure** is
   the key hardening: today the round-trip tests skip silently without `env.sh`, so a green-looking
   release could ship unverified images.)
2. Build each of the 6 cells in BOTH `.dsk` and `.po` (12 images) into `dist/`. Byte-verify: 4 pinned
   cells vs their real reference; 2 derived cells vs the transitive `±$3000` identity. Any mismatch
   OR skip aborts nonzero.
3. Also byte-verify `CPM60.COM` via `build_cpm60_com` as the 60K provenance anchor.
4. Emit `dist/SHA256SUMS` + `dist/release_manifest.json` per target: `{version, memory, format,
   defines, source_git_sha, reference_path, reference_sha256, output_sha256, provenance, build_utc,
   sjasmplus/ca65 versions}`.
5. Package `dist/*.dsk` + checksums + manifest; publish via `gh release create` on a version tag.

**A fork does:** `source shared/toolchain/env.sh && python -m cpm_pipeline build --target
2.23/60K/dsk --output dist/cpm-2.23-60k.dsk` — registry resolves (source, defines, reskew map,
reference), extension picks format, output is byte-verified.

**CI:** one GitHub Actions job sources `env.sh`, runs `pytest softcard/ shared/` (the byte gate),
then `release`, uploads `dist/` on a tag. Hold **≥8 byte gates**: 4 reference-cell reconstructions +
2 existing fold-source gates + 2 new derived-cell transitive gates. Assembler-absent = hard CI fail.

---

## 4. Top risks → how the gates neutralize them

| Risk | Neutralized by |
|---|---|
| Silent 1-of-N gate break via relocation arithmetic (a `(OS_RELOC>>8)` edit correct at 44K, wrong at 56K; skips silently if assembler off PATH). | Step 1 labelizes the arithmetic away; CI hard-fails on assembler-absent; every change runs BOTH cells. |
| Derived-cell blind spot (no reference; nothing else proves axis independence). | Step 0 transitive gates on every CI pass; release refuses to package if red. |
| 60K BDOS forced into the fold (looks like "just another offset," is bimodal). | Architecturally excluded (`CFG_60K` = per-module bases; `CPM60.asm` is authority; do-NOT-fold list). |
| Overclaiming the 60K disk from source. | Manifest marks `installer-derived`; release verifies CPM60.COM as the anchor. |
| IFDEF density creep in the BIOS. | Cap islands ~one screen; grow-outs become separate INCLUDEd files; 2.23 BIOS stays a sibling. |
| Big-bang regression across four trees. | One module / one gate / one commit; bisectable. |
| Windows/POSIX + AI-session drift (an AI sees only `OS_RELOC=0` output and "fixes" a site to match 44K, breaking 56K). | One Python build brain; CLAUDE.md rule "never hand-edit a DEFB relocation; labelize"; UTF-8 mojibake grep + diff-review after bulk island edits. |
| Link-rename regresses CPM60.COM. | Step 3 gates `build_cpm60_com` byte-identical before proceeding. |

---

## 5. Key files / where things live (for the fresh session)

- **Sources:** `softcard/CPMV220-44K/os/CPM_{CCP,BDOS,BIOS}.asm` (canonical base, folds via
  CFG_56K/V220B) + `CPM_BootLoader.s`; `softcard/CPMV223-44K/os/` (2.23-44K); `softcard/CPMV223-60K/`
  (`CPM60.asm` master + `os/`).
- **Includes:** `softcard/include/{cpm22.inc, apple_softcard.inc, cpm_system_220.inc (OS_RELOC),
  cpm_system_223.inc}`.
- **Pipeline:** `softcard/cpm_pipeline/{assemble.py (ChunkSource.defines→-D), chunk_map.py
  (get_variant, _build_chunks_220/223/220_44k), reconstruct.py (reconstruct_disk), deskew.py (the
  220/223/220b page→sector maps + reference_*_image_* helpers), cli.py (build verb),
  reference_data.py (DISK_* single source of truth), build_cpm60.py, regenerate.py, generate.py}`.
- **Tests:** `softcard/cpm_pipeline/tests/test_reconstruct.py` (the fold + reconstruct + cross-format
  gates), `test_regenerate_60k.py`, `test_generate.py`.
- **Reference disks (via `reference_data.DISK_*`):** `DISK_2_20_44K_SYSTEM` (.dsk),
  `DISK_2_20B_56K_SYSTEM` (.po), `DISK_2_23_44K_SYSTEM` (.dsk), `DISK_2_23_60K_SYSTEM` (.DSK derived).
- **Conventions:** `feedback_code_size_symbols_from_labels` (size = label arithmetic + ASSERT),
  `feedback_image_refs_are_relocatable_labels`, `feedback_byte_identical_not_correct_decode`
  (byte-identical is the FLOOR — the adversarial review already caught a byte-identical-but-wrong
  over-relocation this campaign), `feedback_no_duplicate_symbol_definitions`.
