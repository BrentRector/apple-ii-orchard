"""
analyze_sysimg.py -- Analyze the structure of a Z-80 system image
                      (CCP+BDOS at $8000-$96FF) by identifying routines,
                      their callers, and the addresses they touch.

Output: a structural map of every routine in the sysimg, with cross-
references and a classification heuristic. Used as input to the
hand-annotation pass for CPM2{20,23}_SystemImage.asm.
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


def disassemble(binfile: str, base: int, end: int):
    """Run nibbler z80disasm and parse the output."""
    result = subprocess.run(
        ['python', '-m', 'nibbler', 'z80disasm', binfile,
         '--base', f'0x{base:X}', '--start', f'0x{base:X}', '--end', f'0x{end:X}'],
        capture_output=True,
    )
    text = result.stdout.decode('utf-8', errors='replace')
    instrs = []
    for line in text.split('\n'):
        line = line.strip()
        if not line.startswith('$'):
            continue
        addr = int(line[1:5], 16)
        rest = line[7:]
        bytes_part = rest[:9].strip()
        instr = rest[9:].strip()
        instrs.append((addr, bytes_part, instr))
    return instrs


def find_routines(instrs, base, end):
    """Find routine entry points (CALL/JP targets) and end points (RET)."""
    targets = set([base])  # base is always an entry
    rets = set()
    addr_set = {a for a, _, _ in instrs}

    for addr, _, instr in instrs:
        # Find CALL/JP/JR targets within the image
        m = re.search(r'(CALL|JP|JR)(?:\s+\w+,)?\s+([0-9A-Fa-f]{4})$', instr)
        if m:
            t = int(m.group(2), 16)
            if base <= t < end and t in addr_set:
                targets.add(t)
        if instr == 'RET' or instr.startswith('RET '):
            rets.add(addr)
        # JP that doesn't return ends a routine; the next instruction
        # is a routine boundary if it's reached only via fallthrough
        # (which RET/JP-only routines don't allow).

    # A routine starts at a target. End is the next RET or unconditional
    # JP after the entry.
    routines = []
    targets_sorted = sorted(targets)
    for i, entry in enumerate(targets_sorted):
        # Find the end: the next RET or unconditional JP at or after entry,
        # but before the next entry
        next_entry = targets_sorted[i + 1] if i + 1 < len(targets_sorted) else end
        end_addr = entry
        for addr, _, instr in instrs:
            if addr < entry:
                continue
            if addr >= next_entry:
                break
            end_addr = addr
            if instr == 'RET' or (instr.startswith('JP ') and ',' not in instr):
                end_addr = addr
                break
        routines.append((entry, end_addr))
    return routines


def find_state_refs(instrs, base, end):
    """For each instruction, identify state addresses (memory references)
    outside the sysimg range -- these are state slots in TPA, BIOS, etc."""
    state_refs = defaultdict(list)
    for addr, _, instr in instrs:
        # Match (XXXX) or absolute XXXX in load/store/jump
        for m in re.finditer(r'\$?([0-9A-Fa-f]{4})\b', instr):
            try:
                t = int(m.group(1), 16)
                # External references = outside sysimg
                if not (base <= t < end):
                    state_refs[t].append(addr)
            except ValueError:
                pass
    return state_refs


def main():
    if len(sys.argv) < 2:
        print('Usage: analyze_sysimg.py {220|223}')
        sys.exit(1)

    ver = sys.argv[1]
    binfile = f'cpm-investigation/sysimg_{ver}.bin'
    base = 0x8000
    end = 0x96BB

    instrs = disassemble(binfile, base, end)
    routines = find_routines(instrs, base, end)
    state_refs = find_state_refs(instrs, base, end)

    # Group external refs into ranges
    print(f'\n=== sysimg_{ver} structural analysis ===\n')
    print(f'{len(instrs)} instructions, {len(routines)} routines')

    print()
    print(f'External addresses referenced by sysimg (most common):')
    for t, callers in sorted(state_refs.items(), key=lambda kv: -len(kv[1]))[:30]:
        print(f'  ${t:04X}  ({len(callers)} refs)')

    print()
    print(f'Routine count by 256-byte page:')
    pages = defaultdict(int)
    for entry, _ in routines:
        pages[entry & 0xFF00] += 1
    for page in sorted(pages):
        print(f'  ${page:04X}-${page | 0xFF:04X}: {pages[page]} routines')

    # Save routines list for the annotation step
    out = Path(f'cpm-investigation/routines_{ver}.txt')
    with open(out, 'w', encoding='utf-8') as f:
        for entry, end_addr in routines:
            f.write(f'${entry:04X}-${end_addr:04X}\n')
    print(f'\nRoutine list -> {out}')


if __name__ == '__main__':
    main()
