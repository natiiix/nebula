; command buffer
cmdbuff times 0x100 db 0
cmdbuff_idx db 0

; command prompt string
cmdprompt   db ">", 0

; help command data
cmdhelp     db "help", 0
helpstr     db "This is a placeholder help message.", LF, "And this is its second line.", LF, "This line right here.", 0

; invalid command data
invalidcmd  db "Invalid command: ", 0
