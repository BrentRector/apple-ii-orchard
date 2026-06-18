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
from .handoff import find_handoff
from .version_delta import compare_disks
from .dedup import dedup as dedup_disks
from .generate import generate as generate_source_tree
from .filesystem import list_files as cpm_list_files


def _print_file_table(files, numbered=False):
    """Print a CP/M directory listing (optionally with a selection index)."""
    if not files:
        print("  (no files)")
        return
    idx = f"{'#':>3} " if numbered else ""
    print(f"  {idx}{'FILENAME':<14} {'USER':>4} {'RECORDS':>7} {'BYTES':>7}  ATTR")
    print(f"  {'-'*3+' ' if numbered else ''}{'-'*14} {'-'*4} {'-'*7} {'-'*7}  {'-'*4}")
    for i, f in enumerate(files, 1):
        attr = "".join((("R" if f.read_only else "-"), ("S" if f.system else "-")))
        num = f"{i:>3} " if numbered else ""
        print(f"  {num}{f.name:<14} {f.user:>4} {f.records:>7} {f.size:>7}  {attr}")
    print(f"\n  {len(files)} file(s)")


def cmd_list_files(args):
    info = detect(args.disk)
    print(f"# {args.disk}")
    print(f"# detected: {info.variant} (confidence: {info.variant_confidence})\n")
    _print_file_table(cpm_list_files(args.disk))
    return 0


def cmd_decompile_file(args):
    from .decompile_com import decompile_com   # lazy: pulls in disasm_z80
    out = args.out or f"decompiled_{Path(args.name).stem}"
    result = decompile_com(args.disk, args.name, out,
                           max_instructions=args.max_insns,
                           ai=args.ai, ai_backend=args.ai_backend)
    print(result.summary())
    return 0


def cmd_decompile_os(args):
    from .decompile_os import decompile_os     # lazy: pulls in disasm6502/disasm_z80
    result = decompile_os(args.disk, args.output_dir,
                          gold=not args.no_gold, force=args.force,
                          ai=args.ai, ai_backend=args.ai_backend)
    print(result.summary())
    return 0


def _prompt_selection(files):
    """Interactively read program selections (by name or number). Blank = done."""
    names = [f.name for f in files]
    chosen = []
    print("\nSelect a program to decompile (filename or #; blank line to finish):")
    while True:
        try:
            raw = input("  > ").strip()
        except EOFError:
            break
        if not raw:
            break
        if raw.isdigit() and 1 <= int(raw) <= len(names):
            chosen.append(names[int(raw) - 1])
        elif raw.upper() in names:
            chosen.append(raw.upper())
        else:
            print(f"    no such file: {raw}")
    return chosen


def cmd_decompile_disk(args):
    """Interactive end-to-end: verify -> OS -> list -> select -> decompile program(s)."""
    from .decompile_os import decompile_os
    from .decompile_com import decompile_com
    out = Path(args.output_dir)

    info = detect(args.disk)
    print(f"# {args.disk}")
    print(f"# detected: {info.variant} (confidence: {info.variant_confidence})")
    if info.variant == "unknown":
        print("warning: not a recognized SoftCard CP/M variant; OS results are best-effort",
              file=sys.stderr)

    print("\n== Reverse-engineering the CP/M operating system (6502 + Z-80) ==")
    os_res = decompile_os(args.disk, out / "os",
                          gold=not args.no_gold, force=True,
                          ai=args.ai, ai_backend=args.ai_backend)
    print(os_res.summary())

    print("\n== CP/M filesystem ==")
    files = cpm_list_files(args.disk)
    _print_file_table(files, numbered=True)

    names = [f.name for f in files]
    if args.select:
        selected = [s.upper() for s in args.select]
    else:
        selected = _prompt_selection(files)

    for name in selected:
        if name not in names:
            print(f"skip: {name!r} not in the directory", file=sys.stderr)
            continue
        print(f"\n== Decompiling {name} to Z-80 source ==")
        r = decompile_com(args.disk, name, out / "files" / Path(name).stem,
                          ai=args.ai, ai_backend=args.ai_backend)
        print(r.summary())
    return 0


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


def cmd_handoff(args):
    info = find_handoff(args.disk, bios_path=args.bios, bios_org=args.bios_org)
    print(info.summary())
    return 0


def cmd_diff(args):
    delta = compare_disks(args.disk_a, args.disk_b)
    print(delta.summary())

    # CP/M serial number (6 bytes at the BDOS base).
    from .component_diff import system_component_diff, cpm_serial, serial_str
    sa, sb = cpm_serial(args.disk_a), cpm_serial(args.disk_b)
    if sa is not None or sb is not None:
        same = sa == sb
        print(f"  CP/M serial: A={serial_str(sa)}  B={serial_str(sb)} "
              f"({'same' if same else 'DIFFERENT'})")

    # Classify system-track differences by OS component (44K variants).
    comp = system_component_diff(args.disk_a, args.disk_b)
    if comp is not None:
        print("  system components (tracks 0-2):")
        if any(d for d, _ in comp.values()):
            for c, (d, t) in comp.items():
                print(f"    {c:18} {'%d byte diff' % d if d else 'identical'}")
        else:
            print("    all identical")

    # Filesystem-level differences (which files differ).
    from .dedup import compare_logical
    v = compare_logical(args.disk_a, args.disk_b)
    if v.file_diffs:
        print("  filesystem:")
        for fd in v.file_diffs:
            print(f"    {fd}")
    return 0


def cmd_dedup(args):
    if len(args.disks) < 2:
        print("dedup needs at least two disk images", file=sys.stderr)
        return 2
    keepers, drops, verdicts = dedup_disks(args.disks)
    print(f"# logical dedup of {len(args.disks)} disks -> "
          f"{len(keepers)} to keep, {len(drops)} redundant\n")
    print("Keep:")
    for p in keepers:
        print(f"  {p.name}")
    if drops:
        print("\nRedundant (drop):")
        for r in drops:
            extra = (f" (missing: {', '.join(r.missing)})"
                     if r.kind == "subset" else "")
            print(f"  {r.path.name}  --  {r.kind} of {r.kept.name}{extra}")
    # Same-OS pairs that diverge in files (each keeps something the other lacks).
    near = [v for v in verdicts.values()
            if v.os_same and v.relation == "divergent" and v.file_diffs]
    if near:
        print("\nKept apart (same OS, each has files the other lacks):")
        for v in near:
            print("  " + v.summary().replace("\n", "\n  "))

    # Lineage: group by CP/M serial (the licensed copy a disk's system descends
    # from). Independent of byte-level dedup -- a resize/reserialize-free copy
    # keeps the serial, so this clusters disks by origin.
    from .component_diff import lineage_groups
    lin = lineage_groups(args.disks)
    print("\nLineage (CP/M serial = originating license):")
    for serial, group in sorted(lin.items(),
                                key=lambda kv: (kv[0] == "unknown", -len(kv[1]), kv[0])):
        print(f"  {serial}  ({len(group)} disk{'s' if len(group) != 1 else ''}):")
        for d in group:
            print(f"    {d.name}")
    return 0


def cmd_generate(args):
    result = generate_source_tree(
        args.disk, args.output_dir, overwrite=args.force,
    )
    print(result.summary())
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
        source_dir=args.source_dir,
    )
    if not args.quiet:
        total = result.bytes_from_assembled + result.bytes_from_extracted
        pct_assembled = (100 * result.bytes_from_assembled / total) if total else 0
        print(f"wrote {result.output_path}")
        print(f"  {result.chunks_written} chunks placed")
        print(f"  {result.bytes_from_assembled} bytes from freshly assembled OS source (the per-disk os/ tree) "
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

    lf = sub.add_parser("list-files",
                        help="List the CP/M files in the disk's filesystem")
    lf.add_argument("disk", help="Path to a .dsk or .po image")

    dcf = sub.add_parser("decompile-file",
                         help="Decompile a CP/M .COM program to commented Z-80 source")
    dcf.add_argument("disk", help="Path to a .dsk or .po image")
    dcf.add_argument("name", help="CP/M filename to decompile, e.g. CPM60.COM")
    dcf.add_argument("--out", default=None,
                     help="Output directory (default: decompiled_<NAME>)")
    dcf.add_argument("--max-insns", type=int, default=2_000_000, dest="max_insns",
                     help="Emulation instruction budget (default: 2,000,000)")
    dcf.add_argument("--ai", action="store_true",
                     help="Add an AI prose-comment layer (Claude Code CLI, or the API)")
    dcf.add_argument("--ai-backend", choices=("auto", "cli", "api"), default="auto",
                     dest="ai_backend",
                     help="AI backend: auto (prefer Claude Code CLI), cli, or api")

    dco = sub.add_parser("decompile-os",
                         help="Decompile the whole CP/M OS (6502 + Z-80) to an annotated source tree")
    dco.add_argument("disk", help="Path to a .dsk or .po image")
    dco.add_argument("output_dir", help="Output directory")
    dco.add_argument("--force", "-f", action="store_true",
                     help="Overwrite a non-empty output directory")
    dco.add_argument("--no-gold", action="store_true",
                     help="Skip the hand-annotated gold source tree (auto disassembly only)")
    dco.add_argument("--ai", action="store_true",
                     help="Add an AI prose-comment layer (Claude Code CLI, or the API)")
    dco.add_argument("--ai-backend", choices=("auto", "cli", "api"), default="auto",
                     dest="ai_backend",
                     help="AI backend: auto (prefer Claude Code CLI), cli, or api")

    dcd = sub.add_parser("decompile-disk",
                         help="Interactive: verify the disk, decompile the OS, list "
                              "files, select one, decompile it")
    dcd.add_argument("disk", help="Path to a .dsk or .po image")
    dcd.add_argument("output_dir", help="Output directory")
    dcd.add_argument("--select", action="append", default=None,
                     help="Decompile this file non-interactively (repeatable); "
                          "skips the interactive prompt")
    dcd.add_argument("--no-gold", action="store_true",
                     help="Skip the hand-annotated gold source tree")
    dcd.add_argument("--ai", action="store_true",
                     help="Add an AI prose-comment layer (Claude Code CLI, or the API)")
    dcd.add_argument("--ai-backend", choices=("auto", "cli", "api"), default="auto",
                     dest="ai_backend",
                     help="AI backend: auto (prefer Claude Code CLI), cli, or api")

    tr = sub.add_parser("trace", help="Trace the boot loader: install copies, LOAD_CPM, etc.")
    tr.add_argument("disk", help="Path to a .dsk or .po image to trace")

    tz = sub.add_parser("trace-z80",
                        help="Trace the Z-80 BIOS: jump table, trap-marker pages, "
                             "cold-boot generator + dispatch cases")
    tz.add_argument("bios", help="Path to a Z-80 BIOS binary "
                                  "(e.g., cpm-investigation/bios_223.bin)")
    tz.add_argument("--org", type=lambda s: int(s.lstrip('$'), 16), default=None,
                    help="BIOS load address (auto-detected from first JP target if omitted)")

    ho = sub.add_parser("handoff",
                        help="Identify the 6502->Z-80 handoff: planted vectors + CPU-switch trigger")
    ho.add_argument("disk", help="Path to a .dsk or .po image")
    ho.add_argument("--bios", default=None,
                    help="Path to Z-80 BIOS binary; if omitted, auto-detect "
                         "from variant (cpm-investigation/bios_NNN.bin)")
    ho.add_argument("--bios-org", type=lambda s: int(s.lstrip('$'), 16),
                    default=None, dest="bios_org",
                    help="BIOS load address (auto-detected from variant if omitted)")

    df = sub.add_parser("diff", help="Compare two CP/M disks at the routine level")
    df.add_argument("disk_a", help="First disk image")
    df.add_argument("disk_b", help="Second disk image")

    dd = sub.add_parser("dedup",
                        help="Cluster disks by LOGICAL identity (same files + same OS), "
                             "ignoring CPM60/CPM56 don't-care fill and sector order")
    dd.add_argument("disks", nargs="+", help="Two or more disk images to compare")

    gn = sub.add_parser("generate",
                        help="Generate complete annotated source tree from a disk image")
    gn.add_argument("disk", help="Path to a .dsk or .po image")
    gn.add_argument("output_dir", help="Output directory (created or overwritten)")
    gn.add_argument("--force", "-f", action="store_true",
                    help="Overwrite output_dir if it already exists")

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
    build.add_argument("--source-dir", default=None, dest="source_dir",
                       help="Assemble the annotated OS sources from this directory "
                            "instead of softcard/docs/ (e.g. a decompiled/ os/ folder)")
    build.add_argument("--verify", action="store_true",
                       help="Byte-compare the output against the reference")
    build.add_argument("--quiet", action="store_true",
                       help="Suppress progress output")

    args = p.parse_args(argv)
    if args.command == "detect":
        return cmd_detect(args)
    if args.command == "list-files":
        return cmd_list_files(args)
    if args.command == "decompile-file":
        return cmd_decompile_file(args)
    if args.command == "decompile-os":
        return cmd_decompile_os(args)
    if args.command == "decompile-disk":
        return cmd_decompile_disk(args)
    if args.command == "trace":
        return cmd_trace(args)
    if args.command == "trace-z80":
        return cmd_trace_z80(args)
    if args.command == "handoff":
        return cmd_handoff(args)
    if args.command == "diff":
        return cmd_diff(args)
    if args.command == "dedup":
        return cmd_dedup(args)
    if args.command == "generate":
        return cmd_generate(args)
    if args.command == "build":
        return cmd_build(args)
    p.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
