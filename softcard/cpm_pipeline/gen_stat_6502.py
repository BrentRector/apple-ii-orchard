"""Generate STAT_6502.s -- the stale 6502 work-buffer tail of STAT.COM (2.20 44K).

STAT.COM is a Z-80 program. Its tail ($15BD-$18FF in the loaded image) is NOT
Z-80 code or live data: nothing in STAT references it (STAT's last referenced
scratch variable is FILE_SORTKEY_TBL at $15BC; nothing touches $15BD or beyond).
It is leftover content of the cross-assembler's work buffer -- the uninitialised
top of STAT's BSS, captured when the .COM was SAVEd. That leftover content has two
clearly-recognisable parts:

  * $15BD-$15FF  a fragment of assembled 6502 OBJECT CODE (a Disk II denibble /
                 16-bit-add helper: LDA #$03 / STA $8F / ... / JMP $1D59, plus an
                 ($5E),Y read+add loop). Being a fragment, its last few bytes are
                 partial instructions / buffer noise.
  * $1600-$18FF  the 6502 ASSEMBLY-SOURCE LISTING of a Disk II seek/read driver,
                 stored as high-bit ($80-set) Apple text, one source line per
                 $8D (carriage-return) terminator: "SAMEDRV LDA A.TRK",
                 "JSR MYSEEK", "TRYTRK ... RDADR ... SETTRK ... RETRYCNT", etc.

Both run on the 6502 conceptually (the SoftCard CPU switch), so from the Z-80 they
are opaque data -- exactly the cross-CPU situation the COPY/CPM56 utilities handle
by extracting the 6502 payload to its own ca65 source and INCBINing it back. This
module is that extractor for STAT: it disassembles the object fragment as real
6502 instructions and renders the source-listing text as readable strings (via a
ca65 .charmap that maps printable ASCII -> its high-bit Apple form), so the file is
self-documenting yet reassembles byte-identical. STAT.asm INCBINs the result.

Because nothing references the block, NO cross-CPU EQUs are needed (the live Z-80
scratch variables all sit BELOW $15BD and stay as Z-80 DEFB in STAT.asm). The block
is a captured buffer, NOT relocated by STAT, so it is disassembled in place at its
load address ($15BD); the absolute operands ($1D10/$1D1A/$1D59 etc.) are the
literal bytes and are emitted as-is.

A regression test (cpm_pipeline test_utilities_roundtrip, STAT case) reassembles
STAT.asm -- which sub-assembles this file -- and checks it byte-identical to the
on-disk STAT.COM.
"""
from __future__ import annotations

import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO / "shared"))

from disasm6502.opcodes import OPCODES  # noqa: E402

# Block geometry: STAT.COM loads at $0100; the unreferenced stale tail is
# $15BD-$18FF (everything above STAT's last live scratch variable at $15BC).
BLOCK_START = 0x15BD
CODE_END = 0x1600          # 6502 object fragment: $15BD-$15FF
BLOCK_END = 0x1900         # text listing: $1600-$18FF (exclusive end)

# ca65 with `.setcpu "6502"` rejects undocumented opcodes; emit those (and any
# byte that would decode into the next region) as `.byte`. RRA ($6F) and the
# "NOP #imm" forms ($80/$82/$89/$C2/$E2) are the undocumented ones present here.
_UNDOC = {0x6F, 0x80, 0x82, 0x89, 0xC2, 0xE2}

OUT_S = _REPO / "softcard" / "CPMV220-44K" / "utilities" / "STAT_6502.s"
OUT_CFG = OUT_S.with_suffix(".cfg")


def _com_bytes() -> bytes:
    from .filesystem import read_disk, extract_file
    from .reference_data import DISK_2_20_44K_SYSTEM
    return bytes(extract_file(read_disk(Path(DISK_2_20_44K_SYSTEM)), "STAT.COM"))


_HEADER = """\
; ============================================================================
; STAT_6502.s -- stale 6502 work-buffer tail of STAT.COM (SoftCard CP/M 2.20, 44K)
; ----------------------------------------------------------------------------
; The tail of STAT.COM ($15BD-$18FF in the loaded image) is NOT Z-80 code or live
; data -- nothing in STAT references it (its last live scratch variable is
; FILE_SORTKEY_TBL at $15BC; nothing touches $15BD or beyond). It is leftover
; content of the cross-assembler's work buffer -- the uninitialised top of STAT's
; BSS, captured when the .COM was SAVEd. Two recognisable parts:
;
;   $15BD-$15FF  a fragment of assembled 6502 OBJECT CODE (a Disk II denibble /
;                16-bit-add helper -- LDA #$03 / STA $8F / ... / JMP $1D59, plus an
;                ($5E),Y read+add loop). Being a fragment, its last bytes are
;                partial instructions; ca65 cannot encode the one undocumented
;                opcode that falls here ($15F7 NOP #imm), so that and the single
;                $15FF byte that straddles the text boundary are emitted as `.byte`.
;
;   $1600-$18FF  the 6502 ASSEMBLY-SOURCE LISTING of a Disk II seek/read driver,
;                stored as high-bit ($80-set) Apple text, one source line per $8D
;                (carriage-return). Lines: "SAMEDRV LDA A.TRK" / "JSR MYSEEK" /
;                "TRYTRK ... RDADR ... SETTRK ... RETRYCNT" / "GOCAL" / "DRVERR" /
;                "RTTRK LDA A.VOL", etc. -- the symbolic source of a driver like
;                the object fragment above.
;
; Both run on the 6502 conceptually (the SoftCard CPU switch), so from the Z-80
; they are opaque data; STAT.asm INCBINs the assembled binary of this file.
; Nothing references the block, so NO cross-CPU EQUs are needed (the live Z-80
; scratch variables all sit below $15BD and stay as Z-80 DEFB in STAT.asm). The
; block is a captured buffer (NOT relocated by STAT), so it is disassembled in
; place at its load address $15BD and the absolute operands are the literal bytes.
;
; The source-listing text is emitted as readable strings via a `.charmap` that
; maps each printable ASCII code to its high-bit Apple form (e.g. 'A' -> $C1,
; ' ' -> $A0), with the $8D line terminator emitted literally -- so the listing is
; legible yet the bytes are unchanged. Reassembles BYTE-IDENTICAL to the on-disk
; tail (see cpm_pipeline test_utilities_roundtrip, STAT case).
; ============================================================================
"""


def _emit_code(mem) -> list[str]:
    """Disassemble the 6502 object fragment $1580-$15FF in place."""
    out = []
    a = BLOCK_START
    while a < CODE_END:
        op = mem[a]
        ent = OPCODES.get(op)
        if ent is None or op in _UNDOC:
            # ca65 can't encode an undocumented opcode: emit its whole encoding
            # (opcode + operand bytes) as `.byte` so decoding resumes cleanly
            # after it.
            n = ent[2] if ent else 1
            n = min(n, CODE_END - a)
            raw = ", ".join(f"${mem[a+i]:02X}" for i in range(n))
            out.append(f"        .byte   {raw:<35} ; ${a:04X}"
                       f"  (undocumented opcode -- ca65 cannot encode)")
            a += n
            continue
        mn, mode, size = ent
        if a + size > CODE_END:
            raw = ", ".join(f"${mem[a+i]:02X}" for i in range(CODE_END - a))
            out.append(f"        .byte   {raw:<35} ; ${a:04X}"
                       f"  (partial instruction at the text boundary)")
            a = CODE_END
            continue
        operand = _operand(mem, a, mode)
        instr = f"{mn} {operand}".rstrip() if operand else mn
        raw = " ".join(f"{mem[a+i]:02X}" for i in range(size))
        out.append(f"        {instr:<28} ; ${a:04X}  {raw}")
        a += size
    return out


def _operand(mem, addr, mode) -> str:
    if mode in ("IMP", "ACC"):
        return ""
    if mode == "IMM":
        return f"#${mem[addr+1]:02X}"
    if mode == "ZP":
        return f"${mem[addr+1]:02X}"
    if mode == "ZPX":
        return f"${mem[addr+1]:02X},X"
    if mode == "ZPY":
        return f"${mem[addr+1]:02X},Y"
    if mode == "IZX":
        return f"(${mem[addr+1]:02X},X)"
    if mode == "IZY":
        return f"(${mem[addr+1]:02X}),Y"
    if mode == "REL":
        off = mem[addr+1]
        if off > 127:
            off -= 256
        target = (addr + 2 + off) & 0xFFFF
        return f"${target:04X}"
    if mode in ("ABS", "ABX", "ABY", "IND"):
        val = mem[addr+1] | (mem[addr+2] << 8)
        prefix = "a:" if val < 0x100 else ""
        sfx = {"ABS": "", "ABX": ",X", "ABY": ",Y", "IND": ""}[mode]
        if mode == "IND":
            return f"({prefix}${val:04X})"
        return f"{prefix}${val:04X}{sfx}"
    return ""


def _emit_charmap() -> list[str]:
    """A `.charmap` mapping every printable ASCII code to its high-bit Apple form,
    so the source-listing text can be written as plain quoted strings while the
    assembled bytes keep bit 7 set. $8D (CR) is the line terminator, emitted
    literally."""
    out = ["; -- charmap: printable ASCII -> high-bit Apple text (so the listing",
           ";    below reads as plain strings yet assembles with bit 7 set) --"]
    for c in range(0x20, 0x7F):
        out.append(f".charmap ${c:02X}, ${c | 0x80:02X}")
    out.append("")
    return out


def _emit_text(mem) -> list[str]:
    """Emit the high-bit source-listing text $1600-$18FF as `.byte "..."` strings,
    one ca65 directive per source line (split on the $8D terminator)."""
    out = []
    a = CODE_END
    while a < BLOCK_END:
        # Gather one line: printable chars up to and including the next $8D.
        start = a
        chars = []
        while a < BLOCK_END and mem[a] != 0x8D:
            chars.append(mem[a] & 0x7F)
            a += 1
        text = "".join(chr(c) for c in chars)
        # Sanity: every gathered char must be quotable (no quote/backslash).
        assert all(0x20 <= c <= 0x7E and c not in (0x22, 0x5C) for c in chars), \
            f"unquotable byte in listing line at ${start:04X}"
        if a < BLOCK_END and mem[a] == 0x8D:
            # line + CR terminator
            if text:
                out.append(f'        .byte   "{text}", $8D'
                           f'{"":{max(0, 30 - len(text))}}; ${start:04X}')
            else:
                out.append(f'        .byte   $8D'
                           f'                                          ; ${start:04X}')
            a += 1
        else:
            # trailing run with no terminator (end of block)
            out.append(f'        .byte   "{text}"'
                       f'{"":{max(0, 32 - len(text))}}; ${start:04X}')
    return out


def generate() -> str:
    com = _com_bytes()
    mem = bytearray(0x10000)
    mem[0x100:0x100 + len(com)] = com
    lines = [_HEADER, '.setcpu "6502"', '.segment "CODE"', "",
             f".org ${BLOCK_START:04X}", ""]
    lines.append("; -- $15BD-$15FF: assembled 6502 object-code fragment --")
    lines.extend(_emit_code(mem))
    lines.append("")
    lines.append("; -- $1600-$18FF: 6502 assembly-source LISTING (high-bit Apple text) --")
    lines.extend(_emit_charmap())
    lines.extend(_emit_text(mem))
    return "\n".join(lines) + "\n"


def config() -> str:
    size = BLOCK_END - BLOCK_START
    return (
        "# Linker config for STAT_6502.s -- stale 6502 work-buffer tail of STAT.COM.\n"
        "MEMORY {\n"
        f"    RAM: start = ${BLOCK_START:04X}, size = ${size:04X}, file = %O;\n"
        "}\n"
        "SEGMENTS {\n"
        "    CODE: load = RAM, type = ro;\n"
        "}\n"
    )


def write() -> Path:
    OUT_S.write_text(generate(), encoding="utf-8")
    OUT_CFG.write_text(config(), encoding="utf-8")
    return OUT_S


if __name__ == "__main__":
    p = write()
    print("wrote", p, "and", p.with_suffix(".cfg"))
