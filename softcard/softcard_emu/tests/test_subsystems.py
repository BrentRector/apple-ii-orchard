"""Isolation unit tests for the extracted emulator subsystems.

These run without a full boot, so they pin the module contracts the
machine relies on: keyboard strobe/poll counters, the SoftCard switch
trigger + resume rule, the realmap translation, and the Bus dispatch /
return-value contracts (including language-card data routing and the
6502 fetch-banking path that lets the 60K system run from LC RAM).
"""

from nibbler.cpu import CPU6502
from nibbler.z80_cpu import Z80CPU

from softcard_emu.keyboard import Keyboard
from softcard_emu.switch import SoftCardSwitch, realmap
from softcard_emu.langcard import LanguageCard
from softcard_emu.bus import Bus


# -- Keyboard ----------------------------------------------------------

def test_keyboard_strobe_and_side_counters():
    kbd = Keyboard()
    kbd.type_keys("AB")
    # first read latches 'A' with the strobe bit set, counts on 6502 side
    v = kbd.read_data('6502')
    assert v == (ord('A') | 0x80)
    assert kbd.polls_6502 == 1 and kbd.polls_z80 == 0
    # while a key is pending, repeat reads return it without dequeuing
    assert kbd.read_data('z80') == (ord('A') | 0x80)
    assert kbd.polls_z80 == 1
    # clearing the strobe drops bit 7; next read latches 'B'
    assert kbd.clear_strobe() == 0x00
    assert kbd.read_data('6502') == (ord('B') | 0x80)


# -- SoftCardSwitch + realmap ------------------------------------------

def test_switch_6502_trigger_and_resume_rule():
    sw = SoftCardSwitch()
    mem = bytearray(65536)
    mem[0x03C0] = 0x8D            # STA abs at the warm-loop store
    mem[0x1185] = 0x8D            # STA abs at the boot scanner's slot probe
    # Any $C700 store toggles the CPU -- a per-write hardware toggle, not gated
    # to a routine. Warm loop (pc < $0400): STA -> resume at pc+3.
    assert sw.trigger_6502_write(0xC700, 0x03C0, mem.__getitem__) is True
    assert sw.resume_6502 == 0x03C3
    # The same applies to the boot slot scanner's probe at pc=$1185 (>= $0400):
    # this is what lets the disk detect the SoftCard without a fixup hook.
    assert sw.trigger_6502_write(0xC700, 0x1185, mem.__getitem__) is True
    assert sw.resume_6502 == 0x1188
    # non-$8D opcode -> resume at pc (no skip)
    mem[0x0380] = 0xEA           # NOP
    assert sw.trigger_6502_write(0xC7FF, 0x0380, mem.__getitem__) is True
    assert sw.resume_6502 == 0x0380
    # $C400 is NOT a trigger ($C700 only -- matches is_z80_switch / slot 7)
    assert sw.trigger_6502_write(0xC400, 0x03C0, mem.__getitem__) is False
    # unrelated page: no trigger
    assert sw.trigger_6502_write(0xC300, 0x0100, mem.__getitem__) is False


def test_switch_z80_and_realmap():
    sw = SoftCardSwitch()
    assert sw.is_z80_switch(0xC700) is True
    assert sw.is_z80_switch(0xC7FF) is True
    assert sw.is_z80_switch(0xC600) is False
    # documented translation boundaries
    assert realmap(0x0000) == 0x1000
    assert realmap(0xB000) == 0xD000
    assert realmap(0xE000) == 0xC000     # Z-80 $E000 -> Apple I/O page
    assert realmap(0xF000) == 0x0000


def test_switch_first_z80_start():
    sw = SoftCardSwitch()
    z = Z80CPU()
    z.pc = 0x1234
    sw.on_first_z80_start(z)
    assert z.pc == 0 and z.sp == 0 and sw.z80_started
    z.pc = 0x5678
    sw.on_first_z80_start(z)              # idempotent after first start
    assert z.pc == 0x5678


# -- Bus ---------------------------------------------------------------

def _bus_with_cpus(videx=None):
    mem = bytearray(65536)
    lc = LanguageCard(mem)
    kbd = Keyboard()
    sw = SoftCardSwitch()
    bus = Bus(mem, lc=lc, videx=videx, kbd=kbd, switch=sw)
    c = CPU6502(slot=6)
    c.mem = mem
    z = Z80CPU()
    z.mem = mem
    bus.attach_6502(c)
    bus.attach_z80(z)
    return bus, c, z, lc, kbd, mem


def test_bus_flat_and_return_contracts():
    bus, c, z, lc, kbd, mem = _bus_with_cpus()
    # 6502 data: write returns None, lands in flat RAM; read returns int
    assert bus.write6502(0x2000, 0xAB) is None
    assert mem[0x2000] == 0xAB
    assert bus.read6502(0x2000) == 0xAB
    # Z-80 data: writez80 claims every access (True), reads a concrete int.
    # realmap(0x1000) == 0x2000 (Apple), so this aliases the byte above.
    assert bus.writez80(0x1000, 0xCD) is True
    assert mem[0x2000] == 0xCD
    val = bus.readz80(0x1000)
    assert val == 0xCD and val is not None


def test_bus_language_card_routing_and_fetch_banking():
    bus, c, z, lc, kbd, mem = _bus_with_cpus()
    # enable RAM read + write on bank 2 ($C083 x2)
    bus.read6502(0xC083)
    bus.read6502(0xC083)
    assert lc.read_ram and lc.write_en and lc.bank2
    bus.write6502(0xD000, 0x55)
    assert bus.read6502(0xD000) == 0x55
    assert bus.fetch6502(0xD000) == 0x55           # fetch honors banking
    # switch to bank 1 ($C08B x2): distinct storage, fetch follows it
    bus.read6502(0xC08B)
    bus.read6502(0xC08B)
    bus.write6502(0xD000, 0x66)
    assert bus.fetch6502(0xD000) == 0x66
    bus.read6502(0xC083); bus.read6502(0xC083)     # back to bank 2
    assert bus.fetch6502(0xD000) == 0x55
    # below $D000 the fetch path is the flat plane (Videx ROM lives there)
    mem[0xC800] = 0x42
    assert bus.fetch6502(0xC800) == 0x42


def test_bus_keyboard_dispatch():
    bus, c, z, lc, kbd, mem = _bus_with_cpus()
    kbd.type_keys("Z")
    assert bus.read6502(0xC000) == (ord('Z') | 0x80)
    assert kbd.polls_6502 == 1
    assert bus.read6502(0xC010) == 0x00            # strobe clear
    assert not (kbd.current & 0x80)
