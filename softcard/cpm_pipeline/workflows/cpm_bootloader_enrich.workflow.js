export const meta = {
  name: 'cpm-bootloader-enrich',
  description: 'C-level enrichment + full relocatability of the 2.20-44K 6502 boot loader (ca65), adversarially verified; per-cluster specs written to E:/tmp',
  phases: [{ title: 'Map' }, { title: 'Enrich' }, { title: 'Verify' }],
}

const TARGET = 'E:/Orchard/softcard/CPMV220-44K/os/CPM_BootLoader.s'
const IMAGE = '$0800-$13FF'   // the on-disk boot image's stored/run range (3072 bytes; read from .org + the .cfg size)
const INC = 'E:/Orchard/softcard/include'
const DOCS = 'E:/Orchard/softcard/docs'
const SYMS = 'E:/Orchard/shared/symbols/apple2.json'
const SPEC_DIR = 'E:/tmp'   // verify writes bl_spec_<i>.json here

const MODULE = `the Microsoft SoftCard CP/M 2.20 (44K) 6502 BOOT LOADER (ca65 source, on-disk image ${IMAGE},
read from track 0 by the Apple Disk II $Cn00 boot PROM). It is a 6502 program: BOOT0 loads the rest of the
image, then stage-2 ($1000+) runs the RWTS read/seek/nibble primitives, copies image regions down into low
RAM, scans the slots / card types, installs the SoftCard handshake, and builds the Z-80 BIOS handoff so the
Z-80 takes over CP/M. It INCBINs two embedded Z-80 blocks already extracted to their own sources
(CPM_BootLoader_ProbeOvl.bin at the $1169 slot-probe overlay, CPM_BootLoader_ConInit.bin at the $134A serial
console) -- those are DONE; never re-stamp them as data, never touch the .incbin/listing. Reassembles
BYTE-IDENTICAL (the boot-loader reconstruct gate proves it).`

const STYLE = `
THE FILE: ${TARGET} -- ${MODULE}
It already has semantic labels (mostly), [AI]/[DOC] one-liner comments, a strong top LAYOUT MAP, inline
"; $addr bytes" listing comments, and reassembles BYTE-IDENTICAL. Raise it to the BASIC.asm quality bar
WITHOUT changing any assembled byte (the gate is the proof). This is 6502 / ca65 syntax (labels "NAME:",
".byte"/".word", ".org", relative branches), NOT Z-80.

CONTEXT (read what you need with Read/Grep):
- ${SYMS} -- the canonical Apple II monitor-ROM / soft-switch / zero-page symbol table (SETTXT $FB2F,
  SETKBD $FE89, COUT $FDED, PRERR $FF2D, MONZ $FF65, Disk II $C08x soft switches, etc.). Name monitor/HW
  refs from this, not raw hex, where a name exists.
- ${INC}/apple_softcard.inc -- Apple/SoftCard hardware externals: I/O Config Block, Card Type Table, I/O
  Vector Table, A_VEC/Z_CPU RPC cells, slot config cells, zero-page cells.
- ${DOCS}/CPM_Manual_Reconcile_Facts.md + the transcribed SoftCard manuals -- CITE [DOC <manual> <page>]
  for the I/O Config Block / Card Type Table / slot-config cells ($03xx, $02F8,Y per-slot types) / RPC
  cells / disk-param semantics; NEVER [AI]-guess those.
- ${DOCS}/CPM_SoftCard_RWTS_IOB.md -- the RWTS I/O block caller cells (track/sector/drive/slot/buffer/
  command); the disk primitives use these.
- The Disk II RWTS shape (BOOT0 sector load, seek/arm-step with phase on/off, 6-and-2 nibble translate
  tables, read/write nibble loops) and the SoftCard cold-boot sequence (slot scan, card-type match,
  build the Z-80 handoff JMP) -- work out each routine from its bytes.

GOAL: total semantic understanding at C abstraction. Per routine: a framed C-level HEADER + a few
high-level BODY comments. Separate OBSERVED vs [RE] inference vs UNKNOWN; never invent (say UNKNOWN).
Byte-identical is the FLOOR, not the goal.

HEADER TEMPLATE (supply text lines only; the applier frames them with ";----" rules):
   <NAME> -- <one-line purpose>
     In:        <inputs: registers / ZP or workspace cells / IOB cells and what they hold>
     Out:       <outputs: registers / memory / carry+flags>
     Clobbers:  <registers / cells modified>
     Algorithm: <2-5 lines, C-level: WHAT it does and HOW, not opcode-by-opcode>

BODY COMMENTS: full-line high-level intent ABOVE a step ("seek the arm to the target track", "translate
the 6-and-2 nibble", "build the JMP $AA00 Z-80 entry"), NOT "increment Y". Anchor each to the EXACT code
text of the line it sits above (the instruction WITHOUT its "; $addr" comment) + a 1-based occurrence index
within the routine.

RENAMES: any remaining machine/opaque label (L_xxxx / LXXXX / a bare hex-derived name) or mis-named label
-> a semantic name; use the FINAL names in all your header/body/operand text.

RELOCATABILITY (REQUIRED -- the image must end up fully label-based):
- The boot IMAGE is ${IMAGE} (its stored == run base; confirm from the .org + the layout map). Every
  ABSOLUTE operand that points INTO ${IMAGE} written as a FROZEN HEX literal (JMP $1xxx / JSR $0xxx /
  LDA $1168,Y / .word $xxxx) MUST become a LABEL.
- If a label already exists at that address -> operand_rewrite {anchor, occ, old:"$xxxx", new:"LABEL"}.
- If NO label exists there -> a label {anchor:"<the exact in-image code/data line whose ; $addr is $xxxx>",
  occ, name:"LABEL"} PLUS the operand_rewrite that uses it. (Use the inline "; $addr" comments to locate
  the target line.)
- keep_literal for: numeric CONSTANTS; ZERO PAGE / stack / RWTS-IOB workspace cells; hardware/I-O
  ($C0xx Disk II + soft switches, $Cn00 slot ROM); the Apple MONITOR ROM ($Fxxx -- name via apple2.json);
  the COPY-DESTINATION low-RAM addresses the loader writes into ($0200/$0300/$0FFF/$1000 handoff, etc.,
  which are NOT inside the stored image); and any OFF-image address. Discriminator: does the operand point
  INTO ${IMAGE} (this stored image)? If yes -> CLEAN relocatable LABEL. The copy SOURCES (e.g. LDA $1168,Y)
  are in-image -> label; the copy DESTINATIONS (STA $0FFF,Y) are low RAM -> literal. Distinguish them.
- 6502 COVER IDIOM -- NO ADDRESS/LABEL ARITHMETIC ANYWHERE. When a branch/jump enters the MIDDLE of an
  instruction (the classic 6502 skip: "BIT abs" $2C / "BIT zp" $24 / "LDA #" $A9 / "CMP #" $C9 / "LDX #"
  $A2 used as a 1-2 byte cover so the fall-through path skips the next opcode), SPLIT it: render the cover
  opcode as an UNLABELED ".byte $2C" (or $24/$A9/...) and the real instruction with its OWN clean LABEL:
      .byte $24            ; cover (BIT-zp opcode): fall-through eats the next byte, skipping the SEC
  ENTRY_SEC:
      SEC                  ; the real mid-byte entry (reached by BNE ENTRY_SEC)
  Every reference then uses ENTRY_SEC -- a CLEAN label, NEVER ENTRY-1 / COVER+1 / any +offset. (This is
  exactly the CPM_RPC6502.s DRIVE_MOTOR_ON_SEC fix.) Provide a SPLIT {anchor:"<merged instr line text>",
  occ, into:["        .byte $24    ; ...", "ENTRY_SEC:", "        SEC          ; ..."]} (identical bytes;
  the gate proves it) plus any operand_rewrite that now targets ENTRY_SEC.
- IN-IMAGE POINTER/JUMP TABLES -> .word of clean LABELS (interleave/skew tables that are pure data stay
  .byte; but a table of in-image ADDRESS words rendered as raw .byte becomes ".word LABEL1, LABEL2, ...").
  Off-image words stay literal. operand_rewrite: old = the whole ".byte $lo,$hi,..." run, new = ".word
  LABEL1, LABEL2" (identical byte count).
- NEVER force a relocatization onto a cell whose decode you cannot verify -- leave it literal with an
  UNKNOWN note. A self-modified instruction's operand is patched at runtime: name the WRITER + patched
  cell; do not pretend a runtime-patched operand is a static label.

IDIOM POLISH (as operand_rewrites; the byte gate proves equivalence): character comparisons -> char
literals (CMP #'A' not CMP #$41); obvious monitor/HW addresses -> their apple2.json names.

USE SHARED NAMES, never independently redefine: if this file LOCALLY EQUs a monitor/HW symbol that
apple2.json or apple_softcard.inc already names, prefer the shared name (rename refs; FLAG the local EQU in
your summary -- a shared 6502 include is a separate follow-up, so just FLAG, do not delete the EQU yet).

EMBEDDED Z-80 CODE: the two INCBIN'd blocks (ProbeOvl $1169, ConInit $134A) are already extracted + done.
NEVER re-stamp them as .byte, NEVER alter the .incbin or its verbatim listing comment. If you find ANOTHER
embedded foreign-CPU block STILL sitting as raw .byte, FLAG it -- do not emit rewrites that touch it.

CODE vs DATA (default-assume real; recover missed code; strings as literals): the image's bytes are
DELIBERATE. A ".byte" blob that decodes as a clean instruction stream with in-image JMP/JSR targets is
MISSED CODE, not data (its frozen address operands will NOT relocate -- FLAG it). The 6-and-2 nibble
translate tables, the sector interleave/skew table, the phase on/off countdown tables, and the sign-on
BANNER are genuine DATA -- keep them as tables/strings (ASCII runs -> .byte "text" where the assembler
allows, else keep the byte form but comment it as the banner). $FF / $00 fill regions are real padding.

REUSED / SELF-MODIFIED / DUAL-CPU CLARITY: when a cell is rewritten + reused, self-modified, or handed
between the 6502 and the Z-80, the comment must state WHICH code/data is there, WHEN, run by WHICH CPU --
an explicit ordered tenant sequence. Never imply two tenants occupy a cell simultaneously, and NEVER imply
the same bytes execute as both 6502 AND Z-80. The boot loader STAGES Z-80 bytes (it writes the Z-80 reset
handoff at $1000 = JMP into the BIOS); say so plainly.
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

// The full spec shape the verify agent must WRITE to its bl_spec_<i>.json file.
const SPEC_SHAPE = `{
  "routines": [ { "label": "NAME",
    "header": ["NAME -- purpose", "  In: ...", "  Out: ...", "  Clobbers: ...", "  Algorithm: ..."],
    "body_comments": [ { "anchor": "<exact code line text, no ; comment>", "occ": 1, "comment": "..." } ],
    "renames": [ { "old": "OLD", "new": "NEW", "why": "..." } ],
    "operand_rewrites": [ { "anchor": "<exact code line>", "occ": 1, "old": "$1168", "new": "LABEL", "why": "..." } ] } ],
  "labels": [ { "anchor": "<exact in-image target line>", "occ": 1, "name": "LABEL", "why": "..." } ],
  "splits": [ { "anchor": "<merged instr line>", "occ": 1, "into": ["        .byte $24    ; cover", "ENTRY:", "        SEC"], "why": "..." } ],
  "includes": [],
  "equ_to_include": [],
  "summary": "..."
}`

// Full spec schema for the enrich stage (harness-validated draft handed to verify).
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
        into: { type: 'array', items: { type: 'string' } }, why: { type: 'string' } },
      required: ['anchor', 'into'] } },
    includes: { type: 'array', items: { type: 'string' } },
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
    path: { type: 'string', description: 'the bl_spec_<i>.json file written' },
    n_routines: { type: 'number' }, n_labels: { type: 'number' },
    n_operand_rewrites: { type: 'number' }, n_splits: { type: 'number' },
    flags: { type: 'array', items: { type: 'string' }, description: 'mis-decodes found, embedded-code/missed-code blobs, unverifiable cells left literal, local EQUs to share' },
    summary: { type: 'string' },
  }, required: ['cluster', 'path', 'summary'],
}

phase('Map')
const mapping = await agent(
  `${STYLE}\n\nYOUR JOB (map): read ${TARGET} IN FULL (including the top LAYOUT MAP) and enumerate EVERY
routine + named data region, then group them ALL into clusters of ~8-15 labels each (file order) for
parallel enrichment. Use as many clusters as needed (6-10 for this file) so NO label is left unassigned --
completeness matters more than tidy count. EXCLUDE only labels that ALREADY have a FULL framed C-level
header (a ";----" frame with In:/Out:/Clobbers:/Algorithm:). A "routine" = a JMP/JSR/branch target or a
fall-through entry with its own body; also include the named DATA regions (nibble tables, skew table,
phase tables, banner, fill) as their own cluster(s) so they get documented. List label names exactly.`,
  { label: 'map', phase: 'Map', schema: MAP_SCHEMA })

const clusters = (mapping && mapping.clusters || []).filter(c => c && c.labels && c.labels.length)
log(`${clusters.length} clusters: ${clusters.map(c => c.name).join(', ')}`)

phase('Enrich')
const summaries = await pipeline(
  clusters,
  (c, _c, idx) => agent(
    `${STYLE}\n\nYOUR JOB (enrich): deeply reverse-engineer cluster "${c.name}" of ${TARGET}.
Labels (file order): ${c.labels.join(', ')}. ${c.note ? 'Map note: ' + c.note : ''}
For EACH routine produce the C-level HEADER + a few high-level BODY comments + semantic RENAMEs, AND the
RELOCATABILITY operand_rewrites/labels/splits (frozen IN-IMAGE hex -> clean label; distinguish copy SOURCES
in-image from copy DESTINATIONS in low RAM) AND idiom operand_rewrites. For DATA clusters, document the
table/string with header + body comments (and .word-of-labels rewrites only for genuine in-image address
tables). Trace dataflow precisely; mark UNKNOWN rather than guess. One routine entry per label.`,
    { label: `enrich:${c.name}`, phase: 'Enrich', schema: SCHEMA }),
  (enr, c, idx) => agent(
    `${STYLE}\n\nYOUR JOB (adversarial verify + WRITE): a peer enriched cluster "${c.name}" of ${TARGET}.
Their draft spec JSON is below. VERIFY every header/body/rename/operand_rewrite/label/split against the
ACTUAL bytes + the Disk II RWTS shape + the SoftCard cold-boot facts + apple2.json. Check In/Out/Algorithm
vs what the code does; check EACH relocatability rewrite points at the correct IN-IMAGE label and that
non-image operands (copy destinations, $C0xx HW, $Fxxx monitor, ZP) were left literal; fix mis-decodes;
DROP wrong/opcode-gloss body comments; downgrade overconfident claims to [RE]/UNKNOWN.
AUDIT HEURISTICS (skeptic): (1) a valid branch/JMP/JSR NEVER targets the MIDDLE of an instruction -- a
mid-instruction target means data-as-code, an unmodeled inline-arg, or an UNSPLIT 6502 cover idiom;
root-cause it, never paper over with +offset. (2) A copy loop's SOURCE is in-image (label) but its
DESTINATION is low RAM (literal) -- do not relocatize a destination. (3) A label/comment that makes no
functional sense is a red flag of a mis-decode to chase. (4) FLAG any embedded foreign-CPU block left as
raw .byte, and any .byte blob that decodes as coherent in-image code. (5) Do NOT force a relocatization
onto a self-modified or unverifiable cell -- leave literal + UNKNOWN.
THEN: WRITE the corrected spec as STRICT JSON (no markdown fences, no prose -- ONLY the JSON object,
matching ${'`'}${SPEC_SHAPE}${'`'}) to EXACTLY the file ${SPEC_DIR}/bl_spec_${idx}.json using the Write
tool. Return the VERIFY_SUMMARY (path=${SPEC_DIR}/bl_spec_${idx}.json, the counts, and all flags).
DRAFT SPEC:\n${JSON.stringify(enr || {})}`,
    { label: `verify:${c.name}`, phase: 'Verify', schema: VERIFY_SUMMARY }))

return { target: TARGET, clusters: clusters.length, spec_dir: SPEC_DIR,
         summaries: summaries.filter(Boolean) }
