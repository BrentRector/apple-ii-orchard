"""Generate CPM_RPC6502_Restart.s -- the SECOND embedded 6502 block as its own
ca65 source (the $9600-$9700 cold-restart / RPC service of the 2.20-44K CCP).

Sibling recipe to ``gen_rpc6502`` (the $9400 disk-service block). The 2.20 CCP
carries a 257-byte 6502 machine-code payload at Z-80 $9600-$9700; the SoftCard
runs it on the 6502 side via the CPU switch, so from the Z-80's view it is
opaque data. Rather than leave it mis-decoded as Z-80 inside CPM_CCP.asm we
disassemble it as real 6502 and assemble it separately with ca65; the Z-80 image
then INCBINs the byte-identical binary and references its Z-80-visible entry
points as ``RPC_RESTART_BLOCK + offset`` (so they relocate with ORG).

The block is position-independent (every internal reference is to a fixed low
Apple/monitor/soft-switch address; branches are relative), so ``.org $9600`` is
presentation only.

This module is the single recipe; a regression test reassembles its output and
checks it byte-identical to the on-disk block (test_rpc6502_restart).
"""
from __future__ import annotations

import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO / "shared"))

from disasm6502.walker import Walker
from disasm6502.formatter import Ca65Formatter

# Block geometry (Z-80 addresses; the block is at staging offset $0300..$0401).
BLOCK_START, BLOCK_END = 0x9600, 0x9701

# Single entry: $9600. The block is fully covered as code from this one entry
# (recursive trace -> all 257 bytes, ZERO illegal opcodes, every branch lands on
# an instruction boundary). No data sub-regions.
ENTRIES = [0x9600]

OUT_S = _REPO / "softcard" / "CPMV220-44K" / "os" / "CPM_RPC6502_Restart.s"

# Semantic names for the coherent 6502 CODE (OBSERVED control flow; labels are
# zero-width so byte-identity is unaffected). Only routine heads reached by
# coherent 6502 flow are named; purely-internal branch targets stay auto.
NAMES = {
    0x9600: "RPC_RESTART_9600",   # block base (run via the CPU switch)
    0x9628: "SIGNON_COUT_LOOP",   # COUT a $00-string from $114A then JMP MONZ
    0x9636: "COLD_RESTART",       # copy loader blocks, slot scan, BIOS handoff
    0x9638: "COPY_1168_0FFF",     # copy $1168->$0FFF (page 0 image)
    0x9641: "COPY_1200_0200",     # copy $1200->$0200
    0x964c: "COPY_12FF_02FF",     # copy $12FF->$02FF
    0x965f: "SLOT_SCAN_LOOP",     # per-slot card-type scan loop top (JSR $1180)
    0x9697: "CARD_TYPE_MATCH",    # compare slot signature vs $1176,X / $117A,X
    0x96b6: "SLOT_TYPE_RECORD",   # record per-slot type at $02F8,Y; loop
    0x96d9: "LC_COUT_LOOP",       # COUT a $00-string from $112B then JMP MONZ
    0x96e7: "BIOS_HANDOFF",       # copy $13EF->$03EF, build Z-80 handoff at $1000
}


def _block_bytes() -> bytes:
    from .reference_data import INVEST
    sysimg = (INVEST / "sysimg_220_44k.bin").read_bytes()   # loads at $9300
    return sysimg[BLOCK_START - 0x9300:BLOCK_END - 0x9300]


def _trace_code(mem) -> Walker:
    w = Walker(mem, start=BLOCK_START, end=BLOCK_END)
    for e in ENTRIES:
        w.trace(e)
    return w


_HEADER = """\
; ============================================================================
; CPM_RPC6502_Restart.s -- embedded 6502 COLD-RESTART / RPC service of
; SoftCard CP/M 2.20 (44K). 257 bytes at Z-80 $9600-$9700 inside the CCP.
; The SoftCard runs them on the 6502 via the CPU switch; from the Z-80 they
; are opaque data, so CPM_CCP.asm INCBINs the assembled binary of THIS file
; and references its Z-80-visible entry points as RPC_RESTART_BLOCK + offset
; (which relocate with ORG). Sibling to CPM_RPC6502.s ($9400 block).
;
; What it does (OBSERVED): LC RAM write-enable; drive motor off; clear sector
; cells $0478/$04F8; Apple monitor console init (SETTXT/SETVID/SETKBD); reset
; 6502 stack; CMP #$06 -> either COUT a $00-string then JMP $FF65 (MONZ), or
; the full cold restart: copy loader blocks ($1168->$0FFF, $1200->$0200,
; $12FF->$02FF, $13EF->$03EF), slot/card-type scan (JSR $1180/$1117 vs
; $1176,X/$117A,X) writing slot-config cells $03B8/$03C7/$03C8/$03DE/$03DF and
; per-slot types $02F8,Y, then build the Z-80 BIOS handoff at $1000.
; [DOC S&HD 2-24/2-25 ; facts sec.4] CPU switch / 6502-RPC mechanism.
;
; OPEN QUESTION (shared with CPM_RPC6502.s): how a Z-80 CALL/JP into $96xx
; SELECTS this 6502 service is NOT understood -- several Z-80 reference targets
; ($9659/$965E/$9690/$96A9/$96B9/$96C0/$96C8/$96DB/$96DF/$96E9) land
; MID-6502-INSTRUCTION, so they are not 6502 routine starts. Kept as
; RPC_RESTART_BLOCK + offset literals, NOT semantically named.
;
; [RE] $96FE STA $0902: operand high byte is $09, not the $10 the "STA $1002"
; intent (completing JMP $AA00 = C3 00 AA at $1000-$1002) would imply. UNKNOWN;
; preserved verbatim. Clean-room decompile; comments [AI] unless tagged.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502_restart).
; ============================================================================
"""

# Apple Monitor / soft-switch symbols. Symbolizing the operand is byte-identical
# (the assembled bytes are unchanged); ca65 column alignment is cosmetic.
_EQUS = (
    "SETTXT  = $FB2F                 ; Apple II Monitor: select text mode\n"
    "SETVID  = $FE93                 ; Apple II Monitor: reset output hook -> screen\n"
    "SETKBD  = $FE89                 ; Apple II Monitor: reset input hook -> keyboard\n"
    "COUT    = $FDED                 ; Apple II Monitor: output a character\n"
    "MONZ    = $FF65                 ; Apple II Monitor: cold entry (Monitor prompt)\n"
)

# Operand text -> EQU name substitutions (literal and symbol resolve to the same
# bytes; this only changes the printed operand, never the encoding).
_SYM_SUBST = {
    "JSR $FB2F": "JSR SETTXT",
    "JSR $FE93": "JSR SETVID",
    "JSR $FE89": "JSR SETKBD",
    "JSR $FDED": "JSR COUT",
    "JMP $FF65": "JMP MONZ",
}


def generate() -> str:
    """Return the final CPM_RPC6502_Restart.s text."""
    mem = bytearray(0x10000)
    blk = _block_bytes()
    mem[BLOCK_START:BLOCK_END] = blk
    w = _trace_code(mem)
    for addr, name in NAMES.items():       # semantic names for the 6502 code
        w.labels[addr] = name
    w.name_labels()
    fmt = Ca65Formatter(mem, w, None, origin=BLOCK_START,
                        length=BLOCK_END - BLOCK_START,
                        source_name="CPM_RPC6502_Restart")
    body = fmt.emit_source()
    # Strip the generator preamble (we supply our own header) up to `.org`.
    lines = body.splitlines()
    org_i = next(i for i, l in enumerate(lines) if l.strip().startswith(".org"))
    body_lines = lines[org_i:]
    out = []
    for l in body_lines:
        for lit, sym in _SYM_SUBST.items():
            if lit in l:
                l = l.replace(lit, sym, 1)
                break
        out.append(l)
    return (_HEADER + ".setcpu \"6502\"\n.segment \"CODE\"\n\n"
            + _EQUS + "\n" + "\n".join(out) + "\n")


def write() -> Path:
    OUT_S.write_text(generate(), encoding="utf-8")
    return OUT_S


if __name__ == "__main__":
    p = write()
    print("wrote", p)
