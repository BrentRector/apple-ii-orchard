"""RESET, IRQ, NMI and BRK on the NMOS 6502.

The properties asserted here come straight from the hardware definition,
not from a reference emulator:

  * each entry point vectors through its own fixed pointer;
  * BRK pushes P with B (bit 4) SET, IRQ and NMI push it CLEAR -- the only
    way a handler can tell a BRK from an IRQ, since they share a vector;
  * IRQ is masked by the I flag, NMI never is;
  * BRK pushes PC+2, a hardware interrupt pushes PC unmodified;
  * RESET writes nothing but still moves SP down by 3.
"""

import pytest

from nibbler.cpu import CPU6502
from .cpu_harness import ORG, make_cpu

NOP = 0xEA
BRK = 0x00
RTI = 0x40


def vectored(cpu, nmi=0x9000, reset=0x8000, irq=0xA000):
    """Install the three hardware vectors, then return the CPU."""
    cpu.mem[0xFFFA] = nmi & 0xFF
    cpu.mem[0xFFFB] = nmi >> 8
    cpu.mem[0xFFFC] = reset & 0xFF
    cpu.mem[0xFFFD] = reset >> 8
    cpu.mem[0xFFFE] = irq & 0xFF
    cpu.mem[0xFFFF] = irq >> 8
    return cpu


def stack_frame(cpu, sp_before):
    """Return (pushed_pc, pushed_p) for a frame pushed from ``sp_before``."""
    p = cpu.mem[0x0100 + ((sp_before - 2) & 0xFF)]
    lo = cpu.mem[0x0100 + ((sp_before - 1) & 0xFF)]
    hi = cpu.mem[0x0100 + (sp_before & 0xFF)]
    return lo | (hi << 8), p


# ── Vectoring ────────────────────────────────────────────────────────────

def test_reset_vectors_through_fffc():
    cpu = vectored(CPU6502(), reset=0x8123)
    cpu.pc = 0x0000
    cpu.reset()
    assert cpu.pc == 0x8123


def test_irq_vectors_through_fffe():
    cpu = vectored(make_cpu(NOP, I=0), irq=0xA456)
    assert cpu.irq() is True
    assert cpu.pc == 0xA456


def test_nmi_vectors_through_fffa():
    cpu = vectored(make_cpu(NOP), nmi=0x9789)
    assert cpu.nmi() is True
    assert cpu.pc == 0x9789


def test_brk_vectors_through_fffe():
    cpu = vectored(make_cpu(BRK, 0x00), irq=0xA456)
    cpu.step()
    assert cpu.pc == 0xA456


def test_brk_and_irq_share_a_vector():
    """Same target for both -- which is why the B flag has to disambiguate."""
    brk_cpu = vectored(make_cpu(BRK, 0x00), irq=0xABCD)
    brk_cpu.step()
    irq_cpu = vectored(make_cpu(NOP, I=0), irq=0xABCD)
    irq_cpu.irq()
    assert brk_cpu.pc == irq_cpu.pc == 0xABCD


# ── The B flag: the whole point ──────────────────────────────────────────

def test_brk_pushes_p_with_b_set():
    cpu = vectored(make_cpu(BRK, 0x00))
    sp_before = cpu.sp
    cpu.step()
    _, pushed_p = stack_frame(cpu, sp_before)
    assert pushed_p & 0x10, f"BRK pushed P=${pushed_p:02X}, B (bit 4) must be SET"
    assert pushed_p & 0x20, "bit 5 always reads as 1"


def test_irq_pushes_p_with_b_clear():
    cpu = vectored(make_cpu(NOP, I=0))
    sp_before = cpu.sp
    cpu.irq()
    _, pushed_p = stack_frame(cpu, sp_before)
    assert not (pushed_p & 0x10), \
        f"IRQ pushed P=${pushed_p:02X}, B (bit 4) must be CLEAR"
    assert pushed_p & 0x20, "bit 5 always reads as 1"


def test_nmi_pushes_p_with_b_clear():
    cpu = vectored(make_cpu(NOP))
    sp_before = cpu.sp
    cpu.nmi()
    _, pushed_p = stack_frame(cpu, sp_before)
    assert not (pushed_p & 0x10), \
        f"NMI pushed P=${pushed_p:02X}, B (bit 4) must be CLEAR"


def test_b_flag_is_the_only_difference_between_brk_and_irq_frames():
    """With identical flags going in, the pushed bytes differ only in bit 4."""
    brk_cpu = vectored(make_cpu(BRK, 0x00, N=1, V=1, D=1, Z=1, C=1, I=0))
    brk_sp = brk_cpu.sp
    brk_cpu.step()
    _, brk_p = stack_frame(brk_cpu, brk_sp)

    irq_cpu = vectored(make_cpu(NOP, N=1, V=1, D=1, Z=1, C=1, I=0))
    irq_sp = irq_cpu.sp
    irq_cpu.irq()
    _, irq_p = stack_frame(irq_cpu, irq_sp)

    assert brk_p ^ irq_p == 0x10, \
        f"BRK P=${brk_p:02X} vs IRQ P=${irq_p:02X}: only bit 4 may differ"


def test_b_flag_has_no_storage_so_rti_cannot_restore_it():
    """PLP/RTI ignore bits 4 and 5; the 6502 has no B register."""
    cpu = vectored(make_cpu(RTI))
    cpu.push(0x00)          # PCH
    cpu.push(0x00)          # PCL
    cpu.push(0xFF)          # P with every bit set, including B
    cpu.step()
    assert cpu._get_p() & 0x30 == 0x30, "reading P always shows bits 4,5 set"
    # All six real flags came back set; there is nothing else to restore.
    assert (cpu.N, cpu.V, cpu.D, cpu.I, cpu.Z, cpu.C) == (1, 1, 1, 1, 1, 1)


# ── Pushed return address ────────────────────────────────────────────────

def test_brk_pushes_pc_plus_two():
    """BRK skips the padding byte after the opcode."""
    cpu = vectored(make_cpu(BRK, 0x00))
    sp_before = cpu.sp
    cpu.step()
    pushed_pc, _ = stack_frame(cpu, sp_before)
    assert pushed_pc == ORG + 2


def test_hardware_interrupt_pushes_pc_unmodified():
    """An IRQ resumes at the instruction it interrupted, not past it."""
    cpu = vectored(make_cpu(NOP, I=0))
    sp_before = cpu.sp
    cpu.irq()
    pushed_pc, _ = stack_frame(cpu, sp_before)
    assert pushed_pc == ORG


# ── Masking ──────────────────────────────────────────────────────────────

def test_irq_is_ignored_while_i_is_set():
    cpu = vectored(make_cpu(NOP, I=1))
    before = (cpu.pc, cpu.sp)
    assert cpu.irq() is False
    assert (cpu.pc, cpu.sp) == before, "a masked IRQ must not touch the stack"


def test_nmi_is_taken_even_while_i_is_set():
    cpu = vectored(make_cpu(NOP, I=1), nmi=0x9000)
    assert cpu.nmi() is True
    assert cpu.pc == 0x9000


def test_both_entry_points_set_i():
    for take in ("irq", "nmi"):
        cpu = vectored(make_cpu(NOP, I=0))
        getattr(cpu, take)()
        assert cpu.I == 1, f"{take} must set I on entry"


def test_interrupt_sequence_does_not_disturb_registers():
    cpu = vectored(make_cpu(NOP, a=0x11, x=0x22, y=0x33, I=0))
    cpu.irq()
    assert (cpu.a, cpu.x, cpu.y) == (0x11, 0x22, 0x33)


# ── The latched lines that step() polls ──────────────────────────────────

def test_step_services_a_latched_nmi_before_the_next_instruction():
    cpu = vectored(make_cpu(NOP), nmi=0x9000)
    cpu.set_nmi()
    cpu.step()
    assert cpu.pc == 0x9000
    assert cpu.exec_count == 0, "the NMI is taken instead of the instruction"


def test_nmi_edge_fires_once_even_if_latched_twice():
    cpu = vectored(make_cpu(NOP, org=0x9000), nmi=0x9000)
    cpu.pc = ORG
    cpu.mem[ORG] = NOP
    cpu.set_nmi()
    cpu.set_nmi()
    cpu.step()                      # takes the NMI
    sp_after_first = cpu.sp
    cpu.step()                      # must run the NOP at $9000, not re-enter
    assert cpu.sp == sp_after_first, "a single edge must produce a single NMI"


def test_irq_line_is_a_level_and_refires_until_released():
    cpu = vectored(make_cpu(NOP, org=0xA000, I=0), irq=0xA000)
    cpu.pc = ORG
    cpu.mem[ORG] = NOP
    cpu.set_irq(True)
    cpu.step()
    first_sp = cpu.sp
    cpu.I = 0                       # handler re-enables but does not clear /IRQ
    cpu.step()
    assert cpu.sp == (first_sp - 3) & 0xFF, "a held IRQ line re-fires"
    cpu.set_irq(False)
    cpu.I = 0
    held_sp = cpu.sp
    cpu.step()
    assert cpu.sp == held_sp, "releasing the line stops the re-entry"


def test_step_prefers_nmi_when_both_are_pending():
    cpu = vectored(make_cpu(NOP, I=0), nmi=0x9000, irq=0xA000)
    cpu.set_nmi()
    cpu.set_irq(True)
    cpu.step()
    assert cpu.pc == 0x9000


def test_masked_irq_line_does_not_block_execution():
    cpu = vectored(make_cpu(NOP, I=1))
    cpu.set_irq(True)
    cpu.step()
    assert cpu.exec_count == 1 and cpu.pc == ORG + 1


# ── RESET specifics ──────────────────────────────────────────────────────

def test_reset_moves_sp_down_by_three_without_writing():
    cpu = vectored(CPU6502())
    cpu.sp = 0xFF
    cpu.mem[0x01FF] = 0xAA
    cpu.mem[0x01FE] = 0xAA
    cpu.mem[0x01FD] = 0xAA
    cpu.reset()
    assert cpu.sp == 0xFC
    assert cpu.mem[0x01FF] == cpu.mem[0x01FE] == cpu.mem[0x01FD] == 0xAA, \
        "RESET holds R/W in the read state: the three pushes write nothing"


def test_reset_sets_i():
    cpu = vectored(CPU6502())
    cpu.I = 0
    cpu.reset()
    assert cpu.I == 1


def test_reset_leaves_d_alone_because_this_is_nmos():
    """Clearing D on reset is 65C02 behavior. NMOS leaves it undefined.

    That is precisely why real Apple II entry points begin with CLD, and
    modelling it keeps code that depends on the CLD honest.
    """
    cpu = vectored(CPU6502())
    cpu.D = 1
    cpu.reset()
    assert cpu.D == 1


def test_reset_releases_a_jammed_cpu():
    cpu = vectored(make_cpu(0x02), reset=0x8000)      # $02 = KIL
    cpu.step()
    assert cpu.halted
    assert cpu.step() is False
    cpu.reset()
    assert not cpu.halted and cpu.pc == 0x8000


def test_a_jammed_cpu_ignores_irq_and_nmi():
    """A KIL'd 6502 never completes a fetch, so it cannot acknowledge either."""
    cpu = vectored(make_cpu(0x02))
    cpu.step()
    assert cpu.halted
    assert cpu.irq() is False
    assert cpu.nmi() is False


# ── Round trip ───────────────────────────────────────────────────────────

def test_rti_returns_to_the_interrupted_instruction():
    cpu = vectored(make_cpu(NOP, I=0), irq=0xA000)
    cpu.mem[0xA000] = RTI
    cpu.irq()
    assert cpu.pc == 0xA000
    cpu.step()                       # RTI
    assert cpu.pc == ORG, "an IRQ handler returns to the instruction it preempted"
    assert cpu.I == 0, "RTI restores the pre-interrupt I flag"


def test_rti_after_brk_returns_past_the_padding_byte():
    cpu = vectored(make_cpu(BRK, 0x00, NOP), irq=0xA000)
    cpu.mem[0xA000] = RTI
    cpu.step()                       # BRK
    cpu.step()                       # RTI
    assert cpu.pc == ORG + 2, "BRK's padding byte is skipped by the pushed PC+2"


# ── Vectors are read through the memory seam ─────────────────────────────

def test_vectors_are_fetched_through_read_not_the_raw_plane():
    """A host that banks memory over $FFFA-$FFFF must be able to redirect it.

    The Apple language card maps over $D000-$FFFF, which covers all three
    vectors, so reading them straight out of mem[] would pick up whatever
    happened to be in the flat plane instead of the banked bytes.
    """
    cpu = vectored(CPU6502(), reset=0x1111, irq=0x2222, nmi=0x3333)
    banked = {0xFFFA: 0xCD, 0xFFFB: 0xAB, 0xFFFC: 0x34, 0xFFFD: 0x12,
              0xFFFE: 0x78, 0xFFFF: 0x56}
    plain_read = cpu.read
    cpu.read = lambda addr: banked.get(addr, plain_read(addr))

    cpu.reset()
    assert cpu.pc == 0x1234
    cpu.I = 0
    cpu.irq()
    assert cpu.pc == 0x5678
    cpu.nmi()
    assert cpu.pc == 0xABCD


def test_brk_vector_is_fetched_through_read():
    cpu = vectored(make_cpu(BRK, 0x00))
    plain_read = cpu.read
    cpu.read = lambda addr: {0xFFFE: 0xEF, 0xFFFF: 0xBE}.get(addr, plain_read(addr))
    cpu.step()
    assert cpu.pc == 0xBEEF
