# -*- coding: utf-8 -*-
"""Every 2.23-44K utility source must rebuild byte-identical to its disk .COM.

The `CPMV223-44K/utilities/*.asm` files are sjasmplus decompilations of the stock
transient programs on softcard-cpm2.23-44k-system.dsk. This pins them: each
committed source, assembled standalone (SAVEBIN target swapped for a temp path),
must equal the genuine NAME.COM extracted from the disk. It is the gate that lets
the code-as-bytes sweep (decoding code/strings still rendered as DEFB) proceed
without silently diverging from what the original program actually was.
"""
import re
import shutil
from pathlib import Path

import pytest

from cpm_pipeline.region_disasm import assemble_z80
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline.reference_data import DISK_2_23_44K_SYSTEM, present

REPO = Path(__file__).resolve().parents[2]               # softcard/
UTIL_DIR = REPO / "CPMV223-44K" / "utilities"
DISK = DISK_2_23_44K_SYSTEM
HAS = bool(shutil.which("sjasmplus") and present(DISK))
skip = pytest.mark.skipif(
    not HAS, reason="sjasmplus or softcard-cpm2.23-44k-system.dsk missing")

# Every NAME.asm here corresponds to NAME.COM on the system disk.
UTILITIES = sorted(p.stem for p in UTIL_DIR.glob("*.asm"))


@skip
@pytest.mark.parametrize("name", UTILITIES)
def test_utility_source_is_byte_identical(name):
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"',
                 (UTIL_DIR / f"{name}.asm").read_text(encoding="latin-1"))
    built = assemble_z80(src)
    com = bytes(extract_file(read_disk(Path(DISK)), f"{name}.COM"))
    assert built, f"{name}.asm failed to assemble"
    assert built == com, (
        f"{name}.asm rebuilt {len(built)} bytes, expected {len(com)} "
        f"(does NOT round-trip byte-identical to {name}.COM)"
    )
