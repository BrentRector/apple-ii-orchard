# Resume Prompt — Microsoft SoftCard CP/M Investigation

## >> RESUME HERE — 2026-06-23 (PAUSED): CCP/BDOS SEPARATE COMPILATIONS + BDOS EXPORT HEADER

**Branch `main`, working tree CLEAN, gate 228, both trees byte-identical.** Full plan +
exact steps: memory **[[project_cpm_ccp_bdos_separate_compilation]]**; the hard rule:
**[[feedback_no_duplicate_symbol_definitions]]**.

**The architecture decision (Brent).** The CP/M system image's CCP and BDOS are TWO modules
-> TWO **separate compilations** (each its own `.bin`, concatenated on the system tracks),
in BOTH the 2.20-44K and 2.23-44K trees. The CCP no longer INCLUDEs the BDOS. Cross-module
references go through a **per-module BDOS EXPORT HEADER** that is the SINGLE definition both
modules INCLUDE -- NEVER a duplicate/equivalent-value EQU. Any exported symbol has semantic
value and must be properly named.

**DONE + committed this session:**
- **cpm22.inc consolidation** (f9a551c): `RST2_VEC $0010 / RST4_VEC $0020 / CMDLINE $0081`
  added to `softcard/include/cpm22.inc`; their local dup defs deleted from the 15 utilities
  that INCLUDE cpm22.inc.
- **2.23-44K CCP+BDOS = SEPARATE compilations** (f9a551c): CCP `SAVEBIN $8000,$0D00`; BDOS
  builds standalone (`ORG $9C00 ... SAVEBIN $9C00,$0A00`); both fold base page to cpm22.inc.
  chunk_map `CPM223_44K_System` -> `CPM223_44K_CCP` + `CPM223_44K_BDOS`; `_build_chunks_223`
  concatenates; `component_diff` maps both -> "CCP+BDOS". Byte-identical. **CAVEAT:** this
  split is clean ONLY because the 2.23 CCP is still RAW -- its refs into the BDOS are bare hex
  (`CALL $9Cxx`, numbers). When the 2.23 CCP is enriched (refs become NAMED), it will need the
  export header too.
- **2.20-44K BDOS base-page fold** (677bb9a): folded WBOOT_VEC/IOBYTE/DEFAULT_DMA -> cpm22 names.

**PAUSED -- the 2.20-44K CCP/BDOS split (DO THIS NEXT):** the enriched 2.20 CCP references
**59 BDOS-internal symbols** (genuine code: `JP Z,DISK_READ_RECORD_STG+1`, `CALL
FCB_SET_REC_FLAG_5_STG+2`, `JP READ_CON_BUF_EDIT_STG`, `LD HL,(BDOS_VAR_PAGE_7_p12_STG)`,
`BDOS_ERR_VECTORS+6`, `BDOS_DEFAULT_FCB+2`, ...), so it is NOT independently compilable until
the BDOS exports them. Steps (full detail in the project memory):
1. **PREREQ:** resolve the BDOS's ~16 `cover+offset` / `+1`/`+2` exported entries into clean
   cover-idiom splits (DEFB cover + own clean label, NO arithmetic) -- a header can't ship +offset.
2. **PREREQ:** understand + semantically name the `BDOS_VAR_PAGE_7/8/9_pN_STG` shared cells.
3. Author `softcard/include/cpm_bdos_220.inc` -- the single-source export contract (semantic
   name -> BDOS run address); BDOS INCLUDEs it + uses its names; CCP INCLUDEs it.
4. Split: CCP `SAVEBIN $9300,$0901` (2305 B); the 2.20 BDOS is a pure body fragment
   (`DISP $9A01 ... ENT`, no scaffolding) -> add `IFNDEF CPM_LINK DEVICE + ORG $9C01 + INCLUDE
   cpm22.inc + INCLUDE cpm_bdos_220.inc` before, `SAVEBIN "{out_bin}",$9C01,$0DFF` (3583 B)
   after; CCP drops the BDOS INCLUDE. chunk_map: `CPM220_44K_System` -> `CPM220_44K_CCP` +
   `CPM220_44K_BDOS` (mirror 2.23 + `_build_chunks_220`). (chunk_map's CPM56-reuses-CCP comment
   is OUTDATED -- CPM56.asm is self-contained, no entanglement.)
5. THEN 2.23: enrich its CCP, build `cpm_bdos_223.inc`, repeat.
Gate each step: `test_cpm220_44k_reconstruct` / `test_cpm223_reconstruct` + full suite 228.

**Re-derive the 59 cross-refs:** Python -- defs(BDOS labels+EQUs) ∩ refs(CCP code, comments
stripped) − CCP-defs − cpm22 names. They collapse to ~18-20 distinct interface symbols.

---

## CURRENT STATE — 2026-06-23 (LIVE: CP/M source quality-uplift to the BASIC.asm bar — 2.20-44K OS core nearly done)

**Branch `main`, working tree clean, gate 228 passed** (`cd /e/Orchard && source
shared/toolchain/env.sh && python -m pytest softcard/ shared/` — was 226; +2 from the new
`test_rpc6502_restart` pin). Full memory: **[[project_cpm_source_quality_uplift]]**.

**The campaign.** Bring every CP/M source to the exact bar BASIC.asm set — C-level function
headers (Purpose/In/Out/Clobbers/Algorithm), high-level body comments, semantic names
(FUNCNAME_N locals, never L_xxxx), char + CP/M-constant literals, 100-col wrap, FULL
relocatability (every in-image operand a LABEL), shared includes (single source of truth),
**ZERO inline `; $addr <bytes>` comments** (addresses live in a generated `.lst`),
adversarial-verify to catch byte-identical-but-WRONG decodes. **Byte-identical is the FLOOR;
total semantic understanding is the goal** ([[feedback_semantic_understanding_is_the_goal]]).
User's sequencing: TWO INDEPENDENT uplifts — **2.20-44K fully, then 2.23-44K clean-slate**
(NOT derived) — both fully relocatable; THEN decide whether to fold them (only if functions
land in the same order, like BASIC). Within the OS: "**finish the OS core (BIOS/BDOS/CCP)
properly first**, same depth," before utilities.

**Status — 2.20-44K OS core = COMPLETE** (commits aac0bb0→**508c406**; gate 228):
- **CPM_BIOS.asm — DONE** (4fed9e9/9142e2f/395378b/f067bac/508c406): correctly decoded, fully
  relocatable, all techniques, cover idioms in split form, uses apple_softcard.inc + cpm22.inc,
  ZERO inline `; $addr` → `CPM_BIOS.lst`. (#8 fixed the reversed PUN_DISP banner; 508c406 stripped
  39 residual `; $addr` comments #8 had re-introduced.)
- **CPM_CCP.asm — DONE** (b93c63f/60508c0/d8382ce/508c406): C-level layer; the 2nd embedded
  **6502 block `$9600-$9700` EXTRACTED** to `CPM_RPC6502_Restart.s` (a byte-identical-but-WRONG
  Z-80 decode the verify CAUGHT); cpm22.inc at the unit top; **#7 overlap audit applied** (below).
- **CPM_BDOS.asm — DONE** (299d4ea/d8382ce): C-level headers/body, cover-idiom splits incl.
  BDOS_ENTRY, clean relocatizations. (#7: needs no further edits — every BDOS label the CCP
  references already resolves in the combined unit.)
- **#7 OVERLAP AUDIT — DONE** (agent `ad3162a1dfc6260da`; spec `E:/tmp/ccp_bdos_overlap_spec.json`;
  applied + committed in 508c406). The `$9Bxx` region is genuine **DUAL code/data** = the CCP
  command-FCB build buffer at **CCP_FCB=$9BCD** (+1 name, +32 FCB.CR, +33 FCB.R0, +35 drive-seen
  flag), cross-validated against the 2.23 twin (same offsets) — NOT a mis-decode. 46 of 47 deferred
  operands relocatized (CCP_FCB±offset cluster; +$0200/+$0100 6502-view message pointers;
  MSG_ALL_YN+2 print-newline ×6; CCP_CMD_NAMES+5 / MSG_NO_FILE+5 table-/string-interior code
  entries; BDOS_ERR_VECTORS / BDOS_DEFAULT_FCB). The one unverifiable cell (`LD HL,$9710` in
  SEARCH_BUILTIN) kept LITERAL with an UNKNOWN note (its 2.23 analog points to a different relative
  cell). Side fix: **`os_listing` strip is now quote-aware** — a `CP ';'` char literal no longer
  hides the trailing listing comment from `partition(';')` (the bug that left those 39 BIOS + 2 CCP
  residuals); every OS-core file now has ZERO inline `; $addr`.

**Infrastructure (built this campaign; reuse it).**
- `cpm_pipeline/basic/enrich_apply.py` — generalized from BASIC: CLI `--target PATH --write`;
  new spec fields **`splits[{anchor,occ,into[],absorbs[],delete_existing_label_line}]`**
  (re-renders a cover idiom as DEFB cover + clean-labeled real instr — byte-safe), `labels[]`,
  `includes[]`, `equ_to_include[]`, top-level `operand_rewrites`; all anchors via
  `code_norm(_rn(anchor))`.
- `cpm_pipeline/os_listing.py` (NEW) — `strip_listing_comments` (removes ONLY `; $addr <bytes>`
  runs; keeps docs/semantic notes/headers; **quote-aware comment finder** so `CP ';'` doesn't
  hide the trailing listing comment) + `emit_listing` (`assemble_chunk(... lst_path=)`).
- `cpm_pipeline/assemble.py` — `assemble_chunk`/`_assemble_z80` gained `lst_path` (sjasmplus
  `--lst`, reuses the byte-identical build path).
- `cpm_pipeline/chunk_map.py` — `CPM22_INC`; BIOS + System ChunkSources carry the includes;
  System gained the `CPM_RPC6502_Restart.bin` incbin_dep. **RULE: adding an include to an OS
  file REQUIRES registering it in that ChunkSource.include_files.**
- `cpm_pipeline/gen_rpc6502_restart.py` + `tests/test_rpc6502_restart.py` (NEW) — recipe + pin.
- **The enrichment WORKFLOW** (full-technique STYLE; map → enrich-per-cluster →
  adversarial-verify) is saved at **`softcard/cpm_pipeline/workflows/cpm_os_enrich.workflow.js`**
  (the session workflows dir is NOT durable). **`args` does NOT bind here — hardcode the
  TARGET/MODULE constants in the script** before each run, then `Workflow({scriptPath})`.

**Per-file loop:** set TARGET in the workflow script → `Workflow({scriptPath})` → merge cluster
specs → `enrich_apply --target <file> --write` → strip + regen `.lst` (`os_listing`) →
**fast gate `test_cpm220_44k_reconstruct_byte_identical`** + full suite (env.sh!) → commit.

**Conventions locked this campaign (user corrections):**
- **COVER IDIOM = unlabeled `DEFB $01` cover byte + the real instruction at its OWN clean label.
  NO address/label arithmetic, EVER** (no `LABEL+offset`). Pointer tables → `DEFW` of clean
  labels. (My earlier "cover+offset" framing was WRONG — corrected.)
- **ZERO inline `; $addr <bytes>` comments** — BASIC.asm has none; strip to the `.lst`.
- **Use ALL the BASIC lifts from the start** (the 27-technique checklist) — don't wait to be
  told; diff CP/M output directly against BASIC.asm's actual conventions.
- Reloc discriminator: "does the operand point INTO this module's image?" → LABEL; else
  (RAM/HW/numeric constant/off-image) → keep literal [[feedback_image_refs_are_relocatable_labels]].
- Don't force a relocatization onto an unverifiable decode — defer with UNKNOWN
  [[feedback_dont_overclassify_dead_or_data]]. The **5-hour usage limit RESETS** — pause, don't ration.

**6502 OS phase — COMPLETE** (commits fb7a7e5 / c3e569a / 9797001 / **bcc7e6c**) → the WHOLE 2.20-44K
OS is now at the bar. DONE: **CPM_RPC6502_Restart.s**
($9600 cold-restart/RPC), **CPM_RPC6502.s** ($9400 warm-boot/RWTS — the lone `BNE
DRIVE_MOTOR_ON_1+1` cover idiom converted to `.byte $24` (BIT-zp) + `SEC` at clean label
DRIVE_MOTOR_ON_SEC, CFG_56K $94AE variant kept), and the two embedded Z-80 fragments
**CPM_BootLoader_ConInit.asm / CPM_BootLoader_ProbeOvl.asm**. Each: C-level headers + body
comments, ZERO inline `; $addr` (→ `.lst`). New infra: **ca65 `-l` listing** in
`assemble._assemble_6502` + `os_listing.emit_listing` now accepts 6502 (the `.s` `.org` gives
absolute addresses); **generated-6502-source tests pin BYTES not text** (`test_rpc6502`/`_restart`
assemble `generate()` vs the on-disk block — the `.s` is the hand-enriched MASTER, `gen_*` is
provenance-only); **6502 cover idiom = `.byte <opcode>` cover + real instr at own clean label**.
After editing a host's INCBIN'd block, re-run `python -m cpm_pipeline.inject_incbin_listing`.
**`CPM_BootLoader.s` — DONE** (bcc7e6c): the 1284-line boot loader, enriched via a 6502-aware
multi-agent **Workflow** (`softcard/cpm_pipeline/workflows/cpm_bootloader_enrich.workflow.js`; map →
enrich → adversarial-verify, 12 clusters / 25 agents; each verify agent wrote its cluster spec to
`E:/tmp/bl_spec_<i>.json`, then merged with Python + `enrich_apply`). 76 headers, 259 body, 4 renames,
6 in-image relocatizations, 1 minted label (RPC_SERVICE_LOOP @ $03C0), 3 6502 cover-idiom splits, 733
addrs stripped. Adversarial verify caught real mis-decodes (BOOT0 `$27`/`CMP #$09`=dest PAGE not
"sector 9"; swapped 6-and-2 buffers; PHTAB_ON2-vs-NIBBUF-$AA relocation base). **Apply gotchas** (see
the memory for the full list): drop agent over-split thin sub-routines (loop locals); `enrich_apply.
body_end` fixed to end at the next SPEC routine; duplicate same-anchor operand_rewrites use occ=1
repeated; mint a header's NEW label in the file by hand first; `labels[]` uses GLOBAL occ; keep
planted-JMP/copy-destination/self-modified cells literal.

**2.23-44K uplift — IN PROGRESS** (clean-slate from 2.23 bytes; the enriched 2.20 twin is a verify
cross-reference, NEVER copied). `cpm_os_enrich.workflow.js` is now the FILE-WRITING Z-80 OS workflow
(verify → `E:/tmp/os_spec_<i>.json`) + proactive synonym-fold STYLE.
- **CPM_BIOS.asm — DONE** (58955e2): headers/body/renames + a card-descriptor split + cpm22.inc
  folds (WBOOT_VEC→WBOOTV, CDISK→CDISK_ADDR, BDOS_VEC→BDOS, DEFAULT_DMA→TBUFF, $0003→IOBYTE_ADDR) +
  INCLUDE cpm22.inc (registered in chunk_map). **Framing fixed: Z-80 $FA00 = Apple $0A00 LOW main
  RAM, NO language card** ([[feedback_softcard_z80_high_addr_is_low_apple_ram]]); Videx+40col + the
  2.23-only device-6/Pascal probe documented.
- **CPM_BDOS.asm — DOCUMENTED; relocatability DEFERRED** (9d38c9d): byte-safe subset applied — 257
  headers, 465 body, 75 renames, zero inline `; $addr`. Byte-identical. **CCP+BDOS = ONE compilation
  unit** (CCP INCLUDEs BDOS) → shared base-page folds + includes belong at the **CCP unit head** and
  must rename BOTH files; folding BDOS-alone deleted defs the CCP uses → build broke. DEFERRED to the
  CCP pass: the ~16 **cover+offset EQU → clean-label splits** (mint labels + DELETE the EQU lines;
  several collide in the dense $A4xx-$A5xx region), in-image operand→label rewrites, and the
  cpm22/apple_softcard folds+includes (CCP-head placement, both-file rename).
- **NEXT:** enrich **CPM_CCP.asm** as the unit head, carrying the deferred BDOS relocatability +
  unit-wide folds (gate the combined CCP+BDOS chunk) → then the 2.23 6502 files (CPM_BootLoader.s /
  CPM_RPC6502.s + the Z-80 fragments CPM_DiskCallbacks.asm / CPM_BootLoader_DiskXlate.asm / ProbeOvl).

**Remaining campaign (after 2.23-44K OS):** ~16 shared Z-80 utilities (PIP/ED/ASM/STAT/DDT/…) +
their `_6502.s` payloads (disassemble the DEFB blobs; absorbs the queued CP/M-constant rename) →
then the emulator-driven disk producer (capstone).

**Disk-image model (decided; `softcard/docs/CPM_Disk_Build_Plan.md`).** A "full" build = ONE flat
143,360-byte raw sector image (35×16×256). CP/M 2.2 has NO CPM.SYS: tracks 0-2 = boot + CCP/BDOS
+ BIOS as raw sectors; tracks 3+ = the filesystem. Producers: (1) **reconstruct** (reference-
anchored, byte-identical — the GATE), (2) emulator-driven from-scratch (boot OS tracks + empty
FS in softcard_emu, drive BDOS `F_MAKE`/`F_WRITE`/`F_CLOSE` per .COM in directory order — deferred).
Plan docs: `CPM_Source_Quality_Uplift_Plan.md`, `CPM_Lift_Techniques_From_BASIC.md` (27-technique
checklist), `CPM_Disk_Build_Plan.md`.

---

## Earlier handoff — 2026-06-22 (BASIC interpreter RE'd to C-level + the GBASIC/MBASIC FOLD — DONE and MERGED to `main`)

**Branch: `main`, working tree clean, pushed to origin. Merge `b398441`** (`--no-ff`, 23
commits; the local feature branch `basic-semantic-enrichment` was deleted after merge).
Gate: **226 passed** (`cd /e/Orchard && source shared/toolchain/env.sh && python -m pytest
softcard/ shared/`). Both BASICs reassemble byte-identical to their disk `.COM`s.

### What just landed: the BASIC track is COMPLETE

1. **The GBASIC/MBASIC one-conditional-source FOLD is DONE.** ONE editable master
   `CPMV220-44K/utilities/BASIC.asm` assembles byte-identical to BOTH GBASIC.COM (with
   `DEFINE GBASIC`, self-relocates its body to `$3000`, 25600 B) and MBASIC.COM (no define,
   runs flat at `$0100`, 24576 B). Residuals were driven 16 -> 0; almost all were MISSED
   LABELS (relocatable in-image refs), NOT islands — only **3 genuine `IFDEF GBASIC` islands**
   remain (the hi-res statement+function dispatch slots, the ERROR_REPORT message-index clamp,
   and the `$271F` graphics-plot operand). `+$1000` = the reusable SoftCard CPU-view encoding
   for an in-image 6502 RPC payload (BEEP). Feasibility came from full relocatability (every
   ref a label); Brent's audit insight (any non-graphics byte mismatch = a decode bug the
   byte-identical gate is blind to) drove the closures.
2. **The whole interpreter is enriched to C-level** — all **14 subsystems** carry framed
   function headers (Purpose / In / Out / Clobbers / Algorithm) + high-level body comments,
   and hundreds of machine labels were given semantic names. Subsystems: file-I/O, CRUNCH
   tokenizer, CHRGET, FRMEVL, LIST/detokenizer, graphics/RPC, FP-math (MBF), FOUT/FIN,
   var-mgmt + core helpers, console I/O, statement-dispatch, function-dispatch, self-relocator,
   cold/warm-start. GOAL = total semantic understanding; byte-identical is the FLOOR
   ([[feedback_semantic_understanding_is_the_goal]]).
3. **BASIC.asm is the editable MASTER** (promoted; the gen_gbasic/apply_naming/fold_gen pipeline
   is now PROVENANCE-ONLY — `fold_gen` refuses to overwrite the master without `--write-master`).
   Per-build addresses live in git-ignored listings `GBASIC.lst`/`MBASIC.lst` (`fold_build
   --lst`); the inline `; $XXXX <bytes>` comments were stripped from the master.
   `CPMV220-44K/utilities/PROVENANCE.md` documents the model. `GBASIC.asm`/`MBASIC.asm` are
   reference views — `test_utility_source_is_byte_identical` pins only their bytes; their
   annotations now LAG the master, and standalone MBASIC.asm is slated to retire.
4. Also in the branch: canonical **`STRUCT CPMFCB`** (standard DRI FCB field names) + the
   type-model includes (`include/msbasic_{line,strdesc,var,valtyp,fcb}.inc`); **`ORG TPA`**
   (the named transient-program-area constant) across ALL 4 trees' utilities; **character
   literals** for character comparisons (`CP '"'`, `CP ' '`, `SUB 'A'`); all enrichment comments
   **wrapped to 100 columns**.

### THE APPLIER + WORKFLOW (how the enrichment was applied byte-safely)

`cpm_pipeline/basic/enrich_apply.py` takes a spec JSON `{routines:[{label, header[],
body_comments[], renames[], operand_rewrites[]}]}` and edits BASIC.asm by INSERT + global
RENAME + length-preserving operand-rewrite ONLY — it never moves a code byte, so the fold
byte-gate is the proof. Key mechanics: renames apply FIRST/globally (`\b(old)(_\d+)?\b` with
`_N` local drag) so header/body anchors written with FINAL names match; `body_end` bounds the
anchor search to the routine's ACTUAL extent (next non-continuation label) so a same-byte
operand rewrite can't leak into a neighbour; `_strip_was` drops redundant "(was NAME)"; `_wrap`
aligns comments to 100 cols. The per-subsystem WORKFLOW (one script per subsystem under the
session `workflows/scripts/`): **map** the subsystem into 4-7 clusters -> **enrich** each
cluster (header + body comments + renames) -> **ADVERSARIAL verify** each (skeptical re-check
vs the bytes) -> merge specs -> `enrich_apply --write` -> fold byte-gate + full pytest ->
commit. Adversarial verify caught real mis-decodes: FN_LOF->MKI$/MKS$/MKD$, FN_CVI->INPUT#
scanner, FN_INT->FN_ABS, STKFRAME_SCAN->FNDFOR ($82=FOR not GOSUB), OUTDO_DEVICE/_2 BIOS-vector
swap, `$0CB6` = FP-eval flag not screen-reverse, VALTYP legend inverted, &O/&H octal/hex reversed.

### Queued (now folded into the campaign's UTILITIES phase): CP/M-constant rename across the utilities

Brent's sequencing was "finish BASIC enrichment first," then this. Across the ~30 utility
`.asm` files that now carry `cpm22.inc`: rename `CALL $0005` -> `CALL BDOS`, `LD C,$nn` BDOS
selectors -> `F_*`/`DRV_*`, `$0080` -> `TBUFF`, `$005C` -> `TFCB`, etc. CAUTION: 3 files keep
a LOCAL `TPA EQU $0100` to dodge a BDOS-symbol collision (STAT/CPMV220, DDT/CPMV220-44K,
DDT/CPMV223-44K), and the 60K build (CPM60.asm + CPM60_installer.asm) keeps `TPA EQU $0100`
too because `build_cpm60` does NOT stage the shared includes (adding cpm22.inc there broke the
build — reverted). Suggested approach: a per-file byte-safe rewrite applier (same discipline
as `enrich_apply`), base tree CPMV220-44K first, then extend to CPMV223-44K / CPMV220 /
CPMV223-60K. After that: the held low-confidence BASIC items (VALTYP `$620D`, FCB `$7D7C`/`$7F28`
page-wrap, `$0838` PRTFLG), retire the standalone MBASIC.asm, then the older queue below.

### Earlier-landed: Error subsystem — fully RE'd in BOTH twins (merge `a2eab60`; [[project_basic_synchr_decode_and_tokens]])

New modules `cpm_pipeline/basic/{errmsg,errstub}.py`. Message table -> `ERROR_MESSAGE_TABLE`
base + clean `DEFB` strings + the GENERATED `softcard/include/msbasic_errors.inc` (ERR_* EQUs,
generated from **MBASIC.COM** = the code superset: it alone carries code 32 =
ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED). Codes 1-31 then disk 50-70 (printer does CP $32/SUB
$12). Overlap-skip stub runs -> `RAISE_<name>: LD E,ERR_<name>` / `DEFB $01`; non-table
`LD E,$nn` AND `LD DE,$00nn` raise sites -> `LD (D)E,ERR_<name>`. Dispatcher unified
**RAISE_ERROR** across both twins. Disk-error VECTOR run -> `DISK_RAISE_<name>` + tail
`DISK_RESELECT_AND_RAISE`. A surfaced mis-decode: `CONT_CMD` ($0D2E) is really **PROGRAM_END**
(NEWSTT end-of-program; raises No RESUME=19, not Can't continue=17; real CONT is STMT_CONT).

---

## Earlier handoff — 2026-06-20 (GBASIC + MBASIC FULLY RE'd, shared name includes, RWTS IOB; MERGED to `main` via PR #4)

**Everything below was on `main` as of 2026-06-20** (branch `softcard-bootloaders-to-standard`
merged via PR #4); the 2026-06-21 work above builds on it. Gate then **217 passed**.

**GBASIC 2.20-44K — DONE, 0 machine labels** (`softcard/CPMV220-44K/utilities/GBASIC.asm`).
Clean-slate decode of GBASIC.COM (25600 B). It self-relocates: entry `JP $1000`; a `$1000`
stub LDDRs the interpreter body from file `$100E-$6490` UP to run `$3000-$8482`, then
`JP $81D3`. So the body is decoded at run `$3000` and folded to the .COM file offset via
`DISP $3000 ... ENT`. Enriched in stages (dispatch handlers → engine region fan-out → finish
pass), each adversarially verified; MS BASIC-80 RAM canon named (TXTTAB/VARTAB/MEMSIZ/FRETOP/
SAVTXT/...). Recipe + binary facts: **[[project_gbasic_2_20_44k_re_kickoff]]**.

**MBASIC 2.20-44K — DONE, 0 machine labels** (`.../utilities/MBASIC.asm`). The graphics-OFF
twin (same MS BASIC-80 Rev 5.2 engine; graphics tokens dispatch to a "Graphics statement not
implemented" stub). It does NOT relocate — it runs IN PLACE at `$0100` (entry `JP $5E51`
cold start), so it's a single `ORG $0100` region (no DISP). Because GBASIC is assembled for
`$3000` and MBASIC for `$0100`, the shared code is byte-different in every absolute operand
(~18% exact overlap) — so names were transferred by **structural correspondence**, not byte
matching: a LOCKSTEP walk of both programs from corresponding entries (cold start + every
dispatch handler + fall-through) maps `GBASIC_addr -> MBASIC_addr` for code targets AND
data/RAM cells, so identical routines get identical names. See [[project_gbasic_vs_mbasic_relationship]].

**Shared name includes = the SINGLE SOURCE OF TRUTH** (Brent's rule: conform every file TO
the include, never the reverse). `softcard/include/apple_softcard.inc` (Apple/SoftCard
hardware externals: I/O config block, A_VEC/Z_CPU RPC cells + the 6502 register-pass area,
soft switches, zero-page graphics cells, Apple-ROM entry points; grounded in the manuals
`[DOC S&HD]` + `shared/symbols/apple2.json`) and `softcard/include/cpm22.inc` (CP/M 2.2 ABI:
base page, BDOS fn numbers, FCB offsets). INCLUDEd across CPMV220-44K + CPMV223-44K +
CPMV220(56K) + the BASICs. Build/test plumbing stages includes for all 3 Z-80 paths (utility
roundtrip, OS chunk `ChunkSource.include_files`, INCBIN-fragment auto-staging). After editing
an INCBIN'd fragment, re-run `python -m cpm_pipeline.inject_incbin_listing`. Standing rule +
the apple2.json/ROM-entry-point dimension: **[[feedback_use_softcard_docs_for_config_blocks]]**.

**SoftCard RWTS interface — nailed + documented** (`softcard/docs/CPM_SoftCard_RWTS_IOB.md`):
caller block `$F3E0`=track / `$F3E1`=sector / `$F3E4`=drive / `$F3E6`=slot(<<4) / `$F3E8/$E9`=
DMA buffer ptr / `$F3EA`=status / `$F3EB`=command; `$F3E2/$E3/$E5/$E7` are driver-internal
physical-track/current-drive/current-slot latches (the logical-caller-vs-physical-driver split
is what made the cells first look inconsistent). Sector interleave: SoftCard CP/M uses the
Pascal/ProDOS 2:1 order (`00 02 04 06 08 0A 0C 0E 01 ...`), NOT DOS 3.3; RW13 also handles
13-sector DOS 3.2 (a physically distinct format).

**BASIC PIPELINE / where the tooling lives.** The `.asm` files ARE the committed source of
truth (pinned byte-identical by `test_utilities_roundtrip`, like every other utility). The
build SCAFFOLDING — `gen_gbasic_220.py`, `gen_mbasic_220.py`, `apply_naming.py`,
`map_gbasic_to_mbasic.py`, and the `overlay_combined.json` / `overlay_mbasic.json` — lived in
`E:/tmp/` (scratch; may be gone in a new session). The COMMITTED provenance is
`GBASIC.seeds.json` + `GBASIC.overlay.json` and `MBASIC.seeds.json` + `MBASIC.overlay.json`
(the coverage seeds + the address-keyed naming overlays). To resume the BASIC work you can
edit the `.asm` by hand (it's the source of truth) or rebuild the scaffolding from these
companions + the memory recipe.

**REMAINING (next sessions):** (1) 2.20<->2.23 BASIC patch consolidation (the BASICs differ
~50-56 bytes, console/memory patches, NOT graphics); (2) finish include propagation —
CPMV223-60K + `src` build wiring (the 60K modules INCLUDE into one `CPM60.asm` master under an
`IFNDEF CPM60_LINK` guard, so the master needs a global include + `build_cpm60`/
`test_shared_ccp` staging), the `CPM60_installer` disk path (its `$F3Ex` usage differs — RE it
before conforming), `cpm22.inc` across the utilities (BDOS fn numbers — per-`LD C,n` care), and
a separate 6502-side include for the `.s` files ($C0xx/$00xx native); (3) the 56K/60K trees to
the full standard, the CPM56->os/ fold, then the wiseowl "Guided Tour" article series. Plan:
`softcard/docs/CPM_Source_Completion_and_Tour_Plan.md`, [[project_softcard_source_completion_and_tour]].

---

## CURRENT STATE — 2026-06-20 (44K source-completion plan DONE; GBASIC 2.20-44K decompile — superseded by the section above)

**>>> IMMEDIATE NEXT TASK: reverse-engineer / decompile GBASIC.COM from the 2.20-44K
disk to the full standard, byte-identical, SUPERSET-FIRST.** Full recipe + binary
facts: memory **[[project_gbasic_2_20_44k_re_kickoff]]** (READ FIRST) and
**[[project_gbasic_vs_mbasic_relationship]]**. Brent greenlit it.

Crux: GBASIC self-relocates (entry `JP $1000`; relocator `LD HL,$6490 / LD DE,$8482 /
LD BC,$5483 / LDDR / JP $81D3` copies the interpreter from file $100E-$6490 UP to
$3000-$8482, runs at **$3000+**), so decode the body via **`DISP $3000`** (NOT the
file org -- `decompile_com`'s naive $0100 decode is WRONG). The existing
`softcard/CPMV223-44K/utilities/GBASIC.asm` already does the DISP $3000 decode
correctly = the structural TEMPLATE (but unenriched: 3233 machine labels), re-target
it to the 2.20 binary into the BASE tree `CPMV220-44K/utilities/GBASIC.asm`, then
enrich superset-first (naming + relocating graphics-block re-decode + strings + [DOC]).
MBASIC = the graphics-OFF build of the same engine (PROOF: its "Graphics statement
not implemented" string at $0705 that GBASIC drops) -> decompile it LATER. 2.20 vs
2.23 GBASIC differ by only 56 bytes (console/memory patches, not graphics).

**ALL FOUR PHASES of the source-completion plan are DONE for both 44K trees**
(`CPMV220-44K` + `CPMV223-44K`), this session, on branch
**`softcard-bootloaders-to-standard`** (NOT yet merged to main). Gate: **215 passed**
(`source shared/toolchain/env.sh && python -m pytest softcard/ shared/`). Every OS
file + every utility (except the two BASICs) is byte-identical, ZERO machine labels,
strings as literals, manual-cited. Phases:
- **Phase 1 code-as-bytes:** all live code decoded; embedded 6502 disk engines
  extracted to `<NAME>_6502.s` ca65 + INCBIN (BOOT/CPM56/COPY/STAT, the CPM_RPC6502
  pattern); relocated/self-relocating transient bodies (XSUB/DDT/CPM56-body) decoded
  via DISP; a re-audit corrected over-classified "dead/stale" regions (DUMP/DOWNLOAD =
  real relocated library code; APDOS/STAT strings) and made strings literals (high-bit
  via ca65 `.charmap`). [[feedback_dont_overclassify_dead_or_data]],
  [[feedback_disassemble_all_code_both_cpus]], [[feedback_verify_utf8_after_agent_edits]].
- **Phase 2 semantic naming:** 0 machine labels across OS (CCP/BDOS/BIOS both trees)
  + all utilities. Adversarial-verify caught real errors (BIOS disk-engine mislabeled
  "screen-function"; hidden address-stems; live CALL targets mislabeled as data).
- **Phase 3 [DOC] citations:** CCP/RPC6502/boot loaders/BIOS, grounded in
  `softcard/docs/CPM_Manual_Reconcile_Facts.md`. NEW tag `[DOC Vol1 <page>]` (SoftCard
  Volume 1, 1-x pages) alongside `[DOC CPMREF]` / `[DOC S&HD]`. HARD guardrail: never
  [DOC] a [RE]/version-delta. (Gotcha: `CPMV220-44K/os/CPM_RPC6502.s` is GENERATED by
  `cpm_pipeline/gen_rpc6502.py` AND INCBIN-listed into CPM_CCP.asm -- edit the
  generator + re-run `python -m cpm_pipeline.inject_incbin_listing`, and always run
  the FULL suite, not `-k`, to catch `test_rpc6502`/`test_incbin_listing`.)
- **Phase 4 missing 2.20-44K utilities:** COPY/FORMAT/RW13 (bytes differ ~90% from
  2.20B-56K, absent from 2.23) decompiled byte-identical via `decompile_com` base +
  enrich; each embeds a 6502 disk engine extracted to `<NAME>_6502.s`.

Plan + per-phase detail: [[project_softcard_source_completion_and_tour]]. Two BASICs
(GBASIC/MBASIC) were EXEMPT from the standard -> the GBASIC task above starts that.
**REMAINING beyond GBASIC/MBASIC:** the 56K (`CPMV220`) + 60K (`CPMV223-60K`) trees
are not yet held to the full standard (Phases 1-3 were 44K-only); the CPM56->os/ fold
(tasks #2/#4); then the wiseowl "Guided Tour" article series (source must be final
first -- it now is for the 44K trees).

---

## CURRENT STATE — 2026-06-18 (2.20-44K clean-room decompile DONE + the one-CPMV220-tree fold model)

**The original 1980 SoftCard CP/M 2.20 (44K) disk is now FULLY decompiled clean-room, byte-identical, documented, committed.** Then a follow-on architectural decision (the "fold to one master") is locked and partway implemented. Five commits this session: `296f9b6` (clean-room OS), `0bbd403` (.COM utilities), `e465c7b` (provenance), `8ddab46` (fold analysis), `48af1b4` (relocatable formatter mode); on top of `440b2ae` (2.20-family model doc).

**(A) 2.20-44K clean-room decompile — DONE.** Tree `softcard/CPMV220-44K/` (os/ + utilities/ + README). Built by a multi-agent RE workflow (per region: decompile + adversarial verify, **clean-room: NO 56K/2.23 source consulted**); all 3 OS regions byte-identical + verifier ACCEPT. The whole disk reconstructs **byte-identical** (81% from source); config-aware `'220-44k'` chunk_map variant + `reconstruct._detect_variant` (44K vs 56K by Z-80 reset-plant $AA00/$DA00). Tests: 96 cpm_pipeline + 64 disasm pass. KEY findings: the `$9400-$94FC` region is an **embedded 6502 RPC block** (runs via the CPU-switch, classified as data in the Z-80 image); CP/M messages reached by a **computed position-relative locator** (not a pointer load); BDOS dispatch is **runtime-pointer** (`LD HL,($9F43)`), not a static table. Bases: CCP $9400 / BDOS $9C00 / BIOS $AA00. The `os/` is verified independent of all other versions (only the 12 byte-identical reuse .COMs point out to CPMV220/ + CPMV223-44K/, by DRY choice).

**(B) Shared disassembler upgrades (all opt-in, byte-identical, both CPUs).** In `shared/disasm_*` + `disasm_common`: strings-as-strings (terminator-optional, reference-gated, MIXED-yields-to-string), code-coverage maximization (`disasm_common/coverage.py` + `--auto-coverage`: dispatch resolution + table-target harvest + validated string-walled after-terminal sweep), code->data reference harvesting, and a **`relocatable` formatter mode** (labels every in-range absolute operand address so ORG/DISP can move a module). `decompile_com` uses `--auto-coverage`.

**(C) THE LOCKED FOLD MODEL (task #8, IN PROGRESS — see plan doc).** Per Brent 2026-06-18: **`CPMV220/` becomes the SOLE v2.20 source tree** (os/ <- the clean-room 44K source, replacing the old 2.20B-56K decompile which retires). It builds **ONE `cpm220.dsk`** (44K). **`CPM56.asm` builds `CPM56.COM` by INCLUDE-ing the same os/ sources `ORG`'d to their 56K Language-Card run addresses ($C400/$CC00/$DA00) and `DISP`'d to the `CPM56.COM` file offsets** + install logic, byte-identical (the proven `CPM60.asm` DISP/MODULE pattern — VERIFIED: CPM56.COM embeds the 56K BIOS jump table $DEA8/$DACC.. at file offset $2300). **We never generate cpm220-44k.dsk or cpm220-56k.dsk.** A 56K disk is **emulation-derived** (boot cpm220.dsk + run CPM56.COM); the **2.20B-56K disk is kept as the validation reference**. Sub-version **2.20B via `IF REV_B`** (~10-20 byte delta). EMPIRICAL: config 44K<->56K is **pure +$3000 relocation, NOT Language-Card code blocks** (that was a 60K/2.23 assumption).
**Phase 1 (make os/ DISP-relocatable) — partway:** the `relocatable` mode is added; the SystemImage reassembles BYTE-IDENTICAL at $9300 (GATE 1) and relocated to $C300 the diff vs the real 56K dropped **220 -> 171**. REMAINING relocatability: (a) pin the embedded-6502 block ($9400-$94FC) as a **fixed data region** (do not decode/relocate as Z-80); (b) **`DEFW`-label the data-address tables** (pointer/dispatch, e.g. the $95C2 table); (c) residual operands -> down to the ~20 genuine bytes, which become the `IF REV_B` patch. Guard fixed externals from relocating: page-zero $0005, I/O config $F3xx, 6502 cells $03xx. Then repeat for BIOS + BootLoader.
**Phases 2-4 (not started):** (2) write `CPM56.asm` (install logic + the 3 os/ sources via ORG/DISP at the .COM file offsets) -> byte-identical to the disk's CPM56.COM; (3) consolidate to `CPMV220/` (replace os/, add IF REV_B, retire old 56K os/, repoint pipeline to the canonical `220` variant = cpm220.dsk); (4) validate via `softcard_emu` (boot cpm220.dsk + run CPM56.COM -> compare to the 2.20B-56K reference).
Full analysis + step list: `softcard/docs/CPM_Source_Completion_and_Tour_Plan.md`. Memory: [[project_disasm_string_coverage_tooling]], [[project_softcard_source_completion_and_tour]].

**Still PENDING after the fold:** the 2.23-44K `.COM` [DOC] manual-reconcile (plan item b); the wiseowl "Guided Tour Through the SoftCard CP/M Source Code" project + ~8 articles (plan item c, needs the source final first).

## CURRENT STATE — 2026-06-18 (build/test reorg — older)

**Build/test data system reorganized to best practices + canonical disk standardization.**
- **Single source of truth:** `softcard/cpm_pipeline/reference_data.py` exports `DISK_*` constants + `present()` + `bios_bin()`. All ~14 tests + build_cpm60 + emu import from it; no disk path is hard-coded anywhere.
- **Archive now TRACKED** (`softcard/reference/softcard-cpm-archive/`, 52 files; was untracked) = the one home for every reference disk image. Resolves the pending in-repo hosting decision.
- **Disks de-duplicated:** the 3 in-repo duplicate originals were `git rm`'d (md5-identical to archive copies under misleading names — the repo "CPMV220" disk was actually **2.20B 56K**). Per-release folders now hold SOURCE only; the DERIVED 60K disk stays in CPMV223-60K/. (Unreferenced `.dsk` conversions remain in CPMV220/ — optional cleanup.)
- **Decoupling fix:** `handoff._guess_bios_path` + `version_delta._guess_bios_path_for_disk` no longer walk up from the disk to find `cpm-investigation/bios_NNN.bin` (broke when disks moved to the archive); both delegate to package-relative `reference_data.bios_bin`.
- **Gate:** 167 pass with env.sh; reconstruction byte-identical. NOT committed (staged: archive add + 3 disk rm + ~20 edits). See [[project_test_data_single_source_of_truth]].
- **Original thread — fact-sheet Section 9 "2.20→2.23 Differences" DONE** (`[RE]`/`[DIFF]`, same-config 44K basis). **Config-aware diff tooling COMPLETE:** `bios_220_44k.bin` extracted (physical `0x2200`, ORG `$AA00` = the 56K BIOS −`$3000`); `reference_data.bios_bin` keys on the detected BIOS base; `trace_cold_boot` handles `$AA00`; `version_delta` passes the base. `cpm_pipeline diff <2.20-44k> <2.23-44k>` now auto-traces the 44K BIOS — the dispatch **device-6 delta + `$AA00`-based handlers are TOOL-VERIFIED** (regression test `test_diff_44k_2_20_vs_2_23_is_config_clean`; suite **168 pass**). Version deltas: BIOS rebase `$AA00→$FA00`, dispatch case 6, `$E5`→RST-trap filler, the 11-byte `$Cn0B` probe; the `$CC06→$9C06` BDOS shift was 56K-vs-44K CONFIG noise. **REMAINING (smaller, separate):** the handoff LOADER-SCAN is NOT config-aware — BDOS-entry reports `$CC06` for both 2.20 configs (44K expects `$9C06`), and CPU-switch is "skipped" for 2.20-44K; a future handoff pass. See [[project_reconcile_source_vs_docs]].

## CURRENT STATE — 2026-06-17 (older entries retained below)

**Repo:** the CP/M tree is **`softcard/`** (NOT `cpm-80/`; some memory notes mislabel it). Top level = `apple-ii/ softcard/ shared/`. Per-release CP/M folders `softcard/CPMV223-44K/ CPMV223-60K/ CPMV220/` (each os/ + utilities/ + disk image). Repo-root **`CLAUDE.md`** (created 2026-06-17) is the quick-orientation file. Tests ~109 pass / 24 skip (no setup), ~133 with `source shared/toolchain/env.sh`.

**Active work: the canonical SoftCard / Apple CP/M archive** at `softcard/reference/softcard-cpm-archive/` (UNTRACKED; `MANIFEST.csv` is the authoritative per-file record). Goal: wiseowl.com + github = one-stop source for ALL Microsoft SoftCard / CP/M material. This session (2026-06-17):
- **Cleanup:** deleted source-zips, `ap.cpm.fix` (a 1982 RF-noise HARDWARE fix, NOT the boot bug), the CRUNCH'd ZCPR3 `.lbr`, and `0index`; kept the Thunderclock source. `_excluded/` (4 files, 573 KB) is recommended for deletion but NOT yet confirmed by the user.
- **Photos recompressed** (JPEG q85, <=2400px): 5.4 -> 2.0 MB. Originals backed up to `E:/tmp/photos_orig_backup` (SESSION-ONLY scratch).
- **Schematics:** confirmed TWO DISTINCT documents (not one drawing at two resolutions): `Microsoft_Softcard_rev._E_-_Schematic.png` = Microsoft factory **Rev E, May 1980** (authoritative, low-res 1443x922); `Microsoft_Softcard_-_Schematic_redraw_Schafer_1993.gif` (RENAMED) = a **Patrick Schäfer 1993 CAD redraw** (hi-res 6104x4406, blank REV). MANIFEST provenance corrected.
- **cpm_pipeline** gained `.cpm` support, `dedup`, component `diff`, and CP/M serial + lineage grouping (committed 48f3688). Serial = `BD 16 00` product marker + 3-byte per-copy unit = a per-LICENSED-COPY fingerprint.
- **Manual transcription:** the 5 manual PDFs are pure 1-bit / ~300 DPI scans with NO text layer (so PDF->Markdown is a reconstruction, and CCITT-G4/JBIG2 recompression gives no win). Chosen path: AI vision-transcription to searchable Markdown in `manuals/transcribed/`, with the scanned PDFs kept as the AUTHORITATIVE source. Method: pre-render each page to top/bottom half-PNGs (PyMuPDF+Pillow), then a Workflow fans out one vision agent/page + an adversarial verify agent on every table/code page. **DONE 2026-06-17:** ALL 5 manuals transcribed (404 pages, ZERO missing) to `manuals/transcribed/`: `software-and-hardware-details.md` (38), `cpm-reference-manual.md` (154), `software-utilities-manual.md` (36), `volume-1.md` (62), `volume-2.md` (152), plus `README.md` (per-manual QA + transcriber-flagged spot-check lists) and `figures/` (the 4 CP/M diagrams on cpmref pages 53/63/92/93). A verify pass ran on every table/code page. The 404-page run had to be **THROTTLED to chunks of 5** (a 16-wide fan-out trips a server-side rate limit; see [[feedback_workflow_rate_limit_throttle]]).

**Open (handoff):** (1) [DONE 2026-06-17 — all 5 manuals transcribed + assembled]; (2) HOSTING DECISION for the ~11-14 MB archive (in-repo / git-LFS / GitHub Releases / catalog-with-URLs); (3) secondary MS cards (SoftCard II 2.28B, Premium IIe 2.25/2.26); (4) [DONE — `_excluded/` deleted 2026-06-17]; (5) wiseowl.com reference front-door page; (6) reconcile AI-annotated decompiled source vs the now-archived Microsoft manuals — **OS SOURCES DONE 2026-06-17.** All 16 OS source files across CPMV220 / CPMV223-44K / CPMV223-60K reconciled against the manuals (comment-only; all three trees still reconstruct byte-identical; full suite 167 passed; a source-level check confirms 0 code tokens changed). Mechanism: confirmed the **manuals document CP/M 2.20** (1980 original — Card Type Table tops at value 5 with Videx=value 4, no device-6/Pascal-1.1; all (C) 1980; 44K/56K only), so the reconcile anchors on 2.20 and propagates the version-independent I/O-Configuration-Block / RPC / BDOS facts to the 2.23 trees while flagging the device-6 path + 60K map as post-1980. New `[DOC <manual> <page>]` provenance tag added alongside `[AI]`. Ground-truth artifact: **`softcard/docs/CPM_Manual_Reconcile_Facts.md`** (8-section, cited, version-tagged fact sheet). REMAINING (deferred): the .COM utility decompilations. See [[project_reconcile_source_vs_docs]].

**softcard_emu / CPM60:** softcard_emu now boots the 60K CPM60 system (language-card fetch-banking fix) and reproduces CPM60 in-emulator (tracks 0-1 byte-identical to real); refactored into bus/cpus/switch/keyboard subsystems.

---

**Last updated:** 2026-06-11 (late) — **PUBLISHED HANG MECHANISM OVERTURNED. The real 2.20 failure is $C800 expansion-ROM window ownership destroyed by the SoftCard's own CPU-switch access. Doc-correction cascade now includes de-confirming the series' central conclusion. PENDING USER REVIEW before article updates.**

> **READ FIRST on resume:** `softcard/docs/CPM_SoftCard_RealMap_Findings.md` —
> both 2026-06-11 sessions' findings, in order. Short version:
> (A) The real SoftCard Z-80→Apple translation (Z-80 $F000-$FFFF =
> Apple $0000-$0FFF; $B000-$DFFF = $D000-$FFFF; $E000-$EFFF = Apple
> I/O) replaced the bit-12-XOR model; both Part-12 "unmodeled
> mechanisms" dissolved (they were address-window views, not copies);
> BIOS true bases $FA00 (2.23) / $DA00 (2.20); CPU switch = $C700
> access, both directions.
> (B) `emu_softcard_v2.py` now boots BOTH versions from disk bytes to
> fully interactive systems (typed DIR → full directory listing through
> real Videx firmware): $BE11 sector-level disk service + monitor
> SAVE/RESTORE PC hooks were the missing pieces.
> (C) **2.20 + Videx does NOT hang in the corrected model** — the old
> "device 4 → $DFBE → $E5 fill → PUSH HL → SP wrap" story was an
> XOR-map artifact. The demonstrated mechanism: 2.20 drives the Videx
> via Pascal 1.0 FIXED entries ($C800/$C84D/$C9AA — inside the shared
> $C800-$CFFF window) and performs its $CFFF-deselect/$C300-select
> ownership dance on the Z-80 SIDE, before flipping the bus via $C700 —
> but $C700 is another slot's page, so the flip RELEASES the claim
> (other_slot_c8, A2FPGA-verified Videoterm behavior). Every console
> RPC enters the window unowned → floating bus on real hardware →
> blank screen. 2.23 redoes the dance on the 6502 side AFTER the flip
> ($CFFF at $0E30, $C330 at $0E33, $Cn0D vector dispatch through the
> slot page) — zero faults. v2 differential: 38M window faults + 0
> screen chars (2.20) vs 0 faults + working DIR (2.23).
> CORRECTIONS PUBLISHED (2026-06-11, continuation #2): Part 13 ("The
> Conclusion Was Wrong") + dated Update notes on Parts 1-12, the
> pipeline/round-trip articles, the project entry, and 8 devlogs;
> committed to wiseowl.com (deploy BLOCKED on wrangler auth — run
> `npm run deploy` interactively). Videoterm manual cross-confirms the
> mechanism (SETREGS mandate; SETUP=$C800/KEYIN2=$C84D/PSOUT=$C9A7;
> BYTE=$0678; Pascal 1.1 vectors $C311/$C314/$C31C/$C322). Loose ends
> closed: slot-byte patcher = the slot scanner ($1086-$1090 in 2.23);
> BIOS provenance = entire runtime BIOS verbatim from track 2 (2.23:
> fsec 13..8 → $FA00..$FF00; 2.20: fsec 1..5 → $DA00..$DE00, $DF00
> assembled); cold boot = sparse fixup (~185 bytes, last two pages);
> "half-exists"/generator-pages framing was an extraction artifact.
> DONE (continuation #3): BIOS .asm re-base COMPLETE (ORGs $FA00/$DA00;
> 2.20: 51 relative literals shifted; 2.23: absolute label operands
> re-pointed/literalized, labels renamed to true addresses, 4 semantic
> labels neutralized pending re-attachment); cold_boot_trace.py +
> chunk_map + handoff + tests + README corrected; 95 tests pass, both
> disks reconstruct byte-identical. ALSO DONE: filler regions located
> (track-2 padding sectors ADJACENT to both BIOS blocks — the
> "alternating code/filler pages" was an extraction-window artifact);
> CPM223_DiskCallbacks.asm re-identified (CCP/BDOS-support thunks, Z-80
> $A900+ = Apple $B900+, disk trk2 fsec14; no "$1A00 callbacks" exist);
> 2.20 no-videx boots clean in v2 (full field matrix reproduces:
> 2.20+Videx dead / 2.20 alone fine / 2.23+Videx fine); correction
> banners on CPM_BootTrace.md + CPM_DiskSectorMap.md.
> RELEASE-RULE PROVENANCE (important nuance): videx_card.sv documents
> other_slot_rom as FPGA-specific (physical PAL16L8 = $CFFF-only;
> schematic shows no other-slot decode inputs). The demonstrated kill
> is therefore THE A2FPGA MECHANISM (the original failing platform);
> the physical card's trigger is OPEN — candidates: board-revision
> variance (4013 vs PAL boards), SoftCard bus-phase timing hiding the
> Z-80-side $C300 claim, or a divergent real-hardware report. The
> manual-mandated protocol violation (SETREGS must immediately precede
> every $C800 entry by the fetching CPU) is rule-independent and is
> the durable framing.
> STILL OPEN: (1) Joshua's email symptom check (Gmail MCP needs /mcp
> auth; user recalls "it hung"); (2) DEPLOY the site (wrangler needs
> interactive auth: `npm run deploy`); (3) inline section-comment
> sweeps inside both BIOS .asm files + DiskCallbacks re-annotation;
> (4) BootTrace/SectorMap row-level sweeps (banners in place); (5)
> re-attach the 4 neutralized semantic labels at true positions; (6)
> physical-card release trigger (emails/scope/board-rev research).
> Original deliverables below remain done as BYTE-LEVEL facts; the
> failure-mechanism narrative is superseded.

**Previous milestone (2026-05-04):** INVESTIGATION CLOSED + SUCCESSOR TOOLSET SHIPPED.

14 cpm-related articles + 43 devlogs. Investigation closure article: `cpm-videx-12-the-investigation-closes.mdx` (pubDate 2026-05-02). Central question settled byte-for-byte and emulator-confirmed: **2.20 hangs because device-code 4 (Pascal 1.0 generic) routes the Videx-via-CONOUT through `$DFBE`, which has pure `$E5` PUSH-HL fill on disk; the cold-boot generator doesn't populate it with real handler code, so the first CONOUT call executes `PUSH HL` repeatedly, the Z-80 SP wraps past `$0000`, high memory corrupts. 2.23 fixes this by detecting the Videx as device 6 (Pascal 1.1) via the 11-byte `$Cn0B` check, routing through `$FDB0` instead — which contains a one-byte `RET` stub on disk.** Reproduced byte-for-byte in a from-scratch 6502+Z-80+SoftCard emulator (Stage 3, 2026-05-01).

The `cpm-from-source` successor vision is **realized** as the `cpm_pipeline` package — seven-stage build that takes any CP/M 2.20/2.23 `.dsk` and produces verified-byte-identical reconstruction from annotated source. Every byte-level finding from the cpm-videx investigation now falls out of `python -m cpm_pipeline diff` in 200 ms.

This file is the canonical session-recovery prompt. **If this conversation crashes or context is lost, hand this file to a fresh assistant and it should be able to pick up where things stand without losing any directives, conventions, or progress.**

---

## What's New since 2026-05-02 (closure → toolset shipping)

The investigation closed on 2026-05-02 with the "future tool" vision in `softcard/docs/CPM_PIPELINE_ROADMAP.md`. Between 2026-05-03 and 2026-05-04 that vision became reality:

**Disassembler infrastructure (2026-05-03):**

- New top-level packages `disasm6502/`, `disasm_z80/`, `disasm_common/` at the repo root. Production-quality, ca65/sjasmplus output, recursive-descent walker + JSON symbol-table input + a second-pass data analyzer (strings, fills, jump tables, pointer tables). Both packages round-trip byte-identical against real CP/M binaries.
- `nibbler/disasm.py` and `nibbler/z80.py` **deleted** as dead middle layer; nibbler is back to being a pure WOZ-disk-analysis toolkit. Apple-panic Walkthrough migrated to reference `disasm6502`.
- All 11 hand-annotated `softcard/docs/CPM*.asm` files **now reassemble byte-identical** via ca65/ld65 (6502) or sjasmplus (Z-80). Six pytest regression tests in `softcard/cpm-investigation/tests/test_annotated_docs.py` enforce the round-trip property going forward. The bring-up surfaced **9 real bugs** in pre-existing prose annotations (duplicate banner header, 459-byte "GAP" not emitted, JMP_TABLE misinterpretation, off-by-one labels, etc.) — see the round-trip-discipline article and devlog for the catalog.

**`cpm_pipeline` package (2026-05-04):**

Seven-stage Python package implementing the roadmap end-to-end:

| Stage | CLI verb | What it does |
|---|---|---|
| 1 | `detect` | Boot-stub + skew table + variant ID via 16-byte SoftCard signature + 12-byte Pascal-1.1 signature |
| 2 | `trace` | Pattern-match install-copy loops + disk-helper calls in stage-2 |
| 5 | `trace-z80` | Parse BIOS jump table + trap-marker pages + cold-boot generator + dispatch cases |
| 4 | `handoff` | Find Z-80 reset vector plant + BDOS entry plant + CPU-switch trigger |
| 3 | `diff` | Compare two disks at the routine level — Videx fix surfaces as `cases_only_in_b: [6]` |
| 7 | `build` | Assemble all `softcard/docs/CPM*.asm` and place per chunk map → `.dsk`/`.po` byte-identical |
| 6 | `generate` | End-to-end orchestration: produce a complete annotated source tree with build script |

95 tests pass (was 50 at investigation closure). Both target disks (CPMV223-44K.DSK + CPMV220-Disk1.po) reconstruct byte-identical from a single CLI invocation; Phase 7's auto-generated build.sh closes the loop.

**New documentation:**

- `softcard/docs/CPM_BootTrace.md` (556 lines) — synthesis sector-0-to-A-prompt across both 2.20 and 2.23
- `softcard/docs/CPM_PIPELINE_ROADMAP.md` (431 lines) — the seven-stage build plan that drove the work
- `cpm_pipeline/README.md` — package overview with all current CLI verbs

**New writeups (wiseowl.com):**

- Articles: `round-trip-discipline-disassembler-bug-detector` (2026-05-03), `cpm-pipeline-seven-stages` (2026-05-04)
- Devlogs (4 new): `cpm-videx-fb45-code-overlap-2026-05-03`, `cpm-videx-roundtrip-bug-detector-2026-05-03`, `cpm-videx-pipeline-mechanically-reproduces-investigation-2026-05-04`, `cpm-videx-pipeline-chunk-map-off-by-one-2026-05-04`

---

## The Project (the durable goal — now achieved)

Reverse-engineer Microsoft's Apple ][ Z-80 SoftCard CP/M completely — both **2.20** (which fails to boot when a Videx Videoterm 80-column card is installed) and **2.23** (which boots and runs cleanly with the same hardware). The original deliverables were:

1. ✅ Complete description and disassembly of CP/M 2.20 and 2.23, from boot sector through SoftCard switch into Z-80 mode.
2. ✅ Z-80 disassembly of the entire CP/M system (CCP + BDOS + BIOS) for both versions.
3. ✅ Narrative walking the reader from power-on to the `A>` prompt, with full understanding and version diff.

All three are done. The cpm-from-source successor project additionally produces a byte-identical .DSK from the annotated sources via a build tool.

The project is hosted on:
- **Code/disasm repo:** [Orchard](https://github.com/BrentRector/orchard) at `e:/Orchard/`
- **Personal site (publishing):** [wiseowl.com](https://wiseowl.com) at `e:/Sites/wiseowl.com/`. NOT the same as wiseowlsoftware.com (the separate Demeanor product site).

---

## Origin Story

Joshua Norrid (of A2FPGA fame) reported that Microsoft SoftCard CP/M wasn't booting with the A2FPGA Videx Videoterm emulation. He confirmed the same failure on real Videx hardware — so the emulation is faithful, the OS is what's broken. Brent (the user/author) doesn't yet have a physical Microsoft Z-80 SoftCard ("supposedly in the mail") so all analysis is static disassembly + emulator; Joshua's hardware confirms predictions when needed.

Version testing isolated the boundary: **2.20 and 2.20B fail; 2.23 works**.

---

## What's Now Understood (the architecture)

End-to-end. NOTE: the byte-level boot facts below are accurate, but the FAILURE-CAUSE narrative
(the `$E5`/`PUSH HL`/`$DFBE` device-4 hang in items 10/12 and the section that follows) was
OVERTURNED 2026-06-11 — the real cause is the `$C800` expansion-ROM window-ownership loss (see the
overturn banner above + `softcard/docs/CPM_SoftCard_RealMap_Findings.md`).

### The 6502 boot stage (Parts 1-4)

1. **Disk II P6 PROM** loads sector 0 of track 0 to Apple `$0800-$08FF` and `JSR $0801`.
2. **Boot stub** at `$0801-$083C` (byte-identical between 2.20 and 2.23) loads 10 more sectors of track 0 in CP/M skew order (`0,2,4,6,8,A,C,E,1,3,5`) via the P6 PROM's mid-routine entry. Then `JMP $1000`.
3. **Stage-2 loader** at `$1000`: language card RAM enable, Apple monitor TEXT/SETVID/SETKBD, three install loops staging Z-80 code into low Apple memory, then **slot scanner** at `$1060-$10D5`.
4. **Slot scanner** walks slots 7→1, probes `$Cn05/$Cn07`, records device codes at `$03B9-$03BF`. **2.23 added an 11-byte branch** that also reads `$Cn0B` (Pascal 1.1 signature) and tags Pascal-1.1 cards with device code `$06`. *This is the entire bug fix.*
5. **LOAD_CPM** at Apple `$0BEB` reads 29 sectors starting trk0:`$0B`, stages at `$8000-$9CFF`. **There's a SECOND LOAD_CPM call** that handles CCP+BDOS relocation (devlog `cpm-videx-second-load-cpm-call-2026-04-28`).
6. **PREP_HANDOFF** does three page copies splitting the staging into BIOS callbacks at `$0A00`, system image at `$A300`, original RWTS preserved at `$BA00`.
7. **Z-80 reset vector planted** at Apple `$1000-$1002`: 2.23 plants `JP $FA00`, 2.20 plants `JP $DA00`.
8. **CPU switch fires when 6502 PC reaches `$0E36`** (Part 10 / `cpm-videx-cpu-switch-trigger-2026-04-30`). Confirmed via emulator: any 6502 instruction execution at this address is monitored by SoftCard hardware and triggers the bidirectional Z-80 takeover.

### The Z-80 side (Parts 5-9)

9. **Z-80 starts at `$0000`** = Apple `$1000`, reads `JP $FA00`, jumps to BIOS cold-boot.
10. **BIOS layout is 256-byte interleaved** (4 code pages alternating with 4 runtime-generated pages — corrected from "first/second half" framing in earlier devlogs). 2.20 fills generator slots with `$E5` (= `PUSH HL`); 2.23 uses `FF FF 00 00 / F7 F7 00 00` (RST traps if executed prematurely — safety upgrade).
11. **Cold-boot real code resumes** at `$DECC` (2.20) / `$FF0E` (2.23). The post-padding device-scan loop is **structurally identical across versions** — the BIOS factory itself doesn't differ. The fix lives entirely in what device codes the loader feeds it.
12. **Cold-boot generator** populates the runtime-generated pages with per-device handler code (Part 6). For device code 4 (Pascal 1.0 generic), it generates a handler that dispatches to `$DFBE` (in 2.20) — but `$DFBE` is in a generator-padding page filled with `$E5`. For device code 6 (Pascal 1.1), 2.23 dispatches to `$FDB0` — which is a one-byte `RET` stub.
13. **Cooperative-CPU disk I/O model**: Z-80 BIOS routines write parameters into BIOS state area, call into Z-80 disk callbacks at `$1A00`, signal 6502 via `$E000`/`$E010` flag pair (polling loop at Z-80 `$1E36-$1E44`). SoftCard switches CPUs. 6502 reads same state, runs original RWTS at `$BA00-$BFFF`, deposits sector data, signals completion. SoftCard switches back. (Part 8.)

### The 2.20 boot failure — CORRECTED (see the 2026-06-11 overturn banner above + `softcard/docs/CPM_SoftCard_RealMap_Findings.md`)

**The old "device-4 → `$DFBE` → `$E5`/`PUSH HL` → SP-wrap" hang ("Case B") was OVERTURNED** — it
was an artifact of the wrong bit-12-XOR memory model. The real failure is a SHARED-WINDOW
ownership fault. 2.20 drives the Videx through Pascal-1.0 FIXED entries inside the `$C800-$CFFF`
expansion-ROM window and performs its `$CFFF`-deselect / `$C300`-select ownership dance on the
**Z-80 side**, then flips the bus via a `$C700` access — but `$C700` is another slot's page, so
the flip RELEASES the window claim. Every subsequent console RPC enters the window UNOWNED →
floating bus on real hardware → blank screen / dead boot. 2.23 redoes the deselect/select dance on
the **6502 side AFTER** the flip, so the window stays owned. The boot-time detection delta (2.23's
extra `$Cn0B` Pascal-1.1 probe tagging the Videx device 6) is real but is the SMALLER half of the
fix, not the boot-failure cause. The physical-card release trigger remains OPEN; the demonstrated
kill is the A2FPGA mechanism (the differential: 38M window faults + 0 screen chars for 2.20 vs 0
faults + working DIR for 2.23).

### Pascal 1.0 vs 1.1 calling-convention precision (Part 1)

- **Pascal 1.0**: ID bytes ARE the entry points. `$Cn05 = $38` is `SEC`; `$Cn07 = $18` is `CLC`. `JSR $Cn05` does input (carry set), `JSR $Cn07` does output (carry clear).
- **Pascal 1.1**: 4-byte vector table at `$Cn0D-$Cn10` (INIT, READ, WRITE, STATUS). Caller reads offsets, JSRs to `$Cn00 + offset`, MUST call INIT before READ/WRITE/STATUS.
- Pascal 1.1 cards declare BOTH ID sets but only implement the 1.1 calling convention.
- 2.20 sees a Videx → Pascal 1.0 ID match → drives it through the FIXED `$C800`-window entries (the boot failure is the window-ownership loss above, NOT a `$Cn07` hang — "Case B" was overturned).
- 2.23 reads `$Cn0B` → Pascal 1.1 → routes through 1.1 vector table → works.

---

## Decision Points and User Directives (still apply for any successor work)

- **Investigation path: Path A** (reverse-engineer LOAD_CPM rather than build a Z-80 emulator) chosen on 2026-04-27. Path A unlocked the static analysis. Then user directed building the emulator anyway when static evidence couldn't fully settle the v2.20 hang failure mode (2026-04-29).
- **Article structure**: each part is a beginning-to-end narrative, reads as a story.
- **Devlog granularity**: one per topic / approach / area of investigation, NOT one per day.
- **Resume-prompt.md kept current** at all times (this file).
- **Site placement**: wiseowl.com personal site (NOT wiseowlsoftware.com).
- **Article 1 framing**: opens with "The Microsoft Z-80 SoftCard wouldn't work with my Videx 80-column emulation. Seemingly."
- **Disassemblers documented as separate tools** on wiseowl.com (not bundled under nibbler), even though they share repo home in `nibbler/`.
- **Corrections, not rewrites**: when later findings refine earlier devlogs/articles, ADD a forward-pointer Update note. Don't silently rewrite the body. The misinterpretation is part of the investigation narrative.

---

## Editorial Guidance (saved to memory; restated for any successor work)

- **Lead with consequence, not detection.** The act of finding a code delta is the door, not the room.
- **State things clearly, not cleverly.** Cryptic article titles bad; descriptive ones good.
- **Honesty over completeness.** Distinguish "known from reading the code" from "plausible hypothesis pending verification."
- **Don't conflate shared address spaces with specific cards.** `$C800-$CFFF` is the Apple ][ shared expansion-ROM window. (User caught a Videx overreach on this earlier in the project.)
- **Voice for devlogs**: terse, declarative, past tense, NO first-person pronouns. Em dashes for asides. ~200-400 words. End with `**Status:**`.
- **Voice for articles**: long-form (~3000 words, 12-15 min reads), first-person allowed and natural.

---

## Website Structure (current state)

The site at `e:/Sites/wiseowl.com/` is Astro v6, deployed to Cloudflare Pages.

### Project entries (`src/content/projects/`)

- `cpm-videx.mdx` — "Microsoft SoftCard CP/M on a Videx", `featured: true, weight: 5`. **The project entry's "What's settled / open" section is stale** — written before Parts 5-12 + the emulator + cpm-from-source. May need refresh to reflect the closed state and link the successor project.
- `cpm-from-source.mdx` — **NEW project** (started 2026-04-29), `featured: true, weight: 6`. Annotated 6502 + Z-80 sources for both versions, plus a build tool that round-trips a byte-identical .DSK from chunks. Successor to cpm-videx.

### Articles — RESTRUCTURED 2026-06-11

The original 13-part chronological `cpm-videx-NN` series (12 parts +
Part 13 correction) was **DELETED** at user direction ("too difficult
to follow" after the mechanism overturn) and replaced by the 7-part
**softcard-videx** series — system-first, happy decode path, with
small "**Wrong turn:**" blockquote asides for the discovery flavor.
301 redirects for all retired slugs live in `public/_redirects`;
devlogs remain the unedited chronological record.

| # | Slug | Covers |
|---|------|--------|
| 1 | `softcard-videx-01-the-bug-and-the-fix` | whole story arc + version delta table |
| 2 | `softcard-videx-02-booting-a-z80-os-on-a-6502-machine` | P6 PROM → stub → scanner/patcher → handoff |
| 3 | `softcard-videx-03-the-softcards-real-memory-map` | 4 windows; dissolved mysteries; BIOS provenance; 44/56/60K |
| 4 | `softcard-videx-04-two-cpus-one-bus` | warm loop, $45-$48 RPC, patched JSR, $C700 switch, RWTS |
| 5 | `softcard-videx-05-the-shared-window` | C8 ownership, Videoterm entries, kill sequence, fix, open probe |
| 6 | `softcard-videx-06-the-emulator-that-boots-both` | v2 emulator, fault differential, field matrix, model gaps |
| 7 | `softcard-videx-07-how-the-wrong-answer-got-confirmed` | post-mortem (replaces old Parts 12+13) |

Standalones kept: `round-trip-discipline-disassembler-bug-detector`
(2026-05-03), `cpm-pipeline-seven-stages` (2026-05-04). Project entry
`cpm-videx.mdx` rewritten to the corrected story. Tools section gained
`softcard-emulator.mdx`.

ALSO NEW (2026-06-11): 3-part `softcard-emu-series` about the emulator
itself (01-why-static-analysis-wasnt-enough, 02-building-a-two-cpu-
machine-in-python, 03-what-a-working-replica-discovered), pointing to
the Orchard GitHub repo for download; cross-linked from softcard-videx
Part 6, the tools page, and the project entry.

### softcard_emu package (NEW 2026-06-11, continuation #4)

The v2 emulator is packaged as the reusable top-level `softcard_emu/`
package (machine.py + langcard.py + videx.py + CLI + README + 5 smoke
tests; `python -m softcard_emu DISK --keys "DIR\r"`).
`softcard/cpm-investigation/emu_softcard_v2.py` is now a deprecation shim.
NEW HARDWARE: Apple language card (banked $D000-$FFFF, $C080-$C08F
semantics; 2.20B's 56K LC-resident BIOS runs through honest banking).
FINDING: the 44K-vs-60K banner question dissolved — CPMV223-44K.DSK's
boot tracks ARE the 44K build (banner inside the BIOS pages, trk2
fsec8); "60K" strings belong to trk2 fsec7 + CPM60.COM (the 60K
system loader on the filesystem). April's thread mislabeled the disk.
OPEN: `CPM60` does not come up in-emulator — loads (92 sector reads,
3 writes), zeroes the BOOT entry of the $0A00 jump table, never
populates LC RAM, wedges in a CONST-poll RPC ping-pong (warm operand
$0E14, Z-80 at $FB4B). 60K bring-up = next emulator investigation.
All 100 repo tests pass.

### Dev logs (`src/content/devlogs/cpm-videx-*.mdx`) — 43 published

Most recent toolset-era entries (post-investigation closure, 2026-05-03 → 2026-05-04):
- `cpm-videx-pipeline-mechanically-reproduces-investigation-2026-05-04` — every cpm-videx finding now falls out of one CLI invocation
- `cpm-videx-pipeline-chunk-map-off-by-one-2026-05-04` — debugging story: the Apple `$0900` P6 PROM workspace gap
- `cpm-videx-fb45-code-overlap-2026-05-03` — Z-80 idiom: byte at `$FB45` is both JR displacement AND alternate entry
- `cpm-videx-roundtrip-bug-detector-2026-05-03` — 9 real bugs in pre-existing prose annotations surfaced mechanically

Earlier emulator-era entries (still the most-cited for follow-up work):
- `cpm-videx-emulator-stage1-2026-04-29` — 6502 boot harness boots both versions
- `cpm-videx-emulator-stage2-2026-04-29` — Z-80 emulator + SoftCard XOR + CPU-switch model
- `cpm-videx-emulator-stage3-detection-2026-04-30` — Videx slot-3 model + IX/IY opcodes
- `cpm-videx-emulator-220-architecture-2026-04-30` — 2.20 emulator boot architecture
- `cpm-videx-emulator-coldboot-generator-2026-05-01` — cold-boot generator runs in emulator
- `cpm-videx-emulator-220-hang-settled-2026-05-01` — **Case B confirmed** (PUSH HL stack overflow)
- `cpm-videx-cpu-switch-trigger-2026-04-30` — `JSR $0E36` mechanism
- `cpm-videx-rwts-disassembly-2026-04-29` — full 6502 RWTS at $0A00-$0FFF classified
- `cpm-videx-220-hang-byte-trace-2026-04-29` — factual byte-level static trace (pre-emulator)
- `cpm-videx-cold-boot-generator-found-2026-04-28` — generator at `$FB3A` (2.23) / `$DB6E` (2.20)
- `cpm-videx-220-vs-223-coldboot-2026-04-28` — cold-boot side-by-side
- `cpm-videx-bios-jump-table-correction-2026-04-28` — corrects BOOT-vs-LIST confusion
- `cpm-videx-fdb0-stub-2026-04-28` — `$FDB0` is a single `RET`
- `cpm-videx-device-scan-identical-2026-04-28` — device-scan structurally identical 2.20 vs 2.23

(See `ls e:/Sites/wiseowl.com/src/content/devlogs/cpm-videx-*` for the full chronological list of all 43.)

### Reference (`src/content/reference/`)

- `apple-ii-tn-misc-8-pascal-1-1-firmware-protocol.mdx` — full text of Apple Tech Note Misc #8
- `cpm-videx-disk-sector-map.mdx` — 560-row map of every physical sector → role → final address. Pointer to `softcard/docs/CPM_DiskSectorMap.md` in the Orchard repo. **The natural capstone reference.**
- `videx-videoterm-manual.mdx`, `thunderclock-plus-manual.mdx` — pre-existing
- `public/reference/apple-ii-technical-notes-1989-09.pdf` — source PDF

### Tools (`src/content/tools/`)

- `nibbler.mdx` — WOZ analysis toolkit
- `6502-disassembler.mdx` — standalone 6502 disasm
- `z80-disassembler.mdx` — standalone Z-80 disasm

### Frontmatter constraints (build will fail if violated)

- Devlog `tldr` ≤ 200 chars
- Article `description` ≤ 300 chars
- Project `summary` ≤ 300 chars
- `tags` from `TagEnum` only (in `src/content.config.ts`); add new tags to enum BEFORE using
- Numeric-prefix tags (`6502`) MUST be quoted as `"6502"` in YAML block-style arrays

### Build / deploy

- Local build: `npm run build`
- Build + deploy to Cloudflare Pages: `npm run deploy` (= `astro build && wrangler pages deploy dist --project-name wiseowl`)
- Wrangler is globally installed.

### Site wordmark

- "Wise Owl — Brent Rector" (NOT "Wise Owl Software" — that's the separate product site).

---

## Repository Conventions

### Orchard repo (`e:/Orchard/`)

```
Three top-level trees (reorganized 2026-06-13 — see README.md for the map). The
six Python packages still import by bare name; conftest.py / env.sh / pip -e make
them resolvable. ca65/sjasmplus paths inside docs/CPM*.asm resolve with cwd=softcard/.

apple-ii/                 — Apple II reverse-engineering work
  apple-panic/              — game RE: WOZ, disassembly, assets, write-ups
  scripts/                  — ~38 Apple Panic investigation scripts (working artifacts)
  docs/
    DiskII_BootROM.md / .asm  — Apple Disk II P6 PROM (pre-existing)

softcard/                   — CP/M-80 / Microsoft SoftCard work
  cpm-investigation/        — extraction scripts, intermediate binaries, disassemblies,
                              emulator (2026-04-29), original build harness, regression
                              tests for the annotated docs (test_annotated_docs.py)
  cpm_pipeline/             — seven-stage CP/M reverse-engineering pipeline. CLI: detect,
                              trace, trace-z80, handoff, diff, generate, build. Both target
                              disks reconstruct byte-identical.
    disk_format.py            — DOS 3.3 / ProDOS interleave + sector-offset math
    format_detect.py          — Stage 1: boot-stub fingerprint + skew + variant ID
    loader_trace.py           — Stage 2: install-copy + disk-helper-call detection
    cold_boot_trace.py        — Stage 5: BIOS jump table + cold-boot generator + dispatch
    handoff.py                — Stage 4: vector plants + CPU-switch trigger
    version_delta.py          — Stage 3: routine-level diff between two disks
    reconstruct.py            — Stage 7: assemble all annotated source → byte-identical .dsk
    generate.py               — Stage 6: end-to-end orchestration into a complete tree
    chunk_map.py              — hand-maintained sector→bin slice mappings (per variant)
    assemble.py               — wraps ca65/ld65 (6502) and sjasmplus (Z-80)
  softcard_emu/             — reusable whole-system SoftCard emulator: 6502 + Z-80 share
                              one Apple memory image. python -m softcard_emu DISK --keys "DIR\r"
  docs/
    CPM_Videx_Difference.md           — slot scanner side-by-side diff
    CPM_BootLoader.md                 — narrative architecture of the 6502 loader
    CPM_BootTrace.md                  — synthesis sector-0 to A> prompt
    CPM_PIPELINE_ROADMAP.md           — seven-stage build plan
    CPM_DiskSectorMap.md              — 560-row map of every physical sector
    CPM_Filesystem.md                 — CP/M filesystem area (tracks 3-34) overview
    CPM_SoftCard_RealMap_Findings.md  — real SoftCard address map + 2.20 hang mechanism
    CPM223_*.asm                      — annotated 6502 + Z-80 source, 2.23 (round-trip byte-identical)
    CPM220_*.asm                      — same set for 2.20, all round-tripping byte-identical
  disks/
    CPMV223-44K.DSK               — CP/M 2.23 disk image (DOS 3.3 order — V233 is a misnomer for 2.23)
    CPMV220-Disk1.po            — CP/M 2.20 distribution disk 1 (ProDOS sector order)
    CPMV220-Disk2.po            — CP/M 2.20 distribution disk 2

shared/                   — reusable tooling used by both trees
  nibbler/                  — Apple ][ WOZ-disk-analysis toolkit (DISASMS REMOVED 2026-05-03)
    z80_cpu.py                — Z-80 emulator (used by softcard/cpm-investigation + softcard_emu)
    cli.py                    — info / scan / protect / nibbles / boot / decode / dsk / flux
  disasm6502/               — production 6502 disassembler. ca65/ld65 output, byte-identical
                              round-trip. opcodes (256+50 undoc), symbols, walker, formatter, CLI.
  disasm_z80/               — production Z-80 disassembler. Full prefix coverage
                              (base/CB/ED/DD/FD/DDCB/FDCB = 1280 positions). sjasmplus output.
  disasm_common/            — shared analyzer.py: classifies non-code byte runs into strings,
                              fills, jump tables, pointer tables. Used by both disasm packages.
  symbols/                  — JSON symbol-table inputs: apple2.json, cpm_2_2.json,
                              cpm_2_23_bios.json. Schema v1.0 in shared/symbols/README.md.
  toolchain/                — Local toolchain: ca65 V2.19 + sjasmplus v1.23.0 (gitignored
                              binaries; install via shared/toolchain/README.md). Source
                              shared/toolchain/env.sh for assemblers on PATH + PYTHONPATH.

pyproject.toml            — declares the six packages for `pip install -e .`
conftest.py               — adds the three trees to sys.path so pytest works with no install
resume-prompt.md          — THIS FILE
```

**Test count:** 100 total across all packages (cpm_pipeline 32, softcard/cpm-investigation/tests 11 annotation regressions, disasm6502 11, disasm_z80 21, disasm_common 15, plus 10 elsewhere). With `source shared/toolchain/env.sh` active: 100 pass / 0 skip; without the assembler toolchain: 81 pass / 19 skip.

---

## Memory Directory

`C:/Users/brent/.claude/projects/e--Orchard/memory/` contains semantic project memory:

- `MEMORY.md` — index (auto-loaded)
- `project_cpm_videx_investigation.md` — investigation status
- `reference_apple_pascal_firmware_protocol.md` — Pascal 1.1 protocol + Tech Note Misc #8
- `reference_wiseowl_devlogs.md` — devlog conventions, schema, voice
- `feedback_finding_vs_consequence.md` — editorial: don't celebrate detection
- `feedback_apple_ii_address_specificity.md` — editorial: don't conflate shared address spaces with specific cards
- `feedback_devlog_corrections.md` — editorial: forward-pointer Update notes, don't silently rewrite

---

## What's Done / What Could Still Be Done

The cpm-videx investigation itself is **closed** — central question settled, emulator-verified, article series has a closing reading guide (Part 12), all major boot-pipeline mechanisms documented.

The `cpm_pipeline` toolset is **shipped** — seven stages, 95 tests, both target disks reconstruct byte-identical from a single CLI invocation. The `cpm-from-source` successor vision is realized.

### Architectural mechanisms still unmodeled (bounded, not blocking)

Two mechanisms documented in Part 12 remain unmodeled. Both affect *how* the BIOS gets fully populated, not *whether* the central detection-and-dispatch delta works.

1. **`$03B8` → `$F3B8` slot-info copy.** The 6502-side device-code table at `$03B9-$03BF` somehow ends up readable by the Z-80 BIOS at `$F3A0`+ in its device-scan loop. The copy step itself isn't traced. Likely happens via the runtime-population step or an early Z-80 BIOS routine.

2. **`bios_223.bin` → `$FAB8` BIOS load.** The 1 KB of BIOS bytes that come from the LOAD_CPM staging end up at Apple `$0C00-$0FFF` after PREP_HANDOFF. They get copied to LC RAM at `$FAB8-$FEB7` somewhere, but the exact 6502 (or Z-80) instruction that does this is unmapped. Probably a routine in the install fragments at `$0200-$03FF` runs after the SoftCard switch and before BIOS cold-boot.

Both fit a future "bidirectional CPU switch + LC RAM bank" emulator pass that fully models the SoftCard's switching protocol and the language card's bank semantics. Not blocking anything currently.

### Pipeline follow-on enhancements (each independent, none blocking)

Per `softcard/docs/CPM_PIPELINE_ROADMAP.md`'s open-questions inventory and the `cpm-pipeline-seven-stages` article's "what stayed manual" section:

1. **Auto-generated annotated source.** Stage 7 currently copies pre-existing `softcard/docs/CPM*.asm` files. A future enhancement would have it invoke `disasm6502`/`disasm_z80` directly, using the structural analysis from prior stages to seed entry points and data regions. Output would be byte-identical for known regions and fall back to less-prose-heavy disassembler output for newly-explored regions.

2. **Auto-derived chunk map.** `chunk_map.py` is hand-maintained. Stage 2's `LoadSchedule` has the structural information needed (the install copies tell you where bytes get moved during boot); the auto-derivation isn't wired up.

3. **Symbolic execution.** Pattern-matching handles SoftCard CP/M's particular shapes. A boot loader using indirect control flow patterns (e.g. `JMP (zero_page_pointer)` with the pointer set elsewhere) would need symbolic execution. SoftCard variants don't need it; other systems might.

4. **Non-SoftCard CP/M variants.** Apple's own CP/M card, IBM-PC CP/M-86, CP/M Plus. Different boot architectures. The pipeline's signature constants are SoftCard-specific; new variants need new signatures (per-variant inspection effort) and possibly new pattern-matchers.

5. **WOZ input.** The pipeline accepts `.dsk` and `.po`. nibbler handles the GCR decode for WOZ; integrating it as a Stage 0 would let `detect` start from raw flux directly (useful for copy-protected disks).

None block the headline result.

---

## Quick-Reference Address Map (for fast context recovery)

### Apple ][ memory after the loader finishes

- `$0800-$08FF`: boot stub (sector 0)
- `$0A00-$0FFF`: Z-80 disk callbacks + BIOS first 1 KB (depending on version layout)
  - 2.20: BIOS first 1 KB at `$0A00-$0DFF`, callbacks at `$0E00-$0FFF`
  - 2.23: callbacks at `$0A00-$0BFF`, BIOS first 1 KB at `$0C00-$0FFF`
- `$1000-$1002`: Z-80 reset vector (`$C3 $00 $FA` for 2.23, `$C3 $00 $DA` for 2.20)
- `$0200-$03FF`: Z-80 install fragments (warm-boot routine at `$03C0`)
- `$03B9-$03BF`: per-slot device codes (built by slot scanner)
- `$A300-$B9FF`: CCP + BDOS + banner string (from sysimg)
- `$BA00-$BFFF`: original 6502 RWTS routines (preserved by PREP_HANDOFF #1; see `softcard/docs/CPM223_RWTS.asm` for byte-by-byte map)

### Z-80 memory after CP/M is running

- `$0000-$0002`: Z-80 reset vector (`JP $FA00` planted by 6502; rewritten to `JP $FA03` after first cold-boot)
- `$0003-$00FF`: Z-80 zero page / restart vectors
- `$0100-$E3FF`: TPA (Transient Program Area)
- `$E400-$EBFF`: CCP (after relocation)
- `$EC00-$F9FF`: BDOS (after relocation)

**BIOS at `$FAB8-$FFFF` uses 256-byte interleaved layout** (4 code pages alternating with 4 runtime-generator pages):
- `$FAB8-$FBB7`: code page (jump table, inline LISTST/SECTRAN, dispatch table area, internal routines)
- `$FBB8-$FCB7`: generator page (`FF FF 00 00 / F7 F7 00 00` on disk → real handler code at runtime)
- `$FCB8-$FDB7`: code page
- `$FDB8-$FEB7`: generator page (`$FDB0` is in this page's tail — the device-6 dispatch target, a `RET` stub on disk)
- `$FEB8-$FFB7`: code page (BOOT vector target `$FED1` is in this page's runtime-generated prefix; real code at `$FF0E`+ is the device-scan loop)
- `$FFB8-$FFFF`: generator page (per-device handler code)

**Per-device state slots** (in runtime-generated regions): `$FECB` track, `$FED2` sector, `$FED4` DMA, `$FECD` cold-boot state byte.

**2.20 BIOS at `$DACC-$E2FF`** uses the same 256-byte interleave with `$E5` filler in generator pages. BOOT vector `$DEA8`, real code resumes at `$DECC`. (The old "device-4 → `$DFBE` `$E5`-page = hang trigger" reading was a bit-12-XOR-map artifact and is SUPERSEDED — the real boot fault is the `$C800` window-ownership loss; see the overturn banner.)

### SoftCard memory mapping (CORRECTED 2026-06-11 — the bit-12-XOR model was WRONG)

The real Z-80 ↔ Apple address translation (replaces the old bit-12-XOR model):
- Z-80 `$F000-$FFFF` = Apple `$0000-$0FFF`
- Z-80 `$B000-$DFFF` = Apple `$D000-$FFFF`
- Z-80 `$E000-$EFFF` = Apple I/O (`$C000-$CFFF` soft switches / slot ROMs)
- elsewhere: 1:1. BIOS true bases `$FA00` (2.23) / `$DA00` (2.20). See `softcard/docs/CPM_SoftCard_RealMap_Findings.md`.

### Key 2.20 vs 2.23 differences

- **Slot scanner**: 2.23 has 11 extra bytes for the Pascal 1.1 check; produces device code `$06` for Videx instead of `$04`
- **Cold-boot generator dispatch**: device 4 (Pascal 1.0) vs device 6 (Pascal 1.1, via 2.23's `$Cn0B` tag) take different runtime dispatch paths; the device-6 → `$FDB0` `RET`-stub is a real byte fact, but the 2.20 boot failure is the `$C800` window-ownership loss, NOT a device-4 `PUSH HL` hang (overturned)
- BIOS load address: 2.20 at `$DACC`, 2.23 at `$FAB8` (8 KB shift)
- BIOS jump table in staging: 2.20 at offset `$1700`, 2.23 at `$1900`
- BIOS first 1 KB final position in newdisk: 2.20 at start (`$0A00`), 2.23 at end (`$0C00`)
- Boot banner string: present in 2.23, absent in 2.20
- Generator-page filler pattern: 2.20 uses `$E5`; 2.23 uses `FF FF 00 00 / F7 F7 00 00` (RST-trap bytes). This filler-hardening byte delta is real, but it is NOT the boot-failure cause (the "PUSH HL bug class" framing was overturned)

### CPU switch mechanism

- **Trigger**: 6502 PC reaches `$0E36`. SoftCard hardware monitors this address and flips to Z-80 (Part 10 / `cpm-videx-cpu-switch-trigger-2026-04-30`).
- **Direction**: bidirectional (Z-80 can flip back to 6502). The cooperative-CPU disk model in Part 8 documents the round-trip.
