# CP/M 2.23 Disk-Sector Map

This is a comprehensive map of every physical sector in the 140 KB CP/M 2.23
disk image (`CPMV233.DSK`). For each sector, the table shows the first 8
bytes (a quick signature), what role the sector plays in the boot sequence,
and where the bytes end up in Apple memory after the loader runs.

**Format**: `track:sector` is a physical (T,S) coordinate. The .DSK file
stores sectors in DOS 3.3 logical order, so the file offset for physical
sector `(T,S)` is `(T*16 + DOS33_INTERLEAVE[S]) * 256`.

| Trk:Sec | First 8 bytes | Role | Final Apple address |
|---------|---------------|------|---------------------|
| ` 0:$0` | `01 A5 27 C9 09 D0 13 8A` | **Boot stub** (sector 0). Loaded by Disk II P6 PROM. | Apple `$0800-$08FF` |
| ` 0:$1` | `00 8D 01 10 A9 FA 8D 02` | Boot stub iteration 8 (CP/M skew). Stage-2 loader. | Apple `$1100-$11FF` |
| ` 0:$2` | `38 86 27 8E 78 06 BD 8D` | Boot stub iteration 1 (CP/M skew). 6502 disk routines area. | Apple `$0A00-$0AFF` |
| ` 0:$3` | `00 00 00 00 00 00 00 00` (zeros) | Boot stub iteration 9 (CP/M skew). Stage-2 loader. | Apple `$1200-$12FF` |
| ` 0:$4` | `5C 38 60 A0 FC 84 26 C8` | Boot stub iteration 2 (CP/M skew). 6502 disk routines area. | Apple `$0B00-$0BFF` |
| ` 0:$5` | `00 00 00 00 00 00 00 00` | Boot stub iteration 10 (CP/M skew). Stage-2 loader. | Apple `$1300-$13FF` |
| ` 0:$6` | `E6 03 A9 0B 8D E1 03 A9` | Boot stub iteration 3 (CP/M skew). 6502 disk routines area. | Apple `$0C00-$0CFF` |
| ` 0:$7` | `C3 0C 96 C3 08 96 7F 00` | Not loaded by boot stub. Tail of stage-2 area. | (not loaded) |
| ` 0:$8` | `1F CB 1D ED 5B E1 FE 01` | Boot stub iteration 4 (CP/M skew). 6502 disk routines area. | Apple `$0D00-$0DFF` |
| ` 0:$9` | `87 87 87 21 A8 9B B6 32` | Not loaded by boot stub. Tail of stage-2 area. | (not loaded) |
| ` 0:$A` | `3C 3D 3E 3F AD 83 C0 08` | Boot stub iteration 5 (CP/M skew). 6502 disk routines area. | Apple `$0E00-$0EFF` |
| ` 0:$B` | `C3 31 96 1A B7 C8 FE 20` | **LOAD_CPM call 1, sector 0**. CCP/BDOS staging starts here. | Apple `$8000-$80FF` (then via PREP_HANDOFF #3 -> `$A300-$A3FF`) |
| ` 0:$C` | `68 CE F8 04 D0 E5 F0 CA` | Boot stub iteration 6 (CP/M skew). 6502 disk routines area. | Apple `$0F00-$0FFF` |
| ` 0:$D` | `79 C9 23 10 FD 0C 18 E2` | LOAD_CPM call 1, sector 3. CCP/BDOS staging. | Apple `$8200-$82FF` -> `$A500` after PREP_HANDOFF #3 |
| ` 0:$E` | `AD 81 C0 AD 81 C0 8A 4A` | Boot stub iteration 7 (CP/M skew). 6502 disk routines area. | Apple `$1000-$10FF` |
| ` 0:$F` | `A8 9B BE C8 C3 B6 93 3A` | LOAD_CPM call 1, sector 5. CCP/BDOS staging. | Apple `$8400-$84FF` -> `$A700` after PREP_HANDOFF #3 |
| ` 1:$0` | `AA 9B 36 FF 21 AA 9B 7E` | LOAD_CPM call 1, sector 6. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8500-$85FF` -> `$A800` |
| ` 1:$1` | `0F A0 79 95 78 9C DA 0F` | LOAD_CPM call 1, sector 7. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8600-$86FF` -> `$A900` |
| ` 1:$2` | `C3 38 9A 46 69 6C 65 20` | LOAD_CPM call 1, sector 8. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8700-$87FF` -> `$AA00` |
| ` 1:$3` | `C2 FD A0 C9 0C 0D C8 29` | LOAD_CPM call 1, sector 9. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8800-$88FF` -> `$AB00` |
| ` 1:$4` | `32 80 00 CD 99 93 CD AD` | LOAD_CPM call 1, sector 10. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8900-$89FF` -> `$AC00` |
| ` 1:$5` | `FF 22 EA A9 C9 2A C8 A9` | LOAD_CPM call 1, sector 11. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8A00-$8AFF` -> `$AD00` |
| ` 1:$6` | `2B 7E B7 20 D2 C9 11 FF` | LOAD_CPM call 1, sector 12. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8B00-$8BFF` -> `$AE00` |
| ` 1:$7` | `A2 3A D4 A9 C3 01 9F C5` | LOAD_CPM call 1, sector 13. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8C00-$8CFF` -> `$AF00` |
| ` 1:$8` | `BD 16 00 01 4D 40 C3 11` | LOAD_CPM call 1, sector 14. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8D00-$8DFF` -> `$B000` |
| ` 1:$9` | `20 D5 06 00 2A 43 9F 09` | LOAD_CPM call 1, sector 15. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8E00-$8EFF` -> `$B100` |
| ` 1:$A` | `00 B7 C0 C3 09 FA CD FB` | LOAD_CPM call 1, sector 16. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$8F00-$8FFF` -> `$B200` |
| ` 1:$B` | `C2 CD A4 01 EC FF 09 EB` | LOAD_CPM call 1, sector 17. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$9000-$90FF` -> `$B300` |
| ` 1:$C` | `C1 9E FE 08 C2 16 9E 78` | LOAD_CPM call 1, sector 18. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$9100-$91FF` -> `$B400` |
| ` 1:$D` | `32 D5 A9 3E 00 32 D3 A9` | LOAD_CPM call 1, sector 19. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$9200-$92FF` -> `$B500` |
| ` 1:$E` | `9D 32 45 9F C9 3E 01 C3` | LOAD_CPM call 1, sector 20. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$9300-$93FF` -> `$B600` |
| ` 1:$F` | `C3 D2 A0 AF 32 D5 A9 C5` | LOAD_CPM call 1, sector 21. CCP/BDOS or BIOS-first-half staging. (CCP+BDOS area) | Apple `$9400-$94FF` -> `$B700` |
| ` 2:$0` | `A8 73 2B 70 2B 71 CD 2D` | LOAD_CPM call 1, sector 22. End of CCP/BDOS staging. | Apple `$9500-$95FF` -> `$B800` |
| ` 2:$1` | `FB AF 32 04 00 3A BB F3` | LOAD_CPM call 1, sector 23. End of CCP/BDOS staging. | Apple `$9600-$96FF` -> `$B900` |
| ` 2:$2` | `A9 C3 29 A9 3A 42 9F C3` | LOAD_CPM call 1, sector 24. Z-80 callbacks + BIOS first 1 KB. | Apple `$9700-$97FF` -> `$0A00` |
| ` 2:$3` | `FF FF 00 00 FF FF 00 00` | LOAD_CPM call 1, sector 25. Z-80 callbacks + BIOS first 1 KB. | Apple `$9800-$98FF` -> `$0B00` |
| ` 2:$4` | `C3 D1 FE C3 B8 FA C3 10` | LOAD_CPM call 1, sector 26. Z-80 callbacks + BIOS first 1 KB. | Apple `$9900-$99FF` -> `$0C00` |
| ` 2:$5` | `FF FF 00 00 FF FF 00 00` | LOAD_CPM call 1, sector 27. Z-80 callbacks + BIOS first 1 KB. | Apple `$9A00-$9AFF` -> `$0D00` |
| ` 2:$6` | `00 CD F9 FB 3E 01 32 4E` | LOAD_CPM call 1, sector 28. Z-80 callbacks + BIOS first 1 KB. | Apple `$9B00-$9BFF` -> `$0E00` |
| ` 2:$7` | `FF FF 00 00 FF FF 00 00` | LOAD_CPM call 1, sector 29. Z-80 callbacks + BIOS first 1 KB. | Apple `$9C00-$9CFF` -> `$0F00` |
| ` 2:$8` | `00 00 00 00 00 00 00 00` | **Empty (zeros).** Originally would have been BIOS second half — but is runtime-generated, so disk has zeros. | (if loaded would be BIOS `$FEB8-$FFB7` — but isn't) |
| ` 2:$9` | `FF FF 00 00 FF FF 00 00` | **Empty (zeros).** Originally would have been BIOS second half — but is runtime-generated, so disk has zeros. | (if loaded would be BIOS `$FFB8-$100B7` — but isn't) |
| ` 2:$A` | `04 21 DD F3 AE 32 45 F0` | **Empty (zeros).** Originally would have been BIOS second half — but is runtime-generated, so disk has zeros. | (if loaded would be BIOS `$100B8-$101B7` — but isn't) |
| ` 2:$B` | `FF FF 00 00 FF FF 00 00` | **Empty (zeros).** Originally would have been BIOS second half — but is runtime-generated, so disk has zeros. | (if loaded would be BIOS `$101B8-$102B7` — but isn't) |
| ` 2:$C` | `4C E9 BB 4C 04 BE A9 01` | Not loaded. May be loaded by second LOAD_CPM call (post-handoff). | (deferred / not loaded by stage-2) |
| ` 2:$D` | `FF FF 00 00 FF FF 00 00` | Not loaded. May be loaded by second LOAD_CPM call (post-handoff). | (deferred / not loaded by stage-2) |
| ` 2:$E` | `22 D6 03 38 1E 20 09 21` | Not loaded. May be loaded by second LOAD_CPM call (post-handoff). | (deferred / not loaded by stage-2) |
| ` 2:$F` | `FF FF 00 00 FF FF 00 00` | Not loaded. May be loaded by second LOAD_CPM call (post-handoff). | (deferred / not loaded by stage-2) |
| ` 3:$0` | `00 43 41 54 20 20 20 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$1` | `DB 00 CD 93 00 F6 06 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$2` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$3` | `00 53 54 41 54 20 20 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$4` | `FF 97 62 01 00 3A 8F EA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$5` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$6` | `00 44 55 4D 50 20 20 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$7` | `67 75 72 65 20 45 78 74` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$8` | `ED 73 D3 03 31 FB 03 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$9` | `1F 63 70 2F 6D 20 20 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$A` | `20 51 EF 15 20 DE 20 0E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$B` | `0C 00 09 5E CB 23 CB 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$C` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$D` | `52 F0 4E 43 F4 13 3A 82` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$E` | `E5 D5 C5 CD FE 01 23 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 3:$F` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$0` | `49 F0 11 20 DD 20 20 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$1` | `13 3A 8B 20 FF 96 28 4A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$2` | `A3 6C 4F 00 91 20 DF 16` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$3` | `20 19 3A 91 20 46 55 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$4` | `00 A9 72 6E 00 8B 20 50` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$5` | `3A C8 20 0F 14 3A 91 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$6` | `66 73 74 20 3A 20 20 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$7` | `15 29 3A 97 20 48 42 59` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$8` | `52 44 00 9B 6E 59 00 89` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$9` | `22 52 55 42 22 20 DE 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$A` | `42 24 F0 22 52 22 20 DE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$B` | `6C 65 20 4E 61 6D 65 3F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$C` | `00 00 F9 6A 40 00 91 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$D` | `75 81 00 8B 20 E1 11 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$E` | `20 0E 09 00 00 C1 70 65` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 4:$F` | `00 B3 6B 46 00 8D 20 0E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$0` | `20 49 2F 4F 20 65 72 72` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$1` | `87 87 87 21 A8 DB B6 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$2` | `3A 97 20 0C DD F3 2C 0F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$3` | `3A 8B 20 4A EF 0F 60 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$4` | `01 10 10 C3 3D 01 43 4F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$5` | `38 2C 33 33 2C 31 38 34` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$6` | `22 52 55 42 22 20 DE 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$7` | `C3 83 06 00 00 00 C3 4F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$8` | `30 2C 32 33 33 2C 32 34` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$9` | `82 20 49 F0 11 20 DD 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$A` | `C2 18 05 0D 79 C1 C9 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$B` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$C` | `2C 4A 3A 83 00 AE 7A A4` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$D` | `DB 00 CD 93 00 F6 06 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$E` | `C3 0C D6 C3 08 D6 7F 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 5:$F` | `22 20 20 20 22 00 BE 7B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$0` | `C3 15 00 7A E6 38 0F 0F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$1` | `F1 C9 43 5A 4D 45 49 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$2` | `1A 77 3A A5 06 12 C1 F1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$3` | `4F 3D 21 39 06 09 CD F3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$4` | `47 0F 5B 0F 7A 0F 7A 0F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$5` | `7A 0A 11 80 00 0E 80 1A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$6` | `4F 21 62 05 09 CD F3 02` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$7` | `CD DA 1B 0E 01 CD C9 1B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$8` | `00 00 CA 12 0B 3D C2 DF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$9` | `41 20 58 52 41 20 4F 52` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$A` | `81 24 49 24 92 49 12 44` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$B` | `02 CD A8 06 C1 D1 E1 C9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$C` | `00 E5 C3 E1 09 31 03 10` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$D` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$E` | `0C CD B9 0C FE 0D C2 DF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 6:$F` | `08 23 19 D2 09 08 21 FF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$0` | `3E 77 32 0B 00 CD 60 02` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$1` | `01 27 1E CD 18 0A 21 27` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$2` | `23 5E 23 EB 22 DF 0A EB` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$3` | `BD A0 9A 84 3C BC 8C C0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$4` | `31 FD 04 3A 80 00 32 63` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$5` | `29 29 29 29 11 80 00 19` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$6` | `1A B9 D2 06 13 C9 CD 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$7` | `CD 27 04 7C B5 CA 1E 03` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$8` | `44 72 69 76 65 20 46 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$9` | `D5 13 3A A8 1E FE 5B C2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$A` | `EB 03 01 64 05 CD 30 04` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$B` | `6B 20 6F 72 20 64 69 72` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$C` | `31 41 0A 21 E5 04 CD A2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$D` | `05 3C 21 05 05 BE 38 09` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$E` | `B1 F5 3A BF 1F D6 15 D6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 7:$F` | `0A EB 2A DF 0A 7C 12 13` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$0` | `0E 20 1E 1F CD 05 00 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$1` | `00 8D 01 10 A9 FA 8D 02` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$2` | `03 8C E0 03 C8 8C E4 03` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$3` | `C9 0E 06 1E FF CD 05 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$4` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$5` | `F5 FE B7 C4 3B B3 AF 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$6` | `6B 20 77 72 69 74 65 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$7` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$8` | `30 31 32 F0 F1 33 34 35` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$9` | `01 A5 27 C9 09 D0 13 8A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$A` | `C3 0C D6 C3 08 D6 7F 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$B` | `A4 2E CC 78 04 F0 19 AD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$C` | `38 86 27 8E 78 06 BD 8D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$D` | `87 87 87 21 A8 DB B6 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$E` | `AD 81 C0 AD 81 C0 8A 4A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 8:$F` | `5C 38 60 A0 FC 84 26 C8` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$0` | `C3 31 D6 1A B7 C8 FE 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$1` | `FE 0D 28 0E FE 0A 28 0A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$2` | `2B 7E B7 20 D2 C9 11 FF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$3` | `79 C9 23 10 FD 0C 18 E2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$4` | `B7 1F 0D 20 FB 47 3E 08` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$5` | `BD 16 00 01 4D 40 C3 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$6` | `A8 DB BE C8 C3 B6 D3 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$7` | `C3 18 DF CD 8D B7 C8 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$8` | `BC DD C1 CD BC DD 21 DC` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$9` | `AA DB 36 FF 21 AA DB 7E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$A` | `E6 1F 47 2A CC BF 09 7E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$B` | `B7 28 D4 7E 05 2B 18 76` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$C` | `C3 38 DA 46 69 6C 65 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$D` | `19 78 FE 0D 28 14 FE 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$E` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| ` 9:$F` | `32 80 00 CD 99 D3 CD AD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$0` | `D5 ED B0 CD F1 B7 D1 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$1` | `FB AF 32 04 00 3A BB F3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$2` | `C3 EA FE C3 B8 FA C3 10` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$3` | `BF A0 21 DF BF A6 28 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$4` | `C3 CE 04 C9 00 00 C9 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$5` | `00 CD F9 FB 3E 01 32 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$6` | `C6 BF 57 77 23 14 F2 C3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$7` | `20 20 20 43 4F 50 59 52` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$8` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$9` | `BC C9 0E 00 CD 30 BD CC` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$A` | `41 42 4F 52 54 45 44 24` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$B` | `04 21 DD F3 AE 32 45 F0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$C` | `CD E1 B7 C3 A7 BA CD 74` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$D` | `24 44 45 53 54 49 4E 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$E` | `4C 09 0E 8D 8B C0 4C 13` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `10:$F` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$0` | `32 C0 1E 11 00 00 0E 19` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$1` | `08 10 C3 08 10 C3 08 10` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$2` | `01 CA 1F 09 22 7D 1F 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$3` | `B2 1A C3 DB 07 3A A9 1E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$4` | `11 2A 8F 1F 4D CD 15 0F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$5` | `21 DD 0C 09 09 5E 23 56` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$6` | `05 96 9F C1 48 A1 C1 48` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$7` | `3E 0D C9 2A 4E 1F 26 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$8` | `0C C4 0C CF 0C 3A 81 1F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$9` | `FA CD A6 1D 3E FA CD A6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$A` | `1A B9 D2 06 13 C9 CD 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$B` | `FE 01 C2 12 0E 0E 3A CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$C` | `0E 17 CD 05 00 C9 21 C3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$D` | `D5 13 3A A8 1E FE 5B C2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$E` | `9F 2F C1 48 A1 1F D2 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `11:$F` | `CD 94 08 3A AE 1E FE FF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$0` | `C3 B7 15 3A A8 1E D6 53` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$1` | `20 53 79 73 74 65 6D 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$2` | `B1 F5 3A BF 1F D6 15 D6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$3` | `72 2B 73 2B 70 2B 71 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$4` | `C3 33 04 20 20 20 43 6F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$5` | `01 27 1E CD 18 0A 21 27` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$6` | `12 17 CD 2D 17 3A AF 1F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$7` | `35 35 33 36 3A 20 00 31` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$8` | `1F 44 4D 1E 21 CD 18 0A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$9` | `BB 1F BE DA 1C 18 3A BB` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$A` | `74 61 74 75 73 20 20 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$B` | `74 65 6D 20 6E 6F 74 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$C` | `C0 03 01 0F 1E CD FD 15` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$D` | `20 44 69 73 6B 20 41 73` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$E` | `64 20 69 6E 20 64 72 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `12:$F` | `08 C9 0E 07 21 FF 1D CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$0` | `0E 0E CD 4C 14 C9 21 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$1` | `C7 29 FE 02 C2 1C 10 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$2` | `15 3A A9 15 E6 FE 1F 1F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$3` | `15 70 2B 71 21 60 15 36` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$4` | `C2 29 2A C4 29 01 BC 15` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$5` | `19 0A 3D 32 A8 15 FE FF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$6` | `C9 21 67 15 72 2B 73 2B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$7` | `01 BA 21 29 09 4E 23 46` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$8` | `04 CD A0 04 C9 CD 51 05` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$9` | `07 11 01 00 2A 73 15 19` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$A` | `09 77 C3 1F 13 01 0A 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$B` | `6A 00 36 3F 01 5C 00 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$C` | `15 3E 00 CD D3 14 B5 D6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$D` | `13 C9 CD 39 06 CD 39 06` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$E` | `29 36 00 3E 0B 21 C6 29` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `13:$F` | `CD CC 05 CD C3 08 0E 01` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$0` | `C9 1A 1A 1A 1A 1A 1A 1A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$1` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$2` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$3` | `C9 D4 A0 8D A0 C4 C5 D9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$4` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$5` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$6` | `D4 D9 A0 D2 C5 D4 D2 D9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$7` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$8` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$9` | `C3 D0 D9 A0 C3 D5 D2 D4` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$A` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$B` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$C` | `31 00 02 2A 06 00 22 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$D` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$E` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `14:$F` | `C3 E0 0C C3 A1 0D C3 CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$0` | `FF C0 21 29 10 CD BC 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$1` | `18 1A 23 BE C8 13 04 0D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$2` | `12 C9 3A 0A 11 FE 0D CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$3` | `13 23 0D C2 FE 0D 05 C2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$4` | `E9 89 19 92 19 99 19 9F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$5` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$6` | `3A 84 01 21 0C 01 B7 CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$7` | `6F C3 93 18 3A 85 01 FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$8` | `7B 95 7A 9C EB D2 41 15` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$9` | `20 46 49 4C 45 20 52 45` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$A` | `C3 08 1B CD B0 18 3E FF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$B` | `43 43 4D 50 43 50 49 44` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$C` | `C3 40 13 C3 32 11 C3 C0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$D` | `13 FE 06 C2 0C 1C CD E3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$E` | `3F 1D B8 1A FE 13 27 15` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `15:$F` | `3E 01 C3 39 12 CD 71 11` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$0` | `06 11 3A 85 01 FE 04 C2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$1` | `28 0C 70 2B 71 2A 27 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$2` | `32 25 01 B7 C2 09 01 0E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$3` | `1E 88 1E 8F 1E 9E 1E A5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$4` | `36 1A CD 59 04 FE 3A CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$5` | `BC C9 0E 00 CD 30 BD CC` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$6` | `08 C4 BD 20 79 E6 30 B0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$7` | `71 01 3D 0D 11 16 0C CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$8` | `C3 40 02 20 43 4F 50 59` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$9` | `2A EB 20 22 D6 01 CD 49` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$A` | `41 0D D6 30 4F 3E 09 B9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$B` | `54 20 4F 50 45 4E 20 53` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$C` | `C3 05 01 00 1A 3A 03 01` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$D` | `43 54 45 52 20 52 45 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$E` | `CD D0 02 C3 0F 03 3A 0E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `16:$F` | `C3 0D 00 05 00 C9 C3 5D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$0` | `11 4C 05 CD 34 04 0E 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$1` | `08 78 20 07 1C 28 60 A0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$2` | `64 20 69 6E 20 64 72 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$3` | `7A 02 3A 22 05 B7 28 22` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$4` | `51 A5 41 0A 20 99 1C 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$5` | `20 53 79 73 74 65 6D 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$6` | `11 BE 07 CD 61 04 3A 26` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$7` | `A5 2F 20 3C 1E A5 41 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$8` | `4C 00 1C 38 86 27 8E 78` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$9` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$A` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$B` | `5C 38 60 A0 FC 84 26 C8` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$C` | `C0 3A 1D 05 CD 8E 04 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$D` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$E` | `96 97 9A 9B 9D 9E 9F A6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `17:$F` | `74 65 6D 20 6E 6F 74 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$0` | `2A DE F3 22 AB 04 3A 07` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$1` | `0E 36 00 CD AD 04 3A 7D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$2` | `4F 53 20 64 69 73 6B 24` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$3` | `CD B9 03 FE 3D 28 03 C3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$4` | `05 CD 2D 02 21 DB 05 36` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$5` | `16 4C 4F D4 D0 44 CC 35` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$6` | `02 11 5C 00 0E 0F CD 05` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$7` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$8` | `C3 DF 01 20 63 6F 70 79` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$9` | `05 22 94 04 21 11 00 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$A` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$B` | `EB 0E 09 CD 8A 05 C9 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$C` | `5F 0E 02 CD 05 00 E1 D1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$D` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$E` | `CD A7 02 21 74 06 36 80` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `18:$F` | `20 64 69 73 6B 20 61 6E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$0` | `01 BC 01 C3 57 01 20 45` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$1` | `43 54 45 52 20 52 45 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$2` | `49 43 20 43 48 41 52 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$3` | `C3 0D 00 05 00 C9 C3 5D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$4` | `54 48 41 54 20 41 20 4A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$5` | `42 52 43 09 45 51 55 09` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$6` | `32 25 01 B7 C2 09 01 0E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$7` | `52 4B 46 0D 0A 09 43 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$8` | `45 41 20 28 52 45 53 54` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$9` | `01 D5 CD D6 48 E1 CD 60` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$A` | `48 41 52 0D 0A 09 52 45` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$B` | `4A 4D 50 09 46 49 4E 49` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$C` | `3B 09 46 49 4C 45 20 44` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$D` | `0D 0A 09 52 52 43 0D 0A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$E` | `20 4C 49 4E 45 20 50 4F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `19:$F` | `54 59 50 45 20 46 55 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$0` | `0A 3B 09 52 45 41 44 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$1` | `01 1E 46 C3 9E 0C 3A 04` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$2` | `C5 50 58 28 2A FE 2C 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$3` | `20 49 4E 44 45 58 20 54` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$4` | `3A 80 00 B7 11 C0 01 CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$5` | `65 20 00 FE 0D C2 9E 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$6` | `53 45 54 55 50 3A 09 3B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$7` | `00 FA 09 C3 8B 13 0E 2C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$8` | `21 00 00 39 22 15 02 31` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$9` | `56 49 09 43 2C 52 45 41` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$A` | `17 9F 67 C3 55 2C CD E3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$B` | `4C 45 20 50 52 45 53 45` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$C` | `0D 0A 3B 09 53 54 41 43` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$D` | `2C CD 6F 2B 21 56 38 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$E` | `17 9F 6F 67 C3 55 2C 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `20:$F` | `FE 30 D8 FE 3A 3F C9 2B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$0` | `C3 51 5E F4 2B 55 2C 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$1` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$2` | `72 72 6F 72 00 47 72 61` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$3` | `00 00 00 00 F8 52 FB 52` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$4` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$5` | `65 00 54 6F 6F 20 6D 61` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$6` | `82 49 45 4C C4 B9 49 4C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$7` | `F9 43 21 21 05 7B FE 47` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$8` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$9` | `16 4C 4F D4 D0 44 CC 35` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$A` | `37 D1 3A C3 0C B7 20 06` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$B` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$C` | `2C 6C 2C 8E 2E 87 2E BC` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$D` | `01 D5 CD D6 48 E1 CD 60` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$E` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `21:$F` | `74 20 6F 66 20 73 74 72` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$0` | `18 A9 2B F5 01 35 11 C5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$1` | `18 E7 E5 EB CD 8C 2C E1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$2` | `7D 0B EB 28 06 CD FB 14` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$3` | `CD 4F 12 D5 C5 CD F6 1C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$4` | `4F 28 2F FE 48 20 2A 06` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$5` | `28 16 B8 C3 12 18 3A 60` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$6` | `E5 2A 71 0B E3 E5 2A 67` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$7` | `CA 14 2E 01 4F 1E C5 FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$8` | `D2 18 CD BE 48 2A 7F 0B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$9` | `20 05 2A 3A 0B 18 DE F5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$A` | `0B F5 D5 CD 90 1A 22 8C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$B` | `15 53 CD E3 1D F5 20 2B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$C` | `0E CA 06 15 FE 0D EB 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$D` | `03 03 03 03 21 B4 0B CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$E` | `23 21 D0 0C 4E 23 46 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `22:$F` | `0B EB D5 3A 37 0B F5 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$0` | `91 33 E1 7E FE 09 28 05` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$1` | `2C CD 6F 2B 21 56 38 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$2` | `17 9F 6F 67 C3 55 2C 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$3` | `FE 30 D8 FE 3A 3F C9 2B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$4` | `0D CD 49 2C 21 D7 0C 7E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$5` | `01 1E 46 C3 9E 0C 3A 04` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$6` | `C5 50 58 28 2A FE 2C 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$7` | `2C C1 D1 C3 90 29 78 B7` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$8` | `18 F5 C6 09 6F 7A B3 B0` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$9` | `65 20 00 FE 0D C2 9E 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$A` | `CF 0C 0E 08 56 77 7A 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$B` | `2B 7E 32 24 2A 2B 7E 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$C` | `CD E4 13 79 FE 1A 7E 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$D` | `00 00 00 00 20 84 3A D7` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$E` | `17 9F 67 C3 55 2C CD E3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `23:$F` | `18 BF 22 D0 F3 32 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$0` | `1B 2B 05 20 F8 C9 CD 6F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$1` | `08 7E FE 26 30 17 11 2B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$2` | `DF F1 CD 12 32 F5 CD 0D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$3` | `E1 C9 C8 F5 CD E3 1D F5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$4` | `AC 3E EB 13 E1 C9 13 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$5` | `C1 38 D3 13 13 3E 04 18` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$6` | `D1 E1 17 21 D0 05 22 6B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$7` | `D2 3A 37 0B 77 23 5F 16` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$8` | `C3 D4 38 12 E1 C9 21 F4` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$9` | `0C FE 30 28 EE FE 2C 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$A` | `C5 CD 24 21 E1 E5 7C A5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$B` | `E1 18 E9 52 C7 4F 80 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$C` | `51 37 36 30 CC 3D 2B CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$D` | `B7 C8 CD DA 43 FE 20 30` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$E` | `F4 2A 3A D6 0C B7 F5 F2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `24:$F` | `35 5F 79 B7 C4 10 32 83` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$0` | `18 1C 58 E5 0E 02 7E 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$1` | `30 0A E1 E5 CD 44 48 E1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$2` | `28 36 CD E7 14 2B CD E4` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$3` | `0F 32 76 0B FE 3B 28 05` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$4` | `AF 32 61 08 79 FE 07 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$5` | `47 CD 37 4A 7E 23 4E 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$6` | `3E 0D CD EA 42 3E 0A CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$7` | `D1 C1 E1 C9 3E 01 C5 47` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$8` | `2A 46 0B 22 6B 0B 21 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$9` | `44 36 00 21 30 0A 3E 0D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$A` | `13 18 E8 CD A3 45 29 22` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$B` | `E5 86 11 0F 00 DA AC 0D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$C` | `0B 32 79 0B 77 23 77 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$D` | `28 48 78 F6 80 47 AF CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$E` | `C3 98 48 CD 4A 4B D1 D5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `25:$F` | `42 CD F9 43 F1 21 1A 0D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$0` | `03 20 04 CD 43 51 AF 5F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$1` | `2B CD E4 13 C2 92 0D E3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$2` | `59 13 21 27 00 09 C5 AF` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$3` | `C3 86 13 C3 CF 15 0E 02` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$4` | `21 AB 00 09 E5 7E 23 66` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$5` | `C9 CD FF 56 E1 C3 9A 18` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$6` | `F5 CD 37 4A F1 BE D2 EB` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$7` | `CE 00 67 1A 91 AE F5 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$8` | `0B CA 7C 0D FE 03 DA 7C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$9` | `CD F7 53 3A 93 08 32 6E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$A` | `FE 05 28 02 06 50 78 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$B` | `D1 D5 13 CD 78 58 E1 F1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$C` | `5E 3E FF CD A0 57 2A 92` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$D` | `4D E1 3D 20 EB 23 22 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$E` | `91 42 79 FE 04 20 0A 7E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `26:$F` | `79 CD D6 48 E1 C1 E3 D5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$0` | `C3 00 10 76 4F D7 4F 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$1` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$2` | `72 72 6F 72 00 46 49 45` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$3` | `00 00 00 00 7A 76 7D 76` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$4` | `39 7E 23 FE AF 20 06 01` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$5` | `76 65 20 73 65 6C 65 63` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$6` | `82 49 45 4C C4 B9 49 4C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$7` | `7E FE 3F 20 06 E1 21 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$8` | `00 00 00 00 00 00 00 00` (zeros) | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$9` | `16 4C 4F D4 D0 44 CC 35` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$A` | `23 73 23 72 23 11 CF 08` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$B` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$C` | `50 EE 4F 10 52 09 52 3E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$D` | `21 90 64 11 82 84 01 83` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$E` | `00 00 00 00 00 00 00 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `27:$F` | `74 20 6F 66 20 73 74 72` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$0` | `C8 FE A8 C8 FE A6 C8 FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$1` | `50 C3 73 4D CD C9 33 CA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$2` | `B5 CA D0 34 22 5A 0B 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$3` | `F5 CD 34 32 F1 D6 3A 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$4` | `3C CD 41 6A EB 30 0A FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$5` | `FE FF 28 07 B8 D4 88 67` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$6` | `DD CD C8 3D CA 87 0D D2` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$7` | `6F 7C B2 C9 FE 50 20 06` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$8` | `21 0D 0A C3 B3 39 FE 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$9` | `1C 30 28 D6 F5 30 06 FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$A` | `F1 CD FF 3F 0E 04 CD 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$B` | `FE 22 28 0C 3A 53 0B B7` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$C` | `33 2B 11 00 00 CD C9 33` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$D` | `67 0C 2B 22 67 0C 7C B5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$E` | `C6 03 4B 47 C5 01 52 3B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `28:$F` | `3A 14 0B B8 78 28 06 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$0` | `CD 09 41 21 0E 0A CD 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$1` | `4F DC 63 4C 68 63 AF 47` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$2` | `32 3E E1 C9 CD A6 46 3C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$3` | `F5 CD 45 34 F1 01 0B 42` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$4` | `C1 E1 CD 9A 4E EB CD AA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$5` | `CD 25 69 28 CD 20 4B CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$6` | `42 4B D1 28 1D CD 25 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$7` | `35 E1 20 A4 C3 09 4C 3E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$8` | `C9 CD 91 4A 3A E5 47 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$9` | `EB 23 23 23 4E 23 46 3E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$A` | `BA 0C 11 C9 4E D5 11 B1` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$B` | `EB 3A E2 47 2A DF 47 85` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$C` | `FE B0 20 CD 10 CB C9 FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$D` | `FA 0B 50 CA 87 0D CD B5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$E` | `F1 E6 02 C0 78 FE 0C 28` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `29:$F` | `F0 C4 97 40 FE 02 30 63` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$0` | `AD 0C 7E 35 B7 23 28 FA` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$1` | `10 F3 5A 00 00 A0 72 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$2` | `CA 81 0D C3 72 0D F1 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$3` | `AF 06 98 C3 5B 4E D5 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$4` | `B4 0C FE 88 D2 1D 5D FE` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$5` | `EB C1 D1 C9 C5 06 00 23` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$6` | `F8 C9 7E 2F 77 21 AC 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$7` | `F6 4B 21 24 5E C3 C1 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$8` | `21 C2 0C 23 3A 69 0B 95` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$9` | `0C 3E 04 35 C8 3D C2 F5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$A` | `75 4D 21 A0 4B E5 21 02` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$B` | `04 FE 01 9F 57 81 4F 93` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$C` | `FE 51 E1 28 0B 3A 14 0B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$D` | `1A B8 CA 88 60 13 1A 26` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$E` | `C0 36 2C 23 0E 03 C9 D5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `30:$F` | `0B 56 18 DD CD 24 50 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$0` | `08 18 07 CD C9 34 AF 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$1` | `7E 0C B7 28 06 BA 28 03` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$2` | `11 0B B8 20 0A 3A 97 4B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$3` | `23 56 23 E3 F5 CD 1F 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$4` | `EB 2A 73 0B EB CD 1F 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$5` | `E1 C9 3A 34 08 B7 C8 F5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$6` | `23 28 43 FE 19 CA B0 63` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$7` | `7E B7 C9 01 32 3E C5 CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$8` | `23 23 F9 21 27 0B 22 25` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$9` | `23 7E 2B 77 23 18 F3 F5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$A` | `75 3A CD 35 50 CD 25 69` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$B` | `34 D1 E1 E3 D5 CD C9 4E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$C` | `57 1C 0E 00 05 28 48 7E` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$D` | `C9 CD C8 3D C2 FF 6F CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$E` | `2A 6A 0C CD 1F 69 C2 75` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `31:$F` | `2A B1 0C F1 3C CA 7B 65` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$0` | `21 0E 0A CD E0 34 EB 22` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$1` | `80 E1 77 2B 77 B7 D1 C9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$2` | `4F 7B FE 2C 79 C4 70 77` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$3` | `33 C3 6B 33 2A 71 0C 22` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$4` | `C9 01 7F 38 C5 CD 75 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$5` | `23 23 22 6F 0B 21 70 08` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$6` | `0C E1 2B CD C9 33 28 4D` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$7` | `CD D1 78 0E 19 CD 05 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$8` | `21 00 00 22 B6 81 7C EB` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$9` | `69 2C C3 79 73 2A 71 0B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$A` | `EB CD 25 7F 2A 40 08 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$B` | `CD 97 40 D5 7E FE 2C 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$C` | `2A 73 0B 44 4D 2A 6F 0B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$D` | `B6 81 E1 C1 E5 21 B2 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$E` | `16 29 AF 02 03 15 20 FB` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `32:$F` | `6F 7C 9A 67 11 FE FF 19` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$0` | `09 19 7E B7 D1 E1 C1 C9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$1` | `0D C2 28 08 3A 08 1D D6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$2` | `CD 0A 0C 2A 06 1D 4D CD` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$3` | `EB 22 D6 67 22 B2 67 22` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$4` | `CD FA 19 22 26 1D 21 20` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$5` | `29 04 CD B7 12 CD 58 14` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$6` | `CD C9 33 B7 20 F6 C3 53` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$7` | `19 EB 2B 73 23 72 21 04` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$8` | `10 1C 21 21 1D 36 00 C3` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$9` | `01 01 C3 BD 81 0D 0A 0A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$A` | `3A 66 1B 1F D2 08 0B C9` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$B` | `13 2D C2 FD 05 01 95 1A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$C` | `C3 C0 01 20 43 4F 50 59` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$D` | `2A 72 1B EB 0E 09 CD 05` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$E` | `D2 08 07 21 20 1D 36 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `33:$F` | `00 00 01 39 1B 11 6D 1A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$0` | `EB 0E 1A CD 05 00 C9 3A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$1` | `1D 36 01 CD DA 17 CD 46` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$2` | `11 2A 1D CD ED 19 B5 C6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$3` | `3D 1B CD 65 0C 21 65 1B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$4` | `2A 46 1D 4D CD D5 18 1F` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$5` | `0A C2 0D 14 E5 2A 10 1C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$6` | `1B 3A 1A 1C C9 2A 65 1B` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$7` | `13 1A 9C 67 C9 5F 16 00` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$8` | `C3 C4 14 C9 21 37 1D 71` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$9` | `01 CD 3A 0D CD 3B 10 2A` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$A` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$B` | `C2 13 C9 CD 65 11 32 21` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$C` | `17 1D 36 01 3A 16 1D C6` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$D` | `E5 E5 E5 E5 E5 E5 E5 E5` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$E` | `00 CD 24 16 3A 04 1D 32` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
| `34:$F` | `0E 2A CD CB 0B CD B8 0C` | CP/M filesystem area (after CP/M directory track). | (not loaded by boot — accessible via CP/M file ops once running) |
