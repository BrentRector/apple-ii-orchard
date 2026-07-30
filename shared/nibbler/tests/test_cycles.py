"""Instruction cycle counts.

Validation strategy, since a cycle count cannot be derived from first
principles the way a decimal sum can:

1.  Every documented opcode's base count is asserted against a
    TRANSCRIBED PUBLISHED TABLE (below), entered opcode by opcode from the
    standard 6502 timing chart. The implementation derives its counts from
    a class-x-mode rule instead, so the two are independent constructions:
    a mistake in the rule table shows up as a mismatch here, and a typo in
    the transcription shows up as a mismatch too. They agree only if both
    are right.

2.  The two operand-dependent penalties (indexed read page crossing, taken
    and page-crossing branches) are asserted BEHAVIOURALLY by executing
    instructions and reading the delta, including the negative cases: a
    store or read-modify-write through the same addressing mode must NOT
    take the penalty, because it performs the fixup cycle unconditionally.

3.  Structural invariants that must hold for every opcode regardless of
    the table: 2 <= cycles <= 8, and everything is accounted for.

The counts are instruction-level accurate, not sub-instruction accurate:
cycles are charged once per instruction, so there is no model of when
within an instruction a particular bus access happens.
"""

import pytest

from nibbler.cpu import CPU6502, INTERRUPT_CYCLES
from .cpu_harness import ORG, make_cpu


# ── Published base cycle counts for the 151 documented opcodes ───────────
# Transcribed from the standard NMOS 6502 instruction timing chart. Values
# EXCLUDE the page-crossing and branch penalties (the "+1"s), which are
# tested behaviourally below.
PUBLISHED = {
    # ADC
    0x69: 2, 0x65: 3, 0x75: 4, 0x6D: 4, 0x7D: 4, 0x79: 4, 0x61: 6, 0x71: 5,
    # AND
    0x29: 2, 0x25: 3, 0x35: 4, 0x2D: 4, 0x3D: 4, 0x39: 4, 0x21: 6, 0x31: 5,
    # ASL
    0x0A: 2, 0x06: 5, 0x16: 6, 0x0E: 6, 0x1E: 7,
    # branches (not taken)
    0x90: 2, 0xB0: 2, 0xF0: 2, 0x30: 2, 0xD0: 2, 0x10: 2, 0x50: 2, 0x70: 2,
    # BIT
    0x24: 3, 0x2C: 4,
    # BRK
    0x00: 7,
    # CLC CLD CLI CLV
    0x18: 2, 0xD8: 2, 0x58: 2, 0xB8: 2,
    # CMP
    0xC9: 2, 0xC5: 3, 0xD5: 4, 0xCD: 4, 0xDD: 4, 0xD9: 4, 0xC1: 6, 0xD1: 5,
    # CPX CPY
    0xE0: 2, 0xE4: 3, 0xEC: 4, 0xC0: 2, 0xC4: 3, 0xCC: 4,
    # DEC DEX DEY
    0xC6: 5, 0xD6: 6, 0xCE: 6, 0xDE: 7, 0xCA: 2, 0x88: 2,
    # EOR
    0x49: 2, 0x45: 3, 0x55: 4, 0x4D: 4, 0x5D: 4, 0x59: 4, 0x41: 6, 0x51: 5,
    # INC INX INY
    0xE6: 5, 0xF6: 6, 0xEE: 6, 0xFE: 7, 0xE8: 2, 0xC8: 2,
    # JMP JSR
    0x4C: 3, 0x6C: 5, 0x20: 6,
    # LDA
    0xA9: 2, 0xA5: 3, 0xB5: 4, 0xAD: 4, 0xBD: 4, 0xB9: 4, 0xA1: 6, 0xB1: 5,
    # LDX LDY
    0xA2: 2, 0xA6: 3, 0xB6: 4, 0xAE: 4, 0xBE: 4,
    0xA0: 2, 0xA4: 3, 0xB4: 4, 0xAC: 4, 0xBC: 4,
    # LSR
    0x4A: 2, 0x46: 5, 0x56: 6, 0x4E: 6, 0x5E: 7,
    # NOP
    0xEA: 2,
    # ORA
    0x09: 2, 0x05: 3, 0x15: 4, 0x0D: 4, 0x1D: 4, 0x19: 4, 0x01: 6, 0x11: 5,
    # stack
    0x48: 3, 0x08: 3, 0x68: 4, 0x28: 4,
    # ROL ROR
    0x2A: 2, 0x26: 5, 0x36: 6, 0x2E: 6, 0x3E: 7,
    0x6A: 2, 0x66: 5, 0x76: 6, 0x6E: 6, 0x7E: 7,
    # RTI RTS
    0x40: 6, 0x60: 6,
    # SBC
    0xE9: 2, 0xE5: 3, 0xF5: 4, 0xED: 4, 0xFD: 4, 0xF9: 4, 0xE1: 6, 0xF1: 5,
    # SEC SED SEI
    0x38: 2, 0xF8: 2, 0x78: 2,
    # STA
    0x85: 3, 0x95: 4, 0x8D: 4, 0x9D: 5, 0x99: 5, 0x81: 6, 0x91: 6,
    # STX STY
    0x86: 3, 0x96: 4, 0x8E: 4, 0x84: 3, 0x94: 4, 0x8C: 4,
    # transfers
    0xAA: 2, 0xA8: 2, 0xBA: 2, 0x8A: 2, 0x9A: 2, 0x98: 2,
}

# Undocumented opcodes, same source ("NMOS 6510 Unintended Opcodes").
PUBLISHED_UNDOC = {
    # SLO RLA SRE RRA DCP ISB -- all RMW, identical timing per mode
    **{o: 5 for o in (0x07, 0x27, 0x47, 0x67, 0xC7, 0xE7)},
    **{o: 6 for o in (0x17, 0x37, 0x57, 0x77, 0xD7, 0xF7)},
    **{o: 6 for o in (0x0F, 0x2F, 0x4F, 0x6F, 0xCF, 0xEF)},
    **{o: 7 for o in (0x1F, 0x3F, 0x5F, 0x7F, 0xDF, 0xFF)},
    **{o: 7 for o in (0x1B, 0x3B, 0x5B, 0x7B, 0xDB, 0xFB)},
    **{o: 8 for o in (0x03, 0x23, 0x43, 0x63, 0xC3, 0xE3)},
    **{o: 8 for o in (0x13, 0x33, 0x53, 0x73, 0xD3, 0xF3)},
    # LAX
    0xA7: 3, 0xB7: 4, 0xAF: 4, 0xBF: 4, 0xA3: 6, 0xB3: 5,
    # SAX
    0x87: 3, 0x97: 4, 0x8F: 4, 0x83: 6,
    # immediates
    0x0B: 2, 0x2B: 2, 0x4B: 2, 0x6B: 2, 0x8B: 2, 0xAB: 2, 0xCB: 2, 0xEB: 2,
    # SH* family and LAS
    0x9C: 5, 0x9E: 5, 0x9F: 5, 0x93: 6, 0x9B: 5, 0xBB: 4,
    # undocumented NOPs
    **{o: 2 for o in (0x1A, 0x3A, 0x5A, 0x7A, 0xDA, 0xFA)},
    **{o: 2 for o in (0x80, 0x82, 0x89, 0xC2, 0xE2)},
    **{o: 3 for o in (0x04, 0x44, 0x64)},
    **{o: 4 for o in (0x14, 0x34, 0x54, 0x74, 0xD4, 0xF4)},
    0x0C: 4,
    **{o: 4 for o in (0x1C, 0x3C, 0x5C, 0x7C, 0xDC, 0xFC)},
}


@pytest.fixture(scope="module")
def optable():
    return CPU6502().optable


@pytest.mark.parametrize("opcode", sorted(PUBLISHED))
def test_documented_base_cycles_match_the_published_table(optable, opcode):
    handler, mode, size, name, cycles = optable[opcode]
    assert cycles == PUBLISHED[opcode], \
        f"${opcode:02X} {name}: table says {cycles}, published says {PUBLISHED[opcode]}"


@pytest.mark.parametrize("opcode", sorted(PUBLISHED_UNDOC))
def test_undocumented_base_cycles_match_the_published_table(optable, opcode):
    handler, mode, size, name, cycles = optable[opcode]
    assert cycles == PUBLISHED_UNDOC[opcode], \
        f"${opcode:02X} {name}: table says {cycles}, published says " \
        f"{PUBLISHED_UNDOC[opcode]}"


def test_the_published_tables_cover_every_opcode_except_kil(optable):
    """No opcode may quietly escape both transcribed tables."""
    covered = set(PUBLISHED) | set(PUBLISHED_UNDOC)
    kils = {i for i, e in enumerate(optable) if e[3] == "KIL"}
    missing = sorted(set(range(256)) - covered - kils)
    assert missing == [], f"opcodes with no published count asserted: " \
                          f"{[hex(m) for m in missing]}"


def test_kil_is_documented_as_a_convention(optable):
    """A jammed CPU never completes, so its 'cycle count' is a convention.

    2 is used, matching the fetch-and-hang, and it is never accumulated
    more than once because the CPU halts.
    """
    for opcode in (0x02, 0x12, 0x22, 0x32, 0x42, 0x52,
                   0x62, 0x72, 0x92, 0xB2, 0xD2, 0xF2):
        assert optable[opcode][4] == 2


def test_every_base_count_is_in_the_physically_possible_range(optable):
    for i, (_, _, _, name, cycles) in enumerate(optable):
        assert 2 <= cycles <= 8, f"${i:02X} {name}: implausible base {cycles}"


# ── Behavioural: the page-crossing read penalty ──────────────────────────

def cycles_for(*program, org=ORG, **state):
    """Run one instruction and return the cycles it charged."""
    cpu = make_cpu(*program, org=org, **state)
    before = cpu.cycles
    cpu.step()
    return cpu.cycles - before


@pytest.mark.parametrize("opcode,mode_name,index_reg", [
    (0xBD, "abs,X", "x"),      # LDA abs,X
    (0xB9, "abs,Y", "y"),      # LDA abs,Y
    (0xBC, "abs,X", "x"),      # LDY abs,X
    (0xBE, "abs,Y", "y"),      # LDX abs,Y
    (0xDD, "abs,X", "x"),      # CMP abs,X
    (0x3D, "abs,X", "x"),      # AND abs,X
    (0x7D, "abs,X", "x"),      # ADC abs,X
    (0xBF, "abs,Y", "y"),      # LAX abs,Y (undocumented)
    (0xBB, "abs,Y", "y"),      # LAS abs,Y (undocumented)
])
def test_indexed_read_costs_one_more_when_the_index_carries(
        opcode, mode_name, index_reg):
    no_cross = cycles_for(opcode, 0x00, 0x30, **{index_reg: 0x10})   # $3000+$10
    crossed = cycles_for(opcode, 0xF0, 0x30, **{index_reg: 0x20})    # $30F0+$20
    assert crossed == no_cross + 1, \
        f"${opcode:02X} {mode_name}: {no_cross} without crossing, {crossed} with"


def test_izy_read_costs_one_more_when_the_index_carries():
    def run(ptr_lo, ptr_hi, y):
        cpu = make_cpu(0xB1, 0x40, y=y)          # LDA ($40),Y
        cpu.mem[0x40] = ptr_lo
        cpu.mem[0x41] = ptr_hi
        before = cpu.cycles
        cpu.step()
        return cpu.cycles - before

    assert run(0x00, 0x30, 0x10) == 5
    assert run(0xF0, 0x30, 0x20) == 6


@pytest.mark.parametrize("opcode,index_reg,expected", [
    (0x9D, "x", 5),      # STA abs,X -- always 5, never 6
    (0x99, "y", 5),      # STA abs,Y
    (0x91, "y", 6),      # STA (zp),Y -- always 6
    (0x1E, "x", 7),      # ASL abs,X -- RMW, always 7
    (0xFE, "x", 7),      # INC abs,X
    (0xDF, "x", 7),      # DCP abs,X (undocumented RMW)
    (0x9E, "y", 5),      # SHX abs,Y (undocumented store)
])
def test_stores_and_rmw_never_take_the_page_crossing_penalty(
        opcode, index_reg, expected):
    """They perform the fixup cycle unconditionally, so the cost is constant.

    This is the half of the rule that a naive "+1 on any page cross"
    implementation gets wrong.
    """
    def run(lo, hi, index):
        cpu = make_cpu(opcode, lo, hi, **{index_reg: index})
        cpu.mem[0x40] = 0x00
        cpu.mem[0x41] = 0x30
        before = cpu.cycles
        cpu.step()
        return cpu.cycles - before

    if opcode == 0x91:                      # (zp),Y form takes a zp operand
        cpu = make_cpu(0x91, 0x40, y=0x20)
        cpu.mem[0x40] = 0xF0
        cpu.mem[0x41] = 0x30
        before = cpu.cycles
        cpu.step()
        assert cpu.cycles - before == expected
        return

    assert run(0x00, 0x30, 0x10) == expected, "no crossing"
    assert run(0xF0, 0x30, 0x20) == expected, "crossing must NOT add a cycle"


def test_a_page_cross_in_a_store_does_not_leak_into_the_next_instruction():
    """The flag is per-instruction; a stale 1 would over-charge the next read."""
    cpu = make_cpu(0x9D, 0xF0, 0x30,        # STA $30F0,X  (crosses)
                   0xA5, 0x40,              # LDA $40      (3 cycles, no index)
                   x=0x20)
    cpu.step()
    before = cpu.cycles
    cpu.step()
    assert cpu.cycles - before == 3


def test_non_indexed_modes_never_take_the_penalty():
    assert cycles_for(0xA5, 0x40) == 3           # LDA zp
    assert cycles_for(0xAD, 0xFF, 0x30) == 4     # LDA abs at a page end
    assert cycles_for(0xA9, 0x40) == 2           # LDA #imm


# ── Behavioural: branch penalties ────────────────────────────────────────

def test_branch_not_taken_costs_two():
    assert cycles_for(0xD0, 0x10, Z=1) == 2      # BNE with Z set: not taken


def test_branch_taken_costs_three():
    assert cycles_for(0xD0, 0x10, Z=0) == 3      # forward, same page


def test_branch_taken_across_a_page_costs_four():
    # At $02F0, BNE +$20 lands at $0312: a different page from $02F2.
    assert cycles_for(0xD0, 0x20, org=0x02F0, Z=0) == 4


def test_backward_branch_across_a_page_costs_four():
    # At $0301, BNE -$20 lands at $02E3: a different page from $0303.
    assert cycles_for(0xD0, 0xE0, org=0x0301, Z=0) == 4


def test_branch_page_test_is_against_the_next_instruction_not_the_branch():
    """At $02FE the branch instruction is in page $02 but PC+2 is $0300.

    A branch to $0310 from there crosses no page relative to $0300, so it
    must cost 3, not 4. Comparing against the branch's own address instead
    would wrongly charge 4.
    """
    assert cycles_for(0xD0, 0x0E, org=0x02FE, Z=0) == 3


@pytest.mark.parametrize("opcode,flag,value", [
    (0x90, "C", 0), (0xB0, "C", 1), (0xF0, "Z", 1), (0xD0, "Z", 0),
    (0x10, "N", 0), (0x30, "N", 1), (0x50, "V", 0), (0x70, "V", 1),
])
def test_all_eight_branches_share_the_penalty_rule(opcode, flag, value):
    taken = cycles_for(opcode, 0x10, **{flag: value})
    not_taken = cycles_for(opcode, 0x10, **{flag: 1 - value})
    assert (taken, not_taken) == (3, 2)


# ── Interrupts ───────────────────────────────────────────────────────────

def test_interrupt_sequences_cost_seven_cycles():
    for take in ("irq", "nmi"):
        cpu = make_cpu(0xEA, I=0)
        before = cpu.cycles
        getattr(cpu, take)()
        assert cpu.cycles - before == INTERRUPT_CYCLES

    cpu = CPU6502()
    before = cpu.cycles
    cpu.reset()
    assert cpu.cycles - before == INTERRUPT_CYCLES


def test_a_masked_irq_costs_nothing():
    cpu = make_cpu(0xEA, I=1)
    before = cpu.cycles
    assert cpu.irq() is False
    assert cpu.cycles == before


def test_step_charges_seven_for_a_serviced_interrupt_and_runs_no_instruction():
    cpu = make_cpu(0xEA)
    cpu.mem[0xFFFA] = 0x00
    cpu.mem[0xFFFB] = 0x90
    cpu.set_nmi()
    before = cpu.cycles
    cpu.step()
    assert cpu.cycles - before == INTERRUPT_CYCLES
    assert cpu.exec_count == 0


# ── Accumulation ─────────────────────────────────────────────────────────

def test_cycles_accumulate_over_a_known_sequence():
    """A hand-counted program: 2 + 2 + 3 + 4 + 6 + 6 = 23 cycles, 6 instructions."""
    cpu = make_cpu(
        0xA9, 0x05,          # LDA #$05        2
        0xA2, 0x00,          # LDX #$00        2
        0x85, 0x40,          # STA $40         3
        0x8D, 0x00, 0x30,    # STA $3000       4
        0x20, 0x00, 0x40,    # JSR $4000       6
    )
    cpu.mem[0x4000] = 0x60   # RTS             6
    for _ in range(6):
        cpu.step()
    assert cpu.pc == ORG + 12, "RTS should have returned past the JSR"
    assert cpu.cycles == 23
    assert cpu.exec_count == 6


def test_exec_count_and_cycles_are_separate_counters():
    """`cycles` used to be the instruction counter; `exec_count` still is."""
    cpu = make_cpu(0x20, 0x00, 0x40)     # JSR: 1 instruction, 6 cycles
    cpu.mem[0x4000] = 0xEA
    cpu.step()
    assert cpu.exec_count == 1
    assert cpu.cycles == 6
