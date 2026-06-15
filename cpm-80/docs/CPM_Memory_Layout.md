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

Identical, except the **CCP and BDOS are re-assembled `+$4000` higher** — out of
main RAM and up into the Apple Language Card (Z-80 `$B000-$DFFF` maps onto the
Language Card) — and the TPA grows into the space they vacate. The BIOS does not move.

```
 $FFFF ┌────────────────────────────────┐
       │  BIOS scratch / stack          │
 $FA00 │  BIOS   (base $FA00)           │  unchanged
       ├────────────────────────────────┤
       │  BDOS   (base $DC00)           │  in the Language Card. <- was $9C00
 $DC00 │   (relocated +$4000)           │  entry base+6 = $DC06
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
  I/O. It lives high (`$FA00`) and **does not move** between 44K and 60K.

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

## 3. The 6502 (Apple) side

The 6502 boots the machine and then services the Z-80 BIOS's I/O requests —
disk access through the **RWTS** (Read/Write Track Sector, the Disk II sector
driver), console through the Apple monitor ROM. Its memory (Apple addresses):

| Apple addr | Region | Role |
|---|---|---|
| `$0000`–`$00FF` | 6502 zero page | Apple monitor + RWTS scratch |
| `$0200`–`$03FF` | input buffer / install fragments | command-line buffer; boot-time install code |
| `$0400`–`$07FF` | text page 1 | 40-column screen |
| `$0800`–`$09FF` | boot loader (boot time) | sector-0 boot stub + stage-2 loader |
| `$0A00`–`$0FFF` | RWTS (boot) → Z-80 BIOS (run) | Disk II read/write-track-sector at boot; at run time this same Apple RAM is Z-80 `$FA00`, the BIOS |
| `$1000`–`$BFFF` | CP/M base page + TPA | the Z-80's `$0000`–`$AFFF`, seen through the window |
| `$BA00`–`$BFFF` | RWTS runtime copy | the disk routines, relocated here for the running system |
| `$C000`–`$C0FF` | I/O soft switches | keyboard, display, the Disk II controller, the Language Card switches (`$C080`–`$C08F`) |
| `$C100`–`$CFFF` | slot ROMs | the Disk II PROM (`$C600`), the Videx 80-column firmware (`$C300`/`$C800`) |
| `$D000`–`$FFFF` | Language Card (16 KB) | bankable RAM; in 60K it holds the relocated CP/M system |

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
[`decompiled/CPMV233-60K/`](../decompiled/CPMV233-60K/DELTA.md).

The relocation is otherwise faithful: the CCP and BDOS are the **same code** (a
clean re-assembly — the 60K CCP is ~99% byte-for-byte the 44K CCP with its
absolute operands bumped `+$4000`), the BIOS is unchanged, and the filesystem
(tracks 3+) is untouched.
