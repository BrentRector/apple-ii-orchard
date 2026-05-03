"""Shared infrastructure for disasm6502 and disasm_z80.

Holds CPU-agnostic concerns: data-region classification (the second pass that
runs after the recursive walker has marked code), and any other analysis
that doesn't depend on the specific instruction set.
"""

from .analyzer import (
    DataKind, DataRun,
    classify_data, classify_at,
    is_printable_byte, is_string_terminator,
)

__all__ = [
    "DataKind", "DataRun",
    "classify_data", "classify_at",
    "is_printable_byte", "is_string_terminator",
]
