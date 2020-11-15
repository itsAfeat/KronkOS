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
    jc vid_input
    mov al, 1
    mov [mouse_working], al
    call mouse_enable
    jmp vid_input

vid_input:
    ;mov si, mb_string
    ;xor bh, bh
    ;mov bl, vid_forecolor
    ;call print_atr

    ;mov bh, vid_backcolor
    ;call cls

    ;mov al, [mouse_working]
    ;cmp al, 0
    ;call mouse_loop
    ;call move_cursor

    ;mov si, sejt
    ;xor bh, bh
    ;mov bl, vid_forecolor
    ;call print_atr

    hlt

; ------------------------------------------------------------------
; STRINGS AND OTHER VARIABLES

    mouse_working:      db 0
    sejt:               db " ", 0