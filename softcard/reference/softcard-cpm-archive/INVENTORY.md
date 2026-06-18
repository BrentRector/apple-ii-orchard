# SoftCard CP/M disk-image reference inventory

Downloaded masters for analysis. Compiled 2026-06-17 from a multi-source sweep
(Asimov `ftp.apple.asimov.net/images/cpm/os/`, the apple2.org.za **Apple II
Documentation Project**, and web mirrors). The list the user originally supplied
(`.../masters/microsoft/softcard/CMPv2xx.dsk`) is **dead** - that path does not
exist on the mirror; every URL returned one identical 20853-byte HTML soft-404.

**`CMPv...` naming, explained:** there is no literal "CMPv" anywhere. It is a
letter-transposition of Asimov's real **`CPMv`** scheme. "CMPv220" = `Cpmv22_44k.dsk`
(a 44K 2.2 build); "CMPv223" = `CPMV233.DSK` (2.23).

All `.dsk/.po/.cpm` here are standard 143360-byte (140K) Apple images unless noted.
Host needs `curl -k` (cert quirk on ftp.apple.asimov.net).

## Provenance matches against the repo (md5)

| Downloaded file | md5 | Identical to repo file |
|---|---|---|
| `CPMV233.DSK` | `b6ebb2ae…` | `softcard/CPMV223-44K/CPMV223-44K.DSK` |
| `DocProj_SoftCard_Disk1.po` | `c2c24f49…` | `softcard/CPMV220/CPMV220-Disk1.po` (56K 2.20B) |

No other downloaded image duplicates another (all md5-distinct).

## PRIMARY - original Microsoft Z-80 SoftCard CP/M (downloaded)

| Local file | Version | Config | md5 | Notes |
|---|---|---|---|---|
| `Softcard_16sector_MS1980.dsk` | 2.20 | 16-sector | `4395a2fc…` | Dated "Microsoft 1980": earliest original-SoftCard release |
| `Cpmv22_44k.dsk` | 2.2 | **44K** | `344fa310…` | The low-memory config; candidate **no-Language-Card** 2.20 |
| `CPM2.2_56k.dsk` | 2.2 | 56K | `1d40d688…` | 56K build |
| `CPM_V2.2_56k.dsk` | 2.2 | 56K | `07a885f2…` | Distinct 56K dump (NOT identical to the above) |
| `CPMV233.DSK` | 2.23 | 44K | `b6ebb2ae…` | = repo CPMV223-44K source-of-truth |
| `CPM2.23_60k.dsk` | 2.23 | 60K | `18a6f7b1…` | LC-banked 60K |
| `CPM60K.DSK` | 2.23 | 60K | `183aea80…` | 60K build |
| `CPM_60k_a.dsk` | 2.23 | 60K | `7eb33f1e…` | 60K two-disk set, disk A |
| `CPM_60k_b.dsk` | 2.23 | 60K | `2eba7da7…` | 60K set, disk B |
| `CPM_Z80SoftCard.dsk` | 2.2x | ? | `300ca93e…` | Explicitly "Z80SoftCard" |
| `CPM.DSK` | ? | ? | `af75e862…` | Generic stock SoftCard CP/M; inspect boot to confirm |
| `CPM_.DSK` | ? | ? | `ff83a4ca…` | Distinct from CPM.DSK |
| `CPM_Apple_CPM.dsk` | ? | ? | `a082fbd0…` | "Apple CPM" generic, disk A |
| `CPM_Apple_CPM._B.dsk` | ? | ? | `1c8e48f7…` | Disk B; `file` reads it as an Apple DOS 3.3 image - may be a DOS-side companion, verify |
| `DocProj_SoftCard_CPM_Sys2.2.cpm` | 2.2 | ? | `8ac3cf6e…` | Documentation Project system disk |
| `DocProj_SoftCard_Disk1.po` | 2.20B | 56K | `c2c24f49…` | = repo CPMV220-Disk1.po |
| `DocProj_SoftCard_Disk2.po` | 2.20B | 56K | `a70e4b13…` | Disk 2 of that set |
| `softcard.zip` | 2.2x | - | `b7b7662a…` | zip of `CPM1.PO` + `CPM2.PO` |

## PRIMARY collection zips (NOT yet downloaded - large)

| File | Size | Contents |
|---|---|---|
| `cpmdisks.zip` | 400K | CPM2.2(56k) + CPM2.23(60k) OS images + WordStar/SpellBinder app disks |
| `cpmdisks_vol_2.zip` | 667K | Versioned 60K build set: CPM60/61/66/76/83/84/85/86/87 A&B + CPM01A (early build); also CPM51A/B (= AE CP/AM, third-party) |
| `A2.CPM.COLLECTIONS.ZIP` | 2.4M | Nested `CPM.EMUCARD.ZIP` (= softcard.zip pair) + CPM226B (2.26 Premium IIe) + STARCPM/CPS/PCPI/ALS (third-party) |

URLs (asimov base `https://ftp.apple.asimov.net/images/cpm/os/`): `cpmdisks.zip`,
`cpmdisks_vol_2.zip`, `A2.CPM.COLLECTIONS.ZIP`.

## SECONDARY - later Microsoft cards (different hardware, not the original SoftCard)

| File | Version | Card | URL (asimov /images/cpm/os/) |
|---|---|---|---|
| `Microsoft Softcard II CPM 2.28B.DSK` | 2.28B | SoftCard II | `Microsoft%20Softcard%20II%20CPM%202.28B.DSK` |
| `Microsoft Premium Softcard IIe CPM - (Version 2.25)…DSK` | 2.25 | Premium SoftCard IIe | `Microsoft%20Premium%20Softcard%20IIe%20CPM%20-%20%28Version%202.25%29%282-189%20-%20101993%29%28Cat%202347%29%28Part%2023H47%29.DSK` |
| `softcardIIe.zip` (CPM226.dsk) | 2.26 | Premium SoftCard IIe | `softcardIIe.zip` |

## TANGENTIAL - third-party Z-80 cards / non-OS (NOT Microsoft SoftCard)

Applied Engineering CP/AM: `CPAM40B.dsk`, `CPAM51A.dsk`/`CPAM51B.dsk` (+`.SHK`),
`A.E. CPM Plus card.dsk`. ALS: `ALS CPM Card.zip`. PCPI Applicard: `pcpi/` (+`PCPI AppliCard.zip`).
Starcard: `STARCPM.DSK`, `Starcard - CPM Version 2.2 CP2-681-10107.DSK`. Franklin:
`FranklinCPM2.DSK`, `FranklinCPMUtilities.DSK`. CP/M 3.x ports: `CPM3.1_Z80_Softcard.zip`,
`apl2cpm3.zip`. Other: `CPM_ALDS.dsk` (Microsoft ALDS app that runs under CP/M),
`CPM_Zs_ETC.dsk`. All under `https://ftp.apple.asimov.net/images/cpm/os/`.

## Collection-zip contents (downloaded + extracted to `zips_extracted/`)

`cpmdisks.zip`, `cpmdisks_vol_2.zip`, `A2.CPM.COLLECTIONS.ZIP` pulled and unzipped
(nested zips too). **28 byte-distinct NEW disk images** beyond what we already held:

- **`cpmdisks_vol_2.zip` - the 60K-era SoftCard build series** (each a 140K `.dsk`, A&B sides):
  `CPM01A` (earliest), `CPM60A/B`, `CPM61A/B`, `CPM66A/B`, `CPM76A/B`, `CPM83A/B`,
  `CPM84A/B`, `CPM85A/B`, `CPM86A`, `CPM87A`. Build/revision lineage of the 60K system
  (the `83-87` suffixes look year-coded). **Also `CPM51A/B` = Applied Engineering CP/AM 5.1
  (third-party), not SoftCard.** Highest-value set for version archaeology.
- **`cpmdisks.zip`** - apps: `WordstarV3.3(CPM)`, `WordstarV4(CPM)`, `WordstarInstall(CPM)`,
  `SpellBinderCPM`. (Plus dups of `CPM2.2(56k)` / `CPM2.23(60k)`.)
- **`A2.CPM.COLLECTIONS.ZIP`** - third-party card images `CPSMULTIFUNCTION{DOS,Z80,PASC}.IMG`
  (CPS card) and `STARCPM.DSK/.IMG` (Starcard); the nested `CPM.EMUCARD.ZIP` = the
  `CPM1.PO`+`CPM2.PO` pair (**= the 56K 2.20B two-disk set we already have**). Plus a grab-bag
  of CP/M source/drivers and three notable text docs:
  - **`RE.MSOFT.SOFTCARD.SOFTSWITCH`** - 1998 Neil Parker Usenet post that **independently
    confirms our CPU-switch finding**: a write to slot ROM space `$Cn00-$CnFF` suspends the
    6502 and runs Z-80 code at Apple `$1000` (= Z-80 `$0000`); a second write toggles back;
    the original card has just a Z-80 and logic, no RAM/ROM; DIP switches all off; slot 4.
  - `Z80.CARD.INFO.TXT`, `CPM.CARD` - card-variant notes (original SoftCard / Premium IIe /
    "CATS Softcard"; the original has no DRAM, depends on the Apple for RAM+I/O).

## SoftCard utility / startup / language disks (second sweep)

The remembered `Softcard_Utilities/Diagnostics/Startup/Assembler/BASIC.dsk` names do **not**
exist verbatim anywhere; their real equivalents:

| Remembered name | Real disk | Have? | URL |
|---|---|---|---|
| Softcard_Utilities | `CPM_Apple_CPM.dsk` (FORMAT/COPY/CPM56/CPM60/APDOS/CONFIGIO) | yes | asimov `/cpm/os/CPM_Apple_CPM.dsk` |
| Softcard_Startup | `Microsoft SoftCard - CPM System Disk 2.2.cpm` / `Disk 1.po` | yes | Doc Project (downloaded) |
| Softcard_Assembler | `CPM_ALDS.dsk` (Microsoft Assembly Language Development System) | no | asimov `/cpm/os/CPM_ALDS.dsk` |
| Softcard_BASIC | `Microsoft SoftCard - CPM Disk 2.po` (MBASIC+GBASIC) / `CPM_Basic80.dsk` | Disk2 yes | Doc Project / asimov `/cpm/programming/CPM_Basic80.dsk` |
| Softcard_Diagnostics | (none standalone - diagnostics live on the bootable utility disks) | - | - |

**Microsoft SoftCard languages** (all `/cpm/programming/`, SoftCard-branded), not yet downloaded:
`CPM_Basic80.dsk` (MBASIC/BASIC-80), `CPM_Bascom.dsk` (BASIC Compiler), `CPM_COBOL-80_A/B.dsk`,
`CPM_Fortran80.dsk`. Non-Microsoft but SoftCard-runnable: muMATH/muSIMP/muLISP, Turbo Pascal,
Aztec C, C/80, FORTH, Pascal/MT, Pascal/Z, PL/I-80, A65, MUMPS. General CP/M apps (broad
category, sampled): WordStar, dBASE II, SuperCalc - all under `/cpm/productivity/`.

Sibling card: `Microsoft Premium Softcard IIe - CPM 2.26b (ProDOS files).dsk` (Doc Project).

## SoftCard manuals & schematics (downloaded -> `softcard-manuals/`)

From the apple2.org.za Apple II Documentation Project SoftCard tree. **Directly relevant to
the open hardware question** (how a physical Videoterm releases the `$C800` window during the
SoftCard's `$C700` CPU switch):

| File | Bytes | Why it matters |
|---|---|---|
| `Microsoft_SoftCard_-_Software_and_Hardware_Details.pdf` | 304024 | Z-80 board + `$C0xx` switching + BIOS internals |
| `Microsoft_Softcard_rev._E_-_Schematic.png` | 467889 | rev E board schematic - the bus/decode logic |
| `Microsoft_Softcard_-_Schematics.gif` | 320746 | schematic (alt) |
| `Microsoft_SoftCard_-_CPM_Reference_Manual.pdf` | 1222189 | full CP/M reference |
| `Microsoft_SoftCard_-_Software_Utilities_Manual.pdf` | 251040 | FORMAT/COPY/CONFIGIO/MASTER utilities |
| `Microsoft_SoftCard_-_Volume_1.pdf` / `_Volume_2.pdf` | 400287 / 1105946 | manual set |

## SoftCard language / dev-tool disks (downloaded -> `languages/`)

| File | Product | Bytes |
|---|---|---|
| `CPM_Basic80.dsk` | Microsoft BASIC-80 (MBASIC) | 143360 |
| `CPM_Bascom.dsk` | Microsoft BASIC Compiler (BASCOM) | 143360 |
| `CPM_COBOL-80_A.dsk` / `_B.dsk` | Microsoft COBOL-80 (2 disks) | 143360 |
| `CPM_Fortran80.dsk` | Microsoft FORTRAN-80 | 143360 |
| `CPM_ALDS.dsk` | Microsoft Assembly Language Development System | 143360 |

(MBASIC + GBASIC also ship on the SoftCard distribution `Disk 2.po`, already held.)

## Datasheets (-> `datasheets/`) and Photos (-> `photos/`)

- `datasheets/Zilog_Z80_-_Product_Specification.pdf` - the Z-80 CPU datasheet.
- `photos/Microsoft_SoftCard_v1_-_Front.jpg`, `..._v2_-_Front.JPG`, `..._v2_-_Back.JPG`
  (board photos - v2 front/back may help read the bus logic alongside the schematic),
  `..._-_Ad_1.jpg`, `..._-_Ad_2.jpg` (period ads).

## Still to gather for a complete Microsoft-SoftCard archive

- Secondary Microsoft cards (OS images identified, not yet downloaded): SoftCard II 2.28B,
  Premium SoftCard IIe 2.25, `softcardIIe.zip` (2.26).
- The Documentation Project trees for **Premium SoftCard IIe** and (if present) **SoftCard II**
  (their own Disk Images / Manuals / Schematics / Datasheets / Photos).

## Open analysis (artifacts now in hand)

- **Physical `$C800`-window release** (the one open hardware question): the
  `Software_and_Hardware_Details.pdf` and `rev. E` schematic are SCANNED images (no embedded
  text); analyze by page-render / image view. The v2 board photos may corroborate.
- **Language Card on 2.20**: settle empirically with the real 44K `Cpmv22_44k.dsk` vs the 56K dumps.
