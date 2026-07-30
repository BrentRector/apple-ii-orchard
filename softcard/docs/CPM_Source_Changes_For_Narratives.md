# CP/M source changes, 2026-07-30: a handoff to the write-up session

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
SPT:    DEFW    $0020                    ; records per track: 32 x 128-byte records
BSH:    DEFB    $03                      ; block shift: log2(records per block) -> 8 records
BLM:    DEFB    $07                      ; block mask: (records per block) - 1 -> 1 KB blocks
EXM:    DEFB    $00                      ; extent mask
DSM:    DEFW    $007F                    ; highest allocation block number: 127 -> 128 blocks
DRM:    DEFW    $002F                    ; highest directory entry number: 47 -> 48 entries
AL0:    DEFB    $C0                      ; directory-reserved blocks, bitmap, high byte -> 2
AL1:    DEFB    $00                      ; ditto, low byte
CKS:    DEFW    $000C                    ; directory checksum bytes
OFF:    DEFW    $0003                    ; reserved tracks before the file area
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

### Provenance: do NOT cite a manual for this

The ten field names are Digital Research's, from the CP/M 2.2 specification. They are
**not** in the SoftCard manual set held in `softcard/reference/`. All five transcribed
manuals were checked: they document BDOS function 31, the call that *returns* a DPB
pointer, and not the block's layout. The sources therefore carry no `[DOC]` tag on the
field names, and the derived geometry is marked `[RE]`. An article should not say the
SoftCard manuals document the DPB.

---

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
