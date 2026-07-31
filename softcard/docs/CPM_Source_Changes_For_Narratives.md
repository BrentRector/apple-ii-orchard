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

---

# Part 4, 2026-07-31: the failure run in the emulator, and a decode gap it exposed

Gate is **1121 passed / 1 skipped**, not the 1117 in your brief. I added four tests for the new
audit 4 after Part 3 was written. All changes here are comment-level; no assembled byte moved.

Item 1 produced a real result and also produced a boundary I cannot cross. Item 2 is answered.
Item 3 was not run, and why is at the end.

## 1. The emulator run

### 1a. First, the thing you told me to establish before trusting anything

**The default disk path is not a hardware model, and I did not run the experiment on it alone.**
`softcard_emu/machine.py:378` is literally `if track >= 35: return ret(carry=1, err=0x40)`. That
is a policy line, not emergent behaviour. Reporting its output as hardware would have been
reporting my own Python.

There is a second path. `Machine(sector_hook=False)` runs the preserved RWTS against synthetic
nibble streams from `shared/nibbler/dsk_disk.py`. That model *is* structurally faithful at this
limit: it builds nibble tracks for `range(35)` only, `step_phase` lets the head travel to qtrack
159 (track 39), and at any head position with no built track `read_nibble()` returns `$FF`
forever and never yields a `D5 AA 96` address prolog. The failure emerges from absent data rather
than from an assertion. **But `DSKDisk` has no write path at all** -- `read_nibble` and
`step_phase` only, with `q7` as a dead state mirror.

So the faithful layer cannot write and the writable layer asserts the limit. Which matters less
than it sounds, for the reason in 1c.

### 1b. What the run shows, and this part is solid

Setup: a booting 2.23 system (`DSM`=139 lives in its BIOS) whose disk directory carries no
reservation, reached by marking the `cp/m sys` entry deleted on the 2.23 system disk. That disk
is otherwise exactly full, so **every** free block afterwards is a phantom one and the first
allocation is the interesting one. Sharper than filling 2 KB on a 2.20 disk and tests the same
mechanism.

```
free blocks after deleting the entry: [128 ... 139]   12 KB, all phantom

A>STAT
A: R/W, Space: 12k

A>SAVE 4 Z.ZZZ
A>                          <- no error, no message

directory afterwards:
  slot 8  user=$00 'Z       ZZZ'  EX=0  RC=$08  blocks=[128]
```

So:

* **`STAT` offers space that does not exist.** 12k here; your predicted 14 KB for
  `softcard-cpm2.20-44k-system.dsk` is separately confirmed, see 1e.
* **The allocator really does hand out block 128**, on the very first allocation.
* **`SAVE` reports success.** The CCP returns to `A>` with no error.
* **The directory entry is committed** naming a block that cannot exist.
* **The file does not read back.** `TYPE Z.ZZZ` prints garbage.

That is the article's answer for the allocation half, and none of it depends on the disk model:
it is Z-80 BDOS logic over the DPB and the allocation vector, decided in RAM.

### 1c. CP/M computed track 35 correctly. Something below the BIOS turned it into track 0

This is the part worth your attention, and the part I cannot certify.

Reading CP/M's own `sektrk` cell (a byte at Z-80 `$FED1`) at each sector request during the
`SAVE`, against the IOB track (`$03E0`) that actually reached RWTS:

```
 iob_trk  sec  kind    CP/M sektrk
     3     0   read        3
     3    12   WRITE      35        <- directory
     0     0   WRITE      35        <- CP/M asked for 35, the drive was told 0
     0     9   WRITE      35
     0     3   WRITE      35
     0    12   WRITE      35
```

CP/M's arithmetic is right: block 128 is record 1024, `OFF` + 1024/`SPT` = 3 + 32 = **35**. The
BDOS and BIOS both do the correct thing. But the value that reached the sector primitive was
**0**, and track 0 is a boot track. Comparing the image before and after: **689 bytes of track 0
changed.** The damage is not confined to the growing file and does not touch a neighbouring file
either; it lands on the boot sectors.

Note what this means for 1a: the hook's `if track >= 35` **was never reached**, because the track
was already 0 by the time it saw it. The truncation happened upstream, in emulated code running
real bytes.

**Why I still will not put this in the article as hardware behaviour.** The truncation happens
inside code this repo has never decoded, see section 3. I can see 35 go in and 0 come out; I
cannot yet show you the instruction that does it, so I cannot rule out that the emulator's RPC
bridge is responsible rather than Microsoft's deblock. Until that 2 KB is decoded, "writing into
a phantom block scribbles on track 0" is a **lead**, not a finding.

### 1d. What the failure would be on real hardware, from the shipped RWTS

This does not need the emulator at all, and it is better evidence. `CPMV223-44K/os/CPM_BootLoader.s`
contains the real RWTS. Reading `RWTS_MAIN` around `$0EC0`-`$0F0B`:

* `LDY #$30` seeds an inner retry counter of **48**, the classic DOS 3.3 figure;
* each pass calls `$BB03` to find the address field, and `RWTS_MAIN_RETRY` loops on failure;
* when the 48 are gone it recalibrates and decrements an outer counter;
* when that is gone, `RWTS_MAIN_21` does `LDA #$40` and returns with carry set.

`$40` is "drive error" in *Beneath Apple DOS*'s RWTS return codes, so the emulator's chosen error
code happens to be the right one. And the decisive structural point:

> **the write is gated behind a successful address-field match.** `RWTS_MAIN_23` only reaches
> `BCC RWTS_MAIN_WRITE` after the address field has matched the requested track and sector.

Nothing ever writes address fields to track 35, because formatting stops at 34. So on real
hardware the write **cannot happen at all**: RWTS burns 48 retries, recalibrates, retries, and
returns `$40`. No partial write, no torn sector, no corruption of a neighbour. The file's data is
simply never written, and whatever CP/M does next it does having been told the drive failed.

Web research supports the physical half: the Disk II stepper has 4x the resolution of the track
pitch and most drives will reach track 35 or 36, which is why some protected titles used a 36th
track. So the head gets there. It just finds nothing.

### 1e. Your 14 KB figure is confirmed

Rebuilding the allocation vector from each disk's real directory, under both `DSM` values, using
the correct **48**-entry directory (see section 3 for why 48 and not 64):

| disk | free @ `DSM`=127 | free @ `DSM`=139 |
|---|---:|---:|
| `softcard-cpm2.20-44k-system.dsk` | 2 KB | **14 KB** |
| `softcard-cpm2.20-44k-system-1980.dsk` | 3 KB | 15 KB |
| `softcard-cpm2.20b-44k-system.dsk` | 3 KB | 15 KB |
| `softcard-cpm2.20b-56k-system.dsk` | 3 KB | 15 KB |
| `softcard-cpm2.23-44k-system.dsk` | 0 KB | 0 KB |

The article's 14 KB stands. Nothing here contradicts the exposure argument; the run strengthens
it by demonstrating the allocation rather than deriving it.

## 2. Not started: the `ALLOC_VECTOR_BUILD` special-entry path

I did not get to item 2. Everything you narrowed still stands unexamined by me, and I am not
going to summarise your own hypothesis back to you as though it were a result. It remains open,
with your three settling questions intact. Your note that `BDOS_STACK_TOP` may itself be a
mis-annotation is the thread I would pull first, especially given that this session has now found
mis-annotations in that same tier six more times.

## 3. THE THING YOU SHOULD KNOW: a 2 KB hole in the decode

While chasing 1c I went looking for the deblock code, and it is not in this repo.

`CPM_BIOS.asm` says `READ -> JP $AC39` and `WRITE -> JP $AC49`, described as "off-image". That is
accurate but undersells it. From the build's own chunk map for 2.23:

| module | ORG | size | covers |
|---|---|---|---|
| `CPM223_44K_CCP` | `$9300` | 2304 | `$9300-$9BFF` |
| `CPM223_44K_BDOS` | `$9C00` | 3584 | `$9C00-$A9FF` |
| `CPM223_BIOS_Disk` | `$FA00` | 1536 | `$FA00-$FFFF` |

**Z-80 `$AA00-$B1FF` is built from no source at all.** That is 2048 bytes, and it matches exactly
the 8 sectors of track 2 (physical 1, 3, 5, 7, 9, 11, 13, 15) that appear in no `ChunkSpec`. The
`build` verb starts from the reference image and overwrites only the sectors it has sources for,
so those 2 KB are **carried through verbatim**. Byte-identity is therefore trivially preserved
for them and the gate has never been able to see the gap. This is the same blind spot as the
skew problem, in a new place: the gate proves *reproduction*, not *understanding*.

The region is real code. Disassembled from live memory (Z-80 `$ACxx` is Apple `$BCxx`, since the
SoftCard maps Z-80 X to Apple X+`$1000` outside the `$F000` window):

```
AC49  61        LD H,C            ; BIOS WRITE lands here
AC4A  2e 00     LD L,$00
AC4C  22 da fe  LD ($FEDA),HL
AC4F  79        LD A,C
AC50  fe 02     CP $02            ; write type 2 = directory write
AC52  20 0f     JR NZ,$AC63
AC54  2e 08     LD L,$08
AC56  3a d6 fe  LD A,($FED6)      ; sekdsk
...
AC72  3a d1 fe  LD A,($FED1)      ; sektrk
AC75  2a df fe  LD HL,($FEDF)
```

That is the CP/M deblocking layer, the thing that turns 128-byte records into 256-byte host
sectors, and it is exactly where a 35-to-0 truncation would live. It is also, as far as the repo
is concerned, an undecoded blob.

**So the honest answer to "shouldn't we have all the code by now" is no.** The 2.23-44K decode is
missing its disk deblock. I would treat this as the next real work item, ahead of item 2: it is
2 KB, it is the last unexplained code in the 44K boot-to-prompt path, and it currently blocks a
finding the article would want.

## 4. Item 3 not run

Time went into item 1 and then into section 3, which I judged worth more to you than a
time-boxed survey of other vendors' disks. It remains unanswered: whether reserving phantom
blocks with a hidden entry is a Microsoft practice or a general CP/M idiom. Nothing was
downloaded and `MANIFEST.csv` is untouched.

## 5. Source corrections in this pass

Both comment-level, gate re-run green, listings regenerated.

1. **`docs/CPM_Filesystem.md` said 64 directory entries.** `DRM` is `$2F`, so there are **48**.
   The two reserved blocks have room for 64 and only 48 are used; `CKS`=12 = 48/4 confirms it.
   My own free-space numbers were computed both ways and agree, so no figure moves.
2. **Both 2.23 BIOS files said the `$8B` question was "NOT determinable from any byte on these
   disks."** Part 3 determined it. Replaced in `CPMV223-44K/os/CPM_BIOS.asm` and
   `CPMV223-60K/os/CPM_BIOS.asm` with the resolved statement: `$8B` is an error, and the entry is
   Microsoft's shipped workaround, written by two shipped tools.

---

# Part 5, 2026-07-31: the fold. Blocks 128-139 ARE the system tracks

**Read this before using Part 4.** Part 4 got its headline wrong, and the correct answer is a
much better story. Gate 1121 passed / 1 skipped, byte-identical.

## 0. Correcting Part 4

Part 4 said the 2.23-44K decode had "a 2 KB hole" containing the disk deblock, and recommended
decoding it as the next work item. **That was wrong.** The code was already decoded, in
`CPMV223-44K/os/CPM_BootLoader_DiskXlate.asm`, a Z-80 source ORG'd at its `$BC39` run address and
INCBIN'd into the 6502 boot loader, reassembling byte-identical. The repo had done exactly what
its own rule requires for embedded other-CPU code, and I did not find it before writing Part 4.

Two things led me wrong and both are worth knowing:

* I identified 8 track-2 sectors that appear in no `ChunkSpec` and assumed they were the missing
  code. Tracing the boot loads shows those sectors **are never read at all**. The boot reads 29
  sectors into a contiguous staging area and copies them out; the 8 odd sectors are unused disk
  space.
* I searched the raw disk for the deblock signature and mapped the file offset back to a
  track/sector without applying the interleave, which pointed at the wrong chunk.

So: **no decode gap.** The whole 44K boot-to-prompt path is accounted for. Please drop that item.

## 1. What the code actually does, and it changes the article

`SM_NOFLUSH` in `CPM_BootLoader_DiskXlate.asm`, at `$BCDA`:

```asm
        LD A,(REQ_TRACK)     ; requested track
        CP $23               ; 35 = past the last track of a 35-track medium
        JR C,SM_SETSEC       ; normal track, use as-is
        LD L,A
        LD A,(DPB_DSM)       ; the running DPB's DSM byte
        CP $8B               ; ONLY the 140-block geometry
        JR NZ,SM_STORE
        LD A,L
        SUB $23              ; fold onto tracks 0-2
```

Requested track 35 or beyond, **and** the running `DSM` is `$8B`, subtract 35.

The arithmetic lands exactly:

```
block 128 -> record 1024 -> OFF + 1024/SPT = 3 + 32 = track 35 -> 0
block 139 -> record 1112 -> 3 + 34                  = track 37 -> 2
blocks 128..139 = 12 blocks = 12 KB = tracks 0,1,2 = 12,288 bytes
```

**The twelve surplus blocks are not phantom space. They are the three reserved system tracks,
made addressable through the ordinary file system.** That is what the `cp/m    sys` entry names,
and it is why it is called that. Twelve blocks, twelve kilobytes, three tracks, no remainder.

Confirmed at runtime, not just read: instrumenting the requested track and the DSM cell during a
`SAVE` into block 128 shows `$FED1`=35, `$FEE3`=`$8B`, and the IOB track arriving at RWTS as 0.

### This is deliberate, and the gate is the proof

The test is `CP $8B` against the DPB's own `DSM`. A defensive clamp to keep the head on the medium
would not need to know `DSM`; it would clamp regardless. Checking for exactly the value that has
the twelve extra blocks means the author knew those blocks existed and knew where they should
point. The fold appears in no other tree: 2.20's deblock (with `DSM`=`$7F`) has nothing like it.

That said, separate what is proven from what is inferred:

* **Proven:** the fold exists, is gated on `DSM`=`$8B`, aliases blocks 128-139 onto tracks 0-2,
  and the `cp/m sys` entry claims exactly those blocks. Two shipped tools create that entry.
* **Inferred:** that the *purpose* is to expose the system area as a file. It is the only reading
  that explains the gate, the exact arithmetic, and the file's name together, but no byte says so.

## 2. What this does to the defect narrative

The article's framing needs revising in two directions at once. It gets **less** wrong-looking as
an arithmetic blunder and **much worse** as a consequence.

**`DSM`=`$8B` is not simply a miscount.** The Alteration Guide's two readings still explain how
139 could be arrived at, but 139 is also exactly the value that makes the system tracks
addressable, and the deblock is written to support precisely that value. Presenting it purely as
"Microsoft misread their own manual" is no longer supportable.

**The failure is far worse than phantom space.** Everything I wrote in Part 4's section 1d about
RWTS returning `$40` after 48 retries is *irrelevant to this path*: the drive is never asked for
track 35. It is asked for track 0. So:

* there is no drive error;
* there is no failed write;
* the write **succeeds**, onto the boot tracks.

Measured: `SAVE 4 Z.ZZZ` on a 12 KB-free disk reported success, committed a directory entry naming
block 128, and **changed 689 bytes of track 0**. The file did not read back, because reading it
returns boot-track bytes rather than what was written to the buffer.

So the exposure is not "twelve kilobytes that do not exist". It is:

> On a 2.23 system, any disk lacking the `cp/m sys` entry will, once blocks 0-127 are full,
> silently overwrite its own operating system.

Every 2.20-lineage disk qualifies, and they ship 2-3 KB from full. So does any disk a user
formats with `COPY /F` instead of `/S`. The reservation entry is not bookkeeping; it is the only
thing standing between a nearly-full 2.20 disk and destruction of its boot tracks under 2.23.

## 3. Re-evaluating every question posed across these briefs

| # | Question | Answer now |
|---|---|---|
| Q1 | Fresh bootable disk, step by step | `COPY dest=source/S` (add `/F` to format first). Partly open: `/S` without `/F` not traced |
| Q2 | Data-only disk | `COPY d:/F`. Formats, `$E5` fill, valid empty directory, **no** reservation |
| Q3 | `BOOT.COM` writes boot tracks | **No.** Writes nothing; density-selecting re-boot utility |
| Q4 | What initialises the directory | Nothing does. The `$E5` format fill IS an empty directory |
| Q5 | `COPY` format-only? | **Yes**, standalone terminal path. Such a disk IS exposed |
| Q6 | Does a shipped tool write the entry | **Yes, two.** `CPM60.COM` and `COPY.COM /S` |
| Q7 | What `MFT` does | Third-party file copier; needs an existing filesystem, creates nothing |
| Q8 | Does FORMAT write `$E5` | **Yes**, both 2.20's `FORMAT.COM` and 2.23's formatter inside `COPY.COM` |
| item 1 | Run the failure | **Done.** Allocator hands out block 128; STAT offers 12k; SAVE succeeds silently; entry committed; 689 bytes of track 0 overwritten; file unreadable |
| item 2 | `ALLOC_VECTOR_BUILD` `[?]` branch | **Still not started.** Unchanged from Part 4 |
| item 3 | Other vendors' disks | **Not run.** Unchanged |

Three earlier answers now need qualifying in light of the fold:

* **The `$7F` vs `$8B` "count error" framing.** `$8B` is the value the deblock is built around.
  Call it a design with a fatal interaction, not a miscount.
* **"The twelve blocks map to tracks 35-37, which do not exist."** True of the arithmetic before
  the fold, and misleading after it. They resolve to tracks 0-2, which very much exist.
* **Part 4's "no partial write, no torn sector, no neighbouring-file damage."** Correct about what
  a drive does at track 35, and beside the point: the write never goes there.

The 14 KB figure, the `$E5` proof, the two-tools finding, the free-space table and the
`BOOT.COM`/`MFT` answers are all unaffected.

## 4. Source corrections in this pass

`CPM_BootLoader_DiskXlate.asm` had four labels wrong, and they are exactly why this region read as
meaningless. Verified against the shipped RWTS and at runtime. All byte-neutral; the tracked
`.lst` and the INCBIN listing comment in the host file were regenerated.

| was | is | evidence |
|---|---|---|
| `IOB_SECTOR EQU $F3E0` | `IOB_TRACK` | `$03E0` is the track; RWTS_MAIN reads `$03E0`/`$03E1` as track/sector |
| `IOB_TRACK EQU $F3E4` | `IOB_DRIVE` | `$03E4` is drive select, observed 1 |
| `SCR_D1` "requested sector (low)" | `REQ_TRACK` | observed 3 for the directory, 35 for block 128 |
| `SCR_D2` "requested track" | `REQ_RECORD` | observed 0,2,4,6 stepping within a track |
| `SCR_E3` "deblock flag scratch" | `DPB_DSM` | the fold tests it against `$8B` |

`REQ_TRACK` and `REQ_RECORD` were transposed, and with `DPB_DSM` called a "flag", the fold looked
like arbitrary arithmetic on a sector number. Named correctly, it reads as what it is.

The fold itself now carries a header block at the site explaining the aliasing, the exact
arithmetic, and the consequence.

---

# Part 6, 2026-07-31: item 2 resolved. The `[?]` branch is DRI's `$$$.SUB` probe

Your hypothesis was right, and the reason it looked unresolvable was the label. Gate 1121 passed
/ 1 skipped, byte-identical.

## The answer

The branch sets the BDOS return value to `$FF` when **the current user** has a file whose name
begins with `$`. That is Digital Research's documented CP/M 2.2 behaviour for **function 13,
Reset Disk System**, which "logs in drive A: and returns 0FFh if there is a file present whose
name begins with a $, otherwise 0". The CCP reads it to notice `$$$.SUB` and resume a SUBMIT
batch after a warm boot.

So, to your three settling questions:

* **What writes `$9F41`?** `F_USERNUM_H` (fn 32, Get/Set User Code). It is the **current user
  number** cell. Your suspicion about the label was exactly right.
* **Who reads `$9F45`?** The dispatcher, on the way out. `BDOS_RETVAL` is the ordinary BDOS
  return cell, so the `$FF` simply becomes function 13's `A` result.
* **Is it DRI's or a SoftCard addition?** **DRI's.** The 2.20 and 2.23 BDOSes carry it
  identically, and it matches the published function-13 semantics.

It is one clause in the article, as you predicted: *the login scan also notices whether the
current user has a `$`-prefixed file, which is how `SUBMIT` batches survive a warm boot.*

## Why it read as unknown: the label was wrong

`BDOS_STACK_TOP` is a **dual-use cell**, and this is DRI saving a byte rather than an accident:

```
BDOS_DISPATCH:  LD SP,BDOS_USER_NUM     ; SP = $9F41
```

The Z-80 decrements `SP` **before** writing, so the first push lands at `$9F40` and the stack
grows down from there. **The byte at `$9F41` is never touched by the stack.** DRI put the user
number in it. Elsewhere in the same file the repo already knew this, and said so plainly at
`FCB_MERGE_USER` ("OR the current user number into the FCB's drive byte") and at `F_USERNUM_H`.
Only the cell's own definition, and the one place that mattered, carried the stack-only name.

With the cell named for its stack role, `LD A,(BDOS_STACK_TOP) / CP (HL)` reads as "compare a
directory entry against a stack byte", which is meaningless, so it got a `[?]`. Renamed to
`BDOS_USER_NUM` it reads as what it is:

```asm
        LD A,(BDOS_USER_NUM)   ; current user number
        CP (HL)                ; this entry's user byte?
        JP NZ,ALLOC_VECTOR_SCAN_MARK
        INC HL
        LD A,(HL)              ; first name character
        SUB $24                ; '$'?  (A = 0 when it is)
        JP NZ,ALLOC_VECTOR_SCAN_MARK
        DEC A                  ; 0 -> $FF
        LD (BDOS_RETVAL),A     ; fn 13's result
```

**Your Part-2 observation stands unchanged and is worth keeping in the article:** both tests jump
to `MARK`, and the fall-through reaches `MARK` too, so every non-`$E5` entry has its blocks
marked regardless. The probe only sets a flag. "`$E5` and for no other reason" is safe.

## Changes

Comment- and label-level in all three BDOS files; `.lst` regenerated; no assembled byte moved.

* `BDOS_STACK_TOP` renamed **`BDOS_USER_NUM`** across `CPMV220-44K`, `CPMV223-44K` and
  `CPMV223-60K` (16, 17 and 15 references). Its definition now documents the dual tenancy and
  why the stack cannot disturb it.
* The `[?] ... exact intent is UNKNOWN` headers in all three replaced with the resolved
  explanation and the DRI provenance.
* The "special-entry check" wording, which was doing no work, replaced with "the `$` SUBMIT
  probe" throughout.

Worth noting for the annotation-tier theme: the 60K file's header already said the test was
"against the current user" while the two 44K files called it "the BDOS default-FCB byte". A
cross-tree contradiction of exactly the kind audit 3 exists to catch, which it missed because
the two descriptions never shared a label name.

## Running tally of the three follow-up items

| item | state |
|---|---|
| 1. Run the failure in the emulator | **Done**, and it produced the `$8B` fold (Part 5) |
| 2. `ALLOC_VECTOR_BUILD` `[?]` branch | **Done**, this part |
| 3. Third-party CP/M disks | **Not run.** Still the only open item |

---

# Part 7, 2026-07-31: full report. All three items closed

Commits `01477bf` `e368a50` `65a9000` `359104a` `25f94e3` `fbd578c` `83cd467`. Gate **1121 passed
/ 1 skipped** throughout, byte-identical at every step. Your verification of `25f94e3` is
incorporated; where we disagreed I say so and give the evidence.

**The three open items are all closed.** Item 1 (run the failure) produced the fold. Item 2
(the `[?]` branch) is DRI's `$$$.SUB` probe. Item 3 (third-party) is answered from two
independent sources.

---

## PART A. The finding, in the order the evidence forced it

### A1. What `DSM = $8B` actually is

Not a miscount. The 2.23 deblock, `SM_NOFLUSH` at `$BCDA` in
`CPMV223-44K/os/CPM_BootLoader_DiskXlate.asm`:

```asm
        LD A,(REQ_TRACK)     ; requested track
        CP $23               ; 35 = past the last track of a 35-track medium
        JR C,SM_SETSEC       ; normal track, use as-is
        LD L,A
        LD A,(DPB_DSM)       ; the running DPB's DSM byte
        CP $8B               ; ONLY the 140-block geometry
        JR NZ,SM_STORE
        LD A,L
        SUB $23              ; fold onto tracks 0-2
```

```
block 128 -> record 1024 -> OFF + 1024/SPT = 3 + 32 = track 35 -> 0
block 139 -> record 1112 -> 3 + 34                  =       37 -> 2
blocks 128..139 = 12 blocks = 12 KB = tracks 0,1,2 = 12,288 bytes, no remainder
```

The twelve blocks past the 2.20 twin's `$7F` are the three reserved system tracks, reachable
through the ordinary file system. `cp/m    sys` (user `$1F`, block map exactly 128-139) is the
entry that accounts for them.

The gate is the evidence of intent: a clamp that merely kept the head on the medium would not
need to know `DSM`. No other tree has the fold.

### A2. Independent corroboration, found after the fact

Two secondary sources describe this as a deliberate feature. Both are `[?]` tier, and both agree
with the instructions and with each other.

**Apple II SoftCard CP/M Reference** (community, apple2.guidero.us):

> "SoftCard CP/M ver 2.23 and higher uses a trick to allow the system tracks for data storage: a
> file called cp/m.sys is created in user area 31 as a dummy file allocated to the system tracks.
> It is inaccessible from the CCP and unseen by the user."
>
> "COPY.COM has an option to create a 'data diskette' where cp/m.sys is absent, which creates 3
> more tracks for data storage."

**CiderPress2 CP/M format notes**: same entry, user 31, lower-case name, blocks `$80`-`$8B`
"treated as wrapping around to the start of the disk", and "This trick, which appears to have
originated with the Microsoft SoftCard, is used to allow extra storage on non-bootable disks."

That answers item 3: **a Microsoft SoftCard origination, not a general CP/M idiom.**

One caution. The same reference's DPB table prints `DSM`=127 for both versions, which the shipped
BIOS bytes contradict (`$7F` on 2.20, `$8B` on 2.23, verified across 8 archived images). Our bytes
win, and the reference is internally inconsistent: its own "allocated to the system tracks" claim
needs `DSM`>127 to be expressible at all. Do not cite its table.

### A3. THE HAZARD, and it is the story

Neither source mentions it, and it follows directly from what they do say.

**The `cp/m sys` entry is the only thing that distinguishes "this disk's boot tracks are in use"
from "this disk's boot tracks are free storage."** There is no other marker. A data diskette is
simply a disk with no entry.

A 2.20-lineage disk has a boot image on tracks 0-2 and no entry, because under its own `DSM`=`$7F`
those blocks were not expressible and no entry was needed. Mounted on a 2.23 system it is
therefore **indistinguishable from a data diskette**, and 2.23 will allocate its boot tracks to
the next file that needs the space.

Every 2.20 disk in existence is in that state. They ship 2-3 KB from full, so it is one file away.

**Correction to my own earlier claim, and to your point 4:** a `COPY /F` data disk is **not** at
risk. It has no boot image, so writing into those blocks is the documented intended use. The
hazard is specific to a disk that carries a boot image and no entry.

### A4. Reservation or conduit: you were right, and "describable" is still too weak

You are right that **no shipped tool moves data through those blocks.** Verified independently:

* `CPM60.COM`'s entire BDOS function set is `{$06,$09,$0E,$10,$13,$16,$19,$1B,$20}`. No `$14`,
  `$15`, `$21` or `$22`. It never reads or writes through the FCB.
* `COPY.COM` touches that FCB only with `DRV_SET`, `F_DELETE`, `F_MAKE`, `F_CLOSE`.

But "describable" understates it, for two reasons.

**The reservation does not need the fold.** `ALLOC_FROM_FCB` reads a block number, range-checks it
against `DSM`, and calls `ALLOC_BIT_WRITE`. It is a pure bitmap operation and never converts a
block to a track. The reservation would work identically with no fold at all. The fold is reached
**only** from the deblock, on real record I/O.

**And that I/O works.** Round-trip verified: I placed a known 256-byte pattern in the TPA at
`$0100`, ran `SAVE 1 P.PPP` on a disk whose only free blocks were 128-139, and the pattern arrived
**byte-for-byte at track 0 sector 0**.

So the twelve blocks are genuine, working storage that no Microsoft tool uses. The beneficiary is
ordinary user files on a disk with no boot image, which is exactly the use both references
describe. The entry exists to withhold that storage when there *is* a boot image.

---

## PART B. Item 2: the `[?]` branch, and what the `$` filename business is

You said you did not follow this. Here it is from the top, because the mechanism is genuinely
non-obvious and the payoff is one clause in the article.

### B1. What `$$$.SUB` is, and why it has to be a file

CP/M has a batch facility called **SUBMIT**. You put command lines in a file, say `JOB.SUB`, and
type `SUBMIT JOB`. The commands then run one after another without you typing them.

The awkward part is that CP/M has nowhere to keep the queue. Every program that runs owns the
whole TPA, and when it finishes the CCP is **reloaded from disk** (a warm boot). Nothing in memory
survives. So a list of pending commands cannot live in RAM between commands.

DRI's answer: keep the queue **in a file**. `SUBMIT` reads your `JOB.SUB` and writes the pending
command lines into a file literally named `$$$.SUB` on drive A. After each command finishes, the
freshly reloaded CCP looks for `$$$.SUB`; if it is there, it takes the next line from it and
executes that instead of prompting you. When the lines run out the CCP deletes the file and goes
back to prompting. (The lines are stored in reverse and consumed from the end, so "take the next
one" is just "decrement the record count".)

### B2. Why the BDOS is involved at all

Checking "does `$$$.SUB` exist?" on **every warm boot** would mean a directory search every time.

But the BDOS already walks the *entire* directory when it logs a drive in, because that is how it
rebuilds the allocation vector: read every entry, mark the blocks each one owns. DRI piggybacked
the check onto that walk. While marking blocks it also asks, per entry, "does this belong to the
current user, and does its name start with `$`?" If so it sets a flag. The walk was happening
anyway, so the check is free.

The flag is then handed back as the result of **BDOS function 13, Reset Disk System**, which is
documented as returning `0FFh` if a file whose name begins with `$` is present and `0` otherwise.
The CCP makes that one cheap call and learns whether it is worth opening `$$$.SUB`.

Note it tests only the **first character**, not the whole name. It is a hint, not an answer: "there
might be a submit file here, go look properly."

### B3. The code, and why it read as unknown

```asm
        LD A,(BDOS_USER_NUM)   ; current user number
        CP (HL)                ; this entry's user byte?
        JP NZ,ALLOC_VECTOR_SCAN_MARK
        INC HL
        LD A,(HL)              ; first name character
        SUB $24                ; '$'?   (leaves A = 0 when it matches)
        JP NZ,ALLOC_VECTOR_SCAN_MARK
        DEC A                  ; 0 -> $FF
        LD (BDOS_RETVAL),A     ; fn 13's result
```

The cell at `$9F41` was labelled `BDOS_STACK_TOP`, so this read as "compare a directory entry
against a stack byte", which is meaningless. Hence the `[?]`.

It is a **dual-use cell**, and DRI saving a byte rather than an accident. `BDOS_DISPATCH` does
`LD SP,$9F41`, but the Z-80 decrements `SP` **before** writing, so the first push lands at `$9F40`
and the stack grows down from there. The byte at `$9F41` is never touched by the stack, so DRI put
the current user number in it. The same file already knew that at `FCB_MERGE_USER` and
`F_USERNUM_H`; only the definition and the one site that mattered carried the stack-only name.

Answering your three settling questions: `$9F41` is written by `F_USERNUM_H` (fn 32) and is the
current user number; `$9F45` is read by the dispatcher on the way out, being the ordinary BDOS
return cell; and the branch is **standard DRI**, carried identically by the 2.20 and 2.23 BDOSes.

**Your Part-2 observation stands and is worth keeping**: both tests jump to `MARK` and the
fall-through reaches `MARK` too, so every non-`$E5` entry has its blocks marked regardless. The
probe only sets a flag. "`$E5` and for no other reason" is safe.

---

## PART C. Every test I ran, and what it established

| # | Test | Result |
|---|---|---|
| 1 | Rebuild the allocation vector from each archived disk's real directory under both `DSM` values | 2.20 disk 2 KB @127 / **14 KB** @139; your figure confirmed. Recomputed with the correct 48-entry directory; agrees with the 64-entry run |
| 2 | Boot 2.23 with the reservation entry deleted, run `STAT` | `A: R/W, Space: 12k`. Offers space it should not |
| 3 | `SAVE 4 Z.ZZZ` on that disk | **Succeeds silently.** Directory entry committed: `Z.ZZZ`, EX=0, RC=`$08`, blocks=[128] |
| 4 | Diff the image before/after | **689 bytes of track 0 changed**; tracks changed = [0, 3] |
| 5 | Instrument the sector hook: log every request including rejects | Track 35 **never requested**. IOB track = 0 |
| 6 | Read CP/M's own `sektrk` (`$FED1`) and the DSM cell (`$FEE3`) at each request | `$FED1`=35, `$FEE3`=`$8B`, IOB track 0. The fold, caught in the act |
| 7 | Trace the boot loader's 29 sector loads | Staging is contiguous `$7000-$8CFF`; the 8 track-2 sectors in no `ChunkSpec` are **never read** |
| 8 | Search each assembled chunk for the deblock signature | Present in `CPM223_BootLoader` at offset 1097. It was decoded all along |
| 9 | Round-trip: known 256-byte pattern in TPA, `SAVE 1 P.PPP` | Pattern arrived **byte-for-byte at track 0 sector 0**. The blocks are real storage |
| 10 | Enumerate every BDOS function code in `CPM60.COM` and every call on COPY's FCB | No read/write call in either. Reservation, not conduit |
| 11 | Read `ALLOC_FROM_FCB` | Pure bitmap op, no block-to-track conversion. The reservation needs no fold |
| 12 | Read the shipped RWTS (`RWTS_MAIN`, `$0EC0`-`$0F0B`) | 48 inner retries, recalibrate, returns `$40`; **the write is gated behind the address-field match** |
| 13 | Verify the emulator's disk model at the limit | Default path asserts `if track >= 35`; the faithful nibble path is read-only |
| 14 | Grep all trees for the fold | `CP $8B` / `SUB $23` exists **only** in 2.23's deblock |

Test 12 is worth keeping even though it turned out to be off-path: it establishes what a drive
*would* do if it were ever asked for track 35. It never is.

---

## PART D. Every change, and why

All comment-, label- and doc-level. **No assembled byte moved at any point.** Tracked `.lst` files
and the INCBIN listing comment were regenerated after each source edit.

### D1. Corrections to shipped-code annotation

| File | Was | Is | Why it mattered |
|---|---|---|---|
| `CPM60_installer.asm` | `LD E,$1F` = "get current user" | **sets** user 31 | Hid the entire reservation mechanism |
| `CPM60_installer.asm` | fn `$1B` "get DPB", `+$10` "geometry sanity byte" | `Get Addr(Alloc)`; free-space check on blocks 128-139 | Made a deliberate check look like noise |
| `CPM60_installer.asm` | `RW_SECTOR` `$F3E0` | `IOB_TRACK` | **Your find.** Hid that the installer starts at track 0 |
| `CPM60_installer.asm` | `RW_TRACK` `$F3E9` "start at track $14 (20)" | `IOB_BUF_HI`, buffer page | Nonsense value; also contradicted its own comment |
| `CPM60_installer.asm` | `RW_SECCNT` `$F3EB` "sector count" | `IOB_CMD`, 2 = write | |
| `COPY.asm` `$037F` | "opens the source CPM*.SYS file ... reads the OS image" | `WRITE_SYSTEM_RESERVATION` | Opens nothing, reads nothing, **creates** the entry |
| `COPY.asm` | `OPEN_SYSTEM_FCB` "opens (BDOS 15)" | `F_DELETE` (`$13`) | |
| `COPY.asm` | `LD DE,RST2_VEC` | `$0010`, a bitmap offset | Blind `cpm22.inc` rename |
| `COPY.asm` | `FORMAT_DEST_DISK` "writes a fresh CP/M system image" | It does not | |
| `DiskXlate.asm` | `IOB_SECTOR` `$F3E0` | `IOB_TRACK` | The fold read as arithmetic on a sector |
| `DiskXlate.asm` | `IOB_TRACK` `$F3E4` | `IOB_DRIVE` | |
| `DiskXlate.asm` | `SCR_D1`/`SCR_D2` "sector"/"track" | `REQ_TRACK`/`REQ_RECORD` | **Transposed** |
| `DiskXlate.asm` | `SCR_E3` "deblock flag scratch" | `DPB_DSM` | The fold tests it against `$8B` |
| `CPM_BDOS.asm` x3 | `BDOS_STACK_TOP` | `BDOS_USER_NUM` | Made the `$$$.SUB` probe unreadable |
| `CPM_BDOS.asm` x3 | `[?] ... intent is UNKNOWN` | resolved, with DRI provenance | |
| `CPM_BIOS.asm` x2 | "whether `$8B` is an error or a convention is NOT determinable" | resolved | |
| `FORMAT_6502.s`, `COPY_6502.s` | plain constants | the `$E5` derivation | The one thing you could not get from the images |
| `BOOT.asm` | (nothing) | "IT WRITES NOTHING" | The 512-byte size invites the opposite assumption |
| `STAT` x2, `GBASIC` x2, `MBASIC`, `src/os/CPM_CCP` | `RST2_VEC` | `$0010` literal | Six blind renames; all were the number 16 |

Your `$FEE3` trace, which I had asserted rather than proven, is now the header's justification:
`SELDSK` at `$FEA0` walks `DPH_TABLE` to the drive's DPH, takes the DPB pointer at DPH+10, adds 5,
and stores that byte to `$FEE3`. DPB+5 is the low byte of `DSM`. The deblock therefore tests the
running drive's `DSM` at every select. Also recorded: `$FEE2` is a two-tenant overlay
(`LD HL,($F3DE)` at cold boot, self-modified by `SELDSK` afterwards), which is the hazard class
already on file in Part 1 §3 and is why the cell read as scratch.

### D2. Documents

* **`docs/CPM_Disk_Creation.md`** (new) — the eight questions, with an update section carrying the
  fold and the narrowed hazard.
* **`docs/CPM_Filesystem.md`** — "64 directory entries" corrected to **48** (`DRM`=`$2F`;
  `CKS`=12=48/4 confirms). Its "zero-fill tracks 3-34 for an empty directory" was wrong: a zero
  slot is a valid user-0 entry, so that yields 64 blank files. Must be `$E5`. Added sections on
  how a formatted disk gets its directory and on the reservation entry.
* **`CPMV223-60K/CPM60_COM.md`, `BOOT_AND_PATCHING.md`** — the stale `$1B`/DPB claim and the
  stale IOB cell names.

### D3. Tooling

* **Audit 4** in `cpm_pipeline/annotation_audit.py` (+4 tests): flags any comment **or doc** naming
  a BDOS function number alongside another function's terms. It scans `.md` too, because both bad
  `$1B` claims had propagated into the 60K markdown. Zero hits on the current tree.

---

## PART E. Decisions, and two things I got wrong

### E1. Decisions

* **`DSM`=`$8B` is deliberate.** It cannot be presented as Microsoft misreading their own manual.
  The Alteration Guide's two readings still explain how 139 is arrivable, but the deblock is built
  around that exact value. Agreed with your §4; the section built on it should go.
* **The hazard, not the arithmetic, is the story.** Specifically: a disk with a boot image and no
  entry is indistinguishable from a data diskette.
* **Cite the two secondary sources as corroboration, not authority.** They are `[?]` tier and one
  of them has a wrong DPB table. What makes them worth citing is that they agree with the code.
* **Do not claim the emulator settles hardware behaviour at track 35.** It cannot, and it does not
  need to, because the drive is never asked.

### E2. Two things I got wrong, both self-corrected

* **Part 4's "2 KB decode gap" was wrong.** There is no gap. The deblock was already decoded in
  `CPM_BootLoader_DiskXlate.asm` and INCBIN'd into the boot loader. I was misled by 8 track-2
  sectors absent from every `ChunkSpec` (never read at boot) and by mapping a disk file offset back
  to a sector without applying the interleave. Please drop that work item; Part 5 §0 retracts it.
* **Part 5's exposure claim was too broad.** I said a `COPY /F` disk was exposed. It is not; that
  is the designed use. Corrected in Part 7 §A3 and in every source and doc that carried it.

Also for the tally: my own `OPEN_SYSTEM_FCB` header from `01477bf` said COPY "removes" the entry,
when the delete is the first step of rewriting it. A correction that needed correcting, which is
now two of those in this thread.

### E3. Open

* **An audit gap I could not close.** The 60K BDOS header already said the test was "against the
  current user" while both 44K files said "the BDOS default-FCB byte". Audit 3 missed it because
  its polarity list covers opposite *states*, not different *nouns*. Extending it that far would be
  very noisy. A narrow alternative worth building: flag a label whose header is `[?]`/UNKNOWN in
  one tree but explained in another. Not built.
* **No historical report of the failure.** Three searches found no account of a 2.20 disk being
  destroyed by a 2.23 system, and no cross-version warning in the community reference. The
  mechanism is documented; the hazard is documented nowhere. Absence of a report is not absence of
  the failure, and I would not assert either way in print.
* `CAT.asm`, `PATCH.asm`, `AUTORUN.asm` never examined.
