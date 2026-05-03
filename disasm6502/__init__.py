"""Production 6502 disassembler with recursive-descent code/data classification,
JSON symbol-table input, and ca65-compatible output.

Quick start
-----------
    python -m disasm6502 INPUT.bin --org $0100 \\
        --symbols ../symbols/apple2.json \\
        --entry $0100 \\
        --output OUT.s OUT.cfg

The output pair (`OUT.s` + `OUT.cfg`) reassembles to byte-identical bytes via:
    ca65 OUT.s -o OUT.o
    ld65 -C OUT.cfg -o OUT.bin OUT.o
    cmp INPUT.bin OUT.bin
"""

from .opcodes import OPCODES, UNDOC_MNEMONICS
from .symbols import SymbolTable, load_symbols
from .walker import Walker
from .formatter import Ca65Formatter

__all__ = [
    "OPCODES",
    "UNDOC_MNEMONICS",
    "SymbolTable",
    "load_symbols",
    "Walker",
    "Ca65Formatter",
]
