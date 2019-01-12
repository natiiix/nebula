; flag used to print keyboard scancodes
; %define PRINT_SCANCODE

keyhandler:
    pusha               ; push all registers onto stack

    in al, 0x60         ; read key data
    mov bl, al          ; save it for later use

    in al, 0x61         ; read more key data
    mov ah, al          ; make copy of AL in AH
    or al, 0x80         ; disable bit 7 (set it to 1)
    out 0x61, al        ; send it back (with bit 7 disabled)
    mov al, ah          ; move unmodified value back to AL
    out 0x61, al        ; send unmodified value back (with bit 7 in original state)

    mov al, 0x20        ; end-of-interrupt code
    out 0x20, al        ; send end-of-interrupt signal

    mov edi, keybuff    ; get key buffer base address
    movzx eax, byte [keybuff_end]   ; get key buffer end index
    add edi, eax        ; add index to key buffer base address
    mov [edi], bl       ; store scan code in key buffer

    inc eax             ; increment key buffer end index
    mov [keybuff_end], al   ; overflow is handled automatically because index is single-byte
                            ; and there are 256 positions in key buffer

    popa                ; restore all registers from stack
    iret

get_keytab:
    movzx ebx, byte [keystate + 0x2A]   ; get state of left shift key

    cmp ebx, 0          ; if left shift is currently pressed down
    je get_keytab_shift

    movzx ebx, byte [keystate + 0x36]   ; get state of right shift key

    cmp ebx, 0          ; if right shift is currently pressed down
    je get_keytab_shift

    mov esi, keytab     ; return normal conversion table
    ret

get_keytab_shift:
    mov esi, keytab_shift   ; return shifted conversion table
    ret

key_loop:
    call key_get        ; get scan code from key buffer

    cmp eax, 0          ; if scan code is 0 / null
    je key_loop         ; do nothing

%ifdef PRINT_SCANCODE
    push eax            ; store scan code on stack
    call print8         ; print key scan code
    pop eax             ; restore scan code from stack
%endif

    cmp eax, 0x1C       ; enter key pressed
    je key_enter

    cmp eax, 0x40       ; 0x40 and all higher scan codes have no printable character
                        ; release scan codes have bit 7 enabled,
                        ; which means they are also handled by this condition
    jae key_loop        ; if key has no printable char, jump to end of key handler

    call get_keytab     ; get scan-code-to-ASCII table base address
    add esi, eax        ; add scan code to base table address as index / offset
    mov al, [esi]       ; read ASCII value from table at index specified by scan code

    cmp al, 0           ; null character = non-printable key / scan code
    je key_loop         ; skip printing of null characters

    mov edi, cmdbuff    ; get command buffer base address
    movzx ebx, byte [cmdbuff_idx]   ; get command buffer index
    add edi, ebx        ; add index to buffer address

    mov [edi], al       ; store character in command buffer

    sub edi, ebx        ; subtract old command buffer index from EDI register

    inc ebx             ; increment command buffer index
    and ebx, 0xFF       ; make the EDI register seem 8-bit (to emulate 1-byte overflow)
    mov [cmdbuff_idx], bl   ; update command buffer index

    add edi, ebx        ; add new (incremented) command buffer index to EDI register
    mov byte [edi], 0   ; store null character at current end of command buffer

    call print_char     ; print converted ASCII character

%ifdef PRINT_SCANCODE
    call newline        ; terminate line
%endif

    call finish_print   ; perform after-print procedures

    jmp key_loop

key_enter:
    call newline
    PRINTLN cmdbuff

    mov byte [cmdbuff_idx], 0
    mov byte [cmdbuff], 0

    jmp key_loop

key_get:
    movzx eax, byte [keybuff_end]   ; get key buffer end index
    movzx ebx, byte [keybuff_start] ; get key buffer start index

    cmp eax, ebx        ; compare start index to end index
    je key_get_empty    ; if start = end, then key buffer is empty

    mov edi, keybuff    ; get key buffer base address
    add edi, ebx        ; add start index to key buffer address
    movzx eax, byte [edi]   ; read oldest scan code from key buffer

    inc ebx             ; increment start index (overflow is automatic thanks to single-byte size)
    mov [keybuff_start], bl ; store increment start index in memory

    mov ebx, eax        ; copy scan code to EBX

    and ebx, 0x0000007F ; only keep lowest 7 bits (identifies actual key)
    mov edi, keystate   ; get base address of key state table
    add edi, ebx        ; add scan code as offset to state table address

    mov ebx, eax        ; copy scan code to EBX

    and bl, 0x80        ; check if key was pressed or released
    mov [edi], bl       ; store key state in state table

    ret

key_get_empty:
    mov eax, 0          ; return 0 / null scan code
    ret
