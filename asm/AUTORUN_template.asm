; ================================================================
;   Source for autorun target 'tap'
;   ZASM Tape file for Jupiter ACE - AUTORUN files
;
;   Basen on TAP file template for ZX Spectrum by kio@little-bat.de
;   and AUTORUN template for TASM at Jupiter Ace Archive (www.jupiter-ace.co.uk)
;
;   Copyright (c) McKlaud 2020
;
;   Change log:
;
;   v.0.3 - 2020-10-09  minor corrections/comments (kio)
;   v.0.2 - 2020-10-09  housekeeping & AR_DATA block length update
;   v.0.1 - 2020-10-08  first draft (simple and dirty)
;
; ================================================================
;
; #CODE has an additional argument: the block type (flag byte) for the block.
; Since ZASM 4.2.0 the flag byte in #CODE must be set to NONE for ACE TAPs.
; The assembler adds the block size and the checksum for each block
; as required by the Jupiter ACE .tap file format.
; Block size, flag byte and checksum are not counted in address calculations.
; Default fill byte in 'defs' is 0x00.
;
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
;
; Load with:
;   0 0 bload autorun
;
; ================================================================

startadr        equ     $3C51           ; Start address for MAIN program

CUR_LINK        equ     $3C49           ; Current WORD link (0x3C49 default value)

;------------------
; Filenames definitions - to be worked out
;------------------

;------------------
; AUTORUN file definition
;------------------
headerlength    equ     25              ; neither file type nor checksum byte included
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

; ----------------------------------------------------------------------
#code AUTORUN_HEADER, 0, headerlength, flag=NONE

; TAP Header Block:

;               defw    headerlength+1  ; 2 bytes: block size - added by ZASM
                defb    BIN_type        ; 1 byte:  File Type = Binary
                defb    "autorun   "    ; 10 bytes: the file name
                ;       |----------|     <<< Keep it exactly 10 chars long!
                defw    AUTORUN_DATA_size ; 2 bytes: File Length
                defw    $22E0           ; 2 bytes: Start Address at 24th screen line (8928)
                defw    v_c_link        ; 2 bytes: current word link (NOT USED)
                defw    v_current       ; 2 bytes: CURRENT (NOT USED)
                defw    v_context       ; 2 bytes: CONTEXT (NOT USED)
                defw    v_voclink       ; 2 bytes: VOCLINK (NOT USED)
                defw    v_stkbot        ; 2 bytes: STKBOT (NOT USED)
;               defb    checksum        ; 1 byte:  checksum - added by ZASM


; ----------------------------------------------------------------------
#code AUTORUN_DATA, 0, 31, flag=NONE

; TAP Data Block:

; load and execute:
;
;    LOAD mainfile RUN

AR_DATA_start   defb    0               ; Input buffer start marker
                defb    "LOAD "         ; LOAD
                defb    "mainfile  "    ; 10 bytes: the file name
                ;       |----------|     <<< Keep it exactly 10 chars long!
                defb    $20             ; Space
                defb    "RUN"           ; Word to execute (autorun)
                ;       |--------------| <<< Keep it shorter than 14 chars!
                defs    31 - ($ - AR_DATA_start), $20 ; Fill remaining with space


;=======================================================================
;                                Main file
;=======================================================================

; ----------------------------------------------------------------------
#code MAIN_HEADER, 0, headerlength, flag=NONE

; TAP Header Block:

                defb    DICT_type       ; 1 byte: Block Type
                defb    "mainfile  "    ; 10 bytes: the file name
                ;       |----------|     <<< Keep it exactly 10 chars long!
                defw    MAIN_DATA_size  ; 2 bytes: File Length
                defw    MAIN_DATA       ; 2 bytes: Start Address
                defw    word_lnk        ; 2 bytes: AUTORUN word link field address
                defw    v_current       ; 2 bytes: CURRENT
                defw    v_context       ; 2 bytes: CONTEXT
                defw    v_voclink       ; 2 bytes: VOCLINK
                defw    MAIN_DATA_end   ; 2 bytes: STKBOT


; ----------------------------------------------------------------------
#code MAIN_DATA, startadr, *, flag=NONE

; TAP Data Block:
; Definition of autorun word and machine code.

; ---------------
; RUN word header

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

word_end        equ     $


;------------------------------------------------

#end

