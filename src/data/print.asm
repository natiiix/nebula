SECTION .data

; VGA cursor position
xpos    db 0
ypos    db 0

; conversion table from 4-bit value to hexadecimal digit
hextab  db "0123456789ABCDEF"
hexpre  db "0x", 0
hexstr  db "00000000", 0
hexaddr dd 0
