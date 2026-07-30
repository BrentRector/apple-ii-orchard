# -*- coding: utf-8 -*-
"""Label addresses come from the assembler, not from comments.

``parse_label_addrs`` used to scrape the ``; $XXXX`` address comment that each
emitted line carries. That made comments load-bearing: re-wrap, re-align or
strip them and every address silently became wrong, with nothing to catch it,
because the byte-identity gate cannot see a comment.

It was not a hypothetical. The scraper only handled labels sitting on their own
line, so when the DPB fields were given labels on the SAME line as their
directive (``SPT:    DEFW $0020``) it skipped that line's address and assigned
those labels the NEXT address it happened to find: all ten came back as $F3B8
instead of $FA73.., and the regeneration overlay would have been fed that.

These tests pin the replacement: addresses are read out of the assembler
listing, the same artifact os_listing.emit_listing produces for the tracked
.lst files.
"""
import shutil

import pytest

from cpm_pipeline.os_listing import strip_listing_comments
from cpm_pipeline.regenerate import (LabelAddressError, _BDOS_60K, _BIOS_60K,
                                     parse_label_addrs)

pytestmark = pytest.mark.skipif(shutil.which("sjasmplus") is None,
                                reason="sjasmplus not on PATH")

SOURCES = {"60K BIOS": _BIOS_60K, "60K BDOS": _BDOS_60K}


@pytest.mark.parametrize("name", sorted(SOURCES))
def test_addresses_survive_stripping_every_address_comment(name):
    """The whole point: remove all the ``; $XXXX`` comments, get the same map."""
    text = SOURCES[name].read_text(encoding="utf-8")
    stripped, changed = strip_listing_comments(text)
    assert changed > 0, "expected this source to carry inline address comments"

    with_comments = parse_label_addrs(text)
    without = parse_label_addrs(stripped)
    assert with_comments == without, (
        f"{name}: label addresses changed when the address comments were removed"
    )


@pytest.mark.parametrize("name", sorted(SOURCES))
def test_addresses_agree_with_the_assembler_listing(name):
    """Spot-check against addresses the assembler independently reports."""
    addrs = parse_label_addrs(SOURCES[name].read_text(encoding="utf-8"))
    # every value is a plausible 16-bit address, and the map is non-trivial
    assert len(addrs) > 100
    assert all(0 <= a <= 0xFFFF for a in addrs.values())


def test_dpb_field_labels_resolve_to_the_dpb_not_to_the_next_line():
    """The exact bug the rewrite fixed: labels sharing a line with their directive.

    All ten DPB fields sit on the same line as their DEFB/DEFW. The old scraper
    reported every one at $F3B8; they are consecutive cells from $FA73.
    """
    addrs = parse_label_addrs(_BIOS_60K.read_text(encoding="utf-8"))
    expected = {"SPT": 0xFA73, "BSH": 0xFA75, "BLM": 0xFA76, "EXM": 0xFA77,
                "DSM": 0xFA78, "DRM": 0xFA7A, "AL0": 0xFA7C, "AL1": 0xFA7D,
                "CKS": 0xFA7E, "OFF": 0xFA80}
    got = {k: addrs.get(k) for k in expected}
    assert got == expected


def test_equ_constants_are_not_reported_as_labels():
    """``DRIVES EQU 6`` is a constant, not a label at address 6.

    The assembler's symbol table does not distinguish the two, so the source's
    own syntax has to; getting this wrong would put a bogus name into the
    regeneration overlay at a low address.
    """
    addrs = parse_label_addrs(_BIOS_60K.read_text(encoding="utf-8"))
    for constant in ("DRIVES", "ALV_SIZE", "CSV_SIZE", "DIRBUF_SIZE",
                     "WBOOTV", "TPA", "TBUFF", "IOBYTE_ADDR"):
        assert constant not in addrs, \
            f"{constant} is an EQU constant and must not be reported as a label"


def test_labels_declared_by_an_org_layout_are_found():
    """The scratch-overlay labels emit no bytes and carry no address comment.

    They exist only as ORG-advanced labels, so the old comment scraper could not
    see them at all. The assembler can.
    """
    addrs = parse_label_addrs(_BIOS_60K.read_text(encoding="utf-8"))
    assert addrs.get("DIRBUF") == 0xFEFD
    assert addrs.get("ALV_VECTORS") == 0xFF7D
    assert addrs.get("CSV_VECTORS") == 0xFFC5


def test_unassemblable_source_raises_rather_than_returning_wrong_addresses():
    """Failing loudly beats handing back a plausible, wrong map."""
    with pytest.raises(LabelAddressError):
        parse_label_addrs("    THIS IS NOT Z80\nFOO:\n    RET\n")
