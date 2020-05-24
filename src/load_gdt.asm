SECTION .text

; Load GDT and set selectors for a flat memory model.
load_gdt:
    cli                         ; Make sure that interrupts are disabled at this point.
    lgdt [gdt_desc]             ; Load the GDT.
    jmp CODE_SEG:.fill_seg_reg  ; Implicitly set CS register via far JMP to the.

.fill_seg_reg:                  ; Set all segment registers (except CS) to the data segment.
    mov eax, DATA_SEG
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax

    jmp gdt_loaded
