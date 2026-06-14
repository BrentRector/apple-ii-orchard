"""Walker behavior tests."""

from disasm_z80.walker import Walker
from disasm_z80.symbols import SymbolTable


def _mem(*bytes_at_org):
    m = bytearray(0x10000)
    for org, data in bytes_at_org:
        m[org:org + len(data)] = data
    return m


def test_simple_linear_trace():
    # LD A,$05 ; LD ($0200),A ; RET   at $0100
    m = _mem((0x0100, b"\x3E\x05\x32\x00\x02\xC9"))
    w = Walker(m, start=0x0100, end=0x0106)
    w.trace(0x0100)
    assert w.code == {0x0100, 0x0101, 0x0102, 0x0103, 0x0104, 0x0105}


def test_call_creates_sub_label():
    # CALL $0110 ; RET   at $0100   ;  RET at $0110
    m = _mem(
        (0x0100, b"\xCD\x10\x01\xC9"),
        (0x0110, b"\xC9"),
    )
    w = Walker(m, start=0x0100, end=0x0111)
    w.trace(0x0100)
    w.name_labels()
    assert 0x0110 in w.labels
    assert w.labels[0x0110] == "SUB_0110"


def test_jr_creates_l_label():
    # JR NZ,$+1 ; RET ; RET
    m = _mem((0x0100, b"\x20\x01\xC9\xC9"))
    w = Walker(m, start=0x0100, end=0x0104)
    w.trace(0x0100)
    w.name_labels()
    assert 0x0103 in w.labels
    assert w.labels[0x0103] == "L_0103"


def test_unconditional_jr_stops_fall_through():
    # JR $+1 ; <unreachable byte> ; RET
    m = _mem((0x0100, b"\x18\x01\xEA\xC9"))
    w = Walker(m, start=0x0100, end=0x0104)
    w.trace(0x0100)
    # The JR is code; $0103 is reached; $0102 is NOT reached
    assert 0x0100 in w.code
    assert 0x0101 in w.code
    assert 0x0102 not in w.code
    assert 0x0103 in w.code


def test_indirect_jp_stops_trace():
    # JP (HL) ; <unreachable byte>
    m = _mem((0x0100, b"\xE9\xEA"))
    w = Walker(m, start=0x0100, end=0x0102)
    w.trace(0x0100)
    assert 0x0100 in w.code
    assert 0x0101 not in w.code


def test_rst_target_recursed():
    # RST 8 (CALL $0008) at $0100 ; RET at $0008
    m = _mem(
        (0x0008, b"\xC9"),
        (0x0100, b"\xCF\xC9"),
    )
    w = Walker(m, start=0x0000, end=0x0102)
    w.trace(0x0100)
    assert 0x0008 in w.code  # RST 8 target reached


def test_data_region_stops_trace():
    # NOP NOP <data> RET
    m = _mem((0x0100, b"\x00\x00\xC9"))
    w = Walker(m, start=0x0100, end=0x0103)
    w.add_data_region(0x0102, 0x0103)
    w.trace(0x0100)
    assert 0x0100 in w.code
    assert 0x0101 in w.code
    assert 0x0102 not in w.code  # in data region


def test_symbol_overrides_default_naming():
    m = _mem((0x0100, b"\xCD\x05\x00\xC9"))  # CALL $0005 ; RET
    syms = SymbolTable()
    syms.add(0x0005, "BDOS_VEC", "BDOS call vector")
    w = Walker(m, start=0x0100, end=0x0104)
    w.trace(0x0100)
    w.add_label(0x0005)
    w.name_labels(symbols=syms)
    assert w.labels[0x0005] == "BDOS_VEC"
