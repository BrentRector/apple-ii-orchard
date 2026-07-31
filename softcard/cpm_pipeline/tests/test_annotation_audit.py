# -*- coding: utf-8 -*-
"""The annotation audits stay clean, and still catch what they were built for.

Three annotation defects have been found by hand in the recovered sources, all
in [RE]-marked (hand-reviewed) comments rather than [AI]-marked ones. Each audit
in cpm_pipeline.annotation_audit targets one shape. These tests do two things:

  * assert each audit still flags the original defect, using the pre-fix text --
    an audit that has quietly stopped working is worse than no audit;
  * assert the tree is currently clean, so a regression is loud.

Audit 1 (bit polarity) has two long-standing false positives in BASIC.asm, both
read individually: each comment correctly describes the loop-exit or
fall-through case rather than the branch-taken case. They are allowed for by
number so that a THIRD hit fails the test.
"""
import tempfile
from pathlib import Path

from cpm_pipeline.annotation_audit import (audit_bit_polarity,
                                           audit_cross_tree_contradiction,
                                           audit_data_that_may_be_code,
                                           sources)

# BASIC.asm:13181 and :13572 -- comments describing the loop exit / fall-through.
KNOWN_BENIGN_POLARITY = 2


def _tmp_source(text, name="CPM_BIOS.asm"):
    td = tempfile.mkdtemp()
    p = Path(td) / name
    p.write_text(text, encoding="utf-8")
    return p


# ── the audits still catch their original defect ─────────────────────────

def test_bit_polarity_audit_catches_the_allocator_defect():
    """The pre-fix allocator comment: 'in use' on a branch taken when free."""
    pre = (
        "ALLOC_SCAN_DOWN:\n"
        "        CALL ALLOC_BIT_GET\n"
        "        ; carry = the tested block's in-use bit\n"
        "        RRA\n"
        "        ; block already in use -> mark and finish\n"
        "        JP NC,ALLOC_MARK_DONE\n"
    )
    hits = audit_bit_polarity([_tmp_source(pre, "CPM_BDOS.asm")])
    assert hits, "the polarity audit no longer catches the allocator defect"


def test_data_audit_catches_the_post_vector_trailer():
    """The pre-fix 44K BIOS trailer: jump-table entries 15/16 called opaque."""
    pre = (
        "        JP      READ\n"
        "        JP      WRITE\n"
        "        ; post-vector trailer: $AF $C9 then 4 opaque bytes;\n"
        "        ; [RE] not reached as code here.\n"
        "        DEFB    $AF,$C9,$00,$60,$69,$C9\n"
    )
    hits = audit_data_that_may_be_code([_tmp_source(pre)])
    assert hits, "the data-may-be-code audit no longer catches the trailer"


def test_data_audit_ignores_zero_padding():
    """A run of $00 is padding; $00 decodes as NOP so it must not score."""
    pad = ("        JP      WRITE\n"
           "        DEFB    $00,$00,$00,$00\n")
    assert audit_data_that_may_be_code([_tmp_source(pad)]) == []


def test_cross_tree_audit_catches_opposite_state_claims():
    """The LISTST contradiction: one tree said 'ready', another 'not ready'."""
    import re
    pos_re = re.compile(r"(?<!not )\bready\b", re.I)
    neg_re = re.compile(r"\bnot ready\b", re.I)
    said_ready = "report the list device ready. Out: A=0 (always 'ready'/no status)."
    said_not = "Under the CP/M 2.2 convention $00 means NOT ready and $FF means ready."
    assert pos_re.search(said_ready) and not neg_re.search(said_ready)
    assert neg_re.search(said_not)


# ── and the tree is currently clean ──────────────────────────────────────

def test_no_new_bit_polarity_contradictions():
    hits = audit_bit_polarity(sources())
    assert len(hits) <= KNOWN_BENIGN_POLARITY, (
        "new bit-polarity contradiction(s):\n  "
        + "\n  ".join(f"{f}:{ln}  {t}" for f, ln, t in hits))


def test_no_data_runs_that_look_like_code():
    hits = audit_data_that_may_be_code(sources())
    assert hits == [], (
        "DEFB run(s) that may really be code:\n  "
        + "\n  ".join(f"{f}:{ln}  {why}" for f, ln, why, _ in hits))


def test_no_cross_tree_contradictions():
    hits = audit_cross_tree_contradiction()
    assert hits == [], (
        "the same label is described in opposite terms by different trees:\n  "
        + "\n  ".join(f"{lab}: {tp} say {pos!r}; {tn} say {neg!r}"
                      for lab, pos, tp, neg, tn in hits))
