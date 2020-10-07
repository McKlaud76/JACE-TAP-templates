; ================================================================
;   Source for target 'tap'
;   ZASM Tape file for Jupiter ACE - DICTIONARY files
;
;   Basen on TAP file template for ZX Spectrum by kio@little-bat.de
;
;   Copyright (c) McKlaud 2020
;
;   Change log:
;
;   v.0.3 - 7/10/2020 - naming, comments (kio)
;   v.0.2 - 7/10/2020 - spelling corrections and housekeeping
;   v.0.1 - 1/10/2020 - first release
;
; ================================================================
;
; fill byte is 0x00
; #code has an additional argument: the block type (flag byte) for the block.
; Since ZASM 4.2.0 the flag byte in #CODE must be set to NONE for ACE TAPs.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync
; byte and the checksum byte of the preceding segment are not counted when
; calculating the start address of this segment.
;
; Compine with ZASM 4.2.x or above
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
;
; Load with:
;   load filename
;
; ================================================================

startadr        equ     $3C51           ; Start address for DICT files

CUR_LINK        equ     $3C49           ; Current WORD link (0x3C49 default value)

;------------------
; DICT file definition
;------------------
headerlength    equ     25              ; neither block type (flag byte) nor CRC byte included
filetype        equ     $00             ; 0x00 = DICT file type

;------------------
; Default values of system variables
;------------------
v_current       equ     $3C4C
v_context       equ     $3C4C
v_voclink       equ     $3C4F

;------------------
; Jupiter ACE ROM routines
;------------------
CLS             equ     $0A24           ; Clear Screen
PR_STRING2      equ     $097F           ; Print String. DE=String Address, BC=String Lenght

CF_DOCOLON      equ     $0EC3           ; DoColon
F_STK_WORD      equ     $1011           ; Stack next word
F_BASE          equ     $048A           ; BASE
F_CSTORE        equ     $08A5           ; C!
F_FORTHEND      equ     $04B6           ; End a FORTH word definition

#target TAP

#code TAP_HEADER, 0, headerlength, flag=NONE
; Jupiter ACE TAP header structure:

;               defw    headerlength    ; 2 bytes: always 25 bytes (0x1A) for JACE - added by ZASM
                defb    filetype        ; 1 byte:  File Type
                defb    "dict      "    ; 10 bytes: the file name
;                       |----------|     <<< Keep it exactly 10 chars long!
                defw    DICT_DATA_size  ; 2 bytes: File Length
                defw    DICT_DATA       ; 2 bytes: Start Address
                defw    hex_lnk       ; 2 bytes: last WORD link field address
                defw    v_current       ; 2 bytes: CURRENT
                defw    v_context       ; 2 bytes: CONTEXT
                defw    v_voclink       ; 2 bytes: VOCLINK
                defw    DICT_DATA_end   ; 2 bytes: STKBOT
;               defb    checksum        ; 1 byte: Header Block CheckSum - added by ZASM


#code DICT_DATA, startadr, *, flag=NONE
;               defw    DICT_DATA_size  ; 2 bytes: TAP 2nd chunck size - added by ZASM

; DICT words block starts here

;------------------------------
; -- 1st word (HELLO) header

hello_name      defb    "HELLO" + $80           ; WORD Name (last letter in inverse)
                defw    hex_lnk - hello_lnk   ; Word Length Field
                defw    CUR_LINK                ; Link Field
hello_lnk       defb    $ - hello_name - 4      ; Name Length Field
                defw    $ + 2                   ; Code Field Address

;------------------------------
; --- HELLO code ---

                call    CLS                     ; call 'CLS' from ROM
                ld      de,text1
                ld      bc,Ltext1
                call    PR_STRING2              ; call "PRINT STRING"

                jp      (iy)                    ; return to FORTH

text1           defb    "H E L L O",13,13       ; message to be printed
Ltext1          equ     $-text1

hello_end       equ     $

;------------------------------
; -- 2nd word (HEX) header

hex_name        defb    "HEX" + $80           ; WORD Name (last letter inverse)
                defw    hex_end - $           ; Word Length Field
                defw    hello_lnk             ; Link Field
hex_lnk         defb    $ - hex_name - 4      ; Name Lenght Field
                defw    CF_DOCOLON            ; Code Field Address

;------------------------------
; --- OCT code is listable and editable in FORTH ---

                defw    F_STK_WORD            ; Push next word (2 bytes) on the stack
                defw    16                    ;
                defw    F_BASE                ; BASE
                defw    F_CSTORE              ; C!
                defw    F_FORTHEND            ; End of new word definition

hex_end         equ     $

; -----------------------------
; --- Next word header & code ---

; -----------------------------
; --- END ---
endadr          equ     $

;               defb    checksum       ; 1 byte: DICT_DATA Block CheckSum - added by ZASM
#end                                          ; code blocks END
