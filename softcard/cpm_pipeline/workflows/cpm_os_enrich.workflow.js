export const meta = {
  name: 'cpm-os-enrich',
  description: 'C-level enrichment + full relocatability of one CP/M OS source file (Z-80), adversarially verified',
  phases: [{ title: 'Map' }, { title: 'Enrich' }, { title: 'Verify' }],
}

const TARGET = 'E:/Orchard/softcard/CPMV223-44K/os/CPM_BIOS.asm'
const IMAGE = '$FA00-$FDFF'   // the on-disk BIOS chunk (1024 bytes); in-image refs here become labels
const MODULE = `the Microsoft SoftCard CP/M 2.23 (44K) BIOS -- the 17-entry CP/M BIOS jump table +
implementations (BOOT/WBOOT/CONST/CONIN/CONOUT/LIST/PUNCH/READER/HOME/SELDSK/SETTRK/SETSEC/SETDMA/READ/
WRITE/LISTST/SECTRAN), the slot/card/device scan, and cold/warm boot. This is the AS-SHIPPED on-disk
BIOS chunk, Z-80 run address ${IMAGE}.
  ** CLEAN-SLATE (mandatory): enrich from THIS 2.23 file's OWN bytes. The enriched 2.20-44K BIOS
     (softcard/CPMV220-44K/os/CPM_BIOS.asm) may be consulted ONLY as a structural cross-reference LEAD
     during verify -- NEVER copy its comments/decode onto 2.23. 2.23 DIFFERS from 2.20 (a Videx 80-col
     console path AND a 40-col real-ROM fallback; a POST-1980 device-6 / Pascal-1.1 / $Cn0B slot probe;
     different rebase) -- where they diverge, the 2.20 text is WRONG for 2.23. Decode 2.23 on its bytes.
  ** ADDRESS FRAMING (do NOT get this wrong): the SoftCard maps Z-80 $F000-$FFFF -> Apple $0000-$0FFF
     (LOW main RAM). So this BIOS at Z-80 $FA00 lives in Apple $0A00 -- LOW MAIN RAM, NOT the language
     card. 2.23-44K is a 44K (main-RAM-only) system and uses NO language card. Z-80 $E000-$EFFF = Apple
     I/O ($Cxxx soft switches seen as $E0xx); Z-80 $B000-$DFFF = Apple $D000-$FFFF (the LC region -- the
     56K/60K builds, NOT this one). Never describe a high Z-80 address as "LC / high RAM".
  ** Console: 2.23 supports a Videx Videoterm 80-col card AND falls back to the Apple 40-col text screen
     when no 80-col card is present (40-col is uppercase-only). Document BOTH paths from the bytes.
  ** The $FE00+ resident tail is built in RAM at cold boot (NOT in this on-disk image) -- references to
     $FExx are OUT of this $FA00-$FDFF image, so keep them literal. Reassembles byte-identical.`
const INC = 'E:/Orchard/softcard/include'
const DOCS = 'E:/Orchard/softcard/docs'
const SPEC_DIR = 'E:/tmp'   // verify writes os_spec_<i>.json here (no giant round-trip)

const STYLE = `
THE FILE: ${TARGET} -- ${MODULE}. It already has 0 machine labels, [AI]/[DOC] one-liner comments,
inline "; $addr bytes" listing comments, and reassembles BYTE-IDENTICAL (the reconstruct gate proves
it). Raise it to the BASIC.asm quality bar WITHOUT changing any assembled byte.

CONTEXT (read what you need with Read/Grep):
- ${INC}/cpm22.inc -- CP/M 2.2 ABI: BDOS=$0005, F_* / DRV_* function numbers, FCB_* offsets, TPA/TBUFF/TFCB.
- ${INC}/apple_softcard.inc -- Apple/SoftCard hardware externals: I/O Config Block, Card Type Table,
  I/O Vector Table, A_VEC $F3D0 / Z_CPU $F3DE RPC cells, soft switches ($E0xx = Apple $C0xx), zero-page
  cells ($F0xx), Apple-ROM RPC targets.
- ${INC}/msbasic_fcb.inc -- the canonical CP/M FCB STRUCT CPMFCB.
- ${DOCS}/CPM_SoftCard_RWTS_IOB.md -- the SoftCard RWTS I/O block (IOB) caller cells (track/sector/
  drive/slot/DMA buffer/status/command); disk I/O uses this.
- ${DOCS}/CPM_Manual_Reconcile_Facts.md -- cite [DOC <manual> <page>] for config-block / Card-Type /
  RPC / BDOS-ABI semantics; never [AI]-guess those.
- This is a Z-80 CP/M OS module for the SoftCard; work out which from its bytes. CCP = command processor
  (read the console line; parse + dispatch the built-ins DIR/ERA/REN/SAVE/TYPE/USER; else load + run a
  .COM through the BDOS). BDOS = the CP/M 2.2 kernel: ~40 functions reached via the $0005 entry (F_* in
  cpm22.inc) -- console/list I/O, the FCB-based file system (open/close/read/write/search/make/delete/
  rename, sequential + random), and disk allocation / directory / DPB management; it calls the BIOS for
  physical I/O. BIOS = the 17-entry jump table (BOOT/WBOOT/CONST/CONIN/CONOUT/LIST/PUNCH/READER/HOME/
  SELDSK/SETTRK/SETSEC/SETDMA/READ/WRITE/LISTST/SECTRAN); console via the 6502 RPC to the Apple ROM,
  disk via the IOB + the 6502 RWTS, plus slot/device scanning + cold/warm boot.

GOAL: total semantic understanding at C abstraction. Per routine: a framed C-level HEADER and a few
high-level BODY comments. Separate OBSERVED vs [RE] inference vs UNKNOWN; never invent (say UNKNOWN).

HEADER TEMPLATE (supply text lines only; the applier frames them):
   <NAME> -- <one-line purpose>
     In:        <inputs: registers / IOB or workspace cells and what they hold>
     Out:       <outputs: registers / memory / flags>
     Clobbers:  <registers / cells modified>
     Algorithm: <2-5 lines, C-level: WHAT it does and HOW, not opcode-by-opcode>

BODY COMMENTS: full-line high-level intent ABOVE a step ("issue the BDOS console-out call", "poll the
6502 until the sector lands"), NOT "increment HL". Anchor each to the EXACT code text of the line it
sits above (instruction without its comment) + a 1-based occurrence index within the routine.

RENAMES: any remaining machine label (L_/SUB_) or mis-named label -> a semantic name; FINAL names in your text.

RELOCATABILITY (REQUIRED -- this module must end up fully label-based):
- Find every absolute operand that points INTO this module's own image (its OWN run-address range -- read
  it from this file's ORG/DISP directive + SAVEBIN size; e.g. the BIOS image is $AA00-$AEFF, a BDOS runs
  ~$9A00, a CCP ~$9300/$9400) written as a FROZEN HEX literal (LD HL,$xxxx / CALL $xxxx / JP $xxxx /
  DEFW $xxxx). Each must become a LABEL.
- If a label already exists at that address -> operand_rewrite {anchor, occ, old:"$xxxx", new:"LABEL"}.
- If NO label exists there -> a label {anchor:"<the exact code/data line whose address comment is $xxxx>",
  occ, name:"LABEL"} PLUS the operand_rewrite that uses it. (Use the inline "; $addr ..." comments to
  locate the target line.)
- COVER IDIOM -- the SAME approach BASIC.asm used. NO ADDRESS/LABEL ARITHMETIC ANYWHERE. When the
  disassembler MERGED a fall-through skip/cover byte with the following real instruction into ONE
  instruction (bytes like $01 $2E $58 decoded as "LD BC,$582E", where $01 is really a SKIP cover --
  $01 'LD BC,nn' / $11 'LD DE,nn' / $F6 'OR n' / $FE 'CP n' / $3E 'LD A,n' / $21 'LD HL,nn' -- and the
  trailing bytes $2E $58 = "LD L,$58" are the REAL entry), and that entry is reached by a computed
  JP/CALL or pointed at by a table word, SPLIT it: render the cover byte as an UNLABELED "DEFB $01" and
  the real instruction with its OWN clean LABEL:
      DEFB $01            ; cover: on fall-through $01 (LD BC) eats the next instruction
  ENTRY_LABEL:
      LD L,$58            ; the real mid-byte entry
  Every reference then uses ENTRY_LABEL -- a CLEAN label, NEVER ENTRY-1 / COVER+1 / any +offset. The
  classic error-raise form is identical: "RAISE_X: LD E,ERR_X" then a bare unlabeled "DEFB $01", repeat.
  Provide a SPLIT {anchor:"<merged instr line text>", occ, into:["        DEFB $01    ; ...",
  "ENTRY_LABEL:", "        LD L,$58    ; ..."]} (identical bytes; the gate proves it) plus any
  operand_rewrite that now points at ENTRY_LABEL, and a dual-behavior body comment on the DEFB cover.
- IN-IMAGE POINTER TABLES -> DEFW of clean LABELS (same as BASIC): a table of in-image pointer words
  rendered as raw DEFB becomes DEFW of LABELS; where a word points mid-instruction, FIRST split that
  cover (above) to mint a clean entry label, THEN reference it -- never +offset. Off-image words stay
  literal. operand_rewrite: old = the whole "DEFB $lo,$hi,..." operand, new = "DEFW LABEL1, LABEL2,
  $offimg" (identical byte count). NEVER leave an in-image pointer frozen as DEFB.
- keep_literal ONLY for: numeric CONSTANTS, RAM/stack workspace, hardware/I-O ($E0xx/$F0xx/$C0xx/$F3xx),
  cross-module fixed entries already EQU'd (BDOS_ENTRY/CCP_ENTRY), and OFF-image addresses. Discriminator
  (BASIC's rule): does the operand point INTO this module's own image? If yes it is a CLEAN relocatable
  LABEL (split the cover to mint one if it lands mid-instruction) -- never a frozen literal, never label
  arithmetic.

IDIOM POLISH (as operand_rewrites; the byte gate proves equivalence): character comparisons -> char
literals (CP '"' not CP $22; CP ' ' not CP $20); CP/M constants -> names (CALL BDOS not CALL $0005;
LD C,F_* / DRV_*; $0080 -> TBUFF; $005C -> TFCB).

USE SHARED INCLUDES, never independently redefine (single source of truth) -- PROACTIVE, REQUIRED:
- Go through this file's LOCAL EQU block and fold EVERY local symbol that is the SAME item (same
  value + same meaning) as one a system include already provides. cpm22.inc base page: WBOOTV $0000,
  IOBYTE_ADDR $0003, CDISK_ADDR $0004, BDOS $0005, TFCB $005C, TBUFF $0080, TPA $0100 (so a local
  WBOOT_VEC/CDISK/BDOS_VEC/DEFAULT_DMA -> WBOOTV/CDISK_ADDR/BDOS/TBUFF). apple_softcard.inc: the
  hardware/RPC cells, soft switches, slot/config cells. msbasic_fcb.inc: the FCB STRUCT fields.
  For EACH, emit equ_to_include {local_name, include_name, include_file}: the applier renames every ref
  local->include name AND DELETES the local def, so the include is the only definition. Do this even
  when the local name is "nicer" -- the SHARED name wins (the byte gate proves the value is identical).
- If you fold ANY symbol from an include this file does not yet INCLUDE, ALSO list that include in
  "includes" so the applier adds the INCLUDE line (else the folded refs won't resolve and the build
  breaks -- e.g. folding to IOBYTE_ADDR requires INCLUDE "cpm22.inc"). Only include what is referenced.
- Match by VALUE/semantics, not name: a local "BDOS_ENTRY EQU $9C06" / "BDOS_ENTRY_223 $9C06" is the
  config-specific BIOS->BDOS jump address, NOT cpm22.inc's standard BDOS=$0005 -- do NOT fold those.
  Config-specific cells ($9Cxx BDOS base, $FExx resident-tail entries, $9300 CCP base) stay LOCAL.

EMBEDDED 6502 CODE (this is a SoftCard DUAL-CPU module): a block of 6502 machine code inside this Z-80
source (the CCP's RPC block, BIOS/boot console + disk + probe overlays) is CODE, not byte data. The
established pattern: it is disassembled with the 6502 disassembler, extracted to its OWN .s, and INCBIN'd
back so the host reassembles byte-identical (CPM_CCP INCBINs CPM_RPC6502.bin; the boot loaders INCBIN
ProbeOvl/ConInit), each INCBIN site carrying a verbatim listing. NEVER re-stamp such a block as DEFB and
NEVER alter the INCBIN/listing. If you find an embedded 6502 block STILL sitting as raw DEFB, FLAG it in
your summary -- do NOT emit rewrites that touch it.

ERROR / MESSAGE MODEL (same as BASIC's errmsg/errstub): BDOS functions return status codes (A=$00 ok /
$FF or $01 error; directory codes 0-3) and the CCP/BDOS print fixed text ("Bdos Err On ", "Bad Sector$",
"Select$", "File R/O$", "READ ERROR", "NO FILE", "NO SPACE", "BAD LOAD"). (1) NAME every status/return
CONSTANT (a "LD A,$FF" error return -> a named EQU e.g. BDOS_RC_ERROR; directory codes -> DIR_CODE_*) and
reference the name, not the literal. (2) Treat each message as a labeled DEFB string with a comment
stating WHICH condition prints it and HOW it is reached. (3) A run of raise/return stubs sharing the
$01/$11 skip-cover -> decompose exactly like BASIC's RAISE_<name> stubs (split form, no arithmetic).

CODE vs DATA (default-assume real; recover missed code; strings as literals): the system image's bytes
are DELIBERATE -- default-assume a region is real code or real data; never "dead / stale TPA / leftover
sector bytes" without strong proof (no path reaches it AND it does not decode as coherent code AND it is
not strings/a table). A DEFB blob that decodes as a clean instruction stream reaching a terminal, with
in-image JP/CALL targets, is MISSED CODE not data: its address operands are frozen hex that will NOT
relocate -- FLAG it (a split/label+operand_rewrite, or a note) rather than leaving it DEFB. Out-of-image
operands are evidence of RELOCATION (decode at the run address), NOT dead code. ASCII runs are STRING
LITERALS (DEFB "text"), never hex DEFB.

INLINE-ARGUMENT CALLS (SYNCHR-class): if a routine reads the byte(s) IMMEDIATELY AFTER a CALL/RST to it
as data and returns PAST them (BASIC's "CALL SYNCHR" then "DEFB TOK_EQ"), those following bytes are DATA,
not the next instruction. Render them "DEFB <value>   ; inline arg consumed by the preceding CALL <name>"
and resume real code after. The tell is a CALL/JP/RST target that lands MID-instruction -- root-cause it.

REUSED / SELF-MODIFIED / DUAL-CPU CLARITY: when RAM is rewritten + reused, self-modified, or handed
between the 6502 and the Z-80, the comment must state WHICH code/data is there, WHEN, run by WHICH CPU,
as WHICH instruction set -- an explicit ordered (tenant 1, then 2, ...) sequence. Never imply two tenants
occupy the address simultaneously, and NEVER imply the same bytes execute as both 6502 AND Z-80 code. For
self-modifying code, name the ONE writer and the patched cell (a CALL/JP whose target word is patched at
runtime, or an "LD (instr+1),HL" operand patch) and cover-split so the patch site's (cell) operand
relocates. A CALL "patched once to a constant" is NOT runtime dispatch -- say so.

COMPUTED + RUNTIME DISPATCH (dual analysis): the in-image pointer-table rule covers STATIC tables. BDOS
dispatch is a RUNTIME pointer ("LD HL,(cell); JP (HL)") and indexed jumps ("LD HL,base; ADD; JP (HL)")
resolve at run time -- resolve their targets by tracing register dataflow (and/or an emulation trace),
then label the table base + entries so it renders DEFW label. State in the header whether dispatch is
runtime-pointer or static-indexed and where the pointer/index comes from (the CP/M function number in C,
the parsed CCP command index, ...). A JP (HL)/JP (IX) whose table you cannot resolve is UNKNOWN -- say
so; do not invent entry names.

LOCALS + RECORD STRUCTS: in-routine labels are named <HEAD>_<n> from the enclosing semantic head
(SEARCH_DIR_3), NEVER L_/SUB_xxxx. Model record layouts as a STRUCT and reference STRUCT.field instead of
a raw base+offset where a routine clearly walks a record: the FCB is the central one (msbasic_fcb.inc's
CPMFCB -- FCB.CPM.DR/F/T/EX/CR/R0..); the DPB (disk parameter block), the directory entry, and the
SoftCard IOB (CPM_SoftCard_RWTS_IOB.md) are records too. Documentation-only structs (no operand rewrite)
are fine when access is sequential.
`

const MAP_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    clusters: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: { name: { type: 'string' }, labels: { type: 'array', items: { type: 'string' } }, note: { type: 'string' } },
      required: ['name', 'labels'] } },
    summary: { type: 'string' },
  }, required: ['clusters', 'summary'],
}

const SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    routines: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        label: { type: 'string' },
        header: { type: 'array', items: { type: 'string' } },
        body_comments: { type: 'array', items: {
          type: 'object', additionalProperties: false,
          properties: { anchor: { type: 'string' }, occ: { type: 'number' }, comment: { type: 'string' } },
          required: ['anchor', 'occ', 'comment'] } },
        renames: { type: 'array', items: {
          type: 'object', additionalProperties: false,
          properties: { old: { type: 'string' }, new: { type: 'string' }, why: { type: 'string' } },
          required: ['old', 'new'] } },
        operand_rewrites: { type: 'array', items: {
          type: 'object', additionalProperties: false,
          properties: { anchor: { type: 'string' }, occ: { type: 'number' }, old: { type: 'string' }, new: { type: 'string' }, why: { type: 'string' } },
          required: ['anchor', 'occ', 'old', 'new'] } },
      }, required: ['label', 'header'] } },
    labels: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: { anchor: { type: 'string' }, occ: { type: 'number' }, name: { type: 'string' }, why: { type: 'string' } },
      required: ['anchor', 'occ', 'name'] } },
    splits: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: { anchor: { type: 'string' }, occ: { type: 'number' },
        into: { type: 'array', items: { type: 'string' }, description: 'the replacement lines (DEFB cover byte + clean-labeled real instruction); identical bytes' },
        why: { type: 'string' } },
      required: ['anchor', 'into'] } },
    includes: { type: 'array', items: { type: 'string' }, description: 'system include files this file should INCLUDE but does not yet' },
    equ_to_include: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: { local_name: { type: 'string' }, include_name: { type: 'string' }, include_file: { type: 'string' }, why: { type: 'string' } },
      required: ['local_name', 'include_name'] } },
    summary: { type: 'string' },
  }, required: ['routines', 'summary'],
}

const VERIFY_SUMMARY = {
  type: 'object', additionalProperties: false,
  properties: {
    cluster: { type: 'string' },
    path: { type: 'string', description: 'the os_spec_<i>.json file written' },
    n_routines: { type: 'number' }, n_labels: { type: 'number' },
    n_operand_rewrites: { type: 'number' }, n_splits: { type: 'number' },
    flags: { type: 'array', items: { type: 'string' }, description: 'mis-decodes fixed, embedded-6502/missed-code blobs, unverifiable cells left literal, 2.20-vs-2.23 divergences, local EQUs to share' },
    summary: { type: 'string' },
  }, required: ['cluster', 'path', 'summary'],
}

phase('Map')
const mapping = await agent(
  `${STYLE}\n\nYOUR JOB (map): read ${TARGET} IN FULL and enumerate EVERY routine, then group them ALL
into clusters of ~8-15 routine labels each (file order), for parallel enrichment. Use as many clusters
as needed (4-9 for a large file) so that NO routine is left unassigned -- completeness matters more than
tidy cluster count. EXCLUDE only routines that ALREADY have a FULL framed C-level header (a "; ----"
frame with In:/Out:/Clobbers:/Algorithm: lines). A "routine" = a label that is a JP/CALL target or a
fall-through entry with its own body; do NOT list pure mid-routine continuation sub-labels separately.
List the actual label names exactly as they appear.`,
  { label: 'map', phase: 'Map', schema: MAP_SCHEMA })

const clusters = (mapping && mapping.clusters || []).filter(c => c && c.labels && c.labels.length)
log(`${clusters.length} clusters: ${clusters.map(c => c.name).join(', ')}`)

phase('Enrich')
const results = await pipeline(
  clusters,
  (c) => agent(
    `${STYLE}\n\nYOUR JOB (enrich): deeply reverse-engineer and enrich cluster "${c.name}" of ${TARGET}.
Routines (file order): ${c.labels.join(', ')}. ${c.note ? 'Map note: ' + c.note : ''}
For EACH routine produce the C-level HEADER + a few high-level BODY comments + semantic RENAMEs, AND
the RELOCATABILITY operand_rewrites/labels (frozen in-image hex -> label) AND idiom operand_rewrites
(char literals / CP/M constants). Trace dataflow precisely; mark UNKNOWN rather than guess. One entry per routine.`,
    { label: `enrich:${c.name}`, phase: 'Enrich', schema: SCHEMA }),
  (spec, c, idx) => agent(
    `${STYLE}\n\nYOUR JOB (adversarial verify + WRITE): a peer enriched cluster "${c.name}" of ${TARGET}.
VERIFY every header/body/rename/operand_rewrite/label against the ACTUAL bytes + the CP/M BIOS ABI +
the IOB/RPC/jump-table facts. Check In/Out/Algorithm vs what the code does; check EACH relocatability
rewrite points at the correct in-image label and that non-image operands were left literal; flag/fix
mis-decodes; DROP wrong or opcode-gloss body comments; downgrade overconfident claims to [RE]/UNKNOWN.
AUDIT HEURISTICS (apply as a skeptic): (1) a valid CALL/JP/RST NEVER targets the MIDDLE of an instruction
-- a mid-instruction control-flow target means data-decoded-as-code, an unmodeled inline-argument, or an
unsplit skip/cover idiom; root-cause it, never paper over with a +offset. (2) Cross-check every dispatch
HANDLER's name against the table's INDEX math: if the table is indexed by (function number - base) or a
command index, an off-by-one shifts the WHOLE cluster of handler names by one -- verify a couple of
handler bodies against their computed index (BASIC's FUNC_DISPATCH was off by one). (3) A label/comment
that makes no functional sense (a "continuation" pointing at a lone RST/RET; a one-time "dynamic" call)
is a red flag of a mis-decode to chase, not narrate. (4) FLAG any embedded-6502 block left as raw DEFB,
and any DEFB blob that decodes as coherent in-image code, instead of enriching around it. (5) Flag any
2.20-vs-2.23 divergence you notice (the 2.20 twin is a LEAD only -- 2.23 is decoded on its own bytes).
Default skeptical. THEN: WRITE the corrected spec as STRICT JSON (no markdown fences, no prose -- ONLY the
JSON object matching the enrich schema: {routines:[{label,header[],body_comments[{anchor,occ,comment}],
renames[{old,new}],operand_rewrites[{anchor,occ,old,new}]}], labels[{anchor,occ,name}], splits[{anchor,
occ,into[]}], includes[], equ_to_include[], summary}) to EXACTLY the file ${SPEC_DIR}/os_spec_${idx}.json
using the Write tool, then return the VERIFY_SUMMARY (path=${SPEC_DIR}/os_spec_${idx}.json, counts, flags).
\n\nSPEC TO VERIFY:\n${JSON.stringify(spec)}`,
    { label: `verify:${c.name}`, phase: 'Verify', schema: VERIFY_SUMMARY }))

return { target: TARGET, clusters: clusters.length, spec_dir: SPEC_DIR, summaries: results.filter(Boolean) }
