; @desc Determines the length of a string.
; @in   ESI Memory address of the string to evaluate.
; @out  ECX Length of evaluated string.
; @out  ESI Index of string-terminating null character.
strlen:
    mov ecx, 0          ; set string length counter to zero

strlen_loop:
    cmp byte [esi], 0   ; check for terminating null character
    je strlen_done

    inc ecx             ; increment string length counter
    inc esi             ; move on to next string character

    jmp strlen_loop     ; loop until null character is encountered

strlen_done:
    ret
