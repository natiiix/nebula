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

    jmp key_loop        ; jump to infinite synchronous key handling loop

hang:
    hlt                 ; halt CPU
    jmp hang            ; infinite hang loop

fill_segments:          ; fill all segment registers (except for CS) with value from EAX
    mov ss, eax
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    ret

%include "print.asm"
%include "keyboard.asm"

; ============================================
; ================    DATA    ================
; ============================================

%include "data/print.asm"
%include "data/keyboard.asm"

msg     db "Hello World!", 0

%include "data/gdt.asm"
%include "data/idt.asm"

times IMAGE_SIZE-($-$$) db 0    ; pad with zeroes to fill IMAGE_SIZE
