# Resume Prompt — Microsoft SoftCard CP/M Investigation

**Last updated:** 2026-04-27 (15 devlogs published; cold-boot generator located at $FB70 — mislabeled as LIST in jump table; reset vector rewriting + BDOS vector planting + CCP/BDOS final-address relocation revealed; correction notes added to 3 earlier devlogs + Article 4)

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

### The Z-80 side (Parts 3-4 covered the architecture; the runtime second half is open)

10. **Z-80 starts at `$0000`** (= Apple `$1000`), reads `JP $FA00`, jumps to BIOS cold-boot.
11. **BIOS cold-boot enters somewhere in the populated 1 KB** — most code at `$FB70`+ (mislabeled as LIST in the jump table). The cold-boot routine sets up Z-80 stack, plants the standard CP/M BDOS call vector at Z-80 `$0005` (= `JP $9C06`), and **rewrites the Z-80 reset vector** from `JP $FA00` to `JP $FA03` (so subsequent warm-boots enter at `$FA03`, skipping the first cold-boot-only instruction).
12. **CCP, BDOS, and BIOS first 1 KB** are loaded by LOAD_CPM. Final addresses:
    - CCP+BDOS staged at Apple `$A300-$B9FF` (5.9 KB; tail bytes are the boot banner string `Softcard CP/M / 60K Ver. 2.23 / (c) 1980,1982 Microsoft`). **Some still-untraced step relocates this to the standard CP/M position around `$9406-$9C06`** before cold-boot — confirmed by the cold-boot routine planting `JP $9C06` (a BDOS-area address) at the BDOS call vector.
    - BIOS first 1 KB (`$FAB8-$FEB7`) at Apple `$0C00-$0FFF` initially; some still-untraced step copies it to LC RAM `$FAB8` for Z-80 to use.
13. **BIOS second 1 KB (`$FA00-$FAB7` + `$FEB8-$FFFF`) is runtime-generated** by the cold-boot routine at `$FB70`. The cold-boot CALLs into `$FA82` (in the runtime-generated `$FA00-$FAB7` area) — that area must be populated *before* the CALL, by code earlier in cold-boot. The `$FEB8-$FFFF` area gets populated as a mix of generated handler code AND per-device state variables (current track at `$FECB`, sector at `$FED2`, DMA at `$FED4`, etc.).
14. **Cooperative-CPU disk I/O model**: When CP/M needs disk, the Z-80 BIOS routines write parameters into the BIOS state area (`$FECB`/`$FED2`/`$FED4`), call into the Z-80 disk callbacks at `$1A00`, which signal the 6502 via the `$E000`/`$E010` flag pair (the polling loop at Z-80 `$1E36-$1E44`). SoftCard hardware switches CPUs. 6502 reads the same state from the same Apple addresses, runs the original RWTS routines preserved at Apple `$BA00-$BFFF`, deposits sector data at the DMA address, signals completion. SoftCard switches back. Z-80 returns from callback.

**Important corrections from the cold-boot finding:**
- The dispatch table starts at `$FAEB` (not `$FB0A` as earlier devlogs had); 4 entries × 16 bytes ending at `$FB2A`.
- The "LIST" / "PUNCH" / "READER" jump-table entries (`$FB70`, `$FB7F`, `$FB91`) are NOT real LIST/PUNCH/READER routines — they're alternate-entry-point midpoints into the cold-boot routine.
- CONST target `$FB10` and CONIN target `$FB1A` are inside dispatch table entry 3's *padding area* — exactly where the cold-boot generator writes runtime CONST/CONIN code.

### The Pascal 1.0 vs 1.1 calling convention precision (Part 1's full payoff)

- **Pascal 1.0**: ID bytes ARE the entry points. `$Cn05 = $38` is the `SEC` opcode; `$Cn07 = $18` is `CLC`. `JSR $Cn05` does input (carry set), `JSR $Cn07` does output (carry clear). Both fall through to common dispatch using the carry flag.
- **Pascal 1.1**: 4-byte vector table at `$Cn0D-$Cn10` (INIT, READ, WRITE, STATUS — each a single-byte offset). Caller reads offsets, JSRs to `$Cn00 + offset`, MUST call INIT before READ/WRITE/STATUS.
- A Pascal 1.1 card can be backward-compatible at the byte level (the Videx is — `$CB05`/`$CB07` are real `SEC`/`CLC`), but its 1.0-style dispatch typically requires the V flag to be set by an upstream `BIT IORTS` at `$Cn00` during the V-setting preamble. PR#n / COUT-via-CSW sets that up correctly; a naive `JSR $Cn07` does not.
- **CP/M 2.20 sees a Videx, sees Pascal 1.0 ID bytes, does naive `JSR $Cn07`, lands in dispatch code with uninitialized state → hangs.** CP/M 2.23 reads `$Cn0B`, sees Pascal 1.1, routes through the Pascal 1.1 vector table. That's the entire bug fix.

### The BIOS factory mental model (Part 4's contribution)

The static disk image doesn't contain the runtime BIOS. It contains the BIOS *factory* — the cold-boot code generator that produces the runtime BIOS based on which slots have what cards (per the device-code table built by the slot scanner). This is why 2.20 and 2.23 differ structurally despite the byte-level Pascal 1.1 detection delta being only 11 bytes — the *factory* is different between versions, so the *generated BIOS* it produces ends up different in places that aren't directly the Videx detection.

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
- ✅ **Part 1**: `cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card.mdx` — Pascal 1.0 vs 1.1 detection delta, crossed-streams framing
- ✅ **Part 2**: `cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction.mdx` — Beginning-to-end 6502 boot stage narrative
- ✅ **Part 3**: `cpm-videx-03-apple-memory-through-z-80-eyes.mdx` — SoftCard memory model, CP/M layering, BIOS jump table, partial-extraction problem
- ✅ **Part 4**: `cpm-videx-04-the-bios-that-half-exists.mdx` — LOAD_CPM, staging splits, runtime BIOS generation, cooperative-CPU model, BIOS factory
- ⏳ **Part 5 (planned)**: The BIOS factory — cold-boot code generator, diff 2.20 vs 2.23 generators, real Pascal-1.1 driver path
- ⏳ **Part 6 (planned)**: From `JP $FA00` to `A>` — full Z-80 boot trace
- ⏳ **Part 7 (planned)**: Every difference between 2.20 and 2.23 — full inventory

### Dev logs (`src/content/devlogs/cpm-videx-*.mdx`)

15 entries published, chronological:
1. `cpm-videx-origin-2026-04-25.mdx` — Joshua's report, version classification
2. `cpm-videx-disks-2026-04-26.mdx` — disk triage, boot stub elimination
3. `cpm-videx-bios-2026-04-26.mdx` — Z-80 BIOS extraction dead-end, load addresses
4. `cpm-videx-loader-2026-04-26.mdx` — 11-byte Pascal 1.1 detection branch
5. `cpm-videx-device-codes-2026-04-26.mdx` — partial: clues to what device codes mean
6. `cpm-videx-boot-loader-2026-04-27.mdx` — Z-80 reset vector planting
7. `cpm-videx-z80-disassembler-2026-04-27.mdx` — Z-80 disassembler online + CONOUT $C800 (later corrected)
8. `cpm-videx-bios-partial-2026-04-27.mdx` — BIOS extraction partial; CONST/CONIN are dispatch table — **has Update notes**
9. `cpm-videx-shared-address-spaces-2026-04-27.mdx` — $C800 lesson (corrected the Videx overreach)
10. `cpm-videx-bios-trace-wall-2026-04-27.mdx` — CONOUT trace into BIOS hits the partial-extract wall — **has Update note**
11. `cpm-videx-load-cpm-2026-04-27.mdx` — LOAD_CPM cracked
12. `cpm-videx-bios-runtime-generated-2026-04-27.mdx` — half the BIOS is runtime-generated — **has Update note**
13. `cpm-videx-220-reconstruction-2026-04-27.mdx` — 2.20 reconstruction
14. `cpm-videx-bios-state-storage-2026-04-27.mdx` — Z-80 callbacks write to BIOS second half
15. `cpm-videx-cold-boot-found-2026-04-27.mdx` — cold-boot generator located at $FB70 (mislabeled as LIST); reset vector rewrite, BDOS vector planting, CCP/BDOS final-address relocation revealed

Articles with Update notes: Article 4 has a forward-pointer Update at the end pointing to the cold-boot finding devlog.

### Reference (`src/content/reference/`)
- `apple-ii-tn-misc-8-pascal-1-1-firmware-protocol.mdx` — full text of Apple Tech Note Misc #8 (the only canonical Pascal protocol document)
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

In priority order:

1. **Trace the cold-boot routine forward from `$FB70`.** The entry at `$FB70` is identified, but its full execution path isn't traced yet. Specifically: the `CALL $FA82` at `$FB7C` enters the supposedly-zero `$FA00-$FAB7` area — meaning code BEFORE `$FB70` (or the sentinel-check branch at `$FB97`) must populate `$FA82` with executable code first. Trace that. Also trace the JR Z branch at `$FB84` (sentinel `$9C08 == $9C` check) and the `JP $000B` at `$FB94` (jumping to Z-80 page 0 / Apple page 1).

2. **Find the actual code-generation logic.** The bytes at `$FB70-$FBB6` set up architectural fixed points (stack, BDOS vector, reset vector) but don't generate per-device handler code. The Pascal-1.1 driver code generation must happen elsewhere. Candidates: the `$FA82` callee, downstream code, or BIOS routines triggered by the first console-output call.

3. **Find the CCP+BDOS relocation step.** The cold-boot routine plants `JP $9C06` at `$0005`. So BDOS final position is `$9C06`. But sysimg is staged at `$A300`. Some code must move it to its final position. Could be in cold-boot's earlier instructions OR in the BDOS itself once first invoked (BDOS often does its own relocation in CP/M 2.x).

4. **Diff 2.20 vs 2.23 cold-boot routines.** 2.20's BIOS jump table has LIST at `$DB66` (= `$DACC + $9A`); should contain analogous bytes. Direct diff of the cold-boot routines should pinpoint what 2.23 added for Pascal 1.1.

5. **Add CB/DD/ED/FD prefix decoding to z80disasm.** The `JP $000B` at `$FB94` is suspicious — Z-80 `$000B` = Apple `$100B` which is in the loader area. Maybe an instruction we can't decode yet would clarify. Also block instructions (LDIR, LDDR) are likely used in any code-generation step we haven't found.

6. **Draft Part 5 article** when the cold-boot routine's full action is understood — "The BIOS Factory."

7. **Continue updating this resume-prompt.md after each significant step.**

### Side tasks (lower priority but worth noting)

- The `JSR $0E36` callee chain is partly traced (the inter-CPU sync at Z-80 `$1E36`). Could go deeper to find the actual SoftCard switch.
- 2.20 and 2.23 sysimg files (CCP+BDOS) should be diffed — the bulk should be byte-identical (same Digital Research code), confirming our extraction is correct. Any differences would be Microsoft-side modifications worth investigating.
- The `$F3xx` area (Apple TPA region) is referenced heavily by both Z-80 callbacks and BIOS code (`$F3B8`, `$F3D0`, `$F3DE`, `$F3A1`, `$F397`). It's a per-system-state area. Documenting what each `$F3xx` byte means would clarify many references.

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
- `$0000-$0002`: Z-80 reset vector (`JP $FA00` planted by 6502)
- `$0003-$00FF`: Z-80 zero page / restart vectors (mostly unused by CP/M)
- `$0100-$E3FF`: TPA (Transient Program Area for user programs)
- `$E400-$EBFF`: CCP (after relocation; staged at `$A300` initially)
- `$EC00-$F9FF`: BDOS (after relocation)
- `$FA00-$FAB7`: BIOS cold-boot area (RUNTIME-GENERATED, zero on disk)
- `$FAB8-$FAE4`: BIOS jump table (15 entries, statically loaded)
- `$FAE5-$FB09`: inline LISTST/SECTRAN stubs (statically loaded)
- `$FB0A-$FB39`: per-device dispatch table (4 entries × 16 bytes, statically loaded)
- `$FB3A-$FEB7`: BIOS internal routines (CONOUT, LIST, helpers — statically loaded)
- `$FEB8-$FFFF`: BIOS per-device handlers + per-device state (RUNTIME-GENERATED)
  - State: `$FECB` = current track, `$FED2` = current sector, `$FED4` = current DMA, etc.
  - Code: per-device READ, WRITE, HOME, SELDSK, SETTRK, the input handlers at `$FF64-$FF9F`, the output handlers at `$FFAC-$FFDF`

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
