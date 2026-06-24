"""Strip per-line ``; $addr <bytes>`` listing comments from a CP/M OS source, and emit
the address/byte information to a separate ``.lst`` -- the BASIC.asm convention
(``fold_build --lst``): the committed ``.asm`` carries SEMANTIC comments only; the
machine addresses + bytes live in the generated, git-ignored listing.

``strip_listing_comments`` removes only INLINE comments (code before the ``;``) whose text
begins with the line's own 4-hex address, dropping the ``$addr`` and any machine-byte run
that follows it while PRESERVING any semantic remainder. Full-line comments (``; ...`` with
no code -- the framed C-level headers, region maps, body-comment layer) and inline comments
that do not start with a ``$addr`` (the cover-idiom / dual-behaviour notes) are kept verbatim.

``emit_listing`` assembles a Z-80 OS chunk with ``sjasmplus --lst`` (staging its INCLUDE /
INCBIN deps exactly as the reconstruct build does) and writes the listing file.
"""
from __future__ import annotations

import re
from pathlib import Path

from .assemble import AssemblyError, assemble_chunk
from .chunk_map import ChunkSource

# An inline listing comment STARTS with the line's own 4-hex address.
_ADDR = re.compile(r'^\$[0-9A-Fa-f]{4}\b\s*(.*)$')
# After the address, a MACHINE-BYTE run is either the whole remainder (all hex pairs) or
# >=2 leading hex pairs then text. A lone 2-digit token ("10  SETTRK" = a decimal entry
# number / "C9" alone-with-text) is NOT treated as bytes -- semantic wins over stripping.
_ALL_BYTES = re.compile(r'[0-9A-Fa-f]{2}(?:\s+[0-9A-Fa-f]{2})*')
_LEAD_BYTES = re.compile(r'^[0-9A-Fa-f]{2}(?:\s+[0-9A-Fa-f]{2})+\s+(.*)$')


def _strip_comment(comment: str):
    """Return the kept semantic remainder of an inline comment, or None to keep it verbatim
    (not a listing comment). '' means drop the whole comment."""
    m = _ADDR.match(comment.strip())
    if not m:
        return None
    rest = m.group(1)
    if _ALL_BYTES.fullmatch(rest):            # address + pure machine bytes -> drop entirely
        return ""
    mb = _LEAD_BYTES.match(rest)              # address + >=2 byte pairs + semantic -> keep semantic
    kept = (mb.group(1) if mb else rest).strip()
    # the kept remainder may itself START with a second ';' (the source had "; $addr bytes ; note");
    # drop that leading ';' so the re-render doesn't produce a double ';; '.
    return kept.lstrip("; ").strip() if kept.startswith(";") else kept


def _comment_index(line: str) -> int:
    """Index of the comment ';' that is NOT inside a '...' or "..." literal, or -1. A bare
    `line.partition(";")` would split a char literal such as `CP ';'` at the quoted semicolon
    and mis-read the trailing listing comment, leaving it unstripped."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
        elif ch == ";":
            return i
    return -1


def strip_listing_comments(text: str, comment_col: int = 41) -> tuple[str, int]:
    """Return (stripped_text, n_lines_changed). Byte-identical when reassembled (comments
    never affect emitted bytes); the .lst carries the addresses instead."""
    out, changed = [], 0
    for line in text.split("\n"):
        ci = _comment_index(line)
        if ci < 0:                            # no real comment (none, or only a quoted ';')
            out.append(line)
            continue
        code, comment = line[:ci], line[ci + 1:]
        if not code.strip():                  # full-line comment -> documentation, keep
            out.append(line)
            continue
        rest = _strip_comment(comment)
        if rest is None:                      # inline but not a listing addr -> keep (semantic)
            out.append(line)
            continue
        coder = code.rstrip()
        if rest:                              # keep the semantic remainder, re-aligned
            pad = " " * max(1, comment_col - len(coder))
            out.append(f"{coder}{pad}; {rest}")
        else:                                 # pure address+bytes -> drop the whole comment
            out.append(coder)
        changed += 1
    return "\n".join(out), changed


def emit_listing(source: ChunkSource, lst_path: Path) -> None:
    """Assemble an OS chunk and write its assembler listing (address + machine bytes +
    source per line) to `lst_path`. Reuses the reconstruct assembly path (`assemble_chunk`)
    so every INCLUDE / INCBIN dep is staged exactly as the byte-identical build does --
    sjasmplus `--lst` for Z-80, ca65 `-l` for 6502 (the .s `.org` gives absolute addresses)."""
    if source.cpu not in ("z80", "6502"):
        raise AssemblyError(f"emit_listing supports z80/6502 sources (got {source.cpu})")
    lst_path = Path(lst_path)
    assemble_chunk(source, lst_path=lst_path)
    # Strip the assembler's non-deterministic preamble: sjasmplus emits a leading
    # "warning[backslash]: ... <temp-dir>\<file>.asm" line naming the randomly-named temp
    # copy it assembled, which would make the committed listing differ run to run. Drop any
    # line that names a staging temp path so the .lst is reproducible.
    try:
        text = lst_path.read_text(encoding="latin-1")
    except FileNotFoundError:
        return
    import re
    kept = []
    for ln in text.split("\n"):
        if "File name contains" in ln:                       # sjasmplus temp-path warning
            continue
        # The assembler ran on a randomly-named temp copy; scrub those temp paths so the
        # committed listing is reproducible: the sjasmplus SAVEBIN output and the ca65
        # "Main file"/"Current file" header both name it.
        ln = re.sub(r'("[^"]*[\\/]out\.bin")', '"{out_bin}"', ln)
        ln = re.sub(r'^((?:Main|Current) file\s*:\s*).*[\\/]([^\\/]+)$', r'\1\2', ln)
        kept.append(ln)
    lst_path.write_text("\n".join(kept), encoding="latin-1")


def main():
    import sys
    args = sys.argv[1:]
    if not args:
        print("usage: os_listing.py SOURCE.asm [--write]   (strip listing comments)")
        return
    p = Path(args[0])
    text = p.read_text(encoding="latin-1")
    stripped, n = strip_listing_comments(text)
    print(f"{p.name}: {n} inline listing comments stripped")
    if "--write" in args:
        p.write_text(stripped, encoding="latin-1")
        print("WROTE", p)


if __name__ == "__main__":
    main()
