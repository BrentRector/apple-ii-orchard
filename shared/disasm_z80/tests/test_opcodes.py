"""Opcode-table sanity checks: every starting byte must decode without crashing."""

from disasm_z80.opcodes import decode_at, ControlFlow, BASE, CB, ED, DD, FD, DDCB, FDCB


def _mem_with(prefix_bytes):
    """Build a 16-byte memory image with `prefix_bytes` at the start, padded
    with zeros so any decoder can fetch up to 4 bytes safely."""
    m = bytearray(16)
    for i, b in enumerate(prefix_bytes):
        m[i] = b
    return m


def test_every_base_opcode_decodes():
    for op in range(256):
        if op in (0xCB, 0xDD, 0xED, 0xFD):
            continue  # prefix bytes; tested via prefix tables
        m = _mem_with([op])
        instr = decode_at(m, 0)
        assert instr.size in (1, 2, 3), f"opcode ${op:02X}: bad size {instr.size}"
        assert instr.mnemonic, f"opcode ${op:02X}: empty mnemonic"


def test_every_cb_opcode_decodes():
    for op in range(256):
        m = _mem_with([0xCB, op])
        instr = decode_at(m, 0)
        assert instr.size == 2
        assert instr.mnemonic


def test_every_ed_opcode_decodes():
    for op in range(256):
        m = _mem_with([0xED, op])
        instr = decode_at(m, 0)
        assert instr.size in (2, 4)
        assert instr.mnemonic


def test_every_dd_opcode_decodes():
    for op in range(256):
        if op == 0xCB:
            continue  # DDCB is the compound prefix
        m = _mem_with([0xDD, op])
        instr = decode_at(m, 0)
        assert instr.size in (1, 2, 3, 4)
        assert instr.mnemonic


def test_every_fd_opcode_decodes():
    for op in range(256):
        if op == 0xCB:
            continue
        m = _mem_with([0xFD, op])
        instr = decode_at(m, 0)
        assert instr.size in (1, 2, 3, 4)
        assert instr.mnemonic


def test_every_ddcb_opcode_decodes():
    for op in range(256):
        m = _mem_with([0xDD, 0xCB, 0x05, op])  # displacement +5
        instr = decode_at(m, 0)
        assert instr.size == 4
        assert instr.mnemonic


def test_every_fdcb_opcode_decodes():
    for op in range(256):
        m = _mem_with([0xFD, 0xCB, 0xFB, op])  # displacement -5
        instr = decode_at(m, 0)
        assert instr.size == 4
        assert instr.mnemonic


def test_anchor_opcodes():
    """Spot-check well-known opcodes."""
    m = _mem_with([0x00])  # NOP
    assert decode_at(m, 0).mnemonic == 'NOP'
    m = _mem_with([0xC9])  # RET
    instr = decode_at(m, 0)
    assert instr.mnemonic == 'RET'
    assert instr.control_flow == ControlFlow.RET
    m = _mem_with([0xCD, 0x34, 0x12])  # CALL $1234
    instr = decode_at(m, 0)
    assert instr.mnemonic == 'CALL $1234'
    assert instr.target == 0x1234
    m = _mem_with([0x76])  # HALT
    instr = decode_at(m, 0)
    assert instr.mnemonic == 'HALT'
    assert instr.control_flow == ControlFlow.HALT


def test_relative_branch_targets():
    """JR $+5 from $0000 should target $0007 (PC after JR is $0002, +5 = $0007)."""
    m = _mem_with([0x18, 0x05])  # JR +5
    instr = decode_at(m, 0)
    assert instr.target == 0x0007
    assert instr.mnemonic == 'JR $0007'


def test_negative_relative_branch():
    """JR $-2 from $0010 should target $0010 (infinite loop)."""
    m = bytearray(32)
    m[0x10] = 0x18
    m[0x11] = 0xFE  # -2 signed
    instr = decode_at(m, 0x10)
    assert instr.target == 0x0010


def test_ix_displacement_sign():
    """LD A,(IX+5) and LD A,(IX-5) format displacement correctly."""
    m = _mem_with([0xDD, 0x7E, 0x05])
    assert decode_at(m, 0).mnemonic == 'LD A,(IX+5)'
    m = _mem_with([0xDD, 0x7E, 0xFB])  # -5
    assert decode_at(m, 0).mnemonic == 'LD A,(IX-5)'
