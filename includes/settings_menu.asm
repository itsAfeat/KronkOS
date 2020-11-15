show_settings:
    pusha

.main_menu:
    mov ax, .main_options
    mov bx, .main_header
    mov cx, .main_string
    call list_dialog

    cmp ax, 1
    je .display_menu

    jmp .end

.display_menu:
    mov ax, .display_options
    mov bx, .display_header
    mov cx, .display_string
    call list_dialog

    cmp ax, 1
    je .change_cli

    cmp ax, 2
    je .change_vid

    jmp .main_menu

.change_cli:
    mov ax, .display_restart1
    mov bx, .display_restart2
    xor cx, cx
    mov dx, 1
    call dialog_box

    test ax, ax
    jnz .display_menu


    mov byte [vidMode], 0
    xor ax, ax
    int 0x13
    jmp RESET

.change_vid:
    mov ax, .display_restart1
    mov bx, .display_restart2
    xor cx, cx
    mov dx, 1
    call dialog_box

    test ax, ax
    jnz .display_menu

    mov byte [vidMode], 1
    xor ax, ax
    int 0x13
    jmp RESET

.end:
    mov bh, cli_color
    call cls

    popa
    ret


.main_options:      db "DISPLAY,"
                    db "USER,"
                    db "EXIT SETTINGS", 0
.main_header:       db "SETTINGS", 0
.main_string:       db "Change the settings of KronkOS", 0

.display_options:   db "CLI MODE,"
                    db "VIDEO MODE,"
                    db "BACK", 0
.display_header:    db "VIDEO SETTINGS", 0
.display_string:    db "Change the video mode", 0
.display_restart1:  db "This will restart KronkOS", 0
.display_restart2:  db "Press 'OK' to continue", 0