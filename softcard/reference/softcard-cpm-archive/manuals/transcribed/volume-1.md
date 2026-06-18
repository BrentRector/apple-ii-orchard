# Microsoft SoftCard - Volume 1

> **AI-reconstructed text.** Transcribed from the scanned manual `manuals/Microsoft_SoftCard_-_Volume_1.pdf` (md5 `2ac3438bd0f7adcf3c4aa6c069c27151`, 62 pages) by a vision model, with an adversarial verification pass on every table and code page. Convenience copy for search and reference. **The scanned PDF remains the authoritative source** - verify any exact byte, address, or opcode against it. Reconstructed 2026-06-17; spot-check items in [`README.md`](README.md).


<!-- ===== scan page 001 - type:cover ===== -->

# SOFTCARD

**VOLUME I**

<!-- ===== scan page 002 - type:blank ===== -->

<!-- ===== scan page 003 - type:cover ===== -->

# SoftCard™

A Peripheral for the Apple II®
With CP/M® and Microsoft BASIC on diskette.

Produced by Microsoft

Microsoft Consumer Products
400 108th Ave. NE, Suite 200
Bellevue, WA 98004

<!-- ===== scan page 004 (printed i) - type:text ===== -->

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

<!-- ===== scan page 005 (printed ii) - type:text ===== -->

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

<!-- ===== scan page 006 (printed iii) - type:text ===== -->

| | |
|---|---|
| Some CP/M commands:<br>&nbsp;&nbsp;&nbsp;&nbsp;DIR, ERA, REN, TYPE | 1-22 |
| CP/M Error Messages | 1-23 |
| Description of Programs Included on the<br>&nbsp;&nbsp;&nbsp;&nbsp;SoftCard Disk | 1-26 |

## Chapter 4: Getting Started with Microsoft BASIC

| | |
|---|---|
| | 1-31 |

# PART II: Software and Hardware Details

## Chapter 1: Apple II CP/M Software Details

| | |
|---|---|
| Introduction | 2-4 |
| I/O Hardware Conventions | 2-4 |
| 6502/Z-80 Address Translation | 2-5 |
| Apple II CP/M Memory Usage | 2-6 |
| Assembly Language Programming with the<br>&nbsp;&nbsp;&nbsp;&nbsp;Soft Card | 2-7 |
| ASCII Character Codes | 2-7 |

## Chapter 2: Apple II CP/M I/O Configuration Block

| | |
|---|---|
| Introduction | 2-12 |
| Console Cursor Addressing/Screen Control | 2-12 |
| &nbsp;&nbsp;&nbsp;&nbsp;The Hardware/Software Screen Function Table | |
| &nbsp;&nbsp;&nbsp;&nbsp;Terminal Independent Screen<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Functions/Cursor Addressing | |
| Redefinition of Keyboard Characters | 2-17 |
| Support of Non-Standard Peripheral Devices | 2-17 |
| Calling of 6502 Subroutines | 2-24 |
| Indication of Presence and Location of<br>&nbsp;&nbsp;&nbsp;&nbsp;Peripheral Cards | 2-26 |

## Chapter 3: Hardware Description

| | |
|---|---|
| Introduction | 2-30 |
| Timing Scheme | 2-30 |
| SoftCard Control | 2-31 |
| Address Bus Interface | 2-31 |
| Data Base Interface | 2-33 |

iii

<!-- ===== scan page 007 (printed iv) - type:text ===== -->

| | |
|---|---|
| 6502 Refresh | 2-33 |
| DMA Daisy Chain | 2-34 |
| Interrupts | 2-34 |
| SoftCard Parts List | 2-34 |
| SoftCard Schematic | 2-36 |

# PART III: CP/M Reference Manual

## Chapter 1: Introduction to CP/M Features and Facilities

| | |
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

| | |
|---|---|
| Introduction | 3-41 |
| Operating System Call Conventions | 3-43 |
| Sample File-to-File Copy Program | 3-63 |
| Sample File Dump Utility | 3-66 |

<!-- ===== scan page 008 (printed v) - type:text ===== -->

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

<!-- ===== scan page 009 (printed vi) - type:text ===== -->

| | |
|---|---|
| Arithmetic Logic Unit Operations | |
| Control Instructions | |
| Error Messages | 3-114 |
| A Sample Session | 3-115 |

## Chapter 5: CP/M Dynamic Debugging Tool

| | |
|---|---|
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

**Introduction**

| | |
|---|---|
| **Chapter 1: Microsoft BASIC-80 and Applesoft: A Comparison** | **4-3** |
| Features of Microsoft BASIC not found in Applesoft | 4-4 |
| Applesoft Enhancements | 4-6 |
| Features Used Differently in Microsoft BASIC than in Applesoft | 4-7 |
| Changes in BASIC-80 Features | 4-7 |
| Applesoft Features Not Supported | 4-8 |
| **Chapter 2: General Information About BASIC-80** | **4-9** |
| **Chapter 3: BASIC-80 Commands and Statements** | **4-24** |

<!-- ===== scan page 010 (printed vii) - type:text ===== -->

| Chapter 4: BASIC-80 Functions | 4-81 |
| --- | --- |

| Chapter 5: High Resolution Graphics, GBASIC | 4-98 |
| --- | --- |

## Appendices

| | |
| --- | --- |
| New Features in BASIC-80, Release 5.0 | 4-103 |
| BASIC-80 Disk I/O | 4-105 |
| Assembly Language Subroutines | 4-115 |
| Converting Programs to BASIC-80 from BASICs Other Than Applesoft | 4-121 |
| Summary of Error Codes and Error Messages | 4-123 |
| Mathematical Functions | 4-128 |
| ASCII Character Codes | 4-130 |

# PART V: Software Utilities Manual

| | |
| --- | --- |
| Introduction | 5-2 |
| &nbsp;&nbsp;&nbsp;&nbsp;Format Notation | |
| To Prepare Diskettes for Reading and Writing: FORMAT | 5-3 |
| To Make Copies of Diskettes: COPY | 5-7 |
| &nbsp;&nbsp;&nbsp;&nbsp;To Create CP/M System Disks | |
| To Convert 13-Sector CP/M Files from 16-Sector CP/M: RW13 | 5-10 |
| To Configure CP/M for a 56K System: CPM56 | 5-12 |
| To Transfer Files from Apple DOS to CP/M: APDOS | 5-14 |
| To Configure the Apple CP/M Operating Environment: CONFIGIO | 5-16 |
| &nbsp;&nbsp;&nbsp;&nbsp;1. Configure CP/M for External Terminal | |
| &nbsp;&nbsp;&nbsp;&nbsp;2. Redefine Keyboard Characters | |
| &nbsp;&nbsp;&nbsp;&nbsp;3. Load User I/O Configuration | |
| To Transfer CP/M Files from Another Computer: DOWNLOAD and UPLOAD | 5-28 |

<!-- ===== scan page 011 - type:cover ===== -->

# Introduction

<!-- ===== scan page 012 - type:blank ===== -->

<!-- ===== scan page 013 (printed I-1) - type:text ===== -->

# The SoftCard Explained

## The Circuit Card

The Microsoft SoftCard is a plug-in card for the Apple II microcom-
modification, but be sure to read the Installation and Operation Manual to
ensure that you do it correctly.

Once you have installed the SoftCard, you will be able to operate your
Apple in either 6502 or Z-80 mode, using software commands to switch
between the two. Whenever you are in 6502 mode, the SoftCard in no way
affects operation of your Apple.

When in Z-80 mode, you can run both the CP/M operating system from
Digital Research and Microsoft's BASIC interpreter, Version 5.0, which are
included in the SoftCard package.

The SoftCard is easy to install and requires no hardware or software
puter that greatly enhances the software capability of the Apple. The
SoftCard actually contains a Z-80A microprocessor, allowing the Apple to
run software that was written for Z-80 based microcomputers.

## CP/M Operating System

Next to the circuit card itself, CP/M is the most important key to allowing
a wide variety of Z-80 software to run on the Apple. Version 2.2 of CP/M is
included in the SoftCard package.

CP/M (which stands for Control Program/Microprocessors) is an operating
system designed for use with 8080 and Z-80 microprocessors. It is composed
of many small programs whose collective function is to write information to,
and retrieve information from, microcomputer floppy disks. CP/M has been
adapted to run on almost all computers using the 8080 or Z-80 families of
microprocessors and because of its widespread use, a very large group of
high-level languages and application software has been written to operate in
the CP/M environment.

With the advent of the SoftCard, Apple owners are now able to take
advantage of the CP/M Operating System. Microsoft has implemented
CP/M on the Apple II, making all modifications needed to make CP/M run
on the Apple.

Standard CP/M programs will be compatible with Apple CP/M. There is
just one difficulty in loading them on the Apple: Apple disks have a
physically different format than CP/M disks. Before a CP/M program
written for another type of computer can be run on the Apple, it must be
downloaded from a standard CP/M system to the Apple. This process is
described *in detail* in the Software Utilities Manual.

<!-- ===== scan page 014 (printed I-2) - type:text ===== -->

In addition to supporting a wider variety of software, CP/M offers several convenient features not found in Apple DOS. These include easy interface to machine language programs; faster disk I/O; simple file transfer; and wild card file-naming conventions that allow you to refer to multiple files with one name.

## Microsoft BASIC

Microsoft's ANSI-standard BASIC interpreter, in its fifth major release, is also included as part of the SoftCard package. Microsoft BASIC has many features not found in Applesoft. Among these are PRINT USING, CALL, WHILE/WEND, CHAIN and COMMON and built-in Disk I/O statements. In addition, most of the graphics features of Applesoft have been incorporated into Microsoft BASIC to take advantage of the Apple's special capabilities. A complete list of the differences between Microsoft BASIC and Applesoft can be found in Part 4, the Microsoft BASIC Reference Manual.

## The Diskettes

Two diskettes, each containing CP/M and Microsoft BASIC plus several utility programs, are provided. One of the disks is in 13-Sector format and should be used if you don't have a Language Card or DOS 3.3. The other disk is in 16-Sector format and should be used with systems that have the Apple Language Card and/or DOS 3.3. The 16-Sector disk also contains an enhanced version of Microsoft BASIC with high-resolution graphics capabilities.

I-2

<!-- ===== scan page 015 (printed I-3) - type:text ===== -->

# Designers and Manufacturer

## The Softcard Circuit Board

**Designer:** The SoftCard circuit board was designed by Don Burtis of Burtronix, Villa Park, California. Microsoft Consumer Products is grateful to Burtronix for its contribution to making the SoftCard a reality.

**Manufacturer:** The SoftCard circuit board is manufactured for Microsoft Consumer Products by Vista Computer Co. of Santa Ana, California.

## SoftCard Software

The CP/M operating system, Version 2.0, is licensed by Microsoft from Digital Research, Inc., of Pacific Grove, California. The BASIC interpreter included in this package is Microsoft's ANSI-standard BASIC-80, Version 5.0, with additional enhancements to take advantage of the Apple's special capabilities. Neil Konzen, of Microsoft Consumer Products, was instrumental in implementing all of the SoftCard software on the Apple II.

<!-- ===== scan page 016 (printed I-4) - type:text ===== -->

# System Requirements

The SoftCard will operate on an Apple II or Apple II Plus microcomputer with a minimum of 48K RAM and one disk drive.

The SoftCard supports the Apple Language Card system and can utilize 12K of the 16K RAM on the Language Card when in Z-80 mode.

CP/M occupies 7K of RAM, only 5K of which is needed during the execution of user programs. CP/M and MBASIC together occupy just over 29K RAM. CP/M and GBASIC (BASIC with high-resolution graphics, found only on the 16-Sector disk) occupy just over 37K RAM.

When you are in 6502 mode, the SoftCard in no way affects operation of the Apple II.

When in Z-80 mode, all standard Apple I/O peripheral cards and some independent peripherals are supported.

<!-- ===== scan page 017 (printed I-5) - type:text ===== -->

# SoftCard Terminology

There are several terms we use throughout this documentation that you may not understand at first glance. These terms, their definitions, and the reasons we have adopted them are listed below.

| Term | Definition |
| --- | --- |
| **44K System** | Refers to an Apple II or Apple II Plus that has 48K RAM installed. We call it a 44K System, because when you are using the SoftCard (in Z-80 mode), you can address 44K of the 48K total. The 4K you lose is used to handle the Apple screen and CP/M sector read and write routines. |
| **56K System** | Refers to an Apple II or Apple II Plus *with* Language Card (an Apple with 64K RAM installed). As with a 48K system, 4K of the 64K is dedicated to the Apple screen and CP/M sector read and write routines. And since only 12K of the 16K RAM on the Language Card is addressable, you have, in effect, a 56K system. |
| **13-Sector Disk** | Refers to one of the disks in the SoftCard package. This disk should be used if you have Apple DOS 3.2 or earlier and no Language Card. |
| **16-Sector Disk** | Refers to the other disk in the SoftCard package. This disk should be used if you have an Apple Language Card or DOS 3.3. In addition to all of the software on the 13-Sector disk, the 16-Sector disk includes a second version of BASIC, called GBASIC, that includes high-resolution graphics features. |
| **A:-F:** | The names A:, B:, C:, D:, E: and F: refer to disk drives. This is the standard CP/M drive naming convention and since we are using CP/M, it is used throughout this manual. For the relationship of drive names to drives, see the Installation and Operations Manual. |

<!-- ===== scan page 018 (printed I-6) - type:text ===== -->

**External Terminal**
Refers to two types of devices. An external terminal can be a 24 × 80 character video card (such as the Videx Videoterm), or it can actually be a second terminal (such as a Hazeltine or SOROC) that you are using with your system.

**RETURN vs. ⟨cr⟩ vs. carriage return**
All of these mean to press the RETURN key on the Apple keyboard.

<!-- ===== scan page 019 (printed I-7) - type:text ===== -->

# Digital Research License Information

IMPORTANT: Our license with Digital Research for the CP/M Operating System requires that each purchaser of the SoftCard with CP/M register with Microsoft Consumer Products so that records can be maintained of all CP/M owners. This requirement is made by Digital Research, not by Microsoft, and a post card is enclosed for reply. The serial number requested on the card is the number stamped on the disk labels. The registration card also specifies agreement to Digital Research's software license agreement. Before signing the card and returning it to Microsoft, read the software license agreement below carefully.

## DIGITAL RESEARCH

Box 579 Pacific Grove, California, 93950

## SOFTWARE LICENSE AGREEMENT

IMPORTANT: All Digital Research programs are sold only on the condition that the purchaser agrees to the following license. READ THIS LICENSE CAREFULLY. If you do not agree to the terms contained in this license, return the packaged diskette UNOPENED to your distributor and your purchase price will be refunded. If you agree to the terms contained in this license, fill out the REGISTRATION information and RETURN by mail to Microsoft Consumer Products.

DIGITAL RESEARCH agrees to grant and the Customer agrees to accept on the following terms and conditions nontransferable and nonexclusive licenses to use the software program(s) (Licensed Programs) herein delivered with this agreement.

**Term:**

This agreement is effective from the date of receipt of the above-referenced program(s) and shall remain in force until terminated by the Customer upon one month's prior written notice, or by Digital Research as provided below.

Any license under this Agreement may be discontinued by the Customer at any time upon one month's prior written notice. Digital Research may discontinue any license or terminate this Agreement if the Customer fails to comply with any of the terms and conditions of this Agreement.

**License:**

Each program license granted under this Agreement authorizes the Customer to use the Licensed Program in any machine readable form on any single computer system (referred to as System). A separate license is required for each System on which the Licensed Program will be used.

<!-- ===== scan page 020 (printed I-8) - type:text ===== -->

This Agreement and any of the licenses, programs or materials to which it applies may not be assigned, sublicensed or otherwise transferred by the Customer without prior written consent from Digital Research. No right to print or copy, in whole or in part, the Licensed Programs is granted except as hereinafter expressly provided.

**Permission To Copy or Modify Licensed Programs:**
The customer shall not copy, in whole or in part, any Licensed Programs which are provided by Digital Research in printed form under this Agreement. Additional copies of printed materials may be acquired from Digital Research.

Any Licensed Programs which are provided by Digital Research in machine readable form may be copied, in whole or in part, in printed or machine readable form in sufficient number for use by the Customer with the designated System, to understand the contents of such machine readable material, to modify the Licensed Program as provided below, for back-up purposes, or for archive purposes, provided, however, that no more than five (5) printed copies will be in existence under any license at any one time without prior written consent from Digital Research. The Customer agrees to maintain appropriate records of the number and location of all such copies of Licensed Programs. The original, and any copies of the Licensed Programs, in whole or in part, which are made by the Customer shall be the property of Digital Research. This does not imply, of course, that Digital Research owns the media on which the Licensed Programs are recorded. The Customer may modify any machine readable form of the Licensed Programs for his own use and merge it into other program material to form an updated work, provided that, upon discontinuance of the license for such Licensed Program, the Licensed Program supplied by Digital Research will be completely removed from the updated work. Any portion of the Licensed Program included in an updated work shall be used only if on the designated System and shall remain subject to all other terms of this Agreement.

The Customer agrees to reproduce and include the copyright notice of Digital Research on all copies, in whole or in part, in any form, including partial copies of modifications, of Licensed Programs made hereunder.

**Protection and Security:**
The customer agrees not to provide or otherwise make available any Licensed Program including but not limited to program listings, object code and source code, in any form, to any person other than Customer or Digital Research employees, without prior written consent from Digital Research, except with the Customer's permission for purposes specifically related to the Customer's use of the Licensed Program.

<!-- ===== scan page 021 (printed I-9) - type:text ===== -->

## Discontinuance:

Within one month after the date of discontinuance of any license under this Agreement, the Customer will furnish Digital Research a certificate certifying that through his best effort, and to the best of his knowledge, the original and all copies, in whole or in part, in any form, including partial copies in modifications, of the Licensed Program received from Digital Research or made in connection with such license have been destroyed, except that, upon prior written authorization from Digital Research, the Customer may retain a copy for archive purposes.

## Disclaimer of Warranty:

Digital Research makes no warranties with respect to the Licensed Programs. The sole obligation of Digital Research shall be to make available all published modifications or updates made by Digital Research to Licensed Programs which are published within one (1) year from date of purchase, provided Customer has returned the Registration Card delivered with the Licensed Program.

## Limitation of Liability:

THE FOREGOING WARRANTY IS IN LIEU OF ALL OTHER WARRANTIES, EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT WILL DIGITAL RESEARCH BE LIABLE FOR CONSEQUENTIAL DAMAGES EVEN IF DIGITAL RESEARCH HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

## General

If any of the provisions, or portions thereof, of this Agreement are invalid under any applicable statute or rule of law, they are to that extent to be deemed omitted.

<!-- ===== scan page 022 (printed I-10) - type:text ===== -->

# Microsoft Consumer Products Registration Information

Please fill out the SoftCard registration card that is enclosed and return it to us so that we may provide you with information about updates and about new products. The serial number requested on the card is the number printed on the disk labels.

# SoftCard Warranty

Microsoft Consumer Products ("MCP") warrants to the original user of this product that it shall be free of defects resulting from faulty manufacture of the product or its components for a period of ninety (90) days from the date of sale. MCP MAKES NO WARRANTIES REGARDING EITHER THE SATISFACTORY PERFORMANCE (i.e. MERCHANTABILITY) OF THE SOFTWARE ENCODED ON THIS PRODUCT OR THE FITNESS OF THE SOFTWARE FOR ANY PARTICULAR PURPOSE. Defects covered by this Warranty shall be corrected either by repair or, at MCP's election, by replacement. In the event of replacement, the replacement unit will be warranted for the remainder of the original ninety (90) day period or 30 days, whichever is longer.

If this product should require service, return it to Microsoft Consumer Products, 400 108th Ave. NE, Suite 200, Bellevue, Washington 98004, postage prepaid, along with an explanation of the suspected defect. MCP will promptly handle all warranty claims.

THERE ARE NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THOSE OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, WHICH EXTEND BEYOND THE DESCRIPTION AND DURATION SET FORTH HEREIN.

MCP's SOLE OBLIGATION UNDER THIS WARRANTY IS LIMITED TO THE REPAIR OR REPLACEMENT OF A DEFECTIVE PRODUCT AND MCP SHALL NOT, IN ANY EVENT, BE LIABLE FOR ANY INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND RESULTING FROM USE OR POSSESSION OF THIS PRODUCT.

Some states do not allow 1) limitations on how long an implied warranty lasts, or 2) the exclusion or limitation of incidental or consequential damages, so the above limitations or exclusions may not apply to you.

This Warranty gives you specific legal rights, and you may also have other rights which vary from state to state.

<!-- ===== scan page 023 (printed I-11) - type:text ===== -->

# Service Information

If your SoftCard requires repair, please return it to the dealer from whom it was purchased. If it is not possible to return the SoftCard to your dealer, you may send it directly to Microsoft Consumer Products.

If the repair is required during the warranty period, please enclose proof of purchase. During warranty, we will replace or repair your SoftCard without charge. See page I-10 for more details regarding warranty coverage.

If the SoftCard requires service after the warranty period expires, it will be repaired for a flat fee of $39.50. This service charge does not cover damage due to negligence, misuse or inadequate packaging on return to MCP.

To return your SoftCard for service, please mail it post-paid to Microsoft Consumer Products. Package the card securely as we cannot be responsible for damage due to shipping. BE SURE to enclose proof of purchase for warranty work or a check or money order in the amount of $39.50 for non-warranty repairs.

Mail post-paid to:

Microsoft Consumer Products
400 108th Ave. NE, Suite 200
Bellevue, WA 98004

<!-- ===== scan page 024 - type:blank ===== -->

<!-- ===== scan page 025 - type:cover ===== -->

# SoftCard Installation and Operations

<!-- ===== scan page 026 - type:blank ===== -->

<!-- ===== scan page 027 (printed 1-a) - type:frontmatter ===== -->

# PART I: INSTALLATION AND OPERATION

## Chapter 1
### How To Install the SoftCard

| | |
|---|---|
| Apple Peripheral Cards: What Goes Where | 1-2 |
| Interface Cards Compatible with CP/M | 1-2 |
| Placement of Apple Disk Drives | 1-4 |
| Printer Interface Installation | 1-4 |
| General Purposes I/O Installation | 1-5 |
| Using an External Terminal Interface | 1-5 |
| Installation of the SoftCard | 1-5 |

## Chapter 2
### Getting Started with Apple CP/M

| | |
|---|---|
| Bringing Up Apple CP/M | 1-8 |
| How To Copy Your SoftCard Disk | 1-9 |
| Creating CP/M System Disks | 1-11 |
| Using Apple CP/M with the Apple Language Card | 1-13 |
| I/O Configuration | 1-13 |

## Chapter 3
### An Introduction to Apple CP/M

| | |
|---|---|
| Typing at the Keyboard | 1-18 |
| Output Control | 1-19 |
| CP/M Warm Boot: Ctrl-C | 1-19 |
| Changing CP/M Disks | 1-19 |
| CP/M Command Structure | 1-20 |
| CP/M File Naming Conventions | 1-21 |

1-a

<!-- ===== scan page 028 (printed 1-b) - type:frontmatter ===== -->

| | |
|---|---|
| Some CP/M Commands:<br>DIR, ERA, REN, TYPE | 1-22 |
| CP/M Error Messages | 1-23 |
| Description of Programs Included<br>on the SoftCard Disk | 1-26 |

## Chapter 4
## Getting Started with
## Microsoft BASIC

| | |
|---|---|
| Microsoft BASIC | 1-31 |

<!-- ===== scan page 029 (printed 1-1) - type:text ===== -->

# Chapter 1
## How To Install the SoftCard

- Apple Peripheral Cards: What Goes Where
- Interface Cards Compatible with CP/M
- Placement of Apple Disk Drives
- Printer Interface Installation
- General Purpose I/O Installation
- Using an External Terminal Interface
- Installation of the SoftCard

<!-- ===== scan page 030 (printed 1-2) - type:text ===== -->

Installation of the SoftCard is easy, but there are some things you should know before you install it. Improper installation can damage both the SoftCard and the rest of your Apple system. So . . .

**READ THESE INSTRUCTIONS CAREFULLY BEFORE INSTALLING THE SOFTCARD!!**

# Apple Peripheral Cards: What Goes Where

Before you install the SoftCard, you must make sure that your other peripheral cards are installed in the correct peripheral slots in your Apple to insure proper operation with Apple CP/M.

This is necessary because unlike Applesoft and Integer BASIC (but similar to Apple PASCAL), Apple CP/M requires that peripheral I/O cards be plugged into specific slots depending on their intended use. For instance, if you have a printer interface, it should be installed in slot one. This allows you to refer to the printer without specifying a slot number, as is necessary with Applesoft and Integer BASIC. Use the information below as a guide for installing any other peripheral interface cards you might own.

**NOTE to Apple Language Card users:**
The peripheral card slot assignments for Apple CP/M are exactly the same as for Apple Pascal. Therefore, if you have your system set up for use with Apple Pascal, no rearrangement is necessary.

# Interface Cards Directly Compatible With CP/M:

Below is a list of the I/O peripheral card types that are known to be directly compatible with Apple CP/M. The cards listed below, when installed in the appropriate Apple peripheral slot, will work without any software modifications.

| TYPE | CARD NAME |
| --- | --- |
| 1 | Apple Disk II Controller |
| *2 | Apple Communications Interface |
|  | California Computer Systems 7710A Serial Interface |
| 3 | Apple High Speed Serial Interface |
|  | Apple Silentype Printer Interface |
|  | Videx Videoterm 24 × 80 Video Terminal Card |
|  | M&R Enterprises Sup-R-Term 24 × 80 Video Terminal Card |
| 4 | Apple Parallel Printer Card |

<!-- ===== scan page 031 (printed 1-3) - type:mixed ===== -->

\*The CCS 7710A serial interface card is the preferred card of type 2 as it supports hardware handshaking and variable baud rates from 110-19200 baud. The Apple Communications Interface card requires hardware modification for use with data rates other than 110 or 300 baud.

There are some interface cards not listed above that may work with Apple CP/M. As a general rule, any card that is directly compatible with Apple Pascal without requiring any software modifications will probably be directly compatible with Apple CP/M as well. Other peripheral cards may be used if software supplied by the card manufacturer is bound to your Apple CP/M system using the CONFIGIO program. See the Software Details section and the CONFIGIO utility for more information on the implementation of non-standard peripheral cards.

Below is a table of the assigned functions for each of the Apple slots, along with the card types (see above) that are recognized when installed in each. Unless otherwise noted below, unrecognized cards or empty slots are ignored.

**IMPORTANT:** MAKE SURE your Apple is TURNED OFF before you attempt to rearrange your peripheral cards or serious damage may result to your Apple.

| SLOT | VALID CARD TYPES | PURPOSE |
| --- | --- | --- |
| 0 | Not used for I/O | This slot may contain a Language Card or an Applesoft or Integer BASIC ROM card. (The latter are not used by CP/M.) |
| 1 | types 2,3,4 | Line printer interface (CP/M LST: device) |
| 2 | input: 2, 3,4<br>output: 1,2,3,4 | General purpose I/O (CP/M PUN: and RDR: devices) |
| 3 | types 2,3,4 | Console output device (CRT: or TTY:) The normal Apple 24 × 40 screen is used as the TTY: device if no card is present. |
| 4 | type 1 | Disk controller for drives E: and F:. The SoftCard may be installed here if not occupied by a Disk controller card. |
| 5 | type 1 | Disk controller for drives C: and D:. |

<!-- ===== scan page 032 (printed 1-4) - type:mixed ===== -->

| SLOT | VALID CARD TYPES | PURPOSE |
| --- | --- | --- |
| 6 | type 1 | Disk controller for drives A: and B:. (must be present) |
| 7 | any type | No assigned purpose. The SoftCard may be installed in slot 7. |

# Placement of Apple Disk Drives

As indicated in the table above, Apple Disk II controller cards may be installed in slots 6, 5 or 4. You must have at least one disk drive installed in slot six. Disk controller cards are installed in order downward from slot 6, i.e., your second controller should be installed in slot 5, and the third in slot 4.

In CP/M, each of the drives is assigned a letter name, followed by a colon. For instance, the disk in slot 6, drive 1, is CP/M drive A:. (See table below.) This is the way we will refer to your disk drives throughout this documentation. You may want to label each disk drive according to its assigned CP/M name and it is for just that purpose that we enclosed the package of self-adhesive disk drive labels.

| | CP/M name | Slot # | Drive # |
| --- | --- | --- | --- |
| 1st drive: | A: | 6 | 1 |
| 2nd drive: | B: | 6 | 2 |
| 3rd drive: | C: | 5 | 1 |
| 4th drive: | D: | 5 | 2 |
| 5th drive: | E: | 4 | 1 |
| 6th drive: | F: | 4 | 2 |

**NOTE for DOS 3.3 or Apple Pascal users:**
Apple CP/M supports the large-capacity 16-Sector disk format used by DOS 3.3 and Apple Pascal, in addition to standard Apple II 13-Sector format.

# Printer Interface Installation

If you own a printer, its interface card must be installed into slot 1. Most interface cards designed to work with Apple Pascal will work with Apple CP/M as well.

<!-- ===== scan page 033 (printed 1-5) - type:text ===== -->

# General Purpose I/O Installation

General purpose I/O (such as modems, paper tape readers and punches, etc.) must be installed in slot 2. Only those cards noted in Table 1 will be recognized, although other types of cards may be used with interface software supplied by the manufacturer of the card. For more details on interfacing foreign hardware, see the Software Details section, and the CONFIGIO program in the Software Utilities Manual.

# Using an External Terminal Interface

Any of the type 2, 3, or 4 cards of Table 1 can be used to interface an external terminal to Apple CP/M. The terminal interface card must be installed in slot 3.

The SoftCard supports both the Videx Videoterm and M&R Sup-R-Term 24 × 80 character video cards. Other plug-in video boards may be used with interface software supplied by the board manufacturer.

If an interface card is plugged into slot 3, the I/O interface card is used as the terminal device, rather than the Apple 24 × 40 screen and keyboard. If you do have an external terminal interface, we suggest that you remove it from slot 3 and use the normal Apple screen and keyboard until you have configured Apple CP/M for use with your terminal. See CONFIGIO in the Software Utilities Manual.

If you are using an *external* terminal, we suggest that you use either a California Computer Systems 7710A Serial interface or a modified Apple Communications Interface to interface the terminal to your Apple CP/M system. The Apple High Speed Serial Interface will be tolerated, but is not recommended because there is no way for CP/M to check the "status" of this device (i.e., you won't be able to "Ctrl-C" out of a BASIC program).

# Installation of the SoftCard

Now you are ready to install the SoftCard. First,

**MAKE SURE THAT YOUR APPLE IS TURNED OFF!!**

Serious damage to your Apple and to the SoftCard will result if your Apple is left on during installation.

1. With the card laying component-side up in front of you, notice the four small switches on the Apple SoftCard. Make sure that all of these

<!-- ===== scan page 034 (printed 1-6) - type:text ===== -->

switches are OFF. The side of the switch nearest the gold-plated edge connector is DOWN when in the off position. This is the standard operating position for Apple CP/M.

2. With your Apple computer positioned with the keyboard directly in front of you, clear the top of the Apple of miscellaneous monitors, disks, old coffee cups and any other junk. Now remove the top by grasping the cover under its rear lip at each corner with one hand at each corner, pulling up gently till the cover pops loose from its fasteners. Then pull the cover directly out toward the rear of the machine and remove it from your Apple. (The power is off isn't it?)

3. Now you must decide into which slot to install the SoftCard. You may plug the card into any unused slot (except slot zero), but we suggest you install it in slot 4. If slot 4 is occupied by a disk controller card, simply choose any other unused slot.

4. Position the SoftCard's connectors directly over the chosen expansion slot on the Apple's circuit board. Holding the board firmly and vertically, push the connector down into the expansion slot. Insure that the SoftCard is inserted all the way by rocking it gently fore and aft while applying downward pressure. Insure that the SoftCard is not tilted down toward the front of the Apple as this could cause the rear connector fingers to not be fully seated in the expansion slot (which would lead to results that are best not thought about).

5. Make sure that all of your peripheral cards are installed correctly as per the instructions on page 1-2.

6. Carefully replace the Apple's cover. Be sure that the corners pop into place and secure the lid. Now you can rearrange all of your junk just as before.

Now your SoftCard system is ready for use. Checkout of the system consists of bringing up CP/M and using it. BUT, before you turn on your Apple, please read the sections on "Bringing Up Apple CP/M" and "How To Copy Your SoftCard Disk." It is possible to destroy your disks if you do not follow the information in the two sections. So, KEEP READING AND DON'T TURN ON ANYTHING YET.

<!-- ===== scan page 035 (printed 1-7) - type:frontmatter ===== -->

# Chapter 2
# Getting Started with Apple CP/M

- Bringing Up Apple CP/M
- How to copy your SoftCard Disk
- Creating CP/M System Disks
- Using Apple CP/M with the Language Card.
- I/O Configuration

<!-- ===== scan page 036 (printed 1-8) - type:text ===== -->

In the pages to follow, we will show you how to bring up Apple CP/M. PLEASE read this section CAREFULLY and COMPLETELY before you power up your Apple!! You should read completely and understand all the information on pages 1-2 to 1-7 before proceeding.

# Bringing up Apple CP/M

Starting Apple CP/M is simple, but first you must be sure you are using the correct disk.

Two disks are included in the SoftCard package — one in 16-Sector format and the other in 13-Sector format. If you are currently using Apple DOS version 3.3 or Apple Pascal with the Language Card, you must use the 16-Sector disk. If you are currently using DOS 3.2 or earlier, you must use the 13-Sector disk. A 16-Sector disk will NOT boot on a drive set up for 13-Sector disks, and vice-versa.

Select the disk appropriate for your system and insert it into drive A:. (You'll have to start getting used to these drive names — A: is slot 6, drive 1.)

*If you have an Apple II Plus or an Apple II with an Autostart ROM* installed, simply turn the Apple's power on, which will automatically boot the disk.

*If you have a standard Apple II without an Autostart ROM,* boot the disk by first turning the Apple's power on, hitting the RESET key, and then typing 6 Ctrl-K RETURN. Ctrl-K is typed by first pressing the key marked CTRL and holding it down while you press the K key.

After a few seconds, the computer will display

```
APPLE II CP/M
44K vers. 2.2X
(C) 1980 MICROSOFT


A>
```

**NOTE:** If the sign-on message above is not displayed, check to be sure you are using the correct SoftCard disk. Also check to make sure that you have inserted all of your peripheral cards properly.

The "A>" prompt means that CP/M is ready for your command. To see that CP/M is really working, type

```
DIR
```

<!-- ===== scan page 037 (printed 1-9) - type:text ===== -->

and press RETURN to display the names of all of the programs on your SoftCard Master disk. The DIR command and the rest of the CP/M commands will be explained in detail later.

But first, you should . . .

**MAKE A BACKUP COPY OF YOUR SOFTCARD
CP/M MASTER DISK!**

and save the original in a nice, safe, dry, non-magnetic place. In fact, it is a good idea to make more than one copy!

# How To Copy Your SoftCard Disk

**NOTE:** The process below works with both single- and multiple-drive systems. For more information on the use of the FORMAT and COPY programs, see the "Software Utilities Manual."

Copying a CP/M disk is a two-step process. The first step is to use the FORMAT program to "format" a blank disk to use as the backup disk. This process initializes the disk so that it can accept data. Next, you use the COPY program to COPY the master disk onto the newly formatted backup disk.

**NOTE:** CP/M, unlike Apple DOS, does not place the system software on each disk. This means that there are not "slave" or "master" disks in the same sense as with Apple DOS. We refer to the disks shipped with your SoftCard system as "Master Disks" only in the sense that you should save and protect these disks, and not in an operational sense. Also, CP/M disks will not boot up unless the system software is on that particular disk. You must first load CP/M from the system disk before you use any standard CP/M disk.

## Formatting the backup disk

Assuming CP/M is up and running (you should see the A> prompt), and you still have the SoftCard disk in drive A:, type:

```
FORMAT A:
```

and press RETURN. Soon, the Apple will respond by printing:

```
            APPLE II CP/M
     xx SECTOR DISK FORMATTER    (xx 13 or 16 Sector depending
  (C) COPYRIGHT MICROSOFT 1980   on which disk you are using)

  INSERT DISK TO BE FORMATTED INTO DRIVE A:
```

1-9

<!-- ===== scan page 038 (printed 1-10) - type:text ===== -->

Now remove the SoftCard system disk and insert your blank disk. When you are ready to begin, just hit RETURN. Make sure that you have the blank backup disk in the drive when you press RETURN.

The formatting process takes about 30 seconds. The disk drive will remain on during the entire process (you should be able to hear it operating).

When the FORMAT process is complete, the disk will stop and the Apple will type:

```
FORMAT COMPLETED
INSERT SYSTEM DISK AND PRESS RETURN
```

When the red light on the disk drive goes out, remove the newly formatted disk and re-insert the SoftCard system disk. Then press RETURN to return to CP/M. After a second or two, the A> prompt will reappear, letting you know that you have returned to CP/M.

## Copying the backup disk

Now you are ready to copy your SoftCard system disk with the COPY program.
Type:

```
COPY A: = A:
```

After a few seconds, the Apple will display:

```
            APPLE II CP/M             (xx is 13 or 16 Sector
   xx SECTOR DISK COPY PROGRAM        depending on which disk you
        (C) MICROSOFT 1980            are using)

INSERT MASTER DISK     PRESS RETURN
```

Since you want to copy the disk that is already in drive A:, just press RETURN to begin the COPY process. The disk will whirr for a few seconds, then the computer will print:

```
INSERT SLAVE DISK      PRESS RETURN
```

Remove the SoftCard Master disk and insert your freshly formatted backup disk into drive A: and hit RETURN. Again after a few seconds, the computer will prompt:

<!-- ===== scan page 039 (printed 1-11) - type:text ===== -->

```
INSERT MASTER DISK
PRESS RETURN
```

Now remove the backup disk and re-insert the master disk, and hit RETURN.

Finally, the computer will ask you to re-insert the slave disk. This process will be repeated three times.

After you have inserted the slave disk into drive A: for the last time, the computer will display:

```
COPY COMPLETE
DO YOU WISH TO MAKE ANOTHER COPY? (Y/N)
PRESS RETURN
```

Since the disk in the drive is an exact copy of the SoftCard disk, you do not need to re-insert the SoftCard Master Disk. You should now store the SoftCard Master Disk away in a nice, safe, dry, non-magnetic place for safekeeping.

It is a good idea to make at least two backup copies of your SoftCard Master Disk. If you ever have problems that are not immediately identifiable as hardware or software, having a second backup will allow you to test your system without risking your SoftCard Master Disk.

If you have a Language Card, you should definitely make at least three copies as you will need to modify CP/M to take advantage of the additional Language Card memory. We strongly recommend that you do this modification on backup disks and not on your SoftCard Master Disk.

# Creating CP/M System Disks

A CP/M System disk is a disk that will load and initialize CP/M when booted. Creation of CP/M System disks is a two step process: first you must FORMAT the disk, then you must use the COPY program to write the CP/M system onto the disk that will load and run when the system is booted. Below is outlined the process for creating system disks:

1. Use the FORMAT program to format a blank disk. This process is exactly the same as the FORMAT process that you used to copy your SoftCard Master disks earlier.

2. Next, you must use the COPY program to write the CP/M system onto the disk. This is done using the "/S" option as shown below:

<!-- ===== scan page 040 (printed 1-12) - type:text ===== -->

# Use of the COPY program

1. Insert a CP/M system disk that contains the COPY program into drive A: and boot your system. When you see the A> prompt, type

   ```
   COPY A:=A:/S
   ```

   The "/S" means that you only want to copy the CP/M system, not the entire disk. After a second, the computer will display

   ```
   INSERT MASTER DISK     PRESS RETURN
   ```

   Since your disk containing COPY also contains CP/M, just leave the current disk in drive A and press RETURN.

   The disk will whirr for a few seconds then the computer will display the message:

   ```
   INSERT SLAVE DISK      PRESS RETURN
   ```

   Then, insert the disk you want to write the CP/M system onto, and hit RETURN. After a few seconds, the disk will stop and the computer will display

   ```
   INSERT CP/M SYSTEM DISK INTO DRIVE A:
   PRESS RETURN
   ```

   Since the disk in the drive is now a CP/M system disk, you can just hit RETURN to return to CP/M.

   Your new CP/M system disk will now boot and can be used to store programs and data.

   If you have more than one disk drive, or if you wish to create more than one system disk at a time, you should read the "Software Utilities Manual" for more complete information on the use of FORMAT and COPY.

<!-- ===== scan page 041 (printed 1-13) - type:text ===== -->

# Using Apple CP/M with the Apple Language Card

If you are using the Apple Language Card, it is possible to take advantage of the extra 12K of addressable memory contained on the card. This extra 12K of memory makes 56K of contiguous memory space available for use with CP/M. First, however, you must update your CP/M system disk so that 56K CP/M, rather than 44K CP/M, will be invoked when the disk is booted. This is done with the CPM56 utility.

**NOTE:** Updating your CP/M disks in this way does not affect the operation of CP/M. However, a 56K CP/M disk will *NOT BOOT* on a system that is not equipped with a Language Card. We suggest that you do NOT update your SoftCard CP/M Master disk to 56K CP/M. Instead, use one of the backup copies you have just finished making.

To use the CPM56 utility, first make sure CP/M is up and running, (you should see the "A>" prompt) and insert your backup copy of the SoftCard system disk. Then, type:

```
CPM56 A:
```

and hit RETURN. Once you press RETURN, the computer will automatically update your disk. When the conversion is complete, the computer will display the message

```
DISK IN DRIVE A: HAS BEEN UPDATED TO 56K
```

You now have a diskette containing CP/M configured for a 56K system. To load this new version, RE-BOOT your system by either hitting RESET, 6, Ctrl-K (if you don't have an Autostart ROM), or by turning your Apple off and back on again. Soon, the prompt message will re-appear, this time displaying "56K CP/M" instead of ""44K CP/M."

# I/O Configuration

I/O Configuration is the last step in setting CP/M up for your system. This step is not necessary on all systems but you will need to perform it *IF*:

1.  You are using an external terminal

2.  You wish to patch non-standard I/O software to the CP/M system

<!-- ===== scan page 042 (printed 1-14) - type:text ===== -->

The CONFIGIO program is used to perform all of the system configuration process described below. Read the section on CONFIGIO in the "Software Utilities Manual" carefully for more information on the use of CONFIGIO.

Here are the final configurations that may be performed:

**Redefining Keyboard Characters** — If you wish to make it possible to type a character that is not normally available on the Apple keyboard (or on your external terminal if you use one), you can use the CONFIGIO utility of Apple CP/M to redefine the ASCII value that is assigned to any particular key on the keyboard. Since many CP/M programs use characters not found on the Apple keyboard, you will probably find it valuable to use this option. See both Chapter 2 of the "Software and Hardware Details Manual," and CONFIGIO in the "Software Utilities Manual" for complete information on redefining keyboard characters.

**Loading User I/O Driver Software** — The I/O Configuration Block also provides for the support of non-standard Apple peripherals and I/O software. To interface a non-standard peripheral (i.e., a peripheral that the SoftCard does not normally support, see list on page 1-2), you must load the interface software provided by the peripheral manufacturer into the I/O Block. There are specific restrictions regarding the software that can be loaded. For a complete description of these restrictions and for the actual loading process, see both Chapter 2 of the "Software and Hardware Details Manual" and "CONFIGIO" in the "Software Utilities Manual."

**Configuring Apple CP/M for use with an External Terminal** — If you are using an external terminal, you must configure Apple CP/M for use with your terminal. This configuration process is necessary because Apple CP/M supports a number of special screen and cursor control functions (e.g. Clear Screen and Address Cursor) that are used by a number of CP/M programs, such as Microsoft BASIC and the many CP/M word processors. These screen functions are invoked on most terminals by sending a sequence of characters to the terminal, which then performs the appropriate function. So, Apple CP/M must be made to recognize the particular screen function command sequences for your terminal.

Apple CP/M supports most popular video terminals, including the SOROC IQ 120/140, the Hazeltine 1500/1510, and the popular 24 × 80 plug-in video boards, such as the Videx Videoterm and the M&R Sup-R-Term.

As mentioned earlier in the section on installation of the SoftCard, the terminal interface card must be installed in slot 3 of your Apple. "See Apple Peripheral Cards: What Goes Where," page 1-2 for more information on the types of terminal interface cards supported by Apple CP/M.

<!-- ===== scan page 043 (printed 1-15) - type:text ===== -->

Terminal configuration is done using a program written in Microsoft BASIC: CONFIGIO. The use of this program, and the procedure for configuring Apple CP/M to your system can be found in the "Software Utilities Manual."

<!-- ===== scan page 044 (printed 1-16) - type:blank ===== -->

<!-- ===== scan page 045 (printed 1-17) - type:text ===== -->

# Chapter 3
## An Introduction to Apple CP/M

- Typing at the Keyboard
- Output Control
- CP/M Warm Boot: Ctrl-C
- Changing CP/M Disks
- CP/M Command Structure
- CP/M File Naming Conventions
- File Name Specification
- Some CP/M Commands: DIR, ERA, REN, TYPE
- CP/M Error Messages
- Definitions of Programs Included on the SoftCard Disk

<!-- ===== scan page 046 (printed 1-18) - type:text ===== -->

The information presented in this section is intended to be used as a short introduction to CP/M on the Apple II. It will help you get started using CP/M but is in no way intended to replace the standard CP/M documentation as a guide to the complete usage of CP/M. Read the CP/M Reference Manual carefully.

The heart of the CP/M operating system does not lie in the power of its built-in keyboard commands. Instead, CP/M was designed as a link between a computer's hardware and its software. This is the reason for its wide popularity — a program written for CP/M on one machine can be easily transported to another.

Most CP/M "commands" (with the exception of a few such as DIR) are actually *programs* on a disk and so are extensible. To invoke commands of this type, the appropriate disk must be in your drive. Commands executed by loading their program code from the disk in this way are called "transient commands." The COPY and FORMAT commands you used to back up your system disk are transient commands.

# Typing at the Keyboard

Typing at the keyboard with CP/M is quite a bit different than with Integer BASIC or Applesoft. The backspace key deletes the character under the cursor as it moves, and the forward arrow key doesn't work. None of the ESCape key cursor movement/editing features are supported.

However, CP/M supports a few line editing features that are useful when typing at the keyboard. There are also some other important control characters that can be used to perform other useful functions. (Remember: Control characters (denoted by "Ctrl-") are typed by first hitting the CTRL key and holding it down while you type the indicated character).

| Key | Function |
|-----|----------|
| <-- | Backspaces one character position. The backspace key deletes the character under the cursor. (Also invoked with Ctrl-H) |
| Ctrl-X | Backspaces up to the beginning of the line, deleting the line. |
| Ctrl-R | Retypes current line. |
| Ctrl-J | Terminates input same as RETURN key. (Also invoked with LINE FEED) |
| Ctrl-E | Physical end of line. Cursor is moved to beginning of next line, but line is not terminated until RETURN is typed. |
| RUBOUT | Deletes and "echos" (reprints) the last character typed. Also referred to as DEL or DELETE. (Type Ctrl-@ to get RUBOUT on the Apple keyboard — see below) |

1-18

<!-- ===== scan page 047 (printed 1-20) - type:text ===== -->

memory at all times which is used to allocate space on the disk. When you change disks, this information must be replaced with the directory information of the newly inserted disk.

To let CP/M know that you have changed disks, type Ctrl-C to execute a CP/M "Warm Boot." Make sure you do this AFTER you have changed disks. This will cause the disk directory information in the drive to be updated. You should get used to typing Ctrl-C often.

If you do not type Ctrl-C before changing disks and a WRITE is attempted to the changed disk, the computer will display

```
BDOS ERR ON x:Disk R/O      (Where x: is a disk drive A:-F:)
```

(R/O stands for Read Only) When you receive this error message, hit RETURN. This will perform a CP/M warm boot and return you to CP/M. The above error condition applies only to changed disks that are to be WRITTEN. No error will result if you attempt to READ from the changed disk.

Many CP/M programs perform a warm boot upon termination. So, you need not type Ctrl-C to change disks after execution of programs of this type. After a while you will probably recognize the sound of your Apple disk drive during a CP/M warm boot. This is one way to know whether a program performs a warm boot upon completion.

For more information, read the "CP/M Reference Manual — An Introduction to CP/M Features and Facilities." Also see "CP/M Error Messages" later in this section.

# The RESET Key

Pressing the RESET will have different effects, depending on whether your system has an Autostart ROM or not.

**On a system that has an Autostart ROM.** Pressing the RESET key while in CP/M will cause a CP/M warm boot, and you will return to CP/M. Pressing the RESET key while in either MBASIC or GBASIC will result in a "Reset Error," which can be trapped using ON ERROR GOTO, etc.

**On a system that does not have an Autostart ROM.** You can recover from hitting RESET by typing Ctrl-Y then pressing RETURN. You will then either re-boot CP/M (if you hit RESET while in CP/M) or return to BASIC with a "Reset Error" (if you hit RESET while in MBASIC or GBASIC).

<!-- ===== scan page 048 (printed 1-19) - type:text ===== -->

There are a few characters that are normally unavailable on the Apple's keyboard. These have been assigned to certain control characters so that they are available to you:

| Type: | To get: |
| --- | --- |
| Ctrl-K | [ (Left Bracket) |
| Ctrl-@ | RUBOUT |
| Ctrl-B | \ (Backslash) |

These characters are often required by CP/M commands and programs. To change (or do away with) these assignments, or add additional ones, see the CONFIGIO program in the "Software Utilities Manual."

# Output Control

There are two control characters that are used to control character output to the screen and printer:

| | |
| --- | --- |
| Ctrl-S | Temporarily stops character output to the terminal. Program execution and character output resume when any character is typed. |
| Ctrl-P | Sends all character output to the line printer device as well as to the terminal. This "printer echo" mode remains in effect until the next Ctrl-P is typed. |

# CP/M Warm Boot: Ctrl-C

There is also another important control character: Ctrl-C. When typed as the first character of a line, Ctrl-C is used to perform a CP/M "Warm Boot," causing CP/M to be reloaded from the disk to insure that the CP/M in memory is in working order. (This is NOT the same as a *Cold* Boot. A Cold Boot is the act of booting the CP/M disk for the first time.) You should ALWAYS type Ctrl-C whenever you change disks. (See "Changing CP/M Disks," below.)

| | |
| --- | --- |
| Ctrl-C | Perform a CP/M warm boot. |

# Changing CP/M Disks

Unlike Apple DOS, you cannot indiscriminately change disks in drives with CP/M. When you change disks, you must let CP/M know that you have done so. This is because there is certain disk directory information stored in

<!-- ===== scan page 049 (printed 1-21) - type:text ===== -->

# CP/M Command Structure

When you see the "A>" prompt, you know that CP/M is ready for your command. The "A" in the prompt means that drive A: is the "currently logged drive." The "currently logged drive" is the default drive that is used in a file specification if another drive is not specified. It is also the drive that CP/M searches for transient commands if a drive is not specified in the command.

CP/M commands themselves are generally very simple. There are only a handful of non-transient commands, the most useful of which are DIR, ERA, and REN. The DIR command is used to display a disk directory, the ERA command is used to erase disk files, and the REN command is used to rename disk files.

# CP/M File Naming Conventions

Before you are introduced to these CP/M commands, you should become familiar with CP/M disk file naming conventions. CP/M file names are very different than those used with Apple DOS. A file name may be up to 8 characters long, with an optional 3 character "extension." This is a handy construct that lets you identify related files on the disk.

## File Name Specification

The CP/M file specification structure allows you to refer to one *or more* files with a single specification. Files are usually specified in a command by typing the name (up to 8 characters), followed by a period (".") and the 3 character extension. It is also possible to specify the drive in which the file is located. This is done by preceding the file name with the drive name. If no drive is specified, the currently logged drive is assumed. Below are some examples of valid CP/M file name specifications:

```
A:FNAME.EXT       Refers to file FNAME.EXT on drive A:
TEMP.OLD          Refers to file TEMP.OLD on the currently
                  logged drive
B:TEMP.NEW        Refers to file TEMP.NEW on drive B:
```

The 3-character extension usually provides information about the internal format of a file. The most important of these common extensions is COM, which stands for COMMAND. Any file with an extension of COM is a transient command type file and can be invoked by simply typing its name (without the .COM). Other common extensions are BAS, used for BASIC programs; and HEX, ASM, and PRN, which are used (and produced) by the ASM program, which is the CP/M 8080 assembler.

<!-- ===== scan page 050 (printed 1-22) - type:text ===== -->

File specifications can also be used to refer to more than one file at a time. This is done by the use of "wild card" file name specifications. A question mark used in a file name is a "wild card" character, that is, it will match any character in that position when searching the directory for the file name match. An asterisk ("*") is used to match any string of characters. For instance,

```
B:TEMP.???
or
B:TEMP.*
```

refer to both TEMP.OLD and TEMP.NEW on drive B:, if they exist. Below are some more examples of "wild card" file specifications:

| Specification | Meaning |
| --- | --- |
| A:*.COM | Refers to all files on drive A: with an extension of COM |
| B:*.* | Refers to all files on drive B: |
| B:????????.??? | Exactly the same as B:*.* above. |
| DUMP.* | Refers to all files on the currently logged disk beginning with "DUMP" |
| C*.* | Refers to any file on the currently logged disk beginning with the letter "C" |

Note that an "*" is actually an abbreviation of a string of "?"s.

# Some CP/M Commands: DIR, ERA, REN, TYPE

These are the four most commonly used built-in CP/M commands. DIR is used to display the directory of all files on a disk; ERA is used to erase disk files; REN is used to rename disk files; and TYPE is used to display a text file on the terminal. Below is a short introduction to each.

**NOTE:** The information below is meant only as an introduction to a few of the CP/M commands. For more complete information about these and other CP/M commands, see the "CP/M Reference Manual — An Introduction to CP/M Features and Facilities."

## The DIR Command

The DIR command is used to display the names of the files on a disk. To display the directory of all the files on the currently logged disk, type

```
DIR
```

<!-- ===== scan page 051 (printed 1-23) - type:text ===== -->

and press RETURN. To display a directory of the disk in another drive, just include the drive name. For instance,

```
DIR B:
```

will display the directory of the disk in drive B:.

If a file specification is included with the DIR command, only those files whose names match the file specification will be displayed. Here are some examples of the DIR command used with file specifications:

| Command | Description |
| --- | --- |
| `DIR MBASIC.COM` | Displays MBASIC.COM if the file exists on the currently logged disk. |
| `DIR A:*.COM` | Displays all files with an extension of COM on drive A: |
| `DIR B:` | Displays all files on drive B: |
| `DIR A:A*.*` | Displays all files on drive A: whose name begins with the letter "A" |

If there are no files on the disk, or if no files match the file specification, CP/M will respond

```
NO FILE
```

## The ERA Command

The ERA command is used to erase files on the disk. You must always include a file specification with this command.

**NOTE:** *Don't* delete any of the files on your CP/M disk! If you do, you'll have to make another backup copy of the SoftCard Master disk.

Here are a few examples of the use of the ERA command:

| Command | Description |
| --- | --- |
| `ERA B:TEMP.OLD` | Erase the file TEMP.OLD on drive B: |
| `ERA C:*.BAK` | Erase all files on drive C: with extension BAK |
| `ERA *.*` | Erase all of the files on the currently logged disk. If you attempt to erase all of the files on a disk, CP/M will ask ALL (Y/N)?. If you don't want to delete all the files on the disk, respond by typing "N" |

Notice that you can erase more than one file at a time with ERA by using the wild card naming convention.

<!-- ===== scan page 052 (printed 1-24) - type:text ===== -->

# The REN Command

The REN command is used to rename files. Here is the general format of this command:

```
REN newname = oldname
```

where "newname" and oldname" are file specifications. You *cannot* use wild card file specifications with the REN command. You *can* precede the first file specification with a drive name. Below are some examples of the use of the REN command:

```
REN TEMP.NEW = TEMP.OLD        Rename TEMP.OLD as
                               TEMP.NEW
REN B:PEAR.COM = APPLE.COM     Rename   APPLE.COM   on
                               drive B: as PEAR.COM
```

**NOTE:** Unlike Apple DOS, the new file name *precedes* the existing file name (as in algebra, what's on the left side of the " = " becomes what's on the right).

# The TYPE Command

The TYPE command is used to display the contents of a text file on the terminal. You must include a file specification. (Wild card file specifications are not allowed.)

For example, to display the contents of the file DUMP.ASM on the screen, type

```
TYPE DUMP.ASM
```

and press RETURN. If you attempt to TYPE a file that is not a text file, only junk will appear.

**NOTE:** DUMP.ASM is the only text file on the SoftCard Master disk.

# CP/M Error Messages

There are four possible CP/M error messages. Below is listed each message, followed by a list of the possible causes, in the order of their likelihood:

1-24

<!-- ===== scan page 053 (printed 1-25) - type:text ===== -->

## BDOS ERR ON x:BAD SECTOR
(Where x: is a disk drive A:-F:)

This error message can mean any number of things — it does NOT necessarily mean that there is a bad sector on your disk (but it could!). This error message is roughly equivalent to the Apple DOS "DISK I/O ERROR" message. Possible causes:

1. No disk in drive
2. Drive door not closed
3. Disk inserted improperly
4. An attempt was made to access a drive not installed in a controller card (See SELECT error below)
5. A bad disk

When you receive a BAD SECTOR error, CP/M waits for you to type a character from the keyboard. If you type Ctrl-C, a Warm Boot will be performed and you will return to CP/M command mode. Type R to retry the read or write and continue execution. Any other character will cause the error to be ignored and resume execution of the program or operation.

## BDOS ERR ON x:R/O
(where x: is a disk drive A:-F:)

This error message usually means one of two things:

1. You have changed the disk in a drive without typing Ctrl-C
2. There is a write-protect tab covering the notch in the side of your disk

When you receive this error message, CP/M will wait for you to type a character at the keyboard. After you do so, a warm boot will be performed and you will be returned to CP/M.

## BDOS ERR ON x:FILE R/O
(where x: is a disk drive A:-F:)

This error message can mean only one thing:

1. A write was attempted to a file that was marked Read Only with the STAT program

When you receive this error message, CP/M will wait for you to type a character at the keyboard. Type any key to perform a warm boot and return to CP/M.

<!-- ===== scan page 054 (printed 1-26) - type:text ===== -->

For more information on write protection of files with STAT, consult the "CP/M Reference Manual — An Introduction to CP/M Features and Facilities."

## BDOS ERR ON x:SELECT

(where x: is a disk drive A:–F:)

This error message can mean only one thing:

1. An attempt was made to access a non-existent disk drive

When you receive this error message, CP/M will wait for you to enter a character from the keyboard. Type any character to perform a CP/M warm boot and return to CP/M.

**NOTE:** If you only have one drive attached to a disk controller card in your Apple (as is the case with a single-drive system), attempting to access the drive that is not installed will result in a BAD SECTOR error instead of a SELECT error.

# Description of Programs Included on the SoftCard Disk

MBASIC, GBASIC and a number of utility programs are found on the SoftCard disk. All of these programs are described in detail in other sections of the SoftCard Documentation package. Below is a synopsis of the purpose of each program, followed by a reference stating where the complete program documentation can be found.

**APDOS**
This utility program allows you to transfer data from your Apple DOS disks to CP/M disks. APDOS may be used to transfer text and binary files only. (Requires 2 or more disk drives.)

See the "Software Utilities Manual."

**ASM**
ASM is the CP/M 8080 assembler. ASM can be used along with DDT to write and debug 8080 assembly language programs.

See the "CP/M Reference Manual," Chapter 4.

<!-- ===== scan page 055 (printed 1-27) - type:text ===== -->

**CONFIGIO**

The CONFIGIO utility is used to configure the Apple CP/M operating environment to your particular system configuration. It has four major functions — to configure I/O for an external terminal, to redefine keyboard characters, to load user I/O software, and to read and write to the I/O Configuration Block. For more information about the function of I/O Configuration, see Chapter 2 of the "Software and Hardware Details Manual" in addition to the "Software Utilities Manual."

See "Software Utilities Manual."

**COPY**

The COPY program is used to copy CP/M disks, or to create blank CP/M system disks from a newly formatted disk.

See the "Software Utilities Manual."

**DDT**

DDT is the CP/M Dynamic Debugging Tool. It allows dynamic interactive testing and debugging of 8080 assembly language programs.

See the "CP/M Reference Manual," Chapter 5.

**DOWNLOAD**

The DOWNLOAD and UPLOAD utilities enable the user to transfer CP/M files from another CP/M machine to the Apple by means of an RS-232 serial data link. UPLOAD is not included on either of the Apple CP/M disks. Use of these programs requires a working knowledge of 8080 assembly language programming and thus are intended for experienced programmers only.

See the "Software Utilities Manual."

**DUMP**

DUMP displays the contents of a disk file in hexadecimal form. DUMP.ASM is the source listing of the DUMP program, given in Chapter 2 of the CP/M Interface Guide, as an example of an 8080 assembly language program written for the CP/M environment.

See the "CP/M Reference Manual," Chapter 1 and Chapter 2.

<!-- ===== scan page 056 (printed 1-28) - type:text ===== -->

**ED**

ED is the CP/M text editor. It is used to create and edit CP/M text files.

See the "CP/M Reference Manual," Chapter 3.

**FORMAT**

FORMAT formats a blank disk so that it can accept data. A freshly formatted disk will not boot, but it can be used to store programs and data. Use COPY to make a newly formatted disk into a CP/M system disk.

See the "Software Utilities Manual."

**LOAD**

LOAD is used to convert a disk file of extension .HEX into a machine-executable .COM file. LOAD can be used to convert output from the assembler into machine executable code.

See "CP/M Reference Manual," Chapter 1, "Introduction to CP/M Features and Facilities."

**MBASIC**

This is Microsoft BASIC. This version of BASIC is disk BASIC that supports low-resolution graphics, sound, and game controls in addition to many features not found in Applesoft. This version does not support high-resolution graphics.

See the "Microsoft BASIC Reference Manual" for more information.

**PIP**

PIP is one of the most frequently used CP/M programs. It is used to transfer files from one disk to another. It is also used to copy and append disk files. PIP may also be used to transfer files to the terminal devices and to the printer.

See the "CP/M Reference Manual," Chapter 1. For copying an entire disk, or for copying the CP/M system itself to another disk, see COPY in the "Software Utilities Manual."

<!-- ===== scan page 057 (printed 1-29) - type:text ===== -->

| Program | Description |
|---|---|
| **STAT** | STAT provides general status information about disk capacity, file sizes, file indicators and device assignments. File indicators and device assignments can also be altered using this program.<br><br>See the "CP/M Reference Manual," Chapter 1. |
| **SUBMIT** | SUBMIT allows CP/M commands and program input lines to be executed from a disk file rather than from the keyboard for automatic processing.<br><br>See the "CP/M Reference Manual," Chapter 1. |
| **XSUB** | XSUB, when used with SUBMIT, allows character input from a disk file *at all times during* execution of programs.<br><br>See the "CP/M Reference Manual," Chapter 1. |

The following three programs are found only on the 16-Sector SoftCard disk:

| Program | Description |
|---|---|
| **CPM56** | CPM56 is used to update a 44K CP/M system disk to a 56K system disk for use with the Apple Language Card. CPM56 cannot be used with 48K Apple systems.<br><br>See the "Software Utilities Manual." |
| **GBASIC** | GBASIC is the same as MBASIC except that it also supports high-resolution graphics.<br><br>See the "BASIC Reference Manual" for more information. |
| **RW13** | RW13 is used to allow 16-Sector CP/M to access files on a 13-Sector CP/M disk. Used with PIP, RW13 is especially useful for transferring files from a 13-Sector to a 16-Sector diskette. (Requires 2 or more disk drives.)<br><br>See the "Software Utilities Manual." |

<!-- ===== scan page 058 (printed 1-30) - type:blank ===== -->

<!-- ===== scan page 059 (printed 1-31) - type:frontmatter ===== -->

# Chapter 4
# Getting Started with Microsoft BASIC

<!-- ===== scan page 060 (printed 1-32) - type:text ===== -->

Once you have made backup copies of your SoftCard disk, you'll be ready to beg in exploring Microsoft BASIC. As mentioned previously, two versions of BASIC are included in the SoftCard package.

**MBASIC**
Includes all of Microsoft BASIC, Version 5.0, plus low-resolution graphics and some other Applesoft extensions. (A comparision of MBASIC with Applesoft is included in the "BASIC Reference Manual.") MBASIC is found on both the 13-Sector and 16-Sector disks. The name of the file is MBASIC.COM.

**GBASIC**
Includes all of the features of MBASIC *plus* high-resolution graphics. GBASIC is found only on the 16-Sector disk and its filename is GBASIC.COM.

To bring up either MBASIC or GBASIC, you must first be at CP/M command level as indicated on the screen by the A> prompt. If you don't see the prompt, return to page 1-8 Loading CP/M.

The initialization instructions below refer to MBASIC, but may also be used for loading GBASIC simply by substituting GBASIC where MBASIC is typed. Use of the two BASICs is identical except that in GBASIC you also have high-resolution graphics commands available to you.

Once you see the A> prompt, simply type:

```
MBASIC
```

then press RETURN. The computer will reply:

```
BASIC-80 Version 5.xx
Apple CP/M Version
Copyright © 1980 by Microsoft
Created: dd-mm-yy
xxxx Bytes Free
Ok
```

and BASIC is ready to accept commands.

Initialized in this way, BASIC sets certain default parameters: 3 files may be open at any one time during execution of a BASIC program; all the memory up to the start of FDOS in CP/M may be used and the maximum record size is set at 128.

1-32

<!-- ===== scan page 061 (printed 1-33) - type:text ===== -->

If you wish to set these parameters (which are explained further in the "Microsoft BASIC Reference Manual") yourself, you can set certain "switches" when you type in the initialization command. You can also specify a program in the command line to be automatically run when the command is entered. This extended command line format is:

```
MBASIC [⟨filename⟩]  [/F:⟨number of files⟩]  [/M:⟨highest memory
location⟩]   [/S:⟨maximum record⟩]
```

(The square brackets ([]) indicate items that are optional and the angle brackets (⟨⟩) indicate items to be specified by you.)

**The ⟨filename⟩ option** allows you to RUN a program automatically after initialization is complete. A default extension of .BAS is used if none is supplied and the filename is less than nine characters long.

**The /F:⟨number of files⟩ option** sets the number of disk data files that may be open at any one time during the execution of a BASIC program. Each file data block allocated in this fashion requires 166 bytes plus 128 (or number specified by /S:) bytes of memory. The ⟨number of files⟩ may be either decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

**The /M; ⟨highest memory location⟩ option** sets the highest memory location that will be used by MBASIC. In some cases, it is desirable to set the amount of memory well below the CP/M's FDOS to reserve space for assembly language subroutines. In all cases, the highest memory location should be below the start of FDOS (whose address is contained in locations 6 and 7). The ⟨highest memory location⟩ may be decimal, octal (preceded by &O) or hexadecimal (preceded by &H).

**The /S:⟨maximum record size⟩ option** sets the maximum size to be allowed by random files. Any integer may be specified, including integers larger than 128.

Here are a few examples of the different initialization options:

```
A>MBASIC PAYROLL.BAS                Use all memory and 3 files;
                                    load and execute
                                    PAYROLL.BAS

A>MBASIC INVENT/F:6                 Use all memory and 6 files;
                                    load and execute
                                    INVENT.BAS
```

<!-- ===== scan page 062 (printed 1-34) - type:text ===== -->

```
A>MBASIC/M:32768                  Use first 32K of memory and 3
                                  files

A>MBASIC DATACK/F:2/M:&H9000      Use first 36K of memory, 2 files
                                  and execute DATACK.BAS
```

When BASIC is initialized, it types the prompt "Ok." "Ok" means BASIC is at command level, that is, it is ready to accept commands. At this point, it may be used in either direct or indirect mode.

You can now write programs in either MBASIC or GBASIC, depending on which you initialized. Programming in Microsoft BASIC is like programming in Applesoft, but with significantly more power. See the "Microsoft BASIC Reference Manual" for complete documentation on programming in Microsoft BASIC.

This completes the Installation and Operations portion of this manual. At this point, you should have the SoftCard installed and have both CP/M and BASIC up and running. Throughout this section, we have referred you to other sections of the manual for more detailed information. These other sections *are very detailed* and should contain all the information that you need. If after searching carefully, you still cannot find some information, contact your dealer or write a letter to Microsoft Consumer Products. Enjoy yourself! We sincerely hope you will find the SoftCard an exciting and useful addition to your Apple.
