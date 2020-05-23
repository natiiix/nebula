SECTION .data

; command buffer
cmdbuff times 0x100 db 0
cmdbuff_idx db 0

SECTION .rodata

; command prompt string
cmdprompt   db ">", 0

; help command data
cmdhelp     db "help", 0

helpstr     db \
    "Available commands:",                                              LF, \
    "  help      Prints this help message.",                            LF, \
                                                                        LF, \
    "The shell does not provide any other functionality yet.",          0

; invalid command data
invalidcmd  db "Invalid command: ", 0
