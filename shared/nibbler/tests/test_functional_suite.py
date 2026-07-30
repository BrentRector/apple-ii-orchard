"""Klaus Dormann's 6502 functional test suite, run against the core.

This is the strongest available external oracle for a 6502: a real 6502
program, ~30.6 million instructions, that exercises every documented
opcode in every addressing mode, all flag behaviour, decimal mode
(``disable_decimal = 0`` in the published build), BRK/RTI, and the JMP
indirect page-wrap bug. It traps at the failing test on any discrepancy
and reaches a single known success address only if everything passed.
Being a 6502 program rather than a Python assertion, it fits this
codebase's verification style exactly.

The binary is NOT vendored into this repo. It is GPL-3.0 (Klaus Dormann,
2012-2015) and this repo is MIT, so committing it is a licensing decision
for the repo owner rather than something to do silently. The test skips
when the file is absent and says how to get it.

To make it run, put ``6502_functional_test.bin`` in this directory, or
point NIBBLER_FUNCTIONAL_TEST_BIN at a copy:

    curl -Lo shared/nibbler/tests/6502_functional_test.bin \\
      https://raw.githubusercontent.com/Klaus2m5/6502_65C02_functional_tests/master/bin_files/6502_functional_test.bin

Measured result when it does run (2026-07-30): PASS, trapping at $3469
with test_case 240, in 30,646,177 instructions and 96,241,367 cycles.
It takes about 30 seconds, hence the ``slow`` marker.
"""

import os
from pathlib import Path

import pytest

from nibbler.cpu import CPU6502

# Load address is $0000 (the image is a full 64 KB), execution starts at
# code_segment = $0400, and the 'success' macro assembles to a `jmp *` at
# $3469 -- all three per the published 6502_functional_test.lst.
START_PC = 0x0400
SUCCESS_TRAP = 0x3469
TEST_CASE = 0x0200          # data_segment; holds the current test number
FINAL_TEST_CASE = 240
INSTRUCTION_LIMIT = 200_000_000

_ENV = "NIBBLER_FUNCTIONAL_TEST_BIN"
_DEFAULT = Path(__file__).with_name("6502_functional_test.bin")


def _binary_path():
    return Path(os.environ.get(_ENV, _DEFAULT))


class FlatCPU(CPU6502):
    """CPU6502 with the Apple II I/O intercepts removed.

    The test image is 64 KB of plain RAM and writes and reads through the
    whole space, including $C000, $C010 and the slot-6 disk registers.
    Leaving read()'s soft-switch handling in place would return 0 for
    those and fail the test for a reason that has nothing to do with the
    CPU. This subclass isolates the instruction-set core, which is what
    the suite is for.
    """

    def read(self, addr):
        return self.mem[addr & 0xFFFF]

    def write(self, addr, val):
        self.mem[addr & 0xFFFF] = val & 0xFF


@pytest.mark.slow
def test_klaus_dormann_functional_suite_passes():
    path = _binary_path()
    if not path.is_file():
        pytest.skip(
            f"{path.name} not present (GPL-3.0, deliberately not vendored "
            f"into this MIT repo). Place it at {path} or set {_ENV}; see "
            f"this module's docstring for the download URL."
        )

    image = path.read_bytes()
    assert len(image) == 65536, f"expected a 64 KB image, got {len(image)}"

    cpu = FlatCPU()
    cpu.mem[:] = image
    cpu.pc = START_PC

    # Every failure in the suite is a trap: a branch or jump to itself. So
    # running until PC stops changing lands either on the success trap or
    # on the exact instruction that detected the discrepancy.
    previous_pc = -1
    for _ in range(INSTRUCTION_LIMIT):
        if cpu.pc == previous_pc:
            break
        previous_pc = cpu.pc
        if not cpu.step():
            pytest.fail(f"CPU halted (KIL) at ${cpu.pc:04X}")
    else:
        pytest.fail(f"no trap reached within {INSTRUCTION_LIMIT} instructions")

    assert cpu.pc == SUCCESS_TRAP, (
        f"trapped at ${cpu.pc:04X}, not the success address "
        f"${SUCCESS_TRAP:04X}; failing test_case = {cpu.mem[TEST_CASE]}"
    )
    assert cpu.mem[TEST_CASE] == FINAL_TEST_CASE
