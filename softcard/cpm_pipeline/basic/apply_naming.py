#!/usr/bin/env python
"""Apply a semantic-naming overlay to the byte-identical GBASIC base, byte-safely.

Enrichment must not change the assembled bytes. Labels are zero-width and the
per-instruction byte comments (`; $XXXX  HH`) key on the run ADDRESS, not the
label -- so renaming a machine label (`L_503C` -> `FRMEVL`) and adding `;`
comments is byte-identical by construction, and we VERIFY by reassembling.

Overlay JSON schema (produced by the enrichment workflow, merged in the main loop):
{
  "renames":        { "L_503C": "FRMEVL", "SUB_4D12_3": "GFX_HPLOT", ... },
  "label_comments": { "L_503C": "[RE] Evaluate an expression into FAC ...", ... },
  "sections":       { "L_503C": "Expression evaluation", ... },
  "inline_comments":{ "503C": "high byte first", ... }     # keyed by run-addr hex
}
Keys are always the ORIGINAL machine-label / address from the base (stable anchor).
"""
import json
import re
import sys
from pathlib import Path

from cpm_pipeline.basic._paths import asm_path, INCLUDE_DIR

BASE = asm_path("GBASIC")
COM_NAME = "GBASIC.COM"   # which on-disk file to verify byte-identical against

# A machine label: L_XXXX or SUB_XXXX_N (XXXX = 4 hex). These are the only tokens
# we rename; word boundaries keep L_503C from matching inside SUB_503C_1 etc.
LABEL_DEF_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):(.*)$')


def base_label_index(base_text):
    """Map every label DEFINED in the base to its run address (and the inverse
    addr->token), by reading each label's address from the byte-comment on the
    next code/data line. Works for ANY label form -- plain L_/SUB_xxxx AND the
    localized <head>_n locals the formatter emits -- so an overlay key can be a
    bare 4-hex run address (resolved to whatever token sits there) or an exact
    token. The last label defined at an address wins (labels stack zero-width)."""
    addr_tag = re.compile(r';\s+\$([0-9A-Fa-f]{4})\b')
    tok_to_addr, addr_to_tok = {}, {}
    pending = []
    for line in base_text.splitlines():
        m = LABEL_DEF_RE.match(line)
        if m:
            pending.append(m.group(1))
            continue
        am = addr_tag.search(line)
        if am and pending:
            a = am.group(1).upper()
            for t in pending:
                tok_to_addr[t] = a
                addr_to_tok[a] = t
            pending = []
        elif pending and line.strip() and not line.lstrip().startswith(";"):
            pending = []          # a directive (ORG/DISP/EQU) with no addr tag
    return tok_to_addr, addr_to_tok


def _resolve_key(k, valid_tokens, addr_to_tok):
    """An overlay rename key is either an exact machine-label token present in the
    base, or a 4-hex address whose label we look up. Returns (token|None)."""
    if k in valid_tokens:
        return k
    ah = k.upper().lstrip("$")
    if re.fullmatch(r'[0-9A-F]{4}', ah) and ah in addr_to_tok:
        return addr_to_tok[ah]
    return None


def load_overlay(paths, base_text):
    tok_to_addr, addr_to_tok = base_label_index(base_text)
    valid = set(tok_to_addr)
    renames, label_comments, sections, inline = {}, {}, {}, {}
    operand_rewrites = {}
    unmatched, collisions = [], []

    def remap(d):
        """Translate a {key->val} dict whose keys are token-or-address into
        token-keyed, dropping (and recording) keys that don't resolve."""
        out = {}
        for k, v in d.items():
            tok = _resolve_key(k, valid, addr_to_tok)
            if tok is None:
                unmatched.append(k)
            else:
                out[tok] = v
        return out

    for p in paths:
        d = json.loads(Path(p).read_text(encoding="utf-8"))
        for old, new in remap(d.get("renames", {})).items():
            if old in renames and renames[old] != new:
                collisions.append(("dup-old", old, renames[old], new))
            renames[old] = new
        label_comments.update(remap(d.get("label_comments", {})))
        sections.update(remap(d.get("sections", {})))
        inline.update({k.upper().lstrip("$"): v
                       for k, v in d.get("inline_comments", {}).items()})
        # operand_rewrites: {site-addr-hex: [old_literal, new_operand]} -- rewrite
        # one operand on the line at that address (e.g. a cross-region skip-idiom
        # CALL $35B6 -> CALL STMT_DATA+2). Byte-identical: the new operand must
        # resolve to the same address (verified by reassembly).
        operand_rewrites.update({k.upper().lstrip("$"): v
                                 for k, v in d.get("operand_rewrites", {}).items()})
    seen = {}
    for old, new in renames.items():
        if new in seen and seen[new] != old:
            collisions.append(("dup-new", new, seen[new], old))
        seen[new] = old
    return (renames, label_comments, sections, inline, operand_rewrites,
            unmatched, collisions)


INCLUDE_NAME = "apple_softcard.inc"
INCLUDE_PATH = INCLUDE_DIR / INCLUDE_NAME
TOKEN_INCLUDE_NAME = "msbasic_tokens.inc"   # MS BASIC keyword-token EQUs (BASIC sources)
TOKEN_INCLUDE_PATH = INCLUDE_DIR / TOKEN_INCLUDE_NAME
ERROR_INCLUDE_NAME = "msbasic_errors.inc"   # MS BASIC error-code EQUs (ERR_*)
ERROR_INCLUDE_PATH = INCLUDE_DIR / ERROR_INCLUDE_NAME
FCB_INCLUDE_NAME = "msbasic_fcb.inc"        # MS BASIC file-control-block STRUCT (FCB.<field> offsets)
FCB_INCLUDE_PATH = INCLUDE_DIR / FCB_INCLUDE_NAME


def load_external_symbols():
    """Parse the common include's `NAME EQU $XXXX` lines -> {addrhex: NAME}. These
    are EXTERNAL Apple/SoftCard addresses (all >= $E000, outside the file's own
    $0100-$84FF range), so substituting them into operands never hits an internal
    label or a byte-comment, and is byte-identical (the EQU resolves to the value)."""
    syms = {}
    if INCLUDE_PATH.exists():
        for line in INCLUDE_PATH.read_text(encoding="latin-1").splitlines():
            m = re.match(r'^(\w+)\s+EQU\s+\$([0-9A-Fa-f]{4})\b', line)
            if m and int(m.group(2), 16) >= 0xE000:
                syms[m.group(2).upper()] = m.group(1)
    return syms


_SANITIZE = {0x2014: "--", 0x2013: "-", 0x2018: "'", 0x2019: "'", 0x201c: '"',
             0x201d: '"', 0x2026: "...", 0x00a0: " ", 0x2192: "->", 0x2190: "<-",
             0x2022: "*", 0x00d7: "x", 0x2261: "==", 0x2264: "<=", 0x2265: ">="}


def sanitize(s):
    """Agent-supplied comments often carry typographic Unicode (em dashes, arrows,
    smart quotes) that the latin-1 source file cannot hold and that reads as
    mojibake. Fold the common ones to ASCII and drop anything else, so the written
    source stays clean ASCII (comments do not affect the assembled bytes)."""
    return s.translate(_SANITIZE).encode("ascii", "replace").decode("ascii")


_ADDR_COMMENT = re.compile(r'^(.*?)\s*(; \$[0-9A-Fa-f]{4}(?:\s.*)?)$')


def _realign(line):
    """Re-pad an instruction/data line so its `; $XXXX` byte-comment starts at the
    canonical column 41 (renaming/substitution changed the code-text length).
    Whitespace-before-comment only -> byte-identical."""
    m = _ADDR_COMMENT.match(line)
    if not m:
        return line
    code = m.group(1).rstrip()
    if not code or code.lstrip().startswith(";"):
        return line
    return (code.ljust(40) + " " + m.group(2)) if len(code) <= 40 else code + "  " + m.group(2)


def apply(base_text, renames, label_comments, sections, inline, ext_syms=None,
          operand_rewrites=None):
    operand_rewrites = operand_rewrites or {}
    # Build one global token-substitution regex for operand references. A renamed
    # head SUB_6937 also drags its localized locals SUB_6937_4 -> NEWNAME_4, so a
    # renamed routine stays internally consistent (the optional (_\d+) suffix is
    # preserved). Longest-first alternation avoids a prefix matching inside another.
    if renames:
        tok = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                         sorted(renames, key=len, reverse=True)) + r')(_\d+)?\b')
        sub = lambda s: tok.sub(lambda m: renames[m.group(1)] + (m.group(2) or ''), s)
    else:
        sub = lambda s: s
    # PROSE comments are written against the BASE machine labels; the naming pass renames
    # those labels in code but the comment text would keep the dead names. comment_sub keeps
    # prose in sync: rename any referenced machine label to its semantic name, then drop any
    # still-dangling bare L_/SUB_xxxx (an address that stays literal in code) to a $xxxx
    # literal so no comment points at a label that no longer exists.
    _bare_ml = re.compile(r'\b(?:L|SUB)_([0-9A-Fa-f]{4})\b')
    comment_sub = lambda s: _bare_ml.sub(lambda mm: '$' + mm.group(1).upper(), sub(s))
    ext_syms = ext_syms or {}
    ext_re = (re.compile(r'\$(' + '|'.join(sorted(ext_syms)) + r')\b')
              if ext_syms else None)
    extsub = (lambda s: ext_re.sub(lambda m: ext_syms[m.group(1).upper()], s)
              if ext_re else None)

    out = []
    for line in base_text.splitlines():
        # inject the shared includes right after the DEVICE directive: the
        # Apple/SoftCard external names, then the MS BASIC keyword-token names.
        if ext_syms and line.strip() == "DEVICE NOSLOT64K":
            out.append(line)
            out.append(f'    INCLUDE "{INCLUDE_NAME}"   ; canonical Apple/SoftCard external names')
            out.append(f'    INCLUDE "{TOKEN_INCLUDE_NAME}"   ; MS BASIC keyword-token names')
            out.append(f'    INCLUDE "{ERROR_INCLUDE_NAME}"   ; MS BASIC error-code names (ERR_*)')
            out.append(f'    INCLUDE "{FCB_INCLUDE_NAME}"   ; MS BASIC file-control-block STRUCT')
            continue
        m = LABEL_DEF_RE.match(line)
        if m and (m.group(1) in renames or m.group(1) in label_comments
                  or m.group(1) in sections):
            old = m.group(1)
            new = sub(old)                      # suffix-aware: renames a head AND its _N locals
            if old in sections:
                out.append("")
                bar = "; " + "=" * 70
                out.append(bar)
                out.append(f"; {comment_sub(sections[old])}")
                out.append(bar)
            for cl in label_comments.get(old, "").splitlines():
                cl = comment_sub(cl)
                out.append(f"; {cl}" if cl.strip() and not cl.lstrip().startswith(';') else cl)
            out.append(f"{new}:{m.group(2)}")
            continue
        # operand line: rename machine labels, then substitute external symbols
        new_line = sub(line)
        if extsub:
            new_line = extsub(new_line)
        # cross-region operand rewrite (skip-idiom CALLs into another region):
        # replace one literal operand with a label+offset before realigning.
        am0 = re.search(r';\s+\$([0-9A-Fa-f]{4})\b', new_line)
        if am0 and am0.group(1).upper() in operand_rewrites:
            old, new = operand_rewrites[am0.group(1).upper()]
            code, sep, rest = new_line.partition(";")
            new_line = code.replace(old, new, 1) + sep + rest
        new_line = _realign(new_line)
        # inline comment by run-address (matches the trailing "; $XXXX  HH" tag)
        am = re.search(r';\s+\$([0-9A-Fa-f]{4})\b', new_line)
        if am and am.group(1).upper() in inline:
            new_line = new_line.rstrip() + "   <- " + comment_sub(inline[am.group(1).upper()])
        out.append(new_line)
    return "\n".join(out) + "\n"


def verify_byte_identical(text):
    from cpm_pipeline.region_disasm import assemble_z80
    from cpm_pipeline.filesystem import read_disk, extract_file
    from cpm_pipeline import reference_data as rd
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"', text)
    inc = [(nm, pth) for nm, pth in ((INCLUDE_NAME, INCLUDE_PATH),
                                     (TOKEN_INCLUDE_NAME, TOKEN_INCLUDE_PATH),
                                     (ERROR_INCLUDE_NAME, ERROR_INCLUDE_PATH),
                                     (FCB_INCLUDE_NAME, FCB_INCLUDE_PATH))
           if pth.exists()]
    built = assemble_z80(src, include_files=inc)
    genuine = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), COM_NAME))
    return built == genuine, len(built)


def main():
    global BASE, COM_NAME
    args = sys.argv[1:]
    do_write = "--write" in args
    # --base PATH and --com NAME let this drive either GBASIC or MBASIC.
    if "--base" in args:
        i = args.index("--base"); BASE = Path(args[i + 1])
        args = args[:i] + args[i + 2:]
    if "--com" in args:
        i = args.index("--com"); COM_NAME = args[i + 1]
        args = args[:i] + args[i + 2:]
    overlays = [a for a in args if not a.startswith("--")]
    base_text = BASE.read_text(encoding="latin-1")
    if not overlays:
        # identity check: applying an empty overlay must round-trip byte-identical
        ok, n = verify_byte_identical(base_text)
        print(f"identity reassembly: {'BYTE-IDENTICAL' if ok else 'DIFFERS'} ({n} bytes)")
        return
    renames, lc, sec, inl, opr, unmatched, collisions = load_overlay(overlays, base_text)
    if unmatched:
        print(f"UNMATCHED KEYS ({len(unmatched)}):", unmatched[:30])
    if collisions:
        print(f"COLLISIONS ({len(collisions)}):", collisions[:20])
    ext = load_external_symbols()
    enriched = sanitize(apply(base_text, renames, lc, sec, inl, ext_syms=ext,
                              operand_rewrites=opr))
    ok, n = verify_byte_identical(enriched)
    print(f"renames={len(renames)} comments={len(lc)} sections={len(sec)} "
          f"inline={len(inl)} ext-syms={len(ext)}")
    print(f"enriched reassembly: {'BYTE-IDENTICAL' if ok else 'DIFFERS'} ({n} bytes)")
    if ok and do_write:
        BASE.write_text(enriched, encoding="latin-1")
        print("WROTE enriched base")


if __name__ == "__main__":
    main()
