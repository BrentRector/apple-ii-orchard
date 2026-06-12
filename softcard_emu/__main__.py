"""CLI: python -m softcard_emu <disk> [options]"""

import argparse

from .machine import SoftCardMachine


def main():
    ap = argparse.ArgumentParser(
        prog="softcard_emu",
        description="Boot a Microsoft SoftCard CP/M disk image "
                    "(6502 + Z-80 + SoftCard + Disk II + Videx + "
                    "language card).")
    ap.add_argument('disk', help='.dsk (DOS 3.3 order) or .po image')
    ap.add_argument('--keys', default='',
                    help=r'keystrokes to type after boot (\r = Return)')
    ap.add_argument('--steps', type=int, default=80_000_000,
                    help='instruction budget across both CPUs')
    ap.add_argument('--no-videx', action='store_true',
                    help='no Videoterm; console output on the 40-col page')
    ap.add_argument('--no-langcard', action='store_true',
                    help='no language card (flat 48K-style memory)')
    ap.add_argument('--flat-c800', action='store_true',
                    help='always-mapped expansion-ROM window '
                         '(no ownership arbitration)')
    ap.add_argument('--real-rwts', action='store_true',
                    help='no sector hook; run the preserved RWTS against '
                         'synthetic nibble streams')
    ap.add_argument('--videx-rom', default=None,
                    help='path to the 1 KB Videoterm firmware image')
    args = ap.parse_args()

    m = SoftCardMachine(args.disk,
                        videx=not args.no_videx,
                        language_card=not args.no_langcard,
                        sector_hook=not args.real_rwts,
                        c8_arbitrate=not args.flat_c800,
                        videx_rom=args.videx_rom)
    if args.keys:
        m.type_keys(args.keys.replace('\\r', '\r'))
    res = m.run(total_steps=args.steps)

    print(f"result: {res}")
    print(f"CPU switches: {m.switches:,}   "
          f"6502: {m.m6502.exec_count:,} insns   "
          f"Z-80: {m.z.exec_count:,} insns")
    if m.videx and m.videx.arbitrate:
        print(f"C8 window faults: {m.videx.fault_count:,}")
    print(f"disk: {len(m.disk_reads)} sector reads, "
          f"{len(m.disk_writes)} writes via the sector hook")
    print()
    for line in m.screen_text():
        print(f"  |{line}")


if __name__ == '__main__':
    main()
