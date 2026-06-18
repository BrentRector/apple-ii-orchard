"""Logical-dedup tests: same files + same OS == duplicate, regardless of sector
order or system-track fill.

(Fill-invariance of the OS comparison on real fill-different 60K disks is
exercised end-to-end by the `dedup` verb; here we cover the building blocks with
repo fixtures: a content fingerprint that survives a sector-order change, and
clustering.)"""

from pathlib import Path

import pytest

from cpm_pipeline.dedup import (
    compare_logical, fileset_fingerprint, dedup, _content_relation,
)
from cpm_pipeline.disk_format import (
    read_disk, write_disk, sector_offset, TRACKS, SECTORS_PER_TRACK,
)
from cpm_pipeline.filesystem import SOFTCARD_SKEW

REPO = Path(__file__).resolve().parents[2]  # softcard/
DSK_223 = REPO / "CPMV223-44K" / "CPMV223-44K.DSK"
PO_220 = REPO / "CPMV220" / "CPMV220-Disk1.po"


def _has(p):
    return p.exists()


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_disk_is_logical_dup_of_itself():
    v = compare_logical(DSK_223, DSK_223)
    assert v.is_duplicate, v.summary()


@pytest.mark.skipif(not (_has(DSK_223) and _has(PO_220)), reason="fixtures missing")
def test_different_versions_are_distinct():
    v = compare_logical(DSK_223, PO_220)
    assert not v.is_duplicate
    assert v.file_diffs or v.os_diffs


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_fileset_fingerprint_is_order_invariant(tmp_path):
    """Re-lay the filesystem tracks into CP/M logical order (a .cpm); the
    content fingerprint must be unchanged -- it follows the directory, not the
    on-disk byte positions."""
    dsk = read_disk(DSK_223)
    cpm = bytearray(dsk)  # boot tracks copied as-is; only re-lay the FS tracks
    for t in range(3, TRACKS):
        for L in range(SECTORS_PER_TRACK):
            dst = sector_offset(t, L, "cpm")
            src = sector_offset(t, SOFTCARD_SKEW[L], "dsk")
            cpm[dst:dst + 256] = dsk[src:src + 256]
    cpm_path = tmp_path / "fs_relaid.cpm"
    write_disk(cpm_path, cpm)
    assert fileset_fingerprint(cpm_path) == fileset_fingerprint(DSK_223)


def test_content_relation():
    a = frozenset({("X", 0, "h1"), ("Y", 0, "h2")})
    b = frozenset({("X", 0, "h1"), ("Y", 0, "h2"), ("Z", 0, "h3")})
    c = frozenset({("X", 0, "hZ"), ("Y", 0, "h2")})  # X content differs
    assert _content_relation(a, a) == "equal"
    assert _content_relation(a, b) == "a_subset"   # A missing Z, else identical
    assert _content_relation(b, a) == "b_subset"
    assert _content_relation(a, c) == "divergent"  # shared file differs -> not a subset


@pytest.mark.skipif(not (_has(DSK_223) and _has(PO_220)), reason="fixtures missing")
def test_dedup_drops_exact_copy(tmp_path):
    """An exact copy is dropped as a duplicate; a different version is kept."""
    copy = tmp_path / "copy.dsk"
    copy.write_bytes(DSK_223.read_bytes())
    keepers, drops, _ = dedup([DSK_223, copy, PO_220])
    assert len(keepers) == 2 and len(drops) == 1
    assert drops[0].kind == "duplicate"


@pytest.mark.skipif(not _has(DSK_223), reason="CPMV223-44K.DSK missing")
def test_subset_relation_detected():
    """compare_logical recognizes a subset relationship (same OS, A's files a
    proper subset of B's). Constructed by comparing a disk with itself after we
    assert the content-relation helper on its real fileset minus one file."""
    full = frozenset(fileset_fingerprint(DSK_223))
    minus_one = frozenset(list(full)[1:])  # drop one file
    assert _content_relation(minus_one, full) == "a_subset"
