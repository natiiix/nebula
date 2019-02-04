; flag used to print keyboard scan codes
; %define PRINT_SCANCODE

; @desc Handles a keyboard event (key press / release) in the form of a scan code.
;       This procedure is called asynchronously as an interrupt routine.
; @post Keyboard scan code is added to the end of the keyboard event buffer.
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

; @desc Decides which scancode-to-ASCII table should be used based on the state of shift keys.
; @out  ESI Memory address of the scancode-to-ASCII table, which should be currently used.
; @reg  EBX
get_keytab:
    movzx ebx, byte [keystate + 0x2A]   ; get state of left shift key

    cmp ebx, 0          ; if left shift is currently pressed down
    je get_keytab_shift

    movzx ebx, byte [keystate + 0x36]   ; get state of right shift key

    cmp ebx, 0          ; if right shift is currently pressed down
    je get_keytab_shift

    mov esi, keytab     ; return normal conversion table
    ret

; @desc This code is executed if either left or right shift key is pressed.
get_keytab_shift:
    mov esi, keytab_shift   ; return shifted conversion table
    ret

; @desc Retrieves the oldest scan code from the keyboard buffer.
; @out  EAX The retrieved keyboard scan code.
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

; @desc This code is executed if the keyboard buffer is empty.
key_get_empty:
    mov eax, 0          ; return 0 / null scan code
    ret
