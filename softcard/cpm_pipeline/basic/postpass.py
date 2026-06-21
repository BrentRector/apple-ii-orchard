"""Post-emission cleanups applied to the assembled source lines (byte-identical)."""
import re

_DEF = re.compile(r'^((?:L|SUB)_[0-9A-Fa-f]{4}):\s*$')
_TOK = re.compile(r'\b((?:L|SUB)_[0-9A-Fa-f]{4})\b')


def drop_orphan_labels(lines):
    """Remove bare machine-label definitions (``L_xxxx:`` / ``SUB_xxxx:``) that are
    never referenced anywhere else in the source. Such orphans arise when the harvest
    mints a header label for an address whose body reference is later kept literal (a
    coded constant / mid-pointer): the reference disappears but the definition strands,
    splitting a string or table for no reason. Removing an unreferenced label is
    zero-width -> byte-identical."""
    counts = {}
    for ln in lines:
        for m in _TOK.finditer(ln):
            counts[m.group(1)] = counts.get(m.group(1), 0) + 1
    out = []
    for ln in lines:
        dm = _DEF.match(ln)
        if dm and counts.get(dm.group(1), 0) <= 1:   # only the definition itself
            continue
        out.append(ln)
    return out
