"""Shared Z-80 region disassembly + reassembly helpers.

Several places disassemble a flat block of Z-80 bytes at a fixed origin, seeded
by known entry points, with a symbol table, into sjasmplus source that
round-trips byte-identical: the `.COM` decompiler (`decompile_com`), and the
BIOS source generators (`cpm-investigation/gen_bios.py`). This module holds the
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


def disasm_z80_region(mem: bytearray, org: int, length: int, *,
                      symbols: SymbolTable | None = None,
                      seeds=(), source_name: str = "") -> str:
    """Disassemble `mem[org:org+length]` to sjasmplus source (with `{out_bin}`).

    `mem` is a full 64 KB image with the region already placed at `org`. Every
    seed is traced (recursive descent follows control flow from there); `org` is
    always seeded. Address operands resolve to labels/symbols where known.
    """
    walker = Walker(mem, start=org, end=org + length)
    for s in sorted(set(seeds) | {org}):
        walker.trace(s)
    walker.name_labels(symbols=symbols)
    fmt = SjasmFormatter(mem, walker, symbols, origin=org, length=length, source_name=source_name)
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
