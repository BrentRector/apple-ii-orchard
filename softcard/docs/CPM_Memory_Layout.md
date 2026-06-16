# Microsoft SoftCard CP/M 2.23 — memory layout (44K and 60K)

A SoftCard Apple II is **two processors sharing one 64 KB of RAM**. The 6502 owns
the machine (disk, keyboard, screen); the Z-80 on the SoftCard runs CP/M. They do
not see memory the same way — the SoftCard hardware **remaps** the Z-80's address
space onto the Apple's. This document names every region CP/M uses, in both the
standard **44K** layout and the **60K** layout that `CPM60.COM` installs, and
explains how the 60K version reaches a larger program area by moving the resident
operating system into the Apple **Language Card**.

CP/M is small and has the same four parts in every layout. From the bottom of
memory up: a **base page** of system vectors and buffers; the **TPA** (Transient
Program Area), the free RAM where application programs load and run; and, stacked
at the top, the resident operating system in three layers — the **CCP** (Console
Command Processor, the command-line shell that prints the `A>` prompt), the
**BDOS** (Basic Disk Operating System, the hardware-independent file and console
services), and the **BIOS** (Basic I/O System, the hardware-specific drivers).
The 44K and 60K layouts differ only in *where* the CCP and BDOS sit. Each part is
described in full in [section 1](#1-the-z-80-cpm-address-space) below.

Because the two processors address the same RAM differently, this document draws
each layout **twice**: once in the Z-80 (CP/M) address space, the view a program
sees ([section 1](#1-the-z-80-cpm-address-space)), and once in the physical Apple
address space, where each piece really sits in the shared 64 KB
([section 3](#3-the-6502-apple-physical-address-space)). The
[window map in section 2](#2-the-softcard-window--how-the-z-80-sees-apple-ram) is
the translation between the two.

The module **base addresses** anchor everything (read from a booted image of each
disk). Each module is referred to by its base throughout this document:

| module | 44K base | 60K base |
|---|---|---|
| CCP  | `$9300` | `$D300` |
| BDOS | `$9C00` | `$DC00` |
| BIOS | `$FA00` | `$FA00` |

The CCP and BDOS move up by exactly **`+$4000` (16 KB)**; the BIOS does not move.
That 16 KB is the size of the Apple Language Card, and it is exactly how much the
program area grows — the TPA goes from ~39 KB to ~55 KB. (The page-zero `JP` at
`$0005` targets the BDOS *entry*, which is the base + 6, `$9C06` / `$DC06`; the
BDOS note below explains the +6.)

---

## 1. The Z-80 (CP/M) address space

This is the view a CP/M program sees. CP/M 2.2 has four parts stacked from the
bottom up: the **base page**, the **TPA**, and the resident system (**CCP**,
**BDOS**, **BIOS**).

### 44K layout

The whole 44K system lives in main RAM; it does **not** use the Language Card.

```
 $FFFF ┌────────────────────────────────┐
       │  BIOS scratch / stack          │
 $FA00 │  BIOS   (base $FA00)           │  Z-80 $FA00 = Apple $0A00 (RAM, not
       │                                │  ROM); 17-entry table of RPC stubs
       ├────────────────────────────────┤
       │  unused by the 44K system      │  Z-80 $B000-$F9FF: the 44K layout
       │  (Z-80 $B000-$F9FF)            │  needs no Language Card
 $B000 │                                │
       ├────────────────────────────────┤
       │  6502 RWTS runtime copy        │  Apple $BA00-$BFFF (top of main RAM)
 $AA00 │                                │
       ├────────────────────────────────┤
       │  BDOS   (base $9C00)           │  ~3.5 KB; entry is base+6 ($9C06).
       │   incl. disk-callback          │  Its disk-callback thunks sit at the
 $9C00 │   thunks (~$A900)              │  top (~$A900).
       ├────────────────────────────────┤
       │  CCP    (base $9300)           │  ~2.3 KB; the A> command shell
 $9300 │                                │
       ├────────────────────────────────┤
       │  TPA  (Transient               │  programs load at $0100; the top is
       │   Program Area)                │  FBASE = the BDOS entry $9C06.
 $0100 │                                │  The CCP ($9300) is reclaimable.
       ├────────────────────────────────┤
       │  base page                     │  vectors, default FCB, DMA buffer
 $0000 │  (vectors / FCB / DMA)         │
       └────────────────────────────────┘
```

### 60K layout

Identical in structure, except the **CCP and BDOS move `+$4000` higher** — out of
main RAM and up into the Apple Language Card (Z-80 `$B000-$DFFF` maps onto the
Language Card) — and the TPA grows into the space they vacate. The move is *not*
a uniform re-assembly: the **CCP** is a clean re-ORG, but the **BDOS** is also
patched to bank the Language Card in/out, and the **BIOS** keeps its `$FA00`
address while gaining the relocation/banking code (see
[§4](#4-how-60k-is-reached) for the byte-level evidence).

```
 $FFFF ┌────────────────────────────────┐
       │  BIOS scratch / stack          │
 $FA00 │  BIOS   (base $FA00)           │  same address, but code is patched
       │                                │  (+184B: relocation + LC banking)
       ├────────────────────────────────┤
       │  BDOS   (base $DC00)           │  in the Language Card. <- was $9C00
 $DC00 │   (reloc +$4000 + LC banking)  │  entry base+6 = $DC06
       ├────────────────────────────────┤
       │  CCP    (base $D300)           │  in the Language Card. <- was $9300
 $D300 │   (relocated +$4000)           │
       ├────────────────────────────────┤
       │  TPA  (now ~55 KB)             │  16 KB larger: it reclaims the old
       │                                │  $9300-$BFFF system RAM plus the
       │                                │  lower Language Card below the CCP
 $0100 │                                │
       ├────────────────────────────────┤
       │  base page                     │
 $0000 │  (vectors / FCB / DMA)         │
       └────────────────────────────────┘
```

### Component descriptions

* **Base page** (`$0000`–`$00FF`) — CP/M's reserved low memory, the contract
  between programs and the system:
  * `$0000`–`$0002`: `JP WBOOT` — a jump into the BIOS warm-boot entry. Jumping
    to `$0000` restarts CP/M (reloads the CCP).
  * `$0003`: **IOBYTE** — logical-to-physical device assignment (console / list /
    reader / punch).
  * `$0004`: current **drive** (low nibble) and **user** number (high nibble).
  * `$0005`–`$0007`: `JP BDOS` — the system-call entry. A program does
    `CALL $0005` with a function number in `C`. The address word at `$0006` is
    also the **top of the TPA** (the first byte a program must not touch).
  * `$0008`–`$0037`: Z-80 `RST` restart vectors (available to debuggers).
  * `$005C`–`$007C`: the **default FCB** (File Control Block) — the CCP fills it
    from the first command-line argument.
  * `$0080`–`$00FF`: the **default DMA buffer** — the 128-byte sector/record
    buffer used by disk reads and writes. At program load this same buffer holds
    the **command tail** (its length byte at `$0080`, the characters at `$0081`).

* **TPA — Transient Program Area** (`$0100` upward) — where `.COM` files load
  (always at `$0100`) and execute. Its top is **FBASE**, the value CP/M reports
  at `$0006`, which is the BDOS *entry* (`$9C06` / `$DC06`) — the first protected
  byte. With the shell present a program runs below the CCP; a program that wants
  maximum memory reclaims the CCP's space (the CCP is **reloadable** — the next
  warm boot brings it back) and may use right up to FBASE−1.

* **CCP — Console Command Processor** (base `$9300` / `$D300`) — the interactive
  shell: prints the `A>` prompt, parses a command line, runs the built-ins
  (`DIR`, `ERA`, `TYPE`, `SAVE`, `REN`, `USER`), and otherwise loads and runs the
  named `.COM` file from disk. ~2.3 KB.

* **BDOS — Basic Disk Operating System** (base `$9C00` / `$DC00`) — the
  hardware-independent OS: ~40 numbered functions for console I/O, the file system
  (open/close/read/write/make/delete/search/rename), disk selection, the DMA
  address, and the user number. Programs reach it only through `CALL $0005`. ~3.5 KB.
  The module's first 6 bytes are the CP/M **serial number** (here
  `BD 16 00 01 4D 40`, identical on every copy of this system), so the actual
  function-dispatch **entry is the base + 6** (`$9C06` / `$DC06`) — which is what
  the page-zero `JP $0005` vector points at, and what the `$0006` word reports as
  the top of the TPA (FBASE). One consequence: because FBASE is the entry, the 6
  serial bytes sit *below* it, i.e. numerically inside the TPA (`$0100`–`$9C05`).
  They are the head of the BDOS image and are never executed (the code starts at
  the entry), so a program that uses memory right up to FBASE−1 *can* overwrite
  them with no effect on the running BDOS — and a warm boot reloads the module,
  restoring them. So the protected boundary is FBASE `$9C06`, not the module base
  `$9C00`; the 6 serial bytes between them are the head of the BDOS image yet sit
  inside the TPA.

* **BIOS — Basic I/O System** (base `$FA00`, both layouts) — the hardware-specific
  bottom layer: a 17-entry jump table (BOOT, WBOOT, CONST, CONIN, CONOUT, LIST,
  PUNCH, READER, HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST,
  SECTRAN). On the SoftCard the Z-80 BIOS is a **thin stub** that marshals each
  request across to the 6502 side, which performs the actual Apple disk/console
  I/O. It lives high (`$FA00`) and **does not move** between 44K and 60K — but
  *staying put is not the same as staying the same*: the 60K BIOS keeps the
  `$FA00` address while its code is substantially patched (it gains the
  Language-Card relocation and banking; see [§4](#4-how-60k-is-reached)).

---

## 2. The SoftCard window — how the Z-80 sees Apple RAM

The Z-80's addresses are **not** the Apple's. The SoftCard translates every Z-80
access through a fixed map:

| Z-80 range | → Apple range | offset |
|---|---|---|
| `$0000`–`$AFFF` | `$1000`–`$BFFF` | `+$1000` |
| `$B000`–`$DFFF` | `$D000`–`$FFFF` | `+$2000` |
| `$E000`–`$EFFF` | `$C000`–`$CFFF` | `−$2000` |
| `$F000`–`$FFFF` | `$0000`–`$0FFF` | `−$F000` |

Two consequences matter here:

* The CP/M base page and TPA (Z-80 `$0000`–`$AFFF`) live in Apple main RAM
  (`$1000`–`$BFFF`), clear of the Apple's own zero page, stack, and text screen at
  `$0000`–`$0BFF`.
* **Z-80 `$B000`–`$DFFF` maps onto Apple `$D000`–`$FFFF`, which is exactly the
  Apple Language Card.** This is the lever the 60K layout pulls: a system placed at
  Z-80 `$D300` automatically lands in Language-Card RAM.

This also resolves a common surprise: **the BIOS at Z-80 `$FA00` is not in ROM.**
On the Apple, `$FA00` is monitor ROM — but that is the *6502's* `$FA00`. The Z-80's
`$FA00` maps (via the −`$F000` row above) to Apple `$0A00`, low main **RAM**, where
the BIOS physically lives — right next to the 6502 routines it cooperates with (the
boot RWTS loads at Apple `$0A00`, and at run time that same RAM is the Z-80 BIOS).
The Z-80 address that *does* reach the Apple ROM at `$FA00` is `$DA00`, through the
`$B000`–`$DFFF` row — which is where the 2.20 BIOS sat.

---

## 3. The 6502 (Apple) physical address space

[Section 1](#1-the-z-80-cpm-address-space) showed memory as a CP/M program sees
it. This section shows the **same RAM at its real Apple addresses** — where each
piece physically sits in the 64 KB the two processors share. The 6502 boots the
machine and then services the Z-80 BIOS's I/O requests: disk access through the
**RWTS** (Read/Write Track Sector, the Disk II sector driver), console through the
Apple monitor ROM. Run each Z-80 address from [section 1](#1-the-z-80-cpm-address-space)
through the [window map](#2-the-softcard-window--how-the-z-80-sees-apple-ram) and
you land in the diagrams below.

### 44K layout (Apple addresses)

The whole CP/M system fits in main RAM (`$0000`–`$BFFF`); the Language Card is
never banked, so `$D000`–`$FFFF` stays Apple ROM.

```
 $FFFF ┌────────────────────────────────┐
       │  Apple ROM  (Applesoft +       │  $D000-$FFFF: the Apple's own ROM.
       │  Monitor)                      │  The 44K system never banks the
 $D000 │  -- unused by 44K CP/M         │  Language Card, so this stays ROM.
       ├────────────────────────────────┤
       │  slot ROMs  ($C100-$CFFF)      │  Disk II PROM ($C600), Videx
 $C100 │                                │  80-col firmware ($C300/$C800)
       ├────────────────────────────────┤
 $C000 │  I/O soft switches             │  keyboard, display, Disk II,
       │  ($C000-$C0FF)                 │  Language-Card switches ($C08x)
       ├────────────────────────────────┤
 $BA00 │  6502 RWTS runtime copy        │  the Disk II driver, relocated to
       │                                │  top-of-RAM for the running system
       ├────────────────────────────────┤
 $B900 │  disk-callback thunks          │  = Z-80 $A900
       ├────────────────────────────────┤
 $AC00 │  BDOS  (base $AC00)            │  = Z-80 $9C00; entry $AC06 = FBASE
       ├────────────────────────────────┤
 $A300 │  CCP   (base $A300)            │  = Z-80 $9300; reclaimable by the TPA
       ├────────────────────────────────┤
       │  TPA  (Transient               │  = Z-80 $0100-$A2FF. Free RAM; top is
       │   Program Area)                │  FBASE $AC06. Programs load at $1100.
 $1100 │                                │
       ├────────────────────────────────┤
 $1000 │  Z-80 base page                │  = Z-80 $0000 (vectors / FCB / DMA)
       ├────────────────────────────────┤
 $0A00 │  Z-80 BIOS (run time)          │  = Z-80 $FA00. Boot-time RWTS loads
       │                                │  here; at run time it is the BIOS.
       ├────────────────────────────────┤
 $0800 │  boot loader (boot time)       │  sector-0 stub + stage-2 loader
       ├────────────────────────────────┤
 $0400 │  text page 1                   │  the 40-column screen
       ├────────────────────────────────┤
 $0200 │  input buffer / install        │  command-line buffer; boot install
       ├────────────────────────────────┤
 $0100 │  6502 stack                    │
       ├────────────────────────────────┤
 $0000 │  6502 zero page                │  Apple monitor + RWTS scratch
       └────────────────────────────────┘
```

Note what the window does to the addresses: the CP/M system that lives "high" for
the Z-80 (`$9300`–`$AAFF`) is actually `$A300`–`$BAFF`, just below the I/O page in
**main RAM** — and the BIOS the Z-80 reaches at `$FA00` is really down at Apple
`$0A00`, low memory, right next to the 6502 routines it cooperates with.

### 60K layout (Apple addresses)

`CPM60.COM` banks in the **Language Card** (`$D000`–`$FFFF`) and moves the resident
system up into it. The CCP lands at `$F300` and the BDOS at `$FC00`; the 6502 disk
driver moves up out of main RAM into the Language Card as well. The freed main RAM
(`$A300`–`$BFFF`) plus the lower Language Card become extra TPA.

```
 $FFFF ┌────────────────────────────────┐
 $FC00 │  BDOS  (base $FC00)            │  = Z-80 $DC00; entry $FC06 = FBASE.
       │   in the Language Card         │  Tops out at $FFFF (= Z-80 $DFFF).
       ├────────────────────────────────┤
 $F300 │  CCP   (base $F300)            │  = Z-80 $D300; in the Language Card
       ├────────────────────────────────┤
       │  TPA  (upper, in the           │  = Z-80 $C000-$D2FF. The enlarged
 $E000 │   Language Card)               │  TPA continues here, above the I/O.
       ├────────────────────────────────┤
 $D000 │  6502 disk driver +            │  = Z-80 $B000-$BFFF. Bank-switched
       │   buffers (LC, banked)         │  LC 4 KB: RWTS moved here from $BA00
       ├────────────────────────────────┤
       │  slot ROMs  ($C100-$CFFF)      │  Disk II PROM ($C600), Videx
 $C100 │                                │  ($C300/$C800)
       ├────────────────────────────────┤
 $C000 │  I/O soft switches             │  = Z-80 $E000-$EFFF -- in the window
       │  ($C000-$C0FF)                 │  this sits just ABOVE the BDOS
       ├────────────────────────────────┤
       │  TPA  (lower, main RAM)        │  = Z-80 $0100-$AFFF. Programs load
 $1100 │                                │  at $1100; the TPA is split by I/O.
       ├────────────────────────────────┤
 $1000 │  Z-80 base page                │  = Z-80 $0000 (vectors / FCB / DMA)
       ├────────────────────────────────┤
 $0A00 │  Z-80 BIOS (run time)          │  = Z-80 $FA00 (same address; code patched)
       ├────────────────────────────────┤
 $0800 │  boot loader (boot time)       │  does the Language-Card relocation
       ├────────────────────────────────┤
 $0400 │  text page 1                   │  the 40-column screen
       ├────────────────────────────────┤
 $0200 │  input buffer / install        │
       ├────────────────────────────────┤
 $0100 │  6502 stack                    │
       ├────────────────────────────────┤
 $0000 │  6502 zero page                │
       └────────────────────────────────┘
```

This is the diagram that explains the BDOS placement question. In the Z-80's view
the TPA is one contiguous run up to `$DC05`; **physically it is split by the I/O
page.** The lower TPA is main RAM (`$1100`–`$BFFF`); above it sits the Apple I/O
and slot ROMs (`$C000`–`$CFFF`, which the Z-80 never sees as memory — the window
maps them out to Z-80 `$E000`+); then the TPA resumes in the Language Card. The
resident system tops out at Apple `$FFFF`, which is exactly Z-80 `$DFFF` — the
highest address the window maps into the Language Card. The BDOS cannot grow past
it, because the next Z-80 address (`$E000`) lands back on the Apple I/O page, not
on more RAM. That is also why the I/O annotation reads "just above the BDOS":
in the Z-80's address space `$E000` (the I/O) sits immediately above the BDOS at
`$DC00`, even though physically the I/O is far *below* the Language Card.

The `$D000`–`$DFFF` band is the Language Card's bank-switched 4 KB. The booted
image shows the 6502 RWTS driver here, byte-for-byte the copy that sat at `$BA00`
in the 44K system; banking lets this same window double as TPA RAM for the Z-80.

### Fixed Apple hardware regions

The two diagrams above show *CP/M's* occupancy; the underlying Apple hardware map
is the same in both:

| Apple addr | Region | Role |
|---|---|---|
| `$0000`–`$00FF` | 6502 zero page | Apple monitor + RWTS scratch |
| `$0100`–`$01FF` | 6502 stack | |
| `$0200`–`$03FF` | input buffer / install fragments | command-line buffer; boot-time install code |
| `$0400`–`$07FF` | text page 1 | 40-column screen |
| `$0800`–`$09FF` | boot loader (boot time) | sector-0 boot stub + stage-2 loader |
| `$0A00`–`$0FFF` | RWTS (boot) → Z-80 BIOS (run) | Disk II driver at boot; at run time this same Apple RAM is Z-80 `$FA00`, the BIOS |
| `$1000`–`$BFFF` | CP/M base page + TPA (+ system, 44K) | the Z-80's `$0000`–`$AFFF`, seen through the window |
| `$C000`–`$C0FF` | I/O soft switches | keyboard, display, the Disk II controller, the Language Card switches (`$C080`–`$C08F`) |
| `$C100`–`$CFFF` | slot ROMs | the Disk II PROM (`$C600`), the Videx 80-column firmware (`$C300`/`$C800`) |
| `$D000`–`$FFFF` | Apple ROM (44K) / Language Card (60K) | ROM when the card is not banked; in 60K it is banked RAM holding the relocated CP/M system |

---

## 4. How 60K is reached

`CPM60.COM` rewrites the disk's system tracks with a system whose CCP and BDOS are
assembled `$4000` higher. Because of the SoftCard window, "Z-80 `+$4000`" means
"into the Apple Language Card":

* 44K: the system occupies Z-80 `$9300`–`$AAFF` → Apple `$A300`–`$BAFF`, in **main
  RAM**. The TPA tops out at `$9C06`.
* 60K: the system is moved to Z-80 `$D300`+ → Apple `$F300`+, in the **Language
  Card**. That returns the old `$9300`–`$BFFF` main RAM to the TPA, and lets the
  TPA also use the lower Language Card below the system. The TPA tops out at
  `$DC06` — exactly `$4000` (16 KB, the Language Card's size) higher.

The work is done by the **6502 boot loader**: it banks in the Language Card
(`STA $C08B`) and copies the system up in page blocks (CCP to `$D000`, BDOS so it
resolves at `$DC06`, leaving the BIOS at `$FA00`). The full mechanism, with the
relocated sources, is in
[`CPMV223-60K/`](../CPMV223-60K/DELTA.md).

How faithful is the move? Comparing the **pristine** 60K modules (extracted from
`CPM60.COM`'s embedded payload, never run) against the verified 44K originals,
relocation-aware:

* **CCP — a clean re-ORG.** Same length, ~99.8% byte-for-byte identical, **zero**
  inserted or deleted bytes; the only differences are absolute operands bumped
  `+$4000` (high byte `$9x`→`$Dx`) plus a handful of cross-references to modules
  that moved by other offsets. This module genuinely *is* "the same code,
  re-assembled at a higher base."
* **BDOS — the same CP/M 2.2 BDOS, but modified.** It is **not** a clean re-ORG.
  The 60K dispatch begins `LD ($E08B),A` (bank the Language Card in) where the 44K
  dispatch begins `EX DE,HL` / `LD ($9F43),HL`; the module weaves in Language-Card
  bank switches (`$E08B`/`$E083`) and is split across the card (its body addresses
  span both the lower-LC `$Bxxx` window and `$DCxx`). Far more than relocation
  changes.
* **BIOS — same address, substantially different code.** It is *not* relocated at
  all (it stays at `$FA00`), but the 60K BIOS is **~184 bytes longer** and only
  ~19% byte-identical to the 44K BIOS; it carries the cold-boot relocation loop
  and the LC banking. The shared part is the jump-table skeleton at the top, where
  the embedded CCP/BDOS base constants are patched (`9C`→`DC`, `93`→`D3`).
* **Filesystem** (tracks 3+) — untouched.

So "the 60K system is the 44K system recompiled at a higher base" is exactly true
only for the CCP. The BDOS and BIOS carry real, deliberate changes — the
Language-Card relocation and banking machinery — woven into the same code.
