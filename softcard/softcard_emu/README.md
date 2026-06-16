# softcard_emu

A Microsoft SoftCard CP/M **system** emulator: give it an unmodified
SoftCard CP/M disk image and it boots the works — 6502 boot loader,
SoftCard CPU switch, Z-80 operating system, Videx Videoterm console —
to an interactive `A>` prompt you can type at. It boots the 44K (2.23),
56K (2.20B), and 60K (post-`CPM60`) configurations.

Built during (and instrumental to) the
[softcard-videx investigation](https://wiseowl.com/articles/softcard-videx-01-the-bug-and-the-fix);
Part 6 of that series is effectively this package's design rationale, and
[Part 10](https://wiseowl.com/articles/softcard-videx-10-the-60k-system-finally-booted)
covers the 60K bring-up.

## Architecture

The machine is a thin composition of independent subsystems. Every
processor memory access — read, write, **and instruction fetch** — flows
through one central bus that alone resolves the address map; nothing
about "who answers at this address" is scattered elsewhere.

| Module | Subsystem | Responsibility |
|---|---|---|
| `bus.py` | `Bus` | Owns the 64 KB plane; the single address decoder for LC banking, slot ROM, the `$C800` window, and every soft switch. Routes both CPUs' read/write/fetch. |
| `cpus.py` | `Cpu6502`, `Z80` | Wrap the reusable `nibbler` instruction cores as first-class subsystems. |
| `switch.py` | `SoftCardSwitch` | The CPU-switch policy (`realmap`, `Yield`, the trigger conditions, the resume rule). |
| `keyboard.py` | `Keyboard` | The `$C000`/`$C010` latch and the per-CPU poll counters the idle heuristics watch. |
| `langcard.py` | `LanguageCard` | `$D000-$FFFF` bank/write-enable + the `$C080-$C08F` soft switches. |
| `videx.py` | `VidexVideoterm` | Firmware ROM, CRTC, paged VRAM, and `$C800` window ownership/arbitration. |
| `machine.py` | `SoftCardMachine` | Thin glue: builds the subsystems, wires the bus to the CPUs, installs the boot/monitor/sector PC hooks, and runs the cooperative CPU-alternation loop. |

## What's modeled

| Component | Model |
|---|---|
| 6502 + Z-80 | full instruction sets (`nibbler.cpu`, `nibbler.z80_cpu`), one shared 64 KB Apple memory |
| SoftCard | the documented four-window Z-80→Apple address translation; bidirectional CPU switch on any access to the card's slot page |
| Disk II | controller soft switches + synthetic GCR nibble streams; by default, reads/writes are serviced at the RWTS sector primitive straight from the `.dsk`/`.po` image (`--real-rwts` restores the nibble path) |
| Videx Videoterm | real 1 KB firmware ROM executed as 6502 code; MC6845 register file; paged 2 KB VRAM; faithful `$C800-$CFFF` expansion-ROM window arbitration with fault logging (`--flat-c800` for a permissive window) |
| Language card | 16 KB bankable RAM at `$D000-$FFFF` with the standard `$C080-$C08F` soft switches, two `$D000` banks, write-protect/pre-write semantics — and **6502 instruction fetches honor the banking** (the 60K system executes its relocated OS out of LC RAM) |
| Apple monitor | entry points the loader and warm loop use, serviced as PC hooks (register SAVE/RESTORE move real data — they're the RPC channel) |

## Usage

```sh
python -m softcard_emu softcard/CPMV223-44K/CPMV223-44K.DSK --keys "DIR\r"
```

```python
from softcard_emu import SoftCardMachine

m = SoftCardMachine("softcard/CPMV223-44K/CPMV223-44K.DSK")        # or softcard/CPMV220/CPMV220-Disk1.po
m.type_keys("DIR\r")
print(m.run())                            # 'z80-idle (keyboard poll)' etc.
print("\n".join(m.screen_text()))         # the 80-column display
```

Useful switches: `--no-videx` (console on the 40-column page),
`--no-langcard`, `--flat-c800`, `--real-rwts`, `--videx-rom PATH`,
`--steps N`.

Instrumentation surfaces on the machine object: `videx.fault_count` /
`videx.faults` / `videx.events` (window-ownership log), `disk_reads`
/ `disk_writes`, `switches`, `text40()`, `lc` state. The subsystems are
also exported for use in isolation (`from softcard_emu import Bus,
Cpu6502, Z80, LanguageCard, Keyboard, SoftCardSwitch`).

## The party trick

The window-arbitration switch reproduces the historical field-failure
matrix that started the investigation:

| Configuration | Result |
|---|---|
| CP/M 2.20B + Videx | millions of window faults, blank screen |
| CP/M 2.20B, no Videx | boots clean to the console wait |
| CP/M 2.23 + Videx | boots; interactive `DIR` works |

## The 60K system

The emulator boots the post-`CPM60` 60K build (its resident OS relocated
into the language card), and it can **run the real `CPM60.COM` itself**:
boot the stock 44K disk, run `CPM60`, and its ~48-pass system rewrite
persists into the in-memory disk image through the sector hook — the
produced disk boots as 60K. Checked against a disk a real Apple produced,
the boot loader and relocator (tracks 0–1) come out **byte-identical**;
the only divergence is on track 2, and it is provably
uninitialized staging RAM that `CPM60` copies but never writes (zero here,
leftover bytes on a used machine — functionally don't-care). See
[Part 10](https://wiseowl.com/articles/softcard-videx-10-the-60k-system-finally-booted)
for the full investigation.

## Known limitations

- **Functional, not cycle-accurate.** No bus-phase timing; floating
  bus reads as `$FF`. Window faults are detected exactly; post-fault
  behavior on real hardware would differ in its particulars.
- **The `$C800` window-release rule is the A2FPGA's**, deliberately —
  it's the platform the failure was reported on. Whether a physical
  Videoterm board releases the window identically is the one open
  question the softcard-videx series leaves (Part 5).
- ROMs: the Videoterm firmware image ships in `roms/`; the Disk II P6
  PROM image is optional (a boot hook services the PROM's read loop).

## Tests

```sh
python -m pytest softcard/softcard_emu/tests
```

Twelve tests: five whole-system smoke boots (both disks to their
interactive — or faithfully dead — states, plus language-card banking),
and seven isolation unit tests for the extracted subsystems (bus
dispatch + return contracts, keyboard counters/strobe, the switch
resume rule and `realmap`).
