#!/usr/bin/env bash
#
# Rebuild a decompiled distribution's disk image byte-identically from source,
# and verify that every source file in it reassembles to the original bytes.
#
#     bash softcard/decompiled/rebuild.sh CPMV223-44K     # 2.23 -> CPMV223-44K.DSK
#     bash softcard/decompiled/rebuild.sh CPMV220      # 2.20 -> CPMV220-Disk1.po
#
# Requires the local toolchain (ca65 + ld65 + sjasmplus); this script sources
# shared/toolchain/env.sh to put them on PATH (install per
# shared/toolchain/README.md if missing).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/shared/toolchain/env.sh"

DISTRO="${1:-}"
case "$DISTRO" in
  CPMV223-44K) VARIANT=223; DISK="$ROOT/softcard/CPMV223-44K/CPMV223-44K.DSK" ;;
  CPMV220)  VARIANT=220; DISK="$ROOT/softcard/CPMV220/CPMV220-Disk1.po" ;;
  *) echo "usage: rebuild.sh {CPMV223-44K|CPMV220}" >&2; exit 2 ;;
esac

EXT="${DISK##*.}"
OUT_DIR="$HERE/$DISTRO/rebuilt"
OUT="$OUT_DIR/${DISTRO}.${EXT}"
mkdir -p "$OUT_DIR"

echo "=================================================================="
echo " $DISTRO — 1. Reassemble the CP/M OS and rebuild the disk image"
echo "=================================================================="
python -m cpm_pipeline build "$VARIANT" --reference "$DISK" --output "$OUT" --verify

echo
echo "=================================================================="
echo " $DISTRO — 2. Verify every source file round-trips"
echo "=================================================================="
python "$HERE/verify_roundtrip.py" "$DISTRO"

echo
echo "Done."
echo "  Byte-identical disk image: $OUT"
