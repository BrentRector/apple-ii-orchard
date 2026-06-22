# -*- coding: utf-8 -*-
"""Lint the BASIC.asm master + its shared includes.

BASIC.asm is the hand-edited MASTER for the GBASIC/MBASIC fold (see
CPMV220-44K/utilities/PROVENANCE.md). Edits now go in directly, so we no longer get
apply_naming's automatic comment-sanitize. The byte-fidelity gate
(test_fold_build_byte_identical) proves source<->binary but is BLIND to comments. This
lint covers the one guardrail direct editing loses: it asserts the master and the
includes it pulls in stay pure ASCII, catching mojibake (e.g. a UTF-8 em-dash or smart
quote pasted into a comment) that the byte gate would silently pass.
"""
import re
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]                       # softcard/
MASTER = REPO / "CPMV220-44K" / "utilities" / "BASIC.asm"


def _referenced_includes(text):
    return [REPO / "include" / m
            for m in re.findall(r'(?im)^\s*INCLUDE\s+"([^"]+)"', text)]


@pytest.mark.skipif(not MASTER.exists(), reason="BASIC.asm master not present")
def test_master_and_includes_are_ascii():
    text = MASTER.read_text(encoding="latin-1")
    targets = [MASTER] + [p for p in _referenced_includes(text) if p.exists()]
    bad = {}
    for p in targets:
        for i, line in enumerate(p.read_text(encoding="latin-1").splitlines(), 1):
            nonascii = [(hex(ord(c)), c) for c in line if ord(c) > 127]
            if nonascii:
                bad.setdefault(p.name, []).append((i, nonascii[:5]))
    assert not bad, (
        "non-ASCII (mojibake?) in the BASIC master/includes -- direct edits must stay "
        f"ASCII: { {k: v[:3] for k, v in bad.items()} }")
