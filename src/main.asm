%macro PRINT 1
    mov esi, %1
    call print_str
    call finish_print
%endmacro

%macro PRINTLN 1
    mov esi, %1
    call print_str
    call terminate_line
    call finish_print
%endmacro

%include "init16.asm"
%include "init32.asm"

    jmp shell_start     ; jump to Shell code (infinite loop)

%include "lowlevel.asm"

%include "print.asm"
%include "keyboard.asm"
%include "string.asm"
%include "shell.asm"

; ============================================
; ================    DATA    ================
; ============================================

%include "data/print.asm"
%include "data/keyboard.asm"
%include "data/shell.asm"

msg     db "Hello World!", 0

%include "data/gdt.asm"
%include "data/idt.asm"

times IMAGE_SIZE-($-$$) db 0    ; pad with zeroes to fill IMAGE_SIZE
