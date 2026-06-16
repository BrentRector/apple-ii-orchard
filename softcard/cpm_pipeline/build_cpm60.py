"""Build CPM60.COM byte-identically from a single master assembler source.

CPM60.COM (11,264 bytes) is the Microsoft 60K-update installer: a Z-80 driver
at $0100 followed by the embedded 60K system image it writes to a disk's system
tracks. The image pieces live at fixed offsets inside the .COM but RUN at other
addresses -- the CCP/BDOS/BIOS run high, inside the language card.

The canonical build assembles ONE master source, ``CPMV223-60K/CPM60.asm``,
which places every piece at its .COM file offset while assembling the relocating
Z-80 modules as real code at their run address via ``DISP ... ENT`` (so their
labels resolve correctly) -- the same technique GBASIC.COM's interpreter uses.
CPM60.COM is mixed-CPU, so the 6502 pieces (boot loader / RWTS / install
fragments, ca65) are ``INCBIN``'d from their assembled binaries; the Z-80 modules
are ``INCLUDE``d from their canonical sources, each wrapped in a MODULE and
bracketing its own DEVICE/ORG/SAVEBIN behind ``IFNDEF CPM60_LINK``.

Every source is the as-shipped form, so the master reproduces the original
CPM60.COM (the file on CPMV223-44K.DSK) byte-for-byte with no post-placement
transform. ``build_cpm60_com_via_layout`` is an independent cross-check that
concatenates the separately assembled components per a Python layout table;
both methods must equal ``reference_com`` (the genuine file extracted from the
disk image). Runtime boot/load patching is documented in BOOT_AND_PATCHING.md,
not baked into the source.
"""
from __future__ import annotations

import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from .filesystem import extract_file, read_disk
from .regenerate import _assemble_savebin

_REPO = Path(__file__).resolve().parents[2]
_60K = _REPO / "softcard" / "CPMV223-60K"
_OS = _60K / "os"
_DISK = _REPO / "softcard" / "CPMV223-44K" / "CPMV223-44K.DSK"
_SJASMPLUS = _REPO / "shared" / "toolchain" / "sjasmplus" / "sjasmplus-1.23.0.win" / "sjasmplus.exe"

COM_SIZE = 0x2C00

# the 6502 (ca65) pieces the master INCBINs, keyed by the binary name it expects
_SIX = {
    "CPM_BootLoader.bin": _OS / "CPM_BootLoader.s",
    "CPM_RWTS.bin": _OS / "CPM_RWTS.s",
    "CPM_InstallFragments.bin": _OS / "CPM_InstallFragments.s",
}


def _sjasmplus() -> str:
    """sjasmplus on PATH if present, else the bundled toolchain copy."""
    return "sjasmplus" if shutil.which("sjasmplus") else str(_SJASMPLUS)


def _assemble_6502(s_path: Path, out_bin: Path) -> bool:
    """ca65 + ld65 a 6502 component (with its sibling .cfg) to a flat binary."""
    cfg = s_path.with_suffix(".cfg")
    obj = out_bin.with_suffix(".o")
    if subprocess.run(["ca65", str(s_path), "-o", str(obj)],
                      capture_output=True, text=True).returncode:
        return False
    subprocess.run(["ld65", "-C", str(cfg), "-o", str(out_bin), str(obj)],
                   capture_output=True, text=True)
    return out_bin.exists()


def build_cpm60_com() -> bytes:
    """Assemble CPM60.COM from the single master source ``CPM60.asm``.

    Stages the Z-80 sources and the ca65-assembled 6502 binaries into a temp
    dir, runs sjasmplus on the master, and returns the 11,264-byte image. Raises
    if a 6502 piece or the master fails to assemble.
    """
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        (td / "os").mkdir()
        shutil.copy(_60K / "CPM60.asm", td / "CPM60.asm")
        shutil.copy(_60K / "CPM60_installer.asm", td / "CPM60_installer.asm")
        for name in ("CPM_CCP.asm", "CPM_BDOS.asm", "CPM_BIOS.asm"):
            shutil.copy(_OS / name, td / "os" / name)
        for bin_name, src in _SIX.items():
            if not _assemble_6502(src, td / bin_name):
                raise RuntimeError(f"ca65 failed to assemble {src.name}")
        result = subprocess.run([_sjasmplus(), "CPM60.asm"], cwd=str(td),
                                capture_output=True, text=True)
        out = td / "CPM60.COM"
        if not out.exists():
            raise RuntimeError(f"sjasmplus failed on CPM60.asm:\n{result.stdout}{result.stderr}")
        return out.read_bytes()


# --------------------------------------------------------------------------
# Independent cross-check: concatenate separately assembled components per a
# Python layout table. Same result as the master, derived a different way.
# --------------------------------------------------------------------------

@dataclass(frozen=True)
class _Region:
    com_off: int       # offset in CPM60.COM
    src: str           # component key
    src_off: int       # start within the assembled component
    length: int        # bytes to copy


LAYOUT = [
    _Region(0x0000, "installer", 0x000, 0x261),
    _Region(0x0300, "bootloader", 0x000, 0x100),   # $0800 page
    _Region(0x0400, "rwts",       0x000, 0x5BD),
    _Region(0x0A00, "bootloader", 0x800, 0x1F2),   # $1000 reloc page
    _Region(0x0D80, "frag",       0x180, 0x080),   # InstallFragments $0380 slice
    _Region(0x0E00, "ccp",        0x000, 0x906),
    _Region(0x1700, "bdos",       0x000, 0xE00),    # overwrites CCP's 6-byte serial tail
    _Region(0x2600, "bios",       0x000, 0x600),
]


def _components() -> dict[str, bytes]:
    z = lambda p: _assemble_savebin(p.read_text(encoding="utf-8"))
    out_bins: dict[str, bytes] = {}
    with tempfile.TemporaryDirectory() as tds:
        td = Path(tds)
        six = {"bootloader": _OS / "CPM_BootLoader.s",
               "rwts": _OS / "CPM_RWTS.s",
               "frag": _OS / "CPM_InstallFragments.s"}
        for key, src in six.items():
            ob = td / f"{key}.bin"
            out_bins[key] = ob.read_bytes() if _assemble_6502(src, ob) else b""
    return {
        "installer":  z(_60K / "CPM60_installer.asm"),
        "ccp":        z(_OS / "CPM_CCP.asm"),
        "bdos":       z(_OS / "CPM_BDOS.asm"),
        "bios":       z(_OS / "CPM_BIOS.asm"),       # the unpatched template
        **out_bins,
    }


def build_cpm60_com_via_layout() -> bytes:
    """Independent cross-check of :func:`build_cpm60_com`: assemble each
    component on its own and place it at its COM offset per ``LAYOUT``."""
    comp = _components()
    for k, v in comp.items():
        if not v:
            raise RuntimeError(f"component {k} failed to assemble")
    img = bytearray(COM_SIZE)
    for r in LAYOUT:
        img[r.com_off:r.com_off + r.length] = comp[r.src][r.src_off:r.src_off + r.length]
    return bytes(img)


def reference_com() -> bytes:
    """The genuine CPM60.COM, extracted from CPMV223-44K.DSK."""
    return bytes(extract_file(read_disk(_DISK), "CPM60.COM"))
