; ============================================================================
;  CPM_BootLoader_DiskXlate.asm -- Z-80 disk read/sector-translate glue that
;  lives INSIDE the 2.23 / 44K 6502 boot image and is executed by the Z-80, not
;  the 6502 (the CPM_RPC6502 pattern, reversed CPU: the boot image is 6502/ca65,
;  but these 274 bytes are Z-80 code, so they are assembled by the Z-80 assembler
;  and the resulting binary is INCBIN'd back into CPM_BootLoader.s at the right
;  offset). Stored in the boot image at $0C39, relocated by LOAD_CPM's PAGE_COPY
;  into language-card RAM at $BC39, and executed there by the Z-80 once CP/M is
;  running. The 6502 nibble-translate tables that the RWTS reads ($BD5A write
;  table, $BD04+$96.. read table) physically follow this region in the page image.
;
;  Two entry points, both reached from the Z-80 BIOS:
;    SECTOR_MAP  ($BC39)  translate a logical CP/M sector request into a physical
;                         track/sector + buffer move; drives the page-3 IOB mirror
;                         at $F3xx (Apple $03xx) and the BIOS disk scratch at $FExx.
;    DISK_READ   ($BD25)  set up and issue one RWTS read through the IOB, then test
;                         the completion status; its error-classify tail ($BD45-
;                         $BD4A) jumps back to SM_RET on a soft error or to the BIOS
;                         error handler ($FEC6) on a hard one.
;
;  Addresses are the Z-80 run view: $F3xx = Apple $03xx (page-3 IOB mirror, as the
;  6502 sees $03xx); $FExx = the Z-80 BIOS disk scratch; $ADxx = Z-80 BIOS helper
;  routines the glue calls. ORG is the $BC39 run address so every in-routine
;  relative jump resolves to a label here. Byte-identical does NOT depend on ORG
;  (SAVEBIN emits the bytes regardless); $BC39 is chosen only so the JR/JR-cc
;  operands land on these labels. Reassembles BYTE-IDENTICAL to the original
;  $0C39-$0D4A bytes (274 = $112).
; ============================================================================
    DEVICE NOSLOT64K

; -- page-3 IOB mirror (Z-80 $F3xx = Apple $03xx) --
IOB_TRACK   EQU $F3E0        ; IOB TRACK cell (Apple $03E0); $03E1 = sector. Verified against
                             ;   the shipped RWTS (RWTS_MAIN reads $03E0 track / $03E1 sector)
                             ;   and at runtime. An earlier EQU called $03E0 the sector.
IOB_DRIVE   EQU $F3E4        ; IOB DRIVE-select cell (Apple $03E4), 1 or 2. NOT the track;
                             ;   an earlier EQU called it the track cell.
IOB_VOL     EQU $F3E6        ; IOB volume cell (Apple $03E6)
IOB_BUF     EQU $F3E8        ; IOB buffer pointer (Apple $03E8/$03E9)
IOB_CMD     EQU $F3EB        ; IOB command cell (Apple $03EB)
IOB_RETCODE EQU $F3EA        ; IOB return-code cell (Apple $03EA)

; -- Z-80 BIOS disk scratch ($FExx) --
REQ_TRACK   EQU $FED1        ; requested TRACK (observed 3 for the directory, 35 for block 128).
                             ;   An earlier EQU called this the requested sector.
REQ_RECORD  EQU $FED2        ; requested RECORD index within the track. An earlier EQU called
                             ;   this the requested track; they were transposed.
SCR_D6      EQU $FED6        ; current track scratch
SCR_D7      EQU $FED7        ; saved current track
SCR_D8      EQU $FED8        ; first-call flag
SCR_D9      EQU $FED9        ; pending-reseek flag
SCR_DA      EQU $FEDA        ; direction / move flags
SCR_DB      EQU $FEDB        ; read/write direction flag
SCR_DC      EQU $FEDC        ; seek-needed flag (16-bit cell)
SCR_DD      EQU $FEDD        ; retry / settle counter (16-bit cell)
SCR_DF      EQU $FEDF        ; last track/sector cache (16-bit cell)
SCR_E1      EQU $FEE1        ; host buffer pointer (16-bit cell)
DPB_DSM     EQU $FEE3        ; the running DPB's DSM byte ($8B on 2.23, $7F on the 2.20 twin).
                             ;   NOT a 'deblock flag': the fold below tests it explicitly.

; -- Z-80 BIOS helper routines --
BIOS_SKEW   EQU $AD4A        ; logical->physical sector skew table base
BIOS_SEEK   EQU $AD25        ; BIOS seek/recalibrate helper
BIOS_FLUSH  EQU $AD2C        ; BIOS deblock-flush helper
BIOS_RWTS   EQU $FEC3        ; BIOS RWTS issue (runs one IOB operation)
BIOS_ERR    EQU $FEC6        ; BIOS RWTS error-handler entry (read failed)
BIOS_RETRY  EQU $FECA        ; BIOS RWTS retry/return continuation

    ORG $BC39

; ----------------------------------------------------------------------------
; SECTOR_MAP ($BC39): translate the requested logical sector into a physical
; track/sector, deciding whether a seek/reseek is needed and whether the host
; buffer move runs forward (read) or is staged (write).
; ----------------------------------------------------------------------------
SECTOR_MAP:
        XOR A                            ; $BC39  AF
        LD (SCR_DD),A                    ; $BC3A  32 DD FE   clear retry counter low
        LD A,$02                         ; $BC3D  3E 02
        LD HL,SCR_DA                     ; $BC3F  21 DA FE
        LD (HL),A                        ; $BC42  77         SCR_DA = 2
        INC HL                           ; $BC43  23
        LD (HL),A                        ; $BC44  77         SCR_DB = 2
        INC HL                           ; $BC45  23
        LD (HL),A                        ; $BC46  77         SCR_DC = 2
        JR SM_MAP                        ; $BC47  18 48
; -- alternate entry (BIOS jumps here for the cached-track fast path) --
SM_CACHED:
        LD H,C                           ; $BC49  61
        LD L,$00                         ; $BC4A  2E 00
        LD (SCR_DA),HL                   ; $BC4C  22 DA FE
        LD A,C                           ; $BC4F  79
        CP $02                           ; $BC50  FE 02
        JR NZ,SM_CHKDD                   ; $BC52  20 0F
        LD L,$08                         ; $BC54  2E 08
        LD A,(SCR_D6)                    ; $BC56  3A D6 FE
        LD H,A                           ; $BC59  67
        LD (SCR_DD),HL                   ; $BC5A  22 DD FE
        LD HL,(REQ_TRACK)                   ; $BC5D  2A D1 FE
        LD (SCR_DF),HL                   ; $BC60  22 DF FE
SM_CHKDD:
        LD HL,SCR_DD                     ; $BC63  21 DD FE
        LD A,(HL)                        ; $BC66  7E
        OR A                             ; $BC67  B7
        JR Z,SM_NEEDSEEK                 ; $BC68  28 21
        DEC (HL)                         ; $BC6A  35
        LD A,(SCR_D6)                    ; $BC6B  3A D6 FE
        INC HL                           ; $BC6E  23
        CP (HL)                          ; $BC6F  BE
        JR NZ,SM_NEEDSEEK                ; $BC70  20 19
        LD A,(REQ_TRACK)                    ; $BC72  3A D1 FE
        LD HL,(SCR_DF)                   ; $BC75  2A DF FE
        CP L                             ; $BC78  BD
        JR NZ,SM_NEEDSEEK                ; $BC79  20 10
        LD A,(REQ_RECORD)                    ; $BC7B  3A D2 FE
        CP H                             ; $BC7E  BC
        JR NZ,SM_NEEDSEEK                ; $BC7F  20 0A
        INC H                            ; $BC81  24
        LD (SCR_DF),HL                   ; $BC82  22 DF FE
        XOR A                            ; $BC85  AF
        LD (SCR_DC),A                    ; $BC86  32 DC FE   no seek needed
        JR SM_MAP                        ; $BC89  18 06
SM_NEEDSEEK:
        LD HL,$0001                      ; $BC8B  21 01 00
        LD (SCR_DC),HL                   ; $BC8E  22 DC FE   seek needed
; -- main map: derive physical sector from the skew table, schedule the seek --
SM_MAP:
        LD A,(REQ_RECORD)                    ; $BC91  3A D2 FE   requested record index
        LD E,A                           ; $BC94  5F
        OR A                             ; $BC95  B7
        RRA                              ; $BC96  1F
        LD HL,BIOS_SKEW                  ; $BC97  21 4A AD
        ADD A,L                          ; $BC9A  85
        LD L,A                           ; $BC9B  6F
        LD C,(HL)                        ; $BC9C  4E         C = physical sector
        LD HL,SCR_D8                     ; $BC9D  21 D8 FE
        LD A,(HL)                        ; $BCA0  7E
        LD (HL),$01                      ; $BCA1  36 01      mark not-first-call
        OR A                             ; $BCA3  B7
        JR Z,SM_NOFLUSH                  ; $BCA4  28 1B      first call -> skip flush
        LD HL,(SCR_D6)                   ; $BCA6  2A D6 FE
        LD A,L                           ; $BCA9  7D
        CP H                             ; $BCAA  BC
        JR NZ,SM_DOFLUSH                 ; $BCAB  20 0D
        LD HL,(IOB_TRACK)               ; $BCAD  2A E0 F3
        LD A,(REQ_TRACK)                    ; $BCB0  3A D1 FE
        CP L                             ; $BCB3  BD
        JR NZ,SM_DOFLUSH                 ; $BCB4  20 04
        LD A,C                           ; $BCB6  79
        CP H                             ; $BCB7  BC
        JR Z,SM_MOVE                     ; $BCB8  28 42      same sector -> move only
SM_DOFLUSH:
        LD A,(SCR_D9)                    ; $BCBA  3A D9 FE
        OR A                             ; $BCBD  B7
        CALL NZ,BIOS_SEEK                ; $BCBE  C4 25 AD
SM_NOFLUSH:
        LD A,(SCR_D6)                    ; $BCC1  3A D6 FE   current track
        LD (SCR_D7),A                    ; $BCC4  32 D7 FE
        LD B,A                           ; $BCC7  47
        AND $01                          ; $BCC8  E6 01
        INC A                            ; $BCCA  3C
        LD (IOB_DRIVE),A                 ; $BCCB  32 E4 F3
        LD A,B                           ; $BCCE  78
        AND $0E                          ; $BCCF  E6 0E
        ADD A,A                          ; $BCD1  87
        ADD A,A                          ; $BCD2  87
        ADD A,A                          ; $BCD3  87
        CPL                              ; $BCD4  2F
        ADD A,$61                        ; $BCD5  C6 61
        LD (IOB_VOL),A                   ; $BCD7  32 E6 F3
; ----------------------------------------------------------------------------
; THE $8B TRACK FOLD -- blocks 128-139 are ALIASED ONTO THE SYSTEM TRACKS 0-2.
;
; This is the mechanism behind the whole DSM=$8B business, and it is deliberate:
; the test is against $8B itself, so it fires only for the geometry that HAS the
; twelve surplus blocks. A merely defensive clamp would not need to know DSM.
;
;   requested track >= 35 (the medium is 35 tracks, 0-34)
;   AND the running DPB's DSM byte == $8B
;   -> subtract 35, and use THAT as the IOB track.
;
; The arithmetic lands exactly:
;   block 128 -> record 1024 -> OFF + 1024/SPT = 3 + 32 = track 35 -> 35-35 = 0
;   block 139 -> record 1112 -> 3 + 34         =       track 37 -> 37-35 = 2
;   blocks 128..139 = 12 blocks = 12 KB = tracks 0,1,2 = 12,288 bytes, EXACTLY.
;
; So the twelve blocks past the 2.20 twin's DSM=$7F are not phantom space. They
; are the three reserved system tracks, made addressable through the ordinary
; file system. On a DATA disk that is the point: it recovers the boot area as
; 12 KB of usable storage. On a BOOTABLE disk the 'cp/m    sys' directory entry
; (user $1F, block map exactly 128-139) claims them so no file can be allocated
; there, which is why the entry exists and why it is called that. [RE]
;
; TWO INDEPENDENT SOURCES describe this as an intentional feature, and both match
; what the instructions say:
;   [?] Apple II SoftCard CP/M Reference (community, apple2.guidero.us):
;       "SoftCard CP/M ver 2.23 and higher uses a trick to allow the system tracks
;        for data storage: a file called cp/m.sys is created in user area 31 as a
;        dummy file allocated to the system tracks. It is inaccessible from the CCP
;        and unseen by the user." and "COPY.COM has an option to create a 'data
;        diskette' where cp/m.sys is absent, which creates 3 more tracks for data
;        storage."
;   [?] CiderPress2 CP/M format notes: same entry, blocks $80-$8B wrapping to the
;       start of the disk, "appears to have originated with the Microsoft SoftCard,
;       is used to allow extra storage on non-bootable disks".
; Both are secondary sources ([?] tier), but they agree with each other and with the
; code, and the first names COPY's data-diskette option specifically. So a data disk
; WITHOUT the entry is the DESIGNED use of this space, not a hazard.
;
; *** AND HERE IS THE HAZARD NEITHER SOURCE MENTIONS. ***
; The presence of the entry is the ONLY thing that distinguishes "this disk's boot
; tracks are in use" from "this disk's boot tracks are free storage". A 2.20-lineage
; disk has a BOOT IMAGE on tracks 0-2 and NO entry, because under DSM=$7F it never
; needed one -- those blocks were not expressible. Mounted on a 2.23 system it is
; therefore INDISTINGUISHABLE FROM A DATA DISKETTE, and 2.23 will allocate its boot
; tracks to the next file that needs the space. Every 2.20 disk in existence is in
; that state. Neither reference says so; both describe only the intended case.
; NOTE the same reference's DPB table prints DSM=127 for both versions, which the
; shipped BIOS bytes contradict ($7F on 2.20, $8B on 2.23, verified across 8 archived
; images). Our bytes win; the reference is internally inconsistent, since its own
; "allocated to the system tracks" claim needs DSM>127 to be expressible at all.
;
; RESERVATION, NOT CONDUIT -- and the fold is still not decoration:
;   * NO shipped tool moves data through these blocks. CPM60.COM's entire BDOS
;     set is {$06,$09,$0E,$10,$13,$16,$19,$1B,$20}: no read or write call at all.
;     COPY.COM touches the FCB only with DRV_SET / F_DELETE / F_MAKE / F_CLOSE.
;     Both write the system image by RAW RPC to the 6502 instead, and the 60K
;     installer's own loop starts at TRACK 0 SECTOR 0 and runs 48 units = tracks
;     0,1,2 (CPMV223-60K/CPM60_installer.asm), which independently confirms what
;     region the entry describes. So the entry ACCOUNTS FOR the system area; it
;     is not a data path either tool uses.
;   * But the fold is not needed to make the reservation coherent. ALLOC_FROM_FCB
;     range-checks a block number and sets a BITMAP bit; it never converts a block
;     to a track. The reservation would work with no fold at all. The fold is
;     reached ONLY from this deblock, on real record I/O.
;   * And that I/O works. Round-trip verified in the emulator: a known 256-byte
;     pattern placed in the TPA and written with SAVE into block 128 arrived
;     byte-for-byte at track 0 sector 0.
;   So the twelve blocks are genuine, working storage that no Microsoft tool uses.
;   The beneficiary is ordinary user files on a disk with no boot image to protect,
;   which is exactly the use CiderPress2 describes.
;
; CONSEQUENCE, and the hazard is SPECIFIC: a disk that carries a boot image but
; NOT the protecting entry. That is every 2.20-lineage system disk (DSM=$7F, so
; it never needed one) read on a 2.23 system. Once blocks 0-127 are full the
; allocator hands out 128-139, and the write does NOT fail and does NOT reach a
; drive error -- it silently overwrites tracks 0-2 and destroys the boot pipeline.
; Verified in the emulator: SAVE into block 128 reported success, committed the
; directory entry, and changed 689 bytes of track 0. A non-bootable data disk is
; NOT at risk; there the same writes are the intended use of the space.
; See docs/CPM_Disk_Creation.md and docs/CPM_Source_Changes_For_Narratives.md Part 5.
; ----------------------------------------------------------------------------
        LD A,(REQ_TRACK)                 ; $BCDA  3A D1 FE   requested track
        CP $23                           ; $BCDD  FE 23      35 = past the last track
        JR C,SM_SETSEC                   ; $BCDF  38 0B      normal track, use as-is
        LD L,A                           ; $BCE1  6F
        LD A,(DPB_DSM)                   ; $BCE2  3A E3 FE   running DPB's DSM
        CP $8B                           ; $BCE5  FE 8B      only the 140-block geometry
        JR NZ,SM_STORE                   ; $BCE7  20 04
        LD A,L                           ; $BCE9  7D
        SUB $23                          ; $BCEA  D6 23      fold onto tracks 0-2
SM_SETSEC:
        LD L,A                           ; $BCEC  6F
SM_STORE:
        LD H,C                           ; $BCED  61
        LD (IOB_TRACK),HL               ; $BCEE  22 E0 F3
        LD A,(SCR_DC)                    ; $BCF1  3A DC FE
        OR A                             ; $BCF4  B7
        CALL NZ,BIOS_FLUSH               ; $BCF5  C4 2C AD
        XOR A                            ; $BCF8  AF
        LD (SCR_D9),A                    ; $BCF9  32 D9 FE
; -- SM_MOVE ($BCFC): move the 128-byte CP/M record to/from the host buffer --
SM_MOVE:
        LD A,E                           ; $BCFC  7B
        LD HL,$F800                      ; $BCFD  21 00 F8   sector buffer base
        RRA                              ; $BD00  1F
        RR L                             ; $BD01  CB 1D      +$80 for odd record
        LD DE,(SCR_E1)                   ; $BD03  ED 5B E1 FE host buffer pointer
        LD BC,$0080                      ; $BD07  01 80 00   128 bytes
        LD A,(SCR_DA)                    ; $BD0A  3A DA FE
        OR A                             ; $BD0D  B7
        JR NZ,SM_LDIR                    ; $BD0E  20 05
        INC A                            ; $BD10  3C
        LD (SCR_D9),A                    ; $BD11  32 D9 FE
        EX DE,HL                         ; $BD14  EB         swap dir (write path)
SM_LDIR:
        LDIR                             ; $BD15  ED B0
        LD A,(SCR_DB)                    ; $BD17  3A DB FE
        RRA                              ; $BD1A  1F
        LD A,$00                         ; $BD1B  3E 00
        JR NC,SM_RET                     ; $BD1D  30 03
        CALL BIOS_SEEK                   ; $BD1F  CD 25 AD
SM_RET:
        JP BIOS_RETRY                    ; $BD22  C3 CA FE

; ----------------------------------------------------------------------------
; DISK_READ ($BD25): set up the IOB for a read of the CP/M system region and
; issue it via the BIOS RWTS, then test the IOB return code.
; ----------------------------------------------------------------------------
DISK_READ:
        XOR A                            ; $BD25  AF
        LD (SCR_D9),A                    ; $BD26  32 D9 FE   clear reseek flag
        LD A,$02                         ; $BD29  3E 02
        LD HL,$013E                      ; $BD2B  21 3E 01
        LD (IOB_CMD),A                   ; $BD2E  32 EB F3   command = read
        LD HL,$0800                      ; $BD31  21 00 08
        LD (IOB_BUF),HL                  ; $BD34  22 E8 F3   buffer = $0800
        LD HL,$0E03                      ; $BD37  21 03 0E
        CALL BIOS_RWTS                   ; $BD3A  CD C3 FE   issue the read
        LD A,(IOB_RETCODE)               ; $BD3D  3A EA F3
        OR A                             ; $BD40  B7
        RET Z                            ; $BD41  C8         ok -> return
        POP DE                           ; $BD42  D1
        CP $10                           ; $BD43  FE 10      classify the error code
        JR NZ,SM_RET                     ; $BD45  20 DB      not a hard error -> SM_RET ($BD22)
        JP BIOS_ERR                      ; $BD47  C3 C6 FE   hard error -> BIOS error handler
        NOP                              ; $BD4A  00         pad to the page-table boundary

    SAVEBIN "{out_bin}", $BC39, $0112    ; 274 bytes, $BC39..$BD4A
