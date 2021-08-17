kronk_vid:
    mov ax, 1
    mov bh, vid_backcolor
    call switch_mode
    
    ; Disable color blinking
    mov ax, 0x1003
    mov bx, 0x0000
    int 0x10

    ; Initalize and enable the mouse if possible
    call mouse_initialize
    jc error
    call mouse_enable
    jmp vid_input

error: 
    mov bh, 0x00
    call cls
    jmp $


vid_input:
    mov bh, vid_backcolor
    call cls

.at_same:
    call mouse_loop
    cmp dl, [lastX]
    jne .moved

    cmp dh, [lastY]
    jne .moved

    mov si, sejt
    mov bx, 0x000F
    call print_atr

    jmp .at_same

.moved:
    mov [lastX], dl
    mov [lastY], dh

    mov si, sejt
    mov bx, 0x000F
    call print_atr

    jmp vid_input

    .separator: db ", ", 0
    .lastPos:   dw 0

; ------------------------------------------------------------------
; STRINGS AND OTHER VARIABLES

    lastX:              db 0
    lastY:              db 0
    mouse_working:      db 0
    sejt:               db "X", 0