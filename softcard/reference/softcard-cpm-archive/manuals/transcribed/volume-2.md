# Microsoft SoftCard - Volume 2

> **AI-reconstructed text.** Transcribed from the scanned manual `manuals/Microsoft_SoftCard_-_Volume_2.pdf` (md5 `0140e81f71d52469d5274c64a5fc5535`, 152 pages) by a vision model, with an adversarial verification pass on every table and code page. Convenience copy for search and reference. **The scanned PDF remains the authoritative source** - verify any exact byte, address, or opcode against it. Reconstructed 2026-06-17; spot-check items in [`README.md`](README.md).


<!-- ===== scan page 001 - type:cover ===== -->

# SOFTCARD

VOLUME II

<!-- ===== scan page 002 - type:blank ===== -->

<!-- ===== scan page 003 - type:cover ===== -->

# SoftCard&trade;

**A Peripheral for the Apple II&reg;
With CP/M&reg; and Microsoft BASIC on diskette.**

Produced by Microsoft

**Microsoft Consumer Products
400 108th Ave. NE, Suite 200
Bellevue, WA 98004**

<!-- ===== scan page 004 - type:blank ===== -->

<!-- ===== scan page 005 (printed i) - type:text ===== -->

# Copyright and Trademark Notices

The Microsoft SoftCard and all software and documentation in the SoftCard package exclusive of the CP/M operating system are copyrighted under United States Copyright laws by Microsoft. The CP/M operating system and CP/M documentation are copyrighted under United States Copyright laws by Digital Research.

It is against the law to copy any of the software in the SoftCard package on cassette tape, disk or any other medium for any purpose other than personal convenience.

It is against the law to give away or resell copies of any part of the Microsoft SoftCard package. Any unauthorized distribution of this product or any part thereof deprives the authors of their deserved royalties. Microsoft will take full legal recourse against violators.

If you have any questions on these copyrights, please contact:

> Microsoft Consumer Products
> 400 108th Ave. NE, Suite 200
> Bellevue, WA 98004

Copyright© Microsoft, 1980
All Rights Reserved
Printed in U.S.A.

™SoftCard is a trademark of Microsoft.

®Apple is a registered trademark of Apple Computer Inc.

®CP/M is a registered trademark of Digital Research, Inc.

®Z-80 is a registered trademark of Zilog, Inc.

<!-- ===== scan page 006 (printed ii) - type:text ===== -->

# TABLE OF CONTENTS

## INTRODUCTION

| | |
|---|---|
| SoftCard System Explained | I-1 |
| Designers and Manufacturer | I-3 |
| System Requirements | I-4 |
| SoftCard Terminology | I-5 |
| Digital Research License Information | I-7 |
| Microsoft Consumer Products Registration Information | I-10 |
| Warranty | I-10 |
| Service Information | I-11 |

## PART I: Installation and Operation

### Chapter 1: How to Install the SoftCard

| | |
|---|---|
| Apple Peripheral Cards: What Goes Where | 1-2 |
| Interface Cards Compatible with CP/M | 1-2 |
| Placement of Apple Disk Drives | 1-4 |
| Printer Interface Installation | 1-4 |
| General Purpose I/O Installation | 1-5 |
| Using an External Terminal Interface | 1-5 |
| Installation of the SoftCard | 1-5 |

### Chapter 2: Getting Started with Apple CP/M

| | |
|---|---|
| Bringing up Apple CP/M | 1-8 |
| How to copy your SoftCard Disk | 1-9 |
| Creating CP/M System Disks | 1-11 |
| Using Apple CP/M with the Apple Language Card | 1-13 |
| I/O Configuration | 1-13 |

### Chapter 3: An Introduction to Using Apple CP/M

| | |
|---|---|
| Typing at the Keyboard | 1-18 |
| Output Control | 1-19 |
| CP/M Warm Boot: Ctrl-C | 1-19 |
| Changing CP/M Disks | 1-19 |
| CP/M Command Structure | 1-20 |
| CP/M File Naming Conventions | 1-21 |

<!-- ===== scan page 007 (printed iii) - type:text ===== -->

| | |
|---|---|
| Some CP/M commands: DIR, ERA, REN, TYPE | 1-22 |
| CP/M Error Messages | 1-23 |
| Description of Programs Included on the SoftCard Disk | 1-26 |

## Chapter 4: Getting Started with Microsoft BASIC

| | |
|---|---|
| | 1-31 |

# PART II: Software and Hardware Details

## Chapter 1: Apple II CP/M Software Details

| | |
|---|---|
| Introduction | 2-4 |
| I/Hardware Conventions | 2-4 |
| 6502/Z-80 Address Translation | 2-5 |
| Apple II CP/M Memory Usage | 2-6 |
| Assembly Language Programming with the SoftCard | 2-7 |
| ASCII Character Codes | 2-7 |

## Chapter 2: Apple II CP/M I/O Configuration Block

| | |
|---|---|
| Introduction | 2-12 |
| Console Cursor Addressing/Screen Control | 2-12 |
| The Hardware/Software Screen Function Table | |
| Terminal Independent Screen Functions/Cursor Addressing | |
| Redefinition of Keyboard Characters | 2-17 |
| Support of Non-Standard Peripheral Devices | 2-17 |
| Calling of 6502 Subroutines | |
| Indication of Presence and Location of Peripheral Cards | 2-24 |

## Chapter 3: Hardware Description

| | |
|---|---|
| Introduction | 2-28 |
| Timing Scheme | 2-28 |
| SoftCard Control | 2-29 |
| Address Bus Interface | 2-29 |
| Data Base Interface | 2-31 |

<!-- ===== scan page 008 (printed iv) - type:text ===== -->

|  |  |
|---|---|
| 6502 Refresh | 2-31 |
| DMA Daisy Chain | 2-32 |
| Interrupts | 2-32 |
| SoftCard Parts List | 2-32 |
| SoftCard Schematic | 2-34 |

# PART III: CP/M Reference Manual

## Chapter 1: Introduction to CP/M Features and Facilities

|  |  |
|---|---|
| Introduction | 3-3 |
| An Overview of CP/M 2.0 Facilities | 3-5 |
| Functional Description of CP/M | 3-6 |
| General Command Structure | 3-6 |
| File References | 3-7 |
| Switching Disks | 3-9 |
| Form of Built-In Commands | 3-9 |
| &nbsp;&nbsp;&nbsp;&nbsp;ERAse Command | |
| &nbsp;&nbsp;&nbsp;&nbsp;DIRectory Command | |
| &nbsp;&nbsp;&nbsp;&nbsp;REName Command | |
| &nbsp;&nbsp;&nbsp;&nbsp;SAVE Command | |
| &nbsp;&nbsp;&nbsp;&nbsp;TYPE Command | |
| &nbsp;&nbsp;&nbsp;&nbsp;USER Command | |
| Line Editing and Output Control | 3-13 |
| Transient Commands | 3-14 |
| &nbsp;&nbsp;&nbsp;&nbsp;STAT | |
| &nbsp;&nbsp;&nbsp;&nbsp;ASM | |
| &nbsp;&nbsp;&nbsp;&nbsp;LOAD | |
| &nbsp;&nbsp;&nbsp;&nbsp;DDT | |
| &nbsp;&nbsp;&nbsp;&nbsp;PIP | |
| &nbsp;&nbsp;&nbsp;&nbsp;ED | |
| &nbsp;&nbsp;&nbsp;&nbsp;SUBMIT | |
| &nbsp;&nbsp;&nbsp;&nbsp;DUMP | |
| BDOS Error Messages | 3-36 |

## Chapter 2: CP/M 2.0 Interface Guide

|  |  |
|---|---|
| Introduction | 3-41 |
| Operating System Call Conventions | 3-43 |
| Sample File-to-File Copy Program | 3-63 |
| Sample File Dump Utility | 3-66 |

<!-- ===== scan page 009 (printed v) - type:text ===== -->

| | |
|---|---|
| Sample Random Access Program | 3-69 |
| System Function Summary | 3-76 |

## Chapter 3: CP/M Editor

| | |
|---|---|
| Introduction to ED | 3-79 |
| ED Operation | 3-79 |
| Text Transfer Functions | 3-79 |
| Memory Buffer Organization | 3-83 |
| Memory Buffer Operation | 3-83 |
| Command Strings | 3-84 |
| Text Search and Alteration | 3-86 |
| Source Libraries | 3-88 |
| ED Error Conditions | 3-89 |
| Summary of Control Characters | 3-90 |
| Summary of ED Commands | 3-91 |
| ED Text Editing Commands | 3-92 |

## Chapter 4: CP/M Assembler

| | |
|---|---|
| Introduction | 3-97 |
| Program Format | 3-99 |
| Forming the Operand | 3-100 |
| &nbsp;&nbsp;&nbsp;&nbsp;Labels | |
| &nbsp;&nbsp;&nbsp;&nbsp;Numeric Constants | |
| &nbsp;&nbsp;&nbsp;&nbsp;Reserved Words | |
| &nbsp;&nbsp;&nbsp;&nbsp;String Constants | |
| &nbsp;&nbsp;&nbsp;&nbsp;Arithmetic and Logical Operators | |
| &nbsp;&nbsp;&nbsp;&nbsp;Precedence of Operators | |
| Assembler Directives | 3-105 |
| &nbsp;&nbsp;&nbsp;&nbsp;The ORG Directive | |
| &nbsp;&nbsp;&nbsp;&nbsp;The END Directive | |
| &nbsp;&nbsp;&nbsp;&nbsp;The EQU Directive | |
| &nbsp;&nbsp;&nbsp;&nbsp;The SET Directive | |
| &nbsp;&nbsp;&nbsp;&nbsp;The IF and ENDIF Directives | |
| &nbsp;&nbsp;&nbsp;&nbsp;The DB Directive | |
| &nbsp;&nbsp;&nbsp;&nbsp;The DW Directive | |
| Operation Codes | 3-110 |
| &nbsp;&nbsp;&nbsp;&nbsp;Jumps, Calls and Returns | |
| &nbsp;&nbsp;&nbsp;&nbsp;Immediate Operand Instructions | |
| &nbsp;&nbsp;&nbsp;&nbsp;Data Movement Instructions | |

<!-- ===== scan page 010 (printed vi) - type:mixed ===== -->

|  |  |
| --- | --- |
| &nbsp;&nbsp;&nbsp;Arithmetic Logic Unit Operations | |
| &nbsp;&nbsp;&nbsp;Control Instructions | |
| Error Messages | 3-114 |
| A Sample Session | 3-115 |

## Chapter 5: CP/M Dynamic Debugging Tool

|  |  |
| --- | --- |
| Introduction | 3-123 |
| DDT Commands | 3-125 |
| The A (Assembler) Command | 3-126 |
| The D (Display) Command | 3-126 |
| The F (Fill) Command | 3-127 |
| The G (Go) Command | 3-127 |
| The I (Input) Command | 3-128 |
| The L (List) Command | 3-129 |
| The M (Move) Command | 3-129 |
| The R (Read) Command | 3-129 |
| The S (Set) Command | 3-130 |
| The T (Trace) Command | 3-131 |
| The U (Untrace) Command | 3-132 |
| The X (Examine) Command | 3-132 |
| Implementation Notes | |

# PART IV: Microsoft BASIC Reference Manual

Introduction

## Chapter 1: Microsoft BASIC-80 and Applesoft: A Comparison &nbsp;&nbsp;4-3

|  |  |
| --- | --- |
| &nbsp;&nbsp;Features of Microsoft BASIC not found in Applesoft | 4-4 |
| &nbsp;&nbsp;Applesoft Enhancements | 4-6 |
| &nbsp;&nbsp;Features Used Differently in Microsoft BASIC than in Applesoft | 4-7 |
| &nbsp;&nbsp;Changes in BASIC-80 Features | 4-7 |
| &nbsp;&nbsp;Applesoft Features Not Supported | 4-8 |

## Chapter 2: General Information About BASIC-80 &nbsp;&nbsp;4-9

## Chapter 3: BASIC-80 Commands and Statements &nbsp;&nbsp;4-24

<!-- ===== scan page 011 (printed vii) - type:text ===== -->

**Chapter 4: BASIC-80 Functions**

**Chapter 5: High Resolution Graphics, GBASIC** &nbsp;&nbsp;&nbsp; 4-98

## Appendices

| | |
|---|---|
| High Resolution Graphics: GBASIC | 4-99 |
| New Features in BASIC-80, Release 5.0 | 4-103 |
| BASIC-80 Disk I/O | 4-106 |
| Assembly Language Subroutines | 4-116 |
| Converting Programs to BASIC-80 from BASICs Other Than Applesoft | 4-121 |
| Summary of Error Codes and Error Messages | 4-123 |
| Mathematical Functions | 4-128 |
| ASCII Character Codes | 4-130 |

# PART V: Software Utilities Manual

| | |
|---|---|
| Introduction | 5-2 |
| &nbsp;&nbsp;&nbsp;Format Notation | |
| To Prepare Diskettes for Reading and Writing: FORMAT | 5-3 |
| To Make Copies of Diskettes: COPY | 5-7 |
| &nbsp;&nbsp;&nbsp;To Create CP/M System Disks | |
| To Convert 13-Sector CP/M Files from 16-Sector CP/M: RW13 | 5-10 |
| To Configure CP/M for a 56K System: CPM56 | 5-12 |
| To Transfer Files from Apple DOS to CP/M: APDOS | 5-14 |
| To Configure the Apple CP/M Operating Environment: CONFIGIO | 5-16 |
| &nbsp;&nbsp;&nbsp;1. Configure CP/M for External Terminal | |
| &nbsp;&nbsp;&nbsp;2. Redefine Keyboard Characters | |
| &nbsp;&nbsp;&nbsp;3. Load User I/O Configuration | |
| To Transfer CP/M Files from Another Computer: DOWNLOAD and UPLOAD | 5-28 |

<!-- ===== scan page 012 - type:blank ===== -->

<!-- ===== scan page 013 - type:frontmatter ===== -->

# Microsoft BASIC Reference Manual

<!-- ===== scan page 014 - type:blank ===== -->

<!-- ===== scan page 015 (printed 4-1) - type:frontmatter ===== -->

# PART IV: Microsoft BASIC Reference Manual

| | | |
|---|---|---|
| INTRODUCTION | | 4-3 |
| CHAPTER 1 | BASIC-80 and Applesoft: A Comparison | 4-4 |
| CHAPTER 2 | General Information About BASIC-80 | 4-9 |
| CHAPTER 3 | BASIC-80 Commands and Statements | 4-24 |
| CHAPTER 4 | BASIC-80 Functions | 4-81 |
| CHAPTER 5 | High Resolution Graphics: GBASIC | 4-98 |
| APPENDIX A | New Features in BASIC-80, Release 5.0 | 4-103 |
| APPENDIX B | BASIC-80 Disk I/O | 4-105 |
| APPENDIX C | Assembly Language Subroutines | 4-115 |
| APPENDIX D | Converting Programs to BASIC-80 | 4-121 |
| APPENDIX E | Summary of Error Codes and Error Messages | 4-123 |
| APPENDIX F | Mathematical Functions | 4-128 |
| APPENDIX G | ASCII Character Codes | 4-130 |

4-1

<!-- ===== scan page 016 - type:blank ===== -->

<!-- ===== scan page 017 (printed 4-3) - type:text ===== -->

# INTRODUCTION

Microsoft BASIC, written for Z-80 and 8080 microprocessors, is the most extensive implementation of BASIC available for microcomputers today. Now in its fifth major release, Microsoft BASIC (or BASIC-80) meets the ANSI qualifications for BASIC as set forth in document BSRX3.60-1978. It is upwardly compatible with Applesoft BASIC.

With the Microsoft SoftCard, the most recent version of BASIC-80, Version 5.0, is available to Apple owners for the first time. It brings new power to the Apple, adding major features such as PRINT USING, 16-digit precision, CALL, CHAIN and COMMON, WHILE/WEND and improved disk I/O.

The SoftCard package includes two versions of Microsoft BASIC. MBASIC, which is found on both disks, includes all standard Applesoft extensions from low-resolution graphics to sound and cursor control. These features plus high-resolution graphics are included in GBASIC, which is found on the 16-sector disk only.

The reference guide is divided into five chapters plus a number of appendices. Chapter 1 is a short section covering differences between Microsoft BASIC and Applesoft, especially important for persons used to programming in Applesoft. Chapter 2 includes instructions for initialization of either version of Microsoft BASIC, (referred to throughout this manual as BASIC-80), and explains details of information representation when using Microsoft BASIC. Chapter 3 contains the syntax and semantics of every command and statement in BASIC-80 for the Apple, ordered alphabetically. Chapter 5 pertains to GBASIC only, describing all features found exclusively in GBASIC. The appendices contain lists of error messages, ASCII codes and math functions plus helpful information on the use of assembly language subroutines and disk I/O.

This manual is not intended as a tutorial on the BASIC language. It is a reference manual for the specific features of Microsoft BASIC. If you need instructional material regarding the BASIC language, we suggest you read one of the following:

> *BASIC* by Robert L. Albrecht, LeRoy Finkel, Jerry Brown (John Wiley & Sons, 1973)
>
> *BASIC and the Personal Computer* by Thomas A. Dwyer and Margot Critchfield (Addison-Wesley Publishing Co., 1978)
>
> *BASIC From the Ground Up* by David E. Simon (Hayden, 1978)

<!-- ===== scan page 018 (printed 4-4) - type:text ===== -->

# CHAPTER 1

# Microsoft BASIC-80 and Applesoft: A Comparison

Microsoft BASIC-80, Version 5.0, includes many features not found in Applesoft and also uses some features differently than Applesoft. Realizing that most SoftCard buyers have previously written BASIC programs in Applesoft, we include here a listing of the differences between the two versions of BASIC.

By making note of these differences and using the new features provided by BASIC-80, you can take advantage of increased BASIC programming power.

## Features of Microsoft BASIC not found in Applesoft

The following features are found in Microsoft BASIC only. A brief description of these features is given here; for more information on the syntax, purpose and peculiarities of each, see Chapters 2 and 3 of this manual.

| Feature | Description |
|---|---|
| CHAIN and COMMON | Used to call in another BASIC program from disk and pass variables to it. This feature allows the disk to be used as program memory. |
| CALL | Used to call 6502 or Z-80 assembly language subroutine or FORTRAN subroutine. |
| PRINT USING | Greatly enhances programming convenience by making it easy to format output. It includes asterisk fill, floating dollar sign, scientific notation, trailing sign, and comma insertion. |
| Built-in Disk I/O Statements | Since standard Applesoft BASIC and integer BASIC were not designed for a disk environment, Disk I/O commands have to be included in PRINT statements. With Microsoft BASIC 5.0's built-in disk I/O statements, this process is eliminated (no more PRINT "ctrl D"). |
| WHILE/WEND | Gives BASIC a more structured flavor. By putting a WHILE statement in front of a loop and |

<!-- ===== scan page 019 (printed 4-5) - type:text ===== -->

the WEND statement at the end, BASIC 5.0 will continuously execute the loop as long as a given condition is true.

| Feature | Description |
| --- | --- |
| EDIT Commands | Let you edit individual program lines easily and efficiently without re-entering the whole line. |
| AUTO and RENUM | RENUM makes it easier to edit and debug programs by letting you automatically renumber lines in user-specified increments. AUTO is a convenience feature that generates line numbers automatically after every carriage return. |
| IF ... THEN ... ELSE | Extends the IF statement in Applesoft to provide for handling the negative case of IF. |
| ANSI Compatibility | Microsoft 5.0 BASIC meets the ANSI qualifications for BASIC, as set forth in document BSRX3.60-1978. That means any program you write on your Apple in Microsoft BASIC can be run on any other machine that has an ANSI standard BASIC. |
| Compilability | Microsoft has developed a BASIC compiler that compiles MBASIC and GBASIC programs into directly executable Z-80 machine code. The compiler is available separately to SoftCard owners. |
| Powerful Data Types | BASIC 5.0 has three variable types — fast two-byte true integer variables, single precision variables and double precision variables — to give it 16-digit precision, as opposed to 9-digit precision on the Apple. Also, hexadecimal and octal constants may be used. |
| Added String Functions | INSTR, HEX$, OCT$, STRING$, and direct assignment of substrings with MID$ are implemented. |

<!-- ===== scan page 020 (printed 4-6) - type:text ===== -->

| Added Operators | New boolean operators AND, OR, XOR, IMP, and EQV are provided. True Integer arithmetic is supported with an Integer divide and MOD operators. |
| User-Defined Functions | BASIC-80 user-defined functions allow multiple arguments. |
| Protected Files | BASIC programs may be saved in a protected binary format. See SAVE, Chapter 3. |

We have also included four new features to Microsoft BASIC, especially to take advantage of the Apple's unique characteristics. They are:

| BUTTON(0) | A function used to determine whether a paddle button has been pressed. |
| BEEP | A statement that generates a tone of specified pitch and duration. |
| HSCRN(X,Y) | A function used to determine if a point has been plotted on the high-resolution screen at a specified point. |
| VPOS(0) | A function that returns the vertical cursor position. |

## Applesoft Enhancements

Both versions of BASIC support low-resolution graphics, sound, cursor control and other Applesoft BASIC features. The version of Microsoft BASIC included on the 16-sector disk also supports all of the Applesoft high-resolution graphics features except DRAW, XDRAW, SCALE and ROT.

Applesoft-compatible statements and functions found in MBASIC and GBASIC are shown below. Those features available only in GBASIC are indicated with an asterisk.

```
GR
COLOR
PLOT
VLIN
HLIN
SCRN
POP
HGR*
HCOLOR*
HPLOT*
```

<!-- ===== scan page 021 (printed 4-7) - type:text ===== -->

```
TEXT
HTAB
VTAB
INVERSE
NORMAL
PDL(0)
```

## Features Used Differently in Microsoft BASIC Than in Applesoft

Certain statements and commands found in Microsoft BASIC and Applesoft have slightly different uses. You should be aware of these differences when writing BASIC-80 programs. Those statements that differ are listed below; for more information see Chapters 2 and 3 of this manual.

```
FOR ... NEXT
INPUT
ON ERROR GOTO
RESUME
TEXT
GR
HGR
IF ... THEN ... ELSE
CALL
```

## Changes in BASIC-80 Features

For the SoftCard version of BASIC-80, we have made a few very minor changes to normal CP/M Microsoft BASIC features. If you are accustomed to programming in Microsoft BASIC under CP/M, you will want to note the following changes:

| Statement | Change |
|---|---|
| TRON/TROFF | Statement name has been changed to TRACE/NOTRACE. Operation of this statement remains the same. |
| DELETE | Statement name has been changed to DEL. Operation of this statement remains the same. |
| WIDTH | You now have the option to specify screen height in addition to line width. Also, default width is 40 columns for Apple video and 80 columns for external terminals. |
| WAIT | WAIT now monitors the status of an address rather than of a machine input port. The effect, however, remains the same. |
| CLOAD | Not implemented. |

<!-- ===== scan page 022 (printed 4-8) - type:text ===== -->

| Statement | Status |
| --- | --- |
| CSAVE | Not implemented. |
| NULL | Not implemented. |
| INP | Not implemented. |
| OUT | Not implemented. |

NOTE: BASIC-80 Version 5.0 programs transferred to the Apple must be in ASCII format (i.e., saved with the A option). They may not be in binary format.

## Applesoft Features Not Supported

The following features found in Applesoft BASIC are not found in Microsoft BASIC.

```
FLASH                           SHLOAD
ESC A, B, C, D screen editing   XDRAW
STORE                           DRAW
RECALL                          SCALE
IN#                             cassette LOAD
PR#                             cassette SAVE
HIMEM ... LOMEM                 ROT
```

<!-- ===== scan page 023 (printed 4-9) - type:text ===== -->

# CHAPTER 2
# GENERAL INFORMATION ABOUT BASIC-80

## INITIALIZATION

MBASIC is the CP/M version of Microsoft BASIC that includes all standard Applesoft extensions except high-resolution graphics. It is supplied on both the 13-sector and the 16-sector disks in the SoftCard package. The name of the file on both disks is MBASIC.COM. These initialization instructions refer to MBASIC but may be used for GBASIC simply by substituting GBASIC where MBASIC is typed. (For specific instructions for initializing GBASIC, see Chapter 5.)

To load and run Microsoft BASIC-80, simply bring up the CP/M operating system in the usual manner (See Operations Manual). After the A> prompt appears type:

```
MBASIC
```

and press the RETURN key. In a few seconds, a copyright notice will appear, indicating BASIC-80 is ready for your command.

This sets at 3 the number of files that may be open at any one time during the execution of a BASIC program (see /F option below), allows all memory up to the start of FDOS in CP/M to be used (see /M option below) and sets the maximum record size at 128.

The command line format below can be used in place of the simple MBASIC command if you wish to set these options and/or automatically RUN any program after initialization:

```
MBASIC [<filename>] [/F:<number of files>] [/M:<highest memory location>]
[/S:<maximum record size>]    Press RETURN
```

The <filename> option allows you to RUN a program automatically after initialization is complete. A default extension of .BAS is used if none is supplied and the filename is less than nine characters long. This allows BASIC programs to be executed in batch mode using the SUBMIT facility of CP/M. Such programs should include the SYSTEM statement (See Chapter 3) to return to CP/M when they have finished, allowing the next program in the batch stream to execute.

The /F:<number of files> option sets the number of disk files that may

<!-- ===== scan page 024 (printed 4-10) - type:text ===== -->

be open at any one time during the execution of a BASIC program. Each file data block allocated in this fashion requires 166 bytes plus 128 (or number specified by /S:) bytes of memory. If the /F option is omitted, the number of files defaults to 3. Number of files may be either decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

The /M:<highest memory location> option sets the highest memory location that will be used by MBASIC. In some cases, it is desirable to set the amount of memory well below the CP/M's FDOS to reserve space for assembly language subroutines. In all cases, <highest memory location> should be below the start of FDOS (whose address is contained in locations 6 and 7). If the /M option is omitted, all memory up to the start of FDOS is used. The <highest memory location> number may be decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

The /S:<maximum record size> option sets the maximum size to be allowed for random files. Any integer may be specified, including integers larger than 128.

When BASIC-80 is initialized, the system will reply:

```
BASIC-80 Version 5.xx
(Apple CP/M Version)
Copyright 1980 (c) by Microsoft
Created: dd-Mmm-yy
xxxx Bytes free
Ok
```

Here are a few examples of the different initialization options:

```
A>MBASIC PAYROLL.BAS          Use all memory and 3 files;
                              load and execute PAYROLL.BAS

A>MBASIC INVENT/F:6           Use all memory and 6 files;
                              load and execute INVENT.BAS

A>MBASIC /M:32768            Use first 32K of memory and 3 files

A>MBASIC DATACK/F:2/M:&H9000  Use first 36K of memory,
                              2 files and execute DATACK.BAS
```

## MODES OF OPERATION

When BASIC-80 is initialized, it types the prompt "Ok." "Ok" means BASIC-80 is at command level, that is, it is ready to accept commands. At this point, BASIC-80 may be used in either of two modes: the direct mode or the indirect mode.

In the direct mode, BASIC commands and statements are not preceded by line numbers. They are executed as they are entered. Results of arithmetic and logical operations may be displayed immediately and

<!-- ===== scan page 025 (printed 4-11) - type:text ===== -->

stored for later use, but the instructions themselves are lost after execution. This mode is useful for debugging and for using BASIC as a "calculator" for quick computations that do not require a complete program.

The indirect mode is the mode used for entering programs. Program lines are preceded by line numbers and are stored in memory. The program stored in memory is executed by entering RUN command.

## DISK FILES

Disk filenames follow the normal CP/M naming conventions. All filenames may include A:, B:, C:, D:, E: or F: as the first two characters to specify a disk drive, otherwise the currently selected drive is assumed. The drive name, if specified, must be upper case (i.e., A: not a:). A default extension of .BAS is used on LOAD, SAVE, MERGE and RUN filename commands if no "." appears on the filename and the filename is less than 9 characters long.

## LINE FORMAT

Program lines in a BASIC program have the following format (square brackets indicate optional):

```
nnnnn BASIC statement [:BASIC statement...] <carriage return>
```

At the programmer's option, more than one BASIC statement may be placed on a line, but each statement on a line must be separated from the last by a colon.

A BASIC program line always begins with a line number, ends with a carriage return, and may contain a maximum of 255 characters.

It is possible to extend a logical line over more than one physical line by use of the <line feed> or Control J. <Control J> lets you continue typing a logical line on the next physical line without entering a <carriage return>.

### Line Numbers

Every BASIC program line begins with a line number. Line numbers indicate the order in which the program lines are stored in memory and are also used as references when branching and editing. Line numbers must be in the range 0 to 65529. A period (.) may be used in EDIT, LIST, AUTO and DELETE commands to refer to the current line.

## CHARACTER SET

The BASIC-80 character set is comprised of alphabetic characters, numeric characters and special characters. The alphabetic characters in BASIC-80 are the upper case and lower case letters of the alphabet.

<!-- ===== scan page 026 (printed 4-12) - type:text ===== -->

The numeric characters in BASIC-80 are the digits 0 through 9.

The following special characters and terminal keys are recognized by BASIC-80:

| Character | Name |
| --- | --- |
|  | Blank |
| = | Equal sign or assignment symbol |
| + | Plus sign |
| − | Minus sign |
| * | Asterisk or multiplication symbol |
| / | Slash or division symbol |
| ↑ | Up arrow or exponentiation symbol |
| ( | Left parenthesis |
| ) | Right parenthesis |
| % | Percent |
| # | Number (or pound) sign |
| $ | Dollar sign |
| ! | Exclamation point |
| [ | Left bracket |
| ] | Right bracket |
| , | Comma |
| . | Period or decimal point |
| ' | Single quotation mark (apostrophe) |
| ; | Semicolon |
| : | Colon |
| & | Ampersand |
| ? | Question mark |
| < | Less than |
| > | Greater than |
| \ | Backslash or integer division symbol |
| @ | At-sign |
| _ | Underscore |
| \<rubout\> | Deletes last character typed. |
| \<escape\> | Escapes Edit Mode subcommands. See Section 2.16. |
| \<tab\> | Moves print position to next tab stop. Tab stops are every eight columns. |
| \<carriage return\> | Terminates input of a line. |

## Control Characters

The following control characters are in BASIC-80:

<!-- ===== scan page 027 (printed 4-13) - type:mixed ===== -->

| Key | Description |
|-----|-------------|
| Control @ | Rubout |
| Control-A | Enters Edit Mode on the line being typed. |
| Control-B | Backslash |
| Control-C | Interrupts program execution and returns to BASIC-80 command level. |
| Control-G | Rings the bell at the terminal. |
| Control-H | Backspace. Deletes the last character typed. Same as &larr; |
| Control-I | Tab. Tab stops are every eight columns. Same as &rarr; |
| Control-J | Line feed. Moves to next physical line. |
| Control-K | Right square bracket |
| Control-O | Halts program output while execution continues. A second Control-O restarts output. |
| Control-R | Retypes the line that is currently being typed. |
| Control-S | Suspends program execution. |
| Control-Q | Resumes program execution after a Control-S. |
| Control-X | Deletes the line that is currently being typed. |
| Control-Y | Permits recovery from pressing RESET on a system with an Autostart ROM. |
| &rarr; | Tab. Same as Control-I. |
| &larr; | Backspace. Same as Control-H. |

NOTE: Control-@ Control-B, Control-K and Control-U may be redefined using the CONFIGIO utility.

## CONSTANTS

Constants are the actual values BASIC uses during execution. There are two types of constants: string and numeric.

A string constant is a sequence of up to 255 alphanumeric characters enclosed in double quotation marks. Examples of string constants:

```
"HELLO"
"$25,000.00"
"Number of Employees"
```

Numeric constants are positive or negative numbers. Numeric constants in BASIC cannot contain commas. There are five types of numeric constants:

1. Integer constants &nbsp;&nbsp; Whole numbers between &minus;32768 and +32767. Integer constants do not have decimal points.

<!-- ===== scan page 028 (printed 4-14) - type:text ===== -->

| 2. | Fixed Point constants | Positive or negative real numbers, i.e., numbers that contain decimal points. |
| 3. | Floating Point constants | Positive or negative numbers represented in exponential form (similar to scientific notation). A floating point constant consists of an optionally signed integer or fixed point number (the mantissa) followed by the letter E and an optionally signed integer (the exponent). The exponent must be in the range −38 to +38. |

Examples:

```
235.988E-7 = .0000235988
2359E6 = 2359000000
```

(Double precision floating point constants use the letter D instead of E. See "Single and Double Precision Form for Numeric Constants.")

| 4. | Hex constants | Hexadecimal numbers with the prefix &H. Examples: |

```
&H76
&H32F
```

| 5. | Octal constants | Octal numbers with the prefix &O or &. Examples: |

```
&O347
&1234
```

## Single And Double Precision Form For Numeric Constants

Numeric constants may be either single precision or double precision numbers. With double precision, the numbers are stored with 16 digits of precision, and printed with up to 16 digits.

A single precision constant is any numeric constant that has:

1. seven or fewer digits, or
2. exponential form using E, or
3. a trailing exclamation point (!)

A double precision constant is any numeric constant that has:

1. eight or more digits, or
2. exponential form using D, or
3. a trailing number sign (#)

<!-- ===== scan page 029 (printed 4-15) - type:text ===== -->

Examples:

| Single Precision Constants | Double Precision Constants |
|---|---|
| 46.8 | 345692811 |
| -7.09E-06 | -1.09432D-06 |
| 3489.0 | 3489.0# |
| 22.5! | 7654321.1234 |

# VARIABLES

Variables are names used to represent values that are used in a BASIC program. The value of a variable may be assigned explicitly by the programmer, or it may be assigned as the result of calculations in the program. Before a variable is assigned a value, its value is assumed to be zero.

## Variable Names And Declaration Characters

BASIC-80 variable names may be any length; up to 40 characters are significant. The characters allowed in a variable name are letters and numbers, and the decimal point. The first character must be a letter. Special type declaration characters are also allowed — see below.

A variable name may not be a reserved word unless the reserved word is embedded. If a variable begins with FN, it is assumed to be a call to a user-defined function. Reserved words include all BASIC-80 commands, statements, function names and operator names.

Variables may represent either a numeric value or a string. String variable names are written with a dollar sign ($) as the last character. For example: A$ = "SALES REPORT". The dollar sign is a variable type declaration character, that is, it "declares" that the variable will represent a string. Numeric variable names may declare integer, single or double precision values. The type declaration characters for these variable names are as follows:

```
%          Integer variable
!          Single precision variable
#          Double precision variable
```

The default type for a numeric variable name is single precision.

Examples of BASIC-80 variable names follow.

```
PI#        declares a double precision value
MINIMUM!   declares a single precision value
LIMIT%     declares an integer value
N$         declares a string value
ABC        represents a single precision value
```

<!-- ===== scan page 030 (printed 4-16) - type:text ===== -->

There is a second method by which variable types may be declared. The BASIC-80 statements DEFINT, DEFSTR, DEFSNG and DEFDBL may be included in a program to declare the types for certain variable names. These statements are described in detail in Chapter 3.

## Array Variables

An array is a group or table of values referenced by the same variable name. Each element in an array is referenced by an array variable that is subscripted with an integer or an integer expression. An array variable name has as many subscripts as there are dimensions in the array. For example V(10) would reference a value in a one-dimension array, T(1,4) would reference a value in a two-dimension array, and so on. The maximum number of dimensions for an array is 255. The maximum number of elements per dimension is 32767.

# TYPE CONVERSION

When necessary, BASIC will convert a numeric constant from one type to another. The following rules and examples should be kept in mind.

1. If a numeric constant of one type is set equal to a numeric variable of a different type, the number will be stored as the type declared in the variable name. (If a string variable is set equal to a numeric value or vice versa, a "Type mismatch" error occurs.)

   Example:

   ```
   10 A% = 23.42
   20 PRINT A%
   RUN
    23
   ```

2. During expression evaluation, all of the operands in an arithmetic or relational operation are converted to the same degree of precision, i.e., that of the most precise operand. Also, the result of an arithmetic operation is returned to this degree of precision.

   Examples:

   ```
   10 D# = 6#/7          The arithmetic was performed
   20 PRINT D#           in double precision and the
   RUN                   result was returned in D#
    .8571428571428571    as a double precision value.

   10 D = 6#/7           The arithmetic was performed
   20 PRINT D            in double precision and the
   RUN                   result was returned to D (single
   ```

<!-- ===== scan page 031 (printed 4-17) - type:text ===== -->

.857143 precision variable), rounded and printed as a single precision value.

3. Logical operators convert their operands to integers and return an integer result. Operands must be in the range −32768 to 32767 or an "Overflow" error occurs.

4. When a floating point value is converted to an integer, the fractional portion is rounded.
   Example:

   ```
   10 C% = 55.88
   20 PRINT C%
   RUN
     56
   ```

5. If a double precision variable is assigned a single precision value, only the first seven digits, rounded, of the converted number will be valid. This is because only seven digits of accuracy were supplied with the single precision value. The absolute value of the difference between the printed double precision number and the original single precision value will be less than 6.3E−8 times the original single precision value.
   Example:

   ```
   10 A = 2.04
   20 B# = A
   30 PRINT A;B#
   RUN
     2.04   2.039999961853027
   ```

## EXPRESSIONS AND OPERATORS

An expression may be simply a string or numeric constant, or a variable, or it may combine constants and variables with operators to produce a single value. Operators perform mathematical or logical operations on values. The operators provided by BASIC-80 may be divided into four categories:

1. Arithmetic
2. Relational
3. Logical
4. Functional

<!-- ===== scan page 032 (printed 4-18) - type:mixed ===== -->

## Arithmetic Operators

The arithmetic operators, in order of precedence, are:

| Operator | Operation | Sample Expression |
|----------|-----------|-------------------|
| ↑ | Exponentiation | X↑Y |
| − | Negation | −X |
| *,/ | Multiplication, Floating Point Division | X*Y<br>X/Y |
| +,- | Addition, Subtraction | X+Y |

To change the order in which the operations are performed, use parentheses. Operations within parentheses are performed first. Inside parentheses, the usual order of operations is maintained. Here are some sample algebraic expressions and their BASIC counterparts.

| Algebraic Expression | BASIC Expression |
|----------------------|------------------|
| X+2Y | X+Y*2 |
| X − Y/Z | X−Y/Z |
| XY/Z | X*Y/Z |
| (X+Y)/Z | (X+Y)/Z |
| (X²)Y | (X↑2)↑Y |
| X↑(Y↑Z) | X↑(Y↑Z) |
| X(−Y) | X*(−Y)  Two consecutive operators must be separated by parentheses. |

## Integer Division And Modulus Arithmetic

Two additional operators are available in BASIC-80: Integer division and modulus arithmetic.

Integer division is denoted by the backslash or Control-B on the Apple

<!-- ===== scan page 033 (printed 4-19) - type:text ===== -->

keyboard. (\). The operands are rounded to integers (must be in the range −32768 to 32767) before the division is performed, and the quotient is truncated to an integer. For example:

```
10 \ 4 = 2
25.68 \ 6.99 = 3
```

The precedence of integer division is just after multiplication and floating point division.

Modulus arithmetic is denoted by the operator MOD. It gives the integer value that is the remainder of an integer division. For example:

```
10.4 MOD 4 = 2 (10/4=2 with a remainder 2)
25.68 MOD 6.99 = 5 (26/7=3 with a remainder 5)
```

The precedence of modulus arithmetic is just after integer division.

## Overflow And Division By Zero

If, during the evaluation of an expression, a division by zero is encountered, the "Division by zero" error message is displayed, machine infinity with the sign of the numerator is supplied as the result of the division, and execution continues. If the evaluation of an exponentiation results in zero being raised to a negative power, the "Division by zero" error message is displayed, positive machine infinity is supplied as the result of the exponentiation, and execution continues.

If overflow occurs, the "Overflow" error message is displayed, machine infinity with the algebraically correct sign is supplied as the result, and execution continues.

## Relational Operators

Relational operators are used to compare two values. The result of the comparison is either "true" (−1) or "false" (0). This result may then be used to make a decision regarding program flow. (See IF, Chapter 3.)

| Operator | Relation Tested          | Expression |
|----------|--------------------------|------------|
| =        | Equality                 | X=Y        |
| <>       | Inequality               | X<>Y       |
| <        | Less than                | X<Y        |
| >        | Greater than             | X>Y        |
| <=       | Less than or equal to    | X<=Y       |
| >=       | Greater than or equal to | X>=Y       |

(The equal sign is also used to assign a value to a variable. See LET, Chapter 3.)

<!-- ===== scan page 034 (printed 4-20) - type:mixed ===== -->

When arithmetic and relational operators are combined in one expression, the arithmetic is always performed first. For example, the expression

```
X+Y < (T-1)/Z
```

is true if the value of X plus Y is less than the value of T-1 divided by Z. More examples:

```
IF  SIN(X)<0 GOTO 1000
IF  I MOD J <> 0 THEN K=K+1
```

## Logical Operators

Logical operators perform tests on multiple relations, bit manipulation, or Boolean operations. The logical operator returns a bitwise result which is either "true" (not zero) or "false" (zero). In an expression, logical operations are performed after arithmetic and relational operations. The outcome of a logical operation is determined as shown in the following table. The operators are listed in order of precedence.

NOT

```
X       NOT X
1         0
0         1
```

AND

```
X        Y        X AND Y
1        1           1
1        0           0
0        1           0
0        0           0
```

OR

```
X        Y        X OR Y
1        1          1
1        0          1
0        1          1
0        0          0
```

XOR

```
X        Y        X XOR Y
1        1           0
1        0           1
0        1           1
0        0           0
```

<!-- ===== scan page 035 (printed 4-21) - type:mixed ===== -->

IMP

```
X        Y        X IMP Y
1        1           1
1        0           0
0        1           1
0        0           1
```

EQV

```
X        Y        X EQV Y
1        1           1
1        0           0
0        1           0
0        0           1
```

Just as the relational operators can be used to make decisions regarding program flow, logical operators can connect two or more relations and return a true or false value to be used in a decision (see IF, Chapter 3). For example:

```
IF D<200 AND F<4 THEN 80
IF I>10 OR K<0 THEN 50
IF NOT P THEN 100
```

Logical operators work by converting their operands to sixteen bit, signed, two's complement integers in the range −32768 to +32767. (If the operands are not in this range, an error results.) If both operands are supplied as 0 or −1, logical operators return 0 or −1. The given operation is performed on these integers in bitwise fashion, i.e., each bit of the result is determined by the corresponding bits in the two operands. Thus, it is possible to use logical operators to test bytes for a particular bit pattern. For instance, the AND operator may be used to "mask" all but one of the bits of a status byte at a machine I/O port. The OR operator may be used to "merge" two bytes to create a particular binary value. The following examples will help demonstrate how the logical operators work.

```
63 AND 16=16     63 = binary 111111 and 16 = binary
                 10000, so 63 AND 16 = 16

15 AND 14=14     15 = binary 1111 and 14 = binary 1110,
                 so 15 AND 14 = 14 (binary 1110)

-1 AND 8=8       -1 = binary 1111111111111111 and
                 8 = binary 1000, so -1 AND 8 = 8

4 OR 2=6         4 = binary 100 and 2 = binary 10,
                 so 4 OR 2 = 6 (binary 110)
```

<!-- ===== scan page 036 (printed 4-22) - type:text ===== -->

| Expression | Explanation |
|---|---|
| `10 OR 10=10` | 10 = binary 1010, so 1010 OR 1010 = 1010 (10) |
| `-1 OR -2=-1` | -1 = binary 1111111111111111 and -2 = binary 1111111111111110, so -1 OR -2 = -1. The bit complement of sixteen zeros is sixteen ones, which is the two's complement representation of -1. |
| `NOT X=-(X+1)` | The two's complement of any integer is the bit complement plus one. |

## Functional Operators

A function is used in an expression to call a predetermined operation that is to be performed on an operand. BASIC-80 has "intrinsic" functions that reside in the system, such as SQR (square root) or SIN (sine). All of BASIC-80's intrinsic functions are described in Chapter 4. BASIC-80 also allows "user defined" functions that are written by the programmer. See DEF FN, Chapter 3.

## String Operations

Strings may be concatenated using +. For example:

```
10 A$="FILE" : B$="NAME"
20 PRINT A$ + B$
30 PRINT "NEW " + A$ + B$
RUN
FILENAME
NEW FILENAME
```

Strings may be compared using the same relational operators that are used with numbers:

```
=   <>   <   >   <=   >=
```

String comparisons are made by taking one character at a time from each string and comparing the ASCII codes. If all the ASCII codes are the same, the strings are equal. If the ASCII codes differ, the lower code number precedes the higher. If, during string comparison, the end of one string is reached, the shorter string is said to be smaller. Leading and trailing blanks are significant. Examples:

```
"AA" < "AB"
"FILENAME" = "FILENAME"
"X&" > "X#"
"CL " > "CL"
"kg" > "KG"
```

<!-- ===== scan page 037 (printed 4-23) - type:text ===== -->

```
"SMYTH" < "SMYTHE"
B$ < "9/12/78"  where B$ = "8/12/78"
```

Thus, string comparisons can be used to test string values or to alphabetize strings. All string constants used in comparison expressions must be enclosed in quotation marks.

## INPUT EDITING

If an incorrect character is entered as a line is being typed, it can be deleted with the RUBOUT (Control-A) key or with Control-H. Rubout or Control-A surrounds the deleted character(s) with backslashes, and Control-H has the effect of backspacing over a character and erasing it. Once a character(s) has been deleted, simply continue typing the line as desired.

To delete a line that is in the process of being typed, type Control-X. A carriage return is executed automatically after the line is deleted.

To correct program lines for a program that is currently in memory, simply retype the line using the same line number. BASIC-80 will automatically replace the old line with the new line.

More sophisticated editing capabilities are provided. See EDIT, Chapter 3.

To delete the entire program that is currently residing in memory, enter the NEW command. (See Chapter 3) NEW is usually used to clear memory prior to entering a new program.

## ERROR MESSAGES

If BASIC-80 detects an error that causes program execution to terminate, an error message is printed. For a complete list of BASIC-80 error codes and error messages, see Appendix E.

<!-- ===== scan page 038 (printed 4-24) - type:text ===== -->

# CHAPTER 3

# BASIC-80 COMMANDS AND STATEMENTS

All of the BASIC-80 commands and statements are described in this chapter. Each description is formatted as follows:

Syntax:    Shows the correct syntax for the instruction. See below for syntax notation.

Purpose:    Tells what the instruction is used for.

Remarks:    Describes in detail how the instruction is used.

Example:    Shows sample programs or program segments that demonstrate the use of the instruction.

## Syntax Notation

Wherever the syntax for a statement or command is given, the following rules apply:

1. Items in capital letters must be input as shown.

2. Items in lower case letters enclosed in angle brackets (< >) are to be supplied by the user.

3. Items in square brackets ([ ]) are optional.

4. All punctuation except angle brackets and square brackets (i.e., commas, parentheses, semicolons, hyphens, equal signs) must be included where shown.

5. Items followed by an ellipsis (...) may be repeated any number of times (up to the length of the line).

6. Items separated by a vertical bar (|) are mutually exclusive; choose one.

7. All reserved words must be preceded by and followed by a space.

## AUTO

Syntax:    `AUTO [<line number>[,<increment>]]`

Purpose:    To generate a line number automatically after every carriage return.

<!-- ===== scan page 039 (printed 4-25) - type:text ===== -->

| | |
|---|---|
| Remarks: | AUTO begins numbering at \<line number\> and increments each subsequent line number by \<increment\>. The default for both values is 10. If \<line number\> is followed by a comma but \<increment\> is not specified, the last increment specified in an AUTO command is assumed. |
| | If AUTO generates a line number that is already being used, an asterisk is printed after the number to warn the user that any input will replace the existing line. However, typing a carriage return immediately after the asterisk will save the line and generate the next line number. |
| | AUTO is terminated by typing Control-C. The line in which Control-C is typed is not saved. After Control-C is typed, BASIC returns to command level. |

```
Example:    AUTO 100,50   Generates line numbers 100, 150, 200 ...

            AUTO          Generates line numbers 10, 20, 30, 40 ...
```

## BEEP

| | |
|---|---|
| Syntax: | `BEEP <pitch>, <duration>` |
| Purpose: | To create a tone of specified pitch and duration. |
| Remarks: | 0 is the highest \<pitch\>; 255 is the lowest. |
| | 0 is the shortest \<duration\>; 255 is the longest. A \<duration\> of 255 lasts approximately 1 second. |
| | BEEP is intended for sound effects purposes. No attempt has been made to match specific \<pitches\> or \<durations\> with specific musical notes or note lengths. |
| Example: | `10 BEEP PDL(0), PDL(1): GOTO 10` |

## CALL

| | |
|---|---|
| Syntax: | `CALL <variable name>[(<argument list>)]` |
| Purpose: | To call a Z-80 assembly language subroutine. |
| Syntax 2: | `CALL %<variable name>[(<argument>)]` |
| Purpose: | To call a 6502 assembly language subroutine. |
| Remarks: | The CALL statement is one way to transfer program flow to an assembly language subroutine. (See also the USR function, Chapter 4) |
| | \<variable name\> contains an address that is the starting point in memory of the subroutine. \<variable name\> may not be an array variable name. \<argument list\> contains |

<!-- ===== scan page 040 (printed 4-26) - type:text ===== -->

the arguments that are passed to the assembly language subroutine.

In Syntax 2, the per cent symbol (%) preceding the <variable name> allows the CALL statement to call a 6502 assembly language subroutine.

A 6502 subroutine call may have up to three parameters of one byte each. The first (if any) value is placed in the 6502 A register, the next in the X register and the last in the Y register.

The CALL statement generates the same calling sequence used by Microsoft's FORTRAN, COBOL and BASIC compilers.

Example:

```
110 MYROUT=&HD000
120 CALL MYROUT
130 BELL=&HFF3A
140 CALL % BELL
```

# CHAIN

Syntax:

```
CHAIN [MERGE] <filename>[,[<line number exp>]
   [,ALL][,DELETE<range>]
```

Purpose:
To call a program and pass variables to it from the current program.

Remarks:
<filename> is the name of the program that is called. Example:

```
CHAIN"PROG1"
```

<line number exp> is a line number or an expression that evaluates to a line number in the called program. It is the starting point for execution of the called program. If it is omitted, execution begins at the first line. Example:

```
CHAIN"PROG1",1000
```

<line number exp> is not affected by a RENUM command.

With the ALL option, every variable in the current program is passed to the called program. If the ALL option is omitted, the current program must contain a COMMON statement to list the variables that are passed. See COMMON statement. Example:

```
CHAIN"PROG1",1000,ALL
```

If the MERGE option is included, it allows a subroutine to be brought into the BASIC program as an overlay. That is,

<!-- ===== scan page 041 (printed 4-27) - type:mixed ===== -->

a MERGE operation is performed with the current program and the called program. The called program must be an ASCII file if it is to be MERGEd. Example:

```
CHAIN MERGE"OVRLAY",1000
```

After an overlay is brought in, it is usually desirable to delete it so that a new overlay may be brought in. To do this, use the DELETE option. Example:

```
CHAIN MERGE"OVRLAY2",1000,DELETE 1000-5000
```

The line numbers in <range> are affected by the RENUM command.

| | |
|---|---|
| NOTE: | If the MERGE option is omitted, CHAIN does not preserve variable types or user-defined functions for use by the chained program. That is, any DEFINT, DEFSNG, DEFDBL, DEFSTR, or DEFFN statements containing shared variables must be restated in the chained program. |

## CLEAR

| | |
|---|---|
| Syntax: | `CLEAR [,[<expression1>][,<expression2>]]` |
| Purpose: | To set all numeric variables to zero and all string variables to null; and, optionally, to set the end of memory and the amount of stack space. |
| Remarks: | <expression1> is a memory location which, if specified, sets the highest location available for use by BASIC-80. |
| | <expression2> sets aside stack space for BASIC. The default is 256 bytes or one-eighth of the available memory, whichever is smaller. |
| NOTE: | In previous versions of BASIC-80, <expression1> set the amount of string space, and <expression2> set the end of memory. BASIC-80, release 5.0 and later, allocates string space dynamically. An "Out of string space" error occurs only if there is no free memory left for BASIC to use. |
| Examples: | `CLEAR` |
| | `CLEAR ,32768` |
| | `CLEAR ,,2000` |
| | `CLEAR,32768,2000` |

## CLOSE

| | |
|---|---|
| Syntax: | `CLOSE[#]<file number>[,[#]<file number...>]` |

<!-- ===== scan page 042 (printed 4-28) - type:text ===== -->

| | |
|---|---|
| Purpose: | To conclude I/O to a disk file. |
| Remarks: | \<file number\> is the number under which the file was OPENed. A CLOSE with no arguments closes all open files. |

The association between a particular file and file number terminates upon execution of a CLOSE. The file may then be reOPENed using the same or a different file number; likewise, that file number may now be reused to OPEN any file.

A CLOSE for a sequential output file writes the final buffer of output.

The END statement and the NEW command always CLOSE all disk files automatically. (STOP does not close disk files.)

| | |
|---|---|
| Example: | See Appendix B. |

# COLOR

| | |
|---|---|
| Syntax: | `COLOR=<color number>`<br>where \<color number\> is an integer in the range 0-15. |
| Purpose: | To set the color for plotting in low resolution graphics mode. |
| Remarks: | The colors available and their numbers are: |

```
0 black           8 brown
1 magenta         9 orange
2 dark blue      10 gray
3 purple         11 pink
4 dark green     12 green
5 gray           13 yellow
6 medium blue    14 aqua
7 light blue     15 white
```

\<color number\> may be specified in the GR statement. (See GR). If it is not specified in GR it is set to zero when GR is set until another color is specified with the COLOR statement.

To find out the COLOR of a given point on the screen, use the SCRN function.

COLOR may be used in low resolution graphics mode only.

| | |
|---|---|
| Example: | `10 GR`<br>`20 COLOR=13` |

<!-- ===== scan page 043 (printed 4-29) - type:text ===== -->

## COMMON

| | |
|---|---|
| Syntax: | `COMMON <list of variables>` |
| Purpose: | To pass variables to a CHAINed program. |
| Remarks: | The COMMON statement is used in conjunction with the CHAIN statement. COMMON statements may appear anywhere in a program, though it is recommended that they appear at the beginning. The same variable cannot appear in more than one COMMON statement. Array variables are specified by appending "()" to the variable name. If all variables are to be passed, use CHAIN with the ALL option and omit the COMMON statement. |
| Example: | |

```
100 COMMON A,B,C,D(),G$
110 CHAIN "PROG3",10
       .
       .
       .
```

## CONT

| | |
|---|---|
| Syntax: | `CONT` |
| Purpose: | To continue program execution after a Control-C has been typed, or a STOP or END statement has been executed. |
| Remarks: | Execution resumes at the point where the break occurred. If the break occurred after a prompt from an INPUT statement, execution continues with the reprinting of the prompt (? or prompt string). |
| | CONT is usually used in conjunction with STOP for debugging. When execution is stopped, intermediate values may be examined and changed using direct mode statements. Execution may be resumed with CONT or a direct mode GOTO, which resumes execution at a specified line number. CONT may also be used to continue execution after an error. |
| | CONT is invalid if the program has been edited during the break. |
| Example: | See example for STOP statement. |

## DATA

| | |
|---|---|
| Syntax: | `DATA <list of constants>` |

<!-- ===== scan page 044 (printed 4-30) - type:text ===== -->

| | |
|---|---|
| Purpose: | To store the numeric and string constants that are accessed by the program's READ statement(s). (See READ.) |
| Remarks: | DATA statements are nonexecutable and may be placed anywhere in the program. A DATA statement may contain as many constants as will fit on a line (separated by commas), and any number of DATA statements may be used in a program. The READ statements access the DATA statements in order (by line number) and the data contained therein may be thought of as one continuous list of items, regardless of how many items are on a line or where the lines are placed in the program. |

<list of constants> may contain numeric constants in any format, i.e., fixed point, floating point or integer. (No numeric expressions are allowed in the list.) String constants in DATA statements must be surrounded by double quotation marks only if they contain commas, colons or significant leading or trailing spaces. Otherwise, quotation marks are not needed.

The variable type (numeric or string) given in the READ statement must agree with the corresponding constant in the DATA statement.

DATA statements may be reread from the beginning by use of the RESTORE statement.

| | |
|---|---|
| Example: | See examples for READ statement. |

## DEF FN

| | |
|---|---|
| Syntax: | `DEF FN<name>[(<parameter list>)] =<function definition>` |
| Purpose: | To define and name a function that is written by the user. |
| Remarks: | <name> must be a legal variable name. This name, preceded by FN, becomes the name of the function. <parameter list> is comprised of those variable names in the function definition that are to be replaced when the function is called. The items in the list are separated by commas. <function definition> is an expression that performs the operation of the function. It is limited to one line. Variable names that appear in this expression serve only to define the function; they do not affect program variables that have the same name. A variable name used in a function definition may or may not appear in the parameter list. If it does, the value of the parameter is supplied when the function is called. Otherwise, the current value of the variable is used. |

<!-- ===== scan page 045 (printed 4-31) - type:text ===== -->

The variables in the parameter list represent, on a one-to-one basis, the argument variables or values that will be given in the function call.

User-defined functions may be numeric or string. If a type is specified in the function name, the value of the expression is forced to that type before it is returned to the calling statement. If a type is specified in the function name and the argument type does not match, a "Type mismatch" error occurs.

A DEF FN statement must be executed before the function it defines may be called. If a function is called before it has been defined, an "Undefined user function" error occurs. DEF FN is illegal in the direct mode.

Example:

```
        .
        .
        .
410  DEF FNAB(X,Y)=X↑3/Y↑2
420  T=FNAB(I,J)
        .
        .
```

Line 410 defines the function FNAB. The function is called in line 420.

## DEFINT/SNG/DBL/STR

| | |
|---|---|
| Syntax: | `DEF<type>  <range(s) of letters>`<br>where `<type>` is INT, SNG, DBL, or STR |
| Purpose: | To declare variable types as integer, single precision, double precision, or string. |
| Remarks: | A DEFtype statement declares that the variable names beginning with the letter(s) specified will be that type variable. However, a type declaration character always takes precedence over a DEFtype statement in the typing of a variable.<br><br>If no type declaration statements are encountered, BASIC-80 assumes all variables without declaration characters are single precision variables. |
| Examples: | `10 DEFDBL L-P`  All variables beginning with the letters L, M, N, O, and P will be double precision variables.<br><br>`10 DEFSTR A`  All variables beginning with the letter A will be string variables. |

4-31

<!-- ===== scan page 046 (printed 4-32) - type:text ===== -->

```
10 DEFINT I-N,W-Z
```

All variable beginning with the letters I, J, K, L, M, N, W, X, Y, Z will be integer variables.

# DEF USR

Syntax:
```
DEF USR[<digit>]=<integer expression>
```

Purpose:
To specify the starting address of an assembly language subroutine.

Remarks:
<digit> may be any digit from 0 to 9. The digit corresponds to the number of the USR routine whose address is being specified. If <digit> is omitted, DEF USR0 is assumed. The value of <integer expression> is the starting address of the USR routine. See Appendix C, Assembly Language Subroutines.

Any number of DEF USR statements may appear in a program to redefine subroutine starting addresses, thus allowing access to as many subroutines as necessary.

Example:
```
       .
       .
       .
200 DEF USR0=24000
210 X=USR0(Y↑2/2.89)
       .
       .
       .
```

# DEL

Syntax:
```
DEL[<line number>][-<line number>]
```

Purpose:
To delete program lines.

Remarks:
BASIC-80 always returns to command level after a DEL is executed. If <line number> does not exist, an "Illegal function call" error occurs.

DELETE may be used in place of DEL. DEL entered in a program will list as DELETE.

Examples:

| Command | Action |
|---------|--------|
| `DEL 40` | Deletes line 40 |
| `DEL 40-100` | Deletes lines 40 through 100, inclusive |
| `DEL-40` | Deletes all lines up to and including line 40 |

<!-- ===== scan page 047 (printed 4-33) - type:mixed ===== -->

## DIM

| | |
|---|---|
| Syntax: | `DIM <list of subscripted variables>` |
| Purpose: | To specify the maximum values for array variable subscripts and allocate storage accordingly. |
| Remarks: | If an array variable name is used without a DIM statement, the maximum value of its subscript(s) is assumed to be 10. If a subscript is used that is greater than the maximum specified, a "Subscript out of range" error occurs. The minimum value for a subscript is always 0, unless otherwise specified with the OPTION BASE statement (see OPTION BASE). |

The DIM statement sets all the elements of the specified arrays to an initial value of zero.

| | |
|---|---|
| Example: | |

```
10 DIM A(20)
20 FOR I=0 TO 20
30 READ A(I)
40 NEXT I
   .
   .
   .
```

## EDIT

| | |
|---|---|
| Syntax: | `EDIT <line number>` |
| Purpose: | To enter Edit Mode at the specified line. |
| Remarks: | In Edit Mode, it is possible to edit portions of a line without retyping the entire line. Upon entering Edit Mode, BASIC-80 types the line number of the line to be edited, then it types a space and waits for an Edit Mode subcommand. |

**Edit Mode Subcommands**

Edit Mode subcommands are used to move the cursor or to insert, delete, replace, or search for text within a line. The subcommands are not echoed. Most of the Edit Mode subcommands may be preceded by an integer which causes the command to be executed that number of times. When a preceding integer is not specified, it is assumed to be 1.

Edit Mode subcommands may be categorized according to the following functions:

<!-- ===== scan page 048 (printed 4-34) - type:text ===== -->

1. Moving the cursor
2. Inserting text
3. Deleting text
4. Finding text
5. Replacing text
6. Ending and restarting Edit Mode

### NOTE

In the descriptions that follow, `<ch>` represents any character, `<text>` represents a string of characters of arbitrary length, `[i]` represents an optional integer (the default is 1), and `$` represents the Escape (or Altmode) key.

## 1. Moving the Cursor

Space
: Use the space bar to move the cursor to the right. `[i]`Space moves the cursor i spaces to the right. Characters are printed as you space over them.

←
: In Edit Mode, `[i]` moves the cursor i spaces to the left (backspaces). Characters are printed as you backspace over them.

## 2. Inserting Text

I
: I`<text>$` inserts `<text>` at the current cursor position. The inserted characters are printed on the terminal. To terminate insertion, type Escape. If Carriage Return is typed during an Insert command, the effect is the same as typing Escape and then Carriage Return. During an Insert command, the Rubout (Control-A) or left arrow (←) key on the terminal may be used to delete characters to the left of the cursor. If an attempt is made to insert a character that will make the line longer than 255 characters, a bell (Control-G) is typed and the character is not printed.

X
: The X subcommand is used to extend the line. X moves the cursor to the end of the line, goes into insert mode, and allows insertion of text as if an Insert command had been given. When you are finished extending the line, type Escape or Carriage Return.

## 3. Deleting Text

D
: `[i]`D deletes i characters to the right of the cursor. The

<!-- ===== scan page 049 (printed 4-35) - type:text ===== -->

deleted characters are echoed between backslashes, and the cursor is positioned to the right of the last character deleted. If there are fewer than i characters to the right of the cursor, iD deletes the remainder of the line.

| Subcommand | Description |
| --- | --- |
| H | H deletes all characters to the right of the cursor and then automatically enters insert mode. H is useful for replacing statements at the end of a line. |

## 4. Finding Text

| Subcommand | Description |
| --- | --- |
| S | The subcommand [i]S\<ch\> searches for the ith occurrence of \<ch\> and positions the cursor before it. The character at the current cursor position is not included in the search. If \<ch\> is not found, the cursor will stop at the end of the line. All characters passed over during the search are printed. |
| K | The subcommand [i]K\<ch\> is similar to [i]S\<ch\>, except all the characters passed over in the search are deleted. The cursor is positioned before \<ch\>, and the deleted characters are enclosed in backslashes. |

## 5. Replacing Text

| Subcommand | Description |
| --- | --- |
| C | The subcommand C\<ch\> changes the next character to \<ch\>. If you wish to change the next i characters, use the subcommand iC, followed by i characters. After the ith new character is typed, change mode is exited and you will return to Edit Mode. |

## 6. Ending and Restarting Edit Mode

| Subcommand | Description |
| --- | --- |
| \<cr\> | Typing Carriage Return prints the remainder of the line, saves the changes you made and exits Edit Mode. |
| E | The E subcommand has the same effect as Carriage Return, except the remainder of the line is not printed. |
| Q | The Q subcommand returns to BASIC-80 command level, without saving any of the changes that were made to the line during Edit Mode. |
| L | The L subcommand lists the remainder of the line (saving any changes made so far) and repositions the cursor at the beginning of the line, still in Edit Mode. L is usually used to list the line when you first enter Edit Mode. |
| A | The A subcommand lets you begin editing a line over again. It restores the original line and repositions the cursor at the beginning. |

4-35

<!-- ===== scan page 050 (printed 4-36) - type:text ===== -->

## NOTE

> If BASIC-80 receives an unrecognizable command or illegal character while in Edit Mode, it prints a bell (Control-G) and the command or character is ignored.

## Syntax Errors

When a Syntax Error is encountered during execution of a program, BASIC-80 automatically enters Edit Mode at the line that caused the error. For example:

```
10 K = 2(4)
RUN
?Syntax error in 10
10
```

When you finish editing the line and type Carriage Return (or the E subcommand), BASIC-80 reinserts the line, which causes all variable values to be lost. To preserve the variable values for examination , first exit Edit Mode with the Q subcommand. BASIC-80 will return to command level, and all variable values will be preserved.

## Control-A

To enter Edit Mode on the line you are currently typing, type Control-A. BASIC-80 responds with a carriage return, an exclamation point (!) and a space. The cursor will be positioned at the first character in the line. Proceed by typing an Edit Mode subcommand.

> ### NOTE
>
> Remember, if you have just entered a line and wish to go back and edit it, the command "EDIT ." will enter Edit Mode at the current line. (The line number symbol "." always refers to the current line.)

## END

| | |
|---|---|
| Syntax: | END |
| Purpose: | To terminate program execution, close all files and return to command level. |
| Remarks: | END statements may be placed anywhere in the program to terminate execution. Unlike the STOP statement, END does not cause a BREAK message to be printed. An END statement at the end of a program is optional. BASIC-80 |

<!-- ===== scan page 051 (printed 4-37) - type:text ===== -->

always returns to command level after an END is executed.

| | |
|---|---|
| Example: | `520 IF K>1000 THEN END ELSE GOTO 20` |

## ERASE

| | |
|---|---|
| Syntax: | `ERASE <list of array variables>` |
| Purpose: | To eliminate arrays from a program. |
| Remarks: | Arrays may be redimensioned after they are ERASEd, or the previously allocated array space in memory may be used for other purposes. If an attempt is made to redimension an array without first ERASEing it, a "Redimensioned array" error occurs. |
| Example: | |

```
      .

      .

      .

   450  ERASE A,B
   460  DIM B(99)

      .

      .

      .
```

## ERR AND ERL VARIABLES

When an error handling subroutine is entered, the variable ERR contains the error code for the error, and the variable ERL contains the line number of the line in which the error was detected. The ERR and ERL variables are usually used in IF...THEN statements to direct program flow in the error trap routine.

If the statement that caused the error was a direct mode statement, ERL will contain 65535. To test if an error occurred in a direct statement, use `IF 65535 = ERL THEN ...` Otherwise, use

```
IF ERR = error code THEN ...
IF ERL = line number THEN ...
```

If the line number is not on the right side of the relational operator, it cannot be renumbered by RENUM. Because ERL and ERR are reserved variables, neither may appear to the left of the equal sign in a LET (assignment) statement. BASIC-80's error codes are listed in Appendix E.

<!-- ===== scan page 052 (printed 4-38) - type:mixed ===== -->

# ERROR

| | |
|---|---|
| **Syntax:** | `ERROR <integer expression>` |
| **Purpose:** | 1)  To simulate the occurrence of a BASIC-80 error; or 2) to allow error codes to be defined by the user. |
| **Remarks:** | The value of `<integer expression>` must be greater than 0 and less than 255. If the value of `<integer expression>` equals an error code already in use by BASIC-80 (see Appendix E), the ERROR statement will simulate the occurrence of that error, and the corresponding error message will be printed. (See Example 1.) |

To define your own error code, use a value that is greater than any used by BASIC-80's error codes. (It is preferable to use the highest available values, so compatibility may be maintained when more error codes are added to BASIC-80.) This user-defined error code may then be conveniently handled in an error trap routine. (See Example 2.)

If an ERROR statement specifies a code for which no error message has been defined, BASIC-80 responds with the message UNPRINTABLE ERROR. Execution of an ERROR statement for which there is no error trap routine causes an error message to be printed and execution to halt.

**Example 1:**

```
LIST
10 S = 10
20 T = 5
30 ERROR S + T
40 END
Ok
RUN
String too long in line 30

Or, in direct mode:

Ok
ERROR 15            (you type this line)
String too long     (BASIC-80 types this line)
Ok
```

**Example 2:**

```
        .
        .
        .
110 ON ERROR GOTO 400
120 INPUT "WHAT IS YOUR BET";B
130 IF B > 5000 THEN ERROR 210
```

4-38

<!-- ===== scan page 053 (printed 4-39) - type:text ===== -->

```
        .
        .
        .
400 IF ERR = 210 THEN PRINT "HOUSE LIMIT IS $5000"
410 IF ERL = 130 THEN RESUME 120
        .
        .
        .
```

## FIELD

| | |
|---|---|
| Syntax: | `FIELD[#]<file number>,<field width> AS <string variable>...` |
| Purpose: | To allocate space for variables in a random file buffer. |
| Remarks: | To get data out of a random buffer after a GET or to enter data before a PUT, a FIELD statement must have been executed. `<file number>` is the number under which the file was OPENed. `<field width>` is the number of characters to be allocated to `<string variable>`. For example, |

```
FIELD 1, 20 AS N$, 10 AS ID$, 40 AS ADD$
```

allocates the first 20 positions (bytes) in the random file buffer to the string variable N$, the next 10 positions to ID$, and the next 40 positions to ADD$. FIELD does NOT place any data in the random file buffer. (See LSET/RSET and GET.)

The total number of bytes allocated in a FIELD statement must not exceed the record length that was specified when the file was OPENed. Otherwise, a "Field overflow" error occurs. (The default record length is 128.) Any number of FIELD statements may be executed for the same file, and all FIELD statements that have been executed are in effect at the same time.

| | |
|---|---|
| Example: | See Appendix B. |
| NOTE: | **Do not use a FIELDed variable name in an INPUT or LET statement.** Once a variable name is FIELDed, it points to the correct place in the random file buffer. If a subsequent INPUT or LET statement with that variable name is executed, the variable's pointer is moved to string space. |

## FILES

| | |
|---|---|
| Syntax: | `FILES[<filename>]` |

<!-- ===== scan page 054 (printed 4-40) - type:mixed ===== -->

Purpose:
: To print the names of files residing on the current disk.

Remarks:
: If `<filename>` is omitted, all the files on the currently selected drive will be listed. `<filename>` is a string formula which may contain question marks (?) to match any character in the filename or extension. An asterisk (*) as the first character of the filename or extension will match any file or any extension.

Examples:

```
FILES

FILES "*.BAS"

FILES "B:*.*"

FILES "TEST?.BAS"
```

# FOR...NEXT

Syntax:

```
FOR <variable>=x TO y [STEP z]
        .
        .
        .
    NEXT [<variable>][,<variable>...]
```

where x, y and z are numeric expressions.

Purpose:
: To allow a series of instructions to be performed in a loop a given number of times.

Remarks:
: `<variable>` is used as a counter. The first numeric expression (x) is the initial value of the counter. The second numeric expression (y) is the final value of the counter. The program lines following the FOR statement are executed until the NEXT statement is encountered. Then the counter is incremented by the amount specified by STEP. A check is performed to see if the value of the counter is now greater than the final value (y). If it is not greater, BASIC-80 branches back to the statement after the FOR statement and the process is repeated. If it is greater, execution continues with the statement following the NEXT statement. This is a FOR...NEXT loop. If STEP is not specified, the increment is assumed to be one. If STEP is negative, the final value of the counter is set to be less than the initial value. The counter is decremented each time through the loop, and the loop is executed until the counter is less than the final value.

  The body of the loop is skipped if the initial value of the loop times the sign of the step exceeds the final value times the sign of the step.

4-40

<!-- ===== scan page 055 (printed 4-41) - type:mixed ===== -->

There must be one and only one NEXT for every FOR.

## Nested Loops

FOR...NEXT loops may be nested, that is, a FOR...NEXT loop may be placed within the context of another FOR...NEXT loop. When loops are nested, each loop must have a unique variable name as its counter. The NEXT statement for the inside loop must appear before that for the outside loop. If nested loops have the same end point, a single NEXT statement may be used for all of them if the variable for each FOR is specified in the NEXT.

The variable(s) in the NEXT statement may be omitted, in which case the NEXT statement will match the most recent FOR statement. If a NEXT statement is encountered before its corresponding FOR statement, a "NEXT without FOR" error message is issued and execution is terminated.

Example 1:
```
10 K=10
20 FOR I=1 TO K STEP 2
30 PRINT I;
40 K=K+10
50 PRINT K
60 NEXT
RUN
 1  20
 3  30
 5  40
 7  50
 9  60
Ok
```

Example 2:
```
10 J=0
20 FOR I=1 TO J
30 PRINT I
40 NEXT I
```
In this example, the loop does not execute because the initial value of the loop exceeds the final value.

Example 3:
```
10 I=5
20 FOR I=1 TO I+5
30 PRINT I;
40 NEXT
RUN
 1 2 3 4 5 6 7 8 9 10
Ok
```
In this example, the loop executes ten times. The final value for the loop variable is always set before the initial value

<!-- ===== scan page 056 (printed 4-42) - type:mixed ===== -->

is set. (Note: Previous versions of BASIC-80 set the initial value of the loop variable before setting the final value; i.e., the above loop would have executed six times.)

Example 4:

```
 10 FOR I=1 TO 20
 20 IF I 10 GOTO 100
 30 NEXT
 40 GOTO 110
100 NEXT
110 END
```

This program would result in a NEXT without FOR error. There may be one and only one NEXT for every FOR.

# GET

| | |
|---|---|
| Syntax 1: | `GET [#]<file number>[,<record number>]` |
| Purpose 1: | To read a record from a random disk file into a random buffer. |
| Syntax 2: | `GET <keyboard character>` |
| Purpose 2: | To read a single character from the keyboard. |
| Remarks: | Syntax 1: <file number> is the number under which the file was OPENed. If <record number> is omitted, the next record (after the last GET) is read into the buffer. The largest possible record number 32767. After a GET statement, INPUT# and LINE INPUT# may be done to read characters from the random file buffer. |

Syntax 2: <keyboard character> is not displayed on the screen. It is not necessary to press the RETURN key. If Control @ is the <keyboard character>, it returns the null character. The result of GETting a left-arrow or Control H may also PRINT as if the null character were being returned.

| | |
|---|---|
| Examples: | For examples of syntax 1, see Appendix B. |

Syntax 2:

```
10 GET A$:PRINT A$;
20 GOTO 10
```

# GOSUB...RETURN

| | |
|---|---|
| Syntax: | `GOSUB <line number>` |

```
       .
       .
       .
RETURN
```

4-42

<!-- ===== scan page 057 (printed 4-43) - type:text ===== -->

| | |
|---|---|
| Purpose: | To branch to and return from a subroutine. |
| Remarks: | `<line number>` is the first line of the subroutine. |

A subroutine may be called any number of times in a program, and a subroutine may be called from within another subroutine. Such nesting of subroutines is limited only by available memory.

The RETURN statement(s) in a subroutine cause BASIC-80 to branch back to the statement following the most recent GOSUB statement. A subroutine may contain more than one RETURN statement, should logic dictate a return at different points in the subroutine. Subroutines may appear anywhere in the program, but it is recommended that the subroutine be readily distinguishable from the main program. To prevent inadvertant entry into the subroutine, it may be preceded by a STOP, END, or GOTO statement that directs program control around the subroutine. Also, see POP.

Example:

```
10 GOSUB 40
20 PRINT "BACK FROM SUBROUTINE"
30 END
40 PRINT "SUBROUTINE";
50 PRINT " IN";
60 PRINT " PROGRESS"
70 RETURN
RUN
SUBROUTINE IN PROGRESS
BACK FROM SUBROUTINE
Ok
```

## GOTO

| | |
|---|---|
| Syntax: | GOTO `<line number>` |
| Purpose: | To branch unconditionally out of the normal program sequence to a specified line number. |
| Remarks: | If `<line number>` is an executable statement, that statement and those following are executed. If it is a nonexecutable statement, execution proceeds at the first executable statement encountered after `<line number>`. |

Example:

```
LIST
10 READ R
20 PRINT "R =";R,
```

<!-- ===== scan page 058 (printed 4-44) - type:mixed ===== -->

```
30 A = 3.14*R↑2
40 PRINT "AREA = ";A
50 GOTO 10
60 DATA 5,7,12
Ok
RUN
R = 5       AREA = 78.5
R = 7       AREA = 153.86
R = 12      AREA = 452.16
?Out of data in 10
Ok
```

# GR

Syntax:
```
GR <screen number>, <color number>
```
where `<screen number>` is an integer in the range 0-1 and `<color number>` is an integer in the range 0-15.

Purpose: To initialize low-resolution graphics mode.

Remarks: `<screen number>` specifies the mode to be used as follows:

| number | screen mode |
|--------|-------------|
| 0 | 40x40 graphics + 4 lines text |
| 1 | 40x48 graphics with no lines text |

If `<screen number>` is not specified, `<screen number>` = 0 is assumed.

GR clears the screen when it initializes low-resolution graphics mode.

`<color number>` specifies the color to be used and is optional. If `<color number>` is not specified, color is set to black. `<color number>` will fill the screen with the color specified by `<color number>`. See COLOR for a list of color names and their associated numbers.

Examples:
```
GR        Same as Applesoft GR statement
GR 1,15   Fill screen with white and set 40x48 mode
```

**NOTE THAT THIS STATEMENT MAY BE USED DIFFERENTLY IN MBASIC THAN IN APPLESOFT.**

# HLIN

Syntax:
```
HLIN <x1 coordinate>, <x2 coordinate> AT <y coordinate>
```
where **x1** and **x2** are integers in the range 0-39 and **y** is an integer in the range 0-47.

<!-- ===== scan page 059 (printed 4-45) - type:text ===== -->

| | |
|---|---|
| Purpose: | In low resolution graphics mode, to draw a horizontal line from point (x1,y) to point (x2,y). |
| Remarks: | \<x1 coordinate\> must be less than or equal to \<x2 coordinate\>. |

The color of the line is specified by the most recently executed COLOR statement.

If any of the coordinates are not in the required range as specified above, an ILLEGAL FUNCTION CALL error results.

The HLIN statement normally draws a line composed of dots from x1 to x2 at the vertical coordinate y. However, if used when in TEXT mode, or when in mixed graphics and text mode with y in the range 40-47, a line of characters is displayed instead of the line of dots.

| | |
|---|---|
| Example: | |

```
10 GR
20 COLOR=3
30 HLIN 14,20 AT 39
```

# HOME

| | |
|---|---|
| Syntax: | HOME |
| Purpose: | To clear the screen of all text and move the cursor to the upper left corner of the screen. |
| Remarks: | When used with an external terminal, HOME sends a "clear screen" character sequence to terminals that support this feature. |
| Example: | |

```
10 HOME
20 VTAB 12
30 PRINT "A CLEAN SCREEN"
```

# HTAB

| | |
|---|---|
| Syntax: | HTAB \<screen position number\> |
| Purpose: | To move the cursor to the screen position that is \<screen position number\> spaces from the left edge of the current screen line. |
| Remarks: | The first (left-most) position on the line is 1, the last (right-most) position on the line is 40. |

HTAB uses absolute moves, not relative moves. For instance, if the cursor was at position 10, and the command

<!-- ===== scan page 060 (printed 4-46) - type:mixed ===== -->

HTAB 13 was executed, the cursor would be moved to position 13, not position 23.

If a \<screen position number\> greater than 40 but less than 255 is specified, it will be treated modulo 40. The command HTAB 60 would place the cursor at position 20 on the current line. A \<screen position number\> greater than 255 results in an ILLEGAL FUNCTION CALL error.

# IF...THEN ...ELSE  AND IF...GOTO

| | |
|---|---|
| Syntax: | `IF <expression> THEN <statement(s)> | <line number>`<br>`[ELSE <statement(s)> | <line number>]` |
| Syntax: | `IF <expression> GOTO <line number>`<br>`[ELSE <statement(s)> | <line number>]` |
| Purpose: | To make a decision regarding program flow based on the result returned by an expression. |
| Remarks: | If the result of \<expression\> is not zero, the THEN or GOTO clause is executed. THEN may be followed by either a line number for branching or one or more statements to be executed. GOTO is always followed by a line number. If the result of \<expression\> is zero, the THEN or GOTO clause is ignored and the ELSE clause, if present, is executed. Execution continues with the next executable statement. A comma may be used before THEN. |

## Nesting of IF Statements

IF...THEN...ELSE   statements may be nested. Nesting is limited only by the length of the line. For example

```
IF X>Y THEN PRINT "GREATER" ELSE IF Y>X
      THEN PRINT "LESS THAN" ELSE PRINT "EQUAL"
```

is a legal statement. If the statement does not contain the same number of ELSE and THEN clauses, each ELSE is matched with the closest unmatched THEN. For example

```
IF A=B THEN IF B=C THEN PRINT "A=C"
      ELSE PRINT "A<>C"
```

will not print "A<>C" when A<>B.

If an IF...THEN statement is followed by a line number in the direct mode, an "Undefined line" error results unless a statement with the specified line number had previously been entered in the indirect mode.

4-46

<!-- ===== scan page 061 (printed 4-47) - type:text ===== -->

**NOTE:** When using IF to test equality for a value that is the result of a floating point computation, remember that the internal representation of the value may not be exact. Therefore, the test should be against the range over which the accuracy of the value may vary. For example, to test a computed variable A against the value 1.0, use:

```
IF  ABS (A-1.0)<1.0E-6 THEN ...
```

This test returns true if the value of A is 1.0 with a relative error of less than 1.0E-6.

**Example 1:**
```
200 IF I THEN GET # 1,I
```
This statement GETs record number I if I is not zero.

**Example 2:**
```
100 IF(I<20)*(I>10) THEN DB=1979-1:GOTO 300
110 PRINT "OUT OF RANGE"

      .
      .
      .
```

In this example, a test determines if I is greater than 10 and less than 20. If I is in this range, DB is calculated and execution branches to line 300. If I is not in this range, execution continues with line 110.

**Example 3:**
```
210 IF IOFLAG THEN PRINT A$ ELSE LPRINT A$
```
This statement causes printed output to go either to the terminal or the line printer, depending on the value of a variable (IOFLAG). If IOFLAG is zero, output goes to the line printer, otherwise output goes to the terminal.

# INPUT

**Syntax:**
```
INPUT[;][<"prompt string">;]<list of variables>
INPUT[;][<"prompt string">,]<list of variables>
```

**Purpose:** To allow input from the terminal during program execution.

**Remarks:** When an INPUT statement is encountered, program execution pauses and the program waits for information to be typed in at the terminal. If <"prompt string"> is included, the string is printed. The required data items are then entered at the terminal.

Note that unlike Applesoft, you have the option of entering either a semicolon or comma after the <"prompt string">. Like Applesoft, a semicolon causes a question mark to be printed after the <"prompt string">. A comma after the <"prompt string"> causes the question mark to be suppressed.

4-47

<!-- ===== scan page 062 (printed 4-48) - type:mixed ===== -->

If INPUT is immediately followed by a semicolon, then the carriage return typed by the user to input data does not echo a carriage return/line feed sequence.

The data items that are entered are assigned to the variable(s) given in <variable list>. The number of data items supplied must be the same as the number of variables in the list. Data items are separated by commas.

The variable names in the list may be numeric or string variable names (including subscripted variables). The type of each data item that is input must agree with the type specified by the variable name. (Strings input to an INPUT statement need not be surrounded by quotation marks.)

Responding to INPUT with too many or too few items, or with the wrong type of value (numeric instead of string, etc.) causes the messsage "?Redo from start" to be printed. No assignment of input values is made until an acceptable response is given.

NOTE THAT THIS STATEMENT IS USED
DIFFERENTLY IN MBASIC THAN IN APPLESOFT.

Example 1:

```
10 INPUT X
20 PRINT X "SQUARED IS" X↑2
30 END
RUN
?  5 (The 5 was typed in by the user
        in response to the question mark.)
 5 SQUARED IS 25
Ok
```

Example 2:

```
LIST
10 PI=3.14
20 INPUT "WHAT IS THE RADIUS";R
30 A=PI*R↑2
40 PRINT "THE AREA OF THE CIRCLE IS";A
50 PRINT
60 GOTO 20
Ok
RUN
WHAT IS THE RADIUS? 7.4 (User types 7.4)
THE AREA OF THE CIRCLE IS 171.946

WHAT IS THE RADIUS?
etc.
```

<!-- ===== scan page 063 (printed 4-49) - type:text ===== -->

# INPUT#

| | |
|---|---|
| Syntax: | `INPUT# <file number>,<variable list>` |
| Purpose: | To read data items from a sequential disk file and assign them to program variables. |
| Remarks: | `<file number>` is the number used when the file was OPENed for input. `<variable list>` contains the variable names that will be assigned to the items in the file. (The variable type must match the type specified by the variable name.) With INPUT#, no question mark is printed, as with INPUT. |

The data items in the file should appear just as they would if data were being typed in response to an INPUT statement. With numeric values, leading spaces, carriage returns and line feeds are ignored. The first character encountered that is not a space, carriage return or line feed is assumed to be the start of a number. The number terminates on a space, carriage return, line feed or comma.

If BASIC-80 is scanning the sequential data file for a string item, leading spaces, carriage returns and line feeds are also ignored. The first character encountered that is not a space, carriage return, or line feed is assumed to be the start of a string item. If this first character is a quotation mark ("), the string item will consist of all characters read between the first quotation mark and the second. Thus, a quoted string may not contain a quotation mark as a character. If the first character of the string is not a quotation mark, the string is an unquoted string, and will terminate on a comma, carriage or line feed (or after 255 characters have been read). If end of file is reached when a numeric or string item is being INPUT, the item is terminated.

After a GET statement INPUT# and LINE INPUT# may be done to read characters from the random file buffer.

| | |
|---|---|
| Example: | See Appendix B. |

# INVERSE

| | |
|---|---|
| Syntax: | `INVERSE` |
| Purpose: | To set the video output mode so that the screen displays black characters on a white background. |
| Remarks: | When using an external terminal, INVERSE sends a "Hi- |

<!-- ===== scan page 064 (printed 4-50) - type:text ===== -->

lite" character sequence to those terminals that support this feature. (See "Installation and Operations Manual.")

INVERSE does not affect characters that are already on the screen when INVERSE is executed.

The NORMAL command restores the mode to the usual white letters on black background. (See NORMAL.)

Example:
```
10 PRINT "THESE ARE WHITE CHARACTERS"
20 INVERSE
30 PRINT "THESE ARE BLACK CHARACTERS"
```

## KILL

Syntax:
```
KILL <filename>
```

Purpose: To delete a file from disk.

Remarks: If a KILL statement is given for a file that is currently OPEN, a "File already open" error occurs. KILL is used for all types of disk files: program files, random data files and sequential data files.

Example:
```
200 KILL "DATA1.TXT"
```
See also Appendix B.

## LET

Syntax:
```
[LET] <variable>=<expression>
```

Purpose: To assign the value of an expression to a variable.

Remarks: Notice the word LET is optional, i.e., the equal sign is sufficient when assigning an expression to a variable name.

Example:
```
110 LET D=12
120 LET E=12↑2
130 LET F=12↑4
140 LET SUM=D+E+F
       .
       .
       .
     or
110 D=12
120 E=12↑2
130 F=12↑4
140 SUM=D+E+F
       .
       .
```

<!-- ===== scan page 065 (printed 4-51) - type:text ===== -->

# LINE INPUT

| | |
|---|---|
| Syntax: | `LINE INPUT[;][<"prompt string">;]<string variable>` |
| Purpose: | To input an entire line (up to 254 characters) to a string variable, without the use of delimiters. |
| Remarks: | The prompt string is a string literal that is printed at the terminal before input is accepted. A question mark is not printed unless it is part of the prompt string. All input from the end of the prompt to the carriage return is assigned to `<string variable>`. |
| | If LINE INPUT is immediately followed by a semicolon, then the carriage return typed by the user to end the input line does not echo a carriage return/line feed sequence at the terminal. |
| | A LINE INPUT may be escaped by typing Control-C. BASIC-80 will return to command level and type Ok. Typing CONT resumes execution at the LINE INPUT. |
| Example: | See Example, for LINE INPUT#. |

# LINE INPUT#

| | |
|---|---|
| Syntax: | `LINE INPUT# <file number>,<string variable>` |
| Purpose: | To read an entire line (up to 254 characters), without delimiters, from a sequential disk data file to a string variable. |
| Remarks: | `<file number>` is the number under which the file was OPENed. `<string variable>` is the variable name to which the line will be assigned. LINE INPUT# reads all characters in the sequential file up to a carriage return. It then skips over the carriage return/line feed sequence, and the next LINE INPUT# reads all characters up to the next carriage return. (If a line feed/carriage return sequence is encountered, it is preserved.) |
| | LINE INPUT# is especially useful if each line of a data file has been broken into fields, or if a BASIC-80 program saved in ASCII mode is being read as data by another program. |
| | After a GET statement, INPUT# and LINE INPUT# may be done to read characters from the random file buffer. |
| Example: | (see below) |

```basic
10 OPEN "O",1,"LIST"
20 LINE INPUT "CUSTOMER INFORMATION? ";C$
30 PRINT #1, C$
```

<!-- ===== scan page 066 (printed 4-52) - type:mixed ===== -->

```
40 CLOSE 1
50 OPEN "I",1,"LIST"
60 LINE INPUT # 1, C$
70 PRINT C$
80 CLOSE 1
RUN
CUSTOMER INFORMATION? LINDA JONES     234,4     MEMPHIS
LINDA JONES     234,4     MEMPHIS
Ok
```

# LIST

| | |
|---|---|
| Syntax 1: | LIST [\<line number>] |
| Syntax 2: | LIST [\<line number>[-[\<line number>]]] |
| or | LIST [\<line number>[,[\<line number>]]] |
| Purpose: | To list all or part of the program currently in memory at the terminal. |
| Remarks: | BASIC-80 always returns to command level after a LIST is executed. |

Syntax 1: If \<line number> is omitted, the program is listed beginning at the lowest line number. (Listing is terminated either by the end of the program or by typing Control-C.) If \<line number> is included, only the specified line is listed.

Syntax 2: This format allows the following options:

1. If only the first number is specified, that line and all higher-numbered lines are listed.

2. If only the second number is specified, all lines from the beginning of the program through that line are listed.

3. If both numbers are specified, the entire range is listed.

Examples:

```
Syntax 1:
LIST                Lists the program currently in memory.
LIST 500            Lists line 500.

Format 2:
LIST 150-           Lists all lines from 150 to the end.
LIST -1000          Lists all lines from the lowest number
                    through 1000.
LIST 150-1000       Lists lines 150 through 1000, inclusive.
```

<!-- ===== scan page 067 (printed 4-53) - type:mixed ===== -->

## LLIST

| | |
|---|---|
| Syntax: | `LLIST [<line number>[-[<line number>]]]` |
| Purpose: | To list all or part of the program currently in memory at the line printer. |
| Remarks: | LLIST assumes a 132-character-wide printer.<br><br>BASIC-80 always returns to command level after an LLIST is executed. The options for LLIST are the same as for LIST, Syntax 2. |
| NOTE: | Use of LLIST requires that a printer card be plugged into slot 1 of the Apple. |
| Example: | See the examples for LIST, Syntax 2. |

## LOAD

| | |
|---|---|
| Syntax: | `LOAD <filename>[,R]` |
| Purpose: | To load a file from disk into memory. |
| Remarks: | `<filename>` is the name that was used when the file was SAVEd. (With CP/M, the default extension .BAS is supplied.)<br><br>LOAD closes all open files and deletes all variables and program lines currently residing in memory before it loads the designated program. However, if the "R" option is used with LOAD, the program is RUN after it is LOADed, and all open data files are kept open. Thus, LOAD with the "R" option may be used to chain several programs (or segments of the same program). Information may be passed between the programs using their disk data files. |
| Example: | `LOAD "STRTRK",R` |

## LPRINT AND LPRINT USING

| | |
|---|---|
| Syntax: | `LPRINT [<list of expressions>]`<br>`LPRINT USING <string exp>;<list of expressions>` |
| Purpose: | To print data at the line printer. |
| Remarks: | Same as PRINT and PRINT USING, except output goes to the line printer. See PRINT and PRINT USING.<br><br>LPRINT assumes a 132-character-wide printer. |
| NOTE: | Use of LPRINT requires that a printer card be plugged into slot 1 of the Apple |

4-53

<!-- ===== scan page 068 (printed 4-54) - type:text ===== -->

# LSET AND RSET

**Syntax:**

```
LSET <string variable> = <string expression>
RSET <string variable> = <string expression>
```

**Purpose:** To move data from memory to a random file buffer (in preparation for a PUT statement).

**Remarks:** If `<string expression>` requires fewer bytes than were FIELDed to `<string variable>`, LSET left-justifies the string in the field, and RSET right-justifies the string. (Spaces are used to pad the extra positions.) If the string is too long for the field, characters are dropped from the right. Numeric values must be converted to strings before they are LSET or RSET. See the MKI$, MKS$, MKD$ functions.

**Examples:**

```
150 LSET A$=MKS$(AMT)
160 LSET D$=DESC($)
```

See also Appendix B.

**NOTE:** LSET or RSET may also be used with a non-fielded string variable to left-justify or right-justify a string in a given field. For example, the program lines

```
110 A$=SPACE$(20)
120 RSET A$=N$
```

right-justify the string N$ in a 20-character field. This can be very handy for formatting printed output.

# MERGE

**Syntax:**

```
MERGE <filename>
```

**Purpose:** To merge a specified disk file into the program currently in memory.

**Remarks:** `<filename>` is the name used when the file was SAVEd. (With CP/M, the default extension .BAS is supplied.) The file must have been SAVEd in ASCII format. (If not, a "Bad file mode" error occurs.)

If any lines in the disk file have the same line numbers as lines in the program in memory, the lines from the file on disk will replace the corresponding lines in memory. (MERGEing may be thought of as "inserting" the program lines on disk into the program in memory.)

BASIC-80 always returns to command level after executing a MERGE command.

**Example:**

```
MERGE "NUMBRS"
```

<!-- ===== scan page 069 (printed 4-55) - type:mixed ===== -->

## MID$

| | |
|---|---|
| Syntax: | `MID$(<string exp1>,n[,m])=<string exp2>`<br>where   n and m are integer expressions and \<string exp1\> and \<string exp2\> are string expressions. |
| Purpose: | To replace a portion of one string with another string. |
| Remarks: | The characters in \<string exp1\>, beginning at position n, are replaced by the characters in \<string exp2\>. The optional m refers to the number of characters from \<string exp2\> that will be used in the replacement. If m is omitted, all of \<string exp2\> is used. However, regardless of whether m is omitted or included, the replacement of characters never goes beyond the original length of \<string exp1\>. |
| Example: | <pre>10 A$="KANSAS CITY, MO"<br>20 MID$(A$,14)="KS"<br>30 PRINT A$<br>RUN<br>KANSAS CITY, KS</pre> |

MID$ may also be used as a function that returns a substring of a given string. See MID$ in Chapter 4.

## NAME

| | |
|---|---|
| Syntax: | `NAME <old filename> AS <new filename>` |
| Purpose: | To change the name of a disk file. |
| Remarks: | \<old filename\> must exist and \<new filename\> must not exist; otherwise an error will result. After a NAME command, the file exists on the same disk, in the same area of disk space, with the new name. |
| Example: | <pre>Ok<br>NAME "ACCTS" AS "LEDGER"<br>Ok</pre>In this example, the file that was formerly named ACCTS will now be named LEDGER. |

## NEW

| | |
|---|---|
| Syntax: | `NEW` |
| Purpose: | To delete the program currently in memory and clear all variables. |

<!-- ===== scan page 070 (printed 4-56) - type:text ===== -->

Remarks:    NEW is entered at command level to clear memory before entering a new program. BASIC-80 always returns to command level after a NEW is executed.

## NORMAL

Syntax:     NORMAL

Purpose:    To restore the video output mode to the usual white characters on black background.

Remarks:    NORMAL is used in conjunction with the INVERSE command. (See INVERSE.)

NORMAL does not affect characters already on the screen in INVERSE mode when the NORMAL command is executed.

For external terminals that support the "Hi-lite" feature for INVERSE, NORMAL sends a "Lo-lite" character sequence. (See "Installation and Operations Manual.")

Example:
```
10 INVERSE
20 PRINT "THIS IS INVERSE MODE"
30 NORMAL
40 PRINT "THIS IS NOT"
```

## ON ERROR GOTO

Syntax:     ON ERROR GOTO <line number>

Purpose:    To enable error trapping and specify the first line of the error handling subroutine.

Remarks:    Once error trapping has been enabled all errors detected, including direct mode errors (e.g., Syntax errors), will cause a jump to the specified error handling subroutine. If <line number> does not exist, an "Undefined line" error results. To disable error trapping, execute an ON ERROR GOTO 0. Subsequent errors will print an error message and halt execution. An ON ERROR GOTO 0 statement that appears in an error trapping subroutine causes BASIC-80 to stop and print the error message for the error that caused the trap. It is recommended that all error trapping subroutines execute an ON ERROR GOTO 0 if an error is encountered for which there is no recovery action.

4-56

<!-- ===== scan page 071 (printed 4-57) - type:text ===== -->

NOTE: If an error occurs during execution of an error handling subroutine, the BASIC error message is printed and execution terminates. Error trapping does not occur within the error handling subroutine.

Example:

```
10 ON ERROR GOTO 1000
```

NOTE THAT THIS STATEMENT IS USED DIFFERENTLY IN MBASIC THAN IN APPLESOFT

## ON...GOSUB AND ON...GOTO

Syntax:

```
ON <expression> GOTO <list of line numbers>
ON <expression> GOSUB <list of line numbers>
```

Purpose: To branch to one of several specified line numbers, depending on the value returned when an expression is evaluated.

Remarks: The value of <expression> determines which line number in the list will be used for branching. For example, if the value is three, the third line number in the list will be the destination of the branch. (If the value is a non-integer, the fractional portion is rounded.)

In the ON...GOSUB statement, each line number in the list must be the first line number of a subroutine.

If the value of <expression> is zero or greater than the number of items in the list (but less than or equal to 255), BASIC continues with the next executable statement. If the value of <expression> is negative or greater than 255, an "Illegal function call" error occurs.

Example:

```
100 ON L-1 GOTO 150,300,320,390
```

## OPEN

Syntax:

```
OPEN <mode>,[#]<file number>,<filename>[,<reclen>]
```

Purpose: To allow I/O to a disk file.

Remarks: A disk file must be OPENed before any disk I/O operation can be performed on that file. OPEN allocates a buffer for I/O to the file and determines the mode of access that will be used with the buffer.

<mode> is a string expression whose first character is one of the following:

| | |
|---|---|
| O | specifies sequential output mode |
| I | specifies sequential input mode |
| R | specifies random input/output mode |

<!-- ===== scan page 072 (printed 4-58) - type:text ===== -->

&lt;file number&gt; is an integer expression whose value is between one and fifteen. The number is then associated with the file for as long as it is OPEN and is used to refer other disk I/O statements to the file.

&lt;filename&gt; is a string expression containing a name that conforms to your operating system's rules for disk filenames.

&lt;reclen&gt; is an integer expression which, if included, sets the record length for random files. The default record length is 128 bytes. See also Appendix A

NOTE: A file can be OPENed for sequential input or random access on more than one file number at a time. A file may be OPENed for output, however, on only one file number at a time.

Example:
```
10 OPEN "I",2,"INVEN"
```
See also Appendix B.

# OPTION BASE

Syntax:
```
OPTION BASE n
```
where n is 1 or 0

Purpose: To   declare the minimum value for array subscripts.

Remarks: The default base is 0. If the statement
```
OPTION BASE 1
```
is executed, the lowest value an array subscript may have is one.

# PLOT

Syntax:
```
PLOT <x coordinate>, <y coordinate>
```
where &lt;x coordinate&gt; is an integer in the range 0-39 and &lt;y coordinate&gt; is an integer in the range 0-47.

Purpose: In low resolution graphics mode, to place a dot with &lt;x coordinate&gt; and &lt;y coordinate&gt;.

Remarks: The point (0,0) is in the upper left corner of the screen.

The color of the dot placed by PLOT is determined by the most recently executed COLOR or GR statement.

PLOT normally places a dot at (x,y). However, if PLOT is used while in TEXT mode, or while in mixed graphics and text mode with y in the range 40-47, a character is displayed instead of a dot.

4-58

<!-- ===== scan page 073 (printed 4-59) - type:text ===== -->

If either <x coordinate> or <y coordinate> is not in the required range as specified above, an ILLEGAL FUNCTION CALL error results.

Example:

```
GR
COLOR=9
PLOT 24,37
```

## POKE

Syntax:

```
POKE I,J
```

where I and J are integer expressions

Purpose: To write a byte into a memory location.

Remarks: The integer expression I is the address of the memory location to be POKEd. The integer expression J is the data to be POKEd. J must be in the range 0 to 255. I must be in the range 0 to 65536. Refer to the 6502 to Z-80 Memory Map in the Hardware Details section of this manual.

The complementary function to POKE is PEEK. The argument to PEEK is an address from which a byte is to be read. See PEEK, Chapter 4.

POKE and PEEK are useful for efficient data storage, loading assembly language subroutines, and passing arguments and results to and from assembly language subroutines.

NOTE: PEEKs and POKEs used in Applesoft will not work unless they are first converted to use Z-80 addresses. Refer to the 6502 To Z-80 Memory Map in the Hardware Details section of this manual.

Example:

```
10 POKE &H5A00,&HFF
```

## POP

Syntax:

```
POP
```

Purpose: To return from a subroutine that was branched to by a GOSUB without branching back to the statement following the most recent GOSUB.

Remarks: POP is used instead of RETURN to nullify a GOSUB. Like RETURN, it nullifies the last GOSUB in effect, but it does not return to the statement following the GOSUB. After a POP, the next RETURN encountered will branch to one statement beyond the second most recently executed

4-59

<!-- ===== scan page 074 (printed 4-60) - type:mixed ===== -->

GOSUB. Thus POP, in effect, takes one address off the top of the "stack" of RETURN addresses.

See also GOSUB ... RETURN.

Example:

```
5 PRINT "HERE WE GO"
10 GOSUB 100
20 PRINT "XYZ"
30 END
100 GOSUB 200
110 PRINT "HELLO"
120 RETURN
200 POP
210 RETURN

RUN
HERE WE GO
XYZ
```

# PRINT

Syntax:

```
PRINT [<list of expressions>]
```

Purpose: To output data at the terminal.

Remarks: If &lt;list of expressions&gt; is omitted, a blank line is printed. If &lt;list of expressions&gt; is included, the values of the expressions are printed at the terminal. The expressions in the list may be numeric and/or string expressions. (Strings must be enclosed in quotation marks.)

## Print Positions

The position of each printed item is determined by the punctuation used to separate the items in the list. BASIC-80 divides the line into print zones of 14 spaces each. In the list of expressions, a comma causes the next value to be printed at the beginning of the next zone. A semicolon causes the next value to be printed immediately after the last value. Typing one or more spaces between expressions has the same effect as typing a semicolon. If a comma or a semicolon terminates the list of expressions, the next PRINT statement begins printing on the same line, spacing accordingly.

If the list of expressions terminates without a comma or a semicolon, a carriage return is printed at the end of the line. If the printed line is longer than the terminal width, BASIC-80 goes to the next physical line and continues printing.

<!-- ===== scan page 075 (printed 4-61) - type:mixed ===== -->

Printed numbers are always followed by a space. Positive numbers are preceded by a space. Negative numbers are preceded by a minus sign. Single precision numbers that can be represented with 6 or fewer digits in the unscaled format no less accurately than they can be represented in the scaled format, are output using the unscaled format. For example, 10↑(−6) is output as .000001 and 10↑(−7) is output as 1E−7. Double precision numbers that can be represented with 16 or fewer digits in the unscaled format no less accurately than they can be represented in the scaled format, are output using the unscaled format. For example, 1D−16 is output as .0000000000000001 and 1D−17 is output as 1D−17.

A question mark may be used in place of the word PRINT in a PRINT statement.

Example 1:
```
10 X=5
20 PRINT X+5, X−5, X*(−5), X↑5
30 END
RUN
 10            0           −25          3125
Ok
```

In this example, the commas in the PRINT statement cause each value to be printed at the beginning of the next print zone.

Example 2:
```
LIST
10 INPUT X
20 PRINT X "SQUARED IS" X↑2 "AND";
30 PRINT X "CUBED IS" X↑3
40 PRINT
50 GOTO 10
Ok
RUN
? 9
 9 SQUARED IS 81 AND 9 CUBED IS 729

? 21
 21 SQUARED IS 441 AND 21 CUBED IS 9261

?
```

In this example, the semicolon at the end of line 20 causes both PRINT statements to be printed on the same line, and

<!-- ===== scan page 076 (printed 4-62) - type:text ===== -->

line 40 causes a blank line to be printed before the next prompt.

```
Example 3:  10 FOR X = 1 TO 5
            20 J=J+5
            30 K=K+10
            40 ?J;K;
            50 NEXT X
            Ok
            RUN
             5  10  10  20  15  30  20  40  25  50
            Ok
```

In this example, the semicolons in the PRINT statement cause each value to be printed immediately after the preceding value. (Don't forget, a number is always followed by a space and positive numbers are preceded by a space.) In line 40, a question mark is used instead of the word PRINT.

# PRINT USING

| | |
|---|---|
| Syntax: | `PRINT USING <string exp>;<list of expressions>` |
| Purpose: | To print strings or numbers using a specified format. |
| Remarks and Examples: | `<list of expressions>` is comprised of the string expressions or numeric expressions that are to be printed, separated by semicolons. `<string exp>` is a string literal (or variable) comprised of special formatting characters. These formatting characters (see below) determine the field and the format of the printed strings or numbers. |

## String Fields

When PRINT USING is used to print strings, one of three formatting characters may be used to format the string field:

| | |
|---|---|
| `"!"` | Specifies that only the first character in the given string is to be printed. |
| `"\n spaces\"` | Specifies that 2+n characters from the string are to be printed. If the backslashes are typed with no spaces, two characters will be printed; with one space, three characters will be printed, and so on. If the string is longer than the field, the extra characters are ignored. If the field is longer than the string, the string will be left-justified in the field and padded with spaces on the right. |

<!-- ===== scan page 077 (printed 4-63) - type:text ===== -->

Example:

```
10 A$="LOOK":B$="OUT"
30 PRINT USING "!";A$;B$
40 PRINT USING "\   \";A$;B$
50 PRINT USING "\   \";A$;B$;"!!"
RUN
LO
LOOKOUT
LOOK OUT  !!
```

"&"  Specifies a variable length string field. When the field is specified with "&", the string is output exactly as input. Example:

```
10 A$="LOOK":B$="OUT"
20 PRINT USING "!";A$;
30 PRINT USING "&";B$
RUN
LOUT
```

## Numeric Fields

When PRINT USING is used to print numbers, the following special characters may be used to format the numeric field:

\#  A number sign is used to represent each digit position. Digit positions are always filled. If the number to be printed has fewer digits than positions specified, the number will be right-justified (preceded by spaces) in the field.

A decimal point may be inserted at any position in the field. If the format string specifies that a digit is to precede the decimal point, the digit will always be printed (as 0 if necessary). Numbers are rounded as necessary.

```
PRINT USING "##.##";.78
 0.78

PRINT USING "###.##";987.654
987.65

PRINT USING "##.##   ";10.2,5.3,66.789,.234
10.20    5.30    66.79    0.23
```

In the last example, three spaces were inserted at the end of the format string to separate the printed values on the line.

<!-- ===== scan page 078 (printed 4-64) - type:mixed ===== -->

| | |
|---|---|
| `+` | A plus sign at the beginning or end of the format string will cause the sign of the number (plus or minus) to be printed before or after the number. |
| `−` | A minus sign at the end of the format field will cause negative numbers to be printed with a trailing minus sign. |

```
PRINT USING " # #.# #    ";-68.95,2.4,55.6,-.9
-68.95     +2.40    +55.60    -0.90

PRINT USING "# #.# # -    ";-68.95,22.449,-7.01
68.95-     22.45    7.01-
```

| | |
|---|---|
| `**` | A double asterisk at the beginning of the format string causes leading spaces in the numeric field to be filled with asterisks. The `**` also specifies positions for two more digits. |

```
PRINT USING "** #.#     ";12.39,-0.9,765.1
*12.4     *-0.9     765.1
```

| | |
|---|---|
| `$$` | A double dollar sign causes a dollar sign to be printed to the immediate left of the formatted number. The `$$` specifies two more digit positions, one of which is the dollar sign. The exponential format cannot be used with `$$`. Negative numbers cannot be used unless the minus sign trails to the right. |

```
PRINT USING "$$# # #.# #";456.78
  $456.78
```

| | |
|---|---|
| `**$` | The `**$` at the beginning of a format string combines the effects of the above two symbols. Leading spaces will be asterisk-filled and a dollar sign will be printed before the number. `**$` specifies three more digit positions, one of which is the dollar sign. |

```
PRINT USING "**$# #.# #";2.34
***$2.34
```

A comma that is to the left of the decimal point in a formatting string causes a comma to be printed to the left of every third digit to the left of the decimal point. A comma that is at the end of the format string is printed as part of the string. A comma specifies another digit position. The comma has no effect if used with the exponential (↑↑↑↑) format.

```
PRINT USING "# # # #,.# #";1234.5
1,234.50

PRINT USING "# # # #.# #,";1234.5
1234.50,
```

<!-- ===== scan page 079 (printed 4-65) - type:text ===== -->

| Char | Description |
|---|---|
| `↑↑↑↑` | Four carats (or up-arrows) may be placed after the digit position characters to specify exponential format. The four carats allow space for E+xx to be printed. Any decimal point position may be specified. The significant digits are left-justified, and the exponent is adjusted. Unless a leading + or trailing + or − is specified, one digit position will be used to the left of the decimal point to print a space or a minus sign. |

```
PRINT USING "##.##↑↑↑↑";234.56
 2.35E+02

PRINT USING ".####↑↑↑↑-";888888
 .8889E+06

PRINT USING "+.##↑↑↑↑";123
+.12E+03
```

| Char | Description |
|---|---|
| `_` | An underscore in the format string causes the next character to be output as a literal character. |

```
PRINT USING "_!##.##_!";12.34
!12.34!
```

The literal character itself may be an underscore by placing `"_ _"` in the format string.

| Char | Description |
|---|---|
| `%` | If the number to be printed is larger than the specified numeric field, a percent sign is printed in front of the number. If rounding causes the number to exceed the field, a percent sign will be printed in front of the rounded number. |

```
PRINT USING "##.##";111.22
%111.22

PRINT USING ".##";.999
%1.00
```

If the number of digits specified exceeds 24, an "Illegal function call" error will result.

# PRINT# AND PRINT# USING

| | |
|---|---|
| Syntax: | `PRINT# <filenumber>,[USING<string exp>;]<list of exps>` |
| Purpose: | To write data to a sequential disk file. |
| Remarks: | `<filenumber>` is the number used when the file was OPENed for output. `<string exp>` is comprised of formatting characters as described for PRINT USING. The expressions in `<list of expressions>` are the numeric and/or |

<!-- ===== scan page 080 (printed 4-66) - type:text ===== -->

string expressions that will be written to the file.

PRINT# does not compress data on the disk. An image of the data is written to the disk, just as it would be displayed on the terminal with a PRINT statement. For this reason, care should be taken to delimit the data on the disk, so that it will be input correctly from the disk.

In the list of expressions, numeric expressions should be delimited by semicolons. For example,

```
PRINT# 1,A;B;C;X;Y;Z
```

(If commas are used as delimiters, the extra blanks that are inserted between print fields will also be written to disk.)

String expressions must be separated by semicolons in the list. To format the string expressions correctly on the disk, use explicit delimiters in the list of expressions.

For example, let A$="CAMERA" and B$="93604-1". The statement

```
PRINT# 1,A$;B$
```

would write CAMERA93604-1 to the disk. Because there are no delimiters, this could not be input as two separate strings. To correct the problem, insert explicit delimiters into the PRINT# statement as follows:

```
PRINT# 1,A$;",";B$
```

The image written to disk is

```
CAMERA,93604-1
```

which can be read back into two string variables.

If the strings themselves contain commas, semicolons, significant leading blanks, carriage returns, or line feeds, write them to disk surrounded by explicit quotation marks, CHR$(34). For example, let A$="CAMERA, AUTOMATIC" and B$="   93604-1". The statement

```
PRINT# 1,A$;B$
```

would write the following image to disk:

```
CAMERA, AUTOMATIC    93604-1
```

and the statement

```
INPUT# 1,A$,B$
```

<!-- ===== scan page 081 (printed 4-67) - type:text ===== -->

would input "CAMERA" to A$ and "AUTOMATIC 93604-1" to B$. To separate these strings properly on the disk, write double quotes to the disk image using CHR$(34). The statement

```
PRINT # 1,CHR$(34);A$;CHR$(34);CHR$(34);B$;CHR$(34)
```

writes the following image to disk:

```
"CAMERA, AUTOMATIC""    93604-1"
```

and the statement

```
INPUT # 1,A$,B$
```

would input "CAMERA, AUTOMATIC" to A$ and " 93604-1" to B$.

The PRINT# statement may also be used with the USING option to control the format of the disk file. For example:

```
PRINT # 1,USING"$$ # # #.# #,";J;K;L
```

PRINT#, PRINT# USING and WRITE# may also be used to put characters in the random file buffer before a PUT statement

For more examples using PRINT#, see Appendix B. See also WRITE#.

# PUT

| | |
|---|---|
| Syntax: | `PUT [#] <file number>[,<record number>]` |
| Purpose: | To write a record from a random buffer to a random disk file. |
| Remarks: | `<file number>` is the number under which the file was OPENed. If `<record number>` is omitted, the record will have the next available record number (after the last PUT). The largest possible record number is 32767. |
| Example: | See Appendix B. |

# RANDOMIZE

| | |
|---|---|
| Syntax: | `RANDOMIZE [<expression>]` |
| Purpose: | To reseed the random number generator. |
| Remarks: | If `<expression>` is omitted, BASIC-80 suspends program execution and asks for a value by printing |

```
Random Number Seed (-32768 to 32767)?
```

before executing RANDOMIZE.

4-67

<!-- ===== scan page 082 (printed 4-68) - type:mixed ===== -->

If the random number generator is not reseeded, the RND function returns the same sequence of random numbers each time the program is RUN. To change the sequence of random numbers every time the program is RUN, place a RANDOMIZE statement at the beginning of the program and change the argument with each RUN.

Example:

```
10 RANDOMIZE
20 FOR I=1 TO 5
30 PRINT RND;
40 NEXT I
RUN
Random Number Seed (-32768- +32767)? 3 (user types 3)
 .88598  .484668  .586328  .119426  .709225
Ok
RUN
Random Number Seed (-32768- +32767)? 4 (user types 4 for
new sequence)
 .803506  .162462  .929364  .292443  .322921
Ok
RUN
Random Number Seed (-32768- +32767)? 3 (same sequence as
first RUN)
 .88598  .484668  .586328  .119426  .709225
Ok
```

NOTE: With the BASIC Compiler, the prompt given by RANDOMIZE is:

```
Random Number Seed (-32768 to 32767)?
```

# READ

Syntax:

```
READ <list of variables>
```

Purpose: To read values from a DATA statement and assign them to variables. (See DATA.)

Remarks: A READ statement must always be used in conjunction with a DATA statement. READ statements assign variables to DATA statement values on a one-to-one basis. READ statement variables may be numeric or string, and the values read must agree with the variable types specified. If they do not agree, a "Syntax error" will result.

A single READ statement may access one or more DATA

<!-- ===== scan page 083 (printed 4-69) - type:mixed ===== -->

statements (they will be accessed in order), or several READ statements may access the same DATA statement. If the number of variables in <list of variables> exceeds the number of elements in the DATA statement(s), an OUT OF DATA message is printed. If the number of variables specified is fewer than the number of elements in the DATA statement(s), subsequent READ statements will begin reading data at the first unread element. If there are no subsequent READ statements, the extra data is ignored.

To reread DATA statements from the start, use the RESTORE statement (see RESTORE).

Example 1:

```
.
.
.
80 FOR I=1 TO 10
90 READ A(I)
100 NEXT I
110 DATA 3.08,5.19,3.12,3.98,4.24
120 DATA 5.08,5.55,4.00,3.16,3.37
.
.
.
```

This program segment READs the values from the DATA statements into the array A. After execution, the value of A(1) will be 3.08, and so on.

Example 2:

```
LIST
10 PRINT "CITY", "STATE", "   ZIP"
20 READ C$,S$,Z
30 DATA "DENVER,",  COLORADO, 80211
40 PRINT C$,S$,Z
Ok
RUN
CITY            STATE       ZIP
DENVER,         COLORADO    80211
Ok
```

This program READs string and numeric data from the DATA statement in line 30.

## REM

| | |
|---|---|
| Syntax: | REM <remark> |
| Purpose: | To allow explanatory remarks to be inserted in a program. |

<!-- ===== scan page 084 (printed 4-70) - type:mixed ===== -->

Remarks:
: REM statements are not executed but are output exactly as entered when the program is listed.

  REM statements may be branched into (from a GOTO or GOSUB statement), and execution will continue with the first executable statement after the REM statement.

  Remarks may be added to the end of a line by preceding the remark with a single quotation mark instead of :REM.

Example:

```
        .
        .
        .
120 REM CALCULATE AVERAGE VELOCITY
130 FOR I=1 TO 20
140 SUM=SUM + V(I)
        .
        .
        .

or

        .
        .
        .
120 FOR I=1 TO 20 'CALCULATE AVERAGE VELOCITY
130 SUM=SUM+V(I)
140 NEXT I
        .
        .
        .
```

# RENUM

Syntax:
: RENUM [[<new number>][,[<old number>][,<increment>]]]

Purpose:
: To renumber program lines.

Remarks:
: <new number> is the first line number to be used in the new sequence. The default is 10. <old number> is the line in the current program where renumbering is to begin. The default is the first line of the program. <increment> is the increment to be used in the new sequence. The default is 10.

  RENUM also changes all line number references following GOTO, GOSUB, THEN, ON...GOTO, ON...GOSUB and ERL statements to reflect the new line numbers. If a nonexistent line number appears after one of these statements, the error message "Undefined line xxxxx in yyyyy" is printed.

4-70

<!-- ===== scan page 085 (printed 4-71) - type:text ===== -->

The incorrect line number reference (xxxxx) is not changed by RENUM, but line number yyyyy may be changed.

| | |
|---|---|
| NOTE: | RENUM cannot be used to change the order of program lines (for example, RENUM 15,30 when the program has three lines numbered 10, 20 and 30) or to create line numbers greater than 65529. An "Illegal function call" error will result. |

Examples:

```
RENUM                Renumbers the entire program. The
                     first new line number will be 10. Lines
                     will increment by 10.

RENUM 300,,50        Renumbers the entire program The
                     first new line number will be 300.
                     Lines will increment by 50.

RENUM 1000,900,20    Renumbers the lines from 900 up so
                     they start with line number 1000 and
                     increment by 20.
```

# RESET

| | |
|---|---|
| Syntax: | `RESET` |
| Purpose: | To reset the CP/M directory allocation information after you have switched disks. |
| Use: | The procedure for changing disks is as follows: First, type CLOSE to close any data files that may be open at the time. Then, remove the old disk and insert the new disk. Finally, *after* you have inserted the new disk, type RESET. Failure to follow this procedure when changing disks may cause loss of data, resulting in a "Disk Read Only" error. |

# RESTORE

| | |
|---|---|
| Syntax: | `RESTORE [<line number>]` |
| Purpose: | To allow DATA statements to be reread from a specified line. |
| Remarks: | After a RESTORE statement is executed, the next READ statement accesses the first item in the first DATA statement in the program. If <line number> is specified, the next READ statement accesses the first item in the specified DATA statement. |
| Example: | `10 READ A,B,C`<br>`20 RESTORE` |

<!-- ===== scan page 086 (printed 4-72) - type:mixed ===== -->

```
30 READ D,E,F
40 DATA 57, 68, 79
        .
        .
        .
```

# RESUME

| | |
|---|---|
| Syntax: | `RESUME`<br>`RESUME 0`<br>`RESUME NEXT`<br>`RESUME <line number>` |
| Purpose: | To continue program execution after an error recovery procedure has been performed. |
| Remarks: | Any one of the four formats shown above may be used, depending upon where execution is to resume: |

| | |
|---|---|
| `RESUME`<br>or<br>`RESUME 0` | Execution resumes at the statement which caused the error. |
| `RESUME NEXT` | Execution resumes at the statement immediately following the one which caused the error. |
| `RESUME <line number>` | Execution resumes at `<line number>`. |

A RESUME statement that is not in an error trap routine causes a "RESUME without error" message to be printed.

| | |
|---|---|
| Example: | `10 ON ERROR GOTO 900`<br>`        .`<br>`        .`<br>`        .`<br>`900 IF (ERR=230)AND(ERL=90) THEN PRINT "TRY`<br>`AGAIN":RESUME 80`<br>`        .`<br>`        .`<br>`        .` |

**NOTE THAT THIS STATEMENT IS USED DIFFERENTLY IN MBASIC THAN IN APPLESOFT.**

# RUN

| | |
|---|---|
| Syntax 1: | `RUN [<line number>]` |
| Purpose: | To execute the program currently in memory. |

<!-- ===== scan page 087 (printed 4-73) - type:mixed ===== -->

Remarks:
: If `<line number>` is specified, execution begins on that line. Otherwise, execution begins at the lowest line number. BASIC-80 always returns to command level after a RUN is executed.

Example:
: ```
RUN
```

Syntax 2:
: ```
RUN <filename>[,R]
```

Purpose:
: To load a file from disk into memory and run it.

Remarks:
: `<filename>` is the name used when the file was SAVEd. (With CP/M the default extension .BAS is supplied.)

  RUN closes all open files and deletes the current contents of memory before loading the designated program. However, with the "R" option, all data files remain OPEN.

Example:
: ```
RUN "NEWFIL",R
```
  See also Appendix B.

## SAVE

Syntax:
: ```
SAVE <filename>[,A | ,P]
```

Purpose:
: To save a program file on disk.

Remarks:
: `<filename>` is a quoted string with the default extension .BAS. If `<filename>` already exists, the file will be written over.

  Use the A option to save the file in ASCII format. Otherwise, BASIC saves the file in a compressed binary format. ASCII format takes more space on the disk, but some disk access requires that files be in ASCII format. For instance, the MERGE command requires an ASCII format file, and some operating system commands such as LIST may require an ASCII format file.

  In addition, programs written in 5.0 BASIC that you wish to transfer to your Apple SoftCard system must be saved in ASCII format.

  Use the P option to protect the file by saving it in an encoded binary format. When a protected file is later RUN (or LOADed), any attempt to list or edit it will fail.

Examples:
: ```
SAVE"COM2",A
SAVE"PROG",P
```
  See also Appendix B.

4-73

<!-- ===== scan page 088 (printed 4-74) - type:text ===== -->

# STOP

| | |
|---|---|
| Syntax: | `STOP` |
| Purpose: | To terminate program execution and return to command level. |
| Remarks: | STOP statements may be used anywhere in a program to terminate execution. When a STOP is encountered, the following message is printed: |

```
    Break in line nnnnn
```

Unlike the END statement, the STOP statement does not close files.

BASIC-80 always returns to command level after a STOP is executed. Execution is resumed by issuing a CONT command (see CONT).

| | |
|---|---|
| Example: | |

```
10 INPUT A,B,C
20 K=A↑2*5.3:L=B↑3/.26
30 STOP
40 M=C*K+100:PRINT M
RUN
? 1,2,3
BREAK IN 30
Ok
PRINT L
 30.7692
Ok
CONT
 115.9
Ok
```

# SWAP

| | |
|---|---|
| Syntax: | `SWAP <variable>,<variable>` |
| Purpose: | To exchange the values of two variables. |
| Remarks: | Any type variable may be SWAPped (integer, single precision, double precision, string), but the two variables must be of the same type or a "Type mismatch" error results. |

| | |
|---|---|
| Example: | |

```
LIST
10 A$=" ONE  ":B$=" ALL  ":C$="FOR"
20 PRINT A$ C$ B$
30 SWAP A$, B$
40 PRINT A$ C$ B$
```

<!-- ===== scan page 089 (printed 4-75) - type:mixed ===== -->

```
RUN
Ok
 ONE FOR ALL
 ALL FOR ONE
Ok
```

## SYSTEM

| | |
|---|---|
| Syntax: | `SYSTEM` |
| Purpose: | To close all files and return to CP/M |
| Remarks: | You cannot use Control-C to return to CP/M; it always returns to BASIC. |
| Example: | `SYSTEM`<br>`A>` |

## TEXT

| | |
|---|---|
| Syntax: | `TEXT` |
| Purpose: | To reset the screen to normal full Apple text mode (24 lines x 40 characters) from low-resolution graphics (in either MBASIC or GBASIC) or high-resolution graphics (GBASIC only). |
| Remarks: | TEXT will clear the screen if it is used to return from low-resolution graphics. It will not clear the screen from high-resolution graphics.<br><br>If used while in Text mode, TEXT has the same effect as VTAB 24. |
| Example: | (see below) |

```
10 HGR
20 COLOR=5
30 VLIN 24,30 AT 35
40 TEXT
50 PRINT "THIS IS A VERTICAL LINE"
```

## TRACE/NOTRACE

| | |
|---|---|
| Syntax: | `TRACE`<br>`NOTRACE` |
| Purpose: | To trace the execution of program statements. |
| Remarks: | As an aid in debugging, the TRACE statement (executed in either the direct or indirect mode) enables a trace flag that prints each line number of the program as it is executed. The numbers appear enclosed in square brackets. The trace flag is disabled with the NOTRACE statement (or when a NEW command is executed). |

4-75

<!-- ===== scan page 090 (printed 4-76) - type:mixed ===== -->

Example:

```
TRACE
Ok
LIST
10 K=10
20 FOR J=1 TO 2
30 L=K + 10
40 PRINT J;K;L
50 K=K+10
60 NEXT
70 END
Ok
RUN
[10][20][30][40] 1  10  20
[50][60][30][40] 2  20  30
[50][60][70]
Ok
NOTRACE
Ok
```

## VLIN

Syntax:
: VLIN \<y1 coordinate\>, \<y2 coordinate\> AT \<x coordinate\>
where \<y1 coordinate\> and \<y2 coordinate\> are integers in the range 0-47 and \<x coordinate\> is an integer in the range 0-39

Purpose:
: In low-resolution graphics mode, to draw a vertical line from the point at (x,y1) to the point at (x,y2).

Remarks:
: \<y1 coordinate\> must be less than or equal to \<y2 coordinate\>.

  If any of the coordinates are not in the required range as specified above, an ILLEGAL FUNCTION CALL error results.

  The color of the line is determined by the most recent COLOR statement.

  The VLIN statement normally draws a line composed of dots from y1 to y2 at the horizontal coordinate x. However, if used when in Text mode, or when in mixed graphics and text mode with y2 in the range 40-47, the part of the line that falls in the text area will be displayed as a line of characters.

Example:

```
10 GR
20 COLOR=3
30 VLIN 20,45 AT 12
```

<!-- ===== scan page 091 (printed 4-77) - type:text ===== -->

# VTAB

| | |
|---|---|
| Syntax: | `VTAB <screen line number>` |
| Purpose: | To move the cursor to the line on the screen that corresponds to the specified `<screen line number>`. |
| Remarks: | The first line (top line) on the screen is line 1; the last line or bottom line on the screen is line 24. |

VTAB uses absolute moves. For instance, if the cursor was on line 10 of the screen, then the command VTAB 13 was executed, the cursor would be moved to line 13, not line 23.

If a `<screen line number>` greater than 24 is specified, it will be treated modulo 24. The command VTAB 26 would place the cursor on screen line 2. If a `<screen line number>` greater than 255 is specified, it results in an ILLEGAL FUNCTION CALL error.

VTAB can move the cursor either up or down.

When used with an external terminal, VTAB sends a "cursor address" character sequence to terminals that address this feature.

| | |
|---|---|
| Example: | `10 VTAB 12: PRINT "MIDDLE OF SCREEN"` |

# WAIT

| | |
|---|---|
| Syntax: | `WAIT <address>, I[,J]`<br>where I and J are integer expressions |
| Purpose: | To suspend program execution while monitoring the status of an address. |
| Remarks: | The WAIT statement causes execution to be suspended until a specified address develops a specified bit pattern. The data read at the port is exclusive OR'ed with the integer expression J, and then AND'ed with I. If the result is zero, BASIC-80 loops back and reads the data at the address again. If the result is nonzero, execution continues with the next statement. If J is omitted, it is assumed to be zero |
| CAUTION: | It is possible to enter an infinite loop with the WAIT statement, in which case it will be necessary to manually restart the machine. |

```
Example:    100 WAIT &HE000,128
            200 PRINT "KEYPRESS!":GOTO 100
```

<!-- ===== scan page 092 (printed 4-78) - type:mixed ===== -->

# WHILE...WEND

| | |
|---|---|
| Syntax: | `WHILE <expression>` <br> `.` <br> `.` <br> `[<loop statements>]` <br> `.` <br> `.` <br> `WEND` |
| Purpose: | To execute a series of statements in a loop as long as a given condition is true. |
| Remarks: | If `<expression>` is not zero (i.e., true), `<loop statements>` are executed until the WEND statement is encountered. BASIC then returns to the WHILE statement and checks `<expression>`. If it is still true, the process is repeated. If it is not true, execution resumes with the statement following the WEND statement. |
| | WHILE/WEND loops may be nested to any level. Each WEND will match the most recent WHILE. An unmatched WHILE statement causes a "WHILE without WEND" error, and an unmatched WEND statement causes a "WEND without WHILE" error. |
| Example: | (see below) |

```
90 'BUBBLE SORT ARRAY A$
100 FLIPS=1 'FORCE ONE PASS THRU LOOP
110 WHILE FLIPS
115         FLIPS=0
120         FOR I=1 TO J-1
130                 IF A$(I)>A$(I+1) THEN
                            SWAP A$(I),A$(I+1):FLIPS=1
140         NEXT I
150 WEND
```

# WIDTH

| | |
|---|---|
| Syntax 1: | `WIDTH [LPRINT] <line width>` |
| Purpose 1: | To set the printed line width in number of characters for the terminal or line printer. |
| Syntax 2: | `WIDTH [<line width>],[<screen height>]` |
| Purpose 2: | To set the printed line width in number of characters and/or screen height in number of lines for the terminal. |

<!-- ===== scan page 093 (printed 4-79) - type:text ===== -->

Remarks: `<line width>` must be an integer in the range 15-255. `<screen height>` must be an integer in the range 1-24. If you are using 40-column Apple video, the default line length is 40, and the default screen height is 24. If you are using an external terminal with 80 columns, the default line width is 80 and the default screen height is 24.

In Syntax 1, if the LPRINT option is omitted, the line width is set at the terminal. If LPRINT is included, the line width is set at the line printer.

In Syntax 2, one or both of the parameters may be specified, but at least one must be specified.

If `<line width>` is 255, the line width is "infinite," that is, BASIC never inserts a carriage return. However, the position of the cursor or the print head, as given by the POS or LPOs function, returns to zero after position 255. Ok

# WRITE

Syntax:
```
WRITE [<list of expressions>]
```

Purpose: To output data at the terminal.

Remarks: If `<list of expressions>` is omitted, a blank line is output. If `<list of expressions>` is included, the values of te expressions are output at the terminal. The expressions in the list may be numeric and/or string expressions, and they must be separated by commas.

When the printed items are output, each item will be separated from the last by a comma. Printed strings will be delimited by quotation marks. After the last item in the list is printed, BASIC inserts a carriage return/line feed.

WRITE outputs numeric values using the same format as the PRINT statement. (See PRINT.)

Example:
```
10  A=80:B=90:C$=THAT'S ALL
20  WRITE A,B,C$
RUN
 80, 90,"THAT'S ALL"
Ok
```

# WRITE#

Syntax:
```
WRITE# <file number>,<list of expressions>
```

<!-- ===== scan page 094 (printed 4-80) - type:text ===== -->

**Purpose:** To write data to a sequential file.

**Remarks:** `<file number>` is the number under which the file was OPENed in "O" mode. The expressions in the list are string or numeric expressions, and they must be separated by commas.

The difference between WRITE# and PRINT# is that WRITE# inserts commas between the items as they are written to disk and delimits strings with quotation marks. Therefore, it is not necessary for the user to put explicit delimiters in the list. A carriage return/line feed sequence is inserted after the last item in the list is written to disk.

WRITE#, PRINT#, and PRINT# USING may also be used to put characters in the random file buffer before a PUT statement. In the case of WRITE#, BASIC-80 pads the buffer with spaces up to the carriage return. Any attempt to read or write past the end of the buffer causes a "Field overflow" error.

**Example:** Let `A$ = "CAMERA"` and `B$ = "93604-1"`. The statement:

```
WRITE# 1,A$,B$
```

writes the following image to disk:

```
"CAMERA","93604-1"
```

A subsequent INPUT# statement, such as:

```
INPUT# 1,A$,B$
```

would input "CAMERA" to A$ and "93604-1" to B$.

<!-- ===== scan page 095 (printed 4-81) - type:mixed ===== -->

# CHAPTER 4

# BASIC-80 FUNCTIONS

The intrinsic functions provided by BASIC-80 are presented in this chapter. The functions may be called from any program without further definition. Arguments to functions are always enclosed in parentheses. In the formats given for the functions in this chapter, the arguments have been abbreviated as follows:

| Argument | Meaning |
|---|---|
| X and Y | Represent any numeric expressions |
| I and J | Represent integer expressions |
| X and Y | Represent plotting coordinates for graphics functions. |
| X$ and Y$ | Represent string expressions |

If a floating point value is supplied where an integer is required, BASIC-80 will round the fractional portion and use the resulting integer.

> ## NOTE
>
> With the BASIC-80 interpreter, only integer and single precision results are returned by functions. Double precision functions are supported only by the BASIC compiler.

## ABS

Syntax:

```
ABS(X)
```

Action:    Returns the absolute value of the expression X.

Example:

```
PRINT ABS(7*(-5))
 35
Ok
```

## ASC

Syntax:

```
ASC(X$)
```

Action:    Returns a numerical value that is the ASCII code of the first character of the string X$. (See Appendix L for ASCII codes.) If X$ is null, an "Illegal function call" error is returned.

Example:

```
10 X$ = "TEST"
20 PRINT ASC(X$)
```

<!-- ===== scan page 096 (printed 4-82) - type:text ===== -->

```
RUN
 84
Ok
```

See the CHR$ function for ASCII-to-string conversion.

# ATN

| | |
|---|---|
| Syntax: | `ATN(X)` |
| Action: | Returns the arctangent of X in radians. Result is in the range -pi/2 to pi/2. The expression X may be any numeric type, but the evaluation of ATN is always performed in single precision. |
| Example: | (see below) |

```
10 INPUT X
20 PRINT ATN(X)
RUN
? 3
 1.24905
Ok
```

# BUTTON

| | |
|---|---|
| Syntax: | `BUTTON(I)` |
| Action: | Returns the current value of the push button on the game controller, specified by I. |
| Remarks: | I is in the range 0-3. |
| | The returned value is either 0, if the button is not currently depressed, or -1 if the button is currently depressed. |
| Example: | `10 IF BUTTON (0) THEN PRINT "BOOM"` |

# CDBL

| | |
|---|---|
| Syntax: | `CDBL(X)` |
| Action: | Converts X to a double precision number. |
| Example: | (see below) |

```
10 A = 454.67
20 PRINT A;CDBL(A)
RUN
 454.67   454.6700134277344
Ok
```

# CHR$

| | |
|---|---|
| Syntax: | `CHR$(I)` |

<!-- ===== scan page 097 (printed 4-83) - type:mixed ===== -->

| | |
|---|---|
| Action: | Returns a string whose one element has ASCII code I. x(ASCII codes are listed in Appendix G.) CHR$ is commonly used to send a special character to the terminal. For instance, the BEL character could be sent (CHR$(7)) as a preface to an error message, or a form feed could be sent (CHR$(12)) to clear a CRT screen and return the cursor to the home position. |
| Example: | (see below) |

```
PRINT CHR$(66)
B
Ok
```

See the ASC function for ASCII-to-numeric conversion.

## CINT

| | |
|---|---|
| Syntax: | CINT(X) |
| Action: | Converts X to an integer by rounding the fractional portion. If X is not in the range −32768 to 32767, an "Overflow" error occurs. |
| Example: | (see below) |

```
PRINT CINT(45.67)
 46
Ok
```

See the CDBL and CSNG functions for converting numbers to the double precision and single precision data type. See also the FIX and INT functions, both of which return integers.

## COS

| | |
|---|---|
| Syntax: | COS(X) |
| Action: | Returns the cosine of X in radians. The calculation of COS(X) is performed in single precision. |
| Example: | (see below) |

```
10 X = 2*COS(.4)
20 PRINT X
RUN
 1.84212
Ok
```

## CSNG

| | |
|---|---|
| Syntax: | CSNG(X) |
| Action: | Converts X to a single precision number. |
| Example: | (see below) |

```
10 A# = 975.3421#
20 PRINT A#; CSNG(A#)
```

4-83

<!-- ===== scan page 098 (printed 4-84) - type:text ===== -->

```
RUN
 975.3421  975.342
Ok
```

See the CINT and CDBL functions for converting numbers to the integer and double precision data types.

# CVI, CVS, CVD

| | |
|---|---|
| Syntax: | `CVI(<2-byte string>)`<br>`CVS(<4-byte string>)`<br>`CVD(<8-byte string>)` |
| Action: | Convert string values to numeric values. Numeric values that are read in from a random disk file must be converted from strings back into numbers. CVI converts a 2-byte string to an integer. CVS converts a 4-byte string to a single precision number. CVD converts an 8-byte string to a double precision number. |
| Example: | |

```
   .
   .
   .
70 FIELD #1,4 AS N$, 12 AS B$, ...
80 GET #1
90 Y=CVS(N$)
   .
   .
   .
```

See also MKI$, MKS$, MKD$, in this Chapter and Appendix B.

# EOF

| | |
|---|---|
| Syntax: | `EOF(<file number>)` |
| Action: | Returns −1 (true) if the end of a sequential file has been reached. Use EOF to test for end-of-file while INPUTting, to avoid "Input past end" errors. |

The EOF function may also be used with random files. If a GET is done past the end of the file, EOF will return -1. This may be used to find the size of a file using a binary search or other algorithm.

| | |
|---|---|
| Example: | |

```
10 OPEN "I",1,"DATA"
20 C=0
30 IF EOF(1) THEN 100
40 INPUT #1,M(C)
```

<!-- ===== scan page 099 (printed 4-85) - type:mixed ===== -->

```
50 C=C+1:GOTO 30
   .
   .
   .
```

## EXP

| | |
|---|---|
| Syntax: | `EXP(X)` |

**Action:** Returns e to the power of X. X must be <=87.3365. If EXP overflows, the "Overflow" error message is displayed, machine infinity with the appropriate sign is supplied as the result, and execution continues.

**Example:**

```
10 X = 5
20 PRINT EXP (X-1)
RUN
 54.5982
Ok
```

## FIX

| | |
|---|---|
| Syntax: | `FIX(X)` |

**Action:** Returns the truncated integer part of X. FIX(X) is equivalent to SGN(X)*INT(ABS(X)). The major difference between FIX and INT is that FIX does not return the next lower number for negative X.

**Examples:**

```
PRINT FIX(58.75)
 58
Ok

PRINT FIX(-58.75)
-58
Ok
```

## FRE

| | |
|---|---|
| Syntax: | `FRE(0)` |
| | `FRE(X$)` |

**Action:** Arguments to FRE are dummy arguments. FRE returns the number of bytes in memory not being used by BASIC-80.

FRE("") forces a garbage collection before returning the number of free bytes. BE PATIENT: garbage collection may take 1 to 1-1/2 minutes. BASIC will not initiate garbage collection until all free memory has been used up.

<!-- ===== scan page 100 (printed 4-86) - type:text ===== -->

Therefore, using FRE("") periodically will result in shorter delays for each garbage collection.

```
Example:    PRINT FRE(0)
              14542
            Ok
```

# HEX$

Syntax:     `HEX$(X)`

Action:     Returns a string which represents the hexadecimal value of the decimal argument. X is rounded to an integer before HEX$(X) is evaluated.

```
Example:    10 INPUT X
            20 A$ = HEX$(X)
            30 PRINT X "DECIMAL IS  " A$ "  HEXADECIMAL"
            RUN
            ? 32
             32 DECIMAL IS 20 HEXADECIMAL
            Ok
```

See the OCT$ function for octal conversion.

# INKEY$

Syntax:     `INKEY$`

Action:     Returns either a one character string containing a character read from the terminal or a null string if no character is pending at the terminal. No characters will be echoed and all characters are passed through to the program except for Control-C which terminates the program.

```
Example:    1000 'Timed Input Subroutine
            1010 RESPONSE$=""
            1020 FOR I%=1 TO TIMELIMIT%
            1030 A$=INKEY$ : IF LEN(A$)=0 THEN 1060
            1040 IF ASC(A$)=13 THEN TIMEOUT%=0 : RETURN
            1050 RESPONSE$=RESPONSE$+A$
            1060 NEXT I%
            1070 TIMEOUT%=1 : RETURN
```

# INPUT$

Syntax:     `INPUT$(X[,[#]Y])`

Action:     Returns a string of X characters, read from the terminal or from file number Y. If the terminal is used for input, no characters will be echoed and all control characters are

4-86

<!-- ===== scan page 101 (printed 4-87) - type:text ===== -->

passed through except Control-C, which is used to interrupt the execution of the INPUT$ function.

Example 1:

```
5 'LIST THE CONTENTS OF A SEQUENTIAL FILE IN HEXADECIMAL
10 OPEN"I",1,"DATA"
20 IF EOF(1) THEN 50
30 PRINT HEX$(ASC(INPUT$(1,#1)));
40 GOTO 20
50 PRINT
60 END
```

Example 2:

```
   .
   .
   .
100 PRINT "TYPE P TO PROCEED OR S TO STOP"
110 X$=INPUT$(1)
120 IF X$="P" THEN 500
130 IF X$="S" THEN 700 ELSE 100
   .
   .
   .
```

## INSTR

| | |
|---|---|
| Syntax: | `INSTR([I,]X$,Y$)` |
| Action: | Searches for the first occurrence of string Y in X$ and returns the position at which the match is found. Optional offset I sets the position for starting the search. I must be in the range 1 to 255. If I>LEN(X$) or if X$ is null or ifY$ cannot be found, INSTR returns 0. If Y$ is null, INSTR returns I or 1. X$ and Y$ may be string variables, string expressions or string literals. |

Example:

```
10 X$ = "ABCDEB"
20 Y$ = "B"
30 PRINT INSTR(X$,Y$);INSTR(4,X$,Y$)
RUN
 2   6
Ok
```

## INT

| | |
|---|---|
| Syntax: | `INT(X)` |
| Action: | Returns the largest integer <=X. |

Examples:

```
PRINT INT(99.89)
 99
Ok
```

<!-- ===== scan page 102 (printed 4-88) - type:mixed ===== -->

```
PRINT INT(-12.11)
-13
Ok
```

See the FIX and CINT functions which also return integer
values.

# LEFT$

| | |
|---|---|
| Syntax: | `LEFT$(X$,I)` |
| Action: | Returns a string comprised of the leftmost I characters of X$. I must be in the range 0 to 255. If I is greater than LEN(X$), the entire string (X$) will be returned. If I=0, the null string (length zero) is returned. |

Example:

```
10 A$ = "BASIC-80"
20 B$ = LEFT$(A$,5)
30 PRINT B$
BASIC
Ok
```

Also see the MID$ and RIGHT$ functions.

# LEN

| | |
|---|---|
| Syntax: | `LEN(X$)` |
| Action: | Returns the number of characters in X$. Non-printing characters and blanks are counted. |

Example:

```
10 X$ = "PORTLAND, OREGON"
20 PRINT LEN(X$)
 16
Ok
```

# LOC

| | |
|---|---|
| Syntax: | `LOC(<file number>)` |
| Action: | With random disk files, LOC returns the next record number to be used if a GET or PUT (without a record number) is executed. With sequential files, LOC returns the number of sectors (128 byte blocks) read from or written to the file since it was OPENed. |

Example:

```
200 IF LOC(1)>50 THEN STOP
```

# LOF

| | |
|---|---|
| Syntax: | `LOF(<file number>)` |

4-88

<!-- ===== scan page 103 (printed 4-89) - type:text ===== -->

| | |
|---|---|
| Action: | Returns the number of records present in the last extent read or written. If the file does not exceed one extent (128 records), then LOF returns the true length of the file. |
| Example: | `110 IF NUM%>LOF(1) THEN PRINT "INVALID ENTRY"` |

## LOG

| | |
|---|---|
| Syntax: | `LOG(X)` |
| Action: | Returns the natural logarithm of X. X must be greater than zero. |
| Example: | `PRINT LOG(45/7)`<br>`  1.86075`<br>`Ok` |

## LPOS

| | |
|---|---|
| Syntax: | `LPOS(X)` |
| Action: | Returns the current position of the line printer print head within the line printer buffer. Does not necessarily give the physical position of the print head. X is a dummy argument. |
| Example: | `100 IF LPOS(X)>60 THEN LPRINT CHR$(13)` |

## MID$

| | |
|---|---|
| Syntax: | `MID$(X$,I[,J])` |
| Action: | Returns a string of length J characters from X beginning with the Ith character. I and J must be in the range 0 to 255. If J is omitted or if there are fewer than J characters to the right of the Ith character, all rightmost characters beginning with the Ith character are returned. If I>LEN(X$), MID$ returns a null string. |
| Example: | (see listing below) |

```
LIST
10 A$="GOOD "
20 B$="MORNING EVENING AFTERNOON"
30 PRINT A$;MID$(B$,9,7)
Ok
RUN
GOOD EVENING
Ok
```

Also see the LEFT$ and RIGHT$ functions.

<!-- ===== scan page 104 (printed 4-90) - type:text ===== -->

# MKI$, MKS$, MKD$

| | |
|---|---|
| Syntax: | `MKI$(<integer expression>)` |
| | `MKS$(<single precision expression>)` |
| | `MKD$(<double precision expression>)` |

**Action:** Convert numeric values to string values. Any numeric value that is placed in a random file buffer with an LSET or RSET statement must be converted to a string. MKI$ converts an integer to a 2-byte string. MKS$ converts a single precision number to a 4-byte string. MKD$ converts a double precision number to an 8-byte string.

**Example:**

```
90  AMT=(K+T)
100 FIELD #1, 8 AS D$, 20 AS N$
110 LSET D$ = MKS$(AMT)
120 LSET N$ = A$
130 PUT #1
      .
      .
```

See also CVI, CVS, CVD, in this Chapter and Appendix B.

# OCT$

| | |
|---|---|
| Syntax: | `OCT$(X)` |

**Action:** Returns a string which represents the octal value of the decimal argument. X is rounded to an integer before OCT$(X) is evaluated.

**Example:**

```
PRINT OCT$(24)
 30
Ok
```

See the HEX$ function for hexadecimal conversion.

# PDL

| | |
|---|---|
| Syntax: | `PDL(I)` |

**Action:** Returns the current value, in the range 0-255, of the game control specified by I.

**Remarks:** I is an integer in the range 0-3.

The value of two game controls should not be read in consecutive instructions, as the reading from the first may affect the second. A delay such as 10 FOR X=1 TO 10:

<!-- ===== scan page 105 (printed 4-91) - type:mixed ===== -->

NEXT X between the two provides sufficient separation for a correct reading.

| | |
|---|---|
| Example: | `10 PRINT PDL(0): GOTO 10`<br>`RUN`<br>`0`<br>`23`<br>`79`<br>`100`<br>`190`<br>`255`<br>`C`<br>`BREAK IN`<br>`OK` |

## PEEK

| | |
|---|---|
| Syntax: | `PEEK(I)` |
| Action: | Returns the byte (decimal integer in the range 0 to 255) read from memory location I. I must be in the range 0 to 65536. PEEK is the complementary function to the POKE statement, See POKE, Chapter 3 |
| NOTE: | PEEKs and POKEs used in Applesoft and Integer BASIC will not work with BASIC-80 unless they are first converted to use Z-80 addresses. Refer to the 6502 To Z-80 memory map in the "Software and Hardware Details" section of this manual. |
| Example: | `A=PEEK(&H5A00)` |

## POS

| | |
|---|---|
| Syntax: | `POS(I)` |
| Action: | Returns the current cursor position. The leftmost position is 1. X is a dummy argument. |
| Example: | `IF POS(X)>60 THEN PRINT CHR$(13)` |

Also see the LPOS function.

## RIGHT$

| | |
|---|---|
| Syntax: | `RIGHT$(X$,I)` |
| Action: | Returns the rightmost I characters of string X$. If I=LEN(X$), returns X$. If I=0, the null string (length zero) is returned. |

4-91

<!-- ===== scan page 106 (printed 4-92) - type:mixed ===== -->

Example:

```
10 A$="DISK BASIC-80"
20 PRINT RIGHT$(A$,8)
RUN
BASIC-80
Ok
```

Also see the MID$ and LEFT$ functions.

## RND

Syntax:
: `RND[(X)]`

Action:
: Returns a random number between 0 and 1. The same sequence of random numbers is generated each time the program is RUN unless the random number generator is reseeded. (See RANDOMIZE.) However, X<0 always restarts the same sequence for any given X.

: X>0 or X omitted generates the next random number in the sequence. X=0 repeats the last number generated.

Example:

```
10 FOR I=1 TO 5
20 PRINT INT(RND*100);
30 NEXT
RUN
 24  30  31  51  5
Ok
```

## SCRN

Syntax:
: `SCRN(X,Y)`
: where X is an integer in the range 0-39 and Y is an integer in the range 0-47.

Action:
: Returns the color of the point at (X,Y).

Example:

```
10 GR
20 COLOR=13
30 PLOT 10,15
PRINT SCRN(10,15)
RUN
13
```

## SGN

Syntax:
: `SGN(X)`

Action:
: If X>0, SGN(X) returns 1. If X=0, SGN(X) returns 0. If X<0, SGN(X) returns -1.

4-92

<!-- ===== scan page 107 (printed 4-93) - type:text ===== -->

Example:

```
ON SGN(X)+2 GOTO 100,200,300 branches to 100 if
X   is negative, 200 if X is 0 and 300 if X is
positive.
```

## SIN

Syntax:

```
SIN(X)
```

Action:

Returns the sine of X in radians. SIN(X) is calculated in single precision. COS(X)=SIN(X+3.14159/2).

Example:

```
PRINT SIN(1.5)
 .997495
Ok
```

## SPACE$

Syntax:

```
SPACE$(X)
```

Action:

Returns a string of spaces of length X. The expression X is rounded to an integer and must be in the range 0 to 255.

Example:

```
10 FOR I = 1 TO 5
20 X$ = SPACE$(I)
30 PRINT X$;I
40 NEXT I
RUN
  1
   2
    3
     4
      5
Ok
```

Also see the SPC function.

## SPC

Syntax:

```
SPC(I)
```

Action:

Prints I blanks on the terminal. SPC may only be used with PRINT and LPRINT statements. I must be in the range 0 to 255.

Example:

```
PRINT "OVER" SPC(15) "THERE"
OVER                  THERE
Ok
```

Also see the SPACE$ function.

<!-- ===== scan page 108 (printed 4-94) - type:mixed ===== -->

## SQR

| | |
|---|---|
| Syntax: | `SQR(X)` |
| Action: | Returns the square root of X. X must be >=0. |

Example:

```
10 FOR X = 0 TO 25 STEP 5
20 PRINT X, SQR(X)
30 NEXT
RUN
 10        3.16228
 15        3.87298
 20        4.47214
 25        5
Ok
```

## STR$

| | |
|---|---|
| Syntax: | `STR$(X)` |
| Action: | Returns a string representation of the value of X. |

Example:

```
5 REM ARITHMETIC FOR KIDS
10 INPUT "TYPE A NUMBER";N
20 ON LEN(STR$(N)) GOSUB 30,100,200,300,400,500
   .
   .
   .
```

Also see the VAL function.

## STRING$

| | |
|---|---|
| Syntax: | `STRING$(I,J)`<br>`STRING$(I,X$)` |
| Action: | Returns a string of length I whose characters all have ASCII code J or the first character of X$. |

Example:

```
10 X$ = STRING$(10,45)
20 PRINT X$ "MONTHLY REPORT" X$
RUN
----------MONTHLY REPORT----------
Ok
```

## TAB

| | |
|---|---|
| Syntax: | `TAB(I)` |
| Action: | Spaces to position I on the terminal. If the current print position is already beyond space I, TAB goes to that posi-

<!-- ===== scan page 109 (printed 4-95) - type:text ===== -->

tion on the next line. Space 1 is the leftmost position, and the rightmost position is the width minus one. I must be in the range 1 to 255. TAB may only be used in PRINT and LPRINT statements.

Example:

```
10 PRINT "NAME" TAB(25) "AMOUNT" : PRINT
20 READ A$,B$
30 PRINT A$ TAB(25) B$
40 DATA "G. T. JONES","$25.00"
RUN
NAME                AMOUNT
G. T. JONES         $25.00
Ok
```

## TAN

Syntax:

```
TAN(X)
```

Action: Returns the tangent of X in radians. TAN(X) is calculated in single precision. If TAN overflows, the "Overflow" error message is displayed, machine infinity with the appropriate sign is supplied as the result, and execution continues.

Example:

```
10 Y = Q*TAN(X)/2
```

## USR

Syntax :

```
USR[<digit>](X)
```

Action: Calls the user's assembly language subroutine with the argument X. <digit> is in the range 0 to 9 and corresponds to the digit supplied with the DEF USR statement for that routine. If <digit> is omitted, USR0 is assumed. See Appendix C.

Example:

```
40 B = T*SIN(Y)
50 C = USR(B/2)
60 D = USR(B/3)
        .
        .
        .
```

## VAL

Syntax:

```
VAL(X$)
```

Action: Returns the numerical value of string X$. If the first character of X$ is not +, −, &, or a digit, VAL(X$)=0. VAL (X$)

4-95

<!-- ===== scan page 110 (printed 4-96) - type:text ===== -->

will, however, strip blanks, tabs, and linefeeds from the argument string.

Example:

```
10 READ NAME$,CITY$,STATE$,ZIP$
20 IF VAL(ZIP$)<90000 OR VAL(ZIP$)>96699 THEN
PRINT NAME$ TAB(25) "OUT OF STATE"
30 IF VAL(ZIP$)>=90801 AND VAL(ZIP$)<=90815 THEN
PRINT NAME$ TAB(25) "LONG BEACH"
            .
            .
            .
```

See the STR$ function for numeric to string conversion.

# VARPTR

| | |
|---|---|
| Syntax 1: | VARPTR(<variable name>) |
| Syntax 2: | VARPTR( # <file number>) |

Action: Syntax 1: Returns the address of the first byte of data identified with <variable name>. A value must be assigned to <variable name> prior to execution of VARPTR. Otherwise an "Illegal function call" error results. Any type variable name may be used (numeric, string, array), and the address returned will be an integer in the range 32767 to -32768. If a negative address is returned, add it to 65536 to obtain the actual address.

VARPTR is usually used to obtain the address of a variable or array so it may be passed to an assembly language subroutine. A function call of the form VARPTR(A(0)) is usually specified when passing an array, so that the lowest-addressed element of the array is returned.

NOTE: All simple variables should be assigned before calling VARPTR for an array, because the addresses of the arrays change whenever a new simple variable is assigned.

Syntax 2: Returns the starting address of the disk I/O xbuffer assigned to <file number>.

For random files, VARPTR ( # <file number>) returns the address of the FIELD buffer

Example: `100 X=USR(VARPTR(Y))`

# VPOS

Syntax: `VPOS(I)`

Action: Returns the current vertical position of the cursor. The topmost position is 1. X is a dummy argument.

4-96

<!-- ===== scan page 111 (printed 4-97) - type:code ===== -->

Example:

```
10  PRINT "NOW YOU SEE IT."
20  FOR T=0 TO 1000: NEXT T
30  VTAB VPOS(0) -1
40  PRINT "NOW YOU DON'T "
```

<!-- ===== scan page 112 (printed 4-98) - type:text ===== -->

# CHAPTER 5

# HIGH-RESOLUTION GRAPHICS: GBASIC

## INITIALIZATION

GBASIC is the CP/M version of Microsoft BASIC that includes high-resolution graphics capability in addition to all of the features of MBASIC. It is supplied only on the 16-sector disk. The name of the file is GBASIC.COM.

To load and run GBASIC, simply bring up the CP/M operating system in the usual manner (See "Installation and Operations Manual)." After the A> prompt appears, type:

```
GBASIC
```

and press the RETURN key. In a few seconds, a copyright notice will appear, indicating GBASIC is ready for your command.

This initialization process sets at 3 the number of files that may be open at any one time during the execution of a BASIC program (see /F option below), allows all memory up to the start of FDOS in CP/M to be used (see /M option below) and sets maximum record size at 128.

The command line format below allows you to set these options and/or automatically RUN any program after initialization:

```
GBASIC <filename> [/F:<number of files>] [/M:<highest
memory location>][/S:<maximum record size>] Press RETURN
```

The <filename> option allows you to RUN a program automatically after initialization is complete. A default extension of .BAS is used if none is supplied and the filename is less than nine characters long. This allows BASIC programs to be executed in batch mode using the SUBMIT facility of CP/M. Such programs should include the SYSTEM statement (See Chapter 3) to return to CP/M when they have finished, allowing the next program in the batch stream to execute.

The /F:<number of files> option sets the number of disk data files that may be open at any one time during the execution of a BASIC program. Each file data block allocated in this fashion requires 166 bytes plus 128 (or number specified by /S:) bytes of memory. If the /F option is omitted,

<!-- ===== scan page 113 (printed 4-99) - type:text ===== -->

the number of files defaults to 3. \<number of files\> may be either decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

The /M:\<highest memory location\> option sets the highest memory location that will be used by MBASIC. In some cases, it is desirable to set the amount of memory well below the CP/M's FDOS to reserve space for assembly language subroutines. In all cases, highest memory location should be below the start of FDOS (whose address is contained in locations 6 and 7). If the /M option is omitted, all memory up to the start of FDOS is used. The \<highest memory location\> number may be decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

The /S:\<maximum record size\> option sets the maximum size to be allowed by random files. Any integer may be specified, including integers larger than 128. If the /S option is omitted, maximum record size is set at 128.

When BASIC-80 is initialized, the system will reply:

```
BASIC-80 Version 5.xx
(Apple CP/M Version)
Copyright 1980 (c) by Microsoft
Created: dd-Mmm-yy
xxxx Bytes free
Ok
```

Here are a few examples of the different initialization options:

```
A>GBASIC PAYROLL.BAS              Use all memory and 3 files; load
                                  and execute PAYROLL.BAS

A>GBASIC INVENT/F:6               Use all memory and 6 files; load
                                  and execute INVENT.BAS

A>GBASIC /M:32768                 Use first 32K of memory and 3
                                  files

A>GBASIC DATACK/F:2/M:&H9000      Use first 36K of memory, 2 files
                                  and execute DATACK.BAS
```

All other information regarding GBASIC, with the exception of high-resolution graphics commands, is the same as that for MBASIC and can be found in Chapters 1-4. High-resolution graphics are the added attraction of GBASIC and are described below:

## HGR High-Resolution Statements and Commands

\<color number\> is an integer in the range 0-12.

```
Syntax:    HGR <screen number>, <color number>
           where <screen number> is an integer in the range 0-3 and
           <color number> is an integer in the range 0-7.

Purpose:   To initialize high-resolution graphics mode.
```

<!-- ===== scan page 114 (printed 4-100) - type:mixed ===== -->

Remarks: `<screen number>` specifies the display mode to be used as follows:

| Screen # | Clear Screen | Screen Mode |
|----------|--------------|-------------|
| 0 | yes | 280 x 160 graphics + 4 lines text |
| 1 | yes | 280 x 192 graphics, no lines text |
| 2 | no | 280 x 160 graphics + 4 lines text |
| 3 | no | 280 x 192 graphics, no lines text |

If `<screen number>` is not specified, `<screen number>` = 0 is assumed.

`<color number>` specifies the color to be used and is optional. If `<color number>` is not specified, color is set to 0. When used with modes 0 and 1 above, `<color number>` will fill the screen with the color specified by `<color number>`. See HCOLOR for a list of color names and their associated numbers.

Examples:

```
10 HGR        Same as Applesoft HGR statement
10 HGR 1,2    Fill screen with violet, set 280 x 192 mode
10 HGR 3      Set 280 x 192 mode, don't clear screen
```

**NOTE THAT THIS STATEMENT CAN BE USED DIFFERENTLY IN GBASIC THAN IN APPLESOFT.**

# HCOLOR

Syntax: `HCOLOR=<color number>`
where `<color number>` is an integer in the range 0-12.

Purpose: To set the color for plotting in high resolution graphics mode.

Remarks: The colors available and their numbers are:

```
0 black    4 black     8 black1
1 green    5 orange    9 white1
2 violet   6 blue      10 black 2
3 white    7 white     11 white 2
                       12 reverse
```

**To distinguish between the different whites and blacks.** Numbers 0, 3, 4 and 7 plot a very fine line. Black1, white1, black2 and white2 (8, 9, 10 and 11) plot a larger dot or thicker line that is equal in size (width) with dots or lines plotted with green, violet, orange or blue. Black1 and whi-

4-100

<!-- ===== scan page 115 (printed 4-101) - type:text ===== -->

te1 should be used with green or violet if you want dots or lines of the same position and width. Black2 and white2 should be used with orange or blue.

If you are using a black and white monitor, just use 0, 3, 4 and 7.

\<color number> may be specified in the HGR statement (See HGR.) If is not specified in HGR, it is set to zero by HGR until another color is specified with the HCOLOR statement.

HCOLOR may be used in high-resolution graphics mode only.

Note that because of the way in which home TVs work, a high-resolution dot plotted with HCOLOR=3 (white) or HCOLOR=7 (white) will be white only if both (x,y) and (x+1,y) are plotted. If only (x,y) is plotted, the dot will be blue when x is even and green when x is odd.

## HPLOT

| | |
|---|---|
| Syntax 1: | `HPLOT [<x1>, <y1>] [TO <x2>, <y2> ... [TO <xn>, <yn>]]` |
| Purpose: | To plot a point or draw a line(s) on the high-resolution screen, using the points specified by (x1,y1), (x2,y2) etc. |
| Syntax 2: | `HPLOT TO <x2>, <y2>` |
| Purpose: | To draw a line from the last dot plotted to the point at (x2,y2). |
| Remarks: | In Syntax 1, HPLOT \<x1>, \<y1> plots a single point. |

HPLOT \<x1>, \<y1> TO \<x2>, \<y2> TO ... \<xn>, \<yn> plots a line starting a (x1, y1) and proceeding to each of the points specified. The plotted line may be extended from point to point in the same statement by specifying additional points, limited only by screen limits and the 239 character limit.

In Syntax 1, the color of the dot or line is determined by the most recent HCOLOR statement. If no color has been specified, the default color 0 will be assigned.

In Syntax 2, the color of the line is determined by the last HCOLOR executed. Syntax 2 cannot be used if no dot has previously been plotted.

HPLOT may be used in high-resolution graphics mode only.

4-101

<!-- ===== scan page 116 (printed 4-102) - type:text ===== -->

Example:

```
10 HGR
20 COLOR=2
30 HPLOT 24,125 TO 100,12 TO 270,1
```

# HSCRN

Syntax:    HSCRN (X,Y)

Action:    In high-resolution graphics mode, returns -1 if a dot exists at point (X,Y).

Remarks:   Note that unlike SCRN, HSCRN does not recognize color.

X must be in the range 0-279 and Y must be in the range 0-191.

Example:

```
10 HGR: COLOR=3
20 HPLOT 0,100 TO 279,100
30 PRINT HSCRN (46,100), HSCRN (20,20)
RUN
-1              0
```

<!-- ===== scan page 117 (printed 4-103) - type:text ===== -->

# APPENDIX A

# New Features in BASIC-80, Release 5.0

The execution of BASIC programs written under Microsoft BASIC, release 4.51 and earlier may be affected by some of the new features in release 5.0. Before attempting to run such programs, check for the following:

1. New reserved words: CALL, CHAIN, COMMON, WHILE, WEND, WRITE, OPTION BASE, RANDOMIZE.

2. Conversion from floating point to integer values results in rounding, as opposed to truncation. This affects not only assignment statements (e.g., I%=2.5 results in I%=3), but also affects function and statement evaluations (e.g., TAB(4.5) goes to the 5th position, A(1.5) yields A(2), and X=11.5 MOD 4 yields 0 for X).

3. The body of a FOR...NEXT loop is skipped if the initial value of the loop times the sign of the step exceeds the final value times the sign of the step.

4. Division by zero and overflow no longer produce fatal errors. See Chapter 2.

5. The RND function has been changed so that RND with no argument is the same as RND with a positive argument. The RND function generates the same sequence of random numbers with each RUN, unless RANDOMIZE is used. See RND in Chapters 3 and 4.

6. The rules for PRINTing single precision and double precision numbers have been changed. See PRINT, in Chapter 3.

7. String space is allocated dynamically, and the first argument in a two-argument CLEAR statement sets the end of memory. The second argument sets the amount of stack space. See CLEAR, Chapter 3.

8. Responding to INPUT with too many or too few items, or with the wrong type of value (numeric instead of string, etc.), or with a carriage return causes the message "?Redo from start" to be printed. No assignment of input values is made until an acceptable response is given.

9. There are two new field formatting characters for use with PRINT USING. An ampersand is used for variable length string

<!-- ===== scan page 118 (printed 4-104) - type:mixed ===== -->

10. If the expression supplied with the WIDTH statement is 255, BASIC uses an "infinite" line width, that is, it does not insert carriage returns. WIDTH LPRINT may be used to set the line width at the line printer. See WIDTH, Chapter 3.

11. The at-sign and underscore are no longer used as editing characters.

12. Variable names are significant up to 40 characters and can contain embedded reserved words. However, reserved words must now be delimited by spaces. To maintain compatibility with earlier versions of BASIC, spaces will be automatically inserted between adjoining reserved words and variable names. WARNING: This insertion of spaces may cause the end of a line to be truncated if the line length is close to 255 characters.

13. BASIC programs may be saved in a protected binary format. See SAVE, Chapter 3.

14. Reserved words must be preceded by and followed by a space.

## Loading and Saving HIRES Pictures with GBASIC

Below is a short GBASIC program demonstrating the use of random disk I/O statements to load and save Hires Pictures to the disk. Loading and saving Hires pictures in this way is as fast as or faster than using Apple DOS BSAVE and BLOAD statements. This program also creates some pretty Hires pictures.

```
10 DEFINT A-Z:DEFSNG A,F,R
20 DIM X(23),Y(23)
30 GOTO 4000


1000 HGR 1,3:HCOLOR=0
1010 HPLOT 140,96
1020 FOR A=0 TO 3.14159*20 STEP .05
1030 R=SIN(A*2.9)
1040 HPLOT TO 140+107*R*COS(A),96+95*R*SIN(A)
1050 NEXT
1060 HGR 1,12:FOR T=0 TO 500:NEXT:HGR 1,12
1070 GET A$:GOTO 4000


2000 N=INT(RND*14)+13
2010 PI=6.28318/N:FOR I=0 TO N-1:A=PI*I
2020 X(I)=COS(A)*107+140:Y(I)=SIN(A)*95+96
2030 NEXT
2040 HGR 1,0:HCOLOR=3
2050 FOR I=0 TO N-1:FOR J=I TO N-1:HPLOT X(I),Y(I) TO X(J),Y(J):NEXT:NEXT
2060 HGR 1,12:FOR T=0 TO 200:NEXT T:HGR 1,12
2070 GET A$:GOTO 4000
```

<!-- ===== scan page 119 (printed 4-105) - type:mixed ===== -->

```basic
3000 HOME:VTAB 4
3010 ON ERROR GOTO 3020:FILES "*.PIC":PRINT:PRINT:ON ERROR GOTO 0
3020 PRINT "Load or Save (L/S)? ";:GET D$
3030 IF D$="S" OR D$="s" THEN D=1:HGR 3:PRINT "Save"
        ELSE D=0:HGR 1,0:PRINT "Load"
3040 PRINT:INPUT "File name? ",F$:IF F$="" THEN 3040
3050 IF INSTR(F$,".")=0 THEN F$=F$+".PIC"

3060 OPEN "R",1,F$
3070 FIELD#1,128 AS A$:B$=A$
3080 H=16:L=0:P=VARPTR(B$)+1
3090 FOR I=1 TO 64
3100 POKE P,L:POKE P+1,H
3110 IF D=1 THEN LSET A$=B$:PUT 1 ELSE GET 1:LSET B$=A$
3120 L=L XOR 128:IF L=0 THEN H=H+1
3130 NEXT:CLOSE
3140 FOR T=0 TO 1500:NEXT T


4000 TEXT:HOME:VTAB 4:PRINT TAB(5)"*** HIRES GRAPHICS DEMO ***"
4010 VTAB 7:PRINT TAB(5)"1. Rose":PRINT:PRINT TAB(5)"2. Polygon":PRINT
4020 PRINT TAB(5)"3. Load/Save Hires Picture":PRINT:PRINT TAB(5)"Which - ";
4030 A$=INPUT$(1):A=VAL(A$):IF A>3 OR A<1 THEN 4030
4040 PRINT A$:PRINT:PRINT TAB(5)"Working...";
4050 ON A GOTO 1000,2000,3000
```

NOTE: Hires pictures transferred to CP/M from Apple DOS with APDOS will not load correctly with the above program. The first four bytes of these files contain the destination address and length of the picture, which must be removed. This will also save 1K of disk space. Follow the procedure below to fix transferred Apple DOS pictures (you type the *underlined* characters):

```
DDT
DDT VERS 2.2
Ifilename.ext
RFC
M200,2200,100
G0
A>SAVE 32 filename.ext
```

<!-- ===== scan page 120 (printed 4-106) - type:text ===== -->

# APPENDIX B

# BASIC-80 Disk I/O

Disk I/O procedures for the beginning BASIC-80 user are examined in this appendix. If you are new to BASIC-80 or if you're getting disk related errors, read through these procedures and program examples to make sure you're using all the disk statements correctly.

Wherever a filename is required in a disk command or statement, use a name that conforms to your operating system's requirements for filenames. The CP/M operating system will append a default extension .BAS to the filename given in a SAVE, RUN, MERGE or LOAD command.

## PROGRAM FILE COMMANDS

Here is a review of the commands and statements used in program file manipulation.

| Command | Description |
|---|---|
| `SAVE "filename"[,A]` | Writes to disk the program that is currently residing in memory. Optional A writes the program as a series of ASCII characters. (Otherwise, BASIC uses a compressed binary format.) |
| `LOAD "filename"[,R]` | Loads the program from disk into memory. Optional R runs the program immediately. LOAD always deletes the current contents of memory and closes all files before LOADing. If R is included, however, open data files are kept open. Thus programs can be chained or loaded in sections and access the same data files. |
| `RUN "filename"[,R]` | RUN "filename" loads the program from disk into memory and runs it. RUN deletes the current contents of memory and closes all files before loading the program. If the R option is included, however, all open data files are kept open. |
| `MERGE "filename"` | Loads the program from disk into memory but does not delete the current contents of memory. The program line numbers on disk are merged with the line numbers in memory. If two lines have the same number, only the line from the disk program is saved. After a MERGE com- |

<!-- ===== scan page 121 (printed 4-107) - type:mixed ===== -->

| Command | Description |
| --- | --- |
| | mand, the "merged" program resides in memory, and BASIC returns to command level. |
| KILL "filename" | Deletes the file from the disk. "filename" may be a program file, or a sequential or random access data file. |
| NAME | To change the name of a disk file, execute the NAME statement, NAME "oldfile" AS "newfile". NAME may be used with program files, random files, or sequential files. |

## PROTECTED FILES

If you wish to save a program in an encoded binary format, use the "Protect" option with the SAVE command. For example:

```
SAVE "MYPROG",P
```

A program saved this way cannot be listed or edited.

# DISK DATA FILES - SEQUENTIAL AND RANDOM I/O

There are two types of disk data files that may be created and accessed by a BASIC-80 program: sequential files and random access files.

## Sequential Files

Sequential files are easier to create than random files but are limited in flexibility and speed when it comes to accessing the data. The data that is written to a sequential file is stored, one item after another (sequentially), in the order it is sent and is read back in the same way.

The statements and functions that are used with sequential files are:

```
OPEN       PRINT#           INPUT#           WRITE#
           PRINT# USING     LINE INPUT#

CLOSE      EOF      LOC
```

The following program steps are required to create a sequential file and access the data in the file:

1. OPEN the file in "O" mode.

   ```
   OPEN "O",# 1,"DATA"
   ```

2. Write data to the file using the PRINT# statement. (WRITE# may be used instead.)

   ```
   PRINT# 1,A$;B$;C$
   ```

3. To access the data in the file, you must CLOSE the file and reOPEN it in "I" mode.

   ```
   CLOSE  # 1
   OPEN "I",# 1,"DATA"
   ```

<!-- ===== scan page 122 (printed 4-108) - type:mixed ===== -->

4. Use the INPUT # statement to read data from the sequential file into the program.

```
INPUT # 1,X$,Y$,Z$
```

Program B-1 is a short program that creates a sequential file, "DATA", from information you input at the terminal.

```
10 OPEN "O",# 1,"DATA"
20 INPUT "NAME";N$
25 IF N$="DONE" THEN END
30 INPUT "DEPARTMENT";D$
40 INPUT "DATE HIRED";H$
50 PRINT# 1,N$;",";D$;",";H$
60 PRINT:GOTO 20
RUN

NAME? MICKEY MOUSE
DEPARTMENT? AUDIO/VISUAL AIDS
DATE HIRED? 01/12/72

NAME? SHERLOCK HOLMES
DEPARTMENT? RESEARCH
DATE HIRED? 12/03/65

NAME? EBENEEZER SCROOGE
DEPARTMENT? ACCOUNTING
DATE HIRED? 04/27/78

NAME? SUPER MANN
DEPARTMENT? MAINTENANCE
DATE HIRED? 08/16/78

NAME? etc.
```

PROGRAM B-1 - CREATE A SEQUENTIAL DATA FILE

Now look at Program B-2. It accesses the file "DATA" that was created in Program B-1 and displays the name of everyone hired in 1978.

```
10 OPEN "I",# 1,"DATA"
20 INPUT# 1,N$,D$,H$
30 IF RIGHT$(H$,2)="78" THEN PRINT N$
40 GOTO 20
RUN
EBENEEZER SCROOGE
SUPER MANN
```

<!-- ===== scan page 123 (printed 4-109) - type:text ===== -->

```
Input past end in 20
Ok
```

## PROGRAM B-2 - ACCESSING A SEQUENTIAL FILE

Program B-2 reads, sequentially, every item in the file. When all the data has been read, line 20 causes an "Input past end" error. To avoid getting this error, insert line 15 which uses the EOF function to test for end-of-file:

```
15  IF EOF(1) THEN END
```

and change line 40 to GOTO 15.

A program that creates a sequential file can also write formatted data to the disk with the PRINT # USING statement. For example, the statement

```
PRINT#1,USING"####.##,";A,B,C,D
```

could be used to write numeric data to disk without explicit delimiters. The comma at the end of the format string serves to separate the items in the disk file.

The LOC function, when used with a sequential file, returns the number of sectors that have been written to or read from the file since it was OPENed. A sector is a 128-byte block of data.

## Adding Data To A Sequential File

If you have a sequential file residing on disk and later want to add more data to the end of it, you cannot simply open the file in "O" mode and start writing data. As soon as you open a sequential file in "O" mode, you destroy its current contents. The following procedure can be used to add data to an existing file called "NAMES".

1. OPEN "NAMES" in "I" mode.
2. OPEN a second file called "COPY" in "O" mode.
3. Read in the data in "NAMES" and write it to "COPY".
4. CLOSE "NAMES" and KILL it.
5. Write the new information to "COPY".
6. Rename "COPY" as "NAMES" and CLOSE.
7. Now there is a file on disk called "NAMES" that includes all the previous data plus the new data you just added.

Program B-3 illustrates this technique. It can be used to create or add onto a file called NAMES. This program also illustrates the use of LINE INPUT # to read strings with embedded commas from the disk file.

4-109

<!-- ===== scan page 124 (printed 4-110) - type:mixed ===== -->

Remember, LINE INPUT# will read in characters from the disk until it sees a carriage return (it does not stop at quotes or commas) or until it has read 255 characters.

```
10 ON ERROR GOTO 2000
20 OPEN "I",#1,"NAMES"
30 REM IF FILE EXISTS, WRITE IT TO "COPY"
40 OPEN "O",#2,"COPY"
50 IF EOF(1) THEN 90
60 LINE INPUT#1,A$
70 PRINT#2,A$
80 GOTO 50
90 CLOSE #1
100 KILL "NAMES"
110 REM ADD NEW ENTRIES TO FILE
120 INPUT "NAME";N$
130 IF N$="" THEN 200 'CARRIAGE RETURN EXITS INPUT LOOP
140 LINE INPUT "ADDRESS? ";A$
150 LINE INPUT "BIRTHDAY? ";B$
160 PRINT#2,N$
170 PRINT#2,A$
180 PRINT#2,B$
190 PRINT:GOTO 120
200 CLOSE
205 REM CHANGE FILENAME BACK TO "NAMES"
210 NAME "COPY" AS "NAMES"
2000 IF ERR=53 AND ERL=20 THEN OPEN "O",#2,"COPY":RESUME
       120
2010 ON ERROR GOTO 0
```

PROGRAM B-3 - ADDING DATA TO A SEQUENTIAL FILE

The error trapping routine in line 2000 traps a "File does not exist" error in line 20. If this happens, the statements that copy the file are skipped, and "COPY" is created as if it were a new file.

## Random Files

Creating and accessing random files requires more program steps than sequential files, but there are advantages to using random files. One advantage is that random files require less room on the disk, because BASIC stores them in a packed binary format. (A sequential file is stored as a series of ASCII characters.)

The biggest advantage to random files is that data can be accessed randomly, i.e., anywhere on the disk — it is not necessary to read through all the information, as with sequential files. This is possible

<!-- ===== scan page 125 (printed 4-111) - type:mixed ===== -->

because the information is stored and accessed in distinct units called records and each record is numbered.

The statements and functions that are used with random files are:

```
OPEN      FIELD      LSET/RSET    GET
PUT       CLOSE      LOC
MKI$      CVI
MKS$      CVS
MKD$      CVD
```

## Creating a Random File

The following program steps are required to create a random file.

1. OPEN the file for random access ("R" mode). This example specifies a record length of 32 bytes. If the record length is omitted, the default is 128 bytes.

   ```
   OPEN "R",# 1,"FILE",32
   ```

2. Use the FIELD statement to allocate space in the random buffer for the variables that will be written to the random file.

   ```
   FIELD #1 20 AS N$,
    4 AS A$, 8 AS P$
   ```

3. Use LSET to move the data into the random buffer. Numeric values must be made into strings when placed in the buffer. To do this, use the "make" functions: MKI to make an integer value into a string, MKS$ for a single precision value, and MKD$ for a double precision value.

   ```
   LSET N$=X$
   LSET A$=MKS$(AMT)
   LSET P$=TEL$
   ```

4. Write the data from the buffer to the disk using the PUT statement.

   ```
   PUT # 1,CODE%
   ```

Look at Program B-4. It takes information that is input at the terminal and writes it to a random file. Each time the PUT statement is executed, a record is written to the file. The two-digit code that is input in line 30 becomes the record number.

4-111

<!-- ===== scan page 126 (printed 4-112) - type:mixed ===== -->

## NOTE

Do not use a FIELDed string variable in an INPUT or LET statement. This causes the pointer for that variable to point into string space instead of the random file buffer.

```
10 OPEN "R" # 1,"FILE"
20 FIELD # 1,20 AS N$, 4 AS A$, 8 AS P$
30 INPUT "2-DIGIT CODE";CODE%
40 INPUT "NAME";X$
50 INPUT "AMOUNT";AMT
60 INPUT "PHONE";TEL$:PRINT
70 LSET N$=X$
80 LSET A$=MKS$(AMT)
90 LSET P$=TEL$
100 PUT # 1,CODE%
110 GOTO 30
```

PROGRAM B-4 - CREATE A RANDOM FILE

## Access a Random File

The following program steps are required to access a random file:

1. OPEN the file in "R" mode.

   ```
   OPEN "R",# 1,"FILE",32
   ```

2. Use the FIELD statement to allocate space in the random buffer for the variables that will be read from the file.

   ```
   FIELD # 1 20 AS N$,
   4 AS A$, 8 AS P$
   ```

### NOTE:

In a program that performs both input and output on the same random file, you can often use just one OPEN statement and one FIELD statement.

3. Use the GET statement to move the desired record into the random buffer.

   ```
   GET # 1,CODE%
   ```

4. The data in the buffer may now be accessed by the program. Numeric values must be converted back to numbers using the "convert" functions: CVI for integers, CVS for single precision values, and CVD for double precision values.

   ```
   PRINT N$
   PRINT CVS(A$)
   ```

<!-- ===== scan page 127 (printed 4-113) - type:mixed ===== -->

Program B-5 accesses the random file "FILE" that was created in Program B-4. By inputting the three-digit code at the terminal, the information associated with that code is read from the file and displayed.

```
10 OPEN "R",#1,"FILE"
20 FIELD #1, 20 AS N$, 4 AS A$, 8 AS P$
30 INPUT "2-DIGIT CODE";CODE%
40 GET #1, CODE%
50 PRINT N$
60 PRINT USING "$$###.##";CVS(A$)
70 PRINT P$:PRINT
80 GOTO 30
```

<p align="center">PROGRAM B-5 - ACCESS A RANDOM FILE</p>

The LOC function, with random files, returns the "current record number." The current record number is one plus the last record number that was used in a GET or PUT statement. For example, the statement

```
IF LOC(1)>50 THEN END
```

ends program execution if the current record number in file #1 is higher than 50.

Program B-6 is an inventory program that illustrates random file access. In this program, the record number is used as the part number, and it is assumed the inventory will contain no more than 100 different part numbers. Lines 900-960 initialize the data file by writing CHR$(255) as the first character of each record. This is used later (line 270 and line 500) to determine whether an entry already exists for that part number.

Lines 130-220 display the different inventory functions that the program performs. When you type in the desired function number, line 230 branches to the appropriate subroutine.

<p align="center">PROGRAM B-6 - INVENTORY</p>

```
120 OPEN"R",#1,"INVEN.DAT",39
125 FIELD#1,1 AS F$,30 AS D$, 2 AS Q$,2 AS R$,4 AS P$
130 PRINT:PRINT "FUNCTIONS:":PRINT
135 PRINT 1,"INITIALIZE FILE"
140 PRINT 2,"CREATE A NEW ENTRY"
150 PRINT 3,"DISPLAY INVENTORY FOR ONE PART"
160 PRINT 4,"ADD TO STOCK"
170 PRINT 5,"SUBTRACT FROM STOCK"
180 PRINT 6,"DISPLAY ALL ITEMS BELOW REORDER LEVEL"
220 PRINT:PRINT:INPUT"FUNCTION";FUNCTION
```

<!-- ===== scan page 128 (printed 4-114) - type:code ===== -->

```basic
225 IF (FUNCTION<1) OR (FUNCTION>6) THEN PRINT "BAD FUNCTION
        NUMBER":GOTO 130
230 ON FUNCTION GOSUB 900,250,390,480,560,680
240 GOTO 220
250 REM BUILD NEW ENTRY
260 GOSUB 840
270 IF ASC(F$)<>255 THEN INPUT"OVERWRITE";A$:IF A$ <>"Y" THEN
        RETURN
280 LSET F$=CHR$(0)
290 INPUT "DESCRIPTION";DESC$
300 LSET D$=DESC$
310 INPUT "QUANTITY IN STOCK";Q%
320 LSET Q$=MKI$(Q%)
330 INPUT "REORDER LEVEL";R%
340 LSET R$=MKI$(R%)
350 INPUT "UNIT PRICE";P
360 LSET P$=MKS$(P)
370 PUT#1,PART%
380 RETURN
390 REM DISPLAY ENTRY
400 GOSUB 840
410 IF ASC(F$)=255 THEN PRINT "NULL ENTRY":RETURN
420 PRINT USING "PART NUMBER # # #";PART%
430 PRINT D$
440 PRINT USING "QUANTITY ON HAND # # # # #";CVI(Q$)
450 PRINT USING "REORDER LEVEL # # # # #";CVI(R$)
460 PRINT USING "UNIT PRICE $$# #.# #";CVS(P$)
470 RETURN
480 REM ADD TO STOCK
490 GOSUB 840
500 IF ASC(F$)=55 THEN PRINT "NULL ENTRY":RETURN
510 PRINT D$:INPUT "QUANTITY TO ADD ";A%
520 Q%=CVI(Q$)+A%
530 LSET Q$=KI$(Q%)
540 PUT#1,PART%
550 RETURN
560 REM REMOVE FROM STOCK
570 GOSUB 840
580 IF ASC(F$)=255 THEN PRINT "NULL ENTRY":RETURN
590 PRINT D$
600 INPUT "QUANTITY TO SUBTRACT";S%
610 Q%=CVI(Q$)
620 IF (Q%-S%)<0 THEN PRINT "ONLY";Q%;" IN STOCK":GOTO 600
630 Q%=Q%-S%
```

<!-- ===== scan page 129 (printed 4-115) - type:mixed ===== -->

```
640 IF Q%=<CVI(R$) THEN PRINT "QUANTITY NOW";Q%;" REORDER
        LEVEL";CVI(R$)
650 LSET Q$=MKI$(Q%)
660 PUT#1,PART%
670 RETURN
680 DISPLAY ITEMS BELOW REORDER LEVEL
690 FOR I=1 TO 100
710 GET#1,I
720 IF CVI(Q$)<CVI(R$) THEN PRINT D$;" QUANTITY";CVI(Q$) TAB(50)
        "REORDER LEVEL";CVI(R$)
730 NEXT I
740 RETURN
840 INPUT "PART NUMBER";PART%
850 IF(PART%<1) OR (PART%>100) THEN PRINT "BAD PART NUM-
        BER":GOTO 840 ELSE GET#1,PART%:RETURN
890 END
900 REM INITIALIZE FILE
910 INPUT "ARE YOU SURE";B$:IF B$<>"Y" THEN RETURN
920 LSET F$=CHR$(255)
930 FOR I=1 TO 100
940 PUT#1,I
950 NEXT I
960 RETURN
```

<p align="center">PROGRAM B-6 - INVENTORY</p>

# Sequential I/O to and from Random Files

It is also possible to perform sequential I/O operations to and from
random disk files. Although it is generally slower, it *is* very similar to the
Apple DOS random file I/O and may be useful.

```
20
30 OPEN "R",1,"RND.TXT"
40 FOR I=1 TO 20
50 WRITE#1,"RECORD ",I," *** DCJCJC ***"
60 PUT 1,I
70 NEXT
80 CLOSE
90 '
100 '
110 OPEN "R",1,"RND.TXT"
120 FOR I=20 TO 1 STEP -1
130 GET 1,I
140 INPUT#1,A$,R,B$
150 PRINT A$;R;B$
160 NEXT
170 CLOSE
```

<!-- ===== scan page 130 (printed 4-116) - type:text ===== -->

# APPENDIX C

# Assembly Language Subroutines

All versions of BASIC-80 have provisions for interfacing with assembly language subroutines. The USR function allows assembly language subroutines to be called in the same way BASIC's intrinsic functions are called.

The address of FRCINT is 103 hex and the address of MAKINT is 105 hex.

Location 107 Hex contains the high byte of the CP/M BIOS entry for use with direct calls to the BIOS. While BASIC is up, the JMP at location zero is a JMP to the "Reset error" of BASIC, not to the BIOS warm boot routine.

## MEMORY ALLOCATION

Memory space must be set aside for an assembly language subroutine before it can be loaded. During initialization, enter the highest memory location minus the amount of memory needed for the assembly language subroutine(s). BASIC uses all memory available from its starting location up, so only the topmost locations in memory can be set aside for user subroutines.

When an assembly language subroutine is called, the stack pointer is set up for 8 levels (16 bytes) of stack storage. If more stack space is needed, BASIC's stack can be saved and a new stack set up for use by the assembly language subroutine. BASIC's stack must be restored, however, before returning from the subroutine.

The assembly language subroutine may be loaded into memory by means of the system monitor, or the BASIC POKE statement, or (if the user has the MACRO-80 or FORTRAN-80 package) routines may be assembled with MACRO-80 and loaded using LINK-80.

## USR FUNCTION CALLS - EXTENDED AND DISK BASIC

The syntax of the USR function is

```
USR[<digit>](argument)
```

where <digit> is from 0 to 9 and the argument is any numeric or string expression. <digit> specifies which USR routine is being called, and corresponds with the digit supplied in the DEF USR statement for that routine. If <digit> is omitted, USR0 is assumed. The address given in

<!-- ===== scan page 131 (printed 4-117) - type:text ===== -->

the DEF USR statement determines the starting address of the subroutine.

When the USR function call is made, register A contains a value that specifies the type of argument that was given. The value in A may be one of the following:

| Value in A | Type of Argument |
| --- | --- |
| 2 | Two-byte integer (two's complement) |
| 3 | String |
| 4 | Single precision floating point number |
| 8 | Double precision floating point number |

If the argument is a number, the [H,L] register pair points to the Floating Point Accumulator (FAC) where the argument is stored.

If the argument is an integer:

FAC-3 contains the lower 8 bits of the argument and
FAC-2 contains the upper 8 bits of the argument.

If the argument is a single precision floating point number:

FAC-3 contains the lowest 8 bits of mantissa and
FAC-2 contains the middle 8 bits of mantissa and
FAC-1 contains the highest 7 bits of mantissa with leading 1 suppressed (implied). Bit 7 is the sign of the number (0=positive, 1=negative).
FAC is the exponent minus 128, and the binary point is to the left of the most significant bit of the mantissa.

If the argument is a double precision floating point number:

FAC-7 through FAC-4 contain four more bytes of mantissa (FAC-7 contains the lowest 8 bits).

If the argument is a string, the [D,E] register pair points to 3 bytes called the "string descriptor." Byte 0 of the string descriptor contains the length of the string (0 to 255). Bytes 1 and 2, respectively, are the lower and upper 8 bits of the string starting address in string space.

CAUTION:   If the argument is a string literal in the program, the string descriptor will point to program text. Be careful not to alter or destroy your program this way. To avoid unpredictable results, add +"" to the string literal in the program. Example:

```
A$ = "BASIC-80"+""
```

This will copy the string literal into string space and will prevent alteration of program text during a subroutine call.

4-117

<!-- ===== scan page 132 (printed 4-118) - type:mixed ===== -->

Usually, the value returned by a USR function is the same type (integer, string, single precision or double precision) as the argument that was passed to it. However, calling the MAKINT routine returns the integer in [H,L] as the value of the function, forcing the value returned by the function to be integer. To execute MAKINT, use the following sequence to return from the subroutine:

```
PUSH    H           ;save value to be returned
LHLD    xxx         ;get address of MAKINT routine
XTHL                ;save return on stack and
                    ;get back [H,L]
RET                 ;return
```

Also, the argument of the function, regardless of its type, may be forced to an integer by calling the FRCINT routine to get the integer value of the argument in [H,L]. Execute the following routine:

```
LXI     H           ;get address of subroutine
                    ;continuation
PUSH    H           ;place on stack
LHLD    xxx         ;get address of FRCINT
PCHL
SUB1: .....
```

## CALL STATEMENT

User function calls to either Z-80 assembly language subroutines or 6502 assembly language subroutines may be made with the CALL statement. (See CALL, Chapter 3.)

### Calling a Z-80 Subroutine

The calling sequence used is the same as that in Microsoft's FORTRAN, COBOL and BASIC compilers.

A CALL statement with no arguments generates a simple "CALL" instruction. The corresponding subroutine should return via a simple "RET." (CALL and RET are 8080 opcodes - see an 8080 reference manual for details.)

A subroutine CALL with arguments results in a somewhat more complex calling sequence. For each argument in the CALL argument list, a parameter is passed to the subroutine. That parameter is the address of the low byte of the argument. Therefore, parameters always occupy two bytes each, regardless of type.

The method of passing the parameters depends upon the number of parameters to pass:

<!-- ===== scan page 133 (printed 4-119) - type:mixed ===== -->

1. If the number of parameters is less than or equal to 3, they are passed in the registers. Parameter 1 will be in HL, 2 in DE (if present), and 3 in BC (if present).

2. If the number of parameters is greater than 3, they are passed as follows:

   1. Parameter 1 in HL.
   2. Parameter 2 in DE.
   3. Parameters 3 through n in a contiguous data block. BC will point to the low byte of this data block (i.e., to the low byte of parameter 3).

Note that, with this scheme, the subroutine must know how many parameters to expect in order to find them. Conversely, the calling program is responsible for passing the correct number of parameters. There are no checks for the correct number or type of parameters.

If the subroutine expects more than 3 parameters, and needs to transfer them to a local data area, there is a system subroutine which will perform this transfer. This argument transfer routine is named $AT (located in the FORTRAN library, FORLIB.REL), and is called with HL pointing to the local data area, BC pointing to the third parameter, and A containing the number of arguments to transfer (i.e., the total number of arguments minus 2). The subroutine is responsible for saving the first two parameters before calling $AT. For example, if a subroutine expects 5 parameters, it should look like:

```
SUBR:   SHLD    P1          ;SAVE PARAMETER 1
        XCHG
        SHLD    P2          ;SAVE PARAMETER 2
        MVI     A,3         ;NO. OF PARAMETERS LEFT
        LXI     H,P3        ;POINTER TO LOCAL AREA
        CALL    $AT         ;TRANSFER THE OTHER 3 PARAMETERS
        .
        .
        .
        [Body of subroutine]
        .
        .
        RET                 ;RETURN TO CALLER
P1:     DS      2           ;SPACE FOR PARAMETER 1
P2:     DS      2           ;SPACE FOR PARAMETER 2
P3:     DS      6           ;SPACE FOR PARAMETERS 3-5
```

<!-- ===== scan page 134 (printed 4-120) - type:mixed ===== -->

A listing of the argument transfer routine $AT follows.

```
00100   ;             ARGUMENT  TRANSFER
00200   ;[B,C]        POINTS  TO 3RD PARAM.
00300   ;[H,L]        POINTS  TO LOCAL STORAGE FOR PARAM 3
00400   ;[A]          CONTAINS THE  # OF PARAMS TO XFER(TOTAL-2)
00500
00600
00700           ENTRY     $AT         ;SAVE [H,L] IN [D,E]
00800   $AT:    XCHG
00900           MOV       H,B
01000           MOV       L,C         ;[H,L] = PTR TO PARAMS
01100   AT1:    MOV       C,M
01200           INX       H
01300           MOV       B,M
01400           INX       H           ;[B,C] = PARAM ADR
01500           XCHG                  ;[H,L] POINTS TO LOCAL STORAGE
01600           MOV       M,C
01700           INX       H
01800           MOV       M,B
01900           INX       H           ;STORE PARAM IN LOCAL AREA
02000           XCHG                  ;SINCE GOING BACK TO AT1
02100           DCR       A           ;TRANSFERRED ALL PARAMS?
02200           JNZ       AT1         ;NO, COPY MORE
02300           RET                   ;YES, RETURN
```

When accessing parameters in a subroutine, don't forget that they are pointers to the actual arguments passed.

> **NOTE**
>
> It is entirely up to the programmer to see to it that the arguments in the calling program match in number, type, and length with the parameters expected by the subroutine. This applies to BASIC subroutines, as well as those written in assembly language.

## Calling a 6502 Subroutine

The syntax of a CALL statement to a 6502 subroutine differs from that of a CALL to a Z-80 subroutine in requiring that a percent symbol (%) be used before the variable name.

Up to three parameters may be used when calling a 6502 assembly language subroutine. All of the parameters must be single byte parameters.

They are passed as follows:

1. Parameter 1 in 6502 A register

<!-- ===== scan page 135 (printed 4-121) - type:text ===== -->

2. Parameter 2 in 6502 X register

3. Parameter 3 in 6502 Y register

For example:

```
CALL % ROUTINE (10,20,30)
```

10 would be passed in the A register, 20 in the X register and 30 in the Y register. All or some of the parameters may be omitted.

## INTERRUPTS

Assembly language subroutines can be written to handle interrupts. All interrupt handling routines should save the stack, register A-L and the PSW. Interrupts should always be re-enabled before returning from the subroutine, since an interrupt automatically disables all further interrupts once it is received. In CP/M BASIC, all interrupt vectors are free.

See "Software and Hardware Details" section of the SoftCard documentation.

# APPENDIX D

# Converting Programs to BASIC-80 From BASICs other Than Applesoft

If you have programs written in a BASIC other than BASIC-80, some minor adjustments may be necessary before running them with BASIC-80. Here are some specific things to look for when converting BASIC programs.

## STRING DIMENSIONS

Delete all statements that are used to declare the length of strings. A statement such as DIM A$(I,J), which dimensions a string array for J elements of length I, should be converted to the BASIC-80 statement DIM A$(J).

Some BASICs use a comma or ampersand for string concatenation. Each of these must be changed to a plus sign, which is the operator for BASIC-80 string concatenation.

In BASIC-80, the MID$, RIGHT$, and LEFT$ functions are used to take substrings of strings. Forms such as A$(I) to access the Ith character in A$, or A$(I,J) to take a substring of A$ from position I to position J, must be changed as follows:

<!-- ===== scan page 136 (printed 4-122) - type:text ===== -->

| Other BASIC | BASIC-80 |
| --- | --- |
| `X$=A$(I)` | `X$=MID$(A$,I,1)` |
| `X$=A$(I,J)` | `X$=MID$(A$,I,J-I+1)` |

If the substring reference is on the left side of an assignment and X$ is used to replace characters in A$, convert as follows:

| Other BASIC | BASIC-80 |
| --- | --- |
| `A$(I)=X$` | `MID$(A$,1,1)=X$` |
| `A$(I,J)=X$` | `MID$(A$,I,J-I+1)=X$` |

## MULTIPLE ASSIGNMENTS

Some BASICs allow statements of the form:

```
10 LET B=C=0
```

to set B and C equal to zero. BASIC-80 would interpret the second equal sign as a logical operator and set B equal to -1 if C equaled 0. Instead, convert this statement to two assignment statements:

```
10 C=0:B=0
```

## MULTIPLE STATEMENTS

Some BASICs use a backslash (\) to separate multiple statements on a line. With BASIC-80, be sure all statements on a line are separated by a colon (:).

## MAT FUNCTIONS

Programs using the MAT functions available in some BASICs must be rewritten using FOR...NEXT loops to execute properly.

<!-- ===== scan page 137 (printed 4-123) - type:text ===== -->

# APPENDIX E

## Summary of Error Codes and Error Messages

| Number | Message |
| --- | --- |
| 1 | **NEXT without FOR**<br>A variable in a NEXT statement does not correspond to any previously executed, unmatched FOR statement variable. |
| 2 | **Syntax error**<br>A line is encountered that contains some incorrect sequence of characters (such as unmatched parenthesis, misspelled command or statement, incorrect punctuation, etc.). |
| 3 | **Return without GOSUB**<br>A RETURN statement is encountered for which there is no previous, unmatched GOSUB statement. |
| 4 | **Out of data**<br>A READ statement is executed when there are no DATA statements with unread data remaining in the program. |
| 5 | **Illegal function call**<br>A parameter that is out of range is passed to a math or string function. An FC error may also occur as the result of:<br><br>1. a negative or unreasonably large subscript<br>2. a negative or zero argument with LOG<br>3. a negative argument to SQR<br>4. a negative mantissa with a non-integer exponent<br>5. a call to a USR function for which the starting address has not yet been given<br>6. an improper argument to MID$, LEFT$, RIGHT$, INP, OUT, WAIT, PEEK, POKE, TAB, SPC, STRING$, SPACE$, INSTR, or ON...GOTO. |

4-123

<!-- ===== scan page 138 (printed 4-124) - type:text ===== -->

| Code | Message and description |
| --- | --- |
| 6 | **Overflow** <br> The result of a calculation is too large to be represented in BASIC-80's number format. If underflow occurs, the result is zero and execution continues without an error. |
| 7 | **Out of memory** <br> A program is too large, has too many FOR loops or GOSUBs, too many variables, or expressions that are too complicated. |
| 8 | **Undefined line** <br> A line reference in a GOTO, GOSUB, IF...THEN...ELSE or DELETE is to a nonexistent line. |
| 9 | **Subscript out of range** <br> An array element is referenced either with a subscript that is outside the dimensions of the array, or with the wrong number of subscripts. |
| 10 | **Redimensioned array** <br> Two DIM statements are given for the same array, or a DIM statement is given for an array after the default dimension of 10 has been established for that array. |
| 11 | **Division by zero** <br> A division by zero is encountered in an expression, or the operation of involution results in zero being raised to a negative power. Machine infinity with the sign of the numerator is supplied as the result of the division, or positive machine infinity is supplied as the result of the involution, and execution continues. |
| 12 | **Illegal direct** <br> A statement that is illegal in direct mode is entered as a direct mode command. |
| 13 | **Type mismatch** <br> A string variable name is assigned a numeric value or vice versa; a function that expects a numeric argument is given a string argument or vice versa. |
| 14 | **Out of string space** <br> String variables have caused BASIC to exceed the amount of free memory remaining. BASIC will allocate string space dynamically, until it runs out of memory. |
| 15 | **String too long** <br> An attempt is made to create a string more than 255 characters long. |

<!-- ===== scan page 139 (printed 4-125) - type:table ===== -->

| Code | Message and Description |
| --- | --- |
| 16 | **String formula too complex**<br>A string expression is too long or too complex. The expression should be broken into smaller expressions. |
| 17 | **Can't continue**<br>An attempt is made to continue a program that:<br>1. has halted due to an error,<br>2. has been modified during a break in execution, or<br>3. does not exist. |
| 18 | **Undefined user function**<br>A USR function is called before the function definition (DEF statement) is given. |
| 19 | **No RESUME**<br>An error trapping routine is entered but contains no RESUME statement. |
| 20 | **RESUME without error**<br>A RESUME statement is encountered before an error trapping routine is entered. |
| 21 | **Unprintable error**<br>An error message is not available for the error condition which exists. This is usually caused by an ERROR with an undefined error code. |
| 22 | **Missing operand**<br>An expression contains an operator with no operand following it. |
| 23 | **Line buffer overflow**<br>An attempt is made to input a line that has too many characters. |
| 26 | **FOR without NEXT**<br>A FOR was encountered without a matching NEXT. |
| 29 | **WHILE without WEND**<br>A WHILE statement does not have a matching WEND. |
| 30 | **WEND without WHILE**<br>A WEND was encountered without a matching WHILE. |
| 31 | **Reset error**<br>The RESET key on the Apple keyboard has been pressed. |
| 32 | **Graphics statement not implemented**<br>Graphics statement is not implemented in MBASIC. It may be used with GBASIC only. |

<!-- ===== scan page 140 (printed 4-126) - type:text ===== -->

## Disk Errors

**50**
Field overflow

A FIELD statement is attempting to allocate more bytes than were specified for the record length of a random file.

**51**
Internal error

An internal malfunction has occurred in Disk BASIC-80. Report to Microsoft the conditions under which the message appeared.

**52**
Bad file number

A statement or command references a file with a file number that is not OPEN or is out of the range of file numbers specified at initialization.

**53**
File not found

A LOAD, KILL or OPEN statement references a file that does not exist on the current disk.

**54**
Bad file mode

An attempt is made to use PUT, GET, or LOF with a sequential file, to LOAD a random file or to execute an OPEN with a file mode other than I, O, or R.

**55**
File already open

A sequential output mode OPEN is issued for a file that is already open; or a KILL is given for a file that is open.

**57**
Disk I/O error

An I/O error occurred on a disk I/O operation. It is a fatal error, i.e., the operating system cannot recover from the error.

**58**
File already exists

The filename specified in a NAME statement is identical to a filename already in use on the disk.

**61**
Disk full

All disk storage space is in use.

**62**
Input past end

An INPUT statement is executed after all the data in the file has been INPUT, or for a null (empty) file. To avoid this error, use the EOF function to detect the end of file.

**63**
Bad record number

In a PUT or GET statement, the record number is either

<!-- ===== scan page 141 (printed 4-127) - type:text ===== -->

greater than the maximum allowed (32767) or equal to zero.

**64** — Bad file name

An illegal form is used for the filename with LOAD, SAVE, KILL, or OPEN (e.g., a filename with too many characters).

**66** — Direct statement in file

A direct statement is encountered while LOADing an ASCII-format file. The LOAD is terminated.

**67** — Too many files

An attempt is made to create a new file (using SAVE or OPEN) when all 255 directory entries are full.

**68** — Disk read only

Disk is write protected, or disk was changed without using RESET first. This error message will usually appear twice. This is normal and should not be cause for concern.

**69** — Drive select error.

A non-existent drive was selected.

**70** — File read only

A write was attempted to a file that has been set to "Read Only" with the STAT program.

<!-- ===== scan page 142 (printed 4-128) - type:mixed ===== -->

# APPENDIX F

# Mathematical Functions

## Derived Functions

Functions that are not intrinsic to BASIC-80 may be calculated as follows.

| Function | BASIC-80 Equivalent |
| --- | --- |
| SECANT | `SEC(X)=1/COS(X)` |
| COSECANT | `CSC(X)=1/SIN(X)` |
| COTANGENT | `COT(X)=1/TAN(X)` |
| INVERSE SINE | `ARCSIN(X)=ATN(X/SQR(-X*X+1))` |
| INVERSE COSINE | `ARCCOS(X)=-ATN (X/SQR`<br>`(-X*X+1))+1.5708` |
| INVERSE SECANT | `ARCSEC(X)=ATN(X/SQR(X*X-1))`<br>`+SGN(SGN(X)-1)*1.5708` |
| INVERSE COSECANT | `ARCCSC(X)=ATN(X/SQR(X*X-1))`<br>`+(SGN(X)-1)*1.5708` |
| INVERSE COTANGENT | `ARCCOT(X)=ATN(X)+1.5708` |
| HYPERBOLIC SINE | `SINH(X)=EXP(X)-EXP(-X))/2` |
| HYPERBOLIC COSINE | `COSH(X)=(EXP(X)+EXP(-X))/2` |
| HYPERBOLIC TANGENT | `TANH(X)=EXP(-X)/EXP(X)+`<br>`EXP(-X))*2+1` |
| HYPERBOLIC SECANT | `SECH(X)=2/(EXP(X)+EXP(-X))` |
| HYPERBOLIC COSECANT | `CSCH(X)=2/(EXP(X)-EXP(-X))` |
| HYPERBOLIC COTANGENT | `COTH(X)=EXP(-X)/(EXP(X)`<br>`-EXP(-X))*2+1` |
| INVERSE HYPERBOLIC SINE | `ARCSINH(X)=LOG(X+SQR`<br>`(X*X+1))` |
| INVERSE HYPERBOLIC COSINE | `ARCCOSH(X)=LOG(X+SQR(X*X-1)` |
| INVERSE HYPERBOLIC TANGENT | `ARCTANH(X)=LOG((1+X)/(1-X))/2` |
| INVERSE HYPERBOLIC SECANT | `ARCSECH(X)=LOG((SQR(-X*X+1)`<br>`+1)/X)` |

4-128

<!-- ===== scan page 143 (printed 4-129) - type:table ===== -->

| Function | BASIC Equivalent |
|---|---|
| INVERSE HYPERBOLIC COSECANT | `ARCCSCH(X)=LOG((SGN(X)*SQR(X*X+1)+1)/X` |
| INVERSE HYPERBOLIC COTANGENT | `ARCCOTH(X)=LOG((X+1)/(X-1))/2` |

<!-- ===== scan page 144 (printed 4-130) - type:table ===== -->

# APPENDIX G

## ASCII Character Codes

| ASCII Code | Character | ASCII Code | Character | ASCII Code | Character |
| --- | --- | --- | --- | --- | --- |
| 000 | NUL | 036 | $ | 072 | H |
| 001 | SOH | 037 | % | 073 | I |
| 002 | STX | 038 | & | 074 | J |
| 003 | ETX | 039 | ' | 075 | K |
| 004 | EOT | 040 | ( | 076 | L |
| 005 | ENQ | 041 | ) | 077 | M |
| 006 | ACK | 042 | * | 078 | N |
| 007 | BEL | 043 | + | 079 | O |
| 008 | BS | 044 | , | 080 | P |
| 009 | HT | 045 | - | 081 | Q |
| 010 | LF | 046 | . | 082 | R |
| 011 | VT | 047 | / | 083 | S |
| 012 | FF | 048 | 0 | 084 | T |
| 013 | CR | 049 | 1 | 085 | U |
| 014 | SO | 050 | 2 | 086 | V |
| 015 | SI | 051 | 3 | 087 | W |
| 016 | DLE | 052 | 4 | 088 | X |
| 017 | DC1 | 053 | 5 | 089 | Y |
| 018 | DC2 | 054 | 6 | 090 | Z |
| 019 | DC3 | 055 | 7 | 091 | [ |
| 020 | DC4 | 056 | 8 | 092 | \ |
| 021 | NAK | 057 | 9 | 093 | ] |
| 022 | SYN | 058 | : | 094 | ↑ |
| 023 | ETB | 059 | ; | 095 | < |
| 024 | CAN | 060 | < | 096 | ' |
| 025 | EM | 061 | = | 097 | a |
| 026 | SUB | 062 | > | 098 | b |
| 027 | ESCAPE | 063 | ? | 099 | c |
| 028 | FS | 064 | @ | 100 | d |
| 029 | GS | 065 | A | 101 | e |
| 030 | RS | 066 | B | 102 | f |
| 031 | US | 067 | C | 103 | g |
| 032 | SPACE | 068 | D | 104 | h |
| 033 | ! | 069 | E | 105 | i |
| 034 | " | 070 | F | 106 | j |
| 035 | # | 071 | G | 107 | k |

<!-- ===== scan page 145 (printed 4-131) - type:table ===== -->

| Code | Char | Code | Char | Code | Char | Code | Char |
|------|------|------|------|------|------|------|------|
| 108  | l    | 115  | s    | 122  | z    |      |      |
| 109  | m    | 116  | t    | 123  | {    |      |      |
| 110  | n    | 117  | u    | 124  | \|   |      |      |
| 111  | o    | 118  | v    | 125  | }    |      |      |
| 112  | p    | 119  | w    | 126  | ~    |      |      |
| 113  | q    | 120  | x    | 127  | DEL  |      |      |
| 114  | r    | 121  | y    |      |      |      |      |

ASCII codes are in decimal.

LF=Line Feed, FF=Form Feed, CR=Carriage Return, DEL=Rubout

<!-- ===== scan page 146 - type:blank ===== -->

<!-- ===== scan page 147 - type:text ===== -->

# INDEX

| Term | References |
| --- | --- |
| ABS | 4-81 |
| Addition | 4-18 |
| ALL | 4-27, 4-29 |
| ANSI Compatibility | 4-5 |
| Arctangent | 4-82 |
| Array variables | 4-16, 4-29, 4-33 |
| Arrays | 4-16, 4-37 |
| Applesoft | 4-4 to 4-8 |
| ASC | 4-81 |
| ASCII codes | 4-81 to 4-82, 4-130 |
| ASCII format | 4-26, 4-54, 4-73 |
| Assembly language subroutines | 4-25, 4-32, 4-59, 4-95, 4-96, 4-115 |
| ATN | 4-82 |
| AUTO | 4-5, 4-6, 4-11, 4-24, 4-25 |
| Boolean operators | 4-20 |
| Built-in Disk I/O Statements | 4-4 |
| CALL | 4-25, 4-4, 4-117 |
| Carriage return | 4-11, 4-47, 4-51, 4-78 to 4-80 |
| CDBL | 4-82 |
| CHAIN | 4-6, 4-26, 4-29 |
| Character set | 4-11 |
| CHR$ | 4-82 |
| CINT | 4-83 |
| CLEAR | 4-27, 4-103 |
| CLOSE | 4-27, 4-106, 4-110 |
| Compilability | 4-5 |
| Concatenation | 4-22 |
| Constants | 4-13 |
| CONT | 4-29, 4-51 |
| Control characters | 4-13 |
| Control-A | 4-22, 4-36 |
| COS | 4-83 |
| CP/M | 4-9, 4-53, 4-54, 4-72, 4-73, 4-105 |
| CSNG | 4-83 |
| CVD | 4-84, 4-110 |
| CVI | 4-84, 4-110 |
| CVS | 4-84, 4-110 |
| DATA | 4-19, 4-71 |
| DEF FN | 4-30 |
| DEF USR | 4-32, 4-95 |
| DEFDBL | 4-15, 4-31 |
| DEFINT | 4-25, 4-31 |
| DEFSNG | 4-25, 4-31 |
| DEFSTR | 4-15, 4-31 |
| DEINT | 4-115 |

<!-- ===== scan page 148 - type:table ===== -->

| Entry | Pages |
| --- | --- |
| DEL | 1-7, 4-31 |
| DELETE | 4-7, 4-11, 4-26, 4-32 |
| DIM | 4-33 |
| Direct mode | 4-10, 4-46, 4-56 |
| Division | 4-18 |
| Double precision | 4-14, 4-31, 4-60, 4-82, 4-103 |
| EDIT | 4-11, 4-33 |
| Edit mode | 4-5, 4-13, 4-33 |
| END | 4-28 to 4-29, 4-36, 4-43 |
| EOF | 4-84, 4-106, 4-108 |
| ERASE | 4-37 |
| ERL | 4-37 |
| ERR | 4-37 |
| ERROR | 4-38 |
| Error codes | 4-23, 4-37, 4-38, 4-123 |
| Error messages | 4-23, 4-123 |
| Error trapping | 4-37, 4-38, 4-56, 4-72, 4-109 |
| Escape | 4-12, 4-33 |
| EXP | 4-85 |
| Exponentiation | 4-18 to 4-19, 4-85 |
| Expressions | 4-17 |
| FIELD | 4-39, 4-110 |
| FILES | 4-39 |
| FIX | 4-85 |
| FOR...NEXT | 4-7, 4-40, 4-103 |
| FRCINT | 4-7, 4-115, 4-116 |
| FRE | 4-85 |
| Functions | 4-22, 4-30, 4-81, 4-128 |
| GBASIC | 4-3, 4-9, 4-98 |
| GET | 4-39, 4-42, 4-110 |
| GOSUB | 4-42 |
| GOTO | 4-42 to 4-43 |
| GR | 4-6, 4-7, 4-44 |
| HCOLOR | 4-6, 4-100 |
| HEX$ | 4-86 |
| Hexadecimal | 4-14, 4-86 |
| HGR | 4-6, 4-7, 4-99 |
| HLIN | 4-6, 4-44 |
| HOME | 4-45 |
| HPLOT | 4-6, 4-101 |
| IF...GOTO | 4-46 |
| IF...THEN | 4-37, 4-46 |
| IF...THEN...ELSE | 4-46 |
| Indirect mode | 4-9 |
| INKEY$ | 4-5, 4-7, 4-86 |
| INP | 4-7 |

<!-- ===== scan page 149 - type:table ===== -->

| Entry | References |
|---|---|
| INPUT | 4-7, 4-29, 4-39, 4-47, 4-104, 4-111 |
| INPUT$ | 4-86 |
| INPUT # | 4-49, 4-106 |
| INSTR | 4-87 |
| INT | 4-85, 4-87 |
| Integer | 4-83, 4-85, 4-87 |
| Integer division | 4-18 |
| Interrupts | 4-120 |
| INVERSE | 4-6, 4-49 |
| KILL | 4-50, 4-106 |
| LEFT$ | 4-88 |
| LEN | 4-88 |
| LET | 4-39, 4-50, 4-111 |
| Line feed | 4-11, 4-47, 4-51, 4-79 |
| LINE INPUT | 4-51 |
| LINE INPUT # | 4-51, 4-106 |
| Line numbers | 4-10 to 4-11, 4-24, 4-70 |
| Line printer | 4-53, 4-78, 4-89 |
| Lines | 4-10 to 4-11 |
| LIST | 4-11, 4-52 |
| LLIST | 4-53 |
| LOAD | 4-53, 4-73, 4-105 |
| LOC | 4-88, 4-106, 4-108, 4-110 |
| LOF | 4-88 |
| LOG | 4-89 |
| Logical operators | 4-20 |
| Loops | 4-40, 4-78 |
| LPOS | 4-78, 4-89 |
| LPRINT | 4-53, 4-78 |
| LPRINT USING | 4-53 |
| LSET | 4-54, 4-110 |
| MAKINT | 4-115, 4-116 |
| MBASIC | 4-3, 4-9, 4-10 |
| MERGE | 4-16, 4-54, 4-105 |
| MID$ | 4-55, 4-89, 4-121 |
| MKD$ | 4-90, 4-110 |
| MKI$ | 4-90, 4-110 |
| MKS$ | 4-90, 4-110 |
| MOD operator | 4-19 |
| Modulus arithmetic | 4-19 |
| Multiplication | 4-19 |
| NAME | 4-55 |
| Negation | 4-19 |
| NEW | 4-28, 4-55 |
| NORMAL | 4-6, 4-56 |

<!-- ===== scan page 150 - type:table ===== -->

| Entry | References |
| --- | --- |
| NULL | 4-8 |
| Numeric constants | 4-13 |
| Numeric variables | 4-15 |
| OCT$ | 4-90 |
| Octal | 4-14, 4-90 |
| ON ERROR GOTO | 4-7, 4-56 |
| ON...GOSUB | 4-57 |
| ON...GOTO | 4-57 |
| OPEN | 4-28, 4-39, 4-57, 4-106, 4-110 |
| Operators | 4-5, 4-17, 4-19 to 4-22 |
| OPTION BASE | 4-58 |
| OUT | 4-7 |
| Overflow | 4-19, 4-85, 4-95, 4-103 |
| Overlay | 4-27 |
| PDL | 4-6, 4-90 |
| PEEK | 4-59, 4-91 |
| PLOT | 4-6, 4-59 |
| POKE | 4-59, 4-91 |
| POP | 4-6, 4-60 |
| POS | 4-79, 4-91 |
| PRINT | 4-60 to 4-62, 4-103 |
| PRINT USING | 4-4, 4-62 to 4-65, 4-103 |
| PRINT # | 4-65, 4-106 |
| PRINT # USING | 4-65, 4-106, 4-108 |
| Protected files | 4-73, 4-104, 4-106 |
| PUT | 4-39, 4-67, 4-110 |
| Random files | 4-39, 4-40, 4-42, 4-50, 4-54, 4-58, 4-67, 4-84, 4-88, 4-90, 4-109, 4-110 |
| Random numbers | 4-67, 4-68, 4-92 |
| RANDOMIZE | 4-67, 4-68, 4-92, 4-103 |
| READ | 4-68, 4-69, 4-71 |
| Relational operators | 4-19, 4-20 |
| REM | 4-69, 4-70 |
| RENUM | 4-5, 4-26, 4-37, 4-70 |
| RESET | 4-71 |
| RESTORE | 4-71 |
| RESUME | 4-7, 4-72 |
| RETURN | 4-42 |
| RIGHT$ | 4-91 |
| RND | 4-67, 4-92, 4-103 |
| RSET | 4-54, 4-110 |
| Rubout | 4-12, 4-23, 4-35 |
| RUN | 4-72 to 4-73, 4-105 |
| SAVE | 4-53, 4-73, 4-105 |
| SCRN | 4-6, 4-92 |
| Sequential files | 4-49, 4-50, 4-51, 4-57, 4-65, 4-79, to 4-80, 4-84, 4-88, 4-106 to 4-109 |
| SGN | 4-92 to 4-92 |

<!-- ===== scan page 151 - type:table ===== -->

| Entry | Pages |
| --- | --- |
| SIN | 4-93 |
| Single precision | 4-14 to 4-15, 4-31, 4-61, 4-83 |
| SPACE$ | 4-93 |
| SPC | 4-93 |
| SQR | 4-94 |
| STOP | 4-29, 4-36, 4-42 to 4-43, 4-74 |
| STR$ | 4-94 |
| String constants | 4-13 |
| String functions | 4-5, 4-84, 4-87, 4-88, 4-91, 4-94, 4-95, 4-121 |
| String operators | 4-22 |
| String space | 4-27, 4-86, 4-103, 4-111 |
| String variables | 4-16, 4-31, 4-51 |
| STRING$ | 4-94 |
| Subroutines | 4-25, to 4-26, 4-42 to 4-43, 4-57, 4-115 |
| Subscripts | 4-16, 4-33, 4-58 |
| Subtraction | 4-18 |
| SWAP | 4-74 |
| SYSTEM | 4-75 |
| TAB | 4-94 |
| Tab | 4-12, 4-13 |
| TAN | 4-95 |
| TEXT | 4-7, 4-75 |
| TRACE/NOTRACE | 4-7, 4-74 |
| TROFF | 4-7 |
| TRON | 4-7 |
| USR | 4-32, 4-95, 4-115 |
| VAL | 4-95 |
| Variables | 4-15 to 4-16 |
| VARPTR | 4-96 |
| VLIN | 4-76, 4-6 |
| VPOS | 4-6, 4-96 |
| VTAB | 4-7, 4-77 |
| WAIT | 4-7, 4-77 |
| WEND | 4-4, 4-78 |
| WHILE | 4-4, 4-78 |
| WIDTH | 4-7, 4-78, 4-104 |
| WIDTH LPRINT | 4-78, 4-104 |
| WRITE | 4-79 |
| WRITE # | 4-79, 4-106 |
| 13-Sector | 4-3, 4-9 |
| 16-Sector | 4-3, 4-9, 4-98 |

<!-- ===== scan page 152 - type:blank ===== -->
