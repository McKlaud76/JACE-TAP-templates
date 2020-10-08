; ================================================================
;   Source for autorun target 'tap'
;   ZASM Tape file for Jupiter ACE - AUTORUN files
;
;   Basen on TAP file template for ZX Spectrum by Günter Woigk
;   and AUTORUN template for TASM at Jupiter Ace Archive (www.jupiter-ace.co.uk)
;
;   Copyright (c) McKlaud 2020
;
;   Change log:
;
;   v.0.1 - 8/10/2020 - first draft (simple and dirty)
;
; ================================================================

; fill byte is 0x00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync
; byte and the checksum byte of the preceding segment are not counted when
; calculating the start address of this segment.

; Compile with ZASM v 4.x
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
;   0 0 bload autorun

;------------------
startadr        equ     $3C51           ; Start address for MAIN program

CUR_LINK        equ     $3C49           ; Current WORD link (0x3C49 default value)

;------------------
; Filenames definitions - to be worked out
;------------------

;------------------
; AUTORUN file definition
;------------------
headerlength    equ     25              ; neither file type nor CRC byte included
headerflag      equ     $20             ; 0x20 = BINARY file type
DICT_type       equ     $00             ; 0x00 = DICTionary block
BIN_type        equ     $20             ; 0x20 = BINary block

;------------------
; Default values of system variables
;------------------
v_c_link        equ     $2020
v_current       equ     $2020
v_context       equ     $2020
v_voclink       equ     $2020
v_stkbot        equ     $2020

;------------------
; ROM routines
;------------------
CLS             equ     $0A24         ; Clear Screen

#target TAP

;=======================================================================
;                             AUTORUN File
;=======================================================================

#code TAP_HEADER, 0, headerlength, NONE
; Juputer ACE TAP header structure:

;               defw    headerlength    ; 2 bytes: always 25 bytes (0x1A) for JACE - added by ZASM
                defb    headerflag      ; 1 byte: File Type = headerflag

                defb    "autorun   "    ; 10 bytes: the file name
;                       |----------|     <<< Keep it exactly 10 chars long!

                defw    AR_DATA_size    ; 2 bytes: File Length
                defw    $22E0           ; 2 bytes: Start Address at 24th screen line
                defw    v_c_link        ; 2 bytes: current word link (NOT USED)
                defw    v_current       ; 2 bytes: CURRENT (NOT USED)
                defw    v_context       ; 2 bytes: CONTEXT (NOT USED)
                defw    v_voclink       ; 2 bytes: VOCLINK (NOT USED)
                defw    v_stkbot        ; 2 bytes: STKBOT (NOT USED)
;               defb    checksum        ; 1 byte: Header Block CheckSum - added by ZASM
;               defw    CODE_DATA_size  ; 2 bytes: TAP 2nd chunck size - added by ZASM

#code AR_DATA, 0, 32, NONE
; AR_DATA executes FORTH command
;    LOAD mainfile RUN

; mainfile to be defined uder main_fname

; FORTH name to defined under run_word and FORTH definiion below

AR_DATA_start  defb     0               ; Input buffer start marker
               defb     "LOAD "         ; LOAD

               defb     "mainfile  "    ; 10 bytes: the file name
;                       |----------|     <<< Keep it exactly 10 chars long!

               defb     $20             ; Space
               defb     "RUN"           ; Word to autorun
;                       |--------------| <<< Keep it shorter than 14 chars!

               defs     31 - ($ - AR_DATA_start), $20 ; Fill remaining with space
;              defb    checksum         ; 1 byte: Header Block CheckSum - added by ZASM

;=======================================================================
;                                Main file
;=======================================================================
; Since ZASM 4.2.0 flag to be NONE for ACE TAPs
#code MAIN_HEADER, 0, headerlength, NONE
; Juputer ACE TAP header structure:

;               defw    headerlength    ; 2 bytes: always 25 bytes (0x1A) for JACE - added by ZASM
                defb    DICT_type       ; 1 byte: Block Type

                defb     "mainfile  "    ; 10 bytes: the file name
;                        |----------|     <<< Keep it exactly 10 chars long!

                defw    DATA_BLK_size   ; 2 bytes: File Length
                defw    DATA_BLK        ; 2 bytes: Start Address
                defw    word_lnk        ; 2 bytes: AUTORUN word link field address
                defw    v_current       ; 2 bytes: CURRENT
                defw    v_context       ; 2 bytes: CONTEXT
                defw    v_voclink       ; 2 bytes: VOCLINK
                defw    DATA_BLK_end    ; 2 bytes: STKBOT
;               defb    checksum        ; 1 byte: Header Block CheckSum - added by ZASM
;               defw    DICT_DATA_size  ; 2 bytes: TAP 2nd chunck size - added by ZASM

#code DATA_BLK, startadr, *, NONE

; DATA block starts here
;------------------------------
; -- RUN word header
word_name       defb    "RUN" + $80     ; Word Name (last letter inverse)
                defw    word_end - $    ; Word Length Field
                defw    CUR_LINK        ; Link Field
word_lnk        defb    $ - word_name - 4  ; Name Length Field
                defw    $ + 2           ; Code Field Address

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;>>>>>>>>>>>>>>>>>> Insert your ASM code here <<<<<<<<<<<<<<<<<<<<
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                call    CLS             ; call 'CLS' in ROM

                call    s_print         ; call 's_print' - print a string
                defb    13              ; print CR to screen
                defb    "A u t o RUN test ..."  ; message
                defb    13,0            ; print CR twice to screen + end marker

                jp      (iy)            ; return to forth

;------------------------------------------------
; s_print - procedure
;
; Pint string message by SPT (2006)
; text message must be placed after the call to 's_print',
; and end with a 0 byte marker.
;
; entry: none
; exit: none

s_print         pop     hl              ; retrieve return address
                ld      a,(hl)          ; into hl
                inc     hl              ; increase by 1
                push    hl              ; store address
                and     a               ; does hold 0
                ret     z               ; if so, z flag set and return
                rst     $08             ; print contents in A reg
                jr      s_print         ; repeat until end marker 0 is found
                ret                     ; return

; -----------------------------
; --- END ---
word_end        equ     $

;               defb    checksum        ; 1 byte: DICT_DATA Block CheckSum - added by ZASM
#end                                    ; code blocks END
