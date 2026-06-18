# SoftCard CP/M — Source-Completion Gap Analysis + "Guided Tour" Article Plan

Working plan (created 2026-06-18). Two parts: (1) what it takes to get each
SoftCard CP/M build to a **100%-decompiled, fully-documented, byte-identical
round-trip**; (2) the wiseowl.com project + article series that reads the
finished source. Order of work: **2.20-44K → 2.23-44K utilities → 56K/60K
cleanup → articles.**

Definition of "100% operational" (per Brent, 2026-06-18): the pipeline must
(1) fully decompile the bytes present on the disk image, (2) fully comment and
document the source, and (3) re-assemble that source into a **byte-identical**
disk image. Genuine non-code data (text files like `.BAS`/`.ASM`, the directory,
free space) is carried verbatim — that is faithful, not a gap.

---

## Part 1 — Pipeline completion gap analysis

### 2.23-44K — ~95% done
- **Decompile:** done. 7 OS sources + 19 `.COM` to source.
- **Reassemble:** done. Full-disk reconstruct **byte-identical**; **82.9%** of 143,360 bytes from re-assembled source. The carried **17.1% (24,576 B)** is genuine non-code data: `CONFIGIO.BAS`, `DUMP.ASM`, directory, free space.
- **Document:** OS manual-reconciled (`[DOC]` tags); `.COM` are decompiled + **AI-commented only**.
- **REMAINING:** (b) manual-reconcile the 19 `.COM` comments (SoftCard tools — APDOS/COPY/CONFIGIO/DOWNLOAD — against the Software Utilities manual; stock DR tools against the CP/M Reference); add a short note accounting for the carried data files.

### 2.20-44K — the ORIGINAL build (corrected 2026-06-18 per Brent)
- **The 44K disk is the as-shipped ORIGINAL, not a derivative.** Every memory layout (44K / 56K / 60K) is the **SAME OS source recompiled at config-specific base addresses**. `CPM56.COM` / `CPM60.COM` overlay the original 44K system tracks **in place** to produce the 56K / 60K disks (each carries that same source assembled at its config's bases). So **2.20-44K is canonical/primary; 56K and 60K derive FROM it** via CPM56/CPM60, not the other way round.
- **Base addresses:** 44K = BIOS `$AA00` / BDOS `$9C00` / CCP `$9400` (original); 56K = `$DA00` / `$CC00` / `$C400` (LC bank 2); 60K = relocated + both LC banks.
- **The LC configs add code, not only addresses.** 56K/60K **conditionally compile in Language-Card bank-switching** routines (BIOS disk handlers move into LC banks, with bank-switch entry/exit thunks — e.g. the FED2/FEE0-style bank-1<->bank-2 thunks the 2.23 reference describes). So the 44K is the smallest, base build (no LC code), and the 44K<->56K delta = relocation **plus** these extra LC blocks. The shared source is therefore parameterized two ways: **base addresses + Language-Card `IFDEF` blocks**, exactly the conditional pattern `CPM60.asm` already uses (`IFNDEF CPM60_LINK` guards).
- **2.20-vs-2.20B parameterizes cleanly too (confirmed by the 42-byte breakdown).** It splits into: the **CP/M serial** (per-copy fingerprint, not a version trait — already a reconstruct parameter); the **banner string** `2.20` vs `2.20B`; and just **two tiny functional changes** (2.20B turns a `CALL $AF64` into `LD A,($AF64)`, and adds a ~9-byte `CALL $AB3B / XOR A / STA $9407 / RET` routine where 2.20 has banner text). The rest are **`CALL`/`JP` target shifts that follow automatically** once those blocks are placed — i.e. "shift existing 2.20 code a bit" is right; the assembler recomputes the labels.
- **=> THREE parameterization axes:** **sub-version** (2.20/2.20B: banner + 2 conditional blocks), **memory config** (44K/56K/60K: base addresses + LC `IFDEF` blocks), and **serial** (per-copy). All six 2.20-family disks (2.20/2.20B x 44K/56K/60K) fall out of one source.
- The repo's existing `CPMV220/os` is the **2.20B-56K** assembly of this source. Build 2.20-44K by **assembling the OS source at the 44K (original) bases** -> byte-identical, the same way `CPM60.asm` already builds from one master via DISP/MODULE/INCBIN relocating Z-80 modules to run addresses. The end state is ONE parameterized 2.20 OS source spanning the 2.20-family targets (the shared-source-tree vision).
- **Disk contents (19 files):** APDOS, ASM, CONFIGIO.BAS, COPY, CPM56, DDT, DOWNLOAD, DUMP(.ASM/.COM), ED, FORMAT, GBASIC, LOAD, MBASIC, PIP, RW13, STAT, SUBMIT, XSUB.
- **BUILD STEPS (per Brent's methodology — 44K baseline FIRST):**
  1. **Per-`.COM` byte-identity sweep** — DONE: 12/17 reuse, 5 new (CPM56, DDT, SUBMIT, GBASIC, MBASIC).
  2. **Generate the 2.20-44K OS source as the BASELINE.** Decompile the 44K disk at the 44K bases (`$AA00`/`$9C00`/`$9400`), get it reassembling **byte-identical**, and **comment** it. The 44K has no LC code, so it is the clean/minimal baseline. Needs a config-aware `'220-44k'` chunk_map (`decompile-os` currently mislabels the BIOS `$DA00`).
  3. **Sliding-window diff the 56K source against the 44K baseline.** Matched sections (after the address shift) = shared code; the **unmatched 56K sections ARE the Language-Card blocks** -> they fall out naturally. Wrap them in `IF LANGCARD` conditionals.
  4. **Fold in the sub-version + serial parameters** (banner + the 2 tiny 2.20B blocks; per-copy serial) so all six 2.20-family disks (2.20/2.20B x 44K/56K/60K) reconstruct byte-identical, each with a regression test.
  5. **Comment / manual-reconcile** OS (`[DOC]`) + utilities.

### Sequencing
- Under the corrected model, **44K is primary; 56K/60K are CPM56/CPM60 overlays** of it (the same source at higher bases). The repo's existing `CPMV220` (2.20B-56K, byte-identical) is the 56K assembly — so once the OS source is base-parameterized, 56K falls out of the same tree.
- **60K** already proves the pattern: `CPMV223-60K` builds from the `CPM60.asm` master with relocation. The end state is one base-parameterized OS source per sub-version with 44K/56K/60K targets.

---

## Part 2 — wiseowl.com project + series "A Guided Tour Through the SoftCard CP/M Source Code"

**Angle (distinct from the existing series):** softcard-videx = *the story*; softcard-emu = *the tool*; cpm-pipeline / round-trip-discipline = *the method*. This one is **the source itself** — now that we have byte-identical, manual-reconciled assembly, sit down and *read* a 1980 OS module by module, with its own manuals annotating the bytes. Lead each piece with what the code does for the user, then drop into the source.

**Voice (hard rules; from memory):** Brent's **first person**, NO em dashes ever, conversational intros with terms introduced on arrival, lead-with-consequence, the honest human/AI division of labor (Claude built the decompiler/pipeline and drafted annotations; Brent supplied the manuals and the reconciliation direction). Write **incrementally**, one article per finalized module.

**Project entry:** `src/content/projects/softcard-source-tour.mdx` (`featured`). What it is, the annotated-source repo, the `[DOC]`/`[AI]` provenance convention, byte-identical rebuild as the credibility anchor.

**Articles** (`softcard-source-NN-*`, ~8 standalone narratives):
1. **Power-on to `A>`** — the 6502 boot pipeline: P6 PROM → stub → stage-2 loader → install loops → slot scanner → `LOAD_CPM` → `PREP_HANDOFF` → reset plant → `$0E36` CPU switch.
2. **Two CPUs, one bus** — the RPC mechanism: `$45-$49` cells, `$F3D0`/`$F3DE`, the `$03C0` switch.
3. **The Z-80 BIOS** — the 17-entry jump table → cold-boot generator → device dispatch; why half the BIOS is trap filler on disk.
4. **The I/O Configuration Block** — Card Type Table, I/O Vector Table, screen-function tables, the Firmware-Card / Pascal protocol, device 4 vs device 6 (the Videx fix in the source).
5. **BDOS in Z-80** — function dispatch, the FCB, the cooperative-CPU disk model.
6. **CCP** — six built-ins, the line editor, transient loading.
7. **RWTS** — the 6-and-2 GCR codec and the `$C800` Firmware-Card setup (external 2.23 reference corroboration).
8. **Rebuilding the disk byte-for-byte** (capstone) — the reconstruct pipeline + round-trip discipline as proof the tour is true.

**Dependency:** finish the 2.20-44K + 2.23-44K source to 100% **first**, so the source being toured is final.

---

## Status log
- 2026-06-18: plan created; starting (a) 2.20-44K build.
- 2026-06-18 (a) progress:
  - **Step 1 (.COM sweep) DONE:** of 17 `.COM`, **12 are byte-identical to existing decompiles** (reuse: APDOS, ASM, COPY, DOWNLOAD, DUMP, ED, FORMAT, LOAD, PIP, RW13, STAT, XSUB) and **5 are new** (decompile: CPM56, DDT, SUBMIT, GBASIC, MBASIC). 2 data files carried (CONFIGIO.BAS, DUMP.ASM).
  - **Step 2 (OS) scoped + REFRAMED (per Brent):** the 44K is the ORIGINAL; every layout is the SAME source recompiled at config-specific bases (CPM56/CPM60 overlay the 44K tracks). The 2.20-44K OS region is 89% byte-identical to the 2.20B-56K disk = exactly the address relocation. So: assemble a base-parameterized 2.20 OS source at the 44K (original) bases (BIOS $AA00 / BDOS $9C00 / CCP $9400) -> byte-identical. The pipeline's `decompile-os` is NOT yet config-aware (labels the 2.20-44K BIOS `$DA00`) -> needs a config-aware `'220-44k'` variant.
  - **Model CONFIRMED empirically (boot tracks 0-2):** 2.20B-44K vs 2.20B-56K = **1,304 B** differ (pure relocation; same source, different base) — and 2.20-1980 vs 2.20B at the same 44K config = only **42 B** differ (so "plain 2.20" ≈ "2.20B" + a tiny patch). The build is therefore: base-parameterize the shared 2.20 OS source, assemble at 44K (original) -> ≈ the 2.20B-44K disk via relocation, then apply the 42-byte 2.20-vs-2.20B patch for the 1980 disk. Mechanism: the `CPM60.asm` master pattern (DISP/MODULE/INCBIN relocating modules to run addresses).
  - **Remaining (a):** base-parameterize the 2.20 OS source (ORG-driven, à la CPM60.asm) with a 44K target -> config-aware `'220-44k'` chunk_map -> assemble the 12 reuse + 5 new `.COM` -> byte-identical `reconstruct_full_disk` + regression test -> comments.
- 2026-06-18 (a) **2.20-44K CLEAN-ROOM DECOMPILE DONE (byte-identical, verified):**
  - **Method correction (per Brent):** total clean-room decompile of the 2.20-44K disk from boot sector onward; NO reference to 56K/2.23 source. Disasm tooling upgraded first (shared, byte-identical): strings-as-strings (reference-gated + MIXED-yields-to-string), code-coverage maximization (`--auto-coverage`: dispatch + table-target harvest + validated string-walled after-terminal sweep), code->data reference harvesting. See [[project_disasm_string_coverage_tooling]].
  - **Multi-agent RE workflow** (per region: decompile + adversarial verify, clean-room): all 3 OS regions **byte-identical + verifier ACCEPT**. Sources in `CPMV220-44K/os/`: `CPM_BootLoader.s` ($0800, 6502; 44% code, install image=data, COPYRIGHT banner string), `CPM_SystemImage.asm` ($9300, CCP+BDOS; **84% code**, 10 strings, the `$9400-$94FC` **embedded-6502 RPC block** correctly classified as data), `CPM_BIOS.asm` ($AA00; 49% code, rest = `$E5` trap-fill + tables, no strings). KEY findings: SoftCard CP/M messages reached by a **computed/position-relative locator** (interior-offset `CALL`s) + a `LD BC,head;CALL print` form, emitting via the embedded-6502 block over the CPU-switch; BDOS uses a **runtime-pointer dispatch** (`LD HL,($9F43)`), not a static jump table.
  - **Config-aware `'220-44k'` variant wired** (chunk_map SOURCES/CHUNKS + `get_variant`; `reconstruct._detect_variant` splits 2.20 44K-vs-56K by Z-80 reset-plant base $AA00/$DA00). **Whole disk reconstructs BYTE-IDENTICAL: 81.0% from re-assembled source** (OS 9472 + .COM 106624). Regression tests added (`test_cpm220_44k_reconstruct_byte_identical` + full-disk). Suite: 96 cpm_pipeline + 64 disasm/analyzer pass.
  - **(a) DONE + committed** (296f9b6 clean-room OS; 0bbd403 .COM utilities 5-new/12-reuse + README manifest; e465c7b provenance legend + $9E11->$9E16 fix). Whole disk byte-identical, 96+64 tests pass.
- 2026-06-18 **(fold to master, task #8) -- empirical delta map OVERTURNS the plan's LC-block premise:**
  - **Config 44K<->56K is essentially PURE RELOCATION (+$3000), NOT Language-Card blocks.** Measured 2.20B-44K vs 2.20B-56K staging (same 7168 B size): 1090 bytes differ, ~1081 are +$30 address high-byte shifts. There are **no inserted `IF LANGCARD` code blocks in the 2.20 system image** (that was a 60K/2.23 assumption). The fold is therefore **ORG parameterization**, not LC conditionals.
  - **Sub-version 2.20<->2.20B = ~8-10 bytes** in the staging (5 tiny runs) + serial/banner in the boot loader = small `IF REV_B` patches.
  - **The real work = make the 44K source fully address-relocatable.** Reassembling `CPM_SystemImage.asm` at $C300 (+$3000) and diffing vs the real 56K: **220 bytes still differ -- 210 are address high-bytes that should relocate but stayed LITERAL** (160 in code operands, 60 in data/DEFB), 10 are genuine REV_B/config changes. So: convert those ~210 in-range absolute literals/data-address-bytes to **labels** (so `ORG` relocates them), guard the embedded-6502 block + fixed externals (page-zero $0005, I/O config $F3xx, 6502 cells $03xx) from relocating, then ORG-parameterize (`SYS_BASE` 44K=$9300 / 56K=$C300), add the `IF REV_B` patch, and verify all available 2.20-family disks (2.20-44K, 2.20B-44K, 2.20B-56K; NO 2.20 60K disk exists -- 60K is 2.23 only) reconstruct byte-identical. Mechanism precedent: `CPM60.asm` DISP/MODULE relocation. This relocatability pass is a focused, iterative effort (the literal-vs-constant disambiguation is the care point) -- best as its own next session/workflow.
