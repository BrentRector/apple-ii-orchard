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
;   $20 set/get user        $1F (E=$1F) -> get current user number
;   $19 get current disk    $1B get allocation-vector / DPB address (returns HL)
;   $0E select disk         $13 delete file       $16 make (create) file
;   $10 close file          $06 direct console I/O (E=$FF -> poll keyboard)
;   $09 print '$'-string
;
; --- HOW IT WRITES THE NEW SYSTEM (the important part) ---
; It does NOT use BDOS file writes to lay down the system tracks. It pokes the
; 60K BIOS's own RWTS-bridge variables in high RAM and triggers a 6502 "RPC":
;   $F3D0 <- RPC parameter word (HL); A written through trampoline ptr ($F3DE)
;   $F3E0/$F3E9/$F3EB = sector / track / sector-count for the raw disk write
;   $F3EA = error/status returned by the 6502 side (0 = OK)
; A store to Z-80 $E700 (= Apple $C700, slot-7 access) is what actually invokes
; the 6502 RWTS; SUB_01F9 here writes the opcode byte through ($F3DE) to do the
; same. This is identical to the CCP sysgen path (CPM_CCP.asm SUB_DB06 @ $DB06)
; and the BIOS RPC_DISPATCH (@ $FB45) -- the installer is a stand-alone clone of
; the in-system "write the system tracks" routine.
; ============================================================================

    IFNDEF CPM60_LINK  ; [link] master defines CPM60_LINK and owns this; standalone keeps it
    DEVICE NOSLOT64K
    ENDIF

; -- CP/M page-zero / BDOS --
WBOOT_VEC   EQU $0000   ; warm-boot vector (JP WBOOT). Also poked as RPC trigger.
BDOS_VEC    EQU $0005   ; BDOS entry (CALL $0005)
RST2_VEC    EQU $0010   ; +offset used to index the DPB returned by fn $1B
DEFAULT_FCB EQU $005C   ; default FCB (drive byte = cmdline arg-1 drive, if given)

; -- 60K-BIOS RWTS-bridge variables (high RAM, shared with 6502 via window) --
RPC_PARM    EQU $F3D0   ; RPC parameter word (page/opcode passed to 6502)
RPC_TRAMP   EQU $F3DE   ; ptr to live RPC trampoline; opcode byte written thru it
RPC_STAT    EQU $F3EA   ; 6502-returned status (0=ok, $10=protected, else=I/O err)
RW_SECCNT   EQU $F3EB   ; sector count for a raw write
RW_TRACK    EQU $F3E9   ; starting track
RW_SECTOR   EQU $F3E0   ; sector value
DRV_MASK    EQU $F3E4   ; (current drive & 3) - target drive for the 6502 RWTS
DRV_NAME    EQU $F3E6   ; drive letter glyph for messages

    IFNDEF CPM60_LINK  ; [link] master defines CPM60_LINK and owns this; standalone keeps it
    ORG $0100
    ENDIF

; ---------------------------------------------------------------------------
; 1) DETERMINE TARGET DRIVE
;    Get current user (fn $20/$1F). If a drive was given on the command line
;    (FCB drive byte != 0) use it; else query current disk (fn $19) and +1.
;    Save (drive & 3) -> DRV_MASK for the 6502 RWTS.  C = 1-based drive index.
; ---------------------------------------------------------------------------
TPA_START:
        LD C,$20                ; BDOS fn $20 set/get user code...
        LD E,$1F                ; E=$1F -> "get" current user number
        CALL BDOS_VEC
        LD A,(DEFAULT_FCB)      ; FCB drive byte (cmdline "X:" if supplied)
        OR A
        JP NZ,TPA_START_1       ; non-zero -> use the explicit drive
        LD C,$19                ; fn $19 get current disk (0-based)
        CALL BDOS_VEC
        INC A                   ; make 1-based to match FCB convention
TPA_START_1:
        LD C,A                  ; C = 1-based target drive
        AND $03
        LD (DRV_MASK),A         ; F3E4 = drive & 3 (which Disk II drive)
        DEC C                   ; C = 0-based drive
        PUSH BC                 ; keep drive across the BDOS probing below

; ---------------------------------------------------------------------------
; 2) VALIDATE THE TARGET DISK via BDOS, before doing any raw writes:
;    - select it (fn $0E)
;    - delete any stale "CP/M     SYS" placeholder (fn $13)
;    - read its DPB (fn $1B) and sanity-check the disk geometry bytes
;    - try to MAKE a file (fn $16) named "cp/m    sys" to (a) check the disk is
;      not write-protected and (b) reserve directory/space. If make fails (A=$FF
;      after INC -> Z) -> "Disk space already in use".
; ---------------------------------------------------------------------------
        LD E,C
        LD C,$0E                ; fn $0E select disk = C (0-based)
        CALL BDOS_VEC
        LD C,$13                ; fn $13 delete file
        LD DE,$0355             ; FCB "cp/m    sys" (CP/M.SYS placeholder)
        CALL BDOS_VEC
        LD C,$1B                ; fn $1B get allocation vector / DPB; HL->DPB
        CALL BDOS_VEC
        LD DE,RST2_VEC          ; +$10 into the DPB
        ADD HL,DE
        LD A,(HL)               ; geometry sanity byte 0
        OR A
        JP NZ,TPA_START_8       ; unexpected -> "Disk I/O error"
        INC HL
        LD A,(HL)
        AND $F0                 ; geometry sanity byte 1 (high nibble must be 0)
        OR A
        JP NZ,TPA_START_8       ; unexpected -> "Disk I/O error"
        LD C,$16                ; fn $16 make file (create "cp/m    sys")
        LD DE,$0355
        CALL BDOS_VEC
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
        LD C,$10                ; fn $10 close file -> commit directory entry
        LD DE,$0355
        CALL BDOS_VEC
        POP BC                  ; restore drive (C = 0-based)

; ---------------------------------------------------------------------------
; 4) Build the drive-letter glyphs used in the on-screen messages, then print
;    banner + "Insert 16 sector disk into drive Z:  Press RETURN to begin".
;    Wait for RETURN (SUB_0201 = poll console fn $06 until a key).
; ---------------------------------------------------------------------------
        LD A,C
        AND $0E
        ADD A,A
        ADD A,A
        ADD A,A
        CPL
        ADD A,$61
        LD (DRV_NAME),A         ; F3E6 = drive glyph for runtime messages
        LD A,C
        ADD A,$41               ; 'A'+drive -> letter
        LD ($0284),A            ; patch the "drive Z:" letter in the prompt
        LD DE,$0212             ; banner+prompt string
        CALL PRINT_STR
        CALL WAIT_KEY           ; wait for RETURN

; ---------------------------------------------------------------------------
; 5) WRITE THE EMBEDDED SYSTEM TO THE SYSTEM TRACKS  (the actual install).
;    Set up the raw-write bridge:  sector-count=2, track=$14 (20), source page
;    starting at $0E (the $0E00 payload page = start of CCP/BDOS/BIOS image in
;    this loaded .COM), and loop B=$30 (48) pages. Each pass:
;      - SUB_01F9: RPC write of one unit ($F3D0 <- $0E03 opcode; A=page byte
;        written thru ($F3DE)) -> 6502 RWTS lays the page onto the disk.
;      - read RPC_STAT ($F3EA): 0 = OK; $10 = write protected; other = I/O error
;      - advance source pointer (H = page hi), tick RW_TRACK on page wrap.
;    On any error, print the matching message and bail to the reboot prompt.
; ---------------------------------------------------------------------------
        LD A,$02
        LD (RW_SECCNT),A        ; F3EB = 2 sectors per RPC unit
        LD A,$14
        LD (RW_TRACK),A         ; F3E9 = start at track $14 (20) = system tracks
        LD HL,WBOOT_VEC         ; HL = $0000 (source pointer; really page in H)
        LD B,$30                ; 48 pages of system image to write
TPA_START_3:
        LD (RW_SECTOR),HL       ; F3E0 = current sector/source word
        PUSH BC
        PUSH HL
        LD HL,$0E03             ; RPC opcode/parm: page $0E, function $03 (write)
        CALL RPC_WRITE          ; do the raw write via 6502
        LD A,(RPC_STAT)         ; F3EA: 6502 status
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
        LD HL,RW_TRACK
        INC (HL)                ; advance to next track
        POP HL
        INC H                   ; next source page
        LD A,H
        SUB $10                 ; wrapped past $10xx ?
        JP NZ,TPA_START_6
        INC L                   ; carry into source-bank low byte
        LD H,A
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
; SUB_01F9 / RPC_WRITE -- issue one 6502 RPC: store parm word to RPC_PARM,
; then write opcode byte A through the live trampoline pointer (RPC_TRAMP),
; which lands on the 6502 RWTS bridge. Returns when the 6502 has serviced it.
; ---------------------------------------------------------------------------
RPC_WRITE:
SUB_01F9:
        LD (RPC_PARM),HL        ; F3D0 = parm word
        LD HL,(RPC_TRAMP)       ; HL = trampoline ptr
        LD (HL),A               ; write opcode -> triggers 6502 (e.g. $E700)
        RET

; ---------------------------------------------------------------------------
; WAIT_KEY -- BDOS fn $06 direct console input, polled (E=$FF), until a key.
; ---------------------------------------------------------------------------
WAIT_KEY:
SUB_0201:
        LD C,$06
        LD E,$FF                ; direct console input: poll keyboard
        CALL BDOS_VEC
        OR A
        JP Z,SUB_0201           ; loop until a non-zero key
        RET

; ---------------------------------------------------------------------------
; PRINT_STR -- BDOS fn $09 print '$'-terminated string at DE.
; ---------------------------------------------------------------------------
PRINT_STR:
SUB_020D:
        LD C,$09
        JP BDOS_VEC

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
