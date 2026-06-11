# SoftCard Real Address Map — Findings (2026-06-11, session in progress)

**Status: WORKING NOTES — major model correction, partially verified by
emulation, not yet propagated to docs/articles.** This file is the
authoritative record of the 2026-06-11 session's findings. The session
ended mid-investigation (host reboot); resume from "Where it stopped"
below.

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
