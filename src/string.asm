SECTION .text

; @desc Determines the length of a string.
; @in   ESI Memory address of the string to evaluate.
; @out  ECX Length of evaluated string.
strlen:
    mov ecx, 0          ; set string length counter to zero

strlen_loop:
    cmp byte [esi + ecx], 0 ; check for terminating null character
    je strlen_done

    inc ecx             ; increment string length counter / character index
    jmp strlen_loop     ; loop until null character is encountered

strlen_done:
    ret

; WARN: The return value does NOT match the C stdlib counterpart.
; TODO: Maybe it would be possible to use some native,
;       more optimized string instructions instead.
;       This applies to other string-related procedures as well.
; @desc Compares two strings and determines if they are equal.
; @in   ESI Memory address of first string.
; @in   EDI Memory address of second string.
; @out  EAX Value indicating string equality (1 = equal; 0 = not equal).
; @out  ECX Index of character at which strings mismatch or length of strings if they are equal.
strcmp:
    cmp esi, edi        ; compare memory address of first string to memory address of second string
    je strcmp_equal     ; if memory addresses are equal there is no need to check any characters

    mov ecx, 0          ; set character index to zero

strcmp_loop:
    mov al, byte [esi + ecx]    ; read character from first string
    cmp al, byte [edi + ecx]    ; compare character from first string to character from second string
    jne strcmp_not_equal    ; stop if string differ in any character

    cmp al, 0           ; check for terminating null character
    je strcmp_equal     ; null character in both strings at once means they are equal

    inc ecx             ; increment character index (move to next character in both strings)
    jmp strcmp_loop     ; loop until difference is found or null character is encountered in both strings at once

strcmp_equal:
    mov eax, 1
    ret

strcmp_not_equal:
    mov eax, 0
    ret
