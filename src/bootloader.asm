; keep it under 18
%define SECTORS 16
; SECTORS + 1 (~= 18) * 512 bytes
%define IMAGE_SIZE ((SECTORS + 1) * 512)
; 4096 bytes in paragraphs
%define STACK_SIZE 256

	cli                 ; disable interrupts

	;
	; Notes:
	;  1 paragraph	= 16 bytes
	; 32 paragraphs = 512 bytes
	;
	; Skip past our SECTORS
	; Skip past our reserved video memory buffer (for double buffering)
	; Skip past allocated STACK_SIZE
	;
	mov ax, (((SECTORS + 1) * 32) + 4000 + STACK_SIZE)
	mov ss, ax
	mov sp, STACK_SIZE * 16 ; 4096 in bytes

	sti                 ; enable interrupts

	mov ax, 0			; point all segments to _start
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; dl contains the drive number

	mov ax, 0			; reset disk function
	int 0x13			; call BIOS interrupt
	jc bootloader_fatal

	; FIXME: if SECTORS + 1 > 18 (~= max sectors per track)
	; then we should try to do _multiple_ reads
	;
	; Notes:
	;
	; 1 sector			= 512 bytes
	; 1 cylinder/track	= 18 sectors
	; 1 side			= 80 cylinders/tracks
	; 1 disk (1'44 MB)	= 2 sides
	;
	; 2 * 80 * 18 * 512 = 1474560 bytes = 1440 kilo bytes = 1.4 mega bytes
	;
	; We start _reading_ at SECTOR 2 because SECTOR 1 is where our stage 1
	; _bootloader_ (this piece of code up until the dw 0xAA55 marker, if you
	; take the time and scroll down below) is *loaded* automatically by BIOS
	; and therefore there is no need to read it again ...

	push es			    ; save es

	mov ax, 0x07E0	    ; destination location (second segment)
	mov es, ax		    ; destination location
	mov bx, 0		    ; index 0

	mov ah, 2		    ; read sectors function
	mov al, SECTORS	    ; number of sectors
	mov ch, 0		    ; cylinder number
	mov dh, 0		    ; head number
	mov cl, 2		    ; starting sector number
	int 0x13		    ; call BIOS interrupt

	jc bootloader_fatal

	pop es				; restore es

	jmp 0x07E0:0x0000	; jump to kernel_init (a.k.a stage 2)

bootloader_fatal:
	mov ax, 0	        ; reboot
	int 0x19

times 510-($-$$) db 0   ; pad with zeroes to fill first segment (bootloader segment)
    dw 0xAA55           ; terminate first sector with bootloader sector signature
