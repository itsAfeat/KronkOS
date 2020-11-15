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

    jmp kernel_start

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
    
    ; RAM location for kernel disk operations
    disk_buffer     equ 24576

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

; ------------------------------------------------------------------
; KERNEL CODE START
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
    mov bx, 32768
    mov cx, usrNam
    call os_write_file

    jmp RESET

.skip_setup:
    ; Load the settings file
    mov ax, settings_filename
    mov cx, 32768
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
    jmp $

.startVideo:
    call kronk_vid
    jmp $

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

	bin_ext:			db 'BKF'
	bas_ext:			db 'BAS'
	err1_ext:			db "Unknown extension", 0
	err2_ext:			db "Only .BKF and .BAS is allowed", 0
	err3_ext:			db "Error loading file", 0
	err4_ext:			db "You can't load KERNEL.BIN", 0
    err5_ext:           db "You can't load SETTINGS.KSF", 0
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