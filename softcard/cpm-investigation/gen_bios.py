#!/usr/bin/env python3
"""Regenerate the BIOS annotated-source files, byte-identical to the disk bytes.

Four targets, all the same shape (a flat Z-80 region disassembled at its
corrected base with the BIOS symbol tables, jump-table-seeded):

  * the **runtime** (cold-boot-patched) BIOS, from the extracted runtime images
    `bios_2{20,23}.bin`  ->  docs/CPM2{20,23}_BIOS.asm
  * the **pristine on-disk** BIOS image, from the LOAD_CPM staging tail
    `staging_2{20,23}.bin`  ->  docs/CPM2{20,23}_BIOS_Disk.asm

The on-disk image is the un-patched form the loader reads; the runtime image is
that same BIOS after the cold boot patches ~185 bytes, so the two differ and
each needs its own source. All output round-trips byte-identical.

    python gen_bios.py                 # all four
    python gen_bios.py CPM223_BIOS_Disk
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent              # softcard/cpm-investigation
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "shared"))
sys.path.insert(0, str(REPO / "softcard"))

from cpm_pipeline.region_disasm import (             # noqa: E402
    disasm_z80_region, assemble_z80, load_symbols, bios_jump_table_seeds,
)

DOCS = REPO / "softcard" / "docs"
SYMROOT = REPO / "shared" / "symbols"

# output stem -> (source .bin, (lo, hi) byte slice, load org, BIOS symbol file)
TARGETS = {
    "CPM223_BIOS":      ("bios_223.bin",    (0, 0x548),   0xFA00, "cpm_2_23_bios.json"),
    "CPM220_BIOS":      ("bios_220.bin",    (0, 0x800),   0xDA00, "cpm_2_20_bios.json"),
    "CPM223_BIOS_Disk": ("staging_223.bin", (6400, 7424), 0xFA00, "cpm_2_23_bios.json"),
    "CPM220_BIOS_Disk": ("staging_220.bin", (5888, 7168), 0xDA00, "cpm_2_20_bios.json"),
}


def generate(stem: str) -> bool:
    bin_name, (lo, hi), org, bios_sym = TARGETS[stem]
    data = (HERE / bin_name).read_bytes()[lo:hi]
    length = len(data)
    mem = bytearray(0x10000)
    mem[org:org + length] = data

    symbols = load_symbols(SYMROOT / bios_sym, SYMROOT / "cpm_2_2.json")
    seeds = bios_jump_table_seeds(mem, org, length)
    src = disasm_z80_region(mem, org, length, symbols=symbols, seeds=seeds, source_name=stem)

    (DOCS / f"{stem}.asm").write_text(src.replace("{out_bin}", f"build/{stem}.bin"),
                                      encoding="utf-8")
    ok = assemble_z80(src) == data                  # byte-identical round-trip check
    print(f"{stem}.asm  org ${org:04X}  {length} bytes  byte-identical={ok}")
    return ok


def main(argv=None) -> int:
    stems = (argv or sys.argv[1:]) or list(TARGETS)
    bad = [s for s in stems if s not in TARGETS]
    if bad:
        print(f"unknown target(s) {bad}; choose from {list(TARGETS)}")
        return 2
    return 0 if all(generate(s) for s in stems) else 1


if __name__ == "__main__":
    raise SystemExit(main())
