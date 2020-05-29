SECTION .text

; @in   EAX Requested memory block size.
malloc:
    ; Convert size to number of 256-byte blocks, rounded up.
    ; The ADD instruction could be followed by a jump-if-carry
    ; to handle attempts to allocate more than 0xFFFFFF00 bytes.
    add eax, 0xFF
    shr eax, 8

    test eax, eax
    jz .invalid_size

    ; At this point, the value should be in the 0x00000001 - 0x00FFFFFF range.

    test eax, 0x00FF0000
    jnz .primary

    test eax, 0x0000FF00
    jnz .secondary

    jmp .tertiary

.invalid_size:
    PRINTLN err_invalid_size
    ret

.primary:
    ret

.secondary:
    ret

.tertiary:
    ret
