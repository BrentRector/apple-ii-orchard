# Resume Prompt — Microsoft SoftCard CP/M Investigation

**Last updated:** 2026-04-27 (BIOS first 1 KB exact byte match against staged sectors; second 1 KB confirmed all-zero on disk → runtime-generated; 2.20 reconstruction done with PRODOS_INTERLEAVE; structural difference between 2.20 and 2.23 BIOS layout in staging)

This file is the canonical session-recovery prompt for the Microsoft SoftCard CP/M reverse-engineering project. If this conversation crashes or context is lost, hand this file to a fresh assistant and it should be able to pick up exactly where we left off without losing any directives, conventions, or progress.

---

## The Project (the durable goal)

Reverse-engineer Microsoft's Apple ][ Z-80 SoftCard CP/M completely — both **2.20** (which fails to boot when a Videx Videoterm 80-column card is installed) and **2.23** (which boots and runs cleanly with the same hardware). The ultimate deliverable is:

1. A complete description and disassembly of CP/M 2.20 and 2.23, starting at the boot sector (6502 code) and continuing through the SoftCard switch into Z-80 mode.
2. Z-80 disassembly of the entire CP/M system (CCP + BDOS + BIOS) for both versions.
3. A narrative that walks the reader from power-on to the `A>` command prompt, with full understanding of every step and the differences between the two versions.

The project is hosted on:
- **Code/disasm repo:** [Orchard](https://github.com/BrentRector/orchard) at `e:/Orchard/` — investigation scripts, intermediate artifacts, annotated disassembly files, source disk images
- **Website:** [wiseowl.com](https://wiseowl.com) at `e:/Sites/wiseowl.com/` — public-facing project entry, articles, devlogs, references

---

## Origin story (so the narrative voice can pick up)

Joshua Norrid (of A2FPGA fame) reported that Microsoft SoftCard CP/M wasn't booting with the A2FPGA Videx Videoterm emulation. He confirmed the same failure on real Videx hardware. Brent (the user/author) doesn't yet have a physical Microsoft Z-80 SoftCard ("supposedly in the mail") so all analysis is static disassembly; Joshua's hardware confirms predictions. Version testing isolated the boundary: 2.20 and 2.20B fail; 2.23 works.

---

## Current status (as of 2026-04-27)

### What's confirmed and documented
- **Detection delta** (Pascal 1.0 vs 1.1): 2.23 added 11 bytes of 6502 code in the boot loader's slot scanner that read `$Cn0B` (Pascal 1.1 signature byte) and tag any Pascal-1.1 card with internal device code `$06` instead of the generic Pascal-1.0 device code `$04`. Not Videx-specific, just Pascal-1.1-aware. Documented exhaustively in `docs/CPM_Videx_Difference.md`.
- **Pascal 1.0 vs 1.1 calling-convention precision**: Pascal 1.0 entry points ARE the ID bytes (`$38`=`SEC`, `$18`=`CLC`, dual-purpose). Pascal 1.1 uses a 4-byte vector table at `$Cn0D-$Cn10` (INIT/READ/WRITE/STATUS). Pascal 1.1 cards declare both ID sets but only implement the 1.1 calling convention. CP/M 2.20 sees a Videx, classifies as Pascal 1.0, calls a 1.0 entry point that requires Pascal-1.1-style state, hangs. Documented in the article and in `memory/reference_apple_pascal_firmware_protocol.md`.
- **Z-80 BIOS load addresses**: 2.23 BIOS at Z-80 `$FAB8`, 2.20 BIOS at Z-80 `$DACC` — an `$2000` (8 KB) shift up. Found via 17-jump-table pattern scan of disk images. (BIOSes have only 15 entries — SoftCard CP/M is CP/M 2.0-style without LISTST/SECTRAN.)
- **Z-80 reset vector planting**: The 6502 boot loader writes Z-80 machine code (`$C3 $00 $FA` = `JP $FA00`) into Apple `$1000-$1002` before the SoftCard switch. Apple `$1000` is Z-80 `$0000` (the Z-80 reset vector) under the SoftCard's `XOR $1000` mapping. So the 6502 plants the Z-80's reset vector with the address of the BIOS cold-boot entry, then flips the switch. CP/M 2.20 plants `JP $DA00` (consistent with its BIOS at `$DACC`).
- **Boot stub**: byte-identical between 2.20 and 2.23 at `$0801-$083C`. CP/M sector skew table at `$082D-$083C`. Loads sectors `0,2,4,6,8,A,C,E,1,3,5` of track 0 to memory `$0800-$1300`, jumps to `$1000`.
- **Slot scanner annotated**: full understanding of `$1060-$10D5` in both versions, including the 11-byte delta.
- **Apple Disk II controller** detected by the loader's signature table: `($Cn05=$03, $Cn07=$3C)` matches the actual P6 PROM bytes at `$C605/$C607`. Verified.

### What's open / next
- **The actual SoftCard CPU-switch instruction**: confirmed (2026-04-27) the loader has NO writes to `$C0Bx`. So the switch is NOT a direct STA in the 6502 loader. Must be either: (a) inside the disk-load callee at `$0E36` (which the warm-boot routine calls as part of staging more CP/M from disk), (b) triggered by a side-effect of accessing the SoftCard slot's expansion ROM ($C400 or wherever the SoftCard sits), or (c) in the Z-80 fragments that run after the switch. Identifying which requires either deeper 6502 disasm of `$0E36`-area or Z-80 disasm of the install fragments. Likely a side-effect mechanism rather than an explicit STA.
- **6502 disk I/O block** at `$0A00-$0FFF`: surveyed (2026-04-27). Major routines identified: WRITE_SECTOR ($0A00), WRITE_BYTE ($0A8F), READ_SECTOR ($0A99), SEEK_TRACK ($0B5F), LOAD_CPM ($0C00). Standard Apple Disk II RWTS pattern, not annotated per-instruction.
- **6502 subroutines + strings** at `$1100-$11AF`: complete (2026-04-27). PREP_HANDOFF orchestrator, CKSUM_SLOT, PAGE_COPY, "MUST BOOT FROM SLOT SIX" string, Apple monitor reset-vector replacement bytes.
- **The `$1200-$13FF` install images**: copied to Apple `$0200-$03FF`, which is Z-80 `$1200-$13FF` after SoftCard XOR. Mostly Z-80 code that runs after the switch. Will need a Z-80 disassembler.
- **Z-80 BIOS extraction**: blocked previously by not understanding loader sector-to-Z-80-memory mapping. Now that we know the loader plants only the Z-80 reset vector and Z-80 code at `$0200-$03FF`, the rest of CP/M (CCP+BDOS+BIOS) must be loaded by Z-80 code from disk after the switch. So extracting the BIOS without booting requires either (a) simulating the Z-80 loader, or (b) statically reading the disk system tracks knowing the file format.
- **Z-80 disassembler**: COMPLETE (2026-04-27). Added to nibbler as `nibbler/z80.py`, exposed via CLI as `nibbler z80disasm`. Covers all 256 unprefixed opcodes; CB/DD/ED/FD prefix bytes are stubs. Adequate for ~90% of typical BIOS code. Documented as a standalone tool entry on wiseowl.com at `/tools/z80-disassembler`.
- **2.23 CONOUT targets the expansion-ROM window** (2026-04-27): `$FB4D` contains `LD HL,$C800` — that's the Apple ][ **shared expansion-ROM window**, NOT Videx-specific. Any slot card with an expansion ROM gets paged in there when its `$Cn00-$CnFF` slot ROM is touched. The Videx happens to use it for VRAM, but so do Pascal-1.1 cards generally and many ProDOS-era cards. So this proves the BIOS is *expansion-ROM-aware*, not Videx-aware. To prove Videx-specific would need preceding code that pages in the SoftCard-detected slot, or characteristic Videx writes (CRTC programming via `$C0B0/$C0B1`, `$CFFF` ROM-release toggle). Other parts of the path (the dispatch logic that decides "use this routine for code 6") still TBD. **Lesson learned: don't conflate "uses the expansion-ROM window" with "knows about the Videx specifically."**
- **BIOS extraction is partial** (2026-04-27): Some routines (CONOUT, LIST, probably HOME/SELDSK/SETTRK) are at their nominal addresses in the file-offset extract and disassemble cleanly. Others (CONST/CONIN/BOOT/WBOOT) are NOT — the bytes at those addresses are a structured per-device dispatch table (4 entries × 16 bytes). About half the 2.23 BIOS is reachable; the per-device input/output handlers at $FF64-$FFDF, BOOT at $FED1, and the area below $FAB8 are not.
- **LOAD_CPM fully reverse-engineered** (2026-04-27, Path A complete): At Apple $0BEB (= $BBEB after PREP_HANDOFF copy). Reads 29 sectors starting trk0:$0B sequentially, stages at $8000-$9CFF. PREP_HANDOFF then splits: $9700-$9CFF → Apple $0A00-$0FFF (Z-80 disk callbacks), $8000-$96FF → Apple $A300-$B9FF (CCP+BDOS+banner). Reconstruction script at `cpm-investigation/reconstruct_staging.py`. Extracted artifacts: `staging_223.bin`, `sysimg_223.bin`, `newdisk_223.bin`. The system image's tail confirms it's real CP/M with the boot banner string "Softcard CP/M / 60K Ver. 2.23 / (c) 1980,1982 Microsoft".
- **Z-80 disk callbacks at Apple $0A00 = Z-80 $1A00 identified.** They reference $A3xx-$B9xx (CCP+BDOS) and contain a polling loop on `$E000` at $1E36 (the warm-boot's $0E36 target). The `LD A,($E000) / RLA / JR NC,$1E39 / LD ($E010),A` pattern is inter-CPU synchronization — Z-80 polls a flag the 6502 sets after disk I/O completes.
- **BIOS first 1 KB FOUND** (2026-04-27): Exact byte match. The bytes at staging offset $1900 (= Apple $9900) are BIOS $FAB8-$FEB7. After PREP_HANDOFF copies $9700-$9CFF to Apple $0A00-$0FFF, the BIOS first 1 KB lands at Apple $0C00-$0FFF. Some still-untraced step must copy these to LC RAM at $FAB8-$FEB7 before/during BIOS execution.
- **BIOS second 1 KB is RUNTIME-GENERATED** (2026-04-27): Verified the "missing" trk2:$08-$0B sectors are all zeros on disk. The cold-boot area $FA00-$FAB7 is also all zeros/data. So the BIOS routines for BOOT/HOME/SELDSK/SETTRK/READ/WRITE and the per-device handlers at $FF64-$FFDF are GENERATED at runtime by the cold-boot code. SoftCard CP/M does code-generation at boot.
- **2.20/2.23 BIOS layout differs structurally**: 2.20 BIOS jump table at staging offset $1700; 2.23 at $1900 (a 2-sector shift). 2.20 BIOS lands at the START of newdisk_220.bin (Apple $0A00); 2.23 at the END (Apple $0C00). Same 29-sector load mechanism, different content arrangement.
- **2.20 reconstruction done**: staging_220.bin, sysimg_220.bin, newdisk_220.bin extracted. 2.20 has NO 'Softcard' banner (added in 2.23).
- **Z-80 callbacks DO write into BIOS second half**: Found instructions like `LD HL,$FECB / LD (HL),A`, `LD HL,$FED4`, `LD ($FED2),A` in newdisk_223.bin. So the BIOS second half is BOTH runtime-generated code AND per-call state storage that the callbacks read/write.
- **SoftCard CPU-switch trigger STILL not located** (2026-04-27): No direct $C0Bx writes in the 6502 loader, no Z-80 IN/OUT to plausible SoftCard ports in the disk callbacks, no obvious memory-mapped soft-switch access. Likely either: (a) hidden in CB/DD/ED/FD prefix instructions the disassembler doesn't decode, (b) a memory access pattern the SoftCard hardware monitors silently, (c) in BIOS code we don't have.

### Big-picture remaining work toward the deliverable
1. Finish 6502 boot loader annotation (small, mostly mechanical)
2. Add Z-80 disassembler to toolchain (1-2 days of work)
3. Extract and annotate the Z-80 install fragments (`$0200-$03FF` after install)
4. Boot-trace or static-extract the Z-80 BIOS (CCP/BDOS are byte-identical to DRI's reference; only BIOS varies)
5. Annotate Z-80 BIOS for both versions, diff
6. Walk the boot sequence from BIOS cold-boot through CCP entry to `A>` prompt
7. Write the multi-part article series

---

## Website structure (project + articles + devlogs + reference)

The site at `e:/Sites/wiseowl.com/` (Astro v6, Cloudflare Pages) hosts:

### Project entry (`src/content/projects/cpm-videx.mdx`)
- Title: "Microsoft SoftCard CP/M on a Videx"
- Featured: true, weight: 5
- Summary, body sections, link to articles + devlogs + repo
- **Update this when the article roadmap evolves.**

### Articles (`src/content/articles/cpm-videx-NN-*.mdx`)
- **Part 1 (published)**: `cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card.mdx` — Pascal 1.0 vs 1.1 detection delta + crossed-streams framing
- **Part 2 (published 2026-04-27)**: `cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction.mdx` — Beginning-to-end narrative of the 6502 boot stage (per user's explicit request 2026-04-27). Honest about the SoftCard-switch open question.
- **Part 3 (planned)**: Z-80 BIOS architecture and the SoftCard memory model
- **Part 3 (published 2026-04-27)**: `cpm-videx-03-apple-memory-through-z-80-eyes.mdx` — SoftCard memory model (bit-12 XOR), CCP/BDOS/BIOS layering, 2.23 BIOS jump table, per-device dispatch table at $FB0A, partial-extraction problem
- **Part 4 (planned)**: The Pascal 1.1 driver path. **BLOCKED by partial BIOS extraction** — per-device handlers at $FF64-$FFDF aren't in the extract.
- **Part 5 (planned)**: From `JP $FA00` to `A>` — the full CP/M boot trace
- **Part 6+ (planned)**: Differences inventory (every diff between 2.20 and 2.23, not just the Videx-related)

### Dev logs (`src/content/devlogs/cpm-videx-*-YYYY-MM-DD.mdx`)
**One per topic / approach / area of investigation, NOT one per day.** When trying a different angle = new entry, even on the same day.

Existing entries (chronological):
1. `cpm-videx-origin-2026-04-25.mdx` — Joshua's report; version classification
2. `cpm-videx-disks-2026-04-26.mdx` — disk triage; boot stub elimination
3. `cpm-videx-bios-2026-04-26.mdx` — Z-80 BIOS extraction dead-end; load addresses
4. `cpm-videx-loader-2026-04-26.mdx` — 11-byte Pascal 1.1 detection branch
5. `cpm-videx-device-codes-2026-04-26.mdx` — partial: clues to what device codes mean
6. `cpm-videx-boot-loader-2026-04-27.mdx` — Z-80 reset vector planting
7. `cpm-videx-z80-disassembler-2026-04-27.mdx` — Z-80 disassembler online; CONOUT $C800 finding
8. `cpm-videx-bios-partial-2026-04-27.mdx` — BIOS extraction partial; CONST/CONIN are dispatch table
9. `cpm-videx-shared-address-spaces-2026-04-27.mdx` — $C800 lesson learned (corrected the Videx overreach)
10. `cpm-videx-bios-trace-wall-2026-04-27.mdx` — CONOUT trace into BIOS hits the partial-extract wall
11. `cpm-videx-load-cpm-2026-04-27.mdx` — LOAD_CPM cracked: 29-sector load, staging split, sysimg with banner, Z-80 disk callbacks at $0A00
12. `cpm-videx-bios-runtime-generated-2026-04-27.mdx` — BIOS second 1 KB is all-zero on disk because it's runtime-generated; SoftCard CP/M does code generation at boot

Pending devlog entries (write when reaching milestones):
- The "no SoftCard CPU-switch in the loader" finding — could be its own entry or rolled into a Z-80-handoff entry
- LOAD_CPM reverse-engineering (when done; will unlock 2.20 BIOS extraction)
- The dispatch table at `$FB0A`+ structure (4 entries × 16 bytes) — could be folded into the BIOS-completion devlog

**Frontmatter constraints (will fail build if violated):**
- `tldr` ≤ 200 characters
- `tags` from `TagEnum` only (in `src/content.config.ts`); add new tags to enum BEFORE using
- `6502` and similar numeric-prefix tags MUST be quoted as `"6502"` in YAML block-style arrays (else parsed as integer, fails enum validation)
- Article `description` ≤ 300 chars
- Project `summary` ≤ 300 chars

### Reference (`src/content/reference/`)
- `apple-ii-tn-misc-8-pascal-1-1-firmware-protocol.mdx` — full text of Apple Tech Note Misc #8
- Source PDF at `public/reference/apple-ii-technical-notes-1989-09.pdf`

### Build / deploy commands
- Local build/test: `npm run build` (in `e:/Sites/wiseowl.com/`)
- Build + deploy to Cloudflare Pages: `npm run deploy` (runs `astro build && wrangler pages deploy dist --project-name wiseowl`)
- Wrangler is globally installed; uses Brent's existing auth

### Site wordmark
- Header reads "Wise Owl — Brent Rector" (NOT "Wise Owl Software" — that's the separate product site `wiseowlsoftware.com`)

---

## Voice and style

### Devlogs
- Terse, declarative, past tense, **no first-person pronouns** (write "Loaded the WOZ image" not "I loaded")
- Em dashes for asides
- Specific technical detail (addresses, byte values, register names)
- ~200-400 words per entry
- Always end with a `**Status:**` line summarizing what's confirmed and what's next

### Articles
- Long-form (10-15 min reads, ~3000 words)
- First-person allowed and natural
- Rich technical context, history, motivation
- Reference photos/images where useful
- Series tag included (`cpm-videx-series`)

### Both
- No emojis (anywhere)
- No exclamation marks in body copy
- No buzzwords ("revolutionary," "next-gen," etc.)
- No hedging ("might," "could potentially")
- Specific facts, no marketing tone

### Editorial guidance the user has given
- **Lead with consequence, not detection.** When writing about a found code delta, the act of finding it is the door, not the room. Pivot quickly to behavioral consequence — what the system does differently because of the change. The user explicitly flagged this on Part 1 and the framing was rewritten.
- **State things clearly, not cleverly.** Cryptic article titles (like the original "The Eleven Bytes That Recognize a Videx") are bad; descriptive ones (like "Why Microsoft CP/M Didn't Recognize an 80-Column Card") are good. Punchy is fine; cryptic is not.
- **Honesty over completeness.** When something is inferred but not verified from disassembly, say so explicitly. Distinguish "known from reading the code" from "plausible hypothesis pending verification." Other LLMs have presented inference as fact and the user noticed and called it out.

---

## Repository conventions

### Orchard repo (`e:/Orchard/`)
- `cpm-investigation/` — extraction scripts, intermediate binaries, linear disassemblies for both versions
- `docs/CPM_Videx_Difference.md` — the side-by-side annotated diff of the slot scanner
- `docs/CPM_BootLoader.md` — narrative architecture of the 6502 loader
- `docs/CPM223_BootLoader.asm` — annotated 6502 disassembly (work in progress)
- `nibbler/` — Apple ][ disk analysis toolkit (6502 only; needs Z-80 support added)
- `CPMV233.DSK` — CP/M 2.23 disk image (DOS 3.3 sector order)
- `CPM220Disk1.po`, `CPM220Disk2.po` — CP/M 2.20 distribution disks (ProDOS sector order)

### Build/deploy commands
- For Orchard: standard git workflow; no build/deploy needed (just docs and scripts)
- For wiseowl.com: see "Build / deploy commands" above

---

## Memory directory

`C:/Users/brent/.claude/projects/e--Orchard/memory/` contains semantic project memory:
- `MEMORY.md` — index
- `project_cpm_videx_investigation.md` — investigation status, findings, open questions
- `reference_apple_pascal_firmware_protocol.md` — Pascal 1.1 protocol with calling-convention details
- `reference_wiseowl_devlogs.md` — devlog conventions, schema, voice
- `feedback_finding_vs_consequence.md` — editorial guidance about not over-celebrating detection

---

## Concrete next steps when resuming

In priority order:

1. **Disassemble the populated BIOS first 1 KB carefully.** We have it (in `bios_223.bin[0:1024]`, also identical to `newdisk_223.bin[0x200:0x600]`). Map every routine: jump table, inline stubs, dispatch table, CONOUT, LIST, the helper at $FB45, and especially anything that LOOKS LIKE a code generator (writes to $FE/$FF area). The cold-boot generator must be in this area since it's the only BIOS code statically present.
2. **Find the cold-boot generator.** Routine that runs first after Z-80 starts and populates the second 1 KB ($FA00-$FAB7 + $FEB8-$FFFF) with per-device handler code based on the device-code table at $03B9-$03BF. It must call into the per-device dispatch table at $FB0A to know what code to generate.
3. **Trace the SoftCard CPU-switch.** With the BIOS first half disassembled, we should see how the Z-80 receives control. Likely the warm-boot routine at Apple $03C0 (6502) → JSR $0E36 (Z-80 code) is the trigger; SoftCard hardware monitors the 6502 entering this address range and flips. Verify with deeper Z-80 disasm.
4. **Diff 2.20 vs 2.23 BIOS code generators.** Both versions have a populated 1 KB at the equivalent BIOS-base offset. The cold-boot generator differs between versions — that's where 2.23's Pascal-1.1 awareness lives. Diff would directly show what code 2.23 generates differently for device code 6.
5. **Add CB/DD/ED/FD prefix decoding to z80disasm.** The current ED-prefix stub means we miss block instructions (LDIR, LDDR), IM instructions, IN/OUT to (C), and IX/IY operations. Likely needed to fully understand the BIOS and the cold-boot generator.
6. **Draft Part 4 article** when the cold-boot generator is understood — that's the Pascal 1.1 driver path payoff.
7. **Continue updating this resume-prompt.md after each significant step.**
