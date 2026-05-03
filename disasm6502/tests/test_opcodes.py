"""Opcode-table sanity checks."""

from disasm6502.opcodes import OPCODES, UNDOC_MNEMONICS, operand_size


def test_all_256_opcodes_decoded():
    """Every byte 0..0xFF should have a decoded entry (documented or undoc)."""
    missing = [b for b in range(256) if b not in OPCODES]
    assert missing == [], f"undecoded opcodes: {[hex(b) for b in missing]}"


def test_size_matches_addressing_mode():
    """Instruction size = 1 + operand_size(mode) for every entry."""
    for opcode, (mnem, mode, size) in OPCODES.items():
        assert size == 1 + operand_size(mode), (
            f"opcode ${opcode:02X} {mnem} {mode}: size={size}, "
            f"expected {1 + operand_size(mode)}"
        )


def test_documented_anchor_opcodes():
    """Spot-check well-known opcodes."""
    assert OPCODES[0x00] == ("BRK", "IMP", 1)
    assert OPCODES[0x20] == ("JSR", "ABS", 3)
    assert OPCODES[0x4C] == ("JMP", "ABS", 3)
    assert OPCODES[0x60] == ("RTS", "IMP", 1)
    assert OPCODES[0xA9] == ("LDA", "IMM", 2)
    assert OPCODES[0xEA] == ("NOP", "IMP", 1)


def test_undoc_mnemonics_are_real():
    """Every UNDOC_MNEMONICS entry must appear in OPCODES."""
    seen = {m for m, _, _ in OPCODES.values()}
    for m in UNDOC_MNEMONICS:
        assert m in seen, f"UNDOC_MNEMONICS lists {m!r} but OPCODES has no such entry"
