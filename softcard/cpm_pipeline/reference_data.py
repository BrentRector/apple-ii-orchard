"""Canonical reference disk images for the SoftCard CP/M pipeline.

SINGLE SOURCE OF TRUTH for test-data and build-reference disk paths. Tests and
build code import the named constants below instead of hard-coding paths, so
moving or renaming a disk image touches only this file.

Original distribution media live in the version-controlled canonical archive
(``reference/softcard-cpm-archive/``) under their true version/config names.
Reconstructed/derived artifacts (the 60K system, emulator variants) are NOT
original media and live alongside their per-release source tree.

Naming: ``DISK_<version>_<config>_<role>``. ``2_20`` / ``2_20B`` / ``2_23`` are
the CP/M releases; ``44K`` / ``56K`` / ``60K`` the memory configuration.
"""

from __future__ import annotations

from pathlib import Path

# softcard/  (this file is softcard/cpm_pipeline/reference_data.py)
SOFTCARD_ROOT = Path(__file__).resolve().parent.parent
ARCHIVE = SOFTCARD_ROOT / "reference" / "softcard-cpm-archive"
_ARCHIVE_OS = ARCHIVE / "os"
_ARCHIVE_UTIL = ARCHIVE / "utilities"

# Extracted intermediate binaries (BIOS images, etc.) used by the detectors.
INVEST = SOFTCARD_ROOT / "cpm-investigation"

# --- Original distribution media (canonical, from the tracked archive) ---

#: CP/M 2.20, 44K, original 1980 release -- the canonical 2.20 reference.
DISK_2_20_44K_SYSTEM = _ARCHIVE_OS / "softcard-cpm2.20-44k-system-1980.dsk"

#: CP/M 2.20B, 56K (Language Card) system disk 1. This is what the CPMV220/os
#: source tree reconstructs byte-identically (the repo's "2.20" build target).
DISK_2_20B_56K_SYSTEM = _ARCHIVE_OS / "softcard-cpm2.20b-56k-system-disk1.po"

#: CP/M 2.20B, 56K tools disk 2.
DISK_2_20B_56K_TOOLS = _ARCHIVE_UTIL / "softcard-cpm2.20b-56k-tools-disk2.po"

#: CP/M 2.23, 44K -- the canonical 2.23 reference (CPMV223-44K/os reconstructs it).
DISK_2_23_44K_SYSTEM = _ARCHIVE_OS / "softcard-cpm2.23-44k-system.dsk"

# --- Derived / reconstructed artifacts (NOT original media) ---

#: CP/M 2.23, 60K -- reconstructed from the CPMV223-60K/os source tree.
DISK_2_23_60K_SYSTEM = SOFTCARD_ROOT / "CPMV223-60K" / "CPMV223-60K.DSK"

#: CP/M 2.23, 60K emulator variant.
DISK_2_23_60K_EMU = SOFTCARD_ROOT / "CPMV223-60K" / "CPMV223-60K-EMU.DSK"


def present(*paths: Path) -> bool:
    """True iff every given reference disk exists on disk.

    Use in a single, central skip guard rather than scattering path-existence
    string checks through the tests -- if a committed fixture is ever missing,
    the whole data-dependent set skips with one obvious reason instead of
    masking individual failures.
    """
    return all(Path(p).exists() for p in paths)


#: SoftCard CP/M variant id -> extracted BIOS binary filename in cpm-investigation/.
_BIOS_BIN = {
    "softcard_cpm_2_23": "bios_223.bin",
    "softcard_cpm_2_20": "bios_220.bin",
}


def bios_bin(variant: str) -> Path | None:
    """Extracted BIOS binary for a SoftCard CP/M variant, or None if unknown/absent.

    Located relative to THIS package (cpm-investigation/), never relative to a
    disk image -- so BIOS-dependent detectors (handoff, version delta, cold-boot
    trace) work no matter where the disk lives (per-release tree or archive).
    """
    name = _BIOS_BIN.get(variant)
    if name is None:
        return None
    p = INVEST / name
    return p if p.exists() else None
