[ORG 0x7C00]

    xor ax, ax      ; ax = 0
    mov ds, ax      ; ds = ax

    mov si, msg     ; si = msg
    cld             ; lowest-to-highest address string direction

ch_loop:
    lodsb           ; al = *si++
    or al, al
    jz hang         ; al == '\0'

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10        ; BIOS print character interrupt

    jmp ch_loop     ; string printing loop

hang:
    jmp hang        ; infinite hang loop

msg     db 'Hello World!', 13, 10, 0

	times 510-($-$$) db 0
    db 0x55
    db 0xAA         ; boot sector signature
