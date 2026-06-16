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

Every component source is now the as-SHIPPED form (the bytes on CPMV233-60K.DSK /
in CPM60.COM), so the whole 11,264-byte file is reproduced byte-for-byte with NO
post-placement transform. Spots that earlier sources had captured in their
runtime-modified form (the BIOS cold-boot self-writes, the boot loader's $1000
reset-plant target + CPU-switch arming bytes, the InstallFragments STA-$FFFF
placeholder, and the CCP stack scratch the disassembler mis-read as a pointer
table) have been reverted to as-shipped and given meaningful names + comments in
their source files; what each runtime patch does and why lives in the boot/load
patching documentation, not baked into the source.
"""
from __future__ import annotations

import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from .regenerate import _assemble_savebin

_REPO = Path(__file__).resolve().parents[2]
_60K = _REPO / "cpm-80" / "decompiled" / "CPMV233-60K"
_OS = _60K / "os"
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
    """Assemble CPM60.COM purely from the component sources placed at their COM
    offsets. Every source is the as-shipped form, so this reproduces the original
    COM byte-for-byte with no post-placement transform. Returns the 11,264-byte
    image (raises if a component fails to assemble)."""
    comp = _components()
    for k, v in comp.items():
        if not v:
            raise RuntimeError(f"component {k} failed to assemble")
    img = bytearray(COM_SIZE)
    for r in LAYOUT:
        img[r.com_off:r.com_off + r.length] = comp[r.src][r.src_off:r.src_off + r.length]
    return bytes(img)


def reference_com() -> bytes:
    """The original CPM60.COM bytes (from the byte-identical monolithic source)."""
    return _assemble_savebin(_REF_COM_ASM.read_text(encoding="utf-8"))
