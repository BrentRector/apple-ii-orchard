"""Structure the Microsoft BASIC-80 (SoftCard 2.20) coded-error STUB table.

Low-RAM holds two runs of error-raise stubs that JP/JR/fall into RAISE_ERROR ($0D89) with
the error code in E. Each stub is `LD E,$xx` (2 bytes) followed by a `$01` byte: the $01 is
the opcode of `LD BC,nn`, so when a stub falls THROUGH, the next `LD E,$yy` is swallowed as
that LD BC's 2-byte operand and skipped -- the classic overlap-skip idiom. Code jumps to a
specific `LD E` entry to raise that error, then the trailing stubs are harmlessly skipped
down to RAISE_ERROR.

The disassembler rendered the run as `LD BC,$yy1E` covers, which hid the per-stub entries
and their error codes. This module re-renders it as the real overlapping instructions:

    RAISE_<NAME>:  LD E,ERR_<NAME>     ; the raise entry (a JP target)
                   DEFB $01            ; LD BC opcode = 2-byte skip over the next LD E

so each stub gets a semantic label, uses the ERR_* error-code equate, and the $01 skip is
explicit. Byte-identical (ERR_<NAME> resolves to the code, LD E,n + DEFB $01 = the bytes).
"""
import re

SCAN_LO, SCAN_HI = 0x0C00, 0x0F00


def decode_stubs(com, lo=SCAN_LO, hi=SCAN_HI):
    """Return [[(addr, code), ...], ...] -- the runs of LD E,$xx stubs (>= 2 entries),
    each separated by a $01 skip byte."""
    def b(a):
        return com[a - 0x100]
    runs = []
    a = lo
    while a < hi - 3:
        # a run start: LD E,xx ($1E) then a $01 skip then another LD E,xx
        if b(a) == 0x1E and b(a + 2) == 0x01 and b(a + 3) == 0x1E:
            entries = []
            while a < hi and b(a) == 0x1E:
                entries.append((a, b(a + 1)))
                a += 2
                if b(a) == 0x01:
                    a += 1
                else:
                    break
            runs.append(entries)
        else:
            a += 1
    return runs


def _name_map(com):
    """{code: (ERR_name, RAISE_name)} from the error-code equates."""
    from cpm_pipeline.basic import errmsg
    out = {}
    for err_name, code, _msg in errmsg.error_equates(com):
        out[code] = (err_name, "RAISE_" + err_name[len("ERR_"):])
    return out


def _stub_addr_names(com):
    """{stub_addr: RAISE_<name>} for every stub entry address."""
    names = _name_map(com)
    out = {}
    for run in decode_stubs(com):
        for addr, code in run:
            if code in names:
                out[addr] = names[code][1]
    return out


_MLABEL = re.compile(r"^(?:SUB|L)_[0-9A-Fa-f]{4}$")


def stub_old_labels(lines, com):
    """{old_machine_label: RAISE_<name>} for any machine label (SUB_/L_) defined at a stub
    entry address in `lines` -- captured BEFORE the splice drops them, so references that
    used the old label (e.g. a dispatch DEFW) can be rewritten to RAISE_<name>."""
    addrnames = _stub_addr_names(com)
    labdef = re.compile(r"^([A-Za-z_]\w*):\s*$")
    out, pend = {}, []
    for ln in lines:
        m = labdef.match(ln)
        if m:
            pend.append(m.group(1)); continue
        a = _addr(ln)
        if a is not None:
            if a in addrnames:
                for lab in pend:
                    if _MLABEL.match(lab):
                        out[lab] = addrnames[a]
            pend = []
        elif ln.strip():
            pend = []
    return out


def emit_run_lines(com, run):
    """Structured assembly for one stub run: each entry labeled RAISE_<name>, body
    LD E,ERR_<name>, and a DEFB $01 skip between entries (the last entry has none -- it
    falls into the JR/RAISE_ERROR that follows)."""
    names = _name_map(com)
    L = []
    for i, (addr, code) in enumerate(run):
        err_name, raise_name = names.get(code, (f"${code:02X}", f"RAISE_${code:02X}"))
        L.append(f"{raise_name}:")
        L.append(f"        LD E,{err_name:<26} ; ${addr:04X}  raise error {code}")
        if i != len(run) - 1:
            L.append(f"        DEFB    {'$01':<26} ; ${addr+2:04X}  LD BC opcode = skip the next LD E")
    return L


def _addr(ln):
    m = re.search(r";\s*\$([0-9A-Fa-f]{4})\b", ln)
    return int(m.group(1), 16) if m else None


def splice_stubs_into(lines, com):
    """Replace the formatter's cover-idiom lines covering each stub run with the
    structured RAISE_<name> / LD E,ERR_<name> / DEFB $01 form. A bare label is dropped
    only when its addressed line falls INSIDE a run (it is a stub's own label); a label
    on the routine immediately after a run (e.g. RAISE_ERROR at $0D89) is kept."""
    spans = {(run[0][0], run[-1][0] + 2): run for run in decode_stubs(com)}

    def span_of(a):
        return next((s for s in spans if a is not None and s[0] <= a < s[1]), None)

    is_label = re.compile(r"^([A-Za-z_]\w*):\s*$")
    out, pend, emitted = [], [], set()
    for ln in lines:
        m = is_label.match(ln)
        a = _addr(ln)
        if m and a is None:
            pend.append(ln); continue
        sp = span_of(a)
        if sp:
            pend = []                                   # drop the run's own labels
            if sp not in emitted:
                out.extend(emit_run_lines(com, spans[sp])); emitted.add(sp)
            continue
        out.extend(pend); pend = []                     # flush labels for non-run lines
        out.append(ln)
    out.extend(pend)
    return out


_CMT = re.compile(r";\s*\$([0-9A-Fa-f]{4})\s+((?:[0-9A-Fa-f]{2}\s*)+?)\s*$")
_OPERAND = re.compile(
    r"^(\s*(?:JP|JR|CALL|DJNZ)\s+(?:\w+\s*,\s*)?"     # mnemonic + optional condition (Z, NC, ...)
    r"|\s*DEFW\s+"
    r"|\s*LD\s+(?:BC|DE|HL|IX|IY)\s*,\s*)"
    r"(\S.*?)\s*$")                                    # the operand (literal / label / label+offset)


def _stub_target(code, addr, byts):
    """The 16-bit operand target of a stub-referencing instruction, from its raw bytes."""
    op = code.split()[0] if code.split() else ""
    if op == "DEFW" and len(byts) >= 2:
        return byts[0] | (byts[1] << 8)
    if op in ("JR", "DJNZ") and len(byts) >= 2:
        d = byts[1] - 256 if byts[1] >= 128 else byts[1]
        return (addr + 2 + d) & 0xFFFF
    if op in ("JP", "CALL", "LD") and len(byts) >= 3:
        return byts[1] | (byts[2] << 8)
    return None


def apply_reference_renames(lines, com, old_labels=None):
    """Rewrite every reference to a stub entry to its RAISE_<name> label, whatever form the
    operand currently has (a literal $addr, an old machine label, or a local+offset like
    SUB_xxxx_n+1). The instruction's real target is read from its `; $addr  HH HH` byte
    comment; if that target is a stub entry, the operand is replaced. Byte-identical."""
    addrnames = _stub_addr_names(com)
    runs = decode_stubs(com)
    run_spans = [(run[0][0], run[-1][0] + 2) for run in runs]   # [start, end) per run
    old_labels = old_labels or {}
    labpat = (re.compile(r"\b(" + "|".join(re.escape(k) for k in
              sorted(old_labels, key=len, reverse=True)) + r")\b") if old_labels else None)

    def in_run(a):
        return any(s <= a < e for s, e in run_spans)

    out = []
    for ln in lines:
        code, sep, rest = ln.partition(";")
        # 1) old head labels (e.g. a dispatch DEFW SUB_0D6F that the splice removed)
        if labpat:
            code = labpat.sub(lambda m: old_labels[m.group(1)], code)
        # 2) any instruction whose real target (from its byte comment) is in a stub run
        cm = _CMT.search(";" + rest) if rest else None
        om = _OPERAND.match(code)
        if cm and om:
            addr = int(cm.group(1), 16)
            byts = [int(x, 16) for x in cm.group(2).split()]
            tgt = _stub_target(code, addr, byts)
            if tgt in addrnames:                       # a real raise entry -> RAISE_<name>
                code = om.group(1) + addrnames[tgt]
            elif tgt is not None and in_run(tgt):      # interior (a $01 skip byte, often a
                code = om.group(1) + f"${tgt:04X}"     # data-as-code artifact) -> keep literal
        out.append(code + sep + rest)
    return out
