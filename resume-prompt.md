# Resume Prompt — Microsoft SoftCard CP/M Investigation

**Last updated:** 2026-04-27

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
- **The actual SoftCard CPU-switch instruction**: the precise `STA $C0Bx` (or similar) write that flips control from 6502 to Z-80. Suspected to live in the warm-boot routine at Apple `$03C0` (loaded from `$13C0` in the loader image), specifically in the `JSR $0E36` callee. Not yet identified.
- **6502 disk I/O block** at `$0A00-$0FFF`: standard RWTS-style read/write/seek routines. Not yet annotated.
- **6502 subroutines + strings** at `$1100-$11AF`: small section, easily addressable.
- **The `$1200-$13FF` install images**: copied to Apple `$0200-$03FF`, which is Z-80 `$1200-$13FF` after SoftCard XOR. Mostly Z-80 code that runs after the switch. Will need a Z-80 disassembler.
- **Z-80 BIOS extraction**: blocked previously by not understanding loader sector-to-Z-80-memory mapping. Now that we know the loader plants only the Z-80 reset vector and Z-80 code at `$0200-$03FF`, the rest of CP/M (CCP+BDOS+BIOS) must be loaded by Z-80 code from disk after the switch. So extracting the BIOS without booting requires either (a) simulating the Z-80 loader, or (b) statically reading the disk system tracks knowing the file format.
- **Z-80 disassembler**: nibbler is 6502-only. Need to add Z-80 support OR use external `z80dasm`. Recommended: add a minimal Z-80 disassembler to nibbler so the toolchain stays consistent.
- **Downstream consumer of device code 6**: how the Pascal 1.1 path actually drives the Videx (6845 CRTC programming at `$C0B0/$C0B1`, VRAM window writes `$CC00-$CDFF`, `$CFFF` ROM-release switch). Lives in the Z-80 BIOS's `CONOUT`/`BOOT` routines. Pending Z-80 disassembly.

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
- **Part 2 (planned)**: **A beginning-to-end NARRATIVE of the 6502 boot stage** — explicitly the user's request (2026-04-27). Walks the reader from the moment the Apple Disk II PROM loads sector 0, through the boot stub's CP/M-skewed sector reads, the stage-2 language card switch, the Apple monitor calls, the install loops, the slot scanner (with the Pascal 1.0 vs 1.1 detection), the Z-80 reset vector planting, and finally the SoftCard CPU switch. Reads as a story, not a reference. Material in `docs/CPM_BootLoader.md` and `docs/CPM223_BootLoader.asm` is the technical backbone. Draft when the SoftCard switch instruction is identified and the disk I/O block is at least surveyed.
- **Part 3 (planned)**: Z-80 BIOS architecture and the SoftCard memory model
- **Part 4 (planned)**: The Pascal 1.1 driver path (what 2.23's CONOUT actually does for a Videx)
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

1. **Find the SoftCard CPU-switch instruction.** Trace `JSR $0E36` from the warm-boot routine at `$03C0` (Apple `$13CC`, in the loader image at `cpm-investigation/loader_223.bin`). The actual `STA $C0Bx` write that flips the CPU is the missing piece for a complete narrative of the 6502→Z-80 transition.
2. **Annotate `$1100-$11AF`** — small section, mostly subroutines like the slot-ROM checksum and the strings array. Update `docs/CPM223_BootLoader.asm`.
3. **Annotate `$0A00-$0FFF` disk I/O block.** Standard RWTS-style routines but worth documenting since they're called to load the rest of CP/M from disk.
4. **Update the project entry** at `src/content/projects/cpm-videx.mdx` with the multi-part article roadmap.
5. **Add a Z-80 disassembler to nibbler.** Plain Z-80 (no Z80 prefixes initially is OK; prefixes are well-known and can be added incrementally). This unblocks the Z-80 BIOS analysis.
6. **Once Z-80 disasm exists**: extract and annotate the install fragments at Apple `$0200-$03FF` (Z-80 `$1200-$13FF` after XOR).
7. **Decide BIOS-extraction strategy**: simulate the Z-80 loader, or statically pull from the disk's system tracks knowing the file format.
8. **Draft Part 2 article** when the 6502 disassembly is complete enough.
9. **Continue updating this resume-prompt.md after each significant step.**
