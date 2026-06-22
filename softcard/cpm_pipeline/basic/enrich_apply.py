#!/usr/bin/env python
"""Apply a semantic-enrichment spec to the BASIC.asm master, byte-safely.

BASIC.asm is the hand-edited master (see CPMV220-44K/utilities/PROVENANCE.md). The
per-subsystem enrichment workflow produces a spec of C-level function headers, high-level
body comments, and label renames; this applies them by INSERTING comment lines and
RENAMING symbols only -- it never touches a code line -- so the assembled bytes are
unchanged (the fold byte-gate is the final proof).

Spec JSON: {"routines": [{
    "label": "OPEN_FILE",                # anchor: the routine's label exactly as in BASIC.asm
    "header": ["OPEN_FILE -- ...", "  In: ...", ...],          # C-level header text lines (no ';')
    "body_comments": [{"anchor": "CALL BDOS", "occ": 1, "comment": "open the file via the BDOS"}],
    "renames": [{"old": "L_7C26", "new": "PARSE_FILENAME_TO_FCB"}]
}]}

Header text replaces the existing contiguous (non-banner) comment block directly above the
label, so the rich header supersedes any prior one-line [RE] note. Body comments are inserted
as full-line "; <intent>" above the occ-th line whose code matches the anchor, within the
routine's span (label -> next enriched label / section banner / EOF). Renames are global
(definition + refs + _N locals + comment mentions), applied last.
"""
import json
import re
import sys
from pathlib import Path

from cpm_pipeline.basic._paths import asm_path

MASTER = asm_path("GBASIC").with_name("BASIC.asm")
LABEL_RE = re.compile(r'^([A-Za-z_]\w*):')
BANNER_RE = re.compile(r'^\s*;\s*=+')
RULE = "; " + "-" * 70


def code_norm(line):
    return line.split(';', 1)[0].strip()


def _framed_header(hdr_lines):
    out = [RULE]
    for h in hdr_lines:
        h = h.rstrip()
        out.append(("; " + h) if h else ";")
    out.append(RULE)
    return out


def _preceding_comment_block(lines, idx):
    """Start index of the contiguous (non-banner, non-blank) comment block directly
    above the label at idx; == idx if there is none."""
    b = idx
    while b - 1 >= 0:
        prev = lines[b - 1]
        if prev.lstrip().startswith(";") and not BANNER_RE.match(prev):
            b -= 1
        else:
            break
    return b


def apply_spec(text, spec):
    routines = [r for r in spec.get("routines", []) if r.get("label")]
    rep = {"headers": 0, "body": 0, "renames": 0, "unmatched": [], "collisions": []}

    # 1) collect + apply RENAMES first, so that header/body anchors -- which the agents
    #    write with the FINAL (post-rename) names -- match the text we then scan.
    renames = {}
    for r in routines:
        for rn in r.get("renames", []) or []:
            if rn.get("old") and rn.get("new"):
                renames[rn["old"]] = rn["new"]
    pre_labels = {m.group(1) for m in (LABEL_RE.match(l) for l in text.split("\n")) if m}
    for old, new in renames.items():
        if new in pre_labels and new not in renames:       # new name already a distinct label
            rep["collisions"].append((old, new))
    def _rn(s):
        return s
    if renames:
        pat = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                         sorted(renames, key=len, reverse=True)) + r')(_\d+)?\b')
        _rn = lambda s: pat.sub(lambda m: renames[m.group(1)] + (m.group(2) or ''), s)
        text = _rn(text)
        rep["renames"] = len(renames)

    lines = text.split("\n")
    label_idx = {}
    for i, l in enumerate(lines):
        m = LABEL_RE.match(l)
        if m and m.group(1) not in label_idx:
            label_idx[m.group(1)] = i

    def rmap(lab):
        return renames.get(lab, lab)

    spec_label_names = {rmap(r["label"]) for r in routines}

    def body_end(idx, label):
        """End of a routine's body for anchor search: the next OTHER enriched routine
        (a spec label that is not this routine or its NAME_n continuation) or a banner."""
        for j in range(idx + 1, len(lines)):
            if BANNER_RE.match(lines[j]):
                return j
            m = LABEL_RE.match(lines[j])
            if m:
                ll = m.group(1)
                if ll in spec_label_names and ll != label and not ll.startswith(label + "_"):
                    return j
        return len(lines)

    edits = []          # (start, end, replacement_lines) -- replace lines[start:end]
    for r in routines:
        label = rmap(r["label"])
        if label not in label_idx:
            rep["unmatched"].append(("label", r["label"]))
            continue
        idx = label_idx[label]
        end = body_end(idx, label)
        hdr = r.get("header") or []
        if hdr:
            b = _preceding_comment_block(lines, idx)
            edits.append((b, idx, _framed_header(hdr)))   # supersede old comment block
            rep["headers"] += 1
        for bc in r.get("body_comments", []) or []:
            anchor = _rn((bc.get("anchor") or "").strip())   # normalize to post-rename names
            occ = bc.get("occ", 1)
            n, placed = 0, False
            for k in range(idx + 1, end):
                if anchor and code_norm(lines[k]) == anchor:
                    n += 1
                    if n == occ:
                        indent = lines[k][:len(lines[k]) - len(lines[k].lstrip())]
                        edits.append((k, k, [indent + "; " + bc["comment"]]))
                        rep["body"] += 1
                        placed = True
                        break
            if not placed:
                rep["unmatched"].append(("body", r["label"], anchor, occ))

    for start, end, repl in sorted(edits, key=lambda e: -e[0]):
        lines[start:end] = repl
    return "\n".join(lines), rep


def main():
    args = sys.argv[1:]
    write = "--write" in args
    paths = [a for a in args if not a.startswith("--")]
    if not paths:
        print("usage: enrich_apply.py SPEC.json [--write]")
        return
    spec = json.loads(Path(paths[0]).read_text(encoding="utf-8"))
    text = MASTER.read_text(encoding="latin-1")
    out, rep = apply_spec(text, spec)
    print(f"headers={rep['headers']} body={rep['body']} renames={rep['renames']} "
          f"unmatched={len(rep['unmatched'])} collisions={len(rep['collisions'])}")
    if rep["unmatched"]:
        print("  UNMATCHED:", rep["unmatched"][:25])
    if rep["collisions"]:
        print("  COLLISIONS (new name already a label):", rep["collisions"][:25])
    if write:
        MASTER.write_text(out, encoding="latin-1")
        print("WROTE", MASTER)
    else:
        print("(dry run; pass --write to apply)")


if __name__ == "__main__":
    main()
