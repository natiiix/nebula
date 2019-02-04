; @desc Synchronously read scan codes from keyboard buffer and handle them in an infinite loop.
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

; @desc This code is executed if enter key has been pressed.
key_enter:
    call newline
    PRINTLN cmdbuff

    mov byte [cmdbuff_idx], 0
    mov byte [cmdbuff], 0

    jmp key_loop
