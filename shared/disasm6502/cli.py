"""Command-line entry point.

Usage
-----
    python -m disasm6502 INPUT.bin --org $0100 \\
        [--length 0x1000] \\
        [--symbols a.json [--symbols b.json ...]] \\
        [--entry $0100 [--entry $0103 ...]] \\
        [--data-region $1000-$10FF] \\
        --output OUT
        # writes OUT.s and OUT.cfg

If `--entry` is omitted, the origin address is the sole entry point.
"""

import argparse
import sys
from pathlib import Path

from .symbols import SymbolTable
from .walker import Walker
from .formatter import Ca65Formatter


def _parse_addr(s):
    """Parse '$XXXX', '0xXXXX', or decimal."""
    s = s.strip()
    if s.startswith("$"):
        return int(s[1:], 16)
    if s.lower().startswith("0x"):
        return int(s, 16)
    return int(s)


def _parse_range(s):
    """Parse 'START-END' (inclusive end) into (start, end_exclusive)."""
    a, b = s.split("-", 1)
    start = _parse_addr(a)
    end_inclusive = _parse_addr(b)
    return start, end_inclusive + 1


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="disasm6502",
        description="6502 disassembler with recursive descent + ca65 output.",
    )
    p.add_argument("input", help="raw binary to disassemble")
    p.add_argument("--org", required=True,
                   help="load address (e.g. $0100, 0x100, 256)")
    p.add_argument("--length", default=None,
                   help="bytes to disassemble (default: file size)")
    p.add_argument("--symbols", action="append", default=[],
                   help="symbol-table JSON (repeatable)")
    p.add_argument("--entry", action="append", default=[],
                   help="entry-point address (repeatable; default: --org)")
    p.add_argument("--data-region", action="append", default=[],
                   dest="data_regions",
                   help="treat START-END_INCL as data (repeatable)")
    p.add_argument("--auto-coverage", action="store_true",
                   help="grow code coverage past recursive descent: harvest "
                        "jump/pointer-table targets and validated after-terminal "
                        "sweep (byte-identical; minimizes .byte-that-is-code)")
    p.add_argument("--output", required=True,
                   help="output path WITHOUT extension (writes .s and .cfg)")
    args = p.parse_args(argv)

    in_path = Path(args.input)
    raw = in_path.read_bytes()
    org = _parse_addr(args.org)
    length = _parse_addr(args.length) if args.length else len(raw)
    if length > len(raw):
        print(f"error: --length {length} exceeds input size {len(raw)}",
              file=sys.stderr)
        return 2

    # Build a 64K memory image with the file at `org`.
    mem = bytearray(0x10000)
    mem[org:org + length] = raw[:length]

    # Symbols.
    symbols = SymbolTable()
    for sp in args.symbols:
        symbols.load_file(sp)

    # Walker over [org, org+length).
    walker = Walker(mem, start=org, end=org + length)
    for ds in args.data_regions:
        walker.add_data_region(*_parse_range(ds))

    entries = [_parse_addr(e) for e in args.entry] if args.entry else [org]
    for e in entries:
        walker.trace(e)
    if args.auto_coverage:
        from disasm_common.coverage import (
            maximize_coverage, m6502_decoder, m6502_ref_harvester,
        )
        maximize_coverage(
            walker, mem, cpu="6502",
            decoder=m6502_decoder(mem),
            scan_dispatch=None,   # no computed-jump resolver for the 6502 yet
            harvest_refs=m6502_ref_harvester(mem, org, org + length),
        )
    walker.name_labels(symbols=symbols)

    fmt = Ca65Formatter(
        mem, walker, symbols,
        origin=org, length=length,
        source_name=in_path.name,
    )
    out_base = Path(args.output)
    src_path = out_base.with_suffix(".s")
    cfg_path = out_base.with_suffix(".cfg")
    src_path.write_text(fmt.emit_source(), encoding="utf-8")
    cfg_path.write_text(fmt.emit_config(), encoding="utf-8")

    n_code = len(walker.code)
    n_data = length - n_code
    n_labels = len(walker.labels)
    print(f"disassembled {length} bytes at ${org:04X}: "
          f"{n_code} code, {n_data} data, {n_labels} labels")
    print(f"  -> {src_path}")
    print(f"  -> {cfg_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
