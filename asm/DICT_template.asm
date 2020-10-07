; ================================================================
;   Source for target 'tap'
;   ZASM Tape file for Jupiter ACE - DICTIONARY files
;
;   Basen on TAP file template for ZX Spectrum by Günter Woigk
;
;   Copyright (c) McKlaud 2020
; ================================================================

; fill byte is 0x00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync
; byte and the checksum byte of the preceding segment are not counted when
; calculating the start address of this segment.

; Compine with ZASM v 4.x
; zasm --z80 --dotnames -uwy source.asm target.tap
;
; --z80       - traget Zilog Z80 (default)
; --dotnames  - allow label names starting with a dot '.' - if needed
; -b          - write output in binary file (default)
; -u          - include object code in list file
; -w          - append label listing to list file
; -y          - include cpu clock cycles in list file
;
; zasm -uwy source.asm target.tap

; Load with:
;   load filename

startadr        equ     $3C51           ; Start address for DICT files

CUR_LINK        equ     $3C49           ; Current WORD link (0x3C49 default value)

;------------------
; DICT file definition
;------------------
headerlength    equ     25              ; neither file type nor CRC byte included
headerflag      equ     $00             ; 0x00 = DICT file type

;------------------
; Default values of system variables
;------------------
v_current       equ     $3C4C
v_context       equ     $3C4C
v_voclink       equ     $3C4F

;------------------
; ROM routines
;------------------
CLS             equ     $0A24           ; Clear Screen
PR_STRING2      equ     $097F           ; Print String. DE=String Address, BC=String Lenght

#target TAP

#code TAP_HEADER, 0, headerlength-1, headerflag
; Juputer ACE TAP header structure:

;               defw    headerlength    ; 2 bytes: always 25 bytes (0x1A) for JACE - added by ZASM
;               dewb    file_type       ; 1 byte: File Type = headerflag - added by ZASM§
                defb    "dict      "    ; 10 bytes: the file name
;                       |----------|     <<< Keep it exactly 10 chars long!
                defw    DICT_DATA_size  ; 2 bytes: File Length
                defw    DICT_DATA       ; 2 bytes: Start Address
                defw    word2_lnk       ; 2 bytes: last WORD link field address
                defw    v_current       ; 2 bytes: CURRENT
                defw    v_context       ; 2 bytes: CONTEXT
                defw    v_voclink       ; 2 bytes: VOCLINK
                defw    DICT_DATA_end   ; 2 bytes: STKBOT
;               defb    checksum        ; 1 byte: Header Block CheckSum - added by ZASM
;               defw    DICT_DATA_size  ; 2 bytes: TAP 2nd chunck size - added by ZASM

; Since ZASM 4.2.0 flag to be NONE for ACE TAPs
#code DICT_DATA, startadr, *, NONE

; DICT words block starts here

;------------------------------
; -- 1st word (WORD1) header

word1_name      defb    "WORD1" + $80           ; WORD Name (last letter in inverse)
                defw    word2_lnk - word1_lnk   ; Word Length Field
                defw    CUR_LINK                ; Link Field
word1_lnk       defb    $ - word1_name - 4      ; Name Length Field
                defw    $ + 2                   ; Code Field Address

;------------------------------
; --- WORD1 code ---

                call    CLS                     ; call 'CLS' from ROM
                ld      de,text1
                ld      bc,Ltext1
                call    PR_STRING2              ; call "PRINT STRING"

                jp      (iy)                    ; return to FORTH

text1           defb    "H E L L O",13,13       ; message to be printed
Ltext1          equ     $-text1

word1_end       equ     $

;------------------------------
; -- 2md word (WORD2) header

word2_name      defb    "WORD2" + $80           ; WORD Name (last letter inverse)
                defw    word2_end - $           ; Word Length Field
                defw    word1_lnk               ; Link Field
word2_lnk       defb    $ - word2_name - 4      ; Name Lenght Field
                defw    $ + 2                   ; Code Field Address

;------------------------------
; --- WORD2 code ---

                ld      de,text2
                ld      bc,Ltext2
                call    PR_STRING2              ; call "PRINT STRING"

                jp      (iy)                    ; return to FORTH

text2           defb    "WORLD",13,13
Ltext2          equ     $-text2

word2_end       equ     $

; -----------------------------
; --- Next word header & code ---

; -----------------------------
; --- END ---
endadr          equ     $

;               defb    checksum       ; 1 byte: DICT_DATA Block CheckSum - added by ZASM
#end                                          ; code blocks END
