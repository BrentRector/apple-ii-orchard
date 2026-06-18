"""Logical dedup for SoftCard CP/M disk images.

Two disk images are *logical duplicates* when they hold the same files (by
content) and the same operating system -- even if their raw bytes differ. More
generally, a disk is *redundant* when it is a **subset** of another disk: every
file on it is byte-identical to a file on the other, the other has at least one
file it lacks, and they run the same OS. A CP/M disk that is merely missing an
app but otherwise identical to a fuller one is not worth keeping.

The dominant source of raw-byte difference between otherwise-identical disks is
the don't-care fill that ``CPM60.COM`` / ``CPM56.COM`` write into the system
tracks when they rewrite a disk: ~900 bytes copied straight from a staging
buffer and never read back. A raw md5 wildly over-counts distinct disks; this
module compares the *logical* content instead, so the fill -- and the equivalent
cosmetic differences (CP/M directory block allocation, deleted-file remnants,
sector order) -- is ignored:

  * filesystem -- each file's ``(name, user, content-hash)``. ``extract()``
    follows the directory and truncates to the record length, so this never
    sees gap/fill bytes or where the blocks happen to be allocated.
  * operating system -- the routine-level :class:`~cpm_pipeline.version_delta.DiskDelta`
    (variant, boot sector, Z-80 reset / BDOS / CPU-switch vectors, cold-boot
    dispatch cases). Gap bytes are not routines, so this is fill-invariant too.

The fill only appears on update-utility output (60K via ``CPM60``, 56K via
``CPM56``); on an as-shipped 44K disk there is no fill, and the same checks still
hold -- so no special-casing on memory size is needed.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from pathlib import Path

from .filesystem import list_files, extract, NotCpmFilesystem
from .version_delta import compare_disks


def fileset_fingerprint(path: Path | str) -> tuple[tuple[str, int, str], ...]:
    """Sorted ``(name, user, sha1)`` over every file's *content*.

    Order-, allocation-, and fill-invariant: identical for two images that hold
    the same files regardless of sector order or system-track fill.
    """
    out: list[tuple[str, int, str]] = []
    for f in list_files(path):
        try:
            content = extract(path, f.name, f.user)
        except Exception:                       # pragma: no cover - defensive
            content = b"<unreadable>"
        out.append((f.name, f.user, hashlib.sha1(content).hexdigest()))
    return tuple(sorted(out))


def _content_relation(sa: frozenset, sb: frozenset) -> str:
    """Relate two ``(name, user, hash)`` content sets.

    Returns ``equal`` / ``a_subset`` (A's files all on B, B has more) /
    ``b_subset`` / ``divergent`` (each has unique files, or a shared file's
    content differs).
    """
    if sa == sb:
        return "equal"
    if sa < sb:
        return "a_subset"
    if sb < sa:
        return "b_subset"
    return "divergent"


@dataclass
class LogicalVerdict:
    """How two disks relate logically (filesystem + OS)."""
    path_a: Path
    path_b: Path
    relation: str                # content: equal / a_subset / b_subset / divergent
    os_same: bool
    file_diffs: list[str] = field(default_factory=list)
    os_diffs: list[str] = field(default_factory=list)

    @property
    def is_duplicate(self) -> bool:
        return self.relation == "equal" and self.os_same

    def summary(self) -> str:
        if self.is_duplicate:
            verb = "DUPLICATE"
        elif self.os_same and self.relation in ("a_subset", "b_subset"):
            verb = "SUBSET"
        else:
            verb = "DISTINCT"
        lines = [f"{self.path_a.name}  vs  {self.path_b.name}: {verb}"]
        for d in self.file_diffs:
            lines.append(f"    file: {d}")
        for d in self.os_diffs:
            lines.append(f"    os:   {d}")
        return "\n".join(lines)


def _vec(plant):
    return getattr(plant, "target_addr", None) if plant else None


def compare_logical(path_a: Path | str, path_b: Path | str) -> LogicalVerdict:
    """Compare two disks logically (fill/allocation/order invariant)."""
    path_a, path_b = Path(path_a), Path(path_b)

    file_diffs: list[str] = []
    relation = "divergent"
    try:
        fa = fileset_fingerprint(path_a)
        fb = fileset_fingerprint(path_b)
        relation = _content_relation(frozenset(fa), frozenset(fb))
        da = {(n, u): h for n, u, h in fa}
        db = {(n, u): h for n, u, h in fb}
        for key in sorted(set(da) | set(db)):
            name = key[0] if key[1] == 0 else f"{key[0]} (user {key[1]})"
            if key not in db:
                file_diffs.append(f"only on A: {name}")
            elif key not in da:
                file_diffs.append(f"only on B: {name}")
            elif da[key] != db[key]:
                file_diffs.append(f"content differs: {name}")
    except NotCpmFilesystem as e:
        file_diffs.append(f"filesystem unreadable ({e})")

    os_diffs: list[str] = []
    try:
        delta = compare_disks(path_a, path_b)
    except Exception as e:                       # pragma: no cover - defensive
        # Detection failure on either disk -> can't confirm OS identity.
        os_diffs.append(f"OS comparison unavailable ({type(e).__name__})")
        return LogicalVerdict(path_a, path_b, relation, False, file_diffs, os_diffs)

    if not delta.same_variant:
        os_diffs.append(f"variant: {delta.info_a.variant} vs {delta.info_b.variant}")
    if delta.boot_stub_diff_bytes:
        os_diffs.append(
            f"boot loader: {delta.boot_stub_diff_bytes} byte(s) differ in sector 0"
        )
    for label, a, b in (
        ("Z-80 reset", _vec(delta.handoff_a.z80_reset_plant), _vec(delta.handoff_b.z80_reset_plant)),
        ("BDOS entry", _vec(delta.handoff_a.bdos_entry_plant), _vec(delta.handoff_b.bdos_entry_plant)),
        ("CPU-switch", _vec(delta.handoff_a.cpu_switch_trigger), _vec(delta.handoff_b.cpu_switch_trigger)),
    ):
        if a is not None and b is not None and a != b:
            os_diffs.append(f"{label}: ${a:04X} vs ${b:04X}")
    # Dispatch cases only mean something when BOTH BIOSes were located; if one
    # wasn't, its case set is empty for lack of data, not because it differs.
    both_cold = delta.cold_boot_a is not None and delta.cold_boot_b is not None
    if both_cold and (delta.cases_only_in_a or delta.cases_only_in_b
                      or delta.cases_with_different_handler):
        os_diffs.append("cold-boot dispatch cases differ")

    return LogicalVerdict(path_a, path_b, relation, not os_diffs, file_diffs, os_diffs)


@dataclass
class Redundant:
    """A disk that need not be kept, and what subsumes it."""
    path: Path
    kept: Path
    kind: str                    # 'duplicate' | 'subset'
    missing: list[str] = field(default_factory=list)   # files the keeper has and this lacks


def dedup(paths) -> tuple[list[Path], list[Redundant], dict[tuple[int, int], LogicalVerdict]]:
    """Reduce ``paths`` to the set worth keeping.

    A disk is dropped when, running the same OS as another disk, its file
    content set is equal to (keep one) or a proper subset of the other's. Returns
    ``(keepers, redundant, verdicts)``.
    """
    paths = [Path(p) for p in paths]
    n = len(paths)

    sets: list[frozenset] = []
    for p in paths:
        try:
            sets.append(frozenset(fileset_fingerprint(p)))
        except Exception:                        # pragma: no cover - defensive
            sets.append(frozenset())

    verdicts: dict[tuple[int, int], LogicalVerdict] = {}
    os_same = [[False] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            v = compare_logical(paths[i], paths[j])
            verdicts[(i, j)] = v
            os_same[i][j] = os_same[j][i] = v.os_same

    redundant = [False] * n
    subsumer: list[int | None] = [None] * n
    for i in range(n):
        if not sets[i]:                          # unreadable / non-CP/M: never merge
            continue
        best = None
        for j in range(n):
            if i == j or not os_same[i][j]:
                continue
            proper_subset = sets[i] < sets[j]
            equal_noncanonical = sets[i] == sets[j] and j < i
            if proper_subset or equal_noncanonical:
                if best is None or len(sets[j]) > len(sets[best]):
                    best = j
        if best is not None:
            redundant[i] = True
            subsumer[i] = best

    def survivor(i: int) -> int:
        seen: set[int] = set()
        while redundant[i] and subsumer[i] is not None and i not in seen:
            seen.add(i)
            i = subsumer[i]
        return i

    keepers = [paths[i] for i in range(n) if not redundant[i]]
    drops: list[Redundant] = []
    for i in range(n):
        if redundant[i]:
            k = survivor(i)
            kind = "duplicate" if sets[i] == sets[k] else "subset"
            missing = sorted(name for (name, _u, _h) in (sets[k] - sets[i]))
            drops.append(Redundant(paths[i], paths[k], kind, missing))
    return keepers, drops, verdicts
