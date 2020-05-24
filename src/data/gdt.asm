SECTION .rodata

gdt_start:              ; GDT - Global Descriptor Table - used for memory segmentation

gdt_null:               ; null segment - reserved by design, never actually used
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
    db 0x00
    db 0b10010010
    db 0b11001111
    db 0x00

gdt_end:                ; end of GDT

gdt_desc:               ; GDT descriptor
    dw gdt_end - gdt_start - 1      ; size of GDT in bytes minus 1
    dd gdt_start                    ; offset - address of the actual GDT

CODE_SEG equ gdt_code - gdt_start   ; ID of the code segment
DATA_SEG equ gdt_data - gdt_start   ; ID of the data segment
