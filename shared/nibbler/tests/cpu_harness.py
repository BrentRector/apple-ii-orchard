"""Shared helpers for driving CPU6502 in unit tests.

These keep the tests themselves free of setup noise: build a CPU with a
short program at a known address, run exactly one instruction, and read
back the register/flag state.
"""

from nibbler.cpu import CPU6502

# Where test programs are assembled.  Chosen to be plain RAM: away from
# zero page, the stack, and the $C000 soft-switch page, so nothing in
# read()/write() intercepts an access.
ORG = 0x0200


def make_cpu(*program, org=ORG, **state):
    """Return a CPU6502 with ``program`` bytes loaded at ``org`` and PC set there.

    Any keyword argument names a CPU attribute to preset, e.g.
    ``make_cpu(0x69, 0x01, a=0x42, C=1, D=1)``.
    """
    cpu = CPU6502()
    cpu.mem[org:org + len(program)] = bytes(program)
    cpu.pc = org
    for name, value in state.items():
        setattr(cpu, name, value)
    return cpu


def run_one(*program, org=ORG, **state):
    """Assemble ``program`` at ``org``, execute one instruction, return the CPU."""
    cpu = make_cpu(*program, org=org, **state)
    cpu.step()
    return cpu


def flags(cpu):
    """Return the six real flags as a dict (P bits 4/5 have no storage)."""
    return {"N": cpu.N, "V": cpu.V, "D": cpu.D, "I": cpu.I, "Z": cpu.Z, "C": cpu.C}


def from_bcd(byte):
    """Interpret a byte as two packed BCD digits. Only valid for nibbles 0-9."""
    return (byte >> 4) * 10 + (byte & 0x0F)


def to_bcd(value):
    """Pack a 0-99 decimal value into two BCD nibbles."""
    return ((value // 10) << 4) | (value % 10)


VALID_BCD = [to_bcd(v) for v in range(100)]   # $00..$99, no invalid nibbles
