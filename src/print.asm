SECTION .text

; screen width (80 columns / characters)
COLUMNS equ 80
; screen height (25 rows / lines)
ROWS    equ 25

; total number of characters that can be written to the VGA text buffer
TEXT_CHAR_COUNT equ COLUMNS * ROWS

; VGA text buffer base address
TEXT_BUFFER equ 0xB8000

; line feed character (\n)
LF      equ 10
; space character (also used for clearing screen)
SPACE   equ ' '

PORT_CURSOR_CONTROL equ 0x3D4
PORT_CURSOR_DATA    equ 0x3D5

; Low byte of the cursor position.
CMD_CURSOR_POS_LOW      equ 0x0F
; High byte of the cursor position.
CMD_CURSOR_POS_HIGH     equ 0x0E
; Start scanline of the cursor - top of the cursor.
CMD_CURSOR_SIZE_START   equ 0x0A
; End scanline of the cursor - bottom of the cursor.
CMD_CURSOR_SIZE_END     equ 0x0B

; Mask used when setting cursor start position/scanline.
MASK_CURSOR_START   equ 0xC0
; Mask used when setting cursor end position/scanline.
MASK_CURSOR_END     equ 0xE0

; Position of start/top of cursor (0x00 = top-most scanline).
CURSOR_START    equ 0x0B
; Position of end/bottom of cursor (0x0F = bottom-most scanline).
CURSOR_END      equ 0x0D

COLOR_WHITE_ON_BLACK equ 0x0F

; white on black space character ready to be put into the VGA text buffer
SPACE_WORD equ (COLOR_WHITE_ON_BLACK << 8) | SPACE

; @desc Prints a single character to the screen.
; @in   AL  Character to be printed.
print_char:
    cmp al, LF          ; if character is line feed
    je terminate_line   ; print nothing to screen, but move to new line

    mov cl, al          ; move character to temporary register
    call get_cur_pos    ; get current cursor index
    mov ah, COLOR_WHITE_ON_BLACK    ; attribute byte - white on black
    mov al, cl          ; restore character from temporary register

print_char_inner:       ; print single character
    stosw               ; write char + attribute word

    inc byte [xpos]     ; advance to right
    cmp byte [xpos], COLUMNS    ; check if the X position beyond the last column (outside of the screen)
    jne .print_char_done ; if the current row/line is not full yet

    call newline        ; if the line is already full, move to next line

.print_char_done:
    ret

; @desc Replaces last character with spaces a moves cursor one character back.
; @reg  AX
undo_char:
    cmp byte [xpos], 0  ; if cursor X position is 0
    je .undo_char_first_col

    dec byte [xpos]     ; otherwise decrement cursor X position

    jmp .undo_char_print

.undo_char_first_col:
    mov byte [xpos], COLUMNS - 1    ; set cursor X position to last column

    cmp byte [ypos], 0  ; if cursor Y position is 0
    je .undo_char_first_row

    dec byte [ypos]     ; otherwise decrement cursor Y position

    jmp .undo_char_print

.undo_char_first_row:
    mov byte [ypos], ROWS - 1   ; set cursor Y position to last row
    ; jmp .undo_char_print

.undo_char_print:
    call get_cur_pos    ; get current cursor index
    mov ax, SPACE_WORD  ; attribute byte - white on black
    stosw               ; replace character with space

    ret

; @desc Prints a string of characters terminated by a null character.
; @in   ESI Memory address of the beginning of the string to be printed.
print_str:              ; print string
    call get_cur_pos    ; get initial cusror index
    mov ah, COLOR_WHITE_ON_BLACK    ; attribute byte - white on black

print_loop:
    lodsb               ; load next string character / byte

    cmp al, 0           ; check for null string termination character
    je .print_done      ; break loop at null character

    cmp al, LF          ; check for line feed character
    je .print_newline   ; terminate line at line feed character

    call print_char_inner   ; print single character
    jmp print_loop      ; string printing loop

.print_done:
    ret

.print_newline:
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
; [DISABLED] @in   EDX Raw print switch (no `0x` prefix and no line termination if not zero).
printhex:
    mov esi, hextab     ; copy hex table base address into source register

    mov ebx, hexstr_end ; get end address of output hex string
    mov edi, ebx        ; copy end address to destination register
    sub ebx, ecx        ; subtract number of digits from end address to get beginning address
    mov dword [hexaddr], ebx    ; store beginning address in memory for later printing

.hexloop:
    dec edi             ; decrement output hex string index (move one character to left)
    mov ebx, eax        ; copy value to EBX
    and ebx, 0xF        ; extract last 4 bits
    mov bl, byte [esi + ebx]    ; copy character from hex table
    mov byte [edi], bl  ; copy character to output hex string
    shr eax, 4          ; shift right by 4 bits
    dec ecx             ; decrement input value 4-bit block counter
    jnz .hexloop        ; if there are more 4-bit blocks to process, keep going

    ; test edx, edx
    ; jnz .rawprint

    PRINT hexpre        ; print hex value prefix (0x)
    PRINTLN [hexaddr]   ; print output hex string
    ret

; .rawprint:
;     PRINT [hexaddr]
;     ret

; @desc Clears the current line and updates the VGA text-mode cursor position.
finish_print:
    call clear_line
    call update_cursor
    ret

; @desc Clears the old line and moves to the next one.
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

    cmp byte [ypos], ROWS   ; check if the Y position is beyond the last row
    jnz .newline_done   ; this was not the last row yet => no need to overflow
    mov byte [ypos], 0  ; overflow back to the first line

.newline_done:
    ret

; @desc Clears the current line by overwriting the rest of it with spaces.
clear_line:
    call get_cur_pos

    mov ecx, COLUMNS
    movzx eax, byte [xpos]
    sub ecx, eax        ; calculate trailing empty columns on current line

    mov ax, SPACE_WORD

clear_line_inner:
    stosw
    loop clear_line_inner
    ret

; @desc Clears the whole text-mode screen by filling the whole buffer with spaces.
clear_screen:
    mov byte [xpos], 0
    mov byte [ypos], 0

    call update_cursor  ; reset cursor position to 0,0

    mov ecx, TEXT_CHAR_COUNT    ; number of characters in the VGA text buffer
    mov edi, TEXT_BUFFER        ; VGA text buffer base address

    mov ax, SPACE_WORD
    rep stosw               ; clear screen character by character

    ret

; @desc Determines the absolute text-mode cursor position (VGA text-mode buffer index).
; @reg  EAX, EBX, EDX
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
    mul ebx             ; multiply Y position by screen width to get the Y part of the text buffer offset

    movzx ebx, byte [xpos]  ; get cursor X position
    add ebx, eax        ; absolute cursor position (Y * width + X) is now in BX

    mov dx, PORT_CURSOR_CONTROL
    mov al, CMD_CURSOR_POS_LOW
    out dx, al          ; tell VGA to expect cursor low byte

    mov dx, PORT_CURSOR_DATA
    mov al, bl
    out dx, al          ; send low byte

    mov dx, PORT_CURSOR_CONTROL
    mov al, CMD_CURSOR_POS_HIGH
    out dx, al          ; tell VGA to expect cursor high byte

    mov dx, PORT_CURSOR_DATA
    mov al, bh
    out dx, al          ; send high byte

    ret

; @desc Enables the VGA text-mode cursor.
;       Based on C code from https://wiki.osdev.org/Text_Mode_Cursor#Enabling_the_Cursor_2
; @reg  AL, DX
enable_cursor:
    mov dx, PORT_CURSOR_CONTROL
    mov al, CMD_CURSOR_SIZE_START
    out dx, al

    mov dx, PORT_CURSOR_DATA
    in al, dx
    and al, MASK_CURSOR_START
    or al, CURSOR_START
    out dx, al

    mov dx, PORT_CURSOR_CONTROL
    mov al, CMD_CURSOR_SIZE_END
    out dx, al

    mov dx, PORT_CURSOR_DATA
    in al, dx
    and al, MASK_CURSOR_END
    or al, CURSOR_END
    out dx, al

    ret
