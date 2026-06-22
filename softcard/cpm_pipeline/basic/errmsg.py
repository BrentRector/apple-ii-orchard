"""Decode and structure the Microsoft BASIC-80 (SoftCard 2.20) error-message table.

The table at $0522+ is a contiguous list of $00-terminated message strings. The ERROR
handler (RAISE_ERROR, in low RAM -- $0D89 in GBASIC, $0DAC in MBASIC) is entered with the
error code in the E register; the message printer reaches a message by scanning E entries
forward from
ERROR_MESSAGE_TABLE. So the messages are NOT individually code-referenced -- only the few
that a runtime trap loads directly by pointer (Overflow, Division by zero) are. Therefore:

  * the table base gets one label (ERROR_MESSAGE_TABLE) plus a per-message comment
    naming each error code (ERR_<name> = <code>);
  * only the directly-loaded messages keep a string label (ERRMSG_<name>);
  * the error codes are emitted as ERR_<name> EQU <code> constants (msbasic_errors.inc),
    so a 'LD E,<n>' raise site can read 'LD E,ERR_SYNTAX_ERROR'.

The formatter had also mangled the strings into hex-byte + string fragments; this module
emits each as a clean DEFB "...",$00, byte-identical to the original bytes.
"""
import re

BASE_ADDR = 0x0521         # the $00 the scan starts from = ERROR_MESSAGE_TABLE (message 0)
TABLE_LO = 0x0522          # the first real message ("NEXT without FOR" = error code 1)
_SCAN_LIMIT = 0x0900       # safety bound (the table is well under this in both builds)


def _decode_raw(com, lo):
    """Return ([(addr, message_text)], end_addr). The table is a run of $00-terminated
    printable strings; it ENDS at the first entry that is empty or contains a
    non-printable byte (the vector table that follows). Auto-detects the per-build end
    (GBASIC ends at $081F, MBASIC runs longer)."""
    out = []
    a = lo
    while a < _SCAN_LIMIT:
        start = a
        chars = []
        while a < _SCAN_LIMIT and com[a - 0x100] != 0x00:
            chars.append(com[a - 0x100]); a += 1
        if a >= _SCAN_LIMIT or not chars or not all(0x20 <= c < 0x7F for c in chars):
            return out, start                    # non-string entry -> table ends here
        a += 1                                   # skip the $00 terminator
        out.append((start, "".join(chr(c) for c in chars)))
    return out, a


def table_end(com, lo=TABLE_LO):
    """Address one past the table's last terminator (exclusive end for the splice)."""
    return _decode_raw(com, lo)[1]


def _slug(msg):
    return re.sub(r"[^A-Za-z0-9]+", "_", msg.replace("'", "")).strip("_").upper()


def decode(com, lo=TABLE_LO):
    """Return [(addr, msg, code, err_name, msg_label)] for every message. err_name is the
    ERR_<name> code constant (the E-register value), msg_label the ERRMSG_<name> string
    label.

    RAISE_ERROR is entered with the error code in E; the printer
    scans from ERROR_MESSAGE_TABLE-1 ($0521) past (E-1) $00 terminators, so code E selects
    the E-th message: BASIC errors are codes 1..N (= index+1). But the scan REMAPS the disk
    errors (CP $32 / SUB $12): the "FIELD overflow" message onward uses codes 50..70, so
    their code is 50 + (index - boundary)."""
    raw, _end = _decode_raw(com, lo)
    boundary = next((i for i, (_a, m) in enumerate(raw) if m == "FIELD overflow"), len(raw))
    seen, out = {}, []
    for i, (addr, msg) in enumerate(raw):
        code = (i + 1) if i < boundary else (50 + i - boundary)
        slug = _slug(msg) if msg.strip() not in ("", "?") else f"UNUSED_{code}"
        if slug in seen:
            slug = f"{slug}_{code}"
        seen[slug] = True
        out.append((addr, msg, code, f"ERR_{slug}", f"ERRMSG_{slug}"))
    return out


def error_equates(com, lo=TABLE_LO):
    """[(ERR_name, code, msg)] -- the error-code constants (the E-register value)."""
    return [(en, code, msg) for _a, msg, code, en, _ml in decode(com, lo)]


def _str_literal(msg):
    """Render a message as a DEFB operand: a quoted string, with non-printable or quote
    characters split out as hex so the bytes stay exact, plus the $00 terminator."""
    parts, run = [], []
    for ch in msg:
        c = ord(ch)
        if 0x20 <= c < 0x7F and ch != '"':
            run.append(ch)
        else:
            if run:
                parts.append('"' + "".join(run) + '"'); run = []
            parts.append(f"${c:02X}")
    if run:
        parts.append('"' + "".join(run) + '"')
    parts.append("$00")
    return ",".join(parts)


def emit_table_lines(com, labeled=()):
    """Structured error-message table: the ERROR_MESSAGE_TABLE base label at the $0521
    scan-base $00, then each message as DEFB "<text>",$00 with a comment giving its
    ERR_<name>=<code>. Messages whose start address is in `labeled` (loaded directly by a
    runtime trap) also get their ERRMSG_<name> string label."""
    labeled = set(labeled)
    L = ["; -- Error-message table. RAISE_ERROR is entered with the error code in E.",
         ";    The base ERROR_MESSAGE_TABLE ($0521) is a $00 = the empty message 0; the printer",
         ";    scans E terminators forward from it, so code E selects the E-th message (err 1 =",
         ";    'NEXT without FOR'). BASIC errors are codes 1..N; the disk errors (FIELD overflow",
         ";    on) are remapped to codes 50..70 (the scan does CP $32 / SUB $12). Codes are the",
         ";    ERR_* equates (msbasic_errors.inc); messages are not individually referenced, so",
         ";    only the few a trap loads by pointer keep an ERRMSG_* label."]
    L.append("ERROR_MESSAGE_TABLE:")
    L.append(f"        DEFB    {'$00':<34} ; ${BASE_ADDR:04X}  err 0 (empty message, scan base)")
    for addr, msg, code, err_name, msg_label in decode(com):
        if addr in labeled:
            L.append(f"{msg_label}:")
        L.append(f"        DEFB    {_str_literal(msg):<34} ; ${addr:04X}  {err_name} = {code}")
    return L


def reference_renames(com, lo=TABLE_LO):
    """{L_xxxx: name}: the scan base ($0521) -> ERROR_MESSAGE_TABLE, and each message
    start -> its ERRMSG_<name> string label (for the few traps that load one directly)."""
    ren = {f"L_{BASE_ADDR:04X}": "ERROR_MESSAGE_TABLE"}
    ren.update({f"L_{addr:04X}": ml for addr, _m, _c, _en, ml in decode(com, lo)})
    return ren


def apply_reference_renames(lines, com, lo=TABLE_LO):
    """Rewrite L_xxxx references to message starts to their ERRMSG_<name> label, in the
    code part of each line only (never the byte-comment). Byte-identical."""
    ren = reference_renames(com, lo)
    if not ren:
        return list(lines)
    pat = re.compile(r"\b(" + "|".join(re.escape(k) for k in
                     sorted(ren, key=len, reverse=True)) + r")\b")
    out = []
    for ln in lines:
        code, sep, rest = ln.partition(";")
        out.append(pat.sub(lambda m: ren[m.group(1)], code) + sep + rest)
    return out


_LDEF = re.compile(r"^L_([0-9A-Fa-f]{4}):")


def splice_table_into(lines, com, start=BASE_ADDR, end=None):
    """Replace the formatter's lines covering [start, end) with the structured error
    table (from the $00 scan base at $0521 through the last message). Message starts that
    the harvest had labeled (L_xxxx) are the directly-loaded ones; they keep an
    ERRMSG_<name> label, the rest are dropped. `end` defaults to the auto-detected end."""
    if end is None:
        end = table_end(com, TABLE_LO)
    msg_addrs = {a for a, _m, _c, _en, _ml in decode(com)}
    labeled = set()
    for ln in lines:
        m = _LDEF.match(ln)
        if m and int(m.group(1), 16) in msg_addrs:
            labeled.add(int(m.group(1), 16))
    block = emit_table_lines(com, labeled)
    is_label = re.compile(r"^([A-Za-z_]\w*):\s*$")

    def addr(ln):
        m = re.search(r";\s*\$([0-9A-Fa-f]{4})\b", ln)
        return int(m.group(1), 16) if m else None

    out, done, pend = [], False, []
    for ln in lines:
        m = is_label.match(ln)
        a = addr(ln)
        if m and a is None:
            pend.append(ln); continue
        if a is not None and start <= a < end:
            pend = []
            if not done:
                out.extend(block); done = True
            continue
        out.extend(pend); pend = []
        out.append(ln)
    out.extend(pend)
    if not done:
        raise ValueError(f"error-message table ${start:04X}-${end:04X} not found")
    return out


def gen_include(com, lo=TABLE_LO):
    """The full msbasic_errors.inc text: ERR_<name> EQU <code> for every error code."""
    rows = error_equates(com, lo)
    out = [
        "; msbasic_errors.inc -- Microsoft BASIC-80 (SoftCard CP/M 2.20) ERROR CODES.",
        "; GENERATED from the error-message table (cpm_pipeline.basic.errmsg). The error",
        "; code is the value loaded into E before JP RAISE_ERROR (the error dispatcher);",
        "; the printer scans E messages forward from ERROR_MESSAGE_TABLE. EQUs are",
        "; zero-width, so INCLUDEing this is byte-identical.",
        "",
    ]
    width = max(len(en) for en, _c, _m in rows)
    for en, code, msg in rows:
        shown = msg if msg.strip() not in ("", "?") else "(unused)"
        out.append(f"{en:<{width}} EQU {code:<3} ; {shown}")
    out.append("")
    return "\n".join(out)
