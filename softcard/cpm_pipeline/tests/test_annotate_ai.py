"""AI annotation layer — structural tests (live backends need the claude CLI or a key)."""

import cpm_pipeline.annotate_ai as a
from cpm_pipeline.annotate_ai import annotate_text, annotate_file, _labels, insert_comments

SAMPLE = """; header comment
L_FA00:
        JP BOOT
BOOT:
        LD C,$09
        RET
"""


def test_label_parsing():
    assert _labels(SAMPLE) == ["L_FA00", "BOOT"]


def test_insert_comments_is_byte_safe_and_marks_ai():
    new, added = insert_comments(SAMPLE, {"BOOT": "prints a '$'-terminated string via BDOS 9"})
    assert added == 1
    assert "; [AI]" in new
    # original code lines are all still present (comments only added)
    for line in SAMPLE.splitlines():
        assert line in new


def test_auto_prefers_cli_when_available(monkeypatch):
    monkeypatch.setattr(a, "_claude_cli", lambda: "/usr/bin/claude")
    name, reason = a._resolve_backend("auto")
    assert name == "cli"


def test_auto_falls_back_to_api(monkeypatch):
    monkeypatch.setattr(a, "_claude_cli", lambda: None)
    monkeypatch.setattr(a, "_api_available", lambda: True)
    name, reason = a._resolve_backend("auto")
    assert name == "api"


def test_no_backend_is_graceful(monkeypatch):
    monkeypatch.setattr(a, "_claude_cli", lambda: None)
    monkeypatch.setattr(a, "_api_available", lambda: False)
    text, res = annotate_text(SAMPLE, cpu="Z-80", context="test")
    assert text == SAMPLE                 # unchanged
    assert res.annotated is False
    assert "no AI backend" in res.reason
    assert res.labels_seen == 2


def test_api_backend_without_key_is_graceful(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    text, res = annotate_text(SAMPLE, cpu="Z-80", context="test", backend="api")
    assert text == SAMPLE
    assert res.annotated is False
    assert "ANTHROPIC_API_KEY" in res.reason


def test_annotate_file_no_op_when_no_backend(tmp_path, monkeypatch):
    monkeypatch.setattr(a, "_claude_cli", lambda: None)
    monkeypatch.setattr(a, "_api_available", lambda: False)
    p = tmp_path / "x.asm"
    p.write_text(SAMPLE, encoding="utf-8")
    res = annotate_file(p, cpu="Z-80")
    assert res.annotated is False
    assert p.read_text(encoding="utf-8") == SAMPLE   # file untouched
