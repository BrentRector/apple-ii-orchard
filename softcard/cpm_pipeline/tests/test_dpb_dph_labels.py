# -*- coding: utf-8 -*-
"""The DPB and DPH structures stay decoded, and use the same names in every tree.

Two things this guards, neither of which the byte-identity gate can see (labels
and comments emit no bytes, so a source can regress all the way back to an
opaque blob and still round-trip perfectly):

1. The Disk Parameter Block is a labelled structure, not a bare DEFW/DEFB run,
   in all three BIOS sources; and the DPH entries reference those labels rather
   than magic addresses.

2. The same symbol means the same thing across the 2.20-44K, 2.23-44K and
   2.23-60K trees, so a reader (or an article) can carry one vocabulary between
   them.

There is a live way to lose all of this: ``regenerate_60k_bios(write=True)``
re-disassembles the 60K BIOS from its bytes and emits its own rendering, which
drops the hand-decoded DPH table back to a DEFS/DEFB blob and drops the overlay
declaration entirely. It is byte-identical either way, so only a test like this
one notices. Nothing invokes it with write=True today; this makes it fail loudly
if that changes.
"""
import re

import pytest

from cpm_pipeline.chunk_map import OS220_44K, OS223_44K
from cpm_pipeline.regenerate import _BIOS_60K

# The ten Digital Research CP/M 2.2 DPB field names, in layout order.
DPB_FIELDS = ["SPT", "BSH", "BLM", "EXM", "DSM", "DRM", "AL0", "AL1", "CKS", "OFF"]

# The scratch-vector names the DPH entries hand out, shared by all three trees.
SCRATCH = ["DIRBUF", "ALV_VECTORS", "CSV_VECTORS"]

BIOS_SOURCES = {
    "2.20-44K": OS220_44K / "CPM_BIOS.asm",
    "2.23-44K": OS223_44K / "CPM_BIOS.asm",
    "2.23-60K": _BIOS_60K,
}


def source(tree):
    return BIOS_SOURCES[tree].read_text(encoding="utf-8")


def code_lines(text):
    """Non-comment lines."""
    return [l.split(";")[0] for l in text.split("\n") if not l.lstrip().startswith(";")]


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_dpb_fields_are_labels(tree):
    """Every DPB field carries its own label on its own directive."""
    lines = code_lines(source(tree))
    for field in DPB_FIELDS:
        assert any(re.match(rf"^{field}:\s+DEF[BW]\s", l) for l in lines), (
            f"{tree}: DPB field {field} is not a label on its own DEFB/DEFW "
            f"(the block may have regressed to an undecoded blob)"
        )


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_dpb_field_order_matches_the_cpm22_layout(tree):
    """The labels appear in the order the CP/M 2.2 DPB defines them."""
    lines = code_lines(source(tree))
    seen = [f for l in lines for f in DPB_FIELDS if re.match(rf"^{f}:\s+DEF[BW]\s", l)]
    assert seen == DPB_FIELDS, f"{tree}: DPB fields out of order: {seen}"


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_dph_entries_reference_labels_not_addresses(tree):
    """Each DPH row points at DIRBUF / DPB / CSV_VECTORS / ALV_VECTORS by name.

    A row like `DEFW 0,0,0,0,$FEFD,DPB,$FFC5,$FF7D` still assembles to the right
    bytes, but hides which buffer each pointer is and cannot be read against the
    other trees. Requiring the labels is what keeps the structure legible.
    """
    rows = [l for l in code_lines(source(tree)) if re.match(r"\s+DEFW\s+0,0,0,0,", l)]
    assert rows, f"{tree}: no DPH rows found"
    for row in rows:
        for name in ("DIRBUF", "DPB", "CSV_VECTORS", "ALV_VECTORS"):
            assert re.search(rf"\b{name}\b", row), \
                f"{tree}: DPH row does not reference {name}: {row.strip()}"
        assert not re.search(r"\$[0-9A-Fa-f]{4}", row), \
            f"{tree}: DPH row still contains a raw address: {row.strip()}"


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_scratch_overlay_is_declared_as_a_layout(tree):
    """DIRBUF/ALV_VECTORS/CSV_VECTORS are labels from an ORG'd layout block.

    They name a SECOND tenant of bytes the cold-boot code owns, so they are
    declared with their own ORG and sized by arithmetic rather than written as
    magic EQU addresses.
    """
    text = source(tree)
    lines = code_lines(text)
    for name in SCRATCH:
        assert any(re.match(rf"^{name}:\s*(;.*)?$", l.rstrip()) or
                   re.match(rf"^{name}:\s*$", l.rstrip()) for l in lines), \
            f"{tree}: {name} is not defined as a label in the overlay layout"
        assert not re.search(rf"^{name}\s+EQU\s+\$", text, re.M), \
            f"{tree}: {name} is an opaque EQU address; it should be an ORG'd label"
    assert re.search(r"^\s+ORG\s+.*\n\s*DIRBUF:", text, re.M), \
        f"{tree}: the overlay layout does not start with an ORG at DIRBUF"
    # sizes derived, not magic
    assert re.search(r"^ALV_SIZE\s+EQU\s+\d+\s*/\s*8\s*\+\s*1", text, re.M), \
        f"{tree}: ALV_SIZE should be written as DSM/8 + 1"


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_layout_is_pinned_by_assertions(tree):
    """The derived layout is ASSERTed against the shipped addresses."""
    text = source(tree)
    assert len(re.findall(r"^\s+ASSERT\s+(ALV_VECTORS|CSV_VECTORS|BIOS_SCRATCH_END)",
                          text, re.M)) >= 3, \
        f"{tree}: overlay layout is not pinned by ASSERTs"


def test_all_three_trees_share_one_vocabulary():
    """The same names mean the same thing in every tree."""
    for name in DPB_FIELDS + SCRATCH + ["DPB", "DPH_TABLE"]:
        missing = [t for t in BIOS_SOURCES if not re.search(rf"^{name}[:\s]", source(t), re.M)]
        assert not missing, f"{name} is absent from: {missing}"


def test_the_two_223_trees_carry_the_same_dpb_and_220_differs_only_in_dsm():
    """2.20 vs 2.23 differ in exactly one DPB field, and the 2.23 pair agree."""
    def fields(tree):
        out = {}
        for l in code_lines(source(tree)):
            m = re.match(r"^(\w+):\s+DEF[BW]\s+(\$[0-9A-Fa-f]+)", l)
            if m and m.group(1) in DPB_FIELDS:
                out[m.group(1)] = int(m.group(2)[1:], 16)
        return out

    v220, v223, v60k = fields("2.20-44K"), fields("2.23-44K"), fields("2.23-60K")
    assert v223 == v60k, "the two 2.23 DPBs must be identical"
    differing = {k for k in DPB_FIELDS if v220[k] != v223[k]}
    assert differing == {"DSM"}, f"2.20 vs 2.23 should differ only in DSM, got {differing}"
    assert (v220["DSM"], v223["DSM"]) == (0x7F, 0x8B)


@pytest.mark.parametrize("tree", sorted(BIOS_SOURCES))
def test_alv_stride_matches_the_trees_own_dsm(tree):
    """ALV_SIZE is derived from the DSM this BIOS actually publishes."""
    text = source(tree)
    dsm = int(re.search(r"^DSM:\s+DEFW\s+\$([0-9A-Fa-f]+)", text, re.M).group(1), 16)
    declared = int(re.search(r"^ALV_SIZE\s+EQU\s+(\d+)\s*/\s*8", text, re.M).group(1))
    assert declared == dsm, (
        f"{tree}: ALV_SIZE is derived from {declared} but this DPB's DSM is {dsm}"
    )
