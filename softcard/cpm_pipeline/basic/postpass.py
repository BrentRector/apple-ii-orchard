"""Post-emission cleanups applied to the assembled source lines (byte-identical)."""
import re

_DEF = re.compile(r'^((?:L|SUB)_[0-9A-Fa-f]{4}):\s*$')
_TOK = re.compile(r'\b((?:L|SUB)_[0-9A-Fa-f]{4})\b')


def drop_orphan_labels(lines, keep=()):
    """Remove bare machine-label definitions (``L_xxxx:`` / ``SUB_xxxx:``) that are
    never referenced anywhere else in the source. Such orphans arise when the harvest
    mints a header label for an address whose body reference is later kept literal (a
    coded constant / mid-pointer): the reference disappears but the definition strands,
    splitting a string or table for no reason. Removing an unreferenced label is
    zero-width -> byte-identical.

    `keep` is a set of machine-label NAMES to never drop even if they look orphaned --
    used for a label the OVERLAY renames and a header operand references only by the
    future semantic name (e.g. INTERP_COPY_END at the LDDR copy boundary: the relocator's
    `LD DE,$8482` operand is rewritten to `INTERP_COPY_END-1` only in apply_naming, so the
    L_8483 def looks unreferenced here and would otherwise strand)."""
    keep = set(keep)
    counts = {}
    for ln in lines:
        for m in _TOK.finditer(ln):
            counts[m.group(1)] = counts.get(m.group(1), 0) + 1
    out = []
    for ln in lines:
        dm = _DEF.match(ln)
        if dm and dm.group(1) not in keep and counts.get(dm.group(1), 0) <= 1:
            continue
        out.append(ln)
    return out
