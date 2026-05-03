"""JSON symbol-table loader.

Loads one or more `..._symbols/*.json` files written to the schema documented
in `symbols/README.md`. Provides a flat `addr -> (name, comment)` lookup so
the formatter can substitute symbolic names into operands.

A SymbolTable instance is the union of every loaded file. Conflicting entries
keep the first definition (a warning is printed to stderr).
"""

import json
import sys
from pathlib import Path


class SymbolTable:
    """Flat address -> (name, comment) lookup over many JSON files."""

    def __init__(self):
        self._by_addr = {}     # int address -> (name, comment)
        self._sources = []     # list of source file paths

    def add(self, addr, name, comment="", source=""):
        """Add a single symbol. First-write wins on conflict."""
        if addr in self._by_addr:
            existing_name, _ = self._by_addr[addr]
            if existing_name != name:
                print(
                    f"warning: symbol conflict at ${addr:04X}: "
                    f"keeping '{existing_name}', ignoring '{name}' "
                    f"from {source}",
                    file=sys.stderr,
                )
            return
        self._by_addr[addr] = (name, comment)

    def get(self, addr):
        """Return (name, comment) for `addr`, or None if not in table."""
        return self._by_addr.get(addr)

    def name_for(self, addr):
        """Return the symbolic name for `addr`, or None."""
        e = self._by_addr.get(addr)
        return e[0] if e else None

    def comment_for(self, addr):
        """Return the inline comment for `addr`, or empty string."""
        e = self._by_addr.get(addr)
        return e[1] if e else ""

    def addresses(self):
        """All addresses with symbols, sorted ascending."""
        return sorted(self._by_addr.keys())

    def items(self):
        """Iterate (addr, name, comment) sorted by addr."""
        for addr in self.addresses():
            name, comment = self._by_addr[addr]
            yield addr, name, comment

    def sources(self):
        return list(self._sources)

    def __len__(self):
        return len(self._by_addr)

    def __contains__(self, addr):
        return addr in self._by_addr

    def load_file(self, path):
        """Merge symbols from one JSON file (schema v1.0)."""
        path = Path(path)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        ver = data.get("schema_version")
        if ver != "1.0":
            print(
                f"warning: {path}: unknown schema_version {ver!r}; "
                f"trying anyway",
                file=sys.stderr,
            )
        # Categories we never substitute into operands — they describe
        # regions or narrative annotations, not point symbols. Listed here
        # so the loader can hold ground truth in one place.
        SKIP_CATEGORIES = {
            "memory_map_regions",  # large region descriptors
            "memory_model",        # CP/M memory layout descriptors
            "well_known_constants",  # value constants, not addresses
        }
        for cat_name, cat in data.get("categories", {}).items():
            if cat_name in SKIP_CATEGORIES:
                continue
            for key, entry in cat.items():
                if not isinstance(entry, dict):
                    continue
                # Address-keyed entries only. Decimal-keyed entries are
                # offset/function-number tables (BIOS jump table, BDOS
                # function numbers) — they don't apply to memory addresses.
                if not key.startswith("0x"):
                    continue
                # Strip a "_dup" suffix used to disambiguate aliased addresses
                # in the JSON (multiple symbols for the same address).
                hex_part = key[2:].split("_")[0]
                try:
                    addr = int(hex_part, 16)
                except ValueError:
                    continue
                self.add(
                    addr,
                    entry["name"],
                    entry.get("comment", ""),
                    source=str(path),
                )
        self._sources.append(str(path))


def load_symbols(*paths):
    """Convenience: build a SymbolTable from one or more JSON paths."""
    t = SymbolTable()
    for p in paths:
        t.load_file(p)
    return t
