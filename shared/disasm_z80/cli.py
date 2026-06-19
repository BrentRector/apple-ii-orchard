"""Command-line entry point.

    python -m disasm_z80 INPUT.bin --org $0100 \\
        [--length 0x1000] \\
        [--symbols a.json [--symbols b.json ...]] \\
        [--entry $0100 [--entry $0103 ...]] \\
        [--data-region $1000-$10FF] \\
        --output OUT
        # writes OUT.asm
"""

import argparse
import sys
from pathlib import Path

from .symbols import SymbolTable
from .walker import Walker
from .formatter import SjasmFormatter


def _parse_addr(s):
    s = s.strip()
    if s.startswith("$"):
        return int(s[1:], 16)
    if s.lower().startswith("0x"):
        return int(s, 16)
    return int(s)


def _parse_range(s):
    a, b = s.split("-", 1)
    return _parse_addr(a), _parse_addr(b) + 1


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="disasm_z80",
        description="Z-80 disassembler with full prefix coverage + sjasmplus output.",
    )
    p.add_argument("input")
    p.add_argument("--org", required=True)
    p.add_argument("--length", default=None)
    p.add_argument("--symbols", action="append", default=[])
    p.add_argument("--entry", action="append", default=[])
    p.add_argument("--data-region", action="append", default=[],
                   dest="data_regions")
    p.add_argument("--auto-coverage", action="store_true",
                   help="grow code coverage past recursive descent: resolve "
                        "computed-jump dispatch tables, harvest jump/pointer-table "
                        "targets, and validated after-terminal sweep "
                        "(byte-identical; minimizes DEFB-that-is-code)")
    p.add_argument("--output", required=True,
                   help="output path WITHOUT extension (writes .asm)")
    args = p.parse_args(argv)

    in_path = Path(args.input)
    raw = in_path.read_bytes()
    org = _parse_addr(args.org)
    length = _parse_addr(args.length) if args.length else len(raw)
    if length > len(raw):
        print(f"error: --length {length} exceeds input size {len(raw)}",
              file=sys.stderr)
        return 2

    mem = bytearray(0x10000)
    mem[org:org + length] = raw[:length]

    symbols = SymbolTable()
    for sp in args.symbols:
        symbols.load_file(sp)

    walker = Walker(mem, start=org, end=org + length)
    for ds in args.data_regions:
        walker.add_data_region(*_parse_range(ds))

    entries = [_parse_addr(e) for e in args.entry] if args.entry else [org]
    for e in entries:
        walker.trace(e)
    if args.auto_coverage:
        from disasm_common.coverage import (
            maximize_coverage, z80_decoder, z80_dispatch_scanner, z80_ref_harvester,
        )
        maximize_coverage(
            walker, mem, cpu="z80",
            decoder=z80_decoder(mem),
            scan_dispatch=z80_dispatch_scanner(mem, org, org + length),
            harvest_refs=z80_ref_harvester(mem, org, org + length),
        )
    walker.name_labels(symbols=symbols)

    fmt = SjasmFormatter(
        mem, walker, symbols,
        origin=org, length=length,
        source_name=in_path.name,
    )
    out_base = Path(args.output)
    asm_path = out_base.with_suffix(".asm")
    bin_path = out_base.with_suffix(".bin")
    src = fmt.emit_source().replace("{out_bin}", bin_path.as_posix())
    asm_path.write_text(src, encoding="utf-8")

    n_code = len(walker.code)
    n_data = length - n_code
    n_labels = len(walker.labels)
    print(f"disassembled {length} bytes at ${org:04X}: "
          f"{n_code} code, {n_data} data, {n_labels} labels")
    print(f"  -> {asm_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
