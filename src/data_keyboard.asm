keybuff times 0x100 db 0 ; keyboard scan code buffer
keybuff_start   db 0 ; start index of keyboard buffer
keybuff_end     db 0 ; end index of keyboard buffer

; conversion table from keyboard key scan code to ASCII (with shift key released)
keytab  db 0, 0, '1234567890-=', 0, 0, 'qwertyuiop[]', LF, 0, "asdfghjkl;'`", 0, '\zxcvbnm,./', 0, '*', 0, ' '

; shifted conversion table from scan code to ASCII (when shift key is held down)
keytab_shift    db 0, 0, '!@#$%^&*()_+', 0, 0, 'QWERTYUIOP{}', 0, 0, 'ASDFGHJKL:"~', 0, '|ZXCVBNM<>?', 0, 0, 0, ' '

; table of key states (which keys are currently pressed down; 0x00 = pressed; 0x80 = released)
keystate times 0x80 db 0x80
