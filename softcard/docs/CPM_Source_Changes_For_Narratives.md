# CP/M source changes, 2026-07-30: a handoff to the write-up session

> **CORRECTION, 2026-07-31.** Part 1 section 2 originally said "do NOT cite a manual
> for this" about the DPB layout. **That instruction is withdrawn and was wrong.** The
> layout IS normatively documented, by a DRI manual that is not in the SoftCard box.
> The section below is rewritten; the DPB text it prints has also changed. If you acted
> on the old instruction, revisit it. See commit `0620d69`.

**Audience:** whoever is writing the wiseowl.com CP/M narratives. This records what
changed in the recovered CP/M sources so the articles can track it, and, just as
importantly, what must **not** be claimed about it.

**Commits:** `5dee80a`, `1f4f29d`, `1167a60` on `main`.
**Gate:** `source shared/toolchain/env.sh && python -m pytest softcard/ shared/`
= 1098 passed, 1 skipped (was 1078 + 1).

**The central claim is untouched.** Every change here is labels and comments, which
emit no bytes. All 15 OS chunk builds assemble to byte-identical output against the
baseline taken before the work, including both `CFG_56K` folds and the 60K in both
standalone and CPM60.COM-link modes. Nothing about the disk images or the
byte-identical reassembly story has changed.

---

## 1. If you have already published anything quoting these, it needs an Update note

Two things that were previously in the sources are now different, and one of them was
wrong before.

**(a) The BDOS allocation-bit comments were inverted, in both 44K trees.** In the
block allocator (`ALLOC_GET_BLOCK` / `ALLOC_SCAN_DOWN` / `ALLOC_SCAN_UP` /
`ALLOC_MARK_DONE`) the annotation said things like "carry = the tested block's in-use
bit" and "block already in use -> mark and finish", on a branch that is taken when the
block is **free**. Ten comment lines, corrected in `1f4f29d`.

The instructions settle it: the scan calls the bit test, `RRA` rotates bit 0 into
carry, then `JP NC` (taken on carry **clear**). `ALLOC_MARK_DONE` then does `RLA` /
`INC A` / write-back, and `INC A` only reliably sets bit 0 on a value whose bit 0 was
already clear. So carry clear means free, and `ALLOC_MARK_DONE` claims a free block,
which is what an allocator does.

If any published piece quoted those comments, or described the allocator as scanning
for blocks in use, it is wrong and wants a forward-pointing Update note. Devlogs stay
immutable per the house rule; an article can be revised.

**(b) The tracked `.lst` listings were regenerated.** `CPMV220-44K/os/CPM_BIOS.lst`,
`CPM_BDOS.lst` and the 2.23-44K equivalents all moved. Those files are linked from the
articles, so any line number cited from them has shifted. Addresses are unchanged;
cite labels and addresses rather than listing line numbers.

---

## 2. The Disk Parameter Block is now a labelled structure

Previously bare `DEFW`/`DEFB` with the field name only in a trailing comment. Now one
label per field, one directive per field. **This is the exact current text**, so an
article that prints the block can be matched to it verbatim:

```
DPB:
SPT:    DEFW    $0020                    ; Sectors Per Track: counts 128-byte RECORDS, not 256-byte sectors -> 32
BSH:    DEFB    $03                      ; Block SHift: log2(records per block) -> 8 records
BLM:    DEFB    $07                      ; BLock Mask: (records per block) - 1 -> 1 KB blocks
EXM:    DEFB    $00                      ; EXtent Mask
DSM:    DEFW    $007F                    ; Disk Size Max: highest allocation block number: 127 -> 128 blocks
DRM:    DEFW    $002F                    ; DiRectory Max: highest directory entry number: 47 -> 48 entries
AL0:    DEFB    $C0                      ; ALlocation bitmap, directory-reserved blocks, high byte -> 2
AL1:    DEFB    $00                      ; ditto, low byte
CKS:    DEFW    $000C                    ; ChecKSum: directory checksum bytes
OFF:    DEFW    $0003                    ; OFFset: reserved tracks before the file area
```

That is the 2.20-44K block. The 2.23-44K and 2.23-60K blocks are identical except for
`DSM`, which is `$008B` in both, and the 2.23-44K carries the anomaly comment described
in section 4.

Naming: the bare Digital Research names, unprefixed. `OFF` did not need escaping;
sjasmplus 1.23.0 accepts all ten as labels and as operands, which was tested against
the assembler before the sources were touched.

**There are three DPBs, not two.** The 60K tree has one at `$FA73`, byte-for-byte the
same fifteen bytes as the 2.23-44K twin. It was invisible to a search for "DPB" because
it was an unlabelled raw `DEFB` run inside a data blob. It is labelled now too.

### Provenance: cite DRI's Alteration Guide, not the SoftCard manuals

**This reverses what this document said on 2026-07-30.** The distinction is between the
archive and the world, and the original wording collapsed them.

The SoftCard box bundles DRI's CP/M 2.2 *Reference Manual*, which documents only BDOS
function 31, the call that *returns* a DPB pointer, and never the block's layout. That
much was right. But the layout is normatively specified by a different DRI manual, the
CP/M 2.2 *Alteration Guide* (1979), section "Disk Parameter Tables". SoftCard CP/M is
licensed DRI CP/M 2.2, so the Guide governs this block. It is registered in
`softcard/docs/CPM_Manual_Reconcile_Facts.md` as `CPMAG`, with a scan at
bitsavers (`pdf/digitalResearch/cpm/2.2/CPM_2.2_Alteration_Guide_1979.pdf`).

So: **the DPB layout is documented, and citable.** What is *not* citable to the SoftCard
manual set is a different statement, and worth keeping distinct in prose.

**One trap the Guide sets.** It defines all ten fields and **never spells the acronyms
out**. Its own shorthand is `;disk size-1` and `;directory max` in the DISKDEF listing.
"Disk Size Max", "DiRectory Max" and the rest are conventional readings, not DRI's, and
the source comments flag them `[?]` for that reason. Do not attribute an expansion to
the manual. Note also that BSH is Block SHift, not "BLock Shift" - the same word is
abbreviated B in BSH and BL in BLM, which is precisely why no expansion here is more
than convention.

### SPT counts RECORDS, not Apple sectors

The most quotable trap in the block, and it bit this repo in six places before being
corrected. `SPT = 32` does **not** mean 32 physical sectors per track. It counts
128-byte CP/M records. An Apple 5.25" track holds 16 physical sectors of 256 bytes, so
records and sectors differ by a factor of two and any prose that glosses SPT as "sectors
per track" invites an off-by-two.

DRI's own wording *is* "sectors per track", because DRI's reference format was the
8-inch IBM 3740, whose sectors were 128 bytes, where record and sector coincided. The
name is a fossil of that machine. That is a good sentence for an article and a bad
assumption for arithmetic.

## 3. The Disk Parameter Header table, and a mis-decode worth telling

The 60K DPH table was an undecoded blob. It is now four structured entries in the same
shape the two 44K trees use.

**The story here is the mis-decode.** Three of the 60K's DPH pointers rendered as code
labels:

```
DEFW BIOS_BOOT_17        ; = $FF7D
DEFW HANDLER_TBL_FETCH   ; = $FFA1
DEFW BANNER_RESTORE_A    ; = $FFB3
```

So the source read as though a Disk Parameter Header pointed at executable code. It does
not. Those are the per-drive allocation-vector buffer bases. They collide with routine
labels only because the buffers **overlay the one-shot cold-boot code**: that code runs
once at cold start, and only afterwards does the disk system reuse the same bytes as
scratch. Each of the three labels had no other referent anywhere in the file and existed
solely because that data word pointed at it.

This is a good, honest illustration of a general hazard in machine-assisted
disassembly: a disassembler that substitutes a symbol whenever a 16-bit value matches a
known address will invent a reference that the hardware never makes. Note for accuracy
if you write it up: the two tenants are never live at the same time. Do not describe
the buffers and the code as sharing memory concurrently, which is the phrasing the
house style already warns against.

### What confirmed the decode

The structure cross-validates against the DPB, which is the satisfying part:

* the CSV stride is exactly `CKS` = 12
* the ALV stride is exactly `DSM/8 + 1` = 139/8 + 1 = 18
* the regions close with no gap: `DIRBUF + 128 = ALV base`, and
  `ALV base + 4 x 18 = CSV base`

So the DPB the BIOS publishes and the buffer layout the BIOS hands out agree with each
other to the byte. Two independent structures, one arithmetic.

The buffers are now declared as a layout: one `ORG` at the overlay base, then a label
per field with its extent carried in the arithmetic to the next, plus `ASSERT`s pinning
the result to the shipped addresses. Labels emit no bytes, so the region gets named
without being written.

---

## 4. The 2.23 DSM anomaly, and the limit of what can be claimed

This is the most quotable finding in the batch, and also the easiest to overstate.

`DSM = $8B` (139) describes 140 allocation blocks. Derived from the DPB's own fields
that is 35 tracks of file area, which with `OFF = 3` implies a 38-track disk. The floppy
is 35 tracks total. The 2.20 value `$7F` (127) is exact: 32 file tracks plus 3 reserved.

What absorbs the surplus is a directory entry present on every 2.23 disk: user byte
`$1F`, the lowercase name `cp/m    sys`, and an allocation list of exactly blocks
128 to 139, the twelve blocks past the 2.20 twin's 128. The BDOS's allocation-vector
rebuild skips only `$E5` entries and does not range-check the user number, so the entry
is honoured and those twelve blocks stay permanently marked in use.

**Do not assert intent.** Whether `$8B` is a slip covered by a fake file, or a
deliberate whole-medium convention, is not determinable from any byte on these disks.
The source comment states the arithmetic and the entry and stops there, deliberately.
An article should do the same. "We cannot tell which" is the honest ending, and it is a
better one than a guess.

---

## 5. How far the annotation layer can be trusted

You cite the annotations, so here is a measured answer rather than an impression.

After fixing the allocator, two heuristic audits were run over all 54 `.asm` files under
`softcard/`: one for comments adjacent to a bit-test branch, one for routine header
blocks checked against the branches in the body they head. Both were validated by
re-running them against the pre-fix sources, where they flag exactly the lines that were
wrong and nothing else.

Result: **12 flagged sites remain, and none is a genuine inversion.** Eleven are
comments that correctly describe the loop-exit or fall-through case rather than the
branch-taken case, or vocabulary coincidences such as "free-byte count". Each was read
individually. The twelfth, `STAT.asm:208`, is unresolved: its claim that a branch is
"taken when a filename argument is present" cannot be settled without pinning the tested
byte's semantics, and it is already marked `[AI]`, which the files' own convention
defines as machine-generated and unverified.

So: one clustered defect in one routine family, not a systemic pattern. Worth knowing
that the bad comments were `[RE]`-marked, meaning hand-reviewed, rather than `[AI]`.
The markers are doing their job, and the `[AI]` ones are the ones to treat as hints.

---

## 6. The three trees are not equally finished

Relevant if you write about "the recovered sources" as a single uniform artifact. They
are not yet. The two 44K trees share one vocabulary. The 60K diverges in three measured
ways:

1. **The base page has two names for everything.** The 60K BIOS defines its own EQUs
   rather than including the shared `cpm22.inc`, and six of seven differ:
   `WBOOT_VEC` vs `WBOOTV`, `IOBYTE` vs `IOBYTE_ADDR`, `CDISK` vs `CDISK_ADDR`,
   `BDOS_VEC` vs `BDOS`, `DEFAULT_DMA` vs `TBUFF`, `TPA_START` vs `TPA`.
2. **The 60K BDOS uses raw addresses where the 44K trees use labels.** 297 raw
   `($XXXX)` operands against 30 in its 44K twin; 40 of the 55 storage labels the 44K
   BDOS defines have no counterpart. `LD HL,(MAX_BLOCK_DSM)` in the 44K is
   `LD HL,($BFD3)` in the 60K.
3. **Machine-minted routine names** such as `SELDSK_IMPL_2` where the 44K twin has
   `SELDSK_BAD_DRIVE`.

None of this is new breakage; it matches what CLAUDE.md already records about the 60K
not being at the full standard. It is now quantified. Do not describe the 60K source as
being at the same level of understanding as the 44K pair.

---

## 7. Small things worth knowing

* A guard test, `softcard/cpm_pipeline/tests/test_dpb_dph_labels.py` (20 cases), pins
  the field labels, their CP/M 2.2 order, the DPH label references and the shared
  vocabulary across all three trees. The byte gate cannot see any of this, because a
  source can regress all the way back to an opaque blob and still round-trip perfectly.
  That asymmetry is itself a decent narrative point about what byte-identity does and
  does not prove.
* `regenerate_60k_bios(write=True)` re-disassembles the 60K BIOS from its bytes and
  would silently discard the hand decode. Nothing calls it that way today, and the guard
  test above now fails loudly if it happens.
* Separate from the CP/M work, the shared 6502 core in `shared/nibbler/cpu.py` gained
  decimal mode, interrupts, real cycle counts and unstable-opcode fixes. The SoftCard
  emulator uses that core, and all its CP/M boot tests are unchanged and green, so
  nothing in the emulator narrative moves.

## 8. House rules that apply to whatever you write from this

* No em dashes, ever. No LLM tells.
* Lead with the consequence, not the detection. For section 3, the door is "a pointer
  rendered as a routine name"; the room is "a disassembler will invent a reference the
  hardware never makes, and a byte-identical gate will not notice".
* Missteps stated matter-of-fact, not as confessions.
* Devlogs are immutable: corrections go in forward-pointing Update notes. Articles may
  be restructured when a finding is structurally wrong.
* Keep the human/AI division of labour honest. For this batch: the inverted polarity was
  caught by reading the instructions against the comment, and the third DPB was found by
  searching for literals inside a known address range after a name search came up empty.

---

# Part 2, 2026-07-31: two disk images withdrawn from the archive

Separate from the source-annotation work above, and with a direct editorial consequence: the
archive's disk-image counts changed.

**Commits:** `3a7fa43`, `2333aba`. Full evidence for the first withdrawal is in
`softcard/docs/CPM_Archive_2.23B_Counterfeit.md`.

## What was withdrawn, and why

**1. `os/softcard-cpm2.23b-63k-system.dsk` was never a release.** It is
`os/softcard-cpm2.20b-56k-system.dsk` with 40 bytes edited: the copyright line, the no-card
message, the banner's memory size and version, and the machine serial at both sites where it
appears. Every string substitution is exactly as long as what it replaced, which a sector editor
forces and an assembler has no reason to produce. Verified independently before acting.

**2. `os/softcard-cpm2.20b-56k-system-workingcopy.dsk` was a pirated, user-patched disk**, not a
release: ADVEN and DUMP added, ASM and ED removed, one jump target patched. ADVEN had already
been extracted to `games/adventure-adven.com`, which was the only thing it was wanted for.

Both `MANIFEST.csv` rows are **kept** and marked `WITHDRAWN`, rather than deleted. A removed row
would read as "the archive never had this", which is weaker than "had it and rejected it".

## The counts, before and after

| | before | after |
|---|---:|---:|
| disk images in the archive | 22 | **20** |
| images under `os/` | 11 | **9** |
| `role=system` disks | 10 | **8** |
| distinct (version, config) OS cells | 6 | **5** |

The five cells are 2.20/44K, 2.20B/44K, 2.20B/56K, 2.23/44K, 2.23/60K. `languages/` (6),
`apps/` (4) and `utilities/` (1) are unchanged.

**This is the reconciliation the "twelve SoftCard disk images" figure needs.** That number appears
in 15 places in the wiseowl article and 4 in `editorial/FACTS.md`. Nothing on the repo side has
been renumbered; the two corpora were deliberately left to be reconciled in one deliberate pass
rather than drifting apart. Whatever "twelve" was counting, it is now two lower if either
withdrawn image was inside the count.

## Three claims that are now false and may be in the prose

1. **"Six configurations."** There are five. The sixth was the counterfeit's fictitious 63K.
2. **"A 2.23B that tracks the older 2.20 lineage" / "inherited rather than repaired its `$7F`
   DPB" / "a third party's derivative".** None of that happened, because nothing was rebuilt.
   The `$7F` / `$8B` DPB split between the 2.20 lineage and Microsoft's 1982 rewrite is clean,
   with **no exception**. The apparent eighth `$7F` image does not exist.
3. **Anything treating "2.23B" as a version.** There is no 2.23B. The string was typed over
   "2.20B" with a sector editor.

I grepped this repo and found no prose asserting any of these, so the corrections are for the
wiseowl corpus only.

## One argument to state carefully if you write this up

The tempting line is "40 bytes is too few to be a build". **Do not use it**, the archive refutes
it. A genuine 2.20 to 2.20B revision, same memory size, costs 42 bytes. All four scales, each
measured over the same 12,288-byte system area between images still held:

| Change | Cost |
|---|---:|
| two archived copies of one build | 4 bytes |
| minor revision, same version family and size | 42 bytes |
| memory-size change, same version (44K to 56K) | 1,301 bytes |
| version change (2.20 lineage to Microsoft's 2.23) | ~11,500 bytes |

The correct argument is about *which* change is claimed. This disk asserts a different memory
size **and** a different version. Those cost 1,301 and ~11,500 bytes in this same archive. It
exhibits 40, the budget of a revision that changes neither, every byte of it a same-length
string or the serial.

That framing is also the better story: the forger's budget is visible, and it is the budget of
someone who could not assemble anything.

## The archive is complete for this hardware

Checked against asimov's full `images/cpm/os/` listing, the apple2.org.za SoftCard mirror, and by
downloading and identifying every applicable candidate. Nothing is missing:

* `CPM_Z80SoftCard.dsk`, system tracks byte-identical to our 2.20-44K image;
* `CPM_Zs_ETC.dsk`, one byte from our 2.20B-56K image;
* `softcard.zip`, contains md5-identical copies of two images already held;
* `CPM.DSK`, `CPM_.DSK`, `CPM_Apple_CPM._B.dsk`, not SoftCard CP/M system captures (the last
  has no CP/M banner strings anywhere in the image, despite its name);
* CP/M 2.25 and 2.28B exist on asimov but run on the **Premium SoftCard IIe** and **SoftCard II**,
  different cards, out of scope here;
* `CPM3.1_Z80_Softcard.zip` (seven disks) runs on the original card but is a community port, not
  a Microsoft release, so it would belong in a different category if ever taken.

So "the archive holds every Microsoft release for the original Z-80 SoftCard that is known to
survive on asimov" is now a defensible sentence, where before today it was not checked.

---

# Part 3, 2026-07-31: how a disk gets made, and who writes the `cp/m sys` entry

Answering the eight questions in the disk-creation prompt. Commits `01477bf` and `e368a50`.
Everything below is traced from instructions, not from the `[AI]` header tier, which was wrong
in six places here. Full write-up in `docs/CPM_Disk_Creation.md`.

**Read section 1 first if you are holding the article.** It overturns the conclusion.

## 1. THE CONCLUSION CHANGES: `COPY.COM` writes the `cp/m sys` entry

The prompt's question 6 asked whether any shipped 2.23 program writes the pseudo-entry, and said
that if one does, the article is wrong. Two do.

`CPM60.COM` writes it, which was established in `01477bf`. But so does **`COPY.COM`**, in the
routine at `$037F` that had been annotated "opens the source CPM*.SYS file, validates it, and
reads the OS image into the copy buffer". It opens nothing, validates nothing and reads nothing.
Both programs run the same sequence:

```
set user 31                    fn $20, E=$1F
delete "cp/m    sys"           fn $13
get the allocation bitmap      fn $1B
  test byte  HL+$10            all 8 bits clear
  test byte  HL+$11 AND $F0    top 4 bits clear
make "cp/m    sys"             fn $16
fill FCB+16 with $80..$8B
RC = $60, EX = $00
close                          fn $10
```

producing exactly the entry on every `$8B` image: user `$1F`, `cp/m    sys`, `EX=$00`, `RC=$60`,
blocks 128-139.

So a user typing `COPY B:=A:/S` writes the entry. It is not applied by a duplication process
outside the shipped software.

### The free-space test is what settles intent, and it had been mis-annotated in both files

Both files described the two bitmap tests as a "geometry sanity check" on the DPB. They are
neither a sanity check nor on the DPB. Function `$1B` is `Get Addr(Alloc)`, which returns the
allocation **bitmap**; the DPB is fn `$1F`. In that bitmap the MSB of byte 0 is block 0, so:

* byte `$10` covers blocks **128-135**, and all eight must be free;
* byte `$11` masked `$F0` covers blocks **136-139**, and those four must be free.

Precisely the twelve blocks the code then claims, and nothing else. The code asks "is the surplus
area still unclaimed?" before reserving it.

`COPY.COM` then names the answer itself: both tests branch to a routine that prints
**`Disk space already in use`**. That is Microsoft's own shipped string, describing the
twelve-block region as space that can be occupied. There is no reading of that as accidental.

The hard-coded offset `$10` is worth a sentence in any write-up: it only makes sense for
`DSM=139`. Under `DSM=127` the allocation vector is 16 bytes and byte `$10` is off its end. The
code was written for the `$8B` geometry specifically.

### Three supporting points in the article now read differently

Two survive, one does not.

* *"It sits at the first free slot, so it was written after the files."* **Holds, and is now
  explained.** `COPY /S` creates it after the copy phase, so it lands after whatever is there.
* *"It reserves the top twelve blocks, not the bottom, and a real whole-medium convention would
  reserve the bottom and set `OFF`=0. So it is a patch to a symptom, not a design."* **Holds.**
  It is still a workaround for a `DSM` that counts the whole medium. The correction is only that
  it is Microsoft's own workaround, shipped in the tools.
* *"The name is lowercase and contains `/`. The BDOS can write neither."* **This one is wrong and
  should come out.** The BDOS writes whatever 11 bytes are in the FCB it is handed. It is the
  **CCP** that upper-cases input and rejects `/` while parsing a command line. Any program
  supplying its own FCB bypasses that, which is exactly what both tools do. The lowercase name
  with a slash is a deliberate choice to make the entry unreachable from the command line, not
  evidence of an external sector editor. Note this is the second half of the same point as the
  user-31 trick: both hide the entry from the user, by different means.

### What the defect narrative becomes

Not "Microsoft shipped a wrong `DSM` and someone patched the master disks afterwards", but:
Microsoft shipped a wrong `DSM`, noticed, and shipped a workaround **inside the tools** that
reserves the phantom blocks on every disk those tools create. The bug is still real and still
unfixed at its source, the DPB. What changes is that the mitigation is deliberate, documented by
its own error messages, and applied by the software rather than by hand at mastering.

The exposure argument is unchanged in substance and slightly narrower in framing. Still exposed:

1. **Every 2.20-lineage disk.** Never had the entry, and they ship 2-3 KB from full. The measured
   twelve phantom kilobytes per disk stand.
2. **Any disk formatted without `/S`.** The reservation routine returns immediately when the `/S`
   flag is clear, so a plain `/F` format gives a valid empty directory and no entry.

Case 2 is now clearly the *unsupported* path rather than the only path. Microsoft's answer for
disks it made, and for disks a user makes with `/S`, is the reservation. Data disks made with
`/F` alone fall outside that answer.

## 2. The formatter writes `$E5`, which you could not get from the images

This was question 8, and the prompt correctly noted it could not be settled from the archive
because every free block on every archived disk holds released file data rather than virgin fill.

It is settled from the encoder constants. `FORMAT_TRACK` in `CPMV220-44K/utilities/FORMAT_6502.s`
fills the two 6-and-2 nibble buffers before writing each data field:

```
        LDA #$39            ; primary buffer   (256 bytes)
        LDA #$2A            ; secondary buffer  (86 bytes)
```

In Apple 6-and-2 the primary holds `byte >> 2` and the secondary packs three 2-bit fields, each
being the byte's low two bits with the bit order reversed. For `$E5`:

```
$E5 = 1110 0101  ->  primary  = $E5 >> 2     = $39
                     low two  = 01 reversed  = 10
                     three such fields       = %00101010 = $2A
```

Both match, and no neighbouring value does: `$E6` would need a secondary of `$15`. Every data
field a format writes decodes to `$E5`.

**2.23 does the same.** `CPMV223-44K/utilities/COPY_6502.s` carries the identical constants at
`$0CE4`/`$0CEE`, buffers at `$1F00` rather than `$1B00`. The formatter was relocated and
rewritten, not changed in behaviour. So the 510-of-2,280 shared-window measurement in the prompt
is consistent: a rewrite that preserved the format.

## 3. Nothing initialises the directory, and nothing needs to

Question 4 asked which program initialises the directory at track 3, and said that if nothing
does, that is the finding. Nothing does, but the framing should not be "2.23 forgot to".

A CP/M directory slot whose first byte is `$E5` is a free slot. A track of `$E5` is therefore
already a valid empty directory with all 64 slots free. Since the format fills the whole medium
with `$E5`, the directory is initialised as a side effect of formatting. There is no separate
step to find because CP/M's design does not require one.

This is a nice small point for a general audience: the "empty" marker was chosen to be the value
a freshly formatted disk already has.

## 4. `BOOT.COM` writes nothing at all

Question 3 assumed `BOOT.COM` writes boot tracks and asked where the image comes from. The premise
is wrong, so the question dissolves. Its whole body is:

1. seed `$77` at `$000B`, the Z-80/6502 hand-off byte;
2. `LDIR` a 269-byte 6502 read engine into Apple RAM at `$5000`;
3. choose an entry address, `$C600` for 16-sector, which is the Disk II controller's own boot PROM
   in slot 6, or `$6000` for 13-sector;
4. store it in the hand-off slot and `JP $000B`, giving the machine to the 6502.

Its only string is `<3>=13 sector, <CR>=16 sector: $`. It is a **re-boot utility with a density
selector**, for booting 13-sector media on a 16-sector system. No writes, so no question of which
OS version it lays down.

## 5. `COPY` can format without copying

Question 5. At `$01EA` the `/F` flag is tested and, if set, control goes to `FORMAT_DEST_DISK` and
then straight to the `Operation completed` path. No track copying on that branch. A user can
produce a blank formatted disk.

The four switches, decoded at `$0189`-`$01AF`:

| Switch | Char | Flag | Effect |
|---|---|---|---|
| `/S` | `$53` | `$0522` | system copy: write the reservation entry |
| `/D` | `$44` | `$0523` | second drive / swap handling |
| `/F` | `$46` | `$0525` | format |
| `/V` | `$56` | `$0524` | verify: read back and compare |

Also worth knowing: the first thing `COPY` does, at `$0106`, is set user 31. Everything it does
through the BDOS thereafter happens under a user number the CCP cannot reach.

## 6. `MFT` cannot create a filesystem

Question 7. `Single Drive File Transfer Program (C) 1980 by Mycroft Labs`. It copies **named
files** one at a time through a single drive, prompting for disk swaps. Its errors are file-level:
`Not found:`, `Disk read error:`, `Disk or directory full error:`. It writes through the BDOS into
an existing directory. It requires a filesystem on the destination and creates nothing.

## 7. Six annotation corrections, and what they say about the tiers

All comment-level. Gate 1117 passed / 1 skipped, unchanged, so no assembled byte moved.

`CPMV223-44K/utilities/COPY.asm`

1. `READ_SYSTEM_FILE` headed "opens the source CPM*.SYS file ... reads the OS image into the copy
   buffer". Wrong in every clause: no open, no read, no source file. It **creates** the
   reservation. Now documented as `WRITE_SYSTEM_RESERVATION`.
2. `LD DE,RST2_VEC` at `$038C`. `$0010` here is a byte offset into the allocation bitmap, not the
   RST 2 vector. A blind `cpm22.inc` rename; restored to a literal with the offset explained.
3. `FORMAT_DEST_DISK` said to write "a fresh CP/M system image". It does not.
4. `OPEN_SYSTEM_FCB`'s header, which I added earlier the same day in `01477bf`, said COPY removes
   the entry and the installer creates it. Incomplete: the delete at `$0384` is the first step of
   rewriting it. My own correction needed correcting.
5. `BUILD_RECORD_LIST` described as building a record list for reading a file. It fills the FCB
   block map with allocation block numbers.

`CPMV223-60K/CPM60_installer.asm`

6. Fn `$1B` documented as "get DPB", the `+$10` as "geometry sanity byte 0", the `AND $F0` as
   "geometry sanity byte 1". All three wrong, as above. The unused `RST2_VEC EQU $0010` removed.

### The tier lesson, which is now a pattern worth stating in prose

Part 1 section 5 already told you the `[AI]` tier is the least trustworthy. This round sharpens it
in two ways.

First, **the errors were not random noise, they were plausible-sounding fiction.** "Reads the OS
image into the copy buffer" is what a routine called from a copy program near a system FCB
*ought* to do. The annotation described the expected program, not the actual one. That is the
failure mode to describe: not gibberish, but confident narrative that fits the context and
contradicts the instructions.

Second, **a correction is not automatically better than what it replaced.** Item 4 above is mine,
made hours earlier, and it was half right in a way that pointed away from the real finding. If you
write about the annotation layer, this is the honest shape of it: the `[AI]` tier was wrong, the
hand-review tier caught it partially, and the thing that finally settled it was neither, but a
shipped error message.

### What actually settled it

Worth saying plainly because it is a good methodological beat. The decisive evidence was not a
disassembly insight. It was that `COPY.COM` routes its free-space failure to a string reading
`Disk space already in use`. The program documents its own intent, in a message Microsoft wrote
for users in 1982, sitting in the binary the whole time. Cross-validating the two tools against
each other is what made it visible: the installer alone was ambiguous, and the copier's error
message disambiguated it.

## 8. Two things left open

State these as open if you write from this; do not round them off.

* **Whether `/S` without `/F` also writes the entry.** The call graph says yes, since the
  reservation routine is reached from `INIT_FORMAT_DEST` as well as from `FORMAT_DEST_DISK`, but I
  did not enumerate the flag interlocks at `$01D0`-`$0233` and am not asserting it.
* **Where the system tracks come from on a `/S` copy.** `CHECK_SOURCE_SYSTEM` reads track 0 of the
  source through the 6502, and there is a `System not found on source disk` error, so the system
  appears to travel as raw tracks with the `cp/m sys` entry reserving *file-area* blocks rather
  than carrying the image. Not fully traced.

`CAT.asm`, `PATCH.asm` and `AUTORUN.asm` were not examined.

## 9. Corrections to the prompt itself

Two premises in the disk-creation prompt were wrong, both flagged above and repeated here so they
do not survive into prose:

* "`BOOT.COM` is 512 bytes and writes boot tracks." It writes nothing.
* "The name is lowercase and contains `/`. The BDOS can write neither." The BDOS writes whatever
  is in the FCB; it is the CCP that cannot.

Everything else in the prompt held up, including the `DSM` arithmetic, the Alteration Guide
provenance, the count-not-placement point, the block 128-to-track-35 mapping, and the measured
free-space table.
