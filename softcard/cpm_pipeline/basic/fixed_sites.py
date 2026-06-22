"""Identify instruction sites whose in-body address/immediate operand is IDENTICAL in
GBASIC and MBASIC. Because the interpreter body relocates ($3000 in GBASIC, in place at
$0100 in MBASIC), a body-relative reference has DIFFERENT operand values in the two
builds; a value that is the SAME in both is therefore FIXED -- a stack/RAM address or a
constant (e.g. `LD BC,$3028` = graphics coords 48,40) -- and must stay a literal, not a
relocating body label. (Brent's test: same in both => not relocatable.)

Used to tell the formatter which operand sites to keep literal, so a constant/fixed
address is not mislabeled as the body routine that happens to sit at that address."""
import re

from cpm_pipeline.basic.map_gbasic_to_mbasic import (
    gbasic_run_image, flat_image, lockstep)
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline import reference_data as rd
from disasm_z80.opcodes import decode_at
from pathlib import Path

_HEX = re.compile(r'\$([0-9A-Fa-f]{4})')

# Register-load immediate opcodes (LD r,n). When one of these is the LOW byte of an
# `LD BC,$xxNN` operand, the instruction is a coded-constant COVER: a computed jump
# enters at its middle byte (the $NN) so `LD r,$xx` loads a type/error code -- the
# operand $xxNN is NOT an address (the high byte is the code), so it must stay a
# literal, never be mislabeled as the table/string its value happens to point at.
_LOAD_OPS = {0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x3E}


def mid_string_constant_sites(mem, code, str_lo, str_hi, lo, hi, str_mem=None):
    """Instruction addresses in [lo, hi) whose 16-bit operand lands MID-string in the
    error-message region [str_lo, str_hi) -- the byte before it is not a $00 string
    terminator. A genuine error-string reference points to a string START (just past a
    $00); a mid-string value is a coincidental constant used by FP / PRINT USING code,
    so keep it literal (don't mistake it for an error message).

    Instructions are decoded from `mem`; the string terminator is read from `str_mem`
    (default `mem`) -- needed because GBASIC's body image does not contain the low
    region, so the string bytes must come from the header image instead."""
    from disasm_z80.opcodes import decode_at
    str_mem = mem if str_mem is None else str_mem
    sites = set()
    for a in code:
        if not (lo <= a < hi):
            continue
        try:
            ins = decode_at(mem, a)
        except (IndexError, KeyError):
            continue
        for m in _HEX.finditer(ins.mnemonic):
            v = int(m.group(1), 16)
            if str_lo <= v < str_hi and str_mem[v - 1] != 0:
                sites.add(a)
    return sites


def cover_idiom_sites(mem, code, lo, hi, labels=None):
    """Return the set of `LD BC,$xxNN` cover-idiom instruction addresses in [lo, hi)
    (NN a register-load opcode, NOT followed by PUSH BC). Their operand is a coded
    constant (high byte = value, low byte = the mid-instruction LD r,n entry), so the
    formatter must keep it literal. A genuine computed call (`LD BC,addr; PUSH BC`)
    is excluded -- there BC really is an address.

    The cover only exists if a computed jump actually ENTERS mid-instruction, i.e. the
    operand low byte (a+1) is a real jump TARGET -- hence a label. (Merely being in
    `code` is too weak: coverage/recovery may have decoded the operand byte without it
    being a target.) Without that, the `LD BC,$xxNN` is an ordinary address load whose
    low byte coincides with a register-load opcode (e.g. `LD BC,BUF`, BUF=$0A0E, low byte
    $0E); freezing it would wrongly fail to relocate in the fold. So require (a+1) to be a
    label when `labels` is supplied (else fall back to the in-code test). A genuine
    same-in-both cover constant stays protected by fixed_operand_sites."""
    entries = labels if labels is not None else code
    sites = set()
    for a in code:
        if not (lo <= a < hi) or mem[a] != 0x01:        # LD BC,nn
            continue
        if (mem[a + 1] in _LOAD_OPS and mem[a + 3] != 0xC5   # not PUSH BC
                and (a + 1) in entries):                     # a computed jump TARGETS the mid-byte
            sites.add(a)
    return sites


def _gmap(g, m, gmem, mmem):
    anchors = [(0x81D3, 0x5E51)]
    for lo, hi in ((0x0103, 0x0252), (0x04D8, 0x0522)):
        for off in range(lo - 0x100, hi - 0x100 - 1):
            gv = g[off] | (g[off + 1] << 8)
            mv = m[off] | (m[off + 1] << 8)
            if 0x3000 <= gv < 0x8500 and 0x0100 <= mv < 0x6100:
                anchors.append((gv, mv))
    return lockstep(gmem, mmem, [(0x81D3, 0x5E51)] + anchors,
                    g_rng=(0x0100, 0x8500), m_rng=(0x0100, 0x6100))


def fixed_operand_sites():
    """Return (gbasic_sites, mbasic_sites): sets of instruction run-addresses whose
    in-IMAGE operand is the same in both builds (fixed -> keep literal).

    Covers the whole image ($0820 workspace/low-RAM up through the body), not just the
    relocated body: a low-RAM cell or routine that lands at the SAME address in both builds
    (a dead-RAM zero-fill autolabel, or a coincidentally-aligned routine) must stay a literal,
    else the fold's +$23 error-string shift over-relocates it in the MBASIC build.

    Control-flow operands count too: if a JP/CALL target is IDENTICAL in both builds it
    does not relocate with the body, so a literal emits correct bytes for both and a
    body label (e.g. a coincidental skip-idiom FDIV_6+1) would be wrong for the fold."""
    g = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "GBASIC.COM"))
    m = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "MBASIC.COM"))
    gmem, mmem = gbasic_run_image(g), flat_image(m)
    gmap = _gmap(g, m, gmem, mmem)
    gsites, msites = set(), set()
    for ga, ma in gmap.items():
        if not (0x3000 <= ga < 0x8500):
            continue
        try:
            gi, mi = decode_at(gmem, ga), decode_at(mmem, ma)
        except (IndexError, KeyError):
            continue
        if _HEX.sub('#', gi.mnemonic) != _HEX.sub('#', mi.mnemonic):
            continue
        for vg, vm in zip(_HEX.findall(gi.mnemonic), _HEX.findall(mi.mnemonic)):
            if 0x0820 <= int(vg, 16) < 0x8500 and vg == vm:
                gsites.add(ga)
                msites.add(ma)
    return gsites, msites
