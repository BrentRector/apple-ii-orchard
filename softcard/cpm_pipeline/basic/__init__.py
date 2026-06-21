"""BASIC regeneration tooling (2.20-44K GBASIC / MBASIC).

Reproduces the byte-identical, semantically-named GBASIC.asm and MBASIC.asm from
the on-disk .COM bytes plus committed companion artifacts (the *.seeds.json
coverage seeds and *.overlay.json naming overlays). Run as modules, e.g.:

    source shared/toolchain/env.sh      # puts the packages + assembler on PATH
    python -m cpm_pipeline.basic.gen_gbasic            # decode -> base GBASIC.asm
    python -m cpm_pipeline.basic.apply_naming \
        softcard/CPMV220-44K/utilities/GBASIC.overlay.json --write   # enrich

`gen_gbasic` / `gen_mbasic` produce the machine-label BASE decode; `apply_naming`
applies the naming/comment/operand-rewrite overlay (verifying byte-identical by
reassembly); `map_gbasic_to_mbasic` transfers GBASIC's names to MBASIC by
structural correspondence and regenerates MBASIC's overlay + seeds.
"""
