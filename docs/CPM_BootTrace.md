# Microsoft SoftCard CP/M — End-to-End Boot Trace

**From sector 0 to A>**, on Apple II hardware with a Microsoft SoftCard
in slot 4 and (typically) a Disk II controller in slot 6.

This document traces what happens between the moment the Apple's Disk II
P6 PROM begins loading the disk's first sector and the moment the user
sees the CP/M prompt. It is the synthesis document — for per-routine
detail, it cross-references the dedicated source files and the CP/M
Videx article series.

The trace covers both 2.20 and 2.23 versions and explicitly notes the
divergence points (the same Videx-fix delta documented in
[`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md)).

---

## Companion documents

| Document | What it covers |
|---|---|
| [`CPM_BootLoader.md`](./CPM_BootLoader.md) | 6502 side, per-routine narrative |
| [`CPM_DiskSectorMap.md`](./CPM_DiskSectorMap.md) | Every disk sector classified by purpose |
| [`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md) | The 2.20 vs 2.23 byte-level delta |
| [`CPM_Filesystem.md`](./CPM_Filesystem.md) | CP/M 2.2 file system on Apple disks |
| `CPM223_*.asm` (6 files) | 2.23 annotated assembly source (round-trips byte-identical) |
| `CPM220_*.asm` (5 files) | 2.20 annotated assembly source (round-trips byte-identical) |

| Article | Where it fits in this trace |
|---|---|
| [Part 1 — Why CP/M Didn't Recognize an 80-Column Card](https://wiseowl.com/articles/cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card) | Stage-2 slot scanner (the 11-byte branch) |
| [Part 2 — From the Disk II ROM to the Z-80's First Instruction](https://wiseowl.com/articles/cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction) | P6 PROM through Z-80's reset vector |
| [Part 3 — Apple Memory Through Z-80 Eyes](https://wiseowl.com/articles/cpm-videx-03-apple-memory-through-z-80-eyes) | The SoftCard XOR mapping (this trace's "memory model") |
| [Part 4 — The Handoff](https://wiseowl.com/articles/cpm-videx-04-the-handoff) | PREP_HANDOFF and the Z-80 reset-vector plant |
| [Part 5 — The BIOS That Half-Exists](https://wiseowl.com/articles/cpm-videx-05-the-bios-that-half-exists) | Why the BIOS is partly runtime-generated |
| [Part 6 — The BIOS Factory](https://wiseowl.com/articles/cpm-videx-06-the-bios-factory) | Cold-boot generator dispatching per device code |
| [Part 7 — From Reset to Device Scan](https://wiseowl.com/articles/cpm-videx-07-from-reset-to-device-scan) | Z-80's first instructions through device scan |
| [Part 8 — The Cooperative CPU](https://wiseowl.com/articles/cpm-videx-08-cooperative-cpu) | Bidirectional disk I/O after the SoftCard switch |
| [Part 10 — The CPU Switch, and What's Left](https://wiseowl.com/articles/cpm-videx-10-the-cpu-switch) | The JSR `$0E36` mechanism specifically |

Roman-numeral references in section headers below (§II, §III, etc.) are
to those articles.

---

## Memory model: two CPUs, one address space

Before the trace can make sense, the SoftCard's address-space model:

The Apple II 6502 sees memory in the standard layout — `$0000` to `$BFFF`
is RAM, `$C000-$CFFF` is I/O, `$D000-$FFFF` is ROM (or LC RAM bank-
switched). The SoftCard adds a Z-80 that shares the *same physical RAM*
but sees it through a transformation: **for addresses below `$2000`, the
Z-80 sees `apple_addr XOR $1000`**. Apple `$0E36` is Z-80 `$1E36`. Apple
`$0A00` is Z-80 `$1A00`. Above `$2000`, the addresses match.

This matters because the boot pipeline runs on the 6502 first, then
flips to the Z-80 mid-instruction (the SoftCard "CPU switch"). After the
flip, the Z-80 reads bytes the 6502 wrote, but at XOR'd addresses for
the low region. A single physical byte at Apple `$0A00` is read as
`$0A00` if you're a 6502 and as `$1A00` if you're a Z-80.

Page §III walks this in detail. The end-to-end trace below uses Apple
addresses for 6502-side code and Z-80 addresses for Z-80-side code; the
XOR mapping is implicit at the transition.

---

## §I — Disk II PROM: the first 256 bytes

**State at start:** Apple II powered on. Disk II controller in some slot
(typically 6). A bootable CP/M `.dsk` (or WOZ) image in the drive. User
hits CTRL-RESET or boots the slot manually.

The Disk II's P6 PROM runs from `$Cn00-$CnFF` where `n` is the slot
number (`$C600-$C6FF` for slot 6). It performs the elaborate 6-and-2
GCR address-field search and data-field decode dance to read **physical
sector 0 of track 0** into Apple `$0800-$08FF`. Then it `JSR`s to
`$0801`.

Why `$0801` and not `$0800`? Because the byte at `$0800` is a *page
count* the P6 PROM checks (and increments) to know how many sectors it
has loaded. The boot stub starts at `$0801`. The P6 PROM convention is:
the first byte of the boot sector is `$01`, indicating "one page
loaded." The stub will increment that count later.

On entry to `$0801`, the P6 PROM has set up:
- `X = slot * 16` (e.g. `$60` for slot 6)
- `$27 = $09` (one past the destination page already used, i.e. ready
  for next sector to land at `$0900` — but the stub will override this)
- `$3D = 1` (next sector index)
- `$26-$27` is the destination pointer the P6 PROM uses internally

The 60-byte boot stub at `$0801-$083C` is the entry to the loader.

**Per-sector reference:** see [`CPM_DiskSectorMap.md`](./CPM_DiskSectorMap.md)
for what physical sector 0 contains at the byte level. **Per-instruction
prose:** see [`CPM223_BootLoader.asm`](./CPM223_BootLoader.asm) §SECTION 1.

---

## §II — Boot stub: load 10 more sectors of track 0

The stub does three things in 60 bytes:

**(a) One-time setup.** Computes the slot number from the X register,
builds a `$Cn5C` pointer (where `Cn = $C0 + slot`), stores it at
`$3E/$3F`. `$Cn5C` is the P6 PROM's "search for field prolog" entry —
mid-routine code that reads *one* sector identified by `$3D` and stores
it via the `$26/$27` pointer. The stub sets up the indirect-jump target
once.

**(b) Sector-load loop.** Increments a counter at `$00`, looks up the
next physical sector to read in the skew table at `$082D`, stores it at
`$3D`, then `JMP ($003E)` — which jumps to `$Cn5C`, the P6 PROM mid-
routine entry. The P6 PROM reads one sector, increments `$27` (its
destination page counter), then `JMP $0801` (its end-of-load behavior
also fires for these mid-routine calls). Control flow returns to the
stub's top.

**(c) Termination.** The loop terminates when the counter at `$00`
reaches `$0B` (eleven). Total sectors loaded by the stub: 10 (the loop
runs from `$01` to `$0A` inclusive, since `$00` was incremented by the
"one-time setup" stage). The 10 sectors fill Apple `$0A00-$1300`. Then
`JMP $1000` to stage 2.

The skew table at `$082D-$083C` is `$00 $02 $04 $06 $08 $0A $0C $0E $01
$03 $05 $07 $09 $0B $0D $0F` — the CP/M sector skew (read even sectors
first, then odd). This is *not* DOS 3.3 skew; SoftCard CP/M imposes its
own physical-to-logical sector mapping at this layer.

After the stub completes, Apple memory contains:
- `$0800-$08FF`: boot stub + skew table + copyright string + zero pad
- `$0900-$09FF`: untouched (P6 PROM workspace, never overwritten)
- `$0A00-$0FFF`: disk I/O routines (RWTS-style; loaded as the first
  10 sectors of track 0 in skew order)
- `$1000-$13FF`: stage-2 loader

**Detail:** [`CPM_BootLoader.md`](./CPM_BootLoader.md) §SECTION 1 walks
the stub instruction by instruction. The P6 PROM's mid-routine entry is
documented in [`DiskII_BootROM.md`](./DiskII_BootROM.md).

---

## §III — Stage 2: language card, slot scan, install copies, LOAD_CPM

Stage 2 starts at `$1000`. Five concerns, in order:

**(a) Bring up the language card.** Two reads of `$C081` enable LC RAM
read, but with ROM still readable on read; the second read is a
SoftCard-specific quirk that primes the bank state. The Z-80 will need
RAM at addresses where the Apple's monitor ROM normally lives, so LC
RAM has to be writable before any LOAD_CPM call writes there.

**(b) Apple I/O setup.** Calls to `TEXT` (`$FB2F`), `SETVID` (`$FE93`),
and `SETKBD` (`$FE89`) reset the Apple to text mode and reset the input
and output device hooks to their default ROM routines. CP/M will use
these for any console I/O the BIOS routes to the Apple side.

**(c) Slot scanner.** The crucial routine. Walks slots 4, 3, 2, 1 (in
that order — high to low) and at each slot reads two bytes from the
slot ROM: `$Cn05` and `$Cn07`. Compares against signature tables in
stage 2 (`SIG_TABLE_BYTE1` at `$11BE` and `SIG_TABLE_BYTE2` at `$11C2`).
On a match, records a per-slot device code in the dispatch table.

The signature pairs encode: Apple Disk II controller (`$03/$3C`),
unknown Microsoft serial (`$18/$38`), Pascal 1.0 firmware (`$38/$18`),
unknown Microsoft printer (`$48/?`).

**This is the divergence point between 2.20 and 2.23.** The 2.23 stage
2 has 11 additional bytes that perform a *third* read (`$Cn0B`) and
match a Pascal-1.1 marker. When that match succeeds, the device code
recorded for the slot is `$06` instead of `$04`. The 2.20 stage 2
lacks this branch, so a Pascal-1.1 firmware card (e.g., a Videx
Videoterm) registers as device `$04` in 2.20 but as `$06` in 2.23.

This single 11-byte difference is the root cause of every divergent
behavior between 2.20 and 2.23. See [Part 1](https://wiseowl.com/articles/cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card)
for the byte-level deconstruction and [`CPM_Videx_Difference.md`](./CPM_Videx_Difference.md)
for the deeper version comparison.

**(d) Install copies.** Three small copy loops at `$1041/$104F/$10F1`
move the page-2 and page-3 install images from `$1200-$13FF` to
`$0200-$03FF`. The result is that `$0200-$03FF` becomes populated with
the warm-boot routine, per-device handler-target table, and small data
blocks documented in [`CPM223_InstallFragments.asm`](./CPM223_InstallFragments.asm).

**(e) LOAD_CPM.** Calls `$0E10` (in the disk-I/O block at the bottom
of the loader) which reads N more sectors from disk into a high-memory
staging area. For 2.23, N is 29 sectors; for 2.20, N is 28. The staging
area is `$A300-$BFFF` for the CCP+BDOS image; LOAD_CPM also fetches
sectors that go into `$8000` and other addresses.

After LOAD_CPM completes, all the bytes that will eventually become
the running CP/M live in Apple RAM, but at staging addresses, not
runtime addresses.

**Detail:** [`CPM_BootLoader.md`](./CPM_BootLoader.md) §SECTION 3 and
SECTION 4. [Part 2](https://wiseowl.com/articles/cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction)
covers the slot-scanner choreography and the ASCII boot banner output.

---

## §IV — PREP_HANDOFF: relocate everything to runtime addresses

Once LOAD_CPM has staged all sectors, three page-copy loops move the
content into final position. Microsoft used a single subroutine
(PAGE_COPY at `$115C`) parameterized by source/destination/page-count
in zero-page slots `$50-$53` and X. The three calls:

**PREP_HANDOFF #1.** Source `$8000` → destination `$BD00`. 256 bytes —
this is the GCR codec data tables that the LC-RAM-resident RWTS will
need. Specifically the 256-entry decode table at `$BD04` and the 64-
entry encode table at `$BD5A`. The static analysis showed these tables
came from disk via the boot stub; PREP_HANDOFF #1 places them where
the LC-RAM RWTS expects them.

**PREP_HANDOFF #2.** Source `$8000` → destination `$0A00`. This places
the BIOS jump table — which the static disasm originally assumed lived
at `$FAB8` — at the address the runtime cooperative-CPU disk I/O loop
reads from. The emulator pass discovered this in [Part 11](https://wiseowl.com/articles/cpm-videx-11-emulator-verified)
(the Stage-2 devlog); the static disasm of `bios_223.bin` had placed
the table at `$FAB8`, but runtime memory dumps showed `$FAB8` is where
the *handler bodies* live and the table itself is at Apple `$0A00`
(= Z-80 `$1A00`).

**PREP_HANDOFF #3.** Source `$A300` → destination `$8000`. 5888 bytes —
the CCP + BDOS code, relocated to the runtime address that the BDOS
entry vector at `$0005-$0007` will point to.

After PREP_HANDOFF, the runtime layout is in place:
- `$8000-$96FF`: CCP + BDOS (final position)
- `$9C06`: BDOS entry point (where `$0005-$0007` will be planted to point)
- `$BD00-$BDFF`: GCR codec tables (where LC-RAM RWTS reads them)
- `$0A00-$0FFF`: 6502 RWTS routines + BIOS jump table at `$0A00`
- `$0200-$03FF`: install fragments (warm boot, dispatch tables)
- LC RAM `$D000-$FFFF` (or `$E4-$FF` page range): bank-switched RWTS
  copy that the Z-80 disk-callback area will reach via the cooperative
  model

The 6502 has done everything it can statically. Time to hand off.

**Detail:** [Part 4](https://wiseowl.com/articles/cpm-videx-04-the-handoff)
walks the three PREP_HANDOFFs in narrative form. [`CPM_BootLoader.md`](./CPM_BootLoader.md)
§SECTION 5 documents the per-routine 6502 mechanics.

---

## §V — Boot finalization: plant Z-80 vectors, trigger CPU switch

A short sequence at `$1100-$114B` does the final 6502-side work before
handing off:

**Plant Z-80 reset vector at Apple `$0000-$0002`.** Stores `$C3` (Z-80
JP opcode), then `$00 $DA` for 2.20 (jump to `$DA00`) or `$00 $FA` for
2.23 (jump to `$FA00`). After the SoftCard switch, the Z-80 reads its
reset vector from `$0000-$0002` (via the bit-12 XOR'd address `$1000-
$1002`) and jumps to the cold-boot entry.

**Plant Z-80 BDOS call vector at Apple `$0005-$0007`.** Stores `$C3`
followed by the 16-bit BDOS entry address. For 2.23, that's `$9C06`
(so user programs `CALL $0005` → `JP $9C06`). For 2.20, the BDOS
entry is at `$CC06`. The address depends on where PREP_HANDOFF #3
placed CCP+BDOS.

**Patch Apple monitor reset vectors at `$FFFA-$FFFF`.** A short loop
copies six bytes from `$116D-$1172` into `$FFFA-$FFFF`. These six bytes
are the Apple's NMI / RESET / IRQ vectors that the Apple monitor would
normally return to. After this patch, even if the user hits CTRL-RESET,
the Apple monitor returns into CP/M land instead of dropping to the
monitor prompt. (This patch is what makes CP/M "stick" between
applications — it survives soft resets.)

**`JMP $03D2`** to enter the install-fragment runtime. `$03D2` is the
middle of the warm-boot routine at `$03C0-$03DD` (in
[`CPM223_InstallFragments.asm`](./CPM223_InstallFragments.asm)). The
warm-boot routine does:
1. Bank in LC RAM via `LDA $C083` twice
2. Touch `$FFFF` (the LC RAM top page) to flush any pending state
3. Bank in LC bank 2 via `LDA $C081`
4. **`JSR $0E36`** ← THE CPU-SWITCH TRIGGER

Apple `$0E36` is the bit-12 XOR'd alias of Z-80 `$1E36`. The bytes at
`$0E36/$1E36` are the first instruction of the cooperative-CPU sync
polling loop on the Z-80 side. The 6502 doesn't actually execute
those bytes as 6502 instructions — the SoftCard hardware monitors the
6502's address bus, and when the 6502 fetches from `$0E36`, the
SoftCard intercepts the fetch and *flips the bus* from 6502 to Z-80.
The Z-80 takes over execution starting at the same physical address
($1E36 from the Z-80's perspective).

This is a clever piece of hardware — the SoftCard turns a 6502 `JSR`
into a Z-80 jump by interpreting the bus state, not the bytes. See
[Part 10](https://wiseowl.com/articles/cpm-videx-10-the-cpu-switch)
for the full mechanism.

After this `JSR`, the 6502 is suspended. The Z-80 is the active CPU.

**Detail:** [`CPM223_InstallFragments.asm`](./CPM223_InstallFragments.asm)
§SECTION 3. [Part 10](https://wiseowl.com/articles/cpm-videx-10-the-cpu-switch)
end-to-end.

---

## §VI — Z-80 takes over: cold-boot

The Z-80 begins executing at the address corresponding to Apple `$0E36`
(Z-80 `$1E36`). The cooperative-CPU polling loop at `$1E39-$1E44`
manages disk I/O — the Z-80 raises a sync flag, waits for the 6502
(woken by a complementary mechanism) to perform the disk read, then
the 6502 raises an ack flag and the Z-80 reads the data.

But that's the *steady-state* loop. On first entry, the Z-80 hasn't
done anything yet, so the path is different: the Z-80's **reset vector
fires**.

Z-80 reset fetches three bytes from `$0000`. The 6502 planted
`$C3 $00 $DA` (2.20) or `$C3 $00 $FA` (2.23) there in §V. So the Z-80
executes `JP $DA00` or `JP $FA00`.

**For 2.23**, `$FA00` lives in the LC RAM region the LC bank-switching
exposed before the handoff. The bytes there are partly static (loaded
from disk) and partly placeholder (will be overwritten by the cold-boot
generator). The static code at `$FA00-$FAB7` does setup: bring up
internal state, then `JP $FAB8` (the start of the BIOS jump table).

But — and this is where the runtime pass surfaced something the static
analysis missed — the actual BIOS jump table at runtime is at Z-80
`$1A00`, not `$FAB8`. PREP_HANDOFF #2 placed it there. So the path is
`JP $FAB8`, but `$FAB8` is *also* where handler bodies live, and
control falls through into the cold-boot setup that runs before the
jump-table dispatch begins serving real CP/M calls.

**For 2.20**, the equivalent code lives at `$DA00-$DACB`, with the BIOS
jump table at `$DACC` and handler bodies at `$DACC-$E2CB`. Same shape,
different addresses.

**Cold-boot generator.** At `$FB3A` (2.23) or `$DBxx` (2.20). Walks the
slot-info table at `$F3B8+E` for `E = 7, 6, 5, 4, 3, 2, 1` and
dispatches per device code. The cases:
- code 3 → `CALL INIT_KEYBOARD` at `$FE81`
- code 4 → `CALL INIT_PASCAL_1_0` at `$FD83`
- code 6 → `CALL INIT_PASCAL_1_1` at `$FDB0` ← **2.23-only**

The 2.20 generator has no code-6 case. If the slot info contains a 6
(which 2.20's slot scanner never writes, but if it did), the dispatch
would land on whatever bytes happen to live at the corresponding
address — for 2.20 that's `$DBxx` worth of trap markers, not a real
handler.

This is the second half of the 2.20 hang's causal chain. The 2.20
6502-side slot scanner doesn't write `$06` for Pascal-1.1 cards (no
detection branch), so the Z-80 cold-boot generator never sees a `$06`
and never tries to dispatch to the missing case. But if it did — if
some other path put a `$06` into the slot table — the dispatch would
crash. The 2.23 fix is two-sided: 6502 side writes `$06`, Z-80 side
handles it.

The cold-boot generator overwrites the trap-marker pages
($FBB8-$FCB7, $FDB8-$FEB7, $FFB8-$FFFF in 2.23) with runtime-
generated handler bodies. Each handler body is the appropriate per-
device init code for whatever cards the slot scan flagged. After the
generator runs, the trap-marker pages contain real, executable Z-80
code that the BIOS jump-table entries can dispatch to.

**Detail:** [Part 6](https://wiseowl.com/articles/cpm-videx-06-the-bios-factory)
walks the cold-boot generator end-to-end. [`CPM223_BIOS.asm`](./CPM223_BIOS.asm)
§SECTION 3 has the per-instruction prose.

---

## §VII — BIOS init, BDOS sentinel, and CCP cold start

After the cold-boot generator finishes, the Z-80 BIOS is fully
populated. Several pieces of state setup happen:

**BDOS sentinel check.** At `$FB7F-$FB85` (2.23), the BIOS reads
`$9C08` (the byte right after BDOS_ENTRY). On cold boot this byte is
`$9C` (the high byte of `$9C06`, an artifact of how the CCP+BDOS
image was laid out). The BIOS recognizes this and proceeds with
cold-start setup. On warm boot (e.g., after a CTRL-C from the user
back to CCP), this byte will be different and the BIOS takes the
warm-boot path instead.

**Plant warm-boot vector at `$0000-$0002`.** Rewrites the Z-80 reset
vector from `JP $FA00` (cold boot) to `JP $FA03` (warm boot, three
bytes later — skips the cold-boot setup). After this rewrite, any
subsequent reset (from a transient program ending or from CTRL-RESET)
brings the system back up via the warm-boot path that re-loads the
CCP from disk but skips full re-initialization.

**Plant BDOS call vector at `$0005-$0007`.** The 6502 already did this
in §V; the Z-80 BIOS confirms it. User programs reach BDOS via
`CALL $0005` which becomes `JP $9C06` (or `$CC06` in 2.20).

**Stack setup.** `LD SP, $0080`. CP/M convention: the stack grows
downward from `$0080` (just below the default disk transfer area
DMA at `$0080-$00FF`).

**Console init.** The cold-boot generator already populated CONST/
CONIN/CONOUT handlers in the trap-marker pages. The BIOS calls them
to do final per-device setup (e.g., 80-column cards write to their
CRTC programming registers; printers send any reset commands).

**JP into CCP.** Final transfer is to the CCP's cold-start entry at
`$8000`. The CCP initializes its built-in command parser, sets the
default drive (A:), prints any sign-on message (the Microsoft boot
banner is built into the CCP image), and prints the prompt `A>`.

**A>** appears on screen. The CCP is in its main loop, reading from
CONIN, parsing built-in commands, looking up `.COM` files in the
directory of the current drive, executing them.

The system is up.

**Detail:** [Part 5](https://wiseowl.com/articles/cpm-videx-05-the-bios-that-half-exists)
explains the static-vs-runtime BIOS layout. [Part 7](https://wiseowl.com/articles/cpm-videx-07-from-reset-to-device-scan)
walks the Z-80's first instructions through device scan.

---

## §VIII — Steady state: cooperative-CPU disk I/O

After A>, when the user types a command that requires disk I/O (e.g.,
`DIR` or running a `.COM` file), the BIOS jump-table entries READ /
WRITE / SETSEC / SETDMA fire. These don't read the disk directly —
the SoftCard's Z-80 doesn't have access to the Disk II controller's
registers (those are on the Apple I/O page `$C0F0-$C0FF` for slot 6,
which the Z-80 sees via XOR'd addresses but doesn't have hardware
control over).

Instead, the cooperative-CPU model kicks in:
1. The Z-80 sets up parameters (track, sector, DMA address) in BIOS
   state slots at `$FECB-$FED4`.
2. The Z-80 raises a sync flag at `$E000` (or similar — see [Part 8](https://wiseowl.com/articles/cpm-videx-08-cooperative-cpu)).
3. The 6502 (which has been waiting in a polling loop the entire time
   the Z-80 has been running) sees the flag, performs the actual
   Apple-side disk I/O via the LC-RAM RWTS at `$BBxx-$BFxx`, places
   the result data in the DMA buffer the Z-80 specified, and raises
   an ack flag.
4. The Z-80 sees the ack, reads the data, returns from the BIOS call.

This is the "two CPUs sharing one disk" architecture. The 6502 owns
the Disk II hardware; the Z-80 issues high-level requests and waits.
The 6502's part of this loop is what the warm-boot routine at `$03C0`
in install fragments runs perpetually after the handoff.

**Detail:** [Part 8](https://wiseowl.com/articles/cpm-videx-08-cooperative-cpu)
walks the cooperative-CPU model end-to-end, including how the 6502
"resumes" after the SoftCard switched the bus to the Z-80.

---

## Honest inventory of what's not in this document

Two architectural mechanisms remain unmodeled even after the cpm-videx
investigation closed (per [Part 12](https://wiseowl.com/articles/cpm-videx-12-the-investigation-closes)).
Both affect §VI but don't change the high-level trace; they're
*implementation details* of how the BIOS gets fully populated.

**Unknown 1: who copies `$03B8` slot info to `$F3B8`?** The cold-boot
generator at Apple `$0A82` (= Z-80 `$1A82`) reads slot info from
`$F3B8-$F3BF`, but neither the 6502 boot nor any Z-80 code traced so
far writes there. The 6502 stores the slot info at `$03B9-$03BF`; the
generator expects it at `$F3B9-$F3BF`. The copy must happen via a
path none of the bytes we have describe — most likely a SoftCard-LC-
bank-aware path that the existing emulator pass doesn't model.

**Unknown 2: who loads `bios_223.bin` to `$FAB8-$FFFF`?** The BIOS
handler bodies live at `$FAB8-$FFFF` at runtime. The cold-boot
generator's `CALL $FE81 / CALL $FD83 / CALL $FDB0` targets land
there. The `bios_223.bin` file (1352 bytes) on disk has these bytes,
but no traced LOAD_CPM call targets `$FAB8`, and PREP_HANDOFF doesn't
either.

Both unknowns share a likely shape: a *separate* boot path uses the
cooperative-CPU disk model to fetch additional sectors and populate
these regions, after the SoftCard switch but before the cold-boot
generator runs in earnest. Modeling that requires bidirectional CPU
switching and LC-RAM-bank-aware writes — both deferred from the
existing emulator pass.

For the original question (why does 2.20 hang with a Videx, and what
makes 2.23 work?), neither unknown matters: the divergence is fully
explained by the §III slot-scanner branch and the §VI cold-boot
generator dispatch. The unknowns affect *how* the BIOS gets fully
populated, not *whether* the central detection-and-dispatch delta
works.

---

## What a future tool would automate

This document is the manual end-to-end. The intended deliverable is a
toolset that automates this trace for any CP/M `.dsk` (or WOZ) image:

**Stage 1: read the disk format.** Detect 6-and-2 vs 5-and-3 GCR. Find
the CP/M sector skew. Reconstruct the boot loader's disk layout. Output:
the sector → file-offset map.

**Stage 2: trace the boot loader.** Disassemble the boot stub starting
at the P6 PROM entry. Follow control flow through stage 2. Identify
the install copies and LOAD_CPM call. Output: a per-sector → memory-
address map (which sector lands at which Apple address at which point
in the boot sequence).

**Stage 3: identify the version-specific deltas.** Compare the slot
scanner against the canonical 2.20 / 2.23 / 2.x signature. Detect the
Pascal-1.1 detection branch (presence/absence). Detect any other
Microsoft-side modifications. Output: a version diff against a known-
good baseline.

**Stage 4: trace the handoff.** Locate the `JSR $0E36`-equivalent
instruction. Identify the warm-boot routine. Identify the BDOS entry
address. Output: the handoff trigger location and the planted Z-80
vectors.

**Stage 5: trace the Z-80 cold-boot.** Disassemble the BIOS cold-boot
generator. Identify the per-device dispatch table. Identify the
trap-marker pages and their runtime-populated handler bodies.
Output: a runtime BIOS layout (which addresses hold static code,
which hold runtime-generated code).

**Stage 6: produce annotated source.** Generate `.asm` files for every
identified region, with prose annotations naming the routines, cross-
referencing the trace, and documenting the data tables. Output: a
compilable, byte-identical-round-tripping source tree.

**Stage 7: round-trip verify.** Reassemble every annotated source.
Reconstruct the `.dsk` image from the assembled binaries (which means
inverting the disk-format step from Stage 1). Compare against the
original. Output: a byte-identical reconstruction (or a precise diff
showing what didn't match).

The current tooling supports Stages 1, 6, and 7 directly via
`disasm6502/`, `disasm_z80/`, the round-trip harness, and the symbol
tables. Stages 2-5 are partially automated (the recursive walker
handles control-flow tracing, the data analyzer handles structural
data) but not yet end-to-end-automated for an arbitrary CP/M disk.
Each is a clear next project.

The cpm-videx investigation produced this document and the static
analysis manually. The next investigation should be able to point a
tool at a different SoftCard CP/M disk (CP/M 2.21, CP/M 2.22, the
later Apple //e-aware versions) and have most of the trace fall out
mechanically.

---

## Status

**Trace complete from sector 0 to A>** for CP/M 2.20 and 2.23, with
two well-bounded unknowns in §VI and a clear inventory of what a
future tool would need to automate to make this trace mechanical for
arbitrary CP/M `.dsk` images. All cross-referenced sources round-trip
byte-identical. All cross-referenced articles are published.
