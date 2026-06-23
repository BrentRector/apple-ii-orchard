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
def _strip_was(s):
    """Drop the redundant rename annotation "(was NAME)" left after the comment text
    is renamed (the agent's "(was OLD)" becomes "(was NEW)" == the name itself).
    Handles "NAME (was NAME)", "NAME -- ... (was NAME)", and adjacent "X (was X)"."""
    s = re.sub(r'^(\s*(?:;\s*)?)([A-Za-z_]\w*)(.*?) \(was \2\)', r'\1\2\3', s)
    return re.sub(r'([A-Za-z_]\w*) \(was \1\)', r'\1', s)
RULE = "; " + "-" * 70


def code_norm(line):
    return line.split(';', 1)[0].strip()


def _wrap(line, width=100):
    """Word-wrap an over-long comment line for readability (and to stay under the
    assembler's ~2048 line cap). Continuation lines reuse the leading indent + ';'
    and align under the field text (so "In:/Out:/Algorithm:" continuations line up)."""
    if len(line) <= width:
        return [line]
    m = re.match(r'^(\s*)(;\s*)(\w+:\s+)?(.*)$', line)
    if not m:
        return [line]
    ws, semi, label, text = m.group(1), m.group(2), m.group(3) or "", m.group(4)
    head = ws + semi + label
    cont = ws + ";" + " " * (len(semi) - 1 + len(label))   # ';' then pad to the text column
    out, cur = [], head
    for w in text.split(" "):
        cand = cur + ("" if cur in (head, cont) else " ") + w
        if len(cand) > width and cur not in (head, cont):
            out.append(cur)
            cur = cont + w
        else:
            cur = cand
    out.append(cur)
    return out


def _framed_header(hdr_lines):
    out = [RULE]
    for h in hdr_lines:
        h = h.rstrip()
        out.extend(_wrap("; " + h) if h else [";"])
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
    rep = {"headers": 0, "body": 0, "operands": 0, "labels": 0, "splits": 0, "includes": 0,
           "equ_folded": 0, "renames": 0, "unmatched": [], "collisions": []}

    # 1) collect + apply RENAMES first, so that header/body anchors -- which the agents
    #    write with the FINAL (post-rename) names -- match the text we then scan.
    renames = {}
    for r in routines:
        for rn in r.get("renames", []) or []:
            if rn.get("old") and rn.get("new"):
                renames[rn["old"]] = rn["new"]
    # use shared system includes instead of local re-definitions: fold each named local EQU
    # into the include's symbol (rename refs local->include) and drop the local def line.
    inc_files = list(spec.get("includes", []) or [])
    del_equ = []
    for e in spec.get("equ_to_include", []) or []:
        ln, inn = e.get("local_name"), e.get("include_name")
        if not (ln and inn):
            continue
        if ln != inn:
            renames[ln] = inn
        del_equ.append(inn)
        if e.get("include_file"):
            inc_files.append(e["include_file"])
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
        """End of a routine's body for anchor search: the next label that starts a
        DIFFERENT routine (not this label or its NAME_n continuation) or a banner.
        Uses ALL labels (not just enriched ones) so operand rewrites can't leak into a
        neighbouring routine where the same instruction text recurs."""
        for j in range(idx + 1, len(lines)):
            if BANNER_RE.match(lines[j]):
                return j
            m = LABEL_RE.match(lines[j])
            if m:
                ll = m.group(1)
                if ll != label and not ll.startswith(label + "_"):
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
            # _rn the header text too (so prose tracks renames), then drop redundant "(was NAME)"
            edits.append((b, idx, _framed_header([_strip_was(_rn(h)) for h in hdr])))
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
                        edits.append((k, k, _wrap(indent + "; " + _strip_was(_rn(bc["comment"])))))
                        rep["body"] += 1
                        placed = True
                        break
            if not placed:
                rep["unmatched"].append(("body", r["label"], anchor, occ))
        # operand rewrites: replace one literal in a code line (e.g. CP $22 -> CP '"').
        # In-place (no index shift); the fold byte-gate verifies the operand resolves identically.
        for orw in r.get("operand_rewrites", []) or []:
            anc = code_norm(_rn(orw.get("anchor") or ""))
            occ, old, new = orw.get("occ", 1), orw.get("old"), orw.get("new")
            n, done = 0, False
            for k in range(idx + 1, end):
                if anc and code_norm(lines[k]) == anc:
                    n += 1
                    if n == occ:
                        code, sep, rest = lines[k].partition(";")
                        if old and old in code:
                            lines[k] = code.replace(old, new, 1) + sep + rest
                            rep["operands"] += 1
                            done = True
                        break
            if not done:
                rep["unmatched"].append(("operand", r["label"], anc, occ))

    # top-level (file-global) operand rewrites: scattered rewrites not tied to one routine span
    for orw in spec.get("operand_rewrites", []) or []:
        anc = code_norm(_rn(orw.get("anchor") or ""))
        occ, old, new = orw.get("occ", 1), orw.get("old"), orw.get("new")
        n, done = 0, False
        for k in range(len(lines)):
            if anc and code_norm(lines[k]) == anc:
                n += 1
                if n == occ:
                    code, sep, rest = lines[k].partition(";")
                    if old and old in code:
                        lines[k] = code.replace(old, new, 1) + sep + rest
                        rep["operands"] += 1
                        done = True
                    break
        if not done:
            rep["unmatched"].append(("operand", "<global>", anc, occ))

    # relocation labels: define a label at an address-anchored line so that frozen
    # in-image hex operands can be rewritten to a label (full relocatability). The label
    # emits no bytes; the byte-identical gate proves the label resolves to the same addr.
    for lbl in spec.get("labels", []) or []:
        anc = _rn((lbl.get("anchor") or "").strip())
        occ, name = lbl.get("occ", 1), lbl.get("name")
        n, placed = 0, False
        for k in range(len(lines)):
            if anc and code_norm(lines[k]) == anc:
                n += 1
                if n == occ:
                    edits.append((k, k, [name + ":"]))   # insert "NAME:" before the line
                    rep["labels"] += 1
                    placed = True
                    break
        if not placed:
            rep["unmatched"].append(("label", name, anc, occ))

    # cover-idiom SPLIT (the BASIC approach): re-render a merged cover-decode as an unlabeled DEFB
    # cover byte + the real instruction at the entry, each its own clean label -- NO label arithmetic.
    # Replaces the anchor line (+ any contiguous `absorbs` lines, for data words that straddle the
    # original line breaks) with the `into` lines (same bytes; the gate proves it). Optionally drops a
    # pre-existing mis-anchored label line.
    for sp in spec.get("splits", []) or []:
        anc = code_norm(_rn(sp.get("anchor") or ""))
        occ = sp.get("occ", 1)
        into = [_rn(x) for x in (sp.get("into") or [])]
        absorbs = [code_norm(_rn(x)) for x in (sp.get("absorbs") or [])]
        n, placed = 0, False
        for k in range(len(lines)):
            if anc and code_norm(lines[k]) == anc:
                n += 1
                if n == occ:
                    end, ok = k + 1, True
                    for a in absorbs:               # consume the contiguous absorbed lines
                        if end < len(lines) and code_norm(lines[end]) == a:
                            end += 1
                        else:
                            ok = False
                            break
                    if ok:
                        edits.append((k, end, into))
                        rep["splits"] += 1
                        placed = True
                    break
        if not placed:
            rep["unmatched"].append(("split", anc, occ))
        dl = sp.get("delete_existing_label_line")
        if dl:
            lt = (_rn(dl.get("line_text")) if isinstance(dl, dict) else _rn(dl)).strip()
            docc, dn = (dl.get("occ", 1) if isinstance(dl, dict) else 1), 0
            for k in range(len(lines)):
                if lines[k].strip() == lt:
                    dn += 1
                    if dn == docc:
                        edits.append((k, k + 1, []))
                        break

    # fold redundant local EQU defs into the include's symbol, and ensure the INCLUDEs are present
    def _base(p):
        return p.replace("\\", "/").rsplit("/", 1)[-1]
    present_base = {_base(p) for p in re.findall(r'INCLUDE\s+"([^"]*)"', "\n".join(lines))}
    for name in del_equ:                         # drop the (now-renamed) local EQU def line
        for k in range(len(lines)):
            if re.match(r'^\s*' + re.escape(name) + r'\s+EQU\b', lines[k]):
                edits.append((k, k + 1, []))
                rep["equ_folded"] += 1
                break
    to_add = [f for f in dict.fromkeys(inc_files) if _base(f) not in present_base]
    if to_add:                                   # insert INCLUDEs before the first ORG (else after the header)
        ins = next((k for k, l in enumerate(lines) if re.match(r'^\s*ORG\b', l)), None)
        if ins is None:
            ins = 0
            while ins < len(lines) and (lines[ins].lstrip().startswith(";") or not lines[ins].strip()):
                ins += 1
        edits.append((ins, ins, ['        INCLUDE "%s"' % f for f in to_add]))
        rep["includes"] += len(to_add)

    for start, end, repl in sorted(edits, key=lambda e: -e[0]):
        lines[start:end] = repl
    return "\n".join(lines), rep


def main():
    args = sys.argv[1:]
    write = "--write" in args
    target = MASTER                       # default: the BASIC.asm master
    rest = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--target":
            target = Path(args[i + 1]); i += 2; continue
        if a.startswith("--target="):
            target = Path(a.split("=", 1)[1]); i += 1; continue
        if not a.startswith("--"):
            rest.append(a)
        i += 1
    if not rest:
        print("usage: enrich_apply.py SPEC.json [--target PATH] [--write]")
        return
    spec = json.loads(Path(rest[0]).read_text(encoding="utf-8"))
    text = target.read_text(encoding="latin-1")
    out, rep = apply_spec(text, spec)
    print(f"headers={rep['headers']} body={rep['body']} operands={rep['operands']} "
          f"labels={rep['labels']} splits={rep['splits']} includes={rep['includes']} equ_folded={rep['equ_folded']} "
          f"renames={rep['renames']} unmatched={len(rep['unmatched'])} "
          f"collisions={len(rep['collisions'])}")
    if rep["unmatched"]:
        print("  UNMATCHED:", rep["unmatched"][:25])
    if rep["collisions"]:
        print("  COLLISIONS (new name already a label):", rep["collisions"][:25])
    if write:
        target.write_text(out, encoding="latin-1")
        print("WROTE", target)
    else:
        print("(dry run; pass --write to apply)")


if __name__ == "__main__":
    main()
