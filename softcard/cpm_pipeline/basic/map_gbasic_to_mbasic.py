#!/usr/bin/env python
"""Transfer GBASIC's names to MBASIC by structural correspondence (same engine, different
ORG: GBASIC body runs at $3000, MBASIC in place at $0100).  Walk both in lockstep from
corresponding entry points; where instruction SHAPES match (same op, operands may differ),
map GBASIC_addr -> MBASIC_addr for code targets AND data/RAM-cell operands.  Then every
GBASIC name lands on the corresponding MBASIC address -> identical names for identical
constructs.  Divergences (the woven graphics code, absent in MBASIC) just stop a path; we
resync from the next dispatch anchor.
"""
import json
import re
from pathlib import Path
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline import reference_data as rd
from cpm_pipeline.basic._paths import overlay_path, seeds_path
from disasm_z80.opcodes import decode_at

HEX = re.compile(r'\$[0-9A-Fa-f]+')

def gbasic_run_image(com):
    """GBASIC run layout: header $0100-$100D in place; body $100E.. at run $3000."""
    mem = bytearray(0x10000)
    hdr = 0x0F0E
    mem[0x0100:0x0100 + hdr] = com[:hdr]
    body = com[hdr:]
    mem[0x3000:0x3000 + len(body)] = body
    return mem

def flat_image(com, org=0x0100):
    mem = bytearray(0x10000)
    mem[org:org + len(com)] = com
    return mem

def shape(ins):
    """instruction 'shape' = mnemonic with hex operands masked + size."""
    return (HEX.sub('#', ins.mnemonic), ins.size)

def operands(ins):
    return [int(h[1:], 16) for h in HEX.findall(ins.mnemonic)]

def in_code(a, lo, hi):
    return lo <= a < hi

def lockstep(gmem, mmem, anchors, g_rng, m_rng):
    """anchors: list of (g_addr, m_addr).  Returns {g_addr: m_addr}."""
    gmap = {}
    seen = set()
    stack = list(anchors)
    glo, ghi = g_rng; mlo, mhi = m_rng
    CALLJP = ("JP", "CALL", "JR", "DJNZ")
    while stack:
        g, m = stack.pop()
        if (g, m) in seen:
            continue
        steps = 0
        while steps < 6000:
            steps += 1
            if not (in_code(g, glo, ghi) and in_code(m, mlo, mhi)):
                break
            try:
                gi = decode_at(gmem, g); mi = decode_at(mmem, m)
            except Exception:
                break
            if shape(gi) != shape(mi):
                break                       # divergence (e.g. graphics insertion)
            if g not in gmap:
                gmap[g] = m
            go, mo = operands(gi), operands(mi)
            # map each differing operand pair (code target or data cell)
            for gv, mv in zip(go, mo):
                if gv != mv and gv not in gmap:
                    if in_code(gv, glo, ghi) and in_code(mv, mlo, mhi):
                        gmap[gv] = mv
                        # if this instruction transfers control there, walk it too
                        mn = gi.mnemonic.split()[0]
                        if mn in CALLJP:
                            stack.append((gv, mv))
            mn = gi.mnemonic.split()[0]
            uncond_terminal = (mn == "RET" and gi.mnemonic.strip() == "RET") or \
                              (mn in ("JP", "JR") and gi.mnemonic.count(',') == 0)
            if uncond_terminal:
                # the next routine usually follows in the same layout order in both
                stack.append((g + gi.size, m + mi.size))
                break
            seen.add((g, m))
            g += gi.size; m += mi.size
    return gmap

def main():
    g = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "GBASIC.COM"))
    m = bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), "MBASIC.COM"))
    gmem = gbasic_run_image(g)
    mmem = flat_image(m)

    # anchors: cold start, + every dispatch-table position (G word vs M word at same offset)
    anchors = [(0x81D3, 0x5E51)]
    for lo, hi in ((0x0103, 0x0252), (0x04D8, 0x0522)):
        for off in range(lo - 0x100, hi - 0x100 - 1):
            gv = g[off] | (g[off + 1] << 8)
            mv = m[off] | (m[off + 1] << 8)
            if 0x3000 <= gv < 0x8500 and 0x0100 <= mv < 0x6100:
                anchors.append((gv, mv))
    print("anchors:", len(anchors))

    # GBASIC code range = header $0100-$100D + body $3000-$8500; treat as one range pair
    gmap = lockstep(gmem, mmem,
                    [(0x81D3, 0x5E51)] + anchors,
                    g_rng=(0x0100, 0x8500), m_rng=(0x0100, 0x6100))
    print("mapped G->M addresses:", len(gmap))

    # transfer names from the committed GBASIC overlay (single source of truth)
    ov = json.loads(overlay_path("GBASIC").read_text(encoding="utf-8"))
    gnames = ov["renames"]; gcom = ov.get("label_comments", {})
    mren = {}; mcom = {}
    transferred = 0; missed = []
    for ghex, name in gnames.items():
        ga = int(ghex, 16)
        ma = gmap.get(ga)
        if ma is None:
            missed.append(ghex); continue
        mhex = f"{ma:04X}"
        mren[mhex] = name
        if ghex in gcom:
            mcom[mhex] = gcom[ghex]
        transferred += 1
    print(f"names transferred: {transferred}  missed: {len(missed)}")
    print("sample missed (G addrs with no M map):", missed[:20])
    json.dump({"renames": mren, "label_comments": mcom, "sections": {}},
              open(overlay_path("MBASIC"), "w"), indent=0)
    # seed file: ONLY the mapped MBASIC addresses that receive a transferred NAME (the
    # GBASIC-named heads/cells), so the base labels exactly those (not every interior
    # instruction the lockstep walked).
    seeds = []
    for ghex in gnames:
        ma = gmap.get(int(ghex, 16))
        if ma is None or not (0x0100 <= ma < 0x6100):
            continue
        try:
            if decode_at(mmem, ma).size > 0:
                seeds.append(ma)
        except Exception:
            pass
    seeds = sorted(set(seeds))
    json.dump(seeds, open(seeds_path("MBASIC"), "w"))
    print("MBASIC.seeds.json:", len(seeds), "code seeds")
    # spot map checks
    for chk in (0x81D3, 0x5E51):
        pass
    print("\nspot map (GBASIC->MBASIC):")
    for ga in (0x3000, 0x81D3, 0x0B23, 0x0E23):
        print(f"  G${ga:04X} -> M${gmap.get(ga,0):04X}  ({gnames.get(f'{ga:04X}','?')})")

if __name__ == "__main__":
    main()
