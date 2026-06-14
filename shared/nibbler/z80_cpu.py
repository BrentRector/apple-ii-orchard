"""
Minimal Z-80 CPU emulator focused on running the SoftCard CP/M cold-boot
generator and BIOS code. Not a complete Z-80; opcodes are implemented as
needed and unsupported ones halt with a clear error.

Architecture:
  - 64K flat memory (Z-80 view; the SoftCard mapping happens externally)
  - Standard register set (A, B, C, D, E, H, L, F) + alternates + IX/IY
  - I, R, IFF1, IFF2, IM
  - Memory read/write hooks for I/O and the SoftCard CPU-switch flip-flop

Usage::

    cpu = Z80CPU()
    cpu.mem = bytearray(65536)
    cpu.pc = 0xFA00
    cpu.run(max_instructions=1_000_000)
"""
from typing import Callable, Optional


# Flag bits in F register
FLAG_S  = 0x80   # Sign
FLAG_Z  = 0x40   # Zero
FLAG_Y  = 0x20   # Undocumented (bit 5 of result)
FLAG_H  = 0x10   # Half-carry
FLAG_X  = 0x08   # Undocumented (bit 3 of result)
FLAG_PV = 0x04   # Parity / Overflow
FLAG_N  = 0x02   # Subtract (BCD)
FLAG_C  = 0x01   # Carry


def parity(v):
    """Z-80 even-parity flag: 1 if even number of set bits."""
    v = v & 0xFF
    v ^= v >> 4
    v ^= v >> 2
    v ^= v >> 1
    return (~v) & 1


class Z80Halt(Exception):
    """Raised when Z-80 hits HALT or unsupported opcode."""


class Z80CPU:
    """A Z-80 instruction-set emulator.

    Models the full register file (main + alternate set, IX/IY, I/R, the
    interrupt flip-flops) and decodes the main and prefixed (CB/ED/DD/FD)
    opcode groups via dispatch tables built at import time. All memory
    access goes through ``read8``/``write8`` -- including instruction
    fetches (``fetch8`` -> ``read8``) -- so a host can install
    ``read_hook``/``write_hook`` to map I/O or bank-switched memory (this
    is how the SoftCard bus drives it through the Z-80->Apple address
    translation). I/O ports dispatch through ``in_handlers``/
    ``out_handlers``. Drive it with ``run`` (a bounded slice) or ``step``
    (one instruction); ``on_pc`` holds PC breakpoints. Not cycle-accurate
    -- one logical step per instruction."""

    def __init__(self):
        # Main register set
        self.a = 0
        self.f = 0
        self.b = 0
        self.c = 0
        self.d = 0
        self.e = 0
        self.h = 0
        self.l = 0
        # Alternate register set
        self.a_ = 0
        self.f_ = 0
        self.b_ = 0
        self.c_ = 0
        self.d_ = 0
        self.e_ = 0
        self.h_ = 0
        self.l_ = 0
        # Index registers and SP/PC
        self.ix = 0
        self.iy = 0
        self.sp = 0
        self.pc = 0
        # Special
        self.i = 0
        self.r = 0
        self.iff1 = 0
        self.iff2 = 0
        self.im = 0
        self.halted = False

        # Flat 64K memory (overridable by SoftCard mapper externally)
        self.mem = bytearray(65536)

        # I/O port handlers
        self.in_handlers = {}    # port -> callable() returning byte
        self.out_handlers = {}   # port -> callable(byte)

        # Memory access hooks (for memory-mapped I/O), called for EVERY
        # memory access including instruction fetches (fetch8 -> read8).
        # Contract the SoftCard bus relies on:
        #   read_hook(addr, None) -> byte to use, or None to fall through
        #     to the flat self.mem plane.
        #   write_hook(addr, val) -> non-None if it claimed the write
        #     (self.mem is then left untouched), or None to fall through
        #     and store into self.mem.
        self.read_hook = None
        self.write_hook = None

        # PC breakpoints
        self.on_pc = {}

        # Instruction tracing
        self.trace = False
        self.trace_file = None
        self.exec_count = 0

    # -- Register pair accessors -------------------------------------------

    @property
    def af(self):
        return (self.a << 8) | self.f
    @af.setter
    def af(self, v):
        self.a = (v >> 8) & 0xFF
        self.f = v & 0xFF

    @property
    def bc(self):
        return (self.b << 8) | self.c
    @bc.setter
    def bc(self, v):
        self.b = (v >> 8) & 0xFF
        self.c = v & 0xFF

    @property
    def de(self):
        return (self.d << 8) | self.e
    @de.setter
    def de(self, v):
        self.d = (v >> 8) & 0xFF
        self.e = v & 0xFF

    @property
    def hl(self):
        return (self.h << 8) | self.l
    @hl.setter
    def hl(self, v):
        self.h = (v >> 8) & 0xFF
        self.l = v & 0xFF

    # -- Memory access -----------------------------------------------------

    def read8(self, addr):
        """Read one byte at ``addr``, routing through ``read_hook`` if set
        (so a host can map I/O / bank-switched memory); else the flat plane."""
        addr &= 0xFFFF
        if self.read_hook:
            v = self.read_hook(addr, None)
            if v is not None:
                return v & 0xFF
        return self.mem[addr]

    def write8(self, addr, val):
        """Write one byte at ``addr``, offering it to ``write_hook`` first;
        if the hook claims it (returns non-None) the flat plane is untouched."""
        addr &= 0xFFFF
        val &= 0xFF
        if self.write_hook:
            r = self.write_hook(addr, val)
            if r is not None:
                return  # hook claimed it
        self.mem[addr] = val

    def read16(self, addr):
        """Read a little-endian 16-bit word (low byte at ``addr``)."""
        return self.read8(addr) | (self.read8(addr + 1) << 8)

    def write16(self, addr, val):
        """Write a little-endian 16-bit word (low byte at ``addr``)."""
        self.write8(addr, val & 0xFF)
        self.write8(addr + 1, (val >> 8) & 0xFF)

    # -- Stack ops --------------------------------------------------------

    def push16(self, v):
        """Push a 16-bit word: pre-decrement SP by 2, then store."""
        self.sp = (self.sp - 2) & 0xFFFF
        self.write16(self.sp, v)

    def pop16(self):
        """Pop a 16-bit word: read at SP, then post-increment SP by 2."""
        v = self.read16(self.sp)
        self.sp = (self.sp + 2) & 0xFFFF
        return v

    # -- Fetch (instruction stream; advances PC) -------------------------

    def fetch8(self):
        """Fetch the next opcode/operand byte at PC and advance PC."""
        v = self.read8(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return v

    def fetch16(self):
        """Fetch a little-endian 16-bit immediate and advance PC by 2."""
        lo = self.fetch8()
        hi = self.fetch8()
        return (hi << 8) | lo

    def fetch_signed8(self):
        """Fetch one byte as a signed displacement (-128..127); advance PC."""
        v = self.fetch8()
        return v - 256 if v >= 128 else v

    # -- Flag helpers ----------------------------------------------------

    def set_szp(self, v):
        v &= 0xFF
        f = self.f & ~(FLAG_S | FLAG_Z | FLAG_PV | FLAG_Y | FLAG_X)
        if v == 0:
            f |= FLAG_Z
        if v & 0x80:
            f |= FLAG_S
        if parity(v):
            f |= FLAG_PV
        f |= v & (FLAG_Y | FLAG_X)
        self.f = f

    def alu_add8(self, a, b, carry=0):
        result = a + b + carry
        f = 0
        if (result & 0xFF) == 0:
            f |= FLAG_Z
        if result & 0x80:
            f |= FLAG_S
        if ((a ^ b ^ result) & 0x10):
            f |= FLAG_H
        if ((a ^ ~b) & (a ^ result) & 0x80):
            f |= FLAG_PV
        if result > 0xFF:
            f |= FLAG_C
        f |= result & (FLAG_Y | FLAG_X)
        self.f = f
        return result & 0xFF

    def alu_sub8(self, a, b, carry=0):
        result = a - b - carry
        f = FLAG_N
        if (result & 0xFF) == 0:
            f |= FLAG_Z
        if result & 0x80:
            f |= FLAG_S
        if ((a ^ b ^ result) & 0x10):
            f |= FLAG_H
        if ((a ^ b) & (a ^ result) & 0x80):
            f |= FLAG_PV
        if result < 0:
            f |= FLAG_C
        f |= result & (FLAG_Y | FLAG_X)
        self.f = f
        return result & 0xFF

    def alu_and8(self, a, b):
        result = a & b
        self.set_szp(result)
        self.f = (self.f | FLAG_H) & ~(FLAG_C | FLAG_N)
        return result

    def alu_or8(self, a, b):
        result = a | b
        self.set_szp(result)
        self.f &= ~(FLAG_H | FLAG_C | FLAG_N)
        return result

    def alu_xor8(self, a, b):
        result = a ^ b
        self.set_szp(result)
        self.f &= ~(FLAG_H | FLAG_C | FLAG_N)
        return result

    def alu_cp8(self, a, b):
        # Same as alu_sub8 but doesn't return result; flags reflect comparison.
        self.alu_sub8(a, b, 0)

    def alu_inc8(self, v):
        result = (v + 1) & 0xFF
        f = self.f & FLAG_C
        if result == 0:
            f |= FLAG_Z
        if result & 0x80:
            f |= FLAG_S
        if (v & 0x0F) == 0x0F:
            f |= FLAG_H
        if v == 0x7F:
            f |= FLAG_PV
        f |= result & (FLAG_Y | FLAG_X)
        self.f = f
        return result

    def alu_dec8(self, v):
        result = (v - 1) & 0xFF
        f = (self.f & FLAG_C) | FLAG_N
        if result == 0:
            f |= FLAG_Z
        if result & 0x80:
            f |= FLAG_S
        if (v & 0x0F) == 0x00:
            f |= FLAG_H
        if v == 0x80:
            f |= FLAG_PV
        f |= result & (FLAG_Y | FLAG_X)
        self.f = f
        return result

    # -- Run loop --------------------------------------------------------

    def run(self, max_instructions=10_000_000, stop_at=None,
            progress_interval=1_000_000):
        """Execute up to ``max_instructions``, stopping early on a reached
        ``stop_at`` PC, a breakpoint callback returning True, or HALT.

        Returns the stop reason: 'stop_at', 'breakpoint', 'halt', or
        'limit' (budget exhausted). Note a SoftCard bus access can raise
        ``Yield`` out of a memory hook to switch CPUs; that propagates
        through this loop to the caller (the machine's scheduler)."""
        for _ in range(max_instructions):
            pc = self.pc
            if stop_at is not None and pc == stop_at:
                return 'stop_at'
            if pc in self.on_pc:
                if self.on_pc[pc](self):
                    return 'breakpoint'
            if self.halted:
                return 'halt'
            try:
                self.step()
            except Z80Halt as e:
                self._halt_msg = str(e)
                return 'halt'
            self.exec_count += 1
            if progress_interval and self.exec_count % progress_interval == 0:
                print(f"  Z-80 ... {self.exec_count:,} insns, PC=${self.pc:04X}")
        return 'limit'

    def step(self):
        """Execute one Z-80 instruction (with prefix handling)."""
        op = self.fetch8()
        self.r = ((self.r + 1) & 0x7F) | (self.r & 0x80)
        if self.trace:
            self._trace_instr(self.pc - 1, op)
        handler = OPCODES_MAIN.get(op)
        if handler is None:
            raise Z80Halt(f"unsupported main opcode ${op:02X} at PC=${self.pc-1:04X}")
        handler(self, op)

    def _trace_instr(self, addr, op):
        msg = (f"PC=${addr:04X} op=${op:02X} "
               f"AF=${self.af:04X} BC=${self.bc:04X} DE=${self.de:04X} "
               f"HL=${self.hl:04X} SP=${self.sp:04X}\n")
        if self.trace_file:
            self.trace_file.write(msg)
        else:
            print(msg, end='')


# Opcode dispatch tables -- populated below. Each entry is a function
# (cpu, op) -> None.
OPCODES_MAIN = {}
OPCODES_CB = {}
OPCODES_ED = {}
OPCODES_DD = {}
OPCODES_FD = {}


def _op(table, *codes):
    """Decorator to register an opcode handler in the given table."""
    def deco(fn):
        for c in codes:
            table[c] = fn
        return fn
    return deco


# ============================================================================
# 8-bit load instructions
# ============================================================================

# LD r,r' family ($40-$7F, except $76 which is HALT)
# Encoding: 01 ddd sss
#   ddd / sss: 0=B, 1=C, 2=D, 3=E, 4=H, 5=L, 6=(HL), 7=A
REG_NAMES = ['b', 'c', 'd', 'e', 'h', 'l', 'hl_indirect', 'a']


def _read_reg(cpu, idx):
    if idx == 6:
        return cpu.read8(cpu.hl)
    return getattr(cpu, REG_NAMES[idx])


def _write_reg(cpu, idx, val):
    if idx == 6:
        cpu.write8(cpu.hl, val)
        return
    setattr(cpu, REG_NAMES[idx], val & 0xFF)


def _ld_rr(cpu, op):
    dst = (op >> 3) & 7
    src = op & 7
    _write_reg(cpu, dst, _read_reg(cpu, src))


for _op_code in range(0x40, 0x80):
    if _op_code != 0x76:
        OPCODES_MAIN[_op_code] = _ld_rr


# HALT
@_op(OPCODES_MAIN, 0x76)
def _halt(cpu, op):
    cpu.halted = True


# LD r,n ($06, $0E, $16, $1E, $26, $2E, $36, $3E) -- encoding 00 rrr 110
def _ld_r_n(cpu, op):
    dst = (op >> 3) & 7
    n = cpu.fetch8()
    _write_reg(cpu, dst, n)


for _op_code in (0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E):
    OPCODES_MAIN[_op_code] = _ld_r_n


# LD A,(BC) / LD A,(DE) / LD A,(nn)
@_op(OPCODES_MAIN, 0x0A)
def _ld_a_bc(cpu, op):
    cpu.a = cpu.read8(cpu.bc)


@_op(OPCODES_MAIN, 0x1A)
def _ld_a_de(cpu, op):
    cpu.a = cpu.read8(cpu.de)


@_op(OPCODES_MAIN, 0x3A)
def _ld_a_nn(cpu, op):
    addr = cpu.fetch16()
    cpu.a = cpu.read8(addr)


# LD (BC),A / LD (DE),A / LD (nn),A
@_op(OPCODES_MAIN, 0x02)
def _ld_bc_a(cpu, op):
    cpu.write8(cpu.bc, cpu.a)


@_op(OPCODES_MAIN, 0x12)
def _ld_de_a(cpu, op):
    cpu.write8(cpu.de, cpu.a)


@_op(OPCODES_MAIN, 0x32)
def _ld_nn_a(cpu, op):
    addr = cpu.fetch16()
    cpu.write8(addr, cpu.a)


# ============================================================================
# 16-bit load instructions
# ============================================================================

@_op(OPCODES_MAIN, 0x01)
def _ld_bc_nn(cpu, op):
    cpu.bc = cpu.fetch16()


@_op(OPCODES_MAIN, 0x11)
def _ld_de_nn(cpu, op):
    cpu.de = cpu.fetch16()


@_op(OPCODES_MAIN, 0x21)
def _ld_hl_nn(cpu, op):
    cpu.hl = cpu.fetch16()


@_op(OPCODES_MAIN, 0x31)
def _ld_sp_nn(cpu, op):
    cpu.sp = cpu.fetch16()


@_op(OPCODES_MAIN, 0x22)
def _ld_nn_hl(cpu, op):
    addr = cpu.fetch16()
    cpu.write16(addr, cpu.hl)


@_op(OPCODES_MAIN, 0x2A)
def _ld_hl_nn_indirect(cpu, op):
    addr = cpu.fetch16()
    cpu.hl = cpu.read16(addr)


@_op(OPCODES_MAIN, 0xF9)
def _ld_sp_hl(cpu, op):
    cpu.sp = cpu.hl


# PUSH / POP
@_op(OPCODES_MAIN, 0xC5)
def _push_bc(cpu, op):
    cpu.push16(cpu.bc)


@_op(OPCODES_MAIN, 0xD5)
def _push_de(cpu, op):
    cpu.push16(cpu.de)


@_op(OPCODES_MAIN, 0xE5)
def _push_hl(cpu, op):
    cpu.push16(cpu.hl)


@_op(OPCODES_MAIN, 0xF5)
def _push_af(cpu, op):
    cpu.push16(cpu.af)


@_op(OPCODES_MAIN, 0xC1)
def _pop_bc(cpu, op):
    cpu.bc = cpu.pop16()


@_op(OPCODES_MAIN, 0xD1)
def _pop_de(cpu, op):
    cpu.de = cpu.pop16()


@_op(OPCODES_MAIN, 0xE1)
def _pop_hl(cpu, op):
    cpu.hl = cpu.pop16()


@_op(OPCODES_MAIN, 0xF1)
def _pop_af(cpu, op):
    cpu.af = cpu.pop16()


# EX DE,HL / EX (SP),HL / EX AF,AF' / EXX
@_op(OPCODES_MAIN, 0xEB)
def _ex_de_hl(cpu, op):
    cpu.de, cpu.hl = cpu.hl, cpu.de


@_op(OPCODES_MAIN, 0xE3)
def _ex_sp_hl(cpu, op):
    t = cpu.read16(cpu.sp)
    cpu.write16(cpu.sp, cpu.hl)
    cpu.hl = t


@_op(OPCODES_MAIN, 0x08)
def _ex_af_af(cpu, op):
    cpu.a, cpu.a_ = cpu.a_, cpu.a
    cpu.f, cpu.f_ = cpu.f_, cpu.f


@_op(OPCODES_MAIN, 0xD9)
def _exx(cpu, op):
    cpu.b, cpu.b_ = cpu.b_, cpu.b
    cpu.c, cpu.c_ = cpu.c_, cpu.c
    cpu.d, cpu.d_ = cpu.d_, cpu.d
    cpu.e, cpu.e_ = cpu.e_, cpu.e
    cpu.h, cpu.h_ = cpu.h_, cpu.h
    cpu.l, cpu.l_ = cpu.l_, cpu.l


# ============================================================================
# 8-bit arithmetic / logic
# ============================================================================

def _add_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_add8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0x80, 0x88):
    OPCODES_MAIN[_op_code] = _add_a_r


def _adc_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_add8(cpu.a, _read_reg(cpu, src), 1 if cpu.f & FLAG_C else 0)

for _op_code in range(0x88, 0x90):
    OPCODES_MAIN[_op_code] = _adc_a_r


def _sub_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_sub8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0x90, 0x98):
    OPCODES_MAIN[_op_code] = _sub_a_r


def _sbc_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_sub8(cpu.a, _read_reg(cpu, src), 1 if cpu.f & FLAG_C else 0)

for _op_code in range(0x98, 0xA0):
    OPCODES_MAIN[_op_code] = _sbc_a_r


def _and_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_and8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0xA0, 0xA8):
    OPCODES_MAIN[_op_code] = _and_a_r


def _xor_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_xor8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0xA8, 0xB0):
    OPCODES_MAIN[_op_code] = _xor_a_r


def _or_a_r(cpu, op):
    src = op & 7
    cpu.a = cpu.alu_or8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0xB0, 0xB8):
    OPCODES_MAIN[_op_code] = _or_a_r


def _cp_a_r(cpu, op):
    src = op & 7
    cpu.alu_cp8(cpu.a, _read_reg(cpu, src))

for _op_code in range(0xB8, 0xC0):
    OPCODES_MAIN[_op_code] = _cp_a_r


# Immediate ALU: ADD A,n / ADC A,n / SUB n / SBC A,n / AND n / XOR n / OR n / CP n
@_op(OPCODES_MAIN, 0xC6)
def _add_a_n(cpu, op):
    cpu.a = cpu.alu_add8(cpu.a, cpu.fetch8())


@_op(OPCODES_MAIN, 0xCE)
def _adc_a_n(cpu, op):
    cpu.a = cpu.alu_add8(cpu.a, cpu.fetch8(), 1 if cpu.f & FLAG_C else 0)


@_op(OPCODES_MAIN, 0xD6)
def _sub_n(cpu, op):
    cpu.a = cpu.alu_sub8(cpu.a, cpu.fetch8())


@_op(OPCODES_MAIN, 0xDE)
def _sbc_a_n(cpu, op):
    cpu.a = cpu.alu_sub8(cpu.a, cpu.fetch8(), 1 if cpu.f & FLAG_C else 0)


@_op(OPCODES_MAIN, 0xE6)
def _and_n(cpu, op):
    cpu.a = cpu.alu_and8(cpu.a, cpu.fetch8())


@_op(OPCODES_MAIN, 0xEE)
def _xor_n(cpu, op):
    cpu.a = cpu.alu_xor8(cpu.a, cpu.fetch8())


@_op(OPCODES_MAIN, 0xF6)
def _or_n(cpu, op):
    cpu.a = cpu.alu_or8(cpu.a, cpu.fetch8())


@_op(OPCODES_MAIN, 0xFE)
def _cp_n(cpu, op):
    cpu.alu_cp8(cpu.a, cpu.fetch8())


# INC r / DEC r
def _inc_r(cpu, op):
    dst = (op >> 3) & 7
    _write_reg(cpu, dst, cpu.alu_inc8(_read_reg(cpu, dst)))

for _op_code in (0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C):
    OPCODES_MAIN[_op_code] = _inc_r


def _dec_r(cpu, op):
    dst = (op >> 3) & 7
    _write_reg(cpu, dst, cpu.alu_dec8(_read_reg(cpu, dst)))

for _op_code in (0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D):
    OPCODES_MAIN[_op_code] = _dec_r


# 16-bit INC/DEC
@_op(OPCODES_MAIN, 0x03)
def _inc_bc(cpu, op):
    cpu.bc = (cpu.bc + 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x13)
def _inc_de(cpu, op):
    cpu.de = (cpu.de + 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x23)
def _inc_hl(cpu, op):
    cpu.hl = (cpu.hl + 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x33)
def _inc_sp(cpu, op):
    cpu.sp = (cpu.sp + 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x0B)
def _dec_bc(cpu, op):
    cpu.bc = (cpu.bc - 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x1B)
def _dec_de(cpu, op):
    cpu.de = (cpu.de - 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x2B)
def _dec_hl(cpu, op):
    cpu.hl = (cpu.hl - 1) & 0xFFFF


@_op(OPCODES_MAIN, 0x3B)
def _dec_sp(cpu, op):
    cpu.sp = (cpu.sp - 1) & 0xFFFF


# ADD HL,rr
def _add_hl_rr(cpu, op):
    pair = (op >> 4) & 3
    if pair == 0: v = cpu.bc
    elif pair == 1: v = cpu.de
    elif pair == 2: v = cpu.hl
    else: v = cpu.sp
    a, b = cpu.hl, v
    result = a + b
    f = cpu.f & ~(FLAG_H | FLAG_N | FLAG_C | FLAG_X | FLAG_Y)
    if ((a ^ b ^ result) & 0x1000):
        f |= FLAG_H
    if result > 0xFFFF:
        f |= FLAG_C
    cpu.hl = result & 0xFFFF
    f |= (cpu.h) & (FLAG_X | FLAG_Y)
    cpu.f = f


for _op_code in (0x09, 0x19, 0x29, 0x39):
    OPCODES_MAIN[_op_code] = _add_hl_rr


# ============================================================================
# Jumps and calls
# ============================================================================

@_op(OPCODES_MAIN, 0xC3)
def _jp_nn(cpu, op):
    cpu.pc = cpu.fetch16()


@_op(OPCODES_MAIN, 0xE9)
def _jp_hl(cpu, op):
    cpu.pc = cpu.hl


def _check_cond(cpu, cond_idx):
    """0=NZ, 1=Z, 2=NC, 3=C, 4=PO, 5=PE, 6=P, 7=M."""
    f = cpu.f
    if cond_idx == 0: return not (f & FLAG_Z)
    if cond_idx == 1: return bool(f & FLAG_Z)
    if cond_idx == 2: return not (f & FLAG_C)
    if cond_idx == 3: return bool(f & FLAG_C)
    if cond_idx == 4: return not (f & FLAG_PV)
    if cond_idx == 5: return bool(f & FLAG_PV)
    if cond_idx == 6: return not (f & FLAG_S)
    if cond_idx == 7: return bool(f & FLAG_S)


def _jp_cc_nn(cpu, op):
    cond = (op >> 3) & 7
    target = cpu.fetch16()
    if _check_cond(cpu, cond):
        cpu.pc = target

for _op_code in (0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA):
    OPCODES_MAIN[_op_code] = _jp_cc_nn


# JR e (unconditional relative)
@_op(OPCODES_MAIN, 0x18)
def _jr_e(cpu, op):
    e = cpu.fetch_signed8()
    cpu.pc = (cpu.pc + e) & 0xFFFF


# JR cc,e -- only the four conditions Z, NZ, C, NC are valid (cond_idx 0-3)
def _jr_cc_e(cpu, op):
    cond = (op >> 3) & 3  # NZ, Z, NC, C
    e = cpu.fetch_signed8()
    if _check_cond(cpu, cond):
        cpu.pc = (cpu.pc + e) & 0xFFFF


for _op_code in (0x20, 0x28, 0x30, 0x38):
    OPCODES_MAIN[_op_code] = _jr_cc_e


# DJNZ e
@_op(OPCODES_MAIN, 0x10)
def _djnz_e(cpu, op):
    e = cpu.fetch_signed8()
    cpu.b = (cpu.b - 1) & 0xFF
    if cpu.b != 0:
        cpu.pc = (cpu.pc + e) & 0xFFFF


# CALL nn
@_op(OPCODES_MAIN, 0xCD)
def _call_nn(cpu, op):
    target = cpu.fetch16()
    cpu.push16(cpu.pc)
    cpu.pc = target


# CALL cc,nn
def _call_cc_nn(cpu, op):
    cond = (op >> 3) & 7
    target = cpu.fetch16()
    if _check_cond(cpu, cond):
        cpu.push16(cpu.pc)
        cpu.pc = target

for _op_code in (0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC):
    OPCODES_MAIN[_op_code] = _call_cc_nn


# RET / RET cc
@_op(OPCODES_MAIN, 0xC9)
def _ret(cpu, op):
    cpu.pc = cpu.pop16()


def _ret_cc(cpu, op):
    cond = (op >> 3) & 7
    if _check_cond(cpu, cond):
        cpu.pc = cpu.pop16()

for _op_code in (0xC0, 0xC8, 0xD0, 0xD8, 0xE0, 0xE8, 0xF0, 0xF8):
    OPCODES_MAIN[_op_code] = _ret_cc


# RST n
def _rst(cpu, op):
    target = op & 0x38
    cpu.push16(cpu.pc)
    cpu.pc = target

for _op_code in (0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF):
    OPCODES_MAIN[_op_code] = _rst


# ============================================================================
# Misc / control
# ============================================================================

@_op(OPCODES_MAIN, 0x00)
def _nop(cpu, op):
    pass


@_op(OPCODES_MAIN, 0xF3)
def _di(cpu, op):
    cpu.iff1 = 0
    cpu.iff2 = 0


@_op(OPCODES_MAIN, 0xFB)
def _ei(cpu, op):
    cpu.iff1 = 1
    cpu.iff2 = 1


@_op(OPCODES_MAIN, 0x37)
def _scf(cpu, op):
    cpu.f = (cpu.f & ~(FLAG_H | FLAG_N)) | FLAG_C


@_op(OPCODES_MAIN, 0x3F)
def _ccf(cpu, op):
    if cpu.f & FLAG_C:
        cpu.f = (cpu.f & ~(FLAG_C | FLAG_N)) | FLAG_H
    else:
        cpu.f = (cpu.f & ~FLAG_N) | FLAG_C


@_op(OPCODES_MAIN, 0x2F)
def _cpl(cpu, op):
    cpu.a ^= 0xFF
    cpu.f |= FLAG_H | FLAG_N
    cpu.f = (cpu.f & ~(FLAG_X | FLAG_Y)) | (cpu.a & (FLAG_X | FLAG_Y))


# IN A,(n) / OUT (n),A
@_op(OPCODES_MAIN, 0xDB)
def _in_a_n(cpu, op):
    port = cpu.fetch8()
    handler = cpu.in_handlers.get(port)
    cpu.a = handler() if handler else 0xFF


@_op(OPCODES_MAIN, 0xD3)
def _out_n_a(cpu, op):
    port = cpu.fetch8()
    handler = cpu.out_handlers.get(port)
    if handler:
        handler(cpu.a)


# Rotate accumulator
@_op(OPCODES_MAIN, 0x07)
def _rlca(cpu, op):
    bit7 = (cpu.a >> 7) & 1
    cpu.a = ((cpu.a << 1) | bit7) & 0xFF
    cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C | FLAG_X | FLAG_Y))
    if bit7:
        cpu.f |= FLAG_C
    cpu.f |= cpu.a & (FLAG_X | FLAG_Y)


@_op(OPCODES_MAIN, 0x0F)
def _rrca(cpu, op):
    bit0 = cpu.a & 1
    cpu.a = (cpu.a >> 1) | (bit0 << 7)
    cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C | FLAG_X | FLAG_Y))
    if bit0:
        cpu.f |= FLAG_C
    cpu.f |= cpu.a & (FLAG_X | FLAG_Y)


@_op(OPCODES_MAIN, 0x17)
def _rla(cpu, op):
    old_c = 1 if cpu.f & FLAG_C else 0
    bit7 = (cpu.a >> 7) & 1
    cpu.a = ((cpu.a << 1) | old_c) & 0xFF
    cpu.f = cpu.f & ~(FLAG_H | FLAG_N | FLAG_C | FLAG_X | FLAG_Y)
    if bit7:
        cpu.f |= FLAG_C
    cpu.f |= cpu.a & (FLAG_X | FLAG_Y)


@_op(OPCODES_MAIN, 0x1F)
def _rra(cpu, op):
    old_c = 1 if cpu.f & FLAG_C else 0
    bit0 = cpu.a & 1
    cpu.a = (cpu.a >> 1) | (old_c << 7)
    cpu.f = cpu.f & ~(FLAG_H | FLAG_N | FLAG_C | FLAG_X | FLAG_Y)
    if bit0:
        cpu.f |= FLAG_C
    cpu.f |= cpu.a & (FLAG_X | FLAG_Y)


# ============================================================================
# Prefix dispatchers
# ============================================================================

@_op(OPCODES_MAIN, 0xCB)
def _prefix_cb(cpu, op):
    sub = cpu.fetch8()
    handler = OPCODES_CB.get(sub)
    if handler is None:
        raise Z80Halt(f"unsupported CB opcode ${sub:02X} at PC=${cpu.pc-2:04X}")
    handler(cpu, sub)


@_op(OPCODES_MAIN, 0xED)
def _prefix_ed(cpu, op):
    sub = cpu.fetch8()
    handler = OPCODES_ED.get(sub)
    if handler is None:
        raise Z80Halt(f"unsupported ED opcode ${sub:02X} at PC=${cpu.pc-2:04X}")
    handler(cpu, sub)


@_op(OPCODES_MAIN, 0xDD)
def _prefix_dd(cpu, op):
    sub = cpu.fetch8()
    handler = OPCODES_DD.get(sub)
    if handler is None:
        raise Z80Halt(f"unsupported DD opcode ${sub:02X} at PC=${cpu.pc-2:04X}")
    handler(cpu, sub)


@_op(OPCODES_MAIN, 0xFD)
def _prefix_fd(cpu, op):
    sub = cpu.fetch8()
    handler = OPCODES_FD.get(sub)
    if handler is None:
        raise Z80Halt(f"unsupported FD opcode ${sub:02X} at PC=${cpu.pc-2:04X}")
    handler(cpu, sub)


# ============================================================================
# CB-prefixed: bit operations on r / (HL)
# ============================================================================
# Encoding: CB <op>
#   op = 00 ooo rrr  (rotate/shift)
#   op = 01 bbb rrr  BIT b,r
#   op = 10 bbb rrr  RES b,r
#   op = 11 bbb rrr  SET b,r

def _cb_rot_shift(cpu, op):
    op_kind = (op >> 3) & 7
    reg = op & 7
    val = _read_reg(cpu, reg)
    if op_kind == 0:    # RLC
        b7 = (val >> 7) & 1
        result = ((val << 1) | b7) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b7: cpu.f |= FLAG_C
    elif op_kind == 1:  # RRC
        b0 = val & 1
        result = ((val >> 1) | (b0 << 7)) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b0: cpu.f |= FLAG_C
    elif op_kind == 2:  # RL
        old_c = 1 if cpu.f & FLAG_C else 0
        b7 = (val >> 7) & 1
        result = ((val << 1) | old_c) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b7: cpu.f |= FLAG_C
    elif op_kind == 3:  # RR
        old_c = 1 if cpu.f & FLAG_C else 0
        b0 = val & 1
        result = ((val >> 1) | (old_c << 7)) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b0: cpu.f |= FLAG_C
    elif op_kind == 4:  # SLA
        b7 = (val >> 7) & 1
        result = (val << 1) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b7: cpu.f |= FLAG_C
    elif op_kind == 5:  # SRA (arithmetic)
        b0 = val & 1
        b7 = val & 0x80
        result = ((val >> 1) | b7) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b0: cpu.f |= FLAG_C
    elif op_kind == 6:  # SLL (undocumented)
        b7 = (val >> 7) & 1
        result = ((val << 1) | 1) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b7: cpu.f |= FLAG_C
    else:               # SRL
        b0 = val & 1
        result = (val >> 1) & 0xFF
        cpu.f = (cpu.f & ~(FLAG_H | FLAG_N | FLAG_C))
        if b0: cpu.f |= FLAG_C
    cpu.set_szp(result)
    # set_szp clobbered carry bits we set; restore
    if op_kind in (0, 2, 4, 6):
        if (val >> 7) & 1: cpu.f |= FLAG_C
    elif op_kind in (1, 3, 5, 7):
        if val & 1: cpu.f |= FLAG_C
    _write_reg(cpu, reg, result)

for _op_code in range(0x00, 0x40):
    OPCODES_CB[_op_code] = _cb_rot_shift


def _cb_bit(cpu, op):
    bit = (op >> 3) & 7
    reg = op & 7
    val = _read_reg(cpu, reg)
    test = val & (1 << bit)
    f = (cpu.f & FLAG_C) | FLAG_H
    if test == 0:
        f |= FLAG_Z | FLAG_PV
    if bit == 7 and test:
        f |= FLAG_S
    cpu.f = f

for _op_code in range(0x40, 0x80):
    OPCODES_CB[_op_code] = _cb_bit


def _cb_res(cpu, op):
    bit = (op >> 3) & 7
    reg = op & 7
    val = _read_reg(cpu, reg)
    val &= ~(1 << bit) & 0xFF
    _write_reg(cpu, reg, val)

for _op_code in range(0x80, 0xC0):
    OPCODES_CB[_op_code] = _cb_res


def _cb_set(cpu, op):
    bit = (op >> 3) & 7
    reg = op & 7
    val = _read_reg(cpu, reg)
    val |= 1 << bit
    _write_reg(cpu, reg, val)

for _op_code in range(0xC0, 0x100):
    OPCODES_CB[_op_code] = _cb_set


# ============================================================================
# ED-prefixed: extended ops (subset, on demand)
# ============================================================================

@_op(OPCODES_ED, 0xB0)
def _ldir(cpu, op):
    """Block copy: while BC != 0, (DE) <- (HL); HL++, DE++, BC--; if BC != 0,
    PC -= 2 to repeat."""
    while True:
        cpu.write8(cpu.de, cpu.read8(cpu.hl))
        cpu.hl = (cpu.hl + 1) & 0xFFFF
        cpu.de = (cpu.de + 1) & 0xFFFF
        cpu.bc = (cpu.bc - 1) & 0xFFFF
        if cpu.bc == 0:
            break
    cpu.f &= ~(FLAG_H | FLAG_PV | FLAG_N)


@_op(OPCODES_ED, 0xB8)
def _lddr(cpu, op):
    while True:
        cpu.write8(cpu.de, cpu.read8(cpu.hl))
        cpu.hl = (cpu.hl - 1) & 0xFFFF
        cpu.de = (cpu.de - 1) & 0xFFFF
        cpu.bc = (cpu.bc - 1) & 0xFFFF
        if cpu.bc == 0:
            break
    cpu.f &= ~(FLAG_H | FLAG_PV | FLAG_N)


@_op(OPCODES_ED, 0x46)
def _im0(cpu, op):
    cpu.im = 0


@_op(OPCODES_ED, 0x56)
def _im1(cpu, op):
    cpu.im = 1


@_op(OPCODES_ED, 0x5E)
def _im2(cpu, op):
    cpu.im = 2


# LD (nn),BC / LD (nn),DE / LD (nn),SP -- ED 43, ED 53, ED 73
@_op(OPCODES_ED, 0x43)
def _ld_nn_bc(cpu, op):
    addr = cpu.fetch16()
    cpu.write16(addr, cpu.bc)


@_op(OPCODES_ED, 0x53)
def _ld_nn_de(cpu, op):
    addr = cpu.fetch16()
    cpu.write16(addr, cpu.de)


@_op(OPCODES_ED, 0x73)
def _ld_nn_sp(cpu, op):
    addr = cpu.fetch16()
    cpu.write16(addr, cpu.sp)


# LD BC,(nn) / LD DE,(nn) / LD SP,(nn) -- ED 4B, ED 5B, ED 7B
@_op(OPCODES_ED, 0x4B)
def _ld_bc_nn_indirect(cpu, op):
    addr = cpu.fetch16()
    cpu.bc = cpu.read16(addr)


@_op(OPCODES_ED, 0x5B)
def _ld_de_nn_indirect(cpu, op):
    addr = cpu.fetch16()
    cpu.de = cpu.read16(addr)


@_op(OPCODES_ED, 0x7B)
def _ld_sp_nn_indirect(cpu, op):
    addr = cpu.fetch16()
    cpu.sp = cpu.read16(addr)


# ED 44 NEG -- A = 0 - A
@_op(OPCODES_ED, 0x44)
def _neg(cpu, op):
    cpu.a = cpu.alu_sub8(0, cpu.a)


# ED 45 RETN, ED 4D RETI -- treat both as plain RET for our purposes
@_op(OPCODES_ED, 0x45, 0x4D, 0x55, 0x5D, 0x65, 0x6D, 0x75, 0x7D)
def _retn(cpu, op):
    cpu.iff1 = cpu.iff2
    cpu.pc = cpu.pop16()


# ED 47 LD I,A / ED 4F LD R,A / ED 57 LD A,I / ED 5F LD A,R
@_op(OPCODES_ED, 0x47)
def _ld_i_a(cpu, op):
    cpu.i = cpu.a


@_op(OPCODES_ED, 0x4F)
def _ld_r_a(cpu, op):
    cpu.r = cpu.a


@_op(OPCODES_ED, 0x57)
def _ld_a_i(cpu, op):
    cpu.a = cpu.i
    f = cpu.f & FLAG_C
    if cpu.a == 0: f |= FLAG_Z
    if cpu.a & 0x80: f |= FLAG_S
    if cpu.iff2: f |= FLAG_PV
    cpu.f = f


@_op(OPCODES_ED, 0x5F)
def _ld_a_r(cpu, op):
    cpu.a = cpu.r
    f = cpu.f & FLAG_C
    if cpu.a == 0: f |= FLAG_Z
    if cpu.a & 0x80: f |= FLAG_S
    if cpu.iff2: f |= FLAG_PV
    cpu.f = f


# ED 67 RRD / ED 6F RLD -- BCD-shift between A and (HL)
@_op(OPCODES_ED, 0x6F)
def _rld(cpu, op):
    m = cpu.read8(cpu.hl)
    new_a = (cpu.a & 0xF0) | (m >> 4)
    new_m = ((m << 4) | (cpu.a & 0x0F)) & 0xFF
    cpu.a = new_a
    cpu.write8(cpu.hl, new_m)
    cpu.set_szp(cpu.a)
    cpu.f &= ~(FLAG_H | FLAG_N)


@_op(OPCODES_ED, 0x67)
def _rrd(cpu, op):
    m = cpu.read8(cpu.hl)
    new_a = (cpu.a & 0xF0) | (m & 0x0F)
    new_m = ((m >> 4) | ((cpu.a & 0x0F) << 4)) & 0xFF
    cpu.a = new_a
    cpu.write8(cpu.hl, new_m)
    cpu.set_szp(cpu.a)
    cpu.f &= ~(FLAG_H | FLAG_N)


# ED 4A/5A/6A/7A ADC HL,rr  ;  ED 42/52/62/72 SBC HL,rr
def _adc_hl_rr(cpu, op):
    pair = (op >> 4) & 3
    v = (cpu.bc, cpu.de, cpu.hl, cpu.sp)[pair]
    a, b, c = cpu.hl, v, (1 if cpu.f & FLAG_C else 0)
    result = a + b + c
    f = 0
    if (result & 0xFFFF) == 0: f |= FLAG_Z
    if result & 0x8000: f |= FLAG_S
    if ((a ^ b ^ result) & 0x1000): f |= FLAG_H
    if ((a ^ ~b) & (a ^ result) & 0x8000): f |= FLAG_PV
    if result > 0xFFFF: f |= FLAG_C
    cpu.hl = result & 0xFFFF
    cpu.f = f


def _sbc_hl_rr(cpu, op):
    pair = (op >> 4) & 3
    v = (cpu.bc, cpu.de, cpu.hl, cpu.sp)[pair]
    a, b, c = cpu.hl, v, (1 if cpu.f & FLAG_C else 0)
    result = a - b - c
    f = FLAG_N
    if (result & 0xFFFF) == 0: f |= FLAG_Z
    if result & 0x8000: f |= FLAG_S
    if ((a ^ b ^ result) & 0x1000): f |= FLAG_H
    if ((a ^ b) & (a ^ result) & 0x8000): f |= FLAG_PV
    if result < 0: f |= FLAG_C
    cpu.hl = result & 0xFFFF
    cpu.f = f


for _op_code in (0x4A, 0x5A, 0x6A, 0x7A):
    OPCODES_ED[_op_code] = _adc_hl_rr
for _op_code in (0x42, 0x52, 0x62, 0x72):
    OPCODES_ED[_op_code] = _sbc_hl_rr


# ============================================================================
# DD- and FD-prefixed opcodes (IX / IY)
# ============================================================================
# Most DD opcodes are HL-replaced-by-IX of main-table opcodes, with (HL)
# replaced by (IX+d) (signed displacement byte after the opcode). FD is the
# IY counterpart. We implement the subset the SoftCard CP/M code uses --
# enough to run the cold-boot generator and BIOS init.

def _make_idx_opcodes(reg_attr):
    """Build the dispatch table for DD- or FD-prefixed opcodes.

    reg_attr is the Z80CPU attribute name for the index register: 'ix' or 'iy'.
    Returns a dict of opcode -> handler(cpu, op).
    """
    table = {}

    def _idx_get(c):
        return getattr(c, reg_attr)

    def _idx_set(c, v):
        setattr(c, reg_attr, v & 0xFFFF)

    def _idx_addr(c):
        d = c.fetch_signed8()
        return (_idx_get(c) + d) & 0xFFFF

    # DD 21 nn -- LD IX,nn
    def _ld_idx_nn(c, op):
        _idx_set(c, c.fetch16())
    table[0x21] = _ld_idx_nn

    # DD 22 nn -- LD (nn),IX
    def _ld_nn_idx(c, op):
        addr = c.fetch16()
        c.write16(addr, _idx_get(c))
    table[0x22] = _ld_nn_idx

    # DD 2A nn -- LD IX,(nn)
    def _ld_idx_nn_indirect(c, op):
        addr = c.fetch16()
        _idx_set(c, c.read16(addr))
    table[0x2A] = _ld_idx_nn_indirect

    # DD 23 INC IX / DD 2B DEC IX
    def _inc_idx(c, op):
        _idx_set(c, _idx_get(c) + 1)
    table[0x23] = _inc_idx

    def _dec_idx(c, op):
        _idx_set(c, _idx_get(c) - 1)
    table[0x2B] = _dec_idx

    # DD 09/19/29/39 -- ADD IX,rr (rr = BC, DE, IX, SP)
    def _add_idx_rr(c, op):
        pair = (op >> 4) & 3
        if pair == 0: v = c.bc
        elif pair == 1: v = c.de
        elif pair == 2: v = _idx_get(c)
        else: v = c.sp
        a, b = _idx_get(c), v
        result = a + b
        f = c.f & ~(FLAG_H | FLAG_N | FLAG_C)
        if ((a ^ b ^ result) & 0x1000): f |= FLAG_H
        if result > 0xFFFF: f |= FLAG_C
        _idx_set(c, result)
        c.f = f
    for _opc in (0x09, 0x19, 0x29, 0x39):
        table[_opc] = _add_idx_rr

    # DD 36 d n -- LD (IX+d),n
    def _ld_idxd_n(c, op):
        addr = _idx_addr(c)
        n = c.fetch8()
        c.write8(addr, n)
    table[0x36] = _ld_idxd_n

    # DD 7E d -- LD A,(IX+d)
    # Generic: LD r,(IX+d) for r in (B, C, D, E, H, L, A); skip $76 (HALT analog).
    # Encoding: 01 ddd 110 -> opcodes $46, $4E, $56, $5E, $66, $6E, $7E
    def _make_ld_r_idxd(reg_idx):
        def _h(c, op):
            v = c.read8(_idx_addr(c))
            _write_reg(c, reg_idx, v)
        return _h
    for _r, _opc in [(0, 0x46), (1, 0x4E), (2, 0x56), (3, 0x5E),
                      (4, 0x66), (5, 0x6E), (7, 0x7E)]:
        table[_opc] = _make_ld_r_idxd(_r)

    # DD 70 d -- LD (IX+d),B  / similar for C, D, E, H, L, A
    # Encoding: 01 110 sss -> opcodes $70, $71, $72, $73, $74, $75, $77
    def _make_ld_idxd_r(reg_idx):
        def _h(c, op):
            addr = _idx_addr(c)
            c.write8(addr, _read_reg(c, reg_idx))
        return _h
    for _r, _opc in [(0, 0x70), (1, 0x71), (2, 0x72), (3, 0x73),
                      (4, 0x74), (5, 0x75), (7, 0x77)]:
        table[_opc] = _make_ld_idxd_r(_r)

    # DD 86 d -- ADD A,(IX+d)
    # Generic ALU on (IX+d): opcodes $86, $8E, $96, $9E, $A6, $AE, $B6, $BE
    def _alu_idxd(c, op):
        kind = (op >> 3) & 7
        v = c.read8(_idx_addr(c))
        if kind == 0:   c.a = c.alu_add8(c.a, v)
        elif kind == 1: c.a = c.alu_add8(c.a, v, 1 if c.f & FLAG_C else 0)
        elif kind == 2: c.a = c.alu_sub8(c.a, v)
        elif kind == 3: c.a = c.alu_sub8(c.a, v, 1 if c.f & FLAG_C else 0)
        elif kind == 4: c.a = c.alu_and8(c.a, v)
        elif kind == 5: c.a = c.alu_xor8(c.a, v)
        elif kind == 6: c.a = c.alu_or8(c.a, v)
        else:           c.alu_cp8(c.a, v)
    for _opc in (0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE):
        table[_opc] = _alu_idxd

    # DD 34 d -- INC (IX+d) / DD 35 d -- DEC (IX+d)
    def _inc_idxd(c, op):
        addr = _idx_addr(c)
        c.write8(addr, c.alu_inc8(c.read8(addr)))
    table[0x34] = _inc_idxd

    def _dec_idxd(c, op):
        addr = _idx_addr(c)
        c.write8(addr, c.alu_dec8(c.read8(addr)))
    table[0x35] = _dec_idxd

    # DD E1 POP IX / DD E5 PUSH IX
    def _pop_idx(c, op):
        _idx_set(c, c.pop16())
    table[0xE1] = _pop_idx

    def _push_idx(c, op):
        c.push16(_idx_get(c))
    table[0xE5] = _push_idx

    # DD E9 JP (IX) -- PC = IX
    def _jp_idx(c, op):
        c.pc = _idx_get(c)
    table[0xE9] = _jp_idx

    # DD F9 LD SP,IX
    def _ld_sp_idx(c, op):
        c.sp = _idx_get(c)
    table[0xF9] = _ld_sp_idx

    # DD E3 EX (SP),IX
    def _ex_sp_idx(c, op):
        t = c.read16(c.sp)
        c.write16(c.sp, _idx_get(c))
        _idx_set(c, t)
    table[0xE3] = _ex_sp_idx

    # DD CB d <op> -- bit ops on (IX+d). The displacement comes BEFORE the
    # final op byte. Most just RES/SET/BIT on (IX+d); some also store the
    # result in a register (undocumented variant). We implement the basic
    # forms.
    def _ddcb(c, op):
        d = c.fetch_signed8()
        sub = c.fetch8()
        addr = (_idx_get(c) + d) & 0xFFFF
        kind = (sub >> 6) & 3
        bit = (sub >> 3) & 7
        v = c.read8(addr)
        if kind == 0:  # rotate/shift
            shift_kind = (sub >> 3) & 7
            if shift_kind == 0:    # RLC
                b7 = (v >> 7) & 1
                v2 = ((v << 1) | b7) & 0xFF
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b7 else 0)
            elif shift_kind == 1:  # RRC
                b0 = v & 1
                v2 = (v >> 1) | (b0 << 7)
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b0 else 0)
            elif shift_kind == 2:  # RL
                old_c = 1 if c.f & FLAG_C else 0
                b7 = (v >> 7) & 1
                v2 = ((v << 1) | old_c) & 0xFF
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b7 else 0)
            elif shift_kind == 3:  # RR
                old_c = 1 if c.f & FLAG_C else 0
                b0 = v & 1
                v2 = (v >> 1) | (old_c << 7)
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b0 else 0)
            elif shift_kind == 4:  # SLA
                b7 = (v >> 7) & 1
                v2 = (v << 1) & 0xFF
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b7 else 0)
            elif shift_kind == 5:  # SRA
                b0 = v & 1
                b7 = v & 0x80
                v2 = (v >> 1) | b7
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b0 else 0)
            elif shift_kind == 6:  # SLL
                b7 = (v >> 7) & 1
                v2 = ((v << 1) | 1) & 0xFF
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b7 else 0)
            else:                   # SRL
                b0 = v & 1
                v2 = (v >> 1)
                c.f = (c.f & ~(FLAG_H | FLAG_N | FLAG_C)) | (FLAG_C if b0 else 0)
            c.set_szp(v2)
            # set_szp clobbers our carry; restore it
            if shift_kind in (0, 2, 4, 6):
                c.f = (c.f & ~FLAG_C) | (FLAG_C if (v >> 7) & 1 else 0)
            else:
                c.f = (c.f & ~FLAG_C) | (FLAG_C if v & 1 else 0)
            c.write8(addr, v2)
        elif kind == 1:  # BIT b,(IX+d)
            test = v & (1 << bit)
            f = (c.f & FLAG_C) | FLAG_H
            if test == 0: f |= FLAG_Z | FLAG_PV
            if bit == 7 and test: f |= FLAG_S
            c.f = f
        elif kind == 2:  # RES b,(IX+d)
            v &= ~(1 << bit) & 0xFF
            c.write8(addr, v)
        else:            # SET b,(IX+d)
            v |= 1 << bit
            c.write8(addr, v)
    table[0xCB] = _ddcb

    return table


OPCODES_DD.update(_make_idx_opcodes('ix'))
OPCODES_FD.update(_make_idx_opcodes('iy'))
