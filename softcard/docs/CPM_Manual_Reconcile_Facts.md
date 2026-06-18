# SoftCard CP/M 2.20 Manual Fact Sheet

Authoritative reconcile anchor for machine-generated comments in the disassembled OS source.

**Source manuals:** Microsoft SoftCard CP/M 2.20, (C) 1980 (Microsoft / Digital Research). Specifically: *Software and Hardware Details*, the bundled Digital Research *CP/M 2.2 Reference Manual*, and *SoftCard Volume 1 & Volume 2*.

**Reconstruction caveat:** the transcribed Markdown these facts were extracted from is an AI vision-reconstruction of scanned PDFs. The scanned PDFs remain the authoritative source. Any value carrying a trailing **[needs-PDF-check]** marker must be confirmed against the scanned PDF before being treated as final. All such items are collected in the checklist at the end.

**Address convention used throughout:** the SoftCard hardware maps Z-80 addresses to 6502 addresses per the translation table in Section 2. As a shorthand, the config block at 6502 `$0200-$03FF` is Z-80 `0F200H-0F3FFH`. Hex with a leading `0` and trailing `H` (e.g. `0F3DEH`) is the manual's Z-80 (8080-syntax) form; `$`-prefixed hex is the 6502 form.

**Two cross-manual conflicts are surfaced explicitly where they occur** (the Card Type value enumeration vs. the recognized-types list; the manual's "56K Language Card" layout vs. the project's 44K/60K trees). Do not treat either side as wrong without checking the PDF.

---

## 1. Version & Scope Key

| Marker | Meaning |
|---|---|
| **SHARED** | Architectural / carries from CP/M 2.20 into 2.23 (and is generic CP/M where noted). Safe to annotate as version-independent. |
| **2.20-ONLY** | Specific to the 1980 2.20 release as shipped (memory split, banner token, utility presence, etc.). Confirm before applying to 2.23. |
| **2.23-ONLY** | Stated by a source as specific to the later release / a SoftCard-specific edit of the base addresses. |

A note on scope reasoning the extracts make: the I/O Configuration Block, the disk-driver/screen-memory low-memory layout, and the RPC mechanism are **SHARED** (they live in shared low memory and are architectural). The 44K-vs-56K top-of-memory split, the cold-boot banner token, and the shipped utilities are **2.20-ONLY**.

---

## 2. Memory Map (Z-80 <-> 6502)

### 2.1 6502/Z-80 Address Translation table — SHARED

One-line semantics: hardware bank-translation. The SoftCard adds `$1000` to Z-80 addresses except the high banks, which are reordered.
Page: printed 2-6 (scan 08); restated printed 2-32 (scan 34).
Maps to code: foundational for all dual-CPU address mapping in the emulator/disassembler.

| Z-80 range | 6502 range | Note |
|---|---|---|
| `0000H-0FFFH` | `$1000-$1FFF` | Z-80 location zero |
| `1000H-1FFFH` | `$2000-$2FFF` | |
| `2000H-2FFFH` | `$3000-$3FFF` | |
| `3000H-3FFFH` | `$4000-$4FFF` | |
| `4000H-4FFFH` | `$5000-$5FFF` | |
| `5000H-5FFFH` | `$6000-$6FFF` | |
| `6000H-6FFFH` | `$7000-$7FFF` | |
| `7000H-7FFFH` | `$8000-$8FFF` | |
| `8000H-8FFFH` | `$9000-$9FFF` | |
| `9000H-9FFFH` | `$A000-$AFFF` | |
| `0A000H-0AFFFH` | `$B000-$BFFF` | |
| `0B000H-0BFFFH` | `$D000-$DFFF` | |
| `0C000H-0CFFFH` | `$E000-$EFFF` | |
| `0D000H-0DFFFH` | `$F000-$FFFF` | 6502 RESET/NMI/BREAK vectors |
| `0E000H-0EFFFH` | `$C000-$CFFF` | 6502 memory-mapped I/O |
| `0F000H-0FFFFH` | `$0000-$0FFF` | 6502 zero page, stack, Apple screen |

> | 0000H-0FFFH | $1000-$1FFF | Z-80 location zero | ... | 0D000H-0DFFFH | $F000-$FFFF | 6502 RESET, NMI, BREAK vectors | | 0E000H-0EFFFH | $C000-$CFFF | 6502 memory mapped I/O | | 0F000H-0FFFFH | $0000-0FFF | 6502 zero page, stack, Apple screen |

(This same map is restated in Chapter 3 "Address Bus Interface" as the Z-80 -> Apple translation when S1-1 is off.)

### 2.2 Apple II CP/M Memory Usage table — region scope mixed (see notes)

One-line semantics: how Apple memory is partitioned by Apple CP/M. The config block + disk-driver low-memory layout is SHARED; the 44K vs 56K top-of-memory split is 2.20-ONLY.
Page: printed 2-6 (scan 08).
Maps to code: top-level memory map for CPM 2.20 (44K/56K); annotate disk-buffer region, screen memory, config-block base, LC top-of-RAM split.

| 6502 | Z-80 | Use | Scope |
|---|---|---|---|
| `$800-$FFF` | `0F800-0FFFF` | Apple disk drivers and disk buffers | SHARED |
| `$400-$7FF` | `0F400-0F7FF` | Apple screen memory | SHARED |
| `$200-$3FF` | `0F200H-0F3FFH` | I/O Configuration Block | SHARED |
| `$000-$1FF` | `0F000H-0F1FFH` | Reserved 6502 stack and zero page | SHARED |
| `$C000-$CFFF` | `0E000H-0EFFFH` | Apple memory-mapped I/O | SHARED |
| `$FFFA-$FFFF` | `0DFFAH-0DFFFH` | 6502 RESET, NMI, and BREAK vectors | SHARED |
| `$D400-$FFF9` | `0C400H-0DFF9H` | 56K Language Card CP/M (if LC installed) | 2.20-ONLY |
| `$D000-$D3FF` | `0C000H-0C3FFH` | Top 1K of free RAM with 56K LC CP/M | 2.20-ONLY |
| `$A400-$BFFF` | `9400H-0AFFFH` | 44K CP/M (free memory with 56K CP/M) | 2.20-ONLY |
| `$1000-$A3FF` | `0000H-093FFH` | Free RAM (CP/M uses lowest 256 bytes) | 2.20-ONLY (split) |

> | $800-$FFF | 0F800-0FFFF | Apple disk drivers and disk buffers | | $400-$7FF | 0F400-0F7FF | Apple screen memory | | $200-$3FF | 0F200H-0F3FFH | I/O Configuration Block. | | $000-$1FF | 0F000H-0F1FFH | Reserved 6502 memory area — 6502 stack and zero page. | | $C000-$CFFF | 0E000H-0EFFFH | Apple memory mapped I/O | | $FFFA-$FFFF | 0DFFAH-0DFFFH | 6502 RESET, NMI, and BREAK vectors. | | $D400-$FFF9 | 0C400H-0DFF9H | 56K Language Card CP/M (if Language Card installed) | | $D000-$D3FF | 0C000H-0C3FFH | Top 1K of free RAM space with 56K Language Card CP/M | | $A400-$BFFF | 9400H-0AFFFH | 44K CP/M. (Free memory with 56K CP/M) | | $1000-$A3FF | 0000H-093FFH | Free RAM (CP/M uses lowest 256 bytes) |

### 2.3 CP/M module base addresses (DR Reference Manual, SoftCard edit) — 2.20 (1980 manual)

One-line semantics: vertical CP/M layout high-to-low (FDOS above FBASE, CCP above CBASE, TPA above TBASE, system params above BOOT=`0000H`), with Apple-specific base addresses for two configs.
Page: printed 3-41/3-42 (scan 053-054).
Maps to code: `CPM_SystemImage.asm` ORG/EQU for CCP_BASE/BDOS_BASE/BIOS_BASE.

| Module | 44K | 56K (Language Card) |
|---|---|---|
| CCP / CBASE | `9400H` | `C400H` |
| BDOS / FBASE | `9C00H` | `CC00H` |
| BIOS | `AA00H` | `DA00H` |
| Top of RAM | `AFFFH` | `DFFFH` |
| BOOT | `0000H` | `0000H` |
| TBASE (TPA base) | `0100H` | `0100H` |

> Base addresses for the two Apple memory configurations that can be used with CP/M are shown in the table below: | Module | 44K | 56K (Language Card) | | CCP | 9400H | C400H | | BDOS | 9C00H | CC00H | | BIOS | AA00H | DA00H | | Top of RAM | AFFFH | DFFFH |

**SCOPE NOTE (corrected — was mis-tagged 2.23-only in the raw extract).** These CCP/BDOS/BIOS load addresses are from the 1980 SoftCard-edited DR Reference Manual, i.e. the **2.20-era** layout. Decisive cross-check against the repo sources: the **56K column** (CCP `C400H`, BDOS `CC00H`, BIOS `DA00H`) matches **CPMV220** exactly — `CPMV220/os/CPM_BIOS.asm` is `ORG $DA00` and declares `BDOS_ENTRY_220 EQU $CC06`. The **2.23 trees rebased the BIOS to `$FA00`** (`CPMV223-44K/os/CPM_BIOS.asm` is `ORG $FA00`), so this table maps to **CPMV220**, not the 2.23 sources. The manual's second config is "56K Language Card"; the project's later **60K** config is a separate post-1980 layout. The `BOOT=0000H` / `TBASE=0100H` / `0005H`-entry architecture is SHARED. The 44K column (`9400H`/`9C00H`/`AA00H`) has no direct repo source (CPMV220 is the `$DA00` build); confirm it against the PDF only if it is ever needed.

### 2.4 6502 RESET / NMI / BREAK vectors — SHARED

One-line semantics: 6502 hardware vectors (NMI `$FFFA/$FFFB`, RESET `$FFFC/$FFFD`, IRQ/BRK `$FFFE/$FFFF`) at 6502 `$FFFA-$FFFF` = Z-80 `0DFFAH-0DFFFH`; they point at the mode-switch routine at `$3C0`.
Page: printed 2-6 and 2-25 (scan 08, 27).
Maps to code: annotate the 6502 vector area; confirm RESET/NMI/IRQ point to `$3C0`.

> | $FFFA-$FFFF | 0DFFAH-0DFFFH | 6502 RESET, NMI, and BREAK vectors. | ... $3C0 | Start address of 6502 to Z-80 mode switching routine. 6502 RESET, NMI, and BREAK vectors point here.

### 2.5 SoftCard control addresses (slot-dependent CPU switch) — SHARED

One-line semantics: a WRITE to the SoftCard's slot-dependent control area switches CPUs; 6502 view `$CN00-$CNFF` for slot N, Z-80 view `0EN00H`. A write (not a read) is required.
Page: printed 2-24 and 2-31 (scan 26, 33).
Maps to code: the CPU-switch I/O addresses (`$CN00` / `0EN00H`) the emulator/switch logic intercepts; tied to the corrected 2.20 hang mechanism (the `$C700` CPU-switch access destroying the `$C800` expansion-ROM window claim).

| Slot | 6502 control area |
|---|---|
| 1 | `$C100-$C1FF` |
| 2 | `$C200-$C2FF` |
| 3 | `$C300-$C3FF` |
| 4 | `$C400-$C4FF` |
| 5 | `$C500-$C5FF` |
| 6 | `$C600-$C6FF` |
| 7 | `$C700-$C7FF` |
| (any) | Z-80 view `0EN00H`, N = slot |

> | 1 | $C100-$C1FF | | 2 | $C200-$C2FF | | 3 | $C300-$C3FF | | 4 | $C400-$C4FF | | 5 | $C500-$C5FF | | 6 | $C600-$C6FF | | 7 | $C700-$C7FF | ... the 6502 processor is enabled from Z-80 mode by a *write* to the slot-dependent location 0EN00H, where N is the slot location of the SoftCard

### 2.6 Language Card behavior during 6502 calls — 2.20-ONLY

One-line semantics: in Z-80 mode the LC RAM is read- and write-enabled; during a 6502 call the on-board ROM (Monitor) is auto-enabled but LC RAM stays write-enabled, so any 6502 write above `$D000` lands in LC RAM. The first of the two 4K `$D000-$DFFF` banks is NOT used by CP/M. Locations `$800-$FFF` are NOT available to 6502 subroutines (disk drivers + buffers live there).
Addresses: 6502 `$D000-$DFFF` (first 4K bank, unused by CP/M); Z-80 `0C000H-0EFFFH` = 6502 `$D000-$FFFF`.
Page: printed 2-25 (scan 27).
Maps to code: LC banking assumptions around 6502-call sites; relevant to the 56K LC layout and emulator LC fetch-banking.

---

## 3. I/O Configuration Block (`$0200-$03FF` / `0F200H-0F3FFH`)

**Base — SHARED.** The block occupies 6502 `$200-$3FF` = Z-80 `0F200H-0F3FFH`. Every Apple CP/M system disk has its own block, loaded and initialized at boot. Modified via the CONFIGIO utility. Five primary functions:
Page: printed 2-6 and 2-12 (scan 08, 14). Maps to code: base of the entire config block at Z-80 `0F200H`.

> The I/O Configuration Block contains the information necessary to interface Apple CP/M to the various hardware and software configurations available to the Apple CP/M user. Every Apple CP/M system disk has its own I/O Configuration Block, which is loaded and initialized when the system is booted. There are five primary functions of the I/O Configuration Block: 1. Console cursor addressing/screen function interface 2. Redefinition of keyboard characters 3. Support of non-standard peripheral devices and I/O software 4. Calling of 6502 subroutines 5. Indication of the presence and location of peripheral cards

### 3.1 I/O Driver Blocks (three 128-byte user-driver regions) — SHARED

One-line semantics: three 128-byte blocks of the config block hold user I/O driver software, each allocated to a specific slot/logical device to avoid memory conflicts.
Page: printed 2-18 (scan 20). Maps to code: the per-slot driver scratch regions inside the config block.

| Z-80 range | Slot | Device |
|---|---|---|
| `0F200H-0F27FH` | Slot 1 | LST: — line printer |
| `0F280H-0F300H` **[needs-PDF-check]** | Slot 2 | PUN: and RDR: — general purpose I/O |
| `0F300H-0F37FH` | Slot 3 | TTY: — the console |

> | 0F200H-0F27FH | Slot 1 | LST: — line printer device | | 0F280H-0F300H | Slot 2 | PUN: and RDR: — general purpose I/O | | 0F300H-0F37FH | Slot 3 | TTY: — the console device |

Note: the printed Slot-2 end `0F300H` overlaps the Slot-3 start; treat `0F280H-0F2FFH` as the practical Slot-2 block. Verify the `0F300H` Slot-2 end byte against the scan.

### 3.2 I/O Vector Table — SHARED

One-line semantics: eleven two-byte primitive character-I/O vectors, normally pointing into the CP/M BIOS, user-patchable. Each BIOS CONST/CONIN/CONOUT/READER/PUNCH/LIST routine JMPs through one of these cells.
Page: printed 2-18/2-19 (scan 20-21). Maps to code: directly annotate the BIOS console/reader/punch/list dispatch; label cells with these names + the B-register screen-function convention.

| # | Z-80 addr | Vector | Semantics |
|---|---|---|---|
| 1 | `0F380H` | Console Status | Returns `0FFH` in A if a char is ready, else `00H` |
| 2 | `0F382H` | Console Input #1 | Char into A, high bit clear |
| 3 | `0F384H` | Console Input #2 | (same) |
| 4 | `0F386H` | Console Output #1 | ASCII char in C to console |
| 5 | `0F388H` | Console Output #2 | (same) |
| 6 | `0F38AH` | Reader Input #1 | Char from paper-tape reader into A |
| 7 | `0F38CH` | Reader Input #2 | (same) |
| 8 | `0F38EH` | Punch Output #1 | Char in C to paper-tape punch |
| 9 | `0F390H` | Punch Output #2 | (same) |
| 10 | `0F392H` | List Output #1 | Char in C to line printer |
| 11 | `0F394H` | List Output #2 | (same) |

> | 1 | 0F380H | Console Status | Returns 0FFH in register A if a character is ready to read, 00H in register A otherwise. | | 2 | 0F382H | Console Input vector #1 | Reads a character from the console into the A register with the high order bit clear. | | 3 | 0F384H | Console Input vector #2 | ... | | 4 | 0F386H | Console Output vector #1 | Sends the ASCII character in register C to the console device. | | 5 | 0F388H | Console Output vector #2 | ... | | 6 | 0F38AH | Reader Input vector #1 | Reads a character from the "paper tape reader" device into register A. | | 7 | 0F38CH | Reader Input vector #2 | | | 8 | 0F38EH | Punch Output vector #1 | Sends the character in register C to the "paper tape punch" device. | | 9 | 0F390H | Punch Output vector #2 | | | 10 | 0F392H | List Output vector #1 | Sends the character in register C to the line printer device. | | 11 | 0F394H | List Output vector #2 | | **NOTE:** During Console Output, the B register contains a number corresponding to one of the nine supported screen functions during output of a screen function. B contains zero during normal character output. B is also non-zero during the output of the Cursor Address X Y coords after executing screen function #7.

**B-register screen-function signaling during Console Output — SHARED** (printed 2-19, scan 21). During Console Output the B register carries side-band signaling: `B` = 1..9 (the screen-function number) while a screen function is emitted; `B = 0` during normal character output; `B` non-zero during output of the Cursor Address X/Y coords following screen function #7 (Address Cursor). Console-output drivers patched at `0F386H`/`0F388H` must honor this convention.

### 3.3 Cursor address offset and lead-in (screen-function table headers) — SHARED

One-line semantics: each 11-byte screen-function table begins with two header bytes. The coordinate offset's high bit controls X/Y transmission order; lead-in of zero means none.
Page: printed 2-14 (scan 16). Maps to code: GOTOXY / cursor-address code (`SXYOFF EQU 0F396H`, `SFLDIN EQU 0F397H`; hardware side `0F3A1H`/`0F3A2H`).

| Field | Software addr | Hardware addr | Semantics |
|---|---|---|---|
| Cursor XY coordinate offset | `0F396H` | `0F3A1H` | Range 0-127; high bit 0 => Y first then X, high bit 1 => X first then Y |
| Lead-in character | `0F397H` | `0F3A2H` | Zero = no lead-in |

> | 0F396H | 0F3A1H | Cursor address coordinate offset. Range: 0-127. If the high order is 0, the X and Y coordinates are expected to be transmitted Y first, X last. If the high order bit is 1, the coordinates are sent X first, Y last. | | 0F397H | 0F3A2H | Lead-in character. This byte is zero if there is no lead-in. |

### 3.4 Software & Hardware Screen Function Tables — SHARED (some addresses [needs-PDF-check])

One-line semantics: two parallel 11-byte tables. CP/M matches an incoming sequence against the **Software** table (SSFTAB base `0F398H`), then emits the corresponding **Hardware** table entry to the terminal. Per-entry rule: entry = 0 means function not implemented; high bit set means a lead-in is required; high bit clear means no lead-in.
Page: printed 2-14/2-15 (scan 16-17). Maps to code: the console-output screen-function matcher (`SSFTAB EQU 0F398H`, indexed by E 1-9, `LXI H,SSFTAB-1`) and the hardware emit path.

**Scope clarification (resolves a prompt assumption):** the two address columns below are **SOFTWARE vs HARDWARE**, NOT 44K vs 56K. The "two address columns for 44K vs 56K" framing does not appear in this manual; both columns are single-valued.

| Func # | Software addr | Hardware addr | Description |
|---|---|---|---|
| (header) offset | `0F396H` | `0F3A1H` | Cursor XY coordinate offset |
| (header) lead-in | `0F397H` | `0F3A2H` | Lead-in character |
| 1 | `0F398H` | `0F3A3H` | Clear Screen |
| 2 | `0F399H` | `0F3A4H` | Clear to End of Page |
| 3 | `0F39AH` | `0F3A5H` | Clear to End of Line |
| 4 | `0F39BH` | `0F3A6H` | Set Normal (low-light) Text Mode |
| 5 | `0F39CH` | `0F3A7H` | Set Inverse (high-light) Text Mode |
| 6 | `0F39DH` | `0F3A8H` | Home Cursor |
| 7 | `0F39EH` | `0F3A9H` | Address Cursor |
| 8 | `0F39FH` **[needs-PDF-check]** | `0F3AAH` **[needs-PDF-check]** | Move Cursor Up One Line |
| 9 | `0F39FH` **[needs-PDF-check]** | `0F3AAH` **[needs-PDF-check]** | Non-destructively Move Cursor Forward |

Note: the printed table lists BOTH fn8 and fn9 at the same address (`0F39FH` software, `0F3AAH` hardware). This is the manual's stated value; it is suspect (fn9 may belong at `0F3A0H` / `0F3ABH`). Flagged for PDF confirmation.

> SSFTAB EQU 0F398H ;Software screen functions ... | 1 | 0F398H | 0F3A3H | Clear screen | | 2 | 0F399H | 0F3A4H | Clear to End of Page | | 3 | 0F39AH | 0F3A5H | Clear to End of Line | | 4 | 0F39BH | 0F3A6H | Set Normal (low-light) Text Mode | | 5 | 0F39CH | 0F3A7H | Set Inverse (high-light) Text Mode | | 6 | 0F39DH | 0F3A8H | Home Cursor | | 7 | 0F39EH | 0F3A9H | Address Cursor (See above) | | 8 | 0F39FH | 0F3AAH | Move Cursor Up One Line | | 9 | 0F39FH | 0F3AAH | Non-destructively Move Cursor Forward |

The 24x40 Apple screen supports all nine functions independently of the hardware table, but a zero software entry disables that function.

### 3.5 Keyboard Character Redefinition Table — SHARED

One-line semantics: up to six two-byte character redefinitions; first byte = ASCII to redefine, second = desired ASCII (both high bits cleared). End marked by a byte with the high bit set if fewer than six. Applies only to TTY:/CRT: input.
Address: Z-80 `0F3ACH`.
Page: printed 2-17 (scan 19). Maps to code: the console-input keyboard-translation loop scanning `0F3ACH` (max 6 entries, high-bit-set terminator).

> The Keyboard Character Redefinition Table will support up to six character redefinitions. The table is located at 0F3ACH from the Z-80. Entries in the table are two bytes: the first is the ASCII value of the keyboard character to be redefined, and the second is the desired ASCII value of the character. Both bytes must have their high order bits cleared. If there are less than six entries in the Keyboard Character Redefinition Table, the end of the table is denoted by a byte with the high order bit set.

### 3.6 Card Type Table — SHARED

One-line semantics: seven-byte table, one byte per slot 1-7, recording detected card type. Base at Z-80 `0F3B9H` (`SLTTYP`); the entry for slot S is at `3B8H + S` (S = 1..7), so slot 1 is `0F3B9H`. Detection compares two signature bytes against known Apple cards.
Page: printed 2-26/2-27 (scan 28-29); `SLTTYP EQU` on printed 2-23 (scan 25). Maps to code: BIOS slot-scan results storage at `0F3B9H..0F3BFH`; the lower-case driver reads `SLTTYP+2` (= `0F3BBH`, slot 3) and compares to 3.

| Value | Meaning |
|---|---|
| 0 | No peripheral card ROM detected (usually empty slot) |
| 1 | ROM detected, but unknown type |
| 2 | Apple Disk II Controller |
| 3 | Apple Communications Interface or CCS 7710A Serial Interface |
| 4 | Apple High-Speed Serial Interface, **Videx Videoterm**, M&R Sup-R-Term, or Apple Silentype printer interface |
| 5 | Apple Parallel Printer Interface |

> The Card Type Table is located at 0F3B9H. The entry for a given slot is located at 3B8H + S, where S is an integer from 1 to 7. ... | 0 | No peripheral card ROM was detected ... | | 1 | A peripheral card ROM was detected, but it was of an unknown type. | | 2 | An Apple Disk II Controller card is installed in the slot. | | 3 | An Apple Communications Interface or CCS 7710A Serial Interface is installed in the slot. | | 4 | An Apple High-Speed Serial Interface, Videx Videoterm, M&R Sup-R-Term or Apple Silentype printer interface is installed in the slot. | | 5 | An Apple Parallel Printer Interface is installed in the slot. | ... if the third entry (slot 3 — console device) of the Card Type Table is either 3 or 4, a program can assume that the user is using an 80 column external terminal

**KEY 2.20 FACT:** Videx Videoterm = **Card Type value 4**. If the slot-3 entry is 3 or 4, assume an 80-column external terminal (enabling auto 40/80-column configuration).

**RESOLVED — Videx card type number (not a contradiction).** Two different numberings appear in the manual. The "recognized card types" list (printed 2-5 / scan 07) is a category list running **1-4** with NO runtime sentinels: 1=Disk II, 2=Comms/CCS, **3=High-Speed Serial / Videx / Sup-R-Term**, 4=Parallel Printer:

> | 1 | Apple Disk II Controller | | 2 | Apple Communications Interface | | | \*California Computer Systems 7710A Serial Interface | | 3 | Apple High Speed Serial Interface | | | Videx Videoterm 24 × 80 Video Terminal Card | | | M&R Enterprises Sup-R-Term 24 × 80 Video Terminal Card | | 4 | Apple Parallel Printer Card |

The Card Type **Table** (printed 2-26/2-27) is the actual byte stored per slot and prepends two runtime sentinels — **0=none, 1=unknown ROM** — which shifts the real cards up by one: 2=Disk II, 3=Comms/CCS, **4=High-Speed Serial / Videx / Sup-R-Term / Silentype**, 5=Parallel Printer. So **list-type-3 and table-value-4 denote the SAME physical card.** The byte the BIOS stores and the Z-80 reads at `0F3B9H + S` is the **Card Type Table value = 4 for the Videx**, confirmed by the 2.20 BIOS slot-scan dispatch (`SUB $03` then `DEC A` selects the device-4 / Pascal-1.0 path). **Annotate code with value 4.** (2.23 later adds a Pascal-1.1 `$Cn0B` probe that reassigns the Videx to device **6** — a post-1980 extension absent from this manual.)

### 3.7 Disk Count Byte — SHARED

One-line semantics: a single byte at Z-80 `0F3B8H` = number of disk controller cards x 2 (one drive on a controller still counts as two). It sits immediately before the Card Type Table (which is indexed from `0F3B8H + S`).
Page: printed 2-27 (scan 29). Maps to code: annotate `0F3B8H` as the disk-count (controllers x2); it is the `3B8H + 0` base from which Card Type Table entries are indexed.

> The Disk Count Byte is a single byte equal to the number of disk controller cards in the system times two. This value does not reflect an odd number of disk drives (i.e., only one drive plugged into a controller card). The Disk Count Byte is located at 0F3B8H.

---

## 4. The 6502-Subroutine-Call (RPC) Mechanism

The SoftCard lets the Z-80 call a 6502 subroutine: load parameter cells, store the 6502 target at `A$VEC` (`0F3D0H`), then WRITE through the SoftCard location `Z$CPU` (`0F3DEH`) to switch to the 6502 and run it. On return, results are read back from the same parameter cells.

### 4.1 Register-pass cells `$45-$49` — SHARED (EXACT ORDER)

One-line semantics: parameter-passing cells in 6502 zero page (Z-80 `0F045H-0F049H` = 6502 `$45-$49`). **Critical ordering: `$46` is Y and `$47` is X — Y comes before X.**
Page: printed 2-24/2-25 (scan 26-27). Maps to code: annotate the RPC parameter cells; `0F049H` is read AFTER the call to get the 6502 SP. The sample's `A$XREG` label naming is loose — trust the table, not the label.

| Z-80 | 6502 | Cell |
|---|---|---|
| `0F045H` | `$45` | 6502 A register pass area |
| `0F046H` | `$46` | 6502 Y register pass area |
| `0F047H` | `$47` | 6502 X register pass area |
| `0F048H` | `$48` | 6502 P (status) register pass area |
| `0F049H` | `$49` | Contains 6502 stack pointer **on exit** from subroutine |

> | 0F045H | $45 | 6502 A register pass area | | 0F046H | $46 | 6502 Y register pass area | | 0F047H | $47 | 6502 X register pass area | | 0F048H | $48 | 6502 P (status) register pass area | | 0F049H | $49 | Contains 6502 stack pointer on exit from subroutine | ... A$ACC     EQU     0F045H     ;6502 A register goes here  A$XREG    EQU     0F046H     ;6502 Y register pass area

Note: the sample PADDLE code labels `A$ACC EQU 0F045H` and `A$XREG EQU 0F046H` with the comment "6502 Y register pass area" — i.e. the code's `A$XREG` actually points at the **Y** cell `0F046H`. Annotate the cells from the table, not from the loose `A$XREG` name.

### 4.2 6502 Call Vector `A$VEC` (`0F3D0H`) — SHARED

One-line semantics: the address of the 6502 subroutine to be called, stored at Z-80 `0F3D0H` in low-high (little-endian) order before triggering the call. The interrupt handler temporarily overwrites this with `$FF58` (a 6502 RTS) while handing control back to the 6502.
Page: printed 2-25 (scan 27). Maps to code: any `SHLD 0F3D0H` / `SHLD A$VEC` stores the target 6502 routine address; the subsequent write to `Z$CPU` executes it.

> | 0F3D0H | Address of 6502 subroutine to be called is stored here in low-high order. | ... A$VEC     EQU     0F3D0H     ;Addr of 6502 sub. to call goes here

### 4.3 SoftCard Location Cell `Z$CPU` (`0F3DEH`) — SHARED

One-line semantics: the location of the SoftCard (determined by CP/M at boot) is stored at Z-80 `0F3DEH`: low byte = 0, high byte of form `0ENH` where N is the SoftCard's slot. A WRITE to this SoftCard address switches CPUs (from the 6502 side it is `$CN00`). To call a 6502 routine: `LHLD Z$CPU` then `MOV M,A` (a write).
Page: printed 2-24/2-25 (scan 26-27). Maps to code: any `LHLD 0F3DEH` followed by a write through `(HL)` is the CPU-switch / 6502-call trigger. This `$CN00`/`0EN00H` write is the mechanism implicated in the 2.20 `$C800`-window hang.

> | 0F3DEH | | Address of SoftCard held here—low byte = 0 followed by high byte of form 0ENH where N is the slot occupied by the SoftCard. | ... Z$CPU     EQU     0F3DEH     ;Location of SoftCard stored here ... LHLD    Z$CPU           ;Get SoftCard addr...  MOV     M,A             ;Go do it! (Must be a write)

### 4.4 6502-to-Z-80 Mode Switch Routine `$3C0` — SHARED

One-line semantics: 6502 address `$3C0` is the start of the 6502 -> Z-80 mode-switching routine. The 6502 RESET, NMI, and BREAK vectors point here. A JMP to `$3C0` puts the 6502 on hold and returns control to Z-80 mode. (6502 `$3C0` = Z-80 `0F3C0H`.)
Page: printed 2-25 (scan 27). Maps to code: the 6502-side stub at `$3C0` that hands the bus back to the Z-80. Distinct from the disk-buffer region `$800-$FFF` which 6502 subroutines must not use.

> | $3C0 | Start address of 6502 to Z-80 mode switching routine. 6502 RESET, NMI, and BREAK vectors point here. A JMP to this address puts the 6502 on "hold" and returns to Z-80 mode. |

### 4.5 Named Apple Monitor routines used by RPC — SHARED

One-line semantics: `PREAD EQU 0FB1EH` is the Apple Monitor paddle-read routine (Z-80 `0FB1EH` = 6502 Monitor `$FB1E`). `$FF58` is a 6502 RTS in the Apple Monitor ROM, used by the interrupt handler as a no-op 6502 call target. The on-board Apple ROM (incl. Monitor) is auto-enabled during a 6502 call, so `$FB1E` is reachable.
Page: printed 2-10 and 2-25 (scan 12, 27). Maps to code: when the OS calls Monitor routines via RPC, label the 6502 target (e.g. `PREAD = $FB1E` / Z-80 `0FB1EH`).

> PREAD     EQU     0FB1EH     ;Apple Monitor paddle read routine ... Set up the 6502 subroutine call address to $FF58, which is the address of a 6502 RTS instruction in the Apple Monitor ROM.

**Interrupt-handling protocol (SHARED, printed 2-10 / scan 12):** all interrupt processing must be handled by the 6502. In Z-80 mode the Z-80 handler must save registers, save the current 6502-call address, set the 6502 call address to `$FF58` (the Monitor RTS), write to the SoftCard address to return to the 6502, then on return restore the previous 6502-call address, restore registers, `EI`, `RET`.

### 4.6 The manual's sample EQU definitions — SHARED

One-line semantics: canonical EQU symbol names from the manual's 8080 sample code; use as the authoritative semantic labels when annotating config-block / RPC accesses.
Page: printed 2-15, 2-23, 2-25 (scan 17, 25, 27). Maps to code: use these names directly as disassembly labels.

| EQU | Value | Meaning |
|---|---|---|
| `BDOS` | `0005H` | CP/M function-call entry |
| `SXYOFF` | `0F396H` | Software cursor XY coordinate offset |
| `SFLDIN` | `0F397H` | Software function lead-in |
| `SSFTAB` | `0F398H` | Software screen-functions base |
| `SLTTYP` | `0F3B9H` | Slot / card types table |
| `KEYBD` | `0E000H` | Apple keyboard (Z-80 view of 6502 `$C000`); clear-strobe at `KEYBD+10H` = `0E010H` |
| `Z$CPU` | `0F3DEH` | SoftCard location |
| `A$VEC` | `0F3D0H` | 6502 sub-call address |
| `A$ACC` | `0F045H` | 6502 A register pass area |
| `A$XREG` | `0F046H` | labeled "6502 Y register pass area" in the sample (points at the **Y** cell) |
| `PREAD` | `0FB1EH` | Apple Monitor paddle read |
| `SHFCHR` | `21` | Shift key = forward-arrow, ASCII 21 / `0x15` |
| `ORIGIN` | `0F300H` | Real origin of the config-block lower-case driver (Slot-3 TTY: block) |

> BDOS            EQU     0005H           ;CP/M function call address  SXYOFF          EQU     0F396H ... SFLDIN          EQU     0F397H ... SSFTAB          EQU     0F398H ... SLTTYP  EQU     0F3B9H          ;Slot types table  KEYBD   EQU     0E000H          ;Address of Apple keyboard ... Z$CPU     EQU     0F3DEH ... A$VEC     EQU     0F3D0H ... A$ACC     EQU     0F045H ... A$XREG    EQU     0F046H ... PREAD     EQU     0FB1EH

---

## 5. BDOS Function Table (0-36)

One-line semantics: the complete CP/M 2.x BDOS function-number list — SHARED. The C-indexed dispatch jump table in `CPM_BDOS.asm` has one entry per number; label each target with the official name. **The highest defined function is 36 (`24H`); no functions 37-40 are defined in this CP/M 2.x manual.** (The prompt's "0-40" range therefore tops out at 36.)
Page: printed 3-44 (scan 056), summary table printed 3-76 (scan 088).

| C | Function | Input | Output |
|---|---|---|---|
| 0 (`00H`) | System Reset | none | none (JMP BOOT; re-login drive A) |
| 1 (`01H`) | Console Input | none | A = char (echo, tab-expand, ctl-S/ctl-P) |
| 2 (`02H`) | Console Output | E = char | none |
| 3 (`03H`) | Reader Input | none | A = char (RDR:) |
| 4 (`04H`) | Punch Output | E = char | none (PUN:) |
| 5 (`05H`) | List Output | E = char | none (LST:) |
| 6 (`06H`) | Direct Console I/O | E = `0FFH` (in) or char (out) | A = char/status; raw, no ctl-S/ctl-P |
| 7 (`07H`) | Get I/O Byte | none | A = IOBYTE |
| 8 (`08H`) | Set I/O Byte | E = IOBYTE | none |
| 9 (`09H`) | Print String | DE = `$`-terminated string | none |
| 10 (`0AH`) | Read Console Buffer | DE = buffer (`mx`,`nc`,chars) | edited line; line editor |
| 11 (`0BH`) | Get Console Status | none | A = `0FFH`/`00H` |
| 12 (`0CH`) | Return Version Number | none | HL = version (H=00 CP/M, L=`20H`+ for 2.x; 2.2 = `0022H`) |
| 13 (`0DH`) | Reset Disk System | none | all R/W, select A, DMA=`0080H` |
| 14 (`0EH`) | Select Disk | E = disk (0=A..15=P) | login directory |
| 15 (`0FH`) | Open File | DE = FCB | A = dir code (0-3) or `0FFH` |
| 16 (`10H`) | Close File | DE = FCB | A = dir code or `0FFH` |
| 17 (`11H`) | Search for First | DE = FCB | A = dir code; DMA gets dir record; offset = A*32 |
| 18 (`12H`) | Search for Next | none | A = dir code (255 = no more) |
| 19 (`13H`) | Delete File | DE = FCB | A = dir code or 255 |
| 20 (`14H`) | Read Sequential | DE = FCB | A = err code (00 ok, nonzero EOF) |
| 21 (`15H`) | Write Sequential | DE = FCB | A = err code (00 ok, nonzero disk full) |
| 22 (`16H`) | Make File | DE = FCB | A = dir code or `0FFH`; activates FCB |
| 23 (`17H`) | Rename File | DE = FCB | A = dir code or `0FFH` |
| 24 (`18H`) | Return Login Vector | none | HL = login bit-vector |
| 25 (`19H`) | Return Current Disk | none | A = current disk (0-15) |
| 26 (`1AH`) | Set DMA Address | DE = DMA addr | none (default `0080H`) |
| 27 (`1BH`) | Get Addr (Alloc) | none | HL = ALLOC vector base |
| 28 (`1CH`) | Write Protect Disk | none | sets temp R/O for current drive |
| 29 (`1DH`) | Get R/O Vector | none | HL = R/O bit-vector |
| 30 (`1EH`) | Set File Attributes | DE = FCB | A = dir code; sets t1' (R/O), t2' (SYS) |
| 31 (`1FH`) | Get Addr (Disk Parms) | none | HL = DPB address |
| 32 (`20H`) | Set/Get User Code | E = `0FFH` (get) or code (set) | A = current code (0-31, mod 32) |
| 33 (`21H`) | Read Random | DE = FCB | A = return code (01/03/04/06; 00 ok) |
| 34 (`22H`) | Write Random | DE = FCB | A = return code (+05 = directory full) |
| 35 (`23H`) | Compute File Size | DE = FCB | r0,r1,r2 set (virtual size) |
| 36 (`24H`) | Set Random Record | DE = FCB | r0,r1,r2 set |

> | 0 | System Reset | 19 | Delete File | | 1 | Console Input | 20 | Read Sequential | | 2 | Console Output | 21 | Write Sequential | | 3 | Reader Input | 22 | Make File | | 4 | Punch Output | 23 | Rename File | | 5 | List Output | 24 | Return Login Vector | | 6 | Direct Console I/O | 25 | Return Current Disk | | 7 | Get I/O Byte | 26 | Set DMA Address | | 8 | Set I/O Byte | 27 | Get Addr (Alloc) | | 9 | Print String | 28 | Write Protect Disk | | 10 | Read Console Buffer | 29 | Get R/O Vector | | 11 | Get Console Status | 30 | Set File Attributes | | 12 | Return Version Number | 31 | Get Addr (Disk Parms)| | 13 | Reset Disk System | 32 | Set/Get User Code | | 14 | Select Disk | 33 | Read Random | | 15 | Open File | 34 | Write Random | | 16 | Close File | 35 | Compute File Size | | 17 | Search for First | 36 | Set Random Record | | 18 | Search for Next | | |

**Return-convention notes (System Function Summary, printed 3-76 / scan 088):** byte results in A, word results in HL; for funcs 12/24/29, A = L and B = H on return. READ/WRITE Sequential and READ/WRITE Random return "Err Code" in A; OPEN/CLOSE/SEARCH/DELETE/MAKE/RENAME/Set File Attr return "Dir Code"; funcs 35/36 set r0,r1,r2.

**BDOS run-time errors (printed 3-36/3-37, scan 042-043):** `BDOS ERR ON x: error` where error is one of `BAD SECTOR` (controller R/W error), `SELECT` (drive outside A-D range; reboots after console input), or `R/O` (write to read-only / changed disk; warm start after console input).

---

## 6. FCB Layout — SHARED

One-line semantics: the File Control Block is 33 bytes for sequential access, 36 bytes for random (r0,r1,r2 added). All FCB field references in OPEN/CLOSE/READ/WRITE/SEARCH map to these offsets in `CPM_BDOS.asm`.
Page: printed 3-46/3-47 (scan 058-059).

| Offset | Field | Semantics |
|---|---|---|
| 0 | `dr` | Drive code 0-16: 0 = default drive; 1 = A, 2 = B, ... 16 = P |
| 1-8 | `f1..f8` | File name, ASCII upper case, high bit 0 |
| 9-11 | `t1,t2,t3` | File type, ASCII upper case, high bit 0; high bits = attributes (`t1'`=1 R/O, `t2'`=1 SYS/no-DIR, `t3'` reserved) |
| 12 | `ex` | Current extent (0-31 during I/O, normally 0) |
| 13 | `s1` | Reserved, internal |
| 14 | `s2` | Reserved, internal; zeroed on OPEN/MAKE/SEARCH |
| 15 | `rc` | Record count for extent (0-128) |
| 16-31 | `d0..dn` | Allocation map, filled by CP/M (reserved) |
| 32 | `cr` | Current record for sequential I/O (user sets 0 to start at record 0) |
| 33 | `r0` | Random record, low byte |
| 34 | `r1` | Random record, high byte |
| 35 | `r2` | Random record overflow byte |

> | dr | f1 | f2 | / / | f8 | t1 | t2 | t3 | ex | s1 | s2 | rc | d0 | / / | dn | cr | r0 | r1 | r2 |   00   01   02   ...   08   09   10   11   12   13   14   15   16   ...   31   32   33   34   35

`r0,r1` form a 16-bit random record number 0-65535 (low byte `r0`, high byte `r1`), with overflow into `r2`.

---

## 7. CP/M Low-Memory & System-Call Conventions — SHARED (unless noted)

### 7.1 FDOS / BDOS entry point at `BOOT+0005H`

One-line semantics: all OS calls load a function number into C and an information address into DE, then CALL `BOOT+0005H` (normally `0005H`). Location `0005H` holds a JMP to FBASE; the 2-byte address at `0006H` equals FBASE = top of available memory.
Page: printed 3-44 (scan 056). Maps to code: `CPM_BDOS.asm` dispatch entry (the JMP at `0005H` -> FBASE); `CPM_SystemImage.asm` page-zero layout (`BDOS=$0005`, `WBOOT=$0000`, FBASE pointer at `$0006`).

> access to the FDOS functions is accomplished by passing a function number and information address through the primary entry point at location BOOT + 0005H. In general, the function number is passed in register C with the information address in the double byte pair DE. Single byte values are returned in register A, with double byte values returned in HL (a zero value is returned when the function number is out of range). For reasons of compatibility, register A = L and register B = H upon return in all cases.

### 7.2 Register / return convention

Function # in C; information address in DE (single-byte parameters in E). Single-byte results in A; double-byte results in HL. Out-of-range function number returns zero. For compatibility, A = L and B = H on every return. Conventions match Intel PL/M. (printed 3-44, scan 056)

### 7.3 CCP transient stack

One-line semantics: on entry to a transient the CCP sets SP to an 8-level stack with the CCP return address pushed (7 levels free). The FDOS switches to its own local stack on each call. Most transients return via `JMP 0000H`.
Page: printed 3-44 (scan 056). Maps to code: `CPM_CCP.asm` transient-load/launch (SP setup); `CPM_BDOS.asm` local stack switch at entry.

### 7.4 Default FCB (`005CH`), second FCB (`006CH`), default DMA (`0080H`)

One-line semantics: transients use the default FCB at `005CH` and the default 128-byte DMA buffer at `0080H`. The CCP parses up to two file specs into FCB1 (`005CH`) and a second FCB whose first 16 bytes occupy `006CH` (the `d0..dn` region of FCB1) — the second FCB must be copied elsewhere before opening FCB1. The three bytes at `007DH` are free for the random-record fields. Default DMA resets to `0080H` on cold start, warm start, and disk reset.
Page: printed 3-46, 3-47/3-48 (scan 058-060). Maps to code: `CPM_SystemImage.asm` page-zero (`DEFAULT_FCB EQU $5C`, `DMA EQU $80`); `CPM_CCP.asm` two-FCB parse (FCB1=`$5C`, FCB2 first-16 at `$6C`, name at `$6D`, type at `$75`).

| Z-80 | Use |
|---|---|
| `BOOT+005CH` (normally `005CH`) | Default FCB #1 |
| `BOOT+006CH` | Second FCB drive code / FCB1 `d0..dn` region |
| `BOOT+006DH` | Second file name |
| `BOOT+0075H` | Second file type |
| `BOOT+007DH` | 3 bytes free for random fields |
| `BOOT+0080H` (normally `0080H`) | Default DMA / command-tail buffer |

### 7.5 Command-tail buffer at `0080H`

On transient entry the default buffer at `0080H` holds the command-line tail: byte `0080H` = character count, then the tail characters (upper-cased). The `0080H` buffer doubles as the initial DMA buffer. (printed 3-47/3-48, scan 059-060)

### 7.6 IOBYTE — logical-to-physical device map at `0003H`

One-line semantics: the IOBYTE at `0003H` maps four logical devices to physical devices via four 2-bit fields — CONSOLE (bits 0-1), READER (bits 2-3), PUNCH (bits 4-5), LIST (bits 6-7). Set via STAT or BDOS funcs 7 & 8.
Page: printed 2-18 to 2-21 (scan 020-023); DR funcs 7/8 printed 3-50/3-51 (scan 062-063). Maps to code: annotate reads/writes of IOBYTE at `0003H` and the BIOS logical-to-physical demux selecting which I/O Vector Table entry (#1 vs #2) is used.

| Field (bits) | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| CONSOLE (0-1) | TTY: | CRT: | BAT: (RDR: in / LST: out) | UC1: |
| READER (2-3) | TTY: | CRT: | PTR: | UR2: |
| PUNCH (4-5) | TTY: | PTP: | UP1: | UP2: |
| LIST (6-7) | TTY: | CRT: | LPT: | UL1: |

Vector routing: TTY:/CRT: via Console In/Out #1 (status always via Console Status vector); UC1: via Console In/Out #2; PTR: (input card slot 2; returns `1AH` EOF if none) via Reader Input #1; UR1:/UR2: via Reader Input #2; PTP: (output card slot 2) via Punch Output #1; UP1:/UP2: via Punch Output #2; LPT: (slot 1) via List Output #1; UL1: via List Output #2.

> IOBYTE at 0003H:   | LIST  |  PUNCH  |  READER  | CONSOLE |\n          bits:      7   6    5   4     3   2      1   0

### 7.7 Standard CP/M file types

Conventional 3-char types: ASM, PRN, HEX, BAS, INT, COM, PLI, REL, TEX, BAK, SYM, `$$$`. COM marks a TPA-executable memory image loaded at TBASE (`0100H`). (printed 3-45, scan 057)

### 7.8 CCP built-ins & line editing

Six CCP built-ins: ERA, DIR, REN, SAVE, TYPE, USER (printed 3-6 to 3-13, scan 012-019). Line-editing controls (rubout/del, ctl-C reboot, ctl-E phys EOL, ctl-H backspace, ctl-J/ctl-M terminate, ctl-R retype, ctl-X backspace-to-start; ctl-P printer-echo toggle, ctl-S pause) match the func-10 line editor (printed 3-13/3-14, scan 019-020). Maps to code: `CPM_CCP.asm` built-in table + console line editor.

---

## 8. Memory Configurations (44K / 56K) & Boot

### 8.1 44K System — 2.20-ONLY

One-line semantics: a 48K Apple II/II Plus running the SoftCard in Z-80 mode addresses only 44K of 48K; the top 4K is reserved for the Apple screen and the CP/M sector read/write (RWTS) routines. This is the as-shipped "44K CP/M" config.
Page: printed I-5 (scan 17). Maps to code: CPMV220 memory config / TPA top; annotate the 44K MEMTOP/SYS_BASE EQUs and the reserved-4K window.

> 44K System | Refers to an Apple II or Apple II Plus that has 48K RAM installed. We call it a 44K System, because when you are using the SoftCard (in Z-80 mode), you can address 44K of the 48K total. The 4K you lose is used to handle the Apple screen and CP/M sector read and write routines.

### 8.2 56K System — 2.20-ONLY

One-line semantics: a 48K Apple plus the Apple Language Card (64K total). 4K is reserved (Apple screen + RWTS) as in the 48K case, and only 12K of the LC's 16K is addressable, giving an effective 56K. This is the "56K CP/M" config produced by CPM56.
Page: printed I-5 (scan 17). Maps to code: CPMV220 (CPM56) Language-Card-banked config; 56K MEMTOP/SYS_BASE relocation + 12K-of-16K LC mapping.

> 56K System | Refers to an Apple II or Apple II Plus with Language Card (an Apple with 64K RAM installed). As with a 48K system, 4K of the 64K is dedicated to the Apple screen and CP/M sector read and write routines. And since only 12K of the 16K RAM on the Language Card is addressable, you have, in effect, a 56K system.

### 8.3 System RAM requirements / CP/M footprint — 2.20-ONLY

CP/M occupies 7K of RAM, of which only 5K is resident while a user program runs (the other 2K is the CCP, overwritten by the TPA and reloaded on warm boot). CP/M + MBASIC ≈ 29K; CP/M + GBASIC ≈ 37K. The SoftCard can use 12K of the LC's 16K in Z-80 mode. (printed I-4, scan 16)
Maps to code: sizing of resident 5K (BIOS+BDOS) vs the 2K CCP reloaded on warm boot.

> CP/M occupies 7K of RAM, only 5K of which is needed during the execution of user programs. CP/M and MBASIC together occupy just over 29K RAM. CP/M and GBASIC (BASIC with high-resolution graphics, found only on the 16-Sector disk) occupy just over 37K RAM.

### 8.4 Language Card usable RAM (12K of 16K) — 2.20-ONLY

In Z-80 mode the SoftCard can use 12K of the LC's 16K RAM (`$D000-$FFFF` window with only one of the two `$D000` banks plus `$E000-$FFFF`). The LC occupies slot 0 (not an I/O slot for CP/M). (printed I-4, scan 16; slot-0 note printed 1-3, scan 31)

### 8.5 CPM56 disk-update utility (44K -> 56K) — 2.20-ONLY

One-line semantics: CPM56 patches a 44K CP/M system disk in place so booting it invokes 56K (Language-Card banked) CP/M. A 56K disk will NOT boot without a Language Card; CPM56 cannot run on a 48K Apple. Present only on the 16-Sector disk.
Page: printed 1-13 (scan 41). Maps to code: CPMV220 boot-loader/system-image; annotate the disk-resident config bytes the loader reads to choose 44K vs 56K.

> First, however, you must update your CP/M system disk so that 56K CP/M, rather than 44K CP/M, will be invoked when the disk is booted. This is done with the CPM56 utility. ... a 56K CP/M disk will NOT BOOT on a system that is not equipped with a Language Card.

### 8.6 Cold-boot banner / sign-on message — 2.20-ONLY

On a successful cold boot the 44K system displays a three-line banner then `A>`. The 56K variant shows `56K` instead of `44K` after CPM56. Booting is automatic on an Autostart-ROM machine; on a non-Autostart Apple II the user types `6 Ctrl-K RETURN` after RESET.
Page: printed 1-8 (scan 36). Maps to code: CPMV220 BIOS cold-boot/sign-on string; the `44K`/`56K` token is patched by CPM56.

> APPLE II CP/M / 44K vers. 2.2X / (C) 1980 MICROSOFT ... A>

### 8.7 Cold boot vs warm boot — SHARED

A Cold Boot is the first full load + initialize. A Warm Boot (Ctrl-C as the first char of a line, RETURN after certain BDOS errors, or RESET on an Autostart machine) reloads CP/M from disk and re-reads the directory. WBOOT reloads CCP+BDOS, which is why only 5K of the 7K stays resident during TPA execution.
Page: printed 1-19 (scan 47-48). Maps to code: BIOS WBOOT vs BOOT entry behavior in CPMV220.

> When typed as the first character of a line, Ctrl-C is used to perform a CP/M "Warm Boot," causing CP/M to be reloaded from the disk ... (This is NOT the same as a Cold Boot. A Cold Boot is the act of booting the CP/M disk for the first time.)

### 8.8 13-sector vs 16-sector disk / boot incompatibility — 2.20-ONLY

Two physical formats ship. 13-sector = DOS 3.2-or-earlier / no Language Card; 16-sector = DOS 3.3 / Pascal / Language Card. A 16-sector disk will NOT boot a drive set up for 13-sector and vice-versa. The 16-sector disk additionally carries GBASIC, CPM56, and RW13 (reads 13-sector CP/M files from 16-sector CP/M).
Page: printed 1-8 (scan 36). Maps to code: CPMV220 RWTS / boot-loader sector-format handling; the shipped image is 16-sector.

> A 16-Sector disk will NOT boot on a drive set up for 13-Sector disks, and vice-versa.

### 8.9 Slot Function Assignments (where each card goes) — SHARED

One-line semantics: Apple CP/M requires peripheral cards in specific slots (identical to Apple Pascal). Maps to code: CPMV220 BIOS SELDSK / drive-to-slot translation and the LIST/PUNCH/READER device routines.
Page: printed 1-3/1-4 (scan 31-32) and 2-4/2-5 (scan 06-07).

| Slot | Card types | Function | 6502 base |
|---|---|---|---|
| 0 | (not I/O) | Language Card or Applesoft/Integer BASIC ROM card | — |
| 1 | 2,3,4 | Line printer (LST:) | `$C100` |
| 2 | in: 2,3,4 / out: 1,2,3,4 | General-purpose I/O (PUN: and RDR:) | `$C200` |
| 3 | 2,3,4 | Console output (CRT:/TTY:); empty => Apple 24x40 screen as TTY: | `$C300` |
| 4 | 1 | Disk controller for drives E:/F: | `$C400` |
| 5 | 1 | Disk controller for drives C:/D: | `$C500` |
| 6 | 1 | Disk controller for drives A:/B: (MUST be present) | `$C600` |
| 7 | any | No assigned purpose; SoftCard may go here | `$C700` |

NOTE: the SoftCard may be installed in any empty slot except slot zero.

> | 0 | Not used for I/O | This slot may contain a Language Card or an Applesoft or Integer BASIC ROM card. | ... | 1 | types 2,3,4 | Line printer interface (CP/M LST: device) | | 2 | input: 2,3,4 output: 1,2,3,4 | General purpose I/O (CP/M PUN: and RDR: devices) | ... | 3 | types 2,3,4 | Console output device (CRT: or TTY:) The normal Apple 24 × 40 screen is used as the TTY: device if no card is present. | | 4 | type 1 | Disk controller for drives E: and F: | | 5 | type 1 | Disk controller for drives C: and D: | | 6 | type 1 | Disk controller for drives A: and B: (must be present) | | 7 | any type | No assigned purpose. The SoftCard may be installed in slot 7. |

### 8.10 Videx Videoterm / Sup-R-Term support — 2.20-ONLY

One-line semantics: Volume 1 states the SoftCard supports both the Videx Videoterm and M&R Sup-R-Term 24x80 video cards (used as console via slot 3; configured through CONFIGIO). The actual 2.20 boot hang with a Videoterm is the project's separate finding, not a manual claim.
Page: printed 1-5 (scan 33). Maps to code: the BIOS slot-3 console init / `$C800-$CFFF` expansion-ROM claim path that 2.20 mishandles. Do NOT infer Videx-specificity from a bare `$C800` reference.

> The SoftCard supports both the Videx Videoterm and M&R Sup-R-Term 24 × 80 character video cards. Other plug-in video boards may be used with interface software supplied by the board manufacturer.

### 8.11 BOOT.COM helper program — 2.20-ONLY ([needs-PDF-check])

One-line semantics: a small CP/M utility entered at `0100H` via DDT, saved as BOOT.COM, that reboots the slot-6 disk controller without power-cycling (equivalent to `PR#6`). Reference utility, not OS source.
Page: printed 2-27 (scan 29). Maps to code: if annotating a BOOT.COM-like reboot stub, note it stores a `0C600H`-style boot entry and uses `Z$CPU` (`0F3DEH`).

Printed hex dump (bytes `C7`/`D0`/`DE` flagged faint/uncertain in the README spot-check):
```
0100 0E 01 CD 05 00 21 77 C7 22 00 30 21 00 C6 22 D0
0110 F3 2A DE F3 C3 00 30
```

### 8.12 Zero-page FDOS pointer and warm-boot vector — SHARED (one item [needs-PDF-check])

- **FDOS base in zero page (`0006H`/`0007H`) — SHARED.** Locations 6 and 7 hold the address of the start of FDOS (the BDOS); the highest usable memory is just below FDOS. (Vol 1 printed 1-33 / scan 61; Vol 2 printed 4-116 / scan 130.)
- **Warm-boot JMP at `0000H` + BIOS-entry high byte at `0107H` — SHARED ([needs-PDF-check]).** Location 0 normally holds a JMP to the BIOS warm-boot routine; location `0107H` holds the high byte of the CP/M BIOS entry (jump-vector page). While MBASIC/GBASIC is running, the JMP at `0000H` is redirected to BASIC's "Reset error" handler. (`0103H`=FRCINT, `0105H`=MAKINT are BASIC-internal.) (Vol 2 printed 4-116 / scan 130.)

> Location 107 Hex contains the high byte of the CP/M BIOS entry for use with direct calls to the BIOS. While BASIC is up, the JMP at location zero is a JMP to the "Reset error" of BASIC, not to the BIOS warm boot routine.

---

## Values to Confirm Against the Scanned PDF

These carry `needs-pdf-check` confidence in the extracts. Confirm against the authoritative scanned PDFs before treating as final:

1. **I/O Driver Blocks — Slot-2 end byte `0F300H`** (Section 3.1, printed 2-18 / scan 20). The printed Slot-2 end `0F300H` overlaps the Slot-3 start `0F300H`; the practical Slot-2 block is `0F280H-0F2FFH`. Verify the end byte.
2. **Software Screen Function Table — fn8/fn9 both at `0F39FH`** (Section 3.4, printed 2-14/2-15 / scan 16-17). The duplicate address for two distinct functions is suspect (fn9 may belong at `0F3A0H`).
3. **Hardware Screen Function Table — fn8/fn9 both at `0F3AAH`** (Section 3.4, printed 2-14/2-15 / scan 16-17). Same duplicate-address concern (fn9 may belong at `0F3ABH`).
4. **CP/M module base addresses — only the 44K column needs checking** (Section 2.3, printed 3-41/3-42 / scan 053-054). The **56K column is source-confirmed** (BIOS `DA00H` = CPMV220 `ORG $DA00`; BDOS `CC00H` = `BDOS_ENTRY_220 $CC06`). Only the 44K column (`9400H`/`9C00H`/`AA00H`) lacks a repo source; PDF-check it only if needed.
5. **BOOT.COM hex dump — bytes `C7`, `D0`, `DE`** (Section 8.11, printed 2-27 / scan 29). Flagged faint/uncertain in the README spot-check.
6. **Warm-boot JMP at `0000H` / BIOS-entry high byte at `0107H`** (Section 8.12, Vol 2 printed 4-116 / scan 130). Confirm the `0107H` high-byte and the `0103H`/`0105H` BASIC-internal entry points.
7. **ASCII Character Codes table** (referenced from the extracts, printed 2-7 to 2-10 / scan 09-12). README flags: DEC 4 shown as "ET" (standard ASCII is EOT); row 92 backslash and row 96 backtick glyphs uncertain. Verify specific chars (e.g. `SHFCHR=21`/NAK/forward-arrow, `1AH`=EOF) before annotating character codes.

---

## Cross-Manual Conflicts (collected)

1. **Videx card type number — RESOLVED (not a real conflict).** The recognized-types list (printed 2-5) numbers categories 1-4 with no sentinels; the Card Type Table (printed 2-26/2-27) prepends 0=none / 1=unknown-ROM, shifting real cards +1, so list-type-3 = table-value-4 (same card). The stored/read byte is **value 4** for the Videx, confirmed by the 2.20 BIOS dispatch. See Section 3.6. No PDF check needed for this item.
2. **Memory-configuration labeling — RESOLVED for CPMV220.** Section 2.3's "56K (Language Card)" column (BIOS `DA00H`, BDOS `CC00H`) matches CPMV220's source ORG/EQU exactly; the 2.23 trees rebased BIOS to `$FA00`. The project's **60K** config is a separate post-1980 layout. Architecture (`BOOT=0000H`, `TBASE=0100H`, `0005H` entry) is SHARED.
3. **Screen-function table column meaning.** The prompt assumed "two address columns for 44K vs 56K"; the manual's two columns are **Software vs Hardware** (Section 3.4). No conflict in the manual itself — noted to prevent a mis-annotation.
