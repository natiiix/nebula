SECTION .data

; VGA cursor position
xpos    db 0
ypos    db 0

; String used for printing hexadecimal numbers.
hexstr      db "00000000"
; Null terminator character of the hexstr.
hexstr_end  db 0

; Pointer into the hexstr used for printing hexadecimal numbers.
hexaddr dd 0

SECTION .rodata

; Conversion table from 4-bit value to hexadecimal digit.
hextab  db "0123456789ABCDEF"
; Prefix used when printing hexadecimal values.
hexpre  db "0x", 0
