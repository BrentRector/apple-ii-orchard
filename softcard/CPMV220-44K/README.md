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

The disk carries 17 `.COM` + 2 data files. All 17 `.COM` reconstruct
byte-identical (the whole-disk rebuild decompiles each and lands on the exact
original bytes).

**Decompiled here (5 — new to this disk, no byte-identical prior decompile):**

| File | Source-of-record |
|------|------------------|
| `CPM56.COM` | `utilities/CPM56.asm` — the SoftCard 56K-overlay installer |
| `DDT.COM` | `utilities/DDT.asm` — the CP/M dynamic debugging tool |
| `SUBMIT.COM` | `utilities/SUBMIT.asm` — the CP/M batch processor |
| `GBASIC.COM` | stock Microsoft BASIC (graphics); reconstructs byte-identical via `cpm_pipeline.decompile_com` on demand — full committed listing omitted (≈25 KB stock interpreter, mostly data tables) |
| `MBASIC.COM` | stock Microsoft BASIC; same as GBASIC |

**Reused (12 — byte-identical to an already-decompiled build, per the user's
"reuse the binary-identical apps" direction):**

| File | Byte-identical source |
|------|-----------------------|
| `APDOS.COM` | `CPMV220/utilities/APDOS.asm` (also `CPMV223-44K`) |
| `ASM.COM` | `CPMV223-44K/utilities/ASM.asm` |
| `COPY.COM` | `CPMV220/utilities/COPY.asm` |
| `DOWNLOAD.COM` | `CPMV220/utilities/DOWNLOAD.asm` (also `CPMV223-44K`) |
| `DUMP.COM` | `CPMV223-44K/utilities/DUMP.asm` |
| `ED.COM` | `CPMV223-44K/utilities/ED.asm` |
| `FORMAT.COM` | `CPMV220/utilities/FORMAT.asm` |
| `LOAD.COM` | `CPMV223-44K/utilities/LOAD.asm` |
| `PIP.COM` | `CPMV220/utilities/PIP.asm` (also `CPMV223-44K`) |
| `RW13.COM` | `CPMV220/utilities/RW13.asm` |
| `STAT.COM` | `CPMV220/utilities/STAT.asm` (also `CPMV223-44K`) |
| `XSUB.COM` | `CPMV223-44K/utilities/XSUB.asm` |

**Carried as data (2):** `CONFIGIO.BAS` (BASIC source text), `DUMP.ASM` (8080
assembler source text) — genuine non-code text files, carried verbatim.
