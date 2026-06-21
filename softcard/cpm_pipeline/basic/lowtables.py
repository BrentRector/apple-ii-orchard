"""Structured labels for the low-region DISPATCH and OPERATOR tables ($0108-$0521).

Like the reserved-word table (cpm_pipeline.basic.reswords), these are relocatable image
data that only keeps the same address in both BASIC builds because the loader does not
relocate the low region -- so every code reference into them must be a LABEL, not a frozen
literal.  This module assigns one semantic base label per table and rewrites every
reference INTO a table (a machine label L_xxxx the walker minted at a table address) to
``<base>`` or ``<base>+offset``.  Byte-identical (label/offset resolves to the same value).

Table layout (validated against the dispatch decode):
  $0108  STMT_DISPATCH_TBL     statement-handler pointers, 85 x DEFW, index (token-$81)*2
  $01B2  FUNC_DISPATCH_TBL     function-handler pointers,  54 x DEFW, index  token*2
  $04ED  FRMEVL_PREC_TBL       operator precedence bytes (12)
  $04F9  OPERATOR_ROUTINE_TBL  operator routine pointers, 20 x DEFW (+ $0521 terminator)
"""
import re

# (base, end_exclusive, name, is_defw_pointer_table)
TABLES = [
    (0x0108, 0x01B2, "STMT_DISPATCH_TBL", True),
    (0x01B2, 0x021E, "FUNC_DISPATCH_TBL", True),
    (0x04ED, 0x04F9, "FRMEVL_PREC_TBL", False),    # 12 precedence BYTES (any offset ok)
    (0x04F9, 0x0522, "OPERATOR_ROUTINE_TBL", True),
]


def structured_labels():
    """{base_addr: name} -- the one label that DEFINES each table."""
    return {base: name for base, _end, name, _ in TABLES}


def _table_of(addr):
    for base, end, name, defw in TABLES:
        if base <= addr < end:
            return base, name, defw
    return None


def is_mid_pointer(addr):
    """True if addr is the HIGH byte of a DEFW pointer entry (odd offset into a DEFW
    table). A reference to such an address can't be a genuine table-entry reference --
    it would split the relocatable pointer into frozen bytes -- so it is a CONSTANT and
    must stay a literal."""
    t = _table_of(addr)
    return bool(t and t[2] and (addr - t[0]) % 2 == 1)


def reference_renames():
    """{f'L_{addr:04X}': '<base>' | '<base>+n'} for every table address that is a valid
    reference target (a table base, a DEFW entry boundary, or any byte of a byte-table).
    Mid-DEFW-pointer addresses are EXCLUDED (they are constants -> kept literal)."""
    out = {}
    for base, end, name, _defw in TABLES:
        for a in range(base, end):
            if is_mid_pointer(a):
                continue
            out[f"L_{a:04X}"] = name if a == base else f"{name}+{a - base}"
    return out


def literal_sites(mem, code, lo, hi):
    """Instruction addresses in [lo, hi) whose 16-bit operand is a mid-DEFW-pointer
    table address (a constant that coincidentally lands inside a dispatch/operator
    table) -> keep literal so it is neither labeled nor splits the relocatable table."""
    sites = set()
    for a in code:
        if not (lo <= a < hi):
            continue
        try:
            ins = _decode(mem, a)
        except (IndexError, KeyError):
            continue
        for m in re.finditer(r'\$([0-9A-Fa-f]{4})', ins.mnemonic):
            if is_mid_pointer(int(m.group(1), 16)):
                sites.add(a)
    return sites


def _decode(mem, a):
    from disasm_z80.opcodes import decode_at
    return decode_at(mem, a)


_DEF_RE = re.compile(r'^(L_[0-9A-Fa-f]{4}):\s*$')


def apply(lines):
    """Rewrite references into the dispatch/operator tables to <base>[+n]; rename each
    base's label definition to the semantic name and DROP interior label definitions
    (the reference now resolves through the base label). Byte-identical."""
    ren = reference_renames()
    base_tokens = {f"L_{a:04X}" for a in structured_labels()}
    # every non-base address inside a table: its label DEFINITION is dropped (an even
    # offset is referenced via <base>+n; an odd mid-pointer offset is referenced as a
    # literal constant) so the DEFW table is never split by a stray interior label.
    interior_defs = {f"L_{a:04X}" for base, end, _n, _d in TABLES
                     for a in range(base, end) if a != base}
    pat = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                     sorted(ren, key=len, reverse=True)) + r')\b')
    out = []
    for ln in lines:
        dm = _DEF_RE.match(ln)
        if dm and dm.group(1) in interior_defs and dm.group(1) not in base_tokens:
            continue                         # drop interior table label definition
        code, sep, rest = ln.partition(';')
        out.append(pat.sub(lambda m: ren[m.group(1)], code) + sep + rest)
    return out
