# Microsoft SoftCard - Software Utilities Manual

> **AI-reconstructed text.** Transcribed from the scanned manual `manuals/Microsoft_SoftCard_-_Software_Utilities_Manual.pdf` (md5 `9ec1db25c5bd27adb4c6943a2c4a14be`, 36 pages) by a vision model, with an adversarial verification pass on every table and code page. Convenience copy for search and reference. **The scanned PDF remains the authoritative source** - verify any exact byte, address, or opcode against it. Reconstructed 2026-06-17; spot-check items in [`README.md`](README.md).


<!-- ===== scan page 001 - type:cover ===== -->

# Software Utilities Manual

<!-- ===== scan page 002 - type:blank ===== -->

<!-- ===== scan page 003 (printed 5-1) - type:text ===== -->

# PART 5
# SOFTWARE UTILITIES MANUAL

| | |
|---|---:|
| **Introduction** | 5-2 |
| &nbsp;&nbsp;Format Notation | |
| **To Prepare Diskettes for Reading and Writing: FORMAT** | 5-3 |
| **To Make Copies of Diskettes: COPY** | 5-7 |
| &nbsp;&nbsp;To Create CP/M System Disks | |
| **To Access 13-Sector CP/M Files from 16-Sector CP/M: RW13** | 5-10 |
| **To Configure CP/M for a 56K System: CPM56** | 5-12 |
| **To Transfer Files from Apple DOS to CP/M: APDOS** | 5-14 |
| **To Configure the Apple CP/M Operating Environment: CONFIGIO** | 5-16 |
| &nbsp;&nbsp;1. Configure CP/M for External Terminal | |
| &nbsp;&nbsp;2. Redefine Keyboard Characters | |
| &nbsp;&nbsp;3. Load User I/O Driver Software | |
| &nbsp;&nbsp;4. Read/Write I/O Configuration | |
| **To Transfer CP/M Files from Another Computer: DOWNLOAD and UPLOAD** | 5-28 |

<!-- ===== scan page 004 (printed 5-2) - type:text ===== -->

# Introduction

Several utility programs are provided in the SoftCard package to help you accomplish certain tasks associated with using CP/M on an Apple II computer. The utilities provided are:

| Utility | Description |
| --- | --- |
| FORMAT | Formats blank disks for use with the SoftCard system. |
| COPY | Makes duplicate copies of disks. |
| CONFIGIO | Configures I/O for different hardware and software combinations |
| RW13 | Accesses 13-Sector CP/M files from 16-Sector CP/M |
| CPM56 | Configures CP/M for a 56K Language Card System |
| APDOS | Transfers text files and binary files from Apple DOS to CP/M |
| UPLOAD/DOWNLOAD | Transfers files from a standard CP/M machine to the Apple CP/M system. |

Instructions for using each of these programs are included on the following pages.

## Format Notation:

Wherever the format for a statement or command is given, the following rules apply:

1. d:, d₁:, d₂: etc. are disk drives to be specified by you. Acceptable drive names are A:, B:, C:, D:, E: and F:

2. n is an integer 0-9 that will be displayed by the computer according to the particular software you are using.

3. Items in square brackets ([ ]) are optional.

<!-- ===== scan page 005 (printed 5-3) - type:text ===== -->

# To Prepare Diskettes for Reading and Writing: FORMAT

**Command Format:**

```
FORMAT
or
FORMAT d:
```

**Purpose:**

The FORMAT program allows you to prepare blank diskettes for reading and writing. You will need to format all blank diskettes before you use them with the Apple SoftCard system.

**Instructions:**

To format a blank diskette, first insert a diskette that contains CP/M and the FORMAT utility into your disk drive. (These programs are contained on both diskettes in the SoftCard package.) Bring up CP/M as usual. (See "Installation and Operations Manual.") Once you see the CP/M prompt A>, you are ready to begin.

The FORMAT program can be initialized in either of two ways, depending on whether you plan to format *one* or *multiple* diskettes.

**Option 1: Use This Method if You Wish To Format Just One Diskette.**

1. First, type:

   ```
   FORMAT d:
   ```

   And press RETURN. If you have two or more disk drives, make sure you have inserted a blank diskette in the specified drive before you press RETURN. If you have a single-drive system, indicate drive A: but leave the disk containing FORMAT in the drive for now.

2. The screen will display the program copyright notice:

   ```
           APPLE II CP/M
      nn SECTOR DISK FORMATTER
         (C) 1980 MICROSOFT


   INSERT DISK TO BE FORMATTED IN DRIVE d:
   ```

<!-- ===== scan page 006 (printed 5-4) - type:text ===== -->

Do so, then press RETURN to start the formatting process.

4. If you have a multi-drive system, the computer will automatically return to CP/M when the formatting is completed. If you have a single-drive system, the computer will indicate:

```
FORMAT COMPLETED
INSERT CP/M SYSTEM DISK IN DRIVE A: AND PRESS
RETURN
```

Insert a diskette that contains CP/M, then press RETURN. You now have one formatted diskette which is ready to receive CP/M or may be used to store programs and data.

### WARNING

Newly formatted disks do *not* have the CP/M operating system on them and *WILL NOT BOOT*. To create CP/M system diskettes from formatted diskettes, use the COPY utility. (See COPY, page 5-7.)

## Option 2: Use This Method if You Plan To Format More Than One Disk

1. Type:

```
FORMAT
```

   and press RETURN. The computer will indicate:

```
            APPLE II CP/M
      nn-SECTOR DISK FORMATTER
         (C) MICROSOFT 1980


   FORMAT DISK IN WHICH DISK DRIVE?
```

2. Indicate the desired disk drive by typing:

```
d:
```

   then pressing RETURN. If you have two or more disk drives, make sure you have inserted a blank disk in the specified drive before you press RETURN. If you have a single-drive system, indicate drive A: but leave the disk containing FORMAT in the drive for now. If you press RETURN without specifying a drive, the computer will return to CP/M.

<!-- ===== scan page 007 (printed 5-5) - type:text ===== -->

3.  On a multi-drive system, the computer will begin formatting the diskette in the specified drive. On a single-drive system, the computer will display the message:

```
INSERT DISK TO BE FORMATTED IN DRIVE A:
PRESS RETURN TO BEGIN
```

Insert the diskette to be formatted, then press RETURN to begin formatting the diskette.

4.  When the formatting is complete, the computer will indicate:

```
FORMAT COMPLETE
FORMAT DISK IN WHICH DRIVE?
```

You can continue formatting diskettes in this fashion indefinitely, inserting a blank diskette in the appropriate drive each time. When you have finished formatting diskettes, press RETURN in response to FORMAT DISK IN WHICH DRIVE? to return to CP/M. For a single-drive system, be sure to reinsert a diskette containing CP/M before pressing RETURN.

## WARNING

Newly formatted disks do *not* have the CP/M operating system on them and they *WILL NOT BOOT.* To create CP/M system diskettes from formatted diskettes, use the COPY utility. (See COPY, page 5-7.)

*NOTE: If you attempt to format a disk that already contains data, the computer will display this message:*

```
DISK IN DRIVE d: WILL BE ERASED.
CONTINUE(Y/N)?
```

If you answer Y, the computer will re-format the disk, completely erasing it.

If you answer N, the computer will again ask:

```
FORMAT DISK IN WHICH DRIVE?
```

allowing you to insert another diskette or specify another drive.

If you simply press RETURN, the program will be terminated and the computer will return to CP/M.

5-5

<!-- ===== scan page 008 (printed 5-6) - type:text ===== -->

## Error Messages

If the FORMAT is not successful, the computer will indicate one of three error messages.

| Message | Description |
| --- | --- |
| DISK WRITE PROTECTED | There is a write protect tab on the diskette you want to format. Remove the write protect tab and repeat the FORMAT process. |
| DISK I/O ERROR | The computer is unable to format the diskette for some reason. Check to be sure you have a diskette in the disk drive and that the disk drive door is closed. |
| COMMAND ERROR | The command could not be understood. Retype the command line, making sure it is in the correct format. |

After an error is encountered, the computer returns to "FORMAT DISK IN WHICH DRIVE?"

<!-- ===== scan page 009 (printed 5-7) - type:text ===== -->

# To Make Copies of Diskettes: COPY

**Command Format:**

```
COPY d₁:=d₂:
Option: /S allows you to copy CP/M (tracks 0-2) only.
```

**Purpose:**

The copy utility allows you to make copies of Apple CP/M disks. Copy is also used to create CP/M system disks from newly formatted disks.

**Instructions:**

To make a copy of a diskette onto a blank, formatted diskette, first insert a diskette containing the COPY utility and CP/M (these programs are contained on the SoftCard diskettes) in your disk drive and bring up CP/M as usual. (See "Installation and Operations Manual.") Once you see the CP/M prompt A>, you are ready to begin.

1. Type:

   ```
   COPY d₁:=d₂:
   ```

   d₁: is the drive to which you wish to copy, and d₂: is the drive from which you wish to copy. If, for example, you indicate A:=B:, the computer will copy from drive B: and write to drive A:. If you have a single-drive system, type A:=A:.

   If you just typed COPY, the computer will return an asterisk (*) prompt and wait for you to enter a command line (d₁:=d₂:) before proceeding further.

   After the command line is typed, the computer will display the message:

   ```
            APPLE II CP/M
   xx-SECTOR DISK DUPLICATION PROGRAM
          (C) 1980 MICROSOFT
   ```

   (If you have a single-drive system, proceed to step 3.)

2. On a multi-drive system, the computer will also display the message:

   ```
   INSERT MASTER DISK IN d₁:
   INSERT SLAVE DISK IN d₂:
   PRESS RETURN TO BEGIN
   ```

<!-- ===== scan page 010 (printed 5-8) - type:text ===== -->

Insert the disk from which you wish to copy in drive d₁: and the diskette to which you wish to copy in drive d₂:. Press RETURN to begin copying. (Proceed to Step 4.)

3. For a single-drive system, the computer will display the message:

```
INSERT MASTER DISK
PRESS RETURN TO CONTINUE
```

Remove the SoftCard diskette and insert the diskette of which you wish to make a copy. Press RETURN. After some diskette activity, the computer will display the message:

```
INSERT SLAVE DISK     PRESS RETURN
```

Remove the disk you wish to copy and insert a blank formatted disk, then press RETURN. After some disk activity, the above message will be displayed again. Repeat Step 3, until the COPY COMPLETE message is displayed. (See Step 4.)

4. When a copy is completed, the computer will display the message:

```
COPY COMPLETE
DO YOU WISH TO MAKE ANOTHER COPY? (Y/N)
PRESS RETURN
```

Press Y to make another copy. Insert a new blank (formatted) disk in drive d₂ before pressing RETURN. (Also, see "To Create CP/M System Disks.")

Press N to return to CP/M command level.

## To Create CP/M System Disks:

The /S option allows you to *copy the CP/M operating system only* from one diskette to another. Other files on either disk are not affected. *You will need to copy CP/M onto each disk* you wish to use with the SoftCard system. (Diskettes must be formatted before CP/M can be copied to them. See FORMAT, page 5-3.) The command format for initiating the program is:

```
COPY d₁:=d₂:/S
```

d₁: is the drive from which you want to copy and d₂: is the drive to which you want to copy. /S is the switch that tells the computer to only copy CP/M. Otherwise, follow the instructions above for copying disks.

5-8

<!-- ===== scan page 011 (printed 5-9) - type:text ===== -->

## WARNING:

Unless you use the /S option, all files on the destination disk will be erased. Also, the diskette onto which you wish to copy *must be formatted* before it may be copied.

### Error Messages

If the COPY is not successful, the computer will indicate one of three error messages.

| Message | Description |
| --- | --- |
| DISK WRITE PROTECTED | There is a write protect tab on the diskette you want to copy. Remove the write protect tab and repeat the COPY process. |
| DISK I/O ERROR | The computer is unable to access the diskette for some reason. Check to be sure you have diskettes in the specified disk drives and that the disk drive doors are closed. |
| COMMAND ERROR | The command could not be understood. Retype the command line, making sure it is in the correct format. |

<!-- ===== scan page 012 (printed 5-10) - type:text ===== -->

# To Access 13-Sector CP/M Files from 16-Sector CP/M: RW13

**Command Format:**

```
RW13 d₁:
and
RW13 X                  (To convert drive back to 16-Sector)
```

**Purpose:**

RW13 allows a 16-Sector system to Read and Write to a 13-Sector diskette. When RW13 is run, 13-Sector files can be accessed by 16-Sector CP/M. Used with PIP, RW13 is especially useful for transferring files from a 13-Sector to a 16-Sector diskette. The RW13 X command is used to convert the drive back to 16-Sector. RW13 is found only on the 16-Sector SoftCard diskette and requires a system with two or more disk drives. Drive A: cannot be converted to 13-Sector operation.

**Instructions:**

Insert a diskette that contains RW13 and CP/M into your disk drive (these programs are contained on the diskettes in the SoftCard package) and bring up CP/M as usual. (See "Installation and Operations Manual.") When you see the CP/M prompt A>, you are ready to begin.

1. Type:

   ```
   RW13 d₁:
   ```

   where d₁ is a disk drive B:-F:. You may specify any drive *except drive A:*. Press RETURN.

2. The computer will display the message:

   ```
               APPLE II CP/M
       13-SECTOR DISK CONVERSION
            (C) 1980 MICROSOFT


       DRIVE D₁: CONVERTED TO 13 SECTOR OPERATION.
   ```

<!-- ===== scan page 013 (printed 5-11) - type:text ===== -->

3. Any 13-Sector diskette inserted into the "converted" drive can now be read from or written to by any CP/M program. In this mode, you can use PIP (See "Installation and Operations Manual") to transfer files from a 13-Sector diskette in a converted drive to a 16-Sector diskette in a non-converted drive. Or you can use any other CP/M software for a 13-Sector disk system. NOTE: Do not use the COPY program.

4. When you are finished, convert all of the drives back to 16-Sector by typing the command:

```
RW13 X
```

   and pressing RETURN. The drive will be returned to 16-Sector operation.

**NOTE:** RW13 occupies 4K of memory, so while it is in effect, there is 4K less memory available to programs.

<!-- ===== scan page 014 (printed 5-12) - type:text ===== -->

# To Configure CP/M for a 56K System: CPM56

**Command Format:**

```
CPM56 d:
```

**Purpose:**

To update CP/M for use with a 56K Language Card System. If you have a 56K system, you will want to perform this conversion before using CP/M, to take advantage of your system's additional memory. If you have a 48K system, you will not need this utility.

**Instructions:**

1. Insert a diskette containing CP/M and CPM56 into one of your Apple disk drives. (These programs are contained on the 16-Sector disk in the SoftCard package.) Boot up CP/M as usual. (See "Installation and Operations Manual.") When you see the CP/M prompt A>, you are ready to begin.

2. Type:

   ```
   CPM56 d:
   ```

   Insert a diskette that contains a copy of CP/M into the specified drive. (See the COPY utility for instructions for copying CP/M.) Press RETURN.

3. Once you press RETURN, the computer will automatically configure the copy of CP/M in the specified drive for a 56K system. When the conversion is complete, the computer will display the message:

   ```
   DISK IN DRIVE d: HAS BEEN UPDATED TO 56K.
   ```

   You now have a diskette containing CP/M for a 56K system.

**NOTE:** If you have used the CONFIGIO utility to define special characters, those characters will be preserved when CP/M is updated.

<!-- ===== scan page 015 (printed 5-13) - type:text ===== -->

## Error Messages

If the 56K configuration is not successful, one of the following error messages
will be displayed.

| Message | Description |
| --- | --- |
| DISK I/O ERROR | The drive cannot access the diskette for some reason. Check to be sure there is a diskette in the drive and the drive door is closed. |
| DISK WRITE PROTECTED | There is a write protect tab on the disk you wish to configure. Remove the write protect tab and repeat the CPM56 process. |
| COMMAND ERROR | The command could not be understood. Retype the command line, making sure it is in the correct format. |

<!-- ===== scan page 016 (printed 5-14) - type:text ===== -->

# To Transfer Files from Apple DOS to CP/M: APDOS

**Command Format:**

```
APDOS d₁:filename.typ = d₂:filename
or
APDOS d₂:
```

**Purpose:**

To transfer text files and binary files from Apple DOS to CP/M. APDOS cannot read BASIC files and it cannot write to an Applesoft diskette. If you want to transfer a DOS 3.2 file to a 16-sector CP/M disk, you must first use RW13 (see page 5-10) to convert the drive to 13-sector operation.

**Instructions:**

1. Insert a diskette containing both APDOS and CP/M into your Apple disk drive. (Both programs are contained on the diskettes in the SoftCard package.) Bring up CP/M as usual. (See "Installation and Operations Manual.") When you see the CP/M prompt A>, you are ready to begin.

2. Type:

   ```
   APDOS
   ```

   and hit RETURN. The computer will print

   ```
               APPLE II CP/M
   APPLE DOS CP/M FILE TRANSFER
           (C) 1980 MICROSOFT
   ```

   and then print a colon prompt. If you type CAT d: the catalog of the Apple DOS disk in drive d: will be displayed.

3. Type

   ```
   [d₁:] Fname.typ = [d₂:] Filename
   ```

   to transfer the Apple DOS file "Filename" (in drive d₂) to the CP/M file Fname.typ in drive d₁. If drives are not specified, d₁: defaults to A: and d₂: to B:.

<!-- ===== scan page 017 (printed 5-15) - type:text ===== -->

4. To continue copying files from the Apple DOS to the CP/M diskette type:

```
Fname.typ = Filename
```

The computer will assume the same disk drives as previously specified. If you wish to change disk drives, type the APDOS command in its original format.

All characters of an Apple DOS text file transferred using APDOS have their high order bits cleared. Apple DOS binary files retain the four bytes of address and file-length information at the beginning of the file. Actual data begins therefore at the *fifth* byte of the file. See the Apple DOS 3.2 or DOS 3.3 manual for details on the format of text and binary files.

Use the following procedure for transferring either Applesoft or Integer BASIC programs under Apple DOS to CP/M. This procedure converts the Integer BASIC or Applesoft program into a textfile which can be transferred using APDOS:

1. Boot an Apple DOS 3.2 or 3.3 disk that contains the program you wish to transfer, and LOAD the program as usual.

2. Enter the following program line as the first line of the program:
```
0 PRINT "ctrl-D OPEN APPLEPROG" : PRINT "ctrl-D WRITE
   APPLEPROG" : POKE 33,33 : LIST : PRINT "ctrl-D CLOSE" : END
```
(ctrl-D is an embedded ctrl-D character typed by you.)

3. RUN the program. When the program ends, you will have a text file on your Apple DOS disk called APPLEPROG that is actually a text copy of your program.

4. Boot your CP/M disk.

5. Type APDOS.

6. Insert the Apple DOS disk into drive B: (or into A: with a single-drive system).

7. If you have a multi-drive system, type APPLE.BAS=APPLEPROG and press RETURN. If you have a single-drive system, type APPLE.BAS=A:APPLEPROG and press RETURN.

8. Exit APDOS by typing ctrl-C.

9. Enter BASIC by typing MBASIC or GBASIC.

10. Type LOAD "APPLE" and press RETURN.

11. Delete line zero (the line entered by step 2).

12. You have now transferred a copy of your Applesoft or Integer BASIC program to Apple CP/M, which probably *will not run* at first try. You will probably be required to edit the program, changing the POKEs, PEEKs, CALLs, and disk file statements into their equivalent Microsoft BASIC statements. Note that

<!-- ===== scan page 018 (printed 5-16) - type:text ===== -->

most POKEs, PEEKs and CALLs simply will not work with Microsoft BASIC. They can, however, usually be replaced. See the Microsoft BASIC Reference Manual for more information on converting programs to Microsoft BASIC.

## Error Messages

If the Apple DOS to CP/M transfer is not successful, one of the following error messages will be displayed:

| Message | Description |
|---|---|
| DISK I/O ERROR | The drive cannot access the diskette for some reason. Check to be sure there is a diskette in the drive and the drive door is closed. |
| DISK WRITE PROTECTED | There is a write protect tab on one of the diskettes. Remove the write protect tab and repeat the APDOS process. |
| COMMAND ERROR | The command could not be understood. Retype the command line, making sure it is in the correct format. |

# To Configure the Apple CP/M Operating Environment: CONFIGIO

**Purpose:**
The CONFIGIO utility is used to configure the Apple CP/M operating environment to the user's particular system configuration.

**Instructions:**
Insert a CP/M system disk that contains MBASIC (or GBASIC) and CONFIGIO into a disk drive. (These programs can be found on either of the SoftCard disks). Bring up CP/M as usual. (See "Installation and Operations Manual.") When you see the CP/M prompt A>, type:

```
MBASIC CONFIGIO
```

and press RETURN.

If you are using the standard Apple, (i.e., no external terminal), the computer will ask

```
CAN YOUR APPLE DISPLAY LOWER CASE (Y/N)?
```

If your Apple is equipped with hardware that allows the direct display of lower case text on the Apple screen, respond with Y. Otherwise, answer with

<!-- ===== scan page 019 (printed 5-17) - type:text ===== -->

an N. An N response causes lower case characters to be converted to upper case before they are printed on the Apple screen. (This can be made permanent with option 4 below.)

The computer will then display the menu:

```
        + + I/O CONFIGURATION PROGRAM + +

    1. CONFIGURE CP/M FOR EXTERNAL TERMINAL

    2. REDEFINE KEYBOARD CHARACTERS

    3. LOAD USER I/O DRIVER SOFTWARE

    4. READ/WRITE I/O CONFIGURATION BLOCK

    Q. QUIT PROGRAM

    SELECT -
```

Select 1,2,3,4 or Q to perform the following functions:

1. Configure CP/M for External Terminal — Allows you to specify the character sequences required by your particular software or hardware to execute a particular screen function. Once these sequences are set up properly, your system can translate these character sequences between your terminal and your software. See page 5-17.

2. Redefine Keyboard Characters — Allows you to redefine the ASCII value that is assigned to any particular key on the keyboard. Using this option you can make one key (for example the 3 key) generate a character not usually associated with it (for example an ! mark). Or more usefully, you can make pressing Ctrl-V generate a [. This option is especially useful for making characters available that are not normally found on the Apple keyboard. See page 5-23.

3. Load User I/O Driver Software — Allows you to load and bind I/O driver software into the I/O Configuration Block for use with non-standard Apple peripherals, etc. See page 5-25.

4. Read/Write I/O Configuration Block — Allows you to read or write the I/O Configuration Block from or to the disk. Changes made using options 1-3 of CONFIGIO are made permanent by writing the I/O Configuration Block to the disk. See page 5-26.

<!-- ===== scan page 020 (printed 5-18) - type:mixed ===== -->

**Q**  Quit program — Exits program and returns to BASIC.

More information about each of these functions can be found in the Software Details Manual, pages 2-1 to 2-34. Below is an explanation of the use of each of the four functions:

# 1. Configure CP/M for External Terminal

## Introduction

Most video terminals (including the Apple 24 × 40 screen) support a number of special screen functions such as Clear Screen, Highlight Text, and Address Cursor. This is done by sending a special character sequence to the terminal to perform a particular function. Most applications software (such as screen-oriented word processors), however, are usually only capable of working with a small number of terminals — those that "understand" the screen character sequences sent by the software.

Apple CP/M provides you with translation tables for handling the screen function character sequence requirements of your hardware and software. The procedure for setting up Apple CP/M for your particular system configuration is outlined below.

**NOTE:** See the "Software and Hardware Details," page 2-12 for more information regarding terminal configuration.

*After you select number 1* from the main menu, the computer will display another menu:

```
            + TERMINAL SCREEN FUNCTION DEFINITION +

    FUNCTION              SOFTWARE              HARDWARE

    CLEAR SCREEN           ESC *                 FF
    CLR TO EOS             ESC Y                 VT
    CLR TO EOL             ESC T                 GS
    LO-LITE TEXT           ESC )                 SO
    HI-LITE TEXT           ESC (                 SI
    HOME CURSOR            RS                    EM
    ADDRESS CURSOR         ESC =                 RS
    XY COORD OFFST         32                    32
    XY XMIT ORDER     :    YX                    XY
    CURSOR UP              VT                    US
    CURSOR FORWARD         FF                    FS

           1. SOROC IQ 120/IQ 140
           2. HAZELTINE 1500/1510
```

<!-- ===== scan page 021 (printed 5-19) - type:text ===== -->

```
    3. DATAMEDIA
    4. OTHER
    Q. QUIT

    SELECT --
```

These are the Hardware and Software Screen Function Tables.

**NOTE:** When configuring CP/M for an external terminal, you should remove the interface card from slot 3 and use the standard Apple video. Once the configuration process is complete, you can reinsert the card.

The contents of the Hardware and Software Screen Function Tables are displayed using standard ASCII character names. A NUL entry in either table means that the function is not available.

Tables set up for certain other common terminals are available and can be selected by typing the appropriate number as indicated below:

**1. SOROC IQ 120/IQ 140** -- Type 1 to configure either the Software or Hardware Screen Function Table for a SOROC IQ 120/IQ 140 video terminal. If you type 1, you will then be asked which table (hardware or software) is to be reconfigured.

Since the Screen Function Tables are initially set up for use with a SOROC IQ 120/IQ 140 video terminal, you will not need to change them unless you wish to redefine the Software Screen Function Table. NOTE: When the SOROC terminal is powered on, it defaults to "Hi-lite" text mode. CP/M sends the "Lo-lite" character sequence when the system is booted.

**2. Hazeltine 1500/1510** -- Press 2 to configure the Hardware Screen Function table for use with a Hazeltine 1500/1510 video terminal.

Selection 2 should only be used to set up the Hardware Screen Function Table. Because of the non-standard way in which Apple CP/M handles the Hazeltine cursor addressing function (no X-Y coordinate offset is used), it is NOT advisable to use the Hazeltine screen function sequences in the Software table. Set up the Hardware table for the Hazeltine, and the Software table for some other common terminal, such as the SOROC IQ 120/140 (#1).

**3. Datamedia** -- Type 3 to configure the Hardware Screen Function Table for use with a Datamedia-style terminal. This is the configuration used for the 24 X 80 video terminal boards such as the Videoterm or the Sup-R-Term.

Selection 3 should be used to set up the Hardware Screen Function Table only, because the Datamedia Terminal sequences are not usually supported by CP/M *software*. You should set up the hardware table for use with the 24 X 80 video board, and the Software Table for some other common terminal

<!-- ===== scan page 022 (printed 5-20) - type:text ===== -->

such as the SOROC IQ 120/140 (#1). Hi-lite text and Lo-lite text (INVERSE and NORMAL) are not supported by all Datamedia-type terminals, thus the table entries we've specified for these functions are arbitrary. This was done so that these entries would be non-zero.

**4. Other** —Type 4 if you want to set up either the Software or Hardware tables for any terminal not accounted for by the other menu selections. This selection is used to change one or all of the screen function character sequences. When you type 4, the computer will display yet another menu:

```
        + + SCREEN FUNCTION DEFINITION + +


    1 - LEAD-IN CHARACTER
    2 - CLEAR SCREEN
    3 - CLR TO EOS
    4 - CLR TO EOL
    5 - LO-LITE TEXT
    6 - HI-LITE TEXT
    7 - HOME CURSOR
    8 - ADDRESS CURSOR
    9 - CURSOR UP
   10 - CURSOR FORWARD
    Q - QUIT


    SELECT —
```

You can now change any of the values in the "Terminal Screen Function Definition" Table.

**NOTE:** The appropriate screen function command characters for your terminal can be found in the manual for that terminal. To find out which codes are transmitted by a particular program (i.e., a word processor), consult the manual for the particular program.

Select a number 1 through 10 to define the character sequences for any of the following functions:

| Number | Title | Description |
|--------|-------|-------------|
| 1 | Lead-in char | Defines the Lead-in character — the character (usually an ESC) that precedes the screen function command character. A particular screen function may or may not require a lead-in character. |
| 2 | Clear screen | Clears the screen and places the cursor at the top left corner of the screen. |

<!-- ===== scan page 023 (printed 5-21) - type:mixed ===== -->

| # | Function | Description |
|---|----------|-------------|
| 3 | Clear to EOS | Clears the screen from the cursor to the end of the screen |
| 4 | Clear to EOL | Clears the screen from the cursor to the end of the line. |
| 5 | Lo-lite text | Sets the normal video mode for displaying text. |
| 6 | Hi-lite text | Sets inverse or double intensity video mode depending on which of these your terminal supports. |
| 7 | Home cursor | Puts the cursor at the top left corner of the screen but does not clear the screen. |
| 8 | Address cursor | Tells the terminal to go to a certain cursor address that is defined by the next two characters entered. |
|   | XY Coord. Offset | Defined as part of #8. The XY coordinate offset is the number that is added to the X and Y coordinates when they are sent to the terminal (Usually 32). |
|   | XY Xmit Order | Also defined as part of #8. Establishes the order that coordinates are transmitted. Must be either XY or YX (Usually YX). |
| 9 | Cursor Up | Moves the cursor up one line on the screen. |
| 10 | Cursor Forward | Moves the cursor forward on a line without deleting the character under the cursor. |

To assign the appropriate character sequences to any of these functions, just type its corresponding number and hit RETURN.

**Choose number 1** if you wish to specify a screen function lead-in character. The computer will display:

```
LEAD-IN CHAR :
```

Enter the lead-in character required. Characters may be entered in any one of the following formats:

<!-- ===== scan page 024 (printed 5-22) - type:text ===== -->

2 or 3-character ASCII name

| | |
|---|---|
| CTRL-ch | where ch is any character |
| ch | where ch is any keyboard character |
| LC-ch | LC- denotes that the following character is to be lower case. This can be used in place of the lower case character if your keyboard has no lower case. |

ASCII hexadecimal code (preceded by &H)

> May be used if the character cannot be typed. (See the ASCII Code Chart in the "Software Details Manual.")

After you have entered the lead-in character, the computer will respond:

```
SOFTWARE OR HARDWARE (S/H)?
```

Press S or H according to whether the lead-in character is to be used in the Software Screen Function Table or the Hardware Table.

**To define any of the other screen functions,** simply type the corresponding number for that function and the computer will prompt you to input the command character for that particular function. For instance, if you typed 2, the computer would prompt:

```
CLEAR SCREEN     :
```

Enter the character to be used for that particular function (in any of the formats listed above), then press RETURN. Do not include the lead-in character if it is required. If the function is not available, enter NUL (ASCII 00). Characters may be entered in any of the formats shown above.

After you enter in the character, you will be asked:

```
REQUIRE LEAD-IN (Y/N)?
```

Type Y if a lead-in character is required for execution of this function. Type N if none is required.

Next, the computer will ask:

```
SOFTWARE OR HARDWARE (S/H)?
```

<!-- ===== scan page 025 (printed 5-23) - type:text ===== -->

Type S to make the change you've indicated to the Software Screen Function Table. Type H to modify the Hardware Table.

The computer will return to the "SCREEN FUNCTION DEFINITION" menu and wait for you to select another number or Quit. You may make as many changes to the tables as you wish in this way. (The process for changing 8, Address Cursor, differs somewhat. See below.) Typing Q from this menu will redisplay the Screen Function Tables.

**If you select 8,** Address Cursor, you will be lead through the process as above up to:

```
Require Lead-in (Y/N)?
```

After you answer this question by pressing Y or N, the computer will print:

```
XY COORD OFFST    :
```

Enter a number to indicate the number of spaces that is to be added to the X/Y coordinates before they are transmitted. Finally, you will be asked

```
XY XMIT ORDER     :
```

If the X and Y coordinates are transmitted Y first then X, enter YX. If the coordinates are transmitted X then Y, enter XY.

The computer will then pick back up with the questions:

```
SOFTWARE OR HARDWARE (S/H)?
```

and continue as with any of the other functions.

## Notes on CP/M Terminal Configuration

Limitations: The Screen Function Tables may only be used with one or two character sequences: a single control character, or any character preceded by a lead-in character. Longer sequences can be implemented with a special purpose I/O driver. See the Software and Hardware Details (Part 2) for more information.

In order to make changes to the Screen Function Tables permanent, you must use option 4 of the "I/O Configuration Program" menu. If you don't write the I/O Configuration Block onto a CP/M disk, the changes you've made will be "forgotten" the next time your system is re-booted.

<!-- ===== scan page 026 (printed 5-24) - type:text ===== -->

No matter what values you've inserted in the Tables, they will work with the normal Apple 24×40 screen **if and only if ALL table entries are non-zero.**

The Software Screen Function Table must match the sequences the software will send to perform screen functions, and the Hardware Screen Function Table must match the sequences expected by the hardware device.

Microsoft BASIC will work with any terminal as long as the Hardware and Software Screen Function Tables are set up with non-zero entries in all of the nine functions.

It is usually a good idea to set up the Software Screen Function Table to emulate a SOROC IQ 120/140 type terminal. This is a common configuration that is supported by a majority of CP/M software.

## 2. Redefine Keyboard Characters

Keyboard Character Redefinition is used to make available characters to the user that are not normally available.

*If you select number 2,* the computer will display:

```
        + + KEYBOARD CHARACTER DEFINITION + +

   Ctrl-K   ->        [
   Ctrl-@   ->        RUB
   Ctrl-U ->          Ctrl-I
   Ctrl-B   ->        \
   ADD/DELETE/QUIT (A/D/Q) -
```

Shown in the table are three characters that have already been redefined: Ctrl-K, Ctrl-@, and Ctrl-B. These characters have been redefined to be often used characters that are normally unavailable on the Apple keyboard — "[", RUBOUT, and "\".

You can define additional characters, delete characters or return to the main menu by selecting A, D or Q, respectively.

If you type A to add to the table, the computer will display:

```
   CHAR:
```

Enter the character to be *re*defined. A character may be entered in any one of several formats:

<!-- ===== scan page 027 (printed 5-25) - type:text ===== -->

| Entry | Description |
| --- | --- |
| ch | where ch is any character |
| 2 or 3-character ASCII name | |
| Ctrl-ch | where ch is any character |
| LC-ch | The LC- prefix is used to enter lower case characters when lower case is not available. |
| ASCII hexadecimal code (preceded by &H) | (may be used if the character cannot be typed. See the ASCII Code chart in the "Software and Hardware Details" section of this manual.) |

If, for example, you wanted to redefine Ctrl-C as a NUL (ASCII 00) in order to prevent a user's ability to break out of a BASIC program by typing Ctrl-C, you would first type:

```
CTRL-C
```

after the CHAR: prompt.

If the character you have typed in is acceptable, the computer will prompt you to enter the new definition of the character with an arrow. With the example above:

```
CTRL-C -> NUL
```

where you type in NUL.

If your response is not acceptable, the computer will erase your previous input and wait for you to type an acceptable character entry.

Once you have hit RETURN, the list of redefined keyboard characters will again be displayed with the new redefinition added to the list. Now, every time you type Ctrl-C, a NUL character is actually entered. (Oh, by the way, try to Ctrl-C out of the CONFIGIO program!)

You can delete a keyboard character redefinition from the table by typing D. For example, to delete the entry made in the example above, type D. The computer will prompt you for the keyboard character redefinition to be deleted (CHAR:), to which you type: CTRL-C and hit RETURN. The list will be displayed with the Ctrl-C -> NUL entry deleted.

Type Q to return to the main menu.

<!-- ===== scan page 028 (printed 5-26) - type:text ===== -->

## Notes on Keyboard Character Redefinition

It is usually a good idea to delete keyboard character redefinitions if they do not apply to your keyboard. If for example, your keyboard has a RUBOUT key, you should delete the Ctrl-@ redefinition entry.

Redefining Ctrl-C as a NUL to prevent breakout out of BASIC programs with Ctrl-C is a useful idea, but it can present problems when in CP/M command mode. Ctrl-C is usually used by CP/M to re-initialize the system.

Some terminal devices do some redefinition of their own. For instance, with the Videx Videoterm, Ctrl-A is used to toggle upper and lower case input mode. Since Ctrl-A is also used in BASIC to enter EDIT mode, you may want to redefine some other character as Ctrl-A (such as Ctrl-W).

# 3. Load User I/O Driver Software

I/O software intended for use with non-standard hardware, etc., must be loaded and patched into the I/O Configuration Block. This is done with option 3. The program data that is loaded from disk must be of a special internal format. See the "Software and Hardware Details" section for more information.

*If you type 3,* the computer will display:

```
+ + LOAD USER I/O DRIVER SOFTWARE + +

OBJECT FILE NAME?
```

Type the name of the data file that contains the program to be loaded into the I/O Configuration Block and press RETURN. The computer will display the message:

```
LOADING...
```

as it loads and patches the routines from disk into the I/O Configuration Block. After the patches have been made, the computer will return to the main menu.

# 4. Read/Write I/O Configuration Block

This function allows you to write the I/O Configuration Block to disk or read the I/O Configuration Block from a disk into memory. This allows you to examine and modify the I/O Configuration Block on any CP/M disk and then save it to as many disks as desired. Writing the I/O Configuration Block

<!-- ===== scan page 029 (printed 5-27) - type:text ===== -->

to a CP/M system disk makes all changes made by the CONFIGIO program permanent.

**If you type 4,** the computer will display:

```
        + READ/WRITE I/O CONFIGURATION BLOCK +

    READ OR WRITE (R/W)?
```

**If you type W,** the computer will display:

```
    DESTINATION DRIVE (A:-F:)?
```

Insert a CP/M system disk and select the appropriate drive. The I/O Configuration Block on the disk will be replaced with the one currently in memory. Use W to make permanent any changes you've made under options 1-3. As soon as the process is complete, you will be returned to the main menu.

**If you type R,** the computer will ask

```
    SOURCE DRIVE (A:-F:)?
```

Insert a CP/M system disk and select the appropriate drive name. The I/O Configuration Block will be read from the CP/M disk and loaded into memory. Once the operation is complete, you will be returned to the main menu.

NEVER attempt to read or write the I/O Configuration Block on a disk that has CP/M configured for a different memory size than the system on which it is running. (i.e., don't try to read a 44K I/O Configuration Block using a system that runs 56K CP/M). Always make sure that the disk you which to read or write has the same CP/M configuration as the disk in drive A:.

<!-- ===== scan page 030 (printed 5-28) - type:mixed ===== -->

# To Transfer CP/M Files from Another Computer: Download and Upload

WARNING: USE OF THESE PROGRAMS ASSUMES FAMILIARITY WITH 8080 ASSEMBLY LANGUAGE PROGRAMMING. THESE PROGRAMS ARE INTENDED FOR EXPERIENCED PROGRAMMERS ONLY!

**Purpose:**
The DOWNLOAD and UPLOAD utilities enable the user to transfer CP/M files from another CP/M machine to the Apple by means of an RS-232 serial data link. The UPLOAD utility is intended to be typed into the non-Apple CP/M system (referred to as the "source" machine) and configured for the source machine's particular I/O environment using the DDT utility of CP/M. To use DOWNLOAD, you must have an Apple Communications Interface or CCS 7710A serial card plugged into slot 2. DOWNLOAD is found on both of the supplied SoftCard disks.

**To use the Download and Upload Utilities you need:**

1. A working knowledge of the CP/M DDT program and 8080 assembly language programming.

2. A CP/M based computer system (in addition to your Apple II) with an RS-232 Serial I/O port other than the port used for console I/O.

3. Either an Apple Communications Interface or California Computer Systems 7710A Serial Interface installed in slot 2 of the Apple.

**Instructions:**

**Step 1**
Using DDT, enter the following machine language program, UPLOAD, into the source machine starting at location 0163H:

```
0163 3A 80 00 B7 11 D7 01 CA CC 01 CD 03 01
0170 0E 0F 11 5C 00 CD 05 00 3C 11 E5 01 CA CC 01 3E
0180 52 CD 43 01 CD 23 01 FE 53 C2 7F 01 3E 47 CD 43
0190 01 11 06 02 CD D2 01 0E 14 11 5C 00 CD 05 00 B7
01A0 C2 C9 01 21 80 00 0E 00 16 80 7E CD 43 01 A9 4F
01B0 23 15 C2 AA 01 79 CD 43 01 CD 23 01 FE 42 CA A3
01C0 01 FE 47 CA 97 01 C3 B9 01 11 F4 01 CD D2 01 C3
01D0 00 00 0E 09 C3 05 00 43 6F 6D 6D 61 6E 64 20 45
01E0 72 72 6F 72 24 46 69 6C 65 20 6E 6F 74 20 66 6F
01F0 75 6E 64 24 0D 0A 55 50 4C 4F 41 44 20 43 6F 6D
0200 70 6C 65 74 65 24 55 70 6C 6F 61 64 69 6E 67 2E
0210 2E 2E 24 FE
```

<!-- ===== scan page 031 (printed 5-29) - type:text ===== -->

Enter the following three bytes at location 0100H:

```
C3 63 01        (This is a JMP 0163H)
```

When you're finished, double and triple check that you have entered the data correctly. Use the DDT "L" command to list the program and compare the listing with the listing of UPLOAD on page 5-31. Before you attempt the patches below, you should save the program by exiting DDT and typing SAVE 2 UPLOAD.COM. (For more information on the use of DDT, see the "CP/M Reference Manual").

## Step 2:

The next step is to patch the UPLOAD program to recognize the serial I/O port on the source machine. This is done by using DDT to write the following three subroutines. Each routine must begin at the address listed next to the subroutine description below. 32 bytes are allocated for each.

1. 0103H

   Initialize Serial Port — This routine must initialize the serial port on the source machine. (Baud rate, data format, etc.) The data format should be set up for 8 data bits, 1 stop bit, no parity, for compatibility with the Apple Com Card and the CCS 7710A card.

2. 0123H

   Return Serial Port Status — If no character is available at the serial port, this subroutine must return A = 00. If a byte is available, the routine should read the byte and return it in the A register.

3. 0143H

   Write to Serial Port — Output a byte to the serial port. Must save all registers including A.

Once these routines have been written and patched into the UPLOAD program, it should again be saved using the SAVE command.

## Step Three:

Next, wire up a connecting cable from the Apple to the source machine. One port must be wired up as a send (DTE) device, and the other a receiver (DCE). Sometimes the Xmit and Rcve lines (Pins 2 & 3) need to be reversed, or certain handshaking lines need to be wired together. If you are using a CCS 7710A serial card, wire pins 4, 6 and 20 together on the Apple end. Make sure that the data formats expected by the two serial ports are the same.

## Step Four:

Once UPLOAD has been patched and the cable has been made up, you are ready to begin.

<!-- ===== scan page 032 (printed 5-30) - type:text ===== -->

On the Apple, type

```
DOWNLOAD fname.typ
```

where fname.typ is the name the transferred program will be saved under.

Over on the source machine, type

```
UPLOAD fname.typ₂
```

where fname.typ₂ is the name of the file you want to transfer. As soon as communication is established, the Apple will display .

```
DOWNLOADING
```

and the source machine will display:

```
UPLOADING...
```

As each 128 byte record is transferred successfully, a period (".") is printed on the Apple screen. If an error is detected during transfer of a 128 byte record, a "B" is printed, and the record is retried.

When the transfer is complete, the source machine will display, appropriately,

```
UPLOAD COMPLETE
```

and return to CP/M.

When this message appears on the source machine, type Ctrl-C from the Apple keyboard. The disk will whir a bit, and soon the Apple will display

```
DOWNLOAD COMPLETE
```

and return to CP/M.

This process must be repeated for each file to be transferred. To transfer more than one file at a time, use the CP/M program, SUBMIT. You might also want to modify these programs to allow the use of a non-standard interface card, etc.

<!-- ===== scan page 033 (printed 5-31) - type:code ===== -->

# SOURCE LISTING: UPLOAD

```
                ;
                ;          UPLOAD
                ;
                ; WRITTEN 5/80 BY NEIL KONZEN
                ;     (C) 1980 MICROSOFT
                ;
0000 =          BOOT    EQU     0000H           ;BOOT SYSTEM
0005 =          BDOS    EQU     0005H           ;BDOS ENTRY POINT
005C =          FCB     EQU     005CH           ;DEFAULT FCB
0080 =          BUFFER  EQU     0080H           ;DEFAULT BUFFER ADDR
                ;
0100                    ORG     0100H           ;START AT TPA
                ;
0100 C36301     UPLOAD: JMP     ENTRY           ;JUMP AROUND ALL THESE
                ;
                ;
                INIT:                           ;INITIALIZE SERIAL PORT
                ;
                ; THIS SUBROUTINE SHOULD DO ANY INITIALIZATION
                ; OF THE SERIAL PORT THAT MAY BE REQUIRED.    IF
                ; NONE IS REQUIRED, A 'RET' WILL DO.
                ;
0103                    DS      32              ;SPACE FOR ROUTINE
                INPSTS:                         ;INPUT STATUS/READ
                ;
                ; THE INPUT STATUS/READ ROUTINE RETURNS ZERO IN [A] IF NO
                ; BYTE IS AVAILABLE.    IF A BYTE IS AVAILABLE,
                ; THE BYTE SHOULD BE READ AND RETURNED IN THE
                ; [A] REGISTER.
                ;
0123                    DS      32              ;SPACE FOR ROUTINE
                OUTPUT:                         ;SEND A BYTE TO APPLE
                ;
                ; THE OUTPUT ROUTINE SHOULD TRANSMIT THE BYTE IN THE
                ; [A] REGISTER TO THE APPLE VIA THE SERIAL
                ; PORT.   ALL REGS INCLUDING [A] SHOULD BE SAVED.
                ;
0143                    DS      32              ;SPACE FOR ROUTINE
                ;
0163 3A8000     ENTRY:  LDA     BUFFER          ;MAKE SURE HE TYPED SOME SORT OF FILE NAME
0166 B7                 ORA     A               ;A NON-ZERO NO. OF CHARS IN CMD LINE?
0167 11D701             LXI     D,CMDMSG        ;DEFAULT TO COMMAND ERROR MESSAGE
016A CACC01             JZ      EXIT            ;QUIT.
016D CD0301             CALL    INIT            ;INITIALIZE SERIAL PORT
0170 0E0F               MVI     C,15            ;OPEN FILE COMMAND
0172 115C00             LXI     D,FCB           ;POINT TO FCB
0175 CD0500             CALL    BDOS            ;OPEN IT UP
                ;
0178 3C                 INR     A               ;FF BECOMES ZERO
0179 11E501             LXI     D,FNFMSG        ;DEFAULT TO FILE NOT FOUND MSG
017C CACC01             JZ      EXIT            ;NO FILE
                ;
                ;   SEND A BUNCH OF 'R'S UNTIL DOWNLOAD ANSWERS
                ;
017F 3E52       RDYLP:  MVI     A,'R'           ;SEND 'R' FOR 'READY'
0181 CD4301             CALL    OUTPUT          ;SEND VIA SERIAL LINE
0184 CD2301             CALL    INPSTS          ;DID HE RESPOND?
0187 FE53               CPI     'S'             ;'S' FOR 'SET'
0189 C27F01             JNZ     RDYLP           ;THEN TRY AGAIN
                ;
018C 3E47               MVI     A,'G'
018E CD4301             CALL    OUTPUT          ;SEND TO DOWNLOAD
                ;
0191 110602             LXI     D,WRKMSG        ;TELL HIM WE'RE DONG IT
0194 CDD201             CALL    PRMSG
                ;
0197 0E14       READ:   MVI     C,20            ;READ SEQUENTIAL FUNCTION
0199 115C00             LXI     D,FCB
019C CD0500             CALL    BDOS            ;GO READ 128 BYTES
019F B7                 ORA     A               ;ERROR?
01A0 C2C901             JNZ     EOF             ;END OF FILE
01A3 218000     TRYAGN: LXI     H,BUFFER        ;POINT TO THE 128 BYTES
01A6 0E00               MVI     C,0             ;CHECKSUM = 0
01A8 1680               MVI     D,80H           ;BYTE COUNT = 128
```

<!-- ===== scan page 034 (printed 5-32) - type:code ===== -->

```
                    ;
01AA 7E       LOOP1:  MOV     A,M             ;GET CHAR
01AB CD4301           CALL    OUTPUT          ;SEND IT (MUST SAVE [A])
01AE A9               XRA     C               ;CALCULATE CHKSUM
01AF 4F               MOV     C,A             ;AND UPDATE IT
01B0 23               INX     H               ;PT. TO NEXT BYTE
01B1 15               DCR     D               ;DEC BYTE COUNT
01B2 C2AA01           JNZ     LOOP1           ;KEEP GOING UNTILL ALL 128 SENT
01B5 79               MOV     A,C             ;NOW SEND CHECKSUM BYTE
01B6 CD4301           CALL    OUTPUT          ;SEND IT
                    ;
                    ;       WAIT FOR VERIFICATION: 'G'=GOOD, 'B'=BAD
                    ;
01B9 CD2301   VFYLP:  CALL    INPSTS          ;GET A CHAR
01BC FE42             CPI     'B'             ;A BAD READ?
01BE CAA301           JZ      TRYAGN          ;START AGAIN.
01C1 FE47             CPI     'G'             ;A GOOD READ?
01C3 CA9701           JZ      READ            ;GO GET NEXT RECORD THEN
01C6 C3B901           JMP     VFYLP           ;CHAR MUST NOT HAVE BEEN READY
                    ;
01C9 11F401   EOF:    LXI     D,DONMSG
01CC CDD201   EXIT:   CALL    PRMSG           ;OUTPUT MESSAGE
01CF C30000           JMP     BOOT            ;ALL FINISHED.
                    ;
01D2 0E09     PRMSG:  MVI     C,9             ;PRINT MESSAGE FUNCTION
01D4 C30500           JMP     BDOS
                    ;
                    ;
01D7 436F6D6D61CMDMSG: DB     'COMMAND ERROR$'
01E5 46696C6520FNFMSG: DB     'FILE NOT FOUND$'
01F4 0D0A55504CDONMSG: DB     13,10,'UPLOAD COMPLETE$'
0206 55706C6F61WRKMSG: DB     'UPLOADING...$'
                    ;
0213                  END
```

<!-- ===== scan page 035 (printed 5-33) - type:code ===== -->

# SOURCE LISTING: DOWNLOAD

```
                ;
                ;       DOWNLOAD
                ;
                ;       THIS PROGRAM WORKS WITH AN APPLE COMMUNICATIONS
                ;       INTERFACE OR A CCS 7710A SERIAL INTERFACE IN SLOT
                ;       TWO.
                ;
                ;       WRITTEN 5/80 BY NEIL KONZEN
                ;          (C) 1980 MICROSOFT
                ;
0000 =          BOOT    EQU     0000H                   ;BOOT SYSTEM
0005 =          BDOS    EQU     0005H                   ;BDOS ENTRY POINT
005C =          FCB     EQU     005CH                   ;DEFAULT FCB
0080 =          BUFFER  EQU     0080H                   ;DEFAULT BUFFER ADDR
                ;
E0AE =          COMSTS  EQU     0E0AEH                  ;COM OR CCS CARD STATUS LOC
E0AF =          COMDAT  EQU     0E0AFH                  ;COM CARD DATA - SLOT 2
E000 =          APPKBD  EQU     0E000H                  ;APPLE KEYBOARD
                ;
                ;
0100                    ORG     0100H                   ;START AT TPA
                ;
                ;
                ;
0100 3A8000     DWNLOD: LDA     BUFFER                  ;MAKE SURE THERE'S A FILE NAME
0103 B7                 ORA     A                       ;ANY CHARS IN CMD LINE?
0104 11C001             LXI     D,CMDMSG                ;POINT TO CMD ERROR MSG
0107 CA8D01             JZ      EXIT                    ;QUIT
010A 0E13               MVI     C,19                    ;DELETE FILE
010C 115C00             LXI     D,FCB
010F D5                 PUSH    D                       ;SAVE PTR TO FCB
0110 CD0500             CALL    BDOS
0113 D1                 POP     D                       ;REGET PTR TO FCB
0114 0E16               MVI     C,22                    ;MAKE FILE
0116 CD0500             CALL    BDOS
                ;
0119 3C                 INR     A                       ;CHECK FOR ERROR
011A 11CE01             LXI     D,NDSMSG                ;GET READY TO PRINT 'NO DIR. SPACE'
011D CA8D01             JZ      EXIT
                ;
                ;       WAIT TILL UPLOAD SENDS AN 'R'
                ;
0120 CDA001     RDYLP:  CALL    RDCOM                   ;GET A CHAR FROM COM CARD
0123 FE52               CPI     'R'                     ;'R' FOR 'READY'?
0125 C22001             JNZ     RDYLP
                ;
0128 1E53               MVI     E,'S'                   ;GET 'S' FOR 'SET'
012A CD9301             CALL    WRCOM
                ;
012D CDA001     GETGEE: CALL    RDCOM                   ;WAIT FOR 'G' FOR 'GO'
0130 FE47               CPI     'G'
0132 C22D01             JNZ     GETGEE
                ;
0135 21F501             LXI     H,WRKMSG                ;POINT TO 'DOWNLDNG' MSG
0138 7E         PRLP:   MOV     A,M                     ;GET CHR
0139 B7                 ORA     A                       ;SET CC'S
013A CA4701             JZ      TRYAGN                  ;GO DO DOWNLOAD
013D E5                 PUSH    H
013E 5F                 MOV     E,A                     ;CHAR TO [E] FOR CONOUT
013F CDBB01             CALL    CONOUT
0142 E1                 POP     H
0143 23                 INX     H
0144 C33801             JMP     PRLP
```

<!-- ===== scan page 036 (printed 5-34) - type:code ===== -->

```
                ;
                ;
0147 218000     TRYAGN: LXI     H,BUFFER        ;POINT TO 128 BYTE BUFFER
014A 0E00               MVI     C,0             ;CLEAR CHECKSUM
014C 0E81               MVI     C,81H           ;READ 128 BYTES + 1 CHKSUM
                ;
014E CDA001     LOOP1:  CALL    RDCOM           ;READ A BYTE
0151 77                 MOV     M,A             ;STORE IT
0152 A9                 XRA     C               ;CALC CHKSUM
0153 4F                 MOV     C,A             ;UPDATE IT
0154 23                 INX     H               ;NEXT BYTE
0155 15                 DCR     D               ;DECREMENT BYTE COUNT
0156 C24E01             JNZ     LOOP1           ;NOT DONE - CONTINUE
0159 B7                 ORA     A               ;WAS CHKSUM ZERO?
015A CA6A01             JZ      GOODRD          ;THINGS ARE OK
                ;
015D 1E42       BADRD:  MVI     E,'B'           ;'B' FOR 'BAD'
015F CDBB01             CALL    CONOUT
0162 1E42               MVI     E,'B'           ;SEND 'B' TO UPLOAD
0164 CD9301             CALL    WRCOM
0167 C34701             JMP     TRYAGN
                ;
016A 1E2E       GOODRD: MVI     E,'.'           ;PRINT A PERIOD
016C CDBB01             CALL    CONOUT
016F 115C00             LXI     D,FCB           ;POINT TO FCB
0172 0E15               MVI     C,21            ;WRITE SEQ.
0174 CD0500             CALL    BDOS
0177 1E47               MVI     E,'G'           ;SEND UPOAD A 'G' FOR 'GOOD'
0179 CD9301             CALL    WRCOM
017C C34701             JMP     TRYAGN
                ;
                ;
017F 3210E0     DONE:   STA     APPKBD+10H      ;CLR KBD STROBE
0182 115C00             LXI     D,FCB
0185 0E10               MVI     C,16            ;CLOSE THE FILE
0187 CD0500             CALL    BDOS
018A 11E101             LXI     D,DONMSG        ;ALL DONE MSG
018D CDB601     EXIT:   CALL    PRMSG           ;PRINT THE MESSAGE
0190 C30000             JMP     BOOT
                ;
0193 3AAEE0     WRCOM:  LDA     COMSTS          ;COM CARD STATUS
0196 E602               ANI     2               ;CHECK BIT 2
0198 CA9301             JZ      WRCOM
019B 7B                 MOV     A,E             ;GET CHAR TO SEND
019C 32AFE0             STA     COMDAT          ;STORE HERE
019F C9                 RET
                ;
01A0 3AAEE0     RDCOM:  LDA     COMSTS          ;COM CARD STATUS
01A3 1F                 RAR                     ;STS BIT TO CARRY
01A4 DAB201             JC      READIT
01A7 3A00E0             LDA     APPKBD          ;SEE IF CTRL-C TYPED
01AA FE83               CPI     083H            ;??
01AC CA7F01             JZ      DONE

01AF C3A001             JMP     RDCOM           ;NO, WAIT FOR CHAR
                ;
01B2 3AAFE0     READIT: LDA     COMDAT          ;GET INCOMING CHARACTER
01B5 C9                 RET
                ;
01B6 0E09       PRMSG:  MVI     C,9             ;PRINT MESSAGE
01B8 C30500             JMP     BDOS
                ;
01BB 0E02       CONOUT: MVI     C,2             ;CONSOLE OUTPUT
01BD C30500             JMP     BDOS
                ;
01C0 436F6D6D61 CMDMSG: DB      'Command Error$'
01CE 4E6F206469 NDSMSG: DB      'No directory space$'
01E1 0D0A446F77 DONMSG: DB      13,10,'Download complete$'
01F5 446F776E6C WRKMSG: DB      'Downloading',0
                ;
0201            END
```

5-34
