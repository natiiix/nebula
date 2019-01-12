; screen width (80 columns / characters)
%define COLUMNS 80
; screen height (25 rows / lines)
%define ROWS 25
; VGA text buffer base address
%define TEXT_BUFFER 0xB8000

; flag used to print keyboard scancodes
; %define PRINT_SCANCODE

; line feed character
%define LF 10

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

[BITS 16]               ; 16-bit instructions
[ORG 0x7C00]            ; boot sector memory address

%include "bootloader.asm"
%include "gdt.asm"

fill_segments:          ; fill all segment registers (except for CS) with value from AX
    mov ss, eax
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    ret

kernel_init:            ; kernel initialization (enter protected mode)
    cli

    mov eax, 0
    call fill_segments  ; set up segment registers

    mov sp, 0xFFFC      ; set 16-bit stack pointer

    lgdt [gdt_desc]     ; load GDT

    mov eax, cr0        ; enable bit 0 of CR0
    or eax, 0b1
    mov cr0, eax

    jmp CODE_SEG:main32 ; jump to main protected mode code

[BITS 32]               ; 32-bit instructions

main32:
    cli                 ; disable interrupts (during initialization)
    cld                 ; lowest-to-highest byte string direction

    mov eax, DATA_SEG
    call fill_segments  ; set up segment registers

    mov ebp, 0x90000
    mov esp, ebp        ; set 32-bit stack pointer

    PRINTLN msg         ; print string

    mov eax, 0x1234ABCD ; move test value to EAX
    call print16        ; print value in EAX

    mov eax, CODE_SEG
    call print32

    mov eax, DATA_SEG
    call print32

    ; ICW1 - begin initialization
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    ; ICW2 - remap offset address of idt_table
    ; In x86 protected mode, we have to remap the PICs beyond 0x20 because
    ; Intel have designated the first 32 interrupts as "reserved" for cpu exceptions
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al

    ; ICW3 - setup cascading
    mov al, 0
    out 0x21, al
    out 0xA1, al

    ; ICW4 - environment info
    mov al, 1
    out 0x21, al
    out 0xA1, al

    ; Initialization finished

    ; mask interrupts
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al

    lidt [idt_desc]     ; load IDT descriptor

    ; 0xFD is 11111101 - enables only IRQ1 (keyboard)
    mov al, 0xFD
    out 0x21, al

    sti

    jmp key_loop        ; jump to infinite synchronous key handling loop

hang:
    hlt                 ; halt CPU
    jmp hang            ; infinite hang loop

print_char:
    cmp al, LF          ; if character is line feed
    je print_char_newline   ; print nothing to screen, but move to new line

    mov cl, al          ; move character to temporary register
    call get_cur_pos    ; get current cursor index
    mov ah, 0x0F        ; attribute byte - white on black
    mov al, cl          ; restore character from temporary register

print_char_inner:       ; print single character
    stosw               ; write char + attribute word

    inc byte [xpos]     ; advance to right
    cmp byte [xpos], COLUMNS    ; if current line is full
    jne print_char_done

print_char_newline:
    call newline        ; move on to next line

print_char_done:
    ret

print_str:              ; print string
    pusha               ; push all registers onto stack
    call get_cur_pos    ; get initial cusror index
    mov ah, 0x0F        ; attribute byte - white on black

print_loop:
    lodsb               ; load next string character / byte
    cmp al, 0           ; check for null string termination character
    je print_done       ; break loop at null character

    call print_char_inner     ; print single character
    jmp print_loop      ; string printing loop

print_done:
    popa                ; pop all registers from stack
    ret

clear_line:
    call get_cur_pos

    mov ecx, COLUMNS
    movzx eax, byte [xpos]
    sub ecx, eax        ; calculate trailing empty columns on current line

    mov ah, 0x0F        ; black foreground on black background
    mov al, 0x20        ; space character

clear_line_inner:
    stosw
    loop clear_line_inner
    ret

clear_screen:
    mov byte [xpos], 0
    mov byte [ypos], 0

    call update_cursor  ; reset cursor position to 0,0

    mov ecx, COLUMNS * ROWS ; number of characters on screen
    mov edi, TEXT_BUFFER    ; VGA text buffer base address

    mov ah, 0x0F        ; black foreground on black background
    mov al, 0x20        ; space character

clear_screen_inner:
    stosw
    loop clear_line_inner   ; clear screen character by character
    ret

get_cur_pos:            ; get absolute cursor position (buffer index) and put it into DI
    movzx eax, byte [ypos]
    mov edx, COLUMNS * 2    ; 160 bytes per line (80 columns, 2 bytes per column / character)
    mul edx             ; multiply Y position by number of bytes per line
    movzx ebx, byte [xpos]
    shl ebx, 1          ; take X position and multiply it by 2 to skip attributes

    mov edi, TEXT_BUFFER    ; VGA text buffer address
    add edi, eax        ; add Y offset
    add edi, ebx        ; add X offset

    ret

update_cursor:          ; update VGA cursor position
    movzx eax, byte [ypos]  ; get cursor Y position
    mov ebx, COLUMNS    ; screen width (presumably 80)
    mul ebx             ; multiply it by screen width

    movzx ebx, byte [xpos]  ; get cursor X position
    add ebx, eax        ; absolute cursor position (Y * width + X) is now in BX

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
    mov ecx, 2
    jmp printhex

print16:                ; print 16-bit value in AX
    mov ecx, 4
    jmp printhex

print32:                ; print 32-bit value in EAX
    mov ecx, 8
    jmp printhex

printhex:
    mov esi, hextab     ; copy hex table base address into source register

    mov ebx, hexstr + 8 ; get end address of output hex string
    mov edi, ebx        ; copy end address to destination register
    sub ebx, ecx        ; subtract number of digits from end address to get beginning address
    mov dword [hexaddr], ebx    ; store beginning address in memory for later printing

hexloop:
    dec edi             ; decrement output hex string index (move one character to left)
    mov ebx, eax        ; copy value to EBX
    and ebx, 0xF        ; extract last 4 bits
    mov bl, byte [esi + ebx]    ; copy character from hex table
    mov byte [edi], bl  ; copy character to output hex string
    shr eax, 4          ; shift right by 4 bits
    dec ecx             ; decrement input value 4-bit block counter
    jnz hexloop         ; if there are more 4-bit blocks to process, keep going

    PRINT hexpre        ; print hex value prefix (0x)
    PRINTLN [hexaddr]   ; print output hex string

    ret

finish_print:
    call clear_line
    call update_cursor
    ret

terminate_line:
    call clear_line
    call newline
    ret

newline:
    mov byte [xpos], 0  ; carriage return
    add byte [ypos], 1  ; line feed

    cmp byte [ypos], ROWS   ; if cursor is below last line
    jnz newline_done
    mov byte [ypos], 0  ; overflow back to the first line

newline_done:
    ret

%include "keyboard.asm"

; ============================================
; ================    DATA    ================
; ============================================

xpos    db 0
ypos    db 0

; conversion table from 4-bit value to hexadecimal digit
hextab  db "0123456789ABCDEF"
hexpre  db "0x", 0
hexstr  db "00000000", 0
hexaddr dd 0

%include "data_keyboard.asm"

cmdbuff times 0x100 db 0
cmdbuff_idx db 0

msg     db "Hello World!", 0

%include "data_idt.asm"

times IMAGE_SIZE-($-$$) db 0    ; pad with zeroes to fill IMAGE_SIZE
