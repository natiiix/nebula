_idt:
    times 0x21 dq 0

    dw keyhandler
    dw 0x0008
    db 0
    db 0x8E
    dw 0

    times 0xDE dq 0

idt_desc:
    dw (0x100 * 8) - 1  ; limit
    dd _idt             ; base
