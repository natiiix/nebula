; Structure of the 8-byte IA-32 IDT entries.
; https://wiki.osdev.org/Interrupt_Descriptor_Table#Structure_IA-32
STRUC idt_entry
    .handler_low    resw 1  ; low 16-bit half of the 32-bit interrupt handler address
    .segment        resw 1  ; segment in which the interrupt handler code is located
    .zero           resb 1  ; unused, always 0
    .attributes     resb 1  ; see the link above for a detailed explanation
    .handler_high   resw 1  ; high 16-bit half of the 32-bit interrupt handler address
ENDSTRUC
