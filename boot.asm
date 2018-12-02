%macro print 1
    mov si, %1
    call bios_print
%endmacro

[ORG 0x7C00]

    cld             ; lowest-to-highest address string direction

    xor ax, ax      ; ax = 0
    mov ds, ax      ; ds = ax

    print msg

hang:
    jmp hang        ; infinite hang loop

bios_print:
    lodsb           ; al = *si++
    or al, al
    jz return       ; al == '\0'

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10        ; BIOS print character interrupt

    jmp bios_print  ; string printing loop

return:             ; label used for conditional return
    ret

msg     db 'Hello World!', 13, 10, 0

	times 510-($-$$) db 0
    db 0x55
    db 0xAA         ; boot sector signature
