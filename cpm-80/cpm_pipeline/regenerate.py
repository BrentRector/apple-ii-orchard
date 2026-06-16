"""Regenerate annotated disassembly sources with the improved disassembler.

The disassemblers now emit mid-instruction references inline as ``cover+offset``
(no equates) and rename a routine's branch-only labels to ``<routine>_<n>``
(``localize_labels``). A *semantic overlay* -- an ordinary symbol JSON of
``address -> name`` produced by AI analysis of the routine bodies -- turns the
auto ``SUB_xxxx`` heads into meaningful names (e.g. ``CONOUT``), which the
localizer then carries into the locals (``CONOUT_1``, ``CONOUT_2``).

This module regenerates a checked-in ``.asm``/``.s`` source from its original
binary while:

  * keeping the reassembly **byte-identical** (verified here), and
  * preserving the existing ``; [AI]`` prose comments by **migrating them by
    address** (old label -> address -> new label), so curated annotation is not
    lost when labels are renamed.

Only *names* come from AI; the bytes never round-trip through a model, and the
comments are carried over verbatim, so the result still reassembles exactly.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from .annotate_ai import insert_comments

# A column-0 label (ca65 / sjasmplus): NAME or NAME:.
_LABEL_RE = re.compile(r"^([A-Za-z_.][A-Za-z0-9_.]*):")
# The address comment every emitted code/data line carries: "; $XXXX".
_ADDR_RE = re.compile(r";\s*\$([0-9A-Fa-f]{4})\b")
# A full-line comment (only whitespace before the ';').
_FULL_COMMENT_RE = re.compile(r"^\s*;")


def parse_label_addrs(text: str) -> dict[str, int]:
    """Map each label name to the address of the first emitted item after it.

    Robust to renaming: every code/data line carries a ``; $XXXX`` address
    comment, and labels sit on their own line just above. Consecutive labels at
    the same address all map to that address."""
    out: dict[str, int] = {}
    pending: list[str] = []
    for line in text.splitlines():
        m = _LABEL_RE.match(line)
        if m:
            pending.append(m.group(1))
            continue
        am = _ADDR_RE.search(line)
        if am and pending:
            addr = int(am.group(1), 16)
            for name in pending:
                out[name] = addr
            pending = []
    return out


def extract_ai_comments(text: str) -> dict[str, str]:
    """Extract ``; [AI] ...`` prose blocks keyed by the label they annotate.

    A block is a run of full-line ``;`` comments beginning with ``; [AI]`` that
    sits immediately above a label line (exactly how ``insert_comments`` emits
    them). Returns {label: prose}."""
    out: dict[str, str] = {}
    block: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("; [AI]"):
            block = [stripped[len("; [AI]"):].strip()]
            continue
        if block and _FULL_COMMENT_RE.match(line):
            # continuation line of the current [AI] block
            block.append(stripped.lstrip(";").strip())
            continue
        m = _LABEL_RE.match(line)
        if m and block:
            out[m.group(1)] = " ".join(p for p in block if p).strip()
        block = []
    return out


def migrate_comments(old_text: str, new_text: str) -> tuple[str, int, int]:
    """Carry the ``[AI]`` comments from `old_text` onto `new_text` by address.

    Returns (new_text_with_comments, migrated, dropped). A comment is dropped
    only when its address no longer carries a label (e.g. it sat on an old
    mid-instruction overlap label that is now referenced inline)."""
    old_addrs = parse_label_addrs(old_text)
    old_comments = extract_ai_comments(old_text)
    # old label -> address -> comment
    addr_comments: dict[int, str] = {}
    for label, prose in old_comments.items():
        addr = old_addrs.get(label)
        if addr is not None:
            addr_comments.setdefault(addr, prose)
    new_addrs = parse_label_addrs(new_text)
    addr_to_new = {}
    for label, addr in new_addrs.items():
        addr_to_new.setdefault(addr, label)   # first label at the address wins
    new_comments: dict[str, str] = {}
    dropped = 0
    for addr, prose in addr_comments.items():
        label = addr_to_new.get(addr)
        if label is not None:
            new_comments[label] = prose
        else:
            dropped += 1
    out_text, added = insert_comments(new_text, new_comments)
    return out_text, added, dropped


# Auto labels the disassembler mints itself (re-derived on every run); anything
# else in a source is a curated/semantic name worth preserving.
_AUTO_LABEL_RE = re.compile(r"^(L_|SUB_)[0-9A-Fa-f]{4}$")


def extract_semantic_labels(text: str) -> dict[int, str]:
    """Return {address: name} for every inline label in `text` that is NOT an
    auto ``L_xxxx``/``SUB_xxxx`` name -- i.e. the hand-curated / symbol-derived
    semantic labels. These must be fed back as an overlay so regeneration
    reproduces them instead of reverting to auto names."""
    out: dict[int, str] = {}
    for label, addr in parse_label_addrs(text).items():
        if not _AUTO_LABEL_RE.match(label):
            out.setdefault(addr, label)
    return out


def overlay_json(names: dict[int, str], *, comments: dict[int, str] | None = None) -> dict:
    """Build a schema-1.0 symbol-table dict from {address: semantic_name}, ready
    to write as a JSON overlay loaded alongside the curated symbol tables."""
    comments = comments or {}
    entries = {}
    for addr, name in sorted(names.items()):
        e = {"name": name}
        if addr in comments and comments[addr]:
            e["comment"] = comments[addr]
        entries[f"0x{addr:04X}"] = e
    return {"schema_version": "1.0", "categories": {"semantic_names": entries}}


@dataclass
class RegenResult:
    path: Path
    byte_identical: bool
    comments_migrated: int
    comments_dropped: int
    semantic_names: int
    notes: list[str] = field(default_factory=list)


# ── Disassembly recipes ────────────────────────────────────────────────
#
# Each checked-in source has an authoritative recipe that reproduces it
# byte-identically from its original binary. We reuse the existing ones:
#   * Z-80  -> region_disasm.disasm_z80_region (+ the right seeds/symbols)
#   * 6502  -> disasm6502 Walker + Ca65Formatter (+ ld65 to assemble)
# A *semantic overlay* (an extra symbol JSON) is merged in to give heads their
# AI-synthesized names; it never changes bytes (names only).

import subprocess
import tempfile

from .region_disasm import disasm_z80_region, assemble_z80, load_symbols as _load_z80_syms
from .region_disasm import bios_jump_table_seeds

import disasm6502.symbols as _d6502_syms
from disasm6502.walker import Walker as _Walker6502
from disasm6502.formatter import Ca65Formatter
from disasm6502.opcodes import OPCODES as _OPCODES_6502

_ABS_MODES_6502 = ("ABS", "ABX", "ABY", "IND")


def leading_jp_seeds(mem, org, length, *, op):
    """Seed `org` plus the targets of a leading run of ``JP nn`` (Z-80 op 0xC3)
    or ``JMP nn`` (6502 op 0x4C) instructions -- the BIOS/loader jump-table
    idiom -- so the table's handlers are traced as code."""
    seeds = {org}
    i = 0
    while i + 3 <= min(length, 0x80) and mem[org + i] == op:
        t = mem[org + i + 1] | (mem[org + i + 2] << 8)
        if org <= t < org + length:
            seeds.add(t)
        i += 3
    return seeds


def _load_6502_syms(*paths):
    t = _d6502_syms.SymbolTable()
    for p in paths:
        p = Path(p)
        if p.exists():
            t.load_file(str(p))
    return t


# ── 6502 relocation passes (parity with the Z-80 disasm_z80_region passes) ──
# These plant labels / pointer words so absolute operands and pointer tables
# render as relocatable symbols, reusing the shared classify_data machinery.
# They stay byte-identical: a `.word LABEL` / symbolic operand assembles to the
# same bytes; only the structure improves. `_6502_isize` decodes one length.
def _6502_isize(mem, a):
    e = _OPCODES_6502.get(mem[a])
    return (e[2] if e else 1) or 1


def seed_leading_jmp_vector_6502(walker, mem, org, length):
    """Seed each slot of a leading `JMP nn` vector at the origin (the analogue of
    seed_leading_jp_vector). Mostly redundant -- the caller already seeds via
    leading_jp_seeds(op=0x4C) -- but kept for parity and robustness."""
    a = org
    while a + 2 < org + length and (a - org) < 0x30 and mem[a] == 0x4C:
        walker.trace(a)
        a += 3


def resolve_jmp_indirect_6502(walker, mem, org, length):
    """For each `JMP ($vec)` (opcode 0x6C): if the vector and its target are
    in-range, label + trace the target and emit the vector word as a relocatable
    `.word`. The 6502 dispatch analogue of the Z-80 computed-jump resolver, but
    a direct read -- no register tracking. Returns the vector-word addresses."""
    body_end = org + length
    pw = set()
    a = org
    while a + 2 < body_end:
        if a in walker.code and mem[a] == 0x6C:                  # JMP IND
            vec = mem[a + 1] | (mem[a + 2] << 8)
            if org <= vec < body_end - 1:
                tgt = mem[vec] | (mem[vec + 1] << 8)
                if org <= tgt < body_end:
                    walker.add_label(tgt)
                    walker.trace(tgt)
                    walker.add_label(vec)
                    pw.add(vec)
        a += _6502_isize(mem, a) if a in walker.code else 1
    return pw


def label_inrange_operands_6502(walker, mem, org, length):
    """Plant a label on every in-range ABS/ABX/ABY/IND operand so the formatter
    renders it as a symbol that relocates with ORG. A genuine in-range 16-bit
    constant would be mislabeled; the byte-identical round-trip catches that."""
    body_end = org + length
    a = org
    while a < body_end:
        if a in walker.code:
            e = _OPCODES_6502.get(mem[a])
            if e is None:
                a += 1
                continue
            _, mode, size = e
            if mode in _ABS_MODES_6502 and a + 2 < body_end:
                v = mem[a + 1] | (mem[a + 2] << 8)
                if org <= v < body_end:
                    walker.add_label(v)
            a += size or 1
        else:
            a += 1


def scan_pointer_words_6502(walker, mem, org, length):
    """Find static pointer words in data: a 2-byte LE value resolving to a label
    or instruction-start -> emit as `.word <label>`. Greedy + 2-byte aligned;
    skip if the pointer's high byte is itself a referenced label (a `.word`
    there would swallow that label). A false positive surfaces as a relocation
    mismatch in the round-trip."""
    body_end = org + length
    starts = set()
    a = org
    while a < body_end:
        if a in walker.code:
            starts.add(a)
            a += _6502_isize(mem, a)
        else:
            a += 1
    pw = set()
    a = org
    while a + 1 < body_end:
        if a in walker.code or walker.in_data_region(a):
            a += 1
            continue
        v = mem[a] | (mem[a + 1] << 8)
        if (org <= v < body_end and (v in walker.labels or v in starts)
                and (a + 1) not in walker.labels):
            pw.add(a)
            walker.add_label(v)
            a += 2
        else:
            a += 1
    return pw


def disasm_6502_region(mem, org, length, *, symbols=None, seeds=(), source_name="",
                       force_labels=None, resolve_dispatch=True):
    """Disassemble a 6502 region to ca65 source. Returns (asm_text, cfg_text).

    `force_labels` ({addr: name}) plants a label at each in-range address (see
    disasm_z80_region) to preserve hand-curated / AI semantic names.

    `resolve_dispatch` runs the relocation passes (JMP-indirect resolution,
    in-range operand labeling, static pointer words) so absolute operands and
    pointer tables render as relocatable symbols -- parity with the Z-80 path."""
    walker = _Walker6502(mem, start=org, end=org + length)
    for s in sorted(set(seeds) | {org}):
        walker.trace(s)
    pointer_words = None
    if resolve_dispatch:
        seed_leading_jmp_vector_6502(walker, mem, org, length)
        dispatch_words = resolve_jmp_indirect_6502(walker, mem, org, length)
        label_inrange_operands_6502(walker, mem, org, length)
        pointer_words = scan_pointer_words_6502(walker, mem, org, length) | dispatch_words
    if force_labels:
        for addr, name in force_labels.items():
            if org <= addr < org + length:
                walker.labels[addr] = name
    walker.name_labels(symbols=symbols)
    fmt = Ca65Formatter(mem, walker, symbols, origin=org, length=length,
                        source_name=source_name, pointer_words=pointer_words)
    return fmt.emit_source(), fmt.emit_config()


def assemble_6502(asm_text, cfg_text):
    """Assemble ca65 source (+ its cfg) back to bytes for a round-trip check."""
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        asm = td / "r.s"
        cfg = td / "r.cfg"
        obj = td / "r.o"
        out = td / "r.bin"
        asm.write_text(asm_text, encoding="utf-8")
        cfg.write_text(cfg_text, encoding="utf-8")
        r1 = subprocess.run(["ca65", str(asm), "-o", str(obj)],
                            capture_output=True, text=True)
        if r1.returncode != 0:
            return b""
        subprocess.run(["ld65", "-C", str(cfg), "-o", str(out), str(obj)],
                       capture_output=True, text=True)
        return out.read_bytes() if out.exists() else b""


# ── Target registry ────────────────────────────────────────────────────
_REPO = Path(__file__).resolve().parents[2]
_INVEST = _REPO / "cpm-80" / "cpm-investigation"
_DOCS = _REPO / "cpm-80" / "docs"
_SYM = _REPO / "shared" / "symbols"


@dataclass(frozen=True)
class Target:
    """A regenerable source file and the recipe that reproduces it byte-identical."""
    out_path: Path          # checked-in .asm/.s to (re)write
    cpu: str                # '6502' | 'z80'
    bin_path: Path          # source binary
    lo: int                 # byte slice [lo:hi) of the binary
    hi: int
    org: int                # load address
    symbols: tuple          # symbol-table paths (curated), in precedence order
    seed: str               # 'bios' | 'jp' | 'jmp'  (seeding strategy)
    savebin: str = ""       # Z-80 SAVEBIN path substituted for {out_bin} on write


def _docs_targets():
    t = []
    # Z-80 BIOS (runtime + on-disk), from gen_bios's recipe.
    bios = [
        ("CPM223_BIOS",      "bios_223.bin",    0, 0x548,   0xFA00, "cpm_2_23_bios.json"),
        ("CPM220_BIOS",      "bios_220.bin",    0, 0x800,   0xDA00, "cpm_2_20_bios.json"),
        ("CPM223_BIOS_Disk", "staging_223.bin", 6400, 7424, 0xFA00, "cpm_2_23_bios.json"),
        ("CPM220_BIOS_Disk", "staging_220.bin", 5888, 7168, 0xDA00, "cpm_2_20_bios.json"),
    ]
    for stem, b, lo, hi, org, bsym in bios:
        t.append(Target(_DOCS / f"{stem}.asm", "z80", _INVEST / b, lo, hi, org,
                        (_SYM / bsym, _SYM / "cpm_2_2.json"), "bios",
                        savebin=f"build/{stem}.bin"))
    # Z-80 CCP+BDOS system image (both variants).
    for stem, b in (("CPM223_SystemImage", "sysimg_223.bin"),
                    ("CPM220_SystemImage", "sysimg_220.bin")):
        t.append(Target(_DOCS / f"{stem}.asm", "z80", _INVEST / b, 0, 0x1700, 0x8000,
                        (_SYM / "cpm_2_2.json",), "jp", savebin=f"build/{stem}.bin"))
    # Z-80 disk callbacks (2.23 only).
    t.append(Target(_DOCS / "CPM223_DiskCallbacks.asm", "z80",
                    _INVEST / "diskcallbacks_223.bin", 0, 0x200, 0x1A00,
                    (_SYM / "cpm_2_2.json", _SYM / "cpm_2_23_bios.json"), "jp",
                    savebin="build/CPM223_DiskCallbacks.bin"))
    # 6502 boot loader / RWTS / install fragments (both variants).
    for var, suf in (("CPM223", "223"), ("CPM220", "220")):
        t.append(Target(_DOCS / f"{var}_BootLoader.asm", "6502",
                        _INVEST / f"loader_{suf}.bin", 0, 0x0C00, 0x0800,
                        (_SYM / "apple2.json",), "jmp"))
        t.append(Target(_DOCS / f"{var}_RWTS.asm", "6502",
                        _INVEST / f"rwts_{suf}.bin", 0, 0x0600, 0x0A00,
                        (_SYM / "apple2.json",), "jmp"))
        t.append(Target(_DOCS / f"{var}_InstallFragments.asm", "6502",
                        _INVEST / f"installfragments_{suf}.bin", 0, 0x0200, 0x0200,
                        (_SYM / "apple2.json",), "jmp"))
    return t


DOCS_TARGETS = _docs_targets()


def _decompiled_os_targets():
    """The machine-disassembly OS-region tree (decompile_os `auto/` output:
    CPM_<Region>.{asm,s}). Same binaries/recipe as the docs OS regions but fully
    auto-labeled (so all of them, not just the BIOS, benefit from AI naming)."""
    from .decompile_os import _REGIONS
    out = []
    for variant, sub in (("softcard_cpm_2_23", "CPMV233"),
                         ("softcard_cpm_2_20", "CPM220")):
        base = _REPO / "cpm-80" / "decompiled" / sub / "os"
        for r in _REGIONS[variant]:
            ext = ".s" if r.cpu == "6502" else ".asm"
            stem = f"CPM_{r.name}"
            seed = "bios" if r.name == "BIOS" else ("jmp" if r.cpu == "6502" else "jp")
            out.append(Target(
                base / f"{stem}{ext}", r.cpu,
                _INVEST / r.bin_name, 0, r.length, r.org,
                tuple(_SYM / s for s in r.symbols), seed,
                savebin=f"{stem}.bin"))
    return out


DECOMPILED_OS_TARGETS = _decompiled_os_targets()


def _load_mem(target):
    data = target.bin_path.read_bytes()[target.lo:target.hi]
    mem = bytearray(0x10000)
    mem[target.org:target.org + len(data)] = data
    return mem, data


def disassemble(target, *, force_labels=None):
    """Disassemble `target` to source, planting `force_labels` ({addr: name})
    for hand-curated / AI semantic names. Returns (source_text, cfg_text_or_None,
    raw_bytes)."""
    mem, data = _load_mem(target)
    length = len(data)
    if target.cpu == "z80":
        syms = _load_z80_syms(*target.symbols)
        if target.seed == "bios":
            seeds = bios_jump_table_seeds(mem, target.org, length)
        else:
            seeds = leading_jp_seeds(mem, target.org, length, op=0xC3)
        src = disasm_z80_region(mem, target.org, length, symbols=syms, seeds=seeds,
                                source_name=target.out_path.stem, force_labels=force_labels)
        return src, None, data
    else:
        syms = _load_6502_syms(*target.symbols)
        seeds = leading_jp_seeds(mem, target.org, length, op=0x4C)
        src, cfg = disasm_6502_region(mem, target.org, length, symbols=syms, seeds=seeds,
                                      source_name=target.out_path.stem, force_labels=force_labels)
        return src, cfg, data


def _reassemble(target, src, cfg):
    if target.cpu == "z80":
        return assemble_z80(src)
    return assemble_6502(src, cfg)


def regenerate(target, *, ai_names=None, write=False, preserve=True):
    """Regenerate one target with the improved disassembler.

    Builds a semantic-name overlay from (a) the hand-curated labels already in
    the existing source (so they are never lost) plus (b) any AI-synthesized
    names in `ai_names` (which fill in the remaining auto heads). Migrates the
    existing ``[AI]`` comments by address, verifies byte-identical, and
    optionally writes the result back. Returns RegenResult."""
    old_text = target.out_path.read_text(encoding="utf-8") if target.out_path.exists() else ""
    names: dict[int, str] = {}
    if preserve and old_text:
        names.update(extract_semantic_labels(old_text))
    if ai_names:
        names.update(ai_names)            # AI names win on auto heads
    src, cfg, data = disassemble(target, force_labels=names)
    merged, migrated, dropped = (migrate_comments(old_text, src) if old_text
                                 else (src, 0, 0))
    rebuilt = _reassemble(target, merged, cfg)
    ok = rebuilt == data
    if write and ok:
        # The Z-80 source carries a `{out_bin}` SAVEBIN placeholder; write it
        # with the canonical build/ path (the byte-check above used the
        # placeholder, which assemble_z80 substitutes to a temp path).
        text = merged
        if target.cpu == "z80":
            savebin = target.savebin or f"build/{target.out_path.stem}.bin"
            text = text.replace("{out_bin}", savebin)
        target.out_path.write_text(text, encoding="utf-8")
        if cfg is not None:
            target.out_path.with_suffix(".cfg").write_text(cfg, encoding="utf-8")
    return RegenResult(target.out_path, ok, migrated, dropped, len(names),
                       notes=[] if ok else ["NOT byte-identical -- not written"])


# ── 60K BIOS recipe (CPMV233-60K) ──────────────────────────────────────
#
# The 60K BIOS is NOT one of the DECOMPILED_OS_TARGETS: it lives in the
# CPMV233-60K tree, which has no registry binary (its bytes come from the
# CPM60.COM installer payload at COM offset 0x2600, ORG $FA00, *after* the 6502
# boot loader's runtime patches -- the booted image, which DELTA.md confirms is
# exactly what the checked-in source reassembles to). It was also last written
# *before* the disassembler's trace/dispatch upgrades, so its BIOS jump table
# was stranded as DEFB and chunks of the relocation/banking code sat unlabeled.
#
# This recipe regenerates it through the current pipeline: source the booted
# bytes by reassembling the byte-identical checked-in source, re-disassemble at
# $FA00/$0600 with the BIOS jump-table seeds (so the table renders as JP) plus
# any extra code seeds, carry every curated inline label (force_labels) AND
# every curated `EQU` symbol (a symbol overlay -- names a plain re-disassembly
# would not reproduce), then verify byte-identical. force_labels also lets new
# AI names be planted (e.g. $FCA4 = CONSOLE_PUT_CHAR).
_BIOS_60K = (_REPO / "cpm-80" / "decompiled" / "CPMV233-60K" / "os" / "CPM_BIOS.asm")
_BIOS_60K_ORG = 0xFA00
_BIOS_60K_LEN = 0x0600


def _assemble_savebin(text: str) -> bytes:
    """Assemble a source carrying a literal ``SAVEBIN "name", org, len`` and
    return the emitted bytes (b"" on failure). Unlike assemble_z80 -- which
    substitutes a ``{out_bin}`` placeholder -- this reads back the file the
    source's own SAVEBIN names, so it works on a checked-in source as-is."""
    m = re.search(r'SAVEBIN\s+"([^"]+)"', text)
    if not m:
        return b""
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        (td / "r.asm").write_text(text, encoding="utf-8")
        subprocess.run(["sjasmplus", "r.asm"], cwd=str(td), capture_output=True, text=True)
        out = td / m.group(1)
        return out.read_bytes() if out.exists() else b""


def _curated_equs(text: str) -> dict[int, tuple[str, str]]:
    """Header ``NAME EQU $XXXX ; comment`` symbols -> {addr: (name, comment)}.
    These external-symbol names are curated, not in the loaded symbol JSON, so
    they must be carried as an overlay or a re-disassembly drops them."""
    out: dict[int, tuple[str, str]] = {}
    for line in text.splitlines():
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s+EQU\s+\$([0-9A-Fa-f]+)\s*(?:;\s*(.*))?$", line)
        if m:
            out[int(m.group(2), 16)] = (m.group(1), (m.group(3) or "").strip())
    return out


_LINK_GUARD_RE = re.compile(r"^(\s*)(DEVICE\s+\S+|ORG\s+\$[0-9A-Fa-f]+|SAVEBIN\s+\".*)$")
_LINK_NOTE = "  ; [link] master defines CPM60_LINK and owns this; standalone keeps it"


def _guard_link_directives(text: str) -> str:
    """Wrap each DEVICE / ORG / SAVEBIN in ``IFNDEF CPM60_LINK ... ENDIF`` so the
    module assembles standalone (CPM60_LINK unset) but can be INCLUDEd into the
    CPM60.COM master link (CPMV233-60K/CPM60.asm), which defines CPM60_LINK and
    owns those directives. A fresh disassembly emits them unguarded, so the 60K
    BIOS/BDOS regenerators re-apply this -- otherwise a regen would silently
    strip the guards and break the master build.

    Robust + idempotent: first STRIP every existing ``IFNDEF CPM60_LINK`` guard
    (as a pair with its directive and trailing ``ENDIF``), which also clears the
    lone *dangling* ``IFNDEF`` that ``splice_curated_header`` carries over from
    the old DEVICE guard (the block it re-injects ends just before ``DEVICE`` and
    so includes that ``IFNDEF`` but not its ``ENDIF``). Then re-wrap cleanly, so
    the result can never double-guard or leave a dangling ``IFNDEF`` (which under
    CPM60_LINK would skip the whole module body)."""
    raw = text.split("\n")
    norm, i = [], 0
    while i < len(raw):
        if raw[i].strip().startswith("IFNDEF CPM60_LINK"):
            i += 1                                       # drop the IFNDEF
            if i < len(raw):
                norm.append(raw[i]); i += 1              # keep the directive it guarded
                if i < len(raw) and raw[i].strip() == "ENDIF":
                    i += 1                               # drop the matching ENDIF
            continue
        norm.append(raw[i]); i += 1
    out = []
    for line in norm:
        m = _LINK_GUARD_RE.match(line)
        if m:
            ind = m.group(1)
            out.append(f"{ind}IFNDEF CPM60_LINK{_LINK_NOTE}")
            out.append(line)
            out.append(f"{ind}ENDIF")
        else:
            out.append(line)
    return "\n".join(out)


def _assemble_link_mode(module_text: str, run_org: int, length: int) -> bytes:
    """Assemble a module the way the CPM60.COM master INCLUDEs it -- with
    ``CPM60_LINK`` DEFINED, so the module's own DEVICE/ORG/SAVEBIN are guarded
    out and the wrapper supplies them. If the guards are wrong (e.g. a dangling
    ``IFNDEF``), the body is skipped and this returns too few / no bytes, so a
    byte-compare against the standalone build catches the breakage that the
    standalone check alone is blind to. Returns b"" on failure."""
    body = (f"    DEVICE NOSLOT64K\n    DEFINE CPM60_LINK\n    ORG ${run_org:04X}\n"
            + module_text +
            f'\n    SAVEBIN "linked.bin", ${run_org:04X}, ${length:04X}\n')
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        (td / "r.asm").write_text(body, encoding="utf-8")
        subprocess.run(["sjasmplus", "r.asm"], cwd=str(td), capture_output=True, text=True)
        out = td / "linked.bin"
        return out.read_bytes() if out.exists() else b""


def regenerate_60k_bios(*, write: bool = False, ai_names=None, extra_seeds=None) -> RegenResult:
    """Regenerate cpm-80/decompiled/CPMV233-60K/os/CPM_BIOS.asm byte-identical.

    Carries all curated inline labels + curated EQU symbols, seeds the BIOS jump
    table, and accepts `ai_names`/`extra_seeds` ({addr: name}) to plant new
    semantic names and trace previously-stranded routines as code. Returns a
    RegenResult; writes only when byte-identical.
    """
    old = _BIOS_60K.read_text(encoding="utf-8")
    bios = _assemble_savebin(old)
    if len(bios) != _BIOS_60K_LEN:
        return RegenResult(_BIOS_60K, False, 0, 0, 0, notes=["source did not reassemble"])
    mem = bytearray(0x10000)
    mem[_BIOS_60K_ORG:_BIOS_60K_ORG + _BIOS_60K_LEN] = bios

    seeds = set(bios_jump_table_seeds(mem, _BIOS_60K_ORG, _BIOS_60K_LEN)) | set(extra_seeds or {})
    force = _genuine_labels(old)
    force.update(ai_names or {})
    force.update(extra_seeds or {})

    equs = _curated_equs(old)
    ov_names = {a: nm for a, (nm, _c) in equs.items()}
    ov_comments = {a: c for a, (_nm, c) in equs.items() if c}
    import json
    ov = _SYM / "_60k_bios_overlay.json"
    ov.write_text(json.dumps(overlay_json(ov_names, comments=ov_comments)), encoding="utf-8")
    try:
        syms = _load_z80_syms(_SYM / "cpm_2_2.json", ov)
        src = disasm_z80_region(mem, _BIOS_60K_ORG, _BIOS_60K_LEN, symbols=syms,
                                seeds=sorted(seeds), source_name="", force_labels=force)
    finally:
        ov.unlink(missing_ok=True)
    src = src.replace("{out_bin}", "CPM_BIOS.bin")
    src = splice_curated_header(old, src)
    merged, mig, drop = migrate_comments(old, src)
    merged = _guard_link_directives(merged)      # keep the CPM60.COM master-link guards
    rebuilt = _assemble_savebin(merged)          # standalone (CPM60_LINK unset)
    linked = _assemble_link_mode(merged, _BIOS_60K_ORG, _BIOS_60K_LEN)  # as the master INCLUDEs it
    ok = rebuilt == bios and linked == bios
    if write and ok:
        _BIOS_60K.write_text(merged, encoding="utf-8")
    return RegenResult(_BIOS_60K, ok, mig, drop, len(force),
                       notes=[] if ok else ["NOT byte-identical -- not written"])

# (A former derive_booted_bios() applied a 185-entry "boot patch" table to the
# template. A code-grounded analysis showed that table conflated ~38 Z-80
# cold-boot SELF-modifications with ~147 bytes of post-boot dead-RAM reuse caught
# in a snapshot -- it was not a meaningful "running BIOS" and the 6502 loader does
# not patch the BIOS at all. It was removed; the real cold-boot self-mods are
# catalogued in decompiled/CPMV233-60K/BOOT_AND_PATCHING.md section 3c.)


# ── 60K BDOS recipe (CPMV233-60K) ──────────────────────────────────────
#
# The 60K BDOS is byte-identical to the CPM60.COM payload at COM offset 0x1700
# (the boot loader does NOT patch it; only the BIOS and CCP are patched). It was
# recovered after the dispatch upgrades, so -- unlike the BIOS -- it has no
# stranded code to recover; this recipe simply makes it reproducible/force-
# labelable while preserving its large hand-written bank-map header, which a
# fresh disassembly would discard.
_BDOS_60K = (_REPO / "cpm-80" / "decompiled" / "CPMV233-60K" / "os" / "CPM_BDOS.asm")
_BDOS_60K_ORG = 0xDC00
_BDOS_60K_LEN = 0x0E00

def _genuine_labels(text: str) -> dict[int, str]:
    """extract_semantic_labels minus localizer-derived locals.

    A local is any ``<head>_<n>`` (or the ``<head>_<n>_<hex>`` collision form)
    whose ``<head>`` is itself a label. These are minted by localize_labels, not
    curated, and are address-specific -- carrying one across a re-disassembly is
    unsafe: on a byte-shifted variant (the BIOS *template* vs the booted BIOS,
    185 bytes apart) a forced local can collide with a fresh operand target and
    break the round-trip. Only genuine heads transfer; locals are re-derived.
    Dropping them also keeps regeneration idempotent."""
    sem = extract_semantic_labels(text)
    names = set(sem.values())

    def derived(n):
        m = re.match(r"^(.+)_\d+(?:_[0-9A-Fa-f]{4})?$", n)
        return bool(m) and m.group(1) in names
    return {a: n for a, n in sem.items() if not derived(n)}


def splice_curated_header(old_text: str, new_text: str) -> str:
    """Re-inject the curated header block -- the hand-written prose the author
    placed between the generated ``; Range:`` line and the ``DEVICE`` directive
    (e.g. the 60K BDOS bank map) -- from `old_text` into a freshly disassembled
    `new_text`, which would otherwise emit only the generic preamble. Anchored on
    those two lines; if either is missing in either text, returns new_text as-is."""
    o = old_text.splitlines(keepends=True)
    n = new_text.splitlines(keepends=True)

    def idx(lines, pred):
        return next((i for i, l in enumerate(lines) if pred(l)), -1)
    o_rng = idx(o, lambda l: l.startswith("; Range:"))
    o_dev = idx(o, lambda l: l.lstrip().startswith("DEVICE"))
    n_rng = idx(n, lambda l: l.startswith("; Range:"))
    n_dev = idx(n, lambda l: l.lstrip().startswith("DEVICE"))
    if min(o_rng, o_dev, n_rng, n_dev) < 0 or o_dev <= o_rng:
        return new_text
    curated = o[o_rng + 1:o_dev]                 # block strictly between the anchors
    return "".join(n[:n_rng + 1] + curated + n[n_dev:])


def regenerate_60k_bdos(*, write: bool = False, ai_names=None, extra_seeds=None) -> RegenResult:
    """Regenerate cpm-80/decompiled/CPMV233-60K/os/CPM_BDOS.asm byte-identical.

    Seeds the primary entry (the ``JP`` at $DC06), carries genuine inline labels
    + curated EQU symbols, splices the curated bank-map header back in, and
    accepts `ai_names`/`extra_seeds`. Writes only when byte-identical.
    """
    old = _BDOS_60K.read_text(encoding="utf-8")
    bdos = _assemble_savebin(old)
    if len(bdos) != _BDOS_60K_LEN:
        return RegenResult(_BDOS_60K, False, 0, 0, 0, notes=["source did not reassemble"])
    mem = bytearray(0x10000)
    mem[_BDOS_60K_ORG:_BDOS_60K_ORG + _BDOS_60K_LEN] = bdos

    entry = mem[_BDOS_60K_ORG + 7] | (mem[_BDOS_60K_ORG + 8] << 8)   # JP target at $DC06
    seeds = {entry} | set(extra_seeds or {})
    force = _genuine_labels(old)
    force.update(ai_names or {})
    force.update(extra_seeds or {})

    equs = _curated_equs(old)
    ov_names = {a: nm for a, (nm, _c) in equs.items()}
    ov_comments = {a: c for a, (_nm, c) in equs.items() if c}
    import json
    ov = _SYM / "_60k_bdos_overlay.json"
    ov.write_text(json.dumps(overlay_json(ov_names, comments=ov_comments)), encoding="utf-8")
    try:
        syms = _load_z80_syms(_SYM / "cpm_2_2.json", ov)
        src = disasm_z80_region(mem, _BDOS_60K_ORG, _BDOS_60K_LEN, symbols=syms,
                                seeds=sorted(seeds), source_name="CPM_BDOS", force_labels=force)
    finally:
        ov.unlink(missing_ok=True)
    src = src.replace("{out_bin}", "CPM_BDOS.bin")
    src = splice_curated_header(old, src)
    merged, mig, drop = migrate_comments(old, src)
    merged = _guard_link_directives(merged)      # keep the CPM60.COM master-link guards
    rebuilt = _assemble_savebin(merged)          # standalone (CPM60_LINK unset)
    linked = _assemble_link_mode(merged, _BDOS_60K_ORG, _BDOS_60K_LEN)  # as the master INCLUDEs it
    ok = rebuilt == bdos and linked == bdos
    if write and ok:
        _BDOS_60K.write_text(merged, encoding="utf-8")
    return RegenResult(_BDOS_60K, ok, mig, drop, len(force),
                       notes=[] if ok else ["NOT byte-identical -- not written"])
