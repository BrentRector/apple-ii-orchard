# 6502 core — optional 65C02 variant (potential future work)

**Status:** NOT STARTED. Scoped 2026-07-30, deliberately not begun. Nothing in this
repo needs a 65C02 today. This document exists so that whoever picks it up does not
have to re-derive the structure, and so the decision *not* to do it stays an informed
one.

**Scope:** make `shared/nibbler/cpu.py` able to emulate a 65C02 (CMOS) as well as the
NMOS 6502 it emulates now, with the variant selected explicitly and the NMOS
behaviour unchanged.

Companion material: `shared/nibbler/tests/` (the core's test suite), memory
`project_6502_core_completion`.

---

## 1. Why this is not being done now

The two machines this core drives are both NMOS:

* the Apple II+ running Apple Panic (`apple-ii/scripts/boot_emulate_full.py`), and
* the Microsoft SoftCard host in `softcard/softcard_emu/`.

The 65C02 shipped in the **enhanced Apple //e** and the **//c**. So the real trigger
for this work is a decision to model one of those machines, which is a machine-level
project, not a CPU-level one. Doing the CPU half first would leave 61 new opcodes and
a second timing table with no consumer and no reason to stay correct.

**Do not start this because the CPU "should" be complete.** Start it when a target
machine needs it.

---

## 2. Regression floor (do NOT break this)

```
cd /e/Orchard && source shared/toolchain/env.sh && python -m pytest softcard/ shared/
```

**1079 passed** with `6502_functional_test.bin` present (1078 passed + 1 skipped
without it — see `shared/nibbler/tests/test_functional_suite.py`).

And the load-bearing external figure:

```
cd apple-ii/scripts && python boot_emulate_full.py     # ~65s
```

must still reach `JMP $4000` in exactly **69,807,121** instructions, final state
`A=0D X=60 Y=0D SP=FD P=33`. **That number is quoted in an article maintained in a
different repo.** A change to it is a reportable event, not a detail.

Because the NMOS path would be untouched by a correctly-structured variant (see §4),
both of these should come through this work bit-identical. If they do not, the
structure is wrong.

---

## 3. The structural finding that shapes everything

**All 61 opcode slots the 65C02 family redefines are slots that are *undocumented* on
the NMOS 6502. Not one collides with a legal NMOS opcode.** The 151 legal opcodes keep
both their slots and their meanings on both CPUs.

| set | slots | collide with a legal NMOS opcode |
|---|---|---|
| 65C02 base additions | 27 | 0 |
| Rockwell RMB/SMB/BBR/BBS | 32 | 0 |
| WDC WAI/STP | 2 | 0 |

Of the 105 NMOS-undocumented slots, 61 get redefined and **44 become defined NOPs** on
the 65C02 (each with its own size and cycle count — not a blanket 1-byte filler).

Re-derive it with:

```python
import sys; sys.path.insert(0, 'shared')
from nibbler.cpu import CPU6502
c = CPU6502()
UNDOC_HANDLERS = {'_op_nop_undoc','_op_kil','_op_lax','_op_lax_imm','_op_sax',
                  '_op_dcp','_op_isb','_op_slo','_op_rla','_op_sre','_op_rra',
                  '_op_anc','_op_alr','_op_arr','_op_xaa','_op_ahx','_op_tas',
                  '_op_las','_op_axs','_op_shy','_op_shx'}
official = lambda op: (c.optable[op][0].__name__ not in UNDOC_HANDLERS
                       and op != 0xEB)          # $EB is the unofficial SBC mirror
```

The 27 base 65C02 additions:

```
BRA $80                       PHX $DA  PHY $5A  PLX $FA  PLY $7A
INC A $1A   DEC A $3A         STZ  $64 zp  $74 zpx  $9C abs  $9E abx
TSB $04 zp  $0C abs           TRB  $14 zp  $1C abs
BIT $34 zpx $3C abx $89 imm   JMP (abs,X) $7C
(zp) indirect: ORA $12  AND $32  EOR $52  ADC $72
               STA $92  LDA $B2  CMP $D2  SBC $F2      <- the 8 NMOS KIL slots
```

Note `$9C`/`$9E` are NMOS SHY/SHX and become STZ, and the eight `(zp)` slots are
NMOS KILs — so a 65C02 has no JAM opcodes at all (except WDC's `STP`).

---

## 4. Design decisions

### 4.1 Subclass, not a constructor flag

`class CPU65C02(CPU6502)`, not `CPU6502(variant='cmos')`.

1. The dispatch table stores **bound methods** and `_build_opcodes()` runs from
   `__init__`, so a subclass that overrides `_op_adc` is picked up by the table with no
   changes to dispatch. This falls out of the existing design for free.
2. A flag puts `if self.variant` inside `_adc_value()` and `_resolve_read()`, which are
   on the path the 69.8M-instruction Apple Panic boot runs through. Cycle counting
   already cost ~6% wall clock; do not add more to that loop for a variant nobody in
   this repo selects.
3. The 840 tests in `shared/nibbler/tests/` pin NMOS semantics and stay untouched.
4. `test_single_core.py` guards against a *fork* of the core, not a subclass, so it
   remains valid as written.

### 4.2 Split the opcode table, do not duplicate it

`_build_opcodes()` becomes:

```
_build_legal_opcodes()          # 151 slots, shared, unchanged by variant
_build_nmos_undocumented()      # 105 slots   } exactly one of these
_build_65c02_extensions()       #  61 + 44    } per variant
```

This is a small refactor of a method that is already the single place the table is
built, and §3 is what makes it clean: the two variant layers do not overlap.

---

## 5. Work items

| | Item | Size |
|---|---|---|
| A | Split `_build_opcodes` into legal + variant layers | small |
| B | Two new addressing modes, `(zp)` and `(abs,X)`: mode constants, `MODE_SIZE`, `_resolve_addr`, `_resolve_read`, `format_instr`, `CYCLES_BY_CLASS_AND_MODE` (13 modes → 15) | small-medium |
| C | The 27 base 65C02 opcodes | medium, mechanical |
| D | The 44 leftover slots as *defined* NOPs, each with correct size and cycles | medium, detail-dense |
| E | Behavioural overrides (§6) | small each |
| F | Cycle differences (§7) | medium |
| G | Optional: 32 Rockwell RMB/SMB/BBR/BBS, 2 WDC WAI/STP — a third and fourth variant | small-medium each |
| H | Tests (§8) | medium |

---

## 6. Behavioural overrides

Every one of these is a place where `cpu.py` already carries an in-line comment
naming the NMOS/65C02 divergence — those comments are the override points.

* **`_adc_value` / `_sbc_value`** — 65C02 takes N and Z from the *decimal* result, not
  from the half-corrected value. See the "This is NMOS behavior. A 65C02 fixes N/V/Z in
  decimal mode" note in `_adc_value`. V in decimal mode is the uncertain one; let the
  test binary settle it rather than encoding a guess.
* **`_addr_ind`** — the `JMP ($xxFF)` page-wrap bug is fixed on 65C02.
* **`reset()`** — clears D. The current implementation deliberately does not, and says
  why in its docstring; that is the hook.
* **`_op_brk` and `_enter_interrupt`** — clear D after pushing.
* **KIL** — does not exist. `_op_kil` and the `halted` path drop out of the variant.

---

## 7. Cycle differences

* ADC/SBC take **+1 cycle when D=1**.
* `JMP (abs)` is **6**, not 5.
* `ASL/ROL/LSR/ROR abs,X` is commonly given as **6 unless a page is crossed** (NMOS is
  a flat 7), while `INC/DEC abs,X` stays 7. **Published tables disagree here.** Do not
  hand-encode it — let the 65C02 test binary decide, the same way the NMOS counts were
  settled.
* The 44 defined NOPs have per-slot counts, not a uniform 2.

`CYCLES_BY_CLASS_AND_MODE` and `CYCLE_OVERRIDES` are module-level in `cpu.py`. Give the
variant its own override dict layered on top rather than forking the whole table; the
class × mode rule is the same on both CPUs.

---

## 8. Verification

**This part is already solved.** Klaus Dormann's repository ships a prebuilt
`65C02_extended_opcodes_test.bin` (65,536 bytes) alongside the NMOS
`6502_functional_test.bin` that this core already passes:

```
https://raw.githubusercontent.com/Klaus2m5/6502_65C02_functional_tests/master/bin_files/
```

Reuse the `test_functional_suite.py` harness verbatim — same `FlatCPU` subclass, same
run-until-PC-repeats trap detection — with the success address read from the published
`.lst`. Note the same licensing position: that binary is **GPL-3.0 and this repo is
MIT**, so it is not vendored; the test skips with the URL when absent.

Also required:

* **`test_decimal.py`** — the 20,000-case valid-BCD sweep stays non-circular and still
  applies: A and C are identical between variants, so only the N/Z expectations become
  variant-conditional. The invalid-BCD sweep needs a separate 65C02 reference.
* **`test_undocumented.py`** — NMOS-specific by definition. Scope it to the NMOS class.
* **`test_cycles.py`** — needs a second published table for the variant.
* **`test_undocumented.py::test_opcode_table_agrees_with_the_repo_disassembler`** — this
  cross-checks against `disasm6502.opcodes.OPCODES`, which is NMOS-only. Either mark the
  check NMOS-only or grow a parallel 65C02 table in `disasm6502` (which would be its own
  work item, and is what you would want anyway if you ever disassemble //c code).

---

## 9. Explicitly OUT of scope: sub-instruction bus modelling

The core performs **one read per operand and one write per store**. It models neither:

* the NMOS **dummy read of the un-carried address** when an indexed read crosses a page
  (the 65C02 re-reads the last instruction byte instead), nor
* the NMOS **RMW double write** — read, write-original, write-modified (the 65C02 does
  read, read, write).

On the Apple II those phantom accesses land on soft switches, and they are precisely
the class of incompatibility that separates the two CPUs in real software. So a truly
faithful "either CPU" core pulls this in — and it is a **larger change to
`_resolve_read` and every RMW handler than all of §5 combined**, on the hottest path in
the emulator.

Treat it as a **separate work item**, scoped on its own merits, and note that it is a
gap in the *NMOS* emulation today too — not something the 65C02 work introduces.

---

## 10. Sizing

* Base 65C02, no Rockwell/WDC, no bus modelling: **~1 focused day**, with the extended
  opcodes test as the gate.
* Plus the Rockwell bit ops and WDC `WAI`/`STP`: **~1.5 days**.
* Sub-instruction bus fidelity (§9): separate, larger, and needs its own plan.

---

## 11. DO NOT

* **DO NOT** start this without a target machine that needs it (§1).
* **DO NOT** put the variant behind a runtime flag checked inside `_adc_value` or
  `_resolve_read` (§4.1).
* **DO NOT** change any NMOS behaviour. The Apple Panic instruction count and the CP/M
  boot tests are the proof, and the count is externally published (§2).
* **DO NOT** hand-encode the disputed 65C02 cycle counts (§7).
* **DO NOT** vendor the GPL-3.0 test binary into this MIT repo (§8).
