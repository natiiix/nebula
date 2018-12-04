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

    mov ax, 0           ; prepare 0 in AX register
    mov ds, ax          ; set data segment to 0
    mov ss, ax          ; set stack segment to 0
    mov sp, 0x9C00      ; set top of stack to address 0x2000 behind the beginning of the code

    mov ax, 0xB800      ; VGA text buffer address
    mov es, ax

    PRINTLN msg         ; print string

    mov eax, 0x1234ABCD ; move test value to EAX
    call print16        ; print value in EAX

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

print8:                 ; print 8-bit value in AL
    mov cx, 2
    jmp printhex

print16:                ; print 16-bit value in AX
    mov cx, 4
    jmp printhex

print32:                ; print 32-bit value in EAX
    mov cx, 8
    jmp printhex

printhex:
    mov si, hextab      ; copy hex table base address into source register

    mov bx, hexstr + 8  ; get end address of output hex string
    mov di, bx          ; copy end address to destination register
    sub bx, cx          ; subtract number of digits from end address to get beginning address
    mov [hexaddr], bx   ; store beginning address in memory for later printing

hexloop:
    dec di              ; decrement output hex string index (move one character to left)
    mov ebx, eax        ; copy value to EBX
    and ebx, 0xF        ; extract last 4 bits
    mov bl, [si + bx]   ; copy character from hex table
    mov [di], bl        ; copy character to output hex string
    shr eax, 4          ; shift right by 4 bits
    dec cx              ; decrement input value 4-bit block counter
    jnz hexloop         ; if there are more 4-bit blocks to process, keep going

    PRINT hexpre        ; print hex value prefix (0x)
    PRINTLN [hexaddr]   ; print output hex string

    ret

newline:
    mov byte [xpos], 0  ; carriage return
    add byte [ypos], 1  ; line feed

    ret

xpos    db 0
ypos    db 0

hextab  db "0123456789ABCDEF"
hexpre  db "0x", 0
hexstr  db "00000000", 0
hexaddr dw 0

msg     db "Hello World!", 0

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
