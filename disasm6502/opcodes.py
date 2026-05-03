"""6502 opcode table and addressing-mode metadata.

Each entry maps an opcode byte to (mnemonic, addressing_mode, byte_count).
Covers all 151 documented MOS 6502 opcodes plus the well-known undocumented
NMOS opcodes (LAX, SAX, SLO, RLA, etc.) so the disassembler doesn't choke on
them when the recursive walker strays into data.

Addressing modes
----------------
    IMP  Implied              (none)         1
    ACC  Accumulator          A              1
    IMM  Immediate            #$nn           2
    ZP   Zero page            $nn            2
    ZPX  Zero page,X          $nn,X          2
    ZPY  Zero page,Y          $nn,Y          2
    ABS  Absolute             $nnnn          3
    ABX  Absolute,X           $nnnn,X        3
    ABY  Absolute,Y           $nnnn,Y        3
    IND  Indirect             ($nnnn)        3   (JMP only)
    IZX  Indexed indirect     ($nn,X)        2
    IZY  Indirect indexed     ($nn),Y        2
    REL  Relative             $nnnn          2   (signed 8-bit branch offset)
"""

OPCODES = {
    # ── 0x0_ ──
    0x00: ("BRK", "IMP", 1), 0x01: ("ORA", "IZX", 2), 0x05: ("ORA", "ZP", 2),
    0x06: ("ASL", "ZP", 2),  0x08: ("PHP", "IMP", 1), 0x09: ("ORA", "IMM", 2),
    0x0A: ("ASL", "ACC", 1), 0x0D: ("ORA", "ABS", 3), 0x0E: ("ASL", "ABS", 3),
    # ── 0x1_ ──
    0x10: ("BPL", "REL", 2), 0x11: ("ORA", "IZY", 2), 0x15: ("ORA", "ZPX", 2),
    0x16: ("ASL", "ZPX", 2), 0x18: ("CLC", "IMP", 1), 0x19: ("ORA", "ABY", 3),
    0x1D: ("ORA", "ABX", 3), 0x1E: ("ASL", "ABX", 3),
    # ── 0x2_ ──
    0x20: ("JSR", "ABS", 3), 0x21: ("AND", "IZX", 2), 0x24: ("BIT", "ZP", 2),
    0x25: ("AND", "ZP", 2),  0x26: ("ROL", "ZP", 2),  0x28: ("PLP", "IMP", 1),
    0x29: ("AND", "IMM", 2), 0x2A: ("ROL", "ACC", 1), 0x2C: ("BIT", "ABS", 3),
    0x2D: ("AND", "ABS", 3), 0x2E: ("ROL", "ABS", 3),
    # ── 0x3_ ──
    0x30: ("BMI", "REL", 2), 0x31: ("AND", "IZY", 2), 0x35: ("AND", "ZPX", 2),
    0x36: ("ROL", "ZPX", 2), 0x38: ("SEC", "IMP", 1), 0x39: ("AND", "ABY", 3),
    0x3D: ("AND", "ABX", 3), 0x3E: ("ROL", "ABX", 3),
    # ── 0x4_ ──
    0x40: ("RTI", "IMP", 1), 0x41: ("EOR", "IZX", 2), 0x45: ("EOR", "ZP", 2),
    0x46: ("LSR", "ZP", 2),  0x48: ("PHA", "IMP", 1), 0x49: ("EOR", "IMM", 2),
    0x4A: ("LSR", "ACC", 1), 0x4C: ("JMP", "ABS", 3), 0x4D: ("EOR", "ABS", 3),
    0x4E: ("LSR", "ABS", 3),
    # ── 0x5_ ──
    0x50: ("BVC", "REL", 2), 0x51: ("EOR", "IZY", 2), 0x55: ("EOR", "ZPX", 2),
    0x56: ("LSR", "ZPX", 2), 0x58: ("CLI", "IMP", 1), 0x59: ("EOR", "ABY", 3),
    0x5D: ("EOR", "ABX", 3), 0x5E: ("LSR", "ABX", 3),
    # ── 0x6_ ──
    0x60: ("RTS", "IMP", 1), 0x61: ("ADC", "IZX", 2), 0x65: ("ADC", "ZP", 2),
    0x66: ("ROR", "ZP", 2),  0x68: ("PLA", "IMP", 1), 0x69: ("ADC", "IMM", 2),
    0x6A: ("ROR", "ACC", 1), 0x6C: ("JMP", "IND", 3), 0x6D: ("ADC", "ABS", 3),
    0x6E: ("ROR", "ABS", 3),
    # ── 0x7_ ──
    0x70: ("BVS", "REL", 2), 0x71: ("ADC", "IZY", 2), 0x75: ("ADC", "ZPX", 2),
    0x76: ("ROR", "ZPX", 2), 0x78: ("SEI", "IMP", 1), 0x79: ("ADC", "ABY", 3),
    0x7D: ("ADC", "ABX", 3), 0x7E: ("ROR", "ABX", 3),
    # ── 0x8_ ──
    0x81: ("STA", "IZX", 2), 0x84: ("STY", "ZP", 2),  0x85: ("STA", "ZP", 2),
    0x86: ("STX", "ZP", 2),  0x88: ("DEY", "IMP", 1), 0x8A: ("TXA", "IMP", 1),
    0x8C: ("STY", "ABS", 3), 0x8D: ("STA", "ABS", 3), 0x8E: ("STX", "ABS", 3),
    # ── 0x9_ ──
    0x90: ("BCC", "REL", 2), 0x91: ("STA", "IZY", 2), 0x94: ("STY", "ZPX", 2),
    0x95: ("STA", "ZPX", 2), 0x96: ("STX", "ZPY", 2), 0x98: ("TYA", "IMP", 1),
    0x99: ("STA", "ABY", 3), 0x9A: ("TXS", "IMP", 1), 0x9D: ("STA", "ABX", 3),
    # ── 0xA_ ──
    0xA0: ("LDY", "IMM", 2), 0xA1: ("LDA", "IZX", 2), 0xA2: ("LDX", "IMM", 2),
    0xA4: ("LDY", "ZP", 2),  0xA5: ("LDA", "ZP", 2),  0xA6: ("LDX", "ZP", 2),
    0xA8: ("TAY", "IMP", 1), 0xA9: ("LDA", "IMM", 2), 0xAA: ("TAX", "IMP", 1),
    0xAC: ("LDY", "ABS", 3), 0xAD: ("LDA", "ABS", 3), 0xAE: ("LDX", "ABS", 3),
    # ── 0xB_ ──
    0xB0: ("BCS", "REL", 2), 0xB1: ("LDA", "IZY", 2), 0xB4: ("LDY", "ZPX", 2),
    0xB5: ("LDA", "ZPX", 2), 0xB6: ("LDX", "ZPY", 2), 0xB8: ("CLV", "IMP", 1),
    0xB9: ("LDA", "ABY", 3), 0xBA: ("TSX", "IMP", 1), 0xBC: ("LDY", "ABX", 3),
    0xBD: ("LDA", "ABX", 3), 0xBE: ("LDX", "ABY", 3),
    # ── 0xC_ ──
    0xC0: ("CPY", "IMM", 2), 0xC1: ("CMP", "IZX", 2), 0xC4: ("CPY", "ZP", 2),
    0xC5: ("CMP", "ZP", 2),  0xC6: ("DEC", "ZP", 2),  0xC8: ("INY", "IMP", 1),
    0xC9: ("CMP", "IMM", 2), 0xCA: ("DEX", "IMP", 1), 0xCC: ("CPY", "ABS", 3),
    0xCD: ("CMP", "ABS", 3), 0xCE: ("DEC", "ABS", 3),
    # ── 0xD_ ──
    0xD0: ("BNE", "REL", 2), 0xD1: ("CMP", "IZY", 2), 0xD5: ("CMP", "ZPX", 2),
    0xD6: ("DEC", "ZPX", 2), 0xD8: ("CLD", "IMP", 1), 0xD9: ("CMP", "ABY", 3),
    0xDD: ("CMP", "ABX", 3), 0xDE: ("DEC", "ABX", 3),
    # ── 0xE_ ──
    0xE0: ("CPX", "IMM", 2), 0xE1: ("SBC", "IZX", 2), 0xE4: ("CPX", "ZP", 2),
    0xE5: ("SBC", "ZP", 2),  0xE6: ("INC", "ZP", 2),  0xE8: ("INX", "IMP", 1),
    0xE9: ("SBC", "IMM", 2), 0xEA: ("NOP", "IMP", 1), 0xEC: ("CPX", "ABS", 3),
    0xED: ("SBC", "ABS", 3), 0xEE: ("INC", "ABS", 3),
    # ── 0xF_ ──
    0xF0: ("BEQ", "REL", 2), 0xF1: ("SBC", "IZY", 2), 0xF5: ("SBC", "ZPX", 2),
    0xF6: ("INC", "ZPX", 2), 0xF8: ("SED", "IMP", 1), 0xF9: ("SBC", "ABY", 3),
    0xFD: ("SBC", "ABX", 3), 0xFE: ("INC", "ABX", 3),

    # ── Undocumented NMOS 6502 opcodes ──
    # NOP variants:
    0x04: ("NOP", "ZP", 2),  0x44: ("NOP", "ZP", 2),  0x64: ("NOP", "ZP", 2),
    0x0C: ("NOP", "ABS", 3),
    0x14: ("NOP", "ZPX", 2), 0x34: ("NOP", "ZPX", 2), 0x54: ("NOP", "ZPX", 2),
    0x74: ("NOP", "ZPX", 2), 0xD4: ("NOP", "ZPX", 2), 0xF4: ("NOP", "ZPX", 2),
    0x1A: ("NOP", "IMP", 1), 0x3A: ("NOP", "IMP", 1), 0x5A: ("NOP", "IMP", 1),
    0x7A: ("NOP", "IMP", 1), 0xDA: ("NOP", "IMP", 1), 0xFA: ("NOP", "IMP", 1),
    0x80: ("NOP", "IMM", 2), 0x82: ("NOP", "IMM", 2), 0x89: ("NOP", "IMM", 2),
    0xC2: ("NOP", "IMM", 2), 0xE2: ("NOP", "IMM", 2),
    0x1C: ("NOP", "ABX", 3), 0x3C: ("NOP", "ABX", 3), 0x5C: ("NOP", "ABX", 3),
    0x7C: ("NOP", "ABX", 3), 0xDC: ("NOP", "ABX", 3), 0xFC: ("NOP", "ABX", 3),
    # LAX (LDA + LDX combined):
    0xA3: ("LAX", "IZX", 2), 0xA7: ("LAX", "ZP", 2),  0xAF: ("LAX", "ABS", 3),
    0xB3: ("LAX", "IZY", 2), 0xB7: ("LAX", "ZPY", 2), 0xBF: ("LAX", "ABY", 3),
    0xAB: ("LAX", "IMM", 2),
    # SAX (store A AND X):
    0x83: ("SAX", "IZX", 2), 0x87: ("SAX", "ZP", 2),  0x8F: ("SAX", "ABS", 3),
    0x97: ("SAX", "ZPY", 2),
    # SBC duplicate:
    0xEB: ("SBC", "IMM", 2),
    # DCP (DEC + CMP):
    0xC3: ("DCP", "IZX", 2), 0xC7: ("DCP", "ZP", 2),  0xCF: ("DCP", "ABS", 3),
    0xD3: ("DCP", "IZY", 2), 0xD7: ("DCP", "ZPX", 2), 0xDB: ("DCP", "ABY", 3),
    0xDF: ("DCP", "ABX", 3),
    # ISC / ISB (INC + SBC):
    0xE3: ("ISC", "IZX", 2), 0xE7: ("ISC", "ZP", 2),  0xEF: ("ISC", "ABS", 3),
    0xF3: ("ISC", "IZY", 2), 0xF7: ("ISC", "ZPX", 2), 0xFB: ("ISC", "ABY", 3),
    0xFF: ("ISC", "ABX", 3),
    # SLO (ASL + ORA):
    0x03: ("SLO", "IZX", 2), 0x07: ("SLO", "ZP", 2),  0x0F: ("SLO", "ABS", 3),
    0x13: ("SLO", "IZY", 2), 0x17: ("SLO", "ZPX", 2), 0x1B: ("SLO", "ABY", 3),
    0x1F: ("SLO", "ABX", 3),
    # RLA (ROL + AND):
    0x23: ("RLA", "IZX", 2), 0x27: ("RLA", "ZP", 2),  0x2F: ("RLA", "ABS", 3),
    0x33: ("RLA", "IZY", 2), 0x37: ("RLA", "ZPX", 2), 0x3B: ("RLA", "ABY", 3),
    0x3F: ("RLA", "ABX", 3),
    # SRE (LSR + EOR):
    0x43: ("SRE", "IZX", 2), 0x47: ("SRE", "ZP", 2),  0x4F: ("SRE", "ABS", 3),
    0x53: ("SRE", "IZY", 2), 0x57: ("SRE", "ZPX", 2), 0x5B: ("SRE", "ABY", 3),
    0x5F: ("SRE", "ABX", 3),
    # RRA (ROR + ADC):
    0x63: ("RRA", "IZX", 2), 0x67: ("RRA", "ZP", 2),  0x6F: ("RRA", "ABS", 3),
    0x73: ("RRA", "IZY", 2), 0x77: ("RRA", "ZPX", 2), 0x7B: ("RRA", "ABY", 3),
    0x7F: ("RRA", "ABX", 3),
    # ANC, ALR, ARR, AXS:
    0x0B: ("ANC", "IMM", 2), 0x2B: ("ANC", "IMM", 2),
    0x4B: ("ALR", "IMM", 2), 0x6B: ("ARR", "IMM", 2),
    0xCB: ("AXS", "IMM", 2),
    # KIL (jam CPU):
    0x02: ("KIL", "IMP", 1), 0x12: ("KIL", "IMP", 1), 0x22: ("KIL", "IMP", 1),
    0x32: ("KIL", "IMP", 1), 0x42: ("KIL", "IMP", 1), 0x52: ("KIL", "IMP", 1),
    0x62: ("KIL", "IMP", 1), 0x72: ("KIL", "IMP", 1), 0x92: ("KIL", "IMP", 1),
    0xB2: ("KIL", "IMP", 1), 0xD2: ("KIL", "IMP", 1), 0xF2: ("KIL", "IMP", 1),
    # Unstable: SHA/SHX/SHY/TAS/LAS/XAA:
    0x93: ("SHA", "IZY", 2), 0x9F: ("SHA", "ABY", 3),
    0x9E: ("SHX", "ABY", 3), 0x9C: ("SHY", "ABX", 3),
    0x9B: ("TAS", "ABY", 3), 0xBB: ("LAS", "ABY", 3),
    0x8B: ("XAA", "IMM", 2),
}


# Mnemonics that almost never appear in real code; encountering one mid-trace
# strongly suggests the recursive walker has wandered into a data region.
UNDOC_MNEMONICS = frozenset((
    "SLO", "RLA", "SRE", "RRA", "SAX", "LAX", "DCP", "ISC",
    "ANC", "ALR", "ARR", "AXS", "KIL", "SHA", "SHX", "SHY",
    "TAS", "LAS", "XAA",
))


def operand_size(mode):
    """Return the number of operand bytes for an addressing mode."""
    return {
        "IMP": 0, "ACC": 0,
        "IMM": 1, "ZP": 1, "ZPX": 1, "ZPY": 1, "IZX": 1, "IZY": 1, "REL": 1,
        "ABS": 2, "ABX": 2, "ABY": 2, "IND": 2,
    }[mode]
