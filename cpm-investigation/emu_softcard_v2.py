"""
DEPRECATED SHIM -- the v2 emulator grew into the softcard_emu package.

This script's logic (real SoftCard address map, bidirectional CPU
switching, sector-level disk service, monitor-entry hooks, Videx model,
$C800-$CFFF window arbitration) now lives in the top-level
`softcard_emu` package, which adds a language card and a reusable API:

    from softcard_emu import SoftCardMachine
    python -m softcard_emu CPMV233.DSK --keys "DIR\\r"

This shim keeps historical command lines working:

    python cpm-investigation/emu_softcard_v2.py CPMV233.DSK --keys "DIR\\r"

It accepts the old flags and delegates. The findings referenced from
docs/CPM_SoftCard_RealMap_Findings.md and the softcard-videx series
were produced by this code path; `git log` has the original.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from softcard_emu.__main__ import main as _main          # noqa: E402
from softcard_emu import SoftCardMachine, realmap        # noqa: E402,F401

# Back-compat aliases for scripts that imported from this module.
SoftCardV2 = SoftCardMachine


def videx_screen(machine, cols=80, rows=24):
    return machine.videx.screen_text(cols=cols, rows=rows)


if __name__ == '__main__':
    print("[emu_softcard_v2] deprecated shim -> softcard_emu", file=sys.stderr)
    _main()
