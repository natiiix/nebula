SECTION .text

load_idt:
    cli                 ; disable interrupts (during initialization)

    ; ICW1 - begin initialization
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    ; ICW2 - remap offset address of idt_table
    ; In x86 protected mode, we have to remap the PICs beyond 0x20 because
    ; Intel have designated the first 32 interrupts as "reserved" for cpu exceptions
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al

    ; ICW3 - setup cascading
    mov al, 0
    out 0x21, al
    out 0xA1, al

    ; ICW4 - environment info
    mov al, 1
    out 0x21, al
    out 0xA1, al

    ; Initialization finished

    ; mask interrupts
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al

    ; The 32-bit address of the event handler routine must be split
    ; into low and high 16-bit parts to fit the IDT entry structure.
    mov eax, keyhandler
    mov word [idt_key_low], ax
    shr eax, 16
    mov word [idt_key_high], ax

    lidt [idt_desc]     ; load IDT descriptor

    ; 0xFD is 11111101 - enables only IRQ1 (keyboard)
    mov al, 0xFD
    out 0x21, al

    sti
    ret
