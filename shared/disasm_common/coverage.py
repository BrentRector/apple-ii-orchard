"""Coverage maximization: grow a walker's code set past pure recursive descent.

Recursive-descent disassembly only reaches code that is the target of a *static*
branch/call from an entry point. Real OS images leave a lot unreached:

  * routines reached only through a **computed dispatch** (``JP (HL)`` over a
    function table -- CP/M's BDOS, a CCP command table);
  * routines reached only through a **page-zero indirection** (CP/M code calls
    BDOS via ``CALL 5``; the handler is never named by a static CALL inside the
    module);
  * densely packed routines that simply **fall after a terminal** with nothing
    statically pointing at them in-range.

Those unreached bytes get dumped as ``DEFB``/``.byte`` even though they are code.
This pass grows coverage with three high-precision, byte-identity-preserving
strategies, iterated to a fixpoint:

  1. **dispatch resolution** (Z-80 only) -- resolve computed-jump tables via the
     dataflow analyzer and seed their targets;
  2. **table-target harvesting** -- seed the targets of any jump/pointer table the
     data classifier recognises;
  3. **validated after-terminal sweep** -- for each remaining non-code gap, accept
     it as code only if it decodes cleanly (all valid opcodes, no run-off past the
     gap) into a block that reaches a terminal instruction; then trace it so its
     own branches are followed too.

Strategy 3 is a heuristic, so it is *validated* (clean decode to a terminal) to
keep false positives low; it never changes bytes (the formatter still reproduces
the image exactly), only the code/data split. It is opt-in (the CLIs expose it as
``--auto-coverage``) so default disassembly stays purely descent-based.
"""

from __future__ import annotations

from .analyzer import classify_data, DataKind


# Data the classifier recognises with structure -- the sweep must never grab
# these as code (a $00-terminated message or a referenced command name decodes
# as perfectly valid instructions, but it is text, not code).
_STRUCTURED = {DataKind.STRING, DataKind.FILL,
               DataKind.JUMP_TABLE, DataKind.POINTER_TABLE}


def maximize_coverage(walker, mem, *, cpu, decoder, scan_dispatch=None,
                      harvest_refs=None, max_rounds=25, min_block=2, sweep=True):
    """Iteratively enlarge ``walker.code`` in place; return the walker.

    Args:
        walker:        a Walker already seeded with its entry traces.
        mem:           the 64K memory image.
        cpu:           'z80' or '6502' (selects the data classifier's jump-opcode set).
        decoder:       callable(addr) -> (size, is_terminal). size 0 == undecodable
                       (stops a sweep); is_terminal marks RET/JP/JMP/HALT-class
                       instructions that legitimately end a block.
        scan_dispatch: optional callable(walker) -> iterable of DispatchTable
                       (Z-80 computed-jump resolution); None to skip.
        harvest_refs:  optional callable(walker) -> bool that labels in-range data
                       addresses the code references and returns True if it added
                       any. Run before the sweep so referenced strings/tables are
                       recognised (and therefore protected) rather than swept.
        max_rounds:    fixpoint safety cap.
        min_block:     minimum instruction count for a swept gap to count as code.
        sweep:         enable the validated after-terminal linear sweep.
    """
    org, end = walker.start, walker.end

    # String/fill runs are protected as walls: registered as walker data regions
    # so no trace (descent or sweep) can flow through them, and a swept block may
    # not cross one. A string is referenced data the program prints; it decodes
    # as valid instructions but is never executed.
    walled = set()

    def wall(run_addr, run_end):
        if (run_addr, run_end) not in walled:
            walled.add((run_addr, run_end))
            walker.add_data_region(run_addr, run_end)

    def block_ok(start):
        """True if [start, ...) decodes cleanly to a terminal within the gap
        without crossing a protected (string/fill) data region."""
        a, n = start, 0
        while a < end:
            if walker.in_data_region(a):
                return False
            size, terminal = decoder(a)
            if not size or a + size > end:
                return False
            if any(walker.in_data_region(a + i) for i in range(1, size)):
                return False
            n += 1
            if terminal:
                return n >= min_block
            a += size
        return False

    def vouched(start, core):
        """A gap start is credible as a routine head only if something points at
        it (a walker label) or it falls right after a terminal instruction that is
        CORE code -- recursive-descent / dispatch / table-confirmed, never another
        swept block. Requiring the fall-through anchor to be core breaks the
        cascade where a data run that happens to end in $C9 (RET) would vouch the
        next data run, marching the sweep straight through a table."""
        if walker.labels.get(start) is not None:
            return True
        for back in range(1, 4):
            s = start - back
            if s < org or s not in core:
                continue
            size, terminal = decoder(s)
            if size and s + size == start and terminal:
                return True
        return False

    def seed_round():
        """Label code-referenced data, resolve dispatch tables, and harvest
        jump/pointer-table targets (the high-confidence growers). Returns
        (grew, structured) where `structured` is the byte set the data
        classifier recognised as string/fill/table -- regions the sweep must
        leave alone."""
        grew = False
        if harvest_refs is not None and harvest_refs(walker):
            grew = True
        if scan_dispatch is not None:
            for t in scan_dispatch(walker):
                for tg in t.entry_targets:
                    if org <= tg < end and tg not in walker.code:
                        walker.trace(tg)
                        grew = True
        runs = classify_data(mem, org, end, code_set=walker.code,
                             labels=walker.labels, cpu=cpu,
                             body_start=org, body_end=end)
        structured = set()
        for r in runs:
            if r.kind in _STRUCTURED:
                structured.update(range(r.addr, r.end))
            # Protect text/fill as walls so no trace flows through them.
            if r.kind in (DataKind.STRING, DataKind.FILL):
                wall(r.addr, r.end)
            if r.kind in (DataKind.JUMP_TABLE, DataKind.POINTER_TABLE):
                for tg in r.metadata.get("targets", ()):
                    if org <= tg < end and tg not in walker.code:
                        walker.trace(tg)
                        grew = True
        return grew, structured

    # Phase 1: grow the CORE (descent already done by caller; add dispatch +
    # table targets + reference labels) to a fixpoint with no heuristic sweep.
    structured = set()
    for _ in range(max_rounds):
        grew, structured = seed_round()
        if not grew:
            break
    core = set(walker.code)

    # Phase 2: validated, core-anchored after-terminal sweep, interleaved with
    # further seeding. Swept blocks never extend the core anchor set (no cascade
    # through data), and a gap the classifier recognised as a string/fill/table
    # is never swept (text decodes as valid code, but it is not code).
    if sweep:
        for _ in range(max_rounds):
            changed, structured = seed_round()
            a = org
            while a < end:
                if a in walker.code:
                    a += 1
                    continue
                gap_start = a
                while a < end and a not in walker.code:
                    a += 1
                if gap_start in structured:
                    continue
                if vouched(gap_start, core) and block_ok(gap_start):
                    before = len(walker.code)
                    walker.trace(gap_start)
                    if len(walker.code) > before:
                        changed = True
            if not changed:
                break
    return walker


def z80_decoder(mem):
    """Return a decoder(addr) -> (size, is_terminal) for the Z-80."""
    from disasm_z80.opcodes import decode_at, ControlFlow
    terminals = {ControlFlow.RET, ControlFlow.JUMP_ABS,
                 ControlFlow.INDIRECT, ControlFlow.HALT}

    def decode(addr):
        try:
            ins = decode_at(mem, addr)
        except (IndexError, KeyError):
            return (0, False)
        return (ins.size, ins.control_flow in terminals)
    return decode


def m6502_decoder(mem):
    """Return a decoder(addr) -> (size, is_terminal) for the 6502."""
    from disasm6502.opcodes import OPCODES, UNDOC_MNEMONICS

    def decode(addr):
        op = mem[addr]
        spec = OPCODES.get(op)
        if spec is None:
            return (0, False)
        mnem, mode, size = spec
        if mnem in UNDOC_MNEMONICS:
            return (0, False)
        if mnem == "NOP" and op != 0xEA:
            return (0, False)
        terminal = mnem in ("RTS", "RTI", "BRK", "JMP")
        return (size, terminal)
    return decode


def z80_dispatch_scanner(mem, org, end):
    """Return scan_dispatch(walker) using the Z-80 dataflow resolver."""
    from disasm_z80 import dataflow

    def scan(walker):
        return dataflow.scan_static_dispatch(mem, walker, body_start=org, body_end=end)
    return scan


def z80_ref_harvester(mem, org, end):
    """Return harvest_refs(walker): label in-range data addresses referenced by a
    Z-80 16-bit operand. Returns True if any new label was added."""
    import re
    from disasm_z80.opcodes import decode_at
    hexlit = re.compile(r"\$([0-9A-Fa-f]{4})")

    def harvest(walker):
        added = False
        a = org
        while a < end:
            if a in walker.code:
                try:
                    ins = decode_at(mem, a)
                except (IndexError, KeyError):
                    a += 1
                    continue
                for m in hexlit.finditer(ins.mnemonic):
                    v = int(m.group(1), 16)
                    if org <= v < end and v not in walker.code \
                            and walker.labels.get(v) is None:
                        walker.add_label(v)
                        added = True
                a += ins.size or 1
            else:
                a += 1
        if added:
            walker.name_labels()
        return added
    return harvest


def m6502_ref_harvester(mem, org, end):
    """Return harvest_refs(walker): label in-range data addresses referenced by a
    6502 absolute operand (ABS/ABX/ABY/IND). Returns True if any new label added."""
    from disasm6502.opcodes import OPCODES

    def harvest(walker):
        added = False
        a = org
        while a < end:
            if a in walker.code:
                op = mem[a]
                spec = OPCODES.get(op)
                if spec is None:
                    a += 1
                    continue
                mnem, mode, size = spec
                if mode in ("ABS", "ABX", "ABY", "IND"):
                    v = mem[a + 1] | (mem[a + 2] << 8)
                    if org <= v < end and v not in walker.code \
                            and walker.labels.get(v) is None:
                        walker.add_label(v)
                        added = True
                a += size if size > 0 else 1
            else:
                a += 1
        if added:
            walker.name_labels()
        return added
    return harvest
