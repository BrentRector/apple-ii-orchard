"""Undocumented NMOS 6502 opcodes, with the unstable ones called out.

Three grades of claim are made here, and they are not equal:

  STABLE       LAX/SAX/DCP/ISB/SLO/RLA/SRE/RRA/ANC/ALR/AXS/LAS and the
               undocumented NOPs are deterministic on real silicon and are
               asserted exactly, against the "documented equivalent"
               decomposition (e.g. SLO == ASL then ORA on the same address).

  DETERMINISTIC-BUT-WEIRD
               ARR's flag behaviour and the SH* family's page-crossing
               address corruption. Deterministic on hardware, asserted
               exactly, sourced from "NMOS 6510 Unintended Opcodes"
               (Groepaz/Hitmen) and "64doc" (West & Makela).

  ANALOG       The "& (H+1)" term of the SH* family can drop out, and the
               magic constant in XAA/LAX#imm is a floating bus value.
               Neither has a deterministic answer. The tests below assert
               the CONVENTION the core implements and say so; they are not
               claims about silicon.
"""

import pytest

from nibbler.cpu import CPU6502
from .cpu_harness import ORG, make_cpu, run_one


# ── Opcode map completeness ──────────────────────────────────────────────

def test_every_opcode_slot_is_a_named_instruction():
    """No slot may be left on the 'unassigned' filler.

    _build_opcodes() ends by filling anything still None with a 1-byte NOP
    named '?XX'. Such a slot is a gap, not a decision: it gets the wrong
    length as well as the wrong behaviour. $AB (LAX #imm) used to be one.
    """
    cpu = CPU6502()
    unassigned = [f"${i:02X}" for i, e in enumerate(cpu.optable)
                  if e[3].startswith("?")]
    assert unassigned == [], f"unassigned opcode slots: {unassigned}"


def test_opcode_sizes_match_their_addressing_modes():
    from nibbler.cpu import MODE_SIZE
    cpu = CPU6502()
    for i, (_, mode, size, name) in enumerate(cpu.optable):
        assert size == MODE_SIZE[mode], \
            f"${i:02X} {name}: size {size} but mode implies {MODE_SIZE[mode]}"


def test_kil_opcodes_are_the_twelve_real_ones():
    cpu = CPU6502()
    kils = [i for i, e in enumerate(cpu.optable) if e[3] == "KIL"]
    assert kils == [0x02, 0x12, 0x22, 0x32, 0x42, 0x52,
                    0x62, 0x72, 0x92, 0xB2, 0xD2, 0xF2]


# ── Stable undocumented ops == their documented decomposition ────────────
# Each of these is asserted against the two-instruction sequence it is
# equivalent to, run on a separate CPU. That is a real oracle: the
# reference path uses only official opcodes.

def _run_pair(first, second, zp_value, **state):
    """Run `first zp` then `second zp` on one CPU; return (A, X, mem[zp], flags)."""
    cpu = make_cpu(first, 0x40, second, 0x40, **state)
    cpu.mem[0x40] = zp_value
    cpu.step()
    cpu.step()
    return cpu.a, cpu.x, cpu.mem[0x40], (cpu.N, cpu.V, cpu.Z, cpu.C)


def _run_single(opcode, zp_value, **state):
    """Run one zero-page instruction; return (A, X, mem[zp], flags)."""
    cpu = make_cpu(opcode, 0x40, **state)
    cpu.mem[0x40] = zp_value
    cpu.step()
    return cpu.a, cpu.x, cpu.mem[0x40], (cpu.N, cpu.V, cpu.Z, cpu.C)


@pytest.mark.parametrize("combo,doc_first,doc_second,name", [
    (0x07, 0x06, 0x05, "SLO == ASL zp then ORA zp"),
    (0x27, 0x26, 0x25, "RLA == ROL zp then AND zp"),
    (0x47, 0x46, 0x45, "SRE == LSR zp then EOR zp"),
    (0x67, 0x66, 0x65, "RRA == ROR zp then ADC zp"),
    (0xC7, 0xC6, 0xC5, "DCP == DEC zp then CMP zp"),
    (0xE7, 0xE6, 0xE5, "ISB == INC zp then SBC zp"),
])
@pytest.mark.parametrize("a", [0x00, 0x01, 0x7F, 0x80, 0xFF, 0x5A])
@pytest.mark.parametrize("mem", [0x00, 0x01, 0x7F, 0x80, 0xFF, 0xA5])
@pytest.mark.parametrize("carry", [0, 1])
def test_rmw_combo_matches_documented_decomposition(combo, doc_first, doc_second,
                                                    name, a, mem, carry):
    got = _run_single(combo, mem, a=a, C=carry)
    want = _run_pair(doc_first, doc_second, mem, a=a, C=carry)
    assert got == want, name


@pytest.mark.parametrize("decimal", [0, 1])
def test_rra_and_isb_honour_the_decimal_flag(decimal):
    """RRA and ISB share the ALU with ADC/SBC, so D applies to them too."""
    rra = _run_single(0x67, 0x02, a=0x19, C=1, D=decimal)
    ror_adc = _run_pair(0x66, 0x65, 0x02, a=0x19, C=1, D=decimal)
    assert rra == ror_adc
    isb = _run_single(0xE7, 0x02, a=0x19, C=1, D=decimal)
    inc_sbc = _run_pair(0xE6, 0xE5, 0x02, a=0x19, C=1, D=decimal)
    assert isb == inc_sbc


def test_lax_loads_both_a_and_x():
    cpu = make_cpu(0xA7, 0x40)          # LAX $40
    cpu.mem[0x40] = 0x80
    cpu.step()
    assert cpu.a == cpu.x == 0x80 and cpu.N == 1 and cpu.Z == 0


def test_sax_stores_a_and_x_and_touches_no_flags():
    cpu = make_cpu(0x87, 0x40, a=0xCC, x=0xAA, N=1, V=1, Z=1, C=1)   # SAX $40
    cpu.step()
    assert cpu.mem[0x40] == 0xCC & 0xAA
    assert (cpu.N, cpu.V, cpu.Z, cpu.C) == (1, 1, 1, 1)


def test_anc_copies_the_sign_bit_into_carry():
    for a, imm in [(0xFF, 0x80), (0x7F, 0x80), (0xF0, 0xF0), (0x0F, 0xF0)]:
        cpu = run_one(0x0B, imm, a=a)                 # ANC #imm
        assert cpu.a == a & imm
        assert cpu.C == cpu.N == ((a & imm) >> 7) & 1


def test_alr_is_and_then_lsr():
    for a, imm in [(0xFF, 0x03), (0xAA, 0xFF), (0x01, 0x01)]:
        cpu = run_one(0x4B, imm, a=a)                 # ALR #imm
        anded = a & imm
        assert cpu.a == anded >> 1
        assert cpu.C == anded & 1


def test_axs_subtracts_without_borrow_and_sets_carry_like_cmp():
    for a, x, imm in [(0xFF, 0x0F, 0x01), (0x0F, 0x0F, 0x10), (0xF0, 0xFF, 0xF0)]:
        cpu = run_one(0xCB, imm, a=a, x=x, C=0)       # AXS #imm; C ignored on input
        result = (a & x) - imm
        assert cpu.x == result & 0xFF
        assert cpu.C == (0 if result < 0 else 1)


def test_las_ands_memory_with_sp_into_a_x_and_sp():
    cpu = make_cpu(0xBB, 0x00, 0x30, y=0x05, sp=0x3C)   # LAS $3000,Y
    cpu.mem[0x3005] = 0xF0
    cpu.step()
    assert cpu.a == cpu.x == cpu.sp == (0xF0 & 0x3C)


# ── ARR: deterministic but weird ─────────────────────────────────────────

def test_arr_takes_carry_from_bit_6_and_overflow_from_bits_6_xor_5():
    for a, imm, cin in [(0xFF, 0xFF, 0), (0xFF, 0xFF, 1), (0x40, 0xFF, 0),
                        (0x80, 0xFF, 0), (0x60, 0xFF, 0), (0x00, 0xFF, 1)]:
        cpu = run_one(0x6B, imm, a=a, C=cin, D=0)     # ARR #imm
        expect = ((a & imm) >> 1) | (cin << 7)
        assert cpu.a == expect
        assert cpu.C == (expect >> 6) & 1
        assert cpu.V == (((expect >> 6) ^ (expect >> 5)) & 1)


def test_arr_in_decimal_mode_applies_the_bcd_fixup():
    """Documented 64doc behaviour: N is the OLD carry, and the nibble fixups
    run on the rotated value. Asserted against that algorithm only."""
    for a, imm, cin in [(0x99, 0xFF, 0), (0x88, 0xFF, 1), (0x0F, 0xFF, 0),
                        (0xF0, 0xFF, 0), (0x55, 0xFF, 1)]:
        cpu = run_one(0x6B, imm, a=a, C=cin, D=1)
        val = a & imm
        rot = ((val >> 1) | (cin << 7)) & 0xFF
        want = rot
        if (val & 0x0F) + (val & 0x01) > 0x05:
            want = (want & 0xF0) | ((want + 0x06) & 0x0F)
        want_c = 1 if (val & 0xF0) + (val & 0x10) > 0x50 else 0
        if want_c:
            want = (want + 0x60) & 0xFF
        assert (cpu.a, cpu.C, cpu.N) == (want, want_c, cin)


# ── The SH* family: value AND (H+1), and the page-crossing corruption ────

# Each entry pins the source register(s) to $01 and the index register to
# $20, so the value stored ($01 & (H+1)) differs from the high byte of the
# arithmetic address. Without that the corrupted and uncorrupted addresses
# can coincide and the test proves nothing.
SH_FAMILY = [
    # opcode, name,  index register, register state,           source value
    (0x9C, "SHY", "x", dict(y=0x01, x=0x20),                    0x01),
    (0x9E, "SHX", "y", dict(x=0x01, y=0x20),                    0x01),
    (0x9F, "AHX", "y", dict(a=0xFF, x=0x01, y=0x20),            0x01),
    (0x9B, "TAS", "y", dict(a=0xFF, x=0x01, y=0x20),            0x01),
]


@pytest.mark.parametrize("opcode,name,index_reg,state,src", SH_FAMILY)
def test_sh_family_ands_the_stored_value_with_base_high_plus_one(
        opcode, name, index_reg, state, src):
    """No page crossing: value is R & (H+1) and the address is the plain sum."""
    base = 0x2F00                       # high byte $2F, so the mask is $30
    index = state[index_reg]
    cpu = make_cpu(opcode, base & 0xFF, base >> 8, **state)
    cpu.step()
    assert cpu.mem[base + index] == src & 0x30, f"{name} stored the wrong value"
    assert cpu.mem[base] == 0x00, "nothing should land at the unindexed base"


@pytest.mark.parametrize("opcode,name,index_reg,state,src", SH_FAMILY)
def test_sh_family_corrupts_the_target_page_when_the_index_carries(
        opcode, name, index_reg, state, src):
    """When the index carries into the high byte, the stored value REPLACES it.

    Base $12F0 indexed by $20: the arithmetic address is $1310, but the
    value stored is R & ($12 + 1) = $01, and the carry makes that same $01
    become the high byte of the target. The byte lands at $0110, four
    kilobytes away from where the address arithmetic says.
    """
    base = 0x12F0
    index = state[index_reg]
    cpu = make_cpu(opcode, base & 0xFF, base >> 8, **state)
    cpu.step()

    value = src & (((base >> 8) + 1) & 0xFF)          # $01 & $13 = $01
    arithmetic_addr = (base + index) & 0xFFFF          # $1310
    corrupted_addr = (arithmetic_addr & 0x00FF) | (value << 8)   # $0110
    assert corrupted_addr != arithmetic_addr, "test setup must separate the two"

    assert cpu.mem[corrupted_addr] == value, f"{name} did not corrupt the page"
    assert cpu.mem[arithmetic_addr] == 0x00, \
        f"{name} must NOT land at the address the arithmetic implies"


def test_ahx_indirect_indexed_uses_the_pointer_as_the_base():
    """AHX ($93) takes its base from the zero-page pointer, not the operand."""
    cpu = make_cpu(0x93, 0x40, a=0xFF, x=0xFF, y=0x10)   # AHX ($40),Y
    cpu.mem[0x40] = 0x00
    cpu.mem[0x41] = 0x2F                                 # pointer -> $2F00
    cpu.step()
    assert cpu.mem[0x2F10] == 0xFF & 0x30


def test_tas_sets_sp_to_a_and_x():
    cpu = make_cpu(0x9B, 0x00, 0x2F, a=0xF0, x=0x3C, y=0x10)   # TAS $2F00,Y
    cpu.step()
    assert cpu.sp == 0xF0 & 0x3C
    assert cpu.mem[0x2F10] == (0xF0 & 0x3C) & 0x30


def test_sh_family_affects_no_flags():
    for opcode in (0x9C, 0x9E, 0x9F, 0x9B):
        cpu = make_cpu(opcode, 0x00, 0x2F, a=0xFF, x=0x05, y=0x05,
                       N=1, V=1, Z=1, C=1)
        cpu.step()
        assert (cpu.N, cpu.V, cpu.Z, cpu.C) == (1, 1, 1, 1)


# ── The analog immediates: convention, not silicon ───────────────────────

def test_xaa_default_convention_is_a_equals_x_and_imm():
    """magic_constant defaults to $FF, so the A term drops out.

    This is a CONVENTION. Real hardware has no single answer here: the
    magic term is a floating bus value that varies with chip, temperature
    and supply.
    """
    for a, x, imm in [(0x00, 0xFF, 0x0F), (0xFF, 0x3C, 0xF0), (0x55, 0xAA, 0xFF)]:
        cpu = run_one(0x8B, imm, a=a, x=x)
        assert cpu.a == x & imm


def test_xaa_honours_a_different_magic_constant():
    cpu = make_cpu(0x8B, 0xFF, a=0x11, x=0xFF)
    cpu.magic_constant = 0xEE                 # VICE's 6510 default
    cpu.step()
    assert cpu.a == (0x11 | 0xEE) & 0xFF & 0xFF


def test_lax_immediate_is_two_bytes_and_loads_both_registers():
    """$AB used to fall through to the 1-byte filler NOP: wrong length too."""
    cpu = run_one(0xAB, 0x3C, a=0x00, x=0x00)
    assert cpu.a == cpu.x == 0x3C
    assert cpu.pc == ORG + 2, "LAX #imm must consume its operand byte"


def test_lax_immediate_sets_n_and_z():
    assert run_one(0xAB, 0x00).Z == 1
    assert run_one(0xAB, 0x80).N == 1


def test_lax_immediate_honours_the_magic_constant():
    cpu = make_cpu(0xAB, 0xFF, a=0x11)
    cpu.magic_constant = 0xEE
    cpu.step()
    assert cpu.a == cpu.x == (0x11 | 0xEE) & 0xFF


# ── Undocumented NOPs consume the right number of bytes ──────────────────

@pytest.mark.parametrize("opcode,size", [
    (0x1A, 1), (0x3A, 1), (0x5A, 1), (0x7A, 1), (0xDA, 1), (0xFA, 1),
    (0x80, 2), (0x82, 2), (0x89, 2), (0xC2, 2), (0xE2, 2),
    (0x04, 2), (0x44, 2), (0x64, 2),
    (0x14, 2), (0x34, 2), (0x54, 2), (0x74, 2), (0xD4, 2), (0xF4, 2),
    (0x0C, 3),
    (0x1C, 3), (0x3C, 3), (0x5C, 3), (0x7C, 3), (0xDC, 3), (0xFC, 3),
])
def test_undocumented_nops_advance_pc_by_their_size(opcode, size):
    cpu = run_one(opcode, 0x00, 0x00)
    assert cpu.pc == ORG + size


def test_eb_is_a_mirror_of_sbc_immediate():
    a = run_one(0xEB, 0x10, a=0x50, C=1)
    b = run_one(0xE9, 0x10, a=0x50, C=1)
    assert (a.a, a.N, a.V, a.Z, a.C) == (b.a, b.N, b.V, b.Z, b.C)


def test_kil_halts_and_stays_halted():
    cpu = run_one(0x02)
    assert cpu.halted
    assert cpu.step() is False
