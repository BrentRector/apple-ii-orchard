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


# ── Code-overlap (mid-instruction reference) classification ────────────
#
# A recursive-descent walker can discover a control-flow target whose address
# falls in the INTERIOR of another instruction in the primary decode stream.
# An assembler cannot place a label there (it would split the instruction and
# change the bytes), so the formatter must name the address some other way.
#
# The right answer for a GENUINE mid-instruction reference is `cover+offset`:
# a label on the covering instruction's start plus the byte offset into it
# (e.g. `BIT_SKIP+1`). The assembler evaluates that to the identical absolute
# value the old bare `EQU $XXXX` produced, so round-trip is preserved, and the
# source now documents *why* the address is mid-instruction.
#
# Two shapes are genuine:
#   * a named "skip" idiom -- a 6502 `BIT`/Z-80 `LD rr,nn`/`LD A,n` whose
#     operand bytes are entered as a real instruction on another path; and
#   * a shared instruction tail -- the interior address is itself reachable
#     code (the walker traced it), so two decodes legitimately share bytes.
# Anything else (the interior of a non-idiom instruction that is NOT reached
# as code, or a label that fell inside a data run with no covering
# instruction at all) is a MISFRAME: a symptom that the code/data
# classification or the ORG is wrong, not a real overlap.

# Named mid-instruction "skip" idioms: opcode -> the operand-byte offsets a
# second control-flow path can legitimately enter as its own instruction.
_IDIOM_COVERS = {
    "6502": {
        0x2C: (1, 2),   # BIT abs  -- classic "skip 2": operand bytes run as code
        0x24: (1,),     # BIT zp   -- "skip 1"
    },
    "z80": {
        0x21: (1, 2),   # LD HL,nn -- "skip 2" via 16-bit immediate
        0x01: (1, 2),   # LD BC,nn
        0x11: (1, 2),   # LD DE,nn
        0x3E: (1,),     # LD A,n   -- "skip 1" via 8-bit immediate
    },
}


@dataclass
class OverlapResult:
    """Outcome of classifying an in-range label the formatter cannot place
    inline. `kind` is 'IDIOM' (emit `name = cover_label+offset`) or
    'MISFRAME' (no genuine overlap -- emit a flagged fallback and a warning).
    `cover_start` is the covering instruction's address (None when the label
    fell inside a data run). `offset` is `addr - cover_start`."""
    kind: str
    cover_start: int
    offset: int
    reason: str


def overlap_expr(cover_label, offset):
    """Operand text for a mid-instruction reference: a bare label when the
    target IS the instruction start, else ``LABEL+offset``."""
    return cover_label if offset == 0 else f"{cover_label}+{offset}"


def classify_overlap(mem, addr, *, byte_to_start, code_set, decode_size, cpu):
    """Decide whether an unplaceable in-range label at `addr` is a genuine
    mid-instruction reference (IDIOM) or a classification artifact (MISFRAME).

    Args:
        mem:          full memory image.
        addr:         the label address that could not be placed inline.
        byte_to_start: dict mapping every interior code byte to the start of
                      the instruction (as the body emits it) that covers it.
        code_set:     the walker's confirmed-code address set.
        decode_size:  callable(a) -> size in bytes of the instruction at `a`.
        cpu:          'z80' or '6502' (selects the idiom registry).

    Returns an OverlapResult. IDIOM is byte-identical to emit as
    ``cover_label+offset``; MISFRAME signals a data/ORG problem upstream.
    """
    cover = byte_to_start.get(addr)
    if cover is None:
        return OverlapResult(
            "MISFRAME", None, 0,
            "no covering instruction (label falls inside a data run)")
    offset = addr - cover
    size = decode_size(cover)
    if not (cover < addr < cover + size):
        return OverlapResult(
            "MISFRAME", cover, offset,
            f"label not strictly interior to the instruction at ${cover:04X}")
    op = mem[cover]
    idiom_offsets = _IDIOM_COVERS.get(cpu, {}).get(op)
    if idiom_offsets is not None and offset in idiom_offsets:
        return OverlapResult(
            "IDIOM", cover, offset,
            f"{cpu} skip idiom: enters the operand of ${op:02X} at ${cover:04X}")
    if addr in code_set:
        return OverlapResult(
            "IDIOM", cover, offset,
            f"shared instruction tail: ${addr:04X} is reachable code "
            f"inside the instruction at ${cover:04X}")
    return OverlapResult(
        "MISFRAME", cover, offset,
        f"interior of non-idiom instruction ${op:02X} at ${cover:04X} and "
        f"${addr:04X} is not reached as code (likely data decoded as code)")


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


# Minimum printable run length to treat a *terminator-less* byte run as text.
# Terminated strings need only 4 chars (the terminator is strong evidence);
# an un-terminated run is weaker, so require a slightly longer run to avoid
# tagging an incidental 4-byte printable patch (e.g. a table cell) as a string.
MIN_UNTERMINATED_STRING = 5


def _string_length(mem, addr, end):
    """Length (including terminator) of a string starting at addr, or 0
    if no such string. Requires at least 4 printable chars + a terminator."""
    n = 0
    while addr + n < end and is_printable_byte(mem[addr + n]):
        n += 1
    if n >= 4 and addr + n < end and is_string_terminator(mem[addr + n]):
        return n + 1
    return 0


def _word_char(b7):
    """A 7-bit byte that reads as text: letter, digit, or space."""
    return (0x41 <= (b7 & 0xDF) <= 0x5A) or 0x30 <= b7 <= 0x39 or b7 == 0x20


def _unterminated_string_length(mem, addr, end):
    """Length of a printable run starting at addr with no trailing terminator,
    or 0 if it is too short or does not read as text.

    A high-bit-clean printable byte ($20-$7E or, for the Apple 6502 high-bit
    convention, $A0-$FE) run only counts as text when most of it (masked to
    7 bits) is letters/digits/spaces -- otherwise it is binary that merely lies
    in the printable byte range (e.g. a packed table whose bytes happen to be
    $A0-$FE). The caller additionally requires the run to be *referenced by
    code* (a label), which is the real signal that an un-terminated run is a
    string the program addresses: a CP/M command name or message stored without
    a $00/$24 terminator. Together those two gates keep binary out."""
    n = 0
    while addr + n < end and is_printable_byte(mem[addr + n]):
        n += 1
    if n < MIN_UNTERMINATED_STRING:
        return 0
    word = sum(1 for i in range(n) if _word_char(mem[addr + i] & 0x7F))
    if word < 0.70 * n:
        return 0
    return n


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
    """Length of a generic byte run. Stops at the first label boundary (so the
    label gets emitted on its own line), at the start of a structure that begins
    inside the run (a fill block or a terminated string -- so a $00-terminated
    message embedded after a few non-printable bytes is not swallowed into the
    hex blob), and caps at 16 bytes for readable column-aligned output."""
    n = 1  # always consume at least the first byte
    while addr + n < end and n < 16:
        if labels is not None and (addr + n) in labels:
            break
        if _fill_length(mem, addr + n, end) >= 8:
            break
        if _string_length(mem, addr + n, end):     # a terminated string starts here
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

    # Un-terminated string: a printable, texty run the structured detectors
    # declined, that ALSO starts at a code-referenced address (a label). The
    # reference is the boundary/length signal -- the code does `LD HL,msg` /
    # `LDA #<msg`, so `addr` is where a distinct string begins even though it
    # abuts its neighbour with no terminator. Requiring the label keeps
    # incidental printable-range binary (unreferenced) out of the string class.
    if labels is not None and labels.get(addr):
        us_n = _unterminated_string_length(mem, addr, end)
        if us_n:
            return DataRun(addr, bytes(mem[addr:addr + us_n]), DataKind.STRING,
                           {"chars": bytes(mem[addr:addr + us_n]), "terminator": None})

    # Default: mixed bytes up to label or 16-byte limit
    mixed_n = _mixed_length(mem, addr, end, labels)
    return DataRun(addr, bytes(mem[addr:addr + mixed_n]), DataKind.MIXED)


# ── Range classifier ──────────────────────────────────────────────────
def classify_data(mem, start, end, *, code_set, labels=None, symbols=None,
                  cpu="z80", body_start=None, body_end=None, pointer_words=None):
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
        # Sub-classify within [addr, non_code_end). Cap each run at the next
        # interior label so a labelled address always begins a run (and thus
        # gets an emitted `LABEL:` line); otherwise an operand pointing into a
        # data run would reference an undefined symbol. No-op when no data-run
        # interior labels exist (the default path only labels code targets).
        sub = addr
        while sub < non_code_end:
            # A resolved static pointer / dispatch entry emits as a 2-byte
            # `DEFW <label>` so it relocates with ORG.
            if (pointer_words and sub in pointer_words and sub + 2 <= non_code_end
                    and not (labels and labels.get(sub + 1) is not None)):
                # ...but only if the pointer's high byte isn't itself a referenced
                # label -- else the 2-byte DEFW would swallow that label's
                # definition. (When it is, fall through: the run caps at sub+1 and
                # the label gets its own line; this lone pointer stays DEFB.)
                w = mem[sub] | (mem[sub + 1] << 8)
                runs.append(DataRun(sub, bytes(mem[sub:sub + 2]),
                                    DataKind.POINTER_TABLE, {"targets": [w]}))
                sub += 2
                continue
            cap = non_code_end
            if labels:
                nxt = [a for a in labels if sub < a < non_code_end and labels[a] is not None]
                if nxt:
                    cap = min(cap, min(nxt))
            if pointer_words:
                pw = [a for a in pointer_words if sub < a < cap]
                if pw:
                    cap = min(cap, min(pw))     # stop the run at the next pointer word
            run = classify_at(mem, sub, cap, labels=labels,
                              symbols=symbols, cpu=cpu,
                              body_start=body_start, body_end=body_end)
            runs.append(run)
            sub = run.end
        addr = non_code_end
    return runs
