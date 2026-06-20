"""Shared Z-80 region disassembly + reassembly helpers.

Several places disassemble a flat block of Z-80 bytes at a fixed origin, seeded
by known entry points, with a symbol table, into sjasmplus source that
round-trips byte-identical: the `.COM` decompiler (`decompile_com`), and the
BIOS source generators. This module holds the
one copy of that logic so they don't each re-implement it.

`disasm_z80_region` returns source text containing a literal ``{out_bin}``
placeholder for the `SAVEBIN` target; callers substitute a real path before
writing or assembling. `assemble_z80` does the reverse (assemble such text back
to bytes) for round-trip checks.
"""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from disasm_z80.walker import Walker
from disasm_z80.symbols import SymbolTable
from disasm_z80.formatter import SjasmFormatter


def load_symbols(*paths) -> SymbolTable:
    """Build a SymbolTable from the given JSON files (skipping any that are absent)."""
    sym = SymbolTable()
    for p in paths:
        p = Path(p)
        if p.exists():
            sym.load_file(str(p))
    return sym


def bios_jump_table_seeds(mem: bytes, org: int, length: int, entries: int = 17) -> set[int]:
    """Seed addresses for a leading CP/M BIOS jump table: each 3-byte slot and,
    for `JP nn` slots, the in-range target. Disassembles the whole table as JPs
    plus the handlers it points at."""
    seeds = {org}
    for i in range(entries):
        a = org + 3 * i
        if a + 3 <= org + length:
            seeds.add(a)
            if mem[a] == 0xC3:                       # JP nn
                target = mem[a + 1] | (mem[a + 2] << 8)
                if org <= target < org + length:
                    seeds.add(target)
    return seeds


def resolve_computed_dispatch(walker, mem, org, length, *, dyn_dispatch=None):
    """Resolve computed-dispatch jump/pointer tables via static register
    data-flow (and optional dynamic-trace harvest), so their entries get labels
    and the table body is marked data -- which lets the existing table detector
    + `_render_pointer_table` emit relocatable `DEFW <label>` instead of raw,
    non-relocatable `DEFB`. Returns the resolved tables (for logging/tests)."""
    from disasm_z80.dataflow import scan_static_dispatch
    body_start, body_end = org, org + length
    tables = scan_static_dispatch(mem, walker, body_start=body_start, body_end=body_end)
    if dyn_dispatch:
        tables = _merge_dispatch(tables, dyn_dispatch, mem, walker, body_start, body_end)
    dispatch_words = set()
    for t in tables:
        # mark the table body as data BEFORE re-tracing entries, so a target that
        # happens to fall inside the table is never decoded as code.
        walker.add_data_region(t.table_addr, t.table_addr + t.n_bytes)
        if body_start <= t.table_addr < body_end:
            walker.add_label(t.table_addr)       # so `LD HL,table` relocates too
        for e in t.entry_targets:
            if body_start <= e < body_end:
                walker.add_label(e)
        post = t.table_addr + t.n_bytes          # cap boundary for the detector
        if body_start <= post < body_end:
            walker.add_label(post)
        for e in t.entry_targets:                # trace non-executed arms into code
            if body_start <= e < body_end:
                walker.trace(e)
        # emit each pointer entry as a DEFW directly (robust to entries that point
        # OUT of the module, e.g. BDOS fn 0/4/5 -> BIOS $FAxx, which the analyzer's
        # in-range pointer-table detector would reject).
        if t.kind == "pointer":
            for i in range(t.n_entries):
                dispatch_words.add(t.table_addr + 2 * i)
    return tables, dispatch_words


def seed_leading_jp_vector(walker, mem, org, length):
    """Seed each slot of a leading `JP nn` vector at the region origin (the
    classic CCP/BIOS entry table). The cold entry is an unconditional JP, so the
    walker never falls through to the warm entry -- seeding makes every alternate
    entry real code (and thus relocatable) instead of a stranded data `DEFB`."""
    from disasm_z80.opcodes import decode_at
    a = org
    while a + 2 < org + length and (a - org) < 0x30 and mem[a] == 0xC3:
        walker.trace(a)
        a += 3


def scan_pointer_words(walker, mem, org, length):
    """Find static pointer words in data: a 2-byte value that resolves to a
    label or a traced instruction-start is (almost certainly) a relocatable
    pointer. Returns their addresses (for `DEFW <label>` emission) and labels
    each target. Skips code and already-marked dispatch-table data regions.
    Greedy + 2-byte aligned so adjacent pointers (tables) and singles both fall
    out; a false positive would surface as a relocation mismatch, so the rule is
    deliberately strong (label or instruction-start, in range)."""
    from disasm_z80.opcodes import decode_at
    starts = set()
    a = org
    while a < org + length:
        if a in walker.code:
            starts.add(a)
            try:
                a += decode_at(mem, a).size or 1
            except (IndexError, KeyError):
                a += 1
        else:
            a += 1
    pw = set()
    a = org
    while a + 1 < org + length:
        if a in walker.code or walker.in_data_region(a):
            a += 1
            continue
        v = mem[a] | (mem[a + 1] << 8)
        # skip if the pointer's high byte is itself a referenced label (pending or
        # named): a DEFW there would swallow that label's definition.
        if (org <= v < org + length and (v in walker.labels or v in starts)
                and (a + 1) not in walker.labels):
            pw.add(a)
            walker.add_label(v)
            a += 2
        else:
            a += 1
    return pw


def label_inrange_operands(walker, mem, org, length):
    """Plant a label on every in-range absolute address operand (data loads/
    stores, immediate pointers) so `_substitute_operand_symbols` renders it as a
    symbol that relocates with ORG -- not just control-flow targets. A genuine
    in-range 16-bit *constant* would be mislabeled; the byte-identical round-trip
    catches that (it would relocate wrongly), so this stays sound by construction."""
    import re as _re
    from disasm_z80.opcodes import decode_at
    body_end = org + length
    a = org
    while a < body_end:
        if a in walker.code:
            try:
                ins = decode_at(mem, a)
            except (IndexError, KeyError):
                a += 1
                continue
            for m in _re.finditer(r"\$([0-9A-Fa-f]{4})", ins.mnemonic):
                v = int(m.group(1), 16)
                if org <= v < body_end:
                    walker.add_label(v)
            a += ins.size or 1
        else:
            a += 1


def _merge_dispatch(static_tables, dyn_dispatch, mem, walker, body_start, body_end):
    """Union static-resolved tables with dynamically-observed JP (HL) targets.
    Static tables are the complete set (incl. non-executed arms); dynamic targets
    confirm executed arms. A dynamic target that contradicts a static table (same
    jp_addr, target not among entries) demotes that table to bare labels."""
    by_jp = {t.jp_addr: t for t in static_tables}
    kept = []
    for t in static_tables:
        dyn = dyn_dispatch.get(t.jp_addr)
        if dyn and not (set(dyn) <= set(t.entry_targets)):
            # dynamic evidence contradicts the static table -> don't assert a
            # DEFW run; just label the observed targets individually.
            for e in dyn:
                if body_start <= e < body_end:
                    walker.add_label(e); walker.trace(e)
            continue
        kept.append(t)
    # dynamic dispatches with no matching static table -> plain labelled seeds
    for jp_addr, targets in dyn_dispatch.items():
        if jp_addr in by_jp:
            continue
        for e in targets:
            if body_start <= e < body_end:
                walker.add_label(e); walker.trace(e)
    return kept


# ── Foreign-CPU code regions (e.g. an embedded 6502 RPC block in a Z-80 image) ──
#
# Some SoftCard CP/M modules carry machine code for the OTHER CPU inline: the
# 2.20 CCP embeds a 6502 RPC payload that the SoftCard runs on the 6502 side via
# the CPU switch. From the Z-80 assembler's view those bytes are DATA (decoding
# them as Z-80 is garbage, and auto-detecting pointers in them wrongly relocates
# mid-instruction bytes). We pin such a span as opaque DEFB AND annotate the
# foreign-code bytes with the other CPU's mnemonics so the source is readable.

def _format_6502_instr(mem, addr):
    """Return (size, "MNEM operand") for the 6502 instruction at `addr`, or
    (1, None) if the opcode is unknown. Operands are literal (no symbol lookup);
    this is comment text, never assembled."""
    from disasm6502.opcodes import OPCODES
    e = OPCODES.get(mem[addr])
    if e is None:
        return 1, None
    mn, mode, size = e
    if mode in ("IMP", "ACC"):
        op = ""
    elif mode == "IMM":
        op = f"#${mem[addr+1]:02X}"
    elif mode == "ZP":
        op = f"${mem[addr+1]:02X}"
    elif mode == "ZPX":
        op = f"${mem[addr+1]:02X},X"
    elif mode == "ZPY":
        op = f"${mem[addr+1]:02X},Y"
    elif mode == "IZX":
        op = f"(${mem[addr+1]:02X},X)"
    elif mode == "IZY":
        op = f"(${mem[addr+1]:02X}),Y"
    elif mode == "REL":
        off = mem[addr+1]
        off = off - 256 if off > 127 else off
        op = f"${(addr + 2 + off) & 0xFFFF:04X}"
    else:  # ABS/ABX/ABY/IND
        v = mem[addr+1] | (mem[addr+2] << 8)
        if mode == "IND":
            op = f"(${v:04X})"
        else:
            op = f"${v:04X}" + {"ABS": "", "ABX": ",X", "ABY": ",Y"}[mode]
    return size, f"{mn} {op}".strip()


def foreign_code_map(mem, start, end, *, entries, data_subregions=()):
    """Disassemble a foreign 6502-code span and return {addr: (size, mnemonic)}
    for every instruction start the trace proves is code.

    Recursive descent from `entries` (the Z-80 references into the block + its
    own internal flow) plus an after-terminal sweep (the byte following a JMP/
    RTS/RTI/BRK is the next routine, often entered only from outside the block).
    `data_subregions` ((start,end) spans -- lookup tables, the trailing pad, the
    Z-80-accessed word cells) are never decoded as code, so they neither desync
    the sweep nor get a spurious mnemonic.

    These are SoftCard-specific blocks analysed by hand, so the caller supplies
    the entry points and data spans; the result is comment-only annotation, so a
    mis-trace can never change emitted bytes."""
    from disasm6502.opcodes import OPCODES, UNDOC_MNEMONICS

    def in_data(a):
        return any(s <= a < e for s, e in data_subregions)

    code = set()

    def trace(a):
        stack = [a]
        while stack:
            x = stack.pop()
            while start <= x < end and x not in code and not in_data(x):
                ent = OPCODES.get(mem[x])
                if ent is None:
                    break
                mn, mode, size = ent
                if mn in UNDOC_MNEMONICS:
                    break
                if mn == "NOP" and mem[x] != 0xEA:
                    break
                if x + size > end or any(in_data(x + i) for i in range(size)):
                    break
                for i in range(size):
                    code.add(x + i)
                if mode == "REL":
                    off = mem[x+1]
                    off = off - 256 if off > 127 else off
                    t = (x + 2 + off) & 0xFFFF
                    if start <= t < end:
                        stack.append(t)
                if mn == "JSR":
                    t = mem[x+1] | (mem[x+2] << 8)
                    if start <= t < end:
                        stack.append(t)
                if mn == "JMP" and mode == "ABS":
                    t = mem[x+1] | (mem[x+2] << 8)
                    if start <= t < end:
                        stack.append(t)
                    break
                if mn in ("JMP", "RTS", "RTI", "BRK"):
                    break
                x += size

    for e in entries:
        if start <= e < end:
            trace(e)
    # After-terminal sweep to a fixpoint: a routine reached only from outside the
    # block still sits right after a terminal instruction we did trace.
    changed = True
    while changed:
        changed = False
        for a in sorted(code):
            ent = OPCODES.get(mem[a])
            if not ent:
                continue
            mn, _mode, size = ent
            if mn in ("JMP", "RTS", "RTI", "BRK"):
                nxt = a + size
                if start <= nxt < end and nxt not in code and not in_data(nxt):
                    before = len(code)
                    trace(nxt)
                    if len(code) > before:
                        changed = True
    # Build the instr-start -> (size, mnemonic) map over confirmed code.
    annot = {}
    a = start
    while a < end:
        if a in code:
            size, mnem = _format_6502_instr(mem, a)
            annot[a] = (size, mnem)
            a += size or 1
        else:
            a += 1
    return annot


def disasm_z80_region(mem: bytearray, org: int, length: int, *,
                      symbols: SymbolTable | None = None,
                      seeds=(), source_name: str = "", force_labels=None,
                      resolve_dispatch=True, dyn_dispatch=None,
                      auto_coverage=False, relocatable=False,
                      foreign_regions=None) -> str:
    """Disassemble `mem[org:org+length]` to sjasmplus source (with `{out_bin}`).

    `mem` is a full 64 KB image with the region already placed at `org`. Every
    seed is traced (recursive descent follows control flow from there); `org` is
    always seeded. Address operands resolve to labels/symbols where known.

    `force_labels` ({addr: name}) plants a label at each in-range address even if
    it is only a fall-through point -- used to preserve hand-curated / AI semantic
    names that aren't control-flow targets. Labels are zero-width, so this stays
    byte-identical as long as the address is an instruction (or data-run) start.
    """
    walker = Walker(mem, start=org, end=org + length)
    # Foreign-CPU code spans are DATA to the Z-80: mark them as data regions
    # BEFORE tracing so the walker never decodes them as Z-80 (a Z-80 CALL into
    # the block still gets its label, but the bytes stay data) and the
    # pointer/operand passes skip them. They render as an INCBIN of a
    # separately-assembled binary; their entry-point symbols come from an INCLUDE.
    for fr in (foreign_regions or []):
        walker.add_data_region(fr["start"], fr["end"])
    for s in sorted(set(seeds) | {org}):
        walker.trace(s)
    pointer_words = None
    if resolve_dispatch:
        seed_leading_jp_vector(walker, mem, org, length)
        _, dispatch_words = resolve_computed_dispatch(walker, mem, org, length,
                                                      dyn_dispatch=dyn_dispatch)
        label_inrange_operands(walker, mem, org, length)
        pointer_words = scan_pointer_words(walker, mem, org, length) | dispatch_words
    if auto_coverage:
        # Recover code the seeds/dispatch didn't reach (un-executed paths after a
        # dynamic trace, fall-through-after-terminal routines): a validated,
        # core-anchored, string-walled sweep. Byte-identical (code/data split only).
        from disasm_common.coverage import (
            maximize_coverage, z80_decoder, z80_dispatch_scanner, z80_ref_harvester,
        )
        maximize_coverage(
            walker, mem, cpu="z80", decoder=z80_decoder(mem),
            scan_dispatch=z80_dispatch_scanner(mem, org, org + length),
            harvest_refs=z80_ref_harvester(mem, org, org + length),
        )
        if resolve_dispatch:
            pointer_words = (pointer_words or set()) | scan_pointer_words(walker, mem, org, length)
    if force_labels:
        for addr, name in force_labels.items():
            if org <= addr < org + length:
                walker.labels[addr] = name
    walker.name_labels(symbols=symbols)
    # For each foreign region, the base label is the walker's label at its start
    # (e.g. L_9400 -- what Z-80 code uses for the block base); every other
    # in-region referenced label becomes `<base> + offset` in the INCLUDE.
    fr_render = []
    for fr in (foreign_regions or []):
        start = fr["start"]
        base = walker.labels.get(start) or f"FOREIGN_{start:04X}"
        walker.add_label(start, base)
        fr_render.append({**fr, "base_label": base})
    fmt = SjasmFormatter(mem, walker, symbols, origin=org, length=length,
                         source_name=source_name, pointer_words=pointer_words,
                         relocatable=relocatable, foreign_regions=fr_render)
    return fmt.emit_source()


def foreign_include_text(mem, org, length, fr, *, symbols=None, seeds=(),
                         force_labels=None):
    """Generate the sjasmplus EQU include for a foreign region's entry points:
    every in-region address Z-80 code references, as ``name EQU <base> + $off``
    so it relocates with ORG (the base label sits at the INCBIN). Re-runs the
    Z-80 trace to discover which in-region addresses are referenced (same walker
    inputs as `disasm_z80_region`), then emits an EQU per in-region label except
    the base itself."""
    walker = Walker(mem, start=org, end=org + length)
    for f in (force_labels or {}).items():
        pass
    for f in [fr]:
        walker.add_data_region(f["start"], f["end"])
    for s in sorted(set(seeds) | {org}):
        walker.trace(s)
    # operand/pointer passes so data-cell references in the block are labelled too
    label_inrange_operands(walker, mem, org, length)
    scan_pointer_words(walker, mem, org, length)
    if force_labels:
        for addr, name in force_labels.items():
            if org <= addr < org + length:
                walker.labels[addr] = name
    walker.name_labels(symbols=symbols)
    start, end = fr["start"], fr["end"]
    base = walker.labels.get(start) or f"FOREIGN_{start:04X}"
    lines = [
        f"; Entry points + data cells of the embedded {fr.get('cpu','6502')} block,",
        f"; as offsets from {base} (the INCBIN base) so they relocate with ORG.",
        f"; Generated -- do not edit by hand.",
        "",
    ]
    for addr in sorted(walker.labels):
        if not (start <= addr < end) or addr == start:
            continue
        name = walker.labels[addr]
        if not name:
            continue
        lines.append(f"{name:<16} EQU {base} + ${addr - start:03X}")
    return "\n".join(lines) + "\n"


def assemble_z80(src_with_placeholder: str, *, incbin_deps=()) -> bytes:
    """Assemble source produced by `disasm_z80_region` (or similar) back to bytes.

    Substitutes a temp path for `{out_bin}`, runs sjasmplus, and returns the
    emitted binary (empty bytes if assembly failed). Used for round-trip checks.

    `incbin_deps` lets a Z-80 source INCBIN a separately-assembled 6502 block
    (the cross-CPU INCBIN pattern: a utility carries an embedded 6502 payload as
    its own ca65 source, sub-assembled and INCBIN'd back so each CPU's code is
    real source in its own assembler). Each entry is ``(bin_name, ca65_src_path,
    defines)``: the ca65 source (with its sibling ``.cfg``) is assembled into the
    temp dir as ``bin_name`` BEFORE sjasmplus runs, and sjasmplus runs with
    ``cwd`` = the temp dir so the Z-80 source's ``INCBIN "bin_name"`` resolves.
    """
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        out_bin = td / "out.bin"
        for bin_name, src_path, defines in incbin_deps:
            from .assemble import _build_incbin_dep
            _build_incbin_dep(Path(src_path), td / bin_name, tuple(defines))
        asm = td / "region.asm"
        asm.write_text(src_with_placeholder.replace("{out_bin}", out_bin.as_posix()),
                       encoding="utf-8")
        subprocess.run(["sjasmplus", str(asm)], capture_output=True, text=True, cwd=str(td))
        return out_bin.read_bytes() if out_bin.exists() else b""
