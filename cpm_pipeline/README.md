# cpm_pipeline

The CP/M reverse-engineering pipeline. Implements the seven-stage roadmap
in [`docs/CPM_PIPELINE_ROADMAP.md`](../docs/CPM_PIPELINE_ROADMAP.md)
incrementally. Phase 1 (this initial version) ships **Stage 7 — `.dsk`
reconstruction**.

## Phase 1 — what's working

Take the eleven hand-annotated source files in `docs/`, assemble them
fresh, place each assembled binary at its original physical-sector
position on disk, and produce a `.dsk` (or `.po`) image that's
byte-identical to the original.

```sh
source ../tools/env.sh   # ca65 + ld65 + sjasmplus on PATH

# Reconstruct CPMV233.DSK from docs/CPM223_*.asm
python -m cpm_pipeline build 223 \
    --reference ../CPMV233.DSK \
    --output ../build/cpm223_rebuilt.dsk \
    --verify
# → "BYTE-IDENTICAL to ../CPMV233.DSK"

# Same for CP/M 2.20 (the .po-format disk)
python -m cpm_pipeline build 220 \
    --reference ../CPM220Disk1.po \
    --output ../build/cpm220_rebuilt.po \
    --verify
# → "BYTE-IDENTICAL to ../CPM220Disk1.po"
```

What this means: editing a comment in `docs/CPM223_BIOS.asm` and rerunning
the build produces a verified rebuilt disk. The round-trip property holds
end-to-end, from prose annotation through assembled binaries through
final disk image.

Coverage today (2.23):
- **2,816 bytes** (27.5% of the disk's used regions) come from freshly
  assembled `docs/CPM223_*.asm`.
- **7,424 bytes** still come from pre-extracted `cpm-investigation/staging_223.bin`
  (the 29-sector LOAD_CPM staging area, which isn't yet split into
  per-`.asm` regions).
- The remaining ~134 KB of the 143 KB disk is the CP/M filesystem on
  tracks 3+, copied verbatim from the reference image.

A future Phase (Stage 2 of the roadmap) will derive the chunk map
automatically from boot-loader tracing, and a future split of the
staging region into per-`.asm` files will increase the assembled-bytes
coverage.

## Modules

| File | Purpose |
|---|---|
| [`disk_format.py`](disk_format.py) | DOS 3.3 vs ProDOS interleave; sector → file offset math; .dsk/.po format detection |
| [`assemble.py`](assemble.py) | Wraps ca65/ld65 (6502) and sjasmplus (Z-80) for `docs/CPM*.asm` files; returns byte content |
| [`chunk_map.py`](chunk_map.py) | The `(source_binary, byte_range, track, sector)` mappings for 2.20 + 2.23 |
| [`reconstruct.py`](reconstruct.py) | Orchestrator: assemble all → place per chunk map → write disk → optionally verify |
| [`cli.py`](cli.py) | `python -m cpm_pipeline build {220\|223} --reference ... --output ... [--verify]` |
| [`tests/`](tests/) | pytest: format primitives + end-to-end round-trip for both disks |

## Roadmap status

Per the [seven-stage roadmap](../docs/CPM_PIPELINE_ROADMAP.md):

| Stage | Description | Status |
|---|---|---|
| 1 | Disk-format detection | nibbler has the components; not yet a Stage 1 module here |
| 2 | Boot-loader tracing | manual today (chunk map hand-listed) |
| 3 | Version delta detection | manual today |
| 4 | Handoff identification | manual today |
| 5 | Z-80 cold-boot tracing | manual today |
| 6 | Annotated source generation | disasm6502 + disasm_z80 + symbols handle this per-chunk |
| **7** | **`.dsk` reconstruction** | **Phase 1 (this) — DONE for 2.20 + 2.23** |

## Architectural notes

**No nibbler dependency** for Stage 7 — only needs the assembler
subprocess calls, file-format math, and the `disasm6502` /`disasm_z80`
sources don't actually run here (we just consume their already-edited
output). This keeps Stage 7 cleanly factored from the disk-reading
machinery, which is logically the inverse direction.

**`cwd` matters for ca65 `.incbin`.** The `docs/CPM*.asm` sources use
`.incbin "cpm-investigation/loader_XXX.bin", offset, size` to pull
binary content for regions that aren't hand-annotated. ca65 resolves
these paths relative to the current working directory, so the
reconstructor sets `cwd=repo_root` when assembling. This is documented
in [`assemble.py`](assemble.py).

**Chunk map gotcha:** the boot stub doesn't load the boot sector
itself (P6 PROM does), and Apple memory `$0900-$09FF` is a P6 PROM
workspace gap that's never loaded. The chunk map for the boot-loader
region uses explicit `(physical_sector, apple_address)` pairs rather
than computing offsets sequentially — the latter would put the
install-fragment source bytes at the wrong sector position.
