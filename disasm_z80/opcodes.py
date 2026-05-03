"""Z-80 opcode tables and instruction decoder.

Coverage
--------
* Base unprefixed (256 entries)
* CB-prefixed: 256 entries (rotations, BIT/RES/SET)
* ED-prefixed: 256 entries (most invalid, returned as 2-byte NONI no-op)
* DD-prefixed: like base with HL -> IX, plus DDCB compound prefix
* FD-prefixed: like DD with IX -> IY, plus FDCB compound prefix
* DDCB / FDCB: 4-byte (prefix + CB + displacement + op) for IX/IY bit ops

Encoding sources
----------------
The systematic Z-80 encoding follows Smith / Jones / Wilkinson / Eilers and is
documented in the Zilog Z80 CPU User Manual (UM008011-0816). Key structural
patterns this module relies on:

  R8  = ['B','C','D','E','H','L','(HL)','A']           # bits 2:0 or 5:3
  RP  = ['BC','DE','HL','SP']                          # bits 5:4 (arith / LD)
  RP2 = ['BC','DE','HL','AF']                          # bits 5:4 (PUSH/POP)
  CC  = ['NZ','Z','NC','C','PO','PE','P','M']          # bits 5:3 (cond)
  ALU = ['ADD A,','ADC A,','SUB ','SBC A,',
         'AND ','XOR ','OR ','CP ']                    # bits 5:3 (ALU)
  ROT = ['RLC','RRC','RL','RR','SLA','SRA','SLL','SRL']  # CB rot ops

Decoder API
-----------
    decode_at(mem, addr) -> Instruction

`Instruction` is a dataclass with mnemonic_template, total length, and
control-flow class (used by the recursive walker).
"""

from dataclasses import dataclass, field
from enum import Enum


# ── Encoding tables ────────────────────────────────────────────────────
R8 = ['B', 'C', 'D', 'E', 'H', 'L', '(HL)', 'A']
RP = ['BC', 'DE', 'HL', 'SP']
RP2 = ['BC', 'DE', 'HL', 'AF']
CC = ['NZ', 'Z', 'NC', 'C', 'PO', 'PE', 'P', 'M']
ALU = ['ADD A,', 'ADC A,', 'SUB ', 'SBC A,', 'AND ', 'XOR ', 'OR ', 'CP ']
ROT = ['RLC', 'RRC', 'RL', 'RR', 'SLA', 'SRA', 'SLL', 'SRL']


class ControlFlow(Enum):
    """How an instruction affects control flow (for the recursive walker)."""
    NEXT = "next"           # falls through
    JUMP_ABS = "jump_abs"   # JP nn / JR e (unconditional) -- target known, no fall-through
    JUMP_CC = "jump_cc"     # JP cc,nn / JR cc,e / DJNZ -- target known + fall-through
    CALL = "call"           # CALL nn / RST p -- target known + fall-through
    CALL_CC = "call_cc"     # CALL cc,nn -- target known + fall-through
    RET = "ret"             # RET / RETI / RETN / unconditional return
    RET_CC = "ret_cc"       # RET cc -- conditional, fall-through too
    INDIRECT = "indirect"   # JP (HL) / JP (IX) / JP (IY) -- target unknown; stop trace
    HALT = "halt"           # HALT -- stop trace


@dataclass
class Instruction:
    addr: int                    # PC at first byte
    raw: bytes                   # all bytes consumed (1..4)
    mnemonic: str                # already-formatted (no template placeholders)
    size: int                    # total length
    control_flow: ControlFlow
    target: int | None = None    # 16-bit target for JP/CALL/JR/DJNZ/RST


# ── Regular block generators ───────────────────────────────────────────
def _ld_r_r(opcode):
    """40-7F: LD r,r' (r' = bits 2:0, r = bits 5:3). Exception: 76 = HALT."""
    if opcode == 0x76:
        return None  # HALT, handled separately
    src = R8[opcode & 0x07]
    dst = R8[(opcode >> 3) & 0x07]
    return f"LD {dst},{src}"


def _alu_r(opcode):
    """80-BF: ALU A,r (alu = bits 5:3, r = bits 2:0)."""
    op = ALU[(opcode >> 3) & 0x07]
    src = R8[opcode & 0x07]
    return f"{op}{src}"


# ── Base unprefixed table (256 entries) ────────────────────────────────
# Each value is one of:
#   ('static', mnem, size, cf)             -- no operand fetching
#   ('imm8',   template, size, cf)         -- 1 immediate byte (placeholder {n})
#   ('imm16',  template, size, cf)         -- 2 immediate bytes (placeholder {nn})
#   ('rel',    template, size, cf)         -- 1 signed offset (placeholder {e})
# The template uses {n}/{nn}/{e} which the decoder substitutes.
BASE = {}


def _static(op, mnem, size=1, cf=ControlFlow.NEXT):
    BASE[op] = ('static', mnem, size, cf)


def _imm8(op, template, cf=ControlFlow.NEXT):
    BASE[op] = ('imm8', template, 2, cf)


def _imm16(op, template, cf=ControlFlow.NEXT):
    BASE[op] = ('imm16', template, 3, cf)


def _rel(op, template, cf):
    BASE[op] = ('rel', template, 2, cf)


# Block 0x00-0x3F: irregular
_static(0x00, 'NOP')
_imm16(0x01, 'LD BC,${nn:04X}')
_static(0x02, 'LD (BC),A')
_static(0x03, 'INC BC')
_static(0x04, 'INC B')
_static(0x05, 'DEC B')
_imm8(0x06, 'LD B,${n:02X}')
_static(0x07, 'RLCA')
_static(0x08, "EX AF,AF'")
_static(0x09, 'ADD HL,BC')
_static(0x0A, 'LD A,(BC)')
_static(0x0B, 'DEC BC')
_static(0x0C, 'INC C')
_static(0x0D, 'DEC C')
_imm8(0x0E, 'LD C,${n:02X}')
_static(0x0F, 'RRCA')

_rel(0x10, 'DJNZ ${e:04X}', ControlFlow.JUMP_CC)
_imm16(0x11, 'LD DE,${nn:04X}')
_static(0x12, 'LD (DE),A')
_static(0x13, 'INC DE')
_static(0x14, 'INC D')
_static(0x15, 'DEC D')
_imm8(0x16, 'LD D,${n:02X}')
_static(0x17, 'RLA')
_rel(0x18, 'JR ${e:04X}', ControlFlow.JUMP_ABS)
_static(0x19, 'ADD HL,DE')
_static(0x1A, 'LD A,(DE)')
_static(0x1B, 'DEC DE')
_static(0x1C, 'INC E')
_static(0x1D, 'DEC E')
_imm8(0x1E, 'LD E,${n:02X}')
_static(0x1F, 'RRA')

_rel(0x20, 'JR NZ,${e:04X}', ControlFlow.JUMP_CC)
_imm16(0x21, 'LD HL,${nn:04X}')
_imm16(0x22, 'LD (${nn:04X}),HL')
_static(0x23, 'INC HL')
_static(0x24, 'INC H')
_static(0x25, 'DEC H')
_imm8(0x26, 'LD H,${n:02X}')
_static(0x27, 'DAA')
_rel(0x28, 'JR Z,${e:04X}', ControlFlow.JUMP_CC)
_static(0x29, 'ADD HL,HL')
_imm16(0x2A, 'LD HL,(${nn:04X})')
_static(0x2B, 'DEC HL')
_static(0x2C, 'INC L')
_static(0x2D, 'DEC L')
_imm8(0x2E, 'LD L,${n:02X}')
_static(0x2F, 'CPL')

_rel(0x30, 'JR NC,${e:04X}', ControlFlow.JUMP_CC)
_imm16(0x31, 'LD SP,${nn:04X}')
_imm16(0x32, 'LD (${nn:04X}),A')
_static(0x33, 'INC SP')
_static(0x34, 'INC (HL)')
_static(0x35, 'DEC (HL)')
_imm8(0x36, 'LD (HL),${n:02X}')
_static(0x37, 'SCF')
_rel(0x38, 'JR C,${e:04X}', ControlFlow.JUMP_CC)
_static(0x39, 'ADD HL,SP')
_imm16(0x3A, 'LD A,(${nn:04X})')
_static(0x3B, 'DEC SP')
_static(0x3C, 'INC A')
_static(0x3D, 'DEC A')
_imm8(0x3E, 'LD A,${n:02X}')
_static(0x3F, 'CCF')

# Block 0x40-0x7F: LD r,r' (regular, with HALT exception at 0x76)
for op in range(0x40, 0x80):
    if op == 0x76:
        _static(0x76, 'HALT', cf=ControlFlow.HALT)
    else:
        _static(op, _ld_r_r(op))

# Block 0x80-0xBF: ALU A,r (regular)
for op in range(0x80, 0xC0):
    _static(op, _alu_r(op))

# Block 0xC0-0xFF: irregular (RET cc, POP, JP cc, CALL cc, PUSH, ALU n, RST, prefixes)
_static(0xC0, 'RET NZ', cf=ControlFlow.RET_CC)
_static(0xC1, 'POP BC')
_imm16(0xC2, 'JP NZ,${nn:04X}', cf=ControlFlow.JUMP_CC)
_imm16(0xC3, 'JP ${nn:04X}', cf=ControlFlow.JUMP_ABS)
_imm16(0xC4, 'CALL NZ,${nn:04X}', cf=ControlFlow.CALL_CC)
_static(0xC5, 'PUSH BC')
_imm8(0xC6, 'ADD A,${n:02X}')
_static(0xC7, 'RST $00', cf=ControlFlow.CALL)  # RST 00H -- target $0000
_static(0xC8, 'RET Z', cf=ControlFlow.RET_CC)
_static(0xC9, 'RET', cf=ControlFlow.RET)
_imm16(0xCA, 'JP Z,${nn:04X}', cf=ControlFlow.JUMP_CC)
# 0xCB: CB prefix -- handled by decoder
_imm16(0xCC, 'CALL Z,${nn:04X}', cf=ControlFlow.CALL_CC)
_imm16(0xCD, 'CALL ${nn:04X}', cf=ControlFlow.CALL)
_imm8(0xCE, 'ADC A,${n:02X}')
_static(0xCF, 'RST $08', cf=ControlFlow.CALL)

_static(0xD0, 'RET NC', cf=ControlFlow.RET_CC)
_static(0xD1, 'POP DE')
_imm16(0xD2, 'JP NC,${nn:04X}', cf=ControlFlow.JUMP_CC)
_imm8(0xD3, 'OUT (${n:02X}),A')
_imm16(0xD4, 'CALL NC,${nn:04X}', cf=ControlFlow.CALL_CC)
_static(0xD5, 'PUSH DE')
_imm8(0xD6, 'SUB ${n:02X}')
_static(0xD7, 'RST $10', cf=ControlFlow.CALL)
_static(0xD8, 'RET C', cf=ControlFlow.RET_CC)
_static(0xD9, 'EXX')
_imm16(0xDA, 'JP C,${nn:04X}', cf=ControlFlow.JUMP_CC)
_imm8(0xDB, 'IN A,(${n:02X})')
_imm16(0xDC, 'CALL C,${nn:04X}', cf=ControlFlow.CALL_CC)
# 0xDD: DD prefix -- handled by decoder
_imm8(0xDE, 'SBC A,${n:02X}')
_static(0xDF, 'RST $18', cf=ControlFlow.CALL)

_static(0xE0, 'RET PO', cf=ControlFlow.RET_CC)
_static(0xE1, 'POP HL')
_imm16(0xE2, 'JP PO,${nn:04X}', cf=ControlFlow.JUMP_CC)
_static(0xE3, 'EX (SP),HL')
_imm16(0xE4, 'CALL PO,${nn:04X}', cf=ControlFlow.CALL_CC)
_static(0xE5, 'PUSH HL')
_imm8(0xE6, 'AND ${n:02X}')
_static(0xE7, 'RST $20', cf=ControlFlow.CALL)
_static(0xE8, 'RET PE', cf=ControlFlow.RET_CC)
_static(0xE9, 'JP (HL)', cf=ControlFlow.INDIRECT)
_imm16(0xEA, 'JP PE,${nn:04X}', cf=ControlFlow.JUMP_CC)
_static(0xEB, 'EX DE,HL')
_imm16(0xEC, 'CALL PE,${nn:04X}', cf=ControlFlow.CALL_CC)
# 0xED: ED prefix -- handled by decoder
_imm8(0xEE, 'XOR ${n:02X}')
_static(0xEF, 'RST $28', cf=ControlFlow.CALL)

_static(0xF0, 'RET P', cf=ControlFlow.RET_CC)
_static(0xF1, 'POP AF')
_imm16(0xF2, 'JP P,${nn:04X}', cf=ControlFlow.JUMP_CC)
_static(0xF3, 'DI')
_imm16(0xF4, 'CALL P,${nn:04X}', cf=ControlFlow.CALL_CC)
_static(0xF5, 'PUSH AF')
_imm8(0xF6, 'OR ${n:02X}')
_static(0xF7, 'RST $30', cf=ControlFlow.CALL)
_static(0xF8, 'RET M', cf=ControlFlow.RET_CC)
_static(0xF9, 'LD SP,HL')
_imm16(0xFA, 'JP M,${nn:04X}', cf=ControlFlow.JUMP_CC)
_static(0xFB, 'EI')
_imm16(0xFC, 'CALL M,${nn:04X}', cf=ControlFlow.CALL_CC)
# 0xFD: FD prefix -- handled by decoder
_imm8(0xFE, 'CP ${n:02X}')
_static(0xFF, 'RST $38', cf=ControlFlow.CALL)


# ── CB-prefixed table (256 entries, all regular) ───────────────────────
def _cb_mnemonic(op):
    """All 256 CB opcodes are regular."""
    r = R8[op & 0x07]
    if op < 0x40:
        rot = ROT[(op >> 3) & 0x07]
        return f"{rot} {r}"
    bit = (op >> 3) & 0x07
    if op < 0x80:
        return f"BIT {bit},{r}"
    if op < 0xC0:
        return f"RES {bit},{r}"
    return f"SET {bit},{r}"


CB = {op: _cb_mnemonic(op) for op in range(256)}


# ── ED-prefixed table (mostly invalid; valid entries explicit) ─────────
ED = {}  # int -> (mnemonic_template, total_size, cf)


def _ed_static(op, mnem, size=2, cf=ControlFlow.NEXT):
    ED[op] = ('static', mnem, size, cf)


def _ed_imm16(op, template, cf=ControlFlow.NEXT):
    ED[op] = ('imm16', template, 4, cf)


# IN r,(C): 40,48,50,58,60,68,78  (70 = IN F,(C) undocumented)
for r_idx, r in enumerate(R8):
    op = 0x40 | (r_idx << 3)
    if r_idx == 6:  # 70: IN (HL),(C) -- undocumented; reads to (no register), only sets flags
        _ed_static(op, 'IN F,(C)')
    else:
        _ed_static(op, f'IN {r},(C)')

# OUT (C),r: 41,49,...,79  (71 = OUT (C),0 undocumented)
for r_idx, r in enumerate(R8):
    op = 0x41 | (r_idx << 3)
    if r_idx == 6:
        _ed_static(op, 'OUT (C),0')
    else:
        _ed_static(op, f'OUT (C),{r}')

# SBC HL,rp: 42,52,62,72  (rp in bits 5:4)
# ADC HL,rp: 4A,5A,6A,7A
for rp_idx, rp in enumerate(RP):
    _ed_static(0x42 | (rp_idx << 4), f'SBC HL,{rp}')
    _ed_static(0x4A | (rp_idx << 4), f'ADC HL,{rp}')

# LD (nn),rp: 43,53,63,73 ;  LD rp,(nn): 4B,5B,6B,7B
for rp_idx, rp in enumerate(RP):
    _ed_imm16(0x43 | (rp_idx << 4), f'LD (${{nn:04X}}),{rp}')
    _ed_imm16(0x4B | (rp_idx << 4), f'LD {rp},(${{nn:04X}})')

# NEG: 44 documented; 4C,54,5C,64,6C,74,7C undocumented copies
for op in (0x44, 0x4C, 0x54, 0x5C, 0x64, 0x6C, 0x74, 0x7C):
    _ed_static(op, 'NEG')

# RETN: 45,55,65,75 ; RETI: 4D ; (5D,6D,7D undoc RETN)
for op in (0x45, 0x55, 0x65, 0x75, 0x5D, 0x6D, 0x7D):
    _ed_static(op, 'RETN', cf=ControlFlow.RET)
_ed_static(0x4D, 'RETI', cf=ControlFlow.RET)

# IM 0/1/2: 46/56/66 -> IM 0; 4E/6E -> IM 0/1 undoc; 56/76 -> IM 1; 5E/7E -> IM 2
_ed_static(0x46, 'IM 0')
_ed_static(0x4E, 'IM 0')   # undocumented duplicate
_ed_static(0x56, 'IM 1')
_ed_static(0x5E, 'IM 2')
_ed_static(0x66, 'IM 0')   # undocumented duplicate
_ed_static(0x6E, 'IM 0')   # undocumented duplicate
_ed_static(0x76, 'IM 1')   # undocumented duplicate
_ed_static(0x7E, 'IM 2')   # undocumented duplicate

# LD I,A / LD R,A / LD A,I / LD A,R
_ed_static(0x47, 'LD I,A')
_ed_static(0x4F, 'LD R,A')
_ed_static(0x57, 'LD A,I')
_ed_static(0x5F, 'LD A,R')

# RRD / RLD
_ed_static(0x67, 'RRD')
_ed_static(0x6F, 'RLD')

# Block I/O & block move/compare
_ed_static(0xA0, 'LDI')
_ed_static(0xA1, 'CPI')
_ed_static(0xA2, 'INI')
_ed_static(0xA3, 'OUTI')
_ed_static(0xA8, 'LDD')
_ed_static(0xA9, 'CPD')
_ed_static(0xAA, 'IND')
_ed_static(0xAB, 'OUTD')
_ed_static(0xB0, 'LDIR')
_ed_static(0xB1, 'CPIR')
_ed_static(0xB2, 'INIR')
_ed_static(0xB3, 'OTIR')
_ed_static(0xB8, 'LDDR')
_ed_static(0xB9, 'CPDR')
_ed_static(0xBA, 'INDR')
_ed_static(0xBB, 'OTDR')


# ── DD / FD prefixed (HL -> IX / IY) ───────────────────────────────────
# Strategy: derive from BASE table, replacing HL-references. Only a subset
# of base opcodes are meaningfully different; all others have an IX/IY
# encoding identical in BYTES to the base (the prefix is "ignored", i.e.
# the bytes still produce the same effect on the unrelated registers, but
# the disassembler shows them as part of a multi-byte sequence).
#
# We model this as overrides only; if the override is not in the dict,
# the decoder treats the prefix as a no-op affecting only the (HL) ->
# (IX+d) / (IY+d) substitution where applicable.

def _make_idx_table(idx_reg, prefix_byte):
    """Return {opcode: (mnem_template, size, cf)} overrides for DD or FD prefix."""
    t = {}
    # ADD ix,rp: 09,19,29,39 (rp where rp=10 means IX/IY itself)
    for rp_idx, rp in enumerate(RP):
        actual = idx_reg if rp == 'HL' else rp
        # DD/FD 09 = ADD IX,BC (size 2, NEXT)
        t[0x09 | (rp_idx << 4)] = ('static', f'ADD {idx_reg},{actual}', 2, ControlFlow.NEXT)
    # LD ix,nn: 21
    t[0x21] = ('imm16', f'LD {idx_reg},${{nn:04X}}', 4, ControlFlow.NEXT)
    # LD (nn),ix: 22 ;  LD ix,(nn): 2A
    t[0x22] = ('imm16', f'LD (${{nn:04X}}),{idx_reg}', 4, ControlFlow.NEXT)
    t[0x2A] = ('imm16', f'LD {idx_reg},(${{nn:04X}})', 4, ControlFlow.NEXT)
    # INC ix: 23 ; DEC ix: 2B
    t[0x23] = ('static', f'INC {idx_reg}', 2, ControlFlow.NEXT)
    t[0x2B] = ('static', f'DEC {idx_reg}', 2, ControlFlow.NEXT)
    # INC (ix+d): 34 ; DEC (ix+d): 35  -- size 3, displacement byte
    t[0x34] = ('disp', f'INC ({idx_reg}{{d}})', 3, ControlFlow.NEXT)
    t[0x35] = ('disp', f'DEC ({idx_reg}{{d}})', 3, ControlFlow.NEXT)
    # LD (ix+d),n: 36 -- size 4, displacement + immediate
    t[0x36] = ('disp_imm8', f'LD ({idx_reg}{{d}}),${{n:02X}}', 4, ControlFlow.NEXT)
    # LD r,(ix+d) and LD (ix+d),r: 46,4E,56,5E,66,6E,7E (LD r,(IX+d)) and
    # 70,71,72,73,74,75,77 (LD (IX+d),r). 76 stays HALT.
    for r_idx, r in enumerate(R8):
        # LD r,(ix+d): 0x46 + r*8 (where r != (HL))
        if r_idx != 6:  # skip (HL) destination
            t[0x46 | (r_idx << 3)] = ('disp', f'LD {r},({idx_reg}{{d}})', 3, ControlFlow.NEXT)
            # LD (ix+d),r: 0x70 + r
            t[0x70 | r_idx] = ('disp', f'LD ({idx_reg}{{d}}),{r}', 3, ControlFlow.NEXT)
    # ALU A,(ix+d): 0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE
    for alu_idx, op in enumerate(ALU):
        t[0x86 | (alu_idx << 3)] = ('disp', f'{op}({idx_reg}{{d}})', 3, ControlFlow.NEXT)
    # POP ix: E1 ; PUSH ix: E5
    t[0xE1] = ('static', f'POP {idx_reg}', 2, ControlFlow.NEXT)
    t[0xE5] = ('static', f'PUSH {idx_reg}', 2, ControlFlow.NEXT)
    # EX (SP),ix: E3
    t[0xE3] = ('static', f'EX (SP),{idx_reg}', 2, ControlFlow.NEXT)
    # JP (ix): E9
    t[0xE9] = ('static', f'JP ({idx_reg})', 2, ControlFlow.INDIRECT)
    # LD SP,ix: F9
    t[0xF9] = ('static', f'LD SP,{idx_reg}', 2, ControlFlow.NEXT)
    # CB: DDCB / FDCB compound prefix -- handled by decoder
    return t


DD = _make_idx_table('IX', 0xDD)
FD = _make_idx_table('IY', 0xFD)


# ── DDCB / FDCB tables (4-byte instructions) ───────────────────────────
def _idxcb_mnemonic(idx_reg, op):
    """4-byte DDCB/FDCB encoding: prefix + CB + d + op. The op uses the
    standard CB layout but the (HL) slot becomes (IX+d) / (IY+d).
    Undocumented r-store form (when r != 6) writes the result back to r."""
    bit = (op >> 3) & 0x07
    r_idx = op & 0x07
    target = f'({idx_reg}{{d}})'
    if op < 0x40:
        rot = ROT[(op >> 3) & 0x07]
        if r_idx == 6:
            return f'{rot} {target}'
        # Undocumented: rotate (IX+d) AND store result in r
        return f'{rot} {target},{R8[r_idx]}'
    if op < 0x80:
        # BIT does not write back -- r-bits are ignored
        return f'BIT {bit},{target}'
    if op < 0xC0:
        if r_idx == 6:
            return f'RES {bit},{target}'
        return f'RES {bit},{target},{R8[r_idx]}'
    # SET
    if r_idx == 6:
        return f'SET {bit},{target}'
    return f'SET {bit},{target},{R8[r_idx]}'


DDCB = {op: _idxcb_mnemonic('IX', op) for op in range(256)}
FDCB = {op: _idxcb_mnemonic('IY', op) for op in range(256)}


# ── Decoder ────────────────────────────────────────────────────────────
def _signed8(b):
    return b - 256 if b >= 128 else b


def _format_template(template, *, n=None, nn=None, e=None, d=None):
    """Substitute {n}/{nn}/{e}/{d} placeholders. The {d} substitution writes
    a signed displacement like '+5' or '-12' (sjasmplus accepts both)."""
    out = template
    if n is not None:
        out = out.replace('{n:02X}', f'{n:02X}')
    if nn is not None:
        out = out.replace('{nn:04X}', f'{nn:04X}')
    if e is not None:
        out = out.replace('{e:04X}', f'{e:04X}')
    if d is not None:
        sign = '+' if d >= 0 else '-'
        out = out.replace('{d}', f'{sign}{abs(d)}')
    return out


def decode_at(mem, addr):
    """Decode the instruction at `addr`. Returns Instruction.

    Raises IndexError if the instruction extends past `len(mem)`.
    Returns a 1-byte 'DEFB' Instruction with NEXT control flow when the
    decoder hits a truly unrecognized byte (currently never happens since
    every base byte is mapped, but kept for robustness).
    """
    op = mem[addr]

    # Prefix dispatch
    if op == 0xCB:
        op2 = mem[addr + 1]
        return Instruction(
            addr=addr,
            raw=bytes(mem[addr:addr + 2]),
            mnemonic=CB[op2],
            size=2,
            control_flow=ControlFlow.NEXT,
        )

    if op == 0xED:
        op2 = mem[addr + 1]
        entry = ED.get(op2)
        if entry is None:
            # Invalid ED-prefixed: 2-byte NONI (executes as 8-cycle no-op)
            return Instruction(
                addr=addr,
                raw=bytes(mem[addr:addr + 2]),
                mnemonic=f'DEFB ${op:02X},${op2:02X}  ; invalid ED prefix',
                size=2,
                control_flow=ControlFlow.NEXT,
            )
        kind, template, size, cf = entry
        if kind == 'static':
            return Instruction(
                addr=addr,
                raw=bytes(mem[addr:addr + size]),
                mnemonic=template,
                size=size,
                control_flow=cf,
            )
        if kind == 'imm16':
            nn = mem[addr + 2] | (mem[addr + 3] << 8)
            return Instruction(
                addr=addr,
                raw=bytes(mem[addr:addr + 4]),
                mnemonic=_format_template(template, nn=nn),
                size=4,
                control_flow=cf,
            )
        raise AssertionError(f'unhandled ED entry kind {kind!r}')

    if op in (0xDD, 0xFD):
        idx_table = DD if op == 0xDD else FD
        idxcb_table = DDCB if op == 0xDD else FDCB
        idx_reg = 'IX' if op == 0xDD else 'IY'
        op2 = mem[addr + 1]
        if op2 == 0xCB:
            # 4-byte DDCB / FDCB: prefix CB d op
            d = _signed8(mem[addr + 2])
            op4 = mem[addr + 3]
            return Instruction(
                addr=addr,
                raw=bytes(mem[addr:addr + 4]),
                mnemonic=_format_template(idxcb_table[op4], d=d),
                size=4,
                control_flow=ControlFlow.NEXT,
            )
        # IX/IY-specific override?
        entry = idx_table.get(op2)
        if entry is not None:
            kind, template, size, cf = entry
            if kind == 'static':
                return Instruction(
                    addr=addr,
                    raw=bytes(mem[addr:addr + size]),
                    mnemonic=template,
                    size=size,
                    control_flow=cf,
                )
            if kind == 'imm16':
                nn = mem[addr + 2] | (mem[addr + 3] << 8)
                return Instruction(
                    addr=addr,
                    raw=bytes(mem[addr:addr + size]),
                    mnemonic=_format_template(template, nn=nn),
                    size=size,
                    control_flow=cf,
                )
            if kind == 'disp':
                d = _signed8(mem[addr + 2])
                return Instruction(
                    addr=addr,
                    raw=bytes(mem[addr:addr + size]),
                    mnemonic=_format_template(template, d=d),
                    size=size,
                    control_flow=cf,
                )
            if kind == 'disp_imm8':
                d = _signed8(mem[addr + 2])
                n = mem[addr + 3]
                return Instruction(
                    addr=addr,
                    raw=bytes(mem[addr:addr + size]),
                    mnemonic=_format_template(template, d=d, n=n),
                    size=size,
                    control_flow=cf,
                )
            raise AssertionError(f'unhandled DD/FD entry kind {kind!r}')
        # No IX/IY override -> the prefix is a NONI no-op; decode the
        # inner byte from the BASE table and add 1 to its size. Common
        # in real code: e.g., DD 21 nn nn = LD IX,nn (covered above);
        # DD 7E d = LD A,(IX+d) (covered); but DD 00 = NONI + NOP.
        inner = decode_at(mem, addr + 1)
        # Construct a synthetic instruction whose raw bytes include the prefix
        return Instruction(
            addr=addr,
            raw=bytes([op]) + inner.raw,
            mnemonic=f'DEFB ${op:02X}  ; ignored {idx_reg} prefix; '
                     f'inner: {inner.mnemonic}',
            size=1,  # only the prefix byte; the inner instruction will be
                     # disassembled normally on the next pass at addr+1
            control_flow=ControlFlow.NEXT,
        )

    # Plain base-table opcode
    entry = BASE[op]
    kind, template, size, cf = entry
    if kind == 'static':
        return Instruction(
            addr=addr, raw=bytes(mem[addr:addr + size]),
            mnemonic=template, size=size, control_flow=cf,
        )
    if kind == 'imm8':
        n = mem[addr + 1]
        return Instruction(
            addr=addr, raw=bytes(mem[addr:addr + 2]),
            mnemonic=_format_template(template, n=n),
            size=2, control_flow=cf,
        )
    if kind == 'imm16':
        nn = mem[addr + 1] | (mem[addr + 2] << 8)
        target = nn if cf in (ControlFlow.JUMP_ABS, ControlFlow.JUMP_CC,
                              ControlFlow.CALL, ControlFlow.CALL_CC) else None
        return Instruction(
            addr=addr, raw=bytes(mem[addr:addr + 3]),
            mnemonic=_format_template(template, nn=nn),
            size=3, control_flow=cf, target=target,
        )
    if kind == 'rel':
        e = _signed8(mem[addr + 1])
        target = (addr + 2 + e) & 0xFFFF
        return Instruction(
            addr=addr, raw=bytes(mem[addr:addr + 2]),
            mnemonic=_format_template(template, e=target),
            size=2, control_flow=cf, target=target,
        )
    raise AssertionError(f'unhandled base entry kind {kind!r}')


# RST page targets (for the walker).
RST_TARGETS = {
    0xC7: 0x00, 0xCF: 0x08, 0xD7: 0x10, 0xDF: 0x18,
    0xE7: 0x20, 0xEF: 0x28, 0xF7: 0x30, 0xFF: 0x38,
}
