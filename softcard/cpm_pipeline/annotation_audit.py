# -*- coding: utf-8 -*-
"""Audits for annotation defects the byte-identity gate cannot see.

Comments and labels emit no bytes, so a source can round-trip perfectly while
telling a reader something false. Three defects of that kind have been found by
hand so far, all in ``[RE]``-marked (hand-reviewed) annotation rather than
``[AI]``-marked (machine-generated, already flagged as unverified):

  1. the BDOS block allocator described the allocation bit backwards;
  2. two 44K BIOS jump-table entries were dumped as an opaque ``DEFB`` run with
     a comment asserting the bytes were "not reached as code";
  3. the same two bytes were then described in OPPOSITE terms by two trees.

Each audit below targets one of those shapes. They over-report by design: every
hit is printed for a human to judge, never auto-corrected, because deciding what
a routine means is not something a regex can do.

Run as ``python -m cpm_pipeline.annotation_audit``.
"""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

SOFTCARD = Path(__file__).resolve().parent.parent

# ── shared helpers ───────────────────────────────────────────────────────

_LABEL = re.compile(r"^([A-Za-z_]\w*):")
_DATA = re.compile(r"^\s*DEFB\b", re.I)


def comment_index(line: str) -> int:
    """Index of the ';' that starts a comment, ignoring quoted semicolons."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
        elif ch == ";":
            return i
    return -1


def code_of(line: str) -> str:
    i = comment_index(line)
    return line if i < 0 else line[:i]


def sources() -> list[Path]:
    return sorted(list(SOFTCARD.rglob("*.asm")))


def rel(p: Path) -> str:
    return str(p).replace("\\", "/").split("softcard/")[-1]


# ── audit 1: bit polarity stated against the branch ──────────────────────

_ROT = re.compile(r"^\s*(RRA|RLA|RRCA|RLCA|RR|RL|SRL|SLA|SRA)\b", re.I)
_BR = re.compile(r"^\s*(?:JP|JR|CALL|RET)\s+(NC|NZ|C|Z)\b", re.I)
_SET_CLAIM = re.compile(r"\b(in[- ]use|already in use|is set|bit set|allocated|"
                        r"occupied|taken)\b", re.I)
_CLR_CLAIM = re.compile(r"\b(free|unused|is clear|bit clear|available|"
                        r"not in use|unallocated)\b", re.I)


def audit_bit_polarity(paths):
    """Comments whose stated bit sense the branch condition contradicts.

    Only the shape where a bit reaches a flag via a rotate is considered, which
    is where the allocator defect lived: a rotate puts bit 0 into carry, so
    ``JP NC`` is taken when the bit is CLEAR. A comment on that branch claiming
    the bit is SET is inverted.
    """
    hits = []
    for p in paths:
        lines = p.read_text(encoding="utf-8", errors="replace").split("\n")
        for n, line in enumerate(lines):
            m = _BR.match(code_of(line))
            if not m:
                continue
            cond = m.group(1).upper()
            k, looked, found = n - 1, 0, False
            while k >= 0 and looked < 4:
                c = code_of(lines[k])
                if c.strip():
                    looked += 1
                    if _ROT.match(c):
                        found = True
                        break
                    if re.match(r"^\s*(CALL|JP|JR|RET)\b", c, re.I) and looked > 1:
                        break
                k -= 1
            if not found:
                continue
            branch_means_set = cond == "C"
            ctx = []
            if comment_index(line) >= 0:
                ctx.append((n + 1, line[comment_index(line) + 1:].strip()))
            j = n - 1
            while j >= 0 and lines[j].lstrip().startswith(";") and len(ctx) < 3:
                ctx.append((j + 1, lines[j].lstrip(" ;").strip()))
                j -= 1
            for ln, text in ctx:
                s, c2 = _SET_CLAIM.search(text), _CLR_CLAIM.search(text)
                if bool(s) == bool(c2):
                    continue
                if bool(s) != branch_means_set:
                    hits.append((rel(p), ln, text[:88]))
    return hits


# ── audit 2: data that is really code ────────────────────────────────────

# Z-80 opcodes that make a byte run implausible as data if the run decodes
# cleanly end-to-end. Kept deliberately small: single-byte instructions whose
# presence together with a clean length fit is suggestive, not proof.
_Z80_1B = {0xC9: "RET", 0xAF: "XOR A", 0x60: "LD H,B", 0x69: "LD L,C",
           0x7E: "LD A,(HL)", 0x23: "INC HL", 0x00: "NOP", 0xE1: "POP HL",
           0xD1: "POP DE", 0xC5: "PUSH BC", 0xEB: "EX DE,HL"}
_NOT_CODE_CLAIM = re.compile(r"\b(opaque|not reached|never reached|not code|"
                             r"unreached|dead|filler|trailer|padding)\b", re.I)


def audit_data_that_may_be_code(paths):
    """DEFB runs near a jump table, or claimed inert, that look like Z-80.

    The 44K BIOS "post-vector trailer" was six bytes -- XOR A / RET / NOP /
    LD H,B / LD L,C / RET -- sitting immediately after the last JP of the BIOS
    jump table and annotated as opaque and "not reached as code". They were
    jump-table entries 15 and 16 written inline.
    """
    hits = []
    for p in paths:
        lines = p.read_text(encoding="utf-8", errors="replace").split("\n")
        recent_jp = -99
        for n, line in enumerate(lines):
            c = code_of(line)
            if re.match(r"^\s*JP\s+", c, re.I):
                recent_jp = n
            if not _DATA.match(c):
                continue
            byts = re.findall(r"\$([0-9A-Fa-f]{2})\b", c)
            if not 2 <= len(byts) <= 12:
                continue
            vals = [int(b, 16) for b in byts]
            # A run of $00 is padding, not code. $00 decodes as NOP, so an
            # all-zero run would otherwise score 100%; require some real
            # instruction variety before calling a DEFB run suspicious.
            nonzero = [v for v in vals if v != 0x00]
            if len(set(nonzero)) < 2:
                continue
            known = sum(1 for v in vals if v in _Z80_1B)
            near_table = n - recent_jp <= 2
            # the comment block above, for an "inert" claim
            blk, j = [], n - 1
            while j >= 0 and lines[j].lstrip().startswith(";") and len(blk) < 4:
                blk.append(lines[j])
                j -= 1
            claims_inert = bool(_NOT_CODE_CLAIM.search(" ".join(blk)))
            if (near_table and known >= len(vals) * 0.6) or \
               (claims_inert and known >= len(vals) * 0.6):
                why = []
                if near_table:
                    why.append("adjacent to a JP table")
                if claims_inert:
                    why.append("annotated as inert")
                hits.append((rel(p), n + 1,
                             f"{known}/{len(vals)} bytes are common Z-80 opcodes; "
                             + " and ".join(why), c.strip()[:64]))
    return hits


# ── audit 3: the same bytes annotated differently across trees ───────────

_TREES = ("CPMV220-44K", "CPMV223-44K", "CPMV223-60K")
# Deliberately NOT ("set", "clear"): those words carry too many senses in this
# corpus -- "leave hstact set", "clear unacnt", "carry set => below space" -- and
# produced only false positives. The pairs kept are ones that describe a device
# or resource STATE, where two trees asserting opposite values of the same label
# is a genuine contradiction rather than two views of a long routine.
_POLAR = [("ready", "not ready"), ("in use", "free"),
          ("enabled", "disabled"), ("present", "absent")]


def audit_cross_tree_contradiction():
    """A label shared by several trees whose descriptions assert opposite things.

    This is the check that would have caught LISTST: the 60K said A=0 meant the
    list device was READY, the 44K trees said $00 meant NOT ready. Both cannot
    be true of the same two bytes.
    """
    described = defaultdict(dict)          # label -> {tree: header text}
    for tree in _TREES:
        for p in (SOFTCARD / tree / "os").rglob("*.asm"):
            lines = p.read_text(encoding="utf-8", errors="replace").split("\n")
            for n, line in enumerate(lines):
                m = _LABEL.match(line)
                if not m:
                    continue
                blk, j = [], n - 1
                while j >= 0 and lines[j].lstrip().startswith(";") and len(blk) < 10:
                    blk.append(lines[j].lstrip(" ;").strip())
                    j -= 1
                if blk:
                    described[m.group(1)].setdefault(tree, " ".join(reversed(blk)))

    hits = []
    for label, per_tree in sorted(described.items()):
        if len(per_tree) < 2:
            continue
        for pos, neg in _POLAR:
            pos_re = re.compile(rf"(?<!not )\b{re.escape(pos)}\b", re.I)
            neg_re = re.compile(rf"\b{re.escape(neg)}\b", re.I)
            says_pos = {t for t, txt in per_tree.items()
                        if pos_re.search(txt) and not neg_re.search(txt)}
            says_neg = {t for t, txt in per_tree.items() if neg_re.search(txt)}
            if says_pos and says_neg:
                hits.append((label, pos, sorted(says_pos), neg, sorted(says_neg)))
                break
    return hits


def main():
    paths = sources()
    print(f"scanned {len(paths)} .asm files under softcard/\n")

    h1 = audit_bit_polarity(paths)
    print(f"== 1. bit polarity contradicted by the branch: {len(h1)} ==")
    for f, ln, t in h1:
        print(f"   {f}:{ln}  {t}")

    h2 = audit_data_that_may_be_code(paths)
    print(f"\n== 2. DEFB runs that may be code: {len(h2)} ==")
    for f, ln, why, txt in h2:
        print(f"   {f}:{ln}  {why}\n      {txt}")

    h3 = audit_cross_tree_contradiction()
    print(f"\n== 3. same label described in opposite terms across trees: {len(h3)} ==")
    for label, pos, tp, neg, tn in h3:
        print(f"   {label}: {tp} say '{pos}'; {tn} say '{neg}'")

    print(f"\ntotal candidates: {len(h1) + len(h2) + len(h3)} "
          f"(all require human judgement; none is auto-corrected)")


if __name__ == "__main__":
    main()
