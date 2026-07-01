"""The SoftCard CP/M build matrix -- single source of truth for the target cells.

Each :class:`Target` maps one (version x memory) cell to exactly how the pipeline
builds it: the chunk-map variant, the OS ``-D`` defines that describe the cell, the
reference/carrier disk (imported ONLY from :mod:`reference_data` -- never a hard-coded
path), and its provenance. The ``build --target`` and ``release`` verbs resolve a
requested cell to a Target and drive :mod:`reconstruct`.

Six cells (version x memory), four provenance classes:

  * **canonical** -- reconstructs byte-identical to an original release disk
    (2.20/44K, 2.20B/56K, 2.23/44K).
  * **derived** -- a never-shipped off-diagonal 2.20 cell (2.20B/44K, 2.20/56K);
    the OS region is synthesized from the folded source at the derived ORG and the
    filesystem/boot sectors are carried from the nearest same-MEMORY reference. No
    reference disk exists, so it is validated TRANSITIVELY: the derived OS modules,
    relocated by the memory axis, must equal the byte-gated diagonal cell of the
    same version (:func:`verify_derived`). See docs/CPM_Unified_Build_Plan.md Step 0.
  * **installer-derived** -- the 2.23/60K disk, which has no OS chunk-map/reconstruct
    path (its BDOS is bank-woven across two language-card banks, still a partial blob).
    The disk is carried verbatim from its committed reference; provenance is anchored
    to the byte-identical CPM60.COM (build_cpm60.build_cpm60_com). Never claimed as a
    full source reconstruction.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from .reference_data import (
    DISK_2_20_44K_SYSTEM,
    DISK_2_20B_56K_SYSTEM,
    DISK_2_23_44K_SYSTEM,
    DISK_2_23_60K_SYSTEM,
)

CANONICAL = "canonical"
DERIVED = "derived"
INSTALLER_DERIVED = "installer-derived"


@dataclass(frozen=True)
class Target:
    """One (version x memory) build cell of the SoftCard CP/M matrix."""
    key: str                    # canonical cell id, e.g. "2.20B/44K"
    version: str                # "2.20", "2.20B", "2.23"
    memory: str                 # "44K", "56K", "60K"
    variant: str                # chunk_map variant string (get_variant)
    defines: tuple              # OS -D defines describing this cell (for the manifest)
    provenance: str             # CANONICAL / DERIVED / INSTALLER_DERIVED
    reference: Path | None = None    # disk reconstruct verifies against (canonical/installer)
    carrier: Path | None = None      # filesystem/boot carrier for a derived cell
    derived_from: str | None = None  # diagonal Target.key the transitive check relocates from

    @property
    def is_derived(self) -> bool:
        return self.provenance == DERIVED

    @property
    def source_disk(self) -> Path:
        """The disk the OS overlay is written onto: the reference (canonical/installer)
        or the carrier (derived). Every cell has exactly one."""
        d = self.reference if self.reference is not None else self.carrier
        assert d is not None, f"target {self.key} has neither reference nor carrier"
        return d

    def basename(self) -> str:
        """Release filename stem, e.g. 'softcard-cpm2.20b-44k-derived'."""
        name = f"softcard-cpm{self.version.lower()}-{self.memory.lower()}"
        if self.provenance == DERIVED:
            name += "-derived"
        elif self.provenance == INSTALLER_DERIVED:
            name += "-installer-derived"
        return name


# ── The six cells ────────────────────────────────────────────────────────────
TARGETS: dict[str, Target] = {t.key: t for t in (
    Target(key="2.20/44K", version="2.20", memory="44K", variant="220-44k",
           defines=(), provenance=CANONICAL, reference=DISK_2_20_44K_SYSTEM),
    Target(key="2.20B/56K", version="2.20B", memory="56K", variant="220",
           defines=("CFG_56K", "V220B"), provenance=CANONICAL,
           reference=DISK_2_20B_56K_SYSTEM),
    # Derived off-diagonal 2.20 cells (never shipped; carrier = same-memory disk).
    Target(key="2.20B/44K", version="2.20B", memory="44K", variant="220b-44k",
           defines=("V220B",), provenance=DERIVED,
           carrier=DISK_2_20_44K_SYSTEM, derived_from="2.20B/56K"),
    Target(key="2.20/56K", version="2.20", memory="56K", variant="220-56k",
           defines=("CFG_56K",), provenance=DERIVED,
           carrier=DISK_2_20B_56K_SYSTEM, derived_from="2.20/44K"),
    Target(key="2.23/44K", version="2.23", memory="44K", variant="223",
           defines=(), provenance=CANONICAL, reference=DISK_2_23_44K_SYSTEM),
    # 60K: carried verbatim; provenance anchored to the byte-built CPM60.COM.
    Target(key="2.23/60K", version="2.23", memory="60K", variant="223-60k",
           defines=("V223", "CFG_60K"), provenance=INSTALLER_DERIVED,
           reference=DISK_2_23_60K_SYSTEM),
)}


def resolve(spec: str) -> tuple[Target, str | None]:
    """Resolve a 'VER/MEM' or 'VER/MEM/FMT' spec to (Target, fmt|None).

    Case-insensitive; a trailing 'b' on the version is normalized to 'B' and the
    memory to upper-case ('2.20b/44k/dsk' -> the 2.20B/44K target, fmt 'dsk').
    fmt (if given) is 'dsk' or 'po'. Raises ValueError on an unknown cell/format.
    """
    parts = [p for p in spec.strip().split("/") if p != ""]
    if len(parts) not in (2, 3):
        raise ValueError(
            f"target spec {spec!r} must be VER/MEM or VER/MEM/FMT (e.g. 2.23/60K/dsk)")
    ver = parts[0].upper() if parts[0].lower().endswith("b") else parts[0]
    mem = parts[1].upper()
    key = f"{ver}/{mem}"
    if key not in TARGETS:
        raise ValueError(f"unknown target cell {key!r}; valid: {sorted(TARGETS)}")
    fmt = None
    if len(parts) == 3:
        fmt = parts[2].lower().lstrip(".")
        if fmt not in ("dsk", "po"):
            raise ValueError(f"unknown format {parts[2]!r}; expected dsk or po")
    return TARGETS[key], fmt


# ── Transitive verification for the derived cells ─────────────────────────────
# The memory axis is a uniform +$3000 relocation: an in-image address operand's low
# byte is unchanged and its high byte is +$30. The only genuine (non-relocation) delta
# across the axis is the BIOS sign-on banner "44K"->"56K" (2 bytes). This is exactly the
# Step 0 module-level check, re-run here over the ChunkSources the derived DISK is built
# from, so a release proves the shipped cell is a pure relocation of a byte-gated disk.
_BANNER_TOKEN = frozenset({(0x34, 0x35), (0x34, 0x36)})   # '4'->'5', '4'->'6'
_GENUINE_BUDGET = {"CPM_CCP.asm": 0, "CPM_BDOS.asm": 0, "CPM_BIOS.asm": 2}


def classify_reloc(base44: bytes, reloc56: bytes) -> tuple[int, int, list]:
    """Classify per-byte deltas between a 44K image and its +$3000 (56K) sibling.
    Returns (same, reloc, genuine) where genuine is a list of (offset, base, reloc)."""
    if len(base44) != len(reloc56):
        raise ValueError("images differ in length -- not a pure relocation")
    same = reloc = 0
    genuine = []
    for i, (a, b) in enumerate(zip(base44, reloc56)):
        if a == b:
            same += 1
        elif (a + 0x30) & 0xFF == b:
            reloc += 1
        else:
            genuine.append((i, a, b))
    return same, reloc, genuine


def verify_derived(target: Target) -> str:
    """Transitively verify a DERIVED cell: assemble its three OS modules and its diagonal
    cell's OS modules from source, and assert each pair differs ONLY by the memory axis
    (identical, +$30 relocation high-byte, or the 2-byte '44K'->'56K' banner). Returns a
    one-line human description of what was proven. Raises AssertionError on any genuine
    non-relocation delta (axis entanglement) or a missing relocation.
    """
    from .assemble import assemble_chunk
    from .chunk_map import os_module_sources
    if not target.is_derived:
        raise ValueError(f"{target.key} is not a derived cell")
    diagonal = TARGETS[target.derived_from]
    dv = os_module_sources(target.variant)
    gv = os_module_sources(diagonal.variant)
    # Orient by memory: the 44K image is the relocation base, the 56K is the +$3000 sibling.
    lo, hi = (target, diagonal) if target.memory == "44K" else (diagonal, target)
    lo_src = dv if lo is target else gv
    hi_src = dv if hi is target else gv
    for name, budget in _GENUINE_BUDGET.items():
        base = assemble_chunk(lo_src[name])
        reloc = assemble_chunk(hi_src[name])
        same, nreloc, genuine = classify_reloc(base, reloc)
        assert nreloc >= 100, (
            f"{target.key} {name}: only {nreloc} +$3000 relocations -- memory axis not applied?")
        assert len(genuine) == budget and all((a, b) in _BANNER_TOKEN for _, a, b in genuine), (
            f"{target.key} {name}: {len(genuine)} genuine (non-relocation) deltas "
            f"(expected {budget} banner byte(s)): "
            f"{[(hex(o), hex(a), hex(b)) for o, a, b in genuine]}")
    return (f"OS modules are a pure +$3000 relocation of the byte-gated {diagonal.key} "
            f"disk (banner token only)")
