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
| `os/CPM_CCP.asm` | **shared — done** | the **only** clean re-ORG; one source, byte-identical at both ORGs via the two knobs above. Dispatch/pointer tables relocate as `DEFW <label>` (disassembler's static data-flow). |
| BDOS | **config-specific** | same CP/M 2.2 BDOS but re-laid-out across two LC banks (two relocation deltas) + console group genuinely rewritten; merging is not worth it. Use `decompiled/CPMV233-60K/os/CPM_BDOS.asm` (byte-identical) + the 44K BDOS. |
| BIOS | **config-specific** | same `$FA00` origin but ~184 B longer; carries the relocation/banking subsystem. |
| boot loader | **config-specific** | 60K-specific (it *performs* the LC relocation). |
| RWTS | **config-specific** | the same Disk II driver re-ORG'd `+$1600` but with ~250 B of scattered genuine diffs (0.857). The real driver is `decompiled/CPMV233-60K/os/CPM_RWTS.s` (`$D000`, recovered from `CPM60.COM 0x400`; was mislabeled — held BIOS bytes). |

**Why only the CCP is shared:** the 60K conversion *is* the Language-Card relocation +
banking, and that machinery lives in the BDOS/BIOS/loader/RWTS — so those genuinely
differ between 44K and 60K. The CCP is pure command-shell logic untouched by the
conversion except for its load address, which is exactly why it re-ORGs cleanly.

## Building both targets

The build is "shared module where it's clean (CCP), config-specific module otherwise",
and the disk assembler already reproduces both targets byte-identical from source:

- **44K disk** (`CPMV233.DSK`, which also carries `CPM60.COM`): `reconstruct_disk("223", ...)`
  rebuilds the whole disk from the OS sources + each `.COM`'s re-assembled disassembly and
  verifies `diff_count == 0` (`tests/test_reconstruct.py`). `CPM60.COM` — the 60K installer —
  is one of those files, so it is rebuilt byte-identical too (`tests/test_decompile_com.py`).
- **60K system** (what `CPM60.COM` installs): the 60K OS modules in
  `decompiled/CPMV233-60K/os/` (CCP from *this* shared source at `$D300`, plus the
  config-specific BDOS/BIOS/loader/RWTS) each reassemble byte-identical to the
  `CPM60.COM` payload.

The CCP is the single source feeding *both* builds (`$9300` for 44K, `$D300` for 60K) —
proven by `tests/test_shared_ccp.py`.

## Provenance

These sources are the **relocatable** output of the project disassembler
(`disasm_z80_region`, dispatch resolution on by default) over the verified system
images, with the genuine configuration constants lifted to the two symbols above.
Each is verified to reassemble byte-identical to the real 44K and 60K images.
