SECTION .text

; screen width (80 columns / characters)
%define COLUMNS 80
; screen height (25 rows / lines)
%define ROWS 25
; VGA text buffer base address
%define TEXT_BUFFER 0xB8000

; line feed character
%define LF 10

; @desc Prints a single character to the screen.
; @in   AL  Character to be printed.
print_char:
    cmp al, LF          ; if character is line feed
    je terminate_line   ; print nothing to screen, but move to new line

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

; @desc Replaces last character with spaces a moves cursor one character back.
; @reg  AX
undo_char:
    cmp byte [xpos], 0  ; if cursor X position is 0
    je undo_char_first_col

    dec byte [xpos]     ; otherwise decrement cursor X position

    jmp undo_char_print

undo_char_first_col:
    mov byte [xpos], COLUMNS - 1    ; set cursor X position to last column

    cmp byte [ypos], 0  ; if cursor Y position is 0
    je undo_char_first_row

    dec byte [ypos]     ; otherwise decrement cursor Y position

    jmp undo_char_print

undo_char_first_row:
    mov byte [ypos], ROWS - 1   ; set cursor Y position to last row

    jmp undo_char_print

undo_char_print:
    call get_cur_pos    ; get current cursor index
    mov ah, 0x0F        ; attribute byte - white on black
    mov byte al, ' '    ; set character to space
    stosw               ; replace character with space

    ret

; @desc Prints a string of characters terminated by a null character.
; @in   ESI Memory address of the beginning of the string to be printed.
print_str:              ; print string
    call get_cur_pos    ; get initial cusror index
    mov ah, 0x0F        ; attribute byte - white on black

print_loop:
    lodsb               ; load next string character / byte

    cmp al, 0           ; check for null string termination character
    je print_done       ; break loop at null character

    cmp al, LF          ; check for line feed character
    je print_newline    ; terminate line at line feed character

    call print_char_inner   ; print single character
    jmp print_loop      ; string printing loop

print_done:
    ret

print_newline:
    push ax             ; push character + attribute word onto stack to preserve attribute byte
    call terminate_line ; clear rest of current line and move to next line
    pop ax              ; pop word back from stack

    jmp print_loop

; @desc Prints 8-bit value in hexadecimal form.
; @in   AL  Value to be printed.
print8:
    mov ecx, 2
    jmp printhex

; @desc Prints 16-bit value in hexadecimal form.
; @in   AX  Value to be printed.
print16:
    mov ecx, 4
    jmp printhex

; @desc Prints 32-bit value in hexadecimal form.
; @in   EAX Value to be printed.
print32:
    mov ecx, 8
    jmp printhex

; @desc Internal procedure used for printing hexadecimal values.
;       It should never be called directly.
;       There are dedicated procedures for each value size (8, 16, 32-bit).
; @in   EAX Value to be printed.
; @in   ECX Number of least significant hexadecimal digits to print.
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

; @desc Clears the current line and updates the VGA text-mode cursor position.
finish_print:
    call clear_line
    call update_cursor
    ret

; @desc Terminates the current line by clearing it and moving to the next line.
terminate_line:
    call clear_line
    call newline
    ret

; @desc Moves to the next line without clearing the old line.
;       This procedure should only be used internally in situations where clearing the old line
;       is most certainly not necessary (it has either been cleared before or it is completely full).
newline:
    mov byte [xpos], 0  ; carriage return
    add byte [ypos], 1  ; line feed

    cmp byte [ypos], ROWS   ; if cursor is below last line
    jnz newline_done
    mov byte [ypos], 0  ; overflow back to the first line

newline_done:
    ret

; @desc Clears the current line by overwriting the rest of it with spaces.
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

; @desc Clears the whole text-mode screen by filling the whole buffer with spaces.
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

; @desc Determines the absolute text-mode cursor position (VGA text-mode buffer index).
; @out  EDI Current cursor position / buffer index.
get_cur_pos:
    movzx eax, byte [ypos]
    mov edx, COLUMNS * 2    ; 160 bytes per line (80 columns, 2 bytes per column / character)
    mul edx             ; multiply Y position by number of bytes per line
    movzx ebx, byte [xpos]
    shl ebx, 1          ; take X position and multiply it by 2 to skip attributes

    mov edi, TEXT_BUFFER    ; VGA text buffer address
    add edi, eax        ; add Y offset
    add edi, ebx        ; add X offset

    ret

; @desc Updates the position of the VGA text-mode cursor.
update_cursor:
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
