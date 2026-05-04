"""CLI for cpm_pipeline.

    python -m cpm_pipeline detect <disk.dsk>
        Inspect a disk image; report format, boot stub structure, CP/M variant.

    python -m cpm_pipeline build {220|223} \\
        --reference REFERENCE.dsk \\
        --output OUTPUT.dsk \\
        [--verify] [--quiet]

The `build` variant determines the chunk map (CP/M 2.20 vs 2.23). The
reference disk provides bytes for sectors not yet covered by an
annotated source (see chunk_map.py for current coverage). The output
extension determines the disk format (.dsk vs .po; format conversion
happens automatically if needed).
"""

import argparse
import sys
from pathlib import Path

from .reconstruct import reconstruct_disk
from .format_detect import detect
from .loader_trace import trace_loader
from .cold_boot_trace import trace_cold_boot


def cmd_detect(args):
    info = detect(args.disk)
    print(info.summary())
    return 0


def cmd_trace(args):
    sched = trace_loader(args.disk)
    print(sched.summary())
    return 0


def cmd_trace_z80(args):
    sched = trace_cold_boot(args.bios, bios_org=args.org)
    print(sched.summary())
    return 0


def cmd_build(args):
    variant = args.variant
    if variant == "auto":
        info = detect(args.reference)
        if info.variant == "softcard_cpm_2_23":
            variant = "223"
        elif info.variant == "softcard_cpm_2_20":
            variant = "220"
        else:
            print(f"error: could not auto-detect variant from {args.reference}; "
                  f"got {info.variant!r}; pass --variant explicitly",
                  file=sys.stderr)
            return 2
        if not args.quiet:
            print(f"auto-detected variant: {variant} "
                  f"(confidence: {info.variant_confidence})")
    result = reconstruct_disk(
        variant=variant,
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

    det = sub.add_parser("detect", help="Inspect a disk image and print structural info")
    det.add_argument("disk", help="Path to a .dsk or .po image to inspect")

    tr = sub.add_parser("trace", help="Trace the boot loader: install copies, LOAD_CPM, etc.")
    tr.add_argument("disk", help="Path to a .dsk or .po image to trace")

    tz = sub.add_parser("trace-z80",
                        help="Trace the Z-80 BIOS: jump table, trap-marker pages, "
                             "cold-boot generator + dispatch cases")
    tz.add_argument("bios", help="Path to a Z-80 BIOS binary "
                                  "(e.g., cpm-investigation/bios_223.bin)")
    tz.add_argument("--org", type=lambda s: int(s.lstrip('$'), 16), default=None,
                    help="BIOS load address (auto-detected from first JP target if omitted)")

    build = sub.add_parser("build", help="Build a CP/M disk image")
    build.add_argument("variant", choices=("220", "223", "auto"),
                       nargs="?", default="auto",
                       help="CP/M variant (220 or 223, or 'auto' to detect "
                            "from --reference; default: auto)")
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
    if args.command == "detect":
        return cmd_detect(args)
    if args.command == "trace":
        return cmd_trace(args)
    if args.command == "trace-z80":
        return cmd_trace_z80(args)
    if args.command == "build":
        return cmd_build(args)
    p.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
