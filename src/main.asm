; Set stack top at 16MiB address.
; This should be enough stack space for now.
STACK_TOP equ 1 << 24

; Structures and macros

%include "struct/idt.asm"

%include "macro/print.asm"
%include "macro/benchmark.asm"

SECTION .text

; Entry point of the entire kernel.
global _start
_start:
    jmp load_gdt

gdt_loaded:
    mov esp, STACK_TOP  ; set stack pointer to predefined top address
    cld                 ; lowest-to-highest direction of bytes in string

    call enable_cursor  ; VGA text-mode cursor is disabled when GRUB menu is disabled (timeout=0)
    call clear_screen   ; clear the VGA text buffer to remove any remnants of the BIOS/bootloader in the background

    PRINTLN welcomemsg  ; print welcome message
    call load_idt       ; load IDT to enable keyboard event handler

    mov eax, primary_heap_tab
    call print32

    mov eax, 0x02000001
    call malloc
    mov eax, esi
    call print32
    mov eax, dword [primary_heap_tab]
    call print32
    mov eax, dword [primary_heap_tab + 4]
    call print32
    mov eax, dword [primary_heap_tab + 8]
    call print32
    mov eax, dword [primary_heap_tab + 12]
    call print32
    mov eax, dword [primary_heap_tab + 16]
    call print32

; If in benchmark mode, run the defined benchmark code instead of the shell loop.
%if BENCHMARK_MODE_ENABLED
    BENCHMARK_BEGIN
    BENCHMARK_CODE
    BENCHMARK_END
%endif

    jmp shell_start     ; jump to shell code (infinite loop, no need for halt)

; Data

%include "multiboot.asm"

%include "data/gdt.asm"
%include "data/idt.asm"
%include "data/print.asm"
%include "data/heap.asm"
%include "data/keyboard.asm"
%include "data/shell.asm"
%include "data/benchmark.asm"

; Code

%include "load_gdt.asm"
%include "load_idt.asm"

%include "print.asm"
%include "heap.asm"
%include "keyboard.asm"
%include "rtc.asm"
%include "string.asm"
%include "shell.asm"

SECTION .rodata

welcomemsg  db "Welcome to Nebula!", LF, "Source code: https://github.com/natiiix/nebula", 0
