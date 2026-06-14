#!/usr/bin/env python3
"""Verify that every committed .asm in a decompiled distribution reassembles
byte-identically to the original code it describes.

    python verify_roundtrip.py CPMV233      # 2.23 (CPMV233.DSK)
    python verify_roundtrip.py CPM220       # 2.20 (CPM220Disk1.po)
    python verify_roundtrip.py              # both

For each OS region, reassemble (ca65+ld65 for 6502, sjasmplus for Z-80) and
compare to the extracted region binary in cpm-80/cpm-investigation/. For each
utility, reassemble and compare to the program's bytes on the disk image. The
`[AI]` comments are assembler comments, so they don't change a byte -- this proves
the annotated source is faithful, not decorative.

Needs ca65/ld65/sjasmplus on PATH (`source shared/toolchain/env.sh`). Exits
non-zero if anything fails to match.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent           # cpm-80/decompiled
REPO = HERE.parents[1]                            # repo root
sys.path.insert(0, str(REPO / "cpm-80"))
sys.path.insert(0, str(REPO / "shared"))

from cpm_pipeline import filesystem as fs         # noqa: E402

INVEST = REPO / "cpm-80" / "cpm-investigation"
DISKS = REPO / "cpm-80" / "disks"

# distro -> (disk image, [ (region name, cpu, region binary, live length) ])
DISTROS = {
    "CPMV233": ("CPMV233.DSK", [
        ("CPM_BootLoader", "6502", "loader_223.bin", 0x0C00),
        ("CPM_RWTS", "6502", "rwts_223.bin", 0x0600),
        ("CPM_InstallFragments", "6502", "installfragments_223.bin", 0x0200),
        ("CPM_DiskCallbacks", "z80", "diskcallbacks_223.bin", 0x0200),
        ("CPM_SystemImage", "z80", "sysimg_223.bin", 0x1700),
        ("CPM_BIOS", "z80", "bios_223.bin", 0x0548),
    ]),
    "CPM220": ("CPM220Disk1.po", [
        ("CPM_BootLoader", "6502", "loader_220.bin", 0x0C00),
        ("CPM_RWTS", "6502", "rwts_220.bin", 0x0600),
        ("CPM_InstallFragments", "6502", "installfragments_220.bin", 0x0200),
        ("CPM_SystemImage", "z80", "sysimg_220.bin", 0x1700),
        ("CPM_BIOS", "z80", "bios_220.bin", 0x0800),
    ]),
}


def _assemble_z80(asm: Path, work: Path) -> bytes:
    r = subprocess.run(["sjasmplus", str(asm)], capture_output=True, text=True, cwd=str(work))
    if r.returncode != 0:
        raise RuntimeError(f"sjasmplus failed for {asm.name}:\n{r.stdout}\n{r.stderr}")
    bins = list(work.glob("*.bin"))
    if not bins:
        raise RuntimeError(f"{asm.name}: sjasmplus produced no .bin")
    return bins[0].read_bytes()


def _assemble_6502(s: Path, cfg: Path, work: Path) -> bytes:
    obj = work / (s.stem + ".o")
    out = work / (s.stem + ".bin")
    r1 = subprocess.run(["ca65", str(s), "-o", str(obj)], capture_output=True, text=True)
    if r1.returncode != 0:
        raise RuntimeError(f"ca65 failed for {s.name}:\n{r1.stdout}\n{r1.stderr}")
    r2 = subprocess.run(["ld65", "-C", str(cfg), "-o", str(out), str(obj)],
                        capture_output=True, text=True)
    if r2.returncode != 0:
        raise RuntimeError(f"ld65 failed for {s.name}:\n{r2.stdout}\n{r2.stderr}")
    return out.read_bytes()


def verify(distro: str) -> list[str]:
    disk_name, regions = DISTROS[distro]
    disk = DISKS / disk_name
    base = HERE / distro
    failures = []
    print(f"### {distro}  ({disk_name})")
    print("  -- OS regions --")
    for name, cpu, binname, length in regions:
        original = (INVEST / binname).read_bytes()[:length]
        with tempfile.TemporaryDirectory() as t:
            work = Path(t)
            try:
                if cpu == "z80":
                    rebuilt = _assemble_z80(base / "os" / f"{name}.asm", work)
                else:
                    rebuilt = _assemble_6502(base / "os" / f"{name}.s",
                                             base / "os" / f"{name}.cfg", work)
            except RuntimeError as e:
                failures.append(f"{distro}/{name}"); print(f"    FAIL {name}: {e}"); continue
        ok = rebuilt[:length] == original
        if not ok:
            failures.append(f"{distro}/{name}")
        print(f"    {'ok  ' if ok else 'FAIL'} {name:22s} ({cpu}, {length} bytes)")

    print("  -- utilities --")
    for asm in sorted((base / "utilities").glob("*.asm")):
        com_name = asm.stem + ".COM"
        original = fs.extract(disk, com_name)
        with tempfile.TemporaryDirectory() as t:
            work = Path(t)
            try:
                rebuilt = _assemble_z80(asm, work)
            except RuntimeError as e:
                failures.append(f"{distro}/{com_name}"); print(f"    FAIL {com_name}: {e}"); continue
        ok = rebuilt == original
        if not ok:
            failures.append(f"{distro}/{com_name}")
        print(f"    {'ok  ' if ok else 'FAIL'} {com_name:14s} ({len(original)} bytes)")
    return failures


def main() -> int:
    distros = sys.argv[1:] or list(DISTROS)
    failures = []
    for d in distros:
        if d not in DISTROS:
            print(f"unknown distro {d!r}; choose from {list(DISTROS)}"); return 2
        failures += verify(d)
        print()
    if failures:
        print(f"FAILED: {len(failures)} artifact(s) did not round-trip: {failures}")
        return 1
    print("ALL round-trip byte-identical.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
