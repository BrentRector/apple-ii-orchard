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
from cpm_pipeline.basic import reswords
from cpm_pipeline.basic.recover import recover_code

from disasm_z80.walker import Walker
from disasm_z80.formatter import SjasmFormatter
from cpm_pipeline.region_disasm import (
    seed_leading_jp_vector, resolve_computed_dispatch, label_inrange_operands,
    scan_pointer_words,
)
from disasm_z80.symbols import SymbolTable

# ---- geometry ---------------------------------------------------------------
LOAD = 0x0100                 # .COM load address
RELOC_SRC_START = 0x100E      # first body byte in the file image
RUN = 0x3000                  # body run address (LDDR destination start)
BODY_ENTRY = 0x81D3           # JP target after LDDR
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
    hwalk.name_labels()
    hdr_fmt = SjasmFormatter(hdr_mem, hwalk, origin=LOAD, length=hdr_len,
                             source_name="GBASIC", relocatable=False,
                             inline_token_names=TOKENS)
    hdr_fmt._harvest_data_labels()
    hdr_fmt._prepare_overlap_labels()
    hdr_lines, _, _ = hdr_fmt._emit_body()
    # Decompose the reserved-word / token table ($021E-$04EC) into its structured
    # form (index -> DEFW group labels, name entries + TOK_ tokens, operator pairs).
    hdr_lines = reswords.splice_table_into(hdr_lines, com)

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
    # Register the body origin + every indirectly-reached entry point as a call TARGET
    # BEFORE any pass names labels: these are routine HEADS, so they must mint SUB_xxxx
    # head labels (not L_xxxx branch labels the localizer would fold into the preceding
    # routine -- e.g. STMT_END at $6956 was mislabelled SUB_6937_4, a local of RESTORE).
    entry_points = (({RUN, BODY_ENTRY} | dispatch_seeds | hdr_body_seeds)
                    & set(range(RUN, RUN + body_len)))
    for s in entry_points:
        bwalk.call_targets.add(s)
    bwalk.trace(RUN)            # body origin (CRUNCH, reached via a stored vector)
    bwalk.trace(BODY_ENTRY)     # cold-start initializer (JP $81D3 after LDDR)
    for s in dispatch_seeds:
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
    recover_code(bwalk, body_mem, RUN, RUN + body_len)
    label_inrange_operands(bwalk, body_mem, RUN, body_len)   # label the recovered code's
                                                             # operands so they relocate
    body_ptrs = scan_pointer_words(bwalk, body_mem, RUN, body_len) | body_dispatch
    # Ensure each entry point has a label (call_targets were registered up front so
    # name_labels mints SUB_xxxx heads for them).
    for s in entry_points:
        bwalk.add_label(s)
    # Label the LDDR copy boundary ($8483, top of the real interpreter; $8483-$84F1 is
    # dead .COM padding) so the $1000 relocator's bounds derive from it, not literals.
    bwalk.add_label(0x8483)
    bwalk.name_labels()
    # relocatable=False (the utility norm): label real control-flow/data targets but
    # leave in-range IMMEDIATE constants (e.g. LD BC,$3028 = graphics coords 48,40) as
    # literals instead of mislabelling them as the routine that happens to sit there.
    body_fmt = SjasmFormatter(body_mem, bwalk, origin=RUN, length=body_len,
                              source_name="GBASIC", pointer_words=body_ptrs,
                              relocatable=False, inline_token_names=TOKENS)
    body_fmt._harvest_data_labels()
    body_fmt._prepare_overlap_labels()
    body_lines, _, _ = body_fmt._emit_body()

    # Cross-region relocatability: header ($0100-$100D) and body ($3000+) are decoded
    # by SEPARATE walkers, so each region's control-flow operands into the OTHER region
    # were emitted as literals. Substitute them with the other walker's label so every
    # JP/CALL/JR target relocates (the body relocates to $3000 in GBASIC and runs in
    # place in MBASIC; a labeled operand assembles correctly for both). The machine
    # names (SUB_/L_) are renamed consistently in both places by apply_naming.
    import re as _re
    _CF = _re.compile(r'\s*(JP|CALL|JR|DJNZ)\b')

    def _xregion(lns, labels, lo, hi):
        out = []
        for ln in lns:
            code, sep, rest = ln.partition(';')
            if _CF.match(code):
                code = _re.sub(
                    r'\$([0-9A-Fa-f]{4})',
                    lambda m: labels.get(int(m.group(1), 16), m.group(0))
                    if lo <= int(m.group(1), 16) <= hi else m.group(0),
                    code)
            out.append(code + sep + rest)
        return out

    body_labels = {a: n for a, n in bwalk.labels.items() if n}
    hdr_labels = {a: n for a, n in hwalk.labels.items() if n}
    hdr_lines = _xregion(hdr_lines, body_labels, RUN, RUN + body_len)
    body_lines = _xregion(body_lines, hdr_labels, LOAD, LOAD + hdr_len)

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
    dest = asm_path("GBASIC")
    dest.write_text("\n".join(out) + "\n", encoding="latin-1")
    print("wrote", dest, len(out), "lines")

if __name__ == "__main__":
    main()
