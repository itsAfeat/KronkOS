BITS 16
ORG 32768

jmp start

    %include "kronkdev.inc"

start:
    ; Set the video mode
    mov ax, 0x0d
    int 0x10

    ; Clear the screen
    xor bx, bx
    call cls
    
    ; Get the players names

    mov ax, player1_name
    mov bx, player1_msg
    mov cx, 12
    call string_dialog

    mov ax, player2_name
    mov bx, player2_msg
    mov cx, 12
    call string_dialog

    ; Clear the screen again
    xor bx, bx
    call cls

; ------------------------------------------------------------------
; MAIN GAME LOOP

main_loop:
    ; Draw the boxes
    ; The nine player boxes
    mov cx, 3
    xor dx, dx

    .boxes:
        mov bx, 0x000c
        call draw_single_box
        add dl, 7
        call draw_single_box
        add dl, 7
        call draw_single_box

        xor dl, dl
        add dh, 6

        loop .boxes

    mov bx, 0x000f
    mov dx, 0x0516
    call draw_user_box
    call draw_footer

    mov al, [current_player]
    test al, al
    jnz .DRAW_PLAYER2

    mov dh, [player1_y]
    mov dl, [player1_x]
    mov bx, 0x0002
    call draw_single_box

    jmp GET_KEYS

    .DRAW_PLAYER2:
        mov dh, [player2_y]
        mov dl, [player2_x]
        mov bx, 0x0003
        call draw_single_box

    GET_KEYS:
        call draw_marked
        
        xor ax, ax
        int 0x16

        cmp ah, KEY_UP
        je MOVE_UP
        cmp ah, KEY_DOWN
        je MOVE_DOWN
        cmp ah, KEY_RIGHT
        je MOVE_RIGHT
        cmp ah, KEY_LEFT
        je MOVE_LEFT

        cmp al, KEY_SPACE
        je SPACE_PRESSED

        cmp ax, KEY_F1
        je exit
        cmp ax, KEY_F2
        je start
        cmp ax, KEY_F3
        je help

        jmp GET_KEYS


help:
    mov ax, help_msg1
    mov bx, help_msg2
    xor cx, cx
    xor dx, dx
    call dialog_box

    xor bx, bx
    call cls
    jmp main_loop


exit:
    ret


; ------------------------------------------------------------------
; GAMEPLAY FUNCTIONS

MOVE_UP:
    pusha

    call check_marked
    jc .DONE

    mov al, [current_player]
    test al, al
    jnz .PLAYER2_UP

    ; PLAYER 1
    mov ax, [player1_y]
    test ax, ax
    jz .DONE

    sub ax, 6
    mov [player1_y], ax

    mov dh, [player1_y]
    mov dl, [player1_x]
    mov bx, 0x000a
    call draw_single_box

    ; PLAYER 2
    .PLAYER2_UP:
        mov ax, [player2_y]
        test ax, ax
        jz .DONE

        sub ax, 6
        mov [player2_y], ax

        mov dh, [player2_y]
        mov dl, [player2_x]
        mov bx, 0x000b
        call draw_single_box

    .DONE:
        popa
        jmp main_loop

MOVE_DOWN:
    pusha

    call check_marked
    jc .DONE

    mov al, [current_player]
    test al, al
    jnz .PLAYER2_DOWN

    ; PLAYER 1
    mov ax, [player1_y]
    cmp ax, 12
    je .DONE

    add ax, 6
    mov [player1_y], ax

    mov dh, [player1_y]
    mov dl, [player1_x]
    mov bx, 0x000a
    call draw_single_box

    ; PLAYER 2
    .PLAYER2_DOWN:
        mov ax, [player2_y]
        cmp ax, 12
        je .DONE

        add ax, 6
        mov [player2_y], ax

        mov dh, [player2_y]
        mov dl, [player2_x]
        mov bx, 0x000b
        call draw_single_box

    .DONE:
        popa
        jmp main_loop

MOVE_RIGHT:
    pusha
    
    call check_marked
    jc .DONE

    mov al, [current_player]
    cmp al, 0
    jne .PLAYER2_RIGHT

    ; PLAYER 1
    mov ax, [player1_x]
    cmp ax, 14
    je .DONE

    add ax, 7
    mov [player1_x], ax

    mov dh, [player1_y]
    mov dl, [player1_x]
    mov bx, 0x000a
    call draw_single_box

    ; PLAYER 2
    .PLAYER2_RIGHT:
        mov ax, [player2_x]
        cmp ax, 14
        je .DONE

        add ax, 7
        mov [player2_x], ax

        mov dh, [player2_y]
        mov dl, [player2_x]
        mov bx, 0x000b
        call draw_single_box

    .DONE:
        popa
        jmp main_loop

MOVE_LEFT:
    pusha
    
    call check_marked
    jc .DONE

    mov al, [current_player]
    test al, al
    jnz .PLAYER2_LEFT

    ; PLAYER 1
    mov ax, [player1_x]
    test ax, ax
    jz .DONE

    sub ax, 7
    mov [player1_x], ax

    mov dh, [player1_y]
    mov dl, [player1_x]
    mov bx, 0x0002
    call draw_single_box

    ; PLAYER 2
    .PLAYER2_LEFT:
        mov ax, [player2_x]
        test ax, ax
        jz .DONE

        sub ax, 7
        mov [player2_x], ax

        mov dh, [player2_y]
        mov dl, [player2_x]
        mov bx, 0x0003
        call draw_single_box

    .DONE:
        popa
        jmp main_loop

SPACE_PRESSED:
    pusha

    mov al, [current_player]
    test al, al
    jnz .PLAYER2

    ; PLAYER 1
        mov ah, 1
        mov [current_player], ah
        jmp .DONE

    ; PLAYER 2
    .PLAYER2:
        mov ah, 0
        mov [current_player], ah

    .DONE:
        call add_marked

        xor dx, dx
        mov [player1_x], dx
        mov [player1_y], dx

        mov [player2_x], dx
        mov [player2_y], dx

        popa
        jmp main_loop

; ------------------------------------------------------------------
; DRAW FUNCTIONS

draw_marked:
    pusha

    ; PLAYER 1
    mov si, player1_marked
    .MARK_LOOP_1:
        lodsb
        cmp al, 0xff
        je .MARK_LOOP_1

        cmp al, 0
        je .DONE_1

        mov dl, [si]
        inc si
        mov dh, [si]
        inc si
        call move_cursor

        mov bx, 0x000a
        call draw_single_box

        jmp .MARK_LOOP_1

    .DONE_1:

    popa
    ret

draw_single_box:
    pusha
    push dx

    call move_cursor
    mov si, line_top
    call print_atr

    pop dx
    inc dh
    call move_cursor

    push cx
    mov cx, 4

    .draw_side:
        mov si, line_sid
        call print_atr

        call get_cursor_pos
        sub dl, 7
        call move_cursor        

        loop .draw_side

    pop cx
        
    mov si, line_bot
    call print_atr

    popa
    ret

draw_user_box:
    pusha
    push dx

    call move_cursor
    mov si, user_top
    call print_atr

    pop dx
    inc dh
    call move_cursor

    push cx
    mov cx, 6

    .draw_user_side:
        mov si, user_sid
        call print_atr

        call get_cursor_pos
        sub dl, 17
        call move_cursor        

        loop .draw_user_side

    pop cx

    mov si, user_bot
    call print_atr
    
    call get_cursor_pos
    sub dh, 6
    sub dl, 15
    call move_cursor

    mov si, board1_msg
    mov bl, 0x07
    call print_atr

    inc dh
    add dl, 2
    call move_cursor

    mov si, player1_name
    mov bl, 0x0a
    call print_atr

    add dh, 2
    sub dl, 2
    call move_cursor

    mov si, board2_msg
    mov bl, 0x07
    call print_atr

    inc dh
    add dl, 2
    call move_cursor

    mov si, player2_name
    mov bl, 0x0b
    call print_atr

    popa
    ret
    
draw_footer:
    pusha

    mov bx, 0x000F
    mov cx, 0x28
    mov dx, 0x1700
    call move_cursor
    

    .footer_loop:
        mov ah, 0x09
        mov al, 0xc4
        int 0x10

        loop .footer_loop

    inc dh
    call move_cursor

    mov si, footer_msg
    call print_atr

    popa
    ret

; ------------------------------------------------------------------
; MISC FUNCTIONS

add_marked:
    pusha

    mov al, [current_player]
    test al, al
    jz .PLAYER2

    ; PLAYER 1
        mov si, player1_marked
        .ADD_LOOP_1:
            lodsb
            cmp al, 0xff
            jne .ADD_LOOP_1

            mov ax, [player1_x]
            mov [si], ax
            inc si
            
            mov ax, [player1_y]
            mov [si], ax

            jmp .DONE

    ; PLAYER 2
    .PLAYER2:


    .DONE:
        popa
        ret

check_marked:
    pusha

    clc

    popa
    ret

string_dialog:
    pusha

    push ax
    push bx

    mov [.length], cx

    mov dh, 8
    mov dl, 10

    .draw_box:
        call move_cursor
        pusha
        mov ax, 0x09db
        mov bx, 0x0001
        mov cx, 20
        int 0x10
        popa

        inc dh
        cmp dh, 16
        jne .draw_box

    .boxdone:
        mov dh, 10
        mov dl, 11
        call move_cursor

        pop bx
        mov si, bx
        xor bh, bh
        mov bl, 0x1f
        call print_atr

        mov dh, 13
        mov dl, 12
        call move_cursor

        mov ax, 0x09c4
        mov bx, 0x000f
        mov cx, [.length]
        dec cx
        int 0x10

        mov dh, 12
        mov dl, 12
        call move_cursor
        
        mov ax, 0x09db
        mov bx, 0x0000
        mov cx, [.length]
        dec cx
        int 0x10

        mov dl, 12
        call move_cursor

        pop ax
        mov bx, [.length]
        call input_string

        popa
        ret

        .length:    dw 0

; ------------------------------------------------------------------
; STRINGS AND OTHER VARIABLES

    player1_name:   times 12 db 0
    player2_name:   times 12 db 0

    player1_x:      dw 0
    player1_y:      dw 0

    player2_x:      dw 0
    player2_y:      dw 0

    current_player: db 0

    player1_marked: times 18 dw 0xffff
                    db 0
    player2_marked: times 18 dw 0xffff
                    db 0

    player1_msg:    db "Player 1 name:", 0
    player2_msg:    db "Player 2 name:", 0

    line_top:   db 0xda
                times 5 db 0xc4
                db 0xbf, 0

    line_bot:   db 0xc0
                times 5 db 0xc4
                db 0xd9, 0

    line_sid:   db 0xb3
                times 5 db 0x20
                db 0xb3, 0x0a, 0


    user_top:   db 0xc9
                times 15 db 0xcd
                db 0xbb, 0

    user_bot:   db 0xc8
                times 15 db 0xcd
                db 0xbc, 0

    user_sid:   db 0xba
                times 15 db 0x20
                db 0xba, 0x0a, 0

    board1_msg:     db "Player 1:", 0
    board2_msg:     db "Player 2:", 0

    footer_msg:     db "[F1] Exit   [F2] New game   [F3] Help", 0
    help_msg1:      db "Use the arrow keys to change box", 0
    help_msg2:      db "Press space to place in the selected square", 0