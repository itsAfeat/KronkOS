check_pos:
    pusha

    mov ah, 0x03
    xor bh, bh
    int 0x10

    cmp dh, 24
    je .at_end

    popa
    ret

.at_end:
    mov ax, 0x0603
    mov bh, cli_color
	mov dx, 0x184f
	xor cx, cx
    int 0x10

    mov ah, 0x02
    xor bh, bh
    xor dl, dl
    mov dh, 21
    int 0x10

    popa
    ret

draw_menu_bar:
    pusha

    mov ah, 0x03
    xor bh, bh
    int 0x10

    push dx

    mov ax, 0x0704
    mov bh, cli_color
	mov dx, 0x184f
	xor cx, cx
    int 0x10
    mov ax, 0x0604
    int 0x10
    
    mov ah, 0x02
    mov dh, 24
    xor bh, bh
    xor dl, dl
    int 0x10

    mov si, mb_fill
    mov bl, mb_color
    call print_atr

    mov ah, 0x02
    mov dh, 24
    mov dl, 1
    xor bh, bh
    int 0x10

    call get_time_string
    mov si, bx
    mov bl, mb_color
    call print_atr

    mov ah, 0x02
    mov dh, 24
    mov dl, 28
    xor bh, bh
    int 0x10

    mov ax, usrNam
    call string_uppercase
    mov si, ax
    mov bl, mb_color
    call print_atr

    mov ah, 0x02
    mov dh, 24
    mov dl, 69
    xor bh, bh
    int 0x10

    call get_date_string
    mov si, bx
    mov bl, mb_color
    call print_atr

    mov ah, 0x02
    xor bh, bh
    xor dl, dl
    pop dx
    int 0x10

    popa
    ret