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

### 2.20-44K — net-new tree, heavily leveraged
- **Nothing exists** (no `CPMV220-44K/`, no `chunk_map` entry, no reconstruct). We have only `cpm-investigation/bios_220_44k.bin`. The repo's "220" pipeline targets the **2.20B-56K** disk.
- **Leverage:** the 44K OS ≈ the done **2.20B-56K** source relocated **−$3000** (BIOS `$AA00`, BDOS `$9C00`, CCP `$9400`) with **Language-Card banking removed**; most stock `.COM` are byte-identical to existing 56K/2.23 decompiles.
- **Disk contents (19 files):** APDOS, ASM, CONFIGIO.BAS, COPY, CPM56, DDT, DOWNLOAD, DUMP(.ASM/.COM), ED, FORMAT, GBASIC, LOAD, MBASIC, PIP, RW13, STAT, SUBMIT, XSUB. 2.20-specific: CPM56/FORMAT/RW13 (present in the 56K `CPMV220/utilities`); COPY differs from 2.23 (8 vs 28 records).
- **BUILD STEPS (in order):**
  1. **Per-`.COM` byte-identity sweep** — extract each `.COM`, md5 vs existing `bin/` (CPMV220 + CPMV223-44K) → reuse vs decompile-fresh.
  2. **OS decompile** — derive from the 56K source (re-ORG to 44K addresses), then resolve the real config deltas (no-LC-banking, the loader/install, 2.20-vs-2.20B byte diffs). The bulk of the work.
  3. **`chunk_map` `220-44k`** — sector→source map + a `reconstruct_full_disk` path; add variant `'220-44k'` to `get_variant`.
  4. **Byte-identical reconstruct + a regression test** (the gate, mirroring `test_cpm220_reconstruct_byte_identical`).
  5. **Comment + manual-reconcile** (OS `[DOC]` + utilities).

### Sequencing
- **2.20-56K already done** (today's `CPMV220` = 2.20B-56K, byte-identical) → "56K later" is mostly **relabel/formalize**.
- **60K** has a source tree (`CPMV223-60K/os`) + derived disk; reconstruct via the 60K build. Largely there; finish utilities + comments.

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
  - **Step 2 (OS) scoped:** the 2.20-44K OS region (tracks 0-2) is **89% byte-identical** to the done 2.20B-56K (1,338/12,288 bytes differ; concentrated in Track 1 + wherever absolute addresses live). So **derive from the 56K source** (re-ORG −$3000: BIOS $AA00, BDOS $9C00, CCP $9400) + resolve the ~11% deltas (no-LC-banking, loader, 2.20-vs-2.20B). The pipeline's `decompile-os` is NOT yet config-aware (it labels the 2.20-44K BIOS `$DA00`, the 56K default) — needs a `'220-44k'` variant with 44K addresses, like the diff tooling's config-aware fix.
  - **Remaining (a):** add `'220-44k'` to `chunk_map.py` (44K addresses + the disk's sector layout) → create `CPMV220-44K/os/` by re-ORGing the 56K source + reconciling the 11% deltas → assemble the 12 reuse + 5 new `.COM` → byte-identical `reconstruct_full_disk` + regression test → comments. Multi-turn engineering build.
