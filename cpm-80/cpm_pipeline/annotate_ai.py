"""Optional AI prose-comment layer for disassembled source.

Takes an assembled-source listing produced by the disassemblers and adds a short
human-style prose comment above each labelled routine, marked ``[AI]`` so it's
never mistaken for verified annotation. Comments are inserted programmatically as
assembler comment lines (`;`) — the model proposes prose for each *label*, and
the code bytes never round-trip through the model, so the source still reassembles
byte-identically.

Two backends produce the prose, both using Claude Opus 4.8 (``claude-opus-4-8``):

  * ``cli`` — shells out to the **Claude Code** CLI (``claude -p``), which uses the
    user's existing Claude Code authentication. No ``ANTHROPIC_API_KEY`` required.
  * ``api`` — the Anthropic Messages API (needs ``ANTHROPIC_API_KEY`` + the
    ``anthropic`` SDK).

``backend="auto"`` (the default) prefers the Claude Code CLI when ``claude`` is on
PATH, then falls back to the API. If neither is available the source is returned
unchanged with ``AnnotateResult.annotated == False`` and a reason — the toolchain
degrades gracefully and never hard-fails.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

MODEL = "claude-opus-4-8"
MAX_TOKENS = 16000

# ca65 / sjasmplus label at column 0: NAME or NAME: (allow leading $ / . / _).
_LABEL_RE = re.compile(r"^([A-Za-z_.][A-Za-z0-9_.]*):")

_ANNOTATION_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["annotations"],
    "properties": {
        "annotations": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["label", "comment"],
                "properties": {
                    "label": {"type": "string"},
                    "comment": {"type": "string",
                                "description": "one or two sentences, technical, "
                                               "no restating of mnemonics"},
                },
            },
        }
    },
}


@dataclass
class AnnotateResult:
    annotated: bool
    labels_seen: int
    comments_added: int
    model: str = MODEL
    backend: str = ""
    reason: str = ""

    def summary(self) -> str:
        if self.annotated:
            return (f"AI annotation: {self.comments_added}/{self.labels_seen} labels "
                    f"commented via {self.model} ({self.backend})")
        return f"AI annotation skipped ({self.reason})"


# ── backend selection ──────────────────────────────────────────────────

def _claude_cli() -> str | None:
    return shutil.which("claude")


def _api_available() -> bool:
    if not os.environ.get("ANTHROPIC_API_KEY"):
        return False
    try:
        import anthropic  # noqa: F401
    except ImportError:
        return False
    return True


def _resolve_backend(backend: str) -> tuple[str | None, str]:
    """Pick a backend. 'auto' prefers the Claude Code CLI (no API key needed),
    then the Anthropic API. Returns (name, "") or (None, reason)."""
    has_cli = _claude_cli() is not None
    has_api = _api_available()
    if backend == "cli":
        return ("cli", "") if has_cli else (None, "claude CLI not on PATH")
    if backend == "api":
        return (("api", "") if has_api
                else (None, "ANTHROPIC_API_KEY not set / anthropic SDK missing"))
    if has_cli:
        return "cli", ""
    if has_api:
        return "api", ""
    return None, "no AI backend (neither the claude CLI nor ANTHROPIC_API_KEY is available)"


def _system_prompt(cpu: str, context: str) -> str:
    return (
        "You are an expert reverse engineer of vintage 8-bit systems. The provided "
        f"content is a disassembly of {cpu} code ({context}). For each labelled routine "
        "or location, write a concise one- to two-sentence prose comment describing its "
        "PURPOSE and role -- be specific and technical; do NOT merely restate the "
        "mnemonics. Recognize CP/M conventions (BDOS = CALL $0005 with the function "
        "number in C; the TPA is $0100). Prefer accuracy over coverage: omit a label "
        "rather than guessing. Use EXACT label names from the source."
    )


def _parse_annotations(text: str) -> dict:
    t = text.strip()
    if t.startswith("```"):
        t = re.sub(r"^```[a-zA-Z]*\n?", "", t)
        t = re.sub(r"\n?```$", "", t.strip())
    data = json.loads(t)
    return {a["label"]: a["comment"] for a in data["annotations"]
            if a.get("label") and a.get("comment")}


def _comments_from_cli(asm_text: str, *, cpu: str, context: str, model: str,
                       timeout: int = 1800) -> dict:
    """Get annotations from the Claude Code CLI (uses its own auth; no API key)."""
    instruction = (
        _system_prompt(cpu, context) +
        ' The disassembly is provided on stdin. Output ONLY a JSON object of the form '
        '{"annotations":[{"label":"<exact label>","comment":"<text>"}]} '
        "-- no prose, no markdown fences."
    )
    cmd = [_claude_cli(), "-p", instruction, "--output-format", "json", "--model", model]
    r = subprocess.run(cmd, input=asm_text, capture_output=True, text=True, timeout=timeout)
    if r.returncode != 0:
        raise RuntimeError(f"claude CLI rc={r.returncode}: {r.stderr[:200]}")
    outer = json.loads(r.stdout)
    if outer.get("is_error"):
        raise RuntimeError(f"claude CLI error: {str(outer.get('result', ''))[:200]}")
    return _parse_annotations(outer.get("result", ""))


def _comments_from_api(asm_text: str, *, cpu: str, context: str, model: str,
                       labels: list[str]) -> dict:
    """Get annotations from the Anthropic Messages API (needs ANTHROPIC_API_KEY)."""
    import anthropic
    user = (f"Disassembly:\n```\n{asm_text}\n```\n\n"
            f"Write a comment for each of these {len(labels)} labels: {', '.join(labels)}")
    client = anthropic.Anthropic()
    resp = client.messages.create(
        model=model, max_tokens=MAX_TOKENS, system=_system_prompt(cpu, context),
        messages=[{"role": "user", "content": user}],
        output_config={"format": {"type": "json_schema", "schema": _ANNOTATION_SCHEMA}},
    )
    if resp.stop_reason == "refusal":
        raise RuntimeError("model refused")
    return _parse_annotations(next((b.text for b in resp.content if b.type == "text"), ""))


def _labels(text: str) -> list[str]:
    seen: list[str] = []
    for line in text.splitlines():
        m = _LABEL_RE.match(line)
        if m and m.group(1) not in seen:
            seen.append(m.group(1))
    return seen


def insert_comments(asm_text: str, comments: dict, *, model: str = MODEL) -> tuple[str, int]:
    """Insert `; [AI]` comment lines above each labelled line that has a comment.

    Pure text transform: only comment lines are added, so the source still
    reassembles byte-identically. Returns (new_text, comments_added).
    """
    out: list[str] = [
        f"; NOTE: comments marked [AI] are machine-generated by {model} and may be",
        "; inaccurate; treat them as hints, not verified annotation.",
        "",
    ]
    import textwrap
    added = 0
    for line in asm_text.splitlines():
        m = _LABEL_RE.match(line)
        if m and m.group(1) in comments and comments[m.group(1)]:
            indent = line[:len(line) - len(line.lstrip())]
            prose = " ".join(str(comments[m.group(1)]).split())
            wrapped = textwrap.wrap(prose, width=92) or [prose]
            out.append(f"{indent}; [AI] {wrapped[0]}")
            out.extend(f"{indent};       {w}" for w in wrapped[1:])
            added += 1
        out.append(line)
    return "\n".join(out) + "\n", added


def annotate_text(asm_text: str, *, cpu: str, context: str = "",
                  model: str = MODEL, backend: str = "auto") -> tuple[str, AnnotateResult]:
    """Return (possibly-annotated source, result). No-op if no backend is available."""
    labels = _labels(asm_text)
    if not labels:
        return asm_text, AnnotateResult(False, 0, 0, model, "", "no labels to annotate")
    chosen, reason = _resolve_backend(backend)
    if chosen is None:
        return asm_text, AnnotateResult(False, len(labels), 0, model, "", reason)
    try:
        if chosen == "cli":
            comments = _comments_from_cli(asm_text, cpu=cpu, context=context, model=model)
        else:
            comments = _comments_from_api(asm_text, cpu=cpu, context=context,
                                          model=model, labels=labels)
    except Exception as e:  # backend failures degrade to "skipped", never crash the run
        return asm_text, AnnotateResult(False, len(labels), 0, model, chosen,
                                        f"{chosen} backend failed: {type(e).__name__}: {e}")
    new_text, added = insert_comments(asm_text, comments, model=model)
    return new_text, AnnotateResult(True, len(labels), added, model, chosen)


def annotate_file(asm_path, *, cpu: str, context: str = "",
                  model: str = MODEL, backend: str = "auto") -> AnnotateResult:
    """Annotate an .asm/.s file in place (only rewritten if annotation succeeded)."""
    path = Path(asm_path)
    new_text, result = annotate_text(path.read_text(encoding="utf-8"),
                                     cpu=cpu, context=context, model=model, backend=backend)
    if result.annotated:
        path.write_text(new_text, encoding="utf-8")
    return result
