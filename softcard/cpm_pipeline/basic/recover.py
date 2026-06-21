"""Recover code the walker missed -- regions left as DEFB/DEFW data that are actually
reachable code (fragmented by false pointer-cell classification, or reached via a
computed path). Such a blob is NOT benign: any address operand inside it is frozen as
a hex DEFB byte and will NOT relocate, breaking the fold.

Recovery is conservative and LOCAL: it only extends code by FALL-THROUGH -- the byte
immediately after a confirmed non-terminal instruction -- and only when that byte
begins a clean instruction stream that reaches a terminal. The recovered run is marked
linearly (no control-flow recursion), so it can never wander into a string / pointer
table / FP constant the way `walker.trace` would. Iterates, so a routine split into
pieces by false DEFW cells is rejoined one fall-through at a time. Byte-identical
(re-classification only)."""
from disasm_z80.opcodes import decode_at, ControlFlow

# Instructions after which execution does NOT fall through to the next byte.
_NONFALL = (ControlFlow.JUMP_ABS, ControlFlow.RET, ControlFlow.HALT, ControlFlow.INDIRECT)
_TERMINAL = (ControlFlow.JUMP_ABS, ControlFlow.RET, ControlFlow.HALT)


# Absolute control-flow targets in real code land inside the program image; an
# out-of-range JP/CALL means the bytes are data decoding as bogus code (e.g. an FP
# constant $CC,$CC,... -> CALL $CCCC). (Externals like $E0xx/$F3xx are reached via
# RPC / register loads, never a direct JP/CALL, so this does not reject real code.)
_CODE_LO, _CODE_HI = 0x0100, 0x84FF
_ABS_CF = (ControlFlow.JUMP_ABS, ControlFlow.JUMP_CC, ControlFlow.CALL, ControlFlow.CALL_CC)


def _clean_end(mem, a, hi, maxn=512, minn=2):
    """If [a..) decodes as a clean instruction stream of at least `minn` instructions
    reaching a terminal, with every absolute JP/CALL target inside the program image,
    return the end address (exclusive); else None (so genuine data decoding as bogus
    code -- an FP constant, or a dispatch byte like $D8=RET C -- is rejected)."""
    b, n = a, 0
    while b < hi and n < maxn:
        try:
            ins = decode_at(mem, b)
        except (IndexError, KeyError):
            return None
        if ins.size == 0:
            return None
        if (ins.control_flow in _ABS_CF and ins.target is not None
                and not (_CODE_LO <= ins.target <= _CODE_HI)):
            return None
        n += 1
        b += ins.size
        if ins.control_flow in _TERMINAL:
            return b if n >= minn else None
    return None


def recover_code(walker, mem, lo, hi, max_iter=200):
    """Linearly recover fall-through code missed in [lo, hi). Returns bytes added."""
    added = 0
    for _ in range(max_iter):
        changed = False
        a = lo
        while a < hi:
            if a not in walker.code:
                a += 1
                continue
            try:
                ins = decode_at(mem, a)
            except (IndexError, KeyError):
                a += 1
                continue
            sz = ins.size or 1
            nxt = a + sz
            # Recover the run after ANY confirmed instruction: a non-terminal falls
            # through (certainly code); after a terminal (JP/RET) the next bytes are
            # often the next routine reached only by a computed jump (e.g. the CRUNCH
            # matcher after JP CRUNCH_6). Both are gated on a clean decode to a terminal.
            # Recover even across a data-region: passes like dispatch resolution can
            # falsely mark a routine as data; _clean_end's in-range-target + min-length
            # checks reject genuine data, so the strong validator is the safe gate.
            # EXCEPT inline-byte operands (e.g. SYNCHR's expected char): those are
            # genuinely data the preceding CALL consumes -- recovering them would
            # re-create the phantom-instruction cascade. Always respect them.
            if (nxt < hi and nxt not in walker.code
                    and nxt not in getattr(walker, "inline_data", {})):
                end = _clean_end(mem, nxt, hi)
                if end is not None:
                    for x in range(nxt, end):
                        walker.code.add(x)
                    added += end - nxt
                    changed = True
                    a = end
                    continue
            a = nxt
        if not changed:
            break
    return added
