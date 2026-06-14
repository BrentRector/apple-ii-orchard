"""Apple keyboard subsystem.

Models the Apple II keyboard as the bus sees it: a queue of pending
keystrokes, the data latch at $C000 (bit 7 = "key available" strobe),
and the strobe-clear at $C010. Holds two side-specific poll counters --
the machine's run() idle heuristics watch them to tell when the system
is sitting in a keyboard-wait loop (a healthy interactive state) on the
6502 side versus the Z-80 side.

Pure state; address decode lives in the bus, which routes $C000 here to
``read_data(side)`` and $C010 to ``clear_strobe()``.
"""


class Keyboard:
    def __init__(self):
        self.queue = []           # pending keystrokes (ASCII ints)
        self.current = 0x00       # data latch; bit 7 set => key available
        self.polls_z80 = 0        # Z-80-side $C000 reads
        self.polls_6502 = 0       # 6502-side $C000 reads

    def type_keys(self, text):
        """Queue keystrokes (use '\\r' for Return)."""
        for ch in text:
            self.queue.append(ord(ch))

    def read_data(self, side):
        """$C000 read from ``side`` ('6502' or 'z80').

        Counts the poll, latches the next queued key (with the strobe
        bit) when none is pending, and returns the latch.
        """
        if side == '6502':
            self.polls_6502 += 1
        else:
            self.polls_z80 += 1
        if self.queue and not (self.current & 0x80):
            self.current = self.queue.pop(0) | 0x80
        return self.current

    def clear_strobe(self):
        """$C010 read: clear the strobe bit; returns 0x00."""
        self.current &= 0x7F
        return 0x00
