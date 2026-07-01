"""The ``release`` verb: build every SoftCard CP/M target cell as a downloadable disk.

Builds all six (version x memory) cells from :mod:`targets` in BOTH .dsk and .po (12
images) into an output directory, byte-verifies each per its provenance, and emits
``SHA256SUMS`` + ``release_manifest.json`` so a fork can reproduce and audit the set.

**Skip-is-failure.** The byte-identical round-trip tests SKIP silently when the
assemblers are off PATH; a release must never do that. :func:`release` hard-asserts
ca65/ld65/sjasmplus on PATH and every reference disk present, and aborts nonzero on any
mismatch -- a green-looking release can only mean every image was actually verified.

Verification per provenance:
  * **canonical** -- reconstruct byte-identical to the original release disk.
  * **derived** -- the OS modules are a pure +$3000 relocation of the byte-gated diagonal
    cell (:func:`targets.verify_derived`); the disk is the derived OS overlaid on the
    same-memory carrier's filesystem.
  * **installer-derived** (2.23/60K) -- carried verbatim from its committed reference;
    provenance anchored to CPM60.COM built byte-identically from source.

The second format of each cell is produced by the gated-lossless .dsk<->.po transcode of
the byte-verified native image (see ``test_reconstruct_emits_either_dsk_or_po_for_any_build``),
so assembly runs once per cell, not once per format.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from .disk_format import DISK_SIZE, detect_format, read_disk, write_disk
from .reconstruct import _transcode, reconstruct_disk
from .reference_data import present
from .targets import (
    CANONICAL, DERIVED, INSTALLER_DERIVED, TARGETS, Target, verify_derived,
)

_REPO_ROOT = Path(__file__).resolve().parents[2]          # e:/Orchard (git + manifest paths)


class ReleaseError(RuntimeError):
    """A release could not be produced with full verification (skip-is-failure)."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _rel(path: Path) -> str:
    """Path relative to the repo root when possible (e.g. 'softcard/reference/...'),
    else the plain string -- keeps the manifest portable across checkouts."""
    try:
        return str(Path(path).resolve().relative_to(_REPO_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path)


def _tool_versions() -> dict:
    out = {}
    for tool in ("sjasmplus", "ca65", "ld65"):
        ver = "unknown"
        if shutil.which(tool):
            try:
                r = subprocess.run([tool, "--version"], capture_output=True, text=True)
                line = (r.stdout or r.stderr or "").strip().splitlines()
                ver = line[0].strip() if line else "present"
            except Exception:
                ver = "present"
        out[tool] = ver
    return out


def _git_sha() -> str:
    try:
        r = subprocess.run(["git", "rev-parse", "HEAD"], cwd=str(_REPO_ROOT),
                           capture_output=True, text=True)
        return r.stdout.strip() or "unknown"
    except Exception:
        return "unknown"


def _reference_entry(path: Path | None) -> dict | None:
    if path is None:
        return None
    return {"path": _rel(path), "sha256": _sha256(Path(path).read_bytes())}


def _verify_cpm60_anchor() -> dict:
    """Build CPM60.COM from its master source and assert it equals the genuine on-disk
    file -- the provenance anchor for the 2.23/60K cell (whose disk is only carried)."""
    from .build_cpm60 import build_cpm60_com, reference_com
    built = build_cpm60_com()
    ref = reference_com()
    if built != ref:
        raise ReleaseError(
            f"CPM60.COM built from source ({len(built)} B) does not match the genuine "
            f"on-disk file ({len(ref)} B) -- 60K provenance anchor failed")
    return {"byte_identical": True, "size": len(built), "sha256": _sha256(built),
            "note": "built byte-identical from CPMV223-60K/CPM60.asm; the 2.23/60K disk "
                    "is carried, its lower BDOS bank still a partial blob"}


def _build_target(target: Target, out_dir: Path, quiet: bool) -> dict:
    """Build one cell in both formats into ``out_dir``; return its manifest entry."""
    src = target.source_disk
    native = detect_format(src)
    other = "po" if native == "dsk" else "dsk"
    verify_native = target.provenance in (CANONICAL, INSTALLER_DERIVED)

    native_out = out_dir / f"{target.basename()}.{native}"
    result = reconstruct_disk(target.variant, reference_path=src,
                              output_path=native_out, verify=verify_native)
    if verify_native and result.diff_count != 0:
        raise ReleaseError(
            f"{target.key}: {native} build differs from reference at "
            f"{result.diff_count} byte(s); first {result.diff_offsets}")

    # Second format: gated-lossless transcode of the verified native image (no reassembly).
    other_out = out_dir / f"{target.basename()}.{other}"
    write_disk(other_out, _transcode(read_disk(native_out),
                                     src_format=native, dst_format=other))

    if target.provenance == CANONICAL:
        verification = "byte-identical vs original release disk"
    elif target.provenance == DERIVED:
        verification = verify_derived(target)   # raises on any axis entanglement
    else:
        verification = ("carried from committed reference; CPM60.COM byte-identical "
                        "from source")

    images = {}
    for ext, path in ((native, native_out), (other, other_out)):
        data = path.read_bytes()
        if len(data) != DISK_SIZE:
            raise ReleaseError(f"{path.name}: unexpected size {len(data)}")
        images[ext] = {"file": path.name, "sha256": _sha256(data)}

    if not quiet:
        print(f"  {target.key:10s} [{target.provenance:17s}] "
              f"{target.basename()}.{{dsk,po}}  -- {verification}")

    return {
        "key": target.key, "version": target.version, "memory": target.memory,
        "variant": target.variant, "defines": list(target.defines),
        "provenance": target.provenance, "derived_from": target.derived_from,
        "verification": verification,
        "reference": _reference_entry(target.reference),
        "carrier": _reference_entry(target.carrier),
        "images": images,
    }


def release(out_dir: Path | str, *, publish_tag: str | None = None,
            quiet: bool = False) -> dict:
    """Build + verify all six cells (12 images) into ``out_dir``; write SHA256SUMS and
    release_manifest.json; return the manifest dict. Raises :class:`ReleaseError` if the
    assemblers are off PATH, a reference disk is missing, or any image fails verification.
    ``publish_tag`` (if given) publishes the packaged set with ``gh release create``."""
    out_dir = Path(out_dir)

    # Skip-is-failure: hard-require the toolchain and every reference disk.
    missing_tools = [t for t in ("ca65", "ld65", "sjasmplus") if not shutil.which(t)]
    if missing_tools:
        raise ReleaseError(
            f"assemblers not on PATH: {', '.join(missing_tools)} "
            f"(source shared/toolchain/env.sh). A release NEVER skips verification.")
    disks = {t.source_disk for t in TARGETS.values()}
    absent = [str(d) for d in disks if not present(d)]
    if absent:
        raise ReleaseError("reference/carrier disk(s) missing:\n  " + "\n  ".join(absent))

    out_dir.mkdir(parents=True, exist_ok=True)
    if not quiet:
        print(f"Building {len(TARGETS)} cells x 2 formats -> {out_dir}")

    entries = [_build_target(t, out_dir, quiet) for t in TARGETS.values()]
    cpm60 = _verify_cpm60_anchor()

    manifest = {
        "release": {
            "source_git_sha": _git_sha(),
            "build_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tool_versions": _tool_versions(),
            "disk_size": DISK_SIZE,
            "cell_count": len(TARGETS),
            "image_count": 2 * len(TARGETS),
            "cpm60_com": cpm60,
        },
        "targets": entries,
    }

    manifest_path = out_dir / "release_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    # SHA256SUMS over every disk image (sorted; `sha256sum -c` compatible).
    sums = []
    for e in entries:
        for img in e["images"].values():
            sums.append((img["file"], img["sha256"]))
    sums.sort()
    (out_dir / "SHA256SUMS").write_text(
        "".join(f"{h}  {f}\n" for f, h in sums), encoding="utf-8")

    if not quiet:
        print(f"  CPM60.COM anchor: byte-identical ({cpm60['sha256'][:12]}...)")
        print(f"wrote {2 * len(TARGETS)} images + SHA256SUMS + release_manifest.json")

    if publish_tag:
        _publish(publish_tag, out_dir, quiet=quiet)

    return manifest


def _publish(tag: str, out_dir: Path, *, quiet: bool = False) -> None:
    """Publish the packaged release with `gh release create <tag>` (explicit opt-in).
    Uploads every .dsk/.po plus SHA256SUMS and release_manifest.json."""
    if not shutil.which("gh"):
        raise ReleaseError("gh CLI not on PATH; cannot publish")
    assets = sorted(str(p) for p in out_dir.iterdir()
                    if p.suffix.lower() in (".dsk", ".po")
                    or p.name in ("SHA256SUMS", "release_manifest.json"))
    cmd = ["gh", "release", "create", tag, "--title",
           f"SoftCard CP/M disks {tag}",
           "--notes", "Reconstructed SoftCard CP/M disk images (see release_manifest.json).",
           *assets]
    if not quiet:
        print("publishing: " + " ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise ReleaseError(f"gh release create failed:\n{r.stdout}{r.stderr}")
