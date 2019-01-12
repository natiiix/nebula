[BITS 16]               ; 16-bit instructions
[ORG 0x7C00]            ; boot sector memory address

%include "bootloader.asm"

init16:                 ; kernel initialization (enter protected mode)
    cli

    mov eax, 0
    call fill_segments  ; set up segment registers

    mov sp, 0xFFFC      ; set 16-bit stack pointer

    lgdt [gdt_desc]     ; load GDT

    mov eax, cr0        ; enable bit 0 of CR0
    or eax, 0b1
    mov cr0, eax

    jmp CODE_SEG:init32 ; jump to protected mode code to finish kernel initialization
