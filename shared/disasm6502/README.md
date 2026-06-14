# disasm6502

Production-quality 6502 disassembler. Recursive-descent code/data classification, JSON symbol-table input, **byte-identical round-trip** through ca65 + ld65.

## Quick start

```sh
source ../toolchain/env.sh   # puts ca65 + ld65 on PATH

python -m disasm6502 INPUT.bin --org $0100 \
    --symbols ../symbols/apple2.json \
    --entry $0100 \
    --data-region $1000-$10FF \
    --output OUT
# writes OUT.s and OUT.cfg

ca65 OUT.s -o OUT.o
ld65 -C OUT.cfg -o OUT.bin OUT.o
cmp INPUT.bin OUT.bin     # silent = byte-identical
```

## CLI flags

| Flag | Meaning |
|---|---|
| `--org $XXXX` | load address (required) |
| `--length N` | bytes to disassemble (default: file size) |
| `--entry $XXXX` | entry point for the recursive walker (repeatable; default: `--org`) |
| `--data-region START-END_INCL` | force a range to be treated as data (repeatable) |
| `--symbols a.json` | load a symbol table; substitute names in operands (repeatable) |
| `--output PATH` | output base name; `.s` and `.cfg` files written |

## Pieces

| File | Purpose |
|---|---|
| [opcodes.py](opcodes.py) | 6502 opcode table (151 documented + ~50 undocumented NMOS) |
| [symbols.py](symbols.py) | JSON symbol-table loader (schema v1.0, see [../symbols/README.md](../symbols/README.md)) |
| [walker.py](walker.py) | Recursive-descent code/data classifier |
| [formatter.py](formatter.py) | ca65-syntax source emitter + ld65 linker config |
| [cli.py](cli.py) | Command-line entry point |
| [tests/](tests/) | pytest suite (opcode invariants, walker behavior, round-trip) |

## Testing

```sh
python -m pytest shared/disasm6502/tests/
```

Round-trip tests skip silently if `ca65`/`ld65` aren't on PATH. They exercise the trivial smoke binary plus the 3 KB CP/M 2.23 boot loader, which mixes code (44 bytes), text strings, and large zero fills.

## Symbol substitution

Operands that resolve to a known symbol get the symbolic name; otherwise they fall back to `$XXXX`. Only symbols actually referenced in the body are emitted as `Name = $XXXX` equates at the top of the file (so a 70-symbol table doesn't dump 70 lines of equates for a binary that only touches three of them).
