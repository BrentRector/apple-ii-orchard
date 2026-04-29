"""
make_compilable.py -- Transform disassembler-style .asm files into
                       genuinely-compilable assembler sources.

The original .asm files use disassembler output format:
    $0A00: 38       SEC
    $0A01: 86 27    STX $27

The "$0A00:" prefix is a label-style annotation showing the address.
Most assemblers reject labels that start with "$" or that have hex
in their leading position. This script converts each instruction
line to:
    SEC                                 ; $0A00 38
    STX $27                             ; $0A01 86 27

The resulting file is compilable by ca65 (cc65) for 6502 sources or
by sjasmplus / pasmo for Z-80 sources, given the .ORG directive at
the top of the file. Symbol definitions and section comments are
preserved unchanged.

USAGE
    python make_compilable.py docs/CPM223_RWTS.asm docs/build/CPM223_RWTS.s
"""
import re
import sys
from pathlib import Path

_HEX = '0123456789ABCDEFabcdef'


def transform_line(line: str) -> str:
    """Convert one disasm line to compilable assembly.

    Handles two input formats:
        Disasm output ("$XXXX: bb bb bb  INSTRUCTION ..."):
            $0A03: 8E 78 06 STX $0678
        Hand-written ("$XXXX:      INSTRUCTION ..."):
            $1010:      LDA #$5C
    """
    if not line.startswith('$'):
        return line
    if len(line) < 7 or line[5] != ':':
        return line

    addr = line[1:5]
    if not all(c in _HEX for c in addr):
        return line

    rest = line[6:]  # everything after "$XXXX:"

    # Disasm-output form: cols 7-15 are bytes (after the leading "$XXXX: ").
    # That's `rest[1:10]` if `rest` starts with a single space.
    bytes_part = rest[1:10] if len(rest) > 10 else ''
    instruction_disasm = rest[10:].strip() if len(rest) > 10 else ''

    if (bytes_part and instruction_disasm
            and all(c in _HEX + ' ' for c in bytes_part)
            and bytes_part.strip()):
        # Disasm-output form
        return (f"            {instruction_disasm:<32}; ${addr} "
                f"{bytes_part.strip()}")

    # Hand-written form: just whitespace then instruction
    instruction = rest.strip()
    if not instruction:
        return line
    # Skip lines where the "instruction" is actually data ($BYTE) or data-style
    # things we want to keep as data declarations. The hand-written format
    # uses ".BYTE", ".DS", ".WORD", ".ORG" -- those are assembler directives,
    # keep them inline.
    return f"            {instruction:<32}; ${addr}"


def transform_file(input_path: Path, output_path: Path):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(input_path, 'r', encoding='utf-8') as f:
        text = f.read()

    transformed_lines = []
    transformed_count = 0
    for line in text.splitlines():
        new = transform_line(line)
        if new != line:
            transformed_count += 1
        transformed_lines.append(new)

    output = '\n'.join(transformed_lines) + '\n'
    with open(output_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(output)

    print(f'  {input_path.name} -> {output_path}')
    print(f'    {transformed_count} instructions transformed; '
          f'{len(text.splitlines())} total lines')


def main():
    docs = Path('docs')
    build = docs / 'build'

    files = [
        'CPM220_BootLoader.asm',
        'CPM220_InstallFragments.asm',
        'CPM220_RWTS.asm',
        'CPM220_BIOS.asm',
        'CPM220_SystemImage.asm',
        'CPM223_BootLoader.asm',
        'CPM223_InstallFragments.asm',
        'CPM223_RWTS.asm',
        'CPM223_BIOS.asm',
        'CPM223_DiskCallbacks.asm',
        'CPM223_SystemImage.asm',
    ]

    print(f'Transforming {len(files)} disassembler-style .asm files into '
          f'compilable form...')
    for name in files:
        src = docs / name
        if not src.exists():
            print(f'  SKIP missing: {name}')
            continue
        # Compilable output uses .s suffix to distinguish from disassembler-form
        dst = build / name.replace('.asm', '.s')
        transform_file(src, dst)

    print(f'\nOutputs in {build}/')


if __name__ == '__main__':
    main()
