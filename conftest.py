"""Make the repository's packages importable during test collection.

The project is organized into three top-level trees:

    apple-ii/   Apple II reverse-engineering work
    softcard/     CP/M-80 / Microsoft SoftCard work
    shared/     reusable tooling (nibbler, disasm*, symbols, toolchain)

The importable Python packages live one level down inside these trees
(`shared/nibbler`, `softcard/softcard_emu`, `softcard/cpm_pipeline`,
`shared/disasm6502`, ...). Adding each tree root to ``sys.path`` lets the
packages be imported by their bare names (``import nibbler``) from any test,
regardless of which tree the test itself lives in. This mirrors what
``pip install -e .`` (see pyproject.toml) or ``source shared/toolchain/env.sh``
provide outside the test runner.
"""

import sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parent

for _name in ("shared", "softcard", "apple-ii", "."):
    _dir = (_ROOT / _name).resolve()
    if _dir.is_dir() and str(_dir) not in sys.path:
        sys.path.insert(0, str(_dir))
