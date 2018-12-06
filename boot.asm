; screen width (80 columns / characters)
%define COLUMNS 80
; screen height (25 rows / lines)
%define ROWS 25

%macro PRINT 1
    mov si, %1
    call print_str
    call update_cursor
%endmacro

%macro PRINTLN 1
    mov si, %1
    call print_str
    call newline
    call update_cursor
%endmacro

[ORG 0x7C00]            ; boot sector memory address

    cli                 ; disable interrupts (during initialization)
    cld                 ; lowest-to-highest byte string direction

    mov ax, 0           ; prepare 0 in AX register
    mov ds, ax          ; set data segment to 0
    mov ss, ax          ; set stack segment to 0
    mov gs, ax          ; set G segment (used by interrupts) to 0
    mov sp, 0x9C00      ; set top of stack to address 0x2000 behind the beginning of the code

    mov ax, 0xB800      ; VGA text buffer address
    mov es, ax

    mov bx, 0x09        ; keyboard hardware interrupt ID
    shl bx, 2           ; shift left by 2 bits
    mov [gs:bx], word keyhandler    ; set keyboard interrupt procedure address
    mov [gs:bx+2], ds   ; set keyboard interrupt procedure segment (presumably)
    sti                 ; enable interrupts

    PRINTLN msg         ; print string

    mov eax, 0x1234ABCD ; move test value to EAX
    call print16        ; print value in EAX

hang:
    hlt                 ; halt CPU
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
    mov dx, COLUMNS * 2 ; 160 bytes per line (80 columns, 2 bytes per column / character)
    mul dx              ; multiply Y position by number of bytes per line
    movzx bx, byte [xpos]
    shl bx, 1           ; take X position and multiply it by 2 to skip attributes

    mov di, 0           ; start of video memory
    add di, ax          ; add y offset
    add di, bx          ; add x offset

    mov ax, cx          ; restore char/attribute
    stosw               ; write char/attribute
    add byte [xpos], 1  ; advance to right

    cmp byte [xpos], COLUMNS    ; if current line is full
    jne print_char_done
    call newline        ; move on to next line

print_char_done:
    ret

update_cursor:          ; update VGA cursor position
    movzx ax, byte [ypos]   ; get cursor Y position
    mov bx, COLUMNS     ; screen width (presumably 80)
    mul bx              ; multiply it by screen width
    movzx bx, byte [xpos]   ; get cursor X position
    add bx, ax          ; absolute cursor position (Y * width + X) is now in BX

    mov dx, 0x3D4
    mov al, 0x0F
	out dx, al          ; tell VGA to expect cursor low byte

    mov dx, 0x3D5
    mov al, bl
	out dx, al          ; send low byte

    shr bx, 8           ; shift BX by 1 byte to right (get high byte)

    mov dx, 0x3D4
    mov al, 0x0E
	out dx, al          ; tell VGA to expect cursor high byte

    mov dx, 0x3D5
    mov al, bl
	out dx, al          ; send high byte

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

    cmp byte [ypos], ROWS   ; if cursor is below last line
    jnz newline_done
    mov byte [ypos], 0  ; overflow back to the first line

newline_done:
    ret

keyhandler:
    in al, 0x60         ; read key data
    mov bl, al          ; save it for later use
    mov byte [port60], al   ; save it for printing

    in al, 0x61         ; read more key data
    mov ah, al          ; make copy of AL in AH
    or al, 0x80         ; disable bit 7 (set it to 1)
    out 0x61, al        ; send it back (with bit 7 disabled)
    mov al, ah          ; move unmodified value back to AL
    out 0x61, al        ; send unmodified value back (with bit 7 in original state)

    mov al, 0x20        ; end-of-interrupt code
    out 0x20, al        ; send end-of-interrupt signal

    and bl, 0x80        ; check if key was pressed or released
    jnz keyhandler_done ; do not print released keys

    mov al, byte [port60]
    call print8         ; print key code

keyhandler_done:
    iret

; ============================================
; ================    DATA    ================
; ============================================

xpos    db 0
ypos    db 0

hextab  db "0123456789ABCDEF"
hexpre  db "0x", 0
hexstr  db "00000000", 0
hexaddr dw 0

port60  db 0

msg     db "Hello World!", 0

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
