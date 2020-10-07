; ================================================================
;   Source for target 'tap'
;   ZASM Tape file for Jupiter ACE - BINARY files
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
; Compile with ZASM v 4.2.x or above
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
;   0 0 bload binary
;
; Run the code with:
;   16000 call
;
; ================================================================

startadr        equ     $3E80           ; Start address for BIN files; e.g. 16000

;------------------
; BIN file definition
;------------------
headerlength    equ     25              ; neither block type (flag byte) nor CRC byte included
filetype        equ     $20             ; 0x20 = BINARY file type

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
CLS             equ     $0A24           ; Clear Screen

#target TAP

#code TAP_HEADER, 0, headerlength, flag=NONE
; Jupiter ACE TAP header structure:

;               defw    headerlength    ; 2 bytes: always 25 bytes (0x1A) for JACE - added by ZASM
                defb    filetype        ; 1 byte:  File Type
                defb    "binary    "    ; 10 bytes: the file name
;                       |----------|     <<< Keep it exactly 10 chars long!
                defw    CODE_DATA_size  ; 2 bytes: File Length
                defw    startadr        ; 2 bytes: Start Address
                defw    v_c_link        ; 2 bytes: current word link (NOT USED)
                defw    v_current       ; 2 bytes: CURRENT (NOT USED)
                defw    v_context       ; 2 bytes: CONTEXT (NOT USED)
                defw    v_voclink       ; 2 bytes: VOCLINK (NOT USED)
                defw    v_stkbot        ; 2 bytes: STKBOT (NOT USED)
;               defb    checksum        ; 1 byte: Header Block CheckSum - added by ZASM


#code CODE_DATA, startadr, *, flag=NONE
;               defw    CODE_DATA_size  ; 2 bytes: TAP 2nd chunck size - added by ZASM

; BIN block starts here

;------------------------------
; --  Z80 assembler code and data starting at 'startadr'

                call    CLS            ; call 'CLS' in ROM

                call    s_print        ; call 's_print' - print a string
                defb    13             ; print CR to screen
                defb    "Hello ..."    ; start message
                defb    13,0           ; print CR to screen + end marker

                jp      (iy)           ; return to forth

;------------------------------------------------
; s_print - procedure
;
; Pint string message by SPT (2006)
; text message must be placed after the call to 's_print',
; and end with a 0 byte marker.
;
; entry: none
; exit: none

s_print         pop     hl             ; retrieve return address
                ld      a,(hl)         ; into hl
                inc     hl             ; increase by 1
                push    hl             ; store address
                and     a              ; does hold 0
                ret     z              ; if so, z flag set and return
                rst     $08            ; print contents in A reg
                jr      s_print        ; repeat until end marker 0 is found
                ret                    ; return

; -----------------------------
; --- END ---
endadr          equ     $

;               defb    checksum       ; 1 byte: CODE_DATA Block CheckSum - added by ZASM
#end                                   ; code blocks END
