#!/usr/bin/env python
"""Build harness for the GBASIC/MBASIC one-conditional-source FOLD.

`BASIC.asm` is the single master (a copy of the fully-relocatable GBASIC source with
`IFDEF GBASIC` conditionals).  Assembling it with the `GBASIC` symbol defined produces
GBASIC.COM; without it, MBASIC.COM.  Because both interpreters are fully label-relocatable,
the shared code is the SAME source assembled at two ORGs (GBASIC relocates its body to
$3000; MBASIC runs flat at $0100) -- the labels resolve per-build, so only the genuine code
divergences (the graphics handlers, the relocator/DISP wrapper, a few small islands) need a
conditional.

This module assembles either build and byte-diffs it against the reference .COM, which both
drives the fold construction AND serves as a relocation audit: a contiguous run of mismatches
is a code island to conditionalize, an isolated mismatch is a frozen address literal that
failed to relocate.
"""
import re
import subprocess
import tempfile
from pathlib import Path

from cpm_pipeline.basic._paths import INCLUDE_DIR, asm_path
from cpm_pipeline.filesystem import read_disk, extract_file
from cpm_pipeline import reference_data as rd

BASIC_ASM = asm_path("GBASIC").with_name("BASIC.asm")
INCLUDES = ("apple_softcard.inc", "msbasic_tokens.inc", "msbasic_errors.inc", "msbasic_fcb.inc",
            "msbasic_line.inc", "msbasic_valtyp.inc", "msbasic_strdesc.inc", "msbasic_var.inc",
            "cpm22.inc")


def assemble(mode, lst_path=None):
    """Assemble BASIC.asm as 'GBASIC' or 'MBASIC'. Returns (bytes, sjasmplus_log).

    If lst_path is given, sjasmplus also writes a listing (address + machine code +
    source per line) there. The per-build listing is the reference for line addresses
    now that the master source no longer carries inline `; $XXXX <bytes>` comments --
    and it is per-build-accurate (GBASIC body relocates to $3000, MBASIC runs flat at
    $0100), which a single inline comment could not be."""
    src = BASIC_ASM.read_text(encoding="latin-1")
    if mode == "GBASIC":
        src = "    DEFINE GBASIC\n" + src
    src = re.sub(r'SAVEBIN\s+"[^"]+"', 'SAVEBIN "{out_bin}"', src)
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        out = td / "out.bin"
        for n in INCLUDES:
            (td / n).write_text((INCLUDE_DIR / n).read_text(encoding="latin-1"),
                                encoding="latin-1")
        (td / "a.asm").write_text(src.replace("{out_bin}", out.as_posix()), encoding="utf-8")
        cmd = ["sjasmplus", str(td / "a.asm")]
        if lst_path is not None:
            cmd.append(f"--lst={Path(lst_path).resolve()}")
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(td))
        return (out.read_bytes() if out.exists() else b""), r.stdout + r.stderr


def reference(com_name):
    return bytes(extract_file(read_disk(Path(rd.DISK_2_20_44K_SYSTEM)), com_name))


def diff_regions(a, b):
    """Contiguous byte-mismatch regions between two images: [(start, end), ...] in offset."""
    regions, i, n = [], 0, min(len(a), len(b))
    while i < n:
        if a[i] == b[i]:
            i += 1
            continue
        j = i
        while j < n and a[j] != b[j]:
            j += 1
        regions.append((i, j))
        i = j
    if len(a) != len(b):
        regions.append((n, max(len(a), len(b))))
    return regions


def report():
    for mode, com in (("GBASIC", "GBASIC.COM"), ("MBASIC", "MBASIC.COM")):
        lst = BASIC_ASM.with_name(f"{mode}.lst")
        out, log = assemble(mode, lst_path=lst)
        ref = reference(com)
        errs = [l for l in log.splitlines() if "error:" in l.lower()]
        if errs:
            print(f"{mode}: {len(errs)} ASSEMBLY ERRORS (output is unreliable):")
            for l in errs[:12]:
                print("    " + l.strip()[:120])
            continue
        if not out:
            print(f"{mode}: ASSEMBLY produced no output")
            continue
        ok = out == ref
        print(f"{mode}: {len(out)}B (ref {len(ref)}B)  {'BYTE-IDENTICAL' if ok else 'DIFFERS'}")
        if lst.exists():
            print(f"    listing -> {lst.name} ({lst.stat().st_size} B)")
        if not ok:
            regs = diff_regions(out, ref)
            print(f"  {len(regs)} divergence regions; first 8:")
            for s, e in regs[:8]:
                print(f"    .COM ${s:04X}-${e:04X} (run ${0x100+s:04X})  {e-s}B")


if __name__ == "__main__":
    report()
