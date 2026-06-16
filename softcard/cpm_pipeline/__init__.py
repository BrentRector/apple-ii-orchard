"""CP/M pipeline: take a CP/M .dsk image apart, understand it, put it back together.

The seven-stage roadmap is in docs/CPM_PIPELINE_ROADMAP.md. This package
implements the stages incrementally. Phase 1 (this initial version) is
Stage 7 -- .dsk reconstruction from assembled annotated source.

Quick start::

    source shared/toolchain/env.sh   # puts ca65 + ld65 + sjasmplus on PATH

    # Reconstruct CPMV233.DSK from docs/CPM223_*.asm
    python -m cpm_pipeline build 223 \\
        --reference CPMV233.DSK \\
        --output build/cpm223_rebuilt.dsk \\
        --verify

    # Same for 2.20 (.po format)
    python -m cpm_pipeline build 220 \\
        --reference CPM220Disk1.po \\
        --output build/cpm220_rebuilt.po \\
        --verify
"""

from .disk_format import (
    DOS33_INTERLEAVE, PRODOS_INTERLEAVE,
    sector_offset, detect_format,
)
from .assemble import assemble_chunk, AssemblyError
from .chunk_map import CHUNKS_220, CHUNKS_223, ChunkSpec
from .reconstruct import (reconstruct_disk, ReconstructResult,
                          reconstruct_full_disk, FullRebuildResult)
from .format_detect import detect as detect_disk, DiskFormat
from .loader_trace import (
    trace_loader, LoadSchedule, InstallCopy, LoadCpmCall,
)
from .cold_boot_trace import (
    trace_cold_boot, ColdBootSchedule,
    BiosJumpEntry, TrapMarkerPage, DispatchCase,
)
from .handoff import (
    find_handoff, HandoffInfo, VectorPlant, CpuSwitchTrigger,
)
from .version_delta import compare_disks, DiskDelta
from .generate import generate as generate_source_tree, GenerateResult

__all__ = [
    "DOS33_INTERLEAVE", "PRODOS_INTERLEAVE",
    "sector_offset", "detect_format",
    "assemble_chunk", "AssemblyError",
    "CHUNKS_220", "CHUNKS_223", "ChunkSpec",
    "reconstruct_disk", "ReconstructResult",
    "reconstruct_full_disk", "FullRebuildResult",
    "detect_disk", "DiskFormat",
    "trace_loader", "LoadSchedule", "InstallCopy", "LoadCpmCall",
    "trace_cold_boot", "ColdBootSchedule",
    "BiosJumpEntry", "TrapMarkerPage", "DispatchCase",
    "find_handoff", "HandoffInfo", "VectorPlant", "CpuSwitchTrigger",
    "compare_disks", "DiskDelta",
    "generate_source_tree", "GenerateResult",
]
