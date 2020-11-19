kronk_cli:
    mov ax, 0
    mov bh, cli_color
    call switch_mode
    
    ; Disable color blinking
    mov ax, 0x1003
    mov bx, 0x0000
    int 0x10

	; Let's see if there's a file called AUTORUN.BIN and execute
	; it if so, before going to the terminal

    mov ax, .autobin_filename
    call os_file_exists
    jc .no_autorun_bin

    mov cx, prg_load_loc
    call os_load_file
    call execute_bin_program

.no_autorun_bin:
    mov ax, .autobas_filename
    call os_file_exists
    jc .no_autorun_bas

    mov cx, prg_load_loc
    call os_load_file
    call execute_bas_program

.no_autorun_bas:
    ; Draw welcome menu
    mov si, welcome_msg1
    call welcome_print

    mov ah, 0x88
    int 0x15
    call int_to_string
    mov si, ax
    call welcome_print

    mov si, welcome_msg2
    call welcome_print
    mov si, welcome_msg3
    call welcome_print

    mov ax, 0x0e0a
    int 0x10

; The loop that gets the input
.input_loop:
    ; Change the cursor to a solid block
    mov ch, 0x00
    call change_cursor

    call check_pos
    call draw_menu_bar

    ; Print the username and the input msg
    ;mov si, usrNam
    ;call print
    mov si, in_msg
    call print

    ; Get the input and save it in in_buffer 
    call get_input

    ; Check the input
    mov ax, settings_com
    call check_com
    jnc .settings

    mov ax, clear_com
    call check_com
    jnc .clear

    mov ax, dir_com
    call check_com
    jnc .dir

    mov ax, help_com
    call check_com
    jnc .show_help
    
    ; ----------------------------------
    ; MK AND RM

    pusha

    mov si, in_buffer+3
    mov di, .tmp_filename
    call string_copy

    mov si, in_buffer
    mov di, .tmp_inbuffer
    call string_copy

    mov si, in_buffer
    mov ax, 2
    call string_truncate
    
    mov ax, mk_com
    call check_com
    jnc .make_file

    mov ax, rm_com
    call check_com
    jnc .remove_file

    mov si, .tmp_inbuffer
    mov di, in_buffer
    call string_copy

    popa

    ; ----------------------------------
    ; LOAD AND EDIT

    pusha

    mov si, in_buffer+5
    mov di, .tmp_filename
    call string_copy

    mov si, in_buffer
    mov di, .tmp_inbuffer
    call string_copy

    mov si, in_buffer
    mov ax, 4
    call string_truncate

    mov ax, load_com
    call check_com
    jnc .load_file

    mov si, .tmp_inbuffer
    mov di, in_buffer
    call string_copy

    popa

    mov ax, restart_com
    call check_com
    jnc .restart

    mov ax, shutdown_com
    call check_com
    jnc .shutdown
    jc .not_equal

.not_equal:
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10

    mov ah, 0x0e
    mov al, '"'
    int 0x10

    mov si, in_buffer
    call print

    mov ah, 0x0e
    mov al, '"'
    int 0x10
    
    mov si, not_com
    call print
    
    ; Create a new line
    mov ax, 0x0e0a
    int 0x10

    jmp .input_loop

; ----------------------------------
; SETTINGS

.settings:
    call show_settings
    jmp .input_loop

; ----------------------------------
; CLEAR

.clear:
    mov bh, cli_color
    call cls
    jmp .input_loop

; ----------------------------------
; DIR

.dir:
    xor ax, ax
    call os_get_file_list

    push ax
    mov ax, 0x0e0a
    int 0x10
    int 0x10
    mov al, 0x0d
    int 0x10
    pop ax

    mov si, ax
    mov di, .tmp_filename
    mov dx, 0

    mov ah, 0x0e
    mov al, ' '
    int 0x10

    .loop:
        lodsb
        cmp al, ','
        je .add_size
        cmp al, 0
        je .done

        stosb
        inc dx

        mov ah, 0x0e
        int 0x10

        jmp .loop

    .add_size:
        pusha
        cmp dx, 12
        jge .continue

        call .add_spaces

        .continue:
        mov si, .file_size_sep
        call print

        mov ax, dx
        call string_truncate

        mov ax, .tmp_filename
        call os_get_file_size

        mov ax, bx
        call int_to_string
        mov si, ax
        call print

        mov si, file_size_typ
        call print

        mov ax, 0x0e20
        int 0x10

        popa

        mov di, .tmp_filename
        mov dx, 0
        jmp .loop

    .add_spaces:
        mov ax, 0x0e20
        int 0x10
        inc dx
        cmp dx, 12
        jne .add_spaces
        ret

    .done:
        cmp dx, 12
        jge .done_c

        call .add_spaces

        .done_c:
        mov si, .file_size_sep
        call print

        mov si, .tmp_filename
        mov ax, dx
        call string_truncate

        mov ax, .tmp_filename
        call os_get_file_size

        mov ax, bx
        call int_to_string
        mov si, ax
        call print

        mov si, .file_size_typ
        call print

    push ax

    mov ax, 0x0e0a
    int 0x10
    mov al, 0x0d
    int 0x10

    pop ax

    jmp .input_loop

; ----------------------------------
; HELP

.show_help:
    mov ax, .help_commands
    mov bx, .help_header
    mov cx, .help_string
    call list_dialog

    cmp ax, 4
    je .settings
    
    mov bh, cli_color
    call cls

    cmp ax, 2
    je .dir
    cmp ax, 9
    je .restart
    cmp ax, 10
    je .shutdown

    jmp .input_loop

    .help_commands:     db "HELP       --  What you're looking at,"
                        db "DIR        --  Show a list of all files,"
                        db "CLEAR      --  Clear the terminal,"
                        db "SETTINGS   --  Show the settings menu,"
                        db "MK FILE    --  Create a file,"
                        db "RM FILE    --  Delete a file,"
                        db "LOAD FILE  --  Load/run a file,"
                        db "EDIT FILE  --  Load and edit a file,"
                        db "RESTART    --  Restart KronkOS,"
                        db "SHUTDOWN   --  Shutdown KronkOS,,"
                        db "CANCEL     --  Leave this menu", 0
    .help_header:       db "HELP MENU", 0
    .help_string:       db "Press ENTER to run any of the commands", 0

; ----------------------------------
; MAKE FILE

.make_file:
    pusha
    mov ax, .tmp_filename
    call os_create_file
    
    mov ax, 0x0e0a
    int 0x10
    mov al, 0x0d
    int 0x10

    mov si, .tmp_filename
    call print
    mov si, .tmp_filemk
    call print

    mov ax, 0x0e0a
    int 0x10
    int 0x10
    mov al, 0x0d
    int 0x10

    popa

    jmp .input_loop

; ----------------------------------
; REMOVE FILE

.remove_file:
    pusha
    mov ax, .tmp_filename
    call os_remove_file
    
    mov ax, 0x0e0a
    int 0x10
    mov al, 0x0d
    int 0x10

    mov si, .tmp_filename
    call print
    mov si, .tmp_filerm
    call print

    mov ax, 0x0e0a
    int 0x10
    int 0x10
    mov al, 0x0d
    int 0x10

    popa

    jmp .input_loop

; ----------------------------------
; LOAD FILE

.load_file:
    pusha
    xor ax, ax

    mov ax, .tmp_filename
    call try_run_file
    jc .not_found

    popa
    jmp .input_loop

    .not_found:
        mov si, notfound_msg
        call print

        popa
        jmp .input_loop

; ----------------------------------
; EDIT FILE

.edit_file:
    jmp .input_loop

; ----------------------------------
; RESTART

.restart:
    mov ax, 0x00
    int 0x13
    int 0x19

    ; Halt cpu if restart fails
    hlt

; ----------------------------------
; SHUTDOWN

.shutdown:
    xor ax, ax
    int 0x13

    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

    ; Halt cpu if shutdown fails
    hlt


.tmp_filename:      times 20 db 0
.tmp_inbuffer:      times 41 db 0
.file_size_sep:		db " -- ", 0
.file_size_typ:		db " Bytes", 0x0a, 0x0d, 0
.tmp_filerm:        db " has been deleted", 0
.tmp_filemk:        db " has been created", 0
.autobin_filename:  db "AUTORUN.BKF", 0
.autobas_filename:  db "AUTORUN.BAS", 0
