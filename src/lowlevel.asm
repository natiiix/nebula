hang:
    hlt                 ; halt CPU
    jmp hang            ; infinite hang loop

fill_segments:          ; fill all segment registers (except for CS) with value from EAX
    mov ss, eax
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    ret
