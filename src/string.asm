; @desc Determines the length of a string.
; @in   ESI Memory address of the string to evaluate.
; @out  ECX Length of evaluated string.
strlen:
    mov ecx, 0          ; set string length counter to zero

strlen_loop:
    cmp byte [esi + ecx], 0   ; check for terminating null character
    je strlen_done

    inc ecx             ; increment string length counter / character index
    jmp strlen_loop     ; loop until null character is encountered

strlen_done:
    ret

; @desc Compares two strings and determines if they are equal.
; @in   ESI Memory address of first string.
; @in   EDI Memory address of second string.
; @out  EAX Value indicating string equality (1 = equal; 0 = not equal).
; @reg  ESI, EDI
; @post Registers ESI and EDI will point to the last checked character.
strcmp:
    cmpsb               ; compare [ESI] to [EDI]
    jne strcmp_not_equal

    cmp byte [esi], 0   ; check for terminating null character
    je strcmp_equal     ; null character in both strings at once means they are equal

    inc esi             ; move to next character in first string
    inc edi             ; move to next character in second string

    jmp strcmp          ; loop until difference is found or null character is encountered in both strings at once

strcmp_equal:
    mov eax, 1
    ret

strcmp_not_equal:
    mov eax, 0
    ret
