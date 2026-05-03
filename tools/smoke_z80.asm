; sjasmplus smoke test: 6 bytes at $0100
    DEVICE NOSLOT64K
    ORG $0100
    LD A, $42
    LD ($0200), A
    RET
    SAVEBIN "smoke_z80.bin", $0100, 6
