# SoftCard CP/M — 56K / 60K OS fold plan (separate build vs conditional compile)

**Status:** plan of record, 2026-06-29. Empirically grounded by the
`cpm-56k-60k-fold-eval` evaluation workflow (5 analyses + 2 adversarial
verifications, every claim checked against assembled/booted bytes, not docs).

## The question

For a given memory configuration (44K main RAM, 56K language card, 60K language
card), should the resident OS core — **BIOS / BDOS / CCP** — be a **separate
source** per config, or **one conditionally-compiled source** shared with the
44K base tree?

## The answer (module- and axis-specific)

**Conditional compilation for the 2.20 family; module-split for the 2.23 60K.**
This confirms — now with byte-level evidence — the long-standing HYBRID
conclusion in memory `project_shared_source_tree`: *CCP genuinely shared across
ORGs; BDOS/BIOS/loader config-specific; the 60K BDOS not mergeable.*

A correction to the intuition that "the 56K splits modules into pieces relocated
differently": **it does not.** The 56K is a clean **uniform +$3000** of all three
modules. The module that *splits* is the **60K**: its BIOS stays at $FA00 while
CCP/BDOS move +$4000, and its BDOS is cut across two language-card banks.

## Address model

SoftCard Z-80 → Apple map: **`Apple = (Z80 + $1000) mod $10000`** (so Z-80 $FA00
= Apple $0A00 low RAM).

| Build | CCP (Z80→Apple) | BDOS (Z80→Apple) | BIOS (Z80→Apple) | Offset vs 2.20-44K |
|---|---|---|---|---|
| **2.20-44K** (Ver. 2.20, serial `00 16 DF`) | $9400→$A400 | $9C00→$AC00 | $AA00→$BA00 | base — main RAM |
| **2.20B-56K** (Ver. 2.20B, serial `00 60 D9`) | $C400→**$D400** | $CC00→**$DC00** | $DA00→**$EA00** | **uniform +$3000** — language card |
| **2.23-44K** (Ver. 2.23, serial `BD16 00 01 4D 40`) | $9300→$A300 | $9C00→$AC00 | $FA00→$0A00 | (different release) |
| **2.23-60K** (Ver. 2.23, **same serial**) | $D300→$E300 | $DC00→$EC00 | $FA00→**$0A00** | CCP +$4000, BDOS +$4000, **BIOS +$0** (split) |

## Release identity (the version axis)

- **2.20-44K vs 2.20B-56K are different sub-releases** ("Ver. 2.20" vs "Ver.
  2.20B", distinct serials). A unified 2.20 44K↔56K source is therefore a
  **2-axis fold** (version 2.20/2.20B × memory 44K/56K), analogous to BASIC's
  GBASIC×V223 — not a pure memory re-ORG.
- **2.23-44K vs 2.23-60K are the same release** (identical serial). The 44K↔60K
  fold is a **pure memory axis** — but "same serial" ≠ "pure relocation" (the
  60K BDOS/BIOS carry genuine banking code).

## Verified per-module facts (2.20 44K → 56K)

All obtained by booting the real `DISK_2_20B_56K_SYSTEM` in `softcard_emu`
(videx=False → z80-idle), dumping the **de-skewed runtime** via `bus.readz80()`,
and diffing against the fully-relocatable 2.20-44K sources assembled at +$3000.

| Module | 56K = 44K +$3000? | Evidence | Verdict |
|---|---|---|---|
| **CCP** ($C400, 2048 B) | **Yes, pure** | 12 diffs total = relocation-gap (hard-coded DEFB self-pointers) + serial + live-RAM (DEFS-zero cells the running OS populated). **Zero static code deltas.** | clean conditional |
| **BDOS** ($CC00, 3584 B) | **Yes, pure** | 93 diffs = reloc-gap + serial + live-RAM + **exactly 1 behaviorally-inert dead-load operand** (already documented OBSERVED). One contiguous block; **0 language-card soft-switch ($C08x) accesses; no console-routing rewrite.** Banking is entirely the loader's/BIOS's job. | clean conditional |
| **BIOS** ($DA00, 1536 B) | **Mostly** | In-image addresses are uniform +$3000, with **54 genuine static deltas in 8 clusters** (static-vs-static; the boot-time decode of the on-disk image, NOT a post-boot live dump — pages $DE/$DF are runtime-clobbered buffers, which earlier inflated the count to "~86" and produced a phantom "$DEA5 device-output rework"). The real island: (1) CONIN routed through a pre-scan wrapper (vector $DA09 → $DB12, whose `CALL` → $DB50 the body); (2) a NEW warm-boot stub at $DFE8 = `CALL` old-init then `XOR A; LD (CCP_INLEN),A` — clears the CCP staged-command flag (`CCP_INLEN` = `CCP_ENTRY+7`, now a single-source cross-module symbol in `cpm_system_220.inc`) so a BIOS warm boot discards a stale staged command; (3) the sign-on banner `"44K Ver. 2.20"`→`"56K Ver. 2.20B"`. | conditional **with one island** |

**Critical consequence:** the 2.20→2.20B functional delta lives **almost
entirely in the BIOS.** CCP/BDOS are functionally identical across 2.20 and
2.20B (only the per-disk serial + that one inert byte differ). So:

- **CCP/BDOS = memory axis only** (no real version axis).
- **BIOS = the only module where the 2-axis fold actually bites** (a `V220B`
  island + the `CFG_56K` ORG arithmetic).

## The 2.20-family fold plan (do this)

Build-cell matrix (✓ = real reference disk pins it; ⊙ = derived, byte-pinned
transitively):

| | 44K | 56K |
|---|---|---|
| **2.20** | ✓ reference | ⊙ (optional) |
| **2.20B** | ⊙ **new build (the goal)** | ✓ reference |

The two reference disks sit on the diagonal and jointly pin both the version
delta and the relocation, so the off-diagonal **2.20B-44K** is validated
transitively: re-ORGing it +$3000 must reproduce the 2.20B-56K reference
byte-for-byte (the same "derived but byte-pinned" model the 60K disk uses).

**Step 0 — prerequisite: fully decode the 2.20B BIOS to its de-skewed runtime.
[DONE 2026-06-29, gate 227.]** The 2.20B-56K BIOS is the .po's 6 contiguous
sectors **33–38**; its page→sector map is wired into `cpm_pipeline/deskew.py`
(`BIOS_PAGE_TO_SECTOR_220B_56K`, `build_bios_image_220b_56k`,
`reference_bios_image_220b_56k`) with a roundtrip/+$3000 gate
(`test_cpm220b_56k_bios_deskew_roundtrip_and_is_44k_plus_3000`). Decode the
**static on-disk** image (the live post-boot dump's pages $DE/$DF are clobbered
buffers). The V220B island is the three deltas in the BIOS table row above; the
warm-boot stub's `CCP_INLEN` target is now a single-source symbol in
`cpm_system_220.inc`. (CCP/BDOS need **no** re-decode — the relocated 44K source
already reproduces them.)

**Step 1 — Axis A: build 2.20B-44K** ("an ifdef or two").
- CCP/BDOS: **no functional version delta** → 2.20B-44K CCP/BDOS = 2.20-44K bytes
  modulo the serial (a parametrized DEFB, not an island).
- BIOS: one `IFDEF V220B` island = the console-input + device-output +
  warm-boot/sign-on block, plus the sign-on string.
- Validate (2.20, 44K) against its reference disk. (2.20B, 44K) is derived.

**Step 2 — Axis B: build 2.20B-56K** via `CFG_56K` → ORG +$3000 (already a
recognized `-D` define in `assemble.py`). Drive the +$3000 through the
cross-module boundary EQUs (`cpm_system_220.inc`-style), not blanket arithmetic.
Validate byte-identical against the real 2.20B-56K disk → closes the loop and
retroactively pins 2.20B-44K.

**Known prerequisite work surfaced by the eval:** the 2.20-44K CCP/BDOS source
still hard-codes **~40 self/BIOS pointers as DEFB/DEFW literals** rather than
labels, so they don't auto-relocate at a new ORG. Labelizing them is required for
a byte-clean +$3000 — and it is already-wanted relocatability work, not throwaway.

## The 2.23 60K disposition (separable, later) — keep module-split

| Module | 44K → 60K | Plan |
|---|---|---|
| **CCP** | +$4000, 99.78% clean; **1** functional byte (top-of-memory page `$A1→$F0`). Re-ORG test reproduces the 60K carve within 5 reloc bytes. | **fold cleanly** (ORG EQU + 1 memsize `IFDEF`) |
| **BIOS** | stays $FA00 (the "split"); lower half $FA00–$FDFF 94–97% shared; upper $FE00–$FFFF only 4% common (LC warm-boot-rebuild/banking). | **conditional with a large `IFDEF V60` island** for $FE00–$FFFF — borderline, optional |
| **BDOS** | 13 LC bank-switch writes (vs 0 in 44K), per-call bank-in/out envelope, dispatch table split across two banks ($DDxx/$DExx upper + $BExx=Apple $DExx lower) + 3 BIOS delegations; lower bank still an undisassembled DEFB blob (~2700/3584 B). | **separate build** — a single ORG can't express two non-contiguous banks; a fold would be two sources sharing only the dispatch skeleton |

The 60K already uses the `CPM60_LINK` master-link conditional pattern
(`CPM60.asm` INCLUDEs the modules, each guarding its own ORG/DEVICE/SAVEBIN). The
recommendation keeps that, folds CCP, and leaves BDOS separate.

## Validation gates

- 2.20 fold: `(2.20,44K)` and `(2.20B,56K)` cells each reassemble byte-identical
  to their reference disks (`DISK_2_20_44K_SYSTEM`, `DISK_2_20B_56K_SYSTEM`).
  `(2.20B,44K)` proven transitively (its +$3000 re-ORG == the 56K reference).
- Each module: an `ASSERT *_IMAGE_END == boundary` ties the size to the real
  image extent under each config ORG (per `feedback_code_size_symbols_from_labels`).
- The whole-repo gate stays green: `source shared/toolchain/env.sh && python -m
  pytest softcard/ shared/`.

## Why conditional compile is the right call here

The 2.20-44K sources are already fully relocatable (every in-image operand a
label, modulo the ~40 DEFB-literal pointers to fix), so re-ORGing is mechanically
free; the assembler regenerates every absolute operand. The only non-mechanical
content is small, bounded, and exactly the kind of `IFDEF` island the repo
already uses (BASIC 4-way, SUBMIT 1 B, DDT 12 B). Separate builds would duplicate
~5.5 KB of CCP/BDOS that is provably identical-modulo-relocation — the precise
near-duplicate-source situation Brent's version-fold directive exists to prevent.
