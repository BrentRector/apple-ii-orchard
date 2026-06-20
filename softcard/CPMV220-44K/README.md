# CPMV220-44K — Microsoft SoftCard CP/M 2.20, 44K (original 1980)

A **clean-room** decompile of the original 1980 SoftCard CP/M 2.20 / 44K system
disk (`reference/softcard-cpm-archive/os/softcard-cpm2.20-44k-system-1980.dsk`).
Every byte of source here was derived **only** from that disk's bytes plus
general CP/M 2.2 / Z-80 / 6502 / Apple II knowledge and the primary-source 2.20
manuals — **no 56K (`CPMV220`) or 2.23 (`CPMV223-*`) source was consulted.**

The whole disk reconstructs **byte-identical** from this tree:

```bash
python -m cpm_pipeline.reconstruct \
    reference/softcard-cpm-archive/os/softcard-cpm2.20-44k-system-1980.dsk \
    /tmp/out.dsk --variant 220-44k
```

(`reconstruct._detect_variant` auto-selects `220-44k` for this disk by the Z-80
reset-plant base `$AA00`, vs `$DA00` for the 2.20B-56K build.) Regression tests:
`test_cpm220_44k_reconstruct_byte_identical` and the whole-disk variant.

## os/ — the operating system (44K runtime bases)

Each region was independently decompiled and **adversarially verified**, and
reassembles byte-identical. Runtime layout (the original 44K column): CCP
`$9400`, BDOS `$9C00`, BIOS `$AA00`.

| File | CPU | Org | Notes |
|------|-----|-----|-------|
| `CPM_BootLoader.s` | 6502 | `$0800` | boot sector + RWTS + stage-2 + install image; COPYRIGHT banner |
| `CPM_CCP.asm` | Z-80 | `$9300` | serial page + CCP (`$9300-$9BFF`); `INCBIN`s the embedded 6502 RPC block (`CPM_RPC6502.s`) at `$9400` |
| `CPM_BDOS.asm` | Z-80 | `$9C00` | BDOS (`$9C00-$A9FF`); function entry `$9C06`; dispatch via runtime pointer cell `$9F43` |
| `CPM_RPC6502.s` | 6502 | `$9400` | the embedded 6502 RPC / warm-boot / sector-service block; assembled separately, `INCBIN`'d into CCP. One config byte (`$94AE`, the warm-boot buffer hi) is `CFG_56K`-conditional |
| `CPM_BIOS.asm` | Z-80 | `$AA00` | 17-entry jump table; runtime handlers are `$E5` trap-fill on disk |

The former combined `CPM_SystemImage.asm` was **split into its two OS
components** (`CPM_CCP.asm` + `CPM_BDOS.asm`, boundary = BDOS base `$9C00`) so
each is a relocatable module the 56K fold (`CPM56.asm`) can `DISP` independently,
mirroring the `CPM60.asm` pattern. Each carries absolute-address `EQU`s for the
symbols it references across the boundary; both reconstruct byte-identical.

## utilities/ — the .COM programs (19 disk files)

The disk carries 17 `.COM` + 2 data files. **CPMV220-44K is the BASE source tree:**
the utility `.asm` here are the single source-of-record for every `.COM` that is
byte-identical across the 44K releases, so the 2.23-44K tree carries only the
utilities whose bytes differ. Each `.asm` reassembles byte-identical to its disk
`.COM` (gated by `test_utilities_roundtrip.py`; the shared ones are additionally
cross-checked against the 2.23-44K disk).

**Decompiled here (12):**

| Group | Files |
|-------|-------|
| shared base (byte-identical on both 44K disks) | `APDOS ASM DOWNLOAD DUMP ED LOAD PIP STAT XSUB` |
| 2.20-44K-specific (bytes differ from 2.23-44K) | `CPM56` (SoftCard 56K-overlay installer), `DDT`, `SUBMIT` |

**Not yet decompiled (3 — TODO):** `COPY`, `FORMAT`, `RW13`. Their 2.20-44K bytes
differ from **both** the 2.23-44K and the 2.20-56K versions, so no existing `.asm`
covers them; they still need their own 2.20-44K decompilation.

**On-demand (2):** `GBASIC`, `MBASIC` — stock Microsoft BASIC; reconstruct
byte-identical via `cpm_pipeline.decompile_com` on demand (≈25 KB stock
interpreters, mostly data tables; full committed listing omitted).

**Carried as data (2):** `CONFIGIO.BAS` (BASIC source text), `DUMP.ASM` (8080
assembler source text) — genuine non-code text files, carried verbatim.
