; ca65 smoke test: 6 bytes at $0100
.segment "CODE"
    lda #$42
    sta $0200
    rts
