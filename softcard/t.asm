    DEVICE NOSLOT64K
    INCLUDE "s.inc"
    INCLUDE "s.inc"          ; twice, to prove the guard holds
    ORG $0100
    LD BC,FCB.EX             ; 12
    LD BC,FCB.S2 - FCB.EX    ; 2  -- "step from EX to S2", as arithmetic
    LD DE,FCB.AL             ; 16
    LD BC,FCB.CR             ; 32
    ASSERT FCB.CR == 32
    SAVEBIN "o.bin", $0100, 12
