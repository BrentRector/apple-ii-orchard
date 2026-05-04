"""CLI for cpm_pipeline.

    python -m cpm_pipeline build {220|223} \\
        --reference REFERENCE.dsk \\
        --output OUTPUT.dsk \\
        [--verify] [--quiet]

The variant determines the chunk map (CP/M 2.20 vs 2.23). The reference
disk provides bytes for sectors not yet covered by an annotated source
(see chunk_map.py for the current coverage). The output extension
determines the disk format (.dsk vs .po; format conversion happens
automatically if needed).
"""

import argparse
import sys
from pathlib import Path

from .reconstruct import reconstruct_disk


def cmd_build(args):
    result = reconstruct_disk(
        variant=args.variant,
        reference_path=args.reference,
        output_path=args.output,
        verify=args.verify,
    )
    if not args.quiet:
        total = result.bytes_from_assembled + result.bytes_from_extracted
        pct_assembled = (100 * result.bytes_from_assembled / total) if total else 0
        print(f"wrote {result.output_path}")
        print(f"  {result.chunks_written} chunks placed")
        print(f"  {result.bytes_from_assembled} bytes from freshly assembled docs/CPM*.asm "
              f"({pct_assembled:.1f}%)")
        print(f"  {result.bytes_from_extracted} bytes from pre-extracted .bin "
              f"(uncovered by annotated source)")
        if args.verify:
            if result.diff_count == 0:
                print(f"  BYTE-IDENTICAL to {args.reference}")
            else:
                print(f"  DIFFERS from reference at {result.diff_count} byte(s)")
                if result.diff_offsets:
                    print(f"  first diff offsets: " +
                          ", ".join(f"${off:05X}" for off in result.diff_offsets))
    return 0 if (not args.verify or result.diff_count == 0) else 1


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="cpm_pipeline",
        description="Stage 7: reconstruct a CP/M .dsk/.po from annotated source.",
    )
    sub = p.add_subparsers(dest="command", required=True)

    build = sub.add_parser("build", help="Build a CP/M disk image")
    build.add_argument("variant", choices=("220", "223"),
                       help="CP/M variant (220 or 223)")
    build.add_argument("--reference", required=True,
                       help="Reference disk image (provides bytes for "
                            "sectors not yet covered by annotated source)")
    build.add_argument("--output", required=True,
                       help="Output disk image (.dsk or .po; format auto-detected)")
    build.add_argument("--verify", action="store_true",
                       help="Byte-compare the output against the reference")
    build.add_argument("--quiet", action="store_true",
                       help="Suppress progress output")

    args = p.parse_args(argv)
    if args.command == "build":
        return cmd_build(args)
    p.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
