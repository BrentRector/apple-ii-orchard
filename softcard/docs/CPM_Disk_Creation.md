# How a SoftCard CP/M 2.23 user creates a disk

Traced from the instructions in `CPMV220-44K/utilities/`, `CPMV223-44K/utilities/` and
`CPMV223-60K/`, not from the `[AI]` headers, which were wrong in six places found during this
trace and are corrected in-tree. Written 2026-07-31.

## The headline

**Two shipped Microsoft tools write the `cp/m    sys` entry, and one of them is `COPY.COM`.**
The entry is a designed convention, not a mastering-time patch, and any user who types
`COPY B:=A:/S` produces a disk carrying it. This changes the wiseowl article's conclusion and is
detailed in section 3.

## Summary

| Question | Answer |
|---|---|
| Does a shipped 2.23 tool write the `cp/m sys` reservation? | **Yes, two.** `CPM60.COM` and `COPY.COM /S` |
| Does the formatter write `$E5` into data fields? | **Yes**, both 2.20 `FORMAT.COM` and 2.23 `COPY.COM` |
| What initialises the directory? | Nothing separately. The `$E5` format fill **is** an empty directory |
| Can a 2.23 user make a blank formatted disk? | **Yes**, format is a standalone terminal path |
| Is such a disk exposed to the `$8B` bug? | **Yes.** Without `/S` no reservation is written |
| Does `BOOT.COM` write boot tracks? | **No.** It writes nothing at all |

---

## 1. The formatter writes `$E5`, so formatting alone yields a valid empty directory

`FORMAT_TRACK` in `CPMV220-44K/utilities/FORMAT_6502.s` (run `$17DA`) fills the two 6-and-2
nibble buffers with constants before writing every sector's data field:

```
        LDA #$39            ; primary buffer fill  (256 bytes at $1B00)
        LDA #$2A            ; secondary fill        (86 bytes)
```

Those are not arbitrary. In Apple 6-and-2 the primary buffer holds `byte >> 2` and the secondary
packs three 2-bit fields, each being the byte's low two bits **with the bit order reversed**. For
`$E5`:

```
$E5 = 1110 0101   ->  primary = $E5 >> 2      = $39
                      low two = 01 reversed   = 10
                      three such fields       = %00101010 = $2A
```

Both constants match, and no neighbouring value does: `$E6` would need a secondary of `$15`. So
every data field a format writes decodes to `$E5` throughout.

**2.23 does the same.** `CPMV223-44K/utilities/COPY_6502.s` carries the identical sequence at run
`$0CE4`/`$0CEE`, with the buffers at `$1F00` instead of `$1B00`. The formatter was relocated and
rewritten, not changed in behaviour.

### The directory needs no initialisation

Track 3 is outside the boot tracks and no program writes a directory structure to it. It does not
need one. A CP/M directory slot whose first byte is `$E5` is a free slot, so a track of `$E5` is
already a valid empty directory with all 64 slots free. The format fill does the job as a side
effect of filling the whole disk.

That answers "what initialises the directory" with: **nothing does, and nothing needs to.** The
question presumes a step that CP/M's design makes unnecessary.

---

## 2. What each tool actually does

### `BOOT.COM` (2.23, 512 bytes) writes nothing

The premise that it writes boot tracks is wrong. Its only string is
`<3>=13 sector, <CR>=16 sector: $` and its whole body is:

1. seed `$77` at `$000B` (the Z-80/6502 hand-off byte);
2. `LDIR` a 269-byte 6502 read engine into Apple RAM `$5000`;
3. choose an entry address, `$C600` for 16-sector (the Disk II controller's own boot PROM in
   slot 6) or `$6000` for 13-sector;
4. store it in the SoftCard hand-off slot and `JP $000B`, giving the machine to the 6502.

It is a **re-boot utility with a density selector**, for booting 13-sector media on a 16-sector
system. It performs no writes, so the question of which OS version it lays down does not arise.

### `COPY.COM` (2.23, 3,584 bytes) is the disk-creation tool

`16 Sector Disk Copy Program (C) 1982 Microsoft`. The tail is `COPY dest=source/switches`, and
four option letters are decoded at `$0189`-`$01AF`:

| Switch | Char | Flag | Effect |
|---|---|---|---|
| `/S` | `$53` | `$0522` | system copy: write the reservation entry |
| `/D` | `$44` | `$0523` | second drive / swap handling |
| `/F` | `$46` | `$0525` | format |
| `/V` | `$56` | `$0524` | verify (read back and compare) |

The first thing COPY does, at `$0106`, is `LD C,$20 / LD E,$1F`: **set user 31**. Everything it
then does through the BDOS happens under a user number the CCP cannot reach.

**Format is a standalone terminal path.** At `$01EA` the `/F` flag is tested; if set, control goes
directly to `FORMAT_DEST_DISK` and then `JP TPA_START_46`, which prints `Operation completed` and
offers to repeat. No track copying happens on that path. So a user can format a disk without
copying one.

### `MFT.COM` (1,536 bytes) is third-party and cannot create a filesystem

`Single Drive File Transfer Program (C) 1980 by Mycroft Labs`. It prompts
`Insert SOURCE      disk` / `Insert DESTINATION disk` and copies **named files** one at a time
through a single drive. Its error set is file-level: `Not found:`, `Disk read error:`,
`Disk or directory full error:`. It writes through the BDOS into an existing directory, so it
requires a destination that already has a filesystem. It creates nothing.

---

## 3. The reservation entry is written by shipped software, in two places

This is the finding that matters, and it is stronger than "a tool writes it".

### The sequence

`CPM60_installer.asm` (the Z-80 half of `CPM60.COM`) and `COPY.asm`'s routine at `$037F` run the
**same algorithm**:

```
set user 31                    fn $20, E=$1F
delete "cp/m    sys"           fn $13            <- clears any stale entry
get the allocation bitmap      fn $1B            <- HL -> alloc vector
  test byte  HL+$10            all 8 bits clear  <- blocks 128-135 free?
  test byte  HL+$11 AND $F0    top 4 bits clear  <- blocks 136-139 free?
make "cp/m    sys"             fn $16            <- creates the directory entry
fill FCB+16 with $80..$8B                        <- claims blocks 128-139
RC = $60, EX = $00
close                          fn $10            <- commits it
```

which produces exactly the entry found on every `$8B` image: user `$1F`, `cp/m    sys`, `EX=$00`,
`RC=$60`, blocks 128-139.

### Why the free-space test settles the intent

The two bitmap tests are the decisive evidence, and they were previously annotated as a "geometry
sanity check on the DPB". They are not. Function `$1B` is `Get Addr(Alloc)`, which returns the
allocation **bitmap**; the DPB is fn `$1F`. In that bitmap the MSB of byte 0 is block 0, so:

* byte `$10` covers blocks **128-135**, and all eight must be free;
* byte `$11` masked with `$F0` covers blocks **136-139**, and those four must be free.

That is precisely the twelve blocks the code is about to claim, and nothing else. The code is
asking "is the surplus area still unclaimed?" before reserving it.

`COPY.COM` then names the answer itself: both tests branch to `ERR_SPACE_IN_USE`, which prints
**`Disk space already in use`**. A shipped error message, written by Microsoft, describing the
twelve-block region as space that can be in use. There is no reading of that as anything but a
deliberate reservation.

The hard-coded offset `$10` also shows the code was written for `DSM=139` specifically: under
`DSM=127` the allocation vector is only 16 bytes and byte `$10` is past its end.

### What this means

The entry is not a duplication-time patch applied outside the shipped software. It is written by
Microsoft's own installer **and** by Microsoft's own copy utility, with a pre-check and two
dedicated error messages behind it. Any user making a system disk with `COPY B:=A:/S` writes it.

The article's earlier reasoning pointed the other way on three grounds, and each now reads
differently:

* *"It sits at the first free directory slot, so it was written after the files."* Correct, and
  consistent: `COPY /S` creates it after the copy phase, so it lands after whatever is already
  there.
* *"The name is lowercase and contains `/`, which the BDOS can write neither."* The BDOS writes
  whatever bytes are in the FCB. It is the **CCP** that upper-cases and rejects `/` while parsing
  a command line. A program supplying its own 11-byte FCB, which is exactly what both tools do,
  bypasses that entirely. The lowercase name is a deliberate choice to make the entry
  unreachable from the command line, not evidence of an external editor.
* *"It reserves the top twelve blocks, not the bottom, so it is a patch to a symptom."* That part
  stands. It is still a workaround for a `DSM` that counts the whole medium. But it is
  Microsoft's own workaround, shipped in the tools, not someone else's cleanup afterwards.

---

## 3b. UPDATE 2026-07-31: the twelve blocks are the system tracks

Section 4 below was written before the deblock was read, and its "blocks that are addressable and
absent" framing is wrong. The 2.23 deblock
(`CPMV223-44K/os/CPM_BootLoader_DiskXlate.asm`, `SM_NOFLUSH` at `$BCDA`) folds any requested track
`>= 35` back by 35, gated on the running DPB's `DSM` byte being `$8B`:

```
block 128 -> record 1024 -> OFF + 1024/SPT = 3 + 32 = track 35 -> 0
block 139 -> record 1112 -> 3 + 34                  = track 37 -> 2
12 blocks = 12 KB = tracks 0,1,2 = 12,288 bytes exactly
```

So blocks 128-139 alias onto the reserved system tracks, and `cp/m    sys` is the entry that
names them. The `CP $8B` gate is the evidence of intent: a clamp that merely kept the head on the
medium would not need to know `DSM`.

The exposure is therefore worse, not milder, than section 4 says. On a disk with no reservation
entry the allocator hands those blocks out once 0-127 are full, and the write does **not** fail:
it silently overwrites tracks 0-2. Measured in the emulator, `SAVE 4 Z.ZZZ` on a 12 KB-free disk
reported success, committed a directory entry naming block 128, and changed 689 bytes of track 0.
Read section 4 with that substitution: "addressable and absent" should read "aliased onto the
operating system".

## 4. What this means for the `DSM = $8B` exposure

The reservation exists only on disks a tool put it on. Two populations remain exposed on a 2.23
machine:

1. **Every 2.20-lineage disk**, which never had the entry. Measured previously: twelve phantom
   kilobytes on each, and those disks ship 2-3 KB from full.
2. **Any disk formatted without `/S`.** `WRITE_SYSTEM_RESERVATION` returns immediately when the
   `/S` flag is clear, so a plain `/F` format produces a valid empty directory and **no**
   reservation. The last twelve blocks are addressable and absent.

The second is still reachable from a stock 2.23 system in one command, but it is now clearly the
*unsupported* path rather than the only path: Microsoft's answer for disks it made, and for disks
the user makes with `/S`, is the reservation entry. Data disks made with `/F` alone fall outside
that answer.

Whether the bug bites still depends on the file area filling past block 127, since
`ALLOC_GET_BLOCK` takes the first free block scanning down then up from the file's current block.

---

## 5. Open

* Whether `/S` on an already-formatted disk (no `/F`) also writes the reservation. The call graph
  says yes, since `WRITE_SYSTEM_RESERVATION` is reached from `INIT_FORMAT_DEST` as well as from
  `FORMAT_DEST_DISK`, but the flag interlocks at `$01D0`-`$0233` were not fully enumerated.
* Where the system tracks themselves come from on a `/S` copy. `CHECK_SOURCE_SYSTEM` reads track 0
  of the source through the 6502 and there is a `System not found on source disk` error, so the
  system appears to travel as raw tracks, with the `cp/m sys` entry reserving the *file-area*
  blocks rather than carrying the image. Not fully traced.
* `CAT.asm`, `PATCH.asm` and `AUTORUN.asm` were not examined.

## Annotation corrections made in this trace

All comment-level; no assembled byte changes.

`CPMV223-44K/utilities/COPY.asm`

1. `READ_SYSTEM_FILE` was headed "opens the source CPM*.SYS file ... reads the OS image into the
   copy buffer". It opens nothing, reads nothing, and there is no source file: it **creates** the
   reservation entry. Documented as `WRITE_SYSTEM_RESERVATION`.
2. `LD DE,RST2_VEC` at `$038C`. The value `$0010` is a byte offset into the allocation bitmap, not
   the RST 2 vector. A blind `cpm22.inc` rename; restored to a literal with the offset explained.
3. `FORMAT_DEST_DISK` was said to write "a fresh CP/M system image". It does not.
4. `OPEN_SYSTEM_FCB`'s header (added earlier in this session) said COPY removes the entry and the
   installer creates it. Incomplete: the delete at `$0384` is the first step of rewriting it.
5. `BUILD_RECORD_LIST` was described as building a record list for reading a file. It fills the
   FCB block map with allocation block numbers.

`CPMV223-60K/CPM60_installer.asm`

6. Function `$1B` was documented as "get DPB", the `+$10` as "geometry sanity byte 0" and the
   `AND $F0` as "geometry sanity byte 1". It is `Get Addr(Alloc)` and the two tests are a
   free-space check on blocks 128-135 and 136-139. The unused `RST2_VEC EQU $0010` was removed.
