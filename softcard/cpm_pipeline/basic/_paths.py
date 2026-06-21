"""Repo-relative paths for the BASIC regeneration tooling (no hard-coded drive
letters, so the pipeline reproduces from a clean checkout anywhere)."""
from pathlib import Path

SOFTCARD = Path(__file__).resolve().parents[2]          # .../softcard
UTIL_DIR = SOFTCARD / "CPMV220-44K" / "utilities"       # the 2.20-44K utility sources
INCLUDE_DIR = SOFTCARD / "include"                      # shared EQU includes


def asm_path(name):
    return UTIL_DIR / f"{name}.asm"


def overlay_path(name):
    return UTIL_DIR / f"{name}.overlay.json"


def seeds_path(name):
    return UTIL_DIR / f"{name}.seeds.json"


def load_token_names(inc="msbasic_tokens.inc"):
    """Parse the BASIC token include -> {byte_value: TOK_name}, so the formatter
    can render a SYNCHR inline token byte as its EQU name (single source of truth:
    the same include the assembled source pulls in)."""
    import re
    out = {}
    path = INCLUDE_DIR / inc
    if path.exists():
        for line in path.read_text(encoding="latin-1").splitlines():
            m = re.match(r'^(TOK_\w+)\s+EQU\s+\$([0-9A-Fa-f]{2})\b', line)
            if m:
                out[int(m.group(2), 16)] = m.group(1)
    return out
