"""Production Z-80 disassembler.

Full prefix coverage: base, CB, ED, DD, FD, DDCB, FDCB. Recursive-descent
code/data classification, JSON symbol-table input, sjasmplus-compatible output
that round-trips byte-identical.

Quick start
-----------
    python -m disasm_z80 INPUT.bin --org $0100 \\
        --symbols ../symbols/cpm_2_2.json \\
        --entry $0100 \\
        --output OUT
        # writes OUT.asm

The output file reassembles to byte-identical bytes via:
    sjasmplus OUT.asm
    cmp INPUT.bin OUT.bin
"""

from .opcodes import decode_at, ControlFlow
from .symbols import SymbolTable, load_symbols
from .walker import Walker
from .formatter import SjasmFormatter

__all__ = [
    "decode_at",
    "ControlFlow",
    "SymbolTable",
    "load_symbols",
    "Walker",
    "SjasmFormatter",
]
