#!/usr/bin/env python3
"""(Re)generate the raw decompiled source for a distribution: every OS region
and every .COM utility, as commented assembly that round-trips byte-identical.

    python generate_distribution.py CPM220     # 2.20 (CPM220Disk1.po)
    python generate_distribution.py CPMV233    # 2.23 (CPMV233.DSK)

This writes the *raw* (un-annotated) disassembly into <DISTRO>/os and
<DISTRO>/utilities. The AI `[AI]` prose layer is added separately (the toolchain's
`--ai` flag, or the project's annotation workflow); re-running this OVERWRITES any
annotations, so regenerate then re-annotate.

Needs the local toolchain on PATH (`source shared/toolchain/env.sh`) only for the
disassemblers' dependencies; the disassembly itself is pure Python.
"""

from __future__ import annotations

import re
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent           # cpm-80/decompiled
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "cpm-80"))
sys.path.insert(0, str(REPO / "shared"))

from cpm_pipeline.decompile_os import decompile_os      # noqa: E402
from cpm_pipeline.decompile_com import decompile_com    # noqa: E402
from cpm_pipeline import filesystem as fs               # noqa: E402

DISKS = REPO / "cpm-80" / "disks"
DISTROS = {"CPMV233": "CPMV233.DSK", "CPM220": "CPM220Disk1.po"}


def _normalize_savebin(path: Path) -> None:
    """Make any embedded SAVEBIN path a bare filename so the .asm is portable."""
    t = path.read_text(encoding="utf-8")

    def repl(m):
        return 'SAVEBIN "' + m.group(1).replace("\\", "/").split("/")[-1] + '"'

    t2 = re.sub(r'SAVEBIN\s+"([^"]+)"', repl, t)
    if t2 != t:
        path.write_text(t2, encoding="utf-8")


def generate(distro: str) -> None:
    disk = DISKS / DISTROS[distro]
    base = HERE / distro
    os_dir, util_dir = base / "os", base / "utilities"
    for d in (os_dir, util_dir):
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)

    tmp = Path(tempfile.mkdtemp())
    res = decompile_os(disk, tmp / "os", gold=False, force=True)
    print(f"{distro}: OS regions ({res.variant})")
    for r in res.regions:
        for ext in ([".s", ".cfg"] if r.cpu == "6502" else [".asm"]):
            f = r.asm_path.with_suffix(ext)
            if f.exists():
                dst = os_dir / f.name
                shutil.copy2(f, dst)
                if ext == ".asm":
                    _normalize_savebin(dst)
        print(f"  {r.name:22s} {r.cpu}")

    names = [f.name for f in fs.list_files(disk) if f.name.endswith(".COM")]
    print(f"{distro}: {len(names)} .COM utilities")
    for name in names:
        r = decompile_com(disk, name, tmp / "u" / name.split(".")[0])
        dst = util_dir / (Path(name).stem + ".asm")
        shutil.copy2(r.asm_path, dst)
        _normalize_savebin(dst)
        print(f"  {name:14s} {dst.stat().st_size:7d} B  (emu {r.executed_addrs} addrs, {r.stop_reason})")


def main() -> int:
    distros = sys.argv[1:] or list(DISTROS)
    for d in distros:
        if d not in DISTROS:
            print(f"unknown distro {d!r}; choose from {list(DISTROS)}")
            return 2
        generate(d)
    return 0


if __name__ == "__main__":
    sys.exit(main())
