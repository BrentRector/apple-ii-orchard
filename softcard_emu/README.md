# softcard_emu

A Microsoft SoftCard CP/M **system** emulator: give it an unmodified
SoftCard CP/M disk image and it boots the works — 6502 boot loader,
SoftCard CPU switch, Z-80 operating system, Videx Videoterm console —
to an interactive `A>` prompt you can type at.

Built during (and instrumental to) the
[softcard-videx investigation](https://wiseowl.com/articles/softcard-videx-01-the-bug-and-the-fix);
Part 6 of that series is effectively this package's design rationale.

## What's modeled

| Component | Model |
|---|---|
| 6502 + Z-80 | full instruction sets (`nibbler.cpu`, `nibbler.z80_cpu`), one shared 64 KB Apple memory |
| SoftCard | the documented four-window Z-80→Apple address translation; bidirectional CPU switch on any access to the card's slot page |
| Disk II | controller soft switches + synthetic GCR nibble streams; by default, reads are serviced at the RWTS sector-read primitive straight from the `.dsk`/`.po` image (`--real-rwts` restores the nibble path) |
| Videx Videoterm | real 1 KB firmware ROM executed as 6502 code; MC6845 register file; paged 2 KB VRAM; faithful `$C800-$CFFF` expansion-ROM window arbitration with fault logging (`--flat-c800` for a permissive window) |
| Language card | 16 KB bankable RAM at `$D000-$FFFF` with the standard `$C080-$C08F` soft switches, two `$D000` banks, write-protect/pre-write semantics |
| Apple monitor | entry points the loader and warm loop use, serviced as PC hooks (register SAVE/RESTORE move real data — they're the RPC channel) |

## Usage

```sh
python -m softcard_emu CPMV233.DSK --keys "DIR\r"
```

```python
from softcard_emu import SoftCardMachine

m = SoftCardMachine("CPMV233.DSK")        # or CPM220Disk1.po
m.type_keys("DIR\r")
print(m.run())                            # 'z80-idle (keyboard poll)' etc.
print("\n".join(m.screen_text()))         # the 80-column display
```

Useful switches: `--no-videx` (console on the 40-column page),
`--no-langcard`, `--flat-c800`, `--real-rwts`, `--videx-rom PATH`,
`--steps N`.

Instrumentation surfaces on the machine object: `videx.fault_count` /
`videx.faults` / `videx.events` (window-ownership log), `disk_reads`
/ `disk_writes`, `switches`, `text40()`, `lc` state.

## The party trick

The window-arbitration switch reproduces the historical field-failure
matrix that started the investigation:

| Configuration | Result |
|---|---|
| CP/M 2.20B + Videx | millions of window faults, blank screen |
| CP/M 2.20B, no Videx | boots clean to the console wait |
| CP/M 2.23 + Videx | boots; interactive `DIR` works |

## Known limitations

- **Functional, not cycle-accurate.** No bus-phase timing; floating
  bus reads as `$FF`. Window faults are detected exactly; post-fault
  behavior on real hardware would differ in its particulars.
- **6502 instruction fetches bypass the banking/window hooks** (the
  core fetches via `mem[pc]`). Monitor-ROM execution is provided by PC
  hooks, firmware bytes are mirrored into the fetch plane, and
  fetch-side window faults are caught by PC hooks — but 6502 code
  *executing from LC RAM* would read the flat plane. No known SoftCard
  CP/M code does this.
- **`CPM60` (the 60K system loader on the 2.23 disk) does not yet come
  up** — it loads, partially modifies the system, and wedges in a
  console-status poll. The 44K (2.23) and 56K (2.20B) configurations
  boot and run; 60K bring-up is an open investigation.
- ROMs: the Videoterm firmware image ships in `roms/`; the Disk II P6
  PROM image is optional (a boot hook services the PROM's read loop).

## Tests

```sh
python -m pytest softcard_emu/tests
```

Five smoke tests boot both real disk images to their interactive (or
faithfully-dead) states and exercise the language-card banking.
