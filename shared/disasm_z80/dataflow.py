# -*- coding: utf-8 -*-
"""Static register data-flow resolution of computed Z-80 dispatch tables.

The walker stops at indirect ``JP (HL)`` (it cannot statically know the target),
so jump/pointer tables reached by a computed jump are never traced and their
entries never get labels -- which makes ``analyzer._pointer_table_length`` reject
the run and emit raw, non-relocatable ``DEFB``.

This module recovers, by a small abstract interpretation over straight-line code,
the *base* and *extent* of the table feeding such a dispatch, so the caller can
plant entry labels + a data region and let the EXISTING table detector and
``_render_pointer_table`` emit relocatable ``DEFW <label>``.

It is intentionally conservative: it resolves only the recognised pointer-table
and jump-table idioms and returns ``None`` for anything else (a bare ``JP (HL)``,
a single-vector indirect, an unknown HL), preserving the walker's stop-at-indirect
behaviour for everything it does not prove.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field, replace
from enum import Enum

from .opcodes import decode_at, ControlFlow

MAX_DF_WINDOW = 48          # instructions scanned backward from a JP (HL)
MAX_TABLE_ENTRIES = 256


class VKind(Enum):
    UNKNOWN = 0             # no information (top)
    CONST = 1              # a known 16-bit constant
    BASE_IDX = 2          # base_const + (unknown index): a table cursor
    MEM_PTR = 3           # a little-endian word read out of a BASE_IDX table


@dataclass(frozen=True)
class AbsVal:
    kind: VKind = VKind.UNKNOWN
    const: int | None = None      # CONST value / BASE_IDX or MEM_PTR base
    derefed: bool = False         # MEM_PTR: low+high both read from the table word

    @staticmethod
    def unknown():
        return AbsVal(VKind.UNKNOWN)


U = AbsVal.unknown()


@dataclass
class RegState:
    hl: AbsVal = field(default_factory=AbsVal.unknown)
    de: AbsVal = field(default_factory=AbsVal.unknown)
    bc: AbsVal = field(default_factory=AbsVal.unknown)
    a:  AbsVal = field(default_factory=AbsVal.unknown)
    ix: AbsVal = field(default_factory=AbsVal.unknown)
    iy: AbsVal = field(default_factory=AbsVal.unknown)

    def copy(self):
        return replace(self)


@dataclass(frozen=True)
class DispatchTable:
    jp_addr: int
    table_addr: int
    kind: str                      # 'pointer' | 'jump'
    entry_targets: tuple
    n_entries: int

    @property
    def n_bytes(self):
        return self.n_entries * (2 if self.kind == "pointer" else 3)


# ── instruction -> register effect (parsed from the formatted mnemonic) ──────
_PAIRS = ("HL", "DE", "BC", "IX", "IY")
_RE_LD_PAIR_IMM = re.compile(r"^LD (HL|DE|BC|SP|IX|IY),\$([0-9A-Fa-f]{1,4})$")
_RE_LD_PAIR_MEM = re.compile(r"^LD (HL|DE|BC|IX|IY),\(\$([0-9A-Fa-f]{1,4})\)$")
_RE_ADD_HL = re.compile(r"^ADD (HL|IX|IY),(HL|DE|BC|SP|IX|IY)$")
_RE_LD_R_R = re.compile(r"^LD ([ABCDEHL]),([ABCDEHL])$")
_RE_LD_R_HL = re.compile(r"^LD ([ABCDEHL]),\(HL\)$")
_RE_INCDEC = re.compile(r"^(INC|DEC) (HL|DE|BC|IX|IY)$")


def reg_effect(instr):
    """Return a small (op, *args) effect descriptor for the data-flow stepper,
    derived from the formatted mnemonic. Anything not modelled is ('other',)."""
    m = instr.mnemonic.strip()
    g = _RE_LD_PAIR_IMM.match(m)
    if g:
        return ("ld_pair_imm", g.group(1), int(g.group(2), 16))
    g = _RE_LD_PAIR_MEM.match(m)
    if g:
        return ("ld_pair_mem", g.group(1), int(g.group(2), 16))
    g = _RE_ADD_HL.match(m)
    if g:
        return ("add", g.group(1), g.group(2))
    g = _RE_LD_R_HL.match(m)
    if g:
        return ("ld_r_hl", g.group(1))
    g = _RE_LD_R_R.match(m)
    if g:
        return ("ld_r_r", g.group(1), g.group(2))
    g = _RE_INCDEC.match(m)
    if g:
        return (("inc_pair" if g.group(1) == "INC" else "dec_pair"), g.group(2))
    if m == "EX DE,HL":
        return ("ex_de_hl",)
    if m in ("JP (HL)", "JP (IX)", "JP (IY)"):
        return ("jp_indirect", m[4:6])
    return ("other",)


def _get(state, pair):
    return getattr(state, pair.lower(), U)


def _set(state, pair, val):
    setattr(state, pair.lower(), val)


def step_state(state: RegState, instr) -> RegState:
    """Apply one instruction to the abstract register file. Returns a new state.
    Unmodelled writes drop the affected pair(s) to UNKNOWN (conservative)."""
    s = state.copy()
    eff = reg_effect(instr)
    op = eff[0]

    if op == "ld_pair_imm":
        pair, val = eff[1], eff[2]
        if pair != "SP":
            _set(s, pair, AbsVal(VKind.CONST, val))
        return s

    if op == "ld_pair_mem":
        # LD HL,(nn): a single pointer fetched from a fixed address -- not a
        # table cursor. Treat as UNKNOWN for table purposes.
        _set(s, eff[1], U)
        return s

    if op == "add":
        dst, src = eff[1], eff[2]
        d = _get(s, dst)
        # CONST + index  ->  table cursor at the const base.
        if d.kind == VKind.CONST:
            _set(s, dst, AbsVal(VKind.BASE_IDX, d.const))
        elif d.kind == VKind.BASE_IDX:
            pass  # still a cursor at the same base
        else:
            _set(s, dst, U)
        return s

    if op == "ld_r_hl":              # LD r,(HL)
        r = eff[1]
        if r == "A":
            # read-into-HL idiom: LD A,(HL) takes the table word's low byte
            if s.hl.kind == VKind.BASE_IDX:
                s.a = AbsVal(VKind.MEM_PTR, s.hl.const)
            else:
                s.a = U
        elif r == "H":
            # ...then LD H,(HL) takes the high byte -> HL is the table word
            if s.hl.kind == VKind.BASE_IDX and s.a.kind == VKind.MEM_PTR \
                    and s.a.const == s.hl.const:
                s.hl = AbsVal(VKind.MEM_PTR, s.hl.const)
            else:
                s.hl = U
        elif r == "E":
            # read-into-DE idiom (CP/M 2.2 BDOS): LD E,(HL) low byte into E
            if s.hl.kind == VKind.BASE_IDX:
                s.de = AbsVal(VKind.MEM_PTR, s.hl.const)
            else:
                s.de = U
        elif r == "D":
            # ...then LD D,(HL) high byte -> DE is the table word; an EX DE,HL
            # next moves it into HL for the JP (HL).
            if s.hl.kind == VKind.BASE_IDX and s.de.kind == VKind.MEM_PTR \
                    and s.de.const == s.hl.const:
                s.de = AbsVal(VKind.MEM_PTR, s.hl.const, derefed=True)
            else:
                s.de = U
        else:
            _clobber_half(s, r)
        return s

    if op == "ld_r_r":               # LD dst,src  (8-bit)
        dst, src = eff[1], eff[2]
        if dst == "L" and src == "A" and s.a.kind == VKind.MEM_PTR \
                and s.hl.kind == VKind.MEM_PTR and s.a.const == s.hl.const:
            s.hl = AbsVal(VKind.MEM_PTR, s.hl.const, derefed=True)   # both halves
        else:
            _clobber_half(s, dst)
        return s

    if op in ("inc_pair", "dec_pair"):
        pair = eff[1]
        v = _get(s, pair)
        # keep a BASE_IDX cursor a cursor across the INC HL of the deref chain
        if v.kind == VKind.BASE_IDX:
            pass
        elif v.kind == VKind.CONST and op == "inc_pair":
            _set(s, pair, AbsVal(VKind.CONST, (v.const + 1) & 0xFFFF))
        elif v.kind == VKind.CONST and op == "dec_pair":
            _set(s, pair, AbsVal(VKind.CONST, (v.const - 1) & 0xFFFF))
        else:
            _set(s, pair, U)
        return s

    if op == "ex_de_hl":
        s.hl, s.de = s.de, s.hl
        return s

    if op in ("jp_indirect", "other"):
        return s

    return s


def _clobber_half(s, r):
    """An 8-bit write to B/C/D/E/H/L drops the containing 16-bit pair to UNKNOWN
    (we don't model 8-bit halves precisely; A is tracked explicitly)."""
    if r in ("H", "L"):
        s.hl = U
    elif r in ("D", "E"):
        s.de = U
    elif r in ("B", "C"):
        s.bc = U
    elif r == "A":
        s.a = U


# ── dispatch resolution ─────────────────────────────────────────────────────
def _instr_starts(mem, walker, body_start, body_end):
    """Instruction-start addresses across the traced code, in order. Built by
    forward decoding (unambiguous), so mid-instruction bytes are never mistaken
    for starts."""
    starts = []
    a = body_start
    while a < body_end:
        if a in walker.code:
            starts.append(a)
            try:
                a += decode_at(mem, a).size
            except (IndexError, KeyError):
                a += 1
        else:
            a += 1
    return starts


def resolve_dispatch_at(mem, walker, jp_addr, *, body_start, body_end, starts=None):
    """Resolve the dispatch table feeding the JP (HL)/(IX)/(IY) at jp_addr.
    Returns a DispatchTable or None."""
    try:
        jp = decode_at(mem, jp_addr)
    except (IndexError, KeyError):
        return None
    if jp.control_flow != ControlFlow.INDIRECT:
        return None

    if starts is None:
        starts = _instr_starts(mem, walker, body_start, body_end)
    if jp_addr not in starts:
        return None
    idx = starts.index(jp_addr)
    # walk back to the nearest preceding labelled start (block/join boundary),
    # or the window limit -- and step forward from there with a fresh state.
    lo_idx = idx
    for k in range(idx - 1, max(-1, idx - MAX_DF_WINDOW) - 1, -1):
        lo_idx = k
        if walker.labels.get(starts[k]) is not None:
            break

    block = []
    for k in range(lo_idx, idx):
        try:
            block.append(decode_at(mem, starts[k]))
        except (IndexError, KeyError):
            return None
    state = RegState()
    for ins in block:
        state = step_state(state, ins)

    # function-count guard: `CP $n` immediately followed by `RET NC` bounds the
    # table at exactly n entries (valid codes 0..n-1). This is how a CP/M-style
    # dispatcher caps its table, and it survives entries that point OUT of the
    # module (e.g. BDOS fn 0/4/5 -> BIOS $FAxx), which the plausibility walk can't.
    guard = None
    for i in range(len(block) - 1):
        m = re.match(r"^CP \$([0-9A-Fa-f]{1,2})$", block[i].mnemonic.strip())
        if m and block[i + 1].mnemonic.strip() == "RET NC":
            guard = int(m.group(1), 16)

    reg = jp.mnemonic[4:6]            # HL / IX / IY
    cur = _get(state, reg)

    # pointer-table form: cursor dereferenced into a word, base in range
    if cur.kind == VKind.MEM_PTR and cur.const is not None \
            and body_start <= cur.const < body_end:
        base = cur.const
        if guard is not None and 4 <= guard <= MAX_TABLE_ENTRIES:
            targets = _read_n_pointers(mem, base, guard, body_end)
        else:
            targets = _walk_pointer_extent(mem, walker, base, body_start, body_end)
        if len(targets) >= 4:
            return DispatchTable(jp_addr, base, "pointer", tuple(targets), len(targets))
        return None

    # jump-table form: HL holds a const pointing at a run of C3 (JP) slots
    if cur.kind == VKind.CONST and cur.const is not None \
            and body_start <= cur.const < body_end and mem[cur.const] == 0xC3:
        base = cur.const
        targets = _walk_jump_extent(mem, walker, base, body_start, body_end)
        if len(targets) >= 3:
            return DispatchTable(jp_addr, base, "jump", tuple(targets), len(targets))
        return None

    return None


def _read_n_pointers(mem, base, n, body_end):
    """Read exactly n little-endian word entries from base (used when a function-
    count guard fixes the table size). Entries may point outside the module (e.g.
    BIOS routes); they are kept verbatim and rendered as DEFW <label-or-literal>."""
    out = []
    a = base
    for _ in range(n):
        if a + 1 >= body_end:
            break
        out.append(mem[a] | (mem[a + 1] << 8))
        a += 2
    return out


def _walk_pointer_extent(mem, walker, base, body_start, body_end):
    """LE-word entries from base while each resolves to an in-range, decodable
    address; stop at a label boundary (table end) or invalid entry. Capped."""
    targets = []
    a = base
    while len(targets) < MAX_TABLE_ENTRIES:
        if a != base and walker.labels.get(a) is not None:
            break                      # next item already a known boundary
        if a + 1 >= body_end:
            break
        w = mem[a] | (mem[a + 1] << 8)
        if not (body_start <= w < body_end):
            break
        try:
            decode_at(mem, w)
        except (IndexError, KeyError):
            break
        targets.append(w)
        a += 2
    return targets


def _walk_jump_extent(mem, walker, base, body_start, body_end):
    targets = []
    a = base
    while len(targets) < MAX_TABLE_ENTRIES:
        if a + 2 >= body_end or mem[a] != 0xC3:
            break
        if a != base and walker.labels.get(a) is not None:
            break
        w = mem[a + 1] | (mem[a + 2] << 8)
        if not (body_start <= w < body_end):
            break
        targets.append(w)
        a += 3
    return targets


def scan_static_dispatch(mem, walker, *, body_start, body_end):
    """Find and resolve every computed-dispatch table in the traced code."""
    out = []
    starts = _instr_starts(mem, walker, body_start, body_end)
    for addr in starts:
        try:
            ins = decode_at(mem, addr)
        except (IndexError, KeyError):
            continue
        if ins.control_flow != ControlFlow.INDIRECT:
            continue
        t = resolve_dispatch_at(mem, walker, addr, body_start=body_start,
                                body_end=body_end, starts=starts)
        if t is not None:
            out.append(t)
    return out
