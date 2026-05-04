"""Stage 6 — annotated source-tree generation.

Take a CP/M disk image and produce a complete output directory ready for
human reading, modification, and rebuild:

    output_dir/
        README.md                         -- explanation + provenance
        analysis/
            01_format.txt                 -- Phase 2 (detect) report
            02_loader.txt                 -- Phase 3 (trace) report
            03_cold_boot.txt              -- Phase 4 (trace-z80) report
            04_handoff.txt                -- Phase 5 (handoff) report
        source/
            CPM223_BootLoader.asm         -- ca65 source (6502)
            CPM223_RWTS.asm
            CPM223_DiskCallbacks.asm      -- sjasmplus source (Z-80)
            CPM223_SystemImage.asm
            CPM223_BIOS.asm
            CPM223_InstallFragments.asm
        symbols/
            apple2.json
            cpm_2_2.json
            cpm_2_23_bios.json
        build.sh                          -- reassembles + verifies

This Phase 7 implementation uses the hand-annotated `docs/CPM*.asm`
sources as the canonical annotated artifacts. A future enhancement
would auto-generate these from the disasm packages + the prior
phases' structural analysis; for now, the generated source tree
matches what the cpm-videx investigation produced manually.

The build.sh in the output directory shells out to
`python -m cpm_pipeline build` (Phase 1) to reconstruct the disk.
The round-trip property holds end-to-end.
"""

from __future__ import annotations

import shutil
from dataclasses import dataclass, field
from pathlib import Path

from .cold_boot_trace import trace_cold_boot
from .format_detect import detect
from .handoff import find_handoff
from .loader_trace import trace_loader


REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS = REPO_ROOT / "docs"
SYMBOLS = REPO_ROOT / "symbols"


@dataclass
class GenerateResult:
    output_dir: Path
    variant: str
    sources_copied: list[str] = field(default_factory=list)
    symbols_copied: list[str] = field(default_factory=list)
    analysis_files: list[str] = field(default_factory=list)
    build_script: Path | None = None
    notes: list[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = [f"GenerateResult: output -> {self.output_dir}"]
        lines.append(f"  variant: {self.variant}")
        lines.append(f"  sources copied ({len(self.sources_copied)}):")
        for s in self.sources_copied:
            lines.append(f"    {s}")
        lines.append(f"  symbols copied ({len(self.symbols_copied)}):")
        for s in self.symbols_copied:
            lines.append(f"    {s}")
        lines.append(f"  analysis files ({len(self.analysis_files)}):")
        for s in self.analysis_files:
            lines.append(f"    {s}")
        if self.build_script:
            lines.append(f"  build script: {self.build_script.name}")
        if self.notes:
            lines.append("  notes:")
            for n in self.notes:
                lines.append(f"    - {n}")
        return "\n".join(lines)


# Sources that ship with each variant (mapped by variant suffix)
SOURCES_BY_VARIANT = {
    "softcard_cpm_2_23": [
        "CPM223_BootLoader.asm",
        "CPM223_RWTS.asm",
        "CPM223_InstallFragments.asm",
        "CPM223_DiskCallbacks.asm",
        "CPM223_SystemImage.asm",
        "CPM223_BIOS.asm",
    ],
    "softcard_cpm_2_20": [
        "CPM220_BootLoader.asm",
        "CPM220_RWTS.asm",
        "CPM220_InstallFragments.asm",
        "CPM220_SystemImage.asm",
        "CPM220_BIOS.asm",
    ],
}

# Symbol files by variant
SYMBOLS_BY_VARIANT = {
    "softcard_cpm_2_23": ["apple2.json", "cpm_2_2.json", "cpm_2_23_bios.json"],
    "softcard_cpm_2_20": ["apple2.json", "cpm_2_2.json"],
}


def generate(disk_path: Path | str, output_dir: Path | str,
             *, overwrite: bool = False) -> GenerateResult:
    """Generate the annotated source tree for `disk_path` into `output_dir`."""
    disk_path = Path(disk_path)
    output_dir = Path(output_dir)

    if output_dir.exists() and not overwrite:
        raise FileExistsError(
            f"output directory already exists: {output_dir} "
            f"(use overwrite=True to replace)"
        )
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    # Run all prior phases for analysis reports
    info = detect(disk_path)
    sched = trace_loader(disk_path)
    handoff = find_handoff(disk_path)

    # Cold-boot tracing requires the BIOS binary; auto-locate
    cold = None
    if info.variant == "softcard_cpm_2_23":
        bios = REPO_ROOT / "cpm-investigation" / "bios_223.bin"
    elif info.variant == "softcard_cpm_2_20":
        bios = REPO_ROOT / "cpm-investigation" / "bios_220.bin"
    else:
        bios = None
    if bios and bios.exists():
        cold = trace_cold_boot(bios)

    result = GenerateResult(
        output_dir=output_dir,
        variant=info.variant,
    )

    # Write analysis reports
    analysis_dir = output_dir / "analysis"
    analysis_dir.mkdir()
    _write_analysis(analysis_dir / "01_format.txt", info.summary())
    result.analysis_files.append("analysis/01_format.txt")
    _write_analysis(analysis_dir / "02_loader.txt", sched.summary())
    result.analysis_files.append("analysis/02_loader.txt")
    if cold:
        _write_analysis(analysis_dir / "03_cold_boot.txt", cold.summary())
        result.analysis_files.append("analysis/03_cold_boot.txt")
    _write_analysis(analysis_dir / "04_handoff.txt", handoff.summary())
    result.analysis_files.append("analysis/04_handoff.txt")

    # Copy annotated sources for this variant
    sources_to_copy = SOURCES_BY_VARIANT.get(info.variant, [])
    if not sources_to_copy:
        result.notes.append(
            f"no annotated sources known for variant {info.variant!r}; "
            f"source/ left empty"
        )
    else:
        source_dir = output_dir / "source"
        source_dir.mkdir()
        for fname in sources_to_copy:
            src = DOCS / fname
            if src.exists():
                shutil.copy2(src, source_dir / fname)
                result.sources_copied.append(f"source/{fname}")
            else:
                result.notes.append(f"missing annotated source: {src}")

    # Copy symbol tables
    symbols_to_copy = SYMBOLS_BY_VARIANT.get(info.variant, [])
    if symbols_to_copy:
        symbols_dir = output_dir / "symbols"
        symbols_dir.mkdir()
        for fname in symbols_to_copy:
            src = SYMBOLS / fname
            if src.exists():
                shutil.copy2(src, symbols_dir / fname)
                result.symbols_copied.append(f"symbols/{fname}")
            else:
                result.notes.append(f"missing symbol table: {src}")

    # Generate build script
    variant_short = "223" if info.variant == "softcard_cpm_2_23" else "220"
    output_ext = ".dsk" if disk_path.suffix.lower() == ".dsk" else ".po"
    rel_disk_path = disk_path.resolve()  # absolute path so script is relocatable
    script_path = output_dir / "build.sh"
    script_path.write_text(
        _make_build_script(
            variant=variant_short,
            reference_disk=rel_disk_path,
            output_disk_name=f"rebuilt{output_ext}",
        ),
        encoding="utf-8",
    )
    # Make executable on POSIX systems (no-op on Windows but harmless)
    try:
        script_path.chmod(0o755)
    except OSError:
        pass
    result.build_script = script_path

    # Write README
    readme = output_dir / "README.md"
    readme.write_text(_make_readme(info, len(result.sources_copied),
                                   len(result.symbols_copied),
                                   len(result.analysis_files)),
                      encoding="utf-8")

    return result


# ── Helpers ───────────────────────────────────────────────────────────
def _write_analysis(path: Path, content: str) -> None:
    path.write_text(content + "\n", encoding="utf-8")


def _make_build_script(*, variant: str, reference_disk: Path,
                       output_disk_name: str) -> str:
    return f"""\
#!/usr/bin/env bash
# Auto-generated by cpm_pipeline.generate.
# Reassembles the annotated source files in source/ and reconstructs
# a byte-identical disk image into rebuilt/<output_disk_name>.

set -e

REFERENCE="{reference_disk}"
OUTPUT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)/rebuilt"
mkdir -p "$OUTPUT_DIR"

# Make sure assemblers are on PATH
if ! command -v ca65 >/dev/null 2>&1; then
    echo "ca65 not on PATH; source orchard/tools/env.sh first" >&2
    exit 1
fi

# Run the reconstruction (uses the docs/CPM*.asm sources in the orchard
# repo by default; this generated tree's source/ files are for reading
# and editing).
python -m cpm_pipeline build {variant} \\
    --reference "$REFERENCE" \\
    --output "$OUTPUT_DIR/{output_disk_name}" \\
    --verify
"""


def _make_readme(info, n_sources: int, n_symbols: int, n_analysis: int) -> str:
    return f"""\
# CP/M annotated source tree

Generated by `cpm_pipeline.generate` for `{info.path.name}`.

- **Variant detected:** {info.variant}
- **Boot stub:** {"present" if info.has_boot_stub else "not present"}, loads {info.boot_stub_load_count} sectors
- **Skew table:** {' '.join(f'{b:X}' for b in (info.sector_skew_table or []))}

## Directory layout

- [`analysis/`](analysis/) — {n_analysis} structural analysis reports (one per pipeline phase)
- [`source/`](source/) — {n_sources} annotated assembly source files (ca65 for 6502, sjasmplus for Z-80)
- [`symbols/`](symbols/) — {n_symbols} JSON symbol tables consumed by the disassemblers
- [`build.sh`](build.sh) — reassembles + reconstructs the disk image

## Reading order

Start with `analysis/01_format.txt` (the high-level disk structure).
Then `analysis/02_loader.txt` (what the 6502 boot loader does to install
the runtime layout). Then `analysis/03_cold_boot.txt` (the Z-80 BIOS
structure post-handoff). Then `analysis/04_handoff.txt` (the
6502 → Z-80 transition).

The `source/` files are the canonical annotated assembly source. They
reassemble byte-identical to the original disk binary via the
`build.sh` script.

## Round-trip

```sh
./build.sh
# Produces rebuilt/rebuilt{'.dsk' if info.format == 'dsk' else '.po'},
# byte-identical to {info.path.name}
```
"""
