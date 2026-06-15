# disasm_z80

Production-quality Z-80 disassembler. Full prefix coverage (base / CB / ED / DD / FD / DDCB / FDCB), recursive-descent code/data classification, JSON symbol-table input, **byte-identical round-trip** through sjasmplus.

## Quick start

```sh
source ../toolchain/env.sh   # puts sjasmplus on PATH

python -m disasm_z80 INPUT.bin --org $0100 \
    --symbols ../symbols/cpm_2_2.json \
    --entry $0100 \
    --data-region $1000-$10FF \
    --output OUT
# writes OUT.asm

sjasmplus OUT.asm        # writes OUT.bin
cmp INPUT.bin OUT.bin    # silent = byte-identical
```

## CLI flags

| Flag | Meaning |
|---|---|
| `--org $XXXX` | load address (required) |
| `--length $N` | bytes to disassemble (default: file size) |
| `--entry $XXXX` | entry point for the recursive walker (repeatable; default: `--org`) |
| `--data-region START-END_INCL` | force a range to be treated as data (repeatable) |
| `--symbols a.json` | load a symbol table; substitute names in operands (repeatable) |
| `--output PATH` | output base name; `.asm` written |

## Pieces

| File | Purpose |
|---|---|
| [opcodes.py](opcodes.py) | Decoder: BASE / CB / ED tables + DD/FD overrides + DDCB/FDCB compound tables. Handles all 1280 (256 × 5) prefix opcode positions. |
| [symbols.py](symbols.py) | JSON symbol-table loader (schema v1.0; same as disasm6502) |
| [walker.py](walker.py) | Recursive-descent code/data classifier with CALL/RST target tracking |
| [formatter.py](formatter.py) | sjasmplus-syntax source emitter |
| [cli.py](cli.py) | Command-line entry point |
| [tests/](tests/) | pytest suite: opcode coverage, walker behavior, round-trip |

## Code-overlap idiom support

Z-80 BIOSes sometimes use deliberate instruction overlap — calling into the middle of a multi-byte instruction so two code paths share trailing bytes. The CP/M 2.23 BIOS does this at $FB45: `CALL $FB45` enters `RLCA; CALL $FE81; ...` while the surrounding context decodes those same bytes as `JR NZ,L_FB44; CALL $FE81; ...`.

The walker correctly traces both paths. A label that falls mid-instruction can't be placed inline (it would split the covering instruction and change the bytes), so the formatter mints a label on the covering instruction's start and references the target **inline at the use site** as `cover+offset` — no standalone label, no equate. The CP/M 2.23 BIOS overlap reads

```
L_FB44:
        JR NZ,L_FB4D                     ; $FB44  20 07
        ...
        CALL L_FB44+1                    ; $FB56  CD 45 FB
```

The assembler evaluates `L_FB44+1` to `$FB45`, so round-trip stays byte-identical while the call site documents *why* the address is mid-instruction. Recognized shapes are the named skip idioms (6502 `BIT`-skip `$2C`/`$24`, Z-80 `LD rr,nn`/`LD A,n` `$21`/`$01`/`$11`/`$3E`) and shared instruction tails (the interior address is itself reachable code). A comment block near the top of the source summarizes every mid-instruction reference.

A label that lands inside a *data run* (no covering instruction) or inside the interior of a non-idiom instruction it never reaches as code is flagged as a **suspected misframe** — a signal that the code/data classification or the ORG is wrong, not a real overlap. Its operand falls back to a bare literal and the comment block marks it for review.

## Testing

```sh
python -m pytest shared/disasm_z80/tests/
```

Coverage:
- 7 opcode tests prove every byte 0..0xFF decodes in BASE / CB / ED / DD / FD / DDCB / FDCB (1280 starting positions, all valid)
- 8 walker tests cover linear trace, CALL/JR/RST control flow, indirect jumps, data-region boundaries, symbol naming
- 2 round-trip tests prove byte-identical reassembly:
  - 6-byte hand-written smoke binary
  - 1352-byte CP/M 2.23 Z-80 BIOS at $FAB8 (842 traced code bytes, 39 labels, including the $FB45 code-overlap)

Round-trip tests skip silently if `sjasmplus` isn't on PATH.
