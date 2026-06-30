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
# Version-folded utilities: a SINGLE master in CPMV220-44K/utilities builds the 2.20 .COM by
# default and the 2.23 .COM when DEFINE V223 selects its IFDEF V223 islands. The 2.23-44K tree
# carries NO separate copy. (Their .COMs differ by only a few bytes -- one source, two builds,
# the same model as the GBASIC/MBASIC fold.) The default 2.20 build is checked by
# test_utility_source_is_byte_identical; the V223 build by test_version_fold_builds_223.
VERSION_FOLDED = ["SUBMIT", "DDT"]

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


def _include_deps(asm_path: Path):
    """Discover `INCLUDE "name.inc"` directives and resolve each against the shared
    include dir (softcard/include/), so the bare-name INCLUDE assembles standalone.
    Returns the ``(name, path)`` tuples `assemble_z80` stages into the build dir."""
    deps = []
    for m in re.finditer(r'(?im)^\s*INCLUDE\s+"([^"]+)"', asm_path.read_text(encoding="latin-1")):
        name = m.group(1)
        src = REPO / "include" / name
        if src.exists():
            deps.append((name, src))
    return deps


def _assemble(asm_path: Path, defines=()) -> bytes:
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                 asm_path.read_text(encoding="latin-1"))
    if defines:                                   # version-fold: e.g. DEFINE V223 selects the 2.23 islands
        src = "".join(f"    DEFINE {d}\n" for d in defines) + src
    return assemble_z80(src, incbin_deps=_incbin_deps(asm_path),
                        include_files=_include_deps(asm_path))


# (tree, name, disk) for every utility .asm in each 44K tree, vs that tree's disk.
# BASIC.asm is excluded: it is the dual-mode GBASIC/MBASIC fold master (one source, two
# builds via the GBASIC define), checked separately in test_fold_build, not against a single
# BASIC.COM.
_CASES = [
    (tree, p.stem, disk)
    for tree, disk in TREE_DISK.items()
    for p in sorted((REPO / tree / "utilities").glob("*.asm"))
    if p.stem != "BASIC"
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


@pytest.mark.parametrize("mode,version", [("GBASIC", "220"), ("MBASIC", "220"),
                                          ("GBASIC", "223"), ("MBASIC", "223")])
def test_fold_build_byte_identical(mode, version):
    """The one-conditional-source BASIC fold master (BASIC.asm) reassembles ALL FOUR
    interpreter .COMs byte-identically: DEFINE GBASIC selects GBASIC (self-relocating,
    graphics-ON) vs MBASIC (in place, graphics-OFF); DEFINE V223 selects the 2.23 release
    (the ~50-56 byte console/memory/date islands) vs the 2.20 default. One source, four builds;
    the 2.23-44K GBASIC/MBASIC are no longer separate files."""
    disk = DISK_2_23_44K_SYSTEM if version == "223" else DISK_2_20_44K_SYSTEM
    if not (HAS_SJASM and present(disk)):
        pytest.skip("sjasmplus or 44K system disk missing")
    if not (REPO / "CPMV220-44K" / "utilities" / "BASIC.asm").exists():
        pytest.skip("BASIC.asm fold master not present")
    from cpm_pipeline.basic import fold_build
    out, log = fold_build.assemble(mode, version=version)
    assert out, f"BASIC.asm ({mode} {version}) failed to assemble:\n{log[-800:]}"
    assert out == fold_build.reference(f"{mode}.COM", version), (
        f"BASIC.asm ({mode}, release {version}) does not reassemble {mode}.COM byte-identically")


@_skip(DISK_2_23_44K_SYSTEM)
@pytest.mark.parametrize("name", VERSION_FOLDED)
def test_version_fold_builds_223(name):
    """The single CPMV220-44K master, assembled with DEFINE V223, reassembles the 2.23-44K
    disk's .COM byte-identically -- the justification for one conditional source instead of
    two near-duplicate files."""
    built = _assemble(REPO / "CPMV220-44K" / "utilities" / f"{name}.asm", defines=["V223"])
    com = bytes(extract_file(read_disk(Path(DISK_2_23_44K_SYSTEM)), f"{name}.COM"))
    assert built and built == com, (
        f"CPMV220-44K/{name}.asm with DEFINE V223 does not reassemble the 2.23-44K {name}.COM")


@_skip(DISK_2_23_44K_SYSTEM)
@pytest.mark.parametrize("name", SHARED_BASE)
def test_shared_base_utility_also_matches_223_disk(name):
    """The single base (2.20-44K) source for a shared utility must be byte-identical
    on the 2.23-44K disk too -- the justification for keeping only one copy."""
    built = _assemble(REPO / "CPMV220-44K" / "utilities" / f"{name}.asm")
    com = bytes(extract_file(read_disk(Path(DISK_2_23_44K_SYSTEM)), f"{name}.COM"))
    assert built and built == com, (
        f"shared base CPMV220-44K/{name}.asm does not match the 2.23-44K disk copy")
