# cpm_pipeline

The CP/M reverse-engineering pipeline. Implements the seven-stage roadmap
in [`docs/CPM_PIPELINE_ROADMAP.md`](../docs/CPM_PIPELINE_ROADMAP.md)
incrementally. Phase 1 (this initial version) ships **Stage 7 — `.dsk`
reconstruction**.

## What's working

**Phase 1 — Stage 7: `.dsk` reconstruction.** Take the eleven hand-
annotated source files in `docs/`, assemble them fresh, place each
assembled binary at its original physical-sector position on disk, and
produce a `.dsk` (or `.po`) image that's byte-identical to the original.

**Phase 2 — Stage 1: disk-format detection.** Inspect a raw disk image,
identify the boot stub (if any), extract the sector skew table the boot
stub uses, classify the CP/M variant by signature.

**Phase 3 — Stage 2: boot-loader tracing.** Pattern-match stage-2 for
install-copy loops (`LDA src,Y / STA dst,Y / DEY / BNE`) and disk-helper
calls (`JSR $BB__` for 2.23, `JSR $0E__/$0F__` for 2.20), output a
structured `LoadSchedule`.

**Phase 4 — Stage 5: Z-80 cold-boot tracing.** Take a Z-80 BIOS binary
and structurally identify the 17-entry jump table, the trap-marker
pages (runtime-populated), the cold-boot generator routine, and its
per-device dispatch cases. The Videx-fix discriminator surfaces
mechanically: 2.23 has dispatch cases for devices 3, 4, **6**; 2.20
lacks the device-6 case.

**Phase 5 — Stage 4: handoff identification.** Find the three handoff
signals between 6502 and Z-80: the Z-80 reset vector plant (`STA
$1000` after `LDA #$C3`, with auto-detection of the planted target),
the BDOS entry vector plant (done by the Z-80 BIOS), and the
CPU-switch trigger (`JSR $0E36` in 2.23, `JSR $C400` in 2.20).

**Phase 6 — Stage 3: version delta detection.** Compare two CP/M disks
at the routine level. Variant difference, boot-stub byte diff (split
into code-region vs data-region), reset/BDOS/CPU-switch target
deltas, dispatch case deltas (which device codes only appear in one).
Mechanically reproduces what `docs/CPM_Videx_Difference.md`
documents manually.

**Phase 7 — Stage 6: annotated source-tree generation.** End-to-end
orchestration. Take a `.dsk`/`.po` and produce a complete output
directory containing analysis reports from Phases 2-5, the annotated
assembly source files, the symbol tables, a build script, and a
README. The build script reassembles to a byte-identical disk via
Phase 1.

```sh
source ../tools/env.sh   # ca65 + ld65 + sjasmplus on PATH

# Inspect any disk and report what it looks like
python -m cpm_pipeline detect ../CPMV233.DSK
# → CPMV233.DSK: DSK format, 143360 bytes (35T x 16S x 256B)
#     boot stub: count=1, loads 10 sectors of track 0
#     skew table: 0 2 4 6 8 A C E 1 3 5 7 9 B D F
#     variant: softcard_cpm_2_23 (confidence: high)

# Build the disk; auto-detect variant from the reference
python -m cpm_pipeline build \
    --reference ../CPMV233.DSK \
    --output ../build/cpm223_rebuilt.dsk \
    --verify
# → auto-detected variant: 223 (confidence: high)
# → wrote ../build/cpm223_rebuilt.dsk
# → BYTE-IDENTICAL to ../CPMV233.DSK

# Or pin the variant explicitly:
python -m cpm_pipeline build 220 \
    --reference ../CPM220Disk1.po \
    --output ../build/cpm220_rebuilt.po \
    --verify
# → BYTE-IDENTICAL to ../CPM220Disk1.po

# End-to-end: take a disk, produce a complete annotated source tree
python -m cpm_pipeline generate ../CPMV233.DSK ../build/cpm223_tree
# → output_dir/{README.md, analysis/, source/, symbols/, build.sh}
# Then:
bash ../build/cpm223_tree/build.sh
# → wrote rebuilt.dsk; BYTE-IDENTICAL to CPMV233.DSK

# Trace the Z-80 BIOS -- jump table, fill regions, cold-boot generator
python -m cpm_pipeline trace-z80 ../cpm-investigation/bios_223.bin
# → ColdBootSchedule for bios_223.bin
#     BIOS org: $FA00, size: 1352 bytes   (true base; was $FAB8 pre-2026-06-11)
#     jump table: 17 entries  (BOOT -> $FED1, WBOOT -> $FAB8, ...)
#     fill-pattern regions: 6   (load-image filler, not runtime placeholders)
#     cold-boot generator at $FA85
#     dispatch cases: 3
#       device 3 -> CALL $FE81
#       device 4 -> CALL $FD83
#       device 6 -> CALL $FDB0   (INIT_PASCAL_1_1, the 2.23 Videx fix)

# Same for 2.20 -- only 2 dispatch cases (no device 6)
python -m cpm_pipeline trace-z80 ../cpm-investigation/bios_220.bin
# → dispatch cases: 2
#     device 3 -> CALL $DD60
#     device 4 -> CALL $DCEE

# Trace the boot loader -- install-copy loops and disk-helper calls
python -m cpm_pipeline trace ../CPMV233.DSK
# → LoadSchedule for CPMV233.DSK
#     variant: softcard_cpm_2_23
#     stage-2 entry: $1000
#     boot-stub-loaded sectors: 10  (each $0XX0 <- trk0:physN)
#     install-copy loops: 4
#       $11B0-$11BD -> $0FFF-$100C  (14 bytes; loop at $1039)
#       $12FF-$13EF -> $02FF-$03EF  (241 bytes; loop at $104D)  ← page-2/3 install
#       $13EF-$13FE -> $03EF-$03FE  (16 bytes; loop at $10EF)
#       $116C-$1171 -> $FFF9-$FFFE  (6 bytes; loop at $1140)    ← reset-vector patch
#     disk-helper calls (LOAD_CPM-class): 1
#       $111E: JSR $BBEB  (A=$80)
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
| [`format_detect.py`](format_detect.py) | Stage 1 — structural detection: boot-stub fingerprint, skew table extraction, CP/M variant identification |
| [`loader_trace.py`](loader_trace.py) | Stage 2 — boot-loader tracing: install-copy loops + disk-helper call detection; outputs a `LoadSchedule` |
| [`cold_boot_trace.py`](cold_boot_trace.py) | Stage 5 — Z-80 cold-boot tracing: BIOS jump table + trap-marker pages + cold-boot generator + dispatch cases; outputs a `ColdBootSchedule` |
| [`handoff.py`](handoff.py) | Stage 4 — handoff identification: Z-80 reset vector plant, BDOS entry vector plant, CPU-switch trigger; outputs a `HandoffInfo` |
| [`version_delta.py`](version_delta.py) | Stage 3 — version delta detection: routine-level diff between two CP/M disks; outputs a `DiskDelta` |
| [`generate.py`](generate.py) | Stage 6 — annotated source-tree generation: end-to-end orchestration that produces a complete output directory with analysis + sources + build script |
| [`assemble.py`](assemble.py) | Wraps ca65/ld65 (6502) and sjasmplus (Z-80) for `docs/CPM*.asm` files; returns byte content |
| [`chunk_map.py`](chunk_map.py) | The `(source_binary, byte_range, track, sector)` mappings for 2.20 + 2.23 |
| [`reconstruct.py`](reconstruct.py) | Orchestrator: assemble all → place per chunk map → write disk → optionally verify |
| [`cli.py`](cli.py) | `python -m cpm_pipeline {detect\|trace\|trace-z80\|handoff\|diff\|generate\|build} ...` |
| [`tests/`](tests/) | pytest: format primitives + detection + tracing + end-to-end round-trip |

## Roadmap status

Per the [seven-stage roadmap](../docs/CPM_PIPELINE_ROADMAP.md):

| Stage | Description | Status |
|---|---|---|
| **1** | **Disk-format detection** | **Phase 2 — DONE: structural detection of boot stub, skew table, variant** |
| **2** | **Boot-loader tracing** | **Phase 3 — DONE: install-copy loops + disk-helper calls auto-detected** |
| **3** | **Version delta detection** | **Phase 6 — DONE: structured diff covering variant + boot-stub bytes + reset/BDOS/CPU-switch + dispatch cases** |
| **4** | **Handoff identification** | **Phase 5 — DONE: Z-80 reset vector + BDOS entry + CPU-switch trigger auto-detected for both 2.20 and 2.23** |
| **5** | **Z-80 cold-boot tracing** | **Phase 4 — DONE: jump table + trap markers + cold-boot generator + dispatch cases** |
| **6** | **Annotated source generation** | **Phase 7 — DONE: end-to-end orchestration into a complete output tree** |
| **7** | **`.dsk` reconstruction** | **Phase 1 — DONE for 2.20 + 2.23** |

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
