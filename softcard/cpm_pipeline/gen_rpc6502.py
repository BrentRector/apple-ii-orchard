"""Generate CPM_RPC6502.s -- the embedded 6502 RPC block as its own ca65 source.

The 2.20 CCP carries a 257-byte 6502 machine-code payload at Z-80 $9400-$9500
(the SoftCard runs it on the 6502 side via the CPU switch; from the Z-80's view
it is opaque data). Rather than bury it as a DEFB blob inside the Z-80
SystemImage, we disassemble it as real 6502 and assemble it separately with
ca65; the Z-80 SystemImage then INCBINs the byte-identical binary and references
its entry points as ``L_9400 + offset`` (so they relocate with ORG).

The block is position-independent (every internal reference is to a fixed low
Apple address; branches are relative), so the SAME bytes serve 44K ($9400) and
56K ($C400). Exactly ONE byte is config-dependent: $94AE, the high byte of the
warm-boot disk-load buffer ($A400 in 44K, $E400 in 56K) -- emitted here as
``#>$A400`` / ``#>$E400`` under ``CFG_56K`` so each config assembles correctly.

This module is the single recipe; a regression test reassembles its output and
checks it byte-identical to the on-disk block (both configs).
"""
from __future__ import annotations

import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO / "shared"))

from disasm6502.walker import Walker
from disasm6502.formatter import Ca65Formatter
from disasm6502.opcodes import OPCODES

# Block geometry (Z-80 addresses; the block is at staging offset $0100..$0201).
BLOCK_START, BLOCK_END = 0x9400, 0x9501
# Genuine data sub-regions inside the block (never decode as code):
#   $9488-$948B  two 16-bit cells the Z-80 reads/writes (L_9488 / L_948A)
#   $949D-$94AC  the standard CP/M 16-sector skew table
#   $94FD-$9500  trailing $FF,$FF,$FF,$00 pad after the final RTS
DATA_SUBREGIONS = [(0x9488, 0x948C), (0x949D, 0x94AD), (0x94FD, 0x9501)]
# 6502 entry points: $9400 (run via JP (HL)) + every Z-80 CALL/JP target into
# the block that lands on real code, plus $94AD (the warm-boot reload setup,
# reached from outside the trace). $94A2/$94A7/$94FE are Z-80 references that
# land inside data (skew table / pad) -- not code entries, so omitted here.
ENTRIES = [0x9400, 0x948C, 0x9492, 0x9498, 0x94AD, 0x94B8, 0x94BD,
           0x94D0, 0x94DA, 0x94E4, 0x94E9, 0x94EF]

OUT_S = _REPO / "softcard" / "CPMV220-44K" / "os" / "CPM_RPC6502.s"

# Semantic names for the 6502 CODE in the block (proposed by an AI review grounded
# in the captured Microsoft manuals: the manuals call this "CP/M sector read and
# write routines", use "retry"/"warm boot"/"bootstrap loader"). These describe
# what the 6502 code DOES and are byte-identical (labels are zero-width). Only
# routines reached by COHERENT 6502 control flow are named; purely-internal branch
# targets stay auto (L_xxxx). NOTE: the Z-80 side CALLs several of these addresses
# (e.g. $9498, $948C) but lands mid-6502-instruction or in the skew table -- that
# Z-80->6502 DISPATCH is NOT yet understood (see header note), so we do not assert
# those are clean entry points.
NAMES = {
    0x9400: "SECTOR_RW",          # block base (run via JP(HL)); DEC retry, re-enter $0F3E
    0x940E: "SECTOR_MATCH",       # skew sector via $0F9D,Y; compare addr-field $2D
    0x943A: "DRIVE_MOTOR_ON",     # LDA $C088,X (Disk II motor/drive soft switch)
    0x945A: "SECTOR_XFER_BYTE",   # move a byte between buffer halves $0478/$04F8
    0x947D: "SLOT_TO_INDEX",      # TXA; 4x LSR; TAY  (slot*16 -> index)
    0x9484: "SECTOR_MOVE",        # self-modified mover; the Z-80 plants its operand
    # $9488/$948A are the two 16-bit self-mod cells the Z-80 writes into SECTOR_MOVE
    # (LD HL,(L_9488) etc.); left auto-named (L_9488/L_948A) -- the self-mod path
    # tied to the un-understood Z-80 dispatch, so not asserting a firm name.
    0x949D: "SECTOR_XLATE_TABLE", # 16-byte CP/M logical->physical sector table
    0x94AD: "WBOOT_LOAD",         # warm-boot reload: set load buffer, slot 6, loop
    0x94CD: "WBOOT_READ_SECTOR",  # per-sector read loop body (JSR $0E10)
    0x94DA: "WBOOT_ERR_MONITOR",  # read error -> $FF2D monitor, JMP $0FAD
    0x94DD: "WBOOT_NEXT_SECTOR",  # advance buffer page / sector / track
}


def _block_bytes() -> bytes:
    from .reference_data import INVEST
    sysimg = (INVEST / "sysimg_220_44k.bin").read_bytes()   # loads at $9300
    return sysimg[BLOCK_START - 0x9300:BLOCK_END - 0x9300]


def _trace_code(mem) -> set[int]:
    w = Walker(mem, start=BLOCK_START, end=BLOCK_END)
    for s, e in DATA_SUBREGIONS:
        w.add_data_region(s, e)
    for e in ENTRIES:
        w.trace(e)
    # after-terminal sweep: a routine reached only from outside the block still
    # sits right after a JMP/RTS/RTI/BRK we did trace.
    changed = True
    while changed:
        changed = False
        for a in sorted(w.code):
            ent = OPCODES.get(mem[a])
            if not ent:
                continue
            mn, _, size = ent
            if mn in ("JMP", "RTS", "RTI", "BRK"):
                nx = a + size
                if (BLOCK_START <= nx < BLOCK_END and nx not in w.code
                        and not w.in_data_region(nx)):
                    before = len(w.code)
                    w.trace(nx)
                    if len(w.code) > before:
                        changed = True
    return w


_HEADER = """\
; ============================================================================
; CPM_RPC6502.s -- embedded 6502 RPC block of SoftCard CP/M 2.20 (44K)
; ----------------------------------------------------------------------------
; 257 bytes that live at Z-80 $9400-$9500 inside the CCP. The SoftCard runs
; them on the 6502 via the CPU switch; from the Z-80 they are opaque data, so
; the Z-80 SystemImage INCBINs the assembled binary of THIS file and references
; the entry points below as L_9400 + offset (which relocate with ORG).
;
; The block is position-independent (all internal refs are fixed low Apple
; addresses: I/O-config cells $03E0-$03EB, the slot-ROM page $C088,X, monitor
; $FF2D, RWTS helpers $0A25/$0B00/$0BC6/$0BDE/$0E10/$0F3E/$0F5A/$0F7D/$0FAD; all
; branches relative). The SAME bytes serve 44K and 56K -- EXCEPT one byte:
;   $94AE = high byte of the warm-boot disk-load buffer ($A400 44K / $E400 56K),
;           emitted as #>$A400 / #>$E400 under CFG_56K.
;
; What it does (warm-boot / RPC disk service, by routine):
;   $9400  decrement retry counter, restore A/flags, JMP $0F3E (RWTS entry)
;   $940E  match requested sector against the address field (skew via $0F9D,Y)
;   $943A  set up the drive: motor on ($C088,X), clear flags
;   $945A  read/write the sector data buffer ($0478 / $04F8 banked by bit-7 of $35)
;   $9484  (self-modified via cells $9488/$948A) sector-data mover
;   $94AD  warm-boot reload: point the load buffer at $A400 (44K)/$E400 (56K),
;          slot 6, loop reading sectors via $0E10, advancing the buffer page
;
; OPEN QUESTION -- the Z-80->6502 dispatch is NOT understood. The Z-80 CCP/BDOS
; CALLs several addresses in this block (e.g. CALL $9498, CALL $948C), but those
; land mid-6502-instruction or inside the skew table, not on 6502 routine starts.
; So "the Z-80 CALL target is a 6502 run-address" is WRONG, and a simple
; "address = RPC selector" was a hand-wave. How a Z-80 CALL into $94xx actually
; reaches/selects this 6502 service is unresolved (the SoftCard CPU-switch detail).
; The 6502 CODE here is coherent and named accordingly; the Z-80-side entry
; symbols (CPM_SystemImage.asm SUB_94xx EQUs) are kept verbatim, NOT semantically
; named, pending that investigation.
;
; Clean-room decompile; comments are [AI] inference unless tagged otherwise.
; Reassembles BYTE-IDENTICAL to the on-disk block (see test_rpc6502_build).
; ============================================================================
"""


def generate() -> str:
    """Return the final CPM_RPC6502.s text (config-conditional $94AE)."""
    mem = bytearray(0x10000)
    blk = _block_bytes()
    mem[BLOCK_START:BLOCK_END] = blk
    w = _trace_code(mem)
    for addr, name in NAMES.items():       # semantic names for the 6502 code
        w.labels[addr] = name
    w.name_labels()
    fmt = Ca65Formatter(mem, w, None, origin=BLOCK_START,
                        length=BLOCK_END - BLOCK_START, source_name="CPM_RPC6502")
    body = fmt.emit_source()
    # Strip the generator preamble (we supply our own header) up to `.org`.
    lines = body.splitlines()
    org_i = next(i for i, l in enumerate(lines) if l.strip().startswith(".org"))
    body_lines = lines[org_i:]
    # Replace the `LDA #$A4` at $94AD with a config-conditional load of the
    # warm-boot buffer high byte.
    out = []
    for l in body_lines:
        if "; $94AD" in l and "LDA" in l.upper():
            indent = l[:len(l) - len(l.lstrip())]
            out.append(f"{indent}.ifdef CFG_56K")
            out.append(f"{indent}    lda     #>$E400          ; $94AD  warm-boot load buffer hi (56K)")
            out.append(f"{indent}.else")
            out.append(f"{indent}    lda     #>$A400          ; $94AD  warm-boot load buffer hi (44K)")
            out.append(f"{indent}.endif")
        else:
            # Symbolize the one Apple Monitor ROM call in this block ($FF2D =
            # PRERR). "$FF2D" and "PRERR" are both 5 chars, so column alignment
            # (and the assembled bytes) are unchanged.
            if "JSR $FF2D" in l:
                l = l.replace("$FF2D", "PRERR")
            out.append(l)
    equs = ("PRERR           = $FF2D         "
            "; Apple II Monitor: print \"ERR\" + bell\n\n")
    return (_HEADER + ".setcpu \"6502\"\n.segment \"CODE\"\n\n"
            + equs + "\n".join(out) + "\n")


def write() -> Path:
    OUT_S.write_text(generate(), encoding="utf-8")
    return OUT_S


if __name__ == "__main__":
    p = write()
    print("wrote", p)
