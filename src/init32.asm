[BITS 32]               ; 32-bit instructions

init32:
    cli                 ; disable interrupts (during initialization)
    cld                 ; lowest-to-highest byte string direction

    mov eax, DATA_SEG
    call fill_segments  ; set up segment registers

    mov ebp, 0x90000
    mov esp, ebp        ; set 32-bit stack pointer

    PRINTLN msg         ; print string

    mov eax, 0x1234ABCD ; move test value to EAX
    call print16        ; print value in EAX

    mov eax, CODE_SEG
    call print32

    mov eax, DATA_SEG
    call print32

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

    lidt [idt_desc]     ; load IDT descriptor

    ; 0xFD is 11111101 - enables only IRQ1 (keyboard)
    mov al, 0xFD
    out 0x21, al

    sti
