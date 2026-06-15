# SoftCard CP/M — shared OS source

One source per module, assembled at two origins to produce **both** the 44K and
the 60K SoftCard CP/M system byte-for-byte. This is the "build the 44K disk and
`CPM60.COM` from the same files" tree: a module is included after the appropriate
`ORG`, and the assembler relocates it.

## The two build knobs

| Symbol | Meaning | 44K | 60K |
|---|---|---|---|
| `SYS_BASE` | load ORG of the resident system | `$9300` | `$D300` |
| `MEMTOP_PAGE` | top RAM page = memory size (high byte) | `$A1` | `$F0` |

`SYS_BASE` is the *only* address knob — every internal reference is a label (or a
`SYS_BASE`-relative expression like `SYS_BASE-1`, the top-of-TPA buffer one byte
below the CCP), so changing the ORG relocates the whole module. `MEMTOP_PAGE` is a
*separate* axis: it is the machine's top RAM page (the sysgen page-list loop counts
up to it, skipping the `$C0-$CF` I/O hole), which encodes memory size, not load
address — it genuinely is not derivable from `SYS_BASE`.

Build a module:

```
# 60K (default)
sjasmplus os/CPM_CCP.asm
# 44K
sjasmplus -DSYS_BASE=0x9300 -DMEMTOP_PAGE=0xA1 os/CPM_CCP.asm
```

(The defaults in each file are the 60K values, guarded by `IFNDEF`, so a `-D`
override selects 44K.)

## Modules

| Module | Status | Sharing model |
|---|---|---|
| `os/CPM_CCP.asm` | **done** — byte-identical at both ORGs | pure re-ORG + the two knobs above; the dispatch/pointer tables relocate as `DEFW <label>` (resolved by the disassembler's static data-flow + emulation trace) |
| BDOS | todo | same CP/M 2.2 BDOS, but needs `IF SIXTYK` blocks for the Language-Card banking + split layout |
| BIOS | todo | same `$FA00` origin; needs `IF SIXTYK` for the relocation/banking subsystem (the 60K BIOS is ~184 bytes longer) |
| boot loader | todo | largely 60K-specific (it performs the LC relocation) |
| RWTS | todo | standalone 6502 driver (extract the real one from `CPM60.COM` `0x400`; the existing `decompiled/.../CPM_RWTS.s` is mislabeled — it holds BIOS bytes) |

## Provenance

These sources are the **relocatable** output of the project disassembler
(`disasm_z80_region`, dispatch resolution on by default) over the verified system
images, with the genuine configuration constants lifted to the two symbols above.
Each is verified to reassemble byte-identical to the real 44K and 60K images.
