# SoftCard Real Address Map — Findings (2026-06-11, session in progress)

**Status: WORKING NOTES — major model correction, partially verified by
emulation, not yet propagated to docs/articles.** This file is the
authoritative record of the 2026-06-11 session's findings. The session
ended mid-investigation (host reboot); resumed the same day — see
**"Session continuation (2026-06-11, after host reboot)"** at the bottom
for the resolution of every open item below, INCLUDING THE OVERTURN OF
THE PUBLISHED 2.20 HANG MECHANISM.

## Headline

Both "unmodeled mechanisms" from the investigation closure (Part 12 /
`CPM_BootTrace.md` Unknowns 1 & 2) are **dissolved, not solved**: there
is no copy code at all. The missing piece was the SoftCard's documented
Z-80 → Apple address translation, which the investigation's bit-12-XOR
model got wrong above $2000:

| Z-80 address  | Apple address | Note |
|---------------|---------------|------|
| `$0000-$AFFF` | `$1000-$BFFF` | +$1000 (contiguous TPA) |
| `$B000-$DFFF` | `$D000-$FFFF` | +$2000 (language-card region) |
| `$E000-$EFFF` | `$C000-$CFFF` | I/O page + slot space |
| `$F000-$FFFF` | `$0000-$0FFF` | -$F000 (Apple ZP/stack/text/pages 8-15) |

Empirical confirmation: `cpm-investigation/emu_softcard_v2.py`
(bidirectional CPU switching + this map) boots CPMV233.DSK from disk
bytes alone to the authentic banner on an emulated Videx (real firmware
ROM execution):

```
     Softcard CP/M
     44K Ver. 2.23
(c) 1980,1982 Microsoft

A>
```

with the warm-boot vector rewrite ($0000: JP $FA00 → JP $FA03) observed.

## Consequences (each needs doc/article corrections)

1. **Unknown 1 (slot info $03B8 → $F3B8):** no copy. Z-80 `$F3B8+E` IS
   Apple `$03B8+E` through the `-$F000` window. Verified: Videx slot 3
   device code 6 read directly at `$F3BB` (= `$03BB`).

2. **Unknown 2 (BIOS load to $FAB8):** no load. The 2.23 BIOS lives at
   Z-80 `$FA00-$FFFF` = Apple `$0A00-$0FFF` — exactly where PREP_HANDOFF
   staged it. For 2.20 the BIOS at Z-80 `$DA00+` = Apple `$FA00+` (LC
   RAM, +$2000 window), written there by the 6502 loader directly
   (observed in post-boot memory: jump table `JP $DEA8 / JP $DACC / ...`
   at Apple `$FA00`). The "8 KB shift" between versions is really a move
   between two different SoftCard mapping windows.

3. **BIOS base off-by-$B8 (2.23) / off-by-$CC (2.20).** The BIOS jump
   table is at Z-80 `$FA00` (2.23) / `$DA00` (2.20), NOT `$FAB8`/`$DACC`.
   Evidence: memory at Apple $0A00 holds the 17-entry jump table
   (BOOT→$FED1, WBOOT→$FAB8, ...); reset vector `JP $FA00` lands on the
   BOOT entry; warm rewrite `JP $FA03` = the WBOOT entry (3 bytes in) —
   finally explains the +3. The 256-byte page interleave aligns to TRUE
   page boundaries ($FA00/$FB00/...), not $xxB8.
   - `docs/CPM223_BIOS.asm` (ORG $FAB8) and `CPM220_BIOS.asm` (ORG $DACC)
     still round-trip byte-identical (bytes are right) but every address
     comment/label is shifted; cross-references between JP/CALL targets
     and the prose "routine at that address" are off by $B8/$CC.
   - `cold_boot_trace.py`'s reported org and `CPM223_DiskCallbacks.asm`'s
     "$1A00 disk callbacks" / "dual-mapped" framing are artifacts of the
     XOR model (Apple $0A00 viewed at Z-80 $1A00). One region, one copy.
   - Claims like "$FDB0 is a one-byte RET stub" are WRONG at the true
     address: $FDB0 (= Apple $0DB0) holds real delegation code
     (LD A,E / LD ($F047),A / JP $FB45). The 2.20 "$DFBE lands in $E5
     fill" hang chain must be RE-VERIFIED under the corrected base
     (high-level conclusion likely survives; addresses won't).

4. **CPU-switch trigger is NOT a fetch at $0E36.** The warm-boot loop's
   actual bytes (annotation in CPM223_InstallFragments.asm was wrong,
   read $03C6 as STA $FFFF):
   ```
   $03C0: AD 83 C0  LDA $C083      ; LC write-enable x2
   $03C3: AD 83 C0  LDA $C083
   $03C6: 8D 00 C7  STA $C700      ; ← BUS FLIP (slot 7 I/O space)
   $03C9: AD 81 C0  LDA $C081
   $03CC: 20 36 0E  JSR $0E36      ; restore A,X,Y,P from $45-$48; RTS
   $03CF: 20 58 FF  JSR $FF58      ; ← operand $03D0/$03D1 is PATCHED
                                   ;   BY THE Z-80 to the service routine
   $03D2: 8D 81 C0  STA $C081
   $03D5: 78        SEI
   $03D6: 20 4A FF  JSR $FF4A      ; save A,X,Y,P to $45-$48
   $03D9: 4C C0 03  JMP $03C0
   ```
   Z-80 side flips back via `LD ($E700),A` (Apple $C700 through the I/O
   window). 2.20 ships `STA $C400` (slot 4) in its loader image at
   $13C6; the installed copy at $03C6 is patched to $C700 — the SoftCard
   slot is configured at install time (patcher not yet located).
   $0E36 holds plain 6502 code (`A5 48 48 A5 45 A6 46 A4 47 28 58 60`).
   Part 10's trigger story needs an Update note.

5. **Cooperative-CPU protocol (now fully read):** Z-80 RPC to the 6502 =
   (a) write 6502 A,X,Y,P into $45-$48 (monitor SAVE slots) via Z-80
   $F045-$F048; (b) patch the JSR operand at $03D0/$03D1 (Z-80 $F3D0)
   with the 6502 service-routine address; (c) touch $E700. Results
   return in $45-$48 (6502 JSR $FF4A saves; Z-80 reads $F045+).
   - 6502 service routines live at Apple $0DD0-$0E35 (= Z-80 $FDD0+,
     a 6502 code island INSIDE the shared BIOS pages): a textbook
     Pascal 1.1 firmware client ($CFFF deselect, $Cn0D-$Cn10 vector
     dispatch, screen-hole $06F8 = $n0): $0DD0 INIT, $0DE1 WRITE
     (CONOUT), $0E06 READ (CONIN, with status-wait), $0E14 STATUS,
     $0E1D common setup. Disk services: $0E00 `JMP $BBE9`, $0E03
     `JMP $BE04` (into preserved RWTS).
   - Z-80 reads the Apple keyboard DIRECTLY: poll $E000 (= $C000) bit 7,
     strobe clear at $E010 (= $C010) — at $FB39-$FB44. The Part 8
     "$E000/$E010 sync flag pair" was a misreading of keyboard I/O.

6. **"BIOS factory" nuance:** at switch time the generator pages already
   contain real code (staged by the 6502 loader); the cold-boot
   generator's observed writes are sparse per-device PATCHES (vector
   fixups, e.g. the $E700 operand, per-device dispatch operands), not
   wholesale page generation. Part 6's framing needs softening
   ("linker doing fixups" more than "factory writing handlers").

## New emulator assets

- `cpm-investigation/emu_softcard_realmap.py` — one-shot probe: 6502
  boot phase (reusing emu_softcard_full), then Z-80 from reset under the
  real map, with write attribution. First demonstrated cold boot
  reaching BDOS.
- `cpm-investigation/emu_softcard_v2.py` — THE bidirectional emulator:
  real map, $C700-access bus flip both directions (armed only from the
  warm loop at PC<$0400; the slot scanner's $Cn00 probe writes must not
  flip), 6502 resume-past-STA, Videx VRAM paging (2 KB, 512-byte window
  at $CC00 selected by A2-A3 of $C0B0-$C0BF access, CRTC regs R12/R13
  drive the screen decode), keyboard injection (--keys "DIR\r").

## Where it stopped (resume here)

Typed input is consumed but the echo path returns stale `$45` values
('>' repeats): steady-state Z-80 loop = CONST($0E14) / CONOUT($0DE1) /
CONIN($0E06) with CONIN's result reading back the previous CONOUT char.
LAST FINDING: the apparent CONIN staleness coincides with the 6502
entering the REAL RWTS for the drive-A login (directory read) — PC
observed in SEEK_TRACK/STEP_DELAY helpers ($BBC1 area, $46 step counter
climbing). The runtime disk path uses nibbler's DSKDisk nibble streams
(same as boot-time LOAD_CPM, which worked), so suspicion is on seek
timing helpers (MON_WAIT $FCA8 is stubbed RTS; check whether RWTS
seek/settle relies on something else not modeled, or whether motor-on
state machine wedges). NEXT STEPS:
1. Instrument step_phase/current_qtrack + the RWTS retry loop; find why
   the directory read doesn't complete; fix the v2 model.
2. Then re-test "DIR\r" end-to-end (expect directory listing on the
   Videx screen).
3. Run 2.20 (CPM220Disk1.po) under v2 WITH Videx → re-verify the hang
   mechanism at corrected addresses (device 4 dispatch target, what's
   really at the dispatch landing, whether PUSH-HL/SP-wrap story holds).
   Note 2.20's 6502 phase currently halts at $FF51 in v1-style runs —
   needs its own attention (different warm-loop body: JSR $FF3F restore,
   JSR $1010 island).
4. Also locate: who patches $03C7/$03C8 (slot byte) at install time, and
   re-derive the true code/gen page interleave + cold-boot generator
   address (true generator entry ≈ $FA82, was "Apple $0A82 = Z-80
   $1A82" in old docs; CALL $FB45/$FA82 observed from $FAC1).
5. Then the documentation cascade (see Corrections inventory above),
   devlogs + Update notes per the corrections-not-rewrites directive,
   pipeline `cold_boot_trace.py` org fix, CPM223_BIOS.asm re-basing
   decision (keep bytes, shift ORG/labels/comments — big but mechanical,
   round-trip tests protect it).

## Evidence quick-reference (post-6502-phase memory, CPMV233.DSK)

- $03B8-$03BF: `02 00 00 06 00 00 02 00` (slot 3 = Videx = device 6)
- $0A00: `C3 D1 FE C3 B8 FA C3 10 FB ...` (BIOS jump table, 17 entries)
- $0AB8: `31 80 00 3A 51 E0 21 00 0E CD 45 FB CD 82 FA 3A 08 9C FE 9C`
  (WBOOT: LD SP,$0080 / LD A,($E051)=TEXTON / ... / CALL $FB45 /
  CALL $FA82 / BDOS sentinel LD A,($9C08) CP $9C)
- $0E36: `A5 48 48 A5 45 A6 46 A4 47 28 58 60` (6502 restore island)
- $1000-$1002: `C3 00 FA` cold; `C3 03 FA` after first Z-80 cold boot
- 2.20 post-phase: Apple $FA00: `C3 A8 DE C3 CC DA C3 08 DB ...`
  (2.20 jump table in LC RAM; BOOT→$DEA8, WBOOT→$DACC)

---

# Session continuation (2026-06-11, after host reboot)

All four "Where it stopped" items resolved. The fourth resolved with a
result that overturns the investigation's published central conclusion.

## 1. Runtime disk reads fixed (sector-level RWTS service)

The RWTS seek wedge was bypassed rather than diagnosed (user decision):
all 2.23 disk I/O — boot-time LOAD_CPM and the runtime cooperative RPC
path alike — funnels through the sector-read primitive LOAD_CPM_PRIM at
$BE11 in LC RAM. `emu_softcard_v2.py` now hooks $BE11 and services the
request straight from the .dsk image (same approach as the boot-time P6
hook). Contract captured from docs/CPM223_RWTS.asm:

- `$03E0` track, `$03E1` CP/M-logical sector (physical via the skew
  table at $BF9E), `$03E8/$03E9` destination pointer, `$03E4` drive
  (bit 0 = drive 1), `$03EB` bit 0 = read; returns carry + $03EA.
- `--real-rwts` preserves the old nibble-level path.

2.20's RWTS lives at different addresses ($BE11 hook never fires); its
runtime reads run the real nibble path and work.

## 2. Stale-echo fixed (monitor SAVE/RESTORE were stubs)

The `'>'`-repeats symptom was the emulator's own stub: the warm loop's
`JSR $FF4A` (monitor SAVE) was an RTS stub, so the 6502's A register
never landed in the $45-$48 RPC result slots and Z-80 CONIN read back
the previous CONOUT character. v2 now emulates monitor SAVE ($FF4A),
RESTORE ($FF3F), and the other stubbed entries as PC hooks that run
"from ROM" regardless of RAM content at those addresses — which also
dissolves the 2.20 $FF51 halt (Apple $FF4A = Z-80 $DF4A is INSIDE
2.20's LC-RAM BIOS; on real hardware the warm loop's $C081/$C083 dance
banks ROM/RAM so both coexist; the flat model needed the hooks).

**Result: 2.23 boots from disk bytes to a fully interactive system —
`DIR` typed at the A> prompt prints the complete directory through the
real Videx firmware ROM on the emulated Videoterm.**

## 3. 2.20 re-verification — PUBLISHED HANG MECHANISM OVERTURNED

With the corrected map + monitor hooks, **CPM 2.20B boots to its banner
("Apple ][ CP/M / 56K Ver. 2.20B / (C) 1980 Microsoft") and runs DIR to
completion with the Videx installed and detected as device 4** — under
the flat (always-mapped) $C800 window model. The PUSH-HL/SP-wrap hang
does NOT reproduce. The v1 "byte-for-byte confirmation" was an artifact
of the XOR address map (the Z-80 was executing through a scrambled view
of memory).

What 2.20 actually does with device 4 (traced live):

- The Z-80 BIOS patches the warm-loop JSR operand ($03D0/$03D1, Z-80
  $F3D0) with the Apple Pascal 1.0 FIXED firmware entry points, which
  live inside the shared $C800-$CFFF expansion-ROM window:
  `$C800` (INIT, first RPC), `$C9AA` (WRITE/CONOUT), `$C84D`
  (READ/CONIN). NOT `JSR $Cn05/$Cn07` as published in Article 1.
- Character passing uses Apple $45-$48 register slots plus screen hole
  $0678+slot; results return the same way.
- 2.20's Z-80-side RPC setup at $DCEA/$DCEE (Z-80 addresses; Apple
  $FCEA+) performs the TEXTBOOK ownership dance before each console
  RPC: `LD A,($EFFF)` (Apple $CFFF — deselect all expansion ROMs), then
  `LD A,(HL)` with HL=$E300 (Apple $C300 — select the Videx), then RET
  to the dispatcher at $DB3B/$DB3E that patches the operand and flips
  the bus via $E700.

## 4. The real failure mechanism: $C800 window ownership vs the CPU switch

The Videoterm claims the $C800-$CFFF expansion-ROM window when its own
$C3xx page is accessed and releases it on $CFFF — **and on any access
to a different slot's $Cnxx page** (`other_slot_c8`, per the A2FPGA
implementation that was validated against real hardware; see
wiseowl.com article `a2fpga-videx-02`, "C8-space ownership").

The SoftCard's CPU switch IS an access to another slot's page: $C700
(slot 7; 2.20 ships $C400 and the installed copy is patched). So:

- **2.20**: Z-80 claims via $E300 → Z-80 flips the bus via $E700 →
  **the flip releases the claim it just made** → 6502 enters
  `JSR $C800/$C84D/$C9AA` with the window unowned → on real hardware,
  floating-bus fetch → garbage execution → blank screen / dead system
  = "2.20 doesn't boot with a Videx."
- **2.23**: the Pascal 1.1 client island does the dance on the 6502
  side, AFTER the flip: `$CFFF` deselect at $0E30, `$C330` claim at
  $0E33, then the $Cn0D-$Cn10 vector dispatch enters the firmware
  through the $C3xx slot page. The claim survives to the fetch. Zero
  faults.

Emulator demonstration (v2 with `other_slot_c8` arbitration, log-only
faults, floating reads = $FF):

- 2.20 + Videx: **38,069,715 window faults; 0 characters reach the
  Videx screen** (every VRAM write discarded as unowned). First faults:
  6502 fetches at $C800, $C803, ... — the INIT entry executed from an
  unowned window. Ownership log shows the exact kill sequence repeating:
  `claim z80 $C300 (PC=$DD03)` → `release z80 $C700 (PC=$DB41)`.
- 2.23 + Videx: **0 faults**, banner + DIR all the way through, with
  per-call `release $CFFF (PC=$0E30)` / `claim $C330 (PC=$0E33)` pairs.

**So the 2.23 fix is two-part, and the detection half is the smaller
half:** (a) the 11-byte $Cn0B check detects Pascal 1.1 cards as device
6; (b) the device-6 path routes console I/O through a 6502-side island
that performs the expansion-ROM ownership handshake on the correct side
of the CPU switch. 2.20's structure (ownership dance on the Z-80 side,
firmware entered at fixed $C8xx addresses) cannot work behind a
SoftCard, because the SoftCard's own switch access destroys the claim.

### Honesty inventory (what's demonstrated vs. inferred)

- DEMONSTRATED (v2 emulator, real disk bytes, real Videx ROM 2.4 — the
  same image the A2FPGA uses): everything above.
- INFERRED for real hardware: that the physical Videoterm releases the
  window on other-slot access. Evidence: the A2FPGA implements this and
  the original failure was reported on A2FPGA *and confirmed on a real
  Videoterm*; Apple Pascal 1.3 + the 2.23 protocol work on both.
  Schematic-level confirmation from the Videoterm manual still pending.
- The published story (device 4 → Z-80 dispatch to $DFBE → $E5 fill →
  PUSH HL → SP wrap) is DE-CONFIRMED: under the real map those
  addresses/contents were XOR-model artifacts, and the actual device-4
  path never executes Z-80-side handler code at those locations.
- The byte-level STRUCTURAL deltas published earlier (11-byte scanner
  branch; dispatch case 6 only in 2.23; `cases_only_in_b: [6]` from
  `cpm_pipeline diff`) remain TRUE. What changes is the failure
  mechanism and the meaning of the dispatch targets.

## Remaining loose ends — RESOLVED 2026-06-11 (same-day continuation #2)

1. **Slot-byte patcher: FOUND.** The warm loop ships with a placeholder
   operand (`STA $FFFF` in 2.23's install image — the old
   InstallFragments annotation faithfully read it; `STA $C400` in
   2.20's). The stage-2 SLOT SCANNER patches it when it identifies the
   SoftCard's slot: `STY $03C8` (Y=$Cn of probed slot) / `LDA #$00 /
   STA $03C7` at $1086-$1090 (2.23; writes observed from PC $1088 and
   $108D) and the analogous code in 2.20 (writes from $1081/$1086).
2. **Interleave/generator re-derivation: the interleave is DEAD, not
   re-based.** Page provenance (snapshot at first Z-80 instruction,
   exact-match search against the raw disk): the ENTIRE 2.23 runtime
   BIOS arrives verbatim from track 2 file-sectors 13..8 (descending,
   one page each → Z-80 $FA00..$FF00); 2.20's from track 2 sectors 1..5
   ascending (→ $DA00..$DE00; $DF00 assembled during the 6502 phase;
   duplicate copies on track 5). Cold boot then changes only
   4/4/2/0/45/130 bytes per page (2.23) and 3/3/2/3/82/86 (2.20) — a
   sparse fixup pass concentrated in the last two pages. There are no
   runtime "generator pages"; Part 5's "BIOS that half-exists" and the
   $E5/trap-fill placeholder framing were artifacts of extracting wrong
   disk regions under the wrong base. The disk filler regions' true
   role (padding/workspace) → chunk-map question, still open.
3. 2.20 `--no-videx` run halts in v2 at $FC59 — MODEL GAP (missing
   monitor HOME/CLREOP-family stubs for the 40-col console path), not a
   CP/M finding; real hardware boots 2.20 without Videx. Still open.
4. **Videoterm manual: CHECKED (better than schematic).** The manual's
   own example code mandates SETREGS — `STA $CFFF` ("TURN OFF
   CO-RESIDENT ROMS") + `STA $C300` ("SELECT CO-RESIDENT ROM IN SLOT
   3") + screen holes $6F8=$30/$7F8=$C3 — immediately before EVERY
   entry into $C800 space. Symbol table confirms the 2.20 RPC targets
   by name: SETUP=$C800, KEYIN2=$C84D, PSOUT=$C9A7 (entry $C9AA = char
   already in hole), BYTE=$0678 "I/O BYTE FOR PASCAL ENTRIES",
   CRFLAG=$0478. Pascal 1.1 vectors: INIT=$C311, READ=$C314,
   WRITE=$C31C, STATUS=$C322. The hardware other-slot release trigger
   remains inferred (A2FPGA-implemented, symptom-matched on real
   hardware); the protocol violation is now manual-documented
   regardless.
5. The $0478 screen-hole double-use (Videx CRFLAG `LSR $0478` at $C9AA
   vs. RWTS current-track scratch) — real but benign for CP/M's flow
   (RWTS reloads $0478 from the per-slot hole before each seek).

## New emulator assets (this continuation)

- `emu_softcard_v2.py` grew: $BE11 sector-level disk service
  (`--real-rwts` to disable), monitor-entry PC hooks (SAVE/RESTORE
  real, rest RTS), $C800-$CFFF ownership arbitration with fault +
  transition logging (`--flat-c800` to disable), fetch coverage via PC
  hooks over $C100-$CFFF (chains the P6 hook at $C65C).
- `cpm-investigation/videx_rom24.s` — disasm6502 output of Videx ROM
  2.4 with the Pascal 1.0 entries ($C800 INIT path with CRTC register
  table + AN0 video switch, $C84D READ with keyboard poll, $C9AA WRITE)
  annotated by the apple2 symbol table.

## Doc-correction cascade — EXPANDED scope (pending user review)

Everything in the original "Consequences" list above, PLUS:

- Part 12 "the investigation closes" settled-mechanism claim, the
  `cpm-videx-emulator-220-hang-settled-2026-05-01` devlog ("Case B
  confirmed"), Part 8's hang chain, Article 1's `JSR $Cn07` claim, and
  every restatement of the PUSH-HL story — all need forward-pointer
  Update notes per the corrections-not-rewrites directive.
- The resume-prompt "Key 2.20 vs 2.23 differences" and "What's Now
  Understood" sections.
- `cpm_pipeline` cold_boot_trace org fix unchanged in scope; the diff
  output's MEANING (what case 6 buys) needs re-description in docs.
