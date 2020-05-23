SECTION .data

idt_start:
    times 0x21 dq 0

idt_key_low:
    dw 0
    dw CODE_SEG
    db 0
    db 0x8E
idt_key_high:
    dw 0

    times 0xDE dq 0

SECTION .rodata

idt_desc:
    dw (0x100 * 8) - 1  ; limit
    dd idt_start        ; base
