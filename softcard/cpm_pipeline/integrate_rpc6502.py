"""Surgically replace the embedded-6502 DEFB block in CPM_SystemImage.asm with an
INCBIN of CPM_RPC6502.bin + offset EQUs for its entry points/cells.

Preserves every other line (and all curated annotation) verbatim; only the
$9400-$9500 block region is swapped. The result reassembles BYTE-IDENTICAL when
CPM_RPC6502.bin is present alongside.
"""
from __future__ import annotations

import re
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
SYS = _REPO / "softcard" / "CPMV220-44K" / "os" / "CPM_SystemImage.asm"

BLOCK_START, BLOCK_END = 0x9400, 0x9501   # block occupies [start, end)
_ADDR = re.compile(r";\s*\$([0-9A-Fa-f]{4})\b")
_LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


def integrate() -> str:
    lines = SYS.read_text(encoding="utf-8").splitlines()
    # Find the contiguous run of lines belonging to the block: a line is in the
    # block if its address comment is in [START, END), or it is a label line
    # immediately followed (eventually) by such a line. We scan for the first
    # line at $9400 and the last line at <= $9500.
    start_i = end_i = None
    for i, l in enumerate(lines):
        if l.lstrip().startswith(";"):        # skip header/prose comment lines
            continue
        m = _ADDR.search(l)
        if m:
            a = int(m.group(1), 16)
            if a == BLOCK_START and start_i is None:
                # back up over any label-only lines directly above (L_9400:)
                start_i = i
                while start_i - 1 >= 0 and _LABEL.match(lines[start_i - 1]) and not _ADDR.search(lines[start_i - 1]):
                    start_i -= 1
            if BLOCK_START <= a < BLOCK_END:
                end_i = i
    assert start_i is not None and end_i is not None, "block not found"
    # Include trailing label-only lines just after end_i that belong to the block
    # boundary (none expected here; $9501 is code with its own label).
    block_lines = lines[start_i:end_i + 1]
    # Collect labels and their addresses in the block.
    labels = {}   # addr -> name
    pending = []
    for l in block_lines:
        ml = _LABEL.match(l)
        if ml and not _ADDR.search(l):
            pending.append(ml.group(1)); continue
        ma = _ADDR.search(l)
        if ma and pending:
            a = int(ma.group(1), 16)
            for n in pending:
                labels[a] = n
            pending = []
    base = labels.get(BLOCK_START, "L_9400")
    repl = [
        f"{base}:    ; ${BLOCK_START:04X}-${BLOCK_END-1:04X}  embedded 6502 RPC block "
        f"(see CPM_RPC6502.s, ca65) -- INCBIN'd byte-identical",
        f'        INCBIN  "CPM_RPC6502.bin"',
        f"; -- 6502 block entry points / data cells, as offsets from {base} "
        f"(relocate with ORG) --",
    ]
    for a in sorted(labels):
        if a == BLOCK_START:
            continue
        repl.append(f"{labels[a]:<16} EQU {base} + ${a - BLOCK_START:03X}")
    out = lines[:start_i] + repl + lines[end_i + 1:]
    return "\n".join(out) + "\n"


def write() -> Path:
    SYS.write_text(integrate(), encoding="utf-8")
    return SYS


if __name__ == "__main__":
    import sys
    if "--dry" in sys.argv:
        print(integrate())
    else:
        print("wrote", write())
