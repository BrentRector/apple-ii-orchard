# The "CP/M 2.23B, 63K" SoftCard image is a relabelled 2.20B-56K disk

**Status:** withdrawn from the archive's release set on 2026-07-31. The image itself is NOT
retained; this document exists so the same file can be identified again if it is re-downloaded.

| | |
|---|---|
| Archive path (removed) | `os/softcard-cpm2.23b-63k-system.dsk` |
| Filename as distributed | `CPM2.23(60k).dsk` |
| Source | `https://ftp.apple.asimov.net/images/cpm/os/` |
| md5 | `18a6f7b191712fcfb1f8a2e30540ad2e` |
| Size | 143,360 bytes (35 tracks x 16 sectors x 256) |
| What it actually is | `os/softcard-cpm2.20b-56k-system.dsk` with 40 bytes edited |

It is neither 63K nor 2.23. Both numbers on its label were put there with a sector editor.

## How to identify it without the bytes

md5 is sufficient. Failing that: it is a 2.20B 56K system disk whose sign-on banner reads
`63K Ver. 2.23B` and `(C) 1982 DATASOFT`, and whose no-card message reads
`CAN'T FIND STUPID CARD.`

## Evidence

### 1. It is 99.67% identical to a 2.20B-56K disk and shares almost nothing with any real 2.23

Comparing the 12,288 bytes of the system area (tracks 0-2, `img[:3*16*256]`) against every
other image then in `os/`:

| Compared with | Identical | Bytes differing |
|---|---:|---:|
| `softcard-cpm2.20b-56k-system-workingcopy.dsk` | 99.67% | 40 |
| `softcard-cpm2.20b-56k-system.dsk` | 99.67% | 41 |
| `softcard-cpm2.20b-44k-system.dsk` | 89.11% | 1338 |
| `softcard-cpm2.20-44k-system.dsk` | 88.93% | 1360 |
| `softcard-cpm2.20-44k-system-1980.dsk` | 88.93% | 1360 |
| `softcard-cpm2.23-60k-ccompiler-sn010793.dsk` | 14.71% | 10480 |
| `softcard-cpm2.23-60k-system-sn014d40.dsk` | 6.36% | 11507 |
| `softcard-cpm2.23-60k-system-sn010793.dsk` | 6.32% | 11511 |
| `softcard-cpm2.23-44k-system.dsk` | 6.18% | 11529 |

A disk claiming to be 2.23 that shares 6% of its system area with every genuine 2.23, and
99.67% with a 2.20B, is not a 2.23.

### 2. The archive supplies its own scale for reading "40 bytes"

Both figures are measured over the same 12,288-byte window:

* a **real** memory-size change within this family (44K to 56K, same version) costs
  **1,301 bytes**;
* two archived copies of the **same** build differ by **1 byte**.

Forty bytes is two orders of magnitude short of a rebuild and one order past a copy. It is an
edit.

### 3. The forty bytes are seven in-place substitutions, each the length of what it replaced

Offsets are track + byte offset within the track (16 sectors x 256). "old" is
`softcard-cpm2.20b-56k-system.dsk`.

| Offset | old | new |
|---|---|---|
| T0 +$004F | `0 MICROSOFT` | `2 DATASOFT ` |
| T0 +$012C | `$B6 $59` | `$27 $DC` |
| T0 +$073A | `Z80 SOFTCARD` | `STUPID CARD.` |
| T1 +$0C04 | `$B6 $59` | `$27 $DC` |
| T2 +$0988 | `56` | `63` |
| T2 +$0994 | `0` | `3` |
| T2 +$099F | `0 Microsoft\r` | `2 DATASOFT\n\n` |

In context (high-bit ASCII decoded):

```
copyright  old: "PYRIGHT (C) 1980 MICROSOFT - NK"
           new: "PYRIGHT (C) 1982 DATASOFT  - NK"
card msg   old: "AN'T FIND Z80 SOFTCARD"
           new: "AN'T FIND STUPID CARD."
banner     old: "[ CP/M..56K Ver. 2.20B..(C) 1980 Microsoft"
           new: "[ CP/M..63K Ver. 2.23B..(C) 1982 DATASOFT"
```

`STUPID CARD.` and `Z80 SOFTCARD` are both 12 characters. `DATASOFT ` is padded with a trailing
space to the width of `MICROSOFT`. `2.23B` and `2.20B` differ in one character. Same-length,
in-place replacement is what a sector editor forces and what an assembler has no reason to
produce: rebuilding at a different memory size moves code, and 2.20B to 2.23 is a different
program, not a different string table.

### 4. The serial was altered, at both sites

`$B6 $59` becomes `$27 $DC` at two independent offsets (T0 +$012C and T1 +$0C04). `MANIFEST.csv`
recorded both values before this was understood: the two genuine 2.20B-56K rows carry serial
`BD 16 00 00 B6 59`, and this image's row carried `BD 16 00 00 27 DC`. Changing a machine serial
at every site it appears is what moves this from a cosmetic rebrand to defeating a copy
identifier.

### 5. The 41st byte is not the counterfeiter's

Against `softcard-cpm2.20b-56k-system.dsk` the count is 41, not 40. The extra byte is at
T2 +$0B2F, where the two archived 2.20B-56K images **already disagree with each other**:
`softcard-cpm2.20b-56k-system.dsk` has `$3E` and `softcard-cpm2.20b-56k-system-workingcopy.dsk`
(md5 `07a885f2249f475cb1fdd56155d4570f`) has `$31`. The counterfeit has `$31`.

That byte is therefore not attributable to the edit; it is a pre-existing difference between two
genuine 2.20B-56K disks. **No claim is made here about which disk the counterfeiter started
from.** A shared byte is consistent with a common parent and does not establish descent, and the
workingcopy's own history is not independently known.

## Why it was withdrawn rather than kept and annotated

1. **Both numbers on its label are false**, and `MANIFEST.csv` asserted them as data
   (`cpm_version=2.23B`, `config=63k`). Any query over the manifest returned a wrong answer.
2. **It manufactured a phantom release configuration.** Counting configurations gave six; there
   are five. It also appeared as an eighth `$7F`-DPB image and as the sole exception to the
   otherwise clean `$7F` / `$8B` split between the 2.20 lineage and Microsoft's 1982 rewrite.
   That exception does not exist.
3. **Its provenance is poisoned past the parts examined.** Whoever rewrote the serial and the
   version string is not a reliable witness to the rest of the disk, and the file area was never
   diffed.
4. **Nothing depended on it.** No `.py`, `.asm`, `.md`, `.json` or `.toml` in the repo referenced
   the filename; `MANIFEST.csv` was the only place it was named.

Its `MANIFEST.csv` row is kept, corrected to the truth and marked withdrawn, rather than deleted.
A removed row would read as "the archive never had this", which is a different and less useful
statement than "the archive had this and rejected it".

## Reproducing the check

The comparison needs only `softcard-cpm2.20b-56k-system.dsk`, which is retained:

```python
from pathlib import Path
SYS = 3 * 16 * 256                       # tracks 0-2, the system area
a = Path("os/softcard-cpm2.20b-56k-system.dsk").read_bytes()[:SYS]
b = Path("<the suspect image>").read_bytes()[:SYS]
diff = [i for i in range(SYS) if a[i] != b[i]]
print(len(diff))                          # 41 for this image
```
