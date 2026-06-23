; ============================================================================
;  CPM60.COM  --  Microsoft 60K-update installer  (11,264 bytes / $2C00)
;  Single-source master link.  Assembles byte-identically to the CPM60.COM
;  file on CPMV223-44K.DSK.
; ----------------------------------------------------------------------------
;  CPM60.COM is a Z-80 .COM (the installer at $0100) that carries an embedded
;  60K system image and writes it to a disk's system tracks. The image pieces
;  are stored at fixed offsets inside the .COM but RUN at different addresses --
;  the three OS modules run high, inside the language card. This master places
;  every piece at its .COM file offset while assembling the relocating Z-80
;  modules as real code at their RUN address via DISP ... ENT (so their labels
;  resolve correctly), exactly as GBASIC.COM's interpreter is handled.
;
;  Mixed CPU: the boot loader / RWTS / install fragments are 6502 (ca65), so
;  they cannot be Z-80 source -- they are INCBIN'd from their assembled binaries.
;  The Z-80 modules are INCLUDEd from their canonical sources; each is wrapped in
;  a MODULE (its EQUs/labels namespace, so the shared CP/M page-zero and BIOS
;  vectors never collide) and brackets its own DEVICE/ORG/SAVEBIN behind
;  IFNDEF CPM60_LINK, which this file defines.
;
;  file offset   run addr   piece                         source
;  -----------   --------   ---------------------------   ------------------------
;  $0000-$0260   $0100      installer driver              CPM60_installer.asm  (Z-80)
;  $0300-$03FF   $0800      boot loader (page 0 slice)    CPM_BootLoader.bin   (6502)
;  $0400-$09BC   --         RWTS driver                   CPM_RWTS.bin         (6502)
;  $0A00-$0BF1   $1000      boot loader (reloc page)      CPM_BootLoader.bin   (6502)
;  $0D80-$0DFF   $0380      install fragments slice       CPM_InstallFragments.bin (6502)
;  $0E00-$1705   $D300      CCP                           os/CPM_CCP.asm       (Z-80, DISP)
;  $1700-$24FF   $DC00      BDOS                          os/CPM_BDOS.asm      (Z-80, DISP)
;  $2600-$2BFF   $FA00      BIOS (as-shipped template)    os/CPM_BIOS.asm      (Z-80, DISP)
;
;  The CCP/BDOS file regions overlap by 6 bytes ($1700-$1705): that is the
;  shared "BD160001 4D40" serial that ends the CCP and begins the BDOS. CCP is
;  emitted first; BDOS rewrites those 6 bytes with the identical serial.
;  Gaps between regions are $00 (the SAVEBIN window zero-fills unwritten bytes).
;  Runtime boot/load patching is documented in BOOT_AND_PATCHING.md, not here.
; ============================================================================

    DEVICE NOSLOT64K
    DEFINE CPM60_LINK            ; tell each INCLUDEd module: master owns DEVICE/ORG/SAVEBIN

; --- installer driver: runs in place at $0100 (no relocation) -------------
TPA     EQU $0100                        ; CP/M transient program area (local; 60K build does not stage shared includes)
    ORG TPA
    MODULE inst
    INCLUDE "CPM60_installer.asm"
    ENDMODULE

; --- 6502 pieces: INCBIN the ca65-assembled binaries at their .COM offsets ---
    ORG $0400                    ; file $0300
    INCBIN "CPM_BootLoader.bin", $0000, $0100   ; boot loader page-0 slice ($0800)
    ORG $0500                    ; file $0400
    INCBIN "CPM_RWTS.bin",       $0000, $05BD   ; RWTS driver
    ORG $0B00                    ; file $0A00
    INCBIN "CPM_BootLoader.bin", $0800, $01F2   ; boot loader reloc page ($1000)
    ORG $0E80                    ; file $0D80
    INCBIN "CPM_InstallFragments.bin", $0180, $0080  ; install-fragments slice ($0380)

; --- CCP: stored at file $0E00, runs at $D300 -----------------------------
    ORG $0F00                    ; file $0E00
    MODULE ccp
    DISP $D300
    INCLUDE "os/CPM_CCP.asm"
    ENT
    ENDMODULE

; --- BDOS: stored at file $1700, runs at $DC00 (rewrites CCP's 6-byte tail) -
    ORG $1800                    ; file $1700
    MODULE bdos
    DISP $DC00
    INCLUDE "os/CPM_BDOS.asm"
    ENT
    ENDMODULE

; --- BIOS: stored at file $2600, runs at $FA00 (as-shipped template) -------
    ORG $2700                    ; file $2600
    MODULE bios
    DISP $FA00
    INCLUDE "os/CPM_BIOS.asm"
    ENT
    ENDMODULE

    SAVEBIN "CPM60.COM", $0100, $2C00
