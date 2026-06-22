#!/usr/bin/env python
"""Generate BASIC.asm (the GBASIC/MBASIC fold master) from GBASIC.asm + conditional patches.

BASIC.asm is GBASIC.asm with `IFDEF GBASIC` conditionals around the build divergences (the
relocator/DISP wrapper, the hi-res graphics block, the hi-res dispatch slots + not-implemented
stub, the trailing padding, the SAVEBIN size). GENERATING it -- rather than keeping a static
copy -- keeps it in lockstep as GBASIC.asm is regenerated: a GBASIC decode fix (e.g. pinning
the sign-on banner as data) ripples through preceding label refs AND the trailing fill render,
so a hand-copied BASIC.asm silently drifts. Run after gen_gbasic.

Each patch asserts its anchor occurs exactly once, so a drift that moves an anchor fails loudly
instead of producing a wrong master.
"""
from cpm_pipeline.basic._paths import asm_path


_PATCHES = [
    # 1) entry vector: GBASIC jumps to the relocator, MBASIC straight to cold start
    ("        JP RELOCATE_AND_RUN              ; $0100  C3 00 10",
     "    IFDEF GBASIC\n"
     "        JP RELOCATE_AND_RUN              ; $0100  C3 00 10  (GBASIC: relocate body to $3000 first)\n"
     "    ELSE\n"
     "        JP COLD_START                    ; $0100  (MBASIC: runs in place, jump straight to cold start)\n"
     "    ENDIF"),
    # 2) hi-res statement dispatch slots: real handlers (GBASIC) vs the not-impl stub (MBASIC)
    ("        DEFW    GFX_STMT_HGR             ; $01A8\n"
     "        DEFW    GFX_STMT_HPLOT           ; $01AA\n"
     "        DEFW    GFX_STMT_HCOLOR          ; $01AC",
     "    IFDEF GBASIC\n"
     "        DEFW    GFX_STMT_HGR             ; $01A8\n"
     "        DEFW    GFX_STMT_HPLOT           ; $01AA\n"
     "        DEFW    GFX_STMT_HCOLOR          ; $01AC\n"
     "    ELSE\n"
     "        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $01A8  HGR   -> not-implemented stub\n"
     "        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $01AA  HPLOT -> not-implemented stub\n"
     "        DEFW    RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $01AC  HCOLOR-> not-implemented stub\n"
     "    ENDIF"),
    # 3a) start the relocator wrapper after the last shared low-RAM routine
    ("        RET                              ; $0FF7  C9\n"
     "        DEFS    8, $00                   ; $0FF8  fill",
     "        RET                              ; $0FF7  C9\n"
     "    IFDEF GBASIC\n"
     "        DEFS    8, $00                   ; $0FF8  fill"),
    # 3b) close it after DISP (MBASIC has no relocator/DISP; the body runs in place)
    ("    DISP $3000               ; runs at $3000 (the $1000 relocator LDDRs it up, then JP $81D3)\n"
     "INTERP_RUN_START:",
     "    DISP $3000               ; runs at $3000 (the $1000 relocator LDDRs it up, then JP $81D3)\n"
     "    ENDIF\n"
     "INTERP_RUN_START:"),
    # 4a) open the graphics-handler block (GBASIC only)
    ("; [RE] Current hi-res plot color/mode index. Set by COLOR=/HCOLOR= (GFX_SET_COLOR_INDEX $4847); "
     "read by GFX_SELECT_COLOR_MASK ($4A91) and the SCRN color read to pick the bit-pattern mask.\n"
     "GFX_COLOR_INDEX:",
     "    IFDEF GBASIC\n"
     "; ====================================================================== GRAPHICS (GBASIC only)\n"
     "; [RE] Current hi-res plot color/mode index. Set by COLOR=/HCOLOR= (GFX_SET_COLOR_INDEX $4847); "
     "read by GFX_SELECT_COLOR_MASK ($4A91) and the SCRN color read to pick the bit-pattern mask.\n"
     "GFX_COLOR_INDEX:"),
    # 4b) close it just before the (shared) disk-error vectors
    ("        RET                              ; $4B79  C9\n"
     "; -- Disk-error raise vectors. The disk/RWTS error path enters one of these (the",
     "        RET                              ; $4B79  C9\n"
     "    ENDIF\n"
     "; -- Disk-error raise vectors. The disk/RWTS error path enters one of these (the"),
    # 5) the 'Graphics statement not implemented' stub, wedged into the disk-reselect tail (MBASIC)
    ("        POP DE                           ; $4B92  D1\n"
     "        JP RAISE_ERROR                   ; $4B93  C3 89 0D",
     "        POP DE                           ; $4B92  D1\n"
     "    IFNDEF GBASIC\n"
     "        DEFB    $01                      ;        LD BC opcode = skip the LD E on the reselect fall-through\n"
     "RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED:\n"
     "        LD E,ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; HGR/HPLOT/HCOLOR raise (MBASIC has no hi-res)\n"
     "    ENDIF\n"
     "        JP RAISE_ERROR                   ; $4B93  C3 89 0D"),
    # 6a) open the trailing-padding wrapper (label-anchored: the fill render differs run to run)
    ("INTERP_COPY_END:\n",
     "INTERP_COPY_END:\n    IFDEF GBASIC\n"),
    # 6b) close it after ENT (GBASIC ends the DISP; MBASIC has neither padding nor DISP)
    ("INTERP_RUN_TOP:\n    ENT\n",
     "INTERP_RUN_TOP:\n    ENT\n    ENDIF\n"),
    # 7) output size
    ('    SAVEBIN "GBASIC.bin", $0100, $6400',
     "    IFDEF GBASIC\n"
     '    SAVEBIN "GBASIC.bin", $0100, $6400\n'
     "    ELSE\n"
     '    SAVEBIN "MBASIC.bin", $0100, $6000\n'
     "    ENDIF"),
]


def generate():
    text = asm_path("GBASIC").read_text(encoding="latin-1")
    text = ("; BASIC.asm -- GENERATED by cpm_pipeline.basic.fold_gen from GBASIC.asm.\n"
            "; The GBASIC/MBASIC one-conditional-source fold master: assemble with the GBASIC\n"
            "; symbol defined for GBASIC.COM, without it for MBASIC.COM. Do not edit by hand;\n"
            "; edit GBASIC.asm (or its overlay) and the conditional patches in fold_gen.py.\n"
            + text)
    for old, new in _PATCHES:
        n = text.count(old)
        if n != 1:
            raise SystemExit(f"fold_gen: anchor occurs {n}x (expected 1):\n  {old[:80]!r}")
        text = text.replace(old, new, 1)
    out = asm_path("GBASIC").with_name("BASIC.asm")
    out.write_text(text, encoding="latin-1")
    print(f"wrote {out}")


if __name__ == "__main__":
    generate()
