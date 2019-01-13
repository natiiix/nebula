; @desc Determines the length of a string.
; @in   ESI Memory address of the string to evaluate.
; @out  ECX Length of evaluated string.
; @out  ESI Index of string-terminating null character.
strlen:
    mov ecx, 0

strlen_loop:
    cmp byte [esi], 0
    je strlen_done

    inc ecx
    inc esi

    jmp strlen_loop

strlen_done:
    ret
