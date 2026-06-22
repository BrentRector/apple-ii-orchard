"""Tests for cpm_pipeline.basic.recover -- recovering code mis-rendered as data."""
from cpm_pipeline.basic.recover import recover_code
from disasm_z80.walker import Walker


def _walk(data, org=0x0100):
    m = bytearray(0x10000)
    m[org:org + len(data)] = data
    w = Walker(m, org, org + len(data))
    return m, w


def test_recovers_after_terminal_code():
    # LD A,1 ; RET   then a routine reached only after the terminal: INC A ; INC A ; RET
    m, w = _walk(b"\x3E\x01\xC9\x3C\x3C\xC9")
    w.trace(0x0100)
    assert 0x0103 not in w.code          # the post-terminal routine is missed
    recover_code(w, m, 0x0100, 0x0106)
    assert 0x0103 in w.code and 0x0105 in w.code   # recovered


def test_rejects_out_of_range_target_data():
    # LD A,1 ; RET   then an FP-constant-like blob: CALL $CCCC (target out of image)
    m, w = _walk(b"\x3E\x01\xC9\xCD\xCC\xCC")
    w.trace(0x0100)
    recover_code(w, m, 0x0100, 0x0106)
    assert 0x0103 not in w.code          # left as data (bogus out-of-range call)


def test_respects_inline_byte_operands():
    # CALL $0110 (an inline-byte routine) ; <inline $28> ; DEC HL ; RET ; ($0110: RET)
    m, w = _walk(b"\xCD\x10\x01\x28\x2B\xC9", org=0x0100)
    m[0x0110] = 0xC9
    w.end = 0x0111
    w.inline_byte_calls = {0x0110: 1}
    w.trace(0x0100)
    assert w.inline_data.get(0x0103) is True
    recover_code(w, m, 0x0100, 0x0111)
    assert 0x0103 not in w.code          # the inline byte stays data, no phantom decode
