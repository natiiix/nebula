; @desc Halts the CPU in an infinite loop.
; @post CPU remains halted until the host device is rebooted.
hang:
    hlt                 ; halt CPU
    jmp hang            ; infinite hang loop

; @desc Sets all segment registers, except for CS (Code Segment), to the value of EAX.
; @in   EAX Value to set the segment registers to.
; @reg  SS, DS, ES, FS, GS
; @post Specified segment registers will be set to the value of EAX.
fill_segments:
    mov ss, eax
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    ret
