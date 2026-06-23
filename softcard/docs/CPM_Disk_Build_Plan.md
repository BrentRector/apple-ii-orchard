# CP/M Disk-Image Build Plan -- what we produce and how it reaches a disk

**Status: PLAN (2026-06-23).** Defines the build artifact model for a SoftCard CP/M disk and
the two ways we turn our sources into a bootable image. The emulator-driven path (Brent's
proposal) is the chosen *from-scratch* producer.

## The artifact

A SoftCard CP/M disk image is a **single flat 143,360-byte raw sector image** (35 tracks x 16
sectors x 256 bytes -- every sector in order), in one of two byte-orderings: `.dsk` (DOS 3.3
interleave) or `.po` (ProDOS). `cpm_pipeline.reconstruct._transcode` converts between them. It
is NOT a container of named files at the OS level. Two regions:

1. **Reserved system tracks (0-2) -- the OS, as RAW sectors, NOT files.** CP/M 2.2 has no
   `CPM.SYS` (that is CP/M 3); the boot sector loads the OS from these reserved tracks into RAM:
   - track 0 sector 0: boot sector (boot-loader page 1)
   - tracks 0-2 (the chunk_map `staging_sectors`): the system image -- CCP+BDOS (disk
     `$0000-$16FF`) then BIOS (`$1700-$1BFF`)
   Each piece is assembled from an `os/` source to a `.bin` and written to its physical
   `(track, sector)` position by `_place_chunks` (applying the SECTRAN/interleave).
2. **Filesystem / data tracks (3+) -- standard CP/M 2.2 filesystem.** The utilities ARE files
   here: a 64-entry directory (2 directory blocks) at the start of the data area, then each
   `.COM` as 1 KB allocation blocks chained by directory-entry extents. Address chain
   (`filesystem.py` / `CPM_Filesystem.md`): dir entry -> 1 KB block (4 logical sectors) ->
   logical->physical via SECTRAN skew `(L*3)%16` -> on-disk offset via the interleave.

## What we assemble

Per-component binaries: the system image (`CPM220_44K_System.bin` = CCP+BDOS), `CPM_BIOS` bin,
the boot loader bin, and each utility `.COM`. These are placed into the raw image; they are not
shipped individually.

## Builder 1 -- `reconstruct` (reference-anchored; the byte-identical GATE)

- `reconstruct_disk("220-44k", reference)`: OS chunks from source onto the system tracks;
  everything else (the whole filesystem) copied verbatim from the reference disk. This is the
  per-commit gate (`test_cpm220_44k_reconstruct_byte_identical`).
- `reconstruct_full_disk(reference)`: OS from source PLUS every `.COM` from its re-assembled
  source placed into its blocks; directory metadata + free space still carried from the
  reference. Verifies byte-identical.
Both still lean on the reference disk for the **directory** (we do not synthesize directory
entries / block allocation from scratch).

## Builder 2 -- emulator-driven, from scratch (CHOSEN; the authentic producer)

Use the real OS, running in `softcard_emu`, to lay out its own filesystem -- no reimplementation
of CP/M's directory/allocation logic:
- (a) Build a disk with the OS tracks (Builder-1 placement) + a freshly-formatted data area
  (directory = `$E5`).
- (b) Boot it in `softcard_emu` (the `.dsk` IS the mounted drive A:; RWTS write path already
  proven -- it reproduces CPM60's written tracks byte-identical).
- (c) At `A>`, the harness drives **BDOS** for each utility in the reference's directory order:
  `C=F_MAKE($16),DE->FCB`; loop { fill DMA `$0080` with the next 128-byte record from the host
  `.COM`; `C=F_WRITE($15)` }; `C=F_CLOSE($10)`. The OS performs the directory entry, block
  allocation, and sector write. (Scripted PIP, but driving BDOS directly so no second drive /
  transfer protocol is needed.)

**Byte-identity:** CP/M 2.2 allocates blocks linearly from the first free block and writes
deterministic directory entries, so writing files in the **same order / USER areas as the
original** (read once from the reference's directory) reproduces the original layout byte-for-
byte. Deleted-file holes / odd USER numbers are the only thing to replicate explicitly; the
reference disk supplies them.

**Independence + sequencing:** the emulator runs the OS BINARY (byte-identical regardless of
source comments), so this builder does NOT depend on the source-comment uplift and can be built
anytime. It is scheduled as the CAPSTONE because it doubles as the strongest end-to-end test of
the enriched BDOS/BIOS: it exercises the exact `F_MAKE`/`F_WRITE`/`F_CLOSE`/directory/SECTRAN/
RWTS-write paths we are reverse-engineering. A diff of the emulator-built disk vs the original
surfaces real OS-understanding gaps a self-consistent Python `mkfs` never could.

## Recommendation

Keep `reconstruct` as the day-to-day byte-identical gate. Build the emulator-driven
`F_MAKE`/`F_WRITE` producer as a defined deliverable (it can run independently of the uplift,
but is most valuable as the capstone validation once the OS sources are trustworthy).
