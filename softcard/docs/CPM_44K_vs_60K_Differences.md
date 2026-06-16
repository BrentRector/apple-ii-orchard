# Microsoft SoftCard CP/M 2.23 — what actually changes between the 44K and 60K systems

The 44K and 60K systems run the **same CP/M 2.2**. They boot the same way, expose the
same BDOS calls, read the same disks, and run the same programs. The 60K conversion
exists for exactly one reason: to give transient programs **more memory** — a roughly
55 KB program area instead of 39 KB — by lifting the resident operating system up out
of main RAM and into the Apple **Language Card** (the 16 KB of bank-switched RAM at
`$D000`–`$FFFF`).

That single goal explains every difference in this document. A module differs between
the two systems **if and only if** it has to participate in living in, or getting into,
the Language Card. The command shell doesn't care where it runs, so it doesn't change.
The parts that manage memory, manage the card's banking, perform the relocation, or got
carried along by it — those are where the work is.

This is a functional narrative, not a byte diff. For the exact addresses and the
byte-level evidence behind each claim, see
[`CPM_Memory_Layout.md`](CPM_Memory_Layout.md) and
[`../CPMV223-60K/DELTA.md`](../CPMV223-60K/DELTA.md).

## At a glance

| Module | Functionally different? | In one sentence |
|---|---|---|
| **CCP** (command shell) | **No** | Identical shell, just loaded at a higher address; it only learns the machine is bigger. |
| **BDOS** | **Yes** | Same file system, but it now banks the Language Card around every call, is split across two banks, and hands console routing to the BIOS instead of doing it itself. |
| **BIOS** | **Yes** | Gains the machinery to bank in the Language Card and rebuild the resident system there on (re)boot, and reports the larger memory size. |
| **6502 boot loader** | **Yes** | Does the actual relocation: banks in the card, copies the system up into it, and arms the Z-80 to start there. |
| **6502 RWTS** (disk driver) | **Mostly no** | The same Disk II driver, just relocated into the card and patched in place; its disk behavior is unchanged. |
| **Filesystem** (tracks 3+) | **No** | Byte-for-byte identical. Only the system tracks differ. |

---

## CCP — the part that doesn't change

The Console Command Processor is the `A>` shell: it prints the prompt, parses a command
line, runs the built-ins (`DIR`, `TYPE`, `ERA`, `REN`, `SAVE`, `USER`), and otherwise
loads and runs a `.COM` file. None of that depends on where the CCP itself sits in
memory, so **the 60K CCP is the 44K CCP unchanged** — the same code, re-assembled at a
higher origin (`$9300` → `$D300`). Programmatically it is a clean relocation: every
internal reference moves with it and nothing else.

The one thing it learns is **how big the machine is**. The CCP carries a small
disk-write / sysgen routine (the same primitive `CPM60.COM` itself uses), and that
routine walks the machine's RAM pages to write the system image to the system tracks. In
the 60K build it counts up to a higher top-of-memory page (`$F0` = 60 KB) than in the 44K
build (`$A1`), because there is more RAM to account for. That memory-size figure is a
genuine configuration value, not a consequence of the new load address — it reflects the
size of memory, which is the *cause* of the relocation, not its effect. The shell's
day-to-day behavior is otherwise byte-for-byte the same.

That the CCP changes *only* in these two trivial ways is the proof that the conversion
is purely about the Language Card. Everything substantive below is in service of getting
the OS into that card and keeping it running there.

---

## BDOS — same file system, taught to live in a bank

The BDOS is the hardware-independent core: the ~40 numbered functions for console I/O,
the file system (open/close/read/write/search/rename/delete), disk selection, the DMA
address, and the user number. It is the **same CP/M 2.2 BDOS** in both systems — same
serial number, same 41-entry function dispatch, same function-range guard, and the same
file/directory/allocation algorithms. What changes is everything about *where* it lives
and *how it is reached*, plus one genuine rewrite.

**It banks the Language Card around every call.** In the 44K system the BDOS sits in
ordinary main RAM and is simply there. In the 60K system the BDOS lives inside the
Language Card, which is not visible unless the card is banked in. So the 60K BDOS opens
every system call by switching the card's RAM into view and closes every call by
switching it back out — a bank-in prologue on entry and a bank-out epilogue on exit, with
a second bank selected for the lower-numbered functions. The 44K BDOS does none of this;
it has no banking to do. This is invisible to programs (a `CALL 5` behaves identically),
but it is the structural reason the two BDOS images look so different.

**It is split across two banks.** The Language Card's addressable window is smaller than
the full BDOS, so the 60K BDOS is divided: the entry/dispatch logic and the
console-handling functions sit in the upper part of the card, while the bulk of the
file/directory/disk functions live in the card's lower bank. The 44K BDOS is one
contiguous block. The function dispatch table is the seam — its entries point into both
bands (and three of them, the system-reset/list/punch functions, point straight out to
the BIOS, in both systems). Functionally the two BDOSes execute the same routines; the
60K one just has them physically in two places.

**It stops doing its own console routing.** This is the one place the BDOS bodies
genuinely differ rather than merely move. In the 44K BDOS the console, reader, punch, and
list functions run through an in-BDOS demultiplexer: the BDOS reads the IOBYTE (the
logical-to-physical device assignment at `$0003`) and decides which physical device a
request maps to. The 60K BDOS removes that demux and calls the BIOS's console vectors
directly. In effect, **device routing moved out of the BDOS and into the BIOS / 6502
side.** The two IOBYTE functions (get/set IOBYTE) were likewise simplified to read and
write the `$0003` byte plainly. The observable behavior — typing, printing, redirection —
is the same; the responsibility for it shifted down a layer.

**Its scratch variables moved.** The BDOS's working storage (current disk, search state,
DMA address, the read/write vectors) lives at a different address in the 60K system,
consistent with the new layout. This is bookkeeping, not behavior.

What did **not** change is the part that matters most to a program: the file-system core.
Opening files, walking the directory, computing extents and record numbers, the FCB
protocol, allocation — all of it is the same CP/M 2.2 logic, in the same order.

---

## BIOS — gains the Language-Card caretaker role

The BIOS is the hardware-specific bottom layer: the 17-entry jump table (BOOT, WBOOT,
console, list, the disk primitives) that, on the SoftCard, marshals each request across
to the 6502 to do the actual Apple I/O. It lives at the same address (`$FA00`) in both
systems, but **staying put is not staying the same** — the 60K BIOS is meaningfully larger
and carries logic the 44K BIOS has no need for.

The added job is **managing the resident system inside the Language Card across reboots.**
A warm boot in CP/M reloads the CCP (and re-establishes the BDOS) so a freshly exited
program finds a clean shell. In the 44K system that is a straightforward reload into main
RAM. In the 60K system the BIOS must instead ensure the Language Card is banked in and
re-establish the CCP/BDOS *up in the card* — which is extra code that does not exist in the
44K BIOS. The 60K BIOS also reports the larger memory size (the top-of-TPA figure programs
read), so transient programs know they have the bigger area.

The two BIOSes still share their skeleton: the jump-table entry layout and the remote-call
bridge that hands disk and console work to the 6502 are the same idea in both. But the 60K
BIOS is the layer that *knows about the Language Card* and keeps the system alive in it, so
it is the more changed of the two.

---

## 6502 boot loader — the part that actually performs the relocation

Everything above describes a system that is *already* in the Language Card. The boot
loader is what puts it there. This is the most changed module, because the relocation is
its entire added purpose.

The 44K loader is the ordinary story: pull the system off the boot tracks into main RAM,
hand control to the Z-80, done. The 60K loader does that and then a great deal more. It
**banks in the Language Card's RAM**, **copies the resident system up into it** in page
blocks (the CCP and BDOS to their high homes in the card, with a low mirror placed for the
split BDOS), **patches the disk driver** for its new in-card location, and **arms the Z-80
to start in the right place** by writing a jump into the Z-80's reset vector so the
processor powers up into the BIOS. Only after all of that does it switch the machine over
to the Z-80. Concretely it runs on the order of forty-odd times as many instructions as the
44K loader and carries a few hundred bytes of code that simply do not exist in the 44K
version. If you want to point at "where the 60K conversion happens," it is here.

---

## 6502 RWTS — the same disk driver, carried along

The RWTS is the Read/Write Track Sector routine: the low-level Disk II driver that turns
"read this sector" into the head-stepping and nibble-decoding the hardware needs. Its
job is identical in both systems — the disk hardware did not change — and the 60K driver
is recognizably the same code as the 44K driver.

It differs only because it, too, got moved. In the 44K system the running copy sits at the
top of main RAM; in the 60K system it was relocated into the Language Card (so the main RAM
it used to occupy could join the program area), and the boot loader patches a handful of
its addresses in place to suit the new home. There are a few scattered, genuine byte-level
differences beyond the relocation, but no change to what the driver *does*: it reads and
writes Disk II sectors the same way. Of the modules that differ, this is the one whose
difference is closest to "it simply lives somewhere else now."

(A note for anyone reading the decompiled sources: the recovered 6502 driver was at one
point mislabeled and a copy of the BIOS image stood in its place; that has been corrected,
and the real driver is the one described here.)

---

## What does not change

It is worth stating plainly what the conversion leaves alone, because it bounds the work:

* **The filesystem.** Tracks 3 and up — the directory and all file data — are byte-for-byte
  identical between the two disks. Only the system tracks (the boot loader and the resident
  OS) differ.
* **The CCP's behavior.** The shell is the same program at a new address.
* **The BDOS file system.** The directory, FCB, extent, and allocation logic is unchanged
  CP/M 2.2.
* **The RWTS's disk behavior.** Same sectors, same encoding, same operations.
* **The CP/M interface.** Page-zero vectors, the `CALL 5` BDOS convention, the function
  numbers, the FCB and DMA layout — a program cannot tell which system it is running on
  except by the amount of memory it is handed.

The whole of the 44K → 60K difference, then, is the cost of one benefit: a bigger program
area, paid for by teaching the operating system to live in, and the boot path to set up,
the Apple Language Card.
