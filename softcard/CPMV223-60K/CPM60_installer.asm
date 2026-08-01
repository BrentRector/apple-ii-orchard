; ============================================================================
; CPM60.COM  --  Z-80 INSTALLER DRIVER  (file offset 0x000-0x25F, ORG $0100)
; "Softcard CP/M  60K CP/M Disk update program  (C) 1982 Microsoft"
;
; This is the part of CPM60.COM that runs as an ordinary CP/M .COM program in
; the TPA. Its job: take a normal 44K-system Apple/Softcard CP/M boot disk and
; REWRITE its system tracks in place with the embedded 60K system (CCP+BDOS+BIOS
; carried later in this same .COM file), turning the disk into a 60K-CP/M disk.
;
; Reassembles BYTE-IDENTICAL to CPM60.COM[0x000:0x260] (608 bytes), verified.
;
; --- BDOS calls used (LD C,n / CALL $0005) ---
;   $20 set/get user        E=$1F -> SET user 31. Per CPMREF fn 32, E=$FF GETS;
;                           any other E SETS (mod 32). $1F is a set, and it is what
;                           puts user byte $1F on the reservation entry made below.
;   $19 get current disk    $1B Get Addr(Alloc) -> HL = allocation bitmap
;                           (NOT the DPB; that is fn $1F)
;   $0E select disk         $13 delete file       $16 make (create) file
;   $10 close file          $06 direct console I/O (E=$FF -> poll keyboard)
;   $09 print '$'-string
;
; --- HOW IT WRITES THE NEW SYSTEM (the important part) ---
; It does NOT use BDOS file writes to lay down the system tracks. It pokes the
; 60K BIOS's own RWTS-bridge variables in high RAM and triggers a 6502 "RPC":
;   $F3D0 <- RPC parameter word (HL); A written through trampoline ptr ($F3DE)
;   $F3E0/$F3E1 = IOB track/sector, $F3E9 = IOB buffer page, $F3EB = IOB command (2 = write).
;   These are the SAME page-3 IOB cells the deblock uses (CPMV223-44K/os/CPM_BootLoader_DiskXlate.asm);
;   an earlier EQU set here called them sector / track / sector-count, all three wrong.
;   $F3EA = error/status returned by the 6502 side (0 = OK)
; A store to Z-80 $E700 (= Apple $C700, slot-7 access) is what actually invokes
; the 6502 RWTS; RPC_WRITE here writes the opcode byte through ($F3DE) to do the
; same. This is identical to the CCP sysgen path (CPM_CCP.asm SUB_DB06 @ $DB06)
; and the BIOS RPC_DISPATCH (@ $FB45) -- the installer is a stand-alone clone of
; the in-system "write the system tracks" routine.
; ============================================================================

    IFNDEF CPM60_LINK  ; [link] master defines CPM60_LINK and owns this; standalone keeps it
    DEVICE NOSLOT64K
    ENDIF

; -- CP/M page-zero / BDOS --

; -- 60K-BIOS RWTS-bridge variables (high RAM, shared with 6502 via window) --
RPC_PARM    EQU $F3D0   ; RPC parameter word (page/opcode passed to 6502)
RPC_TRAMP   EQU $F3DE   ; ptr to live RPC trampoline; opcode byte written thru it
; The page-3 IOB cells are SHARED external names from include/apple_softcard.inc, not
; re-derived here. This file previously minted four of its own, three of them wrong:
; $F3EB "sector count" (it is the COMMAND, 2 = write), $F3E9 "starting track" (it is the
; buffer-pointer high byte), and $F3E6 "drive letter glyph" (the glyph goes to $0284; this
; is the SLOT, $60 = slot 6 << 4).
    INCLUDE "apple_softcard.inc"
    INCLUDE "cpm22.inc"            ; CP/M 2.2 ABI: base page + BDOS function codes
;   DSK_TRACK $F3E0  DSK_SECTOR $F3E1  DSK_DRIVE $F3E4  DSK_SLOT $F3E6
;   DSK_BUFFER $F3E8  DSK_BUFFER_HI $F3E9  DSK_STATUS $F3EA  DSK_COMMAND $F3EB

    IFNDEF CPM60_LINK  ; [link] master defines CPM60_LINK and owns this; standalone keeps it
    ORG TPA
    ENDIF

; ===========================================================================
; TPA_START -- the installer's main(): convert the target disk to 60K in place.
;   Purpose:   validate the disk through the BDOS, reserve its system area, write
;              the embedded 60K system image onto the system tracks via the 6502
;              RWTS, then fire the 6502 cold-boot relocator to bring it up.
;   In:        runs as a CP/M .COM at $0100; DEFAULT_FCB drive byte = optional
;              "X:" command-line drive; the 60K image follows at file page $0E.
;   Out:       does not return -- ends by JP $000B into the 6502 relocator (or a
;              reboot prompt on error). The target disk is left as a 60K system.
;   Algorithm: (1) pick the target drive; (2) validate + reserve via BDOS; (3)
;              commit the reservation; (4) prompt the operator; (5) raw-write the
;              48-page image through the RPC loop; (6) hand off to the relocator.
; ===========================================================================
; 1) DETERMINE TARGET DRIVE
;    SET the user number to 31 (fn $20, E=$1F -- NOT a get; fn 32 gets only on
;    E=$FF). Everything this program creates therefore lands under user 31, which
;    is outside the 0-15 the CCP's DIR and USER commands reach. If a drive was given
;    on the command line
;    (FCB drive byte != 0) use it; else query current disk (fn $19) and +1.
;    Save (drive & 3) -> DSK_DRIVE for the 6502 RWTS.  C = 1-based drive index.
; ---------------------------------------------------------------------------
TPA_START:
        LD C,$20                ; BDOS fn 32 set/get user code
        LD E,$1F                ; SET user = 31. NOT a get: fn 32 gets only when E=$FF
                                ; [DOC CPMREF fn 32: "If register E is not 0FFH, then the
                                ; current user number is changed to the value of E (modulo 32)"]
        CALL BDOS
        LD A,(TFCB)      ; FCB drive byte (cmdline "X:" if supplied)
        OR A
        JP NZ,TPA_START_1       ; non-zero -> use the explicit drive
        LD C,DRV_GET                ; fn $19 get current disk (0-based)
        CALL BDOS
        INC A                   ; make 1-based to match FCB convention
TPA_START_1:
        LD C,A                  ; C = 1-based target drive
        AND $03
        LD (DSK_DRIVE),A         ; F3E4 = drive & 3 (which Disk II drive)
        DEC C                   ; C = 0-based drive
        PUSH BC                 ; keep drive across the BDOS probing below

; ---------------------------------------------------------------------------
; 2) VALIDATE THE TARGET DISK via BDOS, before doing any raw writes:
;    - select it (fn $0E)
;    - delete any stale "cp/m    sys" reservation entry (fn $13)
;    - CHECK THAT BLOCKS 128-139 ARE FREE, by reading the allocation vector
;      (fn $1B) and testing the two bitmap bytes that cover them
;    - try to MAKE a file (fn $16) named "cp/m    sys" to (a) check the disk is
;      not write-protected and (b) reserve directory/space. If make fails (A=$FF
;      after INC -> Z) -> "Disk space already in use".
;
; The +$10 test below is a FREE-SPACE check on the twelve surplus blocks, not a
; "geometry sanity" check as an earlier header here claimed. fn $1B is
; Get Addr(Alloc), which returns the allocation BITMAP, not the DPB (that is
; fn $1F). In the bitmap the MSB of byte 0 is block 0, so byte $10 covers blocks
; 128-135 and the next byte covers 136-143; AND $F0 tests exactly 136-139.
; Together that is precisely blocks 128..139 -- the twelve this program is about
; to reserve. COPY.COM runs the identical sequence and routes the same failure to
; its "Disk space already in use" message, which names what is being tested. [RE]
;
; Note the code hard-codes byte offset $10, so it assumes DSM=139: under DSM=127
; the allocation vector is only 16 bytes and this reads past its end.
; ---------------------------------------------------------------------------
        LD E,C
        LD C,DRV_SET                ; fn $0E select disk = C (0-based)
        CALL BDOS
        LD C,F_DELETE                ; fn $13 delete file
        LD DE,$0355             ; FCB "cp/m    sys" (the reservation entry)
        CALL BDOS
        LD C,DRV_ALLOCVEC                ; fn $1B Get Addr(Alloc); HL -> allocation bitmap
        CALL BDOS
        LD DE,$0010             ; +$10 = bitmap byte covering blocks 128-135
        ADD HL,DE
        LD A,(HL)               ; blocks 128-135 must all be free
        OR A
        JP NZ,TPA_START_8       ; already in use -> "Disk I/O error"
        INC HL
        LD A,(HL)
        AND $F0                 ; blocks 136-139 (top 4 bits) must be free
        OR A
        JP NZ,TPA_START_8       ; already in use -> "Disk I/O error"
        LD C,F_MAKE                ; fn $16 make file (create "cp/m    sys")
        LD DE,$0355
        CALL BDOS
        INC A                   ; $FF -> 0 means make failed (no dir entry)
        JP Z,TPA_START_9        ;   -> "Disk space already in use"

; ---------------------------------------------------------------------------
; 3) Fill the new file's FCB record-map with blocks $80..$8B (12 records),
;    set record-count/extent fields, then CLOSE (fn $10) to commit the
;    directory entry that reserves the area the system will occupy.
; ---------------------------------------------------------------------------
        LD HL,$0365             ; FCB+16 (disk allocation map)
        LD C,$80                ; first block number
        LD B,$0C                ; 12 blocks
TPA_START_2:
        LD (HL),C
        INC C
        INC HL
        DEC B
        JP NZ,TPA_START_2
        LD A,$60
        LD ($0364),A            ; FCB current-record / RC field
        XOR A
        LD ($0363),A            ; FCB extent = 0
        LD C,F_CLOSE                ; fn $10 close file -> commit directory entry
        LD DE,$0355
        CALL BDOS
        POP BC                  ; restore drive (C = 0-based)

; ---------------------------------------------------------------------------
; 4) Build the drive-letter glyphs used in the on-screen messages, then print
;    banner + "Insert 16 sector disk into drive Z:  Press RETURN to begin".
;    Wait for RETURN (WAIT_KEY = poll console fn $06 until a key).
; ---------------------------------------------------------------------------
        LD A,C
        AND $0E
        ADD A,A
        ADD A,A
        ADD A,A
        CPL
        ADD A,$61
        LD (DSK_SLOT),A         ; $F3E6 = slot << 4 ($60 = slot 6). NOT the drive glyph:
                                ;   that is computed next and stored to $0284.
        LD A,C
        ADD A,$41               ; 'A'+drive -> letter
        LD ($0284),A            ; patch the "drive Z:" letter in the prompt
        LD DE,$0212             ; banner+prompt string
        CALL PRINT_STR
        CALL WAIT_KEY           ; wait for RETURN

; ---------------------------------------------------------------------------
; 5) WRITE THE EMBEDDED SYSTEM TO THE SYSTEM TRACKS  (the actual install).
;    Set up the raw-write bridge: IOB command = 2 (write), IOB buffer page = $14
;    (Apple $1400, the start of the system image), and HL = $0000 so the first
;    unit goes to TRACK 0, SECTOR 0. Loop B=$30 (48) units. Because L is the track
;    and H the sector, and H wraps at 16, this walks sectors 0-15 of track 0, then
;    track 1, then track 2: 48 x 256 = 12,288 bytes = THE THREE SYSTEM TRACKS.
;    That is independent confirmation, from a different routine, that the region
;    the 'cp/m    sys' entry claims is the system area. Each pass:
;      - RPC_WRITE: RPC write of one unit ($F3D0 <- $0E03 opcode; A=page byte
;        written thru ($F3DE)) -> 6502 RWTS lays the page onto the disk.
;      - read DSK_STATUS ($F3EA): 0 = OK; $10 = write protected; other = I/O error
;      - advance the IOB buffer page, then the sector; on sector wrap, the track.
;    On any error, print the matching message and bail to the reboot prompt.
; ---------------------------------------------------------------------------
        LD A,$02
        LD (DSK_COMMAND),A          ; $F3EB = 2 = WRITE command
        LD A,$14
        LD (DSK_BUFFER_HI),A       ; $F3E9 = buffer page $14 -> Apple $1400 (image start)
        LD HL,WBOOTV            ; HL = $0000: L = TRACK 0, H = SECTOR 0
        LD B,$30                ; 48 units = 3 tracks x 16 sectors = 12,288 bytes
TPA_START_3:
        LD (DSK_TRACK),HL       ; L -> $03E0 track, H -> $03E1 sector
        PUSH BC
        PUSH HL
        LD HL,$0E03             ; RPC opcode/parm: page $0E, function $03 (write)
        CALL RPC_WRITE          ; do the raw write via 6502
        LD A,(DSK_STATUS)         ; F3EA: 6502 status
        OR A
        JP Z,TPA_START_5        ; 0 -> OK, continue
        LD DE,$02E4             ; default error msg = "Disk I/O error"
        CP $10
        JP NZ,TPA_START_4
        LD DE,$02F9             ; status $10 -> "Disk write protected"
TPA_START_4:
        CALL PRINT_STR
        JP TPA_START_7          ; -> reboot prompt
TPA_START_5:
        LD HL,DSK_BUFFER_HI
        INC (HL)                ; next 256 bytes of the image
        POP HL
        INC H                   ; next SECTOR
        LD A,H
        SUB $10                 ; all 16 sectors of this track done?
        JP NZ,TPA_START_6
        INC L                   ; yes: next TRACK
        LD H,A                  ; A is 0 here, so sector := 0
TPA_START_6:
        POP BC
        DEC B
        JP NZ,TPA_START_3       ; loop all 48 pages
        LD DE,$029F             ; "Disk has been updated to 60K"
        CALL PRINT_STR

; ---------------------------------------------------------------------------
; 6) Print "Press RETURN to re-boot system", wait, then hand off to the 6502
;    cold-boot relocator: plant the RPC trigger at $000B ($C777), set the 6502
;    entry page ($C600 -> Disk II boot ROM at slot 6) into RPC_PARM, and JP $000B
;    which fires the 6502 to relocate/boot the freshly written 60K system.
; ---------------------------------------------------------------------------
TPA_START_7:
        LD DE,$02C0             ; "Press RETURN to re-boot system"
        CALL PRINT_STR
        CALL WAIT_KEY
        LD HL,$C777             ; 6502 trampoline target (slot-7 RPC vector)
        LD ($000B),HL
        LD HL,$C600             ; 6502 entry = $C600 (slot-6 Disk II boot ROM)
        LD (RPC_PARM),HL        ; F3D0 = boot entry for the 6502 side
        LD HL,(RPC_TRAMP)       ; HL = live trampoline ptr
        JP $000B                ; fire 6502: relocate + cold-boot the 60K system

; -- error exits --
TPA_START_8:
        LD DE,$0314             ; "Disk I/O error" (geometry check failed)
        JP TPA_START_4
TPA_START_9:
        LD DE,$0334             ; "Disk space already in use" (make failed)
        JP TPA_START_4

; ---------------------------------------------------------------------------
; RPC_WRITE -- issue one 6502 "RPC" (remote procedure call into the 6502 RWTS).
;   Purpose:   hand the 6502 side one raw-disk request -- publish the parameter
;              word, then poke the opcode byte through the live trampoline pointer,
;              whose store address is a slot soft-switch ($E700 = Apple $C700) that
;              transfers control to the 6502 RWTS. Returns once the 6502 serviced it.
;   In:        HL = RPC parameter word (page in H, function in L, e.g. $0E03 =
;              page $0E, function $03 write); A = opcode byte written through the
;              trampoline to trigger the 6502.
;   Out:       the 6502 has run; it leaves its status in DSK_STATUS ($F3EA) for the
;              caller to test (0 = OK, $10 = write-protected, else = I/O error).
;   Clobbers:  HL (reloaded from RPC_TRAMP). A is consumed.
;   Algorithm: (RPC_PARM) <- HL ; HL <- (RPC_TRAMP) ; (HL) <- A  [fires the 6502].
; ---------------------------------------------------------------------------
RPC_WRITE:
        LD (RPC_PARM),HL        ; F3D0 = parm word
        LD HL,(RPC_TRAMP)       ; HL = trampoline ptr
        LD (HL),A               ; write opcode -> triggers 6502 (e.g. $E700)
        RET

; ---------------------------------------------------------------------------
; WAIT_KEY -- block until the operator presses a key.
;   Purpose:   pause the installer until a keypress (used after each prompt).
;   In:        none.  Out: A = the key code read (non-zero); Z cleared.
;   Clobbers:  A, C, E (BDOS-call registers).
;   Algorithm: poll BDOS fn $06 direct console input with E=$FF until it returns
;              a non-zero character.
; ---------------------------------------------------------------------------
WAIT_KEY:
        LD C,C_RAWIO
        LD E,$FF                ; direct console input: poll keyboard
        CALL BDOS
        OR A
        JP Z,WAIT_KEY           ; loop until a non-zero key
        RET

; ---------------------------------------------------------------------------
; PRINT_STR -- print a '$'-terminated message.
;   Purpose:   write one console message.  In: DE -> '$'-terminated string.
;   Out:       string printed; tail-calls the BDOS (returns to PRINT_STR's caller).
;   Clobbers:  C (=fn $09); the BDOS's own working registers.
;   Algorithm: C <- $09 (print string); JP BDOS_VEC (tail call).
; ---------------------------------------------------------------------------
PRINT_STR:
        LD C,C_WRITESTR
        JP BDOS

; ============================================================================
; STRINGS / DATA  (file 0x112-0x255, $0212-$0355)
;   $0212  "\r\n      Softcard CP/M\r\n60K CP/M Disk update program\r\n"
;          "    (C) 1982 Microsoft\r\n\r\nInsert 16 sector disk into drive Z:\r\n"
;          "Press RETURN to begin $"        ($0284 = the 'Z' that gets patched)
;   $029F  "\r\n\r\nDisk has been updated to 60K$"
;   $02C0  "\r\n\r\nPress RETURN to re-boot system $"
;   $02E4  "\r\n\r\nDisk I/O error\r\n$"
;   $02F9  "\r\n\r\nDisk write protected\r\n$"
;   $0314  "\r\n\r\nDisk space already in use\r\n$"   (also used for geom error)
;   $0334  "\r\n\r\nNot enough directory space\r\n$"
;   $0353  $0D $0A $24 $00  then FCB template at $0355:
;   $0355  00 "cp/m    " "sys" 00...  (FCB for placeholder file CP/M.SYS)
; ============================================================================
        DEFB    $0D,$0A,$0D,$0A,$20,$20,$20,$20,$20,$20,$53,$6F,$66,$74,$63,$61 ; $0212
        DEFB    "rd CP/M",$0D
        DEFB    $0A,$36,$30,$4B,$20,$43,$50,$2F,$4D,$20,$44,$69,$73,$6B,$20,$75 ; $022A
        DEFB    "pdate program",$0D
        DEFB    $0A,$20,$20,$20,$20,$28,$43,$29,$20,$31,$39,$38,$32,$20,$4D,$69 ; $0248
        DEFB    "crosoft",$0D
        DEFB    $0A,$0D,$0A,$49,$6E,$73,$65,$72,$74,$20,$31,$36,$20,$73,$65,$63 ; $0260
        DEFB    "tor disk into drive Z:",$0D
        DEFB    $0A,$50,$72,$65,$73,$73,$20,$52,$45,$54,$55,$52,$4E,$20,$74,$6F ; $0287
        DEFB    " begin $",$0D
        DEFB    $0A,$0D,$0A,$44,$69,$73,$6B,$20,$68,$61,$73,$20,$62,$65,$65,$6E ; $02A0
        DEFB    " updated to 60K$",$0D
        DEFB    $0A,$0D,$0A,$50,$72,$65,$73,$73,$20,$52,$45,$54,$55,$52,$4E,$20 ; $02C1
        DEFB    "to re-boot system $",$0D
        DEFB    $0A,$0D,$0A,$44,$69,$73,$6B,$20,$49,$2F,$4F,$20,$65,$72,$72,$6F ; $02E5
        DEFB    $72,$0D,$0A,$24,$0D,$0A,$0D,$0A,$44,$69,$73,$6B,$20,$77,$72,$69 ; $02F5
        DEFB    "te protected",$0D
        DEFB    $0A,$24,$0D,$0A,$0D,$0A,$44,$69,$73,$6B,$20,$73,$70,$61,$63,$65 ; $0312
        DEFB    " already in use",$0D
        DEFB    $0A,$24,$0D,$0A,$0D,$0A,$4E,$6F,$74,$20,$65,$6E,$6F,$75,$67,$68 ; $0332
        DEFB    " directory space",$0D
        DEFB    $0A,$24,$00,$63,$70,$2F,$6D,$20,$20,$20,$20,$73,$79,$73 ; $0353  ...00 "cp/m    sys"

    IFNDEF CPM60_LINK  ; [link] master defines CPM60_LINK and owns this; standalone keeps it
    SAVEBIN "CPM60_installer.bin", $0100, $0261
    ENDIF
