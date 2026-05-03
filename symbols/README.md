# Standard Symbol Tables

Canonical address → name mappings consumed by the disassemblers (`disasm6502/`, `disasm-z80/`) and used directly as labels in hand-annotated `.asm` source.

## Files

- `cpm_2_2.json` — Digital Research CP/M 2.2 standard: BIOS jump table, BDOS function numbers, zero-page layout, FCB structure, well-known constants
- `apple2.json` — Apple ][ / ][+ standard: Monitor ROM entry points, soft switches, zero-page conventions

## Schema (v1.0)

```json
{
  "schema_version": "1.0",
  "name": "...",
  "description": "...",
  "sources": [{"name": "...", "url": "..."}],
  "categories": {
    "<category-name>": {
      "<key>": {
        "name": "CANONICAL_NAME",
        "size": 1,
        "comment": "One-line description"
      }
    }
  }
}
```

Categories are domain-specific (e.g., `page_zero`, `bios_jump_table`, `bdos_functions`, `monitor_rom`, `soft_switches`).

Keys are either:
- **Hex addresses** (`"0x0005"`) — the symbol applies to that absolute memory address.
- **Decimal small integers** (`"3"`) — used for offset-based or function-number tables (e.g., BIOS jump table is offset-from-base, BDOS function numbers are integer codes in register C).

`size` is in bytes if applicable; omitted otherwise.

## Usage

The disassemblers accept one or more symbol-table JSON files via a `--symbols` flag. When emitting an instruction whose operand resolves to a known symbol, the operand is replaced with the canonical name and an inline comment is added.

Example without symbols:
```
LD HL,($0005)      ; $0100 2A 05 00
```

With CP/M symbols:
```
LD HL,(BDOS_VEC)   ; $0100 2A 05 00 -- BDOS call vector
```

## Provenance and verification

Each `.json` file lists its sources. When a symbol is added based on inference rather than a cited source, that's noted in the entry's `comment` field as "(inferred)".
