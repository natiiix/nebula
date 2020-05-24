; Set stack top at 16MiB address.
; This should be enough stack space for now.
STACK_TOP equ 1 << 24

%include "print_macros.asm"

SECTION .text

; Entry point of the entire kernel.
global _start
_start:
    jmp load_gdt

gdt_loaded:
    mov esp, STACK_TOP  ; set stack pointer to predefined top address
    cld                 ; lowest-to-highest direction of bytes in string

    call enable_cursor  ; VGA text-mode cursor is disabled when GRUB menu is disabled (timeout=0)

    PRINTLN welcomemsg  ; print welcome message
    call load_idt       ; load IDT to enable keyboard event handler

    jmp shell_start     ; jump to shell code (infinite loop, no need for halt)

%include "multiboot.asm"

%include "load_gdt.asm"
%include "load_idt.asm"

%include "print.asm"
%include "keyboard.asm"
%include "string.asm"
%include "shell.asm"

; ============================================
; ================    DATA    ================
; ============================================

%include "data/gdt.asm"
%include "data/idt.asm"
%include "data/print.asm"
%include "data/keyboard.asm"
%include "data/shell.asm"

SECTION .rodata

welcomemsg  db "Welcome to Nebula!", LF, "Source code: https://github.com/natiiix/nebula", 0
