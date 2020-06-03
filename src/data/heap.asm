SECTION .data

ALIGN 4
primary_heap_tab    times 0x100 dd 0    ; the top-level heap memory table has 256 32-bit entries
primary_heap_tab_end:

SECTION .rodata

err_invalid_size    db "Requested allocation size is invalid (zero or too large).", 0
err_out_of_memory   db "Out of memory (unable to find enough continuous memory block for allocation).", 0
