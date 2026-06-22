#!/usr/bin/env python
"""Clean-slate decode of GBASIC.COM from the 2.20-44K disk.

Derives the source PURELY from the 2.20 binary's bytes (no 2.23 .asm consulted).
GBASIC self-relocates: entry JP $1000; the $1000 stub LDDRs the interpreter body
from file $100E-$6490 UP to run $3000-$8482, then JP $81D3. So the body must be
decoded at its RUN address $3000 and folded back to the .COM file offset via
DISP/ENT.

Model: build ONE 64K image in the *runtime* layout -- header bytes at $0100-$100D,
body bytes at $3000.. -- and run ONE Z-80 walker over it so header<->body cross
references share a single label set. Then emit:

    ORG $0100
    <header $0100-$100D>          ; entry jump + low data/tables + the $1000 relocator
    DISP $3000
    <body $3000-$84F1>            ; the relocated interpreter, labels at run addr
    ENT
    SAVEBIN "out.bin", $0100, $6400
"""
from pathlib import Path

from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline import reference_data as rd
from cpm_pipeline.basic._paths import asm_path, overlay_path, seeds_path, load_token_names
from cpm_pipeline.basic import reswords, lowtables, errmsg, errstub
from cpm_pipeline.basic.recover import recover_code
from cpm_pipeline.basic.fixed_sites import (fixed_operand_sites, cover_idiom_sites,
                                            mid_string_constant_sites)

STRING_LO, STRING_HI = 0x0522, 0x081F          # error-message string region

from disasm_z80.walker import Walker
from disasm_z80.formatter import SjasmFormatter
from cpm_pipeline.region_disasm import (
    seed_leading_jp_vector, resolve_computed_dispatch, label_inrange_operands,
    scan_pointer_words,
)
from disasm_z80.symbols import SymbolTable

# ---- geometry ---------------------------------------------------------------
LOAD = 0x0100                 # CP/M TPA base -- the platform .COM load address (not image-relative)
# RUN / RELOC_SRC_START / BODY_ENTRY are NOT hardcoded: they are derived from the binary's own
# relocator in main() (its LDDR operands encode the body extents and the cold-start entry).
OVERLAY = overlay_path("GBASIC")


def synchr_addr(overlay_path):
    """Resolve the run address of the SYNCHR routine by its name in the naming
    overlay (label -> address map), so the inline-byte-call address is derived
    from the single source of truth, not hard-coded per file."""
    import json
    renames = json.loads(Path(overlay_path).read_text(encoding="utf-8")).get("renames", {})
    for addr_hex, name in renames.items():
        if name == "SYNCHR":
            return int(addr_hex, 16)
    raise ValueError(f"SYNCHR not found in {overlay_path}")


def main():
    com = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "GBASIC.COM"))
    assert len(com) == 25600, len(com)

    # ---- relocation geometry: DERIVED from the binary's own relocator, never hardcoded -------
    # The entry JP ($0100) targets the relocator, whose LDDR setup encodes the body's file/run
    # extents and the cold-start entry. The .asm writes the very same values as label-differences
    # (LD HL,INTERP_LOAD_START+(INTERP_COPY_END-INTERP_RUN_START)-1 / LD DE,INTERP_COPY_END-1 /
    # LD BC,INTERP_COPY_END-INTERP_RUN_START / JP COLD_START), so deriving them keeps every
    # image address a label, not a literal.
    reloc = com[1] | (com[2] << 8)              # entry JP ($0100) target = relocator address
    def _reloc_word(opcode, off):
        i = reloc - LOAD + off
        assert com[i] == opcode, f"relocator +{off}: {com[i]:#04x} != {opcode:#04x}"
        return com[i + 1] | (com[i + 2] << 8)
    src_end = _reloc_word(0x21, 0)              # LD HL,src_end  (LDDR source top, descending)
    dst_end = _reloc_word(0x11, 3)              # LD DE,dst_end  (LDDR destination top)
    count   = _reloc_word(0x01, 6)              # LD BC,count    (= INTERP_COPY_END-INTERP_RUN_START)
    BODY_ENTRY = _reloc_word(0xC3, 11)          # JP COLD_START  (the LDDR at +9 is 2 bytes)
    RELOC_SRC_START = src_end - count + 1       # first body byte in the file image (INTERP_LOAD_START)
    RUN = dst_end - count + 1                   # body run address (LDDR destination start, $3000)

    hdr_len = RELOC_SRC_START - LOAD            # $0F0E bytes ($0100-$100D)
    body = com[hdr_len:]                        # file $100E.. to EOF
    body_len = len(body)                        # $54F2

    from disasm_common.coverage import (
        maximize_coverage, z80_decoder, z80_dispatch_scanner, z80_ref_harvester,
    )

    # ---- HEADER: its own image+walker so body passes can't decode its data --
    # The header is the entry jump ($0100), the low data/keyword tables
    # ($0103-$0FFF) and the relocator stub ($1000-$100D).  Trace ONLY the entry;
    # control flow runs $0100 -> JP $1000 -> relocator -> JP $81D3 (out of range),
    # so the keyword/dispatch tables stay DATA.
    # BUT the low-RAM workspace $0C00-$0FFF holds engine code that runs IN PLACE
    # (the main loop NEWSTT $0E23, the error dispatchers $0D6F/$0D89, line-search
    # $0F88, edit helpers) -- it is NOT in the $3000 DISP body and is reached only
    # by CALL/JP from the body, so the entry-only trace leaves it as DEFB.  Harvest
    # those low-RAM code targets from the body's own CALL/JP operands and seed them.
    _CALLS = {0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
    _JPS = {0xC3, 0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
    lowram_seeds = set()
    for i in range(len(body) - 2):
        if body[i] in _CALLS or body[i] in _JPS:
            t = body[i + 1] | (body[i + 2] << 8)
            if 0x0C00 <= t < 0x1000:
                lowram_seeds.add(t)
    # Low-RAM continuation routines loaded as an address (LD BC,nnnn, opcode $01) by
    # other low-RAM code and entered via a computed jump (e.g. ERROR_REPORT_BODY at
    # $0DA7, set up by LD BC,$0DA7 then JP $68F4 which LD SP,HL + RETs to it). The
    # CALL/JP harvest can't see these, so they were left as DEFB; seed them as code.
    for a in range(0x0C00, RELOC_SRC_START - 2):
        i = a - LOAD
        if com[i] == 0x01:                      # LD BC,nnnn
            t = com[i + 1] | (com[i + 2] << 8)
            if 0x0C00 <= t < 0x1000:
                lowram_seeds.add(t)
    # The reverse: header low-RAM code ($0C00-$100D) that JP/CALLs INTO the relocated
    # body. Harvest those body targets so the body walker mints a label there -- the
    # header references them, and cross-region substitution needs a label to resolve to.
    hdr_body_seeds = set()
    for a in range(0x0C00, RELOC_SRC_START - 2):
        i = a - LOAD
        if com[i] in _CALLS or com[i] in _JPS:
            t = com[i + 1] | (com[i + 2] << 8)
            if RUN <= t < RUN + (len(com) - (RELOC_SRC_START - LOAD)):
                hdr_body_seeds.add(t)

    # SYNCHR reads the byte after each CALL as its expected character and returns
    # past it -- that byte is data, not the next instruction. Declaring it as an
    # inline-byte call makes the walker mark those bytes as data (emitted as char
    # constants) and re-sync the decode instead of cascading. Resolve its address
    # from the naming overlay (label -> address) so it is not hard-coded.
    INLINE_BYTE_CALLS = {synchr_addr(OVERLAY): 1}
    # Render the high-bit SYNCHR inline bytes (keyword tokens) as their EQU names.
    TOKENS = load_token_names()

    from disasm_z80.opcodes import decode_at

    hdr_mem = bytearray(0x10000)
    hdr_mem[LOAD:LOAD + hdr_len] = com[:hdr_len]
    hwalk = Walker(hdr_mem, start=LOAD, end=LOAD + hdr_len)
    hwalk.inline_byte_calls = dict(INLINE_BYTE_CALLS)
    for s in lowram_seeds:               # in-place low-RAM routines are call heads
        hwalk.call_targets.add(s)
    hwalk.trace(LOAD)
    for s in lowram_seeds:
        hwalk.trace(s)
    label_inrange_operands(hwalk, hdr_mem, LOAD, hdr_len)
    for s in lowram_seeds:
        hwalk.add_label(s)
    hwalk.add_label(reswords.INDEX_ADDR)   # split the data run at the reserved-word
                                           # table so it can be spliced out cleanly
    # NOTE: hwalk.name_labels()/emit are DEFERRED to after the body walker, so the
    # body's references INTO the low region can mint header labels (see harvest below).

    # The interpreter's dispatch tables (statement $0108 x85, function $01B2 x54,
    # operator cluster $04F9 x20) are DEFW pointer tables read by computed jumps; render
    # them as DEFW <label> so the (body-relocated) targets relocate, not frozen DEFB.
    DISPATCH_TABLES = {0x0108: 85, 0x01B2: 54, 0x04F9: 20}
    dispatch_ptrs = {base + 2 * i for base, n in DISPATCH_TABLES.items() for i in range(n)}
    # Harvest the handler addresses the dispatch tables point at, so the body walker
    # labels them (a table-only-reached handler is otherwise left as a DEFW literal).
    dispatch_targets = set()
    for base, n in DISPATCH_TABLES.items():
        for i in range(n):
            t = com[base - LOAD + 2 * i] | (com[base - LOAD + 2 * i + 1] << 8)
            if RUN <= t < RUN + (len(com) - (RELOC_SRC_START - LOAD)):
                dispatch_targets.add(t)

    # ---- BODY: its own image+walker at run $3000 ----------------------------
    # Statement/function handlers are reached only through the dispatch ADDRESS
    # tables in the header (DEFW pointers into the body), which a body-only trace
    # can't follow.  Harvest those handler entry points from the 2.20 binary's own
    # address tables ($0103-$0251 and $04D8-$0521, the runs that precede the
    # reserved-word names and the error strings) and seed them as code, alongside
    # the body origin ($3000, the CRUNCH tokenizer reached via a stored vector) and
    # cold start ($81D3).  All seeds are derived from the 2.20 image -- clean-slate.
    # Entry points reached only INDIRECTLY (through the statement/function dispatch
    # tables, or via a stored vector like CRUNCH at $3000) that recursive descent
    # cannot follow.  These are decoded from the 2.20 binary's own dispatch tables +
    # landmark analysis and recorded in the committed companion GBASIC.seeds.json;
    # every one is validated to decode as an instruction.  Clean-slate (binary-derived).
    import json as _json
    seed_file = seeds_path("GBASIC")
    dispatch_seeds = set(_json.loads(seed_file.read_text())) if seed_file.exists() else set()

    body_mem = bytearray(0x10000)
    body_mem[RUN:RUN + body_len] = body
    bwalk = Walker(body_mem, start=RUN, end=RUN + body_len)
    bwalk.inline_byte_calls = dict(INLINE_BYTE_CALLS)
    # FP power-of-ten fraction-digit constant table (FP_POW10_FRAC_TABLE, loaded by
    # LD DE at $5B14): MBF constant bytes, NOT code. Pin as data so the walker does not
    # decode it as bogus instructions / DEFW pointers (which minted a stray L_5C05 label).
    FP_POW10_TBL = (0x5BE8, 0x5C2E)
    bwalk.add_data_region(*FP_POW10_TBL)
    # Data regions the walker mis-decoded as code, identified by the mid-construct
    # reference audit (workflow gbasic-idiom-proof-audit): a 'reference' INTO each was a
    # disassembly artifact (string bytes / FP constant / color table read as an opcode).
    AUDIT_DATA = [
        (0x38B7, 0x38CA),   # "?Redo from start\r\n\0" (the INPUT 'Redo from start' prompt)
        (0x448B, 0x44B2),   # "Random number seed (-32768- to 32767)\0" (RANDOMIZE prompt)
        (0x4709, 0x4722),   # STMT_BEEP inline 6502 RPC block (AD 30 C0 = LDA $C030 speaker-click...
                            #   ...JSR $FF57...$60 RTS): opaque 6502 bytes from the Z80 view, byte-
                            #   identical in both .COMs; the disassembler mis-typed 3 words as DEFW
                            #   Z80 pointers (CRUNCH_9/GFX_PARSE_TWO_BYTES/PTRGET_SEARCH_18).
        (0x47DA, 0x47E6),   # graphics state/variable block (HPLOT coordinate save cells)
        (0x4A81, 0x4A91),   # Apple hi-res color/pixel-pattern WORD table
        (0x5E0B, 0x5E34),   # RND-seed init + FP scratch data; the fold audit showed both decoders
                            #   read its constant words as DEFW pointers (GBASIC: GFX_HIRES_BYTE_ADDR
                            #   from the bytes $DD $47; MBASIC: NEXT_LOOP_BODY_5) -- identical bytes in
                            #   both .COMs, so it is data, not a relocatable address (RNDX_SEED $5E24)
        (0x5EA2, 0x5EC7),   # FN_RND MBF floating-point constant pool
        (0x841D, 0x8482),   # SIGNON_BANNER: "BASIC-80 Rev. 5.2 [Apple CP/M Version] ..." string
    ]
    # NOTE: pinning the banner used to break the build -- with it as data the trailing region
    # is unreached, so $8483 (INTERP_COPY_END, the LDDR copy boundary) is only referenced by
    # the $1000 relocator (via a literal operand apply_naming rewrites to INTERP_COPY_END-1),
    # which drop_orphan_labels couldn't see, so it stranded the L_8483 def. Fixed by the
    # `keep=` protection on the drop_orphan_labels call below.
    for lo, hi in AUDIT_DATA:
        bwalk.add_data_region(lo, hi)
    # Register the body origin + every indirectly-reached entry point as a call TARGET
    # BEFORE any pass names labels: these are routine HEADS, so they must mint SUB_xxxx
    # head labels (not L_xxxx branch labels the localizer would fold into the preceding
    # routine -- e.g. STMT_END at $6956 was mislabelled SUB_6937_4, a local of RESTORE).
    entry_points = (({RUN, BODY_ENTRY} | dispatch_seeds | hdr_body_seeds | dispatch_targets)
                    & set(range(RUN, RUN + body_len)))
    for s in entry_points:
        bwalk.call_targets.add(s)
    bwalk.trace(RUN)            # body origin (CRUNCH, reached via a stored vector)
    bwalk.trace(BODY_ENTRY)     # cold-start initializer (JP $81D3 after LDDR)
    for s in dispatch_seeds:
        bwalk.trace(s)
    # INPUT 'Redo from start' helpers ($38CA INPUT_SKIP_QUOTED, $38D7 INPUT_REDO): real
    # code reached only by JP from the INPUT parser, sitting right after the now-pinned
    # 'Redo from start' string -- seed them so they decode as code, not stranded DEFB.
    for s in (0x38CA, 0x38D7):
        bwalk.trace(s)
    seed_leading_jp_vector(bwalk, body_mem, RUN, body_len)
    _, body_dispatch = resolve_computed_dispatch(bwalk, body_mem, RUN, body_len)
    label_inrange_operands(bwalk, body_mem, RUN, body_len)
    maximize_coverage(
        bwalk, body_mem, cpu="z80", decoder=z80_decoder(body_mem),
        scan_dispatch=z80_dispatch_scanner(body_mem, RUN, RUN + body_len),
        harvest_refs=z80_ref_harvester(body_mem, RUN, RUN + body_len),
    )
    # Recover code the walker missed (reached via computed jumps / pushed continuations,
    # or fragmented by false pointer-cell classification). Such blobs are NOT data -- the
    # address operands inside them are frozen DEFB bytes that would not relocate. Run
    # BEFORE pointer-table detection so the recovered code is not mis-read as pointers.
    recover_code(bwalk, body_mem, RUN, RUN + body_len, protected=[FP_POW10_TBL] + AUDIT_DATA)
    label_inrange_operands(bwalk, body_mem, RUN, body_len)   # label the recovered code's
                                                             # operands so they relocate
    body_ptrs = scan_pointer_words(bwalk, body_mem, RUN, body_len) | body_dispatch
    # Pinned data regions (AUDIT_DATA -- e.g. the sign-on banner's leading CR/LF bytes) must NOT
    # render as DEFW pointer-words: a coincidental data word like $0A0D ($0D $0A = CR LF) would
    # resolve to a dead-RAM label (L_0A0D) and over-relocate +$23 in the MBASIC fold. Keep them DEFB.
    body_ptrs = {p for p in body_ptrs if not any(lo <= p < hi for lo, hi in AUDIT_DATA)}
    # Ensure each entry point has a label (call_targets were registered up front so
    # name_labels mints SUB_xxxx heads for them).
    for s in entry_points:
        bwalk.add_label(s)
    # Label the LDDR copy boundary ($8483, top of the real interpreter; $8483-$84F1 is
    # dead .COM padding) so the $1000 relocator's bounds derive from it, not literals.
    bwalk.add_label(0x8483)
    bwalk.name_labels()

    # The body ($3000+) references INTO the low-region TABLES ($0103-$083F): the
    # statement/function dispatch tables, the reserved-word table, the operator tables
    # and the error-message strings. That image data is conceptually relocatable (it only
    # keeps the same address in both builds because the loader does not relocate it), so
    # each reference must be a LABEL, not a frozen literal. The header and body are decoded
    # by SEPARATE walkers, so harvest every body operand that targets the table region and
    # mint a HEADER label there; the body reference then resolves to that label. (The RAM
    # WORKSPACE above $0840 -- SAVTXT, KBUF, the FAC, the flag cells -- is named where it
    # is referenced, not blanket-labeled here.)
    import re as _reh
    # The whole shared header/low-RAM image -- the dispatch/reserved-word/operator tables and
    # error strings ($0103-$081E), the $D034 vector table, the RAM workspace (SAVTXT/FAC/flag
    # cells) and the in-place low-RAM engine code ($081F-$0FF7) -- is IMAGE data: a body operand
    # pointing into it must become a relocatable LABEL, not a frozen literal. The GBASIC/MBASIC
    # fold assembles this same source at two layouts (MBASIC's error table carries the extra
    # code-32 'Graphics statement not implemented' string, shifting everything past $0704 up by
    # $23), so a frozen literal here is wrong for MBASIC. We therefore mint header labels across
    # the whole header image -- from past the 3-byte entry JP up to RELOC_SRC_START, the body-image
    # boundary (INTERP_LOAD_START). The GBASIC-only relocator falls inside that span but is never
    # referenced by body code (GBASIC's copy of that low-RAM code lives below it), and a genuine
    # same-in-both constant is kept literal by the body formatter's keep_literal
    # (fixed_operand_sites), so neither is mislabeled.
    TABLE_LO, TABLE_HI = LOAD + 3, RELOC_SRC_START
    # Values the mid-construct audit proved are CONSTANTS or inert never-taken-branch
    # operands that only coincidentally land in the table region (a CRUNCH/cold-start
    # arithmetic constant, the operand of a dead JP-NZ/JP-C cover, a write-once scratch
    # cell). Do NOT mint a label for them; they must render as plain literals.
    AUDIT_BOGUS_VALUES = {0x0106, 0x0107, 0x013E, 0x0140, 0x0200, 0x0300, 0x0412}
    cover_lo = cover_idiom_sites(body_mem, bwalk.code, RUN, RUN + body_len, labels=bwalk.labels)
    for a in sorted(bwalk.code):
        if a in cover_lo:                       # a coded-constant cover -> not an address
            continue
        try:
            ins = decode_at(body_mem, a)
        except (IndexError, KeyError):
            continue
        for m in _reh.finditer(r"\$([0-9A-Fa-f]{4})", ins.mnemonic):
            v = int(m.group(1), 16)
            # mid-DEFW-pointer addresses are constants (labeling would split a
            # relocatable dispatch pointer), so don't mint a label for them; nor for the
            # audit's proven-bogus coincidental values.
            if (TABLE_LO <= v < TABLE_HI and not lowtables.is_mid_pointer(v)
                    and v not in AUDIT_BOGUS_VALUES):
                hwalk.add_label(v)

    # ---- finalize HEADER now that body->low references are known -------------
    hwalk.name_labels()
    hdr_fmt = SjasmFormatter(hdr_mem, hwalk, origin=LOAD, length=hdr_len,
                             source_name="GBASIC", relocatable=False,
                             inline_token_names=TOKENS, pointer_words=dispatch_ptrs,
                             keep_literal=(cover_idiom_sites(hdr_mem, hwalk.code, LOAD, LOAD + hdr_len, labels=hwalk.labels)
                                           | lowtables.literal_sites(hdr_mem, hwalk.code, LOAD, LOAD + hdr_len)))
    hdr_fmt._harvest_data_labels()
    hdr_fmt._prepare_overlap_labels()
    hdr_lines, _, _ = hdr_fmt._emit_body()
    # Decompose the reserved-word / token table ($021E-$04EC) into its structured form,
    # then rewrite references INTO it (machine labels minted at table-interior addresses)
    # to the structured label+offset.
    hdr_lines = reswords.splice_table_into(hdr_lines, com)
    hdr_lines = reswords.apply_reference_renames(hdr_lines, com)
    hdr_lines = lowtables.apply(hdr_lines)     # name dispatch/operator table bases+entries
    hdr_lines = errmsg.splice_table_into(hdr_lines, com)        # label every error message
    hdr_lines = errmsg.apply_reference_renames(hdr_lines, com)
    stub_old = errstub.stub_old_labels(hdr_lines, com)          # capture old stub labels first
    hdr_lines = errstub.splice_stubs_into(hdr_lines, com)       # coded-error stubs -> RAISE_* / LD E,ERR_*
    hdr_lines = errstub.apply_reference_renames(hdr_lines, com, stub_old)
    hdr_lines = errstub.apply_direct_raise_renames(hdr_lines, com)  # LD E,$nn;JP RAISE_ERROR -> LD E,ERR_*

    # Inject the header's low-region labels into the body walker's label set so the body
    # formatter renders body->low references as that label (relocatable), not a literal.
    # (Out of the body's $3000+ range, so no body label DEFINITION is emitted; the header
    # owns the definition.) The machine names rename consistently in both via apply_naming.
    for a, n in hwalk.labels.items():
        if n and a < RELOC_SRC_START and a not in bwalk.labels:
            bwalk.labels[a] = n

    # relocatable=False (the utility norm): label real control-flow/data targets but
    # leave in-range IMMEDIATE constants (e.g. LD BC,$3028 = graphics coords 48,40) as
    # literals instead of mislabelling them as the routine that happens to sit there.
    # Keep fixed operands (identical in both builds -> RAM/stack address or constant)
    # literal, so a coincidental body label isn't substituted and wrongly relocated.
    fixed, _ = fixed_operand_sites()
    keep_literal = (fixed | cover_idiom_sites(body_mem, bwalk.code, RUN, RUN + body_len, labels=bwalk.labels)
                    | lowtables.literal_sites(body_mem, bwalk.code, RUN, RUN + body_len)
                    | mid_string_constant_sites(body_mem, bwalk.code, STRING_LO, STRING_HI,
                                                 RUN, RUN + body_len, str_mem=hdr_mem))
    body_fmt = SjasmFormatter(body_mem, bwalk, origin=RUN, length=body_len,
                              source_name="GBASIC", pointer_words=body_ptrs,
                              relocatable=False, inline_token_names=TOKENS,
                              keep_literal=keep_literal,
                              # the sign-on banner's leading CR/LF bytes ($0D $0A = $0A0D)
                              # coincide with the L_0A0D cell label; pin it opaque so they stay
                              # DEFB and do not relocate as a DEFW pointer in the MBASIC fold.
                              data_spans=[(0x841D, 0x8482)])
    body_fmt._harvest_data_labels()
    body_fmt._prepare_overlap_labels()
    body_lines, _, _ = body_fmt._emit_body()
    # Body references INTO the reserved-word table (injected as machine labels L_xxxx
    # from the header) must use the structured label (RESWORD_INDEX / KWGRP_x+n /
    # RESWORD_OPS) the table actually defines -- the L_xxxx defs were dropped by the
    # splice, so an unrewritten reference would dangle to $0000.
    body_lines = reswords.apply_reference_renames(body_lines, com)
    body_lines = lowtables.apply(body_lines)   # dispatch/operator table refs -> base+offset
    body_lines = errmsg.apply_reference_renames(body_lines, com)   # error-message refs -> ERRMSG_*
    body_lines = errstub.apply_reference_renames(body_lines, com, stub_old)  # error-raise refs -> RAISE_*
    body_lines = errstub.apply_direct_raise_renames(body_lines, com)  # LD E,$nn;JP RAISE_ERROR -> LD E,ERR_*
    disk_run = errstub.disk_vector_run(body_lines)             # disk-error vectors (relocated body)
    body_lines = errstub.splice_disk_vectors_into(body_lines, com, disk_run)
    body_lines = errstub.apply_disk_vector_renames(body_lines, com, disk_run)  # vector-table refs -> DISK_RAISE_*
    body_lines = errstub.apply_cover_raise_stubs(body_lines, com)   # single-entry cover stub -> RAISE_*

    # Coded LD-r,$NN cover overlaps (same idiom as the error DEFB $01 covers): split into
    # `DEFB $<op>` + a clean-labeled entry so every reference to the operand-byte entry resolves
    # to a real relocatable label, not a `<cover>+1` literal. Run BEFORE the cross-region pass so
    # the body's literal `$<entry>` refs are rewritten to the entry label here.
    _referenced = errstub.code_operand_addrs(hdr_lines + body_lines)
    hdr_lines, _cover_rw = errstub.find_ld_cover_overlaps(hdr_lines, com, _referenced)
    if _cover_rw:
        def _apply_cover_rw(lns):
            res = []
            for ln in lns:
                c, s, r = ln.partition(';')
                for old, new in _cover_rw.items():
                    c = c.replace(old, new)
                res.append(c + s + r)
            return res
        hdr_lines = _apply_cover_rw(hdr_lines)
        body_lines = _apply_cover_rw(body_lines)

    # Cross-region relocatability: header ($0100-$100D) and body ($3000+) are decoded
    # by SEPARATE walkers, so each region's control-flow operands into the OTHER region
    # were emitted as literals. Substitute them with the other walker's label so every
    # JP/CALL/JR target relocates (the body relocates to $3000 in GBASIC and runs in
    # place in MBASIC; a labeled operand assembles correctly for both). The machine
    # names (SUB_/L_) are renamed consistently in both places by apply_naming.
    import re as _re
    _CF = _re.compile(r'\s*(JP|CALL|JR|DJNZ)\b')

    def _xregion(lns, resolve, lo, hi):
        out = []
        for ln in lns:
            code, sep, rest = ln.partition(';')
            if _CF.match(code):
                code = _re.sub(
                    r'\$([0-9A-Fa-f]{4})',
                    lambda m: (resolve(int(m.group(1), 16)) or m.group(0))
                    if lo <= int(m.group(1), 16) <= hi else m.group(0),
                    code)
            out.append(code + sep + rest)
        return out

    # Resolve through the OTHER region's formatter ._sym (not a plain label dict) so a
    # cross-region control-flow target that lands MID-INSTRUCTION (a cover/overlap, e.g.
    # ERROR_RESUME_FROM_DIRECT_3+1 = the $C1 operand byte of LD A,$C1 at $0E21, entered as
    # POP BC) renders as cover+offset and relocates -- a dict keyed on label heads cannot
    # express the +offset. Clean-label and no-label cases resolve identically to before.
    hdr_lines = _xregion(hdr_lines, body_fmt._sym, RUN, RUN + body_len)
    body_lines = _xregion(body_lines, hdr_fmt._sym, LOAD, LOAD + hdr_len)

    # Resolve the dispatch-table DEFW pointers into the body through the BODY formatter's
    # symbol resolver, which also handles mid-instruction targets as cover+offset (e.g.
    # REM/ELSE dispatch to STMT_DATA+2, the $01 skip idiom) -- a plain label dict can't.
    def _resolve_dispatch_defw(lns):
        out = []
        for ln in lns:
            code, sep, rest = ln.partition(';')
            if code.lstrip().startswith("DEFW"):
                def rep(m):
                    v = int(m.group(1), 16)
                    if RUN <= v < RUN + body_len:
                        return body_fmt._sym(v) or m.group(0)
                    return m.group(0)
                code = _re.sub(r'\$([0-9A-Fa-f]{4})', rep, code)
            out.append(code + sep + rest)
        return out

    hdr_lines = _resolve_dispatch_defw(hdr_lines)

    # strip the formatters' own `ORG $xxxx` lines (we frame them ourselves)
    def strip_org(lines):
        out = list(lines)
        while out and (out[0].strip().startswith("ORG ") or out[0].strip() == ""):
            out.pop(0)
        return out

    hdr_body = strip_org(hdr_lines)
    body_body = strip_org(body_lines)

    out = []
    out.append("; GBASIC.COM -- Microsoft BASIC-80 Rev 5.2 graphics interpreter, SoftCard CP/M 2.20 (44K).")
    out.append("; Clean-slate disassembly of the GBASIC.COM bytes on the 2.20-44K system disk")
    out.append("; (softcard-cpm2.20-44k-system.dsk); reassembles byte-identically to GBASIC.COM.")
    out.append("; Range:  $0100-$64FF  (25600 bytes)")
    out.append(";")
    out.append("; GBASIC self-relocates.  Entry ($0100) is JP $1000; the $1000 stub block-copies the")
    out.append("; interpreter from its on-disk position ($100E-$6490) UP to $3000-$8482 with LDDR, then")
    out.append("; JP $81D3 runs it at $3000+.  The interpreter body is therefore decoded at its run")
    out.append("; address $3000 and folded back to the .COM file offset with DISP/ENT: the bytes stay")
    out.append("; contiguous at their file position while every label resolves to the $3000+ run address.")
    out.append(";")
    out.append("; BASE decode: machine labels (L_/SUB_); semantic naming, strings, and [DOC] citations")
    out.append("; are layered on during enrichment.  Derived from the 2.20 binary only -- NOT the 2.23 .asm.")
    out.append("")
    out.append("    DEVICE NOSLOT64K")
    out.append("")
    out.append("    ORG $0100")
    out.append("")
    out.extend(hdr_body)
    out.append("")
    out.append("INTERP_LOAD_START:           ; physical $100E -- interpreter's first .COM byte (LDDR source)")
    out.append("    DISP $3000               ; runs at $3000 (the $1000 relocator LDDRs it up, then JP $81D3)")
    out.append("INTERP_RUN_START:")
    out.extend(body_body)
    out.append("INTERP_RUN_TOP:")
    out.append("    ENT")
    out.append("")
    out.append('    SAVEBIN "GBASIC.bin", $0100, $6400')
    from cpm_pipeline.basic.postpass import drop_orphan_labels
    # Protect the LDDR copy-boundary label ($8483 -> INTERP_COPY_END): the $1000 relocator
    # references it, but only via a literal operand that apply_naming later rewrites to
    # `INTERP_COPY_END-1`, so it looks orphaned here and would strand (it only survived by
    # coincidence when $8483's neighbourhood was decoded as code with stray refs).
    keep = {n for n in (bwalk.labels.get(0x8483),) if n}
    out = drop_orphan_labels(out, keep=keep)   # strip stranded harvest labels
    dest = asm_path("GBASIC")
    dest.write_text("\n".join(out) + "\n", encoding="latin-1")
    print("wrote", dest, len(out), "lines")

if __name__ == "__main__":
    main()
