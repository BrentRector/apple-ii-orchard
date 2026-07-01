"""Build-matrix registry + release-verb tests (targets.py / release.py).

The registry/resolve tests need no assembler. The build/verify tests assemble the OS
sources and are skipped (silently, like the rest of the suite) when ca65/ld65/sjasmplus
are off PATH -- EXCEPT the skip-is-failure test, which proves the release verb itself
refuses to skip. Source shared/toolchain/env.sh so these run for real.
"""

import shutil
import tempfile
from pathlib import Path

import pytest

from cpm_pipeline.targets import (
    TARGETS, resolve, verify_derived, CANONICAL, DERIVED, INSTALLER_DERIVED,
)
from cpm_pipeline.chunk_map import get_variant
from cpm_pipeline.reference_data import present

HAS_ASSEMBLERS = (
    shutil.which("ca65") is not None
    and shutil.which("ld65") is not None
    and shutil.which("sjasmplus") is not None
)


def test_targets_registry_covers_the_six_cells():
    assert set(TARGETS) == {"2.20/44K", "2.20B/56K", "2.20B/44K",
                            "2.20/56K", "2.23/44K", "2.23/60K"}
    assert {t.provenance for t in TARGETS.values()} == {
        CANONICAL, DERIVED, INSTALLER_DERIVED}
    for t in TARGETS.values():
        # each cell has a resolvable chunk variant
        get_variant(t.variant)
        if t.provenance == DERIVED:
            # a derived cell carries a same-memory filesystem and points at a
            # CANONICAL diagonal it is a pure relocation of -- never its own reference.
            assert t.reference is None and t.carrier is not None
            assert TARGETS[t.derived_from].provenance == CANONICAL
            assert TARGETS[t.derived_from].version == t.version   # same VERSION, other memory
            assert TARGETS[t.derived_from].memory != t.memory
        else:
            assert t.reference is not None and t.carrier is None


def test_resolve_spec_forms():
    t, fmt = resolve("2.23/60K")
    assert t.key == "2.23/60K" and fmt is None
    t, fmt = resolve("2.20b/44k/po")            # case-insensitive, trailing-B, fmt
    assert t.key == "2.20B/44K" and fmt == "po"
    t, fmt = resolve("2.20/56K/.dsk")           # leading dot on fmt tolerated
    assert t.key == "2.20/56K" and fmt == "dsk"
    for bad in ("2.99/44K", "2.20/44K/xyz", "2.20", "a/b/c/d"):
        with pytest.raises(ValueError):
            resolve(bad)


def test_release_basenames_are_unique_and_marked():
    names = [t.basename() for t in TARGETS.values()]
    assert len(set(names)) == len(names) == 6
    assert TARGETS["2.20/44K"].basename() == "softcard-cpm2.20-44k"
    assert TARGETS["2.20B/44K"].basename() == "softcard-cpm2.20b-44k-derived"
    assert TARGETS["2.23/60K"].basename() == "softcard-cpm2.23-60k-installer-derived"


def test_release_hard_fails_when_assembler_missing(monkeypatch):
    """Skip-is-failure: with an assembler 'off PATH' the release verb RAISES rather than
    silently skipping verification (the failure mode the whole harness is meant to close)."""
    from cpm_pipeline import release as rel
    monkeypatch.setattr(rel.shutil, "which",
                        lambda name: None if name == "sjasmplus" else "/usr/bin/" + name)
    with pytest.raises(rel.ReleaseError, match="sjasmplus"):
        rel.release(tempfile.mkdtemp(), quiet=True)


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="assemblers not on PATH")
def test_verify_derived_is_pure_memory_axis():
    for key in ("2.20B/44K", "2.20/56K"):
        assert "relocation" in verify_derived(TARGETS[key])


@pytest.mark.skipif(not HAS_ASSEMBLERS, reason="assemblers not on PATH")
def test_release_builds_and_verifies_all_cells():
    """The Step 5 gate: every cell builds in both formats and byte-verifies per its
    provenance; SHA256SUMS + the manifest cover all 12 images and match each other."""
    from cpm_pipeline.release import release
    if not present(*{t.source_disk for t in TARGETS.values()}):
        pytest.skip("reference disk(s) missing")
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        manifest = release(out, quiet=True)

        disks = list(out.glob("*.dsk")) + list(out.glob("*.po"))
        assert len(disks) == 12
        assert all(d.stat().st_size == 143360 for d in disks)

        sums = (out / "SHA256SUMS").read_text().splitlines()
        assert len(sums) == 12
        assert (out / "release_manifest.json").exists()

        assert len(manifest["targets"]) == 6
        assert manifest["release"]["cpm60_com"]["byte_identical"] is True
        by = {t["key"]: t for t in manifest["targets"]}
        assert "byte-identical" in by["2.20/44K"]["verification"]
        assert "relocation" in by["2.20B/44K"]["verification"]
        assert "CPM60.COM" in by["2.23/60K"]["verification"]
        # derived-cell honesty: no self-reference, carrier recorded, diagonal named.
        assert by["2.20B/44K"]["reference"] is None
        assert by["2.20B/44K"]["carrier"] is not None
        assert by["2.20B/44K"]["derived_from"] == "2.20B/56K"

        # every SHA256SUMS line matches a manifest image hash.
        manifest_hashes = {img["file"]: img["sha256"]
                           for t in manifest["targets"] for img in t["images"].values()}
        assert len(manifest_hashes) == 12
        for line in sums:
            h, f = line.split()
            assert manifest_hashes[f] == h
