"""Recursive-descent code/data walker for the 6502.

The walker takes a 64K memory image, a set of entry points, and an
analyzable address range. Starting from each entry point it follows
all statically-determinable control flow (branches, JSR, JMP abs)
and marks every reachable byte as code. Anything unreachable is data.

Heuristics for stopping a trace:
  * already-visited address (joins an existing path)
  * user-supplied data region
  * undefined opcode (probably data)
  * an undocumented mnemonic (very rare in real code)
  * a multi-byte NOP (NOP $XX, NOP $XX,X, etc.) -- usually data
  * instruction bytes overlap a data region or extend past `end`
  * unconditional control transfer (JMP abs done after recursing target;
    JMP indirect, RTS, RTI, BRK stop without recursing)

Recursion depth is capped at 5000 to bound stack usage on adversarial input.
"""

from .opcodes import OPCODES, UNDOC_MNEMONICS


class Walker:
    """Recursive-descent code/data classifier."""

    MAX_DEPTH = 5000

    def __init__(self, mem, start=0, end=None):
        self.mem = mem
        self.start = start
        self.end = end if end is not None else len(mem)
        self.code = set()           # addrs confirmed as code bytes
        self.labels = {}            # addr -> label name (None = pending)
        self.jsr_targets = set()    # JSR destinations (for SUB_ vs L_ naming)
        self.data_regions = []      # list of (start, end_exclusive)
        self.entry_points = []      # informational

    def add_data_region(self, start, end_exclusive):
        self.data_regions.append((start, end_exclusive))

    def in_data_region(self, addr):
        return any(s <= addr < e for s, e in self.data_regions)

    def add_label(self, addr, name=None):
        """Mark `addr` as a label, optionally with a pre-assigned name.
        First-write wins on the name; later None calls won't overwrite."""
        if addr not in self.labels or self.labels[addr] is None:
            self.labels[addr] = name

    def trace(self, addr, depth=0):
        """Walk forward from `addr`, marking reachable bytes as code."""
        if depth > self.MAX_DEPTH:
            return
        if depth == 0:
            self.entry_points.append(addr)
            self.add_label(addr)
        while self.start <= addr < self.end:
            if addr in self.code:
                return
            if self.in_data_region(addr):
                return
            opcode = self.mem[addr]
            if opcode not in OPCODES:
                return
            mnem, mode, size = OPCODES[opcode]
            if mnem in UNDOC_MNEMONICS:
                return
            if mnem == "NOP" and opcode != 0xEA:
                return
            if addr + size > self.end:
                return
            if any(self.in_data_region(addr + i) for i in range(1, size)):
                return

            for i in range(size):
                self.code.add(addr + i)

            if mode == "REL" and size == 2:
                off = self.mem[addr + 1]
                if off > 127:
                    off -= 256
                target = (addr + 2 + off) & 0xFFFF
                if self.start <= target < self.end:
                    self.add_label(target)
                    self.trace(target, depth + 1)

            if mnem == "JSR" and size == 3:
                target = self.mem[addr + 1] | (self.mem[addr + 2] << 8)
                if self.start <= target < self.end:
                    self.add_label(target)
                    self.jsr_targets.add(target)
                    self.trace(target, depth + 1)

            if mnem == "JMP" and mode == "ABS" and size == 3:
                target = self.mem[addr + 1] | (self.mem[addr + 2] << 8)
                if self.start <= target < self.end:
                    self.add_label(target)
                    self.trace(target, depth + 1)
                return

            if mnem == "JMP" and mode == "IND":
                return
            if mnem in ("RTS", "RTI", "BRK"):
                return

            addr += size

    def name_labels(self, symbols=None):
        """Assign names to labels that don't have one yet.

        Naming priority:
          1. Symbol-table entry (e.g. KBD, BDOS_VEC) wins.
          2. JSR target -> SUB_xxxx
          3. Branch / JMP target -> L_xxxx
        """
        for addr in sorted(self.labels.keys()):
            if self.labels[addr] is not None:
                continue
            if symbols is not None:
                sym_name = symbols.name_for(addr)
                if sym_name:
                    self.labels[addr] = sym_name
                    continue
            if addr in self.jsr_targets:
                self.labels[addr] = f"SUB_{addr:04X}"
            else:
                self.labels[addr] = f"L_{addr:04X}"
