SECTION .text

; Description of the contents of the RTC/CMOS registers can be found here:
; http://www.bioscentral.com/misc/cmosmap.htm
; https://wiki.osdev.org/CMOS#Getting_Current_Date_and_Time_from_RTC

RTC_CONTROL     equ 0x70
RTC_DATA        equ 0x71

RTC_STATUS_A    equ 0x0A
RTC_STATUS_B    equ 0x0B
RTC_STATUS_C    equ 0x0C

RTC_SECOND      equ 0x00
RTC_MINUTE      equ 0x02
RTC_HOUR        equ 0x04
RTC_DAY         equ 0x07
RTC_MONTH       equ 0x08
RTC_YEAR        equ 0x09
RTC_CENTURY     equ 0x32

MASK_NMI_BIT    equ 0x80    ; on RTC control port
MASK_RTC_UPDATE equ 0x80    ; in RTC status register A
MASK_24H        equ 0x02    ; in RTC status register B

RTC_INTERRUPT_PERIODIC      equ 1 << 6  ; in RTC status register B
RTC_INTERRUPT_ALARM         equ 1 << 5  ; in RTC status register B
RTC_INTERRUPT_UPDATE_ENDED  equ 1 << 4  ; in RTC status register B

; @in   AH  CMOS register address.
; @reg  AL
rtc_select_reg:
    in al, RTC_CONTROL      ; Read old RTC control value.
    and al, MASK_NMI_BIT    ; Extract the NMI bit from the control value.
    or al, ah               ; Merge the NMI bit with the register address.
    out RTC_CONTROL, al     ; Write the address (with the NMI bit) to the RTC control port.
    ret


; @in   AH  CMOS register address.
; @out  AL  Value read from the CMOS register.
rtc_read:
    call rtc_select_reg ; Select the specified CMOS register.
    in al, RTC_DATA     ; Read a single byte from the CMOS register.
    ret

; @in   AH  CMOS register address.
; @in   BL  Value to write to the CMOS register.
; @reg  AL
rtc_write:
    call rtc_select_reg ; Select the specified CMOS register.
    mov al, bl          ; OUT can only work with AL.
    out RTC_DATA, al    ; Write the value to the CMOS register.
    ret

; This procedure should only be called when interrupts are disabled.
rtc_init_interrupts:
    mov ah, RTC_STATUS_B
    call rtc_read   ; read status register B into AL

    mov bl, al
    or bl, RTC_INTERRUPT_PERIODIC | RTC_INTERRUPT_UPDATE_ENDED
    call rtc_write  ; write updated value with enabled interrupts back to status register B

    ret

; Handler of all RTC-related interrupts.
; It currently contains only code used for debugging.
; Specifically, it was used to determine the timing difference
; between the 1024 Hz periodical RTC interrupt and the interrupt
; indicating that the seconds register has been incremented.
rtc_handler:
    cli
    pusha

    mov ah, RTC_STATUS_C
    call rtc_read

    ; If the time hasn't been initialized yet.
    test dword [time_high], ~0
    jz .time_init

    add dword [time_low], 1
    adc dword [time_high], 0

    test al, RTC_INTERRUPT_UPDATE_ENDED
    jz .end

    ; Print current time, as stored the kernel's memory.
    call print8

    mov eax, dword [time_low]
    call print32

    ; Clear the time.
    mov dword [time_low], 0

.end:
    call eoi_slave

    popa
    sti
    iret

.time_init:
    test al, RTC_INTERRUPT_UPDATE_ENDED
    jz .end

    mov dword [time_high], 1
    jmp .end

SECTION .data

time_high   dd 0
time_low    dd 0
