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


def disasm_z80_region(mem: bytearray, org: int, length: int, *,
                      symbols: SymbolTable | None = None,
                      seeds=(), source_name: str = "", force_labels=None,
                      resolve_dispatch=True, dyn_dispatch=None) -> str:
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
    for s in sorted(set(seeds) | {org}):
        walker.trace(s)
    pointer_words = None
    if resolve_dispatch:
        seed_leading_jp_vector(walker, mem, org, length)
        _, dispatch_words = resolve_computed_dispatch(walker, mem, org, length,
                                                      dyn_dispatch=dyn_dispatch)
        label_inrange_operands(walker, mem, org, length)
        pointer_words = scan_pointer_words(walker, mem, org, length) | dispatch_words
    if force_labels:
        for addr, name in force_labels.items():
            if org <= addr < org + length:
                walker.labels[addr] = name
    walker.name_labels(symbols=symbols)
    fmt = SjasmFormatter(mem, walker, symbols, origin=org, length=length,
                         source_name=source_name, pointer_words=pointer_words)
    return fmt.emit_source()


def assemble_z80(src_with_placeholder: str) -> bytes:
    """Assemble source produced by `disasm_z80_region` (or similar) back to bytes.

    Substitutes a temp path for `{out_bin}`, runs sjasmplus, and returns the
    emitted binary (empty bytes if assembly failed). Used for round-trip checks.
    """
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        out_bin = td / "out.bin"
        asm = td / "region.asm"
        asm.write_text(src_with_placeholder.replace("{out_bin}", out_bin.as_posix()),
                       encoding="utf-8")
        subprocess.run(["sjasmplus", str(asm)], capture_output=True, text=True, cwd=str(td))
        return out_bin.read_bytes() if out_bin.exists() else b""
