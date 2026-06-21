#!/usr/bin/env python
"""Clean-slate decode of MBASIC.COM from the 2.20-44K disk.

Unlike GBASIC (which self-relocates to $3000 via LDDR), MBASIC RUNS IN PLACE at $0100:
entry $0100 = JP $5E51 (cold start), the whole interpreter at $0100-$60FF.  So a single
ORG $0100 region, no DISP.  Same MS BASIC-80 Rev 5.2 engine as GBASIC, graphics OFF.
"""
from pathlib import Path
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline import reference_data as rd
from cpm_pipeline.basic._paths import asm_path, overlay_path, seeds_path, load_token_names
from cpm_pipeline.basic import reswords, lowtables, errmsg, errstub
from cpm_pipeline.basic.recover import recover_code
from cpm_pipeline.basic.fixed_sites import (fixed_operand_sites, cover_idiom_sites,
                                            mid_string_constant_sites)
from disasm_z80.walker import Walker
from disasm_z80.formatter import SjasmFormatter
from cpm_pipeline.region_disasm import (seed_leading_jp_vector,
    resolve_computed_dispatch, label_inrange_operands, scan_pointer_words)
from disasm_common.coverage import (maximize_coverage, z80_decoder,
    z80_dispatch_scanner, z80_ref_harvester)

LOAD = 0x0100
COLD = 0x5E51            # cold-start (entry JP target)
OVERLAY = overlay_path("MBASIC")


def synchr_addr(overlay_path):
    """Resolve the address of the SYNCHR routine by its name in the naming overlay
    (label -> address map), so the inline-byte-call address is derived from the
    single source of truth, not hard-coded per file. (MBASIC runs in place, so its
    SYNCHR sits at a different address than GBASIC's.)"""
    import json
    renames = json.loads(Path(overlay_path).read_text(encoding="utf-8")).get("renames", {})
    for addr_hex, name in renames.items():
        if name == "SYNCHR":
            return int(addr_hex, 16)
    raise ValueError(f"SYNCHR not found in {overlay_path}")


def main():
    com = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "MBASIC.COM"))
    end = LOAD + len(com)
    mem = bytearray(0x10000)
    mem[LOAD:end] = com

    # Harvest statement/function dispatch-table targets: the header DEFW tables
    # ($0103-$0251 + $04D8-$0521, before the reserved-word names + error strings)
    # point at the in-place handler code.
    def harvest(lo, hi):
        s = set()
        off = lo - LOAD
        while off < hi - LOAD - 1:
            v = com[off] | (com[off + 1] << 8)
            if LOAD + 0x400 <= v < end:        # a code address (past the tables)
                s.add(v)
            off += 2
        return s
    dispatch = harvest(0x0103, 0x0252) | harvest(0x04D8, 0x0522)
    # entry points reached only via stored vectors / cross-routine correspondence,
    # harvested from the GBASIC->MBASIC structural map (MBASIC.seeds.json) so each gets a
    # label that the transferred GBASIC name can attach to.
    import json as _json
    sf = seeds_path("MBASIC")
    mapped = set(_json.loads(sf.read_text())) if sf.exists() else set()

    w = Walker(mem, start=LOAD, end=end)
    # SYNCHR reads the byte after each CALL as its expected char and returns past
    # it; declare it as an inline-byte call so that byte is data (a char constant),
    # not a mis-decoded opcode that cascades. Address resolved from the overlay.
    w.inline_byte_calls = {synchr_addr(OVERLAY): 1}
    # The reserved-word NAME table ($0252-$04D7, last char high-bit set) + the
    # operator sub-table ($04D8-$04EC, char/token pairs) are pure DATA. GBASIC
    # leaves them as data (the header walker only traces the entry); MBASIC's single
    # whole-file walker otherwise wandered in and decoded the keyword strings as
    # bogus code (LD B,C / ADC A,$DE / ...). Pin the table as data so it stays DEFB.
    # The whole low-table region is DATA: statement dispatch $0108 (x85), function
    # dispatch $01B2 (x54), reswords index/name/operator $021E-$04EC, operator-precedence
    # $04ED (12 bytes), operator-routine cluster $04F9 (x20). MBASIC's single walker
    # otherwise decodes it as bogus code. Pin it as data BEFORE tracing.
    DISPATCH_TABLES = {0x0108: 85, 0x01B2: 54, 0x04F9: 20}
    dispatch_ptrs = {b + 2 * i for b, n in DISPATCH_TABLES.items() for i in range(n)}
    LOW_TABLES = (0x0108, 0x0522)
    w.add_data_region(*LOW_TABLES)
    # Seed the handler addresses the dispatch tables point at, read at the correct
    # even-aligned table positions (the range `harvest` above starts at the odd $0103 and
    # samples the statement table misaligned, missing some targets -> DEFW literals).
    dispatch_targets = set()
    for b, n in DISPATCH_TABLES.items():
        for i in range(n):
            t = com[b - LOAD + 2 * i] | (com[b - LOAD + 2 * i + 1] << 8)
            if LOAD <= t < end:
                dispatch_targets.add(t)
    entry_pts = {LOAD, COLD} | dispatch | dispatch_targets | (mapped & set(range(LOAD, end)))
    for s in entry_pts:
        w.call_targets.add(s)
    w.trace(LOAD)
    w.trace(COLD)
    for s in entry_pts:
        w.trace(s)
    seed_leading_jp_vector(w, mem, LOAD, len(com))
    _, disp = resolve_computed_dispatch(w, mem, LOAD, len(com))
    label_inrange_operands(w, mem, LOAD, len(com))
    maximize_coverage(w, mem, cpu="z80", decoder=z80_decoder(mem),
        scan_dispatch=z80_dispatch_scanner(mem, LOAD, end),
        harvest_refs=z80_ref_harvester(mem, LOAD, end))
    recover_code(w, mem, LOAD, end, protected=[LOW_TABLES])   # don't re-decode the tables
    label_inrange_operands(w, mem, LOAD, len(com))   # label recovered code's operands
    ptrs = scan_pointer_words(w, mem, LOAD, len(com)) | disp | dispatch_ptrs
    for s in entry_pts:
        w.add_label(s)
    w.add_label(reswords.INDEX_ADDR)   # split the data run at the reserved-word table
    w.name_labels()

    _, fixed = fixed_operand_sites()          # fixed operands -> keep literal (see gen_gbasic)
    keep_literal = (fixed | cover_idiom_sites(mem, w.code, LOAD, end)      # coded-constant covers
                    | lowtables.literal_sites(mem, w.code, LOAD, end)      # mid-pointer constants
                    | mid_string_constant_sites(mem, w.code, 0x0522, 0x081F, LOAD, end))
    fmt = SjasmFormatter(mem, w, origin=LOAD, length=len(com),
                         source_name="MBASIC", pointer_words=ptrs, relocatable=False,
                         inline_token_names=load_token_names(), keep_literal=keep_literal)
    fmt._harvest_data_labels()
    fmt._prepare_overlap_labels()
    body, _, _ = fmt._emit_body()
    # Decompose the reserved-word / token table ($021E-$04EC) into structured form,
    # then rewrite every code reference INTO that table (a machine label minted at a
    # table-interior address) to its structured label+offset -- the table is
    # relocatable image data, so references resolve to labels, not frozen literals.
    body = reswords.splice_table_into(body, com)
    body = reswords.apply_reference_renames(body, com)
    body = lowtables.apply(body)               # dispatch/operator table refs -> base+offset
    body = errmsg.splice_table_into(body, com)        # label every error message
    body = errmsg.apply_reference_renames(body, com)
    stub_old = errstub.stub_old_labels(body, com)     # capture old stub labels first
    body = errstub.splice_stubs_into(body, com)       # coded-error stubs -> RAISE_* / LD E,ERR_*
    body = errstub.apply_reference_renames(body, com, stub_old)

    out = []
    out.append("; MBASIC.COM -- Microsoft BASIC-80 Rev 5.2 interpreter (graphics OFF), SoftCard CP/M 2.20 (44K).")
    out.append("; Clean-slate disassembly of the MBASIC.COM bytes on the 2.20-44K system disk; reassembles")
    out.append("; byte-identically.  Range: $0100-$%04X (%d bytes).  MBASIC runs IN PLACE at $0100 (entry" % (end-1, len(com)))
    out.append("; $0100 = JP $5E51 cold start); it is the graphics-OFF build of the same engine as GBASIC,")
    out.append("; so the graphics tokens dispatch to a 'Graphics statement not implemented' error stub.")
    out.append("")
    out.append("    DEVICE NOSLOT64K")
    out.append("")
    # strip the formatter's ORG line and re-emit our own
    while body and (body[0].strip().startswith("ORG ") or body[0].strip() == ""):
        body.pop(0)
    out.append("    ORG $0100")
    out.append("")
    out.extend(body)
    out.append("")
    out.append('    SAVEBIN "MBASIC.bin", $0100, $%04X' % len(com))
    from cpm_pipeline.basic.postpass import drop_orphan_labels
    out = drop_orphan_labels(out)              # strip stranded harvest labels
    asm_path("MBASIC").write_text("\n".join(out) + "\n", encoding="latin-1")
    print("wrote MBASIC.asm", len(out), "lines; dispatch seeds:", len(dispatch))

if __name__ == "__main__":
    main()
