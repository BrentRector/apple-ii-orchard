; msbasic_errors.inc -- Microsoft BASIC-80 (SoftCard CP/M 2.20) ERROR CODES.
; GENERATED from the error-message table (cpm_pipeline.basic.errmsg). The error
; code is the value loaded into E before JP RAISE_ERROR / ERROR_DISPATCH ($0D89);
; the printer scans E messages forward from ERROR_MESSAGE_TABLE. EQUs are
; zero-width, so INCLUDEing this is byte-identical.

ERR_NEXT_WITHOUT_FOR           EQU 1   ; NEXT without FOR
ERR_SYNTAX_ERROR               EQU 2   ; Syntax error
ERR_RETURN_WITHOUT_GOSUB       EQU 3   ; RETURN without GOSUB
ERR_OUT_OF_DATA                EQU 4   ; Out of DATA
ERR_ILLEGAL_FUNCTION_CALL      EQU 5   ; Illegal function call
ERR_OVERFLOW                   EQU 6   ; Overflow
ERR_OUT_OF_MEMORY              EQU 7   ; Out of memory
ERR_UNDEFINED_LINE_NUMBER      EQU 8   ; Undefined line number
ERR_SUBSCRIPT_OUT_OF_RANGE     EQU 9   ; Subscript out of range
ERR_DUPLICATE_DEFINITION       EQU 10  ; Duplicate Definition
ERR_DIVISION_BY_ZERO           EQU 11  ; Division by zero
ERR_ILLEGAL_DIRECT             EQU 12  ; Illegal direct
ERR_TYPE_MISMATCH              EQU 13  ; Type mismatch
ERR_OUT_OF_STRING_SPACE        EQU 14  ; Out of string space
ERR_STRING_TOO_LONG            EQU 15  ; String too long
ERR_STRING_FORMULA_TOO_COMPLEX EQU 16  ; String formula too complex
ERR_CANT_CONTINUE              EQU 17  ; Can't continue
ERR_UNDEFINED_USER_FUNCTION    EQU 18  ; Undefined user function
ERR_NO_RESUME                  EQU 19  ; No RESUME
ERR_RESUME_WITHOUT_ERROR       EQU 20  ; RESUME without error
ERR_UNPRINTABLE_ERROR          EQU 21  ; Unprintable error
ERR_MISSING_OPERAND            EQU 22  ; Missing operand
ERR_LINE_BUFFER_OVERFLOW       EQU 23  ; Line buffer overflow
ERR_UNUSED_24                  EQU 24  ; (unused)
ERR_UNUSED_25                  EQU 25  ; (unused)
ERR_FOR_WITHOUT_NEXT           EQU 26  ; FOR Without NEXT
ERR_UNUSED_27                  EQU 27  ; (unused)
ERR_UNUSED_28                  EQU 28  ; (unused)
ERR_WHILE_WITHOUT_WEND         EQU 29  ; WHILE without WEND
ERR_WEND_WITHOUT_WHILE         EQU 30  ; WEND without WHILE
ERR_RESET_ERROR                EQU 31  ; Reset error
ERR_FIELD_OVERFLOW             EQU 50  ; FIELD overflow
ERR_INTERNAL_ERROR             EQU 51  ; Internal error
ERR_BAD_FILE_NUMBER            EQU 52  ; Bad file number
ERR_FILE_NOT_FOUND             EQU 53  ; File not found
ERR_BAD_FILE_MODE              EQU 54  ; Bad file mode
ERR_FILE_ALREADY_OPEN          EQU 55  ; File already open
ERR_UNUSED_56                  EQU 56  ; (unused)
ERR_DISK_I_O_ERROR             EQU 57  ; Disk I/O error
ERR_FILE_ALREADY_EXISTS        EQU 58  ; File already exists
ERR_UNUSED_59                  EQU 59  ; (unused)
ERR_UNUSED_60                  EQU 60  ; (unused)
ERR_DISK_FULL                  EQU 61  ; Disk full
ERR_INPUT_PAST_END             EQU 62  ; Input past end
ERR_BAD_RECORD_NUMBER          EQU 63  ; Bad record number
ERR_BAD_FILE_NAME              EQU 64  ; Bad file name
ERR_UNUSED_65                  EQU 65  ; (unused)
ERR_DIRECT_STATEMENT_IN_FILE   EQU 66  ; Direct statement in file
ERR_TOO_MANY_FILES             EQU 67  ; Too many files
ERR_DISK_READ_ONLY             EQU 68  ; Disk Read Only
ERR_DRIVE_SELECT_ERROR         EQU 69  ; Drive select error
ERR_FILE_READ_ONLY             EQU 70  ; File Read Only

