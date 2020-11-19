; ==================================================================
; The Kronk Operating System kernel
; Copyright (C) 2019 - 2020 Alexander Wiencken
;
; This is loaded from the drive by BOOTLOAD.BIN, as KERNEL.BIN
; ==================================================================

    ORG 0x0000
    BITS 16
    
    %define KRONKOS_VER '0.3.2'
    %define KRONKOS_API 4
    
    ; RAM locations
    disk_buffer     equ 24576
    prg_load_loc    equ 32768
    set_load_loc    equ 36864

    ; Screen mouse clamps
    screenmaxW      equ 0x004E
    screenminW      equ 0x0001
    screenmaxH      equ 0x0017
    screenminH      equ 0x0001
    
    ; Mouse buttons
    leftMButton     equ 0x09
    rightMButton    equ 0x0A

    ; Screen modes
    vidRes          equ 0x13
    cliRes          equ 0x03

; ******************************************************************
; Start the kernel
kernel_start:
    call seed_random

    cli                         ; Clear interrupts
    mov ax, 0x2000              ; The bootloader loads us at 0x2000
    mov ds, ax                  ; Set DS and ES to 0x2000
    mov es, ax

    ; Stack just below 0x2000:0x0000 starting at 0x1000:0x0000.
    ; First push will set SS:SP to 0x1000:0xfffe because SP will wrap.
    mov ax, 0x1000
    mov ss, ax
    xor sp, sp

    cld                         ; Clear Direction Flag (DF=0 is for forward string movement)
; ******************************************************************


; ==================================================================
; START OF KERNEL
; ==================================================================

RESET:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di

    ; Change the cursor to a solid block
    mov ch, 0x00
    call change_cursor

    ; Check if SETTINGS.KSF exists
    mov ax, settings_filename
    call os_file_exists
    jnc .skip_setup     ; If it does... skip the setup

    call setup_init

    ; Save the settings
    mov ax, settings_filename
    mov bx, set_load_loc
    mov cx, usrNam
    call os_write_file

    jmp RESET

.skip_setup:
    ; Load the settings file
    mov ax, settings_filename
    mov cx, set_load_loc
    xor bx, bx
    call os_load_file

    mov si, bx
    mov di, usrNam
    call string_copy

    mov ah, [vidMode]
    cmp ah, 0
    je .startCli
    cmp ah, 1
    je .startVideo

.startCli:
    call kronk_cli
    hlt

.startVideo:
    call kronk_vid
    hlt


; ==================================================================
; JUMP VECTORS
; ==================================================================

JUMP_VECTORS:
    jmp kernel_start        ; 0x0066
    jmp print               ; 0x0068
    jmp cls                 ; 0x006B
    jmp os_file_exists      ; 0x006E
    jmp os_load_file        ; 0x0071
    jmp os_create_file      ; 0x0074
    jmp os_remove_file      ; 0x0077
    jmp os_write_file       ; 0x007A
    jmp string_lowercase    ; 0x007D
    jmp string_uppercase    ; 0x0080
    jmp string_truncate     ; 0x0083
    jmp string_length       ; 0x0086
    jmp move_cursor         ; 0x0089
    jmp get_cursor_pos      ; 0x008C
    jmp print_horiz_line    ; 0x008F
    jmp input_dialog        ; 0x0092
    jmp list_dialog         ; 0x0095
    jmp dialog_box          ; 0x0098
    jmp change_cursor       ; 0x009B
    jmp string_clear        ; 0x009E
    jmp os_get_file_list    ; 0x00A1
    jmp clear_regs          ; 0x00A4
    jmp int_to_string       ; 0x00A7


; ==================================================================
; KERNEL SUBROUTINES
; ==================================================================

    error_ext:
        pop si

        mov ax, err1_ext
        mov bx, err2_ext
        xor cx, cx
        xor dx, dx
        call dialog_box

        mov bh, cli_color
        call cls

        ret

    try_run_file:
        call string_uppercase
        mov si, ax
        mov di, kern_filename
        call string_compare
        jc load_kern_err

        call os_file_exists
        jc .not_found
        clc

        mov si, ax
        push si 

        mov bx, si
        mov ax, si
        call string_length

        mov si, bx
        add si, ax

        sub si, 3

        mov di, bin_ext
        mov cx, 3
        rep cmpsb
        jne execute_bas_program
        pop si

        mov ax, si
        mov cx, prg_load_loc
        call os_load_file

        call execute_bin_program
        ret

        .not_found:
            stc
            ret

        load_kern_err:
            pop si

            mov ax, err3_ext
            mov bx, err4_ext
            xor cx, cx
            xor dx, dx
            call dialog_box

            mov bh, cli_color
            call cls

            ret

    execute_bas_program:
        pop si
        push si
        
        mov bx, si
        mov ax, si
        call string_length

        mov si, bx
        add si, ax

        sub si, 3

        mov di, bas_ext
        mov cx, 3
        rep cmpsb
        jne error_ext

        pop si
        
        mov ax, si
        mov cx, prg_load_loc
        call os_load_file

        mov bh, 0x0F
        call cls

        mov ax, prg_load_loc
        xor si, si
        ;call os_run_basic

        mov si, new_line
        call print

        mov bh, cli_color
        call cls

        ret

    execute_bin_program:
        mov si, new_line
        call print

		xor ax, ax
		xor bx, bx
		xor cx, cx
		xor dx, dx
		xor si, si
		xor di, di

        call prg_load_loc
        mov bh, 0x0F
        call cls

        mov si, prg_done_msg
        call print
        xor ah, ah
        int 0x16
        
        mov bh, 0x0F
        call cls

        ret


; ------------------------------------------------------------------
; STRINGS AND OTHER VARIABLES

    ; DEBUG VARIABLES START
    tmp:                db "Me? Gongaga", 0
    ; END

    ; USER RELATED VARIABLES START
    usrNam:             times 21 db 0

    vidMode:            dw 0x00
    cli_color:          equ 0x0f
    vid_backcolor:      equ 0x01
    vid_forecolor:      equ 0x0f
    ; END

    ; TMP VARIABLES START
    mouse_left:         db "MOUSE LEFT", 0
    mouse_right:        db "MOUSE RIGHT", 0
    ; END

    ; CLI SPECIFIC VARIABLES START
	in_msg:				db ":> ", 0
	in_buffer: 			times 41 db 0
    not_com:            db " is not known command", 0x0a, 0x0d, 0
    ; END

    ; CLI COMMANDS START
    restart_com:        db "restart", 0
    shutdown_com:       db "shutdown", 0
    settings_com:       db "settings", 0
    clear_com:          db "clear", 0
    dir_com:            db "dir", 0
    help_com:           db "help", 0
    edit_com:           db "edit", 0
    load_com:           db "load", 0
    mk_com:             db "mk", 0
    rm_com:             db "rm", 0
    ; END

    ; MOUSE VARIABLES START
    mouse_yes:          db "MOUSE IS CONNECTED!", 0
    mouse_no:           db "MOUSE IS NOT CONNECTED!", 0
    ; END

    ; WELCOME SCREEN VARIABLES START
	welcome_msg1:		db 0x0a, 0x0d, " KronkOS ver. ", KRONKOS_VER
						times 44-18 db " "
						db 0x0a, 0x0d, " ", 0
	welcome_msg2:		db " Kilo Bytes of total memory available. ", 0x0a, 0x0d, 0
	welcome_msg3:		times 45 db " "
						db 0x0a, 0x0d, " Type 'help' and press enter to start off.   ", 0x0a, 0x0d, 0
	; END

    ; FILE RELATED VARIABLES START
	kern_filename:		db 'KERNEL.BIN', 0
    settings_filename:  db 'SETTINGS.KSF', 0
	prg_done_msg:	    db '>>> Program finished --- press a key to continue...', 0

	bin_ext:			db 'BKF'
	bas_ext:			db 'BAS'
	err1_ext:			db "Unknown extension", 0
	err2_ext:			db "Only .BKF and .BAS is allowed", 0
	err3_ext:			db "Error loading file", 0
	err4_ext:			db "You can't load KERNEL.BIN", 0
    err5_ext:           db "You can't load SETTINGS.KSF", 0
    notfound_msg:	    db 0x0a, 0x0d, "File not found", 0x0a, 0x0a, 0x0d, 0
    ; END

    ; OTHER VARIABLES START
	fmt_12_24:			db 0 		; (Non-zero = 24 hour format)
	fmt_date:			db 1, '/'	; 0, 1, 2 = M/D/Y, D/M/Y or Y/M/D
									; Bit 7 = use name for months
									; If bit 7 = 0, second byte = separator character

	new_line:			db 0x0a, 0x0d, 0
	file_size_sep:		db " -- ", 0
	file_size_typ:		db " Bytes", 0x0a, 0x0d, 0
    ; END

    ; MENUBAR VARIABLES START
    mb_color:           equ 0x30
    mb_fill:            times 79 db " "
                        db 0
    ; END

; ------------------------------------------------------------------
; INCLUDED FILES

    %include "./includes/settings_menu.asm"
    %include "./includes/cli.asm"
    %include "./includes/menubar.asm"
    %include "./includes/video.asm"
    %include "./includes/setup.asm"
    %include "./includes/cls.asm"
    %include "./includes/string.asm"
    %include "./includes/screen.asm"
    %include "./includes/misc.asm"
    %include "./includes/input.asm"
    %include "./includes/math.asm"
    %include "./includes/print.asm"
    %include "./includes/mouse.asm"
    %include "./includes/disk.asm"
    %include "./includes/checkin.asm"

; ==================================================================
; END OF KERNEL
; ==================================================================