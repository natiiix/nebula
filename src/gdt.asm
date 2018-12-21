gdt_start:

gdt_null:               ; null segment
    dq 0

gdt_code:               ; code segment
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0b10011010
    db 0b11001111
    db 0x00

gdt_data:               ; data segment
    dw 0xFFFF
    dw 0x0000
    db 0x000
    db 0b10010010
    db 0b11001111
    db 0x00

gdt_end:                ; end of GDT

gdt_desc:               ; GDT descriptor
    dw gdt_end - gdt_start
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
