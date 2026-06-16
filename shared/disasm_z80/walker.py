"""Recursive-descent code/data classifier for Z-80 (parallel of disasm6502/walker.py).

Same algorithm: trace from entry points, follow control flow, mark reachable
bytes as code, stop at terminal instructions or when wandering into data.
"""

import re

from .opcodes import decode_at, ControlFlow, RST_TARGETS

# Auto branch-label pattern (L_xxxx); everything else is a routine "head".
_AUTO_BRANCH_RE = re.compile(r"^L_[0-9A-Fa-f]{4}$")


class Walker:
    MAX_DEPTH = 5000

    def __init__(self, mem, start=0, end=None):
        self.mem = mem
        self.start = start
        self.end = end if end is not None else len(mem)
        self.code = set()           # confirmed-code addresses
        self.labels = {}            # addr -> label name (None = pending)
        self.call_targets = set()   # CALL destinations -> SUB_xxxx vs L_xxxx
        self.data_regions = []
        self.entry_points = []

    def add_data_region(self, start, end_exclusive):
        self.data_regions.append((start, end_exclusive))

    def in_data_region(self, addr):
        return any(s <= addr < e for s, e in self.data_regions)

    def add_label(self, addr, name=None):
        if addr not in self.labels or self.labels[addr] is None:
            self.labels[addr] = name

    def trace(self, addr, depth=0):
        if depth > self.MAX_DEPTH:
            return
        if depth == 0:
            self.entry_points.append(addr)
            # Top-level entries always get a label so they appear in the
            # output -- otherwise jump-table entries that nothing inside
            # the body calls back to would remain anonymous.
            self.add_label(addr)
        while self.start <= addr < self.end:
            if addr in self.code:
                return
            if self.in_data_region(addr):
                return
            try:
                instr = decode_at(self.mem, addr)
            except (IndexError, KeyError):
                return  # ran off the end or hit unknown sequence
            if instr.size == 0:
                return
            if addr + instr.size > self.end:
                return
            if any(self.in_data_region(addr + i) for i in range(1, instr.size)):
                return

            for i in range(instr.size):
                self.code.add(addr + i)

            cf = instr.control_flow
            target = instr.target

            # RST p has a fixed page target ($00, $08, ..., $38) but the
            # decoder doesn't fill it in (the mnemonic encodes it directly).
            if cf == ControlFlow.CALL and target is None and instr.size == 1:
                target = RST_TARGETS.get(self.mem[addr])

            if target is not None and self.start <= target < self.end:
                self.add_label(target)
                if cf in (ControlFlow.CALL, ControlFlow.CALL_CC):
                    self.call_targets.add(target)
                self.trace(target, depth + 1)

            if cf == ControlFlow.JUMP_ABS:
                return
            if cf == ControlFlow.RET:
                return
            if cf == ControlFlow.INDIRECT:
                return
            if cf == ControlFlow.HALT:
                return
            # NEXT, JUMP_CC, CALL, CALL_CC, RET_CC -> fall through

            addr += instr.size

    def name_labels(self, symbols=None):
        for addr in sorted(self.labels.keys()):
            if self.labels[addr] is not None:
                continue
            if symbols is not None:
                sym_name = symbols.name_for(addr)
                if sym_name:
                    self.labels[addr] = sym_name
                    continue
            if addr in self.call_targets:
                self.labels[addr] = f"SUB_{addr:04X}"
            else:
                self.labels[addr] = f"L_{addr:04X}"

    def localize_labels(self, symbols=None):
        """Rename branch-only labels to ``<head>_<n>`` so a routine's internal
        labels read as locals of the routine they belong to (e.g. after a
        ``CONIO`` entry, the next branch labels become ``CONIO_1``, ``CONIO_2``).

        A *head* is any label with a non-auto name -- a CALL target (``SUB_xxxx``),
        a curated symbol, or a hand/AI semantic name. A *local* is an auto
        ``L_xxxx`` branch label. Each local is renamed to the nearest preceding
        head's name plus a per-head counter; locals before any head keep their
        auto name. Idempotent (names derive from role + address order) and
        byte-identical (renaming never changes bytes)."""
        def is_head(addr):
            name = self.labels.get(addr)
            return bool(name) and not _AUTO_BRANCH_RE.match(name)
        # Names that stay fixed (heads + locals before any head); locals are
        # renamed into the gaps, guaranteed unique against `used`.
        used = {n for a, n in self.labels.items() if n and is_head(a)}
        cur_head = None
        counter = 0
        for addr in sorted(self.labels.keys()):
            name = self.labels.get(addr)
            if not name:
                continue
            if is_head(addr):
                cur_head = name
                counter = 0
                continue
            if cur_head is None:
                used.add(name)                 # before any head -- leave as-is
                continue
            if addr not in self.code:          # a referenced data cell (RAM/var),
                used.add(name)                 # not a routine local -- keep its L_xxxx
                continue
            counter += 1
            candidate = f"{cur_head}_{counter}"
            if candidate in used:              # never emit a duplicate label
                candidate = f"{cur_head}_{counter}_{addr:04X}"
            self.labels[addr] = candidate
            used.add(candidate)
