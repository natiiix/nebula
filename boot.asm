%macro PRINT 1
    mov si, %1
    call print_str
%endmacro

%macro PRINTLN 1
    PRINT %1
    call newline
%endmacro

[ORG 0x7C00]            ; boot sector memory address

    cli                 ; clear interrupt flag
    cld                 ; lowest-to-highest byte string direction

    mov ax, 0           ; AX = 0
    mov ds, ax          ; DS = 0
    mov ss, ax          ; stack top = 0
    mov sp, 0x9C00      ; stack bottom = 0x2000 behind the beginning of the code

    mov ax, 0xB800      ; VGA text buffer address
    mov es, ax

    PRINTLN msg         ; print string

    mov ax, 0xABCD      ; move test value to AX
    call print16        ; print value in AX

hang:
    jmp hang            ; infinite hang loop

print_str_char:
    call print_char     ; print single character
print_str:
    lodsb               ; load next string character / byte
    cmp al, 0           ; check for null string termination character
    jne print_str_char  ; string printing loop

    ret

print_char:
    mov ah, 0x0F        ; attribute byte - white on black
    mov cx, ax          ; store character and attribute in CX
    movzx ax, byte [ypos]
    mov dx, 160         ; 160 bytes per line (80 columns, 2 bytes per column / character)
    mul dx              ; multiply Y position by number of bytes per line
    movzx bx, byte [xpos]
    shl bx, 1           ; take X position and multiply it by 2 to skip attributes

    mov di, 0           ; start of video memory
    add di, ax          ; add y offset
    add di, bx          ; add x offset

    mov ax, cx          ; restore char/attribute
    stosw               ; write char/attribute
    add byte [xpos], 1  ; advance to right

    ret

print16:
    mov di, hex16       ; get output hex string base address
    mov si, hextab      ; get hex table base address
    mov cx, 4           ; 16 bits = 4 x 4-bit block (4 hex digits)
hexloop:
    rol ax, 4           ; rotate left by 4 bits
    mov bx, ax          ; copy value to BX
    and bx, 0x0F        ; extract last 4 bits
    mov bl, [si + bx]   ; copy character from hex table
    mov [di], bl        ; copy character to output hex string
    inc di              ; increment output hex string index
    dec cx              ; decrement input value 4-bit block counter
    jnz hexloop         ; if there are more 4-bit blocks to process, keep going

    PRINT hexpre        ; print hex value prefix (0x)
    PRINTLN hex16       ; print output hex string

    ret

newline:
    mov byte [xpos], 0  ; carriage return
    add byte [ypos], 1  ; line feed

    ret

xpos    db 0
ypos    db 0

hextab  db "0123456789ABCDEF"
hexpre  db "0x", 0
hex16   db "0000", 0

msg     db "Hello World!", 0

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
