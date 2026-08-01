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


def _headers_by_label(max_lines: int = 10):
    """label -> {tree: the comment block directly above it}, across the OS sources.

    Shared by the cross-tree audits. Each asks a different question of the same
    harvest: audit 3 whether two trees assert opposite STATES, audit 5 whether one
    tree gave up where another did not, audit 6 whether they disagree about what a
    numbered structure offset is.
    """
    described = defaultdict(dict)
    for tree in _TREES:
        for p in (SOFTCARD / tree / "os").rglob("*.asm"):
            src = p.read_text(encoding="utf-8", errors="replace").split(chr(10))
            for n, line in enumerate(src):
                m = _LABEL.match(line)
                if not m:
                    continue
                blk, j = [], n - 1
                while j >= 0 and src[j].lstrip().startswith(";") and len(blk) < max_lines:
                    blk.append(src[j].lstrip(" ;").strip())
                    j -= 1
                if blk:
                    described[m.group(1)].setdefault(tree, " ".join(reversed(blk)))
    return described


def audit_cross_tree_contradiction():
    """A label shared by several trees whose descriptions assert opposite things.

    This is the check that would have caught LISTST: the 60K said A=0 meant the
    list device was READY, the 44K trees said $00 meant NOT ready. Both cannot
    be true of the same two bytes.
    """
    described = _headers_by_label()

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


# ── audit 4: a BDOS function number described as a different function ────
#
# cpm22.inc is the single source of truth for the BDOS ABI, so a comment that
# names a function number AND a term belonging to a DIFFERENT function is a
# contradiction against it. Two such confusions have been found by hand, both in
# annotation that had already been through review:
#
#   fn $1B is Get Addr(Alloc) -- it returns the allocation BITMAP. It was
#     described as returning the DPB in four places (CPM60_installer.asm, COPY's
#     twin of the same code, CPM60_COM.md, BOOT_AND_PATCHING.md). That mislabel
#     hid what the twelve-block "cp/m sys" reservation is for, because the
#     free-space test on the bitmap reads as a "geometry sanity check" on a DPB.
#     The DPB is fn $1F.
#
#   fn $13 is F_DELETE. A COPY.asm header called it an open, and named BDOS 15
#     (which IS open) in the same breath.
#
# Unlike audits 1-3 this one scans .md as well as .asm/.s: both bad fn $1B
# claims had propagated into the 60K markdown, and a doc that contradicts
# cpm22.inc misleads exactly as effectively as a comment that does.
_FN_CLAIMS = [
    # (fn byte, what it actually is, regex for terms that belong to another fn)
    ("$1B", "Get Addr(Alloc), which returns the allocation bitmap; the DPB is fn $1F",
     re.compile(r"\bDPB\b|\bdisk param", re.I)),
    ("$13", "F_DELETE; open is fn $0F",
     re.compile(r"\bopens?\b|\bopening\b", re.I)),
]
_FN_MENTION = "(?:fn|function|BDOS)\\s*{}"


def audit_bdos_function_misdescription(paths=None):
    """Comments/docs naming a BDOS function number alongside another function's terms."""
    if paths is None:
        paths = sorted(list(SOFTCARD.rglob("*.asm")) + list(SOFTCARD.rglob("*.s"))
                       + list(SOFTCARD.rglob("*.md")))
    hits = []
    for p in paths:
        if "reference" in rel(p).split("/") or p.suffix == ".lst":
            continue          # the archive transcribes vendor manuals verbatim
        try:
            lines = p.read_text(encoding="utf-8", errors="replace").split("\n")
        except OSError:
            continue
        for n, line in enumerate(lines, 1):
            text = line if p.suffix == ".md" else line[comment_index(line):]
            if not text:
                continue
            for fn, truth, wrong in _FN_CLAIMS:
                mention = re.compile(_FN_MENTION.format(re.escape(fn)), re.I)
                if mention.search(text) and wrong.search(text):
                    hits.append((rel(p), n, fn, truth, text.strip()[:110]))
    return hits



# ── audit 5: one tree gave up where another had the answer ──────────────

_GAVE_UP = re.compile(r"\[\?\]|\bUNKNOWN\b|exact (?:purpose|intent)|"
                      r"not determinable|could not (?:be )?determine", re.I)


def audit_unknown_resolved_elsewhere():
    """A label marked unknown in one tree and explained in another.

    This is the check that would have caught the '$' SUBMIT probe. Both 44K
    BDOSes carried "[?] ... its exact intent is UNKNOWN" on ALLOC_VECTOR_BUILD
    while the 60K twin's header already said the test was "against the current
    user". Audit 3 could not see it: the trees did not assert opposite STATES,
    one simply stopped where the other kept going.

    Every hit is free information -- the answer is already in the repository.
    """
    hits = []
    for label, per_tree in sorted(_headers_by_label().items()):
        if len(per_tree) < 2:
            continue
        gave_up = {tr for tr, txt in per_tree.items() if _GAVE_UP.search(txt)}
        # "answers" means a substantive header that does not itself hedge
        answers = {tr for tr, txt in per_tree.items()
                   if tr not in gave_up and len(txt) > 60}
        if gave_up and answers:
            hits.append((label, sorted(gave_up), sorted(answers),
                         per_tree[sorted(answers)[0]][:140]))
    return hits


# ── audit 6: the trees disagree about what an offset IS ─────────────────

# The corpus writes the noun BEFORE the offset far more often than after:
#   "bump the FCB current-record byte (offset 12) and wrap it mod 32"
#   "the 16-byte block map at directory-entry offset $10"
# so capture up to three words on either side and let the caller compare sets.
_OFF_BEFORE = re.compile(
    r"([a-z][a-z0-9-]*(?:\s+[a-z][a-z0-9-]*){0,2})\s*\(?\s*"
    r"(?:at\s+)?offset\s+(\$?[0-9A-Fa-f]{1,2})", re.I)
_OFF_AFTER = re.compile(
    r"offset\s+(\$?[0-9A-Fa-f]{1,2})\s*(?:=|is|,|->)\s*(?:the\s+)?"
    r"([a-z][a-z0-9-]*(?:\s+[a-z][a-z0-9-]*){0,2})", re.I)
_STOPWORDS = {"and", "the", "of", "in", "to", "a", "an", "at", "on", "for", "with",
              "as", "from", "byte", "bytes", "field", "fields", "its", "this",
              "that", "it", "is", "are", "wrap", "bump", "step", "go", "open",
              # structure names, not field nouns: two trees both saying "FCB" agree
              # about nothing, so they must not mask a disagreement about the field
              "fcb", "dir", "directory", "entry", "then", "read", "copy", "called",
              "twins", "k"}


def _parse_off(tok: str) -> int:
    return int(tok[1:], 16) if tok.startswith("$") else int(tok, 10)


def _offset_nouns(text: str) -> dict:
    """{offset: {noun phrases this text says live there}}, filler words removed."""
    out = defaultdict(set)
    for rx, noun_first in ((_OFF_BEFORE, True), (_OFF_AFTER, False)):
        for m in rx.finditer(text):
            noun = m.group(1) if noun_first else m.group(2)
            tok = m.group(2) if noun_first else m.group(1)
            try:
                off = _parse_off(tok)
            except ValueError:
                continue
            words = [w for w in re.split(r"[\s-]+", noun.lower()) if w not in _STOPWORDS]
            if words:
                out[off].add(" ".join(words))
    return out


def audit_offset_noun_disagreement():
    """Two trees naming the SAME structure offset as two different things.

    The check that would have caught the EX mislabel: both 44K BDOSes called FCB
    offset 12 "the current-record byte" while the 60K twin called it "the extent
    byte". Audit 3 missed it because the trees disagreed about a NOUN, not about
    a state, and audit 5 missed it because neither tree hedged -- both were
    confident and one was wrong.

    Over-reports by design; two trees can legitimately describe one offset in
    different words. A human decides.
    """
    hits = []
    for label, per_tree in sorted(_headers_by_label().items()):
        if len(per_tree) < 2:
            continue
        by_tree = {tr: _offset_nouns(txt) for tr, txt in per_tree.items()}
        offsets = set().union(*(d.keys() for d in by_tree.values())) if by_tree else set()
        for off in sorted(offsets):
            claims = {tr: d[off] for tr, d in by_tree.items() if d.get(off)}
            if len(claims) < 2:
                continue
            allw = [w for s in claims.values() for w in s]
            # Compare at WORD level, not whole phrase: "block pointer map" and
            # "block map" are the same field described twice, and demanding an
            # exact phrase match reports every paraphrase. A disagreement is two
            # trees sharing NO significant word about the same offset.
            wordsets = [set(" ".join(s).split()) for s in claims.values()]
            if not set.intersection(*wordsets) and len(set(allw)) > 1:
                hits.append((label, off, {tr: sorted(s) for tr, s in claims.items()}))
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

    h4 = audit_bdos_function_misdescription()
    print(f"\n== 4. BDOS function number described as a different function: {len(h4)} ==")
    for f, ln, fn, truth, txt in h4:
        print(f"   {f}:{ln}  {fn} is {truth}\n      {txt}")

    h5 = audit_unknown_resolved_elsewhere()
    print("")
    print(f"== 5. marked unknown in one tree, explained in another: {len(h5)} ==")
    for label, gave, ans, txt in h5:
        print(f"   {label}: {gave} hedge; {ans} explain")
        print(f"      {txt}")

    h6 = audit_offset_noun_disagreement()
    print("")
    print(f"== 6. trees disagree about what an offset is: {len(h6)} ==")
    for label, off, claims in h6:
        detail = "; ".join(f"{tr}={sorted(s)}" for tr, s in claims.items())
        print(f"   {label} offset {off}: {detail}")

    print("")
    total = len(h1) + len(h2) + len(h3) + len(h4) + len(h5) + len(h6)
    print(f"total candidates: {total} "
          f"(all require human judgement; none is auto-corrected)")


if __name__ == "__main__":
    main()
