# CP/M 2.20/2.23-44K — the system-track SECTOR SKEW finding (2026-06-23)

> **One-line lesson:** the 44K OS sources were decoded against the **on-disk** byte
> order, but the CPU runs the image in a **sector-de-interleaved** order. Byte-identical
> reassembly only proves *disk* reproduction; it is **blind** to whether each source
> label matches the **runtime** address. They mostly do **not** (~10% match). Decode
> against the **de-skewed runtime image**, not the raw disk bytes.

## What is true

CP/M stores the CCP/BDOS on the system tracks **sector-interleaved** (a 2:1-style skew).
The cold loader reads them in *logical* sector order through the RWTS skew table into
**contiguous** RAM, which **de-interleaves** them. So:

- **on-disk order** (what the source decodes, what `assemble_chunk` emits, what the byte
  gate checks) = sector-interleaved.
- **runtime order** (what executes; what the dispatch table, the `$0005` entry, and every
  CALL/JP target refer to) = de-interleaved/contiguous.

The current sources use one uniform `DISP $9A01` over the whole BDOS body. That makes a
source label equal the runtime address **only on the one page** where the skew delta
happens to equal the DISP delta — the dispatch table at `$9C47`. Everywhere else the
listing's address→code mapping is wrong.

## Proof (definitive, copy-immune)

For every BDOS listing line `(DISP addr, emitted bytes)`, compare those bytes to the
**runtime** memory at that **same** address (booted in `softcard_emu`, read via `realmap`):

| tree | source-DISP bytes that match runtime ($9C00–$A5FF) |
|---|---|
| **2.20-44K** | **289 / 2794 = 10.3 %** |
| **2.23-44K** | **272 / 2476 = 11.0 %** |

The ~10 % that match are the dispatch page plus coincidences. The 2.20 and 2.23 BDOSes
differ by only ~50 patch bytes and show **byte-for-byte the same divergence**, so this is
systemic, not a one-tree slip. (Done independently per tree, each byte-identical, each
boots — and both are decoded in on-disk order.)

## The mechanism, measured

Reliable unique-window matching of runtime↔on-disk (the clean BDOS pages, 256/256):

```
runtime  <- on-disk     runtime  <- on-disk     runtime  <- on-disk
 $9A00   <- $9A00 (0)     $9D00   <- $A000        $A100   <- $9900
 $9B00   <- $9C00         $9E00   <- $A200        $A300   <- $9D00
 $9C00   <- $9E00         $9F00   <- $A400        $A500   <- $A100
 (dispatch tbl $9C47)     $A000   <- $A600        $A700   <- $A500
                                                  $A800   <- $A700  $A900 <- $A800
```

Runtime consecutive pages come from **every-other** on-disk page (`$9E,$A0,$A2,$A4,$A6`…)
— the 2:1 de-interleave. (The CCP-head pages `$9300–$95FF` and the exact track-boundary
behaviour need the RWTS skew table to pin byte-perfectly; derived during re-basing.)

## The skew was the root of every "mystery"

Building the **pristine de-skewed image** (on-disk bytes re-ordered by the measured
permutation) makes the BDOS **coherent** and dissolves the artifacts we kept fighting:

- `$9EC8` (fn1 Console Input) = `CD 06 9D C3 01 9F …` — a clean handler.
- `$9F01` = `LD ($9F45),A; RET; LD A,$01; JP $9F01` — the real **BDOS result/return tail**,
  *not* the "out-of-image `CALL $01A4`" the analysis kept hitting.
- The `BDOS_VAR_PAGE_n` "RUN-BASE SHADOW" cells, the "cover-merge" entries, the
  staging-vs-runtime confusion, and the upper fn 12–40 handler block that decoded as
  `$E5` fill — **all** are sector-seam artifacts of reading the interleaved order as if
  contiguous. They vanish in the de-skewed image.

## Scope

- **In scope: the 44K trees only** — `CPMV220-44K` and `CPMV223-44K`. Both affected
  (CCP **and** BDOS).
- **Out of scope: 56K (`CPMV220`).** It relocates into the language card — a totally
  different mechanism — and we are not touching it.
- The 6502 boot loader is a separate (6502-side) image and is not part of this skew.

## The fix (the new direction)

Re-base the OS decode onto the **de-skewed runtime image**: every section ORG'd to its
true runtime address, code genuinely contiguous, every label a real runtime address — no
shadows, no cover-merge seams. The build's `chunk_map`/disk producer then **re-applies the
sector skew** when writing the sectors, so the disk stays **byte-identical**. The CCP/BDOS
split and the export header become trivial on a correctly-addressed source.

## How to not repeat this

- **Verify against the emulator runtime, not only the byte gate.** A new gate: after a
  byte-identical build, boot it and assert source-listing bytes == runtime bytes at the
  same address (the test above). Byte-identity is necessary, not sufficient.
- **Decode the de-skewed (runtime) image,** never the raw on-disk concatenation, for any
  image the loader de-interleaves (the system tracks). See
  `[[feedback_decode_deskewed_runtime_not_ondisk]]`.

## Reproduce

Scratch scripts (in `E:/tmp`, session-scratch): `lst_vs_runtime.py` /
`lst_vs_runtime_223.py` (the 10/11 % proof), `deskew_build.py` (build + verify the
de-skewed image, round-trip). Disk: `reference_data.DISK_2_20_44K_SYSTEM`. Emulator:
`softcard_emu.machine.SoftCardMachine`; Z-80→Apple via `softcard_emu.switch.realmap`.
