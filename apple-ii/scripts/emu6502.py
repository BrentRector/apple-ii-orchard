#!/usr/bin/env python3
"""
6502 Emulator for Apple Panic boot tracing.

Provides a WOZ2 disk image reader with nibble streaming for emulated Disk II
I/O, and helper functions for decoding 6-and-2 and 5-and-3 GCR sectors.

The 6502 core itself is the shared one in ``nibbler.cpu``; it is re-exported
from this module (see the import below) so existing callers are unaffected.
Together they emulate enough Apple II hardware (disk controller soft
switches, keyboard strobe) to boot the copy-protected Apple Panic disk
through all stages and capture decrypted game code from memory.

Classes:
    WOZDisk  -- WOZ2 disk image parser and nibble streamer
    CPU6502  -- re-exported from nibbler.cpu (NMOS 6502 with Apple II I/O)

Functions:
    decode_boot_sector_from_woz() -- Decode 6-and-2 boot sector(s) from WOZ
    decode_53_sector()            -- Decode a single 5-and-3 sector
    decode_track_53()             -- Decode all 5-and-3 sectors on a track
    decode_44()                   -- Decode 4-and-4 address field bytes
    build_gcr_table()             -- Build GCR table in emulated memory

Usage:
    # As a library (imported by boot_emulate.py and boot_emulate_full.py):
    from emu6502 import CPU6502, WOZDisk, decode_boot_sector_from_woz

    # Or run directly for a basic boot trace:
    python emu6502.py

    Paths default to repo-relative locations (apple-ii/apple-panic/ for inputs,
    apple-ii/apple-panic/output/ for generated files).

Expected output (when run directly):
    Boot trace showing milestone addresses, sector reads, and final CPU state.
"""
import struct
import sys
from pathlib import Path

# ── WOZ2 reader and nibble streamer ──────────────────────────────────

# 6-and-2 GCR encoding table: maps 6-bit values (0-63) to valid disk nibbles
ENCODE_62 = [
    0x96, 0x97, 0x9A, 0x9B, 0x9D, 0x9E, 0x9F, 0xA6,
    0xA7, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB2, 0xB3,
    0xB4, 0xB5, 0xB6, 0xB7, 0xB9, 0xBA, 0xBB, 0xBC,
    0xBD, 0xBE, 0xBF, 0xCB, 0xCD, 0xCE, 0xCF, 0xD3,
    0xD6, 0xD7, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE,
    0xDF, 0xE5, 0xE6, 0xE7, 0xE9, 0xEA, 0xEB, 0xEC,
    0xED, 0xEE, 0xEF, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6,
    0xF7, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF,
]
# Reverse lookup: disk nibble -> 6-bit decoded value
DECODE_62 = {v: i for i, v in enumerate(ENCODE_62)}


class WOZDisk:
    """WOZ2 disk image with nibble streaming for emulated disk I/O."""

    def __init__(self, path):
        self.nibble_tracks = {}  # quarter-track -> [nibbles]
        self.current_qtrack = 0  # quarter-track position
        self.nibble_pos = 0
        self.motor_on = True
        self.phases = [False] * 4  # stepper phases
        self.data_latch = 0
        self.q6 = False  # Q6 state (False = data latch read)
        self.q7 = False  # Q7 state (False = read mode)
        self._parse(path)

    def _parse(self, path):
        """Parse WOZ2 file and build nibble arrays for all available tracks."""
        with open(path, 'rb') as f:
            data = f.read()
        tmap = data[88:88 + 160]
        tracks_raw = {}
        for i in range(160):
            offset = 256 + i * 8
            sb = struct.unpack_from('<H', data, offset)[0]
            bc = struct.unpack_from('<H', data, offset + 2)[0]
            bits = struct.unpack_from('<I', data, offset + 4)[0]
            if sb == 0 and bc == 0:
                continue
            tracks_raw[i] = {
                'bit_count': bits,
                'data': data[sb * 512:sb * 512 + bc * 512],
            }
        # Convert each track to nibbles
        for qt in range(160):
            tidx = tmap[qt]
            if tidx == 0xFF or tidx not in tracks_raw:
                continue
            t = tracks_raw[tidx]
            self.nibble_tracks[qt] = self._to_nibbles(t['data'], t['bit_count'])

    @staticmethod
    def _to_nibbles(track_data, bit_count):
        """Convert raw track bytes to a nibble stream with bit-doubling.

        Doubles the bit stream before nibble extraction to properly handle
        sectors that span the track wrap boundary -- a copy protection
        technique used by Apple Panic.
        """
        bits = []
        for b in track_data:
            for i in range(7, -1, -1):
                bits.append((b >> i) & 1)
                if len(bits) >= bit_count:
                    break
            if len(bits) >= bit_count:
                break
        # Double the bit stream to handle sectors spanning the track
        # boundary (copy protection technique used by Apple Panic)
        double_bits = bits + bits
        nibbles = []
        current = 0
        for b in double_bits:
            current = ((current << 1) | b) & 0xFF
            if current & 0x80:
                nibbles.append(current)
                current = 0
        return nibbles

    def read_nibble(self):
        """Return next nibble from current track (called when Q6L is read)."""
        if not self.motor_on:
            return 0x00
        qt = self.current_qtrack
        track = self.nibble_tracks.get(qt)
        if not track or len(track) == 0:
            return 0xFF
        nib = track[self.nibble_pos % len(track)]
        self.nibble_pos = (self.nibble_pos + 1) % len(track)
        return nib

    def step_phase(self, phase, on):
        """Handle stepper motor phase switch. Phases 0-3 control head position."""
        self.phases[phase] = on
        if not on:
            return
        # Determine direction based on which phase turned on relative to current.
        # The stepper motor has 4 phases; advancing to the next phase moves inward,
        # retreating to the previous phase moves outward. diff==2 means half-track
        # (ambiguous direction), which we ignore.
        current_phase = (self.current_qtrack // 2) % 4
        diff = (phase - current_phase + 4) % 4
        if diff == 1:
            self.current_qtrack = min(self.current_qtrack + 2, 159)  # Move inward
        elif diff == 3:
            self.current_qtrack = max(self.current_qtrack - 2, 0)    # Move outward
        elif diff == 2:
            pass  # half-track: don't move for now
        self.nibble_pos = 0  # reset position on track change


# ── 6502 CPU Emulator ────────────────────────────────────────────────
#
# The CPU core is NOT defined here.  It lives in the shared ``nibbler``
# package (``shared/nibbler/cpu.py``) and is re-exported below so that
# ``from emu6502 import CPU6502`` keeps working for the boot scripts.
#
# This file used to carry its own near-copy of that class.  The two had
# drifted: the fork had a decimal-mode ADC/SBC the shared core lacked,
# while the shared core had breakpoints, run(), and a fetch_hook the fork
# lacked.  Both opcode tables were byte-for-byte identical across all 256
# slots, so the fork bought nothing but a second place for bugs to hide.
# The shared core is now a strict superset and is the only 6502 in the
# repo; what remains in this file is the Apple Panic specific material
# (the WOZ reader and the GCR sector decoders).
#
# Note for whoever runs the planned extraction of the CPU cores into their
# own package: this is the single import that has to move.

try:
    from nibbler.cpu import (CPU6502, MODE_SIZE,
                             IMP, ACC, IMM, ZP, ZPX, ZPY,
                             ABS, ABX, ABY, IND, IZX, IZY, REL)
except ImportError:  # pragma: no cover - convenience for direct execution
    # Running this script directly (rather than via `source
    # shared/toolchain/env.sh`, `pip install -e .`, or pytest's conftest)
    # leaves the repo's shared/ tree off sys.path.  Add it and retry.
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "shared"))
    from nibbler.cpu import (CPU6502, MODE_SIZE,
                             IMP, ACC, IMM, ZP, ZPX, ZPY,
                             ABS, ABX, ABY, IND, IZX, IZY, REL)


# ── Main: Boot and trace ─────────────────────────────────────────────

def decode_boot_sector_from_woz(woz_path):
    """Decode Track 0, Sector 0 from the WOZ image using 6-and-2."""
    with open(woz_path, 'rb') as f:
        data = f.read()
    tmap = data[88:88 + 160]
    tidx = tmap[0]

    offset_entry = 256 + tidx * 8
    sb = struct.unpack_from('<H', data, offset_entry)[0]
    bc = struct.unpack_from('<H', data, offset_entry + 2)[0]
    bits = struct.unpack_from('<I', data, offset_entry + 4)[0]
    track_data = data[sb * 512:sb * 512 + bc * 512]

    # Convert to nibbles
    bit_list = []
    for b in track_data:
        for i in range(7, -1, -1):
            bit_list.append((b >> i) & 1)
            if len(bit_list) >= bits:
                break
        if len(bit_list) >= bits:
            break
    nibbles = []
    current = 0
    for b in bit_list:
        current = ((current << 1) | b) & 0xFF
        if current & 0x80:
            nibbles.append(current)
            current = 0

    # Find first D5 AA 96 address field with sector 0, then its data field
    # For simplicity, find ALL D5 AA AD data prologues and decode sector 0
    nib2 = nibbles + nibbles[:500]

    # Find address prologues and match to data fields
    sectors = {}
    i = 0
    while i < len(nibbles):
        if nib2[i] == 0xD5 and nib2[i + 1] == 0xAA and nib2[i + 2] == 0x96:
            idx = i + 3
            vol = ((nib2[idx] << 1) | 1) & nib2[idx + 1]
            trk = ((nib2[idx + 2] << 1) | 1) & nib2[idx + 3]
            sec = ((nib2[idx + 4] << 1) | 1) & nib2[idx + 5]

            # Find following D5 AA AD
            j = idx + 8
            while j < len(nib2) - 346:
                if nib2[j] == 0xD5 and nib2[j + 1] == 0xAA and nib2[j + 2] == 0xAD:
                    # Decode 6-and-2
                    didx = j + 3
                    encoded = []
                    valid = True
                    for k in range(342):
                        n = nib2[didx + k]
                        if n not in DECODE_62:
                            valid = False
                            break
                        encoded.append(DECODE_62[n])
                    if valid:
                        cksum_nib = nib2[didx + 342]
                        cksum_val = DECODE_62.get(cksum_nib, -1)
                        # === ROM-exact decode ===
                        # Phase 1: XOR chain for aux (86 bytes), stored reversed
                        aux_buf = [0] * 86
                        xor_acc = 0
                        for k in range(86):
                            xor_acc ^= encoded[k]
                            aux_buf[85 - k] = xor_acc
                        # Phase 2: XOR chain for primary (256 bytes), continuous
                        pri_buf = [0] * 256
                        for k in range(256):
                            xor_acc ^= encoded[86 + k]
                            pri_buf[k] = xor_acc
                        # Phase 3: Post-decode with destructive LSR/ROL
                        result = bytearray(256)
                        x = 0x56  # aux index (starts at 86)
                        for y in range(256):
                            x -= 1
                            if x < 0:
                                x = 0x55  # reset to 85
                            a = pri_buf[y]
                            # First LSR/ROL: extract bit 0 of aux
                            carry = aux_buf[x] & 1
                            aux_buf[x] >>= 1
                            a = ((a << 1) | carry) & 0xFF
                            # Second LSR/ROL: extract next bit
                            carry2 = aux_buf[x] & 1
                            aux_buf[x] >>= 1
                            a = ((a << 1) | carry2) & 0xFF
                            result[y] = a
                        sectors[sec] = bytes(result)
                    break
                j += 1
            i = j + 343 if j < len(nib2) - 346 else i + 1
        else:
            i += 1

    return sectors


def decode_53_sector(nibbles, idx):
    """Decode one 5-and-3 encoded sector using the correct P5A ROM algorithm.
    nibbles: list of nibbles, idx: start of 411 data nibbles.
    Returns (sector_bytes, checksum_ok) or None.
    """
    ENCODE_53 = [
        0xAB, 0xAD, 0xAE, 0xAF, 0xB5, 0xB6, 0xB7, 0xBA,
        0xBB, 0xBD, 0xBE, 0xBF, 0xD6, 0xD7, 0xDA, 0xDB,
        0xDD, 0xDE, 0xDF, 0xEA, 0xEB, 0xED, 0xEE, 0xEF,
        0xF5, 0xF6, 0xF7, 0xFA, 0xFB, 0xFD, 0xFE, 0xFF,
    ]
    DEC53 = {v: i for i, v in enumerate(ENCODE_53)}
    GRP = 51

    translated = []
    for i in range(411):
        nib = nibbles[idx + i]
        if nib not in DEC53:
            return None
        translated.append(DEC53[nib])

    decoded = [0] * 410
    prev = 0
    for i in range(410):
        decoded[i] = translated[i] ^ prev
        prev = decoded[i]

    cksum_ok = (prev == translated[410])

    # decoded[0..153] = secondary (thr), stored reversed on disk
    # decoded[154..409] = primary (top)
    thr = [decoded[153 - j] for j in range(154)]
    top = [decoded[154 + j] for j in range(256)]

    # Reconstruct 256 bytes
    output = bytearray()
    for i in range(GRP - 1, -1, -1):
        s0 = thr[0 * GRP + i] if (0 * GRP + i) < 154 else 0
        s1 = thr[1 * GRP + i] if (1 * GRP + i) < 154 else 0
        s2 = thr[2 * GRP + i] if (2 * GRP + i) < 154 else 0

        output.append(((top[0 * GRP + i] << 3) | ((s0 >> 2) & 7)) & 0xFF)
        output.append(((top[1 * GRP + i] << 3) | ((s1 >> 2) & 7)) & 0xFF)
        output.append(((top[2 * GRP + i] << 3) | ((s2 >> 2) & 7)) & 0xFF)

        d_low = ((s0 & 2) << 1) | (s1 & 2) | ((s2 & 2) >> 1)
        output.append(((top[3 * GRP + i] << 3) | (d_low & 7)) & 0xFF)

        e_low = ((s0 & 1) << 2) | ((s1 & 1) << 1) | (s2 & 1)
        output.append(((top[4 * GRP + i] << 3) | (e_low & 7)) & 0xFF)

    final_top = top[5 * GRP] if 5 * GRP < 256 else 0
    final_thr = thr[3 * GRP] if 3 * GRP < 154 else 0
    output.append(((final_top << 3) | (final_thr & 7)) & 0xFF)

    return bytes(output[:256]), cksum_ok


def decode_44(b1, b2):
    """Decode a 4-and-4 encoded byte pair from the address field."""
    return ((b1 << 1) | 0x01) & b2


def decode_track_53(woz_path, track_num):
    """Decode all 5-and-3 sectors from a track. Returns dict sector_num -> bytes."""
    with open(woz_path, 'rb') as f:
        data = f.read()
    tmap = data[88:88 + 160]
    tidx = tmap[track_num * 4]
    if tidx == 0xFF:
        return {}

    offset = 256 + tidx * 8
    sb = struct.unpack_from('<H', data, offset)[0]
    bc = struct.unpack_from('<H', data, offset + 2)[0]
    bits_count = struct.unpack_from('<I', data, offset + 4)[0]
    track_data = data[sb * 512:sb * 512 + bc * 512]

    bit_list = []
    for b in track_data:
        for i in range(7, -1, -1):
            bit_list.append((b >> i) & 1)
            if len(bit_list) >= bits_count:
                break
        if len(bit_list) >= bits_count:
            break

    nibbles = []
    current = 0
    for b in bit_list:
        current = ((current << 1) | b) & 0xFF
        if current & 0x80:
            nibbles.append(current)
            current = 0

    nib2 = nibbles + nibbles[:2000]

    ENCODE_53 = [
        0xAB, 0xAD, 0xAE, 0xAF, 0xB5, 0xB6, 0xB7, 0xBA,
        0xBB, 0xBD, 0xBE, 0xBF, 0xD6, 0xD7, 0xDA, 0xDB,
        0xDD, 0xDE, 0xDF, 0xEA, 0xEB, 0xED, 0xEE, 0xEF,
        0xF5, 0xF6, 0xF7, 0xFA, 0xFB, 0xFD, 0xFE, 0xFF,
    ]
    DEC53 = set(ENCODE_53)

    sectors = {}
    for i in range(len(nibbles)):
        if nib2[i] != 0xD5 or nib2[i + 2] != 0xB5:
            continue
        idx = i + 3
        if idx + 8 >= len(nib2):
            continue
        sec = decode_44(nib2[idx + 4], nib2[idx + 5])
        if sec in sectors:
            continue
        for j in range(idx + 8, idx + 80):
            if j + 2 >= len(nib2):
                break
            if nib2[j] == 0xD5 and nib2[j + 1] == 0xAA and nib2[j + 2] == 0xAD:
                didx = j + 3
                valid = sum(1 for k in range(411) if didx + k < len(nib2)
                            and nib2[didx + k] in DEC53)
                if valid >= 410:
                    result = decode_53_sector(nib2, didx)
                    if result:
                        sector_data, ck_ok = result
                        sectors[sec] = sector_data
                break

    return sectors


def build_gcr_table(mem):
    """Build the GCR decode table at $0356+ exactly as the boot ROM does.
    This maps nibble values ($80-$FF range) to 6-bit decoded values (0-63).
    Accessed via EOR $02D6,Y where Y = raw nibble."""
    y = 0  # decoded value counter
    for x in range(3, 128):
        # Validate nibble pattern (no consecutive zero bits)
        a = (x << 1) & 0xFF
        if (a & x) == 0:
            continue
        a = a | x
        a = (~a) & 0xFF
        a = a & 0x7E
        # Check carry (from ASL) - skip if set
        if (x << 1) & 0x100:
            continue
        # Check for consecutive zeros
        valid = True
        while a != 0:
            if (x << 1) & 0x100:
                valid = False
                break
            a = (a >> 1) & 0xFF
        if valid:
            mem[0x0356 + x] = y
            y += 1


def main():
    REPO_ROOT = Path(__file__).resolve().parent.parent
    APPLE_PANIC = REPO_ROOT / "apple-panic"
    OUTPUT_DIR = APPLE_PANIC / "output"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    woz_path = str(APPLE_PANIC / "Apple Panic - Disk 1, Side A.woz")

    print("=" * 70)
    print("APPLE PANIC BOOT TRACE EMULATOR")
    print("=" * 70)

    # Load WOZ disk for nibble streaming
    print("Loading WOZ disk image...")
    disk = WOZDisk(woz_path)

    # Decode boot sector using ROM-exact algorithm
    print("Decoding D5 AA 96 sector 0 (ROM-exact 6-and-2)...")
    sectors_62 = decode_boot_sector_from_woz(woz_path)
    if 0 not in sectors_62:
        print("ERROR: No D5 AA 96 sector 0 found!")
        return
    boot = sectors_62[0]
    print(f"  Byte 0 (sector count): ${boot[0]:02X}")
    print(f"  First 16: " + ' '.join(f'{b:02X}' for b in boot[:16]))

    # Create CPU
    cpu = CPU6502()
    cpu.disk = disk

    # Load boot sector at $0800
    for i, b in enumerate(boot):
        cpu.mem[0x0800 + i] = b

    # Build GCR decode table at $0356 (as boot ROM does before loading sector)
    build_gcr_table(cpu.mem)

    # Set up Apple II+ Monitor ROM stubs
    # $FF58 = IORTS (just RTS) - used by boot ROM for slot detection
    cpu.mem[0xFF58] = 0x60  # RTS

    # $FCA8 = WAIT routine (delay loop, we make it instant)
    # Real: SEC / PHA / SBC #1 / BNE / PLA / SBC #1 / BNE / RTS
    # For emulation, just RTS (delays don't matter)
    cpu.mem[0xFCA8] = 0x60  # RTS

    # IRQ/BRK handler at $FA40 (simplified)
    brk_handler = bytes([
        0xD8,             # CLD
        0x85, 0x45,       # STA $45
        0x68,             # PLA
        0x48,             # PHA
        0x29, 0x10,       # AND #$10
        0xD0, 0x03,       # BNE +3 (→ BRK path)
        0x6C, 0xFE, 0x03, # JMP ($03FE) - IRQ vector
        0xA5, 0x45,       # LDA $45
        0x6C, 0xF0, 0x03, # JMP ($03F0) - BRK vector
    ])
    for i, b in enumerate(brk_handler):
        cpu.mem[0xFA40 + i] = b
    cpu.mem[0xFFFE] = 0x40
    cpu.mem[0xFFFF] = 0xFA  # IRQ/BRK → $FA40

    # BRK software vector ($03F0) - initially halt trap
    # Put a KIL instruction at $FF10 to catch unexpected BRKs
    cpu.mem[0xFF10] = 0x02  # KIL
    cpu.mem[0x03F0] = 0x10
    cpu.mem[0x03F1] = 0xFF  # BRK → $FF10 (halt)

    # Initial state after P6 boot ROM completes:
    # - JMP $0801
    # - X = slot * 16 = $60
    # - Motor on, head on track 0
    # - Stack used minimally (JSR $FF58 leaves return addr)
    cpu.pc = 0x0801
    cpu.x = 0x60  # slot 6
    cpu.sp = 0xFD  # boot ROM uses some stack for JSR
    cpu.a = 0x00
    cpu.y = 0x00
    # $2B = slot * 16 (set by boot ROM)
    cpu.mem[0x2B] = 0x60

    # Motor on, head on track 0
    disk.motor_on = True
    disk.current_qtrack = 0

    # Enable trace to file
    trace_path = str(OUTPUT_DIR / "boot_trace.log")
    cpu.trace = True
    cpu.trace_file = open(trace_path, 'w')

    print(f"\nStarting execution at $0801 (X=$60)...")
    print(f"Trace log: {trace_path}")

    max_instructions = 5_000_000
    mem_before = bytearray(cpu.mem)

    for i in range(max_instructions):
        if not cpu.step():
            print(f"\n  CPU halted at ${cpu.pc:04X} after {cpu.exec_count} instructions")
            break

        pc = cpu.pc

        # Milestone breakpoints
        if pc == 0x020F and cpu.exec_count < 1000:
            print(f"  >> JMP $020F reached (boot code relocated to $0200)")
        if pc == 0x7465:
            print(f"\n  *** GAME ENTRY POINT $7465 reached at instr {cpu.exec_count}!")
            break

        if cpu.exec_count % 500000 == 0:
            print(f"  ... {cpu.exec_count} instructions, PC=${pc:04X} "
                  f"A={cpu.a:02X} X={cpu.x:02X} Y={cpu.y:02X}")

        # Detect infinite BRK loop
        if cpu.brk_count > 10:
            print(f"\n  Too many BRKs ({cpu.brk_count}), stopping")
            print(f"  Last PC=${pc:04X}, state: {cpu.format_state()}")
            break

    cpu.trace_file.close()

    # Summary
    print(f"\n{'=' * 70}")
    print("EXECUTION SUMMARY")
    print(f"{'=' * 70}")
    print(f"Total instructions: {cpu.exec_count}")
    print(f"Final PC: ${cpu.pc:04X}")
    print(f"Final state: {cpu.format_state()}")

    # Memory modifications
    print(f"\nMemory regions modified:")
    modified_ranges = []
    start = None
    for addr in range(65536):
        if cpu.mem[addr] != mem_before[addr]:
            if start is None:
                start = addr
        else:
            if start is not None:
                modified_ranges.append((start, addr - 1))
                start = None
    if start is not None:
        modified_ranges.append((start, 65535))
    for s, e in modified_ranges:
        print(f"  ${s:04X}-${e:04X} ({e - s + 1} bytes)")

    # Show zero page state
    print(f"\nZero page (modified bytes):")
    for addr in range(256):
        if cpu.mem[addr] != mem_before[addr]:
            print(f"  ${addr:02X} = ${cpu.mem[addr]:02X}")

    # Show page 3 vectors
    print(f"\nPage 3 vectors:")
    print(f"  $03F0/$03F1 (BRK): ${cpu.mem[0x03F1]:02X}{cpu.mem[0x03F0]:02X}")

    # Show first 100 trace lines
    print(f"\nFirst 100 trace lines:")
    with open(trace_path) as f:
        for i, line in enumerate(f):
            if i >= 100:
                print(f"  ... ({cpu.exec_count - 100} more lines)")
                break
            print(f"  {line.rstrip()}")

    # Save memory dump
    mem_dump_path = str(OUTPUT_DIR / "emu_memory_dump.bin")
    with open(mem_dump_path, 'wb') as f:
        f.write(cpu.mem)
    print(f"\nMemory dump saved: {mem_dump_path}")


if __name__ == '__main__':
    main()
