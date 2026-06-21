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


def emit_run_lines(com, run, label_prefix="RAISE_"):
    """Structured assembly for one stub run: each entry labeled <prefix><name>, body
    LD E,ERR_<name>, and a DEFB $01 skip between entries (the last entry has none -- it
    falls into the JR/RAISE_ERROR that follows)."""
    names = _code_err_names(com)
    L = []
    for i, (addr, code) in enumerate(run):
        err_name = names.get(code, f"${code:02X}")
        bare = err_name[len("ERR_"):] if err_name.startswith("ERR_") else err_name
        L.append(f"{label_prefix}{bare}:")
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


def dispatcher_addr(com):
    """Address of RAISE_ERROR. The last coded-error run falls straight through into it, so
    the dispatcher is the byte immediately after that run's final LD E entry."""
    runs = decode_stubs(com)
    return runs[-1][-1][0] + 2 if runs else None


def _code_err_names(com):
    """{error_code: ERR_<name>} from the error-message table equates."""
    from cpm_pipeline.basic import errmsg
    return {code: en for en, code, _m in errmsg.error_equates(com)}


def _jump_target(addr, byts):
    """Target of a JP/JP cc/JR/JR cc/DJNZ from its raw bytes (None if not such a jump)."""
    if not byts:
        return None
    op = byts[0]
    if (op == 0xC3 or op in (0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA)) and len(byts) >= 3:
        return byts[1] | (byts[2] << 8)                     # JP / JP cc,nn
    if (op == 0x18 or op in (0x20, 0x28, 0x30, 0x38, 0x10)) and len(byts) >= 2:
        d = byts[1] - 256 if byts[1] >= 128 else byts[1]    # JR / JR cc,e / DJNZ
        return (addr + 2 + d) & 0xFFFF
    return None


def _line_addr_bytes_target(ln):
    """(run-address, byte-count, jump-target|None) parsed from a line's `; $addr  HH HH`
    byte comment; (None, 0, None) for a line with no byte comment (label/section/structured
    line)."""
    m = _CMT.search(ln)
    if not m:
        return (None, 0, None)
    addr = int(m.group(1), 16)
    byts = [int(x, 16) for x in m.group(2).split()]
    return (addr, len(byts), _jump_target(addr, byts))


# A direct raise loads the error code into E and jumps to RAISE_ERROR. Two idioms:
#   LD E,$nn       (1E nn)        -- E = code
#   LD DE,$00nn    (11 nn 00)     -- E = code, D = 0 (16-bit value IS the code, high byte 0)
# so the literal operand always equals the error code and names the ERR_* equate.
_LDE_LIT = re.compile(r"^(\s*LD\s+(?:E|DE),)(\$[0-9A-Fa-f]{2,4})\b")


def apply_direct_raise_renames(lines, com):
    """Rewrite a DIRECT raise site `LD E,$nn` / `LD DE,$00nn` -> `LD (D)E,ERR_<name>`: an LD
    whose very next instruction (at addr + its length) is a JP/JR (conditional or not) to
    RAISE_ERROR. The literal value is the error code, so it names the ERR_* equate
    (byte-identical: the equate resolves to the same value). This is the non-table sibling of
    the coded-error stubs (e.g. ERROR_FC: LD E,$05; JP RAISE_ERROR -> LD E,
    ERR_ILLEGAL_FUNCTION_CALL; STMT_CONT: LD DE,$0011 -> LD DE,ERR_CANT_CONTINUE)."""
    disp = dispatcher_addr(com)
    if disp is None:
        return list(lines)
    names = _code_err_names(com)
    out = list(lines)
    info = [_line_addr_bytes_target(ln) for ln in out]
    for i, ln in enumerate(out):
        m = _LDE_LIT.match(ln.partition(";")[0])
        if not m:
            continue
        val = int(m.group(2).lstrip("$"), 16)
        a, nb, _ = info[i]
        if a is None or val > 0xFF or val not in names:       # high byte must be 0 (E = code)
            continue
        j = i + 1
        while j < len(out) and info[j][0] is None:            # skip comment/label lines
            j += 1
        if j < len(out) and info[j][0] == a + nb and info[j][2] == disp:
            head, sep, rest = ln.partition(";")
            out[i] = head.replace(m.group(2), names[val], 1) + sep + rest
    return out


def apply_reference_renames(lines, com, old_labels=None, addrnames=None, run_spans=None):
    """Rewrite every reference to a stub entry to its <name> label, whatever form the operand
    currently has (a literal $addr, an old machine label, or a local+offset like
    SUB_xxxx_n+1). The instruction's real target is read from its `; $addr  HH HH` byte
    comment; if that target is a stub entry, the operand is replaced. Byte-identical.
    By default operates on the low-RAM coded-error stubs; pass addrnames/run_spans to reuse
    it for another run (e.g. the disk-error vectors)."""
    if addrnames is None:
        addrnames = _stub_addr_names(com)
    if run_spans is None:
        run_spans = [(run[0][0], run[-1][0] + 2) for run in decode_stubs(com)]  # [start,end)
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


# ---- the disk-error-raise vector run -------------------------------------------------
# A SECOND overlap-skip run sits outside the low-RAM range: the disk/RWTS error path JPs to
# one of these entries (also held in a cold-start vector table) to set E, then falls into a
# shared tail that reselects the default drive (BDOS fn 14) and JP RAISE_ERROR. decode_stubs
# can't reach it (its scan is bounded to low RAM, and in the relocated GBASIC body the .COM
# address != the run-time address anyway), so it is found in LINE space via the byte comments.
# It is THE overlap run whose codes are all disk errors (>=50) or the disk reset error (31) --
# which excludes the low-RAM runs (already spliced) and the coincidental same-idiom uses that
# carry type codes / screen cells / FP field values (DEFSTR, screen HOME, FOUT).

def _line_bytes(ln):
    m = _CMT.search(ln)
    if not m:
        return None, None
    return int(m.group(1), 16), [int(x, 16) for x in m.group(2).split()]


def _runs_in_lines(lines):
    """All overlap-skip runs visible in the emitted lines (by byte comment): a `LD E,$nn`
    (1E nn) start, then `LD BC,$nn1E` (01 1E nn) continuations. Returns [[(entry_addr,
    code), ...], ...] with each continuation's REAL entry at the +1 address."""
    code_lines = [(a, b) for a, b in (_line_bytes(ln) for ln in lines) if a is not None]
    runs, k = [], 0
    while k < len(code_lines):
        a, b = code_lines[k]
        if len(b) >= 2 and b[0] == 0x1E:
            ent = [(a, b[1])]; k += 1
            while k < len(code_lines):
                a2, b2 = code_lines[k]
                if len(b2) >= 3 and b2[0] == 0x01 and b2[1] == 0x1E:
                    ent.append((a2 + 1, b2[2])); k += 1
                else:
                    break
            if len(ent) >= 2:
                runs.append(ent)
            continue
        k += 1
    return runs


def disk_vector_run(lines):
    """The disk-error-raise vector run (entries [(addr, code)]) found in line space, or None.
    Must be called BEFORE the run is spliced (it keys off the LD BC cover byte comments)."""
    for ent in _runs_in_lines(lines):
        if all(c == 31 or c >= 50 for _a, c in ent):
            return ent
    return None


def splice_disk_vectors_into(lines, com, run=None):
    """Replace the disk-error vector run's LD BC covers (and the wrong neighbouring-routine
    locals the formatter put on them) with the structured DISK_RAISE_<name> / LD E,ERR_<name>
    / DEFB $01 form. DISK_RAISE_* (not RAISE_*) avoids colliding with the low-RAM disk entries
    of the same code (e.g. Disk I/O error appears in both runs)."""
    if run is None:
        run = disk_vector_run(lines)
    if run is None:
        return list(lines)
    cover_addrs = {run[0][0]} | {a - 1 for a, _c in run[1:]}   # LD E start + each 01 cover
    is_lbl = re.compile(r"^([A-Za-z_]\w*):\s*$")
    cover_idx = [i for i, ln in enumerate(lines)
                 if (lb := _line_bytes(ln)[0]) is not None and lb in cover_addrs]
    if not cover_idx:
        return list(lines)
    lo_i, hi_i = min(cover_idx), max(cover_idx)
    j = lo_i - 1                                                # absorb the run's own labels
    while j >= 0 and (is_lbl.match(lines[j]) or lines[j].lstrip().startswith(";")
                      or not lines[j].strip()):
        j -= 1
    start = j + 1
    header = [
        "; -- Disk-error raise vectors. The disk/RWTS error path enters one of these (the",
        ";    entries are also stored in the cold-start vector table); each sets E and falls",
        ";    through the shared tail (DISK_RESELECT_AND_RAISE) which reselects the default",
        ";    drive (BDOS fn 14) then JP RAISE_ERROR. Same overlap-skip idiom as the low-RAM",
        ";    coded-error stubs; labelled DISK_RAISE_* so codes shared with the low-RAM run",
        ";    don't collide.",
    ]
    block = emit_run_lines(com, run, label_prefix="DISK_RAISE_")
    tail = [
        "; [RE] Shared disk-error exit: save the code (E), issue BDOS Select-Disk (C=$0E) on",
        ";    the CP/M current-drive byte ($0004) to reselect the default drive, then raise.",
        "DISK_RESELECT_AND_RAISE:",
    ]
    return lines[:start] + header + block + tail + lines[hi_i + 1:]


def apply_disk_vector_renames(lines, com, run):
    """Rewrite every reference into the disk-error vector run (e.g. the cold-start table's
    `LD DE,GFX_..+1` / `LD HL,GFX_..`) to its DISK_RAISE_<name> label, by target address."""
    if run is None:
        return list(lines)
    names = _code_err_names(com)
    addrnames = {a: "DISK_RAISE_" + (names[c][len("ERR_"):] if c in names else f"{c:02X}")
                 for a, c in run}
    span = [(run[0][0], run[-1][0] + 2)]
    return apply_reference_renames(lines, com, addrnames=addrnames, run_spans=span)
