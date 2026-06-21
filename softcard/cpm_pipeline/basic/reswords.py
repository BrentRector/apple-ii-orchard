"""Decode the Microsoft BASIC-80 (SoftCard 2.20) reserved-word / token table from
the GBASIC.COM bytes (ground truth) and emit:
  * the full `msbasic_tokens.inc` (every keyword/operator token EQU), and
  * the structured assembly for the table region $021E-$04EC (per-letter index ->
    DEFW group labels; name entries as char bytes + TOK_ token; operator sub-table
    as char + TOK_ pairs), byte-identical to the original.

Table layout (validated against the $0108 statement dispatch):
  $021E  per-letter index: 26 little-endian WORD pointers, one per first letter A-Z.
  $0252  name groups (contiguous, in index order): each entry = the keyword TAIL
         (the first letter is implied by the group), last tail char high-bit set,
         then the token byte; a $00 byte ends a group.
  $04D8  operator sub-table: (char|$80, token) pairs, $00-terminated.
"""

INDEX_ADDR = 0x021E
NAMES_ADDR = 0x0252
OPS_ADDR = 0x04D8
TABLE_END = 0x04ED          # one past the operator table's $00 terminator

# Operators are not valid identifiers -> spelled-out mnemonic names.
_OP_NAMES = {
    '+': 'PLUS', '-': 'MINUS', '*': 'MUL', '/': 'DIV', '^': 'POW', '\\': 'IDIV',
    '>': 'GT', '=': 'EQ', '<': 'LT', "'": 'REM_QUOTE',
}


def _b(com, a):
    return com[a - 0x100]


def _w(com, a):
    return _b(com, a) | (_b(com, a + 1) << 8)


def tok_name(keyword):
    """Keyword/operator string -> TOK_ EQU name. Operators get a mnemonic; `$`
    (string funcs) -> S, `(` (TAB(/SPC() -> _LP."""
    if keyword in _OP_NAMES:
        return 'TOK_' + _OP_NAMES[keyword]
    # `$` (string funcs) -> S, `(` (TAB(/SPC() -> _LP, space (GO TO) -> none so the
    # alternate spelling folds onto the primary token name (GO TO -> TOK_GOTO).
    return 'TOK_' + keyword.replace('$', 'S').replace('(', '_LP').replace(' ', '')


def decode(com):
    """Return (index, groups, ops):
       index  = [group_start_addr per letter A-Z]
       groups = [(letter, start_addr, [(keyword, tail_bytes, token), ...]), ...]
       ops    = [(char, token), ...]"""
    index = [_w(com, INDEX_ADDR + i * 2) for i in range(26)]
    groups = []
    for i, start in enumerate(index):
        letter = chr(65 + i)
        a = start
        entries = []
        while _b(com, a) != 0x00:
            tail = []
            while not (_b(com, a) & 0x80):
                tail.append(_b(com, a)); a += 1
            tail.append(_b(com, a) & 0x7F); a += 1     # last tail char (strip high bit)
            token = _b(com, a); a += 1
            keyword = letter + ''.join(chr(c) for c in tail)
            entries.append((keyword, tail, token))
        groups.append((letter, start, entries))
    a = OPS_ADDR
    ops = []
    while _b(com, a) != 0x00:
        ops.append((chr(_b(com, a) & 0x7F), _b(com, a + 1))); a += 2
    return index, groups, ops


def value_to_name(com):
    """{token_byte: TOK_name} for every token defined in the table."""
    _, groups, ops = decode(com)
    out = {}
    for _, _, entries in groups:
        for kw, _, tok in entries:
            out[tok] = tok_name(kw)
    for ch, tok in ops:
        out[tok] = tok_name(ch)
    return out


def _char_expr(ch, high=False):
    """sjasmplus char literal, +$80 when high; ' and \\ as hex to avoid quoting."""
    base = f"${ord(ch) | (0x80 if high else 0):02X}" if ch in ("'", "\\") \
        else (f"'{ch}'+$80" if high else f"'{ch}'")
    return base


def gen_include(com):
    """The full msbasic_tokens.inc text (every keyword + operator token EQU)."""
    index, groups, ops = decode(com)
    by_name = {}   # name -> [value, [spellings]]; dedupe alternate spellings (GO TO)
    for letter, _, entries in groups:
        for kw, _, tok in entries:
            name = tok_name(kw)
            slot = by_name.setdefault(name, [tok, []])
            assert slot[0] == tok, f"{name} maps to ${slot[0]:02X} and ${tok:02X}"
            slot[1].append(kw)
    for ch, tok in ops:
        name = tok_name(ch)
        slot = by_name.setdefault(name, [tok, []])
        assert slot[0] == tok, f"{name} maps to ${slot[0]:02X} and ${tok:02X}"
        slot[1].append(f"'{ch}' operator")
    rows = sorted(((v[0], name, " / ".join(v[1])) for name, v in by_name.items()),
                  key=lambda r: r[0])
    out = [
        "; msbasic_tokens.inc -- Microsoft BASIC-80 Rev 5.2 (SoftCard CP/M 2.20)",
        "; single-byte keyword/operator TOKENS. GENERATED from the GBASIC.COM",
        "; reserved-word table (cpm_pipeline.basic.reswords) -- the ground truth:",
        "; per-letter index $021E, name table $0252 (last char high-bit set, token",
        "; byte follows), operator sub-table $04D8. Validated against the $0108",
        "; statement dispatch. EQUs are zero-width, so INCLUDEing this is",
        "; byte-identical. CRUNCH folds source keywords to these tokens;",
        "; DETOKENIZE_LINE reverses it; SYNCHR / FRMEVL match them inline.",
        "",
    ]
    for tok, name, comment in rows:
        out.append(f"{name:<16} EQU ${tok:02X}   ; {comment}")
    out.append("")
    return "\n".join(out)


def emit_table_lines(com):
    """Structured assembly lines for $021E-$04EC, byte-identical to the table."""
    index, groups, ops = decode(com)
    L = []
    L.append("; -- Reserved-word / token table (CRUNCH keyword<->token map). The")
    L.append(";    per-letter index points at each first-letter group; a name entry")
    L.append(";    is the keyword TAIL (first letter implied), last char high-bit set,")
    L.append(";    then the token byte; $00 ends a group. Operator sub-table = (char,")
    L.append(";    token) pairs. Byte-identical to the original DEFB bytes.")
    L.append("RESWORD_INDEX:                       ; $021E  per-letter group pointers A-Z")
    for i in range(0, 26, 6):
        labels = ",".join(f"KWGRP_{chr(65 + j)}" for j in range(i, min(i + 6, 26)))
        L.append(f"        DEFW    {labels}")
    for letter, start, entries in groups:
        L.append(f"KWGRP_{letter}:" + " " * max(1, 24 - len(letter)) + f"; ${start:04X}")
        for kw, tail, token in entries:
            parts = [_char_expr(chr(tail[k]), high=(k == len(tail) - 1)) for k in range(len(tail))]
            parts.append(tok_name(kw))
            L.append(f"        DEFB    {','.join(parts):<28} ; {kw}")
        L.append(f"        DEFB    $00                          ; end {letter}-group")
    L.append("RESWORD_OPS:                         ; $04D8  operator (char,token) pairs")
    for ch, token in ops:
        L.append(f"        DEFB    {_char_expr(ch, high=True)+','+tok_name(ch):<28} ; '{ch}'")
    L.append("        DEFB    $00                          ; end operators")
    return L


def structured_labels(com):
    """{addr: structured-label-name} for the table's own labels: RESWORD_INDEX
    ($021E), each KWGRP_<letter> group start, RESWORD_OPS ($04D8)."""
    _, groups, _ = decode(com)
    out = {INDEX_ADDR: "RESWORD_INDEX", OPS_ADDR: "RESWORD_OPS"}
    for i, (_letter, start, _entries) in enumerate(groups):
        out[start] = f"KWGRP_{chr(65 + i)}"
    return out


def reference_renames(com, start=INDEX_ADDR, end=TABLE_END):
    """{f'L_{addr:04X}': 'KWGRP_x[+n]' / 'RESWORD_INDEX[+n]' / 'RESWORD_OPS[+n]'}
    for every address in the table region.  A code reference INTO the reserved-word
    table (a machine label L_xxxx minted at a table-interior address -- the table is
    relocatable image data, so the reference must be a label) is rewritten to the
    structured label it points into, plus a byte offset.  Applied to ALL emitted
    lines so both the header and body references resolve, in both BASICs."""
    struct = structured_labels(com)
    out = {}
    for a in range(start, end):
        encl = max(s for s in struct if s <= a)
        out[f"L_{a:04X}"] = struct[encl] if encl == a else f"{struct[encl]}+{a - encl}"
    return out


def apply_reference_renames(lines, com, start=INDEX_ADDR, end=TABLE_END):
    """Rewrite every machine-label reference into the reserved-word table (L_xxxx,
    minted at a table-interior address) to its structured label+offset, in the code
    part of each line only (never the `; $XXXX` byte-comment). Byte-identical."""
    import re
    ren = reference_renames(com, start, end)
    if not ren:
        return list(lines)
    pat = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                     sorted(ren, key=len, reverse=True)) + r')\b')
    out = []
    for ln in lines:
        code, sep, rest = ln.partition(';')
        out.append(pat.sub(lambda m: ren[m.group(1)], code) + sep + rest)
    return out


def splice_table_into(lines, com, start=INDEX_ADDR, end=TABLE_END):
    """Replace the formatter's DEFB lines covering [start, end) with the structured
    reserved-word table. The caller must have split the data run at `start` (e.g.
    `walker.add_label(start)`) so no line straddles the boundary.

    Labels that sat on a removed (in-range) line are simply DROPPED here: the
    reserved-word table is relocatable image data, so every code reference into it
    must resolve to a structured label -- the caller applies `reference_renames`
    (L_xxxx -> KWGRP_x+n / RESWORD_INDEX+n / RESWORD_OPS+n) over all emitted lines,
    so no EQU alias to a frozen literal is needed (or wanted)."""
    import re
    new = emit_table_lines(com)

    def addr(ln):
        m = re.search(r';\s*\$([0-9A-Fa-f]{4})\b', ln)
        return int(m.group(1), 16) if m else None

    is_label = re.compile(r'^([A-Za-z_]\w*):\s*$')

    # splice the structured block in place of the [start, end) lines; in-range label
    # definitions are dropped (references are rewritten to structured labels instead).
    out = []
    done = False
    pend = []
    for ln in lines:
        m = is_label.match(ln)
        a = addr(ln)
        if m and a is None:
            pend.append(ln); continue
        if a is not None and start <= a < end:
            pend = []                          # drop in-range label defs
            if not done:
                out.extend(new); done = True
            continue
        out.extend(pend); pend = []
        out.append(ln)
    out.extend(pend)
    if not done:
        raise ValueError(f"reserved-word table region ${start:04X}-${end:04X} not found")
    return out
