# Resume Prompt — Microsoft SoftCard CP/M Investigation

**Last updated:** 2026-04-29 (10 articles + 31 devlogs + new disk-sector map reference. Part 10 "The CPU Switch, and What's Left" published 2026-04-30 closing the series. Today's additions: factual byte-level trace of the v2.20 hang in `cpm-videx-220-hang-byte-trace-2026-04-29` — dispatch-path through handler `$DFBE` to `CALL $DAC5` (in runtime-generator zone), with two failure modes both consistent with the observed hang; `docs/CPM_DiskSectorMap.md` 560-row sector reference; companion reference page on wiseowl.com.)

This file is the canonical session-recovery prompt for the Microsoft SoftCard CP/M reverse-engineering project. **If this conversation crashes or context is lost, hand this file to a fresh assistant and it should be able to pick up exactly where we left off without losing any directives, conventions, or progress.**

---

## The Project (the durable goal)

Reverse-engineer Microsoft's Apple ][ Z-80 SoftCard CP/M completely — both **2.20** (which fails to boot when a Videx Videoterm 80-column card is installed) and **2.23** (which boots and runs cleanly with the same hardware). The ultimate deliverable is:

1. A complete description and disassembly of CP/M 2.20 and 2.23, starting at the boot sector (6502 code) and continuing through the SoftCard switch into Z-80 mode.
2. Z-80 disassembly of the entire CP/M system (CCP + BDOS + BIOS) for both versions.
3. A narrative that walks the reader from power-on to the `A>` command prompt, with full understanding of every step and the differences between the two versions.

The project is hosted on:
- **Code/disasm repo:** [Orchard](https://github.com/BrentRector/orchard) at `e:/Orchard/` — investigation scripts, intermediate artifacts, annotated disassembly files, source disk images
- **Personal site (publishing):** [wiseowl.com](https://wiseowl.com) at `e:/Sites/wiseowl.com/` — public-facing project entry, articles, devlogs, references. NOT the same as wiseowlsoftware.com (the separate Demeanor product site).

---

## Origin Story

Joshua Norrid (of A2FPGA fame) reported that Microsoft SoftCard CP/M wasn't booting with the A2FPGA Videx Videoterm emulation. He confirmed the same failure on real Videx hardware — so the emulation is faithful, the OS is what's broken. Brent (the user/author) doesn't yet have a physical Microsoft Z-80 SoftCard ("supposedly in the mail") so all analysis is static disassembly; Joshua's hardware confirms predictions when needed.

Version testing isolated the boundary: **2.20 and 2.20B fail; 2.23 works**.

---

## What's Now Understood (the architecture)

After the investigation through 2026-04-27, the SoftCard CP/M boot sequence is understood end-to-end up to the SoftCard handoff. After the handoff, half of it is also understood; the other half (runtime BIOS code generation) is the current frontier.

### The 6502 boot stage (Parts 1-2 of the article series cover this)

1. **Disk II P6 PROM** loads sector 0 of track 0 to Apple `$0800-$08FF` and `JSR $0801`.
2. **Boot stub** at `$0801-$083C` (byte-identical between 2.20 and 2.23) uses the P6 PROM's mid-routine entry at `$Cn5C` to load 10 more sectors of track 0 in CP/M skew order (`0,2,4,6,8,A,C,E,1,3,5`) into Apple `$0A00-$1300`. Then `JMP $1000`.
3. **Stage-2 loader** at `$1000` enables the language card RAM, calls Apple monitor TEXT/SETVID/SETKBD, runs three install loops staging Z-80 code into low Apple memory (`$0FFF`, `$0200-$02FF`, `$0300-$03FF`), then runs the **slot scanner** at `$1060-$10D5`.
4. **Slot scanner** walks slots 7 → 1, probes Pascal-firmware ID bytes at `$Cn05/$Cn07`, records device codes at Apple `$03B9-$03BF`. **2.23 added an 11-byte branch** that also reads `$Cn0B` (Pascal 1.1 signature byte) and tags Pascal-1.1 cards with new device code `$06` instead of `$04`. This is the Videx-detection delta (Part 1's discovery).
5. **LOAD_CPM** at Apple `$0BEB` (= `$BBEB` after PREP_HANDOFF copy) reads 29 sectors starting trk0:`$0B`, sequentially through trk1:`$00-$0F` and trk2:`$00-$07`, into Apple `$8000-$9CFF`.
6. **PREP_HANDOFF** does three page copies:
   - `$0A00-$0FFF` (original 6502 disk routines) → `$BA00-$BFFF` (preservation)
   - `$9700-$9CFF` (last 6 pages of LOAD_CPM staging) → `$0A00-$0FFF` (Z-80 disk callbacks + first 1 KB of BIOS)
   - `$8000-$96FF` (first 23 pages of LOAD_CPM staging) → `$A300-$B9FF` (CCP + BDOS + boot banner)
7. **Z-80 reset vector planted**: 6502 writes `$C3 $00 $FA` (= Z-80 `JP $FA00`) at Apple `$1000-$1002`. Apple `$1000` is Z-80 `$0000` under the SoftCard's bit-12 XOR mapping. So the Z-80's first instruction will jump to its BIOS cold-boot at `$FA00`. (2.20 plants `JP $DA00` consistent with its BIOS at `$DACC`.)
8. **Apple monitor reset vectors patched** at `$FFFA-$FFFF`, then `JMP $03D2` into the warm-boot routine that was installed at `$03C0`.
9. **Warm-boot routine at Apple `$03C0`** loops: enable LC RAM, touch `$Cn00` (self-modified), disable LC RAM, `JSR $0E36`. The `JSR $0E36` jumps into the now-installed Z-80 disk callbacks (which are nonsense as 6502). **The SoftCard CPU switch fires somewhere in this transition** — the 6502 loader has NO direct `$C0Bx` writes; the trigger is either a memory-access pattern the SoftCard hardware monitors silently, or in CB/DD/ED/FD prefix instructions our Z-80 disassembler doesn't yet decode.

### The Z-80 side (Parts 3-4 covered the architecture; the runtime BIOS-factory algorithm is open)

10. **Z-80 starts at `$0000`** (= Apple `$1000`), reads `JP $FA00`, jumps to BIOS cold-boot. Note: `$FA00` is in a runtime-generated zone — see below for who populates it.
11. **CP/M BIOS jump table** at the BIOS base (2.23: `$FAB8`, 2.20: `$DACC`). Standard 15-entry CP/M layout. **BOOT vector**: 2.23 → `$FED1`, 2.20 → `$DEA8`. Both BOOT targets land in runtime-generated regions.
12. **BIOS layout is 256-byte interleaved**, not "first half / second half." Both versions: 4 code pages alternating with 4 runtime-generated pages. 2.20 fills generator slots with `$E5` (CP/M deleted-file marker, also `PUSH HL`); 2.23 uses `FF FF 00 00 / F7 F7 00 00` (`RST` traps if executed prematurely — a safety upgrade).
13. **Cold-boot real code resumes at `$DECC` (2.20) / `$FF0E` (2.23)** — after the runtime-generated padding/slide that the BOOT vector lands in. The post-padding code is structurally identical across versions: a 9-entry device-scan loop reading from the slot-info table at `$F3A0`. The fix between 2.20 and 2.23 is NOT in the BIOS device-scan; both versions have the same scan logic.
14. **Cold-boot also sets up architectural fixed points** (observed at `$FB70` in 2.23, but `$FB70` is the LIST jump-table entry — its presence in the cold-boot path is not yet fully resolved; either runtime generation rewrites the LIST entry, or `$FB70` is a helper called from BOOT). Setup includes: Z-80 stack at `$0080`, BDOS call vector at `$0005` (= `JP $9C06` in 2.23, `JP $CC06` in 2.20 — 12 KB shift), Z-80 reset vector rewritten from `JP $FA00` to `JP $FA03`.
15. **CCP, BDOS, and BIOS first 1 KB** are loaded by LOAD_CPM. Final addresses:
    - CCP+BDOS staged at Apple `$A300-$B9FF` (5.9 KB; tail bytes are the boot banner string `Softcard CP/M / 60K Ver. 2.23 / (c) 1980,1982 Microsoft`). **Some still-untraced step relocates this to the standard CP/M position around `$9406-$9C06`** before cold-boot — confirmed by the cold-boot routine planting `JP $9C06` (a BDOS-area address) at the BDOS call vector.
    - BIOS first 1 KB at Apple `$0C00-$0FFF` initially; some still-untraced step copies it to LC RAM for Z-80 to use.
16. **The runtime-generated regions get populated by an unidentified mechanism** before the Z-80 first executes BOOT. Since BOOT itself lands in a runtime-generated region, the 6502 loader (or the SoftCard hardware) must populate those bytes before triggering the CPU switch. Open question.
17. **Cooperative-CPU disk I/O model**: When CP/M needs disk, the Z-80 BIOS routines write parameters into the BIOS state area, call into the Z-80 disk callbacks at `$1A00`, which signal the 6502 via the `$E000`/`$E010` flag pair (polling loop at Z-80 `$1E36-$1E44`). SoftCard hardware switches CPUs. 6502 reads the same state from the same Apple addresses, runs the original RWTS routines preserved at Apple `$BA00-$BFFF`, deposits sector data at the DMA address, signals completion. SoftCard switches back. Z-80 returns from callback.

**Important corrections logged on 2026-04-28:**
- Earlier devlogs (`cpm-videx-cold-boot-found-2026-04-27`, `cpm-videx-220-vs-223-coldboot-2026-04-28`) confused the LIST jump-table entry with BOOT. Forward-pointer Update notes added per the standing "don't rewrite, add corrections" directive. New devlog: `cpm-videx-bios-jump-table-correction-2026-04-28`.
- The "first 1 KB populated, second 1 KB all-zero" framing in `cpm-videx-bios-runtime-generated-2026-04-27` is too coarse; layout is 256-byte interleaved. Update note added.
- The 2.20 "inline init" claim (`CALL $DD8E / LD A,$01 / LD ($E5B2),A`) was wrong — `$DD8E` is SETDMA per the 2.20 jump table, not an init helper. The "2.20 inline / 2.23 runtime-gen" thesis still likely holds in some form, but needs re-derivation from correct BOOT entry points.

### The Pascal 1.0 vs 1.1 calling convention precision (Part 1's full payoff)

- **Pascal 1.0**: ID bytes ARE the entry points. `$Cn05 = $38` is the `SEC` opcode; `$Cn07 = $18` is `CLC`. `JSR $Cn05` does input (carry set), `JSR $Cn07` does output (carry clear). Both fall through to common dispatch using the carry flag.
- **Pascal 1.1**: 4-byte vector table at `$Cn0D-$Cn10` (INIT, READ, WRITE, STATUS — each a single-byte offset). Caller reads offsets, JSRs to `$Cn00 + offset`, MUST call INIT before READ/WRITE/STATUS.
- A Pascal 1.1 card can be backward-compatible at the byte level (the Videx is — `$CB05`/`$CB07` are real `SEC`/`CLC`), but its 1.0-style dispatch typically requires the V flag to be set by an upstream `BIT IORTS` at `$Cn00` during the V-setting preamble. PR#n / COUT-via-CSW sets that up correctly; a naive `JSR $Cn07` does not.
- **CP/M 2.20 sees a Videx, sees Pascal 1.0 ID bytes, does naive `JSR $Cn07`, lands in dispatch code with uninitialized state → hangs.** CP/M 2.23 reads `$Cn0B`, sees Pascal 1.1, routes through the Pascal 1.1 vector table. That's the entire bug fix.

### The BIOS factory mental model (Part 4's contribution)

The static disk image doesn't contain the complete runtime BIOS. It contains a *partial* BIOS plus a code generator that fills in 4 of the 8 256-byte pages of BIOS address space at boot. Both 2.20 and 2.23 use the same factory pattern. The fix between versions is NOT in the factory itself — the BIOS device-scan loop is structurally identical between 2.20 and 2.23 (verified by direct disassembly diff on 2026-04-28). The fix lives in the *boot-time slot scanner* (the 11-byte Pascal 1.1 detection branch in the 6502 loader), which determines which device codes get written into the table the BIOS factory consumes. So 2.20 was already capable of handling additional device types — it just never produced the right device code for a Videx because the loader couldn't detect it as Pascal 1.1.

---

## Decision Points and User Directives

These are the user's explicit choices that future sessions need to respect:

- **Investigation path: Path A chosen** (reverse-engineer LOAD_CPM rather than build a Z-80 emulator). Reasoning: story coherence, unlocks both versions, no tooling tangent.
- **Article structure**: multi-part series, each part covers a distinct phase. **Part 4 is now published**; planned Parts 5-7 cover the remaining work.
- **Each part should be a beginning-to-end narrative** that reads as a story (per user's explicit Part 2 framing direction).
- **Devlog granularity**: one per topic / approach / area of investigation, NOT one per day. When trying a different angle = new entry, even on the same day.
- **Resume-prompt.md kept current** at all times (this file). Update after each significant step.
- **Site placement**: wiseowl.com personal site (NOT wiseowlsoftware.com which is the Demeanor product site).
- **Article 1 framing**: opens with "The Microsoft Z-80 SoftCard wouldn't work with my Videx 80-column emulation. Seemingly." (the user explicitly directed this hook).
- **6502 and Z-80 disassemblers**: documented as separate tools on wiseowl.com (not bundled under nibbler), even though they share repo home in `nibbler/`.
- **The disassemblers are general-purpose**: `nibbler disasm` is a 6502 disassembler; `nibbler z80disasm` is a Z-80 disassembler. Independent reusable tools.

---

## Editorial Guidance (saved to memory; restated here)

- **Lead with consequence, not detection.** The act of finding a code delta is the door, not the room. Pivot quickly to behavioral consequence — what the system does differently because of the change.
- **State things clearly, not cleverly.** Cryptic article titles bad; descriptive ones good. ("The Eleven Bytes That Recognize a Videx" was renamed to "Why Microsoft CP/M Didn't Recognize an 80-Column Card" after user feedback.)
- **Honesty over completeness.** When something is inferred but not verified from disassembly, say so explicitly. Distinguish "known from reading the code" from "plausible hypothesis pending verification." Other LLMs have over-claimed and the user noticed.
- **Don't conflate shared address spaces with specific cards.** `$C800-$CFFF` is the Apple ][ shared expansion-ROM window — any slot card uses it. Seeing `LD HL,$C800` in the BIOS proves expansion-ROM-aware, NOT Videx-aware. (User caught a Videx overreach on this.)
- **Corrections, not rewrites.** When later findings contradict or refine earlier devlogs/articles, ADD a brief `**Update (YYYY-MM-DD):**` note at the end pointing forward to the corrected finding. Do NOT silently rewrite the body. The misinterpretation is part of the investigation narrative — readers following the chronology should see what was thought at the time and how it was corrected. (User explicit directive 2026-04-27.)
- **Voice for devlogs**: terse, declarative, past tense, NO first-person pronouns ("Loaded the WOZ image" not "I loaded"). Em dashes for asides. ~200-400 words. End with a `**Status:**` line.
- **Voice for articles**: long-form (~3000 words, 12-15 min reads), first-person ALLOWED and natural, rich technical context, references images/links.

---

## Website Structure

The site at `e:/Sites/wiseowl.com/` is Astro v6, deployed to Cloudflare Pages.

### Project entry
`src/content/projects/cpm-videx.mdx` — Title "Microsoft SoftCard CP/M on a Videx", `featured: true, weight: 5`. Contains the article roadmap. **Update this when the roadmap evolves.**

### Articles (`src/content/articles/cpm-videx-NN-*.mdx`)

Series complete (10 parts published; Part 10 closes the series). Two articles renumbered between drafts so titles ≠ slugs in some cases — see filenames for canonical mapping.

- ✅ **Part 1**: `cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card.mdx` — Pascal 1.0 vs 1.1 detection delta
- ✅ **Part 2**: `cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction.mdx` — 6502 boot stage narrative
- ✅ **Part 3**: `cpm-videx-03-apple-memory-through-z-80-eyes.mdx` — SoftCard memory model, BIOS architecture
- ✅ **Part 4**: `cpm-videx-04-the-handoff.mdx` — 6502→Z-80 handoff (renumbered)
- ✅ **Part 5**: `cpm-videx-05-the-bios-that-half-exists.mdx` — LOAD_CPM, staging splits, runtime BIOS generation
- ✅ **Part 6**: `cpm-videx-06-the-bios-factory.mdx` — Cold-boot code generator, device-6 dispatch
- ✅ **Part 7**: `cpm-videx-07-from-reset-to-device-scan.mdx` — Z-80 BIOS cold-boot, device-scan loop
- ✅ **Part 8**: `cpm-videx-08-cooperative-cpu.mdx` — Cooperative-CPU round-trip, $1E39 polling loop, **v2.20 hang factual trace** (Update note added 2026-04-29)
- ✅ **Part 9**: `cpm-videx-09-every-difference.mdx` — Categorical inventory of 2.20 vs 2.23 changes
- ✅ **Part 10**: `cpm-videx-10-the-cpu-switch.mdx` — `JSR $0E36` SoftCard CPU-switch trigger; series close

### Dev logs (`src/content/devlogs/cpm-videx-*.mdx`)

31 entries published. Authoritative list is the result of `ls e:/Sites/wiseowl.com/src/content/devlogs/cpm-videx-*` — too many to enumerate here verbatim, but most recent topical highlights:

- `cpm-videx-220-hang-byte-trace-2026-04-29` — **factual byte-level trace of the v2.20 hang** (today; documents the dispatch path through `$DFBE → CALL $DAC5` and two failure modes)
- `cpm-videx-cpu-switch-trigger-2026-04-30` — `JSR $0E36` mechanism details
- `cpm-videx-220-also-has-second-load-2026-04-29` — second LOAD_CPM call in 2.20
- `cpm-videx-220-dispatch-table-2026-04-29` — 2.20's 6-entry dispatch table at `$DAFF`
- `cpm-videx-loader-wide-diff-2026-04-29` — wide-diff scan of 2.20 vs 2.23 loaders
- `cpm-videx-embedded-z80-fragment-2026-04-29` — 270-byte Z-80 fragment in 6502 loader at `$143A`
- `cpm-videx-second-load-cpm-call-2026-04-28` — second LOAD_CPM call resolves CCP+BDOS relocation
- `cpm-videx-static-vs-generated-handlers-2026-04-28` — runtime vs static handler split
- `cpm-videx-cold-boot-generator-found-2026-04-28` — cold-boot generator at `$FB3A` (2.23) / `$DB6E` (2.20)
- `cpm-videx-fdb0-stub-2026-04-28` — `$FDB0` is just a `RET` stub
- `cpm-videx-device-scan-identical-2026-04-28` — BIOS device-scan loop is identical across versions
- `cpm-videx-bios-jump-table-correction-2026-04-28` — corrects BOOT-vs-LIST confusion in earlier devlogs
- `cpm-videx-disk-sectors-past-load-cpm-2026-04-28` — what's at trk2:$08+ (zeros) and beyond
- `cpm-videx-2-0-vs-2-2-version-bump-2026-04-28` — wider context: CP/M 2.0→2.2 base under the Videx fix
- (Plus 17 earlier entries — see `ls cpm-videx-*` for the full chronological sequence.)

### Reference (`src/content/reference/`)
- `apple-ii-tn-misc-8-pascal-1-1-firmware-protocol.mdx` — full text of Apple Tech Note Misc #8 (the only canonical Pascal protocol document)
- `cpm-videx-disk-sector-map.mdx` — pointer to the 560-row disk-sector map at `docs/CPM_DiskSectorMap.md` in the Orchard repo (the natural capstone of the investigation)
- Source PDF at `public/reference/apple-ii-technical-notes-1989-09.pdf`

### Tools (`src/content/tools/`)
- `nibbler.mdx` — WOZ analysis toolkit
- `6502-disassembler.mdx` — standalone 6502 disasm tool entry
- `z80-disassembler.mdx` — standalone Z-80 disasm tool entry

### Frontmatter constraints (build will fail if violated)
- Devlog `tldr` ≤ 200 chars
- Article `description` ≤ 300 chars
- Project `summary` ≤ 300 chars
- `tags` from `TagEnum` only (in `src/content.config.ts`); add new tags to enum BEFORE using
- Numeric-prefix tags (`6502`) MUST be quoted as `"6502"` in YAML block-style arrays (else parsed as integer, fails enum validation)

### Build / deploy
- Local build: `npm run build`
- Build + deploy to Cloudflare Pages: `npm run deploy` (= `astro build && wrangler pages deploy dist --project-name wiseowl`)
- Wrangler is globally installed; uses Brent's existing auth.

### Site wordmark
- Header reads "Wise Owl — Brent Rector" (NOT "Wise Owl Software" — that's the separate product site).

---

## Repository Conventions

### Orchard repo (`e:/Orchard/`)

```
cpm-investigation/        — extraction scripts, intermediate binaries, disassemblies
  reconstruct_staging.py    — replays LOAD_CPM against .DSK to extract sysimg/newdisk
  loader_223.bin            — 3 KB Apple [0x0800-0x13FF] memory image of 2.23 boot loader
  loader_220.bin            — same for 2.20
  bios_223.bin              — 2 KB at .DSK file offset 0x2400 (BIOS jump table area)
  bios_220.bin              — same for 2.20
  staging_223.bin           — 7424 bytes simulating LOAD_CPM staging at $8000-$9CFF
  staging_220.bin           — same for 2.20
  sysimg_223.bin            — 5888 bytes (CCP+BDOS+banner, lands at Apple $A300)
  sysimg_220.bin            — same for 2.20
  newdisk_223.bin           — 1536 bytes (Z-80 callbacks + BIOS first 1 KB, lands at Apple $0A00)
  newdisk_220.bin           — same for 2.20
  bios_223_second.bin       — confirmed-zero trk2:$08-$0B sectors
  bios_full_first.bin       — staged $FA00-$FEB7 BIOS area (cold-boot region + populated 1 KB)
  disasm_223_linear.txt     — full 6502 linear disassembly of the loader image
  disasm_220_linear.txt     — same for 2.20

docs/
  CPM_Videx_Difference.md   — slot scanner side-by-side diff with symbolic names
  CPM_BootLoader.md         — narrative architecture of the 6502 loader
  CPM223_BootLoader.asm     — annotated 6502 disassembly (sections complete through $11AF)
  DiskII_BootROM.md         — Apple Disk II P6 PROM doc (pre-existing)
  DiskII_BootROM.asm        — Apple Disk II P6 PROM disasm (pre-existing)

nibbler/                  — Apple ][ disk analysis toolkit
  z80.py                    — Z-80 disassembler (256 unprefixed; CB/DD/ED/FD are stubs)
  cli.py                    — has both `disasm` (6502) and `z80disasm` subcommands

CPMV233.DSK               — CP/M 2.23 disk image (DOS 3.3 sector order — despite name, V233 is a misnomer for 2.23)
CPM220Disk1.po            — CP/M 2.20 distribution disk 1 (ProDOS sector order)
CPM220Disk2.po            — CP/M 2.20 distribution disk 2

resume-prompt.md          — THIS FILE
```

### Build/deploy
- Orchard: standard git workflow; no build needed.
- wiseowl.com: see "Build / deploy" above.

---

## Memory Directory

`C:/Users/brent/.claude/projects/e--Orchard/memory/` contains semantic project memory loaded automatically into future sessions:
- `MEMORY.md` — the index (auto-loaded on every session)
- `project_cpm_videx_investigation.md` — investigation status, findings, open questions
- `reference_apple_pascal_firmware_protocol.md` — Pascal 1.1 protocol with calling-convention details and Tech Note Misc #8 reference
- `reference_wiseowl_devlogs.md` — devlog conventions, schema, voice
- `feedback_finding_vs_consequence.md` — editorial: don't celebrate detection; pivot to consequence
- `feedback_apple_ii_address_specificity.md` — editorial: don't conflate shared address spaces with specific cards
- `feedback_devlog_corrections.md` — editorial: when later findings refine earlier ones, add forward-pointer Update notes; don't silently rewrite

---

## Concrete Next Steps When Resuming

The series is closed (Part 10 published). The investigation has reached a clean stopping point. Three open items remain, all bounded:

1. **Verify the v2.20 hang's actual failure mode (Case A vs Case B).** The factual byte-trace devlog (`cpm-videx-220-hang-byte-trace-2026-04-29`) documents two static-evidence-consistent failure modes: (A) 6502 hung inside Videx ROM after naive `JSR $C307` skips the V-flag preamble, with Z-80 polling forever; (B) Z-80 stack overflow on `$E5` (`PUSH HL`) spam from runtime-generator slot. Distinguishing requires Z-80 emulator boot of 2.20 with Videx in slot 3 and dumping memory at `$DAC5+`. Either way the system hangs, so the answer to "why does 2.20 hang" is settled at the granularity that matters; this is just the final byte of confirmation.

2. **Initial population of `$FA00-$FAB7`** (the cold-boot prelude before the BIOS jump table). At static disk read time, this region is zero/data. Something populates it with executable cold-boot code before Z-80 first runs. Candidates: 6502 loader writes via SoftCard XOR map; SoftCard built-in ROM overlay on first boot. Resolution requires booting in a Z-80 emulator and reading memory.

3. **Runtime population of trap-marker pages with handler code.** The 256-byte interleaved BIOS layout has 4 code pages and 4 generator pages (filled with `$E5` in 2.20 / `FF FF 00 00 / F7 F7 00 00` in 2.23 statically). Strong candidate sectors for the source bytes were identified in the disk-sector map but the runtime-population step itself isn't fully traced.

### Side tasks (lower priority but worth noting)

- 2.20 and 2.23 sysimg files (CCP+BDOS) should be diffed — the bulk should be byte-identical (same Digital Research code), confirming our extraction is correct. Any differences would be Microsoft-side modifications worth investigating.
- The `$F3xx` area (Apple TPA region) is referenced heavily by both Z-80 callbacks and BIOS code (`$F3B8`, `$F3D0`, `$F3DE`, `$F3A1`, `$F397`). It's a per-system-state area. Documenting what each `$F3xx` byte means would clarify many references.
- Add CB/DD/ED/FD prefix decoding to `z80disasm`. The disassembler currently stubs prefix-byte instructions. Block instructions (LDIR, LDDR) and IX/IY-indexed are likely used in code-generation paths we haven't fully seen.
- Continue updating this resume-prompt.md after each significant step.

---

## Quick-Reference Address Map (for fast context recovery)

### Apple ][ memory after the loader finishes
- `$0800-$08FF`: boot stub (sector 0)
- `$0A00-$0FFF`: Z-80 disk callbacks + BIOS first 1 KB (depending on version layout)
  - 2.20: BIOS first 1 KB at `$0A00-$0DFF`, callbacks at `$0E00-$0FFF`
  - 2.23: callbacks at `$0A00-$0BFF`, BIOS first 1 KB at `$0C00-$0FFF`
- `$1000-$1002`: Z-80 reset vector (`$C3 $00 $FA` for 2.23, `$C3 $00 $DA` for 2.20)
- `$0200-$03FF`: Z-80 install fragments (the warm-boot routine at $03C0 lives here)
- `$03B9-$03BF`: per-slot device codes (built by slot scanner)
- `$A300-$B9FF`: CCP + BDOS + banner string (from sysimg)
- `$BA00-$BFFF`: original 6502 RWTS routines (preserved)

### Z-80 memory after CP/M is running (post-handoff, ideal state)
- `$0000-$0002`: Z-80 reset vector (`JP $FA00` planted by 6502; rewritten to `JP $FA03` after first cold-boot)
- `$0003-$00FF`: Z-80 zero page / restart vectors (mostly unused by CP/M)
- `$0100-$E3FF`: TPA (Transient Program Area for user programs)
- `$E400-$EBFF`: CCP (after relocation; staged at `$A300` initially)
- `$EC00-$F9FF`: BDOS (after relocation)

**BIOS at `$FAB8-$FFFF` uses 256-byte interleaved layout** (4 code pages alternating with 4 runtime-generator pages):
- `$FAB8-$FBB7`: code page (jump table at `$FAB8-$FAE4`, inline LISTST/SECTRAN, dispatch table area, internal routines)
- `$FBB8-$FCB7`: generator page (filled with `FF FF 00 00 / F7 F7 00 00` on disk, populated at runtime)
- `$FCB8-$FDB7`: code page (more internal routines)
- `$FDB8-$FEB7`: generator page (filled with markers on disk)
- `$FEB8-$FFB7`: code page (BOOT vector target `$FED1` is in this page's runtime-generated prefix; real code at `$FF0E`+ is the device-scan loop)
- `$FFB8-$FFFF`: generator page (per-device handler code lives here once generated)

**Per-device state slots** (in runtime-generated regions): `$FECB` track, `$FED2` sector, `$FED4` DMA, `$FECD` cold-boot state byte (referenced by 2.23 preflight), `$FEDD` / `$FED8` (cleared by `$FB70` cold-boot-style code).

**2.20 BIOS at `$DACC-$E2FF`** uses the same 256-byte interleave with `$E5` filler in generator pages. BOOT vector `$DEA8`, real code resumes at `$DECC`.

### SoftCard memory mapping (bit-12 XOR for low addresses only)
- Z-80 `$0000-$0FFF` ↔ Apple `$1000-$1FFF`
- Z-80 `$1000-$1FFF` ↔ Apple `$0000-$0FFF`
- Z-80 `$2000-$FFFF` ↔ Apple `$2000-$FFFF` (no swap)

### Key 2.20 vs 2.23 differences
- BIOS load address: 2.20 at `$DACC`, 2.23 at `$FAB8` (8 KB shift)
- BIOS jump table in staging: 2.20 at offset `$1700`, 2.23 at `$1900`
- BIOS first 1 KB final position in newdisk: 2.20 at start (`$0A00`), 2.23 at end (`$0C00`)
- Boot banner string: present in 2.23, absent in 2.20
- Device code for Pascal 1.1 cards: 2.20 doesn't recognize them (assigns code `$04` like Pascal 1.0); 2.23 assigns code `$06`
- Slot scanner: 2.23 has 11 extra bytes for the Pascal 1.1 check
- Cold-boot generator: presumably differs in what it produces for device code `$06` (2.20 doesn't know about that code; 2.23 generates Pascal-1.1-driver code)
