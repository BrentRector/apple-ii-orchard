"""Emulation-assisted decompilation of a CP/M ``.COM`` program to Z-80 source.

A ``.COM`` file is raw Z-80 machine code that CP/M loads at the Transient Program
Area (``$0100``) and enters there. Pure static recursive-descent disassembly
misses code reached only through computed jumps / data-driven dispatch. So this
module first *runs* the program under the nibbler Z-80 core (the same core the
SoftCard emulator uses) with a minimal CP/M BDOS shim, records every address that
actually executed, and feeds those as extra disassembly seeds to ``disasm_z80``.

The result is a richer code/data split than static analysis alone. If emulation
discovers nothing (e.g. the program immediately blocks on hardware the shim does
not model), it falls back to a static disassembly seeded at ``$0100`` — so the
tool always produces output.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from nibbler.z80_cpu import Z80CPU, Z80Halt

from .disk_format import read_disk, detect_format
from .filesystem import extract_file, softcard_params

from .region_disasm import disasm_z80_region, load_symbols

# Repo layout: softcard/cpm_pipeline/decompile_com.py -> repo root is parents[2].
_REPO_ROOT = Path(__file__).resolve().parents[2]
CPM_SYMBOLS = _REPO_ROOT / "shared" / "symbols" / "cpm_2_2.json"

TPA = 0x0100          # transient program area: where .COM loads and entry point
BDOS = 0x0005         # BDOS entry vector
WBOOT_SENTINEL = 0xFFFE   # we plant a HALT here; warm-boot (JP 0) lands on it

# CP/M BDOS functions that terminate the program.
BDOS_EXIT = {0}       # 0 = P_TERMCPM (system reset)


@dataclass
class ComTrace:
    executed: set[int] = field(default_factory=set)   # instruction start addrs in TPA
    bdos_calls: list[int] = field(default_factory=list)
    instructions: int = 0
    reason: str = "limit"        # why tracing stopped


def trace_com(com: bytes, *, max_instructions: int = 2_000_000,
              stall_limit: int = 100_000) -> ComTrace:
    """Run a .COM under a Z-80 + BDOS-shim harness; return executed addresses.

    The shim intercepts ``CALL 5`` (BDOS): it records the function in C, returns
    A=0 for everything, and stops on function 0 (program exit). A HALT planted at
    the warm-boot sentinel catches programs that exit via ``JP 0``.
    """
    cpu = Z80CPU()
    end = TPA + len(com)
    cpu.mem[TPA:end] = com

    # Page-zero CP/M conventions.
    cpu.mem[0x0000] = 0xC3                       # JP WBOOT_SENTINEL  (warm boot)
    cpu.mem[0x0001] = WBOOT_SENTINEL & 0xFF
    cpu.mem[0x0002] = WBOOT_SENTINEL >> 8
    cpu.mem[0x0005] = 0xC3                       # JP $E400 (so LD HL,(6) gives a memtop)
    cpu.mem[0x0006] = 0x00
    cpu.mem[0x0007] = 0xE4
    cpu.mem[WBOOT_SENTINEL] = 0x76              # HALT

    cpu.pc = TPA
    cpu.sp = 0xE000                             # plausible stack; programs usually set their own

    tr = ComTrace()
    steps = 0
    last_new = 0           # step index when a new address was last discovered
    for _ in range(max_instructions):
        pc = cpu.pc
        if pc == WBOOT_SENTINEL or cpu.halted:
            tr.reason = "warm-boot"
            break
        # Stop once code discovery has stalled (covers programs that block
        # polling the console under the no-input shim).
        if steps - last_new > stall_limit:
            tr.reason = "converged"
            break
        if pc == BDOS:
            fn = cpu.c
            tr.bdos_calls.append(fn)
            steps += 1
            if fn in BDOS_EXIT:
                tr.reason = "bdos-exit"
                break
            # Emulate "did nothing, returned 0", then RET to caller.
            cpu.a = 0
            cpu.l = 0
            cpu.h = 0
            ret = cpu.read16(cpu.sp)
            cpu.sp = (cpu.sp + 2) & 0xFFFF
            cpu.pc = ret
            continue
        if TPA <= pc < end and pc not in tr.executed:
            tr.executed.add(pc)
            last_new = steps
        try:
            cpu.step()
            steps += 1
        except Z80Halt:
            tr.reason = "unsupported-opcode"
            break
        except Exception as e:                  # defensive: emulation is best-effort
            tr.reason = f"error:{type(e).__name__}"
            break
    tr.instructions = steps
    return tr


@dataclass
class ComDecompileResult:
    name: str
    com_path: Path
    asm_path: Path
    size: int
    used_emulation: bool
    seed_entries: int
    executed_addrs: int
    instructions: int
    stop_reason: str
    bdos_functions: list[int]
    ai: object = None      # AnnotateResult | None

    def summary(self) -> str:
        mode = "emulation-assisted" if self.used_emulation else "static (emulation found nothing)"
        lines = [
            f"{self.name}: {self.size} bytes -> {self.asm_path}",
            f"  mode: {mode}",
            f"  emulation: {self.instructions:,} insns, "
            f"{self.executed_addrs} addrs executed, stop={self.stop_reason}",
            f"  disassembly seeds: {self.seed_entries} entries",
        ]
        if self.bdos_functions:
            fns = ", ".join(str(f) for f in self.bdos_functions)
            lines.append(f"  BDOS functions called: {fns}")
        if self.ai is not None:
            lines.append(f"  {self.ai.summary()}")
        return "\n".join(lines)


def _disassemble(com: bytes, entries: list[int], out_base: Path, source_name: str) -> Path:
    """Drive disasm_z80 over .COM bytes with the given entry seeds; return .asm path."""
    mem = bytearray(0x10000)
    mem[TPA:TPA + len(com)] = com
    src = disasm_z80_region(mem, TPA, len(com), symbols=load_symbols(CPM_SYMBOLS),
                            seeds=entries, source_name=source_name, auto_coverage=True)
    asm_path = out_base.with_suffix(".asm")
    bin_path = out_base.with_suffix(".bin")
    asm_path.write_text(src.replace("{out_bin}", bin_path.as_posix()), encoding="utf-8")
    return asm_path


def decompile_com(disk_path, name: str, out_dir,
                  *, max_instructions: int = 2_000_000,
                  ai: bool = False, ai_backend: str = "auto") -> ComDecompileResult:
    """Extract a .COM from a CP/M disk and decompile it to commented Z-80 source."""
    disk = read_disk(disk_path)
    params = softcard_params(detect_format(disk_path))
    name = name.upper()
    com = extract_file(disk, name, params)

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    com_path = out_dir / name
    com_path.write_bytes(com)

    tr = trace_com(com, max_instructions=max_instructions)
    used_emulation = bool(tr.executed)
    entries = sorted({TPA} | tr.executed)

    out_base = out_dir / Path(name).stem
    asm_path = _disassemble(com, entries, out_base, source_name=name)

    result = ComDecompileResult(
        name=name, com_path=com_path, asm_path=asm_path, size=len(com),
        used_emulation=used_emulation, seed_entries=len(entries),
        executed_addrs=len(tr.executed), instructions=tr.instructions,
        stop_reason=tr.reason,
        bdos_functions=sorted(set(tr.bdos_calls)),
    )
    if ai:
        from .annotate_ai import annotate_file
        result.ai = annotate_file(asm_path, cpu="Z-80",
                                  context=f"CP/M transient program {name}",
                                  backend=ai_backend)
    return result
