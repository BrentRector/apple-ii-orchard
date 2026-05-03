"""Walker behavior: tracing, label naming, data-region honoring."""

from disasm6502.walker import Walker
from disasm6502.symbols import SymbolTable


def _mem(*bytes_at_org):
    """Helper: build a 64K memory image from a list of (org, bytes) pairs."""
    m = bytearray(0x10000)
    for org, data in bytes_at_org:
        m[org:org + len(data)] = data
    return m


def test_simple_linear_trace():
    # LDA #$05 ; STA $0200 ; RTS  at $0100
    m = _mem((0x0100, b"\xA9\x05\x8D\x00\x02\x60"))
    w = Walker(m, start=0x0100, end=0x0106)
    w.trace(0x0100)
    assert w.code == {0x0100, 0x0101, 0x0102, 0x0103, 0x0104, 0x0105}
    # Only label is the entry point itself (auto-added so it appears in the output).
    assert set(w.labels.keys()) == {0x0100}


def test_jsr_creates_sub_label():
    # $0100: JSR $0110 ; RTS
    # $0110: RTS
    m = _mem(
        (0x0100, b"\x20\x10\x01\x60"),
        (0x0110, b"\x60"),
    )
    w = Walker(m, start=0x0100, end=0x0111)
    w.trace(0x0100)
    w.name_labels()
    assert 0x0110 in w.labels
    assert w.labels[0x0110] == "SUB_0110"


def test_branch_creates_l_label():
    # $0100: BNE $0103 ; RTS  (branch to $0104? actually +1 from $0102)
    # Encode BNE +0 → falls to next instr; let's do BNE +1 (skip the RTS):
    # $0100: D0 01     BNE $0103
    # $0102: 60        RTS
    # $0103: 60        RTS
    m = _mem((0x0100, b"\xD0\x01\x60\x60"))
    w = Walker(m, start=0x0100, end=0x0104)
    w.trace(0x0100)
    w.name_labels()
    assert 0x0103 in w.labels
    assert w.labels[0x0103] == "L_0103"


def test_data_region_stops_trace():
    # $0100: NOP ; NOP ; LDA $0200 ; ...  but $0102 declared as data
    m = _mem((0x0100, b"\xEA\xEA\xAD\x00\x02\x60"))
    w = Walker(m, start=0x0100, end=0x0106)
    w.add_data_region(0x0102, 0x0103)
    w.trace(0x0100)
    # Only $0100, $0101 should be code; $0102+ stops on data region
    assert 0x0100 in w.code
    assert 0x0101 in w.code
    assert 0x0102 not in w.code


def test_symbol_overrides_default_naming():
    m = _mem((0x0100, b"\x20\xED\xFD\x60"))  # JSR $FDED ; RTS
    syms = SymbolTable()
    syms.add(0xFDED, "COUT", "print char")
    w = Walker(m, start=0x0100, end=0x0104)
    w.trace(0x0100)
    w.name_labels(symbols=syms)
    # $FDED is outside the walker range -- it'll still be in labels because
    # the JSR target is recorded, but trace() short-circuits when target is
    # out of range. Add manually to demonstrate naming priority.
    w.add_label(0xFDED)
    w.name_labels(symbols=syms)
    assert w.labels[0xFDED] == "COUT"
