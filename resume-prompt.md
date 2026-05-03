# Resume Prompt — Microsoft SoftCard CP/M Investigation

**Last updated:** 2026-05-02 — **INVESTIGATION CLOSED.**

12 articles + 39 devlogs. Final article: `cpm-videx-12-the-investigation-closes.mdx` (pubDate 2026-05-02). Central question settled byte-for-byte and emulator-confirmed: **2.20 hangs because device-code 4 (Pascal 1.0 generic) routes the Videx-via-CONOUT through `$DFBE`, which has pure `$E5` PUSH-HL fill on disk; the cold-boot generator doesn't populate it with real handler code, so the first CONOUT call executes `PUSH HL` repeatedly, the Z-80 SP wraps past `$0000`, high memory corrupts. 2.23 fixes this by detecting the Videx as device 6 (Pascal 1.1) via the 11-byte `$Cn0B` check, routing through `$FDB0` instead — which contains a one-byte `RET` stub on disk.** Reproduced byte-for-byte in a from-scratch 6502+Z-80+SoftCard emulator (Stage 3, 2026-05-01).

A successor project `cpm-from-source` (also `featured: true` on wiseowl.com) emerged: annotated 6502 + Z-80 source listings that round-trip into a byte-identical CP/M 2.23 .DSK image.

This file is the canonical session-recovery prompt. **If this conversation crashes or context is lost, hand this file to a fresh assistant and it should be able to pick up where things stand without losing any directives, conventions, or progress.**

---

## The Project (the durable goal — now achieved)

Reverse-engineer Microsoft's Apple ][ Z-80 SoftCard CP/M completely — both **2.20** (which fails to boot when a Videx Videoterm 80-column card is installed) and **2.23** (which boots and runs cleanly with the same hardware). The original deliverables were:

1. ✅ Complete description and disassembly of CP/M 2.20 and 2.23, from boot sector through SoftCard switch into Z-80 mode.
2. ✅ Z-80 disassembly of the entire CP/M system (CCP + BDOS + BIOS) for both versions.
3. ✅ Narrative walking the reader from power-on to the `A>` prompt, with full understanding and version diff.

All three are done. The cpm-from-source successor project additionally produces a byte-identical .DSK from the annotated sources via a build tool.

The project is hosted on:
- **Code/disasm repo:** [Orchard](https://github.com/BrentRector/orchard) at `e:/Orchard/`
- **Personal site (publishing):** [wiseowl.com](https://wiseowl.com) at `e:/Sites/wiseowl.com/`. NOT the same as wiseowlsoftware.com (the separate Demeanor product site).

---

## Origin Story

Joshua Norrid (of A2FPGA fame) reported that Microsoft SoftCard CP/M wasn't booting with the A2FPGA Videx Videoterm emulation. He confirmed the same failure on real Videx hardware — so the emulation is faithful, the OS is what's broken. Brent (the user/author) doesn't yet have a physical Microsoft Z-80 SoftCard ("supposedly in the mail") so all analysis is static disassembly + emulator; Joshua's hardware confirms predictions when needed.

Version testing isolated the boundary: **2.20 and 2.20B fail; 2.23 works**.

---

## What's Now Understood (the architecture)

End-to-end, with empirical emulator confirmation of the central question.

### The 6502 boot stage (Parts 1-4)

1. **Disk II P6 PROM** loads sector 0 of track 0 to Apple `$0800-$08FF` and `JSR $0801`.
2. **Boot stub** at `$0801-$083C` (byte-identical between 2.20 and 2.23) loads 10 more sectors of track 0 in CP/M skew order (`0,2,4,6,8,A,C,E,1,3,5`) via the P6 PROM's mid-routine entry. Then `JMP $1000`.
3. **Stage-2 loader** at `$1000`: language card RAM enable, Apple monitor TEXT/SETVID/SETKBD, three install loops staging Z-80 code into low Apple memory, then **slot scanner** at `$1060-$10D5`.
4. **Slot scanner** walks slots 7→1, probes `$Cn05/$Cn07`, records device codes at `$03B9-$03BF`. **2.23 added an 11-byte branch** that also reads `$Cn0B` (Pascal 1.1 signature) and tags Pascal-1.1 cards with device code `$06`. *This is the entire bug fix.*
5. **LOAD_CPM** at Apple `$0BEB` reads 29 sectors starting trk0:`$0B`, stages at `$8000-$9CFF`. **There's a SECOND LOAD_CPM call** that handles CCP+BDOS relocation (devlog `cpm-videx-second-load-cpm-call-2026-04-28`).
6. **PREP_HANDOFF** does three page copies splitting the staging into BIOS callbacks at `$0A00`, system image at `$A300`, original RWTS preserved at `$BA00`.
7. **Z-80 reset vector planted** at Apple `$1000-$1002`: 2.23 plants `JP $FA00`, 2.20 plants `JP $DA00`.
8. **CPU switch fires when 6502 PC reaches `$0E36`** (Part 10 / `cpm-videx-cpu-switch-trigger-2026-04-30`). Confirmed via emulator: any 6502 instruction execution at this address is monitored by SoftCard hardware and triggers the bidirectional Z-80 takeover.

### The Z-80 side (Parts 5-9)

9. **Z-80 starts at `$0000`** = Apple `$1000`, reads `JP $FA00`, jumps to BIOS cold-boot.
10. **BIOS layout is 256-byte interleaved** (4 code pages alternating with 4 runtime-generated pages — corrected from "first/second half" framing in earlier devlogs). 2.20 fills generator slots with `$E5` (= `PUSH HL`); 2.23 uses `FF FF 00 00 / F7 F7 00 00` (RST traps if executed prematurely — safety upgrade).
11. **Cold-boot real code resumes** at `$DECC` (2.20) / `$FF0E` (2.23). The post-padding device-scan loop is **structurally identical across versions** — the BIOS factory itself doesn't differ. The fix lives entirely in what device codes the loader feeds it.
12. **Cold-boot generator** populates the runtime-generated pages with per-device handler code (Part 6). For device code 4 (Pascal 1.0 generic), it generates a handler that dispatches to `$DFBE` (in 2.20) — but `$DFBE` is in a generator-padding page filled with `$E5`. For device code 6 (Pascal 1.1), 2.23 dispatches to `$FDB0` — which is a one-byte `RET` stub.
13. **Cooperative-CPU disk I/O model**: Z-80 BIOS routines write parameters into BIOS state area, call into Z-80 disk callbacks at `$1A00`, signal 6502 via `$E000`/`$E010` flag pair (polling loop at Z-80 `$1E36-$1E44`). SoftCard switches CPUs. 6502 reads same state, runs original RWTS at `$BA00-$BFFF`, deposits sector data, signals completion. SoftCard switches back. (Part 8.)

### The 2.20 hang failure mode (Parts 8 + 12, Stage-3 emulator confirmation)

Empirically: when 2.20 first issues a CONOUT for a Videx slot, BDOS jumps via the BIOS jump table to a CONOUT routine. CONOUT looks up the per-slot device code (`$04` for the Videx because 2.20 didn't run the Pascal 1.1 check). Device 4 dispatches via the cold-boot-generator-built handler to `$DFBE`. `$DFBE` is in a generator-padding page that contains nothing but `$E5` bytes (CP/M deleted-file marker, also Z-80 `PUSH HL`). The Z-80 starts executing `PUSH HL` instructions, each pushing 2 bytes onto the stack. With the stack initialized at `$0080`, after 64 PUSH instructions SP is at `$0000`; the 65th wraps SP to `$FFFE` and starts overwriting BIOS code in the high-memory area. The system corrupts itself and hangs.

2.23 detects the Videx as Pascal 1.1, assigns device code `$06`, and the cold-boot generator routes it through `$FDB0` which is a single-byte `RET` (`$C9`). CONOUT returns cleanly. Whatever real Videx-driving code lives elsewhere gets installed via a separate runtime path (the runtime-generation phase populates real handler code into the trap-marker pages before any actual I/O happens).

### Pascal 1.0 vs 1.1 calling-convention precision (Part 1)

- **Pascal 1.0**: ID bytes ARE the entry points. `$Cn05 = $38` is `SEC`; `$Cn07 = $18` is `CLC`. `JSR $Cn05` does input (carry set), `JSR $Cn07` does output (carry clear).
- **Pascal 1.1**: 4-byte vector table at `$Cn0D-$Cn10` (INIT, READ, WRITE, STATUS). Caller reads offsets, JSRs to `$Cn00 + offset`, MUST call INIT before READ/WRITE/STATUS.
- Pascal 1.1 cards declare BOTH ID sets but only implement the 1.1 calling convention.
- 2.20 sees a Videx → Pascal 1.0 ID match → naive `JSR $Cn07` → hangs (per Case B above).
- 2.23 reads `$Cn0B` → Pascal 1.1 → routes through 1.1 vector table → works.

---

## Decision Points and User Directives (still apply for any successor work)

- **Investigation path: Path A** (reverse-engineer LOAD_CPM rather than build a Z-80 emulator) chosen on 2026-04-27. Path A unlocked the static analysis. Then user directed building the emulator anyway when static evidence couldn't fully settle the v2.20 hang failure mode (2026-04-29).
- **Article structure**: each part is a beginning-to-end narrative, reads as a story.
- **Devlog granularity**: one per topic / approach / area of investigation, NOT one per day.
- **Resume-prompt.md kept current** at all times (this file).
- **Site placement**: wiseowl.com personal site (NOT wiseowlsoftware.com).
- **Article 1 framing**: opens with "The Microsoft Z-80 SoftCard wouldn't work with my Videx 80-column emulation. Seemingly."
- **Disassemblers documented as separate tools** on wiseowl.com (not bundled under nibbler), even though they share repo home in `nibbler/`.
- **Corrections, not rewrites**: when later findings refine earlier devlogs/articles, ADD a forward-pointer Update note. Don't silently rewrite the body. The misinterpretation is part of the investigation narrative.

---

## Editorial Guidance (saved to memory; restated for any successor work)

- **Lead with consequence, not detection.** The act of finding a code delta is the door, not the room.
- **State things clearly, not cleverly.** Cryptic article titles bad; descriptive ones good.
- **Honesty over completeness.** Distinguish "known from reading the code" from "plausible hypothesis pending verification."
- **Don't conflate shared address spaces with specific cards.** `$C800-$CFFF` is the Apple ][ shared expansion-ROM window. (User caught a Videx overreach on this earlier in the project.)
- **Voice for devlogs**: terse, declarative, past tense, NO first-person pronouns. Em dashes for asides. ~200-400 words. End with `**Status:**`.
- **Voice for articles**: long-form (~3000 words, 12-15 min reads), first-person allowed and natural.

---

## Website Structure (current state)

The site at `e:/Sites/wiseowl.com/` is Astro v6, deployed to Cloudflare Pages.

### Project entries (`src/content/projects/`)

- `cpm-videx.mdx` — "Microsoft SoftCard CP/M on a Videx", `featured: true, weight: 5`. **The project entry's "What's settled / open" section is stale** — written before Parts 5-12 + the emulator + cpm-from-source. May need refresh to reflect the closed state and link the successor project.
- `cpm-from-source.mdx` — **NEW project** (started 2026-04-29), `featured: true, weight: 6`. Annotated 6502 + Z-80 sources for both versions, plus a build tool that round-trips a byte-identical .DSK from chunks. Successor to cpm-videx.

### Articles (`src/content/articles/cpm-videx-NN-*.mdx`) — all 12 published

| # | Slug | Title | pubDate |
|---|------|-------|---------|
| 1 | `cpm-videx-01-why-cpm-didnt-recognize-an-80-column-card` | Why CP/M Didn't Recognize an 80-Column Card | 2026-04-26 |
| 2 | `cpm-videx-02-from-the-disk-ii-rom-to-the-z-80s-first-instruction` | From the Disk II ROM to the Z-80's First Instruction | 2026-04-27 |
| 3 | `cpm-videx-03-apple-memory-through-z-80-eyes` | Apple Memory, Through Z-80 Eyes | 2026-04-27 |
| 4 | `cpm-videx-04-the-handoff` | The Handoff | (renumbered) |
| 5 | `cpm-videx-05-the-bios-that-half-exists` | The BIOS That Half-Exists | (was Part 4 originally) |
| 6 | `cpm-videx-06-the-bios-factory` | The BIOS Factory | |
| 7 | `cpm-videx-07-from-reset-to-device-scan` | From Reset to Device Scan | |
| 8 | `cpm-videx-08-cooperative-cpu` | Cooperative CPU | |
| 9 | `cpm-videx-09-every-difference` | Every Difference (categorical 2.20 vs 2.23 inventory) | |
| 10 | `cpm-videx-10-the-cpu-switch` | The CPU Switch (`JSR $0E36` trigger; original series close) | |
| 11 | `cpm-videx-11-emulator-verified` | Verifying It in the Emulator (Stages 1+2) | 2026-05-01 |
| 12 | `cpm-videx-12-the-investigation-closes` | The Investigation Closes (final reading guide) | 2026-05-02 |

### Dev logs (`src/content/devlogs/cpm-videx-*.mdx`) — 39 published

Recent emulator-era entries (most relevant for follow-up work):
- `cpm-videx-emulator-stage1-2026-04-29` — 6502 boot harness boots both versions
- `cpm-videx-emulator-stage2-2026-04-29` — Z-80 emulator + SoftCard XOR + CPU-switch model
- `cpm-videx-emulator-stage3-detection-2026-04-30` — Videx slot-3 model + IX/IY opcodes
- `cpm-videx-emulator-220-architecture-2026-04-30` — 2.20 emulator boot architecture
- `cpm-videx-emulator-coldboot-generator-2026-05-01` — cold-boot generator runs in emulator
- `cpm-videx-emulator-220-hang-settled-2026-05-01` — **Case B confirmed** (PUSH HL stack overflow)
- `cpm-videx-cpu-switch-trigger-2026-04-30` — `JSR $0E36` mechanism
- `cpm-videx-rwts-disassembly-2026-04-29` — full 6502 RWTS at $0A00-$0FFF classified
- `cpm-videx-220-hang-byte-trace-2026-04-29` — factual byte-level static trace (pre-emulator)
- `cpm-videx-cold-boot-generator-found-2026-04-28` — generator at `$FB3A` (2.23) / `$DB6E` (2.20)
- `cpm-videx-220-vs-223-coldboot-2026-04-28` — cold-boot side-by-side
- `cpm-videx-bios-jump-table-correction-2026-04-28` — corrects BOOT-vs-LIST confusion
- `cpm-videx-fdb0-stub-2026-04-28` — `$FDB0` is a single `RET`
- `cpm-videx-device-scan-identical-2026-04-28` — device-scan structurally identical 2.20 vs 2.23

(See `ls e:/Sites/wiseowl.com/src/content/devlogs/cpm-videx-*` for the full chronological list of all 39.)

### Reference (`src/content/reference/`)

- `apple-ii-tn-misc-8-pascal-1-1-firmware-protocol.mdx` — full text of Apple Tech Note Misc #8
- `cpm-videx-disk-sector-map.mdx` — 560-row map of every physical sector → role → final address. Pointer to `docs/CPM_DiskSectorMap.md` in the Orchard repo. **The natural capstone reference.**
- `videx-videoterm-manual.mdx`, `thunderclock-plus-manual.mdx` — pre-existing
- `public/reference/apple-ii-technical-notes-1989-09.pdf` — source PDF

### Tools (`src/content/tools/`)

- `nibbler.mdx` — WOZ analysis toolkit
- `6502-disassembler.mdx` — standalone 6502 disasm
- `z80-disassembler.mdx` — standalone Z-80 disasm

### Frontmatter constraints (build will fail if violated)

- Devlog `tldr` ≤ 200 chars
- Article `description` ≤ 300 chars
- Project `summary` ≤ 300 chars
- `tags` from `TagEnum` only (in `src/content.config.ts`); add new tags to enum BEFORE using
- Numeric-prefix tags (`6502`) MUST be quoted as `"6502"` in YAML block-style arrays

### Build / deploy

- Local build: `npm run build`
- Build + deploy to Cloudflare Pages: `npm run deploy` (= `astro build && wrangler pages deploy dist --project-name wiseowl`)
- Wrangler is globally installed.

### Site wordmark

- "Wise Owl — Brent Rector" (NOT "Wise Owl Software" — that's the separate product site).

---

## Repository Conventions

### Orchard repo (`e:/Orchard/`)

```
cpm-investigation/        — extraction scripts, intermediate binaries, disassemblies,
                            emulator (added 2026-04-29), build harness for cpm-from-source

docs/
  CPM_Videx_Difference.md           — slot scanner side-by-side diff
  CPM_BootLoader.md                 — narrative architecture of the 6502 loader
  CPM_DiskSectorMap.md              — 560-row map of every physical sector
  CPM_Filesystem.md                 — CP/M filesystem area (tracks 3-34) overview
  CPM223_BootLoader.asm             — annotated 6502 disasm, 2.23
  CPM223_RWTS.asm                   — annotated 6502 RWTS at $0A00-$0FFF (43 KB)
  CPM223_BIOS.asm                   — annotated Z-80 BIOS at $FA00-$FFFF
  CPM223_DiskCallbacks.asm          — annotated Z-80 disk callbacks at $1A00-$1BFF
  CPM223_SystemImage.asm            — annotated Z-80 CCP+BDOS at $A300-$B9FF
  CPM223_InstallFragments.asm       — Z-80 fragments installed by stage-2 loader
  CPM220_*.asm                      — same set for 2.20 (BootLoader, BIOS, RWTS, SystemImage, InstallFragments)
  DiskII_BootROM.md / .asm          — Apple Disk II P6 PROM (pre-existing)

nibbler/                  — Apple ][ disk analysis toolkit
  z80.py                    — Z-80 disassembler (256 unprefixed; CB/DD/ED/FD now also covered)
  z80_cpu.py                — Z-80 emulator (added; covers DD/FD per recent commit)
  cli.py                    — `disasm` (6502) + `z80disasm` subcommands; both support `--format asm`
                              for directly-compilable output

CPMV233.DSK               — CP/M 2.23 disk image (DOS 3.3 sector order — V233 is a misnomer for 2.23)
CPM220Disk1.po            — CP/M 2.20 distribution disk 1 (ProDOS sector order)
CPM220Disk2.po            — CP/M 2.20 distribution disk 2

resume-prompt.md          — THIS FILE
```

---

## Memory Directory

`C:/Users/brent/.claude/projects/e--Orchard/memory/` contains semantic project memory:

- `MEMORY.md` — index (auto-loaded)
- `project_cpm_videx_investigation.md` — investigation status
- `reference_apple_pascal_firmware_protocol.md` — Pascal 1.1 protocol + Tech Note Misc #8
- `reference_wiseowl_devlogs.md` — devlog conventions, schema, voice
- `feedback_finding_vs_consequence.md` — editorial: don't celebrate detection
- `feedback_apple_ii_address_specificity.md` — editorial: don't conflate shared address spaces with specific cards
- `feedback_devlog_corrections.md` — editorial: forward-pointer Update notes, don't silently rewrite

---

## What's Done / What Could Still Be Done

The cpm-videx investigation itself is **closed** — the central question is settled and emulator-verified, the article series has a closing reading guide (Part 12), all major boot-pipeline mechanisms are documented.

Two architectural mechanisms remain unmodeled but bounded (worth noting if anyone resumes):

1. **`$03B8` → `$F3B8` slot-info copy.** The 6502-side device-code table at `$03B9-$03BF` somehow ends up readable by the Z-80 BIOS at `$F3A0`+ in its device-scan loop. The copy step itself isn't traced. Likely happens via the runtime-population step or an early Z-80 BIOS routine.

2. **`bios_223.bin` → `$FAB8` BIOS load.** The 1 KB of BIOS bytes that come from the LOAD_CPM staging end up at Apple `$0C00-$0FFF` after PREP_HANDOFF. They get copied to LC RAM at `$FAB8-$FEB7` somewhere, but the exact 6502 (or Z-80) instruction that does this is unmapped. Probably a routine in the install fragments at `$0200-$03FF` runs after the SoftCard switch and before BIOS cold-boot.

Both fit a future "bidirectional CPU switch + LC RAM bank" emulator pass that fully models the SoftCard's switching protocol and the language card's bank semantics. Not blocking anything currently.

The successor project, `cpm-from-source`, takes a different angle: instead of further investigating the runtime mechanisms, it captures everything-as-source. It produces annotated 6502 + Z-80 listings that compile with a build tool to a byte-identical .DSK image. That's where ongoing work lives.

---

## Quick-Reference Address Map (for fast context recovery)

### Apple ][ memory after the loader finishes

- `$0800-$08FF`: boot stub (sector 0)
- `$0A00-$0FFF`: Z-80 disk callbacks + BIOS first 1 KB (depending on version layout)
  - 2.20: BIOS first 1 KB at `$0A00-$0DFF`, callbacks at `$0E00-$0FFF`
  - 2.23: callbacks at `$0A00-$0BFF`, BIOS first 1 KB at `$0C00-$0FFF`
- `$1000-$1002`: Z-80 reset vector (`$C3 $00 $FA` for 2.23, `$C3 $00 $DA` for 2.20)
- `$0200-$03FF`: Z-80 install fragments (warm-boot routine at `$03C0`)
- `$03B9-$03BF`: per-slot device codes (built by slot scanner)
- `$A300-$B9FF`: CCP + BDOS + banner string (from sysimg)
- `$BA00-$BFFF`: original 6502 RWTS routines (preserved by PREP_HANDOFF #1; see `docs/CPM223_RWTS.asm` for byte-by-byte map)

### Z-80 memory after CP/M is running

- `$0000-$0002`: Z-80 reset vector (`JP $FA00` planted by 6502; rewritten to `JP $FA03` after first cold-boot)
- `$0003-$00FF`: Z-80 zero page / restart vectors
- `$0100-$E3FF`: TPA (Transient Program Area)
- `$E400-$EBFF`: CCP (after relocation)
- `$EC00-$F9FF`: BDOS (after relocation)

**BIOS at `$FAB8-$FFFF` uses 256-byte interleaved layout** (4 code pages alternating with 4 runtime-generator pages):
- `$FAB8-$FBB7`: code page (jump table, inline LISTST/SECTRAN, dispatch table area, internal routines)
- `$FBB8-$FCB7`: generator page (`FF FF 00 00 / F7 F7 00 00` on disk → real handler code at runtime)
- `$FCB8-$FDB7`: code page
- `$FDB8-$FEB7`: generator page (`$FDB0` is in this page's tail — the device-6 dispatch target, a `RET` stub on disk)
- `$FEB8-$FFB7`: code page (BOOT vector target `$FED1` is in this page's runtime-generated prefix; real code at `$FF0E`+ is the device-scan loop)
- `$FFB8-$FFFF`: generator page (per-device handler code)

**Per-device state slots** (in runtime-generated regions): `$FECB` track, `$FED2` sector, `$FED4` DMA, `$FECD` cold-boot state byte.

**2.20 BIOS at `$DACC-$E2FF`** uses the same 256-byte interleave with `$E5` filler in generator pages. BOOT vector `$DEA8`, real code resumes at `$DECC`. Device-4 dispatch target `$DFBE` is in a `$E5`-filled generator page — that's the v2.20 hang trigger.

### SoftCard memory mapping (bit-12 XOR for low addresses only)

- Z-80 `$0000-$0FFF` ↔ Apple `$1000-$1FFF`
- Z-80 `$1000-$1FFF` ↔ Apple `$0000-$0FFF`
- Z-80 `$2000-$FFFF` ↔ Apple `$2000-$FFFF` (no swap)

### Key 2.20 vs 2.23 differences

- **Slot scanner**: 2.23 has 11 extra bytes for the Pascal 1.1 check; produces device code `$06` for Videx instead of `$04`
- **Cold-boot generator dispatch**: device 4 → `$DFBE` (`$E5` fill = `PUSH HL` spam, hangs); device 6 → `$FDB0` (`RET` stub, returns cleanly)
- BIOS load address: 2.20 at `$DACC`, 2.23 at `$FAB8` (8 KB shift)
- BIOS jump table in staging: 2.20 at offset `$1700`, 2.23 at `$1900`
- BIOS first 1 KB final position in newdisk: 2.20 at start (`$0A00`), 2.23 at end (`$0C00`)
- Boot banner string: present in 2.23, absent in 2.20
- Generator-page filler pattern: 2.20 uses `$E5` (executes as `PUSH HL` if reached); 2.23 uses `FF FF 00 00 / F7 F7 00 00` (executes as RST traps — safety upgrade against this exact bug class)

### CPU switch mechanism

- **Trigger**: 6502 PC reaches `$0E36`. SoftCard hardware monitors this address and flips to Z-80 (Part 10 / `cpm-videx-cpu-switch-trigger-2026-04-30`).
- **Direction**: bidirectional (Z-80 can flip back to 6502). The cooperative-CPU disk model in Part 8 documents the round-trip.
