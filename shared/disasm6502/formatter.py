"""ca65-compatible output formatter.

Produces a `.s` source file plus a matching `.cfg` linker script that
reassembles to byte-identical bytes via:
    ca65 OUT.s -o OUT.o
    ld65 -C OUT.cfg -o OUT.bin OUT.o
    cmp INPUT.bin OUT.bin   ->   silent

ca65 syntax notes
-----------------
  * Comments:        ; ...
  * Label:           Name:
  * Constant define: Name = $XXXX
  * Origin:          .org $XXXX  (placed inside a SEGMENTS-mapped segment)
  * Data:            .byte $XX, $YY      .word $XXYY      .res N, fill
  * Branches:        ca65 computes the signed 8-bit offset for BEQ/BNE/etc.
                     when the operand is a label or an address.
  * Zero-page vs absolute: ca65 picks zero-page automatically when the
                     resolved value is < $100. To force absolute (necessary
                     for round-trip when the original encoded an absolute
                     instruction with a low operand), prefix the operand
                     with `a:`. Defensive: we emit `a:` whenever the
                     ABS-mode operand is < $100.
"""

import sys
from pathlib import Path

# Allow `from disasm_common import ...` regardless of how this module is loaded.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from disasm_common.analyzer import (  # noqa: E402
    classify_data, DataKind, classify_overlap, overlap_expr,
)

from .opcodes import OPCODES, operand_size


import re as _re

# Auto label names the walker mints (anonymous); anything else is a semantic
# routine name worth preserving even when it lands mid-instruction.
_AUTO_BRANCH_RE = _re.compile(r'^L_[0-9A-Fa-f]{4}$')
_AUTO_SUB_RE = _re.compile(r'^SUB_[0-9A-Fa-f]{4}$')


def _resolve_label(addr, symbols, labels):
    """Pick a name for `addr` from labels first, then symbols, else None."""
    if addr in labels and labels[addr]:
        return labels[addr]
    if symbols is not None:
        n = symbols.name_for(addr)
        if n:
            return n
    return None


class Ca65Formatter:
    """Emit ca65 source + linker config from a Walker result."""

    def __init__(self, mem, walker, symbols=None, *,
                 origin=None, length=None, source_name="", pointer_words=None):
        """
        Args:
            mem:     full 64K memory image used by the walker
            walker:  Walker instance (after .trace() and .name_labels())
            symbols: SymbolTable instance (or None)
            origin:  load address; defaults to walker.start
            length:  number of bytes to emit; defaults to walker.end - origin
            source_name: shown in the header comment
            pointer_words: addresses to emit as a 2-byte `.word <label>` pointer
                (resolved static pointers / dispatch entries), so they relocate
                with ORG.
        """
        self.mem = mem
        self.walker = walker
        self.symbols = symbols
        self.origin = origin if origin is not None else walker.start
        self.length = length if length is not None else (walker.end - self.origin)
        self.source_name = source_name
        self.pointer_words = pointer_words or set()
        # Mid-instruction reference state (populated by _prepare_overlap_labels):
        #   _overlap_covers[addr] = (cover, offset)  anonymous -> inline cover+offset
        #   _overlap_named[addr]  = (name, cover, offset)  named -> equate, keep name
        self._overlap_covers = {}
        self._overlap_named = {}
        self._overlap_notes = []
        self._overlap_addrs = set()

    # ca65 defines a constant with `=` (sjasmplus uses EQU).
    _EQU = "="

    def _sym(self, addr):
        """Resolve `addr` to operand text. A NAMED mid-instruction routine keeps
        its semantic name (defined by an equate). An anonymous mid-instruction
        target resolves to `cover_label+offset` inline (or None -> literal when
        it falls inside a data run). Otherwise fall back to the normal lookup."""
        if addr in self._overlap_named:
            return self._overlap_named[addr][0]
        if addr in self._overlap_covers:
            cover_start, offset = self._overlap_covers[addr]
            cover_name = self.walker.labels.get(cover_start)
            if cover_name:
                return overlap_expr(cover_name, offset)
            return None
        return _resolve_label(addr, self.symbols, self.walker.labels)

    # ── Operand formatting ─────────────────────────────────────────────
    def _format_operand(self, addr, mnem, mode):
        m = self.mem
        if mode in ("IMP", "ACC"):
            return ""
        if mode == "IMM":
            return f"#${m[addr+1]:02X}"
        if mode == "ZP":
            return f"${m[addr+1]:02X}"
        if mode == "ZPX":
            return f"${m[addr+1]:02X},X"
        if mode == "ZPY":
            return f"${m[addr+1]:02X},Y"
        if mode == "IZX":
            return f"(${m[addr+1]:02X},X)"
        if mode == "IZY":
            return f"(${m[addr+1]:02X}),Y"
        if mode == "REL":
            off = m[addr+1]
            if off > 127:
                off -= 256
            target = (addr + 2 + off) & 0xFFFF
            name = self._sym(target)
            return name if name else f"$ {target:04X}".replace(" ", "")
        if mode in ("ABS", "ABX", "ABY", "IND"):
            val = m[addr+1] | (m[addr+2] << 8)
            name = self._sym(val)
            # Force absolute encoding when value < $100 (ca65 would otherwise
            # pick zero-page and produce a 2-byte instruction, breaking
            # the round-trip).
            prefix = "a:" if (val < 0x100 and name is None) else ""
            base = name if name else f"${val:04X}"
            if mode == "IND":
                return f"({prefix}{base})"
            sfx = {"ABS": "", "ABX": ",X", "ABY": ",Y"}[mode]
            return f"{prefix}{base}{sfx}"
        return ""

    # ── Source emission ────────────────────────────────────────────────
    def emit_source(self):
        """Return the full .s file contents as a single string."""
        # Classify every in-range label that lands mid-instruction and mint a
        # label on each covering instruction BEFORE emitting the body, so the
        # operand site can reference it inline as `cover+offset` (no equate).
        self._prepare_overlap_labels()
        # Two-pass emission: build the body so we know which external symbols
        # are actually referenced.
        body_lines, referenced, placed_labels = self._emit_body()
        out = []
        out.append(f"; Generated by disasm6502")
        if self.source_name:
            out.append(f"; Source: {self.source_name}")
        out.append(f"; Range:  ${self.origin:04X}-${self.origin + self.length - 1:04X}  "
                   f"({self.length} bytes)")
        out.append("")
        out.append('.setcpu "6502"')
        out.append('.segment "CODE"')
        out.append("")

        out.extend(self._emit_symbol_block(referenced))
        out.extend(self._emit_overlap_notes())
        out.extend(body_lines)
        return "\n".join(out) + "\n"

    def _decode_size(self, addr):
        return OPCODES[self.mem[addr]][2]

    def _build_instr_index(self):
        """Mirror how `_emit_body` steps through the image and return
        (instr_starts, byte_to_start): the set of code-instruction start
        addresses and a map from each interior code byte to its instruction
        start. Computed purely from `walker.code` + decode sizes, so it does
        not depend on (and is unaffected by) labels or data classification."""
        instr_starts = set()
        byte_to_start = {}
        addr = self.origin
        body_end = self.origin + self.length
        while addr < body_end:
            if addr in self.walker.code:
                size = self._decode_size(addr)
                if size <= 0:
                    addr += 1
                    continue
                instr_starts.add(addr)
                for i in range(1, size):
                    if addr + i < body_end:
                        byte_to_start[addr + i] = addr
                addr += size
            else:
                addr += 1
        return instr_starts, byte_to_start

    def _prepare_overlap_labels(self):
        """Find in-range walker labels that land mid-instruction and record how
        each should be referenced.

        A NAMED routine (curated symbol, hand-curated, or AI semantic name) that
        falls mid-instruction keeps its name, defined by an equate
        ``NAME = cover+offset``. An ANONYMOUS ``L_xxxx``/``SUB_xxxx`` overlap is
        referenced inline at its use site as ``cover+offset`` with no equate. A
        target with no covering instruction (inside a data run) falls back to a
        literal. In every case the mid-instruction walker label is removed and
        the covering instruction gets a minted label to anchor the expression."""
        instr_starts, byte_to_start = self._build_instr_index()
        body_start = self.origin
        body_end = self.origin + self.length
        self._overlap_covers = {}
        self._overlap_named = {}
        self._overlap_notes = []
        self._overlap_addrs = set()
        minted = False
        for addr in sorted(self.walker.labels.keys()):
            if not (body_start <= addr < body_end):
                continue
            name = self.walker.labels[addr]
            if not name:
                continue
            if addr in instr_starts:
                continue  # starts an instruction -> placed inline normally
            if addr not in byte_to_start:
                continue  # not interior to code -> data-run label, handled later
            res = classify_overlap(
                self.mem, addr,
                byte_to_start=byte_to_start,
                code_set=self.walker.code,
                decode_size=self._decode_size,
                cpu="6502",
            )
            semantic = not _AUTO_BRANCH_RE.match(name) and not _AUTO_SUB_RE.match(name)
            self._overlap_addrs.add(addr)
            self._overlap_notes.append(
                (addr, res.kind, res.cover_start, res.offset, res.reason,
                 name if semantic else None))
            del self.walker.labels[addr]   # never sits on a boundary
            if res.cover_start is not None and not self.walker.labels.get(res.cover_start):
                self.walker.add_label(res.cover_start)
                minted = True
            if semantic:
                self._overlap_named[addr] = (name, res.cover_start, res.offset)
            elif res.cover_start is not None:
                self._overlap_covers[addr] = (res.cover_start, res.offset)
        if minted:
            self.walker.name_labels(self.symbols)
        # Rename branch-only labels to <enclosing routine>_<n> for readability
        # (byte-identical; resolved lazily so cover+offset picks up new names).
        self.walker.localize_labels(self.symbols)

    def _overlap_expr_for(self, cover, offset, addr):
        """The cover+offset expression for an overlap, or a literal if no cover."""
        if cover is None:
            return f"${addr:04X}"
        return overlap_expr(self.walker.labels.get(cover, f"${cover:04X}"), offset)

    def _emit_overlap_notes(self):
        """Emit equates for NAMED mid-instruction routines (preserving their
        semantic names) plus an informational comment block for the anonymous
        ones (which are referenced inline as cover+offset)."""
        out = []
        if self._overlap_named:
            out.append("; -- Named mid-instruction routines (kept as cover+offset equates) --")
            for addr in sorted(self._overlap_named):
                name, cover, offset = self._overlap_named[addr]
                expr = self._overlap_expr_for(cover, offset, addr)
                out.append(f"{name:<20} {self._EQU} {expr:<18} ; ${addr:04X}")
            out.append("")
        if self._overlap_notes:
            out.append("; -- Mid-instruction references (shown inline as cover+offset) --")
            for addr, kind, cover, offset, reason, name in self._overlap_notes:
                expr = name if name else self._overlap_expr_for(cover, offset, addr)
                flag = "" if kind == "IDIOM" else "  [SUSPECTED MISFRAME -- review]"
                out.append(f";   ${addr:04X} -> {expr:<20} {reason}{flag}")
            out.append("")
        return out

    def _emit_symbol_block(self, referenced_addrs):
        """Emit equates only for the symbols actually referenced in the body
        (and only for those whose address falls outside the body range -- in-
        range labels are emitted inline at their address).
        """
        if self.symbols is None or not referenced_addrs:
            return []
        body_start = self.origin
        body_end = self.origin + self.length
        used = []
        for addr in sorted(referenced_addrs):
            if body_start <= addr < body_end:
                continue  # in-range; will be emitted as an inline label
            sym = self.symbols.get(addr)
            if sym is None:
                continue
            name, comment = sym
            used.append((addr, name, comment))
        if not used:
            return []
        out = ["; ── External symbols ──"]
        for addr, name, comment in used:
            line = f"{name:<20} = ${addr:04X}"
            if comment:
                line = f"{line:<40} ; {comment}"
            out.append(line)
        out.append("")
        return out

    def _emit_body(self):
        """Return (lines, referenced_addrs, placed_labels)."""
        out = []
        referenced = set()
        placed = set()
        out.append(f".org ${self.origin:04X}")
        out.append("")
        body_end = self.origin + self.length
        runs = classify_data(
            self.mem, self.origin, body_end,
            code_set=self.walker.code,
            labels=self.walker.labels,
            symbols=self.symbols,
            cpu="6502",
            body_start=self.origin, body_end=body_end,
            pointer_words=self.pointer_words,
        )
        runs_by_addr = {r.addr: r for r in runs}
        addr = self.origin
        while addr < body_end:
            label_name = self.walker.labels.get(addr)
            if label_name:
                out.append(f"{label_name}:")
                placed.add(addr)
            if addr in self.walker.code:
                line, refs = self._fmt_code_line(addr)
                out.append(line)
                referenced.update(refs)
                _, _, size = OPCODES[self.mem[addr]]
                addr += size
            else:
                run = runs_by_addr.get(addr)
                if run is None:
                    out.append(f"        .byte   ${self.mem[addr]:02X}    ; ${addr:04X}")
                    addr += 1
                    continue
                lines, refs = self._render_data_run(run)
                out.extend(lines)
                referenced.update(refs)
                addr = run.end
        return out, referenced, placed

    def _render_data_run(self, run):
        if run.kind == DataKind.FILL:
            return ([f"        .res    {len(run.raw)}, ${run.metadata['value']:02X}"
                     f"    ; ${run.addr:04X}  fill"], set())

        if run.kind == DataKind.STRING:
            return (self._render_string(run), set())

        if run.kind == DataKind.JUMP_TABLE:
            return self._render_jump_table(run)

        if run.kind == DataKind.POINTER_TABLE:
            return self._render_pointer_table(run)

        # MIXED
        bytes_str = ", ".join(f"${b:02X}" for b in run.raw)
        return ([f"        .byte   {bytes_str:<48} ; ${run.addr:04X}"], set())

    def _render_string(self, run):
        chars = run.metadata["chars"]
        term = run.metadata["terminator"]
        if all(0x20 <= b <= 0x7E for b in chars):
            try:
                quoted = chars.decode("ascii").replace('"', '\\"')
                return [f'        .byte   "{quoted}", ${term:02X}'
                        f'    ; ${run.addr:04X}  string']
            except UnicodeDecodeError:
                pass
        bytes_str = ", ".join(f"${b:02X}" for b in run.raw)
        decoded = "".join(
            chr(b & 0x7F) if 0x20 <= (b & 0x7F) <= 0x7E else "."
            for b in chars
        )
        return [f'        .byte   {bytes_str:<48} ; ${run.addr:04X}  "{decoded}"']

    def _render_jump_table(self, run):
        lines = ["        ; jump table"]
        refs = set()
        opcode = run.metadata["opcode"]
        mnem = "JMP" if opcode == 0x4C else "JSR"
        for i, target in enumerate(run.metadata["targets"]):
            label = self._resolve_label_for(target)
            target_str = label if label else f"${target:04X}"
            lines.append(f"        {mnem} {target_str:<24} ; ${run.addr + i*3:04X}")
            if (label and target not in self._overlap_addrs
                    and self.symbols and self.symbols.name_for(target)):
                refs.add(target)
        return lines, refs

    def _render_pointer_table(self, run):
        lines = []
        refs = set()
        for i, target in enumerate(run.metadata["targets"]):
            label = self._resolve_label_for(target)
            target_str = label if label else f"${target:04X}"
            lines.append(f"        .word   {target_str:<24} ; ${run.addr + i*2:04X}")
            if (label and target not in self._overlap_addrs
                    and self.symbols and self.symbols.name_for(target)):
                refs.add(target)
        return lines, refs

    def _resolve_label_for(self, addr):
        # Overlap-aware: a mid-instruction target renders as its semantic name
        # (named overlap) or cover+offset (anonymous), defined elsewhere.
        return self._sym(addr)

    def _fmt_code_line(self, addr):
        """Return (formatted_line, set_of_referenced_addresses)."""
        opcode = self.mem[addr]
        mnem, mode, size = OPCODES[opcode]
        operand, refs = self._format_operand_with_refs(addr, mnem, mode)
        instr = f"{mnem} {operand}".rstrip() if operand else mnem
        raw = " ".join(f"{self.mem[addr+i]:02X}" for i in range(size))
        return f"        {instr:<28} ; ${addr:04X}  {raw}", refs

    def _format_operand_with_refs(self, addr, mnem, mode):
        """Same as _format_operand but also returns the set of addresses
        whose symbols (if any) were substituted into the operand."""
        refs = set()
        if mode in ("ABS", "ABX", "ABY", "IND", "REL"):
            if mode == "REL":
                off = self.mem[addr+1]
                if off > 127:
                    off -= 256
                target = (addr + 2 + off) & 0xFFFF
            else:
                target = self.mem[addr+1] | (self.mem[addr+2] << 8)
            # A mid-instruction target is referenced inline as cover+offset and
            # needs no symbol-block equate.
            if (target not in self._overlap_addrs
                    and self.symbols is not None
                    and self.symbols.name_for(target) is not None
                    and not (self.origin <= target < self.origin + self.length
                             and self.walker.labels.get(target))):
                refs.add(target)
        return self._format_operand(addr, mnem, mode), refs


    # ── Linker config ──────────────────────────────────────────────────
    def emit_config(self):
        """Return the matching ld65 config file as a single string."""
        return (
            f"# Generated by disasm6502 for {self.source_name or 'image'}\n"
            f"MEMORY {{\n"
            f"    RAM: start = ${self.origin:04X}, "
            f"size = ${self.length:04X}, file = %O;\n"
            f"}}\n"
            f"SEGMENTS {{\n"
            f"    CODE: load = RAM, type = ro;\n"
            f"}}\n"
        )
