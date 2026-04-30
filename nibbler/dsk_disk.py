"""
DSK-backed Disk II model with synthetic GCR nibble streams.

Exposes the same interface as WOZDisk (read_nibble, step_phase, motor_on,
current_qtrack, etc.) but synthesizes the nibble stream from a sector-order
.dsk or .po image.

Used by the SoftCard-CP/M boot emulator: the CP/M disk images are stored
as 16-sector DOS 3.3 / ProDOS sector-order images, not WOZ flux captures,
so synthetic GCR is sufficient -- the boot stub uses standard prologs,
4-and-4 address fields, and 6-and-2 data fields.
"""

from .gcr import ENCODE_62, DOS33_INTERLEAVE, PRODOS_INTERLEAVE


def _encode_44(b):
    """4-and-4 encode one byte into two disk nibbles (high, low)."""
    return (((b >> 1) & 0x55) | 0xAA, (b & 0x55) | 0xAA)


def _build_aux_buffer(data):
    """
    Build the 86-byte auxiliary buffer that, when consumed by the standard
    Apple ROM merge algorithm, reconstructs the bottom 2 bits of each
    256-byte source byte.

    The merge walks y=0..255, mapping each y to an aux index x via the
    pattern x = 85 - (y mod 86) (with x=85 acting as the "reset" value).
    For each y, two LSR/ROL pairs consume aux[x]'s bottom 2 bits and
    append them to the bottom of the reconstructed byte. So aux[x] holds
    six bits, two each from the three y values that map to the same x.

    The bit-order: the FIRST y that maps to x consumes aux[x]'s bit 0
    (which becomes the destination byte's bit 1) and bit 1 (becomes
    destination's bit 0). The second y consumes the next two bits. Etc.
    """
    aux = [0] * 86
    counts = [0] * 86  # how many bits we've packed into each aux[x] so far
    # Walk in the same order as the decoder.
    x = 0x56
    for y in range(256):
        x -= 1
        if x < 0:
            x = 0x55
        # The two aux bits for data[y]:
        #   first consumed (= dest bit 1) = data[y] bit 1
        #   second consumed (= dest bit 0) = data[y] bit 0
        # In aux[x], they pack at the bottom of the *currently empty*
        # portion: so they go at positions counts[x] (bit 0) and
        # counts[x]+1 (bit 1).
        b0 = (data[y] >> 1) & 1   # first consumed
        b1 = data[y] & 1          # second consumed
        aux[x] |= b0 << counts[x]
        aux[x] |= b1 << (counts[x] + 1)
        counts[x] += 2
    return aux


def _encode_sector_62(data, volume, track, sector):
    """
    Build the on-disk nibble bytes for one physical sector.

    Layout:
      sync gap (40 self-sync $FF bytes)
      address prolog          $D5 $AA $96
      4-and-4 volume / track / sector / checksum
      address epilog          $DE $AA $EB
      sync gap (10 sync bytes)
      data prolog             $D5 $AA $AD
      342 GCR-encoded nibbles + 1 checksum nibble
      data epilog             $DE $AA $EB
      tail gap
    """
    out = []
    out.extend([0xFF] * 40)

    out.extend([0xD5, 0xAA, 0x96])
    out.extend(_encode_44(volume))
    out.extend(_encode_44(track))
    out.extend(_encode_44(sector))
    out.extend(_encode_44(volume ^ track ^ sector))
    out.extend([0xDE, 0xAA, 0xEB])

    out.extend([0xFF] * 10)
    out.extend([0xD5, 0xAA, 0xAD])

    # Build the 86-byte aux buffer + 256-byte primary buffer.
    pri = [data[y] >> 2 for y in range(256)]
    aux = _build_aux_buffer(data)

    # The decoder reverses the aux storage order: aux_buf[85 - k] = ...
    # so on the wire the aux bytes appear in reversed order.
    # Decode does aux_buf[85 - k] = xor_acc, where k=0..85 and xor_acc is
    # the running XOR. So the on-wire 6-bit values for aux are:
    #   wire[0] = aux[85] (XOR'd with seed 0)
    #   wire[1] = aux[85] ^ aux[84]
    #   wire[2] = aux[84] ^ aux[83]
    #   ...
    # i.e. wire_aux[k] = aux_reversed[k] ^ aux_reversed[k-1]
    aux_reversed = list(reversed(aux))
    encoded = []
    last = 0
    for v in aux_reversed:
        encoded.append(v ^ last)
        last = v
    # Now primary, in normal order.
    for v in pri:
        encoded.append(v ^ last)
        last = v

    # Checksum nibble: the final running XOR.
    out.extend(ENCODE_62[v & 0x3F] for v in encoded)
    out.append(ENCODE_62[last & 0x3F])

    out.extend([0xDE, 0xAA, 0xEB])
    out.extend([0xFF] * 5)
    return out


def build_track_nibbles(track_data, track_num, volume=254, interleave=None):
    """
    Build a full track nibble stream from 16 sectors of logical data.

    Args:
        track_data: 4096 bytes -- 16 sectors * 256 bytes, in *logical* order.
        track_num:  Track number (0-34).
        volume:     Volume number (default 254).
        interleave: Logical-to-physical sector mapping. Default DOS 3.3.

    Returns:
        list of nibble bytes for the synthetic track stream.
    """
    if interleave is None:
        interleave = DOS33_INTERLEAVE
    nibbles = []
    for phys in range(16):
        logical = interleave[phys]
        sector_bytes = track_data[logical * 256:(logical + 1) * 256]
        nibbles.extend(_encode_sector_62(sector_bytes, volume, track_num, phys))
    return nibbles


class DSKDisk:
    """
    Disk II model backed by a sector-order .dsk / .po image.

    Mirrors the WOZDisk interface used by CPU6502.

    Attributes:
        nibble_tracks: dict of qtrack -> [nibbles]
        current_qtrack: head position (qtrack = track*4)
        nibble_pos: bit position within current track
        motor_on, q6, q7: hardware state mirrors
    """

    def __init__(self, dsk_path_or_bytes, *, interleave='dos33', volume=254,
                 num_tracks=35):
        if isinstance(dsk_path_or_bytes, (bytes, bytearray)):
            data = bytes(dsk_path_or_bytes)
        else:
            with open(dsk_path_or_bytes, 'rb') as f:
                data = f.read()

        if interleave == 'dos33':
            il = DOS33_INTERLEAVE
        elif interleave == 'prodos':
            il = PRODOS_INTERLEAVE
        else:
            il = interleave

        self.nibble_tracks = {}
        for trk in range(num_tracks):
            track_bytes = data[trk * 4096:(trk + 1) * 4096]
            if len(track_bytes) < 4096:
                # Short final track: pad with zeros.
                track_bytes = track_bytes + bytes(4096 - len(track_bytes))
            nibs = build_track_nibbles(track_bytes, trk, volume=volume,
                                       interleave=il)
            # Bit-doubled stream so wrap-around reads still find prologs.
            doubled = nibs + nibs
            self.nibble_tracks[trk * 4] = doubled

        self.current_qtrack = 0
        self.nibble_pos = 0
        self.motor_on = True
        self.phases = [False] * 4
        self.data_latch = 0
        self.q6 = False
        self.q7 = False
        self.trace_callback = None
        self._recent_nibbles = []

    def read_nibble(self):
        if not self.motor_on:
            return 0x00
        track = self.nibble_tracks.get(self.current_qtrack)
        if not track:
            return 0xFF
        nib = track[self.nibble_pos % len(track)]
        self.nibble_pos = (self.nibble_pos + 1) % len(track)

        if self.trace_callback:
            self._recent_nibbles.append(nib)
            if len(self._recent_nibbles) > 3:
                self._recent_nibbles.pop(0)
            if len(self._recent_nibbles) == 3:
                b0, b1, b2 = self._recent_nibbles
                if b0 == 0xD5 and b1 == 0xAA and b2 == 0x96:
                    self.trace_callback(
                        f"ADDR PROLOG D5 AA 96 at nibble "
                        f"{self.nibble_pos - 3} on track {self.current_qtrack // 4}")
                elif b0 == 0xD5 and b1 == 0xAA and b2 == 0xAD:
                    self.trace_callback(
                        f"DATA PROLOG D5 AA AD at nibble "
                        f"{self.nibble_pos - 3} on track {self.current_qtrack // 4}")
        return nib

    def step_phase(self, phase, on):
        """Mirror WOZDisk.step_phase for stepper-motor head movement."""
        self.phases[phase] = on
        if not on:
            return
        old = self.current_qtrack
        current_phase = (self.current_qtrack // 2) % 4
        diff = (phase - current_phase + 4) % 4
        if diff == 1:
            self.current_qtrack = min(self.current_qtrack + 2, 159)
        elif diff == 3:
            self.current_qtrack = max(self.current_qtrack - 2, 0)
        if self.current_qtrack != old:
            self.nibble_pos = 0
            self._recent_nibbles.clear()
            if self.trace_callback:
                self.trace_callback(
                    f"SEEK track {old // 4} -> {self.current_qtrack // 4}")
