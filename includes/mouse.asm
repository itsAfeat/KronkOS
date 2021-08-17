HW_EQUIP_PS2     equ 4          ; PS2 mouse installed?
MOUSE_PKT_BYTES  equ 3          ; Number of bytes in mouse packet
MOUSE_RESOLUTION equ 3          ; Mouse resolution 8 counts/mm
ARG_OFFSETS      equ 6          ; Offset of args from BP

mouse_initialize:
    push es
    push bx

    int 0x11
    test ax, HW_EQUIP_PS2
    jz .no_mouse

    mov ax, 0xC205
    mov bh, MOUSE_PKT_BYTES
    int 0x15
    jc .no_mouse

    mov ax, 0xC203
    mov bh, MOUSE_RESOLUTION
    int 0x15
    jc .no_mouse

    push cs
    pop es

    mov bx, mouse_callback_dummy
    mov ax, 0xC207
    int 0x15
    jc .no_mouse

    clc
    jmp .finished
    
    .no_mouse:
        stc
    
    .finished:
        pop bx
        pop es
        ret


mouse_enable:
    push es
    push bx

    call mouse_disable

    push cs
    pop es
    mov bx, mouse_callback
    mov ax, 0xC207
    int 0x15

    mov ax, 0xC200
    mov bh, 1
    int 0x15

    pop bx
    pop es
    ret


mouse_disable:
    push es
    push bx

    mov ax, 0xC200
    xor bx, bx
    int 0x15

    mov es, bx
    mov ax, 0xC207
    int 0x15

    pop bx
    pop es
    ret


mouse_callback:
    push bp
    mov bp, sp

    push ds
    push ax
    push bx
    push cx
    push dx

    push cs
    pop ds

    mov al, [bp+ARG_OFFSETS+6]
    mov bl, al
    mov cl, 3
    shl al, cl

    sbb dh, dh
    cbw
    mov dl, [bp+ARG_OFFSETS+2]
    mov al, [bp+ARG_OFFSETS+4]

    neg dx
    mov cx, [mouseY]
    add dx, cx
    mov cx, [mouseX]
    add ax, cx

    mov [curStatus], bl
    mov [mouseX], ax
    mov [mouseY], dx

    pop dx
    pop cx
    pop bx
    pop ax
    pop ds
    pop bp

mouse_callback_dummy:
    retf

poll_mouse:
    push ax
    push bx
    push dx
    
    mov bx, 0x0002

    cli
    mov ax, [mouseX]
    mov dx, [mouseY]
    sti

    pop dx
    pop bx
    pop ax
    ret

clamp_mouse:
    mov ax, [mouseX]

    cmp ax, screenmaxW
    jge .r_edge

    mov dx, screenminW
    cmp ax, dx
    jle .l_edge

    mov dx, screenminH
    mov ax, [mouseY]
    cmp ax, dx
    jle .t_edge

    cmp ax, screenmaxH
    jge .b_edge

    ret

.r_edge:
    mov word [mouseX], screenmaxW
    mov dl, [mouseX]
    mov dh, [mouseY]
    call move_cursor
    ret

.l_edge:
    mov word [mouseX], screenminW
    mov dl, [mouseX]
    mov dh, [mouseY]
    call move_cursor
    ret

.t_edge:
    mov word [mouseY], screenminH
    mov dl, [mouseX]
    mov dh, [mouseY]
    call move_cursor
    ret

.b_edge:
    mov word [mouseY], screenmaxH
    mov dl, [mouseX]
    mov dh, [mouseY]
    call move_cursor
    ret

no_mouse:
    mov ax, mouse_yes
    xor bx, bx
    xor cx, cx
    mov dx, 0
    call dialog_box

    xor ax, ax
    int 0x13

    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

mouse_loop:
    call poll_mouse

    mov dl, [mouseX]
    mov dh, [mouseY]

    call move_cursor
    call clamp_mouse

    ret

mouseX:         dw 0
mouseY:         dw 0
curStatus:      db 0
noMouseMsg:     db 0x0d, "Error setting up and initializing mouse", 0x0a, 0x0d, 0
