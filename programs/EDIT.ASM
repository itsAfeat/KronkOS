BITS 16
ORG 32768

color   equ 0x0F

jmp start

    %include "kronkdev.inc"

start:
    mov bh, color
    call cls
    
	mov ch, 0x06
    call change_cursor

    mov ax, file_name
    call string_length
    mov di, file_name
    call string_clear

    mov ax, file_name
    mov bx, new_file_msg
    mov cx, 13
    call input_dialog

    mov si, file_name
    mov ax, 12
    call chk_string_ext

    mov di, file_name
    call string_copy

    mov bh, color
    call cls

    mov ax, new_color_list
    mov bx, color_help1
    mov cx, color_help2
    call list_dialog
    mov [color_code], ax

    mov ax, file_name
    call os_file_exists
    jnc .file_found

    call .create_file
    .file_found:

    mov ax, file_name
    mov cx, 36864
    call os_load_file

    jmp file_load_success

    .create_file:
        mov ax, file_name
        call os_create_file
        ret

    file_load_success:
        mov word [file_size], bx

        add bx, 36864
        cmp bx, 36864
        jne .not_empty

        mov byte [bx], 10
        inc bx
        inc word [file_size]

    .not_empty:
        mov word [last_byte], bx
        
        mov cx, 0
        mov word [skiplines], 0

        mov byte [cursor_x], 0
        mov byte [cursor_y], 2

    render_text:
        call setup_screen

        mov dh, 2
        mov dl, 0
        call move_cursor

        mov si, 36864
        mov ah, 0x0e

        mov word cx, [skiplines]
    
    redraw:
        cmp cx, 0
        je display_loop
        dec cx

        .skip_loop:
            lodsb
            cmp al, 0
            jne .skip_loop
            jmp redraw

    display_loop:
        lodsb

        cmp al, 10
        jne skip_return

        call get_cursor_pos
        mov dl, 0
        call move_cursor
    
    skip_return:
        call get_cursor_pos
        cmp dl, 79
        je .no_print

        int 0x10

        .no_print:
            mov word bx, [last_byte]
            cmp si, bx
            je near get_input

            call get_cursor_pos
            cmp dh, 23
            je get_input

            jmp display_loop
    get_input:
        mov byte dl, [cursor_x]
        mov byte dh, [cursor_y]
        call move_cursor

        mov ah, 0x00
        int 0x16

        cmp ah, KEY_UP
        je near go_up
        cmp ah, KEY_DOWN
        je near go_down
        cmp ah, KEY_LEFT
        je near go_left
        cmp ah, KEY_RIGHT
        je near go_right

        cmp al, KEY_ESC
        je near close

        jmp text_entry

; ------------------------------------------------------------------
; Move cursor left on the screen, and backward in data bytes
    go_left:
        cmp byte [cursor_x], 0
        je get_input
        sub byte [cursor_x], 2
        sub word [cursor_byte], 2

; ------------------------------------------------------------------
; Move cursor right on the screen, and forward in data bytes
    go_right:
        pusha

        cmp byte [cursor_x], 79
        je .nothing_to_do

        mov word ax, [cursor_byte]
        mov si, 36864
        add si, ax

        inc si

        cmp word si, [last_byte]
        je .nothing_to_do

        dec si

        cmp byte [si], 0x0a
        je .nothing_to_do

        inc word [cursor_byte]
        inc byte [cursor_x]

        .nothing_to_do:
            popa
            jmp get_input

; ------------------------------------------------------------------
; Move cursor down on the screen, and forward in data bytes
    go_down:
        pusha

        mov word cx, [cursor_byte]
        mov si, 36864
        add si, cx

        .loop:
            inc si
            cmp word si, [last_byte]
            je .do_nothing

            dec si
            lodsb

            inc cx
            cmp al, 0x0a
            jne .loop

            mov word [cursor_byte], cx
        
        .nowhere_to_go:
            popa

            cmp byte [cursor_y], 22
            je .scroll_file_down
            
            inc byte [cursor_y]
            mov byte [cursor_x], 0
            jmp render_text
        
        .scroll_file_down:
            inc word [skiplines]
            mov byte [cursor_x], 0
            jmp render_text
        
        .do_nothing:
            popa
            jmp render_text

; ------------------------------------------------------------------
; Move cursor up on the screen, and backward in data bytes
    go_up:
        pusha

        mov word cx, [cursor_byte]
        mov si, 36864
        add si, cx

        cmp si, 36864
        je .start_of_file

        mov byte al, [si]
        cmp al, 0x0a
        je .starting_on_newline

        jmp .full_monty

    .starting_on_newline:
        cmp si, 36865
        je .start_of_file

        cmp byte [si-1], 0x0a
        je .another_newline_before
        dec si
        dec cx
        jmp .full_monty

    .another_newline_before:
        cmp byte [si-2], 0x0a
        jne .go_to_start_of_line

        dec word [cursor_byte]
        jmp .display_move

    .go_to_start_of_line:
        dec si
        dec cx
        cmp si, 36864
        je .start_of_file
        dec si
        dec cx
        cmp si, 36864
        je .start_of_file
        jmp .loop2

    .full_monty:
        cmp si, 36864
        je .start_of_file

        mov byte al, [si]
        cmp al, 0x0a
        je .found_newline
        dec cx
        dec si
        jmp .full_monty

    .found_newline:
        dec si
        dec cx

    .loop2:
        cmp si, 36864
        je .start_of_file

        mov byte al, [si]
        cmp al, 0x0a
        je .found_done

        dec cx
        dec si
        jmp .loop2

    .found_done:
        inc cx
        mov word [cursor_byte], cx
        jmp .display_move

    .start_of_file:
        mov word [cursor_byte], 0
        mov byte [cursor_x], 0

    .display_move:
        popa
        cmp byte [cursor_y], 2
        je .scroll_file_up
        dec byte [cursor_y]
        mov byte [cursor_x], 0
        jmp get_input

    .scroll_file_up:
        cmp word [skiplines], 0
        jle get_input
        dec word [skiplines]
        jmp render_text

; ------------------------------------------------------------------
; When an key (other than cursor keys or Esc) is pressed...
    text_entry:
        pusha

        cmp ax, KEY_F1
        je near help_menu

        cmp ax, KEY_F2
        je near new_file

        cmp ax, KEY_F3
        je near save_file

        cmp ah, 0x53
        je near .delete_pressed

        cmp al, 8
        je near .backspace_pressed

        cmp al, KEY_ENTER
        je near .enter_pressed

        cmp al, 32
        jl near .nothing_to_do

        cmp al, 126
        je near .nothing_to_do

        call get_cursor_pos
        cmp dl, 78
        jg near .nothing_to_do

        push ax
        
        call move_all_chars_forward

        mov word cx, [cursor_byte]
        mov si, 36864
        add si, cx

        pop ax

        mov byte [si], al
        inc word [cursor_byte]
        inc byte [cursor_x]

        .nothing_to_do:
            popa
            jmp render_text

        .delete_pressed:
            mov si, 36865
            add si, word [cursor_byte]

            cmp si, word [last_byte]
            je .end_of_file

            cmp byte [si], 0x0a
            jl .at_final_char_in_line

            call move_all_chars_backward
            popa
            jmp render_text
        
        .backspace_pressed:
            cmp word [cursor_byte], 0
            je .do_nothing

            cmp byte [cursor_x], 0
            je .do_nothing

            dec word [cursor_byte]
            dec byte [cursor_x]

            mov si, 36864
            add si, word [cursor_byte]

            cmp si, word [last_byte]
            je .end_of_file

            cmp byte [si], 0x0a
            jl .at_final_char_in_line

            call move_all_chars_backward
            popa
            jmp render_text
        
        .at_final_char_in_line:
            call move_all_chars_backward
            call move_all_chars_backward
            popa
            jmp render_text

        .do_nothing:
            popa
            jmp render_text
        
        .end_of_file:
            popa
            jmp render_text

        .enter_pressed:
            call move_all_chars_forward

            mov word cx, [cursor_byte]
            mov di, 36864
            add di, cx

            mov byte [di], 0x0a

            popa
            jmp go_down

; ------------------------------------------------------------------
; Move data from current cursor one character ahead
    move_all_chars_forward:
        pusha
        mov si, 36864
        add si, word [file_size]

        mov di, 36864
        add di, word [cursor_byte]

        .loop:
            mov byte al, [si]
            mov byte [si+1], al
            dec si
            cmp si, di
            jl .finished
            jmp .loop

        .finished:
            inc word [file_size]
            inc word [last_byte]

            popa
            ret

; ------------------------------------------------------------------
; Move data from current cursor + 1 to end of file back one char
    move_all_chars_backward:
        pusha

        mov si, 36864
        add si, word [cursor_byte]

        .loop:
            mov byte al, [si+1]
            mov byte [si], al
            inc si
            cmp word si, [last_byte]
            jne .loop

        .finished:
            dec word [file_size]
            dec word [last_byte]

            popa
            ret

; ------------------------------------------------------------------
; SAVE FILE
    save_file:
        mov ax, file_name
        call os_remove_file

        mov ax, file_name
        mov word cx, [file_size]
        mov bx, 36864
        call os_write_file

        jc .save_failure

        mov ax, save_succeed_msg
        mov bx, 0
        mov cx, 0
        mov dx, 0
        call dialog_box

        popa
        jmp render_text

        .save_failure:
            mov ax, save_fail_msg1
            mov bx, save_fail_msg2
            mov cx, 0
            mov dx, 0
            call dialog_box

            popa
            jmp render_text

; ------------------------------------------------------------------  

; ------------------------------------------------------------------
; NEW FILE
    new_file:
        mov ax, confirm_msg
        mov bx, 0
        mov cx, 0
        mov dx, 1
        call dialog_box
        cmp ax, 1
        je .do_nothing

        mov di, 36864
        mov al, 0
        mov cx, 28672
        rep stosb

        mov word [file_size], 1

        mov bx, 36864
        mov byte [bx], 10
        inc bx
        mov word [last_byte], bx

        mov cx, 0
        mov word [skiplines], 0

        mov byte [cursor_x], 0
        mov byte [cursor_y], 2

        mov word [cursor_byte], 0

    .retry_filename:
        mov ax, file_name
        mov bx, new_file_msg
        call input_dialog

        mov ax, file_name
        call os_remove_file

        mov ax, file_name
        mov word cx, [file_size]
        mov bx, 36864
        call os_write_file
        jc .new_failure

    .do_nothing:
        popa
        jmp render_text

    .new_failure:
        mov ax, save_fail_msg1
        mov bx, save_fail_msg2
        mov cx, 0
        mov dx, 0
        call dialog_box

        jmp .retry_filename

; ------------------------------------------------------------------
; HELP MENU
    help_menu:
        mov ax, help_msg1
        mov bx, help_msg2
        mov cx, help_msg3
        mov dx, 0
        call dialog_box
        
        popa
        jmp render_text


; ------------------------------------------------------------------
; QUIT
    close:
	    mov ch, 0x00
        call change_cursor

        mov bh, color
        call cls
        ret

; ------------------------------------------------------------------
; SUBROUTINES

setup_screen:
    pusha

    cmp byte [color_code], 1
    je .bw
    cmp byte [color_code], 2
    je .wb
    cmp byte [color_code], 3
    je .bg
    cmp byte [color_code], 4
    je .gb
    cmp byte [color_code], 5
    je .wg
    cmp byte [color_code], 6
    je .gw

    .bw:
        mov bh, 0xF0
        jmp .continue

    .wb:
        mov bh, 0x0F
        jmp .continue

    .bg:
        mov bh, 0x70
        jmp .continue

    .gb:
        mov bh, 0x07
        jmp .continue

    .wg:
        mov bh, 0x8F
        jmp .continue

    .gw:
        mov bh, 0xF8
        jmp .continue

    .continue:
    call cls

    mov si, title_msg
    call print

    mov si, file_name
    call print

    mov dh, 1
    mov dl, 0
    call move_cursor
    mov ax, 1
    call print_horiz_line

    mov dh, 23
    mov dl, 0
    call move_cursor
    call print_horiz_line

    mov si, footer_msg
    call print

    popa
    ret

; ------------------------------------------------------------------
; STRINGS AND VARIABLES

    file_name:          times 13 db 0
    file_size:          dw 0
    new_file_msg:       db "Enter name of file to create/load", 0

    title_msg:          db "KronkOS Text Editor  -  ", 0
    footer_msg:         db "[Esc] Quit  [F1] Help  [F2] New  [F3] Save  [F5] Run BASIC", 0

	save_fail_msg1:	    db 'Could not save file!', 0
	save_fail_msg2:	    db '(Write-only media or bad filename?)', 0
	save_succeed_msg:	db 'File saved.', 0
    confirm_msg:        db "Are you sure? Unsaved data will be lost!", 0
                    
    help_msg1:          db "              -- HELP --", 0
    help_msg2:          db "[F2] Create a new file", 0
    help_msg3:          db "[F3] Save current file", 0x0a, 0x0d
                        times 20 db " "
                        db "[F5] Compile and run a BASIC (.bas) file", 0

    color_help1:        db "Choose which color scheme to use", 0
    color_help2:        db "[Foreground / Background]", 0
    new_color_list:     db "Black / White,White / Black,Black / Gray,Gray  / Black,White / Gray,Gray  / White", 0
    color_code:         db 0

    skiplines:          dw 0

    cursor_x:           db 0
    cursor_y:           db 1

    cursor_byte:        dw 0
    last_byte:          dw 0