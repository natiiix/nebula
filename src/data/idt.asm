SECTION .data

idt_start:
    ; Exceptions are in the 0x00 - 0x1F range.
    ; https://en.wikipedia.org/wiki/Interrupt_descriptor_table#Protected_mode
    ; IRQs are remapped into the 0x20 - 0x2F range.
    ; https://wiki.osdev.org/Interrupts#General_IBM-PC_Compatible_Interrupt_Information
    times 0x30 dq 0
idt_end:

SECTION .rodata

idt_desc:
    dw idt_end - idt_start - 1  ; limit (size of IDT in bytes minus 1)
    dd idt_start                ; base address of IDT
