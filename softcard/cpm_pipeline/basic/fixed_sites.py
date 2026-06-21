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
_CF = ('JP', 'CALL', 'JR', 'DJNZ')


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
    in-body NON-control-flow operand is the same in both builds (fixed -> keep literal)."""
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
        if gi.mnemonic.split()[0] in _CF:
            continue
        for vg, vm in zip(_HEX.findall(gi.mnemonic), _HEX.findall(mi.mnemonic)):
            if 0x3000 <= int(vg, 16) < 0x8500 and vg == vm:
                gsites.add(ga)
                msites.add(ma)
    return gsites, msites
