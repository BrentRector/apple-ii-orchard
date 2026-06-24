"""CP/M 2.20-44K system-track sector de-interleave (the "de-skew").

The CCP/BDOS sit on the system tracks **sector-interleaved**. The cold loader reads
*logical* sectors (RWTS skew table) into *contiguous* RAM, so the bytes EXECUTE in a
different order than they sit on disk. The OS sources must therefore be decoded against
the **de-skewed runtime image** (every label a true runtime address); this module maps
between the two so the disk producer can re-skew a runtime-order source back to a
byte-identical disk.  See ``softcard/docs/CPM_Skew_Findings.md`` and
``feedback_decode_deskewed_runtime_not_ondisk``.

The page permutation below was derived deterministically from the loader's own recorded
reads (``SoftCardMachine.disk_reads`` -> ``(track, sec_log, phys, dest)``), is bijective,
and round-trips byte-identical (``E:/tmp/deskew_exact.py``; verified 2026-06-23). The
20 system-code pages map to runtime $9600-$A9FF; the three remaining on-disk pages are
passthrough -- the two embedded 6502 RPC blocks ($9400, $9600) and the BDOS variable
page ($A900) -- which the loader does not place into the Z-80 runtime image and which the
source reproduces directly at their on-disk positions.
"""

ONDISK_ORG = 0x9300            # base address of the on-disk linear system image
RUNTIME_ORG = 0x9600          # base address of the de-skewed Z-80 runtime image
PAGE = 0x100

# runtime page address -> the on-disk page address whose bytes execute there.
RUNTIME_TO_ONDISK = {
    0x9600: 0x9300, 0x9700: 0x9500, 0x9800: 0x9700, 0x9900: 0x9800,
    0x9A00: 0x9A00, 0x9B00: 0x9C00, 0x9C00: 0x9E00, 0x9D00: 0xA000,
    0x9E00: 0xA200, 0x9F00: 0xA400, 0xA000: 0xA600, 0xA100: 0x9900,
    0xA200: 0x9B00, 0xA300: 0x9D00, 0xA400: 0x9F00, 0xA500: 0xA100,
    0xA600: 0xA300, 0xA700: 0xA500, 0xA800: 0xA700, 0xA900: 0xA800,
}
ONDISK_TO_RUNTIME = {v: k for k, v in RUNTIME_TO_ONDISK.items()}

# on-disk pages the loader does NOT de-interleave into the Z-80 runtime image
# (embedded 6502 RPC blocks + the $E5 variable page); reproduced in place.
ONDISK_PASSTHROUGH = (0x9400, 0x9600, 0xA900)


def ondisk_to_runtime(ondisk: bytes) -> bytes:
    """De-skew: on-disk linear image ($9300, 23 pages) -> runtime image ($9600, 20 pages)."""
    out = bytearray(20 * PAGE)
    for rt, od in RUNTIME_TO_ONDISK.items():
        o_od = od - ONDISK_ORG
        o_rt = rt - RUNTIME_ORG
        out[o_rt:o_rt + PAGE] = ondisk[o_od:o_od + PAGE]
    return bytes(out)


def runtime_to_ondisk(runtime: bytes, ondisk_template: bytes) -> bytes:
    """Re-skew: runtime image ($9600, 20 pages) + the three passthrough pages (taken from
    ``ondisk_template``) -> the byte-identical on-disk linear image ($9300, 23 pages)."""
    out = bytearray(ondisk_template)            # passthrough pages come from the template
    for rt, od in RUNTIME_TO_ONDISK.items():
        o_od = od - ONDISK_ORG
        o_rt = rt - RUNTIME_ORG
        out[o_od:o_od + PAGE] = runtime[o_rt:o_rt + PAGE]
    return bytes(out)


def _selftest():
    """Round-trip against the live on-disk image: de-skew then re-skew == original."""
    from cpm_pipeline.chunk_map import SOURCES_220_44K
    from cpm_pipeline.assemble import assemble_chunk
    ondisk = assemble_chunk(SOURCES_220_44K['CPM220_44K_System'])
    assert len(ondisk) == 23 * PAGE, len(ondisk)
    rt = ondisk_to_runtime(ondisk)
    back = runtime_to_ondisk(rt, ondisk)
    assert back == ondisk, "round-trip mismatch"
    # bijection sanity
    assert len(set(RUNTIME_TO_ONDISK.values())) == 20
    mapped = set(RUNTIME_TO_ONDISK.values()) | set(ONDISK_PASSTHROUGH)
    assert mapped == {ONDISK_ORG + i * PAGE for i in range(23)}, "pages not fully covered"
    return True


if __name__ == "__main__":
    print("de-skew round-trip byte-identical:", _selftest())
