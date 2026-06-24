"""CP/M 2.20-44K system-track sector de-interleave (the "de-skew").

The CCP/BDOS sit on the system tracks **sector-interleaved**. The cold loader reads
*logical* sectors (RWTS skew) into *contiguous* RAM, so the bytes EXECUTE in a different
order than they sit on disk. The OS sources must therefore be decoded against the
**de-skewed runtime image** (every label a true runtime address); this module maps
between the two so the source can be both decoded at runtime addresses and rebuilt to a
byte-identical disk. See ``softcard/docs/CPM_Skew_Findings.md`` and
``feedback_decode_deskewed_runtime_not_ondisk``.

The mapping below was read straight from the emulator's loader (``SoftCardMachine.run`` ->
``disk_reads``): each runtime page records the .dsk linear sector (``track*16 + file_idx``)
the cold loader copied into it. It covers the WHOLE CCP+BDOS the CPU runs -- z80
$9400-$A9FF, 22 pages (the CCP runs at $9400, FBASE $9C00, var page $A9xx). Derived +
verified 2026-06-23 via ``E:/tmp/deskew_full_220_44k.bin`` (disassembles + reassembles
byte-identical). The embedded 6502 RPC payloads and the boot stub live on other sectors
and are not part of this Z-80 runtime image.
"""

RUNTIME_ORG = 0x9400          # base address of the de-skewed Z-80 runtime image
PAGE = 0x100
RUNTIME_LEN = 22 * PAGE

# runtime page address -> .dsk linear sector (track*16 + file sector) the loader read it from.
PAGE_TO_SECTOR = {
    0x9400: 4,  0x9500: 3,  0x9600: 2,  0x9700: 1,  0x9800: 15, 0x9900: 16,
    0x9A00: 30, 0x9B00: 29, 0x9C00: 28, 0x9D00: 27, 0x9E00: 26, 0x9F00: 25,
    0xA000: 24, 0xA100: 23, 0xA200: 22, 0xA300: 21, 0xA400: 20, 0xA500: 19,
    0xA600: 18, 0xA700: 17, 0xA800: 31, 0xA900: 32,
}


def build_runtime_image(dsk: bytes) -> bytes:
    """Gather the de-skewed runtime image ($9400, 22 pages) from a .dsk disk image:
    each runtime page = the .dsk sector the loader copied into it."""
    out = bytearray(RUNTIME_LEN)
    for page, sector in PAGE_TO_SECTOR.items():
        o = page - RUNTIME_ORG
        out[o:o + PAGE] = dsk[sector * PAGE: sector * PAGE + PAGE]
    return bytes(out)


def scatter_to_disk(runtime: bytes, dsk: bytearray) -> bytearray:
    """Re-skew: write each runtime page of ``runtime`` back to its .dsk sector in ``dsk``
    (mutates + returns ``dsk``). Reproduces the system-track CCP/BDOS sectors."""
    for page, sector in PAGE_TO_SECTOR.items():
        o = page - RUNTIME_ORG
        dsk[sector * PAGE: sector * PAGE + PAGE] = runtime[o:o + PAGE]
    return dsk


def reference_runtime_image() -> bytes:
    """The de-skewed runtime image gathered from the canonical 2.20-44K system .dsk."""
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM
    return build_runtime_image(DISK_2_20_44K_SYSTEM.read_bytes())


def _selftest():
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM
    dsk = bytearray(DISK_2_20_44K_SYSTEM.read_bytes())
    rt = build_runtime_image(dsk)
    assert len(rt) == RUNTIME_LEN
    # round-trip: scatter the gathered image back == the original sectors
    dsk2 = scatter_to_disk(rt, bytearray(dsk))
    for sector in PAGE_TO_SECTOR.values():
        assert dsk2[sector*PAGE:sector*PAGE+PAGE] == dsk[sector*PAGE:sector*PAGE+PAGE]
    assert len(set(PAGE_TO_SECTOR.values())) == 22, "sectors not distinct"
    return True


if __name__ == "__main__":
    print("de-skew round-trip ok:", _selftest())
