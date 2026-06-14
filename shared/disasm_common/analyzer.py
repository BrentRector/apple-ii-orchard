"""Data-classification pass.

Runs AFTER the recursive walker has marked code addresses. For each
contiguous non-code byte run, the analyzer picks the most informative
classification so the formatter can emit a syntax that reveals structure
instead of dumping a 16-byte hex blob.

Classifications (priority order):

    FILL           >=8 identical bytes -> ``DEFS N, $XX``
    STRING         printable run terminated by $00/$8D/$24 -> quoted text
    JUMP_TABLE     >=3 consecutive ``JP nn`` (Z-80) or ``JMP nn`` (6502)
                   triples whose targets resolve to labels
    POINTER_TABLE  >=4 consecutive 16-bit values where most resolve to
                   known labels or look like sane code addresses
    MIXED          everything else -> ``DEFB`` row of up to 16 bytes,
                   broken at label boundaries

The analyzer never crosses into code regions or past label boundaries -- the
walker decides what's code, the analyzer decides how to format what's left.
"""

from dataclasses import dataclass, field
from enum import Enum


class DataKind(Enum):
    FILL = "fill"
    STRING = "string"
    JUMP_TABLE = "jump_table"
    POINTER_TABLE = "pointer_table"
    MIXED = "mixed"


@dataclass
class DataRun:
    addr: int
    raw: bytes
    kind: DataKind
    metadata: dict = field(default_factory=dict)

    @property
    def end(self):
        return self.addr + len(self.raw)

    def __len__(self):
        return len(self.raw)


# ── Predicates ────────────────────────────────────────────────────────
def is_printable_byte(b):
    """True for plain ASCII printables ($20-$7E) and Apple high-bit
    printables ($A0-$FE)."""
    return 0x20 <= b <= 0x7E or 0xA0 <= b <= 0xFE


def is_string_terminator(b):
    """Common terminators: $00 (C-style), $8D (Apple high-bit CR),
    $24 ('$', CP/M BDOS print-string), $0D (CR), $80 (Apple end marker)."""
    return b in (0x00, 0x8D, 0x24, 0x0D, 0x80)


# ── Length probes ─────────────────────────────────────────────────────
def _fill_length(mem, addr, end):
    val = mem[addr]
    n = 0
    while addr + n < end and mem[addr + n] == val:
        n += 1
    return n


def _string_length(mem, addr, end):
    """Length (including terminator) of a string starting at addr, or 0
    if no such string. Requires at least 4 printable chars + a terminator."""
    n = 0
    while addr + n < end and is_printable_byte(mem[addr + n]):
        n += 1
    if n >= 4 and addr + n < end and is_string_terminator(mem[addr + n]):
        return n + 1
    return 0


def _is_likely_code_addr(addr, labels, symbols, body_start, body_end):
    """A 16-bit value looks like a code address if it has a walker-discovered
    label (i.e. we traced into it as a real branch/call target). Symbol-table
    membership alone is too weak -- e.g. $0200 happens to be Apple II's IN
    buffer, so a sequential lookup table like `00 02 04 06 ...` would
    incorrectly look like a pointer to IN."""
    if labels is not None and addr in labels and labels[addr] is not None:
        return True
    return False


def _is_loose_code_addr(addr, labels, symbols, body_start, body_end):
    """Looser variant used only for jump-table detection (where the JP/JMP
    opcode prefix is itself strong evidence). Accepts symbol-table entries
    above page zero, or body-range hits, in addition to walker labels."""
    if _is_likely_code_addr(addr, labels, symbols, body_start, body_end):
        return True
    if symbols is not None and addr >= 0x0100 and symbols.name_for(addr):
        return True
    if body_start <= addr < body_end:
        return True
    return False


def _jump_table_length(mem, addr, end, *, cpu, labels, symbols, body_start, body_end):
    """Number of 3-byte JP/JMP entries starting at addr."""
    if cpu == "z80":
        opcodes = (0xC3,)              # JP nn
    elif cpu == "6502":
        opcodes = (0x4C, 0x20)         # JMP, JSR
    else:
        return 0
    n = 0
    while addr + n * 3 + 2 < end:
        op = mem[addr + n * 3]
        if op not in opcodes:
            break
        target = mem[addr + n * 3 + 1] | (mem[addr + n * 3 + 2] << 8)
        # Looser check: the JP/JMP opcode prefix is strong evidence; we
        # don't need to insist on a walker-confirmed label.
        if not _is_loose_code_addr(target, labels, symbols, body_start, body_end):
            break
        n += 1
    return n


def _pointer_table_length(mem, addr, end, *, labels, symbols, body_start, body_end):
    """Number of 2-byte little-endian pointers starting at addr that look
    plausible. Requires >=4 entries with >=75% hit rate against known
    labels/symbols/body-range."""
    available = (end - addr) // 2
    if available < 4:
        return 0
    targets = []
    for i in range(available):
        t = mem[addr + 2 * i] | (mem[addr + 2 * i + 1] << 8)
        targets.append(t)
    # Greedy: extend as long as the rolling hit rate stays above threshold
    hits = sum(1 for t in targets[:4]
               if _is_likely_code_addr(t, labels, symbols, body_start, body_end))
    if hits < 3:  # at least 3 of first 4 must hit
        return 0
    n = 4
    while n < available:
        t = targets[n]
        if _is_likely_code_addr(t, labels, symbols, body_start, body_end):
            hits += 1
            n += 1
        else:
            # Allow occasional misses but cap the table when miss rate climbs
            if hits / (n + 1) < 0.75:
                break
            n += 1
    return n


def _mixed_length(mem, addr, end, labels):
    """Length of a generic byte run. Stops at the first label boundary
    (so the label gets emitted on its own line) and caps at 16 bytes
    for readable column-aligned output."""
    n = 1  # always consume at least the first byte
    while addr + n < end and n < 16:
        if labels is not None and (addr + n) in labels:
            break
        n += 1
    return n


# ── Per-position classifier ───────────────────────────────────────────
def classify_at(mem, addr, end, *, labels=None, symbols=None, cpu="z80",
                body_start=0, body_end=0x10000):
    """Pick the longest informative classification starting at `addr`.

    `end` caps the search (typically the next code byte's address). `labels`
    is a dict of addr -> label-name (for label-boundary breaks and pointer-
    table validation). `cpu` selects jump-opcode set ('z80' or '6502')."""
    # Fill is highest priority -- 8+ identical bytes is a hard signal.
    fill_n = _fill_length(mem, addr, end)
    if fill_n >= 8:
        return DataRun(addr, bytes(mem[addr:addr + fill_n]), DataKind.FILL,
                       {"value": mem[addr]})

    # String: printable run + terminator
    s_n = _string_length(mem, addr, end)
    if s_n:
        chars = bytes(mem[addr:addr + s_n - 1])
        term = mem[addr + s_n - 1]
        return DataRun(addr, bytes(mem[addr:addr + s_n]), DataKind.STRING,
                       {"chars": chars, "terminator": term})

    # Jump table: at least 3 entries
    jt_n = _jump_table_length(mem, addr, end, cpu=cpu, labels=labels,
                              symbols=symbols,
                              body_start=body_start, body_end=body_end)
    if jt_n >= 3:
        targets = [mem[addr + i*3 + 1] | (mem[addr + i*3 + 2] << 8)
                   for i in range(jt_n)]
        return DataRun(addr, bytes(mem[addr:addr + jt_n * 3]),
                       DataKind.JUMP_TABLE,
                       {"targets": targets, "opcode": mem[addr]})

    # Pointer table: at least 4 entries
    pt_n = _pointer_table_length(mem, addr, end, labels=labels, symbols=symbols,
                                 body_start=body_start, body_end=body_end)
    if pt_n >= 4:
        targets = [mem[addr + i*2] | (mem[addr + i*2 + 1] << 8)
                   for i in range(pt_n)]
        return DataRun(addr, bytes(mem[addr:addr + pt_n * 2]),
                       DataKind.POINTER_TABLE, {"targets": targets})

    # Default: mixed bytes up to label or 16-byte limit
    mixed_n = _mixed_length(mem, addr, end, labels)
    return DataRun(addr, bytes(mem[addr:addr + mixed_n]), DataKind.MIXED)


# ── Range classifier ──────────────────────────────────────────────────
def classify_data(mem, start, end, *, code_set, labels=None, symbols=None,
                  cpu="z80", body_start=None, body_end=None):
    """Walk [start, end), skip code addresses, and yield DataRun objects
    covering the non-code regions. The caller is responsible for emitting
    code lines for addresses in `code_set`."""
    if body_start is None:
        body_start = start
    if body_end is None:
        body_end = end
    runs = []
    addr = start
    while addr < end:
        if addr in code_set:
            addr += 1
            continue
        # Determine how far the contiguous non-code region extends
        non_code_end = addr
        while non_code_end < end and non_code_end not in code_set:
            non_code_end += 1
        # Sub-classify within [addr, non_code_end)
        sub = addr
        while sub < non_code_end:
            run = classify_at(mem, sub, non_code_end, labels=labels,
                              symbols=symbols, cpu=cpu,
                              body_start=body_start, body_end=body_end)
            runs.append(run)
            sub = run.end
        addr = non_code_end
    return runs
