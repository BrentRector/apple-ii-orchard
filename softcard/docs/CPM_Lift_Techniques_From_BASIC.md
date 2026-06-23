<!-- Status note prepended 2026-06-22 -->
> **STATUS:** All 27 techniques below were audited against the CP/M-OS enrichment workflow.
> The 8 gaps (A-H) have been FOLDED INTO the workflow STYLE + the adversarial-verify heuristics,
> and the applier (`enrich_apply.py`) supports the mechanics (splits/absorbs, top-level operand
> rewrites, includes/equ_to_include, labels). This file is the checklist of record for the
> "lift the CP/M sources the same way BASIC was lifted" requirement.

# BASIC.asm RE "lift" techniques -- enumeration + CP/M-enrichment-STYLE audit

Scope: every reverse-engineering "lift" technique and convention codified in the completed
GBASIC/MBASIC fold work (`softcard/cpm_pipeline/basic/*.py`, the master
`CPMV220-44K/utilities/BASIC.asm`, and the memory feedback files), audited against the current
CP/M-OS enrichment workflow STYLE template
(`.../workflows/scripts/cpm-os-enrich-wf_df70c318-227.js`).

"Covered by CP/M STYLE?" = is the technique present in the STYLE prose the agents are given.
"Applies to CP/M OS?" = is it relevant to BDOS/CCP/BIOS (Z-80 CP/M kernels, FCB file I/O, BDOS
function dispatch, console/disk via BIOS, error returns, message strings, embedded 6502).

---

## Technique table

| # | Technique | What it does (1 line) | BASIC example | Covered by CP/M STYLE? | Applies to CP/M OS? (+why) |
|---|-----------|-----------------------|---------------|------------------------|-----------------------------|
| 1 | **C-level framed routine header** | Per routine: `NAME -- purpose` + `In:/Out:/Clobbers:/Algorithm:` framed block, not opcode glosses | `FNDFOR`/`STMT_FOR` headers (BASIC.asm ~L983-1022) | **Yes** (HEADER TEMPLATE; applier frames) | Yes -- every BDOS fn, CCP built-in, BIOS jump-table entry needs one |
| 2 | **High-level body comments anchored to a code line** | Full-line `; intent` above a step, anchored by exact code text + 1-based occ index | `; Evaluate the initial-value expression into the FAC` above `CALL FRMEVL_NOPAREN` | **Yes** (BODY COMMENTS; anchor+occ) | Yes |
| 3 | **OBSERVED vs [RE] vs UNKNOWN discipline** | Separate fact-from-bytes, inference, and admitted-unknown; never invent | 563 `[RE]`, explicit `UNKNOWN:` notes (e.g. STMT_FOR frame layout) | **Yes** (GOAL line: "never invent (say UNKNOWN)") | Yes |
| 4 | **Semantic renames of machine labels** | `L_/SUB_xxxx` -> semantic name; `_N` locals drag with the head | `L_503C` -> `FRMEVL`; `SUB_6937_4` -> `NEWNAME_4` | **Yes** (RENAMES) | Yes -- OS already at 0 machine labels but mis-names still need fixing |
| 5 | **FUNCNAME_N localized branch locals** | In-routine labels = `<head>_<n>`, never `L_xxxx` | `FNDFOR_1..5`, `FRMEVL_OPLOOP_1..8` | **Partial** (renames allowed; STYLE never states the `_N`-from-head naming RULE) | Yes -- keeps OS routines readable |
| 6 | **Relocatability: in-image operand -> LABEL** | Frozen in-image hex (`LD HL,$xxxx`/`CALL`/`JP`/`DEFW`) becomes a label so it relocates | every body ref a label; `0` body-relative literals | **Yes** (RELOCATABILITY section, the discriminator) | Yes -- the OS modules must end fully label-based |
| 7 | **"Image refs are relocatable labels even when addresses coincide"** | Discriminator = "points INTO this module's image?" not "same in both builds" | `LD HL,$0108` -> `STMT_DISPATCH_TBL` | **Yes** (keep_literal list + "Discriminator (BASIC's rule)") | Yes -- but the OS has no twin build, so the rule must be stated as "image vs RAM/HW/const," which STYLE does |
| 8 | **Cover-idiom SPLIT (no label arithmetic)** | A merged skip/cover byte split into unlabeled `DEFB` cover + clean-labeled real instr; refs use the clean label, never `+1` | `RAISE_X: LD E,ERR_X` / `DEFB $01` stub runs | **Yes** (COVER IDIOM; SPLIT spec; "NEVER +offset") | Yes -- CP/M kernels use the same `$01`/`$11`/`$3E` skip covers |
| 9 | **In-image pointer table -> DEFW of clean labels** | A `DEFB $lo,$hi,...` table of in-image words rendered as `DEFW LABEL,...`; off-image words stay literal | `STMT_DISPATCH_TBL`/`FUNC_DISPATCH_TBL` DEFW of `STMT_*` | **Yes** (IN-IMAGE POINTER TABLES) | Yes -- CCP built-in dispatch, BIOS 17-entry jump table, BDOS fn vectors |
| 10 | **Error-code/message MODEL: table + ERR_* EQU include + RAISE_ stubs** | Message table -> base label + per-msg `ERR_<name>=code` comment; generate `*_errors.inc`; raise sites name the EQU | `errmsg.py`/`errstub.py`; `ERROR_MESSAGE_TABLE`, `ERR_*`, `RAISE_<name>` | **No** (STYLE never tells agents to model BDOS/CCP error returns this way or generate an include) | **Yes** -- BDOS returns error codes (A=$FF/$01/...) and CCP/BDOS print fixed messages ("Bdos Err On ", "Bad Sector$", "READ ERROR") -- a named-constant + message-table model fits |
| 11 | **Inline-argument bytes after CALL/RST** | A `CALL`/`RST` whose callee consumes the following byte(s) as data; render as `DEFB <arg>` with a "consumed by the preceding CALL" note, NOT an opcode | `CALL SYNCHR` / `DEFB TOK_EQ` | **No** (STYLE has no inline-arg idiom; only the cover/skip idiom) | **Maybe/Yes** -- CP/M BDOS/BIOS rarely uses inline args, but print-message routines and any "call then skip a parameter byte" pattern need it; cheap insurance against the SYNCHR-class cascade |
| 12 | **Data-as-code recovery (DEFB blob that is really code)** | Linearly recover fall-through code missed by the walker, gated by clean-decode-to-terminal + in-range targets; its frozen operands then relocate | `recover.py`; CRUNCH matcher `$307C`, FP `$5143` recovered | **No** (STYLE assumes the file already has 0 machine labels + relocates; says nothing about a DEFB run that is actually code) | **Yes** -- "a DEFB blob that decodes to code is NOT benign"; an OS module can still carry a missed-code run whose operands won't relocate |
| 13 | **Code-as-data (don't over-classify dead/data); strings as string literals** | Default-assume bytes are real; ASCII runs -> `DEFB "text"` not hex; out-of-image operands = relocation not death | error-message table as `DEFB "...",$00`; AUDIT pins real data | **Partial** (STYLE relocatability implies "in-image operand is real," but never states "don't stamp dead / strings-as-literals") | **Yes** -- the OS already does strings-as-literals (READ ERROR etc.), but the *rule* isn't in STYLE, so a fresh module risks regressions |
| 14 | **Embedded other-CPU (6502) code -> disassemble + extract + INCBIN** | A 6502 block inside a Z-80 module is CODE: disassemble with disasm6502, extract to its own `.s`, INCBIN back + verbatim listing | (BASIC has no 6502 block; the rule is repo-wide) | **No** (STYLE never mentions the embedded-6502/INCBIN pattern) | **Yes, strongly** -- CCP INCBINs `CPM_RPC6502.bin`; BIOS/BootLoader have 6502 RPC/console/disk blocks. An enrichment agent must not re-stamp these DEFB or mis-handle the INCBIN listing |
| 15 | **Cover/SMC/dual-CPU comment clarity (temporal-tenant)** | For reused/self-modified/dual-CPU RAM, state which code is there WHEN, run by WHICH CPU, as WHICH instruction set; no impossible simultaneity; dual-behavior comment on every cover | `; LD A,# cover -- the fall-through loads A=$C1`; SMC `self-modified at runtime` notes | **Partial** (STYLE asks for "a dual-behavior body comment on the DEFB cover" but not the SMC/temporal-tenant/dual-CPU clarity rule) | **Yes** -- the SoftCard boot/BIOS heavily reuses low RAM across 6502/Z-80 and self-modifies; this is exactly where sloppy wording becomes a contradiction |
| 16 | **Self-modifying-code (SMC) modelling** | A `CALL/JP $0000` (or `LD (instr+1),HL`) target patched at runtime -> split into opcode cover + clean-labeled `DEFW`/operand so the patch site `(entry)` relocates; comment the writer | `STROUT_CALL_VECTOR` ($0E34, one writer); `find_ld_cover_overlaps` self-mod branch | **Partial** (the cover-split covers some of it; STYLE doesn't name the self-modified-call-vector pattern) | **Yes** -- CP/M BIOS/boot self-modify (the cold-start-patched poll site, vectored RPC store) |
| 17 | **Computed-dispatch dual analysis (static dataflow + emulation)** | Resolve `LD HL,tbl; JP (HL)` and indexed jumps via BOTH static register dataflow AND emulation trace, then label the table -> `DEFW label` | dispatch resolution feeding `STMT_DISPATCH_TBL` | **Partial** (STYLE says label in-image pointer tables, but the *runtime-pointer* BDOS dispatch -- `LD HL,($9F43)` -- and indexed jumps need the dual-analysis note) | **Yes** -- BDOS dispatch is a runtime pointer, not a static table; CCP command dispatch is indexed |
| 18 | **Shared system includes (single source of truth)** | Fold a local re-`EQU` into the include's symbol (rename refs + delete local def); pull in includes actually referenced; match by VALUE not name | `cpm22.inc`/`apple_softcard.inc`/`msbasic_*`; `equ_to_include` | **Yes** (USE SHARED INCLUDES; `equ_to_include`; "match by VALUE/semantics, not name") | Yes -- cpm22.inc / apple_softcard.inc / msbasic_fcb.inc |
| 19 | **STRUCT for record layouts (FCB, line node, descriptors)** | Model a record as a `STRUCT` and replace base+offset with `STRUCT.field`; documentation-only structs allowed | `CPMFCB`, `BASLINE`, `STRDESC`, `SIMPLEVAR`/`ARRAYVAR` | **Partial** (STYLE references `msbasic_fcb.inc` CPMFCB but never tells the agent to MODEL fields as `FCB.<field>` offsets or build new structs) | **Yes** -- FCB is THE central BDOS record (open/close/read/write/search); DPB, directory entry, and the IOB are records too |
| 20 | **Idiom polish: char + named constants** | Character compares -> char literals (`CP '"'`); magic numbers -> names (`CALL BDOS`, `LD C,F_*`, `$0080`->TBUFF) | `CP '"'`, `DEFB 'N','D'+$80,TOK_AND` | **Yes** (IDIOM POLISH) | Yes |
| 21 | **High-bit char/token rendering** | High-bit-set bytes rendered as `'c'+$80` (or the EQU name) not hex, for keyword tails / Apple text | reswords `_char_expr` (`'D'+$80`); `DEFB TOK_AND` | **Partial** (STYLE's char-literal polish covers low ASCII; high-bit `'c'+$80` and high-bit Apple text via ca65 .charmap not stated) | **Maybe** -- CCP command-name table is 4-char ASCII (low); high-bit appears in 6502/banner text (BootLoader), so relevant there |
| 22 | **100-col comment wrapping + column alignment** | Wrap long comments at 100 cols with aligned continuation; realign the `; $addr` byte-comment column | `_wrap` (enrich_apply), `_realign` (apply_naming) | **Yes (mechanical)** -- the applier does it; agents need not know | Yes (handled by applier) |
| 23 | **Drop orphan labels / postpass cleanup** | Remove bare machine-label defs nobody references (stranded when a ref is kept literal) | `postpass.drop_orphan_labels` | **No** (STYLE/applier has no orphan-drop; not obviously needed since OS is at 0 machine labels) | **Maybe** -- only if a rename/keep-literal strands a label; low priority |
| 24 | **Adversarial verify pass** | A skeptical peer re-derives every header/rename/rewrite vs the actual bytes + ABI; drops opcode-gloss comments; downgrades overconfident claims | the map->enrich->verify workflow; caught real BASIC mis-decodes | **Yes** (the workflow's Verify phase) | Yes |
| 25 | **Byte-identical gate as floor, not goal** | Reassemble-identical proves bytes, NOT correct decode; keep going to total semantic understanding | every module ends "byte-identical (the gate proves it)" | **Yes** ("GOAL: total semantic understanding"; "Raise ... WITHOUT changing any byte") | Yes |
| 26 | **Mis-decode heuristic: CALL/JP into mid-instruction = bug** | A control-flow target landing mid-instruction means data-as-code or an unmodeled inline-arg/skip; root-cause it | drove the SYNCHR + cover audits | **Partial** (STYLE describes the cover SPLIT remedy but never states the *diagnostic*: mid-instruction target == decode bug to chase) | **Yes** -- the cheapest audit signal for an OS module |
| 27 | **Off-by-one / table-index semantic check** | Verify a dispatch handler's name against its index math (table indexed by token-$81), catching whole-cluster mislabels | FUNC_DISPATCH off-by-one ($6FF3 ATN really FRE) | **No** (STYLE never tells the verifier to cross-check handler identity against the dispatch index) | **Yes** -- CCP built-in table and any BDOS sub-dispatch indexed by function number can be off-by-one |

---

## GAPS: concrete additions for the CP/M STYLE

The STYLE already nails: C-level headers, body comments, OBSERVED/[RE]/UNKNOWN, relocatability +
the image-vs-literal discriminator, the cover-idiom SPLIT, in-image pointer tables, shared
includes / `equ_to_include`, and idiom polish (char + CP/M constants). Below is the exact prose to
ADD for each missing/partial technique that applies to the CP/M OS. Each is byte-safe (comments,
labels, length-preserving rewrites, INCBIN of identical bytes).

### A. Error-code + message-table model (technique 10) -- MISSING

Add a section after "IDIOM POLISH":

> ERROR / MESSAGE MODEL (same as BASIC's `errmsg`/`errstub`): BDOS functions return status
> codes (A = $00 ok / $FF or $01 error, directory codes 0-3, etc.) and the CCP/BDOS print fixed
> text ("Bdos Err On ", "Bad Sector$", "Select$", "File R/O$", "READ ERROR", "NO FILE",
> "NO SPACE", "BAD LOAD"). (1) Name every status/return CONSTANT (a `LD A,$FF` error return ->
> a named EQU, e.g. `BDOS_RC_ERROR`; directory codes -> `DIR_CODE_*`) and reference the name, not
> the literal. (2) Treat each message as a labeled `DEFB "text",$..` with a comment stating which
> condition prints it and how it is reached (pointer load vs computed/position-relative locator --
> see technique below). (3) If a run of raise/return stubs shares the `$01`/`$11` skip-cover idiom,
> decompose it exactly like BASIC's `RAISE_<name>` stubs. Put reusable codes in a small include
> only if they recur across modules; otherwise EQU them locally.

### B. Inline-argument bytes after CALL/RST (technique 11) -- MISSING

Add to the relocatability / idiom area:

> INLINE-ARGUMENT CALLS: if a routine reads the byte(s) IMMEDIATELY AFTER a `CALL`/`RST` to it as
> data and returns past them (BASIC's `CALL SYNCHR` / `DEFB TOK_EQ`), those following bytes are
> DATA, not the next instruction. Symptom: the disassembler shows a `CALL`/`RST` whose fall-through
> "instruction" is nonsense or whose next real instruction got swallowed. Render the consumed
> byte(s) as `DEFB <value>  ; inline arg consumed by the preceding CALL <name>` and resume real
> code after them. (A `CALL`/`JP`/`RST` target that lands in the MIDDLE of an instruction is the
> tell -- see the mis-decode heuristic below.)

### C. Data-as-code recovery + don't-over-classify (techniques 12, 13) -- MISSING / PARTIAL

> CODE-vs-DATA (default-assume real; recover missed code): a `.COM`/system image's bytes are
> deliberate -- DEFAULT-ASSUME a region is real code or real data, never "dead / stale TPA / leftover
> sector bytes" without strong proof (no path reaches it AND it doesn't decode as coherent code AND
> it isn't strings/a table). A DEFB blob that decodes as a clean instruction stream reaching a
> terminal, with in-image JP/CALL targets, is MISSED CODE, not benign data: its address operands are
> frozen hex that will NOT relocate, so flag it (a `split`/`label`+`operand_rewrite`, or note it for a
> recover pass) -- do not leave it DEFB. Conversely, out-of-image operands are evidence of RELOCATION
> (decode at the run address), NOT of dead code. ASCII runs are STRING LITERALS (`DEFB "text"`),
> never hex DEFB; high-bit Apple text routes through a ca65 `.charmap`/INCBIN block.

### D. Embedded other-CPU (6502) code -> INCBIN (technique 14) -- MISSING, HIGH PRIORITY

> EMBEDDED 6502 CODE (this is a SoftCard dual-CPU module): a block of 6502 machine code inside a
> Z-80 source (the CCP's RPC block, BIOS/boot console + disk + probe overlays) is CODE, not "byte
> data." It must be disassembled with the 6502 disassembler, extracted to its OWN `.s`/`.asm`
> source, and INCBIN'd back so the host reassembles byte-identical -- the established CPM_RPC6502
> pattern (`CPM_CCP.asm` INCBINs `CPM_RPC6502.bin`; the boot loaders INCBIN `ProbeOvl`/`ConInit`).
> Every INCBIN site carries a verbatim listing of the included source. DO NOT re-stamp such a block
> as DEFB and DO NOT alter the INCBIN/listing structure. If you find an embedded 6502 block still
> sitting as DEFB, FLAG it (note in the summary) rather than enriching around it.

### E. SMC / dual-CPU / temporal-tenant comment clarity (techniques 15, 16) -- PARTIAL

Extend the existing "dual-behavior body comment" instruction:

> REUSED / SELF-MODIFIED / DUAL-CPU CLARITY: when RAM is rewritten and reused, or self-modified, or
> handed between the 6502 and the Z-80, the comment must state WHICH code/data is there, WHEN, run by
> WHICH CPU, as WHICH instruction set -- as an explicit ordered (tenant 1, then 2, ...) sequence.
> Never imply two tenants occupy the address simultaneously, and NEVER imply the same bytes execute
> as both 6502 and Z-80 code. For self-modifying code, name the writer and the patched cell: a
> `CALL/JP $0000` whose target word is patched at runtime, or an `LD (instr+1),HL` operand patch,
> gets the cover-split treatment so the patch site's `(cell)` operand relocates, plus a comment
> naming the one writer and what it stores (BASIC: `STROUT_CALL_VECTOR`, one writer, init-once). A
> CALL "patched once to a constant" is NOT runtime dispatch -- say so.

### F. Computed/runtime dispatch -- dual analysis (technique 17) -- PARTIAL

> COMPUTED + RUNTIME DISPATCH: the in-image-pointer-table rule covers STATIC tables. BDOS dispatch is
> a RUNTIME pointer (`LD HL,(cell); JP (HL)`), and indexed jumps (`LD HL,base; ADD; JP (HL)`) resolve
> at run time -- resolve their targets by tracing the register dataflow (and/or an emulation trace),
> then label the table base + entries so it renders as `DEFW label`. State in the header that the
> dispatch is runtime-pointer vs static-indexed, and where the pointer/index comes from (the CP/M
> function number in C, the parsed CCP command index, ...). A `JP (HL)`/`JP (IX)` whose table you
> could not resolve is UNKNOWN -- say so, don't invent entry names.

### G. Mis-decode + off-by-one diagnostics for the verifier (techniques 26, 27) -- PARTIAL / MISSING

Add to the adversarial-verify job prose:

> AUDIT HEURISTICS (apply these as a skeptic): (1) A valid `CALL`/`JP`/`RST` never targets the
> MIDDLE of an instruction -- a mid-instruction control-flow target means data-was-decoded-as-code,
> an unmodeled inline-argument, or an unsplit skip/cover idiom. Root-cause it; never paper over with a
> `+offset`. (2) Cross-check every dispatch HANDLER's name against the table's INDEX math: if the
> table is indexed by (function number - base) or (command index), an off-by-one shifts the WHOLE
> cluster of handler names by one -- verify a couple of handler bodies against their computed index
> (BASIC's FUNC_DISPATCH was off by one: "FN_ATN" was really FRE). (3) A label or comment that makes
> no functional sense (a "continuation" pointing at a lone `RST`/`RET`, a one-time "dynamic" call) is
> a red flag of a mis-decode to chase, not to narrate.

### H. FUNCNAME_N locals + STRUCT modelling (techniques 5, 19) -- PARTIAL

Add a one-liner to RENAMES and a STRUCT note to the includes section:

> Local (in-routine) labels are named `<HEAD>_<n>` from the enclosing semantic head
> (`SEARCH_DIR_3`), never left as `L_/SUB_xxxx`.
>
> RECORD STRUCTS: model record layouts as a `STRUCT` and reference `STRUCT.field` instead of a raw
> base+offset where a routine clearly walks a record. The FCB is the central one (use
> `msbasic_fcb.inc`'s `CPMFCB`: `FCB.DRIVE/FNAME/FTYPE/EX/CR/RANDREC/...`); the DPB, directory entry,
> and the SoftCard IOB (`CPM_SoftCard_RWTS_IOB.md`) are records too. Documentation-only structs (no
> operand rewrite) are fine when access is sequential.

---

## One-paragraph summary -- the biggest gaps

The CP/M-OS STYLE is already strong on the *presentation* lifts (C-level headers, body comments,
OBSERVED/[RE]/UNKNOWN, renames, shared includes) and on the single hardest *relocatability* lift it
chose to emphasize -- the in-image-operand-to-label rule, the cover-idiom SPLIT, and in-image DEFW
pointer tables, with BASIC's exact discriminator. The biggest missing pieces are the ones unique to a
**dual-CPU CP/M kernel rather than a self-contained BASIC interpreter**: (1) the **embedded-6502 ->
disassemble + extract + INCBIN** rule (the CCP/BIOS/boot literally carry 6502 blocks; an agent told
only "in-image operand -> label" could re-stamp them DEFB or mangle the INCBIN listing) -- this is the
highest-risk gap; (2) the **error-code + message-table model** (named BDOS return/status constants +
labeled message strings + how each message is reached), which BASIC codified in `errmsg`/`errstub` and
the OS does ad hoc; (3) **data-as-code recovery / don't-over-classify-as-dead** plus **strings-as-
literals** as an explicit rule, since a missed-code DEFB run still freezes operands the OS needs to
relocate; and (4) the verifier **diagnostics** -- "mid-instruction control-flow target = decode bug"
and "cross-check handler names against the dispatch index for a whole-cluster off-by-one," both of
which caught real BASIC mis-decodes the byte-identical gate was blind to. Secondary, lower-risk gaps:
the inline-argument-after-CALL idiom, the SMC/temporal-tenant/dual-CPU comment-clarity rule, runtime
(vs static) dispatch dual-analysis, FUNCNAME_N locals, and STRUCT modelling of FCB/DPB/IOB records.
