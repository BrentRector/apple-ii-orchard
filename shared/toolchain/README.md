# Toolchain (local-only)

Native assemblers + linkers used by the disassembly round-trip pipeline. **Not committed** — `.gitignore` excludes the binaries; reinstall with the steps below.

## Tools

| Binary | Path | Source |
|---|---|---|
| `ca65`, `ld65` (and the rest of cc65) | `cc65/bin/` | https://sourceforge.net/projects/cc65/files/cc65-snapshot-win32.zip |
| `sjasmplus` | `sjasmplus/sjasmplus-1.23.0.win/sjasmplus.exe` | https://github.com/z00m128/sjasmplus/releases |

Tested versions: **ca65 V2.19** (Git d20d99b), **sjasmplus v1.23.0**.

## Reinstall

```sh
cd shared/toolchain/
curl -sL -o cc65.zip "https://sourceforge.net/projects/cc65/files/cc65-snapshot-win32.zip/download"
curl -sL -o sjasmplus.zip "https://github.com/z00m128/sjasmplus/releases/download/v1.23.0/sjasmplus-1.23.0.win.zip"
unzip -q cc65.zip -d cc65
unzip -q sjasmplus.zip -d sjasmplus
rm cc65.zip sjasmplus.zip
```

## Adding to PATH

Source `shared/toolchain/env.sh` (bash/MSYS) once per shell:

```sh
source shared/toolchain/env.sh
ca65 --version       # -> ca65 V2.19
sjasmplus --version  # -> SjASMPlus v1.23.0
```

## Smoke tests

`smoke_6502.s` + `smoke_6502.cfg` and `smoke_z80.asm` exercise both toolchains. From the `shared/toolchain/` directory:

```sh
ca65 smoke_6502.s -o smoke_6502.o
ld65 -C smoke_6502.cfg -o smoke_6502.bin smoke_6502.o
xxd smoke_6502.bin   # expect: a942 8d00 0260

sjasmplus smoke_z80.asm
xxd smoke_z80.bin    # expect: 3e42 3200 02c9
```
