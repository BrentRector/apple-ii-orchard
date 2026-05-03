"""JSON symbol-table loader for Z-80 (identical to disasm6502/symbols.py).

Loads schema v1.0 JSON files and provides a flat addr -> (name, comment)
lookup. Multiple files are merged; first-write wins on conflict.
"""

import json
import sys
from pathlib import Path


class SymbolTable:
    """Flat address -> (name, comment) lookup over many JSON files."""

    SKIP_CATEGORIES = {
        "memory_map_regions",
        "memory_model",
        "well_known_constants",
    }

    def __init__(self):
        self._by_addr = {}
        self._sources = []

    def add(self, addr, name, comment="", source=""):
        if addr in self._by_addr:
            existing_name, _ = self._by_addr[addr]
            if existing_name != name:
                print(
                    f"warning: symbol conflict at ${addr:04X}: "
                    f"keeping '{existing_name}', ignoring '{name}' from {source}",
                    file=sys.stderr,
                )
            return
        self._by_addr[addr] = (name, comment)

    def get(self, addr):
        return self._by_addr.get(addr)

    def name_for(self, addr):
        e = self._by_addr.get(addr)
        return e[0] if e else None

    def comment_for(self, addr):
        e = self._by_addr.get(addr)
        return e[1] if e else ""

    def addresses(self):
        return sorted(self._by_addr.keys())

    def items(self):
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
        path = Path(path)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        ver = data.get("schema_version")
        if ver != "1.0":
            print(f"warning: {path}: unknown schema_version {ver!r}; trying anyway",
                  file=sys.stderr)
        for cat_name, cat in data.get("categories", {}).items():
            if cat_name in self.SKIP_CATEGORIES:
                continue
            for key, entry in cat.items():
                if not isinstance(entry, dict) or not key.startswith("0x"):
                    continue
                hex_part = key[2:].split("_")[0]
                try:
                    addr = int(hex_part, 16)
                except ValueError:
                    continue
                self.add(addr, entry["name"], entry.get("comment", ""), source=str(path))
        self._sources.append(str(path))


def load_symbols(*paths):
    t = SymbolTable()
    for p in paths:
        t.load_file(p)
    return t
