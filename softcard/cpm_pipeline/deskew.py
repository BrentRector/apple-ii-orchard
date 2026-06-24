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


# ---- BIOS: the as-loaded 6-page BIOS the CPU runs at z80 $AA00-$AFFF (the prior
# 5-page on-disk-order CPM_BIOS.asm was skewed + missing the 6th page). Emulator-derived.
BIOS_ORG = 0xAA00
BIOS_LEN = 6 * PAGE
BIOS_PAGE_TO_SECTOR = {0xAA00: 46, 0xAB00: 45, 0xAC00: 44, 0xAD00: 43, 0xAE00: 42, 0xAF00: 41}


def build_bios_image(dsk: bytes) -> bytes:
    out = bytearray(BIOS_LEN)
    for page, sector in BIOS_PAGE_TO_SECTOR.items():
        o = page - BIOS_ORG
        out[o:o + PAGE] = dsk[sector * PAGE: sector * PAGE + PAGE]
    return bytes(out)


def reference_bios_image() -> bytes:
    from cpm_pipeline.reference_data import DISK_2_20_44K_SYSTEM
    return build_bios_image(DISK_2_20_44K_SYSTEM.read_bytes())


# ===========================================================================
# 2.23-44K: the same de-skew, derived from the 2.23-44K loader. 2.23 STAGES the system
# at Apple $8000-$9CFF (already de-interleaved) and then RELOCATES it; the maps below are
# the composed runtime-page -> .dsk-sector relation (verified by matching the emulator's
# post-boot runtime memory to the disk sectors). 2.23 differs from 2.20: the CCP+BDOS run
# at z80 $9300-$A9FF (CCP entry $9300, one page LOWER than 2.20's $9400) and the BIOS runs
# at z80 $FA00-$FFFF (= Apple $0A00 LOW RAM, NOT $AA00 -- a different mechanism).
RUNTIME_ORG_223 = 0x9300
RUNTIME_LEN_223 = 23 * PAGE
PAGE_TO_SECTOR_223 = {
    0x9300: 4,  0x9400: 3,  0x9500: 2,  0x9600: 1,  0x9700: 15, 0x9800: 16,
    0x9900: 30, 0x9A00: 29, 0x9B00: 28, 0x9C00: 27, 0x9D00: 26, 0x9E00: 25,
    0x9F00: 24, 0xA000: 23, 0xA100: 22, 0xA200: 21, 0xA300: 20, 0xA400: 19,
    0xA500: 18, 0xA600: 17, 0xA700: 31, 0xA800: 32, 0xA900: 46,
}
BIOS_ORG_223 = 0xFA00
BIOS_LEN_223 = 6 * PAGE
BIOS_PAGE_TO_SECTOR_223 = {0xFA00: 45, 0xFB00: 44, 0xFC00: 43, 0xFD00: 42, 0xFE00: 41, 0xFF00: 40}


def _gather(dsk, page_to_sector, org, length):
    out = bytearray(length)
    for page, sector in page_to_sector.items():
        out[page - org:page - org + PAGE] = dsk[sector * PAGE: sector * PAGE + PAGE]
    return bytes(out)


def _scatter(image, page_to_sector, org, dsk):
    for page, sector in page_to_sector.items():
        dsk[sector * PAGE: sector * PAGE + PAGE] = image[page - org:page - org + PAGE]
    return dsk


def build_runtime_image_223(dsk): return _gather(dsk, PAGE_TO_SECTOR_223, RUNTIME_ORG_223, RUNTIME_LEN_223)
def build_bios_image_223(dsk): return _gather(dsk, BIOS_PAGE_TO_SECTOR_223, BIOS_ORG_223, BIOS_LEN_223)


def reference_runtime_image_223():
    from cpm_pipeline.reference_data import DISK_2_23_44K_SYSTEM
    return build_runtime_image_223(DISK_2_23_44K_SYSTEM.read_bytes())


def reference_bios_image_223():
    from cpm_pipeline.reference_data import DISK_2_23_44K_SYSTEM
    return build_bios_image_223(DISK_2_23_44K_SYSTEM.read_bytes())


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
