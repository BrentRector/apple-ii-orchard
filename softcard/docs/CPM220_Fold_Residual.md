# 2.20 fold — the non-uniform-relocation residual (SystemImage)

The 2.20 OS image relocates 44K→56K by a **uniform +$3000** for the vast bulk
of its in-image address operands (CCP/BDOS/BIOS all shift together: CCP
$9400→$C400, BDOS $9C00→$CC00, BIOS $AA00→$DA00). Those become **label
references** in the relocatable source and the assembler resolves them at each
ORG — no per-byte handling needed.

Measured on the **pure-config** pair (2.20B-44K vs 2.20B-56K staging, same
version): **1001 bytes are the +$30 uniform shift; only 6 bytes fall outside
it.** Brent's hypothesis was that those 6 are also (partial) addresses, not
arbitrary config constants. Decoding the instruction each sits in, in BOTH
configs, **confirms it for most of them** — they are address operands pointing at
config-specific structures (which is why they don't ride the uniform +$3000):

| addr | instr (2.20B-44K → 56K) | kind | what it references |
|------|--------------------------|------|--------------------|
| `$94AE` | `lda #$A4` → `lda #$E4` (6502) | **ADDRESS** | high byte of the embedded-6502 warm-boot disk-load **buffer** `$03E8/$03E9` = `$A400`(44K)/`$E400`(56K). +$4000. |
| `$A3D5/$A3D6` | `LD HL,$9400` → `LD HL,$D6DF` | **ADDRESS** | a config-specific **reload/patch helper**: 44K targets the 6502 RPC block (`$9400`); 56K targets a Z-80 helper at `$D6DF` (`LD A,($D9E3);ADD A,C;LD (HL),A;LD A,($D9E1);LD (HL),A;RET`). Different code per config, so a config symbol, not a uniform shift. |
| `$97B2` | `AND $01` → `AND $03` (`E6 nn`) | **CONSTANT** | a mask on a counter (`LD A,E;INC E;…;AND mask`). `$01`/`$03` = mod-2 / mod-4. Genuinely a config constant, not an address. |
| `$952D` | (`LD D,$DF` region) | VERSION+config | inside the 2.20-vs-2.20B functional-change block (see below); the config part is entangled with the version edit. |
| `$9E05` | duplicate of `$952D` | VERSION+config | same value stored a second time. |

**Verdict on the hypothesis:** correct for the addresses — `$94AE` and
`$A3D5/$A3D6` are address operands and should be **config symbols/labels**, not
magic bytes. `$97B2` is a real config constant (a mask). `$952D/$9E05` belong to
the version delta, not the config delta.

## Version (2.20 vs 2.20B) residual — separate axis

Comparing 2.20-44K vs 2.20B-44K (same config, pure version) the SystemImage
delta is tiny and localized to ~`$952C`/`$9E04`:
- 2.20-44K `$952C/$952D` = `16 DF` (`LD D,$DF`); 2.20B-44K = `B6 16`.
  This is the documented 2.20→2.20B functional edit, mirrored at `$9E04`.

## CORRECTION (verified): "REV_B edit" was the serial number; only 3 config items

Decoding each residual in both configs (per Brent's push to label, not magic-byte,
them) overturned two earlier guesses:

- **`$952C/D` and `$9E04/5` are the CP/M SERIAL NUMBER, not a 2.20→2.20B code
  edit.** `$9528` and `$9E00` both hold `BD 16 00` (the CP/M serial product
  marker) + a 3-byte per-copy unit; the differing bytes are that unit. The
  serial is stored twice (once in the CCP, once in the BDOS). The **entire**
  pure-version delta (2.20-44K vs 2.20B-44K) in the SystemImage is exactly these
  4 bytes — i.e. **there is NO functional REV_B edit in CCP+BDOS**; 2.20 vs 2.20B
  differ only by serial here. (The real REV_B *code* change lives in the BIOS/
  boot loader, to be found there.) The serial is the per-copy axis, already a
  reconstruct parameter — not config and not version.
- Because the 2.20B-44K and 2.20B-56K disks are different licensed copies, the
  serial also differs between them, which is why `$952D/$9E05` showed up in the
  raw "config" diff. They are serial, not config.

So the genuine config (44K↔56K) residual is just **3 items**:
- `$94AE` — **address**: warm-boot load-buffer high byte (`$A400`/`$E400`).
- `$A3D5/6` — **address**: `LD HL,RELOAD_HELPER` (`$9400`/`$D6DF`; 44K targets the
  6502 block, 56K a Z-80 helper).
- `$97B2` — **constant**: an `AND` mask in the drive-letter/directory display
  routine (`…ADD A,$41`→letter; print letter+":"). `$03` = mod-4 (standard CP/M
  4-per-line), `$01` = mod-2. The one true config constant; exact rationale for
  the 44K/56K difference unconfirmed.

Two of the three are addresses (Brent's hypothesis); one is a real config
constant.

## DEFW-table relocatability — two classes (and why phase 2 is the real test)

The remaining ~81 un-relocated bytes are pointer tables the clean-room decompile
decoded as *code* (e.g. `$95C2` dispatch, the `$9E47` table). Pushing on these
surfaced two structural facts:

1. **Odd-byte alignment + mixed targets** — `$9E47` is a 2-byte pointer table at
   ODD alignment (words at `$9E47,$9E49,…`); the analyzer's pointer-table
   heuristic does not fire on it (simply marking the range as data left it MIXED
   `DEFB` and even nudged GATE2 up). These need **explicit per-table
   `pointer_words`** (per-table RE: alignment, extent, in-range entries), not a
   blanket reclassify.
2. **Cross-region (BIOS) entries can't relocate in-source** — many table entries
   point at the BIOS (`$AA03`→`$DA03`, +$3000), but `$AAxx` is just past the
   SystemImage's own `$9300-$A9FF` range, so there is no in-source label to bind.
   They relocate correctly only in the **CPM56.asm whole-system assembly**
   (phase 2), where the BIOS module's labels exist.

**So a standalone SystemImage GATE2=0 is partly not achievable by design.** The
in-image pointers can be DEFW-labelled in the SystemImage; the BIOS-pointing ones
must wait for phase 2. The authoritative relocation test is **CPM56.COM
byte-identical**, not the standalone-SystemImage GATE2 proxy.

## Refined fold model

The 44K↔56K config delta is **~99.4% uniform +$3000** (1001/1007 bytes → labels),
plus a **handful of config-specific symbols** for structures whose placement (or
implementation) differs between the 44K main-RAM build and the 56K language-card
build:
- `WARMBOOT_BUF` = `$A400` / `$E400`  (used as `>WARMBOOT_BUF` in the 6502 block)
- `RELOAD_HELPER` = `$9400` / `$D6DF`  (the `LD HL,…` at `$A3D4`)
- `CFG_MASK` = `$01` / `$03`  (the `AND` at `$97B1`)

So the plan's premise ("config 44K↔56K is essentially pure relocation, not LC
code blocks") holds — there are **no inserted LC code blocks**, only ~3
config-specific addresses/constants plus the uniform shift. Those three become
named config conditionals; everything else is a relocatable label. The 2.20-vs-
2.20B (REV_B) edit at `$952C`/`$9E04` is the separate sub-version axis.

Method: `softcard/cpm-investigation/reloc_probe.py` (uniform-relocation gate) +
direct staging extraction and instruction decode of the three archive disks
(2.20-44K, 2.20B-44K, 2.20B-56K; canonical 56K = `…-disk1.po` == `sysimg_220.bin`).
