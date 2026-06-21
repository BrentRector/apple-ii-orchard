# SoftCard CP/M RWTS interface (the `$03E0-$03EB` parameter block)

Reverse-engineered from the embedded 6502 disk drivers and their Z-80 callers
(COPY/FORMAT/RW13/APDOS/CPM56 in `CPMV220-44K/utilities/*_6502.s` + the matching
`.asm`). The transient utilities do raw disk I/O by filling a small parameter block in
the SoftCard I/O Configuration Block, arming `A_VEC` ($F3D0) with the 6502 RWTS entry,
and triggering the 6502 with a write to `Z_CPU` ($F3DE). The 6502 reads the same cells.

The block lives at Apple `$03E0-$03EB` = Z-80 `$F3E0-$F3EB` (the config block is Apple
`$0200-$03FF` = Z-80 `$F200-$F3FF`). Named in `softcard/include/apple_softcard.inc`.

## Caller parameter block

| Z-80 | Apple | name | role |
|------|-------|------|------|
| `$F3E0` | `$03E0` | `DSK_TRACK` | track number (incremented by the caller when the sector wraps) |
| `$F3E1` | `$03E1` | `DSK_SECTOR` | logical sector; the driver maps it to a physical sector via the interleave table |
| `$F3E4` | `$03E4` | `DSK_DRIVE` | drive / unit (1 or 2) |
| `$F3E6` | `$03E6` | `DSK_SLOT` | disk-controller slot, as `slot# << 4` (e.g. `$60` = slot 6; indexes `$C08C,X`) |
| `$F3E8` | `$03E8` | `DSK_BUFFER` | DMA buffer pointer low byte |
| `$F3E9` | `$03E9` | `DSK_BUFFER_HI` | DMA buffer pointer high byte (advanced one page per sector) |
| `$F3EA` | `$03EA` | `DSK_STATUS` | result: `0` = OK, `$10` = write-protected |
| `$F3EB` | `$03EB` | `DSK_COMMAND` | `1` = read; other = write/format |

Canonical setup, from CPM56's multi-sector read loop (`$09AD`):

```
        LDA #$E4 / STA $03E9      ; buffer = $E400
        LDY #$00 / STY $03E8
        STY $03E0                 ; track  = 0
        INY / STY $03E4           ; drive  = 1
        STY $03EB                 ; command = 1 (read)
        LDA #$60 / STA $03E6      ; slot 6 (<<4)
        LDA #$0B / STA $03E1      ; sector = 11 (start)
loop:   JSR <RWTS>                ; do one sector
        INC $03E9                 ; next buffer page
        LDX $03E1 / INX / CPX #$10 ; sector++
        BNE +
        LDX #$00 / INC $03E0      ;   wrap: sector=0, track++
+       STX $03E1
        ...decrement local count, loop...
```

## Driver-internal cells (NOT caller params)

`$F3E2/$E3` hold the driver's **physical** track (post-skew) and a scratch byte: the
driver translates `DSK_TRACK` to a physical track in `$E2`, then verifies it against the
track field read out of the disk's address header (`$2F`); a mismatch raises error `$20`.
`$F3E5/$E7` are the driver's current-drive / current-slot latches (compared to
`DSK_DRIVE`/`DSK_SLOT` to detect a change and re-select). `$F3EE/$F3EF` are RW13-only:
it saves and restores the BIOS sector-handler vector around its raw access.

These are why the cells first *looked* inconsistent: reading the driver body shows
`$E2` = track, but reading the **caller** shows `$E0` = track. `$E2` is the physical
copy; `$E0` is the logical input.

## Sector interleave (skew)

CP/M, Apple Pascal/ProDOS and Apple DOS 3.3 all use the **same physical 16-sector
format** (same GCR nibble encoding, physical sectors 0-15); they differ only in the
software logical->physical **interleave**. SoftCard CP/M uses the **2:1 (Pascal/ProDOS)
interleave**, carried in CPM56 as:

```
00 02 04 06 08 0A 0C 0E 01 03 05 07 09 0B 0D 0F
```

This is NOT DOS 3.3's descending skew (`00 0D 0B 09 07 ...`). RW13 additionally handles
**DOS 3.2 (13-sector)** disks, which are a *physically different* format (different
encoding, 13 sectors); RW13 selects the 13-sector skew via the `$03E0`-path mode test
and uses a distinct 13-entry table (`00 09 05 03 0C FF 06 02 0A 08 04 FF 0B`, the `$FF`
marking the three "missing" sectors when 13 logical map onto the wider physical track).

## Notes / open

- The `$F3EB` "command" is read by every file-utility driver as read-vs-write. The 60K
  `CPM60_installer` annotates the same cells differently (e.g. `$F3EB` = "sector count")
  and its 6502 fragments do not touch `$03Exx`, so it may drive the disk through a
  different path; it is left with local names pending its own RE.
- `DSK_*` are `[RE]` (reverse-engineered), not Microsoft-documented.
