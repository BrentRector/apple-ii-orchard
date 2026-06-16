"""Build CPM60.COM byte-identically from its component sources.

CPM60.COM (11,264 bytes) is the Microsoft 60K-update installer: a Z-80 driver
followed by the embedded 60K system image it writes to a disk's system tracks.
This assembles that image from the checked-in component sources and verifies the
result equals the original COM byte-for-byte.

The whole file but 38 bytes comes straight from the component sources placed at
their COM offsets:

    COM 0x000  installer driver   CPM60_installer.asm   ($0100)
    COM 0x300  boot loader $0800   os/CPM_BootLoader.s    (page slice)
    COM 0x400  RWTS driver         os/CPM_RWTS.s
    COM 0xA00  boot loader $1000   os/CPM_BootLoader.s    (reloc page)
    COM 0xD80  InstallFragments    os/CPM_InstallFragments.s ($0380 slice)
    COM 0xE00  CCP                 os/CPM_CCP.asm         ($D300)
    COM 0x1700 BDOS                os/CPM_BDOS.asm        ($DC00)
    COM 0x2600 BIOS *template*     os/CPM_BIOS.asm        ($FA00, unpatched)

The BIOS is the unpatched template -- exactly the form shipped in the COM -- so
it places with zero patching, like the BDOS and RWTS.

The remaining 38 bytes are NOT a mystery: our os/ components were recovered from
a *booted memory image*, so they are the RUNTIME forms (self-modified, relocated,
sysgen-filled), while the COM holds the as-ASSEMBLED form. Each of the 38 bytes
is one known install/boot mutation, grouped and explained in cpm60_asbuilt.json:
the boot loader's $1000 LC-handoff glue (the loader overwrites it with its entry
+ the planted Z-80 reset stub), two boot self-patches, the UNRELOCATED
InstallFragments placeholders (the relocator rewrites `STA $FFFF`/zeroed address
cells), and the CCP sysgen pointer cells (zero as-shipped, filled at install).
build_cpm60_com() applies these to undo the runtime mutations.
"""
from __future__ import annotations

import json
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from .regenerate import _assemble_savebin

_REPO = Path(__file__).resolve().parents[2]
_60K = _REPO / "cpm-80" / "decompiled" / "CPMV233-60K"
_OS = _60K / "os"
_ASBUILT = _60K / "cpm60_asbuilt.json"
# the reference COM: the monolithic decompiled installer, byte-identical to the
# original file. Used only to verify the component build.
_REF_COM_ASM = _REPO / "cpm-80" / "decompiled" / "CPMV233" / "utilities" / "CPM60.asm"

COM_SIZE = 0x2C00


@dataclass(frozen=True)
class _Region:
    com_off: int       # offset in CPM60.COM
    src: str           # component key
    src_off: int       # start within the assembled component
    length: int        # bytes to copy


# component layout (all but the 38 documented as-shipped bytes)
LAYOUT = [
    _Region(0x0000, "installer", 0x000, 0x261),
    _Region(0x0300, "bootloader", 0x000, 0x100),   # $0800 page
    _Region(0x0400, "rwts",       0x000, 0x5BD),
    _Region(0x0A00, "bootloader", 0x800, 0x1F2),   # $1000 reloc page
    _Region(0x0D80, "frag",       0x180, 0x080),   # InstallFragments $0380 slice
    _Region(0x0E00, "ccp",        0x000, 0x906),
    _Region(0x1700, "bdos",       0x000, 0xE00),
    _Region(0x2600, "bios",       0x000, 0x600),
]


def _assemble_6502(s_path: Path) -> bytes:
    """ca65 + ld65 a 6502 component (with its sibling .cfg) to a flat binary."""
    cfg = s_path.with_suffix(".cfg")
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        obj, out = td / "a.o", td / "a.bin"
        if subprocess.run(["ca65", str(s_path), "-o", str(obj)],
                          capture_output=True, text=True).returncode:
            return b""
        subprocess.run(["ld65", "-C", str(cfg), "-o", str(out), str(obj)],
                       capture_output=True, text=True)
        return out.read_bytes() if out.exists() else b""


def _components() -> dict[str, bytes]:
    z = lambda p: _assemble_savebin(p.read_text(encoding="utf-8"))
    return {
        "installer":  z(_60K / "CPM60_installer.asm"),
        "ccp":        z(_OS / "CPM_CCP.asm"),
        "bdos":       z(_OS / "CPM_BDOS.asm"),
        "bios":       z(_OS / "CPM_BIOS.asm"),       # the unpatched template
        "bootloader": _assemble_6502(_OS / "CPM_BootLoader.s"),
        "rwts":       _assemble_6502(_OS / "CPM_RWTS.s"),
        "frag":       _assemble_6502(_OS / "CPM_InstallFragments.s"),
    }


def build_cpm60_com() -> bytes:
    """Assemble CPM60.COM from the component sources, then undo the runtime
    mutations our (booted-image-recovered) sources captured by applying the
    documented as-shipped bytes (cpm60_asbuilt.json). Returns the 11,264-byte
    image (raises if a component fails to assemble)."""
    comp = _components()
    for k, v in comp.items():
        if not v:
            raise RuntimeError(f"component {k} failed to assemble")
    img = bytearray(COM_SIZE)
    for r in LAYOUT:
        img[r.com_off:r.com_off + r.length] = comp[r.src][r.src_off:r.src_off + r.length]
    asbuilt = json.loads(_ASBUILT.read_text(encoding="utf-8"))["bytes"]
    for off_hex, byte_hex in asbuilt.items():
        img[int(off_hex, 16)] = int(byte_hex, 16)
    return bytes(img)


def reference_com() -> bytes:
    """The original CPM60.COM bytes (from the byte-identical monolithic source)."""
    return _assemble_savebin(_REF_COM_ASM.read_text(encoding="utf-8"))
