#!/usr/bin/env bash
#
# Rebuild a decompiled distribution's disk image byte-identically from source,
# and verify that every source file in it reassembles to the original bytes.
#
#     bash softcard/decompiled/rebuild.sh CPMV233     # 2.23 -> CPMV233.DSK
#     bash softcard/decompiled/rebuild.sh CPM220      # 2.20 -> CPM220Disk1.po
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
  CPMV233) VARIANT=223; DISK="$ROOT/softcard/disks/CPMV233.DSK" ;;
  CPM220)  VARIANT=220; DISK="$ROOT/softcard/disks/CPM220Disk1.po" ;;
  *) echo "usage: rebuild.sh {CPMV233|CPM220}" >&2; exit 2 ;;
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
