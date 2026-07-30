"""Decimal (BCD) mode arithmetic for ADC and SBC on the NMOS 6502.

The oracle strategy, in decreasing order of independence:

1.  VALID BCD (both nibbles 0-9) -- checked against decimal arithmetic done
    in Python ints.  This is a genuinely non-circular oracle: nothing about
    the expected value comes from the emulator.  100 x 100 x 2 carry values
    = 20,000 cases for each of ADC and SBC.

2.  Properties that hold for ALL operands and are independently derivable
    from the NMOS rules, so they need no reference implementation:
      * ADC decimal Z == ADC binary Z (Z is computed before any adjust).
      * SBC decimal N/V/Z/C == SBC binary N/V/Z/C (only A is adjusted).
    Checked over all 256 x 256 x 2 = 131,072 operand pairs.

3.  INVALID BCD (a nibble > 9) -- no external truth exists, because the
    result has no decimal meaning; it is whatever the hardware's sequence
    produces.  Those cases are asserted against ``ref_adc_decimal`` /
    ``ref_sbc_decimal`` below, which are transcriptions of the published
    NMOS algorithm ("64doc", John West & Marko Makela, Appendix A).  The
    pseudocode is quoted in each function's docstring so the transcription
    can be checked against the source by eye.  These tests prove the
    implementation matches the documented algorithm; they cannot prove the
    documented algorithm matches silicon.

Plus a handful of published worked examples as fixed anchors.
"""

import pytest

from nibbler.cpu import CPU6502
from .cpu_harness import ORG, VALID_BCD, from_bcd, to_bcd, run_one

ADC_IMM = 0x69
SBC_IMM = 0xE9


# ── Reference implementations (documented algorithm, category 3) ─────────

def ref_adc_decimal(a, val, carry_in):
    """NMOS decimal ADC, transcribed from the published algorithm.

    64doc, Appendix A ("Decimal mode in NMOS 6500 series"):

        1. AL = (A & $0F) + (B & $0F) + C
        2. If AL >= $0A, then AL = ((AL + $06) & $0F) + $10
        3. A = (A & $F0) + (B & $F0) + AL
        4. Note that A can be >= $100 at this point
        5. If A >= $A0, then A = A + $60
        6. The accumulator result is the lower 8 bits of A
        7. The carry result is 1 if A >= $100, and is 0 if A < $100

        The Z flag is computed before performing any decimal adjust:
            Z = ((A + B + C) & $FF) == 0
        The N and V flags are computed after step 3 (low-nibble corrected,
        high-nibble not yet corrected).

    Returns (a_out, N, V, Z, C).
    """
    al = (a & 0x0F) + (val & 0x0F) + carry_in
    if al >= 0x0A:
        al = ((al + 0x06) & 0x0F) + 0x10
    s = (a & 0xF0) + (val & 0xF0) + al

    n = (s >> 7) & 1
    v = 1 if (~(a ^ val) & (a ^ s) & 0x80) else 0
    z = 1 if ((a + val + carry_in) & 0xFF) == 0 else 0

    if s >= 0xA0:
        s += 0x60
    c = 1 if s >= 0x100 else 0
    return s & 0xFF, n, v, z, c


def ref_sbc_decimal(a, val, carry_in):
    """NMOS decimal SBC, transcribed from the published algorithm.

    64doc, Appendix A:

        1. AL = (A & $0F) - (B & $0F) + C - 1
        2. If AL < 0, then AL = ((AL - $06) & $0F) - $10
        3. A = (A & $F0) - (B & $F0) + AL
        4. If A < 0, then A = A - $60
        5. The accumulator result is the lower 8 bits of A

        N, V, Z and C are set exactly as in binary mode.

    Returns (a_out, N, V, Z, C).
    """
    borrow = 1 - carry_in
    binary = a - val - borrow

    n = (binary >> 7) & 1
    v = 1 if ((a ^ val) & (a ^ (binary & 0xFF)) & 0x80) else 0
    z = 1 if (binary & 0xFF) == 0 else 0
    c = 0 if binary < 0 else 1

    al = (a & 0x0F) - (val & 0x0F) - borrow
    if al < 0:
        al = ((al - 0x06) & 0x0F) - 0x10
    s = (a & 0xF0) - (val & 0xF0) + al
    if s < 0:
        s -= 0x60
    return s & 0xFF, n, v, z, c


# ── Fast driver ──────────────────────────────────────────────────────────
# One CPU reused across tens of thousands of cases: building a CPU6502
# allocates 64 KB and a 256-entry dispatch table, which would dominate the
# runtime if done per case.

def _sweep(opcode, a, val, carry_in, decimal, cpu):
    """Execute one immediate-mode ADC/SBC and return (A, N, V, Z, C)."""
    cpu.mem[ORG] = opcode
    cpu.mem[ORG + 1] = val
    cpu.pc = ORG
    cpu.a = a
    cpu.C = carry_in
    cpu.D = 1 if decimal else 0
    cpu.N = cpu.V = cpu.Z = 0
    cpu.step()
    return cpu.a, cpu.N, cpu.V, cpu.Z, cpu.C


@pytest.fixture(scope="module")
def cpu():
    return CPU6502()


# ── Category 1: valid BCD vs. Python decimal arithmetic ──────────────────

def test_adc_decimal_valid_bcd_against_python_arithmetic(cpu):
    """ADC over all 100 x 100 x 2 valid-BCD cases (20,000).

    Expected A and C come from Python integer arithmetic on the decimal
    values -- no reference implementation of the 6502 algorithm involved.
    """
    for a in VALID_BCD:
        for val in VALID_BCD:
            for carry_in in (0, 1):
                got_a, _, _, _, got_c = _sweep(ADC_IMM, a, val, carry_in, True, cpu)
                total = from_bcd(a) + from_bcd(val) + carry_in
                assert got_a == to_bcd(total % 100), (
                    f"ADC ${a:02X} + ${val:02X} + {carry_in}: "
                    f"A=${got_a:02X}, expected ${to_bcd(total % 100):02X}"
                )
                assert got_c == (1 if total >= 100 else 0), (
                    f"ADC ${a:02X} + ${val:02X} + {carry_in}: "
                    f"C={got_c}, expected {1 if total >= 100 else 0}"
                )


def test_sbc_decimal_valid_bcd_against_python_arithmetic(cpu):
    """SBC over all 100 x 100 x 2 valid-BCD cases (20,000).

    Expected A and C come from Python integer arithmetic. C is the *borrow*
    output: 1 when no borrow was needed, 0 when the result went negative.
    """
    for a in VALID_BCD:
        for val in VALID_BCD:
            for carry_in in (0, 1):
                got_a, _, _, _, got_c = _sweep(SBC_IMM, a, val, carry_in, True, cpu)
                diff = from_bcd(a) - from_bcd(val) - (1 - carry_in)
                assert got_a == to_bcd(diff % 100), (
                    f"SBC ${a:02X} - ${val:02X} - {1 - carry_in}: "
                    f"A=${got_a:02X}, expected ${to_bcd(diff % 100):02X}"
                )
                assert got_c == (0 if diff < 0 else 1), (
                    f"SBC ${a:02X} - ${val:02X} - {1 - carry_in}: "
                    f"C={got_c}, expected {0 if diff < 0 else 1}"
                )


def test_adc_decimal_zero_flag_is_the_binary_zero_flag(cpu):
    """ADC decimal Z is computed from the BINARY sum, before any adjust.

    Independently checkable without a reference implementation: run the same
    operands with D=0 and D=1 and require identical Z. Covers all 131,072
    operand pairs, valid BCD or not.
    """
    for a in range(256):
        for val in range(256):
            for carry_in in (0, 1):
                _, _, _, z_dec, _ = _sweep(ADC_IMM, a, val, carry_in, True, cpu)
                _, _, _, z_bin, _ = _sweep(ADC_IMM, a, val, carry_in, False, cpu)
                assert z_dec == z_bin, (
                    f"ADC ${a:02X}+${val:02X}+{carry_in}: "
                    f"decimal Z={z_dec} but binary Z={z_bin}"
                )


def test_sbc_decimal_flags_equal_binary_flags(cpu):
    """SBC decimal sets N, V, Z and C exactly as binary mode does.

    Only A is decimal-adjusted. Independently checkable by running each
    operand pair both ways; covers all 131,072 pairs.
    """
    for a in range(256):
        for val in range(256):
            for carry_in in (0, 1):
                _, n1, v1, z1, c1 = _sweep(SBC_IMM, a, val, carry_in, True, cpu)
                _, n0, v0, z0, c0 = _sweep(SBC_IMM, a, val, carry_in, False, cpu)
                assert (n1, v1, z1, c1) == (n0, v0, z0, c0), (
                    f"SBC ${a:02X}-${val:02X} carry={carry_in}: decimal flags "
                    f"NVZC={n1}{v1}{z1}{c1} != binary {n0}{v0}{z0}{c0}"
                )


# ── Category 3: full operand space vs. the documented algorithm ──────────
# These include INVALID BCD (a nibble > 9), for which no decimal meaning
# exists -- the assertion is against the published NMOS sequence only.

def test_adc_decimal_matches_documented_algorithm_everywhere(cpu):
    """All 256 x 256 x 2 ADC cases match the transcribed NMOS algorithm."""
    for a in range(256):
        for val in range(256):
            for carry_in in (0, 1):
                got = _sweep(ADC_IMM, a, val, carry_in, True, cpu)
                assert got == ref_adc_decimal(a, val, carry_in), (
                    f"ADC ${a:02X}+${val:02X}+{carry_in}: got {got}, "
                    f"documented {ref_adc_decimal(a, val, carry_in)}"
                )


def test_sbc_decimal_matches_documented_algorithm_everywhere(cpu):
    """All 256 x 256 x 2 SBC cases match the transcribed NMOS algorithm."""
    for a in range(256):
        for val in range(256):
            for carry_in in (0, 1):
                got = _sweep(SBC_IMM, a, val, carry_in, True, cpu)
                assert got == ref_sbc_decimal(a, val, carry_in), (
                    f"SBC ${a:02X}-${val:02X} carry={carry_in}: got {got}, "
                    f"documented {ref_sbc_decimal(a, val, carry_in)}"
                )


# ── Published worked examples (fixed anchors) ────────────────────────────
# From the 6502.org decimal-mode appendix; these are the cases usually
# quoted to show that N and V come off a half-corrected value.

@pytest.mark.parametrize("a,val,carry_in,exp_a,exp_n,exp_v,exp_z,exp_c", [
    # A     M     Cin    A'     N  V  Z  C
    (0x00, 0x00, 0,    0x00,  0, 0, 1, 0),   # trivial
    (0x99, 0x01, 0,    0x00,  1, 0, 0, 1),   # 99+1 = 100 -> 00 carry out
    (0x50, 0x50, 0,    0x00,  1, 1, 0, 1),   # 50+50: V set off the partial sum
    (0x79, 0x00, 1,    0x80,  1, 1, 0, 0),   # 79+00+1 = 80, yet N=1 and V=1
    (0x24, 0x56, 0,    0x80,  1, 1, 0, 0),   # 24+56 = 80; V set (pos+pos -> bit7)
    (0x6F, 0x00, 1,    0x76,  0, 0, 0, 0),   # invalid BCD input: $6F -> $76
])
def test_adc_decimal_published_examples(cpu, a, val, carry_in,
                                        exp_a, exp_n, exp_v, exp_z, exp_c):
    assert _sweep(ADC_IMM, a, val, carry_in, True, cpu) == \
        (exp_a, exp_n, exp_v, exp_z, exp_c)


@pytest.mark.parametrize("a,val,carry_in,exp_a,exp_c", [
    (0x00, 0x01, 1,    0x99, 0),   # 0 - 1 borrows: 99 with C cleared
    (0x50, 0x25, 1,    0x25, 1),   # 50 - 25 = 25
    (0x00, 0x00, 1,    0x00, 1),   # trivial
    (0x12, 0x34, 1,    0x78, 0),   # 12 - 34 = -22 -> 78 with borrow
])
def test_sbc_decimal_published_examples(cpu, a, val, carry_in, exp_a, exp_c):
    got_a, _, _, _, got_c = _sweep(SBC_IMM, a, val, carry_in, True, cpu)
    assert (got_a, got_c) == (exp_a, exp_c)


# ── The D flag must survive PHP/PLP and not perturb binary mode ──────────

def test_decimal_flag_round_trips_through_php_plp():
    """SED; PHP; CLD; PLP leaves D set again."""
    cpu = run_one(0xF8, a=0x00)          # SED
    assert cpu.D == 1
    cpu.mem[cpu.pc] = 0x08               # PHP
    cpu.step()
    cpu.mem[cpu.pc] = 0xD8               # CLD
    cpu.step()
    assert cpu.D == 0
    cpu.mem[cpu.pc] = 0x28               # PLP
    cpu.step()
    assert cpu.D == 1


def test_binary_mode_arithmetic_unchanged_by_the_decimal_work(cpu):
    """Spot-check that D=0 ADC/SBC still behave as plain 8-bit arithmetic."""
    for a in range(0, 256, 7):
        for val in range(0, 256, 5):
            for carry_in in (0, 1):
                got_a, n, v, z, c = _sweep(ADC_IMM, a, val, carry_in, False, cpu)
                total = a + val + carry_in
                assert got_a == total & 0xFF
                assert c == (1 if total > 0xFF else 0)
                assert z == (1 if (total & 0xFF) == 0 else 0)
                assert n == ((total >> 7) & 1)
                assert v == (1 if (~(a ^ val) & (a ^ total) & 0x80) else 0)
