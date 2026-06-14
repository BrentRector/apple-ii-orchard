"""End-to-end round-trip harness for the CP/M 2.20 + 2.23 chunk map.

For each known region of each disk image, this script:

  1. Runs the appropriate disassembler (disasm6502 or disasm_z80) against
     the extracted .bin file with explicit load address, entry points,
     and data regions.
  2. Reassembles via ca65+ld65 (6502) or sjasmplus (Z-80).
  3. Byte-compares the rebuilt binary against the input.
  4. Prints a pass/fail table with code/data classification stats.

This replaces the placeholder ca65 path in build_dsk.py and validates that
the new disasm6502 + disasm_z80 packages round-trip every CP/M region
byte-identically -- the necessary precondition for the hand-annotation
work in task B.

Usage:
    python cpm-investigation/roundtrip_harness.py            # run all chunks
    python cpm-investigation/roundtrip_harness.py --filter BIOS   # subset
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INVEST = REPO_ROOT / "cpm-investigation"
SYMBOLS = REPO_ROOT / "symbols"

# Make the disasm6502 / disasm_z80 packages at the repo root importable.
sys.path.insert(0, str(REPO_ROOT))


@dataclass
class Chunk:
    name: str
    cpu: str                   # "6502" or "z80"
    bin_path: Path             # absolute path to the extracted .bin
    org: int                   # load address
    length: int | None = None  # bytes to disassemble (None = file size)
    entries: list[int] = field(default_factory=list)   # entry-point addresses
    data_regions: list[tuple[int, int]] = field(default_factory=list)
    symbols: list[Path] = field(default_factory=list)


# ── 2.23 chunk map ─────────────────────────────────────────────────────
# Sources: cpm-investigation/build_dsk.py for load addresses;
# cpm-investigation/gen_*.py for known entry points and effective lengths.

APPLE2 = SYMBOLS / "apple2.json"
CPM22 = SYMBOLS / "cpm_2_2.json"

CHUNKS_223 = [
    # First byte at $0800 is the DOS sector-count byte; code starts at $0801.
    Chunk(
        "CPM223_BootLoader", "6502",
        INVEST / "loader_223.bin",
        org=0x0800, entries=[0x0801],
        # Past $083C is text strings + zero pad + RWTS staging chunks.
        data_regions=[(0x083C, 0x1400)],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM223_InstallFragments", "6502",
        INVEST / "installfragments_223.bin",
        org=0x0200, entries=[0x0200],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM223_RWTS", "6502",
        INVEST / "rwts_223.bin",
        org=0x0A00, entries=[0x0A00],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM223_DiskCallbacks", "z80",
        INVEST / "diskcallbacks_223.bin",
        org=0x1A00, entries=[0x1A00],
        symbols=[CPM22],
    ),
    Chunk(
        "CPM223_SystemImage", "z80",
        INVEST / "sysimg_223.bin",
        org=0x8000, entries=[0x8000],
        symbols=[CPM22],
    ),
    Chunk(
        "CPM223_BIOS", "z80",
        INVEST / "bios_223.bin",
        # File is 2048 bytes (sector-aligned extraction); live BIOS is the
        # first 1352 bytes ($FAB8..$FFFF).
        org=0xFAB8, length=0x0548,
        # All 17 BIOS jump-table entries.
        entries=[0xFAB8 + i * 3 for i in range(17)],
        symbols=[CPM22],
    ),
]

# ── 2.20 chunk map ─────────────────────────────────────────────────────
CHUNKS_220 = [
    Chunk(
        "CPM220_BootLoader", "6502",
        INVEST / "loader_220.bin",
        org=0x0800, entries=[0x0801],
        data_regions=[(0x083C, 0x1400)],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM220_InstallFragments", "6502",
        INVEST / "installfragments_220.bin",
        org=0x0200, entries=[0x0200],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM220_RWTS", "6502",
        INVEST / "rwts_220.bin",
        org=0x0A00, entries=[0x0A00],
        symbols=[APPLE2],
    ),
    Chunk(
        "CPM220_SystemImage", "z80",
        INVEST / "sysimg_220.bin",
        org=0x8000, entries=[0x8000],
        symbols=[CPM22],
    ),
    Chunk(
        "CPM220_BIOS", "z80",
        INVEST / "bios_220.bin",
        org=0xDACC, entries=[0xDACC + i * 3 for i in range(17)],
        symbols=[CPM22],
    ),
]

ALL_CHUNKS = CHUNKS_223 + CHUNKS_220


# ── Disasm + assemble runners ──────────────────────────────────────────
@dataclass
class Result:
    chunk: Chunk
    ok: bool
    bytes_total: int
    bytes_code: int
    bytes_data: int
    n_labels: int
    first_diff: int | None
    note: str = ""


def _addr(n):
    return f"${n:04X}"


def _range(start, end_exclusive):
    return f"{_addr(start)}-{_addr(end_exclusive - 1)}"


def run_chunk(chunk: Chunk, tmp: Path) -> Result:
    if not chunk.bin_path.exists():
        return Result(chunk, False, 0, 0, 0, 0, None,
                      note=f"missing input: {chunk.bin_path.name}")

    raw = chunk.bin_path.read_bytes()
    length = chunk.length if chunk.length is not None else len(raw)
    original_truncated = raw[:length]

    out_base = tmp / chunk.name
    cli_argv = [
        str(chunk.bin_path),
        "--org", _addr(chunk.org),
        "--length", _addr(length),
        "--output", str(out_base),
    ]
    for s in chunk.symbols:
        cli_argv += ["--symbols", str(s)]
    for e in chunk.entries:
        cli_argv += ["--entry", _addr(e)]
    for ds in chunk.data_regions:
        cli_argv += ["--data-region", _range(*ds)]

    if chunk.cpu == "6502":
        from disasm6502.cli import main as disasm_main
        rc = disasm_main(cli_argv)
        if rc != 0:
            return Result(chunk, False, length, 0, 0, 0, None,
                          note="disasm6502 CLI failed")
        s_path = out_base.with_suffix(".s")
        cfg_path = out_base.with_suffix(".cfg")
        o_path = out_base.with_suffix(".o")
        bin_path = out_base.with_suffix(".bin")
        r1 = subprocess.run(
            ["ca65", str(s_path), "-o", str(o_path)],
            capture_output=True, text=True,
        )
        if r1.returncode != 0:
            return Result(chunk, False, length, 0, 0, 0, None,
                          note=f"ca65: {r1.stderr.strip().splitlines()[-1] if r1.stderr else 'failed'}")
        r2 = subprocess.run(
            ["ld65", "-C", str(cfg_path), "-o", str(bin_path), str(o_path)],
            capture_output=True, text=True,
        )
        if r2.returncode != 0:
            return Result(chunk, False, length, 0, 0, 0, None,
                          note=f"ld65: {r2.stderr.strip().splitlines()[-1] if r2.stderr else 'failed'}")
        rebuilt = bin_path.read_bytes()
    else:  # z80
        from disasm_z80.cli import main as disasm_main
        rc = disasm_main(cli_argv)
        if rc != 0:
            return Result(chunk, False, length, 0, 0, 0, None,
                          note="disasm_z80 CLI failed")
        asm_path = out_base.with_suffix(".asm")
        bin_path = out_base.with_suffix(".bin")
        r = subprocess.run(
            ["sjasmplus", str(asm_path)],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            err = (r.stdout + r.stderr).strip().splitlines()
            tail = err[-1] if err else "failed"
            return Result(chunk, False, length, 0, 0, 0, None,
                          note=f"sjasmplus: {tail[:60]}")
        rebuilt = bin_path.read_bytes()

    # Compute code/data stats by re-running the walker (cheap).
    if chunk.cpu == "6502":
        from disasm6502.walker import Walker as W
    else:
        from disasm_z80.walker import Walker as W
    mem = bytearray(0x10000)
    mem[chunk.org:chunk.org + length] = original_truncated
    walker = W(mem, start=chunk.org, end=chunk.org + length)
    for ds in chunk.data_regions:
        walker.add_data_region(*ds)
    for e in chunk.entries:
        walker.trace(e)
    n_code = sum(1 for a in walker.code if chunk.org <= a < chunk.org + length)
    n_data = length - n_code
    n_labels = len(walker.labels)

    # Compare
    if rebuilt == original_truncated:
        return Result(chunk, True, length, n_code, n_data, n_labels, None)
    # Find first diff
    first_diff = next(
        (i for i in range(min(len(rebuilt), len(original_truncated)))
         if rebuilt[i] != original_truncated[i]),
        min(len(rebuilt), len(original_truncated)),
    )
    return Result(chunk, False, length, n_code, n_data, n_labels, first_diff,
                  note=f"differs (rebuilt {len(rebuilt)} vs orig {length})")


# ── Reporting ──────────────────────────────────────────────────────────
def _row(name, cpu, org, length, code, data, labels, status, note):
    return (f"  {name:<26} {cpu:<5} {org:<7} {length:>6} "
            f"{code:>6} {data:>6} {labels:>6}  {status:<5} {note}")


def print_table(results: list[Result]):
    print()
    print(_row("Region", "CPU", "Org", "Bytes", "Code", "Data", "Labels", "Pass", "Note"))
    print("  " + "-" * 100)
    n_pass = 0
    for r in results:
        status = "PASS" if r.ok else "FAIL"
        n_pass += int(r.ok)
        print(_row(
            r.chunk.name, r.chunk.cpu, _addr(r.chunk.org),
            str(r.bytes_total), str(r.bytes_code), str(r.bytes_data),
            str(r.n_labels), status, r.note,
        ))
    print()
    print(f"  {n_pass}/{len(results)} pass")
    print()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--filter", help="substring match against chunk name")
    args = p.parse_args()

    if not shutil.which("ca65") or not shutil.which("ld65"):
        print("error: ca65/ld65 not on PATH (source shared/toolchain/env.sh)", file=sys.stderr)
        return 2
    if not shutil.which("sjasmplus"):
        print("error: sjasmplus not on PATH (source shared/toolchain/env.sh)", file=sys.stderr)
        return 2

    chunks = ALL_CHUNKS
    if args.filter:
        chunks = [c for c in chunks if args.filter.lower() in c.name.lower()]
        if not chunks:
            print(f"no chunks matched filter {args.filter!r}", file=sys.stderr)
            return 1

    results = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for chunk in chunks:
            results.append(run_chunk(chunk, tmp))

    print_table(results)
    return 0 if all(r.ok for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
