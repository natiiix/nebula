SECTION .text

; Rounded-up division by 256.
; Used to get the number of blocks necessary for a heap allocation.
%macro SHR8_ROUND_UP 0
    add edx, 0xFF
    shr edx, 8
%endmacro

%macro DEBUG_PRINT 1
    pusha
    mov eax, %1
    call print32
    popa
%endmacro

; @in   EAX Requested memory block size.
; @out  ESI Address of allocated memory space.
malloc:
    mov edx, eax

    SHR8_ROUND_UP       ; divide by 256 and round up to get the number of tertiary blocks
    ; JC could be used here to handle attempts to allocate more than 0xFFFFFF00 bytes.
    test edx, edx       ; check if the number of tertiary blocks to allocate
    jz .invalid_size    ; if it is zero, either 0 or more than 0xFFFFFF00 bytes have been requested

    ; At this point, EAX should be in the 0x00000001 - 0x00FFFFFF range.

    test edx, ~0xFF ; check higher bits (above least significant byte)
    jz .tertiary    ; zero => below 256 => requested memory size can fit into the tertiary allocation level

    SHR8_ROUND_UP   ; this makes EAX < 0x10000 => number of secondary blocks
    test edx, ~0xFF ; requested size can fit into secondary block(s)
    jz .secondary

    SHR8_ROUND_UP   ; this makes EAX < 0x100 => number of primary blocks
    jmp .primary    ; it is necessary to allocate primary block(s)

.invalid_size:
    PRINTLN err_invalid_size
    ret

; @in   EDX Number of requested primary blocks.
; @out  ESI Address of table entry of the first available block.
; @reg  EAX, ECX, EDX
.primary:
    ; mov edx, eax                    ; EAX will be used by string instructions

    ; Check if there are enough primary memory blocks.
    ; This does not mean that there are really enough continuous blocks.
    ; However, if this check fails, it makes no sense to continue.
    mov eax, 0xFF                   ; total number of entries in primary table (excluding first meta-entry)
    sub eax, dword [primary_heap_tab]   ; subtract first entry value to get number of available primary entries
    cmp eax, edx                    ; check if the number of available entries is lower than the requested
    jb .out_of_memory               ; there are not enough available primary blocks (regardless of continuity)

    mov esi, primary_heap_tab + 4   ; second entry in primary table
    xor ecx, ecx                    ; number of continuous unused block

.primary_find_loop:
    lodsd                           ; load table entry into EAX
    test eax, eax                   ; check if table entry is zero
    jz .primary_find_zero           ; if table entry is zero

    ; Table entry is non-zero.
    and eax, 0xFF                   ; only the least significant byte is used to number of allocated bytes (more significant bytes are reserved)
    dec eax                         ; decrement table entry locally because LODSD has already moved ESI to the next entry
    shl eax, 2                      ; convert table entry value into table offset (32-bit entries)
    add esi, eax                    ; skip the already allocated entries

.primary_find_loop_end:
    cmp esi, primary_heap_tab_end   ; check if ESI is outside of the primary table
    jae .out_of_memory              ; there are not enough continuous memory blocks for the requested allocation

    jmp .primary_find_loop

.primary_find_zero:                 ; primary table entry is zero
    inc ecx                         ; increment counter of continuous available memory blocks
    cmp ecx, edx                    ; check if enough continuous memory blocks were found
    jb .primary_find_loop_end       ; not enough blocks yet

    ; Success - sufficiently long continuous memory block was found.
    shl ecx, 2                      ; multiply by 4 (offset into the table with 32-bit entries).
    sub esi, ecx                    ; get base address of found memory block

    mov dword [esi], edx            ; store the number of allocated blocks into the entry
    add dword [primary_heap_tab], edx   ; add to the total number of allocated primary blocks

    sub esi, primary_heap_tab       ; get first allocated table entry offset
    shl esi, 24 - 2                 ; get address of allocated primary memory block
                                    ; (-2 because entries are 32-bit, so the offset is a multiple of 4)
    ret

.secondary:
    ; Find secondary table.
    ;   - Create a new secondary table.
    ;       - Clear the table.
    ;       - Write number of allocated blocks into the second entry.
    ;       - Copy the value into the first entry (the rest of the table is definitely empty).
    ;       - Propagate the value into the primary table.
    ;   - Suitable table found (judged based on the most significant byte of entry in primary table).
    ;       - Find continuous space for allocation (similar to the process in primary table).
    ;           - Found.
    ;               - Set table entry value to block count.
    ;               - Add block count to first table entry.
    ;               - Propagate value into primary table.
    ;           - Not found.
    ;               - Find a different secondary table.

    call find_secondary_table
    test esi, esi
    jz .secondary_create
    ret

.secondary_create:
    DEBUG_PRINT 0xBAD0_CCCC
    mov esi, 0
    ret

.tertiary:
    ; Similar to secondary block allocation, but with an extra level.
    mov esi, 0
    ret

.out_of_memory:
    PRINTLN err_out_of_memory
    mov esi, 0  ; return NULL pointer
    ret

; @in   EDX Required number of unused entries.
find_secondary_table:
    mov esi, primary_heap_tab + 4   ; start at the second entry in primary table

.find_table_loop:
    cmp esi, primary_heap_tab_end
    jae .fail

    lodsd
    test eax, 0xFF00_0000           ; check the most significant byte to determine if this is a nested table entry
    jnz .found

    test eax, eax                   ; check if the table entry is used
    jz .find_table_loop             ; zero => unused primary table entry

    ; and eax, 0xFF                 ; not necessary, we know from the previous check that this is not a nested table block
    dec eax                         ; LODSD has already incremented the entry pointer
    shl eax, 2                      ; convert from index into 32-bit entry offset
    add esi, eax                    ; skip the allocated data block entries

    jmp .find_table_loop

.found:
    DEBUG_PRINT 0xBAD0_FFFF
    mov ebx, 0xFF                   ; maximal number of blocks that can be allocated
    shr eax, 24                     ; most significant byte contains number of already allocated sub-blocks in a nested table
    sub ebx, eax                    ; calculated number of unused blocks
    cmp ebx, edx                    ; check if there is enough space in the table for the requested allocation
    jb .find_table_loop             ; definitely not enough space in the table

    mov edi, esi                    ; save pointer to unused primary entry for later

    sub esi, primary_heap_tab + 4   ; caculate primary table entry offset (+4 because ESI was already incremented to the next table entry)
    shl esi, 24 - 2                 ; get the address of the secondary table

    DEBUG_PRINT esi

    add esi, 4                      ; move to second entry
    mov ebx, esi                    ; set EBX to address of end of this secondary table
    add ebx, 0xFF * 4               ; skip 255 32-bit table entries to get to the end of the table

    DEBUG_PRINT esi
    DEBUG_PRINT ebx

.find_entry_loop:
    DEBUG_PRINT 0xBAD0_BBBB
    call find_unused_32b_entry
    test esi, esi
    jz .unsuitable_table            ; this secondary table cannot be used, find a different one

    call count_zero_32b
    cmp ecx, edx
    jb .find_entry_loop             ; not enough unused secondary entries in a row

    shl ecx, 2                      ; convert count into 32-bit entry offset
    sub esi, ecx                    ; calculate address of first zero entry in secondary table
    ret

.unsuitable_table:
    DEBUG_PRINT 0xBAD0_DDDD
    mov esi, edi                    ; restore address of entry in primary table
    ; add esi, 4                      ; move to the next entry in primary table
    jmp .find_table_loop

.fail:
    mov esi, 0                      ; there is no suitable secondary table => return NULL pointer
    ret

; Finds the first unused entry in the primary table and returns a pointer to it.
; @out  ESI Address of unused table entry (or NULL if the table is already fully used).
; @reg  EAX, EBX
find_unused_primary_entry:
    mov esi, primary_heap_tab + 4
    mov ebx, primary_heap_tab_end
    ; jmp find_unused_32b_entry

; @in   ESI Start address.
; @in   EBX End address (exclusive).
; @out  ESI Address of unused table entry (or NULL if the table is already fully used).
; @reg  EAX
find_unused_32b_entry:
    cmp esi, ebx
    jae ret_esi_null    ; end of table => all entries already used

    lodsd
    test eax, eax
    jnz .next_entry     ; table entry is already used, skip to the next entry

    ; Success - found an unused table entry.
    sub esi, 4          ; get pointer to the unused entry (LODSD already moved ESI to the address of the next entry)
    ret

.next_entry:
    DEBUG_PRINT 0xEEEE_EEEE
    DEBUG_PRINT esi
    DEBUG_PRINT eax

    and eax, 0xFF       ; only the least significant byte is used to number of allocated bytes (more significant bytes are reserved)
    dec eax             ; decrement table entry locally because LODSD has already moved ESI to the next entry
    shl eax, 2          ; convert table entry value into table offset (32-bit entries)
    add esi, eax        ; skip the already allocated entries

    jmp find_unused_32b_entry

; @in   ESI Start address.
; @in   EBX End address (exclusive).
; @out  ESI Address of unused table entry (or NULL if the table is already fully used).
; @reg  EAX
find_unused_8bit_entry:
    cmp esi, ebx
    jae ret_esi_null    ; end of table => all entries already used

    lodsb
    test al, al
    jnz .next_entry     ; entry is already used, skip to the next entry

    dec esi             ; get address of unused entry (LODSB has already incremented ESI)
    ret

.next_entry:
    dec eax             ; decrement table entry locally because LODSB has already moved ESI to the next entry
    add esi, eax        ; skip the already allocated entries
    jmp find_unused_8bit_entry

; Returns NULL pointer in ESI.
; @out  ESI 0
; @reg
ret_esi_null:
    mov esi, 0
    ret

; Generates a procedure for counting consecutive zeros.
; @args
;   - String instruction to use (LODSx).
;   - Version of the A register to use (AL/AX/EAX).
; @in   ESI Start address.
; @in   EBX End address (exclusive).
; @out  ECX Number of consecutive zeros.
%macro COUNT_ZERO 2
    mov ecx, 0

.count_loop:
    cmp esi, ebx
    jae .end

    %1
    test %2, %2
    jz .next

.end:
    ret

.next:
    inc ecx
    jmp .count_loop
%endmacro

; @in   ESI Start address.
; @in   EBX End address (exclusive).
; @out  ECX Number of consecutive 32-bit zeros.
; @out  ESI Address of first non-zero 32-bit value or end address.
count_zero_32b:
    COUNT_ZERO lodsd, eax

; @in   ESI Start address.
; @in   EBX End address (exclusive).
; @out  ECX Number of consecutive 8-bit zeros.
; @out  ESI Address of first non-zero 8-bit value or end address.
count_zero_8b:
    COUNT_ZERO lodsb, al

; Clears the specified number of 4-byte memory blocks starting at address in EDI.
%macro CLEAR_4BYTE 1
    mov ecx, %1
    mov eax, 0
    rep stosd
    ret
%endmacro

; @in   EDI Address of secondary table.
clear_secondary_table:
    CLEAR_4BYTE 0x100

; @in   EDI Address of tertiary table.
clear_tertiary_table:
    CLEAR_4BYTE 0x40
