# -*- coding: utf-8 -*-
"""Every 44K utility source must rebuild byte-identical to its disk .COM.

The `CPMV220-44K/utilities/*.asm` and `CPMV223-44K/utilities/*.asm` files are
sjasmplus decompilations of the transient programs on the two 44K system disks.
This pins them: each committed source, assembled standalone (SAVEBIN target
swapped for a temp path), must equal the genuine NAME.COM on its disk.

CPMV220-44K is the BASE source tree. The utilities that are byte-identical across
the 2.20-44K and 2.23-44K disks live ONLY in CPMV220-44K (one source for all
releases); the cross-check below proves the base source also reassembles to the
2.23-44K disk's copy. The 2.23-44K tree carries only the utilities whose bytes
differ from 2.20-44K or are 2.23-only (plus the two BASICs).
"""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline.reference_data import (
    DISK_2_20_44K_SYSTEM, DISK_2_23_44K_SYSTEM, present)

REPO = Path(__file__).resolve().parents[2]               # softcard/

# each 44K tree's utilities are checked against THAT tree's disk
TREE_DISK = {
    "CPMV220-44K": DISK_2_20_44K_SYSTEM,
    "CPMV223-44K": DISK_2_23_44K_SYSTEM,
}
# byte-identical-across-both-disks utilities: they live ONLY in the CPMV220-44K
# base and must also reassemble == the 2.23-44K disk copy.
SHARED_BASE = ["APDOS", "ASM", "DOWNLOAD", "DUMP", "ED", "LOAD", "PIP", "STAT", "XSUB"]

HAS_SJASM = shutil.which("sjasmplus") is not None
_skip = lambda disk: pytest.mark.skipif(  # noqa: E731
    not (HAS_SJASM and present(disk)), reason="sjasmplus or 44K system disk missing")


def _incbin_deps(asm_path: Path):
    """Discover any embedded-6502 INCBIN dependencies of a utility source.

    A utility that carries an embedded 6502 payload extracts it to a sibling ca65
    source ``<NAME>.s`` (+ ``<NAME>.cfg``) and INCBINs the assembled ``<NAME>.bin``.
    The INCBIN directive is the single declaration of the dependency, so we just
    scan for it and pair each ``.bin`` with its sibling ca65 source -- no separate
    registry to keep in sync. Returns the ``(bin_name, ca65_src, defines)`` tuples
    `assemble_z80` sub-assembles into the build dir."""
    deps = []
    for m in re.finditer(r'(?im)^\s*INCBIN\s+"([^"]+\.bin)"', asm_path.read_text(encoding="latin-1")):
        bin_name = m.group(1)
        ca65_src = asm_path.parent / (Path(bin_name).stem + ".s")
        if ca65_src.exists():
            deps.append((bin_name, ca65_src, ()))
    return deps


def _assemble(asm_path: Path) -> bytes:
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                 asm_path.read_text(encoding="latin-1"))
    return assemble_z80(src, incbin_deps=_incbin_deps(asm_path))


# (tree, name, disk) for every utility .asm in each 44K tree, vs that tree's disk
_CASES = [
    (tree, p.stem, disk)
    for tree, disk in TREE_DISK.items()
    for p in sorted((REPO / tree / "utilities").glob("*.asm"))
]


@pytest.mark.parametrize(
    "tree,name,disk", _CASES, ids=[f"{t}:{n}" for t, n, _ in _CASES])
def test_utility_source_is_byte_identical(tree, name, disk):
    if not (HAS_SJASM and present(disk)):
        pytest.skip("sjasmplus or 44K system disk missing")
    built = _assemble(REPO / tree / "utilities" / f"{name}.asm")
    com = bytes(extract_file(read_disk(Path(disk)), f"{name}.COM"))
    assert built, f"{tree}/{name}.asm failed to assemble"
    assert built == com, (
        f"{tree}/{name}.asm rebuilt {len(built)} bytes, expected {len(com)} "
        f"(does NOT round-trip byte-identical to {name}.COM on its disk)")


@_skip(DISK_2_23_44K_SYSTEM)
@pytest.mark.parametrize("name", SHARED_BASE)
def test_shared_base_utility_also_matches_223_disk(name):
    """The single base (2.20-44K) source for a shared utility must be byte-identical
    on the 2.23-44K disk too -- the justification for keeping only one copy."""
    built = _assemble(REPO / "CPMV220-44K" / "utilities" / f"{name}.asm")
    com = bytes(extract_file(read_disk(Path(DISK_2_23_44K_SYSTEM)), f"{name}.COM"))
    assert built and built == com, (
        f"shared base CPMV220-44K/{name}.asm does not match the 2.23-44K disk copy")
