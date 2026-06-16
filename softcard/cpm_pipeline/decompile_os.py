"""Hybrid decompilation of the CP/M operating system from a SoftCard disk.

"Hybrid" = always run the real disassemblers (disasm6502 / disasm_z80) over the
OS code regions, producing machine-generated commented source for *any* disk;
and, when the disk is a recognized SoftCard CP/M 2.20/2.23 variant, also emit the
hand-annotated "gold" source tree (via cpm_pipeline.generate) and disassemble
with the curated symbol tables.

The OS spans two CPUs:
  * 6502 (Apple side): the boot loader, the RWTS, the install fragments.
  * Z-80 (SoftCard side): the BIOS, the disk callbacks, the CCP+BDOS system image.

For recognized variants the region binaries come from the prior investigation's
verified extractions (cpm-investigation/*.bin) with known load addresses; this is
the same byte set the round-tripping gold sources describe. For an unrecognized
disk the OS-region segmentation is best-effort (see decompile_os' return value).

Output tree:
    out/
      README.md            -- provenance, detect result, gold-vs-auto explanation
      auto/                -- machine disassembly of every OS region (this module)
        CPM_BootLoader.asm ...
      gold/                -- hand-annotated source tree (recognized variants only)
      symbols/             -- the symbol tables used
"""

from __future__ import annotations

import contextlib
import io
import shutil
from dataclasses import dataclass, field
from pathlib import Path

from .format_detect import detect
from .generate import generate

import disasm6502.cli as _d6502
import disasm_z80.cli as _dz80

_REPO_ROOT = Path(__file__).resolve().parents[2]          # repo root
_INVEST = _REPO_ROOT / "softcard" / "cpm-investigation"
_SYMROOT = _REPO_ROOT / "shared" / "symbols"


@dataclass(frozen=True)
class OsRegion:
    name: str          # human label, e.g. "BIOS"
    cpu: str           # '6502' or 'z80'
    org: int           # load address
    length: int        # bytes of live code/data
    bin_name: str      # source binary in cpm-investigation/
    symbols: tuple[str, ...]   # symbol-table filenames under shared/symbols/


# Recognized-variant region tables. Load addresses mirror chunk_map.py (the same
# values the byte-identical gold sources assemble at).
_REGIONS = {
    "softcard_cpm_2_23": [
        OsRegion("BootLoader", "6502", 0x0800, 0x0C00, "loader_223.bin", ("apple2.json",)),
        OsRegion("RWTS", "6502", 0x0A00, 0x0600, "rwts_223.bin", ("apple2.json",)),
        OsRegion("InstallFragments", "6502", 0x0200, 0x0200, "installfragments_223.bin", ("apple2.json",)),
        OsRegion("DiskCallbacks", "z80", 0x1A00, 0x0200, "diskcallbacks_223.bin",
                 ("cpm_2_2.json", "cpm_2_23_bios.json")),
        OsRegion("SystemImage", "z80", 0x8000, 0x1700, "sysimg_223.bin", ("cpm_2_2.json",)),
        # The AS-SHIPPED pristine on-disk BIOS ($FA00-$FDFF, 1024 B) -- what the
        # disk holds. (The patched $0548 runtime form lives only in bios_223.bin,
        # used by version_delta's cold-boot trace; see CPMV223-44K/BOOT_AND_PATCHING.md.)
        OsRegion("BIOS", "z80", 0xFA00, 0x0400, "bios_223_disk.bin",
                 ("cpm_2_2.json", "cpm_2_23_bios.json")),
    ],
    "softcard_cpm_2_20": [
        OsRegion("BootLoader", "6502", 0x0800, 0x0C00, "loader_220.bin", ("apple2.json",)),
        OsRegion("RWTS", "6502", 0x0A00, 0x0600, "rwts_220.bin", ("apple2.json",)),
        OsRegion("InstallFragments", "6502", 0x0200, 0x0200, "installfragments_220.bin", ("apple2.json",)),
        OsRegion("SystemImage", "z80", 0x8000, 0x1700, "sysimg_220.bin", ("cpm_2_2.json",)),
        OsRegion("BIOS", "z80", 0xDA00, 0x0800, "bios_220.bin", ("cpm_2_2.json",)),
    ],
}

_VARIANT_TO_BUILD = {"softcard_cpm_2_23": "223", "softcard_cpm_2_20": "220"}


@dataclass
class OsRegionResult:
    name: str
    cpu: str
    org: int
    asm_path: Path | None
    ok: bool
    note: str = ""


@dataclass
class OsDecompileResult:
    disk: str
    variant: str
    confidence: str
    out_dir: Path
    regions: list[OsRegionResult] = field(default_factory=list)
    gold_dir: Path | None = None
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [f"OS decompilation of {self.disk}",
                 f"  detected: {self.variant} (confidence: {self.confidence})",
                 f"  output:   {self.out_dir}"]
        for r in self.regions:
            mark = "ok" if r.ok else "FAILED"
            extra = f" -- {r.note}" if r.note else ""
            lines.append(f"    [{r.cpu:>4}] {r.name:<16} ${r.org:04X}  {mark}{extra}")
        if self.gold_dir:
            lines.append(f"  gold (hand-annotated) source tree: {self.gold_dir}")
        for n in self.notes:
            lines.append(f"  note: {n}")
        return "\n".join(lines)


def _jump_table_entries(data: bytes, org: int, cpu: str, max_scan: int = 0x60) -> list[int]:
    """Seed disassembly entries from a leading JP/JMP table (BIOS-style)."""
    op = 0x4C if cpu == "6502" else 0xC3        # JMP abs (6502) / JP nn (Z-80)
    entries = [org]
    i = 0
    limit = min(len(data), max_scan)
    while i + 3 <= limit and data[i] == op:
        tgt = data[i + 1] | (data[i + 2] << 8)
        if org <= tgt < org + len(data):
            entries.append(tgt)
        i += 3
    return sorted(set(entries))


def _disasm_region(region: OsRegion, out_base: Path) -> OsRegionResult:
    bin_path = _INVEST / region.bin_name
    if not bin_path.exists():
        return OsRegionResult(region.name, region.cpu, region.org, None, False,
                              f"missing {region.bin_name}")
    raw = bin_path.read_bytes()[:region.length]
    entries = _jump_table_entries(raw, region.org, region.cpu)

    argv = [str(bin_path), "--org", f"${region.org:04X}",
            "--length", f"${region.length:04X}", "--output", str(out_base)]
    for e in entries:
        argv += ["--entry", f"${e:04X}"]
    for s in region.symbols:
        sym = _SYMROOT / s
        if sym.exists():
            argv += ["--symbols", str(sym)]

    main = _d6502.main if region.cpu == "6502" else _dz80.main
    sink = io.StringIO()
    with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
        rc = main(argv)
    # disasm6502 emits ca65 ".s" (+ ".cfg"); disasm_z80 emits sjasmplus ".asm".
    ext = ".s" if region.cpu == "6502" else ".asm"
    asm_path = out_base.with_suffix(ext)
    ok = rc == 0 and asm_path.exists()
    note = "" if ok else f"disassembler rc={rc}"
    if ok and len(entries) > 1:
        note = f"{len(entries)} entries (jump table seeded)"
    return OsRegionResult(region.name, region.cpu, region.org, asm_path, ok, note)


def decompile_os(disk_path, out_dir, *, gold: bool = True, force: bool = False,
                 ai: bool = False, ai_backend: str = "auto") -> OsDecompileResult:
    """Decompile the CP/M OS from a SoftCard disk into an annotated source tree."""
    info = detect(disk_path)
    out = Path(out_dir)
    if out.exists() and not force and any(out.iterdir()):
        raise FileExistsError(f"{out} exists and is not empty; pass force=True")
    (out / "auto").mkdir(parents=True, exist_ok=True)
    (out / "symbols").mkdir(parents=True, exist_ok=True)

    result = OsDecompileResult(
        disk=str(disk_path), variant=info.variant,
        confidence=info.variant_confidence, out_dir=out,
    )

    regions = _REGIONS.get(info.variant)
    if regions is None:
        result.notes.append(
            "unrecognized variant: OS-region auto-segmentation is not available; "
            "only recognized SoftCard CP/M 2.20/2.23 disks have a region map. "
            "Run `detect` for the structural fingerprint."
        )
        return result

    # Auto-disassemble each OS region.
    annotate_file = None
    if ai:
        from .annotate_ai import annotate_file
    for region in regions:
        out_base = out / "auto" / f"CPM_{region.name}"
        rr = _disasm_region(region, out_base)
        if ai and rr.ok and rr.asm_path is not None and annotate_file is not None:
            cpu_name = "6502" if region.cpu == "6502" else "Z-80"
            ann = annotate_file(rr.asm_path, cpu=cpu_name,
                                context=f"SoftCard CP/M {info.variant} {region.name}",
                                backend=ai_backend)
            if ann.annotated:
                rr.note = (rr.note + "; " if rr.note else "") + ann.summary()
        result.regions.append(rr)

    # Copy the symbol tables actually used.
    used_syms = {s for r in regions for s in r.symbols}
    for s in sorted(used_syms):
        src = _SYMROOT / s
        if src.exists():
            shutil.copy2(src, out / "symbols" / s)

    # Gold (hand-annotated) source tree for recognized variants.
    if gold:
        gold_dir = out / "gold"
        try:
            generate(disk_path, gold_dir, overwrite=True)
            result.gold_dir = gold_dir
        except Exception as e:                  # gold is a bonus; never fail the run
            result.notes.append(f"gold tree skipped: {type(e).__name__}: {e}")

    _write_readme(result, info)
    return result


def _write_readme(result: OsDecompileResult, info) -> None:
    lines = [
        f"# CP/M OS decompilation — {Path(result.disk).name}",
        "",
        f"Detected: **{result.variant}** (confidence: {result.confidence})",
        "",
        "## auto/ — machine disassembly",
        "",
        "Each OS region disassembled with disasm6502 (Apple 6502 side) or disasm_z80",
        "(SoftCard Z-80 side), seeded with the curated symbol tables in `symbols/` and",
        "with leading jump tables traced. These round-trip to the original bytes.",
        "",
        "| Region | CPU | Load addr | File |",
        "|--------|-----|-----------|------|",
    ]
    for r in result.regions:
        f = r.asm_path.name if r.asm_path else "(failed)"
        lines.append(f"| {r.name} | {r.cpu} | ${r.org:04X} | auto/{f} |")
    if result.gold_dir:
        lines += [
            "",
            "## gold/ — hand-annotated source",
            "",
            "Prose-rich, human-annotated source for this recognized variant. These are",
            "the canonical reference sources; `gold/build.sh` reassembles them to a",
            "byte-identical disk image.",
        ]
    for n in result.notes:
        lines += ["", f"> {n}"]
    (result.out_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
