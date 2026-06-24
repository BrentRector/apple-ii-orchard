"""Keep each cross-CPU INCBIN site self-documenting.

When a source file INCBINs code for the OTHER processor (a Z-80 block assembled
by sjasmplus and INCBIN'd into a 6502 ca65 image, or the 6502 CPM_RPC6502 block
INCBIN'd into the Z-80 CCP), the INCBIN line alone tells a reader nothing about
what runs there. The convention (see memory feedback_incbin_list_source) is to
reproduce the embedded source's EXACT lines -- verbatim, one-for-one, nothing
combined or omitted -- as comments at the INCBIN site, inside a regenerable
delimited block. This module owns that: `regen_all()` rewrites the blocks from
the sources; `check_all()` reports any that have drifted (used by a test, so the
comment can never silently diverge from what actually compiles).
"""
from __future__ import annotations

import re
from pathlib import Path

_OS = Path(__file__).resolve().parents[1]      # softcard/

# (host_file, incbin_bin_name, embedded_source_file, title)
SITES = [
    (_OS / "CPMV220-44K/os/CPM_BootLoader.s", "CPM_BootLoader_ProbeOvl.bin",
     _OS / "CPMV220-44K/os/CPM_BootLoader_ProbeOvl.asm", "CPM_BootLoader_ProbeOvl.asm"),
    (_OS / "CPMV220-44K/os/CPM_BootLoader.s", "CPM_BootLoader_ConInit.bin",
     _OS / "CPMV220-44K/os/CPM_BootLoader_ConInit.asm", "CPM_BootLoader_ConInit.asm"),
    # 2.20-44K CCP: SECOND embedded 6502 block ($9600-$9700) -- cold-restart/RPC service
    # 2.23-44K boot loader: slot-probe handshake + embedded Z-80 disk-translate routine
    (_OS / "CPMV223-44K/os/CPM_BootLoader.s", "CPM_BootLoader_ProbeOvl.bin",
     _OS / "CPMV223-44K/os/CPM_BootLoader_ProbeOvl.asm", "CPM_BootLoader_ProbeOvl.asm"),
    (_OS / "CPMV223-44K/os/CPM_BootLoader.s", "CPM_BootLoader_DiskXlate.bin",
     _OS / "CPMV223-44K/os/CPM_BootLoader_DiskXlate.asm", "CPM_BootLoader_DiskXlate.asm"),
    # 56K boot loader: slot-probe handshake + slot-3 console driver
    (_OS / "CPMV220/os/CPM_BootLoader.s", "CPM_BootLoader_ProbeOvl.bin",
     _OS / "CPMV220/os/CPM_BootLoader_ProbeOvl.asm", "CPM_BootLoader_ProbeOvl.asm"),
    (_OS / "CPMV220/os/CPM_BootLoader.s", "CPM_BootLoader_ConInit.bin",
     _OS / "CPMV220/os/CPM_BootLoader_ConInit.asm", "CPM_BootLoader_ConInit.asm"),
]

_BEG = ";   >>> {title} -- verbatim listing of the INCBIN'd source (regen: inject_incbin_listing) >>>"
_END = ";   <<< end listing <<<"


def _body_lines(src_path: Path) -> list[str]:
    """The source's real listing lines: its leading license/header comment block
    and pure build housekeeping (DEVICE/SAVEBIN/.segment/.setcpu) removed; every
    remaining line (EQUs, ORG, labels, instructions, data + their comments) kept
    verbatim."""
    lines = src_path.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines) and (lines[i].lstrip().startswith(";") or not lines[i].strip()):
        i += 1
    out = []
    for l in lines[i:]:
        s = l.strip()
        if re.match(r"(?i)^(DEVICE|SAVEBIN)\b", s):
            continue
        if s.startswith(".segment") or s.startswith(".setcpu"):
            continue
        out.append(l.rstrip())
    while out and not out[-1].strip():
        out.pop()
    return out


def _listing_block(src_path: Path, title: str) -> list[str]:
    body = ["; " + l if l.strip() else ";" for l in _body_lines(src_path)]
    return [_BEG.format(title=title)] + body + [_END]


def _is_incbin_directive(line: str, incbin_name: str) -> bool:
    """True only for an actual INCBIN *directive* for `incbin_name`: ca65
    `.incbin "x"` or sjasmplus `INCBIN "x"` (dot optional, any case), anchored at
    line start so the "INCBIN'd source" text in a BEG-marker comment never matches."""
    return incbin_name in line and re.match(r"(?i)\s*\.?incbin\b", line) is not None


def _splice(host_lines: list[str], incbin_name: str, block: list[str]) -> list[str]:
    """Return host_lines with `block` placed immediately above the INCBIN line,
    replacing any existing block (delimited by the BEG/END markers) there."""
    idx = next(i for i, l in enumerate(host_lines)
               if _is_incbin_directive(l, incbin_name))
    # Drop an existing block for THIS incbin only. Its END marker sits directly
    # above the incbin line and its BEG marker above the body; deleting strictly
    # BEG..END keeps a DIFFERENT site's block (same file) untouched -- the bug
    # that previously deleted ProbeOvl when re-rendering ConInit.
    if idx >= 1 and host_lines[idx - 1].strip() == _END.strip():
        for k in range(idx - 2, max(0, idx - 800), -1):
            if (host_lines[k].lstrip().startswith(";   >>>")
                    and "verbatim listing of the INCBIN" in host_lines[k]):
                del host_lines[k:idx]      # BEG..END inclusive (idx is the incbin)
                idx = k
                break
    return host_lines[:idx] + block + host_lines[idx:]


def regen_all() -> list[Path]:
    """Rewrite every site's listing block from its source. Returns changed files."""
    changed = []
    for host, binname, src, title in SITES:
        lines = host.read_text(encoding="utf-8").splitlines()
        new = _splice(list(lines), binname, _listing_block(src, title))
        if new != lines:
            host.write_text("\n".join(new) + "\n", encoding="utf-8", newline="\n")
            changed.append(host)
    return changed


def check_all() -> list[str]:
    """Return a list of human-readable problems: any site whose embedded listing
    block does not match its source (i.e. would change under regen_all)."""
    problems = []
    for host, binname, src, title in SITES:
        lines = host.read_text(encoding="utf-8").splitlines()
        want = _splice(list(lines), binname, _listing_block(src, title))
        if want != lines:
            problems.append(f"{host.name}: INCBIN listing for {binname} is out of "
                            f"sync with {src.name} (run inject_incbin_listing)")
    return problems


if __name__ == "__main__":
    import sys
    if "--check" in sys.argv:
        probs = check_all()
        print("\n".join(probs) if probs else "all INCBIN listings in sync")
        sys.exit(1 if probs else 0)
    ch = regen_all()
    print("regenerated:", ", ".join(p.name for p in ch) if ch else "(no changes)")
