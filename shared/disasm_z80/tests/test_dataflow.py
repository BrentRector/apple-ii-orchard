# -*- coding: utf-8 -*-
"""Static data-flow resolution of computed Z-80 dispatch tables."""
from disasm_z80.walker import Walker
from disasm_z80.dataflow import (
    scan_static_dispatch, resolve_dispatch_at, reg_effect, step_state, RegState, VKind,
)
from disasm_z80.opcodes import decode_at

ORG = 0x1000


def _mem(code_at_1000):
    m = bytearray(0x10000)
    m[0x1000:0x1000 + len(code_at_1000)] = code_at_1000
    return m


# the canonical indexed pointer-table dispatch idiom + a 4-entry table
IDIOM = bytes([
    0x21, 0x10, 0x10,   # $1000 LD HL,$1010
    0x19,               # $1003 ADD HL,DE
    0x19,               # $1004 ADD HL,DE
    0x7E,               # $1005 LD A,(HL)
    0x23,               # $1006 INC HL
    0x66,               # $1007 LD H,(HL)
    0x6F,               # $1008 LD L,A
    0xE9,               # $1009 JP (HL)
])


def _with_table(extra_pad=b"\x00\x00"):
    m = _mem(IDIOM)
    # table at $1010: four LE pointers to RET stubs, then an out-of-range word
    entries = [0x1020, 0x1023, 0x1026, 0x1029]
    a = 0x1010
    for e in entries:
        m[a] = e & 0xFF
        m[a + 1] = e >> 8
        a += 2
    m[a:a + len(extra_pad)] = extra_pad      # $1018 = $0000 -> bounds the table at 4
    for e in entries:                        # RET stubs so the targets decode
        m[e] = 0xC9
    return m, entries


def test_reg_effect_idiom_opcodes():
    cases = {
        bytes([0x21, 0x10, 0x10]): ("ld_pair_imm", "HL", 0x1010),
        bytes([0x19]): ("add", "HL", "DE"),
        bytes([0x7E]): ("ld_r_hl", "A"),
        bytes([0x23]): ("inc_pair", "HL"),
        bytes([0x66]): ("ld_r_hl", "H"),
        bytes([0x6F]): ("ld_r_r", "L", "A"),
        bytes([0xEB]): ("ex_de_hl",),
        bytes([0xE9]): ("jp_indirect", "HL"),
    }
    for raw, expect in cases.items():
        m = _mem(raw)
        assert reg_effect(decode_at(m, 0x1000)) == expect


def test_resolve_ccp_pointer_table():
    m, entries = _with_table()
    w = Walker(m, start=ORG, end=0x1100)
    w.trace(ORG)
    t = resolve_dispatch_at(m, w, 0x1009, body_start=ORG, body_end=0x1100)
    assert t is not None
    assert t.kind == "pointer"
    assert t.table_addr == 0x1010
    assert t.entry_targets == tuple(entries)
    assert t.n_entries == 4


def test_extent_cap_no_overrun():
    # an in-range (but wrong) word right after the table must not over-read:
    # put $1029 (still in range) at $1018, but $101A out of range bounds it at 5.
    m, entries = _with_table(extra_pad=bytes([0x29, 0x10, 0x00, 0x00]))
    w = Walker(m, start=ORG, end=0x1100); w.trace(ORG)
    t = resolve_dispatch_at(m, w, 0x1009, body_start=ORG, body_end=0x1100)
    assert t is not None and t.n_entries == 5      # exactly the in-range run, no further


def test_reject_single_vector_indirect():
    # LD HL,$1010 ; JP (HL)  -- a plain constant, no deref chain, $1010 not a C3 run
    m = _mem(bytes([0x21, 0x10, 0x10, 0xE9]))
    m[0x1010] = 0x00                                  # not a JP slot
    w = Walker(m, start=ORG, end=0x1100); w.trace(ORG)
    assert resolve_dispatch_at(m, w, 0x1003, body_start=ORG, body_end=0x1100) is None


def test_reject_bare_jp_hl():
    # JP (HL) with HL unknown (mirrors test_indirect_jp_stops_trace)
    m = _mem(bytes([0x00, 0xE9]))                     # NOP ; JP (HL)
    w = Walker(m, start=ORG, end=0x1100); w.trace(ORG)
    assert resolve_dispatch_at(m, w, 0x1001, body_start=ORG, body_end=0x1100) is None


def test_scan_finds_only_real_table():
    m, _ = _with_table()
    w = Walker(m, start=ORG, end=0x1100); w.trace(ORG)
    tables = scan_static_dispatch(m, w, body_start=ORG, body_end=0x1100)
    assert len(tables) == 1 and tables[0].table_addr == 0x1010
