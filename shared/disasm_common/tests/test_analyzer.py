"""Tests for the data-classification pass."""

from disasm_common.analyzer import (
    DataKind, classify_data, classify_at,
    is_printable_byte, is_string_terminator,
)


def _mem_with(data, at=0):
    m = bytearray(0x10000)
    m[at:at + len(data)] = data
    return m


# ── Predicates ─────────────────────────────────────────────────────────
def test_is_printable_byte():
    assert is_printable_byte(0x41)   # 'A'
    assert is_printable_byte(0x20)   # ' '
    assert is_printable_byte(0x7E)   # '~'
    assert is_printable_byte(0xC1)   # Apple high-bit 'A'
    assert is_printable_byte(0xA0)   # Apple high-bit ' '
    assert not is_printable_byte(0x00)
    assert not is_printable_byte(0x1F)
    assert not is_printable_byte(0x7F)
    assert not is_printable_byte(0x9F)
    assert not is_printable_byte(0xFF)


def test_is_string_terminator():
    assert is_string_terminator(0x00)
    assert is_string_terminator(0x0D)   # CR
    assert is_string_terminator(0x8D)   # Apple CR
    assert is_string_terminator(0x24)   # CP/M BDOS '$'
    assert is_string_terminator(0x80)   # Apple end marker
    assert not is_string_terminator(0x20)
    assert not is_string_terminator(0xFF)


# ── Fill detection ─────────────────────────────────────────────────────
def test_fill_detection():
    # 16 bytes of $00 starting at $0100
    m = _mem_with(b"\x00" * 16, at=0x0100)
    runs = classify_data(m, 0x0100, 0x0110, code_set=set())
    assert len(runs) == 1
    assert runs[0].kind == DataKind.FILL
    assert runs[0].metadata["value"] == 0x00
    assert len(runs[0]) == 16


def test_short_fill_below_threshold():
    # Only 7 bytes of $FF -- below the 8-byte fill threshold; should be MIXED
    m = _mem_with(b"\xFF" * 7, at=0x0100)
    runs = classify_data(m, 0x0100, 0x0107, code_set=set())
    assert len(runs) == 1
    assert runs[0].kind == DataKind.MIXED


# ── String detection ───────────────────────────────────────────────────
def test_ascii_string_with_null_terminator():
    data = b"HELLO\x00"
    m = _mem_with(data, at=0x0100)
    runs = classify_data(m, 0x0100, 0x0106, code_set=set())
    assert len(runs) == 1
    assert runs[0].kind == DataKind.STRING
    assert runs[0].metadata["chars"] == b"HELLO"
    assert runs[0].metadata["terminator"] == 0x00


def test_apple_high_bit_string_with_cr_terminator():
    # "HI" in high-bit ASCII + Apple CR ($8D)
    data = b"\xC8\xC9\xC2\xC1\x8D"   # "HIBA" with $8D terminator
    m = _mem_with(data, at=0x0100)
    runs = classify_data(m, 0x0100, 0x0105, code_set=set())
    assert len(runs) == 1
    assert runs[0].kind == DataKind.STRING


def test_short_string_below_threshold():
    # Only 3 printable + terminator -- below 4-char minimum
    m = _mem_with(b"HI\x00", at=0x0100)
    runs = classify_data(m, 0x0100, 0x0103, code_set=set())
    assert len(runs) == 1
    assert runs[0].kind == DataKind.MIXED


def test_string_without_terminator_is_mixed():
    m = _mem_with(b"HELLO\xFF", at=0x0100)
    runs = classify_data(m, 0x0100, 0x0106, code_set=set())
    # Five printables but no terminator -- treated as MIXED
    assert runs[0].kind == DataKind.MIXED


# ── Pointer-table detection ────────────────────────────────────────────
def test_pointer_table_with_walker_labels():
    # 4 little-endian pointers all targeting walker-labeled addresses
    m = _mem_with(b"\x00\x10\x00\x20\x00\x30\x00\x40", at=0x0100)
    labels = {0x1000: "L1", 0x2000: "L2", 0x3000: "L3", 0x4000: "L4"}
    runs = classify_data(m, 0x0100, 0x0108,
                         code_set=set(), labels=labels)
    assert len(runs) == 1
    assert runs[0].kind == DataKind.POINTER_TABLE
    assert runs[0].metadata["targets"] == [0x1000, 0x2000, 0x3000, 0x4000]


def test_sequential_lookup_not_pointer_table():
    # Apple II screen-line offsets: 00 02 04 06 08 0A 0C 0E -- looks like
    # `.word $0200, $0604, $0A08, $0E0C` but is really a per-byte lookup.
    # No walker labels -> not a pointer table.
    m = _mem_with(b"\x00\x02\x04\x06\x08\x0A\x0C\x0E", at=0x0800)
    runs = classify_data(m, 0x0800, 0x0808, code_set=set())
    assert all(r.kind != DataKind.POINTER_TABLE for r in runs)


def test_symbol_table_alone_not_enough_for_pointer_table():
    """Symbol-table membership without a walker label is not enough -- the
    target $0200 might be Apple II's IN buffer but a sequential byte run
    happening to start with `00 02` shouldn't get classified as a pointer."""
    from disasm_common.analyzer import _is_likely_code_addr
    class FakeSymbols:
        def name_for(self, a): return "IN" if a == 0x0200 else None
    assert not _is_likely_code_addr(0x0200, labels={}, symbols=FakeSymbols(),
                                    body_start=0x0800, body_end=0x1000)


# ── Jump-table detection ───────────────────────────────────────────────
def test_z80_jump_table():
    # JP $1000 ; JP $2000 ; JP $3000  -- three C3 prefix triples
    m = _mem_with(b"\xC3\x00\x10\xC3\x00\x20\xC3\x00\x30", at=0x0100)
    runs = classify_data(m, 0x0100, 0x0109,
                         code_set=set(), cpu="z80",
                         body_start=0x0100, body_end=0x4000)
    assert len(runs) == 1
    assert runs[0].kind == DataKind.JUMP_TABLE
    assert runs[0].metadata["targets"] == [0x1000, 0x2000, 0x3000]
    assert runs[0].metadata["opcode"] == 0xC3


def test_6502_jump_table_with_jmp():
    # JMP $1000 ; JMP $2000 ; JMP $3000
    m = _mem_with(b"\x4C\x00\x10\x4C\x00\x20\x4C\x00\x30", at=0x0100)
    runs = classify_data(m, 0x0100, 0x0109,
                         code_set=set(), cpu="6502",
                         body_start=0x0100, body_end=0x4000)
    assert len(runs) == 1
    assert runs[0].kind == DataKind.JUMP_TABLE


# ── Code/data interleaving ─────────────────────────────────────────────
def test_skips_code_addresses():
    # 4 data bytes, then 4 code bytes (in code_set), then 4 more data
    m = _mem_with(b"\x00\x00\x00\x00\xAA\xBB\xCC\xDD\x11\x22\x33\x44",
                  at=0x0100)
    code = {0x0104, 0x0105, 0x0106, 0x0107}
    runs = classify_data(m, 0x0100, 0x010C, code_set=code)
    # Two non-code regions: $0100-$0103 and $0108-$010B
    assert len(runs) == 2
    assert runs[0].addr == 0x0100
    assert runs[0].end == 0x0104
    assert runs[1].addr == 0x0108
    assert runs[1].end == 0x010C


def test_label_breaks_mixed_run():
    # 16 bytes of mixed data, but with a label at offset 8 -- the run
    # should split there so the label can be placed inline
    m = _mem_with(b"\x01\x02\x03\x04\x05\x06\x07\x08"
                  b"\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10", at=0x0100)
    labels = {0x0108: "MID"}
    runs = classify_data(m, 0x0100, 0x0110,
                         code_set=set(), labels=labels)
    # Should have 2 runs split at $0108
    assert len(runs) == 2
    assert runs[0].addr == 0x0100
    assert runs[0].end == 0x0108
    assert runs[1].addr == 0x0108
