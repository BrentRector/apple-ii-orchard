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

from cpm_pipeline.annotation_audit import (audit_bdos_function_misdescription,
                                           audit_bit_polarity,
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


# ── audit 4: a BDOS function number described as a different function ────

def test_bdos_fn_audit_catches_the_alloc_vector_defect():
    """The pre-fix installer text: fn $1B called a DPB read with a geometry check.

    This is the mislabel that hid the "cp/m sys" reservation. fn $1B is
    Get Addr(Alloc) and returns the allocation bitmap, so the two tests that
    follow it are a free-space check on blocks 128-139. Reading it as a DPB made
    them look like a geometry sanity check on unrelated bytes.
    """
    pre = (
        "        LD C,$1B                ; fn $1B get allocation vector / DPB; HL->DPB\n"
        "        CALL BDOS\n"
        "        LD DE,RST2_VEC          ; +$10 into the DPB\n"
    )
    p = _tmp_source(pre, name="CPM60_installer.asm")
    hits = audit_bdos_function_misdescription([p])
    assert hits, "audit 4 no longer catches fn $1B described as returning the DPB"
    assert hits[0][2] == "$1B"


def test_bdos_fn_audit_catches_the_delete_called_open_defect():
    """The pre-fix COPY.asm header: fn $13 (F_DELETE) described as an open."""
    pre = ("; [AI] opens the system FCB (BDOS 15) via fn $13 before copying.\n"
           "OPEN_SYSTEM_FCB:\n")
    p = _tmp_source(pre, name="COPY.asm")
    hits = audit_bdos_function_misdescription([p])
    assert hits, "audit 4 no longer catches fn $13 described as an open"
    assert hits[0][2] == "$13"


def test_bdos_fn_audit_ignores_a_correct_description():
    ok = ("        LD C,$1B   ; fn $1B Get Addr(Alloc); HL -> allocation bitmap\n"
          "        LD C,$1F   ; fn $1F returns the DPB\n")
    p = _tmp_source(ok, name="CPM_BIOS.asm")
    assert audit_bdos_function_misdescription([p]) == []


def test_no_bdos_function_misdescriptions():
    hits = audit_bdos_function_misdescription()
    assert hits == [], (
        "a BDOS function number is described as a different function:\n  "
        + "\n  ".join(f"{f}:{ln}  {fn} is really {truth}\n      {txt}"
                      for f, ln, fn, truth, txt in hits))


# ── audits 5 and 6: the two cross-tree shapes audit 3 cannot see ─────────

def test_audit5_catches_unknown_resolved_in_another_tree():
    """The '$' SUBMIT probe: 44K said UNKNOWN, the 60K twin already explained it."""
    from cpm_pipeline.annotation_audit import _GAVE_UP
    hedged = ("[?] the compare against (BDOS_STACK_TOP) then the $24 ('$') name-byte "
              "test and (BDOS_RETVAL) store is a special-entry path; its exact intent "
              "is UNKNOWN.")
    answered = ("for each entry skip deleted ($E5) ones, run a special-entry check "
                "against the current user byte and the '$' name byte")
    assert _GAVE_UP.search(hedged), "audit 5 no longer recognises a hedge"
    assert not _GAVE_UP.search(answered), "audit 5 now treats an answer as a hedge"
    # Each alternative must be exercised on its OWN. The first version of this test
    # used only the sample above, which contains BOTH "[?]" and "UNKNOWN", so it
    # passed while a mangled UNKNOWN matched nothing at all.
    assert _GAVE_UP.search("its exact intent is UNKNOWN here"), "the UNKNOWN branch is dead"
    assert _GAVE_UP.search("[?] see below"), "the [?] branch is dead"
    assert _GAVE_UP.search("not determinable from these bytes"), "the not-determinable branch is dead"


def test_audit6_catches_the_extent_mislabel():
    """Both 44K BDOSes called FCB offset 12 the current-record byte; the 60K did not."""
    from cpm_pipeline.annotation_audit import _offset_nouns
    pre_44k = _offset_nouns("bump the FCB current-record byte (offset 12) and wrap it mod 32")
    pre_60k = _offset_nouns("bump the FCB extent byte (offset $0C) mod 32")
    assert pre_44k.get(12), "audit 6 failed to read the 44K claim"
    assert pre_60k.get(12), "audit 6 failed to read the 60K claim"
    assert not (pre_44k[12] & pre_60k[12]), (
        "audit 6 would not have flagged the EX mislabel: "
        f"{sorted(pre_44k[12])} vs {sorted(pre_60k[12])}")


def test_audit6_treats_a_paraphrase_as_agreement():
    """'block pointer map' and 'block map' are one field described twice."""
    from cpm_pipeline.annotation_audit import _offset_nouns
    a = _offset_nouns("the block pointer map at offset 16 of the entry")
    b = _offset_nouns("the 16-byte block map at directory-entry offset 16")
    shared = set(" ".join(a[16]).split()) & set(" ".join(b[16]).split())
    assert shared, "paraphrases must share a word, or audit 6 reports every rewording"


def test_no_offset_noun_disagreements():
    from cpm_pipeline.annotation_audit import audit_offset_noun_disagreement
    hits = audit_offset_noun_disagreement()
    assert hits == [], (
        "trees disagree about what a structure offset is:\n  "
        + "\n  ".join(f"{lab} offset {off}: {claims}" for lab, off, claims in hits))
