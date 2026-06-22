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
    # 6) The trailing region (INTERP_COPY_END .. INTERP_RUN_TOP, incl. L_84C8) stays in BOTH
    #    builds so L_84C8 -- the cold-start stack base, referenced by COLD_START -- is DEFINED
    #    in both and RELOCATES: it is INTERP_COPY_END+69, i.e. $84C8 in GBASIC and $6146 in
    #    MBASIC (offset $2382, the post-graphics body delta). The fill bytes here sit past
    #    MBASIC's SAVEBIN ($6000) so they are not written; only ENT is GBASIC-only (MBASIC has
    #    no DISP to close).
    ("INTERP_RUN_TOP:\n    ENT\n",
     "INTERP_RUN_TOP:\n    IFDEF GBASIC\n    ENT\n    ENDIF\n"),
    # 7) output size
    ('    SAVEBIN "GBASIC.bin", $0100, $6400',
     "    IFDEF GBASIC\n"
     '    SAVEBIN "GBASIC.bin", $0100, $6400\n'
     "    ELSE\n"
     '    SAVEBIN "MBASIC.bin", $0100, $6000\n'
     "    ENDIF"),
    # 8a) hi-res FUNCTION dispatch ($D3): GBASIC -> the hi-res handler (in the graphics
    #     block); MBASIC -> the not-impl stub (verified: MBASIC $1CA0 = JP Z,$280F).
    ("        JP Z,SUB_47C6_2                  ; $3C85  CA E6 47",
     "    IFDEF GBASIC\n"
     "        JP Z,SUB_47C6_2                  ; $3C85  CA E6 47  (GBASIC: hi-res fn handler)\n"
     "    ELSE\n"
     "        JP Z,RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $3C85->$280F  hi-res fn -> not-impl (MBASIC)\n"
     "    ENDIF"),
    # 8b) hi-res FUNCTION dispatch ($ED): same divergence (MBASIC $1CAA = JP Z,$280F).
    ("        JP Z,SUB_47C6_3                  ; $3C8F  CA EF 47",
     "    IFDEF GBASIC\n"
     "        JP Z,SUB_47C6_3                  ; $3C8F  CA EF 47  (GBASIC: hi-res fn handler)\n"
     "    ELSE\n"
     "        JP Z,RAISE_GRAPHICS_STATEMENT_NOT_IMPLEMENTED  ; $3C8F->$280F  hi-res fn -> not-impl (MBASIC)\n"
     "    ENDIF"),
    # 9) THE structural root cause (the documented "+$23 low-RAM shift"): MBASIC's
    #     error-message table carries code 32 = "Graphics statement not implemented" -- the
    #     graphics-OFF marker GBASIC drops. Those 35 ($23) bytes shift the whole image after
    #     run $0704 up by $23 in MBASIC; without them the MBASIC body lands $23 low and every
    #     body/RAM reference diverges. Insert it IFNDEF GBASIC, between codes 31 and 50.
    ('        DEFB    "Reset error",$00        ; $06F9  ERR_RESET_ERROR = 31\n'
     '        DEFB    "FIELD overflow",$00     ; $0705  ERR_FIELD_OVERFLOW = 50',
     '        DEFB    "Reset error",$00        ; $06F9  ERR_RESET_ERROR = 31\n'
     '    IFNDEF GBASIC\n'
     '        DEFB    "Graphics statement not implemented",$00  ; MBASIC $0705  ERR_GRAPHICS_STATEMENT_NOT_IMPLEMENTED = 32 (graphics-OFF marker; absent in GBASIC)\n'
     '    ENDIF\n'
     '        DEFB    "FIELD overflow",$00     ; $0705  ERR_FIELD_OVERFLOW = 50'),
    # 10) ERROR_REPORT_BODY message-index clamp. The same code-32 graphics-message slot that
    #     shifts the low image (patch 9) also shifts the disk-error message-index boundaries by
    #     one, so three immediates differ between builds. They are not contiguous (a JR C and two
    #     labels sit between them), so each immediate is conditionalised on its own. Anchored on
    #     the unique byte-address comments; the surrounding labels/branches stay shared.
    ("        CP $20                           ; $0DEB  FE 20",
     "    IFDEF GBASIC\n"
     "        CP $20                           ; $0DEB  FE 20  (printable-range upper bound)\n"
     "    ELSE\n"
     "        CP $21                           ;        MBASIC: +1, the code-32 graphics slot\n"
     "    ENDIF"),
    ("        LD A,$27                         ; $0DEF  3E 27",
     "    IFDEF GBASIC\n"
     "        LD A,$27                         ; $0DEF  3E 27  (clamp index for codes >= $20)\n"
     "    ELSE\n"
     "        LD A,$26                         ;        MBASIC: -1 (one more printable slot)\n"
     "    ENDIF"),
    ("        SUB $12                          ; $0DF1  D6 12",
     "    IFDEF GBASIC\n"
     "        SUB $12                          ; $0DF1  D6 12  (disk-code -> message-index bias)\n"
     "    ELSE\n"
     "        SUB $11                          ;        MBASIC: -1, the code-32 graphics slot\n"
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
