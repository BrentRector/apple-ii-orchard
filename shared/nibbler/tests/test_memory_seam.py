"""Every memory access goes through read()/write().

A host builds its machine by replacing ``cpu.read`` and ``cpu.write``
(softcard_emu's Bus.attach_6502 does exactly this) and installing a
``fetch_hook`` for bank-switched instruction fetches. Any access that
indexes ``mem[]`` directly is invisible to that host, which makes "all
memory access goes through read()/write()" false and leaves the host
unable to model banking or memory-mapped I/O for those accesses.

These tests install counting/redirecting hooks and assert that the
addressing modes, the stack and the interrupt vectors all show up.

The single deliberate exception is format_instr(), which reads mem[]
directly so that enabling ``trace`` cannot perturb the machine; there is
a test for that below too.
"""

from nibbler.cpu import CPU6502
from .cpu_harness import ORG, make_cpu


class Watched(CPU6502):
    """A CPU that records every address seen by read() and write()."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.reads = []
        self.writes = []

    def read(self, addr):
        self.reads.append(addr & 0xFFFF)
        return super().read(addr)

    def write(self, addr, val):
        self.writes.append(addr & 0xFFFF)
        super().write(addr, val)


def watched(*program, org=ORG, **state):
    cpu = Watched()
    cpu.mem[org:org + len(program)] = bytes(program)
    cpu.pc = org
    for name, value in state.items():
        setattr(cpu, name, value)
    return cpu


# ── Indirect addressing pointer fetches ──────────────────────────────────

def test_izx_pointer_fetch_goes_through_read():
    """LDA ($40,X) must read the zero-page pointer through the seam."""
    cpu = watched(0xA1, 0x40, x=0x02)     # pointer at $42/$43
    cpu.mem[0x42] = 0x00
    cpu.mem[0x43] = 0x30
    cpu.step()
    assert 0x42 in cpu.reads and 0x43 in cpu.reads, \
        f"pointer bytes not seen by read(): {[hex(r) for r in cpu.reads]}"


def test_izy_pointer_fetch_goes_through_read():
    """LDA ($40),Y must read the zero-page pointer through the seam."""
    cpu = watched(0xB1, 0x40, y=0x01)
    cpu.mem[0x40] = 0x00
    cpu.mem[0x41] = 0x30
    cpu.step()
    assert 0x40 in cpu.reads and 0x41 in cpu.reads


def test_jmp_indirect_pointer_fetch_goes_through_read():
    """JMP ($3000): the pointer can be anywhere, including a banked region."""
    cpu = watched(0x6C, 0x00, 0x30)
    cpu.mem[0x3000] = 0x34
    cpu.mem[0x3001] = 0x12
    cpu.step()
    assert cpu.pc == 0x1234
    assert 0x3000 in cpu.reads and 0x3001 in cpu.reads


def test_jmp_indirect_through_a_banked_pointer():
    """The real payoff: a host can redirect a JMP (ind) pointer.

    The Apple language card banks RAM or ROM over $D000-$FFFF; a JMP
    indirect through a pointer up there used to bypass the host entirely
    and read the flat plane.
    """
    cpu = CPU6502()
    cpu.mem[ORG:ORG + 3] = bytes((0x6C, 0x00, 0xD0))    # JMP ($D000)
    cpu.pc = ORG
    cpu.mem[0xD000] = 0xFF          # what the flat plane holds
    cpu.mem[0xD001] = 0xFF
    bank = {0xD000: 0xCD, 0xD001: 0xAB}
    plain = cpu.read
    cpu.read = lambda a: bank.get(a, plain(a))
    cpu.step()
    assert cpu.pc == 0xABCD, "the banked bytes must win over the flat plane"


def test_jmp_indirect_page_wrap_bug_still_applies_through_the_seam():
    """JMP ($10FF) takes its high byte from $1000, not $1100 -- still."""
    cpu = watched(0x6C, 0xFF, 0x10)
    cpu.mem[0x10FF] = 0x34
    cpu.mem[0x1000] = 0x12
    cpu.mem[0x1100] = 0xFF
    cpu.step()
    assert cpu.pc == 0x1234
    assert 0x1000 in cpu.reads and 0x1100 not in cpu.reads


# ── Stack ────────────────────────────────────────────────────────────────

def test_push_goes_through_write():
    cpu = watched(0x48, a=0x5A)            # PHA
    cpu.step()
    assert 0x01FF in cpu.writes
    assert cpu.mem[0x01FF] == 0x5A


def test_pull_goes_through_read():
    cpu = watched(0x68)                    # PLA
    cpu.mem[0x01FF] = 0x5A
    cpu.sp = 0xFE
    cpu.step()
    assert 0x01FF in cpu.reads
    assert cpu.a == 0x5A


def test_jsr_and_rts_stack_traffic_goes_through_the_seam():
    cpu = watched(0x20, 0x00, 0x30)        # JSR $3000
    cpu.mem[0x3000] = 0x60                 # RTS
    cpu.step()
    assert 0x01FF in cpu.writes and 0x01FE in cpu.writes
    cpu.step()
    assert 0x01FE in cpu.reads and 0x01FF in cpu.reads
    assert cpu.pc == ORG + 3


def test_interrupt_frame_goes_through_write():
    cpu = watched(0xEA, I=0)
    cpu.irq()
    assert cpu.writes[:3] == [0x01FF, 0x01FE, 0x01FD]


# ── Vectors ──────────────────────────────────────────────────────────────

def test_all_four_vector_fetches_go_through_read():
    for setup, vector in (
        (lambda c: c.reset(), 0xFFFC),
        (lambda c: (setattr(c, "I", 0), c.irq()), 0xFFFE),
        (lambda c: c.nmi(), 0xFFFA),
    ):
        cpu = watched(0xEA)
        setup(cpu)
        assert vector in cpu.reads and vector + 1 in cpu.reads, \
            f"${vector:04X} vector not read through the seam"

    cpu = watched(0x00, 0x00)              # BRK
    cpu.step()
    assert 0xFFFE in cpu.reads and 0xFFFF in cpu.reads


# ── The deliberate exception ─────────────────────────────────────────────

def test_format_instr_does_not_touch_the_seam():
    """A disassembler must not perturb the machine it inspects.

    If format_instr() read through read(), switching ``trace`` on would
    fire disk latches and clear the keyboard strobe, changing the run.
    """
    cpu = watched(0xAD, 0x00, 0xC0)        # LDA $C000
    text = cpu.format_instr()
    assert "LDA" in text
    assert cpu.reads == [], "format_instr must not go through read()"


def test_tracing_does_not_change_execution():
    """Same instruction stream, traced and untraced, must end identically."""
    import io

    def run(trace):
        cpu = CPU6502()
        # LDA $C0EC (a disk soft switch), STA $10, LDA #$01, PHA, PLA
        program = bytes((0xAD, 0xEC, 0xC0, 0x85, 0x10, 0xA9, 0x01, 0x48, 0x68))
        cpu.mem[ORG:ORG + len(program)] = program
        cpu.pc = ORG
        if trace:
            cpu.trace = True
            cpu.trace_file = io.StringIO()
        for _ in range(5):
            cpu.step()
        return cpu.a, cpu.x, cpu.y, cpu.sp, cpu._get_p(), bytes(cpu.mem)

    assert run(False) == run(True)


# ── Instruction fetch still uses fetch_hook, not read() ──────────────────

def test_opcode_and_operand_fetches_use_the_fetch_hook():
    """Fetches are a separate seam so a host can bank code without banking data."""
    cpu = CPU6502()
    cpu.mem[ORG:ORG + 2] = bytes((0xEA, 0xEA))
    cpu.pc = ORG
    fetched = []

    def hook(addr):
        fetched.append(addr)
        return cpu.mem[addr]

    cpu.fetch_hook = hook
    cpu.step()
    assert ORG in fetched


def test_fetch_hook_can_supply_a_different_instruction_stream():
    cpu = CPU6502()
    cpu.mem[ORG] = 0xEA                          # flat plane says NOP
    cpu.pc = ORG
    cpu.fetch_hook = lambda a: 0xE8 if a == ORG else cpu.mem[a]   # banked: INX
    cpu.step()
    assert cpu.x == 1, "the fetch hook's opcode must be the one executed"
