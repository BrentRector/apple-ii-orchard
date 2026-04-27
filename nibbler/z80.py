"""
Z-80 disassembler — first-pass implementation.

Supports all 256 unprefixed opcodes. Handles the four prefix bytes
(CB, DD, ED, FD) by emitting "DB $xx" raw-byte placeholders for
any prefix-byte sequence — accurate enough to read Z-80 BIOS code
without choking on bit ops or IX/IY operations, but those will
appear as raw bytes in the output. Extending coverage to the prefix
tables is a follow-up; the unprefixed core is sufficient for the
SoftCard CP/M install fragments and most BIOS routines.

Overview
--------
The Zilog Z-80 is an 8-bit processor used in CP/M systems, the TRS-80,
the Sinclair Spectrum, and many other machines from the late 1970s
onward. Microsoft's SoftCard plugs a Z-80 into an Apple ][ slot,
allowing CP/M to run alongside the Apple's native 6502.

The Z-80 instruction set has roughly 700 distinct mnemonics across
its base set and four prefix tables (CB for bit operations, DD for
IX-indexed, ED for extended I/O and block ops, FD for IY-indexed).
This implementation covers the unprefixed 256 opcodes — enough for
typical control flow (LD, JP, CALL, RET, JR), 8-bit arithmetic
(ADD, SUB, AND, OR, XOR, CP), I/O (IN, OUT), and stack/register
operations (PUSH, POP, EX). Bit ops, block instructions, and
IX/IY-indexed addressing are emitted as "DB $xx" markers for now.

Addressing-mode notation in the output
--------------------------------------
- Direct register: A, B, C, D, E, H, L
- Register pair: BC, DE, HL, SP, IX, IY, AF
- Immediate 8-bit:  $XX
- Immediate 16-bit: $XXXX
- Indirect via register pair: (BC), (DE), (HL), (IX+d), (IY+d)
- Indirect via address: ($XXXX)
- Relative (JR/DJNZ): displayed as absolute target address $XXXX
- Conditional flags: NZ, Z, NC, C, PO, PE, P, M
"""

# ── Single-bit register encodings ───────────────────────────────────
# Used by the regular 40-7F (LD r,r') and 80-BF (ALU A,r) blocks.
# Bits 2-0 (or bits 5-3 for destination) encode the register.
R8 = ['B', 'C', 'D', 'E', 'H', 'L', '(HL)', 'A']

# ── Register pair encodings ────────────────────────────────────────
# Bits 5-4 of the opcode for instructions like PUSH/POP, INC rp, LD rp,nn
RP = ['BC', 'DE', 'HL', 'SP']      # for arithmetic / LD ops
RP2 = ['BC', 'DE', 'HL', 'AF']     # for PUSH/POP

# ── Condition flag encodings ───────────────────────────────────────
# Bits 5-3 for JP cc, CALL cc, RET cc
CC = ['NZ', 'Z', 'NC', 'C', 'PO', 'PE', 'P', 'M']

# ── ALU operation encodings ────────────────────────────────────────
# Bits 5-3 of the opcode for the 80-BF block, plus the immediate
# variants in the C0-FF block (C6, CE, D6, DE, E6, EE, F6, FE).
ALU = ['ADD A,', 'ADC A,', 'SUB ', 'SBC A,', 'AND ', 'XOR ', 'OR ', 'CP ']

# ── Rotation operation encodings ───────────────────────────────────
# For the small 00-3F block: opcode 07/0F/17/1F/27/2F/37/3F = bit 5-3
ROT_ACC = ['RLCA', 'RRCA', 'RLA', 'RRA', 'DAA', 'CPL', 'SCF', 'CCF']

# ── Sparse table for irregular 00-3F opcodes ───────────────────────
# For the regular blocks (40-7F, 80-BF) we generate mnemonics
# programmatically. The 00-3F and C0-FF blocks are mostly irregular
# so they need a table.
_OP_LO = {
    0x00: ('NOP',           1),
    0x01: ('LD BC,${NN}',   3),
    0x02: ('LD (BC),A',     1),
    0x03: ('INC BC',        1),
    0x04: ('INC B',         1),
    0x05: ('DEC B',         1),
    0x06: ('LD B,${N}',     2),
    0x07: ('RLCA',          1),
    0x08: ("EX AF,AF'",     1),
    0x09: ('ADD HL,BC',     1),
    0x0A: ('LD A,(BC)',     1),
    0x0B: ('DEC BC',        1),
    0x0C: ('INC C',         1),
    0x0D: ('DEC C',         1),
    0x0E: ('LD C,${N}',     2),
    0x0F: ('RRCA',          1),

    0x10: ('DJNZ ${E}',     2),
    0x11: ('LD DE,${NN}',   3),
    0x12: ('LD (DE),A',     1),
    0x13: ('INC DE',        1),
    0x14: ('INC D',         1),
    0x15: ('DEC D',         1),
    0x16: ('LD D,${N}',     2),
    0x17: ('RLA',           1),
    0x18: ('JR ${E}',       2),
    0x19: ('ADD HL,DE',     1),
    0x1A: ('LD A,(DE)',     1),
    0x1B: ('DEC DE',        1),
    0x1C: ('INC E',         1),
    0x1D: ('DEC E',         1),
    0x1E: ('LD E,${N}',     2),
    0x1F: ('RRA',           1),

    0x20: ('JR NZ,${E}',    2),
    0x21: ('LD HL,${NN}',   3),
    0x22: ('LD (${NN}),HL', 3),
    0x23: ('INC HL',        1),
    0x24: ('INC H',         1),
    0x25: ('DEC H',         1),
    0x26: ('LD H,${N}',     2),
    0x27: ('DAA',           1),
    0x28: ('JR Z,${E}',     2),
    0x29: ('ADD HL,HL',     1),
    0x2A: ('LD HL,(${NN})', 3),
    0x2B: ('DEC HL',        1),
    0x2C: ('INC L',         1),
    0x2D: ('DEC L',         1),
    0x2E: ('LD L,${N}',     2),
    0x2F: ('CPL',           1),

    0x30: ('JR NC,${E}',    2),
    0x31: ('LD SP,${NN}',   3),
    0x32: ('LD (${NN}),A',  3),
    0x33: ('INC SP',        1),
    0x34: ('INC (HL)',      1),
    0x35: ('DEC (HL)',      1),
    0x36: ('LD (HL),${N}',  2),
    0x37: ('SCF',           1),
    0x38: ('JR C,${E}',     2),
    0x39: ('ADD HL,SP',     1),
    0x3A: ('LD A,(${NN})',  3),
    0x3B: ('DEC SP',        1),
    0x3C: ('INC A',         1),
    0x3D: ('DEC A',         1),
    0x3E: ('LD A,${N}',     2),
    0x3F: ('CCF',           1),
}

# ── Sparse table for irregular C0-FF opcodes ───────────────────────
_OP_HI = {
    0xC0: ('RET NZ',         1),
    0xC1: ('POP BC',         1),
    0xC2: ('JP NZ,${NN}',    3),
    0xC3: ('JP ${NN}',       3),
    0xC4: ('CALL NZ,${NN}',  3),
    0xC5: ('PUSH BC',        1),
    0xC6: ('ADD A,${N}',     2),
    0xC7: ('RST $00',        1),
    0xC8: ('RET Z',          1),
    0xC9: ('RET',            1),
    0xCA: ('JP Z,${NN}',     3),
    0xCB: ('DB $CB',         1),  # CB-prefix (bit ops) — first-pass: stub
    0xCC: ('CALL Z,${NN}',   3),
    0xCD: ('CALL ${NN}',     3),
    0xCE: ('ADC A,${N}',     2),
    0xCF: ('RST $08',        1),

    0xD0: ('RET NC',         1),
    0xD1: ('POP DE',         1),
    0xD2: ('JP NC,${NN}',    3),
    0xD3: ('OUT (${N}),A',   2),
    0xD4: ('CALL NC,${NN}',  3),
    0xD5: ('PUSH DE',        1),
    0xD6: ('SUB ${N}',       2),
    0xD7: ('RST $10',        1),
    0xD8: ('RET C',          1),
    0xD9: ('EXX',            1),
    0xDA: ('JP C,${NN}',     3),
    0xDB: ('IN A,(${N})',    2),
    0xDC: ('CALL C,${NN}',   3),
    0xDD: ('DB $DD',         1),  # DD-prefix (IX) — first-pass: stub
    0xDE: ('SBC A,${N}',     2),
    0xDF: ('RST $18',        1),

    0xE0: ('RET PO',         1),
    0xE1: ('POP HL',         1),
    0xE2: ('JP PO,${NN}',    3),
    0xE3: ('EX (SP),HL',     1),
    0xE4: ('CALL PO,${NN}',  3),
    0xE5: ('PUSH HL',        1),
    0xE6: ('AND ${N}',       2),
    0xE7: ('RST $20',        1),
    0xE8: ('RET PE',         1),
    0xE9: ('JP (HL)',        1),
    0xEA: ('JP PE,${NN}',    3),
    0xEB: ('EX DE,HL',       1),
    0xEC: ('CALL PE,${NN}',  3),
    0xED: ('DB $ED',         1),  # ED-prefix (extended) — first-pass: stub
    0xEE: ('XOR ${N}',       2),
    0xEF: ('RST $28',        1),

    0xF0: ('RET P',          1),
    0xF1: ('POP AF',         1),
    0xF2: ('JP P,${NN}',     3),
    0xF3: ('DI',             1),
    0xF4: ('CALL P,${NN}',   3),
    0xF5: ('PUSH AF',        1),
    0xF6: ('OR ${N}',        2),
    0xF7: ('RST $30',        1),
    0xF8: ('RET M',          1),
    0xF9: ('LD SP,HL',       1),
    0xFA: ('JP M,${NN}',     3),
    0xFB: ('EI',             1),
    0xFC: ('CALL M,${NN}',   3),
    0xFD: ('DB $FD',         1),  # FD-prefix (IY) — first-pass: stub
    0xFE: ('CP ${N}',        2),
    0xFF: ('RST $38',        1),
}


def _decode_one(opcode: int) -> tuple:
    """Decode a single unprefixed opcode to (mnemonic_template, byte_count).

    Returns the template with placeholders ${N} (byte), ${NN} (word),
    or ${E} (relative). Caller substitutes after reading operand bytes.
    """
    if opcode in _OP_LO:
        return _OP_LO[opcode]
    if opcode in _OP_HI:
        return _OP_HI[opcode]

    # 40-7F: LD r,r' (with HALT at 76 as the "LD (HL),(HL)" slot)
    if 0x40 <= opcode <= 0x7F:
        if opcode == 0x76:
            return ('HALT', 1)
        dst = R8[(opcode >> 3) & 7]
        src = R8[opcode & 7]
        return (f'LD {dst},{src}', 1)

    # 80-BF: ALU A,r
    if 0x80 <= opcode <= 0xBF:
        op = ALU[(opcode >> 3) & 7]
        src = R8[opcode & 7]
        return (f'{op}{src}', 1)

    # Unreachable — every byte is covered by the tables above.
    return (f'DB ${opcode:02X}', 1)


def disassemble_one(buf: bytes, offset: int, addr: int) -> tuple:
    """Disassemble a single Z-80 instruction at buf[offset], with PC = addr.

    Returns (instruction_text, byte_count, raw_bytes_text).
    Raw bytes are returned as space-separated hex for display alongside
    the instruction.
    """
    if offset >= len(buf):
        return ('?? END', 0, '')
    opcode = buf[offset]
    template, n_bytes = _decode_one(opcode)

    # Read operand bytes (clamped to end of buffer)
    raw = [opcode]
    for i in range(1, n_bytes):
        if offset + i < len(buf):
            raw.append(buf[offset + i])
        else:
            raw.append(0)

    # Substitute operands into the template
    text = template
    if '${NN}' in text:
        # Little-endian 16-bit immediate at offset+1, offset+2
        word = raw[1] | (raw[2] << 8)
        text = text.replace('${NN}', f'{word:04X}')
    if '${N}' in text:
        text = text.replace('${N}', f'{raw[1]:02X}')
    if '${E}' in text:
        # Signed 8-bit displacement, target = (addr + 2) + signed e
        e = raw[1]
        if e & 0x80:
            e -= 0x100
        target = (addr + 2 + e) & 0xFFFF
        text = text.replace('${E}', f'{target:04X}')

    raw_text = ' '.join(f'{b:02X}' for b in raw)
    return (text, n_bytes, raw_text)


def disassemble_region(buf: bytes, base_addr: int,
                       start_addr: int = None, end_addr: int = None) -> list:
    """Linearly disassemble buf, treating every byte as code.

    Returns a list of formatted strings, one per instruction.

    Args:
        buf: bytes buffer
        base_addr: Z-80 address corresponding to buf[0]
        start_addr: address to start from (default: base_addr)
        end_addr: address to stop at (default: base_addr + len(buf))
    """
    if start_addr is None:
        start_addr = base_addr
    if end_addr is None:
        end_addr = base_addr + len(buf)

    lines = []
    addr = start_addr
    while addr < end_addr:
        offset = addr - base_addr
        if offset < 0 or offset >= len(buf):
            break
        text, n, raw = disassemble_one(buf, offset, addr)
        if n == 0:
            break
        lines.append(f'  ${addr:04X}: {raw:<8s}  {text}')
        addr += n
    return lines


if __name__ == '__main__':
    # Smoke-test: disassemble a small buffer
    sample = bytes([
        0x31, 0x00, 0x80,   # LD SP,$8000
        0x3E, 0x42,         # LD A,$42
        0xCD, 0x00, 0x10,   # CALL $1000
        0xC3, 0x00, 0xFA,   # JP $FA00 (the planted reset vector!)
        0xDB, 0x40,         # IN A,($40)
        0xD3, 0x40,         # OUT ($40),A
        0xC9,               # RET
    ])
    for line in disassemble_region(sample, 0x0000):
        print(line)
